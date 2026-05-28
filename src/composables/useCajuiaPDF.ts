import { ref } from 'vue';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import QRCode from 'qrcode';
import { format } from 'date-fns';
import { supabase } from '@/api/supabase';
import { useAppStore } from '@/stores/app';
import { useUserStore } from '@/stores/user';
// @ts-ignore
import cajuiaLogoPath from '@/assets/logocajuia.png';

export type PrintFormat = 'a4' | '80mm' | '58mm';

export function useCajuiaPDF() {
  const isGenerating = ref(false);
  const appStore = useAppStore();
  const userStore = useUserStore();

  const COMPANY_INFO = {
    name: "CAJUIA STORE",
    cnpj: "20.631.721/0001-07",
    address: "R. João Teodoro, 1200 - Shopping Total Brás - Loja 65 T",
    contact: "(11) 93313-5371"
  };

  const formatCurrency = (value: number) =>
    new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(value || 0);

  const loadImageBase64 = (url: string): Promise<string> => {
    return new Promise((resolve) => {
      const img = new Image();
      img.crossOrigin = 'Anonymous';
      img.onload = () => {
        const canvas = document.createElement('canvas');
        canvas.width = img.width;
        canvas.height = img.height;
        const ctx = canvas.getContext('2d');
        if (ctx) {
          ctx.drawImage(img, 0, 0);
          resolve(canvas.toDataURL('image/png'));
        } else {
          resolve('');
        }
      };
      img.onerror = () => resolve('');
      img.src = url;
    });
  };

  // --- SALVAR NA NUVEM (Bucket 'cajuia') ---
  const saveReportToSystem = async (blob: Blob, fileName: string, title: string, category: string) => {
    try {
      const userId = userStore.user?.id;
      if (!userId) return null;

      const filePath = `${userId}/${Date.now()}_${fileName}`;
      const { error: uploadError } = await supabase.storage
        .from('cajuia')
        .upload(filePath, blob, { contentType: 'application/pdf', upsert: true });

      if (uploadError) throw uploadError;

      const { data: urlData } = supabase.storage
        .from('cajuia')
        .getPublicUrl(filePath);

      await supabase.from('user_reports').insert({
        user_id: userId,
        title: title,
        file_url: urlData.publicUrl,
        file_path: filePath,
        category: category,
        file_type: 'application/pdf'
      });

      return urlData.publicUrl;
    } catch (e) {
      console.error("Erro ao salvar no sistema:", e);
      return null;
    }
  };

  // --- NOVO: RECIBO DE MOVIMENTAÇÃO (SANGRIA/SUPRIMENTO) ---
  const generateCashFlowReceipt = async (type: 'bleed' | 'supply', amount: number, description: string) => {
    isGenerating.value = true;
    try {
        const doc = new jsPDF();
        const today = new Date();
        const dateStr = format(today, "dd/MM/yyyy HH:mm");
        const title = type === 'bleed' ? 'COMPROVANTE DE SANGRIA' : 'COMPROVANTE DE SUPRIMENTO';
        const color = type === 'bleed' ? [200, 0, 0] : [0, 150, 0]; // Vermelho ou Verde

        const logoBase64 = await loadImageBase64(cajuiaLogoPath);
        if (logoBase64) doc.addImage(logoBase64, 'PNG', 14, 10, 25, 25);

        doc.setFontSize(18).setFont('helvetica', 'bold').setTextColor(0);
        doc.text(title, 105, 25, { align: 'center' });

        doc.setFontSize(10).setFont('helvetica', 'normal').setTextColor(100);
        doc.text(`Data: ${dateStr}`, 105, 32, { align: 'center' });
        doc.text(`Responsável: ${userStore.user?.email || 'Operador'}`, 105, 37, { align: 'center' });

        doc.setDrawColor(color[0], color[1], color[2]);
        doc.setLineWidth(1);
        doc.setFillColor(250, 250, 250);
        doc.roundedRect(60, 50, 90, 30, 3, 3, 'FD');

        doc.setFontSize(12).setTextColor(80);
        doc.text("VALOR MOVIMENTADO", 105, 60, { align: 'center' });

        doc.setFontSize(22).setFont('helvetica', 'bold').setTextColor(color[0], color[1], color[2]);
        doc.text(formatCurrency(amount), 105, 73, { align: 'center' });

        doc.setFontSize(12).setTextColor(0).setFont('helvetica', 'bold');
        doc.text("Justificativa / Origem:", 14, 100);
        doc.setFont('helvetica', 'normal');
        doc.text(description, 14, 108);

        doc.setLineWidth(0.5);
        doc.setDrawColor(0);
        doc.line(60, 160, 150, 160);
        doc.setFontSize(10).text("Assinatura do Responsável", 105, 165, { align: 'center' });

        const filename = `${type}_${format(today, 'yyyyMMdd_HHmmss')}.pdf`;
        const blob = doc.output('blob');
        await saveReportToSystem(blob, filename, `${title} - ${formatCurrency(amount)}`, 'Fechamentos');
        doc.save(filename);

        appStore.showSnackbar('Comprovante gerado!', 'success');

    } catch (e) {
        console.error(e);
        appStore.showSnackbar('Erro ao gerar comprovante.', 'error');
    } finally {
        isGenerating.value = false;
    }
  };

  // --- 1. RELATÓRIO DE FECHAMENTO DE CAIXA ---
  const generateAndSaveDailyReport = async (dailyTotals: any, paymentMethods: Record<string, number>) => {
    isGenerating.value = true;
    try {
      const doc = new jsPDF();
      const today = new Date();
      const dateStr = format(today, "dd/MM/yyyy HH:mm");
      const safeDate = format(today, 'yyyyMMdd_HHmm');
      const filename = `Fechamento_${safeDate}.pdf`;

      doc.setFillColor(20, 20, 25);
      doc.rect(0, 0, 210, 40, 'F');

      const logoBase64 = await loadImageBase64(cajuiaLogoPath);
      if (logoBase64) {
          doc.addImage(logoBase64, 'PNG', 14, 8, 25, 25);
      }

      doc.setTextColor(255, 255, 255);
      doc.setFontSize(22);
      doc.setFont('helvetica', 'bold');
      doc.text("FECHAMENTO DE CAIXA", 45, 20);

      doc.setFontSize(10);
      doc.setFont('helvetica', 'normal');
      doc.text("RELATÓRIO FINANCEIRO DIÁRIO", 45, 26);

      doc.setFontSize(9);
      doc.setTextColor(200, 200, 200);
      doc.text(`Gerado em: ${dateStr}`, 195, 18, { align: 'right' });
      doc.text(`Resp: ${userStore.user?.email || 'Admin'}`, 195, 24, { align: 'right' });

      let yPos = 55;

      doc.setFillColor(232, 245, 233);
      doc.setDrawColor(76, 175, 80);
      doc.roundedRect(14, yPos, 85, 25, 3, 3, 'FD');

      doc.setTextColor(60, 60, 60);
      doc.setFontSize(9);
      doc.text("TOTAL BRUTO (DIA)", 20, yPos + 8);

      doc.setTextColor(27, 94, 32);
      doc.setFontSize(16);
      doc.setFont('helvetica', 'bold');
      doc.text(formatCurrency(dailyTotals.total), 20, yPos + 19);

      doc.setFillColor(245, 245, 245);
      doc.setDrawColor(189, 189, 189);
      doc.roundedRect(105, yPos, 85, 25, 3, 3, 'FD');

      doc.setTextColor(60, 60, 60);
      doc.setFontSize(9);
      doc.setFont('helvetica', 'normal');
      doc.text("PEDIDOS REALIZADOS", 111, yPos + 8);

      doc.setTextColor(33, 33, 33);
      doc.setFontSize(16);
      doc.setFont('helvetica', 'bold');
      doc.text(String(dailyTotals.count), 111, yPos + 19);

      const tableBody = Object.entries(paymentMethods).map(([method, value]) => [
        method.toUpperCase(),
        formatCurrency(value as number)
      ]);

      autoTable(doc, {
        startY: yPos + 35,
        head: [['FORMA DE PAGAMENTO', 'VALOR TOTAL']],
        body: tableBody,
        theme: 'grid',
        headStyles: {
            fillColor: [40, 40, 45],
            textColor: 255,
            fontStyle: 'bold',
            halign: 'left'
        },
        columnStyles: {
            0: { cellWidth: 'auto' },
            1: { cellWidth: 60, halign: 'right', fontStyle: 'bold' }
        },
        foot: [['TOTAL GERAL', formatCurrency(dailyTotals.total)]],
        footStyles: {
            fillColor: [230, 230, 230],
            textColor: 0,
            fontStyle: 'bold',
            halign: 'right'
        },
        styles: { fontSize: 10, cellPadding: 6 }
      });

      const pageCount = (doc as any).internal.getNumberOfPages();
      for (let i = 1; i <= pageCount; i++) {
        doc.setPage(i);
        doc.setFontSize(8);
        doc.setTextColor(150);
        doc.text(`Cajuia System - Página ${i}/${pageCount}`, 105, 290, { align: 'center' });
      }

      const pdfBlob = doc.output('blob');
      await saveReportToSystem(pdfBlob, filename, `Fechamento - ${dateStr}`, 'Fechamentos');
      doc.save(filename);

      return true;

    } catch (error) {
      console.error("Erro ao gerar fechamento:", error);
      throw error;
    } finally {
      isGenerating.value = false;
    }
  };

  // --- LÓGICA TÉRMICA (CUPOM) ---
  const generateThermalReceipt = async (
    doc: jsPDF,
    paperWidth: number,
    orderNumber: number,
    client: any,
    items: any[],
    paymentMethodText: string,
    totalValue: number,
    extraData: any,
    logoBase64: string,
    qrCodeDataUrl: string
  ) => {
    const margin = paperWidth === 58 ? 2 : 4;
    const usableWidth = paperWidth - (margin * 2);
    const centerX = paperWidth / 2;
    let y = 5;

    // Fontes Base
    const fontSizeHeader = paperWidth === 58 ? 9 : 10;
    const fontSizeNormal = paperWidth === 58 ? 7 : 8;
    const fontSizeSmall = paperWidth === 58 ? 6 : 7;

    // --- CABEÇALHO ---
    if (logoBase64) {
        const imgWidth = paperWidth === 58 ? 15 : 20;
        doc.addImage(logoBase64, 'PNG', centerX - (imgWidth / 2), y, imgWidth, imgWidth);
        y += imgWidth + 2;
    }

    doc.setFont('helvetica', 'bold').setFontSize(fontSizeHeader).setTextColor(0, 0, 0);
    doc.text(COMPANY_INFO.name, centerX, y, { align: 'center' });
    y += 4;

    doc.setFont('helvetica', 'normal').setFontSize(fontSizeSmall).setTextColor(50, 50, 50);
    const splitAddr = doc.splitTextToSize(COMPANY_INFO.address, usableWidth);
    doc.text(splitAddr, centerX, y, { align: 'center' });
    y += (splitAddr.length * 3) + 2;

    doc.text(`CNPJ: ${COMPANY_INFO.cnpj}`, centerX, y, { align: 'center' });
    y += 3;
    doc.text(`Tel: ${COMPANY_INFO.contact}`, centerX, y, { align: 'center' });
    y += 5;

    // --- INFO DO PEDIDO ---
    doc.setLineWidth(0.2).line(margin, y, paperWidth - margin, y);
    y += 4;

    doc.setFontSize(fontSizeNormal).setFont('helvetica', 'bold');
    doc.text(`PEDIDO #${String(orderNumber).padStart(4, '0')}`, centerX, y, { align: 'center' });
    y += 4;
    doc.setFont('helvetica', 'normal').setFontSize(fontSizeSmall);
    doc.text(format(new Date(), "dd/MM/yyyy HH:mm"), centerX, y, { align: 'center' });
    y += 5;

    doc.setLineWidth(0.2).line(margin, y, paperWidth - margin, y);
    y += 4;

    // --- CLIENTE ---
    doc.setFont('helvetica', 'normal').setFontSize(fontSizeNormal);
    doc.text("Cliente:", margin, y);
    const clientName = (client.nome || client.name || "Consumidor").substring(0, paperWidth === 58 ? 20 : 30);
    doc.text(clientName, paperWidth - margin, y, { align: 'right' });
    y += 4;

    if (extraData?.cpfNota || client.cpf_cnpj) {
        doc.text("CPF/CNPJ:", margin, y);
        doc.text(extraData?.cpfNota || client.cpf_cnpj, paperWidth - margin, y, { align: 'right' });
        y += 4;
    }

    y += 2;

    // --- ITENS ---
    doc.setFont('helvetica', 'bold').text("ITEM", margin, y);
    doc.text("QTD x UNIT", centerX, y, { align: 'center' });
    doc.text("TOTAL", paperWidth - margin, y, { align: 'right' });
    y += 2;
    doc.line(margin, y, paperWidth - margin, y); // Linha fina
    y += 4;

    doc.setFont('helvetica', 'normal');

    items.forEach(item => {
        const name = (item.product_name || item.name || 'Item').substring(0, paperWidth === 58 ? 18 : 25);
        const qty = item.quantity;
        const price = item.unit_price || item.price;
        const total = item.total_price || (qty * price);

        doc.text(name, margin, y);
        y += 3;

        doc.setFontSize(fontSizeSmall);
        doc.text(`${qty} x ${formatCurrency(price)}`, margin + 2, y);
        doc.setFontSize(fontSizeNormal);
        doc.text(formatCurrency(total), paperWidth - margin, y, { align: 'right' });
        y += 4;
    });

    y += 2;
    doc.setLineWidth(0.2).line(margin, y, paperWidth - margin, y);
    y += 5;

    // --- TOTAIS ---
    const drawTotalLine = (label: string, value: string, bold = false) => {
        doc.setFont('helvetica', bold ? 'bold' : 'normal');
        if(bold) doc.setFontSize(fontSizeHeader);
        else doc.setFontSize(fontSizeNormal);

        doc.text(label, margin, y);
        doc.text(value, paperWidth - margin, y, { align: 'right' });
        y += bold ? 6 : 4;
    };

    drawTotalLine("Subtotal", formatCurrency(totalValue + (extraData?.discount || 0)));

    if (extraData?.discount && extraData.discount > 0) {
        drawTotalLine("Desconto", `-${formatCurrency(extraData.discount)}`);
    }

    drawTotalLine("TOTAL", formatCurrency(totalValue), true);

    y += 2;
    doc.setFont('helvetica', 'normal').setFontSize(fontSizeSmall);
    const splitPayment = doc.splitTextToSize(`Pagamento: ${paymentMethodText}`, usableWidth);
    doc.text(splitPayment, margin, y);
    y += (splitPayment.length * 3) + 4;

    if (extraData?.change && extraData.change > 0) {
        doc.text(`Troco: ${formatCurrency(extraData.change)}`, margin, y);
        y += 4;
    }

    // --- RODAPÉ / QR ---
    y += 4;
    if (qrCodeDataUrl) {
        const qrSize = paperWidth === 58 ? 20 : 25;
        doc.addImage(qrCodeDataUrl, 'PNG', centerX - (qrSize / 2), y, qrSize, qrSize);
        y += qrSize + 2;
    }

    doc.setFontSize(6).setTextColor(100);
    doc.text("Documento sem valor fiscal", centerX, y, { align: 'center' });
    y += 3;
    doc.text("Volte Sempre!", centerX, y, { align: 'center' });
  };

  // --- LÓGICA A4 ORIGINAL ---
  const generateA4Receipt = async (
    doc: jsPDF,
    orderNumber: number,
    client: any,
    items: any[],
    paymentMethodText: string,
    totalValue: number,
    extraData: any,
    logoBase64: string,
    qrCodeDataUrl: string,
    isPreview: boolean
  ) => {
      const pageWidth = doc.internal.pageSize.width;
      const pageHeight = doc.internal.pageSize.height;
      const margin = 12;
      const useFullPagePerCopy = items.length > 10;

      const drawReceiptCopy = (startY: number, viaLabel: string) => {
          let currentY = startY;
          const headerHeight = 35;
          doc.setFillColor(20, 20, 25);
          doc.rect(0, currentY, pageWidth, headerHeight, 'F');

          if (logoBase64) {
             const imgProps = doc.getImageProperties(logoBase64);
             const imgWidth = 28;
             const imgHeight = (imgProps.height * imgWidth) / imgProps.width;
             doc.addImage(logoBase64, 'PNG', margin, currentY + 5, imgWidth, imgHeight);
          }

          doc.setFont('helvetica', 'bold').setFontSize(16).setTextColor(255, 255, 255);
          doc.text(COMPANY_INFO.name, margin + 35, currentY + 10);

          doc.setFontSize(8).setFont('helvetica', 'normal').setTextColor(200, 200, 200);
          doc.text(COMPANY_INFO.address, margin + 35, currentY + 16);
          doc.text(`${COMPANY_INFO.cnpj}  •  ${COMPANY_INFO.contact}`, margin + 35, currentY + 21);

          doc.setFont('helvetica', 'bold').setFontSize(24).setTextColor(255, 255, 255);
          doc.text(`#${String(orderNumber).padStart(4, '0')}`, pageWidth - margin, currentY + 12, { align: 'right' });

          doc.setFontSize(9).setTextColor(150, 150, 150);
          doc.text(format(new Date(), "dd/MM/yyyy 'às' HH:mm"), pageWidth - margin, currentY + 18, { align: 'right' });

          doc.setFillColor(255, 255, 255);
          doc.roundedRect(pageWidth - margin - 28, currentY + 22, 28, 6, 1, 1, 'F');
          doc.setTextColor(0, 0, 0).setFontSize(7).setFont('helvetica', 'bold');
          doc.text(viaLabel.toUpperCase(), pageWidth - margin - 14, currentY + 26, { align: 'center' });

          if(isPreview) {
              doc.saveGraphicsState();
              doc.setGState(new doc.GState({ opacity: 0.08 }));
              doc.setTextColor(0, 0, 0);
              doc.setFontSize(50);
              doc.text("ROMANEIO", pageWidth / 2, currentY + 80, { align: 'center', angle: 45 });
              doc.restoreGraphicsState();
          }

          currentY += headerHeight + 8;

          // Cliente
          doc.setFillColor(250, 250, 252);
          doc.setDrawColor(230, 230, 230);
          doc.roundedRect(margin, currentY, pageWidth - (margin * 2), 18, 2, 2, 'FD');

          const col1 = margin + 5;
          const col2 = margin + 90;
          const col3 = margin + 140;

          doc.setFontSize(7).setTextColor(120, 120, 120).setFont('helvetica', 'bold');
          doc.text("CLIENTE", col1, currentY + 5);
          doc.text("CPF / CNPJ", col2, currentY + 5);
          doc.text("VENDEDOR", col3, currentY + 5);

          doc.setFontSize(9).setTextColor(30, 30, 30).setFont('helvetica', 'bold');
          const clientName = (client.nome || client.name || "Consumidor").substring(0,35);
          doc.text(clientName, col1, currentY + 11);

          const documentNumber = extraData?.cpfNota || client.cpf_cnpj || client.cpf || client.cnpj || "---";
          doc.text(documentNumber, col2, currentY + 11);

          const sellerName = extraData?.sellerName || userStore.profile?.full_name?.split(' ')[0] || "Loja";
          doc.text(sellerName, col3, currentY + 11);

          currentY += 24;

          // Tabela A4
          const tableBody = items.map(item => [
            item.product_name || item.name || 'Item Diverso',
            item.quantity + ' un',
            formatCurrency(item.unit_price || item.price),
            formatCurrency(item.total_price || (item.quantity * (item.unit_price || item.price)))
          ]);

          autoTable(doc, {
            startY: currentY,
            head: [['DESCRIÇÃO DO PRODUTO', 'QTD', 'V. UNIT', 'TOTAL']],
            body: tableBody,
            theme: 'striped',
            styles: { fontSize: 9, cellPadding: 3, textColor: [40, 40, 40], font: 'helvetica', lineColor: [240, 240, 240], lineWidth: 0.1 },
            headStyles: { fillColor: [245, 245, 245], textColor: [80, 80, 80], fontStyle: 'bold', lineWidth: 0 },
            alternateRowStyles: { fillColor: [252, 252, 252] },
            columnStyles: {
                0: { cellWidth: 'auto' },
                1: { halign: 'center', cellWidth: 20 },
                2: { halign: 'right', cellWidth: 30 },
                3: { halign: 'right', cellWidth: 30, fontStyle: 'bold' }
            },
            margin: { left: margin, right: margin },
            pageBreak: useFullPagePerCopy ? 'auto' : 'avoid',
          });

          let finalY = (doc as any).lastAutoTable.finalY + 8;

          // Totais A4
          doc.setDrawColor(220, 220, 220);
          doc.setLineWidth(0.5);
          doc.line(margin, finalY, pageWidth - margin, finalY);
          finalY += 8;

          const rightColX = pageWidth - margin - 80;

          doc.setFontSize(9).setTextColor(100, 100, 100).setFont('helvetica', 'normal');
          doc.text("Subtotal", rightColX, finalY);
          doc.text(formatCurrency(totalValue + (extraData?.discount || 0)), pageWidth - margin, finalY, { align: 'right' });
          finalY += 6;

          if(extraData?.discount && extraData.discount > 0) {
             doc.setTextColor(220, 53, 69);
             doc.text("Desconto Aplicado", rightColX, finalY);
             doc.text(`-${formatCurrency(extraData.discount)}`, pageWidth - margin, finalY, { align: 'right' });
             finalY += 6;
          }

          finalY += 2;
          doc.setFontSize(14).setTextColor(0, 0, 0).setFont('helvetica', 'bold');
          doc.text("TOTAL A PAGAR", rightColX, finalY);
          doc.text(formatCurrency(totalValue), pageWidth - margin, finalY, { align: 'right' });
          finalY += 8;

          if (extraData?.change && extraData.change > 0) {
              doc.setFontSize(10).setTextColor(40, 167, 69);
              doc.setFont('helvetica', 'normal');
              doc.text("Troco", rightColX, finalY);
              doc.text(formatCurrency(extraData.change), pageWidth - margin, finalY, { align: 'right' });
          }

          // Pagamento
          const paymentY = (doc as any).lastAutoTable.finalY + 16;
          doc.setFillColor(248, 248, 248);
          doc.roundedRect(margin, paymentY - 6, 85, 28, 2, 2, 'F');

          doc.setFontSize(8).setTextColor(120, 120, 120).setFont('helvetica', 'bold');
          doc.text("FORMA(S) DE PAGAMENTO", margin + 4, paymentY);
          doc.setFontSize(9).setTextColor(0, 0, 0).setFont('helvetica', 'normal');
          const splitPayment = doc.splitTextToSize(paymentMethodText, 75);
          doc.text(splitPayment, margin + 4, paymentY + 6);

          // Footer Text
          const footerTextY = paymentY + 35;
          doc.setFont('helvetica', 'normal').setFontSize(9).setTextColor(80, 80, 80);
          const receiptText = `A CAJUIA STORE reconhece o recebimento da importância de ${formatCurrency(totalValue)}, pago por ${clientName} ${documentNumber && documentNumber !== '---' ? '(Doc: ' + documentNumber + ')' : ''}, em ${format(new Date(), 'dd/MM/yyyy')}, referente ao Pedido #${orderNumber}.`;

          const splitReceiptText = doc.splitTextToSize(receiptText, pageWidth - 2 * margin - 30);
          doc.text(splitReceiptText, margin, footerTextY);

          if (!isPreview) {
             doc.addImage(qrCodeDataUrl, 'PNG', pageWidth - margin - 20, paymentY + 15, 20, 20);
             doc.setFontSize(6).setTextColor(150);
             doc.text("Ver Online", pageWidth - margin - 10, paymentY + 38, { align: 'center' });
          }

          const bottomY = paymentY + 55;
          doc.setFontSize(7).setTextColor(180);
          doc.text("Obrigado pela preferência! Volte sempre.", pageWidth / 2, bottomY, { align: 'center' });
      };

      if (useFullPagePerCopy) {
          drawReceiptCopy(0, "VIA DA LOJA");
          doc.addPage();
          drawReceiptCopy(0, "VIA DO CLIENTE");
      } else {
          const midPoint = pageHeight / 2;
          drawReceiptCopy(0, "VIA DA LOJA");
          doc.setDrawColor(200, 200, 200);
          doc.setLineDashPattern([2, 2], 0);
          doc.line(10, midPoint, pageWidth - 10, midPoint);
          doc.setLineDashPattern([], 0);
          doc.setFontSize(12).setTextColor(150).text("✂", 5, midPoint + 1.5);
          drawReceiptCopy(midPoint, "VIA DO CLIENTE");
      }
  };

  // --- 2. RECIBO DE PEDIDO (DISPATCHER) ---
  const generateOrderReceipt = async (
    orderId: string,
    orderNumber: number,
    client: any,
    items: any[],
    paymentMethodText: string,
    totalValue: number,
    extraData?: { cpfNota?: string; discount?: number; change?: number; sellerName?: string },
    formatType: PrintFormat = 'a4'
  ) => {
    isGenerating.value = true;
    try {
      const isPreview = orderId === 'PREVIEW';
      const pdfFileName = `Pedido_${String(orderNumber).padStart(4, '0')}${isPreview ? '_PREVIEW' : ''}.pdf`;

      let publicUrl = `https://cajuia.com/orders/${orderNumber}`;
      if(orderId && !isPreview) {
          const { data } = supabase.storage.from('cajuia').getPublicUrl(pdfFileName);
          if(data) publicUrl = data.publicUrl;
      }

      const qrCodeDataUrl = await QRCode.toDataURL(publicUrl, { width: 100, margin: 1 });
      const logoBase64 = await loadImageBase64(cajuiaLogoPath);

      let doc: jsPDF;

      if (formatType === 'a4') {
          doc = new jsPDF('p', 'mm', 'a4');
          await generateA4Receipt(doc, orderNumber, client, items, paymentMethodText, totalValue, extraData, logoBase64, qrCodeDataUrl, isPreview);
      } else {
          const paperWidth = formatType === '80mm' ? 80 : 58;
          const estimatedHeight = 130 + (items.length * 8);
          doc = new jsPDF({ orientation: 'p', unit: 'mm', format: [paperWidth, estimatedHeight] });
          await generateThermalReceipt(doc, paperWidth, orderNumber, client, items, paymentMethodText, totalValue, extraData, logoBase64, qrCodeDataUrl);
      }

      const pdfBlob = doc.output('blob');

      if (!isPreview && orderId) {
          const url = await saveReportToSystem(pdfBlob, pdfFileName, `Recibo #${orderNumber} (${formatType})`, 'Recibos');
          if (url) await supabase.from('cajuia_orders').update({ sales_order_pdf_url: url }).eq('id', orderId);
      }

      const pdfUrl = URL.createObjectURL(pdfBlob);
      window.open(pdfUrl, '_blank');

      appStore.showSnackbar('Recibo gerado com sucesso!', 'success');

    } catch (error) {
      console.error(error);
      appStore.showSnackbar('Erro ao gerar recibo.', 'error');
    } finally {
      isGenerating.value = false;
    }
  };

  // --- 3. FICHA DE CLIENTE ---
  const generateClientReport = async (client: any, historyOrders: any[]) => {
    isGenerating.value = true;
    try {
        const doc = new jsPDF();
        const filename = `Ficha_${client.name || 'Cliente'}.pdf`;

        const logoBase64 = await loadImageBase64(cajuiaLogoPath);
        if (logoBase64) doc.addImage(logoBase64, 'PNG', 14, 10, 25, 25);

        doc.setFontSize(18).text(`Ficha Cadastral`, 14, 45);
        doc.setFontSize(12).text(client.name || 'Cliente', 14, 52);

        const tableBody = historyOrders.map(o => [
            format(new Date(o.created_at), 'dd/MM/yyyy'),
            `#${o.order_number}`,
            o.status || '-',
            formatCurrency(o.total_value)
        ]);

        autoTable(doc, {
            startY: 70,
            head: [['Data', 'Pedido', 'Status', 'Valor']],
            body: tableBody
        });

        const blob = doc.output('blob');
        await saveReportToSystem(blob, filename, `Ficha: ${client.name}`, 'Clientes');
        doc.save(filename);
        appStore.showSnackbar('Ficha salva no Admin!', 'success');
    } catch(e) {
        console.error(e);
        appStore.showSnackbar('Erro ao gerar ficha.', 'error');
    } finally {
        isGenerating.value = false;
    }
  };

  return { isGenerating, generateOrderReceipt, generateClientReport, generateAndSaveDailyReport, generateCashFlowReceipt };
}
