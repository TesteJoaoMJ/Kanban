<template>
  <div
    class="receivables-layout font-sans fill-height d-flex flex-column relative overflow-hidden"
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
        class="header-bar px-4 py-3 px-md-6 py-md-4 d-flex flex-column flex-md-row align-md-center justify-space-between flex-shrink-0"
        :class="themeStore.currentMode === 'light' ? 'bg-white border-b border-grey-lighten-2 shadow-sm' : 'bg-glass-header border-bottom-white-05'"
        style="gap: 12px;"
      >
        <div class="d-flex flex-column">
          <div class="breadcrumb text-caption d-none d-md-block">
            <span class="opacity-70">Financeiro</span>
            <span class="mx-2 opacity-50">></span>
            <span class="font-weight-bold text-primary">Hub Bancário & Tesouraria</span>
          </div>
          <div class="d-flex align-center gap-2 mt-1">
             <div class="text-h5 font-weight-black tracking-tight leading-none" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">
                Gestão de Contas
             </div>
             <v-chip size="x-small" color="primary" variant="flat" class="font-weight-bold chip-3d ml-2">V4.0</v-chip>
          </div>
        </div>

        <div class="d-flex align-center overflow-x-auto pb-1 pb-md-0" style="gap: 10px;">
          <v-btn
            color="pink-darken-2"
            variant="flat"
            class="btn-3d px-3 px-md-4 font-weight-bold text-caption text-uppercase letter-spacing-1 flex-shrink-0"
            prepend-icon="mdi-sync"
            height="40"
            @click="coraSyncModal.show = true"
          >
             Sincronizar Cora
          </v-btn>

          <v-btn
            color="success"
            variant="flat"
            class="btn-3d px-3 px-md-4 font-weight-bold text-caption text-uppercase letter-spacing-1 flex-shrink-0"
            prepend-icon="mdi-file-import"
            height="40"
            @click="ofxUploadModal.show = true"
          >
             Conciliar OFX
          </v-btn>

          <v-btn
            color="blue-darken-3"
            variant="flat"
            class="btn-3d px-3 px-md-4 font-weight-bold text-caption text-uppercase letter-spacing-1 flex-shrink-0"
            prepend-icon="mdi-bank-plus"
            height="40"
            @click="openNewAccountModal"
          >
            Nova Conta
          </v-btn>
        </div>
      </div>

      <div class="flex-grow-1 overflow-hidden d-flex flex-column transition-all">
        <div class="fill-height d-flex flex-column">

            <div class="px-4 px-md-6 py-4 flex-shrink-0">
                <v-row class="d-none d-md-flex">
                <v-col cols="12" sm="6" md="4" v-for="(kpi, idx) in kpiList" :key="idx">
                    <v-card class="kpi-card kpi-rect bg-gradient-custom hover-elevate py-3 px-4 cursor-pointer" :class="kpi.gradient" v-ripple elevation="2">
                    <div class="kpi-bg-icon"><v-icon>{{ kpi.icon }}</v-icon></div>
                    <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                        <div class="d-flex align-center" style="gap: 8px;">
                        <v-icon size="18" class="opacity-80">{{ kpi.icon }}</v-icon>
                        <span class="kpi-label text-white">{{ kpi.label }}</span>
                        </div>
                        <div class="kpi-number-group my-1 text-white">
                        <span v-if="kpi.isCurrency" class="text-body-2 font-weight-medium mr-1 opacity-70">R$</span>
                        <span class="kpi-value">{{ kpi.isCurrency ? formatCurrencyValue(kpi.value) : kpi.value }}</span>
                        </div>
                        <div class="kpi-footer mt-1 text-white">{{ kpi.footer }}</div>
                    </div>
                    </v-card>
                </v-col>
                </v-row>
            </div>

            <div class="px-4 px-md-6 pt-0 pb-2 flex-shrink-0">
                <div class="controls-bar d-flex flex-column" :class="themeStore.currentMode === 'light' ? 'controls-light' : 'controls-dark'">
                    <div class="d-flex align-center justify-space-between">
                        <div class="d-flex align-center gap-2">
                            <v-icon color="primary">mdi-safe</v-icon>
                            <span class="text-subtitle-2 font-weight-black text-high-emphasis text-uppercase tracking-wider">Instituições Conectadas</span>
                        </div>
                        <div class="search-wrap d-flex align-center" :class="themeStore.currentMode === 'light' ? 'search-light' : 'search-dark'" style="width: 300px;">
                            <v-icon :color="themeStore.currentMode === 'light' ? 'grey-darken-1' : 'white-70'">mdi-magnify</v-icon>
                            <input v-model="search" type="text" placeholder="Buscar conta ou agência..." class="clean-input flex-grow-1 ml-2 font-weight-bold" />
                        </div>
                    </div>
                </div>
            </div>

            <div class="px-4 px-md-6 pb-6 flex-grow-1 overflow-hidden d-flex flex-column">
                <v-card class="flex-grow-1 d-flex flex-column rounded-xl border-thin overflow-hidden" :class="themeStore.currentMode === 'light' ? 'bg-white shadow-sm' : 'glass-card border-white-05'" :elevation="0">
                    <div class="grid-scroll flex-grow-1 overflow-auto custom-scroll relative">
                        <div class="grid-header sticky-head" :class="themeStore.currentMode === 'light' ? 'grid-surface-light' : 'grid-surface-dark'" style="grid-template-columns: 80px minmax(220px, 2fr) minmax(100px, 1fr) minmax(140px, 1.2fr) 140px 100px 200px;">
                        <div class="cell center header-text">Status</div>
                        <div class="cell header-text">Instituição Bancária</div>
                        <div class="cell center header-text">Agência</div>
                        <div class="cell center header-text">Conta c/ Dígito</div>
                        <div class="cell center header-text">Saldo Atual</div>
                        <div class="cell center header-text">Situação</div>
                        <div class="cell center header-text">Ações Rápidas</div>
                        </div>

                        <div v-if="loading" class="d-flex flex-column justify-center align-center h-100 py-10 min-w-full">
                        <v-progress-circular indeterminate color="primary" size="32" width="3"></v-progress-circular>
                        </div>
                        <div v-else-if="filteredAccounts.length === 0" class="d-flex flex-column justify-center align-center h-100 opacity-60 gap-2 py-10 min-w-full">
                        <v-icon size="48" color="grey-lighten-1">mdi-bank-off</v-icon>
                        <span class="text-body-2 font-weight-medium text-grey">Nenhuma conta encontrada.</span>
                        </div>

                        <div v-else v-for="(item, index) in filteredAccounts" :key="item.id" class="grid-row hover-bg transition-all" :class="[themeStore.currentMode === 'light' ? 'grid-row-light' : 'grid-row-dark', zebraClass(index)]" style="grid-template-columns: 80px minmax(220px, 2fr) minmax(100px, 1fr) minmax(140px, 1.2fr) 140px 100px 200px;">
                            <div class="cell center">
                                <v-icon :color="item.is_active ? 'success' : 'grey'" size="28">{{ item.is_active ? 'mdi-check-circle' : 'mdi-minus-circle' }}</v-icon>
                            </div>
                            <div class="cell d-flex align-center gap-3">
                                <div class="rounded-lg d-flex align-center justify-center border border-opacity-10 shadow-sm" :class="getBankStyles(item.bank_name).bg" style="width: 40px; height: 40px; flex-shrink: 0;">
                                <v-icon size="20" :class="getBankStyles(item.bank_name).text">mdi-bank</v-icon>
                                </div>
                                <div class="d-flex flex-column justify-center overflow-hidden">
                                <span class="text-subtitle-2 font-weight-black text-truncate">{{ item.name }}</span>
                                <span class="text-caption font-weight-medium opacity-70">{{ item.bank_name }}</span>
                                </div>
                            </div>
                            <div class="cell center">
                                <span class="list-text-11 font-mono font-weight-bold text-medium-emphasis">{{ item.agency || '---' }}</span>
                            </div>
                            <div class="cell center">
                                <span class="list-text-11 font-mono font-weight-bold text-medium-emphasis">{{ item.account_number || '---' }}</span>
                            </div>
                            <div class="cell center">
                                <span class="list-text-11 font-mono font-weight-black" :class="item.current_balance >= 0 ? 'text-success' : 'text-error'">
                                {{ formatCurrency(item.current_balance) }}
                                </span>
                            </div>
                            <div class="cell center">
                                <span class="solid-chip chip-3d" :class="item.is_active ? 'chip-success' : 'chip-warn'">{{ item.is_active ? 'ATIVA' : 'INATIVA' }}</span>
                            </div>
                            <div class="cell center">
                                <div class="actions-inline">
                                    <v-tooltip text="Ver Extrato" location="top"><template v-slot:activator="{ props }"><v-btn v-bind="props" icon size="small" class="action-btn btn-3d bg-indigo-darken-2" @click.stop="openStatementModal(item)" variant="flat"><v-icon size="16">mdi-format-list-checks</v-icon></v-btn></template></v-tooltip>
                                    <v-tooltip text="Nova Transferência" location="top"><template v-slot:activator="{ props }"><v-btn v-bind="props" icon size="small" class="action-btn btn-3d bg-teal-darken-3" @click.stop="openTransferModal(item)" variant="flat"><v-icon size="16">mdi-swap-horizontal</v-icon></v-btn></template></v-tooltip>
                                    <v-divider vertical class="mx-1"></v-divider>
                                    <v-btn icon size="small" class="action-btn btn-3d action-edit" @click.stop="openEditModal(item)" title="Editar Configurações" variant="flat"><v-icon size="16">mdi-pencil</v-icon></v-btn>
                                    <v-btn icon size="small" class="action-btn btn-3d action-del" @click.stop="requirePinForAction('delete_account', item)" title="Excluir Conta" variant="flat"><v-icon size="16">mdi-trash-can-outline</v-icon></v-btn>
                                </div>
                            </div>
                        </div>
                    </div>
                </v-card>
            </div>
        </div>
      </div>
    </div>

    <v-dialog v-model="editModal.show" max-width="550" persistent>
        <v-card class="rounded-xl border-thin overflow-hidden" :class="themeStore.currentMode === 'light' ? 'bg-white shadow-lg' : 'bg-surface border-white-10'">

            <div class="px-6 py-5 bg-blue-grey-darken-4 text-white d-flex justify-space-between align-center shadow-sm relative overflow-hidden">
                <div class="position-absolute opacity-10" style="top: -20px; right: -20px;"><v-icon size="120">mdi-bank-outline</v-icon></div>
                <div class="d-flex align-center gap-4 relative z-10">
                    <div class="bg-white-20 pa-2 rounded-lg border border-white-20 backdrop-blur">
                        <v-icon size="28" color="white">{{ editModal.form.id ? 'mdi-bank-transfer' : 'mdi-bank-plus' }}</v-icon>
                    </div>
                    <div>
                        <h3 class="text-h6 font-weight-black lh-1 letter-spacing-tight">{{ editModal.form.id ? 'Configurações da Conta' : 'Nova Instituição Bancária' }}</h3>
                        <div class="text-caption font-weight-medium text-blue-grey-lighten-2 mt-1 d-flex align-center gap-1">
                            <v-icon size="12">mdi-shield-check</v-icon> Ambiente Seguro e Auditado
                        </div>
                    </div>
                </div>
                <v-btn icon="mdi-close" variant="text" size="small" color="white" class="relative z-10" @click="editModal.show = false"></v-btn>
            </div>

            <div class="pa-6 custom-scroll overflow-y-auto" style="max-height: 70vh;">
                <v-form @submit.prevent="saveAccount">
                    <div class="mb-4">
                        <div class="text-caption font-weight-black text-uppercase text-primary mb-3 ls-1 d-flex align-center gap-2">
                            <v-icon size="16">mdi-card-account-details-outline</v-icon> Identificação Principal
                        </div>
                        <v-text-field v-model="editModal.form.name" label="Nome Interno da Conta *" placeholder="Ex: Conta Principal Nubank" variant="outlined" density="comfortable" color="primary" bg-color="background" class="font-weight-bold mb-3" hide-details="auto"></v-text-field>

                        <v-combobox v-model="editModal.form.bank_name" :items="bankOptions" label="Instituição Bancária *" placeholder="Selecione ou digite..." variant="outlined" density="comfortable" color="primary" bg-color="background" class="font-weight-bold" hide-details="auto" prepend-inner-icon="mdi-bank"></v-combobox>
                    </div>

                    <v-divider class="my-4 opacity-20"></v-divider>

                    <div class="mb-4">
                        <div class="text-caption font-weight-black text-uppercase text-primary mb-3 ls-1 d-flex align-center gap-2">
                            <v-icon size="16">mdi-numeric</v-icon> Dados Bancários e Saldo
                        </div>
                        <v-row dense class="mb-2">
                            <v-col cols="12" md="5">
                                <v-text-field v-model="editModal.form.agency" label="Agência" placeholder="Ex: 0001" variant="outlined" density="comfortable" color="primary" bg-color="background" hide-details="auto"></v-text-field>
                            </v-col>
                            <v-col cols="12" md="7">
                                <v-text-field v-model="editModal.form.account_number" label="Conta c/ Dígito" placeholder="Ex: 123456-7" variant="outlined" density="comfortable" color="primary" bg-color="background" hide-details="auto"></v-text-field>
                            </v-col>
                        </v-row>

                        <v-text-field v-model="editModal.form.current_balance" type="number" step="0.01" :disabled="!canEditBalance" label="Saldo Atual (R$)" prefix="R$" variant="outlined" density="comfortable" color="primary" bg-color="primary-lighten-5" class="font-weight-black font-mono text-primary-darken-2" hide-details="auto" :hint="!canEditBalance ? 'Apenas SuperAdmins podem alterar o saldo base diretamente.' : ''" persistent-hint></v-text-field>
                    </div>

                    <v-divider class="my-4 opacity-20"></v-divider>

                    <div class="bg-grey-lighten-4 pa-4 rounded-lg border">
                        <v-switch v-model="editModal.form.is_active" label="Conta Operacional (Ativa)" color="success" density="compact" inset hide-details class="font-weight-bold text-body-2"></v-switch>
                        <p class="text-[11px] text-medium-emphasis ml-10 mt-n1">Contas inativas não aparecem em novas movimentações ou DRE.</p>
                    </div>
                </v-form>
            </div>

            <div class="pa-4 border-t d-flex justify-space-between align-center bg-grey-lighten-5">
                <v-btn variant="text" color="medium-emphasis" class="font-weight-bold" @click="editModal.show = false">Cancelar</v-btn>
                <v-btn color="blue-darken-3" variant="flat" class="btn-3d px-6 font-weight-black text-none" @click="saveAccount" :loading="editModal.loading">
                    <v-icon start size="20">mdi-check-shield</v-icon> {{ editModal.form.id ? 'Atualizar Registro' : 'Registrar Conta' }}
                </v-btn>
            </div>
        </v-card>
    </v-dialog>


    <v-dialog v-model="transferModal.show" max-width="600" persistent>
        <v-card class="rounded-xl overflow-hidden border-thin" :class="themeStore.currentMode === 'light' ? 'bg-white shadow-xl' : 'bg-surface border-white-10'">
            <div class="px-6 py-5 bg-teal-darken-4 text-white d-flex justify-space-between align-center shadow-sm relative overflow-hidden">
                <div class="position-absolute opacity-10" style="bottom: -20px; right: -10px; transform: rotate(-15deg);"><v-icon size="140">mdi-swap-horizontal</v-icon></div>
                <div class="d-flex align-center gap-4 relative z-10">
                    <div class="bg-white-20 pa-2 rounded-lg border border-white-20 backdrop-blur">
                        <v-icon size="28" color="white">mdi-swap-horizontal-bold</v-icon>
                    </div>
                    <div>
                        <h3 class="text-h6 font-weight-black lh-1 letter-spacing-tight">Transferência de Custódia</h3>
                        <div class="text-caption font-weight-medium text-teal-lighten-4 mt-1 d-flex align-center gap-1">
                            <v-icon size="12">mdi-lock-check</v-icon> Operação Criptografada e Auditável
                        </div>
                    </div>
                </div>
                <v-btn icon="mdi-close" variant="text" size="small" color="white" class="relative z-10" @click="transferModal.show = false"></v-btn>
            </div>

            <div class="pa-6 custom-scroll overflow-y-auto" style="max-height: 70vh;">
                <v-form @submit.prevent="requirePinForAction('transfer')" id="transferForm">

                    <div class="transfer-flow-container mb-6 position-relative border rounded-xl pa-1" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-black-20 border-white-10'">
                        <div class="pa-4 rounded-lg bg-white shadow-sm border mb-2 d-flex justify-space-between align-center">
                            <div class="d-flex align-center gap-3">
                                <div class="rounded-circle pa-2 border shadow-xs" :class="getBankStyles(transferModal.sourceAccount?.bank_name).bg"><v-icon size="20" :class="getBankStyles(transferModal.sourceAccount?.bank_name).text">mdi-bank-minus</v-icon></div>
                                <div>
                                    <div class="text-[10px] font-weight-black text-uppercase text-medium-emphasis mb-1">Conta de Origem</div>
                                    <div class="text-subtitle-2 font-weight-black lh-1">{{ transferModal.sourceAccount?.name }}</div>
                                </div>
                            </div>
                            <div class="text-right">
                                <div class="text-[10px] font-weight-bold text-medium-emphasis mb-1">Saldo Disponível</div>
                                <div class="text-body-2 font-mono font-weight-black" :class="transferModal.sourceAccount?.current_balance < 0 ? 'text-error' : 'text-success'">{{ formatCurrency(transferModal.sourceAccount?.current_balance) }}</div>
                            </div>
                        </div>

                        <div class="position-absolute z-10 translate-middle-xy" style="left: 50%; top: 50%;">
                            <div class="bg-teal-darken-3 rounded-circle pa-1 border-4 shadow-sm d-flex align-center justify-center" :class="themeStore.currentMode === 'light' ? 'border-grey-lighten-5' : 'border-grey-darken-4'" style="width: 32px; height: 32px;">
                                <v-icon color="white" size="16">mdi-arrow-down-thick</v-icon>
                            </div>
                        </div>

                        <div class="pa-4 rounded-lg border transition-all" :class="transferModal.form.to_account_id ? 'shadow-sm border-teal-lighten-2 bg-teal-lighten-5' : 'border-dashed bg-white'">
                            <div class="text-[10px] font-weight-black text-uppercase text-teal-darken-3 mb-2 d-flex align-center gap-1">
                                <v-icon size="12" color="teal-darken-3">mdi-bank-plus</v-icon> Conta de Destino *
                            </div>
                            <v-select v-model="transferModal.form.to_account_id" :items="availableDestinationAccounts" item-title="name" item-value="id" variant="outlined" density="compact" color="teal-darken-3" placeholder="Selecione a conta recebedora..." bg-color="white" class="font-weight-bold text-subtitle-2" hide-details="auto">
                                <template v-slot:item="{ props, item }">
                                    <v-list-item v-bind="props" :subtitle="item.raw.bank_name">
                                        <template v-slot:prepend>
                                            <v-avatar size="28" class="mr-3" :class="getBankStyles(item.raw.bank_name).bg"><v-icon size="14" :class="getBankStyles(item.raw.bank_name).text">mdi-bank</v-icon></v-avatar>
                                        </template>
                                    </v-list-item>
                                </template>
                            </v-select>
                        </div>
                    </div>

                    <div class="pa-5 rounded-xl border mb-6 shadow-sm" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-surface'">
                        <div class="text-caption font-weight-black text-uppercase text-grey-darken-2 mb-4 ls-1 d-flex align-center gap-2">
                            <v-icon size="16">mdi-cash-fast</v-icon> Detalhes da Transferência
                        </div>
                        <v-row dense>
                            <v-col cols="12" sm="6">
                                <v-text-field v-model="transferModal.form.amount" type="number" step="0.01" label="Valor a Transferir *" prefix="R$" variant="outlined" density="comfortable" color="teal-darken-3" class="font-weight-black font-mono text-teal-darken-4 input-lg" bg-color="teal-lighten-5" hide-details="auto"></v-text-field>
                            </v-col>
                            <v-col cols="12" sm="6">
                                <v-text-field v-model="transferModal.form.date" type="date" label="Data de Efetivação *" variant="outlined" density="comfortable" color="teal-darken-3" bg-color="background" class="font-weight-bold font-mono" hide-details="auto"></v-text-field>
                            </v-col>
                        </v-row>
                    </div>

                    <div class="pa-5 rounded-xl border border-red-lighten-4 bg-red-lighten-5">
                        <div class="d-flex align-start gap-3">
                            <v-icon color="red-darken-3" class="mt-1 pulse-icon">mdi-shield-alert</v-icon>
                            <div class="flex-grow-1">
                                <label class="text-caption font-weight-black text-uppercase text-red-darken-3 mb-2 d-block ls-1">Motivo / Justificativa (Auditoria) *</label>
                                <v-textarea v-model="transferModal.form.reason" variant="outlined" density="comfortable" color="red-darken-3" rows="2" placeholder="Ex: Transferência para cobrir folha de pagamento..." bg-color="white" hide-details="auto" class="font-weight-medium text-body-2"></v-textarea>
                            </div>
                        </div>
                    </div>
                </v-form>
            </div>

            <div class="pa-4 border-t d-flex justify-space-between align-center bg-grey-lighten-5">
                <v-btn variant="text" color="medium-emphasis" class="font-weight-bold" @click="transferModal.show = false">Cancelar Operação</v-btn>
                <v-btn color="teal-darken-3" variant="flat" class="btn-3d px-6 font-weight-black text-none" @click="requirePinForAction('transfer')" :loading="transferModal.loading" :disabled="!isTransferValid" size="large">
                    <v-icon start size="20">mdi-fingerprint</v-icon> Autenticar Transferência
                </v-btn>
            </div>
        </v-card>
    </v-dialog>


