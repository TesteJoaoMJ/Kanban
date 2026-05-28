<template>
  <div
    class="payables-layout font-sans fill-height d-flex flex-column relative overflow-hidden"
    :class="theme.global.current.value.dark ? 'bg-glass-dark text-white' : 'bg-grey-lighten-5 text-grey-darken-4'"
  >
    <div v-if="theme.global.current.value.dark" class="background-carousel-wrapper">
       <div class="background-overlay"></div>
    </div>

    <div class="content-wrapper d-flex flex-column fill-height z-10 relative">

      <div
        v-if="!isMobileFullscreen"
        class="orders-executive-header flex-shrink-0"
        :class="theme.global.current.value.dark ? 'orders-executive-header--dark' : 'orders-executive-header--light'"
      >
        <div class="orders-header-main d-flex flex-column flex-lg-row align-lg-center justify-space-between">
          <div class="orders-header-left d-flex align-start">
            <div class="orders-header-icon card-3d mr-4">
              <v-icon size="26">mdi-clipboard-text-clock-outline</v-icon>
            </div>
            <div class="orders-header-copy">
              <div class="orders-breadcrumb d-none d-md-flex align-center">
                <span>COMERCIAL</span>
                <v-icon size="13" class="mx-2">mdi-chevron-right</v-icon>
                <span>Gestão de Pedidos</span>
              </div>

              <div class="d-flex align-center flex-wrap mt-1" style="gap: 10px;">
                <h1 class="orders-title">Gestão de Pedidos</h1>
                <v-chip size="small" :color="orderModeColor" variant="flat" class="font-weight-black chip-3d text-uppercase orders-mode-chip">
                  {{ orderModeTitle }}
                </v-chip>
                <v-chip v-if="isSellerTenantLocked" size="small" color="blue-grey" variant="tonal" class="font-weight-black">
                  {{ sellerLockedCompanyName }}
                </v-chip>
              </div>

              <div class="orders-subtitle mt-1">
                {{ orderModeSubtitle }}
              </div>

              <div v-if="showContextSwitcher" class="context-switcher-row d-flex align-center flex-wrap mt-3">
                <v-btn
                  v-for="btn in contextButtons"
                  :key="btn.id"
                  size="x-small"
                  height="26"
                  :variant="companyStore.context === btn.id ? 'flat' : 'tonal'"
                  :color="companyStore.context === btn.id ? (btn.isHolding ? 'purple' : 'success') : 'grey'"
                  class="font-weight-bold btn-3d px-4 rounded-pill flex-shrink-0"
                  style="font-size: 10px; letter-spacing: 0.5px;"
                  @click="setCompanyFilter(btn.id)"
                >
                  {{ btn.name }}
                </v-btn>
              </div>
            </div>
          </div>

          <div class="orders-header-actions d-flex flex-column align-stretch align-lg-end mt-4 mt-lg-0">
            <v-btn-toggle
              v-if="false"
              v-model="selectedOrderMode"
              density="compact"
              mandatory
              divided
              class="order-mode-toggle btn-3d rounded-lg mb-3"
              :color="orderModeColor"
            >
              <v-btn value="sales" class="font-weight-black text-caption px-3">
                <v-icon start size="16">mdi-cash-register</v-icon>
                Comercial
              </v-btn>
              <v-btn value="billing" class="font-weight-black text-caption px-3">
                <v-icon start size="16">mdi-file-document-check</v-icon>
                Faturamento
              </v-btn>
              <v-btn value="admin" class="font-weight-black text-caption px-3">
                <v-icon start size="16">mdi-view-dashboard-edit</v-icon>
                Completo
              </v-btn>
            </v-btn-toggle>

            <div class="d-flex align-center justify-end flex-wrap" style="gap: 10px;">
              <v-btn icon variant="flat" class="btn-3d orders-refresh-btn" :loading="loading" @click="fetchOrders">
                <v-icon size="20">mdi-refresh</v-icon>
              </v-btn>

              <v-menu location="bottom end">
                <template v-slot:activator="{ props }">
                  <v-btn
                    color="primary"
                    variant="flat"
                    class="btn-3d px-4 px-md-6 font-weight-bold text-button text-uppercase letter-spacing-1"
                    prepend-icon="mdi-plus"
                    height="42"
                    v-bind="props"
                  >
                    Novo Pedido
                    <v-icon end>mdi-chevron-down</v-icon>
                  </v-btn>
                </template>
                <v-list density="compact" class="rounded-lg border-thin shadow-lg mt-2" :bg-color="theme.global.current.value.dark ? '#1E1E24' : 'white'">
                  <v-list-item :to="{ name: 'NewOrderComNota' }">
                    <template v-slot:prepend><v-icon size="20" class="mr-3 text-success">mdi-file-document-check-outline</v-icon></template>
                    <v-list-item-title class="font-weight-bold" style="font-size: 13px;">Com Nota (Fiscal)</v-list-item-title>
                  </v-list-item>
                  <v-divider class="my-1 border-opacity-10"></v-divider>
                  <v-list-item :to="{ name: 'NewOrderSemNota' }">
                    <template v-slot:prepend><v-icon size="20" class="mr-3 text-grey">mdi-file-document-remove-outline</v-icon></template>
                    <v-list-item-title class="font-weight-bold" style="font-size: 13px;">Sem Nota (Gerencial)</v-list-item-title>
                  </v-list-item>
                </v-list>
              </v-menu>
            </div>
          </div>
        </div>
      </div>

      <div v-if="!isMobileFullscreen" class="px-4 px-md-6 pt-2 pt-md-4 pb-2 flex-shrink-0">

         <div v-if="mobile" class="d-flex flex-column gap-2">
             <div class="d-flex align-center gap-2">
                 <v-btn color="grey-darken-3" variant="flat" class="btn-3d px-3" height="44" @click="mobileMenuOpen = true">
                     <v-icon>mdi-menu</v-icon>
                 </v-btn>

                 <div class="search-wrap d-flex align-center flex-grow-1" :class="theme.global.current.value.dark ? 'search-dark' : 'search-light'">
                    <v-icon :color="theme.global.current.value.dark ? 'white-70' : 'grey-darken-1'">mdi-magnify</v-icon>
                    <input v-model="search" type="text" placeholder="Buscar..." class="clean-input flex-grow-1 px-2" style="font-size: 13px;"/>
                 </div>
             </div>

             <div v-if="hasActiveFilters" class="d-flex align-center justify-space-between">
                 <div class="text-caption text-primary font-weight-bold">
                    <v-icon size="small" start>mdi-filter</v-icon> Filtros Ativos
                 </div>
                 <v-chip size="x-small" color="primary" variant="text" @click="clearFilters">Limpar</v-chip>
             </div>
         </div>

         <div v-else class="controls-bar d-flex flex-column gap-3 unified-taskbar" :class="theme.global.current.value.dark ? 'controls-dark' : 'controls-light'">
            <div class="taskbar-main">

                <div class="search-wrap taskbar-search d-flex align-center" :class="theme.global.current.value.dark ? 'search-dark' : 'search-light'">
                  <v-icon :color="theme.global.current.value.dark ? 'white-70' : 'grey-darken-1'">mdi-magnify</v-icon>
                  <input v-model="search" type="text" placeholder="Buscar cliente, ID, vendedor ou valor exato..." class="clean-input flex-grow-1 px-2" style="font-size: 13px;"/>
                </div>

                <div class="taskbar-right">
                <v-menu location="bottom end" :close-on-content-click="true">
                    <template v-slot:activator="{ props }">
                        <v-btn v-bind="props" variant="outlined" class="btn-3d font-weight-bold taskbar-action-btn" height="42" prepend-icon="mdi-dots-grid" append-icon="mdi-chevron-down" :color="theme.global.current.value.dark ? 'white' : 'grey-darken-2'">
                            Mais ações
                        </v-btn>
                    </template>

                    <v-card class="orders-filter-tray orders-actions-tray rounded-xl border-thin shadow-xl" :class="theme.global.current.value.dark ? 'orders-filter-tray-dark text-white' : 'orders-filter-tray-light'" width="350">
                        <div class="tray-header tray-header-compact pa-3 d-flex align-center justify-space-between">
                            <div class="d-flex align-center">
                                <div class="tray-icon mr-3"><v-icon size="18">mdi-dots-grid</v-icon></div>
                                <div>
                                    <div class="text-subtitle-2 font-weight-black">Mais ações</div>
                                    <div class="text-caption opacity-70">Relatórios, atualização e ferramentas rápidas.</div>
                                </div>
                            </div>
                        </div>

                        <div v-if="canSwitchOrderMode" class="tray-section px-3 pb-3">
                            <div class="tray-section-title mb-2">Modo da tela</div>
                            <div class="tray-mode-grid">
                                <button type="button" class="tray-mode-btn" :class="selectedOrderMode === 'sales' ? 'tray-mode-btn--active-sales' : ''" @click="selectedOrderMode = 'sales'">
                                    <v-icon size="15">mdi-cash-register</v-icon>
                                    <span>Comercial</span>
                                </button>
                                <button type="button" class="tray-mode-btn" :class="selectedOrderMode === 'billing' ? 'tray-mode-btn--active-billing' : ''" @click="selectedOrderMode = 'billing'">
                                    <v-icon size="15">mdi-file-document-check</v-icon>
                                    <span>Faturamento</span>
                                </button>
                                <button type="button" class="tray-mode-btn" :class="selectedOrderMode === 'admin' ? 'tray-mode-btn--active-admin' : ''" @click="selectedOrderMode = 'admin'">
                                    <v-icon size="15">mdi-view-dashboard-edit</v-icon>
                                    <span>Completo</span>
                                </button>
                            </div>
                        </div>

                        <div v-if="canUseBillingActions" class="tray-section px-3 pb-3">
                            <div class="tray-section-title mb-2">Relatórios</div>
                            <div class="tray-action-list">
                                <button class="tray-action" type="button" :disabled="generatingPdf" @click="generateOrderReport('production')">
                                    <span class="tray-action-icon text-primary"><v-icon size="18">mdi-printer-outline</v-icon></span>
                                    <span>
                                        <strong>Relatório de Produção</strong>
                                        <small>Resumo operacional dos pedidos.</small>
                                    </span>
                                </button>
                                <button class="tray-action" type="button" :disabled="generatingPdf" @click="generateOrderReport('full')">
                                    <span class="tray-action-icon text-indigo"><v-icon size="18">mdi-file-pdf-box</v-icon></span>
                                    <span>
                                        <strong>Relatório Financeiro</strong>
                                        <small>Conferência financeira e fiscal.</small>
                                    </span>
                                </button>
                            </div>
                        </div>

                        <div class="tray-section px-3 pb-3">
                            <button class="tray-action tray-action--refresh" type="button" @click="fetchOrders">
                                <span class="tray-action-icon text-blue-grey"><v-icon size="18">mdi-refresh</v-icon></span>
                                <span>
                                    <strong>Atualizar lista</strong>
                                    <small>Recarrega pedidos, pendências e documentos.</small>
                                </span>
                            </button>
                        </div>
                    </v-card>
                </v-menu>

                <v-menu location="bottom end" :close-on-content-click="false">
                    <template v-slot:activator="{ props }">
                        <v-btn v-bind="props" variant="flat" color="primary" class="btn-3d font-weight-black taskbar-action-btn" height="42" prepend-icon="mdi-filter-variant" append-icon="mdi-chevron-down">
                            Filtros
                        </v-btn>
                    </template>

                    <v-card class="orders-filter-tray rounded-xl border-thin shadow-xl" :class="theme.global.current.value.dark ? 'orders-filter-tray-dark text-white' : 'orders-filter-tray-light'" width="360">
                        <div class="tray-header tray-header-compact pa-3 d-flex align-center justify-space-between">
                            <div class="d-flex align-center">
                                <div class="tray-icon mr-3"><v-icon size="18">mdi-filter-variant</v-icon></div>
                                <div>
                                    <div class="text-subtitle-2 font-weight-black">Filtros da lista</div>
                                    <div class="text-caption opacity-70">Filtre status, datas, vendedor e período.</div>
                                </div>
                            </div>
                            <v-btn icon="mdi-close" variant="text" size="x-small" @click="fetchOrders"></v-btn>
                        </div>

                        <div class="tray-section px-3 pb-3">
                            <div class="tray-section-title mb-2">Período</div>
                            <div class="tray-period-grid mb-4">
                                <v-btn v-for="period in periodOptions" :key="period.value" :color="currentPeriod === period.value ? 'primary' : (theme.global.current.value.dark ? 'white' : 'grey-darken-1')" :variant="currentPeriod === period.value ? 'flat' : 'tonal'" class="font-weight-black period-filter-btn" height="32" @click="selectPeriod(period.value)">{{ period.label }}</v-btn>
                            </div>

                            <div class="tray-section-title mb-2">Filtros avançados</div>
                            <v-select v-model="filterFinancialStatus" :items="statusFilters" item-title="label" item-value="value" :label="activeOrderMode === 'sales' ? 'Recebimento' : 'Status Financeiro'" density="compact" variant="outlined" hide-details class="tray-field tray-field-compact mb-2"></v-select>
                            <v-select v-model="filterProductionStatus" :items="productionStatusFilters" label="Status Produção" density="compact" variant="outlined" hide-details class="tray-field tray-field-compact mb-2"></v-select>
                            <v-autocomplete v-if="activeOrderMode !== 'sales'" v-model="filterSeller" :items="availableSellers" label="Vendedor" density="compact" variant="outlined" hide-details class="tray-field tray-field-compact mb-2" clearable></v-autocomplete>

                            <div class="tray-mini-label mb-2">Data de criação</div>
                            <div class="tray-date-row mb-3">
                                <v-text-field v-model="filterDateStart" label="Início" type="date" density="compact" variant="outlined" hide-details class="tray-field tray-field-compact"></v-text-field>
                                <v-text-field v-model="filterDateEnd" label="Fim" type="date" density="compact" variant="outlined" hide-details class="tray-field tray-field-compact"></v-text-field>
                            </div>

                            <div class="d-flex justify-space-between align-center gap-2">
                                <v-btn size="small" variant="text" color="error" class="font-weight-black px-2" @click="clearFilters">Limpar filtros</v-btn>
                                <v-btn size="small" color="primary" variant="flat" @click="fetchOrders" class="btn-3d font-weight-black px-6">Aplicar</v-btn>
                            </div>
                        </div>
                    </v-card>
                </v-menu>
                </div>
             </div>

             <div class="d-flex align-center pt-2" style="gap: 12px;">
                 <div class="text-caption opacity-70 d-none d-md-block" v-if="loading">
                    <v-icon size="small" class="mdi-spin mr-1">mdi-loading</v-icon> Atualizando lista e verificando status fiscal local...
                 </div>
                 <div v-if="hasActiveFilters" class="text-caption text-primary font-weight-bold">
                    <v-icon size="small" start>mdi-filter</v-icon> Filtros Ativos
                 </div>
             </div>
         </div>
      </div>

      <div
        class="flex-grow-1 overflow-hidden d-flex flex-column transition-all"
        :class="[
           isMobileFullscreen ? 'absolute top-0 left-0 w-100 h-100 z-20 bg-white' : 'px-4 px-md-6 pb-0',
           mobile ? '' : ''
        ]"
      >
        <v-card class="flex-grow-1 d-flex flex-column rounded-0 border-thin overflow-hidden" :class="theme.global.current.value.dark ? 'glass-card border-white-05' : 'bg-white shadow-sm'" :elevation="0">

          <div v-if="isMobileFullscreen" class="bg-primary text-white px-3 py-3 d-flex align-center justify-space-between flex-shrink-0 gap-3 elevation-2 z-30">
             <v-btn icon="mdi-arrow-left" variant="text" color="white" @click="isMobileFullscreen = false" class="flex-shrink-0"></v-btn>

             <div class="flex-grow-1 relative d-flex align-center">
                 <input
                    v-model="search"
                    type="text"
                    placeholder="Pesquisar..."
                    class="w-100 bg-white-20 text-white rounded px-3 pr-8 text-body-2 font-weight-bold outline-none placeholder-white-70"
                    style="border: 1px solid rgba(255,255,255,0.3); height: 40px;"
                 >
                 <div class="absolute right-2" style="top: 50%; transform: translateY(-50%); display: flex; align-items: center;">
                    <v-icon v-if="!search" size="small" class="text-white-70">mdi-magnify</v-icon>
                    <v-icon v-else size="small" class="text-white cursor-pointer" @click="search = ''">mdi-close</v-icon>
                 </div>
             </div>

             <v-btn icon variant="text" color="white" class="flex-shrink-0" @click="mobileMenuOpen = true">
                 <v-badge v-if="hasActiveFilters" dot color="error">
                    <v-icon>mdi-filter-variant</v-icon>
                 </v-badge>
                 <v-icon v-else>mdi-filter-variant</v-icon>
             </v-btn>
          </div>

          <div v-if="!mobile" class="grid-scroll flex-grow-1 overflow-y-auto custom-scroll">
            <div class="grid-header sticky-head" :class="theme.global.current.value.dark ? 'grid-surface-dark' : 'grid-surface-light'" :style="{ gridTemplateColumns: computedGridTemplate }">
               <div class="cell center header-text">#</div>
               <div class="cell center header-text">Emissão</div>
               <div class="cell header-text">Cliente / Responsável</div>
               <div class="cell center header-text" v-if="companyStore.isGlobalView">Empresa</div>
               <div class="cell center header-text">Vendedor</div>
               <div class="cell center header-text">Qtd</div>
               <div class="cell center header-text">Entrega</div>
               <div class="cell center header-text">Status Produção</div>
               <div class="cell center header-text">{{ activeOrderMode === 'sales' ? 'Recebimento' : 'Financeiro' }}</div>
               <div class="cell center header-text">Fiscal</div>
               <div class="cell center header-text">Sinal</div>
               <div class="cell center header-text text-error">Pendências</div>
               <div class="cell right header-text">Total</div>
               <div class="cell center header-text">Ações</div>
            </div>

            <div v-if="loading" class="d-flex flex-column justify-center align-center h-100 py-12 w-100">
              <v-progress-circular indeterminate color="primary" size="40" width="4"></v-progress-circular>
            </div>
            <div v-else-if="!paginatedOrders || paginatedOrders.length === 0" class="d-flex flex-column justify-center align-center h-100 opacity-60 gap-2 py-12 w-100">
              <v-icon size="56" color="grey-lighten-1">mdi-file-find-outline</v-icon>
              <span class="text-subtitle-1 font-weight-medium text-grey">Nenhum pedido encontrado.</span>
            </div>

            <div v-else v-for="(item, index) in paginatedOrders" :key="item.id" class="grid-row" :class="theme.global.current.value.dark ? 'grid-row-dark' : 'grid-row-light'" :style="{ gridTemplateColumns: computedGridTemplate }">
               <div class="cell center">
                   <span class="pill-ref">{{ String(item.order_number).padStart(4, '0') }}</span>
                   <v-tooltip v-if="item.billing_alert" :text="item.details?.alert_message || 'ALERTA: Faturamento Solicitado'" location="top" content-class="bg-grey-darken-4 text-white font-weight-bold" max-width="300">
                       <template v-slot:activator="{ props }">
                           <v-icon v-bind="props" size="14" color="error" class="ml-1 pulsing-alert">mdi-bell-ring</v-icon>
                       </template>
                   </v-tooltip>
               </div>
               <div class="cell center">
                   <span class="list-text-10 font-mono opacity-80">{{ formatDate(item.created_at) }}</span>
               </div>
               <div class="cell flex-grow-1">
                   <div class="d-flex align-center w-100" style="min-width: 0;">
                       <v-avatar :color="getColor(item.customer_name)" size="28" variant="tonal" class="rounded-sm mr-3 flex-shrink-0 font-weight-bold text-[10px]">{{ item.customer_name?.charAt(0).toUpperCase() }}</v-avatar>
                       <div class="d-flex flex-column overflow-hidden" style="min-width: 0;">
                          <div class="text-truncate list-text-11 font-weight-bold" :title="item.customer_name">{{ item.customer_name }}</div>
                       </div>
                   </div>
               </div>

               <div class="cell center" v-if="companyStore.isGlobalView">
                   <v-chip v-if="item.company_id" size="x-small" color="blue-grey" variant="flat" class="font-weight-bold chip-3d text-truncate" style="max-width: 90px;" :title="item.company?.trade_name">{{ item.company?.trade_name || 'Desconhecida' }}</v-chip>
                   <v-chip v-else size="x-small" color="error" variant="flat" class="font-weight-black chip-3d px-1">S/ EMP</v-chip>
               </div>

              <div class="cell center">
                   <span class="text-truncate list-text-10 opacity-70">{{ item.creator?.full_name?.split(' ')[0] || 'Sistema' }}</span>
               </div>

                <div class="cell center"><span class="list-text-11 font-mono font-weight-bold">{{ formatNumber(item.quantity_meters || 0) }}m</span></div>

               <div class="cell center">
                    <div class="d-flex flex-column align-center">
                        <span class="list-text-10 font-weight-bold" :class="getDeliveryColorClass(item)">
                            {{ getDisplayDeliveryDate(item) }}
                        </span>
                        <div v-if="['delivered', 'ready_for_delivery'].includes(item.status)" class="text-nano-badge px-2 py-0.5 rounded-sm font-weight-bold mt-1 bg-success-transparent text-success">
                            <v-icon size="16">mdi-check-circle</v-icon>
                        </div>
                        <div v-else-if="item.status === 'cancelled'" class="text-nano-badge px-2 py-0.5 rounded-sm font-weight-bold mt-1 bg-error-transparent text-error">
                            <v-icon size="16">mdi-close-circle</v-icon>
                        </div>
                        <div v-else-if="item.days_until_delivery_short" class="text-nano-badge px-2 py-0.5 rounded-sm font-weight-bold mt-1" :class="getDeliveryBadgeClass(item)">
                            {{ item.days_until_delivery_short }}
                        </div>
                    </div>
                </div>

               <div class="cell center">
                   <span class="solid-chip chip-3d" :class="`chip-${getStatusColor(item.status)}`">{{ formatStatus(item.status) }}</span>
               </div>

              <div class="cell center">
                   <template v-if="activeOrderMode === 'sales'">
                        <span class="solid-chip chip-3d" :class="getSellerPaymentChipClass(item)">
                            {{ getSellerPaymentLabel(item) }}
                        </span>
                   </template>
                   <template v-else-if="item.fiscal_doc?.found">
                       <v-tooltip :text="`Documento ${item.fiscal_doc.type} Autorizado! Clique para baixar.`" location="top" content-class="bg-grey-darken-4 text-white font-weight-bold">
                           <template v-slot:activator="{ props }">
                               <v-chip v-bind="props" size="small" :color="item.fiscal_doc.type === 'NFe' ? 'success' : 'deep-orange'" class="font-weight-bold cursor-pointer chip-3d" label @click="downloadFiscalDoc(item)">
                                   <v-icon start size="14">mdi-check-decagram</v-icon> {{ item.fiscal_doc.type }}
                               </v-chip>
                           </template>
                       </v-tooltip>
                   </template>
                   <template v-else>
                        <span class="solid-chip chip-3d" :class="getFinancialChipClass(item.financial_status)">
                            {{ item.financial_status === 'Parcialmente Faturado' ? 'FAT. PARCIAL' : (item.financial_status || 'PENDENTE') }}
                        </span>
                   </template>
               </div>

               <div class="cell center">
                   <v-tooltip :text="item.fiscal_doc?.found ? `Documento ${item.fiscal_doc.type} disponível para baixar.` : 'Sem documento fiscal disponível.'" location="top" content-class="bg-grey-darken-4 text-white font-weight-bold">
                       <template v-slot:activator="{ props }">
                           <button
                               v-bind="props"
                               type="button"
                               class="fiscal-seal chip-3d"
                               :class="item.fiscal_doc?.found ? (item.fiscal_doc.type === 'NFe' ? 'fiscal-seal--nfe' : 'fiscal-seal--nfce') : 'fiscal-seal--empty'"
                               :disabled="!item.fiscal_doc?.found"
                               @click.stop="item.fiscal_doc?.found && downloadFiscalDoc(item)"
                           >
                               <v-icon size="17">{{ item.fiscal_doc?.found ? 'mdi-file-check' : 'mdi-file-question-outline' }}</v-icon>
                               <span>{{ item.fiscal_doc?.found ? item.fiscal_doc.type : 'SEM DOC' }}</span>
                           </button>
                       </template>
                   </v-tooltip>
               </div>

               <div class="cell center">
                    <v-tooltip :text="hasSignal(item) ? `Sinal Pago: ${formatCurrency(getSignalValue(item))}` : 'Sem sinal identificado'" location="top" content-class="bg-grey-darken-4 text-white font-weight-bold">
                        <template v-slot:activator="{ props }">
                            <v-icon v-bind="props" size="18" :color="hasSignal(item) ? 'success' : 'grey'" class="cursor-help" :class="{'opacity-30': !hasSignal(item)}">mdi-currency-usd</v-icon>
                        </template>
                    </v-tooltip>
               </div>

               <div class="cell center">
                   <v-tooltip v-if="item.missing_installments?.length > 0" location="top" content-class="bg-grey-darken-4 text-white px-3 py-2">
                       <template v-slot:activator="{ props }">
                           <v-badge :content="item.missing_installments.length" color="error" offset-x="-2" offset-y="-2">
                               <v-icon v-bind="props" color="error" size="22" class="pulsing-alert">mdi-alert-circle</v-icon>
                           </v-badge>
                       </template>
                       <div class="text-caption mb-1 text-error font-weight-black">Parcelas em aberto:</div>
                       <div v-for="(mi, i) in item.missing_installments" :key="i" class="text-[11px] font-mono font-weight-bold">
                           <v-icon size="12" color="error" start>mdi-close</v-icon>
                           {{ formatDueDate(mi.due_date || mi.dueDate || mi.vencimento || mi.date) }} | {{ formatCurrency(mi.value || mi.amount || mi.total || mi.remaining_value || 0) }}
                       </div>
                   </v-tooltip>
                   <v-tooltip v-else text="Sem parcelas pendentes" location="top" content-class="bg-grey-darken-4 text-white font-weight-bold">
                       <template v-slot:activator="{ props }">
                           <div v-bind="props" class="pending-ok-seal chip-3d">
                               <v-icon size="18">mdi-check-bold</v-icon>
                           </div>
                       </template>
                   </v-tooltip>
               </div>

               <div class="cell right"><span class="list-text-11 font-mono font-weight-black">{{ formatCurrency(item.total_value) }}</span></div>

               <div class="cell center">
                   <div class="actions-inline" style="gap: 6px;">
                       <v-tooltip :text="primaryActionLabel" location="top" content-class="bg-grey-darken-4 text-white font-weight-bold">
                           <template v-slot:activator="{ props }">
                               <v-btn v-bind="props" icon size="small" class="action-btn btn-3d" :class="primaryActionClass" variant="flat" @click.stop="handlePrimaryAction(item)">
                                   <v-icon size="16">{{ primaryActionIcon }}</v-icon>
                               </v-btn>
                           </template>
                       </v-tooltip>

                       <v-tooltip :text="item.fiscal_doc?.found ? `Baixar ${item.fiscal_doc.type}` : 'Sem documento fiscal disponível'" location="top" content-class="bg-grey-darken-4 text-white font-weight-bold">
                           <template v-slot:activator="{ props }">
                               <v-btn
                                   v-bind="props"
                                   icon
                                   size="small"
                                   class="action-btn btn-3d"
                                   :class="item.fiscal_doc?.found ? 'bg-purple-darken-2' : 'fiscal-download-disabled'"
                                   variant="flat"
                                   :disabled="!item.fiscal_doc?.found"
                                   @click.stop="item.fiscal_doc?.found && downloadFiscalDoc(item)"
                               >
                                   <v-icon size="17">mdi-file-download-outline</v-icon>
                               </v-btn>
                           </template>
                       </v-tooltip>
                       <template>
                           <v-tooltip v-if="canUseBillingActions && item.financial_status !== 'Faturado'" text="Lançar / Faturar" location="top" content-class="bg-grey-darken-4 text-white font-weight-bold">
                               <template v-slot:activator="{ props }">
                                   <v-btn v-bind="props" icon size="small" class="action-btn action-pay btn-3d" variant="flat" @click.stop="confirmLaunchFinancial(item)">
                                       <v-icon size="16">mdi-check-all</v-icon>
                                   </v-btn>
                               </template>
                           </v-tooltip>
                           <v-tooltip v-else-if="canUseBillingActions && activeOrderMode !== 'sales'" text="Desfazer e Excluir Financeiro" location="top" content-class="bg-red-darken-4 text-white font-weight-bold">
                               <template v-slot:activator="{ props }">
                                   <v-btn v-bind="props" icon size="small" class="action-btn bg-deep-orange-darken-1 text-white btn-3d" variant="flat" @click.stop="undoLaunchFinancial(item)">
                                       <v-icon size="16">mdi-undo-variant</v-icon>
                                   </v-btn>
                               </template>
                           </v-tooltip>
                       </template>

                       <v-tooltip v-if="canUseBillingActions" text="Excluir" location="top" content-class="bg-grey-darken-4 text-white font-weight-bold">
                           <template v-slot:activator="{ props }">
                               <v-btn v-bind="props" icon size="small" class="action-btn action-delete btn-3d" variant="flat" @click.stop="deleteOrder(item)">
                                   <v-icon size="16">mdi-delete-outline</v-icon>
                               </v-btn>
                           </template>
                       </v-tooltip>

                       <v-menu location="bottom end" :close-on-content-click="false" transition="scale-transition">
                           <template v-slot:activator="{ props }">
                               <v-btn v-bind="props" icon size="small" class="action-btn action-more btn-3d" variant="flat">
                                   <v-icon size="18">mdi-chevron-down</v-icon>
                               </v-btn>
                           </template>
                           <v-list density="compact" class="rounded-lg border-thin shadow-lg py-0" :bg-color="theme.global.current.value.dark ? '#1E1E24' : 'white'" width="240">
                               <v-list-item class="bg-grey-lighten-4 py-1" style="min-height: 30px;">
                                   <v-list-item-title class="text-[10px] font-weight-bold text-uppercase text-grey-darken-1">Ações do Pedido</v-list-item-title>
                               </v-list-item>
                               <v-list-item v-if="canUseSalesActions" link @click="openOrderPaymentsModal(item)" density="compact">
                                   <template v-slot:prepend><v-icon size="18" class="mr-2 text-success">mdi-cash-register</v-icon></template>
                                   <v-list-item-title class="font-weight-bold text-success text-caption">Pagamentos / Recebimentos</v-list-item-title>
                               </v-list-item>
                               <v-list-item v-if="canUseBillingActions" link @click="openFinancialView(item)" density="compact">
                                   <template v-slot:prepend><v-icon size="18" class="mr-2 text-indigo">mdi-finance</v-icon></template>
                                   <v-list-item-title class="font-weight-bold text-indigo text-caption">Ver no Financeiro</v-list-item-title>
                               </v-list-item>
                               <v-list-item link @click="printOrder(item)" density="compact">
                                   <template v-slot:prepend><v-icon size="18" class="mr-2">mdi-printer</v-icon></template>
                                   <v-list-item-title class="text-caption">Imprimir Pedido</v-list-item-title>
                               </v-list-item>
                               <v-list-item v-if="canUseBillingActions" link @click="openStatusChangeModal(item)" density="compact">
                                   <template v-slot:prepend><v-icon size="18" class="mr-2 text-primary">mdi-swap-horizontal</v-icon></template>
                                   <v-list-item-title class="font-weight-bold text-primary text-caption">Alterar Status</v-list-item-title>
                               </v-list-item>
                               <v-divider></v-divider>
                               <v-list-item class="bg-grey-lighten-4 py-1" style="min-height: 30px;">
                                   <v-list-item-title class="text-[10px] font-weight-bold text-uppercase text-grey-darken-1">Fiscal & Compartilhar</v-list-item-title>
                               </v-list-item>
                               <v-list-item v-if="canUseBillingActions" link @click="openNfeModal(item)" :disabled="item.fiscal_doc?.found" density="compact">
                                   <template v-slot:prepend><v-icon size="18" class="mr-2" :color="item.fiscal_doc?.found ? 'success' : ''">mdi-file-document-outline</v-icon></template>
                                   <v-list-item-title class="text-caption" :class="item.fiscal_doc?.found ? 'text-success font-weight-bold' : ''">
                                       {{ item.fiscal_doc?.found ? 'NFe Emitida (Baixar)' : 'Emitir NFe (55)' }}
                                   </v-list-item-title>
                               </v-list-item>
                               <v-list-item v-if="canUseBillingActions" link @click="openNfceDialog(item, true)" :disabled="item.fiscal_doc?.found" density="compact">
                                   <template v-slot:prepend><v-icon size="18" class="mr-2 text-deep-orange">mdi-receipt-text-check</v-icon></template>
                                   <v-list-item-title class="text-caption text-deep-orange">Emitir NFC-e (Nome)</v-list-item-title>
                               </v-list-item>
                               <v-list-item v-if="canUseBillingActions" link @click="openNfceDialog(item, false)" :disabled="item.fiscal_doc?.found" density="compact">
                                   <template v-slot:prepend><v-icon size="18" class="mr-2 text-orange">mdi-receipt-text-outline</v-icon></template>
                                   <v-list-item-title class="text-caption text-orange">Emitir NFC-e (Simples)</v-list-item-title>
                               </v-list-item>
                               <v-list-item link @click="openShareModal(item, 'whatsapp', item.fiscal_doc?.type)" density="compact" :disabled="!item.fiscal_doc?.found">
                                   <template v-slot:prepend><v-icon size="18" class="mr-2 text-success">mdi-whatsapp</v-icon></template>
                                   <v-list-item-title class="text-caption">Env. WhatsApp</v-list-item-title>
                               </v-list-item>
                           </v-list>
                       </v-menu>
                   </div>
               </div>
            </div>
          </div>

