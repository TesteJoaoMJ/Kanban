<template>
  <div class="admin-mj-view animate-fade-in-up">

    <v-row dense class="mb-6">
      <v-col cols="12" sm="6" lg="3">
        <v-card class="kpi-card bg-gradient-indigo hover-elevate" v-ripple>
          <div class="kpi-bg-icon"><v-icon>mdi-factory</v-icon></div>
          <div class="d-flex flex-column position-relative z-10 h-100 justify-space-between">
            <div>
              <span class="kpi-label text-white-70">Fila de Produção</span>
              <div class="kpi-number-group mt-1">
                <span class="kpi-value text-h4">{{ formatNumber(productionQueueMeters) }}</span>
                <span class="kpi-unit">metros</span>
              </div>
            </div>
            <div class="kpi-footer bg-black-20">
              <v-icon size="x-small" color="white" class="mr-1">mdi-tshirt-crew</v-icon>
              {{ productionQueueCount }} pedidos aguardando
            </div>
          </div>
        </v-card>
      </v-col>

      <v-col cols="12" sm="6" lg="3">
        <v-card class="kpi-card bg-gradient-blue hover-elevate" v-ripple>
          <div class="kpi-bg-icon"><v-icon>mdi-truck-fast</v-icon></div>
          <div class="d-flex flex-column position-relative z-10 h-100 justify-space-between">
            <div>
              <span class="kpi-label text-white-70">Entregues (Mês)</span>
              <div class="kpi-number-group mt-1">
                <span class="kpi-value text-h4">{{ formatNumber(deliveredMeters) }}</span>
                <span class="kpi-unit">m</span>
              </div>
            </div>
            <div class="kpi-footer bg-black-20">
              <v-icon size="x-small" color="white" class="mr-1">mdi-calendar-check</v-icon>
              {{ deliveredOrdersCount }} finalizados
            </div>
          </div>
        </v-card>
      </v-col>

      <v-col cols="12" sm="6" lg="3">
        <v-card class="kpi-card bg-gradient-cyan hover-elevate" v-ripple>
          <div class="kpi-bg-icon"><v-icon>mdi-cash-multiple</v-icon></div>
          <div class="d-flex flex-column position-relative z-10 h-100 justify-space-between">
            <div>
              <span class="kpi-label text-white-70">Receita B2B</span>
              <div class="kpi-number-group mt-1">
                <span class="kpi-unit mr-1">R$</span>
                <span class="kpi-value text-h4">{{ formatCurrencyCompact(revenueTotal) }}</span>
              </div>
            </div>
            <div class="kpi-footer bg-black-20">
               Projeção: {{ formatCurrencyCompact(revenueProjection) }}
            </div>
          </div>
        </v-card>
      </v-col>

      <v-col cols="12" sm="6" lg="3">
        <v-card class="kpi-card bg-gradient-deep-orange hover-elevate" v-ripple>
          <div class="kpi-bg-icon"><v-icon>mdi-alert-octagon</v-icon></div>
          <div class="d-flex flex-column position-relative z-10 h-100 justify-space-between">
            <div>
              <span class="kpi-label text-white-70">Atenção Necessária</span>
              <div class="kpi-number-group mt-1">
                <span class="kpi-value text-h4">{{ delayedOrdersCount }}</span>
                <span class="kpi-unit">pedidos</span>
              </div>
            </div>
            <div class="kpi-footer bg-black-20">
              Atraso > 48h no Design/Prod
            </div>
          </div>
        </v-card>
      </v-col>
    </v-row>

    <v-row class="mb-6" dense>
      <v-col cols="12" md="8">
        <v-card class="chart-panel-premium pa-0 rounded-xl border-thin h-100 d-flex flex-column overflow-hidden" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-surface-darker'">
           <div class="px-5 pt-5 pb-2 d-flex align-center justify-space-between">
              <div class="d-flex align-center">
                 <div class="icon-box-sm bg-indigo-lighten-5 rounded-lg mr-3"><v-icon color="indigo">mdi-chart-bar-stacked</v-icon></div>
                 <div>
                    <div class="text-subtitle-1 font-weight-bold">Volume de Produção</div>
                    <div class="text-caption text-medium-emphasis">Metros Processados (Semanal)</div>
                 </div>
              </div>
              <v-tooltip location="top" content-class="custom-tooltip">
                <template v-slot:activator="{ props }">
                  <v-icon v-bind="props" color="grey" size="small">mdi-information-outline</v-icon>
                </template>
                <span>Considera corte, impressão e calandra.</span>
              </v-tooltip>
           </div>

           <div class="flex-grow-1 position-relative px-4" style="min-height: 280px;">
              <Bar :data="productionChartData" :options="productionChartOptions" />
           </div>

           <div class="bg-surface-lighten-1 pa-4 mt-2 border-t" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5' : 'bg-white-05'">
              <v-row dense>
                 <v-col cols="4" class="text-center border-r border-opacity-10">
                    <div class="text-caption text-medium-emphasis mb-1">Média Diária</div>
                    <div class="text-body-2 font-weight-black text-indigo">450m</div>
                 </v-col>
                 <v-col cols="4" class="text-center border-r border-opacity-10">
                    <div class="text-caption text-medium-emphasis mb-1">Recorde Semanal</div>
                    <div class="text-body-2 font-weight-black text-success">3.200m</div>
                 </v-col>
                 <v-col cols="4" class="text-center">
                    <div class="text-caption text-medium-emphasis mb-1">Capacidade Utilizada</div>
                    <div class="text-body-2 font-weight-black text-warning">82%</div>
                 </v-col>
              </v-row>
           </div>
        </v-card>
      </v-col>

      <v-col cols="12" md="4">
        <v-card class="chart-panel-premium pa-0 rounded-xl border-thin h-100 d-flex flex-column overflow-hidden" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-surface-darker'">
           <div class="px-5 pt-5 pb-2 d-flex align-center justify-space-between">
              <div class="d-flex align-center">
                 <div class="icon-box-sm bg-teal-lighten-5 rounded-lg mr-3"><v-icon color="teal">mdi-shape-outline</v-icon></div>
                 <div>
                    <div class="text-subtitle-1 font-weight-bold">Mix de Tecidos</div>
                    <div class="text-caption text-medium-emphasis">Top 5 Substratos</div>
                 </div>
              </div>
           </div>

           <div class="flex-grow-1 position-relative px-4 d-flex align-center justify-center" style="min-height: 280px;">
              <Doughnut :data="fabricChartData" :options="doughnutOptions" />
           </div>

           <div class="bg-surface-lighten-1 pa-4 mt-2 border-t text-center" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5' : 'bg-white-05'">
              <div class="text-caption text-medium-emphasis">Malha continua sendo o carro-chefe (45%)</div>
           </div>
        </v-card>
      </v-col>
    </v-row>

    <v-card
       class="rounded-xl border-thin overflow-hidden"
       :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-surface-darker'"
    >
      <div class="px-6 py-5 border-b d-flex align-center justify-space-between" :class="themeStore.currentMode === 'light' ? 'border-grey-lighten-2' : 'border-white-05'">
         <div class="d-flex align-center">
            <div class="icon-box-sm bg-blue-grey-lighten-5 rounded-lg mr-3"><v-icon color="blue-grey">mdi-clipboard-list-outline</v-icon></div>
            <div>
               <h3 class="text-subtitle-1 font-weight-bold">Status da Produção</h3>
               <div class="text-caption text-medium-emphasis">Pedidos em andamento e fila de corte</div>
            </div>
         </div>
         <v-chip size="small" variant="outlined" class="font-weight-bold">Total: {{ activeOrders.length }}</v-chip>
      </div>

      <v-data-table
        :headers="tableHeaders"
        :items="activeOrders"
        density="comfortable"
        :class="themeStore.currentMode === 'light' ? 'light-table' : 'glass-table'"
        class="premium-table"
        hover
      >
         <template v-slot:item.customer="{ item }">
            <div class="d-flex flex-column py-2">
               <span class="font-weight-bold text-body-2">{{ item.customer_name }}</span>
               <span class="text-caption text-medium-emphasis">#{{ String(item.order_number).padStart(4, '0') }}</span>
            </div>
         </template>

         <template v-slot:item.stage="{ item }">
            <v-chip
               size="small"
               :color="getStageColor(item.status)"
               variant="tonal"
               class="font-weight-bold text-uppercase"
            >
               <v-icon start size="x-small">{{ getStageIcon(item.status) }}</v-icon>
               {{ getStageLabel(item.status) }}
            </v-chip>
         </template>

         <template v-slot:item.progress="{ item }">
            <div class="d-flex align-center" style="width: 120px;">
               <v-progress-linear
                  :model-value="getProgressValue(item.status)"
                  :color="getStageColor(item.status)"
                  height="6"
                  rounded
                  class="mr-2"
               ></v-progress-linear>
               <span class="text-caption font-weight-bold">{{ getProgressValue(item.status) }}%</span>
            </div>
         </template>

         <template v-slot:item.actions="{ item }">
            <v-btn icon size="x-small" variant="text" color="primary">
               <v-icon>mdi-eye</v-icon>
               <v-tooltip activator="parent" location="top" content-class="custom-tooltip">Ver Detalhes</v-tooltip>
            </v-btn>
         </template>
      </v-data-table>
    </v-card>
  </div>
