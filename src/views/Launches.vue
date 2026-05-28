<template>
  <div
    class="launches-layout font-sans fill-height d-flex flex-column relative overflow-hidden"
    :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 text-grey-darken-4' : 'bg-glass-dark text-white'"
  >
    <div v-if="themeStore.currentMode !== 'light'" class="background-carousel-wrapper">
      <v-carousel cycle height="100%" hide-delimiters :show-arrows="false" interval="15000" class="fill-height">
        <v-carousel-item src="@/assets/1.jpg" cover></v-carousel-item>
        <v-carousel-item src="@/assets/2.jpg" cover></v-carousel-item>
        <v-carousel-item src="@/assets/3.jpg" cover></v-carousel-item>
      </v-carousel>
      <div class="background-overlay"></div>
    </div>

    <div class="content-wrapper d-flex flex-column fill-height z-10 relative">

      <div
        class="header-bar px-6 py-4 d-flex align-center justify-space-between flex-shrink-0"
        :class="themeStore.currentMode === 'light' ? 'bg-white border-b border-grey-lighten-2 shadow-sm' : 'bg-glass-header border-bottom-white-05'"
      >
        <div class="d-flex flex-column">
          <div class="breadcrumb text-caption">
            <span class="opacity-70">MJ Process</span>
            <span class="mx-2 opacity-50">></span>
            <span class="font-weight-bold">Produção</span>
          </div>
          <div class="text-h6 font-weight-black tracking-tight leading-none mt-1" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">
            Painel de Lançamentos
          </div>
        </div>

        <div class="d-flex align-center" style="gap: 10px;">
          <v-btn
            variant="outlined"
            class="btn-rect"
            height="40"
            prepend-icon="mdi-refresh"
            :color="themeStore.currentMode === 'light' ? 'grey-darken-2' : 'white'"
            @click="fetchAllData"
            :loading="loading"
          >
            Atualizar
          </v-btn>
        </div>
      </div>

      <div class="px-6 pt-4 pb-2 flex-shrink-0">
        <div
          class="controls-bar d-flex align-center justify-space-between"
          :class="themeStore.currentMode === 'light' ? 'controls-light' : 'controls-dark'"
        >
          <div class="d-flex align-center flex-wrap w-100" style="gap: 10px;">

            <div class="period-nav d-flex align-center" :class="themeStore.currentMode === 'light' ? 'period-nav-light' : 'period-nav-dark'">
              <v-btn icon variant="text" class="icon-rect" height="40" width="40" @click="previousWeek" :title="'Semana Anterior'">
                <v-icon>mdi-chevron-left</v-icon>
              </v-btn>
              <div class="period-label text-caption font-weight-black text-center px-3">
                <v-icon size="small" class="mr-2" color="primary">mdi-calendar-range</v-icon>
                {{ weekRangeText }}
              </div>
              <v-btn icon variant="text" class="icon-rect" height="40" width="40" @click="nextWeek" :title="'Próxima Semana'">
                <v-icon>mdi-chevron-right</v-icon>
              </v-btn>
            </div>

            <div class="vertical-divider mx-2" style="height: 24px; border-left: 1px solid rgba(128,128,128,0.3);"></div>

            <div class="search-wrap d-flex align-center flex-grow-1" :class="themeStore.currentMode === 'light' ? 'search-light' : 'search-dark'">
              <v-icon :color="themeStore.currentMode === 'light' ? 'grey-darken-1' : 'white-70'">mdi-magnify</v-icon>
              <input
                v-model="searchQuery"
                type="text"
                placeholder="Buscar por OP, cliente ou ref estampa..."
                class="clean-input flex-grow-1 text-uppercase font-weight-bold"
              />
            </div>

            <div class="vertical-divider mx-2 d-none d-md-block" style="height: 24px; border-left: 1px solid rgba(128,128,128,0.3);"></div>

            <div class="d-none d-lg-flex align-center gap-4 text-caption font-weight-bold opacity-80">
                <div class="d-flex align-center gap-2">
                    <div class="status-box border-cyan"></div>
                    <span :class="themeStore.currentMode === 'light' ? 'text-grey-darken-2' : 'text-white'">Liberado (Mesa)</span>
                </div>
                <div class="d-flex align-center gap-2">
                    <div class="status-box border-amber"></div>
                    <span :class="themeStore.currentMode === 'light' ? 'text-grey-darken-2' : 'text-white'">Liberado (Corrida)</span>
                </div>
                <div class="d-flex align-center gap-2">
                     <div class="ghost-legend-box"></div>
                     <span :class="themeStore.currentMode === 'light' ? 'text-grey-darken-2' : 'text-white'">Em Design</span>
                </div>
                <div class="d-flex align-center gap-2">
                     <div class="ghost-legend-box delayed-legend"></div>
                     <span :class="themeStore.currentMode === 'light' ? 'text-grey-darken-2' : 'text-white'">Atrasado (+2d)</span>
                </div>
            </div>

          </div>
        </div>
      </div>

      <div class="px-6 py-3 flex-shrink-0">
        <v-row dense>
          <v-col cols="12" sm="4">
            <v-card class="kpi-card kpi-rect bg-gradient-blue hover-elevate py-3 px-4 cursor-pointer" v-ripple elevation="2" @click="openQueueModal('design')">
              <div class="kpi-bg-icon"><v-icon>mdi-palette-swatch</v-icon></div>
              <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                <div class="d-flex align-center" style="gap: 8px;">
                  <v-icon size="18" class="opacity-80">mdi-palette-swatch</v-icon>
                  <span class="kpi-label">Fila de Design</span>
                </div>
                <div class="kpi-number-group my-1">
                  <span class="kpi-value">{{ kpiDesignCount }}</span>
                  <span class="text-caption font-weight-medium ml-1 opacity-70">pedidos</span>
                </div>
                <div class="kpi-footer mt-1">{{ kpiDelayedCount }} com atraso (+2 dias)</div>
              </div>
            </v-card>
          </v-col>

          <v-col cols="12" sm="4">
            <v-card class="kpi-card kpi-rect bg-gradient-warning hover-elevate py-3 px-4 cursor-pointer" v-ripple elevation="2" @click="openQueueModal('stock')">
              <div class="kpi-bg-icon"><v-icon>mdi-alert-octagon</v-icon></div>
              <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                <div class="d-flex align-center" style="gap: 8px;">
                  <v-icon size="18" class="opacity-80">mdi-alert-octagon</v-icon>
                  <span class="kpi-label">Pendente Estoque</span>
                </div>
                <div class="kpi-number-group my-1">
                  <span class="kpi-value">{{ ordersPendingStock.length }}</span>
                  <span class="text-caption font-weight-medium ml-1 opacity-70">pedidos</span>
                </div>
                <div class="kpi-footer mt-1">Aguardando Matéria-Prima</div>
              </div>
            </v-card>
          </v-col>

          <v-col cols="12" sm="4">
            <v-card class="kpi-card kpi-rect bg-gradient-green hover-elevate py-3 px-4" v-ripple elevation="2">
              <div class="kpi-bg-icon"><v-icon>mdi-calendar-check</v-icon></div>
              <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                <div class="d-flex align-center" style="gap: 8px;">
                  <v-icon size="18" class="opacity-80">mdi-calendar-check</v-icon>
                  <span class="kpi-label">Entrada da Semana</span>
                </div>
                <div class="kpi-number-group my-1">
                  <span class="kpi-value">{{ totalMetersWeek.toLocaleString('pt-BR') }}</span>
                  <span class="text-caption font-weight-medium ml-1 opacity-70">metros</span>
                </div>
                <div class="kpi-footer mt-1">Total lançado nesta semana</div>
              </div>
            </v-card>
          </v-col>
        </v-row>
      </div>

      <div class="flex-grow-1 px-6 pb-2 overflow-hidden d-flex flex-column">
        <v-card
          class="flex-grow-1 d-flex flex-column rounded-0 border-thin overflow-hidden"
          :class="themeStore.currentMode === 'light' ? 'bg-white shadow-sm' : 'glass-card border-white-05'"
          :elevation="0"
        >
          <div v-if="loading" class="d-flex flex-column justify-center align-center h-100">
             <v-progress-circular indeterminate color="primary" size="64" width="6"></v-progress-circular>
             <div class="mt-4 font-weight-medium opacity-70">Carregando lançamentos...</div>
          </div>

          <div v-else class="kanban-container d-flex flex-grow-1 overflow-hidden h-100">
            <div
              v-for="(day, index) in weekDays"
              :key="day.date.toISOString()"
              class="kanban-column d-flex flex-column h-100 border-r"
              :class="[
                themeStore.currentMode === 'light' ? (index % 2 === 0 ? 'bg-white' : 'bg-grey-lighten-5') : (index % 2 === 0 ? 'bg-transparent' : 'bg-white-05'),
                themeStore.currentMode === 'light' ? 'border-grey-lighten-2' : 'border-white-05'
              ]"
            >
              <div class="column-header pa-3 flex-shrink-0 border-b" :class="themeStore.currentMode === 'light' ? 'border-grey-lighten-2' : 'border-white-05'">
                <div class="d-flex justify-space-between align-center mb-2">
                  <div>
                     <div class="text-subtitle-2 font-weight-black text-uppercase opacity-70 lh-1">{{ day.name }}</div>
                     <div class="text-h6 font-weight-black lh-1 mt-1">{{ getShortDate(day.date) }}</div>
                  </div>
                  <v-chip size="x-small" label class="font-weight-black px-2" :color="themeStore.currentMode === 'light' ? 'grey-darken-3' : 'white'" variant="tonal">
                     {{ getDayTotalMeters(day.date).toLocaleString('pt-BR') }}m
                  </v-chip>
                </div>

                <div class="d-flex gap-2 mt-2">
                    <div class="mini-stat flex-grow-1" :class="themeStore.currentMode === 'light' ? 'mini-stat-light' : 'mini-stat-dark'">
                       <v-icon size="12" class="mr-1 opacity-70">mdi-table-furniture</v-icon>
                       <span class="text-[10px] font-weight-bold">{{ getDayTotalMesa(day.date).toLocaleString('pt-BR') }}m</span>
                    </div>
                    <div class="mini-stat flex-grow-1" :class="themeStore.currentMode === 'light' ? 'mini-stat-light' : 'mini-stat-dark'">
                       <v-icon size="12" class="mr-1 opacity-70">mdi-run</v-icon>
                       <span class="text-[10px] font-weight-bold">{{ getDayTotalCorrida(day.date).toLocaleString('pt-BR') }}m</span>
                    </div>
                 </div>
              </div>

              <div class="kanban-content pa-2 custom-scroll flex-grow-1 overflow-y-auto">
                <template v-if="day.orders.length > 0">
                  <div v-for="order in day.orders" :key="order.id">

                      <v-card
                        v-if="order.isGhost"
                        class="production-card mb-2 rounded-0 border-s-4 ghost-style"
                        :class="[
                          themeStore.currentMode === 'light' ? 'ghost-light' : '',
                          order.isDelayed ? 'delayed-ghost' : ''
                        ]"
                        variant="flat"
                        @click="openDetailModal(order.id)"
                        v-ripple
                      >
                        <v-card-text class="pa-3 d-flex flex-column h-100 justify-space-between">
                           <div v-if="order.isDelayed" class="delayed-badge">
                              <v-icon size="12" color="white">mdi-clock-alert</v-icon>
                           </div>

                          <div>
                              <div class="d-flex align-center justify-space-between mb-1">
                                   <span class="pill-ref">#{{ String(order.order_number).padStart(4, '0') }}</span>
                                   <v-icon size="14" :color="order.isDelayed ? 'error' : 'purple'">mdi-palette-swatch</v-icon>
                              </div>

                              <div class="text-body-2 font-weight-black lh-1 text-truncate mb-2" :title="order.customer_name" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">
                                {{ order.customer_name }}
                              </div>
                          </div>

                          <div class="d-flex justify-space-between align-center mt-2 pt-2 border-t border-opacity-10" :class="themeStore.currentMode === 'light' ? 'border-grey' : 'border-white'">
                              <v-chip size="x-small" :color="order.isDelayed ? 'error' : 'purple'" variant="tonal" class="font-weight-bold px-2 rounded-0">
                                  {{ order.designCount }}/{{ order.totalItems }} Design
                              </v-chip>
                              <div class="d-flex align-center font-weight-black text-caption" :class="order.isDelayed ? 'text-error' : 'text-purple'">
                                  {{ order.quantity_meters?.toLocaleString('pt-BR') }}m
                              </div>
                          </div>
                        </v-card-text>
                      </v-card>

                      <v-card
                        v-else
                        class="production-card mb-2 rounded-0 border-s-4"
                        :class="[ themeStore.currentMode === 'light' ? 'bg-white border-thin' : 'bg-surface-card border-white-05' ]"
                        :style="`border-left-color: ${order.machine === 'MESA' ? 'var(--v-theme-cyan)' : 'var(--v-theme-amber)'} !important; border-left-width: 4px !important;`"
                        variant="flat"
                        @click="openDetailModal(order.id)"
                        v-ripple
                      >
                        <v-card-text class="pa-3 d-flex flex-column h-100 justify-space-between">
                          <div>
                              <div class="d-flex align-center justify-space-between mb-1">
                                   <span class="pill-ref">#{{ String(order.order_number).padStart(4, '0') }}</span>
                                   <span class="text-[9px] font-weight-black text-uppercase opacity-60">{{ getInitials(order.creator?.full_name) }}</span>
                              </div>

                              <div class="text-body-2 font-weight-black lh-1 text-truncate mb-1" :title="order.customer_name" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">
                                {{ order.customer_name }}
                              </div>

                              <div class="text-[10px] opacity-70 text-truncate d-flex align-center mb-1">
                                  <v-icon size="10" class="mr-1">mdi-texture-box</v-icon>
                                  {{ getOrderMainFabric(order) }}
                              </div>
                          </div>

                          <div class="d-flex justify-space-between align-center mt-2 pt-2 border-t border-opacity-10" :class="themeStore.currentMode === 'light' ? 'border-grey' : 'border-white'">
                              <v-icon size="14" color="success">mdi-check-circle</v-icon>
                              <div class="d-flex align-center font-weight-black text-caption">
                                  <v-icon start size="12" :color="order.machine === 'MESA' ? 'cyan' : 'amber'" class="mr-1">
                                    {{ order.machine === 'MESA' ? 'mdi-table-furniture' : 'mdi-run' }}
                                  </v-icon>
                                  {{ order.quantity_meters?.toLocaleString('pt-BR') }}m
                              </div>
                          </div>
                        </v-card-text>
                      </v-card>

                  </div>
                </template>

                <div v-else class="d-flex flex-column align-center justify-center mt-8 opacity-40">
                    <v-icon size="24" class="mb-2">mdi-calendar-blank</v-icon>
                    <span class="text-[10px] font-weight-bold text-uppercase">Sem Lançamentos</span>
                </div>
              </div>
            </div>
          </div>
        </v-card>
      </div>

      <OrderDetailModal :show="showDetailModal" :order-id="selectedOrderId" :item-id="selectedItemId" @close="showDetailModal = false"/>

      <v-dialog v-model="showQueueModal" max-width="900" scrollable>
        <v-card class="d-flex flex-column rounded-0" :class="isLightMode ? 'bg-white' : 'glassmorphism-card-dialog'">
            <v-toolbar color="transparent" class="border-b px-2" density="compact" :class="isLightMode ? 'border-grey-lighten-2' : 'border-white-05'">
                <v-toolbar-title class="font-weight-bold text-body-1 text-uppercase" :class="isLightMode ? 'text-grey-darken-4' : 'text-white'">{{ modalTitle }}</v-toolbar-title>
                <v-spacer></v-spacer>
                <v-btn icon density="compact" variant="text" @click="showQueueModal = false" :color="isLightMode ? 'grey-darken-2' : 'white'"><v-icon>mdi-close</v-icon></v-btn>
            </v-toolbar>
            <v-card-text class="pa-0">
                <v-data-table
                    :headers="modalHeaders"
                    :items="modalItems"
                    class="bg-transparent"
                    density="compact"
                    hover
                >
                    <template v-slot:item.customer_name="{ item }">
                        <div class="d-flex align-center gap-2 cursor-pointer font-weight-bold text-primary" @click="openDetailModal(item.order_id)">
                            {{ item.customer_name }}
                        </div>
                    </template>
                    <template v-slot:item.quantity_meters="{ item }">
                        <span class="font-weight-black">{{ item.quantity_meters.toLocaleString('pt-BR') }}m</span>
                    </template>
                    <template v-slot:item.created_at="{ item }">
                        {{ formatDate(item.created_at) }}
                    </template>
                </v-data-table>
            </v-card-text>
        </v-card>
      </v-dialog>

    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, computed, onActivated, watch } from 'vue';
