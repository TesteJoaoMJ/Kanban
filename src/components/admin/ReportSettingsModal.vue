<template>
  <v-dialog
    :model-value="show"
    @update:model-value="$emit('close')"
    max-width="1400px"
    height="90vh"
    scrollable
    persistent
    content-class="glass-modal-content"
    transition="dialog-bottom-transition"
  >
    <v-card class="report-main-card d-flex flex-row overflow-hidden rounded-xl" :class="themeClass">

      <div class="report-sidebar d-none d-md-flex flex-column pa-6 border-r" :class="sidebarClass">

        <div class="mb-8">
          <div class="d-flex align-center mb-6">
            <div class="icon-box-lg bg-gradient-primary mr-4 elevation-10 rounded-lg d-flex align-center justify-center glow-pulse">
              <v-icon color="white" size="28">mdi-server-network</v-icon>
            </div>
            <div>
              <div class="text-subtitle-2 font-weight-black letter-spacing-1" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-3' : 'text-white'">ANALYTICS HUB</div>
              <div class="text-[10px] font-mono" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-1' : 'text-white-70'">v2.5.0 • BUILD 8921</div>
            </div>
          </div>

          <v-divider class="mb-6" :class="dividerClass"></v-divider>

          <div class="sidebar-section mb-6">
            <div class="section-label d-flex justify-space-between align-center mb-3">
              <span :class="labelClass">INFRAESTRUTURA</span>
              <v-icon size="x-small" color="success" class="pulse-fast">mdi-circle-medium</v-icon>
            </div>

            <div class="status-card pa-3 rounded-lg border mb-2" :class="statusCardClass">
              <div class="d-flex align-center justify-space-between mb-1">
                <span class="text-caption font-weight-bold" :class="textPrimaryClass">Database (Supabase)</span>
                <v-icon size="x-small" color="success">mdi-check-network</v-icon>
              </div>
              <div class="d-flex align-center justify-space-between">
                <span class="text-[10px] text-medium-emphasis">Conexão Estável</span>
                <span class="text-[10px] font-mono text-success">24ms</span>
              </div>
            </div>

            <div class="status-card pa-3 rounded-lg border" :class="statusCardClass">
              <div class="d-flex align-center justify-space-between mb-1">
                <span class="text-caption font-weight-bold" :class="textPrimaryClass">API Gateway</span>
                <v-icon size="x-small" color="info">mdi-api</v-icon>
              </div>
              <div class="d-flex align-center justify-space-between">
                <span class="text-[10px] text-medium-emphasis">Throughput</span>
                <span class="text-[10px] font-mono text-info">98.2%</span>
              </div>
            </div>
          </div>

          <div class="sidebar-section">
            <div class="section-label mb-3" :class="labelClass">VOLUME DE DADOS</div>

            <div class="metric-row mb-3">
              <div class="d-flex justify-space-between text-[11px] mb-1">
                <span :class="textSecondaryClass">Pedidos Indexados</span>
                <span class="font-weight-bold font-mono" :class="textPrimaryClass">{{ orders.length }}</span>
              </div>
              <v-progress-linear model-value="100" color="primary" height="4" rounded :bg-color="progressBgColor"></v-progress-linear>
            </div>

            <div class="metric-row mb-3">
              <div class="d-flex justify-space-between text-[11px] mb-1">
                <span :class="textSecondaryClass">Clientes Ativos</span>
                <span class="font-weight-bold font-mono" :class="textPrimaryClass">{{ clients.length }}</span>
              </div>
              <v-progress-linear :model-value="Math.min(clients.length, 100)" color="success" height="4" rounded :bg-color="progressBgColor"></v-progress-linear>
            </div>

            <div class="metric-row">
              <div class="d-flex justify-space-between text-[11px] mb-1">
                <span :class="textSecondaryClass">Catálogo de Tecidos</span>
                <span class="font-weight-bold font-mono" :class="textPrimaryClass">{{ fabrics.length }}</span>
              </div>
              <v-progress-linear :model-value="Math.min(fabrics.length * 2, 100)" color="warning" height="4" rounded :bg-color="progressBgColor"></v-progress-linear>
            </div>
          </div>
        </div>

        <div class="mt-auto">
          <div class="session-info pa-3 rounded-lg border" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-4 border-grey-lighten-2' : 'bg-gradient-dark border-white-05'">
            <div class="d-flex align-center mb-1">
              <v-icon size="small" :color="themeStore.currentMode === 'light' ? 'grey-darken-1' : 'grey'" class="mr-2">mdi-account-key</v-icon>
              <span class="text-[10px] text-uppercase" :class="textSecondaryClass">Sessão Atual</span>
            </div>
            <div class="text-caption font-weight-bold text-truncate" :class="textPrimaryClass">{{ userEmail || 'Usuário Admin' }}</div>
            <div class="text-[10px] font-mono mt-1" :class="textSecondaryClass">ID: {{ sessionId }}</div>
          </div>
        </div>
      </div>

      <div class="report-content d-flex flex-column flex-grow-1 position-relative" :class="mainContentClass">

        <div class="px-8 py-5 border-b d-flex align-center justify-space-between" :class="headerClass">
          <div>
            <h2 class="text-h5 font-weight-black mb-1 d-flex align-center" :class="textPrimaryClass">
              Central de Relatórios
              <v-chip size="x-small" color="primary" variant="flat" class="ml-3 font-weight-bold">PRO</v-chip>
            </h2>
            <div class="d-flex align-center text-caption" :class="textSecondaryClass">
              <v-icon size="x-small" class="mr-1">mdi-refresh</v-icon>
              Dados sincronizados em: <span class="font-mono ml-1" :class="textPrimaryClass">{{ lastUpdated }}</span>
            </div>
          </div>
          <div class="d-flex align-center">
             <v-btn icon variant="text" :color="themeStore.currentMode === 'light' ? 'grey-darken-1' : 'white'" class="mr-2" @click="$emit('close')">
               <v-icon>mdi-window-minimize</v-icon>
               <v-tooltip activator="parent" location="bottom">Minimizar</v-tooltip>
             </v-btn>
             <v-btn icon variant="tonal" color="error" class="glass-btn-close" @click="$emit('close')">
               <v-icon>mdi-close</v-icon>
               <v-tooltip activator="parent" location="bottom">Fechar Central</v-tooltip>
             </v-btn>
          </div>
        </div>

        <div class="px-8 pt-6 pb-0">
          <v-tabs v-model="tab" color="primary" align-tabs="start" class="custom-tabs" hide-slider height="48">
            <v-tab value="general" class="rounded-t-xl px-6 font-weight-bold letter-spacing-1 text-caption mr-1 transition-all">
              <v-icon start>mdi-file-document-multiple-outline</v-icon> Exportação Detalhada
            </v-tab>
            <v-tab value="quick" class="rounded-t-xl px-6 font-weight-bold letter-spacing-1 text-caption mr-1 transition-all">
              <v-icon start>mdi-lightning-bolt</v-icon> Relatórios Rápidos
            </v-tab>
            <v-tab value="stock" class="rounded-t-xl px-6 font-weight-bold letter-spacing-1 text-caption transition-all">
              <v-icon start>mdi-package-variant-closed</v-icon> Auditoria de Estoque
            </v-tab>
          </v-tabs>
          <v-divider class="border-primary opacity-50" style="border-width: 2px;"></v-divider>
        </div>

        <div class="flex-grow-1 overflow-y-auto custom-scrollbar px-8 py-6 position-relative">
          <v-window v-model="tab" class="h-100">

            <v-window-item value="general" class="h-100">
              <div class="d-flex flex-column h-100">

                <v-alert
                  icon="mdi-filter-cog"
                  variant="tonal"
                  color="primary"
                  class="mb-6 border-thin rounded-lg text-caption"
                  density="compact"
                >
                  Configure os filtros avançados abaixo para gerar arquivos PDF ou Excel customizados.
                  <strong class="ml-1">Dica:</strong> A planilha em Excel gera planilhas separadas por Mês.
                </v-alert>

                <div class="filter-card pa-6 rounded-xl border mb-6 shadow-sm" :class="filterCardClass">

                  <div class="filter-group full-width mb-6">
                    <label class="filter-label" :class="labelClass">
                      <v-icon size="x-small" class="mr-1">mdi-calendar-range</v-icon> Período de Análise (Data do Lançamento)
                    </label>
                    <v-chip-group v-model="periodSelection" @update:model-value="setPeriod" selected-class="bg-primary text-white elevation-2" mandatory class="mb-2">
                      <v-chip filter value="7d" variant="outlined" size="small" class="font-weight-bold px-4">Últimos 7 Dias</v-chip>
                      <v-chip filter value="30d" variant="outlined" size="small" class="font-weight-bold px-4">Últimos 30 Dias</v-chip>
                      <v-chip filter value="this_month" variant="outlined" size="small" class="font-weight-bold px-4">Este Mês</v-chip>
                      <v-chip filter value="custom" variant="outlined" size="small" class="font-weight-bold px-4">Personalizado</v-chip>
                    </v-chip-group>

                    <v-expand-transition>
                      <div v-if="periodSelection === 'custom'" class="custom-date-box pa-4 rounded-lg border mt-3" :class="dateBoxClass">
                        <v-row dense>
                          <v-col cols="6">
                            <span class="text-[10px] text-medium-emphasis mb-1 d-block">Data Inicial</span>
                            <v-text-field type="date" v-model="customStartDate" density="compact" variant="outlined" hide-details :bg-color="inputBgColor"></v-text-field>
                          </v-col>
                          <v-col cols="6">
                            <span class="text-[10px] text-medium-emphasis mb-1 d-block">Data Final</span>
                            <v-text-field type="date" v-model="customEndDate" density="compact" variant="outlined" hide-details :bg-color="inputBgColor"></v-text-field>
                          </v-col>
                        </v-row>
                      </div>
                    </v-expand-transition>
                  </div>

                  <v-divider class="mb-6 border-dashed" :class="dividerClass"></v-divider>

                  <v-row dense>
                    <v-col cols="12" md="6">
                      <label class="filter-label" :class="labelClass"><v-icon size="x-small" class="mr-1">mdi-account-tie</v-icon> Vendedor</label>
                      <v-autocomplete v-model="selectedSellers" :items="sellers" variant="outlined" density="compact" placeholder="Todos os vendedores" multiple chips closable-chips clearable hide-details :bg-color="inputBgColor">
                          <template v-slot:chip="{ props, item }"><v-chip v-bind="props" size="x-small" color="primary">{{ item.raw }}</v-chip></template>
                      </v-autocomplete>
                    </v-col>
                    <v-col cols="12" md="6">
                      <label class="filter-label" :class="labelClass"><v-icon size="x-small" class="mr-1">mdi-account-group</v-icon> Cliente</label>
                      <v-autocomplete v-model="selectedClients" :items="clients" variant="outlined" density="compact" placeholder="Todos os clientes" multiple chips closable-chips clearable hide-details :bg-color="inputBgColor">
                          <template v-slot:chip="{ props, item }"><v-chip v-bind="props" size="x-small" color="success">{{ item.raw }}</v-chip></template>
                      </v-autocomplete>
                    </v-col>
                    <v-col cols="12" md="6" class="mt-4">
                      <label class="filter-label" :class="labelClass"><v-icon size="x-small" class="mr-1">mdi-texture-box</v-icon> Base (Tecido)</label>
                      <v-autocomplete v-model="selectedFabrics" :items="fabrics" variant="outlined" density="compact" placeholder="Todas as bases" multiple chips closable-chips clearable hide-details :bg-color="inputBgColor">
                          <template v-slot:chip="{ props, item }"><v-chip v-bind="props" size="x-small" color="secondary">{{ item.raw }}</v-chip></template>
                      </v-autocomplete>
                    </v-col>
                    <v-col cols="12" md="6" class="mt-4">
                      <label class="filter-label" :class="labelClass"><v-icon size="x-small" class="mr-1">mdi-list-status</v-icon> Status</label>
                      <v-select v-model="selectedStatus" :items="statusOptions" item-title="text" item-value="value" variant="outlined" density="compact" placeholder="Qualquer status" clearable hide-details :bg-color="inputBgColor"></v-select>
                    </v-col>
                  </v-row>
                </div>

                <v-spacer></v-spacer>

                <div class="action-footer mt-auto pt-6 border-t d-flex align-center" :class="footerBorderClass">
                  <div class="result-counter d-flex align-center mr-auto px-4 py-3 rounded-pill border elevation-1" :class="counterClass">
                    <v-icon color="primary" class="mr-3">mdi-database-check</v-icon>
                    <div class="d-flex flex-column">
                        <span class="text-[10px] text-medium-emphasis text-uppercase font-weight-bold">Prévia de Filtro</span>
                        <span class="text-caption font-weight-black" :class="textPrimaryClass">{{ filteredReportItems.length }} registros correspondentes</span>
                    </div>
                  </div>

                  <v-btn
                    @click="generateExcel"
                    :loading="isGeneratingExcel"
                    color="success"
                    variant="tonal"
                    class="mr-4 font-weight-bold letter-spacing-1 h-48"
                    prepend-icon="mdi-microsoft-excel"
                    :disabled="filteredReportItems.length === 0"
                    size="large"
                  >
                    Exportar Excel
                    <v-tooltip activator="parent" location="top">Baixar planilha segmentada por meses</v-tooltip>
                  </v-btn>

                  <v-btn
                    @click="generateFullReportPdf"
                    :loading="isGeneratingPdf"
                    color="primary"
                    variant="flat"
                    class="font-weight-bold glow-button letter-spacing-1 h-48"
                    prepend-icon="mdi-file-pdf-box"
                    :disabled="filteredReportItems.length === 0"
                    size="large"
                  >
                    Gerar PDF Profissional
                    <v-tooltip activator="parent" location="top">Relatório analítico em paisagem</v-tooltip>
                  </v-btn>
                </div>
              </div>
            </v-window-item>

            <v-window-item value="quick">
              <div class="d-flex align-center justify-space-between mb-6">
                 <div class="text-body-2 text-medium-emphasis">
                   Selecione um dos modelos abaixo para geração imediata baseada nos filtros de Data atuais.
                 </div>
                 <v-chip size="small" color="warning" variant="outlined" prepend-icon="mdi-clock-time-four-outline">
                   Filtro: {{ format(parseISO(customStartDate), 'dd/MM/yy') }} a {{ format(parseISO(customEndDate), 'dd/MM/yy') }}
                 </v-chip>
              </div>

              <v-alert v-if="!processedReportData || filteredReportItems.length === 0" type="warning" variant="tonal" density="compact" class="mb-6 border-dashed border-warning" icon="mdi-alert-circle">
                Nenhum dado disponível. Ajuste os filtros na aba anterior.
              </v-alert>

              <v-row>
                <v-col cols="12" md="6">
                  <v-card class="quick-report-card" variant="outlined" link v-ripple :class="cardClass">
                    <div class="d-flex align-start pa-5 h-100">
                      <div class="icon-box-md bg-gradient-error mr-5 elevation-5 rounded-lg d-flex align-center justify-center">
                        <v-icon color="white" size="32">mdi-factory</v-icon>
                      </div>
                      <div class="flex-grow-1 d-flex flex-column h-100">
                        <div class="text-subtitle-1 font-weight-black mb-1" :class="textPrimaryClass">Fila de Produção (Geral)</div>
                        <p class="text-caption text-medium-emphasis mb-4 line-clamp-2">Listagem completa de todos os pedidos em fila ou produção (exclui design/entregues). Formato para impressão.</p>
                        <v-btn size="small" variant="tonal" color="error" block class="mt-auto font-weight-bold" @click="generateOpenProductionPdf" :loading="isGeneratingPdf">
                          <v-icon start>mdi-file-pdf-box</v-icon> Gerar Relatório
                        </v-btn>
                      </div>
                    </div>
                  </v-card>
                </v-col>

                <v-col cols="12" md="6">
                  <v-card class="quick-report-card" variant="outlined" link v-ripple :class="cardClass">
                    <div class="d-flex align-start pa-5 h-100">
                      <div class="icon-box-md bg-gradient-primary mr-5 elevation-5 rounded-lg d-flex align-center justify-center">
                        <v-icon color="white" size="32">mdi-account-group</v-icon>
                      </div>
                      <div class="flex-grow-1 d-flex flex-column h-100">
                        <div class="text-subtitle-1 font-weight-black mb-1" :class="textPrimaryClass">Ranking de Vendedores</div>
                        <p class="text-caption text-medium-emphasis mb-4 line-clamp-2">Performance individual comparativa por valor monetário e volume de vendas.</p>
                        <div class="mt-auto d-flex gap-2">
                          <v-btn size="small" variant="tonal" color="primary" class="flex-grow-1" @click="generateSellerRankingPdf('value')" :loading="isGeneratingPdf" :disabled="!processedReportData">
                            <v-icon start size="small">mdi-currency-usd</v-icon> Valor
                          </v-btn>
                          <v-btn size="small" variant="tonal" color="primary" class="flex-grow-1" @click="generateSellerRankingPdf('metrics')" :loading="isGeneratingPdf" :disabled="!processedReportData">
                            <v-icon start size="small">mdi-ruler</v-icon> Metros/KG
                          </v-btn>
                        </div>
                      </div>
                    </div>
                  </v-card>
                </v-col>

                <v-col cols="12" md="6">
                  <v-card class="quick-report-card" variant="outlined" link v-ripple :class="cardClass">
                    <div class="d-flex align-start pa-5 h-100">
                      <div class="icon-box-md bg-gradient-success mr-5 elevation-5 rounded-lg d-flex align-center justify-center">
                        <v-icon color="white" size="32">mdi-account-star</v-icon>
                      </div>
                      <div class="flex-grow-1 d-flex flex-column h-100">
                        <div class="text-subtitle-1 font-weight-black mb-1" :class="textPrimaryClass">Ranking de Clientes</div>
                        <p class="text-caption text-medium-emphasis mb-4 line-clamp-2">Análise Pareto (80/20) dos principais clientes e volume de compras.</p>
                        <div class="mt-auto d-flex gap-2">
                          <v-btn size="small" variant="tonal" color="success" class="flex-grow-1" @click="generateClientRankingPdf('value')" :loading="isGeneratingPdf" :disabled="!processedReportData">
                            <v-icon start size="small">mdi-currency-usd</v-icon> Valor
                          </v-btn>
                          <v-btn size="small" variant="tonal" color="success" class="flex-grow-1" @click="generateClientRankingPdf('metrics')" :loading="isGeneratingPdf" :disabled="!processedReportData">
                            <v-icon start size="small">mdi-ruler</v-icon> Metros/KG
                          </v-btn>
                        </div>
                      </div>
                    </div>
                  </v-card>
                </v-col>

                <v-col cols="12" md="6">
                  <v-card class="quick-report-card" variant="outlined" link v-ripple :class="cardClass">
                    <div class="d-flex align-start pa-5 h-100">
                      <div class="icon-box-md bg-gradient-info mr-5 elevation-5 rounded-lg d-flex align-center justify-center">
                        <v-icon color="white" size="32">mdi-texture-box</v-icon>
                      </div>
                      <div class="flex-grow-1 d-flex flex-column h-100">
                        <div class="text-subtitle-1 font-weight-black mb-1" :class="textPrimaryClass">Ranking de Bases</div>
                        <p class="text-caption text-medium-emphasis mb-4 line-clamp-2">Tecidos mais vendidos e tendências de consumo no período.</p>
                        <v-btn size="small" variant="tonal" color="info" block class="mt-auto font-weight-bold" @click="generateFabricRankingPdf" :loading="isGeneratingPdf" :disabled="!processedReportData">
                          <v-icon start>mdi-file-chart</v-icon> Gerar Relatório
                        </v-btn>
                      </div>
                    </div>
                  </v-card>
                </v-col>

                <v-col cols="12" md="6">
                  <v-card class="quick-report-card" variant="outlined" link v-ripple :class="cardClass">
                    <div class="d-flex align-start pa-5 h-100">
                      <div class="icon-box-md bg-gradient-warning mr-5 elevation-5 rounded-lg d-flex align-center justify-center">
                        <v-icon color="white" size="32">mdi-layers-search</v-icon>
                      </div>
                      <div class="flex-grow-1 d-flex flex-column h-100">
                        <div class="text-subtitle-1 font-weight-black mb-1" :class="textPrimaryClass">Consumo de Matéria Prima</div>
                        <p class="text-caption text-medium-emphasis mb-4 line-clamp-2">Relatório de saída de estoque vs Pedidos realizados.</p>
                        <div class="mt-auto d-flex gap-2">
                          <v-btn size="small" variant="tonal" color="warning" class="flex-grow-1" @click="generateFabricUsageReportPdf('summary')" :loading="isGeneratingPdf" :disabled="!processedReportData">Resumido</v-btn>
                          <v-btn size="small" variant="tonal" color="warning" class="flex-grow-1" @click="generateFabricUsageReportPdf('detailed')" :loading="isGeneratingPdf" :disabled="!processedReportData">Detalhado</v-btn>
                        </div>
                      </div>
                    </div>
                  </v-card>
                </v-col>
              </v-row>
            </v-window-item>

            <v-window-item value="stock" class="h-100">
              <div class="d-flex flex-column h-100">

                <div class="audit-filters px-5 py-4 rounded-xl mb-4 d-flex align-center flex-wrap gap-4 border shadow-sm" :class="auditFilterClass">
                  <div class="d-flex align-center flex-grow-1" style="min-width: 250px;">
                    <v-icon color="primary" class="mr-3">mdi-calendar-range</v-icon>
                    <div class="flex-grow-1">
                      <div class="text-[10px] font-weight-bold text-uppercase text-medium-emphasis mb-1">Período da Auditoria</div>
                      <v-menu :close-on-content-click="false" location="bottom start" offset="10">
                        <template v-slot:activator="{ props }">
                          <div v-bind="props" class="d-flex align-center cursor-pointer hover-brightness">
                            <span class="text-body-2 font-weight-bold" :class="textPrimaryClass">{{ auditDateRangeText }}</span>
                            <v-icon size="small" color="grey" class="ml-2">mdi-chevron-down</v-icon>
                            <v-tooltip activator="parent" location="top">Clique para alterar a data</v-tooltip>
                          </div>
                        </template>
                        <v-date-picker v-model="auditDates" range color="primary"></v-date-picker>
                      </v-menu>
                    </div>
                  </div>

                  <v-divider vertical class="mx-2 hidden-sm-and-down" :class="dividerClass" style="height: 32px;"></v-divider>

                  <div class="d-flex gap-3 flex-wrap align-center">
                    <div class="filter-mini">
                        <label class="filter-label text-[10px]" :class="labelClass">Usuário</label>
                        <v-autocomplete v-model="filterByUser" :items="availableUsers" density="compact" variant="outlined" hide-details clearable placeholder="Todos" :bg-color="inputBgColor"></v-autocomplete>
                    </div>
                    <div class="filter-mini">
                        <label class="filter-label text-[10px]" :class="labelClass">Tecido</label>
                        <v-autocomplete v-model="filterByFabric" :items="availableFabrics" density="compact" variant="outlined" hide-details clearable placeholder="Todos" :bg-color="inputBgColor"></v-autocomplete>
                    </div>
                    <div class="filter-mini small">
                        <label class="filter-label text-[10px]" :class="labelClass">Pedido</label>
                        <v-text-field v-model="filterByOrderNumber" density="compact" variant="outlined" hide-details clearable placeholder="#ID" :bg-color="inputBgColor"></v-text-field>
                    </div>
                    <v-btn @click="fetchStockMovements" :loading="isLoadingMovements" color="primary" variant="flat" class="ml-2 mt-4" icon rounded="lg" size="large">
                      <v-icon>mdi-magnify</v-icon>
                      <v-tooltip activator="parent" location="top">Buscar Movimentações</v-tooltip>
                    </v-btn>
                  </div>
                </div>

                <div class="timeline-wrapper flex-grow-1 overflow-y-auto custom-scrollbar pr-2 position-relative px-2">

                  <v-progress-linear v-if="isLoadingMovements" indeterminate color="primary" class="mb-6 rounded-pill"></v-progress-linear>

                  <div v-if="!stockMovements.length && !isLoadingMovements" class="empty-state-container d-flex flex-column align-center justify-center h-75 opacity-50">
                    <div class="icon-box-lg mb-4 rounded-circle d-flex align-center justify-center" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-4' : 'bg-surface-lighten-1'">
                        <v-icon size="48" color="grey">mdi-clipboard-text-search-outline</v-icon>
                    </div>
                    <div class="text-h6 font-weight-bold" :class="textPrimaryClass">Inicie a Auditoria</div>
                    <div class="text-caption text-medium-emphasis">Selecione um período acima e clique na lupa.</div>
                  </div>

                  <div v-else-if="!filteredMovements.length && !isLoadingMovements" class="empty-state-container d-flex flex-column align-center justify-center h-75 opacity-50">
                    <v-icon size="64" class="mb-4 text-grey">mdi-filter-off-outline</v-icon>
                    <div class="text-h6 font-weight-bold" :class="textPrimaryClass">Sem resultados</div>
                    <div class="text-caption text-medium-emphasis">Tente limpar os filtros de usuário ou tecido.</div>
                  </div>

                  <v-timeline v-else align="start" density="compact" side="end" class="audit-timeline pt-2">
                    <TransitionGroup name="list-stagger">
                      <v-timeline-item
                        v-for="item in timelineItems"
                        :key="item.id"
                        :dot-color="item.color"
                        size="small"
                        fill-dot
                      >
                        <template v-slot:icon>
                          <v-icon size="14" color="white">{{ item.icon }}</v-icon>
                        </template>

                        <v-card class="timeline-card border-thin" :class="timelineCardClass" elevation="2">
                          <div class="d-flex justify-space-between align-start pa-3">
                            <div>
                              <div class="d-flex align-center mb-1">
                                <span class="text-subtitle-2 font-weight-black mr-2" :class="textPrimaryClass">{{ item.title }}</span>
                                <v-chip :color="item.color" size="x-small" variant="flat" class="font-weight-bold letter-spacing-1 text-uppercase">{{ item.type_display }}</v-chip>
                              </div>
                              <div class="text-caption text-medium-emphasis d-flex align-center">
                                <v-icon size="x-small" class="mr-1">mdi-clock-outline</v-icon> {{ item.timestamp }}
                                <span class="mx-2 opacity-30">|</span>
                                <v-avatar size="16" class="mr-1" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-2 text-grey-darken-3' : 'bg-grey-darken-3 text-white'">
                                    <span class="text-[8px] font-weight-bold">{{ item.user.charAt(0) }}</span>
                                </v-avatar>
                                {{ item.user }}
                              </div>
                            </div>

                            <div class="text-right">
                              <div class="text-h6 font-weight-black font-mono lh-1 mb-1" :class="`text-${item.color}`">
                                {{ item.quantity_display }}
                              </div>
                              <div class="stock-flow text-[10px] font-mono px-2 py-1 rounded d-inline-flex align-center" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-4 text-grey-darken-2' : 'bg-black-opacity text-white-70'">
                                {{ item.old_quantity.toFixed(1) }} <v-icon size="x-small" class="mx-1" color="grey">mdi-arrow-right-thin</v-icon> <span class="font-weight-bold" :class="textPrimaryClass">{{ item.new_quantity.toFixed(1) }}</span>
                              </div>
                            </div>
                          </div>

                          <div class="px-3 py-2 d-flex align-center border-t" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-black-opacity-05 border-white-05'">
                            <v-icon size="small" class="mr-2 opacity-50" color="secondary">mdi-texture-box</v-icon>
                            <span class="text-caption font-weight-bold" :class="textSecondaryClass">{{ item.fabric_type }}</span>
                          </div>
                        </v-card>
                      </v-timeline-item>
                    </TransitionGroup>
                  </v-timeline>
                </div>

                <div class="audit-footer pt-4 mt-auto border-t d-flex align-center justify-space-between" :class="footerBorderClass">
                  <div class="d-flex align-center text-caption text-medium-emphasis">
                      <v-icon size="small" class="mr-2">mdi-history</v-icon>
                      {{ filteredMovements.length }} registros de movimentação encontrados
                  </div>
                  <v-btn
                    @click="generateAuditPdf"
                    :loading="isGeneratingAuditPdf"
                    :disabled="filteredMovements.length === 0"
                    color="secondary"
                    variant="flat"
                    prepend-icon="mdi-file-download-outline"
                    class="font-weight-bold"
                  >
                    Exportar PDF da Auditoria
                    <v-tooltip activator="parent" location="top">Gera relatório de auditoria detalhado</v-tooltip>
                  </v-btn>
                </div>

              </div>
            </v-window-item>

          </v-window>
        </div>
      </div>
    </v-card>
  </v-dialog>
