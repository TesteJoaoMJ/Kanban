<template>
  <div
    class="designer-layout font-sans fill-height d-flex flex-column relative overflow-hidden"
    :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 text-grey-darken-4' : 'bg-glass-dark text-white'"
  >
    <div
      class="header-bar px-6 py-4 d-flex align-center justify-space-between flex-shrink-0"
      :class="themeStore.currentMode === 'light' ? 'bg-white border-b border-grey-lighten-2 shadow-sm' : 'bg-glass-header border-bottom-white-05'"
    >
      <div class="d-flex flex-column">
        <div class="breadcrumb text-caption">
          <span class="opacity-70">MJ Process</span>
          <span class="mx-2 opacity-50">></span>
          <span class="font-weight-bold">Controle de Design & Liberação</span>
        </div>
        <div class="text-h6 font-weight-black tracking-tight leading-none mt-1" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">
          Painel do Designer
        </div>
      </div>

      <div class="d-flex align-center" style="gap: 10px;">
        <v-btn
          color="secondary"
          variant="tonal"
          class="btn-rect px-4 font-weight-bold text-caption text-uppercase letter-spacing-1"
          prepend-icon="mdi-file-pdf-box"
          height="40"
          @click="generatePDFReport"
          :loading="generatingPdf"
        >
          Relatório Detalhado
        </v-btn>

        <v-btn
          color="primary"
          variant="flat"
          class="btn-rect px-4 font-weight-bold text-caption text-uppercase letter-spacing-1"
          prepend-icon="mdi-view-dashboard-variant"
          height="40"
          :to="{ name: 'DesignKanban' }"
        >
          Kanban Visual
        </v-btn>

        <v-btn
          variant="outlined"
          class="btn-rect"
          height="40"
          prepend-icon="mdi-refresh"
          :color="themeStore.currentMode === 'light' ? 'grey-darken-2' : 'white'"
          @click="fetchData"
          :loading="loading"
        >
          Atualizar
        </v-btn>
      </div>
    </div>

    <div class="px-6 pt-4 pb-2 flex-shrink-0">
      <v-row dense>
        <v-col cols="12" sm="6" md="" v-for="(kpi, idx) in kpiList" :key="idx">
          <v-card class="kpi-card kpi-rect bg-gradient-custom hover-elevate py-3 px-4" :class="kpi.gradient" v-ripple elevation="2">
            <div class="kpi-bg-icon"><v-icon>{{ kpi.icon }}</v-icon></div>
            <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
              <div class="d-flex align-center" style="gap: 8px;">
                <v-icon size="18" class="opacity-80">{{ kpi.icon }}</v-icon>
                <span class="kpi-label">{{ kpi.label }}</span>
              </div>
              <div class="kpi-number-group my-1">
                <span class="kpi-value">{{ kpi.value }}</span>
                <span class="text-caption font-weight-medium ml-1 opacity-70">{{ kpi.unit || '' }}</span>
              </div>
              <div class="kpi-footer mt-1">{{ kpi.footer }}</div>
            </div>
          </v-card>
        </v-col>
      </v-row>
    </div>

    <div class="px-6 py-2 flex-shrink-0">
      <div
        class="controls-bar d-flex align-center justify-space-between"
        :class="themeStore.currentMode === 'light' ? 'controls-light' : 'controls-dark'"
      >
        <div class="d-flex align-center flex-wrap w-100" style="gap: 10px;">

          <div class="d-flex" style="gap: 0;">
              <v-btn
                  v-for="tab in tabs"
                  :key="tab.value"
                  :variant="activeTab === tab.value ? 'flat' : 'text'"
                  :color="activeTab === tab.value ? tab.color : (themeStore.currentMode === 'light' ? 'grey-darken-2' : 'white')"
                  class="btn-rect"
                  height="40"
                  @click="activeTab = tab.value"
              >
                  <v-icon start size="18">{{ tab.icon }}</v-icon>
                  {{ tab.label }}
                  <v-badge v-if="tab.count > 0" :content="tab.count" :color="tab.color === 'default' ? 'grey' : tab.color" inline class="ml-2 font-weight-bold"></v-badge>
              </v-btn>
          </div>

          <div class="vertical-divider mx-2" style="height: 24px; border-left: 1px solid rgba(128,128,128,0.3);"></div>

          <div style="width: 200px;" v-if="activeTab !== 'release'">
               <v-select
                  v-model="filters.designer"
                  :items="designerList"
                  label="Designer Responsável"
                  variant="outlined"
                  density="compact"
                  hide-details
                  class="filter-select rounded-0"
                  :bg-color="themeStore.currentMode === 'light' ? 'white' : 'transparent'"
              ></v-select>
          </div>

          <div class="search-wrap d-flex align-center flex-grow-1" :class="themeStore.currentMode === 'light' ? 'search-light' : 'search-dark'">
            <v-icon :color="themeStore.currentMode === 'light' ? 'grey-darken-1' : 'white-70'">mdi-magnify</v-icon>
            <input
              v-model="search"
              type="text"
              placeholder="Buscar cliente, referência, pedido..."
              class="clean-input flex-grow-1"
            />
          </div>

           <v-btn
              v-if="hasActiveFilters"
              variant="text"
              class="btn-rect"
              height="40"
              color="error"
              @click="clearFilters"
          >
              Limpar
          </v-btn>
        </div>
      </div>
    </div>

    <div class="flex-grow-1 px-6 pb-2 overflow-hidden d-flex flex-column">
      <v-card
        class="flex-grow-1 d-flex flex-column rounded-0 border-thin overflow-hidden"
        :class="themeStore.currentMode === 'light' ? 'bg-white shadow-sm' : 'glass-card border-white-05'"
        :elevation="0"
      >
        <div class="grid-scroll flex-grow-1 overflow-y-auto custom-scroll">
          <div
            class="grid-header sticky-head"
            :class="themeStore.currentMode === 'light' ? 'grid-surface-light' : 'grid-surface-dark'"
          >
            <div class="cell center header-text" style="width: 70px;">Ped.</div>
            <div class="cell center header-text" style="width: 140px;">Status Atual</div>
            <div class="cell center header-text" style="width: 110px;">Prioridade</div>
            <div class="cell header-text flex-grow-1">Cliente / Detalhes</div>
            <div class="cell header-text" style="width: 200px;">Item / Referência</div>
            <div class="cell header-text" style="width: 140px;">Tecido</div>
            <div class="cell header-text" style="width: 150px;">{{ activeTab === 'release' ? 'Vendedor' : 'Designer' }}</div>
            <div class="cell center header-text" style="width: 120px;">Atualização</div>
            <div class="cell center header-text" style="width: 120px;">Dias no Fluxo</div>
            <div class="cell center header-text" style="width: 80px;">Ação</div>
          </div>

          <div v-if="loading" class="d-flex flex-column justify-center align-center h-100 py-10">
            <v-progress-circular indeterminate color="primary" size="32" width="3"></v-progress-circular>
          </div>

          <div v-else-if="paginatedItems.length === 0" class="d-flex flex-column justify-center align-center h-100 opacity-60 gap-2 py-10">
            <v-icon size="48" color="grey-lighten-1">mdi-filter-off</v-icon>
            <span class="text-body-2 font-weight-medium text-grey">Nenhum item nesta lista.</span>
          </div>

          <div
            v-else
            v-for="(item, index) in paginatedItems"
            :key="item.uniqueKey"
            class="grid-row"
            :class="[
              themeStore.currentMode === 'light' ? 'grid-row-light' : 'grid-row-dark',
              getRowPriorityClass(item)
            ]"
          >
            <div class="cell center" style="width: 70px;">
              <span class="pill-ref">#{{ String(item.order_number).padStart(4, '0') }}</span>
            </div>

            <div class="cell center" style="width: 140px;">
              <span class="solid-chip" :class="getStatusChipClass(item.status)">
                {{ getStatusText(item.status) }}
              </span>
            </div>

            <div class="cell center" style="width: 110px;">
               <v-chip
                  v-if="activeTab === 'release' && getDaysInStatus(item) > 3"
                  size="small"
                  color="error"
                  variant="flat"
                  class="font-weight-black text-uppercase animate-pulse"
               >
                  <v-icon start size="14">mdi-fire</v-icon>
                  URGENTE
               </v-chip>
               <v-chip
                  v-else-if="getPriorityLabel(item)"
                  size="x-small"
                  :color="getPriorityColor(item)"
                  variant="flat"
                  class="font-weight-black text-uppercase"
               >
                  {{ getPriorityLabel(item) }}
               </v-chip>
               <span v-else class="text-caption opacity-50">-</span>
            </div>

            <div class="cell flex-grow-1">
              <div class="d-flex flex-column" style="overflow: hidden;">
                  <div class="text-truncate list-text-11 font-weight-bold" :title="item.customer_name">
                  {{ item.customer_name }}
                  </div>
                  <div class="text-truncate list-text-10 opacity-70">
                      Entrada: {{ formatDateSimple(item.created_at) }}
                  </div>
              </div>
            </div>

            <div class="cell" style="width: 200px;">
               <span class="text-truncate list-text-11 font-weight-bold text-primary">{{ item.stamp_ref || 'Item Avulso' }}</span>
            </div>

            <div class="cell" style="width: 140px;">
               <span class="text-truncate list-text-10 opacity-80">{{ item.fabric_type || '-' }}</span>
            </div>

            <div class="cell" style="width: 150px;">
               <div class="d-flex align-center">
                  <v-icon size="14" class="mr-1 opacity-50">{{ activeTab === 'release' ? 'mdi-account-tie' : 'mdi-account-brush-outline' }}</v-icon>
                  <span class="text-truncate list-text-10 font-weight-medium">{{ activeTab === 'release' ? item.creator_name : item.designer_name }}</span>
               </div>
            </div>

            <div class="cell center" style="width: 120px;">
              <span class="list-text-11 font-mono">{{ formatDateSimple(item.updated_at || item.created_at) }}</span>
            </div>

            <div class="cell center" style="width: 120px;">
              <div class="d-flex flex-column align-center">
                  <span
                      class="list-text-11 font-weight-black"
                      :class="getDaysInStatus(item) > 3 ? 'text-error' : 'text-success'"
                  >
                      {{ getDaysInStatus(item) }} dias
                  </span>
                  <span class="list-text-9 opacity-60">nesta etapa</span>
              </div>
            </div>

            <div class="cell center" style="width: 80px;">
              <v-btn
                  icon
                  size="small"
                  class="action-btn"
                  :class="activeTab === 'release' ? 'bg-deep-orange-darken-3' : 'bg-blue-grey'"
                  @click="navigateToItem(item)"
                  :title="activeTab === 'release' ? 'Ir para Liberação' : 'Abrir no Kanban'"
                  variant="flat"
              >
                  <v-icon size="16" color="white">{{ activeTab === 'release' ? 'mdi-arrow-right-bold' : 'mdi-open-in-new' }}</v-icon>
              </v-btn>
            </div>
          </div>
        </div>

        <div class="flex-shrink-0 border-t px-4 py-2 d-flex align-center justify-space-between" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5' : 'bg-white-05'">
          <div class="text-caption opacity-80">
            Mostrando <strong>{{ paginatedItems.length }}</strong> de <strong>{{ filteredItems.length }}</strong> itens
          </div>
          <v-pagination
            v-model="page"
            :length="pageCount"
            :total-visible="5"
            density="compact"
            active-color="primary"
            variant="tonal"
            size="small"
          ></v-pagination>
        </div>
      </v-card>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, reactive } from 'vue';
