<template>
  <div
    class="receivables-layout font-sans fill-height d-flex flex-column relative overflow-hidden"
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
        v-if="!isMobileFullscreen"
        class="header-bar px-4 py-3 px-md-6 py-md-4 d-flex flex-column flex-md-row align-md-start justify-space-between flex-shrink-0"
        :class="themeStore.currentMode === 'light' ? 'bg-white border-b border-grey-lighten-2 shadow-sm' : 'bg-glass-header border-bottom-white-05'"
        style="gap: 12px;"
      >
        <div class="d-flex flex-column" style="max-width: calc(100vw - 32px);">
          <div class="breadcrumb text-caption d-none d-md-block">
            <span class="opacity-70">Financeiro</span>
            <span class="mx-2 opacity-50">></span>
            <span class="font-weight-bold">Contas a Receber</span>
          </div>
          <div class="d-flex align-center gap-2 mt-1">
             <div class="text-h6 font-weight-black tracking-tight leading-none" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">
                Contas a Receber
             </div>
          </div>

          <div class="d-flex align-center gap-3 mt-3 overflow-x-auto hide-scrollbar pb-1 w-100">
             <v-btn
                v-for="btn in contextButtons"
                :key="btn.id"
                size="x-small"
                height="24"
                :variant="companyStore.context === btn.id ? 'flat' : 'tonal'"
                :color="companyStore.context === btn.id ? (btn.isHolding ? 'purple' : 'success') : 'grey'"
                class="font-weight-bold btn-3d px-3 rounded-pill flex-shrink-0"
                style="font-size: 10px; letter-spacing: 0.5px;"
                @click="setCompanyFilter(btn.id)"
             >
                {{ btn.name }}
             </v-btn>
          </div>
        </div>

        <div class="d-none d-md-flex align-center overflow-x-auto pb-1 pb-md-0 mt-3 mt-md-0" style="gap: 10px;">
          <v-menu location="bottom end">
            <template v-slot:activator="{ props }">
              <v-btn
                v-bind="props"
                color="blue-darken-3"
                variant="flat"
                class="btn-3d px-3 px-md-4 font-weight-bold text-caption text-uppercase letter-spacing-1 flex-shrink-0"
                prepend-icon="mdi-file-chart"
                height="40"
                :loading="reportLoading"
              >
                Relatórios
                <v-icon end size="small">mdi-chevron-down</v-icon>
              </v-btn>
            </template>
            <v-list density="compact" nav :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-grey-darken-4 text-white'">
              <v-list-item @click="generateReport('pdf')" prepend-icon="mdi-file-pdf-box" title="Exportar PDF (Geral)" :class="themeStore.currentMode === 'light' ? 'text-red-darken-3' : 'text-red-lighten-1'" class="font-weight-bold"></v-list-item>
              <v-list-item @click="generateReport('pdf_monthly')" prepend-icon="mdi-calendar-multiselect" title="Exportar PDF (Separado por Mês)" :class="themeStore.currentMode === 'light' ? 'text-red-darken-4' : 'text-red-lighten-2'" class="font-weight-black"></v-list-item>
              <v-list-item @click="generateReport('excel')" prepend-icon="mdi-microsoft-excel" title="Exportar Excel (Dados)" :class="themeStore.currentMode === 'light' ? 'text-green-darken-3' : 'text-green-lighten-1'" class="font-weight-bold"></v-list-item>
            </v-list>
          </v-menu>

          <v-btn
            color="teal-darken-3"
            variant="flat"
            class="btn-3d px-3 px-md-4 font-weight-bold text-caption text-uppercase letter-spacing-1 flex-shrink-0"
            prepend-icon="mdi-calendar-sync"
            height="40"
            @click="openFixedAccountModal"
          >
            Lançar Fixo
          </v-btn>

          <v-btn
            color="success"
            variant="flat"
            class="btn-3d px-3 px-md-4 font-weight-bold text-caption text-uppercase letter-spacing-1 flex-shrink-0 shadow-button"
            prepend-icon="mdi-plus"
            height="40"
            @click="openNewReceivableModal"
          >
             Novo Recebimento
          </v-btn>
        </div>
      </div>

      <div v-if="!isMobileFullscreen" class="px-4 px-md-6 py-2 flex-shrink-0">
        <v-row class="d-none d-md-flex">
          <v-col cols="12" sm="6" md="" v-for="(kpi, idx) in kpiList" :key="idx">
            <v-card
              class="kpi-card kpi-rect bg-gradient-custom hover-elevate py-3 px-4 cursor-pointer"
              :class="[kpi.gradient, kpi.active ? 'kpi-active-border' : '']"
              v-ripple
              elevation="2"
              @click="handleKpiClick(kpi.label)"
            >
              <div class="kpi-bg-icon"><v-icon>{{ kpi.icon }}</v-icon></div>
              <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                <div class="d-flex align-center" style="gap: 8px;">
                  <v-icon size="18" class="opacity-80">{{ kpi.icon }}</v-icon>
                  <span class="kpi-label">{{ kpi.label }}</span>
                </div>
                <div class="kpi-number-group my-1">
                  <span class="text-body-2 font-weight-medium mr-1 opacity-70">R$</span>
                  <span class="kpi-value">{{ formatCurrencyValue(kpi.value) }}</span>
                </div>
                <div class="kpi-footer mt-1">{{ kpi.footer }}</div>
              </div>
            </v-card>
          </v-col>
        </v-row>

        <div class="d-block d-md-none kpi-mobile-wrapper my-2">
          <v-window v-model="kpiModel" show-arrows class="elevation-4 rounded-xl overflow-hidden shadow-lg">
             <template v-slot:prev="{ props }">
               <v-btn variant="flat" icon="mdi-chevron-left" @click="props.onClick" color="rgba(0,0,0,0.3)" size="small" class="text-white backdrop-blur-sm"></v-btn>
             </template>
             <template v-slot:next="{ props }">
               <v-btn variant="flat" icon="mdi-chevron-right" @click="props.onClick" color="rgba(0,0,0,0.3)" size="small" class="text-white backdrop-blur-sm"></v-btn>
             </template>

             <v-window-item v-for="(kpi, idx) in kpiList" :key="idx">
                <v-card
                    class="kpi-card-mobile d-flex flex-column align-center justify-center py-6 px-4 text-center relative"
                    :class="[kpi.gradient]"
                    @click="handleKpiClick(kpi.label)"
                    height="140"
                    elevation="0"
                    v-ripple
                >
                    <div class="kpi-bg-icon-mobile"><v-icon>{{ kpi.icon }}</v-icon></div>
                    <div class="d-flex flex-column align-center relative z-10 w-100">
                        <div class="d-flex align-center justify-center mb-1 bg-white-20 px-3 py-1 rounded-pill backdrop-blur-sm" style="max-width: 80%;">
                            <v-icon size="16" class="mr-2 text-white">{{ kpi.icon }}</v-icon>
                            <span class="text-caption font-weight-black text-uppercase text-white tracking-wide text-truncate">{{ kpi.label }}</span>
                        </div>
                        <div class="text-h3 font-weight-black text-white my-2 text-shadow-sm">
                           <span class="text-body-2 opacity-80 align-top mr-1">R$</span>{{ formatCurrencyValue(kpi.value) }}
                        </div>
                        <div class="text-caption text-white font-weight-medium opacity-90">{{ kpi.footer }}</div>
                    </div>
                </v-card>
             </v-window-item>
          </v-window>
          <div class="d-flex justify-center mt-3 gap-2">
              <div
                v-for="(k, i) in kpiList"
                :key="i"
                class="kpi-dot transition-all rounded-circle cursor-pointer"
                :class="kpiModel === i ? 'bg-success w-3 h-3 elevation-2' : 'bg-grey-lighten-2 w-2 h-2 opacity-50'"
                @click="kpiModel = i"
              ></div>
          </div>
        </div>
      </div>

      <div v-if="!isMobileFullscreen" class="px-4 px-md-6 pt-0 pb-2 flex-shrink-0">

        <div v-if="mobile" class="d-flex align-center gap-2">
            <v-menu location="bottom start" :close-on-content-click="false">
                <template v-slot:activator="{ props }">
                    <v-btn
                        v-bind="props"
                        color="blue-darken-3"
                        variant="flat"
                        class="btn-3d flex-shrink-0 px-4"
                        height="44"
                        prepend-icon="mdi-menu"
                    >
                        Ações
                    </v-btn>
                </template>
                <v-list density="compact" nav class="py-2" width="260" :class="isDark ? 'bg-grey-darken-4 text-white' : 'bg-white'">
                    <v-list-item @click="mobileFiltersOpen = true" prepend-icon="mdi-filter-variant" title="Filtros Avançados" class="text-primary font-weight-bold mb-2 rounded" :class="isDark ? 'bg-grey-darken-3' : 'bg-blue-lighten-5'"></v-list-item>

                    <v-list-item @click="toggleConciliatedFilter" :prepend-icon="filters.onlyConciliated ? 'mdi-shield-check' : 'mdi-shield-outline'" title="Apenas Conciliados" :class="filters.onlyConciliated ? 'text-teal-darken-3 font-weight-bold bg-teal-lighten-5 rounded mb-2' : 'mb-2'"></v-list-item>

                    <v-divider class="my-2"></v-divider>
                    <div class="text-caption font-weight-bold ml-4 mb-1 text-grey">Período Rápido</div>
                    <v-list-item @click="applyPreset('today')" title="Hoje" density="compact"></v-list-item>
                    <v-list-item @click="applyPreset('week')" title="Esta Semana" density="compact"></v-list-item>
                    <v-list-item @click="applyPreset('month')" title="Este Mês" density="compact"></v-list-item>
                    <v-list-item @click="applyPreset('year')" title="Este Ano" density="compact"></v-list-item>

                    <v-divider class="my-2"></v-divider>
                    <div class="text-caption font-weight-bold ml-4 mb-1 text-grey">Operações</div>
                    <v-list-item @click="openNewReceivableModal" prepend-icon="mdi-plus" title="Novo Recebimento" class="text-success font-weight-bold"></v-list-item>
                    <v-list-item @click="openFixedAccountModal" prepend-icon="mdi-calendar-sync" title="Lançar Fixo"></v-list-item>
                    <v-list-item @click="generateReport('pdf')" prepend-icon="mdi-file-pdf-box" title="PDF Geral"></v-list-item>
                    <v-list-item @click="generateReport('pdf_monthly')" prepend-icon="mdi-calendar-multiselect" title="PDF por Mês"></v-list-item>
                    <v-list-item @click="syncModalOpen = true" prepend-icon="mdi-cloud-sync" title="Sincronizar ERP"></v-list-item>
                    <v-list-item @click="showImportModal = true" prepend-icon="mdi-upload" title="Importar"></v-list-item>
                    <v-divider class="my-2"></v-divider>
                    <v-list-item @click="gridSettings.showModal = true" prepend-icon="mdi-table-cog" title="Configurar Grid"></v-list-item>
                </v-list>
            </v-menu>

            <div class="flex-grow-1 relative search-wrap rounded border d-flex align-center" :class="isDark ? 'bg-glass-dark border-white-10' : 'bg-white'" style="height: 44px;">
                <input
                  v-model="filters.search"
                  type="text"
                  placeholder="Pesquisar..."
                  class="clean-input w-100 h-100 px-3 font-weight-bold"
                  style="outline: none;"
                  :class="isDark ? 'text-white' : 'text-grey-darken-4'"
                  @keyup.enter="handleSearchEnter"
                />
                <v-btn icon variant="text" density="compact" class="mr-1 text-grey-darken-1" @click="handleSearchEnter">
                    <v-icon>mdi-magnify</v-icon>
                </v-btn>
            </div>
        </div>

        <div
          v-else
          class="controls-bar d-flex flex-column"
          :class="isDark ? 'controls-dark' : 'controls-light'"
          style="gap: 10px;"
        >
          <div class="d-flex flex-column flex-md-row align-start align-md-center justify-space-between" style="gap: 10px;">
            <div class="d-flex align-center flex-wrap w-100 w-md-auto" style="gap: 10px;">
              <v-menu location="bottom start" :close-on-content-click="true">
                <template v-slot:activator="{ props }">
                  <v-btn v-bind="props" variant="outlined" class="btn-3d flex-grow-1 flex-md-grow-0" height="40" prepend-icon="mdi-calendar-range" color="success">
                    {{ quickPeriodLabel }}
                    <v-icon end size="small">mdi-chevron-down</v-icon>
                  </v-btn>
                </template>
                <v-card class="rounded-0" min-width="220" :class="isDark ? 'bg-grey-darken-4' : 'bg-white'">
                  <v-list density="compact" nav :class="isDark ? 'bg-grey-darken-4 text-white' : 'bg-white'">
                    <v-list-item v-for="p in quickPeriodOptions" :key="p.value" @click="applyPreset(p.value)">
                      <v-list-item-title class="text-body-2 font-weight-bold">{{ p.label }}</v-list-item-title>
                    </v-list-item>
                  </v-list>
                </v-card>
              </v-menu>

              <div class="period-nav d-flex align-center justify-center flex-grow-1 flex-md-grow-0" :class="isDark ? 'period-nav-dark text-white' : 'period-nav-light'">
                 <div class="period-label text-caption font-weight-black text-center px-4 d-flex align-center" style="height: 40px;">
                    <v-icon start size="small" class="mr-2 opacity-50">mdi-calendar</v-icon>
                    {{ formatDateSafe(filters.customStart) }} até {{ formatDateSafe(filters.customEnd) }}
                 </div>
              </div>
            </div>

            <div class="d-flex align-center flex-wrap justify-end w-100 w-md-auto" style="gap: 10px;">

              <v-btn
                variant="outlined"
                class="btn-3d"
                height="40"
                :color="filters.onlyConciliated ? 'teal-darken-3' : (isDark ? 'white' : 'grey-darken-2')"
                :class="filters.onlyConciliated ? 'bg-teal-lighten-5 border-teal' : ''"
                @click="toggleConciliatedFilter"
              >
                <v-icon start size="small">{{ filters.onlyConciliated ? 'mdi-shield-check' : 'mdi-shield-outline' }}</v-icon>
                <span class="d-none d-sm-inline">Conciliados</span>
              </v-btn>

              <div class="search-wrap d-flex align-center flex-grow-1 flex-md-grow-0" :class="isDark ? 'search-dark' : 'search-light'">
                <v-icon :color="isDark ? 'white-70' : 'grey-darken-1'">mdi-magnify</v-icon>
                <input
                  v-model="filters.search"
                  type="text"
                  placeholder="Pesquisar..."
                  class="clean-input flex-grow-1"
                  :class="isDark ? 'text-white' : ''"
                  @keyup.enter="handleSearchEnter"
                />
              </div>

              <v-menu
                v-model="filtersDropdownOpen"
                location="bottom end"
                :close-on-content-click="false"
                :z-index="2500"
              >
                <template v-slot:activator="{ props }">
                  <v-btn
                    v-bind="props"
                    variant="outlined"
                    class="btn-3d"
                    height="40"
                    prepend-icon="mdi-filter-variant"
                    :color="activeFilterCount > 0 ? 'success' : (isDark ? 'white' : 'grey-darken-2')"
                  >
                    Filtros
                    <v-badge v-if="activeFilterCount > 0" :content="activeFilterCount" color="success" floating class="ml-2"></v-badge>
                    <v-icon end size="small">mdi-chevron-down</v-icon>
                  </v-btn>
                </template>

                <v-card class="rounded-0 pa-4 overflow-y-auto" width="600" :class="isDark ? 'bg-grey-darken-4 text-white' : 'bg-white'">
                  <div class="d-flex justify-space-between align-center mb-4 border-b pb-2">
                      <span class="text-caption font-weight-black opacity-70 text-uppercase">Configurar Filtros</span>
                      <v-btn size="x-small" variant="text" color="error" @click="clearFilters">Limpar Tudo</v-btn>
                  </div>
                  <v-row dense class="row-gap">
                    <v-col cols="12">
                        <div class="text-caption font-weight-bold mb-1">Considerar Data de:</div>
                        <v-btn-toggle v-model="filters.dateType" density="compact" color="primary" mandatory class="w-100 d-flex" divided variant="outlined">
                            <v-btn value="due_date" class="flex-grow-1 text-caption font-weight-bold">Vencimento</v-btn>
                            <v-btn value="payment_date" class="flex-grow-1 text-caption font-weight-bold">Recebimento (Baixa)</v-btn>
                        </v-btn-toggle>
                    </v-col>
                    <v-col cols="6"><v-text-field v-model="filters.customStart" label="De" type="date" variant="outlined" density="compact" hide-details class="ui-field" color="success" /></v-col>
                    <v-col cols="6"><v-text-field v-model="filters.customEnd" label="Até" type="date" variant="outlined" density="compact" hide-details class="ui-field" color="success" /></v-col>
                    <v-col cols="12" md="6"><v-autocomplete v-model="filters.customerId" :items="auxData.customers" item-title="name" item-value="id" label="Cliente" variant="outlined" density="compact" hide-details clearable class="ui-field" /></v-col>
                    <v-col cols="12" md="6"><v-autocomplete v-model="filters.salespersonId" :items="auxData.salespeople" item-title="full_name" item-value="id" label="Vendedor (Pedido)" variant="outlined" density="compact" hide-details clearable class="ui-field" /></v-col>
                    <v-col cols="12" md="6"><v-text-field v-model.number="filters.minValue" label="Valor Mín. (R$)" type="number" variant="outlined" density="compact" hide-details class="ui-field" prefix="R$" /></v-col>
                    <v-col cols="12" md="6"><v-text-field v-model.number="filters.maxValue" label="Valor Máx. (R$)" type="number" variant="outlined" density="compact" hide-details class="ui-field" prefix="R$" /></v-col>
                    <v-col cols="12"><v-autocomplete v-model="filters.chartOfAccountsId" :items="auxData.chartOfAccounts" item-title="name" item-value="id" label="Plano de Contas" variant="outlined" density="compact" hide-details clearable class="ui-field" /></v-col>

                    <v-col cols="12">
                        <div class="text-caption font-weight-black opacity-70 mb-2 mt-2">Auditoria Bancária</div>
                        <v-chip :color="filters.onlyConciliated ? 'teal-darken-3' : 'grey'" :variant="filters.onlyConciliated ? 'flat' : 'outlined'" class="solid-chip cursor-pointer chip-3d" @click="filters.onlyConciliated = !filters.onlyConciliated">
                            <v-icon start size="small" v-if="filters.onlyConciliated">mdi-check</v-icon>
                            <v-icon start size="small" v-else>mdi-shield-outline</v-icon>
                            Somente Conciliados (OFX)
                        </v-chip>
                    </v-col>

                    <v-col cols="12">
                      <div class="text-caption font-weight-black opacity-70 mb-2 mt-2">Status</div>
                      <div class="d-flex flex-wrap" style="gap: 8px;">
                        <v-chip v-for="s in ['em_aberto','pago','atrasado']" :key="s" :color="filters.status.includes(s) ? (s === 'pago' ? 'success' : (s === 'atrasado' ? 'error' : 'warning')) : 'grey'" :variant="filters.status.includes(s) ? 'flat' : 'outlined'" class="solid-chip cursor-pointer" @click="toggleStatusFilter(s)">
                          <v-icon start size="small" v-if="filters.status.includes(s)">mdi-check</v-icon>
                          {{ s === 'em_aberto' ? 'Aberto' : (s === 'pago' ? 'Recebido' : 'Atrasado') }}
                        </v-chip>
                      </div>
                    </v-col>
                  </v-row>
                  <div class="d-flex justify-end mt-6">
                    <v-btn variant="flat" class="btn-3d w-100 font-weight-bold" height="42" color="success" @click="applyFiltersFromDropdown">
                      <v-icon start>mdi-magnify</v-icon> Aplicar Filtros
                    </v-btn>
                  </div>
                </v-card>
              </v-menu>

              <v-menu location="bottom end" :close-on-content-click="true">
                <template v-slot:activator="{ props }">
                  <v-btn
                    v-bind="props"
                    variant="flat"
                    class="btn-3d"
                    height="40"
                    prepend-icon="mdi-dots-vertical"
                    color="success"
                  >
                    <span class="d-none d-sm-inline">Ações</span>
                    <v-icon end size="small" class="d-none d-sm-inline">mdi-chevron-down</v-icon>
                  </v-btn>
                </template>

                <v-card class="rounded-0" min-width="260" :class="isDark ? 'bg-grey-darken-4' : 'bg-white'">
                  <v-list density="compact" nav :class="isDark ? 'bg-grey-darken-4 text-white' : 'bg-white'">
                    <v-list-item @click="openNewReceivableModal" prepend-icon="mdi-plus">
                      <v-list-item-title>Novo Recebimento</v-list-item-title>
                    </v-list-item>
                    <v-list-item @click="openFixedAccountModal" prepend-icon="mdi-calendar-sync" class="text-teal-darken-3">
                        <v-list-item-title class="font-weight-bold">Lançar Recebimento Fixo</v-list-item-title>
                    </v-list-item>
                    <v-divider class="my-2"></v-divider>
                    <v-list-item @click="syncModalOpen = true" prepend-icon="mdi-cloud-sync">
                      <v-list-item-title>Sincronizar ERP</v-list-item-title>
                    </v-list-item>
                    <v-list-item @click="fetchReceivables" prepend-icon="mdi-refresh">
                      <v-list-item-title>Atualizar Lista</v-list-item-title>
                    </v-list-item>
                    <v-list-item @click="showImportModal = true" prepend-icon="mdi-upload">
                      <v-list-item-title>Importar Planilha</v-list-item-title>
                    </v-list-item>
                    <v-divider class="my-2"></v-divider>
                    <v-list-item @click="gridSettings.showModal = true" prepend-icon="mdi-table-cog">
                      <v-list-item-title>Configurar Grid</v-list-item-title>
                    </v-list-item>
                  </v-list>
                </v-card>
              </v-menu>
            </div>
          </div>
        </div>
      </div>

      <div
        class="flex-grow-1 overflow-hidden d-flex flex-column transition-all"
        :class="[
           isMobileFullscreen ? 'absolute top-0 left-0 w-100 h-100 z-20 bg-white' : 'px-4 px-md-6 pb-0',
           'grid-container-' + gridSettings.textSize
        ]"
      >
        <v-card
          class="flex-grow-1 d-flex flex-column rounded-0 border-thin overflow-hidden"
          :class="isDark ? 'glass-card border-white-05' : 'bg-white shadow-sm'"
          :elevation="0"
        >
          <div v-if="isMobileFullscreen" class="bg-success text-white px-3 py-3 d-flex align-center justify-space-between flex-shrink-0 gap-3 elevation-2 z-30">
             <v-btn icon="mdi-arrow-left" variant="text" color="white" @click="isMobileFullscreen = false" class="flex-shrink-0"></v-btn>

             <div class="flex-grow-1 relative d-flex align-center">
                 <input
                    v-model="filters.search"
                    type="text"
                    placeholder="Pesquisar..."
                    class="w-100 bg-white-20 text-white rounded px-3 pr-8 text-body-2 font-weight-bold outline-none placeholder-white-70"
                    style="border: 1px solid rgba(255,255,255,0.3); height: 40px;"
                 >
                 <div class="absolute right-2" style="top: 50%; transform: translateY(-50%); display: flex; align-items: center;">
                    <v-icon v-if="!filters.search" size="small" class="text-white-70">mdi-magnify</v-icon>
                    <v-icon v-else size="small" class="text-white cursor-pointer" @click="filters.search = ''">mdi-close</v-icon>
                 </div>
             </div>

             <v-btn icon variant="text" color="white" class="flex-shrink-0" @click="mobileFiltersOpen = true">
                 <v-badge v-if="activeFilterCount > 0" :content="activeFilterCount" color="red" dot floating>
                    <v-icon>mdi-filter-variant</v-icon>
                 </v-badge>
                 <v-icon v-else>mdi-filter-variant</v-icon>
             </v-btn>
          </div>

          <div v-if="!mobile" class="grid-scroll flex-grow-1 overflow-auto custom-scroll relative">
            <div
              class="grid-header sticky-head"
              :class="[isDark ? 'grid-surface-dark border-bottom-white-05' : 'grid-surface-light border-b border-grey-lighten-2']"
              :style="{ gridTemplateColumns: computedGridTemplate }"
            >
              <div class="cell cell-check center">
                <v-checkbox-btn
                  :model-value="areAllSelected"
                  @update:model-value="toggleSelectAll"
                  density="compact"
                  color="success"
                  class="chk-fixed"
                ></v-checkbox-btn>
              </div>

              <div class="cell cell-ref center header-text" v-if="isColumnVisible('ref')">Pedido</div>
              <div class="cell cell-client header-text" v-if="isColumnVisible('client')">Cliente / Pagador</div>
              <div class="cell cell-desc header-text" v-if="isColumnVisible('desc')">Descrição</div>
              <div class="cell cell-cat center header-text" v-if="isColumnVisible('cat')">Plano de Contas</div>
              <div class="cell cell-company center header-text" v-if="isColumnVisible('company')">Empresa</div>
              <div class="cell cell-date center header-text" v-if="isColumnVisible('date')">Vencimento</div>
              <div class="cell cell-date2 center header-text" v-if="isColumnVisible('date2')">Recebimento</div>
              <div class="cell cell-val center header-text" v-if="isColumnVisible('val')">Valor</div>
              <div class="cell center header-text" v-if="isColumnVisible('conciliated')">Conciliação</div>
              <div class="cell cell-status center header-text" v-if="isColumnVisible('status')">Status</div>
              <div class="cell cell-ext center header-text" v-if="isColumnVisible('ext')">Conta</div>
              <div class="cell cell-ext-lg header-text" v-if="isColumnVisible('ext-lg')">Obs</div>
              <div class="cell cell-actions center header-text">Ações</div>
            </div>

            <div v-if="loading" class="d-flex flex-column justify-center align-center h-100 py-10 min-w-full">
              <v-progress-circular indeterminate color="success" size="32" width="3"></v-progress-circular>
              <span class="text-caption mt-2 font-weight-bold opacity-60">Carregando...</span>
            </div>

            <div v-else-if="items.length === 0" class="d-flex flex-column justify-center align-center h-100 opacity-60 gap-2 py-10 min-w-full">
              <v-icon size="48" color="grey-lighten-1">mdi-filter-off-outline</v-icon>
              <span class="text-body-2 font-weight-medium text-grey">Nenhum resultado.</span>
            </div>

            <div
              v-else
              v-for="(item, index) in items"
              :key="item.id"
              class="grid-row"
              :class="[
                isDark ? 'grid-row-dark' : 'grid-row-light',
                zebraClass(index),
                selectedIds.has(item.id) ? (isDark ? 'grid-selected-dark' : 'grid-selected-light') : ''
              ]"
              :style="{ gridTemplateColumns: computedGridTemplate }"
            >
                <div class="cell cell-check center">
                    <v-checkbox-btn :model-value="selectedIds.has(item.id)" @update:model-value="toggleSelection(item.id)" density="compact" color="success" class="chk-fixed" :disabled="item.is_signal"></v-checkbox-btn>
                </div>

                <div class="cell cell-ref center" v-if="isColumnVisible('ref')">
                    <span v-if="item.order_id || item.store_sale_id || (item.order_number && item.order_number !== 'S/N')"
                          class="font-weight-black cursor-pointer hover-opacity font-mono"
                          :class="isDark ? 'text-white' : 'text-blue-darken-2'"
                          style="font-size: 12px; text-decoration: underline;"
                          @click="openOrderDetail(item)"> #{{ item.order_number }}
                    </span>
                    <span v-else class="pill-ref" :class="getRefClass(item)" :style="isDark ? 'background: transparent !important; text-decoration: underline; color: #fff !important; padding: 0;' : ''">{{ getRefNumber(item) }}</span>
                </div>

                <div class="cell cell-client" v-if="isColumnVisible('client')">
                    <div class="text-truncate list-text-11 font-weight-bold" :title="getCustomerName(item)">{{ getCustomerName(item) }}</div>
                </div>
                <div class="cell cell-desc" v-if="isColumnVisible('desc')">
                    <div class="d-flex flex-column" style="min-width: 0;">
                        <div class="text-truncate list-text-11 font-weight-medium" :class="isDark ? 'text-white' : 'text-grey-darken-4'" :title="item.description">
                            <v-icon v-if="item.is_signal" size="10" color="orange" class="mr-1">mdi-flash</v-icon>
                            {{ item.description }}
                        </div>
                        <div v-if="hasAttachments(item)" class="mt-1 d-flex gap-2">
                             <v-btn variant="tonal" size="x-small" color="teal-darken-3" height="20" class="px-2 font-weight-bold btn-3d" style="text-transform: none; letter-spacing: 0;" @click.stop="openAttachment(item)"><v-icon start size="12" class="mr-1">mdi-paperclip</v-icon>Anexo</v-btn>
                        </div>
                    </div>
                </div>
                <div class="cell cell-cat center" v-if="isColumnVisible('cat')"><span class="text-truncate list-text-11 font-weight-medium" :class="isDark ? 'text-white-70' : 'text-grey-darken-3'" :title="getChartName(item.chart_of_accounts_id)">{{ getChartName(item.chart_of_accounts_id) || '-' }}</span></div>
                <div class="cell cell-company center" v-if="isColumnVisible('company')"><span v-if="item.company_id" class="solid-chip chip-company chip-3d">{{ getCompanyName(item.company_id) }}</span><span v-else class="list-text-11 opacity-60 text-warning">-</span></div>

                <div class="cell cell-date center" v-if="isColumnVisible('date')">
                    <span class="list-text-11 font-mono" :class="isOverdue(item) ? 'text-error font-weight-black' : (isDark ? 'text-white-70 font-weight-medium' : 'text-grey-darken-4 font-weight-medium')">
                        {{ formatDateSafe(item.due_date) }}
                    </span>
                </div>

                <div class="cell cell-date2 center" v-if="isColumnVisible('date2')">
                    <span class="list-text-11 font-mono font-weight-medium" :class="isDark ? 'text-white-70' : 'text-grey-darken-4'">
                        {{ item.payment_date ? formatDateSafe(item.payment_date) : '-' }}
                    </span>
                </div>

                <div class="cell cell-val center" v-if="isColumnVisible('val')">
                    <span class="list-text-11 font-mono font-weight-black" :class="isDark ? 'text-white' : 'text-grey-darken-4'">
                        {{ formatCurrency(item.value - (item.discount || 0)) }}
                    </span>
                </div>

                <div class="cell center" v-if="isColumnVisible('conciliated')">
                    <v-tooltip v-if="item.reconciliation_status === 'CONCILIATED'" location="top" content-class="tooltip-conciliated">
                        <template v-slot:activator="{ props }">
                            <div v-bind="props" class="bg-teal-lighten-5 rounded-circle pa-1 d-flex align-center justify-center elevation-1 border border-teal-lighten-3 cursor-pointer pulse-box">
                                <v-icon size="16" color="teal-darken-3" class="pulse-success">mdi-shield-check</v-icon>
                            </div>
                        </template>
                        <div class="text-caption font-weight-black text-teal-accent-3 mb-1"><v-icon start size="14" color="teal-accent-3">mdi-bank-transfer</v-icon> Conciliado via Banco</div>
                        <div class="text-[10px] font-mono text-white opacity-90">Assinatura: {{ item.bank_fitid || 'OFX/API' }}</div>
                    </v-tooltip>
                    <div v-else class="rounded-circle pa-1 d-flex align-center justify-center border opacity-50" :class="isDark ? 'border-white-20 bg-white-05' : 'border-grey-lighten-2 bg-grey-lighten-4'">
                         <v-icon size="16" :color="isDark ? 'white-50' : 'grey-darken-1'">mdi-shield-outline</v-icon>
                    </div>
                </div>

                <div class="cell cell-status center" v-if="isColumnVisible('status')">
                    <span class="solid-chip chip-status chip-3d cursor-pointer" :class="getStatusChipClass(item)" @click.stop="openStatusModal(item)">
                        {{ getStatusLabel(item) }}
                    </span>
                </div>

                <div class="cell cell-ext center" v-if="isColumnVisible('ext')"><span class="text-truncate list-text-11">{{ getBankAccountName(item.bank_account_id) }}</span></div>
                <div class="cell cell-ext-lg" v-if="isColumnVisible('ext-lg')"><span class="text-truncate list-text-11 opacity-75">{{ item.notes || '-' }}</span></div>

                <div class="cell cell-actions center">
                    <div class="actions-inline">
                        <v-btn icon size="small" class="action-btn action-edit btn-3d" @click.stop="openEditModal(item)" title="Editar" variant="flat" :disabled="item.is_signal"><v-icon size="16">mdi-pencil</v-icon></v-btn>
                        <v-btn v-if="item.status !== 'pago'" icon size="small" class="action-btn action-pay btn-3d" @click.stop="openStatusModal(item)" title="Baixar Título" variant="flat" :disabled="item.is_signal"><v-icon size="16">mdi-check</v-icon></v-btn>
                        <v-btn v-else icon size="small" class="action-btn action-revert btn-3d" @click.stop="openStatusModal(item)" title="Estornar" variant="flat" :disabled="item.is_signal"><v-icon size="16">mdi-undo-variant</v-icon></v-btn>

                        <v-menu location="bottom end">
                            <template v-slot:activator="{ props }">
                                <v-btn v-bind="props" icon size="small" class="action-btn bg-success btn-3d" variant="flat" title="Ações Extras" :disabled="item.is_signal">
                                    <v-icon size="16">mdi-chevron-down</v-icon>
                                </v-btn>
                            </template>
                            <v-list density="compact" class="shadow-xl border-thin rounded-lg" :class="isDark ? 'bg-grey-darken-4 text-white' : 'bg-white'">
                                <v-list-item v-if="item.status === 'pago'" @click="handlePrintReceipt(item)">
                                    <template v-slot:prepend><v-icon color="blue-grey" size="small" class="mr-2">mdi-printer</v-icon></template>
                                    <v-list-item-title class="text-caption font-weight-bold">Imprimir Recibo</v-list-item-title>
                                </v-list-item>
                                <v-list-item @click="openLinkOrderModal(item)">
                                    <template v-slot:prepend><v-icon color="indigo" size="small" class="mr-2">mdi-link-variant</v-icon></template>
                                    <v-list-item-title class="text-caption font-weight-bold">Vincular a Pedido</v-list-item-title>
                                </v-list-item>
                            </v-list>
                        </v-menu>

                        <v-btn icon size="small" class="action-btn action-del btn-3d" @click.stop="deleteReceivable(item)" title="Excluir" variant="flat" :disabled="item.is_signal"><v-icon size="16">mdi-trash-can-outline</v-icon></v-btn>
                    </div>
                </div>
            </div>
          </div>

          <div v-else class="flex-grow-1 overflow-y-auto pb-12 custom-scroll" :class="isDark ? 'bg-transparent' : 'bg-grey-lighten-4'">
              <div v-if="loading" class="d-flex flex-column align-center justify-center py-8">
                  <v-progress-circular indeterminate color="success"></v-progress-circular>
                  <span class="text-caption mt-2">Carregando...</span>
              </div>

              <div v-else-if="items.length === 0" class="d-flex flex-column align-center justify-center py-10 opacity-60">
                   <v-icon size="40">mdi-filter-off</v-icon>
                   <span class="text-caption mt-2">Nada encontrado</span>
              </div>

              <div v-else class="d-flex flex-column gap-3 pa-3">
                 <div
                    v-for="(item, index) in items"
                    :key="item.id"
                    class="rounded-lg border-thin pa-4 elevation-1 relative overflow-hidden"
                    :class="isDark ? 'bg-surface-variant' : 'bg-white'"
                    @click="toggleSelection(item.id)"
                 >
                    <div v-if="selectedIds.has(item.id)" class="absolute top-0 right-0 p-2 bg-success rounded-bl-xl shadow-md z-10">
                        <v-icon size="small" color="white">mdi-check</v-icon>
                    </div>

                    <div class="d-flex justify-space-between align-center mb-2">
                        <div class="d-flex align-center gap-1">
                            <v-chip size="x-small" :color="isDark ? 'grey-darken-3' : 'grey-lighten-3'" class="font-weight-black chip-3d" :class="isDark ? 'text-white' : 'text-grey-darken-3'">
                                #{{ item.order_number }}
                            </v-chip>
                            <v-chip v-if="item.is_signal" size="x-small" color="orange-lighten-4" class="text-orange-darken-4 font-weight-bold chip-3d">
                                <v-icon start size="10">mdi-flash</v-icon>Sinal
                            </v-chip>
                        </div>
                        <div class="d-flex align-center gap-2">
                            <v-tooltip v-if="item.reconciliation_status === 'CONCILIATED'" location="top" content-class="tooltip-conciliated">
                                <template v-slot:activator="{ props }">
                                    <div v-bind="props" class="bg-teal-lighten-5 rounded-circle pa-1 d-flex align-center justify-center elevation-1 border border-teal-lighten-3 cursor-pointer pulse-box">
                                        <v-icon size="16" color="teal-darken-3" class="pulse-success">mdi-shield-check</v-icon>
                                    </div>
                                </template>
                                <div class="text-caption font-weight-black text-teal-accent-3 mb-1"><v-icon start size="14" color="teal-accent-3">mdi-bank-transfer</v-icon> Conciliado via Banco</div>
                                <div class="text-[10px] font-mono text-white opacity-90">Assinatura: {{ item.bank_fitid || 'OFX/API' }}</div>
                            </v-tooltip>

                            <v-chip size="small" :color="getVuetifyStatusColor(item)" variant="flat" class="font-weight-black text-white text-uppercase px-2 chip-3d cursor-pointer" style="height: 20px; font-size: 10px;" @click.stop="openStatusModal(item)">
                                 {{ getStatusLabel(item) }}
                            </v-chip>
                        </div>
                    </div>

                    <div class="mb-3">
                        <div class="text-subtitle-1 font-weight-black leading-tight mb-1" :class="isDark ? 'text-white' : 'text-grey-darken-4'">
                            {{ getCustomerName(item) }}
                        </div>
                        <div class="text-caption text-grey text-truncate mb-2">
                            {{ item.description }}
                        </div>

                        <div class="d-flex align-end justify-space-between mt-2">
                             <div class="d-flex flex-column">
                                 <span class="text-[10px] font-weight-bold text-grey uppercase tracking-wide">Vencimento</span>
                                 <div class="text-body-2 font-mono font-weight-bold d-flex align-center" :class="isOverdue(item) ? 'text-red-darken-1' : (isDark ? 'text-white-70' : 'text-grey-darken-2')">
                                     <v-icon size="14" class="mr-1">mdi-calendar</v-icon>
                                     {{ formatDateSafe(item.due_date) }}
                                 </div>
                             </div>

                             <div class="text-right">
                                 <span class="text-[10px] font-weight-bold text-grey uppercase tracking-wide">Valor</span>
                                 <div class="text-h6 font-weight-black leading-none" :class="isDark ? 'text-success-lighten-1' : 'text-success-darken-2'">
                                    {{ formatCurrency(item.value - (item.discount || 0)) }}
                                 </div>
                             </div>
                        </div>
                    </div>

                    <v-divider class="mb-3 border-opacity-50"></v-divider>

                    <div class="d-flex gap-2">
                         <v-btn
                            class="flex-grow-1 font-weight-bold btn-3d"
                            :class="isDark ? 'text-white' : 'text-grey-darken-3'"
                            variant="flat"
                            :color="isDark ? 'grey-darken-3' : 'grey-lighten-3'"
                            height="36"
                            @click.stop="openEditModal(item)"
                            :disabled="item.is_signal"
                         >
                            <v-icon size="18" class="mr-1">mdi-pencil</v-icon> Editar
                         </v-btn>

                         <v-btn
                            v-if="item.status !== 'pago'"
                            class="flex-grow-1 font-weight-bold btn-3d text-white"
                            variant="flat"
                            color="success"
                            height="36"
                            @click.stop="openStatusModal(item)"
                            :disabled="item.is_signal"
                         >
                            <v-icon size="18" class="mr-1">mdi-check</v-icon> Baixar Título
                         </v-btn>

                         <v-btn
                            v-else
                            class="flex-grow-1 font-weight-bold btn-3d text-white"
                            variant="flat"
                            color="warning"
                            height="36"
                            @click.stop="openStatusModal(item)"
                            :disabled="item.is_signal"
                         >
                            <v-icon size="18" class="mr-1">mdi-undo</v-icon> Estornar
                         </v-btn>

                         <v-btn
                            v-if="item.status === 'pago'"
                            class="flex-grow-0 font-weight-bold btn-3d text-white"
                            variant="flat"
                            color="blue-grey-darken-2"
                            height="36"
                            min-width="36"
                            width="36"
                            @click.stop="handlePrintReceipt(item)"
                            :loading="printLoadingId === item.id"
                            title="Imprimir Recibo"
                         >
                            <v-icon size="18">mdi-printer</v-icon>
                         </v-btn>
                    </div>
                 </div>
              </div>
          </div>

          <div class="flex-shrink-0 border-t px-4 py-2 d-flex flex-column flex-md-row align-center justify-space-between z-20" :class="isDark ? 'bg-surface-variant border-top-white-05' : 'bg-white'">
            <div class="d-flex align-center justify-space-between w-100 w-md-auto mb-2 mb-md-0">
               <div class="text-caption opacity-80 cursor-pointer" @click="showLogs = !showLogs">
                 <strong>{{ totalItems }}</strong> regs
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
              @update:model-value="handlePageChange"
            ></v-pagination>
          </div>

          <v-expand-transition>
            <div v-if="showLogs" class="bg-black text-green-accent-3 font-mono text-caption pa-3 border-t overflow-auto" style="max-height: 200px; line-height: 1.4;">
               <div class="font-weight-bold mb-1 border-b border-green-900 pb-1">CONSOLE DE RECEBÍVEIS & SINAIS (MULTI-TENANT)</div>
                  <div class="d-flex justify-space-between flex-column flex-md-row">
                    <div>
                      <div>> Contexto: {{ companyStore.isGlobalView ? 'GLOBAL' : companyStore.context }}</div>
                      <div>> Query Status: [{{ filters.status.join(', ') || 'ALL' }}]</div>
                      <div>> Query Date: {{ filters.customStart }} até {{ filters.customEnd }}</div>
                      <div v-if="filters.search">> Search Term: "{{ filters.search }}"</div>
                    </div>
                    <div class="text-left text-md-right mt-2 mt-md-0">
                      <div>TOTAL LISTADO (Global): {{ totalItems }}</div>
                      <div class="font-weight-black mt-1">SOMA TOTAL: {{ formatCurrency(kpiTotals.value) }}</div>
                      <div class="text-green-lighten-2">PAGO: {{ formatCurrency(kpiTotals.paid) }}</div>
                      <div class="text-red-lighten-2">VENCIDO: {{ formatCurrency(kpiTotals.overdue) }}</div>
                    </div>
                  </div>
            </div>
          </v-expand-transition>
        </v-card>
      </div>
    </div>

    <v-scale-transition origin="bottom center">
      <div v-if="selectedIds.size > 0" class="selection-island-wrapper">
        <div class="selection-island elevation-10">
          <div class="d-flex align-center pr-4 border-r border-white-20 mr-4">
            <v-btn icon size="small" variant="text" color="white" @click="selectedIds.clear()">
              <v-icon>mdi-close</v-icon>
            </v-btn>
            <span class="text-body-2 font-weight-bold text-white ml-2 text-no-wrap">
              {{ selectedIds.size }} <span class="d-none d-sm-inline">selecionados</span>
            </span>
          </div>

          <div class="d-flex align-center overflow-x-auto" style="gap: 8px;">
            <v-btn prepend-icon="mdi-domain" variant="text" color="white" height="36" class="font-weight-bold text-capitalize" @click="openBulkCompanyModal">
              <span class="d-none d-sm-inline">Mudar Empresa</span><span class="d-inline d-sm-none">Empresa</span>
            </v-btn>
            <v-divider vertical class="border-white-20 mx-1"></v-divider>

            <v-btn v-if="selectedIds.size >= 2" prepend-icon="mdi-table-merge-cells" variant="text" color="blue-lighten-2" height="36" class="font-weight-bold text-capitalize" @click="openGroupModal">Agrupar Lançamentos</v-btn>

            <v-btn prepend-icon="mdi-check-all" variant="text" color="green-accent-2" height="36" class="font-weight-bold text-capitalize" @click="bulkUpdateStatus('pago')">Receber Hoje</v-btn>
            <v-btn prepend-icon="mdi-calendar-check" variant="text" color="teal-accent-3" height="36" class="font-weight-bold text-capitalize" @click="bulkUpdateStatus('pago', true)">Receber no Venc.</v-btn>
            <v-btn prepend-icon="mdi-undo" variant="text" color="yellow-accent-2" height="36" class="font-weight-bold text-capitalize" @click="bulkUpdateStatus('em_aberto')">Estornar</v-btn>
            <v-divider vertical class="border-white-20 mx-1"></v-divider>
            <v-btn prepend-icon="mdi-trash-can-outline" variant="flat" color="red-darken-1" height="36" class="font-weight-bold px-4 btn-3d" @click="deleteSelected">Excluir</v-btn>
          </div>
        </div>
      </div>
    </v-scale-transition>

    <v-scale-transition>
        <div v-if="feedback.show" class="feedback-toast" :class="feedback.error ? 'is-error' : 'is-success'">
            <div class="d-flex align-center">
                <div class="icon-box mr-3">
                    <v-icon color="white">{{ feedback.error ? 'mdi-alert-circle' : 'mdi-check-circle' }}</v-icon>
                </div>
                <div>
                    <div class="text-subtitle-2 font-weight-black text-white">
                        {{ feedback.error ? 'Erro na Pesquisa' : 'Pesquisa Concluída' }}
                    </div>
                    <div class="text-caption text-white opacity-80 lh-12">
                        {{ feedback.message }}
                    </div>
                </div>
                <div class="ml-auto d-flex align-center pl-3">
                    <v-btn icon size="small" variant="text" color="white" @click="feedback.show = false">
                        <v-icon>mdi-close</v-icon>
                    </v-btn>
                </div>
            </div>
        </div>
    </v-scale-transition>

    <v-dialog v-model="gridSettings.showModal" max-width="500" scrim="black opacity-70">
        <v-card class="rounded-lg overflow-hidden" :class="isDark ? 'bg-grey-darken-4 text-white' : 'bg-white'">
            <div class="px-6 py-4 border-b d-flex align-center justify-space-between" :class="isDark ? 'bg-grey-darken-3' : 'bg-grey-lighten-5'">
                <div>
                    <div class="text-caption font-weight-black opacity-70 text-uppercase">Personalização</div>
                    <div class="text-h6 font-weight-black">Configurar Grid</div>
                </div>
                <v-btn icon variant="text" @click="gridSettings.showModal = false"><v-icon>mdi-close</v-icon></v-btn>
            </div>
            <div class="pa-6">
                <div class="text-subtitle-2 font-weight-bold mb-3" :class="isDark ? 'text-white' : 'text-grey-darken-2'">Tamanho do Texto</div>
                <v-btn-toggle v-model="gridSettings.textSize" density="compact" color="primary" mandatory class="w-100 d-flex mb-6" divided variant="outlined">
                    <v-btn value="small" class="flex-grow-1 text-caption font-weight-bold">Pequeno</v-btn>
                    <v-btn value="medium" class="flex-grow-1 text-caption font-weight-bold">Normal</v-btn>
                    <v-btn value="large" class="flex-grow-1 text-caption font-weight-bold">Grande</v-btn>
                </v-btn-toggle>

                <div class="text-subtitle-2 font-weight-bold mb-3" :class="isDark ? 'text-white' : 'text-grey-darken-2'">Colunas Visíveis</div>
                <v-list density="compact" class="rounded border-thin max-h-[300px] overflow-y-auto" :class="isDark ? 'bg-grey-darken-3 text-white' : 'bg-grey-lighten-5'">
                    <template v-for="(col, index) in gridSettings.columns" :key="col.key">
                        <v-list-item v-if="!col.globalOnly || companyStore.isGlobalView">
                            <template v-slot:prepend>
                                <v-checkbox-btn v-model="col.visible" color="success" density="compact" hide-details></v-checkbox-btn>
                            </template>
                            <v-list-item-title class="font-weight-medium text-body-2">{{ col.label }}</v-list-item-title>
                        </v-list-item>
                    </template>
                </v-list>
            </div>
            <div class="px-6 py-4 border-t d-flex justify-end gap-3" :class="isDark ? 'bg-grey-darken-3' : 'bg-grey-lighten-5'">
                <v-btn variant="outlined" class="btn-3d" height="40" @click="gridSettings.showModal = false" :disabled="gridSettings.loading">Cancelar</v-btn>
                <v-btn color="success" variant="flat" class="btn-3d px-6 font-weight-black" height="40" :loading="gridSettings.loading" @click="saveGridSettings">Salvar e Aplicar</v-btn>
            </div>
        </v-card>
    </v-dialog>

    <v-dialog v-model="mobileFiltersOpen" fullscreen transition="dialog-bottom-transition" scrim="black">
        <v-card class="d-flex flex-column h-100" :class="isDark ? 'bg-grey-darken-4 text-white' : 'bg-grey-lighten-5'">
            <div class="px-4 py-3 d-flex align-center justify-space-between border-b flex-shrink-0" :class="isDark ? 'bg-grey-darken-3' : 'bg-white'">
                <span class="text-h6 font-weight-black">Filtros Avançados</span>
                <div class="d-flex align-center">
                    <v-btn variant="text" color="error" size="small" class="mr-2 font-weight-bold" @click="clearFilters">Limpar</v-btn>
                    <v-btn icon="mdi-close" variant="text" @click="mobileFiltersOpen = false"></v-btn>
                </div>
            </div>

            <div class="flex-grow-1 overflow-y-auto pa-4">
                 <div class="text-caption font-weight-bold mb-1">Considerar Data de:</div>
                 <v-btn-toggle v-model="filters.dateType" density="compact" color="primary" mandatory class="w-100 d-flex mb-4" divided variant="outlined">
                    <v-btn value="due_date" class="flex-grow-1 text-caption font-weight-bold">Vencimento</v-btn>
                    <v-btn value="payment_date" class="flex-grow-1 text-caption font-weight-bold">Pagamento</v-btn>
                 </v-btn-toggle>

                 <v-row dense class="row-gap">
                    <v-col cols="6"><v-text-field v-model="filters.customStart" label="De" type="date" variant="outlined" density="comfortable" hide-details class="ui-field" /></v-col>
                    <v-col cols="6"><v-text-field v-model="filters.customEnd" label="Até" type="date" variant="outlined" density="comfortable" hide-details class="ui-field" /></v-col>
                    <v-col cols="12"><v-autocomplete v-model="filters.customerId" :items="auxData.customers" item-title="name" item-value="id" label="Cliente" variant="outlined" density="comfortable" hide-details clearable class="ui-field" /></v-col>
                    <v-col cols="12"><v-autocomplete v-model="filters.salespersonId" :items="auxData.salespeople" item-title="full_name" item-value="id" label="Vendedor" variant="outlined" density="comfortable" hide-details clearable class="ui-field" /></v-col>
                    <v-col cols="12"><v-autocomplete v-model="filters.chartOfAccountsId" :items="auxData.chartOfAccounts" item-title="name" item-value="id" label="Plano de Contas" variant="outlined" density="comfortable" hide-details clearable class="ui-field" /></v-col>

                    <v-col cols="6"><v-text-field v-model.number="filters.minValue" label="Valor Mín. (R$)" type="number" variant="outlined" density="comfortable" hide-details class="ui-field" prefix="R$" /></v-col>
                    <v-col cols="6"><v-text-field v-model.number="filters.maxValue" label="Valor Máx. (R$)" type="number" variant="outlined" density="comfortable" hide-details class="ui-field" prefix="R$" /></v-col>

                    <v-col cols="12">
                        <div class="text-caption font-weight-black opacity-70 mb-2 mt-2">Auditoria Bancária</div>
                        <v-chip :color="filters.onlyConciliated ? 'teal-darken-3' : 'grey'" :variant="filters.onlyConciliated ? 'flat' : 'outlined'" class="solid-chip cursor-pointer chip-3d" @click="filters.onlyConciliated = !filters.onlyConciliated">
                            <v-icon start size="small" v-if="filters.onlyConciliated">mdi-check</v-icon>
                            <v-icon start size="small" v-else>mdi-shield-outline</v-icon>
                            Somente Conciliados (OFX)
                        </v-chip>
                    </v-col>

                    <v-col cols="12">
                      <div class="text-caption font-weight-black opacity-70 mb-2 mt-2">Status</div>
                      <div class="d-flex flex-wrap" style="gap: 8px;">
                        <v-chip v-for="s in ['em_aberto','pago','atrasado']" :key="s" :color="filters.status.includes(s) ? (s === 'pago' ? 'success' : (s === 'atrasado' ? 'error' : 'warning')) : 'grey'" :variant="filters.status.includes(s) ? 'flat' : 'outlined'" class="solid-chip cursor-pointer" @click="toggleStatusFilter(s)">
                          <v-icon start size="small" v-if="filters.status.includes(s)">mdi-check</v-icon>
                          {{ s === 'em_aberto' ? 'Aberto' : (s === 'pago' ? 'Recebido' : 'Atrasado') }}
                        </v-chip>
                      </div>
                    </v-col>
                 </v-row>
            </div>

            <div class="pa-4 border-t flex-shrink-0" :class="isDark ? 'bg-grey-darken-3' : 'bg-white'">
                <v-btn block color="success" size="large" variant="flat" class="font-weight-bold btn-3d" @click="applyFiltersFromDropdown(); mobileFiltersOpen = false">
                    Aplicar Filtros
                </v-btn>
            </div>
        </v-card>
    </v-dialog>

    <v-dialog
        v-model="editModal.show"
        :width="mobile ? '100%' : '1200'"
        :fullscreen="mobile"
        height="90vh"
        persistent
        scrim="black opacity-80"
        transition="dialog-bottom-transition"
        class="fixed-dialog"
    >
        <v-card class="d-flex overflow-hidden rounded-0 fill-height" :class="mobile ? 'flex-column' : 'flex-row'" height="100%">
            <div class="modal-sidebar pa-6 d-flex flex-column text-white" :class="[editModal.isFixedAccount ? 'bg-teal-darken-3' : (isDark ? 'bg-grey-darken-4' : 'bg-success'), mobile ? 'd-none' : '']" style="width: 340px; flex-shrink: 0; border-right: 1px solid rgba(255,255,255,0.1);">
                 <div class="d-flex align-center" style="gap: 12px;">
                    <div class="bg-white-20 p-3 rounded-0 d-flex align-center justify-center" style="width: 48px; height: 48px;">
                        <v-icon size="32" color="white">{{ editModal.isFixedAccount ? 'mdi-calendar-sync' : 'mdi-cash-plus' }}</v-icon>
                    </div>
                    <div>
                    <h3 class="text-h6 font-weight-black leading-tight">
                        {{ editModal.form.id ? 'Editando' : 'Novo' }}
                        {{ editModal.isFixedAccount ? 'Fixo' : 'Recebimento' }}
                    </h3>
                    <div class="text-caption opacity-80">
                        {{ editModal.isFixedAccount ? 'Gestão de entradas recorrentes.' : 'Detalhes de Entrada' }}
                    </div>
                    </div>
                </div>
                <div class="mt-6 bg-white-10 pa-4 rounded-0">
                    <div class="text-caption font-weight-black opacity-70 mb-1 text-uppercase">Valor Total Previsto</div>
                    <div class="text-h4 font-weight-black">{{ formatCurrency(editModal.form.value - (editModal.form.discount || 0)) }}</div>
                    <div v-if="editModal.recurrence.enabled" class="text-caption mt-2 text-yellow-accent-1 font-weight-bold">
                        <v-icon start size="small" color="yellow-accent-1">mdi-refresh</v-icon>
                        Recorrência Ativa: {{ editModal.recurrence.count }}x
                    </div>
                </div>
                 <v-spacer></v-spacer>
            </div>

            <div class="flex-grow-1 d-flex flex-column h-100 overflow-hidden relative" :class="isDark ? 'bg-grey-darken-4 text-white' : 'bg-white'">
                 <div v-if="mobile" class="pa-4 text-white d-flex align-center justify-space-between flex-shrink-0" :class="isDark ? 'bg-grey-darken-3' : 'bg-success'">
                     <div>
                         <div class="text-subtitle-2 font-weight-black">{{ editModal.form.id ? 'Editar' : 'Novo' }} Recebimento</div>
                         <div class="text-h5 font-weight-bold">{{ formatCurrency(editModal.form.value - (editModal.form.discount || 0)) }}</div>
                     </div>
                     <v-btn icon="mdi-close" variant="text" color="white" @click="editModal.show = false"></v-btn>
                 </div>

                 <v-expand-transition>
                    <div v-if="editModal.error" class="bg-red-lighten-5 px-6 py-4 border-b border-red-lighten-4 d-flex align-start">
                        <v-icon color="red" class="mr-3 mt-1">mdi-alert-circle</v-icon>
                        <div class="flex-grow-1">
                            <div class="text-subtitle-2 font-weight-bold text-red-darken-3">Erro ao salvar lançamento</div>
                            <div class="text-caption text-red-darken-4 mt-1">{{ editModal.error }}</div>
                        </div>
                        <v-btn icon variant="text" size="small" color="red" @click="editModal.error = null">
                            <v-icon>mdi-close</v-icon>
                        </v-btn>
                    </div>
                </v-expand-transition>

                 <div class="pa-0 border-b flex-shrink-0" :class="isDark ? 'bg-grey-darken-3' : 'bg-grey-lighten-5'">
                    <div class="d-flex align-center justify-space-between px-4 pt-3 pb-0">
                        <v-tabs v-model="editModal.activeTab" :color="editModal.isFixedAccount ? 'teal-darken-3' : 'success'" density="comfortable" show-arrows>
                            <v-tab value="basic"><v-icon start size="small">mdi-file-document-outline</v-icon> Dados Básicos</v-tab>
                            <v-tab value="financial"><v-icon start size="small">mdi-currency-usd</v-icon> Financeiro</v-tab>
                            <v-tab value="recurrence" v-if="!editModal.form.id"><v-icon start size="small">mdi-refresh</v-icon> Recorrência</v-tab>
                            <v-tab value="classification"><v-icon start size="small">mdi-tag-outline</v-icon> Classificação</v-tab>
                        </v-tabs>
                        <v-btn v-if="!mobile" icon="mdi-close" variant="text" :color="isDark ? 'white' : 'grey-darken-1'" @click="editModal.show = false"></v-btn>
                    </div>
                </div>

                <div class="flex-grow-1 overflow-y-auto custom-scroll pa-4 pa-md-6 absolute-fill" :class="isDark ? 'bg-grey-darken-4' : 'bg-white'" :style="mobile ? 'padding-bottom: 80px;' : 'height: calc(100% - 110px);'">
                    <v-form @submit.prevent="saveReceivable" id="receivableForm">
                        <v-window v-model="editModal.activeTab">
                            <v-window-item value="basic">
                                <div class="text-subtitle-1 font-weight-bold mb-4">Informações Principais</div>
                                <v-row class="row-gap">
                                    <v-col cols="12" md="6">
                                        <v-autocomplete label="Cliente / Pagador*" v-model="editModal.form.entity_name" :items="auxData.customers" item-title="name" item-value="id" variant="outlined" :color="editModal.isFixedAccount ? 'teal' : 'success'" density="comfortable" class="ui-field" :return-object="false">
                                            <template v-slot:prepend-item>
                                                <v-list-item title="Novo Cliente Rápido" prepend-icon="mdi-plus" class="text-success font-weight-black" @click="openQuickAdd('customer')"></v-list-item>
                                                <v-divider class="mt-2"></v-divider>
                                            </template>
                                        </v-autocomplete>
                                    </v-col>

                                    <v-col cols="12" md="6">
                                        <v-autocomplete
                                            label="Empresa (Recebedor)"
                                            v-model="editModal.form.company_id"
                                            :items="auxData.companies"
                                            item-title="trade_name"
                                            item-value="id"
                                            variant="outlined"
                                            :color="editModal.isFixedAccount ? 'teal' : 'success'"
                                            clearable
                                            density="comfortable"
                                            class="ui-field"
                                            :readonly="!companyStore.isGlobalView"
                                            :hint="!companyStore.isGlobalView ? 'Definido automaticamente pelo contexto' : 'Obrigatório na visão Global'"
                                            persistent-hint
                                        ></v-autocomplete>
                                    </v-col>

                                    <v-col cols="12">
                                        <v-text-field label="Descrição*" v-model="editModal.form.description" variant="outlined" density="comfortable" :color="editModal.isFixedAccount ? 'teal' : 'success'" class="ui-field"></v-text-field>
                                    </v-col>
                                </v-row>
                            </v-window-item>

                            <v-window-item value="financial">
                                <div class="text-subtitle-1 font-weight-bold mb-4">Valores e Prazos</div>
                                <v-row class="row-gap">
                                    <v-col cols="12" md="4"><v-text-field label="Valor Bruto (R$)*" v-model.number="editModal.form.value" type="number" step="0.01" variant="outlined" :color="editModal.isFixedAccount ? 'teal' : 'success'" density="comfortable" class="ui-field font-weight-bold"></v-text-field></v-col>
                                    <v-col cols="12" md="4"><v-text-field label="Descontos (R$)" v-model.number="editModal.form.discount" type="number" step="0.01" variant="outlined" color="error" density="comfortable" class="ui-field"></v-text-field></v-col>
                                    <v-col cols="12" md="4"><v-text-field label="Líquido" :model-value="formatCurrency(editModal.form.value - (editModal.form.discount || 0))" readonly variant="filled" density="comfortable" class="ui-field"></v-text-field></v-col>
                                </v-row>
                                <v-row class="row-gap">
                                    <v-col cols="12" md="3"><v-text-field label="Vencimento*" v-model="editModal.form.due_date" type="date" variant="outlined" :color="editModal.isFixedAccount ? 'teal' : 'success'" density="comfortable" class="ui-field"></v-text-field></v-col>
                                    <v-col cols="12" md="3"><v-text-field label="Competência" v-model="editModal.form.competence_date" type="date" variant="outlined" :color="editModal.isFixedAccount ? 'teal' : 'success'" density="comfortable" class="ui-field"></v-text-field></v-col>
                                    <v-col cols="12" md="3"><v-select label="Banco" v-model="editModal.form.bank_account_id" :items="auxData.bankAccounts" item-title="name" item-value="id" variant="outlined" :color="editModal.isFixedAccount ? 'teal' : 'success'" density="comfortable" class="ui-field"></v-select></v-col>
                                    <v-col cols="12" md="3"><v-select label="Forma Pagto" v-model="editModal.form.payment_method_id" :items="auxData.paymentMethods" item-title="name" item-value="id" variant="outlined" density="comfortable" class="ui-field"></v-select></v-col>
                                </v-row>
                                <v-divider class="my-4 border-white-10"></v-divider>
                                <div class="text-caption font-weight-bold text-uppercase mb-2 opacity-70">Status</div>
                                <v-row class="row-gap">
                                    <v-col cols="12" md="6"><v-select label="Status" v-model="editModal.form.status" :items="['em_aberto','pago','atrasado']" variant="outlined" :color="editModal.isFixedAccount ? 'teal' : 'success'" density="comfortable" class="ui-field"></v-select></v-col>
                                    <v-col cols="12" md="6" v-if="editModal.form.status === 'pago'"><v-text-field label="Data Recebimento" v-model="editModal.form.payment_date" type="date" variant="outlined" color="success" density="comfortable" class="ui-field"></v-text-field></v-col>
                                </v-row>
                            </v-window-item>

                             <v-window-item value="recurrence">
                                 <div class="d-flex align-center justify-space-between mb-6">
                                    <div class="text-subtitle-1 font-weight-bold">Projetar Parcelas</div>
                                    <v-switch v-model="editModal.recurrence.enabled" :color="editModal.isFixedAccount ? 'teal' : 'success'" label="Ativar Recorrência" hide-details density="compact" class="font-weight-bold"></v-switch>
                                 </div>
                                 <v-expand-transition>
                                     <div v-if="editModal.recurrence.enabled">
                                         <div class="pa-4 rounded border-thin mb-4" :class="isDark ? 'bg-grey-darken-3' : 'bg-grey-lighten-5'">
                                             <div class="text-body-2 font-weight-bold mb-2">Como o valor deve ser tratado?</div>
                                             <v-radio-group v-model="editModal.recurrence.calcMethod" :color="editModal.isFixedAccount ? 'teal' : 'success'" hide-details class="mb-4">
                                                 <v-radio value="divide"><template v-slot:label><div><strong>Dividir o valor total</strong> (Parcelamento)</div></template></v-radio>
                                                 <v-radio value="repeat" class="mt-2"><template v-slot:label><div><strong>Repetir o valor (Valor Fixo)</strong> (Mensalidade)</div></template></v-radio>
                                             </v-radio-group>
                                             <v-row class="row-gap mt-2 align-center">
                                                 <v-col cols="12" md="4"><v-text-field label="Quantidade (x)" v-model.number="editModal.recurrence.count" type="number" min="2" max="120" variant="outlined" density="comfortable" class="ui-field"></v-text-field></v-col>
                                                 <v-col cols="12" md="4"><v-select label="Intervalo" v-model="editModal.recurrence.interval" :items="[{title:'Mensal', value:'month'}, {title:'Semanal', value:'week'}]" variant="outlined" density="comfortable" class="ui-field"></v-select></v-col>
                                                 <v-col cols="12" md="4"><v-btn block height="42" variant="flat" :color="editModal.isFixedAccount ? 'teal-darken-3' : 'success'" prepend-icon="mdi-calculator" @click="generateInstallments" class="font-weight-bold btn-3d">Gerar / Simular</v-btn></v-col>
                                             </v-row>
                                         </div>
                                         <div v-if="editModal.projected.length > 0">
                                             <div class="text-subtitle-2 font-weight-black mb-2 d-flex justify-space-between align-center"><span>Prévia das Parcelas ({{ editModal.projected.length }})</span><span class="text-caption opacity-70">Edite individualmente se necessário</span></div>
                                             <div class="border-thin rounded overflow-hidden overflow-x-auto">
                                                 <div class="grid-header" :class="isDark ? 'bg-grey-darken-3' : 'bg-grey-lighten-4'" style="display: grid; grid-template-columns: 50px 140px 140px 140px 1fr 50px; min-width: 600px;">
                                                     <div class="cell center header-text">#</div><div class="cell header-text">Vencimento</div><div class="cell header-text">Competência</div><div class="cell header-text">Valor</div><div class="cell header-text">Descrição</div><div class="cell center header-text">X</div>
                                                 </div>
                                                 <div v-for="(p, i) in editModal.projected" :key="i" class="grid-row" :class="isDark ? 'bg-grey-darken-4' : 'bg-white hover-grey'" style="display: grid; grid-template-columns: 50px 140px 140px 140px 1fr 50px; min-width: 600px;">
                                                     <div class="cell center font-weight-bold text-caption">{{ i + 1 }}</div>
                                                     <div class="cell pa-1"><input type="date" v-model="editModal.projected[i].due_date" class="clean-input w-100 border-thin rounded px-1" style="height:32px;"></div>
                                                     <div class="cell pa-1"><input type="date" v-model="editModal.projected[i].competence_date" class="clean-input w-100 border-thin rounded px-1" style="height:32px;"></div>
                                                     <div class="cell pa-1"><input type="number" v-model.number="editModal.projected[i].value" step="0.01" class="clean-input w-100 border-thin rounded px-1 font-weight-bold" style="height:32px;"></div>
                                                     <div class="cell pa-1"><input type="text" v-model="editModal.projected[i].description" class="clean-input w-100 border-thin rounded px-1 text-caption" style="height:32px;"></div>
                                                     <div class="cell center"><v-btn icon variant="text" size="x-small" color="red" @click="editModal.projected.splice(i, 1)"><v-icon>mdi-close</v-icon></v-btn></div>
                                                 </div>
                                             </div>
                                              <div class="d-flex justify-end mt-2"><div class="text-caption font-weight-bold px-3 py-1 rounded" :class="isDark ? 'bg-grey-darken-3' : 'bg-grey-lighten-4'">Soma Total: {{ formatCurrency(editModal.projected.reduce((a,b) => a + Number(b.value), 0)) }}</div></div>
                                         </div>
                                      </div>
                                 </v-expand-transition>
                            </v-window-item>

                            <v-window-item value="classification">
                                <div class="text-subtitle-1 font-weight-bold mb-4">Categorização Contábil</div>
                                <v-row class="row-gap">
                                    <v-col cols="12" md="6"><v-autocomplete label="Plano de Contas" v-model="editModal.form.chart_of_accounts_id" :items="auxData.chartOfAccounts" item-title="name" item-value="id" variant="outlined" :color="editModal.isFixedAccount ? 'teal' : 'success'" clearable density="comfortable" class="ui-field"></v-autocomplete></v-col>
                                    <v-col cols="12" md="6"><v-autocomplete label="Centro de Custo" v-model="editModal.form.cost_center_id" :items="auxData.costCenters" item-title="name" item-value="id" variant="outlined" :color="editModal.isFixedAccount ? 'teal' : 'success'" clearable density="comfortable" class="ui-field"></v-autocomplete></v-col>
                                    <v-col cols="12"><v-textarea label="Observações / Detalhes" v-model="editModal.form.notes" variant="outlined" rows="3" density="comfortable" class="ui-field"></v-textarea></v-col>
                                </v-row>
                                <v-divider class="my-6 border-white-10"></v-divider>
                                <div class="text-subtitle-1 font-weight-bold mb-4">Anexos e Documentos</div>
                                <v-file-input v-model="editModal.files" label="Selecionar Arquivos (PDF, Imagens)" variant="outlined" density="comfortable" prepend-inner-icon="mdi-upload" :color="editModal.isFixedAccount ? 'teal' : 'success'" multiple chips show-size class="ui-field"></v-file-input>
                                <div v-if="editModal.form.attachments && editModal.form.attachments.length > 0" class="mt-3">
                                    <div class="text-caption font-weight-bold mb-2">Arquivos Anexados:</div>
                                    <div class="d-flex flex-wrap" style="gap: 8px;">
                                        <v-chip v-for="(url, idx) in editModal.form.attachments" :key="idx" size="default" prepend-icon="mdi-file-check" color="blue-grey" variant="flat" :href="url" target="_blank" closable @click:close="removeAttachment(idx)">Anexo {{ idx + 1 }}</v-chip>
                                    </div>
                                </div>
                            </v-window-item>
                        </v-window>
                    </v-form>
                </div>

                <div class="pa-4 border-t d-flex justify-end align-center flex-shrink-0" :class="isDark ? 'bg-grey-darken-3' : 'bg-grey-lighten-5'" style="gap: 12px; height: 80px;">
                    <div class="text-caption mr-4 d-none d-sm-block opacity-70" v-if="editModal.loading"><v-progress-circular indeterminate size="20" color="success" class="mr-2"></v-progress-circular>Salvando...</div>
                    <v-btn variant="outlined" class="btn-3d px-8 font-weight-bold text-body-2" height="48" @click="editModal.show = false" :disabled="editModal.loading">Cancelar</v-btn>
                    <v-btn :color="editModal.isFixedAccount ? 'teal-darken-3' : 'success'" variant="flat" class="btn-3d px-8 font-weight-black text-body-1" height="48" type="submit" form="receivableForm" :loading="editModal.loading"><v-icon start>mdi-content-save-check</v-icon> Salvar</v-btn>
                </div>
            </div>
        </v-card>
    </v-dialog>

    <v-dialog v-model="linkOrderModal.show" max-width="450">
        <v-card class="rounded-lg shadow-xl border-thin" :class="isDark ? 'bg-grey-darken-4 text-white' : 'bg-white'">
            <div class="px-5 py-4 border-b d-flex align-center justify-space-between" :class="isDark ? 'bg-indigo-darken-4' : 'bg-indigo-lighten-5'">
                <div class="d-flex align-center gap-2" :class="isDark ? 'text-white' : 'text-indigo-darken-3'">
                    <v-icon size="24">mdi-link-variant</v-icon>
                    <span class="text-h6 font-weight-black">Vincular Pedido</span>
                </div>
                <v-btn icon="mdi-close" variant="text" size="small" @click="linkOrderModal.show = false"></v-btn>
            </div>
            <div class="pa-5">
                <p class="text-caption font-weight-medium mb-4 opacity-80">
                    Defina de onde vem este recebimento para que o sistema consiga rastrear e abrir o modal correto de leitura do pedido.
                </p>
                <div class="mb-4">
                    <label class="input-label">Origem do Pedido</label>
                    <v-btn-toggle v-model="linkOrderModal.type" density="compact" color="indigo" mandatory class="w-100 d-flex" divided variant="outlined" @update:model-value="fetchOrdersToLink">
                        <v-btn value="orders" class="flex-grow-1 text-caption font-weight-bold">Vendas Padrão</v-btn>
                        <v-btn value="store_sales" class="flex-grow-1 text-caption font-weight-bold">Vendas Balcão</v-btn>
                    </v-btn-toggle>
                </div>
                <div>
                    <label class="input-label">Selecione o Pedido</label>
                    <v-autocomplete
                        v-model="linkOrderModal.selectedId"
                        :items="linkOrderModal.options"
                        item-title="label"
                        item-value="id"
                        variant="outlined"
                        density="comfortable"
                        color="indigo"
                        hide-details
                        class="ui-field font-weight-bold"
                        :loading="linkOrderModal.loading"
                        placeholder="Busque pelo número ou cliente..."
                    >
                        <template v-slot:item="{ props, item }">
                            <v-list-item v-bind="props" :subtitle="`R$ ${item.raw.value}`"></v-list-item>
                        </template>
                    </v-autocomplete>
                </div>
            </div>
            <div class="pa-4 border-t d-flex justify-end gap-2" :class="isDark ? 'bg-black-20 border-white-10' : 'bg-grey-lighten-5'">
                <v-btn variant="text" class="font-weight-bold btn-3d" @click="linkOrderModal.show = false">Cancelar</v-btn>
                <v-btn color="indigo" variant="flat" class="font-weight-black btn-3d px-6" :loading="linkOrderModal.saving" @click="confirmLinkOrder" :disabled="!linkOrderModal.selectedId">Vincular</v-btn>
            </div>
        </v-card>
    </v-dialog>

    <v-dialog v-model="statusModal.show" max-width="500">
        <v-card class="rounded-lg shadow-xl overflow-hidden border-thin" :class="isDark ? 'bg-grey-darken-4 text-white' : 'bg-white'">
            <div class="px-6 py-4 d-flex align-center justify-space-between text-white" :class="statusModal.action === 'pay' ? 'bg-success' : 'bg-orange-darken-3'">
                <div class="d-flex align-center gap-3">
                    <v-icon size="28">{{ statusModal.action === 'pay' ? 'mdi-cash-check' : 'mdi-undo' }}</v-icon>
                    <div>
                        <h3 class="text-h6 font-weight-black leading-none mb-1">
                            {{ statusModal.action === 'pay' ? 'Baixar Título' : 'Estornar Título' }}
                        </h3>
                        <div class="text-caption opacity-80">{{ statusModal.item?.description }}</div>
                    </div>
                </div>
                <v-btn icon="mdi-close" variant="text" color="white" @click="statusModal.show = false"></v-btn>
            </div>

            <div class="pa-6" v-if="statusModal.action === 'pay'">
                <div class="bg-green-lighten-5 rounded-lg pa-4 mb-6 border border-green-lighten-3 text-center">
                    <div class="text-caption font-weight-bold text-green-darken-4 text-uppercase mb-1">Valor Total Pendente</div>
                    <div class="text-h4 font-weight-black text-green-darken-3">{{ formatCurrency(originalModalTotal) }}</div>
                </div>

                <v-row dense class="row-gap">
                    <v-col cols="12" md="6">
                        <v-text-field label="Data da Baixa" type="date" v-model="statusModal.payment_date" variant="outlined" density="comfortable" color="success" hide-details class="ui-field"></v-text-field>
                    </v-col>
                    <v-col cols="12" md="6">
                        <v-text-field label="Valor Recebido" type="number" step="0.01" v-model.number="statusModal.payment_value" variant="outlined" density="comfortable" color="success" hide-details class="ui-field font-weight-bold" prefix="R$"></v-text-field>
                    </v-col>

                    <v-col cols="12" v-if="isPartialPayment">
                        <v-alert type="warning" variant="tonal" density="compact" class="text-caption font-weight-bold mt-2 border-warning">
                            Você está realizando uma baixa parcial. Uma nova parcela será gerada no valor de <strong>{{ formatCurrency(remainingModalBalance) }}</strong> com a mesma data de vencimento.
                        </v-alert>
                    </v-col>

                    <v-col cols="12" md="6">
                        <v-select label="Conta Destino" v-model="statusModal.bank_account_id" :items="filteredBankAccountsForBaixa" item-title="name" item-value="id" variant="outlined" density="comfortable" color="success" hide-details class="ui-field"></v-select>
                    </v-col>
                    <v-col cols="12" md="6">
                        <v-select label="Forma de Pagamento" v-model="statusModal.payment_method_id" :items="auxData.paymentMethods" item-title="name" item-value="id" variant="outlined" density="comfortable" color="success" hide-details class="ui-field"></v-select>
                    </v-col>

                    <v-col cols="12">
                        <v-textarea label="Observação da Baixa" v-model="statusModal.notes" variant="outlined" density="comfortable" color="success" hide-details class="ui-field" rows="2"></v-textarea>
                    </v-col>
                    <v-col cols="12">
                        <v-file-input v-model="statusModal.files" label="Anexar Comprovante (opcional)" variant="outlined" density="comfortable" prepend-inner-icon="mdi-paperclip" color="success" multiple chips show-size class="ui-field" hide-details></v-file-input>
                    </v-col>
                </v-row>
            </div>

            <div class="pa-6 text-center" v-else>
                <v-icon size="64" color="orange-darken-3" class="mb-4">mdi-alert-circle-outline</v-icon>
                <h3 class="text-h6 font-weight-bold mb-2">Confirma o estorno?</h3>
                <p class="text-body-2 mb-4" :class="isDark ? 'text-grey-lighten-1' : 'text-grey-darken-2'">
                    O título voltará para o status "Em Aberto" e será removido do saldo do caixa atual. O sistema unificará automaticamente parcelas filhas criadas por pagamentos parciais vinculados a este lançamento.
                </p>
            </div>

            <div class="px-6 py-4 border-t d-flex justify-end gap-3" :class="isDark ? 'bg-grey-darken-3' : 'bg-grey-lighten-5'">
                <v-btn variant="outlined" class="btn-3d" height="42" @click="statusModal.show = false" :disabled="statusModal.loading">Cancelar</v-btn>
                <v-btn
                    :color="statusModal.action === 'pay' ? 'success' : 'orange-darken-3'"
                    variant="flat"
                    class="btn-3d px-6 font-weight-black text-white"
                    height="42"
                    :loading="statusModal.loading"
                    @click="confirmStatusAction"
                >
                    {{ statusModal.action === 'pay' ? 'Confirmar Baixa' : 'Confirmar Estorno' }}
                </v-btn>
            </div>
        </v-card>
    </v-dialog>

    <v-dialog v-model="groupModal.show" max-width="900" persistent>
        <v-card class="rounded-lg shadow-xl overflow-hidden border-thin" :class="isDark ? 'bg-grey-darken-4 text-white' : 'bg-white'">
            <div class="px-6 py-4 border-b d-flex align-center justify-space-between bg-blue-darken-3 text-white">
                <div class="d-flex align-center gap-3">
                    <v-icon size="28">mdi-table-merge-cells</v-icon>
                    <div>
                        <h3 class="text-h6 font-weight-black leading-none mb-1">Agrupar Lançamentos</h3>
                        <div class="text-caption opacity-80">Mesclar {{ groupModal.items.length }} selecionados em novas parcelas</div>
                    </div>
                </div>
                <v-btn icon="mdi-close" variant="text" color="white" @click="groupModal.show = false"></v-btn>
            </div>

            <div class="pa-6">
                <div class="bg-blue-lighten-5 rounded-lg pa-4 mb-6 border border-blue-lighten-3 text-center">
                    <div class="text-caption font-weight-bold text-blue-darken-4 text-uppercase mb-1">Soma Total dos Itens Selecionados</div>
                    <div class="text-h4 font-weight-black text-blue-darken-3">{{ formatCurrency(groupModal.totalValue) }}</div>
                </div>

                <v-row class="row-gap mb-6">
                    <v-col cols="12" md="6">
                        <v-text-field label="Nova Descrição (Agrupada)" v-model="groupModal.form.description" variant="outlined" density="comfortable" color="blue" hide-details class="ui-field"></v-text-field>
                    </v-col>
                    <v-col cols="12" md="6">
                        <v-autocomplete label="Plano de Contas" v-model="groupModal.form.chart_of_accounts_id" :items="auxData.chartOfAccounts" item-title="name" item-value="id" variant="outlined" color="blue" density="comfortable" hide-details class="ui-field"></v-autocomplete>
                    </v-col>
                    <v-col cols="12">
                        <v-textarea label="Observações de Rastreio" v-model="groupModal.form.notes" variant="outlined" density="comfortable" color="blue" hide-details rows="2" class="ui-field text-caption"></v-textarea>
                    </v-col>
                </v-row>

                <div class="d-flex align-center justify-space-between mb-3">
                    <h4 class="text-subtitle-1 font-weight-bold">Novas Parcelas Projetadas</h4>
                    <v-btn size="small" color="blue" variant="tonal" prepend-icon="mdi-plus" @click="addGroupProjection" class="font-weight-bold btn-3d">Adicionar Parcela</v-btn>
                </div>

                <div class="border-thin rounded overflow-hidden">
                    <div class="grid-header" :class="isDark ? 'bg-grey-darken-3' : 'bg-grey-lighten-4'" style="display: grid; grid-template-columns: 50px 160px 1fr 50px;">
                        <div class="cell center header-text">#</div><div class="cell header-text">Vencimento</div><div class="cell header-text">Valor da Parcela</div><div class="cell center header-text">X</div>
                    </div>
                    <div v-for="(p, i) in groupModal.projected" :key="i" class="grid-row" :class="isDark ? 'bg-grey-darken-4' : 'bg-white'" style="display: grid; grid-template-columns: 50px 160px 1fr 50px;">
                        <div class="cell center font-weight-bold text-caption">{{ i + 1 }}</div>
                        <div class="cell pa-1"><input type="date" v-model="groupModal.projected[i].due_date" class="clean-input w-100 border-thin rounded px-2" style="height:36px;"></div>
                        <div class="cell pa-1"><input type="number" v-model.number="groupModal.projected[i].value" step="0.01" class="clean-input w-100 border-thin rounded px-2 font-weight-bold text-blue-darken-3" style="height:36px;"></div>
                        <div class="cell center"><v-btn icon variant="text" size="small" color="red" @click="groupModal.projected.splice(i, 1)"><v-icon>mdi-close</v-icon></v-btn></div>
                    </div>
                </div>

                <div class="d-flex justify-space-between align-center mt-4 pa-3 rounded" :class="Math.abs(groupProjDiff) > 0.01 ? 'bg-red-lighten-5 border border-red-lighten-3' : 'bg-green-lighten-5 border border-green-lighten-3'">
                    <span class="text-caption font-weight-bold" :class="Math.abs(groupProjDiff) > 0.01 ? 'text-red-darken-2' : 'text-green-darken-2'">
                        {{ Math.abs(groupProjDiff) > 0.01 ? 'Diferença detectada. Ajuste as parcelas.' : 'Soma de parcelas validada com sucesso.' }}
                    </span>
                    <div class="text-subtitle-2 font-weight-black">
                        Total Distribuído: R$ {{ formatCurrencyValue(groupProjTotal) }}
                        <span v-if="Math.abs(groupProjDiff) > 0.01" class="text-red-darken-2 ml-2">(Falta: R$ {{ formatCurrencyValue(groupProjDiff) }})</span>
                    </div>
                </div>
            </div>

            <div class="px-6 py-4 border-t d-flex justify-end gap-3" :class="isDark ? 'bg-grey-darken-3' : 'bg-grey-lighten-5'">
                <v-btn variant="outlined" class="btn-3d" height="42" @click="groupModal.show = false" :disabled="groupModal.loading">Cancelar</v-btn>
                <v-btn color="blue-darken-2" variant="flat" class="btn-3d px-6 font-weight-black text-white" height="42" :loading="groupModal.loading" @click="confirmGroupAction">Confirmar Agrupamento</v-btn>
            </div>
        </v-card>
    </v-dialog>

    <v-dialog v-model="bulkCompanyModal.show" max-width="520" scrim="black opacity-70">
      <v-card class="rounded-0 overflow-hidden">
        <div class="px-6 py-4 border-b bg-grey-lighten-5 d-flex align-center justify-space-between">
          <div><div class="text-caption font-weight-black opacity-70 text-uppercase">Ação em massa</div><div class="text-h6 font-weight-black">Definir Empresa</div></div>
          <v-btn icon variant="text" @click="bulkCompanyModal.show = false"><v-icon>mdi-close</v-icon></v-btn>
        </div>
        <div class="pa-6">
          <p class="text-body-2 text-grey-darken-1 mb-4">Selecione a empresa para atribuir aos <strong>{{ selectedIds.size }}</strong> itens selecionados.</p>
          <v-autocomplete v-model="bulkCompanyModal.companyId" :items="auxData.companies" item-title="trade_name" item-value="id" label="Selecione a Empresa" variant="outlined" density="compact" color="success" class="ui-field"></v-autocomplete>
        </div>
        <div class="px-6 py-4 border-t bg-grey-lighten-5 d-flex justify-end" style="gap: 10px;">
          <v-btn variant="outlined" class="btn-3d" height="40" @click="bulkCompanyModal.show = false">Cancelar</v-btn>
          <v-btn color="success" variant="flat" class="btn-3d px-6 font-weight-black" height="40" :loading="bulkCompanyModal.loading" @click="executeBulkCompanyAssign">Salvar</v-btn>
        </div>
      </v-card>
    </v-dialog>

  <SyncReceivableModal v-model="syncModalOpen" @synced="fetchReceivables" />
    <UniversalImportModal :show="showImportModal" :system-fields="importFields" @update:show="showImportModal = $event" @import="handleImportData" />

    <AdminOrderEditModal v-if="showOrderDetailModal" :show="showOrderDetailModal" :order-id="selectedOrderIdForDetail" @close="showOrderDetailModal = false" />

    <BillingModal v-if="showBillingModal" v-model:show="showBillingModal" :order="selectedOrderForBilling" @close="showBillingModal = false" @refresh="fetchReceivables" />
    <MjCashOpeningModal v-model="showCashOpeningModal" @session-opened="handleSessionOpened" />
    <AdminOrderEditModal
        v-if="showOrderDetailModal"
        :key="selectedOrderIdForDetail"
        :show="showOrderDetailModal"
        :order-id="selectedOrderIdForDetail"
        @close="showOrderDetailModal = false"
    />

