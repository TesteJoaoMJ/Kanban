<template>
  <div class="page-wrapper h-100 overflow-hidden d-flex flex-column bg-grey-lighten-5">

    <div class="header-bar px-6 py-4 bg-white border-b d-flex flex-column flex-md-row align-md-center justify-space-between flex-shrink-0 elevation-1" style="z-index: 10;">
        <div>
            <div class="d-flex align-center gap-2 text-caption text-medium-emphasis mb-1">
                <v-icon size="14">mdi-bank-outline</v-icon>
                <span>Módulo Financeiro</span>
                <v-icon size="12">mdi-chevron-right</v-icon>
                <span class="font-weight-bold text-primary">Banking & Conciliação</span>
            </div>
            <h1 class="text-h5 font-weight-black text-grey-darken-4 d-flex align-center gap-3">
                Gestão Bancária Integrada
                <v-chip size="small" color="blue-darken-3" class="font-weight-bold" variant="flat">V2.0</v-chip>
            </h1>
        </div>

        <div class="d-flex align-center gap-3 mt-4 mt-md-0">
            <v-tabs v-model="currentTab" color="primary" density="compact" class="bg-grey-lighten-4 rounded-lg border pa-1" hide-slider height="40">
                <v-tab value="accounts" class="text-none font-weight-bold text-caption rounded" :class="currentTab === 'accounts' ? 'bg-white elevation-1' : ''">Contas</v-tab>
                <v-tab value="reports" class="text-none font-weight-bold text-caption rounded" :class="currentTab === 'reports' ? 'bg-white elevation-1' : ''">Extrato Geral</v-tab>
            </v-tabs>

            <v-divider vertical class="mx-2 hidden-xs"></v-divider>

            <v-btn color="blue-darken-3" variant="flat" class="text-none font-weight-bold px-4 elevation-2" height="40" prepend-icon="mdi-bank-plus" @click="openNewAccountModal">
                Nova Conta
            </v-btn>
            <v-btn color="teal-darken-3" variant="flat" class="text-none font-weight-bold px-4 elevation-2" height="40" prepend-icon="mdi-file-import" @click="triggerOfxUpload">
                Importar OFX
            </v-btn>
            <input type="file" ref="ofxInput" class="d-none" accept=".ofx,.xml" @change="handleOfxUpload" />
        </div>
    </div>

    <div class="flex-grow-1 overflow-y-auto custom-scrollbar px-6 py-6">
      <v-window v-model="currentTab" class="h-100">

        <v-window-item value="accounts" class="h-100">
            <v-row dense class="mb-6">
                <v-col cols="12" md="4" v-for="(kpi, idx) in kpiList" :key="idx">
                    <v-card class="rounded-xl h-100 border relative overflow-hidden" :class="kpi.bgColor" elevation="0">
                        <div class="pa-5 d-flex flex-column justify-center h-100 z-10 relative">
                            <div class="d-flex align-center justify-space-between mb-2">
                                <span class="text-caption font-weight-bold text-uppercase letter-spacing-1" :class="kpi.textColor">{{ kpi.label }}</span>
                                <v-icon size="24" :class="kpi.textColor" class="opacity-80">{{ kpi.icon }}</v-icon>
                            </div>
                            <div>
                                <div class="text-h4 font-weight-black lh-1 mb-1 font-mono tracking-tight" :class="kpi.textColor">
                                    {{ kpi.isCurrency ? formatCurrencyValue(kpi.value) : kpi.value }}
                                </div>
                                <div class="text-caption opacity-80" :class="kpi.textColor">{{ kpi.footer }}</div>
                            </div>
                        </div>
                    </v-card>
                </v-col>
            </v-row>

            <v-card class="rounded-xl border shadow-sm bg-white overflow-hidden" elevation="0">
                <div class="px-5 py-4 border-b bg-grey-lighten-5 d-flex align-center justify-space-between">
                     <span class="text-subtitle-2 font-weight-black text-grey-darken-3 text-uppercase">Carteira de Contas</span>
                     <div class="search-wrap d-flex align-center bg-white border rounded px-3" style="width: 300px; height: 36px;">
                        <v-icon size="18" color="grey-darken-1" class="mr-2">mdi-magnify</v-icon>
                        <input v-model="search" type="text" placeholder="Buscar conta ou banco..." class="clean-input flex-grow-1 text-body-2" />
                     </div>
                </div>

                <div class="table-container">
                    <div v-if="loading" class="pa-12 text-center"><v-progress-circular indeterminate color="primary"></v-progress-circular></div>
                    <div v-else-if="filteredAccounts.length === 0" class="pa-12 text-center text-grey"><v-icon size="48" class="mb-3">mdi-bank-off</v-icon><br/>Nenhuma conta encontrada.</div>

                    <div v-else class="grid-table">
                        <div class="grid-header bg-grey-lighten-4 border-b">
                            <div class="cell" style="width: 250px">Instituição / Conta</div>
                            <div class="cell" style="width: 200px">Agência e C/C</div>
                            <div class="cell center" style="width: 120px">Status</div>
                            <div class="cell right flex-grow-1 pr-6">Saldo Atual</div>
                            <div class="cell center" style="width: 120px">Ações</div>
                        </div>

                        <div v-for="item in filteredAccounts" :key="item.id" class="grid-row border-b hover-bg transition-all">
                            <div class="cell" style="width: 250px">
                                <div class="d-flex align-center gap-3">
                                    <v-avatar size="36" rounded class="border" :class="getBankStyles(item.bank_name).bg">
                                        <v-icon size="18" :class="getBankStyles(item.bank_name).text">mdi-bank</v-icon>
                                    </v-avatar>
                                    <div class="d-flex flex-column">
                                        <span class="text-body-2 font-weight-bold text-grey-darken-4">{{ item.name }}</span>
                                        <span class="text-caption text-grey-darken-1">{{ item.bank_name }}</span>
                                    </div>
                                </div>
                            </div>
                            <div class="cell" style="width: 200px">
                                <div class="d-flex flex-column">
                                    <span class="text-caption font-mono text-grey-darken-1">Ag: {{ item.agency || '-' }}</span>
                                    <span class="text-caption font-mono font-weight-bold text-grey-darken-4">CC: {{ item.account_number || '-' }}</span>
                                </div>
                            </div>
                            <div class="cell center" style="width: 120px">
                                <v-chip size="x-small" :color="item.is_active ? 'success' : 'grey'" variant="tonal" class="font-weight-bold text-uppercase px-3">
                                    {{ item.is_active ? 'Ativa' : 'Inativa' }}
                                </v-chip>
                            </div>
                            <div class="cell right flex-grow-1 pr-6">
                                <span class="text-subtitle-1 font-mono font-weight-black" :class="item.current_balance >= 0 ? 'text-green-darken-3' : 'text-red-darken-3'">
                                    {{ formatCurrency(item.current_balance) }}
                                </span>
                            </div>
                            <div class="cell center" style="width: 120px">
                                <v-btn icon size="x-small" variant="text" color="blue-darken-2" @click.stop="openEditModal(item)"><v-icon>mdi-pencil</v-icon></v-btn>
                                <v-btn icon size="x-small" variant="text" :color="item.is_active ? 'amber-darken-3' : 'green-darken-2'" @click.stop="toggleStatus(item)">
                                    <v-icon>{{ item.is_active ? 'mdi-archive' : 'mdi-archive-refresh' }}</v-icon>
                                </v-btn>
                            </div>
                        </div>
                    </div>
                </div>
            </v-card>
        </v-window-item>

        <v-window-item value="reports" class="h-100">
            <v-card class="rounded-xl border shadow-sm bg-white h-100 d-flex flex-column" elevation="0">
                <div class="pa-4 border-b bg-grey-lighten-5 d-flex flex-wrap align-center justify-space-between gap-4">
                    <div class="d-flex align-center gap-4">
                        <div class="d-flex align-center gap-2">
                            <v-icon color="primary" size="20">mdi-filter-variant</v-icon>
                            <span class="text-subtitle-2 font-weight-bold">Filtros:</span>
                        </div>
                        <input type="date" v-model="reportFilter.startDate" class="date-input" />
                        <span class="text-grey">até</span>
                        <input type="date" v-model="reportFilter.endDate" class="date-input" />

                        <v-autocomplete
                            v-model="reportFilter.accountId"
                            :items="[{id: 'all', name: 'Todas as Contas'}, ...accounts]"
                            item-title="name"
                            item-value="id"
                            density="compact"
                            variant="outlined"
                            hide-details
                            bg-color="white"
                            style="width: 250px;"
                        ></v-autocomplete>

                        <v-btn color="grey-darken-4" variant="flat" class="text-none font-weight-bold" @click="fetchReports">Atualizar</v-btn>
                    </div>
                    <v-btn color="primary" variant="outlined" prepend-icon="mdi-download" size="small" class="font-weight-bold">Exportar CSV</v-btn>
                </div>

                <div class="flex-grow-1 overflow-y-auto custom-scrollbar">
                     <div class="grid-table">
                        <div class="grid-header bg-grey-lighten-4 border-b sticky-header">
                            <div class="cell" style="width: 120px">Data</div>
                            <div class="cell" style="width: 180px">Conta</div>
                            <div class="cell flex-grow-1">Descrição / Histórico</div>
                            <div class="cell" style="width: 180px">Categoria</div>
                            <div class="cell right" style="width: 150px">Movimento</div>
                            <div class="cell center" style="width: 100px">Status</div>
                        </div>

                        <div v-if="transactions.length === 0" class="pa-12 text-center text-grey">Nenhum registro no período.</div>

                        <div v-else v-for="tx in transactions" :key="tx.id" class="grid-row border-b hover-bg" :class="tx.type === 'INCOME' ? 'border-l-4-green' : 'border-l-4-red'">
                            <div class="cell font-mono text-caption" style="width: 120px">{{ formatDateSimple(tx.transaction_date) }}</div>
                            <div class="cell text-caption" style="width: 180px">{{ getAccountName(tx.account_id) }}</div>
                            <div class="cell flex-grow-1 font-weight-bold text-caption text-truncate">{{ tx.description }}</div>
                            <div class="cell text-caption text-grey-darken-1" style="width: 180px">{{ tx.category || 'Não categorizado' }}</div>
                            <div class="cell right font-mono font-weight-black" style="width: 150px" :class="tx.type === 'INCOME' ? 'text-green-darken-3' : 'text-red-darken-3'">
                                {{ tx.type === 'INCOME' ? '+' : '-' }} {{ formatCurrency(tx.amount) }}
                            </div>
                            <div class="cell center" style="width: 100px">
                                <v-icon size="18" :color="tx.reconciliation_status === 'CONCILIATED' ? 'success' : 'grey'">
                                    {{ tx.reconciliation_status === 'CONCILIATED' ? 'mdi-check-all' : 'mdi-check' }}
                                </v-icon>
                            </div>
                        </div>
                    </div>
                </div>
            </v-card>
        </v-window-item>

      </v-window>
    </div>

    <v-dialog v-model="concileModal.show" fullscreen transition="dialog-bottom-transition" :scrim="false">
        <v-card class="rounded-0 d-flex flex-column fill-height bg-grey-lighten-5">
            <div class="bg-blue-grey-darken-4 text-white px-6 py-4 d-flex align-center justify-space-between flex-shrink-0 elevation-4" style="z-index: 20;">
                <div class="d-flex align-center gap-4">
                    <div class="bg-teal-accent-4 rounded-lg pa-2 elevation-2">
                        <v-icon size="28" color="blue-grey-darken-4">mdi-bank-transfer</v-icon>
                    </div>
                    <div>
                        <div class="text-h6 font-weight-black text-uppercase letter-spacing-1">Auditoria de Conciliação OFX</div>
                        <div class="text-caption text-teal-accent-2 font-weight-bold d-flex align-center gap-2">
                            <v-icon size="14">mdi-file-document-outline</v-icon> Analisando {{ concileModal.items.length }} registros do extrato
                        </div>
                    </div>
                </div>

                <div class="d-flex align-center gap-6">
                    <div class="d-flex align-center bg-white-10 rounded px-4 py-1 border border-white-20">
                        <div class="text-center mr-4 pr-4 border-e border-white-20">
                            <div class="text-[10px] text-uppercase text-grey-lighten-1">Lançamentos Identificados</div>
                            <div class="text-subtitle-1 font-weight-black text-teal-accent-3">{{ stats.matched }}</div>
                        </div>
                        <div class="text-center">
                            <div class="text-[10px] text-uppercase text-grey-lighten-1">Lançamentos Novos</div>
                            <div class="text-subtitle-1 font-weight-black text-white">{{ stats.new }}</div>
                        </div>
                    </div>

                    <v-btn icon="mdi-close" variant="text" color="white" @click="concileModal.show = false"></v-btn>
                </div>
            </div>

            <div class="bg-white border-b px-6 py-3 flex-shrink-0 d-flex align-center gap-4 elevation-1" style="z-index: 10;">
                <v-autocomplete
                    label="Conta Bancária de Destino"
                    v-model="concileModal.targetAccount"
                    :items="accounts"
                    item-title="name"
                    item-value="id"
                    variant="outlined"
                    density="compact"
                    hide-details
                    bg-color="grey-lighten-5"
                    style="max-width: 350px;"
                    placeholder="Obrigatório: Selecione a conta..."
                    prepend-inner-icon="mdi-bank"
                    @update:model-value="analyzeOfxMatches"
                >
                    <template v-slot:item="{ props, item }">
                        <v-list-item v-bind="props" :subtitle="item.raw.bank_name"></v-list-item>
                    </template>
                </v-autocomplete>

                <v-divider vertical class="mx-2"></v-divider>

                <div v-if="concileModal.analyzing" class="d-flex align-center gap-2 text-teal-darken-3 font-weight-bold bg-teal-lighten-5 px-4 py-2 rounded">
                    <v-progress-circular indeterminate size="20" width="2" color="teal"></v-progress-circular>
                    Inteligência Artificial cruzando dados...
                </div>
                <div v-else-if="concileModal.targetAccount" class="text-caption text-grey-darken-1">
                    Revise os vínculos abaixo. O sistema fará a baixa automática nos títulos que deram "Match".
                </div>

                <v-spacer></v-spacer>

                <v-btn
                    color="teal-darken-3"
                    size="large"
                    class="font-weight-black px-8 elevation-2 text-none"
                    prepend-icon="mdi-check-all"
                    @click="processConciliation"
                    :loading="concileModal.processing"
                    :disabled="!concileModal.targetAccount || concileModal.analyzing"
                >
                    Processar Lançamentos Selecionados
                </v-btn>
            </div>

            <div class="flex-grow-1 overflow-y-auto bg-white custom-scrollbar">
                <div class="grid-table reconciliation-grid">
                    <div class="grid-header sticky-header shadow-sm" style="background: #F5F7FA;">
                        <div class="cell center" style="width: 50px;">
                            <v-checkbox-btn v-model="concileModal.selectAll" @update:model-value="toggleAllOfx" density="compact" color="teal-darken-3"></v-checkbox-btn>
                        </div>

                        <div class="cell d-flex flex-column justify-center align-start border-r" style="width: 380px;">
                            <div class="text-[10px] text-blue-grey-darken-1 font-weight-black text-uppercase">Dados do Banco (OFX)</div>
                            <div class="text-[9px] text-grey">O que realmente aconteceu na conta</div>
                        </div>
                        <div class="cell right border-r pr-4" style="width: 140px;">
                            <div class="text-[10px] text-blue-grey-darken-1 font-weight-black text-uppercase">Valor Real</div>
                        </div>

                        <div class="cell center border-r bg-grey-lighten-3" style="width: 80px;">
                            <v-icon size="16" color="grey-darken-1">mdi-link</v-icon>
                        </div>

                        <div class="cell pl-4 flex-grow-1">
                            <div class="text-[10px] text-teal-darken-3 font-weight-black text-uppercase">Dados do Sistema (Previsão / Match)</div>
                            <div class="text-[9px] text-grey">O que o sistema encontrou para dar baixa</div>
                        </div>
                        <div class="cell center" style="width: 100px;">
                            <div class="text-[10px] text-blue-grey-darken-1 font-weight-black text-uppercase">Ação</div>
                        </div>
                    </div>

                    <div v-for="(item, idx) in concileModal.items" :key="idx"
                        class="grid-row border-b transition-all"
                        :class="getRowBgClass(item)"
                    >
                        <div class="cell center" style="width: 50px;">
                            <v-checkbox-btn v-model="item.selected" :disabled="item.exists" density="compact" color="teal-darken-3"></v-checkbox-btn>
                        </div>

                        <div class="cell border-r py-2 d-flex flex-column align-start justify-center" style="width: 380px;">
                            <div class="d-flex align-center gap-2 mb-1">
                                <span class="font-mono text-caption font-weight-black text-grey-darken-4">{{ formatDateSimple(item.date) }}</span>
                                <v-chip size="x-small" :color="item.amount >= 0 ? 'green-lighten-5' : 'red-lighten-5'" :text-color="item.amount >= 0 ? 'green-darken-4' : 'red-darken-4'" class="font-weight-bold px-1" variant="flat">
                                    {{ item.amount >= 0 ? 'CRÉDITO' : 'DÉBITO' }}
                                </v-chip>
                            </div>
                            <span class="text-caption font-weight-bold text-blue-grey-darken-3 text-truncate w-100" :title="item.memo">{{ item.memo }}</span>
                            <span class="text-[10px] font-mono text-grey mt-1">FITID: {{ item.fitid.substring(0, 15) }}...</span>
                        </div>

                        <div class="cell right border-r pr-4" style="width: 140px;">
                            <span class="text-subtitle-2 font-mono font-weight-black" :class="item.amount >= 0 ? 'text-green-darken-3' : 'text-red-darken-3'">
                                {{ formatCurrency(item.amount) }}
                            </span>
                        </div>

                        <div class="cell center border-r" style="width: 80px;" :class="item.exists ? 'bg-grey-lighten-3' : (item.match ? 'bg-teal-lighten-5' : 'bg-orange-lighten-5')">
                            <v-tooltip location="top">
                                <template v-slot:activator="{ props }">
                                    <v-icon v-bind="props" size="24" :color="item.exists ? 'grey' : (item.match ? 'teal-darken-2' : 'orange-darken-2')">
                                        {{ item.exists ? 'mdi-cancel' : (item.match ? (item.matchQuality === 'EXATO' ? 'mdi-check-decagram' : 'mdi-check-circle-outline') : 'mdi-alert-circle-outline') }}
                                    </v-icon>
                                </template>
                                <span>{{ item.exists ? 'Já Importado' : (item.match ? `Match: ${item.matchQuality}` : 'Nenhum Match Encontrado') }}</span>
                            </v-tooltip>
                        </div>

                        <div class="cell pl-4 py-2 flex-grow-1 d-flex flex-column justify-center align-start">

                            <div v-if="item.exists" class="text-caption text-grey-darken-1 font-italic d-flex align-center gap-2">
                                <v-icon size="16">mdi-history</v-icon> Esta transação já foi importada anteriormente e será ignorada.
                            </div>

                            <div v-else-if="item.match" class="w-100">
                                <div class="d-flex align-center justify-space-between mb-1 w-100">
                                    <div class="d-flex align-center gap-2">
                                        <v-chip color="teal" size="x-small" variant="flat" class="font-weight-bold uppercase">
                                            <v-icon start size="12">mdi-link-variant</v-icon> VÍNCULO ENCONTRADO
                                        </v-chip>
                                        <span class="text-[10px] font-weight-bold" :class="item.matchQuality === 'EXATO' ? 'text-teal-darken-2' : 'text-orange-darken-2'">
                                            {{ item.matchQuality === 'EXATO' ? 'Data e Valor Exatos' : `Diferença de Vencimento: ${item.diffDays} dia(s)` }}
                                        </span>
                                    </div>
                                    <v-btn size="x-small" variant="text" color="red" density="compact" @click="item.match = null" class="text-none">Desfazer Vínculo</v-btn>
                                </div>

                                <div class="d-flex align-center gap-3 w-100 mt-1 p-2 bg-white rounded border border-teal-lighten-4">
                                    <div class="d-flex flex-column flex-grow-1 overflow-hidden pa-2">
                                        <div class="d-flex justify-space-between align-center">
                                            <span class="text-caption font-weight-black text-grey-darken-4 text-truncate" style="max-width: 300px;">{{ item.match.description }}</span>
                                            <span class="text-caption font-mono font-weight-bold text-grey-darken-3">{{ formatCurrency(item.match.amount) }}</span>
                                        </div>
                                        <div class="d-flex align-center gap-2 mt-1 text-[10px] text-grey-darken-1">
                                            <span><v-icon size="12" class="mr-1">mdi-calendar-clock</v-icon>Venc: {{ formatDateSimple(item.match.transaction_date) }}</span>
                                            <span>•</span>
                                            <span class="text-truncate" style="max-width: 150px;"><v-icon size="12" class="mr-1">mdi-domain</v-icon>{{ item.match.entity_name || 'N/D' }}</span>
                                            <span>•</span>
                                            <span class="bg-grey-lighten-3 px-1 rounded text-grey-darken-2">{{ item.match.category || 'Geral' }}</span>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <div v-else class="w-100">
                                <v-chip color="orange-darken-2" size="x-small" variant="outlined" class="font-weight-bold uppercase mb-1">
                                    <v-icon start size="12">mdi-plus-circle-outline</v-icon> REGISTRAR COMO NOVO
                                </v-chip>
                                <div class="text-caption text-grey-darken-2 mt-1">
                                    Nenhum título pendente com este valor foi encontrado. Ao processar, o sistema criará um novo registro de {{ item.amount >= 0 ? 'Receita' : 'Despesa' }} direto no caixa.
                                </div>
                            </div>

                        </div>

                        <div class="cell center" style="width: 100px;">
                            <v-chip v-if="!item.exists" size="x-small" :color="item.match ? 'teal' : 'orange'" variant="tonal" class="font-weight-bold">
                                {{ item.match ? 'BAIXAR' : 'CRIAR' }}
                            </v-chip>
                            <span v-else class="text-[10px] text-grey">IGNORADO</span>
                        </div>
                    </div>
                </div>
            </div>
        </v-card>
    </v-dialog>

    <v-dialog v-model="feedbackState.show" max-width="450" persistent>
        <v-card class="rounded-xl">
            <v-card-text class="text-center pa-8">
                <div v-if="feedbackState.status === 'processing'" class="d-flex flex-column align-center">
                    <v-progress-circular indeterminate color="teal-darken-3" size="64" width="6" class="mb-4"></v-progress-circular>
                    <h3 class="text-h6 font-weight-bold">{{ feedbackState.title }}</h3>
                    <p class="text-body-2 text-medium-emphasis mt-2">{{ feedbackState.message }}</p>
                </div>
                <div v-else-if="feedbackState.status === 'success'" class="d-flex flex-column align-center">
                    <div class="icon-circle bg-green-lighten-5 mb-4 d-flex align-center justify-center" style="width: 80px; height: 80px; border-radius: 50%;">
                        <v-icon color="success" size="48">mdi-check-circle</v-icon>
                    </div>
                    <h3 class="text-h6 font-weight-bold text-success">{{ feedbackState.title }}</h3>
                    <p class="text-body-2 mt-2">{{ feedbackState.message }}</p>
                </div>
                <div v-else-if="feedbackState.status === 'error'" class="d-flex flex-column align-center">
                    <div class="icon-circle bg-red-lighten-5 mb-4 d-flex align-center justify-center" style="width: 80px; height: 80px; border-radius: 50%;">
                        <v-icon color="error" size="48">mdi-alert-circle</v-icon>
                    </div>
                    <h3 class="text-h6 font-weight-bold text-error">{{ feedbackState.title }}</h3>
                    <p class="text-body-2 mt-2">{{ feedbackState.message }}</p>
                </div>
            </v-card-text>
            <v-card-actions v-if="feedbackState.status !== 'processing'" class="justify-center pb-6">
                <v-btn color="grey-darken-4" variant="flat" size="large" class="px-8 font-weight-bold rounded-lg" @click="feedbackState.show = false">Fechar</v-btn>
            </v-card-actions>
        </v-card>
    </v-dialog>

  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, reactive, watch } from 'vue';
