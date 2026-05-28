<template>
  <div
    class="sales-layout font-sans fill-height d-flex flex-column position-relative overflow-hidden"
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

    <div class="content-wrapper d-flex flex-column fill-height position-relative" style="z-index: 10;">

      <div
        v-if="!isMobileFullscreen"
        class="header-bar px-4 py-3 px-md-6 py-md-4 d-flex flex-column flex-md-row align-md-center justify-space-between flex-shrink-0"
        :class="themeStore.currentMode === 'light' ? 'bg-white border-b border-grey-lighten-2 elevation-1' : 'bg-glass-header border-bottom-white-05'"
        style="gap: 12px;"
      >
        <div class="d-flex flex-column">
          <div class="breadcrumb text-caption d-none d-md-block">
            <span class="opacity-70 cursor-pointer" @click="$router.push({ name: 'AdminReports', params: { reportType: 'hub' } })">Relatórios</span>
            <span class="mx-2 opacity-50">></span>
            <span class="font-weight-bold">Vendas Detalhadas</span>
          </div>
          <div class="d-flex align-center mt-1" style="gap: 8px;">
             <v-btn class="d-md-none mr-1" icon="mdi-arrow-left" variant="text" size="small" @click="$router.push({ name: 'AdminReports', params: { reportType: 'hub' } })"></v-btn>
             <div class="text-h6 font-weight-black" style="letter-spacing: -0.05em; line-height: 1;" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">
                Relatório Analítico de Vendas
             </div>
          </div>

          <div class="d-flex align-center gap-2 mt-3 overflow-x-auto hide-scrollbar pb-1 w-100">
             <v-btn
                v-for="btn in contextButtons"
                :key="btn.id"
                size="x-small"
                height="24"
                :variant="companyStore.context === btn.id ? 'flat' : 'tonal'"
                :color="companyStore.context === btn.id ? (btn.isHolding ? 'purple' : 'success') : 'grey'"
                class="font-weight-bold btn-rect px-3 flex-shrink-0"
                style="font-size: 10px; letter-spacing: 0.5px;"
                @click="setCompanyFilter(btn.id)"
             >
                {{ btn.name }}
             </v-btn>
          </div>
        </div>

        <div class="d-none d-md-flex align-center overflow-x-auto pb-1 pb-md-0" style="gap: 10px;">
          <v-menu location="bottom end">
            <template v-slot:activator="{ props }">
              <v-btn
                v-bind="props"
                color="blue-darken-3"
                variant="flat"
                class="btn-rect px-3 px-md-4 font-weight-bold text-caption text-uppercase flex-shrink-0"
                style="letter-spacing: 1px;"
                prepend-icon="mdi-file-chart"
                height="40"
                :loading="reportLoading"
                :disabled="loading || activeListLength === 0"
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

      <div v-if="!isMobileFullscreen" class="px-4 px-md-6 py-2 flex-shrink-0">
        <v-row class="d-none d-md-flex">
          <v-col cols="12" sm="6" :md="kpiList.length === 5 ? 'auto' : '3'" v-for="(kpi, idx) in kpiList" :key="idx" :style="kpiList.length === 5 ? 'flex-grow: 1;' : ''">
            <v-card
              class="kpi-card kpi-rect bg-gradient-custom hover-elevate py-3 px-4 cursor-pointer"
              :class="[kpi.gradient, kpi.active ? 'kpi-active-border' : '']"
              v-ripple
              elevation="2"
            >
              <div class="kpi-bg-icon"><v-icon>{{ kpi.icon }}</v-icon></div>
              <div class="d-flex flex-column position-relative justify-space-between fill-height" style="z-index: 10;">
                <div class="d-flex align-center" style="gap: 8px;">
                  <v-icon size="18" class="opacity-80">{{ kpi.icon }}</v-icon>
                  <span class="kpi-label">{{ kpi.label }}</span>
                </div>
                <div class="kpi-number-group my-1">
                  <span v-if="kpi.prefix" class="text-body-2 font-weight-medium mr-1 opacity-70">{{ kpi.prefix }}</span>
                  <span class="kpi-value">{{ kpi.value }}</span>
                  <span v-if="kpi.suffix" class="text-caption font-weight-bold ml-1 opacity-70">{{ kpi.suffix }}</span>
                </div>
                <div class="kpi-footer mt-1">{{ kpi.footer }}</div>
              </div>
            </v-card>
          </v-col>
        </v-row>

        <div class="d-block d-md-none kpi-mobile-wrapper my-2">
          <v-window v-model="kpiModel" show-arrows class="elevation-4 rounded-xl overflow-hidden">
             <template v-slot:prev="{ props }">
               <v-btn variant="flat" icon="mdi-chevron-left" @click="props.onClick" color="rgba(0,0,0,0.3)" size="small" class="text-white" style="backdrop-filter: blur(4px);"></v-btn>
             </template>
             <template v-slot:next="{ props }">
               <v-btn variant="flat" icon="mdi-chevron-right" @click="props.onClick" color="rgba(0,0,0,0.3)" size="small" class="text-white" style="backdrop-filter: blur(4px);"></v-btn>
             </template>

             <v-window-item v-for="(kpi, idx) in kpiList" :key="idx">
                <v-card
                    class="kpi-card-mobile d-flex flex-column align-center justify-center py-6 px-4 text-center position-relative"
                    :class="[kpi.gradient]"
                    height="140"
                    elevation="0"
                    v-ripple
                >
                    <div class="kpi-bg-icon-mobile"><v-icon>{{ kpi.icon }}</v-icon></div>
                    <div class="d-flex flex-column align-center position-relative w-100" style="z-index: 10;">
                        <div class="d-flex align-center justify-center mb-1 px-3 py-1 rounded-pill" style="max-width: 80%; background: rgba(255,255,255,0.2); backdrop-filter: blur(4px);">
                            <v-icon size="16" class="mr-2 text-white">{{ kpi.icon }}</v-icon>
                            <span class="text-caption font-weight-black text-uppercase text-white text-truncate" style="letter-spacing: 0.5px;">{{ kpi.label }}</span>
                        </div>
                        <div class="text-h3 font-weight-black text-white my-2 text-shadow-sm">
                           <span v-if="kpi.prefix" class="text-body-2 opacity-80 align-top mr-1">{{ kpi.prefix }}</span>
                           {{ kpi.value }}
                           <span v-if="kpi.suffix" class="text-body-2 opacity-80 align-top ml-1">{{ kpi.suffix }}</span>
                        </div>
                        <div class="text-caption text-white font-weight-medium opacity-90">{{ kpi.footer }}</div>
                    </div>
                </v-card>
             </v-window-item>
          </v-window>
          <div class="d-flex justify-center mt-3" style="gap: 8px;">
              <div
                v-for="(k, i) in kpiList"
                :key="i"
                class="kpi-dot rounded-circle cursor-pointer"
                :class="kpiModel === i ? 'bg-success elevation-2' : 'bg-grey-lighten-2 opacity-50'"
                :style="kpiModel === i ? 'width: 12px; height: 12px; transition: all 0.3s ease;' : 'width: 8px; height: 8px; transition: all 0.3s ease;'"
                @click="kpiModel = i"
              ></div>
          </div>
        </div>
      </div>

      <div v-if="!isMobileFullscreen" class="px-4 px-md-6 pt-0 pb-2 flex-shrink-0">
        <div v-if="mobile" class="d-flex align-center" style="gap: 8px;">
            <v-btn color="blue-darken-3" variant="flat" class="btn-rect flex-shrink-0 px-4" height="44" @click="mobileFiltersOpen = true">
                <v-badge v-if="activeFilterCount > 0" :content="activeFilterCount" color="red" dot floating>
                    <v-icon>mdi-filter-variant</v-icon>
                </v-badge>
                <v-icon v-else>mdi-filter-variant</v-icon>
            </v-btn>

            <div class="flex-grow-1 position-relative search-wrap rounded bg-white border d-flex align-center" style="height: 44px;">
                <input
                  v-model="filters.search"
                  type="text"
                  placeholder="Pesquisar pedido, cliente..."
                  class="clean-input w-100 h-100 px-3 font-weight-bold"
                  style="outline: none;"
                  @keyup.enter="applyFilters"
                />
                <v-btn icon variant="text" density="compact" class="mr-1 text-grey-darken-1" @click="applyFilters">
                    <v-icon>mdi-magnify</v-icon>
                </v-btn>
            </div>
        </div>

        <div
          v-else
          class="controls-bar d-flex flex-column"
          :class="themeStore.currentMode === 'light' ? 'controls-light' : 'controls-dark'"
          style="gap: 10px;"
        >
          <div class="d-flex flex-column flex-md-row align-start align-md-center justify-space-between" style="gap: 10px;">
            <div class="d-flex align-center flex-wrap w-100 w-md-auto" style="gap: 10px;">
              <v-menu location="bottom start">
                <template v-slot:activator="{ props }">
                  <v-btn v-bind="props" variant="outlined" class="btn-rect flex-grow-1 flex-md-grow-0" height="40" prepend-icon="mdi-calendar-range" color="success">
                    Período Rápido
                    <v-icon end size="small">mdi-chevron-down</v-icon>
                  </v-btn>
                </template>
                <v-card class="rounded-0" min-width="220">
                  <v-list density="compact" nav>
                    <v-list-item @click="applyPreset('today')"><v-list-item-title class="font-weight-bold">Hoje</v-list-item-title></v-list-item>
                    <v-list-item @click="applyPreset('week')"><v-list-item-title class="font-weight-bold">Esta Semana</v-list-item-title></v-list-item>
                    <v-list-item @click="applyPreset('month')"><v-list-item-title class="font-weight-bold">Este Mês</v-list-item-title></v-list-item>
                    <v-list-item @click="applyPreset('year')"><v-list-item-title class="font-weight-bold">Este Ano</v-list-item-title></v-list-item>
                  </v-list>
                </v-card>
              </v-menu>

              <div class="period-nav d-flex align-center justify-center flex-grow-1 flex-md-grow-0" :class="themeStore.currentMode === 'light' ? 'period-nav-light' : 'period-nav-dark'">
                 <div class="period-label text-caption font-weight-black text-center px-4 d-flex align-center" style="height: 40px;">
                    <v-icon start size="small" class="mr-2 opacity-50">mdi-calendar</v-icon>
                    {{ formatDateSafe(filters.startDate) }} até {{ formatDateSafe(filters.endDate) }}
                 </div>
              </div>
            </div>

            <div class="d-flex align-center flex-wrap justify-end w-100 w-md-auto" style="gap: 10px;">
              <div class="search-wrap d-flex align-center flex-grow-1 flex-md-grow-0" :class="themeStore.currentMode === 'light' ? 'search-light' : 'search-dark'">
                <v-icon :color="themeStore.currentMode === 'light' ? 'grey-darken-1' : 'white-70'">mdi-magnify</v-icon>
                <input
                  v-model="filters.search"
                  type="text"
                  placeholder="Pesquisar..."
                  class="clean-input flex-grow-1"
                  @keyup.enter="applyFilters"
                />
              </div>

              <v-menu
                v-model="filtersDropdownOpen"
                location="bottom end"
                :close-on-content-click="false"
              >
                <template v-slot:activator="{ props }">
                  <v-btn
                    v-bind="props"
                    variant="outlined"
                    class="btn-rect"
                    height="40"
                    prepend-icon="mdi-filter-variant"
                    :color="activeFilterCount > 0 ? 'success' : (themeStore.currentMode === 'light' ? 'grey-darken-2' : 'white')"
                  >
                    Filtros
                    <v-badge v-if="activeFilterCount > 0" :content="activeFilterCount" color="success" floating class="ml-2"></v-badge>
                    <v-icon end size="small">mdi-chevron-down</v-icon>
                  </v-btn>
                </template>

                <v-card class="rounded-0 pa-4" width="450">
                  <div class="d-flex justify-space-between align-center mb-4 border-b pb-2">
                      <span class="text-caption font-weight-black opacity-70 text-uppercase">Configurar Filtros</span>
                      <v-btn size="x-small" variant="text" color="error" @click="clearFilters">Limpar Tudo</v-btn>
                  </div>
                  <v-row dense class="row-gap">
                    <v-col cols="6"><v-text-field v-model="filters.startDate" label="Data Inicial" type="date" variant="outlined" density="compact" hide-details class="ui-field" color="success" /></v-col>
                    <v-col cols="6"><v-text-field v-model="filters.endDate" label="Data Final" type="date" variant="outlined" density="compact" hide-details class="ui-field" color="success" /></v-col>
                    <v-col cols="12"><v-autocomplete v-model="filters.seller" :items="availableSellers" label="Vendedor Responsável" variant="outlined" density="compact" hide-details clearable class="ui-field" placeholder="Todos" /></v-col>
                    <v-col cols="12">
                      <div class="text-caption font-weight-black opacity-70 mb-2">Status Financeiro</div>
                      <v-select v-model="filters.financialStatus" :items="['Todos', 'Pendente', 'Parcialmente Faturado', 'Faturado', 'Cancelado']" variant="outlined" density="compact" hide-details class="ui-field"></v-select>
                    </v-col>
                  </v-row>
                  <div class="d-flex justify-end mt-6">
                    <v-btn variant="flat" class="btn-rect w-100 font-weight-bold" height="42" color="success" @click="applyFilters">
                      <v-icon start>mdi-magnify</v-icon> Aplicar Filtros
                    </v-btn>
                  </div>
                </v-card>
              </v-menu>
            </div>
          </div>
        </div>
      </div>

      <div
        class="flex-grow-1 overflow-hidden d-flex flex-column"
        :class="[
           isMobileFullscreen ? 'position-absolute w-100 h-100 bg-white' : 'px-4 px-md-6 pb-0',
           mobile ? '' : ''
        ]"
        :style="isMobileFullscreen ? 'top: 0; left: 0; z-index: 20; transition: all 0.3s ease;' : 'transition: all 0.3s ease;'"
      >
        <v-card
          class="flex-grow-1 d-flex flex-column rounded-0 border-thin overflow-hidden"
          :class="themeStore.currentMode === 'light' ? 'bg-white elevation-1' : 'glass-card border-white-05'"
          :elevation="0"
        >
          <div class="d-flex align-center px-4 py-3 border-b" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-4' : 'bg-white-05'">
             <v-btn-group divided variant="outlined" density="comfortable" color="blue-darken-3">
               <v-btn :variant="currentView === 'detailed' ? 'flat' : 'outlined'" @click="currentView = 'detailed'" class="text-none font-weight-bold px-4">
                 <v-icon start size="16">mdi-format-list-bulleted</v-icon> Todas as Vendas
               </v-btn>
               <v-btn :variant="currentView === 'products' ? 'flat' : 'outlined'" @click="currentView = 'products'" class="text-none font-weight-bold px-4">
                 <v-icon start size="16">mdi-tshirt-crew</v-icon> Top Produtos
               </v-btn>
               <v-btn :variant="currentView === 'customers' ? 'flat' : 'outlined'" @click="currentView = 'customers'" class="text-none font-weight-bold px-4">
                 <v-icon start size="16">mdi-account-group</v-icon> Top Clientes
               </v-btn>
             </v-btn-group>
          </div>

          <div v-if="!mobile" class="grid-scroll flex-grow-1 overflow-auto custom-scroll position-relative">

            <template v-if="currentView === 'detailed'">
              <div class="grid-header sticky-head" :class="themeStore.currentMode === 'light' ? 'grid-surface-light' : 'grid-surface-dark'" :style="{ gridTemplateColumns: computedDetailedGridTemplate }">
                <div class="cell center header-text">Origem</div>
                <div class="cell header-text" v-if="companyStore.isGlobalView">Empresa</div>
                <div class="cell cell-ref center header-text">Pedido</div>
                <div class="cell cell-date center header-text">Data</div>
                <div class="cell cell-client header-text">Cliente</div>
                <div class="cell cell-seller header-text">Vendedor</div>
                <div class="cell cell-desc header-text">Tecido / Produto</div>
                <div class="cell cell-val right header-text pr-4">Qtd MT</div>
                <div class="cell cell-val right header-text pr-4">Qtd KG</div>
                <div v-if="hasUnits" class="cell cell-val right header-text pr-4">Qtd UN</div>
                <div class="cell cell-val right header-text pr-4 text-success">Total</div>
                <div class="cell cell-status center header-text">Status</div>
              </div>

              <div v-if="loading" class="d-flex flex-column justify-center align-center h-100 w-100 py-10">
                <v-progress-circular indeterminate color="success" size="32" width="3"></v-progress-circular>
                <span class="text-caption mt-2 font-weight-bold opacity-60">Processando Vendas...</span>
              </div>

              <div v-else-if="paginatedItems.length === 0" class="d-flex flex-column justify-center align-center h-100 w-100 opacity-60 py-10" style="gap: 8px;">
                <v-icon size="48" color="grey-lighten-1">mdi-package-variant-closed</v-icon>
                <span class="text-body-2 font-weight-medium text-grey">Nenhuma venda encontrada para o filtro.</span>
              </div>

              <div v-else v-for="(item, index) in paginatedItems" :key="index" class="grid-row" :class="[themeStore.currentMode === 'light' ? 'grid-row-light' : 'grid-row-dark', zebraClass(index)]" :style="{ gridTemplateColumns: computedDetailedGridTemplate }">
                  <div class="cell center"><span class="solid-chip text-[9px] w-100" :class="item.source === 'orders' ? 'bg-blue-darken-2' : 'bg-orange-darken-2'">{{ item.source_label }}</span></div>
                  <div class="cell" v-if="companyStore.isGlobalView"><span class="text-[11px] font-weight-bold text-truncate">{{ item.company_name }}</span></div>
                  <div class="cell cell-ref center"><span class="pill-ref text-blue-darken-3 bg-blue-lighten-5">#{{ String(item.pedido_id).padStart(4, '0') }}</span></div>
                  <div class="cell cell-date center"><span class="list-text-11 font-mono opacity-80">{{ formatDateSafe(item.data) }}</span></div>
                  <div class="cell cell-client"><div class="text-truncate list-text-11 font-weight-bold" :title="item.cliente">{{ item.cliente }}</div></div>
                  <div class="cell cell-seller"><div class="text-truncate list-text-11 text-grey-darken-2">{{ item.vendedor.split(' ')[0] }}</div></div>
                  <div class="cell cell-desc"><div class="text-truncate list-text-11" :title="item.tecido">{{ item.tecido }}</div></div>

                  <div class="cell cell-val right pr-4"><span v-if="item.qtd_mt > 0" class="list-text-11 font-mono text-info font-weight-black">{{ formatNumber(item.qtd_mt) }}</span><span v-else class="opacity-30">-</span></div>
                  <div class="cell cell-val right pr-4"><span v-if="item.qtd_kg > 0" class="list-text-11 font-mono text-warning font-weight-black">{{ formatNumber(item.qtd_kg) }}</span><span v-else class="opacity-30">-</span></div>
                  <div v-if="hasUnits" class="cell cell-val right pr-4"><span v-if="item.qtd_un > 0" class="list-text-11 font-mono text-purple font-weight-black">{{ formatNumber(item.qtd_un) }}</span><span v-else class="opacity-30">-</span></div>

                  <div class="cell cell-val right pr-4"><span class="list-text-11 font-mono font-weight-black text-success">{{ formatCurrency(item.valor_total_item) }}</span></div>
                  <div class="cell cell-status center"><span class="solid-chip" :class="getStatusChipClass(item.status_financeiro)">{{ item.status_financeiro }}</span></div>
              </div>
            </template>

            <template v-else-if="currentView === 'products'">
              <div class="grid-header sticky-head grid-ranking" :class="themeStore.currentMode === 'light' ? 'grid-surface-light' : 'grid-surface-dark'" :style="{ gridTemplateColumns: computedRankingGridTemplate }">
                <div class="cell center header-text">Rank</div>
                <div class="cell header-text">Tecido / Produto</div>
                <div class="cell center header-text">Pedidos</div>
                <div class="cell right header-text pr-4">Volume (MT)</div>
                <div class="cell right header-text pr-4">Volume (KG)</div>
                <div v-if="hasUnits" class="cell right header-text pr-4">Volume (UN)</div>
                <div class="cell right header-text pr-4 text-success">Total Faturado</div>
              </div>

              <div v-if="loading" class="d-flex flex-column justify-center align-center h-100 w-100 py-10">
                <v-progress-circular indeterminate color="success" size="32" width="3"></v-progress-circular>
              </div>

              <div v-else-if="paginatedProducts.length === 0" class="d-flex flex-column justify-center align-center h-100 w-100 opacity-60 py-10" style="gap: 8px;">
                <v-icon size="48" color="grey-lighten-1">mdi-tshirt-crew-outline</v-icon>
                <span class="text-body-2 font-weight-medium text-grey">Nenhum produto nos filtros atuais.</span>
              </div>

              <div v-else v-for="(item, index) in paginatedProducts" :key="index" class="grid-row grid-ranking" :class="[themeStore.currentMode === 'light' ? 'grid-row-light' : 'grid-row-dark', zebraClass(index), getRankRowClass(index, page)]" :style="{ gridTemplateColumns: computedRankingGridTemplate }">
                <div class="cell center">
                  <span class="pill-ref text-white" :class="getRankBadgeClass(index, page)">
                    {{ index + 1 + (page - 1) * itemsPerPage }}º
                  </span>
                </div>
                <div class="cell"><div class="text-truncate list-text-11 font-weight-bold">{{ item.tecido }}</div></div>
                <div class="cell center"><span class="list-text-11 font-weight-medium">{{ item.pedidos_count }}</span></div>
                <div class="cell right pr-4"><span class="list-text-11 font-mono text-info font-weight-bold">{{ formatNumber(item.qtd_mt) }}</span></div>
                <div class="cell right pr-4"><span class="list-text-11 font-mono text-warning font-weight-bold">{{ formatNumber(item.qtd_kg) }}</span></div>
                <div v-if="hasUnits" class="cell right pr-4"><span class="list-text-11 font-mono text-purple font-weight-bold">{{ formatNumber(item.qtd_un) }}</span></div>
                <div class="cell right pr-4"><span class="list-text-11 font-mono font-weight-black text-success">{{ formatCurrency(item.valor_total) }}</span></div>
              </div>
            </template>

            <template v-else-if="currentView === 'customers'">
              <div class="grid-header sticky-head grid-ranking" :class="themeStore.currentMode === 'light' ? 'grid-surface-light' : 'grid-surface-dark'" :style="{ gridTemplateColumns: computedRankingGridTemplate }">
                <div class="cell center header-text">Rank</div>
                <div class="cell header-text">Cliente</div>
                <div class="cell center header-text">Pedidos</div>
                <div class="cell right header-text pr-4">Volume (MT)</div>
                <div class="cell right header-text pr-4">Volume (KG)</div>
                <div v-if="hasUnits" class="cell right header-text pr-4">Volume (UN)</div>
                <div class="cell right header-text pr-4 text-success">Total Comprado</div>
              </div>

              <div v-if="loading" class="d-flex flex-column justify-center align-center h-100 w-100 py-10">
                <v-progress-circular indeterminate color="success" size="32" width="3"></v-progress-circular>
              </div>

              <div v-else-if="paginatedCustomers.length === 0" class="d-flex flex-column justify-center align-center h-100 w-100 opacity-60 py-10" style="gap: 8px;">
                <v-icon size="48" color="grey-lighten-1">mdi-account-group-outline</v-icon>
                <span class="text-body-2 font-weight-medium text-grey">Nenhum cliente nos filtros atuais.</span>
              </div>

              <div v-else v-for="(item, index) in paginatedCustomers" :key="index" class="grid-row grid-ranking" :class="[themeStore.currentMode === 'light' ? 'grid-row-light' : 'grid-row-dark', zebraClass(index), getRankRowClass(index, page)]" :style="{ gridTemplateColumns: computedRankingGridTemplate }">
                <div class="cell center">
                  <span class="pill-ref text-white" :class="getRankBadgeClass(index, page)">
                    {{ index + 1 + (page - 1) * itemsPerPage }}º
                  </span>
                </div>
                <div class="cell"><div class="text-truncate list-text-11 font-weight-bold">{{ item.cliente }}</div></div>
                <div class="cell center"><span class="list-text-11 font-weight-medium">{{ item.pedidos_count }}</span></div>
                <div class="cell right pr-4"><span class="list-text-11 font-mono text-info font-weight-bold">{{ formatNumber(item.qtd_mt) }}</span></div>
                <div class="cell right pr-4"><span class="list-text-11 font-mono text-warning font-weight-bold">{{ formatNumber(item.qtd_kg) }}</span></div>
                <div v-if="hasUnits" class="cell right pr-4"><span class="list-text-11 font-mono text-purple font-weight-bold">{{ formatNumber(item.qtd_un) }}</span></div>
                <div class="cell right pr-4"><span class="list-text-11 font-mono font-weight-black text-success">{{ formatCurrency(item.valor_total) }}</span></div>
              </div>
            </template>
          </div>

          <div v-else class="flex-grow-1 overflow-y-auto bg-grey-lighten-4 pb-12 custom-scroll">
              <div v-if="loading" class="d-flex flex-column align-center justify-center py-8">
                  <v-progress-circular indeterminate color="success"></v-progress-circular>
              </div>
              <div v-else-if="activeListLength === 0" class="d-flex flex-column align-center justify-center py-10 opacity-60">
                   <v-icon size="40">mdi-filter-off</v-icon>
                   <span class="text-caption mt-2">Nenhum registro encontrado</span>
              </div>
          </div>

          <div class="flex-shrink-0 border-t px-4 py-2 d-flex flex-column flex-md-row align-center justify-space-between bg-white" style="z-index: 20;">
            <div class="d-flex align-center justify-space-between w-100 w-md-auto mb-2 mb-md-0">
               <div class="text-caption opacity-80">
                 <strong>{{ activeListLength }}</strong> registros | Pág. {{ page }}/{{ pageCount || 1 }}
               </div>
               <v-btn
                 v-if="mobile && !isMobileFullscreen"
                 size="small"
                 variant="text"
                 color="primary"
                 prepend-icon="mdi-fullscreen"
                 @click="isMobileFullscreen = true"
               >
                 Expandir Lista
               </v-btn>
            </div>

            <v-pagination
              v-model="page"
              :length="pageCount"
              :total-visible="mobile ? 3 : 5"
              density="compact"
              active-color="success"
              variant="tonal"
              size="small"
            ></v-pagination>
          </div>
        </v-card>
      </div>
    </div>

    <v-dialog v-model="mobileFiltersOpen" fullscreen transition="dialog-bottom-transition" scrim="black">
        </v-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, reactive, onMounted, watch } from 'vue';
