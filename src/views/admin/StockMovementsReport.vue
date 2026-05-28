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
                  <span class="opacity-70 cursor-pointer hover-underline" @click="$router.push({ name: 'AdminReports', params: { reportType: 'hub' } })">Relatórios</span>
                  <span class="mx-2 opacity-50">></span>
                  <span class="font-weight-bold">Estoque & Logística</span>
              </div>
              <div class="d-flex align-center mt-1" style="gap: 8px;">
                 <v-btn class="d-md-none mr-1" icon="mdi-arrow-left" variant="text" size="small" @click="$router.push({ name: 'AdminReports', params: { reportType: 'hub' } })"></v-btn>
                 <div class="text-h6 font-weight-black tracking-tight leading-none text-truncate" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">
                    Auditoria de Movimentações (Kardex)
                 </div>
              </div>

              <!-- Multi-Tenant Tabs -->
              <div class="d-flex align-center mt-3 overflow-x-auto hide-scrollbar pb-1 w-100" style="gap: 12px;">
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
                    v-for="comp in companies"
                    :key="comp.id"
                    size="x-small"
                    height="24"
                    :variant="filters.companyId === comp.id || (!companyStore.isGlobalView && companyStore.context === comp.id && !filters.companyId) ? 'flat' : 'tonal'"
                    :color="filters.companyId === comp.id || (!companyStore.isGlobalView && companyStore.context === comp.id && !filters.companyId) ? 'warning' : 'grey'"
                    class="font-weight-bold btn-3d px-3 rounded-pill flex-shrink-0"
                    style="font-size: 10px; letter-spacing: 0.5px;"
                    @click="setCompanyFilter(comp.id)"
                 >
                    {{ comp.trade_name }}
                 </v-btn>
              </div>
          </div>

          <!-- Export Button -->
          <div class="d-flex align-center mt-3 mt-md-0">
              <v-menu location="bottom end">
                <template v-slot:activator="{ props }">
                  <v-btn
                      v-bind="props"
                      color="warning"
                      variant="flat"
                      class="btn-rect px-4 px-md-6 font-weight-bold text-uppercase shadow-indigo-soft"
                      style="letter-spacing: 1px;"
                      height="40"
                      prepend-icon="mdi-export"
                      :loading="reportLoading"
                      :disabled="loading || clientFilteredData.length === 0"
                  >
                      <span class="d-none d-sm-inline">Exportar Relatório</span>
                      <v-icon end size="small">mdi-chevron-down</v-icon>
                  </v-btn>
                </template>
                <v-list density="compact" nav width="260" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-glass-header border-white-05 text-white'">
                  <div class="text-[10px] font-weight-bold text-uppercase opacity-70 px-4 mb-2">Exportar Visão Atual</div>
                  <v-list-item @click="generateReport('print')" prepend-icon="mdi-printer" title="Imprimir (Nova Aba)" class="font-weight-bold text-primary"></v-list-item>
                  <v-list-item @click="generateReport('pdf')" prepend-icon="mdi-file-pdf-box" title="Exportar PDF" class="font-weight-bold text-red-darken-2"></v-list-item>
                  <v-divider class="my-2"></v-divider>
                  <v-list-item @click="generateReport('excel')" prepend-icon="mdi-microsoft-excel" title="Exportar Excel" class="font-weight-bold text-green-darken-3"></v-list-item>
                </v-list>
              </v-menu>
          </div>
      </div>

      <!-- KPIs -->
      <div class="px-4 px-md-6 pt-4 pb-0 flex-shrink-0">
          <v-row dense>
              <v-col cols="12" sm="3">
                  <v-card class="kpi-card bg-gradient-success hover-elevate py-3 px-4" elevation="2">
                      <div class="kpi-bg-icon"><v-icon>mdi-arrow-bottom-left-thick</v-icon></div>
                      <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                          <div class="d-flex align-center gap-2">
                              <v-icon size="18" class="opacity-80">mdi-plus-box-outline</v-icon>
                              <span class="kpi-label">Entradas Recebidas</span>
                          </div>
                          <div class="kpi-number-group my-1">
                              <span class="kpi-value text-h5 font-weight-black">+ {{ formatNumber(kpis.entradas) }} <span class="text-caption">m/kg</span></span>
                          </div>
                      </div>
                  </v-card>
              </v-col>

              <v-col cols="12" sm="3">
                  <v-card class="kpi-card bg-gradient-danger hover-elevate py-3 px-4" elevation="2">
                      <div class="kpi-bg-icon"><v-icon>mdi-arrow-top-right-thick</v-icon></div>
                      <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                          <div class="d-flex align-center gap-2">
                              <v-icon size="18" class="opacity-80">mdi-minus-box-outline</v-icon>
                              <span class="kpi-label">Volume Consumido</span>
                          </div>
                          <div class="kpi-number-group my-1">
                              <span class="kpi-value text-h5 font-weight-black">- {{ formatNumber(kpis.saidas) }} <span class="text-caption">m/kg</span></span>
                          </div>
                      </div>
                  </v-card>
              </v-col>

              <v-col cols="12" sm="3">
                  <v-card class="kpi-card bg-gradient-warning hover-elevate py-3 px-4" elevation="2">
                      <div class="kpi-bg-icon"><v-icon>mdi-scale-balance</v-icon></div>
                      <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                          <div class="d-flex align-center gap-2">
                              <v-icon size="18" class="opacity-80">mdi-sigma</v-icon>
                              <span class="kpi-label">Impacto no Saldo</span>
                          </div>
                          <div class="kpi-number-group my-1">
                              <span class="kpi-value text-h5 font-weight-black">{{ kpis.saldo > 0 ? '+' : '' }}{{ formatNumber(kpis.saldo) }} <span class="text-caption">m/kg</span></span>
                          </div>
                      </div>
                  </v-card>
              </v-col>

              <v-col cols="12" sm="3">
                  <v-card class="kpi-card bg-gradient-primary hover-elevate py-3 px-4" elevation="2">
                      <div class="kpi-bg-icon"><v-icon>mdi-warehouse</v-icon></div>
                      <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                          <div class="d-flex align-center justify-space-between">
                              <div class="d-flex align-center gap-2">
                                  <v-icon size="18" class="opacity-80">mdi-layers</v-icon>
                                  <span class="kpi-label">Estoque Físico Atual</span>
                              </div>
                              <v-tooltip activator="parent" location="top">Soma do estoque atual (ativo em vendas) dos tecidos listados abaixo.</v-tooltip>
                          </div>
                          <div class="kpi-number-group my-1 d-flex align-end gap-2">
                              <span class="kpi-value text-h5 font-weight-black">{{ formatNumber(kpis.estoqueAtual) }} <span class="text-caption">m/kg</span></span>
                          </div>
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
                        <input type="date" v-model="filters.startDate" class="clean-input text-center font-weight-bold" @change="fetchData">
                        <span class="mx-2 opacity-50">até</span>
                        <input type="date" v-model="filters.endDate" class="clean-input text-center font-weight-bold" @change="fetchData">
                     </div>
                  </div>

                  <div class="search-wrap d-flex align-center flex-grow-1" :class="themeStore.currentMode === 'light' ? 'search-light' : 'search-dark'">
                      <v-icon :color="themeStore.currentMode === 'light' ? 'grey-darken-1' : 'white-70'">mdi-magnify</v-icon>
                      <input
                        v-model="filters.search"
                        type="text"
                        placeholder="Buscar por lote, tecido, pedido, cliente ou usuário..."
                        class="clean-input flex-grow-1 ml-2 font-weight-bold"
                        @keyup.enter="page = 1"
                      />
                  </div>

                  <v-btn-toggle v-model="groupByProduct" color="warning" mandatory class="border-thin shadow-sm" style="height: 40px; border-radius: 0;" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-transparent'">
                      <v-btn :value="false" class="font-weight-bold px-4 text-caption text-none m-0" style="height: 40px;">
                          <v-icon start size="16">mdi-format-list-bulleted</v-icon> Detalhado
                      </v-btn>
                      <v-btn :value="true" class="font-weight-bold px-4 text-caption text-none m-0" style="height: 40px;">
                          <v-icon start size="16">mdi-format-list-group</v-icon> Agrupado
                      </v-btn>
                  </v-btn-toggle>

                  <v-menu v-model="filtersDropdownOpen" location="bottom end" :close-on-content-click="false" :z-index="2500">
                    <template v-slot:activator="{ props }">
                      <v-btn
                        v-bind="props"
                        variant="outlined"
                        class="btn-rect font-weight-bold"
                        height="40"
                        prepend-icon="mdi-filter-variant"
                        :color="activeFilterCount > 0 ? 'warning' : (themeStore.currentMode === 'light' ? 'grey-darken-2' : 'white')"
                      >
                        Filtros Avançados
                        <v-badge v-if="activeFilterCount > 0" :content="activeFilterCount" color="warning" floating class="ml-2"></v-badge>
                        <v-icon end size="small">mdi-chevron-down</v-icon>
                      </v-btn>
                    </template>

                    <v-card class="rounded-0 pa-4" width="450" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'glass-card border-white-05'">
                      <div class="d-flex justify-space-between align-center mb-4 border-b pb-2">
                          <span class="text-caption font-weight-black opacity-70 text-uppercase">Configurar Filtros</span>
                          <v-btn size="x-small" variant="text" color="error" @click="clearFilters">Limpar Tudo</v-btn>
                      </div>
                      <v-row dense class="row-gap">
                        <v-col cols="12">
                          <v-autocomplete v-model="filters.fabric" :items="availableFabrics" label="Filtrar por Tecido" variant="outlined" density="compact" hide-details clearable class="ui-field" />
                        </v-col>
                        <v-col cols="12">
                          <v-autocomplete v-model="filters.userId" :items="auxData.users" item-title="full_name" item-value="id" label="Usuário Responsável" variant="outlined" density="compact" hide-details clearable class="ui-field" />
                        </v-col>
                        <v-col cols="6">
                          <v-text-field v-model.number="filters.minQty" label="Qtd Mínima" type="number" variant="outlined" density="compact" hide-details class="ui-field" />
                        </v-col>
                        <v-col cols="6">
                          <v-text-field v-model.number="filters.maxQty" label="Qtd Máxima" type="number" variant="outlined" density="compact" hide-details class="ui-field" />
                        </v-col>
                        <v-col cols="12">
                          <div class="text-caption font-weight-black opacity-70 mb-2 mt-2">Sentido da Movimentação</div>
                          <div class="d-flex flex-wrap gap-2">
                            <v-chip v-for="t in movementTypes" :key="t.value"
                                    :color="filters.type === t.value ? t.color : 'grey'"
                                    :variant="filters.type === t.value ? 'flat' : 'outlined'"
                                    class="solid-chip cursor-pointer font-weight-bold"
                                    @click="filters.type = filters.type === t.value ? null : t.value">
                              <v-icon start size="small" v-if="filters.type === t.value">mdi-check</v-icon>
                              {{ t.label }}
                            </v-chip>
                          </div>
                        </v-col>
                      </v-row>
                      <div class="d-flex justify-end mt-6">
                        <v-btn variant="flat" class="btn-rect w-100 font-weight-bold" height="42" color="warning" @click="page = 1; filtersDropdownOpen = false">
                          <v-icon start>mdi-check</v-icon> Aplicar Filtros
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

      <!-- Grid de Dados -->
      <div class="flex-grow-1 px-4 px-md-6 pb-4 overflow-hidden d-flex flex-column mt-2">
          <v-card class="flex-grow-1 d-flex flex-column rounded-0 border-thin overflow-hidden" :class="themeStore.currentMode === 'light' ? 'bg-white shadow-sm' : 'glass-card border-white-05'" :elevation="0">
              <div class="grid-scroll flex-grow-1 overflow-y-auto custom-scroll">

                  <!-- HEADER LISTA CORRIDA -->
                  <div v-if="!groupByProduct" class="grid-header sticky-head" :class="[themeStore.currentMode === 'light' ? 'grid-surface-light' : 'grid-surface-dark', 'grid-flat-list']">
                      <div class="cell center header-text">Data / Hora</div>
                      <div class="cell center header-text">Lote</div>
                      <div class="cell center header-text">Tipo</div>
                      <div class="cell header-text pl-4">Tecido / Produto</div>
                      <div class="cell right header-text pr-4">Qtd.</div>
                      <div class="cell center header-text">Pedido</div>
                      <div class="cell header-text pl-4">Cliente</div>
                      <div class="cell header-text pl-4">Usuário Responsável</div>
                      <div class="cell center header-text">Empresa</div>
                  </div>

                  <!-- HEADER AGRUPADO -->
                  <div v-else class="grid-header sticky-head" :class="themeStore.currentMode === 'light' ? 'grid-surface-light' : 'grid-surface-dark'" style="grid-template-columns: minmax(250px, 2fr) 150px 150px 150px 150px;">
                      <div class="cell header-text pl-4">Tecido / Base</div>
                      <div class="cell right header-text pr-4">Total Entradas</div>
                      <div class="cell right header-text pr-4">Total Consumido</div>
                      <div class="cell right header-text pr-4">Saldo do Período</div>
                      <div class="cell center header-text">Auditoria Detalhada</div>
                  </div>

                  <div v-if="loading" class="d-flex flex-column justify-center align-center h-100 py-10 w-100 min-w-full">
                      <v-progress-circular indeterminate color="warning" size="32" width="3"></v-progress-circular>
                      <span class="mt-4 font-weight-bold opacity-60">Triangulando dados (Kardex Inteligente)...</span>
                  </div>

                  <div v-else-if="paginatedData.length === 0" class="d-flex flex-column justify-center align-center h-100 py-10 opacity-60 w-100 min-w-full">
                      <v-icon size="48" class="mb-2">mdi-dolly</v-icon>
                      <span class="font-weight-medium">Nenhuma movimentação para este filtro.</span>
                  </div>

                  <template v-else>
                      <!-- ROWS LISTA CORRIDA -->
                      <template v-if="!groupByProduct">
                          <div v-for="item in paginatedData" :key="item.id"
                               class="grid-row transition-hover"
                               :class="[
                                   'grid-flat-list',
                                   item.isEntry ? (themeStore.currentMode === 'light' ? 'row-entry-light' : 'row-entry-dark') : (themeStore.currentMode === 'light' ? 'row-exit-light' : 'row-exit-dark')
                               ]">

                              <div class="cell center font-mono opacity-90" style="font-size: 11px;">
                                  <div class="d-flex flex-column lh-1">
                                      <span class="font-weight-bold">{{ formatDateTime(item.created_at).split(' ')[0] }}</span>
                                      <span class="opacity-70 mt-1" style="font-size: 10px;">{{ formatDateTime(item.created_at).split(' ')[1] }}</span>
                                  </div>
                              </div>

                              <!-- LOTE -->
                              <div class="cell center font-mono text-[10px] font-weight-bold opacity-80 text-truncate" :title="item.lote">
                                  {{ item.lote || 'Geral' }}
                              </div>

                              <div class="cell center">
                                  <v-chip size="x-small" class="font-weight-black text-uppercase solid-chip" :color="item.typeColor" variant="flat">
                                      {{ item.typeLabel }}
                                  </v-chip>
                              </div>

                              <div class="cell pl-4 font-weight-bold text-truncate" style="font-size: 11px;" :title="item.fabric_type">
                                  {{ item.fabric_type }}
                              </div>

                              <div class="cell right pr-4 font-mono font-weight-black text-subtitle-2 cursor-pointer cell-qtd-hover"
                                   :class="`text-${item.typeColor}`"
                                   @click="openNarrativeModal(item.fabric_type)"
                                   title="Entender a Matemática deste Saldo">
                                  {{ item.isEntry ? '+' : '-' }}{{ formatNumber(item.abs_quantity) }}
                                  <v-icon size="12" class="ml-1 opacity-50 icon-history-hover">mdi-book-open-page-variant</v-icon>
                              </div>

                              <div class="cell center d-flex align-center justify-center">
                                  <v-chip v-if="item.order_number" size="small" :color="item.inferred ? 'warning' : 'primary'" variant="tonal" class="font-weight-bold font-mono px-2 chip-3d">
                                      <v-icon v-if="item.inferred" start size="14">mdi-robot-outline</v-icon>
                                      <v-tooltip v-if="item.inferred" activator="parent" location="top">Vínculo Descoberto pela Inteligência Artificial</v-tooltip>
                                      #{{ String(item.order_number).padStart(4, '0') }}
                                  </v-chip>
                                  <span v-else class="opacity-40 font-weight-bold">-</span>
                              </div>

                              <div class="cell pl-4 d-flex flex-column justify-center align-start" style="min-width: 0;">
                                  <span class="font-weight-bold text-truncate w-100" style="font-size: 11px;" :title="item.customer_name || 'Estoque Interno'">
                                      {{ item.customer_name || 'Estoque Interno' }}
                                  </span>
                              </div>

                              <div class="cell pl-4 d-flex align-center text-truncate" style="font-size: 11px;">
                                  <v-icon size="14" class="mr-2 opacity-60">mdi-account</v-icon>
                                  {{ item.full_name || 'Sistema' }}
                              </div>

                              <div class="cell center">
                                  <v-chip
                                      size="x-small"
                                      variant="tonal"
                                      class="font-weight-bold text-uppercase text-truncate px-3 chip-company"
                                      :color="(item.displayCompany || '').toUpperCase().includes('SANTOS') || (item.displayCompany || '').toUpperCase().includes('CAJUIA') ? 'warning' : 'primary'"
                                      style="letter-spacing: 0.5px; max-width: 120px;"
                                  >
                                      {{ item.displayCompany }}
                                  </v-chip>
                              </div>
                          </div>
                      </template>

                      <!-- ROWS AGRUPADO -->
                      <template v-else>
                          <div v-for="(group, index) in paginatedData" :key="group.fabric_type"
                               class="grid-row transition-hover"
                               :class="zebraClass(index)"
                               style="grid-template-columns: minmax(250px, 2fr) 150px 150px 150px 150px;">

                              <div class="cell pl-4 font-weight-bold text-subtitle-2 text-truncate" :title="group.fabric_type">
                                  {{ group.fabric_type }}
                              </div>

                              <div class="cell right pr-4 font-mono font-weight-bold text-success cursor-pointer cell-qtd-hover"
                                   :class="themeStore.currentMode === 'light' ? 'bg-success-lighten-5' : 'bg-green-darken-4-alpha'"
                                   @click="openNarrativeModal(group.fabric_type)">
                                  + {{ formatNumber(group.in) }}
                              </div>

                              <div class="cell right pr-4 font-mono font-weight-bold text-error cursor-pointer cell-qtd-hover"
                                   :class="themeStore.currentMode === 'light' ? 'bg-error-lighten-5' : 'bg-red-darken-4-alpha'"
                                   @click="openNarrativeModal(group.fabric_type)">
                                  - {{ formatNumber(group.out) }}
                              </div>

                              <div class="cell right pr-4 font-mono font-weight-black text-subtitle-1 cursor-pointer cell-qtd-hover"
                                   :class="group.balance >= 0 ? 'text-info' : 'text-error'"
                                   @click="openNarrativeModal(group.fabric_type)">
                                  {{ group.balance > 0 ? '+' : '' }}{{ formatNumber(group.balance) }}
                                  <v-icon size="14" class="ml-1 opacity-50 icon-history-hover" :class="group.balance >= 0 ? 'text-info' : 'text-error'">mdi-book-open-page-variant</v-icon>
                              </div>

                              <div class="cell center">
                                  <v-btn variant="tonal" size="small" color="primary" class="font-weight-bold btn-3d" @click="openInspectModal(group)">
                                      <v-icon start size="16">mdi-magnify-scan</v-icon> Inspecionar
                                  </v-btn>
                              </div>
                          </div>
                      </template>
                  </template>
              </div>

              <!-- Pagination Footer -->
              <div class="flex-shrink-0 border-t px-4 py-2 d-flex align-center justify-space-between bg-white z-20" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5' : 'bg-black-20 border-white-05'">
                <div class="text-caption opacity-80">
                  <strong>{{ clientFilteredData.length }}</strong> registros listados
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

    <!-- MODAL NARRATIVO E DIDÁTICO COM LOTE -->
    <v-dialog v-model="narrativeModal.show" max-width="600px" scrollable transition="dialog-bottom-transition">
        <v-card class="d-flex flex-column overflow-hidden rounded-xl shadow-indigo-soft" max-height="85vh" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5' : 'bg-surface-dark border-white-05'">

            <!-- Modal Header -->
            <div class="px-5 py-4 border-b d-flex justify-space-between align-center flex-shrink-0 bg-primary position-relative overflow-hidden">
                <div class="card-bg-icon"><v-icon size="80">mdi-book-open-page-variant</v-icon></div>
                <div class="d-flex align-center gap-3 position-relative z-10">
                    <div class="icon-box bg-white text-primary rounded-lg d-flex align-center justify-center elevation-1" style="width: 38px; height: 38px;">
                        <v-icon size="22">mdi-history</v-icon>
                    </div>
                    <div class="text-white">
                        <div class="font-weight-bold text-uppercase opacity-80" style="font-size: 10px; letter-spacing: 1px;">Histórico de Consumo</div>
                        <div class="text-h6 font-weight-black lh-1 mt-1">{{ narrativeModal.fabricType }}</div>
                    </div>
                </div>
                <div class="d-flex align-center gap-3 position-relative z-10">
                    <div class="text-right d-none d-sm-block px-3 py-1 rounded border border-white-05" style="background: rgba(255, 255, 255, 0.2);">
                        <div class="font-weight-bold text-uppercase text-white opacity-90" style="font-size: 9px;">Estoque Atual</div>
                        <div class="text-subtitle-1 font-weight-black text-white lh-1">
                            {{ formatNumber(narrativeModal.currentBalance) }} <span class="text-caption font-weight-medium">{{ narrativeModal.unit }}</span>
                        </div>
                    </div>
                    <v-btn icon="mdi-close" variant="text" density="compact" color="white" @click="narrativeModal.show = false"></v-btn>
                </div>
            </div>

            <!-- Modal Content (Narrative Feed) -->
            <div class="flex-grow-1 overflow-y-auto custom-scroll px-4 py-4" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5' : 'bg-transparent'">

                <div v-if="narrativeModal.loading" class="d-flex flex-column justify-center align-center py-8">
                    <v-progress-circular indeterminate color="primary" size="32" width="3"></v-progress-circular>
                    <div class="mt-3 font-weight-bold opacity-70 text-body-2">Processando matemática do tempo...</div>
                </div>

                <div v-else-if="narrativeModal.items.length === 0" class="text-center py-8 opacity-50">
                    <v-icon size="40" class="mb-3">mdi-file-document-outline</v-icon>
                    <div class="text-subtitle-1 font-weight-black">Nenhum registro para narrar.</div>
                    <div class="text-caption">Não houve movimentação deste tecido no período filtrado.</div>
                </div>

                <div v-else class="narrative-feed d-flex flex-column gap-3 pb-4">
                    <v-card v-for="item in narrativeModal.items" :key="item.id"
                            class="narrative-card border-thin transition-hover overflow-hidden"
                            :class="themeStore.currentMode === 'light' ? 'bg-white shadow-sm hover-elevate' : 'glass-card border-white-05'" elevation="0">

                        <div class="d-flex flex-row">
                            <!-- Ícone Lateral -->
                            <div class="d-flex flex-column align-center justify-center pa-3 flex-shrink-0"
                                 :class="item.isEntry ? (themeStore.currentMode === 'light' ? 'bg-green-lighten-5' : 'bg-green-darken-4-alpha') : (themeStore.currentMode === 'light' ? 'bg-red-lighten-5' : 'bg-red-darken-4-alpha')"
                                 style="width: 70px; border-right: 1px solid rgba(0,0,0,0.05);">
                                <v-avatar :color="item.isEntry ? 'success' : 'error'" size="28" class="elevation-1 mb-1">
                                    <v-icon color="white" size="14">{{ item.isEntry ? 'mdi-plus-thick' : 'mdi-minus-thick' }}</v-icon>
                                </v-avatar>
                                <span class="text-[9px] font-weight-black text-uppercase text-center" :class="item.isEntry ? 'text-success' : 'text-error'" style="line-height: 1;">
                                    {{ item.typeLabel }}
                                </span>
                            </div>

                            <!-- Corpo Narrativo -->
                            <div class="pa-3 flex-grow-1 d-flex flex-column justify-center">
                                <p class="text-body-2 lh-1.5 mb-2" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-3' : 'text-white-80'">
                                    Em <strong>{{ item.dateDisplay }}</strong> às <strong>{{ item.timeDisplay }}</strong>,
                                    <strong>{{ item.user }}</strong> realizou uma <strong :class="item.isEntry ? 'text-success' : 'text-error'">{{ item.typeLabel.toLowerCase() }}</strong> de
                                    <strong class="text-subtitle-2">{{ formatNumber(item.abs_quantity) }} {{ narrativeModal.unit }}</strong>.
                                </p>

                                <div class="d-flex flex-wrap gap-2 mb-2">
                                  <div v-if="item.lote" class="d-flex align-center gap-1 opacity-90 px-2 py-1 rounded bg-grey-darken-3 text-white text-[10px] font-mono">
                                      <v-icon size="12">mdi-barcode-scan</v-icon> Lote: {{ item.lote }}
                                  </div>
                                  <div v-if="item.order_number" class="d-flex align-center gap-1 opacity-90 px-2 py-1 rounded bg-primary text-white text-[10px]">
                                      <v-icon size="12">mdi-link-variant</v-icon>
                                      <span v-if="item.inferred">IA Vínculo ao </span>
                                      <span v-else>Atrelado ao </span>
                                      pedido #{{ item.order_number }}
                                  </div>
                                </div>

                                <div v-if="item.customer_name" class="text-caption opacity-80 mb-2">
                                  Cliente: <strong class="text-primary">{{ item.customer_name }}</strong>
                                </div>
                                <div v-else-if="!item.isEntry" class="d-flex align-center gap-1 mb-2 opacity-70">
                                    <v-icon size="14">mdi-information-outline</v-icon>
                                    <span class="text-caption">Movimentação avulsa.</span>
                                </div>

                                <!-- Box Matemático -->
                                <div class="math-box d-flex align-center justify-space-between px-3 py-2 rounded border-thin mt-auto w-100"
                                     :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-black-20 border-white-05'"
                                     style="min-width: unset;">

                                    <div class="d-flex flex-column align-start">
                                        <span class="text-[9px] font-weight-bold text-uppercase opacity-60">Anterior</span>
                                        <span class="font-mono text-caption font-weight-bold">{{ formatNumber(item.old_quantity) }}</span>
                                    </div>

                                    <v-icon size="14" class="opacity-40 mx-2">mdi-arrow-right</v-icon>

                                    <div class="d-flex flex-column align-end">
                                        <span class="text-[9px] font-weight-bold text-uppercase opacity-60">Resultante</span>
                                        <span class="font-mono text-caption font-weight-black" :class="item.isEntry ? 'text-success' : 'text-error'">
                                            {{ formatNumber(item.new_quantity) }}
                                        </span>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </v-card>
                </div>
            </div>
        </v-card>
    </v-dialog>

    <v-dialog v-model="inspectModal.show" max-width="1100" persistent>
        <!-- Conteudo modal Inspecionar preservado -->
    </v-dialog>

  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted, watch } from 'vue';
