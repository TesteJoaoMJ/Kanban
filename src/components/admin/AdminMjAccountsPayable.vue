<template>
  <div
    class="payables-layout font-sans fill-height d-flex flex-column relative overflow-hidden"
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
            <span class="font-weight-bold">Contas a Pagar</span>
          </div>
          <div class="d-flex align-center gap-2 mt-1">
             <div class="text-h6 font-weight-black tracking-tight leading-none" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">
                Contas a Pagar
             </div>
          </div>

          <div class="d-flex align-center gap-3 mt-3 overflow-x-auto hide-scrollbar pb-1 w-100">
             <v-btn
                v-for="btn in contextButtons"
                :key="btn.id"
                size="x-small"
                height="24"
                :variant="companyStore.context === btn.id ? 'flat' : 'tonal'"
                :color="companyStore.context === btn.id ? (btn.isHolding ? 'purple' : 'error') : 'grey'"
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
                color="blue-grey-darken-3"
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
            <v-list density="compact" nav>
              <v-list-item @click="generateReport('pdf')" prepend-icon="mdi-file-pdf-box" title="Exportar PDF (Analítico)" class="text-red-darken-3 font-weight-bold"></v-list-item>
              <v-list-item @click="generateReport('excel')" prepend-icon="mdi-microsoft-excel" title="Exportar Excel (Dados)" class="text-green-darken-3 font-weight-bold"></v-list-item>
            </v-list>
          </v-menu>

          <v-btn
            color="purple-darken-2"
            variant="flat"
            class="btn-3d px-3 px-md-4 font-weight-bold text-caption text-uppercase letter-spacing-1 flex-shrink-0"
            prepend-icon="mdi-calendar-sync"
            height="40"
            @click="openFixedAccountModal"
          >
            Lançar Fixo
          </v-btn>

          <v-btn
            color="error"
            variant="flat"
            class="btn-3d px-3 px-md-4 font-weight-bold text-caption text-uppercase letter-spacing-1 flex-shrink-0"
            prepend-icon="mdi-plus"
            height="40"
            @click="openNewPayableModal"
          >
            Novo Pagamento
          </v-btn>
        </div>
      </div>

      <v-expand-transition>
        <div v-if="pendingSyncCount > 0 && !isMobileFullscreen" class="px-4 px-md-6 pt-4 pb-0 flex-shrink-0">
          <v-alert
            color="orange-darken-2"
            variant="tonal"
            density="compact"
            class="alert-rect border-orange-darken-2"
            icon="mdi-cloud-search-outline"
            closable
            @click:close="pendingSyncCount = 0"
          >
            <div class="d-flex align-center justify-space-between w-100 flex-wrap" style="gap: 14px;">
              <div class="text-body-2">
                <span class="font-weight-bold">Atualizações Disponíveis:</span>
                Encontramos <strong class="text-decoration-underline">{{ pendingSyncCount }} registros</strong> com status atualizado ou novos no ERP.
              </div>
              <v-btn variant="flat" color="orange-darken-2" height="36" class="btn-3d px-4 font-weight-bold text-white" @click="showSyncModal = true">
                Ver e Sincronizar
              </v-btn>
            </div>
          </v-alert>
        </div>
      </v-expand-transition>

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
                :class="kpiModel === i ? 'bg-error w-3 h-3 elevation-2' : 'bg-grey-lighten-2 w-2 h-2 opacity-50'"
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
                        color="blue-grey-darken-3"
                        variant="flat"
                        class="btn-3d flex-shrink-0 px-4"
                        height="44"
                        prepend-icon="mdi-menu"
                    >
                        Ações
                    </v-btn>
                </template>
                <v-list density="compact" nav class="py-2" width="260">
                    <v-list-item @click="mobileFiltersOpen = true" prepend-icon="mdi-filter-variant" title="Filtros Avançados" class="text-primary font-weight-bold mb-2 bg-blue-lighten-5 rounded"></v-list-item>

                    <v-list-item @click="toggleConciliatedFilter" :prepend-icon="filters.onlyConciliated ? 'mdi-shield-check' : 'mdi-shield-outline'" title="Apenas Conciliados" :class="filters.onlyConciliated ? 'text-teal-darken-3 font-weight-bold bg-teal-lighten-5 rounded mb-2' : 'mb-2'"></v-list-item>

                    <v-divider class="my-2"></v-divider>
                    <div class="text-caption font-weight-bold ml-4 mb-1 text-grey">Período Rápido</div>
                    <v-list-item @click="applyPreset('today')" title="Hoje" density="compact"></v-list-item>
                    <v-list-item @click="applyPreset('week')" title="Esta Semana" density="compact"></v-list-item>
                    <v-list-item @click="applyPreset('month')" title="Este Mês" density="compact"></v-list-item>
                    <v-list-item @click="applyPreset('year')" title="Este Ano" density="compact"></v-list-item>

                    <v-divider class="my-2"></v-divider>
                    <div class="text-caption font-weight-bold ml-4 mb-1 text-grey">Operações</div>
                    <v-list-item @click="openNewPayableModal" prepend-icon="mdi-plus" title="Novo Pagamento" class="text-error font-weight-bold"></v-list-item>
                    <v-list-item @click="openFixedAccountModal" prepend-icon="mdi-calendar-sync" title="Lançar Fixo"></v-list-item>
                    <v-list-item @click="generateReport('pdf')" prepend-icon="mdi-file-chart" title="Relatórios"></v-list-item>
                    <v-list-item @click="showSyncModal = true" prepend-icon="mdi-cloud-sync" title="Sincronizar ERP"></v-list-item>
                    <v-list-item @click="showImportModal = true" prepend-icon="mdi-upload" title="Importar"></v-list-item>
                    <v-divider class="my-2"></v-divider>
                    <v-list-item @click="gridSettings.showModal = true" prepend-icon="mdi-table-cog" title="Configurar Grid"></v-list-item>
                </v-list>
            </v-menu>

            <div class="flex-grow-1 relative search-wrap rounded bg-white border d-flex align-center" style="height: 44px;">
                <input
                  v-model="filters.search"
                  type="text"
                  placeholder="Pesquisar..."
                  class="clean-input w-100 h-100 px-3 font-weight-bold"
                  style="outline: none;"
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
          :class="themeStore.currentMode === 'light' ? 'controls-light' : 'controls-dark'"
          style="gap: 10px;"
        >
          <div class="d-flex flex-column flex-md-row align-start align-md-center justify-space-between" style="gap: 10px;">
            <div class="d-flex align-center flex-wrap w-100 w-md-auto" style="gap: 10px;">
              <v-menu location="bottom start" :close-on-content-click="true">
                <template v-slot:activator="{ props }">
                  <v-btn v-bind="props" variant="outlined" class="btn-3d flex-grow-1 flex-md-grow-0" height="40" prepend-icon="mdi-calendar-range" color="error">
                    {{ quickPeriodLabel }}
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

              <div class="period-nav d-flex align-center justify-center flex-grow-1 flex-md-grow-0" :class="themeStore.currentMode === 'light' ? 'period-nav-light' : 'period-nav-dark'">
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
                :color="filters.onlyConciliated ? 'teal-darken-3' : (themeStore.currentMode === 'light' ? 'grey-darken-2' : 'white')"
                :class="filters.onlyConciliated ? 'bg-teal-lighten-5 border-teal' : ''"
                @click="toggleConciliatedFilter"
              >
                <v-icon start size="small">{{ filters.onlyConciliated ? 'mdi-shield-check' : 'mdi-shield-outline' }}</v-icon>
                <span class="d-none d-sm-inline">Conciliados</span>
              </v-btn>

              <div class="search-wrap d-flex align-center flex-grow-1 flex-md-grow-0" :class="themeStore.currentMode === 'light' ? 'search-light' : 'search-dark'">
                <v-icon :color="themeStore.currentMode === 'light' ? 'grey-darken-1' : 'white-70'">mdi-magnify</v-icon>
                <input
                  v-model="filters.search"
                  type="text"
                  placeholder="Pesquisar..."
                  class="clean-input flex-grow-1"
                  @keyup.enter="handleSearchEnter"
                />
              </div>

              <v-menu v-model="filtersDropdownOpen" location="bottom end" :close-on-content-click="false" :z-index="2500">
                <template v-slot:activator="{ props }">
                  <v-btn
                    v-bind="props"
                    variant="outlined"
                    class="btn-3d"
                    height="40"
                    prepend-icon="mdi-filter-variant"
                    :color="activeFilterCount > 0 ? 'error' : (themeStore.currentMode === 'light' ? 'grey-darken-2' : 'white')"
                  >
                    Filtros
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
                        <v-chip v-for="s in ['pendente','pago','atrasado']" :key="s" :color="filters.status.includes(s) ? (s === 'pago' ? 'success' : (s === 'atrasado' ? 'error' : 'warning')) : 'grey'" :variant="filters.status.includes(s) ? 'flat' : 'outlined'" class="solid-chip cursor-pointer" @click="toggleStatusFilter(s)">
                          <v-icon start size="small" v-if="filters.status.includes(s)">mdi-check</v-icon>
                          {{ s === 'pendente' ? 'Aberto' : (s === 'pago' ? 'Pago' : 'Atrasado') }}
                        </v-chip>
                      </div>
                    </v-col>
                  </v-row>

                  <div class="d-flex justify-end mt-6">
                    <v-btn variant="flat" class="btn-3d w-100 font-weight-bold" height="42" color="error" @click="applyFiltersFromDropdown">
                      <v-icon start>mdi-magnify</v-icon> Aplicar Filtros
                    </v-btn>
                  </div>
                </v-card>
              </v-menu>

              <v-menu location="bottom end" :close-on-content-click="true">
                <template v-slot:activator="{ props }">
                  <v-btn v-bind="props" variant="flat" class="btn-3d" height="40" prepend-icon="mdi-dots-vertical" color="error">
                   <span class="d-none d-sm-inline">Ações</span>
                   <v-icon end size="small" class="d-none d-sm-inline">mdi-chevron-down</v-icon>
                  </v-btn>
                </template>

                <v-card class="rounded-0" min-width="260">
                  <v-list density="compact" nav>
                    <v-list-item @click="openNewPayableModal" prepend-icon="mdi-plus">
                      <v-list-item-title>Novo Pagamento</v-list-item-title>
                    </v-list-item>
                    <v-list-item @click="openFixedAccountModal" prepend-icon="mdi-calendar-sync" class="text-purple-darken-2">
                       <v-list-item-title class="font-weight-bold">Lançar Conta Fixa</v-list-item-title>
                    </v-list-item>
                    <v-divider class="my-2"></v-divider>
                    <v-list-item @click="showSyncModal = true" prepend-icon="mdi-cloud-sync">
                      <v-list-item-title>Sincronizar ERP</v-list-item-title>
                    </v-list-item>
                    <v-list-item @click="fetchPayables" prepend-icon="mdi-refresh">
                      <v-list-item-title>Atualizar Lista</v-list-item-title>
                    </v-list-item>
                    <v-list-item @click="showImportModal = true" prepend-icon="mdi-upload">
                      <v-list-item-title>Importar</v-list-item-title>
                    </v-list-item>
                    <v-list-item @click="openDeleteModal" prepend-icon="mdi-trash-can-outline" class="text-error font-weight-bold">
                        <v-list-item-title>Exclusão em Massa</v-list-item-title>
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
          :class="themeStore.currentMode === 'light' ? 'bg-white shadow-sm' : 'glass-card border-white-05'"
          :elevation="0"
        >
          <div v-if="isMobileFullscreen" class="bg-error text-white px-3 py-3 d-flex align-center justify-space-between flex-shrink-0 gap-3 elevation-2 z-30">
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
                 <v-badge v-if="activeFilterCount > 0" :content="activeFilterCount" color="white" text-color="red" dot floating>
                    <v-icon>mdi-filter-variant</v-icon>
                 </v-badge>
                 <v-icon v-else>mdi-filter-variant</v-icon>
             </v-btn>
          </div>

          <div v-if="!mobile" class="grid-scroll flex-grow-1 overflow-auto custom-scroll relative">
            <div
              class="grid-header sticky-head"
              :class="[themeStore.currentMode === 'light' ? 'grid-surface-light' : 'grid-surface-dark']"
              :style="{ gridTemplateColumns: computedGridTemplate }"
            >
              <div class="cell cell-check center">
                <v-checkbox-btn
                  :model-value="areAllSelected"
                  @update:model-value="toggleSelectAll"
                  density="compact"
                  color="error"
                  class="chk-fixed"
                ></v-checkbox-btn>
              </div>

              <div class="cell center header-text" v-if="isColumnVisible('ref')">Ref.</div>
              <div class="cell header-text" v-if="isColumnVisible('supplier')">Beneficiário / Fornecedor</div>
              <div class="cell header-text" v-if="isColumnVisible('desc')">Descrição</div>
              <div class="cell header-text" v-if="isColumnVisible('chart')">Plano de Contas</div>
              <div class="cell center header-text" v-if="isColumnVisible('company')">Empresa</div>
              <div class="cell center header-text" v-if="isColumnVisible('bank')">Banco</div>
              <div class="cell center header-text" v-if="isColumnVisible('date')">Vencimento</div>
              <div class="cell center header-text" v-if="isColumnVisible('val')">Valor</div>

              <div class="cell center header-text" v-if="isColumnVisible('conciliated')">Conciliação</div>

              <div class="cell center header-text" v-if="isColumnVisible('status')">Status</div>
              <div class="cell center header-text" v-if="isColumnVisible('cost_center')">Centro Custo</div>
              <div class="cell header-text" v-if="isColumnVisible('notes')">Observações</div>

              <div class="cell center header-text">Ações</div>
            </div>

            <div v-if="loading" class="d-flex flex-column justify-center align-center h-100 py-10 min-w-full">
              <v-progress-circular indeterminate color="error" size="32" width="3"></v-progress-circular>
              <span class="text-caption mt-2 font-weight-bold opacity-60">Carregando contas...</span>
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
                themeStore.currentMode === 'light' ? 'grid-row-light' : 'grid-row-dark',
                zebraClass(index),
                selectedIds.has(item.id) ? (themeStore.currentMode === 'light' ? 'grid-selected-light' : 'grid-selected-dark') : ''
              ]"
              :style="{ gridTemplateColumns: computedGridTemplate }"
            >
              <div class="cell cell-check center">
                <v-checkbox-btn
                  :model-value="selectedIds.has(item.id)"
                  @update:model-value="toggleSelection(item.id)"
                  density="compact"
                  color="error"
                  class="chk-fixed"
                ></v-checkbox-btn>
              </div>

              <div class="cell center" v-if="isColumnVisible('ref')">
                <span class="pill-ref" :class="item.gestao_click_id ? 'text-blue-darken-2 bg-blue-lighten-5' : 'bg-grey-lighten-4'">
                  {{ getRefNumber(item) }}
                </span>
              </div>

              <div class="cell" v-if="isColumnVisible('supplier')">
                <div class="text-truncate list-text-11 font-weight-medium text-grey-darken-4" :title="getSupplierName(item)">
                  {{ getSupplierName(item) }}
                </div>
              </div>

              <div class="cell" v-if="isColumnVisible('desc')">
                <div class="d-flex flex-column" style="min-width: 0;">
                    <div class="text-truncate list-text-11 text-grey-darken-4 font-weight-medium" :title="item.description">
                    {{ item.description }}
                    </div>
                    <div v-if="hasAttachments(item)" class="mt-1 d-flex">
                        <v-btn
                          variant="tonal"
                          size="x-small"
                          color="blue-darken-2"
                          height="20"
                          class="px-2 font-weight-bold btn-3d"
                          style="text-transform: none; letter-spacing: 0;"
                          @click.stop="openAttachment(item)"
                        >
                            <v-icon start size="12" class="mr-1">mdi-paperclip</v-icon>
                            Anexo
                        </v-btn>
                    </div>
                </div>
              </div>

              <div class="cell" v-if="isColumnVisible('chart')">
                <span class="text-truncate list-text-11 font-weight-medium text-grey-darken-3" :title="getChartName(item.chart_of_accounts_id)">
                  {{ getChartName(item.chart_of_accounts_id) || '-' }}
                </span>
              </div>

              <div class="cell center" v-if="isColumnVisible('company')">
                <span v-if="item.company_id" class="solid-chip chip-company chip-3d">
                  {{ getCompanyName(item.company_id) }}
                </span>
                <span v-else class="list-text-11 font-weight-medium opacity-60">-</span>
              </div>

              <div class="cell center" v-if="isColumnVisible('bank')">
                <span class="text-truncate list-text-11 font-weight-medium text-grey-darken-3" :title="getBankAccountName(item.bank_account_id)">
                  {{ getBankAccountName(item.bank_account_id) }}
                </span>
              </div>

              <div class="cell center" v-if="isColumnVisible('date')">
                <span class="list-text-11 font-mono" :class="isOverdue(item) ? 'text-error font-weight-black' : 'text-grey-darken-4 font-weight-medium'">
                  {{ formatDateSafe(item.due_date) }}
                </span>
              </div>

              <div class="cell center" v-if="isColumnVisible('val')">
                <span class="list-text-11 font-mono font-weight-black text-grey-darken-4">{{ formatCurrency(item.value - (item.discount || 0)) }}</span>
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
                <div v-else class="rounded-circle pa-1 d-flex align-center justify-center border border-grey-lighten-2 opacity-50" style="background: rgba(0,0,0,0.02)">
                     <v-icon size="16" color="grey-darken-1">mdi-shield-outline</v-icon>
                </div>
              </div>

              <div class="cell center" v-if="isColumnVisible('status')">
                <span class="solid-chip chip-status chip-3d" :class="getStatusChipClass(item)">
                  {{ getStatusLabel(item) }}
                </span>
              </div>

              <div class="cell center" v-if="isColumnVisible('cost_center')">
                  <span class="text-truncate list-text-11">{{ getCostCenterName(item.cost_center_id) }}</span>
              </div>
              <div class="cell" v-if="isColumnVisible('notes')">
                  <span class="text-truncate list-text-11 opacity-75">{{ item.notes || item.observation || '-' }}</span>
              </div>

              <div class="cell center">
                <div class="actions-inline">
                  <v-btn icon size="small" class="action-btn action-edit btn-3d" @click.stop="openEditModal(item)" title="Editar" variant="flat"><v-icon size="16">mdi-pencil</v-icon></v-btn>
                  <v-btn v-if="item.status !== 'pago'" icon size="small" class="action-btn action-pay btn-3d" @click.stop="openStatusModal(item)" title="Pagar" variant="flat"><v-icon size="16">mdi-cash-check</v-icon></v-btn>
                  <v-btn v-else icon size="small" class="action-btn action-revert btn-3d" @click.stop="openStatusModal(item)" title="Estornar" variant="flat"><v-icon size="16">mdi-undo-variant</v-icon></v-btn>

                  <v-tooltip text="Imprimir Comprovante" location="top" content-class="custom-tooltip" v-if="item.status === 'pago'">
                      <template v-slot:activator="{ props }">
                          <v-btn v-bind="props" icon size="small" class="action-btn bg-blue-grey-darken-2 btn-3d" @click.stop="handlePrintReceipt(item)" :loading="printLoadingId === item.id" variant="flat">
                              <v-icon size="16">mdi-printer</v-icon>
                          </v-btn>
                      </template>
                  </v-tooltip>

                  <v-btn icon size="small" class="action-btn action-del btn-3d" @click.stop="deletePayable(item)" title="Excluir" variant="flat"><v-icon size="16">mdi-trash-can-outline</v-icon></v-btn>
                </div>
              </div>
            </div>
          </div>

          <div v-else class="flex-grow-1 overflow-y-auto bg-grey-lighten-4 pb-12 custom-scroll">
              <div v-if="loading" class="d-flex flex-column align-center justify-center py-8">
                  <v-progress-circular indeterminate color="error"></v-progress-circular>
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
                    class="bg-white rounded-lg border-thin pa-4 elevation-1 relative overflow-hidden"
                    @click="toggleSelection(item.id)"
                 >
                    <div v-if="selectedIds.has(item.id)" class="absolute top-0 right-0 p-2 bg-error rounded-bl-xl shadow-md z-10">
                        <v-icon size="small" color="white">mdi-check</v-icon>
                    </div>

                    <div class="d-flex justify-space-between align-center mb-2">
                        <div class="d-flex align-center gap-1">
                            <v-chip size="x-small" color="grey-lighten-3" class="font-weight-black text-grey-darken-3 chip-3d">
                                Ref: {{ getRefNumber(item) }}
                            </v-chip>
                            <v-chip v-if="item.gestao_click_id" size="x-small" color="blue-lighten-4" class="text-blue-darken-4 font-weight-bold chip-3d">
                                ERP
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

                            <v-chip size="small" :color="getStatusChipClass(item).replace('chip-', '')" variant="tonal" class="font-weight-black text-uppercase px-2 chip-3d" style="height: 20px; font-size: 10px;">
                                {{ getStatusLabel(item) }}
                            </v-chip>
                        </div>
                    </div>

                    <div class="mb-3">
                        <div class="text-subtitle-1 font-weight-black text-grey-darken-4 leading-tight mb-1">
                            {{ getSupplierName(item) }}
                        </div>
                        <div class="text-caption text-grey text-truncate mb-2">
                            {{ item.description }}
                        </div>

                        <div class="d-flex align-end justify-space-between mt-2">
                             <div class="d-flex flex-column">
                                 <span class="text-[10px] font-weight-bold text-grey uppercase tracking-wide">Vencimento</span>
                                 <div class="text-body-2 font-mono font-weight-bold d-flex align-center" :class="isOverdue(item) ? 'text-red-darken-1' : 'text-grey-darken-2'">
                                     <v-icon size="14" class="mr-1">mdi-calendar</v-icon>
                                     {{ formatDateSafe(item.due_date) }}
                                 </div>
                             </div>

                             <div class="text-right">
                                 <span class="text-[10px] font-weight-bold text-grey uppercase tracking-wide">Valor</span>
                                 <div class="text-h6 font-weight-black leading-none text-red-darken-2">
                                    {{ formatCurrency(item.value - (item.discount || 0)) }}
                                 </div>
                             </div>
                        </div>
                    </div>

                    <v-divider class="mb-3 border-opacity-50"></v-divider>

                    <div class="d-flex gap-2">
                         <v-btn
                            class="flex-grow-1 rounded text-grey-darken-3 font-weight-bold btn-3d"
                            variant="flat"
                            color="grey-lighten-4"
                            height="36"
                            @click.stop="openEditModal(item)"
                         >
                            <v-icon size="18" class="mr-1">mdi-pencil</v-icon> Editar
                         </v-btn>

                         <v-btn
                            v-if="item.status !== 'pago'"
                            class="flex-grow-1 rounded font-weight-bold btn-3d"
                            variant="flat"
                            color="green-darken-1"
                            height="36"
                            @click.stop="openStatusModal(item)"
                         >
                            <v-icon size="18" class="mr-1">mdi-cash-check</v-icon> Pagar
                         </v-btn>

                         <v-btn
                            v-else
                            class="flex-grow-1 rounded text-orange-darken-4 font-weight-bold btn-3d"
                            variant="flat"
                            color="orange-lighten-4"
                            height="36"
                            @click.stop="openStatusModal(item)"
                         >
                            <v-icon size="18" class="mr-1">mdi-undo</v-icon> Estornar
                         </v-btn>

                         <v-btn
                            v-if="item.status === 'pago'"
                            class="flex-grow-0 rounded font-weight-bold btn-3d"
                            variant="flat"
                            color="blue-grey-darken-2"
                            height="36"
                            min-width="36"
                            width="36"
                            @click.stop="handlePrintReceipt(item)"
                            :loading="printLoadingId === item.id"
                            title="Imprimir Comprovante"
                         >
                            <v-icon size="18">mdi-printer</v-icon>
                         </v-btn>
                    </div>
                 </div>
              </div>
          </div>

          <div class="flex-shrink-0 border-t px-4 py-2 d-flex flex-column flex-md-row align-center justify-space-between bg-white z-20">
            <div class="d-flex align-center justify-space-between w-100 w-md-auto mb-2 mb-md-0">
               <div class="text-caption opacity-80 cursor-pointer" @click="showLogs = !showLogs">
                 <strong>{{ totalItems }}</strong> registros
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
              active-color="error"
              variant="tonal"
              size="small"
              @update:model-value="fetchPayables"
            ></v-pagination>
          </div>

          <v-expand-transition>
            <div v-if="showLogs" class="bg-black text-green-accent-3 font-mono text-caption pa-3 border-t overflow-auto" style="max-height: 150px; line-height: 1.4;">
              <div class="font-weight-bold mb-1 border-b border-green-900 pb-1">CONSOLE DE CONTAS A PAGAR</div>
              <div class="d-flex justify-space-between flex-column flex-md-row">
                <div>
                  <div>> Query Status: [{{ filters.status.join(', ') || 'ALL' }}]</div>
                  <div>> Query Date: {{ dateRange.start }} até {{ dateRange.end }}</div>
                  <div v-if="filters.search">> Search Term: "{{ filters.search }}"</div>
                </div>
                <div class="text-left text-md-right mt-2 mt-md-0">
                  <div>TOTAL LISTADO: {{ items.length }}</div>
                  <div class="text-blue-lighten-2">ORIGEM ERP (Gestão): {{ logsData.erpCount }}</div>
                  <div class="text-orange-lighten-2">ORIGEM INTERNA: {{ logsData.internalCount }}</div>
                  <div class="font-weight-black mt-1">SOMA VISÍVEL: {{ formatCurrency(logsData.sumValue) }}</div>
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
            <v-btn prepend-icon="mdi-check-all" variant="text" color="green-accent-2" height="36" class="font-weight-bold text-capitalize" @click="bulkUpdateStatus('pago')">Pagar</v-btn>
            <v-btn prepend-icon="mdi-undo" variant="text" color="yellow-accent-2" height="36" class="font-weight-bold text-capitalize" @click="bulkUpdateStatus('pendente')">Estornar</v-btn>
            <v-divider vertical class="border-white-20 mx-1"></v-divider>
            <v-btn prepend-icon="mdi-trash-can-outline" variant="flat" color="red-darken-1" height="36" class="font-weight-bold px-4 btn-3d" @click="deleteSelected">Excluir</v-btn>
          </div>
        </div>
      </div>
    </v-scale-transition>

    <v-dialog v-model="mobileFiltersOpen" fullscreen transition="dialog-bottom-transition" scrim="black">
        <v-card class="d-flex flex-column bg-grey-lighten-5 h-100">
            <div class="px-4 py-3 bg-white d-flex align-center justify-space-between border-b flex-shrink-0">
                <span class="text-h6 font-weight-black">Filtros Avançados</span>
                <div class="d-flex align-center">
                    <v-btn variant="text" color="error" size="small" class="mr-2 font-weight-bold" @click="clearFilters">Limpar</v-btn>
                    <v-btn icon="mdi-close" variant="text" @click="mobileFiltersOpen = false"></v-btn>
                </div>
            </div>

            <div class="flex-grow-1 overflow-y-auto pa-4">
                 <div class="text-caption font-weight-bold mb-1">Considerar Data de:</div>
                 <v-btn-toggle v-model="filters.dateType" density="compact" color="error" mandatory class="w-100 d-flex mb-4" divided variant="outlined">
                    <v-btn value="due_date" class="flex-grow-1 text-caption font-weight-bold">Vencimento</v-btn>
                    <v-btn value="payment_date" class="flex-grow-1 text-caption font-weight-bold">Pagamento</v-btn>
                 </v-btn-toggle>

                 <v-row dense class="row-gap">
                    <v-col cols="6"><v-text-field v-model="filters.customStart" label="De" type="date" variant="outlined" density="comfortable" bg-color="white" hide-details class="ui-field" /></v-col>
                    <v-col cols="6"><v-text-field v-model="filters.customEnd" label="Até" type="date" variant="outlined" density="comfortable" bg-color="white" hide-details class="ui-field" /></v-col>
                    <v-col cols="12"><v-autocomplete v-model="filters.supplierId" :items="auxData.suppliers" item-title="name" item-value="id" label="Fornecedor" variant="outlined" density="comfortable" bg-color="white" hide-details clearable class="ui-field" /></v-col>
                    <v-col cols="12"><v-autocomplete v-model="filters.employeeId" :items="auxData.employees" item-title="name" item-value="id" label="Funcionário" variant="outlined" density="comfortable" bg-color="white" hide-details clearable class="ui-field" /></v-col>
                    <v-col cols="12"><v-autocomplete v-model="filters.chartOfAccountsId" :items="auxData.chartOfAccounts" item-title="name" item-value="id" label="Plano de Contas" variant="outlined" density="comfortable" bg-color="white" hide-details clearable class="ui-field" /></v-col>

                    <v-col cols="6"><v-text-field v-model.number="filters.minValue" label="Valor Mín. (R$)" type="number" variant="outlined" density="comfortable" bg-color="white" hide-details class="ui-field" prefix="R$" /></v-col>
                    <v-col cols="6"><v-text-field v-model.number="filters.maxValue" label="Valor Máx. (R$)" type="number" variant="outlined" density="comfortable" bg-color="white" hide-details class="ui-field" prefix="R$" /></v-col>

                    <v-col cols="12">
                        <div class="text-caption font-weight-black opacity-70 mb-2 mt-2">Auditoria Bancária</div>
                        <v-chip :color="filters.onlyConciliated ? 'teal-darken-3' : 'grey'" :variant="filters.onlyConciliated ? 'flat' : 'outlined'" class="solid-chip cursor-pointer chip-3d" @click="filters.onlyConciliated = !filters.onlyConciliated">
                            <v-icon start size="small" v-if="filters.onlyConciliated">mdi-check</v-icon>
                            <v-icon start size="small" v-else>mdi-shield-outline</v-icon>
                            Somente Conciliados (OFX)
                        </v-chip>
                    </v-col>

                    <v-col cols="12">
                      <div class="text-caption font-weight-black opacity-70 mb-2">Status</div>
                      <div class="d-flex flex-wrap" style="gap: 8px;">
                        <v-chip v-for="s in ['pendente','pago','atrasado']" :key="s" :color="filters.status.includes(s) ? (s === 'pago' ? 'success' : (s === 'atrasado' ? 'error' : 'warning')) : 'grey'" :variant="filters.status.includes(s) ? 'flat' : 'outlined'" class="solid-chip cursor-pointer chip-3d" @click="toggleStatusFilter(s)">
                          <v-icon start size="small" v-if="filters.status.includes(s)">mdi-check</v-icon>
                          {{ s === 'pendente' ? 'Aberto' : (s === 'pago' ? 'Pago' : 'Atrasado') }}
                        </v-chip>
                      </div>
                    </v-col>
                 </v-row>
            </div>

            <div class="pa-4 bg-white border-t flex-shrink-0">
                <v-btn block color="error" size="large" variant="flat" class="font-weight-bold btn-3d" @click="applyFiltersFromDropdown(); mobileFiltersOpen = false">
                    Aplicar Filtros
                </v-btn>
            </div>
        </v-card>
    </v-dialog>

    <v-dialog v-model="gridSettings.showModal" max-width="500" scrim="black opacity-70">
        <v-card class="rounded-lg overflow-hidden" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-grey-darken-4 text-white'">
            <div class="px-6 py-4 border-b d-flex align-center justify-space-between" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5' : 'bg-grey-darken-3'">
                <div>
                    <div class="text-caption font-weight-black opacity-70 text-uppercase">Personalização</div>
                    <div class="text-h6 font-weight-black">Configurar Grid</div>
                </div>
                <v-btn icon variant="text" @click="gridSettings.showModal = false"><v-icon>mdi-close</v-icon></v-btn>
            </div>
            <div class="pa-6">
                <div class="text-subtitle-2 font-weight-bold mb-3 text-grey-darken-2" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-2' : 'text-white'">Tamanho do Texto</div>
                <v-btn-toggle v-model="gridSettings.textSize" density="compact" color="primary" mandatory class="w-100 d-flex mb-6" divided variant="outlined">
                    <v-btn value="small" class="flex-grow-1 text-caption font-weight-bold">Pequeno</v-btn>
                    <v-btn value="medium" class="flex-grow-1 text-caption font-weight-bold">Normal</v-btn>
                    <v-btn value="large" class="flex-grow-1 text-caption font-weight-bold">Grande</v-btn>
                </v-btn-toggle>

                <div class="text-subtitle-2 font-weight-bold mb-3" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-2' : 'text-white'">Colunas Visíveis</div>
                <v-list density="compact" class="rounded border-thin max-h-[300px] overflow-y-auto" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5' : 'bg-grey-darken-3 text-white'">
                    <template v-for="(col, index) in gridSettings.columns" :key="col.key">
                        <v-list-item v-if="!col.globalOnly || companyStore.isGlobalView">
                            <template v-slot:prepend>
                                <v-checkbox-btn v-model="col.visible" color="error" density="compact" hide-details></v-checkbox-btn>
                            </template>
                            <v-list-item-title class="font-weight-medium text-body-2">{{ col.label }}</v-list-item-title>
                        </v-list-item>
                    </template>
                </v-list>
            </div>
            <div class="px-6 py-4 border-t d-flex justify-end gap-3" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5' : 'bg-grey-darken-3'">
                <v-btn variant="outlined" class="btn-3d" height="40" @click="gridSettings.showModal = false" :disabled="gridSettings.loading">Cancelar</v-btn>
                <v-btn color="error" variant="flat" class="btn-3d px-6 font-weight-black" height="40" :loading="gridSettings.loading" @click="saveGridSettings">Salvar e Aplicar</v-btn>
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
        <v-overlay v-model="editModal.loading" contained class="align-center justify-center persistent" z-index="9999">
            <v-card class="pa-6 text-center rounded-lg" width="320" color="white" elevation="10">
                <v-progress-circular indeterminate color="purple" size="48" class="mb-4"></v-progress-circular>
                <div class="text-body-1 font-weight-bold text-grey-darken-3">Processando...</div>
                <div class="text-caption text-grey mt-1">Salvando informações no banco de dados.</div>
            </v-card>
        </v-overlay>

        <div class="modal-sidebar pa-6 d-flex flex-column text-white" :class="[editModal.isFixedAccount ? 'bg-purple-darken-3' : (themeStore.currentMode === 'light' ? 'bg-error' : 'bg-surface-variant'), mobile ? 'd-none' : '']" style="width: 340px; flex-shrink: 0;">
          <div class="d-flex align-center" style="gap: 12px;">
            <div class="bg-white-20 p-3 rounded-0 d-flex align-center justify-center" style="width: 48px; height: 48px;">
                <v-icon size="32" color="white">{{ editModal.isFixedAccount ? 'mdi-calendar-sync' : 'mdi-cash-minus' }}</v-icon>
            </div>
            <div>
              <h3 class="text-h6 font-weight-black leading-tight">
                  {{ editModal.form.id ? 'Editando' : 'Novo' }}
                  {{ editModal.isFixedAccount ? 'Conta Fixa' : 'Pagamento' }}
              </h3>
              <div class="text-caption opacity-80">
                  {{ editModal.isFixedAccount ? 'Gestão de contas recorrentes/fixas.' : 'Preencha os detalhes financeiros.' }}
              </div>
            </div>
          </div>

          <v-divider class="my-6 border-opacity-25"></v-divider>

          <div class="mt-2 bg-white-10 pa-5 rounded-lg border-thin border-white-20">
            <div class="text-caption font-weight-black opacity-70 mb-1 text-uppercase">Valor Total Previsto</div>
            <div class="text-h4 font-weight-black">{{ formatCurrency(editModal.form.value - (editModal.form.discount || 0)) }}</div>
            <div v-if="editModal.isFixedAccount" class="text-caption mt-2 text-yellow-accent-1 font-weight-bold">
                <v-icon start size="small" color="yellow-accent-1">mdi-refresh</v-icon>
                Recorrência Ativa: {{ editModal.recurrence.count }}x
            </div>
          </div>
          <v-spacer></v-spacer>
        </div>

        <div class="flex-grow-1 d-flex flex-column bg-white h-100 overflow-hidden relative">

          <div v-if="mobile" class="pa-4 bg-error text-white d-flex align-center justify-space-between flex-shrink-0">
             <div>
                 <div class="text-subtitle-2 font-weight-black">{{ editModal.form.id ? 'Editar' : 'Novo' }} Pagamento</div>
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

          <div class="pa-0 border-b bg-grey-lighten-5 flex-shrink-0">
             <div class="d-flex align-center justify-space-between px-4 pt-3 pb-0">
                <v-tabs v-model="editModal.activeTab" :color="editModal.isFixedAccount ? 'purple-darken-2' : 'error'" density="comfortable" show-arrows>
                    <v-tab value="basic"><v-icon start size="small">mdi-file-document-outline</v-icon> Dados Básicos</v-tab>
                    <v-tab value="financial"><v-icon start size="small">mdi-currency-usd</v-icon> Financeiro</v-tab>
                    <v-tab value="recurrence" v-if="editModal.isFixedAccount && !editModal.form.id"><v-icon start size="small">mdi-refresh</v-icon> Recorrência</v-tab>
                    <v-tab value="classification"><v-icon start size="small">mdi-tag-outline</v-icon> Classificação & Anexos</v-tab>
                </v-tabs>
                <v-btn v-if="!mobile" icon="mdi-close" variant="text" color="grey-darken-1" @click="editModal.show = false"></v-btn>
             </div>
          </div>

          <div class="flex-grow-1 overflow-y-auto custom-scroll pa-4 pa-md-6 bg-white absolute-fill" :style="mobile ? 'padding-bottom: 80px;' : 'height: calc(100% - 110px);'">
            <v-form @submit.prevent="savePayable" id="payableForm">
                <v-window v-model="editModal.activeTab">
                    <v-window-item value="basic">
                        <div class="text-subtitle-1 font-weight-bold text-grey-darken-3 mb-4">Informações Principais</div>
                        <v-row class="row-gap">
                            <v-col cols="12" md="6">
                              <v-autocomplete
                                label="Beneficiário (Fornecedor ou Funcionário)*"
                                v-model="editModal.form.entity_name"
                                :items="allBeneficiaries"
                                item-title="name"
                                item-value="id"
                                variant="outlined"
                                :color="editModal.isFixedAccount ? 'purple' : 'error'"
                                density="comfortable"
                                class="ui-field"
                                :return-object="false"
                                placeholder="Selecione quem receberá..."
                              >
                                <template v-slot:item="{ props, item }">
                                  <v-list-item v-bind="props" :title="item.raw.name" :subtitle="item.raw.type">
                                      <template v-slot:prepend>
                                          <v-icon :color="item.raw.type === 'Funcionário' ? 'blue' : 'orange'">
                                              {{ item.raw.type === 'Funcionário' ? 'mdi-account-tie' : 'mdi-truck-delivery' }}
                                          </v-icon>
                                      </template>
                                  </v-list-item>
                                </template>
                                <template v-slot:prepend-item>
                                  <v-list-item title="Adicionar Novo Fornecedor" prepend-icon="mdi-plus" class="text-error font-weight-black bg-red-lighten-5" @click="openQuickAdd('supplier')"></v-list-item>
                                  <v-divider></v-divider>
                                </template>
                              </v-autocomplete>
                            </v-col>

                            <v-col cols="12" md="6">
                                <v-autocomplete
                                    label="Empresa Pagadora (Responsável)*"
                                    v-model="editModal.form.company_id"
                                    :items="auxData.companies"
                                    item-title="trade_name"
                                    item-value="id"
                                    variant="outlined"
                                    :color="editModal.isFixedAccount ? 'purple' : 'error'"
                                    density="comfortable"
                                    class="ui-field"
                                    :readonly="!companyStore.isGlobalView"
                                    :hint="!companyStore.isGlobalView ? 'Definido automaticamente pelo contexto atual' : 'Obrigatório na visão Global'"
                                    persistent-hint
                                ></v-autocomplete>
                            </v-col>

                            <v-col cols="12">
                              <v-text-field label="Descrição do Pagamento*" v-model="editModal.form.description" variant="outlined" density="comfortable" :color="editModal.isFixedAccount ? 'purple' : 'error'" class="ui-field" placeholder="Ex: Compra de material..."></v-text-field>
                            </v-col>
                        </v-row>
                    </v-window-item>

                    <v-window-item value="financial">
                        <div class="text-subtitle-1 font-weight-bold text-grey-darken-3 mb-4">Valores e Prazos</div>
                        <v-row class="row-gap">
                            <v-col cols="12" md="4"><v-text-field label="Valor Bruto (R$)*" v-model.number="editModal.form.value" type="number" step="0.01" variant="outlined" bg-color="white" :color="editModal.isFixedAccount ? 'purple' : 'error'" density="comfortable" class="ui-field font-weight-bold" prefix="R$"></v-text-field></v-col>
                            <v-col cols="12" md="4"><v-text-field label="Descontos (R$)" v-model.number="editModal.form.discount" type="number" step="0.01" variant="outlined" bg-color="white" color="success" density="comfortable" class="ui-field"></v-text-field></v-col>
                            <v-col cols="12" md="4"><v-text-field label="Valor Líquido" :model-value="formatCurrency(editModal.form.value - (editModal.form.discount || 0))" readonly variant="filled" bg-color="grey-lighten-4" density="comfortable" class="ui-field"></v-text-field></v-col>
                        </v-row>
                        <v-row class="row-gap">
                            <v-col cols="12" md="4"><v-text-field label="Vencimento*" v-model="editModal.form.due_date" type="date" variant="outlined" :color="editModal.isFixedAccount ? 'purple' : 'error'" density="comfortable" class="ui-field"></v-text-field></v-col>
                            <v-col cols="12" md="4"><v-text-field label="Competência" v-model="editModal.form.competence_date" type="date" variant="outlined" :color="editModal.isFixedAccount ? 'purple' : 'error'" density="comfortable" class="ui-field" hint="Data do fato gerador" persistent-hint></v-text-field></v-col>
                            <v-col cols="12" md="4"><v-select label="Forma de Pagto" v-model="editModal.form.payment_method_id" :items="auxData.paymentMethods" item-title="name" item-value="id" variant="outlined" density="comfortable" class="ui-field"></v-select></v-col>
                        </v-row>
                         <v-divider class="my-4"></v-divider>
                         <div class="text-caption font-weight-bold text-uppercase mb-2 text-grey">Status do Pagamento</div>
                         <v-row class="row-gap">
                              <v-col cols="12" md="4"><v-select label="Status Atual" v-model="editModal.form.status" :items="['pendente','pago','atrasado']" variant="outlined" :color="editModal.isFixedAccount ? 'purple' : 'error'" density="comfortable" class="ui-field"></v-select></v-col>
                              <v-col cols="12" md="4" v-if="editModal.form.status === 'pago'"><v-text-field label="Data do Pagamento" v-model="editModal.form.payment_date" type="date" variant="outlined" color="success" density="comfortable" class="ui-field"></v-text-field></v-col>
                              <v-col cols="12" md="4"><v-select label="Conta Bancária (Saída)" v-model="editModal.form.bank_account_id" :items="auxData.bankAccounts" item-title="name" item-value="id" variant="outlined" :color="editModal.isFixedAccount ? 'purple' : 'error'" density="comfortable" class="ui-field"></v-select></v-col>
                        </v-row>
                    </v-window-item>

                    <v-window-item value="recurrence">
                        <div class="d-flex align-center justify-space-between mb-4">
                            <div class="text-subtitle-1 font-weight-bold text-grey-darken-3">Simulação de Parcelas</div>
                         </div>
                         <v-expand-transition>
                             <div>
                                <div class="bg-grey-lighten-5 pa-4 rounded border-thin mb-4">
                                    <div class="text-body-2 font-weight-bold mb-2">Configuração Base</div>
                                    <v-radio-group v-model="editModal.recurrence.calcMethod" :color="editModal.isFixedAccount ? 'purple' : 'error'" hide-details class="mb-4">
                                        <v-radio value="divide"><template v-slot:label><div><strong class="text-grey-darken-3">Dividir o valor total</strong> (Parcelamento)</div></template></v-radio>
                                        <v-radio value="repeat" class="mt-2"><template v-slot:label><div><strong class="text-grey-darken-3">Repetir o valor (Valor Fixo)</strong> (Assinatura/Aluguel)</div></template></v-radio>
                                    </v-radio-group>
                                    <v-row class="row-gap mt-2 align-center">
                                        <v-col cols="12" md="4"><v-text-field label="Quantidade (x)" v-model.number="editModal.recurrence.count" type="number" min="2" max="120" variant="outlined" density="comfortable" bg-color="white" class="ui-field"></v-text-field></v-col>
                                        <v-col cols="12" md="4"><v-select label="Intervalo" v-model="editModal.recurrence.interval" :items="[{title:'Mensal', value:'month'}, {title:'Semanal', value:'week'}]" variant="outlined" density="comfortable" bg-color="white" class="ui-field"></v-select></v-col>
                                        <v-col cols="12" md="4"><v-btn block height="42" variant="flat" color="purple-darken-2" prepend-icon="mdi-calculator" @click="generateInstallments" class="font-weight-bold btn-3d">Gerar / Simular</v-btn></v-col>
                                    </v-row>
                                </div>
                                <div v-if="editModal.projected.length > 0">
                                    <div class="text-subtitle-2 font-weight-black mb-2 d-flex justify-space-between align-center"><span>Prévia das Parcelas ({{ editModal.projected.length }})</span><span class="text-caption text-grey">Edite individualmente se necessário</span></div>
                                    <div class="border-thin rounded overflow-hidden overflow-x-auto">
                                        <div class="grid-header" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-4' : 'bg-grey-darken-3'" style="display: grid; grid-template-columns: 50px 140px 140px 140px 1fr 50px; min-width: 600px;">
                                            <div class="cell center header-text">#</div><div class="cell header-text">Vencimento</div><div class="cell header-text">Competência</div><div class="cell header-text">Valor</div><div class="cell header-text">Descrição</div><div class="cell center header-text">X</div>
                                        </div>
                                        <div v-for="(p, i) in editModal.projected" :key="i" class="grid-row" :class="themeStore.currentMode === 'light' ? 'bg-white hover-grey' : 'bg-grey-darken-4'" style="display: grid; grid-template-columns: 50px 140px 140px 140px 1fr 50px; min-width: 600px;">
                                            <div class="cell center font-weight-bold text-caption">{{ i + 1 }}</div>
                                            <div class="cell pa-1"><input type="date" v-model="editModal.projected[i].due_date" class="clean-input w-100 border rounded px-1" style="height:32px;"></div>
                                            <div class="cell pa-1"><input type="date" v-model="editModal.projected[i].competence_date" class="clean-input w-100 border rounded px-1" style="height:32px;"></div>
                                            <div class="cell pa-1"><input type="number" v-model.number="editModal.projected[i].value" step="0.01" class="clean-input w-100 border rounded px-1 font-weight-bold" style="height:32px;"></div>
                                            <div class="cell pa-1"><input type="text" v-model="editModal.projected[i].description" class="clean-input w-100 border rounded px-1 text-caption" style="height:32px;"></div>
                                            <div class="cell center"><v-btn icon variant="text" size="x-small" color="red" @click="editModal.projected.splice(i, 1)"><v-icon>mdi-close</v-icon></v-btn></div>
                                        </div>
                                    </div>
                                    <div class="d-flex justify-end mt-2"><div class="text-caption font-weight-bold bg-grey-lighten-4 px-3 py-1 rounded">Soma Total: {{ formatCurrency(editModal.projected.reduce((a,b) => a + Number(b.value), 0)) }}</div></div>
                                </div>
                             </div>
                         </v-expand-transition>
                    </v-window-item>

                    <v-window-item value="classification">
                        <div class="text-subtitle-1 font-weight-bold text-grey-darken-3 mb-4">Categorização Contábil</div>
                         <v-row class="row-gap">
                            <v-col cols="12" md="6"><v-autocomplete label="Plano de Contas" v-model="editModal.form.chart_of_accounts_id" :items="auxData.chartOfAccounts" item-title="name" item-value="id" variant="outlined" :color="editModal.isFixedAccount ? 'purple' : 'error'" clearable density="comfortable" class="ui-field"></v-autocomplete></v-col>
                            <v-col cols="12" md="6"><v-autocomplete label="Centro de Custo" v-model="editModal.form.cost_center_id" :items="auxData.costCenters" item-title="name" item-value="id" variant="outlined" :color="editModal.isFixedAccount ? 'purple' : 'error'" clearable density="comfortable" class="ui-field"></v-autocomplete></v-col>
                            <v-col cols="12"><v-textarea label="Observações / Detalhes" v-model="editModal.form.notes" variant="outlined" rows="3" density="comfortable" class="ui-field"></v-textarea></v-col>
                         </v-row>
                         <v-divider class="my-6"></v-divider>
                         <div class="text-subtitle-1 font-weight-bold text-grey-darken-3 mb-4">Anexos e Documentos</div>
                          <v-file-input v-model="editModal.files" label="Selecionar Arquivos (PDF, Imagens)" variant="outlined" density="comfortable" prepend-inner-icon="mdi-upload" :color="editModal.isFixedAccount ? 'purple' : 'error'" multiple chips show-size class="ui-field"></v-file-input>
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

          <div class="pa-4 border-t bg-grey-lighten-5 d-flex justify-end align-center flex-shrink-0" style="gap: 12px; height: 80px;">
            <v-btn variant="outlined" class="btn-3d" height="48" @click="editModal.show = false" :disabled="editModal.loading">Cancelar</v-btn>
            <v-btn :color="editModal.isFixedAccount ? 'purple-darken-2' : 'error'" variant="flat" class="btn-3d px-8 font-weight-black text-body-1" height="48" type="submit" form="payableForm" :loading="editModal.loading"><v-icon start>mdi-content-save-check</v-icon> Salvar Lançamento</v-btn>
          </div>
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
                            {{ statusModal.action === 'pay' ? 'Baixar Título (Pagar)' : 'Estornar Título' }}
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
                        <v-text-field label="Valor Pago" type="number" step="0.01" v-model.number="statusModal.payment_value" variant="outlined" density="comfortable" color="success" hide-details class="ui-field font-weight-bold" prefix="R$"></v-text-field>
                    </v-col>

                    <v-col cols="12" v-if="isPartialPayment">
                        <v-alert type="warning" variant="tonal" density="compact" class="text-caption font-weight-bold mt-2 border-warning">
                            Você está realizando uma baixa parcial. Uma nova parcela será gerada no valor de <strong>{{ formatCurrency(remainingModalBalance) }}</strong> com a mesma data de vencimento.
                        </v-alert>
                    </v-col>

                    <v-col cols="12" md="6">
                        <v-select label="Conta Origem" v-model="statusModal.bank_account_id" :items="filteredBankAccountsForBaixa" item-title="name" item-value="id" variant="outlined" density="comfortable" color="success" hide-details class="ui-field"></v-select>
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
                    O título voltará para o status "Pendente" (Em Aberto). O sistema unificará automaticamente parcelas filhas criadas por pagamentos parciais vinculados a este lançamento.
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

    <SyncPaymentModal v-model="showSyncModal" @synced="fetchPayables" />

    <v-dialog v-model="deleteModal.show" width="760" persistent scrim="black opacity-70">
       <v-card class="rounded-0 overflow-hidden d-flex flex-row" height="480">
        <div class="bg-red-darken-4 pa-8 d-flex flex-column text-white" style="width: 260px;">
          <v-icon size="64" class="mb-6">mdi-alert-decagram</v-icon>
          <h3 class="text-h5 font-weight-black leading-tight mb-4">Zona de Perigo</h3>
          <p class="text-body-2 opacity-90 mb-6">Você está prestes a excluir registros permanentemente. Essa ação não pode ser desfeita.</p>
          <v-spacer></v-spacer>
          <div class="text-caption font-weight-black text-center opacity-70 bg-black-20 rounded-0 py-2">ACESSO RESTRITO</div>
        </div>
        <div class="flex-grow-1 bg-white d-flex flex-column">
          <div class="pa-6 flex-grow-1">
            <h3 class="text-h6 font-weight-black text-grey-darken-3 mb-1">Exclusão em Massa</h3>
            <p class="text-caption text-grey-darken-1 mb-6">Selecione os critérios para remoção.</p>
            <v-card variant="outlined" class="pa-4 mb-4 rounded-0 border-thin border-error bg-grey-lighten-5">
              <v-row dense class="row-gap">
                <v-col cols="12" md="6"><v-text-field label="De" type="date" v-model="deleteModal.start" variant="outlined" density="compact" color="error" bg-color="white" class="ui-field"></v-text-field></v-col>
                <v-col cols="12" md="6"><v-text-field label="Até" type="date" v-model="deleteModal.end" variant="outlined" density="compact" color="error" bg-color="white" class="ui-field"></v-text-field></v-col>
                <v-col cols="12"><v-select label="Status para Excluir" v-model="deleteModal.status" :items="['Todos', 'Pendente', 'Pago']" variant="outlined" density="compact" color="error" bg-color="white" class="ui-field"></v-select></v-col>
              </v-row>
            </v-card>
            <div class="text-caption font-weight-black text-uppercase text-grey mb-2">Confirmação de Segurança</div>
            <v-text-field label="Digite CONFIRMAR para liberar" v-model="deleteModal.confirmText" variant="outlined" density="compact" color="red" bg-color="red-lighten-5" class="ui-field"></v-text-field>
          </div>
          <div class="pa-5 bg-grey-lighten-5 border-t d-flex justify-end" style="gap: 10px;">
            <v-btn variant="outlined" class="btn-3d" height="40" color="grey-darken-2" @click="deleteModal.show = false" :disabled="deleteModal.loading">Cancelar</v-btn>
            <v-btn color="red" variant="flat" height="40" class="btn-3d px-6 font-weight-black" :disabled="deleteModal.confirmText !== 'CONFIRMAR'" :loading="deleteModal.loading" @click="executeMassDelete"><v-icon start>mdi-trash-can</v-icon> Excluir Definitivamente</v-btn>
          </div>
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
          <v-autocomplete v-model="bulkCompanyModal.companyId" :items="auxData.companies" item-title="trade_name" item-value="id" label="Selecione a Empresa" variant="outlined" density="compact" color="error" class="ui-field"></v-autocomplete>
        </div>
        <div class="px-6 py-4 border-t bg-grey-lighten-5 d-flex justify-end" style="gap: 10px;">
          <v-btn variant="outlined" class="btn-3d" height="40" @click="bulkCompanyModal.show = false">Cancelar</v-btn>
          <v-btn color="error" variant="flat" class="btn-3d px-6 font-weight-black" height="40" :loading="bulkCompanyModal.loading" @click="executeBulkCompanyAssign">Salvar</v-btn>
        </div>
      </v-card>
    </v-dialog>

    <UniversalImportModal :show="showImportModal" :system-fields="importFields" @update:show="showImportModal = $event" @import="handleImportData" />
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted, reactive, watch } from 'vue';
import { supabase } from '@/api/supabase';
import { gestaoApi } from '@/api/gestaoClick';
import { format, parseISO, startOfMonth, endOfMonth, startOfWeek, endOfWeek, addMonths, addDays, startOfYear, endOfYear } from 'date-fns';
import { ptBR } from 'date-fns/locale';
import { useAppStore } from '@/stores/app';
import { useUserStore } from '@/stores/user';
import { useThemeStore } from '@/stores/theme';
import { useCompanyStore } from '@/stores/company';
import { useDisplay } from 'vuetify';
import { useAuditLogger } from '@/composables/useAuditLogger';