</template>

<script setup lang="ts">
import { ref, computed, watch, onMounted } from 'vue';
import { format, subDays, startOfDay, endOfDay, parseISO, startOfMonth, addDays, getDay } from 'date-fns';
import { ptBR } from 'date-fns/locale';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import { supabase } from '@/api/supabase';
import * as XLSX from 'xlsx';
import logoUrl from '@/assets/logomjlm.png';
import { useUserStore } from '@/stores/user';
import { useThemeStore } from '@/stores/theme';
import { useAppStore } from '@/stores/app';

const props = defineProps<{ show: boolean; orders: any[]; sellers: string[]; clients: string[]; fabrics: string[]; }>();
const emit = defineEmits(['update:show', 'close']);
const userStore = useUserStore();
const themeStore = useThemeStore();

const appStore = useAppStore();

// --- STATE BASE ---
const internalShow = ref(props.show);
watch(() => props.show, (val) => { internalShow.value = val; });
watch(internalShow, (val) => { emit('update:show', val); if(!val) emit('close'); });
const closeModal = () => { internalShow.value = false; };

const tab = ref('general');
const stockLevels = ref<Map<string, number>>(new Map());
const lastUpdated = ref(format(new Date(), 'HH:mm'));
const userEmail = computed(() => userStore.user?.email);
const sessionId = computed(() => userStore.user?.id?.substring(0, 8).toUpperCase() || 'UNK');

