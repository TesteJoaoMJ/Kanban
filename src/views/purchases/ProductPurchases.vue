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
            <span class="opacity-70">Produtos</span><span class="mx-2 opacity-50">></span><span class="font-weight-bold">Compra de Produtos</span>
          </div>
          <div class="d-flex align-center gap-2 mt-1">
             <div class="text-h5 font-weight-black tracking-tight leading-none">Gestão de Compras</div>
          </div>

          <div class="d-flex align-center gap-3 mt-3 overflow-x-auto hide-scrollbar pb-1 w-100">
             <v-btn
                v-for="btn in contextButtons"
                :key="btn.id"
                size="x-small"
                height="24"
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

        <div class="d-none d-md-flex align-center overflow-x-auto pb-1 pb-md-0 mt-3 mt-md-0" style="gap: 10px;">
          <v-btn color="success" variant="flat" class="btn-3d px-6 font-weight-bold text-body-2 text-uppercase letter-spacing-1 shadow-button" prepend-icon="mdi-cart-plus" height="44" @click="openNewPurchaseModal">
             Nova Compra
          </v-btn>
        </div>
      </div>

      <div class="px-4 px-md-6 py-3 flex-shrink-0 border-b d-flex flex-wrap align-center justify-space-between shadow-sm z-10" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-glass-dark'" style="gap: 16px;">

          <div class="d-flex align-center flex-grow-1" style="max-width: 400px;">
              <v-text-field
                  v-model="filters.search"
                  label="Buscar (Cód, Fornecedor, etc)..."
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
                  <v-card class="pa-5 rounded-lg shadow-xl border-thin" min-width="380" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-grey-darken-4 text-white'">
                      <div class="text-h6 font-weight-black mb-4 text-primary d-flex align-center gap-2">
                          <v-icon>mdi-filter-outline</v-icon> Filtrar Compras
                      </div>
                      <v-text-field v-model="filters.startDate" label="Data Inicial" type="date" variant="outlined" density="comfortable" class="mb-3 ui-field" hide-details></v-text-field>
                      <v-text-field v-model="filters.endDate" label="Data Final" type="date" variant="outlined" density="comfortable" class="mb-3 ui-field" hide-details></v-text-field>
                      <v-autocomplete v-model="filters.supplier" :items="auxData.suppliers" item-title="name" item-value="id" label="Filtrar por Fornecedor" variant="outlined" density="comfortable" class="mb-3 ui-field" hide-details clearable></v-autocomplete>
                      <v-select v-model="filters.status" :items="['Todos', 'indefinido', 'em_producao', 'com_fornecedor', 'a_caminho', 'entregue', 'cancelado']" label="Status Logístico" variant="outlined" density="comfortable" class="mb-5 ui-field" hide-details></v-select>
                      <v-btn color="success" block variant="flat" height="44" class="font-weight-bold btn-3d text-body-1" @click="fetchPurchases">Aplicar Filtros</v-btn>
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
        <v-card class="flex-grow-1 d-flex flex-column rounded-lg border-thin overflow-hidden" :class="themeStore.currentMode === 'light' ? 'bg-white shadow-sm' : 'glass-card border-white-05'" :elevation="0">
          <div class="grid-scroll flex-grow-1 overflow-auto custom-scroll relative">
            <div class="grid-header sticky-head border-b" :class="[themeStore.currentMode === 'light' ? 'grid-surface-light' : 'grid-surface-dark']" style="grid-template-columns: 100px 2fr 130px 200px 160px 160px 160px 200px; min-width: 1300px;">
              <div class="cell center header-text">Cód.</div>
              <div class="cell header-text">Fornecedor / Descrição</div>
              <div class="cell center header-text">Data Pedido</div>
              <div class="cell center header-text">Status Produção</div>
              <div class="cell center header-text">Condição Pagto</div>
              <div class="cell center header-text">Valor Total</div>
              <div class="cell center header-text">Status Fin.</div>
              <div class="cell center header-text">Ações</div>
            </div>

            <div v-if="loadingPurchases" class="d-flex flex-column justify-center align-center h-100 py-10 min-w-full">
              <v-progress-circular indeterminate color="success" size="48" width="4"></v-progress-circular>
            </div>

            <div v-else-if="filteredPurchases.length === 0" class="d-flex flex-column justify-center align-center h-100 py-10 min-w-full opacity-60">
              <v-icon size="64">mdi-cart-off</v-icon>
              <span class="text-body-1 mt-4 font-weight-bold">Nenhuma compra registrada para os filtros selecionados.</span>
            </div>

            <div v-else v-for="(item, index) in filteredPurchases" :key="item.id" class="grid-row" :class="[themeStore.currentMode === 'light' ? 'grid-row-light' : 'grid-row-dark', zebraClass(index)]" style="grid-template-columns: 100px 2fr 130px 200px 160px 160px 160px 200px; min-width: 1300px;">
                <div class="cell center">
                    <span class="pill-ref bg-grey-lighten-4 text-grey-darken-4 font-weight-black">
                        #{{ formatCode(item) }}
                    </span>
                </div>

                <div class="cell">
                    <div class="d-flex flex-column justify-center w-100">
                        <span class="font-weight-medium text-grey-darken-4 text-truncate" style="font-size: 15px;" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">{{ item.supplier_name || item.entity_name }}</span>
                        <span class="text-grey-darken-3 text-truncate" style="font-size: 13px; margin-top: 2px;" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-3' : 'text-white-70'">{{ item.description }}</span>
                    </div>
                </div>

                <div class="cell center">
                    <span class="font-mono font-weight-medium" style="font-size: 15px;" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white-70'">{{ formatDateSafe(item.order_date) }}</span>
                </div>

                <div class="cell center">
                    <v-chip size="default" :color="getProductionStatusColor(item.production_status)" variant="flat" class="font-weight-bold text-uppercase px-4 cursor-pointer hover-elevate transition-all chip-3d" style="font-size: 12px; height: 28px;" @click.stop="openStatusModal(item)">
                        {{ formatProductionStatus(item.production_status) }}
                    </v-chip>
                </div>

                <div class="cell center">
                    <v-chip size="default" variant="tonal" :color="item.payment_details?.installments > 1 ? 'info' : 'success'" class="font-weight-bold px-3 chip-3d" style="font-size: 12px; height: 28px;">
                        {{ item.payment_details?.installments > 1 ? `Parc. em ${item.payment_details.installments}x` : 'À Vista' }}
                    </v-chip>
                </div>

                <div class="cell center">
                    <span class="font-mono font-weight-black text-success-darken-3" style="font-size: 15px;" :class="themeStore.currentMode === 'light' ? 'text-success-darken-3' : 'text-success'">{{ formatCurrency(item.total_value) }}</span>
                </div>

                <div class="cell center">
                    <span class="solid-chip chip-3d" :class="item.finance_payable_id ? 'bg-success text-white' : 'bg-orange-darken-1 text-white'">
                        {{ item.finance_payable_id ? 'LANÇADO' : 'PENDENTE' }}
                    </span>
                </div>

                <div class="cell center">
                    <div class="actions-inline d-flex flex-nowrap">
                        <v-btn icon size="small" class="action-btn action-pay btn-3d" :class="item.finance_payable_id ? 'opacity-50' : ''" @click.stop="openFinancialPreview(item)" :title="item.finance_payable_id ? 'Já lançado' : 'Lançar no Contas a Pagar'" variant="flat" :disabled="!!item.finance_payable_id"><v-icon size="16">mdi-bank-transfer</v-icon></v-btn>
                        <v-btn icon size="small" class="action-btn action-edit btn-3d" @click.stop="openEditModal(item)" title="Editar" variant="flat"><v-icon size="16">mdi-pencil</v-icon></v-btn>
                        <v-btn icon size="small" class="action-btn bg-blue-grey-lighten-4 text-blue-grey-darken-4 btn-3d" @click.stop="clonePurchase(item)" title="Clonar Compra" variant="flat"><v-icon size="16">mdi-content-copy</v-icon></v-btn>

                        <v-menu location="bottom end" transition="scale-transition">
                            <template v-slot:activator="{ props }">
                                <v-btn v-bind="props" icon size="small" class="action-btn bg-success text-white btn-3d" variant="flat" title="Mais Opções"><v-icon size="16">mdi-chevron-down</v-icon></v-btn>
                            </template>
                            <v-list density="comfortable" nav class="border-thin shadow-xl rounded-lg" width="220" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-grey-darken-4 text-white'">
                                <v-list-item @click="openDetailsModal(item)" prepend-icon="mdi-magnify" base-color="info" title="Auditoria e Detalhes" class="font-weight-bold text-body-2"></v-list-item>
                                <v-list-item @click="printPurchase(item)" prepend-icon="mdi-printer" title="Imprimir Pedido (PDF)" class="font-weight-bold text-body-2"></v-list-item>

                                <v-menu location="start" open-on-hover submenu>
                                    <template v-slot:activator="{ props: menuProps }">
                                        <v-list-item v-bind="menuProps" prepend-icon="mdi-share-variant" title="Compartilhar" append-icon="mdi-menu-right" class="font-weight-bold text-body-2"></v-list-item>
                                    </template>
                                    <v-list density="comfortable" nav class="border-thin shadow-xl rounded-lg" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-grey-darken-4 text-white'">
                                        <v-list-item @click="sharePurchase(item, 'whatsapp')" prepend-icon="mdi-whatsapp" base-color="success" title="Via WhatsApp" class="font-weight-bold text-body-2"></v-list-item>
                                        <v-list-item @click="sharePurchase(item, 'email')" prepend-icon="mdi-email" base-color="error" title="Via E-mail" class="font-weight-bold text-body-2"></v-list-item>
                                    </v-list>
                                </v-menu>

                                <v-divider class="my-2" :class="themeStore.currentMode === 'light' ? 'border-grey-lighten-2' : 'border-white-10'"></v-divider>
                                <v-list-item @click="deletePurchase(item.id)" prepend-icon="mdi-trash-can-outline" base-color="error" title="Excluir Definitivo" class="font-weight-bold text-body-2" :disabled="!!item.finance_payable_id"></v-list-item>
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
        <v-card class="d-flex flex-column rounded-lg bg-grey-lighten-4 h-100" style="max-height: 95vh;">
            <div class="px-6 py-5 bg-success text-white d-flex align-center justify-space-between flex-shrink-0 elevation-2 z-10 relative">
                <div class="d-flex align-center gap-4">
                    <div class="bg-white-20 rounded-lg d-flex align-center justify-center" style="width: 48px; height: 48px;"><v-icon size="28" color="white">{{ modal.form.id ? 'mdi-cart-check' : 'mdi-cart-arrow-down' }}</v-icon></div>
                    <div>
                        <div class="text-h5 font-weight-black leading-tight">{{ modal.form.id ? 'Editando Compra' : 'Lançamento de Nova Compra' }}</div>
                        <div class="text-caption font-weight-medium opacity-90">Preencha detalhadamente as informações do fornecedor, itens e condições de pagamento.</div>
                    </div>
                </div>
                <v-btn icon="mdi-close" variant="text" color="white" size="large" class="btn-3d" @click="modal.show = false"></v-btn>
            </div>

            <v-card-text class="pa-6 custom-scroll d-flex flex-column gap-6">
                <v-form ref="purchaseForm">
                    <v-card variant="outlined" class="bg-white rounded-lg border-thin overflow-hidden shadow-sm">
                        <div class="bg-grey-lighten-4 border-b px-5 py-3 d-flex align-center gap-2">
                            <v-icon size="20" color="success">mdi-domain</v-icon>
                            <span class="text-subtitle-2 font-weight-black text-uppercase text-grey-darken-3 tracking-wide">Dados do Pedido e Fornecedor</span>
                        </div>
                        <div class="pa-5">
                            <v-row dense class="row-gap">
                                <v-col cols="12" md="6"><v-text-field v-model="modal.form.description" label="Descrição / Referência da Compra*" variant="outlined" density="comfortable" color="success" class="ui-field font-weight-bold" placeholder="Ex: Compra de Tecidos Agosto"></v-text-field></v-col>
                                <v-col cols="12" md="6">
                                    <v-autocomplete v-model="modal.form.supplier_id" :items="auxData.suppliers" item-title="name" item-value="id" label="Selecione o Fornecedor*" variant="outlined" density="comfortable" color="success" class="ui-field">
                                        <template v-slot:prepend-item><v-list-item title="Cadastrar Novo Fornecedor Rápido" prepend-icon="mdi-plus-circle" class="text-success font-weight-black bg-success-subtle" @click="openQuickSupplierModal"></v-list-item><v-divider class="my-2"></v-divider></template>
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
                                        color="success"
                                        class="ui-field font-weight-bold"
                                        :disabled="!isAdmin"
                                        :readonly="!isAdmin"
                                        :hint="!isAdmin ? 'Empresa atrelada automaticamente ao seu usuário' : ''"
                                        persistent-hint
                                    ></v-autocomplete>
                                </v-col>

                                <v-col cols="12" md="4"><v-autocomplete v-model="modal.form.chart_of_accounts_id" :items="auxData.chartOfAccounts" item-title="name" item-value="id" label="Plano de Contas (Despesa)" variant="outlined" density="comfortable" color="success" class="ui-field" clearable></v-autocomplete></v-col>
                                <v-col cols="12" md="2"><v-text-field v-model="modal.form.order_date" label="Data de Emissão*" type="date" variant="outlined" density="comfortable" color="success" class="ui-field font-weight-bold"></v-text-field></v-col>
                                <v-col cols="12" md="2"><v-text-field v-model="modal.form.delivery_date" label="Previsão Entrega*" type="date" variant="outlined" density="comfortable" color="success" class="ui-field font-weight-bold"></v-text-field></v-col>

                                <v-col cols="12">
                                    <div class="d-flex align-center justify-space-between bg-green-lighten-5 px-5 py-3 rounded-lg border border-green-lighten-4">
                                        <div class="d-flex align-center gap-3">
                                            <v-icon color="success" size="28">mdi-warehouse</v-icon>
                                            <div>
                                                <div class="font-weight-black text-body-2 text-green-darken-4">Movimentar Estoque Automaticamente</div>
                                                <div class="text-caption text-green-darken-3 mt-1">Ao salvar, os itens que possuem vínculo serão somados imediatamente no estoque.</div>
                                            </div>
                                        </div>
                                        <v-switch v-model="modal.form.move_stock" color="success" hide-details inset></v-switch>
                                    </div>
                                </v-col>
                            </v-row>
                        </div>
                    </v-card>

                    <v-card variant="outlined" class="bg-white rounded-lg border-thin overflow-hidden shadow-sm mt-6">
                        <div class="bg-grey-lighten-4 border-b px-5 py-3 d-flex align-center justify-space-between">
                            <div class="d-flex align-center gap-2"><v-icon size="20" color="success">mdi-format-list-bulleted</v-icon><span class="text-subtitle-2 font-weight-black text-uppercase text-grey-darken-3 tracking-wide">Inclusão de Itens</span></div>
                            <v-chip color="success" size="default" variant="flat" class="font-weight-black px-4 chip-3d">{{ modal.items.length }} Itens Adicionados</v-chip>
                        </div>
                        <div class="pa-5 bg-white border-b border-opacity-50">
                            <v-row dense align="center" class="row-gap">
                                <v-col cols="12" md="4">
                                    <v-autocomplete v-model="currentItem.product_id" :items="auxData.products" item-title="name" item-value="id" label="Buscar Produto no Estoque" variant="outlined" density="comfortable" hide-details color="success" class="ui-field font-weight-bold" @update:model-value="onProductSelect">
                                        <template v-slot:prepend-item><v-list-item title="Cadastrar Novo Produto Rápido" prepend-icon="mdi-plus-circle" class="text-primary font-weight-black bg-blue-lighten-5" @click="openQuickProductModal"></v-list-item><v-divider class="my-2"></v-divider></template>
                                    </v-autocomplete>
                                </v-col>
                                <v-col cols="12" md="3" v-if="!currentItem.product_id"><v-text-field v-model="currentItem.description" label="Descrição Avulsa (S/ Estoque)" variant="outlined" density="comfortable" hide-details class="ui-field"></v-text-field></v-col>
                                <v-col cols="4" md="1"><v-select v-model="currentItem.unit_of_measure" :items="['un', 'm', 'kg', 'g', 'l', 'cx', 'par', 'pct']" label="UN*" variant="outlined" density="comfortable" hide-details color="success" class="ui-field font-weight-bold text-center"></v-select></v-col>
                                <v-col cols="4" md="1"><v-text-field v-model.number="currentItem.quantity" label="Qtd.*" type="number" min="1" variant="outlined" density="comfortable" hide-details class="ui-field font-weight-bold text-center" @input="calcCurrentTotal"></v-text-field></v-col>
                                <v-col cols="4" md="1"><v-text-field v-model.number="currentItem.unit_price" label="V. Unit.*" type="number" step="0.01" variant="outlined" density="comfortable" hide-details class="ui-field font-weight-bold text-success-darken-2" prefix="R$" @input="calcCurrentTotal"></v-text-field></v-col>
                                <v-col cols="12" md="2" class="d-flex justify-end"><v-btn color="blue-darken-3" variant="flat" height="48" class="btn-3d w-100 font-weight-bold text-body-2" @click="addItemToList" :disabled="!isCurrentItemValid"><v-icon start size="20">mdi-plus-thick</v-icon> Adicionar</v-btn></v-col>
                            </v-row>
                        </div>

                        <div class="overflow-auto custom-scroll" style="min-height: 250px; max-height: 400px;">
                            <div class="grid-header sticky-head grid-surface-light border-b" style="grid-template-columns: 60px 2fr 80px 100px 140px 140px 160px; min-width: 900px;">
                                <div class="cell center header-text">Seq.</div><div class="cell header-text">Descrição do Material / Produto</div><div class="cell center header-text">UN</div><div class="cell center header-text">Qtd</div><div class="cell center header-text">Valor Unit.</div><div class="cell center header-text text-success-darken-3">Subtotal</div><div class="cell center header-text">Ações</div>
                            </div>
                            <div v-if="modal.items.length === 0" class="d-flex flex-column justify-center align-center py-12 opacity-40 bg-grey-lighten-5 h-100"><v-icon size="48" class="mb-3">mdi-basket-plus-outline</v-icon><span class="text-body-2 font-weight-bold">A lista de itens está vazia.</span></div>
                            <div v-else v-for="(item, index) in modal.items" :key="item.ui_id" class="grid-row" :class="zebraClass(index)" style="grid-template-columns: 60px 2fr 80px 100px 140px 140px 160px; min-width: 900px;">
                                <div class="cell center font-weight-black text-grey-darken-1" style="font-size: 15px;">{{ index + 1 }}</div>
                                <div class="cell"><div class="d-flex flex-column justify-center w-100 py-1"><span class="font-weight-medium text-grey-darken-4 text-truncate mb-1" style="font-size: 15px;">{{ item.product_name || item.description }}</span><v-chip v-if="item.product_id" size="small" color="success" variant="tonal" class="font-weight-bold px-3 align-self-start chip-3d"><v-icon start size="14">mdi-link</v-icon> VINCULADO</v-chip></div></div>
                                <div class="cell center"><span class="font-weight-bold text-grey-darken-3 text-uppercase" style="font-size: 14px;">{{ item.unit_of_measure || 'UN' }}</span></div>
                                <div class="cell center"><span class="font-mono font-weight-medium text-grey-darken-4" style="font-size: 15px;">{{ item.quantity }}</span></div>
                                <div class="cell center"><span class="font-mono font-weight-medium text-grey-darken-4" style="font-size: 15px;">{{ formatCurrencyValue(item.unit_price) }}</span></div>
                                <div class="cell center bg-green-lighten-5"><span class="font-mono font-weight-black text-success-darken-3" style="font-size: 15px;">{{ formatCurrency(item.total_price) }}</span></div>
                                <div class="cell center"><div class="actions-inline d-flex flex-nowrap"><v-btn icon size="small" class="action-btn bg-blue-grey-lighten-4 text-blue-grey-darken-3 btn-3d" @click="cloneItem(item)" title="Duplicar Item" variant="flat"><v-icon size="16">mdi-content-copy</v-icon></v-btn><v-btn icon size="small" class="action-btn action-edit btn-3d" @click="editItem(index)" title="Editar" variant="flat"><v-icon size="16">mdi-pencil</v-icon></v-btn><v-btn icon size="small" class="action-btn action-del btn-3d" @click="removeItem(index)" title="Excluir" variant="flat"><v-icon size="16">mdi-close-thick</v-icon></v-btn></div></div>
                            </div>
                        </div>
                        <div class="pa-5 bg-grey-lighten-3 border-t d-flex justify-end align-center shadow-inner">
                            <div class="d-flex align-center gap-4 bg-white px-6 py-3 rounded-lg elevation-1 border-thin border-success"><span class="text-body-2 font-weight-black text-uppercase text-grey-darken-2">Valor Total da Compra:</span><span class="text-h5 font-weight-black text-success-darken-3 tabular-nums">{{ formatCurrency(purchaseTotalValue) }}</span></div>
                        </div>
                    </v-card>

                    <v-card variant="outlined" class="bg-white rounded-lg border-thin overflow-hidden shadow-sm mt-6">
                        <div class="bg-grey-lighten-4 border-b px-5 py-3 d-flex align-center gap-2"><v-icon size="20" color="success">mdi-cash-multiple</v-icon><span class="text-subtitle-2 font-weight-black text-uppercase text-grey-darken-3 tracking-wide">Condições de Pagamento</span></div>
                        <div class="pa-5">
                            <v-row dense class="row-gap">
                                <v-col cols="12" md="4"><v-select v-model="modal.payment.method" :items="['Boleto Bancário', 'PIX', 'Cartão de Crédito', 'Transferência Bancária', 'Dinheiro']" label="Forma de Pagamento" variant="outlined" density="comfortable" color="success" class="ui-field font-weight-bold"></v-select></v-col>
                                <v-col cols="12" md="4"><v-select v-model="modal.payment.condition" :items="['À Vista', 'Parcelado']" label="Condição" variant="outlined" density="comfortable" color="success" class="ui-field font-weight-bold"></v-select></v-col>
                                <v-col cols="12" md="4" v-if="modal.payment.condition === 'Parcelado'"><v-select v-model.number="modal.payment.installments" :items="[2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]" label="Quantidade de Parcelas" variant="outlined" density="comfortable" color="success" class="ui-field font-weight-bold" @update:model-value="generateInstallments"></v-select></v-col>

                                <v-col cols="12" v-if="modal.payment.details.length > 0">
                                    <div class="border-thin rounded-lg overflow-hidden mt-2">
                                        <div class="bg-grey-lighten-4 px-4 py-2 text-caption font-weight-black text-uppercase border-b d-flex justify-space-between"><span>Detalhamento das Parcelas</span><v-btn size="small" variant="text" color="primary" class="btn-3d" @click="generateInstallments">Recalcular Valores</v-btn></div>
                                        <div class="pa-4 bg-white">
                                            <v-row dense>
                                                <v-col cols="12" md="6" v-for="(inst, idx) in modal.payment.details" :key="idx">
                                                    <div class="d-flex align-center gap-3 mb-2 bg-grey-lighten-5 pa-2 rounded-lg border">
                                                        <div class="text-body-2 font-weight-black text-grey-darken-2" style="width: 40px;">{{ idx + 1 }}x</div>
                                                        <v-text-field v-model="inst.due_date" label="Vencimento" type="date" variant="outlined" density="comfortable" hide-details class="bg-white flex-grow-1 ui-field"></v-text-field>
                                                        <v-text-field v-model.number="inst.value" label="Valor (R$)" type="number" step="0.01" variant="outlined" density="comfortable" hide-details class="bg-white flex-grow-1 font-weight-bold text-success-darken-3 ui-field"></v-text-field>
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

                    <v-card variant="outlined" class="bg-white rounded-lg border-thin overflow-hidden shadow-sm mt-6 mb-4">
                        <div class="bg-grey-lighten-4 border-b px-5 py-3 d-flex align-center gap-2"><v-icon size="20" color="success">mdi-paperclip</v-icon><span class="text-subtitle-2 font-weight-black text-uppercase text-grey-darken-3 tracking-wide">Anexos Iniciais e Observações</span></div>
                        <div class="pa-5">
                            <v-row dense class="row-gap">
                                <v-col cols="12" md="6"><v-file-input v-model="modal.files" label="Anexar Arquivos (Orçamentos, PDF, IMG)" variant="outlined" density="comfortable" prepend-inner-icon="mdi-cloud-upload" color="success" multiple chips show-size class="ui-field bg-grey-lighten-5"></v-file-input></v-col>
                                <v-col cols="12" md="6"><v-textarea v-model="modal.form.notes" label="Justificativa / Motivo (Opcional)" variant="outlined" rows="3" density="comfortable" class="ui-field"></v-textarea></v-col>
                            </v-row>
                        </div>
                    </v-card>
                </v-form>
            </v-card-text>

            <div class="px-8 py-5 border-t bg-white d-flex justify-space-between align-center flex-shrink-0 elevation-10 z-10 relative">
                <div class="d-flex align-center gap-2 text-body-2 text-grey font-weight-bold bg-grey-lighten-4 px-4 py-2 rounded-lg border"><v-icon size="20">mdi-account-circle</v-icon> Operador: <span class="text-success font-weight-black">{{ userStore.profile?.full_name || userStore.user?.email }}</span></div>
                <div class="d-flex gap-3">
                    <v-btn variant="outlined" color="grey-darken-2" class="btn-3d px-8 font-weight-bold text-body-2" height="50" @click="modal.show = false" :disabled="modal.saving">Cancelar</v-btn>
                    <v-btn color="success" variant="flat" class="btn-3d px-10 font-weight-black text-body-1 shadow-button" height="50" @click="saveFullPurchase" :loading="modal.saving"><v-icon start size="24" class="mr-2">mdi-content-save-check</v-icon> SALVAR COMPRA</v-btn>
                </div>
            </div>
        </v-card>
    </v-dialog>

    <v-dialog v-model="financialPreviewModal.show" max-width="900" persistent transition="dialog-bottom-transition">
        <v-card class="rounded-lg overflow-hidden">
            <div class="px-6 py-5 bg-teal-darken-4 text-white d-flex align-center justify-space-between">
                <div class="d-flex align-center gap-4">
                    <v-icon size="36" color="teal-lighten-4">mdi-bank-transfer-in</v-icon>
                    <div>
                        <div class="text-h5 font-weight-black leading-tight">Autorização de Lançamento Financeiro</div>
                        <div class="text-caption font-weight-medium opacity-80 mt-1">Revise as condições antes de gerar obrigações no Contas a Pagar.</div>
                    </div>
                </div>
                <v-btn icon="mdi-close" variant="text" size="large" class="btn-3d" @click="financialPreviewModal.show = false"></v-btn>
            </div>

            <div class="pa-6 bg-grey-lighten-5">
                <v-alert type="warning" variant="tonal" border="start" density="compact" class="mb-6 font-weight-bold text-body-2 rounded-lg">
                    ATENÇÃO: A confirmação criará <strong>{{ financialPreviewModal.installments.length }} lançamento(s)</strong> no módulo financeiro definitivo. Certifique-se de que os valores e vencimentos estão corretos.
                </v-alert>

                <div class="d-flex flex-wrap justify-space-between align-center mb-6 bg-white pa-5 rounded-lg border-thin shadow-sm gap-4">
                    <div>
                        <div class="text-body-2 text-uppercase font-weight-bold text-grey tracking-wide">Fornecedor / Beneficiário</div>
                        <div class="text-h6 font-weight-black text-grey-darken-4">{{ financialPreviewModal.item?.supplier_name || financialPreviewModal.item?.entity_name }}</div>
                        <div class="text-body-2 text-grey mt-1">Ref: {{ financialPreviewModal.item?.description }}</div>
                    </div>
                    <v-divider vertical class="d-none d-md-flex"></v-divider>
                    <div class="text-right">
                        <div class="text-body-2 text-uppercase font-weight-bold text-grey tracking-wide">Valor Total da Operação</div>
                        <div class="text-h4 font-weight-black text-teal-darken-3 tabular-nums">{{ formatCurrency(financialPreviewModal.item?.total_value) }}</div>
                        <div class="text-body-2 text-grey font-weight-bold mt-1">Condição: {{ financialPreviewModal.item?.payment_details?.condition }} ({{ financialPreviewModal.item?.payment_details?.installments || 1 }}x)</div>
                    </div>
                </div>

                <div class="text-subtitle-1 font-weight-black text-uppercase text-grey-darken-2 mb-3 d-flex align-center gap-2"><v-icon size="24" color="grey-darken-1">mdi-calendar-multiselect</v-icon> Cronograma de Parcelas</div>

                <div class="bg-white border-thin rounded-lg overflow-hidden shadow-sm">
                    <div class="grid-header bg-grey-lighten-4 border-b" style="display: grid; grid-template-columns: 80px 1fr 180px 160px 180px;">
                        <div class="cell center font-weight-bold text-body-2">Parc.</div>
                        <div class="cell font-weight-bold text-body-2">Vencimento Original</div>
                        <div class="cell center font-weight-bold text-body-2">Valor da Parcela</div>
                        <div class="cell center font-weight-bold text-body-2">Situação Atual</div>
                        <div class="cell center font-weight-bold text-body-2">Data Pagto.</div>
                    </div>
                    <div v-for="(inst, idx) in financialPreviewModal.installments" :key="idx" class="grid-row border-b hover:bg-grey-lighten-5 transition-all" style="display: grid; grid-template-columns: 80px 1fr 180px 160px 180px;">
                        <div class="cell center font-weight-black text-grey-darken-2" style="font-size: 15px;">{{ idx + 1 }}/{{ financialPreviewModal.installments.length }}</div>
                        <div class="cell"><v-text-field v-model="inst.due_date" type="date" variant="outlined" density="comfortable" hide-details class="w-100 bg-white font-weight-bold ui-field"></v-text-field></div>
                        <div class="cell center"><v-text-field v-model.number="inst.value" type="number" step="0.01" variant="outlined" density="comfortable" hide-details class="w-100 text-center font-weight-black text-teal-darken-3 bg-white ui-field"></v-text-field></div>
                        <div class="cell center">
                            <v-switch v-model="inst.is_paid" :color="inst.is_paid ? 'success' : 'warning'" :label="inst.is_paid ? 'PAGO' : 'ABERTO'" hide-details density="compact" class="font-weight-black"></v-switch>
                        </div>
                        <div class="cell center">
                            <v-text-field v-if="inst.is_paid" v-model="inst.payment_date" type="date" variant="outlined" density="comfortable" hide-details color="success" class="w-100 bg-green-lighten-5 font-weight-bold ui-field"></v-text-field>
                            <span v-else class="text-body-2 text-grey opacity-60 font-italic">Pendente</span>
                        </div>
                    </div>
                </div>
            </div>

            <div class="pa-5 border-t d-flex justify-space-between align-center bg-white">
                <div class="text-body-2 text-grey font-weight-bold"><v-icon size="20" class="mr-1">mdi-shield-check</v-icon> Autorizado por: {{ userStore.profile?.full_name }}</div>
                <div class="d-flex gap-3">
                    <v-btn variant="outlined" color="grey-darken-3" class="btn-3d font-weight-bold px-6 text-body-2" height="44" @click="financialPreviewModal.show = false">Cancelar</v-btn>
                    <v-btn color="teal-darken-3" variant="flat" class="btn-3d font-weight-black px-8 text-body-2" height="44" @click="confirmFinancialLaunch" :loading="financialPreviewModal.loading">
                        <v-icon start size="20">mdi-check-all</v-icon> CONFIRMAR LANÇAMENTO
                    </v-btn>
                </div>
            </div>
        </v-card>
    </v-dialog>

    <v-dialog v-model="detailsModal.show" max-width="1000" scrollable>
        <v-card class="rounded-lg bg-grey-lighten-4 h-100">
            <div class="px-6 py-4 bg-info text-white d-flex align-center justify-space-between flex-shrink-0">
                <div class="d-flex align-center gap-3">
                    <div class="bg-white-20 rounded-lg d-flex align-center justify-center" style="width: 40px; height: 40px;"><v-icon size="24">mdi-text-box-search-outline</v-icon></div>
                    <div>
                        <div class="text-h6 font-weight-black">Detalhes e Auditoria - Compra #{{ formatCode(detailsModal.item) }}</div>
                        <div class="text-caption opacity-80">Rastreabilidade completa, informações logísticas e financeiras.</div>
                    </div>
                </div>
                <v-btn icon="mdi-close" variant="text" class="btn-3d" @click="detailsModal.show = false"></v-btn>
            </div>

            <v-card-text class="pa-6 custom-scroll d-flex flex-column gap-6">
                <v-card variant="flat" class="bg-white border-thin pa-5 shadow-sm rounded-lg">
                    <v-row>
                        <v-col cols="6" md="3"><div class="text-body-2 text-grey text-uppercase font-weight-bold">Fornecedor</div><div class="font-weight-black text-body-2">{{ detailsModal.item?.supplier_name || detailsModal.item?.entity_name }}</div></v-col>
                        <v-col cols="6" md="3"><div class="text-body-2 text-grey text-uppercase font-weight-bold">Data Pedido</div><div class="font-weight-black text-body-2">{{ formatDateSafe(detailsModal.item?.order_date) }}</div></v-col>
                        <v-col cols="6" md="3"><div class="text-body-2 text-grey text-uppercase font-weight-bold">Prev. Entrega</div><div class="font-weight-black text-body-2">{{ formatDateSafe(detailsModal.item?.delivery_date) }}</div></v-col>
                        <v-col cols="6" md="3"><div class="text-body-2 text-grey text-uppercase font-weight-bold">Valor Total</div><div class="font-weight-black text-h6 text-success-darken-2 tabular-nums">{{ formatCurrency(detailsModal.item?.total_value) }}</div></v-col>
                        <v-col cols="12" md="6"><div class="text-body-2 text-grey text-uppercase font-weight-bold">Descrição da Compra</div><div class="text-body-2">{{ detailsModal.item?.description || '-' }}</div></v-col>
                        <v-col cols="12" md="6"><div class="text-body-2 text-grey text-uppercase font-weight-bold">Status Logístico Atual</div>
                            <v-chip size="default" :color="getProductionStatusColor(detailsModal.item?.production_status)" class="font-weight-black text-uppercase mt-1 chip-3d" style="font-size: 12px;">{{ formatProductionStatus(detailsModal.item?.production_status) }}</v-chip>
                        </v-col>
                    </v-row>
                </v-card>

                <v-card variant="flat" class="bg-white border-thin shadow-sm rounded-lg overflow-hidden">
                    <div class="bg-grey-lighten-4 border-b px-4 py-3 font-weight-black text-uppercase text-body-2 text-grey-darken-3 d-flex align-center gap-2"><v-icon size="20">mdi-credit-card-outline</v-icon> Informações de Pagamento</div>
                    <div class="pa-5 d-flex gap-8 flex-wrap">
                        <div><div class="text-body-2 text-grey font-weight-bold text-uppercase">Método</div><div class="font-weight-black text-body-2">{{ detailsModal.item?.payment_details?.method || '-' }}</div></div>
                        <div><div class="text-body-2 text-grey font-weight-bold text-uppercase">Condição</div><div class="font-weight-black text-body-2">{{ detailsModal.item?.payment_details?.condition || '-' }} ({{ detailsModal.item?.payment_details?.installments || 1 }}x)</div></div>
                        <div><div class="text-body-2 text-grey font-weight-bold text-uppercase">Status Financeiro</div><v-chip size="default" :color="detailsModal.item?.finance_payable_id ? 'success' : 'warning'" variant="flat" class="font-weight-bold mt-1 text-white chip-3d" style="font-size: 12px;">{{ detailsModal.item?.finance_payable_id ? 'LANÇADO NO CONTAS A PAGAR' : 'PENDENTE DE LANÇAMENTO' }}</v-chip></div>
                    </div>
                </v-card>

                <v-card variant="flat" class="bg-white border-thin shadow-sm rounded-lg overflow-hidden">
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

    <v-dialog v-model="statusModal.show" width="450">
        <v-card class="pa-6 rounded-lg border-t-lg border-t-primary">
            <div class="d-flex align-center gap-3 mb-4">
                <v-icon size="36" color="primary">mdi-truck-outline</v-icon>
                <div class="text-h6 font-weight-black leading-none">Atualizar Status de Produção</div>
            </div>
            <p class="text-body-2 text-grey mb-4">Acompanhamento logístico do pedido de compra.</p>

            <v-select v-model="statusModal.status" :items="statusOptions" item-title="label" item-value="value" variant="outlined" density="comfortable" color="primary" hide-details class="font-weight-bold ui-field"></v-select>

            <div class="d-flex justify-end gap-2 mt-6">
                <v-btn variant="text" color="grey-darken-2" class="font-weight-bold btn-3d text-body-2" @click="statusModal.show = false">Cancelar</v-btn>
                <v-btn color="primary" variant="flat" class="font-weight-black px-6 btn-3d text-body-2" height="44" @click="saveProductionStatus" :loading="statusModal.loading">Atualizar</v-btn>
            </div>
        </v-card>
    </v-dialog>

    <v-dialog v-model="quickModal.show" width="450">
        <v-card class="pa-6 rounded-lg border-t-lg border-t-success">
            <div class="d-flex align-center gap-3 mb-6">
                <v-icon size="36" :color="quickModal.type === 'product' ? 'primary' : 'success'">{{ quickModal.type === 'product' ? 'mdi-package-variant-closed' : 'mdi-truck-delivery' }}</v-icon>
                <div class="text-h6 font-weight-black leading-none">Cadastro Rápido de {{ quickModal.type === 'product' ? 'Produto' : 'Fornecedor' }}</div>
            </div>
            <v-text-field v-model="quickModal.name" :label="quickModal.type === 'product' ? 'Nome do Material' : 'Razão Social / Nome'" variant="outlined" density="comfortable" color="success" class="font-weight-bold ui-field"></v-text-field>
            <div class="d-flex justify-end gap-2 mt-4">
                <v-btn variant="text" color="grey-darken-2" class="font-weight-bold btn-3d text-body-2" @click="quickModal.show = false">Cancelar</v-btn>
                <v-btn color="success" variant="flat" class="font-weight-black px-6 btn-3d text-body-2" height="44" @click="saveQuickRegistration">Cadastrar e Usar</v-btn>
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
import logoDark from '@/assets/logo.png';
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
      } else {
        resolve('');
      }
    };
    img.onerror = () => resolve('');
    img.src = url;
  });
};

