<template>
  <div
    class="seller-dashboard-layout font-sans fill-height d-flex flex-column relative overflow-hidden"
    :class="isDark ? 'bg-glass-dark text-white' : 'bg-grey-lighten-5 text-grey-darken-4'"
  >
    <div v-if="isDark" class="background-carousel-wrapper">
       <div class="background-overlay"></div>
    </div>

    <div class="content-wrapper d-flex flex-column fill-height z-10 relative">
      <div
        class="header-bar px-6 py-4 d-flex flex-column flex-md-row align-start align-md-center justify-space-between flex-shrink-0"
        :class="isDark ? 'bg-glass-header border-bottom-white-05' : 'bg-white border-b border-grey-lighten-2 shadow-sm'"
      >
        <div class="d-flex flex-column mb-3 mb-md-0">
          <div class="breadcrumb text-caption mb-1">
            <span class="opacity-70 font-weight-black text-uppercase ls-1">Cajuia Store</span>
            <span class="mx-2 opacity-50">></span>
            <span class="text-primary font-weight-black text-uppercase ls-1">Área do Vendedor</span>
          </div>
          <div class="text-h5 font-weight-black tracking-tight leading-none d-flex align-center mt-1" :class="isDark ? 'text-white' : 'text-grey-darken-4'">
            <v-icon start :color="isDark ? 'blue-lighten-2' : 'primary'" size="28" class="mr-2">mdi-view-dashboard-outline</v-icon>
            Dashboard Operacional
          </div>
        </div>

        <div class="d-flex align-center gap-4 text-caption font-weight-bold" :class="isDark ? 'text-white-70' : 'text-grey-darken-2'">
          <div class="d-flex align-center bg-grey-lighten-4 rounded-lg px-3 py-1 border-thin" :class="isDark ? 'bg-grey-darken-4 border-white-10' : ''">
            <v-icon size="16" class="mr-2" :color="isDark ? 'white' : 'grey-darken-3'">mdi-clock-outline</v-icon>
            <span class="font-mono text-[13px]">{{ currentTime }}</span>
          </div>

          <div class="d-flex align-center">
            <v-icon size="12" color="success" class="mr-1 pulse-icon">mdi-circle</v-icon>
            <span class="text-uppercase tracking-widest text-[10px]">Online</span>
          </div>

          <div class="d-flex align-center">
            <v-icon size="16" class="mr-1">mdi-cloud-sync</v-icon>
            <span class="font-mono text-[11px]">Sinc: {{ lastSyncTime }}</span>
          </div>
        </div>
      </div>

      <div class="flex-grow-1 overflow-y-auto custom-scroll px-4 px-md-6 pt-6 pb-8">
        <v-row class="mb-6">
          <v-col cols="12">
            <v-card class="pa-5 d-flex flex-wrap align-center justify-space-between rounded-xl border-thin shadow-sm" :class="isDark ? 'glass-card border-white-10' : 'bg-white'" elevation="0">
              <div class="d-flex align-center mb-4 mb-md-0">
                <v-avatar size="64" class="mr-5 elevation-4 border-thin" :class="isDark ? 'border-white-20' : 'border-primary-lighten-4'">
                  <v-img :src="userStore.profile?.avatar_url || ''" cover>
                    <template v-slot:placeholder>
                      <div class="d-flex align-center justify-center fill-height bg-gradient-primary">
                        <span class="text-h5 font-weight-black text-white">{{ userInitials }}</span>
                      </div>
                    </template>
                  </v-img>
                </v-avatar>

                <div>
                  <div class="d-flex align-center">
                    <h1 class="text-h4 font-weight-black mr-2 tracking-tight" :class="isDark ? 'text-white' : 'text-grey-darken-4'">
                      Olá, {{ userFirstName }}
                    </h1>
                    <span class="wave-emoji text-h4">👋</span>
                  </div>
                  <div class="d-flex align-center mt-2">
                    <v-chip size="small" color="primary" variant="flat" class="font-weight-black mr-3 chip-3d tracking-widest px-3">
                      VENDEDOR PDV
                    </v-chip>
                    <span class="text-caption font-weight-medium opacity-80 d-none d-sm-block">
                      Acompanhe suas métricas e rankings em tempo real.
                    </span>
                  </div>
                </div>
              </div>

              <div class="d-flex gap-3 align-center">
                 <v-menu location="bottom end" :close-on-content-click="false">
                    <template v-slot:activator="{ props }">
                       <v-btn
                         v-bind="props"
                         color="primary"
                         variant="flat"
                         class="btn-3d font-weight-black tracking-widest px-6"
                         height="48"
                       >
                         <v-icon start size="20">mdi-tune-variant</v-icon>
                         Opções e Filtros
                         <v-icon end size="20">mdi-chevron-down</v-icon>
                       </v-btn>
                    </template>
                    <v-card class="rounded-xl border-thin shadow-xl mt-2 overflow-hidden" width="300" :class="isDark ? 'bg-grey-darken-4' : 'bg-white'">
                        <div class="pa-4 bg-primary text-white d-flex align-center gap-3">
                            <v-icon>mdi-filter-cog-outline</v-icon>
                            <span class="font-weight-black text-uppercase ls-1">Painel de Controle</span>
                        </div>

                        <div class="pa-4">
                            <div class="text-caption font-weight-black opacity-70 mb-2 text-uppercase tracking-widest">Período de Análise</div>
                            <v-select
                                v-model="selectedPeriod"
                                :items="periodOptions"
                                item-title="label"
                                item-value="value"
                                variant="outlined"
                                density="compact"
                                hide-details
                                class="font-weight-bold mb-4"
                                :bg-color="isDark ? 'grey-darken-3' : 'grey-lighten-5'"
                                color="primary"
                            ></v-select>

                            <v-divider class="my-3 border-dashed opacity-20"></v-divider>

                            <div class="text-caption font-weight-black opacity-70 mb-2 text-uppercase tracking-widest">Layout e Acesso</div>
                            <v-btn
                               block
                               variant="outlined"
                               color="primary"
                               class="btn-3d font-weight-bold mb-3"
                               @click="toggleEditMode"
                               :loading="savingLayout"
                            >
                               <v-icon start>{{ isEditing ? 'mdi-content-save-outline' : 'mdi-view-dashboard-edit-outline' }}</v-icon>
                               {{ isEditing ? 'Concluir e Salvar Layout' : 'Organizar Widgets' }}
                            </v-btn>

                            <v-btn
                               block
                               color="success"
                               variant="flat"
                               class="btn-3d font-weight-black text-none"
                               :to="{ name: 'PDV' }"
                            >
                               <v-icon start>mdi-cart-outline</v-icon>
                               Abrir Caixa (PDV)
                            </v-btn>
                        </div>
                    </v-card>
                 </v-menu>
              </div>
            </v-card>
          </v-col>
        </v-row>

        <div v-if="loading" class="d-flex flex-column justify-center align-center w-100 py-12">
          <v-progress-circular indeterminate color="primary" size="64" width="4"></v-progress-circular>
          <span class="mt-4 text-caption font-weight-bold opacity-70 text-uppercase tracking-widest">Processando Métricas...</span>
        </div>

        <draggable
          v-else
          v-model="myWidgets"
          item-key="id"
          class="v-row w-100 ma-0"
          handle=".drag-handle"
          :disabled="!isEditing"
          @end="saveLayoutOrder"
        >
          <template #item="{ element }">
            <v-col :cols="12" :md="element.cols || 3" :key="element.id" class="pa-2 pa-md-3 transition-all" :class="isEditing ? 'editing-pulse' : ''">

              <v-card v-if="element.type === 'kpi'" class="kpi-card hover-elevate py-5 px-6 shadow-sm border-thin rounded-xl d-flex flex-column" :class="[element.gradient, isDark ? 'border-white-10' : '']" elevation="0" style="min-height: 160px;">
                  <div class="kpi-bg-icon"><v-icon>{{ element.icon }}</v-icon></div>
                  <div v-if="isEditing" class="absolute top-2 right-2 z-20">
                      <v-icon class="drag-handle cursor-move text-white opacity-50 hover-opacity-100 bg-black-20 rounded pa-1" size="20">mdi-drag</v-icon>
                  </div>
                  <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height w-100">
                    <div class="d-flex align-center gap-2 mb-3">
                      <v-icon size="24" class="opacity-80 text-white">{{ element.icon }}</v-icon>
                      <span class="kpi-label text-white">{{ element.title }}</span>
                    </div>
                    <div class="kpi-number-group my-1">
                      <span class="kpi-value text-h3 font-weight-black font-mono text-white text-shadow">{{ formatValue(element.value, element.format) }}</span>
                    </div>
                  </div>
              </v-card>

              <v-card v-else-if="element.type === 'list'" class="d-flex flex-column fill-height rounded-xl border-thin shadow-sm overflow-hidden" :class="isDark ? 'glass-card border-white-10' : 'bg-white'" elevation="0" style="min-height: 280px;">
                  <div class="pa-4 border-b d-flex align-center justify-space-between" :class="isDark ? 'bg-white-05 border-white-10' : 'bg-grey-lighten-5'">
                     <div class="d-flex align-center gap-3">
                         <div class="icon-box-sm rounded-lg d-flex align-center justify-center text-white shadow-sm" :class="element.gradient" style="width: 36px; height: 36px;">
                             <v-icon size="18">{{ element.icon }}</v-icon>
                         </div>
                         <h3 class="text-subtitle-2 font-weight-black text-uppercase tracking-widest ls-1" :class="isDark ? 'text-white' : 'text-grey-darken-3'">{{ element.title }}</h3>
                     </div>
                     <v-icon v-if="isEditing" class="drag-handle cursor-move opacity-50 hover-opacity-100" :class="isDark ? 'text-white' : 'text-grey-darken-2'" size="20">mdi-drag</v-icon>
                  </div>

                  <div class="flex-grow-1 overflow-y-auto custom-scroll w-100 pb-2">
                     <div class="grid-header sticky-head shadow-sm" :class="isDark ? 'grid-surface-dark' : 'grid-surface-light'" style="grid-template-columns: 1fr 140px; min-width: 100%;">
                        <div class="cell header-text pl-6">Descrição / Informações</div>
                        <div class="cell right header-text pr-6">Valor / Qtd</div>
                     </div>
                     <div v-if="!element.data?.length" class="pa-8 text-center opacity-50 d-flex flex-column align-center">
                        <v-icon size="40" class="mb-3">{{ element.query === 'last_orders' ? 'mdi-receipt-text-remove' : 'mdi-podium-silver' }}</v-icon>
                        <div class="text-[11px] font-weight-black text-uppercase tracking-widest">Sem dados no período</div>
                     </div>

                     <div v-for="(item, idx) in element.data" :key="idx" class="grid-row hover-bg-row transition-colors" :class="[isDark ? 'grid-row-dark' : 'grid-row-light', zebraClass(idx)]" style="grid-template-columns: 1fr 140px; min-width: 100%;">

                        <div class="cell pl-4 d-flex align-center gap-3">
                            <template v-if="element.query === 'last_orders'">
                                <div class="icon-box-sm rounded d-flex align-center justify-center bg-blue-grey-lighten-5 border border-blue-grey-lighten-4 text-blue-grey-darken-3" style="width: 32px; height: 32px; flex-shrink: 0;">
                                    <v-icon size="16">mdi-receipt-text-check</v-icon>
                                </div>
                                <div class="d-flex flex-column overflow-hidden">
                                    <span class="font-weight-bold text-[13px] text-truncate" :class="isDark ? 'text-white-80' : 'text-grey-darken-4'" :title="item.label">{{ item.label }}</span>
                                    <span class="text-[10px] opacity-70 font-mono mt-1">{{ item.sublabel }}</span>
                                </div>
                            </template>

                            <template v-else>
                                <div v-if="idx === 0" class="medal-badge medal-gold shadow-lg"><v-icon size="16" color="white">mdi-trophy</v-icon></div>
                                <div v-else-if="idx === 1" class="medal-badge medal-silver shadow-md"><v-icon size="16" color="white">mdi-medal</v-icon></div>
                                <div v-else-if="idx === 2" class="medal-badge medal-bronze shadow-md"><v-icon size="16" color="white">mdi-medal</v-icon></div>
                                <div v-else class="medal-badge bg-grey-lighten-2 text-grey-darken-3 font-weight-black shadow-sm">{{ idx + 1 }}º</div>

                                <span class="font-weight-bold text-[13px] text-truncate" :class="isDark ? 'text-white-80' : 'text-grey-darken-3'" :title="item.label">{{ item.label }}</span>
                            </template>
                        </div>

                        <div class="cell right pr-6">
                            <v-chip size="small" :color="(idx < 3 && element.query !== 'last_orders') ? 'primary' : (isDark ? 'grey-darken-3' : 'grey-lighten-3')" :variant="(idx < 3 && element.query !== 'last_orders') ? 'flat' : 'flat'" class="font-mono font-weight-black text-[13px] chip-3d" :class="!(idx < 3 && element.query !== 'last_orders') && isDark ? 'text-white' : (!(idx < 3 && element.query !== 'last_orders') ? 'text-grey-darken-4 border-thin' : '')">
                                {{ item.value }}
                            </v-chip>
                        </div>
                     </div>
                  </div>
              </v-card>

              <v-card v-else-if="element.type === 'chart'" class="d-flex flex-column fill-height rounded-xl border-thin shadow-sm overflow-hidden" :class="isDark ? 'glass-card border-white-10' : 'bg-white'" elevation="0" style="min-height: 380px;">
                  <div class="pa-4 border-b d-flex align-center justify-space-between" :class="isDark ? 'bg-white-05 border-white-10' : 'bg-grey-lighten-5'">
                     <div class="d-flex align-center gap-3">
                         <div class="icon-box-sm rounded-lg d-flex align-center justify-center text-white shadow-sm" :class="element.gradient" style="width: 36px; height: 36px;">
                             <v-icon size="18">{{ element.icon }}</v-icon>
                         </div>
                         <h3 class="text-subtitle-2 font-weight-black text-uppercase tracking-widest ls-1" :class="isDark ? 'text-white' : 'text-grey-darken-3'">{{ element.title }}</h3>
                     </div>
                     <v-icon v-if="isEditing" class="drag-handle cursor-move opacity-50 hover-opacity-100" :class="isDark ? 'text-white' : 'text-grey-darken-2'" size="20">mdi-drag</v-icon>
                  </div>

                  <div class="flex-grow-1 w-100 pa-4 d-flex align-center justify-center">
                     <div v-if="!element.data?.series?.length || element.data.series[0].data.length === 0" class="text-center opacity-50 d-flex flex-column align-center">
                        <v-icon size="40" class="mb-3">mdi-chart-line-stacked</v-icon>
                        <div class="text-[11px] font-weight-black text-uppercase tracking-widest">Sem dados gráficos</div>
                     </div>
                     <div v-else class="w-100 h-100" style="min-height: 250px;">
                        <apexchart
                          type="area"
                          height="100%"
                          width="100%"
                          :options="getChartOptions(element.data.categories)"
                          :series="element.data.series"
                        ></apexchart>
                     </div>
                  </div>
              </v-card>

            </v-col>
          </template>
        </draggable>

      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, computed, onUnmounted, watch } from 'vue';
