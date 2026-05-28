<template>
  <div
    class="liberacao-layout font-sans fill-height d-flex flex-column relative overflow-hidden"
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
            Kanban de Liberação
          </div>
        </div>

        <div class="d-flex align-center" style="gap: 10px;">
          <v-btn
            variant="outlined"
            class="btn-rect"
            height="40"
            prepend-icon="mdi-refresh"
            :color="themeStore.currentMode === 'light' ? 'grey-darken-2' : 'white'"
            @click="fetchReleasedItems"
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

            <div style="width: 180px;">
               <v-autocomplete
                  v-model="selectedCreator"
                  :items="availableCreators"
                  label="Vendedor"
                  variant="outlined"
                  density="compact"
                  hide-details
                  class="filter-select rounded-0"
                  :bg-color="themeStore.currentMode === 'light' ? 'white' : 'transparent'"
                  clearable
              ></v-autocomplete>
            </div>

            <div style="width: 180px;">
               <v-autocomplete
                  v-model="selectedCustomer"
                  :items="availableCustomers"
                  label="Cliente"
                  variant="outlined"
                  density="compact"
                  hide-details
                  class="filter-select rounded-0"
                  :bg-color="themeStore.currentMode === 'light' ? 'white' : 'transparent'"
                  clearable
              ></v-autocomplete>
            </div>

            <div style="width: 180px;">
               <v-autocomplete
                  v-model="selectedFabric"
                  :items="availableFabrics"
                  label="Tecido"
                  variant="outlined"
                  density="compact"
                  hide-details
                  class="filter-select rounded-0"
                  :bg-color="themeStore.currentMode === 'light' ? 'white' : 'transparent'"
                  clearable
              ></v-autocomplete>
            </div>

            <div class="search-wrap d-flex align-center flex-grow-1" :class="themeStore.currentMode === 'light' ? 'search-light' : 'search-dark'">
              <v-icon :color="themeStore.currentMode === 'light' ? 'grey-darken-1' : 'white-70'">mdi-magnify</v-icon>
              <input
                v-model="search"
                type="text"
                placeholder="Buscar por ID, ref, cliente..."
                class="clean-input flex-grow-1"
              />
            </div>
          </div>
        </div>
      </div>

      <div class="px-6 py-3 flex-shrink-0">
        <v-row dense>
          <v-col cols="12" sm="6" md="" v-for="(kpi, key) in kpiDisplayData" :key="key">
            <v-card class="kpi-card kpi-rect bg-gradient-custom hover-elevate py-3 px-4"
                    :class="[kpi.gradient]"
                    v-ripple elevation="2" @click="openKpiModal(kpi.key as any)">
              <div class="kpi-bg-icon"><v-icon>{{ kpi.icon }}</v-icon></div>
              <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                <div class="d-flex align-center" style="gap: 8px;">
                  <v-icon size="18" class="opacity-80">{{ kpi.icon }}</v-icon>
                  <span class="kpi-label">{{ kpi.title }}</span>
                </div>
                <div class="kpi-number-group my-1">
                  <span class="kpi-value">{{ kpi.count }}</span>
                  <span class="text-caption font-weight-medium ml-1 opacity-70">pedidos</span>
                </div>
                <div class="kpi-footer mt-1">{{ formatMeters(kpi.meters) }}m totais</div>
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
             <div class="mt-4 font-weight-medium opacity-70">Carregando liberação...</div>
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
                  <v-tooltip location="top" content-class="tooltip-contrast">
                     <template v-slot:activator="{ props }">
                        <v-icon
                          v-bind="props"
                          :color="getCapacityColor(day.date).color"
                          :icon="isDayOverloaded(day.date) ? 'mdi-alert-circle' : 'mdi-check-circle'"
                        ></v-icon>
                     </template>
                     <span>{{ formatMeters(getDayProduction(day.date).total) }}m / {{ formatMeters(getDailyLimit(day.date)) }}m</span>
                  </v-tooltip>
                </div>

                <div class="capacity-bar mb-2">
                   <v-progress-linear
                      :model-value="(getDayProduction(day.date).total / getDailyLimit(day.date)) * 100"
                      :color="getCapacityColor(day.date).color"
                      height="6"
                      rounded="0"
                      class="opacity-90"
                   ></v-progress-linear>
                </div>

                <div class="d-flex gap-2">
                    <div class="mini-stat flex-grow-1" :class="themeStore.currentMode === 'light' ? 'mini-stat-light' : 'mini-stat-dark'">
                       <v-icon size="12" class="mr-1 opacity-70">mdi-table-furniture</v-icon>
                       <span class="text-[10px] font-weight-bold">{{ formatMeters(getDayProduction(day.date).mesa) }}</span>
                    </div>
                    <div class="mini-stat flex-grow-1" :class="themeStore.currentMode === 'light' ? 'mini-stat-light' : 'mini-stat-dark'">
                       <v-icon size="12" class="mr-1 opacity-70">mdi-run</v-icon>
                       <span class="text-[10px] font-weight-bold">{{ formatMeters(getDayProduction(day.date).corrida) }}</span>
                    </div>
                 </div>
              </div>

              <div class="kanban-content pa-2 custom-scroll flex-grow-1 overflow-y-auto">
                <template v-if="day.orders.length > 0">
                  <v-card
                    v-for="order in day.orders"
                    :key="order.id"
                    class="production-card mb-2 rounded-0 border-s-4"
                    :class="[
                      themeStore.currentMode === 'light' ? 'bg-white border-thin' : 'bg-surface-card border-white-05',
                      { 'status-delayed': isOrderDelayed(order) }
                    ]"
                    :style="`border-left-color: ${getOrderPriorityColor(order.items)} !important; border-left-width: 4px !important;`"
                    variant="flat"
                    @click="openReleaseModal(order)"
                    v-ripple
                  >
                    <v-card-text class="pa-3 d-flex flex-column h-100 justify-space-between">
                       <div v-if="isOrderDelayed(order)" class="delayed-badge">
                          <v-icon size="12" color="white">mdi-alert</v-icon>
                      </div>

                      <div>
                          <div class="d-flex align-center justify-space-between mb-1">
                               <span class="pill-ref">#{{ String(order.order_number).padStart(4, '0') }}</span>
                               <span class="text-[9px] font-weight-black text-uppercase opacity-60">{{ order.creator_name.split(' ')[0] }}</span>
                          </div>

                          <div class="text-body-2 font-weight-black lh-1 text-truncate mb-1" :title="order.customer_name">
                            {{ order.customer_name }}
                          </div>

                          <div class="d-flex flex-wrap gap-1 mb-2">
                             <v-chip
                                v-for="fabric in getUniqueFabrics(order.items).slice(0, 2)"
                                :key="fabric"
                                size="x-small"
                                class="fabric-tag rounded-0"
                                variant="outlined"
                                :class="{ 'light-tag': isLight }"
                             >
                                {{ fabric }}
                             </v-chip>
                             <span v-if="getUniqueFabrics(order.items).length > 2" class="text-[9px] opacity-60 align-self-center ml-1">
                                +{{ getUniqueFabrics(order.items).length - 2 }}
                             </span>
                          </div>
                      </div>

                      <div class="d-flex justify-space-between align-center mt-2 pt-2 border-t" :class="themeStore.currentMode === 'light' ? 'border-grey-lighten-3' : 'border-white-05'">
                         <div v-if="getReleasableItemCount(order) > 0">
                           <span class="text-primary font-weight-black text-caption d-flex align-center">
                              <v-icon start size="12" class="animate-bounce">mdi-rocket-launch</v-icon>
                              Liberar {{ getReleasableItemCount(order) }}
                           </span>
                        </div>
                        <div v-else>
                           <span class="text-caption font-weight-medium opacity-60">{{ getOrderStatus(order).text }}</span>
                        </div>

                         <div class="d-flex align-center font-weight-black text-caption">
                             <v-icon start size="12" :color="getOrderMachineIcon(order.items).color" class="mr-1">
                                {{ getOrderMachineIcon(order.items).icon }}
                             </v-icon>
                             {{ formatMeters(getTotalMeters(order.items)) }}m
                         </div>
                      </div>
                    </v-card-text>
                  </v-card>
                </template>

                <div v-else class="d-flex flex-column align-center justify-center mt-8 opacity-40">
                    <v-icon size="24" class="mb-2">mdi-calendar-blank</v-icon>
                    <span class="text-[10px] font-weight-bold text-uppercase">Livre</span>
                </div>
              </div>
            </div>
          </div>
        </v-card>
      </div>

      <ReleaseOrderModal
        :show="showReleaseModal"
        :order="selectedOrderForRelease"
        @close="closeReleaseModal"
        @update-items="fetchReleasedItems"
      />

      <LaunchDetailModal
        v-if="showLaunchDetailModal"
        :show="showLaunchDetailModal"
        :order-id="selectedLaunchOrderId"
        @close="closeLaunchDetailModal"
        @item-updated="fetchReleasedItems"
      />

      <v-dialog
        v-model="showKpiModal"
        width="90vw"
        height="90vh"
        class="kpi-modal-dialog"
        scrollable
        transition="dialog-bottom-transition"
      >
        <v-card class="d-flex flex-column flex-md-row h-100 w-100 overflow-hidden rounded-0" :class="isLight ? 'bg-white' : 'glassmorphism-card-dialog'">
          <div class="kpi-sidebar pa-5 d-flex flex-column flex-shrink-0" :class="[`sidebar-${activeKpi}`, { 'light-sidebar': isLight }]">
            <div class="d-flex align-center gap-2 mb-6">
               <v-icon size="32" :color="isLight ? 'grey-darken-4' : 'white'">{{ getKpiInfo(activeKpi).icon }}</v-icon>
               <h3 class="text-h6 font-weight-black" :class="isLight ? 'text-grey-darken-4' : 'text-white'">{{ getKpiInfo(activeKpi).title }}</h3>
            </div>

            <p class="text-body-2 mb-6 opacity-90" :class="isLight ? 'text-grey-darken-3' : 'text-grey-lighten-2'" style="line-height: 1.6;">
              {{ getKpiInfo(activeKpi).description }}
            </p>

            <v-divider class="mb-6 border-opacity-25" :class="{ 'border-black': isLight }"></v-divider>

            <div class="stat-box mb-4">
              <div class="text-caption text-uppercase font-weight-bold" :class="isLight ? 'text-grey-darken-2' : 'text-grey-lighten-3'">Total Pedidos</div>
              <div class="text-h4 font-weight-black" :class="isLight ? 'text-grey-darken-4' : 'text-white'">{{ filteredKpiItems.length }}</div>
            </div>

            <div class="stat-box mb-6">
              <div class="text-caption text-uppercase font-weight-bold" :class="isLight ? 'text-grey-darken-2' : 'text-grey-lighten-3'">Metragem Acumulada</div>
              <div class="text-h4 font-weight-black" :class="isLight ? 'text-grey-darken-4' : 'text-white'">{{ formatMeters(kpiModalTotalMeters) }}m</div>
            </div>

            <v-spacer></v-spacer>

             <div class="d-flex flex-column gap-2 mb-4">
                 <v-btn
                    :color="filterDelayed ? 'red-lighten-1' : (isLight ? 'grey-lighten-2' : 'white')"
                    :variant="filterDelayed ? 'flat' : 'outlined'"
                    class="btn-rect"
                    :class="{ 'text-grey-darken-4': isLight && !filterDelayed }"
                    prepend-icon="mdi-clock-alert"
                    @click="filterDelayed = !filterDelayed"
                 >
                    {{ filterDelayed ? 'Mostrando Atrasados' : 'Filtrar Atrasados (+3d)' }}
                    <v-badge v-if="delayedCount > 0" :content="delayedCount" color="red" inline class="ml-2"></v-badge>
                 </v-btn>

                 <v-btn
                    :color="isLight ? 'grey-lighten-2' : 'white'"
                    :class="{ 'text-grey-darken-4': isLight }"
                    variant="tonal"
                    prepend-icon="mdi-file-pdf-box"
                    class="btn-rect"
                    :loading="generatingPdf"
                    @click="generateKpiPdf"
                 >
                    Baixar Relatório PDF
                 </v-btn>
            </div>
          </div>

          <div class="d-flex flex-column flex-grow-1 h-100 position-relative" :class="isLight ? 'bg-white' : 'bg-surface-transparent'">
             <v-toolbar color="transparent" density="compact" class="pr-2 pt-2 px-6 border-b border-opacity-10">
               <div class="d-flex align-center gap-4 w-100">
                  <v-text-field
                    v-model="kpiSearch"
                    prepend-inner-icon="mdi-magnify"
                    placeholder="Buscar cliente, pedido ou vendedor..."
                    :variant="isLight ? 'outlined' : 'outlined'"
                    density="compact"
                    :bg-color="isLight ? 'white' : 'rgba(255,255,255,0.05)'"
                    hide-details
                    class="search-field-custom rounded-0 flex-grow-1"
                    style="max-width: 400px;"
                  ></v-text-field>
                  <v-spacer></v-spacer>
                  <v-btn icon="mdi-close" variant="text" @click="showKpiModal = false"></v-btn>
               </div>
             </v-toolbar>

             <div class="flex-grow-1 overflow-y-auto px-6 py-4 custom-scroll">
                <div v-if="filteredKpiItems.length === 0" class="d-flex flex-column align-center justify-center h-50 text-grey">
                   <v-icon size="64" class="mb-4 opacity-30">mdi-text-box-search-outline</v-icon>
                   <p class="text-body-1">Nenhum pedido encontrado {{ filterDelayed ? 'com atraso crítico' : 'nesta categoria' }}.</p>
                </div>

                <v-slide-y-transition group>
                  <v-card
                    v-for="item in filteredKpiItems"
                    :key="item.id"
                    class="mb-3 kpi-list-item pa-0 overflow-hidden cursor-pointer rounded-0 border-s-4"
                    :class="[
                      { 'status-delayed': isOrderDelayed(item) },
                      isLight ? 'light-list-item elevation-1' : ''
                    ]"
                    elevation="0"
                    border
                    @click="openLaunchDetail(item)"
                    v-ripple
                  >
                     <div class="d-flex flex-column flex-sm-row">
                        <div class="pa-4 flex-grow-1 position-relative">
                           <div v-if="isOrderDelayed(item)" class="delayed-badge-list">
                              Atrasado
                           </div>

                           <div class="d-flex align-center gap-2 flex-wrap mb-2">
                              <v-chip color="primary" size="small" variant="flat" class="font-weight-black px-3 rounded-0">
                                  #{{ String(item.order_number).padStart(4, '0') }}
                              </v-chip>
                              <span class="text-h6 font-weight-bold text-truncate" :class="isLight ? 'text-grey-darken-4' : 'text-white'">{{ item.customer_name }}</span>
                           </div>

                           <div class="d-flex flex-wrap align-center text-caption gap-4 mb-3" :class="isLight ? 'text-grey-darken-2' : 'text-grey-lighten-1'">
                              <div class="d-flex align-center">
                                 <v-avatar size="20" :color="isLight ? 'grey-lighten-2' : 'grey-darken-3'" class="mr-2">
                                    <v-icon size="12" :color="isLight ? 'grey-darken-1' : 'grey'">mdi-account</v-icon>
                                 </v-avatar>
                                 {{ item.creator_name }}
                              </div>
                              <div class="d-flex align-center" v-if="item.scheduled_date">
                                 <v-icon size="16" color="primary" class="mr-2">mdi-calendar-clock</v-icon>
                                 Entrada: {{ getShortDate(new Date(item.scheduled_date)) }}
                                 <span v-if="isOrderDelayed(item)" class="text-red ml-2 font-weight-bold">
                                    ({{ getDaysInProduction(item.scheduled_date) }} dias na fila)
                                 </span>
                              </div>
                           </div>

                           <v-divider class="mb-3 border-opacity-10"></v-divider>

                           <div class="d-flex flex-wrap gap-2">
                              <span class="text-caption text-grey mr-1 align-self-center">Tecidos:</span>
                              <v-chip
                                v-for="fabric in getUniqueFabrics(item.items)"
                                :key="fabric"
                                size="x-small"
                                variant="outlined"
                                class="fabric-chip rounded-0"
                                :class="{ 'light-tag': isLight }"
                              >
                                  {{ fabric }}
                              </v-chip>
                           </div>
                        </div>

                        <div class="d-flex flex-sm-column align-center justify-space-between justify-sm-center pa-4 border-s-sm border-t border-t-sm-0 border-opacity-10"
                             :class="isLight ? 'bg-grey-lighten-4' : 'bg-surface-lighten-1'"
                             style="min-width: 140px;">
                           <div class="text-center">
                              <div class="text-caption text-uppercase text-grey mb-1 font-weight-bold">Total</div>
                              <div class="text-h5 font-weight-black" :class="isLight ? 'text-grey-darken-4' : 'text-white'" style="line-height: 1;">{{ formatMeters(getTotalMeters(item.items)) }}m</div>
                           </div>

                           <div class="mt-0 mt-sm-3 d-flex gap-2">
                              <v-icon
                                 :color="getOrderMachineIcon(item.items).color"
                                 :title="getOrderMachineIcon(item.items).icon === 'mdi-table-furniture' ? 'Mesa' : 'Corrida'"
                                 class="opacity-80"
                                 :class="{ 'text-grey-darken-2': isLight && !getOrderMachineIcon(item.items).color.includes('cyan') && !getOrderMachineIcon(item.items).color.includes('amber') }"
                              >
                                 {{ getOrderMachineIcon(item.items).icon }}
                              </v-icon>
                           </div>
                        </div>
                     </div>
                  </v-card>
                </v-slide-y-transition>
             </div>
          </div>
        </v-card>
      </v-dialog>

    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, computed, watch } from 'vue';