import { useRouter } from 'vue-router';
import { useDashboardStore } from '@/stores/dashboard';
import { useUserStore } from '@/stores/user';
import { useThemeStore } from '@/stores/theme';
import { storeToRefs } from 'pinia';
import { format, differenceInCalendarDays, parseISO, addDays, getDay, isSameDay } from 'date-fns';
import { ptBR } from 'date-fns/locale';
import { supabase } from '@/api/supabase';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';

// --- STORES ---
const dashboardStore = useDashboardStore();
const userStore = useUserStore();
const themeStore = useThemeStore();
const router = useRouter();
const { orders: allOrders } = storeToRefs(dashboardStore);

// --- THEME ---
const isLight = computed(() => themeStore.currentMode === 'light');

// --- STATE ---
const loading = ref(false);
const generatingPdf = ref(false);
const search = ref('');
const page = ref(1);
const itemsPerPage = 30;
const activeTab = ref('changes');
const designerList = ref(['Todos']);
const flatDesignItems = ref<any[]>([]); // Itens de Design
const releaseItems = ref<any[]>([]);   // Itens de Liberação

const filters = reactive({
    designer: 'Todos',
});

// --- DATA PROCESSING ---
const processData = async () => {
    loading.value = true;

    // 1. Mapear Usuários
    const { data: profiles } = await supabase.from('profiles').select('id, full_name');
    const profileMap = new Map();
    const designersSet = new Set<string>();
    if (profiles) profiles.forEach(p => profileMap.set(p.id, p.full_name));

    // 2. PROCESSAR ITENS DE DESIGN (Alteração, Finalização, Aprovações)
    const dItems: any[] = [];

    // Statuses relevantes para o fluxo de Design
    const designStatuses = [
        'changes_requested',
        'finalizing',
        'customer_approval',
        'approved_by_designer',
        'approved_by_seller',
        'design_pending'
    ];

    allOrders.value.forEach(order => {
        const designerName = order.designer_id ? profileMap.get(order.designer_id) : 'Não Atribuído';
        if (designerName !== 'Não Atribuído') designersSet.add(designerName);

        const processItem = (item: any, isOrderItem: boolean) => {
            let virtualStatus = item.status;

            // Refinamento de status baseado em tags se estiver pendente
            if (item.status === 'design_pending') {
                if (item.design_tag === 'Alteração') virtualStatus = 'changes_requested';
                else if (item.design_tag === 'Finalização') virtualStatus = 'finalizing';
                else if (item.design_tag === 'Aprovado') virtualStatus = 'customer_approval';
                else return;
            }

            if (['changes_requested', 'finalizing', 'customer_approval', 'approved_by_designer', 'approved_by_seller'].includes(virtualStatus)) {
                dItems.push({
                    uniqueKey: isOrderItem ? `item-${item.id}` : `order-${item.id}`,
                    id: item.id,
                    order_id: isOrderItem ? item.order_id : item.id,
                    order_number: isOrderItem ? order.order_number : item.order_number,
                    customer_name: order.customer_name || 'Consumidor',
                    stamp_ref: isOrderItem ? item.stamp_ref : (item.details?.stamp_ref || 'Item Padrão'),
                    fabric_type: isOrderItem ? item.fabric_type : item.details?.fabric_type,
                    status: virtualStatus,
                    created_at: item.created_at || new Date().toISOString(),
                    updated_at: item.updated_at || item.created_at,
                    designer_id: order.designer_id,
                    designer_name: designerName,
                    creator_name: order.created_by?.full_name || 'N/A'
                });
            }
        };

        if (order.order_items && order.order_items.length > 0) {
            order.order_items.forEach(subItem => processItem(subItem, true));
        } else if (designStatuses.includes(order.status)) {
            processItem(order, false);
        }
    });

    flatDesignItems.value = dItems.sort((a, b) => new Date(a.updated_at).getTime() - new Date(b.updated_at).getTime());
    designerList.value = ['Todos', ...Array.from(designersSet)];

    // 3. BUSCAR ITENS DE LIBERAÇÃO
    const { data: prodData, error: prodError } = await supabase
        .from('order_items')
        .select(`
            id, status, created_at, stamp_ref, fabric_type,
            order:orders (
                id,
                order_number,
                customer_name,
                creator:created_by (full_name)
            )
        `)
        .eq('status', 'production_queue');

    const rItems: any[] = [];
    if (prodError) {
        console.error("Erro ao buscar itens de liberação:", prodError);
    } else if (prodData) {
        prodData.forEach((item: any) => {
            const creatorName = item.order?.creator?.full_name || 'Vendedor';
            rItems.push({
                uniqueKey: `prod-${item.id}`,
                id: item.id,
                order_id: item.order?.id,
                order_number: item.order?.order_number,
                customer_name: item.order?.customer_name,
                stamp_ref: item.stamp_ref,
                fabric_type: item.fabric_type,
                status: 'production_queue',
                created_at: item.created_at,
                // Fallback para updated_at
                updated_at: item.created_at,
                designer_name: 'N/A',
                creator_name: creatorName
            });
        });
    }

    releaseItems.value = rItems.sort((a, b) => new Date(a.updated_at).getTime() - new Date(b.updated_at).getTime());

    const myName = userStore.profile?.full_name;
    if (myName && designersSet.has(myName) && filters.designer === 'Todos') {
        filters.designer = myName;
    }

    loading.value = false;
};

