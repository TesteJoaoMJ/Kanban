<template>
  <div
    class="producao-dashboard-wrapper font-sans fill-height d-flex flex-column relative overflow-x-hidden"
    :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 text-grey-darken-4' : 'bg-glass-dark text-white'"
  >
    <div v-if="themeStore.currentMode !== 'light'" class="background-carousel-wrapper">
      <div class="background-overlay"></div>
    </div>

    <div class="content-wrapper d-flex flex-column flex-grow-1 z-10 relative custom-scroll overflow-y-auto">

      <div
        class="header-bar px-6 py-4 d-flex align-center justify-space-between flex-shrink-0 flex-wrap gap-2"
        :class="themeStore.currentMode === 'light' ? 'bg-white border-b border-grey-lighten-2 shadow-sm' : 'bg-glass-header border-bottom-white-05'"
      >
        <div class="d-flex flex-column mb-2 mb-sm-0">
          <div class="breadcrumb text-caption d-flex align-center">
            <v-icon size="14" class="mr-1 opacity-70">mdi-factory</v-icon>
            <span class="opacity-70">Industrial</span>
            <span class="mx-2 opacity-50">></span>
            <span class="font-weight-bold">Dashboard</span>
          </div>
          <div class="text-h5 font-weight-black tracking-tight leading-none mt-1 text-uppercase" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">
            Visão Geral Produção
          </div>
        </div>

        <div class="d-flex align-center flex-wrap gap-3">
          <div class="text-caption font-weight-bold opacity-70 border rounded-0 px-3 py-1 bg-white-05" :class="themeStore.currentMode === 'light' ? 'border-grey-lighten-2 bg-grey-lighten-4' : 'border-white-10'">
            <v-icon size="14" class="mr-1">mdi-calendar-clock</v-icon>
            Últimos 7 Dias
          </div>

          <v-btn
            color="indigo-darken-3"
            variant="flat"
            class="btn-rect px-4 font-weight-bold text-caption text-uppercase shadow-sm"
            prepend-icon="mdi-view-week"
            height="40"
            :to="{ name: 'ProductionKanban' }"
          >
            Abrir Kanban
          </v-btn>

          <v-btn
            variant="outlined"
            class="btn-rect font-weight-bold"
            height="40"
            :color="themeStore.currentMode === 'light' ? 'grey-darken-3' : 'white'"
            icon="mdi-refresh"
            @click="fetchDashboardData"
            :loading="loading"
          >
          </v-btn>
        </div>
      </div>

      <div class="pa-6 d-flex flex-column gap-6">

        <v-row dense class="mx-n2">
          <v-col cols="12" sm="6" md="4" lg="auto" class="px-2 pb-2 flex-grow-1" v-for="(kpi, idx) in kpiList" :key="idx">
            <v-card
              class="kpi-card kpi-rect hover-elevate py-3 px-4 position-relative transition-all elevation-2 opacity-90 h-100"
              :class="[kpi.gradient, kpi.action ? 'cursor-pointer' : '']"
              style="min-height: 110px;"
              @click="handleKpiClick(kpi)"
              v-ripple="!!kpi.action"
            >
              <div class="kpi-bg-icon"><v-icon>{{ kpi.icon }}</v-icon></div>
              <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                <div class="d-flex align-center justify-space-between text-white mb-1">
                  <div class="d-flex align-center text-truncate gap-1">
                      <v-icon size="16" class="opacity-80">{{ kpi.icon }}</v-icon>
                      <span class="kpi-label text-truncate">{{ kpi.title }}</span>
                  </div>
                  <v-icon v-if="kpi.action" size="14" class="opacity-60">mdi-open-in-new</v-icon>
                </div>
                <div class="kpi-number-group my-1 text-white">
                  <span class="text-caption font-weight-bold mr-1 opacity-70" v-if="kpi.prefix">{{ kpi.prefix }}</span>
                  <span class="kpi-value text-h4 font-weight-black leading-none">{{ kpi.value }}<span class="text-caption ml-1">{{ kpi.suffix }}</span></span>
                </div>
                <div class="kpi-footer mt-1 text-truncate text-white opacity-90 text-[11px] font-weight-bold">
                  {{ kpi.subtitle }}
                </div>
              </div>
            </v-card>
          </v-col>
        </v-row>

        <v-row dense class="mx-n2">
          <v-col cols="12" lg="8" class="px-2 pb-2">
             <v-card class="dashboard-card border-thin rounded-0 fill-height shadow-sm" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'glass-card'">
                <div class="px-6 py-4 border-b d-flex justify-space-between align-center" :class="themeStore.currentMode === 'light' ? 'border-grey-lighten-3' : 'border-white-10'">
                   <div>
                     <h3 class="text-subtitle-1 font-weight-black text-uppercase tracking-tight mb-0">Evolução de Produção</h3>
                     <span class="text-caption opacity-70">Metragem concluída nos últimos 7 dias</span>
                   </div>
                   <v-chip size="small" color="indigo" variant="tonal" class="font-weight-bold px-3 rounded-0">
                      Total Semanal: {{ formatNumber(weeklyTotalMeters) }}m
                   </v-chip>
                </div>
                <div class="pa-4 relative" style="height: 320px;">
                   <div v-if="loading" class="absolute-fill d-flex align-center justify-center bg-overlay z-10">
                      <v-progress-circular indeterminate color="indigo"></v-progress-circular>
                   </div>
                   <apexchart type="area" height="100%" :options="chartOptions" :series="chartSeries"></apexchart>
                </div>
             </v-card>
          </v-col>

          <v-col cols="12" lg="4" class="px-2 pb-2">
             <v-card class="dashboard-card border-thin rounded-0 fill-height shadow-sm d-flex flex-column" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'glass-card'">
                <div class="px-6 py-4 border-b flex-shrink-0" :class="themeStore.currentMode === 'light' ? 'border-grey-lighten-3' : 'border-white-10'">
                   <h3 class="text-subtitle-1 font-weight-black text-uppercase tracking-tight mb-0">Consumo de Tecido</h3>
                   <span class="text-caption opacity-70">Top 5 Materiais mais rodados na semana</span>
                </div>

                <div class="pa-6 flex-grow-1 overflow-y-auto custom-scroll relative">
                    <div v-if="loading" class="absolute-fill d-flex align-center justify-center bg-overlay z-10">
                      <v-progress-circular indeterminate color="indigo"></v-progress-circular>
                    </div>

                    <div v-if="fabricConsumption.length === 0 && !loading" class="h-100 d-flex flex-column align-center justify-center opacity-50">
                        <v-icon size="48" class="mb-2">mdi-texture</v-icon>
                        <span class="text-caption font-weight-bold text-uppercase">Sem dados de consumo</span>
                    </div>

                    <div class="d-flex flex-column gap-5 h-100 justify-center">
                        <div v-for="(item, idx) in fabricConsumption" :key="item.name" class="w-100">
                            <div class="d-flex justify-space-between align-end mb-1">
                                <span class="font-weight-black text-caption text-uppercase text-truncate mr-2" style="max-width: 70%;">
                                  {{ idx + 1 }}. {{ item.name || 'NÃO ESPECIFICADO' }}
                                </span>
                                <span class="font-weight-bold font-mono text-[13px]" :style="{ color: item.color }">{{ formatNumber(item.meters) }}m</span>
                            </div>
                            <v-progress-linear
                              :model-value="(item.meters / maxFabricMeters) * 100"
                              :color="item.color"
                              height="8"
                              rounded="0"
                              class="shadow-sm"
                            ></v-progress-linear>
                        </div>
                    </div>
                </div>
             </v-card>
          </v-col>
        </v-row>

        <v-row dense class="mx-n2">
          <v-col cols="12" class="px-2 pb-2">
             <v-card class="dashboard-card border-thin rounded-0 shadow-sm d-flex flex-column overflow-hidden" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'glass-card'">
                <div class="px-6 py-4 border-b flex-shrink-0 d-flex justify-space-between align-center" :class="themeStore.currentMode === 'light' ? 'border-grey-lighten-3' : 'border-white-10'">
                   <div>
                     <h3 class="text-subtitle-1 font-weight-black text-uppercase tracking-tight mb-0">Painel Operacional em Tempo Real</h3>
                     <span class="text-caption opacity-70">Todos os itens atualmente ativos na fila de PCP</span>
                   </div>
                   <v-chip size="small" color="success" variant="flat" class="font-weight-bold px-3 shadow-sm rounded-0">
                      <v-icon start size="14">mdi-cog-sync</v-icon> {{ activeProductionItems.length }} ITENS ATIVOS
                   </v-chip>
                </div>

                <div class="flex-grow-1 overflow-x-auto relative" style="min-height: 300px;">
                    <div v-if="loading" class="absolute-fill d-flex align-center justify-center bg-overlay z-10">
                      <v-progress-circular indeterminate color="indigo"></v-progress-circular>
                    </div>

                    <div class="grid-scroll w-100 h-100 d-flex flex-column">
                        <div class="grid-header sticky-head border-b grid-dashboard" :class="themeStore.currentMode === 'light' ? 'grid-surface-light' : 'grid-surface-dark'">
                            <div class="cell center header-text border-r">Arte</div>
                            <div class="cell header-text border-r">Referência</div>
                            <div class="cell header-text border-r">Cliente</div>
                            <div class="cell center header-text border-r">Pedido</div>
                            <div class="cell header-text border-r">Tecido</div>
                            <div class="cell center header-text border-r">Qtd (m)</div>
                            <div class="cell center header-text">Status Atual</div>
                        </div>

                        <div v-if="paginatedActiveItems.length === 0 && !loading" class="d-flex flex-column justify-center align-center py-10 opacity-60 w-100">
                            <v-icon size="48" class="mb-2">mdi-check-all</v-icon>
                            <span class="font-weight-bold">Nenhum item processando nas máquinas neste momento.</span>
                        </div>

                        <div v-for="(item, index) in paginatedActiveItems" :key="item.id" class="grid-row border-b grid-dashboard" :class="zebraClass(index)">

                            <div class="cell center border-r pa-1">
                                <div class="d-flex align-center justify-center rounded border-thin transition-all hover-scale"
                                     style="width: 34px; height: 34px;"
                                     :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-grey-darken-3'"
                                     @click="item.stamp_image_url ? openImage(item) : null"
                                     :style="item.stamp_image_url ? 'cursor: pointer;' : ''"
                                     :title="item.stamp_image_url ? 'Clique para ampliar a arte' : 'Sem arte anexada'">
                                     <v-icon size="20" :color="item.stamp_image_url ? 'indigo-darken-1' : 'grey-lighten-1'">
                                         {{ item.stamp_image_url ? 'mdi-image-search-outline' : 'mdi-image-off-outline' }}
                                     </v-icon>
                                </div>
                            </div>

                            <div class="cell border-r">
                                <span class="font-weight-black text-uppercase text-[13px] tracking-tight text-truncate w-100" :title="item.stamp_ref">{{ item.stamp_ref || 'SEM REFERÊNCIA' }}</span>
                            </div>

                            <div class="cell border-r">
                                <span class="font-weight-bold text-[13px] text-truncate w-100" :title="item.order?.customer_name || item.customer_name">
                                    {{ item.order?.customer_name || item.customer_name || 'Desconhecido' }}
                                </span>
                            </div>

                            <div class="cell center border-r">
                                <span class="font-weight-black font-mono text-[12px] opacity-80 px-2 py-1 rounded-sm"
                                      :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-3 text-grey-darken-4' : 'bg-grey-darken-3 text-grey-lighten-2'">
                                      #{{ item.order?.order_number || item.order_number || '-' }}
                                </span>
                            </div>

                            <div class="cell border-r">
                                <span class="text-[12px] opacity-90 font-weight-medium text-uppercase text-truncate w-100" :title="item.fabric_type">{{ item.fabric_type || '-' }}</span>
                            </div>

                            <div class="cell center border-r">
                                <span class="font-mono font-weight-black text-[14px]">{{ formatNumber(item.quantity_meters) }}m</span>
                            </div>

                            <div class="cell center">
                                <v-chip size="x-small" :color="getStatusConfig(item.status).color" variant="tonal" class="font-weight-black text-uppercase px-3 rounded-0 w-100 justify-center" style="max-width: 120px;">
                                    {{ getStatusConfig(item.status).label }}
                                </v-chip>
                            </div>
                        </div>
                    </div>
                    </div>

                <div class="px-6 py-2 border-t d-flex justify-space-between align-center" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 border-grey-lighten-3' : 'bg-white-05 border-white-10'">
                    <span class="text-caption font-weight-bold opacity-70">
                        Mostrando {{ paginatedActiveItems.length }} de {{ activeProductionItems.length }} registros
                    </span>
                    <v-pagination
                        v-if="activeItemsPageCount > 1"
                        v-model="activeItemsPage"
                        :length="activeItemsPageCount"
                        density="compact"
                        :total-visible="6"
                        active-color="indigo"
                        variant="tonal"
                        size="small"
                    ></v-pagination>
                </div>
             </v-card>
          </v-col>
        </v-row>

      </div>
    </div>

    <v-dialog v-model="showOperatorsModal" max-width="900" scrollable>
        <v-card class="rounded-0 border-thin shadow-2xl" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-4' : 'bg-glass-dark'">
            <div class="px-6 py-4 bg-indigo-darken-4 text-white d-flex justify-space-between align-center flex-shrink-0">
                <div class="d-flex align-center gap-3">
                    <v-icon size="28">mdi-account-hard-hat</v-icon>
                    <div class="d-flex flex-column">
                        <span class="text-subtitle-1 font-weight-black text-uppercase leading-none">Operadores em Atividade</span>
                        <span class="text-[10px] opacity-80">Calandras rodando neste exato momento</span>
                    </div>
                </div>
                <v-btn icon="mdi-close" variant="text" density="compact" @click="showOperatorsModal = false"></v-btn>
            </div>

            <v-card-text class="pa-6" style="max-height: 70vh;">
                <div v-if="activeOperatorsList.length === 0" class="text-center py-10 opacity-50">
                    <v-icon size="64" class="mb-4">mdi-power-plug-off</v-icon>
                    <div class="text-h6 font-weight-black text-uppercase">Nenhuma Calandra Operando</div>
                    <div class="text-caption font-weight-bold">A aba de produção está vazia.</div>
                </div>

                <v-row v-else dense>
                    <v-col cols="12" md="6" v-for="op in activeOperatorsList" :key="op.id">
                        <v-card class="rounded-0 border-thin shadow-sm position-relative pa-5 h-100 transition-all hover-border-indigo"
                                :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-white-05 border-white-10'">

                            <div class="position-absolute" style="top: 20px; right: 20px;">
                                <v-avatar size="46" color="indigo-lighten-5" class="border text-indigo-darken-4 elevation-1">
                                    <v-icon size="24">mdi-account-cog</v-icon>
                                </v-avatar>
                            </div>

                            <div class="text-[11px] font-weight-black text-indigo mb-1 text-uppercase tracking-tight">
                                <v-icon size="12" class="mr-1">mdi-robot-industrial</v-icon> {{ op.machine }}
                            </div>
                            <div class="text-h6 font-weight-black leading-none mb-4 text-uppercase pr-12 text-truncate" :title="op.operator">
                                {{ op.operator }}
                            </div>

                            <v-divider class="my-3 opacity-20"></v-divider>

                            <div class="d-flex flex-column gap-2">
                                <div class="d-flex align-center gap-2 text-caption">
                                    <v-icon size="16" class="opacity-70" color="orange">mdi-texture</v-icon>
                                    <span class="font-weight-bold text-uppercase">{{ op.fabric }}</span>
                                    <span class="ml-auto font-mono font-weight-black text-[12px] bg-grey-lighten-3 px-2 rounded" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-grey-darken-3'">{{ op.meters }}m</span>
                                </div>
                                <div class="d-flex align-center gap-2 text-caption">
                                    <v-icon size="16" class="opacity-70" color="cyan">mdi-tag-multiple</v-icon>
                                    <span class="opacity-90 text-uppercase font-weight-bold text-truncate" style="max-width: 200px;">{{ op.ref }}</span>
                                </div>
                                <div class="d-flex align-center gap-2 text-caption">
                                    <v-icon size="16" class="opacity-70" color="green">mdi-clock-start</v-icon>
                                    <span class="opacity-90">Início: <span class="font-mono font-weight-bold">{{ op.startedAt }}</span></span>
                                </div>
                            </div>
                        </v-card>
                    </v-col>
                </v-row>
            </v-card-text>
        </v-card>
    </v-dialog>

    <ImageModal
        :show="imageModal.show"
        :image-url="imageModal.url"
        :file-name="imageModal.name"
        @close="imageModal.show = false"
    />
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted } from 'vue';
import { supabase } from '@/api/supabase';
import { useThemeStore } from '@/stores/theme';
import { useAppStore } from '@/stores/app';
import { format, subDays, isToday, parseISO, eachDayOfInterval } from 'date-fns';
import { ptBR } from 'date-fns/locale';
import ImageModal from '@/components/ImageModal.vue';

