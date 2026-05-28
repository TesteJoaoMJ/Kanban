import { ref } from 'vue';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import { format } from 'date-fns';
import { supabase } from '@/api/supabase';
import { useAppStore } from '@/stores/app';

export function useOrderPDF() {
  const isGeneratingPdf = ref(false);
  const appStore = useAppStore();

  // --- UTILITÁRIOS ---

  const imageToBase64 = async (urlOrFile: string | File): Promise<string> => {
    try {
      if (!urlOrFile) return '';

      console.log(`[DEBUG] Baixando imagem: ${typeof urlOrFile === 'string' ? urlOrFile.substring(0, 50) + '...' : 'FILE'}`);

      if (typeof urlOrFile !== 'string') {
        return new Promise((resolve, reject) => {
          const reader = new FileReader();
          reader.onload = () => resolve(reader.result as string);
          reader.onerror = reject;
          reader.readAsDataURL(urlOrFile);
        });
      }

      // Adiciona timestamp para evitar cache
      const response = await fetch(urlOrFile + '?t=' + new Date().getTime(), { mode: 'cors', cache: 'no-store' });
      if (!response.ok) {
          console.error(`[DEBUG] Falha HTTP na imagem: ${response.status} ${response.statusText}`);
          throw new Error('Falha ao baixar imagem');
      }
      const blob = await response.blob();
      console.log(`[DEBUG] Imagem baixada (${blob.size} bytes). Convertendo para Base64...`);

      return new Promise((resolve, reject) => {
        const reader = new FileReader();
        reader.onloadend = () => {
            const res = reader.result as string;
            console.log(`[DEBUG] Conversão Base64 OK (Length: ${res.length})`);
            resolve(res);
        };
        reader.onerror = (e) => {
            console.error(`[DEBUG] Erro FileReader:`, e);
            reject(e);
        };
        reader.readAsDataURL(blob);
      });
    } catch (error: any) {
      console.error(`[DEBUG] Erro geral imageToBase64:`, error.message);
      // Retorna pixel transparente
      return 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';
    }
  };

  const sanitizeName = (name: string) => name.replace(/[^a-z0-9]/gi, '_').toUpperCase();

  const formatCurrency = (value: number | null | undefined): string => {
    if (value == null) return 'R$ 0,00';
    return new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(value);
  };

  const uploadFile = async (file: Blob, bucket: string, path: string): Promise<string | null> => {
    try {
        console.log(`[DEBUG] Iniciando Upload para ${bucket}/${path}`);
        const { error } = await supabase.storage.from(bucket).upload(path, file, { upsert: true });

        if (error) {
            console.warn(`[DEBUG] Falha no Upload (RLS/Permissão):`, error.message);
            return null;
        }

        const { data } = supabase.storage.from(bucket).getPublicUrl(path);
        console.log(`[DEBUG] Upload OK. URL Pública: ${data.publicUrl}`);
        return data.publicUrl;
    } catch (e: any) {
        console.error("[DEBUG] Erro Crítico Upload:", e.message);
        return null;
    }
  };

  // --- BUSCA DE IMAGENS (CORRIGIDO: DUPLICATAS) ---
  const fetchStampImagesMap = async (items: any[]) => {
    console.group('[DEBUG] fetchStampImagesMap');
    try {
        const rawRefs = items.map(i => i.stamp_ref);
        const stampRefs = [...new Set(rawRefs)].filter((r): r is string => {
            return typeof r === 'string' && r.trim().length > 0 && r.toUpperCase() !== 'AVULSO';
        });

        if (stampRefs.length === 0) {
            console.groupEnd();
            return {};
        }

        // BUSCA INDIVIDUAL
        const requests = stampRefs.map(async (ref) => {
            console.log(`[DEBUG] Buscando estampa: "${ref}" ...`);

            // CORREÇÃO: Usamos .limit(1) em vez de .maybeSingle()
            // Isso evita erro se houver múltiplas estampas com o mesmo nome.
            const { data, error } = await supabase
                .from('stamp_library')
                .select('name, image_url')
                .eq('name', ref)
                .limit(1);

            if (error) {
                console.error(`[DEBUG] ERRO AO BUSCAR "${ref}":`, error);
                return null;
            }

            // data agora é um array (devido à remoção de maybeSingle)
            if (!data || data.length === 0) {
                console.warn(`[DEBUG] Estampa não encontrada no banco: "${ref}"`);
                return null;
            }

            const stampData = data[0]; // Pega o primeiro encontrado
            console.log(`[DEBUG] Estampa encontrada: "${stampData.name}" -> URL: ${stampData.image_url}`);
            return stampData;
        });

        const results = await Promise.all(requests);
        const validResults = results.filter(r => r !== null);

        const map: Record<string, string> = {};

        // Conversão paralela
        await Promise.all(validResults.map(async (stamp: any) => {
            if (stamp.image_url) {
                 try {
                    const b64 = await imageToBase64(stamp.image_url);
                    if (b64.length > 1000) {
                        map[stamp.name] = b64;
                    }
                 } catch (err) {
                    console.error(`[DEBUG] Falha na conversão da estampa ${stamp.name}:`, err);
                }
            }
        }));

        console.log('[DEBUG] Mapa final de imagens carregadas:', Object.keys(map));
        console.groupEnd();
        return map;

    } catch (e) {
        console.error("[DEBUG] ERRO CRÍTICO GERAL NA BUSCA:", e);
        console.groupEnd();
        return {};
    }
  };

  // --- GERAR PDF ---
  const _createQuotePdfDoc = async (
    orderNumber: number | string,
    clientName: string,
    orderItems: any[],
    totalMeters: number,
    sellerName: string
  ) => {
      console.log('[DEBUG] Iniciando _createQuotePdfDoc');

      const stampImages = await fetchStampImagesMap(orderItems);

      const tableBody = orderItems.map((item, index) => {
        const total = (item.quantity || 0) * (item.valor_unitario || 0);

        const stampRef = item.stamp_ref || 'Lisa/Avulsa';
        const hasImage = !!(item.stamp_ref && stampImages[item.stamp_ref]);
        const imgData = hasImage ? stampImages[item.stamp_ref] : null;

        return {
          img: imgData,
          produto: item.fabric_type || 'Tecido',
          estampa: stampRef,
          qtd: `${item.quantity || 0} ${item.unit_of_measure || 'un'}`,
          rend: item.unit_of_measure === 'kg' ? `~${Number(item.quantity_meters || 0).toFixed(2)}m` : '-',
          unit: formatCurrency(item.valor_unitario),
          total: formatCurrency(total)
        };
      });

      const grandTotal = orderItems.reduce((acc, i) => acc + ((i.quantity||0) * (i.valor_unitario||0)), 0);

      const doc = new jsPDF();
      const pageWidth = doc.internal.pageSize.width;

      // --- HEADER ---
      try {
        const logoUrl = 'https://cdn.shopify.com/s/files/1/0661/4574/6991/files/Sem_nome_1080_x_800_px_1080_x_500_px_1080_x_400_px_1000_x_380_px_da020cf2-2bb9-4dac-8dd3-4548cfd2e5ae.png?v=1756811713';
        const logoPromise = imageToBase64(logoUrl);
        const logoBase64 = await logoPromise.catch(e => null);

        if (logoBase64 && logoBase64.length > 100) {
            doc.addImage(logoBase64, 'PNG', 15, 10, 45, 18);
        }
      } catch (e) {}

      // Dados da Empresa
      doc.setFont('helvetica', 'bold');
      doc.setFontSize(10);
      doc.setTextColor(50, 50, 50);
      doc.text("MR JACKY CONFECCOES LTDA", pageWidth - 15, 15, { align: 'right' });

      doc.setFont('helvetica', 'normal');
      doc.setFontSize(8);
      doc.setTextColor(100, 100, 100);
      doc.text("CNPJ: 20.631.721/0001-07", pageWidth - 15, 19, { align: 'right' });
      doc.text("Rua Luiz Montanhan, 1302 - Tiete/SP", pageWidth - 15, 23, { align: 'right' });
      doc.text("Contato: (15) 99847-8789 | financeiro@mrjacky.com", pageWidth - 15, 27, { align: 'right' });

      doc.setDrawColor(220, 220, 220);
      doc.setLineWidth(0.5);
      doc.line(15, 32, pageWidth - 15, 32);

      doc.setFont('helvetica', 'bold');
      doc.setFontSize(16);
      doc.setTextColor(30, 30, 30);
      doc.text('ORÇAMENTO DE VENDA', 15, 42);

      const displayOrderNum = String(orderNumber).includes('RASC') ? 'PRÉVIA' : `#${String(orderNumber).padStart(4, '0')}`;
      doc.setFontSize(14).setTextColor(80, 80, 80);
      doc.text(displayOrderNum, pageWidth - 15, 42, { align: 'right' });

      // --- BOX CLIENTE ---
      doc.setFillColor(248, 249, 250);
      doc.setDrawColor(230, 230, 230);
      doc.roundedRect(15, 50, 180, 28, 2, 2, 'FD');

      doc.setFont('helvetica', 'bold');
      doc.setFontSize(9);
      doc.setTextColor(100, 100, 110);
      doc.text("DESTINATÁRIO", 20, 57);

      doc.setFont('helvetica', 'bold');
      doc.setFontSize(11);
      doc.setTextColor(0, 0, 0);
      doc.text((clientName || 'Cliente').toUpperCase(), 20, 64);

      doc.setFont('helvetica', 'normal');
      doc.setFontSize(9);
      doc.setTextColor(80, 80, 80);
      doc.text(`Vendedor: ${sellerName || 'N/A'}`, 20, 70);
      doc.text(`Emissão: ${format(new Date(), 'dd/MM/yyyy')}`, 150, 70);

      // --- TEXTO ---
      doc.setFontSize(9);
      doc.setTextColor(60);
      const introText = `Este documento detalha os produtos e serviços solicitados por ${clientName}. ` +
                        `Por favor, confira as estampas (imagens ilustrativas), quantidades e valores abaixo.`;
      doc.text(doc.splitTextToSize(introText, 180), 15, 88);

      // --- TABELA ---
      autoTable(doc, {
        startY: 98,
        head: [['Ref.', 'Produto / Base', 'Estampa / Cor', 'Qtd.', 'Rend.', 'Unit.', 'Total']],
        body: tableBody.map(i => ['', i.produto, i.estampa, i.qtd, i.rend, i.unit, i.total]),

        theme: 'grid',
        styles: {
            fontSize: 8,
            cellPadding: 3,
            valign: 'middle',
            overflow: 'linebreak',
            lineColor: [230, 230, 230],
            lineWidth: 0.1,
            minCellHeight: 18
        },
        headStyles: {
            fillColor: [40, 40, 45],
            textColor: 255,
            fontStyle: 'bold',
            halign: 'center'
        },
        columnStyles: {
            0: { cellWidth: 18 },
            1: { cellWidth: 'auto', fontStyle: 'bold' },
            2: { cellWidth: 35 },
            3: { cellWidth: 20, halign: 'center' },
            4: { cellWidth: 20, halign: 'center' },
            5: { cellWidth: 25, halign: 'right' },
            6: { cellWidth: 25, fontStyle: 'bold', halign: 'right' }
        },

        didDrawCell: (data) => {
            if (data.section === 'body' && data.column.index === 0) {
                const rowData = tableBody[data.row.index];
                if (rowData && rowData.img) {
                    const dim = 14;
                    const x = data.cell.x + (data.cell.width - dim) / 2;
                    const y = data.cell.y + (data.cell.height - dim) / 2;
                    try {
                        doc.addImage(rowData.img, 'PNG', x, y, dim, dim);
                    } catch (err) {}
                }
            }
        },

        foot: [['', '', 'TOTAIS:', `${Number(totalMeters).toFixed(2)}m`, '', '', formatCurrency(grandTotal)]],
        footStyles: { fillColor: [245, 245, 245], textColor: 0, fontStyle: 'bold', fontSize: 10, halign: 'right' }
      });

      // --- ASSINATURA ---
      const finalY = (doc as any).lastAutoTable.finalY + 20;
      const signatureY = doc.internal.pageSize.height - 50;

      if (finalY > signatureY) doc.addPage();

      const sigY = finalY > signatureY ? 50 : signatureY;

      doc.setDrawColor(150);
      doc.line(60, sigY, 150, sigY);
      doc.setFontSize(9);
      doc.setTextColor(0);
      doc.text("De acordo: __________________________________________", 105, sigY + 5, { align: 'center' });
      doc.setFontSize(10).setFont('helvetica', 'bold');
      doc.text(clientName || 'Assinatura', 105, sigY + 11, { align: 'center' });

      // --- PAGINAÇÃO ---
      const pageCount = (doc as any).internal.getNumberOfPages();
      for (let i = 1; i <= pageCount; i++) {
        doc.setPage(i);
        doc.setFontSize(7).setTextColor(150);
        doc.text(`Documento gerado digitalmente em ${format(new Date(), 'dd/MM/yyyy HH:mm')} via MJProcess`, 15, doc.internal.pageSize.height - 10);
        doc.text(`Página ${i} de ${pageCount}`, pageWidth - 15, doc.internal.pageSize.height - 10, { align: 'right' });
      }

      console.log('[DEBUG] PDF gerado com sucesso.');
      return doc;
  };

  // --- 1. FUNÇÃO PÚBLICA ---
  const generateQuoteAndUploadPdf = async (
    orderNumber: number,
    orderId: string,
    clientName: string,
    orderItems: any[],
    totalMeters: number,
    sellerName: string
  ) => {
    isGeneratingPdf.value = true;
    try {
      console.log('[DEBUG] --- START GENERATE PDF ---');
      const doc = await _createQuotePdfDoc(orderNumber, clientName, orderItems, totalMeters, sellerName);
      const fileName = `Orcamento_${String(orderNumber).padStart(4,'0')}_${sanitizeName(clientName)}.pdf`;
      const pdfBlob = doc.output('blob');

      // 1. Download Local
      const url = URL.createObjectURL(pdfBlob);
      const a = document.createElement('a');
      a.href = url;
      a.download = fileName;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);

      // 2. Upload
      const pdfPath = `sales_orders/${fileName}`;
      const publicUrl = await uploadFile(pdfBlob, 'sales-orders', pdfPath);

      if (publicUrl) {
          await supabase.from('orders').update({ sales_order_pdf_url: publicUrl }).eq('id', orderId);
          appStore.showSnackbar('Orçamento baixado e salvo no histórico.', 'success');
      } else {
          appStore.showSnackbar('Orçamento baixado localmente (Erro ao salvar no histórico).', 'warning');
      }

    } catch (error: any) {
      console.error("[DEBUG] Erro Fatal Generate:", error);
      appStore.showSnackbar("Erro ao gerar PDF: " + error.message, "error");
    } finally {
      isGeneratingPdf.value = false;
      console.log('[DEBUG] --- END GENERATE PDF ---');
    }
  };

  // --- 2. PREVIEW ---
  const previewQuotePdf = async (draftData: any, clientName: string, sellerName: string) => {
      isGeneratingPdf.value = true;
      try {
          console.log('[DEBUG] --- START PREVIEW ---');
          const orderItems = draftData.orderItems || [];
          const totalMeters = orderItems.reduce((acc: number, i: any) => acc + (Number(i.quantity_meters) || Number(i.quantity) || 0), 0);
          const orderNumber = draftData.reserved_order_number || 'RASCUNHO';

          const doc = await _createQuotePdfDoc(orderNumber, clientName, orderItems, totalMeters, sellerName);

          const pdfBlob = doc.output('blob');
          const url = URL.createObjectURL(pdfBlob);
          window.open(url, '_blank');

      } catch (error: any) {
          console.error("[DEBUG] Preview Error:", error);
          appStore.showSnackbar("Erro ao gerar preview: " + error.message, "error");
      } finally {
          isGeneratingPdf.value = false;
          console.log('[DEBUG] --- END PREVIEW ---');
      }
  };

  // --- HEADER AUXILIAR ---
  const addHeader = async (doc: jsPDF, orderNumber: any, title: string) => {
      const pageWidth = doc.internal.pageSize.width;
      try {
        const logoUrl = 'https://cdn.shopify.com/s/files/1/0661/4574/6991/files/Sem_nome_1080_x_800_px_1080_x_500_px_1080_x_400_px_1000_x_380_px_da020cf2-2bb9-4dac-8dd3-4548cfd2e5ae.png?v=1756811713';
        const logoBase64 = await imageToBase64(logoUrl);
        if(logoBase64 && logoBase64.length > 100) doc.addImage(logoBase64, 'PNG', 15, 10, 40, 16);
      } catch (e) {}

      doc.setFont('helvetica', 'bold');
      doc.setFontSize(14);
      doc.text(title.toUpperCase(), pageWidth - 15, 20, { align: 'right' });
      doc.setFontSize(10).setTextColor(100);
      doc.text(`Ref: #${String(orderNumber).padStart(4,'0')}`, pageWidth - 15, 26, { align: 'right' });
      doc.line(15, 30, pageWidth - 15, 30);
  };

  const addFooter = (doc: jsPDF) => {
      doc.setFontSize(8).setTextColor(150);
      doc.text(`Gerado por MJProcess em ${format(new Date(), 'dd/MM/yyyy HH:mm')}`, 15, doc.internal.pageSize.height - 10);
  };

  // --- RECIBO ---
  const generateReadyDeliveryReceiptPdf = async (orderNumber: number, client: any, downPaymentValue: number, paymentMethod: string, items: any[]) => {
    isGeneratingPdf.value = true;
    try {
      const doc = new jsPDF();
      const orderNumberText = String(orderNumber).padStart(4, '0');

      await addHeader(doc, orderNumber, 'Recibo de Pagamento');

      doc.setFontSize(10).setTextColor(0);
      doc.text(
          `A MR JACKY confirma o recebimento de ${formatCurrency(downPaymentValue)} referente ao pedido #${orderNumberText}.`,
          15, 50
      );

      const body = items.map(i => [i.fabric_type, i.stamp_ref, `${i.quantity}${i.unit_of_measure}`, formatCurrency(i.total_value_items)]);
      autoTable(doc, {
          startY: 60,
          head: [['Produto', 'Estampa', 'Qtd', 'Valor']],
          body: body,
          theme: 'striped'
      });

      const sigY = (doc as any).lastAutoTable.finalY + 30;
      doc.line(20, sigY, 90, sigY);
      doc.line(120, sigY, 190, sigY);
      doc.setFontSize(8);
      doc.text("MR JACKY", 55, sigY + 5, { align: 'center' });
      doc.text("CLIENTE", 155, sigY + 5, { align: 'center' });

      addFooter(doc);

      const blob = doc.output('blob');
      const fileName = `Recibo_${orderNumberText}.pdf`;
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = fileName;
      a.click();

      // Upload Recibo
      const path = `recibos/${fileName}`;
      await uploadFile(blob, 'recibos', path);

    } catch (e: any) {
        appStore.showSnackbar('Erro ao gerar recibo: ' + e.message, 'error');
    } finally {
        isGeneratingPdf.value = false;
    }
  };

  const generateDraftReceiptPdf = generateReadyDeliveryReceiptPdf;

  return {
    isGeneratingPdf,
    formatCurrency,
    generateQuoteAndUploadPdf,
    previewQuotePdf,
    generateReadyDeliveryReceiptPdf,
    generateDraftReceiptPdf
  };
}