import { supabase } from '@/api/supabase';
import { format, startOfWeek, addDays, subDays, isSameDay, endOfWeek, getDay, addWeeks, differenceInCalendarDays } from 'date-fns';
import { ptBR } from 'date-fns/locale';
import { useUserStore } from '@/stores/user';
import { useThemeStore } from '@/stores/theme'; // Store de Tema Híbrido
import ReleaseOrderModal from '@/components/production/ReleaseOrderModal.vue';
import LaunchDetailModal from '@/components/LaunchDetailModal.vue';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';

// --- TYPES ---
type ProductionItem = {
  id: string; order_id: string; order_number: number; customer_name: string;
  creator_name: string; fabric_type: string; stamp_ref: string; quantity_meters: number;
  status: string; scheduled_date: string; stamp_image_url?: string; is_op_generated: boolean;
  production_start_date?: Date;
  billed_at: string | null;
};

type GroupedOrder = {
    id: string; order_number: number; customer_name: string;
    creator_name: string; billed_at: string | null;
    items: ProductionItem[];
    scheduled_date?: string;
};

// --- STATE ---
const userStore = useUserStore();
const themeStore = useThemeStore();
const loading = ref(true);
const search = ref('');

// Computed do Modo Light
const isLight = computed(() => themeStore.currentMode === 'light');

