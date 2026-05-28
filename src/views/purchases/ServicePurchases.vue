<template>
  <div
    class="receivables-layout font-sans fill-height d-flex flex-column relative overflow-hidden"
    :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 text-grey-darken-4' : 'bg-glass-dark text-white'"
  >
    <div class="content-wrapper d-flex flex-column fill-height z-10 relative">
      <div
        class="header-bar px-4 py-3 px-md-6 py-md-4 d-flex flex-column flex-md-row align-md-start justify-space-between flex-shrink-0"
        :class="themeStore.currentMode === 'light' ? 'bg-white border-b border-grey-lighten-2 shadow-sm' : 'bg-glass-header border-bottom-white-05'"
        style="gap: 12px;"
      >
        <div class="d-flex flex-column" style="max-width: calc(100vw - 32px);">
          <div class="breadcrumb text-body-2 d-none d-md-block">
            <span class="opacity-70">Compras</span><span class="mx-2 opacity-50">></span><span class="font-weight-bold">Contratação de Serviços</span>
          </div>
          <div class="d-flex align-center gap-2 mt-1">
             <div class="text-h5 font-weight-black tracking-tight leading-none">Gestão de Serviços</div>
          </div>

          <div class="d-flex align-center gap-3 mt-3 overflow-x-auto hide-scrollbar pb-1 w-100">
             <v-btn
                v-for="btn in contextButtons"
                :key="btn.id"
                size="x-small"
                height="24"
                :variant="companyStore.context === btn.id ? 'flat' : 'tonal'"
                :color="companyStore.context === btn.id ? (btn.isHolding ? 'purple' : 'info') : 'grey'"
                class="font-weight-bold btn-3d px-3 rounded-pill flex-shrink-0"
                style="font-size: 10px; letter-spacing: 0.5px;"
                @click="setCompanyFilter(btn.id)"
             >
                {{ btn.name }}
             </v-btn>
          </div>
        </div>

        <div class="d-none d-md-flex align-center overflow-x-auto pb-1 pb-md-0 mt-3 mt-md-0" style="gap: 10px;">
          <v-btn v-if="canCreateEdit" color="info" variant="flat" class="btn-3d px-6 font-weight-bold text-body-2 text-uppercase letter-spacing-1 shadow-button" prepend-icon="mdi-handshake" height="44" @click="openNewServiceModal">
             Novo Serviço
          </v-btn>
        </div>
      </div>

