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

    <div class="content-wrapper d-flex flex-column fill-height z-10 relative overflow-hidden">

<div
          class="header-bar px-4 px-md-6 py-3 py-md-4 d-flex flex-column flex-md-row align-md-start justify-space-between flex-shrink-0"
          :class="themeStore.currentMode === 'light' ? 'bg-white border-b border-grey-lighten-2 shadow-sm' : 'bg-glass-header border-bottom-white-05'"
      >
          <div class="d-flex flex-column" style="max-width: calc(100vw - 32px);">
              <div class="breadcrumb text-caption d-none d-md-block">
                  <span class="opacity-70 cursor-pointer hover-underline" @click="$router.push({ name: 'AdminReports', params: { reportType: 'hub' } })">Relatórios</span>
                  <span class="mx-2 opacity-50">></span>
                  <span class="font-weight-bold">Financeiro</span>
              </div>
              <div class="d-flex align-center gap-2 mt-md-1">
                 <v-btn class="d-md-none mr-1" icon="mdi-arrow-left" variant="text" size="small" @click="$router.push({ name: 'AdminReports', params: { reportType: 'hub' } })"></v-btn>
                 <div class="text-h6 font-weight-black tracking-tight leading-none text-truncate" style="max-width: 200px; md:max-width: auto;" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">
                    {{ isPrivacyMode ? 'DRE Gerencial (Demo)' : 'DRE Gerencial' }}
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
                    v-for="comp in companies"
                    :key="comp.id"
                    size="x-small"
                    height="24"
                    :variant="filters.companyId === comp.id || (!companyStore.isGlobalView && companyStore.context === comp.id && !filters.companyId) ? 'flat' : 'tonal'"
                    :color="filters.companyId === comp.id || (!companyStore.isGlobalView && companyStore.context === comp.id && !filters.companyId) ? 'primary' : 'grey'"
                    class="font-weight-bold btn-3d px-3 rounded-pill flex-shrink-0"
                    style="font-size: 10px; letter-spacing: 0.5px;"
                    @click="setCompanyFilter(comp.id)"
                 >
                    {{ comp.trade_name }}
                 </v-btn>
              </div>
          </div>

          <div class="d-flex align-center mt-3 mt-md-0 gap-2 gap-md-3">
              <v-btn
                  variant="tonal"
                  :color="isPrivacyMode ? 'deep-purple-accent-3' : (themeStore.currentMode === 'light' ? 'grey-darken-3' : 'grey-lighten-2')"
                  class="btn-rect btn-3d font-weight-bold"
                  height="40"
                  @click="togglePrivacyMode"
              >
                  <v-icon :start="!mobile" size="small">{{ isPrivacyMode ? 'mdi-incognito' : 'mdi-incognito-off' }}</v-icon>
                  <span class="d-none d-sm-inline">{{ isPrivacyMode ? 'Modo Fantasma Ativo' : 'Ocultar Dados' }}</span>
              </v-btn>

              <v-menu location="bottom end">
                <template v-slot:activator="{ props }">
                  <v-btn
                      v-bind="props"
                      color="primary"
                      variant="flat"
                      class="btn-rect btn-3d px-4 px-md-6 font-weight-bold text-uppercase letter-spacing-1 shadow-indigo-soft"
                      height="40"
                      :loading="loading"
                      :disabled="loading"
                  >
                      <span class="d-none d-sm-inline">Exportar DRE</span>
                      <v-icon :start="!mobile" size="small" class="ml-sm-2">mdi-chevron-down</v-icon>
                  </v-btn>
                </template>
                <v-list density="compact" nav :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-glass-header border-white-05 text-white'">
                  <v-list-item @click="generateReport('print')" prepend-icon="mdi-printer" title="Imprimir (Nova Aba)" class="font-weight-bold" :class="themeStore.currentMode === 'light' ? 'text-primary' : 'text-blue-lighten-2'"></v-list-item>
                  <v-list-item @click="generateReport('pdf')" prepend-icon="mdi-file-pdf-box" title="Exportar PDF" class="font-weight-bold" :class="themeStore.currentMode === 'light' ? 'text-red-darken-3' : 'text-red-lighten-2'"></v-list-item>
                  <v-list-item @click="generateExcelExport()" prepend-icon="mdi-microsoft-excel" title="Exportar Excel" class="font-weight-bold" :class="themeStore.currentMode === 'light' ? 'text-green-darken-3' : 'text-green-accent-3'"></v-list-item>
                </v-list>
              </v-menu>
          </div>
      </div>

      <div class="px-4 px-md-6 pt-4 pb-2 flex-shrink-0">
          <v-btn
              v-if="mobile"
              block
              color="primary"
              variant="tonal"
              height="44"
              class="font-weight-bold border-primary shadow-sm btn-3d"
              @click="mobileFiltersOpen = true"
          >
              <v-icon start>mdi-filter-variant</v-icon>
              Filtros: {{ formatDate(filters.startDate) }} a {{ formatDate(filters.endDate) }}
          </v-btn>

          <div v-else class="enterprise-filter-bar d-flex align-center justify-space-between flex-wrap gap-4 px-4 py-3 rounded-xl border-thin transition-all" :class="themeStore.currentMode === 'light' ? 'bg-white shadow-sm' : 'glass-card border-white-05'">

              <div class="d-flex align-center flex-wrap gap-4 w-100 h-100">
                  <div class="date-range-pill d-flex align-center rounded-lg border-thin px-3" style="height: 40px;" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5' : 'bg-white-05'">
                      <v-text-field
                        type="date"
                        v-model="filters.startDate"
                        variant="plain"
                        density="compact"
                        hide-details
                        class="enterprise-date font-weight-bold text-caption"
                        prepend-inner-icon="mdi-calendar-start"
                        :color="themeStore.currentMode === 'light' ? 'primary' : 'white'"
                      ></v-text-field>
                      <v-divider vertical class="mx-3 opacity-50" style="height: 24px; align-self: center;"></v-divider>
                      <v-text-field
                        type="date"
                        v-model="filters.endDate"
                        variant="plain"
                        density="compact"
                        hide-details
                        class="enterprise-date font-weight-bold text-caption"
                        prepend-inner-icon="mdi-calendar-end"
                        :color="themeStore.currentMode === 'light' ? 'primary' : 'white'"
                      ></v-text-field>
                  </div>

                  <v-btn-toggle
                    v-model="filters.regime"
                    mandatory
                    class="border-thin rounded-lg shadow-sm"
                    style="height: 40px;"
                    :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-transparent'"
                    color="primary"
                  >
                      <v-btn value="caixa" class="font-weight-bold px-4 text-caption text-none m-0" style="height: 40px;">
                          <v-icon start size="16">mdi-cash-check</v-icon> Caixa
                      </v-btn>
                      <v-btn value="competencia" class="font-weight-bold px-4 text-caption text-none m-0" style="height: 40px;">
                          <v-icon start size="16">mdi-calendar-clock</v-icon> Competência
                      </v-btn>
                  </v-btn-toggle>

                  <div style="width: 250px; height: 40px;" v-if="companyStore.isGlobalView">
                      <v-autocomplete
                        v-model="filters.companyId"
                        :items="companies"
                        item-title="trade_name"
                        item-value="id"
                        label="Empresa Referência"
                        variant="outlined"
                        density="compact"
                        hide-details
                        clearable
                        prepend-inner-icon="mdi-domain"
                        class="font-weight-bold ui-field h-100"
                        :bg-color="themeStore.currentMode === 'light' ? 'white' : 'rgba(255,255,255,0.05)'"
                      ></v-autocomplete>
                  </div>

                  <v-btn color="primary" height="40" class="btn-3d font-weight-black px-6 ml-auto" @click="fetchData" :loading="loading">
                      <v-icon start size="20">mdi-calculator-variant</v-icon> Calcular DRE
                  </v-btn>
              </div>
          </div>
      </div>

      <div class="flex-grow-1 overflow-y-auto custom-scroll d-flex flex-column px-4 px-md-6 py-2 pb-10 gap-4 gap-md-6 relative" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-4' : 'bg-transparent'">

          <div v-if="loading" class="d-flex flex-column justify-center align-center absolute-center w-100 h-100 z-10" :class="themeStore.currentMode === 'light' ? 'bg-white-80' : 'bg-black-80'" style="backdrop-filter: blur(4px);">
              <v-progress-circular indeterminate color="primary" size="64" width="4"></v-progress-circular>
              <span class="mt-4 font-weight-bold text-subtitle-1">Estruturando Árvore Contábil...</span>
          </div>

          <v-row v-if="!loading" class="m-0 flex-shrink-0 w-100">

              <v-col cols="12" md="6" class="pa-2">
                  <v-card class="rounded-xl border-thin pa-4 pa-md-6 d-flex flex-column h-100 position-relative" :class="themeStore.currentMode === 'light' ? 'bg-white shadow-sm' : 'glass-card border-white-05'" elevation="0" :style="{ minHeight: mobile ? '450px' : '550px' }">

                       <div class="position-absolute" style="top: 16px; right: 16px; z-index: 20;">
                           <v-menu location="bottom end" :close-on-content-click="false">
                               <template v-slot:activator="{ props }">
                                   <v-btn v-bind="props" variant="tonal" :color="themeStore.currentMode === 'light' ? 'green-darken-3' : 'green-accent-3'" class="font-weight-bold text-caption btn-3d" height="36" rounded="lg">
                                       <v-icon start size="18">mdi-format-list-bulleted</v-icon> Grupos Receita
                                   </v-btn>
                               </template>
                               <v-card width="320" max-height="400" class="overflow-y-auto custom-scroll border-thin" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-glass-dark border-white-05 text-white'">
                                   <v-list density="compact" nav class="py-2" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-transparent'">
                                       <v-list-subheader class="font-weight-black" :class="themeStore.currentMode === 'light' ? 'text-green-darken-3' : 'text-green-accent-3'">COMPOSIÇÃO MACRO</v-list-subheader>
                                       <v-list-item v-for="(leg, i) in receitasLegend" :key="i" class="border-b" :class="zebraClass(i)">
                                           <template v-slot:prepend><v-icon :color="leg.color" size="14" class="mr-2 opacity-80">mdi-circle</v-icon></template>
                                           <v-list-item-title class="text-caption font-weight-bold opacity-90 text-wrap">{{ leg.code }} - {{ leg.name }}</v-list-item-title>
                                           <template v-slot:append>
                                               <div class="text-right ml-2">
                                                   <div class="text-[11px] font-weight-black">{{ formatCurrency(leg.value) }}</div>
                                                   <div class="text-[10px] opacity-70 font-weight-bold">{{ leg.percent }}%</div>
                                               </div>
                                           </template>
                                       </v-list-item>
                                   </v-list>
                               </v-card>
                           </v-menu>
                       </div>

                       <div class="d-flex flex-column align-start mb-2 pr-16 flex-shrink-0">
                           <h3 class="text-h6 text-md-h5 font-weight-black d-flex align-center text-uppercase letter-spacing-1" :class="themeStore.currentMode === 'light' ? 'text-green-darken-2' : 'text-green-accent-3'">
                              <v-icon start size="28">mdi-cash-plus</v-icon> Receitas
                           </h3>
                           <div class="text-h5 text-md-h4 font-weight-black mt-2 font-mono" :class="themeStore.currentMode === 'light' ? 'text-green-darken-3' : 'text-white'">{{ formatCurrency(dre.receitas.total) }}</div>
                           <div class="text-caption font-weight-bold text-primary cursor-pointer d-inline-flex align-center mt-2">
                               <v-icon size="14" class="mr-1">mdi-chart-donut</v-icon> Visão Macro (Grupos Raiz)
                           </div>
                       </div>

                       <div class="flex-grow-1 w-100 d-flex align-center justify-center pt-6 overflow-visible">
                           <apexchart
                               v-if="chartSeriesReceitas.length > 0"
                               type="donut"
                               height="100%"
                               width="100%"
                               :options="chartOptionsReceitas"
                               :series="chartSeriesReceitas"
                               @dataPointSelection="handleChartClick('receitas', $event)"
                               style="min-height: 350px;"
                            ></apexchart>
                           <div v-else class="d-flex flex-column align-center justify-center opacity-50 py-16">
                               <v-icon size="64" class="mb-2">mdi-chart-pie-outline</v-icon>
                               <span class="text-h6 font-weight-bold text-center">Sem receitas<br>no período</span>
                           </div>
                       </div>
                  </v-card>
              </v-col>

              <v-col cols="12" md="6" class="pa-2">
                  <v-card class="rounded-xl border-thin pa-4 pa-md-6 d-flex flex-column h-100 position-relative" :class="themeStore.currentMode === 'light' ? 'bg-white shadow-sm' : 'glass-card border-white-05'" elevation="0" :style="{ minHeight: mobile ? '450px' : '550px' }">

                       <div class="position-absolute" style="top: 16px; right: 16px; z-index: 20;">
                           <v-menu location="bottom end" :close-on-content-click="false">
                               <template v-slot:activator="{ props }">
                                   <v-btn v-bind="props" variant="tonal" :color="themeStore.currentMode === 'light' ? 'red-darken-3' : 'red-lighten-2'" class="font-weight-bold text-caption btn-3d" height="36" rounded="lg">
                                       <v-icon start size="18">mdi-format-list-bulleted</v-icon> Grupos Despesa
                                   </v-btn>
                               </template>
                               <v-card width="320" max-height="400" class="overflow-y-auto custom-scroll border-thin" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-glass-dark border-white-05 text-white'">
                                   <v-list density="compact" nav class="py-2" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-transparent'">
                                       <v-list-subheader class="font-weight-black" :class="themeStore.currentMode === 'light' ? 'text-red-darken-3' : 'text-red-lighten-2'">COMPOSIÇÃO MACRO</v-list-subheader>
                                       <v-list-item v-for="(leg, i) in despesasLegend" :key="i" class="border-b" :class="zebraClass(i)">
                                           <template v-slot:prepend><v-icon :color="leg.color" size="14" class="mr-2 opacity-80">mdi-circle</v-icon></template>
                                           <v-list-item-title class="text-caption font-weight-bold opacity-90 text-wrap">{{ leg.code }} - {{ leg.name }}</v-list-item-title>
                                           <template v-slot:append>
                                               <div class="text-right ml-2">
                                                   <div class="text-[11px] font-weight-black" :class="themeStore.currentMode === 'light' ? 'text-red-darken-2' : 'text-red-lighten-2'">{{ formatCurrency(leg.value) }}</div>
                                                   <div class="text-[10px] opacity-70 font-weight-bold">{{ leg.percent }}%</div>
                                               </div>
                                           </template>
                                       </v-list-item>
                                   </v-list>
                               </v-card>
                           </v-menu>
                       </div>

                       <div class="d-flex flex-column align-start mb-2 pr-16 flex-shrink-0">
                           <h3 class="text-h6 text-md-h5 font-weight-black d-flex align-center text-uppercase letter-spacing-1" :class="themeStore.currentMode === 'light' ? 'text-red-darken-2' : 'text-red-lighten-2'">
                              <v-icon start size="28">mdi-cash-minus</v-icon> Despesas
                           </h3>
                           <div class="text-h5 text-md-h4 font-weight-black mt-2 font-mono" :class="themeStore.currentMode === 'light' ? 'text-red-darken-3' : 'text-white'">- {{ formatCurrency(dre.despesas.total) }}</div>
                           <div class="text-caption font-weight-bold text-primary cursor-pointer d-inline-flex align-center mt-2">
                               <v-icon size="14" class="mr-1">mdi-chart-donut</v-icon> Visão Macro (Grupos Raiz)
                           </div>
                       </div>

                       <div class="flex-grow-1 w-100 d-flex align-center justify-center pt-6 overflow-visible">
                           <apexchart
                               v-if="chartSeriesDespesas.length > 0"
                               type="donut"
                               height="100%"
                               width="100%"
                               :options="chartOptionsDespesas"
                               :series="chartSeriesDespesas"
                               @dataPointSelection="handleChartClick('despesas', $event)"
                               style="min-height: 350px;"
                            ></apexchart>
                           <div v-else class="d-flex flex-column align-center justify-center opacity-50 py-16">
                               <v-icon size="64" class="mb-2">mdi-chart-pie-outline</v-icon>
                               <span class="text-h6 font-weight-bold text-center">Sem despesas<br>no período</span>
                           </div>
                       </div>
                  </v-card>
              </v-col>
          </v-row>

          <v-card class="rounded-xl border-thin pa-0 flex-shrink-0 mt-4 overflow-hidden" :class="themeStore.currentMode === 'light' ? 'bg-white shadow-sm' : 'glass-card border-white-05'" elevation="0">

              <div class="d-flex flex-column flex-md-row justify-space-between align-start align-md-end px-4 px-md-8 py-4 py-md-6 border-b" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-white-05 border-bottom-white-05'">
                  <div>
                      <h2 class="text-h5 text-md-h4 font-weight-black text-uppercase letter-spacing-1" :class="themeStore.currentMode === 'light' ? 'text-primary' : 'text-blue-lighten-2'">
                         Demonstração do Resultado
                      </h2>
                      <div class="text-caption text-md-body-2 font-weight-bold opacity-70 mt-2 d-flex align-center gap-2" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">
                          <v-icon size="16" color="primary">mdi-sitemap</v-icon>
                          Estrutura Baseada no Plano de Contas
                      </div>
                      <div class="text-caption text-md-body-2 font-weight-bold opacity-70 d-flex align-center gap-2 mt-1" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">
                          <v-icon size="16" color="primary">mdi-calendar-range</v-icon>
                          Período: {{ formatDate(filters.startDate) }} até {{ formatDate(filters.endDate) }}
                      </div>
                  </div>

                  <div class="text-left text-md-right mt-4 mt-md-0 w-100 w-md-auto">
                      <div class="text-caption font-weight-black opacity-70 text-uppercase mb-1" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">Margem Líquida da Operação</div>
                      <v-chip :color="dre.margem >= 0 ? 'success' : 'error'" class="font-weight-black text-h5 text-md-h4 px-6 shadow-sm border-thin py-4 py-md-6 w-100 justify-center chip-3d font-mono" variant="flat">
                          <v-icon start size="28" class="mr-2">{{ dre.margem >= 0 ? 'mdi-trending-up' : 'mdi-trending-down' }}</v-icon>
                          {{ dre.margem.toFixed(2) }}%
                      </v-chip>
                  </div>
              </div>

              <div class="w-100 overflow-x-auto pb-4 custom-scroll" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-transparent'">
                  <table class="dre-grid-table w-100" :class="themeStore.currentMode === 'light' ? 'theme-light' : 'theme-dark'">
                      <thead class="sticky-head" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-3' : 'bg-black-20'">
                          <tr>
                              <th class="text-left pl-4 pl-md-8" style="width: 60%;">ESTRUTURA DRE (PLANO DE CONTAS)</th>
                              <th class="text-right pr-4 pr-md-8" style="width: 25%;">VALOR (R$)</th>
                              <th class="text-right pr-4 pr-md-8" style="width: 15%;">AV (%)</th>
                          </tr>
                      </thead>
                      <tbody>
                          <tr class="group-row" :class="themeStore.currentMode === 'light' ? 'bg-green-lighten-5 text-green-darken-4' : 'bg-green-darken-4-alpha text-green-accent-3'">
                              <td class="font-weight-black pl-4 pl-md-8 text-subtitle-2 text-md-h6">1. RECEITAS</td>
                              <td class="font-weight-black text-right pr-4 pr-md-8 text-subtitle-2 text-md-h6 font-mono">{{ formatCurrency(dre.receitas.total) }}</td>
                              <td class="font-weight-black text-right pr-4 pr-md-8 text-subtitle-2 text-md-h6 font-mono">100.00%</td>
                          </tr>

                          <tr v-if="dre.receitas.items.length === 0">
                              <td colspan="3" class="text-center py-4 opacity-50 font-italic">Nenhuma receita localizada.</td>
                          </tr>

                          <tr v-for="(item, idx) in dre.receitas.items" :key="'rec-'+item.id" class="item-row transition-hover cursor-pointer" :class="[zebraClass(idx), themeStore.currentMode === 'light' ? 'text-grey-darken-3' : 'text-white-80']" @click="item.allRawItems.length > 0 ? openDetailsModal('receitas', item) : null">
                              <td class="opacity-90 d-flex align-center" :class="item.is_group ? 'font-weight-black' : 'font-weight-medium'" :style="{ paddingLeft: (32 + item.depth * 24) + 'px' }">
                                  {{ item.code }} - {{ item.name }}
                                  <v-icon v-if="item.allRawItems && item.allRawItems.length > 0" size="12" class="ml-2 opacity-50">mdi-open-in-new</v-icon>
                              </td>
                              <td class="text-right pr-4 pr-md-8 font-mono" :class="item.is_group ? 'font-weight-black' : 'font-weight-bold'">{{ formatCurrency(item.value) }}</td>
                              <td class="text-right pr-4 pr-md-8 font-mono" :class="[item.is_group ? 'font-weight-black' : 'font-weight-bold', themeStore.currentMode === 'light' ? 'text-grey-darken-1' : 'text-grey-lighten-1']">
                                  {{ dre.receitas.total ? ((item.value / dre.receitas.total) * 100).toFixed(2) : '0.00' }}%
                              </td>
                          </tr>

                          <tr><td colspan="3" style="height: 20px; border: none; background: transparent;"></td></tr>

                          <tr class="group-row" :class="themeStore.currentMode === 'light' ? 'bg-red-lighten-5 text-red-darken-4' : 'bg-red-darken-4-alpha text-red-lighten-2'">
                              <td class="font-weight-black pl-4 pl-md-8 text-subtitle-2 text-md-h6">2. CUSTOS E DESPESAS</td>
                              <td class="font-weight-black text-right pr-4 pr-md-8 text-subtitle-2 text-md-h6 font-mono">- {{ formatCurrency(dre.despesas.total) }}</td>
                              <td class="font-weight-black text-right pr-4 pr-md-8 text-subtitle-2 text-md-h6 font-mono">{{ dre.receitas.total ? ((dre.despesas.total / dre.receitas.total) * 100).toFixed(2) : '0.00' }}%</td>
                          </tr>

                          <tr v-if="dre.despesas.items.length === 0">
                              <td colspan="3" class="text-center py-4 opacity-50 font-italic">Nenhuma despesa localizada.</td>
                          </tr>

                          <tr v-for="(item, idx) in dre.despesas.items" :key="'pay-'+item.id" class="item-row transition-hover cursor-pointer" :class="[zebraClass(idx), themeStore.currentMode === 'light' ? 'text-red-darken-3' : 'text-red-lighten-3']" @click="item.allRawItems.length > 0 ? openDetailsModal('despesas', item) : null">
                              <td class="opacity-90 d-flex align-center" :class="item.is_group ? 'font-weight-black' : 'font-weight-medium'" :style="{ paddingLeft: (32 + item.depth * 24) + 'px' }">
                                  {{ item.code }} - {{ item.name }}
                                  <v-icon v-if="item.allRawItems && item.allRawItems.length > 0" size="12" class="ml-2 opacity-50">mdi-open-in-new</v-icon>
                              </td>
                              <td class="text-right pr-4 pr-md-8 font-mono" :class="item.is_group ? 'font-weight-black' : 'font-weight-bold'">- {{ formatCurrency(item.value) }}</td>
                              <td class="text-right pr-4 pr-md-8 font-mono" :class="[item.is_group ? 'font-weight-black' : 'font-weight-bold', themeStore.currentMode === 'light' ? 'text-grey-darken-1' : 'text-grey-lighten-1']">
                                  {{ dre.receitas.total ? ((item.value / dre.receitas.total) * 100).toFixed(2) : '0.00' }}%
                              </td>
                          </tr>

                          <tr><td colspan="3" style="height: 30px; border: none; background: transparent;"></td></tr>

                      </tbody>
                      <tfoot>
                          <tr class="result-row" :class="dre.resultado >= 0 ? (themeStore.currentMode === 'light' ? 'bg-success text-white' : 'bg-green-darken-3 text-white') : (themeStore.currentMode === 'light' ? 'bg-error text-white' : 'bg-red-darken-4 text-white')">
                              <td class="font-weight-black text-subtitle-1 text-md-h5 text-uppercase letter-spacing-1 pl-4 pl-md-8 py-4 py-md-6 border-0">3. RESULTADO LÍQUIDO DO EXERCÍCIO</td>
                              <td class="font-weight-black font-mono text-h6 text-md-h4 text-right pr-4 pr-md-8 py-4 py-md-6 border-0">{{ formatCurrency(dre.resultado) }}</td>
                              <td class="font-weight-black font-mono text-h6 text-md-h5 text-right pr-4 pr-md-8 py-4 py-md-6 border-0">{{ dre.margem.toFixed(2) }}%</td>
                          </tr>
                      </tfoot>
                  </table>
              </div>
          </v-card>
      </div>
    </div>

    <v-dialog v-model="detailsModal.show" max-width="1100" :fullscreen="mobile" persistent scrollable>
        <v-card class="rounded-xl overflow-hidden d-flex flex-column relative" :height="mobile ? '100%' : '85vh'" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-4' : 'glass-card border-white-05'">

            <div class="px-4 px-md-6 py-3 py-md-4 d-flex justify-space-between align-center border-b flex-shrink-0" :class="[themeStore.currentMode === 'light' ? 'bg-white' : 'bg-glass-header border-bottom-white-05', detailsModal.type === 'receitas' ? (themeStore.currentMode === 'light' ? 'border-green-lighten-3' : 'border-green-darken-3') : (themeStore.currentMode === 'light' ? 'border-red-lighten-3' : 'border-red-darken-3')]">
                <div class="d-flex align-center gap-2 gap-md-3" :class="detailsModal.type === 'receitas' ? (themeStore.currentMode === 'light' ? 'text-green-darken-3' : 'text-green-accent-3') : (themeStore.currentMode === 'light' ? 'text-red-darken-3' : 'text-red-lighten-2')">
                    <v-icon :size="mobile ? 24 : 32">{{ detailsModal.type === 'receitas' ? 'mdi-cash-plus' : 'mdi-cash-minus' }}</v-icon>
                    <div>
                        <div class="text-[10px] text-md-caption font-weight-bold text-uppercase opacity-70">Lançamentos Vinculados</div>
                        <div class="text-subtitle-1 text-md-h5 font-weight-black lh-1 text-truncate" :style="mobile ? 'max-width: 200px;' : ''">{{ detailsModal.title }}</div>
                    </div>
                </div>
                <v-btn icon="mdi-close" variant="text" @click="detailsModal.show = false" :color="themeStore.currentMode === 'light' ? 'grey-darken-3' : 'white'"></v-btn>
            </div>

            <div class="px-4 px-md-6 py-3 py-md-4 d-flex flex-column flex-md-row gap-3 flex-shrink-0 border-b shadow-sm" style="z-index: 5;" :class="themeStore.currentMode === 'light' ? 'bg-white border-grey-lighten-3' : 'bg-white-05 border-bottom-white-05'">
                 <div class="pa-2 pa-md-3 rounded-lg border flex-grow-1" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 border-grey-lighten-3 text-grey-darken-4' : 'bg-white-05 border-white-10 text-white'">
                     <div class="text-[10px] text-md-caption opacity-70 font-weight-bold text-uppercase">Soma Consolidada (Plano)</div>
                     <div class="text-subtitle-1 text-md-h6 font-weight-black">{{ formatCurrency(detailsModal.total) }}</div>
                 </div>
                 <div class="pa-2 pa-md-3 rounded-lg border flex-grow-1" :class="detailsModal.type === 'receitas' ? (themeStore.currentMode === 'light' ? 'bg-green-lighten-5 border-green-lighten-4 text-green-darken-4' : 'bg-green-darken-4-alpha border-green-darken-3 text-green-accent-2') : (themeStore.currentMode === 'light' ? 'bg-red-lighten-5 border-red-lighten-4 text-red-darken-4' : 'bg-red-darken-4-alpha border-red-darken-3 text-red-lighten-2')">
                     <div class="text-[10px] text-md-caption font-weight-bold text-uppercase">{{ detailsModal.type === 'receitas' ? 'Já Recebido' : 'Já Pago' }}</div>
                     <div class="text-subtitle-1 text-md-h6 font-weight-black">{{ formatCurrency(detailsModal.pago) }}</div>
                 </div>
                 <div class="pa-2 pa-md-3 rounded-lg border flex-grow-1" :class="themeStore.currentMode === 'light' ? 'bg-orange-lighten-5 border-orange-lighten-4 text-orange-darken-4' : 'bg-orange-darken-4-alpha border-orange-darken-3 text-orange-accent-2'">
                     <div class="text-[10px] text-md-caption font-weight-bold text-uppercase">Pendente / Atrasado</div>
                     <div class="text-subtitle-1 text-md-h6 font-weight-black">{{ formatCurrency(detailsModal.pendente) }}</div>
                 </div>
            </div>

            <div class="flex-grow-1 overflow-y-auto overflow-x-auto custom-scroll relative" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-transparent'">
                <table class="dre-grid-table w-100" style="min-width: 850px;" :class="themeStore.currentMode === 'light' ? 'theme-light' : 'theme-dark'">
                    <thead class="sticky-head" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-3' : 'bg-white-05'">
                        <tr>
                            <th class="text-center" style="width: 50px; padding-left: 8px;">
                                <v-checkbox-btn :model-value="areAllSelected" @update:model-value="toggleSelectAll" color="primary"></v-checkbox-btn>
                            </th>
                            <th class="text-center" style="width: 100px;">Data</th>
                            <th class="text-center" style="width: 100px;">Ref/Doc</th>
                            <th class="text-left">Descrição</th>
                            <th class="text-left">{{ detailsModal.type === 'receitas' ? 'Cliente' : 'Fornecedor' }}</th>
                            <th class="text-center" style="width: 120px;">Status</th>
                            <th class="text-right" style="width: 140px;">Valor Líquido</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr v-if="detailsModal.items.length === 0">
                            <td colspan="7" class="text-center py-8 text-grey font-italic">Nenhum lançamento detalhado encontrado.</td>
                        </tr>
                        <tr v-for="(item, index) in detailsModal.items" :key="item.id" class="item-row transition-hover" :class="zebraClass(index)">
                            <td class="text-center" @click.stop style="padding-left: 8px;">
                                <v-checkbox-btn :model-value="bulkEdit.selectedIds.has(item.id)" @update:model-value="toggleSelection(item.id)" color="primary"></v-checkbox-btn>
                            </td>
                            <td class="text-center font-mono text-caption">{{ formatDateSafe(getDateValue(item)) }}</td>
                            <td class="text-center font-mono text-caption font-weight-bold opacity-80">{{ getRefNumber(item) }}</td>
                            <td class="text-caption font-weight-medium text-truncate" style="max-width: 250px;" :title="item.description">{{ item.description || '-' }}</td>
                            <td class="text-caption text-truncate" style="max-width: 200px;">{{ getEntityName(item) }}</td>
                            <td class="text-center">
                                <v-chip size="small" class="font-weight-black text-uppercase chip-3d" :color="getStatusLabel(item) === 'PAGO' || getStatusLabel(item) === 'RECEBIDO' ? 'success' : 'warning'" variant="flat">
                                    {{ getStatusLabel(item) }}
                                </v-chip>
                            </td>
                            <td class="text-right font-mono font-weight-black" :class="detailsModal.type === 'receitas' ? (themeStore.currentMode === 'light' ? 'text-success' : 'text-green-accent-3') : (themeStore.currentMode === 'light' ? 'text-error' : 'text-red-lighten-2')">
                                {{ formatCurrency((Number(item.value || item.valor) || 0) - (Number(item.discount) || 0)) }}
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>

            <v-scale-transition origin="bottom center">
                <div v-if="bulkEdit.selectedIds.size > 0" class="selection-island-wrapper position-absolute" style="bottom: 30px; left: 0; right: 0; z-index: 100; pointer-events: none; display: flex; justify-content: center;">
                    <div class="selection-island elevation-10" style="pointer-events: auto; background: #1e1e24; border-radius: 12px; padding: 12px 20px; display: flex; align-items: center; gap: 12px; border: 1px solid rgba(255,255,255,0.1);">
                        <span class="text-white font-weight-bold mr-2">{{ bulkEdit.selectedIds.size }} itens selecionados</span>
                        <v-btn color="primary" variant="flat" size="small" class="btn-3d font-weight-bold" @click="bulkEdit.showModal = true">Definir Categoria</v-btn>
                        <v-btn icon="mdi-close" variant="text" size="small" color="white" @click="bulkEdit.selectedIds.clear()"></v-btn>
                    </div>
                </div>
            </v-scale-transition>
        </v-card>
    </v-dialog>

    <v-dialog v-model="bulkEdit.showModal" max-width="500">
        <v-card class="rounded-xl overflow-hidden" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-glass-dark border-white-05 text-white'">
            <div class="pa-4 border-b d-flex align-center justify-space-between bg-primary text-white">
                <div class="font-weight-black text-subtitle-1">Definir Categoria em Massa</div>
                <v-btn icon="mdi-close" variant="text" size="small" @click="bulkEdit.showModal = false"></v-btn>
            </div>
            <v-card-text class="pa-6">
                <p class="text-body-2 mb-4 font-weight-medium" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-3' : 'text-white-80'">Selecione o plano de contas para os <strong>{{ bulkEdit.selectedIds.size }}</strong> itens selecionados.</p>
                <v-autocomplete
                    v-model="bulkEdit.chartId"
                    :items="auxData.chartOfAccounts.filter(c => c.type === (detailsModal.type === 'receitas' ? 'Receita' : 'Despesa'))"
                    item-title="name"
                    item-value="id"
                    label="Plano de Contas"
                    variant="outlined"
                    density="comfortable"
                    hide-details
                    class="ui-field"
                    :bg-color="themeStore.currentMode === 'light' ? 'white' : 'rgba(0,0,0,0.2)'"
                ></v-autocomplete>
            </v-card-text>
            <v-card-actions class="pa-4 border-t d-flex justify-end gap-3" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5' : 'bg-white-05'">
                <v-btn variant="outlined" class="btn-3d font-weight-bold" @click="bulkEdit.showModal = false" :color="themeStore.currentMode === 'light' ? 'grey-darken-2' : 'white'">Cancelar</v-btn>
                <v-btn color="primary" variant="flat" class="btn-3d px-6 font-weight-black" :loading="bulkEdit.loading" :disabled="!bulkEdit.chartId" @click="executeBulkEdit">Aplicar</v-btn>
            </v-card-actions>
        </v-card>
    </v-dialog>

  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted, watch } from 'vue';