// Filtros Principais
const selectedCreator = ref<string | null>(null);
const selectedCustomer = ref<string | null>(null);
const selectedFabric = ref<string | null>(null);

const currentWeekStart = ref(startOfWeek(new Date(), { weekStartsOn: 1 }));
const allProductionItems = ref<ProductionItem[]>([]);

// Modal Release
const showReleaseModal = ref(false);
const selectedOrderForRelease = ref<GroupedOrder | null>(null);

// Modal Launch Detail (Detalhes do Pedido)
const showLaunchDetailModal = ref(false);
const selectedLaunchOrderId = ref<string | null>(null);

// Modal KPI (Avançado)
const showKpiModal = ref(false);
const activeKpi = ref<'fila' | 'faturamento' | 'concluido'>('fila');
const kpiSearch = ref('');
const kpiModalItems = ref<GroupedOrder[]>([]);
const filterDelayed = ref(false);
const generatingPdf = ref(false);

// --- CONSTANTS ---
const dailyLimits = { mesa: 4000, corrida: 10000, overall: 14000, saturday: 5000 };
const fabricMachineMap: Record<string, 'MESA' | 'CORRIDA'> = {
  'TECIDO CREPONADO': 'MESA', 'MALHA TULLE': 'MESA', 'MALHA FLUITY': 'MESA',
  'MALHA CANELADA': 'MESA', 'MALHA SUPLEX': 'MESA', 'TECIDO CHIFFON': 'MESA',
  'MALHA LIGANET': 'MESA', 'TECIDO CREPINHO': 'CORRIDA', 'TECIDO TWILL FLY': 'CORRIDA',
  'TECIDO TOQUE DE SEDA': 'CORRIDA', 'TECIDO CORTA-VENTO': 'CORRIDA', 'TECIDO TACTEL': 'CORRIDA',
  'TECIDO ALFAIATARIA': 'CORRIDA'
};

