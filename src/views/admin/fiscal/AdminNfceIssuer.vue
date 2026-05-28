<template>
  <div
    class="nfce-layout font-sans fill-height d-flex flex-column relative overflow-hidden"
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
                    <span class="font-weight-bold">NFC-e (Consumidor)</span>
                </div>
                <div class="text-h6 font-weight-black tracking-tight leading-none mt-1">
                    Monitor de Vendas
                </div>

                <div class="d-flex align-center gap-3 mt-3 overflow-x-auto hide-scrollbar pb-1 w-100">
                    <v-btn
                        v-for="company in companies"
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
            </div>

            <div class="d-flex align-center gap-3">
                 <v-btn
                     color="primary"
                     variant="flat"
                     class="btn-3d px-6 font-weight-black text-uppercase letter-spacing-1 shadow-indigo-soft rounded"
                     height="40"
                     prepend-icon="mdi-receipt-text-plus"
                     @click="openIssueModal"
                 >
                     Emitir NFC-e
                 </v-btn>
            </div>
        </div>

        <div class="px-6 pt-4 pb-0 flex-shrink-0">
            <v-row>
                <v-col cols="12" sm="6" md="3">
                    <v-card class="kpi-card kpi-rect bg-gradient-info hover-elevate py-3 px-4" v-ripple elevation="2">
                        <div class="kpi-bg-icon"><v-icon>mdi-cart-outline</v-icon></div>
                        <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                            <div class="d-flex align-center" style="gap: 8px;">
                                <v-icon size="18" class="opacity-80 text-white">mdi-receipt-text-check</v-icon>
                                <span class="kpi-label text-white">Vendas Hoje</span>
                            </div>
                            <div class="kpi-number-group my-1 text-white">
                                <span class="kpi-value">{{ kpis.todayCount }}</span>
                                <span class="text-caption ml-1 opacity-70">emitidas</span>
                            </div>
                            <div class="kpi-footer mt-1 text-white">NFC-e Autorizadas</div>
                        </div>
                    </v-card>
                </v-col>

                <v-col cols="12" sm="6" md="3">
                    <v-card class="kpi-card kpi-rect bg-gradient-green hover-elevate py-3 px-4" v-ripple elevation="2">
                        <div class="kpi-bg-icon"><v-icon>mdi-cash-register</v-icon></div>
                        <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                            <div class="d-flex align-center" style="gap: 8px;">
                                <v-icon size="18" class="opacity-80 text-white">mdi-cash-multiple</v-icon>
                                <span class="kpi-label text-white">Faturamento (Dia)</span>
                            </div>
                            <div class="kpi-number-group my-1 text-white">
                                <span class="text-body-2 font-weight-medium mr-1 opacity-70">R$</span>
                                <span class="kpi-value text-h5">{{ formatCurrencyValue(kpis.todayValue) }}</span>
                            </div>
                            <div class="kpi-footer mt-1 text-white">Total Recebido</div>
                        </div>
                    </v-card>
                </v-col>

                <v-col cols="12" sm="6" md="3">
                    <v-card class="kpi-card kpi-rect bg-gradient-purple hover-elevate py-3 px-4" v-ripple elevation="2">
                        <div class="kpi-bg-icon"><v-icon>mdi-calendar-month</v-icon></div>
                        <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                            <div class="d-flex align-center" style="gap: 8px;">
                                <v-icon size="18" class="opacity-80 text-white">mdi-chart-line</v-icon>
                                <span class="kpi-label text-white">Acumulado Mês</span>
                            </div>
                            <div class="kpi-number-group my-1 text-white">
                                <span class="text-body-2 font-weight-medium mr-1 opacity-70">R$</span>
                                <span class="kpi-value text-h5">{{ formatCurrencyValue(kpis.monthValue) }}</span>
                            </div>
                            <div class="kpi-footer mt-1 text-white">{{ kpis.monthCount }} notas</div>
                        </div>
                    </v-card>
                </v-col>

                <v-col cols="12" sm="6" md="3">
                    <v-card class="kpi-card kpi-rect bg-gradient-deep-orange hover-elevate py-3 px-4 cursor-pointer" v-ripple elevation="2" @click="openIssueModal">
                        <div class="kpi-bg-icon"><v-icon>mdi-plus-box</v-icon></div>
                        <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height align-start">
                            <div class="d-flex align-center" style="gap: 8px;">
                                <v-icon size="18" class="opacity-80 text-white">mdi-flash</v-icon>
                                <span class="kpi-label text-white">Ação Rápida</span>
                            </div>
                            <v-btn variant="flat" color="white" class="text-deep-orange-darken-4 font-weight-bold btn-3d rounded mt-2" block>
                                <v-icon start>mdi-plus</v-icon> Nova Venda
                            </v-btn>
                        </div>
                    </v-card>
                </v-col>
            </v-row>
        </div>

        <div class="px-6 pt-4 pb-2 flex-shrink-0">
            <div class="controls-bar d-flex align-center justify-space-between flex-wrap gap-2" :class="themeStore.currentMode === 'light' ? 'controls-light rounded-lg' : 'controls-dark border-white-10 rounded-lg'">
                <div class="d-flex align-center flex-wrap" style="gap: 10px; flex-grow: 1;">
                    <div class="search-wrap d-flex align-center rounded" :class="themeStore.currentMode === 'light' ? 'search-light' : 'search-dark'" style="max-width: 300px;">
                        <v-icon :color="themeStore.currentMode === 'light' ? 'grey-darken-1' : 'white-70'">mdi-magnify</v-icon>
                        <input v-model="search" type="text" placeholder="Buscar por número, valor..." class="clean-input flex-grow-1" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-3' : 'text-white'"/>
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
                                <v-list-item @click="openBulkDownloadModal" class="rounded-sm">
                                    <template v-slot:prepend><v-icon size="18" color="secondary">mdi-folder-zip</v-icon></template>
                                    <v-list-item-title class="font-weight-bold" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">Baixar XMLs (Lote)</v-list-item-title>
                                </v-list-item>
                            </v-list>
                        </v-card>
                    </v-menu>
                </div>
            </div>
        </div>

        <div class="flex-grow-1 px-6 pb-2 overflow-hidden d-flex flex-column">
            <v-card class="flex-grow-1 d-flex flex-column rounded-lg border-thin overflow-hidden" :class="themeStore.currentMode === 'light' ? 'bg-white shadow-sm' : 'glass-card border-white-05'" :elevation="0">
                <div class="grid-scroll flex-grow-1 overflow-y-auto custom-scroll">
                    <div class="grid-header sticky-head" :class="[themeStore.currentMode === 'light' ? 'grid-surface-light border-b border-grey-lighten-2' : 'grid-surface-dark border-bottom-white-05', 'grid-nfce-layout']">
                        <div class="cell center header-text">Status</div>
                        <div class="cell center header-text">Número</div>
                        <div class="cell center header-text">Emissão</div>
                        <div class="cell header-text">Destinatário (CPF/Nome)</div>
                        <div class="cell right header-text">Valor Total</div>
                        <div class="cell center header-text">Ações</div>
                    </div>

                    <div v-if="loading" class="d-flex flex-column justify-center align-center h-100 py-10">
                        <v-progress-circular indeterminate color="primary" size="32" width="3"></v-progress-circular>
                        <p class="text-caption mt-2 font-weight-bold opacity-60">Carregando histórico...</p>
                    </div>

                    <div v-else-if="filteredNotes.length === 0" class="d-flex flex-column justify-center align-center h-100 opacity-60 gap-2 py-10">
                        <v-icon size="48" :color="themeStore.currentMode === 'light' ? 'grey-lighten-1' : 'grey-darken-1'">mdi-receipt-text-outline</v-icon>
                        <span class="text-body-2 font-weight-medium opacity-70">Nenhuma NFC-e encontrada.</span>
                    </div>

                    <template v-else>
                        <div v-for="(note, index) in filteredNotes" :key="note.id" class="grid-row zebra-row" :class="[themeStore.currentMode === 'light' ? 'grid-row-light' : 'grid-row-dark', zebraClass(index), 'grid-nfce-layout']">
                            <div class="cell center">
                                <span class="solid-chip chip-3d" :class="getStatusClass(note.status_sefaz)">{{ note.status_sefaz }}</span>
                            </div>
                            <div class="cell center"><span class="list-text-11 font-mono font-weight-bold">{{ note.numero }}</span></div>
                            <div class="cell center"><span class="list-text-11 font-mono opacity-80">{{ formatDate(note.created_at) }}</span></div>
                            <div class="cell">
                                <span class="list-text-11 font-weight-bold text-truncate">{{ note.destinatario || 'Consumidor Final' }}</span>
                            </div>
                            <div class="cell right"><span class="list-text-11 font-mono font-weight-black text-success">{{ formatCurrency(note.valor_total) }}</span></div>
                            <div class="cell center">
                                <div class="actions-inline">
                                    <v-tooltip text="Imprimir" location="top" content-class="bg-grey-darken-4 text-white font-weight-bold">
                                        <template v-slot:activator="{ props }">
                                            <v-btn v-bind="props" icon size="small" class="action-btn action-print btn-3d rounded-sm" @click="printNote(note)">
                                                <v-icon size="16">mdi-printer</v-icon>
                                            </v-btn>
                                        </template>
                                    </v-tooltip>

                                    <v-tooltip text="Baixar XML" location="top" content-class="bg-grey-darken-4 text-white font-weight-bold">
                                        <template v-slot:activator="{ props }">
                                            <v-btn v-bind="props" icon size="small" class="action-btn bg-blue-grey text-white btn-3d rounded-sm" @click="downloadIndividualXML(note)">
                                                <v-icon size="16">mdi-xml</v-icon>
                                            </v-btn>
                                        </template>
                                    </v-tooltip>

                                    <v-menu location="bottom end" :content-class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-grey-darken-4 text-white'">
                                        <template v-slot:activator="{ props }">
                                            <v-tooltip text="Compartilhar" location="top" content-class="bg-grey-darken-4 text-white font-weight-bold">
                                                <template v-slot:activator="{ props: tooltipProps }">
                                                    <v-btn
                                                        v-bind="{ ...props, ...tooltipProps }"
                                                        icon
                                                        size="small"
                                                        class="action-btn bg-teal text-white btn-3d rounded-sm"
                                                    >
                                                        <v-icon size="16">mdi-share-variant</v-icon>
                                                    </v-btn>
                                                </template>
                                            </v-tooltip>
                                        </template>
                                        <v-list density="compact" nav class="border-thin shadow-xl rounded-lg" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-grey-darken-3'">
                                            <v-list-item title="WhatsApp" prepend-icon="mdi-whatsapp" @click="shareWhatsapp(note)" class="text-caption font-weight-bold"></v-list-item>
                                            <v-list-item title="E-mail" prepend-icon="mdi-email-outline" @click="shareEmail(note)" class="text-caption font-weight-bold"></v-list-item>
                                        </v-list>
                                    </v-menu>

                                    <v-tooltip v-if="note.status_sefaz === 'autorizado' || note.status_sefaz === 'AUTORIZADA'" text="Cancelar" location="top" content-class="bg-grey-darken-4 text-white font-weight-bold">
                                        <template v-slot:activator="{ props }">
                                            <v-btn v-bind="props" icon size="small" class="action-btn action-cancel btn-3d rounded-sm" @click="cancelNote(note)">
                                                <v-icon size="16">mdi-cancel</v-icon>
                                            </v-btn>
                                        </template>
                                    </v-tooltip>

                                    <v-tooltip v-if="note.status_sefaz === 'REJEITADA'" text="Ver Erro" location="top" content-class="bg-grey-darken-4 text-white font-weight-bold">
                                        <template v-slot:activator="{ props }">
                                            <v-btn v-bind="props" icon size="small" class="action-btn action-cancel bg-red btn-3d rounded-sm" @click="showErrorDetails(note)">
                                                <v-icon size="16">mdi-alert-circle</v-icon>
                                            </v-btn>
                                        </template>
                                    </v-tooltip>
                                </div>
                            </div>
                        </div>
                    </template>
                </div>
            </v-card>
        </div>
    </div>

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
                        <label class="input-label" :class="themeStore.currentMode === 'light' ? '' : 'text-white-70'">Data Inicial</label>
                        <v-text-field type="date" v-model="bulkDownloadModal.startDate" variant="outlined" density="compact" hide-details class="ui-field font-weight-bold"></v-text-field>
                    </v-col>
                    <v-col cols="12" sm="6">
                        <label class="input-label" :class="themeStore.currentMode === 'light' ? '' : 'text-white-70'">Data Final</label>
                        <v-text-field type="date" v-model="bulkDownloadModal.endDate" variant="outlined" density="compact" hide-details class="ui-field font-weight-bold"></v-text-field>
                    </v-col>
                    <v-col cols="12" class="mt-2">
                        <label class="input-label" :class="themeStore.currentMode === 'light' ? '' : 'text-white-70'">Status da NFe</label>
                        <v-select
                            v-model="bulkDownloadModal.status"
                            :items="['TODOS', 'AUTORIZADA', 'REJEITADA', 'CANCELADA']"
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

    <v-dialog v-model="issueModal.show" max-width="1200" persistent scrim="black opacity-80" scrollable transition="dialog-bottom-transition">
        <v-card class="rounded-lg d-flex flex-column border-thin" height="800" :class="themeStore.currentMode === 'light' ? 'bg-white text-grey-darken-3 shadow-xl' : 'bg-grey-darken-4 text-white border-white-10'">
             <div class="flex-grow-1 d-flex overflow-hidden" style="max-height: calc(100% - 70px);">
                <div class="border-r d-flex flex-column" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-grey-darken-3 border-white-10'" style="width: 320px; flex-shrink: 0;">
                    <div class="pa-6 border-b" :class="themeStore.currentMode === 'light' ? 'border-grey-lighten-2' : 'border-white-10'">
                        <div class="d-flex align-center gap-3 mb-4">
                            <div class="icon-box rounded-lg pa-3 border shadow-sm" :class="themeStore.currentMode === 'light' ? 'bg-white border-grey-lighten-2' : 'bg-grey-darken-4 border-white-10'">
                                <v-icon color="deep-orange" size="24">mdi-cart-plus</v-icon>
                            </div>
                            <div>
                                <div class="text-caption font-weight-bold text-uppercase opacity-70">NOVA VENDA</div>
                                <div class="text-body-2 font-weight-black">Emissor NFC-e</div>
                            </div>
                        </div>

                        <div class="pa-3 rounded border mb-4" :class="themeStore.currentMode === 'light' ? 'bg-white border-grey-lighten-2' : 'bg-grey-darken-4 border-white-10'">
                            <div class="text-caption font-weight-bold text-uppercase opacity-60 mb-1">Empresa Emissora</div>
                            <div class="font-weight-bold text-body-2">{{ activeCompany?.name || 'Selecione...' }}</div>
                            <div class="font-mono text-caption opacity-70">{{ activeCompany?.cnpj }}</div>
                        </div>

                        <div class="d-flex flex-column gap-2">
                            <div class="d-flex justify-space-between align-end">
                                <span class="text-caption font-weight-bold text-uppercase opacity-60">Total Itens</span>
                                <span class="font-weight-bold">{{ form.itens.length }}</span>
                            </div>
                            <div class="d-flex justify-space-between align-end">
                                <span class="text-caption font-weight-bold text-uppercase opacity-60">Total Mercadorias</span>
                                <span class="font-weight-bold">{{ formatCurrency(totalProducts) }}</span>
                            </div>
                            <v-divider :class="themeStore.currentMode === 'light' ? 'border-grey-lighten-2' : 'border-white-10'"></v-divider>
                            <div class="d-flex justify-space-between align-end mt-2">
                                <span class="text-subtitle-2 font-weight-black text-uppercase text-deep-orange">Total a Pagar</span>
                                <span class="text-h5 font-weight-black text-deep-orange">{{ formatCurrency(totalValue) }}</span>
                            </div>
                        </div>
                    </div>

                    <div class="flex-grow-1 overflow-y-auto pa-4 custom-scroll">
                        <div class="text-caption font-weight-bold text-uppercase opacity-60 mb-2">Itens no Carrinho</div>
                        <div v-for="(item, idx) in form.itens" :key="idx" class="d-flex justify-space-between align-center mb-2 pa-2 border rounded" :class="themeStore.currentMode === 'light' ? 'bg-white border-grey-lighten-2' : 'bg-grey-darken-4 border-white-10'">
                            <div class="d-flex flex-column overflow-hidden mr-2">
                                <span class="text-caption font-weight-bold text-truncate">{{ item.descricao }}</span>
                                <span class="text-[10px] opacity-70">{{ item.quantidade }} x {{ formatCurrency(item.valor_unitario) }}</span>
                            </div>
                            <span class="text-caption font-weight-black">{{ formatCurrency(item.quantidade * item.valor_unitario) }}</span>
                        </div>
                    </div>
                </div>

                <div class="flex-grow-1 d-flex flex-column overflow-hidden" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-grey-darken-4'">
                    <div class="px-8 py-5 border-b d-flex justify-space-between align-center flex-shrink-0 z-10" :class="themeStore.currentMode === 'light' ? 'bg-white border-grey-lighten-2' : 'bg-grey-darken-4 border-white-10'">
                        <div>
                            <h3 class="text-h6 font-weight-bold">Dados da Venda</h3>
                            <p class="text-caption opacity-70">Adicione produtos e forma de pagamento.</p>
                        </div>
                        <v-btn icon="mdi-close" class="btn-3d" variant="text" @click="issueModal.show = false"></v-btn>
                    </div>

                    <div class="px-8 py-6 flex-grow-1 overflow-y-auto custom-scroll">
                        <v-form ref="formRef" @submit.prevent>

                            <div class="mb-6">
                                <div class="d-flex align-center gap-2 mb-3">
                                    <v-icon :color="themeStore.currentMode === 'light' ? 'grey-darken-2' : 'grey-lighten-2'" size="18">mdi-account</v-icon>
                                    <span class="text-subtitle-2 font-weight-bold text-uppercase opacity-70">Consumidor (Opcional)</span>
                                </div>
                                <v-row dense>
                                    <v-col cols="12" md="4">
                                        <v-text-field v-model="form.cpf" label="CPF/CNPJ" variant="outlined" density="compact" hide-details v-maska="'###.###.###-##'" class="ui-field font-weight-bold"></v-text-field>
                                    </v-col>
                                    <v-col cols="12" md="8">
                                        <v-text-field v-model="form.nome" label="Nome do Cliente" variant="outlined" density="compact" hide-details class="ui-field font-weight-bold"></v-text-field>
                                    </v-col>
                                </v-row>
                            </div>

                            <v-divider class="mb-6 border-dashed" :class="themeStore.currentMode === 'light' ? 'border-grey-lighten-2' : 'border-white-10'"></v-divider>

                            <div class="mb-6">
                                <div class="d-flex align-center justify-space-between mb-3">
                                    <div class="d-flex align-center gap-2">
                                        <v-icon :color="themeStore.currentMode === 'light' ? 'grey-darken-2' : 'grey-lighten-2'" size="18">mdi-package-variant</v-icon>
                                        <span class="text-subtitle-2 font-weight-bold text-uppercase opacity-70">Produtos</span>
                                    </div>
                                    <v-btn size="small" variant="tonal" color="primary" prepend-icon="mdi-plus" class="btn-3d font-weight-bold" @click="addItem">Adicionar Item</v-btn>
                                </div>

                                <div class="rounded-lg border overflow-hidden" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-grey-darken-3 border-white-10'">
                                    <div v-for="(item, idx) in form.itens" :key="idx" class="pa-3 border-b transition-colors relative group" :class="themeStore.currentMode === 'light' ? 'hover:bg-white border-grey-lighten-2' : 'hover:bg-grey-darken-4 border-white-10'">
                                        <v-row dense align="center">
                                            <v-col cols="12" md="5">
                                                <v-text-field v-model="item.descricao" label="Descrição" variant="outlined" density="compact" hide-details class="ui-field font-weight-bold"></v-text-field>
                                            </v-col>
                                            <v-col cols="6" md="2">
                                                <v-text-field v-model="item.ncm" label="NCM" variant="outlined" density="compact" hide-details class="ui-field font-weight-bold"></v-text-field>
                                            </v-col>
                                            <v-col cols="6" md="2">
                                                <v-text-field v-model="item.cfop" label="CFOP" variant="outlined" density="compact" hide-details class="ui-field font-weight-bold"></v-text-field>
                                            </v-col>
                                            <v-col cols="4" md="1">
                                                <v-text-field v-model.number="item.quantidade" label="Qtd" type="number" variant="outlined" density="compact" hide-details class="ui-field font-weight-bold text-center"></v-text-field>
                                            </v-col>
                                            <v-col cols="4" md="2">
                                                <v-text-field v-model.number="item.valor_unitario" label="Unitário" type="number" prefix="R$" variant="outlined" density="compact" hide-details class="ui-field font-weight-bold"></v-text-field>
                                            </v-col>
                                        </v-row>
                                        <v-btn icon="mdi-delete" size="x-small" variant="text" color="error" class="absolute top-2 right-2 opacity-0 group-hover:opacity-100 transition-opacity" @click="removeItem(idx)" v-if="form.itens.length > 1"></v-btn>
                                    </div>
                                </div>
                            </div>

                            <v-divider class="mb-6 border-dashed" :class="themeStore.currentMode === 'light' ? 'border-grey-lighten-2' : 'border-white-10'"></v-divider>

                            <div class="mb-2">
                                <div class="d-flex align-center gap-2 mb-3">
                                    <v-icon :color="themeStore.currentMode === 'light' ? 'grey-darken-2' : 'grey-lighten-2'" size="18">mdi-credit-card-outline</v-icon>
                                    <span class="text-subtitle-2 font-weight-bold text-uppercase opacity-70">Pagamento</span>
                                </div>
                                <v-card variant="outlined" class="pa-4 border-dashed rounded-lg" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-grey-darken-3 border-white-10'">
                                    <v-row dense>
                                        <v-col cols="12" md="6">
                                            <v-select
                                                v-model="form.pagamento.forma"
                                                :items="paymentMethods"
                                                item-title="label"
                                                item-value="code"
                                                label="Forma de Pagamento"
                                                variant="outlined"
                                                density="compact"
                                                hide-details
                                                class="ui-field font-weight-bold"
                                            ></v-select>
                                        </v-col>
                                        <v-col cols="12" md="6">
                                            <v-text-field
                                                v-model.number="form.pagamento.valor"
                                                label="Valor Pago"
                                                type="number"
                                                prefix="R$"
                                                variant="outlined"
                                                density="compact"
                                                hide-details
                                                class="ui-field font-weight-black text-success"
                                            ></v-text-field>
                                        </v-col>
                                    </v-row>
                                </v-card>
                            </div>

                        </v-form>
                    </div>
                </div>
            </div>

            <div class="px-8 py-4 border-t d-flex justify-between gap-3 flex-shrink-0 align-center" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-grey-darken-3 border-white-10'">

                <div class="d-flex align-center gap-2">
                    <span class="text-caption text-grey text-uppercase font-weight-bold">Ambiente:</span>
                    <v-btn-toggle v-model="selectedEnvironment" mandatory density="compact" color="primary" variant="outlined" divided class="rounded">
                        <v-btn value="homologacao" class="text-caption font-weight-bold px-3" height="28">Homologação</v-btn>
                        <v-btn value="producao" class="text-caption font-weight-bold px-3" height="28">Produção</v-btn>
                    </v-btn-toggle>
                </div>

                <div class="d-flex gap-3">
                    <v-btn variant="outlined" class="btn-3d font-weight-bold rounded" height="45" @click="issueModal.show = false">Cancelar</v-btn>
                    <v-btn color="deep-orange" variant="flat" class="btn-3d px-8 font-weight-black text-body-1 rounded" height="45" :loading="issuing" @click="emitirNFCe">
                        <v-icon start>mdi-send-check</v-icon> EMITIR CUPOM
                    </v-btn>
                </div>
            </div>
        </v-card>
    </v-dialog>

    <v-dialog v-model="errorDialog.show" max-width="600">
        <v-card class="rounded-lg pa-6 border-thin shadow-xl" :class="themeStore.currentMode === 'light' ? 'bg-white text-grey-darken-3' : 'bg-grey-darken-4 text-white border-white-10'">
            <div class="d-flex align-center gap-3 mb-4 text-error">
                <v-icon size="40">mdi-alert-octagon</v-icon>
                <h3 class="text-h6 font-weight-bold">Emissão Rejeitada</h3>
            </div>

            <v-alert type="error" variant="tonal" class="mb-4 text-caption font-weight-bold border-error">
                {{ errorDialog.message }}
            </v-alert>

            <div class="pa-4 rounded mb-4 overflow-auto custom-scroll" style="max-height: 300px;" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-4' : 'bg-black-20'">
                <pre class="text-caption font-mono" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-3' : 'text-white-70'">{{ JSON.stringify(errorDialog.details, null, 2) }}</pre>
            </div>

            <v-btn block color="primary" variant="flat" class="btn-3d font-weight-bold rounded" @click="errorDialog.show = false">
                Entendi, vou corrigir
            </v-btn>
        </v-card>
    </v-dialog>

  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted, watch } from 'vue';
