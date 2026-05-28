<template>
  <div
    class="finance-premium-layout font-sans fill-height d-flex flex-column relative overflow-hidden"
    :class="isDark ? 'bg-glass-dark text-white' : 'bg-grey-lighten-5 text-grey-darken-4'"
  >
    <div v-if="isDark" class="background-carousel-wrapper">
      <v-carousel cycle height="100%" hide-delimiters :show-arrows="false" interval="15000" class="fill-height">
        <v-carousel-item src="@/assets/1.jpg" cover></v-carousel-item>
        <v-carousel-item src="@/assets/2.jpg" cover></v-carousel-item>
        <v-carousel-item src="@/assets/3.jpg" cover></v-carousel-item>
      </v-carousel>
      <div class="background-overlay"></div>
    </div>

    <div class="content-wrapper d-flex flex-column fill-height z-10 relative">
      <div
        class="header-bar px-4 py-3 px-md-6 py-md-4 d-flex flex-column flex-lg-row align-lg-start justify-space-between flex-shrink-0"
        :class="isDark ? 'bg-glass-header border-bottom-white-05' : 'bg-white border-b border-grey-lighten-2 shadow-sm'"
        style="gap: 14px;"
      >
        <div class="d-flex flex-column min-w-0">
          <div class="breadcrumb text-caption d-none d-md-block">
            <span class="opacity-70">Comando Central</span>
            <span class="mx-2 opacity-50">></span>
            <span class="font-weight-bold">Financeiro & Fiscal</span>
          </div>

          <div class="d-flex align-center gap-3 mt-1 min-w-0">
            <div class="icon-box-lg bg-gradient-purple rounded-xl elevation-8 d-flex align-center justify-center flex-shrink-0">
              <v-icon color="white" size="30">mdi-finance</v-icon>
            </div>
            <div class="min-w-0">
              <h1 class="text-h5 text-md-h4 font-weight-black tracking-tight leading-none text-truncate" :class="isDark ? 'text-white' : 'text-grey-darken-4'">
                Painel Financeiro
              </h1>
              <div class="text-caption text-md-body-2 mt-1" :class="isDark ? 'text-white-70' : 'text-grey-darken-1'">
                Fluxo de caixa, documentos fiscais e vencimentos em uma única visão operacional.
              </div>
            </div>
          </div>

          <div class="d-flex align-center gap-3 mt-3 overflow-x-auto hide-scrollbar pb-1 w-100">
            <v-btn
              v-for="btn in contextButtons"
              :key="btn.id"
              size="x-small"
              height="26"
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

        <div class="d-flex flex-column flex-sm-row align-sm-center gap-6 flex-shrink-0 header-actions">
          <div class="clock-box px-4 rounded-lg border-thin d-flex align-center gap-3" style="height: 38px;" :class="isDark ? 'bg-glass-panel border-white-05' : 'bg-white border-grey-lighten-2'">
            <div class="font-weight-black font-mono leading-none" style="font-size: 14px;" :class="isDark ? 'text-white' : 'text-grey-darken-4'">{{ currentTime }}</div>
            <div class="d-flex align-center gap-1 text-caption font-weight-bold">
              <span class="status-dot bg-success pulse-success" style="width: 6px; height: 6px;"></span>
              <span class="text-success font-weight-black" style="font-size: 10px; letter-spacing: 0.5px;">ONLINE</span>
            </div>
          </div>

          <v-btn
            color="success"
            variant="flat"
            class="btn-3d font-weight-black px-4"
            height="38"
            prepend-icon="mdi-refresh"
            :loading="loading"
            @click="fetchAll"
          >
            Atualizar
          </v-btn>
        </div>
      </div>

      <main class="dashboard-scroll flex-grow-1 overflow-y-auto custom-scroll px-4 px-md-6 py-4">

        <section class="d-flex flex-column flex-lg-row align-lg-center justify-space-between gap-3 mb-4">
          <div>
            <div class="section-eyebrow text-success">Visão Consolidada</div>
            <h2 class="section-title text-h5 font-weight-black" :class="isDark ? 'text-white' : 'text-grey-darken-4'">Resumo financeiro do contexto atual</h2>
          </div>

          <div class="d-flex flex-wrap align-center gap-4">
            <div class="premium-date-wrapper d-flex align-center px-3 py-1 rounded-lg border-thin shadow-sm" :class="isDark ? 'bg-glass-panel border-white-05' : 'bg-white border-grey-lighten-2'">
              <v-icon size="18" class="opacity-50 mr-2" :color="isDark ? 'white' : 'primary'">mdi-calendar-range</v-icon>
              <v-text-field v-model="globalStartDate" type="date" density="compact" variant="plain" hide-details class="custom-date-input" style="max-width: 110px;" @change="onCustomDateChange" :color="isDark ? 'white' : 'primary'"/>
              <span class="text-caption font-weight-black opacity-50 mx-2 text-uppercase" style="font-size: 10px;">Até</span>
              <v-text-field v-model="globalEndDate" type="date" density="compact" variant="plain" hide-details class="custom-date-input" style="max-width: 110px;" @change="onCustomDateChange" :color="isDark ? 'white' : 'primary'"/>
            </div>

            <div class="divider-vertical d-none d-sm-block mx-1" :class="isDark ? 'bg-white-05' : 'bg-grey-lighten-3'"></div>

            <v-btn-toggle
              v-model="timeFilter"
              density="compact"
              color="primary"
              class="rounded border-thin btn-3d"
              divided
              variant="outlined"
              @update:model-value="onPeriodChange"
            >
              <v-btn value="today" class="text-none font-weight-bold px-4">Hoje</v-btn>
              <v-btn value="month" class="text-none font-weight-bold px-4">Este mês</v-btn>
              <v-btn value="year" class="text-none font-weight-bold px-4">Este ano</v-btn>
            </v-btn-toggle>
          </div>
        </section>

        <v-row dense class="mb-5 kpi-row">
          <v-col cols="12" sm="6" lg="4">
            <v-card class="kpi-card kpi-rect bg-gradient-green hover-elevate py-3 px-4" v-ripple :to="{ name: 'FinancialReceivables' }">
              <div class="kpi-bg-icon"><v-icon>mdi-arrow-up-bold-circle-outline</v-icon></div>
              <div class="d-flex flex-column position-relative z-10 h-100 justify-space-between">
                <div class="d-flex align-center" style="gap: 8px;">
                    <v-icon size="18" class="opacity-80">mdi-cash-plus</v-icon>
                    <span class="kpi-label">RECEITAS ({{ filterLabel }})</span>
                </div>
                <div class="kpi-number-group my-2">
                    <span class="text-body-2 font-weight-medium mr-1 opacity-70">R$</span>
                    <span class="kpi-value text-h4">{{ formatCurrencyNoSymbol(kpis.receitas) }}</span>
                </div>
                <div class="kpi-footer opacity-80 mt-1 d-flex align-center justify-space-between w-100">
                    <span class="d-flex align-center"><v-icon size="14" class="mr-1">mdi-check-circle</v-icon> Confirmadas/Pagas</span>
                    <v-icon size="16">mdi-arrow-right</v-icon>
                </div>
              </div>
            </v-card>
          </v-col>

          <v-col cols="12" sm="6" lg="4">
            <v-card class="kpi-card kpi-rect bg-gradient-red hover-elevate py-3 px-4" v-ripple :to="{ name: 'FinancialPayables' }">
              <div class="kpi-bg-icon"><v-icon>mdi-arrow-down-bold-circle-outline</v-icon></div>
              <div class="d-flex flex-column position-relative z-10 h-100 justify-space-between">
                <div class="d-flex align-center" style="gap: 8px;">
                    <v-icon size="18" class="opacity-80">mdi-cash-minus</v-icon>
                    <span class="kpi-label">DESPESAS ({{ filterLabel }})</span>
                </div>
                <div class="kpi-number-group my-2">
                    <span class="text-body-2 font-weight-medium mr-1 opacity-70">R$</span>
                    <span class="kpi-value text-h4">{{ formatCurrencyNoSymbol(kpis.despesas) }}</span>
                </div>
                <div class="kpi-footer opacity-80 mt-1 d-flex align-center justify-space-between w-100">
                    <span class="d-flex align-center"><v-icon size="14" class="mr-1">mdi-check-circle</v-icon> Pagas/Baixadas</span>
                    <v-icon size="16">mdi-arrow-right</v-icon>
                </div>
              </div>
            </v-card>
          </v-col>

          <v-col cols="12" lg="4">
            <v-card class="kpi-card kpi-rect bg-gradient-info hover-elevate py-3 px-4" v-ripple>
              <div class="kpi-bg-icon"><v-icon>mdi-scale-balance</v-icon></div>
              <div class="d-flex flex-column position-relative z-10 h-100 justify-space-between">
                <div class="d-flex align-center" style="gap: 8px;">
                    <v-icon size="18" class="opacity-80">mdi-bank</v-icon>
                    <span class="kpi-label">SALDO OPERACIONAL</span>
                </div>
                <div class="kpi-number-group my-2">
                    <span class="text-body-2 font-weight-medium mr-1 opacity-70">R$</span>
                    <span class="kpi-value text-h4">{{ formatCurrencyNoSymbol(kpis.saldo) }}</span>
                </div>
                <div class="kpi-footer opacity-80 mt-1 d-flex align-center justify-space-between w-100">
                    <span class="d-flex align-center">
                      <v-icon size="14" class="mr-1">{{ kpis.saldo >= 0 ? 'mdi-trending-up' : 'mdi-trending-down' }}</v-icon>
                      {{ kpis.saldo >= 0 ? 'Superávit' : 'Déficit' }}
                    </span>
                    <v-icon size="16">mdi-chart-line</v-icon>
                </div>
              </div>
            </v-card>
          </v-col>
        </v-row>

        <v-card class="premium-panel mb-6 border-thin overflow-hidden" :class="isDark ? 'glass-card border-white-05' : 'bg-white shadow-sm'" :elevation="0">
            <div class="px-6 py-4 border-b d-flex justify-space-between align-center flex-wrap gap-3" :class="isDark ? 'border-white-05' : 'border-grey-lighten-2'">
                <div>
                    <div class="section-eyebrow text-primary">Análise Gráfica</div>
                    <h2 class="section-title text-h6 font-weight-black" :class="isDark ? 'text-white' : 'text-grey-darken-4'">Fluxo de Caixa Consolidado</h2>
                </div>
                <div class="d-flex align-center gap-2">
                    <v-chip size="small" color="success" variant="flat" class="font-weight-bold chip-3d">Receitas</v-chip>
                    <v-chip size="small" color="error" variant="flat" class="font-weight-bold chip-3d">Despesas</v-chip>
                    <v-chip size="small" color="primary" variant="flat" class="font-weight-bold chip-3d">Saldo</v-chip>
                </div>
            </div>
            <div class="pa-4">
                <apexchart type="area" height="350" :options="chartOptions" :series="chartSeries"></apexchart>
            </div>
        </v-card>

        <v-card class="premium-panel mb-6 border-thin overflow-hidden" :class="isDark ? 'glass-card border-white-05' : 'bg-white shadow-sm'" :elevation="0">
            <div class="px-6 py-4 border-b d-flex justify-space-between align-center flex-wrap gap-3" :class="isDark ? 'border-white-05' : 'border-grey-lighten-2'">
                <div>
                    <div class="section-eyebrow text-warning">Central Fiscal</div>
                    <h2 class="section-title text-h6 font-weight-black" :class="isDark ? 'text-white' : 'text-grey-darken-4'">NFe, NFCe e CTe</h2>
                </div>
                <div class="d-flex flex-wrap align-center gap-2">
                    <v-btn color="green-darken-2" variant="flat" class="btn-3d font-weight-black" height="38" prepend-icon="mdi-microsoft-excel" :loading="exportingFiscal" @click="exportFiscalExcel">
                        Excel
                    </v-btn>
                    <v-btn color="indigo" variant="flat" class="btn-3d font-weight-black" height="38" prepend-icon="mdi-folder-download" :loading="bulkFiscalDownload.loading" @click="downloadSelectedFiscalXml">
                        Baixar Selecionados
                    </v-btn>
                </div>
            </div>

            <div class="px-6 py-4">
                <div class="d-flex flex-wrap align-center gap-3 mb-4">
                    <v-text-field v-model="fiscalFilters.search" style="min-width: 200px;" density="compact" variant="outlined" hide-details prepend-inner-icon="mdi-magnify" label="Buscar destinatário ou chave" class="ui-field flex-grow-1" :color="isDark ? 'white' : 'primary'"/>
                    <v-select v-model="fiscalFilters.type" style="max-width: 150px;" :items="fiscalTypeOptions" density="compact" variant="outlined" hide-details label="Tipo" class="ui-field flex-grow-0" :color="isDark ? 'white' : 'primary'"/>
                    <v-select v-model="fiscalFilters.status" style="max-width: 140px;" :items="fiscalStatusOptions" density="compact" variant="outlined" hide-details label="Status" class="ui-field flex-grow-0" :color="isDark ? 'white' : 'primary'"/>
                    <v-text-field v-model="fiscalFilters.start" style="max-width: 130px;" type="date" density="compact" variant="outlined" hide-details label="De" class="ui-field flex-grow-0" :color="isDark ? 'white' : 'primary'"/>
                    <v-text-field v-model="fiscalFilters.end" style="max-width: 130px;" type="date" density="compact" variant="outlined" hide-details label="Até" class="ui-field flex-grow-0" :color="isDark ? 'white' : 'primary'"/>
                </div>

                <v-row dense class="mb-4">
                    <v-col cols="6" md="3" v-for="card in fiscalCards" :key="card.key">
                        <v-card class="mini-kpi pa-3 d-flex align-center gap-3 cursor-pointer btn-3d" :class="card.className" @click="fiscalFilters.type = card.filter">
                            <v-icon size="28">{{ card.icon }}</v-icon>
                            <div>
                                <div class="text-[10px] font-weight-black text-uppercase opacity-80">{{ card.label }}</div>
                                <div class="text-h6 font-weight-black leading-none mt-1">{{ card.value }}</div>
                            </div>
                        </v-card>
                    </v-col>
                </v-row>

                <div class="grid-scroll border-thin rounded-lg overflow-hidden custom-scroll mt-4">
                    <div class="grid-header sticky-head" :class="[gridFiscalClass, isDark ? 'grid-surface-dark border-bottom-white-05' : 'grid-surface-light border-grey-lighten-2 border-b']">
                        <div class="cell center px-2"><v-checkbox-btn :model-value="allFiscalSelected" density="compact" color="success" @update:model-value="toggleAllFiscal" class="chk-fixed" /></div>
                        <div class="cell header-text center px-2">Tipo</div>
                        <div v-if="isGlobal" class="cell header-text px-3">Empresa</div>
                        <div class="cell header-text px-3">Pessoa / Fornecedor</div>
                        <div class="cell header-text px-3">Chave de Acesso</div>
                        <div class="cell header-text center px-2">Emissão</div>
                        <div class="cell header-text right px-3">Valor Total</div>
                        <div class="cell header-text center px-2">Status</div>
                        <div class="cell header-text center px-2">Ações</div>
                    </div>

                    <div v-if="fiscalLoading" class="d-flex flex-column justify-center align-center h-100 py-10">
                        <v-progress-circular indeterminate color="primary" size="32" width="3"></v-progress-circular>
                    </div>
                    <div v-else-if="paginatedFiscalDocuments.length === 0" class="d-flex flex-column justify-center align-center h-100 opacity-60 gap-2 py-10">
                        <v-icon size="48" color="grey-lighten-1">mdi-file-search-outline</v-icon>
                        <span class="text-body-2 font-weight-medium">Nenhum documento encontrado.</span>
                    </div>

                    <template v-else>
                        <div v-for="(note, index) in paginatedFiscalDocuments" :key="note.uid" class="grid-row zebra-row transition-colors" :class="[gridFiscalClass, isDark ? 'grid-row-dark border-bottom-white-05' : 'grid-row-light border-grey-lighten-2 border-b', zebraClass(index)]">
                            <div class="cell center px-2">
                                <v-checkbox-btn v-model="selectedFiscalIds" :value="note.uid" density="compact" color="success" class="chk-fixed" />
                            </div>

                            <div class="cell center min-w-0 px-2">
                                <span class="solid-chip chip-3d text-truncate" style="max-width: 100%;" :class="getFiscalTypeClass(note.type)">{{ note.typeLabel }}</span>
                            </div>

                            <div v-if="isGlobal" class="cell min-w-0 px-3">
                                <span class="list-text-11 font-weight-bold text-truncate d-block w-100 opacity-80" :title="getCompanyNameByCnpj(note.cnpj)">{{ getCompanyNameByCnpj(note.cnpj) }}</span>
                            </div>

                            <div class="cell min-w-0 px-3">
                                <span class="list-text-11 font-weight-bold text-truncate d-block w-100" :title="note.personName">{{ note.personName }}</span>
                            </div>

                            <div class="cell min-w-0 px-3">
                                <span class="font-mono text-[10px] letter-spacing-1 text-truncate d-block w-100 opacity-80" :title="note.key">{{ formatKey(note.key) }}</span>
                            </div>

                            <div class="cell center px-2">
                                <span class="list-text-11 font-mono opacity-80">{{ formatDate(note.issueDate) }}</span>
                            </div>

                            <div class="cell right px-3">
                                <span class="list-text-11 font-mono font-weight-black" :class="isDark ? 'text-success-lighten-1' : 'text-success-darken-2'">{{ formatCurrency(note.value) }}</span>
                            </div>

                            <div class="cell center min-w-0 px-2">
                                <span class="solid-chip chip-3d text-truncate" style="max-width: 100%;" :class="getStatusClass(note.status)">{{ normalizeStatus(note.status) }}</span>
                            </div>

                            <div class="cell center px-2">
                                <div class="actions-inline w-100 justify-center">
                                    <v-tooltip text="Baixar XML" location="top" content-class="tooltip-custom">
                                        <template v-slot:activator="{ props }">
                                            <v-btn v-bind="props" icon size="small" class="action-btn bg-indigo-darken-1 text-white btn-3d rounded-sm" :disabled="!canDownloadFiscal(note)" @click="downloadFiscalXml(note)">
                                                <v-icon size="16">mdi-xml</v-icon>
                                            </v-btn>
                                        </template>
                                    </v-tooltip>
                                    <v-tooltip text="Abrir Módulo" location="top" content-class="tooltip-custom">
                                        <template v-slot:activator="{ props }">
                                            <v-btn v-bind="props" icon size="small" class="action-btn action-edit btn-3d rounded-sm" @click="openFiscalModule(note)">
                                                <v-icon size="16">mdi-open-in-new</v-icon>
                                            </v-btn>
                                        </template>
                                    </v-tooltip>
                                </div>
                            </div>
                        </div>
                    </template>
                </div>

                <div class="d-flex align-center justify-space-between mt-4">
                    <span class="text-caption font-weight-bold opacity-70">{{ filteredFiscalDocuments.length }} documento(s) fiscal(is)</span>
                    <v-pagination v-model="fiscalPage" :length="fiscalPageCount" density="compact" active-color="primary" variant="tonal" size="small" :total-visible="5" />
                </div>
            </div>
        </v-card>

        <v-row dense class="mb-5">
            <v-col cols="12" lg="6">
                <v-card class="premium-panel h-100 border-thin d-flex flex-column" :class="isDark ? 'glass-card border-white-05' : 'bg-white shadow-sm'" :elevation="0">
                    <div class="px-5 py-4 border-b d-flex justify-space-between align-center" :class="isDark ? 'border-white-05' : 'border-grey-lighten-2'">
                        <div>
                            <div class="section-eyebrow text-success">Contas a Receber</div>
                            <h2 class="section-title text-h6 font-weight-black" :class="isDark ? 'text-white' : 'text-grey-darken-4'">Títulos Ativos</h2>
                        </div>
                        <v-btn color="success" variant="flat" class="btn-3d font-weight-black" height="36" prepend-icon="mdi-open-in-new" @click="router.push({ name: 'FinancialReceivables' })">Acessar</v-btn>
                    </div>
                    <div class="pa-4 flex-grow-1 d-flex flex-column">
                        <finance-grid-controls v-model:search="receivableFilters.search" v-model:status="receivableFilters.status" v-model:start="receivableFilters.start" v-model:end="receivableFilters.end" />

                        <div class="grid-scroll border-thin rounded-lg overflow-hidden custom-scroll flex-grow-1">
                            <div class="grid-header sticky-head finance-grid-layout" :class="isDark ? 'grid-surface-dark border-bottom-white-05' : 'grid-surface-light border-grey-lighten-2 border-b'">
                                <div class="cell header-text">Cliente</div>
                                <div class="cell header-text">Descrição</div>
                                <div class="cell header-text center">Venc.</div>
                                <div class="cell header-text right pr-4">Valor</div>
                                <div class="cell header-text center">Status</div>
                                <div class="cell header-text center">Ação</div>
                            </div>

                            <div v-if="receivablesLoading" class="d-flex justify-center align-center py-6"><v-progress-circular indeterminate color="success"></v-progress-circular></div>
                            <div v-else-if="paginatedReceivables.length === 0" class="d-flex justify-center align-center py-6 opacity-60"><v-icon class="mr-2">mdi-cash-remove</v-icon> <span class="text-caption">Nenhum título</span></div>

                            <template v-else>
                                <div v-for="(item, index) in paginatedReceivables" :key="item.id" class="grid-row finance-grid-layout zebra-row transition-colors" :class="[isDark ? 'grid-row-dark border-bottom-white-05' : 'grid-row-light border-grey-lighten-2 border-b', zebraClass(index)]">
                                    <div class="cell min-w-0">
                                        <div class="d-flex flex-column">
                                            <span class="list-text-11 font-weight-bold text-truncate w-100">{{ getFinanceEntity(item, 'receivable') }}</span>
                                            <span class="text-[9px] opacity-70 font-mono">Ref: {{ item.order_number || item.orders?.order_number || 'S/N' }}</span>
                                        </div>
                                    </div>
                                    <div class="cell min-w-0">
                                        <span class="list-text-11 text-truncate w-100">{{ item.description || 'Recebimento' }}</span>
                                    </div>
                                    <div class="cell center"><span class="list-text-11 font-mono opacity-80">{{ formatDate(item.due_date) }}</span></div>
                                    <div class="cell right pr-4"><span class="list-text-11 font-mono font-weight-black text-success">{{ formatCurrency(Number(item.value || 0) - Number(item.discount || 0)) }}</span></div>
                                    <div class="cell center"><span class="solid-chip chip-3d" :class="getFinanceStatusClass(item)">{{ getFinanceStatusLabel(item) }}</span></div>
                                    <div class="cell center">
                                      <v-btn icon size="small" class="action-btn action-edit btn-3d rounded-sm" @click="router.push({ name: 'FinancialReceivables' })"><v-icon size="16">mdi-eye</v-icon></v-btn>
                                    </div>
                                </div>
                            </template>
                        </div>
                        <div class="d-flex align-center justify-space-between mt-3">
                            <span class="text-caption font-weight-bold opacity-70">{{ filteredReceivables.length }} título(s)</span>
                            <v-pagination v-model="receivablePage" :length="receivablePageCount" density="compact" active-color="success" variant="tonal" size="small" />
                        </div>
                    </div>
                </v-card>
            </v-col>

            <v-col cols="12" lg="6">
                <v-card class="premium-panel h-100 border-thin d-flex flex-column" :class="isDark ? 'glass-card border-white-05' : 'bg-white shadow-sm'" :elevation="0">
                    <div class="px-5 py-4 border-b d-flex justify-space-between align-center" :class="isDark ? 'border-white-05' : 'border-grey-lighten-2'">
                        <div>
                            <div class="section-eyebrow text-error">Contas a Pagar</div>
                            <h2 class="section-title text-h6 font-weight-black" :class="isDark ? 'text-white' : 'text-grey-darken-4'">Títulos Ativos</h2>
                        </div>
                        <v-btn color="error" variant="flat" class="btn-3d font-weight-black" height="36" prepend-icon="mdi-open-in-new" @click="router.push({ name: 'FinancialPayables' })">Acessar</v-btn>
                    </div>
                    <div class="pa-4 flex-grow-1 d-flex flex-column">
                        <finance-grid-controls v-model:search="payableFilters.search" v-model:status="payableFilters.status" v-model:start="payableFilters.start" v-model:end="payableFilters.end" />

                        <div class="grid-scroll border-thin rounded-lg overflow-hidden custom-scroll flex-grow-1">
                            <div class="grid-header sticky-head finance-grid-layout" :class="isDark ? 'grid-surface-dark border-bottom-white-05' : 'grid-surface-light border-grey-lighten-2 border-b'">
                                <div class="cell header-text">Fornecedor</div>
                                <div class="cell header-text">Descrição</div>
                                <div class="cell header-text center">Venc.</div>
                                <div class="cell header-text right pr-4">Valor</div>
                                <div class="cell header-text center">Status</div>
                                <div class="cell header-text center">Ação</div>
                            </div>

                            <div v-if="payablesLoading" class="d-flex justify-center align-center py-6"><v-progress-circular indeterminate color="error"></v-progress-circular></div>
                            <div v-else-if="paginatedPayables.length === 0" class="d-flex justify-center align-center py-6 opacity-60"><v-icon class="mr-2">mdi-cash-remove</v-icon> <span class="text-caption">Nenhum título</span></div>

                            <template v-else>
                                <div v-for="(item, index) in paginatedPayables" :key="item.id" class="grid-row finance-grid-layout zebra-row transition-colors" :class="[isDark ? 'grid-row-dark border-bottom-white-05' : 'grid-row-light border-grey-lighten-2 border-b', zebraClass(index)]">
                                    <div class="cell min-w-0">
                                        <div class="d-flex flex-column">
                                            <span class="list-text-11 font-weight-bold text-truncate w-100">{{ getFinanceEntity(item, 'payable') }}</span>
                                            <span class="text-[9px] opacity-70 font-mono text-truncate w-100">{{ item.category || item.chart_of_accounts?.name || 'Sem cat.' }}</span>
                                        </div>
                                    </div>
                                    <div class="cell min-w-0">
                                        <span class="list-text-11 text-truncate w-100">{{ item.description || 'Pagamento' }}</span>
                                    </div>
                                    <div class="cell center"><span class="list-text-11 font-mono opacity-80">{{ formatDate(item.due_date) }}</span></div>
                                    <div class="cell right pr-4"><span class="list-text-11 font-mono font-weight-black text-error">{{ formatCurrency(Number(item.value || 0) - Number(item.discount || 0)) }}</span></div>
                                    <div class="cell center"><span class="solid-chip chip-3d" :class="getFinanceStatusClass(item)">{{ getFinanceStatusLabel(item) }}</span></div>
                                    <div class="cell center">
                                      <v-btn icon size="small" class="action-btn action-edit btn-3d rounded-sm" @click="router.push({ name: 'FinancialPayables' })"><v-icon size="16">mdi-eye</v-icon></v-btn>
                                    </div>
                                </div>
                            </template>
                        </div>
                        <div class="d-flex align-center justify-space-between mt-3">
                            <span class="text-caption font-weight-bold opacity-70">{{ filteredPayables.length }} título(s)</span>
                            <v-pagination v-model="payablePage" :length="payablePageCount" density="compact" active-color="error" variant="tonal" size="small" />
                        </div>
                    </div>
                </v-card>
            </v-col>
        </v-row>

      </main>
    </div>

    <v-dialog v-model="bulkFiscalDownload.show" persistent max-width="400" content-class="blur-backdrop">
      <v-card class="premium-panel border-thin overflow-hidden" :class="isDark ? 'bg-glass-dark border-white-05 text-white' : 'bg-white text-grey-darken-4'">
        <div class="pa-6 text-center d-flex flex-column align-center">
          <div class="icon-box-lg rounded-circle mb-4 d-flex align-center justify-center" :class="isDark ? 'bg-indigo-darken-4' : 'bg-indigo-lighten-5'">
            <v-icon :color="isDark ? 'indigo-lighten-2' : 'indigo'" size="32">mdi-cloud-download</v-icon>
          </div>
          <h3 class="text-h6 font-weight-black mb-1">Processando Lote Fiscal</h3>
          <p class="text-caption opacity-70 mb-5">{{ bulkFiscalDownload.status }}</p>

          <v-progress-linear
            :model-value="(bulkFiscalDownload.current / bulkFiscalDownload.total) * 100"
            color="indigo"
            height="8"
            rounded
            class="mb-2"
          ></v-progress-linear>

          <div class="d-flex justify-space-between w-100 text-caption font-weight-bold font-mono">
            <span class="text-indigo">{{ bulkFiscalDownload.current }} processados</span>
            <span class="opacity-50">Total: {{ bulkFiscalDownload.total }}</span>
          </div>
        </div>
      </v-card>
    </v-dialog>

  </div>