</template>

<script setup lang="ts">
import { computed, defineAsyncComponent } from 'vue';
import { useThemeStore } from '@/stores/theme';
import { useDashboardStore } from '@/stores/dashboard'; // Usando a store principal que já tem os dados MJ
import { storeToRefs } from 'pinia';
import { Chart as ChartJS, Title, Tooltip, Legend, BarElement, CategoryScale, LinearScale, ArcElement } from 'chart.js';

ChartJS.register(Title, Tooltip, Legend, BarElement, CategoryScale, LinearScale, ArcElement);

const Bar = defineAsyncComponent(() => import('vue-chartjs').then(c => c.Bar));
const Doughnut = defineAsyncComponent(() => import('vue-chartjs').then(c => c.Doughnut));

const themeStore = useThemeStore();
const dashboardStore = useDashboardStore();
const { orders, monthlySalesPerformance, salesByFabric } = storeToRefs(dashboardStore);

// --- MÉTODOS DE FORMATAÇÃO ---
const formatNumber = (v: number) => Number(v).toLocaleString('pt-BR');
const formatCurrencyCompact = (v: number) => new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL', notation: 'compact' }).format(v);

// --- DADOS COMPUTADOS (MOCKS REAIS BASEADOS NA STORE) ---
const activeOrders = computed(() => {
   // Filtra pedidos que estão em estágios de produção
   return orders.value.filter(o => ['production_queue', 'in_printing', 'in_cutting', 'sewing', 'finishing'].includes(o.status)).slice(0, 8);
});