import { useThemeStore } from '@/stores/theme';
import { useAppStore } from '@/stores/app';
import { useCompanyStore } from '@/stores/company';
import { sefazService } from '@/api/sefazApi';
import { supabase } from '@/api/supabase';
import { format, parseISO, startOfMonth, endOfMonth, isWithinInterval } from 'date-fns';
import { vMaska } from "maska/vue";
import JSZip from 'jszip';

// --- STATE ---
const themeStore = useThemeStore();
const appStore = useAppStore();
const companyStore = useCompanyStore();

const companies = ref<any[]>([]);
const activeCompany = ref<any>(null);
const loading = ref(false);
const issuing = ref(false);
const history = ref<any[]>([]);
const search = ref('');
const selectedEnvironment = ref('homologacao');

// --- DATAS E ESTADO DOWNLOAD EM MASSA (ZIP) ---
const bulkDownloadModal = reactive({
    show: false,
    startDate: format(startOfMonth(new Date()), 'yyyy-MM-dd'),
    endDate: format(endOfMonth(new Date()), 'yyyy-MM-dd'),
    status: 'AUTORIZADA',
    downloading: false,
    progress: { show: false, current: 0, total: 0 }
});

// --- KPIs ---
const kpis = reactive({
    todayCount: 0,
    todayValue: 0,
    monthCount: 0,
    monthValue: 0
});