<v-dialog v-model="pinModal.show" max-width="400" persistent>
        <v-card class="rounded-xl border-thin shadow-2xl overflow-hidden" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-surface'">
            <div class="px-6 py-4 bg-grey-darken-4 text-white d-flex align-center justify-space-between border-b border-white-10">
                <div class="d-flex align-center gap-3">
                    <v-icon size="24" color="red-accent-2">mdi-shield-lock</v-icon>
                    <span class="text-subtitle-1 font-weight-black ls-1">AUTENTICAÇÃO EXIGIDA</span>
                </div>
                <v-btn icon="mdi-close" variant="text" size="small" color="white" @click="pinModal.show = false"></v-btn>
            </div>

            <div class="pa-8 text-center bg-pattern-lock position-relative overflow-hidden">
                <!-- Ícone de fundo com opacidade forçada, z-index 0 e sem bloquear cliques -->
                <div class="position-absolute d-flex align-center justify-center" style="top: 0; left: 0; right: 0; bottom: 0; opacity: 0.08; z-index: 0; pointer-events: none;">
                    <v-icon size="200" color="red-darken-3">mdi-fingerprint</v-icon>
                </div>

                <!-- Conteúdo principal com z-index superior para ficar à frente da digital -->
                <div class="position-relative" style="z-index: 1;">
                    <v-avatar size="64" color="red-lighten-5" class="mb-4 border border-red-lighten-3 shadow-sm">
                        <v-icon size="32" color="red-darken-3">mdi-dialpad</v-icon>
                    </v-avatar>

                    <h4 class="text-h6 font-weight-black mb-1">PIN de Segurança</h4>
                    <p class="text-caption font-weight-medium text-medium-emphasis mb-6 px-4">
                        Esta é uma ação crítica ({{ pinModal.actionType === 'transfer' ? 'Transferência de Saldo' : 'Exclusão de Conta' }}). Digite seu PIN de 4 dígitos para assinar eletronicamente.
                    </p>

                    <v-otp-input
                        v-model="pinModal.pin"
                        length="4"
                        type="password"
                        color="red-darken-3"
                        class="justify-center mb-2 mx-auto secure-otp"
                        style="max-width: 250px;"
                        @finish="confirmPin"
                    ></v-otp-input>
                </div>
            </div>

            <div class="pa-4 d-flex justify-center border-t" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-4' : 'bg-background'">
                <v-btn color="red-darken-3" variant="flat" size="large" class="btn-3d px-10 font-weight-black text-none w-100" :loading="pinModal.loading" @click="confirmPin" :disabled="pinModal.pin.length < 4">
                    <v-icon start>mdi-check-decagram</v-icon> Validar e Confirmar
                </v-btn>
            </div>
        </v-card>
    </v-dialog>

    <v-dialog v-model="coraSyncModal.show" max-width="450">
        <v-card class="rounded-xl border-thin" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-surface'">
            <v-card-title class="bg-pink-lighten-5 text-pink-darken-3 font-weight-bold d-flex align-center gap-2 pa-4">
                <v-icon>mdi-bank-transfer-in</v-icon> Sincronizar Banco Cora
            </v-card-title>
            <v-card-text class="pa-6">
                <div class="text-body-2 mb-4 text-medium-emphasis">Selecione a empresa e o período para buscar as movimentações diretamente do extrato Cora via API para conciliação.</div>

                <v-alert type="info" variant="tonal" color="pink-darken-2" density="compact" class="mb-4 text-caption font-weight-bold">
                    O sistema buscará as transações fatiadas automaticamente para evitar Timeout (Erro 504).
                </v-alert>

                <label class="text-caption font-weight-bold text-pink-darken-3 mb-1 d-block">Empresa a Sincronizar *</label>
                <v-select v-model="coraSyncModal.clientId" :items="coraIntegrations" item-title="name" item-value="clientId" variant="outlined" density="comfortable" class="mb-4" color="pink-darken-3" hide-details></v-select>

                <label class="text-caption font-weight-bold text-pink-darken-3 mb-1 d-block">Data Inicial</label>
                <v-text-field type="date" v-model="coraSyncModal.startDate" variant="outlined" density="comfortable" class="mb-4" color="pink-darken-3" hide-details></v-text-field>

                <label class="text-caption font-weight-bold text-pink-darken-3 mb-1 d-block">Data Final</label>
                <v-text-field type="date" v-model="coraSyncModal.endDate" variant="outlined" density="comfortable" color="pink-darken-3" hide-details></v-text-field>
            </v-card-text>
            <v-card-actions class="pa-4 border-t justify-end gap-2" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5' : 'bg-background'">
                <v-btn variant="text" @click="coraSyncModal.show = false" :disabled="coraSyncModal.loading" class="font-weight-bold text-none">Cancelar</v-btn>
                <v-btn color="pink-darken-3" variant="flat" class="font-weight-bold px-6 text-none elevation-1 btn-3d" @click="fetchCoraStatementForConciliation" :loading="coraSyncModal.loading">
                    Buscar Transações
                </v-btn>
            </v-card-actions>
        </v-card>
    </v-dialog>

    <v-dialog v-model="ofxUploadModal.show" max-width="500">
        <v-card class="rounded-xl border-thin text-center pa-6" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-surface'">
            <div class="d-flex justify-space-between align-center mb-6">
                <h3 class="text-h6 font-weight-black" :class="themeStore.currentMode === 'light' ? 'text-black' : 'text-white'">Importar Arquivo OFX</h3>
                <v-btn icon="mdi-close" variant="text" size="small" @click="ofxUploadModal.show = false"></v-btn>
            </div>

            <div
                class="dropzone border-dashed border-opacity-50 rounded-lg pa-10 d-flex flex-column align-center justify-center cursor-pointer transition-all"
                :class="[themeStore.currentMode === 'light' ? 'border-primary bg-grey-lighten-5 hover:bg-grey-lighten-4' : 'border-success bg-black-20 hover:bg-white-10', ofxUploadModal.isDragging ? 'bg-primary-lighten-4 border-primary-darken-1' : '']"
                @dragover.prevent="ofxUploadModal.isDragging = true"
                @dragleave.prevent="ofxUploadModal.isDragging = false"
                @drop.prevent="handleOfxDrop"
                @click="$refs.ofxFileInputModal.click()"
            >
                <v-icon size="64" :color="themeStore.currentMode === 'light' ? 'primary' : 'success'" class="mb-4">mdi-cloud-upload</v-icon>
                <div class="text-subtitle-1 font-weight-bold" :class="themeStore.currentMode === 'light' ? 'text-primary' : 'text-success'">Arraste o arquivo .OFX aqui</div>
                <div class="text-caption text-medium-emphasis mt-1">Ou clique para procurar no seu computador</div>
                <input type="file" ref="ofxFileInputModal" class="d-none" accept=".ofx,.xml" @change="handleOfxFileSelect" />
            </div>
        </v-card>
    </v-dialog>

    <v-dialog v-model="statementModal.show" max-width="1200" scrollable persistent transition="dialog-bottom-transition" scrim="black opacity-80">
        <v-card class="rounded-xl overflow-hidden d-flex flex-column h-100 bg-surface">
            <div class="px-6 py-4 flex-shrink-0 d-flex align-center justify-space-between shadow-sm z-10" :class="getBankStyles(statementModal.account?.bank_name).bg">
                <div class="d-flex align-center gap-4">
                    <div class="bg-white pa-2 rounded-circle shadow-sm border"><v-icon size="32" :class="getBankStyles(statementModal.account?.bank_name).text">mdi-bank</v-icon></div>
                    <div>
                        <h3 class="text-h6 font-weight-black lh-1" :class="getBankStyles(statementModal.account?.bank_name).text">Extrato: {{ statementModal.account?.name }}</h3>
                        <div class="text-caption font-weight-bold opacity-80" :class="getBankStyles(statementModal.account?.bank_name).text">Ag: {{ statementModal.account?.agency || '--' }} | CC: {{ statementModal.account?.account_number || '--' }}</div>
                    </div>
                </div>
                <div class="d-flex align-center gap-4">
                    <div class="text-right">
                        <div class="text-caption font-weight-bold opacity-80" :class="getBankStyles(statementModal.account?.bank_name).text">Saldo em Conta</div>
                        <div class="text-h5 font-mono font-weight-black" :class="getBankStyles(statementModal.account?.bank_name).text">{{ formatCurrency(statementModal.account?.current_balance) }}</div>
                    </div>
                    <v-btn icon="mdi-close" variant="text" :class="getBankStyles(statementModal.account?.bank_name).text" @click="statementModal.show = false"></v-btn>
                </div>
            </div>

            <div v-if="statementModal.isCora" class="px-6 py-3 bg-pink-darken-3 text-white flex-shrink-0 d-flex align-center justify-space-between flex-wrap gap-3">
                <div class="d-flex align-center gap-3">
                    <v-icon size="24" color="white" class="pulse-icon">mdi-api</v-icon>
                    <div>
                        <div class="text-subtitle-2 font-weight-bold">Integração Direta Cora Detectada</div>
                        <div class="text-[10px] opacity-80">Sincronize o extrato em tempo real via OpenBanking Cora API.</div>
                    </div>
                </div>
                <div class="d-flex align-center gap-3">
                    <v-select v-model="statementModal.coraClientId" :items="coraIntegrations" item-title="name" item-value="clientId" variant="solo-filled" density="compact" hide-details class="font-weight-bold text-pink-darken-4 bg-white rounded" style="width: 180px;" @update:model-value="fetchAccountStatement"></v-select>
                    <v-btn color="white" variant="flat" size="small" class="text-pink-darken-3 font-weight-bold btn-3d" prepend-icon="mdi-sync" @click="syncCoraApi" :loading="statementModal.syncingCora">
                        Atualizar Extrato
                    </v-btn>
                </div>
            </div>

            <div class="px-6 py-3 border-b flex-shrink-0 d-flex align-center flex-wrap gap-4" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-background'">
                <div class="d-flex align-center bg-grey-lighten-4 rounded px-1" style="height: 36px; border: 1px solid #e0e0e0;">
                    <button v-for="opt in groupingOptions" :key="opt.value" class="px-3 py-1 text-caption font-weight-bold text-uppercase transition-all rounded-sm" :class="statementModal.groupingMode === opt.value ? 'bg-white elevation-1 text-primary' : 'text-grey-darken-1 opacity-70'" @click="statementModal.groupingMode = opt.value">
                        {{ opt.label }}
                    </button>
                </div>

                <v-menu location="bottom start">
                    <template v-slot:activator="{ props }">
                        <v-btn v-bind="props" variant="outlined" class="btn-rect bg-white" height="36" prepend-icon="mdi-calendar-cursor" color="grey-darken-3">
                            Período Rápido <v-icon end size="small">mdi-chevron-down</v-icon>
                        </v-btn>
                    </template>
                    <v-list density="compact" nav>
                        <v-list-item v-for="p in quickPeriodOptions" :key="p.value" @click="applyStatementPreset(p.value)"><v-list-item-title class="text-caption font-weight-bold">{{ p.label }}</v-list-item-title></v-list-item>
                    </v-list>
                </v-menu>

                <div class="filter-group d-flex align-center border rounded-lg px-2 py-1 bg-white shadow-xs" style="height: 36px;">
                    <v-icon size="16" class="mx-2 opacity-50">mdi-calendar</v-icon>
                    <input type="date" v-model="statementModal.filters.startDate" class="clean-input text-caption font-mono font-weight-bold text-black" @change="fetchAccountStatement" />
                    <span class="mx-2 opacity-50 text-caption">até</span>
                    <input type="date" v-model="statementModal.filters.endDate" class="clean-input text-caption font-mono font-weight-bold text-black" @change="fetchAccountStatement" />
                </div>

                <v-text-field v-model="statementModal.filters.search" variant="outlined" density="compact" placeholder="Buscar no extrato..." prepend-inner-icon="mdi-magnify" hide-details class="shadow-xs bg-white" style="max-width: 250px;"></v-text-field>
                <v-spacer></v-spacer>
            </div>

            <div class="flex-grow-1 overflow-y-auto custom-scroll px-6 py-4" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-4' : 'bg-transparent'">
                <div v-if="statementModal.loading" class="d-flex justify-center py-12"><v-progress-circular indeterminate color="primary"></v-progress-circular></div>
                <div v-else-if="groupedStatementData.length === 0" class="pa-12 text-center text-medium-emphasis">
                    <v-icon size="64" color="grey-lighten-2">mdi-text-box-search-outline</v-icon>
                    <div class="text-subtitle-1 font-weight-bold mt-2">Nenhuma movimentação encontrada.</div>
                </div>

                <template v-else>
                    <div v-for="(group, gIdx) in groupedStatementData" :key="gIdx" class="group-container mb-8">
                        <div class="group-header d-flex flex-column flex-sm-row align-start align-sm-center justify-space-between mb-2 px-1">
                            <div class="d-flex align-center gap-3 mb-2 mb-sm-0">
                                <div class="date-badge bg-grey-darken-4 text-white font-weight-black px-3 py-1 rounded elevation-2 text-uppercase text-caption ls-1">
                                    {{ group.label }}
                                </div>
                                <span class="text-caption font-weight-bold text-grey-darken-1">{{ group.items.length }} lançamentos</span>
                            </div>
                            <div class="d-flex align-center gap-3">
                                <div class="d-flex align-center px-3 py-1 bg-green-lighten-5 text-green-darken-3 rounded border border-green-lighten-4">
                                    <v-icon start size="small" color="green-darken-2">mdi-arrow-up</v-icon>
                                    <span class="text-caption font-mono font-weight-black">{{ formatCurrency(group.summary.in) }}</span>
                                </div>
                                <div class="d-flex align-center px-3 py-1 bg-red-lighten-5 text-red-darken-3 rounded border border-red-lighten-4">
                                    <v-icon start size="small" color="red-darken-2">mdi-arrow-down</v-icon>
                                    <span class="text-caption font-mono font-weight-black">{{ formatCurrency(group.summary.out) }}</span>
                                </div>
                            </div>
                        </div>

                        <v-card class="rounded-lg border-thin overflow-hidden shadow-sm bg-white" elevation="0">
                            <div class="grid-statement-layout">
                                <div class="grid-header-row bg-grey-lighten-4 border-b text-grey-darken-2" style="display: grid; grid-template-columns: 80px 100px minmax(250px, 2fr) minmax(200px, 1fr) 140px 140px 60px;">
                                    <div class="cell header-text center">Hora</div>
                                    <div class="cell header-text center">Tipo</div>
                                    <div class="cell header-text">Descrição / Motivo</div>
                                    <div class="cell header-text">Contraparte</div>
                                    <div class="cell header-text center">Doc. (CPF/CNPJ)</div>
                                    <div class="cell header-text right pr-6">Valor (R$)</div>
                                    <div class="cell header-text center">Info</div>
                                </div>

                                <div v-for="(item, i) in group.items" :key="item.id" class="grid-body-row transition-colors" :class="getRowColorClass(item.type)" style="display: grid; grid-template-columns: 80px 100px minmax(250px, 2fr) minmax(200px, 1fr) 140px 140px 60px;">
                                    <div class="cell center"><span class="font-mono text-caption font-weight-bold opacity-80 text-black">{{ formatTime(item.date) }}</span></div>
                                    <div class="cell center">
                                        <v-chip :color="item.type === 'CREDIT' ? 'green-darken-2' : 'red-darken-2'" size="x-small" variant="flat" class="font-weight-black px-2 uppercase chip-3d">
                                            {{ item.type === 'CREDIT' ? 'ENTRADA' : 'SAÍDA' }}
                                        </v-chip>
                                    </div>
                                    <div class="cell">
                                        <div class="d-flex flex-column" style="max-width: 280px;">
                                            <span class="text-caption font-weight-bold text-truncate text-black" :title="item.description">{{ item.description }}</span>
                                            <span class="text-[10px] text-grey-darken-2 text-truncate">{{ item.category }}</span>
                                        </div>
                                    </div>
                                    <div class="cell">
                                        <span class="text-caption font-weight-medium text-grey-darken-3 text-truncate" style="max-width: 200px;" :title="item.counterPartyName">{{ item.counterPartyName }}</span>
                                    </div>
                                    <div class="cell center">
                                        <span class="font-mono text-[11px] text-grey-darken-2 bg-white-50 px-1 rounded">{{ formatDocument(item.counterPartyDoc) }}</span>
                                    </div>
                                    <div class="cell right pr-6">
                                        <span class="font-mono font-weight-black text-body-2" :class="item.type === 'CREDIT' ? 'text-green-darken-3' : 'text-red-darken-3'">
                                            {{ item.type === 'CREDIT' ? '+' : '-' }} {{ formatCurrencyValue(item.amount) }}
                                        </span>
                                    </div>
                                    <div class="cell center">
                                        <v-tooltip location="left">
                                            <template v-slot:activator="{ props }">
                                                <v-icon v-bind="props" size="20" :color="item.isConciliated ? 'success' : 'grey'" class="opacity-80">
                                                    {{ item.isConciliated ? 'mdi-shield-check' : (item.isCora ? 'mdi-api' : 'mdi-clock-outline') }}
                                                </v-icon>
                                            </template>
                                            <span>{{ item.isConciliated ? 'Transação Conciliada via Banco' : (item.isCora ? 'Lido da API Cora' : 'Registro Interno Padrão') }}</span>
                                        </v-tooltip>
                                    </div>
                                </div>
                            </div>
                        </v-card>
                    </div>
                </template>
            </div>
        </v-card>
    </v-dialog>

    <v-dialog v-model="concileModal.show" fullscreen transition="dialog-bottom-transition" persistent>
        <v-card class="d-flex flex-column h-100 overflow-hidden font-sans" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-4' : 'bg-grey-darken-4 text-white'">

            <v-toolbar color="primary" elevation="2" height="70" class="flex-shrink-0">
                <div class="px-6 d-flex align-center w-100">
                    <v-icon size="32" color="white" class="mr-4">mdi-shield-sync</v-icon>
                    <div>
                        <v-toolbar-title class="text-h6 font-weight-black text-white">Conciliação Inteligente Bancária</v-toolbar-title>
                        <div class="text-caption font-weight-bold text-white-70 d-flex align-center gap-2">
                          <v-icon size="12" color="green-accent-3" class="pulse-icon">mdi-circle</v-icon> Cruzamento de Dados Ativo
                        </div>
                    </div>
                    <v-spacer></v-spacer>

                    <div class="d-flex align-center bg-white-20 rounded-lg px-4 py-1 mr-6 shadow-sm border border-white-20">
                        <div class="text-center mr-4 pr-4 border-e border-white-20">
                            <div class="text-[10px] text-uppercase font-weight-bold text-white-70">Lidos</div>
                            <div class="text-subtitle-1 font-weight-black text-white lh-1">{{ concileModal.items.length }}</div>
                        </div>
                        <div class="text-center mr-4 pr-4 border-e border-white-20">
                            <div class="text-[10px] text-uppercase font-weight-bold text-green-accent-2">Entradas</div>
                            <div class="text-subtitle-1 font-weight-black text-green-accent-2 lh-1">{{ formatCurrency(concileModal.kpis.inflow) }}</div>
                        </div>
                        <div class="text-center">
                            <div class="text-[10px] text-uppercase font-weight-bold text-red-lighten-3">Saídas</div>
                            <div class="text-subtitle-1 font-weight-black text-red-lighten-3 lh-1">{{ formatCurrency(concileModal.kpis.outflow) }}</div>
                        </div>
                    </div>

                    <v-btn variant="text" color="white" class="text-none mr-2 font-weight-bold" @click="concileModal.show = false" :disabled="concileModal.processing">Cancelar</v-btn>
                    <v-btn color="success" variant="flat" class="btn-3d text-none font-weight-black px-6" @click="processConciliation" :loading="concileModal.processing" :disabled="concileModal.analyzing || !concileModal.targetAccount">
                       <v-icon start>mdi-check-all</v-icon> Efetivar Transações
                    </v-btn>
                </div>
            </v-toolbar>

            <div v-if="concileModal.analyzing" class="flex-grow-1 d-flex flex-column align-center justify-center relative bg-grey-lighten-4">
                <v-card class="pa-8 d-flex flex-column align-center rounded-xl shadow-lg border-thin bg-white" style="width: 450px;">
                    <v-icon size="64" color="primary" class="mb-6 pulse-icon">mdi-brain</v-icon>
                    <h2 class="text-h6 font-weight-bold mb-2 text-center text-primary">{{ concileModal.loadingStatus.title }}</h2>
                    <p class="text-caption text-medium-emphasis mb-6 text-center">{{ concileModal.loadingStatus.subtitle }}</p>
                    <div class="w-100">
                      <v-progress-linear :model-value="concileModal.loadingProgress" color="primary" height="8" rounded striped></v-progress-linear>
                    </div>
                </v-card>
            </div>

            <div v-else class="flex-grow-1 d-flex flex-column overflow-hidden">
                <div class="bg-white px-6 py-3 border-b shadow-sm flex-shrink-0 d-flex flex-wrap align-center justify-space-between gap-4" style="z-index: 10;" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-surface'">

                    <div class="d-flex align-center gap-3">
                        <div class="bg-primary-lighten-5 pa-2 rounded-lg border border-primary-lighten-4"><v-icon color="primary">mdi-bank-transfer-in</v-icon></div>
                        <div style="width: 280px;">
                            <label class="text-[10px] font-weight-black text-uppercase text-primary mb-1 d-block">Conta de Destino (Obrigatório) *</label>
                            <v-select v-model="concileModal.targetAccount" :items="accounts" item-title="name" item-value="id" variant="outlined" density="compact" color="primary" placeholder="Selecione o banco..." hide-details class="font-weight-bold shadow-xs" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-background'"></v-select>
                        </div>
                    </div>
                    <v-divider vertical class="mx-2"></v-divider>
                    <div class="d-flex align-center gap-3 flex-grow-1">
                        <div style="width: 250px;"><v-text-field v-model="concileFilters.search" variant="outlined" density="compact" placeholder="Buscar extrato ou sistema..." prepend-inner-icon="mdi-magnify" hide-details class="shadow-xs" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-background'"></v-text-field></div>
                        <v-btn-toggle v-model="concileFilters.matchStatus" mandatory density="compact" class="border shadow-xs" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-background'" color="primary">
                            <v-btn value="all" class="text-caption font-weight-bold">Tudo</v-btn>
                            <v-btn value="matched" class="text-caption font-weight-bold text-success">Com Match</v-btn>
                            <v-btn value="unlinked" class="text-caption font-weight-bold text-error">Sem Match</v-btn>
                        </v-btn-toggle>
                        <v-btn-toggle v-model="concileFilters.systemAction" mandatory density="compact" class="border shadow-xs" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-background'" color="primary">
                            <v-btn value="all" class="text-caption font-weight-bold">Ações</v-btn>
                            <v-btn value="dar_baixa" class="text-caption font-weight-bold text-info">Baixar</v-btn>
                            <v-btn value="apenas_vincular" class="text-caption font-weight-bold text-warning">Vincular</v-btn>
                        </v-btn-toggle>
                    </div>
                    <div class="d-flex align-center bg-grey-lighten-4 px-3 py-1 rounded border" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-4' : 'bg-background'">
                        <v-checkbox-btn v-model="concileModal.selectAll" @change="toggleAllOfx" color="primary" density="compact" class="mr-2"></v-checkbox-btn>
                        <span class="text-caption font-weight-bold text-primary">Selecionar Tudo</span>
                    </div>
                </div>

                <div class="flex-grow-1 overflow-y-auto custom-scroll position-relative" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-4' : 'bg-transparent'">
                    <div class="grid-table w-100" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-surface'" style="min-width: 1100px;">

                        <div class="grid-header sticky-head shadow-sm border-b" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-3 text-grey-darken-3' : 'bg-grey-darken-4 text-white'" style="display: grid; grid-template-columns: 50px 1fr 60px 1fr 120px;">
                            <div class="cell center">#</div>
                            <div class="cell px-4 d-flex align-center">
                                <v-icon size="16" class="mr-2 text-medium-emphasis">mdi-file-document-outline</v-icon>
                                <span class="font-weight-black text-blue-grey-darken-3">EXTRATO BANCÁRIO</span>
                            </div>
                            <div class="cell center" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-2' : 'bg-grey-darken-3'"><v-icon size="18" color="grey-darken-1">mdi-link-variant</v-icon></div>
                            <div class="cell px-4 d-flex align-center">
                                <v-icon size="16" class="mr-2 text-medium-emphasis">mdi-database-search</v-icon>
                                <span class="font-weight-black text-teal-darken-3">SISTEMA ERP (Previsão / Match)</span>
                            </div>
                            <div class="cell center"><span class="font-weight-black text-blue-grey-darken-3">AÇÃO</span></div>
                        </div>

                        <div v-if="filteredConcileItems.length === 0" class="text-center py-16 opacity-50">
                            <v-icon size="64" class="mb-4 text-grey">mdi-filter-off</v-icon>
                            <div class="text-h6 font-weight-bold text-grey">Nenhum lançamento nos filtros</div>
                        </div>

                        <div v-else v-for="(item, idx) in filteredConcileItems" :key="idx"
                             class="grid-row border-b transition-all hover-bg"
                             :class="getConcileRowBg(item)"
                             style="display: grid; grid-template-columns: 50px 1fr 60px 1fr 120px; min-height: 80px;">

                            <div class="cell center" :class="item.exists ? (themeStore.currentMode === 'light' ? 'bg-grey-lighten-4' : 'bg-black-20') : ''">
                                <v-checkbox-btn v-model="item.selected" :disabled="item.exists" density="compact" color="primary"></v-checkbox-btn>
                            </div>

                            <div class="cell px-4 d-flex align-center justify-space-between position-relative" :class="item.exists ? (themeStore.currentMode === 'light' ? 'opacity-60 bg-grey-lighten-4' : 'opacity-60 bg-black-20') : ''">
                                <div v-if="item.revalidating" class="revalidating-overlay rounded"><v-progress-circular indeterminate color="primary" size="24" width="3"></v-progress-circular></div>
                                <div class="d-flex flex-column">
                                    <div class="d-flex align-center gap-2 mb-1">
                                        <span class="text-caption font-mono font-weight-bold border rounded px-1" :class="themeStore.currentMode === 'light' ? 'bg-white text-black' : 'bg-surface text-white'">{{ formatDateSimple(item.date) }}</span>
                                        <v-chip size="x-small" :color="item.amount >= 0 ? 'success' : 'error'" variant="flat" class="font-weight-bold px-1 text-[9px] chip-3d">
                                            {{ item.amount >= 0 ? 'ENTRADA' : 'SAÍDA' }}
                                        </v-chip>
                                    </div>
                                    <div class="text-body-2 font-weight-bold text-wrap-clamp" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-3' : 'text-white'" :title="item.memo">{{ item.memo }}</div>
                                    <div class="text-[10px] font-mono text-grey mt-1">ID: {{ item.fitid.substring(0, 15) }}...</div>
                                </div>
                                <div class="text-subtitle-1 font-mono font-weight-black flex-shrink-0 pl-2" :class="item.amount >= 0 ? 'text-success' : 'text-error'">
                                    {{ formatCurrency(item.amount) }}
                                </div>
                            </div>

                            <div class="cell center border-x" :class="item.exists ? (themeStore.currentMode === 'light' ? 'bg-grey-lighten-3' : 'bg-grey-darken-3') : (item.matchType === 'MATCHED' ? 'bg-teal-lighten-5' : 'bg-orange-lighten-5')">
                                <v-tooltip location="top">
                                    <template v-slot:activator="{ props }">
                                        <v-icon v-bind="props" size="28" :color="item.exists ? 'grey' : (item.matchType === 'MATCHED' ? 'teal-darken-2' : 'orange-darken-2')" :class="item.matchType === 'MATCHED' && !item.exists ? 'pulse-success' : ''">
                                            {{ item.exists ? 'mdi-cancel' : (item.matchType === 'MATCHED' ? 'mdi-link-variant' : 'mdi-link-variant-off') }}
                                        </v-icon>
                                    </template>
                                    <span>{{ item.exists ? 'Já Importado' : (item.matchType === 'MATCHED' ? `Match Encontrado (${item.confidence}%)` : 'Sem Correspondência no ERP') }}</span>
                                </v-tooltip>
                            </div>

                            <div class="cell px-4 d-flex align-center position-relative" :class="item.exists ? (themeStore.currentMode === 'light' ? 'opacity-60 bg-grey-lighten-4' : 'opacity-60 bg-black-20') : (item.matchType === 'MATCHED' ? (themeStore.currentMode === 'light' ? 'bg-teal-lighten-5' : 'bg-teal-darken-4') : '')">
                                <div v-if="item.exists" class="text-caption font-italic d-flex align-center gap-2" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-1' : 'text-grey-lighten-1'"><v-icon size="16">mdi-history</v-icon> Transação já existente no sistema.</div>
                                <div v-else-if="item.matchType === 'MATCHED'" class="w-100 d-flex justify-space-between align-center">
                                    <div class="d-flex flex-column">
                                        <div class="d-flex align-center gap-2 mb-1">
                                            <v-chip size="x-small" :color="getCompanyColor(item.matchedRecord?.company_name || '')" variant="flat" class="font-weight-bold font-mono text-[9px] px-1 chip-3d"><v-icon start size="10">mdi-domain</v-icon> {{ item.matchedRecord?.company_name || 'Empresa' }}</v-chip>
                                            <v-chip size="x-small" :color="item.matchedRecord?.table.includes('payable') ? 'error' : 'success'" variant="outlined" class="font-weight-bold text-[9px] px-1">{{ item.matchedRecord?.table.includes('payable') ? 'A PAGAR' : 'A RECEBER' }}</v-chip>
                                            <v-chip size="x-small" :color="item.systemStatus === 'pago' ? 'success' : 'warning'" variant="tonal" class="font-weight-bold text-[9px] px-1">{{ item.systemStatus === 'pago' ? 'Já Pago' : 'Aberto' }}</v-chip>
                                        </div>
                                        <div class="text-body-2 font-weight-bold text-truncate" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'" style="max-width: 300px;">{{ item.matchedRecord?.entity }}</div>
                                        <div class="text-caption text-truncate" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-2' : 'text-grey-lighten-1'" style="max-width: 300px;" :title="item.matchedRecord?.description">{{ item.matchedRecord?.description }}</div>
                                        <div class="text-[10px] font-mono text-grey mt-1 d-flex gap-2">
                                            <span>Venc: <b :class="isLate(item.matchedRecord?.dueDate, item.date) ? 'text-error' : (themeStore.currentMode === 'light' ? 'text-grey-darken-3' : 'text-grey-lighten-2')">{{ formatDateSimple(item.matchedRecord?.dueDate) }}</b></span>
                                            <span>|</span>
                                            <span>Sistema: <b :class="themeStore.currentMode === 'light' ? 'text-grey-darken-3' : 'text-grey-lighten-2'">{{ formatCurrency(item.matchedRecord?.originalValue) }}</b></span>
                                        </div>
                                    </div>
                                    <div class="d-flex flex-column gap-1 ml-2">
                                        <v-btn icon="mdi-magnify" size="x-small" variant="flat" :color="themeStore.currentMode === 'light' ? 'white' : 'grey-darken-3'" class="border shadow-sm text-primary" title="Substituir Vínculo Manualmente" @click="openManualLinkModal(item)"></v-btn>
                                        <v-btn icon="mdi-link-off" size="x-small" variant="flat" :color="themeStore.currentMode === 'light' ? 'white' : 'grey-darken-3'" class="border shadow-sm text-error" title="Desfazer Vínculo" @click="unlinkItem(item)"></v-btn>
                                    </div>
                                </div>
                                <div v-else class="w-100 d-flex justify-space-between align-center">
                                    <div class="d-flex flex-column">
                                        <v-chip color="orange-darken-2" size="x-small" variant="outlined" class="font-weight-bold uppercase mb-1 d-inline-flex" style="width: fit-content;"><v-icon start size="12">mdi-alert</v-icon> TÍTULO NÃO ENCONTRADO</v-chip>
                                        <div class="text-caption lh-1 mt-1" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-2' : 'text-grey-lighten-1'">Será criado um novo registro avulso no sistema.</div>
                                    </div>
                                    <div class="d-flex gap-2 ml-2 flex-shrink-0">
                                        <v-btn color="primary" variant="flat" size="small" class="btn-3d font-weight-bold px-2" @click="openManualLinkModal(item)"><v-icon start size="14">mdi-magnify</v-icon> Localizar</v-btn>
                                        <v-btn color="success" variant="flat" size="small" class="btn-3d font-weight-bold px-2" @click="openQuickTitleModal(item)"><v-icon start size="14">mdi-plus</v-icon> Criar</v-btn>
                                    </div>
                                </div>
                            </div>

                            <div class="cell center" :class="item.exists ? (themeStore.currentMode === 'light' ? 'bg-grey-lighten-4' : 'bg-black-20') : ''">
                                <v-chip v-if="!item.exists" size="small" :color="item.matchType === 'MATCHED' ? 'teal' : 'orange'" variant="flat" class="font-weight-black chip-3d w-100 justify-center">
                                    {{ item.matchType === 'MATCHED' ? (item.systemAction === 'dar_baixa' ? 'BAIXAR' : 'VINCULAR') : 'CRIAR' }}
                                </v-chip>
                                <span v-else class="text-[10px] font-weight-bold text-grey opacity-70">IGNORADO</span>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </v-card>
    </v-dialog>

    <v-dialog v-model="quickTitleModal.show" max-width="500" persistent>
        <v-card class="rounded-xl border-thin" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-surface'">
            <div class="px-6 py-4 border-b border-opacity-10 d-flex justify-space-between align-center bg-success text-white">
                <div class="text-subtitle-1 font-weight-bold d-flex align-center gap-2"><v-icon>mdi-plus-box-multiple</v-icon> Criar Título P/ Conciliar</div>
                <v-btn icon="mdi-close" variant="text" size="small" @click="quickTitleModal.show = false"></v-btn>
            </div>
            <div class="pa-6">
                <label class="text-caption font-weight-bold text-success mb-1 d-block">Valor do Extrato</label>
                <v-text-field :model-value="formatCurrency(quickTitleModal.amount)" readonly variant="outlined" density="compact" class="mb-4 font-weight-bold" :bg-color="themeStore.currentMode === 'light' ? 'grey-lighten-4' : 'black-20'"></v-text-field>
                <label class="text-caption font-weight-bold text-medium-emphasis mb-1 d-block">Empresa *</label>
                <v-select v-model="quickTitleModal.form.company_id" :items="systemCompanies" item-title="name" item-value="id" variant="outlined" density="compact" color="success" class="mb-4 bg-background" hide-details></v-select>
                <label class="text-caption font-weight-bold text-medium-emphasis mb-1 d-block">Cliente / Fornecedor *</label>
                <v-text-field v-model="quickTitleModal.form.entity_name" variant="outlined" density="compact" color="success" class="mb-4 bg-background" hide-details></v-text-field>
                <label class="text-caption font-weight-bold text-medium-emphasis mb-1 d-block">Descrição</label>
                <v-text-field v-model="quickTitleModal.form.description" variant="outlined" density="compact" color="success" hide-details class="bg-background"></v-text-field>
            </div>
            <div class="pa-4 border-t border-opacity-10 d-flex justify-end gap-3" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5' : 'bg-background'">
                <v-btn variant="text" color="medium-emphasis" class="text-none" @click="quickTitleModal.show = false">Cancelar</v-btn>
                <v-btn color="success" variant="flat" class="btn-3d font-weight-bold px-6 text-none" @click="submitQuickTitle" :loading="quickTitleModal.loading"><v-icon start>mdi-check-all</v-icon> Salvar e Vincular</v-btn>
            </div>
        </v-card>
    </v-dialog>

    <v-dialog v-model="manualLinkModal.show" max-width="1500" width="95vw" scrollable transition="dialog-bottom-transition" scrim="black opacity-80">
        <v-card class="rounded-xl overflow-hidden d-flex flex-column h-100" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-4' : 'bg-surface'">
            <div class="px-6 py-4 bg-primary text-white d-flex align-center justify-space-between flex-shrink-0 shadow-sm z-10">
                <div class="d-flex align-center gap-3">
                    <v-icon size="28">mdi-link-box-variant-outline</v-icon>
                    <div>
                        <h3 class="text-h6 font-weight-bold lh-1">Vincular Título Manualmente</h3>
                        <div class="text-caption opacity-80">Localize o título no sistema e vincule ao extrato selecionado.</div>
                    </div>
                </div>
                <v-btn icon="mdi-close" variant="text" color="white" @click="manualLinkModal.show = false"></v-btn>
            </div>

            <div class="pa-4 flex-shrink-0" :class="themeStore.currentMode === 'light' ? 'bg-blue-grey-darken-4 text-white' : 'bg-grey-darken-4 text-white border-b border-white-10'">
                <div class="text-[10px] font-weight-bold text-uppercase text-blue-grey-lighten-3 mb-2">Transação Bancária Selecionada:</div>
                <div class="d-flex justify-space-between align-center">
                    <div class="d-flex flex-column overflow-hidden pr-4">
                        <span class="text-body-1 font-weight-bold text-truncate">{{ manualLinkModal.ofxItem?.memo }}</span>
                        <span class="text-caption font-mono text-blue-grey-lighten-2">{{ formatDateSimple(manualLinkModal.ofxItem?.date) }}</span>
                    </div>
                    <div class="text-h5 font-mono font-weight-black text-right flex-shrink-0" :class="manualLinkModal.ofxItem?.amount >= 0 ? 'text-green-accent-3' : 'text-red-accent-2'">
                        {{ formatCurrency(manualLinkModal.ofxItem?.amount) }}
                    </div>
                </div>
            </div>

            <div class="pa-4 border-b flex-shrink-0 shadow-sm" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 border-grey-lighten-3' : 'bg-background border-white-10'" style="z-index: 5;">
                <div class="d-flex flex-wrap align-center gap-3">
                    <v-text-field v-model="manualLinkModal.search" @update:model-value="manualLinkModal.page = 1" variant="outlined" density="compact" placeholder="Buscar por descrição ou cliente..." prepend-inner-icon="mdi-magnify" hide-details class="flex-grow-1 shadow-xs" style="min-width: 250px;" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-surface'"></v-text-field>
                    <v-btn-toggle v-model="manualLinkModal.filterType" @update:model-value="manualLinkModal.page = 1" mandatory density="compact" class="border shadow-xs" color="primary" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-surface'">
                        <v-btn value="all" class="text-caption font-weight-bold">Tudo</v-btn>
                        <v-btn value="receivable" class="text-caption font-weight-bold text-success">A Receber</v-btn>
                        <v-btn value="payable" class="text-caption font-weight-bold text-error">A Pagar</v-btn>
                    </v-btn-toggle>
                    <v-btn-toggle v-model="manualLinkModal.status" @update:model-value="manualLinkModal.page = 1" mandatory density="compact" class="border shadow-xs" color="primary" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-surface'">
                        <v-btn value="all" class="text-caption font-weight-bold">Todos Status</v-btn>
                        <v-btn value="em_aberto" class="text-caption font-weight-bold text-warning">Pendentes</v-btn>
                        <v-btn value="pago" class="text-caption font-weight-bold text-success">Já Pagos</v-btn>
                    </v-btn-toggle>
                    <v-select v-model="manualLinkModal.company" @update:model-value="manualLinkModal.page = 1" :items="[{id:'all', name:'Todas Empresas'}, ...systemCompanies]" item-title="name" item-value="id" variant="outlined" density="compact" hide-details style="width: 180px;" class="shadow-xs" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-surface'"></v-select>
                    <div class="d-flex align-center gap-2 border rounded px-2 shadow-xs" style="height: 40px;" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-surface'">
                        <span class="text-caption font-weight-bold opacity-70">Vencimento:</span>
                        <input type="date" v-model="manualLinkModal.dateStart" @change="manualLinkModal.page = 1" class="clean-input text-caption font-mono" />
                        <span class="opacity-50">até</span>
                        <input type="date" v-model="manualLinkModal.dateEnd" @change="manualLinkModal.page = 1" class="clean-input text-caption font-mono" />
                    </div>
                </div>
            </div>

            <div class="flex-grow-1 d-flex flex-column overflow-hidden" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-transparent'">
                <div class="grid-scroll flex-grow-1 overflow-auto custom-scroll relative w-100">
                    <div class="grid-header sticky-head shadow-sm border-b" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-3 text-grey-darken-3' : 'bg-grey-darken-4 text-white'" style="display: grid; grid-template-columns: 80px 140px 90px minmax(180px, 1.5fr) minmax(200px, 2fr) 110px 120px 60px;">
                        <div class="cell center header-text">Tipo</div>
                        <div class="cell center header-text">Empresa</div>
                        <div class="cell center header-text">Status</div>
                        <div class="cell header-text">Cliente/Forn.</div>
                        <div class="cell header-text">Descrição</div>
                        <div class="cell center header-text">Vencimento</div>
                        <div class="cell center header-text">Valor Orig.</div>
                        <div class="cell center header-text">#</div>
                    </div>
                    <div v-if="paginatedPendingForLink.length === 0" class="d-flex flex-column justify-center align-center py-16 opacity-50 w-100 position-absolute" style="top: 50px;">
                        <v-icon size="48" class="mb-3">mdi-text-box-search-outline</v-icon>
                        <div class="text-body-1 font-weight-bold">Nenhum título correspondente aos filtros.</div>
                    </div>
                    <div v-else v-for="(item, index) in paginatedPendingForLink" :key="item.table + item.id" class="grid-row hover-bg transition-all" :class="[themeStore.currentMode === 'light' ? 'grid-row-light' : 'grid-row-dark', zebraClass(index)]" style="display: grid; grid-template-columns: 80px 140px 90px minmax(180px, 1.5fr) minmax(200px, 2fr) 110px 120px 60px;">
                        <div class="cell center">
                            <v-chip size="small" :color="item.type === 'receivable' ? 'success' : 'error'" variant="flat" class="font-weight-bold text-[10px] text-uppercase w-100 justify-center chip-3d">{{ item.type === 'receivable' ? 'Receber' : 'Pagar' }}</v-chip>
                        </div>
                        <div class="cell center px-1">
                            <v-chip size="x-small" :color="getCompanyColor(resolveCompanyName(item.company_id))" variant="flat" class="font-weight-bold font-mono text-[9px] text-truncate w-100 justify-center px-1 chip-3d">{{ resolveCompanyName(item.company_id) }}</v-chip>
                        </div>
                        <div class="cell center">
                            <v-chip size="x-small" :color="item.rawStatus === 'pago' || item.rawStatus === 'PAID' ? 'success' : 'warning'" variant="outlined" class="font-weight-bold text-[9px] w-100 justify-center">{{ item.rawStatus === 'pago' || item.rawStatus === 'PAID' ? 'Já Pago' : 'Aberto' }}</v-chip>
                        </div>
                        <div class="cell"><span class="text-body-2 font-weight-bold text-truncate" :class="themeStore.currentMode === 'light' ? 'text-black' : 'text-white'">{{ item.entity }}</span></div>
                        <div class="cell"><span class="text-caption text-medium-emphasis text-truncate">{{ item.description }}</span></div>
                        <div class="cell center"><span class="list-text-11 font-mono" :class="isLate(item.dueDate, format(new Date(), 'yyyy-MM-dd')) ? 'text-error font-weight-bold' : 'text-medium-emphasis'">{{ formatDateSimple(item.dueDate) }}</span></div>
                        <div class="cell center d-flex justify-end pr-4"><span class="list-text-11 font-mono font-weight-black" :class="item.type === 'receivable' ? 'text-success' : 'text-error'">{{ formatCurrency(item.value) }}</span></div>
                        <div class="cell center"><v-btn color="primary" variant="flat" size="small" icon="mdi-check-all" class="btn-3d" title="Vincular Título" @click="confirmManualLink(item)"></v-btn></div>
                    </div>
                </div>
                <div class="px-4 py-2 border-t d-flex justify-space-between align-center flex-shrink-0" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 border-grey-lighten-3' : 'bg-background border-white-10'">
                    <span class="text-caption font-weight-bold opacity-70">Encontrados: {{ filteredPendingForLink.length }}</span>
                    <v-pagination v-model="manualLinkModal.page" :length="manualLinkPageCount" density="compact" active-color="primary" variant="tonal" size="small" :total-visible="7"></v-pagination>
                </div>
            </div>
        </v-card>
    </v-dialog>

    <v-dialog v-model="feedbackState.show" max-width="450" persistent>
        <v-card class="rounded-xl" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-surface'">
            <v-card-text class="text-center pa-8">
                <div v-if="feedbackState.status === 'processing'" class="d-flex flex-column align-center">
                    <v-progress-circular indeterminate color="primary" size="64" width="6" class="mb-4"></v-progress-circular>
                    <h3 class="text-h6 font-weight-bold" :class="themeStore.currentMode === 'light' ? 'text-black' : 'text-white'">{{ feedbackState.title }}</h3>
                    <p class="text-body-2 text-medium-emphasis mt-2">{{ feedbackState.message }}</p>
                </div>
                <div v-else-if="feedbackState.status === 'success'" class="d-flex flex-column align-center">
                    <div class="icon-circle bg-green-lighten-5 mb-4 d-flex align-center justify-center" style="width: 80px; height: 80px; border-radius: 50%;">
                        <v-icon color="success" size="48">mdi-check-circle</v-icon>
                    </div>
                    <h3 class="text-h6 font-weight-bold text-success">{{ feedbackState.title }}</h3>
                    <p class="text-body-2 mt-2" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-2' : 'text-white-70'">{{ feedbackState.message }}</p>
                </div>
                <div v-else-if="feedbackState.status === 'error'" class="d-flex flex-column align-center">
                    <div class="icon-circle bg-red-lighten-5 mb-4 d-flex align-center justify-center" style="width: 80px; height: 80px; border-radius: 50%;">
                        <v-icon color="error" size="48">mdi-alert-circle</v-icon>
                    </div>
                    <h3 class="text-h6 font-weight-bold text-error">{{ feedbackState.title }}</h3>
                    <p class="text-body-2 mt-2" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-2' : 'text-white-70'">{{ feedbackState.message }}</p>
                    <div v-if="feedbackState.details.length" class="mt-4 pa-3 rounded w-100 text-left text-caption font-mono" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-4' : 'bg-black-20'" style="max-height: 150px; overflow-y: auto;">
                        <div v-for="(line, i) in feedbackState.details" :key="i" class="text-red-darken-3">{{ line }}</div>
                    </div>
                </div>
            </v-card-text>
            <v-card-actions v-if="feedbackState.status !== 'processing'" class="justify-center pb-6">
                <v-btn color="primary" variant="flat" size="large" class="btn-3d px-8 font-weight-bold rounded-lg text-none" @click="feedbackState.show = false">Fechar</v-btn>
            </v-card-actions>
        </v-card>
    </v-dialog>

  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, reactive, watch, onUnmounted } from 'vue';