import { useDisplay } from 'vuetify';
import { supabase } from '@/api/supabase';
import { useAppStore } from '@/stores/app';
import { useUserStore } from '@/stores/user';
import { useThemeStore } from '@/stores/theme';
import { useCompanyStore } from '@/stores/company';
import { format, parseISO, startOfMonth, endOfMonth, isBefore, startOfDay } from 'date-fns';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';

import logoMjlm from '@/assets/logomjlm.png';
import logoCajuia from '@/assets/logocajuia.png';

const { mobile } = useDisplay();
const appStore = useAppStore();
const userStore = useUserStore();
const themeStore = useThemeStore();
const companyStore = useCompanyStore();

const now = new Date();
const firstDay = format(startOfMonth(now), 'yyyy-MM-dd');
const lastDay = format(endOfMonth(now), 'yyyy-MM-dd');

const loading = ref(false);
const mobileFiltersOpen = ref(false);
const companies = ref<any[]>([]);

const isPrivacyMode = ref(false);
const realDreData = ref<any>(null);

const auxData = reactive({
    chartOfAccounts: [] as any[]
});

const filters = reactive({
    startDate: firstDay,
    endDate: lastDay,
    regime: 'caixa' as 'caixa' | 'competencia',
    companyId: null as any
});

const setCompanyFilter = (id: string | null) => {
    filters.companyId = id;
    fetchData();
};