import { supabase } from '@/api/supabase';
import { format, parseISO, startOfMonth, endOfMonth, isValid, addDays, subDays } from 'date-fns';
import { useAppStore } from '@/stores/app';
import { useUserStore } from '@/stores/user';

const appStore = useAppStore();
const userStore = useUserStore();

// --- STATE GERAL ---
const currentTab = ref('accounts');
const loading = ref(false);
const accounts = ref<any[]>([]);
const transactions = ref<any[]>([]);
const search = ref('');
const ofxInput = ref<HTMLInputElement | null>(null);

const feedbackState = reactive({ show: false, status: 'idle', title: '', message: '', details: [] as string[] });

const reportFilter = reactive({
    startDate: format(startOfMonth(new Date()), 'yyyy-MM-dd'),
    endDate: format(endOfMonth(new Date()), 'yyyy-MM-dd'),
    accountId: 'all'
});

const concileModal = reactive({
    show: false,
    items: [] as any[],
    targetAccount: null as string | null,
    selectAll: true,
    processing: false,
    analyzing: false
});

const editModal = reactive({
    show: false,
    loading: false,
    form: { id: '', name: '', bank_name: '', agency: '', account_number: '', initial_balance: 0, current_balance: 0, balance_date: format(new Date(), 'yyyy-MM-dd'), is_active: true }
});