import UniversalImportModal from '@/components/admin/UniversalImportModal.vue';
import SyncPaymentModal from '@/components/admin/SyncPaymentModal.vue';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import * as XLSX from 'xlsx';
import QRCode from 'qrcode';

import logoImage from '@/assets/logo.png';
import logoCajuia from '@/assets/logocajuia.png';
import logoMj from '@/assets/logomjlm.png';

const { mobile } = useDisplay();
const appStore = useAppStore();
const userStore = useUserStore();
const themeStore = useThemeStore();
const companyStore = useCompanyStore();
const { logBusinessEvent } = useAuditLogger();

const loading = ref(false);
const items = ref<any[]>([]);
const totalItems = ref(0);
const page = ref(1);
const itemsPerPage = 30;
const showLogs = ref(false);
const reportLoading = ref(false);
const printLoadingId = ref<string | null>(null);

const logsData = reactive({ erpCount: 0, internalCount: 0, sumValue: 0 });
const filtersDropdownOpen = ref(false);
const mobileFiltersOpen = ref(false);
const isMobileFullscreen = ref(false);
const kpiModel = ref(0);

const filters = reactive({
  search: '',
  supplierId: null as any,
  employeeId: null as any,
  chartOfAccountsId: null as any,
  status: [] as string[],
  customStart: format(startOfMonth(new Date()), 'yyyy-MM-dd'),
  customEnd: format(endOfMonth(new Date()), 'yyyy-MM-dd'),
  dateType: 'due_date' as 'due_date' | 'payment_date',
  minValue: null as number | null,
  maxValue: null as number | null,
  onlyConciliated: false
});