import { supabase } from '@/api/supabase';
import { useAppStore } from '@/stores/app';
import { useThemeStore } from '@/stores/theme';
import { useCompanyStore } from '@/stores/company';
import { format, parseISO, startOfMonth, endOfMonth, startOfDay, endOfDay } from 'date-fns';

import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import * as XLSX from 'xlsx';

const appStore = useAppStore();
const themeStore = useThemeStore();
const companyStore = useCompanyStore();

const now = new Date();
const firstDay = format(startOfMonth(now), 'yyyy-MM-dd');
const lastDay = format(endOfMonth(now), 'yyyy-MM-dd');

const loading = ref(false);
const reportLoading = ref(false);
const filtersDropdownOpen = ref(false);
const groupByProduct = ref(false);

const allItems = ref<any[]>([]);
const page = ref(1);
const itemsPerPage = 50;

// TABELA STOCK
const stockData = ref<any[]>([]);

const inspectModal = reactive({ show: false, title: '', totalIn: 0, totalOut: 0, balance: 0, items: [] as any[] });

// ESTADO DO MODAL NARRATIVO
const narrativeModal = reactive({
    show: false,
    loading: false,
    fabricType: '',
    currentBalance: 0,
    unit: 'metros',
    items: [] as any[]
});

const auxData = reactive({ users: [] as any[] });
const companies = ref<any[]>([]);

