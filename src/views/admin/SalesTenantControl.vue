<template>
  <div
    class="apple-hub-layout fill-height d-flex flex-column position-relative overflow-hidden w-100"
    :class="isDark ? 'bg-apple-dark text-white' : 'bg-apple-light text-grey-darken-4'"
  >
    <div class="ambient-glow" :class="isDark ? 'glow-dark' : 'glow-light'"></div>

    <div class="px-6 py-6 px-md-8 py-md-6 border-b flex-shrink-0 d-flex justify-space-between align-start position-relative z-10" :class="isDark ? 'bg-surface-dark/80 border-white-05' : 'bg-white/80 border-grey-lighten-2'" style="backdrop-filter: blur(20px);">
        <div class="d-flex align-center gap-5">
            <div class="icon-box-lg rounded-xl elevation-2 d-flex align-center justify-center" :class="isDark ? 'bg-indigo-darken-4 text-indigo-lighten-1' : 'bg-indigo-lighten-5 text-indigo-darken-1'" style="width: 56px; height: 56px;">
                <v-icon size="32">mdi-source-branch-sync</v-icon>
            </div>
            <div>
                <div class="breadcrumb text-[11px] font-weight-bold opacity-60 mb-1 d-flex align-center tracking-widest text-uppercase">
                    <v-icon size="14" class="mr-2">mdi-home</v-icon>
                    <span>Vendas</span>
                    <span class="mx-2 opacity-40">/</span>
                    <span class="text-indigo">Controle Multi-Empresa</span>
                </div>
                <h1 class="text-h4 font-weight-black tracking-tight lh-1 mb-1" style="letter-spacing: -1px !important;">
                    Controle de Tenants
                </h1>
                <p class="text-caption opacity-70 font-weight-medium">Classifique pedidos do NewOrder e vendas do PDV por empresa para refletir corretamente nos relatórios.</p>
            </div>
        </div>

        <div class="d-flex gap-3">
            <v-btn variant="tonal" class="rounded-lg font-weight-bold shadow-sm" height="44" @click="fetchData" :loading="loading">
                <v-icon start size="18">mdi-refresh</v-icon> Atualizar
            </v-btn>
        </div>
    </div>

    <div class="flex-grow-1 overflow-y-auto custom-scroll position-relative z-10 pa-6 pa-md-8 pb-16">

        <div class="mb-8">
            <div class="d-grid kpi-macro-grid gap-4">
                <v-card class="apple-report-card pa-5 rounded-xl border shadow-micro transition-all overflow-hidden" :class="isDark ? 'bg-surface-dark border-white-05' : 'bg-white border-grey-lighten-2'">
                    <div class="text-[10px] font-weight-bold text-uppercase opacity-50 mb-2 tracking-widest">Total de Registros</div>
                    <div class="text-h5 font-mono font-weight-black">{{ kpi.totalCount }}</div>
                </v-card>

                <v-card class="apple-report-card pa-5 rounded-xl border shadow-micro transition-all overflow-hidden" :class="isDark ? 'bg-error-darken-4/10 border-error/20' : 'bg-error-lighten-5 border-error-lighten-4'">
                    <div class="color-glow bg-error"></div>
                    <div class="text-[10px] font-weight-bold text-uppercase text-error mb-2 tracking-widest">Sem Empresa</div>
                    <div class="text-h5 font-mono font-weight-black text-error">{{ kpi.missingCount }}</div>
                </v-card>

                <v-card class="apple-report-card pa-5 rounded-xl border shadow-micro transition-all overflow-hidden" :class="isDark ? 'bg-warning-darken-4/10 border-warning/20' : 'bg-warning-lighten-5 border-warning-lighten-4'">
                    <div class="color-glow bg-warning"></div>
                    <div class="text-[10px] font-weight-bold text-uppercase text-warning-darken-2 mb-2 tracking-widest">NewOrder (S/ Emp)</div>
                    <div class="text-h5 font-mono font-weight-black text-warning-darken-2">{{ kpi.newOrderMissing }}</div>
                </v-card>

                <v-card class="apple-report-card pa-5 rounded-xl border shadow-micro transition-all overflow-hidden" :class="isDark ? 'bg-warning-darken-4/10 border-warning/20' : 'bg-warning-lighten-5 border-warning-lighten-4'">
                    <div class="color-glow bg-warning"></div>
                    <div class="text-[10px] font-weight-bold text-uppercase text-warning-darken-2 mb-2 tracking-widest">PDV (S/ Emp)</div>
                    <div class="text-h5 font-mono font-weight-black text-warning-darken-2">{{ kpi.pdvMissing }}</div>
                </v-card>

                <v-card class="apple-report-card pa-5 rounded-xl border shadow-micro transition-all overflow-hidden" :class="isDark ? 'bg-purple-darken-4/10 border-purple/20' : 'bg-purple-lighten-5 border-purple-lighten-4'">
                    <div class="color-glow bg-purple"></div>
                    <div class="text-[10px] font-weight-bold text-uppercase text-purple mb-2 tracking-widest">Conflitos Financeiro</div>
                    <div class="text-h5 font-mono font-weight-black text-purple">{{ kpi.conflictCount }}</div>
                </v-card>
            </div>
        </div>

        <div class="d-flex flex-column flex-md-row justify-space-between align-center mb-4 gap-4">
            <div class="d-flex align-center gap-3 w-100 w-md-auto">
                <div class="search-wrap rounded-lg border d-flex align-center shadow-micro" :class="isDark ? 'bg-surface-dark border-white-10' : 'bg-white border-grey-lighten-2'" style="height: 44px; width: 300px;">
                    <v-icon :color="isDark ? 'white-70' : 'grey-darken-1'" class="ml-3">mdi-magnify</v-icon>
                    <input v-model="filters.search" type="text" placeholder="Buscar pedido, cliente..." class="clean-input w-100 h-100 px-3 font-weight-bold" :class="isDark ? 'text-white' : 'text-grey-darken-4'">
                </div>

                <v-btn-toggle v-model="filters.source" color="indigo" mandatory density="compact" variant="outlined" class="rounded-lg border-thin bg-white" :class="isDark ? 'bg-surface-dark border-white-10' : ''">
                    <v-btn value="all" class="font-weight-bold text-[11px] tracking-widest">Ambos</v-btn>
                    <v-btn value="orders" class="font-weight-bold text-[11px] tracking-widest">NewOrder</v-btn>
                    <v-btn value="store_sales" class="font-weight-bold text-[11px] tracking-widest">PDV</v-btn>
                </v-btn-toggle>

                <v-btn-toggle v-model="filters.statusFilter" color="error" mandatory density="compact" variant="outlined" class="rounded-lg border-thin bg-white" :class="isDark ? 'bg-surface-dark border-white-10' : ''">
                    <v-btn value="all" class="font-weight-bold text-[11px] tracking-widest">Todos</v-btn>
                    <v-btn value="missing" class="font-weight-bold text-[11px] tracking-widest text-error">Sem Empresa</v-btn>
                    <v-btn value="conflict" class="font-weight-bold text-[11px] tracking-widest text-purple">Com Conflito</v-btn>
                </v-btn-toggle>
            </div>

            <div v-if="selectedIds.size > 0" class="d-flex align-center gap-3">
                <span class="text-body-2 font-weight-black text-indigo">{{ selectedIds.size }} itens selecionados</span>
                <v-btn color="indigo" variant="flat" class="rounded-lg font-weight-black text-uppercase tracking-widest shadow-button" height="40" @click="openMassAssignModal">
                    Atribuir Empresa
                </v-btn>
            </div>
        </div>

        <v-card class="rounded-xl border shadow-micro overflow-hidden d-flex flex-column" :class="isDark ? 'bg-surface-dark border-white-05' : 'bg-white border-grey-lighten-2'">
            <div class="pa-0 overflow-x-auto custom-scroll">
                <div class="grid-header sticky-head" :class="isDark ? 'bg-surface-dark border-b border-white-10' : 'bg-grey-50 border-b border-grey-lighten-2'" style="grid-template-columns: 50px 100px 180px 120px 120px minmax(200px, 1fr) 100px 100px 120px 100px;">
                    <div class="cell center"><v-checkbox-btn v-model="selectAll" color="indigo" density="compact"></v-checkbox-btn></div>
                    <div class="cell center header-text">Origem</div>
                    <div class="cell header-text">Empresa Atual</div>
                    <div class="cell center header-text">Nº Pedido</div>
                    <div class="cell center header-text">Data</div>
                    <div class="cell header-text">Cliente</div>
                    <div class="cell right header-text pr-4">Total</div>
                    <div class="cell center header-text">Itens</div>
                    <div class="cell center header-text">Financeiro</div>
                    <div class="cell center header-text">Ações</div>
                </div>

                <div v-if="loading" class="d-flex justify-center align-center py-12 w-100">
                    <v-progress-circular indeterminate color="indigo"></v-progress-circular>
                </div>

                <div v-else-if="filteredRecords.length === 0" class="d-flex flex-column justify-center align-center py-12 w-100 opacity-60">
                    <v-icon size="48" class="mb-3">mdi-filter-off-outline</v-icon>
                    <span class="font-weight-bold text-uppercase tracking-widest text-[11px]">Nenhum registro encontrado</span>
                </div>

                <div v-else v-for="(row, idx) in filteredRecords" :key="row.id" class="grid-row transition-all hover-elevate" :class="[isDark ? 'grid-row-dark' : 'grid-row-light', zebraClass(idx), selectedIds.has(row.id) ? (isDark ? 'bg-indigo-900/30' : 'bg-indigo-50') : '']" style="grid-template-columns: 50px 100px 180px 120px 120px minmax(200px, 1fr) 100px 100px 120px 100px;">
                    <div class="cell center"><v-checkbox-btn :model-value="selectedIds.has(row.id)" @update:model-value="toggleSelection(row.id)" color="indigo" density="compact"></v-checkbox-btn></div>

                    <div class="cell center">
                        <span class="solid-chip text-[9px]" :class="row.source === 'orders' ? 'bg-blue-darken-2' : 'bg-orange-darken-2'">{{ row.sourceLabel }}</span>
                    </div>

                    <div class="cell">
                        <span v-if="row.company_id" class="text-[11px] font-weight-bold text-truncate" :title="row.company_name || 'Desconhecida'">{{ row.company_name || 'Empresa ID Oculto' }}</span>
                        <v-chip v-else size="x-small" color="error" variant="flat" class="font-weight-black text-[9px] px-2 rounded-sm tracking-widest uppercase">SEM EMPRESA</v-chip>
                    </div>

                    <div class="cell center font-mono font-weight-black text-[12px]" :class="isDark ? 'text-blue-lighten-2' : 'text-blue-darken-3'">#{{ row.order_number }}</div>

                    <div class="cell center font-mono text-[11px] opacity-80">{{ formatDateTime(row.sale_date) }}</div>

                    <div class="cell text-[12px] font-weight-bold text-truncate" :title="row.customer_name">{{ row.customer_name || 'Consumidor' }}</div>

                    <div class="cell right pr-4 font-mono font-weight-black" :class="isDark ? 'text-success-lighten-1' : 'text-success-darken-2'">{{ formatCurrency(row.total_value) }}</div>

                    <div class="cell center text-[11px] font-weight-bold opacity-70">{{ row.item_count }} itens</div>

                    <div class="cell center">
                        <v-tooltip :text="row.receivable_company_mismatch ? 'Conflito de Empresa no Financeiro' : (row.receivable_count > 0 ? 'Financeiro Sincronizado' : 'Sem Recebíveis')" location="top">
                            <template v-slot:activator="{ props }">
                                <v-chip v-bind="props" size="x-small" :color="row.receivable_company_mismatch ? 'purple' : (row.receivable_count > 0 ? 'success' : 'grey')" variant="flat" class="font-weight-bold rounded-sm">
                                    <v-icon start size="12">{{ row.receivable_company_mismatch ? 'mdi-alert' : (row.receivable_count > 0 ? 'mdi-check-all' : 'mdi-minus') }}</v-icon>
                                    {{ row.receivable_count }} Rec.
                                </v-chip>
                            </template>
                        </v-tooltip>
                    </div>

                    <div class="cell center">
                        <v-btn icon size="x-small" variant="tonal" color="indigo" class="rounded-sm shadow-sm" @click="openSingleAssignModal(row)">
                            <v-icon size="14">mdi-source-branch</v-icon>
                        </v-btn>
                    </div>
                </div>
            </div>
        </v-card>
    </div>

    <v-dialog v-model="assignModal.show" max-width="500" persistent>
        <v-card class="rounded-xl border shadow-2xl" :class="isDark ? 'bg-surface-dark text-white border-white-10' : 'bg-white border-grey-lighten-2'">
            <div class="px-6 py-5 border-b d-flex justify-space-between align-center" :class="isDark ? 'bg-indigo-900/30 border-white-05' : 'bg-indigo-50 border-indigo-100'">
                <div>
                    <h3 class="text-h6 font-weight-black text-indigo-darken-3 lh-1">Atribuir Empresa (Tenant)</h3>
                    <div class="text-caption opacity-70 mt-1 font-weight-medium">Aplicando a {{ assignModal.records.length }} registro(s)</div>
                </div>
                <v-btn icon size="small" variant="text" @click="assignModal.show = false"><v-icon>mdi-close</v-icon></v-btn>
            </div>

            <div class="pa-6">
                <v-alert type="warning" variant="tonal" density="compact" class="mb-5 text-caption font-weight-bold" v-if="assignModal.records.some(r => r.receivable_company_mismatch)">
                    Atenção: Alguns registros possuem recebíveis em empresas diferentes da origem atual.
                </v-alert>

                <label class="text-[11px] font-weight-black text-uppercase opacity-70 mb-2 d-block">Empresa Destino</label>
                <v-autocomplete
                    v-model="assignModal.companyId"
                    :items="auxData.companies"
                    item-title="trade_name"
                    item-value="id"
                    variant="outlined"
                    density="comfortable"
                    class="ui-field mb-4"
                    placeholder="Selecione a empresa correta"
                    clearable
                ></v-autocomplete>

                <label class="text-[11px] font-weight-black text-uppercase opacity-70 mb-2 d-block">Sincronização Financeira</label>
                <v-card variant="outlined" class="pa-3 mb-4 rounded-lg" :class="isDark ? 'border-white-10' : 'border-grey-lighten-2'">
                    <v-checkbox v-model="assignModal.syncFinance" color="indigo" hide-details density="compact" class="font-weight-bold">
                        <template v-slot:label>
                            <span class="text-body-2 font-weight-bold" :class="isDark ? 'text-white' : 'text-grey-darken-4'">Atualizar contas a receber atreladas</span>
                        </template>
                    </v-checkbox>
                    <p class="text-[11px] opacity-60 ml-8 mt-n1">Os títulos financeiros gerados por esta venda também serão movidos para a nova empresa.</p>
                </v-card>

                <label class="text-[11px] font-weight-black text-uppercase opacity-70 mb-2 d-block">Motivo da Alteração (Opcional)</label>
                <v-textarea
                    v-model="assignModal.reason"
                    variant="outlined"
                    density="comfortable"
                    rows="2"
                    placeholder="Ex: Correção de lançamento em filial errada."
                    class="ui-field"
                    hide-details
                ></v-textarea>
            </div>

            <div class="pa-5 border-t d-flex justify-end gap-3" :class="isDark ? 'border-white-05 bg-white-02' : 'border-grey-lighten-2 bg-grey-50'">
                <v-btn variant="outlined" class="rounded-lg font-weight-bold text-uppercase tracking-widest px-4" height="42" @click="assignModal.show = false">Cancelar</v-btn>
                <v-btn color="indigo" variant="flat" class="rounded-lg font-weight-black text-uppercase tracking-widest px-6 shadow-sm" height="42" @click="confirmAssignment" :loading="assignModal.saving" :disabled="!assignModal.companyId">
                    Confirmar Alteração
                </v-btn>
            </div>
        </v-card>
    </v-dialog>

  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, reactive } from 'vue';
