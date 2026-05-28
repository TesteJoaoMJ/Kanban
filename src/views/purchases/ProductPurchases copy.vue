<template>
  <div
    class="receivables-layout font-sans fill-height d-flex flex-column relative overflow-hidden"
    :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 text-grey-darken-4' : 'bg-glass-dark text-white'"
  >
    <div class="content-wrapper d-flex flex-column fill-height z-10 relative">
      <div
        class="header-bar px-4 py-3 px-md-6 py-md-4 d-flex flex-column flex-md-row align-md-center justify-space-between flex-shrink-0"
        :class="themeStore.currentMode === 'light' ? 'bg-white border-b border-grey-lighten-2 shadow-sm' : 'bg-glass-header border-bottom-white-05'"
        style="gap: 12px;"
      >
        <div class="d-flex flex-column">
          <div class="breadcrumb text-body-2 d-none d-md-block">
            <span class="opacity-70">Produtos</span>
            <span class="mx-2 opacity-50">></span>
            <span class="font-weight-bold">Compra de Produtos</span>
          </div>
          <div class="d-flex align-center gap-2 mt-1">
             <div class="text-h5 font-weight-black tracking-tight leading-none">Gestão de Compras</div>
             <v-chip size="small" :color="companyStore.isGlobalView ? 'purple' : 'success'" class="font-weight-bold ml-2 rounded-0">
                {{ companyStore.isGlobalView ? 'HOLDING' : companyStore.currentCompanyName.toUpperCase() }}
             </v-chip>
          </div>
        </div>

        <div class="d-none d-md-flex align-center overflow-x-auto pb-1 pb-md-0" style="gap: 10px;">
          <v-btn color="success" variant="flat" class="btn-rect px-6 font-weight-bold text-body-2 text-uppercase letter-spacing-1 shadow-button" prepend-icon="mdi-cart-plus" height="44" @click="openNewPurchaseModal">
             Nova Compra
          </v-btn>
        </div>
      </div>

      <div class="px-4 px-md-6 py-4 flex-shrink-0 bg-white border-b d-flex flex-wrap align-center justify-space-between gap-3 shadow-sm z-10">
          <div class="d-flex align-center gap-4 flex-grow-1">
              <v-text-field v-model="filters.search" label="Buscar em todas as colunas..." prepend-inner-icon="mdi-magnify" variant="outlined" density="comfortable" class="ui-field bg-white" hide-details clearable style="max-width: 320px;"></v-text-field>

              <v-menu :close-on-content-click="false" location="bottom start">
                  <template v-slot:activator="{ props }">
                      <v-btn color="primary" variant="flat" v-bind="props" prepend-icon="mdi-filter-variant" class="btn-rect font-weight-bold text-body-1" height="48">
                          Filtros Avançados
                      </v-btn>
                  </template>
                  <v-card class="pa-5 rounded-0 shadow-sm border-thin" min-width="380">
                      <div class="text-h6 font-weight-black mb-4 text-primary d-flex align-center gap-2">
                          <v-icon>mdi-filter-outline</v-icon> Filtrar Compras
                      </div>
                      <v-text-field v-model="filters.startDate" label="Data Inicial" type="date" variant="outlined" density="comfortable" class="mb-3 ui-field" hide-details></v-text-field>
                      <v-text-field v-model="filters.endDate" label="Data Final" type="date" variant="outlined" density="comfortable" class="mb-3 ui-field" hide-details></v-text-field>
                      <v-autocomplete v-model="filters.supplier" :items="auxData.suppliers" item-title="name" item-value="id" label="Filtrar por Fornecedor" variant="outlined" density="comfortable" class="mb-3 ui-field" hide-details clearable></v-autocomplete>
                      <v-select v-model="filters.status" :items="['Todos', 'indefinido', 'em_producao', 'com_fornecedor', 'a_caminho', 'entregue', 'cancelado']" label="Status Logístico" variant="outlined" density="comfortable" class="mb-5 ui-field" hide-details></v-select>
                      <v-btn color="success" block variant="flat" height="48" class="font-weight-bold btn-rect text-body-1" @click="fetchPurchases">Aplicar Filtros</v-btn>
                  </v-card>
              </v-menu>
          </div>
          <div class="d-flex gap-2">
              <v-btn color="error" variant="outlined" height="48" class="btn-rect font-weight-bold text-body-1" prepend-icon="mdi-file-pdf-box" @click="exportListToPDF">Exportar PDF</v-btn>
              <v-btn color="teal-darken-3" variant="outlined" height="48" class="btn-rect font-weight-bold text-body-1" prepend-icon="mdi-microsoft-excel" @click="exportToExcel">Exportar Excel</v-btn>
          </div>
      </div>

      <div class="flex-grow-1 overflow-hidden d-flex flex-column transition-all px-4 px-md-6 py-4">
        <v-card class="flex-grow-1 d-flex flex-column rounded-0 border-thin overflow-hidden" :class="themeStore.currentMode === 'light' ? 'bg-white shadow-sm' : 'glass-card border-white-05'" :elevation="0">
          <div class="grid-scroll flex-grow-1 overflow-auto custom-scroll relative">
            <div class="grid-header sticky-head border-b" :class="[themeStore.currentMode === 'light' ? 'grid-surface-light' : 'grid-surface-dark']" style="grid-template-columns: 100px 2fr 130px 200px 160px 160px 160px 200px;">
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

            <div v-else v-for="(item, index) in filteredPurchases" :key="item.id" class="grid-row" :class="[themeStore.currentMode === 'light' ? 'grid-row-light' : 'grid-row-dark', zebraClass(index)]" style="grid-template-columns: 100px 2fr 130px 200px 160px 160px 160px 200px;">
                <div class="cell center">
                    <span class="pill-ref bg-grey-lighten-4 text-grey-darken-3">#{{ item.id.substring(0,6).toUpperCase() }}</span>
                </div>

                <div class="cell">
                    <div class="d-flex flex-column justify-center w-100">
                        <span class="font-weight-medium text-grey-darken-4 text-truncate" style="font-size: 15px;">{{ item.supplier_name || item.entity_name }}</span>
                        <span class="text-grey-darken-3 text-truncate" style="font-size: 13px; margin-top: 2px;">{{ item.description }}</span>
                    </div>
                </div>

                <div class="cell center">
                    <span class="font-mono font-weight-medium text-grey-darken-4" style="font-size: 15px;">{{ formatDateSafe(item.order_date) }}</span>
                </div>

                <div class="cell center">
                    <v-chip size="default" :color="getProductionStatusColor(item.production_status)" variant="flat" class="font-weight-bold text-uppercase px-4 cursor-pointer hover-elevate transition-all rounded-0" style="font-size: 12px; height: 28px;" @click.stop="openStatusModal(item)">
                        {{ formatProductionStatus(item.production_status) }}
                    </v-chip>
                </div>

                <div class="cell center">
                    <v-chip size="default" variant="tonal" :color="item.payment_details?.installments > 1 ? 'info' : 'success'" class="font-weight-bold px-3 rounded-0" style="font-size: 12px; height: 28px;">
                        {{ item.payment_details?.installments > 1 ? `Parc. em ${item.payment_details.installments}x` : 'À Vista' }}
                    </v-chip>
                </div>

                <div class="cell center">
                    <span class="font-mono font-weight-black text-success-darken-3" style="font-size: 15px;">{{ formatCurrency(item.total_value) }}</span>
                </div>

                <div class="cell center">
                    <span class="solid-chip" :class="item.finance_payable_id ? 'bg-success' : 'bg-orange-darken-1'">
                        {{ item.finance_payable_id ? 'LANÇADO' : 'PENDENTE' }}
                    </span>
                </div>

                <div class="cell center">
                    <div class="actions-inline">
                        <v-btn icon size="small" class="action-btn action-pay" :class="item.finance_payable_id ? 'opacity-50' : ''" @click.stop="openFinancialPreview(item)" :title="item.finance_payable_id ? 'Já lançado' : 'Lançar no Contas a Pagar'" variant="flat" :disabled="!!item.finance_payable_id"><v-icon size="16">mdi-bank-transfer</v-icon></v-btn>
                        <v-btn icon size="small" class="action-btn action-edit" @click.stop="openEditModal(item)" title="Editar" variant="flat"><v-icon size="16">mdi-pencil</v-icon></v-btn>
                        <v-btn icon size="small" class="action-btn bg-blue-grey-lighten-4 text-blue-grey-darken-4" @click.stop="clonePurchase(item)" title="Clonar Compra" variant="flat"><v-icon size="16">mdi-content-copy</v-icon></v-btn>

                        <v-menu location="bottom end" transition="scale-transition">
                            <template v-slot:activator="{ props }">
                                <v-btn v-bind="props" icon size="small" class="action-btn bg-success text-white" variant="flat" title="Mais Opções"><v-icon size="16">mdi-chevron-down</v-icon></v-btn>
                            </template>
                            <v-list density="comfortable" nav class="bg-white border-thin shadow-sm rounded-0" width="220">
                                <v-list-item @click="openDetailsModal(item)" prepend-icon="mdi-magnify" base-color="info" title="Auditoria e Detalhes" class="font-weight-bold text-body-2"></v-list-item>
                                <v-list-item @click="printPurchase(item)" prepend-icon="mdi-printer" title="Imprimir Pedido (PDF)" class="font-weight-bold text-body-2"></v-list-item>

                                <v-menu location="start" open-on-hover submenu>
                                    <template v-slot:activator="{ props: menuProps }">
                                        <v-list-item v-bind="menuProps" prepend-icon="mdi-share-variant" title="Compartilhar" append-icon="mdi-menu-right" class="font-weight-bold text-body-2"></v-list-item>
                                    </template>
                                    <v-list density="comfortable" nav class="bg-white border-thin shadow-sm rounded-0">
                                        <v-list-item @click="sharePurchase(item, 'whatsapp')" prepend-icon="mdi-whatsapp" base-color="success" title="Via WhatsApp" class="font-weight-bold text-body-2"></v-list-item>
                                        <v-list-item @click="sharePurchase(item, 'email')" prepend-icon="mdi-email" base-color="error" title="Via E-mail" class="font-weight-bold text-body-2"></v-list-item>
                                    </v-list>
                                </v-menu>

                                <v-divider class="my-2"></v-divider>
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

    <v-dialog v-model="modal.show" max-width="1400" persistent scrollable transition="dialog-bottom-transition">
        <v-card class="d-flex flex-column rounded-0 bg-grey-lighten-4 h-100" style="max-height: 95vh;">
            <div class="px-6 py-5 bg-success text-white d-flex align-center justify-space-between flex-shrink-0 elevation-2 z-10 relative">
                <div class="d-flex align-center gap-4">
                    <div class="bg-white-20 rounded-0 d-flex align-center justify-center" style="width: 48px; height: 48px;"><v-icon size="28" color="white">{{ modal.form.id ? 'mdi-cart-check' : 'mdi-cart-arrow-down' }}</v-icon></div>
                    <div>
                        <div class="text-h5 font-weight-black leading-tight">{{ modal.form.id ? 'Editando Compra' : 'Lançamento de Nova Compra' }}</div>
                        <div class="text-caption font-weight-medium opacity-90">Preencha detalhadamente as informações do fornecedor, itens e condições de pagamento.</div>
                    </div>
                </div>
                <v-btn icon="mdi-close" variant="text" color="white" size="large" @click="modal.show = false"></v-btn>
            </div>

            <v-card-text class="pa-6 custom-scroll d-flex flex-column gap-6">
                <v-form ref="purchaseForm">
                    <v-card variant="outlined" class="bg-white rounded-0 border-thin overflow-hidden shadow-sm">
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
                                <v-col cols="12" md="4" v-if="companyStore.isGlobalView"><v-autocomplete v-model="modal.form.company_id" :items="auxData.companies" item-title="trade_name" item-value="id" label="Empresa Destino da Compra*" variant="outlined" density="comfortable" color="success" class="ui-field"></v-autocomplete></v-col>
                                <v-col cols="12" md="4"><v-autocomplete v-model="modal.form.chart_of_accounts_id" :items="auxData.chartOfAccounts" item-title="name" item-value="id" label="Plano de Contas (Despesa)" variant="outlined" density="comfortable" color="success" class="ui-field" clearable></v-autocomplete></v-col>
                                <v-col cols="12" :md="companyStore.isGlobalView ? 2 : 4"><v-text-field v-model="modal.form.order_date" label="Data de Emissão*" type="date" variant="outlined" density="comfortable" color="success" class="ui-field font-weight-bold"></v-text-field></v-col>
                                <v-col cols="12" :md="companyStore.isGlobalView ? 2 : 4"><v-text-field v-model="modal.form.delivery_date" label="Previsão de Entrega*" type="date" variant="outlined" density="comfortable" color="success" class="ui-field font-weight-bold"></v-text-field></v-col>
                                <v-col cols="12">
                                    <div class="d-flex align-center justify-space-between bg-green-lighten-5 px-5 py-3 rounded-0 border border-green-lighten-4">
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

                    <v-card variant="outlined" class="bg-white rounded-0 border-thin overflow-hidden shadow-sm mt-6">
                        <div class="bg-grey-lighten-4 border-b px-5 py-3 d-flex align-center justify-space-between">
                            <div class="d-flex align-center gap-2"><v-icon size="20" color="success">mdi-format-list-bulleted</v-icon><span class="text-subtitle-2 font-weight-black text-uppercase text-grey-darken-3 tracking-wide">Inclusão de Itens</span></div>
                            <v-chip color="success" size="default" variant="flat" class="font-weight-black px-4 rounded-0">{{ modal.items.length }} Itens Adicionados</v-chip>
                        </div>
                        <div class="pa-5 bg-white border-b border-opacity-50">
                            <v-row dense align="center" class="row-gap">
                                <v-col cols="12" md="4">
                                    <v-autocomplete v-model="currentItem.product_id" :items="auxData.products" item-title="name" item-value="id" label="Buscar Produto no Estoque" variant="outlined" density="comfortable" hide-details color="success" class="ui-field font-weight-bold" @update:model-value="onProductSelect">
                                        <template v-slot:prepend-item><v-list-item title="Cadastrar Novo Produto Rápido" prepend-icon="mdi-plus-circle" class="text-primary font-weight-black bg-blue-lighten-5" @click="openQuickProductModal"></v-list-item><v-divider class="my-2"></v-divider></template>
                                    </v-autocomplete>
                                </v-col>
                                <v-col cols="12" md="3" v-if="!currentItem.product_id"><v-text-field v-model="currentItem.description" label="Descrição Avulsa (S/ Estoque)" variant="outlined" density="comfortable" hide-details class="ui-field"></v-text-field></v-col>
                                <v-col cols="4" :md="currentItem.product_id ? 2 : 1"><v-text-field v-model.number="currentItem.quantity" label="Quant." type="number" min="1" variant="outlined" density="comfortable" hide-details class="ui-field font-weight-bold text-center" @input="calcCurrentTotal"></v-text-field></v-col>
                                <v-col cols="4" md="2"><v-text-field v-model.number="currentItem.unit_price" label="Valor Unitário (R$)" type="number" step="0.01" variant="outlined" density="comfortable" hide-details class="ui-field font-weight-bold text-success-darken-2" prefix="R$" @input="calcCurrentTotal"></v-text-field></v-col>
                                <v-col cols="4" md="2" class="d-flex justify-end"><v-btn color="blue-darken-3" variant="flat" height="48" class="btn-rect w-100 font-weight-bold text-body-2" @click="addItemToList" :disabled="!isCurrentItemValid"><v-icon start size="20">mdi-plus-thick</v-icon> Adicionar</v-btn></v-col>
                            </v-row>
                        </div>

                        <div class="overflow-auto custom-scroll" style="min-height: 250px; max-height: 400px;">
                            <div class="grid-header sticky-head grid-surface-light border-b" style="grid-template-columns: 60px 2fr 120px 160px 160px 140px;">
                                <div class="cell center header-text">Seq.</div><div class="cell header-text">Descrição do Material / Produto</div><div class="cell center header-text">Quantidade</div><div class="cell center header-text">Valor Unitário</div><div class="cell center header-text text-success-darken-3">Subtotal</div><div class="cell center header-text">Ações</div>
                            </div>
                            <div v-if="modal.items.length === 0" class="d-flex flex-column justify-center align-center py-12 opacity-40 bg-grey-lighten-5 h-100"><v-icon size="48" class="mb-3">mdi-basket-plus-outline</v-icon><span class="text-body-2 font-weight-bold">A lista de itens está vazia.</span></div>
                            <div v-else v-for="(item, index) in modal.items" :key="item.ui_id" class="grid-row" :class="zebraClass(index)" style="grid-template-columns: 60px 2fr 120px 160px 160px 140px;">
                                <div class="cell center font-weight-black text-grey-darken-1" style="font-size: 15px;">{{ index + 1 }}</div>
                                <div class="cell"><div class="d-flex flex-column justify-center w-100 py-1"><span class="font-weight-medium text-grey-darken-4 text-truncate mb-1" style="font-size: 15px;">{{ item.product_name || item.description }}</span><v-chip v-if="item.product_id" size="small" color="success" variant="tonal" class="font-weight-bold px-3 align-self-start rounded-0"><v-icon start size="14">mdi-link</v-icon> VINCULADO</v-chip></div></div>
                                <div class="cell center"><span class="font-mono font-weight-medium text-grey-darken-4" style="font-size: 15px;">{{ item.quantity }}</span></div>
                                <div class="cell center"><span class="font-mono font-weight-medium text-grey-darken-4" style="font-size: 15px;">{{ formatCurrencyValue(item.unit_price) }}</span></div>
                                <div class="cell center bg-green-lighten-5"><span class="font-mono font-weight-black text-success-darken-3" style="font-size: 15px;">{{ formatCurrency(item.total_price) }}</span></div>
                                <div class="cell center"><div class="actions-inline"><v-btn icon size="small" class="action-btn bg-blue-grey-lighten-4 text-blue-grey-darken-3" @click="cloneItem(item)" title="Duplicar Item" variant="flat"><v-icon size="16">mdi-content-copy</v-icon></v-btn><v-btn icon size="small" class="action-btn action-edit" @click="editItem(index)" title="Editar" variant="flat"><v-icon size="16">mdi-pencil</v-icon></v-btn><v-btn icon size="small" class="action-btn action-del" @click="removeItem(index)" title="Excluir" variant="flat"><v-icon size="16">mdi-close-thick</v-icon></v-btn></div></div>
                            </div>
                        </div>
                        <div class="pa-5 bg-grey-lighten-3 border-t d-flex justify-end align-center shadow-inner">
                            <div class="d-flex align-center gap-4 bg-white px-6 py-3 rounded-0 elevation-1 border-thin border-success"><span class="text-body-2 font-weight-black text-uppercase text-grey-darken-2">Valor Total da Compra:</span><span class="text-h5 font-weight-black text-success-darken-3 tabular-nums">{{ formatCurrency(purchaseTotalValue) }}</span></div>
                        </div>
                    </v-card>

                    <v-card variant="outlined" class="bg-white rounded-0 border-thin overflow-hidden shadow-sm mt-6">
                        <div class="bg-grey-lighten-4 border-b px-5 py-3 d-flex align-center gap-2"><v-icon size="20" color="success">mdi-cash-multiple</v-icon><span class="text-subtitle-2 font-weight-black text-uppercase text-grey-darken-3 tracking-wide">Condições de Pagamento</span></div>
                        <div class="pa-5">
                            <v-row dense class="row-gap">
                                <v-col cols="12" md="4"><v-select v-model="modal.payment.method" :items="['Boleto Bancário', 'PIX', 'Cartão de Crédito', 'Transferência Bancária', 'Dinheiro']" label="Forma de Pagamento" variant="outlined" density="comfortable" color="success" class="ui-field font-weight-bold"></v-select></v-col>
                                <v-col cols="12" md="4"><v-select v-model="modal.payment.condition" :items="['À Vista', 'Parcelado']" label="Condição" variant="outlined" density="comfortable" color="success" class="ui-field font-weight-bold"></v-select></v-col>
                                <v-col cols="12" md="4" v-if="modal.payment.condition === 'Parcelado'"><v-select v-model.number="modal.payment.installments" :items="[2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]" label="Quantidade de Parcelas" variant="outlined" density="comfortable" color="success" class="ui-field font-weight-bold" @update:model-value="generateInstallments"></v-select></v-col>

                                <v-col cols="12" v-if="modal.payment.details.length > 0">
                                    <div class="border-thin rounded-0 overflow-hidden mt-2">
                                        <div class="bg-grey-lighten-4 px-4 py-2 text-caption font-weight-black text-uppercase border-b d-flex justify-space-between"><span>Detalhamento das Parcelas</span><v-btn size="small" variant="text" color="primary" @click="generateInstallments">Recalcular Valores</v-btn></div>
                                        <div class="pa-4 bg-white">
                                            <v-row dense>
                                                <v-col cols="12" md="6" v-for="(inst, idx) in modal.payment.details" :key="idx">
                                                    <div class="d-flex align-center gap-3 mb-2 bg-grey-lighten-5 pa-2 rounded-0 border">
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

                    <v-card variant="outlined" class="bg-white rounded-0 border-thin overflow-hidden shadow-sm mt-6 mb-4">
                        <div class="bg-grey-lighten-4 border-b px-5 py-3 d-flex align-center gap-2"><v-icon size="20" color="success">mdi-paperclip</v-icon><span class="text-subtitle-2 font-weight-black text-uppercase text-grey-darken-3 tracking-wide">Anexos e Observações Fiscais</span></div>
                        <div class="pa-5">
                            <v-row dense class="row-gap">
                                <v-col cols="12" md="6"><v-file-input v-model="modal.files" label="Anexar Arquivos (NFe, XML, Boleto, PDF, IMG)" variant="outlined" density="comfortable" prepend-inner-icon="mdi-cloud-upload" color="success" multiple chips show-size class="ui-field bg-grey-lighten-5"></v-file-input></v-col>
                                <v-col cols="12" md="6"><v-textarea v-model="modal.form.notes" label="Observações Adicionais (Opcional)" variant="outlined" rows="3" density="comfortable" class="ui-field"></v-textarea></v-col>
                            </v-row>
                        </div>
                    </v-card>
                </v-form>
            </v-card-text>

            <div class="px-8 py-5 border-t bg-white d-flex justify-space-between align-center flex-shrink-0 elevation-10 z-10 relative">
                <div class="d-flex align-center gap-2 text-body-2 text-grey font-weight-bold bg-grey-lighten-4 px-4 py-2 rounded-0 border"><v-icon size="20">mdi-account-circle</v-icon> Operador: <span class="text-success font-weight-black">{{ userStore.profile?.full_name || userStore.user?.email }}</span></div>
                <div class="d-flex gap-3">
                    <v-btn variant="outlined" color="grey-darken-2" class="btn-rect px-8 font-weight-bold text-body-2" height="50" @click="modal.show = false" :disabled="modal.saving">Cancelar</v-btn>
                    <v-btn color="success" variant="flat" class="btn-rect px-10 font-weight-black text-body-1 shadow-button" height="50" @click="saveFullPurchase" :loading="modal.saving"><v-icon start size="24" class="mr-2">mdi-content-save-check</v-icon> SALVAR COMPRA</v-btn>
                </div>
            </div>
        </v-card>
    </v-dialog>

    <v-dialog v-model="financialPreviewModal.show" max-width="900" persistent transition="dialog-bottom-transition">
        <v-card class="rounded-0 overflow-hidden">
            <div class="px-6 py-5 bg-teal-darken-4 text-white d-flex align-center justify-space-between">
                <div class="d-flex align-center gap-4">
                    <v-icon size="36" color="teal-lighten-4">mdi-bank-transfer-in</v-icon>
                    <div>
                        <div class="text-h5 font-weight-black leading-tight">Autorização de Lançamento Financeiro</div>
                        <div class="text-caption font-weight-medium opacity-80 mt-1">Revise as condições antes de gerar obrigações no Contas a Pagar.</div>
                    </div>
                </div>
                <v-btn icon="mdi-close" variant="text" size="large" @click="financialPreviewModal.show = false"></v-btn>
            </div>

            <div class="pa-6 bg-grey-lighten-5">
                <v-alert type="warning" variant="tonal" border="start" density="compact" class="mb-6 font-weight-bold text-body-2 rounded-0">
                    ATENÇÃO: A confirmação criará <strong>{{ financialPreviewModal.installments.length }} lançamento(s)</strong> no módulo financeiro definitivo. Certifique-se de que os valores e vencimentos estão corretos.
                </v-alert>

                <div class="d-flex flex-wrap justify-space-between align-center mb-6 bg-white pa-5 rounded-0 border-thin shadow-sm gap-4">
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

                <div class="bg-white border-thin rounded-0 overflow-hidden shadow-sm">
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
                    <v-btn variant="outlined" color="grey-darken-3" class="btn-rect font-weight-bold px-6 text-body-2" height="44" @click="financialPreviewModal.show = false">Cancelar</v-btn>
                    <v-btn color="teal-darken-3" variant="flat" class="btn-rect font-weight-black px-8 text-body-2" height="44" @click="confirmFinancialLaunch" :loading="financialPreviewModal.loading">
                        <v-icon start size="20">mdi-check-all</v-icon> CONFIRMAR LANÇAMENTO
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
                        <div class="text-h6 font-weight-black">Detalhes e Auditoria - Compra #{{ detailsModal.item?.id?.substring(0,6).toUpperCase() }}</div>
                        <div class="text-caption opacity-80">Rastreabilidade completa, informações logísticas e financeiras.</div>
                    </div>
                </div>
                <v-btn icon="mdi-close" variant="text" @click="detailsModal.show = false"></v-btn>
            </div>

            <v-card-text class="pa-6 custom-scroll d-flex flex-column gap-6">
                <v-card variant="flat" class="bg-white border-thin pa-5 shadow-sm rounded-0">
                    <v-row>
                        <v-col cols="6" md="3"><div class="text-body-2 text-grey text-uppercase font-weight-bold">Fornecedor</div><div class="font-weight-black text-body-2">{{ detailsModal.item?.supplier_name || detailsModal.item?.entity_name }}</div></v-col>
                        <v-col cols="6" md="3"><div class="text-body-2 text-grey text-uppercase font-weight-bold">Data Pedido</div><div class="font-weight-black text-body-2">{{ formatDateSafe(detailsModal.item?.order_date) }}</div></v-col>
                        <v-col cols="6" md="3"><div class="text-body-2 text-grey text-uppercase font-weight-bold">Prev. Entrega</div><div class="font-weight-black text-body-2">{{ formatDateSafe(detailsModal.item?.delivery_date) }}</div></v-col>
                        <v-col cols="6" md="3"><div class="text-body-2 text-grey text-uppercase font-weight-bold">Valor Total</div><div class="font-weight-black text-h6 text-success-darken-2 tabular-nums">{{ formatCurrency(detailsModal.item?.total_value) }}</div></v-col>
                        <v-col cols="12" md="6"><div class="text-body-2 text-grey text-uppercase font-weight-bold">Descrição da Compra</div><div class="text-body-2">{{ detailsModal.item?.description || '-' }}</div></v-col>
                        <v-col cols="12" md="6"><div class="text-body-2 text-grey text-uppercase font-weight-bold">Status Logístico Atual</div>
                            <v-chip size="default" :color="getProductionStatusColor(detailsModal.item?.production_status)" class="font-weight-black text-uppercase mt-1 rounded-0" style="font-size: 12px;">{{ formatProductionStatus(detailsModal.item?.production_status) }}</v-chip>
                        </v-col>
                    </v-row>
                </v-card>

                <v-card variant="flat" class="bg-white border-thin shadow-sm rounded-0 overflow-hidden">
                    <div class="bg-grey-lighten-4 border-b px-4 py-3 font-weight-black text-uppercase text-body-2 text-grey-darken-3 d-flex align-center gap-2"><v-icon size="20">mdi-credit-card-outline</v-icon> Informações de Pagamento</div>
                    <div class="pa-5 d-flex gap-8 flex-wrap">
                        <div><div class="text-body-2 text-grey font-weight-bold text-uppercase">Método</div><div class="font-weight-black text-body-2">{{ detailsModal.item?.payment_details?.method || '-' }}</div></div>
                        <div><div class="text-body-2 text-grey font-weight-bold text-uppercase">Condição</div><div class="font-weight-black text-body-2">{{ detailsModal.item?.payment_details?.condition || '-' }} ({{ detailsModal.item?.payment_details?.installments || 1 }}x)</div></div>
                        <div><div class="text-body-2 text-grey font-weight-bold text-uppercase">Status Financeiro</div><v-chip size="default" :color="detailsModal.item?.finance_payable_id ? 'success' : 'warning'" variant="tonal" class="font-weight-bold mt-1 text-body-2 rounded-0" style="font-size: 12px;">{{ detailsModal.item?.finance_payable_id ? 'LANÇADO NO CONTAS A PAGAR' : 'PENDENTE DE LANÇAMENTO' }}</v-chip></div>
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

    <v-dialog v-model="statusModal.show" width="450">
        <v-card class="pa-6 rounded-0 border-t-lg border-t-primary">
            <div class="d-flex align-center gap-3 mb-4">
                <v-icon size="36" color="primary">mdi-truck-outline</v-icon>
                <div class="text-h6 font-weight-black leading-none">Atualizar Status de Produção</div>
            </div>
            <p class="text-body-2 text-grey mb-4">Acompanhamento logístico do pedido de compra.</p>

            <v-select v-model="statusModal.status" :items="statusOptions" item-title="label" item-value="value" variant="outlined" density="comfortable" color="primary" hide-details class="font-weight-bold ui-field"></v-select>

            <div class="d-flex justify-end gap-2 mt-6">
                <v-btn variant="text" color="grey-darken-2" class="font-weight-bold btn-rect text-body-2" @click="statusModal.show = false">Cancelar</v-btn>
                <v-btn color="primary" variant="flat" class="font-weight-black px-6 btn-rect text-body-2" height="44" @click="saveProductionStatus" :loading="statusModal.loading">Atualizar</v-btn>
            </div>
        </v-card>
    </v-dialog>

    <v-dialog v-model="quickModal.show" width="450">
        <v-card class="pa-6 rounded-0 border-t-lg border-t-success">
            <div class="d-flex align-center gap-3 mb-6">
                <v-icon size="36" :color="quickModal.type === 'product' ? 'primary' : 'success'">{{ quickModal.type === 'product' ? 'mdi-package-variant-closed' : 'mdi-truck-delivery' }}</v-icon>
                <div class="text-h6 font-weight-black leading-none">Cadastro Rápido de {{ quickModal.type === 'product' ? 'Produto' : 'Fornecedor' }}</div>
            </div>
            <v-text-field v-model="quickModal.name" :label="quickModal.type === 'product' ? 'Nome do Material' : 'Razão Social / Nome'" variant="outlined" density="comfortable" color="success" class="font-weight-bold ui-field"></v-text-field>
            <div class="d-flex justify-end gap-2 mt-4">
                <v-btn variant="text" color="grey-darken-2" class="font-weight-bold btn-rect text-body-2" @click="quickModal.show = false">Cancelar</v-btn>
                <v-btn color="success" variant="flat" class="font-weight-black px-6 btn-rect text-body-2" height="44" @click="saveQuickRegistration">Cadastrar e Usar</v-btn>
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