<div class="px-4 px-md-6 py-3 flex-shrink-0 border-b d-flex flex-wrap align-center justify-space-between shadow-sm z-10" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-glass-dark'" style="gap: 16px;">

          <div class="d-flex align-center flex-grow-1" style="max-width: 400px;">
              <v-text-field
                  v-model="filters.search"
                  label="Buscar Serviço, Cód ou Prestador..."
                  prepend-inner-icon="mdi-magnify"
                  variant="outlined"
                  density="compact"
                  :bg-color="themeStore.currentMode === 'light' ? 'grey-lighten-4' : 'grey-darken-4'"
                  class="ui-field"
                  hide-details
                  clearable
              ></v-text-field>
          </div>

          <div class="d-flex align-center gap-3">
              <v-menu :close-on-content-click="false" location="bottom end">
                  <template v-slot:activator="{ props }">
                      <v-btn color="primary" variant="outlined" v-bind="props" prepend-icon="mdi-filter-variant" class="btn-3d font-weight-bold" height="40">
                          Filtros
                          <v-icon end size="small">mdi-chevron-down</v-icon>
                      </v-btn>
                  </template>
                  <v-card class="pa-5 rounded-lg shadow-xl border-thin" min-width="380" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-grey-darken-4'">
                      <div class="text-h6 font-weight-black mb-4 text-primary d-flex align-center gap-2">
                          <v-icon>mdi-filter-outline</v-icon> Filtrar Serviços
                      </div>
                      <v-text-field v-model="filters.startDate" label="Data Inicial" type="date" variant="outlined" density="comfortable" class="mb-3 ui-field" hide-details></v-text-field>
                      <v-text-field v-model="filters.endDate" label="Data Final" type="date" variant="outlined" density="comfortable" class="mb-3 ui-field" hide-details></v-text-field>
                      <v-autocomplete v-model="filters.supplier" :items="auxData.suppliers" item-title="name" item-value="id" label="Filtrar por Prestador" variant="outlined" density="comfortable" class="mb-3 ui-field" hide-details clearable></v-autocomplete>
                      <v-select v-model="filters.status" :items="['Todos', 'aguardando_aprovacao', 'aprovado', 'concluido', 'rejeitado']" label="Status" variant="outlined" density="comfortable" class="mb-5 ui-field" hide-details></v-select>
                      <v-btn color="info" block variant="flat" height="48" class="font-weight-bold btn-3d text-body-1" @click="fetchPurchases">Aplicar Filtros</v-btn>
                  </v-card>
              </v-menu>

              <v-menu location="bottom end">
                  <template v-slot:activator="{ props }">
                      <v-btn
                          v-bind="props"
                          color="blue-darken-3"
                          variant="flat"
                          class="btn-3d font-weight-bold"
                          prepend-icon="mdi-file-chart"
                          height="40"
                      >
                          Relatórios
                          <v-icon end size="small">mdi-chevron-down</v-icon>
                      </v-btn>
                  </template>
                  <v-list density="compact" nav class="rounded-lg shadow-xl border-thin" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-grey-darken-4'">
                      <v-list-item @click="exportListToPDF" prepend-icon="mdi-file-pdf-box" title="Exportar PDF" :class="themeStore.currentMode === 'light' ? 'text-red-darken-3' : 'text-red-lighten-1'" class="font-weight-bold rounded-sm"></v-list-item>
                      <v-list-item @click="exportToExcel" prepend-icon="mdi-microsoft-excel" title="Exportar Excel" :class="themeStore.currentMode === 'light' ? 'text-green-darken-3' : 'text-green-lighten-1'" class="font-weight-bold rounded-sm"></v-list-item>
                  </v-list>
              </v-menu>
          </div>
      </div>

      <div class="flex-grow-1 overflow-hidden d-flex flex-column transition-all px-4 px-md-6 py-4">
        <v-card class="flex-grow-1 d-flex flex-column rounded-0 border-thin overflow-hidden" :class="themeStore.currentMode === 'light' ? 'bg-white shadow-sm' : 'glass-card border-white-05'" :elevation="0">
          <div class="grid-scroll flex-grow-1 overflow-auto custom-scroll relative">

            <div class="grid-header sticky-head border-b" :class="[themeStore.currentMode === 'light' ? 'grid-surface-light' : 'grid-surface-dark']" :style="{ gridTemplateColumns: gridCols, minWidth: minGridWidth }">
              <div class="cell center header-text">Cód.</div>
              <div class="cell header-text">Prestador</div>
              <div class="cell header-text">Descrição do Serviço</div>
              <div class="cell header-text">Solicitante</div>
              <div class="cell header-text text-error">Motivo Rejeição</div>
              <div class="cell center header-text">Emissão</div>
              <div class="cell center header-text">Aprovação</div>
              <div class="cell center header-text">Status Execução</div>
              <div class="cell center header-text">Valor Total</div>
              <div class="cell center header-text" v-if="canApprove">Financeiro</div>
              <div class="cell center header-text">Anexos</div>
              <div class="cell center header-text">Ações</div>
            </div>

            <div v-if="loadingPurchases" class="d-flex flex-column justify-center align-center h-100 py-10 min-w-full">
              <v-progress-circular indeterminate color="info" size="48" width="4"></v-progress-circular>
            </div>

            <div v-else-if="filteredPurchases.length === 0" class="d-flex flex-column justify-center align-center h-100 py-10 min-w-full opacity-60">
              <v-icon size="64">mdi-handshake-outline</v-icon>
              <span class="text-body-1 mt-4 font-weight-bold">Nenhum serviço registrado para os filtros selecionados.</span>
            </div>

            <div v-else v-for="(item, index) in filteredPurchases" :key="item.id" class="grid-row" :class="[themeStore.currentMode === 'light' ? 'grid-row-light' : 'grid-row-dark', zebraClass(index)]" :style="{ gridTemplateColumns: gridCols, minWidth: minGridWidth }">
                <div class="cell center">
                    <span class="pill-ref bg-grey-lighten-4 text-grey-darken-4 font-weight-black">
                        #{{ formatCode(item) }}
                    </span>
                </div>

                <div class="cell">
                    <span class="font-weight-medium text-grey-darken-4 text-truncate w-100" style="font-size: 14px;">{{ item.supplier_name || item.entity_name }}</span>
                </div>

                <div class="cell">
                    <span class="text-grey-darken-3 text-truncate w-100" style="font-size: 13px;">{{ item.description }}</span>
                </div>

                <div class="cell">
                    <span class="text-grey-darken-2 text-truncate w-100 font-weight-medium d-flex align-center" style="font-size: 13px;" :title="item.created_by_name || 'Desconhecido'">
                        <v-icon size="14" class="mr-1 opacity-60">mdi-account-circle</v-icon>
                        {{ item.created_by_name || 'Desconhecido' }}
                    </span>
                </div>

                <div class="cell">
                    <span v-if="item.production_status === 'rejeitado'" class="text-error font-weight-black text-truncate w-100 d-flex align-center" style="font-size: 13px;" :title="getRejectionReason(item)">
                        <v-icon size="14" class="mr-1">mdi-alert-circle</v-icon>
                        {{ getRejectionReason(item) }}
                    </span>
                    <span v-else class="text-grey opacity-40 font-weight-bold">-</span>
                </div>

                <div class="cell center">
                    <span class="font-mono font-weight-medium text-grey-darken-4" style="font-size: 14px;">{{ formatDateSafe(item.order_date) }}</span>
                </div>

                <div class="cell center">
                    <v-chip
                        size="default"
                        :color="item.production_status === 'rejeitado' ? 'error' : (item.production_status === 'aguardando_aprovacao' ? 'warning' : 'success')"
                        variant="flat"
                        class="font-weight-bold text-uppercase px-3 chip-3d"
                        :class="canApprove && item.production_status === 'aguardando_aprovacao' ? 'cursor-pointer hover-elevate' : ''"
                        style="font-size: 11px; height: 28px;"
                        @click="canApprove && item.production_status === 'aguardando_aprovacao' ? openApprovalModal(item) : null"
                    >
                        {{ item.production_status === 'rejeitado' ? 'REJEITADO' : (item.production_status === 'aguardando_aprovacao' ? 'PENDENTE' : 'APROVADO') }}
                    </v-chip>
                </div>

                <div class="cell center">
                    <v-chip
                        v-if="item.production_status !== 'aguardando_aprovacao' && item.production_status !== 'rejeitado'"
                        :color="getStatusColor(item.production_status)"
                        variant="flat"
                        class="font-weight-bold text-white text-uppercase px-3 cursor-pointer hover-elevate chip-3d"
                        style="font-size: 11px; height: 28px;"
                        @click.stop="openStatusModal(item)"
                    >
                        {{ formatStatus(item.production_status) }}
                    </v-chip>
                    <span v-else class="text-grey opacity-40 text-caption font-weight-bold">-</span>
                </div>

                <div class="cell center">
                    <span class="font-mono font-weight-black text-info-darken-3" style="font-size: 14px;">{{ formatCurrency(item.total_value) }}</span>
                </div>

                <div class="cell center" v-if="canApprove">
                    <v-chip size="small" variant="flat" :color="item.finance_payable_id ? 'success' : 'grey'" class="font-weight-bold chip-3d text-white" style="font-size: 10px;">
                        {{ item.finance_payable_id ? 'LANÇADO' : 'NÃO LANÇADO' }}
                    </v-chip>
                </div>

                <div class="cell center">
                    <v-btn icon size="small" variant="flat" color="primary" class="btn-3d" @click.stop="openAttachmentModal(item)">
                        <v-badge :content="item.attachments?.length || 0" color="error" :model-value="(item.attachments?.length || 0) > 0" offset-x="-5" offset-y="-5">
                            <v-icon size="18">mdi-paperclip</v-icon>
                        </v-badge>
                    </v-btn>
                </div>

                <div class="cell center">
                    <div class="actions-inline d-flex flex-nowrap w-100 justify-center">
                        <v-btn v-if="canCreateEdit && (item.production_status === 'aguardando_aprovacao' || canApprove)" icon size="small" class="action-btn btn-3d action-edit" @click.stop="openEditModal(item)" title="Editar" variant="flat"><v-icon size="16">mdi-pencil</v-icon></v-btn>

                        <v-btn v-if="canCreateEdit" icon size="small" class="action-btn btn-3d bg-info" @click.stop="cloneService(item)" title="Clonar Serviço" variant="flat"><v-icon size="16">mdi-content-copy</v-icon></v-btn>

                        <v-btn
                            icon
                            size="small"
                            class="action-btn btn-3d"
                            :class="canPrintService(item) ? 'bg-grey-darken-3 text-white' : 'bg-grey-lighten-2 text-grey-darken-1'"
                            @click.stop="printService(item)"
                            :title="canPrintService(item) ? 'Imprimir Serviço' : 'Aprovação pendente para imprimir'"
                            variant="flat"
                            :disabled="!canPrintService(item)"
                        >
                            <v-icon size="16">mdi-printer</v-icon>
                        </v-btn>

                        <v-menu v-if="canApprove || canDelete" location="bottom end" transition="scale-transition">
                            <template v-slot:activator="{ props }">
                                <v-btn v-bind="props" icon size="small" class="action-btn btn-3d bg-success text-white ml-1" variant="flat" title="Mais Opções"><v-icon size="16">mdi-chevron-down</v-icon></v-btn>
                            </template>
                            <v-list density="comfortable" nav class="bg-white border-thin shadow-sm rounded-0" width="220">
                                <v-list-item v-if="canApprove" @click="openDetailsModal(item)" prepend-icon="mdi-magnify" base-color="info" title="Auditoria e Detalhes" class="font-weight-bold text-body-2"></v-list-item>

                                <v-menu location="start" open-on-hover submenu>
                                    <template v-slot:activator="{ props: menuProps }">
                                        <v-list-item v-bind="menuProps" prepend-icon="mdi-share-variant" title="Compartilhar" append-icon="mdi-menu-right" class="font-weight-bold text-body-2"></v-list-item>
                                    </template>
                                    <v-list density="comfortable" nav class="bg-white border-thin shadow-sm rounded-0">
                                        <v-list-item @click="shareService(item, 'whatsapp')" prepend-icon="mdi-whatsapp" base-color="success" title="Via WhatsApp" class="font-weight-bold text-body-2"></v-list-item>
                                        <v-list-item @click="shareService(item, 'email')" prepend-icon="mdi-email" base-color="error" title="Via E-mail" class="font-weight-bold text-body-2"></v-list-item>
                                    </v-list>
                                </v-menu>

                                <v-divider class="my-2" v-if="canDelete"></v-divider>
                                <v-list-item v-if="canDelete" @click="deletePurchase(item.id)" prepend-icon="mdi-trash-can-outline" base-color="error" title="Excluir Definitivo" class="font-weight-bold text-body-2" :disabled="!!item.finance_payable_id"></v-list-item>
                            </v-list>
                        </v-menu>
                    </div>
                </div>
            </div>
          </div>
        </v-card>
      </div>
    </div>

    <v-dialog v-model="modal.show" max-width="1500" persistent scrollable transition="dialog-bottom-transition">
        <v-card class="d-flex flex-column rounded-0 bg-grey-lighten-4 h-100" style="max-height: 95vh;">
            <div class="px-6 py-5 bg-info text-white d-flex align-center justify-space-between flex-shrink-0 elevation-2 z-10 relative">
                <div class="d-flex align-center gap-4">
                    <div class="bg-white-20 rounded-0 d-flex align-center justify-center" style="width: 48px; height: 48px;"><v-icon size="28" color="white">{{ modal.form.id ? 'mdi-file-document-edit' : 'mdi-handshake' }}</v-icon></div>
                    <div>
                        <div class="text-h5 font-weight-black leading-tight">{{ modal.form.id ? 'Editando Serviço' : 'Contratação de Novo Serviço' }}</div>
                        <div class="text-caption font-weight-medium opacity-90">Especifique o prestador, escopo e condições para envio à diretoria.</div>
                    </div>
                </div>
                <v-btn icon="mdi-close" variant="text" color="white" size="large" @click="modal.show = false"></v-btn>
            </div>

            <v-card-text class="pa-6 custom-scroll d-flex flex-column gap-6">
                <v-form ref="purchaseForm">
                    <v-card variant="outlined" class="bg-white rounded-0 border-thin overflow-hidden shadow-sm">
                        <div class="bg-grey-lighten-4 border-b px-5 py-3 d-flex align-center gap-2">
                            <v-icon size="20" color="info">mdi-domain</v-icon>
                            <span class="text-subtitle-2 font-weight-black text-uppercase text-grey-darken-3 tracking-wide">Dados da Contratação e Prestador</span>
                        </div>
                        <div class="pa-5">
                            <v-row dense class="row-gap">
                                <v-col cols="12" md="6"><v-text-field v-model="modal.form.description" label="Descrição Principal do Serviço*" variant="outlined" density="comfortable" color="info" class="ui-field font-weight-bold" placeholder="Ex: Manutenção Ar Condicionado"></v-text-field></v-col>
                                <v-col cols="12" md="6">
                                    <v-autocomplete v-model="modal.form.supplier_id" :items="auxData.suppliers" item-title="name" item-value="id" label="Selecione o Prestador/Fornecedor*" variant="outlined" density="comfortable" color="info" class="ui-field">
                                        <template v-slot:prepend-item><v-list-item title="Cadastrar Novo Prestador Rápido" prepend-icon="mdi-plus-circle" class="text-info font-weight-black bg-blue-lighten-5" @click="openQuickSupplierModal"></v-list-item><v-divider class="my-2"></v-divider></template>
                                    </v-autocomplete>
                                </v-col>

                                <v-col cols="12" md="4">
                                    <v-autocomplete
                                        v-model="modal.form.company_id"
                                        :items="auxData.companies"
                                        item-title="trade_name"
                                        item-value="id"
                                        label="Empresa Vinculada (Tenant)*"
                                        variant="outlined"
                                        density="comfortable"
                                        color="info"
                                        class="ui-field font-weight-bold"
                                        :disabled="!isAdmin"
                                        :readonly="!isAdmin"
                                        :hint="!isAdmin ? 'Empresa atrelada automaticamente ao seu usuário' : ''"
                                        persistent-hint
                                    ></v-autocomplete>
                                </v-col>

                                <v-col cols="12" md="4"><v-autocomplete v-model="modal.form.chart_of_accounts_id" :items="auxData.chartOfAccounts" item-title="name" item-value="id" label="Plano de Contas (Despesa)" variant="outlined" density="comfortable" color="info" class="ui-field" clearable></v-autocomplete></v-col>
                                <v-col cols="12" md="2"><v-text-field v-model="modal.form.order_date" label="Data de Emissão*" type="date" variant="outlined" density="comfortable" color="info" class="ui-field font-weight-bold"></v-text-field></v-col>
                                <v-col cols="12" md="2"><v-text-field v-model="modal.form.delivery_date" label="Previsão Entrega*" type="date" variant="outlined" density="comfortable" color="info" class="ui-field font-weight-bold"></v-text-field></v-col>
                            </v-row>
                        </div>
                    </v-card>

                    <v-card variant="outlined" class="bg-white rounded-0 border-thin overflow-hidden shadow-sm mt-6">
                        <div class="bg-grey-lighten-4 border-b px-5 py-3 d-flex align-center justify-space-between">
                            <div class="d-flex align-center gap-2"><v-icon size="20" color="info">mdi-format-list-bulleted</v-icon><span class="text-subtitle-2 font-weight-black text-uppercase text-grey-darken-3 tracking-wide">Escopo do Serviço</span></div>
                            <v-chip color="info" size="default" variant="flat" class="font-weight-black px-4 chip-3d">{{ modal.items.length }} Itens Adicionados</v-chip>
                        </div>
                        <div class="pa-5 bg-white border-b border-opacity-50">
                            <v-row dense align="center" class="row-gap">
                                <v-col cols="12" md="4">
                                    <v-autocomplete v-model="currentItem.service_id" :items="auxData.services" item-title="name" item-value="id" label="Buscar Serviço Frequente (Catálogo)" variant="outlined" density="comfortable" hide-details color="info" class="ui-field font-weight-bold" @update:model-value="onServiceSelect" clearable>
                                        <template v-slot:prepend-item><v-list-item title="Cadastrar no Catálogo de Serviços" prepend-icon="mdi-plus-circle" class="text-primary font-weight-black bg-blue-lighten-5" @click="openQuickServiceModal"></v-list-item><v-divider class="my-2"></v-divider></template>
                                    </v-autocomplete>
                                </v-col>
                                <v-col cols="12" md="3" v-if="!currentItem.service_id"><v-text-field v-model="currentItem.description" label="Descrição do Serviço Avulso*" variant="outlined" density="comfortable" hide-details class="ui-field"></v-text-field></v-col>
                                <v-col cols="4" md="1"><v-select v-model="currentItem.unit_of_measure" :items="['un', 'm', 'kg', 'g', 'l', 'cx', 'par', 'pct', 'hr', 'sv']" label="UN*" variant="outlined" density="comfortable" hide-details color="info" class="ui-field font-weight-bold text-center"></v-select></v-col>
                                <v-col cols="4" md="1"><v-text-field v-model.number="currentItem.quantity" label="Qtd.*" type="number" min="1" variant="outlined" density="comfortable" hide-details class="ui-field font-weight-bold text-center" @input="calcCurrentTotal"></v-text-field></v-col>
                                <v-col cols="4" md="1"><v-text-field v-model.number="currentItem.unit_price" label="V. Unit.*" type="number" step="0.01" variant="outlined" density="comfortable" hide-details class="ui-field font-weight-bold text-info-darken-2" prefix="R$" @input="calcCurrentTotal"></v-text-field></v-col>
                                <v-col cols="12" md="2" class="d-flex justify-end"><v-btn color="blue-darken-3" variant="flat" height="48" class="btn-3d w-100 font-weight-bold text-body-2" @click="addItemToList" :disabled="!isCurrentItemValid"><v-icon start size="20">mdi-plus-thick</v-icon> Adicionar</v-btn></v-col>
                            </v-row>
                        </div>

                        <div class="overflow-auto custom-scroll" style="min-height: 250px; max-height: 400px;">
                            <div class="grid-header sticky-head grid-surface-light border-b" style="grid-template-columns: 60px 2fr 80px 100px 140px 140px 160px; min-width: 900px;">
                                <div class="cell center header-text">Seq.</div><div class="cell header-text">Descrição do Serviço Contratado</div><div class="cell center header-text">UN</div><div class="cell center header-text">Qtd</div><div class="cell center header-text">Valor Unit.</div><div class="cell center header-text text-info-darken-3">Subtotal</div><div class="cell center header-text">Ações</div>
                            </div>
                            <div v-if="modal.items.length === 0" class="d-flex flex-column justify-center align-center py-12 opacity-40 bg-grey-lighten-5 h-100 min-w-full">
                                <v-icon size="48" class="mb-3">mdi-tools</v-icon>
                                <span class="text-body-2 font-weight-bold">A lista de escopo está vazia.</span>
                            </div>
                            <div v-else v-for="(item, index) in modal.items" :key="item.ui_id" class="grid-row" :class="zebraClass(index)" style="grid-template-columns: 60px 2fr 80px 100px 140px 140px 160px; min-width: 900px;">
                                <div class="cell center font-weight-black text-grey-darken-1" style="font-size: 15px;">{{ index + 1 }}</div>
                                <div class="cell"><div class="d-flex flex-column justify-center w-100 py-1"><span class="font-weight-medium text-grey-darken-4 text-truncate mb-1" style="font-size: 15px;">{{ item.service_name || item.description }}</span><v-chip v-if="item.service_id" size="small" color="info" variant="tonal" class="font-weight-bold px-3 align-self-start chip-3d"><v-icon start size="14">mdi-link</v-icon> CATÁLOGO</v-chip></div></div>
                                <div class="cell center"><span class="font-weight-bold text-grey-darken-3 text-uppercase" style="font-size: 14px;">{{ item.unit_of_measure || 'SV' }}</span></div>
                                <div class="cell center"><span class="font-mono font-weight-medium text-grey-darken-4" style="font-size: 15px;">{{ item.quantity }}</span></div>
                                <div class="cell center"><span class="font-mono font-weight-medium text-grey-darken-4" style="font-size: 15px;">{{ formatCurrencyValue(item.unit_price) }}</span></div>
                                <div class="cell center bg-light-blue-lighten-5"><span class="font-mono font-weight-black text-info-darken-3" style="font-size: 15px;">{{ formatCurrency(item.total_price) }}</span></div>
                                <div class="cell center"><div class="actions-inline d-flex flex-nowrap"><v-btn icon size="small" class="action-btn btn-3d bg-blue-grey-lighten-4 text-blue-grey-darken-3" @click="cloneItem(item)" title="Duplicar Item" variant="flat"><v-icon size="16">mdi-content-copy</v-icon></v-btn><v-btn icon size="small" class="action-btn btn-3d action-edit" @click="editItem(index)" title="Editar" variant="flat"><v-icon size="16">mdi-pencil</v-icon></v-btn><v-btn icon size="small" class="action-btn btn-3d action-del" @click="removeItem(index)" title="Excluir" variant="flat"><v-icon size="16">mdi-close-thick</v-icon></v-btn></div></div>
                            </div>
                        </div>
                        <div class="pa-5 bg-grey-lighten-3 border-t d-flex justify-end align-center shadow-inner">
                            <div class="d-flex align-center gap-4 bg-white px-6 py-3 rounded-0 elevation-1 border-thin border-info"><span class="text-body-2 font-weight-black text-uppercase text-grey-darken-2">Valor Total do Serviço:</span><span class="text-h5 font-weight-black text-info-darken-3 tabular-nums">{{ formatCurrency(purchaseTotalValue) }}</span></div>
                        </div>
                    </v-card>

                    <v-card variant="outlined" class="bg-white rounded-0 border-thin overflow-hidden shadow-sm mt-6">
                        <div class="bg-grey-lighten-4 border-b px-5 py-3 d-flex align-center gap-2"><v-icon size="20" color="info">mdi-cash-multiple</v-icon><span class="text-subtitle-2 font-weight-black text-uppercase text-grey-darken-3 tracking-wide">Condições de Pagamento</span></div>
                        <div class="pa-5">
                            <v-row dense class="row-gap">
                                <v-col cols="12" md="4"><v-select v-model="modal.payment.method" :items="['Boleto Bancário', 'PIX', 'Cartão de Crédito', 'Transferência Bancária', 'Dinheiro']" label="Forma de Pagamento" variant="outlined" density="comfortable" color="info" class="ui-field font-weight-bold"></v-select></v-col>
                                <v-col cols="12" md="4"><v-select v-model="modal.payment.condition" :items="['À Vista', 'Parcelado']" label="Condição" variant="outlined" density="comfortable" color="info" class="ui-field font-weight-bold"></v-select></v-col>
                                <v-col cols="12" md="4" v-if="modal.payment.condition === 'Parcelado'"><v-select v-model.number="modal.payment.installments" :items="[2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]" label="Quantidade de Parcelas" variant="outlined" density="comfortable" color="info" class="ui-field font-weight-bold" @update:model-value="generateInstallments"></v-select></v-col>

                                <v-col cols="12" v-if="modal.payment.details.length > 0">
                                    <div class="border-thin rounded-0 overflow-hidden mt-2">
                                        <div class="bg-grey-lighten-4 px-4 py-2 text-caption font-weight-black text-uppercase border-b d-flex justify-space-between"><span>Detalhamento das Parcelas</span><v-btn size="small" variant="text" color="primary" class="btn-3d" @click="generateInstallments">Recalcular Valores</v-btn></div>
                                        <div class="pa-4 bg-white">
                                            <v-row dense>
                                                <v-col cols="12" md="6" v-for="(inst, idx) in modal.payment.details" :key="idx">
                                                    <div class="d-flex align-center gap-3 mb-2 bg-grey-lighten-5 pa-2 rounded-0 border">
                                                        <div class="text-body-2 font-weight-black text-grey-darken-2" style="width: 40px;">{{ idx + 1 }}x</div>
                                                        <v-text-field v-model="inst.due_date" label="Vencimento" type="date" variant="outlined" density="comfortable" hide-details class="bg-white flex-grow-1 ui-field"></v-text-field>
                                                        <v-text-field v-model.number="inst.value" label="Valor (R$)" type="number" step="0.01" variant="outlined" density="comfortable" hide-details class="bg-white flex-grow-1 font-weight-bold text-info-darken-3 ui-field"></v-text-field>
                                                    </div>
                                                </v-col>
                                            </v-row>
                                            <div class="d-flex justify-end mt-4 align-center"><span class="text-body-2 font-weight-bold mr-2 text-grey">Soma das Parcelas:</span><span class="text-h6 font-weight-black" :class="sumOfInstallments === purchaseTotalValue ? 'text-success' : 'text-error'">{{ formatCurrency(sumOfInstallments) }}</span></div>
                                        </div>
                                    </div>
                                </v-col>
                            </v-row>
                        </div>
                    </v-card>

                    <v-card variant="outlined" class="bg-white rounded-0 border-thin overflow-hidden shadow-sm mt-6 mb-4">
                        <div class="bg-grey-lighten-4 border-b px-5 py-3 d-flex align-center gap-2"><v-icon size="20" color="info">mdi-paperclip</v-icon><span class="text-subtitle-2 font-weight-black text-uppercase text-grey-darken-3 tracking-wide">Anexos Iniciais e Observações</span></div>
                        <div class="pa-5">
                            <v-row dense class="row-gap">
                                <v-col cols="12" md="6"><v-file-input v-model="modal.files" label="Anexar Arquivos (Orçamentos, PDF, IMG)" variant="outlined" density="comfortable" prepend-inner-icon="mdi-cloud-upload" color="info" multiple chips show-size class="ui-field bg-grey-lighten-5"></v-file-input></v-col>
                                <v-col cols="12" md="6"><v-textarea v-model="modal.form.notes" label="Justificativa / Motivo (Opcional)" variant="outlined" rows="3" density="comfortable" class="ui-field"></v-textarea></v-col>
                            </v-row>
                        </div>
                    </v-card>
                </v-form>
            </v-card-text>

            <div class="px-8 py-5 border-t bg-white d-flex justify-space-between align-center flex-shrink-0 elevation-10 z-10 relative">
                <div class="d-flex align-center gap-2 text-body-2 text-grey font-weight-bold bg-grey-lighten-4 px-4 py-2 rounded-0 border"><v-icon size="20">mdi-account-circle</v-icon> Solicitante: <span class="text-info-darken-2 font-weight-black">{{ userStore.profile?.full_name || userStore.user?.email }}</span></div>
                <div class="d-flex gap-3">
                    <v-btn variant="outlined" color="grey-darken-2" class="btn-3d px-8 font-weight-bold text-body-2" height="50" @click="modal.show = false" :disabled="modal.saving">Cancelar</v-btn>
                    <v-btn color="info" variant="flat" class="btn-3d px-10 font-weight-black text-body-1 shadow-button" height="50" @click="saveFullService" :loading="modal.saving"><v-icon start size="24" class="mr-2">mdi-content-save-check</v-icon> ENVIAR PARA APROVAÇÃO</v-btn>
                </div>
            </div>
        </v-card>
    </v-dialog>

    <v-dialog v-model="approvalModal.show" max-width="800" persistent transition="dialog-bottom-transition">
        <v-card class="rounded-0 overflow-hidden">
            <div class="px-6 py-5 bg-purple-darken-3 text-white d-flex align-center justify-space-between">
                <div class="d-flex align-center gap-4">
                    <v-icon size="36" color="purple-lighten-4">mdi-gavel</v-icon>
                    <div>
                        <div class="text-h5 font-weight-black leading-tight">Decisão e Lançamento Financeiro</div>
                        <div class="text-caption font-weight-medium opacity-80 mt-1">Ao aprovar, o serviço será autorizado e as obrigações geradas no Contas a Pagar.</div>
                    </div>
                </div>
                <v-btn icon="mdi-close" variant="text" size="large" @click="approvalModal.show = false"></v-btn>
            </div>

            <div class="pa-6 bg-grey-lighten-5">
                <div class="d-flex flex-wrap justify-space-between align-center mb-6 bg-white pa-5 rounded-0 border-thin shadow-sm gap-4">
                    <div>
                        <div class="text-body-2 text-uppercase font-weight-bold text-grey tracking-wide">Prestador / Serviço</div>
                        <div class="text-h6 font-weight-black text-grey-darken-4">{{ approvalModal.item?.supplier_name || approvalModal.item?.entity_name }}</div>
                        <div class="text-body-2 text-grey mt-1">Ref: {{ approvalModal.item?.description }}</div>
                    </div>
                    <v-divider vertical class="d-none d-md-flex"></v-divider>
                    <div class="text-right">
                        <div class="text-body-2 text-uppercase font-weight-bold text-grey tracking-wide">Valor Total</div>
                        <div class="text-h4 font-weight-black text-purple-darken-3 tabular-nums">{{ formatCurrency(approvalModal.item?.total_value) }}</div>
                        <div class="text-body-2 text-grey font-weight-bold mt-1">Condição: {{ approvalModal.item?.payment_details?.condition }} ({{ approvalModal.item?.payment_details?.installments || 1 }}x)</div>
                    </div>
                </div>

                <div class="text-subtitle-1 font-weight-black text-uppercase text-grey-darken-2 mb-3 d-flex align-center gap-2 mt-4">
                    <v-icon size="24" color="grey-darken-1">mdi-format-list-bulleted</v-icon> Escopo de Serviços Contratados
                </div>
                <div class="bg-white border-thin rounded-0 overflow-hidden shadow-sm mb-6">
                    <div class="grid-header bg-grey-lighten-4 border-b" style="display: grid; grid-template-columns: 60px 1fr 80px 120px 140px;">
                        <div class="cell center font-weight-bold text-body-2">Item</div>
                        <div class="cell font-weight-bold text-body-2">Descrição do Serviço</div>
                        <div class="cell center font-weight-bold text-body-2">Qtd</div>
                        <div class="cell center font-weight-bold text-body-2">V. Unitário</div>
                        <div class="cell center font-weight-bold text-body-2">Subtotal</div>
                    </div>
                    <div v-for="(purchaseItem, idx) in approvalModal.item?.purchase_items" :key="idx" class="grid-row border-b" style="display: grid; grid-template-columns: 60px 1fr 80px 120px 140px;">
                        <div class="cell center font-weight-black text-grey-darken-2" style="font-size: 15px;">{{ idx + 1 }}</div>
                        <div class="cell font-weight-medium text-body-2">{{ purchaseItem.description || purchaseItem.service_name || 'Serviço' }}</div>
                        <div class="cell center font-weight-bold">{{ purchaseItem.quantity }} {{ purchaseItem.unit_of_measure }}</div>
                        <div class="cell center font-weight-medium">{{ formatCurrencyValue(purchaseItem.unit_price) }}</div>
                        <div class="cell center font-weight-black text-info-darken-3">{{ formatCurrency(purchaseItem.total_price) }}</div>
                    </div>
                </div>

                <div class="text-subtitle-1 font-weight-black text-uppercase text-grey-darken-2 mb-3 d-flex align-center gap-2"><v-icon size="24" color="grey-darken-1">mdi-calendar-multiselect</v-icon> Cronograma Simulado que será Lançado</div>

                <div class="bg-white border-thin rounded-0 overflow-hidden shadow-sm mb-4">
                    <div class="grid-header bg-grey-lighten-4 border-b" style="display: grid; grid-template-columns: 80px 1fr 180px;">
                        <div class="cell center font-weight-bold text-body-2">Parc.</div>
                        <div class="cell font-weight-bold text-body-2">Vencimento Original</div>
                        <div class="cell center font-weight-bold text-body-2">Valor da Parcela</div>
                    </div>
                    <div v-for="(inst, idx) in approvalModal.installments" :key="idx" class="grid-row border-b" style="display: grid; grid-template-columns: 80px 1fr 180px;">
                        <div class="cell center font-weight-black text-grey-darken-2" style="font-size: 15px;">{{ idx + 1 }}/{{ approvalModal.installments.length }}</div>
                        <div class="cell font-weight-bold">{{ formatDateSafe(inst.due_date) }}</div>
                        <div class="cell center font-weight-black text-purple-darken-3">{{ formatCurrency(inst.value) }}</div>
                    </div>
                </div>

                <v-textarea v-model="approvalModal.reason" label="Motivo da Rejeição (Apenas se for Rejeitar)" variant="outlined" density="comfortable" rows="2" class="ui-field bg-white"></v-textarea>
            </div>

            <div class="pa-5 border-t d-flex justify-space-between align-center bg-white">
                <div class="text-body-2 text-grey font-weight-bold"><v-icon size="20" class="mr-1">mdi-shield-check</v-icon> Autorizador: {{ userStore.profile?.full_name }}</div>
                <div class="d-flex gap-3">
                    <v-btn color="error" variant="flat" class="btn-3d font-weight-black px-6" height="44" @click="executeRejection" :loading="approvalModal.loading"><v-icon start>mdi-close-thick</v-icon> Rejeitar Serviço</v-btn>
                    <v-btn color="purple-darken-2" variant="flat" class="btn-3d font-weight-black px-8 shadow-button" height="44" @click="executeApproval" :loading="approvalModal.loading">
                        <v-icon start size="20">mdi-check-all</v-icon> APROVAR E LANÇAR
                    </v-btn>
                </div>
            </div>
        </v-card>
    </v-dialog>

    <v-dialog v-model="detailsModal.show" max-width="1000" scrollable>
        <v-card class="rounded-0 bg-grey-lighten-4 h-100">
            <div class="px-6 py-4 bg-info text-white d-flex align-center justify-space-between flex-shrink-0">
                <div class="d-flex align-center gap-3">
                    <div class="bg-white-20 rounded-0 d-flex align-center justify-center" style="width: 40px; height: 40px;"><v-icon size="24">mdi-text-box-search-outline</v-icon></div>
                    <div>
                        <div class="text-h6 font-weight-black">Auditoria de Serviço #{{ formatCode(detailsModal.item) }}</div>
                        <div class="text-caption opacity-80">Rastreabilidade completa, informações de aprovação e financeiro.</div>
                    </div>
                </div>
                <v-btn icon="mdi-close" variant="text" @click="detailsModal.show = false"></v-btn>
            </div>

            <v-card-text class="pa-6 custom-scroll d-flex flex-column gap-6">
                <v-card variant="flat" class="bg-white border-thin pa-5 shadow-sm rounded-0">
                    <v-row>
                        <v-col cols="6" md="3"><div class="text-body-2 text-grey text-uppercase font-weight-bold">Prestador</div><div class="font-weight-black text-body-2">{{ detailsModal.item?.supplier_name || detailsModal.item?.entity_name }}</div></v-col>
                        <v-col cols="6" md="3"><div class="text-body-2 text-grey text-uppercase font-weight-bold">Data Emissão</div><div class="font-weight-black text-body-2">{{ formatDateSafe(detailsModal.item?.order_date) }}</div></v-col>
                        <v-col cols="6" md="3"><div class="text-body-2 text-grey text-uppercase font-weight-bold">Prev. Conclusão</div><div class="font-weight-black text-body-2">{{ formatDateSafe(detailsModal.item?.delivery_date) }}</div></v-col>
                        <v-col cols="6" md="3"><div class="text-body-2 text-grey text-uppercase font-weight-bold">Valor Total</div><div class="font-weight-black text-h6 text-info-darken-2 tabular-nums">{{ formatCurrency(detailsModal.item?.total_value) }}</div></v-col>
                        <v-col cols="12" md="6"><div class="text-body-2 text-grey text-uppercase font-weight-bold">Descrição do Serviço</div><div class="text-body-2">{{ detailsModal.item?.description || '-' }}</div></v-col>
                        <v-col cols="12" md="6"><div class="text-body-2 text-grey text-uppercase font-weight-bold">Status de Execução</div>
                            <v-chip size="default" :color="getStatusColor(detailsModal.item?.production_status)" class="font-weight-black text-uppercase mt-1 chip-3d" style="font-size: 12px;">{{ formatStatus(detailsModal.item?.production_status) }}</v-chip>
                        </v-col>
                    </v-row>
                </v-card>

                <v-card variant="flat" class="bg-white border-thin shadow-sm rounded-0 overflow-hidden">
                    <div class="bg-grey-lighten-4 border-b px-4 py-3 font-weight-black text-uppercase text-body-2 text-grey-darken-3 d-flex align-center gap-2"><v-icon size="20">mdi-credit-card-outline</v-icon> Informações de Pagamento</div>
                    <div class="pa-5 d-flex gap-8 flex-wrap">
                        <div><div class="text-body-2 text-grey font-weight-bold text-uppercase">Método</div><div class="font-weight-black text-body-2">{{ detailsModal.item?.payment_details?.method || '-' }}</div></div>
                        <div><div class="text-body-2 text-grey font-weight-bold text-uppercase">Condição</div><div class="font-weight-black text-body-2">{{ detailsModal.item?.payment_details?.condition || '-' }} ({{ detailsModal.item?.payment_details?.installments || 1 }}x)</div></div>
                        <div><div class="text-body-2 text-grey font-weight-bold text-uppercase">Status Financeiro</div><v-chip size="default" :color="detailsModal.item?.finance_payable_id ? 'success' : 'warning'" variant="flat" class="font-weight-bold mt-1 text-white chip-3d" style="font-size: 12px;">{{ detailsModal.item?.finance_payable_id ? 'LANÇADO NO CONTAS A PAGAR' : 'PENDENTE / NÃO APROVADO' }}</v-chip></div>
                    </div>
                </v-card>

                <v-card variant="flat" class="bg-white border-thin shadow-sm rounded-0 overflow-hidden">
                    <div class="bg-grey-lighten-4 border-b px-4 py-3 font-weight-black text-uppercase text-body-2 text-grey-darken-3 d-flex align-center gap-2"><v-icon size="20">mdi-history</v-icon> Timeline de Auditoria</div>
                    <div class="pa-5">
                        <div v-if="!detailsModal.item?.audit_log || detailsModal.item.audit_log.length === 0" class="text-center opacity-50 py-4 text-body-2">Nenhum histórico registrado além da criação.</div>
                        <v-timeline density="compact" align="start" class="ml-2" v-else>
                            <v-timeline-item v-for="(log, idx) in detailsModal.item.audit_log" :key="idx" :dot-color="getAuditColor(log.action)" size="small">
                                <div class="mb-1">
                                    <strong class="text-body-2 font-weight-black">{{ log.action }}</strong>
                                    <span class="text-caption text-grey ml-2">{{ formatDateTimeSafe(log.date) }}</span>
                                </div>
                                <div class="text-body-2 text-grey-darken-2 mb-1">{{ log.details }}</div>
                                <div class="text-caption font-weight-bold text-primary"><v-icon size="16">mdi-account</v-icon> {{ log.user }}</div>
                            </v-timeline-item>
                        </v-timeline>
                    </div>
                </v-card>
            </v-card-text>
        </v-card>
    </v-dialog>

    <v-dialog v-model="attachmentModal.show" max-width="500">
        <v-card class="rounded-0 border-t-lg border-t-primary">
            <div class="px-6 py-4 bg-white border-b d-flex justify-space-between align-center">
                <div class="d-flex align-center gap-3">
                    <v-icon size="28" color="primary">mdi-paperclip</v-icon>
                    <span class="text-h6 font-weight-black text-primary">Anexos do Serviço</span>
                </div>
                <v-btn icon="mdi-close" variant="text" @click="attachmentModal.show = false"></v-btn>
            </div>
            <div class="pa-6">
                <div v-if="attachmentModal.item?.attachments?.length > 0" class="mb-4">
                    <div class="text-caption font-weight-bold mb-2 text-uppercase text-grey">Arquivos Cadastrados:</div>
                    <div class="d-flex flex-column gap-2">
                        <a v-for="(url, idx) in attachmentModal.item.attachments" :key="idx" :href="url" target="_blank" class="text-primary text-body-2 font-weight-bold d-flex align-center gap-2 bg-grey-lighten-4 pa-2 rounded text-decoration-none border-thin">
                            <v-icon size="18">mdi-file-document-outline</v-icon> Anexo {{ idx + 1 }}
                        </a>
                    </div>
                </div>
                <div v-else class="text-body-2 text-grey mb-4 font-italic bg-grey-lighten-5 pa-4 rounded border-thin text-center">Nenhum comprovante anexado.</div>

                <v-divider class="my-4"></v-divider>

                <div class="text-caption font-weight-bold mb-2 text-uppercase text-grey">Enviar Novo Arquivo (NFe, Boleto, Contrato):</div>
                <v-file-input v-model="attachmentModal.files" label="Selecionar arquivo..." variant="outlined" density="comfortable" prepend-inner-icon="mdi-cloud-upload" color="primary" multiple chips show-size class="ui-field"></v-file-input>
            </div>
            <div class="pa-4 bg-grey-lighten-4 border-t d-flex justify-end gap-3">
                <v-btn variant="outlined" class="btn-3d font-weight-bold bg-white" @click="attachmentModal.show = false">Fechar</v-btn>
                <v-btn color="primary" variant="flat" class="btn-3d font-weight-black px-6" @click="uploadAttachmentsToPurchase" :loading="attachmentModal.loading">Salvar Anexo</v-btn>
            </div>
        </v-card>
    </v-dialog>

    <v-dialog v-model="statusModal.show" width="450">
        <v-card class="pa-6 rounded-0 border-t-lg border-t-info">
            <div class="d-flex align-center gap-3 mb-4">
                <v-icon size="36" color="info">mdi-list-status</v-icon>
                <div class="text-h6 font-weight-black leading-none">Atualizar Status de Execução</div>
            </div>
            <p class="text-body-2 text-grey mb-4">Acompanhamento da execução do serviço aprovado.</p>

            <v-select v-model="statusModal.status" :items="statusOptions.filter(s => s.value !== 'aguardando_aprovacao' && s.value !== 'rejeitado')" item-title="label" item-value="value" variant="outlined" density="comfortable" color="info" hide-details class="font-weight-bold ui-field"></v-select>

            <div class="d-flex justify-end gap-2 mt-6">
                <v-btn variant="text" color="grey-darken-2" class="btn-3d font-weight-bold text-body-2" @click="statusModal.show = false">Cancelar</v-btn>
                <v-btn color="info" variant="flat" class="btn-3d font-weight-black px-6 text-body-2" height="44" @click="saveProductionStatus" :loading="statusModal.loading">Atualizar</v-btn>
            </div>
        </v-card>
    </v-dialog>

    <v-dialog v-model="quickModal.show" width="450">
        <v-card class="pa-6 rounded-0 border-t-lg border-t-info">
            <div class="d-flex align-center gap-3 mb-6">
                <v-icon size="36" color="info">{{ quickModal.type === 'service' ? 'mdi-handshake' : 'mdi-domain' }}</v-icon>
                <div class="text-h6 font-weight-black leading-none">Cadastro de {{ quickModal.type === 'service' ? 'Serviço Base' : 'Prestador' }}</div>
            </div>

            <template v-if="quickModal.type === 'service'">
                <v-text-field v-model="quickModal.name" label="Nome do Serviço" variant="outlined" density="comfortable" color="info" class="font-weight-bold ui-field"></v-text-field>
            </template>

            <template v-else>
                <v-row dense>
                    <v-col cols="12" md="6"><v-text-field v-model="quickModal.supplier.nome" label="Nome / Razão*" variant="outlined" density="comfortable" color="info" class="ui-field font-weight-bold"></v-text-field></v-col>
                    <v-col cols="12" md="6"><v-text-field v-model="quickModal.supplier.cnpj_cpf" label="CNPJ / CPF*" variant="outlined" density="comfortable" color="info" class="ui-field font-weight-bold"></v-text-field></v-col>
                    <v-col cols="12" md="6"><v-text-field v-model="quickModal.supplier.telefone" label="Telefone*" variant="outlined" density="comfortable" color="info" class="ui-field font-weight-bold"></v-text-field></v-col>
                    <v-col cols="12" md="6"><v-text-field v-model="quickModal.supplier.cidade" label="Cidade" variant="outlined" density="comfortable" color="info" class="ui-field"></v-text-field></v-col>
                </v-row>
            </template>

            <div class="d-flex justify-end gap-2 mt-4">
                <v-btn variant="text" color="grey-darken-2" class="btn-3d font-weight-bold text-body-2" @click="quickModal.show = false">Cancelar</v-btn>
                <v-btn color="info" variant="flat" class="btn-3d font-weight-black px-6 text-body-2" height="44" @click="saveQuickRegistration">Cadastrar</v-btn>
            </div>
        </v-card>
    </v-dialog>

  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, reactive, watch } from 'vue';