const dre = reactive({
    receitas: { total: 0, items: [] as any[] },
    despesas: { total: 0, items: [] as any[] },
    resultado: 0,
    margem: 0
});

const detailsModal = reactive({
    show: false,
    title: '',
    type: 'receitas' as 'receitas' | 'despesas',
    total: 0,
    pago: 0,
    pendente: 0,
    items: [] as any[]
});

const bulkEdit = reactive({
    showModal: false,
    selectedIds: new Set<string>(),
    chartId: null as any,
    loading: false
});

const areAllSelected = computed(() => detailsModal.items.length > 0 && bulkEdit.selectedIds.size === detailsModal.items.length);
const toggleSelectAll = (val: boolean) => {
    if (val) detailsModal.items.forEach(i => bulkEdit.selectedIds.add(i.id));
    else bulkEdit.selectedIds.clear();
};
const toggleSelection = (id: string) => {
    if (bulkEdit.selectedIds.has(id)) bulkEdit.selectedIds.delete(id);
    else bulkEdit.selectedIds.add(id);
};

const executeBulkEdit = async () => {
    if (!bulkEdit.chartId || bulkEdit.selectedIds.size === 0) return;

    if (isPrivacyMode.value) {
        appStore.showSnackbar('Ações não permitidas no Modo Fantasma.', 'warning');
        return;
    }

    bulkEdit.loading = true;
    try {
        const table = detailsModal.type === 'receitas' ? 'finance_receivables' : 'finance_payables';
        const ids = Array.from(bulkEdit.selectedIds);
        const { error } = await supabase.from(table).update({ chart_of_accounts_id: bulkEdit.chartId }).in('id', ids);

        if (error) throw error;

        appStore.showSnackbar('Plano de contas atualizado com sucesso!', 'success');
        bulkEdit.showModal = false;
        bulkEdit.selectedIds.clear();
        detailsModal.show = false;
        fetchData();
    } catch (e: any) {
        appStore.showSnackbar('Erro ao atualizar: ' + e.message, 'error');
    } finally {
        bulkEdit.loading = false;
    }
};