import { useUserStore } from '@/stores/user';
import { useTheme } from 'vuetify';
import { supabase } from '@/api/supabase';
import draggable from 'vuedraggable';
import { format, startOfDay, endOfDay, startOfWeek, endOfWeek, startOfMonth, endOfMonth, startOfYear, endOfYear, subDays } from 'date-fns';

const userStore = useUserStore();
const theme = useTheme();

// --- ESTADO & THEME ---
const isDark = computed(() => theme.global.current.value.dark);
const zebraClass = (index: number) => isDark.value ? (index % 2 === 0 ? 'zebra-dark-a' : 'zebra-dark-b') : (index % 2 === 0 ? 'zebra-light-a' : 'zebra-light-b');

const loading = ref(true);
const isEditing = ref(false);
const savingLayout = ref(false);
const myWidgets = ref<any[]>([]);
const currentTime = ref('');
const lastSyncTime = ref(format(new Date(), 'HH:mm'));
let clockInterval: NodeJS.Timeout;
let subscription: any = null;

// --- FILTRO DE PERÍODO ---
const selectedPeriod = ref('month');
const periodOptions = [
    { label: 'Hoje', value: 'today' },
    { label: 'Últimos 7 Dias', value: 'last7' },
    { label: 'Esta Semana', value: 'week' },
    { label: 'Este Mês', value: 'month' },
    { label: 'Este Ano', value: 'year' },
];