import { supabase } from '@/api/supabase';
import { useAppStore } from '@/stores/app';
import { useThemeStore } from '@/stores/theme';
import { useCompanyStore } from '@/stores/company';
import { useUserStore } from '@/stores/user';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import * as XLSX from 'xlsx';
import logoLight from '@/assets/logomjlm.png';
import logoCajuia from '@/assets/logocajuia.png';

const getBase64Logo = (url: string): Promise<string> => {
  return new Promise((resolve) => {
    const img = new Image();
    img.crossOrigin = 'Anonymous';
    img.onload = () => {
      const canvas = document.createElement('canvas');
      canvas.width = img.width;
      canvas.height = img.height;
      const ctx = canvas.getContext('2d');
      if (ctx) {
        ctx.fillStyle = '#FFFFFF';
        ctx.fillRect(0, 0, canvas.width, canvas.height);
        ctx.drawImage(img, 0, 0);
        resolve(canvas.toDataURL('image/jpeg', 1.0));
      } else resolve('');
    };
    img.onerror = () => resolve('');
    img.src = url;
  });
};

const PURCHASE_TYPE = 'service';

const appStore = useAppStore();
const themeStore = useThemeStore();
const companyStore = useCompanyStore();
const userStore = useUserStore();

const loadingPurchases = ref(false);
const purchases = ref<any[]>([]);

