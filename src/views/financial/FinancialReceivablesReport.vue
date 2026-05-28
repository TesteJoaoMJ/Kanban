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
                    Relatório de Contas a Receber
                 </div>
              </div>

              <!-- BOTÕES MULTI-TENANT ADICIONADOS -->
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
                    :color="filters.companyId === comp.id || (!companyStore.isGlobalView && companyStore.context === comp.id && !filters.companyId) ? 'success' : 'grey'"
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
                      color="success"
                      variant="flat"
                      class="btn-rect px-6 font-weight-bold text-uppercase letter-spacing-1 shadow-indigo-soft"
                      height="40"
                      prepend-icon="mdi-file-chart"
                      :loading="reportLoading"
                      :disabled="loading || clientSideFilteredItems.length === 0"
                  >
                      Exportar Relatório
                      <v-icon end size="small">mdi-chevron-down</v-icon>
                  </v-btn>
                </template>
                <v-list density="compact" nav class="py-2" width="280">
                  <div class="text-[10px] font-weight-bold text-uppercase text-grey-darken-1 px-4 mb-2">Modo Lista Corrida</div>
                  <v-list-item @click="generateReport('print_list')" prepend-icon="mdi-printer" title="Imprimir (Lista)" class="text-primary font-weight-bold"></v-list-item>
                  <v-list-item @click="generateReport('pdf_list')" prepend-icon="mdi-file-pdf-box" title="PDF (Lista)" class="text-red-darken-3 font-weight-bold"></v-list-item>
                  <v-divider class="my-2"></v-divider>
                  <div class="text-[10px] font-weight-bold text-uppercase text-grey-darken-1 px-4 mb-2">Modo Agrupado por Cliente</div>
                  <v-list-item @click="generateReport('print_grouped')" prepend-icon="mdi-printer-pos" title="Imprimir (Agrupado)" class="text-indigo-darken-3 font-weight-bold"></v-list-item>
                  <v-list-item @click="generateReport('pdf_grouped')" prepend-icon="mdi-file-document-multiple" title="PDF (Agrupado)" class="text-orange-darken-4 font-weight-bold"></v-list-item>
                  <v-divider class="my-2"></v-divider>
                  <v-list-item @click="generateReport('excel')" prepend-icon="mdi-microsoft-excel" title="Exportar Dados (Excel)" class="text-green-darken-3 font-weight-bold"></v-list-item>
                </v-list>
              </v-menu>
          </div>
      </div>

      <div class="px-6 pt-4 pb-0 flex-shrink-0">
          <v-row>
              <v-col cols="12" sm="4">
                  <v-card class="kpi-card kpi-rect bg-gradient-info hover-elevate py-3 px-4" elevation="2">
                      <div class="kpi-bg-icon"><v-icon>mdi-cash-plus</v-icon></div>
                      <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                          <div class="d-flex align-center gap-2">
                              <v-icon size="18" class="opacity-80">mdi-clock-outline</v-icon>
                              <span class="kpi-label">A Receber (Pendente/No Filtro)</span>
                          </div>
                          <div class="kpi-number-group my-1">
                              <span class="kpi-value text-h5">{{ formatCurrency(kpis.totalPendente) }}</span>
                          </div>
                      </div>
                  </v-card>
              </v-col>

              <v-col cols="12" sm="4">
                  <v-card class="kpi-card kpi-rect bg-gradient-success hover-elevate py-3 px-4" elevation="2">
                      <div class="kpi-bg-icon"><v-icon>mdi-check-decagram</v-icon></div>
                      <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                          <div class="d-flex align-center gap-2">
                              <v-icon size="18" class="opacity-80">mdi-bank-transfer-in</v-icon>
                              <span class="kpi-label">Recebido (No Filtro)</span>
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
                  <v-menu location="bottom start" :close-on-content-click="true">
                    <template v-slot:activator="{ props }">
                      <v-btn v-bind="props" variant="outlined" class="btn-rect flex-grow-1 flex-md-grow-0" height="40" prepend-icon="mdi-calendar-range" color="success">
                        Período Rápido
                        <v-icon end size="small">mdi-chevron-down</v-icon>
                      </v-btn>
                    </template>
                    <v-card class="rounded-0" min-width="220">
                      <v-list density="compact" nav>
                        <v-list-item v-for="p in quickPeriodOptions" :key="p.value" @click="applyPreset(p.value)">
                          <v-list-item-title class="text-body-2 font-weight-bold">{{ p.label }}</v-list-item-title>
                        </v-list-item>
                      </v-list>
                    </v-card>
                  </v-menu>

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
                        placeholder="Buscar pesquisa local (Cliente, Ref, Valor)..."
                        class="clean-input flex-grow-1 ml-2"
                        @keyup.enter="handleSearchEnter"
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
                        :color="activeFilterCount > 0 ? 'success' : (themeStore.currentMode === 'light' ? 'grey-darken-2' : 'white')"
                      >
                        Filtros DB
                        <v-badge v-if="activeFilterCount > 0" :content="activeFilterCount" color="success" floating class="ml-2"></v-badge>
                        <v-icon end size="small">mdi-chevron-down</v-icon>
                      </v-btn>
                    </template>

                    <v-card class="rounded-0 pa-4 overflow-y-auto" width="600">
                      <div class="d-flex justify-space-between align-center mb-4 border-b pb-2">
                          <span class="text-caption font-weight-black opacity-70 text-uppercase">Configurar Filtros de Banco</span>
                          <v-btn size="x-small" variant="text" color="error" @click="clearFilters">Limpar Tudo</v-btn>
                      </div>

                      <v-row dense class="row-gap">
                        <v-col cols="12">
                            <div class="text-caption font-weight-bold mb-1">Considerar Data de:</div>
                            <v-btn-toggle v-model="filters.dateType" density="compact" color="success" mandatory class="w-100 d-flex" divided variant="outlined">
                                <v-btn value="due_date" class="flex-grow-1 text-caption font-weight-bold">Vencimento</v-btn>
                                <v-btn value="payment_date" class="flex-grow-1 text-caption font-weight-bold">Recebimento (Baixa)</v-btn>
                            </v-btn-toggle>
                        </v-col>

                        <v-col cols="6"><v-text-field v-model="filters.customStart" label="De" type="date" variant="outlined" density="compact" hide-details class="ui-field" color="success" /></v-col>
                        <v-col cols="6"><v-text-field v-model="filters.customEnd" label="Até" type="date" variant="outlined" density="compact" hide-details class="ui-field" color="success" /></v-col>

                        <v-col cols="12" md="6">
                          <v-autocomplete v-model="filters.customerId" :items="auxData.customers" item-title="name" item-value="id" label="Cliente" variant="outlined" density="compact" hide-details clearable class="ui-field" />
                        </v-col>
                        <v-col cols="12" md="6">
                          <v-autocomplete v-model="filters.salespersonId" :items="auxData.salespeople" item-title="full_name" item-value="id" label="Vendedor (Pedido)" variant="outlined" density="compact" hide-details clearable class="ui-field" />
                        </v-col>

                        <v-col cols="12" md="6"><v-text-field v-model.number="filters.minValue" label="Valor Mín. (R$)" type="number" variant="outlined" density="compact" hide-details class="ui-field" prefix="R$" /></v-col>
                        <v-col cols="12" md="6"><v-text-field v-model.number="filters.maxValue" label="Valor Máx. (R$)" type="number" variant="outlined" density="compact" hide-details class="ui-field" prefix="R$" /></v-col>

                        <v-col cols="12" md="6">
                          <v-autocomplete v-model="filters.chartOfAccountsId" :items="auxData.chartOfAccounts" item-title="name" item-value="id" label="Plano de Contas" variant="outlined" density="compact" hide-details clearable class="ui-field" />
                        </v-col>

                        <v-col cols="12" md="6" v-if="companyStore.isGlobalView">
                          <v-autocomplete v-model="filters.companyId" :items="auxData.companies" item-title="trade_name" item-value="id" label="Empresa Emissora" variant="outlined" density="compact" hide-details clearable class="ui-field" />
                        </v-col>

                        <v-col cols="12">
                          <div class="text-caption font-weight-black opacity-70 mb-2 mt-2">Status do Título</div>
                          <div class="d-flex flex-wrap" style="gap: 8px;">
                            <v-chip v-for="s in ['em_aberto','pago','atrasado']" :key="s"
                                    :color="filters.status.includes(s) ? (s === 'pago' ? 'success' : (s === 'atrasado' ? 'error' : 'warning')) : 'grey'"
                                    :variant="filters.status.includes(s) ? 'flat' : 'outlined'"
                                    class="solid-chip cursor-pointer font-weight-bold"
                                    @click="toggleStatusFilter(s)">
                              <v-icon start size="small" v-if="filters.status.includes(s)">mdi-check</v-icon>
                              {{ s === 'em_aberto' ? 'Aberto' : (s === 'pago' ? 'Recebido' : 'Atrasado') }}
                            </v-chip>
                          </div>
                        </v-col>
                      </v-row>

                      <div class="d-flex justify-end mt-6">
                        <v-btn variant="flat" class="btn-rect w-100 font-weight-bold" height="42" color="success" @click="applyFiltersFromDropdown">
                          <v-icon start>mdi-check</v-icon> Aplicar Filtros e Buscar
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
                  <div class="grid-header sticky-head" :class="[themeStore.currentMode === 'light' ? 'grid-surface-light' : 'grid-surface-dark', companyStore.isGlobalView ? 'grid-global' : 'grid-local']">
                      <div class="cell cell-ref center header-text">Ref. / Pedido</div>
                      <div class="cell cell-client header-text">Cliente / Pagador</div>
                      <div class="cell cell-desc header-text">Descrição</div>
                      <div class="cell cell-cat center header-text">Plano de Contas</div>
                      <div class="cell cell-company center header-text" v-if="companyStore.isGlobalView">Empresa</div>
                      <div class="cell cell-date center header-text">Vencimento</div>
                      <div class="cell cell-date2 center header-text">Recebimento</div>
                      <div class="cell cell-val center header-text">Valor</div>
                      <div class="cell cell-status center header-text">Status</div>
                  </div>

                  <div v-if="loading" class="d-flex flex-column justify-center align-center h-100 py-10 w-100 min-w-full">
                      <v-progress-circular indeterminate color="success" size="32" width="3"></v-progress-circular>
                  </div>

                  <div v-else-if="paginatedItems.length === 0" class="d-flex flex-column justify-center align-center h-100 py-10 opacity-60 w-100 min-w-full">
                      <v-icon size="48" class="mb-2">mdi-text-box-search-outline</v-icon>
                      <span>Nenhuma conta a receber encontrada para esses filtros.</span>
                  </div>

                  <template v-else>
                      <div v-for="(item, index) in paginatedItems" :key="item.id"
                           class="grid-row"
                           :class="[
                               themeStore.currentMode === 'light' ? 'grid-row-light' : 'grid-row-dark',
                               zebraClass(index),
                               companyStore.isGlobalView ? 'grid-global' : 'grid-local'
                           ]">

                          <div class="cell cell-ref center">
                              <span v-if="item.order_id || (item.order_number && item.order_number !== 'S/N')" class="text-blue-darken-2 font-weight-black font-mono text-[10px]">#{{ item.order_number }}</span>
                              <span v-else class="pill-ref" :class="getRefClass(item)">{{ getRefNumber(item) }}</span>
                          </div>

                          <div class="cell cell-client">
                              <div class="text-truncate list-text-11 font-weight-bold" :title="getCustomerName(item)">{{ getCustomerName(item) }}</div>
                          </div>

                          <div class="cell cell-desc">
                              <div class="d-flex flex-column" style="min-width: 0;">
                                  <div class="text-truncate list-text-11 opacity-70" :title="item.description">
                                      <v-icon v-if="item.is_signal" size="10" color="orange" class="mr-1">mdi-flash</v-icon>
                                      {{ item.description }}
                                  </div>
                              </div>
                          </div>

                          <div class="cell cell-cat center"><span class="text-truncate list-text-11" :title="getChartName(item.chart_of_accounts_id)">{{ getChartName(item.chart_of_accounts_id) || '-' }}</span></div>

                          <div class="cell cell-company center" v-if="companyStore.isGlobalView">
                              <span v-if="item.company_id" class="solid-chip chip-company">{{ getCompanyName(item.company_id) }}</span>
                              <span v-else class="list-text-11 opacity-60">-</span>
                          </div>

                          <div class="cell cell-date center">
                              <span class="list-text-11 font-mono" :class="isOverdue(item) ? 'text-error font-weight-black' : 'opacity-80'">{{ formatDateSafe(item.due_date) }}</span>
                          </div>

                          <div class="cell cell-date2 center">
                              <span class="list-text-11 font-mono opacity-80">{{ item.payment_date ? formatDateSafe(item.payment_date) : '-' }}</span>
                          </div>

                          <div class="cell cell-val center">
                              <span class="list-text-11 font-mono font-weight-black">{{ formatCurrency(item.value - (item.discount || 0)) }}</span>
                          </div>

                          <div class="cell cell-status center">
                              <span class="solid-chip chip-status" :class="getStatusChipClass(item)">{{ getStatusLabel(item) }}</span>
                          </div>
                      </div>
                  </template>
              </div>

              <div class="flex-shrink-0 border-t px-4 py-2 d-flex align-center justify-space-between bg-white z-20">
                <div class="text-caption opacity-80">
                  <strong>{{ clientSideFilteredItems.length }}</strong> registros no filtro atual
                </div>
                <v-pagination
                  v-model="page"
                  :length="pageCount"
                  :total-visible="5"
                  density="compact"
                  active-color="success"
                  variant="tonal"
                  size="small"
                ></v-pagination>
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
import { format, parseISO, startOfMonth, endOfMonth, startOfWeek, endOfWeek, startOfYear, endOfYear, isBefore, startOfDay } from 'date-fns';

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
const allFetchedItems = ref<any[]>([]);
const filtersDropdownOpen = ref(false);