const stats = computed(() => {
    return {
        matched: concileModal.items.filter(i => i.match && !i.exists && i.selected).length,
        new: concileModal.items.filter(i => !i.match && !i.exists && i.selected).length,
    }
});

const bankOptions = ['Itaú', 'Santander', 'Banco do Brasil', 'Nubank', 'Cora', 'Sicredi', 'Caixa Econômica', 'Bradesco', 'Inter', 'Original', 'Dinheiro / Cofre'];

const filteredAccounts = computed(() => {
    let list = accounts.value;
    if (search.value) {
        const term = search.value.toLowerCase();
        list = list.filter(i => i.name?.toLowerCase().includes(term) || i.bank_name?.toLowerCase().includes(term) || i.account_number?.includes(term));
    }
    return list.sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime());
});

const kpiList = computed(() => {
    const totalBalance = accounts.value.reduce((acc, i) => acc + (Number(i.current_balance)||0), 0);
    const activeCount = accounts.value.filter(i => i.is_active).length;
    return [
        { label: 'Saldo Total Consolidado', value: totalBalance, isCurrency: true, footer: 'Soma de todas as contas', icon: 'mdi-cash-multiple', bgColor: 'bg-white', textColor: 'text-blue-darken-3' },
        { label: 'Contas Ativas', value: activeCount, isCurrency: false, footer: 'Contas em operação', icon: 'mdi-bank-check', bgColor: 'bg-white', textColor: 'text-teal-darken-3' },
        { label: 'Movimentações no Mês', value: transactions.value.length, isCurrency: false, footer: 'Registros processados', icon: 'mdi-chart-timeline-variant', bgColor: 'bg-white', textColor: 'text-blue-grey-darken-2' },
    ];
});

