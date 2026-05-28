<template>
  <div class="d-flex flex-column flex-grow-1 overflow-hidden h-100 pa-6">

    <div class="flex-shrink-0 mb-6">
      <v-row class="d-none d-md-flex">
        <v-col cols="12" sm="3" v-for="(kpi, idx) in cockpitKpis" :key="idx">
          <v-card
            class="kpi-card kpi-rect bg-gradient-custom hover-elevate py-3 px-4 cursor-default rounded-sm"
            :class="[kpi.gradient]"
            elevation="3"
          >
            <div class="kpi-bg-icon"><v-icon>{{ kpi.icon }}</v-icon></div>
            <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
              <div class="d-flex align-center" style="gap: 8px;">
                <v-icon size="18" class="opacity-80">{{ kpi.icon }}</v-icon>
                <span class="kpi-label text-uppercase tracking-widest">{{ kpi.label }}</span>
              </div>
              <div class="kpi-number-group my-1">
                <span class="text-h4 font-weight-black font-mono text-shadow-sm">{{ kpi.value }}</span>
              </div>
              <div class="kpi-footer opacity-80 font-weight-bold text-[10px] text-uppercase">{{ kpi.footer }}</div>
            </div>
          </v-card>
        </v-col>
      </v-row>
    </div>

    <div class="pb-4 d-flex align-center justify-space-between flex-shrink-0">
       <div class="d-flex flex-column">
          <h3 class="text-subtitle-1 font-weight-black text-uppercase tracking-widest text-primary">Apontamento Detalhado</h3>
          <span class="text-[11px] font-weight-bold opacity-60">Registros marcados com (*) foram inseridos manualmente.</span>
       </div>
       <v-btn color="primary" variant="flat" class="btn-3d font-weight-black px-6 text-caption rounded-sm" prepend-icon="mdi-printer" @click="generateEspelhoPDF">
         GERAR PDF OFICIAL
       </v-btn>
    </div>

    <div class="flex-grow-1 overflow-hidden d-flex flex-column transition-all grid-container-medium">
      <v-card
        class="flex-grow-1 d-flex flex-column rounded-sm border-thin overflow-hidden relative"
        :class="isLightMode ? 'bg-white shadow-sm' : 'bg-transparent border-white-05'"
        :elevation="0"
      >
        <div class="grid-scroll flex-grow-1 overflow-auto custom-scroll relative">

          <div
            class="grid-header sticky-head"
            :class="[isLightMode ? 'grid-surface-light border-b border-grey-lighten-2' : 'grid-surface-dark border-bottom-white-05']"
            style="grid-template-columns: 80px minmax(180px, 1.5fr) 75px 75px 75px 75px 70px 70px 70px 70px 70px 100px 50px;"
          >
            <div class="cell header-text center border-r-thick">Dia</div>
            <div class="cell header-text pl-4 border-r-thick">Escala / Regra</div>
            <div class="cell center header-text text-primary">Ent. 1</div>
            <div class="cell center header-text text-warning">Saí. 1</div>
            <div class="cell center header-text text-primary">Ent. 2</div>
            <div class="cell center header-text text-warning border-r-thick">Saí. 2</div>
            <div class="cell center header-text opacity-70">Prev.</div>
            <div class="cell center header-text font-weight-black">Trab.</div>
            <div class="cell center header-text text-success">Ext. 50%</div>
            <div class="cell center header-text text-success font-weight-black">Ext. 100%</div>
            <div class="cell center header-text text-primary border-r-thick">Saldo</div>
            <div class="cell center header-text">Status</div>
            <div class="cell center header-text">Ação</div>
          </div>

          <div v-if="monthMirror.length === 0" class="d-flex flex-column justify-center align-center h-100 opacity-40 py-12">
            <v-progress-circular indeterminate color="primary" class="mb-4"></v-progress-circular>
            <span class="text-uppercase font-weight-black tracking-widest">Processando matriz temporal...</span>
          </div>

          <div
            v-else
            v-for="(row, idx) in monthMirror"
            :key="row.dateStr"
            class="grid-row hover-bg-row transition-all"
            :class="[isLightMode ? 'grid-row-light' : 'grid-row-dark', zebraClass(idx)]"
            style="grid-template-columns: 80px minmax(180px, 1.5fr) 75px 75px 75px 75px 70px 70px 70px 70px 70px 100px 50px;"
          >
            <div class="cell center flex-column border-r-thick">
               <div class="font-weight-black text-body-1 lh-1">{{ row.label.split('/')[0] }}</div>
               <div class="text-[9px] font-weight-bold text-uppercase opacity-60 tracking-tighter">{{ row.weekday }}</div>
            </div>

            <div class="cell pl-4 flex-column align-start border-r-thick overflow-hidden justify-center">
               <div class="text-[11px] font-weight-black text-truncate w-100" :class="isLightMode ? 'text-grey-darken-4' : 'text-white'" :title="row.shiftLabel">{{ row.shiftLabel }}</div>
               <div class="text-[9px] font-weight-bold opacity-50 text-uppercase tracking-widest mt-1">{{ row.ruleLabel }}</div>
            </div>

            <div class="cell center font-mono text-[13px] font-weight-black" :class="row.in1 ? 'text-primary' : 'opacity-20'">{{ row.in1 || '--:--' }}<span v-if="row.in1 && row.statusTag === 'Manual'" class="text-error ml-1">*</span></div>
            <div class="cell center font-mono text-[13px] font-weight-black" :class="row.out1 ? 'text-warning' : 'opacity-20'">{{ row.out1 || '--:--' }}<span v-if="row.out1 && row.statusTag === 'Manual'" class="text-error ml-1">*</span></div>
            <div class="cell center font-mono text-[13px] font-weight-black" :class="row.in2 ? 'text-primary' : 'opacity-20'">{{ row.in2 || '--:--' }}<span v-if="row.in2 && row.statusTag === 'Manual'" class="text-error ml-1">*</span></div>
            <div class="cell center font-mono text-[13px] font-weight-black border-r-thick" :class="row.out2 ? 'text-warning' : 'opacity-20'">{{ row.out2 || '--:--' }}<span v-if="row.out2 && row.statusTag === 'Manual'" class="text-error ml-1">*</span></div>

            <div class="cell center font-mono text-[11px] opacity-60">{{ formatMinutes(row.expectedMinutes) }}</div>
            <div class="cell center font-mono text-[12px] font-weight-black">{{ formatMinutes(row.workedMinutes) }}</div>
            <div class="cell center font-mono text-[11px] text-success font-weight-bold">{{ row.overtime50 > 0 ? formatMinutes(row.overtime50) : '-' }}</div>
            <div class="cell center font-mono text-[11px] text-success font-weight-black">{{ row.overtime100 > 0 ? formatMinutes(row.overtime100) : '-' }}</div>
            <div class="cell center font-mono text-[11px] border-r-thick font-weight-black" :class="row.balanceMinutes > 0 ? 'text-success' : (row.balanceMinutes < 0 ? 'text-error' : 'text-grey')">{{ signedMinutes(row.balanceMinutes) }}</div>

            <div class="cell center overflow-hidden">
              <v-chip size="x-small" :color="statusColor(row.status)" variant="flat" class="font-weight-black text-uppercase chip-3d px-2 tracking-tighter w-100 rounded-sm">
                <span class="text-truncate">{{ row.status }}</span>
              </v-chip>
            </div>

            <div class="cell center">
               <v-btn icon="mdi-pencil" variant="tonal" size="x-small" color="primary" class="rounded-sm btn-3d" @click="openEditPunchModal(row)"></v-btn>
            </div>
          </div>
        </div>

        <div class="flex-shrink-0 border-t px-6 py-3 d-flex align-center justify-space-between z-20"
             :class="isLightMode ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-black-40 border-top-white-05 backdrop-blur-md'">
          <div class="text-caption font-weight-bold opacity-70 text-uppercase tracking-widest">
             Consolidação Mensal: <strong class="text-primary">{{ selectedMonth }}</strong>
          </div>
          <div class="d-flex align-center gap-6">
             <div class="text-[11px] font-weight-black tracking-widest">SALDO ACUMULADO: <span class="font-mono text-body-2 ml-1" :class="payrollSummary.bankLabel.includes('+') ? 'text-success' : (payrollSummary.bankLabel === '00:00' ? 'text-grey' : 'text-error')">{{ payrollSummary.bankLabel }}</span></div>
          </div>
        </div>
      </v-card>
    </div>

    <v-dialog v-model="editPunchModal.show" max-width="500" scrim="black opacity-90" persistent>
      <v-card class="rounded-sm overflow-hidden shadow-neon-elegant border-thin" :class="isLightMode ? 'bg-white' : 'glass-panel text-white border-white-10'">
         <div class="px-6 py-4 border-b d-flex align-center justify-space-between" :class="isLightMode ? 'bg-primary text-white border-grey-lighten-2' : 'bg-black-40 border-white-10'">
            <div class="text-subtitle-1 font-weight-black text-uppercase tracking-widest d-flex align-center gap-3">
              <v-icon size="24">mdi-account-edit</v-icon> Edição de Bordo
            </div>
            <v-btn icon="mdi-close" variant="text" :color="isLightMode ? 'white' : 'grey'" @click="editPunchModal.show = false"></v-btn>
         </div>
         <div class="pa-6">
            <div class="pa-4 rounded-sm border-thin mb-6 d-flex justify-space-between align-center" :class="isLightMode ? 'bg-grey-lighten-5' : 'bg-black-40 border-white-10'">
               <span class="text-caption font-weight-black text-uppercase tracking-widest opacity-70">Data de Referência</span>
               <span class="text-h6 font-weight-black font-mono text-primary">{{ editPunchModal.dateStr }}</span>
            </div>

            <div v-for="(punch, index) in editPunchModal.punches" :key="index" class="d-flex align-center gap-3 mb-4">
               <v-text-field
                 v-model="editPunchModal.punches[index]"
                 type="time"
                 variant="outlined"
                 density="comfortable"
                 hide-details
                 class="ui-field font-mono font-weight-black flex-grow-1 text-h6 custom-time-input"
                 :bg-color="isLightMode ? 'white' : 'rgba(0,0,0,0.4)'"
               ></v-text-field>
               <v-btn icon="mdi-delete" color="error" variant="tonal" class="btn-3d rounded-sm" @click="editPunchModal.punches.splice(index, 1)"></v-btn>
            </div>
            <v-btn variant="tonal" color="primary" class="mt-2 w-100 font-weight-black tracking-widest btn-3d rounded-sm" size="large" prepend-icon="mdi-plus" @click="editPunchModal.punches.push('')">
              ACRESCENTAR EVENTO
            </v-btn>
         </div>
         <div class="px-6 py-4 border-t d-flex justify-end gap-3" :class="isLightMode ? 'bg-grey-lighten-4' : 'bg-black-40 border-white-10'">
            <v-btn variant="outlined" class="btn-3d font-weight-bold px-6 rounded-sm text-caption" @click="editPunchModal.show = false">Abortar</v-btn>
            <v-btn color="primary" variant="flat" class="btn-3d font-weight-black px-8 tracking-widest rounded-sm" @click="saveManualPunches">CRAVAR</v-btn>
         </div>
      </v-card>
    </v-dialog>

  </div>
