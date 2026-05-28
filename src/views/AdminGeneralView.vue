<template>
  <div class="admin-general-view h-100 d-flex flex-column pa-6 bg-transparent">

    <v-row dense class="mb-6 animate-fade-in-up">
       <v-col cols="12" sm="6" md="3">
          <v-card class="mini-stat-card pa-3 d-flex align-center gap-3 border-thin" elevation="0">
             <div class="icon-box-xs bg-green-lighten-5 rounded-lg text-green-darken-2">
                <v-icon size="18">mdi-cash-check</v-icon>
             </div>
             <div>
                <div class="text-[10px] text-uppercase font-weight-bold opacity-60">Recebimento Realizado</div>
                <div class="text-subtitle-2 font-weight-black font-mono">
                   {{ formatPercent(efficiencyMetrics.receivedRate) }}
                </div>
             </div>
          </v-card>
       </v-col>
       <v-col cols="12" sm="6" md="3">
          <v-card class="mini-stat-card pa-3 d-flex align-center gap-3 border-thin" elevation="0">
             <div class="icon-box-xs bg-red-lighten-5 rounded-lg text-red-darken-2">
                <v-icon size="18">mdi-alert-circle-outline</v-icon>
             </div>
             <div>
                <div class="text-[10px] text-uppercase font-weight-bold opacity-60">Inadimplência Atual</div>
                <div class="text-subtitle-2 font-weight-black font-mono text-error">
                   {{ formatPercent(efficiencyMetrics.overdueRate) }}
                </div>
             </div>
          </v-card>
       </v-col>
       <v-col cols="12" sm="6" md="3">
          <v-card class="mini-stat-card pa-3 d-flex align-center gap-3 border-thin" elevation="0">
             <div class="icon-box-xs bg-blue-lighten-5 rounded-lg text-blue-darken-2">
                <v-icon size="18">mdi-calendar-clock</v-icon>
             </div>
             <div>
                <div class="text-[10px] text-uppercase font-weight-bold opacity-60">Previsto (Mês)</div>
                <div class="text-subtitle-2 font-weight-black font-mono">
                   {{ formatCurrency(holdingMetrics.projectedTotal) }}
                </div>
             </div>
          </v-card>
       </v-col>
       <v-col cols="12" sm="6" md="3">
          <v-card class="mini-stat-card pa-3 d-flex align-center gap-3 border-thin" elevation="0">
             <div class="icon-box-xs bg-purple-lighten-5 rounded-lg text-purple-darken-2">
                <v-icon size="18">mdi-scale-balance</v-icon>
             </div>
             <div>
                <div class="text-[10px] text-uppercase font-weight-bold opacity-60">Saldo Projetado</div>
                <div class="text-subtitle-2 font-weight-black font-mono text-primary">
                   {{ formatCurrency(holdingMetrics.balance) }}
                </div>
             </div>
          </v-card>
       </v-col>
    </v-row>

    <v-row dense class="mb-6">

      <v-col cols="12" md="4">
        <v-card class="analytics-card h-100 d-flex flex-column border-thin" elevation="0">
          <div class="pa-4 border-b bg-surface-lighten-1">
             <div class="d-flex justify-space-between align-center mb-2">
                <div class="d-flex align-center gap-2">
                   <v-avatar size="28" color="blue-lighten-5" class="rounded border">
                      <span class="text-blue-darken-3 text-caption font-weight-black">MJ</span>
                   </v-avatar>
                   <div>
                      <div class="text-subtitle-2 font-weight-black lh-1">MJ Process</div>
                      <div class="text-[10px] opacity-60 font-weight-bold text-uppercase">Industrial & Serviços</div>
                   </div>
                </div>
                <v-chip size="x-small" color="blue" variant="flat" class="font-weight-bold">
                   {{ formatCompact(mjMetrics.total) }}
                </v-chip>
             </div>

             <div class="d-flex gap-2 mt-3">
                <div class="flex-1 px-2 py-1 rounded bg-white border">
                   <div class="text-[9px] text-uppercase font-weight-bold text-medium-emphasis">Recebido</div>
                   <div class="text-caption font-weight-black text-success">{{ formatCompact(mjMetrics.received) }}</div>
                </div>
                <div class="flex-1 px-2 py-1 rounded bg-white border">
                   <div class="text-[9px] text-uppercase font-weight-bold text-medium-emphasis">Atrasado</div>
                   <div class="text-caption font-weight-black text-error">{{ formatCompact(mjMetrics.overdue) }}</div>
                </div>
                <div class="flex-1 px-2 py-1 rounded bg-white border">
                   <div class="text-[9px] text-uppercase font-weight-bold text-medium-emphasis">A Pagar</div>
                   <div class="text-caption font-weight-black text-medium-emphasis">{{ formatCompact(mjMetrics.expense) }}</div>
                </div>
             </div>
          </div>

          <div class="chart-container flex-grow-1 px-4 py-4 relative">
             <Bar :data="mjChartData" :options="chartOptions" />
          </div>

          <div class="pa-3 border-t bg-grey-lighten-5 d-flex justify-space-between align-center">
             <div class="d-flex align-center gap-2">
                <div class="legend-dot bg-blue"></div>
                <span class="text-[10px] font-weight-bold text-medium-emphasis">Entradas: {{ formatCurrency(mjMetrics.total) }}</span>
             </div>
             <div class="d-flex align-center gap-2">
                <div class="legend-dot bg-red"></div>
                <span class="text-[10px] font-weight-bold text-medium-emphasis">Saídas: {{ formatCurrency(mjMetrics.expense) }}</span>
             </div>
          </div>
        </v-card>
      </v-col>

      <v-col cols="12" md="4">
        <v-card class="analytics-card h-100 d-flex flex-column border-thin" elevation="0">
          <div class="pa-4 border-b bg-surface-lighten-1">
             <div class="d-flex justify-space-between align-center mb-2">
                <div class="d-flex align-center gap-2">
                   <v-avatar size="28" color="orange-lighten-5" class="rounded border">
                      <span class="text-orange-darken-3 text-caption font-weight-black">CJ</span>
                   </v-avatar>
                   <div>
                      <div class="text-subtitle-2 font-weight-black lh-1">Cajuia Loja</div>
                      <div class="text-[10px] opacity-60 font-weight-bold text-uppercase">Varejo & PDV</div>
                   </div>
                </div>
                <v-chip size="x-small" color="orange" variant="flat" class="font-weight-bold">
                   {{ formatCompact(cajuiaMetrics.total) }}
                </v-chip>
             </div>

             <div class="d-flex gap-2 mt-3">
                <div class="flex-1 px-2 py-1 rounded bg-white border">
                   <div class="text-[9px] text-uppercase font-weight-bold text-medium-emphasis">Vendas</div>
                   <div class="text-caption font-weight-black text-success">{{ formatCompact(cajuiaMetrics.total) }}</div>
                </div>
                <div class="flex-1 px-2 py-1 rounded bg-white border">
                   <div class="text-[9px] text-uppercase font-weight-bold text-medium-emphasis">Recebido</div>
                   <div class="text-caption font-weight-black text-orange-darken-2">{{ formatCompact(cajuiaMetrics.received) }}</div>
                </div>
                <div class="flex-1 px-2 py-1 rounded bg-white border">
                   <div class="text-[9px] text-uppercase font-weight-bold text-medium-emphasis">Despesas</div>
                   <div class="text-caption font-weight-black text-medium-emphasis">{{ formatCompact(cajuiaMetrics.expense) }}</div>
                </div>
             </div>
          </div>

          <div class="chart-container flex-grow-1 px-4 py-4 relative">
             <Bar :data="cajuiaChartData" :options="chartOptions" />
          </div>

          <div class="pa-3 border-t bg-grey-lighten-5 d-flex justify-space-between align-center">
             <div class="d-flex align-center gap-2">
                <div class="legend-dot bg-orange"></div>
                <span class="text-[10px] font-weight-bold text-medium-emphasis">Entradas: {{ formatCurrency(cajuiaMetrics.total) }}</span>
             </div>
             <div class="d-flex align-center gap-2">
                <div class="legend-dot bg-red"></div>
                <span class="text-[10px] font-weight-bold text-medium-emphasis">Saídas: {{ formatCurrency(cajuiaMetrics.expense) }}</span>
             </div>
          </div>
        </v-card>
      </v-col>

      <v-col cols="12" md="4">
        <v-card class="analytics-card bg-gradient-brand text-white h-100 d-flex flex-column border-0 shadow-lg" elevation="0">
          <div class="absolute-overlay"></div>
          <div class="pa-4 border-b border-white-10 relative z-10">
             <div class="d-flex justify-space-between align-center mb-2">
                <div class="d-flex align-center gap-2">
                   <div class="icon-box-sm bg-white-20 rounded text-white">
                      <v-icon size="16">mdi-finance</v-icon>
                   </div>
                   <div>
                      <div class="text-subtitle-2 font-weight-black lh-1 text-white">Holding Group</div>
                      <div class="text-[10px] text-white-70 font-weight-bold text-uppercase">Consolidado Geral</div>
                   </div>
                </div>
                <v-chip size="x-small" color="white" variant="flat" class="text-primary font-weight-black">
                   TOTAL
                </v-chip>
             </div>

             <div class="d-flex gap-2 mt-3">
                <div class="flex-1 px-2 py-1 rounded bg-white-10 border border-white-10">
                   <div class="text-[9px] text-uppercase font-weight-bold text-white-70">Líquido</div>
                   <div class="text-caption font-weight-black text-white">{{ formatCompact(holdingMetrics.balance) }}</div>
                </div>
                <div class="flex-1 px-2 py-1 rounded bg-white-10 border border-white-10">
                   <div class="text-[9px] text-uppercase font-weight-bold text-white-70">Bruto</div>
                   <div class="text-caption font-weight-black text-white">{{ formatCompact(holdingMetrics.total) }}</div>
                </div>
             </div>
          </div>

          <div class="chart-container flex-grow-1 px-4 py-4 relative z-10">
             <Bar :data="totalChartData" :options="chartOptionsDark" />
          </div>

          <div class="pa-3 border-t border-white-10 bg-black-20 d-flex justify-space-between align-center relative z-10">
             <div class="d-flex align-center gap-2">
                <div class="legend-dot bg-white"></div>
                <span class="text-[10px] font-weight-bold text-white-70">Total Entradas: {{ formatCurrency(holdingMetrics.total) }}</span>
             </div>
             <div class="d-flex align-center gap-2">
                <div class="legend-dot bg-red-lighten-2"></div>
                <span class="text-[10px] font-weight-bold text-white-70">Total Saídas: {{ formatCurrency(holdingMetrics.expense) }}</span>
             </div>
          </div>
        </v-card>
      </v-col>
    </v-row>

    <v-card class="border-thin rounded-lg elevation-0 d-flex flex-column flex-grow-1">
       <div class="pa-4 border-b d-flex justify-space-between align-center bg-surface-lighten-1">
          <div class="d-flex align-center gap-2">
             <v-icon color="primary" size="20">mdi-calendar-arrow-right</v-icon>
             <h3 class="text-subtitle-2 font-weight-black text-uppercase">Previsão de Fluxo de Caixa</h3>
          </div>
          <v-chip size="x-small" variant="outlined" color="primary">Próximas 4 Semanas</v-chip>
       </div>

       <v-table density="compact" class="projection-table flex-grow-1">
          <thead>
             <tr>
                <th class="text-left font-weight-black text-uppercase text-[10px] text-medium-emphasis bg-grey-lighten-5" style="width: 15%">Período</th>

                <th class="text-center font-weight-bold text-[10px] text-blue-darken-2 bg-blue-lighten-5 border-l" colspan="2">MJ PROCESS</th>

                <th class="text-center font-weight-bold text-[10px] text-orange-darken-2 bg-orange-lighten-5 border-l" colspan="2">CAJUIA</th>

                <th class="text-right font-weight-black text-[10px] text-grey-darken-3 bg-grey-lighten-4 border-l" style="width: 15%">SALDO</th>
             </tr>
             <tr class="sub-header">
                <th class="bg-grey-lighten-5"></th>

                <th class="text-right text-[9px] text-medium-emphasis border-l">Entrada</th>
                <th class="text-right text-[9px] text-medium-emphasis">Saída</th>

                <th class="text-right text-[9px] text-medium-emphasis border-l">Entrada</th>
                <th class="text-right text-[9px] text-medium-emphasis">Saída</th>

                <th class="text-right text-[9px] text-medium-emphasis bg-grey-lighten-4 border-l">Consolidado</th>
             </tr>
          </thead>
          <tbody>
             <tr v-for="(row, idx) in projectionRows" :key="idx" class="hover-row">
                <td class="py-3">
                   <div class="d-flex flex-column">
                      <span class="text-caption font-weight-bold">{{ row.label }}</span>
                      <span class="text-[9px] font-mono text-medium-emphasis">{{ row.dateRange }}</span>
                   </div>
                </td>

                <td class="text-right border-l font-mono text-caption text-success font-weight-bold">
                   {{ formatCurrency(row.mjIn) }}
                </td>
                <td class="text-right font-mono text-caption text-error opacity-70">
                   {{ formatCurrency(row.mjOut) }}
                </td>

                <td class="text-right border-l font-mono text-caption text-success font-weight-bold">
                   {{ formatCurrency(row.cjIn) }}
                </td>
                <td class="text-right font-mono text-caption text-error opacity-70">
                   {{ formatCurrency(row.cjOut) }}
                </td>

                <td class="text-right border-l bg-grey-lighten-5 font-mono text-body-2 font-weight-black">
                   <span :class="row.balance >= 0 ? 'text-success-darken-1' : 'text-error'">
                      {{ formatCurrency(row.balance) }}
                   </span>
                </td>
             </tr>
          </tbody>
       </v-table>
    </v-card>

    <v-overlay :model-value="isLoading" class="align-center justify-center" persistent no-click-animation scrim="white" opacity="0.8">
       <div class="d-flex flex-column align-center">
          <v-progress-circular indeterminate color="primary" size="48" width="4"></v-progress-circular>
          <div class="text-caption font-weight-bold text-uppercase mt-4 letter-spacing-1 text-primary">Carregando Dados...</div>
       </div>
    </v-overlay>

  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, defineAsyncComponent } from 'vue';