// --- COMPUTED FILTERS & TABS ---
const filteredItems = computed(() => {
    let list: any[] = [];

    if (activeTab.value === 'release') {
        list = releaseItems.value;
    } else {
        list = flatDesignItems.value;
    }

    if (activeTab.value === 'changes') {
        list = list.filter(i => i.status === 'changes_requested');
    } else if (activeTab.value === 'finalizing') {
        list = list.filter(i => i.status === 'finalizing');
    } else if (activeTab.value === 'approval') {
        list = list.filter(i =>
            i.status === 'customer_approval' ||
            i.status === 'approved_by_designer' ||
            i.status === 'approved_by_seller'
        );
    }

    if (activeTab.value !== 'release' && filters.designer !== 'Todos') {
        list = list.filter(i => i.designer_name === filters.designer);
    }

    if (search.value) {
        const s = search.value.toLowerCase();
        list = list.filter(i =>
            String(i.order_number).includes(s) ||
            String(i.customer_name).toLowerCase().includes(s) ||
            String(i.stamp_ref).toLowerCase().includes(s)
        );
    }

    return list;
});

const paginatedItems = computed(() => {
    const start = (page.value - 1) * itemsPerPage;
    return filteredItems.value.slice(start, start + itemsPerPage);
});

const pageCount = computed(() => Math.ceil(filteredItems.value.length / itemsPerPage));
const hasActiveFilters = computed(() => (filters.designer !== 'Todos' && activeTab.value !== 'release') || search.value);

