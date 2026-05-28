<template>
  <v-container fluid class="pa-0 fill-height bg-background-app">
    <div class="d-flex flex-column w-100 h-100">

      <div class="header-section px-6 py-4 border-b d-flex flex-column flex-md-row justify-space-between align-md-center gap-4 flex-shrink-0"
           :class="isLightMode ? 'bg-white border-grey-lighten-2' : 'bg-header-dark border-white-05'">

        <div class="d-flex align-center">
          <div class="icon-box-sm mr-3 rounded-lg d-flex align-center justify-center elevation-3"
               :class="isLightMode ? 'bg-grey-darken-3 text-white' : 'bg-gradient-primary'">
            <v-icon size="20" color="white">mdi-warehouse</v-icon>
          </div>
          <div>
            <div class="text-[10px] font-weight-bold opacity-60 letter-spacing-1 mb-0 text-uppercase">MJ PROCESS > ESTOQUE</div>
            <h1 class="text-subtitle-1 font-weight-black lh-1" :class="textPrimaryClass">
              Controle de Materiais
            </h1>
          </div>
        </div>

        <div class="d-flex align-center gap-3">
             <div class="d-none d-sm-flex align-center px-3 py-1 rounded-pill border"
                  :class="isLightMode ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-surface-light border-white-05'">
                <div class="d-flex align-center mr-3">
                   <div class="status-dot bg-success mr-2 blink"></div>
                   <span class="text-[10px] font-weight-bold text-uppercase opacity-80">Online</span>
                </div>
                <div class="text-[10px] font-mono opacity-60 border-l pl-3" :class="isLightMode ? 'border-grey-lighten-3' : 'border-white-10'">
                   {{ currentTime }}
                </div>
             </div>

             <v-btn icon="mdi-refresh" density="comfortable" variant="tonal" size="small"
                    :color="isLightMode ? 'grey-darken-3' : 'white'"
                    @click="fetchStock" :loading="loading" class="rounded-lg">
                <v-tooltip activator="parent" location="bottom">Atualizar</v-tooltip>
             </v-btn>
        </div>
      </div>

      <div class="flex-grow-1 overflow-y-auto pa-6 custom-scrollbar">

        <div class="d-flex flex-column flex-sm-row align-center justify-space-between mb-6 gap-4">
            <v-tabs v-model="currentTab" density="compact" color="primary"
                    class="rounded-lg border overflow-hidden"
                    :class="isLightMode ? 'bg-white border-grey-lighten-2' : 'bg-surface-light border-white-05'"
                    hide-slider selected-class="bg-primary-opacity-10 text-primary">
                <v-tab value="pronta-entrega" class="text-caption font-weight-bold px-4 letter-spacing-1">Pronta Entrega</v-tab>
                <v-tab value="producao" class="text-caption font-weight-bold px-4 letter-spacing-1">Produção</v-tab>
            </v-tabs>

            <v-text-field
                v-model="search"
                density="compact"
                variant="outlined"
                placeholder="Buscar tecido..."
                prepend-inner-icon="mdi-magnify"
                hide-details
                class="search-field w-100 w-sm-auto compact-input"
                style="min-width: 300px;"
                :bg-color="isLightMode ? 'white' : undefined"
            ></v-text-field>
        </div>

        <div v-if="loading" class="d-flex justify-center py-20">
            <v-progress-circular indeterminate color="primary" size="48" width="4"></v-progress-circular>
        </div>

        <v-window v-else v-model="currentTab" class="w-100">
            <v-window-item v-for="tab in ['pronta-entrega', 'producao']" :key="tab" :value="tab">

                <div v-if="getItemsByTab(tab).length === 0" class="text-center py-12 opacity-50 border border-dashed rounded-xl" :class="isLightMode ? 'border-grey-lighten-2' : 'border-white-10'">
                    <v-icon size="40" color="grey">mdi-package-variant-closed</v-icon>
                    <div class="text-caption mt-2">Nenhum item encontrado nesta categoria.</div>
                </div>

                <div v-else class="stock-grid animate-fade-in-up pb-16">
                    <v-card v-for="item in getItemsByTab(tab)" :key="item.id"
                            class="stock-card d-flex flex-column cursor-pointer group hover-elevate transition-all"
                            :class="[ isLightMode ? 'light-card' : 'dark-card', getStockStatus(item).borderClass ]"
                            elevation="0" v-ripple @click="openHistoryModal(item)">

                        <div class="pa-4 d-flex flex-column h-100">
                            <div class="d-flex justify-space-between align-start mb-2">
                                <v-chip size="x-small" :color="getStockStatus(item).color" variant="flat" label class="font-weight-bold text-uppercase px-2" style="height: 20px;">
                                    {{ getStockStatus(item).text }}
                                </v-chip>
                                <div class="text-right">
                                    <div class="text-h5 font-weight-black lh-1 tabular-nums" :class="getStockStatus(item).textClass">
                                        {{ formatNumber(item.available_meters) }}
                                    </div>
                                    <div class="text-[10px] font-weight-bold text-uppercase opacity-60 text-right">{{ item.unit_of_measure === 'kg' ? 'kg' : 'metros' }}</div>
                                </div>
                            </div>

                            <h3 class="text-subtitle-2 font-weight-bold mb-1 text-truncate" :class="textPrimaryClass" :title="item.fabric_type">
                                {{ item.fabric_type }}
                            </h3>

                            <v-divider class="my-3 border-dashed" :class="isLightMode ? 'border-grey-lighten-2' : 'border-white-10'"></v-divider>

                            <div class="d-flex justify-space-between align-end mt-auto">
                                <div class="d-flex flex-column gap-1">
                                    <div class="d-flex align-center text-[10px] opacity-70">
                                        <v-icon size="10" class="mr-1">mdi-tape-measure</v-icon> Méd: {{ item.meters_per_roll || '-' }} / Rolo
                                    </div>
                                    <div class="d-flex align-center text-[10px] opacity-70">
                                        <v-icon size="10" class="mr-1">mdi-barcode</v-icon> NCM: {{ item.ncm || '54075100' }}
                                    </div>
                                </div>
                                <div class="icon-circle-small" :class="isLightMode ? 'bg-grey-lighten-4 text-primary' : 'bg-white-05 text-white'">
                                    <v-icon size="14">mdi-history</v-icon>
                                </div>
                            </div>
                        </div>
                    </v-card>
                </div>
            </v-window-item>
        </v-window>
      </div>
    </div>

    <v-dialog v-model="showHistoryModal" max-width="1200px" height="85vh" scrollable transition="dialog-bottom-transition" content-class="glass-modal-content">
      <v-card class="d-flex flex-row overflow-hidden rounded-xl h-100" :class="isLightMode ? 'bg-white' : 'bg-surface-modal'">

        <div class="sidebar d-none d-md-flex flex-column pa-5 border-r flex-shrink-0"
             :class="isLightMode ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-surface-sidebar border-white-05'" style="width: 280px;">

             <div class="mb-6">
                <div class="text-[10px] font-weight-bold text-uppercase opacity-50 mb-2">Item Selecionado</div>
                <h3 class="text-subtitle-1 font-weight-black lh-1.2 mb-4" :class="textPrimaryClass">{{ selectedStockItem?.fabric_type }}</h3>

                <div class="kpi-box pa-4 rounded-lg border text-center mb-4" :class="isLightMode ? 'bg-white border-grey-lighten-2 shadow-sm' : 'bg-surface-light border-white-05'">
                    <div class="text-[10px] text-uppercase opacity-60 mb-1 font-weight-bold">Saldo Atual</div>
                    <div class="text-h4 font-weight-black lh-1" :class="getStockStatus(selectedStockItem!).textClass">
                        {{ formatNumber(selectedStockItem?.available_meters || 0) }}
                        <span class="text-caption text-medium-emphasis">{{ selectedStockItem?.unit_of_measure }}</span>
                    </div>
                </div>

                <div class="d-flex flex-column gap-2 text-caption">
                    <div class="d-flex justify-space-between border-b pb-2" :class="isLightMode ? 'border-grey-lighten-3' : 'border-white-05'">
                        <span class="opacity-60">Média/Rolo</span> <span class="font-weight-bold">{{ selectedStockItem?.meters_per_roll || '-' }}</span>
                    </div>
                    <div class="d-flex justify-space-between border-b pb-2" :class="isLightMode ? 'border-grey-lighten-3' : 'border-white-05'">
                        <span class="opacity-60">NCM</span> <span class="font-weight-bold font-mono">{{ selectedStockItem?.ncm || '54075100' }}</span>
                    </div>
                    <div class="d-flex justify-space-between border-b pb-2" :class="isLightMode ? 'border-grey-lighten-3' : 'border-white-05'">
                        <span class="opacity-60">Mínimo</span> <span class="font-weight-bold text-warning">{{ selectedStockItem?.low_stock_threshold || '-' }}</span>
                    </div>
                    <div class="d-flex justify-space-between pt-1">
                        <span class="opacity-60">Categoria</span>
                        <v-chip size="x-small" :color="selectedStockItem?.is_ready_delivery ? 'purple' : 'blue'" variant="flat" density="comfortable" class="font-weight-bold h-auto py-0 px-2 text-[9px]">
                            {{ selectedStockItem?.is_ready_delivery ? 'PRONTA ENTREGA' : 'PRODUÇÃO' }}
                        </v-chip>
                    </div>
                </div>
             </div>

             <div class="mt-auto">
                 <v-btn block variant="tonal" color="primary" size="small" @click="fetchStockMovements" :loading="loadingHistory" prepend-icon="mdi-refresh">
                     Atualizar Dados
                 </v-btn>
             </div>
        </div>

        <div class="d-flex flex-column flex-grow-1 h-100" :class="isLightMode ? 'bg-white' : 'bg-surface-body'">

            <div class="px-5 py-3 border-b d-flex flex-wrap align-center justify-space-between gap-3 flex-shrink-0"
                 :class="isLightMode ? 'border-grey-lighten-2' : 'border-white-05'">

                <div class="d-flex align-center gap-3 flex-grow-1">
                    <v-chip-group v-model="dateFilter" selected-class="bg-primary text-white" mandatory density="compact" class="compact-chips">
                        <v-chip value="today" size="x-small" variant="outlined" filter class="font-weight-bold">Hoje</v-chip>
                        <v-chip value="7d" size="x-small" variant="outlined" filter class="font-weight-bold">7 Dias</v-chip>
                        <v-chip value="30d" size="x-small" variant="outlined" filter class="font-weight-bold">Mês</v-chip>
                        <v-chip value="custom" size="x-small" variant="outlined" filter class="font-weight-bold">Outro</v-chip>
                    </v-chip-group>

                    <div v-if="dateFilter === 'custom'" class="d-flex align-center gap-2 ml-2 transition-all">
                        <input type="date" v-model="customStartDate" class="native-date-input" :class="{ 'light': isLightMode }">
                        <span class="text-[10px] opacity-50">até</span>
                        <input type="date" v-model="customEndDate" class="native-date-input" :class="{ 'light': isLightMode }">
                        <v-btn icon="mdi-magnify" size="x-small" color="primary" variant="flat" density="compact" @click="fetchStockMovements"></v-btn>
                    </div>
                </div>

                <div class="d-flex align-center gap-2">
                    <v-switch
                        v-model="groupOrders"
                        color="primary"
                        label="Agrupar por Pedido"
                        hide-details
                        density="compact"
                        class="mr-2 text-caption font-weight-bold scale-90"
                        inset
                    ></v-switch>

                    <v-menu location="bottom end">
                        <template v-slot:activator="{ props }">
                            <v-btn v-bind="props" variant="tonal" color="secondary" size="small" prepend-icon="mdi-export" class="text-none">Exportar</v-btn>
                        </template>
                        <v-list density="compact" nav :class="isLightMode ? 'bg-white' : 'bg-surface-dark'">
                            <v-list-item prepend-icon="mdi-file-pdf-box" title="Relatório PDF" @click="generateAuditPdf"></v-list-item>
                            <v-list-item prepend-icon="mdi-microsoft-excel" title="Planilha Excel" @click="exportHistoryExcel"></v-list-item>
                        </v-list>
                    </v-menu>
                    <v-btn icon="mdi-close" variant="text" size="small" @click="showHistoryModal = false"></v-btn>
                </div>
            </div>

            <div class="px-5 pt-3 pb-2 flex-shrink-0 d-flex align-center gap-4 bg-opacity-05" :class="isLightMode ? 'bg-grey-lighten-5' : ''">
                <v-tabs v-model="historyTab" density="compact" color="primary" align-tabs="start" height="32" class="rounded overflow-hidden">
                    <v-tab value="all" class="text-caption font-weight-bold px-3">Todos</v-tab>
                    <v-tab value="in" class="text-caption font-weight-bold px-3 text-success">Entradas</v-tab>
                    <v-tab value="out" class="text-caption font-weight-bold px-3 text-error">Saídas</v-tab>
                </v-tabs>
                <v-text-field v-model="historySearch" density="compact" variant="outlined" placeholder="Filtrar por pedido, cliente..."
                              prepend-inner-icon="mdi-magnify" hide-details class="compact-input flex-grow-1"
                              :bg-color="isLightMode ? 'white' : 'rgba(0,0,0,0.2)'"></v-text-field>
            </div>

            <div class="flex-grow-1 overflow-y-auto custom-scrollbar px-5 pb-5 pt-3">
                <div v-if="loadingHistory" class="d-flex justify-center py-8">
                    <v-progress-circular indeterminate color="primary" size="32"></v-progress-circular>
                </div>

                <div v-else-if="processedTimelineItems.length === 0" class="text-center py-12 opacity-50">
                    <div class="text-caption">Nenhum registro encontrado no período selecionado.</div>
                </div>

                <div v-else class="timeline-feed">
                    <div v-for="item in processedTimelineItems" :key="item.id"
                         class="feed-item d-flex align-center py-3 border-b transition-hover"
                         :class="isLightMode ? 'border-grey-lighten-2 hover:bg-grey-lighten-5' : 'border-white-05 hover:bg-white-05'">

                        <div class="d-flex flex-column align-center mr-4 text-center" style="min-width: 60px;">
                            <span class="text-caption font-weight-bold lh-1" :class="textPrimaryClass">{{ item.dateDisplay }}</span>
                            <span class="text-[10px] opacity-50 font-mono">{{ item.timeDisplay }}</span>
                        </div>

                        <div class="type-indicator mr-4 rounded-circle d-flex align-center justify-center border"
                             :class="[
                                item.isEntry ? 'bg-green-lighten-5 text-green border-green-lighten-4' : 'bg-red-lighten-5 text-red border-red-lighten-4',
                                isLightMode ? '' : 'bg-opacity-20'
                             ]"
                             style="width: 36px; height: 36px;">
                            <v-icon size="18">{{ item.icon }}</v-icon>
                        </div>

                        <div class="flex-grow-1 min-w-0 mr-4">
                            <div class="d-flex align-center gap-2 mb-1">
                                <v-chip size="x-small" :color="item.isEntry ? 'success' : 'error'" variant="tonal" label class="font-weight-black text-uppercase h-auto py-0 px-1 text-[10px]">
                                    {{ item.type_display }}
                                </v-chip>
                                <v-chip v-if="item.order_number" size="x-small" color="primary" variant="flat" label class="font-mono h-auto py-0 px-1 text-[10px]">
                                    #{{ String(item.order_number).padStart(4, '0') }}
                                </v-chip>
                                <v-chip v-if="groupOrders && item.count > 1" size="x-small" color="info" variant="tonal" label class="h-auto py-0 px-1 text-[9px]">
                                    Agrupado ({{ item.count }})
                                </v-chip>
                            </div>
                            <div class="text-body-2 font-weight-bold text-truncate" :class="textPrimaryClass" :title="item.title">
                                {{ item.title }}
                            </div>
                            <div class="d-flex align-center gap-3 mt-1 text-[11px] opacity-70">
                                <span v-if="item.user" class="d-flex align-center"><v-icon size="10" class="mr-1">mdi-account</v-icon> {{ item.user }}</span>
                            </div>
                        </div>

                        <div class="text-right" style="min-width: 120px;">
                            <div class="text-subtitle-2 font-weight-black font-mono lh-1 mb-1" :class="item.isEntry ? 'text-success' : 'text-error'">
                                {{ item.isEntry ? '+' : '' }}{{ formatNumber(item.quantity_moved) }}
                            </div>
                            <div class="text-[10px] font-mono d-flex justify-end align-center gap-1 bg-opacity-10 rounded px-2 py-0.5"
                                 :class="isLightMode ? 'bg-grey-lighten-4' : 'bg-white-05'">
                                <span class="opacity-60">{{ formatNumber(item.old_quantity) }}</span>
                                <v-icon size="10" class="text-grey">mdi-arrow-right</v-icon>
                                <span :class="textPrimaryClass" class="font-weight-bold">{{ formatNumber(item.new_quantity) }}</span>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

        </div>
      </v-card>
    </v-dialog>

  </v-container>