const toggleEditMode = () => {
    if (isEditing.value) saveLayoutOrder();
    isEditing.value = !isEditing.value;
};

// --- DADOS COMPUTADOS ---
const userFirstName = computed(() => userStore.profile?.full_name?.split(' ')[0] || 'Vendedor');
const userInitials = computed(() => userStore.profile?.full_name?.substring(0, 2).toUpperCase() || 'VD');

// --- WIDGETS PADRÃO (ATUALIZADOS COM CHARTS E NOVOS RANKINGS) ---
const defaultWidgets = [
  {
    id: 'w1', title: 'Faturamento Bruto', type: 'kpi', cols: 3, icon: 'mdi-cash-register', gradient: 'bg-gradient-success',
    format: 'currency', value: 0, query: 'sales_sum'
  },
  {
    id: 'w2', title: 'Qtd. de Vendas', type: 'kpi', cols: 3, icon: 'mdi-receipt-text-check', gradient: 'bg-gradient-info',
    format: 'number', value: 0, query: 'orders_count'
  },
  {
    id: 'w3', title: 'Ticket Médio', type: 'kpi', cols: 3, icon: 'mdi-chart-areaspline', gradient: 'bg-gradient-purple',
    format: 'currency', value: 0, query: 'avg_ticket'
  },
  {
    id: 'w4', title: 'Descontos Concedidos', type: 'kpi', cols: 3, icon: 'mdi-sale', gradient: 'bg-gradient-warning',
    format: 'currency', value: 0, query: 'discount_sum'
  },
  {
    id: 'w5', title: 'Top Produtos Mais Vendidos', type: 'list', cols: 6, icon: 'mdi-star-circle', gradient: 'bg-gradient-orange',
    data: [], query: 'top_products'
  },
  {
    id: 'w6', title: 'Top Melhores Compradores', type: 'list', cols: 6, icon: 'mdi-crown', gradient: 'bg-gradient-gold',
    data: [], query: 'top_buyers'
  },
  {
    id: 'w8', title: 'Curva de Evolução Financeira', type: 'chart', cols: 12, icon: 'mdi-chart-bell-curve-cumulative', gradient: 'bg-gradient-teal',
    data: { series: [], categories: [] }, query: 'sales_evolution'
  },
  {
    id: 'w7', title: 'Últimas Vendas Passadas no Caixa', type: 'list', cols: 12, icon: 'mdi-history', gradient: 'bg-gradient-primary',
    data: [], query: 'last_orders'
  }
];