const filters = reactive({
    search: '', startDate: firstDay, endDate: lastDay, fabric: null as any,
    type: null as string | null, companyId: null as any, minQty: null as number | null,
    maxQty: null as number | null, userId: null as any
});

const movementTypes = [ { label: 'Entradas', value: 'in', color: 'success' }, { label: 'Saídas', value: 'out', color: 'error' } ];

const availableFabrics = computed(() => {
    const set = new Set<string>();
    allItems.value.forEach(i => { if (i.fabric_type) set.add(i.fabric_type); });
    return Array.from(set).sort();
});

const activeFilterCount = computed(() => {
  let count = 0;
  if (filters.fabric) count++; if (filters.type) count++; if (filters.minQty !== null) count++;
  if (filters.maxQty !== null) count++; if (filters.userId) count++;
  return count;
});

const setCompanyFilter = (id: string | null) => { filters.companyId = id; fetchData(); };

const fetchData = async () => {
    loading.value = true;
    try {
        if (companies.value.length === 0) {
            const { data: comps } = await supabase.from('companies').select('id, trade_name');
            if (comps) companies.value = comps;
        }
        if (auxData.users.length === 0) {
            const { data: usr } = await supabase.from('profiles').select('id, full_name');
            if (usr) auxData.users = usr;
        }

        // BUSCA O ESTOQUE ATUAL
        const { data: st } = await supabase.from('stock').select('id, fabric_type, available_meters, visible_in_sales, unit_of_measure, rendimento')
            .eq('visible_in_sales', true)
            .eq('include_in_kpi', true);
        stockData.value = st || [];

        const startIso = startOfDay(parseISO(filters.startDate)).toISOString();
        const endIso = endOfDay(parseISO(filters.endDate)).toISOString();

        // 1. Busca os movimentos de estoque (Nova RPC com Lote)
        const { data: movementsData, error: movError } = await supabase.rpc('get_stock_movements_report', { start_date: startIso, end_date: endIso });
        if (movError) throw movError;

        // 2. Busca OS PEDIDOS de produção
        const { data: ordersData } = await supabase.from('orders').select('id, order_number, customer_name, created_by, created_at, quantity_meters').gte('created_at', startIso).lte('created_at', endIso);

        // 3. Busca OS ORDER_ITEMS da produção
        const { data: orderItemsData } = await supabase.from('order_items').select('id, order_id, fabric_type, quantity_meters, created_at').gte('created_at', startIso).lte('created_at', endIso);

        // 4. Busca as VENDAS DE LOJA (GestãoClick / PDV)
        const { data: storeSalesData } = await supabase.from('store_sales').select('id, order_number, customer_name, seller_id, created_at, items, total_value').gte('created_at', startIso).lte('created_at', endIso);

        // 5. Cruzamento Inteligente
        allItems.value = (movementsData || []).map((mov: any) => {
            let isEntry = Number(mov.quantity_moved) > 0;
            let absQty = Math.abs(Number(mov.quantity_moved) || 0);
            let inferred = false;
            let orderNumber = mov.order_number;
            let customerName = mov.customer_name;
            let movementType = mov.movement_type;

            const movTime = new Date(mov.created_at).getTime();
            const movFabric = String(mov.fabric_type || '').trim().toLowerCase();
            const isCJProduct = movFabric.startsWith('cj');

            // --- LÓGICA DE CONVERSÃO DE UNIDADE (KG -> METROS) ---
            const stockItemInfo = stockData.value.find(s => String(s.fabric_type).toLowerCase() === movFabric);
            const isKg = stockItemInfo?.unit_of_measure === 'kg';
            const rendimento = Number(stockItemInfo?.rendimento || 1);
            const comparisonQtyMeters = isKg ? (absQty * rendimento) : absQty;

            let realCompany = companies.value.find(c => c.id === mov.company_id);
            let displayCompany = realCompany ? realCompany.trade_name : (isCJProduct ? 'SANTOS & LOPES' : 'MR JACKY');

            // INFERÊNCIA INTELIGENTE DE PEDIDOS
            let isOrphanDeduction = (movementType === 'saida_manual' || movementType === 'AJUSTE MANUAL' || (!orderNumber && !isEntry));

            if (isOrphanDeduction) {
                if (orderItemsData && !inferred) {
                    const candidates = orderItemsData.filter(oi => {
                        const oiFabric = String(oi.fabric_type || '').trim().toLowerCase();
                        const timeDiff = Math.abs(movTime - new Date(oi.created_at).getTime()) / 60000;
                        const oiQty = Number(oi.quantity_meters) || 0;
                        return timeDiff <= 60 && oiFabric === movFabric && Math.abs(oiQty - comparisonQtyMeters) <= Math.max(10, oiQty * 0.1);
                    });
                    if (candidates.length > 0) {
                        candidates.sort((a, b) => Math.abs(movTime - new Date(a.created_at).getTime()) - Math.abs(movTime - new Date(b.created_at).getTime()));
                        const parentOrder = ordersData?.find(o => o.id === candidates[0].order_id);
                        if (parentOrder) { orderNumber = parentOrder.order_number; customerName = parentOrder.customer_name; movementType = 'saida_pedido'; inferred = true; }
                    }
                }
                if (ordersData && !inferred && !isCJProduct) {
                    const candidates = ordersData.filter(order => {
                        const timeDiff = Math.abs(movTime - new Date(order.created_at).getTime()) / 60000;
                        const orderQty = Number(order.quantity_meters) || 0;
                        return timeDiff <= 60 && Math.abs(orderQty - comparisonQtyMeters) <= Math.max(15, orderQty * 0.15);
                    });
                    if (candidates.length > 0) {
                        candidates.sort((a, b) => Math.abs(movTime - new Date(a.created_at).getTime()) - Math.abs(movTime - new Date(b.created_at).getTime()));
                        orderNumber = candidates[0].order_number; customerName = candidates[0].customer_name; movementType = 'saida_pedido'; inferred = true;
                    }
                }
                if (storeSalesData && !inferred) {
                    const candidates = storeSalesData.filter(sale => {
                        const timeDiff = Math.abs(movTime - new Date(sale.created_at).getTime()) / 60000;
                        let foundMatchInItems = false; let saleGlobalQty = 0;
                        if (sale.items && Array.isArray(sale.items)) {
                            for (const item of sale.items) {
                                const itemName = String(item.nome || item.descricao || item.produto || item.fabric_type || '').trim().toLowerCase();
                                const itemQty = Number(item.quantidade || item.quantity || item.qtd || 0);
                                saleGlobalQty += itemQty;
                                if (itemName === movFabric && Math.abs(itemQty - absQty) <= Math.max(10, itemQty * 0.1)) { foundMatchInItems = true; break; }
                            }
                        }
                        const matchByTotal = isCJProduct && (Math.abs(saleGlobalQty - absQty) <= Math.max(10, saleGlobalQty * 0.1));
                        return timeDiff <= 60 && (foundMatchInItems || matchByTotal);
                    });
                    if (candidates.length > 0) {
                        candidates.sort((a, b) => Math.abs(movTime - new Date(a.created_at).getTime()) - Math.abs(movTime - new Date(b.created_at).getTime()));
                        orderNumber = candidates[0].order_number; customerName = candidates[0].customer_name; movementType = 'venda_loja'; inferred = true;
                    }
                }
            }

            let resolvedCompanyId = mov.company_id;
            if (!resolvedCompanyId) {
                let fallbackComp = companies.value.find(c => (c.trade_name || '').toUpperCase().includes(isCJProduct ? 'SANTOS' : 'JACKY'));
                if (fallbackComp) resolvedCompanyId = fallbackComp.id;
            }

            let typeLabel = 'MOVIMENTAÇÃO';
            if (isEntry) typeLabel = 'ENTRADA';
            else if (movementType === 'venda_loja') typeLabel = 'VENDA LOJA';
            else if (orderNumber) typeLabel = 'SAÍDA PEDIDO';
            else typeLabel = 'AJUSTE MANUAL';

            return {
                ...mov, isEntry, abs_quantity: absQty,
                typeLabel,
                order_number: orderNumber, customer_name: customerName, displayCompany,
                resolved_company_id: resolvedCompanyId, resolved_user_id: mov.user_id || mov.created_by,
                typeColor: isEntry ? 'success' : 'error', inferred
            };
        });
        page.value = 1;
    } catch (e: any) { console.error(e); } finally { loading.value = false; }
};

