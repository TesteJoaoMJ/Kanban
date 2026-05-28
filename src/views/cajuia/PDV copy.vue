<template>
  <v-container fluid class="pdv-container pa-0 bg-animated-image">

    <div class="background-overlay"></div>

    <div class="content-wrapper pa-4 d-flex flex-column h-100">

      <div class="header-section d-flex align-center justify-space-between mb-4 flex-shrink-0">
        <div class="d-flex align-center text-caption text-white-50">
          <v-icon size="small" class="mr-2">mdi-store</v-icon>
          <span>Cajuia</span>
          <v-icon size="small" class="mx-2">mdi-chevron-right</v-icon>
          <span class="text-white font-weight-bold">PDV</span>
          <div class="ml-6 d-flex align-center text-success" v-if="isScannerReady">
             <v-icon size="small" class="mr-1 icon-pulse">mdi-barcode-scan</v-icon>
             <span class="text-[10px] font-weight-bold text-uppercase">Leitor Ativo</span>
          </div>
        </div>

        <div class="strategy-center d-flex align-center glass-panel px-1 py-1 rounded-pill border-white-10 mx-4 shadow-lg">
            <v-menu transition="slide-y-transition" :close-on-content-click="true">
                <template v-slot:activator="{ props }">
                    <v-btn
                        v-bind="props"
                        variant="text"
                        height="32"
                        class="text-none px-4 rounded-pill font-weight-bold letter-spacing-1"
                        :color="!hasSelectedPriceList ? 'error' : (activePriceList ? 'warning' : 'white')"
                        :class="{'animate-pulse-error': !hasSelectedPriceList}"
                    >
                        <v-icon start size="small">
                            {{ !hasSelectedPriceList ? 'mdi-alert-circle' : (activePriceList ? 'mdi-tag-text' : 'mdi-tag-outline') }}
                        </v-icon>

                        {{ !hasSelectedPriceList ? 'SELECIONE TABELA' : (activePriceList ? activePriceList.name : 'Varejo') }}

                        <v-icon end size="small" class="opacity-50">mdi-chevron-down</v-icon>
                    </v-btn>
                </template>
                <v-list density="compact" class="glass-menu border-white-10 pa-2 rounded-xl width-250">
                    <div class="text-[10px] text-white-50 font-weight-bold text-uppercase mb-2 px-2">Escolha Obrigatória</div>

                    <v-list-item
                        @click="selectPriceList(null)"
                        :active="hasSelectedPriceList && !activePriceList"
                        color="primary"
                        rounded="lg"
                        class="mb-1"
                    >
                        <template v-slot:prepend><v-icon size="small">mdi-store-outline</v-icon></template>
                        <v-list-item-title class="font-weight-bold">Varejo (Padrão)</v-list-item-title>
                    </v-list-item>

                    <v-divider class="my-1 border-white-10"></v-divider>

                    <v-list-item
                        v-for="list in priceLists"
                        :key="list.id"
                        @click="selectPriceList(list)"
                        :active="activePriceList?.id === list.id"
                        color="warning"
                        rounded="lg"
                        class="mb-1"
                    >
                        <template v-slot:prepend><v-icon size="small" color="warning">mdi-star-circle-outline</v-icon></template>
                        <v-list-item-title class="font-weight-bold text-white">{{ list.name }}</v-list-item-title>
                        <v-list-item-subtitle class="text-[10px]">{{ list.description || 'Tabela diferenciada' }}</v-list-item-subtitle>
                    </v-list-item>
                </v-list>
            </v-menu>
        </div>

        <div class="d-flex align-center gap-3">
          
          <v-menu location="bottom end" :close-on-content-click="false">
            <template v-slot:activator="{ props }">
               <v-btn v-bind="props" icon size="small" class="glass-btn-icon" color="white-70">
                  <v-icon>mdi-printer-settings</v-icon>
                  <v-tooltip activator="parent" location="bottom">Configurar Impressora</v-tooltip>
               </v-btn>
            </template>
            <v-card class="glass-menu border-white-10 pa-4 rounded-xl" width="280">
                <div class="text-caption font-weight-bold text-white mb-3 d-flex align-center">
                    <v-icon size="small" class="mr-2">mdi-receipt-text-outline</v-icon>
                    Formato de Recibo
                </div>
                <v-btn-toggle v-model="printFormat" mandatory density="compact" color="primary" class="glass-toggle w-100 border-white-10 d-flex flex-wrap" style="height: auto;">
                    <v-btn value="80mm" class="flex-grow-1 text-caption font-weight-bold py-1" height="32">
                        Cupom 80mm
                    </v-btn>
                    <v-btn value="58mm" class="flex-grow-1 text-caption font-weight-bold py-1" height="32">
                        Cupom 58mm
                    </v-btn>
                    <v-btn value="a4" class="flex-grow-1 text-caption font-weight-bold py-1" height="32" style="flex-basis: 100%;">
                        Folha A4
                    </v-btn>
                </v-btn-toggle>
                <div class="text-[10px] text-white-50 mt-2 text-center">
                    {{ printFormat === 'a4' ? 'Impressoras Jato de Tinta / Laser' : 'Impressoras Térmicas (Não Fiscal)' }}
                </div>
            </v-card>
          </v-menu>

          <div class="digital-clock px-3 py-1 rounded-pill glass-chip border-white-10 d-flex align-center">
             <v-icon color="primary" size="small" class="mr-2 icon-pulse">mdi-clock-outline</v-icon>
             <span class="font-weight-black text-caption text-white mono-font">{{ realTimeClock }}</span>
          </div>

          <div class="glass-chip px-3 py-1 rounded-pill d-flex align-center border-white-10 bg-glass-dark">
            <div class="d-flex align-center mr-3" v-if="cashStore.isSessionOpen">
                <div class="status-dot success mr-2"></div>
                <span class="text-caption text-white font-weight-bold">Caixa Aberto</span>
            </div>
            <div class="d-flex align-center mr-3" v-else>
                <div class="status-dot error mr-2"></div>
                <span class="text-caption text-white font-weight-bold">Caixa Fechado</span>
            </div>
            <v-divider vertical class="border-white-20 h-16 mr-3"></v-divider>
            <div class="d-flex align-center text-white-50" title="Última sincronização">
                <v-icon size="x-small" class="mr-1">mdi-sync</v-icon>
                <span class="text-caption font-mono">{{ lastSyncTime }}</span>
            </div>
          </div>
        </div>
      </div>

      <v-row class="flex-grow-1 overflow-hidden ma-0" no-gutters>

        <v-col cols="12" md="8" lg="9" class="d-flex flex-column pr-md-4 h-100 overflow-hidden">
          <div class="glass-panel d-flex flex-column h-100 rounded-xl overflow-hidden shadow-xl border-white-05">

            <div class="px-4 py-3 border-b border-white-10 d-flex flex-column gap-3 bg-glass-header">
              <div class="d-flex align-center gap-3">
                <div style="width: 280px;">
                    <v-text-field
                    v-model="productSearch"
                    density="compact"
                    variant="solo"
                    placeholder="Buscar produto (F2)..."
                    prepend-inner-icon="mdi-magnify"
                    hide-details
                    class="glass-input"
                    rounded="lg"
                    bg-color="rgba(20, 20, 25, 0.4)"
                    clearable
                    ref="searchRef"
                    ></v-text-field>
                </div>

                <v-divider vertical class="border-white-10 h-24"></v-divider>

                <div style="width: 160px;">
                    <v-select
                        v-model="filterGender"
                        :items="gendersList"
                        item-title="name"
                        item-value="name"
                        label="Gênero"
                        density="compact"
                        variant="solo"
                        hide-details
                        class="glass-input"
                        bg-color="rgba(20, 20, 25, 0.4)"
                        clearable
                        menu-icon="mdi-chevron-down"
                    ></v-select>
                </div>

                <div style="width: 160px;">
                    <v-select
                        v-model="filterCategory"
                        :items="categoriesList"
                        item-title="name"
                        item-value="name"
                        label="Categoria"
                        density="compact"
                        variant="solo"
                        hide-details
                        class="glass-input"
                        bg-color="rgba(20, 20, 25, 0.4)"
                        clearable
                        menu-icon="mdi-chevron-down"
                    ></v-select>
                </div>

                <v-spacer></v-spacer>

                <div class="d-flex align-center gap-2">
                    <v-btn icon size="small" variant="text" class="glass-btn-icon" @click="fetchData" :loading="isSyncingProducts">
                        <v-icon color="white">mdi-refresh</v-icon>
                        <v-tooltip activator="parent" location="bottom">Sincronizar Agora</v-tooltip>
                    </v-btn>
                </div>
              </div>

              <div class="d-flex align-center justify-space-between">
                  <v-chip-group v-model="stockFilter" mandatory selected-class="text-primary bg-primary-10" class="filter-chips">
                    <v-chip value="all" variant="outlined" size="small" class="glass-chip border-white-10 font-weight-bold px-3">Todos</v-chip>
                    <v-chip value="in_stock" variant="outlined" size="small" class="glass-chip border-white-10 font-weight-bold px-3">Em Estoque</v-chip>
                    <v-chip value="low_stock" variant="outlined" size="small" class="glass-chip border-white-10 font-weight-bold px-3 text-warning">Baixo Estoque</v-chip>
                  </v-chip-group>

                  <div class="text-caption text-white-50 font-weight-medium mr-2">
                      {{ filteredProducts.length }} produtos encontrados
                  </div>
              </div>
            </div>

            <div class="flex-grow-1 overflow-y-auto custom-scrollbar pa-4 bg-glass-body-gradient">
              <v-row v-if="isLoadingProducts" dense>
                <v-col v-for="n in 12" :key="n" cols="12" sm="6" md="4" lg="3" xl="2">
                  <v-skeleton-loader type="image, article" class="bg-transparent rounded-xl opacity-20"></v-skeleton-loader>
                </v-col>
              </v-row>

              <div v-else-if="filteredProducts.length === 0" class="fill-height d-flex flex-column align-center justify-center text-white-50">
                <v-icon size="64" class="mb-4 opacity-20">mdi-hanger</v-icon>
                <span class="text-body-2 opacity-70">Nenhum produto com esses filtros</span>
              </div>

              <v-row v-else dense class="product-grid-gap">
                <v-col
                  v-for="product in filteredProducts"
                  :key="product.id"
                  cols="12"
                  sm="6"
                  md="4"
                  lg="3"
                  xl="2"
                >
                  <v-hover v-slot="{ isHovering, props }">
                    <v-card
                      v-bind="props"
                      class="glass-product-card h-100 d-flex flex-column rounded-xl border-white-05 transition-all overflow-hidden"
                      :class="{ 'hover-elevate': isHovering, 'opacity-60 grayscale': product.quantity_in_stock <= 0 }"
                      flat
                      @click="addToCart(product)"
                      v-ripple
                    >
                      <v-scale-transition>
                        <div v-if="getCartQuantity(product) > 0" class="cart-badge">
                          <v-chip color="primary" variant="flat" size="x-small" class="font-weight-black px-2 elevation-4 border-2-white">
                            {{ getCartQuantity(product) }}
                          </v-chip>
                        </div>
                      </v-scale-transition>

                      <div v-if="product.discountPct > 0" class="discount-ribbon">
                          <span class="text-[10px] font-weight-black text-white">
                              -{{ product.discountPct }}%
                          </span>
                      </div>

                      <div class="product-image-wrapper bg-black-50 position-relative">
                        <v-img
                          :src="product.photo_url || '/placeholder.png'"
                          aspect-ratio="1"
                          cover
                          class="product-img transition-transform duration-500"
                          :class="{'scale-110': isHovering}"
                        >
                          <template v-slot:placeholder>
                            <div class="d-flex align-center justify-center fill-height">
                              <v-progress-circular indeterminate color="white-20" size="20" width="2"></v-progress-circular>
                            </div>
                          </template>
                        </v-img>

                        <div v-if="product.quantity_in_stock <= 0" class="stock-overlay d-flex align-center justify-center backdrop-blur-sm">
                          <span class="text-caption font-weight-black text-uppercase text-white bg-error px-3 py-1 rounded-pill shadow-lg">Esgotado</span>
                        </div>

                        <div class="absolute-bottom-gradient pa-2 d-flex justify-space-between align-end w-100">
                             <div class="d-flex flex-column gap-1">
                                <span class="text-[9px] text-white font-mono bg-black-50 backdrop-blur px-2 py-0-5 rounded text-shadow">
                                    {{ product.sku || 'N/A' }}
                                </span>
                                <v-chip size="x-small" :color="getStockColor(product.quantity_in_stock)" variant="flat" class="font-weight-bold h-16 px-2">
                                    {{ product.quantity_in_stock }} un
                                </v-chip>
                             </div>
                        </div>
                      </div>

                      <div class="pa-3 d-flex flex-column flex-grow-1 justify-space-between bg-glass-card-body">
                        <div class="mb-2">
                            <div class="d-flex gap-1 mb-1" v-if="product.category || product.gender">
                                <span class="text-[9px] text-white-50 text-uppercase font-weight-bold tracking-wide">
                                    {{ product.category }} {{ product.gender ? `• ${product.gender}` : '' }}
                                </span>
                            </div>
                            <div class="text-body-2 font-weight-bold text-white line-clamp-2 lh-1-2" :title="product.name">
                                {{ product.name }}
                            </div>
                        </div>

                        <div class="pt-2 border-t border-white-05 mt-auto d-flex align-end justify-space-between">
                          <div class="d-flex flex-column">
                              <span v-if="product.hasActivePrice && product.base_price > product.active_price" class="text-[10px] text-white-30 text-decoration-line-through mb-n1">
                                  {{ formatCurrency(product.base_price) }}
                              </span>
                              <span class="text-body-1 font-weight-black letter-spacing-tight" :class="product.hasActivePrice ? 'text-warning' : 'text-white'">
                                {{ formatCurrency(product.active_price) }}
                              </span>
                          </div>

                          <div class="add-btn-circle bg-white-10 d-flex align-center justify-center rounded-circle transition-all" :class="{'bg-primary text-white elevation-4': isHovering}">
                              <v-icon size="16">mdi-plus</v-icon>
                          </div>
                        </div>
                      </div>
                    </v-card>
                  </v-hover>
                </v-col>
              </v-row>
            </div>
          </div>
        </v-col>

        <v-col cols="12" md="4" lg="3" class="d-flex flex-column h-100 pl-md-0 mt-4 mt-md-0">
          <div class="glass-panel d-flex flex-column h-100 rounded-xl overflow-hidden border-l-0 shadow-xl">

            <div class="flex-shrink-0 bg-glass-header border-b border-white-10">
                <div class="d-flex align-center justify-space-between px-4 py-3">
                    <div class="d-flex align-center">
                        <div class="icon-circle bg-gradient-primary mr-3 text-white shadow-lg"><v-icon size="small">mdi-cart</v-icon></div>
                        <div>
                            <h2 class="text-subtitle-2 font-weight-bold text-white text-uppercase">Venda</h2>
                            <div class="text-[10px] text-white-50 font-weight-medium">#{{ nextOrderNumber }}</div>
                        </div>
                    </div>

                    <v-menu location="bottom end" transition="slide-y-transition">
                      <template v-slot:activator="{ props }">
                        <v-btn v-bind="props" icon variant="text" size="small" color="white" class="glass-btn-icon">
                            <v-icon>mdi-dots-vertical</v-icon>
                        </v-btn>
                      </template>
                      <v-list density="compact" class="glass-menu border-white-10 pa-2 rounded-xl width-250">
                         <v-list-subheader class="text-[10px] text-uppercase font-weight-bold text-white-50">Ações</v-list-subheader>
                         <v-list-item @click="clearCart" :disabled="cart.length === 0" rounded="lg" class="mb-1">
                            <template v-slot:prepend><v-icon size="small" color="error">mdi-delete-sweep</v-icon></template>
                            <v-list-item-title class="text-white">Limpar Venda (Esc)</v-list-item-title>
                         </v-list-item>
                         <v-list-item @click="saveDraft" :disabled="cart.length === 0" rounded="lg" class="mb-1">
                            <template v-slot:prepend><v-icon size="small" color="warning">mdi-content-save-outline</v-icon></template>
                            <v-list-item-title class="text-white">Salvar Rascunho</v-list-item-title>
                         </v-list-item>
                         <v-list-item @click="openDraftsModal" rounded="lg" class="mb-1">
                            <template v-slot:prepend><v-icon size="small" color="info">mdi-folder-open-outline</v-icon></template>
                            <v-list-item-title class="text-white">Carregar Rascunho</v-list-item-title>
                         </v-list-item>
                         <v-divider class="my-2 border-white-10"></v-divider>
                         <v-list-subheader class="text-[10px] text-uppercase font-weight-bold text-white-50">Caixa & Operações</v-list-subheader>
                         <v-list-item @click="showCashOperationsModal = true" rounded="lg" class="mb-1">
                            <template v-slot:prepend><v-icon size="small" color="warning">mdi-cash-fast</v-icon></template>
                            <v-list-item-title class="text-white">Sangria / Suprimento</v-list-item-title>
                         </v-list-item>
                         <v-list-item @click="handleRomaneio" :loading="isPdfGenerating" :disabled="cart.length === 0" rounded="lg" class="mb-1">
                            <template v-slot:prepend><v-icon size="small" color="info">mdi-file-document</v-icon></template>
                            <v-list-item-title class="text-white">Gerar Romaneio ({{ printFormat }})</v-list-item-title>
                         </v-list-item>
                         <v-list-item @click="showCashClosingModal = true" rounded="lg" class="mb-1">
                            <template v-slot:prepend><v-icon size="small" color="error">mdi-lock</v-icon></template>
                            <v-list-item-title class="text-white">Fechar Caixa</v-list-item-title>
                         </v-list-item>
                      </v-list>
                    </v-menu>
                </div>

                <div class="px-2 pb-2">
                    <v-btn-toggle
                        v-model="activeTab"
                        mandatory
                        rounded="lg"
                        class="d-flex w-100 glass-toggle border-white-10"
                        base-color="transparent"
                        color="primary"
                        density="compact"
                    >
                        <v-btn value="items" class="flex-grow-1 text-caption font-weight-bold text-none" height="32">
                            <v-icon start size="small">mdi-format-list-bulleted</v-icon> Carrinho ({{ cartItemCount }})
                        </v-btn>
                        <v-btn value="payment" class="flex-grow-1 text-caption font-weight-bold text-none" height="32" :disabled="cart.length === 0">
                            <v-icon start size="small">mdi-credit-card-outline</v-icon> Pagamento
                        </v-btn>
                    </v-btn-toggle>
                </div>
            </div>

            <div class="flex-grow-1 overflow-hidden d-flex flex-column position-relative">

                <div v-if="activeTab === 'items'" class="d-flex flex-column h-100 fade-transition">

                    <div class="px-4 pt-2 pb-0">
                        <v-autocomplete
                            v-model="selectedCustomer"
                            :items="clientList"
                            item-title="nome"
                            item-value="id"
                            placeholder="Buscar Cliente (Insert)..."
                            variant="solo"
                            density="compact"
                            prepend-inner-icon="mdi-account-search"
                            :loading="isSyncingProducts"
                            return-object
                            hide-details
                            class="glass-input mb-2"
                            rounded="lg"
                            bg-color="rgba(0, 0, 0, 0.3)"
                            menu-icon="mdi-chevron-down"
                            clearable
                            :custom-filter="filterClients"
                        >
                            <template v-slot:append-inner>
                            <v-btn icon="mdi-account-plus" size="x-small" variant="text" color="success" class="ml-1" @click.stop="showClientModal = true"></v-btn>
                            </template>
                            <template v-slot:no-data>
                            <div class="px-4 py-2 text-caption text-white-50">Digite para buscar...</div>
                            </template>
                        </v-autocomplete>

                        <v-expand-transition>
                            <div v-if="!selectedCustomer || selectedCustomer.nome === 'Consumidor' || selectedCustomer.id === 0 || !selectedCustomer.cpf_cnpj" class="mb-2">
                                <v-text-field
                                    v-model="cpfNota"
                                    label="CPF na Nota (Opcional)"
                                    density="compact"
                                    variant="solo"
                                    bg-color="rgba(0,0,0,0.2)"
                                    hide-details
                                    class="glass-input"
                                    prepend-inner-icon="mdi-card-account-details-outline"
                                    v-maska="'###.###.###-##'"
                                ></v-text-field>
                            </div>
                        </v-expand-transition>
                    </div>

                    <div class="flex-grow-1 overflow-y-auto custom-scrollbar px-3 py-2 bg-glass-body">
                        <v-scale-transition group>
                            <div v-for="(item, index) in cart" :key="item.product_id" class="cart-item-row py-2 px-3 mb-2 rounded-lg d-flex align-center glass-row border-white-05 position-relative overflow-hidden hover-highlight">
                                <div v-if="activePriceList" class="absolute-left-indicator bg-warning shadow-glow-warning"></div>
                                <v-avatar rounded="lg" size="36" class="mr-3 bg-black-20 border-white-10 elevation-2">
                                    <v-img :src="item.photo_url || '/placeholder.png'" cover></v-img>
                                </v-avatar>
                                <div class="flex-grow-1 overflow-hidden mr-2">
                                    <div class="text-[11px] font-weight-bold text-white text-truncate mb-1">{{ item.product_name }}</div>
                                    <div class="text-[10px] text-white-50 d-flex align-center">
                                        {{ formatCurrency(item.unit_price) }}
                                        <v-icon v-if="activePriceList" size="10" color="warning" class="ml-1">mdi-tag-text</v-icon>
                                    </div>
                                </div>
                                <div class="d-flex flex-column align-end">
                                    <div class="text-body-2 font-weight-bold text-white mb-1">{{ formatCurrency(item.total_price) }}</div>
                                    <div class="qty-selector d-flex align-center rounded bg-white-05 border-white-10">
                                        <v-btn icon="mdi-minus" size="x-small" variant="text" density="compact" class="qty-btn w-20 h-20" @click="updateCartQuantity(index, -1)"></v-btn>
                                        <span class="text-[11px] font-weight-bold mx-2 text-white mono-font">{{ item.quantity }}</span>
                                        <v-btn icon="mdi-plus" size="x-small" variant="text" density="compact" class="qty-btn w-20 h-20" @click="updateCartQuantity(index, 1)"></v-btn>
                                    </div>
                                </div>
                            </div>
                        </v-scale-transition>

                        <div v-if="cart.length === 0" class="fill-height d-flex flex-column align-center justify-center text-white-30 my-10">
                            <div class="icon-circle bg-white-05 mb-3"><v-icon>mdi-cart-off</v-icon></div>
                            <span class="text-caption opacity-70">Carrinho vazio</span>
                        </div>
                    </div>

                    <div class="pa-3 bg-glass-footer border-t border-white-10 mt-auto">
                        <div class="d-flex justify-space-between align-end mb-2 px-1">
                            <span class="text-caption text-white-50 font-weight-bold text-uppercase">Subtotal</span>
                            <span class="text-h6 font-weight-black text-white lh-1">{{ formatCurrency(subtotal) }}</span>
                        </div>
                        <v-btn block size="large" color="primary" class="font-weight-bold rounded-lg" @click="activeTab = 'payment'" :disabled="cart.length === 0">
                            IR PARA PAGAMENTO
                            <v-icon end size="small" class="ml-2">mdi-arrow-right</v-icon>
                        </v-btn>
                    </div>
                </div>

                <div v-if="activeTab === 'payment'" class="d-flex flex-column h-100 fade-transition">

                    <div class="flex-grow-1 overflow-y-auto custom-scrollbar px-3 py-3 bg-glass-body">

                        <div class="mb-3">
                            <span class="text-[10px] text-white-50 font-weight-bold text-uppercase mb-2 d-block">Formas de Pagamento</span>
                            <div class="d-flex gap-2 flex-wrap">
                                <v-chip
                                    v-for="method in paymentMethods"
                                    :key="method.nome"
                                    :color="selectedPaymentMethod?.nome === method.nome ? 'primary' : 'white'"
                                    :variant="selectedPaymentMethod?.nome === method.nome ? 'flat' : 'outlined'"
                                    size="small"
                                    class="font-weight-bold cursor-pointer glass-chip"
                                    @click="selectedPaymentMethod = method"
                                >
                                    {{ method.nome }}
                                </v-chip>
                            </div>
                        </div>

                        <div class="glass-well pa-3 rounded-lg mb-4 border-white-05">
                            <div class="d-flex align-center gap-2 mb-2">
                                <div class="flex-grow-1">
                                    <v-select
                                        v-model="selectedPaymentMethod"
                                        :items="paymentMethods"
                                        item-title="nome"
                                        return-object
                                        label="Método Selecionado"
                                        variant="solo"
                                        density="compact"
                                        bg-color="rgba(0, 0, 0, 0.3)"
                                        hide-details
                                        class="glass-input"
                                        rounded="lg"
                                        menu-icon="mdi-chevron-down"
                                    ></v-select>
                                </div>
                                <div style="width: 110px;">
                                    <v-text-field
                                        v-model.number="paymentAmountInput"
                                        label="Valor"
                                        type="number"
                                        density="compact"
                                        variant="solo"
                                        bg-color="rgba(0, 0, 0, 0.3)"
                                        hide-details
                                        class="glass-input"
                                        rounded="lg"
                                        prefix="R$"
                                    ></v-text-field>
                                </div>
                                <v-btn
                                    icon="mdi-plus"
                                    size="small"
                                    color="success"
                                    class="rounded-lg"
                                    @click="addPayment"
                                    :disabled="!selectedPaymentMethod || paymentAmountInput <= 0"
                                ></v-btn>
                            </div>

                            <div v-if="payments.length > 0" class="d-flex flex-column gap-1 mt-2">
                                <div v-for="(p, i) in payments" :key="i" class="d-flex align-center justify-space-between py-2 px-3 bg-white-05 rounded border border-white-05">
                                    <div class="d-flex align-center gap-2">
                                        <v-icon size="small" color="success">mdi-check-circle</v-icon>
                                        <span class="text-caption font-weight-bold text-white">{{ p.method.nome }}</span>
                                    </div>
                                    <div class="d-flex align-center gap-3">
                                        <span class="text-body-2 font-weight-bold text-white">{{ formatCurrency(p.amount) }}</span>
                                        <v-btn icon="mdi-close" size="x-small" variant="text" color="error" density="compact" @click="removePayment(i)"></v-btn>
                                    </div>
                                </div>
                            </div>
                            <div v-else class="text-center py-2">
                                <span class="text-[10px] text-white-30">Nenhum pagamento adicionado.</span>
                            </div>
                        </div>

                        <div class="d-flex flex-column gap-3 mb-4">

                            <div class="d-flex align-center gap-2">
                                <v-btn-toggle v-model="discountType" density="compact" color="primary" mandatory class="glass-toggle flex-shrink-0 border-white-10" style="height: 36px;">
                                    <v-btn value="money" class="text-[10px] px-2">R$</v-btn>
                                    <v-btn value="percent" class="text-[10px] px-2">%</v-btn>
                                </v-btn-toggle>
                                <v-text-field v-model="discountValue" type="number" density="compact" variant="solo" placeholder="Desconto" hide-details class="glass-input" rounded="lg" bg-color="rgba(0,0,0,0.3)" min="0">
                                    <template v-slot:prepend-inner><v-icon size="small" color="white-50">mdi-tag-outline</v-icon></template>
                                </v-text-field>
                            </div>

                            <v-expand-transition>
                                <div v-if="hasCardPayment" class="d-flex align-center justify-space-between glass-well pa-2 rounded-lg border-white-05">
                                    <div class="d-flex align-center gap-2">
                                        <v-switch v-model="enableCardFee" color="warning" density="compact" hide-details inset class="scale-06 ml-n2"></v-switch>
                                        <div class="d-flex flex-column">
                                            <span class="text-[10px] font-weight-bold text-white">Taxa Maquininha</span>
                                            <span class="text-[9px] text-white-50">Repassar custo</span>
                                        </div>
                                    </div>
                                    <div style="width: 80px;">
                                        <v-text-field v-model="cardFeePercentage" density="compact" variant="outlined" hide-details class="glass-input centered-input" type="number" :disabled="!enableCardFee" bg-color="rgba(0,0,0,0.6)">
                                            <template v-slot:append-inner><span class="text-caption font-weight-bold text-white-70">%</span></template>
                                        </v-text-field>
                                    </div>
                                </div>
                            </v-expand-transition>

                            <v-expand-transition>
                                <div v-if="hasInstallmentPayment" class="d-flex gap-2">
                                    <v-text-field v-model.number="installments" label="Parcelas" type="number" min="1" max="12" density="compact" variant="solo" bg-color="rgba(0,0,0,0.3)" hide-details class="glass-input w-50" rounded="lg">
                                        <template v-slot:prepend-inner><span class="text-caption text-white-50 font-weight-bold mt-1">x</span></template>
                                    </v-text-field>
                                    <v-text-field v-model="firstDueDate" label="Vencimento" type="date" density="compact" variant="solo" bg-color="rgba(0,0,0,0.3)" hide-details class="glass-input w-50" rounded="lg"></v-text-field>
                                </div>
                            </v-expand-transition>

                            <v-expand-transition>
                                <div v-if="hasPixPayment" class="glass-well pa-2 rounded-lg d-flex align-center justify-space-between border-white-05">
                                    <div class="d-flex align-center gap-2">
                                        <v-icon size="small" color="primary">mdi-qrcode-scan</v-icon>
                                        <span class="text-[10px] font-weight-bold text-white">Gerar QR Code Pix?</span>
                                    </div>
                                    <v-switch v-model="generatePixQr" color="success" density="compact" hide-details inset class="scale-06"></v-switch>
                                </div>
                            </v-expand-transition>

                            <v-textarea v-model="orderNotes" label="Observações do Pedido" variant="solo" density="compact" bg-color="rgba(0,0,0,0.3)" class="glass-input" hide-details rows="2" rounded="lg"></v-textarea>
                        </div>
                    </div>

                    <div class="pa-4 bg-glass-footer border-t border-white-10 mt-auto">

                        <div class="mb-4">
                            <div class="d-flex justify-space-between align-center mb-1">
                                <span class="text-[10px] font-weight-bold text-white-50 text-uppercase">Subtotal</span>
                                <span class="text-caption text-white font-mono">{{ formatCurrency(subtotal) }}</span>
                            </div>
                            <div v-if="discountAmount > 0" class="d-flex justify-space-between align-center mb-1">
                                <span class="text-[10px] font-weight-bold text-error text-uppercase">Desconto</span>
                                <span class="text-caption text-error font-mono">-{{ formatCurrency(discountAmount) }}</span>
                            </div>
                            <div v-if="cardFeeAmount > 0" class="d-flex justify-space-between align-center mb-1">
                                <span class="text-[10px] font-weight-bold text-warning text-uppercase">Taxa Maq.</span>
                                <span class="text-caption text-warning font-mono">+{{ formatCurrency(cardFeeAmount) }}</span>
                            </div>
                            <v-divider class="border-white-10 my-2"></v-divider>
                            <div class="d-flex justify-space-between align-end mb-3">
                                <span class="text-caption font-weight-bold text-white text-uppercase">Total a Pagar</span>
                                <span class="text-h4 font-weight-black text-success lh-1 text-shadow">{{ formatCurrency(finalTotal) }}</span>
                            </div>

                            <div class="glass-well pa-2 rounded-lg border-white-05">
                                <div class="d-flex justify-space-between align-center mb-1">
                                    <span class="text-[10px] font-weight-bold text-white-50 text-uppercase">Valor Pago</span>
                                    <span class="text-body-2 font-weight-bold text-white">{{ formatCurrency(totalPaid) }}</span>
                                </div>
                                <div class="d-flex justify-space-between align-center">
                                    <span class="text-[10px] font-weight-bold text-uppercase" :class="remainingAmount > 0.05 ? 'text-warning' : 'text-success'">
                                        {{ remainingAmount > 0.05 ? 'Restante' : 'Troco' }}
                                    </span>
                                    <span class="text-h6 font-weight-black" :class="remainingAmount > 0.05 ? 'text-warning' : 'text-success'">
                                        {{ formatCurrency(Math.abs(remainingAmount)) }}
                                    </span>
                                </div>
                                <v-progress-linear
                                    :model-value="(totalPaid / finalTotal) * 100"
                                    :color="remainingAmount > 0.05 ? 'warning' : 'success'"
                                    height="6"
                                    rounded
                                    class="mt-2"
                                ></v-progress-linear>
                            </div>
                        </div>

                        <div class="d-flex gap-2">
                            <v-btn variant="tonal" color="white" class="rounded-lg flex-grow-0" @click="activeTab = 'items'">
                                <v-icon>mdi-arrow-left</v-icon>
                            </v-btn>
                            <v-btn
                                block
                                size="large"
                                color="success"
                                class="font-weight-bold rounded-lg shadow-glow-success text-none flex-grow-1"
                                :disabled="!isOrderValid"
                                :loading="isSubmitting"
                                @click="submitCajuiaOrder"
                                height="48"
                            >
                                <span class="text-body-1 font-weight-bold">FINALIZAR VENDA (F9)</span>
                                <v-icon end size="small" class="ml-2">mdi-check-circle</v-icon>
                            </v-btn>
                        </div>
                    </div>
                </div>

            </div>
          </div>
        </v-col>
      </v-row>
    </div>

    <CajuiaClientFormModal :show="showClientModal" @close="showClientModal = false" @client-created="handleClientCreated" />

    <CajuiaDraftsModal
        :show="showDraftsModal"
        :drafts="draftsList"
        :loading="isLoadingDrafts"
        @close="showDraftsModal = false"
        @load="loadDraft"
        @delete="deleteDraft"
    />

    <CashOpeningModal v-model="showCashOpeningModal" @session-opened="handleSessionOpened" />
    <CashOperationsModal v-model="showCashOperationsModal" @operation-success="fetchData" />
    <CashClosingModal v-model="showCashClosingModal" @session-closed="handleSessionClosed" />

    <v-snackbar v-model="showScannerFeedback" color="success" timeout="1500" location="top center">
      <v-icon start>mdi-barcode-scan</v-icon>
      <span class="font-weight-bold">{{ scannedProductFeedback }}</span>
    </v-snackbar>

    <v-dialog v-model="showPixModal" max-width="1100px" persistent content-class="glass-dialog-backdrop">
      <v-card class="glass-modal border-white-10 rounded-xl overflow-hidden elevation-24">
        <div class="px-8 py-5 bg-glass-header border-b border-white-10 d-flex align-center justify-space-between">
            <div class="d-flex align-center gap-6"> <div class="icon-box-lg bg-gradient-success shadow-glow-success rounded-xl d-flex align-center justify-center elevation-6">
                    <v-icon color="white" size="32">mdi-pix</v-icon>
                </div>
                <div class="d-flex flex-column">
                    <span class="text-h5 font-weight-black text-white lh-1 mb-1">Pagamento Pix</span>
                    <div class="d-flex align-center">
                        <span class="text-caption text-white-70 font-weight-medium text-uppercase tracking-wide">
                            Checkout Seguro Cora Bank
                        </span>
                    </div>
                </div>
            </div>
            <v-btn icon variant="text" color="white-50" size="large" @click="closePixModal" class="hover-scale">
                <v-icon size="28">mdi-close</v-icon>
            </v-btn>
        </div>

        <div class="d-flex flex-column flex-md-row" style="min-height: 600px;">
            <div
                class="bg-white pa-8 d-flex align-center justify-center flex-grow-1 position-relative cursor-zoom-in group"
                style="flex-basis: 55%;"
                @click="showZoomModal = true"
            >
                <div v-if="pixData.imagem" class="d-flex flex-column align-center w-100 h-100 justify-center relative">
                    <v-tooltip activator="parent" location="top">Clique para ampliar</v-tooltip>
                    <v-img
                        :src="pixData.imagem"
                        width="100%"
                        height="100%"
                        max-width="420"
                        max-height="420"
                        contain
                        class="qr-image transition-transform duration-300 filter-drop-shadow"
                    ></v-img>
                    <div class="mt-8 d-flex align-center gap-2 opacity-50">
                        <v-icon color="black" size="small">mdi-shield-check</v-icon>
                        <span class="text-caption font-weight-bold text-black text-uppercase tracking-widest">Ambiente Seguro</span>
                    </div>
                </div>
                <div v-else class="d-flex flex-column align-center justify-center fill-height text-black w-100">
                    <div class="loading-pulse mb-4"></div>
                    <span class="text-body-2 font-weight-bold text-grey-darken-1">Gerando cobrança dinâmica...</span>
                </div>
            </div>

            <div class="d-flex flex-column bg-glass-body" style="flex-basis: 45%; border-left: 1px solid rgba(255,255,255,0.08);">
                <div class="pa-8 border-b border-white-05">
                    <div class="status-card-active pa-5 rounded-xl border-l-4-success bg-gradient-status elevation-4 d-flex align-center">
                        <div class="mr-4 relative">
                             <div class="absolute-ping"></div>
                             <v-icon color="success" size="36" class="relative z-10">mdi-clock-outline</v-icon>
                        </div>
                        <div>
                            <div class="text-h6 font-weight-black text-white lh-1-2 mb-1">
                                Aguardando Pagamento...
                            </div>
                            <div class="text-caption text-green-lighten-4 font-weight-medium lh-1-2">
                                O sistema identificará o pagamento automaticamente.
                            </div>
                        </div>
                    </div>
                </div>

                <div class="px-8 py-6 flex-grow-1">
                    <div class="d-flex align-end justify-space-between mb-6">
                        <span class="text-overline text-white-50">Total a Pagar</span>
                      <span class="text-4xl font-weight-black text-success text-shadow lh-1">
                          {{ formatCurrency(currentPixAmount) }}
                      </span>
                    </div>

                    <div class="metadata-grid rounded-xl bg-white-03 border border-white-05 pa-5">
                        <div class="mb-4 pb-4 border-b border-white-05">
                            <div class="text-[10px] text-white-50 font-weight-bold text-uppercase mb-1">Cliente</div>
                            <div class="text-body-1 text-white font-weight-bold text-truncate">
                                {{ selectedCustomer?.nome || 'Consumidor Final' }}
                            </div>
                            <div class="text-caption text-white-50 font-mono mt-1">
                                CPF/CNPJ: {{ selectedCustomer?.cpf_cnpj || cpfNota || 'Não informado' }}
                            </div>
                        </div>
                    </div>
                </div>

                <div class="px-8 pb-8 mt-auto">
                    <div class="text-[11px] text-white-50 mb-2 font-weight-bold text-uppercase ml-1">Pix Copia e Cola</div>
                    <v-text-field
                        v-if="pixData.copiaCola"
                        v-model="pixData.copiaCola"
                        readonly
                        variant="outlined"
                        density="compact"
                        hide-details
                        class="glass-input mb-6 font-mono text-caption copy-field"
                        bg-color="rgba(0,0,0,0.4)"
                        rounded="lg"
                    >
                        <template v-slot:append-inner>
                            <v-btn icon="mdi-content-copy" variant="text" density="compact" color="primary" @click="copyPixCode"></v-btn>
                        </template>
                    </v-text-field>

                    <v-btn
                        color="success"
                        block
                        size="x-large"
                        class="rounded-xl font-weight-bold shadow-glow-success text-body-1 letter-spacing-1"
                        @click="manualConfirmPix"
                        prepend-icon="mdi-check-circle"
                        height="56"
                    >
                        Confirmar Recebimento (Manual)
                    </v-btn>
                </div>
            </div>
        </div>
      </v-card>
    </v-dialog>

    <v-dialog v-model="showZoomModal" fullscreen transition="fade-transition" style="z-index: 9999;">
        <v-card color="black" class="d-flex align-center justify-center position-relative" @click="showZoomModal = false">
            <v-btn icon="mdi-close" variant="text" color="white" size="x-large" class="position-absolute top-0 right-0 ma-6" style="z-index: 10;"></v-btn>
            <div class="bg-white pa-8 rounded-xl elevation-24" @click.stop>
                <v-img :src="pixData.imagem" width="85vh" height="85vh" contain></v-img>
            </div>
        </v-card>
    </v-dialog>

    <v-dialog v-model="showSuccessModal" max-width="400px" persistent content-class="glass-dialog">
      <v-card class="glass-modal border-white-10 text-center rounded-xl">
        <div class="pa-8">
          <div class="d-flex justify-center mb-6">
            <div class="icon-circle-large bg-gradient-success elevation-10 pulsing-animation">
                <v-icon size="48" color="white">mdi-check-bold</v-icon>
            </div>
          </div>
          <h2 class="text-h5 font-weight-black text-white mb-2">Venda Realizada!</h2>
          <p class="text-white-50 text-body-2 mb-6">Pedido <strong class="text-white">#{{ createdOrderNumber }}</strong> registrado com sucesso.</p>
          
          <div class="mb-4">
              <span class="text-caption text-white-50 font-weight-bold text-uppercase mb-2 d-block">Formato de Impressão</span>
              <v-btn-toggle v-model="printFormat" mandatory density="compact" color="primary" class="glass-toggle w-100 border-white-10">
                  <v-btn value="a4" class="flex-grow-1 text-caption font-weight-bold">A4</v-btn>
                  <v-btn value="80mm" class="flex-grow-1 text-caption font-weight-bold">80mm</v-btn>
                  <v-btn value="58mm" class="flex-grow-1 text-caption font-weight-bold">58mm</v-btn>
              </v-btn-toggle>
          </div>

          <div class="d-flex flex-column gap-3">
              <v-btn color="primary" variant="flat" block size="large" class="rounded-lg shadow-glow-primary font-weight-bold" @click="handleGenerateReceipt" :loading="isPdfGenerating">
                <v-icon start>mdi-printer</v-icon> Imprimir Recibo
              </v-btn>
              <v-btn variant="outlined" block class="text-white-70 rounded-lg border-white-10" @click="resetForm">Nova Venda</v-btn>
          </div>
        </div>
      </v-card>
    </v-dialog>

  </v-container>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted, computed, watch } from 'vue'