import { supabase } from '@/api/supabase';
import { format, startOfWeek, addDays, subDays, isSameDay, parseISO, endOfWeek, differenceInCalendarDays } from 'date-fns';
import { ptBR } from 'date-fns/locale';
import OrderDetailModal from '@/components/OrderDetailModal.vue';
import { useThemeStore } from '@/stores/theme';
import { useCompanyStore } from '@/stores/company';

const themeStore = useThemeStore();
const isLightMode = computed(() => themeStore.currentMode === 'light');

const companyStore = useCompanyStore();

// --- Tipagens ---
type OrderItem = { id: string; fabric_type: string; stamp_ref: string; quantity_meters: number; stamp_image_url: string; status: string; };
type Order = {
  id: string; customer_name: string; status: string; created_at: string; quantity_meters: number;
  order_number: number; details: any; creator?: { full_name: string; };
  order_items: OrderItem[];
  // Campos computados
  isGhost?: boolean;
  isDelayed?: boolean;
  designCount?: number;
  totalItems?: number;
  machine?: 'MESA' | 'CORRIDA';
};

// --- Estado ---
const allOrders = ref<Order[]>([]);
const loading = ref(true);
const currentWeekStart = ref(startOfWeek(new Date(), { weekStartsOn: 1 }));
const showDetailModal = ref(false);
const selectedOrderId = ref<string | null>(null);
const selectedItemId = ref<string | null>(null);
const showQueueModal = ref(false);
const modalTitle = ref('');
const modalItems = ref<any[]>([]);
const searchQuery = ref('');