const themeStore = useThemeStore();
const appStore = useAppStore();
const loading = ref(true);

const showOperatorsModal = ref(false);

// Configs da Paginação Front-end
const activeItemsPage = ref(1);
const activeItemsPerPage = 50;

// Configuração do Modal de Imagem
const imageModal = reactive({
    show: false,
    url: '',
    name: ''
});

const openImage = (item: any) => {
    if (!item.stamp_image_url) return;
    imageModal.url = item.stamp_image_url;
    imageModal.name = item.stamp_ref || 'Estampa';
    imageModal.show = true;
};

// Data States
const allRecentItems = ref<any[]>([]);
const weeklyTotalMeters = ref(0);
const todayMeters = ref(0);

// Helper de formatação de datas
const formatDateFull = (iso?: string | null) => {
    if (!iso) return '-';
    const d = parseISO(iso);
    return format(d, 'dd/MM/yyyy HH:mm', { locale: ptBR });
};

// Helper de classes da Grid nativa
const zebraClass = (i:number) => (themeStore.currentMode==='light' ? (i%2===0 ? 'zebra-light-a':'zebra-light-b') : (i%2===0 ? 'zebra-dark-a':'zebra-dark-b'));

// Status Mappings matching ProductionControl.vue
const getStatusConfig = (s: string) => {
    const map:any = {
        design_pending:{color:'grey',label:'Design'},
        customer_approval:{color:'amber',label:'Aprovação'},
        design_released:{color:'cyan',label:'Liberado PCP'},
        waiting_print:{color:'indigo',label:'Fila Impressão'},
        printing:{color:'blue',label:'Imprimindo'},
        printed:{color:'deep-purple',label:'Impresso'},
        waiting_calandra:{color:'orange',label:'Fila Calandra'},
        in_production:{color:'deep-orange',label:'Na Calandra'},
        billing_pending:{color:'blue-grey',label:'Faturamento'},
        waiting_release:{color:'teal',label:'Expedição'},
        completed:{color:'green',label:'Concluído'}
    };
    return map[s] || {color:'grey', label:s};
};

