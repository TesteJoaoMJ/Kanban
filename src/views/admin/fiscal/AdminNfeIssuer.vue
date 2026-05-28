<template>
  <div
    class="issuer-layout font-sans fill-height d-flex flex-column relative overflow-hidden"
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
            <div class="d-flex flex-column" style="max-width: calc(100vw - 180px);">
                <div class="breadcrumb text-caption">
                    <span class="opacity-70">Fiscal</span>
                    <span class="mx-2 opacity-50">></span>
                    <span class="font-weight-bold">Emissor NFe 4.0</span>
                </div>
                <div class="text-h6 font-weight-black tracking-tight leading-none mt-1">
                    Saída e Faturamento
                </div>

                <div v-if="!isTenantLocked" class="d-flex align-center gap-3 mt-3 overflow-x-auto hide-scrollbar pb-1 w-100">
                    <v-btn
                        v-for="company in visibleCompanies"
                        :key="company.id"
                        size="x-small"
                        height="24"
                        :variant="activeCompany?.id === company.id ? 'flat' : 'tonal'"
                        :color="activeCompany?.id === company.id ? 'success' : 'grey'"
                        class="font-weight-bold btn-3d px-3 rounded-pill flex-shrink-0"
                        style="font-size: 10px; letter-spacing: 0.5px;"
                        @click="switchCompany(company)"
                    >
                        {{ company.trade_name || company.name }}
                    </v-btn>
                </div>

                <div v-else class="d-flex align-center gap-2 mt-3 overflow-hidden pb-1 w-100">
                    <v-chip
                        size="small"
                        color="success"
                        variant="flat"
                        class="font-weight-black chip-3d px-3"
                    >
                        <v-icon start size="14">mdi-lock-check</v-icon>
                        {{ activeCompany?.trade_name || activeCompany?.name || 'Empresa vinculada' }}
                    </v-chip>
                    <span class="text-caption font-weight-bold opacity-70">Acesso restrito à sua empresa</span>
                </div>
            </div>

            <div class="d-flex align-center gap-3">
                 <v-btn
                     color="primary"
                     variant="flat"
                     class="btn-3d px-6 font-weight-black text-uppercase letter-spacing-1 shadow-indigo-soft rounded"
                     height="40"
                     prepend-icon="mdi-plus"
                     @click="openNewNoteModal"
                 >
                     Nova NFe
                 </v-btn>
            </div>
        </div>

        <div class="px-6 pt-4 pb-0 flex-shrink-0">
            <v-row>
                <v-col cols="12" sm="6" md="3">
                    <v-card class="kpi-card kpi-rect bg-gradient-info hover-elevate py-3 px-4" v-ripple elevation="2">
                        <div class="kpi-bg-icon"><v-icon>mdi-xml</v-icon></div>
                        <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                            <div class="d-flex align-center" style="gap: 8px;">
                                <v-icon size="18" class="opacity-80">mdi-check-decagram</v-icon>
                                <span class="kpi-label">Autorizadas</span>
                            </div>
                            <div class="kpi-number-group my-1">
                                <span class="kpi-value">{{ notes.filter(n => n.status === 'AUTORIZADA').length }}</span>
                                <span class="text-caption ml-1 opacity-70">neste mês</span>
                            </div>
                        </div>
                    </v-card>
                </v-col>

                <v-col cols="12" sm="6" md="3">
                    <v-card class="kpi-card kpi-rect bg-gradient-warning hover-elevate py-3 px-4" v-ripple elevation="2" @click="filterStatus = 'RASCUNHO'">
                        <div class="kpi-bg-icon"><v-icon>mdi-pencil</v-icon></div>
                        <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                            <div class="d-flex align-center" style="gap: 8px;">
                                <v-icon size="18" class="opacity-80">mdi-pencil-circle</v-icon>
                                <span class="kpi-label">Rascunhos</span>
                            </div>
                            <div class="kpi-number-group my-1">
                                <span class="kpi-value">{{ notes.filter(n => n.status === 'RASCUNHO').length }}</span>
                                <span class="text-caption ml-1 opacity-70">pendentes</span>
                            </div>
                        </div>
                    </v-card>
                </v-col>

                <v-col cols="12" sm="6" md="3">
                    <v-card class="kpi-card kpi-rect bg-gradient-green hover-elevate py-3 px-4" v-ripple elevation="2">
                        <div class="kpi-bg-icon"><v-icon>mdi-cash-multiple</v-icon></div>
                        <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                            <div class="d-flex align-center" style="gap: 8px;">
                                <v-icon size="18" class="opacity-80">mdi-finance</v-icon>
                                <span class="kpi-label">Faturamento Total</span>
                            </div>
                            <div class="kpi-number-group my-1">
                                <span class="text-body-2 font-weight-medium mr-1 opacity-70">R$</span>
                                <span class="kpi-value text-h5">{{ formatCompact(totalValue) }}</span>
                            </div>
                        </div>
                    </v-card>
                </v-col>

                <v-col cols="12" sm="6" md="3">
                    <v-card class="kpi-card kpi-rect bg-gradient-purple hover-elevate py-3 px-4" v-ripple elevation="2">
                        <div class="kpi-bg-icon"><v-icon>mdi-domain</v-icon></div>
                        <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                            <div class="d-flex align-center" style="gap: 8px;">
                                <v-icon size="18" class="opacity-80">mdi-shield-check</v-icon>
                                <span class="kpi-label">Ambiente</span>
                            </div>
                            <div class="kpi-number-group my-1">
                                <span class="kpi-value text-h6">{{ activeCompany?.nfe_environment === 'producao' ? 'PRODUÇÃO' : 'HOMOLOGAÇÃO' }}</span>
                            </div>
                            <div class="kpi-footer mt-1 opacity-70 text-[10px]">Próx. Nota: {{ nextNfeNumber }}</div>
                        </div>
                    </v-card>
                </v-col>
            </v-row>
        </div>

        <div class="px-6 pt-4 pb-2 flex-shrink-0">
        <div
          class="controls-bar d-flex align-center justify-space-between flex-wrap gap-2"
          :class="themeStore.currentMode === 'light' ? 'controls-light' : 'controls-dark border-white-10 rounded-lg'"
        >
            <div class="d-flex align-center flex-wrap" style="gap: 10px; flex-grow: 1;">
                <v-menu location="bottom start" :close-on-content-click="false">
                    <template v-slot:activator="{ props }">
                        <v-btn
                            v-bind="props"
                            variant="outlined"
                            class="btn-3d font-weight-bold rounded"
                            height="40"
                            color="primary"
                            prepend-icon="mdi-calendar-range"
                        >
                            {{ periodLabel }} <v-icon end size="small">mdi-chevron-down</v-icon>
                        </v-btn>
                    </template>
                    <v-card min-width="280" class="rounded shadow-xl border-thin">
                        <v-list density="compact" nav>
                            <v-list-item @click="setPeriod('month')" :active="currentPeriod === 'month'" rounded="sm" color="primary"><v-list-item-title class="font-weight-bold">Este Mês</v-list-item-title></v-list-item>
                            <v-list-item @click="setPeriod('week')" :active="currentPeriod === 'week'" rounded="sm" color="primary"><v-list-item-title class="font-weight-bold">Esta Semana</v-list-item-title></v-list-item>
                            <v-list-item @click="setPeriod('today')" :active="currentPeriod === 'today'" rounded="sm" color="primary"><v-list-item-title class="font-weight-bold">Hoje</v-list-item-title></v-list-item>
                            <v-list-item @click="setPeriod('all')" :active="currentPeriod === 'all'" rounded="sm" color="primary"><v-list-item-title class="font-weight-bold">Todos</v-list-item-title></v-list-item>
                        </v-list>
                    </v-card>
                </v-menu>

                <div style="width: 180px;">
                    <v-select
                        v-model="filterStatus"
                        :items="['TODOS', 'AUTORIZADA', 'RASCUNHO', 'REJEITADA', 'CANCELADA', 'INUTILIZADA']"
                        variant="outlined"
                        density="compact"
                        hide-details
                        class="clean-input btn-3d rounded"
                        bg-color="transparent"
                        placeholder="Status"
                        :color="themeStore.currentMode === 'light' ? 'primary' : 'white'"
                    >
                        <template v-slot:prepend-inner><v-icon size="small" color="grey">mdi-filter-variant</v-icon></template>
                    </v-select>
                </div>

                <div class="search-wrap d-flex align-center rounded" :class="themeStore.currentMode === 'light' ? 'search-light' : 'search-dark'" style="max-width: 300px;">
                    <v-icon color="grey-darken-1">mdi-magnify</v-icon>
                    <input v-model="search" type="text" placeholder="Buscar destinatário, chave..." class="clean-input flex-grow-1" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'" />
                </div>
            </div>

            <div class="d-flex align-center">
                <v-menu location="bottom end" transition="slide-y-transition">
                    <template v-slot:activator="{ props }">
                        <v-btn
                            v-bind="props"
                            variant="tonal"
                            :color="themeStore.currentMode === 'light' ? 'grey-darken-3' : 'white'"
                            class="btn-3d font-weight-bold rounded"
                            height="40"
                            prepend-icon="mdi-dots-vertical"
                        >
                            Mais Ações
                        </v-btn>
                    </template>
                    <v-card min-width="240" class="rounded shadow-xl mt-1 border-thin" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-grey-darken-4'">
                        <v-list density="compact" nav :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-grey-darken-4'">
                            <v-list-item @click="showLogs = true" class="rounded-sm">
                                <template v-slot:prepend><v-icon size="18" :color="errorCount > 0 ? 'error' : 'grey'">mdi-console</v-icon></template>
                                <v-list-item-title class="font-weight-bold" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">Logs do Sistema</v-list-item-title>
                                <template v-slot:append v-if="errorCount > 0"><v-badge color="error" :content="errorCount" inline></v-badge></template>
                            </v-list-item>

                            <v-list-item @click="checkCertificate" class="rounded-sm">
                                <template v-slot:prepend><v-icon size="18" color="indigo">mdi-shield-check-outline</v-icon></template>
                                <v-list-item-title class="font-weight-bold" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">Status Sefaz</v-list-item-title>
                            </v-list-item>

                            <v-list-item @click="openNuvemNotesModal" class="rounded-sm">
                                <template v-slot:prepend><v-icon size="18" color="blue-grey">mdi-cloud-search</v-icon></template>
                                <v-list-item-title class="font-weight-bold" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">Histórico Nuvem</v-list-item-title>
                            </v-list-item>

                            <v-list-item @click="openInutModal" class="rounded-sm">
                                <template v-slot:prepend><v-icon size="18" color="warning">mdi-cancel</v-icon></template>
                                <v-list-item-title class="font-weight-bold" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">Inutilizar Número</v-list-item-title>
                            </v-list-item>

                            <v-list-item @click="openXmlImportModal" class="rounded-sm">
                                <template v-slot:prepend><v-icon size="18" color="success">mdi-file-upload-outline</v-icon></template>
                                <v-list-item-title class="font-weight-bold" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">Importar XML Único</v-list-item-title>
                            </v-list-item>

                            <v-divider class="my-1" :class="themeStore.currentMode === 'light' ? 'border-grey-lighten-2' : 'border-white-10'"></v-divider>

                            <v-list-item @click="openBulkDownloadModal" class="rounded-sm">
                                <template v-slot:prepend><v-icon size="18" color="secondary">mdi-folder-zip</v-icon></template>
                                <v-list-item-title class="font-weight-bold" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">Baixar XMLs (Lote)</v-list-item-title>
                            </v-list-item>

                            <v-list-item @click="reportModal.show = true" class="rounded-sm">
                                <template v-slot:prepend><v-icon size="18" color="primary">mdi-printer</v-icon></template>
                                <v-list-item-title class="font-weight-bold" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">Imprimir Relatório</v-list-item-title>
                            </v-list-item>
                        </v-list>
                    </v-card>
                </v-menu>
            </div>
        </div>
        </div>

        <div class="flex-grow-1 px-6 pb-6 overflow-hidden d-flex flex-column">
            <v-card
              class="flex-grow-1 d-flex flex-column rounded-lg border-thin overflow-hidden"
              :class="themeStore.currentMode === 'light' ? 'bg-white shadow-sm' : 'glass-card border-white-05'"
              :elevation="0"
            >
                <div class="grid-scroll flex-grow-1 overflow-y-auto custom-scroll">
                    <div
                      class="grid-header sticky-head grid-nfe-layout"
                      :class="[themeStore.currentMode === 'light' ? 'grid-surface-light border-b border-grey-lighten-2' : 'grid-surface-dark border-bottom-white-05']"
                    >
                        <div class="cell center header-text">#</div>
                        <div class="cell center header-text">Nº NFe</div>
                        <div class="cell center header-text">Pedido</div>
                        <div class="cell header-text pl-4">Destinatário</div>
                        <div class="cell header-text pl-4">Chave de Acesso</div>
                        <div class="cell center header-text">Status</div>
                        <div class="cell center header-text">Data</div>
                        <div class="cell right header-text pr-4">Valor Total</div>
                        <div class="cell center header-text">Ações</div>
                    </div>

                    <div v-if="loading" class="d-flex flex-column justify-center align-center h-100 py-10">
                        <v-progress-circular indeterminate color="primary" size="32" width="3"></v-progress-circular>
                    </div>

                    <template v-else>
                        <div v-for="(note, index) in paginatedNotes" :key="note.id"
                             class="grid-row grid-nfe-layout transition-colors border-b"
                             :class="[themeStore.currentMode === 'light' ? 'grid-row-light border-grey-lighten-2' : 'grid-row-dark border-bottom-white-05', zebraClass(index)]"
                        >
                            <div class="cell center">
                                 <v-icon :color="getStatusColor(note.status)" size="20">mdi-file-document-outline</v-icon>
                            </div>

                            <div class="cell center">
                                <span class="list-text-11 font-mono font-weight-black" :class="!note.numero ? 'text-grey italic' : ''">
                                    {{ note.numero ? String(note.numero).padStart(6, '0') : '---' }}
                                </span>
                            </div>

                            <div class="cell center">
                                <v-chip
                                    v-if="getOrderNumber(note)"
                                    size="x-small"
                                    color="indigo"
                                    variant="flat"
                                    class="font-weight-bold cursor-pointer chip-3d rounded"
                                    @click.stop="openOrderModal(note)"
                                >
                                    <v-icon start size="12">mdi-package-variant</v-icon>
                                    #{{ getOrderNumber(note) }}
                                </v-chip>
                                <span v-else class="text-caption text-grey opacity-50">---</span>
                            </div>

                            <div class="cell pl-4">
                                <div class="d-flex flex-column" style="min-width: 0;">
                                    <span class="list-text-11 font-weight-bold text-truncate">{{ note.destinatario_nome || 'Consumidor Final' }}</span>
                                    <span class="text-[9px] text-grey font-weight-medium text-uppercase">{{ note.natureza_operacao || 'VENDA' }}</span>
                                </div>
                            </div>

                            <div class="cell pl-4">
                                <div class="d-flex align-center justify-space-between w-100">
                                    <span v-if="note.chave" class="font-mono text-[10px] letter-spacing-1 text-truncate select-all opacity-80" style="max-width: 100%;">
                                        {{ note.chave }}
                                    </span>
                                    <span v-else class="font-mono text-[10px] text-grey italic">Aguardando Emissão...</span>

                                    <v-tooltip location="top" content-class="bg-grey-darken-4" v-if="note.chave">
                                        <template v-slot:activator="{ props }">
                                            <v-btn v-bind="props" icon size="x-small" variant="text" density="compact"
                                                :color="copiedId === note.id ? 'success' : 'grey'"
                                                class="ml-1 flex-shrink-0"
                                                @click.stop="copyToClipboard(note.chave, note.id)"
                                            >
                                                <v-icon size="14">{{ copiedId === note.id ? 'mdi-check' : 'mdi-content-copy' }}</v-icon>
                                            </v-btn>
                                        </template>
                                        <span class="text-white font-weight-bold">{{ copiedId === note.id ? 'Copiado!' : 'Copiar Chave' }}</span>
                                    </v-tooltip>
                                </div>
                            </div>

                            <div class="cell center">
                                <v-chip
                                    size="x-small"
                                    class="font-weight-black text-uppercase letter-spacing-1 solid-chip chip-3d rounded"
                                    :class="getChipClass(note.status)"
                                    @click="note.status === 'REJEITADA' ? showErrorDetails(note) : null"
                                >
                                    {{ note.status }}
                                    <v-icon end size="14" v-if="note.status === 'REJEITADA'">mdi-alert-circle-outline</v-icon>
                                </v-chip>
                            </div>

                            <div class="cell center">
                                <span class="list-text-11 font-mono opacity-80">{{ formatDate(note.created_at) }}</span>
                            </div>

                            <div class="cell right pr-4">
                                <span class="list-text-11 font-mono font-weight-black text-success">{{ formatCurrency(note.valor_total) }}</span>
                            </div>

                            <div class="cell center">
                                <div class="actions-inline flex-wrap justify-center">
                                    <v-tooltip location="top" content-class="bg-grey-darken-4">
                                        <template v-slot:activator="{ props }">
                                            <v-btn v-bind="props" icon size="small" class="action-btn bg-orange-darken-1 text-white btn-3d rounded-sm"
                                                :disabled="isActionDisabled('edit', note)"
                                                @click="editDraft(note)"
                                            >
                                                <v-icon size="16">mdi-pencil</v-icon>
                                            </v-btn>
                                        </template>
                                        <span class="text-white font-weight-bold">Editar / Corrigir</span>
                                    </v-tooltip>

                                    <v-tooltip location="top" content-class="bg-grey-darken-4">
                                        <template v-slot:activator="{ props }">
                                            <v-btn v-bind="props" icon size="small" class="action-btn bg-indigo-darken-1 text-white btn-3d rounded-sm"
                                                :disabled="isActionDisabled('pdf', note)"
                                                @click="viewDocument(note, 'pdf')"
                                            >
                                                <v-icon size="16">mdi-file-pdf-box</v-icon>
                                            </v-btn>
                                        </template>
                                        <span class="text-white font-weight-bold">Visualizar DANFE</span>
                                    </v-tooltip>

                                    <v-menu location="bottom end">
                                        <template v-slot:activator="{ props }">
                                            <v-btn v-bind="props" icon size="small" class="action-btn bg-blue-grey-darken-2 text-white btn-3d rounded-sm">
                                                <v-icon size="18">mdi-chevron-down</v-icon>
                                            </v-btn>
                                        </template>
                                        <v-list density="compact" class="py-0 border-thin shadow-xl rounded-lg" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-grey-darken-4 text-white'">
                                            <v-list-item v-if="note.status === 'RASCUNHO'" @click="emitDraft(note)" :disabled="issuing === note.id">
                                                <template v-slot:prepend><v-icon size="16" color="success" class="mr-2">mdi-send</v-icon></template>
                                                <v-list-item-title class="font-weight-bold">Transmitir Nota</v-list-item-title>
                                            </v-list-item>

                                            <v-list-item v-if="note.status === 'REJEITADA'" @click="retryEmission(note)">
                                                <template v-slot:prepend><v-icon size="16" color="warning" class="mr-2">mdi-reload</v-icon></template>
                                                <v-list-item-title class="font-weight-bold">Corrigir e Reenviar</v-list-item-title>
                                            </v-list-item>

                                            <v-list-item @click="openCceModal(note)" v-if="note.status === 'AUTORIZADA' || note.status === 'CORRIGIDA'">
                                                <template v-slot:prepend><v-icon size="16" color="orange" class="mr-2">mdi-file-document-edit</v-icon></template>
                                                <v-list-item-title class="font-weight-bold">Carta de Correção (CC-e)</v-list-item-title>
                                            </v-list-item>

                                            <v-list-item @click="downloadCce(note, 'pdf')" v-if="note.status === 'CORRIGIDA'">
                                                <template v-slot:prepend><v-icon size="16" color="orange" class="mr-2">mdi-file-pdf-box</v-icon></template>
                                                <v-list-item-title class="font-weight-bold">Baixar PDF da CC-e</v-list-item-title>
                                            </v-list-item>

                                            <v-list-item @click="downloadCce(note, 'xml')" v-if="note.status === 'CORRIGIDA'">
                                                <template v-slot:prepend><v-icon size="16" color="purple" class="mr-2">mdi-xml</v-icon></template>
                                                <v-list-item-title class="font-weight-bold">Baixar XML da CC-e</v-list-item-title>
                                            </v-list-item>

                                            <v-list-item @click="openEmailModal(note)" v-if="note.status === 'AUTORIZADA'">
                                                <template v-slot:prepend><v-icon size="16" color="blue" class="mr-2">mdi-email-fast</v-icon></template>
                                                <v-list-item-title class="font-weight-bold">Enviar por E-mail</v-list-item-title>
                                            </v-list-item>

                                            <v-list-item @click="syncNfe(note)">
                                                <template v-slot:prepend><v-icon size="16" color="teal" class="mr-2">mdi-sync</v-icon></template>
                                                <v-list-item-title class="font-weight-bold">Sincronizar Sefaz</v-list-item-title>
                                            </v-list-item>

                                            <v-list-item @click="openLinkOrderModal(note)" :disabled="!note.chave">
                                                <template v-slot:prepend><v-icon size="16" color="blue-grey" class="mr-2">mdi-link-variant</v-icon></template>
                                                <v-list-item-title class="font-weight-bold">Vincular a Pedido</v-list-item-title>
                                            </v-list-item>

                                            <v-list-item @click="cloneNote(note)">
                                                <template v-slot:prepend><v-icon size="16" color="teal-darken-1" class="mr-2">mdi-content-copy</v-icon></template>
                                                <v-list-item-title class="font-weight-bold">Clonar (Nova NFe)</v-list-item-title>
                                            </v-list-item>

                                            <v-list-item @click="viewDocument(note, 'xml')" :disabled="isActionDisabled('xml', note)">
                                                <template v-slot:prepend><v-icon size="16" color="purple" class="mr-2">mdi-xml</v-icon></template>
                                                <v-list-item-title class="font-weight-bold">Baixar XML</v-list-item-title>
                                            </v-list-item>

                                            <v-divider :class="themeStore.currentMode === 'light' ? 'border-grey-lighten-2' : 'border-white-10'"></v-divider>
                                            <v-list-subheader class="text-[10px] font-weight-bold text-uppercase" :class="themeStore.currentMode === 'light' ? 'text-grey' : 'text-white-70'">Links Rápidos</v-list-subheader>

                                            <v-list-item @click="shareWhatsapp(note)" :disabled="isActionDisabled('share', note)">
                                                <template v-slot:prepend><v-icon size="16" color="success" class="mr-2">mdi-whatsapp</v-icon></template>
                                                <v-list-item-title class="font-weight-bold">WhatsApp Link</v-list-item-title>
                                            </v-list-item>

                                            <v-divider :class="themeStore.currentMode === 'light' ? 'border-grey-lighten-2' : 'border-white-10'"></v-divider>
                                            <v-list-subheader class="text-[10px] font-weight-bold text-uppercase text-error">Zona de Perigo</v-list-subheader>

                                            <v-list-item v-if="note.status === 'REJEITADA' && note.numero" @click="markAsInutilized(note)">
                                                <template v-slot:prepend><v-icon size="16" color="grey" class="mr-2">mdi-check-all</v-icon></template>
                                                <v-list-item-title class="font-weight-bold text-grey">Marcar como Inutilizada (Manual)</v-list-item-title>
                                            </v-list-item>

                                            <v-list-item v-if="note.status === 'REJEITADA' && note.numero" @click="inutilizarFromGrid(note)">
                                                <template v-slot:prepend><v-icon size="16" color="warning" class="mr-2">mdi-cancel</v-icon></template>
                                                <v-list-item-title class="font-weight-bold">Inutilizar Numeração (Sefaz)</v-list-item-title>
                                            </v-list-item>

                                            <v-list-item @click="cancelNote(note)" class="text-error" :disabled="isActionDisabled('cancel', note)">
                                                <template v-slot:prepend><v-icon size="16" color="error" class="mr-2">mdi-cancel</v-icon></template>
                                                <v-list-item-title class="font-weight-bold">Cancelar NFe</v-list-item-title>
                                            </v-list-item>

                                            <v-list-item @click="deleteDraft(note)" class="text-error" :disabled="isActionDisabled('delete', note)">
                                                <template v-slot:prepend><v-icon size="16" color="error" class="mr-2">mdi-delete</v-icon></template>
                                                <v-list-item-title class="font-weight-bold">Excluir Registro</v-list-item-title>
                                            </v-list-item>
                                        </v-list>
                                    </v-menu>
                                </div>
                            </div>
                        </div>
                    </template>
                </div>

                <div class="flex-shrink-0 border-t px-4 py-2 d-flex align-center justify-space-between z-20" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-surface-variant border-white-05'" v-if="pageCount > 1">
                    <div class="text-caption font-weight-bold opacity-70">Página {{ page }} de {{ pageCount }}</div>
                    <v-pagination v-model="page" :length="pageCount" :total-visible="5" density="compact" :active-color="themeStore.currentMode === 'light' ? 'primary' : 'success'" variant="tonal" size="small"></v-pagination>
                </div>
            </v-card>
        </div>
    </div>

    <input type="file" ref="xmlFileInput" accept=".xml" class="d-none" @change="handleXmlImport" />

    <NfeEmissionModal
      v-if="showIssueModal"
      v-model="showIssueModal"
      :draft-id="editingDraftId"
      :draft-payload="draftPayload"
      @success="fetchHistory"
      @draft-saved="fetchHistory"
    />

    <v-dialog v-model="xmlImportModal.show" max-width="400">
        <v-card class="rounded pa-4 shadow-xl border-thin" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-grey-darken-4 text-white'">
            <v-card-title class="text-h6 font-weight-black px-2 pt-2 pb-4 border-b d-flex align-center gap-2" :class="themeStore.currentMode === 'light' ? 'border-grey-lighten-2' : 'border-white-10'">
                <v-icon color="success">mdi-xml</v-icon> Importar XML
            </v-card-title>
            <v-card-text class="px-2 py-4">
                <p class="text-body-2 mb-4 font-weight-medium" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-2' : 'text-white-70'">
                    Você pode subir um arquivo XML autorizado para alimentar seu sistema.
                </p>
                <v-switch
                    v-model="xmlImportModal.isOrder"
                    color="primary"
                    label="Esta nota pertence a um Pedido?"
                    hide-details
                    density="compact"
                    class="mb-3 font-weight-bold"
                ></v-switch>
                <v-expand-transition>
                    <div v-if="xmlImportModal.isOrder" class="mt-2">
                        <v-radio-group v-model="xmlImportModal.orderType" inline density="compact" hide-details class="mb-3 font-weight-bold text-caption">
                            <v-radio label="Pedido Padrão" value="orders" color="primary"></v-radio>
                            <v-radio label="Venda Balcão" value="store_sales" color="primary"></v-radio>
                        </v-radio-group>
                        <v-text-field
                            v-model="xmlImportModal.orderNumber"
                            :label="xmlImportModal.orderType === 'orders' ? 'Número do Pedido' : 'Número da Venda'"
                            variant="outlined"
                            density="comfortable"
                            hide-details
                            placeholder="Apenas números"
                            class="ui-field"
                        ></v-text-field>
                    </div>
                </v-expand-transition>
            </v-card-text>
            <v-card-actions class="px-2 pb-2">
                <v-spacer></v-spacer>
                <v-btn variant="text" class="btn-3d font-weight-bold rounded" :color="themeStore.currentMode === 'light' ? 'grey-darken-2' : 'white'" @click="xmlImportModal.show = false" :disabled="importingXml">Cancelar</v-btn>
                <v-btn color="success" variant="flat" class="btn-3d font-weight-bold px-6 rounded" :loading="importingXml" @click="confirmXmlImport">
                    Selecionar Arquivo
                </v-btn>
            </v-card-actions>
        </v-card>
    </v-dialog>

    <v-dialog v-model="nuvemNotesState.show" max-width="800" scrollable>
        <v-card class="rounded border-thin shadow-xl" :class="themeStore.currentMode === 'light' ? 'bg-white border-grey-lighten-2' : 'bg-grey-darken-4 text-white border-white-10'">
            <v-card-title class="text-h6 font-weight-black border-b d-flex align-center justify-space-between px-4 py-3" :class="themeStore.currentMode === 'light' ? 'border-grey-lighten-2' : 'border-white-10'">
                <div class="d-flex align-center gap-2 text-blue-grey">
                    <v-icon>mdi-cloud-search</v-icon> Histórico da Nuvem Fiscal
                </div>
                <v-btn icon="mdi-close" variant="text" density="compact" @click="nuvemNotesState.show = false"></v-btn>
            </v-card-title>

            <v-card-text class="pa-0 custom-scroll" style="height: 500px;">
                <div v-if="nuvemNotesState.loading && nuvemNotesState.notes.length === 0" class="d-flex justify-center pa-10">
                    <v-progress-circular indeterminate color="primary"></v-progress-circular>
                </div>

                <v-list v-else bg-color="transparent" class="pa-2">
                    <v-list-item v-for="note in nuvemNotesState.notes" :key="note.id" class="border rounded mb-2" :class="themeStore.currentMode === 'light' ? 'border-grey-lighten-2 bg-grey-lighten-5' : 'border-white-10 bg-black-20'">
                        <template v-slot:prepend>
                            <v-icon :color="note.status === 'autorizado' ? 'success' : (note.status === 'rejeitado' || note.status === 'erro' ? 'error' : 'warning')" class="mr-3">
                                {{ note.status === 'autorizado' ? 'mdi-check-circle' : 'mdi-alert-circle' }}
                            </v-icon>
                        </template>

                        <v-list-item-title class="font-weight-bold d-flex align-center justify-space-between">
                            <span :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">
                                Nº {{ note.numero || 'S/N' }} - {{ note.status.toUpperCase() }}
                            </span>
                            <span class="text-caption text-grey">{{ new Date(note.created_at).toLocaleString('pt-BR') }}</span>
                        </v-list-item-title>

                        <v-list-item-subtitle class="mt-1 text-caption d-flex flex-column gap-1" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-1' : 'text-white-70'">
                            <span><strong>Chave:</strong> {{ note.chave || '---' }}</span>
                            <span v-if="note.status === 'rejeitado' || note.status === 'erro'" class="text-error font-weight-medium">
                                <strong>Motivo:</strong> {{ note.autorizacao?.motivo_status || note.motivo_status || 'Erro desconhecido' }}
                            </span>
                        </v-list-item-subtitle>

                        <template v-slot:append>
                            <div class="d-flex align-center gap-2 flex-wrap">
                                <v-chip v-if="isNoteImported(note)" size="small" color="success" variant="flat" class="font-weight-bold rounded">
                                    <v-icon start size="12">mdi-check</v-icon> No Sistema
                                </v-chip>
                                <v-btn v-else
                                    color="primary" variant="flat" size="small" class="btn-3d font-weight-bold rounded"
                                    @click="importFromNuvem(note)">
                                    <v-icon start size="14">mdi-download</v-icon> Importar
                                </v-btn>

                                <template v-if="note.status === 'rejeitado' || note.status === 'erro'">
                                    <v-btn color="warning" variant="flat" size="small" class="btn-3d font-weight-bold ml-1 rounded" @click="inutilizarFromNuvem(note)">
                                        Inutilizar (Sefaz)
                                    </v-btn>
                                    <v-btn color="grey" variant="flat" size="small" class="btn-3d font-weight-bold ml-1 rounded" @click="markNuvemAsInutilized(note)">
                                        Forçar Inutilizada
                                    </v-btn>
                                </template>
                            </div>
                        </template>
                    </v-list-item>

                    <div v-if="nuvemNotesState.hasMore" class="d-flex justify-center pa-4">
                        <v-btn variant="outlined" color="primary" class="btn-3d font-weight-bold rounded" :loading="nuvemNotesState.loading" @click="nuvemNotesState.skip += 50; fetchNuvemNotes(true)">Carregar Mais Antigas</v-btn>
                    </div>
                    <div v-else-if="nuvemNotesState.notes.length === 0" class="text-center pa-4 text-grey">
                        Nenhuma nota encontrada na Nuvem Fiscal.
                    </div>
                </v-list>
            </v-card-text>
        </v-card>
    </v-dialog>

    <v-dialog v-model="inutState.show" max-width="500">
        <v-card class="rounded pa-4 shadow-xl border-thin" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-grey-darken-4 text-white'">
            <v-card-title class="text-h6 font-weight-black px-2 pt-2 pb-4 border-b d-flex align-center gap-2 text-warning" :class="themeStore.currentMode === 'light' ? 'border-grey-lighten-2' : 'border-white-10'">
                <v-icon>mdi-cancel</v-icon> Inutilizar Numeração (NF-e)
            </v-card-title>
            <v-card-text class="px-2 py-4">
                <v-alert v-if="inutState.status" :type="inutState.status === 'registrado' ? 'success' : (inutState.status === 'rejeitado' ? 'error' : 'info')" variant="tonal" density="compact" class="mb-4 text-caption font-weight-bold">
                    Status: {{ inutState.status.toUpperCase() }}
                </v-alert>

                <div v-if="!inutState.resultadoId">
                    <p class="text-caption font-weight-medium mb-4" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-2' : 'text-white-70'">
                        Informe a sequência de numeração que deseja inutilizar na Sefaz.
                    </p>
                    <v-row dense>
                        <v-col cols="6">
                            <v-text-field v-model.number="inutState.ano" label="Ano (Ex: 24)" variant="outlined" density="compact" type="number" class="ui-field font-weight-bold"></v-text-field>
                        </v-col>
                        <v-col cols="6">
                            <v-text-field v-model.number="inutState.serie" label="Série" variant="outlined" density="compact" type="number" class="ui-field font-weight-bold"></v-text-field>
                        </v-col>
                        <v-col cols="6">
                            <v-text-field v-model.number="inutState.numero_inicial" label="Nº Inicial" variant="outlined" density="compact" type="number" class="ui-field font-weight-bold"></v-text-field>
                        </v-col>
                        <v-col cols="6">
                            <v-text-field v-model.number="inutState.numero_final" label="Nº Final" variant="outlined" density="compact" type="number" class="ui-field font-weight-bold"></v-text-field>
                        </v-col>
                        <v-col cols="12">
                            <v-textarea v-model="inutState.justificativa" label="Justificativa (Mínimo 15 caracteres)" variant="outlined" rows="3" counter="255" maxlength="255" hide-details class="ui-field font-weight-bold mt-2"></v-textarea>
                        </v-col>
                    </v-row>
                </div>

                <div v-else class="text-center mt-4">
                    <div class="mb-4">
                        <v-icon size="48" :color="inutState.status === 'registrado' ? 'success' : 'warning'">
                            {{ inutState.status === 'registrado' ? 'mdi-check-circle' : 'mdi-alert-circle' }}
                        </v-icon>
                        <h4 class="text-h6 mt-2">{{ inutState.status === 'registrado' ? 'Numeração Inutilizada!' : 'Evento Processado' }}</h4>
                    </div>
                    <v-btn color="indigo" variant="flat" class="btn-3d font-weight-bold mr-2 rounded" prepend-icon="mdi-file-pdf-box" @click="downloadInut('pdf')" :disabled="inutState.status !== 'registrado'">Baixar PDF</v-btn>
                    <v-btn color="purple" variant="flat" class="btn-3d font-weight-bold rounded" prepend-icon="mdi-xml" @click="downloadInut('xml')" :disabled="inutState.status !== 'registrado'">Baixar XML</v-btn>
                    <div class="mt-4">
                         <v-btn variant="text" color="primary" @click="checkInutStatus">Atualizar Status</v-btn>
                    </div>
                </div>
            </v-card-text>
            <v-card-actions class="px-2 pb-2">
                <v-spacer></v-spacer>
                <v-btn variant="text" class="btn-3d font-weight-bold rounded" :color="themeStore.currentMode === 'light' ? 'grey-darken-2' : 'white'" @click="inutState.show = false">Fechar</v-btn>
                <v-btn v-if="!inutState.resultadoId" color="warning" variant="flat" class="btn-3d font-weight-bold px-6 rounded" :loading="inutState.loading" @click="submitInut">Confirmar Inutilização</v-btn>
            </v-card-actions>
        </v-card>
    </v-dialog>

    <v-dialog v-model="linkOrderState.show" max-width="400">
        <v-card class="rounded pa-4 shadow-xl border-thin" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-grey-darken-4 text-white'">
            <v-card-title class="text-h6 font-weight-black px-2 pt-2 pb-4 border-b d-flex align-center gap-2" :class="themeStore.currentMode === 'light' ? 'border-grey-lighten-2 text-primary' : 'border-white-10 text-success'">
                <v-icon>mdi-link-variant</v-icon> Vincular Pedido
            </v-card-title>
            <v-card-text class="px-2 py-4 text-body-2 font-weight-medium" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-2' : 'text-white-70'">
                <p class="mb-4">Escolha o tipo e digite o <strong>Número</strong> para forçar o vínculo com esta Nota Fiscal (Chave: {{ linkOrderState.note?.chave || 'Sem chave' }}).</p>

                <v-radio-group v-model="linkOrderState.orderType" inline density="compact" hide-details class="mb-3 font-weight-bold">
                    <v-radio label="Pedido Padrão" value="orders" color="primary"></v-radio>
                    <v-radio label="Venda Balcão (PDV)" value="store_sales" color="primary"></v-radio>
                </v-radio-group>

                <v-text-field
                    v-model="linkOrderState.orderNumber"
                    :label="linkOrderState.orderType === 'orders' ? 'Número do Pedido (Ex: 1050)' : 'Número da Venda (Ex: 50)'"
                    variant="outlined"
                    density="comfortable"
                    hide-details
                    autofocus
                    class="ui-field"
                ></v-text-field>
            </v-card-text>
            <v-card-actions class="px-2 pb-2">
                <v-spacer></v-spacer>
                <v-btn variant="text" class="btn-3d font-weight-bold rounded" :color="themeStore.currentMode === 'light' ? 'grey-darken-2' : 'white'" @click="linkOrderState.show = false">Cancelar</v-btn>
                <v-btn :color="themeStore.currentMode === 'light' ? 'primary' : 'success'" variant="flat" class="btn-3d font-weight-bold px-6 rounded" :loading="linkOrderState.loading" @click="confirmLinkOrder">Vincular</v-btn>
            </v-card-actions>
        </v-card>
    </v-dialog>

    <v-dialog v-model="cceState.show" max-width="500">
        <v-card class="rounded pa-4 shadow-xl border-thin" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-grey-darken-4 text-white'">
            <v-card-title class="text-h6 font-weight-black px-2 pt-2 pb-4 border-b d-flex align-center gap-2 text-orange-darken-2" :class="themeStore.currentMode === 'light' ? 'border-grey-lighten-2' : 'border-white-10'">
                <v-icon>mdi-file-document-edit</v-icon> Carta de Correção (CC-e)
            </v-card-title>
            <v-card-text class="px-2 py-4">
                <v-alert type="warning" variant="tonal" density="compact" class="mb-4 text-caption font-weight-bold">
                    A Correção não pode alterar valores, impostos, data de emissão ou o destinatário (quando exige mudança de CNPJ).
                </v-alert>
                <v-textarea
                    v-model="cceState.text"
                    label="Texto da Correção (Mín 15, Máx 1000 caracteres)"
                    variant="outlined"
                    rows="4"
                    hide-details
                    counter="1000"
                    maxlength="1000"
                    class="ui-field"
                ></v-textarea>
            </v-card-text>
            <v-card-actions class="px-2 pb-2">
                <v-spacer></v-spacer>
                <v-btn variant="text" class="btn-3d font-weight-bold rounded" :color="themeStore.currentMode === 'light' ? 'grey-darken-2' : 'white'" @click="cceState.show = false">Cancelar</v-btn>
                <v-btn color="orange-darken-2" variant="flat" class="btn-3d font-weight-bold px-6 rounded" :loading="cceState.loading" @click="submitCce">Transmitir Correção</v-btn>
            </v-card-actions>
        </v-card>
    </v-dialog>

    <v-dialog v-model="emailState.show" max-width="500">
        <v-card class="rounded pa-4 shadow-xl border-thin" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-grey-darken-4 text-white'">
            <v-card-title class="text-h6 font-weight-black px-2 pt-2 pb-4 border-b d-flex align-center gap-2 text-blue-darken-2" :class="themeStore.currentMode === 'light' ? 'border-grey-lighten-2' : 'border-white-10'">
                <v-icon>mdi-email-fast</v-icon> Enviar XML / PDF
            </v-card-title>
            <v-card-text class="px-2 py-4">
                <p class="text-body-2 font-weight-medium mb-4" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-2' : 'text-white-70'">Insira os e-mails que receberão os arquivos desta nota (separados por vírgula se houver mais de um).</p>
                <v-text-field
                    v-model="emailState.email"
                    label="E-mails Destinatários"
                    variant="outlined"
                    hide-details
                    class="ui-field font-weight-bold"
                ></v-text-field>
            </v-card-text>
            <v-card-actions class="px-2 pb-2">
                <v-spacer></v-spacer>
                <v-btn variant="text" class="btn-3d font-weight-bold rounded" :color="themeStore.currentMode === 'light' ? 'grey-darken-2' : 'white'" @click="emailState.show = false">Cancelar</v-btn>
                <v-btn color="blue-darken-2" variant="flat" class="btn-3d font-weight-bold px-6 rounded" :loading="emailState.loading" @click="submitEmail">Disparar E-mail</v-btn>
            </v-card-actions>
        </v-card>
    </v-dialog>

    <v-dialog v-model="danfeModal.show" max-width="1000" scrollable>
        <v-card class="rounded h-100 border shadow-xl" :class="themeStore.currentMode === 'light' ? 'border-grey-lighten-2 bg-white' : 'border-white-10 bg-glass-dark'">
            <v-toolbar density="compact" class="elevation-0 border-b" :class="themeStore.currentMode === 'light' ? 'bg-grey-darken-4 border-grey-darken-3' : 'bg-primary border-white-10'">
                <v-toolbar-title class="text-caption font-weight-bold text-white tracking-wide">Visualizador de Documento</v-toolbar-title>
                <v-spacer></v-spacer>
                <v-btn icon color="white" class="btn-3d rounded" @click="danfeModal.show = false"><v-icon>mdi-close</v-icon></v-btn>
            </v-toolbar>
            <v-card-text class="pa-0 h-[600px]" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-2' : 'bg-black'" style="height: 80vh;">
                <iframe v-if="danfeModal.url" :src="danfeModal.url" class="pdf-iframe w-100 h-100 border-0"></iframe>
                <div v-else class="d-flex align-center justify-center h-100">
                    <v-progress-circular indeterminate :color="themeStore.currentMode === 'light' ? 'grey-darken-4' : 'success'"></v-progress-circular>
                </div>
            </v-card-text>
        </v-card>
    </v-dialog>

    <v-dialog v-model="errorDialog.show" max-width="600">
        <v-card class="rounded pa-6 border-thin shadow-xl" :class="themeStore.currentMode === 'light' ? 'bg-white border-grey-lighten-2' : 'bg-grey-darken-4 text-white border-white-10'">
            <div class="d-flex align-center gap-3 mb-4 text-error">
                <v-icon size="32">mdi-alert-octagon</v-icon>
                <h3 class="text-h6 font-weight-bold">Nota Rejeitada / Erro</h3>
            </div>
            <div class="pa-4 rounded mb-4 text-caption font-mono custom-scrollbar" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-4 text-grey-darken-3' : 'bg-black-20 text-white-70'" style="max-height: 300px; overflow-y: auto;">
                <pre class="text-wrap">{{ errorDialog.message }}</pre>
            </div>
            <v-btn block :color="themeStore.currentMode === 'light' ? 'primary' : 'success'" variant="flat" class="btn-3d font-weight-bold rounded" @click="errorDialog.show = false">Fechar</v-btn>
        </v-card>
    </v-dialog>

    <v-dialog v-model="reportModal.show" max-width="450">
        <v-card class="rounded pa-4 shadow-xl border-thin" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-grey-darken-4 text-white'">
            <v-card-title class="text-h6 font-weight-black px-2 pt-2 pb-4 border-b d-flex align-center gap-2" :class="themeStore.currentMode === 'light' ? 'border-grey-lighten-2 text-primary' : 'border-white-10 text-success'">
                <v-icon>mdi-printer-cog</v-icon> Configurar Relatório
            </v-card-title>
            <v-card-text class="px-2 py-4">
                <p class="text-body-2 font-weight-medium mb-4" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-2' : 'text-white-70'">
                    Selecione o período exato das notas fiscais que deseja listar neste relatório.
                </p>
                <v-row dense>
                    <v-col cols="12" sm="6">
                        <label class="input-label">Data Inicial</label>
                        <v-text-field type="date" v-model="reportModal.startDate" variant="outlined" density="compact" hide-details class="ui-field font-weight-bold"></v-text-field>
                    </v-col>
                    <v-col cols="12" sm="6">
                        <label class="input-label">Data Final</label>
                        <v-text-field type="date" v-model="reportModal.endDate" variant="outlined" density="compact" hide-details class="ui-field font-weight-bold"></v-text-field>
                    </v-col>
                </v-row>
            </v-card-text>
            <v-card-actions class="px-2 pb-2">
                <v-spacer></v-spacer>
                <v-btn variant="text" class="btn-3d font-weight-bold rounded" :color="themeStore.currentMode === 'light' ? 'grey-darken-2' : 'white'" @click="reportModal.show = false">Cancelar</v-btn>
                <v-btn :color="themeStore.currentMode === 'light' ? 'primary' : 'success'" variant="flat" prepend-icon="mdi-file-document-outline" class="btn-3d font-weight-bold px-6 rounded" @click="generateAndPrintReport">
                    Gerar e Imprimir
                </v-btn>
            </v-card-actions>
        </v-card>
    </v-dialog>

    <v-dialog v-model="bulkDownloadModal.show" max-width="450">
        <v-card class="rounded pa-4 shadow-xl border-thin" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-grey-darken-4 text-white'">
            <v-card-title class="text-h6 font-weight-black px-2 pt-2 pb-4 border-b d-flex align-center gap-2" :class="themeStore.currentMode === 'light' ? 'border-grey-lighten-2 text-secondary' : 'border-white-10 text-secondary'">
                <v-icon>mdi-folder-zip</v-icon> Baixar Lote de XML
            </v-card-title>
            <v-card-text class="px-2 py-4">
                <p class="text-body-2 font-weight-medium mb-4" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-2' : 'text-white-70'">
                    Defina o período e o status das notas que deseja compactar.
                </p>
                <v-row dense>
                    <v-col cols="12" sm="6">
                        <label class="input-label">Data Inicial</label>
                        <v-text-field type="date" v-model="bulkDownloadModal.startDate" variant="outlined" density="compact" hide-details class="ui-field font-weight-bold"></v-text-field>
                    </v-col>
                    <v-col cols="12" sm="6">
                        <label class="input-label">Data Final</label>
                        <v-text-field type="date" v-model="bulkDownloadModal.endDate" variant="outlined" density="compact" hide-details class="ui-field font-weight-bold"></v-text-field>
                    </v-col>
                    <v-col cols="12" class="mt-2">
                        <label class="input-label">Status da NFe</label>
                        <v-select
                            v-model="bulkDownloadModal.status"
                            :items="['TODOS', 'AUTORIZADA', 'REJEITADA', 'CANCELADA', 'RASCUNHO']"
                            variant="outlined"
                            density="compact"
                            hide-details
                            class="ui-field font-weight-bold"
                        ></v-select>
                    </v-col>
                </v-row>

                <div v-if="bulkDownloadModal.progress.show" class="mt-4 rounded pa-3 border-thin" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-4' : 'bg-black-20 border-white-10'">
                    <div class="d-flex justify-space-between text-caption font-weight-bold mb-1" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-3' : 'text-white'">
                        <span>{{ bulkDownloadModal.progress.current === bulkDownloadModal.progress.total ? 'Compactando arquivo ZIP...' : 'Baixando XMLs da Sefaz...' }}</span>
                        <span>{{ bulkDownloadModal.progress.current }} / {{ bulkDownloadModal.progress.total }}</span>
                    </div>
                    <v-progress-linear :model-value="(bulkDownloadModal.progress.current / bulkDownloadModal.progress.total) * 100" color="secondary" height="8" rounded></v-progress-linear>
                </div>
            </v-card-text>
            <v-card-actions class="px-2 pb-2">
                <v-spacer></v-spacer>
                <v-btn variant="text" class="btn-3d font-weight-bold rounded" :color="themeStore.currentMode === 'light' ? 'grey-darken-2' : 'white'" @click="bulkDownloadModal.show = false" :disabled="bulkDownloadModal.downloading">Cancelar</v-btn>
                <v-btn color="secondary" variant="flat" prepend-icon="mdi-download" class="btn-3d font-weight-bold px-6 rounded" @click="downloadBulkXML" :loading="bulkDownloadModal.downloading && !bulkDownloadModal.progress.show">
                    Baixar
                </v-btn>
            </v-card-actions>
        </v-card>
    </v-dialog>

    <v-dialog v-model="showLogs" max-width="800" scrollable>
        <v-card class="bg-grey-darken-4 text-white font-mono rounded border-thin border-white-10 shadow-xl">
            <v-card-title class="d-flex justify-space-between align-center border-b border-white-10 pa-4">
                <span class="text-caption font-weight-bold letter-spacing-1"><v-icon start size="small" color="primary">mdi-console-line</v-icon> CONSOLE DE EVENTOS DA SEFAZ</span>
                <v-btn icon="mdi-close" variant="text" density="compact" class="btn-3d rounded" @click="showLogs = false"></v-btn>
            </v-card-title>
            <v-card-text class="pa-0 custom-scroll" style="max-height: 500px; overflow-y: auto;">
                <div v-for="(log, idx) in systemLogs" :key="idx" class="pa-3 border-b border-white-10 text-[11px] hover:bg-white-05 transition-colors">
                    <span class="text-grey-lighten-1">{{ log.time }}</span>
                    <strong :class="getLogColor(log.type)" class="mx-2">[{{ log.type }}]</strong>
                    <span class="font-weight-medium">{{ log.message }}</span>
                    <pre v-if="log.details" class="bg-black-50 pa-3 mt-2 rounded border-white-10 text-grey-lighten-2 overflow-x-auto">{{ log.details }}</pre>
                </div>
                <div v-if="systemLogs.length === 0" class="pa-10 text-center text-grey opacity-50">
                    <v-icon size="40" class="mb-2">mdi-check-circle-outline</v-icon>
                    <div>Nenhum log registrado na sessão atual.</div>
                </div>
            </v-card-text>
            <v-card-actions class="pa-4 border-t border-white-10 bg-black-20">
                <v-btn block color="error" variant="flat" class="btn-3d font-weight-bold rounded" @click="systemLogs = []" :disabled="systemLogs.length === 0">Limpar Logs</v-btn>
            </v-card-actions>
        </v-card>
    </v-dialog>

    <OrderDetailModal
      v-if="showOrderModal"
      :show="showOrderModal"
      :order-id="selectedOrderId"
      @close="showOrderModal = false"
    />

  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, reactive, computed, watch, defineAsyncComponent } from 'vue';
