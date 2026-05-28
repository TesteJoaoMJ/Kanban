<template>
  <div
    class="new-order-page d-flex flex-column relative"
    :class="[
      pageThemeClass,
      mobile ? 'h-auto overflow-y-auto' : 'fill-height overflow-hidden'
    ]"
  >

    <div v-if="themeStore.currentMode !== 'light'" class="background-carousel-wrapper">
        <v-carousel cycle height="100%" hide-delimiters :show-arrows="false" interval="15000" class="fill-height">
            <v-carousel-item src="@/assets/1.jpg" cover></v-carousel-item>
            <v-carousel-item src="@/assets/2.jpg" cover></v-carousel-item>
        </v-carousel>
        <div class="background-overlay"></div>
    </div>

    <div v-if="isCheckingSession" class="fill-height absolute w-100 h-100 z-50 d-flex align-center justify-center relative z-index-top" :class="pageThemeClass">
       <div class="d-flex flex-column align-center gap-3">
          <v-progress-circular indeterminate color="error" size="64" width="4"></v-progress-circular>
          <span class="text-caption text-uppercase letter-spacing-1 font-weight-black" :class="textSecondaryClass">Sincronizando PDV...</span>
       </div>
    </div>

    <div v-else-if="shouldBlockScreen" class="content-wrapper d-flex flex-column fill-height z-10 relative">
        <div
          class="header-bar px-6 py-4 d-flex align-center justify-space-between flex-shrink-0"
          :class="isLight ? 'bg-white border-b border-grey-lighten-2 shadow-sm' : 'bg-glass-header border-bottom-white-05'"
        >
          <div class="d-flex flex-column">
            <div class="breadcrumb text-caption">
              <span class="opacity-70">Comercial</span>
              <span class="mx-2 opacity-50">></span>
              <span class="font-weight-bold">Ponto de Venda</span>
            </div>
            <div class="text-h6 font-weight-black tracking-tight leading-none mt-1" :class="textPrimaryClass">
              Seleção de Unidade
            </div>
          </div>
           <div class="d-flex align-center" style="gap: 10px;">
             <v-btn
                variant="outlined"
                class="btn-rect"
                height="40"
                prepend-icon="mdi-arrow-left"
                :color="isLight ? 'grey-darken-2' : 'white'"
                @click="$router.push({ name: 'Hub' })"
             >
                Voltar ao Hub
             </v-btn>
          </div>
        </div>

        <div class="px-6 pt-4 pb-0 flex-shrink-0">
            <v-row>
              <v-col cols="12" sm="4" v-for="(kpi, idx) in storeKpis" :key="idx">
                <v-card class="kpi-card kpi-rect bg-gradient-custom hover-elevate py-3 px-4" :class="kpi.gradient" v-ripple elevation="2">
                  <div class="kpi-bg-icon"><v-icon>{{ kpi.icon }}</v-icon></div>
                  <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                    <div class="d-flex align-center" style="gap: 8px;">
                      <v-icon size="18" class="opacity-80">{{ kpi.icon }}</v-icon>
                      <span class="kpi-label">{{ kpi.label }}</span>
                    </div>
                    <div class="kpi-number-group my-1">
                      <span v-if="kpi.isMoney" class="text-body-2 font-weight-medium mr-1 opacity-70">R$</span>
                      <span class="kpi-value">{{ kpi.value }}</span>
                    </div>
                    <div class="kpi-footer mt-1 opacity-80 text-[10px] font-weight-bold uppercase">{{ kpi.footer }}</div>
                  </div>
                </v-card>
              </v-col>
            </v-row>
        </div>

        <div class="px-6 pt-4 pb-2 flex-shrink-0">
            <div class="controls-bar d-flex align-center justify-space-between" :class="isLight ? 'controls-light' : 'controls-dark'">
               <div class="d-flex align-center flex-wrap" style="gap: 10px;">
                <div class="search-wrap d-flex align-center" :class="isLight ? 'search-light' : 'search-dark'">
                  <v-icon :color="isLight ? 'grey-darken-1' : 'white-70'">mdi-magnify</v-icon>
                  <input
                    v-model="searchStore"
                    type="text"
                    placeholder="Pesquisar unidade, cidade..."
                    class="clean-input flex-grow-1"
                  />
                </div>
                <v-chip color="error" variant="outlined" label class="font-weight-bold px-3 border-dashed" style="height: 40px;">
                    {{ availableStores.length }} Unidades Disponíveis
                </v-chip>
              </div>
            </div>
        </div>

        <div class="flex-grow-1 px-6 pb-2 overflow-hidden d-flex flex-column">
             <v-card class="flex-grow-1 d-flex flex-column rounded-0 border-thin overflow-hidden" :class="isLight ? 'bg-white shadow-sm' : 'glass-card border-white-05'" :elevation="0">
              <div class="grid-scroll flex-grow-1 overflow-y-auto custom-scroll">
                 <div class="grid-header sticky-head" :class="[isLight ? 'grid-surface-light' : 'grid-surface-dark', 'grid-store-layout']">
                  <div class="cell center header-text">Status</div>
                  <div class="cell center header-text">ID</div>
                  <div class="cell header-text">Nome da Unidade</div>
                  <div class="cell header-text">Localização / Endereço</div>
                  <div class="cell header-text">Operador Atual</div>
                  <div class="cell right header-text">Vendas Hoje</div>
                  <div class="cell center header-text">Ação</div>
                </div>

                <div v-for="store in filteredStores" :key="store.id" class="grid-row" :class="[isLight ? 'grid-row-light' : 'grid-row-dark','grid-store-layout']" @click="handleAdminStoreSelection(store)">
                    <div class="cell center">
                        <div class="status-indicator" :class="store.active_session_user ? 'bg-success pulse' : 'bg-grey'"></div>
                    </div>
                    <div class="cell center">
                        <span class="pill-ref">{{ String(store.id).substring(0,4).toUpperCase() }}</span>
                    </div>
                    <div class="cell"><span class="list-text-11 font-weight-black text-uppercase">{{ store.name }}</span></div>
                    <div class="cell"><div class="d-flex align-center opacity-70"><v-icon size="14" class="mr-1">mdi-map-marker-outline</v-icon><span class="list-text-10">{{ store.address || 'Matriz' }}</span></div></div>
                    <div class="cell"><span v-if="store.active_session_user" class="solid-chip chip-info">{{ store.active_session_user }}</span><span v-else class="list-text-10 opacity-50 font-italic">Fechado</span></div>
                    <div class="cell right"><span class="list-text-11 font-mono font-weight-black" :class="adminStoreStats[store.id] > 0 ? 'text-success' : 'opacity-50'">{{ formatCurrency(adminStoreStats[store.id] || 0) }}</span></div>
                    <div class="cell center"><v-btn size="small" variant="flat" color="error" class="btn-rect font-weight-bold" height="28" @click.stop="handleAdminStoreSelection(store)">ACESSAR</v-btn></div>
                </div>
              </div>
            </v-card>
        </div>
    </div>

    <div v-else-if="!isSessionOpen && canMoveCash" class="fill-height absolute w-100 h-100 z-40 d-flex align-center justify-center relative overflow-hidden" :class="pageThemeClass">
        <div v-if="!isLight" class="absolute w-100 h-100 bg-black opacity-60 backdrop-blur-md z-0"></div>
        <v-card width="400" class="rounded-xl pa-6 z-10 relative" :class="openingCardClass" :elevation="isLight ? 4 : 24">
            <div class="d-flex flex-column align-center text-center mb-6">
                <div class="icon-circle-lg mb-4" :class="isLight ? 'bg-primary-lighten-5 border-primary-lighten-4' : 'bg-primary-opacity border-primary-opacity'">
                    <v-icon size="40" :color="isLight ? 'primary' : 'white'">mdi-store-clock-outline</v-icon>
                </div>
                <h2 class="text-h5 font-weight-black mb-2" :class="textPrimaryClass">Ponto de Venda</h2>
                <p class="text-caption" :class="textSecondaryClass">
                    Olá, <strong class="text-primary">{{ userStore.profile?.full_name?.split(' ')[0] }}</strong>.<br>
                    Confira o fundo de troco para iniciar.
                </p>
                <div class="mt-2 text-[10px] uppercase font-weight-bold tracking-widest px-2 py-1 rounded" :class="isLight ? 'bg-grey-lighten-3 text-grey-darken-2' : 'bg-white-05 text-white-50'">
                    Unidade: {{ userStore.activeStoreName }}
                </div>
            </div>
            <div class="d-flex flex-column gap-4">
                 <v-text-field v-model="quickStartAmount" label="Fundo de Troco (R$)" prefix="R$" type="number" variant="outlined" :bg-color="inputBgColor" color="primary" :class="['font-weight-bold', isLight ? 'text-grey-darken-3' : 'text-white glass-input']" hide-details autofocus @keyup.enter="handleQuickOpen"></v-text-field>
                 <v-btn block color="primary" height="48" class="font-weight-bold text-uppercase letter-spacing-1" :class="{'shadow-glow': !isLight}" :loading="cashStore.isLoading" @click="handleQuickOpen">Abrir Caixa <v-icon end>mdi-arrow-right</v-icon></v-btn>
                 <v-btn v-if="userStore.isAdmin" variant="text" size="small" :class="textSecondaryClass" @click="resetAdminStore"><v-icon start size="14">mdi-swap-horizontal</v-icon> Trocar Unidade</v-btn>
            </div>
        </v-card>
    </div>

    <div
        v-else
        class="d-flex flex-column flex-grow-1 relative z-10"
        :class="[pageThemeClass, mobile ? 'h-auto' : 'h-100']"
    >
        <header v-if="!orderCreatedSuccess" class="app-header px-3 px-sm-4 py-2 d-flex flex-column flex-shrink-0 border-b gap-2" :class="headerThemeClass">
            <div class="d-flex align-center justify-space-between">
                <div class="d-flex align-center gap-1 text-caption text-medium-emphasis">
                    <v-icon size="18" class="d-sm-none cursor-pointer" @click="$router.push('/hub')">mdi-arrow-left</v-icon>

                    <v-icon size="14" class="d-none d-sm-inline">mdi-home-outline</v-icon>
                    <span class="cursor-pointer hover:text-primary d-none d-sm-inline" @click="$router.push('/hub')">Home</span>
                    <v-icon size="12" class="d-none d-sm-inline">mdi-chevron-right</v-icon>
                    <span class="d-none d-sm-inline">Vendas</span>
                    <v-icon size="12" class="d-none d-sm-inline">mdi-chevron-right</v-icon>
                    <span class="text-high-emphasis font-weight-medium ml-1 ml-sm-0">{{ pageTitle }}</span>
                </div>
                <div class="d-flex align-center gap-2 text-caption">
                     <span class="text-medium-emphasis d-none d-sm-inline">Unidade:</span>
                     <span class="font-weight-bold text-high-emphasis d-flex align-center gap-1">
                         <v-icon size="14" color="primary">mdi-store</v-icon>
                         {{ mobile && userStore.activeStoreName ? userStore.activeStoreName.substring(0, 15) + (userStore.activeStoreName.length > 15 ? '...' : '') : userStore.activeStoreName }}
                     </span>
                     <v-divider vertical class="h-12 opacity-20 mx-2 d-none d-sm-block"></v-divider>
                     <div class="text-caption font-mono font-weight-medium text-medium-emphasis d-none d-sm-block">
                         {{ currentDate }} <span class="text-high-emphasis ml-1">{{ currentTime }}</span>
                     </div>
                </div>
            </div>

            <v-divider class="border-opacity-10"></v-divider>

            <div class="d-flex align-center justify-space-between flex-wrap" :style="mobile ? 'gap: 12px;' : ''">
                <div class="d-flex align-center flex-wrap" :class="mobile ? 'w-100 justify-space-between' : 'gap-4'">
                     <div class="d-flex align-center gap-2">
                        <div class="text-caption text-medium-emphasis text-uppercase font-weight-bold d-none d-sm-block">Pedido Nº</div>
                        <div v-if="loadingNextOrderNumber"><v-progress-circular indeterminate size="10" width="1" color="primary"></v-progress-circular></div>
                        <div v-else class="text-subtitle-2 font-weight-black font-mono text-primary bg-primary-opacity px-2 rounded">
                            <span v-if="mobile" class="text-[10px] opacity-70 mr-1">#</span>{{ String(currentOrderNumber).padStart(4, '0') }}
                        </div>
                     </div>
                     <v-divider vertical class="h-16 opacity-20 d-none d-sm-block"></v-divider>
                     <div class="d-flex align-center gap-2">
                        <div class="text-[10px] text-medium-emphasis text-uppercase font-weight-bold d-none d-sm-block">Entrega Prevista</div>
                        <v-icon size="16" class="d-sm-none text-success">mdi-truck-delivery</v-icon>
                        <div class="text-caption font-weight-bold text-success">{{ forecastDeliveryDate }}</div>
                     </div>
                     <template v-if="clientCreditInfo.limit > 0">
                         <v-divider vertical class="h-16 opacity-20 d-none d-sm-block"></v-divider>
                         <div class="d-flex align-center gap-1">
                            <div class="text-[10px] text-medium-emphasis text-uppercase font-weight-bold d-none d-sm-block">Crédito Loja</div>
                            <v-icon size="16" class="d-sm-none" :class="availableCredit > 0 ? 'text-purple' : 'text-error'">mdi-credit-card-outline</v-icon>
                            <div class="text-caption font-weight-bold" :class="availableCredit > 0 ? 'text-purple' : 'text-error'">
                                {{ formatCurrency(availableCredit) }}
                            </div>
                         </div>
                     </template>
                </div>

                <div class="d-flex align-center justify-end" :class="mobile ? 'w-100 gap-2' : 'gap-1'">
                     <v-btn
                         :size="mobile ? 'small' : 'small'"
                         :variant="mobile ? 'tonal' : 'text'"
                         :color="draftsList.length ? 'warning' : 'medium-emphasis'"
                         class="text-none"
                         :class="mobile ? 'flex-grow-1' : ''"
                         @click="openDraftsModal"
                     >
                         <v-icon :start="!mobile" size="16">mdi-folder-open</v-icon>
                         <span v-if="!mobile">Rascunhos ({{ draftsList.length }})</span>
                         <span v-else class="font-weight-bold ml-1">Rascunhos ({{ draftsList.length }})</span>
                     </v-btn>

                     <v-divider vertical class="h-16 opacity-20 mx-1 d-none d-sm-block"></v-divider>

                     <template v-if="canMoveCash">
                         <v-tooltip location="bottom" text="Suprimento">
                             <template v-slot:activator="{ props }">
                                 <v-btn v-bind="props" :icon="mobile" size="small" :variant="mobile ? 'tonal' : 'text'" color="success" class="text-none px-2" @click="openOperation('supply')">
                                     <v-icon :start="!mobile" size="16">mdi-cash-plus</v-icon> <span v-if="!mobile">Suprimento</span>
                                 </v-btn>
                             </template>
                         </v-tooltip>

                         <v-tooltip location="bottom" text="Sangria">
                             <template v-slot:activator="{ props }">
                                 <v-btn v-bind="props" :icon="mobile" size="small" :variant="mobile ? 'tonal' : 'text'" color="error" class="text-none px-2" @click="openOperation('bleed')">
                                     <v-icon :start="!mobile" size="16">mdi-cash-minus</v-icon> <span v-if="!mobile">Sangria</span>
                                 </v-btn>
                             </template>
                         </v-tooltip>
                     </template>

                     <v-divider vertical class="h-16 opacity-20 mx-1 d-none d-sm-block"></v-divider>

                     <v-tooltip location="bottom" text="Fechar Caixa" content-class="bg-black text-caption font-weight-bold">
                        <template v-slot:activator="{ props }">
                           <v-btn v-bind="props" icon size="small" variant="flat" color="error" :class="{'ml-1': !mobile}" @click="showCloseBoxModal = true">
                              <v-icon size="14">mdi-power</v-icon>
                           </v-btn>
                        </template>
                     </v-tooltip>
                </div>
            </div>
        </header>

        <v-expand-transition>
            <div v-if="showDraftAlert" class="floating-alert px-4 py-1 d-flex align-center justify-center gap-3 elevation-4">
                <v-icon color="warning" size="16">mdi-alert-circle-outline</v-icon>
                <span class="text-caption font-weight-medium">Rascunho não salvo encontrado.</span>
                <v-btn size="x-small" color="warning" variant="flat" class="font-weight-bold rounded-pill text-[10px]" @click="restoreAutoSave">Restaurar</v-btn>
                <v-btn size="x-small" variant="text" icon="mdi-close" density="compact" @click="clearAutoSave(false)"></v-btn>
            </div>
        </v-expand-transition>

        <v-expand-transition>
            <v-alert
              v-if="draftLoadError"
              type="warning"
              variant="tonal"
              closable
              class="mx-4 mt-2 mb-0 border-warning text-caption font-weight-bold"
              @click:close="draftLoadError = null"
            >
                {{ draftLoadError }}
            </v-alert>
        </v-expand-transition>

        <div
            v-if="!orderCreatedSuccess"
            class="custom-scrollbar"
            :class="[
                isLight ? 'bg-grey-lighten-5' : 'bg-background',
                mobile ? 'h-auto overflow-visible' : 'flex-grow-1 overflow-y-auto'
            ]"
        >
            <div class="d-flex flex-column gap-4 pa-4 w-100">

                <div class="w-100">
                    <OrderClientCard
                        v-model:customerId="orderHeader.customer_id"
                        v-model:vendedorId="orderHeader.vendedor_id"
                        :client-list="clientList"
                        :salespeople-list="salespeopleList"
                        :loading-salespeople="loadingData"
                        @create-client="handleCreateClientRequest"
                        @update:clientList="(list) => clientList = list"
                    />
                </div>

                <v-expand-transition>
                  <v-alert
                    v-if="isSelectedClientDelinquent"
                    type="error"
                    variant="tonal"
                    class="mt-3 border-error rounded-lg text-caption font-weight-bold"
                    icon="mdi-account-cancel"
                  >
                    <div class="d-flex flex-column">
                      <span class="text-body-2 font-weight-black">Pedido bloqueado por inadimplência</span>
                      <span>{{ selectedClientDelinquencyMessage }}</span>
                    </div>
                  </v-alert>
                </v-expand-transition>

                  <div class="w-100" :style="mobile ? 'height: auto;' : 'height: 75vh; min-height: 70px;'">
                      <OrderItemManager
                        ref="itemManagerRef"
                        v-model:items="orderItems"
                        :products="products"
                        :stock-items="stockItems"
                        :stamp-library="stampLibrary"
                        :loading-products="loadingData"
                        :design-tags="availableDesignTags"
                        class="h-100"
                      />
                  </div>

                <div class="w-100 mt-auto">
                    <div class="rounded-lg overflow-hidden border border-opacity-10 shadow-sm" :class="checkoutPanelClass">
                      <div class="pa-4 border-b border-opacity-10 flex-shrink-0 d-flex justify-space-between align-center" :class="checkoutHeaderClass">
                          <div class="d-flex align-center gap-3">
                            <div class="icon-box-sm rounded bg-primary-lighten-5 text-primary d-flex align-center justify-center">
                                <v-icon size="20">mdi-cash-register</v-icon>
                            </div>
                            <h3 class="text-subtitle-1 font-weight-bold" :class="textPrimaryClass">Pagamento & Fechamento</h3>
                          </div>

                          <div class="d-flex align-center gap-4">
                            <div class="d-flex flex-column align-end">
                                <div class="d-flex align-center gap-1 opacity-70 mb-1">
                                    <v-icon size="12">mdi-ruler</v-icon>
                                    <span class="text-[9px] font-weight-black uppercase letter-spacing-1">Metragem Total</span>
                                </div>
                                <div class="text-subtitle-2 font-weight-black font-mono bg-grey-lighten-3 px-2 py-1 rounded">
                                    {{ formatCurrency(totalOrderMeters, '', 2) }}m
                                </div>
                            </div>

                            <div class="bg-grey-lighten-1" style="width: 1px; height: 24px; opacity: 0.3;"></div>

                            <div class="text-right">
                                <span class="text-[9px] font-weight-black uppercase opacity-60 d-block mb-0 text-primary">Total do Pedido</span>
                                <span class="text-h5 font-weight-black lh-1" :class="textPrimaryClass">{{ formatCurrency(totalOrderValue) }}</span>
                            </div>
                          </div>
                      </div>

                        <div class="pa-4">
                           <OrderPaymentSummary
                            v-model:paymentDetails="paymentDetails"
                            v-model:orderHeader="orderHeader"
                            v-model:creditUsedValue="usedCreditValue"
                            :total-value="totalOrderValue"
                            :total-meters="totalOrderMeters"  :payment-methods="paymentMethods"
                            :is-saving="isSubmitting"
                            :is-valid="isValidOrder"
                            :is-generating-pdf="isGeneratingPdf"
                            :is-ready-for-delivery="false"
                            :hide-actions="false"
                            :available-credit="availableCredit"
                            @update:isValid="isPaymentValid = $event"
                        />

                           <div class="mt-3 pa-2 rounded border-thin d-flex align-center gap-2" :class="isLight ? 'bg-grey-lighten-4' : 'bg-surface-variant'">
                                <v-icon size="14" color="medium-emphasis">mdi-bank-transfer</v-icon>
                                <span class="text-caption font-weight-medium text-medium-emphasis">
                                    Conta Vinculada: <span class="text-high-emphasis">{{ bankAccountName }}</span>
                                </span>
                           </div>
                        </div>

                        <div class="pa-4 border-t border-opacity-10 d-flex flex-column gap-3" :class="isLight ? 'bg-white' : 'bg-surface'">

                            <div v-if="hasStockIssues" class="w-100">
                                <v-alert density="compact" type="warning" variant="tonal" class="text-caption font-weight-bold mb-0">
                                    <span class="d-flex align-center justify-center">
                                       <v-icon start size="16">mdi-alert-circle</v-icon>
                                       Falta de estoque detectada. Lançamento bloqueado.
                                    </span>
                                </v-alert>
                            </div>

                            <div class="d-flex flex-column flex-sm-row gap-3 w-100">
                                <v-btn
                                    variant="outlined"
                                    :color="draftSaveState === 'success' ? 'success' : 'medium-emphasis'"
                                    class="flex-grow-1 rounded-lg border-opacity-25"
                                    height="48"
                                    @click="saveDraft"
                                    :loading="draftSaveState === 'loading'"
                                    :disabled="isSavingDraft || (!orderHeader.customer_id && orderItems.length === 0)"
                                >
                                    <v-icon start>{{ draftSaveState === 'success' ? 'mdi-check' : 'mdi-content-save-outline' }}</v-icon>
                                    {{ draftSaveState === 'success' ? 'Salvo!' : (currentDraftId ? 'Atualizar Rascunho' : 'Salvar Rascunho') }}
                                </v-btn>

                                <v-btn
                                    height="48"
                                    color="success"
                                    variant="flat"
                                    class="font-weight-bold text-subtitle-1 rounded-lg shadow-soft"
                                    :class="mobile ? 'w-100' : 'flex-grow-1'"
                                    :loading="isSubmitting"
                                    :disabled="!isValidOrder || hasStockIssues || isSelectedClientDelinquent"
                                    @click="submitOrder"
                                    :style="mobile ? '' : 'flex-grow: 2;'"
                                >
                                    <div class="d-flex flex-column align-center lh-1">
                                        <span>LANÇAR PEDIDO</span>
                                        <span class="text-[9px] opacity-80 font-weight-regular mt-1 d-none d-sm-block">F12 PARA CONFIRMAR</span>
                                    </div>
                                    <v-icon end>mdi-check-circle</v-icon>
                                </v-btn>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="pb-6"></div>
            </div>
        </div>

        <div v-else-if="orderCreatedSuccess" class="fill-height d-flex align-center justify-center pa-4 fade-in relative z-20" :class="pageThemeClass">

           <v-card
                  class="rounded-xl elevation-24 border border-opacity-10 overflow-hidden d-flex flex-column flex-md-row"
                  :class="cardThemeClass"
                  max-width="1600"
                  width="100%"
                  style="min-height: 800px;"
              >
               <div class="d-flex flex-column pa-8 border-e border-opacity-10 relative overflow-hidden" :class="isLight ? 'bg-grey-lighten-5' : 'bg-surface-variant'" style="flex: 1; min-width: 320px;">

                   <div v-if="pixState.status === 'PAID'" class="particle-burst"></div>

                   <div class="d-flex align-center justify-center mb-6 relative z-10">
                        <div class="icon-circle-xl elevation-6 transition-all"
                             :class="pixState.status === 'PAID' ? 'bg-green-gradient scale-pop' : 'bg-primary-gradient'">
                            <v-icon size="64" color="white">{{ pixState.status === 'PAID' ? 'mdi-check-all' : 'mdi-check' }}</v-icon>
                        </div>
                   </div>

                   <div class="text-center mb-8 relative z-10">
                       <h2 class="text-h4 font-weight-black mb-1 tracking-tight" :class="textPrimaryClass">
                           {{ pixState.status === 'PAID' ? 'Pagamento Confirmado!' : 'Pedido Registrado' }}
                       </h2>
                       <div class="text-h5 font-weight-bold font-mono mb-2" :class="pixState.status === 'PAID' ? 'text-success' : 'text-primary'">
                           #{{ String(createdOrderNumber).padStart(4, '0') }}
                       </div>

                       <div v-if="pixState.status === 'PAID'" class="d-flex justify-center mt-4">
                           <div class="py-2 px-4 rounded-lg bg-green-lighten-5 border border-green-lighten-3 d-flex align-center gap-2">
                               <v-icon color="success" size="20">mdi-bank-check</v-icon>
                               <div class="d-flex flex-column text-left">
                                   <span class="text-[10px] font-weight-black text-uppercase text-green-darken-3">Status Financeiro</span>
                                   <span class="text-body-2 font-weight-bold text-green-darken-4">Dinheiro em Conta</span>
                               </div>
                           </div>
                       </div>
                       <p v-else class="text-body-2 text-medium-emphasis mt-2">
                           O pedido foi salvo. Aguardando processamento financeiro interno.
                       </p>
                   </div>

                   <div class="mt-auto d-flex flex-column gap-3 relative z-10">
                        <v-btn
                            block
                            size="x-large"
                            :color="pixState.status === 'PAID' ? 'success' : 'primary'"
                            variant="flat"
                            class="font-weight-black rounded-lg text-none shadow-soft"
                            @click="handleDownloadQuote"
                            :loading="isGeneratingPdf"
                        >
                            <v-icon start size="24">mdi-printer</v-icon>
                            Imprimir Pedido
                        </v-btn>

                        <v-btn
                            block
                            size="large"
                            variant="text"
                            class="font-weight-bold rounded-lg text-none opacity-70 hover:opacity-100"
                            @click="resetOrder(true)"
                        >
                            <v-icon start>mdi-plus</v-icon> Novo Pedido
                        </v-btn>
                   </div>
               </div>

               <div class="d-flex flex-column align-center justify-center pa-8 relative bg-white" style="flex: 1.5; min-width: 400px;">

                    <div v-if="pixState.loading" class="d-flex flex-column align-center text-center">
                        <v-progress-circular indeterminate color="primary" size="80" width="6"></v-progress-circular>
                        <h3 class="text-h6 mt-6 font-weight-bold text-primary">Gerando Cobrança Pix...</h3>
                        <p class="text-caption text-medium-emphasis">Conectando ao Banco Cora</p>
                    </div>

                    <div v-else-if="pixState.show && pixState.status !== 'PAID'" class="w-100 h-100 d-flex flex-column align-center animate-pop py-4">

                        <div class="text-center mb-2 flex-shrink-0">
                            <span class="text-overline font-weight-bold text-medium-emphasis d-block lh-1">TOTAL A PAGAR</span>
                            <div class="text-h3 font-weight-black text-primary lh-1 mt-1">{{ pixState.displayValue }}</div>
                        </div>

                        <div class="flex-grow-1 d-flex align-center justify-center w-100 relative my-2 overflow-hidden px-4">
                             <div class="pa-4 rounded-xl border-xl border-primary-lighten-4 bg-white shadow-lg relative d-flex align-center justify-center"
                                  style="width: 100%; height: 100%; max-height: 600px; max-width: 600px;">

                                 <div class="absolute-corner top-left" style="width: 40px; height: 40px; border-width: 6px 0 0 6px;"></div>
                                 <div class="absolute-corner top-right" style="width: 40px; height: 40px; border-width: 6px 6px 0 0;"></div>
                                 <div class="absolute-corner bottom-left" style="width: 40px; height: 40px; border-width: 0 0 6px 6px;"></div>
                                 <div class="absolute-corner bottom-right" style="width: 40px; height: 40px; border-width: 0 6px 6px 0;"></div>

                                 <img
                                      :src="pixState.qrCodeImage"
                                      style="width: 100%; height: 100%; object-fit: contain;"
                                      class="d-block"
                                  />
                             </div>
                        </div>

                        <div class="w-100 px-4 flex-shrink-0" style="max-width: 600px;">
                            <v-text-field
                                :model-value="pixState.copyPaste"
                                readonly
                                variant="outlined"
                                density="compact"
                                bg-color="grey-lighten-5"
                                hide-details
                                class="mb-2 font-mono text-caption font-weight-bold"
                                rounded="lg"
                            >
                                <template v-slot:append-inner>
                                    <v-btn
                                        color="primary"
                                        variant="text"
                                        size="small"
                                        class="text-none font-weight-bold px-2"
                                        @click="() => { navigator.clipboard.writeText(pixState.copyPaste); appStore.showSnackbar('Copiado!', 'success') }"
                                    >
                                        COPIAR
                                    </v-btn>
                                </template>
                            </v-text-field>

                            <div class="text-center pb-2">
                                <span class="text-caption font-weight-bold text-blue-darken-3 d-flex align-center justify-center gap-2">
                                    <v-progress-circular indeterminate color="blue" size="12" width="2"></v-progress-circular>
                                    Aguardando confirmação do banco...
                                </span>
                            </div>
                        </div>
                    </div>

                    <div v-else-if="pixState.status === 'PAID'" class="d-flex flex-column align-center justify-center h-100 text-center animate-pop">
                         <div class="icon-circle-lg bg-green-lighten-5 mb-6">
                             <v-icon size="48" color="success">mdi-cash-check</v-icon>
                         </div>
                         <h3 class="text-h5 font-weight-black text-grey-darken-3 mb-2">Transação Concluída</h3>
                         <p class="text-body-1 text-medium-emphasis mb-6 max-w-sm">
                             O pagamento de <strong>{{ pixState.displayValue }}</strong> foi identificado e conciliado automaticamente.
                         </p>

                         <div class="d-flex gap-4">
                             <div class="d-flex flex-column align-center pa-4 rounded bg-grey-lighten-5 min-w-[120px]">
                                 <span class="text-[10px] uppercase font-weight-bold text-medium-emphasis">Data</span>
                                 <span class="font-weight-bold">{{ currentDate }}</span>
                             </div>
                             <div class="d-flex flex-column align-center pa-4 rounded bg-grey-lighten-5 min-w-[120px]">
                                 <span class="text-[10px] uppercase font-weight-bold text-medium-emphasis">Hora</span>
                                 <span class="font-weight-bold">{{ currentTime }}</span>
                             </div>
                         </div>
                    </div>

                    <div v-else class="d-flex flex-column align-center justify-center opacity-40 h-100">
                        <img src="@/assets/logo.svg" width="120" class="mb-6 grayscale opacity-50" />
                        <div class="text-h6 font-weight-bold">Venda Finalizada</div>
                        <p class="text-caption">Nenhuma ação de pagamento digital pendente.</p>
                    </div>
               </div>

           </v-card>
        </div>
    </div>

    <MjCashOpeningModal v-model="showOpenBoxModal" @session-opened="refreshSession" />
    <MjCashClosingModal v-model="showCloseBoxModal" @session-closed="handleSessionClosed" />
    <MjCashOperationsModal v-model="showOperationsModal" :type="operationType" @operation-completed="refreshSession" />
    <ClientFormModal :show="showClientModal" @close="showClientModal = false" @client-created="handleClientCreated" />
    <DraftsListModal
        :show="showDraftsModal"
        :drafts="draftsList"
        :products="products"
        :client-list="clientList"
        :payment-methods="paymentMethods"
        @close="showDraftsModal = false"
        @load="loadDraft"
        @delete="deleteDraft"
    />

    <v-dialog v-model="showSessionEndedModal" max-width="400" persistent z-index="10000">
        <v-card class="text-center pa-6 rounded-xl" :class="cardThemeClass">
            <div class="icon-circle-lg bg-amber-lighten-5 text-amber mx-auto mb-4">
                 <v-icon size="40">mdi-lock-check</v-icon>
            </div>
            <h2 class="text-h6 font-weight-bold mb-4" :class="textPrimaryClass">Turno Encerrado</h2>
            <div class="pa-3 rounded border-thin mb-4 text-left" :class="isLight ? 'bg-grey-lighten-4' : 'bg-surface-variant'">
                <div class="d-flex justify-space-between mb-1">
                    <span class="text-caption opacity-70">Conferência</span>
                    <span class="text-body-2 font-weight-bold" :class="textPrimaryClass">{{ formatCurrency(lastClosedSession?.session?.final_balance_user || 0) }}</span>
                </div>
                <div class="d-flex justify-space-between">
                    <span class="text-caption opacity-70">Resultado</span>
                    <span class="text-caption font-weight-black text-uppercase" :class="getDiffColor(calculatedDifference)">
                        {{ getDiffLabel(calculatedDifference) }}
                    </span>
                </div>
            </div>
            <div class="d-flex flex-column gap-2">
                <v-btn color="warning" variant="flat" block class="font-weight-bold" prepend-icon="mdi-printer" @click="reprintZReport">Relatório Z</v-btn>
                <v-btn variant="text" block @click="showSessionEndedModal = false">Fechar</v-btn>
            </div>
        </v-card>
    </v-dialog>

    <SubmissionStatusModal
      v-model="showSubmittingModal"
      :status="submissionStatus"
      :user-message="userFriendlyMessage"
      :dev-message="programmerMessage"
      :client-name="orderHeader.customer_name"
      @close="handleSubmissionClose"
      @whatsapp="() => {}"
    />

  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, computed, onUnmounted, watch, reactive } from 'vue';