import { supabase } from '@/api/supabase';
import { format, parseISO, startOfMonth, endOfMonth, isValid, differenceInDays, addDays, getWeek, startOfWeek, endOfWeek, subDays } from 'date-fns';
import { ptBR } from 'date-fns/locale';
import { useAppStore } from '@/stores/app';
import { useUserStore } from '@/stores/user';
import { useThemeStore } from '@/stores/themeStore';
import { coraApi } from '@/api/coraProxy';

const appStore = useAppStore();
const userStore = useUserStore();
const themeStore = useThemeStore();

// --- STATE GERAL ---
const currentTab = ref('accounts');
const loading = ref(false);
const accounts = ref<any[]>([]);
const search = ref('');
const ofxInput = ref<HTMLInputElement | null>(null);

let realtimeChannel: any = null;

// Cache para conciliação
const pendingPayables = ref<any[]>([]);
const pendingReceivables = ref<any[]>([]);
const systemCompanies = ref<any[]>([]);
const ofxFetchedRange = { min: '', max: '' };

const bankOptions = ['Itaú', 'Santander', 'Banco do Brasil', 'Nubank', 'Cora', 'Sicredi', 'Caixa Econômica', 'Bradesco', 'Inter', 'Original', 'Dinheiro / Cofre'];

// Define integrations globally
const coraIntegrations = [
    { name: 'MR JACKY', clientId: 'int-3VpXneDbEmHHHYFNN8hoIh' },
    { name: 'SANTOS & LOPES', clientId: 'int-23ze6BcCmlV6oqO2TPP01s' }
];