import { useThemeStore } from '@/stores/theme';
import { supabase } from '@/api/supabase';
import { startOfMonth, endOfMonth, addMonths, format, startOfWeek, endOfWeek, addWeeks, parseISO, isBefore } from 'date-fns';
import { ptBR } from 'date-fns/locale';
import { Chart as ChartJS, Title, Tooltip, Legend, BarElement, CategoryScale, LinearScale } from 'chart.js';

// Charts
ChartJS.register(Title, Tooltip, Legend, BarElement, CategoryScale, LinearScale);
const Bar = defineAsyncComponent(() => import('vue-chartjs').then(c => c.Bar));

const themeStore = useThemeStore();
const isLoading = ref(false);

// State Data
const mjMetrics = ref({ total: 0, received: 0, overdue: 0, expense: 0, income: 0, balance: 0, history: [] as any[] });
const cajuiaMetrics = ref({ total: 0, received: 0, overdue: 0, expense: 0, income: 0, balance: 0, history: [] as any[] });
const projectionRows = ref<any[]>([]);

const holdingMetrics = computed(() => ({
   total: mjMetrics.value.total + cajuiaMetrics.value.total,
   balance: mjMetrics.value.balance + cajuiaMetrics.value.balance,
   expense: mjMetrics.value.expense + cajuiaMetrics.value.expense,
   projectedTotal: mjMetrics.value.total + cajuiaMetrics.value.total // Simplificação para demo
}));

