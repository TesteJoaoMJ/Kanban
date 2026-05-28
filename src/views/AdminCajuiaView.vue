<template>
  <div class="admin-cajuia-view h-100 d-flex flex-column pa-6 bg-transparent">

    <div class="d-flex align-center gap-3 mb-6 animate-fade-in-down">
       <v-avatar color="orange-lighten-5" rounded="lg" size="40" class="border-thin">
          <v-icon color="orange-darken-3">mdi-storefront</v-icon>
       </v-avatar>
       <div>
          <h1 class="text-h5 font-weight-black text-orange-darken-4 lh-1">Cajuia Loja</h1>
          <div class="text-caption font-weight-bold text-uppercase opacity-60 letter-spacing-1">Gestão de Varejo & PDV</div>
       </div>
       <v-spacer></v-spacer>
       <div class="d-flex gap-2">
          <v-chip color="orange-darken-3" variant="outlined" class="font-weight-bold bg-white">
             <v-icon start size="small">mdi-store</v-icon>
             Loja Física: Aberta
          </v-chip>
       </div>
    </div>

    <v-row dense class="mb-6 animate-fade-in-up">
       <v-col cols="12" sm="6" md="3">
          <v-card class="mini-stat-card pa-4 d-flex align-center gap-4 border-thin" elevation="0">
             <div class="icon-box-sm bg-orange-lighten-5 rounded-lg text-orange-darken-3 elevation-1">
                <v-icon>mdi-shopping</v-icon>
             </div>
             <div>
                <div class="text-[10px] text-uppercase font-weight-bold opacity-60">Vendas Totais (Mês)</div>
                <div class="text-h6 font-weight-black font-mono text-orange-darken-3 lh-1">
                   {{ formatCompact(metrics.totalSales) }}
                </div>
                <div class="text-[10px] font-weight-bold text-medium-emphasis mt-1">
                   {{ metrics.ordersCount }} pedidos faturados
                </div>
             </div>
          </v-card>
       </v-col>

       <v-col cols="12" sm="6" md="3">
          <v-card class="mini-stat-card pa-4 d-flex align-center gap-4 border-thin" elevation="0">
             <div class="icon-box-sm bg-amber-lighten-5 rounded-lg text-amber-darken-3 elevation-1">
                <v-icon>mdi-ticket-percent</v-icon>
             </div>
             <div>
                <div class="text-[10px] text-uppercase font-weight-bold opacity-60">Ticket Médio</div>
                <div class="text-h6 font-weight-black font-mono text-amber-darken-4 lh-1">
                   {{ formatCurrency(metrics.avgTicket) }}
                </div>
                <div class="text-[10px] font-weight-bold text-success mt-1">
                   <v-icon size="x-small" color="success">mdi-arrow-up</v-icon> +5% vs mês ant.
                </div>
             </div>
          </v-card>
       </v-col>

       <v-col cols="12" sm="6" md="3">
          <v-card class="mini-stat-card pa-4 d-flex align-center gap-4 border-thin" elevation="0">
             <div class="icon-box-sm bg-red-lighten-5 rounded-lg text-red-darken-2 elevation-1">
                <v-icon>mdi-store-remove</v-icon>
             </div>
             <div>
                <div class="text-[10px] text-uppercase font-weight-bold opacity-60">Custos Loja</div>
                <div class="text-h6 font-weight-black font-mono text-red-darken-2 lh-1">
                   {{ formatCompact(metrics.expenses) }}
                </div>
                <div class="text-[10px] font-weight-bold text-red mt-1">
                   Despesas Fixas
                </div>
             </div>
          </v-card>
       </v-col>

       <v-col cols="12" sm="6" md="3">
          <v-card class="mini-stat-card pa-4 d-flex align-center gap-4 border-thin" elevation="0">
             <div class="icon-box-sm bg-green-lighten-5 rounded-lg text-green-darken-2 elevation-1">
                <v-icon>mdi-cash-register</v-icon>
             </div>
             <div>
                <div class="text-[10px] text-uppercase font-weight-bold opacity-60">Saldo em Caixa</div>
                <div class="text-h6 font-weight-black font-mono text-green-darken-3 lh-1">
                   {{ formatCompact(metrics.netBalance) }}
                </div>
                <div class="text-[10px] font-weight-bold text-green mt-1">
                   Disponível hoje
                </div>
             </div>
          </v-card>
       </v-col>
    </v-row>

    <v-row dense class="mb-6 flex-grow-0">
      <v-col cols="12" md="8">
        <v-card class="analytics-card h-100 d-flex flex-column border-thin elevation-1">
          <div class="pa-4 border-b bg-surface-lighten-1">
             <div class="d-flex justify-space-between align-center mb-2">
                <div class="d-flex align-center gap-2">
                   <div class="icon-box-xs bg-orange-darken-3 text-white rounded">
                      <v-icon size="14">mdi-chart-bar</v-icon>
                   </div>
                   <div>
                      <div class="text-subtitle-2 font-weight-black lh-1 text-orange-darken-4">Desempenho de Vendas</div>
                      <div class="text-[10px] opacity-60 font-weight-bold text-uppercase">Volume Diário (30 dias)</div>
                   </div>
                </div>
                <div class="d-flex gap-3">
                   <div class="d-flex align-center gap-1">
                      <div class="legend-dot bg-orange"></div> <span class="text-[10px] font-weight-bold">Físico</span>
                   </div>
                   <div class="d-flex align-center gap-1">
                      <div class="legend-dot bg-cyan"></div> <span class="text-[10px] font-weight-bold">Online</span>
                   </div>
                </div>
             </div>
          </div>

          <div class="chart-container flex-grow-1 px-4 py-4 relative bg-white">
             <Bar :data="salesChartData" :options="chartOptions" />
          </div>
        </v-card>
      </v-col>

      <v-col cols="12" md="4">
        <v-card class="analytics-card h-100 d-flex flex-column border-thin elevation-1 bg-gradient-orange text-white border-0">
          <div class="absolute-circles"></div>
          <div class="pa-4 relative z-10 border-b border-white-10">
             <div class="d-flex align-center gap-2 mb-2">
                <v-icon color="white" size="20">mdi-credit-card-settings-outline</v-icon>
                <h3 class="text-subtitle-1 font-weight-black">Métodos de Pagamento</h3>
             </div>
             <div class="text-caption text-white-70">Distribuição do Faturamento</div>
          </div>

          <div class="pa-4 flex-grow-1 relative z-10 d-flex flex-column gap-4 justify-center">
             <div>
                <div class="d-flex justify-space-between text-caption font-weight-bold mb-1">
                   <div class="d-flex align-center gap-1"><v-icon size="x-small">mdi-qrcode</v-icon> PIX</div>
                   <span>45%</span>
                </div>
                <v-progress-linear model-value="45" color="white" height="6" rounded class="opacity-90"></v-progress-linear>
                <div class="text-[10px] text-white-50 mt-1">{{ formatCurrency(metrics.totalSales * 0.45) }}</div>
             </div>

             <div>
                <div class="d-flex justify-space-between text-caption font-weight-bold mb-1">
                   <div class="d-flex align-center gap-1"><v-icon size="x-small">mdi-credit-card</v-icon> Crédito</div>
                   <span>35%</span>
                </div>
                <v-progress-linear model-value="35" color="white" height="6" rounded class="opacity-70"></v-progress-linear>
                <div class="text-[10px] text-white-50 mt-1">{{ formatCurrency(metrics.totalSales * 0.35) }}</div>
             </div>

             <div>
                <div class="d-flex justify-space-between text-caption font-weight-bold mb-1">
                   <div class="d-flex align-center gap-1"><v-icon size="x-small">mdi-cash</v-icon> Débito/Cash</div>
                   <span>20%</span>
                </div>
                <v-progress-linear model-value="20" color="white" height="6" rounded class="opacity-50"></v-progress-linear>
                <div class="text-[10px] text-white-50 mt-1">{{ formatCurrency(metrics.totalSales * 0.20) }}</div>
             </div>
          </div>
        </v-card>
      </v-col>
    </v-row>

    <v-card class="border-thin rounded-lg elevation-1 d-flex flex-column flex-grow-1 animate-fade-in-up" style="animation-delay: 0.1s">
       <div class="pa-4 border-b d-flex justify-space-between align-center bg-surface-lighten-1">
          <div class="d-flex align-center gap-2">
             <v-icon color="orange-darken-3" size="20">mdi-calendar-clock</v-icon>
             <div>
                <h3 class="text-subtitle-2 font-weight-black text-uppercase text-orange-darken-4">Fluxo de Caixa Varejo</h3>
                <div class="text-[10px] text-medium-emphasis font-weight-bold">Projeção de Entradas e Saídas</div>
             </div>
          </div>
          <v-chip size="x-small" color="success" variant="flat">Caixa Positivo</v-chip>
       </div>

       <v-table density="compact" class="projection-table flex-grow-1">
          <thead>
             <tr>
                <th class="text-left font-weight-black text-uppercase text-[10px] text-medium-emphasis bg-grey-lighten-5 pl-4" style="width: 25%">Período</th>
                <th class="text-right font-weight-bold text-[10px] text-orange-darken-3 bg-orange-lighten-5 border-l">Vendas Previstas</th>
                <th class="text-right font-weight-bold text-[10px] text-red-darken-2 bg-red-lighten-5 border-l">Contas Loja</th>
                <th class="text-right font-weight-black text-[10px] text-grey-darken-3 bg-grey-lighten-4 border-l pr-4" style="width: 20%">Líquido</th>
             </tr>
          </thead>
          <tbody>
             <tr v-for="(row, idx) in projectionRows" :key="idx" class="hover-row">
                <td class="py-3 pl-4">
                   <div class="d-flex align-center gap-3">
                      <div class="icon-box-xs rounded bg-grey-lighten-4 text-medium-emphasis font-weight-bold text-[10px]">S{{idx+1}}</div>
                      <div class="d-flex flex-column">
                         <span class="text-caption font-weight-bold text-grey-darken-3">{{ row.label }}</span>
                         <span class="text-[9px] font-mono text-medium-emphasis">{{ row.dateRange }}</span>
                      </div>
                   </div>
                </td>
                <td class="text-right border-l font-mono text-caption text-orange-darken-2 font-weight-bold">
                   {{ formatCurrency(row.income) }}
                </td>
                <td class="text-right border-l font-mono text-caption text-red opacity-80">
                   {{ formatCurrency(row.expense) }}
                </td>
                <td class="text-right border-l bg-grey-lighten-5 font-mono text-body-2 font-weight-black pr-4">
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
          <v-progress-circular indeterminate color="orange-darken-2" size="48" width="4"></v-progress-circular>
          <div class="text-caption font-weight-bold text-uppercase mt-4 letter-spacing-1 text-orange-darken-2">Sincronizando PDV...</div>
       </div>
    </v-overlay>

  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, defineAsyncComponent } from 'vue';