const coraKeys: Record<string, string> = {
    '20631721000107': 'int-3VpXneDbEmHHHYFNN8hoIh',
    '53756096000189': 'int-23ze6BcCmlV6oqO2TPP01s',
};

// --- MODAL OFX DRAG AND DROP ---
const ofxUploadModal = reactive({
    show: false,
    isDragging: false
});

const handleOfxDrop = (e: any) => {
    ofxUploadModal.isDragging = false;
    const file = e.dataTransfer?.files?.[0];
    if (file) {
        processOfxFile(file);
    }
};

const handleOfxFileSelect = (e: any) => {
    const file = e.target.files[0];
    if (file) {
        processOfxFile(file);
    }
};

// --- MODAL DO PIN DE SEGURANÇA ---
const pinModal = reactive({
    show: false,
    pin: '',
    loading: false,
    actionType: '',
    payload: null as any
});

const requirePinForAction = (actionType: string, payload: any = null) => {
    pinModal.actionType = actionType;
    pinModal.payload = payload;
    pinModal.pin = '';
    pinModal.show = true;
};

const confirmPin = async () => {
    if (!pinModal.pin || pinModal.pin.length < 4) return;
    pinModal.loading = true;
    try {
        const { data, error } = await supabase.from('profiles').select('security_pin').eq('id', userStore.user?.id).single();

        if (error) throw new Error('Erro ao validar autorização.');

        if (data && data.security_pin === pinModal.pin) {
            pinModal.show = false;
            // Executar ação correspondente
            if (pinModal.actionType === 'transfer') await submitTransfer();
            else if (pinModal.actionType === 'delete_account') await executeDeleteAccount(pinModal.payload);
        } else {
            appStore.showSnackbar('PIN de Segurança Inválido.', 'error');
        }
    } catch (e: any) {
        appStore.showSnackbar(e.message, 'error');
    } finally {
        pinModal.loading = false;
    }
};