import { useUserStore } from '@/stores/user';
import { useMjCashSessionStore } from '@/stores/mjCashSession';
import { useAppStore } from '@/stores/app';
import { useThemeStore } from '@/stores/theme';
import { supabase } from '@/api/supabase';
import { useOrderPDF } from '@/composables/useOrderPDF';
import { useOrderSubmission } from '@/composables/useOrderSubmission';
import Shepherd from 'shepherd.js';
import { format, startOfDay, parseISO } from 'date-fns';
import { ptBR } from 'date-fns/locale';
import { useCashReport } from '@/composables/useCashReport';
import { useRoute } from 'vue-router';
import { useAuditLogger } from '@/composables/useAuditLogger';
import { coraApi } from '@/api/coraProxy';
import { useDisplay } from 'vuetify';

import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';

// Imports de Componentes
import OrderClientCard from './components/OrderClientCard.vue';
import OrderItemManager from './components/OrderItemManager.vue';
import OrderPaymentSummary from './components/OrderPaymentSummary.vue';
import SubmissionStatusModal from './components/SubmissionStatusModal.vue';
import MjCashOpeningModal from '@/components/sales/MjCashOpeningModal.vue';
import MjCashClosingModal from '@/components/sales/MjCashClosingModal.vue';
import ClientFormModal from '@/components/ClientFormModal.vue';
import DraftsListModal from '@/components/DraftsListModal.vue';
import MjCashOperationsModal from '@/components/sales/MjCashOperationsModal.vue';
import { useCompanyStore } from '@/stores/company'