</div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, reactive, watch } from 'vue';
import { supabase } from '@/api/supabase';
import { format, parseISO, startOfMonth, endOfMonth, startOfWeek, endOfWeek, addMonths, addDays, startOfYear, endOfYear } from 'date-fns';
import { ptBR } from 'date-fns/locale';
import { useAppStore } from '@/stores/app';
import { useUserStore } from '@/stores/user';
import { useThemeStore } from '@/stores/theme';
import { useCompanyStore } from '@/stores/company';
import { useDisplay, useTheme } from 'vuetify';
import { useMjCashSessionStore } from '@/stores/mjCashSession';
import MjCashOpeningModal from '@/components/sales/MjCashOpeningModal.vue';
import UniversalImportModal from '@/components/admin/UniversalImportModal.vue';
import SyncReceivableModal from '@/components/admin/SyncReceivableModal.vue';
import AdminOrderEditModal from '@/components/admin/AdminOrderEditModal.vue';
import BillingModal from '@/components/admin/BillingModal.vue';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import * as XLSX from 'xlsx';
import QRCode from 'qrcode';

import logoImage from '@/assets/logo.png';
import logoCajuia from '@/assets/logocajuia.png';
import logoMj from '@/assets/logomjlm.png';
import { useAuditLogger } from '@/composables/useAuditLogger';