// --- COMPUTED PROPERTIES ---

const availableCustomers = computed(() => {
  const customers = new Set(allProductionItems.value.map(i => i.customer_name));
  return Array.from(customers).sort();
});

const availableCreators = computed(() => {
  const creators = new Set(allProductionItems.value.map(i => i.creator_name));
  return Array.from(creators).sort();
});

const availableFabrics = computed(() => {
  const fabrics = new Set(allProductionItems.value.map(i => i.fabric_type).filter(Boolean));
  return Array.from(fabrics).sort();
});

const groupedOrders = computed((): GroupedOrder[] => {
    const ordersMap = new Map<string, GroupedOrder>();
    const itemsWithStartDate = allProductionItems.value.map(item => ({
        ...item,
        production_start_date: new Date(item.scheduled_date + 'T12:00:00')
    }));

    for (const item of itemsWithStartDate) {
        if (!ordersMap.has(item.order_id)) {
            ordersMap.set(item.order_id, {
                id: item.order_id,
                order_number: item.order_number,
                customer_name: item.customer_name,
                creator_name: item.creator_name,
                billed_at: item.billed_at,
                scheduled_date: item.scheduled_date,
                items: []
            });
        }
        ordersMap.get(item.order_id)!.items.push(item);
    }
    return Array.from(ordersMap.values());
});

const filteredOrders = computed(() => {
    let result = groupedOrders.value;

    if (selectedCreator.value) result = result.filter(order => order.creator_name === selectedCreator.value);
    if (selectedCustomer.value) result = result.filter(order => order.customer_name === selectedCustomer.value);
    if (selectedFabric.value) result = result.filter(order => order.items.some(item => item.fabric_type === selectedFabric.value));

    if (search.value) {
      const query = search.value.toLowerCase();
      result = result.filter(order =>
          order.customer_name.toLowerCase().includes(query) ||
          order.creator_name.toLowerCase().includes(query) ||
          String(order.order_number).includes(query)
      );
    }
    return result;
});