const formatNumber = (v: number) => new Intl.NumberFormat('pt-BR', { maximumFractionDigits: 1 }).format(Number(v) || 0);

// Data Fetching
const fetchDashboardData = async () => {
    loading.value = true;
    try {
        const startDate = subDays(new Date(), 9).toISOString();

        // Status que consideramos "Ativos no PCP"
        const activeStatuses = [
            'design_released', 'waiting_separation', 'in_separation',
            'waiting_print', 'printing',
            'printed', 'waiting_calandra', 'in_calandra', 'in_production'
        ].join(',');

        const { data, error } = await supabase
            .from('order_items')
            .select(`
                id,
                stamp_ref,
                quantity_meters,
                status,
                created_at,
                updated_at,
                fabric_type,
                stamp_image_url,
                order_id,
                details,
                orders (order_number, customer_name)
            `)
            .or(`status.in.(${activeStatuses}),updated_at.gte.${startDate}`);

        if (error) throw error;

        allRecentItems.value = (data || []).map((item: any) => ({
            ...item,
            order: Array.isArray(item.orders) ? item.orders[0] : item.orders
        }));

        calculateKPIs();
        activeItemsPage.value = 1;

    } catch (err) {
        console.error("Erro ao buscar dados do Dashboard de Produção:", err);
        appStore.showSnackbar('Erro ao carregar dados do dashboard.', 'error');
    } finally {
        loading.value = false;
    }
};