// --- DIALOGS ---
const issueModal = reactive({ show: false });
const errorDialog = reactive({ show: false, message: '', details: null as any });

const paymentMethods = [
  { label: 'Dinheiro', code: '01' },
  { label: 'Cartão Crédito', code: '03' },
  { label: 'Cartão Débito', code: '04' },
  { label: 'PIX', code: '17' }
];

const form = reactive({
  cpf: '',
  nome: '',
  itens: [{ descricao: 'PRODUTO DIVERSO', ncm: '61091000', cfop: '5102', unidade: 'UN', quantidade: 1, valor_unitario: 0 }],
  pagamento: { forma: '01', valor: 0 }
});

// --- COMPUTED ---
const totalProducts = computed(() => form.itens.reduce((acc, item) => acc + (item.quantidade * item.valor_unitario), 0));
const totalValue = computed(() => totalProducts.value);

const environmentColor = computed(() => activeCompany.value?.nfe_environment === 'producao' ? 'red' : 'warning');

const filteredNotes = computed(() => {
    let list = history.value;
    if (search.value) {
        const q = search.value.toLowerCase();
        list = list.filter(n =>
            String(n.numero).includes(q) ||
            String(n.valor_total).includes(q) ||
            (n.destinatario && n.destinatario.toLowerCase().includes(q))
        );
    }
    return list;
});