const modalHeaders = [
  { title: 'Pedido', key: 'order_number', align: 'start' },
  { title: 'Cliente', key: 'customer_name', align: 'start' },
  { title: 'Metragem', key: 'quantity_meters', align: 'end' },
  { title: 'Entrada', key: 'created_at', align: 'end' },
];

// --- Lógica Principal ---
const designStatuses = ['design_pending', 'customer_approval', 'changes_requested', 'approved_by_designer', 'approved_by_seller', 'finalizing'];

// KPI de Pendência em Design
const ordersStuckInDesign = computed(() => allOrders.value.filter(o => {
  if (o.order_items && o.order_items.length > 0) {
      return o.order_items.some(item => designStatuses.includes(item.status));
  }
  return designStatuses.includes(o.status);
}));

const ordersPendingStock = computed(() => allOrders.value.filter(o => o.status === 'pending_stock'));

// KPI Contadores
const kpiDesignCount = computed(() => ordersStuckInDesign.value.length);
const kpiDelayedCount = computed(() => {
  const today = new Date();
  return ordersStuckInDesign.value.filter(o => differenceInCalendarDays(today, parseISO(o.created_at)) > 2).length;
});

// --- Função Central de Processamento por Dia COM BUSCA MELHORADA ---
const getOrdersForDay = (date: Date) => {
  const dayOrders = allOrders.value.filter(o => isSameDay(parseISO(o.created_at), date));

  const filtered = searchQuery.value
      ? dayOrders.filter(o => {
          const s = searchQuery.value.toLowerCase();

          if (o.customer_name.toLowerCase().includes(s)) return true;
          if (String(o.order_number).includes(s)) return true;

          // PESQUISA POR REFERÊNCIA DA ESTAMPA
          if (o.order_items && o.order_items.length > 0) {
              const matchInItems = o.order_items.some(i => String(i.stamp_ref || '').toLowerCase().includes(s));
              if (matchInItems) return true;
          }

          return false;
        })
      : dayOrders;

  return filtered.map(o => {
      const items = o.order_items || [];
      const totalItems = items.length > 0 ? items.length : 1;
      const itemsInDesign = items.filter(i => designStatuses.includes(i.status)).length;

      let isGhost = false;
      let designCount = 0;

      if (items.length > 0) {
          isGhost = itemsInDesign > 0;
          designCount = itemsInDesign;
      } else {
          isGhost = designStatuses.includes(o.status);
          designCount = isGhost ? 1 : 0;
      }

      const daysSinceCreation = differenceInCalendarDays(new Date(), parseISO(o.created_at));
      const isDelayed = isGhost && daysSinceCreation >= 2;

      return { ...o, isGhost, isDelayed, designCount, totalItems, machine: getMachineTypeForOrder(o) };
  });
};