</template>

<script setup lang="ts">
import { computed, defineComponent, h, onMounted, onUnmounted, reactive, ref, resolveComponent, watch } from 'vue';
import { useRouter } from 'vue-router';
import { format, startOfMonth, endOfMonth, startOfYear, endOfYear, parseISO, isValid } from 'date-fns';
import { ptBR } from 'date-fns/locale';
import axios from 'axios';
import JSZip from 'jszip';
import * as XLSX from 'xlsx';
import { supabase } from '@/api/supabase';
import { useThemeStore } from '@/stores/themeStore';
import { useAppStore } from '@/stores/app';
import { useCompanyStore } from '@/stores/company';

// Componente ApexCharts
import VueApexCharts from 'vue3-apexcharts';

// Mini componente para os filtros das grids de recebíveis/pagáveis
const FinanceGridControls = defineComponent({
  name: 'FinanceGridControls',
  props: {
    search: { type: String, default: '' },
    status: { type: String, default: 'todos' },
    start: { type: String, default: '' },
    end: { type: String, default: '' },
  },
  emits: ['update:search', 'update:status', 'update:start', 'update:end'],
  setup(props, { emit }) {
    const VTextField = resolveComponent('v-text-field');
    const VSelect = resolveComponent('v-select');
    const statusItems = [
      { title: 'Todos', value: 'todos' },
      { title: 'Pago', value: 'pago' },
      { title: 'Em aberto', value: 'em_aberto' },
      { title: 'Atrasado', value: 'atrasado' },
    ];
    return () => h('div', { class: 'd-flex flex-wrap gap-2 mb-3' }, [
      h(VTextField, { modelValue: props.search, 'onUpdate:modelValue': (v: string) => emit('update:search', v), density: 'compact', variant: 'outlined', hideDetails: true, prependInnerIcon: 'mdi-magnify', placeholder: 'Pesquisar...', class: 'ui-field flex-grow-1', style: 'min-width: 150px;' }),
      h(VSelect, { modelValue: props.status, 'onUpdate:modelValue': (v: string) => emit('update:status', v), items: statusItems, density: 'compact', variant: 'outlined', hideDetails: true, label: 'Status', class: 'ui-field', style: 'max-width: 130px;' }),
      h(VTextField, { modelValue: props.start, 'onUpdate:modelValue': (v: string) => emit('update:start', v), type: 'date', density: 'compact', variant: 'outlined', hideDetails: true, class: 'ui-field', style: 'max-width: 130px;' }),
      h(VTextField, { modelValue: props.end, 'onUpdate:modelValue': (v: string) => emit('update:end', v), type: 'date', density: 'compact', variant: 'outlined', hideDetails: true, class: 'ui-field', style: 'max-width: 130px;' }),
    ]);
  }
});