import { supabase } from '@/api/supabase';
import { useUserStore } from '@/stores/user';
import { useThemeStore } from '@/stores/themeStore';
import { useAppStore } from '@/stores/app';
import { useCompanyStore } from '@/stores/company';
import { format } from 'date-fns';

const userStore = useUserStore();
const themeStore = useThemeStore();
const appStore = useAppStore();
const companyStore = useCompanyStore();

const isDark = computed(() => themeStore.currentMode !== 'light');
const loading = ref(false);

type UnifiedSaleRecord = {
  source: 'orders' | 'store_sales';
  sourceLabel: 'NewOrder' | 'PDV';
  id: string;
  order_number: string | number;
  company_id: string | null;
  company_name?: string | null;
  sale_date: string;
  customer_name: string;
  seller_id?: string | null;
  seller_name?: string | null;
  store_id?: string | null;
  store_name?: string | null;
  total_value: number;
  financial_status?: string | null;
  status?: string | null;
  item_count: number;
  receivable_count: number;
  receivable_company_mismatch: boolean;
};

const records = ref<UnifiedSaleRecord[]>([]);
const selectedIds = ref(new Set<string>());

const auxData = reactive({
    companies: [] as any[]
});

const filters = reactive({
    search: '',
    source: 'all', // 'all', 'orders', 'store_sales'
    statusFilter: 'all' // 'all', 'missing', 'conflict'
});

