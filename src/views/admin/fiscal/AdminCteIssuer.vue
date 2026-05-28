<template>
  <div
    class="fiscal-layout font-sans fill-height d-flex flex-column relative overflow-hidden"
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
            class="header-bar px-6 py-4 d-flex align-center justify-space-between flex-shrink-0"
            :class="themeStore.currentMode === 'light' ? 'bg-white border-b border-grey-lighten-2 shadow-sm' : 'bg-glass-header border-bottom-white-05'"
        >
            <div class="d-flex flex-column">
                <div class="breadcrumb text-caption">
                    <span class="opacity-70">Fiscal</span>
                    <span class="mx-2 opacity-50">></span>
                    <span class="font-weight-bold">Monitor CT-e</span>
                </div>
                <div class="text-h6 font-weight-black tracking-tight leading-none mt-1" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">
                    Conhecimento de Transporte (CT-e)
                </div>
            </div>

            <div class="d-none d-md-flex align-center overflow-x-auto pb-1 pb-md-0" style="gap: 10px;">
                <v-btn color="indigo-darken-1" variant="flat" class="btn-rect px-6 font-weight-bold text-body-2 text-uppercase letter-spacing-1 shadow-button" prepend-icon="mdi-truck-fast" height="40" @click="openEmissionModal">
                    Nova Emissão
                </v-btn>
            </div>
        </div>

        <div class="px-6 pt-4 pb-0 flex-shrink-0">
            <v-row>
                <v-col cols="12" sm="6" md="3">
                    <v-card class="kpi-card kpi-rect bg-gradient-info hover-elevate py-3 px-4" v-ripple elevation="2">
                        <div class="kpi-bg-icon"><v-icon>mdi-cloud-sync</v-icon></div>
                        <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                            <div class="d-flex align-center justify-space-between mb-2">
                                <div class="d-flex align-center" style="gap: 8px;">
                                    <v-icon size="18" class="opacity-80">mdi-cloud-sync</v-icon>
                                    <span class="kpi-label">Sincronização SEFAZ</span>
                                </div>
                                <div class="text-caption opacity-80 font-mono">{{ lastSyncTime }}</div>
                            </div>
                            <div class="d-flex flex-column">
                                <v-btn variant="outlined" color="white" size="small" class="btn-rect font-weight-bold mb-1" :loading="syncing" @click="syncCtesFromSefaz()">
                                    <v-icon start size="16">mdi-refresh</v-icon>
                                    {{ syncing ? 'Buscando...' : 'Puxar CT-es (Transportadoras)' }}
                                </v-btn>
                                <div class="text-caption text-white opacity-70">
                                    <v-icon start size="12" class="mr-1">mdi-check-circle-outline</v-icon> Serviço Disponível
                                </div>
                            </div>
                        </div>
                    </v-card>
                </v-col>

                <v-col cols="12" sm="6" md="3">
                    <v-card class="kpi-card kpi-rect bg-gradient-purple hover-elevate py-3 px-4" v-ripple elevation="2">
                        <div class="kpi-bg-icon"><v-icon>mdi-truck-check</v-icon></div>
                        <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                            <div class="d-flex align-center" style="gap: 8px;">
                                <v-icon size="18" class="opacity-80">mdi-truck-check</v-icon>
                                <span class="kpi-label">CT-es Emitidos</span>
                            </div>
                            <div class="kpi-number-group my-1">
                                <span class="kpi-value">{{ emittedCount }}</span>
                            </div>
                            <div class="kpi-footer mt-1">Próprios (Sua Empresa)</div>
                        </div>
                    </v-card>
                </v-col>

                <v-col cols="12" sm="6" md="3">
                    <v-card class="kpi-card kpi-rect bg-gradient-warning hover-elevate py-3 px-4" v-ripple elevation="2">
                        <div class="kpi-bg-icon"><v-icon>mdi-file-download</v-icon></div>
                        <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                            <div class="d-flex align-center" style="gap: 8px;">
                                <v-icon size="18" class="opacity-80">mdi-file-download</v-icon>
                                <span class="kpi-label">CT-es Recebidos</span>
                            </div>
                            <div class="kpi-number-group my-1">
                                <span class="kpi-value">{{ inboundCount }}</span>
                            </div>
                            <div class="kpi-footer mt-1">Contra o seu CNPJ</div>
                        </div>
                    </v-card>
                </v-col>

                <v-col cols="12" sm="6" md="3">
                    <v-card class="kpi-card kpi-rect bg-gradient-green hover-elevate py-3 px-4" v-ripple elevation="2">
                        <div class="kpi-bg-icon"><v-icon>mdi-cash-fast</v-icon></div>
                        <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                            <div class="d-flex align-center" style="gap: 8px;">
                                <v-icon size="18" class="opacity-80">mdi-cash-fast</v-icon>
                                <span class="kpi-label">Total Frete (Período)</span>
                            </div>
                            <div class="kpi-number-group my-1">
                                <span class="text-body-2 font-weight-medium mr-1 opacity-70">R$</span>
                                <span class="kpi-value text-h5">{{ formatCurrencyValue(totalFretePeriodo) }}</span>
                            </div>
                            <div class="kpi-footer mt-1">{{ periodLabel }}</div>
                        </div>
                    </v-card>
                </v-col>
            </v-row>
        </div>

        <div class="px-6 pt-4 pb-2 flex-shrink-0">
            <div
              class="controls-bar d-flex align-center justify-space-between flex-wrap gap-2"
              :class="themeStore.currentMode === 'light' ? 'controls-light' : 'controls-dark'"
            >
                <div class="d-flex align-center flex-wrap" style="gap: 10px;">
                    <v-menu location="bottom start" :close-on-content-click="false">
                        <template v-slot:activator="{ props }">
                            <v-btn v-bind="props" variant="outlined" class="btn-rect font-weight-bold" height="40" color="primary" prepend-icon="mdi-calendar-range">
                                {{ periodLabel }} <v-icon end size="small">mdi-chevron-down</v-icon>
                            </v-btn>
                        </template>
                        <v-card min-width="280" class="rounded-0 pa-2">
                            <v-list density="compact" nav>
                                <v-list-item @click="setPeriod('month')" :active="currentPeriod === 'month'"><v-list-item-title>Este Mês</v-list-item-title></v-list-item>
                                <v-list-item @click="setPeriod('week')" :active="currentPeriod === 'week'"><v-list-item-title>Esta Semana</v-list-item-title></v-list-item>
                                <v-list-item @click="setPeriod('today')" :active="currentPeriod === 'today'"><v-list-item-title>Hoje</v-list-item-title></v-list-item>
                                <v-list-item @click="setPeriod('year')" :active="currentPeriod === 'year'"><v-list-item-title>Este Ano</v-list-item-title></v-list-item>
                                <v-list-item @click="currentPeriod = 'all'" :active="currentPeriod === 'all'"><v-list-item-title>Todos</v-list-item-title></v-list-item>
                            </v-list>
                        </v-card>
                    </v-menu>

                    <div class="d-flex rounded p-1" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-3' : 'bg-white-10'" style="padding: 4px;">
                        <v-btn variant="flat" class="btn-rect" height="32" :color="currentTab === 'active' ? (themeStore.currentMode === 'light' ? 'white' : 'grey-darken-3') : 'transparent'" @click="currentTab = 'active'" :class="{'text-grey-darken-3': currentTab === 'active' && themeStore.currentMode === 'light', 'text-grey-darken-1': currentTab !== 'active'}">
                            <v-icon start size="16" class="mr-1">mdi-truck-check</v-icon> Ativos
                        </v-btn>
                        <v-btn variant="flat" class="btn-rect" height="32" :color="currentTab === 'archived' ? (themeStore.currentMode === 'light' ? 'white' : 'grey-darken-3') : 'transparent'" @click="currentTab = 'archived'" :class="{'text-purple': currentTab === 'archived', 'text-grey-darken-1': currentTab !== 'archived'}">
                            <v-icon start size="16" class="mr-1">mdi-archive</v-icon> Arquivados
                        </v-btn>
                    </div>

                    <div style="width: 180px;">
                        <v-select v-model="statusFilter" :items="statusOptions" item-title="label" item-value="value" variant="outlined" density="compact" hide-details class="clean-input btn-rect" bg-color="transparent" placeholder="Status">
                             <template v-slot:prepend-inner><v-icon size="small" color="grey">mdi-filter-variant</v-icon></template>
                        </v-select>
                    </div>

                    <div class="search-wrap d-flex align-center" :class="themeStore.currentMode === 'light' ? 'search-light' : 'search-dark'">
                        <v-icon :color="themeStore.currentMode === 'light' ? 'grey-darken-1' : 'white-70'">mdi-magnify</v-icon>
                        <input v-model="search" type="text" placeholder="Buscar CT-e, Chave ou Transportadora..." class="clean-input flex-grow-1" />
                    </div>
                </div>

                <div class="d-flex align-center flex-wrap" style="gap: 10px;">
                    <v-menu location="bottom end" transition="slide-y-transition" :close-on-content-click="true">
                        <template v-slot:activator="{ props }">
                            <v-btn v-bind="props" variant="outlined" class="btn-rect text-none font-weight-bold" height="40" :color="themeStore.currentMode === 'light' ? 'grey-darken-2' : 'white'" prepend-icon="mdi-domain">
                                {{ activeCompany ? activeCompany.name.substring(0, 20) : 'Todas as Lojas' }} <v-icon end size="small">mdi-chevron-down</v-icon>
                            </v-btn>
                        </template>
                        <v-card min-width="300" class="rounded-0 shadow-lg mt-1">
                            <v-list density="compact" nav>
                                <v-list-item @click="switchCompany(null)" :active="activeCompany === null" color="primary">
                                    <template v-slot:prepend><v-icon size="10" class="mr-2">mdi-apps</v-icon></template>
                                    <v-list-item-title class="font-weight-bold">Todas as Lojas</v-list-item-title>
                                </v-list-item>
                                <v-divider class="my-1"></v-divider>
                                <v-list-item v-for="company in companies" :key="company.id" @click="switchCompany(company)" :active="activeCompany?.id === company.id" color="primary">
                                    <template v-slot:prepend><v-icon :color="company.status === 'active' ? 'success' : 'grey'" size="10" class="mr-2">mdi-circle</v-icon></template>
                                    <v-list-item-title class="font-weight-bold">{{ company.name }}</v-list-item-title>
                                    <v-list-item-subtitle class="text-caption font-mono">{{ company.cnpj }}</v-list-item-subtitle>
                                </v-list-item>
                            </v-list>
                        </v-card>
                    </v-menu>

                    <v-menu location="bottom end">
                        <template v-slot:activator="{ props }">
                            <v-btn v-bind="props" variant="flat" color="primary" class="btn-rect font-weight-bold" height="40">
                                Opções <v-icon end size="small">mdi-chevron-down</v-icon>
                            </v-btn>
                        </template>
                        <v-list density="compact" elevation="4" class="py-1" min-width="220">
                            <v-list-item @click="syncCtesFromSefaz()" class="hover:bg-grey-lighten-4">
                                <template v-slot:prepend><v-icon size="18" class="mr-2 text-primary">mdi-cloud-download</v-icon></template>
                                <v-list-item-title class="font-weight-medium">Forçar Sincronização</v-list-item-title>
                            </v-list-item>
                            <v-list-item @click="triggerXmlInput" class="hover:bg-grey-lighten-4">
                                <template v-slot:prepend><v-icon size="18" class="mr-2 text-indigo">mdi-upload</v-icon></template>
                                <v-list-item-title class="font-weight-medium">Importar XML Local</v-list-item-title>
                            </v-list-item>
                        </v-list>
                    </v-menu>
                    <input type="file" ref="xmlInput" class="d-none" accept=".xml" multiple @change="handleXmlUpload">
                </div>
            </div>
        </div>

        <div class="flex-grow-1 px-6 pb-2 overflow-hidden d-flex flex-column">
            <v-card class="flex-grow-1 d-flex flex-column rounded-0 border-thin overflow-hidden" :class="themeStore.currentMode === 'light' ? 'bg-white shadow-sm' : 'glass-card border-white-05'" :elevation="0">
                <div class="grid-scroll flex-grow-1 overflow-y-auto custom-scroll">
                    <div class="grid-header sticky-head" :class="[themeStore.currentMode === 'light' ? 'grid-surface-light' : 'grid-surface-dark', 'grid-fiscal-layout']">
                        <div class="cell center">
                            <v-checkbox-btn :model-value="areAllSelected" :indeterminate="selectedNotes.length > 0 && !areAllSelected" density="compact" color="primary" @update:model-value="toggleSelectAll"></v-checkbox-btn>
                        </div>
                        <div class="cell center header-text">Tipo</div>
                        <div class="cell header-text">Transportador / Emissor</div>
                        <div class="cell header-text">Tomador (Pagador)</div>
                        <div class="cell header-text">Chave de Acesso</div>
                        <div class="cell center header-text">Emissão</div>
                        <div class="cell right header-text">V. Frete</div>
                        <div class="cell center header-text">Status</div>
                        <div class="cell center header-text">Ações</div>
                    </div>

                    <div v-if="loadingGrid" class="d-flex flex-column justify-center align-center h-100 py-10">
                        <v-progress-circular indeterminate color="primary" size="32" width="3"></v-progress-circular>
                    </div>

                    <div v-else-if="paginatedCtes.length === 0" class="d-flex flex-column justify-center align-center h-100 opacity-60 gap-2 py-10">
                        <v-icon size="48" color="grey-lighten-1">{{ currentTab === 'archived' ? 'mdi-archive-outline' : 'mdi-truck-alert-outline' }}</v-icon>
                        <span class="text-body-2 font-weight-medium text-grey">Nenhum CT-e encontrado para os filtros selecionados.</span>
                    </div>

                    <template v-else>
                        <div v-for="(item, index) in paginatedCtes" :key="item.chave" class="grid-row zebra-row" :class="[themeStore.currentMode === 'light' ? 'grid-row-light' : 'grid-row-dark', 'grid-fiscal-layout', {'opacity-60': currentTab === 'archived'}]">
                            <div class="cell center">
                                <v-checkbox-btn v-model="selectedNotes" :value="item.chave" density="compact" color="primary"></v-checkbox-btn>
                            </div>

                            <div class="cell center">
                                <v-tooltip :text="item.source === 'emitted' ? 'CT-e Emitido por nós' : 'CT-e Recebido (Transportadora)'" location="top" content-class="tooltip-custom">
                                    <template v-slot:activator="{ props }">
                                        <v-icon v-bind="props" :color="item.source === 'emitted' ? 'indigo' : 'warning'" size="20">
                                            {{ item.source === 'emitted' ? 'mdi-truck-fast' : 'mdi-download-box' }}
                                        </v-icon>
                                    </template>
                                </v-tooltip>
                            </div>

                            <div class="cell">
                                <div class="text-truncate list-text-10 font-weight-bold" :title="item.emitente_nome">{{ item.emitente_nome || 'N/A' }}</div>
                            </div>

                            <div class="cell">
                                <span class="list-text-10 text-grey-darken-1 font-weight-medium text-truncate w-100">{{ item.tomador_nome || 'Sua Empresa' }}</span>
                            </div>

                            <div class="cell d-flex align-center justify-space-between">
                                <span class="text-truncate list-text-10 opacity-70 font-mono select-all flex-grow-1" :title="item.chave">{{ item.chave }}</span>
                                <v-btn icon variant="text" size="x-small" color="grey" class="ml-2 flex-shrink-0" @click.stop="copyToClipboard(item.chave)">
                                    <v-icon size="14">mdi-content-copy</v-icon>
                                </v-btn>
                            </div>

                            <div class="cell center"><span class="list-text-10 font-mono">{{ formatDateSafe(item.data_emissao) }}</span></div>

                            <div class="cell right"><span class="list-text-10 font-mono font-weight-black text-indigo-darken-3">{{ formatCurrency(item.valor_frete) }}</span></div>

                            <div class="cell center">
                                <span class="solid-chip" :class="getStatusClass(item.status_sefaz)">{{ getStatusLabel(item.status_sefaz) }}</span>
                            </div>

                            <div class="cell center">
                                <div class="actions-inline">
                                    <v-tooltip text="Visualizar DACTE" location="top" content-class="tooltip-custom">
                                        <template v-slot:activator="{ props }">
                                            <v-btn v-bind="props" icon size="small" class="action-btn action-edit" @click.stop="downloadDocument('pdf', item)">
                                                <v-icon size="16">mdi-eye</v-icon>
                                            </v-btn>
                                        </template>
                                    </v-tooltip>

                                    <v-tooltip text="Baixar XML" location="top" content-class="tooltip-custom">
                                        <template v-slot:activator="{ props }">
                                            <v-btn v-bind="props" icon size="small" class="action-btn bg-blue-grey-darken-2 text-white" @click.stop="downloadDocument('xml', item)">
                                                <v-icon size="16">mdi-xml</v-icon>
                                            </v-btn>
                                        </template>
                                    </v-tooltip>

                                    <v-menu location="bottom end">
                                        <template v-slot:activator="{ props }">
                                            <v-btn v-bind="props" icon size="small" class="action-btn bg-success text-white" title="Ações Avançadas">
                                                <v-icon size="18">mdi-chevron-down</v-icon>
                                            </v-btn>
                                        </template>
                                        <v-list density="compact" elevation="4" class="py-1">
                                            <v-list-item @click="syncStatus(item)" class="hover:bg-grey-lighten-4">
                                                <template v-slot:prepend><v-icon size="18" class="mr-2 text-info">mdi-refresh</v-icon></template>
                                                <v-list-item-title>Atualizar Sefaz</v-list-item-title>
                                            </v-list-item>

                                            <v-list-item v-if="item.source === 'inbound'" @click="openDesacordoModal(item)" class="text-error hover:bg-red-lighten-5">
                                                <template v-slot:prepend><v-icon size="18" class="mr-2" color="error">mdi-close-octagon-outline</v-icon></template>
                                                <v-list-item-title>Informar Desacordo</v-list-item-title>
                                            </v-list-item>

                                            <v-list-item v-if="item.source === 'emitted'" @click="openCCeModal(item)" class="hover:bg-grey-lighten-4" :disabled="item.status_sefaz !== 'autorizado'">
                                                <template v-slot:prepend><v-icon size="18" class="mr-2 text-primary">mdi-file-document-edit</v-icon></template>
                                                <v-list-item-title>Carta de Correção</v-list-item-title>
                                            </v-list-item>

                                            <v-divider class="my-1"></v-divider>

                                            <v-list-item @click="archiveCte(item)" v-if="currentTab === 'active'" class="hover:bg-grey-lighten-4">
                                                <template v-slot:prepend><v-icon size="18" class="mr-2">mdi-archive</v-icon></template>
                                                <v-list-item-title>Arquivar Localmente</v-list-item-title>
                                            </v-list-item>
                                            <v-list-item @click="unarchiveCte(item)" v-else class="hover:bg-grey-lighten-4">
                                                <template v-slot:prepend><v-icon size="18" class="mr-2">mdi-archive-refresh</v-icon></template>
                                                <v-list-item-title>Desarquivar</v-list-item-title>
                                            </v-list-item>

                                            <v-list-item v-if="item.source === 'emitted'" @click="openCancelModal(item)" class="text-error hover:bg-red-lighten-5" :disabled="item.status_sefaz !== 'autorizado'">
                                                <template v-slot:prepend><v-icon size="18" class="mr-2" color="error">mdi-cancel</v-icon></template>
                                                <v-list-item-title>Cancelar CT-e</v-list-item-title>
                                            </v-list-item>
                                        </v-list>
                                    </v-menu>
                                </div>
                            </div>
                        </div>
                    </template>
                </div>
            </v-card>

            <v-slide-y-reverse-transition>
               <div v-if="selectedNotes.length > 0" class="absolute-bottom-center pa-4 z-50 w-100 d-flex justify-center">
                   <v-card elevation="8" class="rounded-0 bg-grey-darken-4 text-white pl-6 pr-2 py-2 d-flex align-center gap-4 border border-grey-darken-3" style="border-radius: 50px !important;">
                       <span class="font-weight-bold text-caption">{{ selectedNotes.length }} itens selecionados</span>
                       <v-divider vertical class="bg-white opacity-20 my-1"></v-divider>
                       <v-btn color="warning" variant="flat" class="text-none font-weight-bold rounded-pill" @click="archiveSelected" height="32">
                           <v-icon start size="16">mdi-archive</v-icon> Arquivar Selecionados
                       </v-btn>
                       <v-btn icon="mdi-close" size="small" variant="text" color="grey" @click="selectedNotes = []"></v-btn>
                   </v-card>
               </div>
           </v-slide-y-reverse-transition>

            <div class="flex-shrink-0 border-t px-4 py-2 d-flex align-center justify-space-between bg-white" v-if="pageCount > 1">
                <div class="text-caption text-grey">Página {{ page }} de {{ pageCount }}</div>
                <v-pagination v-model="page" :length="pageCount" :total-visible="5" density="compact" active-color="primary" variant="tonal" size="small"></v-pagination>
            </div>
        </div>
    </div>

    <v-dialog v-model="emissionModal.show" fullscreen transition="dialog-bottom-transition" class="fixed-dialog">
        <v-card class="d-flex flex-column rounded-0 font-sans h-100 overflow-hidden receivables-layout" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 text-grey-darken-4' : 'bg-glass-dark text-white'">
            <div v-if="themeStore.currentMode !== 'light'" class="background-carousel-wrapper">
                <v-carousel cycle height="100%" hide-delimiters :show-arrows="false" interval="15000" class="fill-height">
                    <v-carousel-item src="@/assets/1.jpg" cover></v-carousel-item>
                    <v-carousel-item src="@/assets/2.jpg" cover></v-carousel-item>
                </v-carousel>
                <div class="background-overlay"></div>
            </div>

            <div class="px-4 py-3 px-md-6 py-md-4 d-flex justify-space-between align-center flex-shrink-0 z-20" :class="themeStore.currentMode === 'light' ? 'bg-white border-b border-grey-lighten-2 shadow-sm' : 'bg-glass-header border-bottom-white-05'">
                <div class="d-flex align-center gap-4">
                    <v-btn icon variant="text" :color="themeStore.currentMode === 'light' ? 'grey-darken-4' : 'white'" @click="emissionModal.show = false" class="btn-3d"><v-icon>mdi-arrow-left</v-icon></v-btn>
                    <div>
                        <div class="text-caption font-weight-bold text-uppercase tracking-wide" :class="themeStore.currentMode === 'light' ? 'text-indigo-darken-2' : 'text-indigo-lighten-2'">Emissor de Conhecimento de Transporte</div>
                        <div class="text-h6 font-weight-black lh-1" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">Nova CT-e (Modal Rodoviário)</div>
                    </div>
                </div>
                <div class="d-flex align-center gap-3">
                    <v-btn variant="outlined" :color="themeStore.currentMode === 'light' ? 'grey-darken-2' : 'white'" class="btn-3d font-weight-bold text-none" @click="emissionModal.show = false">
                        Cancelar
                    </v-btn>
                    <v-btn color="indigo-darken-1" variant="flat" class="btn-3d px-8 font-weight-black text-none" @click="submitCte" :loading="emissionModal.loading">
                        <v-icon start>mdi-send-check</v-icon> Transmitir à Sefaz
                    </v-btn>
                </div>
            </div>

            <div class="flex-grow-1 overflow-y-auto custom-scroll pa-4 pa-md-6 w-100 z-10 relative">
                <v-form ref="cteForm" class="d-flex flex-column w-100" style="gap: 20px; max-width: 1200px; margin: 0 auto;">

                  <v-card class="rounded-lg border-thin overflow-hidden shadow-sm w-100" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'glass-card border-white-05'" elevation="0">
                    <div class="px-6 py-3 border-b d-flex justify-space-between align-center" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-white-05 border-bottom-white-05'">
                        <div class="font-weight-black text-subtitle-2 text-uppercase d-flex align-center gap-2" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-3' : 'text-white'">
                            <v-icon size="18" :color="themeStore.currentMode === 'light' ? 'indigo' : 'indigo-lighten-2'">mdi-domain</v-icon> 0. Empresa Emissora (Sua Transportadora)
                        </div>
                        <div style="width: 350px;">
                            <v-select
                                v-model="emissionCompany"
                                :items="companies"
                                item-title="name"
                                return-object
                                variant="outlined"
                                density="compact"
                                hide-details
                                :color="themeStore.currentMode === 'light' ? 'indigo' : 'white'"
                                class="ui-field font-weight-bold"
                                @update:model-value="(val) => {
                                    if(val) {
                                        form.uf_inicio = val.uf || val.estado || 'SP';
                                        form.municipio_inicio_nome = val.city || val.cidade || val.municipio || '';
                                        if (val.rntrc) form.rntrc = val.rntrc;
                                    }
                                }"
                            ></v-select>
                        </div>
                    </div>
                    <div class="pa-6 w-100" v-if="emissionCompany">
                        <v-row dense class="row-gap w-100 ma-0">
                            <v-col cols="12" md="3"><label class="input-label">CNPJ *</label><v-text-field :model-value="emissionCompany.cnpj" variant="outlined" density="compact" class="ui-field font-weight-bold text-indigo" readonly></v-text-field></v-col>
                            <v-col cols="12" md="6"><label class="input-label">Razão Social *</label><v-text-field :model-value="emissionCompany.name" variant="outlined" density="compact" class="ui-field" readonly></v-text-field></v-col>
                            <v-col cols="12" md="3"><label class="input-label">Inscrição Estadual</label><v-text-field :model-value="emissionCompany.ie || emissionCompany.state_registration" variant="outlined" density="compact" class="ui-field" readonly></v-text-field></v-col>
                        </v-row>
                    </div>
                </v-card>

                    <v-card class="rounded-lg border-thin overflow-hidden shadow-sm w-100" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'glass-card border-white-05'" elevation="0">
                        <div class="px-6 py-3 border-b d-flex justify-space-between align-center" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-white-05 border-bottom-white-05'">
                            <div class="font-weight-black text-subtitle-2 text-uppercase d-flex align-center gap-2" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-3' : 'text-white'">
                                <v-icon size="18" :color="themeStore.currentMode === 'light' ? 'indigo' : 'indigo-lighten-2'">mdi-map-marker-path</v-icon> 1. Dados da Operação e Frete
                            </div>
                            <div style="width: 250px;">
                                <v-select v-model="form.ambiente" :items="['homologacao', 'producao']" label="Ambiente" variant="outlined" density="compact" hide-details class="ui-field font-weight-bold text-caption" :color="themeStore.currentMode === 'light' ? 'indigo' : 'white'"></v-select>
                            </div>
                        </div>
                        <div class="pa-6 w-100">
                            <v-row dense class="row-gap w-100 ma-0">
                                <v-col cols="12" md="4">
                                    <label class="input-label d-flex align-center gap-1">CFOP * <v-tooltip text="Código Fiscal da Operação. Define o tipo de tributação e a direção do transporte." location="top"><template v-slot:activator="{ props }"><v-icon v-bind="props" size="14" color="info">mdi-information</v-icon></template></v-tooltip>
                                    </label>
                                    <v-select v-model="form.cfop" :items="cfopOptions" item-title="title" item-value="value" variant="outlined" density="compact" class="ui-field font-weight-bold" :color="themeStore.currentMode === 'light' ? 'indigo' : 'white'"></v-select>
                                </v-col>
                                <v-col cols="12" md="8">
                                    <label class="input-label">Natureza da Operação *</label>
                                    <v-text-field v-model="form.natureza_operacao" variant="outlined" density="compact" class="ui-field" placeholder="Ex: PRESTACAO DE SERVICO DE TRANSPORTE"></v-text-field>
                                </v-col>

                                <v-col cols="12"><v-divider class="my-2 border-dashed"></v-divider></v-col>

                                <v-col cols="12" md="3"><label class="input-label">UF Origem *</label><v-select v-model="form.uf_inicio" :items="estados" variant="outlined" density="compact" class="ui-field font-weight-bold"></v-select></v-col>
                                <v-col cols="12" md="3"><label class="input-label">Município Origem *</label><v-text-field v-model="form.municipio_inicio_nome" variant="outlined" density="compact" class="ui-field"></v-text-field></v-col>
                                <v-col cols="12" md="3"><label class="input-label">UF Destino *</label><v-select v-model="form.uf_fim" :items="estados" variant="outlined" density="compact" class="ui-field font-weight-bold"></v-select></v-col>
                                <v-col cols="12" md="3"><label class="input-label">Município Destino *</label><v-text-field v-model="form.municipio_fim_nome" variant="outlined" density="compact" class="ui-field"></v-text-field></v-col>

                                <v-col cols="12"><v-divider class="my-2 border-dashed"></v-divider></v-col>

                                <v-col cols="12" md="4">
                                    <label class="input-label text-indigo d-flex align-center gap-1">Valor Total do Frete (R$) *
                                        <v-tooltip text="Este é o valor que a sua empresa cobrará pelo transporte da carga." location="top"><template v-slot:activator="{ props }"><v-icon v-bind="props" size="14" color="info">mdi-help-circle</v-icon></template></v-tooltip>
                                    </label>
                                    <v-text-field v-model.number="form.valor_frete" type="number" step="0.01" variant="outlined" density="compact" class="ui-field font-weight-black text-indigo-darken-3 text-h6"></v-text-field>
                                </v-col>
                                <v-col cols="12" md="8">
                                    <label class="input-label text-error d-flex align-center gap-1">Tomador do Serviço (Quem Paga o Frete) *
                                        <v-tooltip text="O tomador é quem receberá a cobrança/fatura. Errar este campo gera nota fiscal contra o CNPJ incorreto." location="top"><template v-slot:activator="{ props }"><v-icon v-bind="props" size="14" color="error">mdi-alert</v-icon></template></v-tooltip>
                                    </label>
                                    <v-select v-model="form.tomador_role" :items="tomadorOptions" item-title="title" item-value="value" variant="outlined" density="compact" class="ui-field font-weight-bold"></v-select>
                                    <div class="text-caption text-error mt-n3 mb-2 font-weight-medium" v-if="form.tomador_role === 4">Se for 'Outros', configure a TAG de recebedor no XML (Consultar suporte).</div>
                                </v-col>
                            </v-row>
                        </div>
                    </v-card>

                    <div class="d-flex flex-column flex-md-row w-100" style="gap: 20px;">

                        <v-card class="rounded-lg border-thin overflow-hidden shadow-sm w-100" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'glass-card border-white-05'" elevation="0">
                            <div class="px-6 py-3 border-b d-flex justify-space-between align-center bg-indigo-lighten-5">
                                <div class="font-weight-black text-subtitle-2 text-uppercase d-flex align-center gap-2 text-indigo-darken-4">
                                    <v-icon size="18" color="indigo-darken-2">mdi-account-arrow-right</v-icon> 2.1 Remetente (Quem envia)
                                </div>
                            </div>
                            <div class="pa-6">
                                <p class="text-caption text-grey-darken-1 mb-4">Geralmente é o vendedor da mercadoria (A origem da NF-e).</p>
                                <v-row dense class="row-gap ma-0">
                                    <v-col cols="12"><label class="input-label">CNPJ/CPF *</label><v-text-field v-model="form.remetente.cnpj_cpf" variant="outlined" density="compact" class="ui-field font-weight-bold"></v-text-field></v-col>
                                    <v-col cols="12"><label class="input-label">Razão Social / Nome *</label><v-text-field v-model="form.remetente.nome" variant="outlined" density="compact" class="ui-field"></v-text-field></v-col>
                                    <v-col cols="12" md="6"><label class="input-label">Inscrição Estadual (IE)</label><v-text-field v-model="form.remetente.ie" variant="outlined" density="compact" class="ui-field"></v-text-field></v-col>
                                    <v-col cols="12" md="6"><label class="input-label">CEP</label><v-text-field v-model="form.remetente.endereco.cep" variant="outlined" density="compact" class="ui-field"></v-text-field></v-col>
                                    <v-col cols="12" md="9"><label class="input-label">Logradouro *</label><v-text-field v-model="form.remetente.endereco.logradouro" variant="outlined" density="compact" class="ui-field"></v-text-field></v-col>
                                    <v-col cols="12" md="3"><label class="input-label">Nº *</label><v-text-field v-model="form.remetente.endereco.numero" variant="outlined" density="compact" class="ui-field"></v-text-field></v-col>
                                </v-row>
                            </div>
                        </v-card>

                        <v-card class="rounded-lg border-thin overflow-hidden shadow-sm w-100" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'glass-card border-white-05'" elevation="0">
                            <div class="px-6 py-3 border-b d-flex justify-space-between align-center bg-teal-lighten-5">
                                <div class="font-weight-black text-subtitle-2 text-uppercase d-flex align-center gap-2 text-teal-darken-4">
                                    <v-icon size="18" color="teal-darken-2">mdi-account-arrow-left</v-icon> 2.2 Destinatário (Quem recebe)
                                </div>
                            </div>
                            <div class="pa-6">
                                <p class="text-caption text-grey-darken-1 mb-4">Geralmente é o comprador da mercadoria (O destino final).</p>
                                <v-row dense class="row-gap ma-0">
                                    <v-col cols="12"><label class="input-label">CNPJ/CPF *</label><v-text-field v-model="form.destinatario.cnpj_cpf" variant="outlined" density="compact" class="ui-field font-weight-bold"></v-text-field></v-col>
                                    <v-col cols="12"><label class="input-label">Razão Social / Nome *</label><v-text-field v-model="form.destinatario.nome" variant="outlined" density="compact" class="ui-field"></v-text-field></v-col>
                                    <v-col cols="12" md="6"><label class="input-label">Inscrição Estadual (IE)</label><v-text-field v-model="form.destinatario.ie" variant="outlined" density="compact" class="ui-field"></v-text-field></v-col>
                                    <v-col cols="12" md="6"><label class="input-label">CEP</label><v-text-field v-model="form.destinatario.endereco.cep" variant="outlined" density="compact" class="ui-field"></v-text-field></v-col>
                                    <v-col cols="12" md="9"><label class="input-label">Logradouro *</label><v-text-field v-model="form.destinatario.endereco.logradouro" variant="outlined" density="compact" class="ui-field"></v-text-field></v-col>
                                    <v-col cols="12" md="3"><label class="input-label">Nº *</label><v-text-field v-model="form.destinatario.endereco.numero" variant="outlined" density="compact" class="ui-field"></v-text-field></v-col>
                                </v-row>
                            </div>
                        </v-card>

                    </div>

                    <v-card class="rounded-lg border-thin overflow-hidden shadow-sm w-100" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'glass-card border-white-05'" elevation="0">
                        <div class="px-6 py-3 border-b d-flex justify-space-between align-center" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-white-05 border-bottom-white-05'">
                            <div class="font-weight-black text-subtitle-2 text-uppercase d-flex align-center gap-2" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-3' : 'text-white'">
                                <v-icon size="18" :color="themeStore.currentMode === 'light' ? 'indigo' : 'white'">mdi-package-variant-closed</v-icon> 3. Carga e Notas Fiscais (NF-e)
                            </div>
                        </div>
                        <div class="pa-6 w-100">
                            <v-row dense class="row-gap w-100 ma-0 mb-6">
                                <v-col cols="12" md="3">
                                    <label class="input-label d-flex align-center gap-1">Valor Mercadoria (R$) *
                                        <v-tooltip text="A soma exata do valor das NF-es que estão sendo transportadas." location="top"><template v-slot:activator="{ props }"><v-icon v-bind="props" size="14" color="info">mdi-information</v-icon></template></v-tooltip>
                                    </label>
                                    <v-text-field v-model.number="form.valor_mercadoria" type="number" step="0.01" variant="outlined" density="compact" class="ui-field font-weight-bold text-success-darken-2"></v-text-field>
                                </v-col>
                                <v-col cols="12" md="3"><label class="input-label">Produto Predominante *</label><v-text-field v-model="form.produto_predominante" variant="outlined" density="compact" class="ui-field" placeholder="Ex: Roupas / Pecas"></v-text-field></v-col>
                                <v-col cols="12" md="3">
                                    <label class="input-label text-error d-flex align-center gap-1">Peso Bruto (KG) *
                                        <v-tooltip text="Importante para passar em balanças da Polícia Rodoviária. Omitir ou errar causa multa." location="top"><template v-slot:activator="{ props }"><v-icon v-bind="props" size="14" color="error">mdi-alert</v-icon></template></v-tooltip>
                                    </label>
                                    <v-text-field v-model.number="form.peso_bruto" type="number" step="0.001" variant="outlined" density="compact" class="ui-field font-weight-bold"></v-text-field>
                                </v-col>
                                <v-col cols="12" md="3"><label class="input-label">Volumes (Qtd) *</label><v-text-field v-model.number="form.qtd_volumes" type="number" variant="outlined" density="compact" class="ui-field font-weight-bold"></v-text-field></v-col>
                            </v-row>

                            <div class="border rounded-lg pa-5 bg-indigo-lighten-5 border-indigo-lighten-4">
                                <div class="text-subtitle-2 font-weight-black text-uppercase text-indigo-darken-4 mb-1">Vincular Notas Fiscais Eletrônicas (NF-e) *</div>
                                <p class="text-caption text-indigo-darken-2 mb-4">Todo CT-e deve referenciar obrigatoriamente as chaves de 44 dígitos das NF-es correspondentes à carga.</p>

                                <div class="d-flex gap-3 mb-4">
                                    <v-text-field v-model="tempNfeKey" label="Cole aqui a Chave de Acesso (44 dígitos numéricos)" variant="outlined" density="compact" bg-color="white" hide-details maxlength="44" @keyup.enter="addNfeKey"></v-text-field>
                                    <v-btn color="indigo-darken-2" variant="flat" height="40" class="btn-3d font-weight-bold text-none px-6" @click="addNfeKey"><v-icon start>mdi-plus</v-icon> Adicionar Chave</v-btn>
                                </div>

                                <div class="border-thin rounded overflow-hidden bg-white shadow-sm">
                                    <div v-if="form.chaves_nfe.length === 0" class="pa-4 text-center text-caption text-error font-weight-bold">
                                        <v-icon start color="error">mdi-alert-circle</v-icon> Nenhuma chave NF-e vinculada. É obrigatório vincular pelo menos uma.
                                    </div>
                                    <v-list density="compact" class="bg-transparent" v-else>
                                        <v-list-item v-for="(chave, idx) in form.chaves_nfe" :key="idx" class="border-b px-4 py-1">
                                            <template v-slot:prepend><v-icon size="small" color="success" class="mr-3">mdi-check-circle</v-icon></template>
                                            <v-list-item-title class="font-mono text-body-2 font-weight-bold">{{ chave }}</v-list-item-title>
                                            <template v-slot:append>
                                                <v-btn icon="mdi-delete" size="small" color="error" variant="text" @click="form.chaves_nfe.splice(idx, 1)"></v-btn>
                                            </template>
                                        </v-list-item>
                                    </v-list>
                                </div>
                            </div>
                        </div>
                    </v-card>

                    <v-card class="rounded-lg border-thin overflow-hidden shadow-sm w-100 mb-8" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'glass-card border-white-05'" elevation="0">
                        <div class="px-6 py-3 border-b d-flex justify-space-between align-center" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-white-05 border-bottom-white-05'">
                            <div class="font-weight-black text-subtitle-2 text-uppercase d-flex align-center gap-2" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-3' : 'text-white'">
                                <v-icon size="18" :color="themeStore.currentMode === 'light' ? 'indigo' : 'white'">mdi-truck</v-icon> 4. Transporte Rodoviário (Veículo)
                            </div>
                        </div>
                        <div class="pa-6 w-100">
                            <v-row dense class="row-gap w-100 ma-0">
                                <v-col cols="12" md="6">
                                    <label class="input-label text-error d-flex align-center gap-1">RNTRC da Transportadora *
                                        <v-tooltip text="Registro Nacional de Transportadores Rodoviários de Cargas. Emitido pela ANTT. Se não preenchido a Sefaz rejeita o CT-e." location="top"><template v-slot:activator="{ props }"><v-icon v-bind="props" size="14" color="error">mdi-alert</v-icon></template></v-tooltip>
                                    </label>
                                    <v-text-field v-model="form.rntrc" variant="outlined" density="compact" class="ui-field font-weight-bold"></v-text-field>
                                </v-col>
                                <v-col cols="12" md="6"><label class="input-label">Placa do Veículo Trator</label><v-text-field v-model="form.veiculo_placa" variant="outlined" density="compact" class="ui-field text-uppercase" maxlength="7" placeholder="Ex: ABC1234"></v-text-field></v-col>
                                <v-col cols="12" md="12">
                                    <label class="input-label">Observações (Impressas no DACTE)</label>
                                    <v-textarea v-model="form.informacoes_adicionais" variant="outlined" density="compact" rows="3" class="ui-field" placeholder="Informações de interesse do contribuinte, horário de entrega, etc."></v-textarea>
                                </v-col>
                            </v-row>
                        </div>
                    </v-card>

                </v-form>
            </div>
        </v-card>
    </v-dialog>

    <v-dialog v-model="cceModal.show" max-width="500">
        <v-card class="rounded-0 border-t-lg border-t-info">
            <div class="pa-6">
                <div class="d-flex align-center gap-3 mb-4">
                    <v-icon size="32" color="info">mdi-file-document-edit-outline</v-icon>
                    <div class="text-h6 font-weight-black leading-tight">Carta de Correção (CC-e)</div>
                </div>
                <p class="text-body-2 text-grey-darken-1 mb-4">A correção é livre, mas não altera valores e datas.</p>

                <v-text-field v-model="cceModal.grupo" label="Grupo Alterado (Ex: ide, rem, dest)" variant="outlined" density="comfortable" class="ui-field font-weight-bold mb-2"></v-text-field>
                <v-text-field v-model="cceModal.campo" label="Campo Alterado (Ex: xMun)" variant="outlined" density="comfortable" class="ui-field font-weight-bold mb-2"></v-text-field>
                <v-textarea v-model="cceModal.valor" label="Novo Valor" variant="outlined" density="comfortable" rows="3" class="ui-field mb-2"></v-textarea>

                <div class="d-flex justify-end gap-3 mt-4">
                    <v-btn variant="outlined" class="btn-rect font-weight-bold" @click="cceModal.show = false">Cancelar</v-btn>
                    <v-btn color="info" variant="flat" class="btn-rect font-weight-black px-6" @click="submitCCe" :loading="cceModal.loading">Enviar Sefaz</v-btn>
                </div>
            </div>
        </v-card>
    </v-dialog>

    <v-dialog v-model="cancelModal.show" max-width="450">
        <v-card class="rounded-0 border-t-lg border-t-error">
            <div class="pa-6">
                <div class="d-flex align-center gap-3 mb-4">
                    <v-icon size="32" color="error">mdi-alert-octagon</v-icon>
                    <div class="text-h6 font-weight-black text-error leading-tight">Cancelar CT-e</div>
                </div>
                <v-textarea v-model="cancelModal.justificativa" label="Justificativa (Mín. 15 char)" variant="outlined" density="comfortable" rows="3" class="ui-field"></v-textarea>
                <div class="d-flex justify-end gap-3 mt-4">
                    <v-btn variant="outlined" class="btn-rect font-weight-bold" @click="cancelModal.show = false">Voltar</v-btn>
                    <v-btn color="error" variant="flat" class="btn-rect font-weight-black px-6" @click="submitCancel" :loading="cancelModal.loading">Confirmar</v-btn>
                </div>
            </div>
        </v-card>
    </v-dialog>

    <v-dialog v-model="desacordoModal.show" max-width="450">
        <v-card class="rounded-0 border-t-lg border-t-error">
            <div class="pa-6">
                <div class="d-flex align-center gap-3 mb-4">
                    <v-icon size="32" color="error">mdi-close-octagon-outline</v-icon>
                    <div class="text-h6 font-weight-black text-error leading-tight">Desconhecer Frete</div>
                </div>
                <p class="text-body-2 text-grey-darken-1 mb-4">
                    Isso informará à Sefaz o evento de <strong>Prestação de Serviço em Desacordo</strong>, isentando sua empresa desta cobrança.
                </p>
                <v-textarea v-model="desacordoModal.justificativa" label="Justificativa (Obrigatório, mín. 15 char)" variant="outlined" density="comfortable" rows="3" class="ui-field"></v-textarea>
                <div class="d-flex justify-end gap-3 mt-4">
                    <v-btn variant="outlined" class="btn-rect font-weight-bold" @click="desacordoModal.show = false">Cancelar</v-btn>
                    <v-btn color="error" variant="flat" class="btn-rect font-weight-black px-6" @click="submitDesacordo" :loading="desacordoModal.loading">Enviar Sefaz</v-btn>
                </div>
            </div>
        </v-card>
    </v-dialog>

  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, reactive } from 'vue';