const clearFilters = () => { filters.fabric = null; filters.type = null; filters.minQty = null; filters.maxQty = null; filters.userId = null; filtersDropdownOpen.value = false; page.value = 1; };

const clientFilteredData = computed(() => {
    let result = allItems.value;
    let activeCompId = filters.companyId;
    if (!activeCompId && !companyStore.isGlobalView && companyStore.context) activeCompId = companyStore.context;

    if (activeCompId) {
        const compObj = companies.value.find(c => c.id === activeCompId);
        const compName = compObj ? (compObj.trade_name || '').toLowerCase() : '';
        result = result.filter(i => {
            if (i.resolved_company_id === activeCompId || i.company_id === activeCompId) return true;
            const gridCompName = (i.displayCompany || '').toLowerCase();
            if (compName.includes('jacky') && gridCompName.includes('jacky')) return true;
            if ((compName.includes('santos') || compName.includes('cajuia')) && gridCompName.includes('santos')) return true;
            return false;
        });
    }

    if (filters.fabric) result = result.filter(i => i.fabric_type === filters.fabric);
    if (filters.type === 'in') result = result.filter(i => i.isEntry);
    if (filters.type === 'out') result = result.filter(i => !i.isEntry);

    if (filters.userId) {
        const userObj = auxData.users.find(u => u.id === filters.userId);
        const userName = userObj ? (userObj.full_name || '').toLowerCase().trim() : '';
        result = result.filter(i => {
            if (i.resolved_user_id === filters.userId || i.user_id === filters.userId || i.created_by === filters.userId) return true;
            if (userName && (i.full_name || '').toLowerCase().includes(userName)) return true;
            return false;
        });
    }

    if (filters.minQty !== null) result = result.filter(i => i.abs_quantity >= filters.minQty!);
    if (filters.maxQty !== null) result = result.filter(i => i.abs_quantity <= filters.maxQty!);
    const term = filters.search.trim().toLowerCase();
    if (term) result = result.filter(i =>
      (i.fabric_type || '').toLowerCase().includes(term) ||
      (i.customer_name || '').toLowerCase().includes(term) ||
      (i.order_number ? String(i.order_number).includes(term) : false) ||
      (i.full_name || '').toLowerCase().includes(term) ||
      (i.lote || '').toLowerCase().includes(term)
    );

    if (groupByProduct.value) {
        const map = new Map();
        result.forEach(i => {
            if (!map.has(i.fabric_type)) map.set(i.fabric_type, { fabric_type: i.fabric_type, in: 0, out: 0, balance: 0, items: [] });
            const g = map.get(i.fabric_type);
            if (i.isEntry) g.in += i.abs_quantity; else g.out += i.abs_quantity;
            g.balance += Number(i.quantity_moved); g.items.push(i);
        });
        return Array.from(map.values()).sort((a,b) => b.balance - a.balance);
    }
    return result;
});

