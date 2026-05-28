import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import { format, isValid } from 'date-fns';
import { ptBR } from 'date-fns/locale';
import { supabase } from '@/api/supabase';
import { useCompanyStore } from '@/stores/company';

export function useCashReport() {

  const formatCurrency = (val: number) => {
    return new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(val || 0);
  };

  const formatDateSafe = (dateString: string | Date | null | undefined): string => {
    if (!dateString) return '---';
    const date = new Date(dateString);
    return isValid(date) ? format(date, "dd/MM/yyyy HH:mm", { locale: ptBR }) : '---';
  };

  const loadLogo = async (url: string): Promise<string | null> => {
    return new Promise((resolve) => {
      const img = new Image();
      img.crossOrigin = 'Anonymous';
      img.src = url;
      img.onload = () => {
        const canvas = document.createElement('canvas');
        canvas.width = img.width;
        canvas.height = img.height;
        const ctx = canvas.getContext('2d');
        if (ctx) {
            ctx.fillStyle = '#FFFFFF';
            ctx.fillRect(0, 0, canvas.width, canvas.height);
            ctx.drawImage(img, 0, 0);
            resolve(canvas.toDataURL('image/png'));
        } else resolve(null);
      };
      img.onerror = () => resolve(null);
    });
  };

  const isCash = (methodName: string | null | undefined) => {
      if (!methodName) return true;
      const m = String(methodName).toLowerCase();
      if (m.includes('pix') || m.includes('cartao') || m.includes('cartão') || m.includes('boleto')) return false;
      return m.includes('dinheiro') || m.includes('espécie') || m.includes('especie') || m === 'cash';
  };

  const normForma = (f: string) => {
      let val = String(f || '').normalize('NFD').replace(/[\u0300-\u036f]/g, "").toUpperCase().trim();
      if (val.includes('CREDIT')) return 'CARTÃO DE CRÉDITO';
      if (val.includes('DEBIT')) return 'CARTÃO DE DÉBITO';
      if (val.includes('PIX') || val.includes('INSTANTANEO')) return 'PIX';
      if (val.includes('DINHEIRO') || val.includes('CASH') || val.includes('ESPECIE')) return 'DINHEIRO';
      if (val.includes('BOLETO')) return 'BOLETO';
      return val || 'OUTROS';
  };

  const normOrder = (num: any) => {
      let n = String(num || 'S/N').replace('#', '').trim();
      if (n.length > 10 && n.includes('-')) return 'S/N';
      return n;
  };

  // ============================================================================
  // MOTOR DE CÁLCULO E EXTRAÇÃO
  // ============================================================================
  const generateClosingReport = async (session: any, movements: any[], storeName: string, operatorName: string, detailedSales: any[]) => {
      if (!session) return;

      const gridGaveta: any[] = [];
      const gridMovimentacoes: any[] = [];

      // 1. VARREDURA DOS MOVIMENTOS FÍSICOS (Apenas Reforços e Sangrias)
      (movements || []).forEach(m => {
          if (m.type === 'opening') return;

          const amt = Math.abs(Number(m.amount));
          const desc = (m.description || '');
          const cleanDesc = desc.replace(/^\[.*?\]\s*/, '').replace('AUDITORIA: ', '').trim();

          const isOrderRelated = m.order_id || m.type === 'sale_cash' || desc.toLowerCase().includes('pedido') || desc.toLowerCase().includes('venda') || desc.toLowerCase().includes('baixa') || desc.toLowerCase().includes('sinal') || desc.toLowerCase().includes('parcela');

          if (!isOrderRelated) {
              if (m.amount > 0 || m.type === 'supply' || m.type === 'in_audit') {
                  gridGaveta.push({ date: m.created_at, tipo: 'REFORÇO', motivo: cleanDesc, valor: amt });
              } else if (m.amount < 0 || m.type === 'bleed' || m.type === 'out_audit') {
                  gridGaveta.push({ date: m.created_at, tipo: 'SANGRIA', motivo: cleanDesc, valor: amt });
              }
          }
      });

      // 2. VARREDURA DE MOVIMENTOS VIRTUAIS/DIGITAIS (Detailed Sales Oficial)
      (detailedSales || []).forEach(s => {
          const amt = Number(s.amount || s.value || 0);
          if (amt <= 0) return;

          const formaOriginal = String(s.method || s.payment_method || 'Digital').toUpperCase();

          if (formaOriginal.includes('PRAZO') || formaOriginal.includes('RECEBER')) return;

          gridMovimentacoes.push({
              date: s.date || session.closed_at || new Date().toISOString(),
              tipo: s.type || 'Venda',
              orderNum: normOrder(s.order_number || s.ref),
              clienteName: s.client || s.customer_name || 'Cliente',
              forma: normForma(formaOriginal),
              valor: amt,
              isCash: s.isCash !== undefined ? s.isCash : isCash(formaOriginal)
          });
      });

      // 3. FILTRO ANTI-DUPLICIDADE MESTRE
      const uniqueMovs: any[] = [];
      let recebimentosEspecie = 0;
      let movimentadoDigital = 0;
      let totalMovimentado = 0;

      gridMovimentacoes.forEach(row => {
          const dupeIndex = uniqueMovs.findIndex(ex => {
              const valMatch = Math.abs(ex.valor - row.valor) < 0.01;
              const formaMatch = ex.forma === row.forma;
              const timeMatch = Math.abs(new Date(ex.date).getTime() - new Date(row.date).getTime()) < 120000;

              if (valMatch && formaMatch && ex.orderNum !== 'S/N' && ex.orderNum === row.orderNum) return true;
              if (valMatch && formaMatch && timeMatch && (ex.orderNum === 'S/N' || row.orderNum === 'S/N')) return true;

              return false;
          });

          if (dupeIndex !== -1) {
              const existing = uniqueMovs[dupeIndex];

              if (existing.orderNum === 'S/N' && row.orderNum !== 'S/N') {
                  existing.orderNum = row.orderNum;
              }

              if (existing.clienteName.includes('Sinal') || existing.clienteName.includes('Parc') || existing.clienteName === 'Cliente') {
                  if (!row.clienteName.includes('Sinal') && !row.clienteName.includes('Parc') && row.clienteName !== 'Cliente') {
                      existing.clienteName = row.clienteName;
                  }
              }

              if (existing.tipo === 'Baixa/Recebimento' && row.tipo !== 'Baixa/Recebimento') {
                  existing.tipo = row.tipo;
              }

              if (row.isCash) existing.isCash = true;
          } else {
              uniqueMovs.push(row);
              totalMovimentado += row.valor;
              if (row.isCash) {
                  recebimentosEspecie += row.valor;
              } else {
                  movimentadoDigital += row.valor;
              }
          }
      });

      uniqueMovs.sort((a,b) => new Date(a.date).getTime() - new Date(b.date).getTime());
      gridGaveta.sort((a,b) => new Date(a.date).getTime() - new Date(b.date).getTime());

      let reforcos = 0;
      let sangrias = 0;
      gridGaveta.forEach(g => {
          if (g.tipo === 'REFORÇO') reforcos += g.valor;
          else sangrias += g.valor;
      });

      const abertura = Number(session.initial_balance || 0);

      // Correção Matemática Exata: O PDF calcula a própria diferença com base nos dados exibidos.
      const totalGeralFisico = abertura + recebimentosEspecie + reforcos - sangrias;
      const valorInformadoFisico = Number(session.final_balance_user || 0);

      const diferenca = valorInformadoFisico - totalGeralFisico;

      const closingNotes = session.closing_notes || session.notes || session.observation || '';

      await drawPDF(
          session, storeName, operatorName,
          abertura, totalMovimentado, totalGeralFisico,
          reforcos, sangrias,
          valorInformadoFisico, diferenca, closingNotes, uniqueMovs, gridGaveta
      );
  };

  // ============================================================================
  // DESENHO DO PDF
  // ============================================================================
  const drawPDF = async (
      session: any, storeName: string, operatorName: string,
      abertura: number, totalMovimentado: number, totalGeral: number,
      reforcos: number, sangrias: number,
      valorInformado: number, diferenca: number, closingNotes: string,
      uniqueMovs: any[], gridGaveta: any[]
  ) => {
      const doc = new jsPDF('p', 'mm', 'a4');
      const M = 10;
      const pageW = doc.internal.pageSize.getWidth();
      const pageH = doc.internal.pageSize.getHeight();
      const boxW = pageW - M * 2;
      let nextY = 10;

      const allMovs: any[] = [];

      uniqueMovs.forEach(r => {
          allMovs.push({
              dateObj: new Date(r.date).getTime(),
              hora: formatDateSafe(r.date).split(' ')[1] || '-',
              operacao: String(r.tipo).toUpperCase(),
              forma: String(r.forma).toUpperCase(),
              pedido: `#${r.orderNum}`,
              descricao: r.clienteName,
              valor: r.valor,
              isOutflow: false
          });
      });

      gridGaveta.forEach(g => {
          allMovs.push({
              dateObj: new Date(g.date).getTime(),
              hora: formatDateSafe(g.date).split(' ')[1] || '-',
              operacao: String(g.tipo).toUpperCase(),
              forma: 'DINHEIRO',
              pedido: '—',
              descricao: g.motivo,
              valor: g.valor,
              isOutflow: g.tipo === 'SANGRIA'
          });
      });

      allMovs.sort((a, b) => a.dateObj - b.dateObj);

      let companyInfo = {
          name: "CONFECÇÕES MJ",
          cnpj: "53.756.096/0001-89",
          address: "RUA LUIZ MONTANHAN, 1302",
          city: "Tietê/SP",
          phones: "(15) 99763-7941",
          email: "financeiro@mrjacky.com"
      };

      let logoBase64 = await loadLogo('https://cdn.shopify.com/s/files/1/0661/4574/6991/files/Sem_nome_1080_x_800_px_1080_x_500_px_1080_x_400_px_1000_x_380_px_da020cf2-2bb9-4dac-8dd3-4548cfd2e5ae.png?v=1756811713').catch(() => null);

      try {
          const companyStore = useCompanyStore();
          const targetCompanyId = session.company_id || (companyStore.context !== 'global' ? companyStore.context : null);

          let query = supabase.from('companies').select('*').eq('active', true);
          if (targetCompanyId) query = query.eq('id', targetCompanyId);
          else query = query.ilike('trade_name', '%JACKY%');

          const { data: comp } = await query.limit(1).maybeSingle();
          if (comp) {
              companyInfo.name = comp.trade_name || comp.name;
              companyInfo.cnpj = comp.cnpj;
              companyInfo.address = `${comp.street || ''}, ${comp.number || ''}`;
              companyInfo.city = `${comp.city || ''}/${comp.state || ''}`;
              companyInfo.phones = comp.phone || companyInfo.phones;
              companyInfo.email = comp.email || companyInfo.email;
              if (comp.logo_url) logoBase64 = await loadLogo(comp.logo_url).catch(() => logoBase64);
          }
      } catch (e) {}

      const headerH = 26;
      doc.setDrawColor(180);
      doc.setLineWidth(0.3);
      doc.rect(M, nextY, boxW, headerH);

      if (logoBase64) {
         try { doc.addImage(logoBase64, 'PNG', M + 3, nextY + 4, 30, 16); } catch (e) {}
      }

      doc.setFont('helvetica', 'bold');
      doc.setFontSize(11);
      doc.text(companyInfo.name, M + 38, nextY + 9);

      doc.setFont('helvetica', 'normal');
      doc.setFontSize(8.5);
      doc.text(`CNPJ: ${companyInfo.cnpj}`, M + 38, nextY + 14);
      doc.text(companyInfo.address, M + 38, nextY + 18);
      doc.text(companyInfo.city, M + 38, nextY + 22);

      const rightX = pageW - M - 3;
      doc.text(companyInfo.phones, rightX, nextY + 9, { align: 'right' });
      doc.text(companyInfo.email, rightX, nextY + 14, { align: 'right' });

      nextY += headerH + 6;

      const barH = 8;
      doc.setFillColor(230);
      doc.rect(M, nextY, boxW, barH, "F");
      doc.setDrawColor(180);
      doc.rect(M, nextY, boxW, barH);

      doc.setFont('helvetica', 'bold');
      doc.setFontSize(11);
      doc.text('RELATÓRIO GERAL DO TURNO (TOTALIZADO)', pageW / 2, nextY + 5.5, { align: 'center' });

      doc.setFontSize(10);
      doc.text(`ID: #${String(session.id).slice(0,8).toUpperCase()}`, pageW - M - 2, nextY + 5.5, { align: 'right' });

      nextY += barH + 6;

      doc.setFont('helvetica', 'bold');
      doc.setFontSize(9.5);
      doc.setFillColor(230);
      doc.rect(M, nextY, boxW, 7, "F");
      doc.setDrawColor(180);
      doc.rect(M, nextY, boxW, 7);
      doc.text('DADOS DO TURNO', M + 2, nextY + 5);

      autoTable(doc, {
        startY: nextY + 7,
        margin: { left: M, right: M },
        tableWidth: boxW,
        theme: 'grid',
        styles: { fontSize: 8.5, cellPadding: 1.5, textColor: [30, 30, 30], lineColor: [200, 200, 200], lineWidth: 0.2, minCellHeight: 7, valign: "middle" },
        body: [
            [
                { content: 'UNIDADE:', fontStyle: 'bold', cellWidth: 35 },
                { content: storeName.toUpperCase() },
                { content: 'OPERADOR:', fontStyle: 'bold', cellWidth: 35 },
                { content: operatorName.toUpperCase() }
            ],
            [
                { content: 'ABERTURA:', fontStyle: 'bold' },
                { content: formatDateSafe(session.opened_at) },
                { content: 'FECHAMENTO:', fontStyle: 'bold' },
                { content: formatDateSafe(session.closed_at) }
            ]
        ]
      });
      nextY = (doc as any).lastAutoTable.finalY + 6;

      doc.setFont('helvetica', 'bold');
      doc.setFontSize(9.5);
      doc.setFillColor(230);
      doc.rect(M, nextY, boxW, 7, "F");
      doc.setDrawColor(180);
      doc.rect(M, nextY, boxW, 7);
      doc.text('EXTRATO DE MOVIMENTAÇÕES', M + 2, nextY + 5);

      autoTable(doc, {
          startY: nextY + 7,
          margin: { left: M, right: M },
          tableWidth: boxW,
          head: [['HORA', 'OPERAÇÃO', 'FORMA PAG.', 'Nº PEDIDO', 'MOTIVO / CLIENTE', 'VALOR (R$)']],
          body: allMovs.length > 0 ? allMovs.map(m => [
              m.hora,
              m.operacao,
              m.forma,
              m.pedido,
              m.descricao,
              formatCurrency(m.valor)
          ]) : [['—', '—', '—', '—', 'Nenhuma movimentação registrada.', 'R$ 0,00']],
          theme: 'grid',
          headStyles: { fillColor: [245, 245, 245], textColor: [30, 30, 30], fontStyle: 'bold', fontSize: 8.5, valign: "middle" },
          styles: { fontSize: 8.3, cellPadding: 1.5, lineColor: [200, 200, 200], lineWidth: 0.2, textColor: [30, 30, 30], minCellHeight: 7, valign: "middle" },
          columnStyles: {
              0: { cellWidth: 15, halign: 'center' },
              1: { cellWidth: 35, fontStyle: 'bold' },
              2: { cellWidth: 35 },
              3: { cellWidth: 20, halign: 'center' },
              4: { cellWidth: 'auto' },
              5: { cellWidth: 28, halign: 'right', fontStyle: 'bold' }
          },
          didParseCell: (dataInfo) => {
              if (dataInfo.section === 'body' && allMovs.length > 0) {
                  const m = allMovs[dataInfo.row.index];
                  if (m.isOutflow) {
                      dataInfo.cell.styles.fillColor = [253, 236, 234];
                  } else {
                      dataInfo.cell.styles.fillColor = [232, 245, 233];
                  }
              }
          }
      });
      nextY = (doc as any).lastAutoTable.finalY + 6;

      if (nextY > pageH - 75) { doc.addPage(); nextY = M; }

      doc.setFont('helvetica', 'bold');
      doc.setFontSize(9.5);
      doc.setFillColor(230);
      doc.rect(M, nextY, boxW, 7, "F");
      doc.setDrawColor(180);
      doc.rect(M, nextY, boxW, 7);
      doc.text('DADOS DO CAIXA', M + 2, nextY + 5);

      let sumPix = 0, sumCredito = 0, sumDebito = 0, sumDinheiro = 0, sumBoleto = 0, sumOutros = 0;

      uniqueMovs.forEach(r => {
          const f = String(r.forma).toUpperCase();
          if (f.includes('PIX')) sumPix += r.valor;
          else if (f.includes('CRÉDITO')) sumCredito += r.valor;
          else if (f.includes('DÉBITO')) sumDebito += r.valor;
          else if (f.includes('DINHEIRO')) sumDinheiro += r.valor;
          else if (f.includes('BOLETO')) sumBoleto += r.valor;
          else sumOutros += r.valor;
      });

      const mathRows: any[] = [
          { label: 'Abertura de Caixa', value: abertura, bgColor: [232, 245, 233] },
          { label: 'Pix', value: sumPix, bgColor: [232, 245, 233] },
          { label: 'Cartão de Crédito', value: sumCredito, bgColor: [232, 245, 233] },
          { label: 'Cartão de Débito', value: sumDebito, bgColor: [232, 245, 233] },
          { label: 'Dinheiro', value: sumDinheiro, bgColor: [232, 245, 233] },
          { label: 'Boleto', value: sumBoleto, bgColor: [232, 245, 233] }
      ];

      if (sumOutros > 0) {
          mathRows.push({ label: 'Outras Formas (Não Mapeadas)', value: sumOutros, bgColor: [232, 245, 233] });
      }

      mathRows.push({ label: 'Reforço', value: reforcos, bgColor: [232, 245, 233] });
      mathRows.push({ label: 'Sangria', value: sangrias, bgColor: [253, 236, 234] });

      mathRows.push({ label: 'SALDO REAL ESPERADO (GAVETA)', value: totalGeral, bgColor: [227, 242, 253], isTotal: true });

      autoTable(doc, {
        startY: nextY + 7,
        margin: { left: M, right: M },
        tableWidth: boxW,
        theme: 'grid',
        styles: { fontSize: 8.5, cellPadding: 2, lineColor: [200, 200, 200], lineWidth: 0.2, minCellHeight: 7, valign: "middle", textColor: [30, 30, 30] },
        columnStyles: { 1: { halign: 'right', fontStyle: 'bold', cellWidth: 45 } },
        body: mathRows.map(r => [
            { content: r.label, fontStyle: r.isTotal ? 'bold' : 'normal' },
            { content: formatCurrency(r.value) }
        ]),
        didParseCell: (data) => {
            if (data.section === 'body') {
                const rowDef = mathRows[data.row.index];
                data.cell.styles.fillColor = rowDef.bgColor as [number, number, number];
            }
        }
      });
      nextY = (doc as any).lastAutoTable.finalY + 6;

      const userBreakdown = session.user_breakdown;

      if (userBreakdown) {
          if (nextY > pageH - 70) { doc.addPage(); nextY = M; }

          doc.setFont('helvetica', 'bold');
          doc.setFontSize(9.5);
          doc.setFillColor(230);
          doc.rect(M, nextY, boxW, 7, "F");
          doc.setDrawColor(180);
          doc.rect(M, nextY, boxW, 7);
          doc.text('CONFERÊNCIA DETALHADA (INFORMADO PELO OPERADOR)', M + 2, nextY + 5);

          const userRows: any[] = [
              { label: 'Dinheiro (Gaveta)', value: Number(userBreakdown.dinheiro || 0) },
              { label: 'Pix', value: Number(userBreakdown.pix || 0) },
              { label: 'Cartão de Crédito', value: Number(userBreakdown.credito || 0) },
              { label: 'Cartão de Débito', value: Number(userBreakdown.debito || 0) },
              { label: 'Transf. Bancária', value: Number(userBreakdown.transferencia || 0) },
              { label: 'Boleto', value: Number(userBreakdown.boleto || 0) },
              { label: 'Crédito Loja / Outros', value: Number(userBreakdown.creditoLoja || 0) }
          ];

          if (userBreakdown.custom && Array.isArray(userBreakdown.custom)) {
              userBreakdown.custom.forEach((c: any) => {
                  if (c.name && c.name.trim() !== '') {
                      userRows.push({ label: c.name.toUpperCase(), value: Number(c.value || 0) });
                  }
              });
          }

          userRows.push({
              label: 'TOTAL GERAL INFORMADO',
              value: Number(userBreakdown.total_geral || valorInformado),
              isTotal: true
          });

          autoTable(doc, {
            startY: nextY + 7,
            margin: { left: M, right: M },
            tableWidth: boxW,
            theme: 'grid',
            styles: { fontSize: 8.5, cellPadding: 2, lineColor: [200, 200, 200], lineWidth: 0.2, minCellHeight: 7, valign: "middle", textColor: [30, 30, 30] },
            columnStyles: { 1: { halign: 'right', fontStyle: 'bold', cellWidth: 45 } },
            body: userRows.map(r => [
                { content: r.label, fontStyle: r.isTotal ? 'bold' : 'normal' },
                { content: formatCurrency(r.value) }
            ]),
            didParseCell: (data) => {
                if (data.section === 'body' && userRows[data.row.index].isTotal) {
                    data.cell.styles.fillColor = [255, 250, 230];
                }
            }
          });
          nextY = (doc as any).lastAutoTable.finalY + 6;
      }

      if (nextY > pageH - 65) { doc.addPage(); nextY = M; }

      const diffColor = Math.abs(diferenca) < 0.01 ? [39, 174, 96] : (diferenca > 0 ? [41, 128, 185] : [200, 50, 50]);
      const diffLabel = Math.abs(diferenca) < 0.01 ? 'CAIXA BATIDO (OK)' : (diferenca > 0 ? 'SOBRA DETECTADA' : 'QUEBRA DE CAIXA');

      const hasNotes = closingNotes.trim().length > 0;
      const boxApuracaoH = hasNotes ? 45 : 26;

      doc.setDrawColor(200, 200, 200);
      doc.setLineWidth(0.3);
      doc.setFillColor(255, 250, 230);
      doc.rect(M, nextY, boxW, boxApuracaoH, 'FD');

      doc.setFont('helvetica', 'bold');
      doc.setFontSize(11);
      doc.setTextColor(30, 30, 30);
      doc.text('GAVETA FÍSICA INFORMADA PELO VENDEDOR:', M + 5, nextY + 8);

      doc.setFontSize(14);
      doc.text(formatCurrency(valorInformado), pageW - M - 5, nextY + 8, { align: 'right' });

      doc.setFontSize(9);
      doc.text(`DIFERENÇA SOBRE O ESPERADO (GAVETA): ${diffLabel}`, M + 5, nextY + 18);

      doc.setFontSize(12);
      doc.setTextColor(diffColor[0], diffColor[1], diffColor[2]);
      doc.text(formatCurrency(diferenca), pageW - M - 5, nextY + 18, { align: 'right' });

      if (hasNotes) {
          doc.setFontSize(9);
          doc.setTextColor(100, 100, 100);
          doc.text('JUSTIFICATIVA / OBSERVAÇÃO:', M + 5, nextY + 28);

          doc.setFont('helvetica', 'normal');
          doc.setFontSize(8.5);
          doc.setTextColor(30, 30, 30);
          const splitNotes = doc.splitTextToSize(closingNotes, boxW - 10);
          doc.text(splitNotes, M + 5, nextY + 34);
      }

      nextY += boxApuracaoH + 20;
      if (nextY > pageH - 25) { doc.addPage(); nextY = 30; }

      const center1 = M + (boxW * 0.25);
      const center2 = M + (boxW * 0.75);

      doc.setDrawColor(0, 0, 0);
      doc.setLineWidth(0.15);

      doc.line(M + 10, nextY, M + (boxW/2) - 10, nextY);
      doc.setFont('helvetica', 'bold'); doc.setFontSize(8); doc.setTextColor(0,0,0);
      doc.text(operatorName.toUpperCase(), center1, nextY + 4, { align: 'center' });
      doc.setFont('helvetica', 'normal'); doc.setFontSize(7);
      doc.text('Operador de Caixa', center1, nextY + 8, { align: 'center' });

      doc.line(M + (boxW/2) + 10, nextY, pageW - M - 10, nextY);
      doc.setFont('helvetica', 'bold'); doc.setFontSize(8);
      doc.text('VISTO DA GERÊNCIA / CONFERENTE', center2, nextY + 4, { align: 'center' });

      const emissaoLabel = format(new Date(), 'dd/MM/yyyy HH:mm:ss');
      const totalPages = (doc as any).internal.getNumberOfPages();

      for (let i = 1; i <= totalPages; i++) {
          doc.setPage(i);
          doc.setFont('helvetica', 'normal');
          doc.setFontSize(7);
          doc.setTextColor(150, 150, 150);

          doc.text(`Gerado via MJProcess em ${emissaoLabel} por ${operatorName.toUpperCase()}`, M, pageH - 5);
          doc.text(`Página ${i} de ${totalPages}`, pageW - M, pageH - 5, { align: 'right' });
      }

      doc.save(`Fechamento_Caixa_${format(new Date(), 'yyyyMMdd_HHmm')}.pdf`);
  };

  const generateAdminReport = () => {};
  const generateEditableClosingReport = async () => {};

  return { generateClosingReport, generateAdminReport, generateEditableClosingReport };
}
