<template>
  <div
    class="financial-report-layout font-sans fill-height d-flex flex-column position-relative overflow-hidden"
    :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 text-grey-darken-4' : 'bg-glass-dark text-white'"
  >
    <!-- Background Carousel -->
    <div v-if="themeStore.currentMode !== 'light'" class="background-carousel-wrapper">
      <v-carousel cycle height="100%" hide-delimiters :show-arrows="false" interval="15000" class="fill-height">
        <v-carousel-item src="@/assets/1.jpg" cover></v-carousel-item>
        <v-carousel-item src="@/assets/2.jpg" cover></v-carousel-item>
        <v-carousel-item src="@/assets/3.jpg" cover></v-carousel-item>
      </v-carousel>
      <div class="background-overlay"></div>
    </div>

    <div class="content-wrapper d-flex flex-column fill-height z-10 position-relative">

      <!-- Header -->
      <div
          class="header-bar px-4 px-md-6 py-3 py-md-4 d-flex flex-column flex-md-row align-md-start justify-space-between flex-shrink-0"
          :class="themeStore.currentMode === 'light' ? 'bg-white border-b border-grey-lighten-2 shadow-sm' : 'bg-glass-header border-bottom-white-05'"
      >
          <div class="d-flex flex-column" style="max-width: calc(100vw - 32px);">
              <div class="breadcrumb text-caption d-none d-md-block">
                  <span class="opacity-70 cursor-pointer hover-underline" @click="$router.push('/admin/reports')">Relatórios</span>
                  <span class="mx-2 opacity-50">></span>
                  <span class="font-weight-bold">Financeiro & Compliance</span>
              </div>
              <div class="d-flex align-center mt-1" style="gap: 8px;">
                 <v-btn class="d-md-none mr-1" icon="mdi-arrow-left" variant="text" size="small" @click="$router.back()"></v-btn>
                 <div class="text-h6 font-weight-black tracking-tight leading-none text-truncate" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">
                    Auditoria de Preços de Venda
                 </div>
              </div>

              <!-- Multi-Tenant Tabs (Filtros Rápidos de Empresa) -->
              <div class="d-flex align-center mt-3 overflow-x-auto hide-scrollbar pb-1 w-100" style="gap: 12px;">
                 <v-btn
                    size="x-small"
                    height="24"
                    :variant="filters.companyName === 'ALL' ? 'flat' : 'tonal'"
                    :color="filters.companyName === 'ALL' ? 'purple' : 'grey'"
                    class="font-weight-bold btn-3d px-3 rounded-pill flex-shrink-0"
                    style="font-size: 10px; letter-spacing: 0.5px;"
                    @click="filters.companyName = 'ALL'"
                 >
                    VISÃO GLOBAL
                 </v-btn>
                 <v-btn
                    size="x-small"
                    height="24"
                    :variant="filters.companyName === 'SANTOS & LOPES' ? 'flat' : 'tonal'"
                    :color="filters.companyName === 'SANTOS & LOPES' ? 'warning' : 'grey'"
                    class="font-weight-bold btn-3d px-3 rounded-pill flex-shrink-0"
                    style="font-size: 10px; letter-spacing: 0.5px;"
                    @click="filters.companyName = 'SANTOS & LOPES'"
                 >
                    SANTOS & LOPES
                 </v-btn>
                 <v-btn
                    size="x-small"
                    height="24"
                    :variant="filters.companyName === 'MR JACKY' ? 'flat' : 'tonal'"
                    :color="filters.companyName === 'MR JACKY' ? 'info' : 'grey'"
                    class="font-weight-bold btn-3d px-3 rounded-pill flex-shrink-0"
                    style="font-size: 10px; letter-spacing: 0.5px;"
                    @click="filters.companyName = 'MR JACKY'"
                 >
                    MR JACKY
                 </v-btn>
              </div>
          </div>
      </div>

      <!-- KPIs (Agora com 5 colunas fluidas) -->
      <div class="px-4 px-md-6 pt-4 pb-0 flex-shrink-0">
          <v-row dense class="flex-nowrap overflow-x-auto hide-scrollbar">
              <v-col cols="12" sm="4" lg="auto" class="flex-grow-1" style="min-width: 220px;">
                  <v-card class="kpi-card bg-gradient-primary hover-elevate py-3 px-4" elevation="2">
                      <div class="kpi-bg-icon"><v-icon>mdi-tag-text-outline</v-icon></div>
                      <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                          <span class="kpi-label">Valor Tabela (Esperado)</span>
                          <span class="kpi-value text-h5 font-weight-black my-1">{{ formatCurrency(kpis.expectedTotal) }}</span>
                      </div>
                  </v-card>
              </v-col>

              <v-col cols="12" sm="4" lg="auto" class="flex-grow-1" style="min-width: 220px;">
                  <v-card class="kpi-card bg-gradient-info hover-elevate py-3 px-4" elevation="2">
                      <div class="kpi-bg-icon"><v-icon>mdi-cash-register</v-icon></div>
                      <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                          <span class="kpi-label">Valor Faturado (Real)</span>
                          <span class="kpi-value text-h5 font-weight-black my-1">{{ formatCurrency(kpis.actualTotal) }}</span>
                      </div>
                  </v-card>
              </v-col>

              <!-- NOVO KPI: Total Recebido -->
              <v-col cols="12" sm="4" lg="auto" class="flex-grow-1" style="min-width: 220px;">
                  <v-card class="kpi-card bg-gradient-purple hover-elevate py-3 px-4" elevation="2">
                      <div class="kpi-bg-icon"><v-icon>mdi-cash-check</v-icon></div>
                      <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                          <div class="d-flex align-center justify-space-between">
                              <span class="kpi-label">Total Recebido (Pago)</span>
                              <v-tooltip activator="parent" location="top">Soma do 'paid_value' nas contas a receber destes pedidos.</v-tooltip>
                          </div>
                          <span class="kpi-value text-h5 font-weight-black my-1">{{ formatCurrency(kpis.totalReceived) }}</span>
                      </div>
                  </v-card>
              </v-col>

              <v-col cols="12" sm="4" lg="auto" class="flex-grow-1" style="min-width: 220px;">
                  <v-card class="kpi-card bg-gradient-danger hover-elevate py-3 px-4" elevation="2">
                      <div class="kpi-bg-icon"><v-icon>mdi-trending-down</v-icon></div>
                      <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                          <span class="kpi-label">Perda (Desconto/Erro)</span>
                          <span class="kpi-value text-h5 font-weight-black my-1">{{ formatCurrency(kpis.totalLoss) }}</span>
                      </div>
                  </v-card>
              </v-col>

              <v-col cols="12" sm="4" lg="auto" class="flex-grow-1" style="min-width: 220px;">
                  <v-card class="kpi-card bg-gradient-success hover-elevate py-3 px-4" elevation="2">
                      <div class="kpi-bg-icon"><v-icon>mdi-trending-up</v-icon></div>
                      <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                          <span class="kpi-label">Acréscimo na Venda</span>
                          <span class="kpi-value text-h5 font-weight-black my-1">+{{ formatCurrency(kpis.totalGain) }}</span>
                      </div>
                  </v-card>
              </v-col>
          </v-row>
      </div>

      <!-- Controls & Filters -->
      <div class="px-4 px-md-6 pt-4 pb-2 flex-shrink-0">
          <div class="controls-bar d-flex align-center justify-space-between flex-wrap gap-3" :class="themeStore.currentMode === 'light' ? 'controls-light' : 'controls-dark'">
              <div class="d-flex align-center flex-wrap w-100" style="gap: 10px;">

                  <div class="period-nav d-flex align-center justify-center flex-grow-0" :class="themeStore.currentMode === 'light' ? 'period-nav-light' : 'period-nav-dark'">
                     <div class="period-label text-caption font-weight-black text-center px-4 d-flex align-center" style="height: 40px;">
                        <v-icon start size="small" class="mr-2 opacity-50">mdi-calendar</v-icon>
                        <input type="date" v-model="filters.startDate" class="clean-input text-center font-weight-bold" @change="fetchAuditData">
                        <span class="mx-2 opacity-50">até</span>
                        <input type="date" v-model="filters.endDate" class="clean-input text-center font-weight-bold" @change="fetchAuditData">
                     </div>
                  </div>

                  <div class="search-wrap d-flex align-center flex-grow-1" :class="themeStore.currentMode === 'light' ? 'search-light' : 'search-dark'">
                      <v-icon :color="themeStore.currentMode === 'light' ? 'grey-darken-1' : 'white-70'">mdi-magnify</v-icon>
                      <input
                        v-model="filters.search"
                        type="text"
                        placeholder="Buscar por pedido, cliente, produto ou vendedor..."
                        class="clean-input flex-grow-1 ml-2 font-weight-bold"
                      />
                  </div>

                  <v-btn-toggle v-model="groupByOrder" color="primary" mandatory class="border-thin shadow-sm flex-shrink-0" style="height: 40px; border-radius: 0;" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-transparent'">
                      <v-btn :value="false" class="font-weight-bold px-3 text-caption text-none m-0" style="height: 40px;">Por Item</v-btn>
                      <v-btn :value="true" class="font-weight-bold px-3 text-caption text-none m-0" style="height: 40px;">Por Pedido</v-btn>
                  </v-btn-toggle>

                  <v-btn-toggle v-model="filters.status" color="warning" mandatory class="border-thin shadow-sm flex-shrink-0" style="height: 40px; border-radius: 0;" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-transparent'">
                      <v-btn value="all" class="font-weight-bold px-3 text-caption text-none m-0" style="height: 40px;">Todos</v-btn>
                      <v-btn value="correct" class="font-weight-bold px-3 text-caption text-none m-0 text-success" style="height: 40px;">Corretos</v-btn>
                      <v-btn value="divergent" class="font-weight-bold px-3 text-caption text-none m-0" style="height: 40px;">Divergentes</v-btn>
                      <v-btn value="loss" class="font-weight-bold px-3 text-caption text-none m-0 text-error" style="height: 40px;">Perdas</v-btn>
                  </v-btn-toggle>

                  <v-btn icon variant="tonal" color="primary" height="40" width="40" class="btn-rect flex-shrink-0" @click="fetchAuditData" :loading="loading">
                      <v-icon>mdi-refresh</v-icon>
                  </v-btn>
              </div>
          </div>
      </div>

      <!-- Grid de Dados -->
      <div class="flex-grow-1 px-4 px-md-6 pb-4 overflow-hidden d-flex flex-column mt-2">
          <v-card class="flex-grow-1 d-flex flex-column rounded-0 border-thin overflow-hidden" :class="themeStore.currentMode === 'light' ? 'bg-white shadow-sm' : 'glass-card border-white-05'" :elevation="0">
              <div class="grid-scroll flex-grow-1 overflow-y-auto custom-scroll">

                  <!-- Header Visão por Item -->
                  <div v-if="!groupByOrder" class="grid-header sticky-head grid-layout-items" :class="themeStore.currentMode === 'light' ? 'grid-surface-light' : 'grid-surface-dark'">
                      <div class="cell center header-text">Origem</div>
                      <div class="cell header-text pl-4">Data / Pedido</div>
                      <div class="cell header-text pl-4">Vendedor / Usuário</div>
                      <div class="cell header-text pl-4">Cliente</div>
                      <div class="cell header-text pl-4">Produto (Qtd)</div>
                      <div class="cell right header-text pr-4">Vlr. Tabela</div>
                      <div class="cell right header-text pr-4">Vlr. Vendido</div>
                      <div class="cell right header-text pr-4">Total Real</div>
                      <div class="cell center header-text">Divergência</div>
                  </div>

                  <!-- Header Visão por Pedido -->
                  <div v-else class="grid-header sticky-head grid-layout-orders" :class="themeStore.currentMode === 'light' ? 'grid-surface-light' : 'grid-surface-dark'">
                      <div class="cell center header-text">Origem</div>
                      <div class="cell header-text pl-4">Data / Pedido</div>
                      <div class="cell header-text pl-4">Vendedor / Usuário</div>
                      <div class="cell header-text pl-4">Cliente</div>
                      <div class="cell center header-text">Empresa</div>
                      <div class="cell right header-text pr-4">Total Tabela</div>
                      <div class="cell right header-text pr-4">Total Faturado</div>
                      <div class="cell center header-text">Divergência Total</div>
                      <div class="cell center header-text">Ação</div>
                  </div>

                  <div v-if="loading" class="d-flex flex-column justify-center align-center h-100 py-10 w-100 min-w-full">
                      <v-progress-circular indeterminate color="primary" size="32" width="3"></v-progress-circular>
                      <span class="mt-4 font-weight-bold opacity-60">Cruzando ERP, PDV e Recebimentos...</span>
                  </div>

                  <div v-else-if="filteredData.length === 0" class="d-flex flex-column justify-center align-center h-100 py-10 opacity-60 w-100 min-w-full">
                      <v-icon size="48" class="mb-2">mdi-check-decagram</v-icon>
                      <span class="font-weight-medium">Nenhum registro encontrado nos filtros atuais.</span>
                  </div>

                  <template v-else>
                      <!-- Rows Visão por Item -->
                      <template v-if="!groupByOrder">
                          <div v-for="(item, index) in paginatedData" :key="item.id"
                               class="grid-row transition-hover grid-layout-items"
                               :class="zebraClass(index)">

                              <div class="cell center">
                                  <v-chip size="x-small" :color="item.source === 'ERP' ? 'primary' : 'purple'" variant="flat" class="font-weight-bold px-2 solid-chip">
                                      {{ item.source }}
                                  </v-chip>
                              </div>

                              <div class="cell pl-4 d-flex flex-column justify-center align-start">
                                  <span class="font-weight-bold font-mono">#{{ item.order_number }}</span>
                                  <span class="text-[10px] opacity-70">{{ item.dateFormatted }}</span>
                              </div>

                              <div class="cell pl-4 d-flex align-center text-truncate text-[11px]">
                                  <v-icon size="12" class="mr-2 opacity-60">mdi-account-tie</v-icon>
                                  {{ item.seller_name }}
                              </div>

                              <div class="cell pl-4 font-weight-bold text-[11px] text-truncate">
                                  {{ item.customer_name }}
                              </div>

                              <div class="cell pl-4 d-flex flex-column justify-center align-start text-truncate">
                                  <span class="font-weight-bold text-[11px] text-truncate">{{ item.fabric_type }}</span>
                                  <span class="text-[10px] opacity-70 mt-1">
                                      {{ formatNumber(item.quantity_meters) }}m
                                      <span v-if="item.unitDisplay === 'kg'" class="text-primary font-weight-bold ml-1">
                                          ({{ formatNumber(item.quantityForPricing) }}kg)
                                      </span>
                                  </span>
                              </div>

                              <div class="cell right pr-4 font-mono text-[12px] opacity-70">
                                  <span v-if="item.base_price">{{ formatCurrency(item.base_price) }}/{{ item.unitDisplay }}</span>
                                  <span v-else class="text-error font-weight-bold" style="font-size: 10px;">Sem Cadastro</span>
                              </div>

                              <div class="cell right pr-4 font-mono font-weight-bold text-[12px]" :class="item.unitPriceDiff < -0.10 ? 'text-error' : (item.unitPriceDiff > 0.10 ? 'text-success' : '')">
                                  {{ formatCurrency(item.actual_unit_price) }}/{{ item.unitDisplay }}
                              </div>

                              <div class="cell right pr-4 font-mono font-weight-black text-subtitle-2">
                                  {{ formatCurrency(item.total_value_items) }}
                              </div>

                              <div class="cell center">
                                  <v-chip size="small" :color="getDiffColor(item.totalDiff)" :variant="Math.abs(item.totalDiff) <= 0.10 ? 'outlined' : 'flat'" class="font-weight-bold font-mono px-2 solid-chip">
                                      {{ item.totalDiff > 0.10 ? '+' : '' }}{{ formatCurrency(item.totalDiff) }}
                                  </v-chip>
                              </div>
                          </div>
                      </template>

                      <!-- Rows Visão por Pedido -->
                      <template v-else>
                          <div v-for="(group, index) in paginatedData" :key="group.orderKey"
                               class="grid-row transition-hover grid-layout-orders"
                               :class="zebraClass(index)">

                              <div class="cell center">
                                  <v-chip size="x-small" :color="group.source === 'ERP' ? 'primary' : 'purple'" variant="flat" class="font-weight-bold px-2 solid-chip">
                                      {{ group.source }}
                                  </v-chip>
                              </div>

                              <div class="cell pl-4 d-flex flex-column justify-center align-start">
                                  <span class="font-weight-bold font-mono text-subtitle-2">#{{ group.order_number }}</span>
                                  <span class="text-[10px] opacity-70">{{ group.dateFormatted }}</span>
                              </div>

                              <div class="cell pl-4 d-flex align-center text-truncate text-[11px]">
                                  <v-icon size="12" class="mr-2 opacity-60">mdi-account-tie</v-icon>
                                  {{ group.seller_name }}
                              </div>

                              <div class="cell pl-4 font-weight-bold text-[11px] text-truncate">
                                  {{ group.customer_name }}
                              </div>

                              <div class="cell center text-[10px] font-weight-bold text-uppercase opacity-70">
                                  {{ group.company_name }}
                              </div>

                              <div class="cell right pr-4 font-mono text-[13px] opacity-70">
                                  {{ formatCurrency(group.expected_total) }}
                              </div>

                              <div class="cell right pr-4 font-mono font-weight-black text-subtitle-1">
                                  {{ formatCurrency(group.actual_total) }}
                              </div>

                              <div class="cell center">
                                  <v-chip size="small" :color="getDiffColor(group.totalDiff)" :variant="Math.abs(group.totalDiff) <= 0.10 ? 'outlined' : 'flat'" class="font-weight-bold font-mono px-3 solid-chip">
                                      {{ group.totalDiff > 0.10 ? '+' : '' }}{{ formatCurrency(group.totalDiff) }}
                                  </v-chip>
                              </div>

                              <div class="cell center">
                                  <v-btn variant="tonal" size="small" color="primary" class="font-weight-bold btn-3d px-2" @click="openOrderDetails(group)">
                                      <v-icon start size="14">mdi-text-box-search-outline</v-icon> Detalhes
                                  </v-btn>
                              </div>
                          </div>
                      </template>
                  </template>
              </div>

              <!-- Paginação Fixa no Rodapé da Grid -->
              <div class="flex-shrink-0 border-t px-4 py-2 d-flex align-center justify-space-between z-20" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5' : 'bg-black-20 border-white-05'">
                <div class="text-caption opacity-80">
                  <strong>{{ filteredData.length }}</strong> registros encontrados
                </div>
                <v-pagination
                  v-model="page"
                  :length="pageCount"
                  :total-visible="5"
                  density="compact"
                  active-color="warning"
                  variant="tonal"
                  size="small"
                ></v-pagination>
              </div>
          </v-card>
      </div>

    </div>

    <!-- MODAL DETALHE DO PEDIDO -->
    <v-dialog v-model="orderModal.show" max-width="800px" scrollable transition="dialog-bottom-transition">
        <v-card class="d-flex flex-column overflow-hidden rounded-xl shadow-indigo-soft" max-height="85vh" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-surface-dark border-white-05'">

            <div class="px-5 py-4 border-b d-flex justify-space-between align-center flex-shrink-0 bg-primary position-relative overflow-hidden">
                <div class="d-flex align-center gap-3 position-relative z-10">
                    <div class="icon-box bg-white text-primary rounded-lg d-flex align-center justify-center elevation-1" style="width: 38px; height: 38px;">
                        <v-icon size="22">mdi-receipt-text-outline</v-icon>
                    </div>
                    <div class="text-white">
                        <div class="text-[10px] font-weight-bold text-uppercase opacity-80 letter-spacing-1">Auditoria de Itens</div>
                        <div class="text-h6 font-weight-black lh-1 mt-1">Pedido #{{ orderModal.order_number }}</div>
                    </div>
                </div>
                <v-btn icon="mdi-close" variant="text" density="compact" color="white" @click="orderModal.show = false"></v-btn>
            </div>

            <div class="flex-grow-1 overflow-y-auto px-4 py-4" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5' : 'bg-transparent'">
                <div class="d-flex flex-column gap-3">
                    <v-card v-for="item in orderModal.items" :key="item.id" class="border-thin p-3 rounded-lg" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-glass-dark'" elevation="0">
                        <div class="d-flex justify-space-between align-center mb-2">
                            <span class="font-weight-bold text-subtitle-2">{{ item.fabric_type }}</span>
                            <v-chip size="x-small" :color="getDiffColor(item.totalDiff)" :variant="Math.abs(item.totalDiff) <= 0.10 ? 'outlined' : 'flat'" class="font-weight-bold">
                                {{ item.totalDiff > 0 ? '+' : '' }}{{ formatCurrency(item.totalDiff) }}
                            </v-chip>
                        </div>
                        <v-divider class="my-2 opacity-20"></v-divider>
                        <v-row dense class="text-caption">
                            <v-col cols="6" sm="3">
                                <div class="opacity-60 text-[10px] text-uppercase">Quantidade</div>
                                <div class="font-weight-bold">{{ formatNumber(item.quantity_meters) }}m <span v-if="item.unitDisplay==='kg'">({{formatNumber(item.quantityForPricing)}}kg)</span></div>
                            </v-col>
                            <v-col cols="6" sm="3">
                                <div class="opacity-60 text-[10px] text-uppercase">Preço Tabela</div>
                                <div class="font-weight-bold">{{ item.base_price ? formatCurrency(item.base_price) : 'N/A' }}</div>
                            </v-col>
                            <v-col cols="6" sm="3">
                                <div class="opacity-60 text-[10px] text-uppercase">Preço Praticado</div>
                                <div class="font-weight-bold" :class="item.unitPriceDiff < -0.10 ? 'text-error' : (item.unitPriceDiff > 0.10 ? 'text-success' : '')">
                                    {{ formatCurrency(item.actual_unit_price) }}
                                </div>
                            </v-col>
                            <v-col cols="6" sm="3">
                                <div class="opacity-60 text-[10px] text-uppercase">Total Item</div>
                                <div class="font-weight-black">{{ formatCurrency(item.total_value_items) }}</div>
                            </v-col>
                        </v-row>
                    </v-card>
                </div>
            </div>
        </v-card>
    </v-dialog>

  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted, watch } from 'vue';
