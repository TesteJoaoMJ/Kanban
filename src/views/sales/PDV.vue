<template>
  <div class="pdv-layout d-flex flex-column h-100 w-100 overflow-hidden" :class="isDark ? 'bg-grey-darken-4 text-white' : 'bg-background text-high-emphasis'" style="height: 100vh;">

    <div v-if="shouldBlockScreen" class="fill-height absolute w-100 h-100 z-50 d-flex flex-column custom-scroll" :class="isDark ? 'bg-glass-dark text-white' : 'bg-surface'">
        <div class="header-bar px-6 py-4 d-flex align-center justify-space-between flex-shrink-0 border-b" :class="isDark ? 'bg-glass-header border-bottom-white-05' : 'bg-surface-light border-grey-lighten-2'">
            <div class="d-flex flex-column">
                <div class="text-caption opacity-70 font-weight-black text-uppercase tracking-widest ls-1">Ponto de Venda > Seleção de Unidade</div>
                <div class="text-h5 font-weight-black mt-1" :class="isDark ? 'text-white' : 'text-primary'">Selecione a Loja (PDV)</div>
            </div>
            <v-btn variant="outlined" prepend-icon="mdi-arrow-left" class="btn-3d font-weight-bold" :color="isDark ? 'white' : 'primary'" @click="$router.push('/hub')">Voltar ao Hub</v-btn>
        </div>

        <div class="px-6 pt-6 pb-2 flex-shrink-0">
            <v-row>
              <v-col cols="12" sm="4" v-for="(kpi, idx) in storeKpis" :key="idx">
                <v-card class="kpi-card py-4 px-5 shadow-soft rounded-lg" :class="kpi.gradient" elevation="2">
                  <div class="kpi-bg-icon"><v-icon>{{ kpi.icon }}</v-icon></div>
                  <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                    <div class="d-flex align-center" style="gap: 8px;">
                      <v-icon size="20" class="opacity-80">{{ kpi.icon }}</v-icon>
                      <span class="kpi-label">{{ kpi.label }}</span>
                    </div>
                    <div class="kpi-number-group my-2">
                      <span class="kpi-value">{{ kpi.value }}</span>
                    </div>
                    <div class="kpi-footer opacity-80 text-[10px] font-weight-black text-uppercase tracking-widest">{{ kpi.footer }}</div>
                  </div>
                </v-card>
              </v-col>
            </v-row>
        </div>

        <div class="px-6 pt-4 pb-4 flex-shrink-0">
            <div class="d-flex align-center justify-space-between pa-3 rounded-lg border-thin" :class="isDark ? 'bg-grey-darken-3 border-white-10' : 'bg-grey-lighten-4'">
                <div class="d-flex align-center rounded border-thin px-3 shadow-sm" :class="isDark ? 'bg-grey-darken-4 border-white-10' : 'bg-white'" style="width: 400px; height: 44px;">
                  <v-icon :color="isDark ? 'white-70' : 'grey-darken-1'">mdi-magnify</v-icon>
                  <input v-model="searchStore" type="text" placeholder="Pesquisar unidade, cidade..." class="clean-input flex-grow-1 ml-2 font-weight-bold" :class="isDark ? 'text-white' : 'text-grey-darken-4'" />
                </div>
                <v-chip color="primary" variant="flat" class="font-weight-bold px-4 rounded chip-3d" size="large">
                    {{ filteredStores.length }} Unidades
                </v-chip>
            </div>
        </div>

        <div class="flex-grow-1 px-6 pb-6 overflow-hidden d-flex flex-column">
             <v-card class="flex-grow-1 d-flex flex-column rounded-lg border-thin overflow-hidden shadow-sm" :class="isDark ? 'bg-grey-darken-4 border-white-10' : 'bg-white'" elevation="0">
              <div class="flex-grow-1 overflow-y-auto custom-scroll">
                 <div class="grid-header sticky-head" :class="isDark ? 'grid-surface-dark' : 'grid-surface-light'" style="grid-template-columns: 60px 80px minmax(200px, 1fr) 220px 160px 140px 100px;">
                  <div class="cell center header-text">Status</div>
                  <div class="cell center header-text">ID</div>
                  <div class="cell header-text">Nome da Unidade</div>
                  <div class="cell header-text">Localização / Endereço</div>
                  <div class="cell header-text">Operador Caixa</div>
                  <div class="cell right header-text">Vendas Hoje</div>
                  <div class="cell center header-text">Ação</div>
                </div>

                <div v-for="(store, idx) in filteredStores" :key="store.id" class="grid-row hover-bg-row cursor-pointer transition-all" :class="[isDark ? 'grid-row-dark' : 'grid-row-light', zebraClass(idx)]" style="grid-template-columns: 60px 80px minmax(200px, 1fr) 220px 160px 140px 100px;" @click="handleAdminStoreSelection(store)">
                    <div class="cell center"><div class="status-indicator shadow-sm" :class="store.active_session_user ? 'bg-success pulse' : 'bg-grey'"></div></div>
                    <div class="cell center"><span class="pill-ref">{{ String(store.id).substring(0,4).toUpperCase() }}</span></div>
                    <div class="cell font-weight-black text-body-2 text-uppercase">{{ store.name }}</div>
                    <div class="cell text-caption"><v-icon size="14" class="mr-1 opacity-70">mdi-map-marker-outline</v-icon>{{ store.address || 'Matriz Principal' }}</div>
                    <div class="cell">
                        <v-chip v-if="store.active_session_user" size="small" color="info" variant="flat" class="font-weight-bold rounded-sm chip-3d"><v-icon start size="12">mdi-account-tie</v-icon>{{ store.active_session_user }}</v-chip>
                        <span v-else class="text-caption opacity-50 font-weight-bold font-italic">Fechado</span>
                    </div>
                    <div class="cell right font-mono font-weight-black text-body-1" :class="adminStoreStats[store.id] > 0 ? 'text-success-darken-1' : ''">{{ formatCurrency(adminStoreStats[store.id] || 0) }}</div>
                    <div class="cell center"><v-btn size="small" color="primary" variant="flat" class="btn-3d font-weight-black tracking-widest" width="100">ACESSAR</v-btn></div>
                </div>
              </div>
            </v-card>
        </div>
    </div>

    <template v-else>
        <v-toolbar density="compact" elevation="1" class="px-3 flex-shrink-0 border-b z-20 relative" :color="isDark ? '#1a1a1f' : 'surface'">
          <div class="d-flex align-center text-caption font-weight-bold" :class="isDark ? 'text-white' : 'text-grey-darken-2'">
            <v-icon size="small" class="mr-2" :color="isDark ? 'blue-lighten-2' : 'primary'">mdi-store</v-icon>

            <span class="d-none d-sm-inline text-uppercase tracking-widest ls-1">
                {{ userStore.activeStoreName || 'SANTOS & LOPES' }}
            </span>
            <v-btn v-if="userStore.isAdmin" size="x-small" variant="flat" :color="isDark ? 'blue-darken-3' : 'primary'" class="btn-3d ml-3 font-weight-black" @click="resetAdminStore">
                <v-icon start size="12">mdi-swap-horizontal</v-icon> TROCAR LOJA
            </v-btn>

            <v-icon size="small" class="mx-2 d-none d-sm-inline opacity-50">mdi-chevron-right</v-icon>
            <span class="font-weight-black text-uppercase tracking-widest ls-1 opacity-70">PDV Varejo</span>

            <v-chip v-if="isScannerReady" size="x-small" color="success" variant="flat" class="chip-3d ml-4 font-weight-bold text-uppercase" label>
              <v-icon start size="small" class="icon-pulse">mdi-barcode-scan</v-icon>
              Leitor Ativo
            </v-chip>
          </div>

          <v-spacer></v-spacer>

          <v-menu location="bottom end" :close-on-content-click="false">
            <template v-slot:activator="{ props }">
                <v-btn v-bind="props" variant="flat" size="small" class="btn-3d mr-3 font-weight-bold" :color="activePriceList ? 'warning' : (isDark ? 'blue-grey-darken-3' : 'primary-lighten-1')">
                  <v-icon start size="small">{{ activePriceList ? 'mdi-tag-text' : 'mdi-tag-outline' }}</v-icon>
                  {{ activePriceList ? activePriceList.name : 'Tabela: Varejo (Padrão)' }}
                  <v-icon end size="small">mdi-chevron-down</v-icon>
                </v-btn>
            </template>
            <v-list density="compact" class="pa-2 rounded-lg border-thin shadow-lg" width="280" :bg-color="isDark ? 'grey-darken-4' : 'white'">
                <div class="text-[10px] opacity-70 font-weight-black text-uppercase tracking-widest mb-2 px-2">Selecione a Tabela</div>
                <v-list-item @click="selectPriceList(null)" :active="!activePriceList" class="rounded-lg mb-1" :color="isDark ? 'white' : 'primary'">
                    <template v-slot:prepend><v-icon size="small">mdi-store-outline</v-icon></template>
                    <v-list-item-title class="font-weight-bold">Varejo (Preço Base)</v-list-item-title>
                </v-list-item>
                <v-list-item v-for="list in priceLists" :key="list.id" @click="selectPriceList(list)" :active="activePriceList?.id === list.id" color="warning" class="rounded-lg mb-1">
                    <template v-slot:prepend><v-icon size="small" color="warning">mdi-star-circle-outline</v-icon></template>
                    <v-list-item-title class="font-weight-bold">{{ list.name }}</v-list-item-title>
                </v-list-item>

                <v-divider class="my-2 border-dashed"></v-divider>

                <v-list-item @click="openPriceListConfig" color="info" class="rounded-lg bg-info-lighten-5">
                    <template v-slot:prepend><v-icon size="small" color="info">mdi-cog-outline</v-icon></template>
                    <v-list-item-title class="font-weight-bold text-info-darken-1">Configurar Tabelas</v-list-item-title>
                </v-list-item>
            </v-list>
          </v-menu>

          <v-menu location="bottom end" :close-on-content-click="false">
            <template v-slot:activator="{ props }">
                <v-btn v-bind="props" variant="outlined" size="small" class="btn-3d mr-3 font-weight-bold" :color="isDark ? 'grey-lighten-1' : 'grey-darken-2'">
                  <v-icon start size="small">mdi-printer-settings</v-icon>
                  Setup Impressão
                </v-btn>
            </template>
            <v-card class="pa-4 rounded-lg border-thin shadow-lg" width="320" :class="isDark ? 'bg-grey-darken-4' : 'bg-white'">
                <div class="text-subtitle-2 font-weight-bold mb-3 d-flex align-center">
                    <v-icon size="small" class="mr-2" color="primary">mdi-printer</v-icon> Setup Fiscal & Impressão
                </div>
                <div class="mb-3">
                    <span class="text-caption font-weight-bold text-uppercase mb-2 d-block tracking-widest opacity-70">Formato da Bobina</span>
                    <v-btn-toggle v-model="printFormat" mandatory density="compact" color="primary" class="w-100 d-flex flex-wrap border rounded-sm" variant="outlined" divided>
                        <v-btn value="80mm" class="flex-grow-1 text-caption font-weight-bold">80mm</v-btn>
                        <v-btn value="58mm" class="flex-grow-1 text-caption font-weight-bold">58mm</v-btn>
                    </v-btn-toggle>
                </div>
                <v-switch v-model="alwaysGenerateNfce" color="primary" label="Gerar NFC-e por Padrão" density="compact" hide-details class="mb-2 font-weight-medium"></v-switch>
                <v-divider class="my-3 border-dashed"></v-divider>
                <v-btn block size="small" color="primary" variant="flat" class="btn-3d font-weight-bold tracking-widest" @click="handleTestPrint" :loading="isTestingPrint">
                    Imprimir Teste / Preview
                </v-btn>
            </v-card>
          </v-menu>

          <v-divider vertical class="mx-2 my-2 opacity-20"></v-divider>

          <div class="d-flex align-center px-2 mr-2">
              <v-icon :color="isDark ? 'blue-lighten-2' : 'primary'" size="small" class="mr-2">mdi-clock-outline</v-icon>
              <span class="font-weight-bold text-caption font-mono opacity-80">{{ realTimeClock }}</span>
          </div>

          <v-btn
            size="small"
            :color="cashStore.isSessionOpen ? 'success' : 'error'"
            variant="flat"
            class="btn-3d font-weight-black text-none px-4 tracking-widest"
            @click="cashStore.isSessionOpen ? showCashClosingModal = true : showCashOpeningModal = true"
          >
            <v-icon start size="small">{{ cashStore.isSessionOpen ? 'mdi-lock-open-variant' : 'mdi-lock' }}</v-icon>
            {{ cashStore.isSessionOpen ? 'Caixa Aberto' : 'Caixa Fechado' }}
          </v-btn>
        </v-toolbar>

        <div class="d-flex flex-grow-1 overflow-hidden h-100 w-100 relative">

          <template v-if="orderCreatedSuccess">
              <div class="w-100 h-100 absolute d-flex align-center justify-center pa-4 fade-in z-50" :class="isDark ? 'bg-grey-darken-4' : 'bg-background'">
                   <v-card class="rounded-xl elevation-12 border-thin w-100 h-100 d-flex flex-column flex-md-row overflow-hidden shadow-xl" :class="isDark ? 'bg-grey-darken-4' : 'bg-surface'" max-width="1200" max-height="700">

                       <div class="d-flex flex-column pa-8 border-e relative overflow-hidden" :class="isDark ? 'bg-grey-darken-3 border-white-10' : 'bg-grey-lighten-5'" style="flex: 1; min-width: 320px;">
                           <div v-if="pixState.status === 'PAID'" class="particle-burst"></div>

                           <div class="d-flex align-center justify-center mb-6 mt-4 relative z-10">
                                <div class="icon-circle-xl elevation-4 transition-all" :class="pixState.status === 'PAID' ? 'bg-green-gradient scale-pop' : 'bg-primary-gradient'">
                                    <v-icon size="56" color="white">{{ pixState.status === 'PAID' ? 'mdi-check-all' : 'mdi-check' }}</v-icon>
                                </div>
                           </div>

                           <div class="text-center mb-8 relative z-10">
                               <h2 class="text-h4 font-weight-black mb-1 tracking-tight">{{ pixState.status === 'PAID' ? 'Pagamento Confirmado!' : 'Venda Registrada' }}</h2>
                               <div class="text-h5 font-weight-bold font-mono mb-2" :class="pixState.status === 'PAID' ? 'text-success' : 'text-primary'">
                                   #{{ String(createdOrderNumber).padStart(4, '0') }}
                               </div>
                               <div v-if="pixState.status === 'PAID'" class="d-flex justify-center mt-4">
                                   <div class="py-2 px-4 rounded-lg d-flex align-center gap-2" :class="isDark ? 'bg-green-darken-4 text-white' : 'bg-green-lighten-5 border border-green-lighten-3'">
                                       <v-icon :color="isDark ? 'white' : 'success'" size="20">mdi-bank-check</v-icon>
                                       <div class="d-flex flex-column text-left">
                                           <span class="text-[10px] font-weight-black text-uppercase" :class="isDark ? 'text-green-lighten-4' : 'text-green-darken-3'">Status Financeiro</span>
                                           <span class="text-body-2 font-weight-bold" :class="isDark ? 'text-white' : 'text-green-darken-4'">Conciliado (Cora)</span>
                                       </div>
                                   </div>
                               </div>
                               <p v-else-if="pixState.show" class="text-body-2 opacity-70 mt-2">Aguardando pagamento via Pix...</p>
                               <p v-else class="text-body-2 opacity-70 mt-2">A venda foi enviada para faturamento na gestão de pedidos.</p>
                           </div>

                           <div class="mt-auto d-flex flex-column gap-3 relative z-10">
                                <v-btn block size="large" color="primary" variant="flat" class="btn-3d font-weight-black text-none text-white" @click="handleGenerateNonFiscalReceipt(false)" :loading="isPdfGenerating">
                                    <v-icon start size="20">mdi-printer</v-icon>
                                    Imprimir Recibo (Sem Valor Fiscal)
                                </v-btn>

                                <v-btn v-if="lastGeneratedNfceData" block size="x-large" color="deep-orange" variant="flat" class="btn-3d font-weight-black text-none" @click="handleGenerateReceipt" :loading="isPdfGenerating">
                                    <v-icon start size="24">mdi-receipt-text-check</v-icon>
                                    Baixar PDF NFC-e
                                </v-btn>

                                <v-btn block size="large" variant="outlined" class="btn-3d font-weight-bold text-none" :class="isDark ? 'border-white-20 text-white' : 'border-opacity-25'" @click="resetFormState">
                                    <v-icon start>mdi-plus</v-icon> Nova Venda (Esc)
                                </v-btn>
                           </div>
                       </div>

                       <div class="d-flex flex-column align-center justify-center pa-8" :class="isDark ? 'bg-grey-darken-4' : 'bg-white'" style="flex: 1.5; min-width: 400px;">
                            <div v-if="pixState.loading" class="d-flex flex-column align-center text-center">
                                <v-progress-circular indeterminate color="primary" size="80" width="6"></v-progress-circular>
                                <h3 class="text-h6 mt-6 font-weight-bold text-primary">Gerando Cobrança Pix...</h3>
                                <p class="text-caption opacity-70">Conectando ao Banco Cora</p>
                            </div>

                            <div v-else-if="pixState.show && pixState.status !== 'PAID'" class="w-100 h-100 d-flex flex-column align-center animate-pop py-4">
                                <div class="text-center mb-2 flex-shrink-0">
                                    <span class="text-overline font-weight-bold opacity-70 d-block lh-1 tracking-widest ls-1">TOTAL A PAGAR</span>
                                    <div class="text-h3 font-weight-black text-primary lh-1 mt-1 font-mono">{{ pixState.displayValue }}</div>
                                </div>

                                <div class="flex-grow-1 d-flex align-center justify-center w-100 relative my-2 overflow-hidden px-4">
                                     <div class="pa-4 rounded-lg border-xl bg-white shadow-sm relative d-flex align-center justify-center" :class="isDark ? 'border-blue-darken-3' : 'border-primary-lighten-4'" style="width: 320px; height: 320px;">
                                         <div class="absolute-corner top-left"></div><div class="absolute-corner top-right"></div>
                                         <div class="absolute-corner bottom-left"></div><div class="absolute-corner bottom-right"></div>
                                         <img :src="pixState.qrCodeImage" style="width: 100%; height: 100%; object-fit: contain;" class="d-block" />
                                     </div>
                                </div>

                                <div class="w-100 px-4 flex-shrink-0" style="max-width: 450px;">
                                    <v-text-field :model-value="pixState.copyPaste" readonly variant="outlined" density="compact" :bg-color="isDark ? 'grey-darken-3' : 'grey-lighten-5'" hide-details class="mb-3 font-mono text-caption font-weight-bold rounded-lg" append-inner-icon="mdi-content-copy" @click:append-inner="copyPixCode"></v-text-field>
                                    <div class="text-center pb-2">
                                        <span class="text-caption font-weight-bold text-blue-darken-3 d-flex align-center justify-center gap-2">
                                            <v-progress-circular indeterminate color="blue" size="14" width="2"></v-progress-circular>
                                            Aguardando banco (Polling automático)...
                                        </span>
                                    </div>
                                </div>
                            </div>

                            <div v-else-if="pixState.status === 'PAID'" class="d-flex flex-column align-center justify-center h-100 text-center animate-pop">
                                 <div class="icon-circle-lg mb-6" :class="isDark ? 'bg-green-darken-4' : 'bg-green-lighten-5'"><v-icon size="48" color="success">mdi-cash-check</v-icon></div>
                                 <h3 class="text-h5 font-weight-black mb-2" :class="isDark ? 'text-white' : 'text-grey-darken-3'">Transação Concluída</h3>
                                 <p class="text-body-1 opacity-70 mb-6 max-w-sm">O pagamento de <strong>{{ pixState.displayValue }}</strong> foi identificado automaticamente no Banco Cora.</p>
                            </div>

                            <div v-else class="d-flex flex-column align-center justify-center opacity-40 h-100">
                                <v-icon size="80" class="mb-6 opacity-50">mdi-check-circle-outline</v-icon>
                                <div class="text-h6 font-weight-bold">Venda Finalizada</div>
                                <p class="text-caption">Pronta para faturamento no painel de gestão.</p>
                            </div>
                       </div>
                   </v-card>
              </div>
          </template>

          <template v-else>
              <div class="d-flex flex-column flex-grow-1 h-100 position-relative border-e" :class="isDark ? 'bg-grey-darken-4 border-white-10' : 'bg-surface'" style="min-width: 0;">

                <div class="px-4 py-3 border-b d-flex flex-column gap-3" :class="isDark ? 'bg-grey-darken-3 border-white-10' : 'bg-surface-light'">
                    <div class="d-flex align-center gap-3">
                      <div style="flex: 2; min-width: 200px;">
                          <v-text-field
                            v-model="productSearch"
                            density="compact"
                            variant="outlined"
                            placeholder="Buscar SKU, código de barras ou nome (F2)..."
                            prepend-inner-icon="mdi-magnify"
                            hide-details
                            class="rounded-lg font-weight-medium ui-field"
                            :bg-color="isDark ? 'grey-darken-4' : 'surface'"
                            clearable
                            ref="searchRef"
                          ></v-text-field>
                      </div>
                      <div style="flex: 1; min-width: 140px;">
                          <v-select
                              v-model="filterCategory"
                              :items="categoriesList"
                              label="Categoria"
                              density="compact"
                              variant="outlined"
                              hide-details
                              class="rounded-lg font-weight-medium ui-field"
                              :bg-color="isDark ? 'grey-darken-4' : 'surface'"
                              clearable
                          ></v-select>
                      </div>
                      <v-btn icon size="small" variant="flat" class="btn-3d" @click="syncAllData(true)" :loading="isSyncingProducts" color="primary">
                          <v-icon>mdi-refresh</v-icon>
                          <v-tooltip activator="parent" location="bottom">Sincronizar Produtos</v-tooltip>
                      </v-btn>
                    </div>

                    <div class="d-flex align-center justify-space-between flex-wrap gap-2">
                        <v-chip-group v-model="stockFilter" mandatory selected-class="bg-primary text-white font-weight-black chip-3d" class="filter-chips" density="compact">
                          <v-chip value="all" filter variant="outlined" class="rounded-lg font-weight-bold tracking-widest" size="small" :color="isDark ? 'white' : 'primary'">Todos</v-chip>
                          <v-chip value="in_stock" filter variant="outlined" class="rounded-lg font-weight-bold tracking-widest" size="small" :color="isDark ? 'white' : 'primary'">Com Estoque</v-chip>
                        </v-chip-group>
                        <div class="text-caption opacity-70 font-weight-black tracking-widest font-mono border-thin rounded-lg px-2 py-1" :class="isDark ? 'bg-grey-darken-4 border-white-10' : 'bg-surface'">
                            {{ filteredProducts.length }} itens listados
                        </div>
                    </div>
                </div>

                <div class="flex-grow-1 overflow-y-auto pa-4 custom-scroll" :class="isDark ? 'bg-grey-darken-4' : 'bg-grey-lighten-4'">
                    <v-row v-if="isLoadingProducts" dense>
                      <v-col v-for="n in 12" :key="n" cols="12" sm="6" md="4" lg="3" xl="2">
                        <v-skeleton-loader type="card" class="rounded-lg border-thin" :color="isDark ? 'grey-darken-3' : 'white'" elevation="0"></v-skeleton-loader>
                      </v-col>
                    </v-row>

                    <div v-else-if="filteredProducts.length === 0" class="fill-height d-flex flex-column align-center justify-center opacity-50">
                      <v-icon size="64" class="mb-4 opacity-40">mdi-package-variant-closed</v-icon>
                      <span class="text-body-2 font-weight-black text-uppercase tracking-widest opacity-70">Catálogo Vazio</span>
                    </div>

                    <v-row v-else dense class="product-grid-gap">
                      <v-col v-for="product in filteredProducts" :key="product.id" cols="12" sm="6" md="4" lg="3" xl="2">
                        <v-hover v-slot="{ isHovering, props }">
                          <v-card
                            v-bind="props"
                            class="product-card h-100 d-flex flex-column rounded-lg transition-all"
                            :elevation="isHovering ? 6 : 0"
                            :class="{
                                'border-primary shadow-soft': isHovering,
                                'opacity-60': product.quantity_in_stock <= 0,
                                'bg-grey-darken-3 border-white-10 border-thin': isDark,
                                'bg-white border-thin': !isDark
                            }"
                            @click="openSizeModal(product)"
                            v-ripple
                          >
                            <div v-if="getCartQuantity(product) > 0" class="cart-badge">
                                <v-chip color="primary" variant="flat" size="small" class="font-weight-black px-2 rounded-lg chip-3d">{{ getCartQuantity(product) }}</v-chip>
                            </div>

                            <div v-if="product.discountPct > 0" class="discount-ribbon">
                                <v-chip color="warning" size="x-small" variant="flat" class="font-weight-black rounded-r-pill chip-3d">-{{ product.discountPct }}%</v-chip>
                            </div>

                            <div class="product-image-wrapper position-relative border-b" :class="isDark ? 'bg-grey-darken-4 border-white-10' : 'bg-grey-lighten-3'">
                              <v-img :src="product.photo_url || '/placeholder.png'" aspect-ratio="1" cover class="product-img"></v-img>
                              <div v-if="product.quantity_in_stock <= 0" class="stock-overlay d-flex align-center justify-center backdrop-blur">
                                <v-chip color="error" variant="flat" size="small" class="font-weight-bold text-uppercase tracking-widest rounded-lg chip-3d">Esgotado</v-chip>
                              </div>
                              <div class="absolute-bottom-info pa-2 d-flex justify-end align-end w-100">
                                  <v-chip size="x-small" :color="getStockColor(product.quantity_in_stock)" variant="flat" class="font-weight-black rounded-lg px-2 chip-3d font-mono">
                                      {{ product.quantity_in_stock }} {{ product.unit_of_measure }}
                                  </v-chip>
                              </div>
                            </div>

                            <div class="pa-3 d-flex flex-column flex-grow-1 justify-space-between">
                              <div class="mb-2">
                                  <div class="text-[10px] opacity-70 text-uppercase font-weight-bold mb-1 font-mono tracking-widest">
                                      <v-icon size="12" class="mr-1">mdi-barcode</v-icon>
                                      {{ product.sku && product.sku !== 'null' ? product.sku : 'SEM CÓDIGO' }}
                                  </div>
                                  <div class="text-caption font-weight-black line-clamp-2 lh-1 text-uppercase" :title="product.name" :class="isDark ? 'text-white' : 'text-high-emphasis'">
                                      {{ product.name }}
                                  </div>
                              </div>
                              <div class="pt-2 border-t border-dashed mt-auto d-flex align-end justify-space-between" :class="isDark ? 'border-white-20' : 'border-grey-lighten-2'">
                                <div class="d-flex flex-column">
                                    <span v-if="product.hasActivePrice" class="text-[10px] text-decoration-line-through opacity-60 mb-n1">{{ formatCurrency(product.base_price) }}</span>
                                    <span class="text-subtitle-2 font-weight-black font-mono" :class="product.hasActivePrice ? 'text-warning' : (isDark ? 'text-blue-lighten-2' : 'text-primary')">
                                      {{ formatCurrency(product.active_price) }}
                                    </span>
                                </div>
                                <v-btn icon size="x-small" color="primary" variant="flat" class="btn-3d rounded-lg"><v-icon>mdi-plus</v-icon></v-btn>
                              </div>
                            </div>
                          </v-card>
                        </v-hover>
                      </v-col>
                    </v-row>
                </div>
              </div>

              <div class="d-flex flex-column h-100 z-10" :class="isDark ? 'bg-grey-darken-3' : 'bg-surface border-s border-thin'" style="width: 440px; min-width: 400px;">
                <div class="pa-4 border-b flex-shrink-0" :class="isDark ? 'bg-grey-darken-4 border-white-10' : 'bg-surface'">
                   <div class="d-flex align-center justify-space-between mb-4">
                      <div class="d-flex align-center gap-3">
                          <div class="icon-box-sm rounded-lg d-flex align-center justify-center border" :class="isDark ? 'bg-blue-darken-4 text-white border-blue-darken-2' : 'bg-primary-lighten-5 text-primary border-primary-lighten-4'" style="width: 40px; height: 40px;">
                              <v-icon size="24">mdi-cart-outline</v-icon>
                          </div>
                          <div>
                              <div class="text-[10px] font-weight-bold text-uppercase opacity-70 tracking-widest lh-1 ls-1">Nova Venda</div>
                              <div class="text-subtitle-1 font-weight-black font-mono lh-1 mt-1" :class="isDark ? 'text-blue-lighten-2' : 'text-primary'">#{{ nextOrderNumber }}</div>
                          </div>
                      </div>

                      <v-menu location="bottom end">
                        <template v-slot:activator="{ props }">
                          <v-btn v-bind="props" icon variant="outlined" size="small" class="btn-3d" :color="isDark ? 'grey-lighten-1' : 'grey-darken-2'"><v-icon>mdi-dots-vertical</v-icon></v-btn>
                        </template>
                        <v-list density="compact" class="rounded-lg border-thin shadow-lg" width="220" :bg-color="isDark ? '#1E1E24' : 'white'">
                           <v-list-subheader class="text-[10px] text-uppercase font-weight-black tracking-widest opacity-70">Ações do Pedido</v-list-subheader>
                           <v-list-item @click="clearCart" :disabled="cart.length === 0" color="error" class="rounded-sm hover-bg-grey-lighten-5">
                              <template v-slot:prepend><v-icon size="small" color="error">mdi-delete-sweep</v-icon></template>
                              <v-list-item-title class="font-weight-bold text-error text-caption">Limpar Venda (Esc)</v-list-item-title>
                           </v-list-item>
                           <v-list-item @click="saveDraft" :disabled="cart.length === 0" class="rounded-sm hover-bg-grey-lighten-5">
                              <template v-slot:prepend><v-icon size="small">mdi-content-save-outline</v-icon></template>
                              <v-list-item-title class="text-caption font-weight-bold">Salvar Rascunho</v-list-item-title>
                           </v-list-item>
                           <v-list-item @click="openDraftsModal" class="rounded-sm hover-bg-grey-lighten-5">
                              <template v-slot:prepend><v-icon size="small">mdi-folder-open-outline</v-icon></template>
                              <v-list-item-title class="text-caption font-weight-bold">Carregar Rascunho</v-list-item-title>
                           </v-list-item>
                           <v-divider class="my-2 border-dashed"></v-divider>
                           <v-list-subheader class="text-[10px] text-uppercase font-weight-black tracking-widest opacity-70">Operações Caixa</v-list-subheader>
                           <v-list-item @click="showOperationsModal = true; operationType = 'supply'" class="rounded-sm hover-bg-grey-lighten-5">
                              <template v-slot:prepend><v-icon size="small" color="success">mdi-cash-plus</v-icon></template>
                              <v-list-item-title class="text-caption font-weight-bold text-success-darken-1">Suprimento (Entrada)</v-list-item-title>
                           </v-list-item>
                           <v-list-item @click="showOperationsModal = true; operationType = 'bleed'" class="rounded-sm hover-bg-grey-lighten-5">
                              <template v-slot:prepend><v-icon size="small" color="error">mdi-cash-minus</v-icon></template>
                              <v-list-item-title class="text-caption font-weight-bold text-error">Sangria (Saída)</v-list-item-title>
                           </v-list-item>
                           <v-list-item @click="showCashClosingModal = true" class="rounded-sm hover-bg-grey-lighten-5">
                              <template v-slot:prepend><v-icon size="small" color="warning">mdi-lock</v-icon></template>
                              <v-list-item-title class="text-caption font-weight-bold text-warning-darken-2">Fechar Caixa</v-list-item-title>
                           </v-list-item>
                        </v-list>
                      </v-menu>
                   </div>

                   <v-btn-toggle v-model="activeTab" mandatory class="w-100 border-thin rounded-lg shadow-sm" color="primary" density="compact" variant="outlined" divided>
                      <v-btn value="items" class="flex-grow-1 text-caption font-weight-black tracking-widest text-none">CARRINHO ({{ cartItemCount }})</v-btn>
                      <v-btn value="payment" class="flex-grow-1 text-caption font-weight-black tracking-widest text-none" :disabled="cart.length === 0">PAGAMENTO</v-btn>
                   </v-btn-toggle>
                </div>

                <div v-if="activeTab === 'items'" class="d-flex flex-column flex-grow-1 overflow-hidden">
                     <div class="px-4 pt-4 pb-2 flex-shrink-0 border-b border-dashed" :class="isDark ? 'bg-grey-darken-4 border-white-20' : 'bg-white'">

                        <div class="d-flex align-center gap-2">
                            <v-autocomplete
                                v-model="selectedCustomer"
                                :items="clientList"
                                item-title="nome"
                                item-value="id"
                                placeholder="Buscar Cliente..."
                                variant="outlined"
                                density="compact"
                                prepend-inner-icon="mdi-account-search"
                                :loading="isSearchingClients"
                                @update:search="handleClientSearch"
                                return-object
                                hide-details
                                class="rounded-lg font-weight-bold ui-field flex-grow-1"
                                :bg-color="isDark ? 'grey-darken-3' : 'surface'"
                                clearable
                                no-data-text="Digite p/ buscar no banco"
                            ></v-autocomplete>

                            <v-tooltip text="Cadastrar Novo Cliente Rápido" location="top">
                                <template v-slot:activator="{ props }">
                                    <v-btn v-bind="props" icon="mdi-account-plus" color="success" variant="tonal" class="btn-3d flex-shrink-0 rounded-lg" height="40" width="40" @click="quickClientModal.show = true"></v-btn>
                                </template>
                            </v-tooltip>
                        </div>

                        <v-expand-transition>
                            <div v-if="!selectedCustomer" class="mt-3 pa-3 rounded-lg border border-dashed d-flex align-center justify-space-between" :class="isDark ? 'bg-grey-darken-3 border-white-20' : 'bg-grey-lighten-4'">
                                <div class="d-flex align-center gap-2">
                                    <v-icon size="small" class="opacity-70">mdi-incognito</v-icon>
                                    <span class="text-[11px] font-weight-bold text-uppercase opacity-70 tracking-widest">Venda Anônima</span>
                                </div>
                                <v-chip size="small" :color="isDark ? 'grey-darken-1' : 'grey-darken-2'" variant="flat" class="font-weight-black chip-3d">CONSUMIDOR FINAL</v-chip>
                            </div>
                        </v-expand-transition>

                        <v-expand-transition>
                            <div v-if="!selectedCustomer || selectedCustomer.nome === 'Consumidor Final' || !selectedCustomer.cpf_cnpj" class="mt-3">
                                <v-text-field
                                    v-model="cpfNota"
                                    label="CPF/CNPJ na Nota (Opcional)"
                                    density="compact"
                                    variant="outlined"
                                    hide-details
                                    class="rounded-lg font-weight-bold ui-field font-mono"
                                    :bg-color="isDark ? 'grey-darken-3' : 'surface'"
                                    prepend-inner-icon="mdi-card-account-details-outline"
                                    v-maska="['###.###.###-##', '##.###.###/####-##']"
                                ></v-text-field>
                            </div>
                        </v-expand-transition>

                        <v-autocomplete
                            v-model="selectedSeller"
                            :items="salespeopleList"
                            item-title="nome"
                            item-value="id"
                            placeholder="Vendedor (Opcional)"
                            variant="outlined"
                            density="compact"
                            prepend-inner-icon="mdi-badge-account-horizontal-outline"
                            hide-details
                            class="mt-3 rounded-lg font-weight-bold ui-field"
                            :bg-color="isDark ? 'grey-darken-3' : 'surface'"
                            clearable
                        ></v-autocomplete>
                     </div>

                     <div class="flex-grow-1 overflow-y-auto px-4 py-3 custom-scroll" :class="isDark ? 'bg-grey-darken-4' : 'bg-grey-lighten-5'">
                        <v-scale-transition group>
                            <div v-for="(item, index) in cart" :key="item.product_id + '_' + index" class="mb-3 pa-3 rounded-lg border-thin shadow-sm d-flex align-center gap-3 border-s-xl border-s-primary" :class="isDark ? 'bg-grey-darken-3' : 'bg-white'">
                                <v-avatar rounded="lg" size="48" class="border-thin"><v-img :src="item.photo_url || '/placeholder.png'" cover></v-img></v-avatar>
                                <div class="flex-grow-1 overflow-hidden">
                                    <div class="text-caption font-weight-black text-uppercase text-truncate lh-1 mb-1">
                                        {{ item.product_name }}
                                        <v-chip v-if="item.size && item.size !== 'U'" size="x-small" color="primary" variant="flat" class="ml-1 font-weight-bold chip-3d">Tam: {{ item.size }}</v-chip>
                                    </div>
                                    <div class="text-[11px] font-weight-bold opacity-70 font-mono tracking-widest d-flex align-center">
                                        {{ formatCurrency(item.unit_price) }}
                                        <v-icon v-if="activePriceList" size="10" color="warning" class="ml-1" title="Tabela Customizada">mdi-tag-text</v-icon>
                                    </div>
                                </div>
                                <div class="d-flex flex-column align-end gap-1">
                                    <div class="text-body-2 font-weight-black lh-1 font-mono" :class="isDark ? 'text-blue-lighten-2' : 'text-primary'">{{ formatCurrency(item.total_price) }}</div>
                                    <div class="d-flex align-center rounded-lg border-thin px-1 mt-1" :class="isDark ? 'bg-grey-darken-4' : 'bg-grey-lighten-4'">
                                        <v-btn icon="mdi-minus" size="x-small" variant="text" density="compact" class="opacity-70" @click="updateCartQuantity(index, -1)"></v-btn>
                                        <span class="text-caption font-weight-black mx-2 font-mono">{{ item.quantity }}</span>
                                        <v-btn icon="mdi-plus" size="x-small" variant="text" density="compact" class="opacity-70" @click="updateCartQuantity(index, 1)"></v-btn>
                                    </div>
                                </div>
                            </div>
                        </v-scale-transition>

                        <div v-if="cart.length === 0" class="fill-height d-flex flex-column align-center justify-center opacity-40 py-12">
                            <v-icon size="64" class="mb-3">mdi-cart-off</v-icon>
                            <span class="text-caption font-weight-black text-uppercase tracking-widest">Carrinho Vazio</span>
                        </div>
                     </div>

                     <div class="pa-4 border-t flex-shrink-0 shadow-up" :class="isDark ? 'bg-grey-darken-4 border-white-10' : 'bg-white'">
                        <div class="d-flex justify-space-between align-end mb-4">
                            <span class="text-caption font-weight-black text-uppercase opacity-70 tracking-widest ls-1">Subtotal Estimado</span>
                            <span class="text-h4 font-weight-black lh-1 font-mono" :class="isDark ? 'text-blue-lighten-2' : 'text-primary'">{{ formatCurrency(subtotal) }}</span>
                        </div>
                        <v-btn block size="x-large" color="primary" class="font-weight-black tracking-widest rounded-lg text-none btn-3d" @click="activeTab = 'payment'" :disabled="cart.length === 0">
                            AVANÇAR PAGAMENTO <v-icon end>mdi-arrow-right</v-icon>
                        </v-btn>
                     </div>
                </div>

                <div v-if="activeTab === 'payment'" class="d-flex flex-column flex-grow-1 overflow-hidden">
                    <div class="flex-grow-1 overflow-y-auto px-4 py-4 custom-scroll" :class="isDark ? 'bg-grey-darken-4' : 'bg-grey-lighten-5'">

                        <div class="mb-6">
                            <span class="text-[10px] font-weight-black text-uppercase opacity-70 mb-2 d-block tracking-widest ls-1">Pagamento Rápido</span>
                            <div class="d-flex flex-wrap gap-2 mb-3">
                                <v-btn v-for="q in quickPaymentOptions" :key="q.id" @click="applyQuickPayment(q)" variant="tonal" color="primary" size="small" class="flex-grow-1 font-weight-black tracking-widest rounded-lg text-none btn-3d">
                                    <v-icon start size="small">{{ q.icon }}</v-icon> {{ q.nome }}
                                </v-btn>
                            </div>

                            <div class="p-4 rounded-xl border-thin shadow-sm" :class="isDark ? 'bg-grey-darken-3' : 'bg-white'">
                                <div class="d-flex align-center gap-2 mb-3 px-1 flex-wrap">
                                    <v-select
                                        v-model="selectedPaymentMethod"
                                        :items="paymentMethods"
                                        item-title="nome"
                                        return-object
                                        label="Forma Pgto"
                                        variant="outlined"
                                        density="compact"
                                        hide-details
                                        class="rounded-lg font-weight-bold ui-field"
                                        :bg-color="isDark ? 'grey-darken-4' : 'white'"
                                        style="min-width: 140px; flex: 2;"
                                    ></v-select>

                                    <v-expand-transition>
                                        <v-text-field
                                            v-if="isCreditCard"
                                            v-model.number="currentFeePct"
                                            label="Taxa %"
                                            type="number"
                                            density="compact"
                                            variant="outlined"
                                            hide-details
                                            class="rounded-lg font-weight-bold text-warning ui-field"
                                            :bg-color="isDark ? 'grey-darken-4' : 'white'"
                                            style="min-width: 70px; flex: 1;"
                                            min="0"
                                        ></v-text-field>
                                    </v-expand-transition>

                                    <v-text-field
                                        v-model.number="paymentAmountInput"
                                        label="Valor R$"
                                        type="number"
                                        density="compact"
                                        variant="outlined"
                                        hide-details
                                        class="rounded-lg font-weight-bold font-mono ui-field"
                                        :bg-color="isDark ? 'grey-darken-4' : 'white'"
                                        style="min-width: 100px; flex: 1.5;"
                                        @keyup.enter="addPayment">
                                    </v-text-field>
                                    <v-btn icon="mdi-plus" size="small" color="success" variant="flat" class="rounded-lg btn-3d mt-1" @click="addPayment" :disabled="!selectedPaymentMethod || paymentAmountInput <= 0" height="40" width="40"></v-btn>
                                </div>
                                <v-divider class="border-dashed my-3 opacity-20"></v-divider>

                                <div class="px-2 pb-2">
                                    <div v-if="payments.length === 0" class="text-[10px] opacity-50 text-center py-4 font-weight-black uppercase tracking-widest ls-1">Nenhum valor lançado</div>
                                    <div v-for="(p, i) in payments" :key="i" class="d-flex align-center justify-space-between py-3 border-b-dashed">
                                        <div class="d-flex align-center gap-3">
                                            <v-icon size="small" color="success">mdi-check-circle</v-icon>
                                            <div class="d-flex flex-column">
                                                <span class="text-caption font-weight-black text-uppercase">{{ p.method.nome }}</span>
                                                <span v-if="p.feePct && p.feePct > 0" class="text-[10px] text-warning font-weight-bold tracking-widest">+{{ p.feePct }}% taxa ({{ formatCurrency(p.feeAmount || 0) }})</span>
                                            </div>
                                        </div>
                                        <div class="d-flex align-center gap-3">
                                            <span class="text-body-2 font-weight-black font-mono">{{ formatCurrency(p.amount + (p.feeAmount || 0)) }}</span>
                                            <v-btn icon="mdi-close" size="x-small" variant="text" color="error" density="compact" @click="removePayment(i)"></v-btn>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <div class="d-flex flex-column gap-4 mb-4">
                             <div class="d-flex align-center gap-2 pa-4 rounded-xl border-thin shadow-sm" :class="isDark ? 'bg-grey-darken-3' : 'bg-white'">
                                <v-btn-toggle v-model="discountType" density="compact" color="primary" mandatory variant="outlined" class="flex-shrink-0 rounded-lg border" divided>
                                    <v-btn value="money" class="text-caption px-3 font-weight-bold">R$</v-btn>
                                    <v-btn value="percent" class="text-caption px-3 font-weight-bold">%</v-btn>
                                </v-btn-toggle>
                                <v-text-field v-model.number="discountValue" type="number" density="compact" variant="outlined" label="Aplicar Desconto" hide-details class="rounded-lg font-weight-bold font-mono ui-field" :bg-color="isDark ? 'grey-darken-4' : 'white'" min="0"></v-text-field>
                            </div>

                            <div v-if="hasPixPayment" class="pa-4 rounded-xl border-thin shadow-sm d-flex align-center justify-space-between" :class="isDark ? 'bg-grey-darken-3' : 'bg-white'">
                                <div class="d-flex align-center gap-3">
                                    <v-icon size="24" color="teal">mdi-qrcode-scan</v-icon>
                                    <div class="d-flex flex-column">
                                        <span class="text-caption font-weight-black lh-1 text-uppercase">Gerar QR Code Pix Cora</span>
                                        <span class="text-[10px] opacity-70 font-weight-bold tracking-widest mt-1 ls-1">CONCILIAÇÃO AUTOMÁTICA</span>
                                    </div>
                                </div>
                                <v-switch v-model="generatePixQr" color="teal" density="compact" hide-details inset></v-switch>
                            </div>

                            <div class="pa-4 rounded-xl border-thin shadow-sm d-flex align-center justify-space-between" :class="isDark ? 'bg-grey-darken-3' : 'bg-white'">
                                <div class="d-flex align-center gap-3">
                                    <v-icon size="24" color="deep-orange">mdi-receipt-text-check</v-icon>
                                    <div class="d-flex flex-column">
                                        <span class="text-caption font-weight-black lh-1 text-uppercase">Emitir NFC-e</span>
                                        <span class="text-[10px] opacity-70 font-weight-bold tracking-widest mt-1 ls-1">CUPOM FISCAL (SEFAZ)</span>
                                    </div>
                                </div>
                                <v-switch v-model="generateRealNfce" color="deep-orange" density="compact" hide-details inset></v-switch>
                            </div>

                            <v-textarea v-model="orderNotes" label="Observações Internas" variant="outlined" density="comfortable" hide-details rows="2" class="rounded-xl shadow-sm font-weight-medium ui-field" :bg-color="isDark ? 'grey-darken-3' : 'white'"></v-textarea>
                        </div>
                    </div>

                    <div class="pa-5 border-t flex-shrink-0 shadow-up" :class="isDark ? 'bg-grey-darken-4 border-white-10' : 'bg-white'">
                         <div class="mb-5">
                            <div class="d-flex justify-space-between align-center mb-2 text-caption opacity-70">
                                <span class="text-uppercase font-weight-bold tracking-widest ls-1">Subtotal</span> <span class="font-mono font-weight-bold">{{ formatCurrency(subtotal) }}</span>
                            </div>
                            <div v-if="discountAmount > 0" class="d-flex justify-space-between align-center mb-2 text-caption text-error font-weight-bold">
                                <span class="text-uppercase tracking-widest ls-1">Desconto</span> <span class="font-mono font-weight-bold">-{{ formatCurrency(discountAmount) }}</span>
                            </div>

                            <div v-if="totalFee > 0" class="d-flex justify-space-between align-center mb-2 text-caption text-warning font-weight-bold">
                                <span class="text-uppercase tracking-widest ls-1">Acréscimo (Taxa Cartão)</span> <span class="font-mono font-weight-bold">+{{ formatCurrency(totalFee) }}</span>
                            </div>

                            <v-divider class="my-3 border-dashed opacity-20"></v-divider>
                            <div class="d-flex justify-space-between align-end mb-4">
                                <span class="text-caption font-weight-black text-uppercase tracking-widest opacity-80 ls-1">Total Líquido</span>
                                <span class="text-h3 font-weight-black lh-1 font-mono tracking-tight" :class="isDark ? 'text-blue-lighten-2' : 'text-primary'">{{ formatCurrency(finalTotal) }}</span>
                            </div>

                            <div class="pa-4 rounded-xl border-thin" :class="isDark ? 'bg-grey-darken-3 border-white-10' : 'bg-grey-lighten-4'">
                                 <div class="d-flex justify-space-between align-center mb-2 text-caption">
                                    <span class="font-weight-black text-uppercase tracking-widest opacity-80 ls-1">Valor Pago</span>
                                    <span class="font-weight-black font-mono text-body-1">{{ formatCurrency(totalPaid) }}</span>
                                </div>
                                <div class="d-flex justify-space-between align-center text-caption" :class="remainingAmount > 0.05 ? 'text-warning font-weight-bold' : 'text-success font-weight-black'">
                                    <span class="text-uppercase tracking-widest ls-1">{{ remainingAmount > 0.05 ? 'Falta Receber' : 'Troco' }}</span>
                                    <span class="text-subtitle-1 font-mono lh-1">{{ formatCurrency(Math.abs(remainingAmount)) }}</span>
                                </div>
                            </div>
                         </div>

                         <div class="d-flex gap-3">
                            <v-btn variant="outlined" class="rounded-xl border-opacity-25 btn-3d opacity-70" width="56" height="56" @click="activeTab = 'items'">
                                <v-icon size="24">mdi-arrow-left</v-icon>
                            </v-btn>
                            <v-btn block color="success" class="font-weight-black rounded-xl text-none flex-grow-1 btn-3d" height="56" :disabled="!isOrderValid" :loading="isSubmitting" @click="submitStoreSale">
                                <div class="d-flex flex-column lh-1">
                                    <span class="tracking-widest ls-1 text-body-1">FINALIZAR VENDA</span>
                                    <span class="text-[9px] opacity-80 font-weight-black tracking-widest mt-1 ls-1">F12 CONFIRMA</span>
                                </div>
                                <v-icon end size="24" class="ml-3">mdi-check-circle</v-icon>
                            </v-btn>
                         </div>
                    </div>
                </div>
              </div>
          </template>
        </div>
    </template>

    <v-dialog v-model="showPriceConfigModal" max-width="900" scrollable persistent z-index="1000">
        <v-card class="rounded-xl border-thin shadow-xl" :class="isDark ? 'bg-grey-darken-4' : 'bg-surface'">
            <div class="pa-4 border-b d-flex align-center justify-space-between" :class="isDark ? 'bg-grey-darken-3 border-white-10' : 'bg-surface-light'">
                <h3 class="text-subtitle-1 font-weight-black d-flex align-center gap-2 text-uppercase tracking-widest ls-1">
                    <v-icon color="primary" size="24">mdi-tag-multiple-outline</v-icon> Gerenciar Tabelas de Preço
                </h3>
                <v-btn icon="mdi-close" variant="text" size="small" @click="showPriceConfigModal = false"></v-btn>
            </div>

            <v-card-text class="pa-0 d-flex" style="height: 65vh; overflow: hidden;">
                <div class="d-flex flex-column border-e" :class="isDark ? 'bg-grey-darken-4 border-white-10' : 'bg-white'" style="width: 260px; flex-shrink: 0;">
                    <div class="pa-3 border-b border-white-10">
                        <v-btn block color="primary" variant="flat" class="btn-3d font-weight-bold" prepend-icon="mdi-plus" @click="createNewPriceList">Nova Tabela</v-btn>
                    </div>
                    <v-list density="compact" class="flex-grow-1 overflow-y-auto bg-transparent py-2 custom-scroll">
                        <v-list-item v-if="priceLists.length === 0" class="opacity-50 text-center py-4">
                            <span class="text-caption font-weight-bold">Nenhuma tabela extra criada.</span>
                        </v-list-item>
                        <v-list-item
                            v-for="list in priceLists"
                            :key="list.id"
                            :active="editingPriceList?.id === list.id"
                            @click="editPriceList(list)"
                            :color="isDark ? 'blue-lighten-2' : 'primary'"
                            class="mb-1 mx-2 rounded-lg"
                        >
                            <template v-slot:prepend><v-icon size="small" :color="editingPriceList?.id === list.id ? 'primary' : 'grey'">mdi-label-outline</v-icon></template>
                            <v-list-item-title class="font-weight-bold">{{ list.name }}</v-list-item-title>
                        </v-list-item>
                    </v-list>
                </div>

                <div class="flex-grow-1 d-flex flex-column bg-grey-lighten-5" :class="isDark ? 'bg-grey-darken-3' : 'bg-grey-lighten-4'">
                    <template v-if="editingPriceList">
                        <div class="pa-4 border-b d-flex align-center gap-3" :class="isDark ? 'bg-grey-darken-4 border-white-10' : 'bg-white'">
                            <v-text-field
                                v-model="editingPriceList.name"
                                label="Nome da Tabela (Ex: Atacado, VIP)"
                                density="compact"
                                variant="outlined"
                                hide-details
                                class="ui-field font-weight-bold"
                            ></v-text-field>
                            <v-btn color="success" class="btn-3d font-weight-bold px-6" @click="savePriceList(editingPriceList)" :loading="isSavingPrices">
                                <v-icon start>mdi-content-save</v-icon> Salvar Configuração
                            </v-btn>
                            <v-btn icon="mdi-delete" color="error" variant="text" @click="deletePriceList(editingPriceList.id)"></v-btn>
                        </div>

                        <div class="pa-3 border-b d-flex align-center gap-3" :class="isDark ? 'bg-grey-darken-3 border-white-10' : 'bg-surface-light'">
                            <span class="text-caption font-weight-bold text-uppercase tracking-widest opacity-70">Ação em Massa:</span>
                            <v-select
                                v-model="massApplyType"
                                :items="[{title: 'Valor Fixo (R$)', value: 'fixed'}, {title: 'Desconto (%)', value: 'percent'}]"
                                density="compact"
                                variant="outlined"
                                hide-details
                                class="ui-field bg-white"
                                :class="isDark ? 'bg-grey-darken-4' : ''"
                                style="max-width: 160px;"
                            ></v-select>
                            <v-text-field
                                v-model.number="massApplyValue"
                                type="number"
                                density="compact"
                                variant="outlined"
                                hide-details
                                class="ui-field bg-white font-mono"
                                :class="isDark ? 'bg-grey-darken-4' : ''"
                                style="max-width: 120px;"
                            ></v-text-field>
                            <v-btn color="primary" variant="tonal" class="font-weight-bold text-none" @click="applyMassPrice" :disabled="selectedProductsForPrice.length === 0">
                                Aplicar em {{ selectedProductsForPrice.length }} item(ns)
                            </v-btn>
                            <v-spacer></v-spacer>
                            <v-text-field v-model="priceListProductSearch" prepend-inner-icon="mdi-magnify" placeholder="Buscar produto..." density="compact" variant="outlined" hide-details class="ui-field" style="max-width: 200px;"></v-text-field>
                        </div>

                        <div class="flex-grow-1 overflow-auto px-4 py-2 custom-scroll">
                            <v-table density="compact" class="rounded-lg border-thin shadow-sm" :class="isDark ? 'bg-grey-darken-4' : 'bg-white'">
                                <thead :class="isDark ? 'bg-grey-darken-3' : 'bg-grey-lighten-4'">
                                    <tr>
                                        <th style="width: 50px;" class="text-center">
                                            <v-checkbox v-model="selectAllProductsForPrice" hide-details density="compact" color="primary"></v-checkbox>
                                        </th>
                                        <th class="font-weight-black text-uppercase text-caption">Produto</th>
                                        <th class="font-weight-black text-uppercase text-caption text-right">Preço Base (Varejo)</th>
                                        <th class="font-weight-black text-uppercase text-caption text-right" style="width: 160px;">Preço Nesta Tabela</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <tr v-for="prod in filteredProductsForPriceList" :key="prod.id" :class="isDark ? 'hover-bg-grey-darken-3' : 'hover-bg-grey-lighten-5'">
                                        <td class="text-center">
                                            <v-checkbox v-model="selectedProductsForPrice" :value="prod.id" hide-details density="compact" color="primary"></v-checkbox>
                                        </td>
                                        <td class="text-caption font-weight-bold">{{ prod.name }}</td>
                                        <td class="text-right text-caption font-mono opacity-70">{{ formatCurrency(prod.base_price) }}</td>
                                        <td class="pa-1">
                                            <v-text-field
                                                v-model.number="editingPrices[prod.id]"
                                                type="number"
                                                density="compact"
                                                variant="outlined"
                                                hide-details
                                                class="font-mono text-right"
                                                prefix="R$"
                                            ></v-text-field>
                                        </td>
                                    </tr>
                                    <tr v-if="filteredProductsForPriceList.length === 0">
                                        <td colspan="4" class="text-center py-4 text-caption opacity-50">Nenhum produto encontrado.</td>
                                    </tr>
                                </tbody>
                            </v-table>
                        </div>
                    </template>
                    <div v-else class="flex-grow-1 d-flex flex-column align-center justify-center opacity-40">
                        <v-icon size="64" class="mb-4">mdi-tag-multiple-outline</v-icon>
                        <span class="text-body-2 font-weight-bold text-uppercase tracking-widest">Selecione ou crie uma Tabela de Preços</span>
                    </div>
                </div>
            </v-card-text>
        </v-card>
    </v-dialog>

    <v-dialog v-model="sizeModal.show" max-width="320" persistent>
        <v-card class="rounded-xl border-thin shadow-xl" :class="isDark ? 'bg-grey-darken-4' : 'bg-white'">
            <div class="pa-4 border-b d-flex align-center justify-space-between" :class="isDark ? 'bg-grey-darken-3' : 'bg-surface-light'">
                <span class="font-weight-black text-uppercase tracking-widest text-caption">Tamanho do Item</span>
                <v-btn icon="mdi-close" variant="text" size="small" @click="sizeModal.show = false"></v-btn>
            </div>
            <div class="pa-6 text-center">
                <div class="text-body-2 font-weight-bold mb-5 opacity-80">{{ sizeModal.product?.name }}</div>
                <div class="d-flex justify-center gap-3 flex-wrap">
                    <v-btn v-for="s in ['P', 'M', 'G', 'GG', 'U']" :key="s"
                        :color="isDark ? 'grey-darken-3' : 'grey-lighten-3'"
                        class="btn-3d font-weight-black text-h6"
                        width="56" height="56"
                        @click="confirmAddToCart(s)"
                    >
                        {{ s }}
                    </v-btn>
                </div>
                <div class="text-[10px] font-weight-bold opacity-50 mt-5 text-uppercase tracking-widest">Você pode digitar a letra no teclado<br>(Letra E = GG)</div>
            </div>
        </v-card>
    </v-dialog>