import { supabase } from '@/api/supabase';
import { startOfMonth, endOfMonth, format, startOfWeek, endOfWeek, addWeeks, parseISO, subDays } from 'date-fns';
import { ptBR } from 'date-fns/locale';
import { Chart as ChartJS, Title, Tooltip, Legend, BarElement, CategoryScale, LinearScale } from 'chart.js';

ChartJS.register(Title, Tooltip, Legend, BarElement, CategoryScale, LinearScale);
const Bar = defineAsyncComponent(() => import('vue-chartjs').then(c => c.Bar));

const isLoading = ref(false);

// State
const metrics = ref({ totalSales: 0, ordersCount: 0, avgTicket: 0, expenses: 0, netBalance: 0 });
const dailySales = ref<any[]>([]);
const projectionRows = ref<any[]>([]);

// Fetch Data
const fetchData = async () => {
   isLoading.value = true;
   try {
      const now = new Date();
      const start = startOfMonth(now).toISOString();
      const end = endOfMonth(now).toISOString();

      // Cajuia Sales (Receivables for now)
      const { data: sales } = await supabase.from('cajuia_receivables').select('gross_value, due_date').gte('due_date', start).lte('due_date', end);
      // Cajuia Expenses
      const { data: expenses } = await supabase.from('cajuia_payables').select('value').gte('due_date', start).lte('due_date', end);

      const totalS = sales?.reduce((acc, i) => acc + (Number(i.gross_value) || 0), 0) || 0;
      const totalE = expenses?.reduce((acc, i) => acc + (Number(i.value) || 0), 0) || 0;
      const count = sales?.length || 0;

      metrics.value = {
         totalSales: totalS,
         ordersCount: count,
         avgTicket: count > 0 ? totalS / count : 0,
         expenses: totalE,
         netBalance: totalS - totalE
      };

      // Mock Daily Sales History
      dailySales.value = generateMockDailySales(totalS);
      projectionRows.value = generateProjections(now, totalS/4, totalE/4);

   } catch (e) { console.error(e); } finally { isLoading.value = false; }
};