import { supabase } from '@/api/supabase'
import { fetchCustomersBC, createSaleBC, getSaleStatusBC, type BomControleSalePayload, type BomControleSaleItem } from '@/api/bomControle'
import { coraApi } from '@/api/coraProxy'
import { useUserStore } from '@/stores/user'
import { useAppStore } from '@/stores/app'
import { useCashSessionStore } from '@/stores/cashSession'
import { useCajuiaPDF, type PrintFormat } from '@/composables/useCajuiaPDF'
import { useCajuiaFinancial } from '@/composables/useCajuiaFinancial'
import { format } from 'date-fns'
import jsPDF from 'jspdf'
import autoTable from 'jspdf-autotable'
import { vMaska } from "maska/vue"

// Components
import CajuiaClientFormModal from '@/components/CajuiaClientFormModal.vue'
import CajuiaDraftsModal from '@/components/CajuiaDraftsModal.vue'
import CashOpeningModal from '@/components/cajuia/CashOpeningModal.vue'
import CashOperationsModal from '@/components/cajuia/CashOperationsModal.vue'
import CashClosingModal from '@/components/cajuia/CashClosingModal.vue'

// Types
type CajuiaProduct = {
    id: string;
    name: string;
    sku: string | null;
    barcode?: string | null;
    category?: string;
    gender?: string;
    base_price: number;
    active_price: number;
    photo_url: string | null;
    quantity_in_stock: number;
    gestaoclick_id: string | null;
    hasActivePrice: boolean;
    discountPct: number;
}