const getBase64Logo = async (url: string): Promise<string> => {
  const response = await fetch(url);
  const blob = await response.blob();
  return new Promise((resolve) => {
    const reader = new FileReader();
    reader.onloadend = () => resolve(reader.result as string);
    reader.readAsDataURL(blob);
  });
};

const PURCHASE_TYPE = 'product';

const appStore = useAppStore();
const themeStore = useThemeStore();
const companyStore = useCompanyStore();
const userStore = useUserStore();

const loadingPurchases = ref(false);
const purchases = ref<any[]>([]);

// FILTROS COM BUSCA GLOBAL
const filters = reactive({ startDate: '', endDate: '', supplier: null, status: 'Todos', search: '' });

const filteredPurchases = computed(() => {
    let result = purchases.value;

    // Busca em todas as colunas
    if (filters.search) {
        const s = filters.search.toLowerCase();
        result = result.filter(p =>
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

const auxData = reactive({ suppliers: [] as any[], products: [] as any[], companies: [] as any[], chartOfAccounts: [] as any[] });

// MODAIS
const modal = reactive({ show: false, saving: false, files: [] as File[], form: { id: '', description: '', supplier_id: null, chart_of_accounts_id: null, order_date: '', delivery_date: '', notes: '', move_stock: true, company_id: null }, items: [] as any[], payment: { method: 'Boleto Bancário', condition: 'À Vista', installments: 1, details: [] as any[] } });
const financialPreviewModal = reactive({ show: false, loading: false, item: null as any, installments: [] as any[] });
const detailsModal = reactive({ show: false, item: null as any });
const quickModal = reactive({ show: false, type: '', name: '' });
const statusModal = reactive({ show: false, loading: false, item: null as any, status: '' });

const initialItemState = { ui_id: '', product_id: null, product_name: '', description: '', quantity: 1, unit_price: 0, total_price: 0 };
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
        if (compData) auxData.companies = compData;

        const { data: chartData } = await supabase.from('finance_chart_of_accounts').select('id, name').eq('type', 'Despesa').order('name');
        if (chartData) auxData.chartOfAccounts = chartData;
    } catch(e) { console.error('Erro auxiliares', e); }
};

const fetchPurchases = async () => {
    loadingPurchases.value = true;
    try {
        let query = supabase.from('purchases').select('*, purchase_items(*)').eq('purchase_type', PURCHASE_TYPE).order('created_at', { ascending: false });
        if (!companyStore.isGlobalView && companyStore.context) query = query.eq('company_id', companyStore.context);

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
    modal.form = { id: '', description: '', supplier_id: null, chart_of_accounts_id: null, order_date: new Date().toISOString().split('T')[0], delivery_date: new Date().toISOString().split('T')[0], notes: '', move_stock: true, company_id: null };
    modal.items = []; modal.files = []; modal.payment = { method: 'Boleto Bancário', condition: 'À Vista', installments: 1, details: [] };
    currentItem.value = { ...initialItemState, ui_id: Math.random().toString(36).substr(2, 9) };
    modal.show = true;
};

const openEditModal = (item: any) => {
    modal.form = { ...item };
    modal.payment = item.payment_details || { method: 'Boleto Bancário', condition: 'À Vista', installments: 1, details: [] };
    modal.items = (item.purchase_items || []).map((i:any) => ({ ...i, ui_id: Math.random().toString(36).substr(2, 9), product_name: i.description }));
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
    const targetCompanyId = companyStore.isGlobalView ? modal.form.company_id : companyStore.context;
    if (companyStore.isGlobalView && !targetCompanyId) { appStore.showSnackbar('Selecione a empresa.', 'warning'); return; }
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
        } as any;

        if (isNew) {
            purchaseHeader.created_by = userStore.user?.id;
            purchaseHeader.created_by_name = userStore.profile?.full_name || userStore.user?.email;
            purchaseHeader.production_status = 'indefinido';
            purchaseHeader.audit_log = [createLogEntry('Criação da Compra', `Compra registrada com ${modal.items.length} itens no valor de ${formatCurrency(purchaseTotalValue.value)}`)];

            const { data: hd, error: he } = await supabase.from('purchases').insert(purchaseHeader).select('id').single();
            if (he) throw he;

            const itemsPayload = modal.items.map(i => ({ purchase_id: hd.id, product_id: i.product_id, description: i.product_id ? i.product_name : i.description, quantity: i.quantity, unit_price: i.unit_price, total_price: i.total_price }));
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
            const itemsPayload = modal.items.map(i => ({ purchase_id: modal.form.id, product_id: i.product_id, description: i.product_id ? i.product_name : i.description, quantity: i.quantity, unit_price: i.unit_price, total_price: i.total_price }));
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
            const desc = isParceled ? `[COMPRA PARCELADA] #${item.id.substring(0,6).toUpperCase()} - ${item.description} (Parc. ${idx + 1}/${installments.length})` : `[COMPRA] #${item.id.substring(0,6).toUpperCase()} - ${item.description}`;
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

// --- GERAÇÃO DE PDF DO PEDIDO COM CABEÇALHO CORRETO E ESPAÇAMENTOS REAIS ---
const printPurchase = async (item: any) => {
  try {
    const doc = new jsPDF({ unit: "mm", format: "a4" });

    // Busca os dados da empresa referentes especificamente a ESTE pedido
    let pdfCompany = companyStore.currentCompany || {};
    if (item.company_id) {
      try {
        const { data: compData } = await supabase.from('companies').select('*').eq('id', item.company_id).single();
        if (compData) pdfCompany = compData;
      } catch (err) {
        console.warn("Não foi possível buscar a empresa do pedido pro PDF", err);
      }
    }
    const companyName = (pdfCompany.trade_name || pdfCompany.corporate_name || companyStore.currentCompanyName || 'Empresa').toUpperCase();

    // DEFINIÇÃO OFICIAL DOS CABEÇALHOS SOLICITADOS
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

    const pageW = doc.internal.pageSize.getWidth();
    const pageH = doc.internal.pageSize.getHeight();
    const marginX = 10;
    const contentW = pageW - marginX * 2;

    const COLORS = {
      border: 180,
      textDark: 40,
      textMid: 90,
      bar: 235,
      headerBox: 245,
      white: 255,
    };

    const fmtMoney = (v: any) => new Intl.NumberFormat('pt-BR', { minimumFractionDigits: 2, maximumFractionDigits: 2 }).format(Number(v) || 0);
    const formatDate = (d: any) => {
      if (!d) return "-";
      const date = d.split('T')[0].split('-');
      return `${date[2]}/${date[1]}/${date[0]}`;
    };

    const drawBox = (x: number, y: number, w: number, h: number, fill?: number) => {
      if (typeof fill === "number") {
        doc.setFillColor(fill);
        doc.setDrawColor(COLORS.border);
        doc.rect(x, y, w, h, "FD");
      } else {
        doc.setDrawColor(COLORS.border);
        doc.rect(x, y, w, h, "S");
      }
    };

    const drawBar = (y: number, h: number, title: string) => {
      doc.setFillColor(COLORS.bar);
      doc.setDrawColor(COLORS.border);
      doc.rect(marginX, y, contentW, h, "FD");
      doc.setFont("helvetica", "bold");
      doc.setFontSize(10.5);
      doc.setTextColor(COLORS.textDark);
      doc.text(title.toUpperCase(), marginX + 3, y + h - 3.2);
    };

    const putLabelValue = (x: number, y: number, label: string, value: string, maxW = 90) => {
      doc.setFont("helvetica", "bold");
      doc.setFontSize(10);
      doc.setTextColor(COLORS.textMid);
      doc.text(label, x, y);
      doc.setFont("helvetica", "normal");
      doc.setFontSize(10.5);
      doc.setTextColor(20);
      const val = value || "-";
      const lines = doc.splitTextToSize(val, maxW);
      doc.text(lines, x, y + 5);
    };

    const logoUrl = userStore.currentModule === 'cajuia' ? logoCajuia : (themeStore.currentMode === 'light' ? logoLight : logoDark);
    const logoBase64 = await getBase64Logo(logoUrl);

    let y = 10;

    // --- BLOCO 1: CABEÇALHO (Empresa com texto exato) ---
    const headerH = 35;
    drawBox(marginX, y, contentW, headerH, COLORS.headerBox);

    if (logoBase64) doc.addImage(logoBase64, 'PNG', marginX + 4, y + 8, 45, 18);

    const infoX = marginX + 55;
    doc.setFont("helvetica", "bold");
    doc.setFontSize(14);
    doc.setTextColor(20);
    doc.text(companyText1, infoX, y + 10);

    doc.setFontSize(10);
    doc.setFont("helvetica", "normal");
    doc.setTextColor(COLORS.textMid);
    doc.text(companyText2, infoX, y + 16);
    doc.text(companyText3, infoX, y + 22);
    doc.text(companyText4, infoX, y + 28);

    y += headerH + 20; // ESPAÇAMENTO GENEROSO APLICADO

    // --- BLOCO 2: TÍTULO E IDENTIFICAÇÃO DO PEDIDO ---
    const orderNo = String(item.id || '').toUpperCase().slice(0, 8);
    drawBar(y, 10, `PEDIDO DE COMPRA Nº ${orderNo}`);
    doc.text(`EMISSÃO: ${formatDate(item.order_date)}`, marginX + contentW - 3, y + 6.8, { align: "right" });

    y += 18; // ESPAÇAMENTO GENEROSO APLICADO

    // --- BLOCO 3: DADOS DO FORNECEDOR ---
    const supplierH = 30;
    drawBox(marginX, y, contentW, supplierH);
    doc.setDrawColor(COLORS.border);
    doc.line(marginX + contentW * 0.55, y, marginX + contentW * 0.55, y + supplierH);

    putLabelValue(marginX + 4, y + 7, "FORNECEDOR:", item.supplier_name || item.entity_name, 100);
    putLabelValue(marginX + 4, y + 19, "DESCRIÇÃO/REF:", item.description, 100);

    const col2X = marginX + contentW * 0.55 + 4;
    putLabelValue(col2X, y + 7, "PREVISÃO ENTREGA:", formatDate(item.delivery_date));
    putLabelValue(col2X, y + 19, "STATUS LOGÍSTICO:", formatProductionStatus(item.production_status).toUpperCase());

    y += supplierH + 20; // ESPAÇAMENTO GENEROSO APLICADO

    // --- BLOCO 4: ITENS DO PEDIDO ---
    drawBar(y, 8, "Produtos / Materiais");
    y += 12;

    const tableBody = (item.purchase_items || []).map((it: any, idx: number) => [
      String(idx + 1),
      it.description || 'Produto sem descrição',
      it.quantity.toString(),
      `R$ ${fmtMoney(it.unit_price)}`,
      `R$ ${fmtMoney(it.total_price)}`
    ]);

    autoTable(doc, {
      startY: y,
      theme: "grid",
      head: [["ITEM", "DESCRIÇÃO DO MATERIAL", "QTD", "VALOR UNIT.", "SUBTOTAL"]],
      body: tableBody,
      styles: { fontSize: 10, cellPadding: 3 },
      headStyles: { fillColor: [COLORS.bar, COLORS.bar, COLORS.bar], textColor: COLORS.textDark, fontStyle: 'bold' },
      columnStyles: {
        0: { halign: 'center', cellWidth: 14 },
        2: { halign: 'center', cellWidth: 20 },
        3: { halign: 'right', cellWidth: 35 },
        4: { halign: 'right', cellWidth: 35 },
      }
    });

    y = (doc as any).lastAutoTable.finalY;

    // Linha de Totalização
    drawBox(marginX, y, contentW, 10, COLORS.bar);
    doc.setFont("helvetica", "bold");
    doc.setFontSize(11);
    doc.text("VALOR TOTAL DA COMPRA", marginX + 4, y + 7);
    doc.text(`R$ ${fmtMoney(item.total_value)}`, marginX + contentW - 4, y + 7, { align: "right" });

    y += 20; // ESPAÇAMENTO GENEROSO APLICADO

    // --- BLOCO 5: CONDIÇÕES DE PAGAMENTO ---
    drawBar(y, 8, "Dados Financeiros / Pagamento");
    y += 12;

    const payDetails = item.payment_details || {};
    const paymentBody = (payDetails.details || []).map((p: any, idx: number) => [
      `${idx + 1}ª Parcela`,
      formatDate(p.due_date),
      `R$ ${fmtMoney(p.value)}`,
      payDetails.method || '-'
    ]);

    autoTable(doc, {
      startY: y,
      theme: "grid",
      head: [["PARCELA", "VENCIMENTO", "VALOR", "FORMA"]],
      body: paymentBody.length ? paymentBody : [["1/1", formatDate(item.delivery_date), `R$ ${fmtMoney(item.total_value)}`, payDetails.method || 'À VISTA']],
      styles: { fontSize: 9.5, cellPadding: 3 },
      headStyles: { fillColor: COLORS.white, textColor: COLORS.textDark, lineWidth: 0.1 },
    });

    y = (doc as any).lastAutoTable.finalY + 20; // ESPAÇAMENTO GENEROSO APLICADO

    // --- BLOCO 6: OBSERVAÇÕES ---
    if (item.notes) {
      drawBar(y, 8, "Observações Adicionais");
      y += 12;
      drawBox(marginX, y, contentW, 20);
      doc.setFont("helvetica", "normal");
      doc.setFontSize(9.5);
      const lines = doc.splitTextToSize(item.notes, contentW - 8);
      doc.text(lines, marginX + 4, y + 6);
    }

    // --- ASSINATURA E RODAPÉ ANCORADOS NO FUNDO (Jamais grudados) ---
    const footerY = pageH - 40;
    const sigW = 70;
    const sigX = marginX + (contentW / 2) - (sigW / 2);

    doc.setDrawColor(COLORS.textDark);
    doc.line(sigX, footerY, sigX + sigW, footerY);
    doc.setFontSize(9);
    doc.text("RESPONSÁVEL PELA COMPRA", pageW / 2, footerY + 5, { align: "center" });

    doc.setFont("helvetica", "italic");
    doc.setFontSize(8);
    doc.setTextColor(COLORS.textMid);
    doc.text(`MJProcess | Documento gerado em ${new Date().toLocaleString('pt-BR')}`, pageW / 2, pageH - 10, { align: "center" });

    doc.save(`Pedido_Compra_${orderNo}.pdf`);
  } catch (e) {
    console.error("Erro completo na geração do PDF:", e);
    appStore.showSnackbar("Erro ao gerar PDF detalhado.", "error");
  }
};

// --- GERAÇÃO DE PDF DA LISTAGEM COMPLETA DA GRID ---
const exportListToPDF = () => {
    const doc = new jsPDF('landscape');

    doc.setFont("helvetica", "bold");
    doc.setFontSize(16);
    doc.text("Relatório Geral de Compras", 14, 15);

    doc.setFontSize(10);
    doc.setFont("helvetica", "normal");
    doc.text(`Gerado em: ${new Date().toLocaleString('pt-BR')}`, 14, 22);

    const tableData = filteredPurchases.value.map(i => [
        i.id.substring(0,8).toUpperCase(),
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
        "Cód": i.id.substring(0,8).toUpperCase(),
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
    const text = `Pedido de Compra #${item.id.substring(0,6).toUpperCase()} - ${item.description}\nFornecedor: ${item.supplier_name}\nValor: ${formatCurrency(item.total_value)}\nPrev. Entrega: ${formatDateSafe(item.delivery_date)}`;
    if (platform === 'whatsapp') window.open(`https://wa.me/?text=${encodeURIComponent(text)}`, '_blank');
    else window.open(`mailto:?subject=Pedido de Compra ${item.id.substring(0,6).toUpperCase()}&body=${encodeURIComponent(text)}`, '_blank');
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

/* FIM DOS ARREDONDAMENTOS E TAMANHOS DE FONTE */
.btn-rect { border-radius: 0px !important; text-transform: none !important; }
.ui-field :deep(.v-field) { border-radius: 0px !important; background-color: #ffffff; font-size: 14px; }

/* ========================================================
   GRID DE COMPRAS (PADRÃO CORPORATIVO 15px)
   ======================================================== */
.grid-scroll { scrollbar-gutter: stable; -webkit-overflow-scrolling: touch; }
.custom-scroll::-webkit-scrollbar { width: 8px; height: 8px; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.35); border-radius: 0px; }
.custom-scroll::-webkit-scrollbar-track { background: transparent; }

.grid-header, .grid-row { display: grid; align-items: stretch; width: 100%; min-width: 1100px; }

/* Ajuste das Células com Bordas Equilibradas */
.cell {
    padding: 8px 12px;
    display: flex;
    align-items: center;
    border-right: 1px solid rgba(0,0,0,0.25);
    border-bottom: 1px solid rgba(0,0,0,0.25);
    min-height: 56px;
    overflow: hidden;
}

.header-text { font-size: 15px !important; font-weight: 900; text-transform: uppercase; letter-spacing: 0.5px; line-height: 1.2; }
.center { justify-content: center; text-align: center; }

/* Temas da Grid com Linhas de 0.25 e 0.30 */
.grid-surface-light .cell { background: #f5f7fa; color: rgba(0,0,0,0.9); border-color: rgba(0,0,0,0.3) !important; }
.grid-surface-dark .cell { background: rgba(255,255,255,0.08); color: rgba(255,255,255,0.95); border-color: rgba(255,255,255,0.3) !important; }
.grid-row-light .cell { background: #fff; border-color: rgba(0,0,0,0.25) !important; }
.grid-row-dark .cell { background: rgba(255,255,255,0.04); border-color: rgba(255,255,255,0.25) !important; }
.zebra-light-a .cell { background: #fff; }
.zebra-light-b .cell { background: #fafafa; }

/* Pílulas e Chips Padronizados e Quadrados */
.pill-ref { font-size: 12px !important; font-weight: 900; font-family: monospace; padding: 4px 6px; border-radius: 0px; white-space: nowrap; }
.solid-chip { display: inline-flex; align-items: center; justify-content: center; height: 28px; padding: 0 12px; border-radius: 0px; font-size: 12px !important; font-weight: 900; color: #fff; text-transform: uppercase; white-space: nowrap; }

/* Moldura Externa da Grid */
.flex-grow-1.overflow-hidden > .v-card.flex-grow-1 {
    border: 1px solid rgba(0,0,0,0.35) !important;
}
.bg-glass-dark .flex-grow-1.overflow-hidden > .v-card.flex-grow-1 {
    border: 1px solid rgba(255,255,255,0.35) !important;
}

.actions-inline { display: flex; gap: 8px; justify-content: center; flex-wrap: wrap; }
.action-btn { width: 34px !important; height: 34px !important; border-radius: 0px !important; color: #fff !important; }
.action-pay { background: #7b1fa2 !important; }
.action-edit { background: #1976d2 !important; }
.action-del { background: #c62828 !important; }

.row-gap { row-gap: 16px; margin-top: 8px; }
.shadow-inner { box-shadow: inset 0 2px 4px rgba(0,0,0,0.05); }
.shadow-button { box-shadow: 0 4px 15px rgba(46, 125, 50, 0.4); }
.bg-white-20 { background-color: rgba(255,255,255,0.2); }
.bg-success-subtle { background-color: #e8f5e9 !important; }
.tracking-wide { letter-spacing: 0.5px; }
</style>