const SEFAZ_PROXY_URL = import.meta.env.VITE_SEFAZ_PROXY_URL || 'https://sefaz-proxy-dujl.onrender.com';
const themeStore = useThemeStore();
const appStore = useAppStore();
const companyStore = useCompanyStore();
const router = useRouter();

const isDark = computed(() => themeStore.currentMode !== 'light');
const isGlobal = computed(() => companyStore.context === 'global');
const gridFiscalClass = computed(() => isGlobal.value ? 'fiscal-grid-layout-global' : 'fiscal-grid-layout');

const loading = ref(false);
const fiscalLoading = ref(false);
const receivablesLoading = ref(false);
const payablesLoading = ref(false);
const exportingFiscal = ref(false);
const timeFilter = ref<'today' | 'month' | 'year' | null>('month');
const globalStartDate = ref(format(startOfMonth(new Date()), 'yyyy-MM-dd'));
const globalEndDate = ref(format(endOfMonth(new Date()), 'yyyy-MM-dd'));
const currentTime = ref('');
const currentDate = ref('');
let clockInterval: ReturnType<typeof setInterval>;

const companies = ref<any[]>([]);
const kpis = ref({ receitas: 0, despesas: 0, saldo: 0 });
const cashflowSeries = ref<any[]>([]);
const fiscalDocuments = ref<any[]>([]);
const selectedFiscalIds = ref<string[]>([]);
const receivables = ref<any[]>([]);
const payables = ref<any[]>([]);