const kpi = reactive({
    totalCount: 0,
    missingCount: 0,
    newOrderMissing: 0,
    pdvMissing: 0,
    conflictCount: 0
});

const assignModal = reactive({
    show: false,
    saving: false,
    records: [] as UnifiedSaleRecord[],
    companyId: null as string | null,
    syncFinance: true,
    reason: ''
});

const calculateKpis = () => {
    kpi.totalCount = records.value.length;
    kpi.missingCount = records.value.filter(r => !r.company_id).length;
    kpi.newOrderMissing = records.value.filter(r => !r.company_id && r.source === 'orders').length;
    kpi.pdvMissing = records.value.filter(r => !r.company_id && r.source === 'store_sales').length;
    kpi.conflictCount = records.value.filter(r => r.receivable_company_mismatch).length;
};

const filteredRecords = computed(() => {
    let result = records.value;

    if (filters.source !== 'all') {
        result = result.filter(r => r.source === filters.source);
    }

    if (filters.statusFilter === 'missing') {
        result = result.filter(r => !r.company_id);
    } else if (filters.statusFilter === 'conflict') {
        result = result.filter(r => r.receivable_company_mismatch);
    }

    if (filters.search) {
        const q = filters.search.toLowerCase();
        result = result.filter(r =>
            String(r.order_number).toLowerCase().includes(q) ||
            (r.customer_name && r.customer_name.toLowerCase().includes(q))
        );
    }

    return result;
});

