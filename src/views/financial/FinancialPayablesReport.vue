<template>
  <div
    class="financial-report-layout font-sans fill-height d-flex flex-column relative overflow-hidden"
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
          class="header-bar px-6 py-4 d-flex flex-column flex-md-row align-md-start justify-space-between flex-shrink-0"
          :class="themeStore.currentMode === 'light' ? 'bg-white border-b border-grey-lighten-2 shadow-sm' : 'bg-glass-header border-bottom-white-05'"
      >
          <div class="d-flex flex-column" style="max-width: calc(100vw - 32px);">
              <div class="breadcrumb text-caption d-none d-md-block">
                  <span class="opacity-70 cursor-pointer hover-underline" @click="$router.push({ name: 'AdminReports', params: { reportType: 'hub' } })">Relatórios</span>
                  <span class="mx-2 opacity-50">></span>
                  <span class="font-weight-bold">Financeiro</span>
              </div>
              <div class="d-flex align-center gap-2 mt-1">
                 <v-btn class="d-md-none mr-1" icon="mdi-arrow-left" variant="text" size="small" @click="$router.push({ name: 'AdminReports', params: { reportType: 'hub' } })"></v-btn>
                 <div class="text-h6 font-weight-black tracking-tight leading-none">
                    Relatório de Contas a Pagar
                 </div>
              </div>

              <div class="d-flex align-center gap-3 mt-3 overflow-x-auto hide-scrollbar pb-1 w-100">
                 <v-btn
                    v-if="companyStore.isGlobalView"
                    size="x-small"
                    height="24"
                    :variant="!filters.companyId ? 'flat' : 'tonal'"
                    :color="!filters.companyId ? 'purple' : 'grey'"
                    class="font-weight-bold btn-3d px-3 rounded-pill flex-shrink-0"
                    style="font-size: 10px; letter-spacing: 0.5px;"
                    @click="setCompanyFilter(null)"
                 >
                    HOLDING / GLOBAL
                 </v-btn>

                 <v-btn
                    v-for="comp in auxData.companies"
                    :key="comp.id"
                    size="x-small"
                    height="24"
                    :variant="filters.companyId === comp.id || (!companyStore.isGlobalView && companyStore.context === comp.id && !filters.companyId) ? 'flat' : 'tonal'"
                    :color="filters.companyId === comp.id || (!companyStore.isGlobalView && companyStore.context === comp.id && !filters.companyId) ? 'error' : 'grey'"
                    class="font-weight-bold btn-3d px-3 rounded-pill flex-shrink-0"
                    style="font-size: 10px; letter-spacing: 0.5px;"
                    @click="setCompanyFilter(comp.id)"
                 >
                    {{ comp.trade_name }}
                 </v-btn>
              </div>
          </div>

          <div class="d-flex align-center mt-3 mt-md-0">
              <v-menu location="bottom end">
                <template v-slot:activator="{ props }">
                  <v-btn
                      v-bind="props"
                      color="error"
                      variant="flat"
                      class="btn-rect px-6 font-weight-bold text-uppercase letter-spacing-1 shadow-indigo-soft"
                      height="40"
                      prepend-icon="mdi-file-chart"
                      :loading="reportLoading"
                      :disabled="loading || filteredData.length === 0"
                  >
                      Exportar Relatório
                      <v-icon end size="small">mdi-chevron-down</v-icon>
                  </v-btn>
                </template>
                <v-list density="compact" nav>
                  <v-list-item @click="generateReport('print')" prepend-icon="mdi-printer" title="Imprimir (Nova Aba)" class="text-primary font-weight-bold"></v-list-item>
                  <v-list-item @click="generateReport('pdf')" prepend-icon="mdi-file-pdf-box" title="Exportar PDF" class="text-red-darken-3 font-weight-bold"></v-list-item>
                  <v-list-item @click="generateReport('excel')" prepend-icon="mdi-microsoft-excel" title="Exportar Excel" class="text-green-darken-3 font-weight-bold"></v-list-item>
                </v-list>
              </v-menu>
          </div>
      </div>

      <div class="px-6 pt-4 pb-0 flex-shrink-0">
          <v-row>
              <v-col cols="12" sm="4">
                  <v-card class="kpi-card kpi-rect bg-gradient-danger hover-elevate py-3 px-4" elevation="2">
                      <div class="kpi-bg-icon"><v-icon>mdi-cash-minus</v-icon></div>
                      <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                          <div class="d-flex align-center gap-2">
                              <v-icon size="18" class="opacity-80">mdi-clock-outline</v-icon>
                              <span class="kpi-label">Total a Pagar (Pendente)</span>
                          </div>
                          <div class="kpi-number-group my-1">
                              <span class="kpi-value text-h5">{{ formatCurrency(kpis.totalPendente) }}</span>
                          </div>
                      </div>
                  </v-card>
              </v-col>

              <v-col cols="12" sm="4">
                  <v-card class="kpi-card kpi-rect bg-gradient-success hover-elevate py-3 px-4" elevation="2">
                      <div class="kpi-bg-icon"><v-icon>mdi-check-all</v-icon></div>
                      <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                          <div class="d-flex align-center gap-2">
                              <v-icon size="18" class="opacity-80">mdi-bank-transfer-out</v-icon>
                              <span class="kpi-label">Total Pago (No Filtro)</span>
                          </div>
                          <div class="kpi-number-group my-1">
                              <span class="kpi-value text-h5">{{ formatCurrency(kpis.totalPago) }}</span>
                          </div>
                      </div>
                  </v-card>
              </v-col>

              <v-col cols="12" sm="4">
                  <v-card class="kpi-card kpi-rect bg-gradient-purple hover-elevate py-3 px-4" elevation="2">
                      <div class="kpi-bg-icon"><v-icon>mdi-sigma</v-icon></div>
                      <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                          <div class="d-flex align-center gap-2">
                              <v-icon size="18" class="opacity-80">mdi-calculator</v-icon>
                              <span class="kpi-label">Total Geral (Filtro Atual)</span>
                          </div>
                          <div class="kpi-number-group my-1">
                              <span class="kpi-value text-h5">{{ formatCurrency(kpis.totalGeral) }}</span>
                          </div>
                      </div>
                  </v-card>
              </v-col>
          </v-row>
      </div>

      <div class="px-6 pt-4 pb-2 flex-shrink-0">
          <div class="controls-bar d-flex align-center justify-space-between flex-wrap gap-3" :class="themeStore.currentMode === 'light' ? 'controls-light' : 'controls-dark'">
              <div class="d-flex align-center flex-wrap w-100" style="gap: 10px;">

                  <div class="period-nav d-flex align-center justify-center flex-grow-0" :class="themeStore.currentMode === 'light' ? 'period-nav-light' : 'period-nav-dark'">
                     <div class="period-label text-caption font-weight-black text-center px-4 d-flex align-center" style="height: 40px;">
                        <v-icon start size="small" class="mr-2 opacity-50">mdi-calendar</v-icon>
                        {{ formatDateSafe(filters.customStart) }} até {{ formatDateSafe(filters.customEnd) }}
                     </div>
                  </div>

                  <div class="search-wrap d-flex align-center flex-grow-1" :class="themeStore.currentMode === 'light' ? 'search-light' : 'search-dark'">
                      <v-icon :color="themeStore.currentMode === 'light' ? 'grey-darken-1' : 'white-70'">mdi-magnify</v-icon>
                      <input
                        v-model="filters.search"
                        type="text"
                        placeholder="Buscar por fornecedor, documento ou descrição..."
                        class="clean-input flex-grow-1 ml-2"
                        @keyup.enter="fetchData"
                      />
                  </div>

                  <v-menu v-model="filtersDropdownOpen" location="bottom end" :close-on-content-click="false" :z-index="2500">
                    <template v-slot:activator="{ props }">
                      <v-btn
                        v-bind="props"
                        variant="outlined"
                        class="btn-rect font-weight-bold"
                        height="40"
                        prepend-icon="mdi-filter-variant"
                        :color="activeFilterCount > 0 ? 'error' : (themeStore.currentMode === 'light' ? 'grey-darken-2' : 'white')"
                      >
                        Filtros Avançados
                        <v-badge v-if="activeFilterCount > 0" :content="activeFilterCount" color="error" floating class="ml-2"></v-badge>
                        <v-icon end size="small">mdi-chevron-down</v-icon>
                      </v-btn>
                    </template>

                    <v-card class="rounded-0 pa-4 overflow-y-auto" width="600">
                      <div class="d-flex justify-space-between align-center mb-4 border-b pb-2">
                          <span class="text-caption font-weight-black opacity-70 text-uppercase">Configurar Filtros</span>
                          <v-btn size="x-small" variant="text" color="error" @click="clearFilters">Limpar Tudo</v-btn>
                      </div>

                      <v-row dense class="row-gap">
                        <v-col cols="12">
                            <div class="text-caption font-weight-bold mb-1">Considerar Data de:</div>
                            <v-btn-toggle v-model="filters.dateType" density="compact" color="error" mandatory class="w-100 d-flex" divided variant="outlined">
                                <v-btn value="due_date" class="flex-grow-1 text-caption font-weight-bold">Vencimento</v-btn>
                                <v-btn value="payment_date" class="flex-grow-1 text-caption font-weight-bold">Pagamento (Baixa)</v-btn>
                                <v-btn value="competence_date" class="flex-grow-1 text-caption font-weight-bold">Competência</v-btn>
                            </v-btn-toggle>
                        </v-col>

                        <v-col cols="6"><v-text-field v-model="filters.customStart" label="De" type="date" variant="outlined" density="compact" hide-details class="ui-field" color="error" /></v-col>
                        <v-col cols="6"><v-text-field v-model="filters.customEnd" label="Até" type="date" variant="outlined" density="compact" hide-details class="ui-field" color="error" /></v-col>

                        <v-col cols="12" md="6">
                          <v-autocomplete v-model="filters.supplierId" :items="auxData.suppliers" item-title="name" item-value="id" label="Fornecedor" variant="outlined" density="compact" hide-details clearable class="ui-field" />
                        </v-col>

                        <v-col cols="12" md="6">
                          <v-autocomplete v-model="filters.employeeId" :items="auxData.employees" item-title="name" item-value="id" label="Funcionário" variant="outlined" density="compact" hide-details clearable class="ui-field" />
                        </v-col>

                        <v-col cols="12" md="6"><v-text-field v-model.number="filters.minValue" label="Valor Mín. (R$)" type="number" variant="outlined" density="compact" hide-details class="ui-field" prefix="R$" /></v-col>
                        <v-col cols="12" md="6"><v-text-field v-model.number="filters.maxValue" label="Valor Máx. (R$)" type="number" variant="outlined" density="compact" hide-details class="ui-field" prefix="R$" /></v-col>

                        <v-col cols="12" md="12">
                          <v-autocomplete v-model="filters.chartOfAccountsId" :items="auxData.chartOfAccounts" item-title="name" item-value="id" label="Plano de Contas" variant="outlined" density="compact" hide-details clearable class="ui-field" />
                        </v-col>

                        <v-col cols="12">
                          <div class="text-caption font-weight-black opacity-70 mb-2 mt-2">Status do Título</div>
                          <div class="d-flex flex-wrap" style="gap: 8px;">
                            <v-chip v-for="s in ['pendente','pago','atrasado']" :key="s"
                                    :color="filters.status.includes(s) ? (s === 'pago' ? 'success' : (s === 'atrasado' ? 'error' : 'warning')) : 'grey'"
                                    :variant="filters.status.includes(s) ? 'flat' : 'outlined'"
                                    class="solid-chip cursor-pointer font-weight-bold"
                                    @click="toggleStatusFilter(s)">
                              <v-icon start size="small" v-if="filters.status.includes(s)">mdi-check</v-icon>
                              {{ s === 'pendente' ? 'Em Aberto' : (s === 'pago' ? 'Pago' : 'Atrasado') }}
                            </v-chip>
                          </div>
                        </v-col>
                      </v-row>

                      <div class="d-flex justify-end mt-6">
                        <v-btn variant="flat" class="btn-rect w-100 font-weight-bold" height="42" color="error" @click="applyFiltersFromDropdown">
                          <v-icon start>mdi-magnify</v-icon> Aplicar Filtros e Buscar
                        </v-btn>
                      </div>
                    </v-card>
                  </v-menu>

                  <v-btn icon variant="tonal" color="primary" height="40" width="40" class="btn-rect" @click="fetchData" :loading="loading">
                      <v-icon>mdi-refresh</v-icon>
                  </v-btn>
              </div>
          </div>
      </div>

      <div class="flex-grow-1 px-6 pb-4 overflow-hidden d-flex flex-column mt-2">
          <v-card class="flex-grow-1 d-flex flex-column rounded-0 border-thin overflow-hidden" :class="themeStore.currentMode === 'light' ? 'bg-white shadow-sm' : 'glass-card border-white-05'" :elevation="0">
              <div class="grid-scroll flex-grow-1 overflow-y-auto custom-scroll">
                  <div class="grid-header sticky-head" :class="[themeStore.currentMode === 'light' ? 'grid-surface-light' : 'grid-surface-dark', companyStore.isGlobalView ? 'grid-finance-layout-global' : 'grid-finance-layout-local']">
                      <div class="cell center header-text">Data</div>
                      <div class="cell center header-text">Documento</div>
                      <div class="cell header-text pl-4">Descrição</div>
                      <div class="cell header-text pl-4">Beneficiário / Fornecedor</div>
                      <div class="cell header-text pl-4" v-if="companyStore.isGlobalView">Empresa</div>
                      <div class="cell center header-text">Status</div>
                      <div class="cell right header-text pr-4">Valor Total</div>
                  </div>

                  <div v-if="loading" class="d-flex flex-column justify-center align-center h-100 py-10 w-100" style="min-width: 1000px;">
                      <v-progress-circular indeterminate color="error" size="32" width="3"></v-progress-circular>
                  </div>

                  <div v-else-if="filteredData.length === 0" class="d-flex flex-column justify-center align-center h-100 py-10 opacity-60 w-100" style="min-width: 1000px;">
                      <v-icon size="48" class="mb-2">mdi-text-box-search-outline</v-icon>
                      <span>Nenhuma conta a pagar encontrada para esses filtros.</span>
                  </div>

                  <template v-else>
                      <div v-for="item in filteredData" :key="item.id"
                           class="grid-row"
                           :class="[getRowColorClass(item), companyStore.isGlobalView ? 'grid-finance-layout-global' : 'grid-finance-layout-local']">

                          <div class="cell center">
                              <div class="d-flex flex-column text-center">
                                  <span class="list-text-10 font-mono font-weight-bold">{{ formatDateSafe(item[filters.dateType]) }}</span>
                              </div>
                          </div>

                          <div class="cell center">
                              <span class="list-text-10 font-mono font-weight-bold opacity-80">{{ getRefNumber(item) }}</span>
                          </div>

                          <div class="cell pl-4">
                              <span class="list-text-10 text-truncate" :title="item.description">{{ item.description || '-' }}</span>
                          </div>

                          <div class="cell pl-4">
                              <span class="list-text-10 font-weight-bold text-truncate" :title="getSupplierName(item)">{{ getSupplierName(item) }}</span>
                          </div>

                          <div class="cell pl-4" v-if="companyStore.isGlobalView">
                              <span class="list-text-10 text-truncate">{{ getCompanyName(item.company_id) }}</span>
                          </div>

                          <div class="cell center">
                              <v-chip size="x-small" class="font-weight-black text-uppercase letter-spacing-1 solid-chip" :class="getStatusClass(item)">
                                  {{ getStatusLabel(item) }}
                              </v-chip>
                          </div>

                          <div class="cell right pr-4">
                              <span class="list-text-10 font-mono font-weight-black text-error">
                                  {{ formatCurrency(item.value || item.valor) }}
                              </span>
                          </div>
                      </div>
                  </template>
              </div>
          </v-card>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted, watch } from 'vue';
