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
                    <span class="font-weight-bold">Monitor DFe</span>
                </div>
                <div class="text-h6 font-weight-black tracking-tight leading-none mt-1" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">
                    Gestão de Documentos Fiscais
                </div>
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
                                    <span class="kpi-label">Sincronização</span>
                                </div>
                                <div class="text-caption opacity-80 font-mono">{{ lastSyncTime }}</div>
                            </div>
                            <div class="d-flex flex-column">
                                <v-btn
                                    variant="outlined"
                                    color="white"
                                    size="small"
                                    class="btn-rect font-weight-bold mb-1"
                                    :loading="syncing"
                                    :disabled="isSyncBlocked"
                                    @click="syncNotesFromSefaz()"
                                >
                                    <v-icon start size="16">mdi-refresh</v-icon>
                                    {{ syncing ? 'Sincronizando...' : (activeCompany ? 'Puxar Notas (Loja)' : 'Puxar Notas (Todas)') }}
                                </v-btn>
                                <div v-if="isSyncBlocked" class="text-caption text-amber-accent-1 font-weight-bold d-flex align-center">
                                    <v-icon start size="12" class="mr-1">mdi-timer-sand</v-icon>
                                    Bloqueio: {{ syncCountdownStr }}
                                </div>
                                <div v-else class="text-caption text-white opacity-70">
                                    <v-icon start size="12" class="mr-1">mdi-check-circle-outline</v-icon>
                                    Serviço Disponível
                                </div>
                            </div>
                        </div>
                    </v-card>
                </v-col>

                <v-col cols="12" sm="6" md="3">
                    <v-card class="kpi-card kpi-rect bg-gradient-purple hover-elevate py-3 px-4" v-ripple elevation="2">
                        <div class="kpi-bg-icon"><v-icon>mdi-file-document-multiple</v-icon></div>
                        <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                            <div class="d-flex align-center" style="gap: 8px;">
                                <v-icon size="18" class="opacity-80">mdi-file-document-multiple</v-icon>
                                <span class="kpi-label">Notas Ativas</span>
                            </div>
                            <div class="kpi-number-group my-1">
                                <span class="kpi-value">{{ unifiedNotes.length }}</span>
                                <span class="text-caption ml-1 opacity-70">listadas</span>
                            </div>
                            <div class="kpi-footer mt-1">Pendentes + Locais</div>
                        </div>
                    </v-card>
                </v-col>

                <v-col cols="12" sm="6" md="3">
                    <v-card class="kpi-card kpi-rect bg-gradient-green hover-elevate py-3 px-4" v-ripple elevation="2">
                        <div class="kpi-bg-icon"><v-icon>mdi-cash-multiple</v-icon></div>
                        <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                            <div class="d-flex align-center" style="gap: 8px;">
                                <v-icon size="18" class="opacity-80">mdi-cash-multiple</v-icon>
                                <span class="kpi-label">Total do Período</span>
                            </div>
                            <div class="kpi-number-group my-1">
                                <span class="text-body-2 font-weight-medium mr-1 opacity-70">R$</span>
                                <span class="kpi-value text-h5">{{ formatCurrencyValue(totalValue) }}</span>
                            </div>
                            <div class="kpi-footer mt-1">{{ periodLabel }}</div>
                        </div>
                    </v-card>
                </v-col>

                <v-col cols="12" sm="6" md="3">
                    <v-card
                        class="kpi-card kpi-rect hover-elevate py-3 px-4 cursor-pointer"
                        :class="pendingCount > 0 ? 'bg-gradient-warning' : 'bg-gradient-grey'"
                        v-ripple
                        elevation="2"
                        @click="statusFilter = 'uninformed'"
                    >
                        <div class="kpi-bg-icon"><v-icon>mdi-alert-decagram</v-icon></div>
                        <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                            <div class="d-flex align-center" style="gap: 8px;">
                                <v-icon size="18" class="opacity-80">mdi-alert-decagram</v-icon>
                                <span class="kpi-label">Não Informadas</span>
                            </div>
                            <div class="kpi-number-group my-1">
                                <span class="kpi-value">{{ pendingCount }}</span>
                            </div>
                            <div class="kpi-footer mt-1">Aguardando Ação</div>
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
                            <v-btn
                                v-bind="props"
                                variant="outlined"
                                class="btn-rect font-weight-bold"
                                height="40"
                                color="primary"
                                prepend-icon="mdi-calendar-range"
                            >
                                {{ periodLabel }} <v-icon end size="small">mdi-chevron-down</v-icon>
                            </v-btn>
                        </template>
                        <v-card min-width="280" class="rounded-0 pa-2">
                            <v-list density="compact" nav>
                                <v-list-item @click="setPeriod('month')" :active="currentPeriod === 'month'"><v-list-item-title>Este Mês</v-list-item-title></v-list-item>
                                <v-list-item @click="setPeriod('week')" :active="currentPeriod === 'week'"><v-list-item-title>Esta Semana</v-list-item-title></v-list-item>
                                <v-list-item @click="setPeriod('today')" :active="currentPeriod === 'today'"><v-list-item-title>Hoje</v-list-item-title></v-list-item>
                                <v-list-item @click="setPeriod('year')" :active="currentPeriod === 'year'"><v-list-item-title>Este Ano</v-list-item-title></v-list-item>
                                <v-list-item @click="currentPeriod = 'custom'" :active="currentPeriod === 'custom'"><v-list-item-title>Personalizado</v-list-item-title></v-list-item>
                            </v-list>
                            <div v-if="currentPeriod === 'custom'" class="pa-2 border-t mt-1">
                                <v-text-field v-model="customDateStart" type="date" label="Início" density="compact" variant="outlined" hide-details class="mb-2"></v-text-field>
                                <v-text-field v-model="customDateEnd" type="date" label="Fim" density="compact" variant="outlined" hide-details class="mb-2"></v-text-field>
                            </div>
                        </v-card>
                    </v-menu>

                    <div class="d-flex rounded p-1" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-3' : 'bg-white-10'" style="padding: 4px;">
                        <v-btn variant="flat" class="btn-rect" height="32" :color="currentTab === 'active' ? (themeStore.currentMode === 'light' ? 'white' : 'grey-darken-3') : 'transparent'" @click="currentTab = 'active'" :class="{'text-grey-darken-3': currentTab === 'active' && themeStore.currentMode === 'light', 'text-grey-darken-1': currentTab !== 'active'}">
                            <v-icon start size="16" class="mr-1">mdi-file-document-multiple</v-icon> Ativas
                        </v-btn>
                        <v-btn variant="flat" class="btn-rect" height="32" :color="currentTab === 'archived' ? (themeStore.currentMode === 'light' ? 'white' : 'grey-darken-3') : 'transparent'" @click="currentTab = 'archived'" :class="{'text-purple': currentTab === 'archived', 'text-grey-darken-1': currentTab !== 'archived'}">
                            <v-icon start size="16" class="mr-1">mdi-archive</v-icon> Arquivadas
                        </v-btn>
                    </div>

                    <div style="width: 180px;">
                        <v-select v-model="statusFilter" :items="statusOptions" item-title="label" item-value="value" variant="outlined" density="compact" hide-details class="clean-input btn-rect" bg-color="transparent" placeholder="Status">
                             <template v-slot:prepend-inner><v-icon size="small" color="grey">mdi-filter-variant</v-icon></template>
                        </v-select>
                    </div>

                    <div class="search-wrap d-flex align-center" :class="themeStore.currentMode === 'light' ? 'search-light' : 'search-dark'">
                        <v-icon :color="themeStore.currentMode === 'light' ? 'grey-darken-1' : 'white-70'">mdi-magnify</v-icon>
                        <input v-model="search" type="text" placeholder="Buscar..." class="clean-input flex-grow-1" />
                    </div>
                </div>

                <div class="d-flex align-center flex-wrap" style="gap: 10px;">
                    <v-menu location="bottom end" transition="slide-y-transition" :close-on-content-click="true">
                        <template v-slot:activator="{ props }">
                            <v-btn
                                v-bind="props"
                                variant="outlined"
                                class="btn-rect text-none font-weight-bold"
                                height="40"
                                :color="themeStore.currentMode === 'light' ? 'grey-darken-2' : 'white'"
                                prepend-icon="mdi-domain"
                                :loading="loadingCompanies"
                            >
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

                    <v-btn variant="outlined" class="btn-rect" height="40" prepend-icon="mdi-upload" :color="themeStore.currentMode === 'light' ? 'grey-darken-2' : 'white'" @click="triggerXmlInput">Upload XML</v-btn>
                    <input type="file" ref="xmlInput" class="d-none" accept=".xml" multiple @change="handleXmlUpload">
                    <v-btn variant="text" class="btn-rect" height="40" prepend-icon="mdi-console" :color="errorCount > 0 ? 'error' : (themeStore.currentMode === 'light' ? 'grey-darken-1' : 'grey')" @click="showLogs = true">
                        Logs <v-badge v-if="errorCount > 0" color="error" :content="errorCount" inline></v-badge>
                    </v-btn>
                    <v-btn color="primary" variant="flat" class="btn-rect px-4 font-weight-bold text-caption text-uppercase letter-spacing-1" prepend-icon="mdi-shield-key" height="40" @click="openCertModal">Certificado</v-btn>
                </div>
            </div>
        </div>

        <div class="flex-grow-1 px-6 pb-2 overflow-hidden d-flex flex-column">
            <v-card
              class="flex-grow-1 d-flex flex-column rounded-0 border-thin overflow-hidden"
              :class="themeStore.currentMode === 'light' ? 'bg-white shadow-sm' : 'glass-card border-white-05'"
              :elevation="0"
            >
                <div class="grid-scroll flex-grow-1 overflow-y-auto custom-scroll">
                    <div
                      class="grid-header sticky-head"
                      :class="[
                        themeStore.currentMode === 'light' ? 'grid-surface-light' : 'grid-surface-dark',
                        'grid-fiscal-layout'
                      ]"
                    >
                        <div class="cell center">
                            <v-checkbox-btn
                               :model-value="areAllSelected"
                               :indeterminate="selectedPending.length > 0 && !areAllSelected"
                               density="compact"
                               color="error"
                               class="chk-fixed"
                               @update:model-value="toggleSelectAll"
                            ></v-checkbox-btn>
                        </div>
                        <div class="cell center header-text">Tipo</div>
                        <div class="cell header-text">Empresa (Destino)</div>
                        <div class="cell header-text">Emissor</div>
                        <div class="cell header-text">Chave de Acesso</div>
                        <div class="cell center header-text">Emissão</div>
                        <div class="cell center header-text">Status</div>
                        <div class="cell right header-text">Valor</div>
                        <div class="cell center header-text">Ações</div>
                    </div>

                    <div v-if="loading" class="d-flex flex-column justify-center align-center h-100 py-10">
                        <v-progress-circular indeterminate color="primary" size="32" width="3"></v-progress-circular>
                    </div>

                    <div v-else-if="paginatedNotes.length === 0" class="d-flex flex-column justify-center align-center h-100 opacity-60 gap-2 py-10">
                        <v-icon size="48" color="grey-lighten-1">{{ currentTab === 'archived' ? 'mdi-archive-outline' : 'mdi-file-find-outline' }}</v-icon>
                        <span class="text-body-2 font-weight-medium text-grey">{{ currentTab === 'archived' ? 'Nenhuma nota arquivada encontrada.' : 'Nenhuma nota encontrada neste período/filtro.' }}</span>
                    </div>

                    <template v-else>
                        <div v-for="(note, index) in paginatedNotes" :key="note.normalized_key" class="grid-row zebra-row" :class="[themeStore.currentMode === 'light' ? 'grid-row-light' : 'grid-row-dark', 'grid-fiscal-layout', {'opacity-60': currentTab === 'archived'}]">
                            <div class="cell center">
                                <v-checkbox-btn v-model="selectedPending" :value="note.normalized_key" density="compact" color="error" class="chk-fixed"></v-checkbox-btn>
                            </div>
                            <div class="cell center">
                                <v-icon v-if="note.source === 'api'" color="warning" size="20">mdi-cloud-download-outline</v-icon>
                                <v-icon v-else :color="getIconColor(note)" size="20">mdi-file-document-outline</v-icon>
                            </div>
                            <div class="cell"><span class="list-text-10 font-weight-bold text-grey-darken-1">{{ getCompanyName(note.cnpj_destinatario) }}</span></div>

                            <div class="cell">
                                <div class="text-truncate list-text-10 font-weight-bold" :title="note.emitente_nome">{{ note.emitente_nome || 'Emitente Desconhecido' }}</div>
                            </div>

                            <div class="cell d-flex align-center justify-space-between">
                                <span class="text-truncate list-text-10 opacity-70 font-mono select-all flex-grow-1" :title="note.chave">{{ note.chave }}</span>
                                <v-btn
                                    icon
                                    variant="text"
                                    size="x-small"
                                    color="grey"
                                    class="ml-2 flex-shrink-0"
                                    @click.stop="copyToClipboard(note.chave)"
                                    title="Copiar Chave"
                                >
                                    <v-icon size="14">mdi-content-copy</v-icon>
                                </v-btn>
                            </div>

                            <div class="cell center"><span class="list-text-10 font-mono">{{ formatDate(note.data_emissao) }}</span></div>
                            <div class="cell center">
                                <span v-if="note.status_processamento === 'contas_a_pagar_gerado'" class="solid-chip chip-success">
                                    <v-icon start size="10">mdi-check-all</v-icon> Lançado
                                </span>
                                <v-tooltip v-else-if="note.source === 'api'" text="Clique para Confirmar ou Rejeitar" location="top" content-class="tooltip-custom">
                                    <template v-slot:activator="{ props }">
                                        <span v-bind="props" class="solid-chip chip-danger cursor-pointer hover:opacity-80" @click="openManifestModal(note)">NÃO INFORMADO</span>
                                    </template>
                                </v-tooltip>
                                <span v-else class="solid-chip" :class="getManifestChipClass(note)">{{ getManifestLabel(note) }}</span>
                            </div>
                            <div class="cell right"><span class="list-text-10 font-mono font-weight-black">{{ formatCurrency(note.valor) }}</span></div>
                            <div class="cell center">
                                <div class="actions-inline" :class="note.source === 'api' ? 'opacity-30 pointer-events-none' : ''">

                                    <v-tooltip v-if="note.status_processamento === 'contas_a_pagar_gerado'" text="Estornar Lançamento" location="top" content-class="tooltip-custom">
                                        <template v-slot:activator="{ props }">
                                            <v-btn v-bind="props" icon size="small" color="error" variant="flat" class="action-btn" @click.stop="revertLaunch(note)">
                                                <v-icon size="16" color="white">mdi-cash-refund</v-icon>
                                            </v-btn>
                                        </template>
                                    </v-tooltip>
                                    <v-tooltip v-else text="Lançar no Financeiro" location="top" content-class="tooltip-custom">
                                        <template v-slot:activator="{ props }">
                                            <v-btn v-bind="props" icon size="small" class="action-btn action-revert" @click.stop="openPayableModal(note)" :disabled="!canLaunchFinance(note)">
                                                 <v-icon size="16">mdi-cash-register</v-icon>
                                            </v-btn>
                                        </template>
                                    </v-tooltip>

                                    <v-tooltip text="Visualizar DANFE" location="top" content-class="tooltip-custom">
                                        <template v-slot:activator="{ props }">
                                            <v-btn v-bind="props" icon size="small" class="action-btn action-edit" @click.stop="openDanfeModal(note)" :loading="pdfLoading === note.chave">
                                                <v-icon size="16">{{ isManifested(note) ? 'mdi-file-document-check' : 'mdi-eye' }}</v-icon>
                                            </v-btn>
                                        </template>
                                    </v-tooltip>

                                    <v-tooltip text="Baixar XML" location="top" content-class="tooltip-custom">
                                        <template v-slot:activator="{ props }">
                                            <v-btn v-bind="props" icon size="small" class="action-btn bg-indigo-lighten-1 text-white" @click.stop="downloadXml(note)">
                                                <v-icon size="16">mdi-download</v-icon>
                                            </v-btn>
                                        </template>
                                    </v-tooltip>

                                    <v-menu location="bottom end">
                                        <template v-slot:activator="{ props }">
                                            <v-btn v-bind="props" icon size="small" class="action-btn bg-success text-white">
                                                <v-icon size="18">mdi-chevron-down</v-icon>
                                            </v-btn>
                                        </template>
                                        <v-list density="compact">
                                            <v-list-item @click="archiveNote(note)" v-if="currentTab === 'active'">
                                                <template v-slot:prepend><v-icon size="18" class="mr-2">mdi-archive</v-icon></template>
                                                <v-list-item-title>Arquivar</v-list-item-title>
                                            </v-list-item>
                                            <v-list-item @click="unarchiveNote(note)" v-else>
                                                <template v-slot:prepend><v-icon size="18" class="mr-2">mdi-archive-refresh</v-icon></template>
                                                <v-list-item-title>Desarquivar</v-list-item-title>
                                            </v-list-item>
                                            <v-list-item @click="deleteNote(note)" class="text-error">
                                                <template v-slot:prepend><v-icon size="18" class="mr-2" color="error">mdi-close</v-icon></template>
                                                <v-list-item-title>Excluir</v-list-item-title>
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
               <div v-if="selectedPending.length > 0" class="absolute-bottom-center pa-4 z-50 w-100 d-flex justify-center">
                   <v-card elevation="8" class="rounded-0 bg-grey-darken-4 text-white pl-6 pr-2 py-2 d-flex align-center gap-4 border border-grey-darken-3" style="border-radius: 50px !important;">
                       <span class="font-weight-bold text-caption">{{ selectedPending.length }} itens selecionados</span>
                       <v-divider vertical class="bg-white opacity-20 my-1"></v-divider>
                       <v-btn color="success" variant="flat" class="text-none font-weight-bold rounded-pill" :loading="bulkLoading" @click="confirmSelectedNotes" height="32">
                           <v-icon start size="16">mdi-check-all</v-icon> Confirmar
                       </v-btn>
                       <v-btn color="warning" variant="flat" class="text-none font-weight-bold rounded-pill" @click="archiveSelectedNotes" height="32">
                           <v-icon start size="16">mdi-archive</v-icon> Arquivar
                       </v-btn>
                       <v-btn icon="mdi-close" size="small" variant="text" color="grey" @click="selectedPending = []"></v-btn>
                   </v-card>
               </div>
           </v-slide-y-reverse-transition>

            <div class="flex-shrink-0 border-t px-4 py-2 d-flex align-center justify-space-between bg-white" v-if="pageCount > 1">
                <div class="text-caption text-grey">Página {{ page }} de {{ pageCount }}</div>
                <v-pagination v-model="page" :length="pageCount" :total-visible="5" density="compact" active-color="primary" variant="tonal" size="small"></v-pagination>
            </div>
        </div>
    </div>

    <v-dialog v-model="launchSuccessModal.show" max-width="500">
        <v-card class="rounded-lg text-center pa-6">
            <v-icon size="64" color="success" class="mb-4">mdi-check-circle-outline</v-icon>
            <h3 class="text-h6 font-weight-black mb-2">Lançamento Realizado!</h3>
            <p class="text-body-2 text-grey mb-6">
                O documento fiscal foi processado e gerou <strong>{{ launchSuccessModal.payloads.length }}</strong> registros no contas a pagar.
            </p>
            <v-btn block color="primary" variant="flat" size="large" class="font-weight-bold" @click="launchSuccessModal.show = false">
                OK, Entendido
            </v-btn>
        </v-card>
    </v-dialog>

    <v-dialog v-model="manifestModal.show" max-width="400">
        <v-card class="rounded-0 overflow-hidden">
            <div class="pa-4 bg-grey-lighten-4 border-b">
                <div class="text-subtitle-2 font-weight-black text-uppercase text-grey-darken-3">Ação na Nota Pendente</div>
                <div class="text-caption text-grey-darken-1">{{ manifestModal.note?.emitente_nome || manifestModal.note?.emitente_nome_razao_social }}</div>
                <div class="text-[10px] font-mono mt-1 text-grey">{{ manifestModal.note?.chave || manifestModal.note?.chave_acesso }}</div>
            </div>
            <div class="pa-4 d-flex flex-column gap-3">
                <v-btn block color="success" variant="flat" height="45" class="rounded-0 font-weight-bold text-body-2" @click="manifestNote(manifestModal.note, 'confirmacao', manifestModal.note.source === 'api'); manifestModal.show = false">
                    <v-icon start>mdi-check</v-icon> Confirmar Recebimento
                </v-btn>
                <div class="text-center text-caption text-grey my-1">OU</div>
                <v-btn block color="error" variant="flat" height="45" class="rounded-0 font-weight-bold text-body-2" @click="archiveNote(manifestModal.note, true); manifestModal.show = false">
                    <v-icon start>mdi-close</v-icon> Rejeitar / Desconhecer
                </v-btn>
            </div>
        </v-card>
    </v-dialog>

    <CertificateUploadModal :show="certModal.show" :companies="companies" :initial-cnpj="activeCompany?.cnpj" :loading="uploading" @update:show="certModal.show = $event" @close="certModal.show = false" @upload="handleCertUpload" />

    <v-dialog v-model="payableModal.show" max-width="1100" persistent scrim="black opacity-80" scrollable>
        <v-card class="rounded-0 bg-white d-flex flex-column" height="750">
             <div class="flex-grow-1 d-flex overflow-hidden" style="max-height: calc(100% - 64px);">
                <div class="bg-grey-lighten-5 border-r border-opacity-10 d-flex flex-column overflow-y-auto" style="width: 320px; flex-shrink: 0;">
                    <div class="pa-6 border-b border-opacity-10">
                        <div class="d-flex align-center gap-3 mb-4">
                            <div class="icon-box rounded-lg pa-3 bg-white border shadow-sm">
                                <v-icon color="primary" size="24">mdi-file-document-outline</v-icon>
                            </div>
                            <div>
                                <div class="text-caption font-weight-bold text-uppercase text-grey-darken-1">DOCUMENTO FISCAL</div>
                                <div class="text-body-2 font-weight-black">Detalhes da NFe</div>
                            </div>
                        </div>
                        <div class="d-flex flex-column gap-4">
                            <div>
                                <label class="text-caption font-weight-bold text-uppercase text-grey mb-1 d-block">Chave</label>
                                <div class="text-caption font-mono bg-white px-2 py-1 rounded border text-wrap break-all lh-1">{{ payableModal.note?.chave }}</div>
                            </div>
                            <div>
                                <label class="text-caption font-weight-bold text-uppercase text-grey mb-1 d-block">Emitente</label>
                                <div class="text-caption font-weight-bold">{{ payableModal.note?.emitente_nome }}</div>
                            </div>
                            <div>
                                <label class="text-caption font-weight-bold text-uppercase text-grey mb-1 d-block">Valor Total</label>
                                <div class="text-h6 font-weight-black text-success">{{ formatCurrency(payableModal.note?.valor) }}</div>
                            </div>
                        </div>
                    </div>
                    <div class="pa-4 text-center text-caption text-grey">Itens não carregados (Futuro)</div>
                </div>

                <div class="flex-grow-1 d-flex flex-column bg-white overflow-hidden">
                    <div class="px-8 py-5 border-b d-flex justify-space-between align-center flex-shrink-0">
                        <div>
                            <h3 class="text-h6 font-weight-bold">Lançamento Financeiro</h3>
                            <p class="text-caption text-grey-darken-1">Configure o parcelamento e vincule a empresa.</p>
                        </div>
                        <v-btn icon="mdi-close" variant="text" @click="payableModal.show = false"></v-btn>
                    </div>

                    <div class="px-8 py-6 flex-grow-1 overflow-y-auto custom-scroll">
                        <v-form @submit.prevent="confirmPayableLaunch">
                            <v-row dense>
                                <v-col cols="12">
                                     <v-autocomplete label="Vincular Empresa (Loja)" v-model="payableForm.company_id" :items="companies" item-title="name" item-value="id" variant="outlined" density="compact" color="primary" hint="Quem está pagando esta conta?" persistent-hint></v-autocomplete>
                                </v-col>
                                <v-col cols="12">
                                    <v-text-field label="Descrição Principal" v-model="payableForm.description" variant="outlined" density="compact"></v-text-field>
                                </v-col>
                                <v-col cols="4"><v-text-field label="Valor Total" v-model.number="payableForm.value" type="number" variant="outlined" density="compact" prefix="R$"></v-text-field></v-col>
                                <v-col cols="4"><v-text-field label="Data Base" v-model="payableForm.dueDate" type="date" variant="outlined" density="compact"></v-text-field></v-col>
                                <v-col cols="4">
                                     <v-select label="Parcelas" v-model="payableForm.installments" :items="[1,2,3,4,5,6,10,12,24]" variant="outlined" density="compact" @update:model-value="recalcInstallments"></v-select>
                                </v-col>
                                <v-col cols="12">
                                     <v-autocomplete label="Plano de Contas" v-model="payableForm.chart_of_accounts_id" :items="chartOfAccounts" item-title="name" item-value="id" variant="outlined" density="compact" color="primary" :rules="[(v) => !!v || 'Plano de Contas é obrigatório']"></v-autocomplete>
                                </v-col>
                                <v-col cols="12">
                                    <v-textarea label="Observações" v-model="payableForm.obs" rows="1" variant="outlined" density="compact" auto-grow></v-textarea>
                                </v-col>
                            </v-row>

                            <v-divider class="my-4"></v-divider>

                            <div class="d-flex justify-space-between align-center mb-2">
                                <span class="text-subtitle-2 font-weight-bold">Parcelas Geradas</span>
                                <v-btn size="small" variant="text" color="primary" @click="applyStatusToAll('Pago')">Marcar todas como Paga</v-btn>
                            </div>

                            <div class="border rounded overflow-hidden">
                                <div class="d-flex bg-grey-lighten-4 py-2 px-4 text-caption font-weight-bold">
                                    <div style="width: 40px" class="text-center">#</div>
                                    <div style="width: 140px">Vencimento</div>
                                    <div class="flex-grow-1">Valor</div>
                                    <div style="width: 160px">Status</div>
                                </div>
                                <div v-for="(inst, idx) in payableForm.customInstallments" :key="idx" class="d-flex border-t py-2 px-4 align-center hover:bg-grey-lighten-5">
                                    <div style="width: 40px" class="text-center text-caption font-weight-bold">{{ idx + 1 }}</div>
                                    <div style="width: 140px" class="mr-4">
                                        <input type="date" v-model="inst.date" class="clean-input border rounded px-2 py-1" />
                                    </div>
                                    <div class="flex-grow-1 mr-4">
                                        <input type="number" v-model.number="inst.value" class="clean-input border rounded px-2 py-1 text-right font-mono" step="0.01" />
                                    </div>
                                    <div style="width: 160px">
                                        <select v-model="inst.status" class="clean-input border rounded px-2 py-1" :class="inst.status === 'Pago' ? 'text-success font-weight-bold' : ''">
                                            <option value="Em Aberto">Em Aberto</option>
                                            <option value="Pago">Pago</option>
                                        </select>
                                    </div>
                                </div>
                            </div>
                        </v-form>
                    </div>
                </div>
            </div>
            <div class="px-8 py-4 border-t d-flex justify-end gap-3 flex-shrink-0 bg-grey-lighten-5">
                <v-btn variant="outlined" class="btn-rect" height="40" @click="payableModal.show = false">Cancelar</v-btn>
                <v-btn color="success" variant="flat" class="btn-rect px-6 font-weight-black" height="40" :loading="payableModal.loading" @click="confirmPayableLaunch">
                    <v-icon start>mdi-check</v-icon> Confirmar Lançamento
                </v-btn>
            </div>
        </v-card>
    </v-dialog>

    <v-dialog v-model="danfeWarningModal.show" max-width="450">
        <v-card class="rounded-lg pa-4">
            <div class="d-flex flex-column align-center text-center">
                <v-icon size="56" color="warning" class="mb-3">mdi-file-alert-outline</v-icon>
                <h3 class="text-h6 font-weight-black">XML Oficial Indisponível</h3>
                <p class="text-body-2 text-grey-darken-1 mt-2 mb-4">
                    Ainda não possuímos o arquivo XML completo desta nota. Isso acontece quando a nota foi apenas manifestada mas o download na SEFAZ ainda não ocorreu.
                </p>
                <v-alert density="compact" type="info" variant="tonal" class="text-caption text-left w-100 mb-4">
                    Tente sincronizar novamente ou aguarde a liberação do documento pela Receita.
                </v-alert>
                <div class="d-flex gap-2 w-100">
                     <v-btn variant="text" block class="flex-1" @click="danfeWarningModal.show = false">Fechar</v-btn>
                     <v-btn color="primary" variant="flat" block class="flex-1 font-weight-bold" @click="syncNotesFromSefaz(); danfeWarningModal.show = false">Tentar Sincronizar</v-btn>
                </div>
            </div>
        </v-card>
    </v-dialog>

    <v-dialog v-model="danfeModal.show" fullscreen transition="dialog-bottom-transition">
      <v-card class="bg-grey-lighten-3 d-flex flex-row overflow-hidden rounded-0">
        <div class="bg-white border-r d-flex flex-column" style="width: 320px; height: 100vh;">
            <div class="pa-6 border-b">
                <div class="d-flex align-center gap-3 mb-4">
                    <div class="icon-box rounded-lg pa-3" :class="danfeModal.isPreview ? 'bg-amber-lighten-5 text-amber-darken-3' : 'bg-blue-lighten-5 text-blue-darken-3'">
                        <v-icon size="24">{{ danfeModal.isPreview ? 'mdi-file-eye' : 'mdi-file-check' }}</v-icon>
                    </div>
                    <div>
                        <div class="text-overline font-weight-bold lh-1 mb-1 text-grey">{{ danfeModal.isPreview ? 'Modo Prévia' : 'Documento Fiscal' }}</div>
                        <h3 class="text-subtitle-1 font-weight-black lh-1">{{ danfeModal.note?.emitente_nome?.substring(0, 15) }}...</h3>
                    </div>
                </div>

                <div v-if="danfeModal.isPreview" class="bg-amber-lighten-5 text-amber-darken-4 pa-3 rounded-lg border border-amber-lighten-4 mb-2">
                    <div class="d-flex align-center gap-2 mb-1">
                        <v-icon size="18">mdi-alert-decagram-outline</v-icon>
                        <span class="font-weight-black text-caption text-uppercase">Sem Validade Fiscal</span>
                    </div>
                    <p class="text-caption font-weight-medium lh-1-4 mb-0">Simulação para conferência.</p>
                </div>
            </div>

            <div class="pa-6 flex-grow-1">
                <div class="mb-4">
                    <label class="text-caption font-weight-bold text-uppercase d-block mb-1 text-grey">Chave</label>
                    <div class="font-mono text-caption bg-grey-lighten-5 pa-2 border rounded break-all">{{ danfeModal.note?.chave }}</div>
                </div>
                <v-btn block color="primary" class="btn-rect" @click="openDanfeModal(danfeModal.note, false)" :loading="pdfLoading === danfeModal.note?.chave">Recarregar XML</v-btn>
            </div>
        </div>
        <div class="flex-grow-1 d-flex flex-column h-screen">
            <div class="bg-white border-b px-6 py-3 d-flex justify-space-between align-center shadow-sm z-10">
                <div class="text-body-2 font-weight-bold">Visualizador</div>
                <v-btn icon variant="text" @click="danfeModal.show = false"><v-icon>mdi-close</v-icon></v-btn>
            </div>
            <div class="flex-grow-1 bg-grey-lighten-3 d-flex justify-center align-center relative overflow-hidden">
                <div v-if="pdfLoading === danfeModal.note?.chave" class="text-center">
                    <v-progress-circular indeterminate color="primary" size="64"></v-progress-circular>
                </div>
                <iframe v-else :src="danfeModal.url" class="pdf-iframe shadow-lg" frameborder="0" style="width: 100%; height: 100%;"></iframe>
            </div>
        </div>
      </v-card>
    </v-dialog>

    <v-dialog v-model="showLogs" max-width="1200" scrollable>
        <v-card class="bg-grey-darken-4 text-grey-lighten-4 rounded-xl border border-grey-darken-3 shadow-lg d-flex flex-row overflow-hidden" style="height: 700px;">
            <div class="bg-grey-darken-4 border-r border-grey-darken-3 d-flex flex-column pa-4" style="width: 250px;">
                <div class="text-overline font-weight-bold text-grey-lighten-1 mb-4 d-flex align-center gap-2">
                    <v-icon size="16">mdi-poll</v-icon> ESTATÍSTICAS
                </div>
                <div class="d-flex flex-column gap-2 mb-6">
                    <div class="d-flex justify-space-between align-center pa-2 rounded hover:bg-grey-darken-3 cursor-pointer" @click="logFilter = 'ALL'" :class="{ 'bg-grey-darken-3': logFilter === 'ALL' }">
                        <span class="text-caption">Todos</span>
                        <v-chip size="x-small" color="grey">{{ systemLogs.length }}</v-chip>
                    </div>
                    <div class="d-flex justify-space-between align-center pa-2 rounded hover:bg-grey-darken-3 cursor-pointer" @click="logFilter = 'ERROR'" :class="{ 'bg-grey-darken-3': logFilter === 'ERROR' }">
                        <span class="text-caption text-red-lighten-2">Erros</span>
                        <v-chip size="x-small" color="red">{{ errorCount }}</v-chip>
                    </div>
                    <div class="d-flex justify-space-between align-center pa-2 rounded hover:bg-grey-darken-3 cursor-pointer" @click="logFilter = 'SUCCESS'" :class="{ 'bg-grey-darken-3': logFilter === 'SUCCESS' }">
                        <span class="text-caption text-green-lighten-2">Sucessos</span>
                        <v-chip size="x-small" color="green">{{ successCount }}</v-chip>
                    </div>
                </div>
                <v-spacer></v-spacer>
                <div class="text-caption text-grey-darken-1 text-center font-mono">MJ Monitor v2.1</div>
            </div>
            <div class="flex-grow-1 d-flex flex-column bg-black">
                <v-card-title class="d-flex justify-space-between align-center py-3 px-4 border-b border-grey-darken-3 bg-grey-darken-4">
                    <div class="d-flex align-center gap-2">
                        <v-icon color="green-accent-3" size="20">mdi-console-line</v-icon>
                        <span class="text-subtitle-2 font-weight-bold font-mono">System Terminal</span>
                    </div>
                    <div class="d-flex align-center gap-2">
                        <v-btn size="x-small" variant="text" color="grey-lighten-1" @click="copyAllLogs" prepend-icon="mdi-content-copy">Copiar Tudo</v-btn>
                        <v-btn size="x-small" variant="text" color="red-accent-2" @click="systemLogs = []" prepend-icon="mdi-delete-sweep">Limpar</v-btn>
                        <v-btn icon="mdi-close" variant="text" density="compact" color="grey" @click="showLogs = false"></v-btn>
                    </div>
                </v-card-title>
                <v-card-text class="pa-0 font-mono text-caption custom-scrollbar flex-grow-1" style="overflow-y: auto;">
                    <div v-if="filteredLogs.length === 0" class="d-flex flex-column align-center justify-center h-100 text-grey-darken-2">
                        <v-icon size="48" class="mb-2 opacity-20">mdi-console</v-icon>
                        <span class="opacity-50">Sem registros para exibir.</span>
                    </div>
                    <div v-for="(log, idx) in filteredLogs" :key="idx" class="log-entry pa-3 border-b border-grey-darken-4 hover:bg-grey-darken-4-lighten transition-colors relative group">
                        <div class="d-flex align-start gap-3">
                            <span class="text-grey-darken-1 select-none font-mono text-[10px] mt-0.5" style="min-width: 60px;">{{ log.time }}</span>
                            <div class="d-flex flex-column flex-grow-1" style="min-width: 0;">
                                <div class="d-flex align-center gap-2 flex-wrap">
                                    <v-chip size="x-small" :color="getLogChipColor(log.type)" label variant="flat" class="font-weight-bold px-1" style="height: 18px;">
                                        {{ log.type }}
                                    </v-chip>
                                    <span :class="getLogMessageColor(log.type)" class="text-break font-weight-medium">{{ log.message }}</span>
                                </div>
                            </div>
                        </div>
                    </div>
                </v-card-text>
            </div>
        </v-card>
    </v-dialog>

  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, reactive, computed, defineAsyncComponent, onUnmounted, watch } from 'vue';