const selectAll = computed({
    get: () => filteredRecords.value.length > 0 && selectedIds.value.size === filteredRecords.value.length,
    set: (val) => {
        if (val) {
            filteredRecords.value.forEach(r => selectedIds.value.add(r.id));
        } else {
            selectedIds.value.clear();
        }
    }
});

const toggleSelection = (id: string) => {
    if (selectedIds.value.has(id)) selectedIds.value.delete(id);
    else selectedIds.value.add(id);
};

// --- BUSCA DE DADOS UNIFICADA COM PAGINAÇÃO INFINITA ---
const fetchData = async () => {
    loading.value = true;
    selectedIds.value.clear();
    try {
        // 1. Dados Auxiliares (Empresas)
        const { data: compData } = await supabase.from('companies').select('id, trade_name');
        auxData.companies = compData || [];
        const compMap = new Map();
        auxData.companies.forEach(c => compMap.set(c.id, c.trade_name));

        // 2. Helper para buscar TODAS as páginas ignorando o limite de 1000 do Supabase
        const fetchAllRecords = async (table: string, selectFields: string) => {
            let results: any[] = [];
            let from = 0;
            const step = 999;
            let hasMore = true;
            let safetyLimit = 0; // Trava para evitar loop infinito acidental

            while (hasMore && safetyLimit < 50) {
                safetyLimit++;
                const { data, error } = await supabase
                    .from(table)
                    .select(selectFields)
                    .order('created_at', { ascending: false })
                    .range(from, from + step);

                if (error) throw error;

                if (data && data.length > 0) {
                    results = results.concat(data);
                    // Se veio menos que o limite, significa que acabaram os registros
                    if (data.length <= step) {
                        hasMore = false;
                    } else {
                        from += step + 1;
                    }
                } else {
                    hasMore = false;
                }
            }
            return results;
        };

        appStore.showSnackbar('Carregando base histórica, aguarde...', 'info');

        // 3. Fetch Orders (Buscando ALL)
        const ordersData = await fetchAllRecords(
            'orders',
            'id, order_number, company_id, created_at, customer_name, created_by, store_id, total_value, financial_status, status, order_items(id), finance_receivables(id, company_id)'
        );

        // 4. Fetch Store Sales (Buscando ALL)
        const storeSalesData = await fetchAllRecords(
            'store_sales',
            'id, order_number, company_id, created_at, date_sale, customer_name, seller_id, seller_name, store_id, total_value, financial_status, status, items, finance_receivables(id, company_id)'
        );

        const unified: UnifiedSaleRecord[] = [];

        // Normaliza Orders
        (ordersData || []).forEach((o: any) => {
            const recs = o.finance_receivables || [];
            const hasMismatch = recs.some((r: any) => r.company_id !== o.company_id);

            unified.push({
                source: 'orders',
                sourceLabel: 'NewOrder',
                id: o.id,
                order_number: o.order_number,
                company_id: o.company_id,
                company_name: compMap.get(o.company_id),
                sale_date: o.created_at,
                customer_name: o.customer_name || 'Desconhecido',
                seller_id: o.created_by,
                store_id: o.store_id,
                total_value: Number(o.total_value) || 0,
                financial_status: o.financial_status,
                status: o.status,
                item_count: o.order_items ? o.order_items.length : 0,
                receivable_count: recs.length,
                receivable_company_mismatch: hasMismatch
            });
        });

        // Normaliza Store Sales
        (storeSalesData || []).forEach((s: any) => {
            const recs = s.finance_receivables || [];
            const hasMismatch = recs.some((r: any) => r.company_id !== s.company_id);
            let parsedItems = 0;
            if (s.items) {
                if (Array.isArray(s.items)) parsedItems = s.items.length;
                else if (typeof s.items === 'string') {
                    try { parsedItems = JSON.parse(s.items).length; } catch(e){}
                }
            }

            unified.push({
                source: 'store_sales',
                sourceLabel: 'PDV',
                id: s.id,
                order_number: s.order_number,
                company_id: s.company_id,
                company_name: compMap.get(s.company_id),
                sale_date: s.date_sale || s.created_at,
                customer_name: s.customer_name || 'Consumidor',
                seller_id: s.seller_id,
                seller_name: s.seller_name,
                store_id: s.store_id,
                total_value: Number(s.total_value) || 0,
                financial_status: s.financial_status,
                status: s.status,
                item_count: parsedItems,
                receivable_count: recs.length,
                receivable_company_mismatch: hasMismatch
            });
        });

        // Ordena tudo por data (do mais recente para o mais antigo)
        unified.sort((a, b) => new Date(b.sale_date).getTime() - new Date(a.sale_date).getTime());
        records.value = unified;
        calculateKpis();

    } catch (e: any) {
        appStore.showSnackbar('Erro ao buscar dados: ' + e.message, 'error');
    } finally {
        loading.value = false;
    }
};