const zebraClass = (i: number) => themeStore.currentMode === 'light' ? (i % 2 === 0 ? 'zebra-light-a' : 'zebra-light-b') : (i % 2 === 0 ? 'zebra-dark-a' : 'zebra-dark-b');

const chartColors = ['#008FFB', '#00E396', '#FEB019', '#FF4560', '#775DD0', '#3F51B5', '#03A9F4', '#4CAF50', '#F9CE1D', '#FF9800', '#33B2DF', '#546E7A', '#D4526E', '#13D8AA', '#A5978B', '#2B908F', '#F9A3A4', '#90EE7E', '#FA4443', '#69D2E7', '#C5D86D', '#46AF78', '#A93F55', '#8C5E58', '#2176FF', '#33A1FD', '#7A918D', '#BAFF29'];
const isDark = computed(() => themeStore.currentMode !== 'light');
const chartFontFamily = "'Segoe UI', Tahoma, Geneva, Verdana, sans-serif";

const topLevelReceitas = computed(() => dre.receitas.items.filter((i: any) => i.depth === 0));
const topLevelDespesas = computed(() => dre.despesas.items.filter((i: any) => i.depth === 0));

const receitasLegend = computed(() => {
    return topLevelReceitas.value.map((item: any, idx: number) => {
        const pct = dre.receitas.total ? ((item.value / dre.receitas.total) * 100).toFixed(1) : '0.0';
        return { ...item, percent: pct, color: chartColors[idx % chartColors.length] };
    });
});

