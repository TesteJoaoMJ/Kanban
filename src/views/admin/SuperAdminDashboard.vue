<template>
  <v-container fluid class="admin-dashboard-container dashboard-readable-lite pa-6" :class="{ 'light-mode-container': themeStore.currentMode === 'light' }">

    <Transition name="context-island-float">
      <div v-show="isContextIslandFloating" class="floating-context-island">
        <div class="floating-island-inner">
          <div class="floating-island-label d-none d-md-flex">
            <v-icon size="14">mdi-swap-horizontal</v-icon>
            <span>Visão</span>
          </div>

          <v-btn
            v-for="btn in tenantContextButtons"
            :key="btn.id"
            size="x-small"
            height="28"
            :variant="companyStore.context === btn.id ? 'flat' : 'text'"
            :color="companyStore.context === btn.id ? (btn.isHolding ? 'purple' : btn.color) : undefined"
            class="font-weight-black floating-context-btn rounded-lg"
            :class="companyStore.context === btn.id ? 'floating-context-btn-active' : 'floating-context-btn-idle'"
            @click="setTenantContext(btn.id)"
          >
            {{ btn.name }}
          </v-btn>
        </div>
      </div>
    </Transition>

    <div class="header-section executive-header executive-header-clean mb-8 animate-fade-in-down" :class="themeStore.currentMode === 'light' ? 'executive-header-light' : 'executive-header-dark'">
      <div class="dashboard-header-inner d-flex flex-column flex-lg-row justify-space-between align-start align-lg-center ga-4">

        <div class="dashboard-title-group d-flex align-center">
          <div
            class="icon-box-lg mr-5 rounded-xl d-flex align-center justify-center transition-all card-3d"
            :class="contextIconColor"
          >
            <v-icon color="white" size="32">{{ contextIcon }}</v-icon>
          </div>
          <div>
            <div class="dashboard-breadcrumb d-flex align-center text-caption font-weight-black mb-1">
              <span>COMANDO CENTRAL</span>
              <v-icon size="x-small" class="mx-2">mdi-chevron-right</v-icon>
              <span>{{ currentContextTitle }}</span>
            </div>
             <div class="d-flex align-center">
                <h1 class="dashboard-title font-weight-black mr-2" :class="themeStore.currentMode === 'light' ? 'text-slate-strong' : 'text-white'">
                   Bem-vindo, {{ userStore.profile?.full_name?.split(' ')[0] || 'Gestor' }}!
                </h1>
                <span class="text-h4 wave-hand">👋</span>
             </div>
             <Transition name="context-dock">
               <div v-show="!isContextIslandFloating" class="context-switcher context-switcher-docked d-flex align-center flex-wrap mt-3">
                  <v-btn
                     v-for="btn in tenantContextButtons"
                     :key="btn.id"
                     size="x-small"
                     height="26"
                     :variant="companyStore.context === btn.id ? 'flat' : 'elevated'"
                     :color="companyStore.context === btn.id ? (btn.isHolding ? 'purple' : btn.color) : undefined"
                     class="font-weight-black btn-context-3d px-4 rounded-lg flex-shrink-0"
                     :class="companyStore.context === btn.id ? 'btn-context-active' : 'btn-context-idle'"
                     style="font-size: 10px; letter-spacing: 0.55px;"
                     @click="setTenantContext(btn.id)"
                  >
                     {{ btn.name }}
                  </v-btn>
               </div>
             </Transition>



             <p class="text-medium-emphasis">{{ dashboardSubtitle }}</p>
          </div>
        </div>


        <div class="dashboard-actions-group d-flex align-center justify-end">
          <v-menu v-model="panelMenuOpen" location="bottom end" :close-on-content-click="false">
               <template v-slot:activator="{ props }">
                  <v-btn v-bind="props" variant="flat" color="indigo" class="btn-3d font-weight-bold panel-options-btn panel-options-inline" height="34" prepend-icon="mdi-view-dashboard-edit">
                     Opções do Painel
                     <v-icon end>mdi-chevron-down</v-icon>
                  </v-btn>
               </template>
               <v-list density="compact" nav class="border-thin shadow-lg rounded-lg" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-grey-darken-4 text-white'" width="280">

                  <v-list-subheader class="text-uppercase text-[10px] font-weight-black opacity-70">Ações Rápidas</v-list-subheader>
                  <v-list-item @click="refreshData(); panelMenuOpen = false" prepend-icon="mdi-refresh">
                     <v-list-item-title class="font-weight-bold">Recarregar Dados</v-list-item-title>
                  </v-list-item>
                  <v-list-item @click="openSyncModal(); panelMenuOpen = false" prepend-icon="mdi-cloud-sync" :class="themeStore.currentMode === 'light' ? 'text-orange-darken-3' : 'text-orange-lighten-1'">
                     <v-list-item-title class="font-weight-bold">Sincronizar ERP Externo</v-list-item-title>
                  </v-list-item>

                  <v-divider class="my-1"></v-divider>

                  <v-list-subheader class="text-uppercase text-[10px] font-weight-black opacity-70">Exibição de Blocos</v-list-subheader>
                  <v-list-item @click="toggleBlock('MJ')">
                     <template v-slot:prepend><v-checkbox-btn :model-value="visibleBlocks.includes('MJ')" density="compact" color="indigo" hide-details></v-checkbox-btn></template>
                     <v-list-item-title class="font-weight-bold ml-2">Indústria (MJ)</v-list-item-title>
                  </v-list-item>
                  <v-list-item @click="toggleBlock('CAJUIA')">
                     <template v-slot:prepend><v-checkbox-btn :model-value="visibleBlocks.includes('CAJUIA')" density="compact" color="indigo" hide-details></v-checkbox-btn></template>
                     <v-list-item-title class="font-weight-bold ml-2">Varejo (Cajuia)</v-list-item-title>
                  </v-list-item>
                  <v-list-item @click="toggleBlock('UNLINKED')">
                     <template v-slot:prepend><v-checkbox-btn :model-value="visibleBlocks.includes('UNLINKED')" density="compact" color="indigo" hide-details></v-checkbox-btn></template>
                     <v-list-item-title class="font-weight-bold ml-2">Não Vinculados</v-list-item-title>
                  </v-list-item>
                  <v-list-item v-for="comp in displayedExtraCompanies" :key="'toggle-'+comp.id" @click="toggleBlock(comp.id)">
                     <template v-slot:prepend><v-checkbox-btn :model-value="visibleBlocks.includes(comp.id)" density="compact" color="indigo" hide-details></v-checkbox-btn></template>
                     <v-list-item-title class="font-weight-bold ml-2 text-truncate" :title="comp.name">{{ comp.name }}</v-list-item-title>
                  </v-list-item>

                  <v-divider class="my-1"></v-divider>

                  <v-list-subheader class="text-uppercase text-[10px] font-weight-black opacity-70">Gerenciamento</v-list-subheader>
                  <v-list-item @click="openAddCompanyModal(); panelMenuOpen = false" prepend-icon="mdi-domain-plus" :class="themeStore.currentMode === 'light' ? 'text-primary' : 'text-blue-lighten-2'">
                     <v-list-item-title class="font-weight-bold">Adicionar Empresa ao Painel</v-list-item-title>
                  </v-list-item>

                  <v-divider class="my-1"></v-divider>

                  <v-list-subheader class="text-uppercase text-[10px] font-weight-black opacity-70">Alternar Contexto Base</v-list-subheader>
                  <v-list-item v-for="ctx in contexts" :key="ctx.value" :value="ctx.value" @click="currentContext = ctx.value; panelMenuOpen = false">
                     <template v-slot:prepend><v-icon :icon="ctx.icon"></v-icon></template>
                     <v-list-item-title class="font-weight-bold">{{ ctx.title }}</v-list-item-title>
                  </v-list-item>
               </v-list>
           </v-menu>
        </div>
      </div>
    </div>

    <div class="animate-fade-in-up">

      <div class="dashboard-filter-bar d-flex align-center justify-end mb-4 flex-wrap" style="gap: 8px;">
         <span class="text-caption font-weight-bold text-uppercase mr-1" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-1' : 'text-medium-emphasis'">
            Filtro de Balanço:
         </span>
         <v-btn-toggle v-model="globalFilter" density="compact" variant="outlined" divided class="rounded-lg btn-3d balance-filter-toggle" :color="themeStore.currentMode === 'light' ? 'indigo-darken-2' : 'white'" mandatory @update:model-value="onGlobalFilterChange">
            <v-btn value="today" class="px-4 font-weight-bold text-caption text-uppercase">Hoje</v-btn>
            <v-btn value="month" class="px-4 font-weight-bold text-caption text-uppercase">Este Mês</v-btn>
            <v-btn value="year" class="px-4 font-weight-bold text-caption text-uppercase">Este Ano</v-btn>
            <v-btn value="custom" class="px-4 font-weight-bold text-caption text-uppercase">Personalizado</v-btn>
         </v-btn-toggle>

         <v-menu v-if="globalFilter === 'custom'" :close-on-content-click="false" location="bottom end">
            <template v-slot:activator="{ props }">
               <v-btn v-bind="props" height="32" variant="flat" color="indigo" class="font-weight-bold ml-1 btn-3d" prepend-icon="mdi-calendar-range">
                  {{ formatDateSimple(customStartDate) }} até {{ formatDateSimple(customEndDate) }}
               </v-btn>
            </template>
            <v-card class="pa-4 rounded-xl shadow-lg border-thin card-3d" min-width="320" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'glass-card'">
               <div class="text-subtitle-2 font-weight-bold mb-3 text-uppercase">Período Personalizado</div>
               <v-text-field v-model="customStartDate" type="date" label="Data Inicial" density="compact" variant="outlined" class="mb-2 ui-field"></v-text-field>
               <v-text-field v-model="customEndDate" type="date" label="Data Final" density="compact" variant="outlined" class="ui-field"></v-text-field>
               <v-btn block color="indigo" variant="flat" class="mt-2 font-weight-bold btn-3d" @click="applyCustomFilter">Aplicar Filtro</v-btn>
            </v-card>
         </v-menu>

         <v-menu location="bottom end">
            <template v-slot:activator="{ props }">
               <v-btn v-bind="props" height="32" :color="themeStore.currentMode === 'light' ? 'grey-darken-3' : 'white'" variant="flat" prepend-icon="mdi-file-chart" class="font-weight-bold ml-3 btn-3d text-uppercase" :loading="reportLoading">
                  Relatórios
                  <v-icon end size="small">mdi-chevron-down</v-icon>
               </v-btn>
            </template>
            <v-card class="rounded-lg shadow-lg border-thin">
                <v-list density="compact" nav>
                   <v-list-item @click="generateReport('pdf')" prepend-icon="mdi-file-pdf-box" title="Exportar PDF (Geral)" class="text-red-darken-3 font-weight-bold"></v-list-item>
                   <v-list-item @click="generateReport('excel')" prepend-icon="mdi-microsoft-excel" title="Exportar Excel (Dados)" class="text-green-darken-3 font-weight-bold"></v-list-item>
                </v-list>
            </v-card>
         </v-menu>
      </div>

      <v-row dense class="mb-4" v-show="(currentContext === 'general' && visibleBlocks.includes('MJ')) || currentContext === 'mj'">
        <v-col cols="12" md="3">
          <v-card class="kpi-card-3d bg-gradient-red" v-ripple>
            <div class="kpi-bg-icon"><v-icon>mdi-calendar-arrow-right</v-icon></div>
            <div class="d-flex flex-column position-relative z-10 h-100 justify-space-between">
              <div>
                <div class="d-flex align-center mb-1">
                   <v-icon color="white" size="small" class="mr-2">mdi-factory</v-icon>
                   <span class="kpi-label text-white" style="font-size: 16px;">{{ shortNameIndustry }} • A PAGAR</span>
                </div>
                <div class="kpi-number-group mt-1">
                  <span class="kpi-unit mr-1 text-h6 opacity-80">R$</span>
                  <span class="kpi-value text-h4 font-mono">{{ formatCurrencyNoSymbol(mjExecution.missingPay) }}</span>
                </div>
              </div>
              <div class="kpi-footer bg-black-20 justify-space-between w-100 pr-1 mt-2 rounded">
                <span class="d-flex align-center"><v-icon size="small" color="white" class="mr-1">mdi-calendar-range</v-icon> PENDENTE ({{ formatFilterLabel.toUpperCase() }})</span>
                <v-btn variant="text" density="compact" size="small" class="px-0 text-white font-weight-bold" @click="goToFinancial('payable', mjCompanyId)">Detalhado <v-icon end size="small">mdi-arrow-right</v-icon></v-btn>
              </div>
            </div>
          </v-card>
        </v-col>

        <v-col cols="12" md="3">
          <v-card class="kpi-card-3d bg-gradient-green" v-ripple>
            <div class="kpi-bg-icon"><v-icon>mdi-cash-fast</v-icon></div>
            <div class="d-flex flex-column position-relative z-10 h-100 justify-space-between">
               <div>
                  <div class="d-flex align-center mb-1">
                     <v-icon color="white" size="small" class="mr-2">mdi-factory</v-icon>
                     <span class="kpi-label text-white" style="font-size: 16px;">{{ shortNameIndustry }} • A RECEBER</span>
                  </div>
                  <div class="kpi-number-group mt-1">
                    <span class="kpi-unit mr-1 text-h6 opacity-80">R$</span>
                    <span class="kpi-value text-h4 font-mono">{{ formatCurrencyNoSymbol(mjExecution.missingRec) }}</span>
                  </div>
               </div>
               <div class="kpi-footer bg-black-20 justify-space-between w-100 pr-1 mt-2 rounded">
                 <span class="d-flex align-center"><v-icon size="small" color="white" class="mr-1">mdi-calendar-range</v-icon> PENDENTE ({{ formatFilterLabel.toUpperCase() }})</span>
                 <v-btn variant="text" density="compact" size="small" class="px-0 text-white font-weight-bold" @click="goToFinancial('receivable', mjCompanyId)">Detalhado <v-icon end size="small">mdi-arrow-right</v-icon></v-btn>
               </div>
            </div>
          </v-card>
        </v-col>

        <v-col cols="12" md="6">
          <v-card class="kpi-card-3d bg-gradient-blue d-flex flex-column justify-center px-5 py-3" v-ripple>
             <div class="kpi-bg-icon" style="right: -30px; bottom: -40px; opacity: 0.08;"><v-icon size="190">mdi-chart-pie</v-icon></div>

             <div class="d-flex align-center mb-3 position-relative z-10">
                <v-icon color="white" size="small" class="mr-2 opacity-80">mdi-chart-line</v-icon>
                <span class="kpi-label text-white-80" style="font-size: 16px;">{{ shortNameIndustry }} • BALANÇO ({{ formatFilterLabel.toUpperCase() }})</span>
             </div>

             <div class="d-flex align-center justify-space-between position-relative z-10 w-100">
                <div class="d-flex align-center flex-grow-1 pr-4 border-r border-white-10">
                   <div style="height: 84px; width: 84px; min-width: 84px;" class="mr-4">
                      <Doughnut :data="mjRecDoughnutData" :options="miniChartOptions" />
                   </div>
                   <div class="flex-grow-1">
                      <div class="font-weight-black text-green-accent-2 mb-1" style="font-size: 16px; letter-spacing: 0.5px;">RECEITAS</div>
                      <div class="d-flex flex-column text-white-90" style="font-size: 16px; line-height: 1.5; gap: 2px;">
                         <div class="d-flex justify-space-between"><span>Previsto:</span> <strong class="font-mono">{{ formatCurrencyNoSymbol(mjReceivablesTotal) }}</strong></div>
                         <div class="d-flex justify-space-between"><span>Real:</span> <strong class="text-green-accent-1 font-mono">{{ formatCurrencyNoSymbol(mjExecution.received) }}</strong></div>
                         <div class="d-flex justify-space-between opacity-70"><span>Falta:</span> <span class="font-mono">{{ formatCurrencyNoSymbol(mjExecution.missingRec) }}</span></div>
                      </div>
                   </div>
                </div>
                <div class="d-flex align-center flex-grow-1 pl-4">
                   <div style="height: 84px; width: 84px; min-width: 84px;" class="mr-4">
                      <Doughnut :data="mjPayDoughnutData" :options="miniChartOptions" />
                   </div>
                   <div class="flex-grow-1">
                      <div class="font-weight-black text-red-accent-2 mb-1" style="font-size: 16px; letter-spacing: 0.5px;">DESPESAS</div>
                      <div class="d-flex flex-column text-white-90" style="font-size: 16px; line-height: 1.5; gap: 2px;">
                         <div class="d-flex justify-space-between"><span>Previsto:</span> <strong class="font-mono">{{ formatCurrencyNoSymbol(mjPayablesTotal) }}</strong></div>
                         <div class="d-flex justify-space-between"><span>Real:</span> <strong class="text-red-accent-1 font-mono">{{ formatCurrencyNoSymbol(mjExecution.paid) }}</strong></div>
                         <div class="d-flex justify-space-between opacity-70"><span>Falta:</span> <span class="font-mono">{{ formatCurrencyNoSymbol(mjExecution.missingPay) }}</span></div>
                      </div>
                   </div>
                </div>
             </div>
          </v-card>
        </v-col>
      </v-row>

      <v-row dense class="mb-4" v-show="(currentContext === 'general' && visibleBlocks.includes('CAJUIA')) || currentContext === 'cajuia'">
        <v-col cols="12" md="3">
          <v-card class="kpi-card-3d bg-gradient-red" v-ripple>
            <div class="kpi-bg-icon"><v-icon>mdi-calendar-arrow-right</v-icon></div>
            <div class="d-flex flex-column position-relative z-10 h-100 justify-space-between">
              <div>
                 <div class="d-flex align-center mb-1">
                    <v-icon color="white" size="small" class="mr-2">mdi-storefront</v-icon>
                    <span class="kpi-label text-white" style="font-size: 16px;">{{ shortNameRetail }} • A PAGAR</span>
                 </div>
                 <div class="kpi-number-group mt-1">
                   <span class="kpi-unit mr-1 text-h6 opacity-80">R$</span>
                   <span class="kpi-value text-h4 font-mono">{{ formatCurrencyNoSymbol(cajuiaExecution.missingPay) }}</span>
                 </div>
              </div>
              <div class="kpi-footer bg-black-20 justify-space-between w-100 pr-1 mt-2 rounded">
                <span class="d-flex align-center"><v-icon size="small" color="white" class="mr-1">mdi-calendar-range</v-icon> PENDENTE ({{ formatFilterLabel.toUpperCase() }})</span>
                <v-btn variant="text" density="compact" size="small" class="px-0 text-white font-weight-bold" @click="goToFinancial('payable', cjCompanyId)">Detalhado <v-icon end size="small">mdi-arrow-right</v-icon></v-btn>
              </div>
            </div>
          </v-card>
        </v-col>

        <v-col cols="12" md="3">
          <v-card class="kpi-card-3d bg-gradient-green" v-ripple>
            <div class="kpi-bg-icon"><v-icon>mdi-cash-fast</v-icon></div>
            <div class="d-flex flex-column position-relative z-10 h-100 justify-space-between">
               <div>
                  <div class="d-flex align-center mb-1">
                     <v-icon color="white" size="small" class="mr-2">mdi-storefront</v-icon>
                     <span class="kpi-label text-white" style="font-size: 16px;">{{ shortNameRetail }} • A RECEBER</span>
                  </div>
                  <div class="kpi-number-group mt-1">
                    <span class="kpi-unit mr-1 text-h6 opacity-80">R$</span>
                    <span class="kpi-value text-h4 font-mono">{{ formatCurrencyNoSymbol(cajuiaExecution.missingRec) }}</span>
                  </div>
               </div>
               <div class="kpi-footer bg-black-20 justify-space-between w-100 pr-1 mt-2 rounded">
                 <span class="d-flex align-center"><v-icon size="small" color="white" class="mr-1">mdi-calendar-range</v-icon> PENDENTE ({{ formatFilterLabel.toUpperCase() }})</span>
                 <v-btn variant="text" density="compact" size="small" class="px-0 text-white font-weight-bold" @click="goToFinancial('receivable', cjCompanyId)">Detalhado <v-icon end size="small">mdi-arrow-right</v-icon></v-btn>
               </div>
            </div>
          </v-card>
        </v-col>

        <v-col cols="12" md="6">
          <v-card class="kpi-card-3d bg-gradient-blue d-flex flex-column justify-center px-5 py-3" v-ripple>
             <div class="kpi-bg-icon" style="right: -30px; bottom: -40px; opacity: 0.08;"><v-icon size="190">mdi-store-clock</v-icon></div>

             <div class="d-flex align-center mb-3 position-relative z-10">
                <v-icon color="white" size="small" class="mr-2 opacity-80">mdi-chart-line</v-icon>
                <span class="kpi-label text-white-80" style="font-size: 16px;">{{ shortNameRetail }} • BALANÇO ({{ formatFilterLabel.toUpperCase() }})</span>
             </div>

             <div class="d-flex align-center justify-space-between position-relative z-10 w-100">
                <div class="d-flex align-center flex-grow-1 pr-4 border-r border-white-10">
                   <div style="height: 84px; width: 84px; min-width: 84px;" class="mr-4">
                      <Doughnut :data="cajuiaRecDoughnutData" :options="miniChartOptions" />
                   </div>
                   <div class="flex-grow-1">
                      <div class="font-weight-black text-green-accent-2 mb-1" style="font-size: 16px; letter-spacing: 0.5px;">RECEITAS</div>
                      <div class="d-flex flex-column text-white-90" style="font-size: 16px; line-height: 1.5; gap: 2px;">
                         <div class="d-flex justify-space-between"><span>Previsto:</span> <strong class="font-mono">{{ formatCurrencyNoSymbol(cajuiaReceivablesTotal) }}</strong></div>
                         <div class="d-flex justify-space-between"><span>Real:</span> <strong class="text-green-accent-1 font-mono">{{ formatCurrencyNoSymbol(cajuiaExecution.received) }}</strong></div>
                         <div class="d-flex justify-space-between opacity-70"><span>Falta:</span> <span class="font-mono">{{ formatCurrencyNoSymbol(cajuiaExecution.missingRec) }}</span></div>
                      </div>
                   </div>
                </div>
                <div class="d-flex align-center flex-grow-1 pl-4">
                   <div style="height: 84px; width: 84px; min-width: 84px;" class="mr-4">
                      <Doughnut :data="cajuiaPayDoughnutData" :options="miniChartOptions" />
                   </div>
                   <div class="flex-grow-1">
                      <div class="font-weight-black text-red-accent-2 mb-1" style="font-size: 16px; letter-spacing: 0.5px;">DESPESAS</div>
                      <div class="d-flex flex-column text-white-90" style="font-size: 16px; line-height: 1.5; gap: 2px;">
                         <div class="d-flex justify-space-between"><span>Previsto:</span> <strong class="font-mono">{{ formatCurrencyNoSymbol(cajuiaPayablesTotal) }}</strong></div>
                         <div class="d-flex justify-space-between"><span>Real:</span> <strong class="text-red-accent-1 font-mono">{{ formatCurrencyNoSymbol(cajuiaExecution.paid) }}</strong></div>
                         <div class="d-flex justify-space-between opacity-70"><span>Falta:</span> <span class="font-mono">{{ formatCurrencyNoSymbol(cajuiaExecution.missingPay) }}</span></div>
                      </div>
                   </div>
                </div>
             </div>
          </v-card>
        </v-col>
      </v-row>

      <v-row dense class="mb-4" v-for="(comp, index) in displayedExtraCompanies" :key="comp.id" v-show="currentContext === 'general' && visibleBlocks.includes(comp.id)">
        <v-col cols="12" md="3">
          <v-card class="kpi-card-3d bg-gradient-red" v-ripple>
            <div class="kpi-bg-icon"><v-icon>mdi-calendar-arrow-right</v-icon></div>
            <div class="d-flex flex-column position-relative z-10 h-100 justify-space-between">
              <div>
                 <div class="d-flex align-center mb-1 pr-8 text-truncate">
                    <v-icon color="white" size="small" class="mr-2">mdi-domain</v-icon>
                    <span class="kpi-label text-white text-truncate" style="font-size: 16px;" :title="comp.name">{{ comp.name.toUpperCase() }} • A PAGAR</span>
                 </div>
                 <div class="kpi-number-group mt-1">
                   <span class="kpi-unit mr-1 text-h6 opacity-80">R$</span>
                   <span class="kpi-value text-h4 font-mono">{{ formatCurrencyNoSymbol(comp.execution.missingPay) }}</span>
                 </div>
              </div>
              <div class="kpi-footer bg-black-20 justify-space-between w-100 pr-1 mt-2 rounded">
                <span class="d-flex align-center"><v-icon size="small" color="white" class="mr-1">mdi-calendar-range</v-icon> PENDENTE ({{ formatFilterLabel.toUpperCase() }})</span>
                <v-btn variant="text" density="compact" size="small" class="px-0 text-white font-weight-bold" @click="goToFinancial('payable', comp.id)">Detalhado <v-icon end size="small">mdi-arrow-right</v-icon></v-btn>
              </div>
            </div>
          </v-card>
        </v-col>

        <v-col cols="12" md="3">
          <v-card class="kpi-card-3d bg-gradient-green" v-ripple>
            <div class="kpi-bg-icon"><v-icon>mdi-cash-fast</v-icon></div>
            <div class="d-flex flex-column position-relative z-10 h-100 justify-space-between">
               <div>
                  <div class="d-flex align-center mb-1 pr-8 text-truncate">
                     <v-icon color="white" size="small" class="mr-2">mdi-domain</v-icon>
                     <span class="kpi-label text-white text-truncate" style="font-size: 16px;" :title="comp.name">{{ comp.name.toUpperCase() }} • A RECEBER</span>
                  </div>
                  <div class="kpi-number-group mt-1">
                    <span class="kpi-unit mr-1 text-h6 opacity-80">R$</span>
                    <span class="kpi-value text-h4 font-mono">{{ formatCurrencyNoSymbol(comp.execution.missingRec) }}</span>
                  </div>
               </div>
               <div class="kpi-footer bg-black-20 justify-space-between w-100 pr-1 mt-2 rounded">
                 <span class="d-flex align-center"><v-icon size="small" color="white" class="mr-1">mdi-calendar-range</v-icon> PENDENTE ({{ formatFilterLabel.toUpperCase() }})</span>
                 <v-btn variant="text" density="compact" size="small" class="px-0 text-white font-weight-bold" @click="goToFinancial('receivable', comp.id)">Detalhado <v-icon end size="small">mdi-arrow-right</v-icon></v-btn>
               </div>
            </div>
          </v-card>
        </v-col>

        <v-col cols="12" md="6">
          <v-card class="kpi-card-3d bg-gradient-blue d-flex flex-column justify-center px-5 py-3" v-ripple>

             <v-btn icon="mdi-close" size="small" color="white" variant="text" class="position-absolute" style="top: 8px; right: 8px; z-index: 20; opacity: 0.7" @click="removeExtraCompany(comp.id)"></v-btn>

             <div class="kpi-bg-icon" style="right: -30px; bottom: -40px; opacity: 0.08;"><v-icon size="190">mdi-chart-pie</v-icon></div>

             <div class="d-flex align-center mb-3 position-relative z-10 pr-6 text-truncate">
                <v-icon color="white" size="small" class="mr-2 opacity-80">mdi-chart-line</v-icon>
                <span class="kpi-label text-white-80 text-truncate" style="font-size: 16px;" :title="comp.name">{{ comp.name.toUpperCase() }} • BALANÇO ({{ formatFilterLabel.toUpperCase() }})</span>
             </div>

             <div class="d-flex align-center justify-space-between position-relative z-10 w-100">
                <div class="d-flex align-center flex-grow-1 pr-4 border-r border-white-10">
                   <div style="height: 84px; width: 84px; min-width: 84px;" class="mr-4">
                      <Doughnut :data="createDoughnutData(comp.execution.received, comp.execution.missingRec, '#69F0AE')" :options="miniChartOptions" />
                   </div>
                   <div class="flex-grow-1">
                      <div class="font-weight-black text-green-accent-2 mb-1" style="font-size: 16px; letter-spacing: 0.5px;">RECEITAS</div>
                      <div class="d-flex flex-column text-white-90" style="font-size: 16px; line-height: 1.5; gap: 2px;">
                         <div class="d-flex justify-space-between"><span>Previsto:</span> <strong class="font-mono">{{ formatCurrencyNoSymbol(comp.receivablesTotal) }}</strong></div>
                         <div class="d-flex justify-space-between"><span>Real:</span> <strong class="text-green-accent-1 font-mono">{{ formatCurrencyNoSymbol(comp.execution.received) }}</strong></div>
                         <div class="d-flex justify-space-between opacity-70"><span>Falta:</span> <span class="font-mono">{{ formatCurrencyNoSymbol(comp.execution.missingRec) }}</span></div>
                      </div>
                   </div>
                </div>
                <div class="d-flex align-center flex-grow-1 pl-4">
                   <div style="height: 84px; width: 84px; min-width: 84px;" class="mr-4">
                      <Doughnut :data="createDoughnutData(comp.execution.paid, comp.execution.missingPay, '#FF5252')" :options="miniChartOptions" />
                   </div>
                   <div class="flex-grow-1">
                      <div class="font-weight-black text-red-accent-2 mb-1" style="font-size: 16px; letter-spacing: 0.5px;">DESPESAS</div>
                      <div class="d-flex flex-column text-white-90" style="font-size: 16px; line-height: 1.5; gap: 2px;">
                         <div class="d-flex justify-space-between"><span>Previsto:</span> <strong class="font-mono">{{ formatCurrencyNoSymbol(comp.payablesTotal) }}</strong></div>
                         <div class="d-flex justify-space-between"><span>Real:</span> <strong class="text-red-accent-1 font-mono">{{ formatCurrencyNoSymbol(comp.execution.paid) }}</strong></div>
                         <div class="d-flex justify-space-between opacity-70"><span>Falta:</span> <span class="font-mono">{{ formatCurrencyNoSymbol(comp.execution.missingPay) }}</span></div>
                      </div>
                   </div>
                </div>
             </div>
          </v-card>
        </v-col>
      </v-row>

      <v-row dense class="mb-4" v-show="currentContext === 'general' && visibleBlocks.includes('UNLINKED')">
        <v-col cols="12" md="3">
          <v-card class="kpi-card-3d bg-gradient-grey" v-ripple>
            <div class="kpi-bg-icon"><v-icon>mdi-help-network-outline</v-icon></div>
            <div class="d-flex flex-column position-relative z-10 h-100 justify-space-between">
              <div>
                 <div class="d-flex align-center mb-1 pr-8 text-truncate">
                    <v-icon color="white" size="small" class="mr-2">mdi-help-network</v-icon>
                    <span class="kpi-label text-white text-truncate" style="font-size: 16px;">NÃO VINCULADOS • A PAGAR</span>
                 </div>
                 <div class="kpi-number-group mt-1">
                   <span class="kpi-unit mr-1 text-h6 opacity-80">R$</span>
                   <span class="kpi-value text-h4 font-mono">{{ formatCurrencyNoSymbol(unlinkedExecution.missingPay) }}</span>
                 </div>
              </div>
              <div class="kpi-footer bg-black-20 justify-space-between w-100 pr-1 mt-2 rounded">
                <span class="d-flex align-center"><v-icon size="small" color="white" class="mr-1">mdi-calendar-range</v-icon> PENDENTE ({{ formatFilterLabel.toUpperCase() }})</span>
                <v-btn variant="text" density="compact" size="small" class="px-0 text-white font-weight-bold" @click="goToFinancial('payable', null)">Detalhado <v-icon end size="small">mdi-arrow-right</v-icon></v-btn>
              </div>
            </div>
          </v-card>
        </v-col>

        <v-col cols="12" md="3">
          <v-card class="kpi-card-3d bg-gradient-grey-light" v-ripple>
            <div class="kpi-bg-icon"><v-icon>mdi-cash-remove</v-icon></div>
            <div class="d-flex flex-column position-relative z-10 h-100 justify-space-between">
               <div>
                  <div class="d-flex align-center mb-1 pr-8 text-truncate">
                     <v-icon color="white" size="small" class="mr-2">mdi-help-network</v-icon>
                     <span class="kpi-label text-white text-truncate" style="font-size: 16px;">NÃO VINCULADOS • A RECEBER</span>
                  </div>
                  <div class="kpi-number-group mt-1">
                    <span class="kpi-unit mr-1 text-h6 opacity-80">R$</span>
                    <span class="kpi-value text-h4 font-mono">{{ formatCurrencyNoSymbol(unlinkedExecution.missingRec) }}</span>
                  </div>
               </div>
               <div class="kpi-footer bg-black-20 justify-space-between w-100 pr-1 mt-2 rounded">
                 <span class="d-flex align-center"><v-icon size="small" color="white" class="mr-1">mdi-calendar-range</v-icon> PENDENTE ({{ formatFilterLabel.toUpperCase() }})</span>
                 <v-btn variant="text" density="compact" size="small" class="px-0 text-white font-weight-bold" @click="goToFinancial('receivable', null)">Detalhado <v-icon end size="small">mdi-arrow-right</v-icon></v-btn>
               </div>
            </div>
          </v-card>
        </v-col>

        <v-col cols="12" md="6">
          <v-card class="kpi-card-3d bg-gradient-grey-dark d-flex flex-column justify-center px-5 py-3" v-ripple>
             <div class="kpi-bg-icon" style="right: -30px; bottom: -40px; opacity: 0.08;"><v-icon size="190">mdi-chart-pie</v-icon></div>

             <div class="d-flex align-center mb-3 position-relative z-10 pr-6 text-truncate">
                <v-icon color="white" size="small" class="mr-2 opacity-80">mdi-chart-line</v-icon>
                <span class="kpi-label text-white-80 text-truncate" style="font-size: 16px;">NÃO VINCULADOS • BALANÇO ({{ formatFilterLabel.toUpperCase() }})</span>
             </div>

             <div class="d-flex align-center justify-space-between position-relative z-10 w-100">
                <div class="d-flex align-center flex-grow-1 pr-4 border-r border-white-10">
                   <div style="height: 84px; width: 84px; min-width: 84px;" class="mr-4">
                      <Doughnut :data="unlinkedDoughnutRec" :options="miniChartOptions" />
                   </div>
                   <div class="flex-grow-1">
                      <div class="font-weight-black text-green-accent-2 mb-1" style="font-size: 16px; letter-spacing: 0.5px;">RECEITAS</div>
                      <div class="d-flex flex-column text-white-90" style="font-size: 16px; line-height: 1.5; gap: 2px;">
                         <div class="d-flex justify-space-between"><span>Previsto:</span> <strong class="font-mono">{{ formatCurrencyNoSymbol(unlinkedReceivablesTotal) }}</strong></div>
                         <div class="d-flex justify-space-between"><span>Real:</span> <strong class="text-green-accent-1 font-mono">{{ formatCurrencyNoSymbol(unlinkedExecution.received) }}</strong></div>
                         <div class="d-flex justify-space-between opacity-70"><span>Falta:</span> <span class="font-mono">{{ formatCurrencyNoSymbol(unlinkedExecution.missingRec) }}</span></div>
                      </div>
                   </div>
                </div>
                <div class="d-flex align-center flex-grow-1 pl-4">
                   <div style="height: 84px; width: 84px; min-width: 84px;" class="mr-4">
                      <Doughnut :data="unlinkedDoughnutPay" :options="miniChartOptions" />
                   </div>
                   <div class="flex-grow-1">
                      <div class="font-weight-black text-red-accent-2 mb-1" style="font-size: 16px; letter-spacing: 0.5px;">DESPESAS</div>
                      <div class="d-flex flex-column text-white-90" style="font-size: 16px; line-height: 1.5; gap: 2px;">
                         <div class="d-flex justify-space-between"><span>Previsto:</span> <strong class="font-mono">{{ formatCurrencyNoSymbol(unlinkedPayablesTotal) }}</strong></div>
                         <div class="d-flex justify-space-between"><span>Real:</span> <strong class="text-red-accent-1 font-mono">{{ formatCurrencyNoSymbol(unlinkedExecution.paid) }}</strong></div>
                         <div class="d-flex justify-space-between opacity-70"><span>Falta:</span> <span class="font-mono">{{ formatCurrencyNoSymbol(unlinkedExecution.missingPay) }}</span></div>
                      </div>
                   </div>
                </div>
             </div>
          </v-card>
        </v-col>
      </v-row>

      <section class="dashboard-shell-section dashboard-shell-section--executive animate-fade-in-up" v-show="currentContext === 'general'">
      <div class="dashboard-section-intro mb-4 animate-fade-in-up" v-show="currentContext === 'general'">
        <div class="dashboard-section-chip">RESUMO EXECUTIVO</div>
        <div class="dashboard-section-title">Saúde financeira da holding</div>
        <div class="dashboard-section-text">Entradas, saídas e saldo consolidado do período.</div>
      </div>

      <v-row dense class="mb-6" v-show="currentContext === 'general'">
        <v-col cols="12" md="3">
          <v-card class="kpi-card-3d bg-gradient-deep-purple" v-ripple>
            <div class="kpi-bg-icon"><v-icon>mdi-calendar-alert</v-icon></div>
            <div class="d-flex flex-column position-relative z-10 h-100 justify-space-between">
              <div>
                 <div class="d-flex align-center mb-1">
                    <v-icon color="white" size="small" class="mr-2">mdi-earth</v-icon>
                    <span class="kpi-label text-white" style="font-size: 16px;">GLOBAL • A PAGAR</span>
                 </div>
                 <div class="kpi-number-group mt-1">
                   <span class="kpi-unit mr-1 text-h6 opacity-80">R$</span>
                   <span class="kpi-value text-h4 font-mono">{{ formatCurrencyNoSymbol(globalExecutionMissingPay) }}</span>
                 </div>
              </div>
              <div class="kpi-footer bg-black-20 mt-2 rounded justify-space-between">
                <span class="d-flex align-center"><v-icon size="small" class="mr-1">mdi-calendar-range</v-icon> PENDENTE ({{ formatFilterLabel.toUpperCase() }})</span>
              </div>
            </div>
          </v-card>
        </v-col>

        <v-col cols="12" md="3">
          <v-card class="kpi-card-3d bg-gradient-indigo" v-ripple>
            <div class="kpi-bg-icon"><v-icon>mdi-cash-multiple</v-icon></div>
            <div class="d-flex flex-column position-relative z-10 h-100 justify-space-between">
               <div>
                  <div class="d-flex align-center mb-1">
                     <v-icon color="white" size="small" class="mr-2">mdi-earth</v-icon>
                     <span class="kpi-label text-white" style="font-size: 16px;">GLOBAL • A RECEBER</span>
                  </div>
                  <div class="kpi-number-group mt-1">
                    <span class="kpi-unit mr-1 text-h6 opacity-80">R$</span>
                    <span class="kpi-value text-h4 font-mono">{{ formatCurrencyNoSymbol(globalExecutionMissingRec) }}</span>
                  </div>
               </div>
               <div class="kpi-footer bg-black-20 mt-2 rounded justify-space-between">
                 <span class="d-flex align-center"><v-icon size="small" class="mr-1">mdi-calendar-range</v-icon> PENDENTE ({{ formatFilterLabel.toUpperCase() }})</span>
               </div>
            </div>
          </v-card>
        </v-col>

        <v-col cols="12" md="6">
          <v-card class="kpi-card-3d bg-gradient-blue-grey d-flex flex-column justify-center px-5 py-3" v-ripple>
             <div class="kpi-bg-icon" style="right: -30px; bottom: -40px; opacity: 0.08;"><v-icon size="190">mdi-scale-balance</v-icon></div>

             <div class="d-flex align-center mb-3 position-relative z-10">
                 <v-icon color="white" size="small" class="mr-2 opacity-80">mdi-earth</v-icon>
                 <span class="kpi-label text-white-80" style="font-size: 16px;">CONSOLIDADO • GLOBAL ({{ formatFilterLabel.toUpperCase() }})</span>
             </div>

             <div class="d-flex align-center justify-space-between position-relative z-10 w-100">
                <div class="d-flex align-center flex-grow-1 pr-4 border-r border-white-10">
                   <div style="height: 84px; width: 84px; min-width: 84px;" class="mr-4">
                      <Doughnut :data="globalRecDoughnutData" :options="miniChartOptions" />
                   </div>
                   <div class="flex-grow-1">
                      <div class="font-weight-black text-green-accent-2 mb-1" style="font-size: 16px; letter-spacing: 0.5px;">RECEITAS</div>
                      <div class="d-flex flex-column text-white-90" style="font-size: 16px; line-height: 1.5; gap: 2px;">
                         <div class="d-flex justify-space-between"><span>Previsto:</span> <strong class="font-mono">{{ formatCurrencyNoSymbol(globalReceivablesTotal) }}</strong></div>
                         <div class="d-flex justify-space-between"><span>Real:</span> <strong class="text-green-accent-1 font-mono">{{ formatCurrencyNoSymbol(globalExecutionReceived) }}</strong></div>
                         <div class="d-flex justify-space-between opacity-70"><span>Falta:</span> <span class="font-mono">{{ formatCurrencyNoSymbol(globalExecutionMissingRec) }}</span></div>
                      </div>
                   </div>
                </div>
                <div class="d-flex align-center flex-grow-1 pl-4">
                   <div style="height: 84px; width: 84px; min-width: 84px;" class="mr-4">
                      <Doughnut :data="globalPayDoughnutData" :options="miniChartOptions" />
                   </div>
                   <div class="flex-grow-1">
                      <div class="font-weight-black text-red-accent-2 mb-1" style="font-size: 16px; letter-spacing: 0.5px;">DESPESAS</div>
                      <div class="d-flex flex-column text-white-90" style="font-size: 16px; line-height: 1.5; gap: 2px;">
                         <div class="d-flex justify-space-between"><span>Previsto:</span> <strong class="font-mono">{{ formatCurrencyNoSymbol(globalPayablesTotal) }}</strong></div>
                         <div class="d-flex justify-space-between"><span>Real:</span> <strong class="text-red-accent-1 font-mono">{{ formatCurrencyNoSymbol(globalExecutionPaid) }}</strong></div>
                         <div class="d-flex justify-space-between opacity-70"><span>Falta:</span> <span class="font-mono">{{ formatCurrencyNoSymbol(globalExecutionMissingPay) }}</span></div>
                      </div>
                   </div>
                </div>
             </div>
          </v-card>
        </v-col>
      </v-row>
      </section>

      <section class="dashboard-shell-section dashboard-shell-section--analytics animate-fade-in-up" style="animation-delay: 0.08s">
      <div class="dashboard-section-intro mb-4 animate-fade-in-up" style="animation-delay: 0.08s">
        <div class="dashboard-section-chip">ANÁLISES VISUAIS</div>
        <div class="dashboard-section-title">Movimento e desempenho do período</div>
        <div class="dashboard-section-text">
          {{ currentContext === 'general'
            ? 'Gráficos para acompanhar o comportamento financeiro e comercial das empresas.'
            : 'Um resumo visual mais claro para acompanhar entradas, saídas e evolução do período.' }}
        </div>
      </div>

      <v-row class="mb-6 animate-fade-in-up" style="animation-delay: 0.1s" dense>
        <v-col cols="12" :md="currentContext === 'general' ? 4 : 12" v-show="currentContext === 'general' || currentContext === 'mj'">
           <v-card class="card-3d analytics-card pa-0 border-thin h-100 d-flex flex-column overflow-hidden" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-surface-darker'">
              <div class="analytics-card__header px-5 pt-5 pb-3 d-flex align-center justify-space-between flex-wrap">
                 <div class="d-flex align-center flex-wrap" style="gap: 12px;">
                    <v-avatar color="indigo-lighten-5" size="40" class="rounded-xl"><v-icon color="indigo" size="20">mdi-factory</v-icon></v-avatar>
                    <div>
                       <div class="text-subtitle-1 font-weight-bold">{{ nameIndustry }}</div>
                       <div class="text-caption text-medium-emphasis">Fluxo de caixa do período</div>
                    </div>
                 </div>
                 <v-btn-toggle v-model="chartFilterMJ" density="compact" variant="outlined" divided class="rounded-lg btn-3d mt-2 mt-sm-0" mandatory @update:model-value="fetchHoldingData">
                    <v-btn value="day" class="px-3 text-caption font-weight-bold">Dia</v-btn>
                    <v-btn value="month" class="px-3 text-caption font-weight-bold">Mês</v-btn>
                    <v-btn value="year" class="px-3 text-caption font-weight-bold">Ano</v-btn>
                 </v-btn-toggle>
              </div>
              <div class="analytics-card__legend px-5 pb-2 d-flex flex-wrap">
                <div class="legend-chip legend-chip--income"><span class="legend-dot"></span>Entradas</div>
                <div class="legend-chip legend-chip--expense"><span class="legend-dot"></span>Saídas</div>
                <div class="legend-chip legend-chip--neutral">Compare a evolução por período</div>
              </div>
              <div class="analytics-chart-region flex-grow-1 position-relative px-4 pb-4 pt-2" :class="currentContext === 'general' ? 'analytics-chart-region--holding' : 'analytics-chart-region--focused'">
                <div class="chart-canvas-shell" :class="currentContext === 'general' ? 'chart-canvas-shell--holding' : 'chart-canvas-shell--focused'">
                  <Bar :data="mjChartData" :options="richChartOptions" />
                </div>
              </div>
           </v-card>
        </v-col>

        <v-col cols="12" :md="currentContext === 'general' ? 4 : 12" v-show="currentContext === 'general' || currentContext === 'cajuia'">
           <v-card class="card-3d analytics-card pa-0 border-thin h-100 d-flex flex-column overflow-hidden" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-surface-darker'">
              <div class="analytics-card__header px-5 pt-5 pb-3 d-flex align-center justify-space-between flex-wrap">
                 <div class="d-flex align-center flex-wrap" style="gap: 12px;">
                    <v-avatar color="orange-lighten-5" size="40" class="rounded-xl"><v-icon color="orange-darken-1" size="20">mdi-storefront</v-icon></v-avatar>
                    <div>
                       <div class="text-subtitle-1 font-weight-bold">{{ nameRetail }}</div>
                       <div class="text-caption text-medium-emphasis">Fluxo de caixa do período</div>
                    </div>
                 </div>
                 <v-btn-toggle v-model="chartFilterCajuia" density="compact" variant="outlined" divided class="rounded-lg btn-3d mt-2 mt-sm-0" mandatory @update:model-value="fetchHoldingData">
                    <v-btn value="day" class="px-3 text-caption font-weight-bold">Dia</v-btn>
                    <v-btn value="month" class="px-3 text-caption font-weight-bold">Mês</v-btn>
                    <v-btn value="year" class="px-3 text-caption font-weight-bold">Ano</v-btn>
                 </v-btn-toggle>
              </div>
              <div class="analytics-card__legend px-5 pb-2 d-flex flex-wrap">
                <div class="legend-chip legend-chip--retail-income"><span class="legend-dot"></span>Entradas</div>
                <div class="legend-chip legend-chip--retail-expense"><span class="legend-dot"></span>Saídas</div>
                <div class="legend-chip legend-chip--neutral">Compare a evolução por período</div>
              </div>
              <div class="analytics-chart-region flex-grow-1 position-relative px-4 pb-4 pt-2" :class="currentContext === 'general' ? 'analytics-chart-region--holding' : 'analytics-chart-region--focused'">
                <div class="chart-canvas-shell" :class="currentContext === 'general' ? 'chart-canvas-shell--holding' : 'chart-canvas-shell--focused'">
                  <Bar :data="cajuiaChartData" :options="richChartOptions" />
                </div>
              </div>
           </v-card>
        </v-col>

        <v-col cols="12" :md="currentContext === 'general' ? 4 : 12" v-show="currentContext === 'general'">
           <v-card class="card-3d border-thin h-100 d-flex flex-column overflow-hidden" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-surface-darker'">
              <div class="px-5 pt-5 pb-2 d-flex align-center justify-space-between border-b" :class="themeStore.currentMode === 'light' ? 'border-grey-lighten-2' : 'border-white-05'">
                 <div class="d-flex align-center">
                    <v-avatar color="pink-lighten-5" size="36" class="mr-3 rounded-lg"><v-icon color="pink" size="20">mdi-bank</v-icon></v-avatar>
                    <div>
                       <div class="text-subtitle-1 font-weight-bold">Contas Bancárias</div>
                       <div class="text-caption text-medium-emphasis">Disponibilidade & Movimentação</div>
                    </div>
                 </div>
              </div>
              <div class="pa-4 flex-grow-1 d-flex flex-column overflow-y-auto custom-scroll" style="max-height: 350px;">
                 <div v-if="realBanks.length === 0" class="text-center py-4 opacity-50">
                    <v-icon size="32">mdi-bank-off</v-icon>
                    <div class="text-caption">Nenhuma conta ativa encontrada</div>
                 </div>
                 <div v-else class="mb-4">
                    <div v-for="bank in realBanks" :key="bank.id" class="ranking-row-safe d-flex align-center justify-space-between mb-3 pa-3 rounded-lg border-thin card-3d" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5' : 'bg-surface-lighten-1'">
                        <div class="d-flex align-center">
                            <div class="rounded-circle d-flex align-center justify-center mr-3" :style="`background-color: ${getBankColor(bank.bank_name)}20; width: 40px; height: 40px;`">
                                <v-icon :color="getBankColor(bank.bank_name)" size="20">mdi-bank</v-icon>
                            </div>
                            <div>
                                <div class="font-weight-bold">{{ bank.name }}</div>
                                <div class="text-caption text-medium-emphasis">{{ bank.bank_name }}</div>
                            </div>
                        </div>
                        <div class="text-right">
                            <div class="text-subtitle-2 font-weight-black">{{ formatCurrency(bank.current_balance) }}</div>
                            <div class="d-flex align-center justify-end text-caption font-weight-bold" style="font-size: 0.65rem;">
                                <span class="text-success mr-2">▲ {{ formatCurrencyNoSymbol(bank.in_flow) }}</span>
                                <span class="text-error">▼ {{ formatCurrencyNoSymbol(bank.out_flow) }}</span>
                            </div>
                        </div>
                    </div>
                 </div>
              </div>
           </v-card>
        </v-col>
      </v-row>
      </section>

      <section class="dashboard-shell-section dashboard-shell-section--focused animate-fade-in-up" v-show="currentContext !== 'general'" style="animation-delay: 0.16s">
      <v-row v-show="currentContext !== 'general'" dense class="mb-6 animate-fade-in-up dashboard-section-row" style="animation-delay: 0.16s">
        <v-col cols="12">
          <div class="dashboard-section-intro dashboard-section-intro-inline mb-2">
            <div class="dashboard-section-chip">RESUMO DA EMPRESA</div>
            <div class="dashboard-section-title">Visão rápida do período</div>
            <div class="dashboard-section-text">Principais números da empresa selecionada.</div>
          </div>
        </v-col>

        <v-col cols="12" md="3">
          <v-card class="card-3d border-thin pa-4 h-100" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-surface-darker'">
            <div class="d-flex align-center mb-3">
              <v-avatar :color="currentContext === 'cajuia' ? 'orange-lighten-5' : 'indigo-lighten-5'" size="38" class="mr-3 rounded-lg card-3d">
                <v-icon :color="currentContext === 'cajuia' ? 'orange-darken-2' : 'indigo'">{{ currentContext === 'cajuia' ? 'mdi-package-variant-closed' : 'mdi-ruler-square' }}</v-icon>
              </v-avatar>
              <div>
                <div class="text-caption font-weight-black text-uppercase opacity-70">{{ currentContext === 'cajuia' ? 'Peças vendidas' : 'Metragem vendida' }}</div>
                <div class="text-h5 font-weight-black">{{ currentContext === 'cajuia' ? tenantMetrics.piecesSold + ' un' : formatNumber(tenantMetrics.metersSold) + ' m' }}</div>
              </div>
            </div>
            <div class="text-caption text-medium-emphasis">
              {{ currentContext === 'cajuia' ? 'Volume do período.' : 'Volume do período.' }}
            </div>
          </v-card>
        </v-col>

        <v-col cols="12" md="3">
          <v-card class="card-3d border-thin pa-4 h-100" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-surface-darker'">
            <div class="d-flex align-center mb-3">
              <v-avatar color="green-lighten-5" size="38" class="mr-3 rounded-lg card-3d">
                <v-icon color="green-darken-2">mdi-cash-register</v-icon>
              </v-avatar>
              <div>
                <div class="text-caption font-weight-black text-uppercase opacity-70">Vendas no período</div>
                <div class="text-h5 font-weight-black">{{ tenantMetrics.salesCount }}</div>
              </div>
            </div>
            <div class="text-caption text-medium-emphasis">
              Base dos rankings.
            </div>
          </v-card>
        </v-col>

        <v-col cols="12" md="3">
          <v-card class="card-3d border-thin pa-4 h-100" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-surface-darker'">
            <div class="d-flex align-center mb-3">
              <v-avatar color="blue-lighten-5" size="38" class="mr-3 rounded-lg card-3d">
                <v-icon color="blue-darken-2">mdi-account-star</v-icon>
              </v-avatar>
              <div>
                <div class="text-caption font-weight-black text-uppercase opacity-70">Maior comprador</div>
                <div class="text-subtitle-1 font-weight-black text-truncate" style="max-width: 210px;">{{ tenantTopCustomers[0]?.name || 'Sem dados' }}</div>
              </div>
            </div>
            <div class="text-caption text-medium-emphasis">
              {{ tenantTopCustomers[0] ? formatCurrency(tenantTopCustomers[0].total) : 'Nenhuma venda encontrada no período.' }}
            </div>
          </v-card>
        </v-col>

        <v-col cols="12" md="3">
          <v-card class="card-3d border-thin pa-4 h-100" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-surface-darker'">
            <div class="d-flex align-center mb-3">
              <v-avatar color="purple-lighten-5" size="38" class="mr-3 rounded-lg card-3d">
                <v-icon color="purple-darken-2">{{ currentContext === 'cajuia' ? 'mdi-tshirt-crew' : 'mdi-texture-box' }}</v-icon>
              </v-avatar>
              <div>
                <div class="text-caption font-weight-black text-uppercase opacity-70">{{ currentContext === 'cajuia' ? 'Produto campeão' : 'Tecido campeão' }}</div>
                <div class="text-subtitle-1 font-weight-black text-truncate" style="max-width: 210px;">{{ tenantTopProducts[0]?.name || 'Sem dados' }}</div>
              </div>
            </div>
            <div class="text-caption text-medium-emphasis">
              {{ tenantTopProducts[0] ? `${tenantTopProducts[0].quantity.toLocaleString('pt-BR')} ${currentContext === 'cajuia' ? 'un' : 'm'}` : 'Nenhum item encontrado.' }}
            </div>
          </v-card>
        </v-col>

        <v-col cols="12">
          <div class="dashboard-subsection-banner dashboard-subsection-banner--rankings mt-1 mb-3">
            <div>
              <div class="dashboard-subsection-title">Rankings e destaques do período</div>
              <div class="dashboard-subsection-text">Veja de forma mais clara quem mais comprou, o que mais vendeu e quem mais se destacou nas vendas.</div>
            </div>
          </div>
        </v-col>

        <v-col cols="12" md="4">
          <v-card class="card-3d ranking-card border-thin h-100 overflow-hidden" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-surface-darker'">
            <div class="px-5 py-4 border-b" :class="themeStore.currentMode === 'light' ? 'border-grey-lighten-2' : 'border-white-05'">
              <div class="text-subtitle-1 font-weight-black d-flex align-center">
                <v-icon start color="primary">mdi-account-group</v-icon>
                Clientes que mais compraram
              </div>
              <div class="text-caption text-medium-emphasis">Ranking do período</div>
            </div>
            <div class="pa-4">
              <div v-if="tenantTopCustomers.length === 0" class="text-center py-8 text-medium-emphasis">
                <v-icon size="34" class="mb-2">mdi-account-search</v-icon>
                <div class="text-caption">Nenhum cliente encontrado neste período.</div>
              </div>
              <template v-else>
                <div class="tenant-ranking-scroll custom-scroll">
                  <div v-for="(customer, idx) in paginatedTenantCustomers" :key="customer.name" class="ranking-row ranking-row-safe d-flex align-center justify-space-between mb-3 pa-3 rounded-lg border-thin" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5' : 'bg-surface-lighten-1'">
                    <div class="d-flex align-center min-w-0">
                      <v-avatar size="28" color="primary" class="mr-3 text-white font-weight-black">{{ ((tenantCustomerPage - 1) * rankingItemsPerPage) + idx + 1 }}</v-avatar>
                      <div class="min-w-0">
                        <div class="font-weight-bold text-truncate">{{ customer.name }}</div>
                        <div class="text-caption text-medium-emphasis">{{ customer.count }} venda(s)</div>
                      </div>
                    </div>
                    <div class="font-weight-black text-success ml-3 ranking-value">{{ formatCurrency(customer.total) }}</div>
                  </div>
                </div>
                <div class="ranking-footer d-flex align-center justify-space-between pt-3">
                  <span class="text-caption text-medium-emphasis font-weight-bold">Total: {{ tenantTopCustomers.length }} cliente(s)</span>
                  <div class="ranking-pagination-box">
                    <v-btn
                      size="small"
                      variant="tonal"
                      class="ranking-page-btn"
                      prepend-icon="mdi-chevron-left"
                      :disabled="tenantCustomerPage <= 1"
                      @click="tenantCustomerPage = Math.max(1, tenantCustomerPage - 1)"
                    >
                      Anterior
                    </v-btn>
                    <div class="ranking-page-indicator">
                      Página <strong>{{ tenantCustomerPage }}</strong> de <strong>{{ tenantCustomerPageCount }}</strong>
                    </div>
                    <v-btn
                      size="small"
                      variant="tonal"
                      class="ranking-page-btn"
                      append-icon="mdi-chevron-right"
                      :disabled="tenantCustomerPage >= tenantCustomerPageCount"
                      @click="tenantCustomerPage = Math.min(tenantCustomerPageCount, tenantCustomerPage + 1)"
                    >
                      Próxima
                    </v-btn>
                  </div>
                </div>
              </template>
            </div>
          </v-card>
        </v-col>

        <v-col cols="12" md="4">
          <v-card class="card-3d ranking-card border-thin h-100 overflow-hidden" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-surface-darker'">
            <div class="px-5 py-4 border-b" :class="themeStore.currentMode === 'light' ? 'border-grey-lighten-2' : 'border-white-05'">
              <div class="text-subtitle-1 font-weight-black d-flex align-center">
                <v-icon start :color="currentContext === 'cajuia' ? 'orange-darken-2' : 'indigo'">{{ currentContext === 'cajuia' ? 'mdi-tshirt-crew' : 'mdi-texture-box' }}</v-icon>
                {{ currentContext === 'cajuia' ? 'Produtos mais vendidos' : 'Tecidos mais vendidos' }}
              </div>
              <div class="text-caption text-medium-emphasis">{{ currentContext === 'cajuia' ? 'Quantidade e valor' : 'Metragem e valor' }}</div>
            </div>
            <div class="pa-4">
              <div v-if="tenantTopProducts.length === 0" class="text-center py-8 text-medium-emphasis">
                <v-icon size="34" class="mb-2">mdi-package-variant</v-icon>
                <div class="text-caption">Nenhum item encontrado neste período.</div>
              </div>
              <template v-else>
                <div class="tenant-ranking-scroll custom-scroll">
                  <div v-for="(product, idx) in paginatedTenantProducts" :key="product.name" class="ranking-row ranking-row-safe d-flex align-center justify-space-between mb-3 pa-3 rounded-lg border-thin" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5' : 'bg-surface-lighten-1'">
                    <div class="d-flex align-center min-w-0">
                      <v-avatar size="28" :color="currentContext === 'cajuia' ? 'orange-darken-2' : 'indigo'" class="mr-3 text-white font-weight-black">{{ ((tenantProductPage - 1) * rankingItemsPerPage) + idx + 1 }}</v-avatar>
                      <div class="min-w-0">
                        <div class="font-weight-bold text-truncate">{{ product.name }}</div>
                        <div class="text-caption text-medium-emphasis">{{ product.count }} pedido(s) • {{ formatCurrency(product.total || 0) }}</div>
                      </div>
                    </div>
                    <div class="font-weight-black ml-3 ranking-value" :class="currentContext === 'cajuia' ? 'text-orange-darken-2' : 'text-primary'">
                      {{ product.quantity.toLocaleString('pt-BR') }} {{ currentContext === 'cajuia' ? 'un' : 'm' }}
                    </div>
                  </div>
                </div>
                <div class="ranking-footer d-flex align-center justify-space-between pt-3">
                  <span class="text-caption text-medium-emphasis font-weight-bold">Total: {{ tenantTopProducts.length }} item(ns)</span>
                  <div class="ranking-pagination-box">
                    <v-btn
                      size="small"
                      variant="tonal"
                      class="ranking-page-btn"
                      prepend-icon="mdi-chevron-left"
                      :disabled="tenantProductPage <= 1"
                      @click="tenantProductPage = Math.max(1, tenantProductPage - 1)"
                    >
                      Anterior
                    </v-btn>
                    <div class="ranking-page-indicator">
                      Página <strong>{{ tenantProductPage }}</strong> de <strong>{{ tenantProductPageCount }}</strong>
                    </div>
                    <v-btn
                      size="small"
                      variant="tonal"
                      class="ranking-page-btn"
                      append-icon="mdi-chevron-right"
                      :disabled="tenantProductPage >= tenantProductPageCount"
                      @click="tenantProductPage = Math.min(tenantProductPageCount, tenantProductPage + 1)"
                    >
                      Próxima
                    </v-btn>
                  </div>
                </div>
              </template>
            </div>
          </v-card>
        </v-col>

        <v-col cols="12" md="4">
          <v-card class="card-3d ranking-card border-thin h-100 overflow-hidden" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-surface-darker'">
            <div class="px-5 py-4 border-b" :class="themeStore.currentMode === 'light' ? 'border-grey-lighten-2' : 'border-white-05'">
              <div class="text-subtitle-1 font-weight-black d-flex align-center">
                <v-icon start color="teal">mdi-account-tie</v-icon>
                Vendedores destaque
              </div>
              <div class="text-caption text-medium-emphasis">Destaques do período</div>
            </div>
            <div class="pa-4">
              <div v-if="tenantTopSellers.length === 0" class="text-center py-8 text-medium-emphasis">
                <v-icon size="34" class="mb-2">mdi-account-tie-outline</v-icon>
                <div class="text-caption">Nenhum vendedor encontrado neste período.</div>
              </div>
              <template v-else>
                <div class="tenant-ranking-scroll custom-scroll">
                  <div v-for="(seller, idx) in paginatedTenantSellers" :key="seller.name" class="ranking-row ranking-row-safe d-flex align-center justify-space-between mb-3 pa-3 rounded-lg border-thin" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5' : 'bg-surface-lighten-1'">
                    <div class="d-flex align-center min-w-0">
                      <v-avatar size="28" color="teal" class="mr-3 text-white font-weight-black">{{ ((tenantSellerPage - 1) * rankingItemsPerPage) + idx + 1 }}</v-avatar>
                      <div class="min-w-0">
                        <div class="font-weight-bold text-truncate">{{ seller.name }}</div>
                        <div class="text-caption text-medium-emphasis">{{ seller.count }} venda(s)</div>
                      </div>
                    </div>
                    <div class="font-weight-black text-teal ml-3 ranking-value">{{ formatCurrency(seller.total) }}</div>
                  </div>
                </div>
                <div class="ranking-footer d-flex align-center justify-space-between pt-3">
                  <span class="text-caption text-medium-emphasis font-weight-bold">Total: {{ tenantTopSellers.length }} vendedor(es)</span>
                  <div class="ranking-pagination-box">
                    <v-btn
                      size="small"
                      variant="tonal"
                      class="ranking-page-btn"
                      prepend-icon="mdi-chevron-left"
                      :disabled="tenantSellerPage <= 1"
                      @click="tenantSellerPage = Math.max(1, tenantSellerPage - 1)"
                    >
                      Anterior
                    </v-btn>
                    <div class="ranking-page-indicator">
                      Página <strong>{{ tenantSellerPage }}</strong> de <strong>{{ tenantSellerPageCount }}</strong>
                    </div>
                    <v-btn
                      size="small"
                      variant="tonal"
                      class="ranking-page-btn"
                      append-icon="mdi-chevron-right"
                      :disabled="tenantSellerPage >= tenantSellerPageCount"
                      @click="tenantSellerPage = Math.min(tenantSellerPageCount, tenantSellerPage + 1)"
                    >
                      Próxima
                    </v-btn>
                  </div>
                </div>
              </template>
            </div>
          </v-card>
        </v-col>
      </v-row>
      </section>

      <section class="dashboard-shell-section dashboard-shell-section--compare animate-fade-in-up" v-show="currentContext === 'general'" style="animation-delay: 0.2s">
      <div class="dashboard-section-intro mb-4 animate-fade-in-up" v-show="currentContext === 'general'" style="animation-delay: 0.2s">
        <div class="dashboard-section-chip">COMPARATIVO DO GRUPO</div>
        <div class="dashboard-section-title">Leitura rápida por empresa</div>
        <div class="dashboard-section-text">Comparativo rápido entre as empresas do grupo.</div>
      </div>

      <v-card
        class="card-3d mb-6 pa-0 overflow-hidden"
        :class="themeStore.currentMode === 'light' ? 'light-panel' : 'glass-panel'"
        v-show="currentContext === 'general'"
      >
        <div class="d-flex flex-column flex-md-row" style="min-height: 160px;">
           <div class="flex-grow-1 pa-6 position-relative overflow-hidden d-flex align-center">
               <div class="position-absolute w-100 h-100" style="background: linear-gradient(135deg, rgba(21, 101, 192, 0.1) 0%, rgba(13, 71, 161, 0.2) 100%); top:0; left:0; z-index: 0;"></div>
               <div class="kpi-bg-icon" style="right: -20px; bottom: -20px; opacity: 0.05;"><v-icon size="140">mdi-factory</v-icon></div>
               <div class="d-flex w-100 justify-space-between align-center position-relative z-10">
                   <div>
                       <div class="d-flex align-center mb-2">
                           <v-chip size="x-small" color="primary" variant="flat" class="font-weight-black mr-2 chip-3d">{{ shortNameIndustry }}</v-chip>
                           <span class="text-caption font-weight-bold letter-spacing-1 opacity-70">{{ nameIndustry.toUpperCase() }}</span>
                       </div>
                       <div class="text-h3 font-weight-black text-primary mb-1">
                           {{ formatNumber(monthlyProduction.totalMeters || 0) }}<span class="text-h5 text-medium-emphasis">m</span>
                       </div>
                       <div class="text-caption text-medium-emphasis font-weight-bold">Produção Realizada Mês</div>
                   </div>
                   <div class="text-center position-relative">
                       <v-progress-circular model-value="78" :size="80" :width="8" color="primary" bg-color="surface-variant">
                           <span class="text-caption font-weight-black">78%</span>
                       </v-progress-circular>
                       <div class="text-caption font-weight-bold mt-1 text-primary">+8% vs Meta</div>
                   </div>
               </div>
           </div>

           <div class="d-none d-md-block" style="width: 1px; background: linear-gradient(to bottom, transparent, rgba(128,128,128, 0.3), transparent);"></div>

           <div class="flex-grow-1 pa-6 position-relative overflow-hidden d-flex align-center">
               <div class="position-absolute w-100 h-100" style="background: linear-gradient(135deg, rgba(239, 108, 0, 0.1) 0%, rgba(230, 81, 0, 0.2) 100%); top:0; left:0; z-index: 0;"></div>
               <div class="kpi-bg-icon" style="right: -20px; bottom: -20px; opacity: 0.05;"><v-icon size="140">mdi-shopping</v-icon></div>
               <div class="d-flex w-100 justify-space-between align-center position-relative z-10">
                   <div>
                       <div class="d-flex align-center mb-2">
                           <v-chip size="x-small" color="orange-darken-1" variant="flat" class="font-weight-black mr-2 chip-3d">{{ shortNameRetail }}</v-chip>
                           <span class="text-caption font-weight-bold letter-spacing-1 opacity-70">{{ nameRetail.toUpperCase() }}</span>
                       </div>
                       <div class="text-h3 font-weight-black text-orange-darken-2 mb-1">
                           {{ cajuiaMonthlySalesCount }}<span class="text-h6 text-medium-emphasis ml-1">pedido(s)</span>
                       </div>
                       <div class="text-caption text-medium-emphasis font-weight-bold">
                           {{ cajuiaMonthlyPiecesCount }} peça(s) vendida(s)
                       </div>
                   </div>
                   <div class="text-center position-relative">
                       <v-progress-circular model-value="45" :size="80" :width="8" color="orange-darken-2" bg-color="surface-variant">
                           <span class="text-caption font-weight-black">45%</span>
                       </v-progress-circular>
                       <div class="text-caption font-weight-bold mt-1 text-error">-2% vs Meta</div>
                   </div>
               </div>
           </div>
        </div>
      </v-card>

      <div class="store-selector-section mb-6 mt-8 animate-fade-in-up" style="animation-delay: 0.2s;">
         <div class="d-flex align-center justify-space-between mb-3 px-1">
            <div class="text-subtitle-1 font-weight-black d-flex align-center" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-3' : 'text-white'">
               <v-icon start color="primary" class="mr-2">mdi-store-clock</v-icon> {{ currentContext === 'general' ? 'PERFORMANCE POR UNIDADE' : 'PERFORMANCE DA EMPRESA SELECIONADA' }}
            </div>
            <v-btn-toggle v-model="storeFilterPeriod" density="compact" variant="outlined" divided class="rounded-lg btn-3d" mandatory @update:model-value="fetchHoldingData">
               <v-btn value="day" class="px-4 font-weight-bold text-caption text-uppercase">Dia</v-btn>
               <v-btn value="month" class="px-4 font-weight-bold text-caption text-uppercase">Mês</v-btn>
               <v-btn value="year" class="px-4 font-weight-bold text-caption text-uppercase">Ano</v-btn>
            </v-btn-toggle>
         </div>

         <v-row dense>
            <v-col v-for="store in storeSummaries" :key="store.name" cols="12" sm="4">
               <v-card
                  class="card-3d border-thin pa-4 hover-lift h-100 cursor-pointer transition-all"
                  :class="[
                     themeStore.currentMode === 'light' ? 'bg-white' : 'glass-card',
                     selectedStores.includes(store.name) ? 'ring-active' : 'opacity-60 grayscale'
                  ]"
                  @click="toggleStoreFilter(store.name)"
               >
                  <div class="d-flex align-center justify-space-between mb-4">
                     <div class="text-body-1 font-weight-black text-truncate pr-2">{{ store.name }}</div>
                     <v-chip size="x-small" color="success" variant="flat" class="font-weight-black chip-3d">
                        LUCRO
                     </v-chip>
                  </div>

                  <div class="excel-stat-row mb-1">
                     <span class="label text-uppercase font-weight-bold opacity-60" style="font-size: 12px;">Fluxo de Receita</span>
                     <span class="value text-success font-weight-black text-h6">{{ formatCurrency(store.receitas) }}</span>
                  </div>

                  <v-divider class="my-3 border-opacity-10"></v-divider>

                  <div class="excel-stat-row">
                     <span class="label text-uppercase font-weight-bold opacity-60" style="font-size: 12px;">
                        Volume Processado
                     </span>
                     <span class="value text-body-1 font-weight-black text-primary">
                        {{ store.unidades > 0 ? store.unidades + ' un' : store.metragem.toFixed(1) + ' m²' }}
                     </span>
                  </div>
               </v-card>
            </v-col>
         </v-row>
      </div>
      </section>

      <section class="dashboard-shell-section dashboard-shell-section--details animate-fade-in-up" style="animation-delay: 0.28s">
      <div class="dashboard-section-intro mb-4 animate-fade-in-up" style="animation-delay: 0.28s">
        <div class="dashboard-section-chip">DETALHAMENTO FINANCEIRO</div>
        <div class="dashboard-section-title">Lançamentos e conferência fina</div>
        <div class="dashboard-section-text">Veja os lançamentos do período com um resumo mais claro, filtros já aplicados e navegação mais organizada.</div>
      </div>

      <v-card
          class="mb-6 card-3d border-thin overflow-hidden animate-fade-in-up"
          :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-surface-darker'"
          style="animation-delay: 0.3s"
      >
        <div class="financial-section-header px-6 py-5 border-b d-flex align-center justify-space-between flex-wrap" :class="themeStore.currentMode === 'light' ? 'border-grey-lighten-2' : 'border-white-05'">
           <div class="d-flex align-center flex-wrap" style="gap: 14px;">
              <div class="financial-header-icon icon-box-sm bg-purple-lighten-5 rounded-xl card-3d"><v-icon color="purple">mdi-calendar-clock</v-icon></div>
              <div>
                 <div class="financial-eyebrow">Conferência detalhada</div>
                 <h3 class="text-subtitle-1 font-weight-black">Lista detalhada de lançamentos</h3>
                 <div class="text-caption text-medium-emphasis font-weight-medium">{{ currentContext === 'general' ? 'Você está vendo os lançamentos das unidades selecionadas acima.' : 'Você está vendo somente os lançamentos da empresa selecionada.' }}</div>
              </div>
           </div>
           <v-btn size="small" variant="flat" color="indigo" class="btn-3d font-weight-bold mt-3 mt-sm-0" append-icon="mdi-arrow-right" @click="goToFinancial('receivable', null)">
              Acessar módulo financeiro
           </v-btn>
        </div>

        <div class="financial-kpi-strip px-4 pt-4 pb-3 border-b" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-surface-lighten-1 border-white-05'">
            <v-row dense>
                <v-col cols="12" md="4">
                    <div class="financial-mini-card financial-mini-card--income card-3d border-thin rounded-xl pa-4" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-grey-darken-4'">
                        <div class="financial-mini-card__label"><v-icon size="16" class="mr-1">mdi-arrow-up-circle</v-icon>Entradas do filtro</div>
                        <div class="financial-mini-card__value">{{ formatCurrency(gridKpis.receitas) }}</div>
                        <div class="financial-mini-card__hint">Tudo que entra no período filtrado.</div>
                    </div>
                </v-col>
                <v-col cols="12" md="4">
                    <div class="financial-mini-card financial-mini-card--expense card-3d border-thin rounded-xl pa-4" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-grey-darken-4'">
                        <div class="financial-mini-card__label"><v-icon size="16" class="mr-1">mdi-arrow-down-circle</v-icon>Saídas do filtro</div>
                        <div class="financial-mini-card__value">{{ formatCurrency(gridKpis.despesas) }}</div>
                        <div class="financial-mini-card__hint">Tudo que sai no período filtrado.</div>
                    </div>
                </v-col>
                <v-col cols="12" md="4">
                    <div class="financial-mini-card financial-mini-card--balance card-3d border-thin rounded-xl pa-4" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-grey-darken-4'">
                        <div class="financial-mini-card__label"><v-icon size="16" class="mr-1">mdi-scale-balance</v-icon>Saldo do filtro</div>
                        <div class="financial-mini-card__value" :class="gridKpis.saldo >= 0 ? 'text-green-darken-3' : 'text-red-darken-3'">{{ formatCurrency(gridKpis.saldo) }}</div>
                        <div class="financial-mini-card__hint">Diferença entre entradas e saídas.</div>
                    </div>
                </v-col>
            </v-row>
        </div>

        <div class="grid-scroll flex-grow-1 overflow-auto custom-scroll relative" style="max-height: 600px;">
            <div class="grid-header-dash sticky-head border-b" :class="themeStore.currentMode === 'light' ? 'grid-surface-light' : 'grid-surface-dark'">
                <div class="cell center header-text border-r">Tipo</div>
                <div class="cell center header-text border-r">Unidade</div>
                <div class="cell center header-text border-r">Ref / Venc</div>
                <div class="cell header-text pl-4 border-r">Pessoa / Entidade</div>
                <div class="cell header-text pl-4 border-r">Descrição / Detalhes</div>
                <div class="cell center header-text border-r">Valor Líquido</div>
                <div class="cell center header-text">Status</div>
            </div>

            <div v-for="(item, idx) in paginatedGridItems" :key="idx" class="grid-row-dash border-b transition-all" :class="[themeStore.currentMode === 'light' ? 'grid-row-light' : 'grid-row-dark', zebraClass(idx)]">

                <div class="cell center border-r">
                    <div class="rounded-circle d-flex align-center justify-center card-3d" :class="item.type === 'receivable' ? 'bg-green-lighten-5' : 'bg-red-lighten-5'" style="width: 28px; height: 28px; min-width: 28px;">
                        <v-icon :color="item.type === 'receivable' ? 'green-darken-2' : 'red-darken-2'" size="16">
                            {{ item.type === 'receivable' ? 'mdi-arrow-up-bold' : 'mdi-arrow-down-bold' }}
                        </v-icon>
                    </div>
                </div>

                <div class="cell center border-r">
                    <v-chip size="x-small" :color="item.filial === shortNameRetail ? 'orange-darken-2' : (item.filial === 'NÃO VINCULADOS' ? 'grey-darken-2' : 'indigo-darken-2')" class="font-weight-black px-2 chip-3d" variant="flat">
                        {{ item.filial }}
                    </v-chip>
                </div>

                <div class="cell center border-r">
                    <span class="list-text-11 font-mono font-weight-black" :class="getDueDateColorText(item.due_date, item.status)">
                        <v-icon size="12" class="mr-1">mdi-calendar</v-icon>
                        {{ formatDateSimple(item.due_date) }}
                    </span>
                </div>

                <div class="cell pl-4 border-r">
                    <span class="text-truncate list-text-11 font-weight-black text-uppercase" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'" :title="item.entity_name || 'Diversos/Não Informado'">
                        {{ item.entity_name || 'Diversos/Não Informado' }}
                    </span>
                </div>

                <div class="cell pl-4 border-r">
                    <div class="d-flex flex-column justify-center" style="min-width: 0;">
                        <span class="text-truncate list-text-11 font-weight-bold" :title="item.description">
                            <v-icon v-if="item.is_signal" size="12" color="orange" class="mr-1">mdi-flash</v-icon>
                            {{ item.description }}
                        </span>
                        <span class="text-truncate font-weight-bold text-uppercase" style="font-size: 10px; opacity: 0.6;">
                            {{ item.type === 'receivable' ? 'Receita/Entrada' : 'Despesa/Saída' }}
                        </span>
                    </div>
                </div>

                <div class="cell center border-r">
                    <span class="list-text-11 font-mono font-weight-black" :class="item.type === 'receivable' ? 'text-green-darken-2' : 'text-red-darken-2'">
                        {{ item.type === 'receivable' ? '+' : '-' }} {{ formatCurrency(item.value - (item.discount || 0)) }}
                    </span>
                </div>

                <div class="cell center">
                    <v-chip size="small" class="font-weight-black text-uppercase chip-3d" :color="getStatusColorDash(item)" variant="flat">
                        {{ getStatusLabelDash(item) }}
                    </v-chip>
                </div>
            </div>

            <div v-if="paginatedGridItems.length === 0" class="pa-10 text-center d-flex flex-column align-center justify-center opacity-60">
                <v-icon size="40" class="mb-2">mdi-check-all</v-icon>
                <span class="text-body-2 font-weight-bold text-uppercase">Nenhum lançamento corresponde aos filtros.</span>
            </div>
        </div>

        <div class="financial-grid-footer px-4 py-3 border-t d-flex align-center justify-space-between flex-wrap z-20" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-surface-darker'">
            <div class="text-caption opacity-80 font-weight-bold">
                Exibindo <strong>{{ paginatedGridItems.length }}</strong> de <strong>{{ finalFilteredItems.length }}</strong> registros
            </div>
            <div class="ranking-pagination-box mt-2 mt-sm-0">
              <v-btn
                size="small"
                variant="tonal"
                class="ranking-page-btn"
                prepend-icon="mdi-chevron-left"
                :disabled="gridPage <= 1"
                @click="gridPage = Math.max(1, gridPage - 1)"
              >
                Anterior
              </v-btn>
              <div class="ranking-page-indicator">
                Página <strong>{{ gridPage }}</strong> de <strong>{{ gridPageCount }}</strong>
              </div>
              <v-btn
                size="small"
                variant="tonal"
                class="ranking-page-btn"
                append-icon="mdi-chevron-right"
                :disabled="gridPage >= gridPageCount"
                @click="gridPage = Math.min(gridPageCount, gridPage + 1)"
              >
                Próxima
              </v-btn>
            </div>
        </div>
      </v-card>

      </section>
    </div>

    <v-dialog v-model="syncCompanyModal" max-width="500">
       <v-card class="rounded-xl pa-4 text-center card-3d border-thin" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'glass-card'">
          <v-card-title class="text-h6 font-weight-black text-uppercase mb-2">Sincronizar ERP (Externo)</v-card-title>
          <v-card-text>
             <p class="mb-4 text-body-2 font-weight-bold opacity-80">
                Selecione o que deseja sincronizar e para qual empresa os dados serão atribuídos.
             </p>
             <v-radio-group v-model="syncType" inline class="justify-center mb-4 font-weight-bold">
                 <v-radio label="Financeiro" value="financial"></v-radio>
                 <v-radio label="Pedidos de Venda" value="orders"></v-radio>
             </v-radio-group>
             <v-select
                v-model="syncTargetCompanyId"
                :items="companyList"
                item-title="name"
                item-value="id"
                label="Empresa de Destino"
                variant="outlined"
                color="indigo"
                class="mb-4 ui-field font-weight-bold"
             ></v-select>
          </v-card-text>
          <v-card-actions class="justify-end gap-2">
             <v-btn variant="outlined" class="btn-3d font-weight-bold" @click="syncCompanyModal = false">Cancelar</v-btn>
             <v-btn color="indigo" variant="flat" class="btn-3d font-weight-bold" :disabled="!syncTargetCompanyId" @click="startSyncProcess">Iniciar Sincronização</v-btn>
          </v-card-actions>
       </v-card>
    </v-dialog>

    <v-dialog v-model="showProgressModal" persistent max-width="700">
      <v-card class="rounded-xl overflow-hidden bg-grey-darken-4 text-white card-3d border-thin">
        <v-card-title class="d-flex align-center justify-space-between py-4 border-b border-white-10">
          <span class="text-h6 font-weight-black text-uppercase">Console de Sincronização</span>
          <v-btn icon variant="text" class="btn-3d" density="compact" color="white" @click="closeProgressModal" :disabled="isSyncingCajuia"><v-icon>mdi-close</v-icon></v-btn>
        </v-card-title>
        <v-card-text class="pa-0">
          <v-progress-linear v-if="isSyncingCajuia" indeterminate color="cyan-accent-3" height="6"></v-progress-linear>
          <v-progress-linear v-else model-value="100" color="success" height="6"></v-progress-linear>
          <div class="logs-container pa-4 font-mono text-caption custom-scroll" style="height: 400px; overflow-y: auto; background-color: #000;">
            <div v-for="(log, i) in syncLogs" :key="i" class="mb-1 d-flex align-start">
              <span class="text-grey mr-3" style="min-width: 60px;">[{{ log.time }}]</span>
              <span :class="getLogColor(log.type)">{{ log.message }}</span>
            </div>
            <div v-if="syncLogs.length === 0" class="text-grey-darken-2 text-center mt-10">Aguardando início...</div>
            <div ref="logsBottom"></div>
          </div>
        </v-card-text>
        <v-divider class="border-white-10"></v-divider>
        <v-card-actions class="pa-4 justify-end">
           <v-btn v-if="!isSyncingCajuia" color="white" variant="outlined" class="font-weight-bold btn-3d" @click="closeProgressModal">Fechar Console</v-btn>
           <v-btn v-else color="grey" variant="text" disabled class="font-weight-bold">Processando...</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <v-dialog v-model="showAddCompanyModal" max-width="500">
       <v-card class="rounded-xl pa-4 card-3d border-thin" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'glass-card'">
          <v-card-title class="text-h6 font-weight-black text-uppercase mb-2 text-center">Adicionar Empresa ao Painel</v-card-title>
          <v-card-text>
             <p class="mb-4 text-body-2 font-weight-bold opacity-80 text-center">
                Selecione uma empresa do sistema para exibir os indicadores financeiros na Visão Global.
             </p>
             <v-autocomplete
                v-model="newCompanyToDashboardId"
                :items="availableCompaniesToAdd"
                item-title="name"
                item-value="id"
                label="Selecione uma Empresa"
                variant="outlined"
                color="primary"
                class="ui-field font-weight-bold"
             ></v-autocomplete>
          </v-card-text>
          <v-card-actions class="justify-end gap-2">
             <v-btn variant="text" class="font-weight-bold" @click="showAddCompanyModal = false">Cancelar</v-btn>
             <v-btn color="primary" variant="flat" class="btn-3d font-weight-bold px-6" :disabled="!newCompanyToDashboardId" @click="addExtraCompany">Adicionar</v-btn>
          </v-card-actions>
       </v-card>
    </v-dialog>

    <v-snackbar v-model="snackbar.show" :color="snackbar.color" :timeout="4000" location="top center" content-class="font-weight-bold elevation-10 rounded-lg">
      <v-icon start>mdi-information</v-icon>
      {{ snackbar.text }}
    </v-snackbar>

  </v-container>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onActivated, defineAsyncComponent, reactive, onUnmounted, nextTick, watch } from 'vue';