<div v-else class="flex-grow-1 overflow-y-auto bg-grey-lighten-4 pb-12 custom-scroll">
  <div v-if="loading" class="d-flex flex-column align-center justify-center py-10">
    <v-progress-circular indeterminate color="primary" size="32"></v-progress-circular>
    <span class="text-caption mt-3 font-weight-bold text-grey-darken-1">Carregando...</span>
  </div>

  <div v-else-if="!paginatedOrders || paginatedOrders.length === 0" class="d-flex flex-column align-center justify-center py-12 opacity-60">
    <v-icon size="64" color="grey-lighten-1" class="mb-2">mdi-file-search-outline</v-icon>
    <span class="text-body-1 font-weight-medium text-grey-darken-1">Nenhum pedido encontrado</span>
  </div>

  <div v-else class="mobile-cards-wrap pa-4">
    <v-card
      v-for="item in paginatedOrders"
      :key="item.id"
      class="mobile-order-card"
      :class="theme.global.current.value.dark ? 'mobile-order-card--dark' : 'mobile-order-card--light'"
      elevation="0"
    >
      <div class="mobile-order-card__accent" :class="item.fiscal_doc?.found ? 'accent-success' : 'accent-primary'"></div>

      <div class="mobile-order-card__header">
        <div class="d-flex align-start justify-space-between gap-3 mobile-header-row">

          <div class="d-flex flex-column">
            <div class="d-flex align-center gap-2 flex-wrap">
              <span class="mobile-order-card__id">#{{ String(item.order_number).padStart(4, '0') }}</span>

              <v-chip v-if="companyStore.isGlobalView" size="x-small" :color="item.company_id ? 'blue-grey' : 'error'" variant="flat" class="font-weight-bold chip-3d">
                  {{ item.company?.trade_name || 'SEM EMP' }}
              </v-chip>

              <v-chip size="x-small" variant="tonal" class="mobile-chip-date" :class="theme.global.current.value.dark ? 'chip-dark' : 'chip-light'" label>
                <v-icon start size="14" class="chip-ico">mdi-calendar</v-icon>
                {{ formatDate(item.created_at) }}
              </v-chip>

              <v-tooltip v-if="item.billing_alert" :text="item.details?.alert_message || 'ALERTA: Faturamento Solicitado'" location="top" content-class="bg-grey-darken-4 text-white font-weight-bold" max-width="300">
                <template v-slot:activator="{ props }">
                  <v-chip v-bind="props" size="x-small" color="error" variant="tonal" class="mobile-chip-alert" label>
                    <v-icon start size="14">mdi-bell-ring</v-icon>
                    Alerta
                  </v-chip>
                </template>
              </v-tooltip>
            </div>

            <div class="mobile-order-card__customer clamp-2">
              {{ item.customer_name || 'Cliente não identificado' }}
            </div>

            <div class="mobile-order-card__meta d-flex align-center gap-2 mt-1">
              <div class="meta-pill">
                <v-icon size="14" class="meta-ico">mdi-account-tie</v-icon>
                <span class="meta-text">{{ item.creator?.full_name?.split(' ')[0] || 'Sistema' }}</span>
              </div>

              <div class="meta-pill">
                <v-icon size="14" class="meta-ico">mdi-ruler-square</v-icon>
                <span class="meta-text">{{ formatNumber(item.quantity_meters || 0) }}m</span>
              </div>
            </div>
          </div>

          <div class="mobile-order-card__total">
            <div class="total-label">TOTAL</div>
            <div class="total-value">{{ formatCurrency(item.total_value) }}</div>
            <div class="delivery-pill" :class="theme.global.current.value.dark ? 'pill-dark' : 'pill-light'">
              <v-icon size="14" class="delivery-ico">mdi-truck-delivery</v-icon>
              <span class="delivery-date" :class="getDeliveryColorClass(item)">{{ item.estimated_delivery }}</span>
              <span
                v-if="item.days_until_delivery_short"
                class="delivery-badge"
                :class="getDeliveryBadgeClass(item)"
              >
                {{ item.days_until_delivery_short }}
              </span>
            </div>
          </div>
        </div>

        <div class="mobile-order-card__statusrow">
          <v-chip
            size="small"
            :color="getStatusColor(item.status)"
            variant="flat"
            class="mobile-chip mobile-chip--prod chip-3d"
            label
          >
            <v-icon start size="16">mdi-factory</v-icon>
            {{ formatStatus(item.status) }}
          </v-chip>

          <template v-if="item.fiscal_doc?.found">
            <v-chip
              size="small"
              :color="item.fiscal_doc.type === 'NFe' ? 'success' : 'deep-orange'"
              variant="tonal"
              class="mobile-chip mobile-chip--fiscal cursor-pointer chip-3d"
              label
              @click.stop="downloadFiscalDoc(item)"
            >
              <v-icon start size="16">mdi-check-decagram</v-icon>
              {{ item.fiscal_doc.type }} Autorizada
            </v-chip>
          </template>
          <template v-else>
            <v-chip
              size="small"
              variant="tonal"
              class="mobile-chip mobile-chip--fin chip-3d"
              :class="getFinancialChipClass(item.financial_status)"
              label
            >
              <v-icon start size="16">
                {{ item.financial_status === 'Faturado' ? 'mdi-check-all' : (item.financial_status === 'Parcialmente Faturado' ? 'mdi-circle-slice-4' : 'mdi-clock-outline') }}
              </v-icon>
              {{ item.financial_status === 'Parcialmente Faturado' ? 'PARCIAL' : (item.financial_status || 'PENDENTE') }}
            </v-chip>
          </template>
        </div>
      </div>

      <v-divider class="mobile-divider"></v-divider>

      <div class="mobile-order-card__actions">
        <v-btn
          class="mbtn btn-3d"
          :class="mobilePrimaryButtonClass"
          height="46"
          variant="flat"
          @click.stop="handlePrimaryAction(item)"
        >
          <v-icon size="20" class="mbtn-ico">{{ primaryActionIcon }}</v-icon>
          <span class="mbtn-txt">{{ mobilePrimaryActionLabel }}</span>
        </v-btn>

        <template v-if="item.fiscal_doc?.found">
          <v-btn
            class="mbtn mbtn--download btn-3d"
            height="46"
            variant="flat"
            @click.stop="downloadFiscalDoc(item)"
          >
            <v-icon size="20" class="mbtn-ico">mdi-download</v-icon>
            <span class="mbtn-txt">Baixar</span>
          </v-btn>
        </template>
        <template v-else-if="canUseBillingActions">
          <v-menu location="top center">
            <template v-slot:activator="{ props }">
              <v-btn
                v-bind="props"
                class="mbtn mbtn--fiscal btn-3d"
                height="46"
                variant="flat"
              >
                <v-icon size="20" class="mbtn-ico">mdi-file-document-plus</v-icon>
                <span class="mbtn-txt">Fiscal</span>
              </v-btn>
            </template>

            <v-list density="compact" class="rounded-xl shadow-xl py-2" width="220">
              <v-list-subheader class="text-[10px] font-weight-bold text-uppercase text-center text-grey">EMISSÃO FISCAL</v-list-subheader>
              <v-divider class="mb-1"></v-divider>
              <v-list-item @click="openNfceDialog(item, false)">
                <template v-slot:prepend><v-icon size="18" class="text-orange mr-2">mdi-receipt-text-outline</v-icon></template>
                <v-list-item-title class="text-caption font-weight-bold">NFC-e Simples</v-list-item-title>
              </v-list-item>
              <v-list-item @click="openNfceDialog(item, true)">
                <template v-slot:prepend><v-icon size="18" class="text-deep-orange mr-2">mdi-receipt-text-check</v-icon></template>
                <v-list-item-title class="text-caption font-weight-bold">NFC-e (Nome)</v-list-item-title>
              </v-list-item>
              <v-list-item @click="openNfeModal(item)">
                <template v-slot:prepend><v-icon size="18" class="text-primary mr-2">mdi-file-document-outline</v-icon></template>
                <v-list-item-title class="text-caption font-weight-bold">NFe (55)</v-list-item-title>
              </v-list-item>
            </v-list>
          </v-menu>
        </template>

        <v-menu location="top end">
          <template v-slot:activator="{ props }">
            <v-btn v-bind="props" class="mbtn mbtn--more btn-3d" height="46" variant="flat">
              <v-icon size="20" class="mbtn-ico">mdi-dots-horizontal</v-icon>
              <span class="mbtn-txt">Mais</span>
            </v-btn>
          </template>

          <v-list density="compact" class="rounded-xl shadow-xl py-2" width="240">
            <v-list-item v-if="canUseSalesActions" @click="openOrderPaymentsModal(item)">
              <template v-slot:prepend><v-icon size="18" class="text-success mr-2">mdi-cash-register</v-icon></template>
              <v-list-item-title class="text-caption font-weight-bold">Pagamentos / Recebimentos</v-list-item-title>
            </v-list-item>

            <v-list-item @click="printOrder(item)">
              <template v-slot:prepend><v-icon size="18" class="text-indigo mr-2">mdi-printer</v-icon></template>
              <v-list-item-title class="text-caption font-weight-bold">Imprimir</v-list-item-title>
            </v-list-item>

            <v-list-item v-if="canUseBillingActions" @click="confirmLaunchFinancial(item)" :disabled="item.financial_status === 'Faturado'">
              <template v-slot:prepend><v-icon size="18" class="text-success mr-2">mdi-cash-check</v-icon></template>
              <v-list-item-title class="text-caption font-weight-bold">Lançar Financeiro</v-list-item-title>
            </v-list-item>

            <v-list-item v-if="canUseBillingActions && activeOrderMode !== 'sales'" @click="undoLaunchFinancial(item)" :disabled="item.financial_status !== 'Faturado'">
              <template v-slot:prepend><v-icon size="18" class="text-deep-orange mr-2">mdi-undo</v-icon></template>
              <v-list-item-title class="text-caption font-weight-bold">Estornar</v-list-item-title>
            </v-list-item>

            <v-list-item v-if="canUseBillingActions" @click="openStatusChangeModal(item)">
              <template v-slot:prepend><v-icon size="18" class="text-primary mr-2">mdi-swap-horizontal</v-icon></template>
              <v-list-item-title class="text-caption font-weight-bold">Alterar Status</v-list-item-title>
            </v-list-item>

            <v-divider class="my-1"></v-divider>

            <v-list-item v-if="canUseBillingActions" @click="deleteOrder(item)" class="text-error">
              <template v-slot:prepend><v-icon size="18" class="text-error mr-2">mdi-trash-can-outline</v-icon></template>
              <v-list-item-title class="text-caption font-weight-bold">Excluir</v-list-item-title>
            </v-list-item>
          </v-list>
        </v-menu>
      </div>
    </v-card>
  </div>