const calculateKPIs = () => {
    let weekTotal = 0;
    let todayTotal = 0;

    const producedStatuses = ['billing_pending', 'waiting_release', 'completed', 'ready_for_delivery'];
    const now = new Date();

    allRecentItems.value.forEach(item => {
        if (producedStatuses.includes(item.status)) {
            const updDate = parseISO(item.updated_at);
            if (updDate >= subDays(now, 7)) {
                weekTotal += Number(item.quantity_meters || 0);
            }
            if (isToday(updDate)) {
                todayTotal += Number(item.quantity_meters || 0);
            }
        }
    });

    weeklyTotalMeters.value = weekTotal;
    todayMeters.value = todayTotal;
};

// Action Router
const handleKpiClick = (kpi: any) => {
    if (kpi.action === 'openOperatorsModal') {
        showOperatorsModal.value = true;
    }
};

// Dados do Modal de Operadores (Apenas itens em "in_production")
const activeOperatorsList = computed(() => {
    const inProdItems = allRecentItems.value.filter(i => i.status === 'in_production');

    return inProdItems.map(item => {
        const operator = item.details?.operator || item.operator || 'Operador não identificado';
        const machine = item.details?.machine || item.machine || 'Máquina não informada';

        return {
            id: item.id,
            operator,
            machine,
            fabric: item.fabric_type || 'NÃO ESPECIFICADO',
            ref: item.stamp_ref || 'S/ REF',
            startedAt: formatDateFull(item.updated_at),
            meters: formatNumber(item.quantity_meters)
        }
    }).sort((a, b) => a.machine.localeCompare(b.machine));
});