import { sefazService } from '@/api/sefazApi';
import { supabase } from '@/api/supabase';
import { useAppStore } from '@/stores/app';
import { useThemeStore } from '@/stores/themeStore';
import { format, parseISO, addDays, addMonths, isAfter, differenceInSeconds, startOfMonth, endOfMonth, isWithinInterval, startOfWeek, endOfWeek, startOfYear, endOfYear, isSameDay } from 'date-fns';
import axios from 'axios';
import { DANFe } from 'node-sped-pdf';
import { PDFDocument, rgb, StandardFonts } from 'pdf-lib';

// --- FUNÇÕES UTILITÁRIAS ---
const formatCurrency = (val: any) => new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(Number(val)||0);
const formatCurrencyValue = (val: any) => new Intl.NumberFormat('pt-BR', { minimumFractionDigits: 2, maximumFractionDigits: 2 }).format(Number(val)||0);

// --- PROTEÇÃO DE DATA ROBUSTA ---
const formatDate = (d: string | Date | null | undefined) => {
    if (!d) return '-';
    try {
        if (d instanceof Date) return format(d, 'dd/MM/yy');
        return format(parseISO(d), 'dd/MM/yy');
    } catch (e) {
        return '-';
    }
};

const parseDateSafe = (dateStr: string) => {
    if(!dateStr) return new Date();
    const parts = dateStr.substring(0, 10).split('-');
    return new Date(Number(parts[0]), Number(parts[1]) - 1, Number(parts[2]), 12, 0, 0);
};
const getNoteKey = (note: any) => String(note?.chave || note?.chave_acesso || note?.xml_id || note?.xml_link || '');