type CartItem = {
    product_id: string;
    product_name: string;
    photo_url: string | null;
    quantity: number;
    unit_price: number;
    total_price: number;
    stock_available: number;
    gestaoclick_id: string | null;
}

type Client = { id: number; nome: string; cpf_cnpj?: string; }
type BCPaymentMethod = { nome: string; categoriaId: number; contaId: number; };
type PriceList = { id: string; name: string; description?: string; }
type AddedPayment = { method: BCPaymentMethod, amount: number }

// Stores & Composables
const userStore = useUserStore()
const appStore = useAppStore()
const cashStore = useCashSessionStore()
const { generateOrderReceipt, isGenerating: isPdfGenerating } = useCajuiaPDF()
const { generateReceivablesFromOrder } = useCajuiaFinancial()

// State
const products = ref<any[]>([])
const productPricesMap = ref<Record<string, Record<string, number>>>({})
const priceLists = ref<PriceList[]>([])
const activePriceList = ref<PriceList | null>(null)
const categoriesList = ref<any[]>([])
const gendersList = ref<any[]>([])

// Print Configuration (Persistente)
const printFormat = ref<PrintFormat>((localStorage.getItem('cajuia_print_format') as PrintFormat) || '80mm');
watch(printFormat, (val) => localStorage.setItem('cajuia_print_format', val));