const gridSettings = reactive({
    showModal: false,
    loading: false,
    textSize: 'medium' as 'small' | 'medium' | 'large',
    columns: [
        { key: 'ref', label: 'Ref.', visible: true, width: '80px', globalOnly: false },
        { key: 'supplier', label: 'Beneficiário / Fornecedor', visible: true, width: 'minmax(120px, 2fr)', globalOnly: false },
        { key: 'desc', label: 'Descrição', visible: true, width: 'minmax(150px, 2.5fr)', globalOnly: false },
        { key: 'chart', label: 'Plano de Contas', visible: true, width: 'minmax(100px, 1fr)', globalOnly: false },
        { key: 'company', label: 'Empresa', visible: true, width: 'minmax(90px, 1fr)', globalOnly: true },
        { key: 'bank', label: 'Banco', visible: true, width: 'minmax(90px, 1fr)', globalOnly: false },
        { key: 'date', label: 'Vencimento', visible: true, width: 'minmax(80px, 1fr)', globalOnly: false },
        { key: 'val', label: 'Valor', visible: true, width: 'minmax(90px, 1fr)', globalOnly: false },
        { key: 'conciliated', label: 'Conciliação', visible: true, width: 'minmax(80px, 0.8fr)', globalOnly: false },
        { key: 'status', label: 'Status', visible: true, width: 'minmax(100px, 1fr)', globalOnly: false },
        { key: 'cost_center', label: 'Centro Custo', visible: false, width: 'minmax(90px, 1fr)', globalOnly: false },
        { key: 'notes', label: 'Observações', visible: false, width: 'minmax(120px, 1.5fr)', globalOnly: false }
    ]
});