</div>

          <div class="flex-shrink-0 border-t px-4 py-2 d-flex flex-column flex-md-row align-center justify-space-between" :class="theme.global.current.value.dark ? 'bg-white-05' : 'bg-grey-lighten-5'">
            <div class="d-flex align-center justify-space-between w-100 w-md-auto mb-2 mb-md-0">
                <div class="text-caption opacity-80" style="font-size: 13px !important;">
                  Total: <strong>{{ filteredOrders ? filteredOrders.length : 0 }}</strong> | <span class="font-weight-black">{{ formatCurrency(filteredTotalValue) }}</span>
                </div>
                <v-btn v-if="mobile && !isMobileFullscreen" size="small" variant="text" color="primary" prepend-icon="mdi-fullscreen" @click="isMobileFullscreen = true">
                    Expandir
                </v-btn>
            </div>
            <v-pagination v-model="page" :length="totalPages" :total-visible="mobile ? 3 : 5" density="compact" active-color="primary" variant="tonal" size="small"></v-pagination>
          </div>
        </v-card>
      </div>
    </div>

    <BillingModal v-if="billingDialog" :show="billingDialog" :receivableId="null" :order="selectedOrder" @update:show="billingDialog = $event" @close="closeBillingModal" @refresh="fetchOrders" />
    <OrderPaymentsModal v-if="paymentDialog" :model-value="paymentDialog" :order="selectedPaymentOrder" @update:model-value="paymentDialog = $event" @close="closePaymentModal" />

    <v-dialog v-model="mobileMenuOpen" fullscreen transition="dialog-bottom-transition">
        <v-card class="d-flex flex-column bg-grey-lighten-5 h-100">
            <div class="px-4 py-3 bg-white d-flex align-center justify-space-between border-b flex-shrink-0">
                <span class="text-h6 font-weight-black">Menu de Ações</span>
                <v-btn icon="mdi-close" variant="text" @click="mobileMenuOpen = false"></v-btn>
            </div>
            <div class="flex-grow-1 overflow-y-auto pa-4">
                <div class="text-caption font-weight-bold text-uppercase opacity-70 mb-2">Período Rápido</div>
                <div class="d-flex flex-wrap gap-2 mb-4">
                    <v-chip v-for="p in periodOptions" :key="p.value" :color="currentPeriod === p.value ? 'primary' : 'default'" @click="selectPeriod(p.value); mobileMenuOpen = false">{{ p.label }}</v-chip>
                </div>

                <v-divider class="mb-4"></v-divider>

                <div class="text-caption font-weight-bold text-uppercase opacity-70 mb-2">Filtros Avançados</div>
                <v-select v-model="filterFinancialStatus" :items="statusFilters" item-title="label" item-value="value" label="Status Financeiro" density="compact" variant="outlined" bg-color="white"></v-select>
                <v-select v-model="filterProductionStatus" :items="productionStatusFilters" label="Status Produção" density="compact" variant="outlined" bg-color="white"></v-select>
                <v-autocomplete v-model="filterSeller" :items="availableSellers" label="Vendedor" density="compact" variant="outlined" bg-color="white" clearable></v-autocomplete>

                <div class="d-flex gap-2">
                    <v-text-field v-model="filterDateStart" type="date" label="De" density="compact" variant="outlined" bg-color="white"></v-text-field>
                    <v-text-field v-model="filterDateEnd" type="date" label="Até" density="compact" variant="outlined" bg-color="white"></v-text-field>
                </div>

                <v-btn block color="primary" variant="flat" size="large" class="mt-2 font-weight-bold btn-3d" @click="fetchOrders(); mobileMenuOpen = false">Aplicar Filtros</v-btn>
                <v-btn block color="error" variant="text" size="small" class="mt-2" @click="clearFilters(); mobileMenuOpen = false">Limpar Filtros</v-btn>

                <v-divider class="my-4"></v-divider>

                <div class="text-caption font-weight-bold text-uppercase opacity-70 mb-2">Relatórios</div>
                <v-list density="compact" class="bg-transparent">
                    <v-list-item link @click="generateOrderReport('production'); mobileMenuOpen = false" prepend-icon="mdi-printer-outline" title="Relatório de Produção"></v-list-item>
                    <v-list-item link @click="generateOrderReport('full'); mobileMenuOpen = false" prepend-icon="mdi-file-pdf-box" title="Relatório Financeiro"></v-list-item>
                </v-list>
            </div>
        </v-card>
    </v-dialog>

    <v-dialog v-model="shareModal.show" max-width="500" persistent scrim="black opacity-80">
        <v-card class="rounded-lg overflow-hidden" :class="theme.global.current.value.dark ? 'bg-surface' : 'bg-white'">
            <div class="pa-4 text-white d-flex align-center gap-3" :class="shareModal.channel === 'whatsapp' ? 'bg-green-darken-2' : 'bg-blue-darken-2'">
                <v-icon>{{ shareModal.channel === 'whatsapp' ? 'mdi-whatsapp' : 'mdi-email' }}</v-icon>
                <h3 class="text-subtitle-2 font-weight-black text-uppercase">Compartilhar {{ shareModal.docType }}</h3>
            </div>
            <v-card-text class="pa-6">
                 <div class="d-flex align-center gap-3 mb-4 bg-grey-lighten-4 pa-3 rounded border-thin">
                    <v-icon color="grey-darken-2" size="large">mdi-file-pdf-box</v-icon>
                    <div class="d-flex flex-column">
                        <span class="font-weight-bold text-caption">Pedido #{{ shareModal.order?.order_number }}</span>
                        <span class="text-[10px] text-grey">Documento Fiscal: {{ shareModal.docType }}</span>
                    </div>
                </div>
                <v-textarea v-model="shareModal.message" label="Mensagem" variant="outlined" auto-grow rows="4" density="compact" hide-details></v-textarea>
                <div v-if="shareModal.channel === 'whatsapp'" class="mt-2 text-caption opacity-70">
                    <v-icon size="small" start>mdi-information-outline</v-icon>
                    O PDF será baixado e o WhatsApp Web abrirá para você anexá-lo.
                </div>
            </v-card-text>
            <div class="pa-4 border-t d-flex justify-end gap-2 bg-grey-lighten-5">
                <v-btn variant="text" class="btn-3d font-weight-bold" color="grey-darken-2" @click="shareModal.show = false" :disabled="shareModal.loading">Cancelar</v-btn>
                <v-btn :color="shareModal.channel === 'whatsapp' ? 'success' : 'info'" variant="flat" class="btn-3d font-weight-black" @click="confirmShare" :loading="shareModal.loading">
                    <v-icon start>mdi-share-variant</v-icon> Enviar Agora
                </v-btn>
            </div>
        </v-card>
    </v-dialog>

    <v-dialog v-model="nfceModal.show" max-width="1200" persistent scrim="black opacity-80" scrollable transition="dialog-bottom-transition">
        <v-card class="rounded-0 d-flex flex-column" height="800" :class="theme.global.current.value.dark ? 'bg-grey-darken-4 text-white' : 'bg-white text-grey-darken-3'">
             <div class="flex-grow-1 d-flex overflow-hidden" style="max-height: calc(100% - 70px);">
                <div class="border-r border-opacity-10 d-flex flex-column" :class="theme.global.current.value.dark ? 'bg-grey-darken-3' : 'bg-grey-lighten-5'" style="width: 320px; flex-shrink: 0;">
                    <div class="pa-6 border-b border-opacity-10">
                        <div class="d-flex align-center gap-3 mb-4">
                            <div class="icon-box rounded-lg pa-3 border shadow-sm" :class="theme.global.current.value.dark ? 'bg-grey-darken-4' : 'bg-white'">
                                <v-icon color="deep-orange" size="24">mdi-receipt-text</v-icon>
                            </div>
                            <div>
                                <div class="text-caption font-weight-bold text-uppercase opacity-70">EMISSÃO DE CUPOM</div>
                                <div class="text-body-2 font-weight-black">NFC-e Consumidor</div>
                            </div>
                        </div>
                        <div class="pa-3 rounded border mb-4" :class="theme.global.current.value.dark ? 'bg-grey-darken-4' : 'bg-white'">
                            <div class="text-caption font-weight-bold text-uppercase opacity-60 mb-1">Empresa Emitente</div>
                            <div class="font-weight-bold text-body-2">{{ activeNfceCompany?.name || 'Procurando Empresa...' }}</div>
                            <div class="font-mono text-caption opacity-70">{{ activeNfceCompany?.cnpj }}</div>
                        </div>
                        <div class="d-flex flex-column gap-2">
                            <div class="d-flex justify-space-between align-end">
                                <span class="text-caption font-weight-bold text-uppercase opacity-60">Itens</span>
                                <span class="font-weight-bold">{{ nfceForm.itens.length }}</span>
                            </div>
                            <v-divider></v-divider>
                            <div class="d-flex justify-space-between align-end mt-2">
                                <span class="text-subtitle-2 font-weight-black text-uppercase text-deep-orange">Total</span>
                                <span class="text-h5 font-weight-black text-deep-orange">{{ formatCurrency(nfceTotalValue) }}</span>
                            </div>
                        </div>
                    </div>
                    <div class="flex-grow-1 overflow-y-auto pa-4">
                        <div class="text-caption font-weight-bold text-uppercase opacity-60 mb-2">Itens do Pedido</div>
                        <div v-for="(item, idx) in nfceForm.itens" :key="idx" class="d-flex justify-space-between align-center mb-2 pa-2 border rounded" :class="theme.global.current.value.dark ? 'bg-grey-darken-4' : 'bg-white'">
                            <div class="d-flex flex-column overflow-hidden mr-2">
                                <span class="text-caption font-weight-bold text-truncate">{{ item.descricao }}</span>
                                <span class="text-[10px] opacity-70">{{ item.quantidade }} x {{ formatCurrency(item.valor_unitario) }}</span>
                            </div>
                            <span class="text-caption font-weight-black">{{ formatCurrency(item.quantidade * item.valor_unitario) }}</span>
                        </div>
                    </div>
                </div>
                <div class="flex-grow-1 d-flex flex-column overflow-hidden" :class="theme.global.current.value.dark ? 'bg-grey-darken-4' : 'bg-white'">
                    <div class="px-8 py-5 border-b d-flex justify-space-between align-center flex-shrink-0 z-10">
                        <div>
                            <h3 class="text-h6 font-weight-bold">Conferência e Emissão</h3>
                            <p class="text-caption opacity-70">Pedido #{{ nfceModal.orderNumber }}</p>
                        </div>
                        <v-btn icon="mdi-close" variant="text" @click="nfceModal.show = false"></v-btn>
                    </div>
                    <div class="px-8 py-6 flex-grow-1 overflow-y-auto custom-scroll">
                        <v-form ref="nfceFormRef" @submit.prevent>
                            <div class="mb-6">
                                <div class="d-flex align-center gap-2 mb-3">
                                    <v-icon size="18">mdi-account</v-icon>
                                    <span class="text-subtitle-2 font-weight-bold text-uppercase opacity-70">Consumidor (Opcional)</span>
                                </div>
                                <v-row dense>
                                    <v-col cols="12" md="4">
                                        <v-text-field v-model="nfceForm.cpf" label="CPF/CNPJ" variant="outlined" density="compact" hide-details v-maska="['###.###.###-##', '##.###.###/####-##']" :bg-color="theme.global.current.value.dark ? undefined : 'grey-lighten-5'"></v-text-field>
                                    </v-col>
                                    <v-col cols="12" md="8">
                                        <v-text-field v-model="nfceForm.nome" label="Nome do Cliente" variant="outlined" density="compact" hide-details :bg-color="theme.global.current.value.dark ? undefined : 'grey-lighten-5'"></v-text-field>
                                    </v-col>
                                </v-row>
                            </div>
                            <v-divider class="mb-6 border-dashed"></v-divider>
                            <div class="mb-6">
                                <div class="d-flex align-center justify-space-between mb-3">
                                    <div class="d-flex align-center gap-2">
                                        <v-icon size="18">mdi-package-variant</v-icon>
                                        <span class="text-subtitle-2 font-weight-bold text-uppercase opacity-70">Produtos (Editável)</span>
                                    </div>
                                    <v-btn size="small" variant="tonal" color="primary" prepend-icon="mdi-plus" class="font-weight-bold" @click="addNfceItem">Adicionar Item</v-btn>
                                </div>

                                <div class="mb-4 bg-grey-lighten-4 pa-3 rounded border border-dashed d-flex flex-column gap-2" :class="theme.global.current.value.dark ? 'bg-grey-darken-3' : ''">
                                    <span class="text-caption font-weight-bold text-primary text-uppercase">
                                        <v-icon size="16" class="mr-1">mdi-brightness-percent</v-icon> Emitir Faturamento Parcial
                                    </span>
                                    <v-btn-toggle v-model="nfcePercentage" mandatory density="compact" color="deep-orange" variant="outlined" divided>
                                        <v-btn :value="25" class="text-caption font-weight-bold flex-grow-1">25%</v-btn>
                                        <v-btn :value="50" class="text-caption font-weight-bold flex-grow-1">50%</v-btn>
                                        <v-btn :value="75" class="text-caption font-weight-bold flex-grow-1">75%</v-btn>
                                        <v-btn :value="100" class="text-caption font-weight-bold flex-grow-1">100% (Integral)</v-btn>
                                    </v-btn-toggle>
                                </div>
                                <div class="rounded border overflow-hidden" :class="theme.global.current.value.dark ? 'bg-grey-darken-3' : 'bg-grey-lighten-5'">
                                    <div v-for="(item, idx) in nfceForm.itens" :key="idx" class="pa-3 border-b transition-colors relative group">
                                        <v-row dense align="center">
                                            <v-col cols="12" md="5"><v-text-field v-model="item.descricao" label="Descrição" variant="outlined" density="compact" hide-details :bg-color="theme.global.current.value.dark ? 'grey-darken-4' : 'white'" class="input-dense"></v-text-field></v-col>
                                            <v-col cols="6" md="2"><v-text-field v-model="item.ncm" label="NCM" variant="outlined" density="compact" hide-details :bg-color="theme.global.current.value.dark ? 'grey-darken-4' : 'white'" class="input-dense"></v-text-field></v-col>
                                            <v-col cols="6" md="2"><v-text-field v-model="item.cfop" label="CFOP" variant="outlined" density="compact" hide-details :bg-color="theme.global.current.value.dark ? 'grey-darken-4' : 'white'" class="input-dense"></v-text-field></v-col>
                                            <v-col cols="4" md="1"><v-text-field v-model.number="item.quantidade" label="Qtd" type="number" variant="outlined" density="compact" hide-details :bg-color="theme.global.current.value.dark ? 'grey-darken-4' : 'white'" class="input-dense font-weight-bold"></v-text-field></v-col>
                                            <v-col cols="4" md="2"><v-text-field v-model.number="item.valor_unitario" label="Unitário" type="number" prefix="R$" variant="outlined" density="compact" hide-details :bg-color="theme.global.current.value.dark ? 'grey-darken-4' : 'white'" class="input-dense font-weight-bold"></v-text-field></v-col>
                                        </v-row>
                                        <v-btn icon="mdi-delete" size="x-small" variant="text" color="error" class="absolute top-2 right-2" @click="removeNfceItem(idx)"></v-btn>
                                    </div>
                                </div>
                            </div>
                            <v-divider class="mb-6 border-dashed"></v-divider>
                            <div class="mb-2">
                                <div class="d-flex align-center gap-2 mb-3">
                                    <v-icon size="18">mdi-credit-card-outline</v-icon>
                                    <span class="text-subtitle-2 font-weight-bold text-uppercase opacity-70">Pagamento</span>
                                </div>
                                <v-card variant="outlined" class="pa-4 border-dashed" :class="theme.global.current.value.dark ? 'bg-grey-darken-3' : 'bg-grey-lighten-5'">
                                    <v-row dense>
                                        <v-col cols="12" md="6">
                                            <v-select v-model="nfceForm.pagamento.forma" :items="nfcePaymentMethods" item-title="label" item-value="code" label="Forma de Pagamento" variant="outlined" density="compact" hide-details :bg-color="theme.global.current.value.dark ? 'grey-darken-4' : 'white'"></v-select>
                                        </v-col>
                                        <v-col cols="12" md="6">
                                            <v-text-field v-model.number="nfceForm.pagamento.valor" label="Valor Pago" type="number" prefix="R$" variant="outlined" density="compact" hide-details :bg-color="theme.global.current.value.dark ? 'grey-darken-4' : 'white'" class="font-weight-black text-success"></v-text-field>
                                        </v-col>
                                    </v-row>
                                </v-card>
                            </div>
                        </v-form>
                    </div>
                </div>
            </div>
            <div class="px-8 py-4 border-t d-flex justify-between gap-3 flex-shrink-0 align-center" :class="theme.global.current.value.dark ? 'bg-grey-darken-3' : 'bg-grey-lighten-5'">
                <div class="d-flex align-center gap-2">
                    <span class="text-caption text-grey text-uppercase font-weight-bold">Ambiente:</span>
                    <v-btn-toggle v-model="selectedNfceEnvironment" mandatory density="compact" color="primary" variant="outlined" divided>
                        <v-btn value="homologacao" class="text-caption px-2" height="28">Homolog</v-btn>
                        <v-btn value="producao" class="text-caption px-2" height="28">Prod</v-btn>
                    </v-btn-toggle>
                </div>
                <div class="d-flex gap-3">
                    <v-btn variant="outlined" class="btn-3d" height="45" @click="nfceModal.show = false">Cancelar</v-btn>
                    <v-btn color="deep-orange" variant="flat" class="btn-3d px-8 font-weight-black text-body-1" height="45" :loading="nfceModal.loading" @click="submitNFCe">
                        <v-icon start>mdi-send-check</v-icon> EMITIR CUPOM
                    </v-btn>
                </div>
            </div>
        </v-card>
    </v-dialog>

    <v-dialog v-model="nfceErrorDialog.show" max-width="600">
        <v-card class="rounded-lg pa-6 border-thin">
            <div class="d-flex align-center gap-3 mb-4 text-error">
                <v-icon size="40">mdi-alert-octagon</v-icon>
                <h3 class="text-h6 font-weight-bold">Emissão Rejeitada</h3>
            </div>
            <v-alert type="error" variant="tonal" class="mb-4 text-caption font-weight-bold border-error">
                {{ nfceErrorDialog.message }}
            </v-alert>
            <div class="pa-4 rounded mb-4 overflow-auto custom-scroll" style="max-height: 300px; background: rgba(0,0,0,0.05);">
                <pre class="text-caption font-mono">{{ JSON.stringify(nfceErrorDialog.details, null, 2) }}</pre>
            </div>
            <v-btn block color="primary" variant="flat" size="large" class="font-weight-bold btn-3d" @click="nfceErrorDialog.show = false">
                Entendi, vou corrigir
            </v-btn>
        </v-card>
    </v-dialog>

    <v-dialog v-model="financialViewDialog" max-width="900" scrollable>
        <v-card class="rounded-xl overflow-hidden border-thin" :class="theme.global.current.value.dark ? 'bg-surface' : 'bg-white'">
            <div class="pa-5 border-b d-flex justify-space-between align-center" :class="theme.global.current.value.dark ? 'border-white-10' : 'border-grey-lighten-2'">
                <div>
                    <h3 class="text-h6 font-weight-black">Financeiro do Pedido #{{ currentViewingOrder?.order_number }}</h3>
                    <div class="text-body-2 opacity-70">{{ currentViewingOrder?.customer_name }}</div>
                </div>
                <v-btn icon variant="text" @click="financialViewDialog = false"><v-icon>mdi-close</v-icon></v-btn>
            </div>
            <div class="pa-5 bg-grey-lighten-5">
                <v-row>
                    <v-col cols="4">
                        <v-card class="pa-4 text-center rounded-lg border-thin" elevation="0">
                            <div class="text-caption font-weight-bold text-uppercase opacity-60">Total Pedido</div>
                            <div class="text-h5 font-weight-black">{{ formatCurrency(financialSummary.total) }}</div>
                        </v-card>
                    </v-col>
                    <v-col cols="4">
                        <v-card class="pa-4 text-center rounded-lg border-thin bg-green-lighten-5 text-green-darken-3" elevation="0">
                            <div class="text-caption font-weight-bold text-uppercase opacity-80">Recebido (Pago)</div>
                            <div class="text-h5 font-weight-black">{{ formatCurrency(financialSummary.received) }}</div>
                        </v-card>
                    </v-col>
                    <v-col cols="4">
                        <v-card class="pa-4 text-center rounded-lg border-thin" :class="financialSummary.pending > 0 ? 'bg-red-lighten-5 text-red-darken-3' : 'bg-grey-lighten-4'" elevation="0">
                            <div class="text-caption font-weight-bold text-uppercase opacity-80">Pendente</div>
                            <div class="text-h5 font-weight-black">{{ formatCurrency(financialSummary.pending) }}</div>
                        </v-card>
                    </v-col>
                </v-row>
            </div>
            <v-card-text class="pa-0">
                <v-table class="text-caption" density="compact">
                    <thead>
                        <tr class="bg-grey-lighten-4">
                            <th class="font-weight-bold text-uppercase" style="font-size: 13px;">Vencimento</th>
                            <th class="font-weight-bold text-uppercase" style="font-size: 13px;">Descrição</th>
                            <th class="font-weight-bold text-uppercase text-right" style="font-size: 13px;">Valor</th>
                            <th class="font-weight-bold text-uppercase text-center" style="font-size: 13px;">Status</th>
                            <th class="font-weight-bold text-uppercase text-center" style="font-size: 13px;">Pagamento</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr v-for="rec in financialSummary.receivables" :key="rec.id" class="hover:bg-grey-lighten-5">
                            <td class="font-mono font-weight-bold" style="font-size: 13px;">{{ formatDate(rec.due_date) }}</td>
                            <td style="font-size: 13px;">{{ rec.description }}</td>
                            <td class="text-right font-mono font-weight-black" style="font-size: 13px;">{{ formatCurrency(rec.value) }}</td>
                            <td class="text-center">
                                <v-chip size="small" :color="rec.status === 'pago' ? 'success' : (rec.is_virtual ? 'info' : 'warning')" label class="font-weight-bold text-uppercase chip-3d">
                                    {{ rec.status === 'pago' ? 'Pago' : (rec.is_virtual ? 'Previsto' : 'Em Aberto') }}
                                </v-chip>
                            </td>
                            <td class="text-center font-mono opacity-70" style="font-size: 13px;">
                                <span v-if="rec.is_virtual" class="text-info text-[10px] font-weight-bold text-uppercase">Ag. Faturamento</span>
                                <span v-else>{{ rec.payment_date ? formatDate(rec.payment_date) : '-' }}</span>
                            </td>
                        </tr>
                        <tr v-if="financialSummary.receivables.length === 0">
                            <td colspan="5" class="text-center py-8 opacity-50 text-subtitle-2">Nenhuma parcela encontrada.</td>
                        </tr>
                    </tbody>
                </v-table>
            </v-card-text>
        </v-card>
    </v-dialog>

    <v-dialog v-model="statusModal.show" max-width="400">
        <v-card :class="theme.global.current.value.dark ? 'bg-grey-darken-4' : 'bg-white'">
            <v-card-title class="text-subtitle-2 font-weight-bold border-b d-flex align-center justify-space-between pa-4">
                Alterar Status Financeiro
                <v-btn icon size="small" variant="text" @click="statusModal.show = false"><v-icon>mdi-close</v-icon></v-btn>
            </v-card-title>
            <v-card-text class="pa-4">
                <div class="text-caption mb-4 opacity-70" style="font-size: 13px !important;">
                    Selecione o novo status para o pedido <strong>#{{ statusModal.order?.order_number }}</strong>.
                </div>
                <v-list density="compact" class="bg-transparent" nav>
                  <v-list-item @click="confirmStatusChange('Em Aberto')" class="mb-1 border-thin" rounded>
                      <template v-slot:prepend><v-icon color="grey" class="mr-3">mdi-clock-outline</v-icon></template>
                      <v-list-item-title class="font-weight-bold" style="font-size: 13px;">Em Aberto</v-list-item-title>
                  </v-list-item>
                    <v-list-item @click="confirmStatusChange('Parcialmente Faturado')" class="mb-1 border-thin" rounded>
                        <template v-slot:prepend><v-icon color="warning" class="mr-3">mdi-circle-slice-4</v-icon></template>
                        <v-list-item-title class="font-weight-bold text-warning" style="font-size: 13px;">Parcialmente Faturado</v-list-item-title>
                    </v-list-item>
                    <v-list-item @click="confirmStatusChange('Faturado')" class="mb-1 border-thin" rounded>
                        <template v-slot:prepend><v-icon color="success" class="mr-3">mdi-check-all</v-icon></template>
                        <v-list-item-title class="font-weight-bold text-success" style="font-size: 13px;">Faturado (Auditado)</v-list-item-title>
                    </v-list-item>
                    <v-divider class="my-2"></v-divider>
                    <v-list-item @click="confirmStatusChange('Cancelado')" class="border-thin bg-error-transparent" rounded>
                        <template v-slot:prepend><v-icon color="error" class="mr-3">mdi-cancel</v-icon></template>
                        <v-list-item-title class="font-weight-bold text-error" style="font-size: 13px;">Cancelado / Estornado</v-list-item-title>
                    </v-list-item>
                </v-list>
            </v-card-text>
        </v-card>
    </v-dialog>

    <v-dialog v-model="cancelResultDialog.show" max-width="450">
        <v-card class="rounded-lg pa-6 border-thin">
            <div class="d-flex align-center gap-3 mb-4 text-primary">
                <v-icon size="32">mdi-information-outline</v-icon>
                <h3 class="text-h6 font-weight-bold">{{ cancelResultDialog.title }}</h3>
            </div>
            <div class="mb-6 text-body-2 font-weight-medium text-grey-darken-3" style="white-space: pre-wrap;">
                {{ cancelResultDialog.message }}
            </div>
            <v-btn block color="primary" variant="flat" size="large" class="font-weight-bold btn-3d" @click="cancelResultDialog.show = false">
                Ciente
            </v-btn>
        </v-card>
    </v-dialog>

    <NfeEmissionModal
        v-model="nfeModalState.show"
        :order-id="nfeModalState.orderId"
        @success="fetchOrders"
    />

  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, reactive, watch } from 'vue';
import { useTheme, useDisplay } from 'vuetify';
import { supabase } from '@/api/supabase';
import { sefazService } from '@/api/sefazApi';
import { format, parseISO, differenceInCalendarDays, startOfMonth, endOfMonth, startOfWeek, endOfWeek, startOfYear, endOfYear, isSameDay, startOfDay, endOfDay, isBefore, startOfToday } from 'date-fns';
import { useAppStore } from '@/stores/app';
import BillingModal from '@/components/admin/BillingModal.vue';
import OrderPaymentsModal from '@/components/OrderPaymentsModal.vue';
import { useRouter } from 'vue-router';
import { useUserStore } from '@/stores/user';
import { useCompanyStore } from '@/stores/company'; // MULTI-TENANT
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import { vMaska } from "maska/vue";
import axios from 'axios';
import NfeEmissionModal from '@/components/admin/fiscal/NfeEmissionModal.vue';

// --- STATE ---
const { mobile } = useDisplay();
const theme = useTheme();
const router = useRouter();
const appStore = useAppStore();
const userStore = useUserStore();
const companyStore = useCompanyStore(); // MULTI-TENANT

