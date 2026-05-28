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
            <div class="d-flex flex-column" style="max-width: calc(100vw - 220px);">
                <div class="breadcrumb text-caption">
                    <span class="opacity-70">Fiscal</span>
                    <span class="mx-2 opacity-50">></span>
                    <span class="font-weight-bold">Notas Recebidas</span>
                </div>
                <div class="text-h6 font-weight-black tracking-tight leading-none mt-1" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">
                    Monitor de notas fiscais recebidas
                </div>

                <div class="d-flex align-center gap-3 mt-3 overflow-x-auto hide-scrollbar pb-1 w-100">
                    <v-btn
                        v-for="btn in contextButtons"
                        :key="btn.id"
                        size="x-small"
                        height="24"
                        :variant="activeContextId === btn.id ? 'flat' : 'tonal'"
                        :color="activeContextId === btn.id ? (btn.isHolding ? 'purple' : 'success') : 'grey'"
                        class="font-weight-bold btn-3d context-btn-3d px-3 rounded-pill flex-shrink-0"
                        style="font-size: 10px; letter-spacing: 0.5px;"
                        @click="setCompanyFilter(btn.id)"
                    >
                        {{ btn.name }}
                    </v-btn>
                </div>
            </div>
        </div>

        <div class="px-6 pt-4 pb-0 flex-shrink-0">
            <v-row>
                <v-col cols="12" sm="6" md="3">
                    <v-card class="kpi-card kpi-rect kpi-3d bg-gradient-info hover-elevate py-3 px-4 cursor-pointer" v-ripple elevation="2" @click="nfeSyncState.showDetails = true">
                        <div class="kpi-bg-icon"><v-icon>mdi-brain</v-icon></div>
                        <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                            <div class="d-flex align-center justify-space-between mb-2">
                                <div class="d-flex align-center" style="gap: 8px;">
                                    <v-icon size="18" class="opacity-80">mdi-brain</v-icon>
                                    <span class="kpi-label">IA Fiscal</span>
                                </div>
                                <div class="text-caption opacity-80 font-mono">{{ formatDateTime(nfeSyncState.current?.next_run_at) }}</div>
                            </div>
                            <div class="d-flex flex-column">
                                <div class="text-caption font-weight-black text-uppercase">
                                    {{ nfeSyncLabel }}
                                </div>
                                <div class="text-caption text-white opacity-80 mt-1">
                                    Sequência: {{ nfeSyncState.current?.ultimo_nsu ?? '---' }} • Recebidas: {{ nfeSyncState.totalRecebidas }}
                                </div>
                                <div v-if="nfeSyncIsBlocked" class="text-caption text-amber-accent-1 font-weight-bold d-flex align-center mt-1">
                                    <v-icon start size="12" class="mr-1">mdi-timer-sand</v-icon>
                                    Até {{ formatDateTime(nfeSyncState.current?.blocked_until) }}
                                </div>
                                <v-btn
                                    variant="outlined"
                                    color="white"
                                    size="small"
                                    class="btn-rect btn-3d font-weight-bold mt-2"
                                    :loading="nfeSyncState.loading"
                                    @click.stop="fetchNfeSyncStatus"
                                >
                                    <v-icon start size="16">mdi-refresh</v-icon>
                                    Atualizar status
                                </v-btn>
                            </div>
                        </div>
                    </v-card>
                </v-col>

                <v-col cols="12" sm="6" md="3">
                    <v-card class="kpi-card kpi-rect kpi-3d bg-gradient-purple hover-elevate py-3 px-4" v-ripple elevation="2">
                        <div class="kpi-bg-icon"><v-icon>mdi-file-document-multiple</v-icon></div>
                        <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                            <div class="d-flex align-center" style="gap: 8px;">
                                <v-icon size="18" class="opacity-80">mdi-file-document-multiple</v-icon>
                                <span class="kpi-label">Notas na tela</span>
                            </div>
                            <div class="kpi-number-group my-1">
                                <span class="kpi-value">{{ unifiedNotes.length }}</span>
                                <span class="text-caption ml-1 opacity-70">listadas</span>
                            </div>
                            <div class="kpi-footer mt-1">Recebidas + manuais</div>
                        </div>
                    </v-card>
                </v-col>

                <v-col cols="12" sm="6" md="3">
                    <v-card class="kpi-card kpi-rect kpi-3d bg-gradient-green hover-elevate py-3 px-4" v-ripple elevation="2">
                        <div class="kpi-bg-icon"><v-icon>mdi-cash-multiple</v-icon></div>
                        <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                            <div class="d-flex align-center" style="gap: 8px;">
                                <v-icon size="18" class="opacity-80">mdi-cash-multiple</v-icon>
                                <span class="kpi-label">Total no período</span>
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
                        class="kpi-card kpi-rect kpi-3d hover-elevate py-3 px-4 cursor-pointer"
                        :class="pendingCount > 0 ? 'bg-gradient-warning' : 'bg-gradient-grey'"
                        v-ripple
                        elevation="2"
                        @click="statusFilter = 'uninformed'; currentPeriod = 'all'"
                    >
                        <div class="kpi-bg-icon"><v-icon>mdi-alert-decagram</v-icon></div>
                        <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                            <div class="d-flex align-center" style="gap: 8px;">
                                <v-icon size="18" class="opacity-80">mdi-alert-decagram</v-icon>
                                <span class="kpi-label">Sem manifestação</span>
                            </div>
                            <div class="kpi-number-group my-1">
                                <span class="kpi-value">{{ pendingCount }}</span>
                            </div>
                            <div class="kpi-footer mt-1">Aguardando escolha</div>
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
                                class="btn-rect btn-3d font-weight-bold"
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
                                <v-list-item @click="setPeriod('all')" :active="currentPeriod === 'all'"><v-list-item-title>Todos os Períodos</v-list-item-title></v-list-item>
                                <v-list-item @click="currentPeriod = 'custom'" :active="currentPeriod === 'custom'"><v-list-item-title>Personalizado</v-list-item-title></v-list-item>
                            </v-list>
                            <div v-if="currentPeriod === 'custom'" class="pa-2 border-t mt-1">
                                <v-text-field v-model="customDateStart" type="date" label="Início" density="compact" variant="outlined" hide-details class="mb-2"></v-text-field>
                                <v-text-field v-model="customDateEnd" type="date" label="Fim" density="compact" variant="outlined" hide-details class="mb-2"></v-text-field>
                            </div>
                        </v-card>
                    </v-menu>

                    <div class="d-flex rounded p-1" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-3' : 'bg-white-10'" style="padding: 4px;">
                        <v-btn variant="flat" class="btn-rect btn-3d" height="32" :color="currentTab === 'active' ? (themeStore.currentMode === 'light' ? 'white' : 'grey-darken-3') : 'transparent'" @click="currentTab = 'active'" :class="{'text-grey-darken-3': currentTab === 'active' && themeStore.currentMode === 'light', 'text-grey-darken-1': currentTab !== 'active'}">
                            <v-icon start size="16" class="mr-1">mdi-file-document-multiple</v-icon> Em aberto
                        </v-btn>
                        <v-btn variant="flat" class="btn-rect btn-3d" height="32" :color="currentTab === 'archived' ? (themeStore.currentMode === 'light' ? 'white' : 'grey-darken-3') : 'transparent'" @click="currentTab = 'archived'" :class="{'text-purple': currentTab === 'archived', 'text-grey-darken-1': currentTab !== 'archived'}">
                            <v-icon start size="16" class="mr-1">mdi-archive</v-icon> Arquivadas
                        </v-btn>
                    </div>

                    <div style="width: 180px;">
                        <v-select v-model="statusFilter" :items="statusOptions" item-title="label" item-value="value" variant="outlined" density="compact" hide-details class="clean-input btn-rect btn-3d" bg-color="transparent" placeholder="Status">
                             <template v-slot:prepend-inner><v-icon size="small" color="grey">mdi-filter-variant</v-icon></template>
                        </v-select>
                    </div>

                    <div class="search-wrap d-flex align-center" :class="themeStore.currentMode === 'light' ? 'search-light' : 'search-dark'">
                        <v-icon :color="themeStore.currentMode === 'light' ? 'grey-darken-1' : 'white-70'">mdi-magnify</v-icon>
                        <input v-model="search" type="text" placeholder="Buscar..." class="clean-input flex-grow-1" />
                    </div>
                </div>

                <div class="d-flex align-center flex-wrap" style="gap: 10px;">
                    <v-btn
                        variant="outlined"
                        class="btn-rect btn-3d text-none font-weight-bold"
                        height="40"
                        :color="themeStore.currentMode === 'light' ? 'grey-darken-2' : 'white'"
                        prepend-icon="mdi-brain"
                        :loading="nfeSyncState.loading"
                        @click="nfeSyncState.showDetails = true"
                    >
                        Status da IA
                    </v-btn>

                    <v-btn
                        variant="outlined"
                        class="btn-rect btn-3d text-none font-weight-bold"
                        height="40"
                        :color="themeStore.currentMode === 'light' ? 'grey-darken-2' : 'white'"
                        prepend-icon="mdi-refresh"
                        :loading="loading || nfeSyncState.loading"
                        @click="refreshFiscalMonitor"
                    >
                        Atualizar tela
                    </v-btn>

                    <v-menu location="bottom end">
                        <template v-slot:activator="{ props }">
                            <v-btn
                                v-bind="props"
                                variant="flat"
                                color="primary"
                                class="btn-rect btn-3d font-weight-bold"
                                height="40"
                            >
                                Mais ações <v-icon end size="small">mdi-chevron-down</v-icon>
                            </v-btn>
                        </template>
                        <v-list density="compact" elevation="4" class="py-1" min-width="250">

                            <v-menu location="start top" offset="5" open-on-hover>
                                <template v-slot:activator="{ props }">
                                    <v-list-item v-bind="props" class="hover:bg-grey-lighten-4">
                                        <template v-slot:prepend><v-icon size="18" class="mr-2 text-primary">mdi-cloud-sync</v-icon></template>
                                        <v-list-item-title class="font-weight-bold text-primary">Busca manual</v-list-item-title>
                                        <template v-slot:append><v-icon size="16">mdi-chevron-right</v-icon></template>
                                    </v-list-item>
                                </template>
                                <v-list density="compact" elevation="4" class="py-1">
                                    <v-list-item @click="openConsultKeyModal" class="hover:bg-grey-lighten-4">
                                        <template v-slot:prepend><v-icon size="16" class="mr-2 text-success">mdi-magnify-scan</v-icon></template>
                                        <v-list-item-title class="text-caption font-weight-bold">Buscar nota pela chave</v-list-item-title>
                                    </v-list-item>
                                    <v-list-item @click="rescueDeletedNotes(false)" class="hover:bg-grey-lighten-4">
                                        <template v-slot:prepend><v-icon size="16" class="mr-2 text-warning">mdi-lifebuoy</v-icon></template>
                                        <v-list-item-title class="text-caption font-weight-bold">Recuperar nota específica</v-list-item-title>
                                        <v-list-item-subtitle class="text-[10px]">Use só se a IA não encontrar depois da busca automática.</v-list-item-subtitle>
                                    </v-list-item>
                                    <v-list-item @click="nfeSyncState.showDetails = true" class="hover:bg-grey-lighten-4">
                                        <template v-slot:prepend><v-icon size="16" class="mr-2 text-info">mdi-brain</v-icon></template>
                                        <v-list-item-title class="text-caption font-weight-bold">Ver status da IA automática</v-list-item-title>
                                    </v-list-item>
                                </v-list>
                            </v-menu>

                            <v-divider class="my-1"></v-divider>

                            <v-list-item @click="triggerXmlInput" class="hover:bg-grey-lighten-4">
                                <template v-slot:prepend><v-icon size="18" class="mr-2 text-grey-darken-3">mdi-upload</v-icon></template>
                                <v-list-item-title class="font-weight-medium text-grey-darken-3">Upload XML Manual</v-list-item-title>
                            </v-list-item>

                            <v-list-item @click="openCertModal" class="hover:bg-grey-lighten-4">
                                <template v-slot:prepend><v-icon size="18" class="mr-2 text-info">mdi-shield-key</v-icon></template>
                                <v-list-item-title class="font-weight-medium text-grey-darken-3">Certificado Digital</v-list-item-title>
                            </v-list-item>

                            <v-divider class="my-1"></v-divider>

                            <v-list-item @click="showLogs = true" class="hover:bg-grey-lighten-4">
                                <template v-slot:prepend>
                                    <v-icon size="18" class="mr-2" :color="errorCount > 0 ? 'error' : 'grey-darken-1'">mdi-console</v-icon>
                                </template>
                                <v-list-item-title class="font-weight-medium" :class="errorCount > 0 ? 'text-error font-weight-bold' : 'text-grey-darken-3'">
                                    Ver Logs <v-badge v-if="errorCount > 0" color="error" :content="errorCount" inline class="ml-1"></v-badge>
                                </v-list-item-title>
                            </v-list-item>
                        </v-list>
                    </v-menu>

                    <input type="file" ref="xmlInput" class="d-none" accept=".xml" multiple @change="handleXmlUpload">
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
                        <div class="cell center header-text" style="width: 220px;">Ações</div>
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
                                <div class="text-truncate list-text-10 font-weight-bold" :class="note.emitente_nome === 'Emitente Desconhecido' ? 'text-error' : ''" :title="note.emitente_nome">{{ note.emitente_nome || 'Emitente Desconhecido' }}</div>
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
                                <span v-if="note.status_processamento === 'contas_a_pagar_gerado'" class="solid-chip chip-3d chip-success">
                                    <v-icon start size="10">mdi-check-all</v-icon> Lançado
                                </span>
                                <v-tooltip v-else-if="note.source === 'api'" text="Clique para Confirmar ou Rejeitar" location="top" content-class="tooltip-custom">
                                    <template v-slot:activator="{ props }">
                                        <span v-bind="props" class="solid-chip chip-3d chip-danger cursor-pointer hover:opacity-80" @click="openManifestModal(note)">NÃO INFORMADO</span>
                                    </template>
                                </v-tooltip>
                                <span v-else class="solid-chip chip-3d" :class="getManifestChipClass(note)">{{ getManifestLabel(note) }}</span>
                            </div>
                            <div class="cell right">
                                <span class="list-text-10 font-mono font-weight-black" :class="!note.valor || note.valor === 0 ? 'text-error' : ''">{{ formatCurrency(note.valor) }}</span>
                            </div>

                            <div class="cell center" style="width: 220px;">
                                <div class="actions-inline" :class="note.source === 'api' ? 'opacity-30 pointer-events-none' : ''">
                                    <v-tooltip text="Receber Estoque (XML)" location="top" content-class="tooltip-custom">
                                        <template v-slot:activator="{ props }">
                                            <v-btn v-bind="props" icon size="small" class="action-btn btn-3d" color="teal-darken-2" variant="flat" @click.stop="openStockReceiveModal(note)">
                                                <v-icon size="16">mdi-package-down</v-icon>
                                            </v-btn>
                                        </template>
                                    </v-tooltip>

                                    <v-tooltip v-if="note.status_processamento === 'contas_a_pagar_gerado'" text="Estornar Lançamento Financeiro" location="top" content-class="tooltip-custom">
                                        <template v-slot:activator="{ props }">
                                            <v-btn v-bind="props" icon size="small" color="error" variant="flat" class="action-btn btn-3d" @click.stop="revertLaunch(note)">
                                                <v-icon size="16" color="white">mdi-cash-refund</v-icon>
                                            </v-btn>
                                        </template>
                                    </v-tooltip>
                                    <v-tooltip v-else text="Lançar no Financeiro" location="top" content-class="tooltip-custom">
                                        <template v-slot:activator="{ props }">
                                            <v-btn v-bind="props" icon size="small" class="action-btn btn-3d action-revert" @click.stop="openPayableModal(note)" :disabled="!canLaunchFinance(note)">
                                                 <v-icon size="16">mdi-cash-register</v-icon>
                                            </v-btn>
                                        </template>
                                    </v-tooltip>

                                    <v-tooltip text="Visualizar DANFE" location="top" content-class="tooltip-custom">
                                        <template v-slot:activator="{ props }">
                                            <v-btn v-bind="props" icon size="small" class="action-btn btn-3d action-edit" @click.stop="openDanfeModal(note)" :loading="pdfLoading === note.chave">
                                                <v-icon size="16">{{ isManifested(note) ? 'mdi-file-document-check' : 'mdi-eye' }}</v-icon>
                                            </v-btn>
                                        </template>
                                    </v-tooltip>

                                    <v-tooltip text="Baixar XML" location="top" content-class="tooltip-custom">
                                        <template v-slot:activator="{ props }">
                                            <v-btn v-bind="props" icon size="small" class="action-btn btn-3d bg-indigo-lighten-1 text-white" @click.stop="downloadXml(note)">
                                                <v-icon size="16">mdi-download</v-icon>
                                            </v-btn>
                                        </template>
                                    </v-tooltip>

                                    <v-menu location="bottom end">
                                        <template v-slot:activator="{ props }">
                                            <v-btn v-bind="props" icon size="small" class="action-btn btn-3d bg-success text-white" title="Ações Avançadas">
                                                <v-icon size="18">mdi-chevron-down</v-icon>
                                            </v-btn>
                                        </template>
                                        <v-list density="compact" elevation="4" class="py-1" min-width="220">

                                            <v-list-item @click="openRaioXModal(note)" class="text-primary hover:bg-grey-lighten-4">
                                                <template v-slot:prepend><v-icon size="18" class="mr-2">mdi-radar</v-icon></template>
                                                <v-list-item-title class="font-weight-bold">Raio-X da Nota</v-list-item-title>
                                            </v-list-item>

                                            <v-list-item @click="fixNoteDataFromXml(note)" v-if="note.emitente_nome === 'Emitente Desconhecido' || !note.valor" class="text-indigo hover:bg-indigo-lighten-5">
                                                <template v-slot:prepend><v-icon size="18" class="mr-2">mdi-auto-fix</v-icon></template>
                                                <v-list-item-title class="font-weight-bold">Corrigir Dados (Ler XML)</v-list-item-title>
                                            </v-list-item>

                                            <v-divider class="my-1"></v-divider>

                                            <v-menu location="start top" offset="5" open-on-hover>
                                                <template v-slot:activator="{ props }">
                                                    <v-list-item v-bind="props" class="hover:bg-grey-lighten-4">
                                                        <template v-slot:prepend><v-icon size="18" class="mr-2 text-warning">mdi-check-decagram</v-icon></template>
                                                        <v-list-item-title class="font-weight-medium">Manifestação</v-list-item-title>
                                                        <template v-slot:append><v-icon size="16">mdi-chevron-right</v-icon></template>
                                                    </v-list-item>
                                                </template>
                                                <v-list density="compact" elevation="4">
                                                    <v-list-item @click="manifestNote(note, 'ciencia')"><v-list-item-title class="text-caption">Dar Ciência</v-list-item-title></v-list-item>
                                                    <v-list-item @click="manifestNote(note, 'confirmacao')"><v-list-item-title class="text-caption">Confirmar Operação</v-list-item-title></v-list-item>
                                                    <v-list-item @click="manifestNote(note, 'desconhecimento')"><v-list-item-title class="text-caption">Desconhecer</v-list-item-title></v-list-item>
                                                    <v-list-item @click="manifestNote(note, 'nao_realizada')"><v-list-item-title class="text-caption">Operação Não Realizada</v-list-item-title></v-list-item>
                                                </v-list>
                                            </v-menu>

                                            <v-menu location="start top" offset="5" open-on-hover>
                                                <template v-slot:activator="{ props }">
                                                    <v-list-item v-bind="props" class="hover:bg-grey-lighten-4">
                                                        <template v-slot:prepend><v-icon size="18" class="mr-2 text-grey">mdi-folder</v-icon></template>
                                                        <v-list-item-title class="font-weight-medium">Organização</v-list-item-title>
                                                        <template v-slot:append><v-icon size="16">mdi-chevron-right</v-icon></template>
                                                    </v-list-item>
                                                </template>
                                                <v-list density="compact" elevation="4">
                                                    <v-list-item @click="archiveNote(note)" v-if="currentTab === 'active'"><v-list-item-title class="text-caption">Arquivar</v-list-item-title></v-list-item>
                                                    <v-list-item @click="unarchiveNote(note)" v-else><v-list-item-title class="text-caption">Desarquivar</v-list-item-title></v-list-item>
                                                    <v-list-item @click="deleteNote(note)" class="text-error"><v-list-item-title class="text-caption">Excluir</v-list-item-title></v-list-item>
                                                </v-list>
                                            </v-menu>

                                        </v-list>
                                    </v-menu>
                                </div>
                            </div>
                        </div>
                    </template>
                </div>
            </v-card>

            <v-slide-y-reverse-transition>
               <div v-if="selectedPending.length > 0" class="bulk-action-island-wrapper">
                   <v-card elevation="10" class="bulk-action-island bg-grey-darken-4 text-white border border-grey-darken-3">
                       <div class="bulk-action-count">
                           <v-icon size="18" color="warning">mdi-checkbox-multiple-marked-circle</v-icon>
                           <span>{{ selectedPending.length }} item(ns) selecionado(s)</span>
                       </div>

                       <v-divider vertical class="bg-white opacity-20 my-1 d-none d-sm-block"></v-divider>

                       <div class="bulk-action-buttons">
                           <v-btn
                               color="success"
                               variant="flat"
                               class="text-none font-weight-bold rounded-pill bulk-action-btn"
                               :loading="bulkLoading"
                               @click="confirmSelectedNotes"
                               height="34"
                           >
                               <v-icon start size="16">mdi-check-all</v-icon>
                               Confirmar
                           </v-btn>

                           <v-btn
                               color="warning"
                               variant="flat"
                               class="text-none font-weight-bold rounded-pill bulk-action-btn"
                               :loading="bulkLoading"
                               @click="archiveSelectedNotes"
                               height="34"
                           >
                               <v-icon start size="16">mdi-archive</v-icon>
                               Arquivar
                           </v-btn>

                           <v-btn
                               icon="mdi-close"
                               size="small"
                               variant="text"
                               color="grey-lighten-1"
                               class="bulk-action-close"
                               @click="selectedPending = []"
                           ></v-btn>
                       </div>
                   </v-card>
               </div>
           </v-slide-y-reverse-transition>

            <div class="flex-shrink-0 border-t px-4 py-2 d-flex align-center justify-space-between bg-white" v-if="pageCount > 1">
                <div class="text-caption text-grey">Página {{ page }} de {{ pageCount }}</div>
                <v-pagination v-model="page" :length="pageCount" :total-visible="5" density="compact" active-color="primary" variant="tonal" size="small"></v-pagination>
            </div>
        </div>
    </div>

    <v-dialog v-model="stockReceiveModal.show" max-width="900" persistent scrollable scrim="black opacity-80">
        <v-card class="rounded-xl border-thin shadow-xl d-flex flex-column" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-grey-darken-4 text-white'" style="height: 75vh;">
            <div class="pa-5 border-b d-flex align-center justify-space-between" :class="themeStore.currentMode === 'light' ? 'bg-teal-lighten-5 border-teal-lighten-4' : 'bg-grey-darken-3 border-white-10'">
                <div class="d-flex align-center gap-3">
                    <v-icon color="teal-darken-3" size="28">mdi-package-down</v-icon>
                    <div>
                        <h3 class="text-subtitle-1 font-weight-black d-flex align-center gap-2 text-uppercase tracking-widest ls-1 text-teal-darken-3">Recebimento de Estoque</h3>
                        <div class="text-caption font-mono font-weight-bold opacity-70">NFe: {{ stockReceiveModal.note?.chave }}</div>
                    </div>
                </div>
                <v-btn icon="mdi-close" variant="text" size="small" @click="stockReceiveModal.show = false"></v-btn>
            </div>

            <div class="flex-grow-1 overflow-auto pa-5 custom-scroll">
                <div v-if="stockReceiveModal.loading" class="d-flex flex-column align-center justify-center h-100 py-10">
                    <v-progress-circular indeterminate color="teal-darken-3" size="48" width="4"></v-progress-circular>
                    <span class="text-caption font-weight-bold mt-4 opacity-70 text-uppercase tracking-widest">Lendo itens do XML...</span>
                </div>
                <div v-else>
                    <v-alert type="info" variant="tonal" density="compact" class="mb-4 text-caption font-weight-medium">
                        Selecione os itens da nota que deseja adicionar ao estoque. O sistema tentou parear os produtos automaticamente pelo nome, mas você pode alterar o destino manualmente.
                    </v-alert>

                    <v-table density="compact" class="border-thin rounded-lg shadow-sm" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-grey-darken-3'">
                        <thead :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-4' : 'bg-grey-darken-4'">
                            <tr>
                                <th style="width: 50px" class="text-center">
                                    <v-checkbox-btn v-model="stockReceiveModal.selectAll" @change="toggleSelectAllStock" color="teal-darken-3"></v-checkbox-btn>
                                </th>
                                <th class="text-caption font-weight-black text-uppercase">Produto na Nota (XML)</th>
                                <th class="text-caption font-weight-black text-uppercase text-center">Qtd (XML)</th>
                                <th class="text-caption font-weight-black text-uppercase" style="width: 300px;">Produto Destino (Estoque)</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr v-for="(item, idx) in stockReceiveModal.items" :key="idx" :class="themeStore.currentMode === 'light' ? 'hover-bg-grey-lighten-5' : 'hover-bg-grey-darken-3'">
                                <td class="text-center">
                                    <v-checkbox-btn v-model="item.selected" color="teal-darken-3"></v-checkbox-btn>
                                </td>
                                <td>
                                    <div class="d-flex flex-column py-1">
                                        <span class="text-body-2 font-weight-bold">{{ item.xProd }}</span>
                                        <span class="text-[10px] font-mono opacity-70">V. Unit: {{ formatCurrency(item.vProd / item.qCom) }} | Total: {{ formatCurrency(item.vProd) }}</span>
                                    </div>
                                </td>
                                <td class="text-center">
                                    <v-text-field v-model.number="item.qCom" type="number" density="compact" variant="outlined" hide-details class="font-mono text-center mx-auto" style="max-width: 90px;"></v-text-field>
                                </td>
                                <td class="pa-2">
                                    <v-autocomplete
                                        v-model="item.stock_id"
                                        :items="stockItems"
                                        item-title="fabric_type"
                                        item-value="id"
                                        variant="outlined"
                                        density="compact"
                                        hide-details
                                        placeholder="Selecione o Tecido..."
                                        :bg-color="themeStore.currentMode === 'light' ? 'white' : 'grey-darken-4'"
                                    >
                                        <template v-slot:item="{ props, item }">
                                            <v-list-item v-bind="props">
                                                <v-list-item-subtitle class="text-[10px] font-mono">Saldo Atual: {{ item.raw.available_meters }} {{ item.raw.unit_of_measure }}</v-list-item-subtitle>
                                            </v-list-item>
                                        </template>
                                    </v-autocomplete>
                                </td>
                            </tr>
                        </tbody>
                    </v-table>
                </div>
            </div>

            <div class="pa-4 border-t d-flex justify-end gap-3 flex-shrink-0" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5' : 'bg-grey-darken-3'">
                <v-btn variant="outlined" class="btn-rect font-weight-bold" height="40" @click="stockReceiveModal.show = false" :disabled="stockReceiveModal.processing">Cancelar</v-btn>
                <v-btn color="teal-darken-3" variant="flat" class="btn-rect px-6 font-weight-black" height="40" @click="confirmStockReceive" :loading="stockReceiveModal.processing" :disabled="stockReceiveModal.loading || stockReceiveModal.items.filter(i => i.selected).length === 0">
                    <v-icon start>mdi-check-all</v-icon> Confirmar Recebimento
                </v-btn>
            </div>
        </v-card>
    </v-dialog>

    <v-dialog v-model="consultKeyModal.show" max-width="500" persistent scrim="black opacity-80">
        <v-card class="rounded-lg pa-6" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-grey-darken-4'">
            <div class="d-flex align-center justify-space-between mb-4">
                <h3 class="text-h6 font-weight-black d-flex align-center gap-2">
                    <v-icon color="success">mdi-magnify-scan</v-icon>
                    Buscar nota pela chave
                </h3>
                <v-btn icon="mdi-close" variant="text" density="compact" @click="consultKeyModal.show = false"></v-btn>
            </div>
            <div class="text-body-2 mb-4" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-1' : 'text-grey-lighten-1'">
                Digite a chave de acesso de 44 dígitos para baixar os dados na SEFAZ e importar a nota para o sistema. <strong>Requer uma loja selecionada no filtro do menu superior.</strong>
            </div>
            <v-text-field
                v-model="consultKeyModal.chave"
                label="Chave de Acesso (Apenas números)"
                variant="outlined"
                density="comfortable"
                color="success"
                :disabled="consultKeyModal.loading"
                class="mb-4 font-mono text-caption"
                counter="44"
                maxlength="54"
            ></v-text-field>
            <div class="d-flex gap-3 mt-2">
                <v-btn variant="outlined" class="flex-grow-1 btn-rect" height="45" @click="consultKeyModal.show = false">Cancelar</v-btn>
                <v-btn color="success" variant="flat" class="flex-grow-1 btn-rect font-weight-bold" height="45" @click="executeConsultKey" :loading="consultKeyModal.loading">
                    Buscar e importar
                </v-btn>
            </div>
        </v-card>
    </v-dialog>

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


    <v-dialog v-model="raioXModal.show" max-width="600">
        <v-card class="rounded-xl overflow-hidden border border-grey-lighten-2">
            <v-card-title class="bg-grey-darken-4 text-white d-flex align-center justify-space-between py-3 px-5">
                <div class="d-flex align-center gap-2">
                    <v-icon color="green-accent-3">mdi-radar</v-icon>
                    <span class="font-weight-black text-subtitle-1">Raio-X da Nota (SEFAZ)</span>
                </div>
                <v-btn icon="mdi-close" variant="text" density="compact" color="grey" @click="raioXModal.show = false"></v-btn>
            </v-card-title>

            <v-card-text class="pa-6 bg-grey-lighten-4" style="min-height: 250px;">
                <div v-if="raioXModal.loading" class="d-flex flex-column align-center justify-center py-8">
                    <v-progress-circular indeterminate color="primary" size="48" width="4"></v-progress-circular>
                    <span class="text-caption mt-4 font-weight-bold text-grey-darken-1 text-uppercase letter-spacing-1">Buscando informações da nota...</span>
                </div>

                <div v-else-if="raioXModal.data" class="d-flex flex-column gap-4">
                    <div class="bg-white rounded-lg border px-4 py-3 shadow-sm">
                        <div class="text-[10px] text-grey text-uppercase font-weight-black mb-1">Chave de Acesso</div>
                        <div class="font-mono text-caption bg-blue-grey-lighten-5 pa-2 border rounded select-all text-grey-darken-3">{{ raioXModal.data.chave_acesso }}</div>
                    </div>

                    <v-row dense>
                        <v-col cols="6">
                            <div class="bg-white rounded-lg border px-4 py-3 shadow-sm h-100">
                                <div class="text-[10px] text-grey text-uppercase font-weight-black mb-2">Disponibilidade do XML</div>
                                <v-chip size="small" :color="!raioXModal.data.nota_encontrada ? 'error' : (raioXModal.data.apenas_resumo ? 'warning' : 'success')" variant="flat" class="font-weight-bold px-3 chip-3d">
                                    <v-icon start size="14">{{ !raioXModal.data.nota_encontrada ? 'mdi-close' : (raioXModal.data.apenas_resumo ? 'mdi-alert' : 'mdi-check-all') }}</v-icon>
                                    {{ !raioXModal.data.nota_encontrada ? 'Não Encontrado' : (raioXModal.data.apenas_resumo ? 'Apenas Resumo' : 'XML Completo Liberado') }}
                                </v-chip>
                            </div>
                        </v-col>
                        <v-col cols="6">
                            <div class="bg-white rounded-lg border px-4 py-3 shadow-sm h-100">
                                <div class="text-[10px] text-grey text-uppercase font-weight-black mb-1">Situação de Manifestação</div>
                                <div class="font-weight-black text-body-2 text-primary">{{ raioXModal.data.situacao_manifestacao }}</div>
                            </div>
                        </v-col>
                    </v-row>

                    <div class="d-flex justify-center mt-2" v-if="raioXModal.noteRef?.emitente_nome === 'Emitente Desconhecido' || !raioXModal.noteRef?.valor">
                        <v-btn color="primary" variant="flat" class="font-weight-bold" @click="fixNoteDataFromXml(raioXModal.noteRef)" :loading="fixingNote">
                            <v-icon start>mdi-auto-fix</v-icon> Forçar Correção de Dados (Ler XML)
                        </v-btn>
                    </div>

                    <div class="bg-white rounded-lg border shadow-sm overflow-hidden mt-2">
                        <div class="bg-grey-lighten-3 px-4 py-2 border-b d-flex align-center gap-2">
                            <v-icon size="16" color="grey-darken-2">mdi-history</v-icon>
                            <span class="text-caption font-weight-black text-uppercase text-grey-darken-2">Eventos Vinculados ({{ raioXModal.data.eventos_registrados.length }})</span>
                        </div>
                        <div v-if="raioXModal.data.eventos_registrados.length === 0" class="pa-6 text-center text-caption text-grey font-weight-medium">
                            Nenhum evento ou manifestação foi registrado ainda.
                        </div>
                        <v-list density="compact" class="py-0 bg-transparent" v-else>
                            <v-list-item v-for="(ev, i) in raioXModal.data.eventos_registrados" :key="i" class="border-b py-2 px-4">
                                <template v-slot:prepend>
                                    <div class="bg-blue-lighten-5 rounded-circle p-2 mr-3 border border-blue-lighten-4" style="padding: 6px;">
                                        <v-icon size="16" color="primary">mdi-file-sign</v-icon>
                                    </div>
                                </template>
                                <v-list-item-title class="font-weight-bold text-body-2 text-grey-darken-3">{{ ev.descricao }}</v-list-item-title>
                                <v-list-item-subtitle class="text-[11px] font-mono mt-1 text-grey-darken-1">
                                    Protocolo: {{ ev.protocolo || 'N/A' }} <span class="mx-1">•</span> {{ new Date(ev.data).toLocaleString() }}
                                </v-list-item-subtitle>
                            </v-list-item>
                        </v-list>
                    </div>
                </div>
            </v-card-text>
        </v-card>
    </v-dialog>

    <v-dialog v-model="nfeSyncState.showDetails" max-width="760">
        <v-card class="rounded-xl border-thin shadow-xl" :class="themeStore.currentMode === 'light' ? 'bg-white text-grey-darken-4' : 'bg-grey-darken-4 text-white'">
            <v-card-title class="d-flex align-center justify-space-between px-5 py-4 border-b" :class="themeStore.currentMode === 'light' ? 'border-grey-lighten-2' : 'border-white-10'">
                <div class="d-flex align-center gap-2">
                    <v-icon color="primary">mdi-brain</v-icon>
                    <span class="font-weight-black">IA automática de Notas recebidas</span>
                </div>
                <v-btn icon="mdi-close" variant="text" density="compact" @click="nfeSyncState.showDetails = false"></v-btn>
            </v-card-title>

            <v-card-text class="pa-5">
                <v-alert
                    :type="nfeSyncAlertType"
                    variant="tonal"
                    density="compact"
                    class="mb-4 rounded-lg"
                >
                    <strong>{{ nfeSyncLabel }}</strong>
                    <div class="text-caption mt-1">
                        A IA busca as Notas recebidas automaticamente a cada 2 horas. Ela respeita os tempos de espera da SEFAZ/Nuvem para evitar bloqueios.
                    </div>
                </v-alert>

                <div class="ai-activity-card mb-4" :class="themeStore.currentMode === 'light' ? 'ai-activity-light' : 'ai-activity-dark'">
                    <div class="ai-orb-wrap">
                        <div class="ai-orb"></div>
                        <span class="ai-ring ai-ring-one"></span>
                        <span class="ai-ring ai-ring-two"></span>
                    </div>

                    <div class="flex-grow-1">
                        <div class="d-flex align-center flex-wrap gap-2 mb-1">
                            <span class="text-caption font-weight-black text-uppercase">IA fiscal em atividade</span>
                            <span class="ai-live-dot"></span>
                        </div>
                        <div class="ai-phrase-viewport">
                            <div class="ai-phrase-track">
                                <div>Conferindo novas notas emitidas contra seus CNPJs...</div>
                                <div>Respeitando os horários seguros da SEFAZ para evitar bloqueios...</div>
                                <div>Organizando o que foi encontrado para aparecer no monitor fiscal...</div>
                                <div>Quando uma nota não vier completa, a IA tenta completar no próximo ciclo...</div>
                            </div>
                        </div>
                    </div>
                </div>

                <v-row dense>
                    <v-col cols="12" sm="6">
                        <div class="sync-detail-card">
                            <span class="sync-detail-label">Contexto</span>
                            <strong>{{ activeCompany ? (activeCompany.trade_name || activeCompany.name) : 'Holding / Todas as lojas' }}</strong>
                        </div>
                    </v-col>
                    <v-col cols="12" sm="6">
                        <div class="sync-detail-card">
                            <span class="sync-detail-label">CNPJ acompanhado</span>
                            <strong>{{ activeCompany?.cnpj || 'Todos os CNPJs' }}</strong>
                        </div>
                    </v-col>
                    <v-col cols="12" sm="6">
                        <div class="sync-detail-card">
                            <span class="sync-detail-label">Última sequência consultada</span>
                            <strong>{{ nfeSyncState.current?.ultimo_nsu ?? '---' }}</strong>
                        </div>
                    </v-col>
                    <v-col cols="12" sm="6">
                        <div class="sync-detail-card">
                            <span class="sync-detail-label">Maior sequência encontrada</span>
                            <strong>{{ nfeSyncState.current?.max_nsu ?? '---' }}</strong>
                        </div>
                    </v-col>
                    <v-col cols="12" sm="6">
                        <div class="sync-detail-card">
                            <span class="sync-detail-label">Próxima busca automática</span>
                            <strong>{{ formatDateTime(nfeSyncState.current?.next_run_at) }}</strong>
                        </div>
                    </v-col>
                    <v-col cols="12" sm="6">
                        <div class="sync-detail-card">
                            <span class="sync-detail-label">Pausa até</span>
                            <strong>{{ formatDateTime(nfeSyncState.current?.blocked_until) }}</strong>
                        </div>
                    </v-col>
                    <v-col cols="12" sm="6">
                        <div class="sync-detail-card">
                            <span class="sync-detail-label">Notas recebidas no sistema</span>
                            <strong>{{ nfeSyncState.totalRecebidas }}</strong>
                        </div>
                    </v-col>
                    <v-col cols="12" sm="6">
                        <div class="sync-detail-card">
                            <span class="sync-detail-label">Última nota encontrada</span>
                            <strong>{{ formatDateTime(nfeSyncState.lastDfeSeen) }}</strong>
                        </div>
                    </v-col>
                </v-row>

                <v-alert v-if="nfeSyncState.current?.last_error" type="warning" variant="tonal" density="compact" class="mt-4 rounded-lg">
                    {{ nfeSyncState.current.last_error }}
                </v-alert>

                <v-alert type="info" variant="tonal" density="compact" class="mt-4 rounded-lg">
                    Consulta por chave e envio de XML continuam disponíveis como opções manuais. Evite buscas pesadas repetidas para não causar bloqueio por excesso de tentativas.
                </v-alert>
            </v-card-text>

            <v-card-actions class="px-5 pb-5">
                <v-spacer></v-spacer>
                <v-btn variant="text" class="font-weight-bold" @click="nfeSyncState.showDetails = false">Fechar</v-btn>
                <v-btn color="primary" variant="flat" class="font-weight-bold" :loading="nfeSyncState.loading" @click="fetchNfeSyncStatus">
                    Atualizar status
                </v-btn>
            </v-card-actions>
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
                                    <v-chip size="x-small" :color="getLogChipColor(log.type)" label variant="flat" class="font-weight-bold px-1 chip-3d" style="height: 18px;">
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
import { useUserStore } from '@/stores/user';
import { useCompanyStore } from '@/stores/company';
import { useThemeStore } from '@/stores/themeStore';
import { format, parseISO, addDays, addMonths, isAfter, differenceInSeconds, startOfMonth, endOfMonth, isWithinInterval, startOfWeek, endOfWeek, startOfYear, endOfYear, isSameDay } from 'date-fns';
import axios from 'axios';
import { DANFe } from 'node-sped-pdf';