const generateMockDailySales = (total: number) => {
   const dailyAvg = total / 30;
   return Array.from({ length: 15 }, (_, i) => ({
      label: format(subDays(new Date(), 14 - i), 'dd/MM'),
      physical: dailyAvg * (0.6 + Math.random()*0.4),
      online: dailyAvg * (0.3 + Math.random()*0.3)
   }));
};

const generateProjections = (baseDate: Date, weeklyIncome: number, weeklyExpense: number) => {
   const rows = [];
   for(let i=0; i<4; i++) {
      const s = addWeeks(startOfWeek(baseDate), i);
      const e = endOfWeek(s);
      rows.push({
         label: `Semana ${i+1}`,
         dateRange: `${format(s, 'dd/MM')} - ${format(e, 'dd/MM')}`,
         income: weeklyIncome * (0.9 + Math.random()*0.2),
         expense: weeklyExpense * (0.9 + Math.random()*0.2),
         balance: (weeklyIncome - weeklyExpense)
      });
   }
   return rows;
};

// Chart Options
const chartOptions = {
   responsive: true, maintainAspectRatio: false,
   plugins: { legend: { display: false }, tooltip: { enabled: true, mode: 'index', intersect: false, backgroundColor: 'rgba(0,0,0,0.9)', titleColor: '#fff', bodyColor: '#fff' } },
   scales: { x: { grid: { display: false } }, y: { display: false } },
   barPercentage: 0.6, categoryPercentage: 0.8, borderRadius: 3, stacked: true
};