const { mobile } = useDisplay();
const appStore = useAppStore();
const themeStore = useThemeStore();
const companyStore = useCompanyStore();
const userStore = useUserStore();
const theme = useTheme();
const { logBusinessEvent } = useAuditLogger();

// CORREÇÃO DO MODO ESCURO
const isDark = computed(() => themeStore.currentMode !== 'light');

const loading = ref(false);
const allFetchedItems = ref<any[]>([]);
const totalItems = ref(0);
const page = ref(1);
const itemsPerPage = 30;
const showLogs = ref(false);
const syncModalOpen = ref(false);
const showImportModal = ref(false);
const selectedIds = ref(new Set<string>());
const filtersDropdownOpen = ref(false);
const mobileFiltersOpen = ref(false);
const reportLoading = ref(false);
const isMobileFullscreen = ref(false);
const kpiModel = ref(0);
const printLoadingId = ref<string | null>(null);

const mjCashStore = useMjCashSessionStore();
// Billing Modal Controls
const showBillingModal = ref(false);
const selectedOrderForBilling = ref<any>(null);

const showCashOpeningModal = ref(false);
const pendingCashAction = ref<(() => void) | null>(null);

const handleSessionOpened = () => {
    showCashOpeningModal.value = false;
    if (pendingCashAction.value) {
        pendingCashAction.value();
        pendingCashAction.value = null;
    }
};