import { useDashboardStore } from '@/stores/dashboard';
import { useThemeStore } from '@/stores/theme';
import { useUserStore } from '@/stores/user';
import { useCompanyStore } from '@/stores/company';
import { storeToRefs } from 'pinia';
import { gestaoApi } from '@/api/gestaoClick';
import { gestaoApiCajuia } from '@/api/gestaoClick_Cajuia';
import { format, startOfMonth, endOfMonth, parseISO, startOfYear, endOfYear, isPast, isToday } from 'date-fns';
import { ptBR } from 'date-fns/locale';
import { Chart as ChartJS, Title, Tooltip, Legend, ArcElement, CategoryScale, LineElement, LinearScale, PointElement, BarElement, Filler } from 'chart.js';
import { supabase } from '@/api/supabase';
import { useRouter } from 'vue-router';

import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import * as XLSX from 'xlsx';
import logoMj from '@/assets/logomjlm.png';
import logoCajuia from '@/assets/logocajuia.png';

ChartJS.register(Title, Tooltip, Legend, ArcElement, CategoryScale, LineElement, LinearScale, PointElement, BarElement, Filler);

const Bar = defineAsyncComponent(() => import('vue-chartjs').then(c => c.Bar));
const Doughnut = defineAsyncComponent(() => import('vue-chartjs').then(c => c.Doughnut));