<v-dialog v-model="quickClientModal.show" max-width="600px" persistent>
    <v-card class="rounded-xl overflow-hidden border-thin shadow-2xl" :class="isDark ? 'bg-grey-darken-4 text-white' : 'bg-white'">
        <div class="px-5 py-4 border-b d-flex justify-space-between align-center" :class="isDark ? 'bg-grey-darken-3 border-white-10' : 'bg-blue-lighten-5 border-blue-lighten-2'">
           <div class="d-flex align-center gap-3 text-blue-darken-4">
              <v-icon size="24">mdi-account-plus</v-icon>
              <h2 class="text-subtitle-1 font-weight-black text-uppercase">Novo Cliente</h2>
           </div>
           <v-btn icon size="small" variant="text" color="blue-darken-4" @click="quickClientModal.show = false"><v-icon>mdi-close</v-icon></v-btn>
        </div>
        <v-card-text class="pa-5">
            <v-row dense class="row-gap-md">
                <v-col cols="12">
                    <label class="input-label font-weight-bold text-caption d-block mb-1">CPF ou CNPJ (Busca Automática)</label>
                    <v-text-field v-model="quickClientModal.cpf_cnpj" variant="outlined" density="compact" hide-details class="ui-field font-mono font-weight-bold text-primary" v-maska="['###.###.###-##', '##.###.###/####-##']" append-inner-icon="mdi-magnify" @click:append-inner="consultarCnpjCpfQuick" @keyup.enter="consultarCnpjCpfQuick"></v-text-field>
                </v-col>
                <v-col cols="12" sm="7">
                    <label class="input-label font-weight-bold text-caption d-block mb-1">Nome ou Razão Social *</label>
                    <v-text-field v-model="quickClientModal.nome" variant="outlined" density="compact" hide-details class="ui-field font-weight-bold"></v-text-field>
                </v-col>
                <v-col cols="12" sm="5">
                    <label class="input-label font-weight-bold text-caption d-block mb-1">Telefone / WhatsApp</label>
                    <v-text-field v-model="quickClientModal.telefone" variant="outlined" density="compact" hide-details class="ui-field font-weight-bold" v-maska="'(##) #####-####'"></v-text-field>
                </v-col>

                <v-col cols="12">
                    <v-divider class="my-2 border-dashed opacity-50"></v-divider>
                    <span class="text-caption font-weight-bold text-uppercase opacity-70">Endereço (Busca por CEP)</span>
                </v-col>

                <v-col cols="12" sm="4">
                    <label class="input-label font-weight-bold text-caption d-block mb-1">CEP</label>
                    <v-text-field v-model="quickClientModal.cep" variant="outlined" density="compact" hide-details class="ui-field font-weight-bold font-mono" v-maska="'#####-###'" append-inner-icon="mdi-magnify" @click:append-inner="buscarCepQuick" @keyup.enter="buscarCepQuick" :loading="quickClientModal.searchingCep"></v-text-field>
                </v-col>
                <v-col cols="12" sm="8">
                    <label class="input-label font-weight-bold text-caption d-block mb-1">Logradouro / Rua</label>
                    <v-text-field v-model="quickClientModal.logradouro" variant="outlined" density="compact" hide-details class="ui-field font-weight-bold"></v-text-field>
                </v-col>
                <v-col cols="12" sm="3">
                    <label class="input-label font-weight-bold text-caption d-block mb-1">Número</label>
                    <v-text-field v-model="quickClientModal.numero" variant="outlined" density="compact" hide-details class="ui-field font-weight-bold"></v-text-field>
                </v-col>
                <v-col cols="12" sm="4">
                    <label class="input-label font-weight-bold text-caption d-block mb-1">Complemento</label>
                    <v-text-field v-model="quickClientModal.complemento" variant="outlined" density="compact" hide-details class="ui-field font-weight-bold"></v-text-field>
                </v-col>
                <v-col cols="12" sm="5">
                    <label class="input-label font-weight-bold text-caption d-block mb-1">Bairro</label>
                    <v-text-field v-model="quickClientModal.bairro" variant="outlined" density="compact" hide-details class="ui-field font-weight-bold"></v-text-field>
                </v-col>
                <v-col cols="12" sm="9">
                    <label class="input-label font-weight-bold text-caption d-block mb-1">Cidade</label>
                    <v-text-field v-model="quickClientModal.cidade" variant="outlined" density="compact" hide-details class="ui-field font-weight-bold"></v-text-field>
                </v-col>
                <v-col cols="12" sm="3">
                    <label class="input-label font-weight-bold text-caption d-block mb-1">UF</label>
                    <v-text-field v-model="quickClientModal.estado" variant="outlined" density="compact" hide-details class="ui-field font-weight-bold text-uppercase" maxlength="2"></v-text-field>
                </v-col>

                <v-col cols="12">
                    <v-divider class="my-2 border-dashed opacity-50"></v-divider>
                </v-col>
                <v-col cols="12" :sm="quickClientModal.acquisition_channel === 'Internet' ? 6 : 12">
                    <label class="input-label font-weight-bold text-caption d-block mb-1">Canal de Aquisição *</label>
                    <v-select v-model="quickClientModal.acquisition_channel" :items="['Internet', 'Cliente veio até a loja', 'Vendedor foi até o cliente', 'Indicação', 'Outros']" variant="outlined" density="compact" hide-details class="ui-field font-weight-bold"></v-select>
                </v-col>
                <v-expand-transition>
                    <v-col cols="12" sm="6" v-if="quickClientModal.acquisition_channel === 'Internet'">
                        <label class="input-label font-weight-bold text-caption d-block mb-1">Subcanal / Rede *</label>
                        <v-select v-model="quickClientModal.acquisition_subchannel" :items="['Instagram', 'WhatsApp', 'Facebook', 'Google Ads', 'Site', 'Outros']" variant="outlined" density="compact" hide-details class="ui-field font-weight-bold"></v-select>
                    </v-col>
                </v-expand-transition>
            </v-row>
        </v-card-text>
        <v-card-actions class="pa-4 border-t justify-end gap-2" :class="isDark ? 'bg-grey-darken-3 border-white-10' : 'bg-grey-lighten-5'">
            <v-btn variant="outlined" :color="isDark ? 'white' : 'grey-darken-2'" height="40" class="btn-rect px-4 btn-3d font-weight-bold rounded-lg" @click="quickClientModal.show = false">Cancelar</v-btn>
            <v-btn color="success" variant="flat" height="40" class="btn-rect px-6 font-weight-black btn-3d rounded-lg" @click="saveQuickClient" :loading="quickClientModal.loading" :disabled="!quickClientModal.nome">
                <v-icon start>mdi-check</v-icon> Salvar
            </v-btn>
        </v-card-actions>
    </v-card>