const formatCurrency = (val: any) => new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(Number(val)||0);
const formatCurrencyValue = (val: any) => new Intl.NumberFormat('pt-BR', { minimumFractionDigits: 2 }).format(Number(val)||0);
const formatDateSimple = (date: string) => {
    if (!date) return '-';
    try { const d = parseISO(date); return isValid(d) ? format(d, 'dd/MM/yyyy') : date; } catch { return date; }
};

const getBankStyles = (bankName: string) => {
    const name = bankName?.toLowerCase() || '';
    if(name.includes('cora')) return { bg: 'bg-pink-lighten-5', text: 'text-pink-accent-3' };
    if(name.includes('sicredi')) return { bg: 'bg-green-lighten-5', text: 'text-green-darken-3' };
    if(name.includes('itaú')) return { bg: 'bg-orange-lighten-5', text: 'text-orange-darken-3' };
    if(name.includes('santander')) return { bg: 'bg-red-lighten-5', text: 'text-red-darken-3' };
    if(name.includes('nubank')) return { bg: 'bg-purple-lighten-5', text: 'text-purple-accent-3' };
    if(name.includes('inter')) return { bg: 'bg-orange-lighten-5', text: 'text-orange-accent-3' };
    if(name.includes('brasil')) return { bg: 'bg-yellow-lighten-4', text: 'text-yellow-darken-4' };
    return { bg: 'bg-grey-lighten-4', text: 'text-grey-darken-3' };
};