</template>

<script setup lang="ts">
import { computed, reactive } from 'vue';
import { storeToRefs } from 'pinia';
import { supabase } from '@/api/supabase';
import { useThemeStore } from '@/stores/theme';
import { useTimeTrackingStore } from '@/stores/timeTracking';
import { useCompanyStore } from '@/stores/company';
import { useUserStore } from '@/stores/user';
import { format, lastDayOfMonth } from 'date-fns';
import { ptBR } from 'date-fns/locale';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';

// Dispara eventos para o pai (Notificações)
const emit = defineEmits(['show-toast']);

// --- STORES ---
const themeStore = useThemeStore();
const timeStore = useTimeTrackingStore();
const companyStore = useCompanyStore();
const userStore = useUserStore();

// --- COMPUTEDS BÁSICOS ---
const isLightMode = computed(() => themeStore.currentMode === 'light');

const {
  payrollSummary,
  monthMirror,
  selectedEmployeeId,
  selectedMonth,
  selectedEmployeeResolved,
  timeLogs
} = storeToRefs(timeStore);

// --- KPIs FORMATADOS PARA O COCKPIT ---
const cockpitKpis = computed(() => [
  { label: 'Horas Previstas', value: payrollSummary.value.expectedHoursLabel, footer: 'Carga Contratual', icon: 'mdi-clock-outline', gradient: 'bg-gradient-info' },
  { label: 'Extras Reais', value: payrollSummary.value.overtimeHoursLabel, footer: 'Total do Mês', icon: 'mdi-plus-circle-outline', gradient: 'bg-gradient-green' },
  { label: 'Atrasos / Faltas', value: payrollSummary.value.missingHoursLabel, footer: 'Débitos de Tempo', icon: 'mdi-minus-circle-outline', gradient: 'bg-gradient-red' },
  { label: 'Saldo do Banco', value: payrollSummary.value.bankLabel, footer: 'Balanço Final', icon: 'mdi-scale-balance', gradient: 'bg-gradient-purple' },
]);