import { useAppStore } from '@/stores/app';
import { useThemeStore } from '@/stores/themeStore';
import { useCompanyStore } from '@/stores/company';
import { useUserStore } from '@/stores/user';
import { sefazService } from '@/api/sefazApi';
import axios from 'axios';
import { supabase } from '@/api/supabase';
import { format, parseISO, startOfMonth, endOfMonth, startOfWeek, endOfWeek, startOfYear, endOfYear, isSameDay, isWithinInterval } from 'date-fns';

const appStore = useAppStore();
const themeStore = useThemeStore();
const companyStore = useCompanyStore();
const userStore = useUserStore();

// --- ESTADOS E FILTROS ---
const loadingGrid = ref(false);
const ctes = ref<any[]>([]);
const search = ref('');
const statusFilter = ref('all');
const currentTab = ref('active');
const syncing = ref(false);
const lastSyncTime = ref('--:--');

const statusOptions = [
    { label: 'Todos', value: 'all' },
    { label: 'Autorizado', value: 'autorizado' },
    { label: 'Cancelado', value: 'cancelado' },
    { label: 'Desacordo', value: 'desacordo' },
    { label: 'Pendente', value: 'pendente' }
];

// Lógica de Datas
const currentPeriod = ref('month');
const periodLabel = computed(() => {
    const map: any = { 'month': 'Este Mês', 'week': 'Esta Semana', 'today': 'Hoje', 'year': 'Este Ano', 'all': 'Todos' };
    return map[currentPeriod.value] || 'Período';
});
const setPeriod = (val: string) => { currentPeriod.value = val; };