import { supabase } from '@/api/supabase';
import { useAppStore } from '@/stores/app';
import { useUserStore } from '@/stores/user';
import { useThemeStore } from '@/stores/themeStore';
import { useCompanyStore } from '@/stores/company';
import { format, parseISO, isBefore, startOfDay, startOfMonth, endOfMonth } from 'date-fns';

import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import * as XLSX from 'xlsx';

import logoMjlm from '@/assets/logomjlm.png';
import logoCajuia from '@/assets/logocajuia.png';

const appStore = useAppStore();
const userStore = useUserStore();
const themeStore = useThemeStore();
const companyStore = useCompanyStore();

const now = new Date();
const firstDay = new Date(now.getFullYear(), now.getMonth(), 1).toISOString().substring(0, 10);
const lastDay = new Date(now.getFullYear(), now.getMonth() + 1, 0).toISOString().substring(0, 10);

const loading = ref(false);
const reportLoading = ref(false);
const transactions = ref<any[]>([]);
const filtersDropdownOpen = ref(false);

const auxData = reactive({
  suppliers: [] as any[],
  employees: [] as any[],
  chartOfAccounts: [] as any[],
  companies: [] as any[]
});

const filters = reactive({
    search: '',
    customStart: firstDay,
    customEnd: lastDay,
    dateType: 'due_date' as 'due_date' | 'payment_date' | 'competence_date',
    supplierId: null as any,
    employeeId: null as any,
    chartOfAccountsId: null as any,
    status: [] as string[],
    companyId: null as any,
    minValue: null as number | null,
    maxValue: null as number | null,
});