const fiscalPage = ref(1);
const receivablePage = ref(1);
const payablePage = ref(1);
const itemsPerPage = 30;

const bulkFiscalDownload = reactive({ show: false, loading: false, current: 0, total: 0, status: '' });

const fiscalFilters = reactive({ search: '', type: 'todos', status: 'todos', start: '', end: '' });

const receivableFilters = reactive({
  search: '', status: 'todos',
  start: format(startOfMonth(new Date()), 'yyyy-MM-dd'),
  end: format(endOfMonth(new Date()), 'yyyy-MM-dd')
});

const payableFilters = reactive({
  search: '', status: 'todos',
  start: format(startOfMonth(new Date()), 'yyyy-MM-dd'),
  end: format(endOfMonth(new Date()), 'yyyy-MM-dd')
});

const fiscalTypeOptions = [
  { title: 'Todos', value: 'todos' },
  { title: 'NFe Emitidas', value: 'nfe_emitida' },
  { title: 'NFe Recebidas', value: 'nfe_recebida' },
  { title: 'NFCe Emitidas', value: 'nfce_emitida' },
  { title: 'CTe', value: 'cte' },
];
const fiscalStatusOptions = [
  { title: 'Todos', value: 'todos' },
  { title: 'Autorizada', value: 'AUTORIZADA' },
  { title: 'Cancelada', value: 'CANCELADA' },
  { title: 'Rejeitada', value: 'REJEITADA' },
  { title: 'Pendente', value: 'PENDENTE' },
];

const contextButtons = computed(() => {
  const list = [{ id: 'global', name: 'HOLDING', isHolding: true }];
  list.push(...companies.value.map((c: any) => ({ id: c.id, name: c.trade_name || c.name || 'Empresa', isHolding: false })));
  return list;
});

const activeCompany = computed(() => companies.value.find((c: any) => c.id === companyStore.context) || null);
const activeCnpj = computed(() => String(activeCompany.value?.cnpj || '').replace(/\D/g, ''));
const todayDateIso = computed(() => format(new Date(), 'yyyy-MM-dd'));
const filterLabel = computed(() => {
  if (timeFilter.value === 'today') return 'HOJE';
  if (timeFilter.value === 'month') return 'ESTE MÊS';
  if (timeFilter.value === 'year') return 'ESTE ANO';
  return 'PERSONALIZADO';
});

const dateRange = computed(() => {
  return { start: globalStartDate.value, end: globalEndDate.value };
});

const applyGlobalDates = async () => {
  fiscalFilters.start = globalStartDate.value;
  fiscalFilters.end = globalEndDate.value;
  receivableFilters.start = globalStartDate.value;
  receivableFilters.end = globalEndDate.value;
  payableFilters.start = globalStartDate.value;
  payableFilters.end = globalEndDate.value;

  await Promise.all([
    fetchFinancialKpisAndChart(),
    fetchFiscalDocuments()
  ]);
};

const onCustomDateChange = () => {
  timeFilter.value = null;
  applyGlobalDates();
};