const gridSettings = reactive({
    showModal: false,
    loading: false,
    textSize: 'medium' as 'small' | 'medium' | 'large',
    columns: [
        { key: 'ref', label: 'Pedido', visible: true, width: '80px', globalOnly: false },
        { key: 'client', label: 'Cliente / Pagador', visible: true, width: 'minmax(100px, 1.5fr)', globalOnly: false },
        { key: 'desc', label: 'Descrição', visible: true, width: 'minmax(120px, 2fr)', globalOnly: false },
        { key: 'cat', label: 'Plano de Contas', visible: true, width: 'minmax(80px, 1fr)', globalOnly: false },
        { key: 'company', label: 'Empresa', visible: true, width: 'minmax(80px, 1fr)', globalOnly: true },
        { key: 'date', label: 'Vencimento', visible: true, width: 'minmax(70px, 0.8fr)', globalOnly: false },
        { key: 'date2', label: 'Recebimento', visible: true, width: 'minmax(70px, 0.8fr)', globalOnly: false },
        { key: 'val', label: 'Valor', visible: true, width: 'minmax(75px, 1fr)', globalOnly: false },
        { key: 'conciliated', label: 'Conciliação', visible: true, width: 'minmax(80px, 0.8fr)', globalOnly: false },
        { key: 'status', label: 'Status', visible: true, width: 'minmax(120px, 1fr)', globalOnly: false },
        { key: 'ext', label: 'Conta Bancária', visible: false, width: 'minmax(80px, 1fr)', globalOnly: false },
        { key: 'ext-lg', label: 'Observações', visible: false, width: 'minmax(100px, 1.5fr)', globalOnly: false }
    ]
});