const despesasLegend = computed(() => {
    const revColors = [...chartColors].reverse();
    return topLevelDespesas.value.map((item: any, idx: number) => {
        const pct = dre.despesas.total ? ((item.value / dre.despesas.total) * 100).toFixed(1) : '0.0';
        return { ...item, percent: pct, color: revColors[idx % revColors.length] };
    });
});

const chartOptionsReceitas = computed(() => ({
    chart: { type: 'donut', background: 'transparent', fontFamily: chartFontFamily },
    labels: topLevelReceitas.value.map((i: any) => `${i.code} - ${i.name}`),
    theme: { mode: isDark.value ? 'dark' : 'light' },
    colors: chartColors,
    dataLabels: { enabled: false },
    stroke: { width: 2, colors: isDark.value ? ['#1e1e24'] : ['#ffffff'] },
    plotOptions: {
        pie: {
            customScale: 1.0,
            donut: {
                size: '70%',
                labels: {
                    show: true,
                    name: { fontSize: '13px', fontWeight: 600, color: isDark.value ? '#aaa' : '#666', offsetY: -5 },
                    value: { fontSize: mobile.value ? '20px' : '26px', fontWeight: 900, color: isDark.value ? '#fff' : '#333', offsetY: 5, formatter: (val: number) => formatCurrency(Number(val)) },
                    total: { show: true, showAlways: true, label: 'TOTAL', fontSize: '12px', fontWeight: 900, color: isDark.value ? '#aaa' : '#666', formatter: () => formatCurrency(dre.receitas.total) }
                }
            }
        }
    },
    legend: { show: false },
    tooltip: { theme: isDark.value ? 'dark' : 'light', y: { formatter: (val: number) => formatCurrency(val) } }
}));

const chartSeriesReceitas = computed(() => topLevelReceitas.value.map((i: any) => i.value));

const chartOptionsDespesas = computed(() => ({
    chart: { type: 'donut', background: 'transparent', fontFamily: chartFontFamily },
    labels: topLevelDespesas.value.map((i: any) => `${i.code} - ${i.name}`),
    theme: { mode: isDark.value ? 'dark' : 'light' },
    colors: [...chartColors].reverse(),
    dataLabels: { enabled: false },
    stroke: { width: 2, colors: isDark.value ? ['#1e1e24'] : ['#ffffff'] },
    plotOptions: {
        pie: {
            customScale: 1.0,
            donut: {
                size: '70%',
                labels: {
                    show: true,
                    name: { fontSize: '13px', fontWeight: 600, color: isDark.value ? '#aaa' : '#666', offsetY: -5 },
                    value: { fontSize: mobile.value ? '20px' : '26px', fontWeight: 900, color: isDark.value ? '#fff' : '#333', offsetY: 5, formatter: (val: number) => formatCurrency(Number(val)) },
                    total: { show: true, showAlways: true, label: 'TOTAL', fontSize: '12px', fontWeight: 900, color: isDark.value ? '#aaa' : '#666', formatter: () => formatCurrency(dre.despesas.total) }
                }
            }
        }
    },
    legend: { show: false },
    tooltip: { theme: isDark.value ? 'dark' : 'light', y: { formatter: (val: number) => formatCurrency(val) } }
}));

const chartSeriesDespesas = computed(() => topLevelDespesas.value.map((i: any) => i.value));

// =========================================================================

const formatCurrency = (v: any) => new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(Number(v)||0);

// Aqui será resolvido dinamicamente com base no estado atual do filters.regime
const getDateValue = (item: any) => {
    // Correção: Como a UI envia Caixa, mas a lógica pedida era inversão:
    const isCaixa = filters.regime === 'caixa';
    return isCaixa ? item.due_date : (item.payment_date || item.created_at);
};

const formatDateSafe = (dateString: string) => {
    if (!dateString) return '-';
    try { return format(parseISO(dateString), 'dd/MM/yyyy'); } catch { return dateString; }
};
const formatDate = formatDateSafe;

const getRefNumber = (item: any) => item.document_number || item.order_number || item.gestao_click_id || (item.id ? String(item.id).slice(0, 4).toUpperCase() : '-');
const getEntityName = (item: any) => item.customer_name || item.cliente || item.supplier_name || item.fornecedor || item.entity_name || '-';

const getStatusLabel = (item: any) => {
    const status = String(item.status || '').toUpperCase();
    if (status === 'PAGO' || status === 'RECEBIDO') return status;
    const itemDate = getDateValue(item) || item.due_date || item.created_at;
    if (isBefore(parseISO(itemDate), startOfDay(new Date()))) return 'ATRASADO';
    return 'PENDENTE';
};

const fetchAuxiliaryData = async () => {
    try {
        const { data: comp } = await supabase.from('companies').select('id, trade_name, name');
        if (comp) companies.value = comp;

        const { data: chartData } = await supabase
            .from('finance_chart_of_accounts')
            .select('id, parent_id, code, name, type, is_group')
            .order('code', { ascending: true });

        if (chartData) auxData.chartOfAccounts = chartData;
    } catch (e) { console.error(e); }
};

const togglePrivacyMode = () => {
    // ... mantido o código de demonstração fictícia inalterado
    isPrivacyMode.value = !isPrivacyMode.value;
    if (isPrivacyMode.value) {
        realDreData.value = JSON.parse(JSON.stringify(dre));
        dre.receitas.total = 350000.00;
        dre.receitas.items = [
            { name: 'Venda de Produtos', code: '1.1', depth: 0, is_group: true, value: 250000.00, allRawItems: [] },
            { name: 'Prestação de Serviços', code: '1.2', depth: 0, is_group: true, value: 100000.00, allRawItems: [] }
        ];
        dre.despesas.total = 180000.00;
        dre.despesas.items = [
            { name: 'Fornecedores e Insumos', code: '2.1', depth: 0, is_group: true, value: 80000.00, allRawItems: [] },
            { name: 'Folha de Pagamento', code: '2.2', depth: 0, is_group: true, value: 50000.00, allRawItems: [] }
        ];
        dre.resultado = dre.receitas.total - dre.despesas.total;
        dre.margem = (dre.resultado / dre.receitas.total) * 100;
        if (detailsModal.show) detailsModal.show = false;
    } else {
        if (realDreData.value) {
            dre.receitas = realDreData.value.receitas;
            dre.despesas = realDreData.value.despesas;
            dre.resultado = realDreData.value.resultado;
            dre.margem = realDreData.value.margem;
        }
    }
};