const isManifested = (note: any) => {
    const s = String(note.situacao_manifestacao || '');
    return s === 'Confirmada' || s === 'Ciencia' || s === 'Autorizada';
};
const getManifestLabel = (note: any) => {
    if (note.source === 'api') return 'NÃO INFORMADO';
    const s = String(note.situacao_manifestacao || '');
    if (s === 'Confirmada' || s === 'Autorizada') return 'Confirmada';
    if (s === 'Ciencia') return 'Ciência';
    return 'Pendente';
};
const getManifestChipClass = (note: any) => {
    if (note.source === 'api') return 'chip-danger';
    const s = String(note.situacao_manifestacao || '').toLowerCase();
    if (s.includes('confirmada') || s.includes('autorizada')) return 'chip-warn';
    if (s.includes('ciencia')) return 'chip-info';
    return 'chip-grey';
};
const getIconColor = (n: any) => {
    const s = String(n.situacao_sefaz || '').toLowerCase();
    return s.includes('cancelada') ? 'error' : 'primary';
};

const copyToClipboard = (text: string) => {
    if (!text) return;
    navigator.clipboard.writeText(text);
    appStore.showSnackbar('Chave copiada!', 'success');
};

const CertificateUploadModal = defineAsyncComponent(() => import('@/components/admin/CertificateUploadModal.vue'));