</v-dialog>

    <MjCashOpeningModal v-model="showCashOpeningModal" @session-opened="handleSessionOpened" />
    <MjCashOperationsModal v-model="showOperationsModal" :type="operationType" @operation-completed="handleOperationSuccess" />
    <MjCashClosingModal v-model="showCashClosingModal" @session-closed="handleSessionClosed" />

    <v-dialog v-model="showSessionEndedModal" max-width="450" persistent z-index="10000">
        <v-card class="text-center pa-8 rounded-xl shadow-2xl border-thin" :class="isDark ? 'bg-grey-darken-4' : 'bg-white'">
            <div class="icon-circle-xl mb-6 mx-auto" :class="isDark ? 'bg-amber-darken-4' : 'bg-amber-lighten-5 text-amber'">
                 <v-icon size="48" :color="isDark ? 'white' : 'amber'">mdi-lock-check</v-icon>
            </div>
            <h2 class="text-h5 font-weight-black mb-4 tracking-tight">Turno Encerrado</h2>
            <div class="pa-5 rounded-lg border-thin mb-6 text-left" :class="isDark ? 'bg-grey-darken-3' : 'bg-grey-lighten-5'">
                <div class="d-flex justify-space-between mb-2">
                    <span class="text-caption opacity-70 font-weight-bold text-uppercase tracking-widest ls-1">Conferência</span>
                    <span class="text-body-1 font-weight-black font-mono" :class="isDark ? 'text-blue-lighten-2' : 'text-primary'">{{ formatCurrency(lastClosedSession?.session?.final_balance_user || 0) }}</span>
                </div>
                <div class="d-flex justify-space-between">
                    <span class="text-caption opacity-70">Resultado</span>
                    <span class="text-caption font-weight-black text-uppercase" :class="getDiffColor(calculatedDifference)">
                        {{ getDiffLabel(calculatedDifference) }}
                    </span>
                </div>
            </div>
            <div class="d-flex flex-column gap-3">
                <v-btn color="warning" variant="flat" size="large" block class="font-weight-black btn-3d tracking-widest ls-1 text-none" prepend-icon="mdi-printer" @click="reprintZReport">Imprimir Relatório Z</v-btn>
                <v-btn variant="outlined" size="large" block class="font-weight-bold btn-3d opacity-70" @click="() => { showSessionEndedModal = false; window.location.reload(); }">Fechar e Recarregar</v-btn>
            </div>
        </v-card>
    </v-dialog>

    <v-dialog v-model="showDraftsModal" max-width="600" scrollable>
        <v-card class="rounded-xl border-thin shadow-xl" :class="isDark ? 'bg-grey-darken-4' : 'bg-surface'">
            <div class="pa-5 border-b d-flex align-center justify-space-between" :class="isDark ? 'bg-grey-darken-3 border-white-10' : 'bg-surface-light'">
                <h3 class="text-subtitle-1 font-weight-black d-flex align-center gap-3 text-uppercase tracking-widest ls-1"><v-icon color="warning" size="24">mdi-folder-open-outline</v-icon> Rascunhos Salvos</h3>
                <v-btn icon="mdi-close" variant="text" size="small" @click="showDraftsModal = false"></v-btn>
            </div>
            <v-card-text class="pa-0 custom-scroll">
                <div v-if="isLoadingDrafts" class="pa-10 text-center"><v-progress-circular indeterminate color="primary" size="48" width="4"></v-progress-circular></div>
                <div v-else-if="draftsList.length === 0" class="pa-12 text-center opacity-60">
                    <v-icon size="64" class="mb-4 opacity-50">mdi-text-box-remove-outline</v-icon>
                    <div class="font-weight-black text-caption text-uppercase tracking-widest ls-1">Nenhum rascunho salvo.</div>
                </div>
                <v-list v-else lines="two" bg-color="transparent" class="pa-4">
                    <v-list-item v-for="draft in draftsList" :key="draft.id" class="mb-3 border-thin rounded-lg shadow-sm" :class="isDark ? 'bg-grey-darken-3 hover-bg-light' : 'bg-white hover-bg-light'">
                        <template v-slot:prepend>
                            <v-avatar :color="isDark ? 'blue-darken-4' : 'primary-lighten-5'" class="rounded-lg mr-4 font-weight-black border" :class="isDark ? 'text-white border-white-10' : 'text-primary border-primary-lighten-4'">{{ draft.draft_data.item_count }}</v-avatar>
                        </template>
                        <v-list-item-title class="font-weight-black text-body-2 text-uppercase tracking-wide">{{ draft.name || 'Rascunho Sem Nome' }}</v-list-item-title>
                        <v-list-item-subtitle class="text-[11px] mt-1 font-mono font-weight-bold opacity-80">
                            <span :class="isDark ? 'text-blue-lighten-2' : 'text-primary'">{{ formatCurrency(draft.draft_data.total_value) }}</span> • Cliente: {{ draft.draft_data.customer_name }}
                        </v-list-item-subtitle>
                        <template v-slot:append>
                            <v-btn size="small" color="primary" variant="flat" class="rounded-lg font-weight-black text-none mr-2 btn-3d tracking-widest" @click="loadDraft(draft)">Carregar</v-btn>
                            <v-btn icon="mdi-delete" size="small" color="error" variant="text" class="opacity-70 hover-opacity-100" @click="deleteDraft(draft.id)"></v-btn>
                        </template>
                    </v-list-item>
                </v-list>
            </v-card-text>
        </v-card>
    </v-dialog>

    <v-dialog v-model="showSyncFeedback" max-width="450" persistent>
        <v-card class="rounded-xl pa-8 shadow-2xl border-thin" :class="isDark ? 'bg-grey-darken-4' : 'bg-white'">
            <h3 class="text-h6 font-weight-black mb-6 text-center text-uppercase tracking-widest ls-1" :class="isDark ? 'text-blue-lighten-2' : 'text-primary'">{{ isSubmitting ? 'Processando...' : 'Sincronizando...' }}</h3>
            <v-list density="compact" class="bg-transparent pa-0">
                <v-list-item class="mb-4 pa-0">
                    <template v-slot:prepend>
                        <v-progress-circular v-if="syncStatus.db === 'pending'" indeterminate color="primary" size="32" class="mr-4" width="4"></v-progress-circular>
                        <v-icon v-else-if="syncStatus.db === 'success'" color="success" class="mr-4" size="36">mdi-check-circle</v-icon>
                        <v-icon v-else-if="syncStatus.db === 'error'" color="error" class="mr-4" size="36">mdi-alert-circle</v-icon>
                    </template>
                    <v-list-item-title class="font-weight-black text-body-2 text-uppercase tracking-wide">Banco de Dados Local</v-list-item-title>
                    <v-list-item-subtitle class="text-[11px] font-mono mt-1 opacity-70 font-weight-bold">{{ syncStatusMessages.db }}</v-list-item-subtitle>
                </v-list-item>

                <v-list-item v-if="isSubmitting && generateRealNfce" class="mt-4 pt-4 border-t border-dashed border-opacity-25 pa-0">
                    <template v-slot:prepend>
                        <v-progress-circular v-if="syncStatus.sefaz === 'pending'" indeterminate color="deep-orange" size="32" class="mr-4" width="4"></v-progress-circular>
                        <v-icon v-else-if="syncStatus.sefaz === 'success'" color="success" class="mr-4" size="36">mdi-check-circle</v-icon>
                        <v-icon v-else-if="syncStatus.sefaz === 'error'" color="warning" class="mr-4" size="36">mdi-alert-circle</v-icon>
                    </template>
                    <v-list-item-title class="font-weight-black text-body-2 text-uppercase tracking-wide">Emissão Sefaz (NFC-e)</v-list-item-title>
                    <v-list-item-subtitle class="text-[11px] font-mono mt-1 opacity-70 font-weight-bold">{{ syncStatusMessages.sefaz }}</v-list-item-subtitle>
                </v-list-item>
            </v-list>
        </v-card>
    </v-dialog>

  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted, watch, reactive } from 'vue'