import logoMjlm from '@/assets/logomjlm.png';
import logoCajuia from '@/assets/logocajuia.png';
import { sefazService } from '@/api/sefazApi';
import { supabase } from '@/api/supabase';
import { useAppStore } from '@/stores/app';
import { useThemeStore } from '@/stores/theme';
import { useCompanyStore } from '@/stores/company';
import { useUserStore } from '@/stores/user';
import { format, parseISO, startOfMonth, endOfMonth, startOfWeek, endOfWeek, isSameDay } from 'date-fns';
import { DANFe } from 'node-sped-pdf';
import axios from 'axios';
import JSZip from 'jszip'; // Biblioteca para download em lote

const OrderDetailModal = defineAsyncComponent(() => import('@/components/OrderDetailModal.vue'));
const NfeEmissionModal = defineAsyncComponent(() => import('@/components/admin/fiscal/NfeEmissionModal.vue'));

const appStore = useAppStore();
const themeStore = useThemeStore();
const companyStore = useCompanyStore();
const userStore = useUserStore();
const SEFAZ_PROXY_URL = import.meta.env.VITE_SEFAZ_PROXY_URL || 'https://sefaz-proxy-dujl.onrender.com';

const now = new Date();
const firstDay = new Date(now.getFullYear(), now.getMonth(), 1).toISOString().substring(0, 10);
const lastDay = new Date(now.getFullYear(), now.getMonth() + 1, 0).toISOString().substring(0, 10);