const appStore = useAppStore();
const themeStore = useThemeStore();
const companies = ref<any[]>([]);
const activeCompany = ref<any>(null); // Null agora significa "Todas"
const notes = ref<any[]>([]);
const optimisticNotes = ref<any[]>([]);
const pendingNotes = ref<any[]>([]);
const pendingCount = ref(0);
const search = ref('');
const loadingCompanies = ref(false);
const loading = ref(false);
const syncing = ref(false);
const lastSyncTime = ref('--:--');
const currentTab = ref('active');
const statusFilter = ref('all');
const loadingManifest = ref<string | null>(null);
const pdfLoading = ref<string | null>(null);
const uploading = ref(false);
const xmlInput = ref<HTMLInputElement | null>(null);
const showLogs = ref(false);
const systemLogs = ref<any[]>([]);
const logFilter = ref('ALL');
const manifestModal = reactive({ show: false, note: null as any });
const chartOfAccounts = ref<any[]>([]);

// Filtros de Data
const currentPeriod = ref('month');
const customDateStart = ref('');
const customDateEnd = ref('');
const periodLabel = computed(() => {
    const map: any = { 'month': 'Este Mês', 'week': 'Esta Semana', 'today': 'Hoje', 'year': 'Este Ano', 'all': 'Todos', 'custom': 'Personalizado' };
    return map[currentPeriod.value] || 'Período';
});
const setPeriod = (val: string) => { currentPeriod.value = val; };

// Paginação
const page = ref(1);
const itemsPerPage = 50;

const SEFAZ_PROXY_URL = import.meta.env.VITE_SEFAZ_PROXY_URL || 'https://sefaz-proxy-dujl.onrender.com';