const PURCHASE_TYPE = 'product';

const appStore = useAppStore();
const themeStore = useThemeStore();
const companyStore = useCompanyStore();
const userStore = useUserStore();

const loadingPurchases = ref(false);
const purchases = ref<any[]>([]);

// FUNÇÃO PARA FORMATAR O CÓDIGO
const formatCode = (item: any) => {
    if (!item) return '';
    if (item.codigo) return String(item.codigo).padStart(5, '0');
    if (item.sequential_id) return String(item.sequential_id).padStart(5, '0');
    return item.id ? item.id.substring(0, 6).toUpperCase() : 'NOVO';
};

const isAdmin = computed(() => {
    const role = userStore.profile?.role?.toLowerCase();
    return role === 'admin' || role === 'super_admin' || role === 'financeiro';
});

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


// FILTROS COM BUSCA GLOBAL
const filters = reactive({ startDate: '', endDate: '', supplier: null, status: 'Todos', search: '' });

const filteredPurchases = computed(() => {
    let result = purchases.value;

    if (filters.search) {
        const s = filters.search.toLowerCase();
        result = result.filter(p =>
            (p.codigo && String(p.codigo).includes(s)) ||
            (p.sequential_id && String(p.sequential_id).includes(s)) ||
            (p.id && p.id.toLowerCase().includes(s)) ||
            (p.supplier_name && p.supplier_name.toLowerCase().includes(s)) ||
            (p.entity_name && p.entity_name.toLowerCase().includes(s)) ||
            (p.description && p.description.toLowerCase().includes(s)) ||
            (p.production_status && formatProductionStatus(p.production_status).toLowerCase().includes(s)) ||
            (p.total_value && p.total_value.toString().includes(s)) ||
            (p.payment_details?.condition && p.payment_details.condition.toLowerCase().includes(s))
        );
    }

    if (filters.startDate) result = result.filter(p => p.order_date >= filters.startDate);
    if (filters.endDate) result = result.filter(p => p.order_date <= filters.endDate);
    if (filters.supplier) result = result.filter(p => p.supplier_id === filters.supplier);
    if (filters.status !== 'Todos') result = result.filter(p => p.production_status === filters.status);
    return result;
});