// Algoritmo Central de Agregação de Contas em Árvore
const fetchData = async () => {
    isPrivacyMode.value = false;
    loading.value = true;
    try {
        const accTotals: Record<string, any> = {};
        const codeMap: Record<string, string> = {};

        // 1. Inicializa os mapas e a referência por código
        auxData.chartOfAccounts.forEach(acc => {
            accTotals[acc.id] = { ...acc, value: 0, rawItems: [], allRawItems: [] };
            if (acc.code) codeMap[acc.code.trim()] = acc.id;
        });

        // 2. Agregação à Prova de Falhas (Sobe pelo parent_id ou pelo corte do código)
        const addValueToAccount = (accId: string, item: any, val: number) => {
            let currNode = accTotals[accId];
            if (!currNode) return;

            currNode.rawItems.push(item);

            let idToUpdate: string | null = accId;
            const visited = new Set<string>();

            // Sobe espalhando o valor para os grupos superiores
            while (idToUpdate && accTotals[idToUpdate] && !visited.has(idToUpdate)) {
                visited.add(idToUpdate);
                const node = accTotals[idToUpdate];

                node.value += val;
                node.allRawItems.push(item);

                let nextId = node.parent_id;

                // Se o parent_id falhar, descobre o ID do pai quebrando o código (ex: 2.01.002 -> 2.01)
                if (!nextId && node.code && node.code.includes('.')) {
                    const parts = node.code.split('.');
                    parts.pop();
                    const parentCode = parts.join('.');
                    if (codeMap[parentCode]) {
                        nextId = codeMap[parentCode];
                    }
                }

                idToUpdate = nextId;
            }
        };

        // --- CORREÇÃO DE REGIME ---
        const isCaixa = filters.regime === 'caixa';
        const dateFieldPay = isCaixa ? 'due_date' : 'payment_date';
        const dateFieldRec = isCaixa ? 'due_date' : 'payment_date';

        // CORREÇÃO DO ERRO 400 ENUM: O banco só aceita 'pago' minúsculo
        const statusValuesPay = isCaixa ? null : ['pago'];
        const statusValuesRec = isCaixa ? null : ['pago'];

        let targetCompany = null;
        if (!companyStore.isGlobalView && companyStore.context) targetCompany = companyStore.context;
        if (filters.companyId) targetCompany = filters.companyId;

        let reqRec = supabase.from('finance_receivables').select('*').gte(dateFieldRec, filters.startDate).lte(dateFieldRec, filters.endDate);
        if (statusValuesRec) reqRec = reqRec.in('status', statusValuesRec);
        if (targetCompany) reqRec = reqRec.eq('company_id', targetCompany);

        let reqPay = supabase.from('finance_payables').select('*').gte(dateFieldPay, filters.startDate).lte(dateFieldPay, filters.endDate);
        if (statusValuesPay) reqPay = reqPay.in('status', statusValuesPay);
        if (targetCompany) reqPay = reqPay.eq('company_id', targetCompany);

        const [resRec, resPay] = await Promise.all([reqRec, reqPay]);

        if (resRec.error) throw resRec.error;
        if (resPay.error) throw resPay.error;

        let totalRec = 0;
        let uncatRecItems: any[] = [];
        let uncatRecTotal = 0;

        (resRec.data || []).forEach(r => {
            const val = Number(r.value || r.valor || 0) - Number(r.discount || 0);
            if (r.chart_of_accounts_id && accTotals[r.chart_of_accounts_id]) {
                addValueToAccount(r.chart_of_accounts_id, r, val);
            } else {
                uncatRecTotal += val;
                uncatRecItems.push(r);
            }
            totalRec += val;
        });

        let totalPay = 0;
        let uncatPayItems: any[] = [];
        let uncatPayTotal = 0;

        (resPay.data || []).forEach(p => {
            const val = Number(p.value || p.valor || 0) - Number(p.discount || 0);
            if (p.chart_of_accounts_id && accTotals[p.chart_of_accounts_id]) {
                addValueToAccount(p.chart_of_accounts_id, p, val);
            } else {
                uncatPayTotal += val;
                uncatPayItems.push(p);
            }
            totalPay += val;
        });

        // 3. Monta a lista achatada para exibição (Ordenação Rígida por Código)
        const buildFlatTree = (typeFilter: string) => {
            const activeNodes = Object.values(accTotals).filter((node: any) => node.type === typeFilter && node.value > 0);

            // Ordena o array completamente baseado no código string (Ex: '2.01.001' vem antes de '2.01.002')
            activeNodes.sort((a: any, b: any) => {
                const codeA = String(a.code || 'Z').trim();
                const codeB = String(b.code || 'Z').trim();
                return codeA.localeCompare(codeB, undefined, { numeric: true, sensitivity: 'base' });
            });

            // Aplica a profundidade de recuo com base na contagem de pontos '.'
            return activeNodes.map((node: any) => {
                let depth = 0;
                if (node.code && !node.code.toLowerCase().startsWith('erp')) {
                    depth = (node.code.match(/\./g) || []).length;
                }
                return {
                    ...node,
                    depth
                };
            });
        };

        const recItems = buildFlatTree('Receita');
        if (uncatRecTotal > 0) {
            recItems.push({
                id: 'uncat-rec', name: 'Receitas Não Categorizadas', code: 'S/C', is_group: false, depth: 0,
                value: uncatRecTotal, rawItems: uncatRecItems, allRawItems: uncatRecItems
            });
        }

        const payItems = buildFlatTree('Despesa');
        if (uncatPayTotal > 0) {
            payItems.push({
                id: 'uncat-pay', name: 'Despesas Não Categorizadas', code: 'S/C', is_group: false, depth: 0,
                value: uncatPayTotal, rawItems: uncatPayItems, allRawItems: uncatPayItems
            });
        }

        dre.receitas.total = totalRec;
        dre.receitas.items = recItems;

        dre.despesas.total = totalPay;
        dre.despesas.items = payItems;

        dre.resultado = totalRec - totalPay;
        dre.margem = totalRec > 0 ? (dre.resultado / totalRec) * 100 : 0;

    } catch (e: any) {
        console.error("Erro DRE:", e);
        appStore.showSnackbar("Falha estrutural ao compilar o DRE.", "error");
    } finally {
        loading.value = false;
    }
};

const handleChartClick = (type: 'receitas' | 'despesas', e: any) => {
    let index = -1;
    if (typeof e === 'number') index = e;
    else if (e && e.dataPointIndex !== undefined) index = e.dataPointIndex;
    else if (arguments.length >= 3 && arguments[2]?.dataPointIndex !== undefined) index = arguments[2].dataPointIndex;

    if (index === -1) return;

    const topLevelList = type === 'receitas' ? topLevelReceitas.value : topLevelDespesas.value;
    const item = topLevelList[index];

    if (item && item.allRawItems.length > 0) openDetailsModal(type, item);
};

const openDetailsModal = (type: 'receitas' | 'despesas', item: any) => {
    bulkEdit.selectedIds.clear();
    detailsModal.type = type;
    detailsModal.title = item.name;
    detailsModal.total = item.value;

    const rawList = item.allRawItems || [];
    const sortedItems = [...rawList].sort((a,b) => new Date(getDateValue(b) || new Date()).getTime() - new Date(getDateValue(a) || new Date()).getTime());
    detailsModal.items = sortedItems;

    let pagoCalc = 0;
    let pendenteCalc = 0;

    sortedItems.forEach(i => {
        const v = (Number(i.value || i.valor) || 0) - (Number(i.discount) || 0);
        const st = getStatusLabel(i);
        if (st === 'RECEBIDO' || st === 'PAGO') pagoCalc += v;
        else pendenteCalc += v;
    });

    detailsModal.pago = pagoCalc;
    detailsModal.pendente = pendenteCalc;
    detailsModal.show = true;
};

watch(() => companyStore.context, () => { fetchData(); });

// =========================================================================
// IMPRESSÃO E EXPORTAÇÃO (PDF E EXCEL)
// =========================================================================