// Paginação e Multi-Empresa
const page = ref(1);
const itemsPerPage = 50;
const companies = ref<any[]>([]);
const activeCompany = ref<any>(null);
const selectedNotes = ref<string[]>([]);
const xmlInput = ref<HTMLInputElement | null>(null);

// --- COMPuted KPIs e Filtros ---
const filteredCtes = computed(() => {
    let result = ctes.value;

    if (currentTab.value === 'active') result = result.filter(c => c.status_processamento !== 'arquivado');
    else result = result.filter(c => c.status_processamento === 'arquivado');

    if (activeCompany.value) {
        const cnpjClean = activeCompany.value.cnpj.replace(/\D/g, '');
        result = result.filter(c => c.cnpj_emitente === cnpjClean || c.cnpj_destinatario === cnpjClean);
    }

    if (currentPeriod.value !== 'all') {
        const now = new Date();
        let startD, endD;
        if (currentPeriod.value === 'month') { startD = startOfMonth(now); endD = endOfMonth(now); }
        else if (currentPeriod.value === 'week') { startD = startOfWeek(now); endD = endOfWeek(now); }
        else if (currentPeriod.value === 'today') { startD = now; endD = now; }
        else if (currentPeriod.value === 'year') { startD = startOfYear(now); endD = endOfYear(now); }

        if (startD && endD) {
            result = result.filter(n => {
                const date = parseISO(n.data_emissao || n.created_at);
                if (currentPeriod.value === 'today') return isSameDay(date, now);
                return isWithinInterval(date, { start: startD, end: endD });
            });
        }
    }

    if (statusFilter.value !== 'all') {
        result = result.filter(c => (c.status_sefaz || '').toLowerCase().includes(statusFilter.value));
    }

    if (search.value) {
        const s = search.value.toLowerCase();
        result = result.filter(c =>
            (c.chave && c.chave.toLowerCase().includes(s)) ||
            (c.emitente_nome && c.emitente_nome.toLowerCase().includes(s)) ||
            (c.tomador_nome && c.tomador_nome.toLowerCase().includes(s)) ||
            (c.numero && String(c.numero).includes(s))
        );
    }

    return result.sort((a, b) => new Date(b.data_emissao || b.created_at).getTime() - new Date(a.data_emissao || a.created_at).getTime());
});