const kpiData = computed(() => {
    const data = {
        fila: { orders: 0, meters: 0, items: [] as GroupedOrder[] },
        faturamento: { orders: 0, meters: 0, items: [] as GroupedOrder[] },
        concluido: { orders: 0, meters: 0, items: [] as GroupedOrder[] },
    };
    groupedOrders.value.forEach(order => {
        const statusInfo = getOrderStatus(order);
        const totalMeters = getTotalMeters(order.items);

        if (statusInfo.key === 'fila') {
            data.fila.orders++;
            data.fila.meters += totalMeters;
            data.fila.items.push(order);
        } else if (statusInfo.key === 'faturamento') {
            data.faturamento.orders++;
            data.faturamento.meters += totalMeters;
            data.faturamento.items.push(order);
        } else if (statusInfo.key === 'concluido') {
            data.concluido.orders++;
            data.concluido.meters += totalMeters;
            data.concluido.items.push(order);
        }
    });
    return data;
});

const kpiDisplayData = computed(() => ({
  fila: {
    key: 'fila',
    title: 'Na Fila',
    count: kpiData.value.fila.orders,
    meters: kpiData.value.fila.meters,
    icon: 'mdi-timer-sand',
    iconColor: 'blue-grey',
    lightIconBg: 'blue-grey-lighten-4',
    gradient: 'bg-gradient-blue'
  },
  faturamento: {
    key: 'faturamento',
    title: 'Aguard. Faturamento',
    count: kpiData.value.faturamento.orders,
    meters: kpiData.value.faturamento.meters,
    icon: 'mdi-file-document-alert-outline',
    iconColor: 'amber',
    lightIconBg: 'amber-lighten-4',
    gradient: 'bg-gradient-warning'
  },
  concluido: {
    key: 'concluido',
    title: 'Concluídos',
    count: kpiData.value.concluido.orders,
    meters: kpiData.value.concluido.meters,
    icon: 'mdi-check-all',
    iconColor: 'green',
    lightIconBg: 'green-lighten-4',
    gradient: 'bg-gradient-green'
  }
}));

const weekDays = computed(() => {
    return Array.from({ length: 6 }, (_, i) => {
        const date = addDays(currentWeekStart.value, i);
        return { date, name: format(date, 'EEEE', { locale: ptBR }).split('-')[0], orders: getOrdersForDay(date) };
    });
});

// Computed para o Modal KPI
const delayedCount = computed(() => {
    return kpiModalItems.value.filter(item => isOrderDelayed(item)).length;
});

const filteredKpiItems = computed(() => {
  let items = kpiModalItems.value;

  // Filtro de Atrasados
  if (filterDelayed.value) {
      items = items.filter(item => isOrderDelayed(item));
  }

  // Filtro de Busca
  if (kpiSearch.value) {
    const query = kpiSearch.value.toLowerCase();
    items = items.filter(item =>
       item.customer_name.toLowerCase().includes(query) ||
       String(item.order_number).includes(query) ||
       item.creator_name.toLowerCase().includes(query)
    );
  }
  return items;
});

const kpiModalTotalMeters = computed(() => {
   return filteredKpiItems.value.reduce((acc, curr) => acc + getTotalMeters(curr.items), 0);
});

// --- METHODS ---

// Lógica de Atraso Corrigida
const getDaysInProduction = (dateString?: string) => {
    if (!dateString) return 0;
    return differenceInCalendarDays(new Date(), new Date(dateString));
};

const isOrderDelayed = (order: GroupedOrder) => {
    if (!order.scheduled_date) return false;
    const daysDiff = getDaysInProduction(order.scheduled_date);
    if (daysDiff <= 3) return false;

    const hasItemsWaitingForRelease = order.items.some(item => item.status === 'production_queue');
    return hasItemsWaitingForRelease;
};

const getUniqueFabrics = (items: ProductionItem[]) => {
   const fabrics = new Set(items.map(i => i.fabric_type).filter(Boolean));
   return Array.from(fabrics);
};

const getOrderMachineIcon = (items: ProductionItem[]) => {
   let mesaCount = 0;
   let corridaCount = 0;
   items.forEach(i => {
      if (getMachineTypeForFabric(i.fabric_type) === 'MESA') mesaCount += i.quantity_meters;
      else corridaCount += i.quantity_meters;
   });
   if (mesaCount > corridaCount) return { icon: 'mdi-table-furniture', color: isLight.value ? 'cyan-darken-1' : 'cyan-lighten-3' };
   if (corridaCount > mesaCount) return { icon: 'mdi-run', color: isLight.value ? 'amber-darken-2' : 'amber-lighten-3' };
   return { icon: 'mdi-factory', color: isLight.value ? 'grey-darken-1' : 'grey-lighten-3' };
};

const getCapacityColor = (date: Date) => {
   const limit = getDailyLimit(date);
   const current = getDayProduction(date).total;
   const percent = current / limit;
   if (percent > 1) return { color: 'error', text: 'text-error' };
   if (percent > 0.85) return { color: 'warning', text: 'text-warning' };
   return { color: 'success', text: 'text-success' };
};

const orderHasReleasableItem = (order: GroupedOrder): boolean => {
  if (!order || !order.items) return false;
  return order.items.some(item => item.status === 'production_queue');
};

const getReleasableItemCount = (order: GroupedOrder): number => {
  if (!order || !order.items) return 0;
  return order.items.filter(item => item.status === 'production_queue').length;
};