const formatCurrency = (val: any) => new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(Number(val)||0);
const formatCurrencyValue = (val: any) => new Intl.NumberFormat('pt-BR', { minimumFractionDigits: 2, maximumFractionDigits: 2 }).format(Number(val)||0);

const formatDate = (d: string | Date | null | undefined) => {
    if (!d) return '-';
    try {
        if (d instanceof Date) return format(d, 'dd/MM/yy');
        return format(parseISO(d), 'dd/MM/yy');
    } catch (e) { return '-'; }
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
const userStore = useUserStore();
const companyStore = useCompanyStore();
const companies = ref<any[]>([]);
const activeCompany = ref<any>(null);
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
const stockItems = ref<any[]>([]);

const activeContextId = computed(() => activeCompany.value?.id || 'holding');

const contextButtons = computed(() => [
    { id: 'holding', name: 'HOLDING', isHolding: true },
    ...companies.value.map((company: any) => ({
        id: company.id,
        name: company.trade_name || company.name || company.cnpj,
        isHolding: false
    }))
]);

const nfeSyncState = reactive({
    loading: false,
    current: null as any,
    totalRecebidas: 0,
    lastDfeSeen: null as string | null,
    showDetails: false
});

const nfeSyncLabel = computed(() => {
    const status = nfeSyncState.current?.last_status;

    const map: Record<string, string> = {
        distribution_configured: 'Busca automática configurada',
        nsu_ready: 'Sequência pronta',
        nsu_autocorrected: 'Sequência ajustada pela IA',
        running: 'IA buscando notas agora',
        success: 'Notas atualizadas',
        concluido: 'Notas atualizadas',
        cooldown: 'Pausa obrigatória da SEFAZ/Nuvem',
        blocked: 'Pausa temporária',
        partial_error: 'Busca parcialmente concluída',
        error: 'Erro na busca automática'
    };

    if (!activeCompany.value) return 'Holding: acompanhando todas as lojas';
    return map[status] || status || 'Aguardando primeira busca automática';
});

const nfeSyncAlertType = computed(() => {
    const status = nfeSyncState.current?.last_status;

    if (status === 'blocked' || status === 'cooldown') return 'warning';
    if (status === 'error' || status === 'partial_error') return 'error';
    if (status === 'success' || status === 'concluido' || status === 'nsu_autocorrected') return 'success';

    return 'info';
});

const nfeSyncIsBlocked = computed(() => {
    const blockedUntil = nfeSyncState.current?.blocked_until;
    return !!blockedUntil && new Date(blockedUntil) > new Date();
});

const formatDateTime = (value?: string | null) => {
    if (!value) return '---';

    try {
        return new Date(value).toLocaleString('pt-BR', {
            timeZone: 'America/Sao_Paulo',
            day: '2-digit',
            month: '2-digit',
            year: '2-digit',
            hour: '2-digit',
            minute: '2-digit'
        });
    } catch {
        return '---';
    }
};


const currentPeriod = ref('month');
const customDateStart = ref('');
const customDateEnd = ref('');
const periodLabel = computed(() => {
    const map: any = { 'month': 'Este Mês', 'week': 'Esta Semana', 'today': 'Hoje', 'year': 'Este Ano', 'all': 'Todos', 'custom': 'Personalizado' };
    return map[currentPeriod.value] || 'Período';
});
const setPeriod = (val: string) => { currentPeriod.value = val; };

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
const raioXModal = reactive({ show: false, loading: false, data: null as any, noteRef: null as any });
const launchSuccessModal = reactive({ show: false, payloads: [] as any[] });

const xmlFullStatus = reactive<Record<string, 'ok' | 'missing' | 'checking' | undefined>>({});

const stockReceiveModal = reactive({
    show: false,
    loading: false,
    processing: false,
    note: null as any,
    items: [] as any[],
    selectAll: false
});

const toggleSelectAllStock = () => {
    stockReceiveModal.items.forEach(i => i.selected = stockReceiveModal.selectAll);
};

const openStockReceiveModal = async (note: any) => {
    stockReceiveModal.note = note;
    stockReceiveModal.items = [];
    stockReceiveModal.loading = true;
    stockReceiveModal.processing = false;
    stockReceiveModal.selectAll = false;
    stockReceiveModal.show = true;

    const cnpj = (note.cnpj_destinatario || activeCompany.value?.cnpj)?.replace(/\D/g, '');
    const id = note.xml_link || note.chave;

    if (!cnpj || !id) {
        appStore.showSnackbar('Faltam dados para baixar o XML desta nota.', 'error');
        stockReceiveModal.show = false;
        return;
    }

    try {
        const url = `${SEFAZ_PROXY_URL}/api/baixar-xml/${id}?cnpj=${cnpj}`;
        const response = await axios.get(url, { responseType: 'text' });
        const xmlText = response.data;

        if (!xmlText.includes('<infNFe') || !xmlText.includes('<det')) {
             throw new Error("XML incompleto ou indisponível na SEFAZ. Tente novamente mais tarde.");
        }

        const parser = new DOMParser();
        const xmlDoc = parser.parseFromString(xmlText, "text/xml");
        const detNodes = xmlDoc.getElementsByTagName("det");

        for (let i = 0; i < detNodes.length; i++) {
            const prod = detNodes[i].getElementsByTagName("prod")[0];
            if (prod) {
                const xProd = prod.getElementsByTagName("xProd")[0]?.textContent;
                const qCom = Number(prod.getElementsByTagName("qCom")[0]?.textContent || 0);
                const uCom = prod.getElementsByTagName("uCom")[0]?.textContent;
                const vProd = Number(prod.getElementsByTagName("vProd")[0]?.textContent || 0);

                let matchedId = null;
                if (xProd) {
                    const searchStr = xProd.toLowerCase();
                    const match = stockItems.value.find(s =>
                        s.fabric_type.toLowerCase() === searchStr ||
                        searchStr.includes(s.fabric_type.toLowerCase())
                    );
                    if (match) matchedId = match.id;
                }

                stockReceiveModal.items.push({
                    selected: false,
                    xProd,
                    qCom,
                    uCom,
                    vProd,
                    stock_id: matchedId
                });
            }
        }
    } catch(e: any) {
        appStore.showSnackbar(e.message || 'Erro ao ler itens do XML.', 'error');
        stockReceiveModal.show = false;
    } finally {
        stockReceiveModal.loading = false;
    }
};

const confirmStockReceive = async () => {
    const toProcess = stockReceiveModal.items.filter(i => i.selected);
    if(toProcess.length === 0) return appStore.showSnackbar('Selecione pelo menos um item para receber.', 'warning');

    for(const item of toProcess) {
        if(!item.stock_id) return appStore.showSnackbar(`Selecione o produto de destino para "${item.xProd}".`, 'warning');
        if(item.qCom <= 0) return appStore.showSnackbar(`Quantidade inválida para "${item.xProd}".`, 'warning');
    }

    stockReceiveModal.processing = true;
    try {
        for(const item of toProcess) {
            const { data: currentStock } = await supabase.from('stock').select('available_meters, quantity').eq('id', item.stock_id).single();
            if(currentStock) {
                const newQty = Number(currentStock.available_meters || 0) + item.qCom;
                const { error } = await supabase.from('stock').update({ available_meters: newQty, quantity: newQty }).eq('id', item.stock_id);

                if(!error) {
                    await supabase.from('stock_movements').insert({
                        product_id: item.stock_id,
                        movement_type: 'entrada',
                        quantity_moved: item.qCom,
                        old_quantity: currentStock.available_meters || 0,
                        new_quantity: newQty,
                        user_id: userStore.user?.id,
                        notes: `Entrada via NFe ${stockReceiveModal.note.chave}`
                    });
                }
            }
        }
        appStore.showSnackbar('Estoque recebido e atualizado com sucesso!', 'success');
        stockReceiveModal.show = false;
    } catch(e: any) {
        appStore.showSnackbar('Erro ao receber estoque: ' + e.message, 'error');
    } finally {
        stockReceiveModal.processing = false;
    }
};

// --- MODAL DE CONSULTA DE CHAVE DE ACESSO ---
const consultKeyModal = reactive({
    show: false,
    chave: '',
    loading: false
});

const openConsultKeyModal = () => {
    if (!activeCompany.value?.cnpj) {
        appStore.showSnackbar('Escolha uma loja específica antes de buscar pela chave.', 'warning');
        return;
    }
    consultKeyModal.chave = '';
    consultKeyModal.show = true;
};

const executeConsultKey = async () => {
    const chave = consultKeyModal.chave.replace(/\D/g, '');
    if (chave.length !== 44) {
        appStore.showSnackbar('A chave de acesso deve conter exatamente 44 números.', 'warning');
        return;
    }

    const cnpj = activeCompany.value?.cnpj?.replace(/\D/g, '');
    if (!cnpj) return;

    consultKeyModal.loading = true;

    try {
        const raioXRes = await axios.get(`${SEFAZ_PROXY_URL}/api/status-nota/${chave}?cnpj=${cnpj}`);
        const statusData = raioXRes.data.data;

        if (!statusData.nota_encontrada && !statusData.id_nuvem_nota) {
            throw new Error("A SEFAZ recusou ou não encontrou o documento para este CNPJ.");
        }

        let emitenteNome = statusData.emitente !== 'N/A' ? statusData.emitente : 'Emitente Desconhecido';
        let valor = statusData.valor || 0;
        let emitenteCnpj = null;
        let dataEmissao = new Date().toISOString();

        if (statusData.id_nuvem_nota) {
            try {
                const xmlRes = await axios.get(`${SEFAZ_PROXY_URL}/api/baixar-xml/${statusData.id_nuvem_nota}?cnpj=${cnpj}`, { responseType: 'text' });

                if (xmlRes.data) {
                    const parser = new DOMParser();
                    const xmlDoc = parser.parseFromString(xmlRes.data, "text/xml");

                    if (xmlRes.data.includes('<infNFe')) {
                        const emit = xmlDoc.getElementsByTagName("emit")[0];
                        if (emit) {
                            emitenteNome = emit.getElementsByTagName("xNome")[0]?.textContent || emitenteNome;
                            emitenteCnpj = emit.getElementsByTagName("CNPJ")[0]?.textContent || emit.getElementsByTagName("CPF")[0]?.textContent || null;
                        }
                        const total = xmlDoc.getElementsByTagName("ICMSTot")[0];
                        if (total) valor = Number(total.getElementsByTagName("vNF")[0]?.textContent || valor);
                        const ide = xmlDoc.getElementsByTagName("ide")[0];
                        if (ide) dataEmissao = ide.getElementsByTagName("dhEmi")[0]?.textContent || dataEmissao;
                    } else if (xmlRes.data.includes('<resNFe')) {
                        const resNFe = xmlDoc.getElementsByTagName("resNFe")[0];
                        if (resNFe) {
                            emitenteNome = resNFe.getElementsByTagName("xNome")[0]?.textContent || emitenteNome;
                            emitenteCnpj = resNFe.getElementsByTagName("CNPJ")[0]?.textContent || resNFe.getElementsByTagName("CPF")[0]?.textContent || null;
                            valor = Number(resNFe.getElementsByTagName("vNF")[0]?.textContent || valor);
                            dataEmissao = resNFe.getElementsByTagName("dhEmi")[0]?.textContent || dataEmissao;
                        }
                    }
                }
            } catch (xmlErr) {
                console.warn("Falha ao ler XML detalhado. Salvando dados básicos do Raio-X.", xmlErr);
            }
        }

        const dbEntry = {
             chave: chave,
             emitente_nome: emitenteNome,
             emitente_cnpj: emitenteCnpj,
             cnpj_destinatario: cnpj,
             valor: valor,
             data_emissao: dataEmissao,
             situacao_manifestacao: statusData.situacao_manifestacao !== 'Nao Informado' ? statusData.situacao_manifestacao : 'Ciencia',
             situacao_sefaz: 'Autorizada',
             status_processamento: 'aguardando_xml',
             xml_link: statusData.id_nuvem_nota || null
        };

        const { error } = await supabase.from('dfe_entries').upsert(dbEntry, { onConflict: 'chave' });
        if (error) throw error;

        const existingIndex = notes.value.findIndex(n => n.chave === chave);
        if (existingIndex > -1) {
            notes.value[existingIndex] = { ...notes.value[existingIndex], ...dbEntry };
        } else {
            notes.value.unshift(dbEntry);
        }

        pendingNotes.value = pendingNotes.value.filter(n => n.chave_acesso !== chave);
        pendingCount.value = pendingNotes.value.length;

        appStore.showSnackbar('Nota encontrada e importada com sucesso!', 'success');
        consultKeyModal.show = false;

        if (emitenteNome === 'Emitente Desconhecido' || valor === 0) {
            setTimeout(() => fixNoteDataFromXml(dbEntry), 3000);
        }

    } catch (e: any) {
        console.error(e);
        appStore.showSnackbar('Não foi possível encontrar a nota. Confira se a chave pertence ao CNPJ desta loja.', 'error');
    } finally {
        consultKeyModal.loading = false;
    }
};


const loadXmlCache = () => {
  try {
    const cached = localStorage.getItem('sefaz_xml_status_cache');
    if (cached) Object.assign(xmlFullStatus, JSON.parse(cached));
  } catch (e) { console.error(e); }
};

const saveXmlCache = () => {
  try {
    const toSave = Object.keys(xmlFullStatus).reduce((acc, key) => {
      if (xmlFullStatus[key] === 'ok') acc[key] = 'ok';
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

const getCompanyName = (cnpj: string) => {
    if (!cnpj) return '-';
    const clean = cnpj.replace(/\D/g, '');
    const comp = companies.value.find(c => c.cnpj && c.cnpj.replace(/\D/g, '') === clean);
    return comp ? comp.name.substring(0, 15) : clean;
};

const fixingNote = ref(false);
const fixNoteDataFromXml = async (note: any) => {
    const cnpj = (note.cnpj_destinatario || note.cnpj || activeCompany.value?.cnpj)?.replace(/\D/g, '');
    if (!cnpj || !note.chave) return;

    fixingNote.value = true;
    try {
        const url = `${SEFAZ_PROXY_URL}/api/baixar-xml/${note.xml_link || note.chave}?cnpj=${cnpj}`;
        const response = await axios.get(url, { responseType: 'text' });

        if (response.data && response.data.includes('<infNFe')) {
            const parser = new DOMParser();
            const xmlDoc = parser.parseFromString(response.data, "text/xml");

            const emit = xmlDoc.getElementsByTagName("emit")[0];
            const xNome = emit ? emit.getElementsByTagName("xNome")[0]?.textContent : null;
            const cnpjEmit = emit ? (emit.getElementsByTagName("CNPJ")[0]?.textContent || emit.getElementsByTagName("CPF")[0]?.textContent) : null;

            const total = xmlDoc.getElementsByTagName("ICMSTot")[0];
            const vNF = total ? total.getElementsByTagName("vNF")[0]?.textContent : null;

            const ide = xmlDoc.getElementsByTagName("ide")[0];
            const dhEmi = ide ? ide.getElementsByTagName("dhEmi")[0]?.textContent : null;

            let updated = false;
            const updates: any = {};

            if (xNome && note.emitente_nome === 'Emitente Desconhecido') {
                note.emitente_nome = xNome; updates.emitente_nome = xNome; updated = true;
            }
            if (cnpjEmit && !note.emitente_cnpj) {
                note.emitente_cnpj = cnpjEmit; updates.emitente_cnpj = cnpjEmit; updated = true;
            }
            if (vNF && (!note.valor || note.valor === 0)) {
                note.valor = Number(vNF); updates.valor = Number(vNF); updated = true;
            }
            if (dhEmi && (!note.data_emissao || note.data_emissao === '-')) {
                note.data_emissao = dhEmi; updates.data_emissao = dhEmi; updated = true;
            }

            if (updated) {
                await supabase.from('dfe_entries').update(updates).eq('chave', note.chave);
                appStore.showSnackbar('Dados da nota corrigidos a partir do XML!', 'success');
            }
        }
    } catch(e) {
        console.warn('Auto-fix failed', e);
    } finally {
        fixingNote.value = false;
    }
};

const checkFullXml = async (note: any) => {
  const key = getNoteKey(note);
  if (!key) return;

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

const selectedPending = ref<string[]>([]);
const bulkLoading = ref(false);

const areAllSelected = computed(() => {
    const currentKeys = paginatedNotes.value.map((n: any) => n.normalized_key);
    return currentKeys.length > 0 && currentKeys.every((k: string) => selectedPending.value.includes(k));
});

const toggleSelectAll = (val: boolean) => {
    const currentKeys = paginatedNotes.value.map((n: any) => n.normalized_key);
    if (val) {
        const newSelection = new Set([...selectedPending.value, ...currentKeys]);
        selectedPending.value = Array.from(newSelection);
    } else {
        selectedPending.value = selectedPending.value.filter(k => !currentKeys.includes(k));
    }
};

const findSelectedFiscalNote = (selectionKey: string) => {
    return unifiedNotes.value.find((note: any) => note.normalized_key === selectionKey) || null;
};

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

const unifiedNotes = computed(() => {
    const apiNormalized = pendingNotes.value.map(n => ({
        ...n,
        normalized_key: `api-${n.chave_acesso}`,
        chave: n.chave_acesso,
        emitente_nome: n.emitente_nome_razao_social,
        valor: n.valor_nfe,
        cnpj_destinatario: n.cnpj,
        data_emissao: n.data_emissao || n.dhEmi || n.emissao || new Date().toISOString(),
        source: 'api',
        situacao_manifestacao: 'NaoInformado',
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

    if (activeCompany.value && activeCompany.value.cnpj) {
        const activeClean = activeCompany.value.cnpj.replace(/\D/g, '');
        combined = combined.filter(n => {
            const noteCnpj = String(n.cnpj_destinatario || n.cnpj || '').replace(/\D/g, '');
            return noteCnpj === activeClean;
        });
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

    if (currentPeriod.value !== 'all' && currentTab.value !== 'archived') {
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
                if (!n.data_emissao) return true;
                try {
                    const date = parseISO(n.data_emissao);
                    if (isNaN(date.getTime())) return true;
                    if (currentPeriod.value === 'today') return isSameDay(date, now);
                    return isWithinInterval(date, { start: start!, end: end! });
                } catch (e) {
                    return true;
                }
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

const recalcInstallments = () => { generateProjections(payableModal.note, null, true); };
const applyStatusToAll = (newStatus: string) => { if (payableForm.customInstallments.length > 0) payableForm.customInstallments.forEach(i => i.status = newStatus); };

const addLog = (type: 'INFO' | 'SUCCESS' | 'ERROR' | 'API' | 'WARNING', message: string, details?: any) => {
    if (!Array.isArray(systemLogs.value)) systemLogs.value = [];
    systemLogs.value.unshift({ time: new Date().toLocaleTimeString(), type, message, details: details ? JSON.stringify(details, null, 2) : null });
};
const getLogChipColor = (type: string) => {
    if (type === 'ERROR') return 'red-darken-1'; if (type === 'WARNING') return 'orange-darken-3';
    if (type === 'SUCCESS') return 'green-darken-1'; if (type === 'API') return 'blue-darken-1'; return 'grey-darken-1';
};
const getLogMessageColor = (type: string) => {
    if (type === 'ERROR') return 'text-red-lighten-1'; if (type === 'WARNING') return 'text-orange-lighten-2';
    if (type === 'SUCCESS') return 'text-green-lighten-1'; return 'text-grey-lighten-3';
};
const copyAllLogs = () => {
    if (!systemLogs.value) return;
    const text = systemLogs.value.map(l => `[${l.time}] [${l.type}] ${l.message} ${l.details || ''}`).join('\n');
    navigator.clipboard.writeText(text); appStore.showSnackbar('Copiado!', 'success');
};
const filteredLogs = computed(() => {
    const logs = Array.isArray(systemLogs.value) ? systemLogs.value : [];
    if (logFilter.value === 'ALL') return logs;
    return logs.filter(l => l.type === logFilter.value);
});
const errorCount = computed(() => Array.isArray(systemLogs.value) ? systemLogs.value.filter(l => l.type === 'ERROR').length : 0);
const successCount = computed(() => Array.isArray(systemLogs.value) ? systemLogs.value.filter(l => l.type === 'SUCCESS').length : 0);

const loadCompanies = async () => {
   loadingCompanies.value = true;
   try {
      const { data, error } = await supabase.from('companies').select('*');
      if (error) throw error;
      companies.value = data || [];

      const preferredContext = companyStore.context && companyStore.context !== 'holding'
          ? companyStore.context
          : 'holding';

      const selectedCompany = companies.value.find((company: any) => company.id === preferredContext) || null;
      activeCompany.value = selectedCompany;

      await refreshFiscalMonitor();

      const { data: charts } = await supabase.from('finance_chart_of_accounts').select('id, name').eq('type', 'Despesa').order('name');
      chartOfAccounts.value = charts || [];

      const { data: stockData } = await supabase.from('stock').select('id, fabric_type, available_meters, unit_of_measure').order('fabric_type');
      stockItems.value = stockData || [];

   } catch (e) { addLog('ERROR', 'Falha ao carregar dados iniciais', e); }
   finally { loadingCompanies.value = false; }
};

const setCompanyFilter = (contextId: string) => {
   const company = contextId === 'holding'
       ? null
       : companies.value.find((item: any) => item.id === contextId) || null;

   switchCompany(company);
};

const switchCompany = (company: any) => {
   activeCompany.value = company;
   optimisticNotes.value = [];
   const cnpj = company ? company.cnpj : null;

   if (companyStore.setContext) companyStore.setContext(company ? company.id : 'holding');
   if (company && companyStore.setActiveCompany) companyStore.setActiveCompany(company);

   if(cnpj) addLog('INFO', `Trocando empresa para ${company.trade_name || company.name}`);
   else addLog('INFO', `Visualizando Holding / Todas as Lojas`);

   refreshFiscalMonitor();
};

const refreshFiscalMonitor = async () => {
   const cnpj = activeCompany.value ? activeCompany.value.cnpj : null;

   await fetchStoredNotes(cnpj);
   await fetchPendingNotesFromApi(cnpj);
   await fetchNfeSyncStatus();

   lastSyncTime.value = format(new Date(), 'HH:mm');
};

const fetchNfeSyncStatus = async () => {
    nfeSyncState.loading = true;

    try {
        const cnpj = activeCompany.value?.cnpj?.replace(/\D/g, '') || null;
        const ambiente = activeCompany.value?.nfe_environment === 'homologacao' ? 'homologacao' : 'producao';

        if (cnpj) {
            const { data: syncRow, error: syncError } = await supabase
                .from('nfe_distribution_sync_state')
                .select('*')
                .eq('cnpj', cnpj)
                .eq('ambiente', ambiente)
                .maybeSingle();

            if (syncError) throw syncError;
            nfeSyncState.current = syncRow;
        } else {
            const { data: states, error: statesError } = await supabase
                .from('nfe_distribution_sync_state')
                .select('*')
                .eq('ambiente', 'producao')
                .order('next_run_at', { ascending: true });

            if (statesError) throw statesError;

            const rows = states || [];
            const blocked = rows.find((row: any) => row.blocked_until && new Date(row.blocked_until) > new Date());
            const errored = rows.find((row: any) => row.last_status === 'error' || row.last_status === 'partial_error');

            nfeSyncState.current = blocked || errored || rows[0] || null;
        }

        let dfeQuery = supabase
            .from('dfe_entries')
            .select('last_seen_at', { count: 'exact' })
            .order('last_seen_at', { ascending: false })
            .limit(1);

        if (cnpj) dfeQuery = dfeQuery.eq('cnpj_destinatario', cnpj);

        const { count, data: latestDfe, error: dfeError } = await dfeQuery;

        if (dfeError) throw dfeError;

        nfeSyncState.totalRecebidas = count || 0;
        nfeSyncState.lastDfeSeen = latestDfe?.[0]?.last_seen_at || null;
    } catch (error: any) {
        addLog('ERROR', 'Erro ao consultar status da IA automática de NFe', error.message || error);
    } finally {
        nfeSyncState.loading = false;
    }
};

const fetchStoredNotes = async (cnpj: string | null) => {
    loading.value = true;
    try {
        let query = supabase.from('dfe_entries').select('*').order('data_emissao', { ascending: false });

        if (cnpj) {
            const cleanCnpj = cnpj.replace(/\D/g, '');
            query = query.or(`cnpj_destinatario.eq.${cleanCnpj},cnpj_destinatario.eq.${cnpj}`);
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
            const cleanC = c.replace(/\D/g, '');
            const res = await axios.get(`${SEFAZ_PROXY_URL}/api/notas-sem-manifestacao`, {
                params: { cnpj: cleanC, ambiente: 'producao', conclusiva: true }
            });
            const raw = res.data.data || [];
            const formatted = raw.map((n: any) => ({ ...n, cnpj: cleanC }));
            pendingNotes.value.push(...formatted);
        } catch (e) {
            console.error(`Falha ao buscar pendentes para ${c}`);
        }
    }
    const existingKeys = new Set(notes.value.map(n => n.chave));
    pendingNotes.value = pendingNotes.value.filter((n: any) => !existingKeys.has(n.chave_acesso));
    pendingCount.value = pendingNotes.value.length;
};

const syncNotesFromSefaz = async (_forcedNsu?: number) => {
   appStore.showSnackbar('A IA busca novas notas sozinha a cada 2 horas. Use Atualizar tela para ver o que já entrou no sistema.', 'info');
   nfeSyncState.showDetails = true;
   await fetchNfeSyncStatus();
};


const openManifestModal = (note: any) => {
    manifestModal.note = note;
    manifestModal.show = true;
};

const openRaioXModal = async (note: any) => {
    const chave = note.chave || note.chave_acesso;
    const cnpj = (note.cnpj_destinatario || note.cnpj || activeCompany.value?.cnpj)?.replace(/\D/g, '');

    if (!chave || !cnpj) return appStore.showSnackbar('Falta Chave ou CNPJ para consultar status.', 'error');

    raioXModal.show = true;
    raioXModal.loading = true;
    raioXModal.data = null;
    raioXModal.noteRef = note;

    try {
        const response = await axios.get(`${SEFAZ_PROXY_URL}/api/status-nota/${chave}?cnpj=${cnpj}`);
        raioXModal.data = response.data.data;
        addLog('SUCCESS', `Raio-X carregado: Chave ${chave}`);

        if (note.emitente_nome === 'Emitente Desconhecido' || !note.valor) {
            await fixNoteDataFromXml(note);
        }

    } catch (error: any) {
        addLog('ERROR', `Erro Raio-X: ${error.message}`);
        appStore.showSnackbar('Nota não processada completamente pela SEFAZ ainda.', 'error');
        raioXModal.show = false;
    } finally {
        raioXModal.loading = false;
    }
};

const manifestNote = async (note: any, tipo: 'ciencia' | 'confirmacao' | 'desconhecimento' | 'nao_realizada', fromPending: boolean = false, silent: boolean = false) => {
    const chaveParaManifestar = note.chave || note.chave_acesso;

    const cnpjAlvoRaw = note.cnpj_destinatario || note.cnpj || activeCompany.value?.cnpj;
    const cnpjAlvo = cnpjAlvoRaw ? cnpjAlvoRaw.replace(/\D/g, '') : null;

    if (!cnpjAlvo || !chaveParaManifestar) {
        appStore.showSnackbar('Erro: CNPJ da empresa ou Chave não identificados.', 'error');
        return;
    }

    let justificativa = '';
    if (tipo === 'nao_realizada' || tipo === 'desconhecimento') {
        const just = prompt(`ATENÇÃO!\nInsira uma justificativa para ${tipo === 'nao_realizada' ? 'Operação Não Realizada' : 'Desconhecimento'} (Mínimo 15 caracteres):`);
        if (!just || just.length < 15) {
            appStore.showSnackbar('A justificativa precisa ter pelo menos 15 caracteres.', 'warning');
            return;
        }
        justificativa = just;
    } else {
        if (!silent && !fromPending && !confirm(`Confirma a manifestação de ${tipo.toUpperCase()}?`)) return;
    }

    addLog('INFO', `Manifestando nota ${chaveParaManifestar} como ${tipo}`);
    loadingManifest.value = chaveParaManifestar;

    try {
        await axios.post(`${SEFAZ_PROXY_URL}/api/manifestar`, {
            chave: chaveParaManifestar,
            cnpj: cnpjAlvo,
            tipo: tipo,
            justificativa: justificativa
        });

        let newStatus = 'Ciencia';
        if (tipo === 'confirmacao') newStatus = 'Confirmada';
        if (tipo === 'desconhecimento') newStatus = 'Desconhecida';
        if (tipo === 'nao_realizada') newStatus = 'Nao Realizada';

        try {
            if (cnpjAlvo) {
                const nsuKey = `sefaz_last_nsu_${cnpjAlvo.replace(/\D/g, '')}`;
                const current = Number(localStorage.getItem(nsuKey) || 0);
                const back = Math.max(0, current - 1500);
                addLog('INFO', `Pós-manifestação: re-sync`);
                await syncNotesFromSefaz(back);
            }
        } catch (e: any) {
            addLog('WARNING', `Falha no re-sync: ${e.message}`);
        }

        if (fromPending) {
             const dbEntry = {
                 chave: chaveParaManifestar,
                 emitente_nome: note.emitente_nome_razao_social || 'Emitente Desconhecido',
                 emitente_cnpj: note.emitente_cnpj || note.cpf_cnpj_emitente,
                 cnpj_destinatario: cnpjAlvo,
                 valor: note.valor_nfe || note.valor_total || 0,
                 data_emissao: note.data_emissao || note.created_at || new Date().toISOString(),
                 situacao_manifestacao: newStatus,
                 situacao_sefaz: 'Manifestação Realizada',
                 status_processamento: 'aguardando_xml',
                 xml_link: null
             };
             await supabase.from('dfe_entries').upsert(dbEntry, { onConflict: 'chave' });

             notes.value.unshift(dbEntry);
             pendingNotes.value = pendingNotes.value.filter(n => n.chave_acesso !== chaveParaManifestar);
             pendingCount.value = pendingNotes.value.length;

             appStore.showSnackbar('Nota manifestada e movida para a base!', 'success');
             await fixNoteDataFromXml(dbEntry);
        } else {
             await supabase.from('dfe_entries').update({ situacao_manifestacao: newStatus }).eq('chave', chaveParaManifestar);
             note.situacao_manifestacao = newStatus;
             if(!silent) appStore.showSnackbar('Status salvo com sucesso.', 'success');
        }
    } catch (e: any) {
        addLog('ERROR', `Falha manifestação: ${e.response?.data?.message || e.message}`);
        if(!silent) appStore.showSnackbar('Erro: ' + (e.response?.data?.message || e.message), 'error');
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
                 cnpj_destinatario: (note.cnpj || activeCompany.value?.cnpj)?.replace(/\D/g, ''),
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
            const chave = note.chave || note.chave_acesso;
            const { error } = await supabase.from('dfe_entries').update({ status_processamento: 'arquivado' }).eq('chave', chave);
            if (error) throw error;

            const idx = notes.value.findIndex((n: any) => n.chave === chave);
            if (idx >= 0) {
                notes.value[idx] = { ...notes.value[idx], status_processamento: 'arquivado' };
            }

            note.status_processamento = 'arquivado';
        }
        appStore.showSnackbar('Nota arquivada com sucesso.', 'success');
    } catch (e: any) {
        appStore.showSnackbar('Erro ao arquivar: ' + e.message, 'error');
        throw e;
    }
};

const archiveSelectedNotes = async () => {
    if (selectedPending.value.length === 0) return;
    if (!confirm(`Deseja arquivar ${selectedPending.value.length} nota(s)?`)) return;

    bulkLoading.value = true;
    let successCount = 0;
    let failCount = 0;

    try {
        for (const selectionKey of selectedPending.value) {
            const note = findSelectedFiscalNote(selectionKey);

            if (!note) {
                failCount++;
                continue;
            }

            try {
                await archiveNote(note, note.source === 'api');
                successCount++;
            } catch (err) {
                failCount++;
                console.error(`Erro ao arquivar nota selecionada ${selectionKey}`, err);
            }
        }

        selectedPending.value = [];

        if (successCount > 0) {
            appStore.showSnackbar(`${successCount} nota(s) arquivada(s) com sucesso.`, 'success');
        }

        if (failCount > 0) {
            appStore.showSnackbar(`${failCount} nota(s) não puderam ser arquivada(s).`, 'warning');
        }

        await refreshFiscalMonitor();
    } catch (e: any) {
        appStore.showSnackbar('Erro no arquivamento em massa: ' + e.message, 'error');
    } finally {
        bulkLoading.value = false;
    }
};

const confirmSelectedNotes = async () => {
    if (selectedPending.value.length === 0) return;

    const apiSelections = selectedPending.value
        .map(findSelectedFiscalNote)
        .filter((note: any) => note && note.source === 'api');

    if (apiSelections.length === 0) {
        appStore.showSnackbar('Selecione notas recém-encontradas para confirmar em massa.', 'warning');
        return;
    }

    if (!confirm(`Deseja confirmar ${apiSelections.length} nota(s) recém-encontrada(s)?`)) return;

    bulkLoading.value = true;
    let successCount = 0;
    let failCount = 0;

    try {
        for (const note of apiSelections) {
            try {
                await manifestNote(note, 'confirmacao', true, true);
                successCount++;
            } catch (err) {
                failCount++;
                console.error(`Erro ao confirmar nota ${note.chave_acesso || note.chave}`, err);
            }
        }

        selectedPending.value = [];
        appStore.showSnackbar(`${successCount} nota(s) confirmada(s).`, successCount > 0 ? 'success' : 'warning');

        if (failCount > 0) {
            appStore.showSnackbar(`${failCount} nota(s) não puderam ser confirmada(s).`, 'warning');
        }

        await refreshFiscalMonitor();
    } catch (e: any) {
        appStore.showSnackbar('Erro na confirmação em massa: ' + e.message, 'error');
    } finally {
        bulkLoading.value = false;
    }
};


const unarchiveNote = async (note: any) => {
    if (!confirm('Desarquivar e retornar para a lista ativa?')) return;
    try {
        const chave = note.chave || note.chave_acesso;
        const { error } = await supabase.from('dfe_entries').update({ status_processamento: 'aguardando_xml' }).eq('chave', chave);
        if (error) throw error;

        const idx = notes.value.findIndex((n: any) => n.chave === chave);
        if (idx >= 0) {
            notes.value[idx] = { ...notes.value[idx], status_processamento: 'aguardando_xml' };
        }

        note.status_processamento = 'aguardando_xml';
        appStore.showSnackbar('Nota desarquivada!', 'success');
        await refreshFiscalMonitor();
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
             const url = `${SEFAZ_PROXY_URL}/api/baixar-xml/${note.xml_link || note.chave}?cnpj=${cnpj}`;
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

    if (note.cnpj_destinatario) {
        const destClean = note.cnpj_destinatario.replace(/\D/g, '');
        const matched = companies.value.find(c => c.cnpj && c.cnpj.replace(/\D/g, '') === destClean);
        if (matched) payableForm.company_id = matched.id;
    }

    if (chartOfAccounts.value.length > 0) payableForm.chart_of_accounts_id = chartOfAccounts.value[0].id;

    try {
       const id = note.xml_link || note.chave;
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
                generateProjections(note, null, true);
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

        if (payableForm.customInstallments && payableForm.customInstallments.length > 0) {
             for (const parc of payableForm.customInstallments) {
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
                     company_id: payableForm.company_id,
                     payment_date: parc.status === 'Pago' ? new Date().toISOString().split('T')[0] : null
                 });
             }
        } else {
             await generateProjections(note, payloads);
        }

        const { error: financeError } = await supabase.from('finance_payables').insert(payloads);
        if (financeError) throw new Error('Erro no banco: ' + financeError.message);

        launchSuccessModal.payloads = payloads;
        launchSuccessModal.show = true;

        const nowIso = new Date().toISOString();
        let upError = null;

        try {
             const { error } = await supabase
                .from('dfe_entries')
                .update({ status_processamento: 'contas_a_pagar_gerado', launched_at: nowIso })
                .eq('chave', note.chave);
             upError = error;
        } catch (err) {}

        if (upError || !upError) {
             if(upError) {
                 console.warn("Falha ao atualizar data (coluna inexistente?), tentando apenas status...");
                 const { error: retryError } = await supabase
                    .from('dfe_entries')
                    .update({ status_processamento: 'contas_a_pagar_gerado' })
                    .eq('chave', note.chave);
                 if (retryError) throw retryError;
             }
        }

        const sourceNote = notes.value.find(n => n.chave === note.chave);
        if (sourceNote) {
            sourceNote.status_processamento = 'contas_a_pagar_gerado';
            sourceNote.launched_at = nowIso;
        }

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
            date: format(currentDueDate, 'yyyy-MM-dd'),
            number: i + 1,
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

        let upError = null;
        try {
             const { error } = await supabase.from('dfe_entries').update({ status_processamento: newStatus, launched_at: null }).eq('chave', note.chave);
             upError = error;
        } catch { }

        if (upError) {
             const { error: retry } = await supabase.from('dfe_entries').update({ status_processamento: newStatus }).eq('chave', note.chave);
             if (retry) throw new Error('Erro ao atualizar status: ' + retry.message);
        }

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
      if (note.chave) {
          const id = note.xml_link || note.chave;
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
         const url = `${SEFAZ_PROXY_URL}/api/baixar-xml/${note.xml_link || note.chave}?cnpj=${cnpj}`;
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
        let sanitized = xmlContent.replace(/<dVenc>(\d{4}-\d{2}-\d{2})<\/dVenc>/g, '<dVenc>$1T12:00:00</dVenc>');
        sanitized = sanitized.replace(/<dhEmi>(\d{4}-\d{2}-\d{2})<\/dhEmi>/g, '<dhEmi>$1T12:00:00</dhEmi>');

        sanitized = sanitized.replace(/<cobr[\s\S]*?<\/cobr>/gi, '');
        sanitized = sanitized.replace(/<fat[\s\S]*?<\/fat>/gi, '');
        sanitized = sanitized.replace(/<dup[\s\S]*?<\/dup>/gi, '');
        sanitized = sanitized.replace(/<[a-zA-Z0-9]+:cobr[\s\S]*?<\/[a-zA-Z0-9]+:cobr>/gi, '');

        const pdfResult = await DANFe({ xml: sanitized });
        const pdfBytes = (pdfResult instanceof Blob) ? await pdfResult.arrayBuffer() : pdfResult;

        const blob = new Blob([pdfBytes], { type: 'application/pdf' });
        danfeModal.url = URL.createObjectURL(blob);

    } catch (e: any) {
        console.error("Render failed completely", e);
        appStore.showSnackbar(`Erro ao processar PDF da DANFE local: ${e.message || 'Falha desconhecida'}`, 'error');
    }
};

const deleteNote = async (note: any) => {
    if(!confirm('Remover da lista?')) return;
    if (note.is_optimistic) { optimisticNotes.value = optimisticNotes.value.filter(n => n.chave !== note.chave); return; }
    await supabase.from('dfe_entries').delete().eq('chave', note.chave);
    notes.value = notes.value.filter(n => n.chave !== note.chave);
};


const rescueDeletedNotes = async (deepScan: boolean = false) => {
    if (deepScan) {
        appStore.showSnackbar('A busca pesada foi desativada nesta tela para evitar bloqueio por excesso de tentativas. Use consulta por chave ou aguarde a IA automática.', 'warning');
        nfeSyncState.showDetails = true;
        return;
    }

    const cnpjAlvoRaw = activeCompany.value?.cnpj;
    if (!cnpjAlvoRaw) {
        appStore.showSnackbar('Selecione uma loja específica para recuperação manual. No modo Holding, a IA automática acompanha todas as lojas.', 'warning');
        return;
    }

    const cnpjAlvo = cnpjAlvoRaw.replace(/\D/g, '');

    if (!confirm('Recuperação manual deve ser usada apenas como último recurso. Deseja buscar histórico recente para esta loja?')) return;

    bulkLoading.value = true;
    appStore.showSnackbar('Buscando histórico recente na Nuvem Fiscal...', 'info');

    try {
        const response = await axios.get(`${SEFAZ_PROXY_URL}/api/consultar-notas?cnpj=${cnpjAlvo}&deep_scan=false`);
        const notasNuvem = response.data.data || [];

        let recuperadas = 0;

        for (const n of notasNuvem) {
            const existeLocal = notes.value.find((local: any) => local.chave === n.chave);
            const existePending = pendingNotes.value.find((pend: any) => pend.chave_acesso === n.chave);

            if (!existeLocal && !existePending) {
                const dbEntry = {
                     chave: n.chave || n.chave_acesso,
                     emitente_nome: n.emitente || n.nome_emitente || n.emitente_nome_razao_social || 'Emitente Desconhecido',
                     emitente_cnpj: n.cnpj_emitente || n.cpf_cnpj_emitente || null,
                     cnpj_destinatario: cnpjAlvo,
                     valor: n.valor || n.valor_nfe || n.valor_total || 0,
                     data_emissao: n.emissao || n.data_emissao || n.dhEmi || new Date().toISOString(),
                     situacao_manifestacao: n.situacao_manifestacao || 'Confirmada',
                     situacao_sefaz: n.situacao_sefaz || 'Autorizada',
                     status_processamento: 'aguardando_xml',
                     xml_link: n.xml_link || n.id || null,
                     forma_distribuicao: 'recuperacao_manual',
                     last_seen_at: new Date().toISOString(),
                     raw_payload: n
                };

                await supabase.from('dfe_entries').upsert(dbEntry, { onConflict: 'chave' });
                notes.value.unshift(dbEntry);
                recuperadas++;
            }
        }

        if (recuperadas > 0) {
            appStore.showSnackbar(`${recuperadas} notas ausentes foram restauradas/importadas com sucesso!`, 'success');
        } else {
            appStore.showSnackbar('Nenhuma nota ausente encontrada no histórico recente.', 'info');
        }

        await refreshFiscalMonitor();

    } catch (e: any) {
        appStore.showSnackbar('Erro ao tentar resgatar notas: ' + (e.response?.data?.message || e.message), 'error');
    } finally {
        bulkLoading.value = false;
    }
};


const triggerXmlInput = () => { if (xmlInput.value) xmlInput.value.click(); };
const handleXmlUpload = (e: any) => { console.log('Upload de XML local pendente'); };
const openCertModal = () => { certModal.show = true; };
const handleCertUpload = () => { loadCompanies(); certModal.show = false; };

onMounted(() => { loadCompanies(); loadXmlCache(); startSyncCountdown(); });
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


.btn-rect {
  border-radius: 10px !important;
  text-transform: none !important;
  font-weight: 900 !important;
  letter-spacing: .2px;
}
.btn-3d {
  box-shadow: 0 2px 0 rgba(0,0,0,0.13), 0 5px 10px rgba(0,0,0,0.10), inset 0 1px 0 rgba(255,255,255,0.18) !important;
  transform: translateY(0);
  transition: transform .14s ease, box-shadow .14s ease, filter .14s ease;
}
.btn-3d:hover {
  filter: brightness(1.02);
  transform: translateY(-1px);
  box-shadow: 0 3px 0 rgba(0,0,0,0.13), 0 7px 12px rgba(0,0,0,0.12), inset 0 1px 0 rgba(255,255,255,0.22) !important;
}
.btn-3d:active {
  transform: translateY(1px);
  box-shadow: 0 1px 0 rgba(0,0,0,0.14), 0 3px 7px rgba(0,0,0,0.10), inset 0 1px 0 rgba(255,255,255,0.16) !important;
}
.context-btn-3d {
  min-width: max-content;
  border: 1px solid rgba(255,255,255,0.14) !important;
}
.controls-bar { border: 1px solid rgba(0,0,0,0.08); border-radius: 14px; padding: 10px; box-shadow: 0 3px 10px rgba(0,0,0,0.06), inset 0 1px 0 rgba(255,255,255,0.12); }
.controls-light { background: #ffffff; }
.controls-dark { background: rgba(30,30,35,0.55); backdrop-filter: blur(16px); border: 1px solid rgba(255,255,255,0.08); }
.search-wrap { height: 40px; border-radius: 0; padding: 0 12px; min-width: 300px; flex: 1; }
.search-light { background: #f4f6f8; border: 1px solid rgba(0,0,0,0.08); }
.search-dark { background: rgba(255,255,255,0.08); border: 1px solid rgba(255,255,255,0.10); }
.clean-input { border: none; outline: none; background: transparent; font-size: 12px; color: inherit; width: 100%; }

.kpi-bg-icon { position: absolute; right: -20px; bottom: -20px; opacity: 0.15; transform: rotate(-15deg); pointer-events: none; }
.kpi-bg-icon .v-icon { font-size: 100px; color: white; }
.kpi-card {
  border: 1px solid rgba(255,255,255,0.16);
  color: white;
  min-height: 110px;
  position: relative;
  overflow: hidden;
  box-shadow: 0 3px 0 rgba(0,0,0,0.12), 0 8px 16px rgba(0,0,0,0.12), inset 0 1px 0 rgba(255,255,255,0.16) !important;
  transform: translateY(0);
  transition: transform .14s ease, box-shadow .14s ease, filter .14s ease;
}
.kpi-card:hover {
  transform: translateY(-1px);
  filter: brightness(1.02);
  box-shadow: 0 4px 0 rgba(0,0,0,0.12), 0 10px 18px rgba(0,0,0,0.14), inset 0 1px 0 rgba(255,255,255,0.20) !important;
}
.kpi-card:active {
  transform: translateY(1px);
  box-shadow: 0 1px 0 rgba(0,0,0,0.14), 0 5px 10px rgba(0,0,0,0.12), inset 0 1px 0 rgba(255,255,255,0.14) !important;
}
.kpi-rect { border-radius: 16px !important; }
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
  grid-template-columns:
    50px
    60px
    140px
    minmax(140px, 0.7fr)
    1fr
    90px
    110px
    110px
    220px; /* Alargado para caber o novo botão de estoque */
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

.solid-chip {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  height: 24px;
  padding: 0 11px;
  border-radius: 999px;
  font-size: 10px;
  font-weight: 900;
  color: #fff;
  white-space: nowrap;
  box-shadow: 0 2px 0 rgba(0,0,0,0.13), 0 5px 9px rgba(0,0,0,0.10), inset 0 1px 0 rgba(255,255,255,0.20);
  text-shadow: 0 1px 1px rgba(0,0,0,0.25);
}
.chip-success { background: #2e7d32; }
.chip-warn { background: #f57f17; }
.chip-info { background: #1976d2; }
.chip-grey { background: #78909c; }
.chip-danger { background: #c62828; }

.actions-inline { display: flex; align-items: center; justify-content: center; gap: 8px; }
.action-btn {
  width: 34px !important;
  height: 34px !important;
  border-radius: 10px !important;
  color: #fff !important;
  box-shadow: 0 2px 0 rgba(0,0,0,0.14), 0 6px 10px rgba(0,0,0,0.12), inset 0 1px 0 rgba(255,255,255,0.20) !important;
}
.action-btn:hover { transform: translateY(-1px); filter: brightness(1.03); }
.action-btn:active { transform: translateY(1px); box-shadow: 0 1px 0 rgba(0,0,0,0.14), 0 4px 8px rgba(0,0,0,0.10), inset 0 1px 0 rgba(255,255,255,0.16) !important; }
.action-btn :deep(.v-icon) { color: #fff !important; }
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


.bulk-action-island-wrapper {
  position: fixed;
  left: 50%;
  bottom: 22px;
  transform: translateX(-50%);
  z-index: 2400;
  width: min(760px, calc(100vw - 24px));
  display: flex;
  justify-content: center;
  pointer-events: none;
}

.bulk-action-island {
  pointer-events: auto;
  width: auto;
  max-width: 100%;
  border-radius: 999px !important;
  padding: 9px 12px 9px 18px;
  display: flex;
  align-items: center;
  gap: 14px;
  box-shadow: 0 10px 30px rgba(0,0,0,0.25), inset 0 1px 0 rgba(255,255,255,0.10) !important;
}

.bulk-action-count {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 12px;
  font-weight: 900;
  white-space: nowrap;
}

.bulk-action-buttons {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-wrap: nowrap;
}

.bulk-action-btn {
  min-width: 104px;
  padding-left: 14px !important;
  padding-right: 14px !important;
}

.bulk-action-close {
  margin-left: 2px;
}

@media (max-width: 640px) {
  .bulk-action-island-wrapper {
    bottom: 14px;
    width: calc(100vw - 16px);
  }

  .bulk-action-island {
    border-radius: 18px !important;
    flex-direction: column;
    align-items: stretch;
    padding: 12px;
    gap: 10px;
  }

  .bulk-action-count,
  .bulk-action-buttons {
    justify-content: center;
  }

  .bulk-action-buttons {
    flex-wrap: wrap;
  }
}


/* FIX TOOLTIPS */
:global(.tooltip-custom) {
    background-color: black !important;
    color: white !important;
    font-weight: bold;
    font-size: 11px;
}

.sync-detail-card {
  border: 1px solid rgba(128,128,128,0.18);
  border-radius: 12px;
  padding: 12px 14px;
  min-height: 72px;
  display: flex;
  flex-direction: column;
  justify-content: center;
  gap: 4px;
  background: rgba(128,128,128,0.08);
  box-shadow: 0 2px 0 rgba(0,0,0,0.08), 0 6px 12px rgba(0,0,0,0.06), inset 0 1px 0 rgba(255,255,255,0.10);
}

.sync-detail-label {
  font-size: 10px;
  font-weight: 900;
  text-transform: uppercase;
  letter-spacing: 0.6px;
  opacity: 0.65;
}


.ai-activity-card {
  display: flex;
  align-items: center;
  gap: 14px;
  border-radius: 16px;
  padding: 14px 16px;
  border: 1px solid rgba(80,120,255,0.18);
  overflow: hidden;
  position: relative;
}
.ai-activity-light { background: linear-gradient(135deg, rgba(232,240,255,0.95), rgba(255,255,255,0.96)); }
.ai-activity-dark { background: linear-gradient(135deg, rgba(30,42,72,0.74), rgba(20,20,28,0.82)); }
.ai-orb-wrap {
  width: 52px;
  height: 52px;
  position: relative;
  flex: 0 0 52px;
  display: grid;
  place-items: center;
}
.ai-orb {
  width: 28px;
  height: 28px;
  border-radius: 50%;
  background: radial-gradient(circle at 35% 30%, #ffffff, #64b5f6 34%, #7c4dff 72%, #263238 100%);
  box-shadow: 0 0 18px rgba(100,181,246,0.45);
  animation: aiGlow 2.4s ease-in-out infinite;
}
.ai-ring {
  position: absolute;
  border-radius: 50%;
  border: 1px solid rgba(100,181,246,0.45);
  inset: 7px;
  animation: aiRing 2.2s ease-out infinite;
}
.ai-ring-two { animation-delay: .8s; }
.ai-live-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: #4caf50;
  box-shadow: 0 0 0 0 rgba(76,175,80,0.45);
  animation: aiLive 1.6s ease-in-out infinite;
}
.ai-phrase-viewport {
  height: 22px;
  overflow: hidden;
  font-size: 12px;
  font-weight: 700;
  opacity: .82;
}
.ai-phrase-track {
  animation: aiPhraseRoll 12s ease-in-out infinite;
}
.ai-phrase-track > div {
  height: 22px;
  display: flex;
  align-items: center;
}
@keyframes aiGlow {
  0%, 100% { transform: scale(1); filter: brightness(1); }
  50% { transform: scale(1.06); filter: brightness(1.12); }
}
@keyframes aiRing {
  0% { transform: scale(.72); opacity: .8; }
  100% { transform: scale(1.35); opacity: 0; }
}
@keyframes aiLive {
  0%, 100% { box-shadow: 0 0 0 0 rgba(76,175,80,0.42); }
  50% { box-shadow: 0 0 0 6px rgba(76,175,80,0); }
}
@keyframes aiPhraseRoll {
  0%, 18% { transform: translateY(0); }
  25%, 43% { transform: translateY(-22px); }
  50%, 68% { transform: translateY(-44px); }
  75%, 93% { transform: translateY(-66px); }
  100% { transform: translateY(0); }
}

</style>