</template>

<script setup lang="ts">
import { ref, onMounted, computed, onUnmounted, watch } from 'vue';
import { supabase } from '@/api/supabase';
import { useThemeStore } from '@/stores/theme';
import { format, parseISO, startOfDay, endOfDay, subDays } from 'date-fns';
import { ptBR } from 'date-fns/locale';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import * as XLSX from 'xlsx';

// Types (Atualizado com NCM)
type StockItem = {
  id: string; fabric_type: string; available_meters: number; meters_per_roll: number | null;
  unit_of_measure: 'metro' | 'kg'; low_stock_threshold: number | null; is_ready_delivery: boolean;
  ncm?: string;
};

// Store
const themeStore = useThemeStore();
const isLightMode = computed(() => themeStore.currentMode === 'light');

// Main State
const loading = ref(true);
const search = ref('');
const stockItems = ref<StockItem[]>([]);
const currentTab = ref('pronta-entrega');
const currentTime = ref('');
const currentDate = ref('');
const lastSyncTime = ref('');
let timer: any = null;

// Modal State
const showHistoryModal = ref(false);
const loadingHistory = ref(false);
const selectedStockItem = ref<StockItem | null>(null);
const rawHistory = ref<any[]>([]);
const historySearch = ref('');
const historyTab = ref('all');
const groupOrders = ref(true);
const dateFilter = ref('7d');
const customStartDate = ref(format(new Date(), 'yyyy-MM-dd'));
const customEndDate = ref(format(new Date(), 'yyyy-MM-dd'));
const isGeneratingAuditPdf = ref(false);