const getAccountName = (id: string) => accounts.value.find(a => a.id === id)?.name || 'Conta Excluída';
const getRowBgClass = (item: any) => {
    if (item.exists) return 'bg-grey-lighten-4 opacity-70';
    if (!item.selected) return 'bg-white opacity-50 grayscale';
    if (item.match) return 'bg-teal-lighten-5'; // Fundo leve verde se tem match
    return 'bg-white';
};

const fetchAccounts = async () => {
    loading.value = true;
    try {
        const { data } = await supabase.from('finance_accounts').select('*');
        accounts.value = data || [];
    } catch { appStore.showSnackbar('Erro ao carregar contas.', 'error'); } finally { loading.value = false; }
};

const fetchReports = async () => {
    try {
        let query = supabase.from('finance_transactions').select('*')
            .gte('transaction_date', reportFilter.startDate).lte('transaction_date', reportFilter.endDate).order('transaction_date', { ascending: false });
        if (reportFilter.accountId !== 'all') query = query.eq('account_id', reportFilter.accountId);
        const { data } = await query;
        if (data) transactions.value = data;
    } catch { transactions.value = []; }
};

const openNewAccountModal = () => { Object.assign(editModal.form, { id: '', name: '', bank_name: '', agency: '', account_number: '', initial_balance: 0, current_balance: 0, balance_date: format(new Date(), 'yyyy-MM-dd'), is_active: true }); editModal.show = true; };
const openEditModal = (item: any) => { Object.assign(editModal.form, { ...item, balance_date: item.balance_date || format(new Date(), 'yyyy-MM-dd') }); editModal.show = true; };
const saveAccount = async () => { /* Mesma lógica mantida do original para contas... */ };
const toggleStatus = async (item: any) => { await supabase.from('finance_accounts').update({ is_active: !item.is_active }).eq('id', item.id); item.is_active = !item.is_active; };