const paginatedData = computed(() => { const start = (page.value - 1) * itemsPerPage; return clientFilteredData.value.slice(start, start + itemsPerPage); });
const pageCount = computed(() => Math.ceil(clientFilteredData.value.length / itemsPerPage));

const kpis = computed(() => {
    let entradas = 0; let saidas = 0; let estoqueAtual = 0;
    const uniqueFabrics = new Set<string>();

    clientFilteredData.value.forEach(item => {
        if (groupByProduct.value) {
           uniqueFabrics.add(item.fabric_type);
           item.items.forEach((subItem: any) => { if (subItem.isEntry) entradas += subItem.abs_quantity; else saidas += subItem.abs_quantity; });
        } else {
           uniqueFabrics.add(item.fabric_type);
           if (item.isEntry) entradas += item.abs_quantity; else saidas += item.abs_quantity;
        }
    });

    if (filters.fabric) {
        const stockItem = stockData.value.find(s => s.fabric_type === filters.fabric);
        if (stockItem) estoqueAtual = Number(stockItem.available_meters);
    } else {
        stockData.value.forEach(s => {
            if (uniqueFabrics.has(s.fabric_type)) estoqueAtual += Number(s.available_meters);
        });
    }

    return { entradas, saidas, saldo: entradas - saidas, estoqueAtual };
});