const productionQueueMeters = computed(() => activeOrders.value.reduce((acc, curr) => acc + (curr.quantity_meters || 0), 0));
const productionQueueCount = computed(() => activeOrders.value.length);
const deliveredOrders = computed(() => orders.value.filter(o => o.status === 'delivered'));
const deliveredMeters = computed(() => deliveredOrders.value.reduce((acc, curr) => acc + (curr.quantity_meters || 0), 0));
const deliveredOrdersCount = computed(() => deliveredOrders.value.length);
const revenueTotal = computed(() => 85400); // Mockado pois não temos tabela de valores exatos no orders ainda
const revenueProjection = computed(() => 120000);
const delayedOrdersCount = computed(() => orders.value.filter(o => o.status === 'design_delayed').length || 3);

// --- CHART DATA ---
const productionChartData = computed(() => ({
   labels: monthlySalesPerformance.value.labels, // Reutilizando labels da store
   datasets: [{
      label: 'Produção (m)',
      data: monthlySalesPerformance.value.data,
      backgroundColor: '#3F51B5',
      borderRadius: 4,
      barPercentage: 0.6
   }]
}));

const fabricChartData = computed(() => ({
   labels: salesByFabric.value.slice(0, 5).map(f => f.fabric),
   datasets: [{
      data: salesByFabric.value.slice(0, 5).map(f => f.totalMeters),
      backgroundColor: ['#26C6DA', '#AB47BC', '#FFA726', '#EF5350', '#7E57C2'],
      borderWidth: 0
   }]
}));

// --- CHART OPTIONS ---
const chartTextColor = computed(() => themeStore.currentMode === 'light' ? '#424242' : '#e0e0e0');
const chartGridColor = computed(() => themeStore.currentMode === 'light' ? 'rgba(0,0,0,0.05)' : 'rgba(255,255,255,0.05)');

const productionChartOptions = computed(() => ({
   responsive: true,
   maintainAspectRatio: false,
   plugins: {
      legend: { display: false },
      tooltip: {
         backgroundColor: '#212121', // Fundo escuro forçado
         titleColor: '#FFFFFF',
         bodyColor: '#FFFFFF',
         padding: 10,
         cornerRadius: 8,
         displayColors: false,
         callbacks: {
            label: (ctx: any) => `${formatNumber(ctx.raw)} metros`
         }
      }
   },
   scales: {
      x: { grid: { display: false }, ticks: { color: chartTextColor.value } },
      y: { grid: { color: chartGridColor.value, borderDash: [4, 4] }, ticks: { display: false } }
   }
}));