import { supabase } from '@/api/supabase'
import { useUserStore } from '@/stores/user'
import { useAppStore } from '@/stores/app'
import { useTheme } from 'vuetify'
import { useCompanyStore } from '@/stores/company'
import { useMjCashSessionStore } from '@/stores/mjCashSession'
import { useCashReport } from '@/composables/useCashReport'
import { coraApi } from '@/api/coraProxy'
import { format, startOfDay } from 'date-fns'
import jsPDF from 'jspdf'
import autoTable from 'jspdf-autotable'
import { vMaska } from "maska/vue"
import axios from 'axios'
import logoCajuia from '@/assets/logocajuia.png'

import MjCashOpeningModal from '@/components/sales/MjCashOpeningModal.vue'
import MjCashOperationsModal from '@/components/sales/MjCashOperationsModal.vue'
import MjCashClosingModal from '@/components/sales/MjCashClosingModal.vue'

const theme = useTheme();
const isDark = computed(() => theme.global.current.value.dark);
const zebraClass = (index: number) => isDark.value ? (index % 2 === 0 ? 'zebra-dark-a' : 'zebra-dark-b') : (index % 2 === 0 ? 'zebra-light-a' : 'zebra-light-b');

const formatCurrency = (v: number | string, prefix = 'R$', decimals = 2) => {
    const num = Number(v) || 0;
    return new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL', minimumFractionDigits: decimals, maximumFractionDigits: decimals }).format(num).replace('R$', prefix ? prefix + ' ' : '').trim();
};