const activeFilterCount = computed(() => {
  let count = 0;
  if (filters.supplierId) count++;
  if (filters.employeeId) count++;
  if (filters.chartOfAccountsId) count++;
  if (filters.status.length > 0) count++;
  if (filters.minValue || filters.maxValue) count++;
  return count;
});

// 🚨 TABELA CORRETA DE CONTAS A PAGAR
const TABLE_NAME = 'finance_payables';

const buildQuery = (baseQuery: any) => {
    const { customStart, customEnd, dateType } = filters;
    const todayStr = format(new Date(), 'yyyy-MM-dd');

    // 1. DATAS
    const dateField = dateType === 'payment_date' ? 'payment_date' : (dateType === 'competence_date' ? 'competence_date' : 'due_date');
    if (customStart) baseQuery = baseQuery.gte(dateField, customStart);
    if (customEnd) baseQuery = baseQuery.lte(dateField, customEnd);

    // 2. CONTEXTO E EMPRESA (Os botões têm prioridade)
    if (filters.companyId) {
        baseQuery = baseQuery.eq('company_id', filters.companyId);
    } else if (!companyStore.isGlobalView && companyStore.context) {
        baseQuery = baseQuery.eq('company_id', companyStore.context);
    }

    // 3. CAMPO DE BUSCA LIVRE (Único .or() que deve existir)
    if (filters.search && filters.search.trim() !== '') {
        const term = filters.search.trim();
        const val = Number(term);
        if (!isNaN(val) && isFinite(val) && term.length < 10) {
             baseQuery = baseQuery.or(`value.eq.${val},id.eq.${val}`);
        } else {
             baseQuery = baseQuery.or(`description.ilike.%${term}%,entity_name.ilike.%${term}%`);
        }
    }

    // 4. DEMAIS FILTROS PONTUAIS
    if (filters.supplierId) {
        const supName = auxData.suppliers.find(s => s.id === filters.supplierId)?.name;
        if(supName) baseQuery = baseQuery.ilike('entity_name', `%${supName}%`);
    }

    if (filters.employeeId) {
        const empName = auxData.employees.find(e => e.id === filters.employeeId)?.name;
        if(empName) baseQuery = baseQuery.ilike('entity_name', `%${empName}%`);
    }

    if (filters.chartOfAccountsId) baseQuery = baseQuery.eq('chart_of_accounts_id', filters.chartOfAccountsId);
    if (filters.minValue) baseQuery = baseQuery.gte('value', filters.minValue);
    if (filters.maxValue) baseQuery = baseQuery.lte('value', filters.maxValue);

    // 5. INTELIGÊNCIA DE STATUS
    if (filters.status.length > 0) {
        const wantsPago = filters.status.includes('pago');
        const wantsPendente = filters.status.includes('pendente');
        const wantsAtrasado = filters.status.includes('atrasado');

        let orConditions = [];

        if (wantsPago) {
            orConditions.push(`status.eq.pago`);
        }
        if (wantsPendente) {
            orConditions.push(`and(status.eq.pendente,due_date.gte.${todayStr})`);
        }
        if (wantsAtrasado) {
            orConditions.push(`and(status.eq.pendente,due_date.lt.${todayStr})`);
        }

        if (orConditions.length > 0) {
            baseQuery = baseQuery.or(orConditions.join(','));
        }
    }

    return baseQuery;
};