// Função dedicada para exportar de forma profissional ao Excel (.xls usando HTML nativo do Office)
const generateExcelExport = () => {
    if (dre.receitas.total === 0 && dre.despesas.total === 0) {
        return appStore.showSnackbar("Não há dados contábeis no período selecionado.", "warning");
    }

    const regimeLabel = filters.regime === 'caixa' ? 'Regime de Caixa (Efetivamente Recebido/Pago)' : 'Regime de Competência (Provisão/Vencimento)';

    let html = `<html xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:x="urn:schemas-microsoft-com:office:excel" xmlns="http://www.w3.org/TR/REC-html40">
    <head><meta charset="UTF-8"></head><body>`;
    html += `<table border="1" style="font-family: Arial, sans-serif; border-collapse: collapse; font-size: 13px;">`;

    // Cabeçalho Principal
    html += `<tr><th colspan="3" style="font-size: 18px; font-weight: bold; background-color: #E8F0FE; color: #1976D2; height: 50px; vertical-align: middle;">DRE GERENCIAL ANALÍTICO</th></tr>`;
    html += `<tr><td colspan="3" style="background-color: #F8F9FA;"><b>Empresa:</b> ${companyStore.currentCompanyName.toUpperCase()}</td></tr>`;
    html += `<tr><td colspan="3" style="background-color: #F8F9FA;"><b>Período:</b> ${formatDate(filters.startDate)} a ${formatDate(filters.endDate)}</td></tr>`;
    html += `<tr><td colspan="3" style="background-color: #F8F9FA;"><b>Método:</b> ${regimeLabel}</td></tr>`;
    html += `<tr><td colspan="3" style="height: 15px; border: none;"></td></tr>`;

    // Colunas da Tabela
    html += `<tr>
        <th style="background-color: #333333; color: #FFFFFF; width: 450px;">ESTRUTURA DRE (PLANO DE CONTAS)</th>
        <th style="background-color: #333333; color: #FFFFFF; width: 150px;">VALOR (R$)</th>
        <th style="background-color: #333333; color: #FFFFFF; width: 100px;">AV (%)</th>
    </tr>`;

    // Bloco: RECEITAS
    html += `<tr>
        <td style="font-weight: bold; background-color: #E8F5E9; color: #1B5E20; font-size: 14px;">1. RECEITAS</td>
        <td style="font-weight: bold; background-color: #E8F5E9; color: #1B5E20; font-size: 14px;">${dre.receitas.total.toLocaleString('pt-BR', { minimumFractionDigits: 2 })}</td>
        <td style="font-weight: bold; background-color: #E8F5E9; color: #1B5E20; font-size: 14px;">100,00%</td>
    </tr>`;

    dre.receitas.items.forEach((i: any) => {
        const av = dre.receitas.total ? ((i.value / dre.receitas.total) * 100).toFixed(2).replace('.', ',') : '0,00';
        const fw = i.is_group ? 'bold' : 'normal';
        // Espaçamento do recuo é emulado via &nbsp; para funcionar impecavelmente no Excel
        const indent = "&nbsp;&nbsp;&nbsp;&nbsp;".repeat(i.depth);
        html += `<tr>
            <td style="font-weight: ${fw};">${indent}${i.code} - ${i.name}</td>
            <td style="font-weight: ${fw};">${i.value.toLocaleString('pt-BR', { minimumFractionDigits: 2 })}</td>
            <td style="color: #666666;">${av}%</td>
        </tr>`;
    });

    html += `<tr><td colspan="3" style="height: 15px; border: none;"></td></tr>`;

    // Bloco: DESPESAS
    const despesasAv = dre.receitas.total ? ((dre.despesas.total / dre.receitas.total) * 100).toFixed(2).replace('.', ',') : '0,00';
    html += `<tr>
        <td style="font-weight: bold; background-color: #FFEBEE; color: #B71C1C; font-size: 14px;">2. CUSTOS E DESPESAS</td>
        <td style="font-weight: bold; background-color: #FFEBEE; color: #B71C1C; font-size: 14px;">-${dre.despesas.total.toLocaleString('pt-BR', { minimumFractionDigits: 2 })}</td>
        <td style="font-weight: bold; background-color: #FFEBEE; color: #B71C1C; font-size: 14px;">${despesasAv}%</td>
    </tr>`;

    dre.despesas.items.forEach((i: any) => {
        const av = dre.receitas.total ? ((i.value / dre.receitas.total) * 100).toFixed(2).replace('.', ',') : '0,00';
        const fw = i.is_group ? 'bold' : 'normal';
        const indent = "&nbsp;&nbsp;&nbsp;&nbsp;".repeat(i.depth);
        html += `<tr>
            <td style="font-weight: ${fw}; color: #B71C1C;">${indent}${i.code} - ${i.name}</td>
            <td style="font-weight: ${fw}; color: #B71C1C;">-${i.value.toLocaleString('pt-BR', { minimumFractionDigits: 2 })}</td>
            <td style="color: #666666;">${av}%</td>
        </tr>`;
    });

    html += `<tr><td colspan="3" style="height: 15px; border: none;"></td></tr>`;

    // Bloco: RESULTADO LÍQUIDO
    const resColor = dre.resultado >= 0 ? '#1B5E20' : '#B71C1C';
    html += `<tr>
        <td style="font-weight: bold; font-size: 16px; background-color: ${resColor}; color: #FFFFFF; height: 35px; vertical-align: middle;">3. RESULTADO LÍQUIDO DO EXERCÍCIO</td>
        <td style="font-weight: bold; font-size: 16px; background-color: ${resColor}; color: #FFFFFF; height: 35px; vertical-align: middle;">${dre.resultado.toLocaleString('pt-BR', { minimumFractionDigits: 2 })}</td>
        <td style="font-weight: bold; font-size: 16px; background-color: ${resColor}; color: #FFFFFF; height: 35px; vertical-align: middle;">${dre.margem.toFixed(2).replace('.', ',')}%</td>
    </tr>`;

    html += `</table></body></html>`;

    // Gerando link de download invisível
    const blob = new Blob([html], { type: 'application/vnd.ms-excel' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement("a");
    link.setAttribute("href", url);
    link.setAttribute("download", `DRE_Gerencial_${format(new Date(), 'yyyyMMdd')}.xls`);
    document.body.appendChild(link);
    link.click();
    link.remove();
    appStore.showSnackbar('Excel (Analítico) exportado com sucesso!', 'success');
};


const generateReport = async (type: 'pdf' | 'print') => {
    if (dre.receitas.total === 0 && dre.despesas.total === 0) {
        return appStore.showSnackbar("O vácuo não possui registros para exportar.", "warning");
    }

    const companyNameLabel = isPrivacyMode.value ? 'FICTÍCIA S.A. - DADOS DEMO' : (companyStore.isGlobalView ? 'VISÃO GLOBAL - HOLDING' : companyStore.currentCompanyName.toUpperCase());
    const logoUrl = companyNameLabel.toLowerCase().includes('cajuia') || companyNameLabel.toLowerCase().includes('santos') ? logoCajuia : logoMjlm;
    const regimeLabel = filters.regime === 'caixa' ? 'Regime de Caixa (Efetivamente Recebido/Pago)' : 'Regime de Competência (Provisão/Vencimento)';

    if (type === 'print') {
        const printWindow = window.open('', '_blank');
        if (!printWindow) return appStore.showSnackbar('Permita a abertura de pop-ups.', 'warning');

        let recHtml = '';
        if (dre.receitas.items.length === 0) recHtml = '<tr><td colspan="3" class="text-center" style="color:#999;">Sem receitas</td></tr>';
        dre.receitas.items.forEach((i: any) => {
            const av = dre.receitas.total ? ((i.value / dre.receitas.total) * 100).toFixed(2) : '0.00';
            const pad = 20 + (i.depth * 15);
            const wgt = i.is_group ? 'bold' : 'normal';
            recHtml += `<tr><td style="padding-left: ${pad}px; font-weight: ${wgt};">${i.code} - ${i.name}</td><td class="text-right" style="font-weight: ${wgt};">${formatCurrency(i.value)}</td><td class="text-right" style="color: #666; font-weight: bold;">${av}%</td></tr>`;
        });

        let payHtml = '';
        if (dre.despesas.items.length === 0) payHtml = '<tr><td colspan="3" class="text-center" style="color:#999;">Sem despesas</td></tr>';
        dre.despesas.items.forEach((i: any) => {
            const av = dre.receitas.total ? ((i.value / dre.receitas.total) * 100).toFixed(2) : '0.00';
            const pad = 20 + (i.depth * 15);
            const wgt = i.is_group ? 'bold' : 'normal';
            payHtml += `<tr><td style="padding-left: ${pad}px; color: #c62828; font-weight: ${wgt};">${i.code} - ${i.name}</td><td class="text-right" style="color: #c62828; font-weight: ${wgt};">- ${formatCurrency(i.value)}</td><td class="text-right" style="color: #666; font-weight: bold;">${av}%</td></tr>`;
        });

        const bgResult = dre.resultado >= 0 ? '#1B5E20' : '#B71C1C';

        const html = `
            <!DOCTYPE html>
            <html lang="pt-BR">
            <head>
                <meta charset="UTF-8">
                <title>DRE Gerencial Analítico - ${companyNameLabel}</title>
                <style>
                    body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; padding: 20px; color: #333; margin: 0; }
                    .header { display: flex; justify-content: space-between; align-items: flex-start; border-bottom: 2px solid #1976D2; padding-bottom: 15px; margin-bottom: 20px; }
                    .header-info h1 { margin: 0 0 5px 0; font-size: 22px; color: #1976D2; text-transform: uppercase; letter-spacing: 1px; }
                    .header-info p { margin: 3px 0; font-size: 12px; color: #555; }
                    .logo-placeholder img { max-width: 160px; max-height: 65px; object-fit: contain; }

                    .print-toolbar { display: flex; gap: 10px; margin-bottom: 20px; background: #f5f5f5; padding: 10px; border-radius: 6px; align-items: center;}
                    .btn-print { background: #1976D2; color: white; border: none; padding: 8px 16px; border-radius: 4px; font-weight: bold; cursor: pointer; }

                    table { width: 100%; border-collapse: collapse; font-size: 13px; margin-bottom: 20px; }
                    th { background-color: #333; color: white; padding: 12px; text-transform: uppercase; }
                    td { border-bottom: 1px solid #eee; padding: 10px 12px; }

                    .group-header { font-weight: bold; font-size: 15px; border-bottom: 2px solid #ddd; }
                    .group-header.success { color: #1B5E20; background-color: #E8F5E9; }
                    .group-header.danger { color: #B71C1C; background-color: #FFEBEE; }

                    .result-row { background-color: ${bgResult}; color: white; font-weight: bold; font-size: 18px; }
                    .result-row td { border: none; padding: 15px; }

                    .text-right { text-align: right; }
                    .text-center { text-align: center; }

                    .footer { margin-top: 30px; font-size: 10px; color: #888; text-align: center; border-top: 1px solid #eee; padding-top: 10px; }

                    @media print {
                        body { padding: 0; }
                        .print-toolbar { display: none; }
                        * { -webkit-print-color-adjust: exact !important; color-adjust: exact !important; print-color-adjust: exact !important; }
                        @page { margin: 1.5cm; size: A4 portrait; }
                    }
                </style>
            </head>
            <body>
                <div class="print-toolbar">
                    <button class="btn-print" onclick="window.print()">🖨️ Imprimir DRE</button>
                </div>

                <div class="header">
                    <div class="header-info">
                        <h1>DRE Gerencial Analítico</h1>
                        <p><strong>Empresa:</strong> ${companyNameLabel}</p>
                        <p><strong>Período:</strong> ${formatDate(filters.startDate)} a ${formatDate(filters.endDate)}</p>
                        <p><strong>Método de Apuração:</strong> ${regimeLabel}</p>
                    </div>
                    <div class="logo-placeholder">
                        <img src="${logoUrl}" alt="Logo">
                    </div>
                </div>

                <table>
                    <thead>
                        <tr>
                            <th class="text-left">ESTRUTURA DRE (PLANO DE CONTAS)</th>
                            <th class="text-right" style="width: 200px;">VALOR (R$)</th>
                            <th class="text-right" style="width: 100px;">AV (%)</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr class="group-header success">
                            <td>1. RECEITAS</td>
                            <td class="text-right">${formatCurrency(dre.receitas.total)}</td>
                            <td class="text-right">100.00%</td>
                        </tr>
                        ${recHtml}

                        <tr><td colspan="3" style="border:none; padding: 10px;"></td></tr>

                        <tr class="group-header danger">
                            <td>2. CUSTOS E DESPESAS</td>
                            <td class="text-right">- ${formatCurrency(dre.despesas.total)}</td>
                            <td class="text-right">${dre.receitas.total ? ((dre.despesas.total / dre.receitas.total) * 100).toFixed(2) : '0.00'}%</td>
                        </tr>
                        ${payHtml}

                        <tr><td colspan="3" style="border:none; padding: 15px;"></td></tr>

                        <tr class="result-row">
                            <td style="text-transform: uppercase;">3. RESULTADO LÍQUIDO DO EXERCÍCIO</td>
                            <td class="text-right">${formatCurrency(dre.resultado)}</td>
                            <td class="text-right">${dre.margem.toFixed(2)}%</td>
                        </tr>
                    </tbody>
                </table>

                <div class="footer">
                    Relatório Financeiro Estruturado | MJProcess | Gerado em ${format(new Date(), 'dd/MM/yyyy HH:mm')} por ${userStore.user?.email || 'Operador'}
                </div>
                <script>
                    window.onload = () => { setTimeout(() => { window.print(); }, 500); };
                <\/script>
            </body>
            </html>
        `;

        printWindow.document.open();
        printWindow.document.write(html);
        printWindow.document.close();

    } else if (type === 'pdf') {
        const doc = new jsPDF({ orientation: 'p', unit: 'mm', format: 'a4' });
        const pageWidth = doc.internal.pageSize.width;

        try {
            const imgProps = doc.getImageProperties(logoUrl);
            const imgWidth = 35;
            const imgHeight = (imgProps.height * imgWidth) / imgProps.width;
            doc.addImage(logoUrl, 'PNG', 15, 10, imgWidth, imgHeight);
        } catch(e) {}

        doc.setFontSize(8).setTextColor(80);
        doc.text([companyNameLabel, "DRE Gerencial Analítico", `Emissão: ${format(new Date(), 'dd/MM/yyyy HH:mm')}`], pageWidth - 15, 15, { align: 'right' });

        doc.setDrawColor(220); doc.line(15, 32, pageWidth - 15, 32);

        doc.setFontSize(16).setFont('helvetica', 'bold').setTextColor(20);
        doc.text("DRE GERENCIAL (PLANO DE CONTAS)", 15, 45);
        doc.setFontSize(10).setFont('helvetica', 'normal').setTextColor(100);
        doc.text(`Período: ${formatDate(filters.startDate)} a ${formatDate(filters.endDate)} | ${regimeLabel.split(' ')[0]}`, 15, 52);

        const tableData: any[] = [];

        tableData.push([{ content: '1. RECEITAS', styles: { fontStyle: 'bold', textColor: [27, 94, 32], fillColor: [232, 245, 233] } }, { content: formatCurrency(dre.receitas.total), styles: { fontStyle: 'bold', halign: 'right', textColor: [27, 94, 32], fillColor: [232, 245, 233] } }, { content: '100.00%', styles: { fontStyle: 'bold', halign: 'right', textColor: [27, 94, 32], fillColor: [232, 245, 233] } }]);
        dre.receitas.items.forEach((i: any) => {
            const av = dre.receitas.total ? ((i.value / dre.receitas.total) * 100).toFixed(2) : '0.00';
            const space = '  '.repeat(i.depth);
            const wgt = i.is_group ? 'bold' : 'normal';
            tableData.push([{ content: space + i.code + ' - ' + i.name, styles: { fontStyle: wgt, textColor: [80, 80, 80] } }, { content: formatCurrency(i.value), styles: { fontStyle: wgt, halign: 'right' } }, { content: av + '%', styles: { fontStyle: 'bold', halign: 'right', textColor: [120,120,120] } }]);
        });
        tableData.push([{ content: '', colSpan: 3, styles: { fillColor: [255, 255, 255], cellPadding: 2 } }]);

        const despAvTotal = dre.receitas.total ? ((dre.despesas.total / dre.receitas.total) * 100).toFixed(2) : '0.00';
        tableData.push([{ content: '2. CUSTOS E DESPESAS', styles: { fontStyle: 'bold', textColor: [183, 28, 28], fillColor: [255, 235, 238] } }, { content: '- ' + formatCurrency(dre.despesas.total), styles: { fontStyle: 'bold', halign: 'right', textColor: [183, 28, 28], fillColor: [255, 235, 238] } }, { content: despAvTotal + '%', styles: { fontStyle: 'bold', halign: 'right', textColor: [183, 28, 28], fillColor: [255, 235, 238] } }]);
        dre.despesas.items.forEach((i: any) => {
            const av = dre.receitas.total ? ((i.value / dre.receitas.total) * 100).toFixed(2) : '0.00';
            const space = '  '.repeat(i.depth);
            const wgt = i.is_group ? 'bold' : 'normal';
            tableData.push([{ content: space + i.code + ' - ' + i.name, styles: { fontStyle: wgt, textColor: [183, 28, 28] } }, { content: '- ' + formatCurrency(i.value), styles: { fontStyle: wgt, halign: 'right', textColor: [183, 28, 28] } }, { content: av + '%', styles: { fontStyle: 'bold', halign: 'right', textColor: [120,120,120] } }]);
        });
        tableData.push([{ content: '', colSpan: 3, styles: { fillColor: [255, 255, 255], cellPadding: 2 } }]);

        const resultColor = dre.resultado >= 0 ? [27, 94, 32] : [183, 28, 28];
        tableData.push([{ content: `3. RESULTADO LÍQUIDO DO EXERCÍCIO`, styles: { fontStyle: 'bold', textColor: [255,255,255], fillColor: resultColor, fontSize: 13, cellPadding: 8 } }, { content: formatCurrency(dre.resultado), styles: { fontStyle: 'bold', halign: 'right', textColor: [255,255,255], fillColor: resultColor, fontSize: 13, cellPadding: 8 } }, { content: dre.margem.toFixed(2) + '%', styles: { fontStyle: 'bold', halign: 'right', textColor: [255,255,255], fillColor: resultColor, fontSize: 13, cellPadding: 8 } }]);

        autoTable(doc, {
            startY: 60,
            head: [['ESTRUTURA DRE (PLANO DE CONTAS)', 'VALOR (R$)', 'AV (%)']],
            body: tableData,
            theme: 'plain',
            headStyles: { fillColor: [50, 50, 50], textColor: 255, fontStyle: 'bold', fontSize: 10 },
            styles: { fontSize: 9, cellPadding: 5, lineColor: [230, 230, 230], lineWidth: { bottom: 0.1 } },
            columnStyles: { 0: { cellWidth: 'auto' }, 1: { cellWidth: 45 }, 2: { cellWidth: 25 } }
        });

        doc.save(`DRE_Gerencial_${format(new Date(), 'yyyyMMdd')}.pdf`);
        appStore.showSnackbar('PDF do DRE Estruturado Gerado com Sucesso!', 'success');
    }
};

onMounted(() => {
    fetchAuxiliaryData().then(() => fetchData());
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

/* CLASSES 3D E ZEBRADO */
.btn-rect { border-radius: 0 !important; text-transform: none !important; }
.btn-3d { border-radius: 6px !important; box-shadow: 0 3px 5px rgba(0,0,0,0.15), inset 0 2px 0 rgba(255,255,255,0.25) !important; transition: transform 0.1s ease, box-shadow 0.1s ease; text-transform: none !important; }
.btn-3d:active { transform: translateY(2px); box-shadow: 0 1px 2px rgba(0,0,0,0.15), inset 0 1px 0 rgba(255,255,255,0.2) !important; }
.chip-3d { border-radius: 6px !important; box-shadow: 0 3px 5px rgba(0,0,0,0.12), inset 0 1px 0 rgba(255,255,255,0.25) !important; text-shadow: 0 1px 2px rgba(0,0,0,0.25); }

.zebra-light-a { background-color: #ffffff; }
.zebra-light-b { background-color: #f8fafc; }
.zebra-dark-a { background-color: rgba(255,255,255,0.02) !important; }
.zebra-dark-b { background-color: transparent !important; }

/* ENTERPRISE BAR E INPUTS ALINHADOS */
.enterprise-filter-bar { border: 1px solid rgba(0,0,0,0.08); }
.enterprise-date :deep(.v-field__input) { padding-top: 0 !important; padding-bottom: 0 !important; min-height: 40px !important; display: flex; align-items: center; }
.enterprise-date :deep(.v-field__prepend-inner) { padding-top: 0 !important; display: flex; align-items: center; margin-right: 4px; }
.ui-field :deep(.v-field__input) { min-height: 40px !important; padding-top: 0 !important; padding-bottom: 0 !important; display: flex; align-items: center; }
.ui-field :deep(.v-field) { border-radius: 0 !important; }

.clean-input { border: none; outline: none; background: transparent; font-size: 12px; color: inherit; width: 100%; }

.shadow-indigo-soft { box-shadow: 0 4px 15px rgba(63, 81, 181, 0.4); }
.custom-scroll::-webkit-scrollbar { width: 8px; height: 8px; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.3); border-radius: 4px; }
.glass-card { background: rgba(30, 30, 35, 0.45); backdrop-filter: blur(25px); border: 1px solid rgba(255,255,255,0.08); }

.bg-black-80 { background-color: rgba(0,0,0,0.8); }
.bg-white-80 { background-color: rgba(255,255,255,0.8); }
.bg-white-05 { background-color: rgba(255,255,255,0.05) !important; }
.bg-black-20 { background-color: rgba(0,0,0,0.2) !important; }
.bg-green-darken-4-alpha { background-color: rgba(27, 94, 32, 0.15) !important; }
.bg-red-darken-4-alpha { background-color: rgba(183, 28, 28, 0.15) !important; }
.bg-orange-darken-4-alpha { background-color: rgba(230, 81, 0, 0.2) !important; }
.text-white-80 { color: rgba(255,255,255,0.8) !important; }
.absolute-center { position: absolute; top: 0; left: 0; }

/* Grid DRE Personalizada e Elegante (Estrutura de Árvore) */
.dre-grid-table { border-collapse: collapse; min-width: 700px; }

.dre-grid-table th {
    padding: 16px;
    font-size: 12px;
    font-weight: 900;
    color: #555;
    background: transparent;
}
.theme-dark .dre-grid-table th { color: #aaa; }

.dre-grid-table td { padding: 12px 16px; font-size: 13px; }

.group-row td { border-bottom: 1px solid rgba(0,0,0,0.1); }
.theme-dark .group-row td { border-bottom: 1px solid rgba(255,255,255,0.1); }

.item-row { border-bottom: 1px solid rgba(128,128,128,0.1); }
.item-row:last-child { border-bottom: none; }

.transition-hover { transition: background-color 0.15s ease; }
.theme-light .transition-hover:hover { background-color: #f1f5f9 !important; }
.theme-dark .transition-hover:hover { background-color: rgba(255,255,255,0.05) !important; }

.shadow-xs { box-shadow: 0 1px 2px 0 rgba(0, 0, 0, 0.05); }
.lh-1 { line-height: 1; }
.sticky-head { position: sticky; top: 0; z-index: 10; box-shadow: 0 8px 16px -4px rgba(0, 0, 0, 0.08); }
.theme-dark .sticky-head { box-shadow: 0 8px 20px -4px rgba(0, 0, 0, 0.4); }

.hover-underline:hover { text-decoration: underline; opacity: 1 !important; color: rgb(var(--v-theme-primary)); }
</style>