const statusOptions = [
    { label: 'Todos', value: 'all' },
    { label: 'Não Informado', value: 'uninformed' },
    { label: 'Confirmada', value: 'confirmed' },
    { label: 'Lançada', value: 'launched' }
];

const syncStatus = reactive({ show: false, state: 'idle', message: '', nextTry: '', minutesLeft: 0 });
const payableModal = reactive({ show: false, loading: false, note: null as any });
const payableForm = reactive({ description: '', value: 0, dueDate: '', obs: '', installments: 1, category: '', company_id: null as any, chart_of_accounts_id: null as any, customInstallments: [] as any[], status: 'Em Aberto' });
const certModal = reactive({ show: false });
const danfeModal = reactive({ show: false, note: null as any, url: '', isPreview: false, hasXml: false });
const danfeWarningModal = reactive({ show: false, note: null as any });
const launchSuccessModal = reactive({ show: false, payloads: [] as any[] });

const xmlFullStatus = reactive<Record<string, 'ok' | 'missing' | 'checking' | undefined>>({});

// Carrega status de XML do localStorage
const loadXmlCache = () => {
  try {
    const cached = localStorage.getItem('sefaz_xml_status_cache');
    if (cached) Object.assign(xmlFullStatus, JSON.parse(cached));
  } catch (e) { console.error(e); }
};

const saveXmlCache = () => {
  try {
    const toSave = Object.keys(xmlFullStatus).reduce((acc, key) => {
      if (xmlFullStatus[key] === 'ok') acc[key] = 'ok'; // ✅ só OK
      return acc;
    }, {} as any);
    localStorage.setItem('sefaz_xml_status_cache', JSON.stringify(toSave));
  } catch (e) { console.error(e); }
};

const canLaunchFinance = (note: any) => {
  if (!note || note.status_processamento === 'contas_a_pagar_gerado') return false;
  const key = getNoteKey(note);
  if (key && xmlFullStatus[key] === 'missing') return false;
  return true;
};

// --- MULTI EMPRESA ---
const getCompanyName = (cnpj: string) => {
    if (!cnpj) return '-';
    const clean = cnpj.replace(/\D/g, '');
    const comp = companies.value.find(c => c.cnpj.replace(/\D/g, '') === clean);
    return comp ? comp.name.substring(0, 15) : clean;
};

// --- LÓGICA DE XML CHECK ---
const checkFullXml = async (note: any) => {
  const key = getNoteKey(note);
  if (!key) return;

  // REMOVIDO O 'missing' DAQUI PARA PARAR DE IGNORAR AS NOTAS BUGADAS!
  if (xmlFullStatus[key] === 'ok' || xmlFullStatus[key] === 'checking') return;

  xmlFullStatus[key] = 'checking';
  const cnpj = (note.cnpj_destinatario || activeCompany.value?.cnpj)?.replace(/\D/g, '');
  if (!cnpj || !note?.chave) {
    xmlFullStatus[key] = 'missing'; saveXmlCache(); return;
  }

  try {
    const url = `${SEFAZ_PROXY_URL}/api/baixar-xml/${note.chave}?cnpj=${cnpj}`;
    const res = await axios.get(url, { responseType: 'text' });
    const ok = !!(res.data && res.data.includes('<infNFe') && res.data.includes('<det'));
    xmlFullStatus[key] = ok ? 'ok' : 'missing';
    saveXmlCache();
  } catch {
    xmlFullStatus[key] = 'missing'; saveXmlCache();
  }
};

// --- ESTADOS PARA AÇÃO EM MASSA ---
const selectedPending = ref<string[]>([]);
const bulkLoading = ref(false);

// --- SYNC TIMER LOGIC ---
const syncCountdownStr = ref('');
let countdownInterval: any = null;

const isSyncBlocked = computed(() => {
    if (!syncStatus.nextTry) return false;
    return isAfter(new Date(syncStatus.nextTry), new Date());
});

const startSyncCountdown = () => {
    if (countdownInterval) clearInterval(countdownInterval);
    countdownInterval = setInterval(() => {
        if (syncStatus.nextTry && isSyncBlocked.value) {
            const diff = differenceInSeconds(new Date(syncStatus.nextTry), new Date());
            const mins = Math.floor(diff / 60);
            const secs = diff % 60;
            syncCountdownStr.value = `${mins}m ${secs}s`;
        } else {
            syncCountdownStr.value = '';
        }
    }, 1000);
};

// --- COMPUTED: UNIFICAÇÃO & FILTRAGEM ---
const unifiedNotes = computed(() => {
    const apiNormalized = pendingNotes.value.map(n => ({
        ...n,
        normalized_key: `api-${n.chave_acesso}`,
        chave: n.chave_acesso,
        emitente_nome: n.emitente_nome_razao_social,
        valor: n.valor_nfe,
        cnpj_destinatario: n.cnpj,
        source: 'api',
        situacao_manifestacao: 'NaoInformado', // Flag interna
        status_processamento: 'pendente'
    }));

    const dbNormalized = notes.value.map(n => ({
        ...n,
        normalized_key: `db-${n.chave}`,
        source: 'db'
    }));

    let combined = [];
    if (currentTab.value === 'active') {
        const activeDb = dbNormalized.filter(n => n.status_processamento !== 'arquivado');
        combined = [...apiNormalized, ...activeDb];
    } else {
        combined = dbNormalized.filter(n => n.status_processamento === 'arquivado');
    }

    if (activeCompany.value) {
        combined = combined.filter(n => n.cnpj_destinatario === activeCompany.value.cnpj);
    }

    if (search.value) {
        const term = search.value.toLowerCase();
        combined = combined.filter(n =>
            (n.emitente_nome && String(n.emitente_nome).toLowerCase().includes(term)) ||
            (n.chave && String(n.chave).includes(term)) ||
            (n.valor && String(n.valor).includes(term))
        );
    }

    if (statusFilter.value && statusFilter.value !== 'all') {
        combined = combined.filter(n => {
            if (statusFilter.value === 'uninformed') return n.source === 'api';
            if (statusFilter.value === 'confirmed') return n.source === 'db' && (n.situacao_manifestacao === 'Confirmada' || n.situacao_manifestacao === 'Autorizada') && n.status_processamento !== 'contas_a_pagar_gerado';
            if (statusFilter.value === 'launched') return n.status_processamento === 'contas_a_pagar_gerado';
            return true;
        });
    }

    if (currentPeriod.value !== 'all') {
        const now = new Date();
        let start, end;

        if (currentPeriod.value === 'month') { start = startOfMonth(now); end = endOfMonth(now); }
        else if (currentPeriod.value === 'week') { start = startOfWeek(now); end = endOfWeek(now); }
        else if (currentPeriod.value === 'today') { start = now; end = now; }
        else if (currentPeriod.value === 'year') { start = startOfYear(now); end = endOfYear(now); }
        else if (currentPeriod.value === 'custom' && customDateStart.value && customDateEnd.value) {
             start = parseISO(customDateStart.value);
             end = parseISO(customDateEnd.value);
        }

        if (start && end) {
            combined = combined.filter(n => {
                const date = parseISO(n.data_emissao);
                if (currentPeriod.value === 'today') return isSameDay(date, now);
                return isWithinInterval(date, { start: start!, end: end! });
            });
        }
    }

    return combined.sort((a, b) => new Date(b.data_emissao).getTime() - new Date(a.data_emissao).getTime());
});

const pageCount = computed(() => Math.ceil(unifiedNotes.value.length / itemsPerPage));
const paginatedNotes = computed(() => {
    const start = (page.value - 1) * itemsPerPage;
    return unifiedNotes.value.slice(start, start + itemsPerPage);
});

const totalValue = computed(() => unifiedNotes.value.reduce((acc, note) => acc + (Number(note.valor) || 0), 0));

// --- SIMULAÇÃO DE PARCELAS ---
const recalcInstallments = () => {
    generateProjections(payableModal.note, null, true);
};

const applyStatusToAll = (newStatus: string) => {
    if (payableForm.customInstallments.length > 0) {
        payableForm.customInstallments.forEach(i => i.status = newStatus);
    }
};

// --- SISTEMA DE LOGS ---
const addLog = (type: 'INFO' | 'SUCCESS' | 'ERROR' | 'API' | 'WARNING', message: string, details?: any) => {
    if (!Array.isArray(systemLogs.value)) systemLogs.value = [];
    systemLogs.value.unshift({ time: new Date().toLocaleTimeString(), type, message, details: details ? JSON.stringify(details, null, 2) : null });
};
const getLogChipColor = (type: string) => {
    if (type === 'ERROR') return 'red-darken-1';
    if (type === 'WARNING') return 'orange-darken-3';
    if (type === 'SUCCESS') return 'green-darken-1';
    if (type === 'API') return 'blue-darken-1';
    return 'grey-darken-1';
};
const getLogMessageColor = (type: string) => {
    if (type === 'ERROR') return 'text-red-lighten-1';
    if (type === 'WARNING') return 'text-orange-lighten-2';
    if (type === 'SUCCESS') return 'text-green-lighten-1';
    return 'text-grey-lighten-3';
};
const copyAllLogs = () => {
    if (!systemLogs.value) return;
    const text = systemLogs.value.map(l => `[${l.time}] [${l.type}] ${l.message} ${l.details || ''}`).join('\n');
    navigator.clipboard.writeText(text);
    appStore.showSnackbar('Copiado!', 'success');
};
const filteredLogs = computed(() => {
    const logs = Array.isArray(systemLogs.value) ? systemLogs.value : [];
    if (logFilter.value === 'ALL') return logs;
    return logs.filter(l => l.type === logFilter.value);
});
const errorCount = computed(() => Array.isArray(systemLogs.value) ? systemLogs.value.filter(l => l.type === 'ERROR').length : 0);
const successCount = computed(() => Array.isArray(systemLogs.value) ? systemLogs.value.filter(l => l.type === 'SUCCESS').length : 0);

// --- API ACTIONS ---
const loadCompanies = async () => {
   loadingCompanies.value = true;
   try {
      const { data, error } = await supabase.from('companies').select('*');
      if (error) throw error;
      companies.value = data || [];

      fetchStoredNotes(null);
      fetchPendingNotesFromApi(null);

      const { data: charts } = await supabase.from('finance_chart_of_accounts').select('id, name').eq('type', 'Despesa').order('name');
      chartOfAccounts.value = charts || [];
   } catch (e) {
       addLog('ERROR', 'Falha ao carregar dados iniciais', e);
   } finally {
       loadingCompanies.value = false;
   }
};