// Fluxo de Caixa
const hasSelectedPriceList = ref(false)
const showCashOpeningModal = computed({
    get: () => !cashStore.isSessionOpen && cashStore.isSessionChecked,
    set: (v) => {}
})
const showCashOperationsModal = ref(false)
const showCashClosingModal = ref(false)

// Filtros & Busca
const productSearch = ref('')
const filterCategory = ref(null)
const filterGender = ref(null)
const stockFilter = ref('in_stock')
const searchRef = ref<any>(null)

// Carrinho & Venda
const activeTab = ref('items')
const cart = ref<CartItem[]>([])
const clientSearch = ref('')
const clientList = ref<Client[]>([])
const isSearchingClients = ref(false)
const selectedCustomer = ref<Client | null>(null)
const showClientModal = ref(false)
const cpfNota = ref('')
let clientSearchTimeout: NodeJS.Timeout

// PAGAMENTOS MISTOS
const paymentMethods = ref<BCPaymentMethod[]>([])
const selectedPaymentMethod = ref<BCPaymentMethod | null>(null)
const paymentAmountInput = ref(0)
const payments = ref<AddedPayment[]>([])

const isSubmitting = ref(false)
const isLoadingProducts = ref(false)
const isSyncingProducts = ref(false)
const orderNotes = ref('')