const paginatedCtes = computed(() => {
    const start = (page.value - 1) * itemsPerPage;
    return filteredCtes.value.slice(start, start + itemsPerPage);
});
const pageCount = computed(() => Math.ceil(filteredCtes.value.length / itemsPerPage));

// KPIs Calcs
const emittedCount = computed(() => filteredCtes.value.filter(c => c.source === 'emitted').length);
const inboundCount = computed(() => filteredCtes.value.filter(c => c.source === 'inbound').length);
const totalFretePeriodo = computed(() => filteredCtes.value.reduce((acc, c) => acc + (Number(c.valor_frete) || 0), 0));

const areAllSelected = computed(() => paginatedCtes.value.length > 0 && paginatedCtes.value.every(c => selectedNotes.value.includes(c.chave)));
const toggleSelectAll = (val: boolean) => {
    if (val) selectedNotes.value = Array.from(new Set([...selectedNotes.value, ...paginatedCtes.value.map(c => c.chave)]));
    else selectedNotes.value = selectedNotes.value.filter(k => !paginatedCtes.value.find(c => c.chave === k));
};

// --- FUNÇÕES DE INTERFACE ---
const getStatusLabel = (status: string) => status ? status.toUpperCase() : 'PENDENTE';
const getStatusClass = (status: string) => {
    const s = (status || '').toLowerCase();
    if(s.includes('autorizado')) return 'chip-success';
    if(s.includes('cancelado')) return 'chip-danger';
    if(s.includes('desacordo')) return 'chip-danger';
    if(s.includes('rejeitado')) return 'chip-warn';
    return 'chip-info';
};