// --- ESTADO LOCAL (MODAL) ---
const editPunchModal = reactive({
  show: false,
  dateStr: '',
  punches: [] as string[]
});

// --- UTILITÁRIOS LOCAIS ---
const zebraClass = (index: number) => {
  return isLightMode.value
    ? (index % 2 === 0 ? 'zebra-light-a' : 'zebra-light-b')
    : (index % 2 === 0 ? 'zebra-dark-a' : 'zebra-dark-b');
};

const statusColor = (s: string) => {
  if (s === 'Falta' || s === 'Incompleto') return 'error';
  if (s === 'Atraso') return 'warning';
  if (s === 'Hora Extra' || s.includes('Feriado')) return 'success';
  if (s === 'Folga' || s === 'Aguardando') return 'grey';
  return 'primary';
};

const formatMinutes = (min: number) => {
  const s = Math.max(0, Math.round(min || 0));
  return `${String(Math.floor(s / 60)).padStart(2, '0')}:${String(s % 60).padStart(2, '0')}`;
};

const signedMinutes = (min: number) => {
  if (min === 0) return '00:00';
  return `${min > 0 ? '+' : '-'}${formatMinutes(Math.abs(min))}`;
};

const imageToBase64 = (urlOrFile: string | File): Promise<string> => new Promise((resolve, reject) => {
    const img = new Image();
    img.crossOrigin = 'Anonymous';
    img.onload = () => {
        const canvas = document.createElement('canvas');
        canvas.width = img.width; canvas.height = img.height;
        const ctx = canvas.getContext('2d');
        if (ctx) {
            ctx.fillStyle = '#FFFFFF';
            ctx.fillRect(0, 0, canvas.width, canvas.height);
            ctx.drawImage(img, 0, 0);
            resolve(canvas.toDataURL('image/png'));
        } else reject(new Error('Canvas ctx error'));
    };
    img.onerror = reject;
    if (typeof urlOrFile === 'string') img.src = urlOrFile; else img.src = URL.createObjectURL(urlOrFile);
});