const salesChartData = computed(() => ({
   labels: dailySales.value.map(h => h.label),
   datasets: [
      { label: 'Loja Física', data: dailySales.value.map(h => h.physical), backgroundColor: '#F57C00' },
      { label: 'Online', data: dailySales.value.map(h => h.online), backgroundColor: '#26C6DA' }
   ]
}));

// Helpers
const formatCurrency = (v: number) => new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(v);
const formatCompact = (v: number) => new Intl.NumberFormat('pt-BR', { notation: "compact", compactDisplay: "short", style: 'currency', currency: 'BRL' }).format(v);

onMounted(fetchData);
</script>

<style scoped lang="scss">
/* --- CORE STYLES --- */
.mini-stat-card {
   background: white; border-radius: 12px; transition: transform 0.2s;
   &:hover { transform: translateY(-2px); box-shadow: 0 4px 12px rgba(230, 81, 0, 0.08); }
}

.analytics-card {
   background: white; border-radius: 12px; overflow: hidden;
   box-shadow: 0 2px 8px rgba(0,0,0,0.04);
}

.bg-gradient-orange { background: linear-gradient(135deg, #EF6C00, #E65100); }
.absolute-circles {
   position: absolute; top:0; left:0; width:100%; height:100%;
   background-image: radial-gradient(circle, rgba(255,255,255,0.1) 10%, transparent 10%);
   background-size: 20px 20px; opacity: 0.4; pointer-events: none;
}

/* --- TYPOGRAPHY --- */
.lh-1 { line-height: 1; }
.font-mono { font-family: 'Roboto Mono', monospace; }
.text-white-70 { color: rgba(255,255,255,0.7); }
.text-white-50 { color: rgba(255,255,255,0.5); }
.bg-surface-lighten-1 { background-color: #FAFAFA; }
.border-white-10 { border-color: rgba(255,255,255,0.1) !important; }

/* --- ICONS --- */
.icon-box-sm { width: 42px; height: 42px; display: flex; align-items: center; justify-content: center; }
.icon-box-xs { width: 28px; height: 28px; display: flex; align-items: center; justify-content: center; }
.legend-dot { width: 8px; height: 8px; border-radius: 50%; }

/* --- TABLE --- */
.projection-table {
   th { height: 38px !important; }
   td { height: 52px !important; }
   .hover-row:hover { background-color: #F5F5F5; }
   .border-l { border-left: 1px solid rgba(0,0,0,0.06); }
}

/* --- ANIMATIONS --- */
.animate-fade-in-down { animation: fadeInDown 0.6s cubic-bezier(0.2, 0.8, 0.2, 1); }
.animate-fade-in-up { animation: fadeInUp 0.6s cubic-bezier(0.2, 0.8, 0.2, 1) backwards; }
@keyframes fadeInDown { from { opacity: 0; transform: translateY(-20px); } to { opacity: 1; transform: translateY(0); } }
@keyframes fadeInUp { from { opacity: 0; transform: translateY(20px); } to { opacity: 1; transform: translateY(0); } }
</style>