const imageToBase64 = async (url: string): Promise<string> => {
  try {
    const res = await fetch(url);
    const blob = await res.blob();
    return new Promise((resolve) => {
        const reader = new FileReader();
        reader.onload = () => resolve(String(reader.result));
        reader.readAsDataURL(blob);
    });
  } catch(e) { return ''; }
};

type StoreProduct = { id: string; name: string; sku: string | null; barcode?: string | null; category?: string; base_price: number; active_price: number; photo_url: string | null; quantity_in_stock: number; unit_of_measure: string; hasActivePrice: boolean; discountPct: number; ncm: string; }
type CartItem = { product_id: string; product_name: string; photo_url: string | null; quantity: number; unit_price: number; total_price: number; stock_available: number; unit_of_measure: string; size: string; ncm: string; sku: string; }
type AddedPayment = { method: any, amount: number, feePct?: number, feeAmount?: number }

const userStore = useUserStore()
const appStore = useAppStore()
const companyStore = useCompanyStore()
const cashStore = useMjCashSessionStore()

const products = ref<StoreProduct[]>([])
const paymentMethods = ref<any[]>([])
const clientList = ref<any[]>([])
const salespeopleList = ref<any[]>([]);
const selectedSeller = ref<string | null>(null);
const categoriesList = ref<string[]>([])

const priceLists = ref<any[]>([])
const activePriceList = ref<any | null>(null)
const productPricesMap = ref<Record<string, Record<string, number>>>({})
const showPriceConfigModal = ref(false)
const editingPriceList = ref<any | null>(null)
const isSavingPrices = ref(false)
const priceListProductSearch = ref('')
const selectedProductsForPrice = ref<string[]>([])
const editingPrices = ref<Record<string, number>>({})
const massApplyType = ref('fixed')
const massApplyValue = ref(0)

const selectAllProductsForPrice = computed({
    get() { const list = filteredProductsForPriceList.value; return list.length > 0 && selectedProductsForPrice.value.length === list.length; },
    set(val) { if (val) { selectedProductsForPrice.value = filteredProductsForPriceList.value.map(p => p.id); } else { selectedProductsForPrice.value = []; } }
})

const filteredProductsForPriceList = computed(() => {
    let result = products.value;
    if (priceListProductSearch.value) { const q = priceListProductSearch.value.toLowerCase(); result = result.filter(p => p.name.toLowerCase().includes(q) || p.sku?.toLowerCase().includes(q)); }
    return result.sort((a, b) => a.name.localeCompare(b.name));
});

const processedProducts = computed<StoreProduct[]>(() => {
    return products.value.map(p => {
        const base = Number(p.base_price) || 0;
        let active = base; let hasActive = false;
        if (activePriceList.value) {
            const listPrices = productPricesMap.value[activePriceList.value.id];
            if (listPrices && listPrices[p.id] !== undefined) { active = listPrices[p.id]; hasActive = true; }
        }
        const discount = (hasActive && active < base && base > 0) ? Math.round(((base - active) / base) * 100) : 0;
        return { ...p, active_price: active, hasActivePrice: hasActive, discountPct: discount };
    });
});

const filteredProducts = computed(() => {
  let result = processedProducts.value;
  if (productSearch.value) { const q = productSearch.value.toLowerCase(); result = result.filter(p => p.name.toLowerCase().includes(q) || p.sku?.toLowerCase().includes(q) || p.barcode?.toLowerCase().includes(q)); }
  if (filterCategory.value) result = result.filter(p => p.category === filterCategory.value);
  if (stockFilter.value === 'in_stock') result = result.filter(p => p.quantity_in_stock > 0);
  return result.sort((a, b) => a.name.localeCompare(b.name));
});

const fetchPriceListsData = async () => {
    try {
        const { data: lists } = await supabase.from('pdv_price_lists').select('*').eq('is_active', true);
        priceLists.value = lists || [];
        const { data: prices } = await supabase.from('pdv_product_prices').select('*');
        const map: any = {};
        prices?.forEach(p => { if(!map[p.price_list_id]) map[p.price_list_id] = {}; map[p.price_list_id][p.product_id] = Number(p.price); });
        productPricesMap.value = map;
    } catch (e) { console.error(e); }
}

const openPriceListConfig = () => { editingPriceList.value = null; selectedProductsForPrice.value = []; editingPrices.value = {}; priceListProductSearch.value = ''; showPriceConfigModal.value = true; }
const createNewPriceList = () => { editingPriceList.value = { id: 'NEW', name: 'Nova Tabela de Preço' }; editingPrices.value = {}; selectedProductsForPrice.value = []; products.value.forEach(p => { editingPrices.value[p.id] = p.base_price; }); }
const editPriceList = (list: any) => { editingPriceList.value = { ...list }; editingPrices.value = {}; selectedProductsForPrice.value = []; const listPrices = productPricesMap.value[list.id] || {}; products.value.forEach(p => { editingPrices.value[p.id] = listPrices[p.id] !== undefined ? listPrices[p.id] : p.base_price; }); }
const applyMassPrice = () => { selectedProductsForPrice.value.forEach(pid => { const prod = products.value.find(p => p.id === pid); if (prod) { if (massApplyType.value === 'fixed') { editingPrices.value[pid] = massApplyValue.value; } else { editingPrices.value[pid] = Number((prod.base_price * (1 - massApplyValue.value / 100)).toFixed(2)); } } }); appStore.showSnackbar(`Valores aplicados.`, 'success'); }

const savePriceList = async (list: any) => {
    isSavingPrices.value = true;
    try {
        let listId = list.id;
        if (listId === 'NEW') { const { data, error } = await supabase.from('pdv_price_lists').insert({ name: list.name }).select('id').single(); if (error) throw error; listId = data.id; }
        else { await supabase.from('pdv_price_lists').update({ name: list.name }).eq('id', listId); }
        const pricesToUpsert = Object.keys(editingPrices.value).map(prodId => ({ price_list_id: listId, product_id: prodId, price: editingPrices.value[prodId] }));
        await supabase.from('pdv_product_prices').delete().eq('price_list_id', listId);
        if (pricesToUpsert.length > 0) { await supabase.from('pdv_product_prices').insert(pricesToUpsert); }
        appStore.showSnackbar('Tabela salva!', 'success'); await fetchPriceListsData(); showPriceConfigModal.value = false;
        if (activePriceList.value && (activePriceList.value.id === listId || list.id === 'NEW')) { const updatedList = priceLists.value.find(l => l.id === listId); if(updatedList) selectPriceList(updatedList); }
    } catch (e: any) { appStore.showSnackbar('Erro: ' + e.message, 'error'); } finally { isSavingPrices.value = false; }
}

const deletePriceList = async (id: string) => {
    if (id === 'NEW') { editingPriceList.value = null; return; }
    if (!confirm('Excluir esta tabela?')) return;
    try { await supabase.from('pdv_price_lists').delete().eq('id', id); if (activePriceList.value?.id === id) selectPriceList(null); await fetchPriceListsData(); editingPriceList.value = null; appStore.showSnackbar('Tabela excluída.', 'success'); } catch (e: any) { }
}

const selectPriceList = (list: any | null) => {
    activePriceList.value = list;
    cart.value.forEach(item => { const prod = processedProducts.value.find(p => p.id === item.product_id); if (prod) { item.unit_price = prod.active_price; item.total_price = item.quantity * item.unit_price; } });
    if(list) appStore.showSnackbar(`Tabela: ${list.name} ativada.`, 'info');
}

const productSearch = ref('')
const filterCategory = ref<string | null>(null)
const stockFilter = ref('in_stock')
const searchRef = ref<any>(null)
const activeTab = ref('items')

const shouldBlockScreen = computed(() => userStore.isAdmin && !userStore.activeStoreId);
const searchStore = ref('');
const availableStores = ref<any[]>([]);
const adminStoreStats = ref<Record<string, number>>({});
const isCheckingSession = ref(true);

const filteredStores = computed(() => { if (!searchStore.value) return availableStores.value; const term = searchStore.value.toLowerCase(); return availableStores.value.filter(s => s.name.toLowerCase().includes(term) || s.address?.toLowerCase().includes(term)); });
const storeKpis = computed(() => { const totalStores = availableStores.value.length; const openStores = availableStores.value.filter(s => s.active_session_user).length; const totalSales = Object.values(adminStoreStats.value).reduce((acc, val) => acc + val, 0); return [ { label: 'Unidades', value: totalStores, footer: 'Cadastradas', icon: 'mdi-store', gradient: 'bg-gradient-purple', isMoney: false }, { label: 'Abertas Agora', value: openStores, footer: 'Em operação', icon: 'mdi-store-clock', gradient: 'bg-gradient-info', isMoney: false }, { label: 'Vendas Hoje', value: formatCurrency(totalSales), footer: 'Rede Total', icon: 'mdi-chart-line', gradient: 'bg-gradient-success', isMoney: false } ]; });

const fetchStoresWithStatus = async () => {
    if (!userStore.isAdmin) return;
    const { data: storesData } = await supabase.from('stores').select('*').eq('active', true);
    const { data: sessionsData } = await supabase.from('mj_cash_sessions').select('store_id, user:profiles(full_name)').eq('status', 'open');
    availableStores.value = (storesData || []).map(store => { const session = sessionsData?.find((s: any) => s.store_id === store.id); const userData = Array.isArray(session?.user) ? session?.user[0] : session?.user; return { ...store, active_session_user: userData?.full_name || null }; });
};

const fetchAdminStoreStats = async () => {
    if (!userStore.isAdmin) return;
    const today = startOfDay(new Date()).toISOString();
    const { data } = await supabase.from('store_sales').select('store_id, total_value').gte('created_at', today).neq('status', 'cancelled');
    if (data) { const stats: Record<string, number> = {}; data.forEach((sale: any) => { if (sale.store_id) stats[sale.store_id] = (stats[sale.store_id] || 0) + Number(sale.total_value || 0); }); adminStoreStats.value = stats; }
};

const handleAdminStoreSelection = async (store: any) => { userStore.setAdminStore(store); isCheckingSession.value = true; await cashStore.checkActiveSession(); await fetchNextOrderNumber(); isCheckingSession.value = false; };
const resetAdminStore = () => { userStore.setAdminStore(null); cashStore.currentSession = null; fetchAdminStoreStats(); fetchNextOrderNumber(); };

const cart = ref<CartItem[]>([])
const selectedCustomer = ref<any | null>(null)
const isSearchingClients = ref(false)
let clientSearchTimeout: NodeJS.Timeout
const cpfNota = ref('')

const sizeModal = reactive({ show: false, product: null as StoreProduct | null });

// Adicione as novas variáveis no objeto reactive
const quickClientModal = reactive({
    show: false,
    nome: '',
    cpf_cnpj: '',
    telefone: '',
    acquisition_channel: 'Cliente veio até a loja',
    acquisition_subchannel: '',
    cep: '',
    logradouro: '',
    numero: '',
    complemento: '',
    bairro: '',
    cidade: '',
    estado: '',
    loading: false,
    searchingCep: false
});

// Nova função para buscar o CEP
const buscarCepQuick = async () => {
    const cep = quickClientModal.cep?.replace(/\D/g, '');
    if (!cep || cep.length !== 8) return;

    quickClientModal.searchingCep = true;
    try {
        const res = await fetch(`https://viacep.com.br/ws/${cep}/json/`);
        const data = await res.json();
        if (data.erro) throw new Error('CEP inválido.');

        quickClientModal.logradouro = data.logradouro;
        quickClientModal.bairro = data.bairro;
        quickClientModal.cidade = data.localidade;
        quickClientModal.estado = data.uf;

        appStore.showSnackbar('Endereço preenchido automaticamente.', 'success');
    } catch (e: any) {
        appStore.showSnackbar('CEP não encontrado.', 'error');
    } finally {
        quickClientModal.searchingCep = false;
    }
};

// Atualize o consultarCnpjCpfQuick para preencher o endereço também
const consultarCnpjCpfQuick = async () => {
    const doc = quickClientModal.cpf_cnpj.replace(/\D/g, '');
    if (doc.length === 14) {
        try {
            appStore.showSnackbar('Consultando CNPJ...', 'info');
            const { data } = await axios.get(`https://brasilapi.com.br/api/cnpj/v1/${doc}`);

            // Dados da empresa
            quickClientModal.nome = data.razao_social || data.nome_fantasia || '';
            quickClientModal.telefone = data.ddd_telefone_1 || '';

            // Endereço (BrasilAPI já retorna essas chaves)
            quickClientModal.cep = data.cep || '';
            quickClientModal.logradouro = data.logradouro || data.descricao_tipo_de_logradouro + ' ' + data.logradouro;
            quickClientModal.numero = data.numero || '';
            quickClientModal.complemento = data.complemento || '';
            quickClientModal.bairro = data.bairro || '';
            quickClientModal.cidade = data.municipio || '';
            quickClientModal.estado = data.uf || '';

            appStore.showSnackbar('Dados da empresa carregados!', 'success');
        } catch(e) {
            appStore.showSnackbar('CNPJ não encontrado.', 'error');
        }
    }
};