// --- KPI HELPER ---
const getKpiInfo = (key: string) => {
   switch(key) {
      case 'fila': return {
         title: 'Fila de Produção',
         icon: 'mdi-timer-sand',
         description: 'Estes pedidos estão aguardando o início ou a finalização dos processos produtivos. Monitore os prazos para evitar atrasos.'
      };
      case 'faturamento': return {
         title: 'Aguardando Faturamento',
         icon: 'mdi-file-document-alert-outline',
         description: 'Pedidos totalmente produzidos que aguardam emissão de nota fiscal para serem despachados.'
      };
      case 'concluido': return {
         title: 'Histórico de Concluídos',
         icon: 'mdi-check-all',
         description: 'Pedidos que completaram todo o ciclo de vida na produção e já foram faturados.'
      };
      default: return { title: '', icon: '', description: '' };
   }
}

const openKpiModal = (statusKey: 'fila' | 'faturamento' | 'concluido') => {
    activeKpi.value = statusKey;
    kpiModalItems.value = kpiData.value[statusKey].items;
    kpiSearch.value = '';
    filterDelayed.value = false;
    showKpiModal.value = true;
};

// --- PDF GENERATION ---
const imageToBase64 = (url: string): Promise<string> => new Promise((resolve, reject) => {
    const img = new Image();
    img.crossOrigin = 'Anonymous';
    img.onload = () => {
        const canvas = document.createElement('canvas');
        canvas.width = img.width; canvas.height = img.height;
        const ctx = canvas.getContext('2d');
        if (ctx) {
            ctx.drawImage(img, 0, 0);
            resolve(canvas.toDataURL('image/png'));
        } else {
            reject(new Error('Contexto do canvas não obtido'));
        }
    };
    img.onerror = reject;
    img.src = url;
});

const generateKpiPdf = async () => {
    generatingPdf.value = true;
    try {
        const doc = new jsPDF({ orientation: 'p', unit: 'mm', format: 'a4' });
        const pageWidth = doc.internal.pageSize.width;

        try {
            const logoUrl = 'https://cdn.shopify.com/s/files/1/0661/4574/6991/files/Sem_nome_1080_x_800_px_1080_x_500_px_1080_x_400_px_1000_x_380_px_da020cf2-2bb9-4dac-8dd3-4548cfd2e5ae.png?v=1756811713';
            const logoBase64 = await imageToBase64(logoUrl);
            doc.addImage(logoBase64, 'PNG', 15, 12, 40, 15);
        } catch (e) { console.error("Logo PDF Error", e); }

        doc.setFontSize(14).setFont('helvetica', 'bold').setTextColor(0);
        const titleSuffix = filterDelayed.value ? '(Atrasados)' : '';
        doc.text(`Relatório de ${getKpiInfo(activeKpi.value).title} ${titleSuffix}`, pageWidth / 2, 20, { align: 'center' });

        doc.setFontSize(9).setFont('helvetica', 'normal').setTextColor(100);
        doc.text(`Gerado em: ${format(new Date(), "dd/MM/yyyy HH:mm")}`, pageWidth / 2, 26, { align: 'center' });

        const tableBody = [];
        for (const order of filteredKpiItems.value) {
             for (const item of order.items) {
                 if (filterDelayed.value && !isOrderDelayed(order)) continue;

                 tableBody.push([
                     `#${String(order.order_number).padStart(4, '0')}`,
                     order.customer_name,
                     format(new Date(order.scheduled_date || ''), 'dd/MM'),
                     `${getDaysInProduction(order.scheduled_date)} dias`,
                     item.stamp_ref,
                     item.fabric_type,
                     `${formatMeters(item.quantity_meters)}m`
                 ]);
             }
        }

        autoTable(doc, {
            startY: 35,
            head: [['Ped.', 'Cliente', 'Entrada', 'Tempo', 'Estampa', 'Tecido', 'Qtd.']],
            body: tableBody,
            theme: 'grid',
            styles: { fontSize: 8, valign: 'middle' },
            headStyles: { fillColor: [41, 128, 185], textColor: 255 },
            columnStyles: {
                0: { cellWidth: 15 },
                1: { cellWidth: 40 },
                2: { cellWidth: 15 },
                3: { cellWidth: 20 },
                4: { cellWidth: 35 },
                5: { cellWidth: 40 },
                6: { cellWidth: 15, halign: 'right' }
            },
             didParseCell: (data) => {
                if (data.section === 'body' && parseInt(data.row.raw[3] as string) > 3) {
                    data.cell.styles.textColor = [255, 0, 0];
                }
            }
        });

        doc.save(`Relatorio_${activeKpi.value}_${format(new Date(), 'yyyy-MM-dd')}.pdf`);
    } catch (error) {
        console.error("PDF generation failed:", error);
    } finally {
        generatingPdf.value = false;
    }
};

const fetchReleasedItems = async () => {
  loading.value = true;
  try {
    const fromDate = format(startOfWeek(currentWeekStart.value, { weekStartsOn: 1 }), 'yyyy-MM-dd');
    const toDate = format(addWeeks(endOfWeek(currentWeekStart.value, { weekStartsOn: 1 }), 4), 'yyyy-MM-dd');

    const { data, error } = await supabase
      .from('production_schedule')
      .select(`
        scheduled_date,
        order:orders!inner(id, customer_name, order_number, billed_at, creator:created_by!left(full_name)),
        item:order_items!inner(id, status, quantity_meters, fabric_type, stamp_ref, stamp_image_url, is_op_generated)
      `)
      .gte('scheduled_date', fromDate)
      .lte('scheduled_date', toDate)
      .order('scheduled_date', { ascending: true });

    if (error) throw error;

    allProductionItems.value = (data || []).map((entry: any) => ({
      id: entry.item.id,
      order_id: entry.order.id,
      order_number: entry.order.order_number,
      customer_name: entry.order.customer_name,
      creator_name: entry.order.creator?.full_name || 'N/A',
      billed_at: entry.order.billed_at,
      fabric_type: entry.item.fabric_type,
      stamp_ref: entry.item.stamp_ref,
      quantity_meters: entry.item.quantity_meters,
      status: entry.item.status,
      scheduled_date: entry.scheduled_date,
      stamp_image_url: entry.item.stamp_image_url,
      is_op_generated: entry.item.is_op_generated,
    }));
  } catch (err) {
    console.error('Erro ao buscar itens:', err);
  } finally {
    loading.value = false;
  }
};