const copyToClipboard = (text: string) => { if(text) { navigator.clipboard.writeText(text); appStore.showSnackbar('Chave copiada!', 'success'); } };
const triggerXmlInput = () => { if (xmlInput.value) xmlInput.value.click(); };
const handleXmlUpload = (e: any) => { console.log('Upload XML Local...'); };

const loadCompanies = async () => {
   try {
      const { data } = await supabase.from('companies').select('*');
      if (data) companies.value = data;
   } catch (e) {}
};

const switchCompany = (comp: any) => {
    activeCompany.value = comp;
    fetchCtes();
};

// ==========================================
// DB & SYNC LOGIC
// ==========================================
const fetchCtes = async () => {
    loadingGrid.value = true;
    try {
        const cnpjAlvo = activeCompany.value?.cnpj || companyStore.currentCompany?.cnpj;
        const cnpjClean = cnpjAlvo ? cnpjAlvo.replace(/\D/g, '') : null;

        const { data: dbData, error: dbError } = await supabase.from('cte_entries').select('*');
        if (dbError) console.error("❌ Erro db local:", dbError);

        ctes.value = dbData || [];

    } catch (e) {
        console.error(e);
        appStore.showSnackbar('Erro ao carregar lista de CT-e.', 'error');
    } finally {
        loadingGrid.value = false;
    }
};