// Computed KPIs
const kpiList = computed(() => {
    const list = allRecentItems.value;

    // 1. Separação
    const filaSep = list.filter(i => ['design_released', 'waiting_separation', 'in_separation'].includes(i.status));
    const sepMeters = filaSep.reduce((sum, i) => sum + Number(i.quantity_meters || 0), 0);
    const kpi1 = {
        title: 'SEPARAÇÃO',
        prefix: 'METRAGEM:',
        value: formatNumber(sepMeters),
        suffix: 'm',
        subtitle: `${filaSep.length} itens na etapa`,
        icon: 'mdi-basket-outline',
        gradient: 'bg-gradient-cyan'
    };

    // 2. Impressão
    const filaImp = list.filter(i => ['waiting_print', 'printing'].includes(i.status));
    const impMeters = filaImp.reduce((sum, i) => sum + Number(i.quantity_meters || 0), 0);
    const kpi2 = {
        title: 'IMPRESSÃO',
        prefix: 'METRAGEM:',
        value: formatNumber(impMeters),
        suffix: 'm',
        subtitle: `${filaImp.length} itens na etapa`,
        icon: 'mdi-printer-3d-nozzle',
        gradient: 'bg-gradient-warning'
    };

    // 3. Calandra
    const filaCal = list.filter(i => ['printed', 'waiting_calandra'].includes(i.status));
    const calMeters = filaCal.reduce((sum, i) => sum + Number(i.quantity_meters || 0), 0);
    const kpi3 = {
        title: 'FILA CALANDRA',
        prefix: 'METRAGEM:',
        value: formatNumber(calMeters),
        suffix: 'm',
        subtitle: `${filaCal.length} itens aguardando`,
        icon: 'mdi-fire',
        gradient: 'bg-gradient-orange'
    };

    // 4. Operadores Ativos
    const inProdCount = activeOperatorsList.value.length;
    const kpi4 = {
        title: 'EM OPERAÇÃO',
        prefix: 'MÁQUINAS:',
        value: inProdCount,
        suffix: 'ativas',
        subtitle: 'Clique para ver operadores',
        icon: 'mdi-account-hard-hat',
        gradient: 'bg-gradient-blue',
        action: 'openOperatorsModal'
    };

    // 5. Produzido Hoje
    const kpi5 = {
        title: 'PRODUZIDO HOJE',
        prefix: 'METRAGEM:',
        value: formatNumber(todayMeters.value),
        suffix: 'm',
        subtitle: `Na semana: ${formatNumber(weeklyTotalMeters.value)}m`,
        icon: 'mdi-check-decagram',
        gradient: 'bg-gradient-green'
    };

    return [kpi1, kpi2, kpi3, kpi4, kpi5];
});