const clearFilters = () => {
    filters.designer = 'Todos';
    search.value = '';
};

// --- KPIS & TABS STATS ---
const stats = computed(() => {
    let baseDesign = flatDesignItems.value;
    if (filters.designer !== 'Todos') {
        baseDesign = baseDesign.filter(i => i.designer_name === filters.designer);
    }

    const changes = baseDesign.filter(i => i.status === 'changes_requested').length;
    const finalizing = baseDesign.filter(i => i.status === 'finalizing').length;
    const approval = baseDesign.filter(i =>
        i.status === 'customer_approval' ||
        i.status === 'approved_by_designer' ||
        i.status === 'approved_by_seller'
    ).length;

    const release = releaseItems.value.length;
    const releaseDelayed = releaseItems.value.filter(i => getDaysInStatus(i) > 3).length;

    return { changes, finalizing, approval, release, releaseDelayed };
});

const kpiList = computed(() => [
    { label: 'Em Alteração', value: stats.value.changes, unit: 'itens', footer: 'Prioridade Alta', icon: 'mdi-alert-circle', gradient: 'bg-gradient-red' },
    { label: 'Finalizando', value: stats.value.finalizing, unit: 'ativos', footer: 'Pré-Impressão', icon: 'mdi-flag-checkered', gradient: 'bg-gradient-purple' },
    { label: 'Aprovações', value: stats.value.approval, unit: 'pendentes', footer: 'Cliente/Vendedor', icon: 'mdi-account-check', gradient: 'bg-gradient-blue' },
    { label: 'P/ Liberação', value: stats.value.release, unit: 'prontos', footer: `${stats.value.releaseDelayed} Atrasados`, icon: 'mdi-rocket-launch', gradient: 'bg-gradient-success' },
]);