// Geração dinâmica dos botões de contexto
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

const setCompanyFilter = (id: string) => {
    companyStore.setContext(id);
};

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

        if (data && data.settings && data.settings.payables_grid) {
            const prefs = data.settings.payables_grid;
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

        currentSettings.payables_grid = {
            textSize: gridSettings.textSize,
            columns: gridSettings.columns.map(c => ({ key: c.key, visible: c.visible }))
        };

        const payload = {
            user_id: userStore.user.id,
            settings: currentSettings
        };

        const { error } = await supabase.from('user_preferences').upsert(payload, { onConflict: 'user_id' });

        if (error) throw error;

        await logBusinessEvent('Financeiro - Pagar', 'UPDATE', 'Salvou preferências de visualização da grid.', payload, null);

        appStore.showSnackbar('Configurações da grid salvas!', 'success');
        gridSettings.showModal = false;
    } catch (e: any) {
        appStore.showSnackbar('Erro ao salvar grid: ' + e.message, 'error');
    } finally {
        gridSettings.loading = false;
    }
};

const toggleConciliatedFilter = () => {
    filters.onlyConciliated = !filters.onlyConciliated;
    page.value = 1;
    fetchPayables();
};

const activeFilterCount = computed(() => {
  let count = 0;
  if (filters.search) count++;
  if (filters.supplierId) count++;
  if (filters.employeeId) count++;
  if (filters.chartOfAccountsId) count++;
  if (filters.status.length > 0) count++;
  if (filters.minValue || filters.maxValue) count++;
  if (filters.onlyConciliated) count++;
  return count;
});