// Contadores do Dia
const getDayTotalMeters = (date: Date) => getOrdersForDay(date).reduce((sum, o) => sum + (o.quantity_meters || 0), 0);
const getDayTotalMesa = (date: Date) => getOrdersForDay(date).filter(o => o.machine === 'MESA').reduce((sum, o) => sum + (o.quantity_meters || 0), 0);
const getDayTotalCorrida = (date: Date) => getOrdersForDay(date).filter(o => o.machine === 'CORRIDA').reduce((sum, o) => sum + (o.quantity_meters || 0), 0);

const totalMetersWeek = computed(() => {
  let sum = 0;
  weekDays.value.forEach(d => sum += getDayTotalMeters(d.date));
  return sum;
});

// --- Calendário e Navegação ---
const weekDays = computed(() => Array.from({ length: 6 }, (_, i) => ({
  date: addDays(currentWeekStart.value, i),
  name: format(addDays(currentWeekStart.value, i), 'EEEE', { locale: ptBR }).split('-')[0],
  orders: getOrdersForDay(addDays(currentWeekStart.value, i))
})));

const weekRangeText = computed(() => `${format(currentWeekStart.value, 'dd MMM', { locale: ptBR })} - ${format(endOfWeek(currentWeekStart.value, { weekStartsOn: 1 }), 'dd MMM', { locale: ptBR })}`);
const nextWeek = () => { currentWeekStart.value = addDays(currentWeekStart.value, 7); };
const previousWeek = () => { currentWeekStart.value = subDays(currentWeekStart.value, 7); };
const getShortDate = (date: Date) => format(date, 'dd/MM');