const auxData = reactive({ suppliers: [] as any[], products: [] as any[], companies: [] as any[], chartOfAccounts: [] as any[], mrJackyId: null as any });

// MODAIS
const modal = reactive({ show: false, saving: false, files: [] as File[], form: { id: '', description: '', supplier_id: null, chart_of_accounts_id: null, order_date: new Date().toISOString().split('T')[0], delivery_date: new Date().toISOString().split('T')[0], notes: '', move_stock: true, company_id: null as any }, items: [] as any[], payment: { method: 'Boleto Bancário', condition: 'À Vista', installments: 1, details: [] as any[] } });
const financialPreviewModal = reactive({ show: false, loading: false, item: null as any, installments: [] as any[] });
const detailsModal = reactive({ show: false, item: null as any });
const quickModal = reactive({ show: false, type: '', name: '' });
const statusModal = reactive({ show: false, loading: false, item: null as any, status: '' });

const initialItemState = { ui_id: '', product_id: null, product_name: '', description: '', unit_of_measure: 'un', quantity: 1, unit_price: 0, total_price: 0 };
const currentItem = ref({ ...initialItemState });

const statusOptions = [
    { value: 'indefinido', label: 'Indefinido (Aguardando)' },
    { value: 'em_producao', label: 'Em Produção' },
    { value: 'com_fornecedor', label: 'Retido no Fornecedor' },
    { value: 'a_caminho', label: 'A Caminho (Em Trânsito)' },
    { value: 'entregue', label: 'Entregue / Concluído' },
    { value: 'cancelado', label: 'Cancelado' }
];