// --- MÉTODOS DE EDIÇÃO DE PONTO ---
function openEditPunchModal(row: any) {
  editPunchModal.dateStr = row.dateStr;
  editPunchModal.punches = [...row.punches];
  editPunchModal.show = true;
}

async function saveManualPunches() {
  const validPunches = editPunchModal.punches.filter(p => p.trim() !== '').sort();
  try {
    const payload = {
        employee_id: selectedEmployeeId.value,
        date: editPunchModal.dateStr,
        punches: validPunches,
        in1: validPunches[0] || null,
        out1: validPunches[1] || null,
        in2: validPunches[2] || null,
        out2: validPunches[3] || null,
        status: 'Manual'
    };

    const { error } = await supabase.from('time_tracking_logs').upsert(payload, { onConflict: 'employee_id, date' });
    if (error) throw error;

    if (selectedEmployeeId.value) {
      if (!timeLogs.value[selectedEmployeeId.value]) {
         timeLogs.value[selectedEmployeeId.value] = {};
      }

      timeLogs.value[selectedEmployeeId.value][editPunchModal.dateStr] = {
         ...(timeLogs.value[selectedEmployeeId.value][editPunchModal.dateStr] || {}),
         punches: validPunches,
         in1: payload.in1, out1: payload.out1, in2: payload.in2, out2: payload.out2,
         statusTag: 'Manual'
      };

      timeStore.regenerateMonthMirror();
    }

    editPunchModal.show = false;
    emit('show-toast', { message: 'Batidas gravadas com precisão.', color: 'success' });
  } catch(e: any) {
    emit('show-toast', { message: 'Erro ao salvar ponto: ' + e.message, color: 'error' });
  }
}