const efficiencyMetrics = computed(() => {
   const totalRec = holdingMetrics.value.total || 1;
   const received = mjMetrics.value.received + cajuiaMetrics.value.received;
   const overdue = mjMetrics.value.overdue + cajuiaMetrics.value.overdue;
   return {
      receivedRate: received / totalRec,
      overdueRate: overdue / totalRec
   };
});

// --- DATA FETCHING ---
const fetchData = async () => {
   isLoading.value = true;
   try {
      const now = new Date();
      const start = startOfMonth(now).toISOString();
      const end = endOfMonth(now).toISOString();

      // 1. MJ DATA
      const { data: mjRec } = await supabase
         .from('finance_receivables')
         .select('value, due_date, status')
         .gte('due_date', start).lte('due_date', end);

      const mjTotal = mjRec?.reduce((acc, i) => acc + (Number(i.value) || 0), 0) || 0;
      const mjReceived = mjRec?.filter(i => ['paid','pago'].includes(i.status?.toLowerCase())).reduce((acc, i) => acc + (Number(i.value) || 0), 0) || 0;
      const mjOverdue = mjRec?.filter(i => isBefore(parseISO(i.due_date), now) && !['paid','pago'].includes(i.status?.toLowerCase())).reduce((acc, i) => acc + (Number(i.value) || 0), 0) || 0;

      mjMetrics.value = {
         total: mjTotal,
         received: mjReceived,
         overdue: mjOverdue,
         income: mjTotal,
         expense: 0, // Placeholder
         balance: mjTotal - 0,
         history: generateMockHistory(mjTotal)
      };

      // 2. CAJUIA DATA
      const { data: cjRec } = await supabase
         .from('cajuia_receivables')
         .select('gross_value, due_date, status')
         .gte('due_date', start).lte('due_date', end);

      const cjTotal = cjRec?.reduce((acc, i) => acc + (Number(i.gross_value) || 0), 0) || 0;
      const cjReceived = cjRec?.filter(i => ['paid','pago'].includes(i.status?.toLowerCase())).reduce((acc, i) => acc + (Number(i.gross_value) || 0), 0) || 0;
      const cjOverdue = cjRec?.filter(i => isBefore(parseISO(i.due_date), now) && !['paid','pago'].includes(i.status?.toLowerCase())).reduce((acc, i) => acc + (Number(i.gross_value) || 0), 0) || 0;

      cajuiaMetrics.value = {
         total: cjTotal,
         received: cjReceived,
         overdue: cjOverdue,
         income: cjTotal,
         expense: 0, // Placeholder
         balance: cjTotal - 0,
         history: generateMockHistory(cjTotal)
      };

      // 3. PROJECTIONS
      generateProjections(now, mjRec || [], cjRec || []);

   } catch (e) { console.error(e); } finally { isLoading.value = false; }
};