// Styles
const textPrimaryClass = computed(() => isLightMode.value ? 'text-grey-darken-4' : 'text-white');

// --- MAIN LIST LOGIC ---
const getItemsByTab = (tab: string) => {
    const q = search.value.toLowerCase();
    const isReady = tab === 'pronta-entrega';
    return stockItems.value.filter(i =>
        i.is_ready_delivery === isReady &&
        (!q || i.fabric_type.toLowerCase().includes(q))
    ).sort((a, b) => a.fabric_type.localeCompare(b.fabric_type));
};

const getStockStatus = (item: StockItem) => {
  if (item.available_meters <= 0) return { text: 'Esgotado', color: 'error', icon: 'mdi-close-octagon', textClass: 'text-error', borderClass: 'border-l-error' };
  if (item.low_stock_threshold && item.available_meters < item.low_stock_threshold) return { text: 'Baixo', color: 'warning', icon: 'mdi-alert', textClass: 'text-warning', borderClass: 'border-l-warning' };
  return { text: 'Normal', color: 'success', icon: 'mdi-check-circle', textClass: isLightMode.value ? 'text-grey-darken-4' : 'text-white', borderClass: 'border-l-success' };
};

// --- AUDIT LOGIC ---
const auditDates = computed(() => {
    const today = new Date();
    switch (dateFilter.value) {
        case 'today': return [startOfDay(today), endOfDay(today)];
        case '7d': return [subDays(today, 7), endOfDay(today)];
        case '30d': return [subDays(today, 30), endOfDay(today)];
        case 'custom': return [startOfDay(parseISO(customStartDate.value)), endOfDay(parseISO(customEndDate.value))];
        default: return [startOfDay(today), endOfDay(today)];
    }
});