const fiscalCards = computed(() => [
  { key: 'nfe_emitida', filter: 'nfe_emitida', label: 'NFe Emitidas', value: fiscalDocuments.value.filter(n => n.type === 'nfe_emitida').length, icon: 'mdi-file-send', className: 'text-info bg-blue-lighten-5' },
  { key: 'nfe_recebida', filter: 'nfe_recebida', label: 'NFe Recebidas', value: fiscalDocuments.value.filter(n => n.type === 'nfe_recebida').length, icon: 'mdi-file-download', className: 'text-purple bg-purple-lighten-5' },
  { key: 'nfce_emitida', filter: 'nfce_emitida', label: 'NFCe Emitidas', value: fiscalDocuments.value.filter(n => n.type === 'nfce_emitida').length, icon: 'mdi-receipt-text-check', className: 'text-success bg-green-lighten-5' },
  { key: 'cte', filter: 'cte', label: 'CTe', value: fiscalDocuments.value.filter(n => n.type === 'cte').length, icon: 'mdi-truck-check', className: 'text-warning bg-orange-lighten-5' },
]);

// --- APEXCHARTS COMPUTEDS ---
const chartSeries = computed(() => [
  { name: 'Receitas', data: cashflowSeries.value.map(s => s.receitas) },
  { name: 'Despesas', data: cashflowSeries.value.map(s => s.despesas) },
  { name: 'Saldo', data: cashflowSeries.value.map(s => s.saldo) }
]);

const chartOptions = computed(() => {
  const textColor = isDark.value ? '#adb5bd' : '#64748b';
  const gridColor = isDark.value ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.08)';

  return {
    chart: { type: 'area', height: 350, fontFamily: 'inherit', toolbar: { show: false }, background: 'transparent', animations: { enabled: true } },
    colors: ['#10b981', '#ef4444', '#3b82f6'],
    fill: { type: ['gradient', 'gradient', 'solid'], gradient: { shadeIntensity: 1, opacityFrom: 0.4, opacityTo: 0.05, stops: [0, 100] } },
    dataLabels: { enabled: false },
    stroke: { curve: 'smooth', width: [3, 3, 2], dashArray: [0, 0, 4] },
    xaxis: { categories: cashflowSeries.value.map(s => s.label), labels: { style: { colors: textColor } }, axisBorder: { show: false }, axisTicks: { show: false } },
    yaxis: { labels: { style: { colors: textColor }, formatter: (value: number) => new Intl.NumberFormat('pt-BR', { notation: 'compact' }).format(value) } },
    grid: { borderColor: gridColor, strokeDashArray: 4 },
    theme: { mode: isDark.value ? 'dark' : 'light' },
    legend: { position: 'top', horizontalAlign: 'right', labels: { colors: textColor } },
    tooltip: { theme: isDark.value ? 'dark' : 'light', y: { formatter: (val: number) => new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(val) } }
  };
});

// --- FILTER & PAGINATION COMPUTEDS ---
const filteredFiscalDocuments = computed(() => {
  const term = fiscalFilters.search.trim().toLowerCase();
  return fiscalDocuments.value.filter(n => {
    if (fiscalFilters.type !== 'todos' && n.type !== fiscalFilters.type) return false;
    if (fiscalFilters.status !== 'todos' && normalizeStatusBucket(n.status) !== fiscalFilters.status) return false;
    if (fiscalFilters.start && onlyDate(n.issueDate) < fiscalFilters.start) return false;
    if (fiscalFilters.end && onlyDate(n.issueDate) > fiscalFilters.end) return false;
    if (!term) return true;
    return [n.typeLabel, n.numberLabel, n.personName, n.key, n.status].some(v => String(v || '').toLowerCase().includes(term));
  });
});
const fiscalPageCount = computed(() => Math.max(1, Math.ceil(filteredFiscalDocuments.value.length / itemsPerPage)));
const paginatedFiscalDocuments = computed(() => paginate(filteredFiscalDocuments.value, fiscalPage.value));
const selectedFiscalDocs = computed(() => fiscalDocuments.value.filter(n => selectedFiscalIds.value.includes(n.uid)));
const allFiscalSelected = computed(() => paginatedFiscalDocuments.value.length > 0 && paginatedFiscalDocuments.value.every(n => selectedFiscalIds.value.includes(n.uid)));

const filteredReceivables = computed(() => filterFinanceRows(receivables.value, receivableFilters, 'receivable'));
const filteredPayables = computed(() => filterFinanceRows(payables.value, payableFilters, 'payable'));
const receivablePageCount = computed(() => Math.max(1, Math.ceil(filteredReceivables.value.length / itemsPerPage)));
const payablePageCount = computed(() => Math.max(1, Math.ceil(filteredPayables.value.length / itemsPerPage)));
const paginatedReceivables = computed(() => paginate(filteredReceivables.value, receivablePage.value));
const paginatedPayables = computed(() => paginate(filteredPayables.value, payablePage.value));

const getCompanyNameByCnpj = (cnpj: string) => {
  const clean = String(cnpj || '').replace(/\D/g, '');
  const comp = companies.value.find(c => String(c.cnpj).replace(/\D/g, '') === clean);
  return comp ? (comp.trade_name || comp.name) : 'Empresa Indefinida';
};

const updateClock = () => {
  const now = new Date();
  currentTime.value = format(now, 'HH:mm:ss');
  currentDate.value = format(now, "EEE, d MMM yyyy", { locale: ptBR });
};

const setCompanyFilter = async (id: string) => {
  companyStore.setContext(id || 'global');
  fiscalPage.value = 1; receivablePage.value = 1; payablePage.value = 1;
  await fetchAll();
};

const onPeriodChange = async (val: string | null) => {
  if (!val) return;
  const today = new Date();

  if (val === 'today') {
    globalStartDate.value = format(today, 'yyyy-MM-dd');
    globalEndDate.value = format(today, 'yyyy-MM-dd');
  } else if (val === 'month') {
    globalStartDate.value = format(startOfMonth(today), 'yyyy-MM-dd');
    globalEndDate.value = format(endOfMonth(today), 'yyyy-MM-dd');
  } else if (val === 'year') {
    globalStartDate.value = format(startOfYear(today), 'yyyy-MM-dd');
    globalEndDate.value = format(endOfYear(today), 'yyyy-MM-dd');
  }
  await applyGlobalDates();
};

const fetchCompanies = async () => {
  const { data, error } = await supabase.from('companies').select('*').order('trade_name', { ascending: true });
  if (error) throw error;
  companies.value = data || [];
};

const applyCompanyFilter = (query: any, field = 'company_id') => {
  if (!isGlobal.value && companyStore.context) return query.eq(field, companyStore.context);
  return query;
};
const applyCnpjFilter = (query: any, field = 'emitente_cnpj') => {
  if (!isGlobal.value && activeCnpj.value) return query.eq(field, activeCnpj.value);
  return query;
};

const fetchAll = async () => {
  loading.value = true;
  try {
    if (companies.value.length === 0) await fetchCompanies();
    await Promise.all([fetchFinancialKpisAndChart(), fetchFiscalDocuments(), fetchReceivables(), fetchPayables()]);
  } catch (e: any) {
    console.error('Erro no dashboard financeiro premium:', e);
    appStore.showSnackbar?.(`Erro no dashboard: ${e.message || e}`, 'error');
  } finally {
    loading.value = false;
  }
};

const fetchFinancialKpisAndChart = async () => {
  const { start, end } = dateRange.value;
  const recQuery = applyCompanyFilter(supabase.from('finance_receivables').select('id, value, discount, status, due_date, payment_date, company_id').gte('due_date', start).lte('due_date', end));
  const payQuery = applyCompanyFilter(supabase.from('finance_payables').select('id, value, discount, status, due_date, payment_date, company_id').gte('due_date', start).lte('due_date', end));
  const [{ data: recData, error: recError }, { data: payData, error: payError }] = await Promise.all([recQuery, payQuery]);
  if (recError) throw recError;
  if (payError) throw payError;

  const paidRec = (recData || []).filter(i => i.status === 'pago').reduce((acc, r) => acc + netValue(r), 0);
  const paidPay = (payData || []).filter(i => i.status === 'pago').reduce((acc, p) => acc + netValue(p), 0);
  kpis.value = { receitas: paidRec, despesas: paidPay, saldo: paidRec - paidPay };
  cashflowSeries.value = buildCashflowSeries(recData || [], payData || []);
};

const fetchFiscalDocuments = async () => {
  fiscalLoading.value = true;
  try {
    const start = fiscalFilters.start || dateRange.value.start;
    const end = fiscalFilters.end || dateRange.value.end;

    const nfeQuery = applyCnpjFilter(supabase.from('nfe_outbound').select('*').gte('created_at', `${start}T00:00:00`).lte('created_at', `${end}T23:59:59`).order('created_at', { ascending: false }).limit(500));
    const nfceQuery = applyCnpjFilter(supabase.from('nfce_outbound').select('*').gte('created_at', `${start}T00:00:00`).lte('created_at', `${end}T23:59:59`).order('created_at', { ascending: false }).limit(500));
    const dfeQuery = supabase.from('dfe_entries').select('*').gte('data_emissao', start).lte('data_emissao', end).order('data_emissao', { ascending: false }).limit(500);

    const results = await Promise.allSettled([nfeQuery, nfceQuery, dfeQuery]);
    const [nfeRes, nfceRes, dfeRes] = results.map((r: any) => r.status === 'fulfilled' ? r.value : { data: [], error: null });

    const nfe = (nfeRes.data || []).map((n: any) => normalizeFiscalDoc(n, 'nfe_emitida'));
    const nfce = (nfceRes.data || []).map((n: any) => normalizeFiscalDoc(n, 'nfce_emitida'));
    const dfe = (dfeRes.data || []).filter((n: any) => {
        if (isGlobal.value || !activeCnpj.value) return true;
        const cnpjDestinatario = String(n.cnpj_destinatario || n.destinatario_cnpj || n.destinatario?.cnpj || n.cnpj || '').replace(/\D/g, '');
        return cnpjDestinatario === activeCnpj.value;
      }).map((n: any) => normalizeFiscalDoc(n, 'nfe_recebida'));

    fiscalDocuments.value = [...nfe, ...nfce, ...dfe].sort((a, b) => new Date(b.issueDate).getTime() - new Date(a.issueDate).getTime());
  } finally {
    fiscalLoading.value = false;
  }
};