// --- AÇÕES DE ATRIBUIÇÃO ---
const openSingleAssignModal = (row: UnifiedSaleRecord) => {
    assignModal.records = [row];
    assignModal.companyId = row.company_id;
    assignModal.reason = '';
    assignModal.syncFinance = true;
    assignModal.show = true;
};

const openMassAssignModal = () => {
    const selectedRecords = records.value.filter(r => selectedIds.value.has(r.id));
    assignModal.records = selectedRecords;
    assignModal.companyId = null;
    assignModal.reason = '';
    assignModal.syncFinance = true;
    assignModal.show = true;
};

const confirmAssignment = async () => {
    if (!assignModal.companyId && assignModal.companyId !== null) return;
    assignModal.saving = true;

    try {
        const orderIds = assignModal.records.filter(r => r.source === 'orders').map(r => r.id);
        const storeSaleIds = assignModal.records.filter(r => r.source === 'store_sales').map(r => r.id);

        const assignPayload = {
            company_id: assignModal.companyId,
            company_assignment_source: 'manual',
            company_assigned_at: new Date().toISOString(),
            company_assigned_by: userStore.user?.id,
            company_assignment_notes: assignModal.reason || null
        };

        // Função auxiliar para quebrar arrays gigantes em lotes de 100 itens
        const chunkArray = (arr: any[], size: number) => {
            const chunks = [];
            for (let i = 0; i < arr.length; i += size) {
                chunks.push(arr.slice(i, i + size));
            }
            return chunks;
        };

        const CHUNK_SIZE = 100;

        // 1. Atualiza Orders em Lotes
        if (orderIds.length > 0) {
            const chunks = chunkArray(orderIds, CHUNK_SIZE);
            for (const chunk of chunks) {
                const { error } = await supabase.from('orders').update(assignPayload).in('id', chunk);
                if (error) throw error;
            }
        }

        // 2. Atualiza Store Sales em Lotes
        if (storeSaleIds.length > 0) {
            const chunks = chunkArray(storeSaleIds, CHUNK_SIZE);
            for (const chunk of chunks) {
                const { error } = await supabase.from('store_sales').update(assignPayload).in('id', chunk);
                if (error) throw error;
            }
        }

        // 3. Sincroniza Financeiro em Lotes
        if (assignModal.syncFinance) {
            if (orderIds.length > 0) {
                const chunks = chunkArray(orderIds, CHUNK_SIZE);
                for (const chunk of chunks) {
                    await supabase.from('finance_receivables').update({ company_id: assignModal.companyId }).in('order_id', chunk);
                }
            }
            if (storeSaleIds.length > 0) {
                const chunks = chunkArray(storeSaleIds, CHUNK_SIZE);
                for (const chunk of chunks) {
                    await supabase.from('finance_receivables').update({ company_id: assignModal.companyId }).in('store_sale_id', chunk);
                }
            }
        }

        // 4. Salva a Auditoria em Lotes (Para não explodir o payload de Inserção)
        const auditRows = assignModal.records.map(r => ({
            source_table: r.source,
            source_id: r.id,
            old_company_id: r.company_id,
            new_company_id: assignModal.companyId,
            changed_by: userStore.user?.id,
            reason: assignModal.reason || null,
            metadata: {
                order_number: r.order_number,
                customer_name: r.customer_name,
                total_value: r.total_value,
                syncFinance: assignModal.syncFinance
            }
        }));

        if (auditRows.length > 0) {
            const chunks = chunkArray(auditRows, CHUNK_SIZE);
            for (const chunk of chunks) {
                await supabase.from('sales_company_assignment_audit').insert(chunk);
            }
        }

        appStore.showSnackbar(`${assignModal.records.length} registros atualizados com sucesso!`, 'success');

        assignModal.show = false;
        selectedIds.value.clear(); // Limpa as caixinhas marcadas da tela
        fetchData(); // Atualiza a tabela

    } catch (e: any) {
        appStore.showSnackbar('Erro ao atribuir: ' + e.message, 'error');
    } finally {
        assignModal.saving = false;
    }
};