watch(dateFilter, () => { if(dateFilter.value !== 'custom') fetchStockMovements(); });

// ** CORE PROCESSING **
const processedTimelineItems = computed(() => {
    if (!selectedStockItem.value || rawHistory.value.length === 0) return [];

    let processed = [...rawHistory.value];

    if (historyTab.value === 'in') processed = processed.filter(i => (i.quantity_moved || 0) > 0);
    if (historyTab.value === 'out') processed = processed.filter(i => (i.quantity_moved || 0) < 0);

    if (historySearch.value) {
        const q = historySearch.value.toLowerCase();
        processed = processed.filter(i =>
            (i.order_number && String(i.order_number).includes(q)) ||
            (i.customer_name && i.customer_name.toLowerCase().includes(q)) ||
            (i.full_name && i.full_name.toLowerCase().includes(q))
        );
    }

    let currentBalance = selectedStockItem.value.available_meters;

    const historyWithBalance = rawHistory.value.sort((a,b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime()).map(item => {
        const qty = item.quantity_moved || 0;
        const balAfter = currentBalance;
        const balBefore = currentBalance - qty;
        currentBalance = balBefore;
        return { ...item, old_quantity: balBefore, new_quantity: balAfter, isEntry: qty > 0 };
    });

    let displayItems = historyWithBalance.filter(i => processed.some(p => p.id === i.id));

    if (groupOrders.value) {
        const groupedMap = new Map();
        displayItems.forEach(item => {
            const key = item.order_number
                ? `${item.order_number}_${item.created_at.split('T')[0]}`
                : item.id;

            if (!groupedMap.has(key)) {
                groupedMap.set(key, { ...item, count: 1, aggregatedQty: item.quantity_moved });
            } else {
                const existing = groupedMap.get(key);
                existing.aggregatedQty += item.quantity_moved;
                existing.count++;
                existing.old_quantity = item.old_quantity;
            }
        });

        displayItems = Array.from(groupedMap.values()).map(i => ({
            ...i,
            quantity_moved: i.aggregatedQty,
            isEntry: i.aggregatedQty > 0,
        }));
    }

    return displayItems.map(item => {
        let title = 'Ajuste Manual';
        let type_display = 'Ajuste';
        let icon = 'mdi-swap-horizontal';

        if (item.movement_type === 'saida_pedido' || item.order_number) {
            title = item.customer_name || 'Cliente';
            type_display = 'Venda';
            icon = 'mdi-arrow-top-right';
        } else if (item.movement_type === 'entrada_manual' || item.quantity_moved > 0) {
            title = 'Entrada de Estoque';
            type_display = 'Entrada';
            icon = 'mdi-arrow-bottom-left';
        } else if (item.movement_type === 'saida_manual') {
            title = 'Baixa Manual / Perda';
            type_display = 'Baixa';
            icon = 'mdi-arrow-top-right';
        }

        return {
            ...item, title, type_display, icon,
            dateDisplay: format(parseISO(item.created_at), "dd/MM/yy"),
            timeDisplay: format(parseISO(item.created_at), "HH:mm"),
            user: item.full_name || 'Sistema',
        };
    });
});

// --- DATA FETCHING ---
const fetchStock = async () => {
  loading.value = true;
  try {
    const { data, error } = await supabase.from('stock').select('*').eq('verification', true);
    if (error) throw error;
    stockItems.value = data || [];
    lastSyncTime.value = format(new Date(), 'HH:mm');
  } catch (e) { console.error(e); } finally { loading.value = false; }
};

const openHistoryModal = (item: StockItem) => {
    selectedStockItem.value = item;
    showHistoryModal.value = true;
    dateFilter.value = '7d';
    fetchStockMovements();
};

const fetchStockMovements = async () => {
    if (!selectedStockItem.value) return;
    loadingHistory.value = true;
    try {
        const [start, end] = auditDates.value;
        const { data, error } = await supabase.rpc('get_stock_movements_report', {
            start_date: start.toISOString(),
            end_date: end.toISOString()
        });

        if (error) throw error;
        const fabricData = (data || []).filter((i: any) => i.fabric_type === selectedStockItem.value!.fabric_type);

        rawHistory.value = fabricData.map((i: any) => ({
            id: i.id,
            created_at: i.created_at,
            movement_type: i.movement_type,
            quantity_moved: i.quantity_moved,
            order_number: i.order_number,
            customer_name: i.customer_name,
            full_name: i.full_name
        }));

    } catch (e) { console.error(e); } finally { loadingHistory.value = false; }
};

// --- PDF GENERATION ---
const imageToBase64 = (url: string): Promise<string> => new Promise((resolve, reject) => {
  const img = new Image();
  img.crossOrigin = 'Anonymous';
  img.onload = () => {
     const c = document.createElement('canvas');
     c.width = img.width; c.height = img.height;
     const ctx = c.getContext('2d');
     if(ctx){ ctx.drawImage(img,0,0); resolve(c.toDataURL('image/png')); }
     else reject('Canvas error');
  };
  img.onerror = () => reject('Image load error');
  img.src = url;
});

const generateAuditPdf = async () => {
    if (!processedTimelineItems.value.length) return;
    isGeneratingAuditPdf.value = true;
    try {
        const doc = new jsPDF();
        const item = selectedStockItem.value!;
        const pageWidth = doc.internal.pageSize.width;

        try {
            const logo = await imageToBase64('https://cdn.shopify.com/s/files/1/0661/4574/6991/files/Sem_nome_1080_x_800_px_1080_x_500_px_1080_x_400_px_1000_x_380_px_da020cf2-2bb9-4dac-8dd3-4548cfd2e5ae.png?v=1756811713');
            const logoProps = doc.getImageProperties(logo);
            const logoWidth = 50;
            const logoHeight = (logoProps.height * logoWidth) / logoProps.width;
            doc.addImage(logo, 'PNG', 15, 10, logoWidth, logoHeight);
        } catch (err) { console.warn("Logo load failed", err); }

        doc.setFontSize(9).setTextColor(100);
        doc.text([
          "MR JACKY - CONTROLE DE ESTOQUE",
          "RUA LUIZ MONTANHAN, 1302 TIRO DE GUERRA - TIETE - SP",
          "Relatório de Auditoria e Rastreabilidade"
        ], pageWidth - 15, 15, { align: 'right' });

        doc.setDrawColor(220); doc.setLineWidth(0.5);
        doc.line(15, 35, pageWidth - 15, 35);

        doc.setFontSize(14).setFont('helvetica', 'bold').setTextColor(0);
        doc.text(`Histórico: ${item.fabric_type}`, 15, 45);

        doc.setFontSize(10).setFont('helvetica', 'normal').setTextColor(100);
        const [start, end] = auditDates.value;
        doc.text(`Período: ${format(start, 'dd/MM/yy')} à ${format(end, 'dd/MM/yy')} | Saldo Atual: ${formatNumber(item.available_meters)}`, 15, 51);

        const body = processedTimelineItems.value.map(i => [
            `${i.dateDisplay} ${i.timeDisplay}`,
            i.type_display,
            i.order_number ? `#${i.order_number}` : '-',
            i.title,
            i.user,
            i.old_quantity.toFixed(2),
            i.quantity_moved.toFixed(2),
            i.new_quantity.toFixed(2)
        ]);

        autoTable(doc, {
            head: [['Data/Hora', 'Tipo', 'Pedido', 'Cliente/Detalhe', 'Usuário', 'Saldo Ant.', 'Mov.', 'Saldo Final']],
            body, startY: 58,
            theme: 'striped',
            headStyles: { fillColor: [44, 62, 80], textColor: 255, fontSize: 8 },
            styles: { fontSize: 8, cellPadding: 2 },
            columnStyles: {
                5: { halign: 'right', textColor: 100 },
                6: { halign: 'right', fontStyle: 'bold' },
                7: { halign: 'right', fontStyle: 'bold', textColor: 50 }
            },
            didDrawCell: (d) => {
                if (d.section === 'body' && d.column.index === 6) {
                    const v = parseFloat(d.cell.text[0]);
                    doc.setTextColor(v > 0 ? [0, 150, 0] : [200, 0, 0]);
                }
            }
        });

        const totalPages = (doc as any).internal.getNumberOfPages();
        const pageHeight = doc.internal.pageSize.height;
        for (let i = 1; i <= totalPages; i++) {
            doc.setPage(i);
            doc.setFontSize(8).setTextColor(150);
            doc.text(`Gerado em ${format(new Date(), 'dd/MM/yyyy HH:mm')} - MJProcess`, pageWidth / 2, pageHeight - 10, { align: 'center' });
        }

        doc.save(`Auditoria_${item.fabric_type.replace(/[^a-z0-9]/gi, '_')}.pdf`);
    } catch (e: any) {
        console.error("Erro ao gerar PDF:", e);
        alert(`Erro ao gerar PDF: ${e.message}`);
    } finally {
        isGeneratingAuditPdf.value = false;
    }
};

const exportHistoryExcel = () => {
    const data = processedTimelineItems.value.map(i => ({
        'Data': `${i.dateDisplay} ${i.timeDisplay}`,
        'Tipo': i.type_display,
        'Pedido': i.order_number || '-',
        'Cliente': i.title,
        'Usuário': i.user,
        'Saldo Anterior': i.old_quantity,
        'Movimentação': i.quantity_moved,
        'Saldo Final': i.new_quantity
    }));
    const ws = XLSX.utils.json_to_sheet(data);
    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, "Auditoria");
    XLSX.writeFile(wb, "Auditoria_Estoque.xlsx");
};