const generateMockHistory = (total: number) => {
   const base = total / 6;
   return Array.from({ length: 6 }, (_, i) => ({
      label: format(addMonths(new Date(), -5 + i), 'MMM'),
      income: base * (0.8 + Math.random() * 0.4),
      expense: base * 0.5 // Mock expense approx 50%
   }));
};

const generateProjections = (baseDate: Date, mj: any[], cj: any[]) => {
   const rows = [];
   for(let i=0; i<4; i++) {
      const s = addWeeks(startOfWeek(baseDate), i);
      const e = endOfWeek(s);

      const mjIn = mj.filter(x => isBetween(x.due_date, s, e)).reduce((a,b) => a + (Number(b.value)||0), 0);
      const cjIn = cj.filter(x => isBetween(x.due_date, s, e)).reduce((a,b) => a + (Number(b.gross_value)||0), 0);

      rows.push({
         label: `Semana ${i+1}`,
         dateRange: `${format(s, 'dd/MM')} - ${format(e, 'dd/MM')}`,
         mjIn, mjOut: 0, cjIn, cjOut: 0, balance: (mjIn + cjIn)
      });
   }
   projectionRows.value = rows;
};

const isBetween = (d: string, start: Date, end: Date) => {
   const date = parseISO(d);
   return date >= start && date <= end;
};