const themeStore = useThemeStore();
const dashboardStore = useDashboardStore();
const userStore = useUserStore();
const companyStore = useCompanyStore();
const router = useRouter();

const { monthlyProduction } = storeToRefs(dashboardStore);

const STORE_IDS = { MJ: 523283, CAJUIA: 524728 };

const nameIndustry = computed(() => companyStore.isDemoMode ? 'Indústria Fictícia S.A.' : 'MJ Process');
const nameRetail = computed(() => companyStore.isDemoMode ? 'Varejo Fictício Ltda.' : 'Santos & Lopes');
const shortNameIndustry = computed(() => companyStore.isDemoMode ? 'INDÚSTRIA' : 'MJ');
const shortNameRetail = computed(() => companyStore.isDemoMode ? 'VAREJO' : 'CAJUIA');

const contexts = computed(() => [
  { title: companyStore.isDemoMode ? 'Visão Global (Demo)' : 'Visão Geral (Holding)', value: 'general', icon: 'mdi-domain', color: 'bg-gradient-purple' },
  { title: nameIndustry.value, value: 'mj', icon: 'mdi-factory', color: 'bg-gradient-primary' },
  { title: nameRetail.value, value: 'cajuia', icon: 'mdi-storefront', color: 'bg-gradient-orange' }
]);