// --- Helpers ---
const fabricMachineMap: Record<string, 'MESA' | 'CORRIDA'> = {
  'creponado': 'MESA', 'tule': 'MESA', 'fluity': 'MESA', 'canelado': 'MESA',
  'suplex': 'MESA', 'chiffon': 'MESA', 'liganet': 'MESA',
  'crepinho': 'CORRIDA', 'twill': 'CORRIDA', 'seda': 'CORRIDA',
  'corta-vento': 'CORRIDA', 'tactel': 'CORRIDA', 'alfaiataria': 'CORRIDA'
};

const getMachineTypeForOrder = (order: Order): 'MESA' | 'CORRIDA' => {
  let fabric = '';
  if (order.order_items && order.order_items.length > 0) fabric = order.order_items[0].fabric_type;
  else if (order.details && order.details.fabric_type) fabric = order.details.fabric_type;

  if (!fabric) return 'CORRIDA';
  const lowerFabric = fabric.toLowerCase();
  const match = Object.keys(fabricMachineMap).find(k => lowerFabric.includes(k));
  return match ? fabricMachineMap[match] : 'CORRIDA';
};

const getOrderMainFabric = (order: Order) => {
  if (order.order_items && order.order_items.length > 0) return order.order_items[0].fabric_type;
  return order.details?.fabric_type || 'Tecido Diverso';
}