// --- CHART OPTIONS ---
const commonOptions = {
   responsive: true, maintainAspectRatio: false,
   plugins: { legend: { display: false }, tooltip: { enabled: true, mode: 'index', intersect: false } },
   scales: { x: { display: false }, y: { display: false } },
   barPercentage: 0.6, categoryPercentage: 0.8
};
const chartOptions = { ...commonOptions };
const chartOptionsDark = { ...commonOptions };

const mjChartData = computed(() => ({
   labels: mjMetrics.value.history.map(h => h.label),
   datasets: [
      { label: 'Entradas', data: mjMetrics.value.history.map(h => h.income), backgroundColor: '#2196F3', borderRadius: 3 },
      { label: 'Saídas', data: mjMetrics.value.history.map(h => h.expense), backgroundColor: '#EF5350', borderRadius: 3 }
   ]
}));

const cajuiaChartData = computed(() => ({
   labels: cajuiaMetrics.value.history.map(h => h.label),
   datasets: [
      { label: 'Entradas', data: cajuiaMetrics.value.history.map(h => h.income), backgroundColor: '#FF9800', borderRadius: 3 },
      { label: 'Saídas', data: cajuiaMetrics.value.history.map(h => h.expense), backgroundColor: '#EF5350', borderRadius: 3 }
   ]
}));