// --- WATCHERS ---
watch(totalValue, (val) => {
    form.pagamento.valor = val;
});

watch(activeCompany, (newVal) => {
    if(newVal) {
        selectedEnvironment.value = newVal.nfe_environment || 'homologacao';
    }
});

// --- ACTIONS ---
const switchCompany = (company: any) => {
    activeCompany.value = company;

    companyStore.setContext(company.id);

    if (companyStore.setActiveCompany) {
        companyStore.setActiveCompany(company);
    } else {
        companyStore.activeCompany = company;
    }

    fetchHistory();
};

const loadCompanies = async () => {
    loading.value = true;

    if (companyStore.isDemoMode) {
        companies.value = [
            { id: 'fake-comp-1', name: 'INDÚSTRIA FICTÍCIA S.A.', trade_name: 'INDÚSTRIA FICTÍCIA', cnpj: '00.000.000/0001-00', nfe_environment: 'producao', nfe_series: 1, nfe_next_number: 15420, status: 'active', ie: '123456789' },
            { id: 'fake-comp-2', name: 'VAREJO FICTÍCIO LTDA.', trade_name: 'VAREJO FICTÍCIO', cnpj: '11.111.111/0001-11', nfe_environment: 'producao', nfe_series: 2, nfe_next_number: 5432, status: 'active', ie: '987654321' }
        ];

        if (companies.value.length > 0 && !activeCompany.value) {
            if (companyStore.activeCompany && companies.value.some(c => c.id === companyStore.activeCompany.id)) {
                activeCompany.value = companies.value.find(c => c.id === companyStore.activeCompany.id);
            } else {
                activeCompany.value = companies.value[0];
                if(companyStore.setActiveCompany) companyStore.setActiveCompany(activeCompany.value);
                else companyStore.activeCompany = activeCompany.value;
            }
            fetchHistory();
        }
        loading.value = false;
        return;
    }

    try {
        const { data: dbCompanies } = await supabase.from('companies').select('*');

        let nuvemCompanies = [];
        try {
            const nuvemResponse = await sefazService.listarEmpresas();
            nuvemCompanies = nuvemResponse.data || (Array.isArray(nuvemResponse) ? nuvemResponse : []);
        } catch (e) {
            console.warn("Nuvem Fiscal não retornou empresas. Usando base local.");
        }

        companies.value = (dbCompanies || []).map((dbc: any) => {
            const nc = nuvemCompanies.find((n: any) => n.cnpj?.replace(/\D/g, '') === dbc.cnpj?.replace(/\D/g, '')) || {};
            const crtRaw = dbc.crt;
            const crtFinal = (crtRaw !== undefined && crtRaw !== null) ? String(crtRaw) : '1';

            return {
                ...nc,
                ...dbc,
                id: dbc.id,
                name: dbc.trade_name || dbc.name || nc.nome || 'Empresa Sem Nome',
                nfe_environment: dbc.nfe_environment || 'homologacao',
                nfce_series: dbc.nfce_series || 1,
                nfce_next_number: parseInt(dbc.nfce_next_number) || 0,
                crt: crtFinal,
                ie: dbc.ie || nc.inscricao_estadual
            };
        });

        if (companies.value.length > 0 && !activeCompany.value) {
            if (companyStore.context && companyStore.context !== 'global') {
                const found = companies.value.find(c => c.id === companyStore.context);
                activeCompany.value = found || companies.value[0];
            } else if (companyStore.activeCompany && companies.value.some(c => c.id === companyStore.activeCompany.id)) {
                activeCompany.value = companies.value.find(c => c.id === companyStore.activeCompany.id);
            } else {
                activeCompany.value = companies.value[0];
                companyStore.setContext(activeCompany.value.id);
            }
            fetchHistory();
        }
    } catch (e: any) {
        console.error('Erro ao carregar empresas', e.message);
    } finally {
        loading.value = false;
    }
};