const reportModal = reactive({ show: false, startDate: firstDay, endDate: lastDay });

// --- STATE ---
const companies = ref<any[]>([]);
const activeCompany = ref<any>(null);
const notes = ref<any[]>([]);
const search = ref('');
const loadingCompanies = ref(false);
const loading = ref(false);
const issuing = ref<boolean>(false);
const copiedId = ref<string|null>(null);

const xmlFileInput = ref<HTMLInputElement | null>(null);
const importingXml = ref(false);

const showIssueModal = ref(false);
const showLogs = ref(false);
const filterStatus = ref('TODOS');

// --- ESCOPO DE TENANT / EMPRESA ---
// Funcionário com company_id no perfil fica preso à própria empresa nesta tela.
// Admin/super_admin continuam podendo alternar entre tenants.
const initialTenantContext = ref<string | null>(null);

const profileCompanyId = computed(() => {
    const profile: any = userStore.profile || {};
    return profile.company_id || profile.companyId || profile.company?.id || profile.empresa_id || profile.tenant_id || null;
});

const isGlobalTenantAdmin = computed(() => {
    const role = (userStore.profile as any)?.role;
    return ['super_admin', 'admin'].includes(role || '') || userStore.isGlobalAdmin === true;
});

const lockedCompanyId = computed(() => {
    if (isGlobalTenantAdmin.value) return null;
    return profileCompanyId.value || initialTenantContext.value || null;
});