const { mobile } = useDisplay();
const userStore = useUserStore();
const cashStore = useMjCashSessionStore();
const appStore = useAppStore();
const themeStore = useThemeStore();
const route = useRoute();
const { logSecureAction, logBusinessEvent } = useAuditLogger();

const { generateQuoteAndUploadPdf, isGeneratingPdf } = useOrderPDF();
const { generateClosingReport } = useCashReport();
const { submitLaunch, submissionStatus, showSubmittingModal, userFriendlyMessage, programmerMessage, createdOrderId } = useOrderSubmission();
const companyStore = useCompanyStore()

const orderContext = computed(() => (route.meta.orderContext as 'com_nota' | 'sem_nota') || 'com_nota');
const pageTitle = computed(() => orderContext.value === 'com_nota' ? 'Novo Pedido (C/ Nota)' : 'Novo Pedido (S/ Nota)');
const targetBankName = computed(() => orderContext.value === 'com_nota' ? 'Sicredi' : 'Cora');

// State Refs
const itemManagerRef = ref<any>(null);
const loadingData = ref(false);
const isSubmitting = ref(false);
const isSavingDraft = ref(false);
const products = ref<any[]>([]);
const stockItems = ref<any[]>([]);
const clientList = ref<any[]>([]);
const salespeopleList = ref<any[]>([]);
const paymentMethods = ref<any[]>([]);
const saleStatuses = ref<any[]>([]);
const stampLibrary = ref<any[]>([]);
const availableStores = ref<any[]>([]);
const availableDesignTags = ref<string[]>([]);