const totalChartData = computed(() => ({
   labels: mjMetrics.value.history.map(h => h.label),
   datasets: [
      { label: 'Total Entradas', data: mjMetrics.value.history.map((h, i) => h.income + (cajuiaMetrics.value.history[i]?.income||0)), backgroundColor: '#FFFFFF', borderRadius: 3 },
      { label: 'Total Saídas', data: mjMetrics.value.history.map((h, i) => h.expense + (cajuiaMetrics.value.history[i]?.expense||0)), backgroundColor: 'rgba(255,255,255,0.4)', borderRadius: 3 }
   ]
}));

// --- HELPERS ---
const formatCurrency = (v: number) => new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(v);
const formatCompact = (v: number) => new Intl.NumberFormat('pt-BR', { notation: "compact", compactDisplay: "short", style: 'currency', currency: 'BRL' }).format(v);
const formatPercent = (v: number) => new Intl.NumberFormat('pt-BR', { style: 'percent', minimumFractionDigits: 1 }).format(v || 0);

onMounted(fetchData);
</script>

<style scoped lang="scss">
.analytics-card {
   border-radius: 12px;
   background: white;
   transition: box-shadow 0.3s ease;
   overflow: hidden;
   &:hover { box-shadow: 0 12px 24px rgba(0,0,0,0.08); }
}

.mini-stat-card {
   background: white;
   border-radius: 8px;
}

.bg-gradient-brand {
   background: linear-gradient(135deg, #1565C0, #0D47A1); // Deep Blue
}

.absolute-overlay {
   position: absolute; top:0; left:0; width:100%; height:100%;
   background: radial-gradient(circle at top right, rgba(255,255,255,0.1), transparent 60%);
   pointer-events: none;
}

// Typography
.lh-1 { line-height: 1; }
.font-mono { font-family: 'Roboto Mono', monospace; }
.flex-1 { flex: 1; }

// Icons
.icon-box-xs { width: 32px; height: 32px; display: flex; align-items: center; justify-content: center; }

// Dots
.legend-dot { width: 8px; height: 8px; border-radius: 50%; }

// Table
.projection-table {
   th { height: 36px !important; }
   td { height: 48px !important; }
   .hover-row:hover { background-color: #F5F5F5; }
   .border-l { border-left: 1px solid rgba(0,0,0,0.06); }
   .sub-header th { font-size: 9px; padding: 0 8px !important; height: 28px !important; }
}

.bg-surface-lighten-1 { background-color: #FAFAFA; }
.bg-white-20 { background-color: rgba(255,255,255,0.2); }
.bg-white-10 { background-color: rgba(255,255,255,0.1); }
.bg-black-20 { background-color: rgba(0,0,0,0.2); }
.text-white-70 { color: rgba(255,255,255,0.7); }
</style>