// Geração dinâmica dos botões de contexto para ficar padronizado (Holding sendo o terceiro botão)
const contextButtons = computed(() => {
    const btns = [];
    const comps = auxData.companies || [];

    if (comps.length > 0) btns.push({ id: comps[0].id, name: comps[0].trade_name, isHolding: false });
    if (comps.length > 1) btns.push({ id: comps[1].id, name: comps[1].trade_name, isHolding: false });

    btns.push({ id: 'global', name: 'HOLDING / GLOBAL', isHolding: true });

    for (let i = 2; i < comps.length; i++) {
        btns.push({ id: comps[i].id, name: comps[i].trade_name, isHolding: false });
    }
    return btns;
});

const isColumnVisible = (key: string) => {
    const col = gridSettings.columns.find(c => c.key === key);
    if (!col) return false;
    if (col.globalOnly && !companyStore.isGlobalView) return false;
    return col.visible;
};

const computedGridTemplate = computed(() => {
    let template = '45px ';
    gridSettings.columns.forEach(col => {
        if (isColumnVisible(col.key)) template += col.width + ' ';
    });
    template += '160px';
    return template;
});

const loadGridSettings = async () => {
    if (!userStore.user?.id) return;
    try {
        const { data, error } = await supabase
            .from('user_preferences')
            .select('settings')
            .eq('user_id', userStore.user.id)
            .maybeSingle();

        if (error) return;

        if (data && data.settings && data.settings.receivables_grid) {
            const prefs = data.settings.receivables_grid;
            if (prefs.textSize) gridSettings.textSize = prefs.textSize;
            if (prefs.columns) {
                prefs.columns.forEach((savedCol: any) => {
                    const target = gridSettings.columns.find(c => c.key === savedCol.key);
                    if (target) target.visible = savedCol.visible;
                });
            }
        }
    } catch (e) {
        console.warn('Configurações de grid ainda não salvas, usando padrão.');
    }
};

const saveGridSettings = async () => {
    if (!userStore.user?.id) return;
    gridSettings.loading = true;
    try {
        const { data: currentPrefs } = await supabase
            .from('user_preferences')
            .select('settings')
            .eq('user_id', userStore.user.id)
            .maybeSingle();

        const currentSettings = currentPrefs?.settings || {};

        currentSettings.receivables_grid = {
            textSize: gridSettings.textSize,
            columns: gridSettings.columns.map(c => ({ key: c.key, visible: c.visible }))
        };

        const payload = {
            user_id: userStore.user.id,
            settings: currentSettings
        };

        const { error } = await supabase.from('user_preferences').upsert(payload, { onConflict: 'user_id' });

        if (error) throw error;
        await logBusinessEvent('Financeiro - Receber', 'UPDATE', 'Salvou preferências de visualização da grid.', payload, null);
        appStore.showSnackbar('Configurações da grid salvas!', 'success');
        gridSettings.showModal = false;
    } catch (e: any) {
        appStore.showSnackbar('Erro ao salvar grid: ' + e.message, 'error');
    } finally {
        gridSettings.loading = false;
    }
};

// --- STATUS MODAL MODIFICADO ---
const statusModal = reactive({
    show: false,
    loading: false,
    item: null as any,
    action: 'pay' as 'pay' | 'revert',
    payment_date: format(new Date(), 'yyyy-MM-dd'),
    bank_account_id: null as any,
    payment_method_id: null as any,
    payment_value: 0,
    notes: '',
    files: [] as File[],
});

// Computed para garantir que apenas contas bancárias compatíveis sejam listadas no momento da baixa
const filteredBankAccountsForBaixa = computed(() => {
    if (!statusModal.item || !statusModal.item.company_id) return auxData.bankAccounts;
    return auxData.bankAccounts.filter(b => b.company_id === statusModal.item.company_id || !b.company_id);
});

const originalModalTotal = computed(() => {
    if (!statusModal.item) return 0;
    return Number(statusModal.item.value) - Number(statusModal.item.discount || 0);
});

const isPartialPayment = computed(() => {
    if (statusModal.action === 'revert') return false;
    const val = Number(statusModal.payment_value);
    return val > 0 && val < originalModalTotal.value;
});

const remainingModalBalance = computed(() => {
    return originalModalTotal.value - Number(statusModal.payment_value);
});

const openStatusModal = async (item: any) => {
    if (item.is_signal) {
        appStore.showSnackbar('Sinais não podem ser manipulados por aqui (apenas leitura).', 'warning');
        return;
    }

    if (item.status !== 'pago' && (item.order_id || (item.order_number && item.order_number !== 'S/N'))) {
        const orderStoreId = item.orders?.store_id;

        if (orderStoreId && userStore.activeStoreId !== orderStoreId) {
            const storeName = item.orders?.stores?.name || 'Loja do Pedido';
            userStore.setAdminStore({ id: orderStoreId, name: storeName });
            await mjCashStore.checkActiveSession();
        }

        if (!mjCashStore.isSessionOpen) {
            appStore.showSnackbar('Abra o caixa desta unidade para registrar a baixa do pedido.', 'warning');
            pendingCashAction.value = () => openStatusModal(item);
            showCashOpeningModal.value = true;
            return;
        }
    }

    statusModal.item = JSON.parse(JSON.stringify(item));
    statusModal.action = item.status === 'pago' ? 'revert' : 'pay';
    statusModal.payment_date = format(new Date(), 'yyyy-MM-dd');
    statusModal.bank_account_id = item.bank_account_id || null;
    statusModal.payment_method_id = item.payment_method_id || null;
    statusModal.payment_value = originalModalTotal.value;
    statusModal.notes = item.notes || '';
    statusModal.files = [];

    statusModal.show = true;
};

const uploadStatusAttachments = async (): Promise<string[]> => {
    if (statusModal.files.length === 0) return [];
    const uploadedUrls: string[] = [];
    for (const file of statusModal.files) {
        const fileExt = file.name.split('.').pop();
        const fileName = `status_${Date.now()}-${Math.random().toString(36).substring(7)}.${fileExt}`;
        const filePath = `receivables/${fileName}`;
        const { error } = await supabase.storage.from('finance-attachments').upload(filePath, file);
        if (!error) {
             const { data } = supabase.storage.from('finance-attachments').getPublicUrl(filePath);
             if (data?.publicUrl) uploadedUrls.push(data.publicUrl);
        }
    }
    return uploadedUrls;
};

// --- CONFIRM STATUS ACTION MODIFICADO (ESTORNO UNIFICADO E DATA FIXA) ---
const confirmStatusAction = async () => {
    if (!statusModal.item) return;
    statusModal.loading = true;
    try {
        if (statusModal.action === 'revert') {
            // LÓGICA DE ESTORNO UNIFICADO
            // 1. Verificar se existe uma parcela filha gerada pelo pagamento parcial
            const { data: childSplits } = await supabase
                .from('finance_receivables')
                .select('*')
                .like('notes', `%[SPLIT_FROM:${statusModal.item.id}]%`);

            let newTotal = Number(statusModal.item.value);
            let hasChild = false;

            if (childSplits && childSplits.length > 0) {
                // Pegar a parcela filha, somar o valor dela e depois excluí-la
                const child = childSplits[0];
                newTotal += Number(child.value);
                await supabase.from('finance_receivables').delete().eq('id', child.id);
                hasChild = true;
            }

            // 2. Atualiza o lançamento atual (que foi estornado) unindo o valor
            const payload = {
                status: 'em_aberto',
                payment_date: null,
                value: newTotal // Volta ao valor total
            };

            const { error } = await supabase.from('finance_receivables').update(payload).eq('id', statusModal.item.id);
            if (error) throw error;

            await logBusinessEvent('Financeiro - Receber', 'STATUS_CHANGE', `Estornou o recebimento de ${statusModal.item.entity_name || 'Cliente'}`, { action: 'revert', had_child: hasChild }, statusModal.item.id, statusModal.item);

            appStore.showSnackbar('Estorno realizado' + (hasChild ? ' e parcela unificada' : '') + ' com sucesso!', 'success');

        } else if (statusModal.action === 'pay') {
            // Removida a obrigatoriedade da conta bancária
            if (Number(statusModal.payment_value) <= 0) throw new Error('O valor recebido deve ser maior que zero.');

            const newUrls = await uploadStatusAttachments();
            const existingAttachments = statusModal.item.attachments || [];
            const finalAttachments = [...existingAttachments, ...newUrls];

            if (isPartialPayment.value) {
                const {
                    id, chart_of_accounts, orders, customer,
                    order_number, is_signal, numeric_value,
                    _mainDateStr, _monthKey, _monthDisplay,
                    ...basePayload
                } = statusModal.item;

                // Atualiza a parcela atual como paga, mudando o valor dela para o valor recebido
                const paidPayload = {
                    status: 'pago',
                    payment_date: statusModal.payment_date,
                    bank_account_id: statusModal.bank_account_id || null,
                    payment_method_id: statusModal.payment_method_id || null,
                    value: statusModal.payment_value,
                    discount: 0,
                    notes: statusModal.notes || 'Baixa parcial',
                    attachments: finalAttachments
                };

                const { error: updErr } = await supabase.from('finance_receivables').update(paidPayload).eq('id', statusModal.item.id);
                if (updErr) throw updErr;

                // Gera a nova parcela rigidamente presa a data original
                const newInstPayload = {
                    ...basePayload,
                    value: remainingModalBalance.value,
                    discount: 0,
                    status: 'em_aberto',
                    payment_date: null,
                    due_date: statusModal.item.due_date, // TRAVADO NA DATA ORIGINAL
                    competence_date: statusModal.item.competence_date, // TRAVADO NA DATA ORIGINAL
                    description: `${statusModal.item.description} (Saldo Remanescente)`,
                    notes: `[SPLIT_FROM:${statusModal.item.id}] Gerado a partir do pagamento parcial`, // TAG DE RASTREIO
                    attachments: existingAttachments
                };

                const { error: insErr } = await supabase.from('finance_receivables').insert(newInstPayload);
                if (insErr) throw insErr;

                await logBusinessEvent('Financeiro - Receber', 'STATUS_CHANGE', `Realizou baixa parcial de R$ ${statusModal.payment_value} no recebimento de ${statusModal.item.entity_name || 'Cliente'} e desmembrou saldo.`, paidPayload, statusModal.item.id, statusModal.item);

                appStore.showSnackbar('Baixa parcial e desmembramento concluídos com sucesso!', 'success');

            } else {
                const payload = {
                    status: 'pago',
                    payment_date: statusModal.payment_date,
                    bank_account_id: statusModal.bank_account_id || null,
                    payment_method_id: statusModal.payment_method_id || null,
                    value: statusModal.payment_value,
                    notes: statusModal.notes,
                    attachments: finalAttachments
                };
                const { error } = await supabase.from('finance_receivables').update(payload).eq('id', statusModal.item.id);
                if (error) throw error;

                await logBusinessEvent('Financeiro - Receber', 'STATUS_CHANGE', `Baixou (recebeu integralmente) o título de ${statusModal.item.entity_name || 'Cliente'}`, payload, statusModal.item.id, statusModal.item);

                appStore.showSnackbar('Título baixado com sucesso!', 'success');
            }
        }

        statusModal.show = false;
        fetchReceivables();
    } catch (e: any) {
        appStore.showSnackbar('Erro: ' + e.message, 'error');
    } finally {
        statusModal.loading = false;
    }
};

const parseAttachments = (attachments: any) => {
    if (!attachments) return [];
    if (Array.isArray(attachments)) return attachments;
    if (typeof attachments === 'string') {
        try {
            const parsed = JSON.parse(attachments);
            return Array.isArray(parsed) ? parsed : [parsed];
        } catch {
            return [attachments];
        }
    }
    return [];
};

const feedback = reactive({
    show: false,
    error: false,
    message: '',
    log: '',
    idsFound: 0
});

const logsData = reactive({ erpCount: 0, internalCount: 0, signalsCount: 0, sumValue: 0 });

const filters = reactive({
  search: '',
  customerId: null as any,
  chartOfAccountsId: null as any,
  descriptionSearch: '',
  status: [] as string[],
  customStart: format(startOfMonth(new Date()), 'yyyy-MM-dd'),
  customEnd: format(endOfMonth(new Date()), 'yyyy-MM-dd'),
  dateType: 'due_date' as 'due_date' | 'payment_date',
  salespersonId: null as any,
  minValue: null as number | null,
  maxValue: null as number | null,
  onlyConciliated: false
});

const setCompanyFilter = (id: string | null) => {
    companyStore.setContext(id || 'global');
};

const toggleConciliatedFilter = () => {
    filters.onlyConciliated = !filters.onlyConciliated;
    page.value = 1;
    fetchReceivables();
};

const importFields = [
  { key: 'description', label: 'Descrição', required: true },
  { key: 'value', label: 'Valor', type: 'number', required: true },
  { key: 'due_date', label: 'Data Vencimento', type: 'date', required: true },
  { key: 'competence_date', label: 'Data Competência', type: 'date' },
  { key: 'entity_name', label: 'Cliente/Pagador', required: true },
  { key: 'status', label: 'Status (em_aberto, pago)' }
];

const handleImportData = async (rows: any[]) => {
    loading.value = true;
    try {
        const payload = rows.map(r => ({
            ...r,
            company_id: companyStore.context || null,
            discount: 0,
            chart_of_accounts_id: null
        }));

        const { error } = await supabase.from('finance_receivables').insert(payload);
        if(error) throw error;

        await logBusinessEvent('Financeiro - Receber', 'IMPORT', `Importou ${payload.length} recebimentos via Excel.`, { count: payload.length }, null);

        appStore.showSnackbar(`${rows.length} registros importados!`, 'success');
        showImportModal.value = false;
        fetchReceivables();
    } catch(e:any) {
        appStore.showSnackbar('Erro na importação: ' + e.message, 'error');
    } finally {
        loading.value = false;
    }
};

const quickPeriodLabel = computed(() => 'Período Personalizado');

const quickPeriodOptions = [
    { label: 'Hoje', value: 'today' },
    { label: 'Esta Semana', value: 'week' },
    { label: 'Este Mês', value: 'month' },
    { label: 'Este Ano', value: 'year' },
];

const activeFilterCount = computed(() => {
  let c = 0;
  if (filters.search) c++;
  if (filters.customerId) c++;
  if (filters.chartOfAccountsId) c++;
  if (filters.descriptionSearch) c++;
  if (filters.status.length > 0) c++;
  if (filters.salespersonId) c++;
  if (filters.minValue || filters.maxValue) c++;
  if (filters.onlyConciliated) c++;
  return c;
});

const auxData = reactive({
  customers: [] as any[],
  bankAccounts: [] as any[],
  paymentMethods: [] as any[],
  chartOfAccounts: [] as any[],
  costCenters: [] as any[],
  companies: [] as any[],
  salespeople: [] as any[]
});

// --- ESTADO DO MODAL INTELIGENTE DE PEDIDO ---
const selectedOrderIdForDetail = ref<string>('');
const showOrderDetailModal = ref(false);

const openOrderDetail = (item: any) => {
    console.log('================================================');
    console.log('🛑 [DEBUG CLICK] Função openOrderDetail disparada!');

    // Fazemos o stringify para quebrar a reatividade do Vue/Proxy e ver o objeto CRU que veio do banco
    console.log('📦 Item RAW clicado:', JSON.parse(JSON.stringify(item)));

    // 1. Avalia a origem
    const type = item.source_type || (item.store_sale_id ? 'store_sales' : 'orders');
    console.log('🔍 Tipo identificado (source_type ou fallback):', type);

    // 2. Extrai o ID
    const id = type === 'store_sales' ? item.store_sale_id : item.order_id;
    console.log(`🔑 Tentando extrair ID usando a coluna [${type === 'store_sales' ? 'store_sale_id' : 'order_id'}]. Resultado:`, id);

    // 3. Validações críticas
    if (!id) {
        console.error('❌ ERRO: O ID extraído é FALSE, NULL, ou VAZIO.', { id });
        appStore.showSnackbar('ID do pedido inválido ou não vinculado.', 'warning');
        return;
    }

    if (id === 'undefined' || id === 'null') {
        console.error('❌ ERRO: O ID extraído é uma STRING literal de nulo/undefined!', { id });
        appStore.showSnackbar('ID do pedido com erro de formatação.', 'warning');
        return;
    }

    // 4. Aciona o modal
    console.log('✅ ID válido confirmado! Injetando no estado do modal...');
    selectedOrderIdForDetail.value = String(id);
    showOrderDetailModal.value = true;

    console.log('🚀 Estados pós-mutação:');
    console.log('   -> selectedOrderIdForDetail:', selectedOrderIdForDetail.value);
    console.log('   -> showOrderDetailModal:', showOrderDetailModal.value);
    console.log('================================================');
};

// --- LINK ORDER MODAL (NOVO) ---
const linkOrderModal = reactive({
    show: false,
    loading: false,
    saving: false,
    item: null as any,
    type: 'orders' as 'orders' | 'store_sales',
    selectedId: null as string | null,
    options: [] as any[]
});

const openLinkOrderModal = (item: any) => {
    linkOrderModal.item = item;
    linkOrderModal.type = item.source_type || (item.store_sale_id ? 'store_sales' : 'orders');
    linkOrderModal.selectedId = item.source_type === 'store_sales' ? item.store_sale_id : item.order_id;
    linkOrderModal.options = [];
    linkOrderModal.show = true;
    fetchOrdersToLink();
};

const fetchOrdersToLink = async () => {
    linkOrderModal.loading = true;
    try {
        if (linkOrderModal.type === 'orders') {
            const { data } = await supabase.from('orders').select('id, order_number, customer_name, total_value').order('order_number', { ascending: false }).limit(200);
            linkOrderModal.options = (data || []).map(o => ({ id: o.id, label: `#${o.order_number} - ${o.customer_name || 'S/N'} (R$ ${o.total_value})`, order_number: o.order_number }));
        } else {
            const { data } = await supabase.from('store_sales').select('id, order_number, customer_name, total_value').order('order_number', { ascending: false }).limit(200);
            linkOrderModal.options = (data || []).map(o => ({ id: o.id, label: `#${o.order_number} - ${o.customer_name || 'Balcão'} (R$ ${o.total_value})`, order_number: o.order_number }));
        }
    } catch(e) { } finally { linkOrderModal.loading = false; }
};