import { useThemeStore } from '@/stores/theme';
import { useAppStore } from '@/stores/app';
import { useCompanyStore } from '@/stores/company';
import { useUserStore } from '@/stores/user';
import { supabase } from '@/api/supabase';
import { format, parseISO, startOfMonth, endOfMonth, startOfWeek, endOfWeek, startOfYear, endOfYear } from 'date-fns';
import { useDisplay } from 'vuetify';

import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import * as XLSX from 'xlsx';

import logoMjlm from '@/assets/logomjlm.png';
import logoCajuia from '@/assets/logocajuia.png';

const { mobile } = useDisplay();
const themeStore = useThemeStore();
const appStore = useAppStore();
const companyStore = useCompanyStore();
const userStore = useUserStore();

const isDark = computed(() => themeStore.currentMode !== 'light');
const isMobileFullscreen = ref(false);
const loading = ref(false);
const reportLoading = ref(false);
const rawItems = ref<any[]>([]);
const availableSellers = ref<string[]>([]);
const kpiModel = ref(0);

const filtersDropdownOpen = ref(false);
const mobileFiltersOpen = ref(false);

const page = ref(1);
const itemsPerPage = 30;

const currentView = ref('detailed'); // 'detailed' | 'products' | 'customers'

// Verifica se existem itens unitários (UN) para ativar as colunas do PDV
const hasUnits = computed(() => {
    return filteredItems.value.some(i => i.qtd_un > 0);
});