// Permissões Dinâmicas
const isAdmin = computed(() => {
    const role = userStore.profile?.role?.toLowerCase();
    return role === 'admin' || role === 'super_admin' || role === 'financeiro';
});

const canCreateEdit = computed(() => isAdmin.value || userStore.profile?.permissions?.includes('create_edit_services'));
const canApprove = computed(() => isAdmin.value || userStore.profile?.permissions?.includes('approve_services'));
const canDelete = computed(() => isAdmin.value || userStore.profile?.permissions?.includes('delete_services'));
const canPrintUnapproved = computed(() => isAdmin.value || userStore.profile?.permissions?.includes('print_unapproved_services'));

const canPrintService = (item: any) => {
    if (item.production_status === 'aprovado' || item.production_status === 'concluido') return true;
    return canPrintUnapproved.value;
};

// BOTÕES DE CONTEXTO SUPERIORES
const contextButtons = computed(() => {
    const btns = [];
    const comps = auxData.companies || [];

    if (comps.length > 0) btns.push({ id: comps[0].id, name: comps[0].trade_name, isHolding: false });
    if (comps.length > 1) btns.push({ id: comps[1].id, name: comps[1].trade_name, isHolding: false });

    btns.push({ id: 'global', name: 'HOLDING / GLOBAL', isHolding: true });

    for (let i = 2; i < comps.length; i++) {
        btns.push({ id: comps[i].id, name: comps[i].trade_name, isHolding: false });
    }
    return btns;
});