const confirmLinkOrder = async () => {
    if (!linkOrderModal.selectedId) return;
    linkOrderModal.saving = true;
    try {
        const selectedOpt = linkOrderModal.options.find(o => o.id === linkOrderModal.selectedId);
        const payload: any = {
            source_type: linkOrderModal.type,
            order_number: selectedOpt?.order_number
        };

        if (linkOrderModal.type === 'orders') {
            payload.order_id = linkOrderModal.selectedId;
            payload.store_sale_id = null;
        } else {
            payload.store_sale_id = linkOrderModal.selectedId;
            payload.order_id = null;
        }

        await supabase.from('finance_receivables').update(payload).eq('id', linkOrderModal.item.id);

        await logBusinessEvent('Financeiro - Receber', 'LINK', `Vinculou recebimento ao pedido #${payload.order_number}`, payload, linkOrderModal.item.id);

        appStore.showSnackbar('Vínculo atualizado com sucesso!', 'success');
        linkOrderModal.show = false;
        fetchReceivables();
    } catch(e) {
        appStore.showSnackbar('Erro ao vincular pedido.', 'error');
    } finally {
        linkOrderModal.saving = false;
    }
};

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
    fetchReceivables();
};

const applyFiltersFromDropdown = () => {
    filtersDropdownOpen.value = false;
    page.value = 1;
    fetchReceivables();
};

const handleSearchEnter = () => {
    page.value = 1;
    fetchReceivables();
}

const clearFilters = () => {
    filters.search = '';
    filters.customerId = null;
    filters.chartOfAccountsId = null;
    filters.descriptionSearch = '';
    filters.status = [];
    filters.salespersonId = null;
    filters.minValue = null;
    filters.maxValue = null;
    filters.onlyConciliated = false;
    applyPreset('month');
};

const kpiTotals = reactive({ value: 0, paid: 0, openFuture: 0, expiresToday: 0, overdue: 0 });
const kpiList = computed(() => ([
  { label: 'A Receber', value: kpiTotals.openFuture, footer: 'Em dia', icon: 'mdi-cash-plus', gradient: 'bg-gradient-info', active: false },
  { label: 'Vencem Hoje', value: kpiTotals.expiresToday, footer: 'Atenção', icon: 'mdi-alarm-light-outline', gradient: 'bg-gradient-warning', active: false },
  { label: 'Vencidos', value: kpiTotals.overdue, footer: 'Atrasado', icon: 'mdi-alert-circle', gradient: 'bg-gradient-red', active: false },
  { label: 'Recebido', value: kpiTotals.paid, footer: 'Caixa', icon: 'mdi-check-all', gradient: 'bg-gradient-green', active: false },
  { label: 'Total', value: kpiTotals.value, footer: 'Geral', icon: 'mdi-chart-line', gradient: 'bg-gradient-purple', active: false },
]));

const handleKpiClick = (label: string) => {
  filters.status = [];
  if (label === 'Vencem Hoje') { applyPreset('today'); filters.status = ['em_aberto']; }
  else if (label === 'Vencidos') { applyPreset('year'); filters.status = ['atrasado']; }
  else if (label === 'A Receber') { applyPreset('year'); filters.status = ['em_aberto']; }
  else if (label === 'Recebido') { applyPreset('month'); filters.status = ['pago']; }
  fetchReceivables();
};

// -- UTILS --
const formatDateSafe = (dateString: string) => {
    if (!dateString) return '-';
    return dateString.split('T')[0].split('-').reverse().join('/');
};

const formatCurrency = (val:any) => new Intl.NumberFormat('pt-BR', {style:'currency',currency:'BRL'}).format(Number(val)||0);
const formatCurrencyValue = (val:any) => new Intl.NumberFormat('pt-BR', {minimumFractionDigits:2}).format(Number(val)||0);
const isOverdue = (i:any) => i.status!=='pago' && i.due_date < format(new Date(), 'yyyy-MM-dd');
const getStatusLabel = (i:any) => i.status==='pago'?'Recebido':(isOverdue(i)?'Atrasado':'Aberto');
const getStatusChipClass = (i:any) => i.status==='pago'?'chip-success':(isOverdue(i)?'chip-danger':'chip-warn');

const getVuetifyStatusColor = (item:any) => {
    if(item.status === 'pago') return 'success';
    return isOverdue(item) ? 'error' : 'warning';
};

const getRefNumber = (i:any) => i.gestao_click_id || (i.id ? String(i.id).substring(0,6).toUpperCase() : '-');

const getRefClass = (i:any) => {
    if (themeStore.currentMode !== 'light') return 'text-white underline-ref bg-transparent';
    return i.is_signal ? 'bg-orange-lighten-4 text-orange-darken-4' : (i.gestao_click_id ? 'text-teal-darken-3 bg-teal-lighten-5' : 'bg-grey-lighten-4');
};

const getCustomerName = (i:any) => i.entity_name || auxData.customers.find(c=>c.id===i.customer_id)?.name || 'Cliente';
const getChartName = (id:any) => auxData.chartOfAccounts.find(c=>c.id===id)?.name || '-';
const getCompanyName = (id:any) => auxData.companies.find(c=>c.id===id)?.trade_name || '-';
const getPaymentMethodName = (id:any) => auxData.paymentMethods.find(m=>m.id===id)?.name || '';
const getBankAccountName = (id:any) => auxData.bankAccounts.find(b=>b.id===id)?.name || '-';
const zebraClass = (i:number) => themeStore.currentMode!=='light' ? (i%2===0?'zebra-dark-a':'zebra-dark-b') : (i%2===0?'zebra-light-a':'zebra-light-b');

const normalizeText = (text: string) => {
    return text ? text.normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase() : '';
};

// --- QUERY BUILDER ---
const buildQuery = (baseQuery: any) => {
    const { customStart, customEnd, dateType } = filters;
    const todayStr = format(new Date(), 'yyyy-MM-dd');

    const dateField = dateType === 'payment_date' ? 'payment_date' : 'due_date';
    if (customStart) baseQuery = baseQuery.gte(dateField, customStart);
    if (customEnd) baseQuery = baseQuery.lte(dateField, customEnd);

    // Ajuste: O contexto da empresa dita a regra geral agora
    if (!companyStore.isGlobalView && companyStore.context) {
        baseQuery = baseQuery.eq('company_id', companyStore.context);
    }

    if (filters.chartOfAccountsId) baseQuery = baseQuery.eq('chart_of_accounts_id', filters.chartOfAccountsId);
    if (filters.minValue) baseQuery = baseQuery.gte('value', filters.minValue);
    if (filters.maxValue) baseQuery = baseQuery.lte('value', filters.maxValue);

    if (filters.onlyConciliated) {
        baseQuery = baseQuery.eq('reconciliation_status', 'CONCILIATED');
    }

    if (filters.status.length > 0) {
        if (filters.status.includes('atrasado')) {
            if(filters.status.length === 1) {
                 baseQuery = baseQuery.lt('due_date', todayStr).neq('status', 'pago');
            } else {
                 const effectiveStatus = filters.status.map(s => s === 'atrasado' ? 'em_aberto' : s);
                 baseQuery = baseQuery.in('status', effectiveStatus);
            }
        } else {
            baseQuery = baseQuery.in('status', filters.status);
        }
    }

    return baseQuery;
};