watch(currentView, () => {
    page.value = 1;
});

const filters = reactive({
    search: '',
    startDate: format(startOfMonth(new Date()), 'yyyy-MM-dd'),
    endDate: format(endOfMonth(new Date()), 'yyyy-MM-dd'),
    seller: null as string | null,
    financialStatus: 'Todos'
});

const auxData = reactive({
    companies: [] as any[]
});

const contextButtons = computed(() => {
    const btns = [];
    const comps = companyStore.availableCompanies || [];
    if (comps.length > 0) btns.push({ id: comps[0].id, name: comps[0].trade_name, isHolding: false });
    if (comps.length > 1) btns.push({ id: comps[1].id, name: comps[1].trade_name, isHolding: false });
    btns.push({ id: 'global', name: 'HOLDING / GLOBAL', isHolding: true });
    for (let i = 2; i < comps.length; i++) {
        btns.push({ id: comps[i].id, name: comps[i].trade_name, isHolding: false });
    }
    return btns;
});

const setCompanyFilter = (id: string | null) => {
    companyStore.setContext(id || 'global');
    applyFilters();
};

const computedDetailedGridTemplate = computed(() => {
    let base = companyStore.isGlobalView
        ? '80px 100px 75px 85px minmax(130px, 1.8fr) minmax(100px, 1fr) minmax(130px, 1.5fr) 70px 80px '
        : '80px 75px 85px minmax(130px, 1.8fr) minmax(100px, 1fr) minmax(130px, 1.5fr) 70px 80px ';

    if (hasUnits.value) base += '70px '; // Adiciona coluna UN
    base += '95px 110px'; // Total e Status
    return base;
});