const showImportModal = ref(false);
const showSyncModal = ref(false);
const selectedIds = ref(new Set<string>());
const autoSyncInterval = ref<any>(null);
const pendingSyncCount = ref(0);

const auxData = reactive({
  suppliers: [] as any[],
  employees: [] as any[],
  bankAccounts: [] as any[],
  paymentMethods: [] as any[],
  chartOfAccounts: [] as any[],
  costCenters: [] as any[],
  companies: [] as any[]
});

const allBeneficiaries = computed(() => {
    const suppliers = auxData.suppliers.map(s => ({ ...s, type: 'Fornecedor' }));
    const employees = auxData.employees.map(e => ({ ...e, type: 'Funcionário' }));
    return [...suppliers, ...employees].sort((a,b) => a.name.localeCompare(b.name));
});

const quickPeriodLabel = computed(() => 'Período Personalizado');

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
    fetchPayables();
};

const dateRange = computed(() => {
    return { start: filters.customStart, end: filters.customEnd };
});

const kpiTotals = reactive({ total: 0, paid: 0, openFuture: 0, expiresToday: 0, overdue: 0 });

const fetchKpiTotals = async () => {
  try {
    let query = supabase.from('finance_payables').select('value, status, due_date, discount, company_id, description, entity_name, chart_of_accounts_id, reconciliation_status');
    query = buildQuery(query);

    const { data, error } = await query;
    if (error || !data) return;

    let total = 0, paid = 0, openFuture = 0, expiresToday = 0, overdue = 0;
    const todayStr = format(new Date(), 'yyyy-MM-dd');

    data.forEach((i: any) => {
      const val = (i.value || 0) - (i.discount || 0);
      total += val;
      const iDateStr = i.due_date ? String(i.due_date).substring(0, 10) : '';
      if (i.status === 'pago') paid += val;
      else {
        if (iDateStr < todayStr) overdue += val;
        else { openFuture += val; if (iDateStr === todayStr) expiresToday += val; }
      }
    });

    kpiTotals.total = total; kpiTotals.paid = paid; kpiTotals.openFuture = openFuture; kpiTotals.expiresToday = expiresToday; kpiTotals.overdue = overdue;
  } catch (e) { console.warn('fetchKpiTotals error:', e); }
};

const kpiList = computed(() => ([
  { label: 'A Pagar', value: kpiTotals.openFuture, footer: 'Em dia', icon: 'mdi-cash-minus', gradient: 'bg-gradient-info', active: false },
  { label: 'Vencem Hoje', value: kpiTotals.expiresToday, footer: 'Atenção', icon: 'mdi-alarm-light-outline', gradient: 'bg-gradient-warning', active: false },
  { label: 'Vencidos', value: kpiTotals.overdue, footer: 'Atrasado', icon: 'mdi-alert-circle', gradient: 'bg-gradient-red', active: false },
  { label: 'Pago', value: kpiTotals.paid, footer: 'Liquidado', icon: 'mdi-check-all', gradient: 'bg-gradient-green', active: false },
  { label: 'Total', value: kpiTotals.total, footer: 'Geral', icon: 'mdi-chart-line', gradient: 'bg-gradient-purple', active: false },
]));

const handleKpiClick = (kpiLabel: string) => {
  filters.status = [];
  if (kpiLabel === 'Vencem Hoje') { applyPreset('today'); filters.status = ['pendente']; }
  else if (kpiLabel === 'Vencidos') { applyPreset('all'); filters.status = ['atrasado']; }
  else if (kpiLabel === 'A Pagar') { applyPreset('all'); filters.status = ['pendente']; }
  else if (kpiLabel === 'Pago') { applyPreset('month'); filters.status = ['pago']; }
  else if (kpiLabel === 'Total') { applyPreset('month'); filters.status = []; }
  fetchPayables();
};

const buildQuery = (baseQuery: any) => {
    const { customStart, customEnd, dateType } = filters;
    const todayStr = format(new Date(), 'yyyy-MM-dd');

    const dateField = dateType === 'payment_date' ? 'payment_date' : 'due_date';
    if (customStart) baseQuery = baseQuery.gte(dateField, customStart);
    if (customEnd) baseQuery = baseQuery.lte(dateField, customEnd);

    if (!companyStore.isGlobalView && companyStore.context) {
        baseQuery = baseQuery.eq('company_id', companyStore.context);
    }

    if (filters.search && filters.search.trim() !== '') {
        const term = filters.search.trim();
        const val = Number(term);
        if (!isNaN(val) && isFinite(val) && term.length < 10) {
             baseQuery = baseQuery.or(`value.eq.${val},id.eq.${val}`);
        } else {
             baseQuery = baseQuery.or(`description.ilike.%${term}%,entity_name.ilike.%${term}%`);
        }
    }

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

    if (filters.onlyConciliated) {
        baseQuery = baseQuery.eq('reconciliation_status', 'CONCILIATED');
    }

    if (filters.status.length > 0) {
        if (filters.status.includes('atrasado')) {
            if(filters.status.length === 1) {
                 baseQuery = baseQuery.lt('due_date', todayStr).neq('status', 'pago');
            } else {
                 const effectiveStatus = filters.status.map(s => s === 'atrasado' ? 'pendente' : s);
                 baseQuery = baseQuery.in('status', effectiveStatus);
            }
        } else {
            baseQuery = baseQuery.in('status', filters.status);
        }
    }

    return baseQuery;
};

const fetchPayables = async () => {
  loading.value = true;
  try {
    let query = supabase.from('finance_payables').select('*', { count: 'exact' });
    query = buildQuery(query);

    query = query.order('due_date', { ascending: true });
    const from = (page.value - 1) * itemsPerPage;
    const to = from + itemsPerPage - 1;
    query = query.range(from, to);

    const { data, error, count } = await query;
    if (error) throw error;

    items.value = data || [];
    totalItems.value = count || 0;

    const erp = items.value.filter(i => i.gestao_click_id).length;
    const internal = items.value.length - erp;
    const totalVal = items.value.reduce((acc, i) => acc + (Number(i.value) - Number(i.discount || 0)), 0);
    logsData.erpCount = erp; logsData.internalCount = internal; logsData.sumValue = totalVal;

    await fetchKpiTotals();
  } catch (e) { console.error('Erro ao buscar contas a pagar:', e); } finally { loading.value = false; }
};

const fetchAllPayablesForExport = async () => {
    try {
        let query = supabase.from('finance_payables').select('*');
        query = buildQuery(query);
        query = query.order('due_date', { ascending: true });

        const { data, error } = await query;
        if (error) throw error;
        return data || [];
    } catch (e: any) {
        console.error("Export fetch error", e);
        appStore.showSnackbar("Erro ao buscar dados completos para exportação", "error");
        return [];
    }
};

const handleSearchEnter = () => {
    page.value = 1;
    fetchPayables();
}

const applyFiltersFromDropdown = () => {
    filtersDropdownOpen.value = false;
    page.value = 1;
    fetchPayables();
};

const clearFilters = () => {
    filters.search = '';
    filters.supplierId = null;
    filters.employeeId = null;
    filters.chartOfAccountsId = null;
    filters.status = [];
    filters.minValue = null;
    filters.maxValue = null;
    filters.onlyConciliated = false;
    applyPreset('month');
};

const areAllSelected = computed(() => items.value.length > 0 && selectedIds.value.size === items.value.length);
const toggleSelectAll = (val: boolean) => { if (val) items.value.forEach(i => selectedIds.value.add(i.id)); else selectedIds.value.clear(); };
const toggleSelection = (id: string) => { if (selectedIds.value.has(id)) selectedIds.value.delete(id); else selectedIds.value.add(id); };
const pageCount = computed(() => Math.ceil(totalItems.value / itemsPerPage));
const toggleStatusFilter = (s: string) => { const idx = filters.status.indexOf(s); if (idx >= 0) filters.status.splice(idx, 1); else filters.status.push(s); };

// --- STATUS MODAL (NOVO PARA PAGAR - INCLUINDO LOGS) ---
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
        const filePath = `payables/${fileName}`;
        const { error } = await supabase.storage.from('finance-attachments').upload(filePath, file);
        if (!error) {
             const { data } = supabase.storage.from('finance-attachments').getPublicUrl(filePath);
             if (data?.publicUrl) uploadedUrls.push(data.publicUrl);
        }
    }
    return uploadedUrls;
};

const confirmStatusAction = async () => {
    if (!statusModal.item) return;
    statusModal.loading = true;
    try {
        if (statusModal.action === 'revert') {
            const { data: childSplits } = await supabase
                .from('finance_payables')
                .select('*')
                .like('notes', `%[SPLIT_FROM:${statusModal.item.id}]%`);

            let newTotal = Number(statusModal.item.value);
            let hasChild = false;

            if (childSplits && childSplits.length > 0) {
                const child = childSplits[0];
                newTotal += Number(child.value);
                await supabase.from('finance_payables').delete().eq('id', child.id);
                hasChild = true;
            }

            const payload = {
                status: 'pendente',
                payment_date: null,
                value: newTotal
            };

            const { error } = await supabase.from('finance_payables').update(payload).eq('id', statusModal.item.id);
            if (error) throw error;

            await logBusinessEvent('Financeiro - Pagar', 'STATUS_CHANGE', `Estornou o pagamento de ${statusModal.item.entity_name || 'Fornecedor'}`, { action: 'revert', had_child: hasChild }, statusModal.item.id, statusModal.item);

            appStore.showSnackbar('Estorno realizado' + (hasChild ? ' e parcela unificada' : '') + ' com sucesso!', 'success');

        } else if (statusModal.action === 'pay') {
            if (Number(statusModal.payment_value) <= 0) throw new Error('O valor pago deve ser maior que zero.');

            const newUrls = await uploadStatusAttachments();
            const existingAttachments = statusModal.item.attachments || [];
            const finalAttachments = [...existingAttachments, ...newUrls];

            if (isPartialPayment.value) {
                const {
                    id, ...basePayload
                } = statusModal.item;

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

                const { error: updErr } = await supabase.from('finance_payables').update(paidPayload).eq('id', statusModal.item.id);
                if (updErr) throw updErr;

                const newInstPayload = {
                    ...basePayload,
                    value: remainingModalBalance.value,
                    discount: 0,
                    status: 'pendente',
                    payment_date: null,
                    due_date: statusModal.item.due_date,
                    competence_date: statusModal.item.competence_date,
                    description: `${statusModal.item.description} (Saldo Remanescente)`,
                    notes: `[SPLIT_FROM:${statusModal.item.id}] Gerado a partir do pagamento parcial`,
                    attachments: existingAttachments
                };

                const { error: insErr } = await supabase.from('finance_payables').insert(newInstPayload);
                if (insErr) throw insErr;

                await logBusinessEvent('Financeiro - Pagar', 'STATUS_CHANGE', `Realizou baixa parcial de R$ ${statusModal.payment_value} no pagamento de ${statusModal.item.entity_name || 'Fornecedor'} e desmembrou saldo.`, paidPayload, statusModal.item.id, statusModal.item);

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
                const { error } = await supabase.from('finance_payables').update(payload).eq('id', statusModal.item.id);
                if (error) throw error;

                await logBusinessEvent('Financeiro - Pagar', 'STATUS_CHANGE', `Baixou (pagou integralmente) a conta de ${statusModal.item.entity_name || 'Fornecedor'}`, payload, statusModal.item.id, statusModal.item);

                appStore.showSnackbar('Título baixado com sucesso!', 'success');
            }
        }

        statusModal.show = false;
        fetchPayables();
    } catch (e: any) {
        appStore.showSnackbar('Erro: ' + e.message, 'error');
    } finally {
        statusModal.loading = false;
    }
};

const bulkCompanyModal = reactive({ show: false, companyId: null as any, loading: false });

const openBulkCompanyModal = () => { bulkCompanyModal.companyId = null; bulkCompanyModal.show = true; };
const executeBulkCompanyAssign = async () => {
  if (!bulkCompanyModal.companyId) return;
  bulkCompanyModal.loading = true;
  try {
      const ids = Array.from(selectedIds.value);
      const { error } = await supabase.from('finance_payables').update({ company_id: bulkCompanyModal.companyId }).in('id', ids);
      if (error) throw error;

      const compName = auxData.companies.find(c => c.id === bulkCompanyModal.companyId)?.trade_name || 'Desconhecida';
      await logBusinessEvent('Financeiro - Pagar', 'UPDATE', `Moveu ${ids.length} contas a pagar para a empresa ${compName}`, { new_company: bulkCompanyModal.companyId });

      appStore.showSnackbar(`${ids.length} itens atualizados!`, 'success');
      bulkCompanyModal.show = false;
      selectedIds.value.clear();
      fetchPayables();
  } catch (e: any) {
      appStore.showSnackbar('Erro: ' + e.message, 'error');
  } finally {
      bulkCompanyModal.loading = false;
  }
};

const bulkUpdateStatus = async (newStatus: 'pago' | 'pendente') => {
    if(!confirm(`Deseja alterar o status de ${selectedIds.value.size} itens para ${newStatus.toUpperCase()}?`)) return;
    loading.value = true;
    try {
        const ids = Array.from(selectedIds.value);
        const payload = {
            status: newStatus,
            payment_date: newStatus === 'pago' ? new Date().toISOString().split('T')[0] : null
        };
        const { error } = await supabase.from('finance_payables').update(payload).in('id', ids);
        if(error) throw error;

        const acao = newStatus === 'pago' ? 'Efetuou pagamento em lote de' : 'Estornou em lote';
        await logBusinessEvent('Financeiro - Pagar', 'STATUS_CHANGE', `${acao} ${ids.length} contas a pagar.`, { new_status: newStatus, count: ids.length });

        appStore.showSnackbar(`${ids.length} itens atualizados para ${newStatus}!`, 'success');
        selectedIds.value.clear();
        fetchPayables();
    } catch(e:any) {
        appStore.showSnackbar('Erro ao atualizar em massa: ' + e.message, 'error');
    } finally {
        loading.value = false;
    }
};