const isTenantLocked = computed(() => !!lockedCompanyId.value);

const visibleCompanies = computed(() => {
    if (!isTenantLocked.value) return companies.value;
    return companies.value.filter(c => String(c.id) === String(lockedCompanyId.value));
});

const normalizeCnpj = (value: any) => String(value || '').replace(/\D/g, '');

const isCompanyAllowed = (company: any) => {
    if (!company) return false;
    if (!isTenantLocked.value) return true;
    return String(company.id) === String(lockedCompanyId.value);
};

const applyTenantScopeToCompanies = (list: any[]) => {
    if (!isTenantLocked.value) return list;
    return list.filter(company => String(company.id) === String(lockedCompanyId.value));
};

const getScopedCompany = () => {
    if (isTenantLocked.value) {
        return companies.value.find(company => String(company.id) === String(lockedCompanyId.value)) || null;
    }
    return activeCompany.value || null;
};

const syncActiveCompany = (company: any) => {
    if (!company) return;
    activeCompany.value = company;
    nextNfeNumber.value = parseInt(company.nfe_next_number || 0) + 1;

    if (!isTenantLocked.value) {
        companyStore.setContext(company.id);
    }

    if (companyStore.setActiveCompany) {
        companyStore.setActiveCompany(company);
    } else {
        companyStore.activeCompany = company;
    }
};

const selectInitialCompany = () => {
    if (companies.value.length === 0) {
        activeCompany.value = null;
        notes.value = [];
        return;
    }

    let selected: any = null;

    if (isTenantLocked.value) {
        selected = getScopedCompany();
        if (!selected) {
            activeCompany.value = null;
            notes.value = [];
            appStore.showSnackbar('Seu usuário não possui empresa fiscal vinculada para esta tela.', 'warning');
            return;
        }
    } else if (companyStore.context && companyStore.context !== 'global') {
        selected = companies.value.find(c => c.id === companyStore.context) || null;
    } else if (companyStore.activeCompany && companies.value.some(c => c.id === companyStore.activeCompany.id)) {
        selected = companies.value.find(c => c.id === companyStore.activeCompany.id) || null;
    }

    syncActiveCompany(selected || companies.value[0]);
    fetchHistory();
};

// --- MODAL E ESTADO DOWNLOAD EM MASSA (ZIP) ---
const bulkDownloadModal = reactive({
    show: false,
    startDate: firstDay,
    endDate: lastDay,
    status: 'AUTORIZADA',
    downloading: false,
    progress: { show: false, current: 0, total: 0 }
});

const openBulkDownloadModal = () => {
    bulkDownloadModal.show = true;
    bulkDownloadModal.progress.show = false;
    bulkDownloadModal.downloading = false;
};

// States for NfeEmissionModal
const editingDraftId = ref<string | null>(null);
const draftPayload = ref<any>(null);

// Modal Limpo de XML
const xmlImportModal = reactive({ show: false, isOrder: false, orderType: 'orders', orderNumber: '' });

// Vínculo Manual
const linkOrderState = reactive({ show: false, note: null as any, orderType: 'orders', orderNumber: '', loading: false });

// CC-e
const cceState = reactive({ show: false, note: null as any, text: '', loading: false });

// Email
const emailState = reactive({ show: false, note: null as any, email: '', loading: false });

// --- HISTÓRICO DA NUVEM (LISTAR NF-E) ---
const nuvemNotesState = reactive({
    show: false,
    loading: false,
    notes: [] as any[],
    skip: 0,
    hasMore: true
});

const openNuvemNotesModal = () => {
    nuvemNotesState.show = true;
    fetchNuvemNotes(false);
};

const fetchNuvemNotes = async (loadMore = false) => {
    if (!activeCompany.value) return appStore.showSnackbar('Selecione uma empresa', 'warning');

    // INTERCEPTADOR DE MODO DEMO
    if (companyStore.isDemoMode) {
        if (!loadMore) {
            nuvemNotesState.skip = 0;
            nuvemNotesState.notes = [
                { id: 'nuv-1', numero: 15419, status: 'autorizado', chave: '35260300000000000100550010000154191000154191', created_at: new Date().toISOString() },
                { id: 'nuv-2', numero: 15415, status: 'rejeitado', chave: '35260300000000000100550010000154151000154151', created_at: new Date(Date.now()-10000000).toISOString(), motivo_status: 'Rejeição: CPF/CNPJ inválido' }
            ];
            nuvemNotesState.hasMore = false;
        }
        return;
    }

    if (!loadMore) {
        nuvemNotesState.skip = 0;
        nuvemNotesState.notes = [];
    }
    nuvemNotesState.loading = true;
    try {
        const ambiente = activeCompany.value.nfe_environment === 'producao' ? 'producao' : 'homologacao';
        const cnpj = activeCompany.value.cnpj.replace(/\D/g, '');

        const res = await sefazService.listarNfesNuvem(cnpj, ambiente, 50, nuvemNotesState.skip);
        const fetchedNotes = res.data || [];

        if (fetchedNotes.length < 50) {
            nuvemNotesState.hasMore = false;
        } else {
            nuvemNotesState.hasMore = true;
        }

        nuvemNotesState.notes.push(...fetchedNotes);
    } catch (e: any) {
        appStore.showSnackbar(e.message, 'error');
        addLog('ERROR', 'Erro ao listar notas da Nuvem Fiscal', e);
    } finally {
        nuvemNotesState.loading = false;
    }
};

const isNoteImported = (nuvemNote: any) => {
    return notes.value.some(n =>
        (n.retorno_sefaz?.id_nuvem === nuvemNote.id) ||
        (n.chave && n.chave === nuvemNote.chave) ||
        (n.numero && nuvemNote.numero && n.numero === nuvemNote.numero)
    );
};