const switchCompany = (company: any) => {
   activeCompany.value = company;
   optimisticNotes.value = [];
   const cnpj = company ? company.cnpj : null;
   if(cnpj) addLog('INFO', `Trocando empresa para ${company.name}`);
   else addLog('INFO', `Visualizando Todas as Lojas`);

   fetchStoredNotes(cnpj);
   fetchPendingNotesFromApi(cnpj);
};

const fetchStoredNotes = async (cnpj: string | null) => {
    loading.value = true;
    try {
        let query = supabase.from('dfe_entries').select('*').order('data_emissao', { ascending: true });
        if (cnpj) {
            query = query.eq('cnpj_destinatario', cnpj);
        }
        const { data, error } = await query;
        if (error) throw error;
        notes.value = (data || []).map(n => ({ ...n, xml_id: n.xml_link }));
        addLog('INFO', `Notas locais carregadas: ${notes.value.length}`);
    } catch (e: any) { addLog('ERROR', 'Erro ao carregar notas locais', e.message); }
    finally { loading.value = false; }
};

const fetchPendingNotesFromApi = async (cnpj: string | null) => {
    pendingNotes.value = [];
    const cnpjsToFetch = cnpj ? [cnpj] : companies.value.map(c => c.cnpj);

    for (const c of cnpjsToFetch) {
        try {
            const res = await axios.get(`${SEFAZ_PROXY_URL}/api/notas-sem-manifestacao`, {
                params: { cnpj: c.replace(/\D/g, ''), ambiente: 'producao', conclusiva: true }
            });
            const raw = res.data.data || [];
            const formatted = raw.map((n: any) => ({ ...n, cnpj: c }));
            pendingNotes.value.push(...formatted);
        } catch (e) {
            console.error(`Falha ao buscar pendentes para ${c}`);
        }
    }
    const existingKeys = new Set(notes.value.map(n => n.chave));
    pendingNotes.value = pendingNotes.value.filter((n: any) => !existingKeys.has(n.chave_acesso));
    pendingCount.value = pendingNotes.value.length;
};

// --- SYNC CORRIGIDO (SEQUENCIAL PARA MULTIPLAS LOJAS) ---
const syncNotesFromSefaz = async (forcedNsu?: number) => {
   if (isSyncBlocked.value) return appStore.showSnackbar(`Aguarde o tempo de bloqueio da SEFAZ.`, 'warning');

   const companiesToSync = activeCompany.value ? [activeCompany.value] : companies.value;
   if (companiesToSync.length === 0) return appStore.showSnackbar('Nenhuma empresa cadastrada ou disponível para sincronizar.', 'warning');

   syncStatus.show = false;
   syncing.value = true;

   let successCount = 0;
   let blockCount = 0;

   try {
       for (const company of companiesToSync) {
           const cnpj = company.cnpj;
           addLog('INFO', `Iniciando Sync SEFAZ para ${cnpj} (${company.name})`);

           try {
               let lastNsu = forcedNsu;
               if (lastNsu === undefined) {
                   const nsuKey = `sefaz_last_nsu_${cnpj.replace(/\D/g, '')}`;
                   const localNsu = localStorage.getItem(nsuKey);
                   lastNsu = localNsu ? parseInt(localNsu) : 0;
               }

               const syncRes = await axios.post(`${SEFAZ_PROXY_URL}/api/sincronizar-sefaz`, {
                   cnpj: cnpj,
                   last_nsu: lastNsu
               });

               if (syncRes.data.status === 'blocked') {
                   const waitMin = syncRes.data.wait_minutes || 60;
                   const nextTry = new Date(Date.now() + waitMin * 60000).toISOString();
                   if (!syncStatus.nextTry || nextTry > syncStatus.nextTry) {
                       syncStatus.nextTry = nextTry; // Pega o maior bloqueio
                   }
                   localStorage.setItem(`sefaz_last_nsu_${cnpj.replace(/\D/g, '')}` + '_block', nextTry);
                   blockCount++;
                   addLog('WARNING', `Sync bloqueado para ${company.name}`);
               } else {
                   successCount++;
                   addLog('SUCCESS', `Sync OK para ${company.name}`);
                   if (syncRes.data.ultimo_nsu) {
                       localStorage.setItem(`sefaz_last_nsu_${cnpj.replace(/\D/g, '')}`, syncRes.data.ultimo_nsu.toString());
                   }
               }
           } catch (err: any) {
               addLog('ERROR', `Erro ao sincronizar ${company.name}: ${err.message}`);
           }
       }

       if (blockCount > 0) appStore.showSnackbar(`${blockCount} lojas bloqueadas temporariamente pela SEFAZ.`, 'warning');
       if (successCount > 0) appStore.showSnackbar(`${successCount} lojas sincronizadas com sucesso!`, 'success');

       // Atualiza a lista geral
       await fetchStoredNotes(activeCompany.value ? activeCompany.value.cnpj : null);
       await fetchPendingNotesFromApi(activeCompany.value ? activeCompany.value.cnpj : null);
       lastSyncTime.value = format(new Date(), 'HH:mm');

   } catch (e: any) {
      addLog('ERROR', 'Erro geral no Sync', e.message);
      appStore.showSnackbar('Falha no processo de sincronização.', 'error');
   } finally {
      syncing.value = false;
   }
};

const openManifestModal = (note: any) => {
    manifestModal.note = note;
    manifestModal.show = true;
};

const manifestNote = async (note: any, tipo: 'ciencia' | 'confirmacao', fromPending: boolean = false, silent: boolean = false) => {
    const chaveParaManifestar = fromPending ? note.chave_acesso : note.chave;
    addLog('INFO', `Manifestando nota ${chaveParaManifestar} como ${tipo}`);

    if (!silent && !fromPending && !confirm(`Confirma ${tipo === 'ciencia' ? 'Ciência' : 'Confirmação'}?`)) return;

    loadingManifest.value = chaveParaManifestar;

    try {
        const cnpjAlvo = fromPending ? (note.cnpj || activeCompany.value?.cnpj) : activeCompany.value?.cnpj;
        await axios.post(`${SEFAZ_PROXY_URL}/api/manifestar`, {
            chave: chaveParaManifestar,
            cnpj: cnpjAlvo,
            tipo: tipo
        });

        if (fromPending) {
             const dbEntry = {
                 chave: note.chave_acesso,
                 emitente_nome: note.emitente_nome_razao_social || 'Emitente Desconhecido',
                 emitente_cnpj: note.emitente_cnpj,
                 cnpj_destinatario: cnpjAlvo,
                 valor: note.valor_nfe,
                 data_emissao: note.data_emissao,
                 situacao_manifestacao: tipo === 'ciencia' ? 'Ciencia' : 'Confirmada',
                 situacao_sefaz: 'Ciência Realizada',
                 status_processamento: 'aguardando_xml',
                 xml_link: null
             };
             const { error: dbError } = await supabase.from('dfe_entries').upsert(dbEntry, { onConflict: 'chave' });
             if (dbError) throw dbError;

             notes.value.unshift(dbEntry);
             pendingNotes.value = pendingNotes.value.filter(n => n.chave_acesso !== chaveParaManifestar);
             pendingCount.value = pendingNotes.value.length;

             appStore.showSnackbar('Nota salva e movida para Base Local!', 'success');
        } else {
             const newStatus = tipo === 'confirmacao' ? 'Confirmada' : 'Ciencia';
             await supabase.from('dfe_entries').update({ situacao_manifestacao: newStatus }).eq('chave', note.chave);
             note.situacao_manifestacao = newStatus;
             if(!silent) appStore.showSnackbar('Status salvo com sucesso.', 'success');
        }
    } catch (e: any) {
        addLog('ERROR', `Falha manifestação: ${e.message}`);
        if(!silent) appStore.showSnackbar('Erro: ' + e.message, 'error');
    } finally {
        loadingManifest.value = null;
    }
};

const archiveNote = async (note: any, fromPending: boolean = false) => {
    if (!fromPending && !confirm('Deseja arquivar esta nota? Ela sairá da lista principal.')) return;
    try {
        if (fromPending) {
             const dbEntry = {
                 chave: note.chave_acesso,
                 emitente_nome: note.emitente_nome_razao_social || 'Emitente Desconhecido',
                 emitente_cnpj: note.emitente_cnpj,
                 cnpj_destinatario: note.cnpj || activeCompany.value?.cnpj,
                 valor: note.valor_nfe,
                 data_emissao: note.data_emissao,
                 situacao_manifestacao: 'Sem Manifestacao',
                 situacao_sefaz: 'Arquivada Localmente',
                 status_processamento: 'arquivado',
                 xml_link: null
             };
             const { error } = await supabase.from('dfe_entries').upsert(dbEntry, { onConflict: 'chave' });
             if (error) throw error;

             pendingNotes.value = pendingNotes.value.filter(n => n.chave_acesso !== note.chave_acesso);
             pendingCount.value = pendingNotes.value.length;
             notes.value.push(dbEntry);
        } else {
            const { error } = await supabase.from('dfe_entries').update({ status_processamento: 'arquivado' }).eq('chave', note.chave);
            if (error) throw error;
            note.status_processamento = 'arquivado';
        }
        appStore.showSnackbar('Nota arquivada com sucesso.', 'success');
    } catch (e: any) {
        appStore.showSnackbar('Erro ao arquivar: ' + e.message, 'error');
    }
};

const archiveSelectedNotes = async () => {
    if (selectedPending.value.length === 0) return;
    if (!confirm(`Deseja arquivar ${selectedPending.value.length} notas?`)) return;
    bulkLoading.value = true;
    let successCount = 0;
    try {
        for (const chave of selectedPending.value) {
            const note = pendingNotes.value.find(n => n.chave_acesso === chave);
            if (note) {
                try { await archiveNote(note, true); successCount++; } catch (err) { console.error(`Erro ao arquivar nota ${chave}`, err); }
            }
        }
        selectedPending.value = [];
        appStore.showSnackbar(`${successCount} notas arquivadas!`, 'success');
    } catch (e: any) {
        appStore.showSnackbar('Erro no processamento em lote: ' + e.message, 'error');
    } finally { bulkLoading.value = false; }
};