const page = ref(1);
const itemsPerPage = 50;

const auxData = reactive({
  customers: [] as any[],
  salespeople: [] as any[],
  chartOfAccounts: [] as any[],
  companies: [] as any[]
});

const filters = reactive({
    search: '',
    customStart: firstDay,
    customEnd: lastDay,
    dateType: 'due_date' as 'due_date' | 'payment_date', // PADRÃO LIMPO (Sem Misto)
    customerId: null as any,
    salespersonId: null as any,
    chartOfAccountsId: null as any,
    status: [] as string[],
    companyId: null as any,
    minValue: null as number | null,
    maxValue: null as number | null,
});

const setCompanyFilter = (id: string | null) => {
    filters.companyId = id;
    page.value = 1;
    fetchData();
};

const quickPeriodOptions = [
    { label: 'Hoje', value: 'today' },
    { label: 'Esta Semana', value: 'week' },
    { label: 'Este Mês', value: 'month' },
    { label: 'Este Ano', value: 'year' },
];

const applyPreset = (preset: string) => {
    const today = new Date();
    if (preset === 'today') {
        filters.customStart = format(today, 'yyyy-MM-dd');
        filters.customEnd = format(today, 'yyyy-MM-dd');
    } else if (preset === 'week') {
        filters.customStart = format(startOfWeek(today, { weekStartsOn: 1 }), 'yyyy-MM-dd');
        filters.customEnd = format(endOfWeek(today, { weekStartsOn: 1 }), 'yyyy-MM-dd');
    } else if (preset === 'month') {
        filters.customStart = format(startOfMonth(today), 'yyyy-MM-dd');
        filters.customEnd = format(endOfMonth(today), 'yyyy-MM-dd');
    } else if (preset === 'year') {
        filters.customStart = format(startOfYear(today), 'yyyy-MM-dd');
        filters.customEnd = format(endOfYear(today), 'yyyy-MM-dd');
    }
    page.value = 1;
    fetchData();
};