type UnifiedOrderMode = 'sales' | 'billing' | 'admin' | 'readonly';

const sellerToRegionMap: Record<string, 'sudeste' | 'nordeste'> = {
    'Beatriz Garcia': 'sudeste',
    'Marcos Levi': 'sudeste',
    'Juci': 'sudeste',
    'Elda': 'nordeste',
    'Sueli': 'nordeste',
    'Fernanda Garcia': 'sudeste',
    'João Vitor': 'sudeste',
    'Danilo Martins': 'sudeste'
};

const userRegion = computed(() => {
    const name = userStore.profile?.full_name;
    if (!name) return 'sudeste';
    return sellerToRegionMap[name] || 'sudeste';
});

const baseOrderMode = computed<UnifiedOrderMode>(() => {
    const role = userStore.profile?.role || '';

    if (['super_admin', 'admin', 'gerente'].includes(role)) return 'admin';
    if (['faturador', 'financeiro'].includes(role)) return 'billing';
    if (role === 'vendedor') return 'sales';

    if (userStore.hasPermission?.('sales_management')) return 'billing';
    if (userStore.hasPermission?.('sales_my_orders')) return 'sales';

    return 'readonly';
});

const selectedOrderMode = ref<UnifiedOrderMode>('admin');

const canSwitchOrderMode = computed(() => baseOrderMode.value === 'admin');
const activeOrderMode = computed<UnifiedOrderMode>(() => canSwitchOrderMode.value ? selectedOrderMode.value : baseOrderMode.value);

watch(baseOrderMode, (mode) => {
    selectedOrderMode.value = mode === 'admin' ? 'admin' : mode;
}, { immediate: true });

const canUseSalesActions = computed(() => ['sales', 'admin'].includes(activeOrderMode.value));
const canUseBillingActions = computed(() => ['billing', 'admin'].includes(activeOrderMode.value));

const userCompanyId = computed(() => {
    const profile: any = userStore.profile || {};
    return profile.company_id || profile.companyId || profile.default_company_id || profile.tenant_id || profile.company?.id || null;
});

const isSellerTenantLocked = computed(() => activeOrderMode.value === 'sales' && !!userCompanyId.value);
const showContextSwitcher = computed(() => !isSellerTenantLocked.value);

const sellerLockedCompanyName = computed(() => {
    if (!userCompanyId.value) return '';
    const company = (companyStore.availableCompanies || []).find((c: any) => c.id === userCompanyId.value);
    return company?.trade_name || company?.name || 'Empresa vinculada';
});

const orderModeSubtitle = computed(() => {
    if (activeOrderMode.value === 'sales') {
        return isSellerTenantLocked.value
            ? 'Visão comercial restrita à empresa vinculada ao vendedor. Use o editar para lançar ou conferir recebimentos.'
            : 'Visão comercial para acompanhamento de pedidos e recebimentos.';
    }
    if (activeOrderMode.value === 'billing') return 'Visão de faturamento, auditoria fiscal, financeiro e conferência dos pedidos.';
    if (activeOrderMode.value === 'admin') return 'Visão completa com ações comerciais, financeiras, fiscais e administrativas.';
    return 'Acesso somente para consulta dos pedidos.';
});

const orderModeTitle = computed(() => {
    if (activeOrderMode.value === 'sales') return 'Modo Comercial';
    if (activeOrderMode.value === 'billing') return 'Modo Faturamento';
    if (activeOrderMode.value === 'admin') return 'Modo Completo';
    return 'Somente Leitura';
});

const orderModeColor = computed(() => {
    if (activeOrderMode.value === 'sales') return 'success';
    if (activeOrderMode.value === 'billing') return 'primary';
    if (activeOrderMode.value === 'admin') return 'purple';
    return 'grey';
});

const primaryActionLabel = computed(() => {
    if (activeOrderMode.value === 'sales') return 'Editar recebimentos / parcelas';
    if (activeOrderMode.value === 'billing') return 'Auditar / faturar pedido';
    if (activeOrderMode.value === 'admin') return 'Abrir faturamento completo';
    return 'Visualizar pedido';
});

const mobilePrimaryActionLabel = computed(() => {
    if (activeOrderMode.value === 'sales') return 'Receber';
    if (activeOrderMode.value === 'billing') return 'Faturar';
    if (activeOrderMode.value === 'admin') return 'Editar';
    return 'Ver';
});

const primaryActionIcon = computed(() => {
    if (activeOrderMode.value === 'sales') return 'mdi-cash-register';
    if (activeOrderMode.value === 'billing') return 'mdi-file-document-check';
    if (activeOrderMode.value === 'admin') return 'mdi-pencil';
    return 'mdi-eye';
});

const primaryActionClass = computed(() => {
    if (activeOrderMode.value === 'sales') return 'action-payment-main';
    if (activeOrderMode.value === 'billing') return 'action-edit';
    if (activeOrderMode.value === 'admin') return 'action-edit';
    return 'action-more';
});

const mobilePrimaryButtonClass = computed(() => {
    if (activeOrderMode.value === 'sales') return 'mbtn--payment';
    if (activeOrderMode.value === 'billing') return 'mbtn--edit';
    if (activeOrderMode.value === 'admin') return 'mbtn--edit';
    return 'mbtn--more';
});


const isMobileFullscreen = ref(false);
const mobileMenuOpen = ref(false);

const loading = ref(false);
const orders = ref<any[]>([]);
const search = ref('');
const page = ref(1);
const itemsPerPage = 30;

// Filtros
const filterSeller = ref(null);
const filterDateStart = ref(null);
const filterDateEnd = ref(null);
const filterFinancialStatus = ref(null);
const filterProductionStatus = ref(null);
const currentPeriod = ref('month');

const billingDialog = ref(false);
const paymentDialog = ref(false);
const selectedOrder = ref<any>(null);
const selectedPaymentOrder = ref<any>(null);
const generatingPdf = ref(false);
const financialViewDialog = ref(false);
const financialSummary = ref({ total: 0, received: 0, pending: 0, receivables: [] as any[] });
const currentViewingOrder = ref<any>(null);
const cancelResultDialog = reactive({ show: false, message: '', title: 'Cancelamento de Pedido' });

const statusFilters = [
    { label: 'Todos', value: 'all' },
    { label: 'Em Aberto', value: 'Em Aberto' },
    { label: 'Pendente', value: 'Pendente' },
    { label: 'Parcialmente Faturado', value: 'Parcialmente Faturado' },
    { label: 'Faturado', value: 'Faturado' },
    { label: 'Cancelado', value: 'Cancelado' }
];

const productionStatusFilters = [
    { title: 'Fila', value: 'production_queue' },
    { title: 'Em Produção', value: 'in_production' },
    { title: 'Pronto Entrega', value: 'ready_for_delivery' },
    { title: 'Entregue', value: 'delivered' },
    { title: 'Concluído', value: 'completed' }
];

// --- NFE STATE ---
const nfeModal = reactive({
    show: false, activeTab: 'data', loading: false, savingDraft: false,
    fetchingData: false, consulting: false, draftLoaded: false,
    orderNumber: '', orderId: null as string | null, errorMessages: [] as string[]
});
const activeCompany = ref<any>(null);
const companies = ref<any[]>([]);
const previewUrl = ref('');
const previewLoading = ref(false);
const nfeForm = reactive({
    natureza_operacao: 'VENDA DE MERCADORIA',
    destinatario: { cnpj_cpf: '', nome: '', ie: '', email: '', endereco: { logradouro: '', numero: '', bairro: '', municipio: '', uf: 'SP', cep: '' } },
    itens: [] as any[],
    pagamento: { forma: '0', meio: '17' },
    obs: ''
});
const naturezaOptions = ['VENDA DE MERCADORIA', 'REMESSA PARA INDUSTRIALIZACAO', 'RETORNO DE INDUSTRIALIZACAO', 'BONIFICACAO'];
const mediosPagamento = [{ text: 'PIX', value: '17' }];

// --- NFC-e STATE ---
const nfceModal = reactive({ show: false, loading: false, orderNumber: '', orderId: null as string | null });
const activeNfceCompany = ref<any>(null);
const selectedNfceEnvironment = ref('homologacao');
const nfcePercentage = ref(100);
const nfceOriginalItems = ref<any[]>([]);
const nfceForm = reactive({ cpf: '', nome: '', itens: [] as any[], pagamento: { forma: '01', meio: '01', valor: 0 } });
const nfceTotalValue = computed(() => nfceForm.itens.reduce((acc, item) => acc + (item.quantidade * item.valor_unitario), 0));
const nfcePaymentMethods = [{ label: 'Dinheiro', code: '01' }, { label: 'Cartão Crédito', code: '03' }, { label: 'Cartão Débito', code: '04' }, { label: 'PIX', code: '17' }];
const nfceErrorDialog = reactive({ show: false, message: '', details: null as any, title: 'Erro' });

watch(nfceTotalValue, (val) => { nfceForm.pagamento.valor = val; });

watch(nfcePercentage, (newPct) => {
    const factor = newPct / 100;
    nfceForm.itens = nfceOriginalItems.value.map((origItem, index) => {
        const currentItem = nfceForm.itens[index] || {};
        return {
            ...currentItem,
            descricao: currentItem.descricao || origItem.descricao,
            ncm: currentItem.ncm || origItem.ncm,
            cfop: currentItem.cfop || origItem.cfop,
            quantidade: origItem.quantidade,
            valor_unitario: Number((origItem.valor_unitario * factor).toFixed(4))
        };
    });
});

// --- SHARE STATE ---
const shareModal = reactive({ show: false, message: '', order: null as any, channel: 'whatsapp', docType: 'NFe', loading: false });
const statusModal = reactive({ show: false, order: null as any, loading: false });

// --- UTILS ---
const formatCurrency = (val: number) => new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(val || 0);
const formatNumber = (val: number) => new Intl.NumberFormat('pt-BR', { minimumFractionDigits: 0, maximumFractionDigits: 2 }).format(val || 0);

const formatDueDate = (date: any) => {
    if (!date) return '-';

    const raw = String(date);

    // Evita diferença de 1 dia por fuso quando o banco salva 00:00:00Z.
    const match = raw.match(/^(\d{4})-(\d{2})-(\d{2})/);
    if (match) {
        return `${match[3]}/${match[2]}/${match[1]}`;
    }

    try {
        return format(parseISO(raw), 'dd/MM/yyyy');
    } catch {
        return raw;
    }
};

const formatDate = (d: any) => {
    if (!d) return '-';
    const dateObj = new Date(d);
    if (isNaN(dateObj.getTime())) return '-';
    const day = String(dateObj.getDate()).padStart(2, '0');
    const month = String(dateObj.getMonth() + 1).padStart(2, '0');
    const year = String(dateObj.getFullYear()).slice(-2);
    return `${day}/${month}/${year}`;
};
const cleanDigits = (val: any) => {
    return String(val || '').replace(/\D/g, '');
};

const formatStatus = (s: string) => {
    const k = String(s || '').trim().toLowerCase();
    const map: Record<string, string> = {
        'production_queue': 'Fila',
        'in_production': 'Produção',
        'completed': 'Concluído',
        'cancelled': 'Cancelado',
        'ready_for_delivery': 'Pronta Entrega',
        'delivered': 'Entregue',
        'design_pending': 'Design',
        'customer_approval': 'Aprovação',
        'billing_pending': 'Faturamento Pend.'
    };
    return map[k] || s;
};

const getStatusColor = (s: string) => {
    const map: Record<string, string> = {
        'production_queue': 'warning',
        'in_production': 'info',
        'completed': 'success',
        'cancelled': 'danger',
        'ready_for_delivery': 'success',
        'delivered': 'success',
        'design_pending': 'purple',
        'customer_approval': 'info',
        'billing_pending': 'warning'
    };
    return map[String(s || '').toLowerCase()] || 'default';
};

const getColor = (name: string) => { const colors = ['primary', 'secondary', 'info', 'success', 'warning', 'error']; let hash = 0; if(!name) return 'grey'; for(let i=0; i<name.length; i++) hash = name.charCodeAt(i) + ((hash << 5) - hash); return colors[Math.abs(hash) % colors.length]; };

const getFinancialChipClass = (s: string) => {
    switch(String(s||'').toLowerCase()) {
        case 'faturado': return 'chip-success';
        case 'parcialmente faturado': return 'chip-warning';
        case 'cancelado': return 'chip-danger';
        default: return 'chip-info';
    }
};

const getInstallmentValue = (installment: any) => Number(
    installment?.value ??
    installment?.amount ??
    installment?.total ??
    installment?.valor ??
    installment?.installment_value ??
    0
);

const getSellerPaymentLabel = (item: any) => {
    const total = Number(item?.total_value || 0);
    const paid = Number(item?.total_paid || 0);

    // Para vendedor, QUITADO só pode significar dinheiro confirmado >= total do pedido.
    // Não pode depender apenas de existir alguma parcela criada, nem de financial_status antigo.
    if (total > 0 && paid >= total - 0.05) return 'QUITADO';
    if (paid > 0) return 'PARCIAL';
    return 'PENDENTE';
};

const getSellerPaymentChipClass = (item: any) => {
    const label = getSellerPaymentLabel(item).toLowerCase();
    if (label.includes('quitado')) return 'chip-success';
    if (label.includes('parcial')) return 'chip-warning';
    return 'chip-danger';
};


const hasSignal = (item: any) => { if (item.financial_status === 'Parcialmente Faturado') return true; if (Number(item.details?.entry_value) > 0) return true; return false; };
const getSignalValue = (item: any) => Number(item.details?.entry_value || 0);

const isInstallmentPaidInPayload = (installment: any) => {
    if (!installment) return false;

    const rawStatus = String(
        installment.status ||
        installment.payment_status ||
        installment.financial_status ||
        installment.situacao ||
        installment.state ||
        ''
    ).toLowerCase();

    if (['pago', 'paid', 'quitado', 'faturado', 'recebido', 'liquidado', 'baixado'].some(k => rawStatus.includes(k))) {
        return true;
    }

    if (installment.paid === true || installment.is_paid === true || installment.received === true || installment.liquidated === true) {
        return true;
    }

    const value = Number(installment.value || installment.amount || installment.total || 0);
    const paidValue = Number(installment.paid_value || installment.amount_paid || installment.received_value || installment.valor_pago || 0);

    if (value > 0 && paidValue >= value - 0.05) return true;
    if (installment.payment_date || installment.paid_at || installment.received_at || installment.liquidated_at) return true;

    return false;
};

const getOrderFinancialSnapshot = (order: any, orderRecs: any[] = []) => {
    const orderTotal = Number(order?.total_value || 0);
    const schedule = Array.isArray(order?.details?.installments_schedule) ? order.details.installments_schedule : [];

    const paidStatuses = ['pago', 'paid', 'quitado', 'faturado', 'recebido', 'liquidado', 'baixado'];

    const dbPaidTotal = orderRecs
        .filter((r: any) => paidStatuses.includes(String(r.status || '').toLowerCase()))
        .reduce((sum: number, r: any) => sum + Number(r.value || 0), 0);

    const dbTotal = orderRecs.reduce((sum: number, r: any) => sum + Number(r.value || 0), 0);
    const payloadPaidTotal = schedule
        .filter((sch: any) => isInstallmentPaidInPayload(sch))
        .reduce((sum: number, sch: any) => sum + getInstallmentValue(sch), 0);
    const payloadTotal = schedule.reduce((sum: number, sch: any) => sum + getInstallmentValue(sch), 0);

    const status = String(order?.financial_status || '').toLowerCase();
    const fullyPaidByStatus = ['faturado', 'quitado', 'pago', 'paid'].some(k => status.includes(k));
    const fullyPaidByDb = orderTotal > 0 && dbPaidTotal >= orderTotal - 0.05;
    const fullyPaidByPayload = orderTotal > 0 && payloadPaidTotal >= orderTotal - 0.05;
    const fullyPaidByAllPayloadInstallments = schedule.length > 0 && payloadTotal >= orderTotal - 0.05 && schedule.every((sch: any) => isInstallmentPaidInPayload(sch));

    const hasPaymentEvidence = orderRecs.length > 0 || schedule.length > 0 || dbPaidTotal > 0 || payloadPaidTotal > 0 || dbTotal > 0 || payloadTotal > 0;

    // Regra corrigida:
    // - se existe qualquer evidência de parcelas/recebimentos, QUITADO só se o total pago alcançar o total do pedido;
    // - o financial_status antigo sozinho não pode mascarar saldo em aberto;
    // - status antigo só é aceito quando não há nenhuma evidência financeira detalhada.
    const isFullyPaid = fullyPaidByDb || fullyPaidByPayload || fullyPaidByAllPayloadInstallments || (!hasPaymentEvidence && fullyPaidByStatus);

    return {
        orderTotal,
        dbTotal,
        dbPaidTotal,
        payloadTotal,
        payloadPaidTotal,
        paidTotal: Math.max(dbPaidTotal, payloadPaidTotal),
        isFullyPaid
    };
};

const getDeliveryBadgeClass = (item: any) => {
    if (['delivered', 'completed', 'ready_for_delivery'].includes(item.status)) return 'bg-success-transparent text-success';
    if (!item.delivery_date_obj) return '';
    const now = new Date(); now.setHours(0,0,0,0);
    const del = new Date(item.delivery_date_obj); del.setHours(0,0,0,0);
    if (del < now) return 'bg-error-transparent text-error';
    if (isSameDay(del, now)) return 'bg-warning-transparent text-warning';
    return 'bg-success-transparent text-success';
};

const getDeliveryColorClass = (item: any) => {
    if (['delivered', 'completed', 'ready_for_delivery'].includes(item.status)) return 'text-success';
    if (!item.delivery_date_obj) return 'text-grey-darken-1';
    const now = new Date(); now.setHours(0,0,0,0);
    const del = new Date(item.delivery_date_obj); del.setHours(0,0,0,0);
    if (del < now) return 'text-error';
    if (isSameDay(del, now)) return 'text-warning';
    return 'text-success';
};

const getDeliveryInfo = (item: any) => {
    if (!item) return { dateStr: '--/--', daysDiff: null, fullDate: null };
    try {
        let finalDateObj = null;

        let savedDate = item.delivery_date || item.actual_delivery_date || item.forecast_delivery_date || item.details?.forecast_delivery_date;

        if (savedDate) {
            if (typeof savedDate === 'string' && savedDate.length === 10) {
                savedDate += 'T12:00:00';
            }
            finalDateObj = new Date(savedDate);
        }
        else {
            const baseDateStr = item.created_at || item.order?.created_at;
            const baseDate = baseDateStr ? new Date(baseDateStr) : new Date();
            finalDateObj = appStore.calculateForecastDate(baseDate);
        }

        if (!finalDateObj || isNaN(finalDateObj.getTime())) {
            return { dateStr: '--/--', daysDiff: null, fullDate: null };
        }

        const now = new Date();
        now.setHours(0,0,0,0);
        const deliveryMidnight = new Date(finalDateObj);
        deliveryMidnight.setHours(0,0,0,0);

        const diffTime = deliveryMidnight.getTime() - now.getTime();
        const diff = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

        let diffText = '';
        if (diff < 0) diffText = `${Math.abs(diff)}d atraso`;
        else if (diff === 0) diffText = 'Hoje';
        else diffText = `${diff}d`;

        const day = String(finalDateObj.getDate()).padStart(2, '0');
        const month = String(finalDateObj.getMonth() + 1).padStart(2, '0');

        return { dateStr: `${day}/${month}`, daysDiff: diffText, fullDate: finalDateObj };
    } catch (e) {
        console.error("Erro calcular data de entrega:", e);
        return { dateStr: '--/--', daysDiff: null, fullDate: null };
    }
};

watch(() => companyStore.context, () => {
    page.value = 1;
    fetchOrders();
});

watch(activeOrderMode, () => {
    page.value = 1;
    fetchOrders();
});

// --- FETCH ORDERS & FISCAL MATCHING ---
const fetchOrders = async () => {
    loading.value = true;
    try {
        let query = supabase
            .from('orders')
            .select('*, creator:created_by(full_name), company:company_id(trade_name)')
            .order('created_at', { ascending: false });

        if (isSellerTenantLocked.value && userCompanyId.value) {
            query = query.eq('company_id', userCompanyId.value);
        } else if (!companyStore.isGlobalView && companyStore.context) {
            query = query.eq('company_id', companyStore.context);
        }

        const { data: ordersData, error: ordersErr } = await query;
        if (ordersErr) throw ordersErr;

        let scopedOrdersData = ordersData || [];

        if (activeOrderMode.value === 'sales' && !canSwitchOrderMode.value) {
            scopedOrdersData = scopedOrdersData.filter((order: any) => {
                const sellerName = order.creator?.full_name;
                if (!sellerName) return order.created_by === userStore.user?.id;

                const orderRegion = sellerToRegionMap[sellerName] || 'sudeste';
                return orderRegion === userRegion.value;
            });
        }

        const { data: nfeData } = await supabase.from('nfe_outbound').select('*').in('status', ['AUTORIZADA', 'autorizado']);
        const { data: nfceData } = await supabase.from('nfce_outbound').select('*').in('status', ['AUTORIZADA', 'autorizado']);

        const orderIds = (scopedOrdersData || []).map(o => o.id);
        const recData: any[] = [];

        if (orderIds.length > 0) {
            const chunkSize = 100;
            for (let i = 0; i < orderIds.length; i += chunkSize) {
                const chunk = orderIds.slice(i, i + chunkSize);
                const { data, error } = await supabase
                    .from('finance_receivables')
                    .select('order_id, value, status')
                    .in('order_id', chunk);
                if (data) recData.push(...data);
                if (error) console.error('Erro ao buscar contas a receber:', error);
            }
        }

        const recsByOrder = recData.reduce((acc, r) => {
            if (!acc[r.order_id]) acc[r.order_id] = [];
            acc[r.order_id].push(r);
            return acc;
        }, {});

        orders.value = (scopedOrdersData || []).map(o => {
            let fiscalDoc = { found: false, type: '', key: '', pdf: '', nuvem_id: '' };

            const checkMatch = (doc: any) => {
                if (doc.retorno_sefaz?.payload?.orderId === o.id) return true;
                if (o.nfe_key && doc.chave && o.nfe_key === doc.chave) return true;
                const docVal = Number(doc.valor_total);
                const orderVal = Number(o.total_value);
                if (Math.abs(docVal - orderVal) < 0.1) {
                    if (o.nfe_number && String(doc.numero) === String(o.nfe_number)) return true;
                    const docName = String(doc.destinatario_nome || '').toLowerCase();
                    const orderName = String(o.customer_name || '').toLowerCase();
                    if (docName.length > 3 && orderName.includes(docName)) return true;
                }
                return false;
            };

            const foundNfe = nfeData?.find(d => checkMatch(d));
            if (foundNfe) {
                fiscalDoc = { found: true, type: 'NFe', key: foundNfe.chave, pdf: foundNfe.pdf_link, nuvem_id: foundNfe.retorno_sefaz?.id_nuvem || foundNfe.retorno_sefaz?.id };
            } else {
                const foundNfce = nfceData?.find(d => checkMatch(d));
                if (foundNfce) {
                    fiscalDoc = { found: true, type: 'NFCe', key: foundNfce.chave, pdf: foundNfce.pdf_link, nuvem_id: foundNfce.retorno_sefaz?.id_nuvem || foundNfce.retorno_sefaz?.id };
                }
            }

            const orderRecs = recsByOrder[o.id] || [];
            const schedule = o.details?.installments_schedule || [];
            const financialSnapshot = getOrderFinancialSnapshot(o, orderRecs);

            let bStatus = o.financial_status || 'Pendente';
            if (fiscalDoc.found) bStatus = 'Faturado';
            else if (o.is_invoiced) bStatus = 'Faturado';
            else if (financialSnapshot.isFullyPaid) bStatus = 'Faturado';
            else if (bStatus === 'Pendente' && Number(o.details?.entry_value) > 0) bStatus = 'Parcialmente Faturado';

            const dInfo = getDeliveryInfo(o);

            const missingInstallments: any[] = [];
            const paidDbPool = [...orderRecs].filter((r: any) => ['pago', 'paid', 'quitado', 'faturado', 'recebido', 'liquidado', 'baixado'].includes(String(r.status || '').toLowerCase()));

            if (!financialSnapshot.isFullyPaid) {
                if (schedule.length > 0) {
                    schedule.forEach((sch: any) => {
                        const schValue = getInstallmentValue(sch);
                        if (isInstallmentPaidInPayload(sch)) return;

                        const paidMatchIdx = paidDbPool.findIndex((r: any) => Math.abs(Number(r.value) - schValue) < 0.1);
                        if (paidMatchIdx !== -1) {
                            paidDbPool.splice(paidMatchIdx, 1);
                            return;
                        }

                        missingInstallments.push({
                            ...sch,
                            value: schValue,
                            due_date: sch.due_date || sch.dueDate || sch.vencimento || sch.date || o.created_at
                        });
                    });
                }

                // Mesmo que todas as parcelas projetadas tenham sido marcadas como pagas,
                // ainda pode sobrar saldo do pedido. Ex.: pedido de 3.596, pago 2.000,
                // payload só tinha o sinal de 2.000. A grid precisa mostrar 1.596 pendente.
                const paidTotal = Number(financialSnapshot.paidTotal || 0);
                const alreadyMissingTotal = missingInstallments.reduce((sum: number, sch: any) => sum + Number(sch.value || 0), 0);
                const remainingValue = Math.max(0, financialSnapshot.orderTotal - paidTotal - alreadyMissingTotal);

                if (remainingValue > 0.05) {
                    missingInstallments.push({
                        description: `Saldo restante do pedido`,
                        value: remainingValue,
                        due_date: o.created_at
                    });
                }
            }

            return {
                ...o,
                financial_status: bStatus,
                real_payment_status: financialSnapshot.isFullyPaid ? 'Quitado' : (missingInstallments.length > 0 ? 'Pendente' : (bStatus || 'Pendente')),
                fiscal_doc: fiscalDoc,
                estimated_delivery: dInfo.dateStr,
                days_until_delivery_short: dInfo.daysDiff,
                delivery_date_obj: dInfo.fullDate,
                missing_installments: missingInstallments,
                payment_pending_count: missingInstallments.length,
                total_paid: financialSnapshot.paidTotal
            };
        });
    } catch(e) {
        console.error("Erro fetchOrders:", e);
    } finally {
        loading.value = false;
    }
};