// --- HELPERS ---
const updateClock = () => {
  currentTime.value = new Date().toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit', second: '2-digit' });
};

const formatValue = (val: number, type: string) => {
  if (type === 'currency') return new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(val);
  return new Intl.NumberFormat('pt-BR').format(val);
};

const getChartOptions = (categories: string[]) => ({
    chart: { type: 'area', fontFamily: 'Roboto, sans-serif', toolbar: { show: false }, background: 'transparent' },
    colors: ['#1976D2'],
    fill: { type: 'gradient', gradient: { shadeIntensity: 1, opacityFrom: 0.4, opacityTo: 0.05, stops: [0, 90, 100] } },
    dataLabels: { enabled: false },
    stroke: { curve: 'smooth', width: 3 },
    xaxis: {
        categories: categories,
        labels: { style: { colors: isDark.value ? '#8c8c8c' : '#757575', fontWeight: 600 } },
        axisBorder: { show: false }, axisTicks: { show: false }
    },
    yaxis: {
        labels: {
            formatter: (val: number) => `R$ ${val.toLocaleString('pt-BR')}`,
            style: { colors: isDark.value ? '#8c8c8c' : '#757575', fontWeight: 600 }
        }
    },
    grid: { borderColor: isDark.value ? 'rgba(255,255,255,0.05)' : 'rgba(0,0,0,0.05)', strokeDashArray: 4 },
    theme: { mode: isDark.value ? 'dark' : 'light' },
    tooltip: { y: { formatter: (val: number) => `R$ ${val.toLocaleString('pt-BR', {minimumFractionDigits: 2})}` } }
});