const importFromNuvem = async (note: any) => {
    if (companyStore.isDemoMode) return appStore.showSnackbar('Ação não permitida em modo demonstração', 'warning');
    appStore.showSnackbar('Importando nota para o sistema...', 'info');
    nuvemNotesState.loading = true;
    try {
        let mappedStatus = 'RASCUNHO';
        if (note.status === 'autorizado') mappedStatus = 'AUTORIZADA';
        else if (note.status === 'rejeitado' || note.status === 'erro') mappedStatus = 'REJEITADA';
        else if (note.status === 'cancelado') mappedStatus = 'CANCELADA';
        else if (note.status === 'denegado') mappedStatus = 'REJEITADA';

        const activeCnpj = activeCompany.value?.cnpj?.replace(/\D/g, '') || '';

        const dbData = {
            emitente_cnpj: activeCnpj,
            destinatario_nome: 'Recuperado da Nuvem (Sincronize para Atualizar)',
            valor_total: parseFloat(note.valor_total || 0),
            status: mappedStatus,
            chave: note.chave || null,
            numero: parseInt(note.numero) || 0,
            created_at: note.created_at || new Date().toISOString(),
            retorno_sefaz: {
                id_nuvem: note.id,
                status: note.status,
                motivo_status: note.motivo_status || note.autorizacao?.motivo_status,
                imported_from_cloud: true,
                sync_data: note
            }
        };

        const { error } = await supabase.from('nfe_outbound').insert(dbData);

        if (error) {
            if (error.code === '23505') throw new Error("Uma nota com estes dados já existe.");
            throw error;
        }

        appStore.showSnackbar(`Nota importada com sucesso!`, 'success');
        await fetchHistory();
    } catch (e: any) {
        appStore.showSnackbar(e.message, 'error');
        addLog('ERROR', 'Erro ao importar nota', e);
    } finally {
        nuvemNotesState.loading = false;
    }
};

const markNuvemAsInutilized = async (note: any) => {
    if (companyStore.isDemoMode) return appStore.showSnackbar('Ação não permitida em modo demonstração', 'warning');
    if(!confirm(`Tem certeza que deseja forçar a importação da NFe ${note.numero || ''} como INUTILIZADA? Use isso apenas se a nota já estiver inutilizada na Sefaz.`)) return;

    appStore.showSnackbar('Importando nota como INUTILIZADA...', 'info');
    nuvemNotesState.loading = true;
    try {
        const activeCnpj = activeCompany.value?.cnpj?.replace(/\D/g, '') || '';
        const dbData = {
            emitente_cnpj: activeCnpj,
            destinatario_nome: 'Recuperado da Nuvem (Inutilizada)',
            valor_total: parseFloat(note.valor_total || 0),
            status: 'INUTILIZADA',
            chave: note.chave || null,
            numero: parseInt(note.numero) || 0,
            created_at: note.created_at || new Date().toISOString(),
            retorno_sefaz: {
                id_nuvem: note.id,
                status: note.status,
                motivo_status: 'Forçado como INUTILIZADA manualmente.',
                imported_from_cloud: true,
                sync_data: note
            }
        };

        const { error } = await supabase.from('nfe_outbound').insert(dbData);
        if (error && error.code !== '23505') throw error;

        if (error && error.code === '23505') {
            await supabase.from('nfe_outbound').update({ status: 'INUTILIZADA' }).eq('numero', note.numero).eq('emitente_cnpj', activeCnpj);
        }

        appStore.showSnackbar(`Nota importada como INUTILIZADA com sucesso!`, 'success');
        await fetchHistory();
    } catch (e: any) {
        appStore.showSnackbar(e.message, 'error');
        addLog('ERROR', 'Erro ao forçar inutilização', e);
    } finally {
        nuvemNotesState.loading = false;
    }
};

const inutilizarFromNuvem = (note: any) => {
    nuvemNotesState.show = false;
    openInutModal();
    inutState.numero_inicial = note.numero;
    inutState.numero_final = note.numero;
    inutState.justificativa = 'Numeração rejeitada/pulada por erro de emissão';
};

const inutilizarFromGrid = (note: any) => {
    openInutModal();
    inutState.numero_inicial = note.numero;
    inutState.numero_final = note.numero;
    inutState.justificativa = 'Numeração pulada/rejeitada por erro de emissão';
};

const markAsInutilized = async (note: any) => {
    if (companyStore.isDemoMode) return appStore.showSnackbar('Ação não permitida em modo demonstração', 'warning');
    if(!confirm(`Tem certeza que deseja marcar a NFe ${note.numero || ''} como INUTILIZADA manualmente no sistema local?`)) return;
    try {
        await supabase.from('nfe_outbound').update({ status: 'INUTILIZADA' }).eq('id', note.id);
        appStore.showSnackbar('Status atualizado para INUTILIZADA!', 'success');
        fetchHistory();
    } catch(e: any) {
        appStore.showSnackbar('Erro ao atualizar: ' + e.message, 'error');
    }
};

// Inutilização
const inutState = reactive({
    show: false,
    ano: new Date().getFullYear() % 100,
    serie: 1,
    numero_inicial: null as number | null,
    numero_final: null as number | null,
    justificativa: '',
    loading: false,
    resultadoId: null as string | null,
    status: ''
});

const openInutModal = () => {
    inutState.ano = new Date().getFullYear() % 100;
    inutState.serie = activeCompany.value?.nfe_series || 1;
    inutState.numero_inicial = null;
    inutState.numero_final = null;
    inutState.justificativa = '';
    inutState.resultadoId = null;
    inutState.status = '';
    inutState.show = true;
};

const submitInut = async () => {
    if (companyStore.isDemoMode) return appStore.showSnackbar('Ação não permitida em modo demonstração', 'warning');
    if(!activeCompany.value) return appStore.showSnackbar('Selecione uma empresa', 'warning');
    if(inutState.justificativa.length < 15) return appStore.showSnackbar('A justificativa deve ter no mínimo 15 caracteres', 'warning');
    if(!inutState.numero_inicial || !inutState.numero_final) return appStore.showSnackbar('Informe os números inicial e final', 'warning');
    if(inutState.numero_inicial > inutState.numero_final) return appStore.showSnackbar('Número inicial não pode ser maior que o final', 'warning');

    inutState.loading = true;
    try {
        const activeCnpj = activeCompany.value.cnpj.replace(/\D/g, '');
        const payload: any = {
            ambiente: activeCompany.value.nfe_environment === 'producao' ? 'producao' : 'homologacao',
            cnpj: activeCnpj,
            ano: Number(inutState.ano),
            serie: Number(inutState.serie),
            numero_inicial: Number(inutState.numero_inicial),
            numero_final: Number(inutState.numero_final),
            justificativa: inutState.justificativa
        };

        const res = await sefazService.inutilizarNFe(payload);

        inutState.status = res.status || 'pendente';
        inutState.resultadoId = res.id;

        if (inutState.status === 'registrado') {
            appStore.showSnackbar('Inutilização registrada com sucesso!', 'success');
            addLog('SUCCESS', `Inutilização registrada: Num ${inutState.numero_inicial} a ${inutState.numero_final}`);

            try {
                await supabase.from('nfe_outbound')
                    .update({ status: 'INUTILIZADA' })
                    .eq('emitente_cnpj', activeCompany.value.cnpj)
                    .gte('numero', inutState.numero_inicial)
                    .lte('numero', inutState.numero_final);

                fetchHistory();
            } catch (err) {}

        } else if (inutState.status === 'rejeitado') {
             appStore.showSnackbar('Inutilização rejeitada pela Sefaz.', 'error');
             addLog('ERROR', 'Inutilização rejeitada', res);
        } else {
            appStore.showSnackbar('Inutilização enviada. Atualize o status.', 'info');
        }

    } catch (error: any) {
        const msg = error.message || '';

        if (msg.toLowerCase().includes('já registrada') || msg.includes('206')) {
            appStore.showSnackbar('A Sefaz informou que esta numeração já foi inutilizada anteriormente! Atualizando o sistema...', 'success');
            try {
                await supabase.from('nfe_outbound').update({ status: 'INUTILIZADA' })
                    .eq('emitente_cnpj', activeCompany.value.cnpj)
                    .gte('numero', inutState.numero_inicial)
                    .lte('numero', inutState.numero_final);

                fetchHistory();
                inutState.show = false;
            } catch (err) {}
        } else {
            appStore.showSnackbar(msg, 'error');
            addLog('ERROR', 'Erro ao inutilizar', error);
        }
    } finally {
        inutState.loading = false;
    }
};

const checkInutStatus = async () => {
    if (!inutState.resultadoId) return;
    try {
        const res = await sefazService.consultarInutilizacao(inutState.resultadoId);
        inutState.status = res.status || inutState.status;
        if (inutState.status === 'registrado') {
             appStore.showSnackbar('Inutilização aprovada!', 'success');
             fetchHistory();
        } else {
             appStore.showSnackbar(`Status atual: ${inutState.status}`, 'info');
        }
    } catch (e: any) {
        appStore.showSnackbar('Erro ao consultar status.', 'error');
    }
};

const downloadInut = async (tipo: 'pdf' | 'xml') => {
    if (!inutState.resultadoId) return;
    try {
        appStore.showSnackbar(`Baixando ${tipo.toUpperCase()}...`, 'info');
        const url = sefazService.getInutilizacaoDownloadUrl(tipo, inutState.resultadoId);

        const response = await axios.get(url, { responseType: 'blob' });
        const blob = new Blob([response.data], { type: tipo === 'pdf' ? 'application/pdf' : 'text/xml' });

        if (tipo === 'pdf') {
            if (danfeModal.url) URL.revokeObjectURL(danfeModal.url);
            danfeModal.url = URL.createObjectURL(blob);
            danfeModal.show = true;
            danfeModal.type = 'pdf';
        } else {
            const downloadUrl = URL.createObjectURL(blob);
            const link = document.createElement('a');
            link.href = downloadUrl;
            link.download = `inutilizacao_${inutState.resultadoId}.${tipo}`;
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
            URL.revokeObjectURL(downloadUrl);
            appStore.showSnackbar('Download concluído!', 'success');
        }
    } catch (error: any) {
        appStore.showSnackbar(`Erro ao baixar documento ${tipo.toUpperCase()}.`, 'error');
        addLog('ERROR', `Download ${tipo} inutilização falhou`, error);
    }
};

const nextNfeNumber = ref(0);

const page = ref(1);
const itemsPerPage = 20;
const currentPeriod = ref('month');
const periodLabel = computed(() => {
    const map: any = { 'month': 'Este Mês', 'week': 'Esta Semana', 'today': 'Hoje', 'all': 'Todos' };
    return map[currentPeriod.value] || 'Período';
});
const setPeriod = (val: string) => { currentPeriod.value = val; page.value = 1; };

const showOrderModal = ref(false);
const selectedOrderId = ref<string>('');

const errorDialog = reactive({ show: false, message: '' });
const danfeModal = reactive({ show: false, url: '', type: 'pdf' });

const systemLogs = ref<any[]>([]);
const addLog = (type: string, message: string, details?: any) => {
    systemLogs.value.unshift({ time: new Date().toLocaleTimeString(), type, message, details: details ? JSON.stringify(details, null, 2) : null });
};
const getLogColor = (t: string) => t === 'ERROR' ? 'text-red' : t === 'SUCCESS' ? 'text-success' : 'text-primary';
const errorCount = computed(() => systemLogs.value.filter(l => l.type === 'ERROR').length);