const doughnutOptions = computed(() => ({
   responsive: true,
   maintainAspectRatio: false,
   plugins: {
      legend: { position: 'right', labels: { color: chartTextColor.value, usePointStyle: true, boxWidth: 8 } }
   }
}));

// --- TABLE CONFIG ---
const tableHeaders = [
   { title: 'Cliente / Pedido', key: 'customer', align: 'start' },
   { title: 'Data Entrada', key: 'created_at', align: 'start' },
   { title: 'Etapa Atual', key: 'stage', align: 'center' },
   { title: 'Progresso', key: 'progress', align: 'start' },
   { title: 'Ações', key: 'actions', align: 'end', sortable: false },
];

const getStageColor = (status: string) => {
   const map: any = { production_queue: 'grey', in_printing: 'indigo', in_cutting: 'cyan', sewing: 'purple', finishing: 'teal' };
   return map[status] || 'grey';
};
const getStageLabel = (status: string) => {
   const map: any = { production_queue: 'Fila', in_printing: 'Impressão', in_cutting: 'Corte', sewing: 'Costura', finishing: 'Acabamento' };
   return map[status] || status;
};
const getStageIcon = (status: string) => {
   const map: any = { production_queue: 'mdi-tray-full', in_printing: 'mdi-printer-3d', in_cutting: 'mdi-scissors-cutting', sewing: 'mdi-needle', finishing: 'mdi-check-all' };
   return map[status] || 'mdi-circle';
};
const getProgressValue = (status: string) => {
   const map: any = { production_queue: 10, in_printing: 30, in_cutting: 50, sewing: 75, finishing: 90 };
   return map[status] || 0;
};
</script>

<style scoped lang="scss">
/* Reuse Styles from Dashboard for consistency */
.kpi-card { height: 120px; border-radius: 16px; padding: 16px; position: relative; overflow: hidden; border: 1px solid rgba(255,255,255,0.1); cursor: pointer; transition: all 0.3s ease; color: white; display: flex; flex-direction: column; justify-content: space-between; }
.kpi-card:hover { transform: translateY(-6px); box-shadow: 0 12px 30px rgba(0,0,0,0.4); filter: brightness(1.1); }
.kpi-bg-icon { position: absolute; right: -20px; bottom: -20px; opacity: 0.15; transform: rotate(-15deg); pointer-events: none; }
.kpi-bg-icon .v-icon { font-size: 100px; color: white; }
.kpi-label { font-size: 0.7rem; font-weight: 700; text-transform: uppercase; letter-spacing: 1px; }
.kpi-value { font-weight: 900; line-height: 1; }
.kpi-footer { padding: 2px 6px; border-radius: 4px; display: inline-flex; align-items: center; width: fit-content; font-size: 0.7rem; }
.bg-black-20 { background: rgba(0,0,0,0.2); }

/* Gradients Industry */
.bg-gradient-indigo { background: linear-gradient(135deg, #3949AB, #1A237E); }
.bg-gradient-blue { background: linear-gradient(135deg, #1E88E5, #0D47A1); }
.bg-gradient-cyan { background: linear-gradient(135deg, #00ACC1, #006064); }
.bg-gradient-deep-orange { background: linear-gradient(135deg, #F4511E, #BF360C); }

/* Custom Tooltip Class (Global override might be needed in App.vue, but scoped works for components inside) */
:deep(.custom-tooltip) {
   background-color: #212121 !important;
   color: white !important;
   font-weight: 600;
   border: 1px solid rgba(255,255,255,0.2);
   border-radius: 6px;
}

/* Helpers */
.icon-box-sm { width: 32px; height: 32px; display: flex; align-items: center; justify-content: center; }
.text-white-70 { color: rgba(255,255,255,0.7); }
.border-white-05 { border-color: rgba(255,255,255,0.05) !important; }

/* Tables */
.premium-table :deep(th) { font-size: 0.7rem !important; text-transform: uppercase; letter-spacing: 1px; opacity: 0.7; font-weight: 700 !important; }
.glass-table :deep(th) { color: rgba(255,255,255,0.7) !important; border-bottom: 1px solid rgba(255,255,255,0.1) !important; background: transparent !important; }
.glass-table :deep(td) { border-bottom: 1px solid rgba(255,255,255,0.05) !important; color: white !important; }
.light-table :deep(th) { color: #616161 !important; background: #FAFAFA !important; border-bottom: 1px solid #EEEEEE !important; }
</style>