const unarchiveNote = async (note: any) => {
    if (!confirm('Desarquivar e retornar para a lista ativa?')) return;
    try {
        const { error } = await supabase.from('dfe_entries').update({ status_processamento: 'aguardando_xml' }).eq('chave', note.chave);
        if (error) throw error;
        note.status_processamento = 'aguardando_xml';
        appStore.showSnackbar('Nota desarquivada!', 'success');
    } catch (e: any) {
        appStore.showSnackbar('Erro: ' + e.message, 'error');
    }
};

const openPayableModal = async (note: any) => {
    if (note.status_processamento === 'contas_a_pagar_gerado') {
        appStore.showSnackbar('Esta nota já foi lançada no financeiro!', 'warning');
        return;
    }
    const cnpj = (note.cnpj_destinatario || activeCompany.value?.cnpj)?.replace(/\D/g, '');
    let xmlAvailable = !!(note.xml_link || note.xml_id);
    if (!xmlAvailable && note.chave && cnpj) {
         try {
             const url = `${SEFAZ_PROXY_URL}/api/baixar-xml/${note.chave}?cnpj=${cnpj}`;
             const res = await axios.get(url, { responseType: 'text' });
             if (res.data && res.data.includes('<infNFe') && res.data.includes('<det')) xmlAvailable = true;
         } catch (e) { xmlAvailable = false; }
    }
    const key = getNoteKey(note);
    if (!xmlAvailable) {
      if (key) xmlFullStatus[key] = 'missing';
      appStore.showSnackbar('Aguardando liberação do XML completo pela SEFAZ. Tente baixar o XML primeiro.', 'warning');
      return;
    }
    if (key) xmlFullStatus[key] = 'ok';

    payableModal.note = note;
    payableModal.loading = true;
    payableModal.show = true;
    payableForm.description = note.emitente_nome;
    payableForm.value = note.valor;
    payableForm.category = '';
    payableForm.installments = 1;
    payableForm.customInstallments = [];
    payableForm.obs = `Ref. NFe ${note.numero || note.chave.substring(25, 34)}`;
    payableForm.dueDate = format(addDays(parseISO(note.data_emissao || new Date().toISOString()), 30), 'yyyy-MM-dd');

    // Tenta encontrar empresa destino
    if (note.cnpj_destinatario) {
        const destClean = note.cnpj_destinatario.replace(/\D/g, '');
        const matched = companies.value.find(c => c.cnpj.replace(/\D/g, '') === destClean);
        if (matched) payableForm.company_id = matched.id;
    }

    // Default chart of account (first one)
    if (chartOfAccounts.value.length > 0) payableForm.chart_of_accounts_id = chartOfAccounts.value[0].id;

    try {
        const id = note.xml_link || note.xml_id || note.chave;
        if (id && cnpj) {
            const url = `${SEFAZ_PROXY_URL}/api/baixar-xml/${id}?cnpj=${cnpj}`;
            const response = await axios.get(url, { responseType: 'blob' });
            const xmlText = await response.data.text();
            const parser = new DOMParser();
            const xmlDoc = parser.parseFromString(xmlText, "text/xml");
            const dups = xmlDoc.getElementsByTagName("dup");
            if (dups && dups.length > 0) {
                const extractedInstallments = [];
                for (let i = 0; i < dups.length; i++) {
                    const el = dups[i];
                    const vDup = el.getElementsByTagName("vDup")[0]?.textContent;
                    const dVenc = el.getElementsByTagName("dVenc")[0]?.textContent;
                    const nDup = el.getElementsByTagName("nDup")[0]?.textContent;
                    if (vDup && dVenc) extractedInstallments.push({ number: nDup, value: Number(vDup), date: dVenc, status: 'Em Aberto' });
                }
                if (extractedInstallments.length > 0) {
                    payableForm.installments = extractedInstallments.length;
                    payableForm.customInstallments = extractedInstallments;
                    payableForm.dueDate = extractedInstallments[0].date;
                    appStore.showSnackbar(`${extractedInstallments.length} parcelas importadas do XML!`, 'success');
                }
            } else {
                generateProjections(note, null, true); // Gera padrão se não tiver no XML
            }
        }
    } catch (e) { console.error('Erro ao ler parcelas do XML:', e); generateProjections(note, null, true); }
    finally { payableModal.loading = false; }
};

const confirmPayableLaunch = async () => {
    if (!payableForm.chart_of_accounts_id) return appStore.showSnackbar('Selecione um Plano de Contas.', 'warning');
    if (!payableForm.company_id) return appStore.showSnackbar('Selecione uma Empresa.', 'warning');

    payableModal.loading = true;
    try {
        const note = payableModal.note;
        if (note.status_processamento === 'contas_a_pagar_gerado') throw new Error("Nota já lançada!");
        const payloads = [];

        // Usa as parcelas customizáveis (grid do modal) se existirem
        if (payableForm.customInstallments && payableForm.customInstallments.length > 0) {
             for (const parc of payableForm.customInstallments) {
                 // BUSCA FORNECEDOR (TENTA ENCONTRAR NA TABELA DE CUSTOMERS)
                 let supplier_id = null;
                 if (note.emitente_cnpj) {
                      const { data: sup } = await supabase.from('customers_mj').select('id').eq('cnpj', note.emitente_cnpj.replace(/\D/g,'')).maybeSingle();
                      supplier_id = sup?.id;
                 }

                 payloads.push({
                     description: `${payableForm.description || note.emitente_nome} (Parc. ${parc.number || 1})`,
                     entity_name: note.emitente_nome,
                     supplier_id: supplier_id,
                     value: parc.value,
                     due_date: parc.date,
                     status: parc.status === 'Pago' ? 'pago' : 'pendente',
                     chart_of_accounts_id: payableForm.chart_of_accounts_id,
                     notes: payableForm.obs,
                     origin_nfe_key: note.chave,
                     company_id: payableForm.company_id, // Salva o vinculo
                     payment_date: parc.status === 'Pago' ? new Date().toISOString().split('T')[0] : null
                 });
             }
        } else {
             await generateProjections(note, payloads);
        }

        const { error: financeError } = await supabase.from('finance_payables').insert(payloads);
        if (financeError) throw new Error('Erro no banco: ' + financeError.message);

        // Feedback Visual
        launchSuccessModal.payloads = payloads;
        launchSuccessModal.show = true;

        // CORREÇÃO CRÍTICA DO DATE E FALLBACK PARA UPDATE
        const nowIso = new Date().toISOString();
        let upError = null;

        try {
             // Tenta atualizar completo com data. Se launched_at não existe, cairá no catch.
             const { error } = await supabase
                .from('dfe_entries')
                .update({ status_processamento: 'contas_a_pagar_gerado', launched_at: nowIso })
                .eq('chave', note.chave);
             upError = error;
        } catch (err) {
             // Silenciosamente ignora erro no primeiro update
        }

        // Se deu erro no primeiro update (provavelmente launched_at inexistente), tenta apenas status
        if (upError || !upError /* tenta sempre o fallback se o primeiro falhou */) {
             // Na verdade, o supabase-js não lança throw no error, ele retorna error object.
             // Se error existe, tentamos o fallback.
             if(upError) {
                 console.warn("Falha ao atualizar data (coluna inexistente?), tentando apenas status...");
                 const { error: retryError } = await supabase
                    .from('dfe_entries')
                    .update({ status_processamento: 'contas_a_pagar_gerado' })
                    .eq('chave', note.chave);

                 if (retryError) throw retryError;
             }
        }

        // Atualiza a fonte de verdade (notes.value)
        const sourceNote = notes.value.find(n => n.chave === note.chave);
        if (sourceNote) {
            sourceNote.status_processamento = 'contas_a_pagar_gerado';
            sourceNote.launched_at = nowIso;
        }

        // Atualiza o objeto local para refletir na UI imediatamente
        note.status_processamento = 'contas_a_pagar_gerado';
        note.launched_at = nowIso;

        payableModal.show = false;
    } catch (e: any) {
        console.error("Erro no lançamento:", e);
        const msg = e.message || (typeof e === 'object' ? JSON.stringify(e) : String(e));
        appStore.showSnackbar('Erro detalhado: ' + msg, 'error');
    } finally {
        payableModal.loading = false;
    }
};

const generateProjections = async (note: any, payloads: any[] | null, fillForm = false) => {
    const installmentsCount = Number(payableForm.installments);
    const totalValue = Number(payableForm.value);
    const installmentValue = Number((totalValue / installmentsCount).toFixed(2));
    const totalCalculated = installmentValue * installmentsCount;
    const diff = Number((totalValue - totalCalculated).toFixed(2));
    const baseDate = parseDateSafe(payableForm.dueDate);

    const generated = [];
    for (let i = 0; i < installmentsCount; i++) {
        const currentDueDate = addMonths(baseDate, i);
        const currentValue = (i === installmentsCount - 1) ? Number((installmentValue + diff).toFixed(2)) : installmentValue;

        const obj = {
            description: `${payableForm.description || note.emitente_nome} (${i + 1}/${installmentsCount})`,
            entity_name: note.emitente_nome,
            value: currentValue,
            due_date: format(currentDueDate, 'yyyy-MM-dd'),
            date: format(currentDueDate, 'yyyy-MM-dd'), // para o form
            number: i + 1, // para o form
            status: payableForm.status || 'Em Aberto',
            chart_of_accounts_id: payableForm.chart_of_accounts_id,
            notes: payableForm.obs,
            origin_nfe_key: note.chave,
            company_id: payableForm.company_id
        };
        generated.push(obj);
        if(payloads) payloads.push(obj);
    }

    if(fillForm) {
        payableForm.customInstallments = generated;
    }
};