// --- GERAÇÃO DE PDF OFICIAL (JS-PDF) ---
async function generateEspelhoPDF() {
  const emp = selectedEmployeeResolved.value;
  if (!emp) {
    emit('show-toast', { message: 'Selecione um colaborador primeiro.', color: 'warning' });
    return;
  }

  let companyInfo = { razao_social: 'EMPRESA PADRÃO LTDA', cnpj: '00.000.000/0001-00', address: 'Endereço não configurado' };
  let logoData = '';
  let roleName = userStore.profile?.role || 'SISTEMA';

  try {
    const roleId = userStore.user?.user_metadata?.custom_role_id || userStore.profile?.custom_role_id;
    if (roleId) {
        const { data: roleData } = await supabase.from('custom_roles').select('name').eq('id', roleId).maybeSingle();
        if (roleData && roleData.name) roleName = roleData.name;
        else roleName = 'Administrador';
    }

    const targetCompanyId = emp.company_id || companyStore.context;
    let query = supabase.from('companies').select('name, trade_name, cnpj, street, number, logo_url');
    if (targetCompanyId) query = query.eq('id', targetCompanyId);
    else query = query.eq('active', true).limit(1);

    const { data: comp } = await query.maybeSingle();
    if (comp) {
        companyInfo.razao_social = comp.trade_name || comp.name || companyInfo.razao_social;
        companyInfo.cnpj = comp.cnpj || companyInfo.cnpj;
        companyInfo.address = `${comp.street || ''}, ${comp.number || ''}`.replace(/^,\s*/, '');
        if (comp.logo_url) {
            try { logoData = await imageToBase64(comp.logo_url); } catch (err) {}
        }
    }
  } catch (e) {}

  if (!logoData) {
     try { logoData = await imageToBase64('/placeholder.png'); } catch(e){}
  }

  const [yearStr, monthStr] = selectedMonth.value.split('-');
  const startDateObj = new Date(Number(yearStr), Number(monthStr) - 1, 1);
  const endDateObj = lastDayOfMonth(startDateObj);

  const periodoLabel = `${format(startDateObj, 'dd/MM/yyyy')} até ${format(endDateObj, 'dd/MM/yyyy')}`;
  const emissaoLabel = format(new Date(), 'dd/MM/yyyy HH:mm:ss');

  const currentUserEmail = userStore.user?.email || 'Sistema';
  const footerText = `Gerado via MJProcess em ${emissaoLabel} por ${currentUserEmail} (${roleName.toUpperCase()})`;

  const doc = new jsPDF('l', 'mm', 'a4');
  const pageWidth = doc.internal.pageSize.getWidth();
  const marginX = 10;
  const usableWidth = pageWidth - (marginX * 2);

  const drawVia = (viaName: string) => {
      let nextY = 10;
      const gap = 1.5;

      const borderColor = [160, 160, 160];
      const borderWidth = 0.2;
      const headerHeight = 18;

      doc.setDrawColor(borderColor[0], borderColor[1], borderColor[2]);
      doc.setLineWidth(borderWidth);
      doc.setFillColor(248, 250, 252);
      doc.rect(marginX, nextY, usableWidth, headerHeight, 'FD');

      doc.line(marginX + 45, nextY, marginX + 45, nextY + headerHeight);
      doc.line(marginX + usableWidth - 85, nextY, marginX + usableWidth - 85, nextY + headerHeight);

      if (logoData) {
         try {
            const props = doc.getImageProperties(logoData);
            const maxWidth = 38;
            const maxHeight = 14;
            let targetWidth = maxWidth;
            let targetHeight = (props.height * targetWidth) / props.width;

            if (targetHeight > maxHeight) {
                targetHeight = maxHeight;
                targetWidth = (props.width * targetHeight) / props.height;
            }

            const xOffset = marginX + (45 - targetWidth) / 2;
            const yOffset = nextY + (headerHeight - targetHeight) / 2;
            doc.addImage(logoData, 'PNG', xOffset, yOffset, targetWidth, targetHeight, '', 'FAST');
         } catch (e) {}
      }

      doc.setFont('helvetica', 'bold');
      doc.setFontSize(11);
      doc.setTextColor(30, 30, 30);
      doc.text(companyInfo.razao_social.toUpperCase(), marginX + 48, nextY + 6.5);

      doc.setFont('helvetica', 'normal');
      doc.setFontSize(8);
      doc.setTextColor(60, 60, 60);
      doc.text(`CNPJ: ${companyInfo.cnpj}`, marginX + 48, nextY + 11);
      doc.text(`Endereço: ${companyInfo.address}`, marginX + 48, nextY + 15);

      const rightAlignX = marginX + usableWidth - 3;

      doc.setFont('helvetica', 'bold');
      doc.setFontSize(11);
      doc.setTextColor(41, 128, 185);
      doc.text('ESPELHO DE PONTO ELETRÔNICO', rightAlignX, nextY + 6, { align: 'right' });

      doc.setFont('helvetica', 'bold');
      doc.setFontSize(8);
      doc.setTextColor(60, 60, 60);
      doc.text(viaName, rightAlignX, nextY + 10, { align: 'right' });

      doc.setFont('helvetica', 'normal');
      doc.setFontSize(7);
      doc.setTextColor(80, 80, 80);
      doc.text(`Período: ${periodoLabel}`, rightAlignX, nextY + 14, { align: 'right' });
      doc.text(`Emissão: ${emissaoLabel}`, rightAlignX, nextY + 17, { align: 'right' });

      nextY += headerHeight + gap;

      autoTable(doc, {
        startY: nextY,
        margin: { left: marginX, right: marginX },
        theme: 'grid',
        styles: { fontSize: 7, cellPadding: 1, minCellHeight: 5.5, textColor: [40,40,40], lineColor: borderColor, lineWidth: borderWidth, valign: 'middle' },
        body: [
            [
                { content: 'COLABORADOR:', fontStyle: 'bold', cellWidth: 28, fillColor: [245, 247, 250] },
                { content: emp.nome.toUpperCase(), cellWidth: 85 },
                { content: 'CPF:', fontStyle: 'bold', cellWidth: 15, fillColor: [245, 247, 250] },
                { content: emp.cpf || 'Não informado', cellWidth: 40 },
                { content: 'ADMISSÃO:', fontStyle: 'bold', cellWidth: 20, fillColor: [245, 247, 250] },
                { content: emp.admission_date ? formatDateSafe(emp.admission_date) : 'Não informada' }
            ],
            [
                { content: 'CARGO/FUNÇÃO:', fontStyle: 'bold', fillColor: [245, 247, 250] },
                { content: emp.cargo || emp.role || 'Não informado' },
                { content: 'PIS:', fontStyle: 'bold', fillColor: [245, 247, 250] },
                { content: '000.00000.00-0' },
                { content: 'MATRÍCULA:', fontStyle: 'bold', fillColor: [245, 247, 250] },
                { content: '000' + emp.id.substring(0,4).toUpperCase() }
            ]
        ]
      });
      nextY = (doc as any).lastAutoTable.finalY + gap;

      const head = [['DATA', 'DIA', 'ENTRADA', 'SAÍDA', 'ENTRADA', 'SAÍDA', 'PREVISTO', 'TRABALHADO', 'FALTA', 'EXT 50%', 'EXT 100%', 'OCORRÊNCIA']];

      const body = monthMirror.value.map((r: any) => {
        const tag = r.statusTag === 'Manual' ? '*' : '';
        const ocorrencia = r.shiftLabel.includes('Feriado') ? r.shiftLabel : r.status;
        return [
          r.label,
          r.weekday.toUpperCase(),
          r.in1 ? r.in1 + tag : '---', r.out1 ? r.out1 + tag : '---',
          r.in2 ? r.in2 + tag : '---', r.out2 ? r.out2 + tag : '---',
          formatMinutes(r.expectedMinutes), formatMinutes(r.workedMinutes),
          formatMinutes(r.missingMinutes),
          formatMinutes(r.overtime50 || 0),
          formatMinutes(r.overtime100 || 0),
          ocorrencia
        ];
      });

      autoTable(doc, {
        startY: nextY,
        margin: { left: marginX, right: marginX },
        tableWidth: 'auto',
        head, body,
        theme: 'grid',
        styles: {
           fontSize: 6,
           textColor: [50, 50, 50],
           cellPadding: 0.7,
           font: 'helvetica',
           lineColor: borderColor,
           lineWidth: borderWidth
        },
        headStyles: {
           fillColor: [240, 244, 248],
           textColor: [41, 128, 185],
           fontStyle: 'bold',
           halign: 'center'
        },
        columnStyles: {
          0: { cellWidth: 16, halign: 'center', fontStyle: 'bold' },
          1: { cellWidth: 12, halign: 'center' },
          2: { halign: 'center' }, 3: { halign: 'center' },
          4: { halign: 'center' }, 5: { halign: 'center' },
          6: { halign: 'center', textColor: [120, 120, 120] },
          7: { halign: 'center', fontStyle: 'bold' },
          8: { halign: 'center', textColor: [200, 50, 50] },
          9: { halign: 'center', textColor: [39, 174, 96] },
          10: { halign: 'center', textColor: [20, 120, 60], fontStyle: 'bold' },
          11: { halign: 'left', cellWidth: 'auto' }
        },
        didParseCell: function(data) {
           if (data.section === 'body') {
              const rowText = data.row.raw[1];
              const isWeekend = rowText === 'SÁB' || rowText === 'DOM';
              const isHoliday = data.row.raw[11].toString().includes('Feriado');

              if (isWeekend || isHoliday) {
                 data.cell.styles.fillColor = [248, 250, 252];
                 if(isHoliday) data.cell.styles.fontStyle = 'bold';
              }
           }
        }
      });
      nextY = (doc as any).lastAutoTable.finalY + gap;

      autoTable(doc, {
        startY: nextY,
        margin: { left: marginX, right: marginX },
        theme: 'grid',
        styles: { fontSize: 7, cellPadding: 1.2, minCellHeight: 6, textColor: [40,40,40], lineColor: borderColor, lineWidth: borderWidth, valign: 'middle' },
        body: [
            [
                { content: 'TOTAIS DO PERÍODO:', fontStyle: 'bold', cellWidth: 38, fillColor: [245, 247, 250] },
                { content: `Previstas: ${payrollSummary.value.expectedHoursLabel}` },
                { content: `Trabalhadas: ${payrollSummary.value.regularHoursLabel}` },
                { content: `Faltas/Atrasos: ${payrollSummary.value.missingHoursLabel}`, textColor: [200, 50, 50], fontStyle: 'bold' },
                { content: `Extras 50%: ${payrollSummary.value.overtime50Label || '00:00'}`, textColor: [39, 174, 96], fontStyle: 'bold' },
                { content: `Extras 100%: ${payrollSummary.value.overtime100Label || '00:00'}`, textColor: [20, 120, 60], fontStyle: 'bold' }
            ]
        ]
      });
      nextY = (doc as any).lastAutoTable.finalY + gap;

      const sigHeight = 22;
      doc.setDrawColor(borderColor[0], borderColor[1], borderColor[2]);
      doc.setLineWidth(borderWidth);
      doc.setFillColor(255, 255, 255);
      doc.rect(marginX, nextY, usableWidth, sigHeight, 'FD');

      const textY = nextY + 3.5;
      doc.setFontSize(6);
      doc.setTextColor(100, 100, 100);
      doc.setFont('helvetica', 'normal');
      doc.text('* = Marcação inserida manualmente. Documento auxiliar para conferência de ponto.', marginX + 2, textY);

      const centerBoxX = marginX + (usableWidth / 2);

      doc.setDrawColor(0,0,0);
      doc.setLineWidth(0.15);
      doc.line(marginX + 20, nextY + 12, centerBoxX - 20, nextY + 12);
      doc.setFont('helvetica', 'bold');
      doc.setFontSize(7);
      doc.setTextColor(0,0,0);
      doc.text(companyInfo.razao_social.toUpperCase(), marginX + (usableWidth / 4), nextY + 15.5, { align: 'center' });

      doc.line(centerBoxX + 20, nextY + 12, marginX + usableWidth - 20, nextY + 12);
      doc.text(emp.nome.toUpperCase(), centerBoxX + (usableWidth / 4), nextY + 15.5, { align: 'center' });

      doc.setFont('helvetica', 'normal');
      doc.setFontSize(6.5);
      doc.setTextColor(80, 80, 80);
      doc.text(`Eu, ${emp.nome.toUpperCase()}, concordo com as marcações e cálculos no modelo compensatório.`, centerBoxX + (usableWidth / 4), nextY + 19.5, { align: 'center' });

      doc.setFont('helvetica', 'italic');
      doc.setFontSize(6);
      doc.setTextColor(150, 150, 150);
      doc.text(footerText, pageWidth / 2, 204, { align: 'center' });
  };

  drawVia('1ª VIA - ARQUIVO DA EMPRESA');
  doc.addPage();
  drawVia('2ª VIA - RECIBO DO COLABORADOR');

  doc.save(`Espelho_Ponto_${emp.nome.replace(/\s+/g,'_')}_${selectedMonth.value}.pdf`);
  emit('show-toast', { message: 'PDF oficial despachado para download.', color: 'success' });
}