const getPeriodDates = () => {
    const now = new Date();
    switch (selectedPeriod.value) {
        case 'today': return { start: startOfDay(now), end: endOfDay(now) };
        case 'last7': return { start: startOfDay(subDays(now, 7)), end: endOfDay(now) };
        case 'week': return { start: startOfWeek(now, { weekStartsOn: 1 }), end: endOfWeek(now, { weekStartsOn: 1 }) };
        case 'year': return { start: startOfYear(now), end: endOfYear(now) };
        case 'month': default: return { start: startOfMonth(now), end: endOfMonth(now) };
    }
};

// --- FETCH DATA MESTRA ---
const fetchData = async () => {
  if (!userStore.user?.id) return;
  if (myWidgets.value.length === 0) loading.value = true;

  const { start, end } = getPeriodDates();
  const userId = userStore.user.id;

  try {
      // Puxa vendas do PDV (store_sales) com order_number adicionado!
      const { data: orders, error } = await supabase
      .from('store_sales')
      .select('id, order_number, total_value, created_at, customer_name, items')
      .eq('seller_id', userId)
      .gte('created_at', start.toISOString())
      .lte('created_at', end.toISOString())
      .neq('status', 'cancelled')
      .order('created_at', { ascending: false });

    if (error) throw error;

    const validOrders = orders || [];

    // 1. KPIs Simples
    const totalSales = validOrders.reduce((acc, o) => acc + (Number(o.total_value) || 0), 0);
    const totalOrders = validOrders.length;
    const avgTicket = totalOrders > 0 ? totalSales / totalOrders : 0;

    const totalDiscounts = 0; // Se tiver no json, puxe aqui.

    // Atualiza KPIs
    const wSales = myWidgets.value.find(w => w.query === 'sales_sum');
    if (wSales) wSales.value = totalSales;

    const wOrders = myWidgets.value.find(w => w.query === 'orders_count');
    if (wOrders) wOrders.value = totalOrders;

    const wTicket = myWidgets.value.find(w => w.query === 'avg_ticket');
    if (wTicket) wTicket.value = avgTicket;

    const wDisc = myWidgets.value.find(w => w.query === 'discount_sum');
    if (wDisc) wDisc.value = totalDiscounts;

    // 2. Últimas Vendas (Widget) - FORMATADO COM NUMERO DO PEDIDO E DATA
    const wLastOrders = myWidgets.value.find(w => w.query === 'last_orders');
    if (wLastOrders) {
      wLastOrders.data = validOrders.slice(0, 10).map(o => ({
        label: `Pedido #${String(o.order_number || o.id.toString().substring(0,4)).padStart(4, '0')} - ${o.customer_name || 'Consumidor Final'}`,
        sublabel: format(new Date(o.created_at), 'dd/MM/yyyy HH:mm'),
        value: formatValue(Number(o.total_value), 'currency')
      }));
    }

    // 3. Top Produtos
    const wTopProd = myWidgets.value.find(w => w.query === 'top_products');
    if (wTopProd) {
       const productCounts: Record<string, number> = {};
       validOrders.forEach(o => {
           if (o.items && Array.isArray(o.items)) {
               o.items.forEach((item: any) => {
                   const pName = item.produto?.nome_produto || item.name || 'Produto Diverso';
                   const pQty = Number(item.produto?.quantidade || item.quantity || 1);
                   productCounts[pName] = (productCounts[pName] || 0) + pQty;
               });
           }
       });
       wTopProd.data = Object.entries(productCounts)
           .sort((a, b) => b[1] - a[1]).slice(0, 10)
           .map(e => ({ label: e[0], value: `${e[1]} un` }));
    }

    // 4. Top Compradores
    const wTopBuyers = myWidgets.value.find(w => w.query === 'top_buyers');
    if (wTopBuyers) {
       const buyerTotals: Record<string, number> = {};
       validOrders.forEach(o => {
           const cName = o.customer_name || 'Consumidor Final';
           buyerTotals[cName] = (buyerTotals[cName] || 0) + Number(o.total_value || 0);
       });
       wTopBuyers.data = Object.entries(buyerTotals)
           .sort((a, b) => b[1] - a[1]).slice(0, 10)
           .map(e => ({ label: e[0], value: formatValue(e[1], 'currency') }));
    }

    // 5. Gráfico de Evolução (Area Chart)
    const wChart = myWidgets.value.find(w => w.query === 'sales_evolution');
    if (wChart) {
       const salesByDay: Record<string, number> = {};
       const ascOrders = [...validOrders].reverse();

       ascOrders.forEach(o => {
           const dayKey = format(new Date(o.created_at), 'dd/MM');
           salesByDay[dayKey] = (salesByDay[dayKey] || 0) + Number(o.total_value || 0);
       });

       const categories = Object.keys(salesByDay);
       const seriesData = Object.values(salesByDay).map(v => Number(v.toFixed(2)));

       wChart.data = {
           categories: categories,
           series: [{ name: 'Faturamento R$', data: seriesData }]
       };
    }

    lastSyncTime.value = format(new Date(), 'HH:mm:ss');

  } catch (e) {
    console.error("Erro Dashboard Vendedor:", e);
  } finally {
    loading.value = false;
  }
};