const fetchReceivables = async () => {
  receivablesLoading.value = true;
  try {
    let q = supabase.from('finance_receivables').select(`*, chart_of_accounts:finance_chart_of_accounts(name), orders!left(id, order_number, customer_name, customer_id, store_id)`);
    q = applyCompanyFilter(q);
    if (receivableFilters.start) q = q.gte('due_date', receivableFilters.start);
    if (receivableFilters.end) q = q.lte('due_date', receivableFilters.end);
    q = q.order('due_date', { ascending: true }).limit(500);
    const { data, error } = await q;
    if (error) throw error;
    const rows = data || [];
    const customerIds = Array.from(new Set(rows.map((item: any) => item.customer_id || item.orders?.customer_id).filter(Boolean)));
    const customerMap = new Map<string, any>();
    if (customerIds.length > 0) {
      for (let i = 0; i < customerIds.length; i += 300) {
        const chunk = customerIds.slice(i, i + 300);
        const { data: customers } = await supabase.from('customers_mj').select('id, nome').in('id', chunk);
        (customers || []).forEach((customer: any) => customerMap.set(customer.id, customer));
      }
    }
    receivables.value = rows.map((item: any) => ({ ...item, customer: customerMap.get(item.customer_id || item.orders?.customer_id) || null }));
  } finally { receivablesLoading.value = false; }
};

const fetchPayables = async () => {
  payablesLoading.value = true;
  try {
    let q = supabase.from('finance_payables').select('*, chart_of_accounts:finance_chart_of_accounts(name)');
    q = applyCompanyFilter(q);
    if (payableFilters.start) q = q.gte('due_date', payableFilters.start);
    if (payableFilters.end) q = q.lte('due_date', payableFilters.end);
    q = q.order('due_date', { ascending: true }).limit(500);
    const { data, error } = await q;
    if (error) throw error;
    payables.value = data || [];
  } finally { payablesLoading.value = false; }
};

const buildCashflowSeries = (recRows: any[], payRows: any[]) => {
  const { start, end } = dateRange.value;
  const startDate = parseISO(start);
  const endDate = parseISO(end);
  const map = new Map<string, any>();
  const cursor = new Date(startDate);
  const useMonthly = timeFilter.value === 'year';
  while (cursor <= endDate) {
    const key = useMonthly ? format(cursor, 'yyyy-MM') : format(cursor, 'yyyy-MM-dd');
    const label = useMonthly ? format(cursor, 'MMM', { locale: ptBR }) : format(cursor, 'dd/MM');
    if (!map.has(key)) map.set(key, { key, label, receitas: 0, despesas: 0, saldo: 0 });
    if (useMonthly) cursor.setMonth(cursor.getMonth() + 1); else cursor.setDate(cursor.getDate() + 1);
  }
  recRows.filter(r => r.status === 'pago').forEach(r => {
    const key = useMonthly ? format(safeDate(r.payment_date || r.due_date), 'yyyy-MM') : format(safeDate(r.payment_date || r.due_date), 'yyyy-MM-dd');
    if (map.has(key)) map.get(key).receitas += netValue(r);
  });
  payRows.filter(r => r.status === 'pago').forEach(r => {
    const key = useMonthly ? format(safeDate(r.payment_date || r.due_date), 'yyyy-MM') : format(safeDate(r.payment_date || r.due_date), 'yyyy-MM-dd');
    if (map.has(key)) map.get(key).despesas += netValue(r);
  });
  return Array.from(map.values()).map(p => ({ ...p, saldo: p.receitas - p.despesas }));
};

const normalizeFiscalDoc = (raw: any, type: string) => {
  const labels: Record<string, string> = { nfe_emitida: 'NFe Emitida', nfe_recebida: 'NFe Recebida', nfce_emitida: 'NFCe Emitida', cte: 'CTe' };
  const key = extractFiscalKey(raw);
  const issueDate = raw.data_emissao || raw.created_at || raw.issue_date || raw.emitted_at || new Date().toISOString();
  const personName = raw.destinatario_nome || raw.emitente_nome || raw.customer_name || raw.tomador_nome || raw.remetente_nome || raw.razao_social || 'Não identificado';
  const value = Number(raw.valor_total ?? raw.valor ?? raw.total ?? raw.vlr_total ?? 0);
  const status = raw.status || raw.status_sefaz || raw.status_processamento || raw.situacao_manifestacao || 'PENDENTE';
  const number = raw.numero || raw.nNF || raw.number || raw.id?.slice?.(0, 8) || 'S/N';
  return {
    uid: `${type}-${raw.id || key || number}-${Math.random().toString(36).slice(2, 8)}`,
    raw, type, typeLabel: labels[type], numberLabel: number, personName, key, issueDate, value, status,
    xmlLink: raw.xml_link || raw.xml_id || raw.retorno_sefaz?.id_nuvem || raw.retorno_sefaz?.id || raw.id_nuvem || key,
    cnpj: String(raw.emitente_cnpj || raw.cnpj_destinatario || raw.cnpj || activeCnpj.value || '').replace(/\D/g, ''),
  };
};