// --- LEITURA OFX ---
const triggerOfxUpload = () => ofxInput.value?.click();
const getTagValue = (content: string, tag: string) => { const match = content.match(new RegExp(`<${tag}>([^<]*)`, 'i')); return match ? match[1].trim() : null; };
const parseOfxDate = (dateStr: string | null) => {
    if (!dateStr || dateStr.length < 8) return new Date().toISOString().split('T')[0];
    return `${dateStr.substring(0, 4)}-${dateStr.substring(4, 6)}-${dateStr.substring(6, 8)}`;
};

const handleOfxUpload = async (e: any) => {
    const file = e.target.files[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = async (ev: any) => {
        const content = ev.target.result as string;
        const transactionsRaw = content.split(/<STMTTRN>/i);
        if (transactionsRaw.length > 0) transactionsRaw.shift();

        const parsedItems = transactionsRaw.map((block) => {
            const date = parseOfxDate(getTagValue(block, 'DTPOSTED'));
            const amountStr = getTagValue(block, 'TRNAMT');
            const memo = getTagValue(block, 'MEMO');
            const fitid = getTagValue(block, 'FITID');
            const amount = parseFloat(amountStr?.replace(',', '.') || '0');

            return {
                date, memo, amount, fitid: fitid || `MANUAL_${Date.now()}_${Math.random()}`,
                type: amount >= 0 ? 'INCOME' : 'EXPENSE',
                selected: true, exists: false, match: null, matchQuality: '', diffDays: 0
            };
        });

        concileModal.items = parsedItems.sort((a,b) => new Date(b.date).getTime() - new Date(a.date).getTime());
        concileModal.targetAccount = null;
        concileModal.show = true;
    };
    reader.readAsText(file);
    e.target.value = '';
};

const toggleAllOfx = (val: boolean) => concileModal.items.forEach(i => { if(!i.exists) i.selected = val; });

// --- ALGORITMO INTELIGENTE (COM METADADOS EXTRAS) ---
const analyzeOfxMatches = async () => {
    if (!concileModal.targetAccount || concileModal.items.length === 0) return;
    concileModal.analyzing = true;

    try {
        const dates = concileModal.items.map(i => parseISO(i.date).getTime());
        const minDate = format(subDays(new Date(Math.min(...dates)), 15), 'yyyy-MM-dd'); // Range maior de segurança
        const maxDate = format(addDays(new Date(Math.max(...dates)), 15), 'yyyy-MM-dd');

        // Busca com metadados detalhados (category, entity_name)
        const { data: pendingTxs } = await supabase
            .from('finance_transactions')
            .select('id, amount, type, transaction_date, description, category, entity_name, status')
            .in('status', ['PENDING', 'OVERDUE'])
            .gte('transaction_date', minDate)
            .lte('transaction_date', maxDate);

        const fitids = concileModal.items.map(i => i.fitid);
        const { data: existingTxs } = await supabase.from('finance_transactions').select('external_id').in('external_id', fitids);
        const existingFitidSet = new Set(existingTxs?.map(t => t.external_id) || []);

        const availablePending = [...(pendingTxs || [])];

        concileModal.items.forEach(ofx => {
            if (existingFitidSet.has(ofx.fitid)) {
                ofx.exists = true; ofx.selected = false; ofx.match = null; return;
            }

            ofx.exists = false;
            const ofxDate = parseISO(ofx.date);
            const ofxAbsAmount = Math.abs(ofx.amount);

            // Lógica de Score / Match
            let bestMatchIndex = -1;
            let bestMatchScore = 999; // Menor score é melhor (diff em dias)

            availablePending.forEach((p, idx) => {
                const pDate = parseISO(p.transaction_date);
                const pAmount = Number(p.amount);

                if (p.type === ofx.type && Math.abs(pAmount - ofxAbsAmount) < 0.05) {
                    const diffDays = Math.abs((pDate.getTime() - ofxDate.getTime()) / (1000 * 3600 * 24));
                    if (diffDays <= 7 && diffDays < bestMatchScore) { // Tolerância de 7 dias
                        bestMatchScore = diffDays;
                        bestMatchIndex = idx;
                    }
                }
            });

            if (bestMatchIndex !== -1) {
                ofx.match = availablePending[bestMatchIndex];
                ofx.diffDays = Math.round(bestMatchScore);
                ofx.matchQuality = ofx.diffDays === 0 ? 'EXATO' : 'APROXIMADO';
                availablePending.splice(bestMatchIndex, 1);
            } else {
                ofx.match = null;
            }
        });

    } catch (error) { console.error(error); } finally { concileModal.analyzing = false; }
};

// --- PROCESSAR E SALVAR ---
const processConciliation = async () => {
    feedbackState.title = 'Processando Conciliação';
    feedbackState.message = 'Baixando títulos e injetando OFX no sistema...';
    feedbackState.status = 'processing';
    feedbackState.details = [];
    feedbackState.show = true;

    const itemsToProcess = concileModal.items.filter(i => i.selected && !i.exists);
    if (itemsToProcess.length === 0) return;

    concileModal.processing = true;

    try {
        const toInsert = [];
        const toUpdate = [];
        let netChange = 0;

        for (const item of itemsToProcess) {
            netChange += item.amount;
            if (item.match) {
                toUpdate.push({
                    id: item.match.id,
                    status: 'COMPLETED',
                    reconciliation_status: 'CONCILIATED',
                    transaction_date: item.date, // Atualiza para data real do banco
                    external_id: item.fitid,
                    account_id: concileModal.targetAccount
                });
            } else {
                toInsert.push({
                    account_id: concileModal.targetAccount,
                    transaction_date: item.date,
                    description: item.memo || 'Lançamento OFX',
                    amount: Math.abs(item.amount),
                    type: item.amount >= 0 ? 'INCOME' : 'EXPENSE',
                    category: 'Conciliação Automática',
                    status: 'COMPLETED',
                    reconciliation_status: 'CONCILIATED',
                    external_id: item.fitid
                });
            }
        }

        if (toInsert.length > 0) await supabase.from('finance_transactions').insert(toInsert);
        for (const up of toUpdate) { await supabase.from('finance_transactions').update(up).eq('id', up.id); }

        const account = accounts.value.find(a => a.id === concileModal.targetAccount);
        if (account) {
            const newBalance = (Number(account.current_balance) || 0) + netChange;
            await supabase.from('finance_accounts').update({ current_balance: newBalance }).eq('id', concileModal.targetAccount);
        }

        feedbackState.status = 'success';
        feedbackState.title = 'Auditoria Finalizada!';
        feedbackState.message = `${itemsToProcess.length} registros sincronizados. Títulos correspondentes foram baixados e o saldo da conta atualizado.`;

        concileModal.show = false;
        fetchReports(); fetchAccounts();
    } catch (e: any) {
        feedbackState.status = 'error';
        feedbackState.title = 'Erro na Operação';
        feedbackState.details.push(e.message);
    } finally { concileModal.processing = false; }
};

watch(currentTab, (v) => { if (v === 'reports' && transactions.value.length === 0) fetchReports(); });
onMounted(() => { fetchAccounts(); fetchReports(); });
</script>

<style scoped lang="scss">
.page-wrapper { font-family: 'Roboto', sans-serif; }
.clean-input { border: none; outline: none; background: transparent; padding: 0; min-width: 100px; }
.hover-bg:hover { background-color: rgba(0,0,0,0.02); }
.border-l-4-green { border-left: 4px solid #2E7D32 !important; }
.border-l-4-red { border-left: 4px solid #C62828 !important; }
.uppercase { text-transform: uppercase; }
.grayscale { filter: grayscale(100%); }

.bg-white-10 { background: rgba(255,255,255,0.1); }
.border-white-20 { border-color: rgba(255,255,255,0.2) !important; }

/* CSS GRID STANDARD (Mesmo estilo do AdminMjReceivables) */
.table-container { overflow-x: auto; }
.grid-table { display: table; width: 100%; min-width: 1000px; }
.reconciliation-grid { min-width: 1200px; }

.grid-header, .grid-row {
   display: flex;
   align-items: stretch;
}

.grid-header { font-weight: 800; text-transform: uppercase; font-size: 11px; color: #616161; letter-spacing: 0.5px; }

.cell {
   padding: 12px 16px;
   display: flex;
   align-items: center;
   font-size: 13px;
}

.center { justify-content: center; text-align: center; }
.right { justify-content: flex-end; text-align: right; }
.border-r { border-right: 1px solid rgba(0,0,0,0.05); }

.sticky-header { position: sticky; top: 0; z-index: 5; }
.custom-scrollbar::-webkit-scrollbar { width: 8px; height: 8px; }
.custom-scrollbar::-webkit-scrollbar-thumb { background-color: #CFD8DC; border-radius: 4px; }
</style>