const setCompanyFilter = (id: string | null) => {
    companyStore.setContext(id || 'global');
};

watch(() => companyStore.context, () => {
    fetchPurchases();
});


// Colunas Dinâmicas Baseadas em Permissões
const gridCols = computed(() => (isAdmin.value || canApprove.value)
    ? '80px 1.5fr 1.5fr 1.2fr 1.5fr 100px 120px 140px 120px 110px 80px 180px'
    : '80px 1.5fr 1.5fr 1.2fr 1.5fr 100px 120px 140px 120px 80px 180px');
const minGridWidth = computed(() => (isAdmin.value || canApprove.value) ? '1750px' : '1650px');

const formatCode = (item: any) => {
    if (!item) return '';
    if (item.codigo) return String(item.codigo).padStart(5, '0');
    if (item.sequential_id) return String(item.sequential_id).padStart(5, '0');
    return item.id ? item.id.substring(0, 6).toUpperCase() : 'NOVO';
};

const filters = reactive({ startDate: '', endDate: '', supplier: null, status: 'Todos', search: '' });

const filteredPurchases = computed(() => {
    let result = purchases.value;

    if (filters.search) {
        const s = filters.search.toLowerCase();
        result = result.filter(p =>
            (p.codigo && String(p.codigo).includes(s)) ||
            (p.sequential_id && String(p.sequential_id).includes(s)) ||
            (p.supplier_name && p.supplier_name.toLowerCase().includes(s)) ||
            (p.description && p.description.toLowerCase().includes(s)) ||
            (p.production_status && formatStatus(p.production_status).toLowerCase().includes(s))
        );
    }

    if (filters.startDate) result = result.filter(p => p.order_date >= filters.startDate);
    if (filters.endDate) result = result.filter(p => p.order_date <= filters.endDate);
    if (filters.supplier) result = result.filter(p => p.supplier_id === filters.supplier);
    if (filters.status !== 'Todos') result = result.filter(p => p.production_status === filters.status);
    return result;
});

const auxData = reactive({ suppliers: [] as any[], services: [] as any[], companies: [] as any[], chartOfAccounts: [] as any[], mrJackyId: null as any });

const approvalModal = reactive({ show: false, loading: false, item: null as any, reason: '', installments: [] as any[] });
const attachmentModal = reactive({ show: false, loading: false, item: null as any, files: [] as File[] });
const statusModal = reactive({ show: false, loading: false, item: null as any, status: '' });

const statusOptions = [
    { value: 'aguardando_aprovacao', label: 'Pendente' },
    { value: 'aprovado', label: 'Aprovado / Em Andamento' },
    { value: 'concluido', label: 'Concluído' },
    { value: 'rejeitado', label: 'Rejeitado / Cancelado' }
];

const formatStatus = (status: string) => statusOptions.find(s => s.value === status)?.label || 'INDEFINIDO';
const getStatusColor = (status: string) => {
    switch(status) {
        case 'concluido': return 'success';
        case 'aprovado': return 'info';
        case 'aguardando_aprovacao': return 'warning';
        case 'rejeitado': return 'error';
        default: return 'grey';
    }
};

const getRejectionReason = (item: any) => {
    if (item.production_status !== 'rejeitado' || !item.audit_log) return 'Serviço Rejeitado';
    const rejectLog = item.audit_log.slice().reverse().find((log: any) => log.action.includes('Rejeita'));
    return rejectLog ? rejectLog.details : 'Rejeitada (Sem justificativa registrada)';
};

const getAuditColor = (action: string) => {
    if (action.includes('Criação')) return 'success';
    if (action.includes('Aprovado')) return 'purple';
    if (action.includes('Rejeitado')) return 'error';
    return 'info';
};

const quickModal = reactive({ show: false, type: '', name: '', supplier: { nome: '', razao_social: '', cnpj_cpf: '', telefone: '', celular: '', email: '', cidade: '', estado: '' } });
const detailsModal = reactive({ show: false, item: null as any });

const modal = reactive({
    show: false, saving: false, files: [] as File[],
    form: { id: '', description: '', supplier_id: null, chart_of_accounts_id: null, order_date: new Date().toISOString().split('T')[0], delivery_date: new Date().toISOString().split('T')[0], notes: '', company_id: null as any },
    items: [] as any[],
    payment: { method: 'Boleto Bancário', condition: 'À Vista', installments: 1, details: [] as any[] }
});

const initialItemState = { ui_id: '', service_id: null, service_name: '', description: '', unit_of_measure: 'sv', quantity: 1, unit_price: 0, total_price: 0 };
const currentItem = ref({ ...initialItemState });

onMounted(async () => { await fetchAuxData(); await fetchPurchases(); });

const fetchAuxData = async () => {
    try {
        const { data: supData } = await supabase.from('suppliers_mj').select('id, nome, razao_social').order('nome');
        if (supData) auxData.suppliers = supData.map((s: any) => ({ id: s.id, name: s.nome || s.razao_social || 'Sem Nome' }));

        const { data: servData } = await supabase.from('services_catalog').select('id, name, base_price').order('name');
        if (servData) auxData.services = servData.map((p: any) => ({ id: p.id, name: p.name, default_price: p.base_price || 0 }));

        const { data: compData } = await supabase.from('companies').select('id, trade_name');
        if (compData) {
            auxData.companies = compData;
            const mrJacky = compData.find((c: any) => c.trade_name && c.trade_name.toUpperCase().includes('JACKY'));
            if (mrJacky) auxData.mrJackyId = mrJacky.id;
        }

        const { data: chartData } = await supabase.from('finance_chart_of_accounts').select('id, name').eq('type', 'Despesa').order('name');
        if (chartData) auxData.chartOfAccounts = chartData;
    } catch(e) { console.error('Erro auxiliares', e); }
};

const fetchPurchases = async () => {
    loadingPurchases.value = true;
    try {
        let query = supabase.from('purchases')
            .select('*, purchase_items(*)')
            .eq('purchase_type', PURCHASE_TYPE)
            .order('created_at', { ascending: false });

        if (!isAdmin.value && !canApprove.value) {
            query = query.eq('created_by', userStore.user?.id);
        } else if (!companyStore.isGlobalView && companyStore.context) {
            query = query.eq('company_id', companyStore.context);
        }

        const { data, error } = await query;
        if (error) throw error;
        purchases.value = data || [];
    } catch(e) { appStore.showSnackbar('Erro ao buscar serviços', 'error'); }
    finally { loadingPurchases.value = false; }
};

const createLogEntry = (action: string, details: string) => ({ date: new Date().toISOString(), user: userStore.profile?.full_name || userStore.user?.email || 'Sistema', action, details });

// ========================================================
// APROVAÇÃO E LOGÍSTICA
// ========================================================
const openApprovalModal = (item: any) => {
    approvalModal.item = item;
    approvalModal.reason = '';
    let rawInstallments = item.payment_details?.details || [];
    if (rawInstallments.length === 0) rawInstallments = [{ due_date: item.delivery_date, value: item.total_value }];
    approvalModal.installments = rawInstallments;
    approvalModal.show = true;
};