const computedRankingGridTemplate = computed(() => {
    let base = '70px minmax(250px, 2fr) 100px 100px 100px ';
    if (hasUnits.value) base += '100px ';
    base += '140px';
    return base;
});

const getRankBadgeClass = (index: number, pageNum: number, textOnly = false) => {
    if (pageNum !== 1) return textOnly ? 'opacity-50' : 'bg-blue-grey-darken-2';
    if (index === 0) return textOnly ? 'text-amber-darken-2' : 'bg-amber-darken-2';
    if (index === 1) return textOnly ? 'text-grey-darken-1' : 'bg-grey-darken-1';
    if (index === 2) return textOnly ? 'text-brown-darken-1' : 'bg-brown-darken-1';
    return textOnly ? 'opacity-50' : 'bg-blue-grey-darken-2';
};

const getRankRowClass = (index: number, pageNum: number) => {
    if (pageNum !== 1) return '';
    if (index === 0) return 'row-rank-1';
    if (index === 1) return 'row-rank-2';
    if (index === 2) return 'row-rank-3';
    return '';
};

// --- KPIs ---
const kpiList = computed(() => {
    const items = filteredItems.value;
    const uniqueOrders = new Set(items.map(i => i.pedido_id));

    const rev = items.reduce((acc, i) => acc + i.valor_total_item, 0);
    const mt = items.reduce((acc, i) => acc + i.qtd_mt, 0);
    const kg = items.reduce((acc, i) => acc + i.qtd_kg, 0);
    const un = items.reduce((acc, i) => acc + i.qtd_un, 0);

    const list = [
        { label: 'Receita Total', value: formatCurrencyValue(rev), prefix: 'R$', footer: 'Faturamento Bruto', icon: 'mdi-currency-usd', gradient: 'bg-gradient-green', active: false },
        { label: 'Volume (Metros)', value: formatNumber(mt), suffix: 'MT', footer: 'Produção Linear', icon: 'mdi-ruler', gradient: 'bg-gradient-info', active: false },
        { label: 'Volume (Quilos)', value: formatNumber(kg), suffix: 'KG', footer: 'Produção em Peso', icon: 'mdi-weight-kilogram', gradient: 'bg-gradient-warning', active: false },
    ];

    if (un > 0) {
        list.push({ label: 'Volume (Unidade/Metro)', value: formatNumber(un), suffix: 'UN', footer: 'Unidades/Metros', icon: 'mdi-cube-outline', gradient: 'bg-gradient-danger', active: false });
    }

    list.push({ label: 'Total Pedidos', value: uniqueOrders.size, footer: 'Pedidos Atendidos', icon: 'mdi-shopping', gradient: 'bg-gradient-purple', active: false });

    return list;
});

// --- UTILS ---
const formatCurrency = (val: number) => new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(val || 0);
const formatCurrencyValue = (val: number) => new Intl.NumberFormat('pt-BR', { minimumFractionDigits: 2, maximumFractionDigits: 2 }).format(val || 0);
const formatNumber = (val: number) => new Intl.NumberFormat('pt-BR', { minimumFractionDigits: 2, maximumFractionDigits: 2 }).format(val || 0);
const formatDateSafe = (d: string) => d ? format(parseISO(d), 'dd/MM/yyyy') : '-';
const zebraClass = (i:number) => themeStore.currentMode!=='light' ? (i%2===0?'zebra-dark-a':'zebra-dark-b') : (i%2===0?'zebra-light-a':'zebra-light-b');

const getStatusChipClass = (s: string) => {
    if (s === 'Faturado') return 'chip-success';
    if (s === 'Parcialmente Faturado' || s === 'P. Faturado') return 'chip-warn';
    if (s === 'Cancelado') return 'chip-danger';
    return 'chip-info';
};

const activeFilterCount = computed(() => {
  let c = 0;
  if (filters.search) c++;
  if (filters.seller) c++;
  if (filters.financialStatus !== 'Todos') c++;
  return c;
});

// --- DATA FETCHING (MULTI-TENANT / MULTI-SOURCE) ---
const fetchData = async () => {
    loading.value = true;
    try {
        const { data: compData } = await supabase.from('companies').select('id, trade_name');
        auxData.companies = compData || [];
        const compMap = new Map();
        auxData.companies.forEach(c => compMap.set(c.id, c.trade_name));

        const fetchAllRecords = async (table: string, selectFields: string, dateField: string) => {
            let results: any[] = [];
            let from = 0;
            const step = 999;
            let hasMore = true;
            let safetyLimit = 0;

            let query = supabase.from(table).select(selectFields);

            if (filters.startDate) query = query.gte(dateField, `${filters.startDate}T00:00:00`);
            if (filters.endDate) query = query.lte(dateField, `${filters.endDate}T23:59:59`);

            if (filters.financialStatus !== 'Todos') {
                const translatedStatus = filters.financialStatus === 'P. Faturado' ? 'Parcialmente Faturado' : filters.financialStatus;
                query = query.eq('financial_status', translatedStatus);
            }
            if (!companyStore.isGlobalView && companyStore.context) {
                query = query.eq('company_id', companyStore.context);
            }

            while (hasMore && safetyLimit < 50) {
                safetyLimit++;
                const { data, error } = await query.order('created_at', { ascending: false }).range(from, from + step);

                if (error) throw error;
                if (data && data.length > 0) {
                    results = results.concat(data);
                    if (data.length <= step) hasMore = false;
                    else from += step + 1;
                } else {
                    hasMore = false;
                }
            }
            return results;
        };

        const ordersData = await fetchAllRecords('orders', 'id, order_number, created_at, customer_name, financial_status, created_by, creator:created_by(full_name), customer:customers_mj(nome, razao_social), company_id', 'created_at');
        const pdvData = await fetchAllRecords('store_sales', 'id, order_number, date_sale, created_at, customer_name, seller_name, financial_status, items, company_id', 'date_sale');

        let allItems: any[] = [];
        const orderIds = (ordersData || []).map(o => o.id);

        if (orderIds.length > 0) {
            const chunkSize = 150;
            for (let i = 0; i < orderIds.length; i += chunkSize) {
                const chunk = orderIds.slice(i, i + chunkSize);
                const { data: itemsChunk } = await supabase.from('order_items').select('*').in('order_id', chunk);
                if (itemsChunk) allItems = [...allItems, ...itemsChunk];
            }
        }

        const processedOrders = allItems.map(item => {
            const order = (ordersData || []).find(o => o.id === item.order_id);
            if (!order) return null;

            const rawMt = Number(item.quantity_meters || 0);
            const rawKg = Number(item.quantity_unit || 0);
            const val_total = Number(item.total_value_items || 0);

            let qtd_mt = 0; let qtd_kg = 0; let qtd_un = 0;
            let und = String(item.unit_of_measure || '').toUpperCase().trim();
            if (!und) { if (rawKg > 0 && rawMt === 0) und = 'KG'; else und = 'MT'; }

            if (und === 'KG') { qtd_kg = rawKg > 0 ? rawKg : rawMt; }
            else if (und === 'MT') { qtd_mt = rawMt > 0 ? rawMt : rawKg; }
            else { qtd_un = rawMt > 0 ? rawMt : rawKg; }

            const preco_unit_kg = qtd_kg > 0 ? val_total / qtd_kg : 0;
            const preco_unit_mt = qtd_mt > 0 ? val_total / qtd_mt : 0;
            const clienteNome = order.customer?.nome || order.customer?.razao_social || order.customer_name || 'Consumidor';

            return {
                source: 'orders',
                source_label: 'PDV Textil',
                company_id: order.company_id,
                company_name: compMap.get(order.company_id) || 'Sem Empresa',
                pedido_id: order.order_number,
                data: order.created_at,
                mes_ano: format(parseISO(order.created_at), 'MM/yyyy'),
                cliente: clienteNome,
                vendedor: order.creator?.full_name || 'Sistema',
                tecido: item.fabric_type || 'Produto Diverso',
                qtd_mt, preco_unit_mt, qtd_kg, preco_unit_kg, qtd_un, valor_total_item: val_total,
                status_financeiro: (order.financial_status === 'Parcialmente Faturado') ? 'P. Faturado' : (order.financial_status || 'Pendente'),
                order_id: order.id
            };
        }).filter(Boolean);

        const processedPDV = (pdvData || []).flatMap(sale => {
            let itemsArray = [];
            if (sale.items) {
                if (typeof sale.items === 'string') {
                    try { itemsArray = JSON.parse(sale.items); } catch(e){}
                } else if (Array.isArray(sale.items)) {
                    itemsArray = sale.items;
                }
            }

            return itemsArray.map((raw: any) => {
                const prod = raw.produto || raw;
                const qtd = Number(prod.quantidade || raw.quantity || 0);
                const vUnit = Number(prod.valor_unitario || raw.unit_price || 0);
                const vTot = Number(prod.valor_total || raw.total_price || (qtd * vUnit));
                const und = String(prod.tamanho || raw.size || 'UN').toUpperCase();

                let qtd_mt = 0; let qtd_kg = 0; let qtd_un = 0;
                if (und === 'MT') { qtd_mt = qtd; }
                else if (und === 'KG') { qtd_kg = qtd; }
                else { qtd_un = qtd; }

                let preco_unit_mt = qtd_mt > 0 ? vTot / qtd_mt : 0;
                let preco_unit_kg = qtd_kg > 0 ? vTot / qtd_kg : 0;

                return {
                    source: 'store_sales',
                    source_label: 'PDV',
                    company_id: sale.company_id,
                    company_name: compMap.get(sale.company_id) || 'Sem Empresa',
                    pedido_id: sale.order_number || '-',
                    data: sale.date_sale || sale.created_at,
                    mes_ano: format(parseISO(sale.date_sale || sale.created_at), 'MM/yyyy'),
                    cliente: sale.customer_name || 'Consumidor Balcão',
                    vendedor: sale.seller_name || 'PDV',
                    tecido: prod.nome_produto || raw.product_name || 'Produto Varejo PDV',
                    qtd_mt, preco_unit_mt, qtd_kg, preco_unit_kg, qtd_un, valor_total_item: vTot,
                    status_financeiro: (sale.financial_status === 'Parcialmente Faturado') ? 'P. Faturado' : (sale.financial_status || 'Pendente'),
                    order_id: sale.id
                };
            });
        });

        const combined = [...processedOrders, ...processedPDV];
        rawItems.value = combined.sort((a: any, b: any) => new Date(b.data).getTime() - new Date(a.data).getTime());

        const sellersSet = new Set<string>();
        combined.forEach(o => { if (o.vendedor) sellersSet.add(o.vendedor); });
        availableSellers.value = Array.from(sellersSet).sort();

    } catch (error: any) {
        console.error(error);
        appStore.showSnackbar("Erro ao buscar dados multi-tenant.", "error");
    } finally {
        loading.value = false;
    }
};