const setCompanyFilter = (id: string | null) => {
    filters.companyId = id;
    fetchData();
};

const fetchData = async () => {
    loading.value = true;
    filtersDropdownOpen.value = false;
    try {
        let query = supabase.from(TABLE_NAME).select('*');
        query = buildQuery(query);
        query = query.order(filters.dateType, { ascending: true });

        const { data, error } = await query;
        if (error) throw error;
        transactions.value = data || [];
    } catch (error: any) {
        console.error("Erro ao buscar dados", error);
        appStore.showSnackbar("Erro ao carregar os dados de contas a pagar.", "error");
    } finally {
        loading.value = false;
    }
};

const fetchAuxiliaryData = async () => {
  try { const { data } = await supabase.from('customers_mj').select('id, nome'); if (data) auxData.suppliers = data.map(c => ({ id: c.id, name: c.nome })); } catch {}
  try { const { data } = await supabase.from('employees_mj').select('id, nome'); if (data) auxData.employees = data.map(e => ({ id: e.id, name: e.nome })); } catch {}
  try { const { data } = await supabase.from('finance_chart_of_accounts').select('id, name').eq('type', 'Despesa').order('name'); if (data) auxData.chartOfAccounts = data; } catch {}
  try { const { data } = await supabase.from('companies').select('id, trade_name, name'); if (data) auxData.companies = data; } catch {}
};

const getStatusLabel = (item: any) => {
    const status = String(item.status || '').toUpperCase();
    if (status === 'PAGO' || status === 'RECEBIDO') return 'PAGO';
    if (isBefore(parseISO(item.due_date), startOfDay(new Date()))) return 'ATRASADO';
    return 'PENDENTE';
};

const getStatusClass = (item: any) => {
    const label = getStatusLabel(item);
    if (label === 'PAGO') return 'chip-success';
    if (label === 'ATRASADO') return 'chip-danger';
    return 'chip-warning';
};

const getRowColorClass = (item: any) => {
    const status = getStatusLabel(item);
    if (themeStore.currentMode === 'light') {
        if (status === 'PAGO') return 'bg-green-lighten-5';
        if (status === 'ATRASADO') return 'bg-red-lighten-5';
        return 'bg-yellow-lighten-5';
    } else {
        if (status === 'PAGO') return 'bg-green-darken-4';
        if (status === 'ATRASADO') return 'bg-red-darken-4';
        return 'bg-yellow-darken-4';
    }
};

const getCompanyName = (id: any) => auxData.companies.find(c => c.id === id)?.trade_name || 'Desconhecida';
const getChartName = (id: any) => auxData.chartOfAccounts.find(c => c.id === id)?.name || '-';
const getSupplierName = (item: any) => item.entity_name || item.supplier_name || item.fornecedor || '-';
const getRefNumber = (item: any) => item.gestao_click_id || item.document_number || (item.id ? String(item.id).slice(0, 4).toUpperCase() : '-');

const filteredData = computed(() => {
    return transactions.value;
});

const kpis = computed(() => {
    let pago = 0;
    let pendente = 0;

    filteredData.value.forEach(t => {
        const val = Number(t.value || t.valor) || 0;
        if (getStatusLabel(t) === 'PAGO') {
            pago += val;
        } else {
            pendente += val;
        }
    });

    return { totalPago: pago, totalPendente: pendente, totalGeral: pago + pendente };
});

const formatCurrency = (v: any) => new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(Number(v)||0);
const formatDateSafe = (dateString: string) => {
    if (!dateString) return '-';
    try { return format(parseISO(dateString), 'dd/MM/yyyy'); } catch { return dateString; }
};

const toggleStatusFilter = (s: string) => {
    const idx = filters.status.indexOf(s);
    if (idx >= 0) filters.status.splice(idx, 1);
    else filters.status.push(s);
};