watch(selectedPeriod, () => {
    loading.value = true;
    fetchData();
});

// --- LAYOUT MANAGEMENT ---
const loadLayout = async () => {
  if (!userStore.user?.id) return;

  const { data } = await supabase
    .from('user_preferences')
    .select('settings')
    .eq('user_id', userStore.user.id)
    .maybeSingle();

  if (data?.settings?.seller_dashboard) {
      const savedLayout = data.settings.seller_dashboard;
      const merged = defaultWidgets.map(dw => {
          const found = savedLayout.find((sl:any) => sl.id === dw.id);
          // FORÇA OS COLS e ORDEM ORIGINAIS pra resolver o bug do layout anterior salvo errado
          return found ? { ...dw, ...found, cols: dw.cols, data: dw.data } : dw;
      });
      merged.sort((a, b) => defaultWidgets.findIndex(d => d.id === a.id) - defaultWidgets.findIndex(d => d.id === b.id));
      myWidgets.value = merged;
  } else {
      const saved = localStorage.getItem('cajuia_seller_layout');
      myWidgets.value = saved ? JSON.parse(saved) : JSON.parse(JSON.stringify(defaultWidgets));
  }
};

const saveLayoutOrder = async () => {
  if (!userStore.user?.id) return;
  savingLayout.value = true;

  try {
      const { data: currentPrefs } = await supabase.from('user_preferences').select('settings').eq('user_id', userStore.user.id).maybeSingle();
      const newSettings = currentPrefs?.settings || {};

      const layoutToSave = myWidgets.value.map(w => ({ ...w, data: Array.isArray(w.data) ? [] : {} }));
      newSettings.seller_dashboard = layoutToSave;

      await supabase.from('user_preferences').upsert({
          user_id: userStore.user.id,
          settings: newSettings
      }, { onConflict: 'user_id' });

      localStorage.setItem('cajuia_seller_layout', JSON.stringify(layoutToSave));
  } catch (e) {
      console.error('Erro ao salvar layout:', e);
  } finally {
      savingLayout.value = false;
      isEditing.value = false;
  }
};