const tabs = computed(() => [
    { label: 'Alterações', value: 'changes', icon: 'mdi-alert-circle', color: 'error', count: stats.value.changes },
    { label: 'Finalização', value: 'finalizing', icon: 'mdi-flag-checkered', color: 'purple', count: stats.value.finalizing },
    { label: 'Aprovações', value: 'approval', icon: 'mdi-account-check', color: 'info', count: stats.value.approval },
    { label: 'Liberação', value: 'release', icon: 'mdi-rocket-launch', color: 'success', count: stats.value.release },
]);

// --- NAVIGATION ---
const navigateToItem = (item: any) => {
    if (activeTab.value === 'release') {
        // CORREÇÃO: Usando router.push com name para a rota nomeada 'Liberacao'
        router.push({ name: 'Liberacao' });
    } else {
        router.push({ name: 'DesignKanban' });
    }
};

// --- PDF GENERATION LOGIC ---

// Helper: Calcula data de entrega (4 dias úteis + próximo dia de entrega)
const calculateDeadline = (createdDateStr: string): Date => {
    const start = parseISO(createdDateStr);

    // 1. Adicionar 4 dias úteis
    let businessDaysAdded = 0;
    let current = new Date(start);
    while (businessDaysAdded < 4) {
        current = addDays(current, 1);
        const day = getDay(current);
        if (day !== 0 && day !== 6) { // Ignora Dom (0) e Sab (6) para contagem util
            businessDaysAdded++;
        }
    }

    // 2. Encontrar próximo dia de entrega (Terça=2, Quinta=4, Sábado=6)
    // Se cair em um dia de entrega, mantém. Se não, avança.
    while (true) {
        const d = getDay(current);
        if (d === 2 || d === 4 || d === 6) break;
        current = addDays(current, 1);
    }

    return current;
};