const tenantContextButtons = computed(() => {
  const companies = companyStore.availableCompanies || [];

  const mappedCompanies = companies.map((company: any) => {
    const label = company.trade_name || company.name || 'Empresa';
    const normalized = `${label} ${company.name || ''}`.toLowerCase();

    const isRetail = normalized.includes('santos') || normalized.includes('lopes') || normalized.includes('cajuia');
    const isIndustry = normalized.includes('jacky') || normalized.includes('mr jacky') || normalized.includes('mj');

    return {
      id: company.id,
      name: label,
      icon: isRetail ? 'mdi-storefront' : (isIndustry ? 'mdi-factory' : 'mdi-domain'),
      color: isRetail ? 'orange-darken-2' : (isIndustry ? 'indigo-darken-2' : 'success'),
      isHolding: false
    };
  });

  return [
    ...mappedCompanies,
    {
      id: 'global',
      name: companyStore.isDemoMode ? 'DEMO GLOBAL' : 'HOLDING / GLOBAL',
      icon: 'mdi-domain',
      color: 'purple',
      isHolding: true
    }
  ];
});

const dashboardSubtitle = computed(() => {
  if (companyStore.isGlobalView) {
    return 'Visão Consolidada: Regime de Caixa & Competência.';
  }

  return `Visão focada em ${companyStore.currentCompanyName}: financeiro, vendas e rankings desta empresa.`;
});

const handleContextIslandScroll = () => {
  isContextIslandFloating.value = window.scrollY > 120;
};

const setTenantContext = async (contextId: string) => {
  companyStore.setContext(contextId);

  if (contextId === 'global') {
    currentContext.value = 'general';
  } else {
    const company = companyStore.availableCompanies.find((c: any) => c.id === contextId);
    const label = `${company?.trade_name || ''} ${company?.name || ''}`.toLowerCase();

    if (label.includes('santos') || label.includes('lopes') || label.includes('cajuia')) {
      currentContext.value = 'cajuia';
    } else {
      currentContext.value = 'mj';
    }
  }

  await fetchHoldingData();
};

const currentContext = ref('general');
const isLoading = ref(false);
const isSyncingCajuia = ref(false);
const reportLoading = ref(false);
const snackbar = reactive({ show: false, text: '', color: '' });
const panelMenuOpen = ref(false);
const isContextIslandFloating = ref(false);

const mjCompanyId = ref<string | null>(null);
const cjCompanyId = ref<string | null>(null);

const syncCompanyModal = ref(false);
const showProgressModal = ref(false);
const syncTargetCompanyId = ref<string | null>(null);
const syncType = ref('financial');
const companyList = ref<any[]>([]);

const visibleBlocks = ref<string[]>(JSON.parse(localStorage.getItem('superAdminVisibleBlocks') || '["MJ", "CAJUIA", "UNLINKED"]'));

const toggleBlock = (block: string) => {
    if (visibleBlocks.value.includes(block)) {
        visibleBlocks.value = visibleBlocks.value.filter(b => b !== block);
    } else {
        visibleBlocks.value.push(block);
    }
    localStorage.setItem('superAdminVisibleBlocks', JSON.stringify(visibleBlocks.value));
};

interface SyncLog { time: string; message: string; type: 'info' | 'success' | 'error' | 'warning'; }
const syncLogs = ref<SyncLog[]>([]);
const logsBottom = ref<HTMLElement | null>(null);

const addLog = (message: string, type: 'info' | 'success' | 'error' | 'warning' = 'info') => {
    const time = format(new Date(), 'HH:mm:ss');
    syncLogs.value.push({ time, message, type });
    nextTick(() => { if(logsBottom.value) logsBottom.value.scrollIntoView({ behavior: 'smooth' }); });
};

const getLogColor = (type: string) => {
    switch(type) { case 'success': return 'text-green-accent-3'; case 'error': return 'text-red-accent-2 font-weight-bold'; case 'warning': return 'text-orange-accent-2'; default: return 'text-grey-lighten-2'; }
};

const closeProgressModal = () => { showProgressModal.value = false; };

const startSyncProcess = () => {
    if (companyStore.isDemoMode) return showSnackbar('Ação não permitida em modo demonstração', 'warning');
    syncCompanyModal.value = false;
    showProgressModal.value = true;
    confirmSyncCajuia();
};

const currentContextObj = computed(() => contexts.value.find(c => c.value === currentContext.value) || contexts.value[0]);
const currentContextTitle = computed(() => currentContextObj.value.title);
const contextIcon = computed(() => currentContextObj.value.icon);
const contextIconColor = computed(() => themeStore.currentMode === 'light' ? 'bg-grey-darken-4 text-white' : currentContextObj.value.color);

const globalFilter = ref('month');
const customStartDate = ref(format(startOfMonth(new Date()), 'yyyy-MM-dd'));
const customEndDate = ref(format(endOfMonth(new Date()), 'yyyy-MM-dd'));

const chartFilterMJ = ref('month');
const chartFilterCajuia = ref('month');
const storeFilterPeriod = ref('month');

const mjPayablesTotal = ref(0);
const mjReceivablesTotal = ref(0);
const cajuiaPayablesTotal = ref(0);
const cajuiaReceivablesTotal = ref(0);
const unlinkedPayablesTotal = ref(0);
const unlinkedReceivablesTotal = ref(0);

const mjExecution = reactive({ received: 0, missingRec: 0, paid: 0, missingPay: 0 });
const cajuiaExecution = reactive({ received: 0, missingRec: 0, paid: 0, missingPay: 0 });
const unlinkedExecution = reactive({ received: 0, missingRec: 0, paid: 0, missingPay: 0 });

const cajuiaMonthlySalesCount = ref(0);
const cajuiaMonthlyPiecesCount = ref(0);
const tenantMetrics = reactive({ salesCount: 0, piecesSold: 0, metersSold: 0 });
const tenantTopCustomers = ref<Array<{ name: string; total: number; count: number }>>([]);
const tenantTopProducts = ref<Array<{ name: string; quantity: number; total: number; count: number }>>([]);
const tenantTopSellers = ref<Array<{ name: string; total: number; count: number }>>([]);

const rankingItemsPerPage = 8;
const tenantCustomerPage = ref(1);
const tenantProductPage = ref(1);
const tenantSellerPage = ref(1);

const tenantCustomerPageCount = computed(() => Math.max(1, Math.ceil(tenantTopCustomers.value.length / rankingItemsPerPage)));
const tenantProductPageCount = computed(() => Math.max(1, Math.ceil(tenantTopProducts.value.length / rankingItemsPerPage)));
const tenantSellerPageCount = computed(() => Math.max(1, Math.ceil(tenantTopSellers.value.length / rankingItemsPerPage)));

const paginatedTenantCustomers = computed(() => {
    const start = (tenantCustomerPage.value - 1) * rankingItemsPerPage;
    return tenantTopCustomers.value.slice(start, start + rankingItemsPerPage);
});

const paginatedTenantProducts = computed(() => {
    const start = (tenantProductPage.value - 1) * rankingItemsPerPage;
    return tenantTopProducts.value.slice(start, start + rankingItemsPerPage);
});

const paginatedTenantSellers = computed(() => {
    const start = (tenantSellerPage.value - 1) * rankingItemsPerPage;
    return tenantTopSellers.value.slice(start, start + rankingItemsPerPage);
});


const showAddCompanyModal = ref(false);
const newCompanyToDashboardId = ref<string | null>(null);
const activeExtraCompanyIds = ref<string[]>(JSON.parse(localStorage.getItem('superAdminExtraCompanies') || '[]'));
const displayedExtraCompanies = ref<any[]>([]);

const availableCompaniesToAdd = computed(() => {
    return companyList.value.filter(c =>
        c.id !== mjCompanyId.value &&
        c.id !== cjCompanyId.value &&
        !activeExtraCompanyIds.value.includes(c.id)
    );
});

const openAddCompanyModal = async () => {
    if (companyList.value.length === 0) await fetchCompanies();

    if (companyStore.isDemoMode) {
        addExtraCompany();
    } else {
        newCompanyToDashboardId.value = null;
        showAddCompanyModal.value = true;
    }
};

const addExtraCompany = () => {
    if (companyStore.isDemoMode) {
        const fakeId = `fake-company-${Date.now()}`;
        activeExtraCompanyIds.value.push(fakeId);
        showSnackbar('Empresa Fictícia adicionada ao painel!', 'success');
    } else {
        if (!newCompanyToDashboardId.value) return;
        activeExtraCompanyIds.value.push(newCompanyToDashboardId.value);
        localStorage.setItem('superAdminExtraCompanies', JSON.stringify(activeExtraCompanyIds.value));
        showAddCompanyModal.value = false;
        showSnackbar('Empresa vinculada com sucesso!', 'success');
    }
    fetchHoldingData();
};

const removeExtraCompany = (id: string) => {
    activeExtraCompanyIds.value = activeExtraCompanyIds.value.filter(cId => cId !== id);
    if (!companyStore.isDemoMode) {
        localStorage.setItem('superAdminExtraCompanies', JSON.stringify(activeExtraCompanyIds.value));
    }
    fetchHoldingData();
};

const globalReceivablesTotal = computed(() => Number(mjReceivablesTotal.value) + Number(cajuiaReceivablesTotal.value) + Number(unlinkedReceivablesTotal.value) + displayedExtraCompanies.value.reduce((sum, c) => sum + c.receivablesTotal, 0));
const globalExecutionReceived = computed(() => Number(mjExecution.received) + Number(cajuiaExecution.received) + Number(unlinkedExecution.received) + displayedExtraCompanies.value.reduce((sum, c) => sum + c.execution.received, 0));
const globalExecutionMissingRec = computed(() => Number(mjExecution.missingRec) + Number(cajuiaExecution.missingRec) + Number(unlinkedExecution.missingRec) + displayedExtraCompanies.value.reduce((sum, c) => sum + c.execution.missingRec, 0));

const globalPayablesTotal = computed(() => Number(mjPayablesTotal.value) + Number(cajuiaPayablesTotal.value) + Number(unlinkedPayablesTotal.value) + displayedExtraCompanies.value.reduce((sum, c) => sum + c.payablesTotal, 0));
const globalExecutionPaid = computed(() => Number(mjExecution.paid) + Number(cajuiaExecution.paid) + Number(unlinkedExecution.paid) + displayedExtraCompanies.value.reduce((sum, c) => sum + c.execution.paid, 0));
const globalExecutionMissingPay = computed(() => Number(mjExecution.missingPay) + Number(cajuiaExecution.missingPay) + Number(unlinkedExecution.missingPay) + displayedExtraCompanies.value.reduce((sum, c) => sum + c.execution.missingPay, 0));

const mjChartData = ref({ labels: [] as string[], datasets: [] as any[] });
const cajuiaChartData = ref({ labels: [] as string[], datasets: [] as any[] });
const realBanks = ref<any[]>([]);

const allProjectionItems = ref<any[]>([]);
const storeSummaries = ref<any[]>([]);
const selectedStores = ref<string[]>([]);
const gridPage = ref(1);
const gridItemsPerPage = 40;

const finalFilteredItems = computed(() => {
    return allProjectionItems.value.filter(i => selectedStores.value.includes(i.filial));
});

const paginatedGridItems = computed(() => {
    const start = (gridPage.value - 1) * gridItemsPerPage;
    return finalFilteredItems.value.slice(start, start + gridItemsPerPage);
});

const gridPageCount = computed(() => Math.ceil(finalFilteredItems.value.length / gridItemsPerPage));

const gridKpis = computed(() => {
    let rec = 0, pay = 0;
    finalFilteredItems.value.forEach(i => {
        const val = Number(i.value) - Number(i.discount || 0);
        if (i.type === 'receivable') rec += val;
        else pay += val;
    });
    return { receitas: rec, despesas: pay, saldo: rec - pay };
});

const toggleStoreFilter = (storeName: string) => {
    const idx = selectedStores.value.indexOf(storeName);
    if (idx > -1) selectedStores.value.splice(idx, 1);
    else selectedStores.value.push(storeName);
    gridPage.value = 1;
};

watch(currentContext, () => {
    selectedStores.value = storeSummaries.value.map(s => s.name);
    gridPage.value = 1;
});

const createDoughnutData = (realized: number, missing: number, color: string) => ({
  labels: ['Realizado', 'Falta'], datasets: [{ backgroundColor: [color, 'rgba(255,255,255,0.15)'], borderWidth: 0, data: [realized, missing] }]
});

const mjRecDoughnutData = computed(() => createDoughnutData(mjExecution.received, mjExecution.missingRec, '#69F0AE'));
const mjPayDoughnutData = computed(() => createDoughnutData(mjExecution.paid, mjExecution.missingPay, '#FF5252'));
const cajuiaRecDoughnutData = computed(() => createDoughnutData(cajuiaExecution.received, cajuiaExecution.missingRec, '#69F0AE'));
const cajuiaPayDoughnutData = computed(() => createDoughnutData(cajuiaExecution.paid, cajuiaExecution.missingPay, '#FF5252'));
const unlinkedDoughnutRec = computed(() => createDoughnutData(unlinkedExecution.received, unlinkedExecution.missingRec, '#69F0AE'));
const unlinkedDoughnutPay = computed(() => createDoughnutData(unlinkedExecution.paid, unlinkedExecution.missingPay, '#FF5252'));
const globalRecDoughnutData = computed(() => createDoughnutData(globalExecutionReceived.value, globalExecutionMissingRec.value, '#69F0AE'));
const globalPayDoughnutData = computed(() => createDoughnutData(globalExecutionPaid.value, globalExecutionMissingPay.value, '#FF5252'));

const formatFilterLabel = computed(() => {
   if (globalFilter.value === 'today') return 'Hoje';
   if (globalFilter.value === 'month') return 'Este Mês';
   if (globalFilter.value === 'year') return 'Este Ano';
   return `${formatDateSimple(customStartDate.value)} a ${formatDateSimple(customEndDate.value)}`;
});

const showSnackbar = (msg: string, color: string = 'success') => {
    snackbar.text = msg;
    snackbar.color = color;
    snackbar.show = true;
};

const onGlobalFilterChange = () => {
    if (globalFilter.value !== 'custom') {
        fetchHoldingData();
    }
};

const applyCustomFilter = () => {
    if (customStartDate.value && customEndDate.value) {
        fetchHoldingData();
    } else {
        showSnackbar('Selecione a data inicial e final!', 'warning');
    }
};

const safeDateOrNull = (dateStr: any) => {
    if (!dateStr || dateStr === '' || dateStr === '0000-00-00') return null;
    return dateStr;
};

const confirmSyncCajuia = async () => {
    if (!syncTargetCompanyId.value) {
        addLog("Erro: Nenhuma empresa selecionada.", 'error');
        return;
    }

    isSyncingCajuia.value = true;
    syncLogs.value = [];
    addLog("=== INICIANDO SYNC ERP ===", 'info');
    addLog(`Tipo de Sincronização: ${syncType.value.toUpperCase()}`, 'info');

    try {
        const today = new Date();
        const start = '2020-01-01';
        const end = format(today, 'yyyy-MM-dd');

        if (syncType.value === 'financial') {
            await syncFinancialData(start, end);
        } else if (syncType.value === 'orders') {
            await syncOrdersData(start, end);
        }

        addLog("Atualizando Dashboard...", 'info');
        await fetchHoldingData();

        addLog("=== SINCRONIZAÇÃO CONCLUÍDA COM SUCESSO! ===", 'success');
        showSnackbar('Dados sincronizados com sucesso!', 'success');

    } catch (error: any) {
        addLog(`Erro Crítico no Sync: ${error.message || error}`, 'error');
    } finally {
        isSyncingCajuia.value = false;
    }
};

const syncFinancialData = async (start: string, end: string) => {
    addLog("1. Buscando Pagamentos no ERP...", 'info');
    try {
        const payData = await gestaoApi.buscarPagamentos({ data_inicio: start, data_fim: end, loja_id: STORE_IDS.CAJUIA });
        if (payData && payData.length > 0) {
            const payloads = payData.filter((item: any) => item.id).map((item: any) => ({
                gestao_click_id: item.id,
                description: item.descricao,
                value: parseFloat(item.valor_total || item.valor || 0),
                due_date: safeDateOrNull(item.data_vencimento),
                competence_date: safeDateOrNull(item.data_competencia) || safeDateOrNull(item.data_vencimento),
                status: (item.liquidado == '1' || item.liquidado === true) ? 'pago' : 'pendente',
                payment_date: safeDateOrNull(item.data_liquidacao),
                entity_name: item.nome_fornecedor,
                notes: item.observacoes,
                company_id: syncTargetCompanyId.value
            }));

            await supabase.from('finance_payables').upsert(payloads, { onConflict: 'gestao_click_id' });
            addLog("Pagamentos salvos com sucesso.", 'success');
        }
    } catch (e: any) { addLog(`Erro pagamentos: ${e.message}`, 'error'); }

    addLog("2. Buscando Recebimentos no ERP...", 'info');
    try {
        const recData = await gestaoApi.buscarRecebimentos({ data_inicio: start, data_fim: end, loja_id: STORE_IDS.CAJUIA });
        if (recData && recData.length > 0) {
            const payloads = recData.filter((item: any) => item.id).map((item: any) => ({
                gestao_click_id: item.id,
                description: item.descricao,
                value: parseFloat(item.valor_total || item.valor || 0),
                due_date: safeDateOrNull(item.data_vencimento),
                competence_date: safeDateOrNull(item.data_competencia) || safeDateOrNull(item.data_vencimento),
                status: (item.liquidado == '1' || item.liquidado === true) ? 'pago' : 'em_aberto',
                payment_date: safeDateOrNull(item.data_liquidacao),
                entity_name: item.nome_cliente,
                notes: item.observacoes,
                company_id: syncTargetCompanyId.value
            }));

            await supabase.from('finance_receivables').upsert(payloads, { onConflict: 'gestao_click_id' });
            addLog("Recebimentos salvos com sucesso.", 'success');
        }
    } catch (e: any) { addLog(`Erro recebimentos: ${e.message}`, 'error'); }
};

const syncOrdersData = async (start: string, end: string) => {
    try {
        const salesData = await gestaoApiCajuia.buscarVendas({
            data_inicio: start, data_fim: end, loja_id: String(STORE_IDS.CAJUIA), tipo: 'vendas_balcao'
        });

        if (salesData && salesData.length > 0) {
            const payloads = salesData.map((sale: any) => {
                let status = 'pending';
                const situacao = (sale.nome_situacao || '').toLowerCase();
                if (situacao.includes('concretizada') || situacao.includes('confirmado') || situacao.includes('faturado')) status = 'completed';
                else if (situacao.includes('cancelad')) status = 'cancelled';

                let payStatus = status === 'completed' ? 'paid' : 'pending';

                return {
                    gestao_click_id: String(sale.id),
                    order_number: sale.codigo || sale.id,
                    customer_name: sale.nome_cliente || 'Consumidor Final',
                    total_value: parseFloat(sale.valor_total || 0),
                    discount_value: parseFloat(sale.valor_desconto || 0),
                    net_value: parseFloat(sale.valor_total || 0),
                    created_at: sale.data ? `${sale.data}T12:00:00` : new Date().toISOString(),
                    date_sale: sale.data,
                    status: status,
                    payment_status: payStatus,
                    company_id: syncTargetCompanyId.value,
                    seller_name: sale.nome_vendedor,
                    items: sale.produtos || [],
                    payments: sale.pagamentos || [],
                    notes: sale.observacoes || ''
                };
            });

            await supabase.from('store_sales').upsert(payloads, { onConflict: 'gestao_click_id' });
            addLog(`Sucesso! ${payloads.length} vendas sincronizadas.`, 'success');
        }
    } catch (e: any) { addLog(`Erro vendas: ${e.message}`, 'error'); }
};