const getDisplayDeliveryDate = (item: any) => {
    if (!item || !item.delivery_date_obj) return '-';
    const d = new Date(item.delivery_date_obj);
    if (!isNaN(d.getTime())) {
        const day = String(d.getDate()).padStart(2, '0');
        const month = String(d.getMonth() + 1).padStart(2, '0');
        const year = d.getFullYear();
        return `${day}/${month}/${year}`;
    }
    return '-';
};

// --- FILTROS COMPUTADOS ---
const hasActiveFilters = computed(() => !!filterSeller.value || !!filterDateStart.value || !!filterDateEnd.value || !!filterFinancialStatus.value || !!filterProductionStatus.value);
const availableSellers = computed(() => { const sellers = new Set(orders.value.map(o => o.creator?.full_name).filter(Boolean)); return Array.from(sellers).sort(); });

const filteredOrders = computed(() => {
    let list = orders.value || [];
    const now = new Date();
    let start: Date | null = null;
    let end: Date | null = null;

    if (currentPeriod.value === 'today') { start = now; end = now; }
    else if (currentPeriod.value === 'week') { start = startOfWeek(now, { weekStartsOn: 1 }); end = endOfWeek(now, { weekStartsOn: 1 }); }
    else if (currentPeriod.value === 'month') { start = startOfMonth(now); end = endOfMonth(now); }

    if (start && end && currentPeriod.value !== 'all') {
        const s = startOfDay(start); const e = endOfDay(end);
        list = list.filter(o => { const d = parseISO(o.created_at); return d >= s && d <= e; });
    }

    if (filterSeller.value) list = list.filter(o => o.creator?.full_name === filterSeller.value);
    if (filterFinancialStatus.value && filterFinancialStatus.value !== 'all') list = list.filter(o => o.financial_status === filterFinancialStatus.value);
    if (filterProductionStatus.value) list = list.filter(o => o.status === filterProductionStatus.value);
    if (filterDateStart.value) list = list.filter(o => parseISO(o.created_at) >= startOfDay(parseISO(filterDateStart.value)));
    if (filterDateEnd.value) list = list.filter(o => parseISO(o.created_at) <= endOfDay(parseISO(filterDateEnd.value)));

    if (search.value) {
        const s = search.value.toLowerCase();
        const isNum = !isNaN(Number(s.replace(',', '.')));
        list = list.filter(o => {
            const matchesText = String(o.order_number).includes(s) || o.customer_name?.toLowerCase().includes(s);
            const matchesValue = isNum && Math.abs(Number(o.total_value) - Number(s.replace(',', '.'))) < 1;
            return matchesText || matchesValue;
        });
    }
    return list;
});

const paginatedOrders = computed(() => { const list = filteredOrders.value; const start = (page.value - 1) * itemsPerPage; return list.slice(start, start + itemsPerPage); });
const totalPages = computed(() => Math.ceil(filteredOrders.value.length / itemsPerPage));
const filteredTotalValue = computed(() => filteredOrders.value.reduce((acc, o) => acc + (Number(o.total_value) || 0), 0));

// --- ACTIONS ---
const openNewOrder = () => router.push({ name: 'NewOrder' });
const selectPeriod = (val: string) => currentPeriod.value = val;
const clearFilters = () => { filterSeller.value = null; filterDateStart.value = null; filterDateEnd.value = null; filterFinancialStatus.value = null; filterProductionStatus.value = null; };

const openBillingModal = (order: any) => { selectedOrder.value = order; billingDialog.value = true; };

const openOrderPaymentsModal = (order: any) => {
    selectedPaymentOrder.value = order;
    paymentDialog.value = true;
};

const handlePrimaryAction = (order: any) => {
    if (activeOrderMode.value === 'sales') {
        openOrderPaymentsModal(order);
        return;
    }

    if (activeOrderMode.value === 'billing' || activeOrderMode.value === 'admin') {
        openBillingModal(order);
        return;
    }

    printOrder(order);
};

const closeBillingModal = () => { billingDialog.value = false; selectedOrder.value = null; fetchOrders(); };
const closePaymentModal = () => { paymentDialog.value = false; selectedPaymentOrder.value = null; fetchOrders(); };

const handleOrderCancellation = async (item: any) => {
    loading.value = true;
    try {
        const { data: receivables } = await supabase.from('finance_receivables').select('*').eq('order_id', item.id);
        const toDelete = receivables?.filter(r => r.status !== 'pago') || [];
        const kept = receivables?.filter(r => r.status === 'pago') || [];

        if (toDelete.length > 0) {
            const deleteIds = toDelete.map(r => r.id);
            await supabase.from('finance_receivables').delete().in('id', deleteIds);
        }

        await supabase.from('orders').update({ status: 'cancelled', financial_status: 'Cancelado' }).eq('id', item.id);

        let alertMsg = `O pedido #${item.order_number} foi cancelado no sistema.\n\n`;
        if (toDelete.length > 0) alertMsg += `🗑️ ${toDelete.length} parcela(s) pendente(s) foram apagadas.\n`;
        if (kept.length > 0) alertMsg += `✅ ${kept.length} parcela(s) paga(s) mantida(s) no caixa (Sinal).`;
        else alertMsg += `⚠️ Nenhum valor pago para ser mantido.`;

        cancelResultDialog.message = alertMsg;
        cancelResultDialog.show = true;

        fetchOrders();
    } catch(e) {
        console.error(e);
        appStore.showSnackbar("Erro ao cancelar pedido", "error");
    } finally {
        loading.value = false;
    }
}

const openStatusChangeModal = (item: any) => { statusModal.order = item; statusModal.show = true; };
const confirmStatusChange = async (newStatus: string) => {
    if (!statusModal.order) return;
    try {
        if (newStatus === 'Cancelado') {
            await handleOrderCancellation(statusModal.order);
        } else {
            await supabase.from('orders').update({ financial_status: newStatus }).eq('id', statusModal.order.id);
            appStore.showSnackbar("Status atualizado!", "success");
        }
        statusModal.show = false;
        fetchOrders();
    } catch(e) { console.error(e); }
};

const deleteOrder = async (item: any) => {
    if(confirm(`Deseja realmente cancelar o pedido #${item.order_number}?`)) {
        await handleOrderCancellation(item);
    }
};

const confirmLaunchFinancial = async (item: any) => {
    if (!confirm(`Confirma o lançamento financeiro do Pedido #${item.order_number}?\n\nIsso irá gerar as contas a receber com base no cronograma e marcar o pedido como FATURADO.`)) {
        return;
    }
    loading.value = true;
    try {
        const { data: orderData, error: fetchError } = await supabase
            .from('orders')
            .select('details, customer_id, created_by, company_id')
            .eq('id', item.id)
            .single();

        if (fetchError) throw fetchError;

        const schedule = orderData.details?.installments_schedule || [];

        const { data: existingReceivables } = await supabase
            .from('finance_receivables')
            .select('*')
            .eq('order_id', item.id);

        const receivablesToCreate = [];

        let chartId = null;
        const { data: chartData } = await supabase
            .from('finance_chart_of_accounts')
            .select('id')
            .eq('type', 'Receita')
            .ilike('name', '%Venda de Produto%')
            .limit(1)
            .maybeSingle();

        if (chartData) {
            chartId = chartData.id;
        } else {
            const { data: fallback } = await supabase
                .from('finance_chart_of_accounts')
                .select('id')
                .eq('type', 'Receita')
                .limit(1)
                .maybeSingle();
            chartId = fallback?.id;
        }

        if (!chartId) {
             throw new Error("Nenhum Plano de Contas de Receita encontrado (Necessário 'Venda de Produto').");
        }

        let bankId = null;
        const { data: bankData } = await supabase
            .from('finance_accounts')
            .select('id')
            .eq('is_active', true)
            .limit(1)
            .maybeSingle();
        bankId = bankData?.id;

        const totalInstallments = schedule.length;

        for (const [idx, plan] of schedule.entries()) {
            if (plan.status === 'pago') continue;

            const matchInDb = existingReceivables?.some(r =>
                Math.abs(Number(r.value) - Number(plan.value)) < 0.1 &&
                r.due_date === plan.due_date
            );

            if (!matchInDb) {
                let defaultDesc = '';
                if (totalInstallments === 1) {
                    defaultDesc = `Restante - Pedido #${item.order_number}`;
                } else {
                    defaultDesc = `Parcela ${idx + 1}/${totalInstallments} - Pedido #${item.order_number}`;
                }

                receivablesToCreate.push({
                    description: plan.description || defaultDesc,
                    value: Number(plan.value),
                    due_date: plan.due_date,
                    competence_date: plan.competence_date || plan.due_date,
                    status: 'em_aberto',
                    order_id: item.id,
                    customer_id: orderData.customer_id,
                    created_by: userStore.user?.id || orderData.created_by,
                    company_id: orderData.company_id || (companyStore.isGlobalView ? null : companyStore.context),
                    chart_of_accounts_id: chartId,
                    bank_account_id: bankId,
                    payment_method_id: plan.payment_method_id || null
                });
            }
        }

        if (receivablesToCreate.length > 0) {
            const { error: insertError } = await supabase.from('finance_receivables').insert(receivablesToCreate);
            if (insertError) throw insertError;
        }

        const { error: updateError } = await supabase.from('orders').update({
            financial_status: 'Faturado',
            is_invoiced: true,
            invoiced_at: new Date().toISOString(),
            invoiced_by: userStore.user?.id
        }).eq('id', item.id);

        if (updateError) throw updateError;

        appStore.showSnackbar(`Pedido #${item.order_number} Lançado e Faturado com Sucesso!`, "success");
        await fetchOrders();

    } catch (e: any) {
        console.error("Erro ao lançar:", e);
        appStore.showSnackbar("Erro ao lançar: " + e.message, "error");
    } finally {
        loading.value = false;
    }
};

const undoLaunchFinancial = async (item: any) => {
    if (!confirm(`ATENÇÃO: Tem certeza que deseja desfazer o lançamento do pedido #${item.order_number}?\n\nIsso irá EXCLUIR PERMANENTEMENTE todos os registros financeiros deste pedido, inclusive as parcelas JÁ PAGAS.\n\nEssa ação é irreversível e indicará uma devolução/estorno.`)) {
        return;
    }

    loading.value = true;
    try {
        const { error: deleteError } = await supabase
            .from('finance_receivables')
            .delete()
            .eq('order_id', item.id);

        if (deleteError) throw deleteError;

        const { error: updateError } = await supabase
            .from('orders')
            .update({
                financial_status: 'Pendente',
                is_invoiced: false,
                invoiced_at: null,
                invoiced_by: null
            })
            .eq('id', item.id);

        if (updateError) throw updateError;

        appStore.showSnackbar(`Lançamento desfeito e financeiro do pedido #${item.order_number} excluído com sucesso!`, "success");
        await fetchOrders();

    } catch (e: any) {
        console.error("Erro ao desfazer lançamento:", e);
        appStore.showSnackbar("Erro ao desfazer: " + (e.message || e), "error");
    } finally {
        loading.value = false;
    }
};

const openFinancialView = async (item: any) => {
    currentViewingOrder.value = item;
    const { data } = await supabase.from('finance_receivables').select('*').eq('order_id', item.id).order('due_date');
    if (data) {
        financialSummary.value.receivables = data;
        let totalRec = 0;
        financialSummary.value.received = 0;
        financialSummary.value.pending = 0;

        financialSummary.value.receivables.forEach((r: any) => {
            totalRec += Number(r.value);
            if (r.status === 'pago') financialSummary.value.received += Number(r.value);
            else financialSummary.value.pending += Number(r.value);
        });

        // INCLUIR AS PARCELAS VIRTUAIS (VINDAS DA PROJEÇÃO DO VENDEDOR)
        const orderTotal = Number(item.total_value || 0);
        if (orderTotal - totalRec > 0.05) {
            const schedule = item.details?.installments_schedule || [];
            const dbPool = [...financialSummary.value.receivables];

            schedule.forEach((sch: any, idx: number) => {
                const matchIdx = dbPool.findIndex(r => Math.abs(Number(r.value) - Number(sch.value)) < 0.1);
                if (matchIdx !== -1) {
                    dbPool.splice(matchIdx, 1);
                } else {
                    let defaultDesc = '';
                    if (schedule.length === 1) {
                        defaultDesc = `Restante - Pedido #${item.order_number}`;
                    } else {
                        defaultDesc = `Parcela ${idx + 1}/${schedule.length} - Pedido #${item.order_number}`;
                    }

                    financialSummary.value.receivables.push({
                        id: 'virtual-' + idx,
                        due_date: sch.due_date,
                        value: sch.value,
                        status: 'em_aberto',
                        payment_method_id: sch.payment_method_id,
                        description: sch.description || defaultDesc,
                        is_virtual: true
                    });
                    financialSummary.value.pending += Number(sch.value);
                    totalRec += Number(sch.value);
                }
            });
            financialSummary.value.receivables.sort((a, b) => new Date(a.due_date).getTime() - new Date(b.due_date).getTime());
        }

        financialSummary.value.total = totalRec;
    }
    financialViewDialog.value = true;
};

// --- DOWNLOAD PDF (DB PRIORITÁRIO) ---
const downloadFiscalDoc = async (item: any) => {
    if (!item.fiscal_doc?.found) return;
    if (item.fiscal_doc.pdf) {
        window.open(item.fiscal_doc.pdf, '_blank');
        return;
    }
    try {
        const idNuvem = item.fiscal_doc.nuvem_id;
        if(!idNuvem) throw new Error("ID Nuvem não encontrado para este documento.");
        const endpointMethod = item.fiscal_doc.type === 'NFCe' ? 'getProxyNfceDownloadUrl' : 'getProxyDownloadUrl';
        const url = sefazService[endpointMethod]('pdf', idNuvem);
        window.open(url, '_blank');
    } catch (e: any) {
        console.error(e);
        appStore.showSnackbar("Erro ao abrir documento: " + e.message, "error");
    }
};

// --- SHARE ---
const openShareModal = async (item: any, channel: any, type: any) => {
    shareModal.order = item; shareModal.channel = channel; shareModal.docType = type;
    shareModal.show = true;
    shareModal.message = `Olá! Segue a ${type} do pedido #${item.order_number}.`;
};

const confirmShare = async () => {
    if (!shareModal.order) return;
    shareModal.loading = true;
    try {
        const order = shareModal.order;
        let file = null;
        if (order.fiscal_doc?.pdf) {
             const response = await axios.get(order.fiscal_doc.pdf, { responseType: 'blob' });
             file = new File([response.data], `${shareModal.docType}_${order.order_number}.pdf`, { type: 'application/pdf' });
        } else {
             const idNuvem = order.fiscal_doc?.nuvem_id;
             if(!idNuvem) throw new Error("Documento não disponível.");
             const endpointMethod = shareModal.docType === 'NFCe' ? 'getProxyNfceDownloadUrl' : 'getProxyDownloadUrl';
             const url = sefazService[endpointMethod]('pdf', idNuvem);
             const response = await axios.get(url, { responseType: 'blob' });
             file = new File([response.data], `Doc_${order.order_number}.pdf`, { type: 'application/pdf' });
        }

        if (shareModal.channel === 'whatsapp') {
            if (navigator.canShare && navigator.canShare({ files: [file] })) {
                await navigator.share({ files: [file], title: `Doc ${order.order_number}`, text: shareModal.message });
            } else {
                const link = document.createElement('a'); link.href = URL.createObjectURL(file); link.download = `Doc_${order.order_number}.pdf`; document.body.appendChild(link); link.click(); document.body.removeChild(link);
                window.open(`https://wa.me/?text=${encodeURIComponent(shareModal.message)}`, '_blank');
            }
        } else {
            window.open(`mailto:?subject=Nota Fiscal ${order.order_number}&body=${encodeURIComponent(shareModal.message)}`, '_blank');
        }
        shareModal.show = false;
        appStore.showSnackbar("Processo de envio iniciado.", "success");
    } catch(e: any) {
        console.error(e);
        appStore.showSnackbar("Erro ao preparar arquivo: " + e.message, "error");
    } finally {
        shareModal.loading = false;
    }
};

// --- NFC-e UNIFICADA E SIMPLIFICADA ---
const openNfceDialog = async (item: any, withName = true) => {
    nfceModal.orderId = item.id;
    nfceModal.orderNumber = item.order_number;

    // RESETAR PORCENTAGEM
    nfcePercentage.value = 100;
    nfceOriginalItems.value = [];

    if (!activeNfceCompany.value) {
        if(companies.value.length > 0) activeNfceCompany.value = companies.value[0];
        else {
            appStore.showSnackbar("Erro: Nenhuma empresa emissora configurada.", "error");
            return;
        }
    }
    nfceForm.cpf = '';
    nfceForm.nome = '';
    nfceForm.itens = [];
    nfceForm.pagamento = { forma: '01', meio: '01', valor: 0 };

    if (withName) {
        nfceForm.nome = item.customer_name || '';
        const { data: c } = await supabase.from('customers_mj').select('cpf').eq('nome', item.customer_name).limit(1).maybeSingle();
        if(c?.cpf) nfceForm.cpf = c.cpf;
    }

    try {
        const { data: items } = await supabase.from('order_items').select('*').eq('order_id', item.id);
        const { data: stockData } = await supabase.from('stock').select('fabric_type, ncm');

        if (items) {
            nfceForm.itens = items.map((i: any) => {
                const stockMatch = (stockData || []).find((p: any) => p.fabric_type === i.fabric_type);
                return {
                    descricao: i.fabric_type || 'Produto Diverso',
                    ncm: stockMatch?.ncm || '61091000',
                    cfop: '5102',
                    quantidade: i.quantity_meters || 1,
                    valor_unitario: Number(i.total_value_items) / (i.quantity_meters || 1)
                };
            });
            // SALVA A CÓPIA INTACTA PARA CÁLCULO DE PORCENTAGEM
            nfceOriginalItems.value = JSON.parse(JSON.stringify(nfceForm.itens));
        }
        nfceModal.show = true;
    } catch(e) { console.error(e); appStore.showSnackbar("Erro ao carregar itens.", "error"); }
};

const addNfceItem = () => {
    const newItem = { descricao: '', ncm: '', cfop: '5102', quantidade: 1, valor_unitario: 0 };
    nfceForm.itens.push({...newItem});
    nfceOriginalItems.value.push({...newItem});
};
const removeNfceItem = (i: number) => {
    nfceForm.itens.splice(i, 1);
    nfceOriginalItems.value.splice(i, 1);
};

const submitNFCe = async () => {
    if (!activeNfceCompany.value) return appStore.showSnackbar("Empresa não selecionada.", "error");
    if (nfceForm.itens.length === 0) return appStore.showSnackbar("Adicione itens.", "warning");

    nfceModal.loading = true;

    try {
        const { data: companyData } = await supabase
            .from('companies')
            .select('nfce_next_number, nfce_series, nfe_environment, crt')
            .eq('id', activeNfceCompany.value.id)
            .single();

        if (companyData) {
            activeNfceCompany.value.nfce_next_number = companyData.nfce_next_number;
            activeNfceCompany.value.nfce_series = companyData.nfce_series;
            activeNfceCompany.value.crt = companyData.crt;
        }

        const cleanDoc = nfceForm.cpf.replace(/\D/g, '');
        const emitenteCnpjLimpo = activeNfceCompany.value.cnpj.replace(/\D/g, '');

        let destinatarioPayload = null;
        if (cleanDoc || nfceForm.nome) {
            destinatarioPayload = {
                cnpj_cpf: cleanDoc,
                nome: nfceForm.nome,
                indIEDest: 9
            };
        }

        const payload = {
            ambiente: selectedNfceEnvironment.value,
            serie: activeNfceCompany.value.nfce_series || 1,
            numero: (activeNfceCompany.value.nfce_next_number || 1),
            crt: activeNfceCompany.value.crt || 1,
            destinatario: destinatarioPayload,
            itens: nfceForm.itens.map((i, idx) => ({
                ...i,
                codigo_produto: `ITEM${idx+1}`,
                ncm: i.ncm.replace(/\D/g, ''),
                cfop: i.cfop.replace(/\D/g, '')
            })),
            pagamentos: [{
                forma_pagamento: nfceForm.pagamento.forma,
                valor: nfceTotalValue.value
            }],
            valor_total: nfceTotalValue.value,
            referencia: `PDV-${nfceModal.orderNumber}-${Date.now()}`
           };

        let result;
        try {
            result = await sefazService.emitirNFCe(payload, activeNfceCompany.value.cnpj, activeNfceCompany.value.ie);
        } catch (apiErr: any) {
            const msg = apiErr.message || '';
            const details = apiErr.response?.data || apiErr.details || apiErr;
            if (msg.includes('Autorizado') || details?.status === 'autorizado') {
                result = details;
            } else {
                throw apiErr;
            }
        }

        const statusFinal = result.status_sefaz || result.status;
        const isAuthorized = (statusFinal === 'autorizado' || statusFinal === 'AUTORIZADA');
        const idNota = result.id || result.id_nuvem;

        let pdfUrl = '';
        if (idNota) {
            pdfUrl = sefazService.getProxyNfceDownloadUrl('pdf', idNota);
        }

        await supabase.from('nfce_outbound').insert({
            emitente_cnpj: emitenteCnpjLimpo,
            numero: result.numero || payload.numero,
            valor_total: nfceTotalValue.value,
            status: isAuthorized ? 'AUTORIZADA' : 'REJEITADA',
            chave: result.chave || result.autorizacao?.chave_acesso,
            pdf_link: pdfUrl,
            ambiente: payload.ambiente,
            destinatario_nome: nfceForm.nome || 'Consumidor Final',
            retorno_sefaz: result
        });

        if (!isAuthorized) {
            nfceErrorDialog.message = result.motivo || result.message || 'Erro na emissão';
            nfceErrorDialog.details = result;
            nfceErrorDialog.show = true;
            return;
        }

        appStore.showSnackbar(`NFC-e ${result.numero || payload.numero} emitida!`, 'success');

        const nextNum = Number(result.numero || payload.numero) + 1;
        await supabase.from('companies').update({ nfce_next_number: nextNum }).eq('id', activeNfceCompany.value.id);
        activeNfceCompany.value.nfce_next_number = nextNum;

        if (nfceModal.orderId) {
            await supabase.from('orders').update({
                nfe_number: String(result.numero || payload.numero),
                financial_status: 'Faturado',
                nfe_key: result.chave || result.autorizacao?.chave_acesso
            }).eq('id', nfceModal.orderId);
        }

        const localOrder = orders.value.find(o => o.id === nfceModal.orderId);
            if (localOrder) {
                localOrder.financial_status = 'Faturado';
                localOrder.nfe_number = String(result.numero || payload.numero);
                localOrder.nfe_key = result.chave || result.autorizacao?.chave_acesso;
                localOrder.fiscal_doc = {
                    found: true,
                    type: 'NFCe',
                    key: result.chave || result.autorizacao?.chave_acesso,
                    pdf: pdfUrl,
                    nuvem_id: idNota
                };
            }

        nfceModal.show = false;
        fetchOrders();

        if (pdfUrl) {
            window.open(pdfUrl, '_blank');
        } else {
            appStore.showSnackbar("Nota autorizada, mas ID para download não encontrado.", "warning");
        }

    } catch (e: any) {
        console.error("Erro CRÍTICO NFCe:", e);
        const errorMsg = e.message || "Erro desconhecido";
        const errorDetails = e.response?.data || e;
        nfceErrorDialog.title = 'Falha na Emissão';
        nfceErrorDialog.message = errorMsg;
        nfceErrorDialog.details = errorDetails;
        nfceErrorDialog.show = true;
    } finally {
        nfceModal.loading = false;
    }
};