const syncCtesFromSefaz = async () => {
    const cnpjAlvo = activeCompany.value?.cnpj || companyStore.currentCompany?.cnpj;
    if (!cnpjAlvo) return appStore.showSnackbar('Selecione uma empresa para sincronizar.', 'warning');

    syncing.value = true;

    try {
        const { data: maxNsuData } = await supabase
            .from('cte_entries')
            .select('nsu')
            .eq('source', 'inbound')
            .order('nsu', { ascending: false })
            .limit(1);

        let lastNsu = 0;
        if (maxNsuData && maxNsuData.length > 0 && maxNsuData[0].nsu) {
            lastNsu = parseInt(maxNsuData[0].nsu);
        }

        const res = await sefazService.sincronizarCTes(cnpjAlvo, lastNsu);

        if (res?.status === 'blocked') {
            appStore.showSnackbar(`Sefaz em espera. Tente em ${res.wait_minutes} min.`, 'warning');

        } else if (res?.notas && res.notas.length > 0) {
            const formatCTesToInsert = res.notas.map((n: any) => ({
                chave: n.chave,
                cnpj_emitente: n.cnpj_emitente,
                emitente_nome: n.emitente_nome,
                valor_frete: n.valor_frete,
                data_emissao: n.data_emissao,
                status_sefaz: n.status_sefaz || 'Autorizado',
                nsu: parseInt(n.nsu),
                source: 'inbound',
                tomador_nome: 'Sua Empresa (Destinatário)',
                company_id: activeCompany.value?.id || companyStore.currentCompany?.id,
                cnpj_destinatario: cnpjAlvo.replace(/\D/g, '')
            }));

            const { error } = await supabase.from('cte_entries').upsert(formatCTesToInsert, { onConflict: 'chave' });
            if (!error) {
                lastSyncTime.value = format(new Date(), 'HH:mm');
                appStore.showSnackbar(`${res.notas.length} CT-es recebidos e salvos!`, 'success');
            }
        } else {
            appStore.showSnackbar('Sefaz diz: Nenhum CT-e novo no momento.', 'info');
        }

        await fetchCtes();
    } catch (e: any) {
        console.error("❌ [ERRO SYNC SEFAZ CT-E]", e);
        appStore.showSnackbar('Erro ao conectar na Sefaz.', 'error');
    } finally {
        syncing.value = false;
    }
};

onMounted(() => {
    loadCompanies();
    fetchCtes();
});

const archiveCte = async (item: any) => {
    try {
        await supabase.from('cte_entries').update({ status_processamento: 'arquivado' }).eq('id', item.id);
        item.status_processamento = 'arquivado';
        appStore.showSnackbar('CT-e Arquivado', 'success');
    } catch(e) {}
};

const unarchiveCte = async (item: any) => {
    try {
        await supabase.from('cte_entries').update({ status_processamento: null }).eq('id', item.id);
        item.status_processamento = null;
    } catch(e) {}
};

const archiveSelected = async () => {
    if(selectedNotes.value.length === 0) return;
    try {
        for(const chave of selectedNotes.value) {
            await supabase.from('cte_entries').update({ status_processamento: 'arquivado' }).eq('chave', chave);
        }
        selectedNotes.value = [];
        fetchCtes();
        appStore.showSnackbar('Arquivados em lote!', 'success');
    } catch(e) {}
};