// Atualize o saveQuickClient para injetar e resetar os novos campos
const saveQuickClient = async () => {
    quickClientModal.loading = true;
    try {
        const doc = quickClientModal.cpf_cnpj.replace(/\D/g, '');
        const payload = {
            nome: quickClientModal.nome,
            cpf: doc.length <= 11 && doc.length > 0 ? doc : null,
            cnpj: doc.length > 11 ? doc : null,
            telefone: quickClientModal.telefone,
            tipo_pessoa: doc.length > 11 ? 'PJ' : 'PF',
            acquisition_channel: quickClientModal.acquisition_channel,
            acquisition_subchannel: quickClientModal.acquisition_channel === 'Internet' ? quickClientModal.acquisition_subchannel : null,

            // Novos Campos
            cep: quickClientModal.cep,
            endereco: quickClientModal.logradouro,
            numero: quickClientModal.numero,
            complemento: quickClientModal.complemento,
            bairro: quickClientModal.bairro,
            cidade: quickClientModal.cidade,
            estado: quickClientModal.estado
        };

        const { data, error } = await supabase.from('customers_mj').insert(payload).select().single();
        if (error) throw error;

        const novo = { id: data.id, nome: data.nome, cpf_cnpj: doc };
        clientList.value.push(novo);
        selectedCustomer.value = novo;

        quickClientModal.show = false;

        // Reset Limpeza dos campos
        quickClientModal.nome = ''; quickClientModal.cpf_cnpj = ''; quickClientModal.telefone = '';
        quickClientModal.cep = ''; quickClientModal.logradouro = ''; quickClientModal.numero = '';
        quickClientModal.complemento = ''; quickClientModal.bairro = ''; quickClientModal.cidade = ''; quickClientModal.estado = '';
        quickClientModal.acquisition_channel = 'Cliente veio até a loja';
        quickClientModal.acquisition_subchannel = '';

        appStore.showSnackbar('Cliente salvo e selecionado!', 'success');
    } catch(e: any) {
        appStore.showSnackbar(`Erro ao cadastrar cliente: ${e.message}`, 'error');
    } finally {
        quickClientModal.loading = false;
    }
};

const selectedPaymentMethod = ref<any | null>(null)
const paymentAmountInput = ref(0)
const payments = ref<AddedPayment[]>([])
const discountType = ref('money')
const discountValue = ref(0)
const orderNotes = ref('')
const generatePixQr = ref(true)
const generateRealNfce = ref(localStorage.getItem('mj_pdv_always_nfce') === 'true')
const alwaysGenerateNfce = ref(localStorage.getItem('mj_pdv_always_nfce') === 'true')

watch(alwaysGenerateNfce, (val) => { localStorage.setItem('mj_pdv_always_nfce', String(val)); generateRealNfce.value = val; });

const currentFeePct = ref(3);
const isCreditCard = computed(() => { return selectedPaymentMethod.value?.nome?.toLowerCase().includes('crédito') || selectedPaymentMethod.value?.nome?.toLowerCase().includes('credito'); });

watch(selectedPaymentMethod, (newVal) => { if (newVal?.nome?.toLowerCase().includes('crédito') || newVal?.nome?.toLowerCase().includes('credito')) { currentFeePct.value = 3; } else { currentFeePct.value = 0; } });

const isLoadingProducts = ref(false)
const isSyncingProducts = ref(false)
const isSubmitting = ref(false)
const showSyncFeedback = ref(false)
const syncStatus = ref({ db: 'pending', sefaz: 'pending' })
const syncStatusMessages = ref({ db: 'Aguardando...', sefaz: 'Aguardando...' })

const showDraftsModal = ref(false)
const draftsList = ref<any[]>([])
const isLoadingDrafts = ref(false)
const currentDraftId = ref<string | null>(null)

const nextOrderNumber = ref<number | string>('...')
const realTimeClock = ref(format(new Date(), 'HH:mm:ss'))
let clockInterval: NodeJS.Timeout

const showCashOpeningModal = ref(false)
const showCashClosingModal = ref(false)
const showOperationsModal = ref(false)
const operationType = ref<'supply'|'bleed'>('supply')

const orderCreatedSuccess = ref(false)
const createdOrderId = ref<string | null>(null)
const createdOrderNumber = ref<number | null>(null)
const lastSoldItems = ref<CartItem[]>([])
const lastPaymentText = ref('')
const lastCpfNota = ref('')
const lastSoldTotal = ref(0)
const lastSoldCustomer = ref<any>(null)
const isPdfGenerating = ref(false)
const lastGeneratedNfceData = ref<any>(null)
const lastDiscount = ref(0)
const lastFee = ref(0)
const lastNotes = ref('')

const pixState = reactive({ show: false, loading: false, qrCodeImage: '', copyPaste: '', invoiceId: '', status: 'PENDING', displayValue: '', checkInterval: null as NodeJS.Timeout | null })

const isScannerReady = ref(true)
const barcodeBuffer = ref('')
const lastKeyTime = ref(0)
const printFormat = ref<'a4' | '80mm' | '58mm'>(localStorage.getItem('mj_pdv_print_format') as any || '80mm')
const printerType = ref<'thermal' | 'ink'>(localStorage.getItem('mj_pdv_printer_type') as any || 'thermal')
const printerName = ref<string>(localStorage.getItem('mj_pdv_printer_name') || '')
const isTestingPrint = ref(false)

watch(printFormat, (val) => localStorage.setItem('mj_pdv_print_format', val))
watch(printerType, (val) => localStorage.setItem('mj_pdv_printer_type', val))
watch(printerName, (val) => localStorage.setItem('mj_pdv_printer_name', val))

const currentCompanyName = computed(() => {
    if (!companyStore.companies || !Array.isArray(companyStore.companies)) return 'CAJUIA STORE';
    return companyStore.companies.find(c => c.id === companyStore.context)?.trade_name || 'CAJUIA STORE';
});
const quickPaymentOptions = computed(() => {
    const desired = ['dinheiro', 'pix', 'crédito', 'débito'];
    const options = [];
    const methods = paymentMethods.value || [];
    for(const d of desired) {
        const found = methods.find(m => m.nome && m.nome.toLowerCase().includes(d));
        if(found) {
            let icon = 'mdi-cash';
            if(d === 'pix') icon = 'mdi-qrcode-scan';
            if(d.includes('crédito')) icon = 'mdi-credit-card-outline';
            if(d.includes('débito')) icon = 'mdi-credit-card';
            options.push({ ...found, icon });
        }
    }
    return options.slice(0, 4);
});
const subtotal = computed(() => cart.value.reduce((total, item) => total + item.total_price, 0))
const discountAmount = computed(() => { const val = Number(discountValue.value) || 0; if (val <= 0) return 0; if (discountType.value === 'percent') return subtotal.value * (Math.min(val, 100) / 100); return Math.min(val, subtotal.value) })
const totalFee = computed(() => payments.value.reduce((sum, p) => sum + (p.feeAmount || 0), 0))
const finalTotal = computed(() => Math.max(0, subtotal.value - discountAmount.value + totalFee.value))
const totalPaid = computed(() => payments.value.reduce((sum, p) => sum + p.amount + (p.feeAmount || 0), 0))
const remainingAmount = computed(() => (subtotal.value - discountAmount.value) - payments.value.reduce((sum, p) => sum + p.amount, 0))
const cartItemCount = computed(() => cart.value.reduce((count, item) => count + item.quantity, 0))
const hasPixPayment = computed(() => payments.value.some(p => p.method.nome.toLowerCase().includes('pix')) || (payments.value.length === 0 && selectedPaymentMethod.value?.nome.toLowerCase().includes('pix')))

const isOrderValid = computed(() => { if (cart.value.length === 0 || !cashStore.isSessionOpen) return false; if (payments.value.length === 0) return false; return totalPaid.value >= (finalTotal.value - 0.05); })
watch([remainingAmount, selectedPaymentMethod], ([rem]) => { if(rem > 0) paymentAmountInput.value = Number(rem.toFixed(2)); })

const syncAllData = async (force = false) => {
    if (isSyncingProducts.value) return;
    isSyncingProducts.value = true;
    if(force) { showSyncFeedback.value = true; syncStatus.value.db = 'pending'; syncStatusMessages.value.db = 'Baixando catálogo...'; }
    try {
        const { data: stockData } = await supabase.from('stock').select('*');
        if (stockData) {
            products.value = stockData.filter((s: any) => {
                    // CORREÇÃO: Barra o item imediatamente se ele foi ocultado no StockManagement
                    if (s.visible_in_sales === false) return false;

                    const sku = s.sku || s.barcode || s.gestao_click_id || '';
                    const name = s.fabric_type || s.name || '';
                    return sku.toUpperCase().startsWith('CJ') || name.toUpperCase().startsWith('CJ');
                })
                .map((s: any) => ({
                    id: s.id,
                    name: s.fabric_type || s.name || 'Produto',
                    sku: s.barcode || null,
                    barcode: s.barcode || null,
                    category: s.category || 'Varejo',
                    base_price: Number(s.base_price || 0),
                    active_price: Number(s.base_price || 0),
                    photo_url: s.photo_url || null,
                    quantity_in_stock: Number(s.available_meters || s.quantity || 0),
                    unit_of_measure: s.unit_of_measure || 'UN',
                    hasActivePrice: false,
                    discountPct: 0,
                    ncm: s.ncm || 'S/N'
                }));
            categoriesList.value = [...new Set(products.value.map(p => p.category).filter(Boolean))] as string[];
        }
        await fetchPriceListsData();
        const { data: cliData } = await supabase.from('customers_mj').select('id, nome, cpf, cnpj').limit(50);
        if (cliData) { clientList.value = cliData.map(c => ({ id: c.id, nome: c.nome || c.name || c.full_name || 'Sem Nome', cpf_cnpj: c.cnpj || c.cpf || '' })); }
        const { data: profData } = await supabase.from('profiles').select('id, full_name').order('full_name');
        if (profData) salespeopleList.value = profData.map(p => ({ id: p.id, nome: p.full_name }));
        const { data: financeMethods } = await supabase.from('finance_payment_methods').select('id, name, gestao_click_id').eq('is_active', true).order('name');
        if (financeMethods) { paymentMethods.value = financeMethods.map(m => ({ id: m.id, nome: m.name, gestao_click_id: m.gestao_click_id })); }
        if(force) { syncStatus.value.db = 'success'; syncStatusMessages.value.db = 'Catálogo Sincronizado!'; }
    } catch (e: any) { if(force) { syncStatus.value.db = 'error'; syncStatusMessages.value.db = e.message; } } finally { isSyncingProducts.value = false; if(force) setTimeout(() => { showSyncFeedback.value = false; }, 1000); }
}

const fetchAllData = async () => { isLoadingProducts.value = true; await syncAllData(); isLoadingProducts.value = false; fetchDrafts(); }

const fetchNextOrderNumber = async () => {
    try {
        if (!companyStore.context) {
            nextOrderNumber.value = 1;
            return;
        }

        const { data } = await supabase
            .from('store_sales')
            .select('order_number')
            .eq('company_id', companyStore.context)
            .limit(10000);

        if (data && data.length > 0) {
            const maxNum = Math.max(...data.map(d => Number(String(d.order_number).replace(/\D/g, '')) || 0));
            nextOrderNumber.value = maxNum + 1;
        } else {
            nextOrderNumber.value = 1;
        }
    } catch (e) {
        nextOrderNumber.value = 1;
    }
}

watch(() => companyStore.context, () => {
    fetchNextOrderNumber();
});

const getCartQuantity = (p: StoreProduct) => cart.value.find(i => i.product_id === p.id)?.quantity || 0
const getStockColor = (q: number) => q <= 0 ? 'error' : (q < 5 ? 'warning' : 'surface')

const openSizeModal = (product: StoreProduct) => {
    if (!cashStore.isSessionOpen) return appStore.showSnackbar('Abra o caixa primeiro.', 'error')
    if (product.quantity_in_stock <= 0) return appStore.showSnackbar('Produto sem estoque.', 'warning')
    sizeModal.product = product; sizeModal.show = true;
}

const confirmAddToCart = (size: string) => {
    if (!sizeModal.product) return;
    const product = sizeModal.product;
    activeTab.value = 'items'
    const existing = cart.value.find(i => i.product_id === product.id && i.size === size)
    if (existing) { if (existing.quantity < existing.stock_available) { existing.quantity++; existing.total_price = existing.quantity * existing.unit_price } else appStore.showSnackbar('Estoque limite atingido.', 'warning') }
    else { cart.value.push({ product_id: product.id, product_name: product.name, photo_url: product.photo_url, quantity: 1, unit_price: product.active_price, total_price: product.active_price, stock_available: product.quantity_in_stock, unit_of_measure: product.unit_of_measure, size: size, sku: product.sku || '', ncm: product.ncm || '' }) }
    sizeModal.show = false; sizeModal.product = null;
}

const updateCartQuantity = (index: number, change: number) => {
  const item = cart.value[index]
  const newQty = item.quantity + change
  if (newQty <= 0) { cart.value.splice(index, 1); return }
  if (newQty > item.stock_available) return appStore.showSnackbar('Limite de estoque.', 'warning')
  item.quantity = newQty; item.total_price = newQty * item.unit_price
}

const clearCart = () => { cart.value = []; payments.value = []; selectedPaymentMethod.value = null; currentDraftId.value = null; activeTab.value = 'items'; }

const applyQuickPayment = (method: any) => {
    selectedPaymentMethod.value = method;
    if (remainingAmount.value > 0) {
        paymentAmountInput.value = Number(remainingAmount.value.toFixed(2));
        if (method.nome.toLowerCase().includes('crédito') || method.nome.toLowerCase().includes('credito')) { currentFeePct.value = 3; }
        else { currentFeePct.value = 0; addPayment(); }
    }
}

const addPayment = () => {
    if(!selectedPaymentMethod.value || paymentAmountInput.value <= 0) return;
    const feePct = isCreditCard.value ? Number(currentFeePct.value) : 0;
    const feeAmt = paymentAmountInput.value * (feePct / 100);
    payments.value.push({ method: selectedPaymentMethod.value, amount: paymentAmountInput.value, feePct: feePct, feeAmount: feeAmt });
    if(remainingAmount.value <= 0) { selectedPaymentMethod.value = null; paymentAmountInput.value = 0; currentFeePct.value = 3; }
}
const removePayment = (index: number) => { payments.value.splice(index, 1); }

const saveDraft = async () => {
    if (cart.value.length === 0) return appStore.showSnackbar('Carrinho vazio.', 'warning')

    const draftData = {
        cart: cart.value,
        client: selectedCustomer.value,
        payments: payments.value,
        discount: { type: discountType.value, value: discountValue.value },
        notes: orderNotes.value,
        cpfNota: cpfNota.value,
        total_value: finalTotal.value,
        item_count: cartItemCount.value,
        customer_name: selectedCustomer.value?.nome || 'Consumidor Final'
    }

    const payload: any = {
        user_id: userStore.user?.id,
        company_id: companyStore.context,
        name: `PDV - ${selectedCustomer.value?.nome || 'Balcão'}`,
        draft_data: draftData,
        reserved_order_number: nextOrderNumber.value
    }

    try {
        if (currentDraftId.value) {
            const { error } = await supabase.from('order_drafts').update(payload).eq('id', currentDraftId.value);
            if (error) throw error;
            appStore.showSnackbar('Rascunho atualizado!', 'success');
        } else {
            const { data, error } = await supabase.from('order_drafts').insert(payload).select('id').single();
            if (error) throw error;
            currentDraftId.value = data?.id || null;
            appStore.showSnackbar('Novo rascunho salvo!', 'success');
        }
        fetchDrafts();
    } catch(e: any) {
        console.error("ERRO NO RASCUNHO:", e);

        // BLINDAGEM CONTRA A CONSTRAINT CEGA DO SUPABASE (Erro 23505)
        if (e.code === '23505' && !currentDraftId.value) {
            console.warn("Colisão de numeração com o Gestão! Salvando rascunho com número de reserva nulo...");
            payload.reserved_order_number = null; // Bypassa a constraint para salvar o rascunho

            const { data: retryData, error: retryErr } = await supabase.from('order_drafts').insert(payload).select('id').single();

            if (!retryErr) {
                currentDraftId.value = retryData?.id || null;
                appStore.showSnackbar('Rascunho salvo com sucesso (sem reservar número)!', 'success');
                fetchDrafts();
                return; // Encerra aqui pois deu certo no plano B
            }
        }

        appStore.showSnackbar(`Erro ao salvar rascunho: ${e.message}`, 'error');
    }
}

const fetchDrafts = async () => { isLoadingDrafts.value = true; try { const { data } = await supabase.from('order_drafts').select('*').eq('user_id', userStore.user?.id).ilike('name', 'PDV%').order('created_at', { ascending: false }); draftsList.value = data || []; } catch(e) {} finally { isLoadingDrafts.value = false; } }
const openDraftsModal = () => { fetchDrafts(); showDraftsModal.value = true; }
const loadDraft = (draft: any) => {
    if(cart.value.length > 0 && currentDraftId.value !== draft.id) if(!confirm('Substituir carrinho atual pelo rascunho?')) return;
    currentDraftId.value = draft.id; const data = draft.draft_data;
    if(data) { cart.value = data.cart || []; selectedCustomer.value = data.client || null; payments.value = data.payments || []; discountType.value = data.discount?.type || 'money'; discountValue.value = data.discount?.value || 0; orderNotes.value = data.notes || ''; cpfNota.value = data.cpfNota || ''; }
    showDraftsModal.value = false; appStore.showSnackbar('Rascunho carregado!', 'info');
}
const deleteDraft = async (id: string) => {
    if(!confirm('Excluir este rascunho?')) return;

    // O .select() no final obriga o Supabase a confessar se apagou ou não
    const { data, error } = await supabase
        .from('order_drafts')
        .delete()
        .eq('id', id)
        .select();

    if (error) {
        console.error("Erro fatal no banco:", error);
        appStore.showSnackbar(`Erro do DB: ${error.message}`, 'error');
        return;
    }

    // AQUI ESTÁ A PEGADINHA DO SUPABASE! Se data for vazio, ele mentiu.
    if (!data || data.length === 0) {
        console.error("Supabase bloqueou a exclusão silenciosamente (RLS ou Trigger). ID:", id);
        appStore.showSnackbar(`FALHA: O banco se recusou a apagar o rascunho!`, 'error');
        return;
    }

    appStore.showSnackbar('Rascunho excluído DE VERDADE!', 'success');

    // Atualiza a lista visualmente
    draftsList.value = draftsList.value.filter(d => d.id !== id);

    if (currentDraftId.value === id) {
        currentDraftId.value = null;
    }
}