const clearFilters = () => {
    filters.search = '';
    filters.supplierId = null;
    filters.employeeId = null;
    filters.chartOfAccountsId = null;
    filters.status = [];
    filters.companyId = null;
    filters.minValue = null;
    filters.maxValue = null;
    filters.dateType = 'due_date';
    filters.customStart = format(startOfMonth(new Date()), 'yyyy-MM-dd');
    filters.customEnd = format(endOfMonth(new Date()), 'yyyy-MM-dd');
    fetchData();
};

const applyFiltersFromDropdown = () => { fetchData(); };

watch(() => companyStore.context, () => { fetchData(); });

// =========================================================================
// SISTEMA DE EXPORTAÇÃO (PRINT NOVO VERTICAL / PDF / EXCEL)
// =========================================================================
const generateReport = async (type: 'pdf' | 'excel' | 'print') => {
    reportLoading.value = true;
    const dataToExport = filteredData.value;

    if (dataToExport.length === 0) {
        appStore.showSnackbar('Nenhum dado para exportar', 'warning');
        reportLoading.value = false;
        return;
    }

    const todayStr = format(new Date(), 'yyyy-MM-dd');
    const companyNameLabel = companyStore.isGlobalView ? 'VISÃO GLOBAL - HOLDING' : companyStore.currentCompanyName.toUpperCase();
    const dateLabel = filters.dateType === 'due_date' ? 'Vencimento' : (filters.dateType === 'payment_date' ? 'Pagamento' : 'Competência');

    // Lógica da Logo
    let logoUrl = companyStore.currentCompanyLogo;
    if (companyStore.isGlobalView) {
        logoUrl = logoMjlm;
    } else {
        const name = (companyStore.currentCompanyName || '').toLowerCase();
        if (name.includes('mr jacky') || name.includes('mjprocess') || companyStore.context === 'mjprocess' || !companyStore.currentCompanyLogo) {
            logoUrl = logoMjlm;
        } else if (name.includes('cajuia') || name.includes('santos')) {
            logoUrl = logoCajuia;
        }
    }

    // ----- 1. EXCEL -----
    if (type === 'excel') {
        const ws = XLSX.utils.json_to_sheet(dataToExport.map(i => ({
            Ref: getRefNumber(i),
            Data: formatDateSafe(i[filters.dateType]),
            Fornecedor_Beneficiario: getSupplierName(i),
            Descricao: i.description,
            PlanoContas: getChartName(i.chart_of_accounts_id),
            Status: getStatusLabel(i),
            Valor: Number(i.value || i.valor) - Number(i.discount || 0),
            Empresa: getCompanyName(i.company_id),
            Observacoes: i.notes || ''
        })));
        const wb = XLSX.utils.book_new();
        XLSX.utils.book_append_sheet(wb, ws, "ContasPagar");
        XLSX.writeFile(wb, `Relatorio_Pagar_${format(new Date(), 'dd-MM-yyyy')}.xlsx`);
        appStore.showSnackbar('Excel Gerado com Sucesso!', 'success');
        reportLoading.value = false;
        return;
    }

    // CALCULAR KPIS
    let totalVal = 0, openVal = 0, overdueVal = 0, paidVal = 0;
    dataToExport.forEach(row => {
        const val = Number(row.value || row.valor) - Number(row.discount || 0);
        totalVal += val;
        const isPaid = getStatusLabel(row) === 'PAGO';
        if (isPaid) paidVal += val;
        else {
            if (row.due_date < todayStr) overdueVal += val;
            else openVal += val;
        }
    });

    // ----- 2. PDF NATIVO (jsPDF) - RETRATO COM BORDAS E KPIS -----
    if (type === 'pdf') {
        const doc = new jsPDF({ orientation: 'p', unit: 'mm', format: 'a4' });
        const pageW = doc.internal.pageSize.getWidth();
        const pageH = doc.internal.pageSize.getHeight();
        const M = 10;
        const boxW = pageW - M * 2;

        try {
            const img = new Image();
            img.crossOrigin = "Anonymous";
            img.src = logoUrl || logoMjlm;
            await new Promise((resolve) => {
                img.onload = resolve;
                img.onerror = () => { img.src = logoMjlm; img.onload = resolve; };
            });
            const canvas = document.createElement('canvas');
            canvas.width = img.width; canvas.height = img.height;
            const ctx = canvas.getContext('2d');
            ctx.fillStyle = '#FFFFFF'; ctx.fillRect(0, 0, canvas.width, canvas.height);
            ctx.drawImage(img, 0, 0);
            const imgData = canvas.toDataURL('image/jpeg', 1.0);
            const imgProps = doc.getImageProperties(imgData);
            const imgWidth = 35;
            const imgHeight = (imgProps.height * imgWidth) / imgProps.width;
            doc.addImage(imgData, 'JPEG', M + 3, M + 4, imgWidth, imgHeight);
        } catch(e) { console.warn("Logo falhou", e); }

        // CAIXA DO CABEÇALHO (Header)
        const headerH = 26;
        doc.setDrawColor(50, 50, 50); // Linha escura
        doc.setLineWidth(0.3);
        doc.rect(M, M, boxW, headerH);

        doc.setFont("helvetica", "bold");
        doc.setFontSize(14);
        doc.setTextColor(0);
        doc.text("CONTAS A PAGAR", M + 42, M + 8);

        doc.setFont("helvetica", "normal");
        doc.setFontSize(9);
        doc.text(`Empresa: ${companyNameLabel}`, M + 42, M + 14);
        doc.text(`Período (${dateLabel}): ${formatDateSafe(filters.customStart)} a ${formatDateSafe(filters.customEnd)}`, M + 42, M + 19);
        doc.text(`Filtro Status: ${filters.status.length ? filters.status.join(', ').toUpperCase() : 'TODOS'}`, M + 42, M + 24);

        doc.text(`Emissão: ${format(new Date(), 'dd/MM/yyyy HH:mm')}`, pageW - M - 3, M + 8, { align: 'right' });
        doc.text(`Por: ${userStore.user?.email || 'Sistema'}`, pageW - M - 3, M + 14, { align: 'right' });

        // CAIXAS DOS KPIs
        const kpiY = M + headerH + 4;
        const kpiH = 14;
        const gap = 3;
        const kpiW = (boxW - (gap * 3)) / 4;

        const drawKpi = (label: string, value: string, i: number) => {
            const x = M + i * (kpiW + gap);
            doc.setFillColor(245, 245, 245);
            doc.rect(x, kpiY, kpiW, kpiH, 'FD');
            doc.setFont("helvetica", "bold");
            doc.setFontSize(7);
            doc.setTextColor(80, 80, 80);
            doc.text(label, x + 3, kpiY + 5);
            doc.setFontSize(10);
            doc.setTextColor(0);
            doc.text(value, x + 3, kpiY + 11);
        };

        drawKpi("TOTAL GERAL", formatCurrency(totalVal), 0);
        drawKpi("A PAGAR", formatCurrency(openVal), 1);
        drawKpi("ATRASADO", formatCurrency(overdueVal), 2);
        drawKpi("PAGO", formatCurrency(paidVal), 3);

        // CAIXA DE LEGENDA
        const legY = kpiY + kpiH + 4;
        doc.setFillColor(255, 255, 255);
        doc.rect(M, legY, boxW, 8, 'FD');
        doc.setFont("helvetica", "bold");
        doc.setFontSize(8);
        doc.text("LEGENDA:   [ ] Caixa para Baixa Manual   |   [Verde] Pago   |   [Branco] Em Aberto   |   [Vermelho] Atrasado", pageW / 2, legY + 5.5, { align: "center" });

        let finalY = legY + 12;

        const columns = [
            { header: 'BAIXA', dataKey: 'check' },
            { header: 'DATA', dataKey: 'date' },
            { header: 'DOCUMENTO', dataKey: 'ref' },
            { header: 'FORNECEDOR / BENEF.', dataKey: 'entity' },
            { header: 'DESCRIÇÃO', dataKey: 'desc' },
            ...(companyStore.isGlobalView ? [{ header: 'EMPRESA', dataKey: 'company' }] : []),
            { header: 'STATUS', dataKey: 'status_label' },
            { header: 'VALOR', dataKey: 'value' }
        ];

        const drawCheckbox = (data: any) => {
            if (data.column.dataKey === 'check' && data.section === 'body') {
                doc.setDrawColor(50, 50, 50); // Linha bem preta
                doc.setLineWidth(0.3);
                const dim = 4;
                const x = data.cell.x + (data.cell.width - dim) / 2;
                const y = data.cell.y + (data.cell.height - dim) / 2;
                doc.rect(x, y, dim, dim);
            }
        };

        const tableBody = dataToExport.map(row => {
            const val = Number(row.value || row.valor) - Number(row.discount || 0);
            const isPaid = getStatusLabel(row) === 'PAGO';
            const isOverdueItem = !isPaid && row.due_date < todayStr;

            let rowColor: [number, number, number] = [255, 255, 255];
            if (isPaid) rowColor = [236, 253, 245]; // Verde claro
            else if (isOverdueItem) rowColor = [254, 242, 242]; // Vermelho claro

            return {
                check: '',
                date: formatDateSafe(row[filters.dateType]),
                ref: getRefNumber(row),
                entity: getSupplierName(row).substring(0, 25),
                desc: (row.description || '').substring(0, 30),
                company: companyStore.isGlobalView ? getCompanyName(row.company_id).substring(0, 15) : '',
                status_label: getStatusLabel(row).toUpperCase(),
                value: formatCurrency(val),
                _rowColor: rowColor
            };
        });

        autoTable(doc, {
            startY: finalY, columns: columns, body: tableBody, theme: 'grid',
            tableWidth: boxW, margin: { left: M, right: M },
            styles: { fontSize: 7, cellPadding: 2, lineColor: [50, 50, 50], lineWidth: 0.2, textColor: 0 },
            headStyles: { fillColor: [230, 230, 230], textColor: 0, fontStyle: 'bold' },
            columnStyles: {
                check: { cellWidth: 10, halign: 'center' },
                value: { halign: 'right', fontStyle: 'bold', cellWidth: 22 }
            },
            didDrawCell: drawCheckbox,
            didParseCell: (data) => {
                if (data.section === 'body' && (data.row.raw as any)._rowColor) {
                    data.cell.styles.fillColor = (data.row.raw as any)._rowColor;
                }
            },
            foot: [['', '', '', '', ...(companyStore.isGlobalView ? [''] : []), 'TOTAL DO RELATÓRIO:', '', formatCurrency(totalVal)]],
            footStyles: { fillColor: [240, 240, 240], textColor: [0, 0, 0], fontStyle: 'bold', halign: 'right' }
        });

        const totalPages = doc.internal.getNumberOfPages();
        for (let i = 1; i <= totalPages; i++) {
            doc.setPage(i);
            doc.setFontSize(7).setTextColor(150);
            doc.text(`Gerado com MJProcess`, pageW - M, pageH - 5, { align: "right" });
        }

        doc.save(`Contas_Pagar_${format(new Date(), 'yyyyMMdd_HHmm')}.pdf`);
        appStore.showSnackbar('PDF Gerado com Sucesso!', 'success');

    // ----- 3. IMPRESSÃO HTML (COM BORDAS ESCURAS) -----
    } else if (type === 'print') {
        const printWindow = window.open('', '_blank');
        if (!printWindow) {
            appStore.showSnackbar('Permita a abertura de pop-ups.', 'warning');
            reportLoading.value = false; return;
        }

        let rowsHtml = '';

        dataToExport.forEach(row => {
            const val = Number(row.value || row.valor) - Number(row.discount || 0);
            const isPaid = getStatusLabel(row) === 'PAGO';
            const isOverdueItem = !isPaid && row.due_date < todayStr;

            let rowClass = 'row-open';
            if (isPaid) rowClass = 'row-paid';
            else if (isOverdueItem) rowClass = 'row-overdue';

            const companyHtml = companyStore.isGlobalView ? `<td class="text-center">${getCompanyName(row.company_id)}</td>` : '';

            rowsHtml += `
                <tr class="${rowClass}">
                    <td class="text-center"><div class="checkbox-box"></div></td>
                    <td class="text-center">${formatDateSafe(row[filters.dateType])}</td>
                    <td class="text-center font-bold">${getRefNumber(row)}</td>
                    <td>${getSupplierName(row)}</td>
                    <td>${row.description || '-'}</td>
                    ${companyHtml}
                    <td class="text-center font-bold">${getStatusLabel(row).toUpperCase()}</td>
                    <td class="text-right font-bold">${formatCurrency(val)}</td>
                </tr>
            `;
        });

        const companyColHead = companyStore.isGlobalView ? '<th class="text-center" style="width: 80px;">Empresa</th>' : '';
        const columnCount = companyStore.isGlobalView ? 8 : 7;

        const html = `
            <!DOCTYPE html>
            <html lang="pt-BR">
            <head>
                <meta charset="UTF-8">
                <title>Romaneio - Contas a Pagar</title>
                <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
                <style>
                    :root { --border: #333; --text-main: #000; --bg-head: #e5e7eb; }
                    body { font-family: 'Inter', sans-serif; color: var(--text-main); margin: 0; padding: 20px; font-size: 11px; background: #fff; }

                    .print-toolbar { display: flex; justify-content: space-between; align-items: center; background: #f8fafc; padding: 12px 20px; border-radius: 8px; border: 1px solid var(--border); margin-bottom: 20px; }
                    .btn-print { background: #0f172a; color: #fff; border: none; padding: 8px 20px; border-radius: 6px; font-weight: 600; cursor: pointer; transition: 0.2s; }

                    /* BORDAS FORTES IGUAL ORDERMANAGEMENT */
                    .header-box { display: flex; justify-content: space-between; align-items: center; border: 1.5px solid var(--border); padding: 15px; margin-bottom: 15px; }
                    .logo { max-width: 140px; max-height: 45px; object-fit: contain; }
                    .header-info { text-align: right; }
                    .header-info h1 { margin: 0 0 5px 0; font-size: 18px; font-weight: 900; text-transform: uppercase; }
                    .header-info p { margin: 2px 0; font-size: 11px; font-weight: 500; }

                    .kpi-container { display: flex; gap: 10px; margin-bottom: 10px; }
                    .kpi-card { flex: 1; border: 1px solid var(--border); padding: 8px 12px; background: #fafafa; }
                    .kpi-title { font-size: 9px; font-weight: 800; text-transform: uppercase; margin-bottom: 4px; color: #444; }
                    .kpi-val { font-size: 14px; font-weight: 900; color: #000; }

                    .legend-box { border: 1px solid var(--border); padding: 8px; text-align: center; font-size: 10px; font-weight: 800; margin-bottom: 15px; background: #fff; }

                    table { width: 100%; border-collapse: collapse; margin-bottom: 30px; border: 1px solid var(--border); }
                    th, td { padding: 6px 8px; text-align: left; border: 1px solid var(--border) !important; }
                    th { background-color: var(--bg-head) !important; color: #000; font-weight: 800; font-size: 10px; text-transform: uppercase; }

                    .text-center { text-align: center; }
                    .text-right { text-align: right; }
                    .font-bold { font-weight: 700; }

                    .checkbox-box { width: 12px; height: 12px; border: 1.5px solid var(--border); margin: 0 auto; background: #fff; }

                    /* Backgrounds que forçam cor na impressão */
                    .row-paid { background-color: #dcfce7 !important; }
                    .row-overdue { background-color: #fee2e2 !important; }
                    .row-open { background-color: #ffffff !important; }

                    .table-footer td { background-color: var(--bg-head) !important; border-top: 2px solid var(--border) !important; font-size: 12px; }

                    @media print {
                        body { padding: 0; }
                        .print-toolbar { display: none !important; }
                        * { -webkit-print-color-adjust: exact !important; color-adjust: exact !important; print-color-adjust: exact !important; }
                        @page { margin: 10mm; size: A4 portrait; }
                    }
                </style>
            </head>
            <body>
                <div class="print-toolbar">
                    <span style="color: #64748b; font-weight: 500;">Dica: Salve em PDF ou imprima direto na impressora. As linhas já estão configuradas.</span>
                    <button class="btn-print" onclick="window.print()">🖨️ Imprimir Romaneio</button>
                </div>

                <div class="header-box">
                    <img src="${logoUrl}" alt="Logo" class="logo">
                    <div class="header-info">
                        <h1>CONTAS A PAGAR</h1>
                        <p>Empresa: ${companyNameLabel}</p>
                        <p>Período (${dateLabel}): ${formatDateSafe(filters.customStart)} a ${formatDateSafe(filters.customEnd)}</p>
                        <p>Filtro: ${filters.status.length ? filters.status.join(', ').toUpperCase() : 'TODOS'}</p>
                    </div>
                </div>

                <div class="kpi-container">
                    <div class="kpi-card"><div class="kpi-title">Total Geral</div><div class="kpi-val">${formatCurrency(totalVal)}</div></div>
                    <div class="kpi-card"><div class="kpi-title">A Pagar</div><div class="kpi-val">${formatCurrency(openVal)}</div></div>
                    <div class="kpi-card"><div class="kpi-title">Atrasados</div><div class="kpi-val">${formatCurrency(overdueVal)}</div></div>
                    <div class="kpi-card"><div class="kpi-title">Pagos</div><div class="kpi-val">${formatCurrency(paidVal)}</div></div>
                </div>

                <div class="legend-box">
                    LEGENDA: &nbsp; [ ] Caixa para Baixa Manual &nbsp; | &nbsp; 🟩 Verde = Pago &nbsp; | &nbsp; ⬜ Branco = Em Aberto &nbsp; | &nbsp; 🟥 Vermelho = Atrasado
                </div>

                <table>
                    <thead>
                        <tr>
                            <th class="text-center" style="width: 40px;">Baixa</th>
                            <th class="text-center" style="width: 70px;">Data</th>
                            <th class="text-center" style="width: 70px;">Doc/Ref</th>
                            <th>Fornecedor / Benef.</th>
                            <th>Descrição</th>
                            ${companyColHead}
                            <th class="text-center" style="width: 80px;">Status</th>
                            <th class="text-right" style="width: 90px;">Valor</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${rowsHtml}
                    </tbody>
                    <tfoot>
                        <tr class="table-footer">
                            <td colspan="${columnCount - 1}" class="text-right font-bold">TOTAL DO RELATÓRIO:</td>
                            <td class="text-right font-bold">${formatCurrency(totalVal)}</td>
                        </tr>
                    </tfoot>
                </table>
                <script>
                    window.onload = () => { setTimeout(() => { window.print(); }, 500); };
                <\/script>
            </body>
            </html>
        `;

        printWindow.document.open();
        printWindow.document.write(html);
        printWindow.document.close();
    }

    reportLoading.value = false;
};