const activeFilterCount = computed(() => {
  let c = 0;
  if (filters.customerId) c++;
  if (filters.chartOfAccountsId) c++;
  if (filters.status.length > 0) c++;
  if (filters.companyId) c++;
  if (filters.salespersonId) c++;
  if (filters.minValue || filters.maxValue) c++;
  return c;
});

const buildQuery = (query: any) => {
    const { customStart, customEnd, dateType } = filters;
    const todayStr = format(new Date(), 'yyyy-MM-dd');

    // 1. DATA DIRETA
    const dateField = dateType === 'payment_date' ? 'payment_date' : 'due_date';
    if (customStart) query = query.gte(dateField, customStart);
    if (customEnd) query = query.lte(dateField, customEnd);

    // 2. EMPRESA
    if (!companyStore.isGlobalView && companyStore.context) {
        query = query.eq('company_id', companyStore.context);
    } else if (filters.companyId) {
        query = query.eq('company_id', filters.companyId);
    }

    // 3. PESQUISA GLOBAL ISOLADA
    if (filters.search && filters.search.trim() !== '') {
        const term = filters.search.trim();
        const val = Number(term);
        if (!isNaN(val) && isFinite(val) && term.length < 10) {
             query = query.or(`value.eq.${val},id.eq.${val}`);
        } else {
             query = query.or(`description.ilike.%${term}%,entity_name.ilike.%${term}%`);
        }
    }

    // 4. RESTANTE DOS FILTROS (AND)
    if (filters.customerId) query = query.eq('customer_id', filters.customerId);
    if (filters.chartOfAccountsId) query = query.eq('chart_of_accounts_id', filters.chartOfAccountsId);
    if (filters.minValue) query = query.gte('value', filters.minValue);
    if (filters.maxValue) query = query.lte('value', filters.maxValue);

    // 5. INTELIGÊNCIA DE STATUS
    if (filters.status.length > 0) {
        const wantsPago = filters.status.includes('pago');
        const wantsAberto = filters.status.includes('em_aberto');
        const wantsAtrasado = filters.status.includes('atrasado');

        let orConditions = [];

        if (wantsPago) {
            orConditions.push(`status.eq.pago`);
        }
        if (wantsAberto) {
            // Em Aberto real (status em_aberto e data de vencimento >= hoje)
            orConditions.push(`and(status.eq.em_aberto,due_date.gte.${todayStr})`);
        }
        if (wantsAtrasado) {
            // Atrasado real (status em_aberto e data de vencimento < hoje)
            orConditions.push(`and(status.eq.em_aberto,due_date.lt.${todayStr})`);
        }

        if (orConditions.length > 0) {
            query = query.or(orConditions.join(','));
        }
    }
    return query;
};