const formatProductionStatus = (status: string) => statusOptions.find(s => s.value === status)?.label || 'INDEFINIDO';
const getProductionStatusColor = (status: string) => {
    switch(status) {
        case 'entregue': return 'success';
        case 'a_caminho': return 'info';
        case 'em_producao': return 'primary';
        case 'com_fornecedor': return 'warning';
        case 'cancelado': return 'error';
        default: return 'error';
    }
};
const getAuditColor = (action: string) => {
    if (action.includes('Criação')) return 'success';
    if (action.includes('Status')) return 'info';
    if (action.includes('Financeiro')) return 'purple';
    return 'warning';
};

onMounted(async () => { await fetchAuxData(); await fetchPurchases(); });

const fetchAuxData = async () => {
    try {
        const { data: supData } = await supabase.from('suppliers_mj').select('id, nome, razao_social').order('nome');
        if (supData) auxData.suppliers = supData.map((s: any) => ({ id: s.id, name: s.nome || s.razao_social || 'Sem Nome' }));

        const { data: prodData } = await supabase.from('stock').select('id, fabric_type, base_price').order('fabric_type');
        if (prodData) auxData.products = prodData.map((p: any) => ({ id: p.id, name: p.fabric_type, default_price: p.base_price || 0 }));

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
            .eq('purchase_type', 'product')
            .eq('is_quotation', false)
            .order('created_at', { ascending: false });

        if (!isAdmin.value) {
            if (userStore.profile?.company_id) {
                query = query.eq('company_id', userStore.profile.company_id);
            } else {
                query = query.eq('created_by', userStore.user?.id);
            }
        } else {
            if (!companyStore.isGlobalView && companyStore.context) {
                query = query.eq('company_id', companyStore.context);
            }
        }

        const { data, error } = await query;
        if (error) throw error;
        purchases.value = data || [];
    } catch(e) { appStore.showSnackbar('Erro ao buscar compras', 'error'); }
    finally { loadingPurchases.value = false; }
};