const emitirNfceSefaz = async () => {
    syncStatus.value.sefaz = 'pending'; syncStatusMessages.value.sefaz = 'Assinando e transmitindo XML Sefaz...'; await new Promise(r => setTimeout(r, 1500));
    syncStatus.value.sefaz = 'success'; syncStatusMessages.value.sefaz = 'Autorizado o uso da NFC-e';
    return { chave_acesso: "352603" + "12345678000199" + "65" + "001" + String(nextOrderNumber.value).padStart(9, '0') + "1" + "84729183", protocolo: "13526" + Math.floor(Math.random() * 10000000000), data_autorizacao: new Date().toISOString() }
}

const handleClientSearch = (val: string) => {
    if (!val || val.length < 3) return;
    clearTimeout(clientSearchTimeout);
    clientSearchTimeout = setTimeout(async () => {
        try {
            const { data } = await supabase.from('customers_mj').select('id, nome, cpf, cnpj').ilike('nome', `%${val}%`).limit(20);
            if(data) {
                const mapped = data.map(c => ({ id: c.id, nome: c.nome || 'Sem Nome', cpf_cnpj: c.cnpj || c.cpf || '' }));
                mapped.forEach(m => { if (!clientList.value.find(existing => existing.id === m.id)) { clientList.value.push(m); } });
            }
        } catch(e) {} finally { isSearchingClients.value = false; }
    }, 500);
}

const submitStoreSale = async () => {
    if (isSubmitting.value) return;
    if (!isOrderValid.value) return;

    isSubmitting.value = true;
    showSyncFeedback.value = true;
    syncStatus.value.db = 'pending';
    syncStatusMessages.value.db = 'Salvando pedido...';

    if (!selectedCustomer.value) selectedCustomer.value = { id: null, nome: 'Consumidor Final', cpf_cnpj: cpfNota.value }
    if(generateRealNfce.value) { syncStatus.value.sefaz = 'pending'; syncStatusMessages.value.sefaz = 'Aguardando fila...'; }

    try {
        const finalPayments = [...payments.value];

        // 1. CONSOLIDAÇÃO DE PAGAMENTOS
        const consolidatedPayments: AddedPayment[] = [];
        for (const p of finalPayments) {
            const existing = consolidatedPayments.find(cp => cp.method.id === p.method.id);
            if (existing) {
                existing.amount += p.amount;
                existing.feeAmount = (existing.feeAmount || 0) + (p.feeAmount || 0);
            } else {
                consolidatedPayments.push({ ...p });
            }
        }

        const paymentsInfo = consolidatedPayments.map(p => `${p.method.nome}: R$ ${(p.amount + (p.feeAmount || 0)).toFixed(2)}`).join(' | ');

        let nfceData = null;
        if (generateRealNfce.value) { nfceData = await emitirNfceSefaz(); lastGeneratedNfceData.value = nfceData; }

        // 2. VERIFICAÇÃO DE ORDER NUMBER
        let finalOrderNumberToSave = nextOrderNumber.value;
        const { data: latestSaleCheck } = await supabase
            .from('store_sales')
            .select('order_number')
            .eq('company_id', companyStore.context)
            .limit(100);

        if (latestSaleCheck && latestSaleCheck.length > 0) {
            const rawLatest = Math.max(...latestSaleCheck.map(d => Number(String(d.order_number).replace(/\D/g, '')) || 0));
            if (rawLatest >= Number(nextOrderNumber.value)) {
                finalOrderNumberToSave = rawLatest + 1;
                nextOrderNumber.value = finalOrderNumberToSave;
            }
        }

        const isUuid = /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/.test(String(selectedCustomer.value.id));
        const finalCustomerId = isUuid ? selectedCustomer.value.id : null;
        const uniqueSaleId = `PDV-${Date.now()}-${Math.floor(Math.random() * 10000)}`;

        // 3. INSERÇÃO DA VENDA (COM A SESSÃO DO CAIXA VINCULADA)
        const { data: saleData, error: saleErr } = await supabase.from('store_sales').insert({
            gestao_click_id: uniqueSaleId,
            company_id: companyStore.context,
            store_id: userStore.activeStoreId,
            customer_id: finalCustomerId,
            customer_name: selectedCustomer.value.nome,
            order_number: Number(finalOrderNumberToSave),
            total_value: finalTotal.value,
            items: cart.value.map(i => ({ produto: { codigo: i.sku, nome_produto: i.product_name, quantidade: i.quantity, valor_unitario: i.unit_price, valor_total: i.total_price, tamanho: i.size, ncm: i.ncm }})),
            status: 'completed',
            financial_status: 'Pendente',
            seller_id: selectedSeller.value,
            seller_name: salespeopleList.value.find(s => s.id === selectedSeller.value)?.nome || userStore.user?.full_name || 'PDV Varejo',
            notes: orderNotes.value,
            date_sale: new Date().toISOString(),
            nfe_key: nfceData ? nfceData.chave_acesso : null
        }).select('id').single()

        if (saleErr) throw saleErr

        createdOrderId.value = saleData.id;

        // CORREÇÃO: EXCLUSÃO FORÇADA DO RASCUNHO IMEDIATAMENTE (NÃO ESPERA O RESTO)
          if (currentDraftId.value) {
                      const idToDelete = currentDraftId.value;
                      currentDraftId.value = null;
                      draftsList.value = draftsList.value.filter(d => d.id !== idToDelete);

                      const { error: draftErr } = await supabase
                          .from('order_drafts')
                          .delete()
                          .eq('id', idToDelete);

                      if (draftErr) {
                          console.error("Falha ao apagar rascunho no DB", draftErr);
                          appStore.showSnackbar(`Erro DB (Rascunho): ${draftErr.message}`, 'error');
                      }
                  }

        // 4. INSERÇÃO DOS RECEBÍVEIS E CAIXA
        for (const p of consolidatedPayments) {
            const isPix = p.method.nome.toLowerCase().includes('pix');
            const paymentValue = p.amount + (p.feeAmount || 0);
            const isCash = cashStore.isCashMethod(p.method.id);

            let finalStatus = 'em_aberto';
            if (isCash) finalStatus = 'pago';
            else if (isPix && !generatePixQr.value) finalStatus = 'pago';

            const { error: recErr } = await supabase.from('finance_receivables').insert({
                company_id: companyStore.context,
                description: `PDV #${finalOrderNumberToSave} - ${p.method.nome}`,
                value: paymentValue,
                status: finalStatus,
                payment_date: finalStatus === 'pago' ? new Date().toISOString() : null,
                paid_at: finalStatus === 'pago' ? new Date().toISOString() : null,
                due_date: new Date().toISOString().split('T')[0],
                competence_date: new Date().toISOString().split('T')[0],
                payment_method_id: p.method.id,
                customer_id: finalCustomerId,
                store_sale_id: saleData.id,
                order_id: null,
                order_number: Number(finalOrderNumberToSave)
            });

            if (recErr && recErr.code !== '23505') console.warn(recErr);

            // CORREÇÃO: INSERÇÃO DIRETA NO CAIXA (BYPASS NO ORDER_ID)
            if (isCash && cashStore.currentSession?.id) {
                try {
                    await supabase.from('mj_cash_movements').insert({
                        session_id: cashStore.currentSession.id,
                        user_id: userStore.user?.id,
                        type: 'sale_cash',
                        amount: paymentValue,
                        description: `Venda PDV #${finalOrderNumberToSave}`,
                        source_table: 'store_sales',
                        source_id: saleData.id
                    });
                } catch (err: any) {
                    console.error('ERRO GRAVE NO CAIXA:', err.message);
                }
            }
        }

        // 5. BAIXA DE ESTOQUE BLINDADA (EVITA ERRO 400)
        for (const item of cart.value) {
            const { data: currentStock, error: stockErr } = await supabase.from('stock').select('*').eq('id', item.product_id).maybeSingle();

            if (currentStock) {
                const updatePayload: any = {};
                const currentQty = Number(currentStock.quantity || currentStock.available_meters || 0);
                const newQty = currentQty - item.quantity;

                // Manda apenas o que realmente existe na tabela deste produto
                if ('quantity' in currentStock) updatePayload.quantity = newQty;
                if ('available_meters' in currentStock) updatePayload.available_meters = newQty;

                if (Object.keys(updatePayload).length > 0) {
                    await supabase.from('stock').update(updatePayload).eq('id', item.product_id);
                }
            }
        }

        // 6. PREPARA TELA DE SUCESSO
        createdOrderNumber.value = Number(finalOrderNumberToSave);
        lastSoldItems.value = [...cart.value];
        lastPaymentText.value = paymentsInfo;
        lastSoldTotal.value = finalTotal.value;
        lastSoldCustomer.value = selectedCustomer.value;
        lastCpfNota.value = cpfNota.value || (selectedCustomer.value?.cpf_cnpj ? selectedCustomer.value.cpf_cnpj : '');
        lastDiscount.value = discountAmount.value;
        lastFee.value = totalFee.value;
        lastNotes.value = orderNotes.value;

        syncStatus.value.db = 'success';
        syncStatusMessages.value.db = 'Venda Registrada!';

        showSyncFeedback.value = false;
        orderCreatedSuccess.value = true;
        tryGeneratePostLaunchPix(consolidatedPayments);

    } catch (e: any) {
        console.error("ERRO NO PDV:", e);
        syncStatus.value.db = 'error';
        syncStatusMessages.value.db = `Erro: ${e.message}`;

        appStore.showSnackbar(`Erro ao finalizar: ${e.message}`, 'error');
        showSyncFeedback.value = false;

        // Só salva rascunho de emergência se o pedido não tiver sido salvo no banco ainda
        if (cart.value.length > 0 && !createdOrderId.value) {
            appStore.showSnackbar('Salvando rascunho de segurança...', 'info');
            await saveDraft();
        }
    } finally {
        isSubmitting.value = false;
    }
}

const tryGeneratePostLaunchPix = async (finalPayments: any[]) => {
    if (!generatePixQr.value) return;
    const pixPayments = finalPayments.filter(p => p.method.nome.toLowerCase().includes('pix')); const amountToCharge = pixPayments.reduce((sum, p) => sum + p.amount + (p.feeAmount || 0), 0); if (amountToCharge <= 0) return;
    const doc = (lastSoldCustomer.value?.cpf_cnpj || lastCpfNota.value || ''); const cleanDoc = doc.replace(/\D/g, ''); const storeCnpj = '20631721000107';
    if (!doc || cleanDoc.length < 11) { appStore.showSnackbar('Sem CPF/CNPJ. Pix não gerado.', 'warning'); return; }
    if (cleanDoc === storeCnpj) { appStore.showSnackbar('Não gere pix pra própria loja.', 'warning'); return; }

    pixState.loading = true; pixState.show = true; pixState.status = 'PENDING'; pixState.displayValue = formatCurrency(amountToCharge);
    try {
        const result = await coraApi.generatePix({ amount: Math.round(amountToCharge * 100), code: `PDV-${createdOrderNumber.value}`, customer: { name: lastSoldCustomer.value?.nome || 'Consumidor', identity: cleanDoc } });
        pixState.qrCodeImage = result.qrCodeUrl; pixState.copyPaste = result.emv; pixState.invoiceId = result.id; startPixPolling();
    } catch (e: any) { appStore.showSnackbar('Erro Pix.', 'error'); pixState.show = false; } finally { pixState.loading = false; }
}

const startPixPolling = () => {
    if (pixState.checkInterval) clearInterval(pixState.checkInterval);
    pixState.checkInterval = setInterval(async () => {
        if (!pixState.invoiceId || pixState.status === 'PAID') return;
        try {
            const res = await coraApi.checkStatus(pixState.invoiceId);
            if (res && res.status === 'PAID') { pixState.status = 'PAID'; clearInterval(pixState.checkInterval!); await confirmPixPaymentInDb(); appStore.showSnackbar('Pix Pago!', 'success'); }
        } catch (err) {}
    }, 4000);
}

const confirmPixPaymentInDb = async () => {
    if (!createdOrderId.value) return;
    const { data: bank } = await supabase.from('finance_accounts').select('id').ilike('name', '%Cora%').eq('is_active', true).limit(1).maybeSingle();
    const targetBankId = bank?.id || null;
    const pixMethod = paymentMethods.value.find(m => m.nome.toLowerCase().includes('pix') || m.nome.toLowerCase().includes('instantâneo'));
    const targetMethodId = pixMethod ? pixMethod.id : null;
    const { data: receivables } = await supabase.from('finance_receivables').select('*').eq('store_sale_id', createdOrderId.value);
    if (receivables && receivables.length > 0) {
        const receivablesToUpdate = receivables.filter(rec => rec.status === 'em_aberto' || (rec.status === 'pago' && !rec.bank_account_id) );
        for (const rec of receivablesToUpdate) { await supabase.from('finance_receivables').update({ status: 'pago', paid_at: new Date().toISOString(), receipt_date: new Date().toISOString().split('T')[0], bank_account_id: targetBankId, payment_method_id: targetMethodId || rec.payment_method_id, description: rec.description.includes('(Confirmado via Pix)') ? rec.description : rec.description + ' (Confirmado via Pix)' }).eq('id', rec.id); }
    }
    await supabase.from('store_sales').update({ financial_status: 'Faturado' }).eq('id', createdOrderId.value);
}

const copyPixCode = () => { navigator.clipboard.writeText(pixState.copyPaste); appStore.showSnackbar('Copiado!', 'success'); }
const getFormattedPaymentText = () => { if (payments.value.length > 0) { return payments.value.map(p => `${p.method.nome}: ${formatCurrency(p.amount + (p.feeAmount||0))}`).join(' | '); } if (selectedPaymentMethod.value) { return `${selectedPaymentMethod.value.nome}: ${formatCurrency(finalTotal.value)}`; } return 'Dinheiro'; }