const fetchData = async () => {
    loading.value = true;
    allFetchedItems.value = [];
    filtersDropdownOpen.value = false;

    try {
        const selectString = `
            *,
            chart_of_accounts:finance_chart_of_accounts(name),
            orders!left(id, order_number, created_by, customer_name, customer_id)
        `;

        const fetchAllPages = async (buildQ: () => any) => {
            let aggregatedData: any[] = [];
            let from = 0;
            const step = 900;
            let hasMore = true;
            let safetyCounter = 0;

            while (hasMore && safetyCounter < 50) {
                safetyCounter++;
                const to = from + step - 1;
                const q = buildQ().range(from, to);
                const { data: chunk, error } = await q;

                if (error) throw error;

                if (chunk && chunk.length > 0) {
                    aggregatedData = aggregatedData.concat(chunk);
                    if (chunk.length < step) hasMore = false;
                    else from += step;
                } else {
                    hasMore = false;
                }
            }
            return aggregatedData;
        };

        const getFinanceQuery = () => {
            let query = supabase.from('finance_receivables').select(selectString);
            query = buildQuery(query);
            return query.order('due_date', { ascending: true }).order('id', { ascending: true });
        };
        const financeData = await fetchAllPages(getFinanceQuery);

        let signalsRaw: any[] = [];
        const isSignalsAllowed = companyStore.isGlobalView;
        const statusAllowsSignals = filters.status.length === 0 || filters.status.includes('pago');

        if (isSignalsAllowed && statusAllowsSignals) {
const getSignalsQuery = () => {
             let signalQuery = supabase.from('order_payments')
                .select(`*, orders!inner(id, order_number, customer_name, created_by, customer_id)`);

             // CORREÇÃO: order_payments não tem due_date, então sempre filtramos por payment_date (ou created_at se preferir)
             const dateField = 'payment_date';

             if(filters.customStart) signalQuery = signalQuery.gte(dateField, filters.customStart);
             if(filters.customEnd) signalQuery = signalQuery.lte(dateField, filters.customEnd);

             if (filters.customerId) signalQuery = signalQuery.eq('orders.customer_id', filters.customerId);
             if (filters.minValue) signalQuery = signalQuery.gte('amount', filters.minValue);
             if (filters.maxValue) signalQuery = signalQuery.lte('amount', filters.maxValue);

             return signalQuery.order('payment_date', { ascending: true }).order('id', { ascending: true });
         };
             signalsRaw = await fetchAllPages(getSignalsQuery);
        }

        const allCustomerIds = new Set<string>();
        financeData?.forEach((item: any) => {
            if (item.customer_id) allCustomerIds.add(item.customer_id);
            if (item.orders?.customer_id) allCustomerIds.add(item.orders.customer_id);
        });
        signalsRaw.forEach((s: any) => {
            if (s.orders?.customer_id) allCustomerIds.add(s.orders.customer_id);
        });

        const customerMap = new Map();
        if (allCustomerIds.size > 0) {
            const customerIdsArray = Array.from(allCustomerIds);
            const chunkSize = 500;
            for (let i = 0; i < customerIdsArray.length; i += chunkSize) {
                 const chunk = customerIdsArray.slice(i, i + chunkSize);
                 const { data: customers } = await supabase.from('customers_mj').select('id, nome, vendedor_responsavel_id').in('id', chunk);
                 if (customers) customers.forEach(c => customerMap.set(c.id, c));
            }
        }

        const financeEnriched = (financeData || []).map((item: any) => {
            const cId = item.customer_id || item.orders?.customer_id;
            return { ...item, customer: customerMap.get(cId) };
        });

        const signalsEnriched = signalsRaw.map((s: any) => {
            const orderObj = s.orders || {};
            const cId = orderObj.customer_id;
            const cData = customerMap.get(cId);
            const nomeCliente = cData?.nome || orderObj.customer_name || 'Cliente';

            return {
                id: s.id,
                is_signal: true,
                description: s.notes || `Sinal Pedido #${orderObj.order_number || 'S/N'}`,
                entity_name: nomeCliente,
                value: s.amount,
                discount: 0,
                due_date: s.payment_date,
                payment_date: s.payment_date,
                status: 'pago',
                attachments: s.receipt_url ? [s.receipt_url] : [],
                chart_of_accounts_id: null,
                notes: `Ref. Pedido ${s.order_id}`,
                order_id: s.order_id,
                order_number: orderObj.order_number,
                created_by: orderObj.created_by,
                customer: cData
            };
        });

        let combined = [...financeEnriched, ...signalsEnriched];

        if (filters.salespersonId) {
            combined = combined.filter(item => {
                const createdBy = item.orders?.created_by || item.created_by;
                const walletOwner = item.customer?.vendedor_responsavel_id;
                return createdBy === filters.salespersonId || walletOwner === filters.salespersonId;
            });
        }

        combined.sort((a, b) => new Date(a.due_date).getTime() - new Date(b.due_date).getTime());

        const mappedItems = combined.map(i => {
             let orderNum = 'S/N';
             if (i.orders && i.orders.order_number) orderNum = i.orders.order_number;
             if (i.order_number && (!orderNum || orderNum === 'S/N')) orderNum = i.order_number;
             return { ...i, order_number: orderNum };
        });

        allFetchedItems.value = mappedItems;
        page.value = 1;

    } catch (e: any) {
        console.error('Fetch Error:', e);
        appStore.showSnackbar('Erro: ' + e.message, 'error');
    } finally {
        loading.value = false;
    }
};