watch(currentWeekStart, () => {
  fetchReleasedItems();
});

onMounted(() => {
  fetchReleasedItems();
});

const getOrdersForDay = (date: Date): GroupedOrder[] => {
    const orderIdsForDay = new Set<string>();
    filteredOrders.value.forEach(order => {
        const hasItemOnDay = order.items.some(item =>
            item.production_start_date && isSameDay(item.production_start_date, date)
        );
        if (hasItemOnDay) orderIdsForDay.add(order.id);
    });
    return filteredOrders.value.filter(order => orderIdsForDay.has(order.id));
};

const getDayProduction = (date: Date) => {
    const ordersOnDay = getOrdersForDay(date);
    let mesa = 0;
    let corrida = 0;
    ordersOnDay.forEach(order => {
        order.items.forEach(item => {
            if (item.production_start_date && isSameDay(item.production_start_date, date)) {
                if (getMachineTypeForFabric(item.fabric_type) === 'MESA') {
                    mesa += item.quantity_meters;
                } else {
                    corrida += item.quantity_meters;
                }
            }
        });
    });
    return { mesa, corrida, total: mesa + corrida };
};

const getTotalMeters = (items: ProductionItem[]) => items.reduce((sum, item) => sum + item.quantity_meters, 0);

const getOrderPriorityColor = (items: ProductionItem[]) => {
    const allCompleted = items.every(item => item.status === 'completed');
    if (allCompleted) return isLight.value ? '#388E3C' : 'var(--v-theme-success)';
    const hasMesa = items.some(item => getMachineTypeForFabric(item.fabric_type) === 'MESA');
    const hasCorrida = items.some(item => getMachineTypeForFabric(item.fabric_type) === 'CORRIDA');
    if (hasMesa && hasCorrida) return '#FFAB40';
    if (hasMesa) return isLight.value ? '#00ACC1' : 'var(--v-theme-cyan)';
    return isLight.value ? '#FFB300' : 'var(--v-theme-amber)';
};

const getOrderStatus = (order: GroupedOrder): { text: string, color: string, key: string } => {
    const allCompleted = order.items.every(item => item.status === 'completed');
    if (allCompleted) {
        return order.billed_at
            ? { text: 'Concluído', color: 'success', key: 'concluido' }
            : { text: 'Faturar', color: 'warning', key: 'faturamento' };
    }
    return { text: 'Em Fila', color: 'blue-grey-lighten-2', key: 'fila' };
};

const openReleaseModal = (order: GroupedOrder) => {
    selectedOrderForRelease.value = order;
    showReleaseModal.value = true;
};
const closeReleaseModal = () => {
    showReleaseModal.value = false;
    selectedOrderForRelease.value = null;
};

// --- LAUNCH DETAIL NAVIGATION ---
const openLaunchDetail = (order: GroupedOrder) => {
    selectedLaunchOrderId.value = order.id;
    showLaunchDetailModal.value = true;
};
const closeLaunchDetailModal = () => {
    showLaunchDetailModal.value = false;
    selectedLaunchOrderId.value = null;
};

const getMachineTypeForFabric = (fabric: string): 'MESA' | 'CORRIDA' => fabricMachineMap[fabric] || 'CORRIDA';
const weekRangeText = computed(() => `${format(currentWeekStart.value, 'dd MMM', { locale: ptBR })} - ${format(endOfWeek(currentWeekStart.value, { weekStartsOn: 1 }), 'dd MMM', { locale: ptBR })}`);
const nextWeek = () => { currentWeekStart.value = addDays(currentWeekStart.value, 7); };
const previousWeek = () => { currentWeekStart.value = subDays(currentWeekStart.value, 7); };
const getShortDate = (date: Date) => format(date, 'dd/MM');
const formatMeters = (meters: number) => Number(meters || 0).toLocaleString('pt-BR', { minimumFractionDigits: 0, maximumFractionDigits: 0 });
const getDailyLimit = (date: Date) => getDay(date) === 6 ? dailyLimits.saturday : dailyLimits.overall;
const isDayOverloaded = (date: Date) => {
    const prod = getDayProduction(date);
    return prod.total > getDailyLimit(date) || prod.mesa > dailyLimits.mesa || prod.corrida > dailyLimits.corrida;
}
</script>

<style scoped lang="scss">
.liberacao-layout { position: relative; }
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