// Pagamento Avançado
const generatePixQr = ref(true)
const installments = ref(1)
const firstDueDate = ref(format(new Date(), 'yyyy-MM-dd'))

// Descontos
const discountType = ref('money')
const discountValue = ref(0)

// TAXA DE CARTÃO
const enableCardFee = ref(true)
const cardFeePercentage = ref(5)

// Next Number
const nextOrderNumber = ref<number | string>('...')

// Modal Sucesso
const showSuccessModal = ref(false)
const createdOrderId = ref<string | null>(null)
const createdOrderNumber = ref<number | null>(null)
const lastSoldItems = ref<CartItem[]>([])

// Variáveis para Persistência no Recibo
const lastPaymentText = ref('');
const lastCpfNota = ref('');
const lastSoldTotal = ref(0);
const lastSoldCustomer = ref<any>(null);
// Adicionados para persistência do resumo financeiro
const lastDiscount = ref(0);
const lastChange = ref(0);

// RASCUNHOS
const showDraftsModal = ref(false)
const draftsList = ref<any[]>([])
const isLoadingDrafts = ref(false)
const draftsCount = ref(0)
const currentDraftId = ref<string | null>(null)

// PIX
const showPixModal = ref(false)
const showZoomModal = ref(false)
const pixData = ref({ imagem: '', copiaCola: '' })
const isPixConfirmed = ref(false)
const currentPixAmount = ref(0)

// Utils
const realTimeClock = ref(format(new Date(), 'HH:mm:ss'))
const lastSyncTime = ref('--:--')
let clockInterval: NodeJS.Timeout
let pixPollingInterval: NodeJS.Timeout | undefined;

// Cache
const CACHE_KEY_DATA = 'CAJUIA_PDV_DATA';
const CACHE_EXPIRATION_MS = 1000 * 60 * 60 * 12; 

// --- BARCODE SCANNER & HOTKEYS ---
const barcodeBuffer = ref('')
const lastKeyTime = ref(0)
const BARCODE_DELAY = 50
const showScannerFeedback = ref(false)
const scannedProductFeedback = ref('')
const isScannerReady = ref(true)

const handleGlobalKeydown = (e: KeyboardEvent) => {
    if (e.key === 'F2') { e.preventDefault(); searchRef.value?.focus(); return; }
    if (e.key === 'F9' || e.key === 'End') { e.preventDefault(); if (activeTab.value === 'items') activeTab.value = 'payment'; else if (isOrderValid.value) submitCajuiaOrder(); return; }
    if (e.key === 'Insert') { e.preventDefault(); showClientModal.value = true; return; }
    if (e.key === 'Escape') { if (!showClientModal.value && !showSuccessModal.value) { if(activeTab.value === 'payment') activeTab.value = 'items'; else if (cart.value.length > 0 && confirm('Limpar carrinho?')) clearCart(); } return; }

    const target = e.target as HTMLElement
    if (['INPUT', 'TEXTAREA'].includes(target.tagName)) return

    const currentTime = Date.now()
    if (currentTime - lastKeyTime.value > BARCODE_DELAY) { barcodeBuffer.value = '' }
    lastKeyTime.value = currentTime

    if (e.key === 'Enter') { if (barcodeBuffer.value.length > 2) { e.preventDefault(); processBarcode(barcodeBuffer.value) } barcodeBuffer.value = '' } 
    else if (e.key.length === 1) { barcodeBuffer.value += e.key }
}

const processBarcode = (code: string) => {
    const product = processedProducts.value.find(p => p.barcode === code)
    if (product) { addToCart(product); scannedProductFeedback.value = `Adicionado: ${product.name}`; showScannerFeedback.value = true } 
    else { appStore.showSnackbar(`Produto com código ${code} não encontrado.`, 'warning') }
}

// --- FILTRO LOCAL DE CLIENTES ---
const filterClients = (itemTitle: string, queryText: string, item: any) => {
    const text = queryText.toLowerCase();
    const nome = item.raw.nome ? item.raw.nome.toLowerCase() : '';
    const doc = item.raw.cpf_cnpj ? item.raw.cpf_cnpj.replace(/\D/g, '') : '';
    return nome.includes(text) || doc.includes(text);
};

// --- CACHE & SYNC ---
const loadFromCache = () => {
    const cached = localStorage.getItem(CACHE_KEY_DATA);
    if (cached) {
        try {
            const parsed = JSON.parse(cached);
            const now = new Date().getTime();
            if (now - parsed.timestamp < CACHE_EXPIRATION_MS) {
                products.value = parsed.products || [];
                clientList.value = parsed.clients || [];
                categoriesList.value = parsed.categories || [];
                gendersList.value = parsed.genders || [];
                priceLists.value = parsed.priceLists || [];
                productPricesMap.value = parsed.pricesMap || {};
                appStore.showSnackbar('Dados carregados do cache local.', 'info');
                return true; 
            }
        } catch (e) { console.error('Erro ao ler cache:', e); }
    }
    return false;
};

const saveToCache = () => {
    const dataToSave = { timestamp: new Date().getTime(), products: products.value, clients: clientList.value, categories: categoriesList.value, genders: gendersList.value, priceLists: priceLists.value, pricesMap: productPricesMap.value };
    try { localStorage.setItem(CACHE_KEY_DATA, JSON.stringify(dataToSave)); console.log('📦 Dados do PDV salvos no LocalStorage.'); } 
    catch (e) { console.error('Erro ao salvar cache:', e); }
};

const syncAllData = async () => {
    isSyncingProducts.value = true;
    try {
        console.log('🔄 Iniciando sincronização completa...');
        const [resProds, resCats, resLists, resPrices] = await Promise.all([
            supabase.from('cajuia_products').select('*').eq('is_active', true).order('name'),
            supabase.from('cajuia_categories').select('*').order('name'),
            supabase.from('cajuia_price_lists').select('*').order('created_at'),
            supabase.from('cajuia_product_prices').select('*')
        ]);

        if (resProds.data) products.value = resProds.data;
        if (resCats.data) { categoriesList.value = resCats.data.filter((i: any) => i.type === 'category'); gendersList.value = resCats.data.filter((i: any) => i.type === 'gender'); }
        if (resLists.data) priceLists.value = resLists.data;
        const map: Record<string, Record<string, number>> = {};
        if (resPrices.data) { resPrices.data.forEach((item: any) => { if (!map[item.price_list_id]) map[item.price_list_id] = {}; map[item.price_list_id][item.product_id] = Number(item.price); }); productPricesMap.value = map; }

        // BC Clientes Paginado
        let allClients: any[] = [];
        let page = 1;
        let hasMore = true;
        while (hasMore) {
            const res = await fetchCustomersBC('', page, 200); 
            if (res && res.length > 0) {
                const mapped = res.map((c: any) => ({
                    id: c.Id,
                    nome: c.Nome || c.PessoaFisica?.Nome || c.PessoaJuridica?.NomeFantasia || c.PessoaJuridica?.RazaoSocial || 'Desconhecido',
                    cpf_cnpj: c.CpfCnpj || c.PessoaFisica?.Documento || c.PessoaJuridica?.Documento || ''
                }));
                allClients = [...allClients, ...mapped];
                page++;
                if (res.length < 200) hasMore = false;
            } else { hasMore = false; }
        }
        if (allClients.length > 0) clientList.value = allClients;

        saveToCache();
        lastSyncTime.value = format(new Date(), 'HH:mm');
        appStore.showSnackbar('Dados sincronizados e cacheados!', 'success');
    } catch (e) { console.error('Erro na sincronização:', e); appStore.showSnackbar('Erro ao sincronizar dados. Usando versão local.', 'warning'); } 
    finally { isLoadingProducts.value = false; isSyncingProducts.value = false; }
};