const currentStoreObj = ref<any>(null);

const defaultChartOfAccountId = ref<string | null>(null);
const defaultBankAccountId = ref<string | null>(null);
const bankAccountName = ref<string>('Carregando...');

const searchStore = ref('');

const showOpenBoxModal = ref(false);
const showCloseBoxModal = ref(false);
const showOperationsModal = ref(false);
const showSessionEndedModal = ref(false);
const operationType = ref<'supply' | 'bleed'>('supply');
const showClientModal = ref(false);
const showDraftsModal = ref(false);
const lastClosedSession = ref<any>(null);

const isCheckingSession = ref(true);
const adminStoreStats = ref<Record<string, number>>({});
const quickStartAmount = ref<number | string>('');

const draftsList = ref<any[]>([]);
const showDraftAlert = ref(false);
const draftLoadError = ref<string | null>(null);
const AUTO_RECOVERY_KEY = 'autoRecoveryOrder';
const currentDraftId = ref<string | null>(null);
const currentDraftName = ref<string | null>(null);
const draftSaveState = ref<'idle' | 'loading' | 'success'>('idle');
let autoSaveTimeout: NodeJS.Timeout;

const orderHeader = ref({
    customer_id: null as string | number | null,
    customer_name: '',
    vendedor_id: userStore.user?.id,
    observation: ''
});
const orderItems = ref<any[]>([]);

const paymentDetails = ref({
    entry_value: 0,
    entry_method_id: null as string | null,
    installment_payment_method_id: null as string | null,
    type: 'vista',
    installments: [] as any[],
    installments_count: 1,
    installments_interval: 30,
    first_due_date: format(new Date(), 'yyyy-MM-dd'),
    downPayments: [] as any[],
    generatePix: true
});

const usedCreditValue = ref(0);
const clientCreditInfo = ref({ limit: 0, used: 0 });
const availableCredit = computed(() => Math.max(0, clientCreditInfo.value.limit - clientCreditInfo.value.used));
const selectedClient = computed(() => {
    if (!orderHeader.value.customer_id) return null;

    return clientList.value.find((client: any) =>
        String(client.id) === String(orderHeader.value.customer_id) ||
        String(client.gestao_click_id || '') === String(orderHeader.value.customer_id)
    ) || null;
});

const isSelectedClientDelinquent = computed(() => !!selectedClient.value?.is_delinquent);

const selectedClientDelinquencyMessage = computed(() => {
    const name = selectedClient.value?.nome_fantasia || selectedClient.value?.nome || orderHeader.value.customer_name || 'Este cliente';
    const reason = selectedClient.value?.delinquency_reason || 'Cliente com débito em aberto com a empresa.';
    return `${name} está bloqueado para novos pedidos. Motivo: ${reason} O cliente deve quitar os débitos antes de fazer um novo pedido.`;
});
const isPaymentValid = ref(false);

const currentOrderNumber = ref<number | string>('...');
const loadingNextOrderNumber = ref(true);
const orderCreatedSuccess = ref(false);
const createdOrderNumber = ref<number | null>(null);
let tour: Shepherd.Tour;

const currentTime = ref('');
const currentDate = ref('');
const updateClock = () => {
    const now = new Date();
    currentTime.value = format(now, 'HH:mm');
    currentDate.value = format(now, "EEE, d MMM", { locale: ptBR });
};
let clockInterval: NodeJS.Timeout;

const isLight = computed(() => themeStore.currentMode === 'light');
const pageThemeClass = computed(() => isLight.value ? 'bg-grey-lighten-5 text-grey-darken-4' : 'bg-background-dark text-white');
const headerThemeClass = computed(() => isLight.value ? 'bg-white border-grey-lighten-2' : 'bg-surface border-white-05');
const cardThemeClass = computed(() => isLight.value ? 'bg-white border-grey-lighten-2' : 'bg-surface border-white-1');
const textPrimaryClass = computed(() => isLight.value ? 'text-grey-darken-4' : 'text-white');
const textSecondaryClass = computed(() => isLight.value ? 'text-grey-darken-1' : 'text-white-70');
const textSecondaryColor = computed(() => isLight.value ? 'grey-darken-1' : 'white-50');
const checkoutPanelClass = computed(() => isLight.value ? 'bg-white border-grey-lighten-2 shadow-sm' : 'bg-surface border-white-1');
const checkoutHeaderClass = computed(() => isLight.value ? 'bg-grey-lighten-5' : 'bg-surface-variant');
const openingCardClass = computed(() => isLight.value ? 'bg-white border-grey-lighten-2' : 'glass-card border-white-1');
const inputBgColor = computed(() => isLight.value ? 'white' : 'rgba(0,0,0,0.3)');

const isSessionOpen = computed(() => cashStore.isSessionOpen);
const totalOrderValue = computed(() => orderItems.value.reduce((acc, item) => acc + (item.quantity * item.valor_unitario), 0));

const hasStockIssues = computed(() => {
    const itemTravado = orderItems.value.find(item => item.has_insufficient_stock === true);
    if (itemTravado) return true;

    const usageMap = new Map();
    for (const item of orderItems.value) {
        if (!item.fabric_type) continue;
        const currentUsage = usageMap.get(item.fabric_type) || 0;
        const meters = Number(item.quantity_meters) || Number(item.quantity) || 0;
        usageMap.set(item.fabric_type, currentUsage + meters);
    }

    let hasError = false;
    for (const [fabric, needed] of usageMap.entries()) {
        const stockItem = stockItems.value.find(s => s.fabric_type === fabric);
        if (stockItem) {
            let availableRaw = Number(stockItem.available_meters || 0);
            let availableMeters = availableRaw;
            const unit = (stockItem.unit_of_measure || stockItem.unidade || 'm').toLowerCase();
            const rendimento = Number(stockItem.rendimento || 0);

            if (unit === 'kg' && rendimento > 0) {
                availableMeters = availableRaw * rendimento;
            }

            if (needed > availableMeters + 0.05) {
                hasError = true;
            }
        }
    }
    return hasError;
});

const isValidOrder = computed(() => {
    const headerValid = !!orderHeader.value.customer_id;
    const itemsValid = orderItems.value.length > 0;
    const valueValid = totalOrderValue.value > 0;
    return headerValid && itemsValid && valueValid && isPaymentValid.value && !isSelectedClientDelinquent.value;
});

const canMoveCash = computed(() => userStore.profile?.can_move_cash !== false);
const shouldBlockScreen = computed(() => { return userStore.isAdmin && !userStore.activeStoreId; });

const filteredStores = computed(() => {
    if (!searchStore.value) return availableStores.value;
    const term = searchStore.value.toLowerCase();
    return availableStores.value.filter(s => s.name.toLowerCase().includes(term) || s.address?.toLowerCase().includes(term));
});

const formatCurrency = (value: number | string, prefix = 'R$', decimals = 2) => {
    const num = Number(value) || 0;
    return new Intl.NumberFormat('pt-BR', {
        style: 'currency',
        currency: 'BRL',
        minimumFractionDigits: decimals,
        maximumFractionDigits: decimals
    }).format(num).replace('R$', prefix ? prefix + ' ' : '').trim();
};