import { supabase } from '@/api/supabase';
import { useThemeStore } from '@/stores/theme';
import { format, parseISO, startOfMonth, endOfMonth, startOfDay, endOfDay } from 'date-fns';

const themeStore = useThemeStore();

const now = new Date();
const firstDay = format(startOfMonth(now), 'yyyy-MM-dd');
const lastDay = format(endOfMonth(now), 'yyyy-MM-dd');

const loading = ref(false);
const rawItems = ref<any[]>([]);
const page = ref(1);
const itemsPerPage = 50;

const groupByOrder = ref(false);

const filters = reactive({
    search: '',
    startDate: firstDay,
    endDate: lastDay,
    status: 'divergent', // 'all', 'correct', 'divergent', 'loss'
    companyName: 'ALL' // 'ALL', 'SANTOS & LOPES', 'MR JACKY'
});

const orderModal = reactive({
    show: false,
    order_number: '',
    items: [] as any[]
});

// Motor de paginação infinita copiado do seu AdminMjReceivables
const fetchAllPages = async (buildQ: () => any) => {
    let aggregatedData: any[] = [];
    let from = 0;
    const step = 900;
    let hasMore = true;
    let safetyCounter = 0;

    while (hasMore && safetyCounter < 100) { // Limite de segurança de 100 * 900 = 90.000 registros
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

// Nova versão de busca de chunks para não sofrer cortes na base
const fetchReceivablesInChunks = async (column: string, ids: string[]) => {
    const chunkSize = 200;
    let allData: any[] = [];
    for (let i = 0; i < ids.length; i += chunkSize) {
        const chunk = ids.slice(i, i + chunkSize);

        // Usamos o fetchAllPages aqui dentro também para garantir que as parcelas não sofram corte
        const getRecQuery = () => supabase
            .from('finance_receivables')
            .select(`${column}, status, value, discount, paid_value`)
            .in(column, chunk);

        const data = await fetchAllPages(getRecQuery);
        if (data) allData.push(...data);
    }
    return allData;
};

const fetchAuditData = async () => {
    loading.value = true;
    try {
        const startIso = startOfDay(parseISO(filters.startDate)).toISOString();
        const endIso = endOfDay(parseISO(filters.endDate)).toISOString();

        // 1. Busca Tabela de Estoque
        const getStockQuery = () => supabase.from('stock').select('fabric_type, base_price, unit_of_measure, rendimento');
        const stockData = await fetchAllPages(getStockQuery);

        const stockMap = new Map();
        stockData.forEach(s => {
            if (s.fabric_type && s.base_price !== null) {
                stockMap.set(s.fabric_type.trim().toUpperCase(), {
                    basePrice: Number(s.base_price),
                    unit: s.unit_of_measure,
                    rendimento: Number(s.rendimento) || 1
                });
            }
        });

        const calculateMath = (fabricType: string, qtyMeters: number, actualTotal: number) => {
            const fabricName = String(fabricType || '').trim().toUpperCase();
            const fabricInfo = stockMap.get(fabricName) || null;

            let expectedTotal = 0, totalDiff = 0, unitPriceDiff = 0, actualUnitPrice = 0;
            let basePriceDisplay = null, unitDisplay = 'm', qtyForPricing = qtyMeters;

            if (fabricInfo !== null) {
                const basePrice = fabricInfo.basePrice;
                const isKg = fabricInfo.unit === 'kg';
                const rendimento = fabricInfo.rendimento;

                qtyForPricing = isKg ? (qtyMeters / rendimento) : qtyMeters;
                unitDisplay = isKg ? 'kg' : 'm';
                expectedTotal = qtyForPricing * basePrice;
                actualUnitPrice = qtyForPricing > 0 ? actualTotal / qtyForPricing : 0;
                totalDiff = actualTotal - expectedTotal;
                unitPriceDiff = actualUnitPrice - basePrice;
                basePriceDisplay = basePrice;
            } else {
                actualUnitPrice = qtyMeters > 0 ? actualTotal / qtyMeters : 0;
            }

            return { fabricName, qtyForPricing, unitDisplay, expectedTotal, actualUnitPrice, totalDiff, unitPriceDiff, basePriceDisplay };
        };

        const tempItems = [];
        const erpOrderIds = new Set<string>();
        const pdvSaleIds = new Set<string>();

        // 2. Busca ERP via loop infinito do range (quebra a barreira de 1000)
        const getErpQuery = () => supabase
            .from('order_items')
            .select(`id, fabric_type, quantity_meters, total_value_items, order_id, orders!inner ( id, order_number, customer_name, created_at, created_by, profiles!orders_created_by_fkey ( full_name ) )`)
            .gte('orders.created_at', startIso)
            .lte('orders.created_at', endIso)
            .gt('quantity_meters', 0);

        const erpItems = await fetchAllPages(getErpQuery);

        if (erpItems && erpItems.length > 0) {
            erpItems.forEach((item: any) => {
                const order = Array.isArray(item.orders) ? item.orders[0] : item.orders;
                if(!order) return;

                erpOrderIds.add(order.id);
                const qty = Number(item.quantity_meters) || 0;
                const actualTotal = Number(item.total_value_items) || 0;
                const math = calculateMath(item.fabric_type, qty, actualTotal);
                const isCJ = math.fabricName.startsWith('CJ');

                tempItems.push({
                    id: `erp-${item.id}`, source: 'ERP', orderKey: `erp-${order.id}`, order_id: order.id,
                    order_number: String(order.order_number).padStart(4, '0'),
                    customer_name: order.customer_name || 'Não Informado',
                    seller_name: order.profiles ? order.profiles.full_name : 'Desconhecido',
                    company_name: isCJ ? 'SANTOS & LOPES' : 'MR JACKY',
                    fabric_type: math.fabricName, quantity_meters: qty, quantityForPricing: math.qtyForPricing,
                    unitDisplay: math.unitDisplay, base_price: math.basePriceDisplay, actual_unit_price: math.actualUnitPrice,
                    total_value_items: actualTotal, expected_total: math.expectedTotal, totalDiff: math.totalDiff,
                    unitPriceDiff: math.unitPriceDiff, dateFormatted: formatDateTime(order.created_at)
                });
            });
        }

        // 3. Busca PDV via loop infinito do range
        const getPdvQuery = () => supabase
            .from('store_sales')
            .select('id, order_number, gestao_click_id, customer_name, seller_name, created_at, items')
            .gte('created_at', startIso)
            .lte('created_at', endIso);

        const pdvSales = await fetchAllPages(getPdvQuery);

        if (pdvSales && pdvSales.length > 0) {
            pdvSales.forEach((sale: any) => {
                const items = sale.items || [];
                const orderNum = sale.order_number || sale.gestao_click_id || sale.id.substring(0,6);

                pdvSaleIds.add(sale.id);

                items.forEach((item: any, idx: number) => {
                    const rawFabricName = String(item.nome || item.descricao || item.produto || '').trim();
                    if (!rawFabricName) return;
                    const qty = Number(item.quantidade || item.quantity || item.qtd || 0);
                    const actualTotal = Number(item.valor_total || item.total_value || (qty * (item.valor_unitario || 0))) || 0;
                    if (qty <= 0) return;

                    const math = calculateMath(rawFabricName, qty, actualTotal);
                    const isCJ = math.fabricName.startsWith('CJ');

                    tempItems.push({
                        id: `pdv-${sale.id}-${idx}`, source: 'PDV', orderKey: `pdv-${sale.id}`, store_sale_id: sale.id,
                        order_number: orderNum, customer_name: sale.customer_name || 'Consumidor Final',
                        seller_name: sale.seller_name || 'Desconhecido', company_name: isCJ ? 'SANTOS & LOPES' : 'MR JACKY',
                        fabric_type: math.fabricName, quantity_meters: qty, quantityForPricing: math.qtyForPricing,
                        unitDisplay: math.unitDisplay, base_price: math.basePriceDisplay, actual_unit_price: math.actualUnitPrice,
                        total_value_items: actualTotal, expected_total: math.expectedTotal, totalDiff: math.totalDiff,
                        unitPriceDiff: math.unitPriceDiff, dateFormatted: formatDateTime(sale.created_at)
                    });
                });
            });
        }

        // 4. Recebimentos
        const orderPaymentsMap = new Map();
        const pdvPaymentsMap = new Map();

        if (erpOrderIds.size > 0) {
            const erpIdsArr = Array.from(erpOrderIds);

            // 4.1 Busca Financeiro (Contas a receber) usando a nova função com loop
            const recErp = await fetchReceivablesInChunks('order_id', erpIdsArr);
            recErp.forEach(r => {
                const current = orderPaymentsMap.get(r.order_id) || 0;
                const val = r.status === 'pago' ? (Number(r.value) - Number(r.discount || 0)) : Number(r.paid_value || 0);
                orderPaymentsMap.set(r.order_id, current + val);
            });

            // 4.2 Buscando SINAIS via loop
            const chunkSize = 200;
            for (let i = 0; i < erpIdsArr.length; i += chunkSize) {
                const chunk = erpIdsArr.slice(i, i + chunkSize);

                const getSignalsQuery = () => supabase
                    .from('order_payments')
                    .select('order_id, amount')
                    .in('order_id', chunk);

                const signals = await fetchAllPages(getSignalsQuery);

                if (signals) {
                    signals.forEach(s => {
                        const current = orderPaymentsMap.get(s.order_id) || 0;
                        orderPaymentsMap.set(s.order_id, current + Number(s.amount || 0));
                    });
                }
            }
        }

        if (pdvSaleIds.size > 0) {
            const recPdv = await fetchReceivablesInChunks('store_sale_id', Array.from(pdvSaleIds));
            recPdv.forEach(r => {
                const current = pdvPaymentsMap.get(r.store_sale_id) || 0;
                const val = r.status === 'pago' ? (Number(r.value) - Number(r.discount || 0)) : Number(r.paid_value || 0);
                pdvPaymentsMap.set(r.store_sale_id, current + val);
            });
        }

        rawItems.value = tempItems.map(item => {
            const paidValue = item.source === 'ERP'
                ? (orderPaymentsMap.get(item.order_id) || 0)
                : (pdvPaymentsMap.get(item.store_sale_id) || 0);

            return { ...item, order_paid_value: paidValue };
        });

    } catch (error) {
        console.error("Erro ao buscar dados de auditoria:", error);
    } finally {
        loading.value = false;
        page.value = 1;
    }
};

const filteredData = computed(() => {
    let result = rawItems.value;

    // Filtro de Empresa
    if (filters.companyName !== 'ALL') {
        result = result.filter(i => i.company_name === filters.companyName);
    }

    // Filtro de Status
    if (filters.status === 'divergent') {
        result = result.filter(i => Math.abs(i.totalDiff) > 0.10 || i.base_price === null);
    } else if (filters.status === 'loss') {
        result = result.filter(i => i.totalDiff < -0.10);
    } else if (filters.status === 'correct') {
        result = result.filter(i => Math.abs(i.totalDiff) <= 0.10 && i.base_price !== null);
    }

    // Filtro de Busca
    const term = filters.search.trim().toLowerCase();
    if (term) {
        result = result.filter(i =>
            (i.customer_name || '').toLowerCase().includes(term) ||
            (i.fabric_type || '').toLowerCase().includes(term) ||
            String(i.order_number).toLowerCase().includes(term) ||
            (i.seller_name || '').toLowerCase().includes(term)
        );
    }

    if (groupByOrder.value) {
        const orderMap = new Map();
        result.forEach(i => {
            if (!orderMap.has(i.orderKey)) {
                orderMap.set(i.orderKey, {
                    orderKey: i.orderKey,
                    source: i.source,
                    order_number: i.order_number,
                    dateFormatted: i.dateFormatted,
                    seller_name: i.seller_name,
                    customer_name: i.customer_name,
                    company_name: i.company_name,
                    expected_total: 0,
                    actual_total: 0,
                    totalDiff: 0,
                    items: []
                });
            }
            const group = orderMap.get(i.orderKey);
            group.expected_total += i.expected_total;
            group.actual_total += i.total_value_items;
            group.totalDiff += i.totalDiff;
            group.items.push(i);
        });

        // Ordenar os pedidos do maior prejuízo para o maior lucro
        return Array.from(orderMap.values()).sort((a, b) => a.totalDiff - b.totalDiff);
    }

    // Ordenar itens do maior prejuízo para o maior lucro
    return result.sort((a, b) => a.totalDiff - b.totalDiff);
});

const paginatedData = computed(() => {
    const start = (page.value - 1) * itemsPerPage;
    return filteredData.value.slice(start, start + itemsPerPage);
});

const pageCount = computed(() => Math.ceil(filteredData.value.length / itemsPerPage));

const kpis = computed(() => {
    let expectedTotal = 0;
    let actualTotal = 0;
    let totalLoss = 0;
    let totalGain = 0;
    let totalReceived = 0;

    const uniqueOrders = new Set();

    const itemsToSum = groupByOrder.value
        ? filteredData.value.flatMap(g => g.items)
        : filteredData.value;

    itemsToSum.forEach((item: any) => {
        expectedTotal += item.expected_total;
        actualTotal += item.total_value_items;

        if (item.totalDiff < -0.10) {
            totalLoss += item.totalDiff;
        } else if (item.totalDiff > 0.10) {
            totalGain += item.totalDiff;
        }

        // Soma o valor recebido apenas 1 vez por pedido para evitar duplicidade de itens
        if (!uniqueOrders.has(item.orderKey)) {
            uniqueOrders.add(item.orderKey);
            totalReceived += item.order_paid_value || 0;
        }
    });

    return { expectedTotal, actualTotal, totalLoss, totalGain, totalReceived };
});

const openOrderDetails = (group: any) => {
    orderModal.order_number = group.order_number;
    orderModal.items = group.items;
    orderModal.show = true;
};

// Helpers
const formatCurrency = (val: number) => new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(val || 0);
const formatNumber = (v: any) => new Intl.NumberFormat('pt-BR', { minimumFractionDigits: 1, maximumFractionDigits: 2 }).format(Number(v)||0);
const formatDateTime = (dateString: string) => { if (!dateString) return '-'; try { return format(parseISO(dateString), 'dd/MM/yy HH:mm'); } catch { return dateString; } };
const zebraClass = (i: number) => themeStore.currentMode === 'light' ? (i % 2 === 0 ? 'zebra-light-a' : 'zebra-light-b') : (i % 2 === 0 ? 'zebra-dark-a' : 'zebra-dark-b');

const getDiffColor = (diff: number) => {
    if (diff < -0.10) return 'error';
    if (diff > 0.10) return 'success';
    return 'grey';
};

onMounted(() => {
    fetchAuditData();
});

watch(() => filters.status, () => { page.value = 1; });
watch(() => filters.companyName, () => { page.value = 1; });
watch(() => groupByOrder.value, () => { page.value = 1; });
</script>

<style scoped>
.financial-report-layout { position: relative; }
.background-carousel-wrapper { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 0; opacity: 0.6; pointer-events: none; }
.background-overlay { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 1; background: radial-gradient(circle at center, rgba(15, 15, 19, 0.4), rgba(15, 15, 19, 0.98)); backdrop-filter: blur(8px); }
.z-10 { position: relative; z-index: 10; }
.bg-glass-dark { background: rgba(10,10,12,0.85); }
.bg-surface-dark { background-color: #1a1a20; }
.bg-glass-header { background: rgba(20,20,24,0.55); backdrop-filter: blur(14px); }
.border-bottom-white-05 { border-bottom: 1px solid rgba(255,255,255,0.08); }

.hover-underline:hover { text-decoration: underline; opacity: 1 !important; color: rgb(var(--v-theme-primary)); }

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

.kpi-bg-icon { position: absolute; right: -20px; bottom: -20px; opacity: 0.15; transform: rotate(-15deg); pointer-events: none; }
.kpi-bg-icon .v-icon { font-size: 100px; color: white; }
.kpi-card { border: 1px solid rgba(255,255,255,0.15); color: white; min-height: 110px; position: relative; overflow: hidden; border-radius: 0 !important; }

.bg-gradient-info { background: linear-gradient(135deg, #0288d1, #005b9f); }
.bg-gradient-success { background: linear-gradient(135deg, #2e7d32, #1b5e20); }
.bg-gradient-danger { background: linear-gradient(135deg, #c62828, #b71c1c); }
.bg-gradient-primary { background: linear-gradient(135deg, #1976d2, #0d47a1); }
.bg-gradient-purple { background: linear-gradient(135deg, #7b1fa2, #4a148c); }

.kpi-label { font-size: 12px; font-weight: 900; letter-spacing: .2px; text-transform: uppercase; }
.kpi-value { font-size: 26px; font-weight: 900; letter-spacing: .2px; }

.btn-rect { border-radius: 0 !important; text-transform: none !important; font-weight: 800; }
.btn-3d { border-radius: 6px !important; box-shadow: 0 3px 5px rgba(0,0,0,0.15), inset 0 2px 0 rgba(255,255,255,0.25) !important; transition: transform 0.1s ease, box-shadow 0.1s ease; text-transform: none !important; }
.btn-3d:active { transform: translateY(2px); box-shadow: 0 1px 2px rgba(0,0,0,0.15), inset 0 1px 0 rgba(255,255,255,0.2) !important; }

/* Grid Layouts */
.grid-layout-items {
    display: grid;
    width: 100%;
    /* Origem | Data/Pedido | Vendedor | Cliente | Produto | Vlr Tabela | Vlr Vendido | Total Real | Divergência */
    grid-template-columns: 80px minmax(130px, 1fr) minmax(150px, 1.5fr) minmax(150px, 1.5fr) minmax(160px, 2fr) 130px 140px 130px 150px;
    min-width: 1250px; /* Aumentado para garantir espaço do scroll horizontal */
}

.grid-layout-orders {
    display: grid;
    width: 100%;
    /* Origem | Data/Pedido | Vendedor | Cliente | Empresa | Total Tabela | Total Faturado | Divergência | Ação */
    grid-template-columns: 80px minmax(130px, 1fr) minmax(150px, 1.5fr) minmax(150px, 1.5fr) 120px 140px 140px 160px 110px;
    min-width: 1150px;
}

.cell { padding: 8px 10px; display: flex; align-items: center; border-right: 1px solid rgba(0,0,0,0.08); border-bottom: 1px solid rgba(0,0,0,0.08); min-height: 52px; overflow: hidden; }
.center { justify-content: center; text-align: center; }
.right { justify-content: flex-end; text-align: right; }

.header-text { font-size: 11px; font-weight: 900; text-transform: uppercase; letter-spacing: 0.5px; opacity: 0.8; padding: 12px 8px; }
.grid-header { align-items: stretch; width: 100%; border-bottom: 1px solid rgba(0,0,0,0.08); position: sticky; top: 0; z-index: 10; }
.grid-row { align-items: stretch; width: 100%; }

.grid-surface-light .cell { background: #f5f7fa; color: rgba(0,0,0,0.7); }
.grid-surface-dark .cell { background: rgba(255,255,255,0.08); color: rgba(255,255,255,0.80); }

.zebra-light-a .cell { background: #fff; }
.zebra-light-b .cell { background: #f8fafc; }
.zebra-dark-a .cell { background: rgba(255,255,255,0.02); }
.zebra-dark-b .cell { background: transparent; }

.transition-hover:hover .cell { filter: brightness(0.95); }
.bg-glass-dark .transition-hover:hover .cell { filter: brightness(1.2); }

.solid-chip { display: inline-flex; align-items: center; justify-content: center; height: 24px; border-radius: 4px; }
.custom-scroll::-webkit-scrollbar { width: 6px; height: 6px; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.3); border-radius: 4px; }
.glass-card { background: rgba(30, 30, 35, 0.45); backdrop-filter: blur(25px); border: 1px solid rgba(255,255,255,0.08); }
.shadow-indigo-soft { box-shadow: 0 4px 15px rgba(63, 81, 181, 0.4); }
</style>