const fetchHistory = async () => {
    if (!activeCompany.value) return;
    loading.value = true;
    try {
        const cnpjFiltro = String(activeCompany.value.cnpj).replace(/\D/g, '');

        const { data, error } = await supabase.from('nfce_outbound')
            .select('*')
            .eq('emitente_cnpj', cnpjFiltro)
            .order('created_at', { ascending: false })
            .limit(50);

        if(error) {
            console.error("Supabase Error:", error);
            history.value = [];
        } else {
            const rawData = data || [];
            history.value = rawData.map((n:any) => ({
                id: n.id,
                numero: n.numero,
                created_at: n.created_at,
                valor_total: n.valor_total,
                status_sefaz: n.status || 'autorizado',
                destinatario: n.destinatario_nome,
                pdf_url: n.pdf_link,
                chave: n.chave,
                id_nuvem: n.retorno_sefaz?.id_nuvem,
                retorno_sefaz: n.retorno_sefaz
            }));
        }

        calcKpis();
    } catch (e: any) {
        console.error("Fetch Exception:", e);
    }
    finally {
        loading.value = false;
    }
};

const calcKpis = () => {
    const now = new Date();
    const todayStr = format(now, 'yyyy-MM-dd');
    const startMonth = startOfMonth(now);
    const endMonth = endOfMonth(now);

    let todayC = 0, todayV = 0, monthC = 0, monthV = 0;

    history.value.forEach(n => {
        const d = parseISO(n.created_at);
        const dStr = format(d, 'yyyy-MM-dd');
        const val = Number(n.valor_total) || 0;

        if (dStr === todayStr) { todayC++; todayV += val; }
        if (isWithinInterval(d, { start: startMonth, end: endMonth })) { monthC++; monthV += val; }
    });

    kpis.todayCount = todayC;
    kpis.todayValue = todayV;
    kpis.monthCount = monthC;
    kpis.monthValue = monthV;
};