const storeKpis = computed(() => {
    const totalStores = availableStores.value.length;
    const openStores = availableStores.value.filter(s => s.active_session_user).length;
    const totalSales = Object.values(adminStoreStats.value).reduce((acc, val) => acc + val, 0);
    return [
        { label: 'Unidades', value: totalStores, footer: 'Cadastradas', icon: 'mdi-store', gradient: 'bg-gradient-purple', isMoney: false },
        { label: 'Abertas Agora', value: openStores, footer: 'Em operação', icon: 'mdi-store-clock', gradient: 'bg-gradient-info', isMoney: false },
        { label: 'Vendas Hoje', value: formatCurrency(totalSales), footer: 'Rede Total', icon: 'mdi-chart-line', gradient: 'bg-gradient-success', isMoney: false }
    ];
});

const rawForecastDate = computed(() => {
    if (orderItems.value.length === 0) return null;
    return appStore.calculateForecastDate(new Date());
});

const forecastDeliveryDate = computed(() => {
    if (!rawForecastDate.value) return '---';
    return format(rawForecastDate.value, "dd/MM", { locale: ptBR });
});

const fetchStoresWithStatus = async () => {
    if (!userStore.isAdmin) return;
    const { data: storesData } = await supabase.from('stores').select('*').eq('active', true);
    const { data: sessionsData } = await supabase.from('mj_cash_sessions').select('store_id, user:profiles(full_name)').eq('status', 'open');
    availableStores.value = (storesData || []).map(store => {
        const session = sessionsData?.find((s: any) => s.store_id === store.id);
        const userData = Array.isArray(session?.user) ? session?.user[0] : session?.user;
        return { ...store, active_session_user: userData?.full_name || null };
    });
};

const fetchAdminStoreStats = async () => {
    if (!userStore.isAdmin) return;
    const today = startOfDay(new Date()).toISOString();
    const { data } = await supabase.from('orders').select('store_id, total_value').gte('created_at', today).neq('status', 'cancelled');
    if (data) {
        const stats: Record<string, number> = {};
        data.forEach((order: any) => {
            if (order.store_id) stats[order.store_id] = (stats[order.store_id] || 0) + Number(order.total_value || 0);
        });
        adminStoreStats.value = stats;
    }
};

const handleQuickOpen = async () => {
    const val = Number(String(quickStartAmount.value).replace(',', '.'));
    if (isNaN(val) || val < 0) return appStore.showSnackbar("Valor inválido", "error");
    try {
        await cashStore.openSession(val);
        appStore.showSnackbar("Caixa aberto!", "success");
        refreshSession();
    } catch (e: any) {
        appStore.showSnackbar("Erro ao abrir caixa: " + e.message, "error");
    }
};

const handleCreateClientRequest = () => {
    if (!currentStoreObj.value) {
         if (userStore.activeStoreName?.toUpperCase().includes('SP')) {
              appStore.showSnackbar('Para esta unidade, novos clientes devem ser cadastrados pelo Administrador.', 'warning');
              return;
         }
         showClientModal.value = true;
         return;
    }

    const address = (currentStoreObj.value.address || '').toUpperCase();
    const name = (currentStoreObj.value.name || '').toUpperCase();
    const state = (currentStoreObj.value.state || '').toUpperCase();

    const isRestricted =
        address.includes('SP') ||
        address.includes('SÃO PAULO') ||
        address.includes('SAO PAULO') ||
        state === 'SP' ||
        name.includes('SP') ||
        name.includes('MATRIZ') ||
        name.includes('SUDESTE');

    if (isRestricted) {
        appStore.showSnackbar('Cadastro de clientes restrito para esta região. Solicite ao Administrador.', 'warning');
    } else {
        showClientModal.value = true;
    }
};

const fetchDesignTags = async () => {
    try {
        const { data } = await supabase
            .from('design_kanban_columns')
            .select('tag_name')
            .eq('available_in_new_order', true)
            .order('order_index', { ascending: true });

        if (data) {
            availableDesignTags.value = data.map(d => d.tag_name);
        }
    } catch (e) {
        console.error("Erro ao buscar tags de design para o NewOrder", e);
    }
};

const init = async () => {
    loadingData.value = true;
    isCheckingSession.value = true;
    updateClock();
    clockInterval = setInterval(updateClock, 1000);
    try {
        await appStore.fetchDeliveryConfig();

        if (!userStore.profile?.id) await userStore.fetchProfile();

        if (userStore.activeStoreId) {
             const { data } = await supabase.from('stores').select('*').eq('id', userStore.activeStoreId).single();
             currentStoreObj.value = data;
        }

        if (userStore.isAdmin) {
            await fetchStoresWithStatus();
            await fetchAdminStoreStats();
        }
        await fetchPaymentMethods();
        await Promise.all([
            fetchInitialData(),
            fetchNextOrderNumber(),
            fetchFinancialDefaults(),
            fetchDesignTags()
        ]);

        if (userStore.activeStoreId && canMoveCash.value) await cashStore.checkActiveSession();
        if (route.query.cloneId) await loadOrderForCloning(String(route.query.cloneId));
        else if (localStorage.getItem(AUTO_RECOVERY_KEY)) restoreAutoSave();
    } finally {
        loadingData.value = false;
        isCheckingSession.value = false;
    }
    window.addEventListener('keydown', handleKeydown);
    orderHeader.value.vendedor_id = userStore.user?.id;
};

const loadOrderForCloning = async (id: string) => {
  loadingData.value = true;
  try {
    const { data: order, error } = await supabase.from('orders').select('*, order_items(*)').eq('id', id).single();
    if (error) throw error;
    orderHeader.value.customer_id = order.customer_id;
    orderHeader.value.customer_name = order.customer_name;
    orderHeader.value.observation = order.details?.observation || '';
    orderItems.value = order.order_items.map((i: any) => ({ ...i, id: undefined, order_id: undefined }));
    appStore.showSnackbar('Dados do pedido clonados. Revise antes de lançar.', 'info');
  } catch (e) {
    console.error(e);
    appStore.showSnackbar('Erro ao clonar pedido.', 'error');
  } finally {
    loadingData.value = false;
  }
};

onUnmounted(() => {
    window.removeEventListener('keydown', handleKeydown);
    clearInterval(clockInterval);
    clearTimeout(autoSaveTimeout);
    if (tour) tour.complete();
    if (pixState.checkInterval) clearInterval(pixState.checkInterval);
});

const handleAdminStoreSelection = async (store: any) => {
    userStore.setAdminStore(store);
    currentStoreObj.value = store;
    if(canMoveCash.value) {
        isCheckingSession.value = true;
        await cashStore.checkActiveSession();
        isCheckingSession.value = false;
    }
};
const resetAdminStore = () => { userStore.setAdminStore(null); cashStore.currentSession = null; fetchAdminStoreStats(); currentStoreObj.value = null; };

const handleKeydown = (e: KeyboardEvent) => {
    if (!e || !e.key) return;
    if (e.key === 'F12' && isValidOrder.value) { e.preventDefault(); submitOrder(); return; }
    const activeTag = document.activeElement?.tagName;
    const isTyping = e.key.length === 1 && !e.ctrlKey && !e.altKey && !e.metaKey;
    if (isTyping && activeTag !== 'INPUT' && activeTag !== 'TEXTAREA') {
        if (itemManagerRef.value && itemManagerRef.value.focusSearch) itemManagerRef.value.focusSearch();
    }
};

const fetchFinancialDefaults = async () => {
    try {
        const { data: chart } = await supabase.from('finance_chart_of_accounts').select('id, name').or('code.eq.1.01.001,name.ilike.%venda de produtos%').limit(1).maybeSingle();
        if (chart) defaultChartOfAccountId.value = chart.id;
        else { const { data: anyChart } = await supabase.from('finance_chart_of_accounts').select('id').eq('type', 'Receita').limit(1).maybeSingle(); if(anyChart) defaultChartOfAccountId.value = anyChart.id; }
        const bankNameSearch = targetBankName.value;
        const { data: bank } = await supabase.from('finance_accounts').select('id, name').ilike('name', `%${bankNameSearch}%`).eq('is_active', true).limit(1).maybeSingle();
        if (bank) { defaultBankAccountId.value = bank.id; bankAccountName.value = bank.name; }
        else { const { data: anyBank } = await supabase.from('finance_accounts').select('id, name').eq('is_active', true).limit(1).maybeSingle(); if (anyBank) { defaultBankAccountId.value = anyBank.id; bankAccountName.value = anyBank.name + " (Padrão)"; } else { bankAccountName.value = "Nenhuma conta ativa"; } }
    } catch (e) { console.error("Erro defaults financeiros", e); bankAccountName.value = "Erro ao carregar"; }
};

const fetchInitialData = async () => {
    const { data: stock } = await supabase.from('stock').select('*').eq('verification', true).eq('visible_in_sales', true);
    stockItems.value = stock || [];
    // Mapeado apenas o ID local do Supabase
    products.value = stockItems.value.map(s => ({ id: s.id, internal_id: s.id, nome: s.fabric_type, valor_venda: s.base_price, estoque: s.available_meters, unidade: s.unit_of_measure, rendimento: s.rendimento }));
    const { data: profiles } = await supabase.from('profiles').select('id, full_name').or(`role.eq.vendedor,role.eq.admin,role.eq.super_admin`);
    salespeopleList.value = profiles || [];
    const { data: stamps } = await supabase.from('stamp_library').select('*').limit(100);
    stampLibrary.value = stamps || [];
    const { data: clients } = await supabase.from('customers_mj').select('*').limit(50);
    clientList.value = clients || [];
    saleStatuses.value = []; // Totalmente desvinculado do GestãoClick
};

const fetchPaymentMethods = async () => {
    try {
        const { data: financeMethods } = await supabase.from('finance_payment_methods').select('id, name').eq('is_active', true).order('name');
        if (financeMethods && financeMethods.length > 0) {
             paymentMethods.value = financeMethods.map(m => ({ id: m.id, nome: m.name }));
        } else { throw new Error("Nenhuma forma de pagamento disponível."); }
    } catch (e: any) {
        console.error("Erro em formas de pagamento:", e);
        appStore.showSnackbar('Erro ao carregar pagamentos: ' + e.message, 'error');
        paymentMethods.value = [{ id: 'dinheiro-fallback', nome: 'Dinheiro' }, { id: 'cartao-fallback', nome: 'Cartão' }];
    }
}

const fetchNextOrderNumber = async () => {
  if (currentDraftId.value && currentOrderNumber.value) return;
  loadingNextOrderNumber.value = true;
  try {
    const { data, error } = await supabase.rpc('get_next_order_number');
    if (error) throw error;
    currentOrderNumber.value = data;
  } catch (e) { currentOrderNumber.value = 0; }
  finally { loadingNextOrderNumber.value = false; }
};

const handleClientCreated = (newClient: any) => {
  clientList.value.unshift(newClient);
  orderHeader.value.customer_id = newClient.id;
  orderHeader.value.customer_name = newClient.nome || newClient.name || 'Novo Cliente';
  showClientModal.value = false;
  appStore.showSnackbar(`Cliente "${orderHeader.value.customer_name}" cadastrado!`, 'success');
};