// --- REALTIME ---
const subscribeToSales = () => {
    if (subscription) return;
    subscription = supabase
        .channel('store-sales-seller-channel')
        .on(
            'postgres_changes',
            { event: '*', schema: 'public', table: 'store_sales', filter: `seller_id=eq.${userStore.user?.id}` },
            () => fetchData()
        )
        .subscribe();
};

// --- LIFECYCLE ---
onMounted(async () => {
  updateClock();
  clockInterval = setInterval(updateClock, 1000);
  await loadLayout();
  await fetchData();
  subscribeToSales();
});

onUnmounted(() => {
  clearInterval(clockInterval);
  if (subscription) supabase.removeChannel(subscription);
});
</script>

<style scoped lang="scss">
/* Base Layout */
.seller-dashboard-layout { position: relative; font-family: 'Roboto', sans-serif; }
.background-carousel-wrapper { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 0; opacity: 0.6; pointer-events: none; }
.background-overlay { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 1; background: radial-gradient(circle at center, rgba(15, 15, 19, 0.4), rgba(15, 15, 19, 0.98)); backdrop-filter: blur(8px); }
.z-10 { position: relative; z-index: 10; }
.z-20 { position: relative; z-index: 20; }

/* Theme Colors */
.bg-glass-dark { background-color: #1a1a1f; }
.bg-glass-header { background-color: rgba(26, 26, 31, 0.65); backdrop-filter: blur(12px); }
.border-bottom-white-05 { border-bottom: 1px solid rgba(255, 255, 255, 0.05); }
.border-white-10 { border-color: rgba(255, 255, 255, 0.1) !important; }
.border-white-20 { border-color: rgba(255, 255, 255, 0.2) !important; }
.glass-card { background: rgba(30, 30, 35, 0.45); backdrop-filter: blur(25px); border: 1px solid rgba(255,255,255,0.08) !important; }
.bg-white-05 { background-color: rgba(255, 255, 255, 0.05); }
.bg-black-20 { background-color: rgba(0, 0, 0, 0.2); }

/* Utils */
.font-mono { font-family: monospace; }
.tracking-wide { letter-spacing: 1px; }
.tracking-widest { letter-spacing: 1.5px; }
.ls-1 { letter-spacing: 0.5px; }
.lh-1 { line-height: 1.1; }
.text-shadow { text-shadow: 0 2px 4px rgba(0,0,0,0.3); }

/* Components */
.btn-3d {
    border-radius: 8px !important;
    box-shadow: 0 3px 5px rgba(0,0,0,0.15), inset 0 2px 0 rgba(255,255,255,0.25) !important;
    transition: transform 0.1s ease, box-shadow 0.1s ease;
    text-transform: none !important;
}
.btn-3d:active {
    transform: translateY(2px);
    box-shadow: 0 1px 2px rgba(0,0,0,0.15), inset 0 1px 0 rgba(255,255,255,0.2) !important;
}

.chip-3d {
    box-shadow: 0 3px 5px rgba(0,0,0,0.12), inset 0 1px 0 rgba(255,255,255,0.25) !important;
    text-shadow: 0 1px 2px rgba(0,0,0,0.25);
}

.shadow-sm { box-shadow: 0 4px 12px rgba(0,0,0,0.05) !important; }
.shadow-md { box-shadow: 0 6px 14px rgba(0,0,0,0.1) !important; }
.shadow-lg { box-shadow: 0 8px 24px rgba(0,0,0,0.15) !important; }
.border-thin { border: 1px solid rgba(0,0,0,0.08) !important; }

/* Custom Scrollbar */
.custom-scroll { scrollbar-gutter: stable; }
.custom-scroll::-webkit-scrollbar { width: 6px; height: 6px; }
.custom-scroll::-webkit-scrollbar-track { background: transparent; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128, 0.25); border-radius: 4px; }