// Computed Styles
const themeClass = computed(() => themeStore.currentMode === 'light' ? 'bg-white text-grey-darken-3' : 'bg-glass-panel text-white');
const sidebarClass = computed(() => themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-surface-darker border-white-05');
const dividerClass = computed(() => themeStore.currentMode === 'light' ? 'border-grey-lighten-2' : 'border-white-10');
const labelClass = computed(() => themeStore.currentMode === 'light' ? 'text-grey-darken-1' : 'text-white-50');
const statusCardClass = computed(() => themeStore.currentMode === 'light' ? 'bg-white border-grey-lighten-2' : 'bg-surface-lighten-1 border-white-05');
const textPrimaryClass = computed(() => themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white');
const textSecondaryClass = computed(() => themeStore.currentMode === 'light' ? 'text-grey-darken-1' : 'text-white-70');
const progressBgColor = computed(() => themeStore.currentMode === 'light' ? 'rgba(0,0,0,0.05)' : 'rgba(255,255,255,0.1)');
const mainContentClass = computed(() => themeStore.currentMode === 'light' ? 'bg-white' : 'bg-glass-panel');
const headerClass = computed(() => themeStore.currentMode === 'light' ? 'bg-white border-grey-lighten-2' : 'bg-header-glass border-white-05');
const filterCardClass = computed(() => themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-surface-lighten-1 border-white-05');
const dateBoxClass = computed(() => themeStore.currentMode === 'light' ? 'bg-white border-grey-lighten-2' : 'bg-black-opacity border-white-05');
const inputBgColor = computed(() => themeStore.currentMode === 'light' ? 'white' : 'rgba(0,0,0,0.2)');
const footerBorderClass = computed(() => themeStore.currentMode === 'light' ? 'border-grey-lighten-2' : 'border-white-05');
const counterClass = computed(() => themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-surface-lighten-1 border-white-05');
const cardClass = computed(() => themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-surface-lighten-1 border-white-05');
const auditFilterClass = computed(() => themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-surface-darker border-white-05');
const timelineCardClass = computed(() => themeStore.currentMode === 'light' ? 'bg-white border-grey-lighten-2' : 'bg-surface-lighten-1 border-white-05');

const colorPalette = ['#1E88E5', '#43A047', '#FB8C00', '#D81B60', '#6D4C41', '#00ACC1', '#5E35B1', '#F4511E'];

// --- TAB 1: FILTROS E RELATÓRIO GERAL ---
const isGeneratingPdf = ref(false);
const isGeneratingExcel = ref(false);
const periodSelection = ref('30d');
const customStartDate = ref(format(subDays(new Date(), 30), 'yyyy-MM-dd'));
const customEndDate = ref(format(new Date(), 'yyyy-MM-dd'));
const selectedSellers = ref<string[]>([]);
const selectedClients = ref<string[]>([]);
const selectedFabrics = ref<string[]>([]);
const selectedStatus = ref<string | null>(null);

const statusOptions = [
    { value: 'all', text: 'Todos' },
    { value: 'design_pending', text: 'Em design' },
    { value: 'customer_approval', text: 'Aprovação do Cliente' },
    { value: 'completed', text: 'Completado' },
    { value: 'production_queue', text: 'Fila de Produção' },
    { value: 'in_production', text: 'Em Produção' },
    { value: 'ready_for_delivery', text: 'Pronta Entrega' },
    { value: 'delivered', text: 'Entregue' }
];

// Helpers Formatação
const formatCurrency = (v: any) => new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(v || 0);
const formatNumber = (v: any) => new Intl.NumberFormat('pt-BR', { minimumFractionDigits: 1, maximumFractionDigits: 2 }).format(v || 0);
const getStatusText = (v: string) => statusOptions.find(s => s.value === v)?.text || v;

// Controle de Datas Blindado (Sem fuso)
const setPeriod = (v: string) => {
  const end = new Date(); let start = new Date();
  if (v === '7d') start = subDays(end, 7); else if (v === '30d') start = subDays(end, 30); else if (v === 'this_month') start = startOfMonth(end);
  customStartDate.value = format(start, 'yyyy-MM-dd');
  customEndDate.value = format(end, 'yyyy-MM-dd');
};
watch(periodSelection, (v) => { if(v !== 'custom') setPeriod(v); }, { immediate: true });

// --- LÓGICA DE FILTRAGEM ---
const filteredReportItems = computed(() => {
    // Definimos os limites do dia usando o horário local para garantir precisão
    const startBound = new Date(customStartDate.value + 'T00:00:00').getTime();
    const endBound = new Date(customEndDate.value + 'T23:59:59.999').getTime();

    return props.orders.filter(o => {
        const d = new Date(o.created_at).getTime();

        if (d < startBound || d > endBound) return false;
        if (selectedSellers.value.length && !selectedSellers.value.includes(o.creator?.full_name)) return false;
        if (selectedClients.value.length && !selectedClients.value.includes(o.customer_name)) return false;

        if (selectedStatus.value && selectedStatus.value !== 'all') {
            if (o.status !== selectedStatus.value) return false;
        }

        if (selectedFabrics.value.length) {
            const hasFabric = o.order_items?.some((i:any) => selectedFabrics.value.includes(i.fabric_type));
            if (!hasFabric) return false;
        }

        return true;
    });
});

// --- LÓGICA DE PROCESSAMENTO DE DADOS (METROS vs KILOS) ---
const processedReportData = computed(() => {
  const orders = filteredReportItems.value;
  if (!orders.length) return null;

  const sellersMap = new Map();
  const clientsMap = new Map();
  const fabricsMap = new Map();

  let totalVal = 0, totalMet = 0, totalKg = 0;

  orders.forEach(o => {
    totalVal += o.total_value || 0;
    const seller = o.creator?.full_name || 'N/A';
    const client = o.customer_name || 'N/A';

    // Inicia Seller
    if(!sellersMap.has(seller)) sellersMap.set(seller, { name: seller, value: 0, meters: 0, kg: 0, orders: 0, clients: new Set() });
    const sStat = sellersMap.get(seller);
    sStat.value += o.total_value || 0;
    sStat.orders++;
    sStat.clients.add(client);

    // Inicia Client
    if(!clientsMap.has(client)) clientsMap.set(client, { name: client, value: 0, meters: 0, kg: 0, orders: 0 });
    const cStat = clientsMap.get(client);
    cStat.value += o.total_value || 0;
    cStat.orders++;

    // Verifica Items (Separação KG e M)
    o.order_items?.forEach((i:any) => {
        const fab = i.fabric_type || 'N/A';
        const unit = String(i.unit_of_measure || '').toLowerCase();
        const isKg = unit === 'kg' || unit === 'quilo' || fab.toLowerCase().includes('kg');

        const qty = isKg
            ? (Number(i.quantity_unit) > 0 ? Number(i.quantity_unit) : Number(i.quantity_meters || 0))
            : Number(i.quantity_meters || 0);

        if (isKg) {
            totalKg += qty;
            sStat.kg += qty;
            cStat.kg += qty;
        } else {
            totalMet += qty;
            sStat.meters += qty;
            cStat.meters += qty;
        }

        if(!fabricsMap.has(fab)) fabricsMap.set(fab, { name: fab, meters: 0, kg: 0, value: 0, orders: new Set(), stock_level: stockLevels.value.get(fab) || 0, isKg });
        const fStat = fabricsMap.get(fab);
        if (isKg) fStat.kg += qty; else fStat.meters += qty;
        fStat.value += i.total_value_items || 0;
        fStat.orders.add(String(o.order_number).padStart(4,'0'));
    });
  });

  return {
      summary: {
          totalValue: totalVal,
          totalMeters: totalMet,
          totalKg: totalKg,
          totalOrders: orders.length,
          sellerBreakdown: Array.from(sellersMap.values()).sort((a:any,b:any) => b.value - a.value),
          clientBreakdown: Array.from(clientsMap.values()).sort((a:any,b:any) => b.value - a.value),
          fabricBreakdown: Array.from(fabricsMap.values()).sort((a:any,b:any) => (b.meters + b.kg) - (a.meters + a.kg))
      }
  };
});

// --- EXPORTAÇÕES (EXCEL MULTI-ABA E PDF LAUDADO) ---
const generateExcel = async () => {
    if (filteredReportItems.value.length === 0) return;
    isGeneratingExcel.value = true;
    try {
        const wb = XLSX.utils.book_new();
        const groupedByMonth = new Map<string, any[]>();

        let grandTotalM = 0;
        let grandTotalKG = 0;
        let grandTotalVal = 0;

        filteredReportItems.value.forEach(order => {
            const date = new Date(order.created_at);
            const monthKey = format(date, 'MM/yyyy');
            if (!groupedByMonth.has(monthKey)) groupedByMonth.set(monthKey, []);

            let orderM = 0;
            let orderKG = 0;
            let itemsDesc: string[] = [];

            if (order.order_items && order.order_items.length > 0) {
                order.order_items.forEach((item: any) => {
                    const unit = String(item.unit_of_measure || '').toLowerCase();
                    const fab = String(item.fabric_type || '').toLowerCase();
                    const isKg = unit === 'kg' || unit === 'quilo' || fab.includes('kg');

                    const qty = isKg
                        ? (Number(item.quantity_unit) > 0 ? Number(item.quantity_unit) : Number(item.quantity_meters || 0))
                        : Number(item.quantity_meters || 0);

                    if (isKg) orderKG += qty; else orderM += qty;
                    itemsDesc.push(`${qty}${isKg?'kg':'m'} ${item.fabric_type}`);
                });
            }

            grandTotalM += orderM;
            grandTotalKG += orderKG;
            grandTotalVal += Number(order.total_value || 0);

            groupedByMonth.get(monthKey)!.push({
                ...order,
                dateStr: format(date, 'dd/MM/yyyy'),
                orderM,
                orderKG,
                itemsDesc: itemsDesc.join(' | ')
            });
        });

        // 1. Aba Resumo
        const summaryRows = [
            ["RELATÓRIO GERENCIAL DE VENDAS"],
            ["Período Filtrado:", `${format(parseISO(customStartDate.value), 'dd/MM/yyyy')} até ${format(parseISO(customEndDate.value), 'dd/MM/yyyy')}`],
            ["Gerado em:", format(new Date(), 'dd/MM/yyyy HH:mm')],
            [],
            ["MÊS REFERÊNCIA", "QTD PEDIDOS", "METRAGEM (M)", "QUILOGRAMAS (KG)", "FATURAMENTO BRUTO"]
        ];

        groupedByMonth.forEach((orders, monthKey) => {
            const monthM = orders.reduce((acc, o) => acc + o.orderM, 0);
            const monthKG = orders.reduce((acc, o) => acc + o.orderKG, 0);
            const monthVal = orders.reduce((acc, o) => acc + Number(o.total_value || 0), 0);
            summaryRows.push([monthKey, orders.length, monthM, monthKG, monthVal]);
        });

        summaryRows.push([]);
        summaryRows.push(["TOTAL GERAL", filteredReportItems.value.length, grandTotalM, grandTotalKG, grandTotalVal]);

        const wsSummary = XLSX.utils.aoa_to_sheet(summaryRows);
        wsSummary['!cols'] = [{ wch: 20 }, { wch: 15 }, { wch: 20 }, { wch: 20 }, { wch: 25 }];
        XLSX.utils.book_append_sheet(wb, wsSummary, "RESUMO GERAL");

        // 2. Planilhas Mensais
        groupedByMonth.forEach((orders, monthKey) => {
            const monthRows = [
                [`DETALHAMENTO DE VENDAS - ${monthKey}`],
                [],
                ["DATA", "PEDIDO", "CLIENTE", "VENDEDOR", "STATUS", "ITENS", "QTD (METROS)", "QTD (KG)", "VALOR TOTAL"]
            ];

            let subM = 0, subKG = 0, subVal = 0;

            orders.forEach(o => {
                subM += o.orderM;
                subKG += o.orderKG;
                subVal += Number(o.total_value || 0);

                monthRows.push([
                    o.dateStr,
                    o.order_number,
                    o.customer_name || 'Desconhecido',
                    o.creator?.full_name || '-',
                    getStatusText(o.status),
                    o.itemsDesc,
                    o.orderM,
                    o.orderKG,
                    Number(o.total_value || 0)
                ]);
            });

            monthRows.push([]);
            monthRows.push(["TOTAIS DO MÊS", "", "", "", "", "", subM, subKG, subVal]);

            const wsMonth = XLSX.utils.aoa_to_sheet(monthRows);
            wsMonth['!cols'] = [{ wch: 12 }, { wch: 10 }, { wch: 40 }, { wch: 20 }, { wch: 15 }, { wch: 45 }, { wch: 15 }, { wch: 15 }, { wch: 20 }];
            XLSX.utils.book_append_sheet(wb, wsMonth, monthKey.replace('/', '-'));
        });

        XLSX.writeFile(wb, `Relatorio_Vendas_${format(new Date(), 'dd-MM-yyyy')}.xlsx`);
        appStore.showSnackbar('Excel multi-abas gerado com sucesso!', 'success');
    } catch(e: any) {
        alert(`Erro ao gerar Excel: ${e.message}`);
    } finally {
        isGeneratingExcel.value = false;
    }
};

const generateFullReportPdf = async () => {
    if (filteredReportItems.value.length === 0) return;
    isGeneratingPdf.value = true;
    try {
        const doc = new jsPDF({ orientation: 'l', unit: 'mm', format: 'a4' });
        const pageWidth = doc.internal.pageSize.width;
        const pageHeight = doc.internal.pageSize.height;

        let y = await addHeader(doc, 'Relatório Analítico de Vendas');

        doc.setFontSize(10).setTextColor(100);
        doc.text(`Período: ${format(parseISO(customStartDate.value), 'dd/MM/yyyy')} a ${format(parseISO(customEndDate.value), 'dd/MM/yyyy')}`, 15, y);
        y += 8;

        let totalM = 0, totalKG = 0, totalVal = 0;

        const tableBody = filteredReportItems.value.map(order => {
            let orderM = 0;
            let orderKG = 0;

            order.order_items?.forEach((item: any) => {
                const unit = String(item.unit_of_measure || '').toLowerCase();
                const fab = String(item.fabric_type || '').toLowerCase();
                const isKg = unit === 'kg' || unit === 'quilo' || fab.includes('kg');

                const qty = isKg
                    ? (Number(item.quantity_unit) > 0 ? Number(item.quantity_unit) : Number(item.quantity_meters || 0))
                    : Number(item.quantity_meters || 0);

                if (isKg) orderKG += qty; else orderM += qty;
            });

            totalM += orderM;
            totalKG += orderKG;
            totalVal += Number(order.total_value || 0);

            return [
                format(new Date(order.created_at), 'dd/MM/yyyy'),
                `#${order.order_number}`,
                (order.customer_name || 'Desconhecido').substring(0, 35),
                (order.creator?.full_name || '-').substring(0, 20),
                formatNumber(orderM),
                formatNumber(orderKG),
                formatCurrency(order.total_value || 0)
            ];
        });

        autoTable(doc, {
            startY: y,
            head: [['Data', 'Pedido', 'Cliente', 'Vendedor', 'Metros (M)', 'Quilos (KG)', 'Valor Total']],
            body: tableBody,
            theme: 'striped',
            styles: { fontSize: 8, cellPadding: 2.5 },
            headStyles: { fillColor: [40, 40, 40], textColor: 255, fontStyle: 'bold', halign: 'center' },
            columnStyles: {
                0: { halign: 'center' },
                1: { halign: 'center', fontStyle: 'bold' },
                4: { halign: 'right', textColor: [0, 100, 0], fontStyle: 'bold' },
                5: { halign: 'right', textColor: [100, 0, 100], fontStyle: 'bold' },
                6: { halign: 'right', fontStyle: 'bold' }
            },
            foot: [['TOTAIS GERAIS', '', '', '', formatNumber(totalM), formatNumber(totalKG), formatCurrency(totalVal)]],
            footStyles: { fillColor: [240, 240, 240], textColor: [0, 0, 0], fontStyle: 'bold', halign: 'right' },
            didDrawPage: () => {
                const nowStr = format(new Date(), 'dd/MM/yyyy HH:mm');
                doc.setFontSize(7).setTextColor(150);
                doc.text(`Gerado via MJProcess em ${nowStr}`, 15, pageHeight - 10);
                doc.text(`Pág ${doc.internal.getNumberOfPages()}`, pageWidth - 15, pageHeight - 10, { align: 'right' });
            }
        });

        doc.save(`Relatorio_Vendas_${format(new Date(), 'yyyyMMdd_HHmm')}.pdf`);
        appStore.showSnackbar('PDF gerado com sucesso!', 'success');
    } catch(e: any) {
        alert(`Erro ao gerar PDF: ${e.message}`);
    } finally {
        isGeneratingPdf.value = false;
    }
};

// --- FUNÇÃO ESPECÍFICA: PRODUÇÃO EM ABERTO ---
const generateOpenProductionPdf = async () => {
  isGeneratingPdf.value = true;
  try {
    const doc = new jsPDF({ orientation: 'p', unit: 'mm', format: 'a4' });
    const pageWidth = doc.internal.pageSize.width;
    const pageHeight = doc.internal.pageSize.height;

    let y = await addHeader(doc, 'Relatório de Produção (Em Aberto)');

    const excludedStatuses = ['design_pending', 'delivered', 'completed', 'cancelled', 'budget'];
    const openOrders = props.orders.filter(o => !excludedStatuses.includes(o.status));

    if (openOrders.length === 0) {
      alert("Nenhum pedido em aberto encontrado.");
      return;
    }

    const localColorPalette = [ [207, 216, 220], [179, 229, 252], [188, 239, 192], [255, 224, 178], [225, 190, 231], [178, 235, 242] ];

    const tableBody = [];
    const orderColors: Record<string, number[]> = {};
    let colorIndex = 0;

    openOrders.sort((a, b) => new Date(a.created_at).getTime() - new Date(b.created_at).getTime());

    for (const order of openOrders) {
      const orderNumber = String(order.order_number);
      const color = localColorPalette[colorIndex % localColorPalette.length];
      orderColors[orderNumber] = color;
      colorIndex++;

      const items = order.order_items || [];
      const launchDate = format(parseISO(order.created_at), 'dd/MM');

      for (const item of items) {
        const unit = String(item.unit_of_measure || '').toLowerCase();
        const fab = String(item.fabric_type || '').toLowerCase();
        const isKg = unit === 'kg' || unit === 'quilo' || fab.includes('kg');
        const qty = isKg ? (Number(item.quantity_unit) > 0 ? Number(item.quantity_unit) : Number(item.quantity_meters || 0)) : Number(item.quantity_meters || 0);

        const baseDate = item.scheduled_date ? parseISO(item.scheduled_date) : parseISO(order.created_at);
        const completionDate = addBusinessDays(baseDate, 3);
        const forecastDate = getNextDeliveryDay(completionDate);

        tableBody.push({
            orderNumber,
            cells: [
                launchDate,
                `#${orderNumber.padStart(4, '0')}`,
                order.customer_name?.substring(0, 25) || 'N/A',
                item.fabric_type || '-',
                `${formatNumber(qty)} ${isKg?'kg':'m'}`,
                format(forecastDate, 'dd/MM/yyyy', { locale: ptBR }),
                ''
            ]
        });
      }
    }

    autoTable(doc, {
      startY: y,
      head: [['Data', 'Ped.', 'Cliente', 'Tecido', 'Qtd.', 'Entrega', 'OK']],
      body: tableBody.map(row => row.cells),
      theme: 'grid',
      willDrawCell: (data) => {
         if (data.section === 'body' && tableBody[data.row.index]) {
              const rowOrderNumber = tableBody[data.row.index].orderNumber;
              const color = orderColors[rowOrderNumber];
              if (color) doc.setFillColor(color[0], color[1], color[2]);
          }
      },
      columnStyles: {
        0: { cellWidth: 15, halign: 'center' },
        1: { cellWidth: 15, halign: 'center' },
        2: { cellWidth: 50 },
        3: { cellWidth: 40 },
        4: { cellWidth: 20, halign: 'right', fontStyle: 'bold' },
        5: { cellWidth: 25, halign: 'center' },
        6: { cellWidth: 15, halign: 'center' }
      },
      headStyles: { fillColor: [41, 128, 185], valign: 'middle', textColor: [255, 255, 255], fontSize: 8 },
      bodyStyles: { valign: 'middle', fontSize: 7, textColor: [0, 0, 0] },
    });

    doc.save(`Producao_Geral_Aberto_${format(new Date(), 'yyyy-MM-dd')}.pdf`);
  } catch (error) {
    alert("Ocorreu um erro ao gerar o PDF. Verifique o console.");
  } finally {
    isGeneratingPdf.value = false;
  }
};

const generateSellerRankingPdf = async (type: 'value'|'metrics') => {
 const data = processedReportData.value; if(!data) return;
 isGeneratingPdf.value = true;
 try {
  const doc = new jsPDF();
  const title = `Ranking de Vendedores (${type === 'value' ? 'Por Faturamento' : 'Por Volume'})`;
  let y = await addHeader(doc, title);

  const sorted = [...data.summary.sellerBreakdown].sort((a:any,b:any) => type === 'value' ? (b.value - a.value) : ((b.meters+b.kg) - (a.meters+a.kg)));

  autoTable(doc, {
      startY: y, head: [['Pos', 'Vendedor', 'Valor', 'Metros (M)', 'Quilos (KG)', 'Pedidos']],
      body: sorted.map((s:any, i:number) => [`#${i+1}`, s.name, formatCurrency(s.value), formatNumber(s.meters), formatNumber(s.kg), s.orders]),
      headStyles: { fillColor: [44, 62, 80] },
      columnStyles: { 2: {halign:'right'}, 3: {halign:'right'}, 4: {halign:'right'}, 5:{halign:'center'} }
  });
  doc.save(`ranking_vendedores_${type}.pdf`);
 } catch(e){} finally { isGeneratingPdf.value = false; }
};

const generateClientRankingPdf = async (type: 'value'|'metrics') => {
 const data = processedReportData.value; if(!data) return;
 isGeneratingPdf.value = true;
 try {
  const doc = new jsPDF();
  let y = await addHeader(doc, `Ranking de Clientes (${type === 'value' ? 'Faturamento' : 'Volume'})`);

  const sorted = [...data.summary.clientBreakdown].sort((a:any,b:any) => type === 'value' ? (b.value - a.value) : ((b.meters+b.kg) - (a.meters+a.kg)));

  autoTable(doc, {
      startY: y, head: [['Pos', 'Cliente', 'Valor', 'Metros (M)', 'Quilos (KG)', 'Pedidos']],
      body: sorted.slice(0, 50).map((s:any, i:number) => [`#${i+1}`, s.name, formatCurrency(s.value), formatNumber(s.meters), formatNumber(s.kg), s.orders]),
      headStyles: { fillColor: [39, 174, 96] },
      columnStyles: { 2: {halign:'right'}, 3: {halign:'right'}, 4: {halign:'right'}, 5:{halign:'center'} }
  });
  doc.save(`ranking_clientes.pdf`);
 } catch(e){} finally { isGeneratingPdf.value = false; }
};

const generateFabricRankingPdf = async () => {
 const data = processedReportData.value; if(!data) return;
 isGeneratingPdf.value = true;
 try {
  const doc = new jsPDF();
  let y = await addHeader(doc, 'Ranking de Bases (Mais Vendidos)');
  autoTable(doc, {
      startY: y, head: [['Pos', 'Tecido / Base', 'Metros (M)', 'Quilos (KG)', 'Valor Gerado', 'Nº Pedidos']],
      body: data.summary.fabricBreakdown.map((s:any, i:number) => [`#${i+1}`, s.name, formatNumber(s.meters), formatNumber(s.kg), formatCurrency(s.value), s.orders.size]),
      headStyles: { fillColor: [41, 128, 185] },
      columnStyles: { 2: {halign:'right'}, 3: {halign:'right'}, 4: {halign:'right'}, 5:{halign:'center'} }
  });
  doc.save(`ranking_tecidos.pdf`);
 } catch(e){} finally { isGeneratingPdf.value = false; }
};

const generateFabricUsageReportPdf = async (mode: 'summary'|'detailed') => {
 const data = processedReportData.value; if(!data) return;
 isGeneratingPdf.value = true;
 try {
  const doc = new jsPDF({ orientation: mode === 'detailed' ? 'landscape' : 'portrait' });
  let y = await addHeader(doc, `Consumo de Insumos (${mode === 'detailed' ? 'Detalhado' : 'Resumido'})`);
  autoTable(doc, {
      startY: y, head: [['Tecido', 'Tipo', 'Consumo', 'Estoque Atual (aprox)', mode === 'detailed' ? 'Pedidos Vinculados' : 'Qtd. Pedidos']],
      body: data.summary.fabricBreakdown.map((s:any) => [
          s.name,
          s.isKg ? 'KG' : 'Metro',
          formatNumber(s.isKg ? s.kg : s.meters),
          formatNumber(s.stock_level),
          mode === 'detailed' ? Array.from(s.orders).join(', ') : s.orders.size
      ]),
      headStyles: { fillColor: [251, 140, 0] },
      columnStyles: { 2: {halign:'right', fontStyle:'bold'}, 3: {halign:'right'}, 4: mode === 'detailed' ? { cellWidth: 120 } : { halign: 'center' } }
  });
  doc.save(`consumo_insumos_${mode}.pdf`);
 } catch(e){} finally { isGeneratingPdf.value = false; }
};

// --- FETCH AUDIT DATA ---
const fetchStockMovements = async () => {
  const dates = auditDates.value;
  if (!dates || (Array.isArray(dates) && dates.length === 0)) return;
  isLoadingMovements.value = true;
  try {
    let start = Array.isArray(dates) ? dates[0] : dates;
    let end = Array.isArray(dates) ? (dates[1] || dates[0]) : dates;
    const { data, error } = await supabase.rpc('get_stock_movements_report', {
      start_date: startOfDay(start).toISOString(), end_date: endOfDay(end).toISOString()
    });
    if (error) throw error;
    stockMovements.value = data || [];
  } catch (e: any) { fetchError.value = e.message; }
  finally { isLoadingMovements.value = false; }
};

onMounted(() => {
    if(props.show) {
        fetchStockLevels();
        setPeriod(periodSelection.value);
    }
});
</script>

<style scoped lang="scss">
.glass-dialog-container { backdrop-filter: blur(8px); }

.report-main-card {
  border-radius: 20px !important;
  box-shadow: 0 30px 60px -12px rgba(0, 0, 0, 0.6);
  height: 85vh;
}

/* SIDEBAR */
.report-sidebar { width: 280px; flex-shrink: 0; }
.bg-glass-panel { background: rgba(30, 30, 35, 0.95); border: 1px solid rgba(255, 255, 255, 0.1); }
.bg-gradient-dark { background: linear-gradient(135deg, #263238, #102027); }
.bg-surface-darker { background-color: rgba(0, 0, 0, 0.2); }
.bg-header-glass { background: rgba(255,255,255,0.03); backdrop-filter: blur(10px); }
.bg-surface-lighten-1 { background-color: rgba(255, 255, 255, 0.05); }
.bg-black-opacity { background: rgba(0, 0, 0, 0.3); }
.bg-black-opacity-05 { background: rgba(0, 0, 0, 0.15); }

/* TABS */
.custom-tabs .v-btn { text-transform: none; letter-spacing: 0.5px; opacity: 0.6; transition: 0.3s; }
.custom-tabs .v-slide-group-item--active { opacity: 1; color: rgb(var(--v-theme-primary)); background: linear-gradient(to top, rgba(var(--v-theme-primary), 0.1), transparent); }

/* FILTER GRID */
.filter-label { display: block; font-size: 0.7rem; font-weight: 700; text-transform: uppercase; margin-bottom: 6px; letter-spacing: 0.5px; }
.filter-mini { flex: 1; min-width: 140px; label { display: block; font-size: 0.65rem; font-weight: 700; text-transform: uppercase; margin-bottom: 4px; } }
.filter-mini.small { flex: 0 0 100px; min-width: 100px; }

/* CARDS */
.quick-report-card { transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1); height: 100%; }
.quick-report-card:hover { transform: translateY(-4px); border-color: rgba(var(--v-theme-primary), 0.3); box-shadow: 0 10px 30px -10px rgba(0, 0, 0, 0.5); }
.icon-box-md { width: 56px; height: 56px; }
.bg-gradient-primary { background: linear-gradient(135deg, #1976D2, #0D47A1); }
.bg-gradient-success { background: linear-gradient(135deg, #43A047, #1B5E20); }
.bg-gradient-info { background: linear-gradient(135deg, #0288D1, #01579B); }
.bg-gradient-warning { background: linear-gradient(135deg, #FB8C00, #E65100); }
.bg-gradient-error { background: linear-gradient(135deg, #FF5252, #D32F2F); }

/* TIMELINE */
.timeline-card { border-radius: 12px; overflow: hidden; transition: transform 0.2s; }
.timeline-card:hover { transform: translateX(4px); }

/* SCROLLBAR */
.custom-scrollbar::-webkit-scrollbar { width: 6px; }
.custom-scrollbar::-webkit-scrollbar-track { background: transparent; }
.custom-scrollbar::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.2); border-radius: 3px; }
.custom-scrollbar::-webkit-scrollbar-thumb:hover { background: rgba(128,128,128,0.4); }

/* UTILS */
.letter-spacing-1 { letter-spacing: 1px; }
.line-clamp-2 { display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; }
.glow-button { box-shadow: 0 0 15px rgba(var(--v-theme-primary), 0.4); }
.hover-brightness:hover { filter: brightness(1.2); }
.border-white-05 { border-color: rgba(255, 255, 255, 0.05) !important; }
.h-48 { height: 48px; }
.gap-2 { gap: 8px; }
.transition-all { transition: all 0.3s ease; }
</style>