const refreshSession = async () => { await cashStore.checkActiveSession(); showOpenBoxModal.value = false; showOperationsModal.value = false; };
const handleSessionClosed = (result: any) => { showCloseBoxModal.value = false; lastClosedSession.value = result; cashStore.checkActiveSession(); showSessionEndedModal.value = true; };
const openOperation = (type: any) => { operationType.value = type; showOperationsModal.value = true; };

const reprintZReport = async () => {
    if (!lastClosedSession.value) return;
    appStore.showSnackbar('Gerando Relatório de Caixa...', 'info');
    try {
        await generateClosingReport(
            lastClosedSession.value.session,
            lastClosedSession.value.movements,
            userStore.activeStoreName || 'Loja',
            userStore.profile?.full_name || 'Operador',
            lastClosedSession.value.detailedSales || []
        );
        appStore.showSnackbar('Relatório gerado com sucesso!', 'success');
    } catch (e: any) {
        console.error("Erro ao gerar o PDF:", e);
        appStore.showSnackbar('Erro ao gerar relatório: ' + e.message, 'error');
    }
};

const getDiffColor = (diff: number) => { return (!diff || diff === 0) ? 'text-success' : (diff > 0 ? 'text-info' : 'text-error'); };
const getDiffLabel = (diff: number) => { return (!diff || diff === 0) ? 'Sem Divergência' : (diff > 0 ? `Sobra: ${formatCurrency(diff)}` : `Quebra: ${formatCurrency(diff)}`); };

const calculatedDifference = computed(() => {
    if (!lastClosedSession.value || !lastClosedSession.value.session) return 0;

    const session = lastClosedSession.value.session;
    const movements = lastClosedSession.value.movements || [];

    const initial = Number(session.initial_balance || 0);
    const finalUser = Number(session.final_balance_user || 0);

    let expected = initial;
    movements.forEach((m: any) => {
        const val = Math.abs(Number(m.amount || 0));

        if (m.type === 'supply' || m.type === 'sale_cash' || m.type === 'in_audit') {
            expected += val;
        }
        else if (m.type === 'bleed' || m.type === 'out_audit') {
            expected -= val;
        }
    });

    return finalUser - expected;
});

const totalOrderMeters = computed(() => {
    return orderItems.value.reduce((acc, item) => acc + (Number(item.quantity_meters) || 0), 0);
});

const autoSave = () => {
  if (!orderHeader.value.customer_id && orderItems.value.length === 0) { clearAutoSave(false); return; }
  localStorage.setItem(AUTO_RECOVERY_KEY, JSON.stringify({ orderHeader: orderHeader.value, orderItems: orderItems.value, paymentDetails: paymentDetails.value, draftContext: { id: currentDraftId.value, name: currentDraftName.value } }));
};

const restoreAutoSave = () => {
  try {
    const saved = JSON.parse(localStorage.getItem(AUTO_RECOVERY_KEY)!);
    Object.assign(orderHeader.value, saved.orderHeader);
    orderItems.value = saved.orderItems;

    const savedDetails = saved.paymentDetails || paymentDetails.value;
    if(!savedDetails.downPayments) savedDetails.downPayments = [];
    paymentDetails.value = savedDetails;

    if (saved.draftContext) { currentDraftId.value = saved.draftContext.id; currentDraftName.value = saved.draftContext.name; }
    showDraftAlert.value = true;
  } catch (e) { clearAutoSave(false); }
};

const clearAutoSave = (reset = false) => { localStorage.removeItem(AUTO_RECOVERY_KEY); showDraftAlert.value = false; if (reset) resetOrder(false); };

const saveDraft = async () => {
  if (!userStore.profile?.id) {
    await userStore.fetchProfile();
    if (!userStore.profile?.id) {
      appStore.showSnackbar('Erro: Perfil de usuário não carregado.', 'error');
      return;
    }
  }
  if (!orderHeader.value.customer_id && orderItems.value.length === 0) return;

  draftSaveState.value = 'loading';
  try {
    let draftName = currentDraftName.value;
    if (!draftName) {
      draftName = prompt('Nome do rascunho:', `${orderHeader.value.customer_name || 'Novo'} - ${new Date().toLocaleDateString()}`);
      if (!draftName) { draftSaveState.value = 'idle'; return; }
      currentDraftName.value = draftName;
    }

    if (draftName.toUpperCase().startsWith('PDV')) {
        draftName = draftName.replace(/^PDV\s*-?\s*/i, 'Pedido - ');
        currentDraftName.value = draftName;
    }

    if (!orderHeader.value.customer_name && orderHeader.value.customer_id) {
        const client = clientList.value.find(c => c.id == orderHeader.value.customer_id);
        if (client) orderHeader.value.customer_name = client.nome || client.name || '';
    }

    const headerSnapshot = JSON.parse(JSON.stringify(orderHeader.value));
    const paymentsSnapshot = JSON.parse(JSON.stringify(paymentDetails.value));

    const payload: any = {
        user_id: userStore.profile.id,
        company_id: companyStore.context,
        name: draftName,
        draft_data: {
            orderHeader: headerSnapshot,
            orderItems: JSON.parse(JSON.stringify(orderItems.value)),
            paymentDetails: paymentsSnapshot
        },
        reserved_order_number: currentOrderNumber.value
    };

    if (currentDraftId.value) payload.id = currentDraftId.value;

    const { data, error } = await supabase.from('order_drafts').upsert(payload).select().single();

    if (error) {
        if (error.code === '23505' && !currentDraftId.value) {
            console.warn("Colisão de número reservado. Salvando sem reservar número.");
            payload.reserved_order_number = null;
            const { data: retryData, error: retryErr } = await supabase.from('order_drafts').insert(payload).select().single();
            if (retryErr) throw retryErr;
            currentDraftId.value = retryData.id;
        } else {
            throw error;
        }
    } else {
        currentDraftId.value = data.id;
    }

    await logBusinessEvent(
        'Vendas',
        payload.id ? 'Atualização' : 'Criação',
        payload.id ? `Atualizou o rascunho do pedido (${draftName}).` : `Salvou um novo rascunho de pedido (${draftName}).`,
        payload
    );

    appStore.showSnackbar(payload.id ? 'Rascunho atualizado!' : 'Rascunho salvo!', 'success');
    draftSaveState.value = 'success';
    setTimeout(() => { draftSaveState.value = 'idle'; }, 3000);
    clearAutoSave(false);

  } catch (e: any) {
    console.error("Erro no rascunho:", e);
    appStore.showSnackbar(e.message, 'error');
    draftSaveState.value = 'idle';
  }
};

const openDraftsModal = async () => {
    if (!userStore.profile?.id) return;

    const { data } = await supabase.from('order_drafts')
        .select('*')
        .eq('user_id', userStore.profile.id)
        .eq('company_id', companyStore.context)
        .not('name', 'ilike', 'PDV%')
        .order('created_at', { ascending: false });

    draftsList.value = data || [];
    showDraftsModal.value = true;
};

const loadDraft = async (draft: any) => {
    const dData = draft.draft_data;
    draftLoadError.value = null;

    const loadedHeader = dData.orderHeader || {};
    let targetCustomerId = loadedHeader.customer_id;

    if (targetCustomerId) {
        const clientExistsLocally = clientList.value.some(c => String(c.id) === String(targetCustomerId));

        if (!clientExistsLocally) {
            appStore.showSnackbar("Buscando dados do cliente do rascunho...", "info");

try {
                const isUuid = /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/.test(String(targetCustomerId));
                const { data: missingClient } = await supabase
                    .from('customers_mj')
                    .select('*')
                    .eq(isUuid ? 'id' : 'gestao_click_id', targetCustomerId)
                    .maybeSingle();

                if (missingClient) {
                    clientList.value = [missingClient, ...clientList.value];
                } else {
                    draftLoadError.value = "Cliente do rascunho não encontrado no banco de dados.";
                }
            } catch (err) {}
        }
    }

    orderHeader.value.customer_id = targetCustomerId;
    const clientObj = clientList.value.find(c => String(c.id) === String(targetCustomerId));
    orderHeader.value.customer_name = clientObj ? (clientObj.nome || clientObj.name) : (loadedHeader.customer_name || '');
    orderHeader.value.vendedor_id = loadedHeader.vendedor_id;
    orderHeader.value.observation = loadedHeader.observation;

    if (orderHeader.value.customer_id && !orderHeader.value.customer_name) {
        draftLoadError.value = "O ID do cliente existe, mas o nome não foi carregado. Selecione o cliente novamente.";
    }

    const rawItems = dData.orderItems || [];
    orderItems.value = rawItems.map((i: any) => ({
        ...i,
        has_insufficient_stock: false,
        error_message: null
    }));

    const loadedDetails = dData.paymentDetails || paymentDetails.value;
    if(!loadedDetails.downPayments) loadedDetails.downPayments = [];
    paymentDetails.value = loadedDetails;

    currentDraftId.value = draft.id;
    currentDraftName.value = draft.name;
    currentOrderNumber.value = draft.reserved_order_number;

    showDraftsModal.value = false;
    appStore.showSnackbar('Rascunho carregado com sucesso!', 'success');
};

const deleteDraft = async (id: string) => { await supabase.from('order_drafts').delete().eq('id', id); draftsList.value = draftsList.value.filter(d => d.id !== id); };
const getPaymentMethodName = (id: string | null) => { if (!id) return 'Desconhecido'; const method = paymentMethods.value.find(m => String(m.id) === String(id)); return method ? method.nome : 'Outros'; };