const fetchReceivables = async () => {
    loading.value = true;
    feedback.show = false;
    allFetchedItems.value = [];

    try {
      const selectString = `
          *,
          chart_of_accounts:finance_chart_of_accounts(name),
          orders!left(id, order_number, created_by, customer_name, customer_id, store_id, stores(name))
      `;

        const fetchAllPages = async (buildQ: () => any, queryName: string) => {
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
        const financeData = await fetchAllPages(getFinanceQuery, "Recebíveis Principais");

        let signalsRaw: any[] = [];
        const isSignalsAllowed = companyStore.isGlobalView;
        const statusAllowsSignals = filters.status.length === 0 || filters.status.includes('pago');
        const conciliatedAllowsSignals = !filters.onlyConciliated;

        if (isSignalsAllowed && statusAllowsSignals && conciliatedAllowsSignals) {
             const getSignalsQuery = () => {
                 let signalQuery = supabase.from('order_payments')
                    .select(`*, orders!inner(id, order_number, customer_name, created_by, customer_id, store_id, stores(name))`)
                    .gte('payment_date', filters.customStart)
                    .lte('payment_date', filters.customEnd);

                 if (filters.customerId) signalQuery = signalQuery.eq('orders.customer_id', filters.customerId);
                 if (filters.minValue) signalQuery = signalQuery.gte('amount', filters.minValue);
                 if (filters.maxValue) signalQuery = signalQuery.lte('amount', filters.maxValue);

                 return signalQuery.order('payment_date', { ascending: true }).order('id', { ascending: true });
             };
             signalsRaw = await fetchAllPages(getSignalsQuery, "Sinais de Pedidos");
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
                customer: cData,
                reconciliation_status: 'PENDING',
                bank_fitid: null
            };
        });

      let combined = [...financeEnriched, ...signalsEnriched];

        if (filters.onlyConciliated) {
            combined = combined.filter(item => item.reconciliation_status === 'CONCILIATED');
        }

        if (filters.customerId) {
            combined = combined.filter(item => {
                const cId = item.customer_id || item.orders?.customer_id || item.customer?.id;
                return cId === filters.customerId;
            });
        }

        if (filters.salespersonId) {
            combined = combined.filter(item => {
                const createdBy = item.orders?.created_by || item.created_by;
                const walletOwner = item.customer?.vendedor_responsavel_id;
                return createdBy === filters.salespersonId || walletOwner === filters.salespersonId;
            });
        }

        if (filters.status.length > 0) {
            const todayStr = format(new Date(), 'yyyy-MM-dd');
            combined = combined.filter(item => {
                const isItemOverdue = item.status !== 'pago' && item.due_date < todayStr;
                const isItemOpen = item.status !== 'pago';
                const isItemPaid = item.status === 'pago';

                if (filters.status.includes('pago') && isItemPaid) return true;
                if (filters.status.includes('atrasado') && isItemOverdue) return true;
                if (filters.status.includes('em_aberto') && isItemOpen) return true;

                return false;
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

        feedback.error = false;
        feedback.message = `${mappedItems.length} registros carregados com sucesso.`;
        feedback.show = true;

    } catch (e: any) {
        console.error('Fetch Error:', e);
        feedback.error = true;
        feedback.message = 'Erro: ' + e.message;
        feedback.show = true;
    } finally {
        loading.value = false;
    }
};

const clientSideFilteredItems = computed(() => {
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

const items = computed(() => {
    totalItems.value = clientSideFilteredItems.value.length;
    const start = (page.value - 1) * itemsPerPage;
    const end = start + itemsPerPage;
    return clientSideFilteredItems.value.slice(start, end);
});

const calculateKpis = (allItems: any[]) => {
    let total = 0, paid = 0, open = 0, todayCount = 0, overdue = 0;
    const todayStr = format(new Date(), 'yyyy-MM-dd');

    allItems.forEach(i => {
        const val = Number(i.value) - Number(i.discount || 0);
        total += val;

        if (i.status === 'pago') {
            paid += val;
        } else {
            if (i.due_date < todayStr) overdue += val;
            else {
                open += val;
                if (i.due_date === todayStr) todayCount += val;
            }
        }
    });

    kpiTotals.value = total;
    kpiTotals.paid = paid;
    kpiTotals.openFuture = open;
    kpiTotals.expiresToday = todayCount;
    kpiTotals.overdue = overdue;

    logsData.sumValue = total;
};

watch(clientSideFilteredItems, (newFilteredItems) => {
    calculateKpis(newFilteredItems);
}, { immediate: true });

const handlePageChange = (newPage: number) => {
    page.value = newPage;
};

const hasAttachments = (item: any) => {
    return item.attachments && (Array.isArray(item.attachments) ? item.attachments.length > 0 : !!item.attachments);
};

const openAttachment = (item: any) => {
    let url = '';
    if (Array.isArray(item.attachments)) url = item.attachments[0];
    else if (typeof item.attachments === 'string') {
        try {
            const parsed = JSON.parse(item.attachments);
            url = Array.isArray(parsed) ? parsed[0] : parsed;
        } catch { url = item.attachments; }
    }
    if (url) window.open(url, '_blank');
};

const areAllSelected = computed(() => items.value.length>0 && selectedIds.value.size === items.value.length);
const toggleSelectAll = (v:boolean) => { if(v) items.value.forEach(i=>selectedIds.value.add(i.id)); else selectedIds.value.clear(); };
const toggleSelection = (id:string) => { if(selectedIds.value.has(id)) selectedIds.value.delete(id); else selectedIds.value.add(id); };
const pageCount = computed(() => Math.ceil(totalItems.value / itemsPerPage));
const toggleStatusFilter = (s:string) => { const idx=filters.status.indexOf(s); if(idx>=0) filters.status.splice(idx,1); else filters.status.push(s); };

const deleteReceivable = async (i:any) => {
    if(confirm('Excluir?')) {
        const oldState = { ...i };
        await supabase.from('finance_receivables').delete().eq('id',i.id);
        await logBusinessEvent('Financeiro - Receber', 'DELETE', `Excluiu recebimento de ${getCustomerName(i)}`, null, i.id, oldState);
        fetchReceivables();
    }
};
const deleteSelected = async () => {
    if(confirm(`Excluir ${selectedIds.value.size}?`)) {
        const ids=Array.from(selectedIds.value);
        await supabase.from('finance_receivables').delete().in('id',ids);
        await logBusinessEvent('Financeiro - Receber', 'DELETE', `Excluiu ${ids.length} recebimentos em lote.`, { idsDeleted: ids }, null, null);
        selectedIds.value.clear();
        fetchReceivables();
    }
};

// Toggle rápido de status (Mantido com log para consistência caso venha a ser ativado no template)
const toggleStatus = async (i:any) => {
    const s = i.status==='pago'?'em_aberto':'pago';
    const oldState = { ...i };
    await supabase.from('finance_receivables').update({ status:s, payment_date: s==='pago'?new Date().toISOString():null }).eq('id',i.id);
    const msg = s === 'pago' ? `Baixou (pagou) o título de ${getCustomerName(i)}` : `Estornou o título de ${getCustomerName(i)}`;
    await logBusinessEvent('Financeiro - Receber', 'STATUS_CHANGE', msg, { new_status: s }, i.id, oldState);
    fetchReceivables();
};

const fetchAuxiliaryData = async () => {
    const { data: c } = await supabase.from('customers_mj').select('id, nome'); if(c) auxData.customers = c.map(x=>({id:x.id,name:x.nome}));
    const { data: cat } = await supabase.from('finance_chart_of_accounts').select('id, name').eq('type','Receita'); if(cat) auxData.chartOfAccounts = cat;
    const { data: comp } = await supabase.from('companies').select('id, trade_name'); if(comp) auxData.companies = comp;

    // FIX: Solicitando apenas 'id' e 'name' para evitar o erro 400 Bad Request
    const { data: b } = await supabase.from('finance_accounts').select('id, name'); if(b) auxData.bankAccounts = b;

    const { data: p } = await supabase.from('finance_payment_methods').select('id, name'); if(p) auxData.paymentMethods = p;
    const { data: cc } = await supabase.from('finance_cost_centers').select('id, name'); if(cc) auxData.costCenters = cc;
    const { data: sellers } = await supabase.from('profiles').select('id, full_name').or('role.eq.vendedor,role.eq.admin'); if(sellers) auxData.salespeople = sellers;
};

// --- PDF RECEIPT HELPERS ---
const imageToBase64 = (urlOrFile: string | File): Promise<string> => new Promise((resolve, reject) => {
    const img = new Image();
    img.crossOrigin = 'Anonymous';
    img.onload = () => {
        const canvas = document.createElement('canvas');
        canvas.width = img.width;
        canvas.height = img.height;
        const ctx = canvas.getContext('2d');
        if (ctx) {
            // FIX: Pinta o fundo de branco antes de desenhar a logo para matar o bug do jsPDF
            ctx.fillStyle = '#FFFFFF';
            ctx.fillRect(0, 0, canvas.width, canvas.height);

            ctx.drawImage(img, 0, 0);
            resolve(canvas.toDataURL('image/png'));
        } else {
            reject(new Error('Canvas context error'));
        }
    };
    img.onerror = reject;
    if (typeof urlOrFile === 'string') img.src = urlOrFile;
    else img.src = URL.createObjectURL(urlOrFile);
});

const addHeader = async (doc: jsPDF, orderNum: any, title: string, yOffset = 0, companyName: string) => {
    const pageWidth = doc.internal.pageSize.width;
    const margin = 15;
    try {
        const logoUrl = 'https://cdn.shopify.com/s/files/1/0661/4574/6991/files/Sem_nome_1080_x_800_px_1080_x_500_px_1080_x_400_px_1000_x_380_px_da020cf2-2bb9-4dac-8dd3-4548cfd2e5ae.png?v=1756811713';
        const logoBase64 = await imageToBase64(logoUrl);
        const logoProps = doc.getImageProperties(logoBase64);
        const logoWidth = 45;
        const logoHeight = (logoProps.height * logoWidth) / logoProps.width;
        doc.addImage(logoBase64, 'PNG', margin, 12 + yOffset, logoWidth, logoHeight);
    } catch (e) { }

    doc.setFont('helvetica', 'bold');
    doc.setFontSize(14);
    doc.text(title, pageWidth / 2, 20 + yOffset, { align: 'center' });
    if (orderNum && orderNum !== 'S/N') {
        doc.setFontSize(12);
        doc.setTextColor(0, 0, 0);
        doc.text(`Ref Nº: ${String(orderNum).padStart(4, '0')}`, pageWidth / 2, 28 + yOffset, { align: 'center' });
    }
    doc.setFont('helvetica', 'normal');
    doc.setFontSize(8);
    doc.setTextColor(100);
    doc.text([
      companyName.toUpperCase(),
      "Documento Auxiliar Financeiro"
    ], pageWidth - margin, 20 + yOffset, { align: 'right' });
    doc.setLineWidth(0.5);
    doc.line(margin, 38 + yOffset, pageWidth - margin, 38 + yOffset);
};

const addFooter = (doc: jsPDF) => {
    const pageCount = (doc as any).internal.getNumberOfPages();
    const pageWidth = doc.internal.pageSize.width;
    const pageHeight = doc.internal.pageSize.height;
    doc.setFontSize(8).setTextColor(150);
    for (let i = 1; i <= pageCount; i++) {
        doc.setPage(i);
        doc.text(`Gerado por MJProcess em ${format(new Date(), 'dd/MM/yyyy HH:mm')}`, 15, pageHeight - 3);
        doc.text(`Página ${i} de ${pageCount}`, pageWidth - 15, pageHeight - 3, { align: 'right' });
    }
};

const addWatermark = async (doc: jsPDF) => {
    const totalPages = (doc as any).internal.getNumberOfPages();
    const pageWidth = doc.internal.pageSize.getWidth();
    const pageHeight = doc.internal.pageSize.getHeight();
    let logoBase64: string | null = null;
    try {
        const logoUrl = 'https://cdn.shopify.com/s/files/1/0661/4574/6991/files/Sem_nome_1080_x_800_px_1080_x_500_px_1080_x_400_px_1000_x_380_px_da020cf2-2bb9-4dac-8dd3-4548cfd2e5ae.png?v=1756811713';
        logoBase64 = await imageToBase64(logoUrl);
    } catch (e) { }

    for (let i = 1; i <= totalPages; i++) {
        doc.setPage(i);
        doc.saveGraphicsState();
        doc.setGState(new (doc as any).GState({ opacity: 0.08 }));
        if (logoBase64) {
            const logoProps = doc.getImageProperties(logoBase64);
            const logoWidth = pageWidth * 0.75;
            const logoHeight = (logoProps.height * logoWidth) / logoProps.width;
            doc.addImage(logoBase64, 'PNG', (pageWidth - logoWidth) / 2, (pageHeight - logoHeight) / 2, logoWidth, logoHeight);
        }
        doc.setGState(new (doc as any).GState({ opacity: 0.7 }));
        doc.setFont('helvetica', 'bold'); doc.setFontSize(18); doc.setTextColor(255, 150, 150);
        const text = 'recibo';
        const yStep = 50;
        for (let y = 25; y < pageHeight - 15; y += yStep) { doc.text(text, 6, y, { angle: 90 }); }
        for (let y = 25; y < pageHeight - 15; y += yStep) { doc.text(text, pageWidth - 6, y, { angle: -90 }); }
        doc.restoreGraphicsState();
    }
};

const handlePrintReceipt = async (rec: any) => {
    printLoadingId.value = rec.id;

    try {
        const orderNum = rec.order_number && rec.order_number !== 'S/N' ? rec.order_number : null;
        const clientName = getCustomerName(rec);
        const clientCpfCnpj = rec.customer?.cpf_cnpj || rec.customer?.cnpj || rec.customer?.cpf || 'Não informado';
        const currentCompanyName = getCompanyName(rec.company_id) || companyStore.currentCompanyName || 'Sua Empresa';

        const amount = Number(rec.value) - Number(rec.discount || 0);
        const method = getPaymentMethodName(rec.payment_method_id) || 'Diversos';
        const description = rec.description || `Referente ao lançamento #${rec.id}`;

        const pdfFileName = `Recibo_${orderNum ? orderNum : rec.id.substring(0,6)}.pdf`;

        const qrCodeContent = window.location.href;
        const qrCodeDataUrl = await QRCode.toDataURL(qrCodeContent, { width: 175, margin: 1 });

        const doc = new jsPDF('p', 'mm', 'a4');
        const pageWidth = doc.internal.pageSize.width;
        const pageHeight = doc.internal.pageSize.height;
        const midPointY = pageHeight / 2;
        const margin = 15;

        const introText = `A empresa ${currentCompanyName.toUpperCase()} confirma o recebimento do valor descrito abaixo${orderNum ? `, referente ao Pedido/Doc nº ${orderNum}.` : '.'}`;
        const qrSize = 25; const qrGap = 5; const tableWidth = pageWidth - margin * 2 - qrSize - qrGap;

        const tableHead = [['Cliente / Pagador', 'CPF/CNPJ', 'Valor Pago', 'Detalhes / Forma']];
        const tableBody = [[ clientName, clientCpfCnpj, formatCurrency(amount), `${description} (${method})` ]];

        const dataDoPagamento = `${format(new Date(), "dd 'de' MMMM 'de' yyyy", { locale: ptBR })}`;

        const generateViaContent = async (yOffset: number, viaTitle: string) => {
            await addHeader(doc, orderNum, `Recibo de Pagamento`, yOffset, currentCompanyName);

            doc.setFontSize(8).setTextColor(150).text(viaTitle, pageWidth - margin, yOffset + 10, { align: 'right' });

            const startY = yOffset + 48;
            doc.setFontSize(10).setFont('helvetica', 'normal').setTextColor(0, 0, 0);
            doc.text(introText, margin, startY, { maxWidth: pageWidth - margin * 2 });

            const tableStartY = startY + 12;
            const qrX = margin + tableWidth + qrGap;

            autoTable(doc, {
                startY: tableStartY,
                head: tableHead,
                body: tableBody,
                theme: 'striped',
                headStyles: { fillColor: yOffset === 0 ? [220, 230, 250] : [70, 100, 200], textColor: yOffset === 0 ? 0 : [255, 255, 255], fontStyle: 'bold' },
                columnStyles: { 0: { cellWidth: 'auto' }, 1: { cellWidth: 40 }, 2: { cellWidth: 35, halign: 'right' }, 3: { cellWidth: 50 } },
                styles: { overflow: 'linebreak', cellPadding: 2 },
                tableWidth: tableWidth, margin: { left: margin },
            });

            doc.addImage(qrCodeDataUrl, 'PNG', qrX, tableStartY, qrSize, qrSize);
            doc.setFontSize(7).setTextColor(100).text('Validar', qrX + qrSize / 2, tableStartY + qrSize + 3, { align: 'center' });

            let finalY = (doc as any).lastAutoTable.finalY + 15;

            const signatureY = Math.min(finalY + 10, (yOffset === 0 ? midPointY : pageHeight) - 20);
            const signatureWidth = (pageWidth - margin * 3) / 2;
            const signatureX1 = margin;
            const signatureX2 = margin * 2 + signatureWidth;

            doc.setLineWidth(0.3).setDrawColor(0, 0, 0);
            doc.line(signatureX1, signatureY, signatureX1 + signatureWidth, signatureY);
            doc.setFontSize(9).setTextColor(0, 0, 0).text(currentCompanyName.substring(0,30), signatureX1 + signatureWidth / 2, signatureY + 5, { align: 'center' });

            doc.line(signatureX2, signatureY, signatureX2 + signatureWidth, signatureY);
            doc.setFontSize(9).setTextColor(0, 0, 0).text(clientName.substring(0,30), signatureX2 + signatureWidth / 2, signatureY + 5, { align: 'center' });

            const dateY = signatureY + 15;
            doc.setFontSize(9).setFont('helvetica', 'normal').text(`Emitido em: ${dataDoPagamento}`, pageWidth / 2, dateY, { align: 'center' });
        };

        await generateViaContent(0, 'Via da Empresa');

        doc.setLineDashPattern([2, 2], 0);
        doc.line(5, midPointY, pageWidth - 5, midPointY);
        doc.setLineDashPattern([], 0);

        doc.setFontSize(8).setTextColor(150).text('- - - - corte aqui - - - -', pageWidth / 2, midPointY - 1, { align: 'center' });

        await generateViaContent(midPointY, 'Via do Pagador');
        await addWatermark(doc);
        addFooter(doc);

        doc.save(pdfFileName);

        await logBusinessEvent('Financeiro - Receber', 'PRINT', `Imprimiu recibo para ${clientName}`, null, rec.id, null);

        appStore.showSnackbar('Recibo gerado com sucesso!', 'success');

    } catch (e:any) {
        console.error(e);
        appStore.showSnackbar('Erro ao gerar recibo: ' + e.message, 'error');
    } finally {
        printLoadingId.value = null;
    }
}

// --- BULK COMPANY ASSIGN ---
const bulkCompanyModal = reactive({ show: false, companyId: null as any, loading: false });
const openBulkCompanyModal = () => { bulkCompanyModal.companyId = null; bulkCompanyModal.show = true; };
const executeBulkCompanyAssign = async () => {
  if (!bulkCompanyModal.companyId) return;
  bulkCompanyModal.loading = true;
  try {
      const ids = Array.from(selectedIds.value);
      const realIds = ids.filter(id => allFetchedItems.value.find(i => i.id === id && !i.is_signal));

      if (realIds.length === 0) {
          throw new Error('Nenhum item válido para atualização selecionado (Sinais não podem ser editados aqui).');
      }

      const { error } = await supabase
        .from('finance_receivables')
        .update({ company_id: bulkCompanyModal.companyId })
        .in('id', realIds);

      if (error) throw error;

      const compName = auxData.companies.find(c => c.id === bulkCompanyModal.companyId)?.trade_name;
      await logBusinessEvent('Financeiro - Receber', 'UPDATE', `Moveu ${realIds.length} recebimentos para a empresa ${compName}`, { new_company: bulkCompanyModal.companyId }, null, null);

      appStore.showSnackbar(`${realIds.length} itens atualizados!`, 'success');
      bulkCompanyModal.show = false;
      selectedIds.value.clear();
      fetchReceivables();
  } catch (e: any) {
      appStore.showSnackbar('Erro: ' + e.message, 'error');
  } finally {
      bulkCompanyModal.loading = false;
  }
};

// --- BULK STATUS UPDATE ---
const bulkUpdateStatus = async (newStatus: 'pago' | 'em_aberto', useDueDate: boolean = false) => {
    const actionText = newStatus === 'pago' ? (useDueDate ? 'RECEBIDO NA DATA ORIGINAL' : 'RECEBIDO HOJE') : 'ABERTO';
    if(!confirm(`Deseja alterar o status de ${selectedIds.value.size} itens para ${actionText}?`)) return;

    const ids = Array.from(selectedIds.value);
    const realItems = allFetchedItems.value.filter(i => ids.includes(i.id) && !i.is_signal);
    const realIds = realItems.map(i => i.id);

    if (realIds.length === 0) {
        appStore.showSnackbar('Nenhum item válido para atualizar selecionado.', 'warning');
        return;
    }

// VERIFICAÇÃO DE CAIXA EM LOTE E ABERTURA AUTOMÁTICA
if (newStatus === 'pago') {
    const hasOrder = realItems.some(i => i.order_id || (i.order_number && i.order_number !== 'S/N'));
    if (hasOrder) {

        // Pega o store_id e o nome da loja do primeiro item que tiver um pedido vinculado
        const firstItemWithOrder = realItems.find(i => i.orders?.store_id);
        const firstStoreId = firstItemWithOrder?.orders?.store_id;

        if (firstStoreId && userStore.activeStoreId !== firstStoreId) {
            const storeName = firstItemWithOrder?.orders?.stores?.name || 'Loja do Pedido';
            userStore.setAdminStore({ id: firstStoreId, name: storeName });
            await mjCashStore.checkActiveSession();
        }

        if (!mjCashStore.isSessionOpen) {
            appStore.showSnackbar('Abra o caixa antes de realizar baixas em lote para pedidos.', 'warning');

            pendingCashAction.value = () => bulkUpdateStatus(newStatus, useDueDate);
            showCashOpeningModal.value = true;
            return;
        }
    }
}

    loading.value = true;
    try {
        const ids = Array.from(selectedIds.value);
        const realItems = allFetchedItems.value.filter(i => ids.includes(i.id) && !i.is_signal);
        const realIds = realItems.map(i => i.id);

        if (realIds.length === 0) {
            appStore.showSnackbar('Nenhum item válido para atualizar selecionado.', 'warning');
            loading.value = false;
            return;
        }

        if (newStatus === 'pago' && useDueDate) {
            const promises = realItems.map(item =>
                supabase.from('finance_receivables')
                    .update({ status: 'pago', payment_date: item.due_date })
                    .eq('id', item.id)
            );
            await Promise.all(promises);
        } else {
            const payload = {
                status: newStatus,
                payment_date: newStatus === 'pago' ? new Date().toISOString().split('T')[0] : null
            };
            const { error } = await supabase.from('finance_receivables').update(payload).in('id', realIds);
            if(error) throw error;
        }

        await logBusinessEvent('Financeiro - Receber', 'STATUS_CHANGE', `Alterou status de ${realIds.length} recebimentos em lote para ${newStatus}.`, { new_status: newStatus, count: realIds.length }, null, null);

        appStore.showSnackbar(`${realIds.length} itens atualizados com sucesso!`, 'success');
        selectedIds.value.clear();
        fetchReceivables();
    } catch(e:any) {
        appStore.showSnackbar('Erro ao atualizar em massa: ' + e.message, 'error');
    } finally {
        loading.value = false;
    }
};

// --- REPORT GENERATION ---
const generateReport = async (type: 'pdf' | 'pdf_monthly' | 'excel') => {
    reportLoading.value = true;

    let dataToExport = [...clientSideFilteredItems.value].map(item => {
        let v = item.value !== undefined ? item.value : 0;
        let d = item.discount !== undefined ? item.discount : 0;

        if (typeof v === 'string') v = parseFloat(v.toString().replace(/[^\d.-]/g, '')) || 0;
        if (typeof d === 'string') d = parseFloat(d.toString().replace(/[^\d.-]/g, '')) || 0;

        return {
            ...item,
            numeric_value: Number(v) - Number(d)
        };
    });

    if (dataToExport.length === 0) {
        appStore.showSnackbar('Nenhum dado para exportar', 'warning');
        reportLoading.value = false;
        return;
    }

    const getMainDateStr = (row: any) => {
        let dStr = row.due_date;
        if (filters.dateType === 'payment_date' && row.payment_date) dStr = row.payment_date;
        if (filters.dateType === 'both' && row.status === 'pago' && row.payment_date) dStr = row.payment_date;
        return dStr ? String(dStr).substring(0, 10) : '2000-01-01';
    };

    dataToExport = dataToExport.map(row => {
        const dateStr = getMainDateStr(row);
        const parts = dateStr.split('-');

        const monthNames = ["", "JANEIRO", "FEVEREIRO", "MARÇO", "ABRIL", "MAIO", "JUNHO", "JULHO", "AGOSTO", "SETEMBRO", "OUTUBRO", "NOVEMBRO", "DEZEMBRO"];
        const monthNum = parseInt(parts[1], 10);
        const monthDisplay = `${monthNames[monthNum]} / ${parts[0]}`;

        return {
            ...row,
            _mainDateStr: dateStr,
            _monthKey: `${parts[0]}-${parts[1]}`,
            _monthDisplay: monthDisplay
        };
    });

    dataToExport.sort((a, b) => a._mainDateStr.localeCompare(b._mainDateStr));

    await logBusinessEvent('Financeiro - Receber', 'READ', `Exportou relatório de Contas a Receber em formato ${type.toUpperCase()}`, { filters: filters }, null, null);

    if (type === 'excel') {
        const ws = XLSX.utils.json_to_sheet(dataToExport.map(i => ({
            Ref: i.order_number,
            Cliente: getCustomerName(i),
            Descricao: i.description,
            PlanoContas: getChartName(i.chart_of_accounts_id),
            Vencimento: formatDateSafe(i.due_date),
            Pagamento: i.payment_date ? formatDateSafe(i.payment_date) : '-',
            Valor: i.numeric_value,
            Status: getStatusLabel(i),
            Empresa: getCompanyName(i.company_id),
            Observacoes: i.notes || ''
        })));
        const wb = XLSX.utils.book_new();
        XLSX.utils.book_append_sheet(wb, ws, "ContasReceber");
        XLSX.writeFile(wb, `Relatorio_Receber_${format(new Date(), 'dd-MM-yyyy')}.xlsx`);
        appStore.showSnackbar('Excel Gerado!', 'success');
        reportLoading.value = false;
        return;
    }

        const doc = new jsPDF({ orientation: 'p', unit: 'mm', format: 'a4' });
        const pageWidth = doc.internal.pageSize.width;
        const pageHeight = doc.internal.pageSize.height;
        const todayStr = format(new Date(), 'yyyy-MM-dd');
        const companyName = companyStore.isGlobalView ? 'VISÃO GLOBAL - HOLDING' : companyStore.currentCompanyName.toUpperCase();

        // FIX: Converter as logos para Base64 (que já vai com o fundo branco aplicado)
        let base64Mj = logoMj;
        let base64Cajuia = logoCajuia;
        try {
            base64Mj = await imageToBase64(logoMj);
            base64Cajuia = await imageToBase64(logoCajuia);
        } catch (e) {
            console.warn("Aviso: Falha ao pré-carregar base64 das logos", e);
        }

    const drawLogos = (d: any, x: number, y: number) => {
        const renderImgProportional = (imgSrc: any, posX: number, posY: number, targetWidth: number) => {
            try {
                const props = d.getImageProperties(imgSrc);
                const targetHeight = (props.height * targetWidth) / props.width;
                d.addImage(imgSrc, 'PNG', posX, posY, targetWidth, targetHeight);
            } catch (e) {
                d.addImage(imgSrc, 'PNG', posX, posY, targetWidth, 18);
            }
        };

        try {
            if (companyStore.isGlobalView) {
                renderImgProportional(logoMj, x, y, 32);
                renderImgProportional(logoCajuia, x + 38, y, 32);
            } else if (companyStore.currentCompanyName.toLowerCase().includes('cajuia')) {
                renderImgProportional(logoCajuia, x, y, 40);
            } else {
                renderImgProportional(logoMj, x, y, 40);
            }
        } catch(e) {
             try { renderImgProportional(logoImage, x, y, 35); } catch(ex) {}
        }
    };

    const calcTotals = (items: any[]) => {
        let t = 0, p = 0, o = 0, a = 0;
        items.forEach(r => {
            t += r.numeric_value;
            if (r.status === 'pago') p += r.numeric_value;
            else if (r.due_date < todayStr) o += r.numeric_value;
            else a += r.numeric_value;
        });
        return { total: t, paid: p, overdue: o, open: a };
    };

    const renderCoverPage = () => {
        drawLogos(doc, 15, 15);

        doc.setFontSize(22).setFont('helvetica', 'bold').setTextColor(30, 30, 30);
        doc.text("RELATÓRIO DE CONTAS A RECEBER", pageWidth / 2, 50, { align: 'center' });

        doc.setFontSize(11).setFont('helvetica', 'normal').setTextColor(100);
        doc.text(`Período Base: ${formatDateSafe(filters.customStart)} até ${formatDateSafe(filters.customEnd)}`, pageWidth / 2, 60, { align: 'center' });
        doc.text(`Contexto da Emissão: ${companyName}`, pageWidth / 2, 66, { align: 'center' });

        const drawCoverKpi = (label: string, val: number, color: number[], x: number, y: number) => {
            doc.setFillColor(color[0], color[1], color[2]);
            doc.roundedRect(x, y, 80, 32, 3, 3, 'F');
            doc.setDrawColor(color[0]-30, color[1]-30, color[2]-30);
            doc.roundedRect(x, y, 80, 32, 3, 3, 'S');

            doc.setFontSize(9).setFont('helvetica', 'bold').setTextColor(120, 120, 120);
            doc.text(label.toUpperCase(), x + 40, y + 10, { align: 'center' });

            doc.setFontSize(18).setFont('helvetica', 'bold').setTextColor(30, 30, 30);
            doc.text(formatCurrency(val), x + 40, y + 23, { align: 'center' });
        };

        const xLeft = (pageWidth / 2) - 85;
        const xRight = (pageWidth / 2) + 5;
        const globalTotals = calcTotals(dataToExport);

        drawCoverKpi("Total de Lançamentos", globalTotals.total, [240, 244, 248], xLeft, 85);
        drawCoverKpi("Total Recebido (Baixado)", globalTotals.paid, [232, 248, 235], xRight, 85);
        drawCoverKpi("Total em Atraso", globalTotals.overdue, [255, 235, 238], xLeft, 125);
        drawCoverKpi("Total a Receber (Em dia)", globalTotals.open, [255, 248, 225], xRight, 125);

        const nowStr = format(new Date(), 'dd/MM/yyyy HH:mm');
        doc.setFontSize(8).setTextColor(150);
        doc.text(`Gerado em ${nowStr} por ${userStore.user?.email || 'Sistema'}`, pageWidth / 2, pageHeight - 15, { align: 'center' });
    };

    renderCoverPage();

    const renderDataSection = (title: string, dataSlice: any[]) => {
        doc.addPage();

        drawLogos(doc, 15, 10);
        doc.setFontSize(8).setTextColor(80).setFont('helvetica', 'normal');
        doc.text([companyName, "Detalhamento de Recebíveis", "MJProcess ERP"], pageWidth - 15, 12, { align: 'right', lineHeightFactor: 1.2 });
        doc.setDrawColor(220, 220, 220);
        doc.line(15, 28, pageWidth - 15, 28);

        doc.setFontSize(14).setFont('helvetica', 'bold').setTextColor(20);
        doc.text(title, 15, 38);

        const sliceTotals = calcTotals(dataSlice);
        const kpiY = 46;
        const kpiBoxWidth = (pageWidth - 30) / 4;

        const drawMiniKpi = (lbl: string, val: number, col: string, xPos: number) => {
            doc.setFontSize(7).setTextColor(120).setFont('helvetica', 'normal');
            doc.text(lbl, xPos, kpiY);
            doc.setFontSize(9).setTextColor(col).setFont('helvetica', 'bold');
            doc.text(formatCurrency(val), xPos, kpiY + 4);
        };

        drawMiniKpi("SUBTOTAL", sliceTotals.total, "#333333", 15);
        drawMiniKpi("A RECEBER", sliceTotals.open, "#F57F17", 15 + kpiBoxWidth);
        drawMiniKpi("ATRASADO", sliceTotals.overdue, "#D32F2F", 15 + kpiBoxWidth * 2);
        drawMiniKpi("RECEBIDO", sliceTotals.paid, "#388E3C", 15 + kpiBoxWidth * 3);

        const columns = [
            { header: 'Ref', dataKey: 'ref' },
            { header: 'Data Base', dataKey: 'date_str' },
            { header: 'Cliente / Pagador', dataKey: 'entity' },
            { header: 'Descrição', dataKey: 'desc' },
            { header: 'Status', dataKey: 'status_label' },
            { header: 'Valor', dataKey: 'value' }
        ];

        const tableBody = dataSlice.map(row => {
            const isPaid = row.status === 'pago';
            const isOverdueItem = !isPaid && row.due_date < todayStr;

            let rowColor: [number, number, number] = [255, 255, 255];
            if (isPaid) rowColor = [240, 250, 240];
            else if (isOverdueItem) rowColor = [255, 240, 240];
            else rowColor = [255, 250, 235];

            return {
                ref: row.order_number,
                date_str: formatDateSafe(row._mainDateStr),
                entity: getCustomerName(row).substring(0, 30),
                desc: (row.description || '').substring(0, 45),
                status_label: getStatusLabel(row).toUpperCase(),
                value: formatCurrency(row.numeric_value),
                _rowColor: rowColor
            };
        });

        autoTable(doc, {
            startY: kpiY + 8,
            columns: columns,
            body: tableBody,
            theme: 'grid',
            styles: { fontSize: 7, cellPadding: 2.5, textColor: 50, lineColor: [200, 200, 200], lineWidth: 0.1 },
            headStyles: { fillColor: [40, 40, 40], textColor: 255, fontStyle: 'bold', halign: 'center' },
            columnStyles: {
                ref: { cellWidth: 14, fontStyle: 'bold' },
                date_str: { cellWidth: 18, halign: 'center' },
                entity: { cellWidth: 'auto' },
                desc: { cellWidth: 'auto' },
                status_label: { cellWidth: 20, halign: 'center', fontStyle: 'bold' },
                value: { cellWidth: 24, halign: 'right', fontStyle: 'bold' }
            },
            didParseCell: (data) => {
                if (data.section === 'body') {
                    const row = data.row.raw as any;
                    if (row._rowColor) data.cell.styles.fillColor = row._rowColor;
                    data.cell.styles.textColor = [40, 40, 40];
                }
            },
            didDrawPage: () => {
                doc.setFontSize(7).setTextColor(150);
                doc.text(`Pág ${doc.internal.getNumberOfPages()}`, pageWidth - 15, pageHeight - 10, { align: 'right' });
            },
            foot: [['', '', '', '', 'SOMA DESTE BLOCO', formatCurrency(sliceTotals.total)]],
            footStyles: { fillColor: [240, 240, 240], textColor: [0, 0, 0], fontStyle: 'bold', halign: 'right' }
        });
    };

    if (type === 'pdf_monthly') {
        const groupedData: Record<string, any[]> = {};
        const orderOfMonths: string[] = [];

        dataToExport.forEach(row => {
            const mk = row._monthKey;
            if(!groupedData[mk]) {
                groupedData[mk] = [];
                orderOfMonths.push(mk);
            }
            groupedData[mk].push(row);
        });

        for (const monthKey of orderOfMonths) {
             const slice = groupedData[monthKey];
             renderDataSection(`Movimentação: ${slice[0]._monthDisplay}`, slice);
        }
    } else {
        renderDataSection("Lista Cronológica Completa", dataToExport);
    }

    doc.save(`Relatorio_Receber_${type}_${format(new Date(), 'yyyyMMdd_HHmm')}.pdf`);
    appStore.showSnackbar('PDF Gerado com Sucesso!', 'success');
    reportLoading.value = false;
};

const editModal = reactive({
    show: false,
    loading: false,
    error: null as string | null,
    activeTab: 'basic',
    isFixedAccount: false,
    files: [] as File[],
    projected: [] as any[],
    form: { id:'', description:'', entity_name:null as any, value:0, discount:0, due_date:'', competence_date:'', status:'em_aberto', payment_date:null, chart_of_accounts_id:null, company_id:null as any, cost_center_id:null, bank_account_id:null, payment_method_id:null, notes: '', attachments: [] as string[] },
    recurrence: { enabled: false, calcMethod: 'divide', count: 2, interval: 'month' as 'month'|'week' }
});

const openNewReceivableModal = () => { resetModal(); editModal.isFixedAccount=false; editModal.show=true; };
const openFixedAccountModal = () => { resetModal(); editModal.isFixedAccount=true; editModal.recurrence.enabled=true; editModal.recurrence.calcMethod='repeat'; editModal.recurrence.count=12; editModal.activeTab='recurrence'; editModal.show=true; };

const resetModal = () => {
    const defaultCompany = !companyStore.isGlobalView ? companyStore.context : null;

    Object.assign(editModal.form, { id:'', description:'', entity_name:null, value:0, discount:0, due_date:format(new Date(),'yyyy-MM-dd'), competence_date:format(new Date(),'yyyy-MM-dd'), status:'em_aberto', payment_date:null, chart_of_accounts_id:null, company_id: defaultCompany, notes:'', attachments: [] });
    editModal.files = []; editModal.projected = []; editModal.error = null; editModal.activeTab = 'basic'; editModal.recurrence.enabled=false;
};

const openEditModal = (i:any) => {
    if (i.order_id) {
        selectedOrderForBilling.value = { id: i.order_id };
        showBillingModal.value = true;
        return;
    }
    const data = JSON.parse(JSON.stringify(i));
    Object.assign(editModal.form, data);
    if (i.customer_id) { editModal.form.entity_name = i.customer_id; } else { editModal.form.entity_name = i.entity_name; }
    editModal.files = []; editModal.projected = []; editModal.error = null; editModal.isFixedAccount = false; editModal.recurrence.enabled = false; editModal.activeTab = 'basic'; editModal.show = true;
};

const openQuickAdd = async (type:string) => { if(type!=='customer') return; const n=prompt('Nome:'); if(!n) return; const {data}=await supabase.from('customers_mj').insert({nome:n}).select('id, nome').single(); if(data){ auxData.customers.push({id:data.id,name:data.nome}); editModal.form.entity_name=data.id; } };

const uploadAttachments = async (): Promise<string[]> => {
    if (editModal.files.length === 0) return [];
    const uploadedUrls: string[] = [];
    for (const file of editModal.files) {
        const fileExt = file.name.split('.').pop();
        const fileName = `${Date.now()}-${Math.random().toString(36).substring(7)}.${fileExt}`;
        const filePath = `receivables/${fileName}`;
        const { error } = await supabase.storage.from('finance-attachments').upload(filePath, file);
        if (!error) {
             const { data } = supabase.storage.from('finance-attachments').getPublicUrl(filePath);
             if (data?.publicUrl) uploadedUrls.push(data.publicUrl);
        }
    }
    return uploadedUrls;
};

const removeAttachment = (index:number) => { if(confirm('Remover anexo?')) editModal.form.attachments.splice(index,1); };

const generateInstallments = () => {
  const count = Math.max(2, Number(editModal.recurrence.count));
  const totalBaseValue = Number(editModal.form.value);
  const method = editModal.recurrence.calcMethod;
  if (!editModal.form.due_date) { alert('Preencha a data de vencimento primeiro.'); return; }
  const baseDate = parseISO(editModal.form.due_date);
  const baseComp = editModal.form.competence_date ? parseISO(editModal.form.competence_date) : baseDate;
  editModal.projected = [];
  let installmentValue = method === 'divide' ? totalBaseValue / count : totalBaseValue;
  for (let i = 0; i < count; i++) {
      const d = editModal.recurrence.interval === 'month' ? addMonths(baseDate, i) : addDays(baseDate, i * 7);
      const c = editModal.recurrence.interval === 'month' ? addMonths(baseComp, i) : addDays(baseComp, i * 7);
      editModal.projected.push({
          installment: i + 1,
          description: `${editModal.form.description} (${i+1}/${count})`,
          value: parseFloat(installmentValue.toFixed(2)),
          due_date: format(d, 'yyyy-MM-dd'),
          competence_date: format(c, 'yyyy-MM-dd'),
          status: 'em_aberto'
      });
  }
};

const saveReceivable = async () => {
    editModal.loading = true;
    editModal.error = null;
    try {
        const newAttachments = await uploadAttachments();
        const finalAttachments = [...(editModal.form.attachments || []), ...newAttachments];

        // LÓGICA RÍGIDA DE PAYLOAD: Limpando dados do SELECT para evitar BAD REQUEST
        const payload: any = {
            description: editModal.form.description,
            value: Number(editModal.form.value) || 0,
            discount: Number(editModal.form.discount) || 0,
            due_date: editModal.form.due_date,
            competence_date: editModal.form.competence_date,
            status: editModal.form.status,
            payment_date: editModal.form.status === 'pago' ? editModal.form.payment_date : null,
            chart_of_accounts_id: editModal.form.chart_of_accounts_id,
            company_id: editModal.form.company_id,
            cost_center_id: editModal.form.cost_center_id,
            bank_account_id: editModal.form.bank_account_id,
            payment_method_id: editModal.form.payment_method_id,
            notes: editModal.form.notes,
            attachments: finalAttachments
        };

        // Preservação do company_id corrigida para NOVO LANÇAMENTO
        if (!editModal.form.id && !payload.company_id && !companyStore.isGlobalView && companyStore.context) {
            payload.company_id = companyStore.context;
        }

        if (!payload.company_id) {
            throw new Error('A empresa é obrigatória. Selecione uma empresa ou mude para um contexto específico.');
        }

        // Validação se 'entity_name' (v-model do select) é um UUID (cliente da base) ou um texto livre
        const isUUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(String(editModal.form.entity_name));

        if (isUUID) {
             const client = auxData.customers.find(c => c.id === editModal.form.entity_name);
             if(client) {
                 payload.customer_id = client.id;
                 payload.entity_name = client.name;
             }
        } else {
            payload.customer_id = null;
            payload.entity_name = editModal.form.entity_name;
        }

        if(!editModal.form.id && editModal.recurrence.enabled) {
            if (editModal.projected.length === 0) throw new Error('Lista de parcelas vazia.');
            const payloads = editModal.projected.map(p => ({ ...payload, installment_number: p.installment, total_installments: editModal.recurrence.count, description: p.description, value: p.value, due_date: String(p.due_date), competence_date: String(p.competence_date), status: 'em_aberto' }));
            await supabase.from('finance_receivables').insert(payloads);

            await logBusinessEvent('Financeiro - Receber', 'INSERT', `Lançou ${payloads.length} recebimentos fixos para ${payload.entity_name}`, { total_value: payload.value, installments: payloads.length }, null, null);
        } else {
            if(editModal.form.id) {
                const { data: oldState } = await supabase.from('finance_receivables').select('*').eq('id', editModal.form.id).single();
                await supabase.from('finance_receivables').update(payload).eq('id', editModal.form.id);
                await logBusinessEvent('Financeiro - Receber', 'UPDATE', `Editou informações do recebimento de ${payload.entity_name}`, payload, editModal.form.id, oldState);
            } else {
                const { data: savedRecord, error: insertErr } = await supabase.from('finance_receivables').insert(payload).select().single();
                if (insertErr) throw insertErr;
                await logBusinessEvent('Financeiro - Receber', 'INSERT', `Lançou novo recebimento manual para ${payload.entity_name}`, payload, savedRecord.id, null);
            }
        }
        appStore.showSnackbar('Salvo!', 'success');
        editModal.show = false;
        fetchReceivables();
    } catch(e:any){
        console.error(e);
        editModal.error = e.message || 'Erro ao salvar';
    } finally {
        editModal.loading=false;
    }
};

watch(() => companyStore.context, () => {
    page.value = 1;
    fetchReceivables();
});

// --- FUNÇÃO E MODAL DE AGRUPAMENTO (NOVO) ---
const groupModal = reactive({
    show: false,
    loading: false,
    items: [] as any[],
    totalValue: 0,
    form: { chart_of_accounts_id: null as any, description: '', notes: '' },
    projected: [] as any[]
});

const groupProjTotal = computed(() => groupModal.projected.reduce((a, b) => a + Number(b.value), 0));
const groupProjDiff = computed(() => Number((groupModal.totalValue - groupProjTotal.value).toFixed(2)));

const openGroupModal = () => {
    const selItems = allFetchedItems.value.filter(i => selectedIds.value.has(i.id) && !i.is_signal);
    if(selItems.length < 2) {
        appStore.showSnackbar('Selecione ao menos 2 lançamentos comuns para agrupar.', 'warning');
        return;
    }

    groupModal.items = selItems;
    groupModal.totalValue = selItems.reduce((acc, i) => acc + (Number(i.value) - Number(i.discount || 0)), 0);

    const firstOrder = selItems.find(i => i.order_number && i.order_number !== 'S/N');
    const orderText = firstOrder ? ` (Pedido #${firstOrder.order_number})` : '';

    groupModal.form.description = `Agrupamento de ${selItems.length} lançamentos${orderText}`;
    groupModal.form.chart_of_accounts_id = selItems[0].chart_of_accounts_id;
    groupModal.form.notes = `Lançamentos originais mesclados: ${selItems.map(i => '#' + String(i.id).substring(0,5)).join(', ')}`;

    groupModal.projected = [{
        value: groupModal.totalValue,
        due_date: selItems[0].due_date,
        status: 'em_aberto'
    }];

    groupModal.show = true;
};

const addGroupProjection = () => {
    groupModal.projected.push({
        value: groupProjDiff.value > 0 ? groupProjDiff.value : 0,
        due_date: format(new Date(), 'yyyy-MM-dd'),
        status: 'em_aberto'
    });
};

const confirmGroupAction = async () => {
    if (Math.abs(groupProjDiff.value) > 0.01) {
        appStore.showSnackbar('A soma das parcelas projetadas deve ser igual ao Valor Total Selecionado.', 'warning');
        return;
    }

    groupModal.loading = true;
    try {
        // 1. Apaga os IDs selecionados originais
        const idsToDelete = groupModal.items.map(i => i.id);
        await supabase.from('finance_receivables').delete().in('id', idsToDelete);

        // 2. Cria os novos baseados no template do primeiro selecionado
        const baseItem = groupModal.items[0];
        const payloads = groupModal.projected.map((p, idx) => ({
            company_id: baseItem.company_id,
            customer_id: baseItem.customer_id,
            order_id: baseItem.order_id,
            order_number: baseItem.order_number,
            chart_of_accounts_id: groupModal.form.chart_of_accounts_id,
            description: groupModal.form.description + (groupModal.projected.length > 1 ? ` (${idx+1}/${groupModal.projected.length})` : ''),
            value: p.value,
            discount: 0,
            due_date: p.due_date,
            competence_date: p.due_date,
            status: p.status,
            payment_date: p.status === 'pago' ? format(new Date(), 'yyyy-MM-dd') : null,
            notes: groupModal.form.notes
        }));

        const { error } = await supabase.from('finance_receivables').insert(payloads);
        if(error) throw error;

        await logBusinessEvent('Financeiro - Receber', 'GROUP', `Agrupou ${idsToDelete.length} recebimentos em ${payloads.length} novas parcelas.`, { deleted_ids: idsToDelete, new_payloads: payloads }, null, null);

        appStore.showSnackbar('Lançamentos agrupados com sucesso!', 'success');
        groupModal.show = false;
        selectedIds.value.clear();
        fetchReceivables();
    } catch(e:any) {
        appStore.showSnackbar('Erro ao agrupar: ' + e.message, 'error');
    } finally {
        groupModal.loading = false;
    }
};

onMounted(() => {
    fetchAuxiliaryData();
    fetchReceivables();
    loadGridSettings();
    mjCashStore.checkActiveSession();
});
</script>

<style scoped lang="scss">
/* Layout Geral */
.receivables-layout { position: relative; }
.bg-glass-dark { background: rgba(10,10,12,0.85); }
.bg-glass-header { background: rgba(20,20,24,0.55); backdrop-filter: blur(14px); }
.border-bottom-white-05 { border-bottom: 1px solid rgba(255,255,255,0.08); }
.border-top-white-05 { border-top: 1px solid rgba(255,255,255,0.08); }
.border-white-10 { border: 1px solid rgba(255,255,255,0.1) !important; }
.controls-bar { border: 1px solid rgba(0,0,0,0.08); padding: 10px; }
.search-wrap { height: 40px; padding: 0 12px; display: flex; align-items: center; min-width: 300px; flex: 1; }

@media (max-width: 600px) {
  .search-wrap { min-width: 100%; }
}

.clean-input { border: none; outline: none; flex: 1; font-size: 12px; }

.hide-scrollbar::-webkit-scrollbar { display: none; }
.hide-scrollbar { -ms-overflow-style: none; scrollbar-width: none; }

/* Grid e Scroll */
.grid-scroll { scrollbar-gutter: stable; -webkit-overflow-scrolling: touch; }
.custom-scroll::-webkit-scrollbar { width: 8px; height: 8px; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.35); border-radius: 6px; }
.custom-scroll::-webkit-scrollbar-track { background: transparent; }

/* GRID LAYOUT FLUIDO E RESPONSIVO DINÂMICO */
.grid-header, .grid-row {
    display: grid;
    align-items: stretch;
    width: 100%;
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

.header-text { font-weight: 800; text-transform: uppercase; letter-spacing: 0.5px; line-height: 1.2; }
.center { justify-content: center; text-align: center; }

.grid-header .cell {
    min-height: 44px;
    font-weight: 800;
    text-transform: uppercase;
    letter-spacing: 0.5px;
    line-height: 1.2;
}

.list-text-11 { line-height: 1.2 !important; }

/* CONTROLE DE TAMANHO DA GRID (SM, MD, LG) */
.grid-container-sm {
   .header-text { font-size: 11px !important; }
   .list-text-11 { font-size: 12px !important; }
   .chip-3d { font-size: 10px !important; height: 22px; padding: 0 8px; }
}

.grid-container-md {
   .header-text { font-size: 14px !important; }
   .list-text-11 { font-size: 14px !important; }
   .chip-3d { font-size: 11px !important; height: 26px; padding: 0 10px; }
}

.grid-container-lg {
   .header-text { font-size: 16px !important; }
   .list-text-11 { font-size: 16px !important; }
   .chip-3d { font-size: 12px !important; height: 30px; padding: 0 12px; }
}

:deep(.v-checkbox-btn) { width: 24px !important; height: 24px !important; }
:deep(.v-checkbox-btn .v-selection-control__input) { width: 24px !important; height: 24px !important; }
:deep(.v-checkbox-btn .v-icon) { font-size: 18px !important; }
.chk-fixed { margin: 0 !important; padding: 0 !important; }

/* CARROSSEL E DARK MODE DA GRID */
.background-carousel-wrapper {
  position: absolute;
  top: 0; left: 0; width: 100%; height: 100%;
  z-index: 0;
  opacity: 0.6;
  pointer-events: none;
}

.background-overlay {
  position: absolute;
  top: 0; left: 0; width: 100%; height: 100%;
  z-index: 1;
  background: radial-gradient(circle at center, rgba(15, 15, 19, 0.4), rgba(15, 15, 19, 0.98));
  backdrop-filter: blur(8px);
}

.grid-surface-light .cell { background: #f5f7fa; color: rgba(0,0,0,0.9); border-color: rgba(0,0,0,0.12) !important; }
.grid-row-light .cell { border-color: rgba(0,0,0,0.08) !important; }
.zebra-light-a .cell { background: #ffffff; }
.zebra-light-b .cell { background: #f0f4f8; }
.grid-row-light:hover .cell { background: #e3f2fd !important; }
.grid-selected-light .cell { background: #e8f5e9 !important; }

.grid-surface-dark .cell {
  background: rgba(255,255,255,0.08) !important;
  color: rgba(255,255,255,0.80) !important;
  border-color: rgba(255,255,255,0.10) !important;
  backdrop-filter: none !important;
}

.grid-row-dark .cell {
  background: rgba(255,255,255,0.04);
  border-color: rgba(255,255,255,0.08) !important;
  color: rgba(255,255,255,0.85);
}

.zebra-dark-a .cell { background: rgba(255,255,255,0.04) !important; }
.zebra-dark-b .cell { background: rgba(255,255,255,0.015) !important; }
.grid-row-dark:hover .cell { background: rgba(255,255,255,0.07) !important; }
.grid-selected-dark .cell { background: rgba(76, 175, 80, 0.2) !important; }

.v-theme--dark { .text-grey-darken-4, .text-grey-darken-3, .text-grey-darken-2, .text-grey-darken-1, .text-grey { color: rgba(255,255,255,0.9) !important; } }
.hover-grey:hover { background-color: #f5f5f5 !important; }

/* KPI Desktop & Mobile */
.kpi-card { color: white; position: relative; min-height: 110px; overflow: hidden; border-radius: 8px;}
.kpi-bg-icon { position: absolute; right: -20px; bottom: -20px; opacity: 0.15; transform: rotate(-15deg); }
.kpi-bg-icon .v-icon { font-size: 100px; color: white; }
.kpi-bg-icon-mobile { position: absolute; right: -5px; bottom: -5px; opacity: 0.15; transform: rotate(-10deg); }
.kpi-bg-icon-mobile .v-icon { font-size: 60px; color: white; }
.text-shadow-sm { text-shadow: 0 2px 4px rgba(0,0,0,0.2); }

.bg-gradient-info { background: linear-gradient(135deg, #0288d1, #005b9f); }
.bg-gradient-green { background: linear-gradient(135deg, #2e7d32, #1b5e20); }
.bg-gradient-red { background: linear-gradient(135deg, #c62828, #8e0000); }
.bg-gradient-purple { background: linear-gradient(135deg, #7b1fa2, #4a148c); }
.bg-gradient-warning { background: linear-gradient(135deg, #FFB300, #F57F17); }
.kpi-label { font-size: 12px; font-weight: 900; letter-spacing: .2px; }
.kpi-value { font-size: 22px; font-weight: 900; }
.kpi-footer { font-size: 11px; opacity: .9; font-weight: 700; }

.pill-ref { font-size: 12px !important; font-weight: 900; font-family: monospace; padding: 4px 6px; border-radius: 0px; white-space: nowrap; }
.underline-ref { text-decoration: underline !important; }

.solid-chip { display: inline-flex; align-items: center; justify-content: center; height: 28px; padding: 0 12px; font-weight: 900; color: #fff; text-transform: uppercase; white-space: nowrap; }
.chip-status { min-width: 70px; }
.chip-company { background: #455a64; }
.chip-success { background: #2e7d32; }
.chip-warn { background: #f57f17; }
.chip-danger { background: #c62828; }

.actions-inline { display: flex; gap: 4px; justify-content: center; flex-wrap: nowrap !important; }
.action-btn { width: 28px !important; height: 28px !important; color: #fff !important; }
.action-edit { background: #1976d2 !important; }
.action-pay { background: #2e7d32 !important; }
.action-revert { background: #f57f17 !important; }
.action-del { background: #c62828 !important; }

/* EFEITOS 3D */
.btn-3d { border-radius: 6px !important; box-shadow: 0 3px 5px rgba(0,0,0,0.15), inset 0 2px 0 rgba(255,255,255,0.25) !important; transition: transform 0.1s ease, box-shadow 0.1s ease; text-transform: none !important; }
.btn-3d:active { transform: translateY(2px); box-shadow: 0 1px 2px rgba(0,0,0,0.15), inset 0 1px 0 rgba(255,255,255,0.2) !important; }
.chip-3d { border-radius: 6px !important; box-shadow: 0 2px 4px rgba(0,0,0,0.12), inset 0 1px 0 rgba(255,255,255,0.25) !important; text-shadow: 0 1px 2px rgba(0,0,0,0.25); }

.ui-field :deep(.v-field) { border-radius: 0 !important; }
.row-gap { row-gap: 14px; }
.fixed-dialog { overflow: hidden !important; }
.absolute-fill { height: 100%; overflow-y: auto; }

/* Feedback Toast */
.feedback-toast { position: fixed; bottom: 24px; right: 24px; padding: 16px 20px; border-radius: 8px; box-shadow: 0 10px 30px rgba(0,0,0,0.3); z-index: 9999; min-width: 320px; max-width: 400px; animation: slideUp 0.3s ease-out; }
.feedback-toast.is-success { background: #2e7d32; }
.feedback-toast.is-error { background: #c62828; }
.icon-box { width: 32px; height: 32px; display: flex; align-items: center; justify-content: center; background: rgba(255,255,255,0.2); border-radius: 50%; }
.lh-12 { line-height: 1.2; }

/* Floating Selection Bar */
.selection-island-wrapper { position: absolute; bottom: 30px; left: 0; right: 0; display: flex; justify-content: center; z-index: 100; pointer-events: none; }
.selection-island { pointer-events: auto; background: #1e1e24; border-radius: 12px; padding: 8px 16px; display: flex; align-items: center; gap: 8px; border: 1px solid rgba(255,255,255,0.1); box-shadow: 0 10px 30px rgba(0,0,0,0.3); }

.bg-white-20 { background: rgba(255,255,255,0.2); }
@keyframes slideUp { from { transform: translateY(20px); opacity: 0; } to { transform: translateY(0); opacity: 1; } }

.flex-grow-1.overflow-hidden > .v-card.flex-grow-1 { border: 1px solid rgba(0,0,0,0.12) !important; }
.bg-glass-dark .flex-grow-1.overflow-hidden > .v-card.flex-grow-1 { border: 1px solid rgba(255,255,255,0.12) !important; }

/* CABEÇALHO FIXO */
.sticky-head { position: sticky; top: 0; z-index: 20; box-shadow: 0 8px 16px -4px rgba(0, 0, 0, 0.12); }
.bg-glass-dark .sticky-head { box-shadow: 0 8px 20px -4px rgba(0, 0, 0, 0.4); }

.pulse-success { animation: pulse-success-scale 2s infinite; }
@keyframes pulse-success-scale { 0% { transform: scale(1); opacity: 0.8; color: #00695C; } 50% { transform: scale(1.2); opacity: 1; color: #00BFA5; } 100% { transform: scale(1); opacity: 0.8; color: #00695C; } }
.pulse-box { animation: pulse-box-glow 2s infinite; }
@keyframes pulse-box-glow { 0% { box-shadow: 0 0 0 0 rgba(0, 191, 165, 0.4); } 70% { box-shadow: 0 0 0 6px rgba(0, 191, 165, 0); } 100% { box-shadow: 0 0 0 0 rgba(0, 191, 165, 0); } }

:deep(.tooltip-conciliated) { background: rgba(10, 10, 12, 0.95) !important; border: 1px solid #1DE9B6 !important; box-shadow: 0 4px 15px rgba(0, 191, 165, 0.3) !important; backdrop-filter: blur(10px); }
</style>