const fetchAuxiliaryData = async () => {
  try { const { data } = await supabase.from('customers_mj').select('id, nome'); if (data) auxData.customers = data.map(c => ({ id: c.id, name: c.nome })); } catch {}
  try { const { data } = await supabase.from('profiles').select('id, full_name').or('role.eq.vendedor,role.eq.admin'); if(data) auxData.salespeople = data; } catch {}
  try { const { data } = await supabase.from('finance_chart_of_accounts').select('id, name').eq('type', 'Receita').order('name'); if (data) auxData.chartOfAccounts = data; } catch {}
  try { const { data } = await supabase.from('companies').select('id, trade_name, name'); if (data) auxData.companies = data; } catch {}
};

// -- HELPERS DE EXIBIÇÃO --
const formatCurrency = (v: any) => new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(Number(v)||0);
const formatDateSafe = (dateString: string) => {
    if (!dateString) return '-';
    return dateString.split('T')[0].split('-').reverse().join('/');
};

const isOverdue = (i:any) => i.status!=='pago' && i.due_date < format(new Date(), 'yyyy-MM-dd');
const getStatusLabel = (i:any) => i.status==='pago'?'Recebido':(isOverdue(i)?'Atrasado':'Aberto');
const getStatusChipClass = (i:any) => i.status==='pago'?'chip-success':(isOverdue(i)?'chip-danger':'chip-warn');
const getRefNumber = (i:any) => i.gestao_click_id || (i.id ? String(i.id).substring(0,6).toUpperCase() : '-');
const getRefClass = (i:any) => i.is_signal ? 'bg-orange-lighten-4 text-orange-darken-4' : (i.gestao_click_id ? 'text-teal-darken-3 bg-teal-lighten-5' : 'bg-grey-lighten-4');
const getChartName = (id:any) => auxData.chartOfAccounts.find(c=>c.id===id)?.name || '-';
const getCompanyName = (id:any) => auxData.companies.find(c=>c.id===id)?.trade_name || '-';
const zebraClass = (i:number) => themeStore.currentMode!=='light' ? (i%2===0?'zebra-dark-a':'zebra-dark-b') : (i%2===0?'zebra-light-a':'zebra-light-b');

const getCustomerName = (i:any) => {
    if (i.entity_name) return i.entity_name;
    if (i.customer?.nome) return i.customer.nome;
    if (i.customer_id) return auxData.customers.find(c=>c.id===i.customer_id)?.name || 'Cliente';
    return 'Cliente';
};

// --- PESQUISA LOCAL & PAGINAÇÃO ---
const clientSideFilteredItems = computed(() => {
    // O banco já resolve o conflito dos status perfeitamente, só precisamos do filtro de texto aqui.
    let result = allFetchedItems.value;
    const term = filters.search.trim().toLowerCase();

    if (term) {
        result = result.filter(item => {
            const desc = item.description ? item.description.toLowerCase() : '';
            const name = getCustomerName(item).toLowerCase();
            const orderRef = item.order_number ? String(item.order_number).toLowerCase() : '';
            const val = String(item.value);

            return desc.includes(term) || name.includes(term) || orderRef.includes(term) || val.includes(term);
        });
    }
    return result;
});

const paginatedItems = computed(() => {
    const start = (page.value - 1) * itemsPerPage;
    const end = start + itemsPerPage;
    return clientSideFilteredItems.value.slice(start, end);
});

const pageCount = computed(() => Math.ceil(clientSideFilteredItems.value.length / itemsPerPage));

const kpis = computed(() => {
    let pago = 0; let pendente = 0;

    clientSideFilteredItems.value.forEach(t => {
        const val = Number(t.value) - Number(t.discount || 0);
        if (t.status === 'pago') pago += val; else pendente += val;
    });
    return { totalPago: pago, totalPendente: pendente, totalGeral: pago + pendente };
});

const handleSearchEnter = () => { page.value = 1; };
const toggleStatusFilter = (s: string) => { const idx = filters.status.indexOf(s); if (idx >= 0) filters.status.splice(idx, 1); else filters.status.push(s); };
const clearFilters = () => {
    filters.search = ''; filters.customerId = null; filters.chartOfAccountsId = null; filters.salespersonId = null;
    filters.status = []; filters.companyId = null; filters.minValue = null; filters.maxValue = null;
    filters.dateType = 'due_date';
    applyPreset('month');
};
const applyFiltersFromDropdown = () => { fetchData(); };
watch(() => companyStore.context, () => { fetchData(); });

// =========================================================================
// SISTEMA DE EXPORTAÇÃO (AGRUPADO E LISTA CORRIDA DELICADA)
// =========================================================================
const groupDataByCustomer = (data: any[]) => {
    const groups = new Map<string, { items: any[], subtotal: number, pago: number, pendente: number, atrasado: number }>();
    const todayStr = format(new Date(), 'yyyy-MM-dd');

    data.forEach(item => {
        const clientName = getCustomerName(item).toUpperCase();
        const val = Number(item.value) - Number(item.discount || 0);
        const isPaid = item.status === 'pago';

        if (!groups.has(clientName)) {
            groups.set(clientName, { items: [], subtotal: 0, pago: 0, pendente: 0, atrasado: 0 });
        }

        const group = groups.get(clientName)!;
        group.items.push(item);
        group.subtotal += val;

        if (isPaid) group.pago += val;
        else if (item.due_date < todayStr) group.atrasado += val;
        else group.pendente += val;
    });

    return Array.from(groups.entries()).sort((a, b) => a[0].localeCompare(b[0]));
};