const submitOrder = async () => {
    if (isSelectedClientDelinquent.value) {
    appStore.showSnackbar(selectedClientDelinquencyMessage.value, 'error');
    return;
}

    if (hasStockIssues.value) {
        appStore.showSnackbar('Lançamento bloqueado por falta de estoque.', 'error');
        return;
    }

    if (canMoveCash.value && !cashStore.currentSession) {
        appStore.showSnackbar('Sessão de caixa necessária.', 'error');
        return;
    }

    const currentCustomerId = orderHeader.value.customer_id;
    if (!currentCustomerId) {
        appStore.showSnackbar('Cliente não selecionado.', 'error');
        return;
    }

    if (usedCreditValue.value > 0 && usedCreditValue.value > availableCredit.value) {
        appStore.showSnackbar(`Saldo insuficiente!`, 'error');
        return;
    }

    isSubmitting.value = true;
    try {
        let nextOrderNumber = Number(currentOrderNumber.value);
        if (!nextOrderNumber || isNaN(nextOrderNumber) || nextOrderNumber === 0) {
             const nextNumberData = await supabase.rpc('get_next_order_number');
             nextOrderNumber = nextNumberData.data || Date.now();
        }

        createdOrderNumber.value = nextOrderNumber;

        if (!userStore.activeStoreId) throw new Error("Loja não selecionada.");

let finalCustomerUuid = String(currentCustomerId);
        const isUuid = /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/.test(finalCustomerUuid);

        if (!isUuid) {
            const { data: existing } = await supabase.from('customers_mj').select('id').eq('gestao_click_id', currentCustomerId).maybeSingle();
            if (existing) finalCustomerUuid = existing.id;
        }

        if (!orderHeader.value.customer_name) {
            const client = clientList.value.find(c => String(c.id) === String(currentCustomerId));
            if (client) orderHeader.value.customer_name = client.nome || client.name || '';
        }

        const defaultTag = availableDesignTags.value.length > 0 ? availableDesignTags.value[0] : 'Desenvolvimento';

        const processedItems = orderItems.value.map(i => {
            const stockItem = stockItems.value.find(s => s.fabric_type === i.fabric_type);
            const trueUnit = stockItem ? stockItem.unit_of_measure : (i.unit_of_measure || 'm');

            const originalQty = Number(i.quantity) || 0;
            let finalMeters = originalQty;

            if (trueUnit === 'kg' && i.rendimento && Number(i.rendimento) > 0) {
                finalMeters = originalQty * Number(i.rendimento);
            } else {
                finalMeters = originalQty;
            }

            return {
                ...i,
                quantity: originalQty,
                final_meters_for_db: Number(finalMeters.toFixed(2)),
                unit_of_measure: trueUnit,
                rendimento: i.rendimento,
                observation: i.observation || i.notes || '',
                is_ready_for_billing: i.is_ready_for_billing,
                design_tag: i.design_tag || defaultTag
            };
        });

        const orderHeaderForLaunch = { ...orderHeader.value };
        orderHeaderForLaunch.customer_id = finalCustomerUuid;
        orderHeaderForLaunch.company_id = companyStore.context;

        const creditLaunchDetails = { value: usedCreditValue.value, gestaoMethodId: null };

        const fallbackMethodId = paymentMethods.value.find(m => m.nome.toLowerCase().includes('não informado'))?.id || null;
        const mainMethodId = paymentDetails.value.installment_payment_method_id || fallbackMethodId;
        const targetBankId = defaultBankAccountId.value;
        const targetChartId = defaultChartOfAccountId.value;

        if (paymentDetails.value.installments && paymentDetails.value.installments.length > 0) {
            paymentDetails.value.installments = paymentDetails.value.installments.map((inst: any) => ({
                ...inst,
                payment_method_id: inst.payment_method_id || mainMethodId,
                bank_account_id: targetBankId,
                chart_of_accounts_id: targetChartId
            }));
        }

        if (paymentDetails.value.downPayments && paymentDetails.value.downPayments.length > 0) {
            paymentDetails.value.downPayments = paymentDetails.value.downPayments.map((dp: any) => ({
                ...dp,
                bank_account_id: targetBankId,
                chart_of_accounts_id: targetChartId,
                method_id: dp.method_id || fallbackMethodId
            }));
        }

        const localPaymentDetails = JSON.parse(JSON.stringify(paymentDetails.value));

        await submitLaunch(
            nextOrderNumber,
            orderHeaderForLaunch,
            processedItems,
            localPaymentDetails,
            salespeopleList.value,
            saleStatuses.value,
            products.value,
            stockItems.value,
            userStore.profile,
            currentDraftId.value,
            undefined,
            creditLaunchDetails
        );

        if (createdOrderId.value && companyStore.context && companyStore.context !== 'global') {
             await supabase.from('orders').update({ company_id: companyStore.context }).eq('id', createdOrderId.value);
             await supabase.from('finance_receivables').update({ company_id: companyStore.context }).eq('order_id', createdOrderId.value);
        }

        if (localPaymentDetails.downPayments && Array.isArray(localPaymentDetails.downPayments)) {
            localPaymentDetails.downPayments.forEach((dp: any) => {
                if (Number(dp.value) > 0) {
                    cashStore.logExtraction('NEW_ORDER_SINAL', Number(dp.value), dp.method_id || dp.entry_method_id, `#${nextOrderNumber}`, dp);
                }
            });
        }
        else if (Number(localPaymentDetails.entry_value) > 0) {
            cashStore.logExtraction('NEW_ORDER_SINAL', Number(localPaymentDetails.entry_value), localPaymentDetails.entry_method_id, `#${nextOrderNumber}`, { value: localPaymentDetails.entry_value });
        }

    } catch (e: any) {
        console.error("Erro crítico ao lançar pedido:", e);
        appStore.showSnackbar('Erro: ' + e.message, 'error');
        isSubmitting.value = false;
    }
};

const handleDownloadQuote = () => {
    if(!createdOrderId.value) return;

    const clientName = clientList.value.find(c => c.id == orderHeader.value.customer_id)?.nome || orderHeader.value.customer_name || 'Cliente';
    const sellerObj = salespeopleList.value.find(s => s.id === orderHeader.value.vendedor_id);
    const sellerName = sellerObj ? sellerObj.full_name : (userStore.profile?.full_name || 'Vendedor');

    const itemsForPdf = orderItems.value.map(i => {
        const stockItem = stockItems.value.find(s => s.fabric_type === i.fabric_type);
        const trueUnit = stockItem ? stockItem.unit_of_measure : (i.unit_of_measure || 'm');

        let meters = Number(i.quantity_meters) || 0;
        if (meters === 0) {
             if (trueUnit === 'kg' && i.rendimento) {
                 meters = Number(i.quantity) * Number(i.rendimento);
             } else {
                 meters = Number(i.quantity);
             }
        }

        return {
            ...i,
            quantity: Number(i.quantity),
            unit_of_measure: trueUnit,
            quantity_meters: meters,
            observation: i.observation || i.notes || ''
        };
    });

    const totalMetersPdf = itemsForPdf.reduce((sum, i) => sum + (Number(i.quantity_meters) || 0), 0);
    generateQuoteAndUploadPdf(createdOrderNumber.value!, createdOrderId.value!, clientName, itemsForPdf, totalMetersPdf, sellerName);
};

const handleSubmissionClose = async () => {
    showSubmittingModal.value = false;
    if (submissionStatus.step === 'success') {
        orderCreatedSuccess.value = true;
        clearAutoSave(false);
        setTimeout(() => { tryGeneratePostLaunchPix(); }, 500);
    }
    isSubmitting.value = false;
};

const resetOrder = (full = true) => {
    orderCreatedSuccess.value = false;
    orderItems.value = [];
    orderHeader.value.customer_id = null;
    orderHeader.value.customer_name = '';
    paymentDetails.value.entry_value = 0;
    paymentDetails.value.installments = [];
    paymentDetails.value.downPayments = [];
    usedCreditValue.value = 0;
    currentDraftId.value = null;
    currentDraftName.value = null;
    fetchNextOrderNumber();
    if(full) clearAutoSave(true);
    setTimeout(() => { if (itemManagerRef.value?.focusSearch) itemManagerRef.value.focusSearch(); }, 200);

    pixState.show = false;
    pixState.status = 'PENDING';
    if (pixState.checkInterval) clearInterval(pixState.checkInterval);
};

watch([orderHeader, orderItems, paymentDetails], () => { clearTimeout(autoSaveTimeout); autoSaveTimeout = setTimeout(autoSave, 2000); }, { deep: true });

watch(() => orderHeader.value.customer_id, async (newId) => {
   if (newId) {
       const client = clientList.value.find(c => String(c.id) === String(newId));

       if (client) {
           orderHeader.value.customer_name = client.nome || client.name || client.full_name || '';
       }

       const isUuid = /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/.test(String(newId));
       const column = isUuid ? 'id' : 'gestao_click_id';

       const { data: creditData } = await supabase.from('customers_mj').select('credit_limit, credit_used').eq(column, newId).maybeSingle();
       if (creditData) { clientCreditInfo.value = { limit: Number(creditData.credit_limit) || 0, used: Number(creditData.credit_used) || 0 }; }
   }
});

watch(() => route.meta.orderContext, async () => { await fetchFinancialDefaults(); });

// --- CORA KEYS MAP ---
const coraKeys: Record<string, string> = {
    '20631721000107': 'int-3VpXneDbEmHHHYFNN8hoIh', // Mr Jacky
    '53756096000189': 'int-23ze6BcCmlV6oqO2TPP01s', // Santos & Lopes
};

const pixState = reactive({
    show: false,
    loading: false,
    qrCodeImage: '',
    copyPaste: '',
    invoiceId: '',
    status: 'PENDING',
    displayValue: '',
    checkInterval: null as NodeJS.Timeout | null
});

const tryGeneratePostLaunchPix = async () => {
    if (paymentDetails.value.generatePix === false) {
        console.log('Geração de Pix ignorada pelo usuário.');
        return;
    }

    const isPixEntry = paymentDetails.value.entry_method_id &&
                       getPaymentMethodName(paymentDetails.value.entry_method_id).toLowerCase().includes('pix');

    const hasPixDownPayment = paymentDetails.value.downPayments?.some((dp: any) =>
        getPaymentMethodName(dp.method_id).toLowerCase().includes('pix')
    );

    const isPixMainMethod = paymentDetails.value.installment_payment_method_id &&
                            getPaymentMethodName(paymentDetails.value.installment_payment_method_id).toLowerCase().includes('pix');

    if (!isPixEntry && !hasPixDownPayment && !isPixMainMethod) return;

    let amountToCharge = 0;

    if (isPixEntry) amountToCharge += Number(paymentDetails.value.entry_value || 0);

    if (paymentDetails.value.downPayments) {
        paymentDetails.value.downPayments.forEach((dp: any) => {
            if (getPaymentMethodName(dp.method_id).toLowerCase().includes('pix')) {
                amountToCharge += Number(dp.value || 0);
            }
        });
    }

    if (isPixMainMethod) {
        let totalDownPayments = Number(paymentDetails.value.entry_value || 0);
        if (paymentDetails.value.downPayments) {
            totalDownPayments = paymentDetails.value.downPayments.reduce((acc, dp) => acc + Number(dp.value || 0), 0);
        }
        const remainingBalance = totalOrderValue.value - totalDownPayments - usedCreditValue.value;
        if (remainingBalance > 0.05) {
            amountToCharge += remainingBalance;
        }
    }

    if (amountToCharge <= 0) return;

    const clientObj = clientList.value.find(c => c.id == orderHeader.value.customer_id);
    let identity = clientObj?.cnpj || clientObj?.cpf || '';
    identity = identity.replace(/\D/g, '');

    const storeCnpj = '20631721000107';

    if (!identity || identity === storeCnpj) {
        if(identity === storeCnpj) appStore.showSnackbar('Aviso: Não é possível gerar Pix para a própria empresa (Auto-cobrança).', 'warning');
        else appStore.showSnackbar('Cliente sem CPF/CNPJ. Pix não gerado.', 'warning');
        return;
    }

    pixState.loading = true;
    pixState.show = true;
    pixState.status = 'PENDING';
    pixState.displayValue = formatCurrency(amountToCharge);

    try {
        const targetCoraId = coraKeys[storeCnpj];

        const result = await coraApi.generatePix({
            amount: Math.round(amountToCharge * 100),
            code: `PED-${createdOrderNumber.value}`,
            customer: {
                name: orderHeader.value.customer_name,
                identity: identity
            }
        }, targetCoraId);

        pixState.qrCodeImage = result.qrCodeUrl;
        pixState.copyPaste = result.emv;
        pixState.invoiceId = result.id;

        if (createdOrderId.value) {
            await logBusinessEvent(
                'Financeiro',
                'Criação',
                `Gerou uma cobrança PIX instantânea no valor de ${formatCurrency(amountToCharge)} via integração Cora.`,
                { invoice_id: result.id, amount: amountToCharge },
                createdOrderId.value
            );
        }

        startPixPolling();

    } catch (e: any) {
        console.error('Erro Pix:', e);
        appStore.showSnackbar('Erro ao gerar QR Code Cora: ' + e.message, 'error');
        pixState.show = false;
    } finally {
        pixState.loading = false;
    }
};