// Utils
const updateClock = () => { const now = new Date(); currentTime.value = format(now, 'HH:mm:ss'); currentDate.value = format(now, 'EEE, d MMM yyyy', { locale: ptBR }); };
const formatNumber = (v: number) => Number(v || 0).toLocaleString('pt-BR', { minimumFractionDigits: 1, maximumFractionDigits: 2 });

onMounted(() => { fetchStock(); updateClock(); timer = setInterval(updateClock, 1000); });
onUnmounted(() => clearInterval(timer));
</script>

<style scoped lang="scss">
/* --- BASE --- */
.bg-background-app { background-color: transparent; }
.bg-header-dark { background-color: #1e1e24; }
.bg-surface-modal { background-color: #121212; }
.bg-surface-sidebar { background-color: #18181b; }
.bg-surface-body { background-color: #121212; }
.bg-surface-light { background-color: #F8F9FA; }
.bg-surface-card { background: rgba(255,255,255,0.03); }
.border-white-05 { border-color: rgba(255,255,255,0.05) !important; }
.border-white-10 { border-color: rgba(255,255,255,0.1) !important; }
.bg-white-05 { background: rgba(255,255,255,0.05); }
.bg-black-20 { background: rgba(0,0,0,0.2); }

/* --- GRID --- */
.stock-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(260px, 1fr)); gap: 24px; }
.stock-card {
    border-radius: 16px; transition: all 0.2s ease; overflow: hidden;
    &.dark-card { background-color: rgba(30, 30, 35, 0.6); border: 1px solid rgba(255, 255, 255, 0.08); box-shadow: 0 4px 6px rgba(0,0,0,0.2); }
    &.dark-card:hover { transform: translateY(-3px); background-color: rgba(40,40,45,0.9); box-shadow: 0 12px 24px rgba(0,0,0,0.4); border-color: rgba(255,255,255,0.15); }

    &.light-card { background-color: #FFFFFF; border: 1px solid #E0E0E0; box-shadow: 0 2px 8px rgba(0,0,0,0.05); }
    &.light-card:hover { transform: translateY(-3px); box-shadow: 0 8px 20px rgba(0,0,0,0.1); border-color: #BDBDBD; }
}

.status-bar { height: 4px; width: 100%; opacity: 0.8; }
.border-l-success { border-left: 4px solid #4CAF50; }
.border-l-warning { border-left: 4px solid #FFC107; }
.border-l-error { border-left: 4px solid #F44336; }

/* --- ICONS --- */
.icon-box-lg { width: 56px; height: 56px; }
.icon-box-sm { width: 36px; height: 36px; }
.icon-circle { width: 36px; height: 36px; border-radius: 50%; display: flex; align-items: center; justify-content: center; }
.icon-circle-small { width: 28px; height: 28px; border-radius: 50%; display: flex; align-items: center; justify-content: center; }
.card-bg-icon { position: absolute; bottom: -10px; right: -10px; font-size: 100px; opacity: 0.03; pointer-events: none; transform: rotate(-15deg); }

.bg-gradient-primary { background: linear-gradient(135deg, #1976d2, #0d47a1); }
.shadow-soft { box-shadow: 0 2px 6px rgba(0,0,0,0.05); }
.glass-panel { background: rgba(30, 30, 35, 0.6); backdrop-filter: blur(20px); border: 1px solid rgba(255, 255, 255, 0.08); box-shadow: 0 4px 12px rgba(0,0,0,0.2); }
.glass-modal-content { border-radius: 16px; overflow: hidden; box-shadow: 0 25px 50px -12px rgba(0,0,0,0.5); }

/* --- INPUTS --- */
.compact-input :deep(.v-field__input) { min-height: 32px; padding-top: 0; padding-bottom: 0; font-size: 0.85rem; }
.native-date-input {
    background: rgba(255,255,255,0.05); border: 1px solid rgba(255,255,255,0.1); color: white;
    padding: 4px 8px; border-radius: 6px; font-size: 0.75rem; font-family: inherit; outline: none;
    &.light { background: #fff; border: 1px solid #ccc; color: #333; }
}

/* --- UTILS --- */
.lh-1 { line-height: 1.1; }
.lh-1\.2 { line-height: 1.2; }
.tabular-nums { font-variant-numeric: tabular-nums; }
.scale-90 { transform: scale(0.9); transform-origin: right; }
.gap-4 { gap: 16px; } .ga-3 { gap: 12px; }
.blink { animation: blink 2s infinite; }
@keyframes blink { 0%, 100% { opacity: 1; } 50% { opacity: 0.4; } }
.custom-scrollbar::-webkit-scrollbar { width: 6px; }
.custom-scrollbar::-webkit-scrollbar-track { background: transparent; }
.custom-scrollbar::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.3); border-radius: 3px; }
</style>