// Lógica da Paginação da Tabela de Produção
const activeProductionItems = computed(() => {
    const activeStatuses = [
        'design_released', 'waiting_separation', 'in_separation',
        'waiting_print', 'printing',
        'printed', 'waiting_calandra', 'in_calandra', 'in_production'
    ];
    return allRecentItems.value
        .filter(i => activeStatuses.includes(i.status))
        .sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime());
});

const paginatedActiveItems = computed(() => {
    const start = (activeItemsPage.value - 1) * activeItemsPerPage;
    return activeProductionItems.value.slice(start, start + activeItemsPerPage);
});

const activeItemsPageCount = computed(() => {
    return Math.ceil(activeProductionItems.value.length / activeItemsPerPage);
});

// Fabric Consumption Calculation
const fabricConsumption = computed(() => {
    const consumption: Record<string, number> = {};
    const producedStatuses = ['billing_pending', 'waiting_release', 'completed', 'ready_for_delivery', 'in_production', 'printing'];
    const now = new Date();

    allRecentItems.value.forEach(order => {
        if (producedStatuses.includes(order.status)) {
             const updDate = parseISO(order.updated_at);
             if (updDate >= subDays(now, 7)) {
                const fabric = order.fabric_type ? order.fabric_type.toUpperCase() : 'NÃO ESPECIFICADO';
                consumption[fabric] = (consumption[fabric] || 0) + Number(order.quantity_meters || 0);
             }
        }
    });

    const colors = ['#00BCD4', '#FF9800', '#4CAF50', '#E91E63', '#9C27B0'];
    return Object.entries(consumption)
        .map(([name, meters], index) => ({
            name,
            meters,
            color: colors[index % colors.length]
        }))
        .sort((a, b) => b.meters - a.meters)
        .slice(0, 5);
});