const startPixPolling = () => {
    if (pixState.checkInterval) clearInterval(pixState.checkInterval);

    pixState.checkInterval = setInterval(async () => {
        if (!pixState.invoiceId || pixState.status === 'PAID') return;

        try {
            const res = await coraApi.checkStatus(pixState.invoiceId);
            if (res && res.status === 'PAID') {
                pixState.status = 'PAID';
                clearInterval(pixState.checkInterval!);

                await confirmPixPaymentInDb();

                appStore.showSnackbar('Pagamento Confirmado!', 'success');
            }
        } catch (err) { console.error('Erro polling pix', err); }
    }, 4000);
};

const confirmPixPaymentInDb = async () => {
    if (!createdOrderId.value) return;

    const pixMethod = paymentMethods.value.find(m => m.nome.toLowerCase().includes('pix') || m.nome.toLowerCase().includes('instantâneo'));
    const targetMethodId = pixMethod ? pixMethod.id : null;
    const targetBankId = defaultBankAccountId.value;

    const { data: receivables } = await supabase
        .from('finance_receivables')
        .select('*')
        .eq('order_id', createdOrderId.value);

    if (receivables && receivables.length > 0) {
        const receivablesToUpdate = receivables.filter(rec =>
            rec.status === 'em_aberto' ||
            (rec.status === 'pago' && !rec.bank_account_id)
        );

        for (const rec of receivablesToUpdate) {
            await supabase.from('finance_receivables').update({
                status: 'pago',
                paid_at: new Date().toISOString(),
                receipt_date: format(new Date(), 'yyyy-MM-dd'),
                bank_account_id: targetBankId,
                payment_method_id: targetMethodId || rec.payment_method_id,
                description: rec.description + ' (Confirmado via Pix)'
            }).eq('id', rec.id);

            await logBusinessEvent(
                'Financeiro',
                'Atualização',
                `O sistema detectou o pagamento do PIX e liquidou o título automaticamente.`,
                { receivable_id: rec.id, status: 'pago' },
                createdOrderId.value
            );
        }
    }
};

onMounted(init);
</script>

<style scoped lang="scss">
/* MANTÉM TODO ESTILO ORIGINAL */
.new-order-page { position: relative; min-height: 100vh; overflow-y: auto; overflow-x: hidden; }
.bg-background-dark { background: #0f0f13; }
.lh-1 { line-height: 1; }
.h-12 { height: 12px; } .h-16 { height: 16px; }
.gap-1 { gap: 4px; } .gap-2 { gap: 8px; } .gap-3 { gap: 12px; } .gap-4 { gap: 16px; }
.z-10 { position: relative; z-index: 10; } .z-20 { position: relative; z-index: 20; } .z-40 { position: relative; z-index: 40; } .z-50 { position: relative; z-index: 50; }
.shadow-soft { box-shadow: 0 4px 12px rgba(0,0,0,0.1); }
.shadow-sm { box-shadow: 0 1px 3px rgba(0,0,0,0.05); }
.border-thin { border-width: 1px !important; border-style: solid; border-color: rgba(var(--v-border-color), 0.08) !important; }
.background-carousel-wrapper { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 0; pointer-events: none; }
.background-overlay { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 1; background: radial-gradient(circle at center, rgba(15, 15, 19, 0.4), rgba(15, 15, 19, 0.95)); backdrop-filter: blur(8px); }
.glass-card { background: rgba(255, 255, 255, 0.03); backdrop-filter: blur(20px); -webkit-backdrop-filter: blur(20px); }
.glass-input :deep(.v-field__outline) { opacity: 0.2; }
.glass-input:hover :deep(.v-field__outline) { opacity: 0.5; }
.icon-glow { width: 80px; height: 80px; border-radius: 50%; display: flex; align-items: center; justify-content: center; }
.bg-primary-opacity { background: rgba(var(--v-theme-primary), 0.15); }
.border-primary-opacity { border: 1px solid rgba(var(--v-theme-primary), 0.3); }
.shadow-glow { box-shadow: 0 0 20px rgba(var(--v-theme-primary), 0.3); }
.bg-white-05 { background: rgba(255,255,255,0.05); }
.bg-glass-header { background: rgba(20,20,24,0.55); backdrop-filter: blur(14px); }
.text-white-50 { color: rgba(255,255,255,0.5); }
.text-white-70 { color: rgba(255,255,255,0.7); }
.border-white-05 { border-color: rgba(255,255,255,0.05) !important; }
.border-white-10 { border-color: rgba(255,255,255,0.1) !important; }
.border-bottom-white-05 { border-bottom: 1px solid rgba(255,255,255,0.08); }
.grid-store-layout { display: grid; grid-template-columns: 60px 80px minmax(200px, 1fr) 220px 160px 140px 100px; align-items: stretch; width: 100%; }
.cell { padding: 8px 10px; display: flex; align-items: center; border-right: 1px solid rgba(0,0,0,0.08); border-bottom: 1px solid rgba(0,0,0,0.08); min-height: 56px; overflow: hidden; }
.center { justify-content: center; text-align: center; }
.right { justify-content: flex-end; text-align: right; }
.grid-header .cell { min-height: 44px; font-size: 12px; font-weight: 900; text-transform: uppercase; letter-spacing: .6px; }
.grid-surface-light .cell { background: #f5f7fa; color: rgba(0,0,0,0.7); border-color: rgba(0,0,0,0.10); }
.grid-surface-dark .cell { background: rgba(255,255,255,0.08); color: rgba(255,255,255,0.80); border-color: rgba(255,255,255,0.10); }
.grid-row-light .cell { background: #fff; border-color: rgba(0,0,0,0.08); }
.grid-row-light:hover .cell { background: #f7fafc; cursor: pointer; }
.grid-row-dark .cell { background: rgba(255,255,255,0.04); border-color: rgba(255,255,255,0.08); }
.grid-row-dark:hover .cell { background: rgba(255,255,255,0.07); cursor: pointer; }
.kpi-bg-icon { position: absolute; right: -20px; bottom: -20px; opacity: 0.15; transform: rotate(-15deg); pointer-events: none; z-index: 0; }
.kpi-bg-icon .v-icon { font-size: 100px; color: white; }
.kpi-card { border: 1px solid rgba(255,255,255,0.15); color: white; min-height: 110px; position: relative; overflow: hidden; }
.kpi-rect { border-radius: 0 !important; }
.bg-gradient-info { background: linear-gradient(135deg, #0288d1, #005b9f); }
.bg-gradient-green { background: linear-gradient(135deg, #2e7d32, #1b5e20); }
.bg-gradient-success { background: linear-gradient(135deg, #00c853, #009624); }
.bg-gradient-purple { background: linear-gradient(135deg, #7b1fa2, #4a148c); }
.kpi-label { font-size: 12px; font-weight: 900; letter-spacing: .2px; }
.kpi-value { font-size: 22px; font-weight: 900; letter-spacing: .2px; }
.controls-bar { border: 1px solid rgba(0,0,0,0.08); border-radius: 0; padding: 10px; }
.controls-light { background: #ffffff; }
.controls-dark { background: rgba(30,30,35,0.55); backdrop-filter: blur(16px); border: 1px solid rgba(255,255,255,0.08); }
.search-wrap { height: 40px; border-radius: 0; padding: 0 12px; min-width: 360px; max-width: 520px; flex: 1 1 360px; }
.search-light { background: #f4f6f8; border: 1px solid rgba(0,0,0,0.08); }
.search-dark { background: rgba(255,255,255,0.08); border: 1px solid rgba(255,255,255,0.10); }
.clean-input { border: none; outline: none; background: transparent; font-size: 12px; color: inherit; padding: 0; }
.btn-rect { border-radius: 0 !important; text-transform: none !important; font-weight: 800; }
.pill-ref { font-size: 10px; font-weight: 900; font-family: monospace; background: rgba(0,0,0,0.06); padding: 4px 8px; border-radius: 6px; }
.list-text-11 { font-size: 11px !important; line-height: 1.25 !important; }
.list-text-10 { font-size: 10px !important; line-height: 1.25 !important; }
.solid-chip { display: inline-flex; align-items: center; justify-content: center; height: 22px; padding: 0 10px; border-radius: 8px; font-size: 10px; font-weight: 900; color: #fff; white-space: nowrap; }
.chip-info { background: #1976d2; }
.status-indicator { width: 10px; height: 10px; border-radius: 50%; }
.pulse { animation: pulse-green 2s infinite; }
@keyframes pulse-green { 0% { box-shadow: 0 0 0 0 rgba(0, 200, 83, 0.7); } 70% { box-shadow: 0 0 0 10px rgba(0, 200, 83, 0); } 100% { box-shadow: 0 0 0 0 rgba(0, 200, 83, 0); } }
.icon-circle-lg { width: 80px; height: 80px; border-radius: 50%; display: flex; align-items: center; justify-content: center; }
.animate-pop { animation: popIn 0.5s cubic-bezier(0.175, 0.885, 0.32, 1.275) forwards; }
@keyframes popIn { 0% { transform: scale(0.5); opacity: 0; } 100% { transform: scale(1); opacity: 1; } }
.fade-in { animation: fadeIn 0.3s ease-in; }
@keyframes fadeIn { from { opacity: 0; } to { opacity: 1; } }
.custom-scrollbar::-webkit-scrollbar { width: 6px; }
.custom-scrollbar::-webkit-scrollbar-track { background: transparent; }
.custom-scrollbar::-webkit-scrollbar-thumb { background: rgba(128, 128, 128, 0.2); border-radius: 3px; }
.icon-circle-xl { width: 100px; height: 100px; border-radius: 50%; display: flex; align-items: center; justify-content: center; }
.bg-green-gradient { background: linear-gradient(135deg, #43A047, #2E7D32); }
.bg-primary-gradient { background: linear-gradient(135deg, #1976D2, #1565C0); }
.scale-pop { animation: scalePop 0.6s cubic-bezier(0.175, 0.885, 0.32, 1.275); }
@keyframes scalePop { 0% { transform: scale(0.5); opacity: 0; } 50% { transform: scale(1.1); } 100% { transform: scale(1); opacity: 1; } }
.max-w-md { max-width: 400px; }
.max-w-sm { max-width: 300px; }
.absolute-corner { position: absolute; width: 20px; height: 20px; border-color: #1976D2; border-style: solid; }
.top-left { top: -1px; left: -1px; border-width: 3px 0 0 3px; border-radius: 4px 0 0 0; }
.top-right { top: -1px; right: -1px; border-width: 3px 3px 0 0; border-radius: 0 4px 0 0; }
.bottom-left { bottom: -1px; left: -1px; border-width: 0 0 3px 3px; border-radius: 0 0 0 4px; }
.bottom-right { bottom: -1px; right: -1px; border-width: 0 3px 3px 0; border-radius: 0 0 4px 0; }
</style>