onMounted(() => {
    fetchAuxiliaryData();
    fetchData();
});
</script>

<style scoped lang="scss">
.financial-report-layout { position: relative; }
.background-carousel-wrapper { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 0; opacity: 0.6; pointer-events: none; }
.background-overlay { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 1; background: radial-gradient(circle at center, rgba(15, 15, 19, 0.4), rgba(15, 15, 19, 0.98)); backdrop-filter: blur(8px); }
.z-10 { position: relative; z-index: 10; }
.bg-glass-dark { background: rgba(10,10,12,0.85); }
.bg-glass-header { background: rgba(20,20,24,0.55); backdrop-filter: blur(14px); }
.border-bottom-white-05 { border-bottom: 1px solid rgba(255,255,255,0.08); }

.btn-rect { border-radius: 0 !important; text-transform: none !important; font-weight: 800; }
.controls-bar { border: 1px solid rgba(0,0,0,0.08); border-radius: 0; padding: 10px; }
.controls-light { background: #ffffff; }
.controls-dark { background: rgba(30,30,35,0.55); backdrop-filter: blur(16px); border: 1px solid rgba(255,255,255,0.08); }

.period-nav { border-radius: 0; height: 40px; overflow: hidden; }
.period-nav-light { border: 1px solid rgba(0,0,0,0.12); background: #fafafa; }
.period-nav-dark { border: 1px solid rgba(255,255,255,0.10); background: rgba(255,255,255,0.06); }

.search-wrap { height: 40px; border-radius: 0; padding: 0 12px; min-width: 250px; }
.search-light { background: #f4f6f8; border: 1px solid rgba(0,0,0,0.08); }
.search-dark { background: rgba(255,255,255,0.08); border: 1px solid rgba(255,255,255,0.10); }

.clean-input { border: none; outline: none; background: transparent; font-size: 12px; color: inherit; width: 100%; }
.date-input { width: 130px; }
.ui-field :deep(.v-field) { border-radius: 0 !important; }

.kpi-bg-icon { position: absolute; right: -20px; bottom: -20px; opacity: 0.15; transform: rotate(-15deg); pointer-events: none; }
.kpi-bg-icon .v-icon { font-size: 100px; color: white; }
.kpi-card { border: 1px solid rgba(255,255,255,0.15); color: white; min-height: 110px; position: relative; overflow: hidden; border-radius: 0 !important; }
.bg-gradient-info { background: linear-gradient(135deg, #0288d1, #005b9f); }
.bg-gradient-success { background: linear-gradient(135deg, #2e7d32, #1b5e20); }
.bg-gradient-purple { background: linear-gradient(135deg, #7b1fa2, #4a148c); }
.bg-gradient-danger { background: linear-gradient(135deg, #c62828, #b71c1c); }

.kpi-label { font-size: 12px; font-weight: 900; letter-spacing: .2px; }
.kpi-value { font-size: 24px; font-weight: 900; letter-spacing: .2px; }

/* Grid Separado: Data, Doc, Desc, Fornecedor, Empresa(opt), Status, Valor */
.grid-finance-layout-global { display: grid; width: 100%; grid-template-columns: 90px 100px 1.5fr 1.5fr minmax(0, 1fr) 100px 120px; }
.grid-finance-layout-local { display: grid; width: 100%; grid-template-columns: 90px 100px 1.5fr 1.5fr 100px 120px; }

.cell { padding: 8px 10px; display: flex; align-items: center; border-right: 1px solid rgba(0,0,0,0.08); border-bottom: 1px solid rgba(0,0,0,0.08); min-height: 56px; overflow: hidden; }
.center { justify-content: center; text-align: center; }
.right { justify-content: flex-end; text-align: right; }

.header-text { font-size: 11px; font-weight: 900; text-transform: uppercase; letter-spacing: 0.5px; opacity: 0.8; padding: 12px 8px; }
.grid-header .cell { min-height: 44px; font-size: 12px; font-weight: 900; text-transform: uppercase; letter-spacing: .6px; }

.grid-surface-light .cell { background: #f5f7fa; color: rgba(0,0,0,0.7); }
.grid-surface-dark .cell { background: rgba(255,255,255,0.08); color: rgba(255,255,255,0.80); }
.sticky-head { position: sticky; top: 0; z-index: 10; }

.shadow-indigo-soft { box-shadow: 0 4px 15px rgba(63, 81, 181, 0.4); }
.custom-scroll::-webkit-scrollbar { width: 6px; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.3); border-radius: 4px; }
.list-text-10 { font-size: 13px !important; line-height: 1.25 !important; }

.solid-chip { display: inline-flex; align-items: center; justify-content: center; height: 22px; padding: 0 10px; border-radius: 8px; font-size: 10px; font-weight: 900; color: #fff; white-space: nowrap; }
.chip-success { background: #2e7d32; }
.chip-warning { background: #f57f17; }
.chip-danger { background: #c62828; }
.row-gap { row-gap: 12px; }
.hide-scrollbar::-webkit-scrollbar { display: none; }
.hide-scrollbar { -ms-overflow-style: none; scrollbar-width: none; }

/* EFEITOS 3D E BOTÕES */
.btn-3d {
    border-radius: 6px !important;
    box-shadow: 0 3px 5px rgba(0,0,0,0.15), inset 0 2px 0 rgba(255,255,255,0.25) !important;
    transition: transform 0.1s ease, box-shadow 0.1s ease;
    text-transform: none !important;
    font-weight: 800;
}
.btn-3d:active {
    transform: translateY(2px);
    box-shadow: 0 1px 2px rgba(0,0,0,0.15), inset 0 1px 0 rgba(255,255,255,0.2) !important;
}

</style>