const getStatusColor = (deadline: Date): [number, number, number] => {
    const today = new Date();
    // Zera horas para comparação justa
    today.setHours(0,0,0,0);
    const dLine = new Date(deadline);
    dLine.setHours(0,0,0,0);

    if (dLine < today) return [255, 200, 200]; // Vermelho Pastel (Atrasado)
    if (isSameDay(dLine, today)) return [255, 255, 200]; // Amarelo Pastel (Hoje)
    return [200, 255, 200]; // Verde Pastel (No Prazo)
};

const imageToBase64 = (url: string): Promise<string> => {
    return new Promise((resolve, reject) => {
        const img = new Image();
        img.crossOrigin = 'Anonymous';
        img.onload = () => {
            const canvas = document.createElement('canvas');
            canvas.width = img.width;
            canvas.height = img.height;
            const ctx = canvas.getContext('2d');
            if (ctx) {
                ctx.drawImage(img, 0, 0);
                resolve(canvas.toDataURL('image/png'));
            } else reject();
        };
        img.onerror = reject;
        img.src = url;
    });
};

const generatePDFReport = async () => {
    generatingPdf.value = true;
    try {
        const doc = new jsPDF({ orientation: 'portrait', unit: 'mm', format: 'a4' });
        const pageWidth = doc.internal.pageSize.width;

        // Cabeçalho com Logo
        try {
            const logoUrl = 'https://cdn.shopify.com/s/files/1/0661/4574/6991/files/Sem_nome_1080_x_800_px_1080_x_500_px_1080_x_400_px_1000_x_380_px_da020cf2-2bb9-4dac-8dd3-4548cfd2e5ae.png?v=1756811713';
            const logoBase64 = await imageToBase64(logoUrl);
            doc.addImage(logoBase64, 'PNG', 15, 10, 40, 15);
        } catch (e) { console.warn('Logo error', e); }

        doc.setFontSize(8).setTextColor(100);
        doc.text("MJ Process - Controle de Produção", pageWidth - 15, 15, { align: 'right' });
        doc.text(`Gerado em: ${format(new Date(), "dd/MM/yyyy HH:mm", { locale: ptBR })}`, pageWidth - 15, 20, { align: 'right' });

        // Título do Relatório
        const tabTitle = tabs.value.find(t => t.value === activeTab.value)?.label || 'Geral';
        doc.setFontSize(16).setFont('helvetica', 'bold').setTextColor(0);
        doc.text(`Relatório Detalhado: ${tabTitle}`, 15, 35);

        // KPIs Rápidos
        doc.setFontSize(10).setFont('helvetica', 'normal');
        doc.text(`Total de Itens: ${filteredItems.value.length}`, 15, 42);

        // Tabela
        const tableBody = filteredItems.value.map(item => {
            const deadline = calculateDeadline(item.created_at);
            const statusColor = getStatusColor(deadline);

            return [
                { content: `#${String(item.order_number).padStart(4,'0')}`, styles: { fillColor: statusColor } },
                { content: item.customer_name, styles: { fillColor: statusColor } },
                { content: item.stamp_ref || '-', styles: { fillColor: statusColor } },
                { content: item.fabric_type || '-', styles: { fillColor: statusColor } },
                { content: format(parseISO(item.created_at), 'dd/MM'), styles: { fillColor: statusColor } },
                { content: format(deadline, 'dd/MM'), styles: { fillColor: statusColor } }, // Data Prevista
                { content: activeTab.value === 'release' ? item.creator_name : item.designer_name, styles: { fillColor: statusColor } }
            ];
        });

        autoTable(doc, {
            startY: 50,
            head: [['Ped.', 'Cliente', 'Ref. Estampa', 'Tecido', 'Emissão', 'Entrega', 'Resp.']],
            body: tableBody,
            theme: 'grid',
            headStyles: { fillColor: [41, 128, 185], textColor: 255, fontSize: 8, fontStyle: 'bold' },
            bodyStyles: { fontSize: 7, textColor: 50 },
            columnStyles: {
                0: { cellWidth: 15 },
                1: { cellWidth: 45 },
                2: { cellWidth: 35 },
                3: { cellWidth: 30 },
                4: { cellWidth: 15 },
                5: { cellWidth: 15 },
                6: { cellWidth: 25 }
            }
        });

        // Legenda
        const finalY = (doc as any).lastAutoTable.finalY + 10;
        doc.setFontSize(8).setTextColor(100);
        doc.text("Legenda de Prazos:", 15, finalY);

        doc.setFillColor(200, 255, 200); doc.rect(15, finalY + 2, 4, 4, 'F');
        doc.text("No Prazo", 22, finalY + 5);

        doc.setFillColor(255, 255, 200); doc.rect(40, finalY + 2, 4, 4, 'F');
        doc.text("Entrega Hoje", 47, finalY + 5);

        doc.setFillColor(255, 200, 200); doc.rect(70, finalY + 2, 4, 4, 'F');
        doc.text("Atrasado", 77, finalY + 5);

        doc.save(`Relatorio_${tabTitle}_${format(new Date(), 'yyyy-MM-dd')}.pdf`);

    } catch (err) {
        console.error("Erro ao gerar PDF:", err);
        alert("Erro ao gerar o PDF. Verifique o console.");
    } finally {
        generatingPdf.value = false;
    }
};