const revertLaunch = async (note: any) => {
    if (!confirm('ATENÇÃO: Isso excluirá os lançamentos financeiros gerados para esta nota e resetará o status. Continuar?')) return;
    loadingManifest.value = note.chave;
    try {
        const { error: delError } = await supabase.from('finance_payables').delete().eq('origin_nfe_key', note.chave);
        if (delError) throw new Error('Erro ao excluir financeiro: ' + delError.message);
        const newStatus = note.situacao_manifestacao === 'Confirmada' ? 'aguardando_xml' : null;

        // CORREÇÃO: Garante que launched_at seja null explicitamente
        // Tenta update seguro (sem data se falhar)
        let upError = null;
        try {
             const { error } = await supabase.from('dfe_entries').update({ status_processamento: newStatus, launched_at: null }).eq('chave', note.chave);
             upError = error;
        } catch { }

        if (upError) {
             const { error: retry } = await supabase.from('dfe_entries').update({ status_processamento: newStatus }).eq('chave', note.chave);
             if (retry) throw new Error('Erro ao atualizar status: ' + retry.message);
        }

        // Atualiza a fonte de verdade
        const sourceNote = notes.value.find(n => n.chave === note.chave);
        if (sourceNote) {
            sourceNote.status_processamento = newStatus;
            sourceNote.launched_at = null;
        }

        note.status_processamento = newStatus;
        note.launched_at = null;
        appStore.showSnackbar('Lançamento estornado com sucesso!', 'success');
    } catch (e: any) { appStore.showSnackbar(e.message, 'error'); } finally { loadingManifest.value = null; }
};

const downloadXml = (note: any) => {
    const cnpj = (note.cnpj_destinatario || activeCompany.value?.cnpj)?.replace(/\D/g, '');
    if (!cnpj) { appStore.showSnackbar('Empresa não identificada.', 'error'); return; }
    if (note.xml_link || note.xml_id || note.chave) {
        const id = note.xml_link || note.xml_id || note.chave;
        const url = `${SEFAZ_PROXY_URL}/api/baixar-xml/${id}?cnpj=${cnpj}`;
        window.open(url, '_blank');
    } else { appStore.showSnackbar('XML indisponível (sem chave).', 'warning'); }
};

const openDanfeModal = async (note: any, forcePreview: boolean = false) => {
    if (note.source === 'api') {
        danfeWarningModal.show = true;
        danfeWarningModal.note = note;
        return;
    }

    if (danfeModal.url) URL.revokeObjectURL(danfeModal.url);
    danfeModal.url = '';
    danfeModal.note = note;
    danfeModal.show = true;
    pdfLoading.value = note.chave;

    try {
        const cnpj = (note.cnpj_destinatario || activeCompany.value?.cnpj)?.replace(/\D/g, '');
         const url = `${SEFAZ_PROXY_URL}/api/baixar-xml/${note.xml_link || note.xml_id || note.chave}?cnpj=${cnpj}`;
         const response = await axios.get(url, { responseType: 'text' });

         if (response.data && response.data.includes('<infNFe') && response.data.includes('<det')) {
             await renderLocalPdf(response.data, false);
             danfeModal.isPreview = false;
         } else {
             danfeModal.show = false;
             danfeWarningModal.show = true;
             danfeWarningModal.note = note;
         }
    } catch (e) {
        console.warn("Falha XML ou XML Incompleto", e);
        danfeModal.show = false;
        danfeWarningModal.show = true;
        danfeWarningModal.note = note;
    } finally { pdfLoading.value = null; }
};

const confirmPreviewDanfe = () => { danfeWarningModal.show = false; openDanfeModal(danfeWarningModal.note, true); };

const renderLocalPdf = async (xmlContent: string, isPreview: boolean) => {
    try {
        // Correção de data de fuso horário
        let sanitized = xmlContent.replace(/<dVenc>(\d{4}-\d{2}-\d{2})<\/dVenc>/g, '<dVenc>$1T12:00:00</dVenc>');
        sanitized = sanitized.replace(/<dhEmi>(\d{4}-\d{2}-\d{2})<\/dhEmi>/g, '<dhEmi>$1T12:00:00</dhEmi>');

        let pdfBytes;

        try {
            // TENTATIVA 1: Tenta gerar o DANFE normalmente
            const pdfResult = await DANFe({ xml: sanitized });
            pdfBytes = (pdfResult instanceof Blob) ? await pdfResult.arrayBuffer() : pdfResult;
        } catch (err) {
            console.warn("⚠️ Bug da biblioteca PDF detectado. Aplicando remoção cirúrgica com DOMParser...");

            // ESCUDO AVANÇADO: Usa o navegador para transformar o XML em objetos reais,
            // acha os nós problemáticos e deleta eles antes da biblioteca tentar ler.
            let fallbackXml = sanitized;
            try {
                const parser = new DOMParser();
                const xmlDoc = parser.parseFromString(sanitized, "text/xml");

                // Pega todos os vilões causadores do erro nDup
                const tagsToRemove = ["cobr", "dup", "fat"];

                tagsToRemove.forEach(tag => {
                    const nodes = xmlDoc.getElementsByTagName(tag);
                    // Remove de trás pra frente para não bugar a lista
                    for (let i = nodes.length - 1; i >= 0; i--) {
                        if (nodes[i] && nodes[i].parentNode) {
                            nodes[i].parentNode?.removeChild(nodes[i]);
                        }
                    }
                });

                // Transforma de volta em texto XML
                const serializer = new XMLSerializer();
                fallbackXml = serializer.serializeToString(xmlDoc);
            } catch (domErr) {
                console.error("Erro no DOMParser, usando fallback regex bruto", domErr);
                fallbackXml = sanitized.replace(/<cobr[\s\S]*?<\/cobr>/gi, '');
            }

            // TENTATIVA 2: Manda gerar o PDF com o XML limpo e livre das tags de cobrança
            const fallbackResult = await DANFe({ xml: fallbackXml });
            pdfBytes = (fallbackResult instanceof Blob) ? await fallbackResult.arrayBuffer() : fallbackResult;
        }

        const blob = new Blob([pdfBytes], { type: 'application/pdf' });
        danfeModal.url = URL.createObjectURL(blob);

    } catch (e: any) {
        console.error("Render failed completely", e);
        appStore.showSnackbar(`Erro ao processar PDF: ${e.message || 'Falha desconhecida'}`, 'error');
    }
};

const deleteNote = async (note: any) => {
    if(!confirm('Remover da lista?')) return;
    if (note.is_optimistic) { optimisticNotes.value = optimisticNotes.value.filter(n => n.chave !== note.chave); return; }
    await supabase.from('dfe_entries').delete().eq('chave', note.chave);
    notes.value = notes.value.filter(n => n.chave !== note.chave);
};

onMounted(() => { loadCompanies(); loadXmlCache(); });
onUnmounted(() => { if (danfeModal.url) URL.revokeObjectURL(danfeModal.url); if (countdownInterval) clearInterval(countdownInterval); });
</script>

<style scoped lang="scss">
.fiscal-layout { position: relative; }
.background-carousel-wrapper { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 0; opacity: 0.6; pointer-events: none; }
.background-overlay { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 1; background: radial-gradient(circle at center, rgba(15, 15, 19, 0.4), rgba(15, 15, 19, 0.98)); backdrop-filter: blur(8px); }
.z-10 { position: relative; z-index: 10; }

.bg-glass-dark { background: rgba(10,10,12,0.85); }
.bg-glass-header { background: rgba(20,20,24,0.55); backdrop-filter: blur(14px); }
.border-bottom-white-05 { border-bottom: 1px solid rgba(255,255,255,0.08); }

.btn-rect { border-radius: 0 !important; text-transform: none !important; font-weight: 800; }
.controls-bar { border: 1px solid rgba(0,0,0,0.08); border-radius: 0; padding: 10px; }
.controls-light { background: #ffffff; }
.controls-dark { background: rgba(30,30,35,0.55); backdrop-filter: blur(16px); border: 1px solid rgba(255,255,255,0.08); }
.search-wrap { height: 40px; border-radius: 0; padding: 0 12px; min-width: 300px; flex: 1; }
.search-light { background: #f4f6f8; border: 1px solid rgba(0,0,0,0.08); }
.search-dark { background: rgba(255,255,255,0.08); border: 1px solid rgba(255,255,255,0.10); }
.clean-input { border: none; outline: none; background: transparent; font-size: 12px; color: inherit; width: 100%; }

.kpi-bg-icon { position: absolute; right: -20px; bottom: -20px; opacity: 0.15; transform: rotate(-15deg); pointer-events: none; }
.kpi-bg-icon .v-icon { font-size: 100px; color: white; }
.kpi-card { border: 1px solid rgba(255,255,255,0.15); color: white; min-height: 110px; position: relative; overflow: hidden; }
.kpi-rect { border-radius: 0 !important; }
.bg-gradient-info { background: linear-gradient(135deg, #0288d1, #005b9f); }
.bg-gradient-green { background: linear-gradient(135deg, #2e7d32, #1b5e20); }
.bg-gradient-purple { background: linear-gradient(135deg, #7b1fa2, #4a148c); }
.bg-gradient-warning { background: linear-gradient(135deg, #FFB300, #F57F17); }
.bg-gradient-grey { background: linear-gradient(135deg, #757575, #424242); }
.kpi-label { font-size: 12px; font-weight: 900; letter-spacing: .2px; }
.kpi-value { font-size: 22px; font-weight: 900; letter-spacing: .2px; }

.grid-fiscal-layout {
  display: grid;
  width: 100%;

  /* Check | Tipo | Destino | Emissor | Chave | Emissao | Status | Valor | Acoes */
  grid-template-columns:
    50px
    60px
    140px
    minmax(140px, 0.7fr)   /* Emissor menor */
    1fr                    /* CHAVE pega o resto */
    90px
    110px
    110px
    190px;                 /* Ações fixa */
}



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
.chip-grey { background: #78909c; }
.chip-danger { background: #c62828; }

.actions-inline { display: flex; align-items: center; justify-content: center; gap: 8px; }
.action-btn { width: 32px !important; height: 32px !important; border-radius: 8px !important; color: #fff !important; }
.action-edit { background: #1976d2 !important; }
.action-revert { background: #009688 !important; }
.glass-card { background: rgba(30, 30, 35, 0.45); backdrop-filter: blur(25px); border: 1px solid rgba(255,255,255,0.08); }
.list-text-10 { font-size: 13px !important; line-height: 1.25 !important; }
.border-l-4-warning { border-left: 4px solid #F57F17 !important; }
.pdf-iframe { width: 100%; height: 100%; border: none; background: white; }
.icon-box { width: 40px; height: 40px; border-radius: 8px; display: flex; align-items: center; justify-content: center; }
.custom-scroll::-webkit-scrollbar { width: 8px; height: 8px; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.35); border-radius: 6px; }
.custom-scroll::-webkit-scrollbar-track { background: transparent; }

/* FIX TOOLTIPS */
:global(.tooltip-custom) {
    background-color: black !important;
    color: white !important;
    font-weight: bold;
    font-size: 11px;
}
</style>