const getErpStatus = (val: any) => { const s = String(val).toLowerCase(); if (['1', 's', 'sim', 'true', 'confirmado', 'pago'].includes(s)) return 'pago'; return 'pendente'; };
const startAutoSyncService = () => { checkBackgroundSync(); autoSyncInterval.value = setInterval(() => checkBackgroundSync(), 5 * 60 * 1000); };
const checkBackgroundSync = async () => { try { const startDate = format(startOfMonth(new Date()), 'yyyy-MM-dd'); const endDate = format(endOfMonth(new Date()), 'yyyy-MM-dd'); const params: any = { limit: 100, itens_por_pagina: 100, data_inicio: startDate, data_fim: endDate, loja_id: 523283 }; const apiData = await gestaoApi.buscarPagamentos(params); if (apiData && apiData.length > 0) { const apiIds = apiData.map((i: any) => String(i.id)); const { data: existing } = await supabase.from('finance_payables').select('gestao_click_id, status').in('gestao_click_id', apiIds); const existingMap = new Map(existing?.map(e => [String(e.gestao_click_id), e.status])); let updatesFound = 0; apiData.forEach((apiItem: any) => { const localStatus = existingMap.get(String(apiItem.id)); const erpStatus = getErpStatus(apiItem.liquidado); if (localStatus === undefined) updatesFound++; else if (localStatus !== 'pago' && erpStatus === 'pago') updatesFound++; }); pendingSyncCount.value = updatesFound > 0 ? updatesFound : 0; } } catch (e) { console.warn('AutoSync check failed (silent):', e); } };

const deleteModal = reactive({ show: false, loading: false, start: '', end: '', status: 'Todos', confirmText: '' });
const openDeleteModal = () => { deleteModal.start = format(startOfMonth(new Date()), 'yyyy-MM-dd'); deleteModal.end = format(endOfMonth(new Date()), 'yyyy-MM-dd'); deleteModal.status = 'Todos'; deleteModal.confirmText = ''; deleteModal.show = true; };
const executeMassDelete = async () => {
    if (deleteModal.confirmText !== 'CONFIRMAR') return;
    deleteModal.loading = true;
    try {
        let query = supabase.from('finance_payables').delete();
        query = query.gte('due_date', deleteModal.start).lte('due_date', deleteModal.end);
        if (deleteModal.status === 'Pendente') query = query.neq('status', 'pago');
        if (deleteModal.status === 'Pago') query = query.eq('status', 'pago');

        const { error } = await query;
        if (error) throw error;

        await logBusinessEvent('Financeiro - Pagar', 'DELETE', `Excluiu um período inteiro de contas a pagar (${deleteModal.start} até ${deleteModal.end})`, { filters: deleteModal });

        appStore.showSnackbar('Exclusão realizada.', 'success');
        deleteModal.show = false;
        fetchPayables();
    } catch (e: any) {
        appStore.showSnackbar('Erro: ' + e.message, 'error');
    } finally {
        deleteModal.loading = false;
    }
};

const formatCurrency = (val: any) => new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(Number(val) || 0);
const formatCurrencyValue = (val: any) => new Intl.NumberFormat('pt-BR', { minimumFractionDigits: 2 }).format(Number(val) || 0);
const formatDateSafe = (dateString: string) => {
    if (!dateString) return '-';
    const [year, month, day] = dateString.split('-');
    return `${day}/${month}/${year}`;
};

const isOverdue = (item: any) => { if (item.status === 'pago') return false; const todayStr = format(new Date(), 'yyyy-MM-dd'); return item.due_date < todayStr; };
const getStatusLabel = (item: any) => { if (item.status === 'pago') return 'Pago'; if (isOverdue(item)) return 'Atrasado'; return 'Pendente'; };
const getStatusChipClass = (item: any) => { const s = getStatusLabel(item); if (s === 'Pago') return 'chip-success'; if (s === 'Atrasado') return 'chip-danger'; return 'chip-warn'; };
const getRefNumber = (item: any) => item.gestao_click_id || (item.id ? String(item.id).slice(0, 4).toUpperCase() : '-');
const getSupplierName = (item: any) => { if (item.entity_name) return item.entity_name; if (item.supplier_id) return auxData.suppliers.find(s => s.id === item.supplier_id)?.name || 'Fornecedor'; return '-'; };
const getBankAccountName = (id: any) => auxData.bankAccounts.find(b => b.id === id)?.name || '-';
const getCompanyName = (id: any) => auxData.companies.find(c => c.id === id)?.trade_name || '-';
const getCostCenterName = (id: any) => auxData.costCenters.find(c => c.id === id)?.name || '-';
const getChartName = (id: any) => auxData.chartOfAccounts.find(c => c.id === id)?.name || '-';
const getPaymentMethodName = (id: any) => auxData.paymentMethods.find(m => m.id === id)?.name || '';
const zebraClass = (index: number) => { if (themeStore.currentMode !== 'light') return index % 2 === 0 ? 'zebra-dark-a' : 'zebra-dark-b'; return index % 2 === 0 ? 'zebra-light-a' : 'zebra-light-b'; };

const fetchAuxiliaryData = async () => {
  try { const { data } = await supabase.from('customers_mj').select('id, nome'); if (data) auxData.suppliers = data.map(c => ({ id: c.id, name: c.nome })); } catch {}
  try { const { data } = await supabase.from('employees_mj').select('id, nome'); if (data) auxData.employees = data.map(e => ({ id: e.id, name: e.nome })); } catch {}
  try { const { data } = await supabase.from('finance_accounts').select('id, name'); if (data) auxData.bankAccounts = data; } catch {}
  try { const { data } = await supabase.from('finance_payment_methods').select('id, name'); if (data) auxData.paymentMethods = data; } catch {}
  try { const { data } = await supabase.from('finance_chart_of_accounts').select('id, name, code, type').eq('type', 'Despesa').order('name'); if (data) auxData.chartOfAccounts = data; } catch {}
  try { const { data } = await supabase.from('finance_cost_centers').select('id, name'); if (data) auxData.costCenters = data; } catch {}
  try { const { data } = await supabase.from('companies').select('id, trade_name, name'); if (data) auxData.companies = data; } catch (e) { console.error('Erro companies', e); }
};