const extractFiscalKey = (raw: any) => {
  const direct = raw.chave || raw.chave_acesso || raw.access_key || raw.nfe_key || raw.cte_key || raw.retorno_sefaz?.chave || raw.retorno_sefaz?.chave_acesso || raw.retorno_sefaz?.autorizacao?.chave;
  if (direct) return String(direct).replace(/\D/g, '').slice(0, 44);
  const xml = String(raw.xml || raw.xml_content || raw.retorno_sefaz?.xml || '');
  const match = xml.match(/(?:Id=["']NFe|Id=["']CTe)(\d{44})/i) || xml.match(/<chNFe>(\d{44})<\/chNFe>/i) || xml.match(/<chCTe>(\d{44})<\/chCTe>/i);
  return match ? match[1] : '';
};

const getDownloadUrl = (note: any) => {
  const id = note.xmlLink || note.key;
  const cnpj = note.cnpj || activeCnpj.value;
  if (!id) return '';

  const isSefazKey = /^\d{44}$/.test(String(id));

  if (note.type === 'nfce_emitida') {
    return isSefazKey ? `${SEFAZ_PROXY_URL}/api/baixar-xml/${id}?cnpj=${cnpj}` : `${SEFAZ_PROXY_URL}/api/nfce/download/xml/${id}`;
  }
  if (note.type === 'cte') {
    return isSefazKey ? `${SEFAZ_PROXY_URL}/api/cte/baixar-xml/${id}?cnpj=${cnpj}` : `${SEFAZ_PROXY_URL}/api/cte/download/xml/${id}`;
  }

  if (isSefazKey) {
    return `${SEFAZ_PROXY_URL}/api/baixar-xml/${id}?cnpj=${cnpj}`;
  }
  return `${SEFAZ_PROXY_URL}/api/nfe/download/xml/${id}`;
};

const canDownloadFiscal = (note: any) => !!getDownloadUrl(note);

const downloadFiscalXml = (note: any) => {
  const url = getDownloadUrl(note);
  if (!url) return appStore.showSnackbar?.('XML indisponível para este documento.', 'warning');
  window.open(url, '_blank');
};

const downloadSelectedFiscalXml = async () => {
  const docs = selectedFiscalDocs.value;
  if (docs.length === 0) return appStore.showSnackbar?.('Selecione pelo menos um documento fiscal.', 'warning');

  bulkFiscalDownload.show = true;
  bulkFiscalDownload.loading = true;
  bulkFiscalDownload.total = docs.length;
  bulkFiscalDownload.current = 0;
  bulkFiscalDownload.status = 'Iniciando extração...';

  try {
    if (isGlobal.value) {
      // HOLDING: Agrupar documentos por Empresa e disparar múltiplos ZIPs
      const grouped = docs.reduce((acc, doc) => {
        const compName = getCompanyNameByCnpj(doc.cnpj);
        if (!acc[compName]) acc[compName] = [];
        acc[compName].push(doc);
        return acc;
      }, {} as Record<string, any[]>);

      for (const [compName, compDocs] of Object.entries(grouped)) {
        bulkFiscalDownload.status = `Empresa: ${compName}...`;
        const zip = new JSZip();

        for (const doc of compDocs) {
          try {
            const url = getDownloadUrl(doc);
            if (!url) continue;
            const response = await axios.get(url, { responseType: 'text' });
            if (response.data && typeof response.data === 'string' && response.data.includes('<?xml')) {
                const key = extractFiscalKey({ ...doc.raw, xml: response.data }) || doc.key || doc.numberLabel;
                zip.file(`${doc.typeLabel.replace(/\s/g, '_')}_${key || doc.numberLabel}.xml`, response.data);
            }
          } catch (err) {
            console.warn(`Erro ao baixar XML da nota ${doc.numberLabel}.`);
          }
          bulkFiscalDownload.current++;
        }

        if (Object.keys(zip.files).length > 0) {
            const blob = await zip.generateAsync({ type: 'blob' });
            triggerDownload(blob, `Lote_Fiscal_${compName.replace(/\s+/g, '_')}_${format(new Date(), 'dd-MM-yyyy')}.zip`);
            // Pequeno delay para o navegador do usuário não bloquear popups de múltiplos downloads
            await new Promise(resolve => setTimeout(resolve, 800));
        }
      }
    } else {
      // COMPORTAMENTO NORMAL (Apenas 1 ZIP)
      bulkFiscalDownload.status = `Baixando arquivos...`;
      const zip = new JSZip();
      for (const doc of docs) {
        try {
          const url = getDownloadUrl(doc);
          if (!url) continue;
          const response = await axios.get(url, { responseType: 'text' });
          if (response.data && typeof response.data === 'string' && response.data.includes('<?xml')) {
              const key = extractFiscalKey({ ...doc.raw, xml: response.data }) || doc.key || doc.numberLabel;
              zip.file(`${doc.typeLabel.replace(/\s/g, '_')}_${key || doc.numberLabel}.xml`, response.data);
          }
        } catch (err) {
          console.warn(`Erro ao baixar XML da nota ${doc.numberLabel}.`);
        }
        bulkFiscalDownload.current++;
      }

      if (Object.keys(zip.files).length > 0) {
          const blob = await zip.generateAsync({ type: 'blob' });
          triggerDownload(blob, `Lote_Fiscal_${format(new Date(), 'dd-MM-yyyy_HHmm')}.zip`);
      }
    }

    bulkFiscalDownload.status = 'Concluído com sucesso!';
    appStore.showSnackbar?.(`Download em lote finalizado!`, 'success');
  } finally {
    setTimeout(() => {
        bulkFiscalDownload.show = false;
        bulkFiscalDownload.loading = false;
        selectedFiscalIds.value = [];
    }, 1500);
  }
};

const exportFiscalExcel = async () => {
  exportingFiscal.value = true;
  try {
    const rows = filteredFiscalDocuments.value.map(n => ({
      Tipo: n.typeLabel,
      Empresa: getCompanyNameByCnpj(n.cnpj),
      Numero: n.numberLabel,
      Pessoa: n.personName,
      Chave: n.key,
      Data_Emissao: formatDate(n.issueDate),
      Valor: n.value,
      Status: normalizeStatus(n.status),
      CNPJ_Contexto: n.cnpj,
    }));
    const ws = XLSX.utils.json_to_sheet(rows);
    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, 'Central Fiscal');
    XLSX.writeFile(wb, `Central_Fiscal_${format(new Date(), 'dd-MM-yyyy')}.xlsx`);
  } finally { exportingFiscal.value = false; }
};

const openFiscalModule = (note: any) => {
  if (note.type === 'nfe_emitida') return router.push({ name: 'AdminNfeIssuer' });
  if (note.type === 'nfce_emitida') return router.push({ name: 'AdminNfceIssuer' });
  if (note.type === 'nfe_recebida') return router.push({ name: 'FiscalMonitor' });
  return router.push({ name: 'FiscalMonitor' });
};

const toggleAllFiscal = (checked: boolean) => {
  const pageIds = paginatedFiscalDocuments.value.map(n => n.uid);
  if (checked) selectedFiscalIds.value = Array.from(new Set([...selectedFiscalIds.value, ...pageIds]));
  else selectedFiscalIds.value = selectedFiscalIds.value.filter(id => !pageIds.includes(id));
};

const filterFinanceRows = (rows: any[], filters: any, type: 'receivable' | 'payable') => {
  const term = filters.search.trim().toLowerCase();
  return rows.filter(item => {
    if (filters.status !== 'todos') {
      const bucket = getFinanceStatusBucket(item);
      if (bucket !== filters.status) return false;
    }
    if (!term) return true;
    return [getFinanceEntity(item, type), item.description, item.order_number, item.category, item.value].some(v => String(v || '').toLowerCase().includes(term));
  });
};

const getFinanceEntity = (item: any, type: 'receivable' | 'payable') => {
  if (type === 'receivable') return item.entity_name || item.customer?.nome || item.customer?.name || item.orders?.customer_name || 'Cliente';
  return item.entity_name || item.supplier_name || item.vendor_name || item.fornecedor || 'Fornecedor';
};
const getFinanceStatusBucket = (item: any) => {
  if (item.status === 'pago') return 'pago';
  if (item.due_date && onlyDate(item.due_date) < todayDateIso.value) return 'atrasado';
  return 'em_aberto';
};
const getFinanceStatusLabel = (item: any) => getFinanceStatusBucket(item) === 'pago' ? 'Pago' : getFinanceStatusBucket(item) === 'atrasado' ? 'Atrasado' : 'Aberto';
const getFinanceStatusClass = (item: any) => getFinanceStatusBucket(item) === 'pago' ? 'chip-success' : getFinanceStatusBucket(item) === 'atrasado' ? 'chip-danger' : 'chip-warning';

const normalizeStatusBucket = (status: string) => {
  const s = String(status || '').toUpperCase();
  if (s.includes('AUTORIZ') || s.includes('CONFIRM') || s.includes('GERADO')) return 'AUTORIZADA';
  if (s.includes('CANCEL')) return 'CANCELADA';
  if (s.includes('REJEIT') || s.includes('ERRO')) return 'REJEITADA';
  return 'PENDENTE';
};
const normalizeStatus = (status: string) => {
  const bucket = normalizeStatusBucket(status);
  if (bucket === 'AUTORIZADA') return 'AUTORIZADA';
  if (bucket === 'CANCELADA') return 'CANCELADA';
  if (bucket === 'REJEITADA') return 'REJEITADA';
  return 'PENDENTE';
};
const getStatusClass = (status: string) => {
  const bucket = normalizeStatusBucket(status);
  if (bucket === 'AUTORIZADA') return 'chip-success';
  if (bucket === 'CANCELADA') return 'chip-neutral';
  if (bucket === 'REJEITADA') return 'chip-danger';
  return 'chip-warning';
};
const getFiscalTypeClass = (type: string) => type === 'nfe_emitida' ? 'chip-info' : type === 'nfe_recebida' ? 'chip-purple' : type === 'nfce_emitida' ? 'chip-success' : 'chip-warning';

const paginate = (rows: any[], page: number) => rows.slice((page - 1) * itemsPerPage, page * itemsPerPage);
const netValue = (row: any) => Number(row.value || 0) - Number(row.discount || 0);
const safeDate = (value: any) => {
  const d = typeof value === 'string' ? parseISO(value) : new Date(value);
  return isValid(d) ? d : new Date();
};
const onlyDate = (value: any) => value ? format(safeDate(value), 'yyyy-MM-dd') : '';
const formatDate = (value: any) => value ? format(safeDate(value), 'dd/MM/yyyy') : '-';
const formatCurrency = (val: number) => new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(Number(val || 0));
const formatCurrencyNoSymbol = (val: number) => new Intl.NumberFormat('pt-BR', { minimumFractionDigits: 2, maximumFractionDigits: 2 }).format(Number(val || 0));
const formatKey = (key: string) => {
  const k = String(key || '').replace(/\D/g, '');
  if (!k) return 'Sem chave';
  return k.length > 18 ? `${k.slice(0, 6)} ${k.slice(6, 18)} ${k.slice(18, 30)} ${k.slice(30, 44)}` : k;
};
const zebraClass = (index: number) => index % 2 === 0 ? 'zebra-a' : 'zebra-b';
const triggerDownload = (blob: Blob, filename: string) => {
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url; a.download = filename; document.body.appendChild(a); a.click(); document.body.removeChild(a); URL.revokeObjectURL(url);
};

watch(() => companyStore.context, () => fetchAll());
watch([() => fiscalFilters.search, () => fiscalFilters.type, () => fiscalFilters.status, () => fiscalFilters.start, () => fiscalFilters.end], () => { fiscalPage.value = 1; });

// RE-FETCH ON DATE CHANGE
watch([() => receivableFilters.start, () => receivableFilters.end], () => fetchReceivables());
watch([() => payableFilters.start, () => payableFilters.end], () => fetchPayables());

onMounted(async () => {
  updateClock();
  clockInterval = setInterval(updateClock, 1000);
  const { start, end } = dateRange.value;
  fiscalFilters.start = start; fiscalFilters.end = end;
  await fetchAll();
});

onUnmounted(() => clearInterval(clockInterval));
</script>

<style scoped lang="scss">
.finance-premium-layout { min-height: 100vh; position: relative; }

/* Backgrounds (Glassmorphism & Carousel) */
.background-carousel-wrapper { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 0; opacity: 0.6; pointer-events: none; }
.background-overlay { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 1; background: radial-gradient(circle at center, rgba(15, 15, 19, 0.4), rgba(15, 15, 19, 0.98)); backdrop-filter: blur(8px); }

.content-wrapper { z-index: 10; height: 100vh; min-height: 0; }
.dashboard-scroll { scrollbar-gutter: stable; -webkit-overflow-scrolling: touch; }

/* Dark / Light Modes Gerais */
.bg-glass-dark { background: rgba(10,10,12,0.85); }
.bg-glass-header { background: rgba(20,20,24,0.55); backdrop-filter: blur(14px); }
.border-bottom-white-05 { border-bottom: 1px solid rgba(255,255,255,0.08) !important; }
.border-white-05 { border: 1px solid rgba(255,255,255,0.1) !important; }

.min-w-0 { min-width: 0; }
.hide-scrollbar { scrollbar-width: none; } .hide-scrollbar::-webkit-scrollbar { display: none; }
.icon-box-lg { width: 54px; height: 54px; }

/* Gradientes */
.bg-gradient-purple { background: linear-gradient(135deg, #7b1fa2, #4a148c); }
.bg-gradient-red { background: linear-gradient(135deg, #c62828, #8e0000); }
.bg-gradient-green { background: linear-gradient(135deg, #2e7d32, #1b5e20); }
.bg-gradient-info { background: linear-gradient(135deg, #0288d1, #005b9f); }

/* Filtro de Datas Premium */
.custom-date-input :deep(.v-field__input) { padding-top: 0; padding-bottom: 0; min-height: 28px; }
.divider-vertical { width: 1px; height: 32px; }
.bg-white-05 { background-color: rgba(255,255,255,0.08); }

/* Botoes & Chips 3D */
.btn-3d { border-radius: 6px !important; box-shadow: 0 3px 5px rgba(0,0,0,.15), inset 0 2px 0 rgba(255,255,255,.25) !important; transition: transform .1s ease, box-shadow .1s ease; text-transform: none !important; }
.btn-3d:active { transform: translateY(2px); box-shadow: 0 1px 2px rgba(0,0,0,.15), inset 0 1px 0 rgba(255,255,255,.2) !important; }
.chip-3d { border-radius: 6px !important; box-shadow: 0 2px 4px rgba(0,0,0,0.12), inset 0 1px 0 rgba(255,255,255,0.25) !important; text-shadow: 0 1px 2px rgba(0,0,0,0.25); }

/* Elementos Comuns */
.status-dot { width: 8px; height: 8px; border-radius: 50%; display: inline-block; }
.pulse-success { animation: pulse-success-scale 2s infinite; }
@keyframes pulse-success-scale { 0% { transform: scale(1); opacity: 0.8; box-shadow: 0 0 0 0 rgba(76, 175, 80, 0.4); } 70% { transform: scale(1.1); opacity: 1; box-shadow: 0 0 0 6px rgba(76, 175, 80, 0); } 100% { transform: scale(1); opacity: 0.8; box-shadow: 0 0 0 0 rgba(76, 175, 80, 0); } }

.section-eyebrow { font-size: 11px; font-weight: 900; text-transform: uppercase; letter-spacing: 1.3px; margin-bottom: 3px; }

/* KPI Cards Refinados */
.kpi-card { color: white; position: relative; min-height: 110px; overflow: hidden; border-radius: 8px;}
.kpi-bg-icon { position: absolute; right: -20px; bottom: -20px; opacity: 0.15; transform: rotate(-15deg); }
.kpi-bg-icon .v-icon { font-size: 100px; color: white; }
.kpi-label { font-size: 12px; font-weight: 900; letter-spacing: .2px; text-transform: uppercase; }
.kpi-value { font-weight: 900; line-height: 1; letter-spacing: -1px; }

/* Painéis & Inputs */
.premium-panel { border-radius: 12px; }
.glass-card { background: rgba(255,255,255,0.03); backdrop-filter: blur(10px); }
.ui-field :deep(.v-field) { border-radius: 6px !important; }

/* Mini KPIs Fiscais */
.mini-kpi { border-radius: 8px; transition: .2s ease; overflow: hidden; position: relative; }
.mini-kpi:hover { transform: translateY(-2px); filter: brightness(1.04); }

/* Modal Background Blur */
:global(.blur-backdrop) {
  backdrop-filter: blur(12px) brightness(0.8) !important;
  -webkit-backdrop-filter: blur(12px) brightness(0.8) !important;
}

/* ---------------------------------------------------- */
/* CSS GRID FIXES  */
/* ---------------------------------------------------- */
.grid-scroll { scrollbar-gutter: stable; -webkit-overflow-scrolling: touch; }
.custom-scroll::-webkit-scrollbar { width: 8px; height: 8px; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.35); border-radius: 6px; }
.custom-scroll::-webkit-scrollbar-track { background: transparent; }

.grid-header, .grid-row { display: grid; align-items: stretch; width: 100%; }

/* Tamanhos de Colunas das Grids */
.fiscal-grid-layout {
    grid-template-columns: 48px 115px minmax(160px, 1.4fr) minmax(130px, 1.1fr) 95px 115px 105px 90px;
    min-width: 900px;
}
.fiscal-grid-layout-global {
    grid-template-columns: 48px 115px minmax(140px, 1fr) minmax(140px, 1fr) minmax(130px, 1.1fr) 95px 115px 105px 90px;
    min-width: 1050px;
}
.finance-grid-layout { grid-template-columns: minmax(150px, 1.5fr) minmax(180px, 1.5fr) 90px 120px 110px 80px; min-width: 750px; }

.cell {
  padding: 6px 12px;
  display: flex;
  align-items: center;
  border-right: 1px solid rgba(0,0,0,0.08);
  border-bottom: 1px solid rgba(0,0,0,0.08);
  min-height: 54px;
  overflow: hidden;
  min-width: 0;
  transition: background-color 0.2s ease;
}
.header-text { font-weight: 800; text-transform: uppercase; letter-spacing: 0.5px; line-height: 1.2; font-size: 11px !important; }
.center { justify-content: center; text-align: center; }
.right { justify-content: flex-end; text-align: right; }

.grid-header .cell { min-height: 44px; }
.list-text-11 { font-size: 12px !important; line-height: 1.2 !important; }
.list-text-10 { font-size: 11px !important; line-height: 1.25 !important; }

/* Dark/Light Modes da Grid */
.grid-surface-light .cell { background: #f5f7fa; color: rgba(0,0,0,0.9); border-color: rgba(0,0,0,0.12) !important; }
.grid-row-light .cell { border-color: rgba(0,0,0,0.08) !important; }
.zebra-light-a .cell { background: #ffffff; }
.zebra-light-b .cell { background: #f0f4f8; }
.grid-row-light:hover .cell { background: #e3f2fd !important; }

.grid-surface-dark .cell { background: rgba(255,255,255,0.08) !important; color: rgba(255,255,255,0.80) !important; border-color: rgba(255,255,255,0.10) !important; backdrop-filter: none !important; }
.grid-row-dark .cell { background: rgba(255,255,255,0.04); border-color: rgba(255,255,255,0.08) !important; color: rgba(255,255,255,0.85); }
.zebra-dark-a .cell { background: rgba(255,255,255,0.04) !important; }
.zebra-dark-b .cell { background: rgba(255,255,255,0.015) !important; }
.grid-row-dark:hover .cell { background: rgba(255,255,255,0.07) !important; }

.sticky-head { position: sticky; top: 0; z-index: 20; box-shadow: 0 8px 16px -4px rgba(0, 0, 0, 0.12); }
.bg-glass-dark .sticky-head { box-shadow: 0 8px 20px -4px rgba(0, 0, 0, 0.4); }

.v-theme--dark { .text-grey-darken-4, .text-grey-darken-3, .text-grey-darken-2, .text-grey-darken-1, .text-grey { color: rgba(255,255,255,0.9) !important; } }

/* Ações nas linhas */
.actions-inline { display: flex; gap: 4px; justify-content: center; flex-wrap: nowrap !important; }
.action-btn { width: 28px !important; height: 28px !important; color: #fff !important; }
.action-edit { background: #1976d2 !important; }

.solid-chip { display: inline-flex; align-items: center; justify-content: center; height: 22px; padding: 0 10px; font-weight: 900; color: #fff; text-transform: uppercase; white-space: nowrap; font-size: 10px; }
.chip-success { background: #2e7d32; }
.chip-warning { background: #f57f17; }
.chip-danger { background: #c62828; }
.chip-neutral { background: #e5e7eb; color: #374151; }
.chip-info { background: #0288d1; }
.chip-purple { background: #7b1fa2; }

:deep(.v-checkbox-btn) { width: 24px !important; height: 24px !important; }
:deep(.v-checkbox-btn .v-selection-control__input) { width: 24px !important; height: 24px !important; }
:deep(.v-checkbox-btn .v-icon) { font-size: 18px !important; }
.chk-fixed { margin: 0 !important; padding: 0 !important; }

:global(.tooltip-custom) { background-color: rgba(10,10,12,0.95) !important; color: white !important; font-weight: bold !important; font-size: 11px !important; border: 1px solid rgba(255,255,255,0.1) !important; box-shadow: 0 4px 15px rgba(0,0,0,0.3) !important; }

@media (max-width: 960px) { .header-actions { width: 100%; } .clock-box { flex: 1; } }
@media (max-width: 640px) { .kpi-card { height: 122px; } }
</style>