const formatCurrency = (val: any) => new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(Number(val) || 0);
const formatDateTime = (d: string) => d ? format(new Date(d), 'dd/MM/yy HH:mm') : '-';
const zebraClass = (i:number) => isDark.value ? (i%2===0?'zebra-dark-a':'zebra-dark-b') : (i%2===0?'zebra-light-a':'zebra-light-b');

onMounted(() => {
    fetchData();
});
</script>

<style scoped>
/* =========================================================
   STYLE PADRÃO APPLE / ADMIN
========================================================== */
.rounded-sm { border-radius: 4px !important; }
.rounded-md { border-radius: 6px !important; }
.rounded-lg { border-radius: 8px !important; }
.rounded-xl { border-radius: 12px !important; }

.ui-field :deep(.v-field) { border-radius: 6px !important; }
.btn-3d { border-radius: 6px !important; box-shadow: 0 3px 5px rgba(0,0,0,0.15), inset 0 2px 0 rgba(255,255,255,0.25) !important; transition: transform 0.1s ease, box-shadow 0.1s ease; text-transform: none !important; }
.btn-3d:active { transform: translateY(2px); box-shadow: 0 1px 2px rgba(0,0,0,0.15), inset 0 1px 0 rgba(255,255,255,0.2) !important; }
.chip-3d { border-radius: 4px !important; box-shadow: 0 2px 4px rgba(0,0,0,0.12), inset 0 1px 0 rgba(255,255,255,0.25) !important; text-shadow: 0 1px 2px rgba(0,0,0,0.25); }