const maxFabricMeters = computed(() => {
    if (fabricConsumption.value.length === 0) return 1;
    return Math.max(...fabricConsumption.value.map(f => f.meters));
});

// --- CHART LOGIC ---
const chartSeries = computed(() => {
    const dataByDay: Record<string, number> = {};
    const producedStatuses = ['billing_pending', 'waiting_release', 'completed', 'ready_for_delivery'];

    const end = new Date();
    const start = subDays(end, 6);
    const daysInterval = eachDayOfInterval({ start, end });

    daysInterval.forEach(date => {
        const dateStr = format(date, 'yyyy-MM-dd');
        dataByDay[dateStr] = 0;
    });

    allRecentItems.value.forEach(item => {
         if (producedStatuses.includes(item.status)) {
             const updDate = parseISO(item.updated_at);
             if (updDate >= start) {
                 const dateStr = format(updDate, 'yyyy-MM-dd');
                 if (dataByDay[dateStr] !== undefined) {
                     dataByDay[dateStr] += Number(item.quantity_meters || 0);
                 }
             }
         }
    });

    const dataArray = Object.keys(dataByDay).sort().map(key => Number(dataByDay[key].toFixed(1)));

    return [{
        name: 'Metros Produzidos',
        data: dataArray
    }];
});

const chartOptions = computed(() => {
    const isDark = themeStore.currentMode !== 'light';
    const textColor = isDark ? '#B0BEC5' : '#78909C';
    const gridColor = isDark ? 'rgba(255,255,255,0.05)' : 'rgba(0,0,0,0.05)';

    const end = new Date();
    const start = subDays(end, 6);
    const daysInterval = eachDayOfInterval({ start, end });
    const categories = daysInterval.map(date => format(date, 'dd/MM', { locale: ptBR }));

    return {
        chart: {
            type: 'area',
            fontFamily: 'inherit',
            toolbar: { show: false },
            zoom: { enabled: false },
            background: 'transparent'
        },
        colors: ['#3F51B5'],
        fill: {
            type: 'gradient',
            gradient: {
                shadeIntensity: 1,
                opacityFrom: 0.4,
                opacityTo: 0.05,
                stops: [0, 90, 100]
            }
        },
        dataLabels: { enabled: false },
        stroke: { curve: 'smooth', width: 3 },
        xaxis: {
            categories: categories,
            labels: { style: { colors: textColor, fontSize: '11px', fontWeight: 600 } },
            axisBorder: { show: false },
            axisTicks: { show: false },
            crosshairs: { show: false }
        },
        yaxis: {
            labels: {
                style: { colors: textColor, fontSize: '11px', fontWeight: 600 },
                formatter: (value: number) => `${formatNumber(value)}m`
            },
        },
        grid: {
            borderColor: gridColor,
            strokeDashArray: 4,
            xaxis: { lines: { show: true } },
            yaxis: { lines: { show: true } },
            padding: { top: 0, right: 0, bottom: 0, left: 10 }
        },
        tooltip: {
            theme: isDark ? 'dark' : 'light',
            y: { formatter: (val: number) => `${formatNumber(val)} metros` }
        },
        legend: { show: false }
    };
});

onMounted(() => {
    fetchDashboardData();
});
</script>

<style scoped lang="scss">
/* Wrapper and Layout */
.producao-dashboard-wrapper { position: absolute; top: 0; left: 0; right: 0; bottom: 0; }
.background-carousel-wrapper { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 0; opacity: 0.4; pointer-events: none; }
.background-overlay { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 1; background: radial-gradient(circle at center, rgba(15, 15, 19, 0.6), rgba(15, 15, 19, 0.98)); backdrop-filter: blur(8px); }