const imageToBase64 = (urlOrFile: string | File): Promise<string> => new Promise((resolve, reject) => {
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

const handlePrintReceipt = async (item: any) => {
    printLoadingId.value = item.id;

    try {
        const refNum = getRefNumber(item);
        const supplierName = getSupplierName(item);
        const currentCompanyName = getCompanyName(item.company_id) || companyStore.currentCompanyName || 'Sua Empresa';

        const amount = Number(item.value) - Number(item.discount || 0);
        const method = getPaymentMethodName(item.payment_method_id) || 'Diversos';
        const description = item.description || `Referente ao lançamento #${item.id}`;

        const pdfFileName = `Comprovante_Pagamento_${refNum}.pdf`;

        const qrCodeContent = window.location.href;
        const qrCodeDataUrl = await QRCode.toDataURL(qrCodeContent, { width: 175, margin: 1 });

        const doc = new jsPDF('p', 'mm', 'a4');
        const pageWidth = doc.internal.pageSize.width;
        const pageHeight = doc.internal.pageSize.height;
        const midPointY = pageHeight / 2;
        const margin = 15;

        const introText = `A empresa ${currentCompanyName.toUpperCase()} declara ter efetuado o pagamento do valor descrito abaixo ao beneficiário listado.`;
        const qrSize = 25; const qrGap = 5; const tableWidth = pageWidth - margin * 2 - qrSize - qrGap;

        const tableHead = [['Beneficiário', 'Valor Pago', 'Detalhes / Forma']];
        const tableBody = [[ supplierName, formatCurrency(amount), `${description} (${method})` ]];

        const dataDoPagamento = `${format(new Date(), "dd 'de' MMMM 'de' yyyy", { locale: ptBR })}`;

        const generateViaContent = async (yOffset: number, viaTitle: string) => {
            await addHeader(doc, refNum, `Comprovante de Pagamento`, yOffset, currentCompanyName);

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
                headStyles: { fillColor: yOffset === 0 ? [250, 220, 220] : [200, 70, 70], textColor: yOffset === 0 ? 0 : [255, 255, 255], fontStyle: 'bold' },
                columnStyles: { 0: { cellWidth: 'auto' }, 1: { cellWidth: 35, halign: 'right' }, 2: { cellWidth: 60 } },
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
            doc.setFontSize(9).setTextColor(0, 0, 0).text(supplierName.substring(0,30), signatureX2 + signatureWidth / 2, signatureY + 5, { align: 'center' });

            const dateY = signatureY + 15;
            doc.setFontSize(9).setFont('helvetica', 'normal').text(`Emitido em: ${dataDoPagamento}`, pageWidth / 2, dateY, { align: 'center' });
        };

        await generateViaContent(0, 'Via da Empresa');

        doc.setLineDashPattern([2, 2], 0);
        doc.line(5, midPointY, pageWidth - 5, midPointY);
        doc.setLineDashPattern([], 0);

        doc.setFontSize(8).setTextColor(150).text('- - - - corte aqui - - - -', pageWidth / 2, midPointY - 1, { align: 'center' });

        await generateViaContent(midPointY, 'Via do Beneficiário');
        await addWatermark(doc);
        addFooter(doc);

        doc.save(pdfFileName);

        await logBusinessEvent('Financeiro - Pagar', 'PRINT', `Baixou/Imprimiu o comprovante de pagamento para ${supplierName}`, null, item.id, null);

        appStore.showSnackbar('Comprovante gerado com sucesso!', 'success');

    } catch (e:any) {
        console.error(e);
        appStore.showSnackbar('Erro ao gerar comprovante: ' + e.message, 'error');
    } finally {
        printLoadingId.value = null;
    }
}

const generateReport = async (type: 'pdf' | 'excel') => {
    reportLoading.value = true;
    try {
        const dataToExport = await fetchAllPayablesForExport();

        if (!dataToExport || dataToExport.length === 0) {
            appStore.showSnackbar('Nenhum dado encontrado para os filtros atuais.', 'warning');
            return;
        }

        await logBusinessEvent('Financeiro - Pagar', 'READ', `Exportou relatório de Contas a Pagar em formato ${type.toUpperCase()}`, { filters: filters });

        if (type === 'excel') {
            const ws = XLSX.utils.json_to_sheet(dataToExport.map(i => ({
                Ref: getRefNumber(i),
                Fornecedor: getSupplierName(i),
                Descricao: i.description,
                PlanoContas: getChartName(i.chart_of_accounts_id),
                Vencimento: formatDateSafe(i.due_date),
                Pagamento: i.payment_date ? formatDateSafe(i.payment_date) : '-',
                Valor: Number(i.value) - Number(i.discount || 0),
                Status: getStatusLabel(i),
                Empresa: getCompanyName(i.company_id),
                Observacoes: i.notes || ''
            })));
            const wb = XLSX.utils.book_new();
            XLSX.utils.book_append_sheet(wb, ws, "ContasPagar");
            XLSX.writeFile(wb, `Relatorio_Pagar_${format(new Date(), 'dd-MM-yyyy')}.xlsx`);
            appStore.showSnackbar('Excel Gerado com sucesso!', 'success');
        } else {
            const doc = new jsPDF({ orientation: 'p', unit: 'mm', format: 'a4' });
            const pageWidth = doc.internal.pageSize.width;
            const pageHeight = doc.internal.pageSize.height;
            const todayStr = format(new Date(), 'yyyy-MM-dd');

            try {
                const logoUrl = logoImage;
                const imgProps = doc.getImageProperties(logoUrl);
                const imgWidth = 35;
                const imgHeight = (imgProps.height * imgWidth) / imgProps.width;
                doc.addImage(logoUrl, 'PNG', 15, 10, imgWidth, imgHeight);
            } catch (e) {
                console.warn("Logo error", e);
            }

            doc.setFontSize(8).setTextColor(80);
            const companyName = companyStore.isGlobalView ? 'VISÃO GLOBAL - HOLDING' : companyStore.currentCompanyName.toUpperCase();
            const headerInfo = [
                companyName,
                "Relatório Financeiro - Contas a Pagar",
                "MJProcess ERP",
                `Emitido por: ${userStore.user?.email || 'Sistema'}`
            ];
            doc.text(headerInfo, pageWidth - 15, 15, { align: 'right', lineHeightFactor: 1.2 });

            doc.setDrawColor(220, 220, 220);
            doc.line(15, 32, pageWidth - 15, 32);

            doc.setFontSize(14).setFont('helvetica', 'bold').setTextColor(20);
            doc.text("Relatório Analítico de Contas a Pagar", 15, 42);

            doc.setFontSize(9).setFont('helvetica', 'normal').setTextColor(100);
            const periodStr = `Período: ${formatDateSafe(filters.customStart)} até ${formatDateSafe(filters.customEnd)}`;
            const filterStr = `Filtros: ${filters.search ? '"'+filters.search+'"' : 'Geral'} | Status: ${filters.status.length ? filters.status.join(', ') : 'Todos'}`;
            doc.text(`${periodStr}  —  ${filterStr}`, 15, 48);

            let totalVal = 0, openVal = 0, overdueVal = 0, paidVal = 0;

            dataToExport.forEach(row => {
                const val = Number(row.value) - Number(row.discount || 0);
                totalVal += val;

                if (row.status === 'pago') {
                    paidVal += val;
                } else {
                    if (row.due_date < todayStr) overdueVal += val;
                    else openVal += val;
                }
            });

            const kpiY = 55;
            const kpiBoxWidth = (pageWidth - 30) / 4;

            const drawKpi = (label: string, value: string, color: string, x: number) => {
                doc.setFontSize(8).setTextColor(120).setFont('helvetica', 'normal');
                doc.text(label, x, kpiY);
                doc.setFontSize(10).setTextColor(color).setFont('helvetica', 'bold');
                doc.text(value, x, kpiY + 5);
            };

            drawKpi("TOTAL GERAL", formatCurrency(totalVal), "#333333", 15);
            drawKpi("EM ABERTO", formatCurrency(openVal), "#F57F17", 15 + kpiBoxWidth);
            drawKpi("ATRASADO", formatCurrency(overdueVal), "#D32F2F", 15 + kpiBoxWidth * 2);
            drawKpi("PAGO", formatCurrency(paidVal), "#388E3C", 15 + kpiBoxWidth * 3);

            const columns = [
                { header: 'Ref', dataKey: 'ref' },
                { header: 'Vencimento', dataKey: 'due_date' },
                { header: 'Fornecedor / Beneficiário', dataKey: 'entity' },
                { header: 'Descrição', dataKey: 'desc' },
                { header: 'Empresa', dataKey: 'company' },
                { header: 'Pagto', dataKey: 'payment_date' },
                { header: 'Status', dataKey: 'status_label' },
                { header: 'Valor', dataKey: 'value' }
            ];

            const tableBody = dataToExport.map(row => {
                const val = Number(row.value) - Number(row.discount || 0);
                const isPaid = row.status === 'pago';
                const isOverdueItem = !isPaid && row.due_date < todayStr;

                let rowColor: [number, number, number] = [255, 255, 255];
                let statusText = getStatusLabel(row).toUpperCase();

                if (isPaid) {
                    rowColor = [220, 245, 220];
                } else if (isOverdueItem) {
                    rowColor = [255, 225, 225];
                } else {
                    rowColor = [255, 250, 205];
                }

                return {
                    ref: getRefNumber(row),
                    due_date: formatDateSafe(row.due_date),
                    entity: getSupplierName(row).substring(0, 30),
                    desc: (row.description || '').substring(0, 40),
                    company: getCompanyName(row.company_id),
                    payment_date: row.payment_date ? formatDateSafe(row.payment_date) : '-',
                    status_label: statusText,
                    value: formatCurrency(val),
                    _rowColor: rowColor
                };
            });

            autoTable(doc, {
                startY: kpiY + 12,
                columns: columns,
                body: tableBody,
                theme: 'grid',
                styles: {
                    fontSize: 7,
                    cellPadding: 2.5,
                    textColor: 50,
                    lineColor: [200, 200, 200],
                    lineWidth: 0.1
                },
                headStyles: {
                    fillColor: [40, 40, 40],
                    textColor: 255,
                    fontStyle: 'bold',
                    halign: 'center'
                },
                columnStyles: {
                    ref: { cellWidth: 15, fontStyle: 'bold' },
                    due_date: { cellWidth: 18, halign: 'center' },
                    entity: { cellWidth: 'auto' },
                    desc: { cellWidth: 'auto' },
                    company: { cellWidth: 22, halign: 'center' },
                    payment_date: { cellWidth: 18, halign: 'center' },
                    status_label: { cellWidth: 20, halign: 'center', fontStyle: 'bold' },
                    value: { cellWidth: 22, halign: 'right', fontStyle: 'bold' }
                },
                didParseCell: (data) => {
                    if (data.section === 'body') {
                        const row = data.row.raw as any;
                        if (row._rowColor) {
                            data.cell.styles.fillColor = row._rowColor;
                        }
                        data.cell.styles.textColor = [40, 40, 40];
                    }
                },
                didDrawPage: (data) => {
                    const nowStr = format(new Date(), 'dd/MM/yyyy HH:mm');
                    const userEmail = userStore.user?.email || 'Usuário';
                    const footerText = `Gerado dia ${nowStr}, por ${userEmail} via MJProcess.`;

                    doc.setFontSize(7).setTextColor(150).setFont('helvetica', 'normal');
                    doc.text(footerText, 15, pageHeight - 10);
                    const pageNum = `Pág ${doc.internal.getNumberOfPages()}`;
                    doc.text(pageNum, pageWidth - 15, pageHeight - 10, { align: 'right' });
                },
                foot: [['', '', '', 'TOTAL DO RELATÓRIO', '', '', '', formatCurrency(totalVal)]],
                footStyles: {
                    fillColor: [240, 240, 240],
                    textColor: [0, 0, 0],
                    fontStyle: 'bold',
                    halign: 'right'
                }
            });

            doc.save(`Relatorio_ContasPagar_${format(new Date(), 'yyyyMMdd_HHmm')}.pdf`);
            appStore.showSnackbar('PDF Gerado com sucesso!', 'success');
        }

    } catch (e: any) {
        console.error("Erro ao gerar relatório:", e);
        appStore.showSnackbar('Erro ao gerar relatório: ' + (e.message || e), 'error');
    } finally {
        reportLoading.value = false;
    }
};

const editModal = reactive({
  show: false, loading: false,
  error: null as string | null,
  activeTab: 'basic',
  isFixedAccount: false,
  files: [] as File[],
  projected: [] as any[],
  form: { id: '', description: '', entity_name: null as any, supplier_id: null as any, value: 0, discount: 0, due_date: '', competence_date: '', payment_date: '', chart_of_accounts_id: null as any, cost_center_id: null as any, status: '', bank_account_id: null as any, payment_method_id: null as any, company_id: null as any, notes: '', attachments: [] as string[], gestao_click_id: null as any },
  recurrence: { enabled: false, calcMethod: 'divide', count: 2, interval: 'month' as 'month' | 'week' }
});

const openNewPayableModal = () => {
  resetModal();
  editModal.isFixedAccount = false;
  editModal.recurrence.enabled = false;
  editModal.activeTab = 'basic';
  editModal.show = true;
};

const openFixedAccountModal = () => {
  resetModal();
  editModal.isFixedAccount = true;
  editModal.recurrence.enabled = true;
  editModal.recurrence.calcMethod = 'repeat';
  editModal.recurrence.count = 12;
  editModal.activeTab = 'recurrence';
  editModal.show = true;
};

const resetModal = () => {
   const defaultCompany = !companyStore.isGlobalView ? companyStore.context : null;
   Object.assign(editModal.form, {
      id: '', description: '', entity_name: null, supplier_id: null, value: 0, discount: 0,
      due_date: format(new Date(), 'yyyy-MM-dd'), competence_date: format(new Date(), 'yyyy-MM-dd'),
      payment_date: null, status: 'pendente', bank_account_id: null, payment_method_id: null,
      chart_of_accounts_id: null, cost_center_id: null, company_id: defaultCompany, notes: '', attachments: [], gestao_click_id: null
   });
   editModal.files = [];
   editModal.projected = [];
   editModal.error = null;
   editModal.recurrence.enabled = false;
   editModal.recurrence.calcMethod = 'divide';
};

const openEditModal = async (i: any) => {
    const { data: dbItem, error } = await supabase.from('finance_payables').select('*').eq('id', i.id).single();
    if(error || !dbItem) {
        appStore.showSnackbar('Erro ao carregar dados do lançamento', 'error');
        return;
    }

    const data = JSON.parse(JSON.stringify(dbItem));
    Object.assign(editModal.form, { ...data, attachments: data.attachments || [] });

    if (dbItem.supplier_id) { editModal.form.entity_name = dbItem.supplier_id; }
    else { editModal.form.entity_name = dbItem.entity_name; }

    editModal.files = [];
    editModal.projected = [];
    editModal.error = null;
    editModal.isFixedAccount = false;
    editModal.recurrence.enabled = false;
    editModal.activeTab = 'basic';
    editModal.show = true;
};

const openQuickAdd = async (type: string) => { if (type !== 'supplier') return; const name = prompt('Nome do fornecedor (será criado em Customers):'); if (!name || name.trim().length < 2) return; try { const { data, error } = await supabase.from('customers_mj').insert({ nome: name.trim() }).select('id, nome').single(); if (error) throw error; auxData.suppliers.push({ id: data.id, name: data.nome }); editModal.form.entity_name = data.id; appStore.showSnackbar('Fornecedor criado!', 'success'); } catch (e: any) { appStore.showSnackbar('Erro ao criar fornecedor: ' + (e.message || 'Falha'), 'error'); } };
const ensureChartOfAccounts = async (chartName: string) => { const name = String(chartName || '').trim(); if (!name) return null; const { data: existing } = await supabase.from('finance_chart_of_accounts').select('id').eq('name', name).eq('type', 'Despesa').maybeSingle(); if (existing?.id) return existing.id; const code = `ERP-${Date.now().toString().slice(-6)}`; const { data: created, error } = await supabase.from('finance_chart_of_accounts').insert({ code, name, type: 'Despesa', active: true, is_group: false }).select('id, name').single(); if (error) { console.warn('Falha ao criar plano de contas:', error); return null; } if (created) { auxData.chartOfAccounts.push(created); await logBusinessEvent('Financeiro - Pagar', 'INSERT', `Criou novo Plano de Contas: ${name}`, { name, code }, created.id); return created.id; } return null; };

const uploadAttachments = async (): Promise<string[]> => {
    if (editModal.files.length === 0) return [];
    const uploadedUrls: string[] = [];
    for (const file of editModal.files) {
        const fileExt = file.name.split('.').pop();
        const fileName = `${Date.now()}-${Math.random().toString(36).substring(7)}.${fileExt}`;
        const filePath = `payables/${fileName}`;
        const { error: uploadError } = await supabase.storage.from('finance-attachments').upload(filePath, file);
        if (uploadError) { console.error('Erro upload:', uploadError); continue; }
        const { data: publicUrlData } = supabase.storage.from('finance-attachments').getPublicUrl(filePath);
        if (publicUrlData.publicUrl) uploadedUrls.push(publicUrlData.publicUrl);
    }
    return uploadedUrls;
};

const removeAttachment = (index: number) => { if (confirm('Remover este anexo do formulário?')) editModal.form.attachments.splice(index, 1); }

const generateInstallments = () => {
  const count = Math.max(2, Number(editModal.recurrence.count));
  const totalBaseValue = Number(editModal.form.value);
  const method = editModal.recurrence.calcMethod;

  if (!editModal.form.due_date) {
      alert('Preencha a data de vencimento (aba Financeiro) primeiro.');
      return;
  }

  const baseDate = parseISO(editModal.form.due_date);
  const baseComp = editModal.form.competence_date ? parseISO(editModal.form.competence_date) : baseDate;

  editModal.projected = [];

  let installmentValue = totalBaseValue;
  if (method === 'divide') {
      installmentValue = totalBaseValue / count;
  }

  for (let i = 0; i < count; i++) {
      const d = editModal.recurrence.interval === 'month'
        ? addMonths(baseDate, i)
        : addDays(baseDate, i * 7);

      const c = editModal.recurrence.interval === 'month'
        ? addMonths(baseComp, i)
        : addDays(baseComp, i * 7);

      editModal.projected.push({
          installment: i + 1,
          description: `${editModal.form.description} (${i+1}/${count})`,
          value: parseFloat(installmentValue.toFixed(2)),
          due_date: format(d, 'yyyy-MM-dd'),
          competence_date: format(c, 'yyyy-MM-dd'),
          status: 'pendente'
      });
  }
};

const savePayable = async () => {
  editModal.loading = true;
  editModal.error = null;

  try {
    const newAttachments = await uploadAttachments();
    const finalAttachments = [...(editModal.form.attachments || []), ...newAttachments];

    const { id, ...data } = editModal.form;
    const basePayload: any = { ...data };
    basePayload.attachments = finalAttachments;

    if (!basePayload.payment_date) basePayload.payment_date = null;
    if (!basePayload.competence_date) basePayload.competence_date = null;
    if (!basePayload.supplier_id) basePayload.supplier_id = null;
    if (!basePayload.bank_account_id) basePayload.bank_account_id = null;
    if (!basePayload.payment_method_id) basePayload.payment_method_id = null;
    if (!basePayload.chart_of_accounts_id) basePayload.chart_of_accounts_id = null;
    if (!basePayload.cost_center_id) basePayload.cost_center_id = null;

    // Ajuste da lógica de preservação do company_id:
    // Só herdamos o company_id do contexto se o registro for NOVO (!id) e a empresa não tiver sido definida
    if (!id && !basePayload.company_id && !companyStore.isGlobalView && companyStore.context) {
        basePayload.company_id = companyStore.context;
    }

    if (!basePayload.company_id) {
        throw new Error('A empresa é obrigatória. Selecione uma empresa ou mude para um contexto específico.');
    }

    if (!id) {
        delete basePayload.gestao_click_id;
    }

    if (basePayload.entity_name) {
        const isSup = auxData.suppliers.find(s => s.id === basePayload.entity_name || s.name === basePayload.entity_name);
        const isEmp = auxData.employees.find(e => e.id === basePayload.entity_name || e.name === basePayload.entity_name);
        if (isSup) { basePayload.supplier_id = isSup.id; basePayload.entity_name = isSup.name; }
        else if (isEmp) { basePayload.supplier_id = null; basePayload.entity_name = isEmp.name; }
        else if (typeof basePayload.entity_name === 'string') { basePayload.entity_name = basePayload.entity_name; }
    }

    if (basePayload.chart_of_accounts_id && typeof basePayload.chart_of_accounts_id === 'string' && basePayload.chart_of_accounts_id.length < 30) {
        const createdId = await ensureChartOfAccounts(basePayload.chart_of_accounts_id);
        if (createdId) basePayload.chart_of_accounts_id = createdId;
    }

    if (!id && editModal.isFixedAccount) {
        if (editModal.projected.length === 0) {
             editModal.error = 'A lista de parcelas está vazia. Clique em "Gerar / Simular" antes de salvar.';
             editModal.loading = false;
             return;
        }

        const totalParcelas = editModal.recurrence.count;

        const payloads = editModal.projected.map(p => ({
            ...basePayload,
            installment_number: p.installment,
            total_installments: totalParcelas,
            description: p.description,
            value: p.value,
            due_date: String(p.due_date),
            competence_date: String(p.competence_date),
            status: 'pendente'
        }));

        const { error } = await supabase.from('finance_payables').insert(payloads);
        if (error) throw error;

        await logBusinessEvent('Financeiro - Pagar', 'INSERT', `Lançou ${payloads.length} contas a pagar fixas (recorrentes) para ${basePayload.entity_name}`, { total_value: basePayload.value, installments: payloads.length }, null, null);

    } else {
        if (id) {
            const { data: oldState } = await supabase.from('finance_payables').select('*').eq('id', id).single();
            const { error } = await supabase.from('finance_payables').update(basePayload).eq('id', id);
            if (error) throw error;
            await logBusinessEvent('Financeiro - Pagar', 'UPDATE', `Editou informações da conta a pagar de ${basePayload.entity_name}`, basePayload, id, oldState);
        } else {
            const { data: savedRecord, error } = await supabase.from('finance_payables').insert(basePayload).select().single();
            if (error) throw error;
            await logBusinessEvent('Financeiro - Pagar', 'INSERT', `Lançou nova conta a pagar (Manual) para ${basePayload.entity_name}`, basePayload, savedRecord.id);
        }
    }

    appStore.showSnackbar('Salvo com sucesso!', 'success');
    editModal.show = false;
    fetchPayables();
  } catch (e: any) {
      console.error('Erro no save:', e);
      editModal.error = e.message || 'Erro desconhecido ao salvar';
  } finally {
      editModal.loading = false;
  }
};

const toggleStatus = async (item: any) => {
    const newStatus = item.status === 'pago' ? 'pendente' : 'pago';
    const paymentDate = newStatus === 'pago' ? new Date().toISOString().split('T')[0] : null;

    const oldState = { ...item };
    await supabase.from('finance_payables').update({ status: newStatus, payment_date: paymentDate }).eq('id', item.id);

    const msg = newStatus === 'pago' ? `Efetuou pagamento para ${getSupplierName(item)}` : `Estornou pagamento de ${getSupplierName(item)}`;
    await logBusinessEvent('Financeiro - Pagar', 'STATUS_CHANGE', msg, { new_status: newStatus, payment_date: paymentDate }, item.id, oldState);

    item.status = newStatus;
    fetchPayables();
};

const deletePayable = async (item: any) => {
    if (!confirm('Excluir este pagamento?')) return;
    const oldState = { ...item };
    await supabase.from('finance_payables').delete().eq('id', item.id);

    await logBusinessEvent('Financeiro - Pagar', 'DELETE', `Excluiu a conta a pagar de ${getSupplierName(item)}`, null, item.id, oldState);

    fetchPayables();
};

const deleteSelected = async () => {
    if (!confirm(`Excluir permanentemente ${selectedIds.value.size} itens?`)) return;
    loading.value = true;
    try {
        const ids = Array.from(selectedIds.value);
        const { error } = await supabase.from('finance_payables').delete().in('id', ids);
        if (error) throw error;

        await logBusinessEvent('Financeiro - Pagar', 'DELETE', `Excluiu ${ids.length} contas a pagar em lote.`, { idsDeleted: ids }, null, null);

        selectedIds.value.clear();
        appStore.showSnackbar(`${ids.length} itens excluídos`, 'success');
        fetchPayables();
    } catch (e: any) {
        appStore.showSnackbar('Erro: ' + e.message, 'error');
    } finally {
        loading.value = false;
    }
};

const getSafeAttachments = (item: any) => {
    if (!item.attachments) return [];
    if (Array.isArray(item.attachments)) return item.attachments;
    try {
        if (typeof item.attachments === 'string') {
            const cleanStr = item.attachments.startsWith('"') && item.attachments.endsWith('"')
                ? item.attachments.slice(1, -1)
                : item.attachments;
            return JSON.parse(cleanStr);
        }
    } catch (e) {
        console.warn('Erro ao ler anexo:', e);
    }
    return [];
};

const hasAttachments = (item: any) => {
    const att = getSafeAttachments(item);
    return att && att.length > 0;
};

const openAttachment = (item: any) => {
    const att = getSafeAttachments(item);
    if (att && att.length > 0) {
        window.open(att[0], '_blank');
    } else {
        appStore.showSnackbar('Não foi possível abrir o anexo.', 'warning');
    }
};

const importFields = computed(() => [ { key: 'description', label: 'Descrição', required: true, type: 'string' }, { key: 'entity_name', label: 'Fornecedor', required: true, type: 'string' }, { key: 'value', label: 'Valor', required: true, type: 'number' }, { key: 'due_date', label: 'Vencimento', required: true, type: 'date' }, { key: 'status', label: 'Status', required: false, type: 'string' }, { key: 'chart_of_accounts_id', label: 'Plano de Contas', required: false, type: 'reference', validationList: auxData.chartOfAccounts }, { key: 'cost_center_id', label: 'Centro de Custo', required: false, type: 'reference', validationList: auxData.costCenters }, { key: 'company_id', label: 'Empresa', required: false, type: 'reference', validationList: auxData.companies }, { key: 'notes', label: 'Observação', type: 'string' } ]);
const handleImportData = async (data: any[]) => {
    loading.value = true;
    try {
        const preparedData: any[] = [];
        for (const row of data) {
            if (row.chart_of_accounts_id && typeof row.chart_of_accounts_id === 'string' && row.chart_of_accounts_id.length < 30) {
                const chartId = await ensureChartOfAccounts(row.chart_of_accounts_id);
                row.chart_of_accounts_id = chartId;
            }
            let dbStatus = 'pendente';
            if (row.status && ['pago', 'recebido', 'confirmado', 'liquidado'].some(x => String(row.status).toLowerCase().includes(x))) dbStatus = 'pago';
            preparedData.push({
                description: row.description, entity_name: row.entity_name, value: row.value, due_date: row.due_date,
                competence_date: row.competence_date || row.due_date, status: dbStatus,
                payment_date: dbStatus === 'pago' ? (row.payment_date || new Date().toISOString().split('T')[0]) : null,
                chart_of_accounts_id: row.chart_of_accounts_id || null, cost_center_id: row.cost_center_id || null,
                company_id: row.company_id || null, notes: row.notes || row.observation
            });
        }

        if (preparedData.length > 0) {
            const { error } = await supabase.from('finance_payables').insert(preparedData);
            if (error) throw error;

            await logBusinessEvent('Financeiro - Pagar', 'IMPORT', `Importou ${preparedData.length} contas a pagar via planilha Excel.`, { count: preparedData.length }, null, null);

            appStore.showSnackbar(`${preparedData.length} registros importados com sucesso!`, 'success');
            fetchPayables();
        }
    } catch (e: any) {
        appStore.showSnackbar('Erro na importação: ' + (e.message || e.details), 'error');
    } finally {
        loading.value = false;
    }
};

watch(() => companyStore.context, () => {
    page.value = 1;
    fetchPayables();
});

onMounted(() => {
    fetchAuxiliaryData();
    fetchPayables();
    loadGridSettings();
});
onUnmounted(() => { if (autoSyncInterval.value) clearInterval(autoSyncInterval.value); });
</script>

<style scoped lang="scss">
/* Layout Geral */
.payables-layout { position: relative; }
.background-carousel-wrapper { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 0; opacity: 0.6; pointer-events: none; }
.background-overlay { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 1; background: radial-gradient(circle at center, rgba(15, 15, 19, 0.4), rgba(15, 15, 19, 0.98)); backdrop-filter: blur(8px); }
.z-10 { position: relative; z-index: 10; }
.bg-glass-dark { background: rgba(10,10,12,0.85); }
.bg-glass-header { background: rgba(20,20,24,0.55); backdrop-filter: blur(14px); }
.border-bottom-white-05 { border-bottom: 1px solid rgba(255,255,255,0.08); }
.border-top-white-05 { border-top: 1px solid rgba(255,255,255,0.08); }
.border-white-10 { border: 1px solid rgba(255,255,255,0.1) !important; }
.controls-bar { border: 1px solid rgba(0,0,0,0.08); padding: 10px; }
.controls-light { background: #ffffff; }
.controls-dark { background: rgba(30,30,35,0.55); backdrop-filter: blur(16px); border: 1px solid rgba(255,255,255,0.08); }
.period-nav { border-radius: 0; height: 40px; overflow: hidden; }
.period-nav-light { border: 1px solid rgba(0,0,0,0.12); background: #fafafa; }
.period-nav-dark { border: 1px solid rgba(255,255,255,0.10); background: rgba(255,255,255,0.06); }
.period-label { min-width: 190px; display: flex; align-items: center; justify-content: center; height: 40px; }
.search-wrap { height: 40px; padding: 0 12px; border: 1px solid rgba(0,0,0,0.08); display: flex; align-items: center; min-width: 300px; flex: 1; }

.hide-scrollbar::-webkit-scrollbar { display: none; }
.hide-scrollbar { -ms-overflow-style: none; scrollbar-width: none; }

@media (max-width: 600px) {
  .search-wrap { min-width: 100%; }
}

.search-light { background: #f4f6f8; border: 1px solid rgba(0,0,0,0.08); }
.search-dark { background: rgba(255,255,255,0.08); border: 1px solid rgba(255,255,255,0.10); }
.clean-input { border: none; outline: none; background: transparent; font-size: 13px; color: inherit; flex: 1; }

/* ========================================================
   GRID LAYOUT FLUIDO E RESPONSIVO DINÂMICO
   ======================================================== */
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

/* Grid & Scroll System Variables */
.grid-scroll { scrollbar-gutter: stable; -webkit-overflow-scrolling: touch; }
.custom-scroll::-webkit-scrollbar { width: 8px; height: 8px; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.35); border-radius: 6px; }
.custom-scroll::-webkit-scrollbar-track { background: transparent; }

/* KPI Desktop */
.kpi-bg-icon { position: absolute; right: -20px; bottom: -20px; opacity: 0.15; transform: rotate(-15deg); pointer-events: none; z-index: 0; }
.kpi-bg-icon .v-icon { font-size: 100px; color: white; }
.kpi-card { border: 1px solid rgba(255,255,255,0.15); color: white; min-height: 110px; position: relative; overflow: hidden; transition: all 0.2s ease; }
.kpi-rect { border-radius: 0 !important; }
.kpi-active-border { border: 2px solid white !important; box-shadow: 0 0 15px rgba(255,255,255,0.3); transform: translateY(-2px); }

/* KPI Mobile Improved */
.kpi-bg-icon-mobile { position: absolute; right: -5px; bottom: -5px; opacity: 0.15; transform: rotate(-10deg); }
.kpi-bg-icon-mobile .v-icon { font-size: 60px; color: white; }
.text-shadow-sm { text-shadow: 0 2px 4px rgba(0,0,0,0.2); }

.bg-gradient-info { background: linear-gradient(135deg, #0288d1, #005b9f); }
.bg-gradient-green { background: linear-gradient(135deg, #2e7d32, #1b5e20); }
.bg-gradient-red { background: linear-gradient(135deg, #c62828, #8e0000); }
.bg-gradient-purple { background: linear-gradient(135deg, #7b1fa2, #4a148c); }
.bg-gradient-warning { background: linear-gradient(135deg, #FFB300, #F57F17); }
.kpi-label { font-size: 12px; font-weight: 900; letter-spacing: .2px; }
.kpi-value { font-size: 22px; font-weight: 900; letter-spacing: .2px; }
.kpi-footer { font-size: 11px; opacity: .9; font-weight: 700; }
.glass-card { background: rgba(30, 30, 35, 0.45); backdrop-filter: blur(25px); border: 1px solid rgba(255,255,255,0.08); }
.bg-white-05 { background: rgba(255,255,255,0.05); }
.bg-white-10 { background: rgba(255,255,255,0.1); }
.bg-white-20 { background: rgba(255,255,255,0.2); }

/* Themes & Cells */
.grid-surface-light .cell { background: #f5f7fa; color: rgba(0,0,0,0.9); border-color: rgba(0,0,0,0.12) !important; }
.grid-surface-dark .cell { background: rgba(255,255,255,0.08); color: rgba(255,255,255,0.95); border-color: rgba(255,255,255,0.10) !important; }

/* Bordas internas mais suaves nas linhas de dados */
.grid-row-light .cell { border-color: rgba(0,0,0,0.08) !important; }
.grid-row-dark .cell { border-color: rgba(255,255,255,0.08) !important; }

/* Zebrado Forte Elegante */
.zebra-light-a .cell { background: #ffffff; }
.zebra-light-b .cell { background: #f0f4f8; }
.zebra-dark-a .cell { background: rgba(0,0,0,0.15); }
.zebra-dark-b .cell { background: rgba(255,255,255,0.03); }

/* Hover Marcante em toda a Linha */
.grid-row-light:hover .cell { background: #e3f2fd !important; }
.grid-row-dark:hover .cell { background: rgba(255,255,255,0.12) !important; }

.grid-selected-light .cell { background: #ffebee !important; }
.grid-selected-dark .cell { background: rgba(255,255,255,0.10) !important; }

/* Cabeçalho Fixo com Efeito de Elevação */
.sticky-head {
    position: sticky;
    top: 0;
    z-index: 20;
    box-shadow: 0 8px 16px -4px rgba(0, 0, 0, 0.12);
}

.bg-glass-dark .sticky-head {
    box-shadow: 0 8px 20px -4px rgba(0, 0, 0, 0.4);
}

.pill-ref { font-size: 12px !important; font-weight: 900; font-family: monospace; background: rgba(0,0,0,0.06); padding: 4px 6px; border-radius: 0px; white-space: nowrap; }
.solid-chip { display: inline-flex; align-items: center; justify-content: center; height: 28px; padding: 0 12px; font-weight: 900; color: #fff; white-space: nowrap; text-transform: uppercase; }
.chip-status { min-width: 70px; }
.chip-company { background: #455a64; }
.chip-success { background: #2e7d32; }
.chip-warn { background: #f57f17; }
.chip-danger { background: #c62828; }
.chip-info { background: #1976d2; }

/* Buttons & Inputs Override */
.actions-inline { display: flex; align-items: center; justify-content: center; gap: 4px; flex-wrap: nowrap !important; }
.action-btn { width: 28px !important; height: 28px !important; border-radius: 6px !important; color: #fff !important; }
.action-btn :deep(.v-icon) { color: #fff !important; font-size: 16px !important; }
.action-edit { background: #1976d2 !important; }
.action-pay { background: #2e7d32 !important; }
.action-revert { background: #f57f17 !important; }
.action-del { background: #c62828 !important; }
.ui-field :deep(.v-field) { border-radius: 0 !important; }
.ui-field :deep(.v-field__input) { min-height: 40px !important; padding-top: 6px !important; padding-bottom: 6px !important; }
.ui-field :deep(.v-field__prepend-inner) { margin-right: 8px !important; }
.row-gap { row-gap: 14px; }

/* EFEITOS 3D */
.btn-3d {
    border-radius: 6px !important;
    box-shadow: 0 3px 5px rgba(0,0,0,0.15), inset 0 2px 0 rgba(255,255,255,0.25) !important;
    transition: transform 0.1s ease, box-shadow 0.1s ease;
    text-transform: none !important;
}
.btn-3d:active {
    transform: translateY(2px);
    box-shadow: 0 1px 2px rgba(0,0,0,0.15), inset 0 1px 0 rgba(255,255,255,0.2) !important;
}

.chip-3d {
    border-radius: 6px !important;
    box-shadow: 0 3px 5px rgba(0,0,0,0.12), inset 0 1px 0 rgba(255,255,255,0.25) !important;
    text-shadow: 0 1px 2px rgba(0,0,0,0.25);
}

.fixed-dialog { overflow: hidden !important; }
.absolute-fill { height: 100%; overflow-y: auto; }
.hover-grey:hover { background-color: #f5f5f5 !important; }

/* Floating Selection Bar */
.selection-island-wrapper {
    position: absolute;
    bottom: 30px;
    left: 0;
    right: 0;
    display: flex;
    justify-content: center;
    z-index: 100;
    pointer-events: none;
}

.selection-island {
    pointer-events: auto;
    background: #1e1e24;
    border-radius: 12px;
    padding: 8px 16px;
    display: flex;
    align-items: center;
    gap: 8px;
    border: 1px solid rgba(255,255,255,0.1);
    box-shadow: 0 10px 30px rgba(0,0,0,0.3);
    @media (max-width: 600px) {
        width: 95%;
        flex-wrap: nowrap;
        justify-content: flex-start;
        overflow-x: auto;
        padding-bottom: 12px;
    }
}

/* ========================================================
   CONTORNO EXTERNO DA GRID (MOLDURA)
   ======================================================== */
.flex-grow-1.overflow-hidden > .v-card.flex-grow-1 {
    border: 1px solid rgba(0,0,0,0.12) !important;
}
.bg-glass-dark .flex-grow-1.overflow-hidden > .v-card.flex-grow-1 {
    border: 1px solid rgba(255,255,255,0.12) !important;
}

/* FIX PARA TEXTOS CINZAS NO MODO ESCURO */
.v-theme--dark {
  .text-grey-darken-4, .text-grey-darken-3, .text-grey-darken-2, .text-grey-darken-1, .text-grey {
    color: rgba(255,255,255,0.9) !important;
  }
}

/* EFEITOS DA CONCILIAÇÃO BANCÁRIA */
.pulse-success { animation: pulse-success-scale 2s infinite; }
@keyframes pulse-success-scale { 0% { transform: scale(1); opacity: 0.8; color: #00695C; } 50% { transform: scale(1.2); opacity: 1; color: #00BFA5; } 100% { transform: scale(1); opacity: 0.8; color: #00695C; } }

.pulse-box { animation: pulse-box-glow 2s infinite; }
@keyframes pulse-box-glow { 0% { box-shadow: 0 0 0 0 rgba(0, 191, 165, 0.4); } 70% { box-shadow: 0 0 0 6px rgba(0, 191, 165, 0); } 100% { box-shadow: 0 0 0 0 rgba(0, 191, 165, 0); } }

:deep(.tooltip-conciliated) {
    background: rgba(10, 10, 12, 0.95) !important;
    border: 1px solid #1DE9B6 !important;
    box-shadow: 0 4px 15px rgba(0, 191, 165, 0.3) !important;
    backdrop-filter: blur(10px);
}
</style>