.font-sans { font-family: 'Inter', system-ui, sans-serif; }
.bg-apple-light { background-color: #f5f5f7; }
.bg-apple-dark { background-color: #0c0d10; }
.bg-surface-dark { background-color: #14151a; }

.border-white-05 { border-color: rgba(255,255,255,0.05) !important; }
.border-white-10 { border-color: rgba(255,255,255,0.1) !important; }
.bg-white-02 { background-color: rgba(255,255,255,0.02) !important; }

.shadow-micro { box-shadow: 0 2px 8px rgba(0,0,0,0.04); }
.shadow-soft { box-shadow: 0 4px 14px rgba(0,0,0,0.1) !important; }
.shadow-button { box-shadow: 0 4px 12px rgba(var(--v-theme-primary), 0.4) !important; }

.tracking-widest { letter-spacing: 0.1em !important; }
.lh-1 { line-height: 1.1; }
.font-mono { font-family: 'JetBrains Mono', monospace !important; }

.icon-box-lg { width: 56px; height: 56px; display: flex; align-items: center; justify-content: center; }

/* AMBIENT GLOW */
.ambient-glow { position: absolute; top: 0; left: 0; right: 0; bottom: 0; pointer-events: none; z-index: -1; opacity: 0.4; }
.glow-light { background: radial-gradient(circle at 10% 10%, rgba(var(--v-theme-primary), 0.1) 0%, transparent 40%), radial-gradient(circle at 90% 90%, rgba(var(--v-theme-info), 0.1) 0%, transparent 40%); }
.glow-dark { background: radial-gradient(circle at 10% 10%, rgba(var(--v-theme-primary), 0.15) 0%, transparent 50%), radial-gradient(circle at 90% 90%, rgba(var(--v-theme-info), 0.1) 0%, transparent 50%); opacity: 0.7; }

/* KPI MACRO GRID */
.d-grid { display: grid; }
.kpi-macro-grid { grid-template-columns: repeat(5, 1fr); }
@media (max-width: 1200px) { .kpi-macro-grid { grid-template-columns: repeat(3, 1fr); } }

.apple-report-card { position: relative; overflow: hidden; border-radius: 12px !important; }
.color-glow { position: absolute; width: 120px; height: 120px; bottom: -40px; right: -40px; border-radius: 50%; filter: blur(40px); opacity: 0.1; pointer-events: none; z-index: 0; transition: opacity 0.4s ease, transform 0.4s ease; }
.apple-report-card:hover .color-glow { opacity: 0.25; transform: scale(1.2); }

/* GRID PERSONALIZADA APPLE */
.grid-header, .grid-row { display: grid; align-items: stretch; width: 100%; min-width: 1100px; }
.cell { padding: 6px 12px; display: flex; align-items: center; border-right: 1px solid rgba(0,0,0,0.08); border-bottom: 1px solid rgba(0,0,0,0.08); min-height: 48px; overflow: hidden; transition: background-color 0.2s ease; }
.header-text { font-weight: 800; text-transform: uppercase; letter-spacing: 0.5px; line-height: 1.2; font-size: 11px; white-space: nowrap; }
.center { justify-content: center; text-align: center; }
.right { justify-content: flex-end; text-align: right; }

.grid-surface-light .cell, .grid-header.bg-grey-50 .cell { background: #f8fafc; color: rgba(0,0,0,0.8); border-color: rgba(0,0,0,0.08) !important; }
.grid-surface-dark .cell { background: rgba(255,255,255,0.05); color: rgba(255,255,255,0.9); border-color: rgba(255,255,255,0.08) !important; }

.zebra-light-a .cell { background: #ffffff; }
.zebra-light-b .cell { background: #fcfcfc; }
.zebra-dark-a .cell { background: rgba(0,0,0,0.15); }
.zebra-dark-b .cell { background: rgba(255,255,255,0.02); }

.grid-row-light:hover .cell { background: #f1f5f9 !important; }
.grid-row-dark:hover .cell { background: rgba(255,255,255,0.08) !important; }

.sticky-head { position: sticky; top: 0; z-index: 20; box-shadow: 0 8px 16px -4px rgba(0, 0, 0, 0.08); }

/* SEARCH E SCROLL */
.search-wrap { border-radius: 6px; overflow: hidden; }
.clean-input { border: none; outline: none; background: transparent; }
.custom-scroll::-webkit-scrollbar { width: 8px; height: 8px; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.35); border-radius: 6px; }

/* CHIPS E BOTÕES */
.solid-chip { display: inline-flex; align-items: center; justify-content: center; height: 22px; padding: 0 8px; font-weight: 900; color: #fff; text-transform: uppercase; white-space: nowrap; border-radius: 4px; letter-spacing: 0.5px;}
.hover-elevate:hover { transform: translateY(-1px); box-shadow: 0 4px 10px rgba(0,0,0,0.05); z-index: 5; position: relative;}
</style>