const applyFilters = () => {
    filtersDropdownOpen.value = false;
    page.value = 1;
    fetchData();
};

const applyPreset = (preset: string) => {
    const today = new Date();
    if (preset === 'today') {
        filters.startDate = format(today, 'yyyy-MM-dd');
        filters.endDate = format(today, 'yyyy-MM-dd');
    } else if (preset === 'week') {
        filters.startDate = format(startOfWeek(today, { weekStartsOn: 1 }), 'yyyy-MM-dd');
        filters.endDate = format(endOfWeek(today, { weekStartsOn: 1 }), 'yyyy-MM-dd');
    } else if (preset === 'month') {
        filters.startDate = format(startOfMonth(today), 'yyyy-MM-dd');
        filters.endDate = format(endOfMonth(today), 'yyyy-MM-dd');
    } else if (preset === 'year') {
        filters.startDate = format(startOfYear(today), 'yyyy-MM-dd');
        filters.endDate = format(endOfYear(today), 'yyyy-MM-dd');
    }
    applyFilters();
};

const clearFilters = () => {
    filters.search = '';
    filters.seller = null;
    filters.financialStatus = 'Todos';
    applyPreset('month');
};

const filteredItems = computed(() => {
    if (!filters.search) return rawItems.value;
    const s = filters.search.toLowerCase();
    return rawItems.value.filter(i =>
        String(i.pedido_id).includes(s) ||
        (i.company_name && i.company_name.toLowerCase().includes(s)) ||
        i.cliente.toLowerCase().includes(s) ||
        i.tecido.toLowerCase().includes(s) ||
        i.vendedor.toLowerCase().includes(s)
    );
});

const topProducts = computed(() => {
    const map = new Map();
    filteredItems.value.forEach(item => {
        const key = item.tecido;
        if (!map.has(key)) {
            map.set(key, { tecido: key, qtd_mt: 0, qtd_kg: 0, qtd_un: 0, valor_total: 0, pedidos: new Set() });
        }
        const data = map.get(key);
        data.qtd_mt += item.qtd_mt;
        data.qtd_kg += item.qtd_kg;
        data.qtd_un += item.qtd_un;
        data.valor_total += item.valor_total_item;
        data.pedidos.add(item.pedido_id);
    });
    return Array.from(map.values())
        .map(d => ({ ...d, pedidos_count: d.pedidos.size }))
        .sort((a, b) => b.valor_total - a.valor_total);
});

const topCustomers = computed(() => {
    const map = new Map();
    filteredItems.value.forEach(item => {
        const key = item.cliente;
        if (!map.has(key)) {
            map.set(key, { cliente: key, qtd_mt: 0, qtd_kg: 0, qtd_un: 0, valor_total: 0, pedidos: new Set() });
        }
        const data = map.get(key);
        data.qtd_mt += item.qtd_mt;
        data.qtd_kg += item.qtd_kg;
        data.qtd_un += item.qtd_un;
        data.valor_total += item.valor_total_item;
        data.pedidos.add(item.pedido_id);
    });
    return Array.from(map.values())
        .map(d => ({ ...d, pedidos_count: d.pedidos.size }))
        .sort((a, b) => b.valor_total - a.valor_total);
});

const activeListLength = computed(() => {
    if (currentView.value === 'detailed') return filteredItems.value.length;
    if (currentView.value === 'products') return topProducts.value.length;
    if (currentView.value === 'customers') return topCustomers.value.length;
    return 0;
});

const pageCount = computed(() => Math.ceil(activeListLength.value / itemsPerPage));

const paginatedItems = computed(() => {
    const start = (page.value - 1) * itemsPerPage;
    return filteredItems.value.slice(start, start + itemsPerPage);
});

const paginatedProducts = computed(() => {
    const start = (page.value - 1) * itemsPerPage;
    return topProducts.value.slice(start, start + itemsPerPage);
});

const paginatedCustomers = computed(() => {
    const start = (page.value - 1) * itemsPerPage;
    return topCustomers.value.slice(start, start + itemsPerPage);
});