// --- HELPERS (DATES & STATUS) ---
const getDaysInStatus = (item: any) => {
    const refDate = item.updated_at || item.created_at;
    if (!refDate) return 0;
    try {
        return differenceInCalendarDays(new Date(), parseISO(refDate));
    } catch { return 0; }
};

const getPriorityLabel = (item: any) => {
    if (activeTab.value !== 'release') return null;
    const days = getDaysInStatus(item);
    if (days > 3) return 'Urgente';
    return 'Normal';
};

const getPriorityColor = (item: any) => {
    const days = getDaysInStatus(item);
    if (days > 3) return 'error';
    return 'grey';
};

const getRowPriorityClass = (item: any) => {
    if (activeTab.value !== 'release') return '';
    const days = getDaysInStatus(item);
    if (days > 3) return isLight.value ? 'bg-red-lighten-5' : 'bg-red-opacity-10';
    return '';
};

const formatDateSimple = (d: string) => {
    if (!d) return '-';
    try { return format(parseISO(d), 'dd/MM/yy'); } catch { return '-'; }
};

const getStatusText = (s: string) => {
    const map: any = {
        'changes_requested': 'Alteração',
        'finalizing': 'Finalizando',
        'customer_approval': 'Aprov. Cliente',
        'approved_by_designer': 'Aprov. Vendedor',
        'approved_by_seller': 'Aprov. Vendedor',
        'production_queue': 'Aguard. Liberação'
    };
    return map[s] || s;
};

const getStatusChipClass = (s: string) => {
    if (s === 'changes_requested') return 'chip-danger';
    if (s === 'finalizing') return 'chip-purple';
    if (s === 'customer_approval') return 'chip-info';
    if (s === 'approved_by_designer' || s === 'approved_by_seller') return 'chip-info';
    if (s === 'production_queue') return 'chip-success';
    return 'chip-default';
};

const fetchData = async () => {
    loading.value = true;
    await dashboardStore.fetchData();
    await processData();
    loading.value = false;
};

// --- LIFECYCLE ---
onMounted(() => {
    fetchData();
});
</script>

<style scoped lang="scss">
/* Manteve-se os estilos originais, adicionando apenas animação de pulso para o badge de fogo */
.designer-layout { position: relative; }
.z-10 { position: relative; z-index: 10; }

.bg-glass-dark { background: rgba(10,10,12,0.95); }
.bg-glass-header { background: rgba(20,20,24,0.65); backdrop-filter: blur(14px); }
.border-bottom-white-05 { border-bottom: 1px solid rgba(255,255,255,0.08); }
.border-thin { border: 1px solid rgba(0,0,0,0.08); }

.btn-rect { border-radius: 0 !important; text-transform: none !important; font-weight: 800; letter-spacing: 0.5px; }
.kpi-rect { border-radius: 0 !important; }