const filteredNotes = computed(() => {
    let list = [...notes.value];

    if (activeCompany.value) {
        const activeCnpj = activeCompany.value.cnpj.replace(/\D/g, '');
        list = list.filter(n => n.emitente_cnpj && n.emitente_cnpj.replace(/\D/g, '') === activeCnpj);
    }

    if (filterStatus.value !== 'TODOS') list = list.filter(n => n.status === filterStatus.value);

    if (currentPeriod.value !== 'all') {
        const now = new Date();
        let start, end;
        if (currentPeriod.value === 'month') { start = startOfMonth(now); end = endOfMonth(now); }
        else if (currentPeriod.value === 'week') { start = startOfWeek(now); end = endOfWeek(now); }
        else if (currentPeriod.value === 'today') { start = now; end = now; }

        if (start && end) {
            list = list.filter(n => {
                if(!n.created_at) return false;
                const d = parseISO(n.created_at);
                if (currentPeriod.value === 'today') return isSameDay(d, now);
                return d >= start && d <= end;
            });
        }
    }

    if (search.value) {
        const term = search.value.toLowerCase();
        list = list.filter(n => (n.destinatario_nome && String(n.destinatario_nome).toLowerCase().includes(term)) || (n.numero && String(n.numero).includes(term)) || (n.chave && String(n.chave).includes(term)));
    }
    return list.sort((a,b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime());
});

const pageCount = computed(() => Math.ceil(filteredNotes.value.length / itemsPerPage));
const paginatedNotes = computed(() => {
    const start = (page.value - 1) * itemsPerPage;
    return filteredNotes.value.slice(start, start + itemsPerPage);
});

const totalValue = computed(() => filteredNotes.value.filter(n => n.status === 'AUTORIZADA' || n.status === 'CORRIGIDA').reduce((acc, n) => acc + (Number(n.valor_total) || 0), 0));

watch(activeCompany, (newVal) => {
    if (newVal && !isCompanyAllowed(newVal)) {
        const scoped = getScopedCompany();
        if (scoped && scoped.id !== newVal.id) activeCompany.value = scoped;
        return;
    }

    fetchHistory();
    if(newVal) nextNfeNumber.value = Number(newVal.nfe_next_number || 0) + 1;
});

const loadCompanies = async () => {
    loadingCompanies.value = true;

    // INTERCEPTADOR DE MODO DEMO
    if (companyStore.isDemoMode) {
        companies.value = [
            { id: 'fake-comp-1', name: 'INDÚSTRIA FICTÍCIA S.A.', trade_name: 'INDÚSTRIA FICTÍCIA', cnpj: '00.000.000/0001-00', nfe_environment: 'producao', nfe_series: 1, nfe_next_number: 15420, status: 'active', ie: '123456789' },
            { id: 'fake-comp-2', name: 'VAREJO FICTÍCIO LTDA.', trade_name: 'VAREJO FICTÍCIO', cnpj: '11.111.111/0001-11', nfe_environment: 'producao', nfe_series: 2, nfe_next_number: 5432, status: 'active', ie: '987654321' }
        ];

        companies.value = applyTenantScopeToCompanies(companies.value);

        if (companies.value.length > 0 && !activeCompany.value) {
            selectInitialCompany();
        }
        loadingCompanies.value = false;
        return;
    }

    try {
        // 1. Busca TODAS as empresas do seu banco de dados local como fonte da verdade
        const { data: dbCompanies } = await supabase.from('companies').select('*');

        // 2. Tenta buscar na Nuvem Fiscal para mesclar dados extras
        let nuvemCompanies = [];
        try {
            const nuvemResponse = await sefazService.listarEmpresas();
            nuvemCompanies = nuvemResponse.data || (Array.isArray(nuvemResponse) ? nuvemResponse : []);
        } catch (e) {
            console.warn("Nuvem Fiscal não retornou empresas. Usando base local exclusivamente.");
        }

        // 3. Mapeia usando as empresas do BANCO (dbCompanies) como loop principal
        companies.value = (dbCompanies || []).map((dbc: any) => {
            const nc = nuvemCompanies.find((n: any) => n.cnpj?.replace(/\D/g, '') === dbc.cnpj?.replace(/\D/g, '')) || {};
            const crtRaw = dbc.crt;
            const crtFinal = (crtRaw !== undefined && crtRaw !== null) ? String(crtRaw) : '1';

            return {
                ...nc,
                ...dbc, // Garante que os dados locais predominem
                id: dbc.id,
                name: dbc.trade_name || dbc.name || nc.nome || 'Empresa Sem Nome',
                nfe_environment: dbc.nfe_environment || 'homologacao',
                nfe_series: dbc.nfe_series || 1,
                nfe_next_number: parseInt(dbc.nfe_next_number) || 0,
                crt: crtFinal,
                ie: dbc.ie || nc.inscricao_estadual
            };
        });

        companies.value = applyTenantScopeToCompanies(companies.value);

        if (companies.value.length > 0 && !activeCompany.value) {
            selectInitialCompany();
        }
    } catch (e: any) {
        addLog('ERROR', 'Erro fatal ao carregar empresas', e.message);
    } finally {
        loadingCompanies.value = false;
    }
};

// Modificado para comunicar com a store global com trava de tenant para funcionários
const switchCompany = (company: any) => {
    if (!isCompanyAllowed(company)) {
        const scoped = getScopedCompany();
        if (scoped) syncActiveCompany(scoped);
        appStore.showSnackbar('Você só pode acessar as NF-e da empresa vinculada ao seu usuário.', 'warning');
        return;
    }

    syncActiveCompany(company);
    fetchHistory();
};

const fetchHistory = async () => {
    loading.value = true;

    // INTERCEPTADOR DE MODO DEMO
    if (companyStore.isDemoMode) {
        const activeCnpj = activeCompany.value?.cnpj?.replace(/\D/g, '') || '00000000000100';
        const today = new Date().toISOString();
        const yesterday = new Date(Date.now() - 86400000).toISOString();

        notes.value = [
            { id: 'fake-nfe-1', numero: 15419, destinatario_nome: 'Cliente Fictício 1', natureza_operacao: 'VENDA DE MERCADORIA', chave: '35260300000000000100550010000154191000154191', status: 'AUTORIZADA', created_at: today, valor_total: 12500.50, emitente_cnpj: activeCnpj, order_number_display: 1050 },
            { id: 'fake-nfe-2', numero: 15420, destinatario_nome: 'Cliente Fictício 2', natureza_operacao: 'VENDA DE MERCADORIA', chave: null, status: 'RASCUNHO', created_at: today, valor_total: 3450.00, emitente_cnpj: activeCnpj, order_number_display: 1051 },
            { id: 'fake-nfe-3', numero: 15418, destinatario_nome: 'Consumidor Final', natureza_operacao: 'VENDA DE MERCADORIA', chave: '35260300000000000100550010000154181000154181', status: 'REJEITADA', created_at: yesterday, valor_total: 450.00, emitente_cnpj: activeCnpj, retorno_sefaz: { details: 'Rejeição 539: Duplicidade de NFe com diferença na Chave de Acesso' } },
            { id: 'fake-nfe-4', numero: 15417, destinatario_nome: 'Fornecedor Fictício (Devolução)', natureza_operacao: 'DEVOLUÇÃO DE COMPRA', chave: '35260300000000000100550010000154171000154171', status: 'AUTORIZADA', created_at: yesterday, valor_total: 1200.00, emitente_cnpj: activeCnpj },
            { id: 'fake-nfe-5', numero: 15416, destinatario_nome: 'Nota Inutilizada', natureza_operacao: 'N/A', chave: null, status: 'INUTILIZADA', created_at: yesterday, valor_total: 0, emitente_cnpj: activeCnpj }
        ];
        loading.value = false;
        return;
    }

    try {
        const scopedCompany = getScopedCompany();

        if (!scopedCompany) {
            notes.value = [];
            return;
        }

        if (activeCompany.value?.id !== scopedCompany.id) {
            activeCompany.value = scopedCompany;
        }

        const rawCnpj = String(scopedCompany.cnpj || '');
        const cleanCnpj = normalizeCnpj(rawCnpj);

        let query = supabase.from('nfe_outbound').select('*');

        if (rawCnpj && cleanCnpj && rawCnpj !== cleanCnpj) {
            query = query.or(`emitente_cnpj.eq.${rawCnpj},emitente_cnpj.eq.${cleanCnpj}`);
        } else if (cleanCnpj) {
            query = query.eq('emitente_cnpj', cleanCnpj);
        }

        const { data } = await query;
        notes.value = (data || []).filter(note => normalizeCnpj(note.emitente_cnpj) === cleanCnpj);
        if(notes.value.length > 0) await fetchOrdersForNotes(notes.value);
    } finally { loading.value = false; }
};

const fetchOrdersForNotes = async (notesList: any[]) => {
    const keys = notesList.map(n => n.chave).filter(k => k);
    if(keys.length === 0) return;

    try {
        const { data: ordersData } = await supabase.from('orders').select('id, order_number, nfe_key').in('nfe_key', keys);
        const { data: salesData } = await supabase.from('store_sales').select('id, order_number, nfe_key').in('nfe_key', keys);

        notes.value = notes.value.map(note => {
            let updatedNote = { ...note };

            const foundOrder = (ordersData || []).find(o => o.nfe_key === note.chave);
            if(foundOrder) {
                updatedNote.order_id = foundOrder.id;
                updatedNote.order_number_display = foundOrder.order_number;
            } else {
                const foundSale = (salesData || []).find(s => s.nfe_key === note.chave);
                if (foundSale) {
                    updatedNote.order_id = foundSale.id;
                    updatedNote.order_number_display = `PDV-${foundSale.order_number}`;
                }
            }
            return updatedNote;
        });
    } catch(e) {}
};

const getOrderNumber = (note: any) => {
    return note.order_number_display || note.order_id || note.pedido_id || null;
};

const openOrderModal = (note: any) => {
    const id = note.order_id || note.pedido_id;
    if (id && !String(note.order_number_display).startsWith('PDV-')) {
        selectedOrderId.value = String(id);
        showOrderModal.value = true;
    } else if (id && String(note.order_number_display).startsWith('PDV-')) {
        appStore.showSnackbar('Vínculo com Venda Balcão (PDV). Verifique o registro na tela de Vendas.', 'info');
    }
};

const openLinkOrderModal = (note: any) => {
    if (!note.chave) return appStore.showSnackbar('A nota precisa estar autorizada (com Chave) para ser vinculada.', 'warning');
    linkOrderState.note = note;
    linkOrderState.orderType = 'orders';
    linkOrderState.orderNumber = '';
    linkOrderState.show = true;
};

const confirmLinkOrder = async () => {
    if (companyStore.isDemoMode) return appStore.showSnackbar('Ação não permitida em modo demonstração', 'warning');
    if (!linkOrderState.orderNumber) return;
    linkOrderState.loading = true;
    try {
        const table = linkOrderState.orderType;
        const column = 'order_number';

        const { data: orderData, error: searchError } = await supabase
            .from(table)
            .select('id')
            .eq(column, linkOrderState.orderNumber)
            .single();

        if (searchError || !orderData) throw new Error("Registro não encontrado no sistema.");

        const { error: updateError } = await supabase
            .from(table)
            .update({ nfe_key: linkOrderState.note.chave })
            .eq('id', orderData.id);

        if (updateError) throw updateError;

        appStore.showSnackbar(`Nota vinculada com sucesso!`, 'success');
        linkOrderState.show = false;
        fetchHistory();
    } catch (e: any) {
        appStore.showSnackbar(e.message, 'error');
    } finally {
        linkOrderState.loading = false;
    }
};

const openCceModal = (note: any) => {
    if(!note.retorno_sefaz?.id && !note.retorno_sefaz?.id_nuvem) return appStore.showSnackbar('Nota importada não suporta envio de CC-e pelo sistema.', 'warning');
    cceState.note = note; cceState.text = ''; cceState.show = true;
};

const submitCce = async () => {
    if (companyStore.isDemoMode) return appStore.showSnackbar('Ação não permitida em modo demonstração', 'warning');
    if(cceState.text.length < 15) return appStore.showSnackbar('A correção deve ter no mínimo 15 caracteres.', 'warning');
    cceState.loading = true;
    try {
        const nuvemId = cceState.note.retorno_sefaz?.id_nuvem || cceState.note.retorno_sefaz?.id;
        const res = await axios.post(`${SEFAZ_PROXY_URL}/api/nfe/${nuvemId}/carta-correcao`, { correcao: cceState.text });
        const cceData = res.data.data;
        const novoRetorno = { ...cceState.note.retorno_sefaz, cce: cceData };

        await supabase.from('nfe_outbound').update({ status: 'CORRIGIDA', retorno_sefaz: novoRetorno }).eq('id', cceState.note.id);
        appStore.showSnackbar('Carta de Correção registrada com sucesso!', 'success');
        addLog('SUCCESS', `CC-e registrada para nota ${cceState.note.numero}`);
        cceState.show = false; fetchHistory();
    } catch(e: any) {
        appStore.showSnackbar('Erro ao enviar CC-e: ' + (e.response?.data?.message || e.message), 'error');
        addLog('ERROR', 'Erro ao enviar CC-e', e.response?.data || e);
    } finally { cceState.loading = false; }
};

const downloadCce = async (note: any, type: 'pdf' | 'xml') => {
    try {
        appStore.showSnackbar(`Obtendo ${type.toUpperCase()} da Carta de Correção...`, 'info');
        const nuvemId = note.retorno_sefaz?.id_nuvem || note.retorno_sefaz?.id;
        const response = await axios.get(`${SEFAZ_PROXY_URL}/api/nfe/${nuvemId}/carta-correcao/download/${type}`, { responseType: 'blob' });
        const blob = new Blob([response.data], { type: type === 'pdf' ? 'application/pdf' : 'text/xml' });
        const downloadUrl = URL.createObjectURL(blob);

        if (type === 'pdf') { danfeModal.url = downloadUrl; danfeModal.show = true; danfeModal.type = 'pdf'; }
        else {
            const link = document.createElement('a'); link.href = downloadUrl; link.download = `cce_${note.numero || 'nota'}.${type}`;
            document.body.appendChild(link); link.click(); document.body.removeChild(link); URL.revokeObjectURL(downloadUrl);
            appStore.showSnackbar('Download concluído!', 'success');
        }
    } catch (e: any) {
        const fallbackUrl = type === 'pdf' ? note.retorno_sefaz?.cce?.pdf_url : note.retorno_sefaz?.cce?.xml_url;
        if (fallbackUrl) window.open(fallbackUrl, '_blank'); else appStore.showSnackbar('Erro ao baixar documento da CC-e.', 'error');
    }
};

const openEmailModal = (note: any) => {
    if(!note.retorno_sefaz?.id && !note.retorno_sefaz?.id_nuvem) return appStore.showSnackbar('Nota importada não suporta envio de e-mail pelo sistema.', 'warning');
    emailState.note = note; emailState.email = note.destinatario_nome ? (note.retorno_sefaz?.payload?.destinatario?.email || '') : ''; emailState.show = true;
};

const submitEmail = async () => {
    if (companyStore.isDemoMode) return appStore.showSnackbar('Ação não permitida em modo demonstração', 'warning');
    if(!emailState.email) return appStore.showSnackbar('Informe um email.', 'warning');
    emailState.loading = true;
    try {
        const nuvemId = emailState.note.retorno_sefaz?.id_nuvem || emailState.note.retorno_sefaz?.id;
        const destinatarios = emailState.email.split(',').map(e => ({ email: e.trim() }));
        await axios.post(`${SEFAZ_PROXY_URL}/api/nfe/${nuvemId}/email`, { destinatarios });
        appStore.showSnackbar('E-mail enviado com sucesso!', 'success');
        emailState.show = false;
    } catch(e: any) { appStore.showSnackbar('Erro ao enviar E-mail.', 'error'); } finally { emailState.loading = false; }
};

const syncNfe = async (note: any) => {
    if (companyStore.isDemoMode) return appStore.showSnackbar('Ação não permitida em modo demonstração', 'warning');
    const nuvemId = note.retorno_sefaz?.id_nuvem || note.retorno_sefaz?.id;
    if(!nuvemId) return appStore.showSnackbar('Nota sem ID na API (importada).', 'warning');
    appStore.showSnackbar('Sincronizando com a Sefaz...', 'info');
    try {
        const res = await axios.get(`${SEFAZ_PROXY_URL}/api/nfe/${nuvemId}/sincronizar`);
        const data = res.data;
        const status = data.status ? data.status.toLowerCase() : '';
        let newStatus = note.status;

        if (status === 'autorizado' || status === 'autorizada') newStatus = 'AUTORIZADA';
        else if (status === 'cancelado' || status === 'cancelada') newStatus = 'CANCELADA';
        else if (status === 'rejeitado' || status === 'erro') newStatus = 'REJEITADA';

        await supabase.from('nfe_outbound').update({ status: newStatus, retorno_sefaz: { ...note.retorno_sefaz, sync_data: data } }).eq('id', note.id);
        appStore.showSnackbar(`Sincronizado! Status atual: ${newStatus}`, 'success');
        fetchHistory();
    } catch(e: any) { appStore.showSnackbar('Erro na sincronização.', 'error'); addLog('ERROR', 'Erro na sincronização', e.response?.data || e); }
};

// --- DOWNLOAD EM LOTE DE NFE ---
const downloadBulkXML = async () => {
    if (!activeCompany.value) return appStore.showSnackbar('Selecione uma empresa.', 'warning');
    if (!bulkDownloadModal.startDate || !bulkDownloadModal.endDate) return appStore.showSnackbar('Selecione o período.', 'warning');

    bulkDownloadModal.downloading = true;
    bulkDownloadModal.progress.show = false;

    try {
        const cnpjFiltro = String(activeCompany.value.cnpj).replace(/\D/g, '');

        let query = supabase.from('nfe_outbound')
            .select('id, numero, chave, retorno_sefaz, emitente_cnpj')
            .eq('emitente_cnpj', cnpjFiltro)
            .gte('created_at', `${bulkDownloadModal.startDate}T00:00:00.000Z`)
            .lte('created_at', `${bulkDownloadModal.endDate}T23:59:59.999Z`);

        if (bulkDownloadModal.status !== 'TODOS') {
            if (bulkDownloadModal.status === 'AUTORIZADA') {
                query = query.in('status', ['AUTORIZADA', 'CORRIGIDA']);
            } else {
                query = query.eq('status', bulkDownloadModal.status);
            }
        }

        const { data, error } = await query;

        if (error || !data || data.length === 0) {
            appStore.showSnackbar('Nenhuma NF-e encontrada neste período e status.', 'warning');
            return;
        }

        bulkDownloadModal.progress.total = data.length;
        bulkDownloadModal.progress.current = 0;
        bulkDownloadModal.progress.show = true;

        const zip = new JSZip();

        for (const nota of data) {
            try {
                let url = '';
                const nuvemId = nota.retorno_sefaz?.id_nuvem || nota.retorno_sefaz?.id;

                if (nuvemId) {
                    url = `${SEFAZ_PROXY_URL}/api/nfe/download/xml/${nuvemId}`;
                } else if (nota.chave) {
                    url = `${SEFAZ_PROXY_URL}/api/baixar-xml/${nota.chave}?cnpj=${cnpjFiltro}`;
                }

                if (url) {
                    const response = await fetch(url);
                    if (response.ok) {
                        const xmlText = await response.text();
                        zip.file(`NFe_${nota.numero}_${cnpjFiltro}.xml`, xmlText);
                    }
                } else if (nota.retorno_sefaz?.payload?.imported && nota.retorno_sefaz?.payload?.xml_raw) {
                    zip.file(`NFe_${nota.numero}_${cnpjFiltro}_importada.xml`, nota.retorno_sefaz.payload.xml_raw);
                }
            } catch (err) {
                console.error(`Erro no download da nota ${nota.numero}`);
            }
            bulkDownloadModal.progress.current++;
        }

        const zipBlob = await zip.generateAsync({ type: 'blob' });
        const downloadUrl = window.URL.createObjectURL(zipBlob);

        const a = document.createElement('a');
        a.href = downloadUrl;
        a.download = `Lote_NFe_${activeCompany.value.name.substring(0,10)}_${bulkDownloadModal.startDate}.zip`;
        document.body.appendChild(a);
        a.click();

        document.body.removeChild(a);
        window.URL.revokeObjectURL(downloadUrl);

        appStore.showSnackbar(`Download de ${data.length} XML(s) finalizado!`, 'success');

        // Fecha o modal suavemente 1 segundo após concluir para dar tempo de ler "Compactando arquivo ZIP..."
        setTimeout(() => { bulkDownloadModal.show = false; }, 1000);
    } catch (error: any) {
        console.error(error);
        appStore.showSnackbar(error.message || 'Erro crítico ao empacotar XMLs.', 'error');
    } finally {
        bulkDownloadModal.downloading = false;
    }
};

const copyToClipboard = (text: string, id: string) => { navigator.clipboard.writeText(text).then(() => { copiedId.value = id; setTimeout(() => copiedId.value = null, 2000); }); };

const openNewNoteModal = () => {
    editingDraftId.value = null;
    draftPayload.value = null;
    showIssueModal.value = true;
};

const editDraft = (note: any) => {
    const data = note.retorno_sefaz?.payload || note.retorno_sefaz;
    if (data) {
        draftPayload.value = data;
        editingDraftId.value = note.id;
        showIssueModal.value = true;
    }
};

const emitDraft = (note: any) => {
    if (companyStore.isDemoMode) return appStore.showSnackbar('Ação não permitida em modo demonstração', 'warning');
    editDraft(note);
};

const cloneNote = async (note: any) => {
    if (companyStore.isDemoMode) return appStore.showSnackbar('Ação não permitida em modo demonstração', 'warning');
    try {
        await loadCompanies();
        const company = activeCompany.value;
        if(!company) throw new Error("Empresa não selecionada");

        const newNumber = parseInt(company.nfe_next_number || 0) + 1;
        const sourceData = note.retorno_sefaz?.payload ? JSON.parse(JSON.stringify(note.retorno_sefaz.payload)) : {};

        if (!note.retorno_sefaz?.payload) {
             sourceData.destinatario = { nome: note.destinatario_nome };
        }

        sourceData.chave = null;
        sourceData.protocolo = null;
        sourceData.data_emissao = new Date().toISOString().slice(0, 16);
        sourceData.data_saida = new Date().toISOString().slice(0, 16);
        sourceData.numero = newNumber;
        sourceData.ide = null;

        const { data: draft, error } = await supabase.from('nfe_outbound').insert({
            emitente_cnpj: company.cnpj,
            destinatario_nome: sourceData.destinatario?.nome || 'Clonada',
            valor_total: note.valor_total,
            status: 'RASCUNHO',
            numero: newNumber,
            retorno_sefaz: { payload: sourceData }
        }).select().single();

        if (error) throw error;

        editingDraftId.value = draft.id;
        draftPayload.value = sourceData;
        showIssueModal.value = true;

        fetchHistory();
        appStore.showSnackbar(`Nota ${newNumber} criada como rascunho!`, 'success');

    } catch (e: any) {
        appStore.showSnackbar('Erro ao clonar: ' + e.message, 'error');
    }
};

const openXmlImportModal = () => {
    xmlImportModal.isOrder = false;
    xmlImportModal.orderType = 'orders';
    xmlImportModal.orderNumber = '';
    xmlImportModal.show = true;
};

const confirmXmlImport = () => {
    if (companyStore.isDemoMode) return appStore.showSnackbar('Ação não permitida em modo demonstração', 'warning');
    if (xmlImportModal.isOrder && !xmlImportModal.orderNumber) return appStore.showSnackbar('Informe o número do registro.', 'warning');
    if (xmlFileInput.value) xmlFileInput.value.click();
    xmlImportModal.show = false;
};

const handleXmlImport = async (event: Event) => {
    const target = event.target as HTMLInputElement;
    const file = target.files?.[0];
    if (!file) return;

    importingXml.value = true;
    try {
        const text = await file.text();
        await parseAndSaveXml(text);
    } catch (error: any) {
        appStore.showSnackbar(`Erro ao ler arquivo: ${error.message}`, 'error');
        addLog('ERROR', 'Erro leitura XML', error);
    } finally { importingXml.value = false; target.value = ''; }
};

const parseAndSaveXml = async (xmlString: string) => {
    const parser = new DOMParser();
    const xmlDoc = parser.parseFromString(xmlString, "text/xml");

    const infNFe = xmlDoc.getElementsByTagName('infNFe')[0];
    if (!infNFe) throw new Error("XML inválido: infNFe não encontrado");

    const emit = xmlDoc.getElementsByTagName('emit')[0];
    const dest = xmlDoc.getElementsByTagName('dest')[0];
    const total = xmlDoc.getElementsByTagName('total')[0];
    const protNFe = xmlDoc.getElementsByTagName('protNFe')[0];
    const ide = xmlDoc.getElementsByTagName('ide')[0];

    const chave = infNFe.getAttribute('Id')?.replace('NFe', '') || '';
    const cnpjEmit = emit?.getElementsByTagName('CNPJ')[0]?.textContent || '';
    const nomeDest = dest?.getElementsByTagName('xNome')[0]?.textContent || 'Destinatário Desconhecido';
    const vNF = total?.getElementsByTagName('vNF')[0]?.textContent || '0';
    const numero = ide?.getElementsByTagName('nNF')[0]?.textContent || '';
    const dataEmissao = ide?.getElementsByTagName('dhEmi')[0]?.textContent || new Date().toISOString();

    const cStat = protNFe?.getElementsByTagName('cStat')[0]?.textContent;
    const isAutorizada = cStat === '100' || protNFe != null;
    const status = isAutorizada ? 'AUTORIZADA' : 'RASCUNHO';

    const activeCnpj = activeCompany.value?.cnpj?.replace(/\D/g, '') || '';

    const dbData = {
        emitente_cnpj: cnpjEmit || activeCnpj,
        destinatario_nome: nomeDest,
        valor_total: parseFloat(vNF),
        status: status,
        chave: chave,
        numero: parseInt(numero) || 0,
        created_at: dataEmissao,
        retorno_sefaz: { payload: { imported: true, xml_raw: xmlString } }
    };

    const { error } = await supabase.from('nfe_outbound').insert(dbData);
    if (error) {
        if (error.code === '23505') throw new Error("Esta NFe já foi importada (chave duplicada).");
        throw error;
    }

    if (xmlImportModal.isOrder && xmlImportModal.orderNumber) {
        try {
            const table = xmlImportModal.orderType;
            const column = 'order_number';
            const { data: orderData, error: searchError } = await supabase.from(table).select('id').eq(column, xmlImportModal.orderNumber).single();
            if (!searchError && orderData) {
                await supabase.from(table).update({ nfe_key: chave }).eq('id', orderData.id);
                appStore.showSnackbar(`XML importado e vinculado ao registro #${xmlImportModal.orderNumber}!`, 'success');
            } else appStore.showSnackbar(`XML importado, mas registro #${xmlImportModal.orderNumber} não encontrado.`, 'warning');
        } catch(e) {}
    } else {
        appStore.showSnackbar(`XML importado com sucesso! NFe: ${numero}`, 'success');
    }
    addLog('SUCCESS', `XML importado NFe ${numero}`);
    fetchHistory();
};

const retryEmission = (note: any) => {
    editDraft(note);
    if(note.retorno_sefaz?.details) {
        errorDialog.message = typeof note.retorno_sefaz.details === 'string' ? note.retorno_sefaz.details : JSON.stringify(note.retorno_sefaz.details, null, 2);
        errorDialog.show = true;
    }
};

const deleteDraft = async (note: any) => {
    if (companyStore.isDemoMode) return appStore.showSnackbar('Ação não permitida em modo demonstração', 'warning');
    if(!confirm('Excluir?')) return;
    await supabase.from('nfe_outbound').delete().eq('id', note.id);
    fetchHistory();
};

const cancelNote = async (note: any) => {
    if (companyStore.isDemoMode) return appStore.showSnackbar('Ação não permitida em modo demonstração', 'warning');
    const just = prompt('Justificativa (mín 15 chars):');
    if (!just || just.length < 15) return alert('Justificativa curta.');

    try {
        const nuvemId = note.retorno_sefaz?.id_nuvem || note.retorno_sefaz?.id;
        if (!nuvemId) return appStore.showSnackbar('ID da nota não encontrado no banco de dados.', 'error');

        await sefazService.cancelarNFe(nuvemId, just);
        await supabase.from('nfe_outbound').update({ status: 'CANCELADA' }).eq('id', note.id);
        fetchHistory();
        appStore.showSnackbar('Nota Cancelada com Sucesso!', 'success');
    } catch(e: any) { appStore.showSnackbar(e.message, 'error'); }
};

const shareWhatsapp = (note: any) => { window.open(`https://wa.me/?text=${encodeURIComponent(`Olá, segue link da sua NFe: ${note.pdf_link || note.xml_link}`)}`, '_blank'); };

const viewDocument = async (note: any, type: 'pdf' | 'xml') => {
    if (type === 'pdf') {
        if (danfeModal.url) URL.revokeObjectURL(danfeModal.url);
        danfeModal.url = ''; danfeModal.show = true; danfeModal.type = 'pdf';
    }

    try {
        appStore.showSnackbar('Obtendo documento...', 'info');

        if (note.retorno_sefaz?.payload?.imported && note.retorno_sefaz?.payload?.xml_raw) {
            const rawXml = note.retorno_sefaz.payload.xml_raw;
            if (type === 'xml') {
                const blob = new Blob([rawXml], { type: 'text/xml' });
                const downloadUrl = URL.createObjectURL(blob);
                const link = document.createElement('a'); link.href = downloadUrl; link.download = `${note.chave || note.numero || 'nota_importada'}.xml`;
                document.body.appendChild(link); link.click(); document.body.removeChild(link); URL.revokeObjectURL(downloadUrl);
                appStore.showSnackbar('XML baixado com sucesso!', 'success'); return;
            } else {
                appStore.showSnackbar('Gerando DANFE localmente do XML importado...', 'info');
                try {
                    let safeXml = rawXml.replace(/<dup>(?![\s\S]*?<nDup>.*<\/nDup>)[\s\S]*?<\/dup>/g, '').replace(/<dup>\s*<\/dup>/g, '').replace(/<dup\s*\/>/g, '').replace(/<fat>\s*<\/fat>/g, '').replace(/<fat\s*\/>/g, '').replace(/<cobr>\s*<\/cobr>/g, '').replace(/<cobr\s*\/>/g, '').replace(/<dVenc>(\d{4}-\d{2}-\d{2})<\/dVenc>/g, '<dVenc>$1T12:00:00</dVenc>').replace(/<dhEmi>(\d{4}-\d{2}-\d{2})<\/dhEmi>/g, '<dhEmi>$1T12:00:00</dhEmi>');
                    const pdfResult = await DANFe({ xml: safeXml });
                    const pdfBytes = (pdfResult instanceof Blob) ? await pdfResult.arrayBuffer() : pdfResult;
                    const blob = new Blob([pdfBytes], { type: 'application/pdf' });
                    danfeModal.url = URL.createObjectURL(blob);
                } catch (err) { appStore.showSnackbar('Falha ao gerar o PDF. O XML importado possui estrutura corrompida ou fora do padrão.', 'error'); danfeModal.show = false; }
                return;
            }
        }

        const nuvemId = note.retorno_sefaz?.id_nuvem || note.retorno_sefaz?.id;
        const cnpj = note.emitente_cnpj ? note.emitente_cnpj.replace(/\D/g, '') : activeCompany.value.cnpj.replace(/\D/g, '');
        let url = '';

        if (nuvemId) url = `${SEFAZ_PROXY_URL}/api/nfe/download/${type}/${nuvemId}`;
        else if (note.chave) url = `${SEFAZ_PROXY_URL}/api/${type === 'pdf' ? 'danfe' : 'baixar-xml'}/${note.chave}?cnpj=${cnpj}`;
        else throw new Error('Nota sem ID e sem Chave de Acesso.');

        const response = await axios.get(url, { responseType: 'blob' });

        if (type === 'pdf') {
            const blob = new Blob([response.data], { type: 'application/pdf' });
            danfeModal.url = URL.createObjectURL(blob);
        } else {
            const blob = new Blob([response.data], { type: 'text/xml' });
            const downloadUrl = URL.createObjectURL(blob);
            const link = document.createElement('a'); link.href = downloadUrl; link.download = `${note.chave || note.numero || 'nota'}.xml`;
            document.body.appendChild(link); link.click(); document.body.removeChild(link); URL.revokeObjectURL(downloadUrl);
            appStore.showSnackbar('Download concluído!', 'success');
        }

    } catch (e: any) {
        let errorMsg = 'Erro ao baixar documento.';
        if (e.response?.data instanceof Blob && e.response.data.type === 'application/json') {
            try {
                const text = await e.response.data.text();
                const json = JSON.parse(text);
                errorMsg = `Erro API: ${json.message || json.error || JSON.stringify(json)}`;
                errorDialog.message = JSON.stringify(json, null, 2);
                errorDialog.show = true;
            } catch (err) {}
        } else if (e.message) errorMsg = e.message;

        appStore.showSnackbar(errorMsg, 'error'); danfeModal.show = false;
        if (type === 'pdf' && note.pdf_link && note.pdf_link.startsWith('http')) {
             if(confirm('Falha ao gerar pelo sistema. Tentar abrir link externo salvo?')) window.open(note.pdf_link, '_blank');
        }
    }
};

const showErrorDetails = (note: any) => {
    let msg = 'Erro desconhecido.';
    const sfz = note.retorno_sefaz || {};
    const det = sfz.error || sfz.sync_data?.autorizacao?.motivo_status || sfz.sync_data?.motivo_status || sfz.details || sfz.motivo_status;
    if (det) msg = typeof det === 'string' ? det : JSON.stringify(det, null, 2);
    errorDialog.message = msg;
    errorDialog.show = true;
};

const checkCertificate = () => {
    if (companyStore.isDemoMode) return appStore.showSnackbar('Status Sefaz indisponível no Modo Demo', 'info');
    appStore.showSnackbar('Verificando Sefaz...', 'info');
}

const isActionDisabled = (action: string, note: any) => {
    if (action === 'edit') return note.status === 'AUTORIZADA' || note.status === 'CORRIGIDA' || note.status === 'CANCELADA' || note.status === 'INUTILIZADA';
    if (action === 'emit') return note.status !== 'RASCUNHO';
    if (action === 'pdf' || action === 'xml') return note.status !== 'AUTORIZADA' && note.status !== 'CORRIGIDA';
    if (action === 'cancel') return note.status !== 'AUTORIZADA' && note.status !== 'CORRIGIDA';
    if (action === 'delete') return note.status === 'AUTORIZADA' || note.status === 'CORRIGIDA';
    return false;
};

const formatCurrency = (v: any) => new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(Number(v)||0);
const formatCompact = (v: any) => new Intl.NumberFormat('pt-BR', { notation: "compact", style: 'currency', currency: 'BRL' }).format(Number(v)||0);
const formatDate = (d: string) => d ? format(parseISO(d), 'dd/MM/yy') : '-';
const getStatusColor = (s: string) => (s === 'AUTORIZADA' || s === 'CORRIGIDA') ? 'success' : s === 'RASCUNHO' ? 'warning' : s === 'INUTILIZADA' ? 'grey' : 'error';
const getChipClass = (s: string) => s === 'AUTORIZADA' ? 'chip-success' : s === 'CORRIGIDA' ? 'chip-warning' : s === 'RASCUNHO' ? 'chip-warning' : s === 'INUTILIZADA' ? 'bg-grey-darken-2 text-white' : 'chip-danger';
const zebraClass = (i: number) => themeStore.currentMode !== 'light' ? (i % 2 === 0 ? 'zebra-dark-a' : 'zebra-dark-b') : (i % 2 === 0 ? 'zebra-light-a' : 'zebra-light-b');

const generateAndPrintReport = () => {
    let list = [...notes.value];
    if (activeCompany.value) {
        const activeCnpj = activeCompany.value.cnpj.replace(/\D/g, '');
        list = list.filter(n => n.emitente_cnpj && n.emitente_cnpj.replace(/\D/g, '') === activeCnpj);
    }
    const start = new Date(`${reportModal.startDate}T00:00:00`);
    const end = new Date(`${reportModal.endDate}T23:59:59`);
    list = list.filter(n => { if(!n.created_at) return false; const d = new Date(n.created_at); return d >= start && d <= end; });
    list.sort((a,b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime());

    if (list.length === 0) return appStore.showSnackbar('Nenhuma nota encontrada no período selecionado.', 'warning');

    const companyName = activeCompany.value?.name?.toLowerCase() || '';
    const isSantosELopes = companyName.includes('santos') || companyName.includes('lopes') || companyName.includes('cajuia');
    const logoUrl = isSantosELopes ? logoCajuia : logoMjlm;

    const notasAutorizadas = list.filter(n => n.status === 'AUTORIZADA' || n.status === 'CORRIGIDA').length;
    const faturamentoReport = list.filter(n => n.status === 'AUTORIZADA' || n.status === 'CORRIGIDA').reduce((acc, n) => acc + (Number(n.valor_total) || 0), 0);

    let rowsHtml = '';
    list.forEach(note => {
        const num = note.numero ? String(note.numero).padStart(6, '0') : '---';
        const dest = note.destinatario_nome || 'Consumidor Final';
        rowsHtml += `<tr><td class="text-center"><b>${num}</b></td><td>${dest}</td><td class="text-center">${note.status}</td><td class="text-center">${formatDate(note.created_at)}</td><td class="text-right"><b>${formatCurrency(note.valor_total)}</b></td></tr>`;
    });

    const printWindow = window.open('', '_blank');
    if (!printWindow) return appStore.showSnackbar('Permita a abertura de pop-ups para visualizar o relatório.', 'warning');

    const html = `<!DOCTYPE html><html lang="pt-BR"><head><meta charset="UTF-8"><title>Relatório de NF-e</title><style>body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; padding: 20px; color: #333; margin: 0; } .header { display: flex; justify-content: space-between; align-items: flex-start; border-bottom: 2px solid #1976d2; padding-bottom: 15px; margin-bottom: 20px; } .header-info h1 { margin: 0 0 5px 0; font-size: 22px; color: #1976d2; text-transform: uppercase; letter-spacing: 1px; } .header-info p { margin: 3px 0; font-size: 12px; color: #555; } .logo-placeholder { display: flex; align-items: center; justify-content: flex-end; } .logo-placeholder img { max-width: 160px; max-height: 65px; object-fit: contain; } .kpis { display: flex; gap: 15px; margin-bottom: 20px; } .kpi { border: 1px solid #e0e0e0; background: #f9f9f9; padding: 15px; border-radius: 6px; flex: 1; text-align: center; } .kpi-title { font-size: 11px; text-transform: uppercase; font-weight: bold; color: #757575; margin-bottom: 5px; } .kpi-value { font-size: 22px; font-weight: 900; color: #212121; } .kpi-value.success { color: #2e7d32; } .kpi-value.primary { color: #1565c0; } table { width: 100%; border-collapse: collapse; font-size: 11px; } th, td { border: 1px solid #ddd; padding: 8px; } th { background-color: #f5f5f5; text-transform: uppercase; color: #555; text-align: left; } .text-right { text-align: right; } .text-center { text-align: center; } tr:nth-child(even) { background-color: #fafafa; } .footer { margin-top: 30px; font-size: 10px; color: #888; text-align: center; border-top: 1px solid #eee; padding-top: 10px; } @media print { body { padding: 0; } .header { border-bottom: 1px solid #ccc; } .kpi { border: 1px solid #ccc; background: transparent; } @page { margin: 1.5cm; size: A4 portrait; } }</style></head><body><div class="header"><div class="header-info"><h1>Relatório Analítico - NF-e 4.0</h1><p><strong>Empresa Emissora:</strong> ${activeCompany.value?.name || 'Todas as Lojas'}</p><p><strong>CNPJ:</strong> ${activeCompany.value?.cnpj || '---'}</p><p><strong>Período:</strong> ${formatDate(reportModal.startDate)} a ${formatDate(reportModal.endDate)}</p></div><div class="logo-placeholder"><img src="${companyStore.isDemoMode ? '' : logoUrl}" alt="Logo da Empresa"></div></div><div class="kpis"><div class="kpi"><div class="kpi-title">Notas Emitidas (Qtd)</div><div class="kpi-value">${list.length}</div></div><div class="kpi"><div class="kpi-title">Autorizadas (Qtd)</div><div class="kpi-value success">${notasAutorizadas}</div></div><div class="kpi"><div class="kpi-title">Faturamento Emitido (R$)</div><div class="kpi-value primary">${formatCurrency(faturamentoReport)}</div></div></div><table><thead><tr><th class="text-center" style="width: 70px;">Nº NFe</th><th>Destinatário</th><th class="text-center" style="width: 110px;">Status</th><th class="text-center" style="width: 90px;">Data Emissão</th><th class="text-right" style="width: 110px;">Valor Total</th></tr></thead><tbody>${rowsHtml}</tbody></table><div class="footer">Relatório gerado pelo Sistema em ${new Date().toLocaleString('pt-BR')}</div><script>window.onload = () => { setTimeout(() => { window.print(); window.close(); }, 500); };<\/script></body></html>`;
    printWindow.document.open(); printWindow.document.write(html); printWindow.document.close();
    reportModal.show = false;
};


watch(() => companyStore.context, () => {
    if (!isTenantLocked.value) return;

    const scoped = getScopedCompany();
    if (scoped && activeCompany.value?.id !== scoped.id) {
        syncActiveCompany(scoped);
        fetchHistory();
    }
});

onMounted(async () => {
    if (!userStore.profile && userStore.fetchSession) {
        await userStore.fetchSession();
    }

    initialTenantContext.value = companyStore.context && companyStore.context !== 'global'
        ? String(companyStore.context)
        : null;

    loadCompanies();
});
</script>

<style scoped lang="scss">
/* Layout Geral Premium */
.issuer-layout { position: relative; }
.background-carousel-wrapper { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 0; opacity: 0.6; pointer-events: none; }
.background-overlay { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 1; background: radial-gradient(circle at center, rgba(15, 15, 19, 0.4), rgba(15, 15, 19, 0.98)); backdrop-filter: blur(8px); }
.z-10 { position: relative; z-index: 10; }
.bg-glass-dark { background: rgba(10,10,12,0.85); }
.bg-glass-header { background: rgba(20,20,24,0.55); backdrop-filter: blur(14px); }
.border-bottom-white-05 { border-bottom: 1px solid rgba(255,255,255,0.08) !important; }
.border-white-10 { border: 1px solid rgba(255,255,255,0.1) !important; }
.bg-white-05 { background: rgba(255,255,255,0.05); }
.bg-black-90 { background: rgba(0,0,0,0.9); }
.bg-black-80 { background: rgba(0,0,0,0.8); }
.bg-black-40 { background: rgba(0,0,0,0.4); }
.bg-black-20 { background: rgba(0,0,0,0.2) !important; }
.bg-white-90 { background: rgba(255,255,255,0.9); }
.bg-white-20 { background: rgba(255,255,255,0.2); }
.text-white-70 { color: rgba(255,255,255,0.7) !important; }
.backdrop-blur-sm { backdrop-filter: blur(4px); }
.text-shadow-sm { text-shadow: 0 2px 4px rgba(0,0,0,0.2); }

/* Controles e Pesquisa */
.controls-bar { padding: 10px; }
.controls-light { background: #ffffff; border: 1px solid rgba(0,0,0,0.08); }
.controls-dark { background: rgba(30,30,35,0.55); backdrop-filter: blur(16px); }
.search-wrap { height: 40px; padding: 0 12px; border: 1px solid rgba(0,0,0,0.08); flex: 1; }
.search-light { background: #f4f6f8; }
.search-dark { background: rgba(255,255,255,0.08); border-color: rgba(255,255,255,0.10); }
.clean-input { border: none; outline: none; background: transparent; font-size: 13px; font-weight: bold; width: 100%; }
.input-dense :deep(.v-field__input) { min-height: 32px; padding-top: 4px; padding-bottom: 4px; font-size: 12px; }

@media (max-width: 600px) { .search-wrap { min-width: 100%; } }

/* Grid e Scroll */
.grid-scroll { scrollbar-gutter: stable; -webkit-overflow-scrolling: touch; }
.custom-scroll::-webkit-scrollbar { width: 8px; height: 8px; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.35); border-radius: 6px; }
.custom-scroll::-webkit-scrollbar-track { background: transparent; }

/* GRID LAYOUT FLUIDO */
.grid-header, .grid-row { display: grid; align-items: stretch; width: 100%; }
.grid-nfe-layout { grid-template-columns: 50px 80px 100px 1.5fr 1fr 110px 100px 120px 180px; min-width: 1100px; }
.cell { padding: 8px 10px; display: flex; align-items: center; border-right: 1px solid rgba(0,0,0,0.08); border-bottom: 1px solid rgba(0,0,0,0.08); min-height: 54px; overflow: hidden; transition: background-color 0.2s ease; }
.header-text { font-size: 11px !important; font-weight: 900; text-transform: uppercase; letter-spacing: 0.5px; opacity: 0.8; }
.center { justify-content: center; text-align: center; }
.right { justify-content: flex-end; text-align: right; }
.grid-header .cell { min-height: 44px; }
.list-text-10 { font-size: 12px !important; line-height: 1.25 !important; }
.list-text-11 { font-size: 13px !important; line-height: 1.2 !important; }

/* Dark/Light Modes da Grid */
.grid-surface-light .cell { background: #f0f2f5; color: rgba(0,0,0,0.9); border-color: rgba(0,0,0,0.08) !important; }
.grid-row-light .cell { border-color: rgba(0,0,0,0.05) !important; }
.zebra-light-a .cell { background: #ffffff; }
.zebra-light-b .cell { background: #f8f9fa; }
.grid-row-light:hover .cell { background: #e3f2fd !important; }

.grid-surface-dark .cell { background: rgba(255,255,255,0.08) !important; color: rgba(255,255,255,0.80) !important; border-color: rgba(255,255,255,0.10) !important; }
.grid-row-dark .cell { background: rgba(255,255,255,0.04); border-color: rgba(255,255,255,0.08) !important; color: rgba(255,255,255,0.85); }
.zebra-dark-a .cell { background: rgba(255,255,255,0.04) !important; }
.zebra-dark-b .cell { background: rgba(255,255,255,0.015) !important; }
.grid-row-dark:hover .cell { background: rgba(255,255,255,0.07) !important; }

.v-theme--dark { .text-grey-darken-4, .text-grey-darken-3, .text-grey-darken-2, .text-grey-darken-1, .text-grey { color: rgba(255,255,255,0.9) !important; } }

/* Ações e Botões 3D */
.actions-inline { display: flex; gap: 4px; justify-content: center; }
.action-btn { width: 28px !important; height: 28px !important; color: #fff !important; }
.btn-3d { box-shadow: 0 3px 5px rgba(0,0,0,0.15), inset 0 2px 0 rgba(255,255,255,0.25) !important; text-transform: none !important; }
.btn-3d:active { transform: translateY(2px); box-shadow: 0 1px 2px rgba(0,0,0,0.15), inset 0 1px 0 rgba(255,255,255,0.2) !important; }
.chip-3d { box-shadow: 0 3px 5px rgba(0,0,0,0.12), inset 0 1px 0 rgba(255,255,255,0.25) !important; text-shadow: 0 1px 2px rgba(0,0,0,0.25); }
.glass-card { background: rgba(255,255,255,0.03); backdrop-filter: blur(10px); }
.shadow-indigo-soft { box-shadow: 0 4px 15px rgba(63, 81, 181, 0.4); }

/* KPI Cards */
.kpi-card { color: white; position: relative; min-height: 110px; overflow: hidden; border-radius: 8px; cursor: pointer; }
.kpi-bg-icon { position: absolute; right: -20px; bottom: -20px; opacity: 0.15; transform: rotate(-15deg); pointer-events: none; }
.kpi-bg-icon .v-icon { font-size: 100px; color: white; }
.bg-gradient-info { background: linear-gradient(135deg, #0288d1, #005b9f); }
.bg-gradient-green { background: linear-gradient(135deg, #2e7d32, #1b5e20); }
.bg-gradient-purple { background: linear-gradient(135deg, #7b1fa2, #4a148c); }
.bg-gradient-warning { background: linear-gradient(135deg, #FFB300, #F57F17); }
.kpi-label { font-size: 12px; font-weight: 900; letter-spacing: .2px; text-transform: uppercase; }
.kpi-value { font-size: 24px; font-weight: 900; letter-spacing: .2px; }
.kpi-footer { font-size: 11px; opacity: .9; font-weight: 700; text-transform: uppercase; }

/* Formulários e Misc */
.ui-field :deep(.v-field) { border-radius: 6px !important; }
.solid-chip { display: inline-flex; align-items: center; justify-content: center; height: 22px; padding: 0 10px; font-size: 10px; font-weight: 900; color: #fff; white-space: nowrap; }
.chip-success { background: #2e7d32; }
.chip-warning { background: #f57f17; }
.chip-danger { background: #c62828; }
.pdf-iframe { width: 100%; height: 100%; border: none; background: white; }
.lh-1 { line-height: 1.1; }
.letter-spacing-1 { letter-spacing: 1px; }

/* Cabeçalho Fixo */
.sticky-head { position: sticky; top: 0; z-index: 20; box-shadow: 0 8px 16px -4px rgba(0, 0, 0, 0.12); }
.bg-glass-dark .sticky-head { box-shadow: 0 8px 20px -4px rgba(0, 0, 0, 0.4); }
</style>