const generateReport = async (type: 'pdf' | 'excel' | 'print') => {
    reportLoading.value = true;

    let dataToExport: any[] = [];
    let reportTitle = '';
    let pdfColumns: any[] = [];
    let htmlHeaders = '';

    if (currentView.value === 'detailed') {
        dataToExport = filteredItems.value;
        reportTitle = 'RELATÓRIO ANALÍTICO DE VENDAS';

        pdfColumns = [
            { header: 'ORIGEM', dataKey: 'origem' },
            ...(companyStore.isGlobalView ? [{ header: 'EMPRESA', dataKey: 'empresa' }] : []),
            { header: 'PEDIDO', dataKey: 'pedido' },
            { header: 'DATA', dataKey: 'data' },
            { header: 'CLIENTE', dataKey: 'cliente' },
            { header: 'VEND', dataKey: 'vendedor' },
            { header: 'TECIDO', dataKey: 'tecido' },
            { header: 'MT', dataKey: 'mt' },
            { header: 'KG', dataKey: 'kg' }
        ];

        if (hasUnits.value) pdfColumns.push({ header: 'UN', dataKey: 'un' });

        pdfColumns.push(
            { header: 'TOTAL', dataKey: 'total' },
            { header: 'STATUS', dataKey: 'status' }
        );

        htmlHeaders = `
            <th class="text-center" style="width: 50px;">Origem</th>
            ${companyStore.isGlobalView ? '<th>Empresa</th>' : ''}
            <th class="text-center" style="width: 50px;">Pedido</th>
            <th class="text-center" style="width: 65px;">Data</th>
            <th>Cliente</th>
            <th>Vendedor</th>
            <th>Tecido</th>
            <th class="text-right" style="width: 40px;">MT</th>
            <th class="text-right" style="width: 40px;">KG</th>
            ${hasUnits.value ? '<th class="text-right" style="width: 40px;">UN</th>' : ''}
            <th class="text-right" style="width: 65px;">Total</th>
            <th class="text-center" style="width: 60px;">Status</th>
        `;
    } else if (currentView.value === 'products') {
        dataToExport = topProducts.value;
        reportTitle = 'RANKING DE PRODUTOS (MAIS VENDIDOS)';
        pdfColumns = [
            { header: 'RANK', dataKey: 'rank' },
            { header: 'TECIDO / PRODUTO', dataKey: 'produto' },
            { header: 'PEDIDOS', dataKey: 'pedidos' },
            { header: 'VOL (MT)', dataKey: 'mt' },
            { header: 'VOL (KG)', dataKey: 'kg' }
        ];

        if (hasUnits.value) pdfColumns.push({ header: 'VOL (UN)', dataKey: 'un' });
        pdfColumns.push({ header: 'TOTAL FATURADO', dataKey: 'total' });

        htmlHeaders = `
            <th class="text-center" style="width: 40px;">Rank</th>
            <th>Tecido / Produto</th>
            <th class="text-center" style="width: 50px;">Pedidos</th>
            <th class="text-right" style="width: 50px;">Vol (MT)</th>
            <th class="text-right" style="width: 50px;">Vol (KG)</th>
            ${hasUnits.value ? '<th class="text-right" style="width: 50px;">Vol (UN)</th>' : ''}
            <th class="text-right" style="width: 80px;">Total Faturado</th>
        `;
    } else if (currentView.value === 'customers') {
        dataToExport = topCustomers.value;
        reportTitle = 'RANKING DE CLIENTES';
        pdfColumns = [
            { header: 'RANK', dataKey: 'rank' },
            { header: 'CLIENTE', dataKey: 'cliente' },
            { header: 'PEDIDOS', dataKey: 'pedidos' },
            { header: 'VOL (MT)', dataKey: 'mt' },
            { header: 'VOL (KG)', dataKey: 'kg' }
        ];

        if (hasUnits.value) pdfColumns.push({ header: 'VOL (UN)', dataKey: 'un' });
        pdfColumns.push({ header: 'TOTAL COMPRADO', dataKey: 'total' });

        htmlHeaders = `
            <th class="text-center" style="width: 40px;">Rank</th>
            <th>Cliente</th>
            <th class="text-center" style="width: 50px;">Pedidos</th>
            <th class="text-right" style="width: 50px;">Vol (MT)</th>
            <th class="text-right" style="width: 50px;">Vol (KG)</th>
            ${hasUnits.value ? '<th class="text-right" style="width: 50px;">Vol (UN)</th>' : ''}
            <th class="text-right" style="width: 80px;">Total Comprado</th>
        `;
    }

    if (dataToExport.length === 0) {
        appStore.showSnackbar('Nenhum dado para exportar nesta visualização.', 'warning');
        reportLoading.value = false;
        return;
    }

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

    // Cálculos Globais (A partir dos items originais)
    const totalVal = filteredItems.value.reduce((acc, i) => acc + i.valor_total_item, 0);
    const totalMt = filteredItems.value.reduce((acc, i) => acc + i.qtd_mt, 0);
    const totalKg = filteredItems.value.reduce((acc, i) => acc + i.qtd_kg, 0);
    const totalUn = filteredItems.value.reduce((acc, i) => acc + i.qtd_un, 0);
    const totalPedidos = new Set(filteredItems.value.map(i => i.pedido_id)).size;

    const generateTop5Html = () => {
        const top5 = topProducts.value.slice(0, 5);
        if (top5.length === 0) return '';

        let rows = top5.map((p, idx) => `
            <tr>
                <td style="text-align: center; font-weight: bold; width: 30px;">${idx + 1}º</td>
                <td>${p.tecido}</td>
                <td style="text-align: center;">${p.pedidos_count}</td>
                <td style="text-align: right; color: #166534; font-weight: bold;">${formatCurrency(p.valor_total)}</td>
            </tr>
        `).join('');

        return `
        <div style="margin-bottom: 20px; border: 1px solid var(--border); border-radius: 4px; overflow: hidden;">
            <div style="background: #f1f5f9; padding: 6px 12px; font-weight: 900; font-size: 11px; text-transform: uppercase; border-bottom: 1px solid var(--border);">Top 5 Itens Mais Vendidos (No Filtro Atual)</div>
            <table style="margin-bottom: 0; border: none;">
                <thead>
                    <tr><th style="text-align: center;">Rank</th><th>Produto</th><th style="text-align: center;">Vendas</th><th style="text-align: right;">Total Receita</th></tr>
                </thead>
                <tbody>${rows}</tbody>
            </table>
        </div>
        `;
    };

    // ==========================================
    // EXCEL DINÂMICO
    // ==========================================
    if (type === 'excel') {
        let rows = [];

        if (currentView.value === 'detailed') {
             rows = dataToExport.map(i => {
                 const obj: any = {
                    'Origem': i.source_label,
                    'Pedido': i.pedido_id,
                    'Data': formatDateSafe(i.data),
                    'Mês': i.mes_ano,
                    'Cliente': i.cliente, 'Vendedor': i.vendedor, 'Tecido': i.tecido,
                    'MT': i.qtd_mt, 'R$/MT': i.preco_unit_mt,
                    'KG': i.qtd_kg, 'R$/KG': i.preco_unit_kg,
                    'UN': i.qtd_un,
                    'Total': i.valor_total_item, 'Status': i.status_financeiro
                 };
                 if (companyStore.isGlobalView) obj['Empresa'] = i.company_name;
                 return obj;
             });
             const totalRow: any = { 'Origem': 'TOTAIS:', 'Pedido': '', 'Data': '', 'Mês': '', 'Cliente': '', 'Vendedor': '', 'Tecido': '', 'MT': totalMt, 'R$/MT': '', 'KG': totalKg, 'R$/KG': '', 'UN': totalUn, 'Total': totalVal, 'Status': '' };
             if (companyStore.isGlobalView) totalRow['Empresa'] = '';
             rows.push({} as any);
             rows.push(totalRow);
        } else if (currentView.value === 'products') {
            rows = dataToExport.map((i, idx) => ({
                'Rank': idx + 1, 'Produto': i.tecido, 'Qtd Pedidos': i.pedidos_count,
                'Total MT': i.qtd_mt, 'Total KG': i.qtd_kg, 'Total UN': i.qtd_un, 'Total Faturado': i.valor_total
            }));
        } else if (currentView.value === 'customers') {
            rows = dataToExport.map((i, idx) => ({
                'Rank': idx + 1, 'Cliente': i.cliente, 'Qtd Pedidos': i.pedidos_count,
                'Total MT': i.qtd_mt, 'Total KG': i.qtd_kg, 'Total UN': i.qtd_un, 'Total Comprado': i.valor_total
            }));
        }

        const ws = XLSX.utils.json_to_sheet(rows);
        const wb = XLSX.utils.book_new();
        XLSX.utils.book_append_sheet(wb, ws, currentView.value);
        XLSX.writeFile(wb, `Relatorio_Vendas_${format(new Date(), 'dd-MM-yyyy')}.xlsx`);
        appStore.showSnackbar('Excel Gerado com Sucesso!', 'success');
        reportLoading.value = false;
        return;
    }

    // ==========================================
    // PDF (JSPDF + AUTOTABLE) - RETRATO (Em pé)
    // ==========================================
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
        doc.text(reportTitle, M + 42, M + 8);

        doc.setFont("helvetica", "normal");
        doc.setFontSize(9);
        doc.text(`Empresa: ${companyNameLabel}`, M + 42, M + 14);
        doc.text(`Período: ${formatDateSafe(filters.startDate)} a ${formatDateSafe(filters.endDate)}`, M + 42, M + 19);
        doc.text(`Status: ${filters.financialStatus}`, M + 42, M + 24);

        doc.text(`Emissão: ${format(new Date(), 'dd/MM/yyyy HH:mm')}`, pageW - M - 3, M + 8, { align: 'right' });
        doc.text(`Por: ${userStore.user?.email || 'Sistema'}`, pageW - M - 3, M + 14, { align: 'right' });

        // AVISO EM DESTAQUE
        doc.setFontSize(7);
        doc.setTextColor(220, 38, 38);
        doc.text("* AVISO: Os valores consideram o total do pedido. Alguns podem não estar faturados, não refletindo o valor financeiro final.", M, M + headerH + 4);

        // CAIXAS DOS KPIs
        const kpiY = M + headerH + 6;
        const kpiH = 14;
        const gap = 3;

        let colsKpi = 4;
        if (hasUnits.value) colsKpi = 5;
        const kpiW = (boxW - (gap * (colsKpi - 1))) / colsKpi;

        const drawKpi = (label: string, value: string, i: number) => {
            const x = M + i * (kpiW + gap);
            doc.setFillColor(245, 245, 245);
            doc.rect(x, kpiY, kpiW, kpiH, 'FD');
            doc.setFont("helvetica", "bold");
            doc.setFontSize(7);
            doc.setTextColor(80, 80, 80);
            doc.text(label, x + 3, kpiY + 5);
            doc.setFontSize(9);
            doc.setTextColor(0);
            doc.text(value, x + 3, kpiY + 11);
        };

        drawKpi("TOTAL RECEITA", formatCurrency(totalVal), 0);
        drawKpi("VOL (MT)", formatNumber(totalMt), 1);
        drawKpi("VOL (KG)", formatNumber(totalKg), 2);

        let curIdx = 3;
        if (hasUnits.value) { drawKpi("VOL (UN)", formatNumber(totalUn), curIdx); curIdx++; }
        drawKpi("TOTAL PEDIDOS", String(totalPedidos), curIdx);

        let finalY = kpiY + kpiH + 6;

        // INCLUIR TOP 5 NO PDF
        if (currentView.value === 'detailed' && topProducts.value.length > 0) {
            const top5 = topProducts.value.slice(0, 5);
            doc.setFont("helvetica", "bold");
            doc.setFontSize(9);
            doc.setTextColor(0);
            doc.text("TOP 5 PRODUTOS NESTE FILTRO", M, finalY + 4);

            autoTable(doc, {
                startY: finalY + 6,
                head: [['RANK', 'PRODUTO', 'PEDIDOS', 'TOTAL']],
                body: top5.map((p, idx) => [`${idx + 1}º`, p.tecido.substring(0,40), p.pedidos_count, formatCurrency(p.valor_total)]),
                theme: 'grid',
                styles: { fontSize: 7, cellPadding: 1.5, lineColor: [50, 50, 50], lineWidth: 0.2 },
                headStyles: { fillColor: [241, 245, 249], textColor: 0, fontStyle: 'bold' },
                columnStyles: { 0: { halign: 'center', cellWidth: 15 }, 2: { halign: 'center', cellWidth: 20 }, 3: { halign: 'right', fontStyle: 'bold', cellWidth: 30, textColor: [22, 101, 52] } }
            });
            finalY = (doc as any).lastAutoTable.finalY + 6;
        }

        let pdfBody = [];
        if (currentView.value === 'detailed') {
            pdfBody = dataToExport.map(i => {
                const obj: any = {
                    origem: i.source_label,
                    pedido: `#${String(i.pedido_id).padStart(4, '0')}`,
                    data: formatDateSafe(i.data),
                    cliente: i.cliente.substring(0, 15),
                    vendedor: i.vendedor.split(' ')[0].substring(0, 10),
                    tecido: i.tecido.substring(0, 15),
                    mt: formatNumber(i.qtd_mt),
                    kg: formatNumber(i.qtd_kg),
                    total: formatCurrency(i.valor_total_item),
                    status: i.status_financeiro
                };
                if (hasUnits.value) obj['un'] = formatNumber(i.qtd_un);
                if (companyStore.isGlobalView) obj['empresa'] = i.company_name.substring(0, 10);
                return obj;
            });
        } else {
            pdfBody = dataToExport.map((i, idx) => {
                let rowColor = [255, 255, 255];
                if (idx === 0) rowColor = [254, 243, 199];
                else if (idx === 1) rowColor = [241, 245, 249];
                else if (idx === 2) rowColor = [255, 237, 213];

                const obj: any = {
                    rank: `${idx + 1}º`,
                    produto: i.tecido,
                    cliente: i.cliente,
                    pedidos: i.pedidos_count,
                    mt: formatNumber(i.qtd_mt),
                    kg: formatNumber(i.qtd_kg),
                    total: formatCurrency(i.valor_total),
                    _rowColor: rowColor
                };
                if (hasUnits.value) obj['un'] = formatNumber(i.qtd_un);
                return obj;
            });
        }

        const colStyles: any = {};
        if (currentView.value === 'detailed') {
            colStyles.origem = { halign: 'center' };
            colStyles.mt = { halign: 'right' };
            colStyles.kg = { halign: 'right' };
            if (hasUnits.value) colStyles.un = { halign: 'right' };
            colStyles.total = { halign: 'right', fontStyle: 'bold' };
            colStyles.status = { halign: 'center' };
        } else {
            colStyles.rank = { halign: 'center' };
            colStyles.pedidos = { halign: 'center' };
            colStyles.mt = { halign: 'right' };
            colStyles.kg = { halign: 'right' };
            if (hasUnits.value) colStyles.un = { halign: 'right' };
            colStyles.total = { halign: 'right', fontStyle: 'bold' };
        }

        autoTable(doc, {
            startY: finalY, columns: pdfColumns, body: pdfBody, theme: 'grid',
            tableWidth: boxW, margin: { left: M, right: M },
            styles: { fontSize: 6.5, cellPadding: 1.5, lineColor: [50, 50, 50], lineWidth: 0.2, textColor: 0 },
            headStyles: { fillColor: [230, 230, 230], textColor: 0, fontStyle: 'bold' },
            columnStyles: colStyles,
            didParseCell: (data) => {
                if (data.section === 'body' && (data.row.raw as any)._rowColor) {
                    data.cell.styles.fillColor = (data.row.raw as any)._rowColor;
                }
            }
        });

        const totalPages = doc.internal.getNumberOfPages();
        for (let i = 1; i <= totalPages; i++) {
            doc.setPage(i);
            doc.setFontSize(7).setTextColor(150);
            doc.text(`Gerado com MJProcess`, pageW - M, pageH - 5, { align: "right" });
        }

        doc.save(`Vendas_${currentView.value}_${format(new Date(), 'yyyyMMdd_HHmm')}.pdf`);
        appStore.showSnackbar('PDF Gerado com Sucesso!', 'success');

    // ==========================================
    // IMPRESSÃO HTML (EM PÉ COM AVISO E CORES)
    // ==========================================
    } else if (type === 'print') {
        const printWindow = window.open('', '_blank');
        if (!printWindow) {
            appStore.showSnackbar('Permita a abertura de pop-ups.', 'warning');
            reportLoading.value = false; return;
        }

        let htmlRows = '';
        if (currentView.value === 'detailed') {
             htmlRows = dataToExport.map(i => `
                <tr class="row-open">
                    <td class="text-center font-bold text-[10px]">${i.source_label}</td>
                    ${companyStore.isGlobalView ? `<td class="text-[10px]">${i.company_name}</td>` : ''}
                    <td class="text-center font-bold">#${String(i.pedido_id).padStart(4, '0')}</td>
                    <td class="text-center">${formatDateSafe(i.data)}</td>
                    <td>${i.cliente}</td>
                    <td>${i.vendedor.split(' ')[0]}</td>
                    <td>${i.tecido}</td>
                    <td class="text-right">${formatNumber(i.qtd_mt)}</td>
                    <td class="text-right">${formatNumber(i.qtd_kg)}</td>
                    ${hasUnits.value ? `<td class="text-right">${formatNumber(i.qtd_un)}</td>` : ''}
                    <td class="text-right font-bold text-success">${formatCurrency(i.valor_total_item)}</td>
                    <td class="text-center font-bold">${i.status_financeiro}</td>
                </tr>
            `).join('');
        } else if (currentView.value === 'products') {
             htmlRows = dataToExport.map((i, idx) => {
                let rowClass = 'row-open';
                if (idx === 0) rowClass += ' row-rank-1';
                else if (idx === 1) rowClass += ' row-rank-2';
                else if (idx === 2) rowClass += ' row-rank-3';

                return `
                <tr class="${rowClass}">
                    <td class="text-center font-bold">${idx + 1}º</td>
                    <td class="font-bold">${i.tecido}</td>
                    <td class="text-center">${i.pedidos_count}</td>
                    <td class="text-right">${formatNumber(i.qtd_mt)}</td>
                    <td class="text-right">${formatNumber(i.qtd_kg)}</td>
                    ${hasUnits.value ? `<td class="text-right">${formatNumber(i.qtd_un)}</td>` : ''}
                    <td class="text-right font-bold text-success">${formatCurrency(i.valor_total)}</td>
                </tr>
                `
             }).join('');
        } else if (currentView.value === 'customers') {
             htmlRows = dataToExport.map((i, idx) => {
                let rowClass = 'row-open';
                if (idx === 0) rowClass += ' row-rank-1';
                else if (idx === 1) rowClass += ' row-rank-2';
                else if (idx === 2) rowClass += ' row-rank-3';

                return `
                <tr class="${rowClass}">
                    <td class="text-center font-bold">${idx + 1}º</td>
                    <td class="font-bold">${i.cliente}</td>
                    <td class="text-center">${i.pedidos_count}</td>
                    <td class="text-right">${formatNumber(i.qtd_mt)}</td>
                    <td class="text-right">${formatNumber(i.qtd_kg)}</td>
                    ${hasUnits.value ? `<td class="text-right">${formatNumber(i.qtd_un)}</td>` : ''}
                    <td class="text-right font-bold text-success">${formatCurrency(i.valor_total)}</td>
                </tr>
                `
             }).join('');
        }

        const html = `
            <!DOCTYPE html>
            <html lang="pt-BR">
            <head>
                <meta charset="UTF-8">
                <title>Romaneio de Vendas</title>
                <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
                <style>
                    :root { --border: #333; --text-main: #000; --bg-head: #e5e7eb; }
                    body { font-family: 'Inter', sans-serif; color: var(--text-main); margin: 0; padding: 20px; font-size: 10px; background: #fff; }
                    .print-toolbar { display: flex; justify-content: space-between; align-items: center; background: #f8fafc; padding: 12px 20px; border-radius: 8px; border: 1px solid var(--border); margin-bottom: 20px; }
                    .btn-print { background: #0f172a; color: #fff; border: none; padding: 8px 20px; border-radius: 6px; font-weight: 600; cursor: pointer; transition: 0.2s; }
                    .warning-box { background: #fef2f2; color: #991b1b; padding: 8px 12px; border: 1px solid #f87171; border-radius: 4px; font-size: 9px; margin-bottom: 15px; font-weight: 600; text-align: center; }
                    .header-box { display: flex; justify-content: space-between; align-items: center; border: 1.5px solid var(--border); padding: 15px; margin-bottom: 15px; }
                    .logo { max-width: 140px; max-height: 45px; object-fit: contain; }
                    .header-info { text-align: right; }
                    .header-info h1 { margin: 0 0 5px 0; font-size: 16px; font-weight: 900; text-transform: uppercase; }
                    .header-info p { margin: 2px 0; font-size: 10px; font-weight: 500; }
                    .kpi-container { display: flex; gap: 10px; margin-bottom: 20px; }
                    .kpi-card { flex: 1; border: 1px solid var(--border); padding: 8px 12px; background: #fafafa; }
                    .kpi-title { font-size: 8px; font-weight: 800; text-transform: uppercase; margin-bottom: 4px; color: #444; }
                    .kpi-val { font-size: 12px; font-weight: 900; color: #000; }
                    table { width: 100%; border-collapse: collapse; margin-bottom: 30px; border: 1px solid var(--border); }
                    th, td { padding: 4px 6px; text-align: left; border: 1px solid var(--border) !important; font-size: 9px; }
                    th { background-color: var(--bg-head) !important; color: #000; font-weight: 800; text-transform: uppercase; }
                    .text-center { text-align: center; }
                    .text-right { text-align: right; }
                    .font-bold { font-weight: 700; }
                    .text-[10px] { font-size: 10px; }
                    .text-success { color: #166534; }
                    .row-open { background-color: #ffffff !important; }
                    .row-rank-1 td { background-color: #fef3c7 !important; }
                    .row-rank-2 td { background-color: #f1f5f9 !important; }
                    .row-rank-3 td { background-color: #ffedd5 !important; }
                    @media print {
                        body { padding: 0; }
                        .print-toolbar { display: none !important; }
                        * { -webkit-print-color-adjust: exact !important; color-adjust: exact !important; print-color-adjust: exact !important; }
                        @page { margin: 8mm; size: A4 portrait; }
                    }
                </style>
            </head>
            <body>
                <div class="print-toolbar">
                    <span style="color: #64748b; font-weight: 500;">Dica: Salve em PDF ou imprima direto na impressora. As linhas já estão configuradas.</span>
                    <button class="btn-print" onclick="window.print()">🖨️ Imprimir</button>
                </div>
                <div class="warning-box">
                    <strong>⚠️ AVISO IMPORTANTE:</strong> Os valores abaixo consideram o total do pedido, podendo não refletir o saldo financeiro real caso existam pendências.
                </div>
                <div class="header-box">
                    <img src="${logoUrl}" alt="Logo" class="logo">
                    <div class="header-info">
                        <h1>${reportTitle}</h1>
                        <p>Tenant: ${companyNameLabel}</p>
                        <p>Período: ${formatDateSafe(filters.startDate)} a ${formatDateSafe(filters.endDate)}</p>
                        <p>Status Financeiro: ${filters.financialStatus}</p>
                    </div>
                </div>
                <div class="kpi-container">
                    <div class="kpi-card"><div class="kpi-title">Receita Total</div><div class="kpi-val">${formatCurrency(totalVal)}</div></div>
                    <div class="kpi-card"><div class="kpi-title">Volume (MT)</div><div class="kpi-val">${formatNumber(totalMt)}</div></div>
                    <div class="kpi-card"><div class="kpi-title">Volume (KG)</div><div class="kpi-val">${formatNumber(totalKg)}</div></div>
                    ${hasUnits.value ? `<div class="kpi-card"><div class="kpi-title">Volume (UN)</div><div class="kpi-val">${formatNumber(totalUn)}</div></div>` : ''}
                    <div class="kpi-card"><div class="kpi-title">Total Pedidos</div><div class="kpi-val">${totalPedidos}</div></div>
                </div>
                ${generateTop5Html()}
                <table>
                    <thead><tr>${htmlHeaders}</tr></thead>
                    <tbody>${htmlRows}</tbody>
                </table>
                <script> window.onload = () => { setTimeout(() => { window.print(); }, 500); }; <\/script>
            </body>
            </html>
        `;

        printWindow.document.open();
        printWindow.document.write(html);
        printWindow.document.close();
    }

    reportLoading.value = false;
};