const fetchData = async () => {
    const hasCache = loadFromCache();
    if (!hasCache) isLoadingProducts.value = true;
    await syncAllData();
    fetchDrafts();
};

// --- COMPUTED ---
const processedProducts = computed<CajuiaProduct[]>(() => {
    return products.value.map(p => {
        const base = Number(p.price) || 0; let active = base; let hasActive = false;
        if (activePriceList.value) { const listPrices = productPricesMap.value[activePriceList.value.id]; if (listPrices && listPrices[p.id] !== undefined) { active = listPrices[p.id]; hasActive = true; } }
        let discount = 0; if (hasActive && active < base && base > 0) discount = Math.round(((base - active) / base) * 100);
        return { id: p.id, name: p.name, sku: p.sku, barcode: p.barcode, category: p.category, gender: p.gender, base_price: base, active_price: active, photo_url: p.photo_url, quantity_in_stock: p.quantity_in_stock, gestaoclick_id: p.gestaoclick_id, hasActivePrice: hasActive, discountPct: discount };
    })
})

const filteredProducts = computed(() => {
  let result = [...processedProducts.value];
  if (productSearch.value) { const query = productSearch.value.toLowerCase(); result = result.filter(p => p.name.toLowerCase().includes(query) || p.sku?.toLowerCase().includes(query) || p.barcode?.toLowerCase().includes(query)) }
  if (filterCategory.value) result = result.filter(p => p.category === filterCategory.value);
  if (filterGender.value) result = result.filter(p => p.gender === filterGender.value);
  if (stockFilter.value === 'in_stock') result = result.filter(p => p.quantity_in_stock > 0); else if (stockFilter.value === 'low_stock') result = result.filter(p => p.quantity_in_stock > 0 && p.quantity_in_stock <= 5);
  result.sort((a, b) => a.name.localeCompare(b.name));
  return result;
})

const subtotal = computed(() => cart.value.reduce((total, item) => total + item.total_price, 0))
const discountAmount = computed(() => { const val = Number(discountValue.value) || 0; if (val <= 0) return 0; return discountType.value === 'percent' ? subtotal.value * (Math.min(val, 100) / 100) : Math.min(val, subtotal.value) })
const hasCardPayment = computed(() => { 
    const inList = payments.value.some(p => { const n = p.method.nome.toLowerCase(); return n.includes('crédito') || n.includes('credito') || n.includes('débito') || n.includes('debito'); });
    if (inList) return true;
    if (payments.value.length === 0 && selectedPaymentMethod.value) { const n = selectedPaymentMethod.value.nome.toLowerCase(); return n.includes('crédito') || n.includes('credito') || n.includes('débito') || n.includes('debito'); }
    return false; 
})
const hasPixPayment = computed(() => { const inList = payments.value.some(p => p.method.nome.toLowerCase().includes('pix')); if (inList) return true; if (payments.value.length === 0 && selectedPaymentMethod.value?.nome.toLowerCase().includes('pix')) return true; return false; })
const cardFeeAmount = computed(() => { if(!hasCardPayment.value || !enableCardFee.value) return 0; const baseValue = Math.max(0, subtotal.value - discountAmount.value); const pct = Number(cardFeePercentage.value) || 0; return baseValue * (pct / 100); })
const finalTotal = computed(() => { const base = Math.max(0, subtotal.value - discountAmount.value); return base + cardFeeAmount.value; })
const totalPaid = computed(() => payments.value.reduce((sum, p) => sum + p.amount, 0))
const remainingAmount = computed(() => finalTotal.value - totalPaid.value)
const hasInstallmentPayment = computed(() => { const allMethods = [...payments.value.map(p => p.method), selectedPaymentMethod.value].filter(Boolean); return allMethods.some(m => { const n = m!.nome.toLowerCase(); return !n.includes('dinheiro') && !n.includes('pix'); }); });
const cartItemCount = computed(() => cart.value.reduce((count, item) => count + item.quantity, 0))
const isOrderValid = computed(() => { if(cart.value.length === 0 || !selectedCustomer.value || !hasSelectedPriceList.value || !cashStore.isSessionOpen) return false; if(payments.value.length === 0) return !!selectedPaymentMethod.value; return totalPaid.value >= (finalTotal.value - 0.05); })

watch([remainingAmount, selectedPaymentMethod], ([rem, method]) => { if(rem > 0) paymentAmountInput.value = Number(rem.toFixed(2)); });

// --- ACTIONS ---
const fetchNextOrderNumber = async () => {
    try { const { data } = await supabase.from('cajuia_orders').select('order_number').order('order_number', { ascending: false }).limit(1).maybeSingle(); nextOrderNumber.value = data ? data.order_number + 1 : 1; } catch (e) { console.error(e) }
}
const selectPriceList = (list: PriceList | null) => { activePriceList.value = list; hasSelectedPriceList.value = true; appStore.showSnackbar(`Estratégia: ${list ? list.name : 'Varejo'} ativada.`, 'info'); recalcCartPrices(); }
const recalcCartPrices = () => { cart.value.forEach(item => { const product = processedProducts.value.find(p => p.id === item.product_id); if (product) { item.unit_price = product.active_price; item.total_price = item.quantity * item.unit_price; } }) }
const addToCart = (product: CajuiaProduct) => {
  if (!cashStore.isSessionOpen) { appStore.showSnackbar('Caixa fechado. Abra o caixa para vender.', 'error'); return; }
  if (product.quantity_in_stock <= 0) { appStore.showSnackbar('Produto esgotado.', 'warning'); return; }
  if(activeTab.value !== 'items') activeTab.value = 'items';
  const existingItem = cart.value.find(item => item.product_id === product.id);
  if (existingItem) { if (existingItem.quantity < existingItem.stock_available) { existingItem.quantity++; existingItem.total_price = existingItem.quantity * existingItem.unit_price; } else { appStore.showSnackbar('Máximo em estoque atingido.', 'warning'); } } 
  else { cart.value.push({ product_id: product.id, product_name: product.name, photo_url: product.photo_url, quantity: 1, unit_price: product.active_price, total_price: product.active_price, stock_available: product.quantity_in_stock, gestaoclick_id: product.gestaoclick_id }); }
}
const updateCartQuantity = (index: number, change: number) => { const item = cart.value[index]; const newQty = item.quantity + change; if (newQty <= 0) { cart.value.splice(index, 1); return; } if (newQty > item.stock_available) { appStore.showSnackbar('Limite de estoque.', 'warning'); return; } item.quantity = newQty; item.total_price = newQty * item.unit_price; }
const clearCart = () => { cart.value = []; payments.value = []; selectedPaymentMethod.value = null; currentDraftId.value = null; cpfNota.value = ''; activeTab.value = 'items'; }
const addPayment = () => { if(!selectedPaymentMethod.value || paymentAmountInput.value <= 0) return; payments.value.push({ method: selectedPaymentMethod.value, amount: paymentAmountInput.value }); if(remainingAmount.value <= 0) { selectedPaymentMethod.value = null; paymentAmountInput.value = 0; } }
const removePayment = (index: number) => { payments.value.splice(index, 1); }

// --- RASCUNHOS ---
const saveDraft = async () => {
    if(cart.value.length === 0) { appStore.showSnackbar('Carrinho vazio.', 'warning'); return; }
    const draftData = { cart: cart.value, client: selectedCustomer.value, payments: payments.value, discount: { type: discountType.value, value: discountValue.value }, installments: installments.value, notes: orderNotes.value, activePriceList: activePriceList.value, cpfNota: cpfNota.value };
    const payload = { created_by: userStore.user?.id, customer_name: selectedCustomer.value?.nome || 'Consumidor', order_number: nextOrderNumber.value, total_value: finalTotal.value, item_count: cartItemCount.value, draft_data: draftData };
    try {
        if (currentDraftId.value) { await supabase.from('cajuia_order_drafts').update(payload).eq('id', currentDraftId.value); appStore.showSnackbar('Rascunho atualizado!', 'success'); } 
        else { const { data } = await supabase.from('cajuia_order_drafts').insert(payload).select('id').single(); if (data) currentDraftId.value = data.id; appStore.showSnackbar('Novo rascunho salvo!', 'success'); }
        fetchDrafts();
    } catch(e) { console.error(e); appStore.showSnackbar('Erro ao salvar rascunho.', 'error'); }
}
const fetchDrafts = async () => { isLoadingDrafts.value = true; try { const { data, count } = await supabase.from('cajuia_order_drafts').select('*', { count: 'exact' }).order('created_at', { ascending: false }); draftsList.value = data || []; draftsCount.value = count || 0; } catch(e) {} finally { isLoadingDrafts.value = false; } }
const openDraftsModal = () => { fetchDrafts(); showDraftsModal.value = true; }
const loadDraft = (draft: any) => {
    if(cart.value.length > 0 && currentDraftId.value !== draft.id) { if(!confirm('Substituir carrinho atual?')) return; }
    currentDraftId.value = draft.id;
    const data = draft.draft_data;
    if(data) { cart.value = data.cart || []; selectedCustomer.value = data.client || null; payments.value = data.payments || []; discountType.value = data.discount?.type || 'money'; discountValue.value = data.discount?.value || 0; installments.value = data.installments || 1; orderNotes.value = data.notes || ''; activePriceList.value = data.activePriceList || null; cpfNota.value = data.cpfNota || ''; hasSelectedPriceList.value = true; if(data.activePriceList) recalcCartPrices(); }
    showDraftsModal.value = false; appStore.showSnackbar('Rascunho carregado!', 'info');
}
const deleteDraft = async (id: string) => { if(!confirm('Excluir?')) return; try { await supabase.from('cajuia_order_drafts').delete().eq('id', id); fetchDrafts(); if(currentDraftId.value === id) currentDraftId.value = null; appStore.showSnackbar('Excluído.', 'success'); } catch(e) { appStore.showSnackbar('Erro ao excluir.', 'error'); } }