// --- MODAIS DE NEGÓCIO ---
const statementModal = reactive({
    show: false,
    loading: false,
    account: null as any,
    isCora: false,
    syncingCora: false,
    coraClientId: coraIntegrations[0].clientId,
    groupingMode: 'day' as 'day' | 'week' | 'month',
    filters: {
        startDate: format(subDays(new Date(), 2), 'yyyy-MM-dd'),
        endDate: format(new Date(), 'yyyy-MM-dd'),
        search: ''
    }
});

const groupingOptions = [
    { label: 'Dia', value: 'day' },
    { label: 'Semana', value: 'week' },
    { label: 'Mês', value: 'month' }
];

const quickPeriodOptions = [
    { label: 'Hoje', value: 'today' },
    { label: 'Ontem', value: 'yesterday' },
    { label: 'Esta Semana', value: 'week' },
    { label: 'Este Mês', value: 'month' },
];

const applyStatementPreset = (preset: string) => {
    const today = new Date();
    if (preset === 'today') {
        statementModal.filters.startDate = format(today, 'yyyy-MM-dd');
        statementModal.filters.endDate = format(today, 'yyyy-MM-dd');
    } else if (preset === 'yesterday') {
        statementModal.filters.startDate = format(subDays(today, 1), 'yyyy-MM-dd');
        statementModal.filters.endDate = format(subDays(today, 1), 'yyyy-MM-dd');
    } else if (preset === 'week') {
        statementModal.filters.startDate = format(startOfWeek(today, { weekStartsOn: 1 }), 'yyyy-MM-dd');
        statementModal.filters.endDate = format(endOfWeek(today, { weekStartsOn: 1 }), 'yyyy-MM-dd');
    } else if (preset === 'month') {
        statementModal.filters.startDate = format(startOfMonth(today), 'yyyy-MM-dd');
        statementModal.filters.endDate = format(endOfMonth(today), 'yyyy-MM-dd');
    }
    fetchAccountStatement();
};

const transferModal = reactive({
    show: false,
    loading: false,
    sourceAccount: null as any,
    form: {
        to_account_id: null as any,
        amount: null as number | null,
        date: format(new Date(), 'yyyy-MM-dd'),
        reason: ''
    }
});

const concileFilters = reactive({
    search: '',
    dateStart: '',
    dateEnd: '',
    valMin: null as number | null | string,
    valMax: null as number | null | string,
    company: 'all',
    matchStatus: 'all',
    systemAction: 'all'
});

const concileModal = reactive({
  show: false,
  analyzing: false,
  loadingProgress: 0,
  loadingStatus: { title: '', subtitle: '' },
  items: [] as any[],
  targetAccount: null as string | null,
  selectAll: true,
  processing: false,
  filterType: 'all',
  kpis: { inflow: 0, outflow: 0 }
});

const coraSyncModal = reactive({
    show: false,
    loading: false,
    startDate: format(startOfMonth(new Date()), 'yyyy-MM-dd'),
    endDate: format(endOfMonth(new Date()), 'yyyy-MM-dd'),
    clientId: coraIntegrations[0].clientId
});

const manualLinkModal = reactive({ show: false, search: '', company: 'all', ofxItem: null as any, filterType: 'all' as 'all' | 'payable' | 'receivable', status: 'all' as 'all' | 'pago' | 'em_aberto', dateStart: '', dateEnd: '', page: 1, itemsPerPage: 15 });
const quickTitleModal = reactive({ show: false, loading: false, ofxItem: null as any, amount: 0, form: { company_id: null as any, entity_name: '', description: '' } });
const editModal = reactive({ show: false, loading: false, form: { id: '', name: '', bank_name: '', agency: '', account_number: '', initial_balance: 0, current_balance: 0, balance_date: format(new Date(), 'yyyy-MM-dd'), created_at: format(new Date(), 'yyyy-MM-dd'), is_active: true } });
const feedbackState = reactive({ show: false, status: 'idle', title: '', message: '', details: [] as string[] });

// --- COMPUTED ---
const canEditBalance = computed(() => !editModal.form.id || userStore.isSuperAdmin);

const filteredAccounts = computed(() => {
  let list = accounts.value;
  if (search.value) {
    const term = search.value.toLowerCase();
    list = list.filter(i => i.name?.toLowerCase().includes(term) || i.bank_name?.toLowerCase().includes(term) || i.account_number?.includes(term));
  }
  return list.sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime());
});

const statementItemsList = ref<any[]>([]);

const filteredStatementItems = computed(() => {
    let list = statementItemsList.value;
    if (statementModal.filters.search) {
        const term = statementModal.filters.search.toLowerCase();
        list = list.filter(t =>
            t.description?.toLowerCase().includes(term) ||
            t.counterPartyName?.toLowerCase().includes(term) ||
            t.category?.toLowerCase().includes(term)
        );
    }
    return list;
});

const groupedStatementData = computed(() => {
    const groups: Record<string, { label: string, dateObj: Date, items: any[], summary: { in: number, out: number } }> = {};

    filteredStatementItems.value.forEach(item => {
        const date = parseISO(item.date);
        if (!isValid(date)) return;

        let key = '';
        let label = '';

        if (statementModal.groupingMode === 'day') {
            key = format(date, 'yyyy-MM-dd');
            label = format(date, 'dd/MM/yyyy (EEEE)', { locale: ptBR });
        } else if (statementModal.groupingMode === 'week') {
            const week = getWeek(date, { locale: ptBR });
            const year = date.getFullYear();
            key = `${year}-W${week}`;
            label = `Semana ${week} de ${year}`;
        } else { // month
            key = format(date, 'yyyy-MM');
            label = format(date, 'MMMM yyyy', { locale: ptBR }).toUpperCase();
        }

        if (!groups[key]) {
            groups[key] = { label, dateObj: date, items: [], summary: { in: 0, out: 0 } };
        }

        groups[key].items.push(item);
        if (item.type === 'CREDIT') groups[key].summary.in += item.amount;
        else groups[key].summary.out += item.amount;
    });

    return Object.values(groups).sort((a, b) => b.dateObj.getTime() - a.dateObj.getTime());
});