// ==========================================
// EMISSÃO DE CT-E - NOVAS OPÇÕES
// ==========================================
const estados = ['SP', 'RJ', 'MG', 'RS', 'PR', 'SC', 'BA', 'PE', 'DF', 'GO', 'ES', 'CE', 'PA', 'MA', 'PB', 'AM', 'RN', 'AL', 'PI', 'MT', 'MS', 'SE', 'RO', 'TO', 'AC', 'AP', 'RR'];

const cfopOptions = [
    { value: 5353, title: '5353 - Transporte dentro do estado (Intermunicipal)' },
    { value: 6353, title: '6353 - Transporte para outro estado (Interestadual)' },
    { value: 5359, title: '5359 - Transporte p/ não contribuinte (No estado)' },
    { value: 6359, title: '6359 - Transporte p/ não contribuinte (Outro estado)' },
    { value: 7358, title: '7358 - Transporte de Exportação' },
];

const tomadorOptions = [
    { value: 0, title: '0 - Remetente (CIF - Quem envia paga o frete)' },
    { value: 3, title: '3 - Destinatário (FOB - Quem recebe paga o frete)' },
    { value: 4, title: '4 - Outros (Terceiro pagador)' }
];

const emissionModal = reactive({ show: false, loading: false });
const tempNfeKey = ref('');

const initialFormState = () => ({
    ambiente: 'homologacao', natureza_operacao: 'PRESTACAO DE SERVICO DE TRANSPORTE', cfop: 5353,
    uf_inicio: 'SP', municipio_inicio_nome: 'Sao Paulo', municipio_inicio_ibge: '3550308',
    uf_fim: 'RJ', municipio_fim_nome: 'Rio de Janeiro', municipio_fim_ibge: '3304557',
    tomador_role: 0, valor_frete: 0, valor_mercadoria: 0, produto_predominante: 'MERCADORIAS EM GERAL',
    peso_bruto: 0, qtd_volumes: 0, rntrc: '', veiculo_placa: '', informacoes_adicionais: '', chaves_nfe: [] as string[],
    remetente: { cnpj_cpf: '', nome: '', ie: '', endereco: { logradouro: '', numero: '', municipio: '', uf: '', cep: '', codigo_municipio: '3550308' } },
    destinatario: { cnpj_cpf: '', nome: '', ie: '', endereco: { logradouro: '', numero: '', municipio: '', uf: '', cep: '', codigo_municipio: '3304557' } }
});

const form = ref(initialFormState());

const emissionCompany = ref<any>(null);

const openEmissionModal = () => {
    form.value = initialFormState();
    tempNfeKey.value = '';

    // Tenta pegar a empresa selecionada no filtro da tela.
    // Se estiver em "Todas as Lojas" (null), busca do contexto global
    let comp = activeCompany.value;
    if (!comp) {
        const contextId = companyStore.context || companyStore.currentCompany?.id;
        comp = companies.value.find(c => c.id === contextId) || companies.value[0];
    }

    emissionCompany.value = comp;

    // Preenche automaticamente o estado base e o RNTRC (caso exista na empresa)
    if (comp) {
        form.value.uf_inicio = comp.uf || comp.estado || 'SP';
        form.value.municipio_inicio_nome = comp.city || comp.cidade || comp.municipio || '';
        if (comp.rntrc) {
            form.value.rntrc = comp.rntrc;
        }
    }

    emissionModal.show = true;
};

const addNfeKey = () => {
    const key = tempNfeKey.value.replace(/\D/g, '');
    if (key.length !== 44) return appStore.showSnackbar('A chave da NF-e deve conter 44 números exatos.', 'warning');
    if (form.value.chaves_nfe.includes(key)) return;
    form.value.chaves_nfe.push(key); tempNfeKey.value = '';
};

const submitCte = async () => {
    if (!emissionCompany.value) return appStore.showSnackbar('Selecione a empresa emissora no topo do modal.', 'error');
    if (form.value.chaves_nfe.length === 0) return appStore.showSnackbar('É obrigatório vincular pelo menos uma NF-e.', 'warning');
    if (!form.value.rntrc) return appStore.showSnackbar('O RNTRC é obrigatório para CT-e rodoviário.', 'error');
    if (form.value.peso_bruto <= 0) return appStore.showSnackbar('O Peso Bruto deve ser maior que zero.', 'warning');

    emissionModal.loading = true;
    try {
        const comp = emissionCompany.value;
        const cnpjEmitente = comp?.cnpj?.replace(/\D/g, '');
        if (!cnpjEmitente) throw new Error("CNPJ da empresa não configurado.");

        const payload = { freight: form.value, cnpj_emitente: cnpjEmitente, ie_emitente: comp?.state_registration || comp?.ie };

        const SEFAZ_PROXY_URL_LOCAL = import.meta.env.VITE_SEFAZ_PROXY_URL || 'https://sefaz-proxy-dujl.onrender.com';
        const res = await axios.post(`${SEFAZ_PROXY_URL_LOCAL}/api/emitir-cte`, payload);
        appStore.showSnackbar('CT-e Transmitido com sucesso!', 'success');

        await supabase.from('cte_entries').insert({
            chave: res.data.chave, numero: res.data.numero, id_nuvem: res.data.id_nuvem,
            status_sefaz: res.data.status_sefaz || 'pendente', source: 'emitted', data_emissao: new Date().toISOString(),
            emitente_nome: comp?.name || comp?.razao_social,
            cnpj_emitente: cnpjEmitente,
            tomador_nome: form.value.tomador_role === 0 ? form.value.remetente.nome : form.value.destinatario.nome,
            ambiente: form.value.ambiente, natureza_operacao: form.value.natureza_operacao, cfop: form.value.cfop,
            uf_inicio: form.value.uf_inicio, municipio_inicio_nome: form.value.municipio_inicio_nome, municipio_inicio_ibge: form.value.municipio_inicio_ibge,
            uf_fim: form.value.uf_fim, municipio_fim_nome: form.value.municipio_fim_nome, municipio_fim_ibge: form.value.municipio_fim_ibge,
            tomador_role: form.value.tomador_role, valor_frete: form.value.valor_frete, valor_mercadoria: form.value.valor_mercadoria,
            produto_predominante: form.value.produto_predominante, peso_bruto: form.value.peso_bruto, qtd_volumes: form.value.qtd_volumes,
            rntrc: form.value.rntrc, veiculo_placa: form.value.veiculo_placa, informacoes_adicionais: form.value.informacoes_adicionais,
            chaves_nfe: form.value.chaves_nfe, remetente: form.value.remetente, destinatario: form.value.destinatario,
            company_id: comp.id
        });

        emissionModal.show = false;
        fetchCtes();
    } catch (e: any) {
        appStore.showSnackbar(e.response?.data?.message || 'Erro ao emitir CT-e na Sefaz', 'error');
    } finally {
        emissionModal.loading = false;
    }
};

const downloadDocument = async (tipo: 'pdf' | 'xml', item: any) => {
    const id = item.id_nuvem || item.chave;
    if (!id) return;
    window.open(sefazService.getProxyCteDownloadUrl(tipo, id), '_blank');
};

const syncStatus = async (item: any) => {
    if (!item.id_nuvem) return;
    try {
        const SEFAZ_PROXY_URL_LOCAL = import.meta.env.VITE_SEFAZ_PROXY_URL || 'https://sefaz-proxy-dujl.onrender.com';
        const res = await axios.post(`${SEFAZ_PROXY_URL_LOCAL}/api/cte/${item.id_nuvem}/sincronizar`);
        appStore.showSnackbar('Sincronizado: ' + res.data.data.status, 'success');
        await supabase.from('cte_entries').update({ status_sefaz: res.data.data.status }).eq('id', item.id);
        item.status_sefaz = res.data.data.status;
    } catch (error) {}
};

const cancelModal = reactive({ show: false, loading: false, item: null as any, justificativa: '' });
const openCancelModal = (item: any) => { cancelModal.item = item; cancelModal.justificativa = ''; cancelModal.show = true; };
const submitCancel = async () => {
    if (cancelModal.justificativa.length < 15) return;
    cancelModal.loading = true;
    try {
        const SEFAZ_PROXY_URL_LOCAL = import.meta.env.VITE_SEFAZ_PROXY_URL || 'https://sefaz-proxy-dujl.onrender.com';
        await axios.post(`${SEFAZ_PROXY_URL_LOCAL}/api/cte/cancelar`, { cte_id: cancelModal.item.id_nuvem, justificativa: cancelModal.justificativa });
        appStore.showSnackbar('Cancelamento solicitado!', 'success');
        cancelModal.show = false; syncStatus(cancelModal.item);
    } catch (error: any) { appStore.showSnackbar(error.response?.data?.message || 'Erro', 'error'); }
    finally { cancelModal.loading = false; }
};