const generateReport = async (type: 'pdf' | 'excel') => {
    reportLoading.value = true;
    try {
        const dataToExport = finalFilteredItems.value.map(item => {
            const isReceivable = item.type === 'receivable';
            const isCajuia = item.filial === shortNameRetail.value;
            return {
                ...item,
                numeric_value: Number(item.value) - Number(item.discount || 0),
                empresaNome: item.filial,
                tipoDoc: isReceivable ? 'CONTAS A RECEBER' : 'CONTAS A PAGAR',
                entity_name: item.entity_name || 'Diversos/Não Informado',
                isReceivable,
                isCajuia
            };
        });

        if (dataToExport.length === 0) return showSnackbar('Nenhum dado para exportar', 'warning');

        if (type === 'excel') {
            const ws = XLSX.utils.json_to_sheet(dataToExport.map(i => ({
                Empresa: i.empresaNome,
                Filial: i.filial,
                Operacao: i.tipoDoc,
                Vencimento: formatDateSimple(i.due_date),
                Entidade: i.entity_name,
                Descricao: i.description,
                Valor: i.numeric_value,
                Status: getStatusLabelDash(i).toUpperCase()
            })));
            const wb = XLSX.utils.book_new();
            XLSX.utils.book_append_sheet(wb, ws, "Fluxo");
            XLSX.writeFile(wb, `Relatorio_Dashboard_${format(new Date(), 'dd-MM-yyyy')}.xlsx`);
            return showSnackbar("Excel Gerado!", "success");
        }

        const doc = new jsPDF({ orientation: 'l', unit: 'mm', format: 'a4' });
        const pageWidth = doc.internal.pageSize.width;

        const contextName = currentContext.value === 'general' ? 'VISÃO GLOBAL - HOLDING' : (currentContext.value === 'mj' ? `${nameIndustry.value} - INDÚSTRIA` : `${nameRetail.value} - VAREJO`);

        const drawHeader = (d: any, pageTitle: string, subtitle: string) => {
            try {
                if (!companyStore.isDemoMode) {
                    if (currentContext.value === 'general') {
                        d.addImage(logoMj, 'PNG', 15, 10, 32, 12);
                        d.addImage(logoCajuia, 'PNG', 50, 10, 32, 12);
                    } else if (currentContext.value === 'cajuia') {
                        d.addImage(logoCajuia, 'PNG', 15, 10, 40, 15);
                    } else {
                        d.addImage(logoMj, 'PNG', 15, 10, 40, 15);
                    }
                }
            } catch(e) {}

            d.setFontSize(14).setFont('helvetica', 'bold').setTextColor(30, 30, 30);
            d.text(pageTitle, pageWidth - 15, 16, { align: 'right' });
            d.setFontSize(9).setFont('helvetica', 'normal').setTextColor(100);
            d.text(subtitle, pageWidth - 15, 22, { align: 'right' });
            d.setDrawColor(220, 220, 220);
            d.line(15, 26, pageWidth - 15, 26);
        };

        drawHeader(doc, "RELATÓRIO CONSOLIDADO DE FLUXO DE CAIXA", `Período: ${formatFilterLabel.value}`);

        doc.setFontSize(12).setFont('helvetica', 'bold').setTextColor(20);
        doc.text(`RESUMO DO CONTEXTO: ${contextName}`, 15, 40);

        const drawCoverKpi = (label: string, val: number, color: number[], x: number, y: number, w: number = 70) => {
            doc.setFillColor(color[0], color[1], color[2]);
            doc.roundedRect(x, y, w, 28, 3, 3, 'F');
            doc.setDrawColor(color[0]-20, color[1]-20, color[2]-20);
            doc.roundedRect(x, y, w, 28, 3, 3, 'S');
            doc.setFontSize(8).setFont('helvetica', 'bold').setTextColor(100, 100, 100);
            doc.text(label.toUpperCase(), x + (w/2), y + 10, { align: 'center' });
            doc.setFontSize(14).setFont('helvetica', 'bold').setTextColor(30, 30, 30);
            doc.text(formatCurrency(val), x + (w/2), y + 21, { align: 'center' });
        };

        drawCoverKpi("A Receber (Entradas)", gridKpis.value.receitas, [232, 248, 235], 15, 50, 80);
        drawCoverKpi("A Pagar (Saídas)", gridKpis.value.despesas, [255, 235, 238], 105, 50, 80);
        drawCoverKpi("Saldo Líquido", gridKpis.value.saldo, [240, 244, 248], 195, 50, 80);

        const renderCompanyTable = (empresaNome: string, itens: any[], title: string) => {
            if (itens.length === 0) return;
            doc.addPage();
            drawHeader(doc, `DETALHAMENTO: ${empresaNome}`, `Período: ${formatFilterLabel.value}`);

            doc.setFontSize(12).setFont('helvetica', 'bold').setTextColor(20);
            doc.text(title, 15, 36);

            const empRec = itens.filter(i => i.isReceivable).reduce((a,b) => a + b.numeric_value, 0);
            const empPay = itens.filter(i => !i.isReceivable).reduce((a,b) => a + b.numeric_value, 0);
            const empSaldo = empRec - empPay;

            doc.setFontSize(9).setFont('helvetica', 'normal').setTextColor(80);
            doc.text(`Entradas: ${formatCurrency(empRec)}   |   Saídas: ${formatCurrency(empPay)}   |   Saldo: ${formatCurrency(empSaldo)}`, 15, 42);

            const columns = [
                { header: 'Operação', dataKey: 'tipoDoc' },
                { header: 'Filial', dataKey: 'filial' },
                { header: 'Ref/Venc.', dataKey: 'due_date' },
                { header: 'Pessoa / Entidade', dataKey: 'entity' },
                { header: 'Descrição', dataKey: 'desc' },
                { header: 'Status', dataKey: 'status' },
                { header: 'Valor', dataKey: 'value' }
            ];

            const tableBody = itens.map(row => {
                const isPaid = ['paid','pago','received'].includes(row.status?.toLowerCase());
                const isOverdueItem = !isPaid && isPast(parseISO(row.due_date)) && !isToday(parseISO(row.due_date));
                let rowColor: [number, number, number] = [255, 255, 255];
                if (row.isReceivable) rowColor = isPaid ? [235, 248, 235] : [250, 250, 250];
                else rowColor = isPaid ? [245, 245, 245] : (isOverdueItem ? [255, 235, 235] : [255, 248, 245]);

                return {
                    tipoDoc: row.tipoDoc, filial: row.filial, due_date: formatDateSimple(row.due_date),
                    entity: (row.entity_name || '').substring(0, 40), desc: (row.description || '').substring(0, 45),
                    status: getStatusLabelDash(row).toUpperCase(), value: (row.isReceivable ? '+ ' : '- ') + formatCurrency(row.numeric_value),
                    _rowColor: rowColor, _isReceivable: row.isReceivable
                };
            });

            autoTable(doc, {
                startY: 48, columns: columns, body: tableBody, theme: 'grid',
                styles: { fontSize: 8, cellPadding: 3, textColor: 50, lineColor: [220, 220, 220], lineWidth: 0.1 },
                headStyles: { fillColor: [50, 50, 55], textColor: 255, fontStyle: 'bold', halign: 'center' },
                columnStyles: {
                    tipoDoc: { cellWidth: 28, fontStyle: 'bold', halign: 'center' }, filial: { cellWidth: 25, halign: 'center' }, due_date: { cellWidth: 20, halign: 'center' },
                    entity: { cellWidth: 50 }, desc: { cellWidth: 'auto' }, status: { cellWidth: 25, halign: 'center', fontStyle: 'bold' }, value: { cellWidth: 35, halign: 'right', fontStyle: 'bold' }
                },
                didParseCell: (data) => {
                    if (data.section === 'body') {
                        const row = data.row.raw as any;
                        if (row._rowColor) data.cell.styles.fillColor = row._rowColor;
                        if (data.column.dataKey === 'tipoDoc' || data.column.dataKey === 'value') data.cell.styles.textColor = row._isReceivable ? [46, 125, 50] : [198, 40, 40];
                        else data.cell.styles.textColor = [40, 40, 40];
                    }
                }
            });
        };

        const mjItens = dataToExport.filter(i => !i.isCajuia && i.filial !== 'NÃO VINCULADOS');
        const cjItens = dataToExport.filter(i => i.isCajuia);
        const unlinkedItens = dataToExport.filter(i => i.filial === 'NÃO VINCULADOS');

        if (currentContext.value === 'general' || currentContext.value === 'mj') renderCompanyTable(`${nameIndustry.value} (INDÚSTRIA)`, mjItens, 'Lançamentos Financeiros (Caixa/Competência)');
        if (currentContext.value === 'general' || currentContext.value === 'cajuia') renderCompanyTable(`${nameRetail.value} (VAREJO)`, cjItens, 'Lançamentos Financeiros (Caixa/Competência)');
        if (currentContext.value === 'general' && unlinkedItens.length > 0) renderCompanyTable(`REGISTROS SEM EMPRESA`, unlinkedItens, 'Lançamentos Financeiros (Não Vinculados)');

        doc.save(`Relatorio_Dashboard_Financeiro_${format(new Date(), 'yyyyMMdd_HHmm')}.pdf`);
        showSnackbar('Relatório PDF Gerado!', 'success');
    } catch (err: any) {
        showSnackbar('Erro ao gerar relatório', 'error');
    } finally {
        reportLoading.value = false;
    }
};

const filterByDateExact = (item: any, start: string, end: string) => {
    const dStr = item.due_date ? item.due_date.substring(0, 10) : null;
    if (!dStr) return false;
    return dStr >= start && dStr <= end;
};

const bucketData = (items: any[], filter: string) => {
   let labels: string[] = []; const map = new Map<string, number>();
   const getBucketDate = (item: any) => { return item.due_date; };

   if (filter === 'day') {
      items.forEach(item => {
          const dateStr = getBucketDate(item); if (!dateStr) return;
          try {
              const key = dateStr.substring(0, 10);
              map.set(key, (map.get(key) || 0) + (Number(item.value || item.amount || item.gross_value) || 0));
          } catch {}
      });
      labels = Array.from(map.keys()).sort();
      const displayLabels = labels.map(d => d.substring(8,10) + '/' + d.substring(5,7));
      return { labels: displayLabels, values: labels.map(l => map.get(l) || 0) };
   } else if (filter === 'month') {
      labels = ['Sem 1', 'Sem 2', 'Sem 3', 'Sem 4', 'Sem 5'];
      items.forEach(item => { const dateStr = getBucketDate(item); if (!dateStr) return; try { const day = parseISO(dateStr).getDate(); const week = Math.ceil(day / 7); const key = `Sem ${Math.min(week, 5)}`; map.set(key, (map.get(key) || 0) + (Number(item.value || item.amount || item.gross_value) || 0)); } catch {} });
   } else if (filter === 'year') {
      labels = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
      items.forEach(item => { const dateStr = getBucketDate(item); if (!dateStr) return; try { const monthIdx = parseISO(dateStr).getMonth(); const key = labels[monthIdx]; map.set(key, (map.get(key) || 0) + (Number(item.value || item.amount || item.gross_value) || 0)); } catch {} });
   }
   labels.forEach(l => { if(!map.has(l)) map.set(l, 0); });
   const values = labels.map(l => map.get(l) || 0);
   return { labels, values };
};

const goToFinancial = (type: 'receivable' | 'payable', compId: string | null) => {
    if (compId) { companyStore.setContext(compId); companyStore.isGlobalView = false; } else { companyStore.isGlobalView = true; }
    if (type === 'receivable') { router.push({ name: 'FinancialReceivables' }); } else { router.push({ name: 'FinancialPayables' }); }
};

const fetchCompanies = async () => {
    try {
        const { data, error } = await supabase.from('companies').select('*').eq('active', true);
        if (error) throw error;
        companyList.value = data || [];
        const mj = data.find((c: any) => c.trade_name?.toUpperCase().includes('JACKY') || c.name?.toUpperCase().includes('JACKY'));
        const cj = data.find((c: any) => c.trade_name?.toUpperCase().includes('SANTOS') || c.trade_name?.toUpperCase().includes('LOPES') || c.name?.toUpperCase().includes('CAJUIA'));
        mjCompanyId.value = mj?.id || null;
        cjCompanyId.value = cj?.id || null;
    } catch (e) { console.error('Erro ao carregar empresas:', e); }
};


const normalizeTenantFromCompanyContext = () => {
    const ctx = companyStore.context;
    if (!ctx || ctx === 'global') {
        currentContext.value = 'general';
        return;
    }

    const selectedCompany = companyStore.availableCompanies.find((c: any) => c.id === ctx) || companyList.value.find((c: any) => c.id === ctx);
    const haystack = `${selectedCompany?.trade_name || ''} ${selectedCompany?.name || ''} ${selectedCompany?.cnpj || ''}`.toUpperCase();

    if (ctx === cjCompanyId.value || haystack.includes('CAJUIA') || haystack.includes('SANTOS') || haystack.includes('LOPES')) {
        currentContext.value = 'cajuia';
        return;
    }

    if (ctx === mjCompanyId.value || haystack.includes('JACKY') || haystack.includes('MR JACKY') || haystack.includes('MJ')) {
        currentContext.value = 'mj';
        return;
    }

    currentContext.value = 'general';
};

const resetTenantRankings = () => {
    tenantMetrics.salesCount = 0;
    tenantMetrics.piecesSold = 0;
    tenantMetrics.metersSold = 0;
    tenantTopCustomers.value = [];
    tenantTopProducts.value = [];
    tenantTopSellers.value = [];
};

const sumMapValue = (map: Map<string, any>, key: string, amount: number, quantity = 0) => {
    const safeKey = key?.trim() || 'Não informado';
    const current = map.get(safeKey) || { name: safeKey, total: 0, quantity: 0, count: 0 };
    current.total += Number(amount) || 0;
    current.quantity += Number(quantity) || 0;
    current.count += 1;
    map.set(safeKey, current);
};

const extractSaleItems = (sale: any) => {
    const raw = sale.items || sale.products || sale.order_items || sale.produtos || [];
    if (Array.isArray(raw)) return raw;
    if (typeof raw === 'string') {
        try {
            const parsed = JSON.parse(raw);
            return Array.isArray(parsed) ? parsed : [];
        } catch {
            return [];
        }
    }
    return [];
};

const getItemName = (item: any) => {
    const candidate =
        item.product_name ||
        item.nome_produto ||
        item.produto_nome ||
        item.name ||
        item.nome ||
        item.descricao ||
        item.description ||
        item.titulo ||
        item.sku ||
        item.codigo;

    if (typeof candidate === 'string' && candidate.trim()) {
        const clean = candidate.trim();
        if (clean.toLowerCase().includes('item sem nome')) return null;
        return clean;
    }

    if (item.produto && typeof item.produto === 'object') {
        return getItemName(item.produto);
    }

    return null;
};

const getItemQuantity = (item: any, fallback = 0) => {
    return Number(item.quantity_meters || item.meters || item.metragem || item.quantidade_metros || item.quantity || item.quantidade || item.qtd || fallback || 0);
};

const getItemValue = (item: any, sale: any = null, quantity = 0, itemsCount = 1) => {
    const explicit = Number(
        item.total_price ??
        item.total_value ??
        item.valor_total ??
        item.subtotal ??
        item.sub_total ??
        item.valor ??
        item.total ??
        0
    );
    if (explicit > 0) return explicit;

    const unit = Number(item.unit_price ?? item.preco_unitario ?? item.price ?? item.preco ?? item.valor_unitario ?? 0);
    if (unit > 0 && quantity > 0) return unit * quantity;

    const saleTotal = sale ? getSaleAmount(sale) : 0;
    if (saleTotal > 0 && itemsCount > 0) return saleTotal / itemsCount;

    return 0;
};

const getSaleAmount = (sale: any) => {
    return Number(sale.net_value || sale.total_value || sale.valor_total || sale.value || sale.amount || sale.gross_value || 0);
};

const getSaleDateColumnValue = (sale: any) => {
    return sale.date_sale || sale.created_at || sale.data || sale.emission_date || null;
};

const isSaleInRange = (sale: any, start: string, end: string) => {
    const raw = getSaleDateColumnValue(sale);
    if (!raw) return false;
    const d = String(raw).substring(0, 10);
    return d >= start && d <= end;
};


const fetchCajuiaStoreSalesSummary = async (start: string, end: string) => {
    if (!cjCompanyId.value) {
        cajuiaMonthlyPiecesCount.value = 0;
        return;
    }

    try {
        let from = 0;
        const step = 999;
        let hasMore = true;
        let salesCount = 0;
        let piecesCount = 0;

        while (hasMore) {
            const { data, error } = await supabase
                .from('store_sales')
                .select('id, status, items, date_sale, created_at, company_id')
                .eq('company_id', cjCompanyId.value)
                .gte('date_sale', start)
                .lte('date_sale', end)
                .range(from, from + step);

            if (error) throw error;

            const rows = data || [];
            rows.forEach((sale: any) => {
                const status = String(sale.status || '').toLowerCase();
                if (status.includes('cancel')) return;

                salesCount += 1;

                const items = extractSaleItems(sale);
                if (items.length === 0) {
                    piecesCount += 1;
                    return;
                }

                items.forEach((item: any) => {
                    const productName = getItemName(item);
                    if (!productName) return;
                    piecesCount += getItemQuantity(item, 1);
                });
            });

            if (rows.length <= step) hasMore = false;
            else from += step + 1;
        }

        cajuiaMonthlySalesCount.value = salesCount;
        cajuiaMonthlyPiecesCount.value = piecesCount;
    } catch (error) {
        console.error('Erro ao calcular resumo de peças da Cajuia:', error);
        cajuiaMonthlyPiecesCount.value = 0;
    }
};


const fetchTenantRankings = async (start: string, end: string) => {
    resetTenantRankings();

    if (currentContext.value === 'general') return;

    const isCajuiaContext = currentContext.value === 'cajuia';
    const targetCompanyId = isCajuiaContext ? cjCompanyId.value : mjCompanyId.value;
    if (!targetCompanyId) return;

    const customers = new Map<string, any>();
    const products = new Map<string, any>();
    const sellers = new Map<string, any>();

    const addMoneyRank = (map: Map<string, any>, name: string, value: number) => {
        const key = name?.trim() || 'Não informado';
        const row = map.get(key) || { name: key, total: 0, quantity: 0, count: 0 };
        row.total += Number(value) || 0;
        row.count += 1;
        map.set(key, row);
    };

    const addProductRank = (name: string | null, quantity: number, value: number) => {
        const key = typeof name === 'string' ? name.trim() : '';
        const qty = Number(quantity) || 0;
        const total = Number(value) || 0;

        // Na Cajuia, ranking de produtos só entra quando existe nome real do produto.
        // Isso evita a linha inútil "Item sem nome / R$ 0,00" que vinha de vendas integradas sem detalhamento.
        if (!key) return;
        if (isCajuiaContext && key.toLowerCase().includes('item sem nome')) return;
        if (isCajuiaContext && qty <= 0 && total <= 0) return;

        const row = products.get(key) || { name: key, total: 0, quantity: 0, count: 0 };
        row.quantity += qty;
        row.total += total;
        row.count += 1;
        products.set(key, row);
    };

    const fetchPaged = async (table: string, buildQuery: (from: number, to: number) => any) => {
        let dataArr: any[] = [];
        let from = 0;
        const step = 999;
        let hasMore = true;

        while (hasMore) {
            const { data, error } = await buildQuery(from, from + step);
            if (error) throw error;

            if (data && data.length > 0) {
                dataArr = dataArr.concat(data);
                if (data.length <= step) hasMore = false;
                else from += step + 1;
            } else {
                hasMore = false;
            }
        }

        return dataArr;
    };

    try {
        if (isCajuiaContext) {
            // Cajuia/Santos & Lopes: a venda real sincronizada fica em store_sales.
            // Os clientes, vendedores, valor da venda e itens vendidos vêm dessa tabela.
            const cajuiaSales = await fetchPaged('store_sales', (from, to) => supabase
                .from('store_sales')
                .select('id, order_number, customer_name, total_value, net_value, date_sale, created_at, status, seller_name, items, company_id')
                .eq('company_id', targetCompanyId)
                .gte('date_sale', start)
                .lte('date_sale', end)
                .order('date_sale', { ascending: false })
                .range(from, to)
            );

            const validSales = cajuiaSales.filter((sale: any) => {
                const status = String(sale.status || '').toLowerCase();
                return !status.includes('cancel');
            });

            validSales.forEach((sale: any) => {
                const value = getSaleAmount(sale);
                const customerName = sale.customer_name || 'Cliente não informado';
                const sellerName = sale.seller_name || 'Vendedor não informado';

                tenantMetrics.salesCount += 1;
                addMoneyRank(customers, customerName, value);
                addMoneyRank(sellers, sellerName, value);

                const items = extractSaleItems(sale);
                items.forEach((item: any) => {
                    const productName = getItemName(item);
                    if (!productName) return;

                    // Em store_sales.items, muitas vendas antigas vêm sem campo de quantidade.
                    // Quando existe item com nome real, pelo menos 1 unidade foi vendida naquela venda.
                    // Se houver quantidade explícita, usamos ela; se não houver, contamos 1.
                    const qty = getItemQuantity(item, 1);
                    const itemValue = getItemValue(item, sale, qty, items.length);

                    if (qty <= 0 && itemValue <= 0) return;

                    tenantMetrics.piecesSold += qty;
                    addProductRank(productName, qty, itemValue);
                });
            });
        } else {
            // Fonte principal do MR Jacky: orders + order_items.
            // O dump mostra que order_items possui fabric_type e quantity_meters/billed_quantity,
            // então é essa tabela que detalha tecidos e metragem vendida corretamente.
            const mjOrders = await fetchPaged('orders', (from, to) => supabase
                .from('orders')
                .select('id, order_number, customer_name, total_value, quantity_meters, created_at, status, company_id, created_by')
                .eq('company_id', targetCompanyId)
                .gte('created_at', `${start}T00:00:00`)
                .lte('created_at', `${end}T23:59:59`)
                .order('created_at', { ascending: false })
                .range(from, to)
            );

            const validOrders = mjOrders.filter((order: any) => {
                const status = String(order.status || '').toLowerCase();
                return !status.includes('cancel');
            });

            const orderIds = validOrders.map((o: any) => o.id).filter(Boolean);
            let orderItems: any[] = [];

            for (let i = 0; i < orderIds.length; i += 800) {
                const chunk = orderIds.slice(i, i + 800);
                const { data, error } = await supabase
                    .from('order_items')
                    .select('order_id, fabric_type, quantity_meters, billed_quantity, quantity_unit, total_value_items')
                    .in('order_id', chunk)
                    .neq('excluded_from_invoice', true);
                if (error) throw error;
                orderItems = orderItems.concat(data || []);
            }

            const sellerIds = Array.from(new Set(validOrders.map((o: any) => o.created_by).filter(Boolean)));
            const sellerNameById = new Map<string, string>();

            if (sellerIds.length > 0) {
                const { data: profiles } = await supabase
                    .from('profiles')
                    .select('id, full_name, username, email')
                    .in('id', sellerIds);

                (profiles || []).forEach((p: any) => {
                    sellerNameById.set(p.id, p.full_name || p.username || p.email || 'Vendedor não informado');
                });
            }

            const itemsByOrder = new Map<string, any[]>();
            orderItems.forEach((item: any) => {
                const list = itemsByOrder.get(item.order_id) || [];
                list.push(item);
                itemsByOrder.set(item.order_id, list);
            });

            validOrders.forEach((order: any) => {
                const value = Number(order.total_value || 0);
                const customerName = order.customer_name || 'Cliente não informado';
                const sellerName = sellerNameById.get(order.created_by) || 'Vendedor não informado';
                const items = itemsByOrder.get(order.id) || [];

                tenantMetrics.salesCount += 1;
                addMoneyRank(customers, customerName, value);
                addMoneyRank(sellers, sellerName, value);

                if (items.length > 0) {
                    items.forEach((item: any) => {
                        const meters = Number(item.billed_quantity ?? item.quantity_meters ?? item.quantity_unit ?? 0);
                        const itemValue = Number(item.total_value_items || 0);
                        tenantMetrics.metersSold += meters;
                        addProductRank(item.fabric_type || 'Tecido não informado', meters, itemValue);
                    });
                } else {
                    const meters = Number(order.quantity_meters || 0);
                    tenantMetrics.metersSold += meters;
                    addProductRank('Tecido não detalhado', meters, value);
                }
            });
        }

        tenantTopCustomers.value = Array.from(customers.values()).sort((a, b) => b.total - a.total);
        tenantTopProducts.value = Array.from(products.values()).sort((a, b) => (b.quantity - a.quantity) || (b.total - a.total));
        tenantTopSellers.value = Array.from(sellers.values()).sort((a, b) => b.total - a.total);
    } catch (error) {
        console.error('Erro ao carregar rankings do tenant:', error);
    }
};

const fetchFinanceDataSafely = async (table: string, start: string, end: string) => {
    let dataArr: any[] = [];
    let from = 0; const step = 999; let hasMore = true;

    const selectQuery = table === 'finance_receivables'
        ? '*, orders!left(id, order_number, store_id, stores(name))'
        : '*';

    while(hasMore) {
        const { data, error } = await supabase.from(table).select(selectQuery)
            .gte('due_date', start).lte('due_date', end).range(from, from + step);
        if (error) { console.error(error); break; }
        if (data && data.length > 0) {
            dataArr = dataArr.concat(data);
            if (data.length <= step) hasMore = false; else from += step + 1;
        } else hasMore = false;
    }
    return dataArr;
};

const fetchSignalsSafely = async (start: string, end: string) => {
    let dataArr: any[] = [];
    let from = 0; const step = 999; let hasMore = true;
    while(hasMore) {
        const { data, error } = await supabase.from('order_payments').select('*, orders!left(order_number, customer_name, store_id, stores(name))')
            .gte('payment_date', start).lte('payment_date', end).range(from, from + step);
        if (error) { console.error(error); break; }
        if (data && data.length > 0) {
            dataArr = dataArr.concat(data);
            if (data.length <= step) hasMore = false; else from += step + 1;
        } else hasMore = false;
    }
    return dataArr;
};

const getFilialName = (item: any) => {
    if (!item.company_id) return 'NÃO VINCULADOS';

    if (item.company_id === cjCompanyId.value || (item.entity_name && item.entity_name.toUpperCase().includes('CAJUIA'))) {
        return shortNameRetail.value;
    }

    const orderStoreName = item.orders?.stores?.name || '';
    const strMatch = `${orderStoreName} ${item.store_name || ''} ${item.unidade || ''} ${item.description || ''} ${item.notes || ''} ${item.entity_name || ''}`.toUpperCase();

    if (
        strMatch.includes('FILIAL - PE') ||
        strMatch.includes('FILIAL PE') ||
        strMatch.includes('PERNAMBUCO') ||
        strMatch.includes('PE ') ||
        strMatch.includes('LOJA FE') ||
        strMatch.includes('LOJA - FE') ||
        strMatch.includes('FE ')
    ) {
        return companyStore.isDemoMode ? 'FILIAL FICTÍCIA - PE' : 'FILIAL - PE';
    }

    return companyStore.isDemoMode ? 'MATRIZ FICTÍCIA' : 'MATRIZ - SP';
};