const getInitials = (name?: string) => name ? name.split(' ').map(n => n[0]).join('').slice(0, 2).toUpperCase() : 'NA';
const formatDate = (dateString: string) => format(new Date(dateString), "dd/MM/yy HH:mm", { locale: ptBR });

// --- Actions ---
const openDetailModal = (orderId: string, itemId: string | null = null) => {
  selectedOrderId.value = orderId;
  selectedItemId.value = itemId;
  showDetailModal.value = true;
};

const openQueueModal = (queueType: 'stock' | 'design') => {
  if (queueType === 'stock') {
      modalTitle.value = 'Pedidos Aguardando Matéria-Prima';
      modalItems.value = ordersPendingStock.value.map(o => ({
          id: o.id, order_id: o.id, customer_name: o.customer_name, order_number: o.order_number,
          quantity_meters: o.quantity_meters, created_at: o.created_at
      }));
  } else {
      modalTitle.value = 'Fila de Design (Pendentes)';
      modalItems.value = ordersStuckInDesign.value.map(o => ({
          id: o.id, order_id: o.id, customer_name: o.customer_name, order_number: o.order_number,
          quantity_meters: o.quantity_meters, created_at: o.created_at,
      }));
  }
  showQueueModal.value = true;
};

// --- API ---
const fetchAllData = async () => {
  loading.value = true;
  try {
    if (companyStore.isDemoMode) {
      // DADOS MOCKADOS PARA O MODO DEMO
      const baseDate = currentWeekStart.value;
      const now = new Date();

      allOrders.value = [
        {
          id: 'demo-1', customer_name: 'Boutique Elegance (Demo)', status: 'approved',
          created_at: addDays(baseDate, 0).toISOString(), quantity_meters: 150, order_number: 9001,
          details: { fabric_type: 'tule' }, creator: { full_name: 'João Vendedor' },
          order_items: [{ id: 'i1', fabric_type: 'tule', stamp_ref: 'FLORAL-01', quantity_meters: 150, stamp_image_url: '', status: 'released' }]
        },
        {
          id: 'demo-2', customer_name: 'Moda Praia Sol (Demo)', status: 'approved',
          created_at: addDays(baseDate, 1).toISOString(), quantity_meters: 350, order_number: 9002,
          details: { fabric_type: 'tactel' }, creator: { full_name: 'Maria Vendedora' },
          order_items: [{ id: 'i2', fabric_type: 'tactel', stamp_ref: 'GEOM-02', quantity_meters: 350, stamp_image_url: '', status: 'released' }]
        },
        {
          id: 'demo-3', customer_name: 'Ateliê Costura (Demo)', status: 'pending_stock',
          created_at: addDays(baseDate, 2).toISOString(), quantity_meters: 50, order_number: 9003,
          details: { fabric_type: 'suplex' }, creator: { full_name: 'Pedro Vendas' },
          order_items: [] // Cai no Pendente de Estoque
        },
        {
          id: 'demo-4', customer_name: 'Confecções XYZ (Demo)', status: 'approved',
          created_at: addDays(baseDate, 2).toISOString(), quantity_meters: 80, order_number: 9004,
          details: { fabric_type: 'creponado' }, creator: { full_name: 'Ana Vendas' },
          order_items: [{ id: 'i4', fabric_type: 'creponado', stamp_ref: 'ANIMAL-01', quantity_meters: 80, stamp_image_url: '', status: 'design_pending' }]
        },
        {
          id: 'demo-5', customer_name: 'Studio Design (Demo) - ATRASADO', status: 'approved',
          created_at: subDays(now, 3).toISOString(), quantity_meters: 200, order_number: 9005,
          details: { fabric_type: 'seda' }, creator: { full_name: 'Lucas Vendas' },
          order_items: [{ id: 'i5', fabric_type: 'seda', stamp_ref: 'ABSTRATO-99', quantity_meters: 200, stamp_image_url: '', status: 'design_pending' }]
        },
        {
          id: 'demo-6', customer_name: 'Malharia Sul (Demo)', status: 'approved',
          created_at: addDays(baseDate, 3).toISOString(), quantity_meters: 100, order_number: 9006,
          details: { fabric_type: 'fluity' }, creator: { full_name: 'João Vendedor' },
          order_items: [{ id: 'i6', fabric_type: 'fluity', stamp_ref: 'LISTRAS-05', quantity_meters: 100, stamp_image_url: '', status: 'released' }]
        }
      ] as Order[];

      // Delay suave para simular requisição
      await new Promise(resolve => setTimeout(resolve, 600));

    } else {
      // FLUXO NORMAL DE PRODUÇÃO
      const { data: ordersData, error: ordersError } = await supabase
          .from('orders')
          .select(`*, creator:profiles!created_by(full_name), order_items(*)`)
          .order('created_at', { ascending: false })
          .limit(5000);

      if (ordersError) throw ordersError;
      allOrders.value = ordersData || [];
    }

  } catch (err: any) {
    console.error('Erro ao buscar dados:', err);
  } finally {
    loading.value = false;
  }
};