const executeApproval = async () => {
    approvalModal.loading = true;
    try {
        const item = approvalModal.item;
        const installments = approvalModal.installments;

        const payloads = installments.map((inst: any, idx: number) => {
            const isParceled = installments.length > 1;
            const seqCode = formatCode(item);
            const desc = isParceled ? `[SERVIÇO PARCELADO] #${seqCode} - ${item.description} (Parc. ${idx + 1}/${installments.length})` : `[SERVIÇO] #${seqCode} - ${item.description}`;
            return { description: desc, entity_name: item.supplier_name || item.entity_name, value: inst.value, due_date: inst.due_date, status: 'em_aberto', company_id: item.company_id || (companyStore.context === 'global' ? null : companyStore.context), chart_of_accounts_id: item.chart_of_accounts_id || null };
        });

        const { data: finData, error: finError } = await supabase.from('finance_payables').insert(payloads).select('id');
        if (finError) throw new Error("Erro Financeiro: " + finError.message);

        const safeAuditLog = Array.isArray(item.audit_log) ? item.audit_log : [];
        const newLog = createLogEntry('Serviço Aprovado', `Aprovado pelo Admin e gerado ${installments.length} registro(s) no Contas a Pagar.`);

        const updatePayload = {
            production_status: 'aprovado',
            finance_payable_id: finData && finData.length > 0 ? finData[0].id : null,
            audit_log: [...safeAuditLog, newLog]
        };

        const { error } = await supabase.from('purchases').update(updatePayload).eq('id', item.id);

        if(error) throw new Error("Erro Update Database: " + error.message);

        appStore.showSnackbar('Serviço Aprovado e Lançado no Financeiro!', 'success');
        approvalModal.show = false;
        fetchPurchases();
    } catch (e: any) {
        appStore.showSnackbar(e.message || 'Falha ao aprovar', 'error');
    } finally {
        approvalModal.loading = false;
    }
};

const executeRejection = async () => {
    approvalModal.loading = true;
    try {
        const item = approvalModal.item;
        const safeAuditLog = Array.isArray(item.audit_log) ? item.audit_log : [];
        const newLog = createLogEntry('Serviço Rejeitado', `Motivo: ${approvalModal.reason || 'Não informado.'}`);

        const { error } = await supabase.from('purchases').update({
            production_status: 'rejeitado',
            audit_log: [...safeAuditLog, newLog]
        }).eq('id', item.id);

        if(error) throw error;

        appStore.showSnackbar('Serviço Rejeitado.', 'error');
        approvalModal.show = false;
        fetchPurchases();
    } catch (e: any) { appStore.showSnackbar('Erro: ' + e.message, 'error'); } finally { approvalModal.loading = false; }
};

const openStatusModal = (item: any) => { statusModal.item = item; statusModal.status = item.production_status; statusModal.show = true; };
const saveProductionStatus = async () => {
    statusModal.loading = true;
    try {
        const item = statusModal.item;
        const safeAuditLog = Array.isArray(item.audit_log) ? item.audit_log : [];
        const newLog = createLogEntry('Alteração de Execução', `De "${formatStatus(item.production_status)}" para "${formatStatus(statusModal.status)}"`);

        const { error } = await supabase.from('purchases').update({
            production_status: statusModal.status,
            audit_log: [...safeAuditLog, newLog]
        }).eq('id', item.id);

        if (error) throw error;
        appStore.showSnackbar('Status Atualizado!', 'success');
        statusModal.show = false;
        fetchPurchases();
    } catch(e: any) { appStore.showSnackbar('Erro: ' + e.message, 'error'); } finally { statusModal.loading = false; }
};

const openAttachmentModal = (item: any) => { attachmentModal.item = item; attachmentModal.files = []; attachmentModal.show = true; };
const uploadAttachmentsToPurchase = async () => {
    if (attachmentModal.files.length === 0) return;
    attachmentModal.loading = true;
    try {
        const urls = [];
        for (const file of attachmentModal.files) {
            const fp = `purchases/${Date.now()}-${Math.random().toString(36).substring(7)}.${file.name.split('.').pop()}`;
            const { error } = await supabase.storage.from('finance-attachments').upload(fp, file);
            if (!error) { const { data } = supabase.storage.from('finance-attachments').getPublicUrl(fp); if (data?.publicUrl) urls.push(data.publicUrl); }
        }
        const updatedAttachments = [...(attachmentModal.item.attachments || []), ...urls];
        await supabase.from('purchases').update({ attachments: updatedAttachments }).eq('id', attachmentModal.item.id);
        appStore.showSnackbar('Comprovante anexado!', 'success');
        attachmentModal.show = false; fetchPurchases();
    } catch(e: any) { appStore.showSnackbar('Erro: ' + e.message, 'error'); } finally { attachmentModal.loading = false; }
};

// ========================================================
// CRIAÇÃO E EDIÇÃO
// ========================================================
const openNewServiceModal = () => {
    const defaultCompanyId = isAdmin.value ? (companyStore.context || auxData.mrJackyId || (auxData.companies.length ? auxData.companies[0].id : null)) : userStore.profile?.company_id;
    modal.form = { id: '', description: '', supplier_id: null, chart_of_accounts_id: null, order_date: new Date().toISOString().split('T')[0], delivery_date: new Date().toISOString().split('T')[0], notes: '', company_id: defaultCompanyId };
    modal.items = []; modal.files = []; modal.payment = { method: 'Boleto Bancário', condition: 'À Vista', installments: 1, details: [] };
    currentItem.value = { ...initialItemState, ui_id: Math.random().toString(36).substr(2, 9) };
    modal.show = true;
};

const openEditModal = (item: any) => {
    modal.form = { ...item };
    modal.payment = item.payment_details || { method: 'Boleto Bancário', condition: 'À Vista', installments: 1, details: [] };
    modal.items = (item.purchase_items || []).map((i:any) => ({ ...i, ui_id: Math.random().toString(36).substr(2, 9), service_name: i.description, service_id: i.service_id }));
    modal.show = true;
};

const cloneService = (item: any) => {
    openEditModal(item).then(() => { modal.form.id = ''; modal.form.description = `${modal.form.description} (Cópia)`; });
};

const openDetailsModal = (item: any) => { detailsModal.item = item; detailsModal.show = true; };

const purchaseTotalValue = computed(() => modal.items.reduce((acc, curr) => acc + Number(curr.total_price), 0));
const sumOfInstallments = computed(() => modal.payment.details.reduce((acc, curr) => acc + Number(curr.value || 0), 0));

watch(() => purchaseTotalValue.value, () => { if (modal.payment.condition === 'À Vista') modal.payment.details = [{ due_date: modal.form.delivery_date, value: purchaseTotalValue.value }]; else generateInstallments(); });
watch(() => modal.payment.condition, (val) => { if (val === 'À Vista') { modal.payment.installments = 1; modal.payment.details = [{ due_date: modal.form.delivery_date, value: purchaseTotalValue.value }]; } else { modal.payment.installments = 2; generateInstallments(); } });

const generateInstallments = () => {
    const count = modal.payment.installments; const total = purchaseTotalValue.value; const baseDate = new Date(modal.form.delivery_date || new Date());
    modal.payment.details = [];
    let instVal = parseFloat((total / count).toFixed(2));
    let diff = total - (instVal * count);
    for (let i = 0; i < count; i++) {
        let val = instVal; if (i === count - 1) val += diff;
        const d = new Date(baseDate); d.setMonth(d.getMonth() + i);
        modal.payment.details.push({ due_date: d.toISOString().split('T')[0], value: Number(val.toFixed(2)) });
    }
};

const onServiceSelect = (servId: any) => { if (!servId) { currentItem.value.service_name = ''; return; } const serv = auxData.services.find(p => p.id === servId); if (serv) { currentItem.value.service_name = serv.name; currentItem.value.description = serv.name; if (!currentItem.value.unit_price) { currentItem.value.unit_price = serv.default_price || 0; calcCurrentTotal(); } } };
const calcCurrentTotal = () => { currentItem.value.total_price = (Number(currentItem.value.quantity) || 0) * (Number(currentItem.value.unit_price) || 0); };
const isCurrentItemValid = computed(() => (currentItem.value.service_id || currentItem.value.description.trim().length > 0) && currentItem.value.quantity > 0 && currentItem.value.unit_price > 0);
const addItemToList = () => { if (!isCurrentItemValid.value) return; const idx = modal.items.findIndex(i => i.ui_id === currentItem.value.ui_id); if (idx >= 0) modal.items[idx] = { ...currentItem.value }; else modal.items.push({ ...currentItem.value, ui_id: Math.random().toString(36).substr(2, 9) }); currentItem.value = { ...initialItemState, ui_id: Math.random().toString(36).substr(2, 9) }; };
const editItem = (index: number) => { currentItem.value = { ...modal.items[index] }; };
const cloneItem = (item: any) => { modal.items.push({ ...item, ui_id: Math.random().toString(36).substr(2, 9) }); };
const removeItem = (index: number) => { modal.items.splice(index, 1); };

const uploadAttachments = async (): Promise<string[]> => {
    if (modal.files.length === 0) return [];
    const urls: string[] = [];
    for (const file of modal.files) {
        const fp = `purchases/${Date.now()}-${Math.random().toString(36).substring(7)}.${file.name.split('.').pop()}`;
        const { error } = await supabase.storage.from('finance-attachments').upload(fp, file);
        if (!error) { const { data } = supabase.storage.from('finance-attachments').getPublicUrl(fp); if (data?.publicUrl) urls.push(data.publicUrl); }
    }
    return urls;
};

const saveFullService = async () => {
    const targetCompanyId = modal.form.company_id;
    if (!targetCompanyId) { appStore.showSnackbar('Você não tem empresa vinculada.', 'error'); return; }
    if (!modal.form.description) { appStore.showSnackbar('Descrição obrigatória.', 'warning'); return; }
    if (!modal.form.supplier_id || modal.items.length === 0) { appStore.showSnackbar('Adicione prestador e itens de serviço.', 'warning'); return; }
    if (sumOfInstallments.value !== purchaseTotalValue.value && modal.payment.condition === 'Parcelado') { appStore.showSnackbar('A soma das parcelas difere do total.', 'error'); return; }

    modal.saving = true;
    try {
        const supInfo = auxData.suppliers.find(s => s.id === modal.form.supplier_id);
        const newAttachments = await uploadAttachments();
        const finalAttachments = [...(modal.form.attachments || []), ...newAttachments];
        const isNew = !modal.form.id;

        const purchaseHeader = {
            purchase_type: PURCHASE_TYPE, description: modal.form.description,
            supplier_id: modal.form.supplier_id, supplier_name: supInfo?.name || 'Prestador', entity_name: supInfo?.name || 'Prestador',
            chart_of_accounts_id: modal.form.chart_of_accounts_id,
            order_date: modal.form.order_date, delivery_date: modal.form.delivery_date,
            total_value: purchaseTotalValue.value, move_stock: false,
            notes: modal.form.notes, company_id: targetCompanyId,
            attachments: finalAttachments, payment_details: modal.payment,
            is_quotation: false
        } as any;

        if (isNew) {
            purchaseHeader.created_by = userStore.user?.id;
            purchaseHeader.created_by_name = userStore.profile?.full_name || userStore.user?.email;
            purchaseHeader.production_status = 'aguardando_aprovacao';
            purchaseHeader.audit_log = [createLogEntry('Criação', `Serviço solicitado no valor de ${formatCurrency(purchaseTotalValue.value)}. Aguardando Aprovação.`)];

            const { data: hd, error: he } = await supabase.from('purchases').insert(purchaseHeader).select('id').single();
            if (he) throw he;

            const itemsPayload = modal.items.map(i => ({ purchase_id: hd.id, service_id: i.service_id, description: i.service_id ? i.service_name : i.description, quantity: i.quantity, unit_of_measure: i.unit_of_measure, unit_price: i.unit_price, total_price: i.total_price }));
            await supabase.from('purchase_items').insert(itemsPayload);

            await supabase.from('notifications').insert({
                content: `[ALERT_PENDING_APPROVAL]Contratação de Serviço::O usuário ${userStore.profile?.full_name || 'Sistema'} solicitou um serviço de ${formatCurrency(purchaseTotalValue.value)}.`,
                recipient_id: null
            });

        } else {
            purchaseHeader.updated_at = new Date().toISOString();
            purchaseHeader.updated_by_name = userStore.profile?.full_name || userStore.user?.email;

            const safeAuditLog = Array.isArray(modal.form.audit_log) ? modal.form.audit_log : [];
            purchaseHeader.audit_log = [...safeAuditLog, createLogEntry('Edição Manual', `Edição das informações do serviço.`)];

            await supabase.from('purchases').update(purchaseHeader).eq('id', modal.form.id);
            await supabase.from('purchase_items').delete().eq('purchase_id', modal.form.id);
            const itemsPayload = modal.items.map(i => ({ purchase_id: modal.form.id, service_id: i.service_id, description: i.service_id ? i.service_name : i.description, quantity: i.quantity, unit_of_measure: i.unit_of_measure, unit_price: i.unit_price, total_price: i.total_price }));
            await supabase.from('purchase_items').insert(itemsPayload);

            await supabase.from('notifications').insert({
                content: `[ALERT_PENDING_APPROVAL]Serviço Atualizado::O usuário ${userStore.profile?.full_name || 'Sistema'} re-enviou o serviço (${formatCurrency(purchaseTotalValue.value)}).`,
                recipient_id: null
            });
        }

        appStore.showSnackbar('Serviço Salvo com Sucesso!', 'success');
        modal.show = false; fetchPurchases();
    } catch(e: any) { appStore.showSnackbar('Erro ao salvar: ' + e.message, 'error'); }
    finally { modal.saving = false; }
};