const handleGenerateNonFiscalReceipt = async (isPreview = false) => {
    isPdfGenerating.value = true;
    try {
        const is58 = printFormat.value === '58mm';
        const pageW = is58 ? 58 : 80;
        const itemsToPrint = isPreview ? (cart.value.length > 0 ? cart.value : [{ product_name: 'Produto Exemplo', size: 'M', quantity: 1, unit_price: 100, total_price: 100 }]) : lastSoldItems.value;
        const estHeight = 150 + (itemsToPrint.length * 10);
        const doc = new jsPDF({ orientation: "p", unit: "mm", format: printFormat.value === 'a4' ? 'a4' : [pageW, estHeight] });
        let y = 5;

        if (printFormat.value === '80mm' || printFormat.value === '58mm') {
            try {
                const logoB64 = await imageToBase64(logoCajuia);
                const logoW = 36; const logoH = 16;
                doc.addImage(logoB64, "PNG", (pageW / 2) - (logoW / 2), y, logoW, logoH);
                y += logoH + 4;
            } catch (e) { /* ignore */ }

            doc.setFont("helvetica", "bold"); doc.setFontSize(is58 ? 10 : 12);
            doc.text(currentCompanyName.value, pageW / 2, y, { align: "center" }); y += 5;
            doc.setFontSize(is58 ? 7 : 8); doc.setFont("helvetica", "normal");

            doc.setFont("helvetica", "bold"); doc.setFontSize(is58 ? 8 : 10);
            doc.text(isPreview ? "PREVIEW DE IMPRESSÃO" : "RECIBO DE VENDA (NÃO FISCAL)", pageW / 2, y, { align: "center" }); y += 6;

            doc.setFont("helvetica", "normal"); doc.setFontSize(is58 ? 7 : 8);
            const orderNum = isPreview ? "PREVIEW" : createdOrderNumber.value;
            const dateStr = format(new Date(), 'dd/MM/yyyy HH:mm');
            doc.text(`Venda: #${orderNum} - Data: ${dateStr}`, pageW / 2, y, { align: "center" }); y += 8;

            const customer = isPreview ? (selectedCustomer.value || { nome: 'Cliente Preview' }) : (lastSoldCustomer.value || { nome: 'Consumidor Final' });
            const docCpf = isPreview ? cpfNota.value : (lastCpfNota.value || '');
            const seller = isPreview ? (salespeopleList.value.find(s => s.id === selectedSeller.value)?.nome || userStore.user?.full_name || 'PDV Varejo') : (salespeopleList.value.find(s => s.id === selectedSeller.value)?.nome || userStore.user?.full_name || 'PDV Varejo');

            doc.setFont("helvetica", "bold"); doc.text("CONSUMIDOR", 2, y); y += 4;
            doc.setFont("helvetica", "normal"); doc.text(`Nome: ${customer.nome}`, 2, y); y += 4;
            if(docCpf) { doc.text(`CPF/CNPJ: ${docCpf}`, 2, y); y += 4; }
            doc.text(`Vendedor: ${seller}`, 2, y); y += 4;
            doc.setLineWidth(0.2); doc.line(2, y, pageW - 2, y); y += 4;
            doc.setFont("helvetica", "bold"); doc.text("QTD   DESCRIÇÃO              TOTAL", 2, y); y += 4;
            doc.line(2, y, pageW - 2, y); y += 4;

            doc.setFont("helvetica", "normal");
            let totalVal = 0;
            itemsToPrint.forEach(item => {
                const descText = `${item.product_name} ${item.size && item.size !== 'U' ? '(Tam: '+item.size+')' : ''}`;
                const desc = doc.splitTextToSize(descText, is58 ? 26 : 40);
                doc.text(`${item.quantity} UN`, 2, y); doc.text(desc, is58 ? 14 : 16, y); doc.text(`${formatCurrency(item.total_price)}`, pageW - 2, y, { align: "right" });
                y += (desc.length * 4); totalVal += item.total_price;
            });
            doc.line(2, y, pageW - 2, y); y += 5;

            const tDiscount = isPreview ? discountAmount.value : (lastDiscount.value || 0);
            const tFee = isPreview ? totalFee.value : (lastFee.value || 0);
            const tFinal = isPreview ? finalTotal.value : (lastSoldTotal.value || 0);
            const pgtosText = isPreview ? getFormattedPaymentText() : lastPaymentText.value;

            doc.setFont("helvetica", "normal");
            doc.text("Subtotal:", 2, y); doc.text(formatCurrency(totalVal), pageW - 2, y, { align: "right" }); y += 4;
            if (tDiscount > 0) { doc.text("Desconto:", 2, y); doc.text(`-${formatCurrency(tDiscount)}`, pageW - 2, y, { align: "right" }); y += 4; }
            if (tFee > 0) { doc.text("Acréscimo:", 2, y); doc.text(`+${formatCurrency(tFee)}`, pageW - 2, y, { align: "right" }); y += 4; }

            doc.setFont("helvetica", "bold"); doc.setFontSize(is58 ? 10 : 12);
            doc.text(`TOTAL R$:`, 2, y); doc.text(formatCurrency(tFinal), pageW - 2, y, { align: "right" }); y += 6;
            doc.setFontSize(is58 ? 7 : 8); doc.setFont("helvetica", "normal");
            const splitPgtos = doc.splitTextToSize(`PGTO: ${pgtosText}`, pageW - 4); doc.text(splitPgtos, 2, y); y += (splitPgtos.length * 4) + 2;

            const notes = isPreview ? orderNotes.value : lastNotes.value;
            if(notes) { const splitNotes = doc.splitTextToSize("Obs: " + notes, pageW - 4); doc.text(splitNotes, 2, y); y += (splitNotes.length * 4) + 2; }
            y += 4; doc.setFont("helvetica", "bold"); doc.text("OBRIGADO PELA PREFERÊNCIA!", pageW / 2, y, { align: "center" });

            doc.autoPrint();
            window.open(URL.createObjectURL(doc.output('blob')), '_blank');

            if(isPreview) appStore.showSnackbar('Enviado para visualização/impressão!', 'success');

        } else {
            doc.setFont("helvetica", "bold"); doc.setFontSize(16);
            doc.text(`Recibo #${isPreview ? "PREVIEW" : createdOrderNumber.value} - ${currentCompanyName.value}`, 10, y); y += 10;
            doc.setFontSize(12); doc.setFont("helvetica", "normal");
            doc.text(`Cliente: ${isPreview ? (selectedCustomer.value?.nome || 'Preview') : (lastSoldCustomer.value?.nome || 'Consumidor')}`, 10, y); y += 6;
            doc.text(`Data: ${format(new Date(), 'dd/MM/yyyy HH:mm')}`, 10, y); y += 10;

            const tableBody = itemsToPrint.map(i => [`${i.product_name} (Tam: ${i.size})`, i.quantity, 'UN', formatCurrency(i.unit_price), formatCurrency(i.total_price)]);
            autoTable(doc, { startY: y, head: [['Produto', 'Qtd', 'Un', 'Valor Un.', 'Total']], body: tableBody });
            y = (doc as any).lastAutoTable.finalY + 10;
            doc.setFont("helvetica", "bold"); doc.setFontSize(14);
            doc.text(`TOTAL GERAL: ${formatCurrency(isPreview ? finalTotal.value : lastSoldTotal.value)}`, 190, y, { align: "right" });

            doc.autoPrint();
            window.open(URL.createObjectURL(doc.output('blob')), '_blank');
        }
    } catch(e) { console.error(e); } finally { isPdfGenerating.value = false; }
}

const handleTestPrint = () => { handleGenerateNonFiscalReceipt(true); }

const handleSessionOpened = () => { appStore.showSnackbar('Caixa aberto!', 'success'); showCashOpeningModal.value = false; cashStore.checkActiveSession(); }
const handleOperationSuccess = () => { showOperationsModal.value = false; cashStore.checkActiveSession(); }

const { generateClosingReport } = useCashReport();
const showSessionEndedModal = ref(false);
const lastClosedSession = ref<any>(null);

const getDiffColor = (diff: number) => { return (!diff || diff === 0) ? 'text-success' : (diff > 0 ? 'text-info' : 'text-error'); };
const getDiffLabel = (diff: number) => { return (!diff || diff === 0) ? 'Sem Divergência' : (diff > 0 ? `Sobra: ${formatCurrency(diff)}` : `Quebra: ${formatCurrency(diff)}`); };

// 👇 ADICIONE ESTE BLOCO LOGO ABAIXO 👇
const calculatedDifference = computed(() => {
    if (!lastClosedSession.value || !lastClosedSession.value.session) return 0;

    const session = lastClosedSession.value.session;
    const movements = lastClosedSession.value.movements || [];

    const initial = Number(session.initial_balance || 0);
    const finalUser = Number(session.final_balance_user || 0);

    let expected = initial;
    movements.forEach((m: any) => {
        // 👇 A MÁGICA AQUI: Força o número a ser positivo (ignora o sinal do DB)
        const val = Math.abs(Number(m.amount || 0));

        // Soma as entradas
        if (m.type === 'supply' || m.type === 'sale_cash' || m.type === 'in_audit') {
            expected += val;
        }
        // Subtrai as saídas reais
        else if (m.type === 'bleed' || m.type === 'out_audit') {
            expected -= val;
        }
    });

    return finalUser - expected;
});
// 👆 FIM DO BLOCO 👆

const handleSessionClosed = (result: any) => {
    showCashClosingModal.value = false;
    lastClosedSession.value = result;
    cashStore.checkActiveSession();
    showSessionEndedModal.value = true;
};

const reprintZReport = () => {
    if (!lastClosedSession.value) return;
    generateClosingReport(
        lastClosedSession.value.session,
        lastClosedSession.value.movements,
        userStore.activeStoreName || 'Loja',
        userStore.profile?.full_name || 'Operador',
        lastClosedSession.value.detailedSales || []
    );
    appStore.showSnackbar('Gerando Relatório Z...', 'success');
};

const filterClients = (title: string, query: string, item: any) => { const text = query.toLowerCase(); const n = item.raw.nome ? item.raw.nome.toLowerCase() : ''; const doc = item.raw.cpf_cnpj ? item.raw.cpf_cnpj.replace(/\D/g, '') : ''; return n.includes(text) || doc.includes(text); };
const resetFormState = () => {
    cart.value = []; payments.value = []; discountValue.value = 0; paymentAmountInput.value = 0; orderNotes.value = ''; cpfNota.value = '';
    selectedCustomer.value = null; activeTab.value = 'items'; lastGeneratedNfceData.value = null;
    selectedSeller.value = null;
    orderCreatedSuccess.value = false; pixState.show = false; pixState.status = 'PENDING';

    createdOrderId.value = null;

    if(pixState.checkInterval) clearInterval(pixState.checkInterval);

    isSubmitting.value = false;
    showSyncFeedback.value = false;
    currentDraftId.value = null;

    fetchAllData(); fetchNextOrderNumber();
}

const handleGlobalKeydown = (e: KeyboardEvent) => {
    if (sizeModal.show) {
        const key = e.key.toUpperCase();
        if (['P', 'M', 'G', 'U'].includes(key)) { e.preventDefault(); confirmAddToCart(key); }
        else if (e.key.toUpperCase() === 'E') { e.preventDefault(); confirmAddToCart('GG'); }
        return;
    }
    if (e.key === 'F12' || e.key === 'End') {
        e.preventDefault();
        if (activeTab.value === 'items') { activeTab.value = 'payment'; }
        else if (isOrderValid.value && !isSubmitting.value) { submitStoreSale(); }
        return;
    }
    if (e.key === 'Escape' && !quickClientModal.show) { if(orderCreatedSuccess.value) { resetFormState(); return; } if(activeTab.value === 'payment') activeTab.value = 'items'; else if(cart.value.length > 0 && confirm('Limpar carrinho?')) clearCart(); return; }

    const target = e.target as HTMLElement
    if (['INPUT', 'TEXTAREA'].includes(target.tagName)) return
    const currentTime = Date.now()
    if (currentTime - lastKeyTime.value > 50) barcodeBuffer.value = ''
    lastKeyTime.value = currentTime
    if (e.key === 'Enter') {
            if (barcodeBuffer.value.length > 2) {
                e.preventDefault();
                const found = products.value.find(p => p.barcode === barcodeBuffer.value || p.sku === barcodeBuffer.value);
                if (found) { openSizeModal(found); } else appStore.showSnackbar(`Código ${barcodeBuffer.value} não localizado.`, 'warning');
            }
            barcodeBuffer.value = ''
        } else if (e.key.length === 1) barcodeBuffer.value += e.key
}

onMounted(async () => {
    isCheckingSession.value = true;
    if (!userStore.profile?.id) await userStore.fetchProfile();
    if (userStore.isAdmin) { await fetchStoresWithStatus(); await fetchAdminStoreStats(); }
    if (userStore.activeStoreId) { await cashStore.checkActiveSession(); }
    fetchAllData(); fetchNextOrderNumber();
    window.addEventListener('keydown', handleGlobalKeydown);
    clockInterval = setInterval(() => realTimeClock.value = format(new Date(), 'HH:mm:ss'), 1000);
    isCheckingSession.value = false;
})
onUnmounted(() => { window.removeEventListener('keydown', handleGlobalKeydown); clearInterval(clockInterval); if(pixState.checkInterval) clearInterval(pixState.checkInterval); })
</script>

<style scoped>
.pdv-layout { position: relative; font-family: 'Roboto', sans-serif; }
.clean-input :deep(.v-field__input) { min-height: 38px; padding-top: 0; padding-bottom: 0; }
.product-grid-gap { gap: 12px; margin: -6px; }

/* Theme Colors */
.bg-background { background-color: #f4f6f8; }
.bg-surface { background-color: #ffffff; }
.bg-surface-light { background-color: #f8fafc; }
.bg-glass-dark { background-color: #1a1a1f; }
.bg-glass-header { background-color: rgba(26, 26, 31, 0.8); backdrop-filter: blur(10px); }
.border-bottom-white-05 { border-bottom: 1px solid rgba(255, 255, 255, 0.05); }
.border-white-10 { border-color: rgba(255, 255, 255, 0.1) !important; }
.border-white-20 { border-color: rgba(255, 255, 255, 0.2) !important; }
.text-high-emphasis { color: rgba(0, 0, 0, 0.87); }
.text-medium-emphasis { color: rgba(0, 0, 0, 0.6); }

/* Components */
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

.chip-3d {
    box-shadow: 0 3px 5px rgba(0,0,0,0.12), inset 0 1px 0 rgba(255,255,255,0.25) !important;
    text-shadow: 0 1px 2px rgba(0,0,0,0.25);
    font-weight: 900;
}

.ui-field :deep(.v-field) { border-radius: 6px !important; }

/* Product Cards */
.product-card { cursor: pointer; overflow: hidden; }
.product-card:hover .product-img { transform: scale(1.05); }
.product-img { transition: transform 0.3s ease; }
.cart-badge { position: absolute; top: 6px; right: 6px; z-index: 5; }
.stock-overlay { position: absolute; inset: 0; background: rgba(255,255,255,0.8); z-index: 2; backdrop-filter: blur(2px); }
.discount-ribbon { position: absolute; top: 8px; left: 0; z-index: 10; }

/* Typography & Layout Utils */
.line-clamp-2 { display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; }
.lh-1 { line-height: 1.1; }
.border-dashed { border-style: dashed !important; border-width: 1px; border-color: rgba(0,0,0,0.15) !important; }
.border-b-dashed { border-bottom: 1px dashed rgba(0,0,0,0.15) !important; }
.border-thin { border: 1px solid rgba(0,0,0,0.08) !important; }
.tracking-widest { letter-spacing: 0.05em; }
.ls-1 { letter-spacing: 0.5px; }
.shadow-up { box-shadow: 0 -4px 12px rgba(0,0,0,0.05); }
.shadow-soft { box-shadow: 0 4px 12px rgba(0,0,0,0.1); }
.pill-ref { font-size: 11px; font-weight: 900; font-family: monospace; background: rgba(0,0,0,0.06); padding: 4px 6px; border-radius: 4px; }

/* Custom Scrollbar */
.custom-scroll { scrollbar-gutter: stable; }
.custom-scroll::-webkit-scrollbar { width: 6px; height: 6px; }
.custom-scroll::-webkit-scrollbar-track { background: transparent; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128, 0.25); border-radius: 4px; }

/* Pulse Status Alerts */
@keyframes pulse-green { 0% { opacity: 1; } 50% { opacity: 0.5; } 100% { opacity: 1; } }
.icon-pulse { animation: pulse-green 2s infinite; }

/* PIX UI ANIMATIONS */
.icon-circle-xl { width: 110px; height: 110px; border-radius: 50%; display: flex; align-items: center; justify-content: center; }
.icon-circle-lg { width: 80px; height: 80px; border-radius: 50%; display: flex; align-items: center; justify-content: center; }
.bg-green-gradient { background: linear-gradient(135deg, #43A047, #2E7D32); }
.bg-primary-gradient { background: linear-gradient(135deg, #1976D2, #1565C0); }
.scale-pop { animation: scalePop 0.6s cubic-bezier(0.175, 0.885, 0.32, 1.275); }
@keyframes scalePop { 0% { transform: scale(0.5); opacity: 0; } 50% { transform: scale(1.1); } 100% { transform: scale(1); opacity: 1; } }
.animate-pop { animation: popIn 0.5s cubic-bezier(0.175, 0.885, 0.32, 1.275) forwards; }
@keyframes popIn { 0% { transform: scale(0.5); opacity: 0; } 100% { transform: scale(1); opacity: 1; } }
.fade-in { animation: fadeIn 0.4s ease-in; }
@keyframes fadeIn { from { opacity: 0; } to { opacity: 1; } }

/* TELA SELEÇÃO DE LOJA (ADMIN) */
.kpi-card { color: white; position: relative; overflow: hidden; height: 110px; }
.kpi-bg-icon { position: absolute; right: -15px; bottom: -15px; opacity: 0.2; transform: rotate(-15deg); }
.kpi-bg-icon .v-icon { font-size: 90px; }
.kpi-label { font-size: 13px; font-weight: 900; letter-spacing: 0.5px; text-transform: uppercase; }
.kpi-value { font-size: 26px; font-weight: 900; }
.bg-gradient-purple { background: linear-gradient(135deg, #7b1fa2, #4a148c); }
.bg-gradient-info { background: linear-gradient(135deg, #0288d1, #005b9f); }
.bg-gradient-success { background: linear-gradient(135deg, #00c853, #009624); }

.status-indicator { width: 12px; height: 12px; border-radius: 50%; display: inline-block; }
.pulse { animation: pulse-green 2s infinite; }
.bg-grey { background-color: #9e9e9e; }

/* Grid Styles */
.grid-header, .grid-row {
    display: grid;
    align-items: stretch;
    width: 100%;
    border-bottom: 1px solid rgba(0,0,0,0.08);
}
.cell { padding: 8px 10px; display: flex; align-items: center; border-right: 1px solid rgba(0,0,0,0.05); font-size: 13px; }
.cell:last-child { border-right: none; }
.header-text { padding: 12px 10px; font-size: 11px; font-weight: 900; text-transform: uppercase; letter-spacing: 0.5px; display: flex; align-items: center; color: rgba(0,0,0,0.7); }
.cell.center, .header-text.center { justify-content: center; text-align: center; }
.cell.right, .header-text.right { justify-content: flex-end; text-align: right; }

.grid-surface-light .cell { background: #f5f7fa; color: rgba(0,0,0,0.9); border-color: rgba(0,0,0,0.12); }
.grid-surface-dark .cell { background: rgba(255,255,255,0.08); color: rgba(255,255,255,0.80); border-color: rgba(255,255,255,0.10); }

.grid-row-light .cell { background: #fff; border-color: rgba(0,0,0,0.08); transition: background-color 0.2s ease; }
.grid-row-dark .cell { background: rgba(255,255,255,0.04); border-color: rgba(255,255,255,0.08); }
.hover-bg-row:hover .cell { background: #F8FAFC !important; cursor: default; }
.grid-row-dark.hover-bg-row:hover .cell { background: rgba(255,255,255,0.07) !important; }

.zebra-light-a .cell { background: #ffffff; }
.zebra-light-b .cell { background: #fafafa; }
.zebra-dark-a .cell { background: rgba(255,255,255,0.03); }
.zebra-dark-b .cell { background: rgba(255,255,255,0.06); }

.sticky-head { position: sticky; top: 0; z-index: 10; box-shadow: 0 4px 6px -4px rgba(0, 0, 0, 0.1); }

/* QR Code Borders */
.absolute-corner { position: absolute; width: 24px; height: 24px; border-style: solid; }
.top-left { top: -1px; left: -1px; border-width: 3px 0 0 3px; border-radius: 4px 0 0 0; }
.top-right { top: -1px; right: -1px; border-width: 3px 3px 0 0; border-radius: 0 4px 0 0; }
.bottom-left { bottom: -1px; left: -1px; border-width: 0 0 3px 3px; border-radius: 0 0 0 4px; }
.bottom-right { bottom: -1px; right: -1px; border-width: 0 3px 3px 0; border-radius: 0 0 4px 0; }

.hover-bg-grey-darken-3:hover { background-color: #333333; }
.hover-bg-grey-lighten-5:hover { background-color: #f5f5f5; }

</style>