const createLogEntry = (action: string, details: string) => ({
    date: new Date().toISOString(),
    user: userStore.profile?.full_name || userStore.user?.email || 'Sistema',
    action, details
});

const openStatusModal = (item: any) => {
    statusModal.item = item;
    statusModal.status = item.production_status || 'indefinido';
    statusModal.show = true;
};

const saveProductionStatus = async () => {
    statusModal.loading = true;
    try {
        const item = statusModal.item;
        const oldStatus = formatProductionStatus(item.production_status);
        const newStatus = formatProductionStatus(statusModal.status);

        const newLog = createLogEntry('Alteração de Status Logístico', `De "${oldStatus}" para "${newStatus}"`);
        const currentLogs = item.audit_log || [];

        const { error } = await supabase.from('purchases').update({
            production_status: statusModal.status,
            audit_log: [...currentLogs, newLog]
        }).eq('id', item.id);

        if (error) throw error;
        appStore.showSnackbar('Status Atualizado!', 'success');
        statusModal.show = false;
        fetchPurchases();
    } catch(e: any) { appStore.showSnackbar('Erro: ' + e.message, 'error'); }
    finally { statusModal.loading = false; }
};

const openNewPurchaseModal = () => {
    const defaultCompanyId = isAdmin.value
        ? (companyStore.context || auxData.mrJackyId || (auxData.companies.length ? auxData.companies[0].id : null))
        : userStore.profile?.company_id;

    modal.form = {
        id: '',
        description: '',
        supplier_id: null,
        chart_of_accounts_id: null,
        order_date: new Date().toISOString().split('T')[0],
        delivery_date: new Date().toISOString().split('T')[0],
        notes: '',
        move_stock: true,
        company_id: defaultCompanyId
    };
    modal.items = []; modal.files = []; modal.payment = { method: 'Boleto Bancário', condition: 'À Vista', installments: 1, details: [] };
    currentItem.value = { ...initialItemState, ui_id: Math.random().toString(36).substr(2, 9) };
    modal.show = true;
};