function formatDateSafe(dStr: string | undefined | null) {
  if(!dStr) return '-';
  return dStr.split('T')[0].split('-').reverse().join('/');
}
</script>

<style scoped lang="scss">
/* === ESTILOS DA GRID PREMIUM COCKPIT === */
.grid-header, .grid-row { display: grid; align-items: stretch; width: 100%; }
.cell { padding: 4px 8px; display: flex; align-items: center; border-right: 1px solid rgba(128,128,128,0.08); border-bottom: 1px solid rgba(128,128,128,0.08); min-height: 52px; overflow: hidden; }
.border-r-thick { border-right: 2px solid rgba(128,128,128,0.15) !important; }
.header-text { font-weight: 900; text-transform: uppercase; font-size: 10px !important; letter-spacing: 0.05em; }
.center { justify-content: center; text-align: center; }
.sticky-head { position: sticky; top: 0; z-index: 20; }
.border-thin { border: 1px solid rgba(128,128,128,0.15) !important; }

/* Dark/Light Configs */
.grid-surface-light .cell { background: #f5f7fa; color: rgba(0,0,0,0.9); }
.zebra-light-a .cell { background: #ffffff; }
.zebra-light-b .cell { background: #f9fbfc; }
.grid-row-light:hover .cell { background: #f1f5f9 !important; }

.grid-surface-dark .cell { background: rgba(20,20,25,0.9) !important; color: rgba(255,255,255,0.85); border-color: rgba(255,255,255,0.05) !important; }
.zebra-dark-a .cell { background: rgba(255,255,255,0.02) !important; border-color: rgba(255,255,255,0.05) !important;}
.zebra-dark-b .cell { background: transparent !important; border-color: rgba(255,255,255,0.05) !important;}
.grid-row-dark:hover .cell { background: rgba(255,255,255,0.06) !important; }

/* KPIs */
.kpi-card { color: white; position: relative; min-height: 100px; overflow: hidden; }
.kpi-bg-icon { position: absolute; right: -15px; bottom: -15px; opacity: 0.12; transform: rotate(-15deg); }
.kpi-bg-icon .v-icon { font-size: 90px; color: white; }
.bg-gradient-info { background: linear-gradient(135deg, #0288d1, #005b9f); }
.bg-gradient-green { background: linear-gradient(135deg, #2e7d32, #1b5e20); }
.bg-gradient-red { background: linear-gradient(135deg, #c62828, #8e0000); }
.bg-gradient-purple { background: linear-gradient(135deg, #7b1fa2, #4a148c); }

.chip-3d { box-shadow: 0 2px 4px rgba(0,0,0,0.15), inset 0 1px 0 rgba(255,255,255,0.2) !important; }
.btn-3d { box-shadow: 0 3px 5px rgba(0,0,0,0.1), inset 0 2px 0 rgba(255,255,255,0.2) !important; text-transform: none !important; }
.btn-3d:active { transform: translateY(2px); box-shadow: 0 1px 2px rgba(0,0,0,0.1), inset 0 1px 0 rgba(255,255,255,0.1) !important; }

.rounded-sm { border-radius: 4px !important; }

.grid-scroll { scrollbar-gutter: stable; }
.custom-scroll::-webkit-scrollbar { width: 5px; height: 5px; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.3); border-radius: 4px; }

/* Modal Glass/Neon */
.bg-black-40 { background-color: rgba(0, 0, 0, 0.4) !important; }
.border-white-10 { border-color: rgba(255, 255, 255, 0.1) !important; }
.border-white-05 { border-color: rgba(255, 255, 255, 0.05) !important; }
.border-top-white-05 { border-top: 1px solid rgba(255, 255, 255, 0.05) !important; }
.glass-panel { background: rgba(24, 24, 28, 0.65) !important; backdrop-filter: blur(24px); }
.shadow-neon-elegant { box-shadow: 0 8px 32px rgba(0,0,0,0.6), inset 0 0 0 1px rgba(255,255,255,0.05) !important; }

.ui-field :deep(.v-field) { border-radius: 4px !important; }
.custom-time-input :deep(.v-field__input) { text-align: center; letter-spacing: 2px; }
.tracking-tighter { letter-spacing: -0.05em; }
</style>