const calculateTotals = (items: any[], companyId: string | null | 'unlinked') => {
    const filtered = companyId === 'unlinked'
        ? items.filter(i => !i.company_id)
        : (companyId ? items.filter(i => i.company_id === companyId) : items);

    let total = 0;
    let paid = 0;

    filtered.forEach(i => {
        const val = Number(i.value) - Number(i.discount || 0);
        total += val;
        const isPaid = ['paid', 'pago', 'received'].includes(i.status?.toLowerCase());
        if (isPaid) {
            paid += val;
        }
    });

    // Usa Number(..toFixed(2)) para evitar bugs malucos de ponto flutuante do JavaScript
    return { total, paid, missing: Math.max(0, Number((total - paid).toFixed(2))) };
};


// =========================================================
// LOOP PRINCIPAL DE CARREGAMENTO
// =========================================================
const fetchHoldingData = async () => {
  isLoading.value = true;

  const today = new Date();
  const todayStr = format(today, 'yyyy-MM-dd');

  // ===============================================
  // INTERCEPTADOR DE MODO DEMO GLOBAL
  // ===============================================
  if (companyStore.isDemoMode) {
      const isTodayFilter = globalFilter.value === 'today';

      mjPayablesTotal.value = isTodayFilter ? 20000 : 185000;
      mjExecution.paid = isTodayFilter ? 7600 : 145000;
      mjExecution.missingPay = isTodayFilter ? 12400 : 40000;

      mjReceivablesTotal.value = isTodayFilter ? 35000 : 420000;
      mjExecution.received = isTodayFilter ? 10000 : 310000;
      mjExecution.missingRec = isTodayFilter ? 25000 : 110000;

      cajuiaPayablesTotal.value = isTodayFilter ? 8000 : 65000;
      cajuiaExecution.paid = isTodayFilter ? 4500 : 50000;
      cajuiaExecution.missingPay = isTodayFilter ? 3500 : 15000;

      cajuiaReceivablesTotal.value = isTodayFilter ? 18000 : 180000;
      cajuiaExecution.received = isTodayFilter ? 6000 : 150000;
      cajuiaExecution.missingRec = isTodayFilter ? 12000 : 30000;

      unlinkedPayablesTotal.value = isTodayFilter ? 1500 : 15000;
      unlinkedExecution.paid = isTodayFilter ? 500 : 5000;
      unlinkedExecution.missingPay = isTodayFilter ? 1000 : 10000;

      unlinkedReceivablesTotal.value = isTodayFilter ? 2500 : 25000;
      unlinkedExecution.received = isTodayFilter ? 1000 : 10000;
      unlinkedExecution.missingRec = isTodayFilter ? 1500 : 15000;

      cajuiaMonthlySalesCount.value = 642;
      cajuiaMonthlyPiecesCount.value = 1840;
      monthlyProduction.value = { totalMeters: 45000 };

      displayedExtraCompanies.value = activeExtraCompanyIds.value.map((id, index) => {
          const basePay = isTodayFilter ? 2000 * (index + 1) : 20000 * (index + 1);
          const baseRec = isTodayFilter ? 4000 * (index + 1) : 40000 * (index + 1);
          return {
              id,
              name: `Empresa Fictícia ${index + 1}`,
              payablesTotal: basePay,
              receivablesTotal: baseRec,
              execution: { paid: basePay * 0.7, missingPay: basePay * 0.3, received: baseRec * 0.8, missingRec: baseRec * 0.2 }
          };
      });

      realBanks.value = [
          { id: '1', name: 'Conta Principal Fictícia', bank_name: 'Banco Fictício 1', current_balance: 1250430.50, in_flow: 450000, out_flow: 180000 },
          { id: '2', name: 'Caixa Secundário', bank_name: 'Banco Fictício 2', current_balance: 85000.00, in_flow: 15000, out_flow: 2500 },
      ];

      const demoStoreSummaries = [
          { name: 'MATRIZ FICTÍCIA', receitas: 320000, metragem: 35000, unidades: 0 },
          { name: 'FILIAL FICTÍCIA - PE', receitas: 100000, metragem: 10000, unidades: 0 },
          { name: shortNameRetail.value, receitas: 180000, metragem: 0, unidades: 642 },
          { name: 'NÃO VINCULADOS', receitas: 25000, metragem: 0, unidades: 0 }
      ];

      displayedExtraCompanies.value.forEach(comp => {
          demoStoreSummaries.push({
              name: comp.name.toUpperCase(),
              receitas: comp.receivablesTotal,
              metragem: 0,
              unidades: Math.floor(comp.receivablesTotal / 100)
          });
      });

      storeSummaries.value = demoStoreSummaries;

      const baseDemoGrid = [
          { type: 'receivable', filial: 'MATRIZ FICTÍCIA', due_date: todayStr, entity_name: 'Cliente Corporativo Fictício', description: 'Venda de Malhas', value: 15000, status: 'pendente' },
          { type: 'payable', filial: shortNameRetail.value, due_date: todayStr, entity_name: 'Fornecedor Fictício Beta', description: 'Insumos de Loja', value: 3500, status: 'pendente' },
          { type: 'receivable', filial: 'FILIAL FICTÍCIA - PE', due_date: todayStr, entity_name: 'Moda Praia Fictícia', description: 'Varejo', value: 4500, status: 'pago' },
          { type: 'payable', filial: 'MATRIZ FICTÍCIA', due_date: todayStr, entity_name: 'Companhia de Energia', description: 'Conta de Luz', value: 12000, status: 'pendente' },
          { type: 'payable', filial: 'NÃO VINCULADOS', due_date: todayStr, entity_name: 'Avulso', description: 'Despesa Genérica', value: 500, status: 'pago' }
      ];

      displayedExtraCompanies.value.forEach(comp => {
          baseDemoGrid.push(
              { type: 'receivable', filial: comp.name.toUpperCase(), due_date: todayStr, entity_name: `Cliente Base ${comp.name}`, description: 'Faturamento', value: 9000, status: 'pendente' },
              { type: 'payable', filial: comp.name.toUpperCase(), due_date: todayStr, entity_name: `Fornecedor ${comp.name}`, description: 'Material', value: 1500, status: 'pago' }
          );
      });

      allProjectionItems.value = baseDemoGrid;

      mjChartData.value = {
          labels: ['Sem 1', 'Sem 2', 'Sem 3', 'Sem 4'],
          datasets: [
             { label: 'Entradas', data: [80000, 120000, 90000, 130000], backgroundColor: '#4CAF50', barPercentage: 0.6, borderRadius: 4 },
             { label: 'Saídas', data: [40000, 60000, 35000, 50000], backgroundColor: '#EF5350', barPercentage: 0.6, borderRadius: 4 }
          ]
      };
      cajuiaChartData.value = {
          labels: ['Sem 1', 'Sem 2', 'Sem 3', 'Sem 4'],
          datasets: [
             { label: 'Entradas', data: [30000, 50000, 45000, 55000], backgroundColor: '#FF9800', barPercentage: 0.6, borderRadius: 4 },
             { label: 'Saídas', data: [15000, 20000, 10000, 20000], backgroundColor: '#D32F2F', barPercentage: 0.6, borderRadius: 4 }
          ]
      };

      if (selectedStores.value.length === 0) selectedStores.value = storeSummaries.value.map(s => s.name);
      gridPage.value = 1;
      isLoading.value = false;
      return;
  }
  // ===============================================

  await dashboardStore.fetchData();
  if (companyList.value.length === 0) await fetchCompanies();
  normalizeTenantFromCompanyContext();

  let startTop = format(startOfMonth(today), 'yyyy-MM-dd');
  let endTop = format(endOfMonth(today), 'yyyy-MM-dd');

  if (globalFilter.value === 'today') {
     startTop = format(today, 'yyyy-MM-dd'); endTop = format(today, 'yyyy-MM-dd');
  } else if (globalFilter.value === 'year') {
     startTop = format(startOfYear(today), 'yyyy-MM-dd'); endTop = format(endOfYear(today), 'yyyy-MM-dd');
  } else if (globalFilter.value === 'custom') {
     startTop = customStartDate.value; endTop = customEndDate.value;
  }

  const mjChartRange = { start: format(startOfMonth(today), 'yyyy-MM-dd'), end: format(endOfMonth(today), 'yyyy-MM-dd') };
  const cajuiaChartRange = { start: format(startOfMonth(today), 'yyyy-MM-dd'), end: format(endOfMonth(today), 'yyyy-MM-dd') };

  let storeStart = format(startOfMonth(today), 'yyyy-MM-dd');
  let storeEnd = format(endOfMonth(today), 'yyyy-MM-dd');

  if (storeFilterPeriod.value === 'day') {
     storeStart = format(today, 'yyyy-MM-dd'); storeEnd = format(today, 'yyyy-MM-dd');
  } else if (storeFilterPeriod.value === 'year') {
     storeStart = format(startOfYear(today), 'yyyy-MM-dd'); storeEnd = format(endOfYear(today), 'yyyy-MM-dd');
  }

  if(chartFilterMJ.value === 'year') { mjChartRange.start = format(startOfYear(today), 'yyyy-MM-dd'); mjChartRange.end = format(endOfYear(today), 'yyyy-MM-dd'); }
  else if(chartFilterMJ.value === 'day') { mjChartRange.start = startTop; mjChartRange.end = endTop; }

  if(chartFilterCajuia.value === 'year') { cajuiaChartRange.start = format(startOfYear(today), 'yyyy-MM-dd'); cajuiaChartRange.end = format(endOfYear(today), 'yyyy-MM-dd'); }
  else if(chartFilterCajuia.value === 'day') { cajuiaChartRange.start = startTop; cajuiaChartRange.end = endTop; }

  try {
    const { data: accounts } = await supabase.from('finance_accounts').select('*').eq('is_active', true);
    if(accounts) { realBanks.value = accounts; }

    const minStart = [startTop, mjChartRange.start, cajuiaChartRange.start, storeStart].sort()[0];
    const maxEnd = [endTop, mjChartRange.end, cajuiaChartRange.end, storeEnd].sort().reverse()[0];

    const allRecsRaw = await fetchFinanceDataSafely('finance_receivables', minStart, maxEnd);
    const allPaysRaw = await fetchFinanceDataSafely('finance_payables', minStart, maxEnd);
    const signalsRaw = await fetchSignalsSafely(minStart, maxEnd);

    const signalsMapped = signalsRaw.map((s: any) => ({
        id: s.id,
        is_signal: true,
        description: `Sinal Pedido #${s.orders?.order_number || 'S/N'}`,
        value: s.amount,
        discount: 0,
        due_date: s.payment_date,
        payment_date: s.payment_date,
        status: 'pago',
        company_id: mjCompanyId.value,
        orders: s.orders,
        entity_name: s.orders?.customer_name || 'Cliente de Varejo (Sinal)',
        type: 'receivable'
    }));

    const cardRecsAll = [...allRecsRaw, ...signalsMapped];
    const cardPaysAll = allPaysRaw;

    const dashboardRecs = cardRecsAll.filter(i => filterByDateExact(i, startTop, endTop));
    const dashboardPays = cardPaysAll.filter(i => filterByDateExact(i, startTop, endTop));

    const storeRecs = cardRecsAll.filter(i => filterByDateExact(i, storeStart, storeEnd));
    const storePays = cardPaysAll.filter(i => filterByDateExact(i, storeStart, storeEnd));

    // Cálculos Exatos MJ
    const mjRecStats = calculateTotals(dashboardRecs, mjCompanyId.value);
    mjReceivablesTotal.value = mjRecStats.total;
    mjExecution.received = mjRecStats.paid;
    mjExecution.missingRec = mjRecStats.missing;

    const mjPayStats = calculateTotals(dashboardPays, mjCompanyId.value);
    mjPayablesTotal.value = mjPayStats.total;
    mjExecution.paid = mjPayStats.paid;
    mjExecution.missingPay = mjPayStats.missing;

    // Cálculos Exatos CAJUIA
    const cjRecStats = calculateTotals(dashboardRecs, cjCompanyId.value);
    cajuiaReceivablesTotal.value = cjRecStats.total;
    cajuiaExecution.received = cjRecStats.paid;
    cajuiaExecution.missingRec = cjRecStats.missing;

    const cjPayStats = calculateTotals(dashboardPays, cjCompanyId.value);
    cajuiaPayablesTotal.value = cjPayStats.total;
    cajuiaExecution.paid = cjPayStats.paid;
    cajuiaExecution.missingPay = cjPayStats.missing;

    // Cálculos Exatos UNLINKED
    const unlinkedRecStats = calculateTotals(dashboardRecs, 'unlinked');
    unlinkedReceivablesTotal.value = unlinkedRecStats.total;
    unlinkedExecution.received = unlinkedRecStats.paid;
    unlinkedExecution.missingRec = unlinkedRecStats.missing;

    const unlinkedPayStats = calculateTotals(dashboardPays, 'unlinked');
    unlinkedPayablesTotal.value = unlinkedPayStats.total;
    unlinkedExecution.paid = unlinkedPayStats.paid;
    unlinkedExecution.missingPay = unlinkedPayStats.missing;

    cajuiaMonthlySalesCount.value = dashboardRecs.filter(r => r.company_id === cjCompanyId.value).length;
    await fetchCajuiaStoreSalesSummary(startTop, endTop);

    // Lojas (Filiais)
    const newStoreSummaries: any[] = [];
    let globalProjectionList: any[] = [];

    let mjOrders: any[] = [];
    try {
        const { data: ordersData } = await supabase
            .from('orders')
            .select('id, total_value, quantity_meters, store:store_id(name)')
            .gte('created_at', `${storeStart}T00:00:00`)
            .lte('created_at', `${storeEnd}T23:59:59`)
            .neq('status', 'cancelled');
        if (ordersData) mjOrders = ordersData;
    } catch (e) {}

    const processIndustryStore = (keywords: string[], cardName: string) => {
        const ordersForStore = mjOrders.filter(o => {
            const sName = (o.store?.name || '').toUpperCase();
            if (keywords.includes('MATRIZ') && (sName === '' || sName.includes('MATRIZ'))) return true;
            return keywords.some(k => sName.includes(k));
        });

        const met = ordersForStore.reduce((sum, o) => sum + (Number(o.quantity_meters) || 0), 0);

        const r = storeRecs.filter(x => getFilialName(x) === cardName);
        const p = storePays.filter(x => getFilialName(x) === cardName);

        const recTotal = r.reduce((sum, val) => sum + (Number(val.value) - Number(val.discount||0)), 0);
        newStoreSummaries.push({ name: cardName, receitas: recTotal, metragem: met, unidades: 0 });

        r.forEach(i => globalProjectionList.push({ ...i, type: 'receivable', filial: cardName }));
        p.forEach(i => globalProjectionList.push({ ...i, type: 'payable', filial: cardName }));
    };

    processIndustryStore(['MATRIZ', 'SP'], 'MATRIZ - SP');
    processIndustryStore(['FILIAL', 'PE', 'PERNAMBUCO'], 'FILIAL - PE');

    const rCajuia = storeRecs.filter(x => getFilialName(x) === shortNameRetail.value);
    const pCajuia = storePays.filter(x => getFilialName(x) === shortNameRetail.value);

    const recTotalCajuia = rCajuia.reduce((sum, val) => sum + (Number(val.value) - Number(val.discount||0)), 0);
    newStoreSummaries.push({ name: shortNameRetail.value, receitas: recTotalCajuia, metragem: 0, unidades: rCajuia.length });

    rCajuia.forEach(i => globalProjectionList.push({ ...i, type: 'receivable', filial: shortNameRetail.value }));
    pCajuia.forEach(i => globalProjectionList.push({ ...i, type: 'payable', filial: shortNameRetail.value }));

    const rUnlinked = storeRecs.filter(x => !x.company_id);
    const pUnlinked = storePays.filter(x => !x.company_id);
    const recTotalUnlinked = rUnlinked.reduce((sum, val) => sum + (Number(val.value) - Number(val.discount||0)), 0);
    newStoreSummaries.push({ name: 'NÃO VINCULADOS', receitas: recTotalUnlinked, metragem: 0, unidades: 0 });

    rUnlinked.forEach(i => globalProjectionList.push({ ...i, type: 'receivable', filial: 'NÃO VINCULADOS' }));
    pUnlinked.forEach(i => globalProjectionList.push({ ...i, type: 'payable', filial: 'NÃO VINCULADOS' }));

    // ==============================================
    // PROCESSAMENTO DE EMPRESAS EXTRAS DO MODO NORMAL
    // ==============================================
    displayedExtraCompanies.value = [];
    for (const compId of activeExtraCompanyIds.value) {
        const compObj = companyList.value.find(c => c.id === compId);
        if (!compObj) continue;
        const compName = compObj.trade_name || compObj.name || 'Empresa Extra';

        const cStatsRec = calculateTotals(dashboardRecs, compId);
        const cStatsPay = calculateTotals(dashboardPays, compId);

        displayedExtraCompanies.value.push({
            id: compId,
            name: compName,
            payablesTotal: cStatsPay.total,
            receivablesTotal: cStatsRec.total,
            execution: {
                paid: cStatsPay.paid,
                missingPay: cStatsPay.missing,
                received: cStatsRec.paid,
                missingRec: cStatsRec.missing
            }
        });

        newStoreSummaries.push({ name: compName.toUpperCase(), receitas: cStatsRec.total, metragem: 0, unidades: dashboardRecs.filter(r => r.company_id === compId).length });

        dashboardRecs.filter(r => r.company_id === compId).forEach(i => globalProjectionList.push({ ...i, type: 'receivable', filial: compName.toUpperCase() }));
        dashboardPays.filter(p => p.company_id === compId).forEach(i => globalProjectionList.push({ ...i, type: 'payable', filial: compName.toUpperCase() }));
    }

    const mjStoreNames = new Set([companyStore.isDemoMode ? 'MATRIZ FICTÍCIA' : 'MATRIZ - SP', companyStore.isDemoMode ? 'FILIAL FICTÍCIA - PE' : 'FILIAL - PE']);
    const cajuiaStoreName = shortNameRetail.value;

    if (currentContext.value === 'mj') {
        storeSummaries.value = newStoreSummaries.filter(s => mjStoreNames.has(s.name));
        globalProjectionList = globalProjectionList.filter(i => mjStoreNames.has(i.filial));
        selectedStores.value = storeSummaries.value.map(s => s.name);
    } else if (currentContext.value === 'cajuia') {
        storeSummaries.value = newStoreSummaries.filter(s => s.name === cajuiaStoreName);
        globalProjectionList = globalProjectionList.filter(i => i.filial === cajuiaStoreName);
        selectedStores.value = storeSummaries.value.map(s => s.name);
    } else {
        storeSummaries.value = newStoreSummaries;
        selectedStores.value = selectedStores.value.filter(name => storeSummaries.value.some(s => s.name === name));
        if (selectedStores.value.length === 0) {
            selectedStores.value = storeSummaries.value.map(s => s.name);
        }
    }

    allProjectionItems.value = globalProjectionList.sort((a, b) => {
        const dateA = new Date(a.due_date).getTime();
        const dateB = new Date(b.due_date).getTime();
        return dateB - dateA;
    });

    const recMjChart = cardRecsAll.filter(r => r.company_id === mjCompanyId.value && filterByDateExact(r, mjChartRange.start, mjChartRange.end));
    const payMjChart = cardPaysAll.filter(p => p.company_id === mjCompanyId.value && filterByDateExact(p, mjChartRange.start, mjChartRange.end));
    const recCjChart = cardRecsAll.filter(r => r.company_id === cjCompanyId.value && filterByDateExact(r, cajuiaChartRange.start, cajuiaChartRange.end));
    const payCjChart = cardPaysAll.filter(p => p.company_id === cjCompanyId.value && filterByDateExact(p, cajuiaChartRange.start, cajuiaChartRange.end));

    const mjRecBucket = bucketData(recMjChart, chartFilterMJ.value); const mjPayBucket = bucketData(payMjChart, chartFilterMJ.value);
    mjChartData.value = { labels: mjRecBucket.labels, datasets: [ { label: 'Entradas', data: mjRecBucket.values, backgroundColor: '#4CAF50', barPercentage: 0.6, borderRadius: 4 }, { label: 'Saídas', data: mjPayBucket.values, backgroundColor: '#EF5350', barPercentage: 0.6, borderRadius: 4 } ] };
    const cjRecBucket = bucketData(recCjChart, chartFilterCajuia.value); const cjPayBucket = bucketData(payCjChart, chartFilterCajuia.value);
    cajuiaChartData.value = { labels: cjRecBucket.labels, datasets: [ { label: 'Entradas', data: cjRecBucket.values, backgroundColor: '#FF9800', barPercentage: 0.6, borderRadius: 4 }, { label: 'Saídas', data: cjPayBucket.values, backgroundColor: '#D32F2F', barPercentage: 0.6, borderRadius: 4 } ] };

    await fetchTenantRankings(startTop, endTop);

  } catch (error) { console.warn("Erro ao carregar dados Holding:", error); } finally { isLoading.value = false; }
};

const refreshData = async () => { await fetchHoldingData(); };

const chartTextColor = computed(() => themeStore.currentMode === 'light' ? '#424242' : '#e0e0e0');
const chartGridColor = computed(() => themeStore.currentMode === 'light' ? 'rgba(0,0,0,0.05)' : 'rgba(255,255,255,0.05)');
const richChartOptions = computed(() => ({ responsive: true, maintainAspectRatio: false, plugins: { legend: { display: false }, tooltip: { backgroundColor: themeStore.currentMode === 'light' ? 'rgba(255,255,255,0.95)' : 'rgba(20, 20, 25, 0.95)', titleColor: themeStore.currentMode === 'light' ? '#000' : '#fff', bodyColor: themeStore.currentMode === 'light' ? '#333' : '#e0e0e0', borderColor: themeStore.currentMode === 'light' ? 'rgba(0,0,0,0.1)' : 'rgba(255,255,255,0.1)', borderWidth: 1, padding: 12, callbacks: { label: function(context: any) { let label = context.dataset.label || ''; if (label) label += ': '; if (context.parsed.y !== null) { label += new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(context.parsed.y); } return label; } } } }, scales: { x: { grid: { display: false }, ticks: { color: chartTextColor.value, font: { size: 10 } } }, y: { grid: { color: chartGridColor.value, borderDash: [4, 4] }, ticks: { display: false } } } }));
const miniChartOptions = computed(() => ({ responsive: true, maintainAspectRatio: false, cutout: '85%', plugins: { legend: { display: false }, tooltip: { enabled: false } }, elements: { arc: { borderWidth: 0 } } }));

const formatNumber = (val: number) => Number(val).toLocaleString('pt-BR');
const formatCurrency = (val: number) => new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(val);
const formatCurrencyNoSymbol = (val: number) => new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(val).replace('R$', '').trim();
const formatDateSimple = (date: string) => {
    if (!date) return '-';
    try { return format(parseISO(date), 'dd/MM/yyyy'); } catch(e) { return date; }
};

const zebraClass = (i:number) => themeStore.currentMode!=='light' ? (i%2===0?'zebra-dark-a':'zebra-dark-b') : (i%2===0?'zebra-light-a':'zebra-light-b');
const getStatusLabelDash = (i:any) => ['paid','pago','received'].includes(i.status?.toLowerCase()) ? 'Liquidado' : (isPast(parseISO(i.due_date)) && !isToday(parseISO(i.due_date)) ? 'Atrasado' : 'Pendente');
const getStatusColorDash = (i:any) => { const s = i.status?.toLowerCase(); if (['paid','pago','received'].includes(s)) return 'green-darken-2'; if (isPast(parseISO(i.due_date)) && !isToday(parseISO(i.due_date))) return 'red-darken-2'; return 'orange-darken-2'; };
const getDueDateColorText = (dStr: string, status: string) => { if (['paid','pago','received'].includes(status?.toLowerCase())) return 'text-grey opacity-60'; const d = parseISO(dStr); if (isPast(d) && !isToday(d)) return 'text-red-darken-2'; if (isToday(d)) return 'text-orange-darken-2'; return themeStore.currentMode === 'light' ? 'text-grey-darken-3' : 'text-white'; };
const getBankColor = (bankName: string) => { const name = bankName?.toLowerCase() || ''; if(name.includes('itaú') || name.includes('itau')) return 'orange-darken-2'; if(name.includes('santander') || name.includes('bradesco')) return 'red-darken-2'; if(name.includes('brasil')) return 'yellow-darken-3'; if(name.includes('nubank')) return 'purple-darken-2'; if(name.includes('sicredi') || name.includes('green')) return 'green-darken-2'; if(name.includes('cora')) return 'pink-accent-3'; return 'blue-grey'; };

const currentTime = ref(''); const currentDate = ref(''); const lastSyncTime = ref(''); let clockInterval: NodeJS.Timeout;
const updateClock = () => { const now = new Date(); currentTime.value = format(now, 'HH:mm:ss'); currentDate.value = format(now, "EEE, d MMM yyyy", { locale: ptBR }); };

watch(() => companyStore.context, () => {
  normalizeTenantFromCompanyContext();
  fetchHoldingData();
});

onActivated(() => { normalizeTenantFromCompanyContext(); fetchHoldingData(); updateClock(); });
onMounted(async () => {
    handleContextIslandScroll();
    window.addEventListener('scroll', handleContextIslandScroll, { passive: true });
  updateClock();
  clockInterval = setInterval(updateClock, 1000);
  if (companyStore.availableCompanies.length === 0) await companyStore.loadCompanies();
  await fetchHoldingData();
});
onUnmounted(() => clearInterval(clockInterval));


onBeforeUnmount(() => {
    window.removeEventListener('scroll', handleContextIslandScroll);
});

</script>

<style scoped lang="scss">
.animate-fade-in-down { animation: fadeInDown 0.7s cubic-bezier(0.2, 0.8, 0.2, 1); }
.animate-fade-in-up { animation: fadeInUp 0.7s cubic-bezier(0.2, 0.8, 0.2, 1) backwards; }
@keyframes fadeInDown { from { opacity: 0; transform: translateY(-30px); } to { opacity: 1; transform: translateY(0); } }
@keyframes fadeInUp { from { opacity: 0; transform: translateY(30px); } to { opacity: 1; transform: translateY(0); } }
.blink { animation: blink 2s infinite; }
@keyframes blink { 0% { opacity: 1; } 50% { opacity: 0.4; } 100% { opacity: 1; } }
.wave-hand { display: inline-block; animation: wave 2.5s infinite; transform-origin: 70% 70%; }
@keyframes wave { 0% { transform: rotate(0deg); } 10% { transform: rotate(14deg); } 20% { transform: rotate(-8deg); } 30% { transform: rotate(14deg); } 40% { transform: rotate(-4deg); } 50% { transform: rotate(10deg); } 60% { transform: rotate(0deg); } 100% { transform: rotate(0deg); } }