const openIssueModal = () => {
    if (!activeCompany.value) return appStore.showSnackbar('Selecione uma empresa.', 'error');
    form.itens = [{ descricao: 'PRODUTO DIVERSO', ncm: '61091000', cfop: '5102', unidade: 'UN', quantidade: 1, valor_unitario: 0 }];
    form.cpf = '';
    form.nome = '';
    form.pagamento.valor = 0;

    selectedEnvironment.value = activeCompany.value.nfe_environment || 'homologacao';
    issueModal.show = true;
};

const addItem = () => form.itens.push({ descricao: '', ncm: '00000000', cfop: '5102', unidade: 'UN', quantidade: 1, valor_unitario: 0 });
const removeItem = (idx: number) => form.itens.splice(idx, 1);

const emitirNFCe = async () => {
  if (!activeCompany.value) return;
  issuing.value = true;

  try {
    const env = selectedEnvironment.value;

    const payload = {
      ambiente: env,
      serie: activeCompany.value.nfce_series || 1,
      numero: (activeCompany.value.nfce_next_number || 1),
      crt: activeCompany.value.crt || 1,
      destinatario: { cnpj_cpf: form.cpf, nome: form.nome },
      itens: form.itens.map((i, idx) => ({ ...i, codigo_produto: `ITEM${idx+1}` })),
      pagamentos: [{ forma_pagamento: form.pagamento.forma, valor: totalValue.value }],
      valor_total: totalValue.value,
      referencia: `PDV-${Date.now()}`
    };

    const result = await sefazService.emitirNFCe(payload, activeCompany.value.cnpj, activeCompany.value.ie);

    if (result.status_sefaz !== 'autorizado' && result.status !== 'success') {
        const errorMsg = result.motivo || result.message || 'Erro no processamento';
        const details = result.details || result.erros || result;

        errorDialog.message = errorMsg;
        errorDialog.details = details;
        errorDialog.show = true;

        try {
            await supabase.from('nfce_outbound').insert({
                emitente_cnpj: activeCompany.value.cnpj,
                numero: result.numero || payload.numero,
                valor_total: totalValue.value,
                status: 'REJEITADA',
                ambiente: env,
                destinatario_nome: form.nome || 'Consumidor Final',
                retorno_sefaz: result
            });
            fetchHistory();
        } catch {}

        issuing.value = false;
        return;
    }

    appStore.showSnackbar(`NFC-e ${result.numero} autorizada!`, 'success');

    try {
        await supabase.from('nfce_outbound').insert({
            emitente_cnpj: activeCompany.value.cnpj,
            numero: result.numero,
            valor_total: totalValue.value,
            status: 'AUTORIZADA',
            chave: result.chave,
            pdf_link: result.pdf_url,
            ambiente: env,
            destinatario_nome: form.nome || 'Consumidor Final',
            retorno_sefaz: result
        });
    } catch (dbErr: any) {
        console.warn("Erro ao salvar no banco:", dbErr.message);
    }

    await supabase.from('companies').update({ nfce_next_number: Number(result.numero) + 1 }).eq('id', activeCompany.value.id);
    activeCompany.value.nfce_next_number = Number(result.numero) + 1;

    fetchHistory();
    issueModal.show = false;

    const url = sefazService.getProxyNfceDownloadUrl('pdf', result.id_nuvem);
    window.open(url, '_blank');

  } catch (e: any) {
    console.error("Erro Emissão Catch:", e);
    const msg = e.response?.data?.message || e.message || 'Erro desconhecido';
    const details = e.response?.data?.details || e.response?.data || {};

    errorDialog.message = msg;
    errorDialog.details = details;
    errorDialog.show = true;
  } finally {
    issuing.value = false;
  }
};

const showErrorDetails = (note: any) => {
    errorDialog.message = "Detalhes da Rejeição";
    errorDialog.details = note.retorno_sefaz || { info: "Sem detalhes gravados" };
    errorDialog.show = true;
};

const printNote = (note: any) => {
    const id = note.id_nuvem || note.retorno_sefaz?.id_nuvem;
    if (id) {
        const url = sefazService.getProxyNfceDownloadUrl('pdf', id);
        window.open(url, '_blank');
    } else if (note.pdf_url) {
        window.open(note.pdf_url, '_blank');
    }
};