/* Glassmorphism Styles */
.bg-glass-dark { background: rgba(10,10,12,0.9); }
.bg-glass-header { background: rgba(20,20,24,0.7); backdrop-filter: blur(14px); -webkit-backdrop-filter: blur(14px); }
.glass-card { background: rgba(255, 255, 255, 0.03); backdrop-filter: blur(10px); -webkit-backdrop-filter: blur(10px); border-color: rgba(255,255,255,0.08) !important; }
.shadow-glass { box-shadow: 0 8px 32px 0 rgba(0, 0, 0, 0.3) !important; }
.bg-overlay { background: rgba(255,255,255,0.8); }
.bg-glass-dark .bg-overlay { background: rgba(15,15,19,0.8); }

/* Utils */
.absolute-fill { position: absolute; top: 0; left: 0; right: 0; bottom: 0; }
.z-10 { position: relative; z-index: 10; }
.border-white-05 { border-color: rgba(255,255,255,0.05) !important; }
.border-white-10 { border-color: rgba(255,255,255,0.1) !important; }
.bg-white-05 { background-color: rgba(255,255,255,0.05) !important; }
.tracking-tight { letter-spacing: -0.5px !important; }
.leading-none { line-height: 1; }
.max-w-200 { max-width: 200px; display: inline-block; }
.cursor-pointer { cursor: pointer; }

/* Scrollbars */
.custom-scroll::-webkit-scrollbar { width: 8px; height: 8px; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.3); border-radius: 4px; }
.custom-scroll::-webkit-scrollbar-track { background: transparent; }

/* Buttons */
.btn-rect { border-radius: 0 !important; text-transform: none !important; }

/* KPIs */
.kpi-card { border: 1px solid rgba(0,0,0,0.08); transition: all 0.2s ease; border-radius: 0 !important; }
.bg-gradient-blue { background: linear-gradient(135deg, #1976D2, #0D47A1); color:white; }
.bg-gradient-cyan { background: linear-gradient(135deg, #00BCD4, #00838F); color:white; }
.bg-gradient-warning { background: linear-gradient(135deg, #FFC107, #FF8F00); color:white; }
.bg-gradient-orange { background: linear-gradient(135deg, #FF9800, #EF6C00); color:white; }
.bg-gradient-green { background: linear-gradient(135deg, #4CAF50, #2E7D32); color:white; }
.kpi-bg-icon { position: absolute; right: -10px; bottom: -10px; opacity: 0.2; transform: rotate(-15deg); }
.kpi-bg-icon .v-icon { font-size: 60px; }
.hover-elevate:hover { transform: translateY(-3px); box-shadow: 0 12px 24px -8px rgba(0,0,0,0.15) !important; }

/* CSS Grid Nativo - Idêntico ao ProductionControl mas com as colunas separadas */
.grid-scroll { scrollbar-gutter: stable; -webkit-overflow-scrolling: touch; }
.grid-header, .grid-row { display: grid; align-items: stretch; width: 100%; min-width: 1000px; }
/* COLUNAS: Arte (50px), Ref (140px+), Cliente (180px+), OP (100px), Tecido (220px+), Qtd (100px), Status (140px) */
.grid-dashboard { grid-template-columns: 50px minmax(140px, 1fr) minmax(180px, 1.5fr) 100px minmax(220px, 2fr) 100px 140px; }

.cell { padding: 0 12px; display: flex; align-items: center; border-right: 1px solid rgba(0,0,0,0.08); height: 50px; overflow: hidden; }
.grid-header .cell { min-height: 40px; height: 40px; font-size: 11px; font-weight: 900; text-transform: uppercase; opacity: 0.9; }
.center { justify-content: center; text-align: center; }

/* Themes & Zebrado para o CSS Grid */
.grid-surface-light { background: #f9fafb; color: rgba(0,0,0,0.7); }
.grid-surface-dark { background: rgba(255,255,255,0.08); color: rgba(255,255,255,0.8); }
.zebra-light-a { background: #ffffff; }
.zebra-light-b { background: #fdfdfd; }
.zebra-dark-a { background: rgba(255,255,255,0.03); }
.zebra-dark-b { background: rgba(255,255,255,0.06); }
.grid-row:hover { background-color: rgba(128,128,128,0.1) !important; }

.hover-border-indigo:hover { border-color: #3F51B5 !important; }
.bg-glass-dark .bg-opacity-20 { background-color: rgba(0,0,0,0.2) !important; }
.hover-scale { transition: transform 0.2s; }
.hover-scale:hover { transform: scale(1.15); box-shadow: 0 2px 8px rgba(0,0,0,0.2); border-color: #5C6BC0 !important; }
</style>