/* ========================================================
   EFEITOS 3D E BORDAS / BUTTONS E CARDS
   ======================================================== */

.btn-3d {
    border-radius: 6px !important;
    box-shadow: 0 3px 5px rgba(0,0,0,0.15), inset 0 2px 0 rgba(255,255,255,0.25) !important;
    transition: transform 0.1s ease, box-shadow 0.1s ease;
    text-transform: none !important;
    font-weight: 700;
    letter-spacing: 0.5px;
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

.card-3d {
    border-radius: 12px !important;
    box-shadow: 0 6px 12px rgba(0,0,0,0.15), inset 0 2px 0 rgba(255,255,255,0.2) !important;
    transition: transform 0.2s ease, box-shadow 0.2s ease;
}

/* Auxiliares de 3D */
.square-btn { width: 32px !important; height: 32px !important; min-width: 32px !important; padding: 0 !important; }
.ui-field :deep(.v-field) { border-radius: 8px !important; }

/* Panels and Colors */
.glass-card { background: rgba(30, 30, 35, 0.85); backdrop-filter: blur(25px); color: white; }
.glass-panel { background: rgba(30, 30, 35, 0.6); backdrop-filter: blur(20px); border: 1px solid rgba(255, 255, 255, 0.08); box-shadow: 0 8px 32px rgba(0,0,0,0.3); }
.light-panel { background: #FFFFFF; border: 1px solid #E0E0E0; box-shadow: 0 4px 12px rgba(0,0,0,0.05); }

.bg-gradient-primary { background: linear-gradient(135deg, #1976d2, #0d47a1); }
.bg-gradient-purple { background: linear-gradient(135deg, #7b1fa2, #4a148c); }
.bg-gradient-deep-purple { background: linear-gradient(135deg, #512DA8, #311B92); }
.bg-gradient-indigo { background: linear-gradient(135deg, #303F9F, #1A237E); }
.bg-gradient-orange { background: linear-gradient(135deg, #f57c00, #e65100); }
.bg-gradient-red { background: linear-gradient(135deg, #ff5252, #d32f2f); }
.bg-gradient-green { background: linear-gradient(135deg, #388E3C, #1B5E20); }
.bg-gradient-blue { background: linear-gradient(135deg, #1976D2, #0288D1); }
.bg-gradient-cyan { background: linear-gradient(135deg, #0097A7, #006064); }
.bg-gradient-teal { background: linear-gradient(135deg, #00796B, #004D40); }
.bg-gradient-blue-grey { background: linear-gradient(135deg, #455A64, #263238); }
.bg-gradient-grey { background: linear-gradient(135deg, #9E9E9E, #616161); }
.bg-gradient-grey-light { background: linear-gradient(135deg, #BDBDBD, #757575); }
.bg-gradient-grey-dark { background: linear-gradient(135deg, #616161, #424242); }


/* KPI Cards Específicos */
.kpi-card-3d {
    height: 160px;
    border-radius: 12px !important;
    padding: 16px;
    position: relative;
    overflow: hidden;
    border: 1px solid rgba(255,255,255,0.1);
    cursor: pointer;
    color: white;
    display: flex;
    flex-direction: column;
    box-shadow: 0 6px 12px rgba(0,0,0,0.2), inset 0 2px 0 rgba(255,255,255,0.3) !important;
    transition: transform 0.2s ease, box-shadow 0.2s ease, filter 0.2s ease;
}
.kpi-card-3d:hover {
    transform: translateY(-4px);
    box-shadow: 0 12px 24px rgba(0,0,0,0.3), inset 0 2px 0 rgba(255,255,255,0.4) !important;
    filter: brightness(1.05);
    z-index: 2;
}

.kpi-bg-icon { position: absolute; right: -25px; bottom: -25px; opacity: 0.2; transform: rotate(0deg); pointer-events: none; }
.kpi-bg-icon .v-icon { font-size: 130px; color: white; }
.kpi-label { font-size: 14px !important; font-weight: 800; text-transform: uppercase; letter-spacing: 1px; }
.kpi-value { font-weight: 900; line-height: 1; letter-spacing: -1px; }
.kpi-footer { padding: 6px 10px; border-radius: 8px; display: inline-flex; align-items: center; width: fit-content; font-weight: 700; font-size: 12px !important; text-transform: uppercase; }
.bg-black-20 { background: rgba(0,0,0,0.25); }

/* ESTILIZAÇÕES DE LOJA ESTILO SALESAREA */
.hover-lift { transition: transform 0.3s ease, box-shadow 0.3s ease; }
.hover-lift:hover { transform: translateY(-3px); box-shadow: 0 12px 24px rgba(0,0,0,0.25), inset 0 2px 0 rgba(255,255,255,0.3) !important; }
.ring-active { border: 2px solid #4CAF50 !important; box-shadow: 0 0 0 2px rgba(76, 175, 80, 0.2); }
.grayscale { filter: grayscale(100%); opacity: 0.5; }
.excel-stat-row { display: flex; justify-content: space-between; align-items: center; }

/* Grid e Custom Scroll */
.grid-scroll { scrollbar-gutter: stable both-edges; -webkit-overflow-scrolling: touch; }
.custom-scroll::-webkit-scrollbar { width: 8px; height: 8px; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.35); border-radius: 6px; }
.custom-scroll::-webkit-scrollbar-track { background: transparent; }

.grid-header-dash, .grid-row-dash {
    display: grid;
    grid-template-columns: 50px 100px 100px minmax(150px, 1fr) minmax(180px, 1.5fr) 140px 120px;
    align-items: stretch;
    width: 100%;
    min-width: 900px;
}

.cell {
    padding: 8px 12px;
    display: flex;
    align-items: center;
    border-right: 1px solid rgba(0,0,0,0.08);
    border-bottom: 1px solid rgba(0,0,0,0.08);
    min-height: 54px;
    overflow: hidden;
}
.cell:last-child { border-right: none !important; }

.header-text { font-size: 14px !important; font-weight: 900; text-transform: uppercase; letter-spacing: 0.5px; line-height: 1.2; }
.center { justify-content: center; text-align: center; }
.list-text-11 { font-size: 14px !important; line-height: 1.3 !important; }

.grid-surface-light .cell { background: #f5f7fa; color: #555; border-color: rgba(0,0,0,0.06); }
.grid-surface-dark .cell { background: rgba(255,255,255,0.04); color: #ccc; border-color: rgba(255,255,255,0.05); }
.grid-row-light .cell { background: #fff; border-color: rgba(0,0,0,0.06); }
.grid-row-light:hover .cell { background: #f7fafc; }
.grid-row-dark .cell { background: rgba(255,255,255,0.02); border-color: rgba(255,255,255,0.05); }
.grid-row-dark:hover .cell { background: rgba(255,255,255,0.05); }
.zebra-light-a .cell { background: #fff; }
.zebra-light-b .cell { background: #fafafa; }
.zebra-dark-a .cell { background: rgba(255,255,255,0.01); }
.zebra-dark-b .cell { background: rgba(255,255,255,0.03); }

/* Auxiliares */
.icon-box-lg { width: 56px; height: 56px; }
.icon-box-sm { width: 32px; height: 32px; display: flex; align-items: center; justify-content: center; }
.font-mono { font-family: 'Roboto Mono', monospace; }

/* Fix Tooltips Contrast - Dark BG / White Text */
:global(.tooltip-contrast > .v-overlay__content) { background-color: rgba(33, 33, 33, 0.95) !important; color: #ffffff !important; font-size: 11px !important; font-weight: 700 !important; border-radius: 4px; border: 1px solid rgba(255,255,255,0.2); }


.bg-gradient-red {
  background: linear-gradient(135deg, #ef4444 0%, #b91c1c 100%) !important;
}

.bg-gradient-green {
  background: linear-gradient(135deg, #22c55e 0%, #15803d 100%) !important;
}

.bg-gradient-blue {
  background: linear-gradient(135deg, #2563eb 0%, #1e40af 100%) !important;
}


.analytics-chart-region {
  display: flex;
  width: 100%;
}

.analytics-chart-region--holding {
  height: 320px;
}

.analytics-chart-region--focused {
  height: 400px;
}

.chart-canvas-shell {
  width: 100%;
  height: 100%;
  min-height: 0;
}

.chart-canvas-shell--holding {
  height: 100%;
}

.chart-canvas-shell--focused {
  height: 100%;
}

.chart-canvas-shell canvas {
  width: 100% !important;
  height: 100% !important;
  display: block;
}

@media (max-width: 960px) {
  .executive-header {
    padding: 14px;
    border-radius: 18px;
  }

  .context-switcher {
    max-width: calc(100vw - 48px);
  }

  .dashboard-clock,
  .server-status-pill {
    display: none !important;
  }
}


.executive-header {
  position: relative;
  padding: 20px 22px;
  border-radius: 22px;
  overflow: hidden;
  border: 1px solid rgba(148, 163, 184, 0.22);
  transition: box-shadow 0.25s ease, transform 0.25s ease, background 0.25s ease;
}

.executive-header-light {
  background:
    linear-gradient(135deg, #ffffff 0%, #f8fafc 48%, #eef6ff 100%) !important;
  box-shadow:
    0 16px 38px rgba(15, 23, 42, 0.08),
    0 1px 0 rgba(255, 255, 255, 0.95) inset;
}

.executive-header-dark {
  background:
    linear-gradient(135deg, rgba(17, 24, 39, 0.90) 0%, rgba(30, 41, 59, 0.82) 56%, rgba(15, 23, 42, 0.92) 100%) !important;
  border-color: rgba(255, 255, 255, 0.08);
  box-shadow:
    0 18px 46px rgba(0, 0, 0, 0.24),
    0 1px 0 rgba(255,255,255,0.06) inset;
}

.executive-header::before {
  content: '';
  position: absolute;
  inset: 0;
  pointer-events: none;
  background:
    radial-gradient(circle at 4% 0%, rgba(59, 130, 246, 0.10), transparent 32%),
    radial-gradient(circle at 92% 8%, rgba(34, 197, 94, 0.10), transparent 28%);
}

.executive-header > * {
  position: relative;
  z-index: 1;
}

.dashboard-breadcrumb {
  color: #64748b;
  letter-spacing: 0.08em;
  font-size: 10px !important;
  text-transform: uppercase;
}

.executive-header-dark .dashboard-breadcrumb {
  color: rgba(226, 232, 240, 0.72);
}

.dashboard-title {
  font-size: clamp(1.45rem, 2.4vw, 2rem);
  line-height: 1.08;
  letter-spacing: -0.035em;
}

.text-slate-strong {
  color: #0f172a !important;
}

.context-switcher {
  gap: 10px;
  max-width: min(820px, calc(100vw - 430px));
}

.btn-context-3d {
  text-transform: uppercase;
  min-width: 0 !important;
  border: 1px solid rgba(148, 163, 184, 0.22) !important;
  transform: translateY(0);
  transition:
    transform 0.16s ease,
    box-shadow 0.16s ease,
    filter 0.16s ease,
    opacity 0.16s ease,
    background 0.16s ease;
}

.btn-context-idle {
  color: #64748b !important;
  background: rgba(255, 255, 255, 0.74) !important;
  box-shadow:
    0 2px 0 rgba(15, 23, 42, 0.08),
    0 8px 16px rgba(15, 23, 42, 0.07) !important;
}

.executive-header-dark .btn-context-idle {
  color: rgba(226, 232, 240, 0.82) !important;
  background: rgba(255, 255, 255, 0.08) !important;
  border-color: rgba(255, 255, 255, 0.10) !important;
}

.btn-context-active {
  color: white !important;
  box-shadow:
    0 2px 0 rgba(0, 0, 0, 0.20),
    0 10px 18px rgba(15, 23, 42, 0.16) !important;
}

.btn-context-3d:hover {
  transform: translateY(-1px);
  filter: brightness(1.025);
  box-shadow:
    0 3px 0 rgba(15, 23, 42, 0.12),
    0 12px 22px rgba(15, 23, 42, 0.12) !important;
}

.btn-context-3d:active {
  transform: translateY(1px);
  box-shadow:
    0 1px 0 rgba(15, 23, 42, 0.14),
    0 5px 10px rgba(15, 23, 42, 0.08) !important;
}

.dashboard-clock,
.server-status-pill {
  position: relative;
  z-index: 2;
  min-height: 50px;
  padding: 9px 13px;
  border-radius: 17px;
  background: rgba(255,255,255,0.82);
  border: 1px solid rgba(148, 163, 184, 0.20);
  box-shadow:
    0 10px 24px rgba(15,23,42,0.08),
    inset 0 1px 0 rgba(255,255,255,0.9);
  backdrop-filter: blur(12px);
}

.executive-header-dark .dashboard-clock,
.executive-header-dark .server-status-pill {
  background: rgba(15, 23, 42, 0.58);
  border-color: rgba(255,255,255,0.10);
  box-shadow:
    0 12px 28px rgba(0,0,0,0.22),
    inset 0 1px 0 rgba(255,255,255,0.06);
}

.clock-icon-soft {
  width: 38px;
  height: 38px;
  border-radius: 14px;
  color: #2563eb;
  background: linear-gradient(135deg, rgba(37,99,235,0.14), rgba(37,99,235,0.04));
  box-shadow:
    inset 0 1px 0 rgba(255,255,255,0.9),
    0 8px 18px rgba(37,99,235,0.13);
}

.server-status-pill {
  color: #059669;
}

.executive-header-dark .server-status-pill {
  color: #34d399;
}

.server-pulse {
  width: 10px;
  height: 10px;
  border-radius: 999px;
  background: #22c55e;
  box-shadow: 0 0 0 0 rgba(34,197,94,0.45);
  animation: serverPulse 1.8s infinite;
}

.panel-options-btn {
  border-radius: 14px !important;
  box-shadow:
    0 3px 0 rgba(30, 64, 175, 0.35),
    0 10px 20px rgba(37, 99, 235, 0.20) !important;
}

@keyframes serverPulse {
  0% { box-shadow: 0 0 0 0 rgba(34,197,94,0.45); }
  70% { box-shadow: 0 0 0 8px rgba(34,197,94,0); }
  100% { box-shadow: 0 0 0 0 rgba(34,197,94,0); }
}

.bg-gradient-red {
  background: linear-gradient(135deg, #ef4444 0%, #b91c1c 100%) !important;
}

.bg-gradient-green {
  background: linear-gradient(135deg, #22c55e 0%, #15803d 100%) !important;
}

.bg-gradient-blue {
  background: linear-gradient(135deg, #2563eb 0%, #1e40af 100%) !important;
}

@media (max-width: 1260px) {
  .context-switcher {
    max-width: calc(100vw - 420px);
  }

  .dashboard-clock,
  .server-status-pill {
    padding: 8px 10px;
  }
}

@media (max-width: 1100px) {
  .executive-header .ga-6 {
    gap: 12px !important;
  }

  .context-switcher {
    max-width: 100%;
  }
}

@media (max-width: 960px) {
  .executive-header {
    padding: 16px;
    border-radius: 18px;
  }

  .executive-header > .d-flex {
    gap: 16px;
  }

  .context-switcher {
    max-width: 100%;
  }

  .dashboard-clock,
  .server-status-pill {
    display: none !important;
  }
}

@media (max-width: 600px) {
  .executive-header {
    padding: 14px;
  }

  .executive-header .icon-box-lg {
    width: 42px !important;
    height: 42px !important;
    min-width: 42px !important;
    margin-right: 12px !important;
  }

  .dashboard-title {
    font-size: 1.25rem;
  }

  .dashboard-breadcrumb {
    font-size: 9px !important;
  }

  .context-switcher {
    gap: 8px;
  }

  .btn-context-3d {
    height: 24px !important;
    padding-inline: 10px !important;
    font-size: 9px !important;
  }
}


/* ===== AJUSTES RESPONSIVOS PROFISSIONAIS DO SUPER DASHBOARD ===== */
.dashboard-header-inner {
  position: relative;
  z-index: 2;
}

.dashboard-title-group {
  min-width: 0;
  flex: 1 1 auto;
}

.dashboard-title-group > div:last-child {
  min-width: 0;
}

.dashboard-actions-group {
  flex: 0 0 auto;
}

.executive-header {
  isolation: isolate;
}

.context-switcher {
  width: 100%;
  max-width: 780px;
  row-gap: 8px !important;
  column-gap: 10px !important;
  overflow: visible !important;
  padding-right: 4px;
}

.btn-context-3d {
  max-width: 150px;
}

.btn-context-3d .v-btn__content {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.dashboard-filter-bar {
  position: relative;
  z-index: 1;
}

.balance-filter-toggle {
  max-width: 100%;
  overflow-x: auto;
}

.balance-filter-toggle .v-btn {
  min-width: max-content;
}

.ranking-row-safe {
  min-width: 0;
  overflow: hidden;
}

.ranking-row-safe > * {
  min-width: 0;
}

.ranking-row-safe .text-h6,
.ranking-row-safe .text-subtitle-1,
.ranking-row-safe .font-weight-black,
.ranking-row-safe .font-weight-bold {
  min-width: 0;
}

.ranking-row-safe div {
  min-width: 0;
}

.ranking-row-safe .text-success,
.ranking-row-safe .text-primary,
.ranking-row-safe .text-orange-darken-2,
.ranking-row-safe .font-mono {
  white-space: nowrap;
  flex-shrink: 0;
}

.ranking-row-safe .text-truncate,
.ranking-row-safe [class*="text-"] {
  overflow-wrap: anywhere;
}

@media (max-width: 1260px) {
  .executive-header {
    padding: 18px !important;
  }

  .dashboard-actions-group {
    gap: 10px !important;
  }

  .context-switcher {
    max-width: 100%;
  }
}

@media (max-width: 960px) {
  .admin-dashboard-container {
    padding: 14px !important;
  }

  .executive-header {
    border-radius: 20px !important;
    padding: 16px !important;
  }

  .dashboard-header-inner {
    align-items: stretch !important;
  }

  .dashboard-title-group {
    align-items: flex-start !important;
  }

  .dashboard-title-group .icon-box-lg {
    width: 44px !important;
    height: 44px !important;
    min-width: 44px !important;
    margin-right: 12px !important;
    border-radius: 14px !important;
  }

  .dashboard-title {
    font-size: 1.35rem !important;
    line-height: 1.12 !important;
    letter-spacing: -0.025em !important;
    max-width: 100%;
  }

  .wave-hand {
    font-size: 1.25rem !important;
  }

  .dashboard-breadcrumb {
    font-size: 9px !important;
    line-height: 1.2 !important;
    margin-bottom: 4px !important;
    max-width: 100%;
    white-space: normal !important;
  }

  .context-switcher {
    display: flex !important;
    flex-wrap: wrap !important;
    max-width: 100% !important;
    width: 100%;
    gap: 8px !important;
    margin-top: 10px !important;
    padding-bottom: 0 !important;
  }

  .btn-context-3d {
    height: 25px !important;
    padding-inline: 11px !important;
    max-width: calc(50% - 6px);
    flex: 0 1 auto;
    font-size: 9px !important;
    letter-spacing: 0.35px !important;
  }

  .dashboard-actions-group {
    width: 100%;
    justify-content: flex-start !important;
    margin-top: 8px;
  }

  .panel-options-btn {
    height: 38px !important;
    border-radius: 13px !important;
  }

  .dashboardSubtitle,
  .executive-header p.text-medium-emphasis {
    font-size: 0.88rem !important;
    line-height: 1.35 !important;
    max-width: 100%;
  }

  .dashboard-filter-bar {
    justify-content: flex-start !important;
    gap: 8px !important;
    overflow: hidden;
  }

  .dashboard-filter-bar > span {
    width: 100%;
    text-align: left;
    margin-bottom: 2px;
  }

  .balance-filter-toggle {
    width: 100%;
    display: flex;
  }

  .balance-filter-toggle .v-btn {
    flex: 1 1 auto;
    padding-inline: 10px !important;
    font-size: 10px !important;
  }

  .dashboard-filter-bar .v-btn {
    max-width: 100%;
  }

  .kpi-card-3d {
    min-height: 142px;
  }

  .kpi-value {
    font-size: clamp(1.55rem, 8vw, 2rem) !important;
    line-height: 1.05 !important;
    word-break: break-word;
  }

  .kpi-label {
    font-size: 13px !important;
  }

  .kpi-footer {
    font-size: 10px !important;
    gap: 6px;
  }

  .kpi-footer .v-btn {
    font-size: 10px !important;
    min-width: max-content;
  }
}

@media (max-width: 600px) {
  .admin-dashboard-container {
    padding: 10px !important;
  }

  .executive-header {
    padding: 14px !important;
    border-radius: 18px !important;
  }

  .dashboard-title-group {
    display: flex !important;
    width: 100%;
  }

  .dashboard-title-group .icon-box-lg {
    width: 40px !important;
    height: 40px !important;
    min-width: 40px !important;
    margin-right: 10px !important;
  }

  .dashboard-title {
    font-size: 1.16rem !important;
    line-height: 1.14 !important;
  }

  .dashboard-breadcrumb {
    font-size: 8px !important;
    letter-spacing: 0.05em !important;
  }

  .executive-header p.text-medium-emphasis {
    font-size: 0.84rem !important;
    line-height: 1.35 !important;
  }

  .btn-context-3d {
    max-width: calc(50% - 5px);
    height: 24px !important;
    padding-inline: 9px !important;
    font-size: 8.5px !important;
  }

  .panel-options-btn {
    width: 100%;
    max-width: 210px;
    justify-content: center;
  }

  .dashboard-filter-bar {
    margin-top: 4px;
  }

  .balance-filter-toggle {
    overflow-x: auto;
    border-radius: 12px !important;
  }

  .balance-filter-toggle .v-btn {
    min-width: 94px;
    flex: 0 0 auto;
    font-size: 9.5px !important;
  }

  .ranking-row-safe {
    align-items: flex-start !important;
    gap: 10px;
    padding: 12px !important;
  }

  .ranking-row-safe .v-avatar,
  .ranking-row-safe .rounded-circle {
    flex: 0 0 auto;
  }

  .ranking-row-safe > div:nth-child(2),
  .ranking-row-safe > div:first-child {
    min-width: 0;
  }

  .ranking-row-safe .text-h6,
  .ranking-row-safe .text-subtitle-1,
  .ranking-row-safe .font-weight-black {
    font-size: 0.92rem !important;
    line-height: 1.18 !important;
    white-space: normal !important;
    overflow-wrap: anywhere;
  }

  .ranking-row-safe .text-caption {
    font-size: 0.72rem !important;
    line-height: 1.25 !important;
  }

  .ranking-row-safe .text-success,
  .ranking-row-safe .text-primary,
  .ranking-row-safe .text-orange-darken-2,
  .ranking-row-safe .font-mono {
    font-size: 0.86rem !important;
    line-height: 1.2 !important;
    text-align: right;
    max-width: 112px;
    overflow: hidden;
    text-overflow: ellipsis;
  }

  .v-card-title,
  .text-subtitle-1 {
    overflow-wrap: anywhere;
  }
}

@media (max-width: 430px) {
  .btn-context-3d {
    max-width: 100%;
    flex: 1 1 calc(50% - 5px);
  }

  .executive-header p.text-medium-emphasis {
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
    overflow: hidden;
  }

  .ranking-row-safe {
    display: grid !important;
    grid-template-columns: auto minmax(0, 1fr);
    grid-template-areas:
      "rank main"
      "rank value";
  }

  .ranking-row-safe > :first-child {
    grid-area: rank;
  }

  .ranking-row-safe > :nth-child(2) {
    grid-area: main;
  }

  .ranking-row-safe > :last-child {
    grid-area: value;
    justify-self: start;
    max-width: 100%;
    text-align: left;
    margin-left: 0 !important;
  }
}


/* ===== HEADER FINAL: LIMPO, COMPACTO E LEGÍVEL ===== */
.executive-header-clean {
  padding: 18px 20px !important;
  min-height: auto !important;
}

.executive-header-clean .dashboard-header-inner {
  align-items: flex-start !important;
}

.executive-header-clean .dashboard-title-group {
  width: 100%;
  max-width: 100%;
}

.executive-header-clean .dashboard-title-group > div:last-child {
  width: 100%;
  min-width: 0;
}

.executive-header-clean .dashboard-clock,
.executive-header-clean .server-status-pill {
  display: none !important;
}

.executive-header-light.executive-header-clean {
  background:
    linear-gradient(135deg, #ffffff 0%, #f8fbff 52%, #eef8f3 100%) !important;
  border: 1px solid rgba(148, 163, 184, 0.22) !important;
  box-shadow:
    0 14px 34px rgba(15, 23, 42, 0.075),
    inset 0 1px 0 rgba(255,255,255,0.90) !important;
}

.executive-header-dark.executive-header-clean {
  background:
    linear-gradient(135deg, rgba(15,23,42,0.94) 0%, rgba(30,41,59,0.88) 100%) !important;
  border: 1px solid rgba(255,255,255,0.08) !important;
}

.executive-header-clean .dashboard-breadcrumb {
  font-size: 9px !important;
  letter-spacing: 0.09em;
  color: #64748b !important;
  opacity: 1 !important;
}

.executive-header-clean .dashboard-title {
  font-size: clamp(1.35rem, 2vw, 1.9rem) !important;
  line-height: 1.08 !important;
  color: #0f172a !important;
}

.executive-header-dark.executive-header-clean .dashboard-title {
  color: #fff !important;
}

.executive-header-clean .wave-hand {
  font-size: 1.35rem !important;
}

.executive-header-clean p.text-medium-emphasis {
  margin-top: 6px !important;
  margin-bottom: 0 !important;
  font-size: 0.88rem !important;
  line-height: 1.32 !important;
  color: #475569 !important;
  max-width: 760px;
}

.executive-header-dark.executive-header-clean p.text-medium-emphasis {
  color: rgba(226,232,240,0.78) !important;
}

.executive-header-clean .context-switcher {
  max-width: 100% !important;
  gap: 10px !important;
  margin-top: 10px !important;
  overflow: visible !important;
}

.executive-header-clean .btn-context-3d {
  height: 25px !important;
  padding-inline: 13px !important;
  border-radius: 8px !important;
  font-size: 9.5px !important;
  letter-spacing: 0.045em !important;
  border: 1px solid rgba(148,163,184,0.22) !important;
}

.executive-header-clean .btn-context-idle {
  background: #ffffff !important;
  color: #64748b !important;
  box-shadow:
    0 2px 0 rgba(15, 23, 42, 0.08),
    0 7px 14px rgba(15, 23, 42, 0.08) !important;
}

.executive-header-clean .btn-context-active {
  color: #ffffff !important;
  box-shadow:
    0 2px 0 rgba(0, 0, 0, 0.18),
    0 10px 20px rgba(15, 23, 42, 0.16) !important;
}

.executive-header-clean .header-inline-actions {
  display: flex;
  align-items: center;
  gap: 10px;
}

.executive-header-clean .panel-options-inline {
  height: 34px !important;
  border-radius: 10px !important;
  padding-inline: 14px !important;
  box-shadow:
    0 3px 0 rgba(30, 64, 175, 0.28),
    0 10px 18px rgba(37, 99, 235, 0.18) !important;
}

@media (max-width: 960px) {
  .executive-header-clean {
    padding: 14px !important;
    border-radius: 18px !important;
  }

  .executive-header-clean .dashboard-title-group {
    align-items: flex-start !important;
  }

  .executive-header-clean .icon-box-lg {
    width: 42px !important;
    height: 42px !important;
    min-width: 42px !important;
    margin-right: 12px !important;
    border-radius: 13px !important;
  }

  .executive-header-clean .dashboard-title {
    font-size: 1.24rem !important;
  }

  .executive-header-clean .context-switcher {
    gap: 8px !important;
  }

  .executive-header-clean .btn-context-3d {
    max-width: calc(50% - 5px);
    flex: 1 1 auto;
    height: 24px !important;
    font-size: 8.5px !important;
    padding-inline: 8px !important;
  }

  .executive-header-clean .header-inline-actions {
    margin-top: 10px !important;
  }

  .executive-header-clean .panel-options-inline {
    width: 100%;
    max-width: 220px;
  }
}

@media (max-width: 430px) {
  .executive-header-clean .btn-context-3d {
    flex: 1 1 calc(50% - 5px);
    max-width: calc(50% - 5px);
  }

  .executive-header-clean p.text-medium-emphasis {
    font-size: 0.82rem !important;
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
    overflow: hidden;
  }
}


/* ===== Ajuste pontual: Opções do Painel à direita ===== */
.executive-header-clean .dashboard-actions-group {
  margin-left: auto;
  align-self: flex-start;
  padding-top: 30px;
  flex: 0 0 auto;
}

.executive-header-clean .dashboard-actions-group .panel-options-inline {
  margin-left: auto;
}

@media (max-width: 960px) {
  .executive-header-clean .dashboard-actions-group {
    width: 100%;
    padding-top: 6px;
    margin-left: 0;
    justify-content: flex-start !important;
  }
}


/* ===== Rankings completos com scroll interno e paginação ===== */
.tenant-ranking-scroll {
  max-height: 430px;
  overflow-y: auto;
  overflow-x: hidden;
  padding-right: 4px;
}

.ranking-footer {
  gap: 10px;
  border-top: 1px solid rgba(148, 163, 184, 0.18);
}

.ranking-footer .v-pagination {
  flex: 0 0 auto;
}

.ranking-row-safe {
  min-width: 0;
}

.ranking-row-safe > * {
  min-width: 0;
}

.ranking-value {
  flex-shrink: 0;
  white-space: nowrap;
  max-width: 145px;
  overflow: hidden;
  text-overflow: ellipsis;
  text-align: right;
}

@media (max-width: 960px) {
  .tenant-ranking-scroll {
    max-height: 360px;
  }

  .ranking-footer {
    flex-direction: column;
    align-items: flex-start !important;
  }

  .ranking-footer .v-pagination {
    max-width: 100%;
    overflow-x: auto;
  }
}



/* ===== Hierarquia visual e seções do dashboard ===== */
.dashboard-section-intro {
  position: relative;
  padding: 16px 18px;
  border-radius: 18px;
  border: 1px solid rgba(148, 163, 184, 0.18);
  background: linear-gradient(135deg, rgba(255,255,255,0.88) 0%, rgba(248,250,252,0.96) 60%, rgba(241,245,249,0.98) 100%);
  box-shadow: 0 10px 24px rgba(15, 23, 42, 0.05), inset 0 1px 0 rgba(255,255,255,0.9);
}

.theme--dark .dashboard-section-intro,
.v-theme--dark .dashboard-section-intro,
.dashboard-root.theme-dark .dashboard-section-intro {
  background: linear-gradient(135deg, rgba(30,41,59,0.76) 0%, rgba(15,23,42,0.88) 100%);
  border-color: rgba(255,255,255,0.08);
}

.dashboard-section-intro-inline {
  margin-bottom: 6px;
}

.dashboard-section-chip {
  display: inline-flex;
  align-items: center;
  padding: 5px 10px;
  border-radius: 999px;
  background: rgba(59, 130, 246, 0.10);
  color: #1d4ed8;
  font-size: 0.68rem;
  line-height: 1;
  font-weight: 900;
  letter-spacing: 0.1em;
  margin-bottom: 8px;
}

.dashboard-section-title {
  font-size: clamp(1.05rem, 1.4vw, 1.35rem);
  line-height: 1.15;
  font-weight: 900;
  color: #0f172a;
  margin-bottom: 6px;
}

.dashboard-section-text {
  color: #64748b;
  font-size: 0.93rem;
  line-height: 1.55;
  max-width: 880px;
}

.dashboard-subsection-banner {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 12px;
  padding: 14px 16px;
  border-radius: 16px;
  border: 1px dashed rgba(148, 163, 184, 0.35);
  background: rgba(248, 250, 252, 0.9);
}

.dashboard-subsection-title {
  font-size: 0.92rem;
  font-weight: 900;
  color: #0f172a;
  margin-bottom: 4px;
  text-transform: uppercase;
  letter-spacing: 0.04em;
}

.dashboard-subsection-text {
  font-size: 0.84rem;
  line-height: 1.5;
  color: #64748b;
  max-width: 760px;
}

.dashboard-section-row > .v-col {
  padding-top: 8px;
  padding-bottom: 8px;
}

@media (max-width: 960px) {
  .dashboard-section-intro {
    padding: 14px 14px;
    border-radius: 16px;
  }

  .dashboard-section-title {
    font-size: 1rem;
  }

  .dashboard-section-text {
    font-size: 0.85rem;
  }

  .dashboard-subsection-banner {
    padding: 12px 12px;
  }

  .dashboard-subsection-text {
    font-size: 0.8rem;
  }
}



/* ===== Seções completas com mais respiro ===== */
.dashboard-shell-section {
  position: relative;
  margin: 0 0 32px;
  padding: 22px;
  border-radius: 28px;
  border: 1px solid rgba(148, 163, 184, 0.18);
  background: linear-gradient(180deg, rgba(255,255,255,0.82) 0%, rgba(248,250,252,0.92) 100%);
  box-shadow: 0 18px 40px rgba(15, 23, 42, 0.06), inset 0 1px 0 rgba(255,255,255,0.9);
  overflow: hidden;
}

.dashboard-shell-section::before {
  content: '';
  position: absolute;
  inset: 0 0 auto 0;
  height: 5px;
  border-radius: 28px 28px 0 0;
  opacity: 0.95;
}

.dashboard-shell-section > .dashboard-section-intro,
.dashboard-shell-section > .store-selector-section,
.dashboard-shell-section > .v-row,
.dashboard-shell-section > .v-card {
  position: relative;
  z-index: 1;
}

.dashboard-shell-section > .dashboard-section-intro {
  margin-bottom: 18px !important;
}

.dashboard-shell-section > .v-row,
.dashboard-shell-section > .v-card,
.dashboard-shell-section > .store-selector-section {
  margin-top: 0;
}

.dashboard-shell-section--executive::before {
  background: linear-gradient(90deg, #ef4444 0%, #2563eb 55%, #0ea5e9 100%);
}

.dashboard-shell-section--analytics::before {
  background: linear-gradient(90deg, #4f46e5 0%, #7c3aed 50%, #06b6d4 100%);
}

.dashboard-shell-section--focused::before {
  background: linear-gradient(90deg, #f59e0b 0%, #3b82f6 48%, #10b981 100%);
}

.dashboard-shell-section--compare::before {
  background: linear-gradient(90deg, #0ea5e9 0%, #14b8a6 55%, #22c55e 100%);
}

.dashboard-shell-section--details::before {
  background: linear-gradient(90deg, #8b5cf6 0%, #6366f1 50%, #334155 100%);
}

.dashboard-shell-section--analytics .dashboard-section-intro {
  background: linear-gradient(135deg, rgba(238,242,255,0.92) 0%, rgba(248,250,252,0.98) 100%);
}

.dashboard-shell-section--focused .dashboard-section-intro {
  background: linear-gradient(135deg, rgba(255,247,237,0.95) 0%, rgba(248,250,252,0.98) 100%);
}

.dashboard-shell-section--compare .dashboard-section-intro {
  background: linear-gradient(135deg, rgba(240,253,250,0.95) 0%, rgba(248,250,252,0.98) 100%);
}

.dashboard-shell-section--details .dashboard-section-intro {
  background: linear-gradient(135deg, rgba(245,243,255,0.95) 0%, rgba(248,250,252,0.98) 100%);
}

.dashboard-shell-section .dashboard-subsection-banner {
  margin-top: 4px;
  margin-bottom: 14px !important;
}

.dashboard-shell-section .store-selector-section {
  margin-top: 22px !important;
  padding-top: 18px;
  border-top: 1px dashed rgba(148, 163, 184, 0.3);
}

.dashboard-shell-section .v-card.card-3d {
  backdrop-filter: blur(6px);
}

.dashboard-shell-section .dashboard-section-text {
  max-width: 980px;
}

.theme--dark .dashboard-shell-section,
.v-theme--dark .dashboard-shell-section,
.dashboard-root.theme-dark .dashboard-shell-section {
  background: linear-gradient(180deg, rgba(15,23,42,0.78) 0%, rgba(17,24,39,0.88) 100%);
  border-color: rgba(255,255,255,0.07);
  box-shadow: 0 18px 40px rgba(2, 6, 23, 0.26), inset 0 1px 0 rgba(255,255,255,0.04);
}

.theme--dark .dashboard-shell-section--analytics .dashboard-section-intro,
.v-theme--dark .dashboard-shell-section--analytics .dashboard-section-intro,
.dashboard-root.theme-dark .dashboard-shell-section--analytics .dashboard-section-intro {
  background: linear-gradient(135deg, rgba(55,48,163,0.16) 0%, rgba(30,41,59,0.94) 100%);
}

.theme--dark .dashboard-shell-section--focused .dashboard-section-intro,
.v-theme--dark .dashboard-shell-section--focused .dashboard-section-intro,
.dashboard-root.theme-dark .dashboard-shell-section--focused .dashboard-section-intro {
  background: linear-gradient(135deg, rgba(146,64,14,0.16) 0%, rgba(30,41,59,0.94) 100%);
}

.theme--dark .dashboard-shell-section--compare .dashboard-section-intro,
.v-theme--dark .dashboard-shell-section--compare .dashboard-section-intro,
.dashboard-root.theme-dark .dashboard-shell-section--compare .dashboard-section-intro {
  background: linear-gradient(135deg, rgba(13,148,136,0.14) 0%, rgba(30,41,59,0.94) 100%);
}

.theme--dark .dashboard-shell-section--details .dashboard-section-intro,
.v-theme--dark .dashboard-shell-section--details .dashboard-section-intro,
.dashboard-root.theme-dark .dashboard-shell-section--details .dashboard-section-intro {
  background: linear-gradient(135deg, rgba(109,40,217,0.14) 0%, rgba(30,41,59,0.94) 100%);
}

@media (max-width: 1264px) {
  .dashboard-shell-section {
    padding: 18px;
    border-radius: 24px;
    margin-bottom: 26px;
  }
}

@media (max-width: 960px) {
  .dashboard-shell-section {
    padding: 14px;
    border-radius: 20px;
    margin-bottom: 22px;
  }

  .dashboard-shell-section::before {
    border-radius: 20px 20px 0 0;
  }

  .dashboard-shell-section > .dashboard-section-intro {
    margin-bottom: 14px !important;
  }

  .dashboard-shell-section .store-selector-section {
    margin-top: 18px !important;
    padding-top: 14px;
  }
}


/* ===== Ilha flutuante de contexto e menor densidade visual ===== */
.floating-context-island {
  position: fixed;
  top: 18px;
  left: 50%;
  transform: translateX(-50%);
  z-index: 40;
  pointer-events: none;
  width: min(92vw, 860px);
  display: flex;
  justify-content: center;
}

.floating-island-inner {
  pointer-events: auto;
  display: flex;
  align-items: center;
  gap: 8px;
  max-width: 100%;
  padding: 7px;
  border-radius: 18px;
  background: rgba(255, 255, 255, 0.86);
  border: 1px solid rgba(148, 163, 184, 0.22);
  box-shadow:
    0 12px 30px rgba(15, 23, 42, 0.14),
    0 2px 0 rgba(15, 23, 42, 0.06),
    inset 0 1px 0 rgba(255,255,255,0.86);
  backdrop-filter: blur(16px);
  overflow-x: auto;
  overflow-y: hidden;
  scrollbar-width: none;
}

.floating-island-inner::-webkit-scrollbar {
  display: none;
}

.floating-island-label {
  align-items: center;
  gap: 5px;
  padding: 0 8px;
  height: 28px;
  color: #64748b;
  font-size: 10px;
  font-weight: 900;
  text-transform: uppercase;
  letter-spacing: 0.08em;
  border-right: 1px solid rgba(148, 163, 184, 0.22);
  margin-right: 2px;
  white-space: nowrap;
}

.floating-context-btn {
  flex: 0 0 auto;
  min-width: 0 !important;
  padding-inline: 11px !important;
  font-size: 9.5px !important;
  letter-spacing: 0.045em !important;
  text-transform: uppercase;
  transition: transform .16s ease, box-shadow .16s ease, background .16s ease, color .16s ease;
}

.floating-context-btn-idle {
  color: #475569 !important;
  background: rgba(248, 250, 252, 0.72) !important;
  box-shadow: inset 0 0 0 1px rgba(148, 163, 184, 0.14) !important;
}

.floating-context-btn-active {
  color: white !important;
  box-shadow:
    0 2px 0 rgba(0, 0, 0, 0.18),
    0 8px 16px rgba(15, 23, 42, 0.15) !important;
}

.floating-context-btn:hover {
  transform: translateY(-1px);
}

.floating-context-btn:active {
  transform: translateY(1px);
}

.animate-floating-island {
  animation: islandEnter .55s cubic-bezier(.2,.9,.25,1), islandFloat 5.5s ease-in-out infinite .7s;
}

@keyframes islandEnter {
  from {
    opacity: 0;
    transform: translateX(-50%) translateY(-16px) scale(.96);
  }
  to {
    opacity: 1;
    transform: translateX(-50%) translateY(0) scale(1);
  }
}

@keyframes islandFloat {
  0%, 100% {
    transform: translateX(-50%) translateY(0);
  }
  50% {
    transform: translateX(-50%) translateY(-3px);
  }
}

/* Menos texto dentro dos cards: os cards mostram número/ação; a explicação fica nas seções */
.dashboard-readable-lite .v-card > .text-caption.text-medium-emphasis,
.dashboard-readable-lite .v-card .d-flex.align-center.mb-3 + .text-caption.text-medium-emphasis {
  display: none !important;
}

.dashboard-readable-lite .dashboard-section-text {
  font-size: 0.86rem !important;
  line-height: 1.42 !important;
  max-width: 760px !important;
}

.dashboard-readable-lite .dashboard-section-intro {
  padding: 14px 16px !important;
}

.dashboard-readable-lite .dashboard-section-title {
  margin-bottom: 3px !important;
}

.dashboard-readable-lite .dashboard-subsection-text {
  font-size: 0.8rem !important;
}

.dashboard-readable-lite .tenant-ranking-scroll .ranking-row {
  margin-bottom: 8px !important;
}

.dashboard-readable-lite .v-card .px-5.py-4.border-b {
  padding-top: 14px !important;
  padding-bottom: 12px !important;
}

@media (max-width: 960px) {
  .floating-context-island {
    top: auto;
    bottom: 14px;
    width: calc(100vw - 20px);
  }

  .floating-island-inner {
    justify-content: flex-start;
    border-radius: 16px;
    padding: 7px;
  }

  .floating-context-btn {
    height: 27px !important;
    font-size: 8.5px !important;
    padding-inline: 9px !important;
  }

  .admin-dashboard-container {
    padding-bottom: 78px !important;
  }
}

@media (max-width: 430px) {
  .floating-context-island {
    bottom: 10px;
  }

  .floating-island-inner {
    gap: 6px;
  }

  .floating-context-btn {
    max-width: 118px;
  }

  .floating-context-btn .v-btn__content {
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }
}


/* ===== Contexto: grudado no header no topo, ilha ao rolar ===== */
.context-switcher-docked {
  transform-origin: top left;
  will-change: opacity, transform, filter;
}

.context-dock-enter-active,
.context-dock-leave-active {
  transition: opacity .28s ease, transform .34s cubic-bezier(.2,.9,.25,1), filter .28s ease;
}

.context-dock-enter-from,
.context-dock-leave-to {
  opacity: 0;
  transform: translateY(-8px) scale(.96);
  filter: blur(4px);
}

.context-dock-enter-to,
.context-dock-leave-from {
  opacity: 1;
  transform: translateY(0) scale(1);
  filter: blur(0);
}

.context-island-float-enter-active {
  transition:
    opacity .38s ease,
    transform .52s cubic-bezier(.18, 1.15, .28, 1),
    filter .34s ease;
}

.context-island-float-leave-active {
  transition:
    opacity .30s ease,
    transform .42s cubic-bezier(.22, .8, .28, 1),
    filter .28s ease;
}

.context-island-float-enter-from {
  opacity: 0;
  transform: translateX(-50%) translateY(-42px) scale(.82);
  filter: blur(10px);
}

.context-island-float-enter-to {
  opacity: 1;
  transform: translateX(-50%) translateY(0) scale(1);
  filter: blur(0);
}

.context-island-float-leave-from {
  opacity: 1;
  transform: translateX(-50%) translateY(0) scale(1);
  filter: blur(0);
}

.context-island-float-leave-to {
  opacity: 0;
  transform: translateX(-50%) translateY(-34px) scale(.88);
  filter: blur(9px);
}

.floating-context-island {
  animation: islandSoftHover 5.8s ease-in-out infinite .6s;
}

.floating-context-island::before {
  content: '';
  position: absolute;
  inset: -10px;
  pointer-events: none;
  border-radius: 28px;
  background: radial-gradient(circle at 50% 50%, rgba(59,130,246,0.13), transparent 62%);
  opacity: .75;
  animation: islandGlow 3.6s ease-in-out infinite;
}

@keyframes islandSoftHover {
  0%, 100% {
    margin-top: 0;
  }
  50% {
    margin-top: -2px;
  }
}

@keyframes islandGlow {
  0%, 100% {
    opacity: .45;
    transform: scale(.96);
  }
  50% {
    opacity: .78;
    transform: scale(1.02);
  }
}

/* A versão antiga usava animação infinita direto no wrapper. Aqui ela vira neutra. */
.animate-floating-island {
  animation: none !important;
}


.floating-island-inner {
  position: relative;
  z-index: 2;
}

@media (max-width: 960px) {
  .floating-context-island::before {
    display: none;
  }
}


/* ===== Rankings: visual mais bonito e paginação legível ===== */
.dashboard-subsection-banner--rankings {
  position: relative;
  padding: 16px 18px !important;
  border-radius: 18px !important;
  border: 1px solid rgba(148, 163, 184, 0.18) !important;
  border-style: solid !important;
  background:
    linear-gradient(135deg, rgba(255,255,255,0.88) 0%, rgba(248,250,252,0.96) 58%, rgba(241,245,249,0.98) 100%);
  box-shadow:
    0 10px 24px rgba(15, 23, 42, 0.05),
    inset 0 1px 0 rgba(255,255,255,0.92);
}

.dashboard-subsection-banner--rankings::before {
  content: '';
  position: absolute;
  inset: 0 0 auto 0;
  height: 4px;
  border-radius: 18px 18px 0 0;
  background: linear-gradient(90deg, #3b82f6 0%, #f59e0b 50%, #14b8a6 100%);
  opacity: .95;
}

.ranking-card {
  border-radius: 22px !important;
  box-shadow:
    0 14px 30px rgba(15, 23, 42, 0.07),
    inset 0 1px 0 rgba(255,255,255,0.75) !important;
}

.ranking-card .border-b {
  background: linear-gradient(180deg, rgba(248,250,252,0.9) 0%, rgba(255,255,255,0.6) 100%);
}

.ranking-card .text-subtitle-1 {
  letter-spacing: -0.01em;
}

.tenant-ranking-scroll {
  max-height: 395px;
  overflow-y: auto;
  overflow-x: hidden;
  padding-right: 6px;
}

.ranking-row {
  transition: transform .16s ease, box-shadow .18s ease, border-color .18s ease, background .18s ease;
  border-color: rgba(148, 163, 184, 0.20) !important;
  background: linear-gradient(180deg, rgba(255,255,255,0.86) 0%, rgba(248,250,252,0.92) 100%) !important;
}

.ranking-row:hover {
  transform: translateY(-1px);
  box-shadow: 0 10px 20px rgba(15, 23, 42, 0.06);
  border-color: rgba(59, 130, 246, 0.22) !important;
}

.ranking-footer {
  gap: 14px;
  margin-top: 6px;
  padding-top: 14px !important;
  border-top: 1px solid rgba(148, 163, 184, 0.16);
}

.ranking-pagination-box {
  display: inline-flex;
  align-items: center;
  gap: 10px;
  padding: 6px;
  border-radius: 999px;
  background: rgba(248,250,252,0.95);
  border: 1px solid rgba(148, 163, 184, 0.18);
  box-shadow:
    0 8px 18px rgba(15, 23, 42, 0.05),
    inset 0 1px 0 rgba(255,255,255,0.92);
}

.ranking-page-btn {
  min-width: 112px !important;
  height: 34px !important;
  border-radius: 999px !important;
  font-size: 0.74rem !important;
  font-weight: 800 !important;
  letter-spacing: 0.02em !important;
  text-transform: none !important;
  box-shadow:
    0 2px 0 rgba(15, 23, 42, 0.08),
    0 6px 14px rgba(15, 23, 42, 0.06);
}

.ranking-page-btn:not(.v-btn--disabled):hover {
  transform: translateY(-1px);
}

.ranking-page-indicator {
  min-width: 122px;
  text-align: center;
  padding: 0 8px;
  font-size: 0.78rem;
  color: #475569;
  white-space: nowrap;
}

.ranking-page-indicator strong {
  color: #0f172a;
  font-weight: 900;
}

@media (max-width: 960px) {
  .tenant-ranking-scroll {
    max-height: 330px;
  }

  .ranking-footer {
    flex-direction: column;
    align-items: stretch !important;
  }

  .ranking-pagination-box {
    width: 100%;
    justify-content: space-between;
    flex-wrap: wrap;
    border-radius: 18px;
  }

  .ranking-page-btn {
    min-width: calc(50% - 6px) !important;
  }

  .ranking-page-indicator {
    width: 100%;
    order: -1;
    padding-top: 2px;
  }
}



/* ===== Detalhamento financeiro: seção mais elegante ===== */
.financial-section-header {
  background: linear-gradient(135deg, rgba(255,255,255,0.64) 0%, rgba(248,250,252,0.94) 60%, rgba(241,245,249,0.98) 100%);
}

.financial-header-icon {
  width: 48px;
  height: 48px;
  min-width: 48px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.financial-eyebrow {
  font-size: 0.72rem;
  font-weight: 900;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: #7c3aed;
  margin-bottom: 2px;
}

.financial-kpi-strip {
  background-image: linear-gradient(180deg, rgba(248,250,252,0.88) 0%, rgba(255,255,255,0.7) 100%);
}

.financial-mini-card {
  position: relative;
  overflow: hidden;
  border-color: rgba(148, 163, 184, 0.18) !important;
  box-shadow: 0 12px 24px rgba(15, 23, 42, 0.05), inset 0 1px 0 rgba(255,255,255,0.75);
}

.financial-mini-card::after {
  content: '';
  position: absolute;
  right: -22px;
  top: -22px;
  width: 84px;
  height: 84px;
  border-radius: 50%;
  opacity: 0.12;
}

.financial-mini-card--income::after { background: #16a34a; }
.financial-mini-card--expense::after { background: #dc2626; }
.financial-mini-card--balance::after { background: #2563eb; }

.financial-mini-card__label {
  display: inline-flex;
  align-items: center;
  font-size: 0.74rem;
  font-weight: 900;
  letter-spacing: 0.05em;
  text-transform: uppercase;
  margin-bottom: 10px;
}

.financial-mini-card--income .financial-mini-card__label { color: #15803d; }
.financial-mini-card--expense .financial-mini-card__label { color: #b91c1c; }
.financial-mini-card--balance .financial-mini-card__label { color: #334155; }

.financial-mini-card__value {
  font-size: 1.45rem;
  font-weight: 900;
  line-height: 1.15;
  color: #1f2937;
}

.financial-mini-card__hint {
  margin-top: 8px;
  font-size: 0.78rem;
  color: #64748b;
}

.grid-header-dash {
  background: linear-gradient(180deg, rgba(248,250,252,0.98) 0%, rgba(241,245,249,0.98) 100%) !important;
  box-shadow: inset 0 -1px 0 rgba(148, 163, 184, 0.14);
}

.grid-row-dash {
  transition: background .16s ease, transform .16s ease;
}

.grid-row-dash:hover {
  background: rgba(248,250,252,0.72) !important;
}

.financial-grid-footer {
  gap: 12px;
  border-top-color: rgba(148, 163, 184, 0.18) !important;
}

/* ===== Analytics / charts ===== */
.analytics-card {
  border-radius: 22px !important;
  box-shadow: 0 16px 34px rgba(15, 23, 42, 0.07), inset 0 1px 0 rgba(255,255,255,0.75) !important;
}

.analytics-card__header {
  gap: 12px;
}

.analytics-card__legend {
  gap: 10px;
}

.legend-chip {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  min-height: 30px;
  padding: 0 12px;
  border-radius: 999px;
  font-size: 0.74rem;
  font-weight: 800;
  letter-spacing: 0.02em;
  border: 1px solid rgba(148, 163, 184, 0.16);
  background: rgba(248,250,252,0.9);
  color: #334155;
}

.legend-dot {
  width: 10px;
  height: 10px;
  border-radius: 50%;
  display: inline-block;
}

.legend-chip--income .legend-dot { background: #4caf50; }
.legend-chip--expense .legend-dot { background: #ef5350; }
.legend-chip--retail-income .legend-dot { background: #ff9800; }
.legend-chip--retail-expense .legend-dot { background: #d32f2f; }
.legend-chip--neutral { color: #64748b; }

.chart-canvas-shell {
  position: relative;
  padding: 12px 12px 6px;
  border-radius: 18px;
  background: linear-gradient(180deg, rgba(255,255,255,0.9) 0%, rgba(248,250,252,0.95) 100%);
  border: 1px solid rgba(148, 163, 184, 0.16);
  box-shadow: inset 0 1px 0 rgba(255,255,255,0.92);
}

.chart-canvas-shell canvas {
  filter: saturate(1.02);
}

@media (max-width: 960px) {
  .financial-section-header {
    align-items: flex-start !important;
  }

  .financial-mini-card__value {
    font-size: 1.24rem;
  }

  .analytics-card__header {
    align-items: flex-start !important;
  }

  .chart-canvas-shell {
    padding: 10px 8px 4px;
  }
}

</style>