// --- NFE STATE (Mantido original simplificado) ---
const nfeModalState = reactive({
    show: false,
    orderId: null as string | null
});

const openNfeModal = (item: any) => {
    nfeModalState.orderId = item.id;
    nfeModalState.show = true;
};
const saveDraft = async () => {
    nfeModal.savingDraft = true;
    addLog('INFO', 'Salvando rascunho...');
    try {
        const payloadToSave = { ...JSON.parse(JSON.stringify(nfeForm)), orderId: nfeModal.orderId };
        const dbPayload = { emitente_cnpj: activeCompany.value?.cnpj, destinatario_nome: nfeForm.destinatario.nome || 'Rascunho', valor_total: nfeTotalValue.value, status: 'RASCUNHO', retorno_sefaz: { payload: payloadToSave } };
        const { data: existing } = await supabase.from('nfe_outbound').select('id').eq('status', 'RASCUNHO').contains('retorno_sefaz', { payload: { orderId: nfeModal.orderId } }).maybeSingle();
        if (existing) { await supabase.from('nfe_outbound').update(dbPayload).eq('id', existing.id); addLog('SUCCESS', 'Rascunho atualizado'); } else { await supabase.from('nfe_outbound').insert(dbPayload); addLog('SUCCESS', 'Rascunho criado'); }
        appStore.showSnackbar('Rascunho salvo com sucesso.', 'success');
    } catch(e: any) { addLog('ERROR', 'Erro ao salvar rascunho', e.message); appStore.showSnackbar('Erro ao salvar rascunho: ' + e.message, 'error'); } finally { nfeModal.savingDraft = false; }
};
const addItemToNfe = () => nfeForm.itens.push({ descricao: '', quantidade: 1, valor: 0 });
const removeItemFromNfe = (i: number) => nfeForm.itens.splice(i, 1);
const generatePreview = async () => {
    previewLoading.value = true;
    addLog('INFO', 'Gerando preview DANFE...');
    try {
        const pdfDoc = new jsPDF();
        pdfDoc.text("PREVIEW SIMPLIFICADO NFE", 10, 10);
        pdfDoc.text(`Destinatário: ${nfeForm.destinatario.nome}`, 10, 20);
        pdfDoc.text(`Valor Total: ${formatCurrency(nfeTotalValue.value)}`, 10, 30);
        nfeForm.itens.forEach((item: any, i: number) => {
            pdfDoc.text(`${item.descricao} - Qtd: ${item.quantidade} - Valor: ${item.valor_unitario}`, 10, 40 + (i*10));
        });
        const blob = pdfDoc.output('blob');
        if (previewUrl.value) URL.revokeObjectURL(previewUrl.value);
        previewUrl.value = URL.createObjectURL(blob);
        addLog('SUCCESS', 'Preview gerado com sucesso');
    } catch (e: any) { addLog('ERROR', 'Erro ao gerar preview', e.message); appStore.showSnackbar('Erro ao gerar preview: ' + e.message, 'error'); } finally { previewLoading.value = false; }
};
const confirmEmission = async () => {
    nfeModal.errorMessages = [];
    if (!isFormValid.value) return appStore.showSnackbar("Verifique as pendências no checklist.", "error");
    nfeModal.loading = true;
    addLog('INFO', 'Iniciando processo de emissão...');
    try {
        const numeroNota = nextNfeNumber.value;
        const payload = {
            natureza_operacao: nfeForm.natureza_operacao,
            destinatario: { ...nfeForm.destinatario, cnpj_cpf: cleanDigits(nfeForm.destinatario.cnpj_cpf), endereco: { ...nfeForm.destinatario.endereco, cep: cleanDigits(nfeForm.destinatario.endereco.cep) } },
            itens: nfeForm.itens.map(i => ({ ...i, ncm: cleanDigits(i.ncm), cfop: cleanDigits(i.cfop), quantidade: Number(i.quantidade), valor_unitario: Number(i.valor_unitario) })),
            pagamentos: [{ meio_pagamento: nfeForm.pagamento.meio, valor: nfeTotalValue.value, forma_pagamento: nfeForm.pagamento.forma }],
            ambiente: activeCompany.value.nfe_environment || 'homologacao',
            serie: activeCompany.value.nfe_series || 1,
            numero: numeroNota,
            informacoes_adicionais: `${nfeForm.obs || ''} ${activeCompany.value.nfe_info_complementar || ''}`.trim()
        };
        addLog('API', 'Enviando payload para SEFAZ', payload);
        if (nfeType.value === 'fiscal') {
            const result = await sefazService.emitirNFe(payload, activeCompany.value.cnpj, activeCompany.value.ie);
            const isSuccess = result.status === 'autorizado' || result.status === 'success';
            addLog(isSuccess ? 'SUCCESS' : 'ERROR', `Retorno SEFAZ: ${result.status}`, result);
            const dbPayload = { emitente_cnpj: activeCompany.value.cnpj, destinatario_nome: nfeForm.destinatario.nome, valor_total: nfeTotalValue.value, status: isSuccess ? 'AUTORIZADA' : 'REJEITADA', chave: result.chave, numero: result.numero, xml_link: result.xml_url, pdf_link: result.pdf_url, retorno_sefaz: { ...result, payload: { ...payload, orderId: nfeModal.orderId } } };
            await supabase.from('nfe_outbound').insert(dbPayload);
            if (isSuccess) {
                const newSeq = parseInt(String(numeroNota)) + 1;
                await supabase.from('companies').update({ nfe_next_number: newSeq }).eq('id', activeCompany.value.id);
                activeCompany.value.nfe_next_number = newSeq;
                if (nfeModal.orderId) await supabase.from('orders').update({ nfe_number: result.numero, nfe_key: result.chave, financial_status: 'Faturado' }).eq('id', nfeModal.orderId);
                appStore.showSnackbar(`NFe ${result.numero} Autorizada!`, "success");
                nfeModal.show = false;
                fetchOrders();
            } else throw new Error('SEFAZ não autorizou.');
        } else {
            if (nfeModal.orderId) await supabase.from('orders').update({ financial_status: 'Faturado' }).eq('id', nfeModal.orderId);
            appStore.showSnackbar("Recibo gerado.", "success");
            addLog('SUCCESS', 'Recibo gerado localmente');
            nfeModal.show = false;
            fetchOrders();
        }
    } catch (e: any) {
        console.error("Erro Emissão:", e);
        let errorList = [];
        if (e.response?.data?.details?.error?.errors) errorList = e.response.data.details.error.errors.map((err: any) => `${err.code||''}: ${err.message}`);
        else errorList.push(e.message || "Erro desconhecido.");
        nfeModal.errorMessages = errorList;
        addLog('ERROR', 'Falha na emissão', errorList);
        appStore.showSnackbar("Falha na emissão. Veja os logs.", "error");
        showLogs.value = true;
    } finally { nfeModal.loading = false; }
};

const periodOptions = [
    { label: 'Hoje', value: 'today' },
    { label: 'Esta Semana', value: 'week' },
    { label: 'Este Mês', value: 'month' },
    { label: 'Este Ano', value: 'year' },
    { label: 'Todos', value: 'all' }
];

const showLogs = ref(false);
const systemLogs = ref<any[]>([]);
const addLog = (type: 'INFO' | 'SUCCESS' | 'ERROR' | 'API', message: string, details?: any) => {
    systemLogs.value.unshift({ time: new Date().toLocaleTimeString(), type, message, details: details ? JSON.stringify(details, null, 2) : null });
};

const nfeTotalValue = computed(() => {
    if (!nfeForm.itens) return 0;
    return nfeForm.itens.reduce((acc: number, item: any) => acc + (item.quantidade * item.valor_unitario), 0);
});

watch(() => activeCompany.value, async (newVal) => {
    if(newVal) {
        addLog('INFO', `Empresa alterada para: ${newVal.name}`);
        await updateNextNumberDisplay();
    }
}, { deep: true });

const nextNfeNumber = ref(0);
const nfeType = ref('fiscal');

const fetchProductOptions = async () => {};
const loadCompanies = async () => {
   try {
      let nuvemCompanies = [];
      try {
          const nuvemResponse = await sefazService.listarEmpresas();
          nuvemCompanies = nuvemResponse.data || (Array.isArray(nuvemResponse) ? nuvemResponse : []);
      } catch (err: any) {
          console.warn("Backend Local offline (ERR_NETWORK), carregando fallback do banco.");
      }

      const { data: dbCompanies } = await supabase.from('companies').select('*');

      if (nuvemCompanies.length === 0) {
          companies.value = (dbCompanies || []).map(c => ({
              ...c,
              nfe_environment: c.nfe_environment || 'homologacao',
              nfe_series: c.nfe_series || 1,
              nfce_series: c.nfce_series || 1,
              nfe_next_number: parseInt(c.nfe_next_number) || 0,
              nfce_next_number: parseInt(c.nfce_next_number) || 1
          }));
      } else {
          companies.value = nuvemCompanies.map((nc: any) => {
              const dbConfig = (dbCompanies || []).find((dbc: any) => dbc.cnpj.replace(/\D/g, '') === nc.cnpj.replace(/\D/g, ''));
              return {
                  ...nc,
                  id: dbConfig?.id || nc.id,
                  nfe_environment: dbConfig?.nfe_environment || 'homologacao',
                  nfe_series: dbConfig?.nfe_series || 1,
                  nfe_next_number: parseInt(dbConfig?.nfe_next_number) || 0,
                  nfe_info_complementar: dbConfig?.nfe_info_complementar || '',
                  ie: dbConfig?.ie || nc.inscricao_estadual,
                  nfce_next_number: parseInt(dbConfig?.nfce_next_number) || 1,
                  nfce_series: dbConfig?.nfce_series || 1,
              };
          });
      }

      if (companies.value.length > 0 && !activeCompany.value) {
          activeCompany.value = companies.value[0];
          await updateNextNumberDisplay();
      }
   } catch (e: any) {
       addLog('ERROR', 'Erro crítico ao carregar empresas', e.message);
   }
};

const updateNextNumberDisplay = async () => {
    if(!activeCompany.value) return;
    let configNum = Number(activeCompany.value.nfe_next_number) || 0;
    const { data } = await supabase.from('nfe_outbound').select('numero').eq('emitente_cnpj', activeCompany.value.cnpj).eq('status', 'AUTORIZADA').order('numero', { ascending: false }).limit(1).maybeSingle();
    const lastUsed = data?.numero ? Number(data.numero) : 0;
    nextNfeNumber.value = Math.max(configNum, lastUsed + 1);
};

const currentPeriodLabel = computed(() => periodOptions.find(p => p.value === currentPeriod.value)?.label || 'Período');

const validationChecklist = computed(() => {
    const list = [
        { title: 'Emitente', valid: !!activeCompany.value },
        { title: 'Destinatário', valid: true },
        { title: 'Produtos', valid: true },
    ];
    const d = nfeForm.destinatario;
    let destValid = !!d.nome;
    if (nfeType.value === 'fiscal') {
        destValid = destValid && !!d.cnpj_cpf && !!d.endereco.logradouro && !!d.endereco.municipio && !!d.endereco.uf;
    }
    list[1].valid = destValid;
    let itemValid = nfeForm.itens.length > 0;
    nfeForm.itens.forEach((item) => {
        if (!item.descricao || item.quantidade <= 0) itemValid = false;
        if (nfeType.value === 'fiscal' && (!item.ncm || !item.cfop)) itemValid = false;
    });
    list[2].valid = itemValid;
    return list;
});
const isFormValid = computed(() => validationChecklist.value.every(i => i.valid));

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

const printOrder = async (row: any) => {
  try {
    const orderId = row?.id;
    if (!orderId) { appStore.showSnackbar("Pedido inválido para impressão.", "error"); return; }

    const brDate = (d: any) => { if (!d) return ""; try { const iso = String(d); const date = iso.includes("T") ? parseISO(iso) : parseISO(`${iso}T00:00:00`); return format(date, "dd/MM/yyyy"); } catch { return String(d); } };
    const money = (val: number) => new Intl.NumberFormat("pt-BR", { style: "currency", currency: "BRL" }).format(Number(val || 0));
    const num = (val: number) => new Intl.NumberFormat("pt-BR", { minimumFractionDigits: 2, maximumFractionDigits: 2 }).format(Number(val || 0));

    const [ { data: order }, { data: items }, { data: receivables }, { data: stockRows }, { data: paymentMethods } ] = await Promise.all([
      supabase.from("orders").select("*, customers_mj(*), creator:created_by(full_name)").eq("id", orderId).maybeSingle(),
      supabase.from("order_items").select("*").eq("order_id", orderId).order("created_at", { ascending: true }),
      supabase.from("finance_receivables").select("*").eq("order_id", orderId).order("due_date", { ascending: true }),
      supabase.from("stock").select("fabric_type, gestao_click_id, ncm"),
      supabase.from("finance_payment_methods").select("id, name")
    ]);

    if (!order) { appStore.showSnackbar("Não foi possível carregar o pedido.", "error"); return; }

    const stockMap = new Map<string, any>((stockRows || []).map((s: any) => [String(s.fabric_type || "").trim().toLowerCase(), s]));
    const paymentMap = new Map<string, string>((paymentMethods || []).map((p: any) => [p.id, p.name]));

    const c = (order.customer || order.customers_mj || {});
    const clienteNome = String(c.nome || c.razao_social || c.nome_fantasia || order.customer_name || "").trim() || "—";
    const addressLine = [ String(c.endereco || "").trim(), c.numero ? `, ${c.numero}` : "", c.bairro ? ` - ${c.bairro}` : "" ].join("").trim();
    const cep = String(c.cep || "").trim();
    const cidade = String(c.cidade || "").trim();
    const estado = String(c.estado || "").trim();
    const telefone = String(c.telefone || c.celular || "").trim();
    const email = String(c.email || "").trim();

    const productsBody = (items || []).map((it: any, idx: number) => {
      const fabricRaw = String(it.fabric_type || "").trim();
      const stockData = stockMap.get(fabricRaw.toLowerCase());
      const codigoTecido = String(it.gestao_click_product_id || "").trim() || String(stockData?.gestao_click_id || "").trim() || "—";
      const referencia = String(it.stamp_ref || "").trim() || "—";
      const notes = String(it.notes || "").trim();
      const nomeLinha = notes ? `${fabricRaw} (Obs: ${notes})` : fabricRaw || "PRODUTO";

      const rawQtd = (it.quantity_unit && Number(it.quantity_unit) > 0) ? it.quantity_unit : it.quantity_meters;
      const qtd = Number(rawQtd || 0);

      const subtotal = Number(it.total_value_items || 0);
      const unit = qtd > 0 ? subtotal / qtd : 0;
      const und = String(it.unit_of_measure || (it.quantity_unit ? "KG" : "MT")).toUpperCase();

      return [ String(idx + 1), codigoTecido, referencia, nomeLinha, und, num(qtd), num(unit), num(subtotal) ];
    });

    const totalProdutos = (items || []).reduce((acc: number, it: any) => acc + Number(it.total_value_items || 0), 0);
    const totalQtd = (items || []).reduce((acc: number, it: any) => {
       const q = (it.quantity_unit && Number(it.quantity_unit) > 0) ? it.quantity_unit : it.quantity_meters;
       return acc + Number(q || 0);
    }, 0);

    let finalReceivables = [...(receivables || [])];
    const orderTotal = Number(order.total_value || 0);
    const dbTotal = finalReceivables.reduce((acc, r) => acc + Number(r.value || 0), 0);

    if (orderTotal - dbTotal > 0.05) {
        const schedule = order.details?.installments_schedule || [];
        const dbPool = [...finalReceivables];

        schedule.forEach((sch: any) => {
            const matchIdx = dbPool.findIndex(r => Math.abs(Number(r.value) - Number(sch.value)) < 0.1);
            if (matchIdx !== -1) {
                dbPool.splice(matchIdx, 1);
            } else {
                finalReceivables.push({
                    due_date: sch.due_date,
                    value: sch.value,
                    payment_method_id: sch.payment_method_id,
                    description: sch.description || 'Parcela (Prevista)',
                    is_virtual: true
                });
            }
        });
        finalReceivables.sort((a, b) => new Date(a.due_date).getTime() - new Date(b.due_date).getTime());
    }

    const payRows = finalReceivables.map((r: any) => {
      const venc = brDate(r.due_date);
      const val = Number(r.value || 0);
      let nomeForma = "—";
      if (r.payment_method_id && paymentMap.has(r.payment_method_id)) { nomeForma = paymentMap.get(r.payment_method_id)!; } else if (r.payment_method) { nomeForma = String(r.payment_method); }
      const obs = String(r.description || r.notes || "").trim() || "Parcela referente ao pedido.";
      return [venc, num(val), nomeForma, obs];
    });

    const doc = new jsPDF({ orientation: "p", unit: "mm", format: "a4" });
    const pageW = doc.internal.pageSize.getWidth();
    const pageH = doc.internal.pageSize.getHeight();
    const M = 10;
    const boxW = pageW - M * 2;

    const COMPANY = { name: "CONFECCOES MJ", cnpj: "53.756.096/0001-89", address: "RUA LUIZ MONTANHAN, 1302 (BARRACÃO TERRA NOVA)", city: "Tietê/SP - CEP: 18530-000", phones: "(15) 9789-0653 - (15) 99763-7941", email: "mrjackyfinanceiro@gmail.com", seller: `Vendedor: ${order.creator?.full_name || "Sistema"}`, logoUrl: "https://cdn.shopify.com/s/files/1/0661/4574/6991/files/Sem_nome_1080_x_800_px_1080_x_500_px_1080_x_400_px_1000_x_380_px_da020cf2-2bb9-4dac-8dd3-4548cfd2e5ae.png?v=1756811713" };
    const topY = 10;
    const headerH = 26;
    doc.setDrawColor(180); doc.setLineWidth(0.3); doc.rect(M, topY, boxW, headerH);
    try { const logoBase64 = await imageToBase64(COMPANY.logoUrl); doc.addImage(logoBase64, "PNG", M + 3, topY + 4, 30, 16); } catch (e) { /* ignore */ }
    doc.setFont("helvetica", "bold"); doc.setFontSize(11); doc.text(COMPANY.name, M + 38, topY + 9);
    doc.setFont("helvetica", "normal"); doc.setFontSize(8.5);
    doc.text(`CNPJ: ${COMPANY.cnpj}`, M + 38, topY + 14); doc.text(COMPANY.address, M + 38, topY + 18); doc.text(COMPANY.city, M + 38, topY + 22);
    const rightX = pageW - M;
    doc.text(COMPANY.phones, rightX, topY + 9, { align: "right" }); doc.text(COMPANY.email, rightX, topY + 14, { align: "right" }); doc.text(COMPANY.seller, rightX, topY + 19, { align: "right" });

    const barY = topY + headerH + 6;
    const barH = 8;
    doc.setFillColor(230); doc.rect(M, barY, boxW, barH, "F"); doc.setDrawColor(180); doc.rect(M, barY, boxW, barH);
    doc.setFont("helvetica", "bold"); doc.setFontSize(11);
    const orderNum = String(order.order_number ?? "").trim();
    doc.text(`PEDIDO N° ${orderNum || "—"}`, pageW / 2, barY + 5.5, { align: "center" });
    const issueDate = order.created_at ? brDate(order.created_at) : brDate(new Date().toISOString());
    doc.setFontSize(10); doc.text(issueDate, pageW - M - 2, barY + 5.5, { align: "right" });

    const clientBoxY = barY + barH + 6;
    doc.setFont("helvetica", "bold"); doc.setFontSize(9.5);
    doc.setFillColor(230); doc.rect(M, clientBoxY, boxW, 7, "F"); doc.setDrawColor(180); doc.rect(M, clientBoxY, boxW, 7);
    doc.text("DADOS DO CLIENTE", M + 2, clientBoxY + 5);
    const clientRows = [ ["Cliente:", clienteNome, "CNPJ/CPF:", c.cnpj || c.cpf || "—"], ["Endereço:", addressLine || "—", "CEP:", cep || "—"], ["Cidade:", cidade || "—", "Estado:", estado || "—"], ["Telefone:", telefone || "—", "E-mail:", email || "—"] ];
    autoTable(doc, { startY: clientBoxY + 7, theme: "grid", tableWidth: boxW, margin: { left: M, right: M }, styles: { fontSize: 8.5, cellPadding: 1.5, textColor: 0, lineColor: [200, 200, 200], lineWidth: 0.2, minCellHeight: 7, valign: "middle" }, bodyStyles: { fillColor: [255, 255, 255] }, columnStyles: { 0: { cellWidth: 20, fontStyle: "bold" }, 1: { cellWidth: 75 }, 2: { cellWidth: 20, fontStyle: "bold" }, 3: { cellWidth: 75 } }, body: clientRows });

    let lastY = (doc as any).lastAutoTable.finalY + 5;
    const notesContent = String(order.notes || "").trim();

    if (notesContent) {
        doc.setFillColor(255, 243, 224);
        doc.setDrawColor(255, 183, 77);
        doc.setFont("helvetica", "normal");
        doc.setFontSize(8.5);
        const splitNotes = doc.splitTextToSize(notesContent, boxW - 4);
        const notesHeight = (splitNotes.length * 4) + 8;

        doc.rect(M, lastY, boxW, notesHeight, "F");
        doc.rect(M, lastY, boxW, notesHeight);

        doc.setFont("helvetica", "bold");
        doc.setTextColor(230, 81, 0);
        doc.text("OBSERVAÇÕES DO PEDIDO:", M + 2, lastY + 4);

        doc.setFont("helvetica", "normal");
        doc.setTextColor(0);
        doc.text(splitNotes, M + 2, lastY + 9);

        lastY += notesHeight + 5;
    }

    doc.setFont("helvetica", "bold");
    doc.setFontSize(9.5);
    doc.setFillColor(230);
    doc.setDrawColor(180);
    doc.rect(M, lastY, boxW, 7, "F");
    doc.rect(M, lastY, boxW, 7);
    doc.setTextColor(0);
    doc.text("PRODUTOS", M + 2, lastY + 5);

    autoTable(doc, {
        startY: lastY + 7,
        theme: "grid",
        tableWidth: boxW,
        margin: { left: M, right: M },
        headStyles: { fillColor: [245, 245, 245], textColor: 0, fontStyle: "bold", fontSize: 8.5, valign: "middle" },
        styles: { fontSize: 8.3, cellPadding: 1.5, lineColor: [200, 200, 200], lineWidth: 0.2, textColor: 0, minCellHeight: 7, valign: "middle" },
        columnStyles: { 0: { cellWidth: 9, halign: "center" }, 1: { cellWidth: 22 }, 2: { cellWidth: 25 }, 3: { cellWidth: 56 }, 4: { cellWidth: 10, halign: "center" }, 5: { cellWidth: 18, halign: "right" }, 6: { cellWidth: 23, halign: "right" }, 7: { cellWidth: 27, halign: "right" } },
        head: [["ITEM", "CÓDIGO", "REFERÊNCIA", "NOME DO PRODUTO", "UND", "QTD", "VR. UNIT", "SUBTOTAL"]],
        body: productsBody.length ? productsBody : [["—", "—", "—", "Nenhum item", "—", "0", "0,00", "0,00"]],
        foot: [["TOTAL", "", "", "", "", num(totalQtd), "", num(totalProdutos)]],
        footStyles: { fillColor: [240, 240, 240], fontStyle: "bold", halign: "right", valign: "middle" }
    });

    const afterProductsY = (doc as any).lastAutoTable.finalY + 4;
    const rightBoxW = 70;
    const rightBoxX = pageW - M - rightBoxW;
    const totalsBoxH = 14;
    doc.setFillColor(230); doc.rect(rightBoxX, afterProductsY, rightBoxW, totalsBoxH, "F"); doc.setDrawColor(180); doc.rect(rightBoxX, afterProductsY, rightBoxW, totalsBoxH);
    doc.setFont("helvetica", "bold"); doc.setFontSize(9);
    doc.text(`PRODUTOS: ${money(totalProdutos)}`, rightBoxX + rightBoxW - 2, afterProductsY + 5.5, { align: "right" });
    doc.text(`TOTAL PEDIDO: ${money(totalProdutos)}`, rightBoxX + rightBoxW - 2, afterProductsY + 11.5, { align: "right" });

    const afterTotalsY = afterProductsY + totalsBoxH + 6;
    doc.setFont("helvetica", "bold"); doc.setFontSize(9.5);
    doc.setFillColor(230); doc.rect(M, afterTotalsY, boxW, 7, "F"); doc.setDrawColor(180); doc.rect(M, afterTotalsY, boxW, 7);
    doc.text("FINANCEIRO / PARCELAS", M + 2, afterTotalsY + 5);

    autoTable(doc, { startY: afterTotalsY + 7, theme: "grid", tableWidth: boxW, margin: { left: M, right: M }, headStyles: { fillColor: [245, 245, 245], textColor: 0, fontStyle: "bold", fontSize: 8.5, valign: "middle" }, styles: { fontSize: 8.3, cellPadding: 1.5, lineColor: [200, 200, 200], lineWidth: 0.2, textColor: 0, minCellHeight: 7, valign: "middle" }, columnStyles: { 0: { cellWidth: 30, halign: "center" }, 1: { cellWidth: 35, halign: "right" }, 2: { cellWidth: 40 }, 3: { cellWidth: 85 } }, head: [["VENCIMENTO", "VALOR", "FORMA PAGTO", "OBSERVAÇÃO"]], body: payRows.length ? payRows : [["—", "0,00", "—", "Sem lançamentos."]] });

    const afterPayY = (doc as any).lastAutoTable.finalY + 10;
    const signH = 18;
    let signY = afterPayY;
    if (signY + signH > pageH - M) { doc.addPage(); signY = M + 10; }
    doc.setDrawColor(0); doc.setLineWidth(0.3); doc.rect(M, signY, boxW, signH);
    doc.setDrawColor(120); doc.line(M + 50, signY + 12, M + boxW - 50, signY + 12);
    doc.setFont("helvetica", "normal"); doc.setFontSize(8); doc.text("Assinatura do responsável / cliente", pageW / 2, signY + 16, { align: "center" });

    const totalPages = doc.getNumberOfPages();
    for (let i = 1; i <= totalPages; i++) { doc.setPage(i); doc.setFontSize(7); doc.setTextColor(150); doc.text("Gerado com MJProcess", pageW - M, pageH - 5, { align: "right" }); }

    doc.save(`Pedido_${orderNum || orderId}.pdf`);
    appStore.showSnackbar("PDF gerado com sucesso.", "success");
  } catch (e: any) { console.error("printOrder error:", e); appStore.showSnackbar(`Erro ao gerar PDF: ${e?.message || e}`, "error"); }
};