const downloadIndividualXML = async (note: any) => {
    const id = note.id_nuvem || note.retorno_sefaz?.id_nuvem;
    if (!id) return appStore.showSnackbar('ID da nota não encontrado na Nuvem Fiscal.', 'error');

    try {
        appStore.showSnackbar('Baixando XML...', 'info');
        const url = sefazService.getProxyNfceDownloadUrl('xml', id);

        const response = await fetch(url);
        if (!response.ok) throw new Error('Falha de conexão ou arquivo não encontrado.');

        const blob = await response.blob();
        const blobUrl = window.URL.createObjectURL(blob);

        const a = document.createElement('a');
        a.href = blobUrl;
        a.download = `NFCe_${note.numero}.xml`;
        document.body.appendChild(a);
        a.click();

        document.body.removeChild(a);
        window.URL.revokeObjectURL(blobUrl);
    } catch (e: any) {
        console.error(e);
        appStore.showSnackbar('Erro ao tentar baixar o XML.', 'error');
    }
};

const openBulkDownloadModal = () => {
    bulkDownloadModal.show = true;
    bulkDownloadModal.progress.show = false;
    bulkDownloadModal.downloading = false;
};

const downloadBulkXML = async () => {
    if (!activeCompany.value) return appStore.showSnackbar('Selecione uma empresa.', 'warning');
    if (!bulkDownloadModal.startDate || !bulkDownloadModal.endDate) return appStore.showSnackbar('Selecione o período inicial e final.', 'warning');

    bulkDownloadModal.downloading = true;
    bulkDownloadModal.progress.show = false;

    try {
        const cnpjFiltro = String(activeCompany.value.cnpj).replace(/\D/g, '');

        let query = supabase.from('nfce_outbound')
            .select('numero, retorno_sefaz')
            .eq('emitente_cnpj', cnpjFiltro)
            .gte('created_at', `${bulkDownloadModal.startDate}T00:00:00.000Z`)
            .lte('created_at', `${bulkDownloadModal.endDate}T23:59:59.999Z`);

        if (bulkDownloadModal.status !== 'TODOS') {
            if (bulkDownloadModal.status === 'AUTORIZADA') {
                query = query.in('status', ['AUTORIZADA', 'autorizado']);
            } else {
                query = query.eq('status', bulkDownloadModal.status);
            }
        }

        const { data, error } = await query;

        if (error || !data || data.length === 0) {
            appStore.showSnackbar('Nenhuma NFC-e encontrada no Supabase neste período e status.', 'warning');
            return;
        }

        const notasParaBaixar = data.map(n => ({
            id_nuvem: n.retorno_sefaz?.id_nuvem,
            numero: n.numero
        })).filter(n => n.id_nuvem);

        if (notasParaBaixar.length === 0) {
            return appStore.showSnackbar('As notas filtradas não possuem ID vinculado na nuvem.', 'error');
        }

        bulkDownloadModal.progress.total = notasParaBaixar.length;
        bulkDownloadModal.progress.current = 0;
        bulkDownloadModal.progress.show = true;

        const zip = new JSZip();

        for (const nota of notasParaBaixar) {
            try {
                const url = sefazService.getProxyNfceDownloadUrl('xml', nota.id_nuvem);
                const response = await fetch(url);

                if (response.ok) {
                    const xmlText = await response.text();
                    zip.file(`NFCe_${nota.numero}_${cnpjFiltro}.xml`, xmlText);
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
        a.download = `Lote_NFCe_${activeCompany.value.name.substring(0,10)}_${bulkDownloadModal.startDate}.zip`;
        document.body.appendChild(a);
        a.click();

        document.body.removeChild(a);
        window.URL.revokeObjectURL(downloadUrl);

        appStore.showSnackbar(`Download de ${notasParaBaixar.length} XML(s) finalizado!`, 'success');

        setTimeout(() => { bulkDownloadModal.show = false; }, 1000);
    } catch (error: any) {
        console.error(error);
        appStore.showSnackbar(error.message || 'Erro crítico ao empacotar XMLs.', 'error');
    } finally {
        bulkDownloadModal.downloading = false;
    }
};

const shareWhatsapp = (note: any) => {
    const id = note.id_nuvem || note.retorno_sefaz?.id_nuvem;
    let link = note.pdf_url;
    if (id) link = sefazService.getProxyNfceDownloadUrl('pdf', id);

    if (!link) return appStore.showSnackbar('Link do PDF não disponível.', 'warning');

    const text = `Olá, aqui está sua NFC-e: ${link}`;
    const url = `https://wa.me/?text=${encodeURIComponent(text)}`;
    window.open(url, '_blank');
};

const shareEmail = (note: any) => {
    const id = note.id_nuvem || note.retorno_sefaz?.id_nuvem;
    let link = note.pdf_url;
    if (id) link = sefazService.getProxyNfceDownloadUrl('pdf', id);

    if (!link) return appStore.showSnackbar('Link do PDF não disponível.', 'warning');

    const subject = `NFC-e #${note.numero}`;
    const body = `Olá, aqui está o link da sua Nota Fiscal de Consumidor: ${link}`;
    window.open(`mailto:?subject=${encodeURIComponent(subject)}&body=${encodeURIComponent(body)}`, '_self');
};

const cancelNote = async (note: any) => {
    const just = prompt("Justificativa (min 15 chars):");
    if(!just || just.length < 15) return;
    try {
        const id = note.id_nuvem || note.retorno_sefaz?.id_nuvem;
        await sefazService.cancelarNFCe(id, just);

        await supabase.from('nfce_outbound').update({ status: 'CANCELADA' }).eq('id', note.id);

        appStore.showSnackbar('Nota cancelada!', 'success');
        fetchHistory();
    } catch(e:any) { appStore.showSnackbar(e.message, 'error'); }
};

const formatCurrency = (val: number) => new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(val);
const formatCurrencyValue = (val: number) => new Intl.NumberFormat('pt-BR', { minimumFractionDigits: 2 }).format(val);
const formatDate = (d: string) => d ? format(parseISO(d), 'dd/MM/yy HH:mm') : '-';
const getStatusClass = (s: string) => {
    if(s === 'autorizado' || s === 'AUTORIZADA') return 'chip-success';
    if(s === 'cancelado' || s === 'CANCELADA') return 'chip-danger';
    if(s === 'rejeitado' || s === 'REJEITADA') return 'chip-danger';
    return 'chip-grey';
};
const zebraClass = (i: number) => themeStore.currentMode !== 'light' ? (i % 2 === 0 ? 'zebra-dark-a' : 'zebra-dark-b') : (i % 2 === 0 ? 'zebra-light-a' : 'zebra-light-b');

onMounted(() => { loadCompanies(); });
</script>

<style scoped lang="scss">
.nfce-layout { position: relative; }
.background-carousel-wrapper { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 0; opacity: 0.6; pointer-events: none; }
.background-overlay { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 1; background: radial-gradient(circle at center, rgba(15, 15, 19, 0.4), rgba(15, 15, 19, 0.98)); backdrop-filter: blur(8px); }
.z-10 { position: relative; z-index: 10; }

/* Dark Mode Specifics */
.bg-glass-dark { background: rgba(10,10,12,0.85); }
.bg-glass-header { background: rgba(20,20,24,0.55); backdrop-filter: blur(14px); }
.border-bottom-white-05 { border-bottom: 1px solid rgba(255,255,255,0.08) !important; }
.border-white-10 { border: 1px solid rgba(255,255,255,0.1) !important; }
.bg-black-20 { background: rgba(0,0,0,0.2) !important; }
.text-white-70 { color: rgba(255,255,255,0.7) !important; }

/* Ações e Botões 3D */
.btn-3d { box-shadow: 0 3px 5px rgba(0,0,0,0.15), inset 0 2px 0 rgba(255,255,255,0.25) !important; text-transform: none !important; transition: transform 0.1s ease, box-shadow 0.1s ease; }
.btn-3d:active { transform: translateY(2px); box-shadow: 0 1px 2px rgba(0,0,0,0.15), inset 0 1px 0 rgba(255,255,255,0.2) !important; }
.shadow-indigo-soft { box-shadow: 0 4px 15px rgba(63, 81, 181, 0.4); }

.controls-bar { padding: 10px; }
.controls-light { background: #ffffff; border: 1px solid rgba(0,0,0,0.08); }
.controls-dark { background: rgba(30,30,35,0.55); backdrop-filter: blur(16px); }
.search-wrap { height: 40px; padding: 0 12px; border: 1px solid rgba(0,0,0,0.08); min-width: 300px; flex: 1; }
.search-light { background: #f4f6f8; }
.search-dark { background: rgba(255,255,255,0.08); border-color: rgba(255,255,255,0.10); }
.clean-input { border: none; outline: none; background: transparent; font-size: 13px; font-weight: bold; width: 100%; }

/* KPIs */
.kpi-bg-icon { position: absolute; right: -20px; bottom: -20px; opacity: 0.15; transform: rotate(-15deg); pointer-events: none; }
.kpi-bg-icon .v-icon { font-size: 100px; color: white; }
.kpi-card { border: 1px solid rgba(255,255,255,0.15); color: white; min-height: 110px; position: relative; overflow: hidden; cursor: default; }
.kpi-rect { border-radius: 8px !important; }
.bg-gradient-info { background: linear-gradient(135deg, #0288d1, #005b9f); }
.bg-gradient-green { background: linear-gradient(135deg, #2e7d32, #1b5e20); }
.bg-gradient-purple { background: linear-gradient(135deg, #7b1fa2, #4a148c); }
.bg-gradient-deep-orange { background: linear-gradient(135deg, #FF5722, #E64A19); cursor: pointer; }
.kpi-label { font-size: 12px; font-weight: 900; letter-spacing: .2px; text-transform: uppercase; }
.kpi-value { font-size: 24px; font-weight: 900; letter-spacing: .2px; }

/* Grid Layout */
.grid-nfce-layout { display: grid; width: 100%; grid-template-columns: 140px 100px 140px 1fr 120px 160px; min-width: 1000px;}
.cell { padding: 8px 10px; display: flex; align-items: center; border-right: 1px solid rgba(0,0,0,0.08); border-bottom: 1px solid rgba(0,0,0,0.08); min-height: 56px; overflow: hidden; transition: background-color 0.2s ease;}
.center { justify-content: center; text-align: center; }
.right { justify-content: flex-end; text-align: right; }

.grid-header .cell { min-height: 44px; font-size: 11px !important; font-weight: 900; text-transform: uppercase; letter-spacing: 0.5px; opacity: 0.8; }
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
.sticky-head { position: sticky; top: 0; z-index: 10; box-shadow: 0 8px 16px -4px rgba(0, 0, 0, 0.12); }
.bg-glass-dark .sticky-head { box-shadow: 0 8px 20px -4px rgba(0, 0, 0, 0.4); }

.v-theme--dark { .text-grey-darken-4, .text-grey-darken-3, .text-grey-darken-2, .text-grey-darken-1, .text-grey { color: rgba(255,255,255,0.9) !important; } }

/* CHIPS & ACTIONS */
.solid-chip { display: inline-flex; align-items: center; justify-content: center; height: 22px; padding: 0 10px; font-size: 10px; font-weight: 900; color: #fff; white-space: nowrap; text-transform: uppercase; }
.chip-3d { border-radius: 6px !important; box-shadow: 0 3px 5px rgba(0,0,0,0.12), inset 0 1px 0 rgba(255,255,255,0.25) !important; text-shadow: 0 1px 2px rgba(0,0,0,0.25); }
.chip-success { background: #2e7d32; }
.chip-danger { background: #c62828; }
.chip-grey { background: #78909c; }

.actions-inline { display: flex; gap: 4px; justify-content: center; }
.action-btn { width: 28px !important; height: 28px !important; color: #fff !important; }
.action-print { background: #1976d2 !important; }
.action-cancel { background: #c62828 !important; }

.glass-card { background: rgba(255,255,255,0.03); backdrop-filter: blur(10px); }
.list-text-11 { font-size: 13px !important; line-height: 1.2 !important; }
.grid-scroll { scrollbar-gutter: stable; -webkit-overflow-scrolling: touch; }
.custom-scroll::-webkit-scrollbar { width: 8px; height: 8px; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.35); border-radius: 6px; }
.custom-scroll::-webkit-scrollbar-track { background: transparent; }

/* Icons Box */
.icon-box { width: 42px; height: 42px; display: flex; align-items: center; justify-content: center; }
.ui-field :deep(.v-field) { border-radius: 6px !important; }
.input-label { font-size: 12px; font-weight: 900; margin-bottom: 4px; display: block; opacity: 0.8;}
.hide-scrollbar::-webkit-scrollbar { display: none; }
.hide-scrollbar { -ms-overflow-style: none; scrollbar-width: none; }
</style>