.controls-bar {
  border: 1px solid rgba(0,0,0,0.08);
  border-radius: 0;
  padding: 10px;
}
.controls-light { background: #ffffff; }
.controls-dark { background: rgba(30,30,35,0.55); backdrop-filter: blur(16px); border: 1px solid rgba(255,255,255,0.08); }

.period-nav { border-radius: 0; height: 40px; overflow: hidden; }
.period-nav-light { border: 1px solid rgba(0,0,0,0.12); background: #fafafa; }
.period-nav-dark { border: 1px solid rgba(255,255,255,0.10); background: rgba(255,255,255,0.06); }
.period-label { min-width: 190px; display: flex; align-items: center; justify-content: center; height: 40px; }

.search-wrap { height: 40px; border-radius: 0; padding: 0 12px; min-width: 250px; flex: 1 1 300px; }
.search-light { background: #f4f6f8; border: 1px solid rgba(0,0,0,0.08); }
.search-dark { background: rgba(255,255,255,0.08); border: 1px solid rgba(255,255,255,0.10); }
.clean-input { border: none; outline: none; background: transparent; font-size: 12px; color: inherit; width: 100%; }
.filter-select :deep(.v-field) { border-radius: 0 !important; }
.filter-select :deep(.v-field__input) { min-height: 40px !important; padding-top: 8px !important; }

.kpi-bg-icon { position: absolute; right: -20px; bottom: -20px; opacity: 0.15; transform: rotate(-15deg); pointer-events: none; z-index: 0; }
.kpi-bg-icon .v-icon { font-size: 100px; color: white; }
.kpi-card { border: 1px solid rgba(255,255,255,0.15); color: white; min-height: 110px; position: relative; overflow: hidden; }

.bg-gradient-blue { background: linear-gradient(135deg, #1E88E5, #1565C0); }
.bg-gradient-warning { background: linear-gradient(135deg, #FFB300, #F57F17); }
.bg-gradient-green { background: linear-gradient(135deg, #43A047, #2E7D32); }

.kpi-label { font-size: 12px; font-weight: 900; letter-spacing: .2px; text-transform: uppercase; }
.kpi-value { font-size: 22px; font-weight: 900; letter-spacing: .2px; }
.kpi-footer { font-size: 11px; opacity: .9; font-weight: 700; }

.kanban-container { gap: 0; }
.kanban-column { flex: 1; min-width: 240px; }

.glass-card { background: rgba(30, 30, 35, 0.45); backdrop-filter: blur(25px); border: 1px solid rgba(255,255,255,0.08); }
.bg-white-05 { background: rgba(255,255,255,0.05); }
.border-white-05 { border-color: rgba(255,255,255,0.05) !important; }
.bg-surface-card { background-color: rgba(255, 255, 255, 0.05); }

.custom-scroll::-webkit-scrollbar { width: 6px; height: 6px; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.35); border-radius: 6px; }
.custom-scroll::-webkit-scrollbar-track { background: transparent; }

.production-card { transition: transform 0.2s, box-shadow 0.2s; position: relative; }
.production-card:hover { transform: translateY(-2px); box-shadow: 0 4px 8px rgba(0,0,0,0.15) !important; z-index: 2; }

.mini-stat { background: rgba(0,0,0,0.04); border-radius: 4px; padding: 4px; display: flex; align-items: center; justify-content: center; color: inherit; }
.mini-stat-light { background: #f5f5f5; border: 1px solid #e0e0e0; }
.mini-stat-dark { background: rgba(255,255,255,0.05); border: 1px solid rgba(255,255,255,0.08); }

.pill-ref {
  font-size: 9px; font-weight: 900; font-family: monospace; background: rgba(0,0,0,0.08); padding: 2px 6px; border-radius: 4px;
}

/* Pulsing & Status */
@keyframes pulse-red { 0% { box-shadow: 0 0 0 0 rgba(255, 82, 82, 0.7); } 70% { box-shadow: 0 0 0 6px rgba(255, 82, 82, 0); } 100% { box-shadow: 0 0 0 0 rgba(255, 82, 82, 0); } }
.status-delayed { animation: pulse-red 2s infinite; border: 1px solid rgba(255, 82, 82, 0.6) !important; }

.delayed-badge { position: absolute; top: 8px; right: 32px; background: #ff5252; border-radius: 50%; width: 20px; height: 20px; display: flex; align-items: center; justify-content: center; animation: pulse 1s infinite; }
.delayed-badge-list { position: absolute; top: 0; right: 0; background: #ff5252; color: white; font-size: 9px; font-weight: bold; padding: 2px 8px; border-bottom-left-radius: 8px; text-transform: uppercase; }

@keyframes pulse { 0% { opacity: 1; transform: scale(1); } 50% { opacity: 0.8; transform: scale(1.05); } 100% { opacity: 1; transform: scale(1); } }
.animate-bounce { animation: bounce 1.5s infinite; }

.lh-1 { line-height: 1 !important; }
.fabric-chip { font-size: 9px !important; }
.light-tag { color: #616161; border-color: #E0E0E0; background: #FFFFFF; }

/* Modal & Sidebar */
.glassmorphism-card-dialog { background: #1e1e24 !important; color: #fff; border: 1px solid rgba(255,255,255,0.1); }
.kpi-modal-dialog { @media (max-width: 960px) { margin: 0 !important; width: 100% !important; height: 100% !important; border-radius: 0 !important; } }
.kpi-sidebar { width: 280px; @media (max-width: 960px) { width: 100%; min-height: auto; } }
.sidebar-fila { background: linear-gradient(160deg, #37474F, #263238); }
.sidebar-faturamento { background: linear-gradient(160deg, #5D4037, #3E2723); }
.sidebar-concluido { background: linear-gradient(160deg, #1B5E20, #003300); }
.light-sidebar { background: #F5F5F5; border-right: 1px solid #E0E0E0; }
.light-sidebar.sidebar-fila { background: #ECEFF1; }
.light-sidebar.sidebar-faturamento { background: #FFF8E1; }
.light-sidebar.sidebar-concluido { background: #E8F5E9; }

.bg-surface-transparent { background: rgba(0,0,0,0.2); }
.bg-surface-lighten-1 { background: rgba(255,255,255,0.03); }
.kpi-list-item { background: rgba(255,255,255,0.03); border-color: rgba(255,255,255,0.05); transition: background 0.2s; }
.kpi-list-item:hover { background: rgba(255,255,255,0.06); }
.light-list-item { background: #FFFFFF; border: 1px solid #EEEEEE; }
.light-list-item:hover { background: #FAFAFA; border-color: #BDBDBD; }
</style>