const generateOrderReport = async (mode: 'full' | 'production' = 'full') => {
  generatingPdf.value = true;
  try {
    await fetchOrders();

    const doc = new jsPDF({ orientation: 'p', unit: 'mm', format: 'a4' });
    const pageWidth = doc.internal.pageSize.width;
    const pageHeight = doc.internal.pageSize.height;

    try {
      const logoUrl = 'https://cdn.shopify.com/s/files/1/0661/4574/6991/files/Sem_nome_1080_x_800_px_1080_x_500_px_1080_x_400_px_1000_x_380_px_da020cf2-2bb9-4dac-8dd3-4548cfd2e5ae.png?v=1756811713';
      const logoBase64 = await imageToBase64(logoUrl);
      const props = doc.getImageProperties(logoBase64);
      const h = (props.height * 45) / props.width;
      doc.addImage(logoBase64, 'PNG', 15, 10, 45, h);
    } catch (e) {
      console.error("Logo Error", e);
    }

    doc.setFontSize(8).setTextColor(50);
    const headerText = [
      "MR JACKY CONFECCOES LTDA",
      "CNPJ: 20.631.721/0001-07",
      "Rua Luiz Montanhan, 1302 - Tiete/SP",
      "Contato: (15) 99847-8789 | financeiro@mrjacky.com"
    ];
    doc.text(headerText, pageWidth - 15, 15, { align: 'right' });

    doc.setDrawColor(200, 200, 200);
    doc.line(15, 30, pageWidth - 15, 30);

    doc.setFontSize(14).setFont('helvetica', 'bold').setTextColor(0);
    const title = mode === 'production' ? 'Relatório de Produção' : 'Relatório Financeiro de Pedidos';
    doc.text(title, 15, 40);

    doc.setFontSize(9).setFont('helvetica', 'normal').setTextColor(100);
    const filterName = statusFilters.find(f => f.value === (filterFinancialStatus.value || 'all'))?.label || 'Todos';
    doc.text(`Filtro: ${filterName} | Período: ${currentPeriodLabel.value}`, 15, 45);

    let tableStartY = 55;

    if (mode === 'full') {
      const totalMeters = filteredOrders.value.reduce((acc, o) => acc + (Number(o.quantity_meters) || 0), 0);
      const totalValue = filteredOrders.value.reduce((acc, o) => acc + (Number(o.total_value) || 0), 0);

      const uniqueMonths = new Set(filteredOrders.value.map(o => {
          if (!o.created_at) return '';
          const date = parseISO(o.created_at);
          const monthName = new Intl.DateTimeFormat('pt-BR', { month: 'long', year: 'numeric' }).format(date);
          return monthName.charAt(0).toUpperCase() + monthName.slice(1);
      }).filter(Boolean));
      const monthsCovered = Array.from(uniqueMonths).join(', ') || 'Nenhum';

      const uniqueSellers = Array.from(new Set(filteredOrders.value.map(o => o.creator?.full_name).filter(Boolean)));
      const sellerCovered = uniqueSellers.length === 1 ? uniqueSellers[0] : (uniqueSellers.length > 1 ? 'Múltiplos Vendedores' : 'N/A');

      doc.setFillColor(248, 249, 250);
      doc.setDrawColor(220, 220, 220);
      doc.roundedRect(15, 50, pageWidth - 30, 22, 3, 3, 'FD');

      doc.setFontSize(8).setFont('helvetica', 'normal').setTextColor(100);
      doc.text(`Vendedor(a):`, 20, 58);
      doc.setFontSize(10).setFont('helvetica', 'bold').setTextColor(40);
      doc.text(sellerCovered.length > 20 ? sellerCovered.substring(0, 20) + '...' : sellerCovered, 20, 64);

      doc.setFontSize(8).setFont('helvetica', 'normal').setTextColor(100);
      doc.text(`Meses Abordados:`, 75, 58);
      doc.setFontSize(11).setFont('helvetica', 'bold').setTextColor(25, 118, 210);
      const splitMonths = doc.splitTextToSize(monthsCovered, 55);
      doc.text(splitMonths[0] + (splitMonths.length > 1 ? '...' : ''), 75, 64);

      doc.setFontSize(8).setFont('helvetica', 'normal').setTextColor(100);
      doc.text(`Total Metragem:`, 135, 58);
      doc.setFontSize(10).setFont('helvetica', 'bold').setTextColor(40);
      doc.text(`${formatNumber(totalMeters)}m`, 135, 64);

      doc.setFontSize(8).setFont('helvetica', 'normal').setTextColor(100);
      doc.text(`Total Valor:`, 170, 58);
      doc.setFontSize(11).setFont('helvetica', 'bold').setTextColor(46, 125, 50);
      doc.text(`${formatCurrency(totalValue)}`, 170, 64);

      tableStartY = 80;
    }

    const openStatuses = ['production_queue', 'in_production', 'design_pending', 'customer_approval', 'in_queue'];

    let columns = [
      { header: 'Pedido', dataKey: 'id' },
      { header: 'Emissão', dataKey: 'date' },
      { header: 'Cliente', dataKey: 'client' },
      { header: 'Metros', dataKey: 'meters' },
      { header: 'Entrega', dataKey: 'delivery' },
      { header: 'Status', dataKey: 'status' }
    ];

    if (mode === 'full') {
      columns.push({ header: 'Valor', dataKey: 'value' });
    }

    const tableBody = filteredOrders.value.map(order => {
      const isReallyOpen = openStatuses.includes(order.status);
      const statusText = isReallyOpen ? "EM ABERTO" : formatStatus(order.status);

      let statusColor = [50, 50, 50];
      let statusBg = null;

      if (isReallyOpen) {
          statusBg = [255, 152, 0];
          statusColor = [255, 255, 255];
      } else if (order.status === 'delivered' || order.status === 'completed') {
          statusBg = [76, 175, 80];
          statusColor = [255, 255, 255];
      } else if (order.status === 'ready_for_delivery') {
          statusBg = [33, 150, 243];
          statusColor = [255, 255, 255];
      } else if (order.status === 'cancelled') {
          statusBg = [244, 67, 54];
          statusColor = [255, 255, 255];
      }

      let rowColor = [255, 255, 255];
      if (order.delivery_date_obj && isReallyOpen) {
        const delDate = new Date(order.delivery_date_obj);
        const now = new Date();
        if (isSameDay(delDate, now)) {
          rowColor = [255, 224, 178];
        } else if (isBefore(delDate, startOfToday())) {
          rowColor = [255, 205, 210];
        } else {
          rowColor = [245, 245, 245];
        }
      }

      return {
        id: `#${String(order.order_number).padStart(4, '0')}`,
        date: formatDate(order.created_at),
        client: order.customer_name?.substring(0, 25) || 'Consumidor',
        meters: `${formatNumber(order.quantity_meters || 0)}m`,
        delivery: order.estimated_delivery || '--',
        status: { text: statusText, color: statusColor, bgColor: statusBg },
        value: formatCurrency(order.total_value),
        _rowColor: rowColor
      };
    });

    autoTable(doc, {
      startY: tableStartY,
      columns: columns,
      body: tableBody,
      theme: 'grid',
      headStyles: { fillColor: [50, 50, 50], textColor: 255, fontStyle: 'bold', fontSize: 8 },
      bodyStyles: { fontSize: 8, textColor: 50, cellPadding: 2 },
      columnStyles: {
        id: { fontStyle: 'bold', cellWidth: 18 },
        client: { cellWidth: 'auto' },
        meters: { halign: 'center', cellWidth: 15 },
        delivery: { halign: 'center', cellWidth: 20 },
        status: { halign: 'center', cellWidth: 30, fontStyle: 'bold' },
        value: { halign: 'right', cellWidth: 25 }
      },
      didParseCell: (data) => {
        if (data.section === 'body') {
          const row = data.row.raw as any;
          if (row._rowColor) {
            data.cell.styles.fillColor = row._rowColor as [number, number, number];
          }
          if (data.column.dataKey === 'status') {
            const cellData = row.status;
            data.cell.text = [cellData.text];
            if (cellData.bgColor) {
              data.cell.styles.fillColor = cellData.bgColor;
              data.cell.styles.textColor = cellData.color;
            }
          }
        }
      },
      didDrawPage: (data) => {
        const str = `Emitido em ${format(new Date(), 'dd/MM/yyyy HH:mm')} via MJProcess`;
        doc.setFontSize(8).setTextColor(150);
        doc.text(str, pageWidth / 2, pageHeight - 10, { align: 'center' });
        doc.text(`Pág ${doc.internal.getNumberOfPages()}`, pageWidth - 15, pageHeight - 10, { align: 'right' });
      }
    });

    doc.save(`Relatorio_${mode}.pdf`);
    appStore.showSnackbar('Relatório gerado com sucesso.', 'success');

  } catch (e: any) {
    console.error("PDF Error", e);
    appStore.showSnackbar("Erro ao gerar PDF: " + (e.message || e), "error");
  } finally {
    generatingPdf.value = false;
  }
};

// MULTI-TENANT
const computedGridTemplate = computed(() => {
    return companyStore.isGlobalView
        ? '62px 82px minmax(185px, 1.25fr) 88px 104px 70px 118px 126px 112px 78px 50px 76px 102px 142px'
        : '62px 82px minmax(210px, 1.35fr) 104px 70px 118px 126px 112px 78px 50px 76px 102px 142px';
});

const contextButtons = computed(() => {
    const btns = [];
    const comps = companyStore.availableCompanies || [];
    if (comps.length > 0) btns.push({ id: comps[0].id, name: comps[0].trade_name, isHolding: false });
    if (comps.length > 1) btns.push({ id: comps[1].id, name: comps[1].trade_name, isHolding: false });
    btns.push({ id: 'global', name: 'HOLDING / GLOBAL', isHolding: true });
    for (let i = 2; i < comps.length; i++) {
        btns.push({ id: comps[i].id, name: comps[i].trade_name, isHolding: false });
    }
    return btns;
});

const setCompanyFilter = (id: string | null) => {
    if (isSellerTenantLocked.value) return;
    companyStore.setContext(id || 'global');
};

watch(() => companyStore.context, () => {
    page.value = 1;
    fetchOrders();
});

onMounted(async () => {
    await loadCompanies();

    if (isSellerTenantLocked.value && userCompanyId.value && companyStore.context !== userCompanyId.value) {
        companyStore.setContext(userCompanyId.value);
    }

    await fetchOrders();
    fetchProductOptions();
});
</script>

<style scoped lang="scss">
/* Layout Geral */
.payables-layout { position: relative; }
.background-carousel-wrapper { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 0; opacity: 0.6; pointer-events: none; }
.background-overlay { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 1; background: radial-gradient(circle at center, rgba(15, 15, 19, 0.4), rgba(15, 15, 19, 0.98)); backdrop-filter: blur(8px); }
.z-10 { position: relative; z-index: 10; }

.bg-glass-dark { background: rgba(10,10,12,0.85); }
.bg-glass-header { background: rgba(20,20,24,0.55); backdrop-filter: blur(14px); }
.border-bottom-white-05 { border-bottom: 1px solid rgba(255,255,255,0.08); }
.border-thin { border: 1px solid rgba(0,0,0,0.08); }
.bg-white-05 { background: rgba(255,255,255,0.05); }

/* Buttons & Inputs */
.clean-input { border: none; outline: none; background: transparent; font-size: 13px; color: inherit; }