const availableDestinationAccounts = computed(() => {
    if (!transferModal.sourceAccount) return [];
    return accounts.value.filter(a => a.id !== transferModal.sourceAccount.id && a.is_active);
});

const isTransferValid = computed(() => {
    return transferModal.form.to_account_id &&
           transferModal.form.amount &&
           transferModal.form.amount > 0 &&
           transferModal.form.reason.trim().length > 3 &&
           transferModal.form.date;
});

const filteredConcileItems = computed(() => {
    let list = concileModal.items;

    if (concileModal.filterType === 'in') list = list.filter(i => i.amount >= 0);
    if (concileModal.filterType === 'out') list = list.filter(i => i.amount < 0);

    if (concileFilters.matchStatus === 'matched') list = list.filter(i => i.matchType === 'MATCHED');
    if (concileFilters.matchStatus === 'unlinked') list = list.filter(i => i.matchType !== 'MATCHED');

    if (concileFilters.systemAction !== 'all') list = list.filter(i => i.systemAction === concileFilters.systemAction);

    if (concileFilters.search) {
        const term = concileFilters.search.toLowerCase();
        list = list.filter(i => i.memo.toLowerCase().includes(term) || (i.matchedRecord && i.matchedRecord.entity.toLowerCase().includes(term)));
    }

    if (concileFilters.dateStart) list = list.filter(i => i.date >= concileFilters.dateStart);
    if (concileFilters.dateEnd) list = list.filter(i => i.date <= concileFilters.dateEnd);

    if (concileFilters.valMin !== null && concileFilters.valMin !== '') list = list.filter(i => Math.abs(i.amount) >= Number(concileFilters.valMin));
    if (concileFilters.valMax !== null && concileFilters.valMax !== '') list = list.filter(i => Math.abs(i.amount) <= Number(concileFilters.valMax));

    if (concileFilters.company !== 'all') {
        list = list.filter(i => i.matchedRecord && (i.matchedRecord.company_id === concileFilters.company));
    }

    return list;
});

const filteredPendingForLink = computed(() => {
    const payables = pendingPayables.value.map(p => ({
        id: p.id, table: p._table, type: 'payable', description: p.description, entity: p.supplier_name || p.entity_name || 'Desconhecido', dueDate: p.due_date, value: Number(p.amount || p.value), company_id: p.company_id || p.companie_id, rawStatus: p.status
    }));
    const receivables = pendingReceivables.value.map(r => ({
        id: r.id, table: 'finance_receivables', type: 'receivable', description: r.description, entity: r.entity_name || r.customer_name || 'Desconhecido', dueDate: r.due_date, value: Number(r.value), company_id: r.company_id || r.companie_id, rawStatus: r.status
    }));

    let all = [...payables, ...receivables];

    if (manualLinkModal.filterType === 'payable') all = payables;
    if (manualLinkModal.filterType === 'receivable') all = receivables;
    if (manualLinkModal.company !== 'all') all = all.filter(i => i.company_id === manualLinkModal.company);
    if (manualLinkModal.search) {
        const term = manualLinkModal.search.toLowerCase();
        all = all.filter(i => i.description?.toLowerCase().includes(term) || i.entity?.toLowerCase().includes(term) || String(i.value).includes(term));
    }

    if (manualLinkModal.status === 'pago') all = all.filter(i => i.rawStatus === 'PAID' || i.rawStatus === 'pago');
    else if (manualLinkModal.status === 'em_aberto') all = all.filter(i => i.rawStatus !== 'PAID' && i.rawStatus !== 'pago');

    if (manualLinkModal.dateStart) all = all.filter(i => i.dueDate >= manualLinkModal.dateStart);
    if (manualLinkModal.dateEnd) all = all.filter(i => i.dueDate <= manualLinkModal.dateEnd);

    return all.sort((a,b) => new Date(a.dueDate).getTime() - new Date(b.dueDate).getTime());
});

const manualLinkPageCount = computed(() => Math.ceil(filteredPendingForLink.value.length / manualLinkModal.itemsPerPage) || 1);

const paginatedPendingForLink = computed(() => {
    const start = (manualLinkModal.page - 1) * manualLinkModal.itemsPerPage;
    return filteredPendingForLink.value.slice(start, start + manualLinkModal.itemsPerPage);
});

const kpiList = computed(() => {
  const totalBalance = accounts.value.reduce((acc, i) => acc + (Number(i.current_balance)||0), 0);
  const activeCount = accounts.value.filter(i => i.is_active).length;
  return [
    { label: 'Saldo Consolidado', value: totalBalance, footer: 'Todas as contas conectadas', icon: 'mdi-currency-brl', gradient: 'bg-gradient-info', isCurrency: true },
    { label: 'Contas Ativas', value: activeCount, footer: 'Em operação normal', icon: 'mdi-check-decagram', gradient: 'bg-gradient-green', isCurrency: false },
    { label: 'Bancos Conectados', value: accounts.value.length, footer: 'Instituições Financeiras', icon: 'mdi-bank-transfer', gradient: 'bg-gradient-purple', isCurrency: false },
  ];
});

// --- HELPERS & STYLES ---
const formatCurrency = (val: any) => new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(Number(val)||0);
const formatCurrencyValue = (val: any) => new Intl.NumberFormat('pt-BR', { minimumFractionDigits: 2 }).format(Number(val)||0);
const formatDateSimple = (date: string) => { if (!date) return '-'; try { const d = parseISO(date); return isValid(d) ? format(d, 'dd/MM/yyyy') : date; } catch { return date; } };
const formatTime = (isoString: string) => { if (!isoString) return '-'; try { return format(parseISO(isoString), 'HH:mm'); } catch { return '-'; } };
const isLate = (due: string, paid: string) => differenceInDays(parseISO(paid), parseISO(due)) > 0;
const zebraClass = (i:number) => themeStore.currentMode!=='light' ? (i%2===0?'zebra-dark-a':'zebra-dark-b') : (i%2===0?'zebra-light-a':'zebra-light-b');
const formatDocument = (doc: string | undefined) => {
    if (!doc) return '-';
    if (doc.length === 11) return doc.replace(/(\d{3})(\d{3})(\d{3})(\d{2})/, '$1.$2.$3-$4');
    if (doc.length === 14) return doc.replace(/(\d{2})(\d{3})(\d{3})(\d{4})(\d{2})/, '$1.$2.$3/$4-$5');
    return doc;
};

const getBankStyles = (bankName: string) => {
  const name = bankName?.toLowerCase() || '';
  if(name.includes('cora')) return { bg: 'bg-pink-lighten-5', text: 'text-pink-accent-3' };
  if(name.includes('sicredi')) return { bg: 'bg-green-lighten-5', text: 'text-green-darken-3' };
  if(name.includes('itaú')) return { bg: 'bg-orange-lighten-5', text: 'text-orange-darken-3' };
  if(name.includes('santander')) return { bg: 'bg-red-lighten-5', text: 'text-red-darken-3' };
  if(name.includes('nubank')) return { bg: 'bg-purple-lighten-5', text: 'text-purple-accent-3' };
  return { bg: 'bg-grey-lighten-4', text: 'text-grey-darken-3' };
};

const getConcileRowBg = (item: any) => {
    if (!item.selected && !item.exists) return 'opacity-50 grayscale';
    return '';
};

const getRowColorClass = (type: string) => {
    return type === 'CREDIT' ? 'bg-green-soft border-l-4-green' : 'bg-red-soft border-l-4-red';
};

const getCompanyColor = (companyName: string) => {
    const name = companyName.toLowerCase();
    if (name.includes('jacky')) return 'orange-darken-3';
    if (name.includes('santos')) return 'blue-darken-3';
    return 'blue-grey-darken-1';
};

const resolveCompanyName = (companyId: string) => {
    if (!companyId) return 'Empresa Padrão';
    let name = '';
    const comp = systemCompanies.value.find(c => c.id === companyId);
    if (comp) name = comp.name || comp.trade_name;
    else name = companyId;

    if (name.toLowerCase().includes('jacky')) return 'MR JACKY';
    if (name.toLowerCase().includes('santos')) return 'SANTOS & LOPES';
    return 'Empresa (ID: ' + companyId.substring(0, 5) + '...)';
};

// --- AÇÕES DA GRID PRINCIPAL ---
const openStatementModal = (account: any) => {
    statementModal.account = account;
    statementModal.isCora = account.bank_name?.toLowerCase().includes('cora');

    if (statementModal.isCora) {
        const accName = account.name.toLowerCase();
        if (accName.includes('santos')) statementModal.coraClientId = coraIntegrations[1].clientId;
        else statementModal.coraClientId = coraIntegrations[0].clientId;
    }

    statementModal.filters.search = '';

    // Chunking prevention start
    let defaultStart = new Date();
    defaultStart.setDate(defaultStart.getDate() - 5);
    statementModal.filters.startDate = format(defaultStart, 'yyyy-MM-dd');
    statementModal.filters.endDate = format(new Date(), 'yyyy-MM-dd');

    statementModal.show = true;
    fetchAccountStatement();
};

const fetchAccountStatement = async () => {
    statementModal.loading = true;
    statementItemsList.value = [];
    try {
        if (statementModal.isCora) {
            const targetClientId = statementModal.coraClientId;
            if (targetClientId) {

                let allEntries: any[] = [];
                let currentDate = parseISO(statementModal.filters.startDate);
                const finalDate = parseISO(statementModal.filters.endDate);

                // CHUNKING LOGIC - DE 5 EM 5 DIAS PARA EVITAR 504 TIMEOUT
                while (currentDate <= finalDate) {
                    let chunkEnd = addDays(currentDate, 5);
                    if (chunkEnd > finalDate) chunkEnd = finalDate;

                    const chunkStartStr = format(currentDate, 'yyyy-MM-dd');
                    const chunkEndStr = format(chunkEnd, 'yyyy-MM-dd');

                    try {
                        const response = await coraApi.getBankStatement({
                            start: chunkStartStr,
                            end: chunkEndStr
                        }, targetClientId);

                        if (response && response.entries) {
                            allEntries = allEntries.concat(response.entries);
                        }
                    } catch (chunkErr) {
                        console.warn(`Erro no chunk ${chunkStartStr} a ${chunkEndStr}`, chunkErr);
                    }

                    currentDate = addDays(chunkEnd, 1);
                }

                statementItemsList.value = allEntries.map((item: any) => ({
                    id: item.id,
                    date: item.createdAt,
                    type: item.type === 'CREDIT' ? 'CREDIT' : 'DEBIT',
                    description: item.transaction.description,
                    category: item.transaction.title || 'Transferência Bancária',
                    counterPartyName: item.transaction.counterParty?.name || '-',
                    counterPartyDoc: item.transaction.counterParty?.identity || '-',
                    amount: Math.abs(item.amount / 100),
                    isCora: true,
                    isConciliated: false
                }));
            }
        } else {
            const { data } = await supabase.from('finance_transactions')
                .select('*')
                .eq('account_id', statementModal.account.id)
                .gte('transaction_date', statementModal.filters.startDate)
                .lte('transaction_date', statementModal.filters.endDate)
                .order('transaction_date', { ascending: false });

            statementItemsList.value = (data || []).map((tx: any) => ({
                id: tx.id,
                date: tx.transaction_date,
                type: tx.type === 'INCOME' ? 'CREDIT' : 'DEBIT',
                description: tx.description,
                category: tx.category || 'Geral',
                counterPartyName: tx.entity_name || '-',
                counterPartyDoc: tx.document || '-',
                amount: Math.abs(tx.amount),
                isCora: false,
                isConciliated: tx.reconciliation_status === 'CONCILIATED'
            }));
        }
    } catch (e: any) {
        console.error(e);
        appStore.showSnackbar(e.message || 'Erro ao buscar extrato.', 'error');
    } finally {
        statementModal.loading = false;
    }
};

const syncCoraApi = async () => {
    statementModal.syncingCora = true;
    try {
        await new Promise(resolve => setTimeout(resolve, 1500));
        appStore.showSnackbar('Extrato Cora sincronizado com sucesso via API!', 'success');
        fetchAccountStatement();
    } catch (error) {
        appStore.showSnackbar('Erro ao sincronizar com Cora API.', 'error');
    } finally {
        statementModal.syncingCora = false;
    }
};

const openTransferModal = (account: any) => {
    transferModal.sourceAccount = account;
    transferModal.form = {
        to_account_id: null,
        amount: null,
        date: format(new Date(), 'yyyy-MM-dd'),
        reason: ''
    };
    transferModal.show = true;
};

const submitTransfer = async () => {
    transferModal.loading = true;
    try {
        const fromAccount = transferModal.sourceAccount;
        const toAccount = accounts.value.find(a => a.id === transferModal.form.to_account_id);
        const amount = Number(transferModal.form.amount);
        const date = transferModal.form.date;
        const reason = transferModal.form.reason;

        const { error: err1 } = await supabase.from('finance_transactions').insert({
            account_id: fromAccount.id,
            amount: amount,
            type: 'EXPENSE',
            category: 'Transferência Saída',
            description: `Transferência para ${toAccount.name} | Motivo: ${reason}`,
            status: 'COMPLETED',
            transaction_date: date
        });
        if (err1) throw err1;

        const { error: err2 } = await supabase.from('finance_transactions').insert({
            account_id: toAccount.id,
            amount: amount,
            type: 'INCOME',
            category: 'Transferência Entrada',
            description: `Transferência recebida de ${fromAccount.name} | Motivo: ${reason}`,
            status: 'COMPLETED',
            transaction_date: date
        });
        if (err2) throw err2;

        await supabase.from('finance_accounts').update({ current_balance: Number(fromAccount.current_balance) - amount }).eq('id', fromAccount.id);
        await supabase.from('finance_accounts').update({ current_balance: Number(toAccount.current_balance) + amount }).eq('id', toAccount.id);

        await supabase.from('operation_events').insert({
            module_key: 'Financeiro',
            actor_type: 'user',
            actor_id: userStore.user?.id,
            actor_name: userStore.user?.full_name || 'Sistema',
            action_type: 'TRANSFER',
            entity_type: 'finance_accounts',
            entity_id: fromAccount.id,
            entity_label: 'Transferência entre Contas',
            didactic_message: `Transferiu ${formatCurrency(amount)} de ${fromAccount.name} para ${toAccount.name}. Motivo: ${reason}`,
            payload: { from: fromAccount.id, to: toAccount.id, amount, reason },
            severity: 'warning'
        });

        appStore.showSnackbar('Transferência realizada e auditada com sucesso.', 'success');
        transferModal.show = false;
        fetchAccounts();
    } catch (error: any) {
        appStore.showSnackbar(`Erro na transferência: ${error.message}`, 'error');
    } finally {
        transferModal.loading = false;
    }
};

const executeDeleteAccount = async (item: any) => {
    try {
        await supabase.from('finance_accounts').delete().eq('id', item.id);
        accounts.value = accounts.value.filter(a => a.id !== item.id);
        appStore.showSnackbar('Conta excluída com sucesso.', 'success');
    } catch(e:any) {
        appStore.showSnackbar('Erro ao excluir: ' + e.message, 'error');
    }
};