/* Gradients */
.bg-gradient-primary { background: linear-gradient(135deg, #1976D2, #1565C0) !important; color: white !important; }
.bg-gradient-success { background: linear-gradient(135deg, #2E7D32, #1B5E20) !important; color: white !important; }
.bg-gradient-info { background: linear-gradient(135deg, #0288D1, #01579B) !important; color: white !important; }
.bg-gradient-warning { background: linear-gradient(135deg, #F57F17, #E65100) !important; color: white !important; }
.bg-gradient-error { background: linear-gradient(135deg, #C62828, #B71C1C) !important; color: white !important; }
.bg-gradient-purple { background: linear-gradient(135deg, #7B1FA2, #4A148C) !important; color: white !important; }
.bg-gradient-orange { background: linear-gradient(135deg, #F57C00, #E65100) !important; color: white !important; }
.bg-gradient-teal { background: linear-gradient(135deg, #00897B, #00695C) !important; color: white !important; }
.bg-gradient-gold { background: linear-gradient(135deg, #FFD54F, #FF8F00) !important; color: white !important; }

/* KPI Cards */
.kpi-card { position: relative; overflow: hidden; color: white; }
.kpi-bg-icon { position: absolute; right: -15px; bottom: -20px; opacity: 0.15; transform: rotate(-15deg); pointer-events: none; }
.kpi-bg-icon .v-icon { font-size: 110px; color: white; }
.kpi-label { font-size: 13px; font-weight: 900; letter-spacing: 1px; text-transform: uppercase; }
.kpi-value { letter-spacing: -0.5px; }

/* Medalhas 3D / Rankings */
.medal-badge {
    width: 32px; height: 32px; border-radius: 8px;
    display: flex; align-items: center; justify-content: center;
    flex-shrink: 0; font-family: monospace; font-size: 14px;
}
.medal-gold { background: linear-gradient(135deg, #FFD700, #F57F17); border: 1px solid #FFF59D; }
.medal-silver { background: linear-gradient(135deg, #E0E0E0, #9E9E9E); border: 1px solid #FAFAFA; }
.medal-bronze { background: linear-gradient(135deg, #FF8A65, #D84315); border: 1px solid #FFCCBC; }

/* Grid Layout (Listas) */
.grid-header, .grid-row {
    display: grid;
    align-items: stretch;
    width: 100%;
    border-bottom: 1px solid rgba(0,0,0,0.08);
}
.cell { padding: 10px 12px; display: flex; align-items: center; border-right: 1px solid rgba(0,0,0,0.05); font-size: 13px; }
.cell:last-child { border-right: none; }

.header-text { padding: 12px 10px; font-size: 10px; font-weight: 900; text-transform: uppercase; letter-spacing: 0.5px; display: flex; align-items: center; color: rgba(0,0,0,0.6); }
.cell.center, .header-text.center { justify-content: center; text-align: center; }
.cell.right, .header-text.right { justify-content: flex-end; text-align: right; }

.grid-surface-light .cell { background: #f5f7fa; border-color: rgba(0,0,0,0.10); }
.grid-surface-dark .cell { background: rgba(255,255,255,0.08); color: rgba(255,255,255,0.80); border-color: rgba(255,255,255,0.10); }

.grid-row-light .cell { border-color: rgba(0,0,0,0.08); transition: background-color 0.2s ease; }
.grid-row-dark .cell { border-color: rgba(255,255,255,0.08); }
.hover-bg-row:hover .cell { background: #F8FAFC !important; cursor: default; }
.grid-row-dark.hover-bg-row:hover .cell { background: rgba(255,255,255,0.07) !important; }

.zebra-light-a .cell { background: #ffffff; }
.zebra-light-b .cell { background: #fafafa; }
.zebra-dark-a .cell { background: rgba(255,255,255,0.02); }
.zebra-dark-b .cell { background: rgba(255,255,255,0.05); }

.sticky-head { position: sticky; top: 0; z-index: 10; box-shadow: 0 4px 6px -4px rgba(0,0,0,0.1); }

/* Animations */
.wave-emoji { animation: wave 2s infinite; transform-origin: 70% 70%; display: inline-block; }
@keyframes wave { 0% { transform: rotate(0deg); } 10% { transform: rotate(14deg); } 20% { transform: rotate(-8deg); } 30% { transform: rotate(14deg); } 40% { transform: rotate(-4deg); } 50% { transform: rotate(10deg); } 60% { transform: rotate(0deg); } 100% { transform: rotate(0deg); } }

.pulse-icon { animation: pulseAlpha 2s infinite; }
@keyframes pulseAlpha { 0% { opacity: 1; } 50% { opacity: 0.3; } 100% { opacity: 1; } }

.editing-pulse { animation: editPulse 2s infinite; border-radius: 24px; }
@keyframes editPulse { 0% { box-shadow: 0 0 0 0 rgba(25, 118, 210, 0.4); } 70% { box-shadow: 0 0 0 8px rgba(25, 118, 210, 0); } 100% { box-shadow: 0 0 0 0 rgba(25, 118, 210, 0); } }
</style>