const generateReport = async (type: 'pdf_list' | 'pdf_grouped' | 'excel' | 'print_list' | 'print_grouped') => {
    reportLoading.value = true;
    const dataToExport = clientSideFilteredItems.value;

    if (dataToExport.length === 0) {
        appStore.showSnackbar('Nenhum dado para exportar', 'warning');
        reportLoading.value = false;
        return;
    }

    const todayStr = format(new Date(), 'yyyy-MM-dd');
    const companyNameLabel = companyStore.isGlobalView ? 'VISÃO GLOBAL - HOLDING' : companyStore.currentCompanyName.toUpperCase();

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

    // ==========================================
    // EXCEL
    // ==========================================
    if (type === 'excel') {
        const ws = XLSX.utils.json_to_sheet(dataToExport.map(i => ({
            Ref: i.order_number || getRefNumber(i),
            DataVencimento: formatDateSafe(i.due_date),
            DataRecebimento: i.payment_date ? formatDateSafe(i.payment_date) : '-',
            Cliente: getCustomerName(i),
            Descricao: i.description,
            PlanoContas: getChartName(i.chart_of_accounts_id),
            Status: getStatusLabel(i),
            Valor: Number(i.value) - Number(i.discount || 0),
            Empresa: getCompanyName(i.company_id),
            Observacoes: i.notes || ''
        })));
        const wb = XLSX.utils.book_new();
        XLSX.utils.book_append_sheet(wb, ws, "ContasReceber");
        XLSX.writeFile(wb, `Relatorio_Receber_${format(new Date(), 'dd-MM-yyyy')}.xlsx`);
        appStore.showSnackbar('Excel Gerado com Sucesso!', 'success');
        reportLoading.value = false;
        return;
    }

    // CALCULAR KPIS
    let totalVal = 0, openVal = 0, overdueVal = 0, paidVal = 0;
    dataToExport.forEach(row => {
        const val = Number(row.value) - Number(row.discount || 0);
        totalVal += val;
        if (row.status === 'pago') paidVal += val;
        else { if (row.due_date < todayStr) overdueVal += val; else openVal += val; }
    });

    // PALETA DE CORES POR CLIENTE (Alternadas)
    const clientColorsPDF = [
        [224, 242, 254], // Azul Claro
        [243, 232, 255], // Roxo Claro
        [254, 226, 226], // Vermelho Claro
        [220, 252, 231], // Verde Claro
        [254, 249, 195], // Amarelo Claro
    ];
    const clientColorsHTML = ['#e0f2fe', '#f3e8ff', '#fee2e2', '#dcfce7', '#fef9c3'];

    // ==========================================
    // PDF (JSPDF + AUTOTABLE) - LAYOUT ROMANEIO
    // ==========================================
    if (type.startsWith('pdf')) {
        const isGrouped = type === 'pdf_grouped';
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
        doc.text("CONTAS A RECEBER " + (isGrouped ? "(POR CLIENTE)" : ""), M + 42, M + 8);

        doc.setFont("helvetica", "normal");
        doc.setFontSize(9);
        doc.text(`Empresa: ${companyNameLabel}`, M + 42, M + 14);
        doc.text(`Período: ${formatDateSafe(filters.customStart)} a ${formatDateSafe(filters.customEnd)}`, M + 42, M + 19);
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
        drawKpi("A RECEBER", formatCurrency(openVal), 1);
        drawKpi("ATRASADO", formatCurrency(overdueVal), 2);
        drawKpi("RECEBIDO", formatCurrency(paidVal), 3);

        // CAIXA DE LEGENDA
        const legY = kpiY + kpiH + 4;
        doc.setFillColor(255, 255, 255);
        doc.rect(M, legY, boxW, 8, 'FD');
        doc.setFont("helvetica", "bold");
        doc.setFontSize(8);
        doc.text("LEGENDA:   [ ] Caixa para Baixa Manual   |   [Verde] Recebido   |   [Branco] Em Aberto   |   [Vermelho] Atrasado", pageW / 2, legY + 5.5, { align: "center" });

        let finalY = legY + 12;

        const columns = [
            { header: 'BAIXA', dataKey: 'check' },
            { header: 'REF/PED', dataKey: 'ref' },
            { header: 'VENCIMENTO', dataKey: 'date' },
            ...(isGrouped ? [] : [{ header: 'CLIENTE', dataKey: 'client' }]),
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

        if (isGrouped) {
            const groupedData = groupDataByCustomer(dataToExport);
            let colorIdx = 0;

            for (const [clientName, groupData] of groupedData) {
                if (finalY > pageH - 35) { doc.addPage(); finalY = 15; }

                const bgColor = clientColorsPDF[colorIdx % clientColorsPDF.length];
                colorIdx++;

                doc.setFillColor(...bgColor);
                doc.setDrawColor(50, 50, 50);
                doc.rect(M, finalY, boxW, 7, 'FD'); // Fundo e Borda explícita do Cliente

                doc.setFontSize(9).setFont('helvetica', 'bold').setTextColor(0);
                doc.text(`CLIENTE: ${clientName}`, M + 2, finalY + 5);
                doc.text(`SUBTOTAL: ${formatCurrency(groupData.subtotal)}`, M + boxW - 2, finalY + 5, { align: 'right' });

                finalY += 7;

                const tableBody = groupData.items.map(row => {
                    const val = Number(row.value) - Number(row.discount || 0);
                    const isPaid = row.status === 'pago';
                    let rowColor = [255, 255, 255];
                    if (isPaid) rowColor = [236, 253, 245];
                    else if (row.due_date < todayStr) rowColor = [254, 242, 242];

                    return {
                        check: '', ref: row.order_number || getRefNumber(row),
                        date: formatDateSafe(row.due_date), desc: (row.description || '').substring(0, 45),
                        company: companyStore.isGlobalView ? getCompanyName(row.company_id).substring(0, 15) : '',
                        status_label: getStatusLabel(row).toUpperCase(), value: formatCurrency(val), _rowColor: rowColor
                    };
                });

                autoTable(doc, {
                    startY: finalY, columns: columns.filter(c => c.dataKey !== 'client'), body: tableBody,
                    theme: 'grid', tableWidth: boxW, margin: { left: M, right: M },
                    styles: { fontSize: 7, cellPadding: 2, lineColor: [50, 50, 50], lineWidth: 0.2, textColor: 0 },
                    headStyles: { fillColor: [230, 230, 230], textColor: 0, fontStyle: 'bold' },
                    columnStyles: { check: { cellWidth: 12, halign: 'center' }, value: { halign: 'right', fontStyle: 'bold' } },
                    didDrawCell: drawCheckbox,
                    didParseCell: (data) => { if (data.section === 'body' && (data.row.raw as any)._rowColor) data.cell.styles.fillColor = (data.row.raw as any)._rowColor; }
                });
                finalY = (doc as any).lastAutoTable.finalY + 4;
            }
        } else {
            const tableBody = dataToExport.map(row => {
                const val = Number(row.value) - Number(row.discount || 0);
                const isPaid = row.status === 'pago';
                let rowColor = [255, 255, 255];
                if (isPaid) rowColor = [236, 253, 245];
                else if (row.due_date < todayStr) rowColor = [254, 242, 242];

                return {
                    check: '', ref: row.order_number || getRefNumber(row), date: formatDateSafe(row.due_date),
                    client: getCustomerName(row).substring(0, 25), desc: (row.description || '').substring(0, 30),
                    company: companyStore.isGlobalView ? getCompanyName(row.company_id).substring(0, 15) : '',
                    status_label: getStatusLabel(row).toUpperCase(), value: formatCurrency(val), _rowColor: rowColor
                };
            });

            autoTable(doc, {
                startY: finalY, columns: columns, body: tableBody, theme: 'grid',
                tableWidth: boxW, margin: { left: M, right: M },
                styles: { fontSize: 7, cellPadding: 2, lineColor: [50, 50, 50], lineWidth: 0.2, textColor: 0 },
                headStyles: { fillColor: [230, 230, 230], textColor: 0, fontStyle: 'bold' },
                columnStyles: { check: { cellWidth: 12, halign: 'center' }, value: { halign: 'right', fontStyle: 'bold' } },
                didDrawCell: drawCheckbox,
                didParseCell: (data) => { if (data.section === 'body' && (data.row.raw as any)._rowColor) data.cell.styles.fillColor = (data.row.raw as any)._rowColor; }
            });
        }

        const totalPages = doc.internal.getNumberOfPages();
        for (let i = 1; i <= totalPages; i++) {
            doc.setPage(i);
            doc.setFontSize(7).setTextColor(150);
            doc.text(`Gerado com MJProcess`, pageW - M, pageH - 5, { align: "right" });
        }

        doc.save(`Contas_Receber_${format(new Date(), 'yyyyMMdd')}.pdf`);
        appStore.showSnackbar('PDF Gerado com Sucesso!', 'success');

    // ==========================================
    // IMPRESSÃO HTML (COM BORDAS ESCURAS)
    // ==========================================
    } else if (type.startsWith('print')) {
        const isGrouped = type === 'print_grouped';
        const printWindow = window.open('', '_blank');
        if (!printWindow) {
            appStore.showSnackbar('Permita a abertura de pop-ups.', 'warning');
            reportLoading.value = false; return;
        }

        const columnCount = isGrouped ? (companyStore.isGlobalView ? 7 : 6) : (companyStore.isGlobalView ? 8 : 7);
        const companyColHead = companyStore.isGlobalView ? `<th class="text-center">Empresa</th>` : '';

        let rowsHtml = '';

        const generateRowHtml = (row: any) => {
            const val = Number(row.value) - Number(row.discount || 0);
            const isPaid = row.status === 'pago';
            const isOverdue = !isPaid && row.due_date < todayStr;

            let rowClass = 'row-open';
            if (isPaid) rowClass = 'row-paid';
            else if (isOverdue) rowClass = 'row-overdue';

            const companyHtml = companyStore.isGlobalView ? `<td class="text-center">${getCompanyName(row.company_id)}</td>` : '';
            const clientHtml = !isGrouped ? `<td>${getCustomerName(row)}</td>` : '';

            return `
                <tr class="${rowClass}">
                    <td class="text-center"><div class="checkbox-box"></div></td>
                    <td class="text-center">${formatDateSafe(row.due_date)}</td>
                    <td class="text-center font-bold">${row.order_number || getRefNumber(row)}</td>
                    ${clientHtml}
                    <td>${row.description || '-'}</td>
                    ${companyHtml}
                    <td class="text-center font-bold status-${row.status}">${getStatusLabel(row).toUpperCase()}</td>
                    <td class="text-right font-bold">${formatCurrency(val)}</td>
                </tr>
            `;
        };

        if (isGrouped) {
            const groupedData = groupDataByCustomer(dataToExport);
            let colorIdx = 0;

            for (const [clientName, groupData] of groupedData) {
                const bgHtml = clientColorsHTML[colorIdx % clientColorsHTML.length];
                colorIdx++;

                rowsHtml += `
                    <tr class="group-header" style="background-color: ${bgHtml} !important;">
                        <td colspan="${columnCount}">
                            <div class="flex-between">
                                <span>CLIENTE: ${clientName}</span>
                                <span>SUBTOTAL: ${formatCurrency(groupData.subtotal)}</span>
                            </div>
                        </td>
                    </tr>
                `;
                groupData.items.forEach(row => { rowsHtml += generateRowHtml(row); });
            }
        } else {
            dataToExport.forEach(row => { rowsHtml += generateRowHtml(row); });
        }

        const html = `
            <!DOCTYPE html>
            <html lang="pt-BR">
            <head>
                <meta charset="UTF-8">
                <title>Romaneio - Contas a Receber</title>
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
                    .flex-between { display: flex; justify-content: space-between; align-items: center; width: 100%; font-weight: 800; }

                    .checkbox-box { width: 12px; height: 12px; border: 1.5px solid var(--border); margin: 0 auto; background: #fff; }

                    /* Backgrounds que forçam cor na impressão */
                    .row-paid { background-color: #dcfce7 !important; }
                    .row-overdue { background-color: #fee2e2 !important; }
                    .row-open { background-color: #ffffff !important; }
                    .group-header td { border-top: 2px solid var(--border) !important; font-size: 11px; }

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
                        <h1>CONTAS A RECEBER ${isGrouped ? '(POR CLIENTE)' : ''}</h1>
                        <p>Empresa: ${companyNameLabel}</p>
                        <p>Período: ${formatDateSafe(filters.customStart)} a ${formatDateSafe(filters.customEnd)}</p>
                        <p>Filtro: ${filters.status.length ? filters.status.join(', ').toUpperCase() : 'TODOS'}</p>
                    </div>
                </div>

                <div class="kpi-container">
                    <div class="kpi-card"><div class="kpi-title">Total Geral</div><div class="kpi-val">${formatCurrency(totalVal)}</div></div>
                    <div class="kpi-card"><div class="kpi-title">A Receber</div><div class="kpi-val">${formatCurrency(openVal)}</div></div>
                    <div class="kpi-card"><div class="kpi-title">Atrasados</div><div class="kpi-val">${formatCurrency(overdueVal)}</div></div>
                    <div class="kpi-card"><div class="kpi-title">Recebidos</div><div class="kpi-val">${formatCurrency(paidVal)}</div></div>
                </div>

                <div class="legend-box">
                    LEGENDA: &nbsp; [ ] Caixa para Baixa Manual &nbsp; | &nbsp; 🟩 Verde = Recebido &nbsp; | &nbsp; ⬜ Branco = Em Aberto &nbsp; | &nbsp; 🟥 Vermelho = Atrasado
                </div>

                <table>
                    <thead>
                        <tr>
                            <th class="text-center" style="width: 40px;">Baixa</th>
                            <th class="text-center" style="width: 80px;">Vencimento</th>
                            <th class="text-center" style="width: 70px;">Pedido</th>
                            ${!isGrouped ? '<th>Cliente</th>' : ''}
                            <th>Descrição</th>
                            ${companyColHead}
                            <th class="text-center" style="width: 80px;">Status</th>
                            <th class="text-right" style="width: 100px;">Valor</th>
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
    applyPreset('month');
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

.kpi-label { font-size: 12px; font-weight: 900; letter-spacing: .2px; }
.kpi-value { font-size: 24px; font-weight: 900; letter-spacing: .2px; }

.grid-global { grid-template-columns: 90px minmax(200px, 1.5fr) minmax(200px, 1.5fr) 140px 110px 120px 120px 120px 110px; min-width: 1400px; }
.grid-local  { grid-template-columns: 90px minmax(200px, 1.5fr) minmax(200px, 1.5fr) 140px 120px 120px 120px 110px; minwidth: 1300px; }

.cell { padding: 8px 10px; display: flex; align-items: center; border-right: 1px solid rgba(0,0,0,0.08); border-bottom: 1px solid rgba(0,0,0,0.08); min-height: 56px; overflow: hidden; }
.center { justify-content: center; text-align: center; }
.right { justify-content: flex-end; text-align: right; }

.header-text { font-size: 11px; font-weight: 900; text-transform: uppercase; letter-spacing: 0.5px; opacity: 0.8; padding: 12px 8px; }
.grid-header { display: grid; align-items: stretch; width: 100%; border-bottom: 1px solid rgba(0,0,0,0.08); position: sticky; top: 0; z-index: 10; }
.grid-row { display: grid; align-items: stretch; width: 100%; }

.grid-surface-light .cell { background: #f5f7fa; color: rgba(0,0,0,0.7); }
.grid-surface-dark .cell { background: rgba(255,255,255,0.08); color: rgba(255,255,255,0.80); }

.grid-row-light .cell { background: #fff; }
.grid-row-light:hover .cell { background: #f7fafc; }
.grid-row-dark .cell { background: rgba(255,255,255,0.04); }
.grid-row-dark:hover .cell { background: rgba(255,255,255,0.07); }

.zebra-light-a .cell { background: #fff; }
.zebra-light-b .cell { background: #fafafa; }
.zebra-dark-a .cell { background: rgba(255,255,255,0.03); }
.zebra-dark-b .cell { background: rgba(255,255,255,0.06); }

.shadow-indigo-soft { box-shadow: 0 4px 15px rgba(63, 81, 181, 0.4); }
.custom-scroll::-webkit-scrollbar { width: 8px; height: 8px; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.35); border-radius: 6px; }

.list-text-11 { font-size: 11px !important; line-height: 1.25 !important; }

.pill-ref { font-size: 10px; font-weight: 900; font-family: monospace; padding: 4px 8px; border-radius: 6px; }
.solid-chip { display: inline-flex; align-items: center; justify-content: center; height: 22px; padding: 0 10px; border-radius: 8px; font-size: 10px; font-weight: 900; color: #fff; text-transform: uppercase; }
.chip-status { min-width: 84px; }
.chip-company { background: #455a64; }
.chip-success { background: #2e7d32; }
.chip-warn { background: #f57f17; }
.chip-danger { background: #c62828; }
.row-gap { row-gap: 12px; }
</style>