.controls-bar {
  border: 1px solid rgba(0,0,0,0.08);
  border-radius: 0;
  padding: 8px 12px;
}
.controls-light { background: #ffffff; }
.controls-dark { background: rgba(30,30,35,0.55); backdrop-filter: blur(16px); border: 1px solid rgba(255,255,255,0.08); }

.search-wrap { height: 40px; border-radius: 0; padding: 0 12px; min-width: 250px; }
.search-light { background: #f4f6f8; border: 1px solid rgba(0,0,0,0.08); }
.search-dark { background: rgba(255,255,255,0.08); border: 1px solid rgba(255,255,255,0.10); }
.clean-input { border: none; outline: none; background: transparent; font-size: 13px; color: inherit; width: 100%; font-weight: 500; }
.filter-select :deep(.v-field) { border-radius: 0 !important; }
.filter-select :deep(.v-field__input) { min-height: 40px !important; padding-top: 8px !important; }

.kpi-bg-icon { position: absolute; right: -20px; bottom: -20px; opacity: 0.15; transform: rotate(-15deg); pointer-events: none; z-index: 0; }
.kpi-bg-icon .v-icon { font-size: 90px; color: white; }

.kpi-card {
  border: 1px solid rgba(255,255,255,0.15);
  color: white;
  min-height: 100px;
  position: relative;
  overflow: hidden;
}

.bg-gradient-blue { background: linear-gradient(135deg, #1E88E5, #1565C0); }
.bg-gradient-cyan { background: linear-gradient(135deg, #00ACC1, #00838F); }
.bg-gradient-purple { background: linear-gradient(135deg, #7B1FA2, #4A148C); }
.bg-gradient-red { background: linear-gradient(135deg, #E53935, #C62828); }
.bg-gradient-success { background: linear-gradient(135deg, #2E7D32, #1B5E20); }

.kpi-label { font-size: 11px; font-weight: 900; letter-spacing: 1px; text-transform: uppercase; }
.kpi-value { font-size: 24px; font-weight: 900; }
.kpi-footer { font-size: 10px; opacity: .9; font-weight: 700; background: rgba(0,0,0,0.15); padding: 2px 6px; display: inline-block; }

.grid-scroll { scrollbar-gutter: stable both-edges; }
.custom-scroll::-webkit-scrollbar { width: 8px; height: 8px; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.35); border-radius: 6px; }
.custom-scroll::-webkit-scrollbar-track { background: transparent; }

.glass-card { background: rgba(30, 30, 35, 0.45); backdrop-filter: blur(25px); border: 1px solid rgba(255,255,255,0.08); }
.bg-white-05 { background: rgba(255,255,255,0.05); }

.grid-header, .grid-row { display: flex; align-items: stretch; width: 100%; border-bottom: 1px solid rgba(0,0,0,0.08); }
.grid-header .cell { font-size: 11px; font-weight: 900; text-transform: uppercase; letter-spacing: .6px; min-height: 44px; }
.sticky-head { position: sticky; top: 0; z-index: 10; }

.grid-surface-light .cell { background: #f5f7fa; color: rgba(0,0,0,0.7); border-right: 1px solid rgba(0,0,0,0.05); }
.grid-surface-dark .cell { background: rgba(30,30,35,0.95); color: rgba(255,255,255,0.80); border-right: 1px solid rgba(255,255,255,0.05); }

.grid-row-light .cell { background: #fff; border-right: 1px solid rgba(0,0,0,0.05); color: #333; }
.grid-row-light:hover .cell { background: #f0f7ff; }
.grid-row-dark .cell { background: rgba(255,255,255,0.03); border-right: 1px solid rgba(255,255,255,0.05); color: #ddd; }
.grid-row-dark:hover .cell { background: rgba(255,255,255,0.08); }

.cell { padding: 8px 12px; display: flex; align-items: center; overflow: hidden; min-height: 50px; }
.center { justify-content: center; text-align: center; }

.list-text-11 { font-size: 11px !important; line-height: 1.2 !important; }
.list-text-10 { font-size: 10px !important; line-height: 1.2 !important; }
.list-text-9 { font-size: 9px !important; }

.pill-ref {
  font-size: 10px;
  font-weight: 900;
  font-family: monospace;
  background: rgba(128,128,128,0.2);
  padding: 2px 6px;
  border-radius: 4px;
}

.solid-chip {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  height: 20px;
  padding: 0 8px;
  border-radius: 0px;
  font-size: 9px;
  font-weight: 900;
  color: #fff;
  white-space: nowrap;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}
.chip-default { background: #607D8B; }
.chip-info { background: #0288D1; }
.chip-purple { background: #7B1FA2; }
.chip-warn { background: #F57C00; }
.chip-danger { background: #D32F2F; }
.chip-success { background: #43A047; }

.action-btn { width: 28px !important; height: 28px !important; border-radius: 4px !important; }

.text-error { color: #FF5252 !important; }
.text-success { color: #4CAF50 !important; }
.bg-red-lighten-5 { background-color: #FFEBEE !important; }
.bg-red-opacity-10 { background-color: rgba(244, 67, 54, 0.15) !important; }
.bg-deep-orange-darken-3 { background-color: #D84315 !important; }

@keyframes pulse { 0% { opacity: 1; transform: scale(1); } 50% { opacity: 0.8; transform: scale(1.05); } 100% { opacity: 1; transform: scale(1); } }
.animate-pulse { animation: pulse 1.5s infinite; }
</style>