// ========================================================
// PDF E EXCEL
// ========================================================
const printService = async (item: any) => {
  try {
    const orderId = item?.id;
    if (!orderId) { appStore.showSnackbar("Inválido para impressão.", "error"); return; }

    const money = (val: number) => new Intl.NumberFormat("pt-BR", { style: "currency", currency: "BRL" }).format(Number(val || 0));
    const num = (val: number) => new Intl.NumberFormat("pt-BR", { minimumFractionDigits: 2, maximumFractionDigits: 2 }).format(Number(val || 0));
    const formatDate = (d: any) => { if (!d) return "-"; const date = d.split('T')[0].split('-'); return `${date[2]}/${date[1]}/${date[0]}`; };

    const doc = new jsPDF({ orientation: "p", unit: "mm", format: "a4" });
    const pageW = doc.internal.pageSize.getWidth();
    const pageH = doc.internal.pageSize.getHeight();
    const M = 10;
    const boxW = pageW - M * 2;

    let pdfCompany = companyStore.currentCompany || {};
    if (item.company_id) {
      try {
        const { data: compData } = await supabase.from('companies').select('*').eq('id', item.company_id).single();
        if (compData) pdfCompany = compData;
      } catch (err) {}
    }
    const companyName = (pdfCompany.trade_name || pdfCompany.corporate_name || companyStore.currentCompanyName || 'Empresa').toUpperCase();

    let companyText1 = companyName;
    let companyText2 = `CNPJ: ${pdfCompany.cnpj || 'N/A'}`;
    let companyText3 = `${pdfCompany.address_line || 'Endereço não configurado'}`;
    let companyText4 = `${pdfCompany.city || ''} ${pdfCompany.state ? '- ' + pdfCompany.state : ''} | ${pdfCompany.email || ''}`;

let logoUrl = logoLight;

    if (companyName.includes('SANTOS') || companyName.includes('LOPES')) {
        logoUrl = logoCajuia;
    } else if (companyName.includes('JACKY') || companyName.includes('MJ')) {
        logoUrl = logoLight;
    } else if (userStore.currentModule === 'cajuia' || companyName.includes('CAJUIA')) {
        logoUrl = logoCajuia;
    }

    const logoBase64 = await getBase64Logo(logoUrl);

    const topY = 10;
    const headerH = 26;
    doc.setDrawColor(180); doc.setLineWidth(0.3); doc.rect(M, topY, boxW, headerH);
    try { if (logoBase64) doc.addImage(logoBase64, "JPEG", M + 3, topY + 4, 30, 16); } catch (e) { }

    doc.setFont("helvetica", "bold"); doc.setFontSize(11); doc.text(companyText1, M + 38, topY + 9);
    doc.setFont("helvetica", "normal"); doc.setFontSize(8.5);
    doc.text(companyText2, M + 38, topY + 14);
    doc.text(companyText3, M + 38, topY + 18);
    doc.text(companyText4, M + 38, topY + 22);

    const rightX = pageW - M;
    doc.text(`Gerado por: ${userStore.profile?.full_name || "Sistema"}`, rightX - 2, topY + 22, { align: "right" });

    const barY = topY + headerH + 6;
    const barH = 8;
    doc.setFillColor(230); doc.rect(M, barY, boxW, barH, "F"); doc.setDrawColor(180); doc.rect(M, barY, boxW, barH);
    doc.setFont("helvetica", "bold"); doc.setFontSize(11);
    const orderNo = formatCode(item);
    doc.text(`CONTRATAÇÃO DE SERVIÇO N° ${orderNo}`, pageW / 2, barY + 5.5, { align: "center" });
    doc.setFontSize(10); doc.text(`EMISSÃO: ${formatDate(item.order_date)}`, pageW - M - 2, barY + 5.5, { align: "right" });

    const forncBoxY = barY + barH + 6;
    doc.setFont("helvetica", "bold"); doc.setFontSize(9.5);
    doc.setFillColor(230); doc.rect(M, forncBoxY, boxW, 7, "F"); doc.setDrawColor(180); doc.rect(M, forncBoxY, boxW, 7);
    doc.text("DADOS DO PRESTADOR", M + 2, forncBoxY + 5);

    const forncRows = [
        ["Prestador:", item.supplier_name || item.entity_name || "—", "Prev. Conclusão:", formatDate(item.delivery_date)],
        ["Serviço:", item.description || "—", "Status Aprovação:", formatStatus(item.production_status).toUpperCase()]
    ];
    autoTable(doc, {
        startY: forncBoxY + 7,
        theme: "grid",
        tableWidth: boxW,
        margin: { left: M, right: M },
        styles: { fontSize: 8.5, cellPadding: 1.5, textColor: 0, lineColor: [200, 200, 200], lineWidth: 0.2, minCellHeight: 7, valign: "middle" },
        bodyStyles: { fillColor: [255, 255, 255] },
        columnStyles: { 0: { cellWidth: 22, fontStyle: "bold" }, 1: { cellWidth: 83 }, 2: { cellWidth: 35, fontStyle: "bold" }, 3: { cellWidth: 50 } },
        body: forncRows
    });

    let lastY = (doc as any).lastAutoTable.finalY + 5;

    const notesContent = String(item.notes || "").trim();
    if (notesContent) {
        doc.setFillColor(255, 243, 224); doc.setDrawColor(255, 183, 77);
        doc.setFont("helvetica", "normal"); doc.setFontSize(8.5);
        const splitNotes = doc.splitTextToSize(notesContent, boxW - 4);
        const notesHeight = (splitNotes.length * 4) + 8;
        doc.rect(M, lastY, boxW, notesHeight, "F"); doc.rect(M, lastY, boxW, notesHeight);
        doc.setFont("helvetica", "bold"); doc.setTextColor(230, 81, 0);
        doc.text("JUSTIFICATIVA:", M + 2, lastY + 4);
        doc.setFont("helvetica", "normal"); doc.setTextColor(0);
        doc.text(splitNotes, M + 2, lastY + 9);
        lastY += notesHeight + 5;
    }

    doc.setFont("helvetica", "bold"); doc.setFontSize(9.5);
    doc.setFillColor(230); doc.setDrawColor(180); doc.rect(M, lastY, boxW, 7, "F"); doc.rect(M, lastY, boxW, 7);
    doc.setTextColor(0); doc.text("ESCOPO DE SERVIÇOS CONTRATADOS", M + 2, lastY + 5);

    const productsBody = (item.purchase_items || []).map((it: any, idx: number) => [
        String(idx + 1),
        it.description || 'Sem descrição',
        num(it.quantity),
        money(it.unit_price),
        money(it.total_price)
    ]);
    const totalQtd = (item.purchase_items || []).reduce((acc: number, it: any) => acc + Number(it.quantity || 0), 0);

    autoTable(doc, {
        startY: lastY + 7,
        theme: "grid",
        tableWidth: boxW,
        margin: { left: M, right: M },
        headStyles: { fillColor: [245, 245, 245], textColor: 0, fontStyle: "bold", fontSize: 8.5, valign: "middle" },
        styles: { fontSize: 8.3, cellPadding: 1.5, lineColor: [200, 200, 200], lineWidth: 0.2, textColor: 0, minCellHeight: 7, valign: "middle" },
        columnStyles: { 0: { cellWidth: 15, halign: "center" }, 1: { cellWidth: 105 }, 2: { cellWidth: 20, halign: "center" }, 3: { cellWidth: 25, halign: "right" }, 4: { cellWidth: 25, halign: "right" } },
        head: [["ITEM", "DESCRIÇÃO DO SERVIÇO", "QTD", "VALOR UNIT.", "SUBTOTAL"]],
        body: productsBody.length ? productsBody : [["—", "Nenhum item", "0", "0,00", "0,00"]],
        foot: [["TOTAL", "", num(totalQtd), "", money(item.total_value)]],
        footStyles: { fillColor: [240, 240, 240], fontStyle: "bold", halign: "right", valign: "middle" }
    });

    const afterProductsY = (doc as any).lastAutoTable.finalY + 4;

    const rightBoxW = 70;
    const rightBoxX = pageW - M - rightBoxW;
    const totalsBoxH = 10;
    doc.setFillColor(230); doc.rect(rightBoxX, afterProductsY, rightBoxW, totalsBoxH, "F"); doc.setDrawColor(180); doc.rect(rightBoxX, afterProductsY, rightBoxW, totalsBoxH);
    doc.setFont("helvetica", "bold"); doc.setFontSize(9);
    doc.text(`TOTAL DO SERVIÇO: ${money(item.total_value)}`, rightBoxX + rightBoxW - 2, afterProductsY + 6.5, { align: "right" });

    const afterTotalsY = afterProductsY + totalsBoxH + 6;
    doc.setFont("helvetica", "bold"); doc.setFontSize(9.5);
    doc.setFillColor(230); doc.rect(M, afterTotalsY, boxW, 7, "F"); doc.setDrawColor(180); doc.rect(M, afterTotalsY, boxW, 7);
    doc.text("FINANCEIRO / PARCELAS", M + 2, afterTotalsY + 5);

    const payDetails = item.payment_details || {};
    const paymentBody = (payDetails.details || []).map((p: any, idx: number) => [
        `${idx + 1}ª Parcela`,
        formatDate(p.due_date),
        money(p.value),
        payDetails.method || '-'
    ]);

    autoTable(doc, {
        startY: afterTotalsY + 7,
        theme: "grid",
        tableWidth: boxW,
        margin: { left: M, right: M },
        headStyles: { fillColor: [245, 245, 245], textColor: 0, fontStyle: "bold", fontSize: 8.5, valign: "middle" },
        styles: { fontSize: 8.3, cellPadding: 1.5, lineColor: [200, 200, 200], lineWidth: 0.2, textColor: 0, minCellHeight: 7, valign: "middle" },
        columnStyles: { 0: { cellWidth: 30, halign: "center" }, 1: { cellWidth: 40, halign: "center" }, 2: { cellWidth: 40, halign: "right" }, 3: { cellWidth: 80 } },
        head: [["PARCELA", "VENCIMENTO", "VALOR", "FORMA PAGTO"]],
        body: paymentBody.length ? paymentBody : [["1/1", formatDate(item.delivery_date), money(item.total_value), payDetails.method || 'À VISTA']]
    });

    const afterPayY = (doc as any).lastAutoTable.finalY + 10;
    const signH = 18;
    let signY = afterPayY;
    if (signY + signH > pageH - M) { doc.addPage(); signY = M + 10; }
    doc.setDrawColor(0); doc.setLineWidth(0.3); doc.rect(M, signY, boxW, signH);
    doc.setDrawColor(120); doc.line(M + 50, signY + 12, M + boxW - 50, signY + 12);
    doc.setFont("helvetica", "normal"); doc.setFontSize(8); doc.text("SOLICITANTE", pageW / 2, signY + 16, { align: "center" });

    const totalPages = doc.getNumberOfPages();
    for (let i = 1; i <= totalPages; i++) {
        doc.setPage(i); doc.setFontSize(7); doc.setTextColor(150);
        doc.text("Gerado com MJProcess", pageW - M, pageH - 5, { align: "right" });
    }

    doc.save(`Servico_${orderNo}.pdf`);
  } catch (e: any) { appStore.showSnackbar(`Erro PDF: ${e?.message || e}`, "error"); }
};