// Recarrega os dados imediatamente se o usuário ligar/desligar o modo demo
watch(() => companyStore.isDemoMode, () => {
    fetchAllData();
});

onActivated(fetchAllData);
onMounted(fetchAllData);
</script>

<style scoped lang="scss">
/* --- IDENTIDADE VISUAL EXATA DO LIBERACAO.VUE --- */
.launches-layout { position: relative; }
.background-carousel-wrapper { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 0; opacity: 0.6; pointer-events: none; }
.background-overlay { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 1; background: radial-gradient(circle at center, rgba(15, 15, 19, 0.4), rgba(15, 15, 19, 0.98)); backdrop-filter: blur(8px); }
.z-10 { position: relative; z-index: 10; }

.bg-glass-dark { background: rgba(10,10,12,0.85); }
.bg-glass-header { background: rgba(20,20,24,0.55); backdrop-filter: blur(14px); }
.border-bottom-white-05 { border-bottom: 1px solid rgba(255,255,255,0.08); }
.border-thin { border: 1px solid rgba(0,0,0,0.08); }

.btn-rect { border-radius: 0 !important; text-transform: none !important; font-weight: 800; }
.icon-rect { border-radius: 0 !important; }
.kpi-rect { border-radius: 0 !important; }

/* Controles Base */
.controls-bar { border: 1px solid rgba(0,0,0,0.08); border-radius: 0; padding: 10px; }
.controls-light { background: #ffffff; }
.controls-dark { background: rgba(30,30,35,0.55); backdrop-filter: blur(16px); border: 1px solid rgba(255,255,255,0.08); }

.period-nav { border-radius: 0; height: 40px; overflow: hidden; }
.period-nav-light { border: 1px solid rgba(0,0,0,0.12); background: #fafafa; }
.period-nav-dark { border: 1px solid rgba(255,255,255,0.10); background: rgba(255,255,255,0.06); }
.period-label { min-width: 190px; display: flex; align-items: center; justify-content: center; height: 40px; }

.search-wrap { height: 40px; border-radius: 0; padding: 0 12px; min-width: 250px; flex: 1 1 300px; }
.search-light { background: #f4f6f8; border: 1px solid rgba(0,0,0,0.08); }
.search-dark { background: rgba(255,255,255,0.08); border: 1px solid rgba(255,255,255,0.10); }
.clean-input { border: none; outline: none; background: transparent; font-size: 12px; color: inherit; width: 100%; margin-left: 8px; }

/* KPIs Estilo Liberacao */
.kpi-card { border: 1px solid rgba(255,255,255,0.15); color: white; min-height: 110px; position: relative; overflow: hidden; }
.kpi-bg-icon { position: absolute; right: -20px; bottom: -20px; opacity: 0.15; transform: rotate(-15deg); pointer-events: none; z-index: 0; }
.kpi-bg-icon .v-icon { font-size: 100px; color: white; }
.bg-gradient-blue { background: linear-gradient(135deg, #1E88E5, #1565C0); }
.bg-gradient-warning { background: linear-gradient(135deg, #FFB300, #F57F17); }
.bg-gradient-green { background: linear-gradient(135deg, #43A047, #2E7D32); }

.kpi-label { font-size: 12px; font-weight: 900; letter-spacing: .2px; text-transform: uppercase; }
.kpi-value { font-size: 22px; font-weight: 900; letter-spacing: .2px; }
.kpi-footer { font-size: 11px; opacity: .9; font-weight: 700; }

/* Kanban Board Container */
.kanban-container { gap: 0; }
.kanban-column { flex: 1; min-width: 240px; }

.glass-card { background: rgba(30, 30, 35, 0.45); backdrop-filter: blur(25px); border: 1px solid rgba(255,255,255,0.08); }
.bg-white-05 { background: rgba(255,255,255,0.05); }
.border-white-05 { border-color: rgba(255,255,255,0.05) !important; }
.bg-surface-card { background-color: rgba(255, 255, 255, 0.05); }

.custom-scroll::-webkit-scrollbar { width: 6px; height: 6px; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.35); border-radius: 6px; }
.custom-scroll::-webkit-scrollbar-track { background: transparent; }

/* Cards Específicos */
.production-card { transition: transform 0.2s, box-shadow 0.2s; position: relative; }
.production-card:hover { transform: translateY(-2px); box-shadow: 0 4px 8px rgba(0,0,0,0.15) !important; z-index: 2; }

.mini-stat { background: rgba(0,0,0,0.04); border-radius: 4px; padding: 4px; display: flex; align-items: center; justify-content: center; color: inherit; }
.mini-stat-light { background: #f5f5f5; border: 1px solid #e0e0e0; }
.mini-stat-dark { background: rgba(255,255,255,0.05); border: 1px solid rgba(255,255,255,0.08); }

.pill-ref { font-size: 9px; font-weight: 900; font-family: monospace; background: rgba(0,0,0,0.08); padding: 2px 6px; border-radius: 4px; }

/* Legendas & Status (Baseadas no Launches antigo) */
.status-box { width: 12px; height: 12px; border-radius: 2px; border: 2px solid; }
.border-cyan { border-color: #00BCD4; background-color: rgba(0, 188, 212, 0.2); }
.border-amber { border-color: #FFC107; background-color: rgba(255, 193, 7, 0.2); }
.ghost-legend-box { width: 12px; height: 12px; border: 1px dashed #BA68C8; background-color: rgba(156, 39, 176, 0.2); border-radius: 2px; }
.delayed-legend { border-color: #ef5350; background-color: rgba(244, 67, 54, 0.2); animation: pulse-red 2s infinite; }

/* GHOST & DELAYED STYLES (Adaptado pro modelo card-border-s-4) */
.ghost-style {
    background: rgba(156, 39, 176, 0.08) !important;
    border: 1px dashed rgba(156, 39, 176, 0.3) !important;
    border-left: 4px dashed #9c27b0 !important;
}
.ghost-light {
    background: #fdf5ff !important;
    border-color: #d1c4e9 !important;
}

.delayed-ghost {
    background: rgba(244, 67, 54, 0.08) !important;
    border-color: #ef5350 !important;
    border-left: 4px dashed #ef5350 !important;
    animation: pulse-red 2s infinite;
}
.delayed-badge { position: absolute; top: 8px; right: 8px; background: #ff5252; border-radius: 50%; width: 20px; height: 20px; display: flex; align-items: center; justify-content: center; animation: pulse 1s infinite; }

@keyframes pulse { 0% { opacity: 1; transform: scale(1); } 50% { opacity: 0.8; transform: scale(1.05); } 100% { opacity: 1; transform: scale(1); } }
@keyframes pulse-red { 0% { box-shadow: 0 0 0 0 rgba(255, 82, 82, 0.7); } 70% { box-shadow: 0 0 0 6px rgba(255, 82, 82, 0); } 100% { box-shadow: 0 0 0 0 rgba(255, 82, 82, 0); } }

/* Modals */
.glassmorphism-card-dialog { background: #1e1e24 !important; color: #fff; border: 1px solid rgba(255,255,255,0.1); }
.lh-1 { line-height: 1 !important; }
</style>