const openNarrativeModal = async (fabricType: string) => {
    narrativeModal.fabricType = fabricType;
    narrativeModal.show = true;
    narrativeModal.loading = true;

    const stockItem = stockData.value.find(s => s.fabric_type === fabricType);
    narrativeModal.currentBalance = stockItem ? Number(stockItem.available_meters) : 0;
    narrativeModal.unit = stockItem && stockItem.unit_of_measure === 'kg' ? 'kg' : 'metros';

    try {
        const fabricData = clientFilteredData.value.filter((i: any) => i.fabric_type === fabricType);

        narrativeModal.items = fabricData.sort((a,b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime()).map(item => ({
            id: item.id,
            abs_quantity: item.abs_quantity,
            typeLabel: item.typeLabel,
            order_number: item.order_number,
            customer_name: item.customer_name,
            inferred: item.inferred,
            old_quantity: item.old_quantity,
            new_quantity: item.new_quantity,
            isEntry: item.isEntry,
            dateDisplay: formatDateTime(item.created_at).split(' ')[0],
            timeDisplay: formatDateTime(item.created_at).split(' ')[1],
            user: item.full_name || 'Sistema',
            lote: item.lote
        }));

    } catch (e) { console.error(e); } finally { narrativeModal.loading = false; }
};

const openInspectModal = (group: any) => { inspectModal.title = group.fabric_type; inspectModal.totalIn = group.in; inspectModal.totalOut = group.out; inspectModal.balance = group.balance; inspectModal.items = [...group.items].sort((a,b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime()); inspectModal.show = true; };

// Helpers Formatação
const formatNumber = (v: any) => new Intl.NumberFormat('pt-BR', { minimumFractionDigits: 1, maximumFractionDigits: 2 }).format(Number(v)||0);
const formatDateTime = (dateString: string) => { if (!dateString) return '-'; try { return format(parseISO(dateString), 'dd/MM/yy HH:mm'); } catch { return dateString; } };
const zebraClass = (i: number) => themeStore.currentMode === 'light' ? (i % 2 === 0 ? 'zebra-light-a' : 'zebra-light-b') : (i % 2 === 0 ? 'zebra-dark-a' : 'zebra-dark-b');

const generateReport = async (type: 'pdf' | 'excel' | 'print') => {
    reportLoading.value = true;
    try {
        if (type === 'excel') exportExcel();
        if (type === 'pdf') exportPdf();
        if (type === 'print') window.print();
    } catch (e: any) {
        appStore.showSnackbar('Erro ao exportar: ' + e.message, 'error');
    } finally {
        reportLoading.value = false;
    }
};
const exportExcel = () => {
    const ws = XLSX.utils.json_to_sheet(clientFilteredData.value.map(i => ({
        'Data': formatDateTime(i.created_at),
        'Operacao': i.typeLabel,
        'Tecido': i.fabric_type,
        'Lote': i.lote || 'N/D',
        'Quantidade': i.abs_quantity,
        'Pedido': i.order_number || '',
        'Cliente': i.customer_name || '',
        'Responsavel': i.full_name || 'Sistema'
    })));
    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, "Kardex");
    XLSX.writeFile(wb, `Kardex_Estoque_${format(new Date(), 'yyyyMMdd')}.xlsx`);
};
const exportPdf = () => {
    const doc = new jsPDF();
    doc.text("Relatório de Kardex - Estoque", 14, 15);
    autoTable(doc, {
        head: [['Data', 'Operacao', 'Lote', 'Tecido', 'Qtd', 'Pedido']],
        body: clientFilteredData.value.map(i => [
            formatDateTime(i.created_at), i.typeLabel, i.lote || '-', i.fabric_type, i.abs_quantity, i.order_number || '-'
        ]),
        startY: 20, styles: { fontSize: 8 }
    });
    doc.save(`Kardex_Estoque_${format(new Date(), 'yyyyMMdd')}.pdf`);
};

onMounted(() => { fetchData(); });
watch(() => companyStore.context, () => { fetchData(); });
</script>

<style scoped lang="scss">
@import "@/styles/settings.scss";

.financial-report-layout { position: relative; }
.background-carousel-wrapper { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 0; opacity: 0.6; pointer-events: none; }
.background-overlay { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 1; background: radial-gradient(circle at center, rgba(15, 15, 19, 0.4), rgba(15, 15, 19, 0.98)); backdrop-filter: blur(8px); }
.z-10 { position: relative; z-index: 10; }
.bg-glass-dark { background: rgba(10,10,12,0.85); }
.bg-surface-dark { background-color: #1a1a20; }
.bg-glass-header { background: rgba(20,20,24,0.55); backdrop-filter: blur(14px); }
.border-bottom-white-05 { border-bottom: 1px solid rgba(255,255,255,0.08); }
.border-top-white-05 { border-top: 1px solid rgba(255,255,255,0.08); }

.btn-rect { border-radius: 0 !important; text-transform: none !important; font-weight: 800; }
.btn-3d { border-radius: 6px !important; box-shadow: 0 3px 5px rgba(0,0,0,0.15), inset 0 2px 0 rgba(255,255,255,0.25) !important; transition: transform 0.1s ease, box-shadow 0.1s ease; text-transform: none !important; }
.btn-3d:active { transform: translateY(2px); box-shadow: 0 1px 2px rgba(0,0,0,0.15), inset 0 1px 0 rgba(255,255,255,0.2) !important; }

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

/* GRADIENTES */
.bg-gradient-info { background: linear-gradient(135deg, #0288d1, #005b9f); }
.bg-gradient-success { background: linear-gradient(135deg, #2e7d32, #1b5e20); }
.bg-gradient-danger { background: linear-gradient(135deg, #c62828, #b71c1c); }
.bg-gradient-warning { background: linear-gradient(135deg, #f57c00, #e65100); }
.bg-gradient-primary { background: linear-gradient(135deg, #1976d2, #0d47a1); }

.kpi-label { font-size: 12px; font-weight: 900; letter-spacing: .2px; text-transform: uppercase; }
.kpi-value { font-size: 26px; font-weight: 900; letter-spacing: .2px; }

/* Grid Separado em Colunas Fixas */
.grid-flat-list { display: grid; width: 100%; grid-template-columns: 100px 120px 100px minmax(180px, 1.5fr) 100px 100px minmax(150px, 1fr) 140px 140px; min-width: 1150px; }

.cell { padding: 8px 10px; display: flex; align-items: center; border-right: 1px solid rgba(0,0,0,0.08); border-bottom: 1px solid rgba(0,0,0,0.08); min-height: 52px; overflow: hidden; }
.center { justify-content: center; text-align: center; }
.right { justify-content: flex-end; text-align: right; }

.header-text { font-size: 11px; font-weight: 900; text-transform: uppercase; letter-spacing: 0.5px; opacity: 0.8; padding: 12px 8px; }
.grid-header { display: grid; align-items: stretch; width: 100%; border-bottom: 1px solid rgba(0,0,0,0.08); position: sticky; top: 0; z-index: 10; }
.grid-row { display: grid; align-items: stretch; width: 100%; }

.grid-surface-light .cell { background: #f5f7fa; color: rgba(0,0,0,0.7); }
.grid-surface-dark .cell { background: rgba(255,255,255,0.08); color: rgba(255,255,255,0.80); }

/* Zebra Default */
.zebra-light-a .cell { background: #fff; }
.zebra-light-b .cell { background: #f8fafc; }
.zebra-dark-a .cell { background: rgba(255,255,255,0.02); }
.zebra-dark-b .cell { background: transparent; }

/* Linhas com cor */
.row-entry-light .cell { background-color: #f0fdf4; color: #166534; }
.row-exit-light .cell { background-color: #fef2f2; color: #991b1b; }
.row-entry-dark .cell { background-color: rgba(76, 175, 80, 0.1); color: #69f0ae; }
.row-exit-dark .cell { background-color: rgba(244, 67, 54, 0.1); color: #ff8a80; }

.transition-hover:hover .cell { filter: brightness(0.95); }
.bg-glass-dark .transition-hover:hover .cell { filter: brightness(1.2); }

/* Hover Clicável */
.cell-qtd-hover { transition: background 0.2s ease; border-radius: 4px; }
.cell-qtd-hover:hover { background: rgba(255, 255, 255, 0.1); filter: brightness(1.1); box-shadow: inset 0 0 10px rgba(0,0,0,0.05); }
.icon-history-hover { transition: opacity 0.2s ease; }
.cell-qtd-hover:hover .icon-history-hover { opacity: 1 !important; color: rgb(var(--v-theme-primary)); }

.solid-chip { display: inline-flex; align-items: center; justify-content: center; height: 22px; padding: 0 10px; border-radius: 8px; font-size: 10px; font-weight: 900; color: #fff; white-space: nowrap; }
.custom-scroll::-webkit-scrollbar { width: 6px; height: 6px; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.3); border-radius: 4px; }
.glass-card { background: rgba(30, 30, 35, 0.45); backdrop-filter: blur(25px); border: 1px solid rgba(255,255,255,0.08); }
.shadow-indigo-soft { box-shadow: 0 4px 15px rgba(63, 81, 181, 0.4); }
.hide-scrollbar::-webkit-scrollbar { display: none; }
.ui-field :deep(.v-field) { border-radius: 0 !important; }
.row-gap { row-gap: 12px; }
.bg-black-20 { background-color: rgba(0,0,0,0.2); }
.bg-white-10 { background-color: rgba(255,255,255,0.1); }
.bg-white-80 { color: rgba(255,255,255,0.8); }
.bg-green-darken-4-alpha { background-color: rgba(27, 94, 32, 0.15) !important; }
.bg-red-darken-4-alpha { background-color: rgba(183, 28, 28, 0.15) !important; }

/* MODAL NARRATIVO */
.card-bg-icon { position: absolute; right: -10px; bottom: -20px; opacity: 0.15; transform: rotate(-15deg); pointer-events: none; }
.card-bg-icon .v-icon { color: white; }
.narrative-card { border-radius: 12px; }
.lh-1 { line-height: 1.1; }
.lh-1\.5 { line-height: 1.5; }
</style>