const handleClientCreated = (c: Client) => { selectedCustomer.value = c; showClientModal.value = false; }
const getFormattedPaymentText = () => { if (payments.value.length > 0) { return payments.value.map(p => `${p.method.nome}: ${formatCurrency(p.amount)}`).join(' | '); } if (selectedPaymentMethod.value) { return `${selectedPaymentMethod.value.nome}: ${formatCurrency(finalTotal.value)}`; } return 'Dinheiro'; }

// --- ROMANEIO (PREVIEW) ---
const handleRomaneio = async () => {
    if (cart.value.length === 0) { appStore.showSnackbar('Carrinho vazio.', 'warning'); return; }
    await fetchNextOrderNumber();
    const paymentText = getFormattedPaymentText();
    try {
        await generateOrderReceipt(
            'PREVIEW',
            Number(nextOrderNumber.value),
            selectedCustomer.value || { nome: 'Consumidor', id: 0 },
            cart.value,
            paymentText,
            finalTotal.value,
            { cpfNota: cpfNota.value, discount: discountAmount.value, change: remainingAmount.value < 0 ? Math.abs(remainingAmount.value) : 0 },
            printFormat.value // Usa o formato selecionado
        );
    } catch (e) { console.error(e); appStore.showSnackbar('Erro ao gerar romaneio.', 'error'); }
}

const submitCajuiaOrder = async () => {
  if (!isOrderValid.value) { if(!hasSelectedPriceList.value) appStore.showSnackbar('Selecione Tabela!', 'error'); return; }
  if (hasPixPayment.value && generatePixQr.value && !isPixConfirmed.value) { await handlePixGeneration(); return; }
  await finalizeSaleToERP();
}

const handlePixGeneration = async () => {
    isSubmitting.value = true;
    try {
        const clientIdentity = selectedCustomer.value?.cpf_cnpj || cpfNota.value;
        if (!clientIdentity || clientIdentity.length < 11) throw new Error('Para Pix Cora, é necessário CPF/CNPJ válido do cliente.');
        let pixAmount = payments.value.length > 0 ? payments.value.filter(p => p.method.nome.toLowerCase().includes('pix')).reduce((sum, p) => sum + p.amount, 0) : finalTotal.value;
        if (pixAmount <= 0) throw new Error('Nenhum valor de Pix encontrado.');
        currentPixAmount.value = pixAmount;
        const result = await coraApi.generatePix({ amount: Math.round(pixAmount * 100), code: `PDV-${Date.now()}`, customer: { name: selectedCustomer.value?.nome || 'Cliente Balcão', identity: clientIdentity } });
        pixData.value = { imagem: result.qrCodeUrl, copiaCola: result.emv };
        showPixModal.value = true;
        if (result.id) startPixPolling(result.id);
    } catch (e: any) { console.error(e); appStore.showSnackbar(`Erro Pix Cora: ${e.message}`, 'error'); } finally { isSubmitting.value = false; }
}

const finalizeSaleToERP = async () => {
  isSubmitting.value = true;
  try {
      const finalPayments = payments.value.length > 0 ? [...payments.value] : [{ method: selectedPaymentMethod.value!, amount: finalTotal.value }];
      const surchargeMultiplier = (cardFeeAmount.value > 0) ? 1 + (Number(cardFeePercentage.value) / 100) : 1;
      let totalDiscountVal = 0; if (subtotal.value > 0 && discountValue.value > 0) { totalDiscountVal = discountType.value === 'percent' ? subtotal.value * (Number(discountValue.value) / 100) : Number(discountValue.value); }
      const totalCartValue = subtotal.value; let remainingDiscount = totalDiscountVal;

      const erpItems: BomControleSaleItem[] = cart.value.map((item, index) => {
          const basePriceWithFee = item.unit_price * surchargeMultiplier;
          let lineTotalDiscount = 0;
          if (totalDiscountVal > 0 && totalCartValue > 0) { const ratio = item.total_price / totalCartValue; lineTotalDiscount = index === cart.value.length - 1 ? remainingDiscount : Math.round((totalDiscountVal * ratio) * 100) / 100; remainingDiscount -= lineTotalDiscount; }
          const itemTotalWithFee = (item.quantity * basePriceWithFee); if(lineTotalDiscount > itemTotalWithFee) lineTotalDiscount = itemTotalWithFee;
          let unitDiscount = (item.quantity > 0) ? Math.round((lineTotalDiscount / item.quantity) * 100) / 100 : 0;
          return { IdProduto: Number(item.gestaoclick_id), Quantidade: item.quantity, ValorUnitario: Number((basePriceWithFee - unitDiscount).toFixed(2)), ValorDesconto: 0 };
      })

      const paymentsInfo = finalPayments.map(p => `${p.method.nome}: ${formatCurrency(p.amount)}`).join(' + ');
      const finalObs = `PDV Cajuia | ${paymentsInfo} | ${orderNotes.value}`;
      const paymentPayload = { Outros: { Nome: 'Outros' } };
      const salePayload: any = { IdEmpresa: 2, IdCliente: selectedCustomer.value!.id, IdConta: 3, Data: format(new Date(), 'yyyy-MM-dd HH:mm:ss'), Itens: erpItems, Observacoes: finalObs, PrimeiroVencimento: format(new Date(), 'yyyy-MM-dd HH:mm:ss'), QuatidadeParcelas: 0, FormaPagamento: paymentPayload, MovimentarEstoque: true };

      const apiResponse = await createSaleBC(salePayload);
      const saleId = (typeof apiResponse === 'object') ? (apiResponse.Id || apiResponse.Data || apiResponse.IdVenda) : apiResponse;

      const mainPayment = finalPayments.reduce((p, c) => (p.amount > c.amount) ? p : c);
      const rpcData = { p_vendedor_id: userStore.user.id, p_customer_id: String(selectedCustomer.value!.id), p_customer_name: selectedCustomer.value!.nome, p_total_value: finalTotal.value, p_payment_method: mainPayment.method.nome, p_gestaoclick_sale_id: String(saleId), p_order_items: cart.value.map(i => ({ product_id: i.product_id, product_name: i.product_name, quantity: i.quantity, unit_price: i.unit_price, total_price: i.total_price })) };
      const { data: orderId, error } = await supabase.rpc('create_cajuia_order', rpcData); if(error) throw error;

      await generateReceivablesFromOrder(orderId, Number(nextOrderNumber.value), selectedCustomer.value, finalPayments, installments.value, firstDueDate.value, enableCardFee.value ? Number(cardFeePercentage.value) : 0);
      const totalCash = finalPayments.filter(p => p.method.nome.toLowerCase().includes('dinheiro')).reduce((sum, p) => sum + p.amount, 0);
      if (totalCash > 0) await cashStore.registerMovement('sale_cash', totalCash, `Venda #${nextOrderNumber.value}`, orderId);

      if(currentDraftId.value) { await supabase.from('cajuia_order_drafts').delete().eq('id', currentDraftId.value); currentDraftId.value = null; fetchDrafts(); }

      createdOrderId.value = orderId; createdOrderNumber.value = Number(nextOrderNumber.value); lastSoldItems.value = [...cart.value]; lastPaymentText.value = paymentsInfo; lastSoldTotal.value = finalTotal.value; lastSoldCustomer.value = selectedCustomer.value;
      lastDiscount.value = discountAmount.value; lastChange.value = remainingAmount.value < 0 ? Math.abs(remainingAmount.value) : 0;

      showSuccessModal.value = true; resetFormState();
  } catch (e: any) { console.error(e); appStore.showSnackbar(`Erro ao finalizar: ${e.message}`, 'error'); } finally { isSubmitting.value = false; }
}

const startPixPolling = (saleId: number) => {
    if (pixPollingInterval) clearInterval(pixPollingInterval);
    pixPollingInterval = setInterval(async () => {
        const status = await getSaleStatusBC(saleId);
        if (status && (status.Situacao === 'Pago' || status.Situacao === 'Concluido' || status.Quitado === true)) { appStore.showSnackbar('Pagamento Pix confirmado!', 'success'); closePixModal(); finishOrderProcess(); }
    }, 3000);
}
const closePixModal = () => { showPixModal.value = false; if (pixPollingInterval) clearInterval(pixPollingInterval); }
const manualConfirmPix = () => { if(confirm("Confirmar que o cliente pagou?")) { closePixModal(); finishOrderProcess(); } }
const copyPixCode = () => { navigator.clipboard.writeText(pixData.value.copiaCola); appStore.showSnackbar('Código Copia e Cola copiado!', 'info'); }
const finishOrderProcess = () => { showSuccessModal.value = true; resetFormState(); fetchNextOrderNumber(); }
const resetFormState = () => { cart.value = []; payments.value = []; discountValue.value = 0; orderNotes.value = ''; installments.value = 1; firstDueDate.value = format(new Date(), 'yyyy-MM-dd'); currentDraftId.value = null; hasSelectedPriceList.value = false; enableCardFee.value = true; paymentAmountInput.value = 0; cpfNota.value = ''; activeTab.value = 'items'; }

const handleGenerateReceipt = async () => {
    if(!createdOrderId.value) return;
    await generateOrderReceipt(createdOrderId.value, createdOrderNumber.value || 0, lastSoldCustomer.value || { nome: 'Consumidor', id: 0 }, lastSoldItems.value, lastPaymentText.value, lastSoldTotal.value, { cpfNota: lastCpfNota.value, discount: lastDiscount.value, change: lastChange.value }, printFormat.value);
}

const resetForm = () => { showSuccessModal.value = false; selectedCustomer.value = null; clientSearch.value = ''
    resetFormState(); fetchData(); 
}

const handleSessionOpened = () => { appStore.showSnackbar('Caixa aberto com sucesso!', 'success'); }
const handleSessionClosed = (closedSession: any) => { 
    try {
        const doc = new jsPDF(); const today = new Date();
        doc.setFillColor(30, 30, 30); doc.rect(0, 0, 210, 40, 'F'); doc.setTextColor(255, 255, 255); doc.setFontSize(18); doc.setFont('helvetica', 'bold'); doc.text('RELATÓRIO DE FECHAMENTO (Z)', 14, 20); doc.setFontSize(10); doc.setFont('helvetica', 'normal'); doc.text(`Sessão ID: ${closedSession.id.split('-')[0]}...`, 14, 28); doc.text(`Data: ${format(today, "dd/MM/yyyy HH:mm")}`, 150, 20, { align: 'right' }); doc.text(`Operador: ${userStore.user?.email || '---'}`, 150, 28, { align: 'right' });
        let y = 50; doc.setTextColor(0,0,0); doc.setFontSize(12); doc.setFont('helvetica', 'bold'); doc.text("Resumo Financeiro", 14, y); y += 10;
        const data = [['Saldo Inicial', formatCurrency(closedSession.initial_balance)], ['Saldo Final Calculado', formatCurrency(closedSession.final_balance_system)], ['Saldo Informado', formatCurrency(closedSession.final_balance_user)], ['Diferença', formatCurrency(closedSession.difference)]];
        autoTable(doc, { startY: y, head: [['Descrição', 'Valor']], body: data, theme: 'grid', headStyles: { fillColor: [50, 50, 50] }, columnStyles: { 1: { halign: 'right', fontStyle: 'bold' } } });
        y = (doc as any).lastAutoTable.finalY + 20; doc.setFontSize(10); if(closedSession.difference < 0) { doc.setTextColor(200, 0, 0); doc.text(`Quebra de caixa: ${formatCurrency(closedSession.difference)}`, 14, y); } else { doc.setTextColor(0, 150, 0); doc.text("Caixa OK", 14, y); }
        doc.save(`Fechamento_Z_${format(today, 'yyyyMMdd_HHmm')}.pdf`);
        cart.value = []; selectedCustomer.value = null; hasSelectedPriceList.value = false; activePriceList.value = null; window.location.reload();
    } catch (e) { console.error("Erro Relatório Z:", e); appStore.showSnackbar('Erro PDF Z.', 'error'); }
}