const exportListToPDF = () => {
    const doc = new jsPDF('landscape');
    doc.setFont("helvetica", "bold"); doc.setFontSize(16); doc.text("Relatório de Serviços Contratados", 14, 15);
    doc.setFontSize(10); doc.setFont("helvetica", "normal"); doc.text(`Gerado em: ${new Date().toLocaleString('pt-BR')}`, 14, 22);

    const tableData = filteredPurchases.value.map(i => [
        formatCode(i), i.supplier_name || i.entity_name, i.description || '-', formatDateSafe(i.order_date),
        formatStatus(i.production_status), formatCurrency(i.total_value), i.finance_payable_id ? 'Sim' : 'Não'
    ]);

    autoTable(doc, {
        startY: 30, theme: "grid",
        head: [["Cód", "Prestador", "Descrição", "Data Pedido", "Status", "Valor Total", "Lançado Fin."]],
        body: tableData, styles: { fontSize: 9, cellPadding: 3 }, headStyles: { fillColor: [40, 40, 40], textColor: 255, fontStyle: 'bold' }
    });

    doc.save("Relatorio_Servicos.pdf");
};

const exportToExcel = () => {
    const data = filteredPurchases.value.map(i => ({
        "Cód": formatCode(i), "Prestador": i.supplier_name || i.entity_name, "Descrição": i.description,
        "Data Emissão": formatDateSafe(i.order_date), "Prev. Conclusão": formatDateSafe(i.delivery_date),
        "Status": formatStatus(i.production_status), "Valor Total": i.total_value, "Lançado Financeiro": i.finance_payable_id ? 'Sim' : 'Não'
    }));
    const ws = XLSX.utils.json_to_sheet(data); const wb = XLSX.utils.book_new(); XLSX.utils.book_append_sheet(wb, ws, "Serviços"); XLSX.writeFile(wb, "Relatorio_Servicos.xlsx");
};

const shareService = (item: any, platform: 'whatsapp' | 'email') => {
    const code = formatCode(item);
    const text = `Contratação de Serviço #${code} - ${item.description}\nPrestador: ${item.supplier_name}\nValor: ${formatCurrency(item.total_value)}\nData Emissão: ${formatDateSafe(item.order_date)}`;
    if (platform === 'whatsapp') window.open(`https://wa.me/?text=${encodeURIComponent(text)}`, '_blank');
    else window.open(`mailto:?subject=Serviço #${code}&body=${encodeURIComponent(text)}`, '_blank');
};

const openQuickSupplierModal = () => { quickModal.type = 'supplier'; quickModal.supplier = { nome: '', razao_social: '', cnpj_cpf: '', telefone: '', celular: '', email: '', cidade: '', estado: '' }; quickModal.show = true; };
const openQuickServiceModal = () => { quickModal.type = 'service'; quickModal.name = ''; quickModal.show = true; };
const saveQuickRegistration = async () => {
    try {
        if (quickModal.type === 'supplier') {
            const spl = quickModal.supplier;
            if (!spl.nome || !spl.cnpj_cpf || !spl.telefone) { appStore.showSnackbar('Nome, Documento e Telefone obrigatórios.', 'warning'); return; }
            const { data } = await supabase.from('suppliers_mj').insert({ nome: spl.nome, razao_social: spl.razao_social || spl.nome, cnpj_cpf: spl.cnpj_cpf, email: spl.email, telefone: spl.telefone, celular: spl.celular, cidade: spl.cidade, estado: spl.estado, situacao: 'Ativo', tipo_pessoa: spl.cnpj_cpf.length > 14 ? 'PJ' : 'PF' }).select('id, nome').single();
            if (data) { auxData.suppliers.push({ id: data.id, name: data.nome }); modal.form.supplier_id = data.id; }
        } else {
            if (!quickModal.name) return;
            const { data } = await supabase.from('services_catalog').insert({ name: quickModal.name, base_price: 0 }).select('id, name, base_price').single();
            if (data) { auxData.services.push({ id: data.id, name: data.name, default_price: data.base_price }); currentItem.value.service_id = data.id; onServiceSelect(data.id); }
        }
        quickModal.show = false; appStore.showSnackbar('Cadastrado!', 'success');
    } catch(e) { appStore.showSnackbar('Erro no cadastro.', 'error'); }
};

const deletePurchase = async (id: string) => {
    if (!confirm('Excluir permanentemente este serviço?')) return;
    try { await supabase.from('purchases').delete().eq('id', id); fetchPurchases(); } catch(e) { appStore.showSnackbar('Erro ao excluir', 'error'); }
};

const formatDateSafe = (d: string) => { if (!d) return '-'; return d.split('T')[0].split('-').reverse().join('/'); };
const formatDateTimeSafe = (d: string) => { if (!d) return '-'; const obj = new Date(d); return `${obj.toLocaleDateString('pt-BR')} às ${obj.toLocaleTimeString('pt-BR').substring(0,5)}`; };
const formatCurrency = (val:any) => new Intl.NumberFormat('pt-BR', {style:'currency',currency:'BRL'}).format(Number(val)||0);
const formatCurrencyValue = (val:any) => new Intl.NumberFormat('pt-BR', {minimumFractionDigits:2}).format(Number(val)||0);
const zebraClass = (i:number) => themeStore.currentMode!=='light' ? (i%2===0?'zebra-dark-a':'zebra-dark-b') : (i%2===0?'zebra-light-a':'zebra-light-b');
</script>

<style scoped lang="scss">
.receivables-layout { position: relative; }
.bg-glass-dark { background: rgba(10,10,12,0.85); }
.bg-glass-header { background: rgba(20,20,24,0.55); backdrop-filter: blur(14px); }
.border-bottom-white-05 { border-bottom: 1px solid rgba(255,255,255,0.08); }

.bg-gradient-orange-dark { background: linear-gradient(135deg, #EF6C00, #BF360C); border: 1px solid rgba(255,255,255,0.1); }

.ui-field :deep(.v-field) { border-radius: 0px !important; background-color: #ffffff; font-size: 14px; }

.grid-scroll { scrollbar-gutter: stable; -webkit-overflow-scrolling: touch; }
.custom-scroll::-webkit-scrollbar { width: 8px; height: 8px; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.35); border-radius: 0px; }
.custom-scroll::-webkit-scrollbar-track { background: transparent; }

.grid-header, .grid-row { display: grid; align-items: stretch; width: 100%; }

.cell {
    padding: 8px 12px;
    display: flex;
    align-items: center;
    border-right: 1px solid rgba(0,0,0,0.08);
    border-bottom: 1px solid rgba(0,0,0,0.08);
    min-height: 56px;
    overflow: hidden;
    transition: background-color 0.2s ease;
}

.header-text { font-size: 16px !important; font-weight: 900; text-transform: uppercase; letter-spacing: 0.5px; line-height: 1.2; }
.center { justify-content: center; text-align: center; }

.grid-header .cell {
    min-height: 44px;
    font-size: 16px !important;
    font-weight: 900;
    text-transform: uppercase;
    letter-spacing: 0.5px;
    line-height: 1.2;
}

.sticky-head {
    position: sticky;
    top: 0;
    z-index: 20;
    box-shadow: 0 8px 16px -4px rgba(0, 0, 0, 0.12);
}

.bg-glass-dark .sticky-head {
    box-shadow: 0 8px 20px -4px rgba(0, 0, 0, 0.4);
}

.grid-surface-light .cell { background: #f5f7fa; color: rgba(0,0,0,0.9); border-color: rgba(0,0,0,0.12) !important; }
.grid-surface-dark .cell { background: rgba(255,255,255,0.08); color: rgba(255,255,255,0.95); border-color: rgba(255,255,255,0.10) !important; }

.grid-row-light .cell { border-color: rgba(0,0,0,0.08) !important; }
.grid-row-dark .cell { border-color: rgba(255,255,255,0.08) !important; }

.zebra-light-a .cell { background: #ffffff; }
.zebra-light-b .cell { background: #f0f4f8; }
.zebra-dark-a .cell { background: rgba(0,0,0,0.15); }
.zebra-dark-b .cell { background: rgba(255,255,255,0.03); }

.grid-row-light:hover .cell { background: #e3f2fd !important; }
.grid-row-dark:hover .cell { background: rgba(255,255,255,0.12) !important; }

.pill-ref { font-size: 12px !important; font-weight: 900; font-family: monospace; padding: 4px 6px; border-radius: 0px; white-space: nowrap; }

.solid-chip { display: inline-flex; align-items: center; justify-content: center; height: 28px; padding: 0 12px; border-radius: 0px; font-size: 12px !important; font-weight: 900; color: #fff; text-transform: uppercase; white-space: nowrap; }

.flex-grow-1.overflow-hidden > .v-card.flex-grow-1 {
    border: 1px solid rgba(0,0,0,0.12) !important;
}
.bg-glass-dark .flex-grow-1.overflow-hidden > .v-card.flex-grow-1 {
    border: 1px solid rgba(255,255,255,0.12) !important;
}

.actions-inline {
    display: flex;
    gap: 8px;
    justify-content: center;
    flex-wrap: nowrap !important;
    white-space: nowrap;
}

.action-btn { width: 34px !important; height: 34px !important; color: #fff !important; }
.action-edit { background: #1976d2 !important; }
.action-del { background: #c62828 !important; }

/* EFEITO 3D E ARREDONDAMENTO PARA BOTÕES */
.btn-3d {
    border-radius: 6px !important;
    box-shadow: 0 3px 5px rgba(0,0,0,0.15), inset 0 2px 0 rgba(255,255,255,0.25) !important;
    transition: transform 0.1s ease, box-shadow 0.1s ease;
    text-transform: none !important;
}
.btn-3d:active {
    transform: translateY(2px);
    box-shadow: 0 1px 2px rgba(0,0,0,0.15), inset 0 1px 0 rgba(255,255,255,0.2) !important;
}

/* EFEITO 3D E ARREDONDAMENTO PARA TAGS (CHIPS) */
.chip-3d {
    border-radius: 6px !important;
    box-shadow: 0 3px 5px rgba(0,0,0,0.12), inset 0 1px 0 rgba(255,255,255,0.25) !important;
    text-shadow: 0 1px 2px rgba(0,0,0,0.25);
}

.row-gap { row-gap: 16px; margin-top: 8px; }
.shadow-inner { box-shadow: inset 0 2px 4px rgba(0,0,0,0.05); }
.shadow-button { box-shadow: 0 4px 15px rgba(2, 136, 209, 0.4); }
.bg-white-20 { background-color: rgba(255,255,255,0.2); }
.tracking-wide { letter-spacing: 0.5px; }

/* Ocultar scrollbar dos botões contextuais */
.hide-scrollbar::-webkit-scrollbar { display: none; }
.hide-scrollbar { -ms-overflow-style: none; scrollbar-width: none; }
</style>