const openEditModal = (item: any) => {
    modal.form = { ...item };
    modal.payment = item.payment_details || { method: 'Boleto Bancário', condition: 'À Vista', installments: 1, details: [] };
    modal.items = (item.purchase_items || []).map((i:any) => ({
        ...i,
        ui_id: Math.random().toString(36).substr(2, 9),
        product_name: i.description,
        unit_of_measure: i.unit_of_measure || 'un'
    }));
    modal.show = true;
};

const clonePurchase = (item: any) => {
    openEditModal(item).then(() => {
        modal.form.id = '';
        modal.form.description = `${modal.form.description} (Cópia)`;
    });
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

const onProductSelect = (prodId: any) => { if (!prodId) { currentItem.value.product_name = ''; return; } const prod = auxData.products.find(p => p.id === prodId); if (prod) { currentItem.value.product_name = prod.name; currentItem.value.description = prod.name; if (!currentItem.value.unit_price) { currentItem.value.unit_price = prod.default_price || 0; calcCurrentTotal(); } } };
const calcCurrentTotal = () => { currentItem.value.total_price = (Number(currentItem.value.quantity) || 0) * (Number(currentItem.value.unit_price) || 0); };
const isCurrentItemValid = computed(() => (currentItem.value.product_id || currentItem.value.description.trim().length > 0) && currentItem.value.quantity > 0 && currentItem.value.unit_price > 0);
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

const saveFullPurchase = async () => {
    const targetCompanyId = modal.form.company_id;

    if (!targetCompanyId) {
        appStore.showSnackbar('Você não tem empresa vinculada.', 'error');
        return;
    }

    if (!modal.form.description) { appStore.showSnackbar('Descrição obrigatória.', 'warning'); return; }
    if (!modal.form.supplier_id || modal.items.length === 0) { appStore.showSnackbar('Adicione fornecedor e itens.', 'warning'); return; }
    if (sumOfInstallments.value !== purchaseTotalValue.value && modal.payment.condition === 'Parcelado') { appStore.showSnackbar('A soma das parcelas difere do total.', 'error'); return; }

    modal.saving = true;
    try {
        const supInfo = auxData.suppliers.find(s => s.id === modal.form.supplier_id);
        const newAttachments = await uploadAttachments();
        const finalAttachments = [...(modal.form.attachments || []), ...newAttachments];
        const isNew = !modal.form.id;

        const purchaseHeader = {
            purchase_type: PURCHASE_TYPE, description: modal.form.description,
            supplier_id: modal.form.supplier_id, supplier_name: supInfo?.name || 'Fornecedor', entity_name: supInfo?.name || 'Fornecedor',
            chart_of_accounts_id: modal.form.chart_of_accounts_id,
            order_date: modal.form.order_date, delivery_date: modal.form.delivery_date,
            total_value: purchaseTotalValue.value, move_stock: modal.form.move_stock,
            notes: modal.form.notes, company_id: targetCompanyId,
            attachments: finalAttachments, payment_details: modal.payment,
            is_quotation: false
        } as any;

        if (isNew) {
            purchaseHeader.created_by = userStore.user?.id;
            purchaseHeader.created_by_name = userStore.profile?.full_name || userStore.user?.email;
            purchaseHeader.production_status = 'indefinido';
            purchaseHeader.audit_log = [createLogEntry('Criação da Compra', `Compra registrada com ${modal.items.length} itens no valor de ${formatCurrency(purchaseTotalValue.value)}`)];

            const { data: hd, error: he } = await supabase.from('purchases').insert(purchaseHeader).select('id').single();
            if (he) throw he;

            const itemsPayload = modal.items.map(i => ({
                purchase_id: hd.id,
                product_id: i.product_id,
                description: i.product_id ? i.product_name : i.description,
                quantity: i.quantity,
                unit_of_measure: i.unit_of_measure,
                unit_price: i.unit_price,
                total_price: i.total_price
            }));
            await supabase.from('purchase_items').insert(itemsPayload);

            if (modal.form.move_stock) {
                for (const sItem of itemsPayload.filter(i => i.product_id)) {
                    const { data: cs } = await supabase.from('stock').select('available_meters').eq('id', sItem.product_id).single();
                    if (cs) await supabase.from('stock').update({ available_meters: Number(cs.available_meters || 0) + Number(sItem.quantity) }).eq('id', sItem.product_id);
                }
            }
        } else {
            purchaseHeader.updated_at = new Date().toISOString();
            purchaseHeader.updated_by_name = userStore.profile?.full_name || userStore.user?.email;
            const currentLogs = modal.form.audit_log || [];
            purchaseHeader.audit_log = [...currentLogs, createLogEntry('Edição Manual', `Edição das informações da compra, itens ou pagamento.`)];

            await supabase.from('purchases').update(purchaseHeader).eq('id', modal.form.id);
            await supabase.from('purchase_items').delete().eq('purchase_id', modal.form.id);
            const itemsPayload = modal.items.map(i => ({
                purchase_id: modal.form.id,
                product_id: i.product_id,
                description: i.product_id ? i.product_name : i.description,
                quantity: i.quantity,
                unit_of_measure: i.unit_of_measure,
                unit_price: i.unit_price,
                total_price: i.total_price
            }));
            await supabase.from('purchase_items').insert(itemsPayload);
        }

        appStore.showSnackbar('Compra Salva!', 'success');
        modal.show = false; fetchPurchases();
    } catch(e: any) { appStore.showSnackbar('Erro ao salvar: ' + e.message, 'error'); }
    finally { modal.saving = false; }
};

const openFinancialPreview = (item: any) => {
    if (item.finance_payable_id) return;
    financialPreviewModal.item = item;
    let rawInstallments = item.payment_details?.details || [];
    if (rawInstallments.length === 0) rawInstallments = [{ due_date: item.delivery_date, value: item.total_value }];
    financialPreviewModal.installments = rawInstallments.map((inst: any) => ({ ...inst, is_paid: false, payment_date: new Date().toISOString().split('T')[0] }));
    financialPreviewModal.show = true;
};

const confirmFinancialLaunch = async () => {
    financialPreviewModal.loading = true;
    try {
        const item = financialPreviewModal.item; const installments = financialPreviewModal.installments;
        const payloads = installments.map((inst: any, idx: number) => {
            const isParceled = installments.length > 1;
            const seqCode = formatCode(item);
            const desc = isParceled ? `[COMPRA PARCELADA] #${seqCode} - ${item.description} (Parc. ${idx + 1}/${installments.length})` : `[COMPRA] #${seqCode} - ${item.description}`;
            return { description: desc, entity_name: item.supplier_name || item.entity_name, value: inst.value, due_date: inst.due_date, status: inst.is_paid ? 'pago' : 'em_aberto', payment_date: inst.is_paid ? inst.payment_date : null, company_id: item.company_id || (companyStore.context === 'global' ? null : companyStore.context), chart_of_accounts_id: item.chart_of_accounts_id || null };
        });

        const { data, error } = await supabase.from('finance_payables').insert(payloads).select('id');
        if (error) throw error;

        const newLog = createLogEntry('Lançamento Financeiro', `Gerado ${installments.length} registro(s) no Contas a Pagar.`);
        const currentLogs = item.audit_log || [];
        if (data && data.length > 0) {
            await supabase.from('purchases').update({ finance_payable_id: data[0].id, audit_log: [...currentLogs, newLog] }).eq('id', item.id);
        }

        appStore.showSnackbar('Lançado no Contas a Pagar!', 'success');
        financialPreviewModal.show = false; fetchPurchases();
    } catch(e: any) { appStore.showSnackbar('Erro financeiro: ' + e.message, 'error'); }
    finally { financialPreviewModal.loading = false; }
};

const printPurchase = async (item: any) => {
  try {
    const orderId = item?.id;
    if (!orderId) { appStore.showSnackbar("Pedido inválido para impressão.", "error"); return; }

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
      } catch (err) { console.warn("Não foi possível buscar a empresa do pedido pro PDF", err); }
    }
    const companyName = (pdfCompany.trade_name || pdfCompany.corporate_name || companyStore.currentCompanyName || 'Empresa').toUpperCase();

    let companyText1 = companyName;
    let companyText2 = `CNPJ: ${pdfCompany.cnpj || 'N/A'}`;
    let companyText3 = `${pdfCompany.address_line || 'Endereço não configurado'}`;
    let companyText4 = `${pdfCompany.city || ''} ${pdfCompany.state ? '- ' + pdfCompany.state : ''} | ${pdfCompany.email || ''}`;

    if (companyName.includes('JACKY') || companyName.includes('MR JACKY') || companyName.includes('HOLDING')) {
        companyText1 = "MR JACKY CONFECCOES LTDA";
        companyText2 = "CNPJ: 20.631.721/0001-07";
        companyText3 = "Rua Luiz Montanhan, 1302 - Tiete/SP";
        companyText4 = "Contato: (15) 99847-8789 | financeiro@mrjacky.com";
    } else if (companyName.includes('SANTOS') || companyName.includes('MJ') || companyName.includes('CAJUIA')) {
        companyText1 = "CONFECCOES MJ";
        companyText2 = "CNPJ: 53.756.096/0001-89";
        companyText3 = "RUA LUIZ MONTANHAN, 1302 (BARRACÃO TERRA NOVA)";
        companyText4 = "Tietê/SP - CEP: 18530-000";
    }

const logoUrl = userStore.currentModule === 'cajuia' ? logoCajuia : logoLight;
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
    doc.text(`PEDIDO DE COMPRA N° ${orderNo}`, pageW / 2, barY + 5.5, { align: "center" });
    doc.setFontSize(10); doc.text(`EMISSÃO: ${formatDate(item.order_date)}`, pageW - M - 2, barY + 5.5, { align: "right" });

    const forncBoxY = barY + barH + 6;
    doc.setFont("helvetica", "bold"); doc.setFontSize(9.5);
    doc.setFillColor(230); doc.rect(M, forncBoxY, boxW, 7, "F"); doc.setDrawColor(180); doc.rect(M, forncBoxY, boxW, 7);
    doc.text("DADOS DO FORNECEDOR", M + 2, forncBoxY + 5);

    const forncRows = [
        ["Fornecedor:", item.supplier_name || item.entity_name || "—", "Prev. Entrega:", formatDate(item.delivery_date)],
        ["Ref/Desc:", item.description || "—", "Status Log.:", formatProductionStatus(item.production_status).toUpperCase()]
    ];
    autoTable(doc, {
        startY: forncBoxY + 7,
        theme: "grid",
        tableWidth: boxW,
        margin: { left: M, right: M },
        styles: { fontSize: 8.5, cellPadding: 1.5, textColor: 0, lineColor: [200, 200, 200], lineWidth: 0.2, minCellHeight: 7, valign: "middle" },
        bodyStyles: { fillColor: [255, 255, 255] },
        columnStyles: { 0: { cellWidth: 22, fontStyle: "bold" }, 1: { cellWidth: 83 }, 2: { cellWidth: 30, fontStyle: "bold" }, 3: { cellWidth: 55 } },
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
        doc.text("OBSERVAÇÕES DO PEDIDO:", M + 2, lastY + 4);
        doc.setFont("helvetica", "normal"); doc.setTextColor(0);
        doc.text(splitNotes, M + 2, lastY + 9);
        lastY += notesHeight + 5;
    }

    doc.setFont("helvetica", "bold"); doc.setFontSize(9.5);
    doc.setFillColor(230); doc.setDrawColor(180); doc.rect(M, lastY, boxW, 7, "F"); doc.rect(M, lastY, boxW, 7);
    doc.setTextColor(0); doc.text("PRODUTOS / MATERIAIS", M + 2, lastY + 5);

    const productsBody = (item.purchase_items || []).map((it: any, idx: number) => [
        String(idx + 1),
        it.description || 'Produto sem descrição',
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
        head: [["ITEM", "DESCRIÇÃO DO MATERIAL", "QTD", "VALOR UNIT.", "SUBTOTAL"]],
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
    doc.text(`TOTAL DA COMPRA: ${money(item.total_value)}`, rightBoxX + rightBoxW - 2, afterProductsY + 6.5, { align: "right" });

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
    doc.setFont("helvetica", "normal"); doc.setFontSize(8); doc.text("RESPONSÁVEL PELA COMPRA", pageW / 2, signY + 16, { align: "center" });

    const totalPages = doc.getNumberOfPages();
    for (let i = 1; i <= totalPages; i++) {
        doc.setPage(i); doc.setFontSize(7); doc.setTextColor(150);
        doc.text("Gerado com MJProcess", pageW - M, pageH - 5, { align: "right" });
    }

    doc.save(`Pedido_Compra_${orderNo}.pdf`);
    appStore.showSnackbar("PDF gerado com sucesso.", "success");
  } catch (e: any) {
    console.error("printOrder error:", e);
    appStore.showSnackbar(`Erro ao gerar PDF: ${e?.message || e}`, "error");
  }
};

const exportListToPDF = () => {
    const doc = new jsPDF('landscape');
    doc.setFont("helvetica", "bold");
    doc.setFontSize(16);
    doc.text("Relatório Geral de Compras", 14, 15);
    doc.setFontSize(10);
    doc.setFont("helvetica", "normal");
    doc.text(`Gerado em: ${new Date().toLocaleString('pt-BR')}`, 14, 22);

    const tableData = filteredPurchases.value.map(i => [
        formatCode(i),
        i.supplier_name || i.entity_name,
        i.description || '-',
        formatDateSafe(i.order_date),
        formatProductionStatus(i.production_status),
        formatCurrency(i.total_value),
        i.finance_payable_id ? 'Sim' : 'Não'
    ]);

    autoTable(doc, {
        startY: 30,
        theme: "grid",
        head: [["Cód", "Fornecedor", "Descrição", "Data Pedido", "Status Produção", "Valor Total", "Lançado Fin."]],
        body: tableData,
        styles: { fontSize: 9, cellPadding: 3 },
        headStyles: { fillColor: [40, 40, 40], textColor: 255, fontStyle: 'bold' }
    });

    doc.save("Relatorio_Compras_Grid.pdf");
};

const exportToExcel = () => {
    const data = filteredPurchases.value.map(i => ({
        "Cód": formatCode(i),
        "Fornecedor": i.supplier_name || i.entity_name,
        "Descrição": i.description,
        "Data Pedido": formatDateSafe(i.order_date),
        "Prev. Entrega": formatDateSafe(i.delivery_date),
        "Status Produção": formatProductionStatus(i.production_status),
        "Valor Total": i.total_value,
        "Lançado Financeiro": i.finance_payable_id ? 'Sim' : 'Não'
    }));
    const ws = XLSX.utils.json_to_sheet(data);
    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, "Compras");
    XLSX.writeFile(wb, "Relatorio_Compras.xlsx");
};

const sharePurchase = (item: any, platform: 'whatsapp' | 'email') => {
    const code = formatCode(item);
    const text = `Pedido de Compra #${code} - ${item.description}\nFornecedor: ${item.supplier_name}\nValor: ${formatCurrency(item.total_value)}\nPrev. Entrega: ${formatDateSafe(item.delivery_date)}`;
    if (platform === 'whatsapp') window.open(`https://wa.me/?text=${encodeURIComponent(text)}`, '_blank');
    else window.open(`mailto:?subject=Pedido de Compra #${code}&body=${encodeURIComponent(text)}`, '_blank');
};

const openQuickSupplierModal = () => { quickModal.type = 'supplier'; quickModal.name = ''; quickModal.show = true; };
const openQuickProductModal = () => { quickModal.type = 'product'; quickModal.name = ''; quickModal.show = true; };
const saveQuickRegistration = async () => {
    if (!quickModal.name) return;
    try {
        if (quickModal.type === 'supplier') { const { data } = await supabase.from('suppliers_mj').insert({ nome: quickModal.name, situacao: 'Ativo', tipo_pessoa: 'PJ' }).select('id, nome').single(); if (data) { auxData.suppliers.push({ id: data.id, name: data.nome }); modal.form.supplier_id = data.id; } }
        else { const { data } = await supabase.from('stock').insert({ fabric_type: quickModal.name, unit_of_measure: 'm', base_price: 0, available_meters: 0 }).select('id, fabric_type, base_price').single(); if (data) { auxData.products.push({ id: data.id, name: data.fabric_type, default_price: data.base_price }); currentItem.value.product_id = data.id; onProductSelect(data.id); } }
        quickModal.show = false; appStore.showSnackbar('Cadastrado!', 'success');
    } catch(e) { appStore.showSnackbar('Erro', 'error'); }
};

const deletePurchase = async (id: string) => {
    if (!confirm('Excluir permanentemente?')) return;
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

.ui-field :deep(.v-field) { border-radius: 6px !important; background-color: #ffffff; font-size: 14px; }

.grid-scroll { scrollbar-gutter: stable; -webkit-overflow-scrolling: touch; }
.custom-scroll::-webkit-scrollbar { width: 8px; height: 8px; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.35); border-radius: 6px; }
.custom-scroll::-webkit-scrollbar-track { background: transparent; }

.grid-header, .grid-row { display: grid; align-items: stretch; width: 100%; min-width: 1100px; }

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

.header-text { font-size: 14px !important; font-weight: 900; text-transform: uppercase; letter-spacing: 0.5px; line-height: 1.2; }
.center { justify-content: center; text-align: center; }

.grid-header .cell {
    min-height: 44px;
    font-size: 14px !important;
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

.pill-ref { font-size: 12px !important; font-weight: 900; font-family: monospace; padding: 4px 6px; border-radius: 6px; white-space: nowrap; }
.solid-chip { display: inline-flex; align-items: center; justify-content: center; height: 28px; padding: 0 12px; font-size: 11px !important; font-weight: 900; color: #fff; text-transform: uppercase; white-space: nowrap; }

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

/* Base dos botões de ação */
.action-btn { width: 34px !important; height: 34px !important; color: #fff !important; }
.action-pay { background: #7b1fa2 !important; }
.action-edit { background: #1976d2 !important; }
.action-del { background: #c62828 !important; }

/* EFEITO 3D E ARREDONDAMENTO PARA BOTÕES */
.btn-3d {
    border-radius: 6px !important; /* Arredondamento suave */
    box-shadow: 0 3px 5px rgba(0,0,0,0.15), inset 0 2px 0 rgba(255,255,255,0.25) !important;
    transition: transform 0.1s ease, box-shadow 0.1s ease;
    text-transform: none !important;
}
.btn-3d:active {
    transform: translateY(2px); /* Efeito de ser "pressionado" */
    box-shadow: 0 1px 2px rgba(0,0,0,0.15), inset 0 1px 0 rgba(255,255,255,0.2) !important;
}

/* EFEITO 3D E ARREDONDAMENTO PARA TAGS (CHIPS) */
.chip-3d {
    border-radius: 6px !important; /* Arredondamento suave */
    box-shadow: 0 3px 5px rgba(0,0,0,0.12), inset 0 1px 0 rgba(255,255,255,0.25) !important;
    text-shadow: 0 1px 2px rgba(0,0,0,0.25); /* Sombra no texto para melhor leitura */
}

.row-gap { row-gap: 16px; margin-top: 8px; }
.shadow-inner { box-shadow: inset 0 2px 4px rgba(0,0,0,0.05); }
.shadow-button { box-shadow: 0 4px 15px rgba(46, 125, 50, 0.4); }
.bg-white-20 { background-color: rgba(255,255,255,0.2); }
.bg-success-subtle { background-color: #e8f5e9 !important; }
.tracking-wide { letter-spacing: 0.5px; }

/* Ocultar scrollbar dos botões contextuais */
.hide-scrollbar::-webkit-scrollbar { display: none; }
.hide-scrollbar { -ms-overflow-style: none; scrollbar-width: none; }
</style>