const fetchAccounts = async () => {
  loading.value = true;
  try {
    const { data } = await supabase.from('finance_accounts').select('*');
    if(data) accounts.value = data;
  } catch { appStore.showSnackbar('Erro ao carregar contas.', 'error'); } finally { loading.value = false; }
};

const fetchCompanies = async () => {
    try {
        const { data } = await supabase.from('companies').select('id, trade_name, name').limit(50);
        if (data) systemCompanies.value = data;
    } catch (e) { console.warn('Aviso: Não foi possível buscar companies da base.', e) }
};

const openNewAccountModal = () => { Object.assign(editModal.form, { id: '', name: '', bank_name: '', agency: '', account_number: '', initial_balance: 0, current_balance: 0, balance_date: format(new Date(), 'yyyy-MM-dd'), created_at: format(new Date(), 'yyyy-MM-dd'), is_active: true }); editModal.show = true; };
const openEditModal = (item: any) => { Object.assign(editModal.form, { ...item, balance_date: item.balance_date || format(new Date(), 'yyyy-MM-dd') }); editModal.show = true; };

const saveAccount = async () => {
    editModal.loading = true;
    try {
        const payload = { ...editModal.form };
        if(payload.id) {
            await supabase.from('finance_accounts').update(payload).eq('id', payload.id);
        } else {
            await supabase.from('finance_accounts').insert(payload);
        }
        appStore.showSnackbar('Conta salva com sucesso!', 'success');
        editModal.show = false;
        fetchAccounts();
    } catch(e:any) {
        appStore.showSnackbar(e.message, 'error');
    } finally {
        editModal.loading = false;
    }
};

const toggleStatus = async (item: any) => { await supabase.from('finance_accounts').update({ is_active: !item.is_active }).eq('id', item.id); item.is_active = !item.is_active; fetchAccounts(); };

// --- LÓGICA DE VINCULAÇÃO MANUAL ---
const openManualLinkModal = (ofxItem: any) => {
    manualLinkModal.ofxItem = ofxItem;
    manualLinkModal.search = '';
    manualLinkModal.company = 'all';
    manualLinkModal.filterType = ofxItem.amount < 0 ? 'payable' : 'receivable';
    manualLinkModal.status = 'all';
    manualLinkModal.dateStart = '';
    manualLinkModal.dateEnd = '';
    manualLinkModal.page = 1;
    manualLinkModal.show = true;
};

const confirmManualLink = (record: any) => {
    if (manualLinkModal.ofxItem) {
        const isPaid = record.rawStatus === 'PAID' || record.rawStatus === 'pago';

        manualLinkModal.ofxItem.matchType = 'MATCHED';
        manualLinkModal.ofxItem.confidence = 100;
        manualLinkModal.ofxItem.systemStatus = isPaid ? 'pago' : 'em_aberto';
        manualLinkModal.ofxItem.systemAction = isPaid ? 'apenas_vincular' : 'dar_baixa';
        manualLinkModal.ofxItem.matchedRecord = {
            id: record.id,
            table: record.table,
            description: record.description || 'Vínculo Manual',
            entity: record.entity,
            dueDate: record.dueDate,
            originalValue: Number(record.value),
            company_id: record.company_id,
            company_name: resolveCompanyName(record.company_id)
        };
    }
    manualLinkModal.show = false;
};

const unlinkItem = (item: any) => {
    item.matchType = 'NEW';
    item.confidence = 0;
    item.systemStatus = 'novo';
    item.systemAction = 'criar_avulso';
    item.matchedRecord = null;
};

const revalidateUnlinkedItems = async () => {
    const unlinkedItems = concileModal.items.filter(i => i.matchType !== 'MATCHED');
    if (unlinkedItems.length === 0) return;

    unlinkedItems.forEach(i => { i.revalidating = true; });

    await new Promise(r => setTimeout(r, 100));
    await fetchFinancialsForConciliation(ofxFetchedRange.min, ofxFetchedRange.max);

    setTimeout(() => {
        unlinkedItems.forEach(item => {
            const matchInfo = findMatch(item);
            if (matchInfo.matchType === 'MATCHED') {
                item.matchType = matchInfo.matchType;
                item.confidence = matchInfo.confidence;
                item.systemStatus = matchInfo.systemStatus;
                item.systemAction = matchInfo.systemAction;
                item.matchedRecord = matchInfo.matchedRecord;
                appStore.showSnackbar(`Vínculo automático encontrado para: ${item.memo}`, 'success');
            }
            item.revalidating = false;
        });
    }, 1200);
};

const openQuickTitleModal = (ofxItem: any) => {
    quickTitleModal.ofxItem = ofxItem;
    quickTitleModal.amount = Math.abs(ofxItem.amount);
    quickTitleModal.form = {
        company_id: systemCompanies.value.length > 0 ? systemCompanies.value[0].id : null,
        entity_name: '',
        description: ofxItem.memo || ''
    };
    quickTitleModal.show = true;
};

const submitQuickTitle = async () => {
    if (!quickTitleModal.form.company_id || !quickTitleModal.form.entity_name) {
        appStore.showSnackbar('Preencha Empresa e Entidade.', 'warning');
        return;
    }
    quickTitleModal.loading = true;
    try {
        const isReceivable = quickTitleModal.ofxItem.amount >= 0;
        const table = isReceivable ? 'finance_receivables' : 'finance_payables';
        const dateStr = quickTitleModal.ofxItem.date ? quickTitleModal.ofxItem.date.split('T')[0] : format(new Date(), 'yyyy-MM-dd');

        const payload = {
            company_id: quickTitleModal.form.company_id,
            entity_name: quickTitleModal.form.entity_name,
            description: quickTitleModal.form.description,
            value: quickTitleModal.amount,
            due_date: dateStr,
            status: 'em_aberto'
        };

        const { error } = await supabase.from(table).insert(payload);
        if (error) throw error;

        quickTitleModal.show = false;
        appStore.showSnackbar('Título Criado! Iniciando Sincronização...', 'success');

        await revalidateUnlinkedItems();

    } catch(e:any) {
        appStore.showSnackbar(e.message, 'error');
    } finally {
        quickTitleModal.loading = false;
    }
};

const triggerOfxUpload = () => { ofxUploadModal.show = true; };

// ==========================================
// --- LÓGICA COMPARTILHADA DA CONCILIAÇÃO ---
// ==========================================
const executeConciliationAnalysis = async (rawItems: any[]) => {
    if (rawItems.length === 0) {
        concileModal.analyzing = false;
        appStore.showSnackbar('Nenhuma transação encontrada no arquivo ou período.', 'warning');
        return;
    }

    concileModal.analyzing = true;
    concileModal.loadingStatus = { title: 'Cruzando Dados com o ERP...', subtitle: 'Buscando Faturas Abertas e Recém Pagas' };
    concileModal.loadingProgress = 50;

    const dates = rawItems.map(i => i.date).filter(d => !!d).map(d => parseISO(d.split('T')[0]).getTime());
    ofxFetchedRange.min = new Date(Math.min(...dates)).toISOString();
    ofxFetchedRange.max = new Date(Math.max(...dates)).toISOString();

    await Promise.all([fetchFinancialsForConciliation(ofxFetchedRange.min, ofxFetchedRange.max), fetchCompanies()]);

    setTimeout(async () => {
        const fitids = rawItems.map(i => i.fitid);
        const { data: existingTxs } = await supabase.from('finance_transactions').select('external_id').in('external_id', fitids);
        const existingSet = new Set(existingTxs?.map(t => t.external_id));

        let inflow = 0, outflow = 0;
        concileModal.items = rawItems.map(item => {
            const exists = existingSet.has(item.fitid);
            const matchInfo = findMatch(item);
            if(item.amount >= 0) inflow += item.amount; else outflow += Math.abs(item.amount);
            return { ...item, ...matchInfo, exists, selected: !exists, revalidating: false };
        });

        concileModal.kpis = { inflow, outflow };

        concileFilters.search = '';
        concileFilters.dateStart = '';
        concileFilters.dateEnd = '';
        concileFilters.valMin = null;
        concileFilters.valMax = null;
        concileFilters.company = 'all';
        concileFilters.matchStatus = 'all';
        concileFilters.systemAction = 'all';

        concileModal.loadingProgress = 100;
        concileModal.loadingStatus = { title: 'Análise Concluída!', subtitle: 'Matches gerados com sucesso.' };
        setTimeout(() => { concileModal.analyzing = false; }, 600);
    }, 500);
};

const processOfxFile = (file: File) => {
    ofxUploadModal.show = false;
    concileModal.show = true;
    concileModal.analyzing = true;
    concileModal.loadingStatus = { title: 'Lendo Arquivo Bancário...', subtitle: 'Processando extrato OFX' };
    concileModal.loadingProgress = 20;

    const reader = new FileReader();
    reader.onload = async (ev: any) => {
        const content = ev.target.result;
        const rawItems = parseOFX(content);
        concileModal.targetAccount = null;
        await executeConciliationAnalysis(rawItems);
    };
    reader.readAsText(file);
};

const fetchCoraStatementForConciliation = async () => {
    coraSyncModal.loading = true;
    try {
        const targetClientId = coraSyncModal.clientId;
        const companyName = coraIntegrations.find(c => c.clientId === targetClientId)?.name || 'Cora';

        let allRawItems: any[] = [];
        let currentDate = parseISO(coraSyncModal.startDate);
        const finalDate = parseISO(coraSyncModal.endDate);

        // Fatiamento (Chunking) de 5 em 5 dias para o proxy Cora não dar 504
        while (currentDate <= finalDate) {
            let chunkEnd = addDays(currentDate, 5);
            if (chunkEnd > finalDate) chunkEnd = finalDate;

            const chunkStartStr = format(currentDate, 'yyyy-MM-dd');
            const chunkEndStr = format(chunkEnd, 'yyyy-MM-dd');

            try {
                const response = await coraApi.getBankStatement({
                    start: chunkStartStr,
                    end: chunkEndStr
                }, targetClientId);

                if (response && response.entries) {
                    const chunkItems = response.entries.map((entry: any) => {
                        const valInCents = Number(entry.amount);
                        const valInReais = valInCents / 100;
                        const finalAmount = entry.type === 'DEBIT' ? -Math.abs(valInReais) : Math.abs(valInReais);

                        const cpName = entry.transaction?.counterParty?.name;
                        const desc = entry.transaction?.description || 'Transação Cora';
                        const memo = cpName ? `${desc} - ${cpName} (${companyName})` : `${desc} (${companyName})`;

                        return {
                            date: entry.createdAt ? entry.createdAt.substring(0, 10) : new Date().toISOString().substring(0, 10),
                            memo: memo,
                            amount: finalAmount,
                            fitid: entry.id || `CORA_${Date.now()}_${Math.random()}`
                        };
                    });
                    allRawItems = allRawItems.concat(chunkItems);
                }
            } catch (chunkErr) {
                console.warn(`Erro no chunk ${chunkStartStr} a ${chunkEndStr}`, chunkErr);
            }

            currentDate = addDays(chunkEnd, 1);
        }

        if (allRawItems.length === 0) {
            throw new Error('Nenhuma transação encontrada no período.');
        }

        coraSyncModal.show = false;
        concileModal.show = true;

        const coraAccount = accounts.value.find(a => a.bank_name?.toLowerCase().includes('cora'));
        if (coraAccount) concileModal.targetAccount = coraAccount.id;
        else concileModal.targetAccount = null;

        await executeConciliationAnalysis(allRawItems);

        appStore.showSnackbar(`Extrato Cora importado: ${allRawItems.length} registros.`, 'success');
    } catch (error: any) {
        appStore.showSnackbar('Erro ao buscar extrato da Cora: ' + error.message, 'error');
        concileModal.show = false;
    } finally {
        coraSyncModal.loading = false;
    }
};

const fetchFinancialsForConciliation = async (minDate: string, maxDate: string) => {
    try {
        const start = format(addDays(parseISO(minDate.split('T')[0]), -10), 'yyyy-MM-dd');
        const end = format(addDays(parseISO(maxDate.split('T')[0]), 10), 'yyyy-MM-dd');

        const [cpOpen, cpPaid, fpOpen, fpPaid, frOpenRaw, frPaid] = await Promise.all([
            supabase.from('cajuia_payables').select('*').neq('status', 'PAID').order('id', {ascending: false}).limit(3000),
            supabase.from('cajuia_payables').select('*').eq('status', 'PAID').gte('payment_date', start).lte('payment_date', end),
            supabase.from('finance_payables').select('*').neq('status', 'pago').order('id', {ascending: false}).limit(3000),
            supabase.from('finance_payables').select('*').eq('status', 'pago').gte('payment_date', start).lte('payment_date', end),
            supabase.from('finance_receivables').select('*').neq('status', 'pago').order('id', {ascending: false}).limit(3000),
            supabase.from('finance_receivables').select('*').eq('status', 'pago').gte('payment_date', start).lte('payment_date', end)
        ]);

        const uniqueById = (arr1: any[], arr2: any[]) => {
            const map = new Map();
            [...(arr1||[]), ...(arr2||[])].forEach(item => map.set(item.id, item));
            return Array.from(map.values());
        };

        pendingPayables.value = [
            ...uniqueById(cpOpen.data || [], cpPaid.data || []).map((i:any) => ({...i, _table: 'cajuia_payables'})),
            ...uniqueById(fpOpen.data || [], fpPaid.data || []).map((i:any) => ({...i, _table: 'finance_payables'}))
        ];

        const validFrOpen = (frOpenRaw.data || []).filter((r:any) => r.status !== 'confirmado');
        pendingReceivables.value = uniqueById(validFrOpen, frPaid.data || []).map((i:any) => ({...i, _table: 'finance_receivables'}));

    } catch (e) {
        console.error('[DEBUG MATCH] Erro ao buscar pendencias:', e);
    }
};

const findMatch = (ofxItem: any) => {
    const targetList = ofxItem.amount < 0 ? pendingPayables.value : pendingReceivables.value;
    const targetAmount = Math.abs(ofxItem.amount);

    const ofxDateStr = ofxItem.date ? String(ofxItem.date).split('T')[0] : '';

    const match = targetList.find(record => {
        const baseVal = Number(record.amount || record.value || 0);
        const discountVal = Number(record.discount || 0);
        const recordNet = baseVal - discountVal;

        const amountMatch = Math.abs(recordNet - targetAmount) < 0.05;

        const recDueStr = record.due_date ? String(record.due_date).split('T')[0] : '';
        const recPaidStr = record.payment_date ? String(record.payment_date).split('T')[0] : '';

        const dateDiffDue = recDueStr ? Math.abs(differenceInDays(parseISO(ofxDateStr), parseISO(recDueStr))) : 999;
        const dateDiffPaid = recPaidStr ? Math.abs(differenceInDays(parseISO(ofxDateStr), parseISO(recPaidStr))) : 999;

        return amountMatch && (dateDiffDue <= 5 || dateDiffPaid <= 5);
    });

    if (match) {
        const recDueStr = match.due_date ? String(match.due_date).split('T')[0] : '';
        const recPaidStr = match.payment_date ? String(match.payment_date).split('T')[0] : '';

        const dateDiffDue = recDueStr ? Math.abs(differenceInDays(parseISO(ofxDateStr), parseISO(recDueStr))) : 999;
        const dateDiffPaid = recPaidStr ? Math.abs(differenceInDays(parseISO(ofxDateStr), parseISO(recPaidStr))) : 999;
        const bestDateDiff = Math.min(dateDiffDue, dateDiffPaid);

        let confidence = 100;
        if (bestDateDiff > 0) confidence = 85;
        if (bestDateDiff > 3) confidence = 70;

        const rawCompanyId = match.companie_id || match.company_id || null;
        const isPaid = match.status === 'PAID' || match.status === 'pago';

        return {
            matchType: 'MATCHED',
            confidence: confidence,
            systemStatus: isPaid ? 'pago' : 'em_aberto',
            systemAction: isPaid ? 'apenas_vincular' : 'dar_baixa',
            matchedRecord: {
                id: match.id,
                table: match._table,
                description: match.description || 'Sem Descrição',
                entity: match.supplier_name || match.entity_name || match.customer_name || 'Desconhecido',
                dueDate: match.due_date,
                paymentDate: match.payment_date,
                originalValue: Number(match.amount || match.value),
                company_id: rawCompanyId,
                company_name: resolveCompanyName(rawCompanyId)
            }
        };
    }
    return { matchType: 'NEW', confidence: 0, systemStatus: 'novo', systemAction: 'criar_avulso', matchedRecord: null };
};