const cceModal = reactive({ show: false, loading: false, item: null as any, grupo: '', campo: '', valor: '' });
const openCCeModal = (item: any) => { cceModal.item = item; cceModal.grupo = ''; cceModal.campo = ''; cceModal.valor = ''; cceModal.show = true; };
const submitCCe = async () => {
    if (!cceModal.grupo || !cceModal.campo || !cceModal.valor) return;
    cceModal.loading = true;
    try {
        const SEFAZ_PROXY_URL_LOCAL = import.meta.env.VITE_SEFAZ_PROXY_URL || 'https://sefaz-proxy-dujl.onrender.com';
        await axios.post(`${SEFAZ_PROXY_URL_LOCAL}/api/cte/${cceModal.item.id_nuvem}/carta-correcao`, {
            correcoes: [{ grupo_alterado: cceModal.grupo, campo_alterado: cceModal.campo, valor_alterado: cceModal.valor }]
        });
        appStore.showSnackbar('CC-e enviada!', 'success'); cceModal.show = false;
    } catch (error: any) { appStore.showSnackbar(error.response?.data?.message || 'Erro', 'error'); }
    finally { cceModal.loading = false; }
};

const desacordoModal = reactive({ show: false, loading: false, item: null as any, justificativa: 'Prestacao de servico em desacordo' });
const openDesacordoModal = (item: any) => { desacordoModal.item = item; desacordoModal.show = true; };

const submitDesacordo = async () => {
    if (desacordoModal.justificativa.length < 15) return appStore.showSnackbar('Justificativa muito curta.', 'warning');
    desacordoModal.loading = true;
    try {
        const cnpjAlvo = activeCompany.value?.cnpj || companyStore.currentCompany?.cnpj;
        const SEFAZ_PROXY_URL_LOCAL = import.meta.env.VITE_SEFAZ_PROXY_URL || 'https://sefaz-proxy-dujl.onrender.com';
        const response = await axios.post(`${SEFAZ_PROXY_URL_LOCAL}/api/cte/desacordo`, {
             chave: desacordoModal.item.chave, cnpj: cnpjAlvo, justificativa: desacordoModal.justificativa
        });

        alert(`✅ DESACORDO AUTORIZADO PELA SEFAZ!\n\nGuarde este comprovante legal:\nProtocolo: ${response.data.protocolo}\nData: ${response.data.data}`);
        appStore.showSnackbar('Desacordo registrado na Sefaz!', 'success');

        await supabase.from('cte_entries').update({ status_sefaz: 'Desacordo' }).eq('id', desacordoModal.item.id);
        desacordoModal.item.status_sefaz = 'Desacordo';
        desacordoModal.show = false;
    } catch (error: any) {
        appStore.showSnackbar(error.response?.data?.message || error.response?.data?.error || 'Erro ao comunicar desacordo', 'error');
    } finally {
        desacordoModal.loading = false;
    }
};

const formatDateSafe = (d: string) => { if (!d) return '-'; try { return format(parseISO(d), 'dd/MM/yy'); } catch { return '-'; } };
const formatCurrency = (val:any) => new Intl.NumberFormat('pt-BR', {style:'currency',currency:'BRL'}).format(Number(val)||0);
const formatCurrencyValue = (val:any) => new Intl.NumberFormat('pt-BR', {minimumFractionDigits:2}).format(Number(val)||0);
</script>

<style scoped lang="scss">
:global(.tooltip-custom) { background-color: #212121 !important; color: #ffffff !important; font-weight: 700 !important; font-size: 12px !important; border-radius: 6px !important; box-shadow: 0px 4px 10px rgba(0,0,0,0.3) !important; }

.fiscal-layout { position: relative; }
.background-carousel-wrapper { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 0; opacity: 0.6; pointer-events: none; }
.background-overlay { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 1; background: radial-gradient(circle at center, rgba(15, 15, 19, 0.4), rgba(15, 15, 19, 0.98)); backdrop-filter: blur(8px); }
.z-10 { position: relative; z-index: 10; }

.bg-glass-dark { background: rgba(10,10,12,0.85); }
.bg-glass-header { background: rgba(20,20,24,0.55); backdrop-filter: blur(14px); }
.border-bottom-white-05 { border-bottom: 1px solid rgba(255,255,255,0.08); }
.border-white-10 { border: 1px solid rgba(255,255,255,0.1) !important; }

/* Estilos Trazidos da NF-e */
.fixed-dialog { overflow: hidden !important; }
.absolute-fill { height: 100%; overflow-y: auto; }
.ui-field :deep(.v-field) { border-radius: 6px !important; background-color: #ffffff; font-size: 14px; }
.row-gap { row-gap: 16px; margin-top: 4px; }
.input-label { display: block; font-size: 11px; font-weight: 800; text-transform: uppercase; color: #757575; margin-bottom: 6px; letter-spacing: 0.5px; }

.btn-3d { border-radius: 6px !important; box-shadow: 0 3px 5px rgba(0,0,0,0.15), inset 0 2px 0 rgba(255,255,255,0.25) !important; transition: transform 0.1s ease, box-shadow 0.1s ease; text-transform: none !important; }
.btn-3d:active { transform: translateY(2px); box-shadow: 0 1px 2px rgba(0,0,0,0.15), inset 0 1px 0 rgba(255,255,255,0.2) !important; }
.glass-card { background: rgba(255,255,255,0.03); backdrop-filter: blur(10px); }

/* Antigos */
.btn-rect { border-radius: 0 !important; text-transform: none !important; font-weight: 800; }
.controls-bar { border: 1px solid rgba(0,0,0,0.08); border-radius: 0; padding: 10px; }
.controls-light { background: #ffffff; }
.controls-dark { background: rgba(30,30,35,0.55); backdrop-filter: blur(16px); border: 1px solid rgba(255,255,255,0.08); }
.search-wrap { height: 40px; border-radius: 0; padding: 0 12px; min-width: 300px; flex: 1; }
.search-light { background: #f4f6f8; border: 1px solid rgba(0,0,0,0.08); }
.search-dark { background: rgba(255,255,255,0.08); border: 1px solid rgba(255,255,255,0.10); }
.clean-input { border: none; outline: none; background: transparent; font-size: 12px; color: inherit; width: 100%; }

/* KPIs */
.kpi-bg-icon { position: absolute; right: -20px; bottom: -20px; opacity: 0.15; transform: rotate(-15deg); pointer-events: none; }
.kpi-bg-icon .v-icon { font-size: 100px; color: white; }
.kpi-card { border: 1px solid rgba(255,255,255,0.15); color: white; min-height: 110px; position: relative; overflow: hidden; }
.bg-gradient-info { background: linear-gradient(135deg, #0288d1, #005b9f); }
.bg-gradient-green { background: linear-gradient(135deg, #2e7d32, #1b5e20); }
.bg-gradient-purple { background: linear-gradient(135deg, #7b1fa2, #4a148c); }
.bg-gradient-warning { background: linear-gradient(135deg, #FFB300, #F57F17); }
.kpi-label { font-size: 12px; font-weight: 900; letter-spacing: .2px; }
.kpi-value { font-size: 22px; font-weight: 900; letter-spacing: .2px; }
.kpi-footer { font-size: 10px; font-weight: bold; opacity: 0.8; text-transform: uppercase; }

/* Grid */
.grid-fiscal-layout { display: grid; width: 100%; grid-template-columns: 50px 60px 1.2fr 1.2fr 2fr 100px 110px 110px 160px; min-width: 1200px; }
.cell { padding: 8px 10px; display: flex; align-items: center; border-right: 1px solid rgba(0,0,0,0.08); border-bottom: 1px solid rgba(0,0,0,0.08); min-height: 56px; overflow: hidden; }
.center { justify-content: center; text-align: center; }
.right { justify-content: flex-end; text-align: right; }
.zebra-row:nth-child(even) .cell { background-color: rgba(0,0,0,0.02); }
.grid-row-dark.zebra-row:nth-child(even) .cell { background-color: rgba(255,255,255,0.02); }
.grid-header .cell { min-height: 44px; font-size: 12px; font-weight: 900; text-transform: uppercase; letter-spacing: .6px; }
.grid-surface-light .cell { background: #f5f7fa; color: rgba(0,0,0,0.7); border-color: rgba(0,0,0,0.10); }
.grid-surface-dark .cell { background: rgba(255,255,255,0.08); color: rgba(255,255,255,0.80); border-color: rgba(255,255,255,0.10); }
.sticky-head { position: sticky; top: 0; z-index: 10; }

.solid-chip { display: inline-flex; align-items: center; justify-content: center; height: 22px; padding: 0 10px; border-radius: 8px; font-size: 10px; font-weight: 900; color: #fff; white-space: nowrap; }
.chip-success { background: #2e7d32; }
.chip-warn { background: #f57f17; }
.chip-info { background: #1976d2; }
.chip-danger { background: #c62828; }

.actions-inline { display: flex; align-items: center; justify-content: center; gap: 8px; }
.action-btn { width: 32px !important; height: 32px !important; border-radius: 8px !important; color: #fff !important; }
.action-edit { background: #1976d2 !important; }

.list-text-10 { font-size: 13px !important; line-height: 1.25 !important; }
.shadow-button { box-shadow: 0 4px 15px rgba(57, 73, 171, 0.4); }

.custom-scroll::-webkit-scrollbar { width: 8px; height: 8px; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.35); border-radius: 6px; }
.custom-scroll::-webkit-scrollbar-track { background: transparent; }
.border-dashed { border-style: dashed !important; border-color: rgba(0,0,0,0.12) !important; }
</style>