onMounted(() => { fetchData(); });
</script>

<style scoped lang="scss">
/* Layout Geral e Wrapper */
.sales-layout { position: relative; }
.bg-glass-dark { background: rgba(10,10,12,0.85); }
.bg-glass-header { background: rgba(20,20,24,0.55); backdrop-filter: blur(14px); }
.border-bottom-white-05 { border-bottom: 1px solid rgba(255,255,255,0.08); }
.background-carousel-wrapper { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 0; opacity: 0.6; pointer-events: none; }
.background-overlay { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 1; background: radial-gradient(circle at center, rgba(15, 15, 19, 0.4), rgba(15, 15, 19, 0.98)); backdrop-filter: blur(8px); }
.z-10 { position: relative; z-index: 10; }
.w-8 { width: 32px; }
.lh-1 { line-height: 1; }

/* Controles e Inputs */
.btn-rect { border-radius: 4px !important; text-transform: none !important; font-weight: 800; }
.controls-bar { border: 1px solid rgba(0,0,0,0.08); padding: 10px; }
.controls-light { background: #ffffff; }
.controls-dark { background: rgba(30,30,35,0.55); backdrop-filter: blur(16px); border: 1px solid rgba(255,255,255,0.08); }
.search-wrap { height: 40px; padding: 0 12px; border: 1px solid rgba(0,0,0,0.08); display: flex; align-items: center; min-width: 300px; flex: 1; }
.search-light { background: #f4f6f8; }
.search-dark { background: rgba(255,255,255,0.08); border-color: rgba(255,255,255,0.1); }
.clean-input { border: none; outline: none; flex: 1; font-size: 12px; background: transparent; color: inherit; }
.period-nav { height: 40px; border: 1px solid rgba(0,0,0,0.08); }
.period-nav-light { background: #f4f6f8; }
.period-nav-dark { background: rgba(255,255,255,0.08); border-color: rgba(255,255,255,0.1); }

/* GRID CSS NATIVO (A Identidade Visual Restaurada) */
.glass-card { background: rgba(30, 30, 35, 0.45); backdrop-filter: blur(25px); border: 1px solid rgba(255,255,255,0.08); }
.grid-scroll { scrollbar-gutter: stable; -webkit-overflow-scrolling: touch; }
.custom-scroll::-webkit-scrollbar { width: 8px; height: 8px; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.35); border-radius: 6px; }
.custom-scroll::-webkit-scrollbar-track { background: transparent; }

.grid-header, .grid-row {
    display: grid;
    align-items: stretch;
    width: 100%;
}

.grid-ranking {
    grid-template-columns: 70px minmax(250px, 2fr) 100px 140px 140px 160px;
    min-width: 800px;
}

.cell {
    padding: 6px 8px;
    display: flex;
    align-items: center;
    border-right: 1px solid rgba(0,0,0,0.08);
    border-bottom: 1px solid rgba(0,0,0,0.08);
    min-height: 54px;
    overflow: hidden;
    transition: background-color 0.2s ease;
}

.center { justify-content: center; text-align: center; }
.right { justify-content: flex-end; text-align: right; }

.grid-header .cell {
    min-height: 44px;
    font-size: 14px !important;
    font-weight: 800;
    text-transform: uppercase;
    letter-spacing: 0.5px;
    line-height: 1.2;
}

.list-text-11 { font-size: 14px !important; line-height: 1.2 !important; }

/* Grid Themes & Zebra */
.grid-surface-light .cell { background: #f5f7fa; color: rgba(0,0,0,0.9); border-color: rgba(0,0,0,0.12) !important; }
.grid-surface-dark .cell { background: rgba(255,255,255,0.08); color: rgba(255,255,255,0.95); border-color: rgba(255,255,255,0.1) !important; }

.grid-row-light .cell { border-color: rgba(0,0,0,0.08) !important; }
.grid-row-dark .cell { border-color: rgba(255,255,255,0.08) !important; }

.zebra-light-a .cell { background: #ffffff; }
.zebra-light-b .cell { background: #fcfcfc; }
.zebra-dark-a .cell { background: rgba(0,0,0,0.15); }
.zebra-dark-b .cell { background: rgba(255,255,255,0.02); }

.grid-row-light:hover .cell { background: #e3f2fd !important; }
.grid-row-dark:hover .cell { background: rgba(255,255,255,0.12) !important; }

/* Cores do Ranking na UI */
.grid-row-light.row-rank-1 .cell { background: #fffbeb !important; border-bottom-color: #fde68a !important; }
.grid-row-light.row-rank-2 .cell { background: #f8fafc !important; border-bottom-color: #e2e8f0 !important; }
.grid-row-light.row-rank-3 .cell { background: #fff7ed !important; border-bottom-color: #ffedd5 !important; }

.grid-row-dark.row-rank-1 .cell { background: rgba(245, 158, 11, 0.15) !important; border-bottom-color: rgba(245, 158, 11, 0.3) !important; }
.grid-row-dark.row-rank-2 .cell { background: rgba(148, 163, 184, 0.15) !important; border-bottom-color: rgba(148, 163, 184, 0.3) !important; }
.grid-row-dark.row-rank-3 .cell { background: rgba(217, 119, 6, 0.15) !important; border-bottom-color: rgba(217, 119, 6, 0.3) !important; }

.sticky-head { position: sticky; top: 0; z-index: 20; box-shadow: 0 8px 16px -4px rgba(0, 0, 0, 0.12); }
.bg-glass-dark .sticky-head { box-shadow: 0 8px 20px -4px rgba(0, 0, 0, 0.4); }

/* KPIs */
.kpi-card { color: white; position: relative; min-height: 110px; overflow: hidden; border-radius: 0; }
.kpi-bg-icon { position: absolute; right: -20px; bottom: -20px; opacity: 0.15; transform: rotate(-15deg); }
.kpi-bg-icon .v-icon { font-size: 100px; color: white; }

.kpi-bg-icon-mobile { position: absolute; right: -5px; bottom: -5px; opacity: 0.15; transform: rotate(-10deg); }
.kpi-bg-icon-mobile .v-icon { font-size: 60px; color: white; }
.text-shadow-sm { text-shadow: 0 2px 4px rgba(0,0,0,0.2); }

.bg-gradient-info { background: linear-gradient(135deg, #0288d1, #005b9f); }
.bg-gradient-green { background: linear-gradient(135deg, #2e7d32, #1b5e20); }
.bg-gradient-warning { background: linear-gradient(135deg, #FFB300, #F57F17); }
.bg-gradient-purple { background: linear-gradient(135deg, #7b1fa2, #4a148c); }
.bg-gradient-danger { background: linear-gradient(135deg, #c62828, #b71c1c); color: white; }

.kpi-label { font-size: 12px; font-weight: 900; letter-spacing: .2px; }
.kpi-value { font-size: 22px; font-weight: 900; }
.kpi-footer { font-size: 11px; opacity: .9; font-weight: 700; }

/* Elementos Menores */
.pill-ref { font-size: 12px !important; font-weight: 900; font-family: monospace; padding: 4px 6px; border-radius: 0px; white-space: nowrap; }
.solid-chip { display: inline-flex; align-items: center; justify-content: center; height: 28px; padding: 0 12px; border-radius: 0px; font-size: 11px !important; font-weight: 900; color: #fff; text-transform: uppercase; white-space: nowrap; }
.chip-success { background: #2e7d32; }
.chip-warn { background: #f57f17; }
.chip-danger { background: #c62828; }
.chip-info { background: #1976d2; }

.ui-field :deep(.v-field) { border-radius: 0 !important; }
.row-gap { row-gap: 14px; }
.bg-white-20 { background: rgba(255,255,255,0.2); }
.bg-white-05 { background: rgba(255,255,255,0.05); }

/* BOTÕES 3D QUE VOCÊ PEDIU */
.btn-3d { border-radius: 6px !important; box-shadow: 0 3px 5px rgba(0,0,0,0.15), inset 0 2px 0 rgba(255,255,255,0.25) !important; transition: transform 0.1s ease, box-shadow 0.1s ease; text-transform: none !important; }
.btn-3d:active { transform: translateY(2px); box-shadow: 0 1px 2px rgba(0,0,0,0.15), inset 0 1px 0 rgba(255,255,255,0.2) !important; }
.hover-elevate:hover { transform: translateY(-2px); box-shadow: 0 4px 10px rgba(0,0,0,0.2); z-index: 5; position: relative;}

@media (max-width: 600px) {
  .search-wrap { min-width: 100%; }
}
</style>