const setupRealtime = () => {
    if (realtimeChannel) supabase.removeChannel(realtimeChannel);

    const handleRealtimeChange = async (payload: any) => {
        if (!concileModal.show) return;
        await revalidateUnlinkedItems();
    };

    realtimeChannel = supabase.channel('concile_realtime')
        .on('postgres_changes', { event: '*', schema: 'public', table: 'finance_receivables' }, handleRealtimeChange)
        .on('postgres_changes', { event: '*', schema: 'public', table: 'cajuia_payables' }, handleRealtimeChange)
        .on('postgres_changes', { event: '*', schema: 'public', table: 'finance_payables' }, handleRealtimeChange)
        .subscribe();
};

const parseOFX = (ofxString: string) => {
  const transactions = [];
  const regex = /<STMTTRN>([\s\S]*?)<\/STMTTRN>/gi;
  let match;
  let count = 0;
  while ((match = regex.exec(ofxString)) !== null) {
    count++;
    const block = match[1];

    const extractTag = (tag: string) => {
       const tagRegex = new RegExp(`<${tag}>([^<\\r\\n]+)`, 'i');
       return block.match(tagRegex)?.[1]?.trim() || '';
    };

    const type = extractTag('TRNTYPE') || 'OTHER';
    const dateRaw = extractTag('DTPOSTED');
    const amountStr = extractTag('TRNAMT') || '0';
    const fitid = extractTag('FITID') || `MANUAL_${Date.now()}_${count}`;
    const memo = extractTag('MEMO') || 'Sem descrição';

    const amount = parseFloat(amountStr.replace(',', '.'));
    const date = dateRaw ? `${dateRaw.substring(0,4)}-${dateRaw.substring(4,6)}-${dateRaw.substring(6,8)}` : new Date().toISOString();

    let finalAmount = amount;
    if (type.toUpperCase() === 'DEBIT' && amount > 0) finalAmount = -amount;

    transactions.push({ amount: finalAmount, date: date, fitid: fitid, memo: memo });
  }
  return transactions;
};

const toggleAllOfx = () => concileModal.items.forEach(i => { if(!i.exists) i.selected = concileModal.selectAll });

const processConciliation = async () => {
    if (!concileModal.targetAccount) { appStore.showSnackbar('Selecione a Conta de Destino.', 'warning'); return; }

    let itemsToImport = concileModal.items.filter(i => i.selected && !i.exists);

    if (itemsToImport.length === 0) {
        appStore.showSnackbar('Nenhum item selecionado', 'info');
        return;
    }

    const hasUnlinked = itemsToImport.some(i => i.matchType !== 'MATCHED');
    if (hasUnlinked) {
        appStore.showSnackbar('ERRO: Não é permitido salvar lançamentos avulsos. Localize o título e vincule manualmente.', 'error');
        return;
    }

    concileModal.processing = true;

    try {
        let successCount = 0;

        for (const item of itemsToImport) {
            let finalDesc = `${item.memo || 'OFX'} [ID:${item.fitid}] (Vinc: ${item.matchedRecord?.description || 'Manual'})`;

            const { error: transError } = await supabase.from('finance_transactions').insert({
                account_id: concileModal.targetAccount,
                transaction_date: item.date,
                description: finalDesc,
                amount: Math.abs(item.amount),
                type: item.amount >= 0 ? 'INCOME' : 'EXPENSE',
                category: 'Conciliado Automático',
                status: 'COMPLETED',
                reconciliation_status: 'CONCILIATED',
                external_id: item.fitid
            });

            if (transError) throw new Error(`Erro transação: ${transError.message}`);

            if (item.systemAction === 'dar_baixa' || item.systemAction === 'apenas_vincular') {
                const table = item.matchedRecord.table;
                const recId = item.matchedRecord.id;
                const safeDate = item.date ? item.date.split('T')[0] : format(new Date(), 'yyyy-MM-dd');

                const updatePayload: any = {
                    reconciliation_status: 'CONCILIATED',
                    bank_fitid: item.fitid
                };

                if (item.systemAction === 'dar_baixa') {
                    updatePayload.status = table === 'cajuia_payables' ? 'PAID' : 'pago';
                    updatePayload.payment_date = safeDate;
                    updatePayload.bank_account_id = concileModal.targetAccount;

                    if (table === 'cajuia_payables') {
                        updatePayload.amount_paid = Math.abs(item.amount);
                    }
                }

                const { error: updateError } = await supabase.from(table).update(updatePayload).eq('id', recId);
                if (updateError) throw new Error(`Erro ao vincular título: ${updateError.message}`);
            }
            successCount++;
        }

        const totalIncome = itemsToImport.filter(i => i.amount >= 0).reduce((acc, i) => acc + i.amount, 0);
        const totalExpense = itemsToImport.filter(i => i.amount < 0).reduce((acc, i) => acc + Math.abs(i.amount), 0);
        const netChange = totalIncome - totalExpense;

        const account = accounts.value.find(a => a.id === concileModal.targetAccount);
        if (account) {
            const newBalance = (Number(account.current_balance) || 0) + netChange;
            await supabase.from('finance_accounts').update({ current_balance: newBalance }).eq('id', concileModal.targetAccount);
        }

        appStore.showSnackbar(`Conciliação Concluída! ${successCount} lançamentos efetivados e vinculados.`, 'success');
        concileModal.show = false;
        fetchAccounts();

    } catch (e: any) {
        appStore.showSnackbar('Erro na Importação: ' + e.message, 'error');
    } finally {
        concileModal.processing = false;
    }
};

onMounted(() => {
    fetchAccounts();
    fetchCompanies();
    setupRealtime();
});
onUnmounted(() => {
    if (realtimeChannel) supabase.removeChannel(realtimeChannel);
});
</script>

<style scoped lang="scss">
/* Tipografia e Utilidades */
.font-mono { font-family: 'Courier New', Courier, monospace; letter-spacing: -0.5px; }
.tracking-tight { letter-spacing: -0.02em; }
.tracking-wider { letter-spacing: 0.05em; }
.ls-1 { letter-spacing: 1px !important; }
.lh-1 { line-height: 1; }
.letter-spacing-tight { letter-spacing: -0.5px; }
.outline-none { outline: none; }
.clean-input { border: none; background: transparent; color: inherit; outline: none; }
.text-wrap-clamp { white-space: normal; word-break: break-word; display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; line-height: 1.3; }

/* Helpers de Posicionamento */
.translate-middle-xy { transform: translate(-50%, -50%); }

/* Scrollbar Customizada */
.custom-scrollbar::-webkit-scrollbar, .custom-scroll::-webkit-scrollbar { width: 8px; height: 8px; }
.custom-scrollbar::-webkit-scrollbar-track, .custom-scroll::-webkit-scrollbar-track { background: transparent; }
.custom-scrollbar::-webkit-scrollbar-thumb, .custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.35); border-radius: 6px; }

/* Backgrounds e Glassmorphism */
.bg-glass-dark { background: rgba(10,10,12,0.85); }
.bg-glass-header { background: rgba(20,20,24,0.55); backdrop-filter: blur(14px); }
.background-carousel-wrapper { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 0; opacity: 0.6; pointer-events: none; }
.background-overlay { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 1; background: radial-gradient(circle at center, rgba(15, 15, 19, 0.4), rgba(15, 15, 19, 0.98)); backdrop-filter: blur(8px); }
.glass-card { background: rgba(30, 30, 35, 0.45); backdrop-filter: blur(25px); border: 1px solid rgba(255,255,255,0.08); }
.border-white-05 { border-color: rgba(255,255,255,0.05) !important; }
.border-white-10 { border-color: rgba(255,255,255,0.1) !important; }
.border-white-20 { border-color: rgba(255,255,255,0.2) !important; }
.bg-white-20 { background-color: rgba(255,255,255,0.2) !important; }
.backdrop-blur { backdrop-filter: blur(8px); }

/* Modais e UI de Transferência */
.transfer-flow-container { border-style: dashed; }
.input-lg :deep(.v-field__input) { font-size: 1.5rem !important; height: 56px !important; padding-top: 10px; }

/* OTP e PIN */
.bg-pattern-lock { background-image: radial-gradient(rgba(0,0,0,0.05) 1px, transparent 1px); background-size: 20px 20px; }
.bg-grey-darken-4 .bg-pattern-lock { background-image: radial-gradient(rgba(255,255,255,0.05) 1px, transparent 1px); }
.secure-otp :deep(input) { font-size: 24px !important; font-weight: 900 !important; color: #b71c1c; }

/* KPIs */
.kpi-card { color: white; position: relative; min-height: 110px; overflow: hidden; border-radius: 12px; }
.kpi-bg-icon { position: absolute; right: -20px; bottom: -20px; opacity: 0.15; transform: rotate(-15deg); }
.kpi-bg-icon .v-icon { font-size: 100px; color: white; }
.kpi-label { font-size: 12px; font-weight: 900; letter-spacing: .2px; text-transform: uppercase; }
.kpi-value { font-size: 26px; font-weight: 900; line-height: 1; }
.kpi-footer { font-size: 11px; opacity: .9; font-weight: 700; }
.bg-gradient-info { background: linear-gradient(135deg, #0288d1, #005b9f); }
.bg-gradient-green { background: linear-gradient(135deg, #2e7d32, #1b5e20); }
.bg-gradient-purple { background: linear-gradient(135deg, #7b1fa2, #4a148c); }

/* Botões e Chips 3D */
.btn-3d {
    border-radius: 6px !important;
    box-shadow: 0 3px 5px rgba(0,0,0,0.15), inset 0 2px 0 rgba(255,255,255,0.25) !important;
    transition: transform 0.1s ease, box-shadow 0.1s ease;
    text-transform: none !important;
}
.btn-3d:active { transform: translateY(2px); box-shadow: 0 1px 2px rgba(0,0,0,0.15), inset 0 1px 0 rgba(255,255,255,0.2) !important; }
.chip-3d { border-radius: 6px !important; box-shadow: 0 3px 5px rgba(0,0,0,0.12), inset 0 1px 0 rgba(255,255,255,0.25) !important; text-shadow: 0 1px 2px rgba(0,0,0,0.25); }
.btn-rect { border-radius: 0 !important; }

/* GRID SYSTEM */
.grid-table { display: flex; flex-direction: column; width: 100%; }
.grid-header, .grid-row { display: grid; align-items: stretch; width: 100%; }
.cell { padding: 8px 12px; display: flex; align-items: center; border-right: 1px solid rgba(0,0,0,0.08); border-bottom: 1px solid rgba(0,0,0,0.08); overflow: hidden; transition: background-color 0.2s ease; }
.grid-header .cell { min-height: 44px; font-size: 11px; font-weight: 900; text-transform: uppercase; color: inherit; }
.center { justify-content: center; text-align: center; }
.right { justify-content: flex-end; text-align: right; }

/* Grid Dark/Light Modes */
.grid-surface-light .cell { background: #f5f7fa; color: rgba(0,0,0,0.9); border-color: rgba(0,0,0,0.12) !important; }
.grid-surface-dark .cell { background: rgba(255,255,255,0.08); color: rgba(255,255,255,0.95); border-color: rgba(255,255,255,0.1) !important; }
.grid-row-light .cell { border-color: rgba(0,0,0,0.08) !important; }
.grid-row-dark .cell { border-color: rgba(255,255,255,0.08) !important; color: rgba(255,255,255,0.85); }

.zebra-light-a .cell { background: #ffffff; }
.zebra-light-b .cell { background: #f8fafc; }
.zebra-dark-a .cell { background: rgba(255,255,255,0.04); }
.zebra-dark-b .cell { background: rgba(255,255,255,0.015); }
.hover-bg:hover .cell { background-color: rgba(var(--v-theme-on-surface), 0.05) !important; }

.list-text-11 { font-size: 14px !important; line-height: 1.2 !important; }
.solid-chip { display: inline-flex; align-items: center; justify-content: center; height: 26px; padding: 0 12px; border-radius: 4px; font-size: 10px !important; font-weight: 900; color: #fff; text-transform: uppercase; white-space: nowrap; }
.chip-success { background: #2e7d32; }
.chip-warn { background: #f57f17; }

.sticky-head { position: sticky; top: 0; z-index: 20; box-shadow: 0 4px 10px rgba(0, 0, 0, 0.08); }

.actions-inline { display: flex; gap: 6px; justify-content: center; flex-wrap: nowrap !important; }
.action-btn { width: 30px !important; height: 30px !important; border-radius: 6px !important; color: #fff !important; }
.action-edit { background: #1976d2 !important; }
.action-revert { background: #f57f17 !important; }
.action-del { background: #c62828 !important; }

.controls-bar { border: 1px solid rgba(0,0,0,0.08); padding: 10px; border-radius: 8px; margin-bottom: 12px; }
.search-wrap { height: 40px; padding: 0 12px; border: 1px solid rgba(0,0,0,0.08); border-radius: 6px; background: white; }
.search-dark { background: rgba(255,255,255,0.1); border-color: rgba(255,255,255,0.2); color: white; }

/* Real-time BLUR e Loadings */
.position-relative { position: relative !important; }
.revalidating-overlay {
    position: absolute; top: 0; left: 0; right: 0; bottom: 0;
    background: rgba(255,255,255,0.75); backdrop-filter: blur(4px); z-index: 10;
    display: flex; flex-direction: column; align-items: center; justify-content: center; border-radius: inherit;
}
.bg-grey-darken-4 .revalidating-overlay { background: rgba(0,0,0,0.75); }

/* Animações e Destaques */
.pulse-icon { animation: pulse-scale 2s infinite; }
.pulse-success { animation: pulse-success-scale 2s infinite; }
@keyframes pulse-scale { 0% { transform: scale(1); opacity: 0.8; } 50% { transform: scale(1.1); opacity: 1; } 100% { transform: scale(1); opacity: 0.8; } }
@keyframes pulse-success-scale { 0% { transform: scale(1); opacity: 0.8; color: #4CAF50; } 50% { transform: scale(1.15); opacity: 1; color: #00E676; } 100% { transform: scale(1); opacity: 0.8; color: #4CAF50; } }

/* Cores das Linhas do Extrato */
.bg-green-soft { background-color: rgba(76, 175, 80, 0.08); }
.bg-red-soft { background-color: rgba(244, 67, 54, 0.08); }
.border-l-4-green { border-left: 4px solid #2e7d32 !important; }
.border-l-4-red { border-left: 4px solid #c62828 !important; }

/* Upload Drag and Drop */
.dropzone { border: 2px dashed rgba(var(--v-theme-primary), 0.5); transition: all 0.3s ease; }
.dropzone:hover { border-color: rgb(var(--v-theme-primary)); background-color: rgba(var(--v-theme-primary), 0.05); }

.bg-white-50 { background-color: rgba(255, 255, 255, 0.5) !important; }
</style>