const getCartQuantity = (p: CajuiaProduct) => cart.value.find(i => i.product_id === p.id)?.quantity || 0
const getStockColor = (q: number) => q <= 0 ? 'error' : (q < 5 ? 'warning' : 'success')
const formatCurrency = (v: number) => new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(v)

onMounted(async () => {
    await cashStore.checkActiveSession(); fetchData(); fetchNextOrderNumber(); window.addEventListener('keydown', handleGlobalKeydown); clockInterval = setInterval(() => realTimeClock.value = format(new Date(), 'HH:mm:ss'), 1000);
    paymentMethods.value = [{ nome: 'Dinheiro', categoriaId: 1, contaId: 3 }, { nome: 'PIX', categoriaId: 1, contaId: 3 }, { nome: 'Boleto', categoriaId: 1, contaId: 3 }, { nome: 'Cartão de Crédito', categoriaId: 1, contaId: 3 }, { nome: 'Cartão de Débito', categoriaId: 1, contaId: 3 }];
})
onUnmounted(() => { window.removeEventListener('keydown', handleGlobalKeydown); clearInterval(clockInterval); if(pixPollingInterval) clearInterval(pixPollingInterval); })
</script>

<style scoped lang="scss">
.pdv-container { height: 100vh; width: 100vw; overflow: hidden; }
.bg-animated-image { background: #12121200; position: relative; z-index: 1; }
.background-overlay { position: absolute; inset: 0; background: rgba(10, 10, 15, 0.5); z-index: -1; }
.content-wrapper { position: relative; z-index: 2; }
.glass-panel, .glass-modal { background: rgba(30, 30, 35, 0.6); backdrop-filter: blur(16px); border: 1px solid rgba(255, 255, 255, 0.08); box-shadow: 0 8px 32px rgba(0,0,0,0.3); }
.glass-dialog { backdrop-filter: blur(4px); }
.bg-glass-header { background: rgba(255, 255, 255, 0.03); }
.bg-glass-body-gradient { background: linear-gradient(to bottom, rgba(0,0,0,0.1), rgba(0,0,0,0.3)); }
.bg-glass-footer { background: rgba(25, 25, 30, 0.85); backdrop-filter: blur(20px); }
.glass-menu { background: rgba(30, 30, 35, 0.95) !important; backdrop-filter: blur(10px); }
.bg-glass-dark { background: rgba(0,0,0,0.4); backdrop-filter: blur(8px); }
.glass-product-card { background: rgba(255, 255, 255, 0.03) !important; border: 1px solid rgba(255, 255, 255, 0.05); cursor: pointer; transition: all 0.4s cubic-bezier(0.4, 0, 0.2, 1); &:hover { transform: translateY(-8px); border-color: rgba(var(--v-theme-primary), 0.5); box-shadow: 0 15px 40px rgba(0,0,0,0.5); .bg-glass-card-body { background: linear-gradient(to top, rgba(var(--v-theme-primary), 0.1), rgba(30,30,35,0.6)); } .add-btn-circle { transform: scale(1.1); } } }
.bg-glass-card-body { background: linear-gradient(to top, rgba(30,30,35,0.95), rgba(30,30,35,0.5)); transition: background 0.3s; }
.product-image-wrapper { overflow: hidden; height: 180px; width: 100%; }
.scale-110 { transform: scale(1.1); }
.cart-badge { position: absolute; top: 10px; right: 10px; z-index: 10; }
.discount-ribbon { position: absolute; top: 10px; left: 0; z-index: 10; filter: drop-shadow(0 2px 4px rgba(0,0,0,0.5)); }
.absolute-bottom-gradient { background: linear-gradient(to top, rgba(0,0,0,0.8), transparent); }
.add-btn-circle { width: 32px; height: 32px; }
.h-16 { height: 16px; } .h-24 { height: 24px; }
.glass-input :deep(.v-field) { border-radius: 10px !important; border: 1px solid rgba(255,255,255,0.1); color: white !important; font-size: 0.85rem; }
.glass-input.centered-input :deep(input) { text-align: center; }
.glass-chip { background: rgba(255,255,255,0.05); border-color: rgba(255,255,255,0.1) !important; }
.glass-well { background: rgba(0,0,0,0.3); border: 1px solid rgba(255,255,255,0.05); }
.glass-toggle { background: rgba(0,0,0,0.3) !important; border: 1px solid rgba(255,255,255,0.1); }
.glass-btn-icon { background: rgba(255, 255, 255, 0.05); border-radius: 8px; }
.icon-box-lg { width: 56px; height: 56px; }
.gap-6 { gap: 24px; }
.status-card-active { background: linear-gradient(90deg, rgba(0, 230, 118, 0.15), rgba(0, 230, 118, 0.05)); border: 1px solid rgba(0, 230, 118, 0.3); border-left: 4px solid #00e676; }
.border-l-4-success { border-left-width: 4px !important; border-left-style: solid; border-left-color: #00e676; }
.text-4xl { font-size: 2.5rem; line-height: 1; }
.text-white-70 { color: rgba(255, 255, 255, 0.7) !important; }
.text-green-lighten-4 { color: #b9f6ca !important; }
.glass-input.copy-field :deep(.v-field__input) { color: #81c784 !important; font-weight: bold; }
@keyframes ping { 75%, 100% { transform: scale(2); opacity: 0; } }
.z-10 { z-index: 10; position: relative; }
.filter-drop-shadow { filter: drop-shadow(0 10px 20px rgba(0,0,0,0.15)); }
.bg-white-03 { background: rgba(255,255,255,0.03); }
.bg-black-80 { background: rgba(0,0,0,0.8); }
.loading-pulse { width: 64px; height: 64px; background: #e0e0e0; border-radius: 12px; animation: pulse-gray 1.5s infinite; }
@keyframes pulse-gray { 0% { opacity: 0.5; } 50% { opacity: 1; } 100% { opacity: 0.5; } }
.shadow-lg { box-shadow: 0 10px 30px rgba(0,0,0,0.4); }
.shadow-glow-primary { box-shadow: 0 0 20px rgba(var(--v-theme-primary), 0.4); }
.shadow-glow-success { box-shadow: 0 0 20px rgba(var(--v-theme-success), 0.4); }
.shadow-glow-warning { box-shadow: 0 0 10px rgba(var(--v-theme-warning), 0.5); }
.text-shadow { text-shadow: 0 2px 4px rgba(0,0,0,0.5); }
.bg-gradient-primary { background: linear-gradient(135deg, rgb(var(--v-theme-primary)), #1565c0); }
.bg-gradient-success { background: linear-gradient(135deg, #00c853, #006025); }
.icon-circle { width: 40px; height: 40px; border-radius: 50%; display: flex; align-items: center; justify-content: center; }
.icon-circle-large { width: 80px; height: 80px; border-radius: 50%; display: flex; align-items: center; justify-content: center; }
.w-20 { width: 20px; } .h-20 { height: 20px; } .w-8 { width: 32px; }
.width-250 { width: 250px; } .min-w-0 { min-width: 0 !important; }
.text-white-50 { color: rgba(255,255,255,0.5) !important; }
.border-white-05 { border-color: rgba(255,255,255,0.05) !important; }
.border-white-10 { border-color: rgba(255,255,255,0.1) !important; }
.border-white-20 { border-color: rgba(255,255,255,0.2) !important; }
.bg-primary-10 { background: rgba(var(--v-theme-primary), 0.15); }
.bg-black-20 { background: rgba(0,0,0,0.2); }
.bg-black-50 { background: rgba(0,0,0,0.5); }
.bg-white-05 { background: rgba(255,255,255,0.05); }
.scale-in-enter-active { animation: scale-in 0.4s cubic-bezier(0.25, 0.8, 0.25, 1); }
.scale-in-leave-active { animation: scale-in 0.3s reverse; }
@keyframes scale-in { 0% { opacity: 0; transform: scale(0.8); } 100% { opacity: 1; transform: scale(1); } }
.pulsing-animation { animation: pulse-shadow 7s infinite; }
@keyframes pulse-shadow { 0% { box-shadow: 0 0 0 0 rgba(76, 175, 79, 0.281); } 70% { box-shadow: 0 0 0 20px rgba(76, 175, 80, 0); } 100% { box-shadow: 0 0 0 0 rgba(76, 175, 80, 0); } }
.animate-pulse-error { animation: pulse-error 1.5s infinite; }
@keyframes pulse-error { 0% { box-shadow: 0 0 0 0 rgba(244, 67, 54, 0.4); } 70% { box-shadow: 0 0 0 10px rgba(244, 67, 54, 0); } 100% { box-shadow: 0 0 0 0 rgba(244, 67, 54, 0); } }
.status-dot { width: 8px; height: 8px; border-radius: 50%; }
.status-dot.success { background-color: #00e676; box-shadow: 0 0 8px rgba(0, 230, 118, 0.5); }
.status-dot.error { background-color: #ff5252; box-shadow: 0 0 8px rgba(255, 82, 82, 0.5); }
.product-grid-gap { gap: 16px; }
.custom-scrollbar::-webkit-scrollbar { width: 5px; }
.custom-scrollbar::-webkit-scrollbar-track { background: transparent; }
.custom-scrollbar::-webkit-scrollbar-thumb { background: rgba(255, 255, 255, 0.2); border-radius: 3px; }
.hide-scrollbar::-webkit-scrollbar { display: none; }
.scale-06 { transform: scale(0.6); transform-origin: right center; }
.lh-1 { line-height: 1; }
.ml-n2 { margin-left: -8px; }
.fade-transition { animation: fadeIn 0.3s ease; }
@keyframes fadeIn { from { opacity: 0; transform: translateY(5px); } to { opacity: 1; transform: translateY(0); } }
</style>