/* Controles */
.controls-bar { border: 1px solid rgba(0,0,0,0.08); border-radius: 0; padding: 10px; }
.controls-light { background: #ffffff; }
.controls-dark { background: rgba(30,30,35,0.55); backdrop-filter: blur(16px); border: 1px solid rgba(255,255,255,0.08); }

.search-wrap { height: 42px; border-radius: 0; padding: 0 12px; min-width: 360px; max-width: 520px; flex: 1 1 360px; }
@media (max-width: 600px) {
  .search-wrap { min-width: 100%; max-width: 100%; }
}
.search-light { background: #f4f6f8; border: 1px solid rgba(0,0,0,0.08); }
.search-dark { background: rgba(255,255,255,0.08); border: 1px solid rgba(255,255,255,0.10); }

/* ========================================================
   GRID LAYOUT CSS (Estilo Recebíveis e Pagáveis Admin)
   ======================================================== */
.glass-card { background: rgba(30, 30, 35, 0.45); backdrop-filter: blur(25px); border: 1px solid rgba(255,255,255,0.08); }
.grid-scroll { scrollbar-gutter: stable both-edges; }
.custom-scroll::-webkit-scrollbar { width: 8px; height: 8px; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.35); border-radius: 6px; }
.custom-scroll::-webkit-scrollbar-track { background: transparent; }

.grid-header, .grid-row {
    display: grid;
    align-items: stretch;
    width: 100%;
    border-bottom: 1px solid rgba(0,0,0,0.08);
    min-width: 1200px;
}

.cell {
    padding: 10px 12px;
    display: flex;
    align-items: center;
    border-right: 1px solid rgba(0,0,0,0.08);
    min-height: 56px;
    overflow: hidden;
    transition: background-color 0.2s ease;
}

.center { justify-content: center; text-align: center; }
.right { justify-content: flex-end; text-align: right; }

.grid-header .cell { min-height: 48px; font-size: 13px; font-weight: 900; text-transform: uppercase; letter-spacing: .6px; }
.header-text { font-size: 13px; font-weight: 800; text-transform: uppercase; }

/* Grid Theme Variations */
.grid-surface-light .cell { background: #f5f7fa; color: rgba(0,0,0,0.9); border-color: rgba(0,0,0,0.12); }
.grid-surface-dark .cell { background: rgba(255,255,255,0.08); color: rgba(255,255,255,0.80); border-color: rgba(255,255,255,0.10); }

.grid-row-light .cell { background: #fff; border-color: rgba(0,0,0,0.08); }
.grid-row-light:nth-child(even) .cell { background: #fafafa; }
.grid-row-light:hover .cell { background: #f7fafc !important; }

.grid-row-dark .cell { background: rgba(255,255,255,0.04); border-color: rgba(255,255,255,0.08); }
.grid-row-dark:nth-child(even) .cell { background: rgba(255,255,255,0.015); }
.grid-row-dark:hover .cell { background: rgba(255,255,255,0.07) !important; }

.sticky-head { position: sticky; top: 0; z-index: 10; box-shadow: 0 8px 16px -4px rgba(0, 0, 0, 0.12); }
.bg-glass-dark .sticky-head { box-shadow: 0 8px 20px -4px rgba(0, 0, 0, 0.4); }

/* ========================================================
   EFEITOS 3D E BOTÕES (Estilo Recebíveis)
   ======================================================== */
.btn-3d {
    border-radius: 6px !important;
    box-shadow: 0 3px 5px rgba(0,0,0,0.15), inset 0 2px 0 rgba(255,255,255,0.25) !important;
    transition: transform 0.1s ease, box-shadow 0.1s ease;
    text-transform: none !important;
    font-weight: 800;
}
.btn-3d:active {
    transform: translateY(2px);
    box-shadow: 0 1px 2px rgba(0,0,0,0.15), inset 0 1px 0 rgba(255,255,255,0.2) !important;
}

.chip-3d {
    border-radius: 6px !important;
    box-shadow: 0 3px 5px rgba(0,0,0,0.12), inset 0 1px 0 rgba(255,255,255,0.25) !important;
    text-shadow: 0 1px 2px rgba(0,0,0,0.25);
    font-weight: 900;
}

/* Utils */
.pill-ref { font-size: 13px; font-weight: 900; font-family: monospace; background: rgba(0,0,0,0.06); padding: 4px 8px; border-radius: 6px; }
.list-text-11 { font-size: 14px !important; line-height: 1.25 !important; }
.list-text-10 { font-size: 13px !important; line-height: 1.25 !important; }
.text-nano-badge { font-size: 11px !important; line-height: 1; letter-spacing: 0.5px; }

.solid-chip { display: inline-flex; align-items: center; justify-content: center; height: 26px; padding: 0 12px; border-radius: 6px; font-size: 11px; font-weight: 900; color: #fff; white-space: nowrap; text-transform: uppercase; }
.chip-success { background: #2e7d32; }
.chip-info { background: #1976d2; }
.chip-warning { background: #f57f17; }
.chip-danger { background: #c62828; }
.chip-purple { background: #7b1fa2; }
.chip-default { background: #455a64; }

/* Actions */
.actions-inline { display: flex; align-items: center; justify-content: center; gap: 8px; }
.action-btn { width: 30px !important; height: 30px !important; min-width: 30px !important; border-radius: 15% !important; color: #fff !important; }
.action-btn :deep(.v-icon) { color: #fff !important; }

.action-edit { background: #fb8c00 !important; }
.action-pay { background: #2e7d32 !important; }
.action-delete { background: #e53935 !important; }
.action-more { background: #1b5e20 !important; }

/* Status Colors */
.bg-success-transparent { background: rgba(0, 200, 83, 0.1); }
.bg-info-transparent { background: rgba(33, 150, 243, 0.1); }
.bg-warning-transparent { background: rgba(255, 202, 40, 0.1); }
.bg-error-transparent { background: rgba(255, 82, 82, 0.1); }
.border-success-glow { border: 1px solid rgba(0, 200, 83, 0.3); }
.border-info-glow { border: 1px solid rgba(33, 150, 243, 0.3); }
.border-warning-glow { border: 1px solid rgba(255, 202, 40, 0.3); }
.border-error-glow { border: 1px solid rgba(255, 82, 82, 0.3); }

/* NFE Modal Fixes */
.compact-input :deep(.v-field__input) { font-size: 13px; min-height: 36px; padding-top: 6px; padding-bottom: 6px; }
.dense-input :deep(.v-field__input) { font-size: 12px; padding: 0; min-height: 28px; }
.input-label { font-size: 11px; font-weight: 700; text-transform: uppercase; color: rgba(var(--v-theme-on-surface), 0.5); display: block; margin-bottom: 4px; }
:deep(.nfe-dialog-fixed) { overflow: hidden; }
.custom-scrollbar-dark::-webkit-scrollbar { width: 6px; }
.custom-scrollbar-dark::-webkit-scrollbar-thumb { background: #333; border-radius: 3px; }
.custom-scrollbar-dark::-webkit-scrollbar-track { background: #111; }
.absolute-center { position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%); }

/* Animation for Billing Alert */
.pulsing-alert { animation: pulse-alert 1.5s infinite; }
@keyframes pulse-alert {
    0% { transform: scale(1); opacity: 1; }
    50% { transform: scale(1.2); opacity: 0.7; }
    100% { transform: scale(1); opacity: 1; }
}

/* MOBILE CARDS LAYOUT */
.mobile-cards-wrap{ display:flex; flex-direction:column; gap:14px; }
.mobile-order-card{ position:relative; overflow:hidden; border-radius:18px; border:1px solid rgba(0,0,0,0.06); background:#fff; box-shadow: 0 10px 26px rgba(0,0,0,0.08); }
.mobile-order-card--dark{ background: rgba(24,24,30,0.70); border:1px solid rgba(255,255,255,0.08); box-shadow: 0 10px 26px rgba(0,0,0,0.45); backdrop-filter: blur(10px); }
.mobile-order-card__accent{ height:4px; width:100%; background: rgba(33,150,243,0.9); }
.accent-success{ background: rgba(76,175,80,0.95); }
.accent-primary{ background: rgba(33,150,243,0.95); }
.mobile-order-card__header{ padding:14px 14px 10px 14px; }
.mobile-order-card__id{ font-weight:900; font-size:18px; letter-spacing:-0.4px; }
.mobile-header-row{ width: 100%; }
.mobile-order-card__customer{ margin-top:6px; font-weight:900; font-size:14px; line-height:1.1; overflow: hidden; text-overflow: ellipsis; }
.clamp-2{ display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; white-space: normal; }
.mobile-order-card__meta .meta-pill{ display:flex; align-items:center; gap:6px; padding:4px 8px; border-radius:999px; border:1px solid rgba(0,0,0,0.06); background: rgba(0,0,0,0.03); }
.mobile-order-card--dark .mobile-order-card__meta .meta-pill{ border:1px solid rgba(255,255,255,0.10); background: rgba(255,255,255,0.06); }
.meta-ico{ opacity:0.9; }
.meta-text{ font-size:12px; font-weight:800; opacity:0.85; }
.mobile-order-card__total{ flex: 0 0 auto; white-space: nowrap; }
.total-label{ font-size:10px; font-weight:900; opacity:0.6; letter-spacing:0.12em; }
.total-value{ margin-top:2px; font-size:18px; font-weight:900; letter-spacing:-0.3px; }
.delivery-pill{ margin-top:8px; display:inline-flex; align-items:center; gap:8px; padding:6px 10px; border-radius:999px; border:1px solid rgba(0,0,0,0.06); background: rgba(0,0,0,0.03); }
.mobile-order-card--dark .delivery-pill{ border:1px solid rgba(255,255,255,0.10); background: rgba(255,255,255,0.06); }
.delivery-ico{ opacity:0.9; }
.delivery-date{ font-size:12px; font-weight:900; }
.delivery-badge{ font-size:10px; font-weight:900; padding:2px 8px; border-radius:999px; border:1px solid rgba(0,0,0,0.06); }
.mobile-order-card__statusrow{ margin-top:12px; display:flex; gap:10px; flex-wrap:wrap; }
.mobile-chip{ font-weight:900 !important; letter-spacing:0.02em; border-radius:12px !important; }
.mobile-chip--prod{ box-shadow: 0 8px 18px rgba(0,0,0,0.10); }
.mobile-chip--fin{ border:1px solid rgba(0,0,0,0.06); }
.mobile-chip--fiscal{ border:1px solid rgba(0,0,0,0.06); }
.mobile-chip-date{ font-weight:900 !important; border-radius:12px !important; }
.mobile-chip-date .chip-ico{ opacity:0.9; }
.chip-light{ background: rgba(0,0,0,0.04) !important; }
.chip-dark{ background: rgba(255,255,255,0.08) !important; }
.mobile-chip-alert{ font-weight:900 !important; border-radius:12px !important; }
.mobile-divider{ opacity:0.6; }
.mobile-order-card__actions{ padding:12px 12px 14px 12px; display:grid; grid-template-columns: repeat(4, 1fr); gap:10px; }
.mbtn{ border-radius:14px !important; text-transform:none !important; font-weight:900 !important; letter-spacing:0.02em; box-shadow: 0 10px 18px rgba(0,0,0,0.10); border: 1px solid rgba(0,0,0,0.06); display:flex !important; align-items:center !important; justify-content:center !important; gap:8px !important; padding:0 10px !important; transition: transform .12s ease, box-shadow .12s ease, filter .12s ease; }
.mbtn:active{ transform: scale(0.98); }
.mbtn:hover{ filter: brightness(1.03); box-shadow: 0 14px 22px rgba(0,0,0,0.14); }
.mbtn .mbtn-txt{ font-size:12px; font-weight:900; }
.mbtn .mbtn-ico{ opacity:0.95; }
.mbtn--edit{ background: linear-gradient(135deg, rgba(33,150,243,0.95), rgba(63,81,181,0.95)) !important; color:#fff !important; border: 1px solid rgba(33,150,243,0.40) !important; }
.mbtn--download{ background: linear-gradient(135deg, rgba(156,39,176,0.95), rgba(103,58,183,0.95)) !important; color:#fff !important; border: 1px solid rgba(156,39,176,0.40) !important; }
.mbtn--fiscal{ background: linear-gradient(135deg, rgba(255,87,34,0.95), rgba(255,152,0,0.95)) !important; color:#fff !important; border: 1px solid rgba(255,87,34,0.40) !important; }
.mbtn--more{ background: rgba(0,0,0,0.04) !important; color: rgba(0,0,0,0.80) !important; }
.mobile-order-card--dark .mbtn--more{ background: rgba(255,255,255,0.08) !important; color: rgba(255,255,255,0.90) !important; border: 1px solid rgba(255,255,255,0.10) !important; }
.mbtn--edit .mbtn-ico, .mbtn--download .mbtn-ico, .mbtn--fiscal .mbtn-ico{ color:#fff !important; }
.mobile-order-card--dark .mbtn{ border: 1px solid rgba(255,255,255,0.10); box-shadow: 0 10px 22px rgba(0,0,0,0.42); }

/* ===== Unificação Comercial + Faturamento: acabamento visual ===== */
.top-actions-island {
  overflow: visible !important;
  padding-bottom: 3px;
}

.order-mode-toggle {
  background: rgba(255,255,255,0.72);
  border: 1px solid rgba(148,163,184,0.22);
  overflow: hidden;
}

.unified-taskbar {
  border-radius: 18px !important;
  padding: 12px !important;
  box-shadow:
    0 14px 30px rgba(15,23,42,0.06),
    inset 0 1px 0 rgba(255,255,255,0.72);
}

.controls-dark.unified-taskbar {
  box-shadow:
    0 14px 30px rgba(0,0,0,0.22),
    inset 0 1px 0 rgba(255,255,255,0.06);
}

.action-payment-main {
  background: linear-gradient(180deg, #22c55e 0%, #16a34a 100%) !important;
  color: #fff !important;
}

.action-edit {
  background: linear-gradient(180deg, #2563eb 0%, #1d4ed8 100%) !important;
  color: #fff !important;
}

.mbtn--payment {
  background: linear-gradient(180deg, #22c55e 0%, #16a34a 100%) !important;
  color: #fff !important;
}

.grid-header {
  backdrop-filter: blur(12px);
  box-shadow: inset 0 -1px 0 rgba(148,163,184,0.18), 0 8px 18px rgba(15,23,42,0.04);
}

.grid-row {
  transition: background .16s ease, transform .16s ease, box-shadow .16s ease;
}

.grid-row:hover {
  background: rgba(99,102,241,0.055) !important;
  box-shadow: inset 3px 0 0 rgba(99,102,241,0.45);
}

.solid-chip,
.v-chip.chip-3d {
  letter-spacing: .02em;
}

@media (max-width: 960px) {
  .top-actions-island {
    width: 100%;
    justify-content: flex-start !important;
  }

  .order-mode-toggle {
    max-width: 100%;
    overflow-x: auto;
  }
}



/* Header unificado mais limpo e com hierarquia */
.orders-executive-header {
  padding: 18px 24px;
  border-bottom: 1px solid rgba(148, 163, 184, 0.18);
  overflow: visible;
}

.orders-executive-header--light {
  background:
    radial-gradient(circle at top right, rgba(59, 130, 246, 0.10), transparent 30%),
    linear-gradient(135deg, #ffffff 0%, #f8fbff 56%, #f1f5f9 100%);
  box-shadow: 0 14px 28px rgba(15, 23, 42, 0.06);
}

.orders-executive-header--dark {
  background:
    radial-gradient(circle at top right, rgba(99, 102, 241, 0.20), transparent 32%),
    rgba(15, 23, 42, 0.82);
  backdrop-filter: blur(18px);
}

.orders-header-main {
  gap: 20px;
}

.orders-header-icon {
  width: 52px;
  height: 52px;
  min-width: 52px;
  border-radius: 16px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #1e293b, #0f172a);
  color: #ffffff;
}

.orders-breadcrumb {
  font-size: 10px;
  font-weight: 900;
  letter-spacing: 0.08em;
  color: #64748b;
  text-transform: uppercase;
}

.orders-title {
  font-size: clamp(1.45rem, 2vw, 2rem);
  line-height: 1.05;
  font-weight: 950;
  letter-spacing: -0.04em;
  margin: 0;
  color: #0f172a;
}

.orders-executive-header--dark .orders-title {
  color: #fff;
}

.orders-mode-chip {
  min-height: 25px;
}

.orders-subtitle {
  font-size: 0.86rem;
  line-height: 1.35;
  color: #64748b;
  max-width: 780px;
  font-weight: 600;
}

.orders-executive-header--dark .orders-subtitle,
.orders-executive-header--dark .orders-breadcrumb {
  color: rgba(226, 232, 240, 0.75);
}

.context-switcher-row {
  gap: 10px;
  max-width: 100%;
  overflow-x: auto;
  scrollbar-width: none;
  padding-bottom: 4px;
}

.context-switcher-row::-webkit-scrollbar {
  display: none;
}

.orders-header-actions {
  min-width: min(520px, 100%);
}

.orders-refresh-btn {
  width: 42px !important;
  height: 42px !important;
  background: #ffffff !important;
  color: #334155 !important;
}

.orders-executive-header--dark .orders-refresh-btn {
  background: rgba(255,255,255,0.08) !important;
  color: #fff !important;
}

.order-mode-toggle {
  align-self: flex-end;
  background: rgba(255,255,255,0.80);
  overflow: hidden;
}

@media (max-width: 960px) {
  .orders-executive-header {
    padding: 14px 14px;
  }

  .orders-header-left {
    width: 100%;
  }

  .orders-header-icon {
    width: 44px;
    height: 44px;
    min-width: 44px;
    border-radius: 14px;
  }

  .orders-title {
    font-size: 1.25rem;
  }

  .orders-subtitle {
    font-size: 0.78rem;
  }

  .orders-header-actions {
    width: 100%;
    min-width: 0;
    align-items: stretch !important;
  }

  .order-mode-toggle {
    align-self: stretch;
    width: 100%;
  }
}



/* ===== Bandeja de filtros e ações refinada ===== */
.orders-filter-tray {
  overflow: hidden;
  border-radius: 18px !important;
}

.orders-filter-tray-light {
  background: linear-gradient(180deg, #ffffff 0%, #f8fafc 100%);
  border-color: rgba(148, 163, 184, 0.22) !important;
}

.orders-filter-tray-dark {
  background: linear-gradient(180deg, rgba(30, 41, 59, 0.98) 0%, rgba(15, 23, 42, 0.98) 100%);
  border-color: rgba(255, 255, 255, 0.08) !important;
}

.tray-header {
  background: linear-gradient(135deg, rgba(37,99,235,0.08) 0%, rgba(124,58,237,0.06) 100%);
  border-bottom: 1px solid rgba(148, 163, 184, 0.18);
}

.tray-icon {
  width: 36px;
  height: 36px;
  border-radius: 13px;
  background: rgba(37, 99, 235, 0.12);
  color: #2563eb;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: inset 0 1px 0 rgba(255,255,255,.8), 0 8px 18px rgba(37,99,235,.12);
}

.tray-section {
  padding-top: 14px;
  border-bottom: 1px solid rgba(148, 163, 184, 0.14);
}

.tray-section:last-child {
  border-bottom: 0;
}

.tray-section-title {
  font-size: 0.72rem;
  font-weight: 900;
  text-transform: uppercase;
  letter-spacing: 0.08em;
  color: #64748b;
}

.tray-action-list {
  display: grid;
  gap: 8px;
}

.tray-action {
  width: 100%;
  display: flex;
  align-items: center;
  gap: 12px;
  text-align: left;
  border: 1px solid rgba(148, 163, 184, 0.16);
  background: rgba(255,255,255,0.72);
  border-radius: 14px;
  padding: 10px 12px;
  cursor: pointer;
  transition: transform .16s ease, box-shadow .16s ease, border-color .16s ease;
}

.tray-action:hover:not(:disabled) {
  transform: translateY(-1px);
  border-color: rgba(37,99,235,0.26);
  box-shadow: 0 10px 20px rgba(15, 23, 42, 0.08);
}

.tray-action:disabled {
  opacity: .55;
  cursor: not-allowed;
}

.tray-action strong {
  display: block;
  font-size: .78rem;
  color: #0f172a;
}

.tray-action small {
  display: block;
  font-size: .68rem;
  color: #64748b;
  margin-top: 1px;
}

.tray-action-icon {
  width: 34px;
  height: 34px;
  border-radius: 12px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  background: rgba(248,250,252,.94);
  flex: 0 0 auto;
}

.tray-mini-label {
  font-size: .72rem;
  font-weight: 900;
  text-transform: uppercase;
  letter-spacing: .04em;
  color: #64748b;
}

.tray-date-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 10px;
}

.tray-field :deep(.v-field) {
  border-radius: 13px;
  background: rgba(255,255,255,.82);
}

.taskbar-action-btn {
  border-radius: 12px !important;
}

@media (max-width: 520px) {
  .orders-filter-tray {
    width: calc(100vw - 24px) !important;
  }

  .tray-date-row {
    grid-template-columns: 1fr;
  }
}


/* ===== Refinos de barra, fiscal e pendências ===== */
.taskbar-main {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 14px;
  width: 100%;
}

.taskbar-search {
  flex: 1 1 420px;
  min-width: 260px;
  max-width: 760px;
}

.taskbar-right {
  display: flex;
  align-items: center;
  justify-content: flex-end;
  gap: 10px;
  flex: 0 0 auto;
  margin-left: auto;
}

.period-button-group {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 5px;
  border-radius: 14px;
  background: rgba(248, 250, 252, 0.92);
  border: 1px solid rgba(148, 163, 184, 0.18);
  box-shadow: inset 0 1px 0 rgba(255,255,255,0.88), 0 8px 18px rgba(15,23,42,0.05);
}

.period-btn {
  border-radius: 10px !important;
}

.fiscal-seal {
  min-width: 74px;
  height: 28px;
  border: 0;
  border-radius: 999px;
  padding: 0 9px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 5px;
  font-size: 10px;
  font-weight: 900;
  letter-spacing: .04em;
  cursor: pointer;
  text-transform: uppercase;
  color: #fff;
}

.fiscal-seal--nfe {
  background: linear-gradient(135deg, #16a34a 0%, #15803d 100%);
}

.fiscal-seal--nfce {
  background: linear-gradient(135deg, #f97316 0%, #ea580c 100%);
}

.fiscal-seal--empty {
  background: rgba(148, 163, 184, .18);
  color: #94a3b8;
  box-shadow: inset 0 0 0 1px rgba(148, 163, 184, .28) !important;
  cursor: not-allowed;
}

.fiscal-download-disabled {
  background: rgba(148, 163, 184, .24) !important;
  color: #94a3b8 !important;
  opacity: .75;
}

.pending-ok-seal {
  width: 34px;
  height: 34px;
  border-radius: 999px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  color: #16a34a;
  background: linear-gradient(135deg, rgba(34,197,94,.18), rgba(22,163,74,.10));
  border: 1px solid rgba(22, 163, 74, .34);
  box-shadow:
    0 2px 0 rgba(22, 101, 52, .18),
    0 8px 14px rgba(22, 163, 74, .18),
    inset 0 1px 0 rgba(255,255,255,.65) !important;
}

.theme--dark .period-button-group,
.v-theme--dark .period-button-group {
  background: rgba(255,255,255,.06);
  border-color: rgba(255,255,255,.10);
}

@media (max-width: 1180px) {
  .taskbar-main {
    align-items: stretch;
    flex-direction: column;
  }

  .taskbar-search {
    max-width: none;
    width: 100%;
  }

  .taskbar-right {
    width: 100%;
    justify-content: flex-start;
    flex-wrap: wrap;
    margin-left: 0;
  }

  .period-button-group {
    overflow-x: auto;
    max-width: 100%;
  }
}



/* ===== Refinos finais: toolbar, filtros, datas e selos ===== */
.taskbar-main {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 14px;
  width: 100%;
}

.taskbar-search {
  flex: 1 1 520px;
  max-width: 760px;
  min-width: 280px;
}

.taskbar-right {
  display: flex;
  align-items: center;
  justify-content: flex-end;
  gap: 10px;
  margin-left: auto;
  flex-wrap: wrap;
}

.taskbar-action-btn {
  border-radius: 12px !important;
  letter-spacing: .02em !important;
  text-transform: none !important;
}

.orders-actions-tray .tray-action-list,
.orders-filter-tray .tray-action-list {
  display: grid;
  gap: 10px;
}

.tray-action {
  width: 100%;
  display: flex;
  align-items: center;
  gap: 12px;
  text-align: left;
  padding: 12px;
  border-radius: 14px;
  border: 1px solid rgba(148, 163, 184, .18);
  background: linear-gradient(180deg, rgba(248,250,252,.96), rgba(255,255,255,.92));
  box-shadow: 0 8px 18px rgba(15, 23, 42, .05), inset 0 1px 0 rgba(255,255,255,.9);
  transition: transform .15s ease, box-shadow .15s ease, border-color .15s ease;
}

.tray-action:hover:not(:disabled) {
  transform: translateY(-1px);
  border-color: rgba(59, 130, 246, .28);
  box-shadow: 0 12px 22px rgba(15, 23, 42, .08), inset 0 1px 0 rgba(255,255,255,.9);
}

.tray-action:disabled {
  opacity: .5;
  cursor: not-allowed;
}

.tray-action-icon {
  width: 36px;
  height: 36px;
  min-width: 36px;
  border-radius: 12px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  background: rgba(59, 130, 246, .10);
}

.tray-action strong {
  display: block;
  font-size: .82rem;
  line-height: 1.1;
}

.tray-action small {
  display: block;
  margin-top: 3px;
  color: #64748b;
  font-size: .72rem;
  line-height: 1.25;
}

.tray-period-grid {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 8px;
}

.period-filter-btn {
  font-size: 11px !important;
  border-radius: 12px !important;
  text-transform: uppercase !important;
}

.pending-ok-seal {
  width: 36px;
  height: 30px;
  border-radius: 12px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  color: #15803d;
  background: linear-gradient(135deg, rgba(220,252,231,.98), rgba(187,247,208,.96));
  border: 1px solid rgba(34,197,94,.38);
  box-shadow: 0 2px 0 rgba(21,128,61,.20), 0 8px 14px rgba(21,128,61,.14) !important;
}

.fiscal-seal {
  min-width: 76px;
  min-height: 30px;
  padding: 0 10px;
  border-radius: 12px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 5px;
  font-size: 10px;
  font-weight: 900;
  letter-spacing: .04em;
  border: 1px solid transparent;
  transition: transform .15s ease, opacity .15s ease, box-shadow .15s ease;
}

.fiscal-seal:not(:disabled):hover {
  transform: translateY(-1px);
}

.fiscal-seal--nfe {
  color: #fff;
  background: linear-gradient(135deg, #16a34a, #22c55e);
  border-color: rgba(22, 163, 74, .45);
}

.fiscal-seal--nfce {
  color: #fff;
  background: linear-gradient(135deg, #ea580c, #f97316);
  border-color: rgba(249, 115, 22, .45);
}

.fiscal-seal--empty,
.fiscal-download-disabled {
  opacity: .42 !important;
  filter: grayscale(.25);
  cursor: not-allowed !important;
}

.fiscal-download-disabled {
  background: #94a3b8 !important;
  color: white !important;
}

@media (max-width: 1180px) {
  .taskbar-main {
    align-items: stretch;
    flex-direction: column;
  }

  .taskbar-search {
    max-width: none;
    width: 100%;
    min-width: 0;
  }

  .taskbar-right {
    justify-content: flex-start;
    margin-left: 0;
  }
}

@media (max-width: 640px) {
  .tray-period-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}



/* ===== Refino visual solicitado: grid, check clean, dropdowns compactos ===== */
.order-mode-toggle {
  display: none !important;
}

.tray-mode-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 7px;
}

.tray-mode-btn {
  height: 34px;
  border: 1px solid rgba(148, 163, 184, .18);
  border-radius: 10px;
  background: rgba(248,250,252,.92);
  color: #334155;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 5px;
  font-size: 10.5px;
  font-weight: 900;
  letter-spacing: .02em;
  box-shadow: 0 2px 0 rgba(15,23,42,.06), 0 8px 14px rgba(15,23,42,.05);
  transition: transform .14s ease, box-shadow .14s ease, background .14s ease, color .14s ease;
}

.tray-mode-btn:hover {
  transform: translateY(-1px);
}

.tray-mode-btn--active-sales {
  background: linear-gradient(135deg, #16a34a, #22c55e);
  color: white;
  border-color: rgba(22, 163, 74, .40);
}

.tray-mode-btn--active-billing {
  background: linear-gradient(135deg, #2563eb, #60a5fa);
  color: white;
  border-color: rgba(37, 99, 235, .40);
}

.tray-mode-btn--active-admin {
  background: linear-gradient(135deg, #7c3aed, #a855f7);
  color: white;
  border-color: rgba(124, 58, 237, .40);
}

.orders-filter-tray {
  max-width: min(360px, calc(100vw - 24px)) !important;
  overflow: hidden;
}

.orders-actions-tray {
  max-width: min(350px, calc(100vw - 24px)) !important;
}

.tray-header-compact {
  min-height: auto !important;
  border-bottom: 1px solid rgba(148, 163, 184, .14);
}

.tray-header-compact .tray-icon {
  width: 30px !important;
  height: 30px !important;
  min-width: 30px !important;
  border-radius: 10px !important;
}

.tray-header-compact .text-subtitle-2 {
  font-size: .82rem !important;
  line-height: 1.1 !important;
}

.tray-header-compact .text-caption {
  font-size: .68rem !important;
  line-height: 1.15 !important;
}

.tray-section-title {
  font-size: .68rem !important;
  letter-spacing: .08em !important;
  color: #64748b !important;
}

.tray-field-compact :deep(.v-field),
.tray-field.tray-field-compact :deep(.v-field) {
  min-height: 34px !important;
  border-radius: 10px !important;
  font-size: .78rem !important;
}

.tray-field-compact :deep(.v-field__input),
.tray-field.tray-field-compact :deep(.v-field__input) {
  min-height: 34px !important;
  padding-top: 3px !important;
  padding-bottom: 3px !important;
  font-size: .78rem !important;
}

.tray-field-compact :deep(.v-label),
.tray-field.tray-field-compact :deep(.v-label) {
  font-size: .72rem !important;
}

.tray-mini-label {
  font-size: .68rem !important;
  margin-bottom: 5px !important;
}

.tray-date-row {
  gap: 7px !important;
}

.tray-period-grid {
  gap: 6px !important;
}

.period-filter-btn {
  height: 32px !important;
  font-size: 10px !important;
  border-radius: 9px !important;
  box-shadow: 0 1px 0 rgba(15,23,42,.08), 0 5px 10px rgba(15,23,42,.04) !important;
}

.tray-action {
  padding: 9px !important;
  border-radius: 11px !important;
  gap: 9px !important;
}

.tray-action-icon {
  width: 30px !important;
  height: 30px !important;
  min-width: 30px !important;
  border-radius: 10px !important;
}

.tray-action strong {
  font-size: .76rem !important;
}

.tray-action small {
  font-size: .66rem !important;
  line-height: 1.15 !important;
}

.pending-ok-seal {
  width: 26px !important;
  height: 26px !important;
  min-width: 26px !important;
  border-radius: 999px !important;
  color: #15803d !important;
  background: rgba(220, 252, 231, .95) !important;
  border: 1px solid rgba(34, 197, 94, .28) !important;
  box-shadow: inset 0 1px 0 rgba(255,255,255,.9), 0 4px 10px rgba(22, 163, 74, .08) !important;
}

.pending-ok-seal .v-icon {
  font-size: 18px !important;
}

.grid-header,
.grid-row {
  width: 100%;
}

.grid-row .cell,
.grid-header .cell {
  min-width: 0;
}

.actions-inline {
  justify-content: center;
  width: 100%;
}

.cell.right {
  padding-right: 12px;
}

@media (max-width: 1180px) {
  .tray-mode-grid {
    grid-template-columns: 1fr;
  }
}

</style>
