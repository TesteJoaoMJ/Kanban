<template>
  <div
    class="sales-layout font-sans fill-height d-flex flex-column relative overflow-hidden"
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
            <span class="opacity-70">Varejo</span>
            <span class="mx-2 opacity-50">></span>
            <span class="font-weight-bold">Vendas de Balcão</span>
          </div>
          <div class="d-flex align-center gap-2 mt-1">
             <div class="text-h6 font-weight-black tracking-tight leading-none" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">
                Gestão de Loja (PDV)
             </div>
             <v-chip size="x-small" :color="companyStore.isGlobalView ? 'purple' : 'success'" class="font-weight-bold ml-2">
                {{ companyStore.isGlobalView ? 'HOLDING' : companyStore.currentCompanyName.toUpperCase() }}
             </v-chip>
          </div>

          <div class="context-switcher-row d-flex align-center flex-wrap mt-3">
            <v-btn
              v-for="btn in tenantContextButtons"
              :key="btn.id"
              size="x-small"
              height="28"
              :variant="companyStore.context === btn.id || (btn.id === 'global' && companyStore.isGlobalView) ? 'flat' : 'elevated'"
              :color="companyStore.context === btn.id || (btn.id === 'global' && companyStore.isGlobalView) ? (btn.isHolding ? 'purple' : btn.color) : undefined"
              class="context-btn-3d font-weight-black rounded-lg flex-shrink-0"
              :class="companyStore.context === btn.id || (btn.id === 'global' && companyStore.isGlobalView) ? 'context-btn-active' : 'context-btn-idle'"
              @click="setTenantContext(btn.id)"
            >
              <v-icon start size="13">{{ btn.icon }}</v-icon>
              {{ btn.name }}
            </v-btn>
          </div>
        </div>

        <div class="top-actions d-flex align-center">
            <v-chip color="primary" variant="flat" class="font-weight-bold chip-3d d-none d-sm-flex">
                Total: {{ totalSalesCount }}
            </v-chip>
            <v-tooltip text="Relatório de Itens Vendidos" location="bottom">
                <template v-slot:activator="{ props }">
                    <v-btn v-bind="props" icon variant="text" @click="reportModal.show = true" class="btn-3d top-icon-action" :color="themeStore.currentMode === 'light' ? 'blue-darken-2' : 'info'">
                        <v-icon>mdi-file-chart-outline</v-icon>
                    </v-btn>
                </template>
            </v-tooltip>
            <v-btn icon variant="text" @click="fetchSales" :loading="loading" class="btn-3d top-icon-action" :color="themeStore.currentMode === 'light' ? 'grey-darken-3' : 'white'"><v-icon>mdi-refresh</v-icon></v-btn>
            <v-btn
              color="success"
              variant="flat"
              class="btn-3d top-new-sale px-4 font-weight-bold text-caption text-uppercase letter-spacing-1 flex-shrink-0"
              prepend-icon="mdi-cart-outline"
              height="40"
              @click="$router.push({ name: 'PDV' })"
            >
              Nova Venda
            </v-btn>
        </div>
      </div>

      <div class="px-4 px-md-6 pt-3 pb-2 flex-shrink-0">
         <div class="controls-bar d-flex flex-column gap-3 rounded-lg" :class="themeStore.currentMode === 'light' ? 'controls-light' : 'controls-dark border-white-10'">

            <div class="controls-main-row d-flex align-center justify-space-between flex-wrap">

                <v-expand-transition>
                    <div v-if="selectedItems.length > 0" class="d-flex align-center gap-2 bg-indigo-lighten-5 px-3 py-1 rounded border border-indigo-lighten-3 shadow-sm mr-2">
                        <span class="text-caption font-weight-bold text-indigo-darken-3">
                            {{ selectedItems.length }} selecionados | Total: {{ formatCurrency(selectedTotalValue) }}
                        </span>
                        <v-divider vertical class="mx-2 border-indigo-lighten-3"></v-divider>
                        <v-menu>
                            <template v-slot:activator="{ props }">
                                <v-btn v-bind="props" size="small" color="indigo" variant="flat" append-icon="mdi-chevron-down" class="font-weight-bold btn-3d">Ações em Massa</v-btn>
                            </template>
                            <v-list density="compact" class="shadow-xl border-thin rounded-lg" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-grey-darken-4'">
                                <v-list-item @click="openBulkAssignSeller" link>
                                    <template v-slot:prepend><v-icon color="indigo" size="small" class="mr-2">mdi-account-arrow-right</v-icon></template>
                                    <v-list-item-title class="text-caption font-weight-bold text-indigo">Atribuir Vendedor</v-list-item-title>
                                </v-list-item>
                                <v-divider class="my-1"></v-divider>

                                <v-list-subheader class="text-[10px] text-uppercase font-weight-bold pt-1">Financeiro</v-list-subheader>
                                <v-list-item @click="bulkUpdateFinancial('Faturado')" link>
                                    <template v-slot:prepend><v-icon color="success" size="small" class="mr-2">mdi-check-all</v-icon></template>
                                    <v-list-item-title class="text-caption font-weight-bold" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">Marcar Faturado</v-list-item-title>
                                </v-list-item>
                                <v-list-item @click="bulkUpdateFinancial('Pendente')" link>
                                    <template v-slot:prepend><v-icon color="warning" size="small" class="mr-2">mdi-clock-outline</v-icon></template>
                                    <v-list-item-title class="text-caption font-weight-bold" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">Marcar Pendente</v-list-item-title>
                                </v-list-item>
                                <v-divider class="my-2"></v-divider>
                                <v-list-item @click="bulkDelete" link>
                                    <template v-slot:prepend><v-icon color="warning" size="small" class="mr-2">mdi-cancel</v-icon></template>
                                    <v-list-item-title class="text-caption font-weight-bold text-warning">Cancelar Selecionados</v-list-item-title>
                                </v-list-item>
                            </v-list>
                        </v-menu>
                        <v-btn icon size="x-small" variant="text" color="indigo-darken-3" @click="selectedItems = []"><v-icon>mdi-close</v-icon></v-btn>
                    </div>
                </v-expand-transition>

                <div class="search-wrap d-flex align-center flex-grow-1 rounded border" :class="themeStore.currentMode === 'light' ? 'search-light' : 'search-dark'">
                  <v-icon :color="themeStore.currentMode === 'light' ? 'grey-darken-1' : 'white-70'" class="ml-2">mdi-magnify</v-icon>
                  <input v-model="filters.search" type="text" placeholder="Buscar cliente, código ou vendedor..." class="clean-input flex-grow-1 pa-2 font-weight-bold" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'"/>
                </div>

                <v-menu :close-on-content-click="false" location="bottom end">
                    <template v-slot:activator="{ props }">
                        <v-btn
                            v-bind="props"
                            variant="outlined"
                            class="btn-3d font-weight-bold filter-trigger-btn"
                            height="40"
                            :color="themeStore.currentMode === 'light' ? 'primary' : 'white'"
                            prepend-icon="mdi-filter-variant"
                        >
                            Filtros
                        </v-btn>
                    </template>
                    <v-card class="filter-panel rounded-xl shadow-xl border-thin" :class="themeStore.currentMode === 'light' ? 'filter-panel-light' : 'filter-panel-dark text-white'" min-width="420">
                        <div class="filter-panel-header">
                            <div class="filter-panel-icon"><v-icon size="18">mdi-filter-variant</v-icon></div>
                            <div>
                                <div class="filter-panel-title">Filtros avançados</div>
                                <div class="filter-panel-subtitle">Refine a lista sem travar o carregamento.</div>
                            </div>
                        </div>

                        <div class="filter-section">
                            <div class="filter-section-title"><v-icon size="14">mdi-calendar-range</v-icon> Período específico</div>
                            <div class="filter-grid-2">
                                <v-text-field v-model="filters.startDate" label="Data inicial" type="date" variant="outlined" density="compact" class="ui-field filter-field" hide-details></v-text-field>
                                <v-text-field v-model="filters.endDate" label="Data final" type="date" variant="outlined" density="compact" class="ui-field filter-field" hide-details></v-text-field>
                            </div>
                        </div>

                        <div class="filter-section">
                            <div class="filter-section-title"><v-icon size="14">mdi-receipt-text-check-outline</v-icon> Status</div>
                            <div class="filter-grid-2">
                                <v-select v-model="filters.fiscalStatus" :items="['Todos', 'Com NFCe', 'Com NFe', 'Sem Fiscal']" label="Fiscal" variant="outlined" density="compact" class="ui-field filter-field" hide-details></v-select>
                                <v-select v-model="filters.financialStatus" :items="['Todos', 'Faturado', 'Pendente', 'Parcialmente Faturado']" label="Financeiro" variant="outlined" density="compact" class="ui-field filter-field" hide-details></v-select>
                            </div>
                        </div>

                        <div class="filter-section">
                            <div class="filter-section-title"><v-icon size="14">mdi-cash-multiple</v-icon> Faixa de valores</div>
                            <div class="filter-grid-2">
                                <v-text-field v-model.number="filters.minValue" label="Valor mínimo" prefix="R$" type="number" variant="outlined" density="compact" class="ui-field filter-field" hide-details></v-text-field>
                                <v-text-field v-model.number="filters.maxValue" label="Valor máximo" prefix="R$" type="number" variant="outlined" density="compact" class="ui-field filter-field" hide-details></v-text-field>
                            </div>
                        </div>

                        <div class="filter-panel-footer">
                            <v-btn color="error" variant="tonal" height="38" class="font-weight-bold filter-clear-btn" prepend-icon="mdi-backspace-outline" @click="clearFilters">Limpar filtros</v-btn>
                        </div>
                    </v-card>
                </v-menu>

                <div class="period-actions d-flex align-center">
                    <v-btn-toggle v-model="currentPeriod" density="compact" color="primary" mandatory class="d-flex period-toggle" divided variant="outlined" style="height: 40px;">
                        <v-btn value="today" class="text-caption font-weight-bold">Hoje</v-btn>
                        <v-btn value="week" class="text-caption font-weight-bold">Semana</v-btn>
                        <v-btn value="month" class="text-caption font-weight-bold">Mês</v-btn>
                        <v-btn value="custom" class="text-caption font-weight-bold">Específico</v-btn>
                        <v-btn value="all" class="text-caption font-weight-bold">Todos</v-btn>
                    </v-btn-toggle>
                </div>
             </div>
         </div>
      </div>

      <div class="flex-grow-1 px-4 px-md-6 pb-6 overflow-hidden d-flex flex-column">
        <v-card class="flex-grow-1 d-flex flex-column rounded-lg border-thin overflow-hidden" :class="themeStore.currentMode === 'light' ? 'bg-white shadow-sm' : 'glass-card border-white-05'" :elevation="0">
          <div class="grid-scroll flex-grow-1 overflow-y-auto custom-scroll relative">
            <div class="grid-header sticky-head" :class="[themeStore.currentMode === 'light' ? 'grid-surface-light border-b border-grey-lighten-2' : 'grid-surface-dark border-bottom-white-05']" :style="{ gridTemplateColumns: computedGridTemplate }">
               <div class="cell center header-text">
                   <v-checkbox-btn :model-value="selectAll" @update:model-value="toggleSelectAll" density="compact" hide-details color="primary" class="chk-fixed"></v-checkbox-btn>
               </div>
               <div class="cell center header-text">Cód.</div>
               <div class="cell center header-text">Data</div>
               <div class="cell header-text">Cliente / Responsável</div>
               <div class="cell header-text">Vendedor</div>
               <div v-if="companyStore.isGlobalView" class="cell center header-text">Empresa</div>
               <div class="cell center header-text">Valor Total</div>
               <div class="cell center header-text">Status</div>
               <div class="cell center header-text">Financeiro</div>
               <div class="cell center header-text">Fiscal</div>
               <div class="cell center header-text">Ações</div>
            </div>

            <div v-if="loading" class="d-flex flex-column justify-center align-center h-100 py-12">
              <v-progress-circular indeterminate color="primary" size="40" width="4"></v-progress-circular>
            </div>

            <div v-else-if="filteredSales.length === 0" class="d-flex flex-column justify-center align-center h-100 opacity-60 gap-2 py-12">
              <v-icon size="56" color="grey-lighten-1">mdi-store-remove</v-icon>
              <span class="text-subtitle-1 font-weight-medium text-grey">Nenhuma venda encontrada.</span>
            </div>

            <div v-else v-for="(item, idx) in paginatedSales" :key="item.id" class="grid-row border-b" :class="[themeStore.currentMode === 'light' ? 'grid-row-light border-grey-lighten-2' : 'grid-row-dark border-bottom-white-05', zebraClass(idx)]" :style="{ gridTemplateColumns: computedGridTemplate }">

               <div class="cell center">
                    <v-checkbox-btn v-model="selectedItems" :value="item.id" density="compact" hide-details color="primary" class="chk-fixed"></v-checkbox-btn>
               </div>

               <div class="cell center">
                   <span class="pill-ref" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-4' : 'bg-transparent text-white underline-ref'">
                       {{ String(item.order_number ?? 0).padStart(4, '0') }}
                   </span>
               </div>

               <div class="cell center">
                   <span class="list-text-11 font-mono font-weight-bold" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-3' : 'text-white-70'">{{ formatDate(item.date_sale || item.created_at) }}</span>
               </div>

               <div class="cell">
                   <div class="d-flex align-center w-100" style="min-width: 0;">
                       <v-avatar :color="getColor(item.customer_name)" size="32" variant="tonal" class="rounded-lg mr-3 flex-shrink-0 font-weight-black text-[12px] shadow-sm">{{ item.customer_name?.charAt(0).toUpperCase() || 'C' }}</v-avatar>
                       <div class="d-flex flex-column overflow-hidden" style="min-width: 0;">
                          <div class="text-truncate list-text-11 font-weight-black" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'" :title="item.customer_name">{{ item.customer_name || 'Consumidor Final' }}</div>
                          <div class="text-[10px] text-uppercase font-weight-bold" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-1' : 'text-white-70'" v-if="item.items?.length">
                              <v-icon size="10" class="mr-1">mdi-package-variant-closed</v-icon> {{ item.items.length }} ite{{ item.items.length > 1 ? 'ns' : 'm' }}
                          </div>
                          <div class="text-[10px] text-uppercase font-weight-bold opacity-50" v-else>
                              {{ item.item_count || 0 }} itens
                          </div>
                       </div>
                   </div>
               </div>

               <div class="cell">
                   <span class="text-truncate list-text-11 font-weight-bold opacity-80">{{ item.seller_name || item.creator?.full_name || '-' }}</span>
               </div>

               <div v-if="companyStore.isGlobalView" class="cell center">
                    <v-chip size="x-small" color="blue-grey" variant="flat" class="font-weight-black chip-3d">{{ getCompanyName(item.company_id) }}</v-chip>
               </div>

               <div class="cell center">
                   <span class="list-text-11 font-mono font-weight-black" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">{{ formatCurrency(item.total_value) }}</span>
               </div>

               <div class="cell center">
                   <span class="solid-chip chip-3d" :class="getStatusColorClass(item.status)">
                       {{ formatStatus(item.status) }}
                   </span>
               </div>

                <div class="cell center">
                   <span class="solid-chip chip-3d" :class="getFinancialColorClass(item.financial_status)">
                        {{ item.financial_status || 'Pendente' }}
                   </span>
               </div>

               <div class="cell center">
                   <template v-if="item.fiscal_doc?.found">
                       <v-tooltip :text="item.fiscal_doc.key?.includes('MANUAL') ? 'Selo Manual - Sem PDF Vinculado' : `Documento ${item.fiscal_doc.type} Autorizado! Clique para baixar.`" location="top" content-class="custom-tooltip">
                           <template v-slot:activator="{ props }">
                               <v-chip v-bind="props" size="small" :color="item.fiscal_doc.type === 'NFe' ? 'success' : 'deep-orange'" class="font-weight-bold cursor-pointer chip-3d" @click="downloadFiscalDoc(item)">
                                   <v-icon start size="14">mdi-check-decagram</v-icon> {{ item.fiscal_doc.type }}
                               </v-chip>
                           </template>
                       </v-tooltip>
                   </template>
                   <template v-else>
                       <span class="text-caption text-grey opacity-50 font-weight-bold">-</span>
                   </template>
               </div>

               <div class="cell center">
                   <div class="actions-inline">
                       <v-tooltip text="Ver Detalhes / Faturar" location="top" content-class="custom-tooltip">
                           <template v-slot:activator="{ props }">
                               <v-btn v-bind="props" icon size="small" class="action-btn action-edit btn-3d" variant="flat" @click.stop="openDetailModal(item)">
                                   <v-icon size="16">mdi-text-box-search-outline</v-icon>
                               </v-btn>
                           </template>
                       </v-tooltip>

                       <template v-if="item.fiscal_doc?.found && !item.fiscal_doc.key?.includes('MANUAL')">
                           <v-tooltip :text="`Baixar ${item.fiscal_doc.type}`" location="top" content-class="custom-tooltip">
                               <template v-slot:activator="{ props }">
                                   <v-btn v-bind="props" icon size="small" class="action-btn bg-purple-darken-2 btn-3d" variant="flat" @click.stop="downloadFiscalDoc(item)">
                                       <v-icon size="16">mdi-file-download-outline</v-icon>
                                   </v-btn>
                               </template>
                           </v-tooltip>
                       </template>
                       <template v-else>
                           <v-tooltip text="Imprimir Pedido" location="top" content-class="custom-tooltip">
                               <template v-slot:activator="{ props }">
                                   <v-btn v-bind="props" icon size="small" class="action-btn bg-indigo-darken-2 btn-3d" variant="flat" @click.stop="printOrder(item)">
                                       <v-icon size="16">mdi-printer</v-icon>
                                   </v-btn>
                               </template>
                           </v-tooltip>
                       </template>

                       <v-menu location="bottom end" :close-on-content-click="false" transition="scale-transition">
                           <template v-slot:activator="{ props }">
                               <v-btn v-bind="props" icon size="small" class="action-btn action-more btn-3d" variant="flat">
                                   <v-icon size="18">mdi-chevron-down</v-icon>
                               </v-btn>
                           </template>
                           <v-list density="compact" class="rounded-lg border-thin shadow-xl py-0" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-grey-darken-4 text-white'" width="260">

                               <v-list-item :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-4' : 'bg-white-05'" class="py-1" style="min-height: 30px;">
                                   <v-list-item-title class="text-[10px] font-weight-black text-uppercase opacity-70">Ações do Pedido</v-list-item-title>
                               </v-list-item>

                               <v-list-item link @click="openAssignSeller(item)" density="compact">
                                   <template v-slot:prepend><v-icon size="18" class="mr-2 text-indigo">mdi-account-arrow-right</v-icon></template>
                                   <v-list-item-title class="text-caption text-indigo font-weight-bold">Atribuir Vendedor</v-list-item-title>
                               </v-list-item>

                               <v-divider :class="themeStore.currentMode === 'light' ? 'border-grey-lighten-2' : 'border-white-10'"></v-divider>

                               <v-list-item link @click="openNfceDialog(item, true)" density="compact" :disabled="item.fiscal_doc?.found">
                                   <template v-slot:prepend><v-icon size="18" class="mr-2" :class="item.fiscal_doc?.found ? 'text-grey' : 'text-deep-orange'">mdi-receipt-text-check</v-icon></template>
                                   <v-list-item-title class="text-caption font-weight-bold" :class="item.fiscal_doc?.found ? 'text-grey' : 'text-deep-orange'">
                                        {{ item.fiscal_doc?.found ? 'Emissão Bloqueada' : 'Emitir NFC-e (Nome)' }}
                                   </v-list-item-title>
                               </v-list-item>

                               <v-list-item link @click="openNfceDialog(item, false)" density="compact" :disabled="item.fiscal_doc?.found">
                                   <template v-slot:prepend><v-icon size="18" class="mr-2" :class="item.fiscal_doc?.found ? 'text-grey' : 'text-orange'">mdi-receipt-text-outline</v-icon></template>
                                   <v-list-item-title class="text-caption font-weight-bold" :class="item.fiscal_doc?.found ? 'text-grey' : 'text-orange'">
                                        {{ item.fiscal_doc?.found ? 'Emissão Bloqueada' : 'Emitir NFC-e (Simples)' }}
                                   </v-list-item-title>
                               </v-list-item>

                               <v-list-item link @click="openNfeModal(item)" density="compact" :disabled="item.fiscal_doc?.found">
                                    <template v-slot:prepend><v-icon size="18" class="mr-2" :class="item.fiscal_doc?.found ? 'text-grey' : 'text-primary'">mdi-file-document-outline</v-icon></template>
                                    <v-list-item-title class="text-caption font-weight-bold" :class="item.fiscal_doc?.found ? 'text-grey' : 'text-primary'">
                                        {{ item.fiscal_doc?.found ? 'Emissão Bloqueada' : 'Emitir NFe (55)' }}
                                    </v-list-item-title>
                                </v-list-item>

                               <v-divider :class="themeStore.currentMode === 'light' ? 'border-grey-lighten-2' : 'border-white-10'"></v-divider>

                               <v-list-item :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-4' : 'bg-white-05'" class="py-1" style="min-height: 30px;">
                                   <v-list-item-title class="text-[10px] font-weight-black text-uppercase opacity-70">Correções Manuais</v-list-item-title>
                               </v-list-item>

                               <v-list-item link @click="reopenFinancial(item)" density="compact" :disabled="item.financial_status === 'Pendente'">
                                    <template v-slot:prepend><v-icon size="18" class="mr-2" :class="themeStore.currentMode === 'light' ? 'text-warning' : 'text-warning'">mdi-undo-variant</v-icon></template>
                                    <v-list-item-title class="text-caption font-weight-bold" :class="themeStore.currentMode === 'light' ? 'text-warning-darken-3' : 'text-warning'">Reabrir / Estornar Fin.</v-list-item-title>
                               </v-list-item>

                               <v-list-item link @click="openMarkEmitted(item, 'NFCe')" density="compact" :disabled="item.fiscal_doc?.found">
                                    <template v-slot:prepend><v-icon size="18" class="mr-2" :class="themeStore.currentMode === 'light' ? 'text-blue-grey' : 'text-grey-lighten-1'">mdi-tag-check</v-icon></template>
                                    <v-list-item-title class="text-caption font-weight-bold" :class="themeStore.currentMode === 'light' ? 'text-blue-grey-darken-3' : 'text-grey-lighten-1'">Forçar Selo NFC-e</v-list-item-title>
                                </v-list-item>

                                <v-list-item link @click="openMarkEmitted(item, 'NFe')" density="compact" :disabled="item.fiscal_doc?.found">
                                    <template v-slot:prepend><v-icon size="18" class="mr-2" :class="themeStore.currentMode === 'light' ? 'text-blue-grey' : 'text-grey-lighten-1'">mdi-tag-check</v-icon></template>
                                    <v-list-item-title class="text-caption font-weight-bold" :class="themeStore.currentMode === 'light' ? 'text-blue-grey-darken-3' : 'text-grey-lighten-1'">Forçar Selo NFe</v-list-item-title>
                                </v-list-item>

                               <v-divider :class="themeStore.currentMode === 'light' ? 'border-grey-lighten-2' : 'border-white-10'"></v-divider>

                               <v-list-item link @click="openShareModal(item, 'whatsapp', item.fiscal_doc?.type || 'Pedido')" density="compact">
                                   <template v-slot:prepend><v-icon size="18" class="mr-2 text-success">mdi-whatsapp</v-icon></template>
                                   <v-list-item-title class="text-caption font-weight-bold">Compartilhar Documento</v-list-item-title>
                               </v-list-item>

                               <v-list-item link @click="deleteOrder(item)" density="compact">
                                   <template v-slot:prepend><v-icon size="18" class="mr-2 text-warning">mdi-cancel</v-icon></template>
                                   <v-list-item-title class="text-caption text-warning font-weight-bold">Cancelar Venda</v-list-item-title>
                               </v-list-item>
                           </v-list>
                       </v-menu>
                   </div>
               </div>

            </div>
          </div>
          <div class="flex-shrink-0 border-t px-4 py-2 d-flex align-center justify-space-between z-20" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-surface-variant border-white-05'">
            <div class="text-caption opacity-80 font-weight-bold">
              Total: <strong :class="themeStore.currentMode === 'light' ? 'text-primary' : 'text-white'">{{ paginatedSales.length }}</strong> de <strong :class="themeStore.currentMode === 'light' ? 'text-primary' : 'text-white'">{{ totalSalesCount }}</strong> vendas | Valor desta página: <strong :class="themeStore.currentMode === 'light' ? 'text-primary' : 'text-white'">{{ formatCurrency(currentPageTotalValue) }}</strong>
            </div>
            <v-pagination v-model="page" :length="totalPages" :total-visible="5" density="compact" :active-color="themeStore.currentMode === 'light' ? 'primary' : 'success'" variant="tonal" size="small"></v-pagination>
          </div>
        </v-card>
      </div>
    </div>

    <StoreSaleDetailModal
        v-if="detailModalState.show && selectedOrder"
        v-model="detailModalState.show"
        :sale="selectedOrder"
        @faturar="handleFaturar"
        @print-a4="printOrder"
        @print-nfce="openNfceDialog($event, true)"
    />

    <v-dialog v-model="linkCustomerModal.show" max-width="500" persistent>
        <v-card class="rounded-lg shadow-xl border-thin" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-grey-darken-4 text-white'">
            <div class="pa-4 d-flex align-center justify-space-between border-b" :class="themeStore.currentMode === 'light' ? 'bg-indigo-darken-3 text-white' : 'bg-indigo-darken-4 border-white-10'">
                <span class="font-weight-bold d-flex align-center gap-2"><v-icon>mdi-account-search</v-icon> Vincular Cliente Obrigatório</span>
                <v-btn icon="mdi-close" variant="text" size="small" @click="linkCustomerModal.show = false"></v-btn>
            </div>
            <div class="pa-5">
                <v-alert type="warning" variant="tonal" class="mb-4 text-caption border-thin font-weight-bold">
                    Esta venda está sem cliente atrelado (Consumidor Final). Para lançar no financeiro e gerar as contas a receber corretamente, você precisa vincular um cliente do banco de dados ou cadastrar um novo.
                </v-alert>

                <v-tabs v-model="linkCustomerModal.mode" density="compact" color="indigo" class="mb-4 border-b" :class="themeStore.currentMode === 'light' ? 'border-grey-lighten-2' : 'border-white-10'">
                    <v-tab value="search" class="text-caption font-weight-bold">Buscar Existente</v-tab>
                    <v-tab value="new" class="text-caption font-weight-bold">Cadastrar Novo</v-tab>
                </v-tabs>

                <v-window v-model="linkCustomerModal.mode">
                    <v-window-item value="search">
                        <v-autocomplete
                            v-model="linkCustomerModal.selectedCustomerId"
                            :items="linkCustomerModal.customers"
                            item-title="display"
                            item-value="id"
                            label="Procurar Cliente (Nome, CPF/CNPJ)"
                            variant="outlined"
                            density="comfortable"
                            class="ui-field"
                            hide-details
                            @update:search="fetchCustomersQuery"
                        >
                             <template v-slot:prepend-inner>
                                 <v-icon size="20" class="mr-1 opacity-60">mdi-magnify</v-icon>
                             </template>
                        </v-autocomplete>
                    </v-window-item>
                    <v-window-item value="new">
                        <v-text-field v-model="linkCustomerModal.newCustomer.nome" label="Nome Completo / Razão Social *" variant="outlined" density="compact" class="mb-3 ui-field" hide-details></v-text-field>
                        <v-text-field v-model="linkCustomerModal.newCustomer.cpf_cnpj" label="CPF / CNPJ" variant="outlined" density="compact" class="mb-3 ui-field" hide-details v-maska="['###.###.###-##', '##.###.###/####-##']"></v-text-field>
                        <v-text-field v-model="linkCustomerModal.newCustomer.telefone" label="Celular / WhatsApp" variant="outlined" density="compact" class="ui-field" hide-details v-maska="['(##) ####-####', '(##) #####-####']"></v-text-field>
                    </v-window-item>
                </v-window>
            </div>
            <div class="pa-4 border-t d-flex justify-end gap-2" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-black-20 border-white-10'">
                <v-btn variant="text" class="font-weight-bold btn-3d" :color="themeStore.currentMode === 'light' ? 'grey-darken-2' : 'white'" @click="linkCustomerModal.show = false">Cancelar</v-btn>
                <v-btn color="indigo-darken-2" variant="flat" class="font-weight-bold btn-3d px-6" :loading="linkCustomerModal.loading" @click="confirmLinkCustomer">
                    <v-icon start>mdi-link</v-icon> Vincular e Continuar
                </v-btn>
            </div>
        </v-card>
    </v-dialog>

    <NfeEmissionModal
        v-if="nfeModalState.show"
        v-model="nfeModalState.show"
        :order-id="nfeModalState.orderId"
        :draft-payload="null"
        @success="handleNfeSuccess"
    />

    <v-dialog v-model="markEmittedModal.show" max-width="400">
        <v-card class="rounded-lg shadow-xl border-thin" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-grey-darken-4 text-white'">
            <div class="pa-4 d-flex align-center justify-space-between border-b" :class="themeStore.currentMode === 'light' ? 'bg-blue-grey-darken-3 text-white' : 'border-white-10'">
                <span class="font-weight-bold">Forçar Selo de {{ markEmittedModal.type }}</span>
                <v-btn icon="mdi-close" variant="text" size="small" class="btn-3d" @click="markEmittedModal.show = false"></v-btn>
            </div>
            <div class="pa-4">
                <p class="text-caption font-weight-medium mb-4 lh-1" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-2' : 'text-white-70'">
                    Use esta opção se a nota foi emitida por fora do sistema e você deseja colocar o selo para evitar que alguém emita novamente.
                </p>
                <v-text-field v-model="markEmittedModal.numero" label="Número da Nota (Opcional)" variant="outlined" density="compact" class="mb-3 ui-field" hide-details></v-text-field>
                <v-text-field v-model="markEmittedModal.chave" label="Chave de Acesso (Opcional)" variant="outlined" density="compact" class="ui-field" hide-details></v-text-field>
            </div>
            <div class="pa-4 border-t d-flex justify-end gap-2" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5' : 'bg-black-20 border-white-10'">
                <v-btn variant="text" class="font-weight-bold btn-3d" @click="markEmittedModal.show = false">Cancelar</v-btn>
                <v-btn :color="themeStore.currentMode === 'light' ? 'blue-grey-darken-3' : 'success'" variant="flat" class="font-weight-bold btn-3d px-6" :loading="markEmittedModal.loading" @click="confirmMarkEmitted">Gravar Selo</v-btn>
            </div>
        </v-card>
    </v-dialog>

    <v-dialog v-model="nfceModal.show" max-width="1500" persistent scrim="black opacity-80" scrollable transition="dialog-bottom-transition" class="fixed-dialog">
        <v-card class="rounded-xl d-flex flex-row overflow-hidden shadow-xl mx-auto" style="height: 90vh; max-height: 850px;" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-grey-darken-4 text-white'">

            <div class="border-r d-flex flex-column" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-4 border-grey-lighten-2' : 'bg-grey-darken-3 border-white-10'" style="width: 380px; flex-shrink: 0;">
                <div class="pa-8 border-b" :class="themeStore.currentMode === 'light' ? 'border-grey-lighten-2' : 'border-white-10'">
                    <div class="d-flex align-center gap-4 mb-6">
                        <div class="icon-box rounded-xl pa-4 border shadow-sm" :class="themeStore.currentMode === 'light' ? 'bg-white border-grey-lighten-2' : 'bg-grey-darken-4 border-white-10'">
                            <v-icon color="deep-orange" size="32">mdi-receipt-text</v-icon>
                        </div>
                        <div>
                            <div class="text-caption font-weight-black text-uppercase opacity-70 mb-1 letter-spacing-1">Emissão de Cupom</div>
                            <div class="text-h6 font-weight-black lh-1">NFC-e Consumidor</div>
                        </div>
                    </div>

                    <div class="pa-4 rounded-xl border mb-6 shadow-inner" :class="themeStore.currentMode === 'light' ? 'bg-white border-grey-lighten-2' : 'bg-grey-darken-4 border-white-10'">
                        <div class="text-[10px] font-weight-black text-uppercase opacity-60 mb-2 letter-spacing-1">Empresa Emitente</div>
                        <div class="font-weight-black text-body-1 mb-1">{{ activeNfceCompany?.trade_name || activeNfceCompany?.name || 'Procurando...' }}</div>
                        <div class="font-mono text-caption opacity-70">{{ activeNfceCompany?.cnpj }}</div>
                    </div>

                    <div class="d-flex flex-column gap-3">
                        <div class="d-flex justify-space-between align-end">
                            <span class="text-caption font-weight-bold text-uppercase opacity-60">Itens do Pedido</span>
                            <span class="font-weight-black text-body-1">{{ nfceForm.itens.length }}</span>
                        </div>
                        <v-divider :class="themeStore.currentMode === 'light' ? 'border-grey-lighten-2' : 'border-white-10'"></v-divider>
                        <div class="d-flex justify-space-between align-end mt-2">
                            <span class="text-subtitle-1 font-weight-black text-uppercase text-deep-orange">Total</span>
                            <span class="text-h4 font-weight-black text-deep-orange lh-1">{{ formatCurrency(nfceTotalValue) }}</span>
                        </div>
                    </div>
                </div>
                <div class="mt-auto pa-6 border-t d-flex flex-column gap-3" :class="themeStore.currentMode === 'light' ? 'border-grey-lighten-2' : 'border-white-10'">
                    <span class="text-caption font-weight-black text-uppercase opacity-70 letter-spacing-1">Ambiente Sefaz</span>
                    <v-btn-toggle v-model="selectedNfceEnvironment" mandatory density="comfortable" :color="themeStore.currentMode === 'light' ? 'primary' : 'success'" variant="outlined" divided class="w-100 d-flex">
                        <v-btn value="homologacao" class="text-caption font-weight-black flex-grow-1">Homologação</v-btn>
                        <v-btn value="producao" class="text-caption font-weight-black flex-grow-1">Produção</v-btn>
                    </v-btn-toggle>
                </div>
            </div>

            <div class="flex-grow-1 d-flex flex-column overflow-hidden relative" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-grey-darken-4'">
                 <div class="px-8 py-5 border-b d-flex justify-space-between align-center flex-shrink-0 z-10 shadow-sm" :class="themeStore.currentMode === 'light' ? 'bg-white border-grey-lighten-2' : 'bg-grey-darken-3 border-white-10'">
                    <div>
                        <h2 class="text-h5 font-weight-black">Conferência e Emissão</h2>
                        <p class="text-subtitle-2 font-weight-bold opacity-70 mt-1">Ref. Pedido #{{ nfceModal.orderNumber }}</p>
                    </div>
                    <v-btn icon="mdi-close" variant="flat" :color="themeStore.currentMode === 'light' ? 'grey-lighten-3' : 'grey-darken-3'" class="btn-3d" @click="nfceModal.show = false"></v-btn>
                </div>

                <div class="px-8 py-6 flex-grow-1 overflow-y-auto custom-scroll">
                    <v-form ref="nfceFormRef" @submit.prevent>

                        <div class="mb-8">
                            <div class="d-flex align-center gap-3 mb-4">
                                <v-avatar size="36" :color="themeStore.currentMode === 'light' ? 'blue-lighten-5 text-blue-darken-2' : 'blue-darken-4 text-white'" class="rounded-lg"><v-icon size="20">mdi-account-box</v-icon></v-avatar>
                                <span class="text-h6 font-weight-black text-uppercase letter-spacing-1">Consumidor <span class="opacity-50 text-caption ml-2">(Opcional)</span></span>
                            </div>
                            <v-row dense class="row-gap-sm mb-4">
                                <v-col cols="12" md="4">
                                    <label class="input-label mb-2">CPF / CNPJ</label>
                                    <v-text-field v-model="nfceForm.cpf" variant="outlined" density="comfortable" hide-details v-maska="['###.###.###-##', '##.###.###/####-##']" class="ui-field font-weight-bold" placeholder="Somente números"></v-text-field>
                                </v-col>
                                <v-col cols="12" md="8">
                                    <label class="input-label mb-2">Nome Completo</label>
                                    <v-text-field v-model="nfceForm.nome" variant="outlined" density="comfortable" hide-details class="ui-field font-weight-bold" placeholder="Nome do consumidor final"></v-text-field>
                                </v-col>
                            </v-row>
                        </div>

                        <v-divider class="mb-8 border-dashed" :class="themeStore.currentMode === 'light' ? 'border-grey-lighten-2' : 'border-white-10'"></v-divider>

                        <div class="mb-8">
                            <div class="d-flex align-center justify-space-between mb-4">
                                <div class="d-flex align-center gap-3">
                                    <v-avatar size="36" :color="themeStore.currentMode === 'light' ? 'orange-lighten-5 text-orange-darken-2' : 'orange-darken-4 text-white'" class="rounded-lg"><v-icon size="20">mdi-package-variant-closed</v-icon></v-avatar>
                                    <span class="text-h6 font-weight-black text-uppercase letter-spacing-1">Produtos</span>
                                </div>
                                <v-btn size="large" :variant="themeStore.currentMode === 'light' ? 'tonal' : 'flat'" :color="themeStore.currentMode === 'light' ? 'primary' : 'success'" prepend-icon="mdi-plus" class="font-weight-bold btn-3d" @click="addNfceItem">Adicionar Produto Manual</v-btn>
                            </div>

                            <div class="mb-6 pa-5 rounded-xl border border-dashed d-flex flex-column gap-3" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-grey-darken-3 border-white-10'">
                                <span class="text-caption font-weight-black text-uppercase" :class="themeStore.currentMode === 'light' ? 'text-primary' : 'text-success'">
                                    <v-icon size="18" class="mr-1">mdi-brightness-percent</v-icon> Calcular Faturamento Parcial
                                </span>
                                <v-btn-toggle v-model="nfcePercentage" mandatory density="comfortable" color="deep-orange" variant="outlined" divided class="d-flex flex-wrap mt-1 w-100">
                                    <v-btn v-for="pct in [10, 20, 30, 40, 50, 60, 70, 80, 90, 100]" :key="pct" :value="pct" class="text-body-2 font-weight-black flex-grow-1" :class="themeStore.currentMode === 'light' ? 'bg-white' : ''">
                                        {{ pct }}%
                                    </v-btn>
                                </v-btn-toggle>
                            </div>

                            <div class="rounded-xl border overflow-hidden shadow-sm" :class="themeStore.currentMode === 'light' ? 'bg-white border-grey-lighten-2' : 'bg-grey-darken-3 border-white-10'">
                                <div v-for="(item, idx) in nfceForm.itens" :key="idx" class="pa-5 border-b transition-colors relative" :class="themeStore.currentMode === 'light' ? 'hover-bg-grey border-grey-lighten-2' : 'border-white-10'">
                                    <v-row dense align="center" class="row-gap-sm pr-8">
                                        <v-col cols="12" md="6">
                                            <label class="input-label mb-2">Descrição do Produto</label>
                                            <v-text-field v-model="item.descricao" variant="outlined" density="comfortable" hide-details class="ui-field font-weight-black text-body-1"></v-text-field>
                                        </v-col>
                                        <v-col cols="6" md="2">
                                            <label class="input-label mb-2">NCM</label>
                                            <v-text-field v-model="item.ncm" variant="outlined" density="comfortable" hide-details class="ui-field font-mono"></v-text-field>
                                        </v-col>
                                        <v-col cols="6" md="1">
                                            <label class="input-label mb-2">CFOP</label>
                                            <v-text-field v-model="item.cfop" variant="outlined" density="comfortable" hide-details class="ui-field font-mono"></v-text-field>
                                        </v-col>
                                        <v-col cols="4" md="1">
                                            <label class="input-label mb-2">Qtd</label>
                                            <v-text-field v-model.number="item.quantidade" type="number" variant="outlined" density="comfortable" hide-details class="ui-field font-weight-black text-center"></v-text-field>
                                        </v-col>
                                        <v-col cols="4" md="2">
                                            <label class="input-label mb-2">Valor Unitário</label>
                                            <v-text-field v-model.number="item.valor_unitario" type="number" prefix="R$" variant="outlined" density="comfortable" hide-details class="ui-field font-weight-black text-right"></v-text-field>
                                        </v-col>
                                    </v-row>
                                    <v-btn icon="mdi-delete" size="small" variant="flat" color="error" class="absolute top-2 right-2 btn-3d" @click="removeNfceItem(idx)" style="top: 50%; transform: translateY(-50%);"></v-btn>
                                </div>
                            </div>
                        </div>

                        <v-divider class="mb-8 border-dashed" :class="themeStore.currentMode === 'light' ? 'border-grey-lighten-2' : 'border-white-10'"></v-divider>

                        <div class="mb-4">
                            <div class="d-flex align-center gap-3 mb-4">
                                <v-avatar size="36" :color="themeStore.currentMode === 'light' ? 'green-lighten-5 text-green-darken-2' : 'green-darken-4 text-white'" class="rounded-lg"><v-icon size="20">mdi-credit-card-outline</v-icon></v-avatar>
                                <span class="text-h6 font-weight-black text-uppercase letter-spacing-1">Pagamento (Obrigatório)</span>
                            </div>
                            <v-card variant="outlined" class="pa-6 border-dashed rounded-xl" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-grey-darken-3 border-white-10'">
                                <v-row dense class="row-gap-md">
                                    <v-col cols="12" md="6">
                                        <label class="input-label mb-2">Forma de Pagamento Sefaz</label>
                                        <v-select v-model="nfceForm.pagamento.forma" :items="nfcePaymentMethods" item-title="label" item-value="code" variant="outlined" density="comfortable" hide-details class="ui-field font-weight-bold text-body-1"></v-select>
                                    </v-col>
                                    <v-col cols="12" md="6">
                                        <label class="input-label mb-2">Valor Pago (Obrigatório bater com o total de {{ formatCurrency(nfceTotalValue) }})</label>
                                        <v-text-field v-model.number="nfceForm.pagamento.valor" type="number" prefix="R$" variant="outlined" density="comfortable" hide-details class="ui-field font-weight-black text-h6 text-success"></v-text-field>
                                    </v-col>
                                </v-row>
                            </v-card>
                        </div>

                    </v-form>
                </div>

                <div class="px-8 py-5 border-t d-flex justify-end gap-4 flex-shrink-0 align-center z-10 shadow-up" :class="themeStore.currentMode === 'light' ? 'bg-white border-grey-lighten-2' : 'bg-grey-darken-3 border-white-10'">
                     <v-btn variant="text" class="btn-3d font-weight-black text-body-1" size="large" @click="nfceModal.show = false">Cancelar</v-btn>
                     <v-btn color="deep-orange" variant="flat" class="btn-3d px-12 font-weight-black text-h6" size="x-large" :loading="nfceModal.loading" @click="submitNFCe">
                         <v-icon start size="28">mdi-send-check</v-icon> EMITIR CUPOM
                     </v-btn>
                </div>
            </div>
        </v-card>
    </v-dialog>

    <v-dialog v-model="nfceErrorDialog.show" max-width="600">
        <v-card class="rounded-lg pa-6 border-thin shadow-xl" :class="themeStore.currentMode === 'light' ? 'bg-white border-grey-lighten-2' : 'bg-grey-darken-4 text-white border-white-10'">
            <div class="d-flex align-center gap-3 mb-4 text-error">
                <v-icon size="40">mdi-alert-octagon</v-icon>
                <h3 class="text-h6 font-weight-black">Emissão Rejeitada</h3>
            </div>
            <v-alert type="error" variant="tonal" class="mb-4 text-caption font-weight-bold border-error">
                {{ nfceErrorDialog.message }}
            </v-alert>
            <div class="pa-4 rounded mb-4 overflow-auto custom-scroll shadow-inner" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-4' : 'bg-black-20'" style="max-height: 300px;">
                <pre class="text-caption font-mono" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-3' : 'text-white-70'">{{ JSON.stringify(nfceErrorDialog.details, null, 2) }}</pre>
            </div>
            <v-btn block :color="themeStore.currentMode === 'light' ? 'primary' : 'success'" variant="flat" size="large" class="font-weight-black btn-3d" @click="nfceErrorDialog.show = false">
                Entendi, vou corrigir
            </v-btn>
        </v-card>
    </v-dialog>

    <v-dialog v-model="shareModal.show" max-width="500" persistent scrim="black opacity-80">
        <v-card class="rounded-lg overflow-hidden border-thin shadow-xl" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-grey-darken-4 text-white'">
            <div class="pa-4 text-white d-flex align-center gap-3" :class="shareModal.channel === 'whatsapp' ? 'bg-green-darken-2' : 'bg-blue-darken-2'">
                <v-icon>{{ shareModal.channel === 'whatsapp' ? 'mdi-whatsapp' : 'mdi-email' }}</v-icon>
                <h3 class="text-subtitle-2 font-weight-black text-uppercase">Compartilhar {{ shareModal.docType }}</h3>
            </div>
            <v-card-text class="pa-6">
                 <div class="d-flex align-center gap-3 mb-4 pa-3 rounded-lg border-thin shadow-sm" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-4 border-grey-lighten-2' : 'bg-black-20 border-white-10'">
                    <v-icon :color="themeStore.currentMode === 'light' ? 'grey-darken-2' : 'white-70'" size="large">mdi-file-pdf-box</v-icon>
                    <div class="d-flex flex-column">
                        <span class="font-weight-black text-caption">Pedido #{{ shareModal.order?.order_number }}</span>
                        <span class="text-[10px]" :class="themeStore.currentMode === 'light' ? 'text-grey' : 'text-white-70'">Documento: {{ shareModal.docType }}</span>
                    </div>
                </div>
                <label class="input-label">Mensagem</label>
                <v-textarea v-model="shareModal.message" variant="outlined" auto-grow rows="4" density="compact" hide-details class="ui-field font-weight-medium"></v-textarea>
                <div v-if="shareModal.channel === 'whatsapp'" class="mt-3 text-caption font-weight-medium" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-1' : 'text-white-70'">
                    <v-icon size="small" start>mdi-information-outline</v-icon>
                    O PDF será baixado e o WhatsApp Web abrirá para você anexá-lo.
                </div>
            </v-card-text>
            <div class="pa-4 border-t d-flex justify-end gap-2" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5' : 'bg-grey-darken-3 border-white-10'">
                <v-btn variant="text" class="btn-3d font-weight-bold" :color="themeStore.currentMode === 'light' ? 'grey-darken-2' : 'white'" @click="shareModal.show = false" :disabled="shareModal.loading">Cancelar</v-btn>
                <v-btn :color="shareModal.channel === 'whatsapp' ? 'success' : 'info'" variant="flat" class="btn-3d font-weight-black px-6" @click="confirmShare" :loading="shareModal.loading">
                    <v-icon start>mdi-share-variant</v-icon> Enviar Agora
                </v-btn>
            </div>
        </v-card>
    </v-dialog>

    <v-dialog v-model="assignSellerModal.show" max-width="450" persistent>
        <v-card class="rounded-lg pa-4 shadow-xl border-thin" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-grey-darken-4 text-white'">
            <v-card-title class="text-h6 font-weight-black px-2 pt-2 pb-4 border-b d-flex align-center gap-2" :class="themeStore.currentMode === 'light' ? 'text-indigo border-grey-lighten-2' : 'text-indigo-lighten-2 border-white-10'">
                <v-icon>mdi-account-switch</v-icon> Atribuir Vendedor
            </v-card-title>
            <v-card-text class="px-2 py-4">
                <p class="text-body-2 font-weight-medium mb-4" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-1' : 'text-white-70'" v-if="!assignSellerModal.isBulk">
                    Selecione o vendedor que será o responsável pela venda <strong>#{{ assignSellerModal.sale?.order_number }}</strong>. Isso afetará as comissões.
                </p>
                <p class="text-body-2 font-weight-medium mb-4" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-1' : 'text-white-70'" v-else>
                    Selecione o vendedor que será o responsável pelas <strong>{{ selectedItems.length }} vendas selecionadas</strong>. Isso afetará as comissões.
                </p>
                <v-autocomplete
                    v-model="assignSellerModal.newSellerId"
                    :items="salespeopleList"
                    item-title="nome"
                    item-value="id"
                    label="Vendedor Responsável"
                    variant="outlined"
                    density="comfortable"
                    hide-details
                    class="ui-field font-weight-bold"
                ></v-autocomplete>
            </v-card-text>
            <v-card-actions class="px-2 pb-2">
                <v-spacer></v-spacer>
                <v-btn variant="text" class="btn-3d font-weight-bold" :color="themeStore.currentMode === 'light' ? 'grey' : 'white'" @click="assignSellerModal.show = false" :disabled="assignSellerModal.loading">Cancelar</v-btn>
                <v-btn :color="themeStore.currentMode === 'light' ? 'indigo' : 'indigo-lighten-1'" variant="flat" class="btn-3d font-weight-black px-6" :loading="assignSellerModal.loading" @click="confirmAssignSeller">Salvar Alteração</v-btn>
            </v-card-actions>
        </v-card>
    </v-dialog>

    <v-dialog v-model="reportModal.show" max-width="400" persistent>
        <v-card class="rounded-lg shadow-xl border-thin" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-grey-darken-4 text-white'">
            <div class="pa-4 d-flex align-center justify-space-between border-b" :class="themeStore.currentMode === 'light' ? 'bg-blue-grey-darken-3 text-white' : 'border-white-10'">
                <span class="font-weight-bold"><v-icon class="mr-2">mdi-file-chart-outline</v-icon> Relatório de Itens</span>
                <v-btn icon="mdi-close" variant="text" size="small" class="btn-3d" @click="reportModal.show = false"></v-btn>
            </div>
            <div class="pa-5">
                <p class="text-caption mb-4" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-2' : 'text-white-70'">
                    Selecione o período para gerar um PDF com todos os itens vendidos.
                </p>
                <v-text-field v-model="reportModal.startDate" label="Data Inicial" type="date" variant="outlined" density="compact" class="mb-4 ui-field" hide-details></v-text-field>
                <v-text-field v-model="reportModal.endDate" label="Data Final" type="date" variant="outlined" density="compact" class="ui-field" hide-details></v-text-field>
            </div>
            <div class="pa-4 border-t d-flex justify-end gap-2" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5' : 'bg-black-20 border-white-10'">
                <v-btn variant="text" class="font-weight-bold btn-3d" @click="reportModal.show = false">Cancelar</v-btn>
                <v-btn :color="themeStore.currentMode === 'light' ? 'blue-grey-darken-3' : 'success'" variant="flat" class="font-weight-bold btn-3d px-6" :loading="reportModal.loading" @click="generateItemsReport">Gerar PDF</v-btn>
            </div>
        </v-card>
    </v-dialog>

  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, reactive, watch } from 'vue';
import { supabase } from '@/api/supabase';
import { sefazService } from '@/api/sefazApi';
import { format, parseISO, startOfMonth, endOfMonth, startOfWeek, endOfWeek, startOfYear, endOfYear, startOfDay, endOfDay, differenceInCalendarDays } from 'date-fns';
import { useThemeStore } from '@/stores/theme';
import { useCompanyStore } from '@/stores/company';
import { useAppStore } from '@/stores/app';
import { useUserStore } from '@/stores/user';
import { useRouter } from 'vue-router';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';

// IMPORTAÇÃO DO NOVO MODAL PREMIUM
import StoreSaleDetailModal from '@/components/admin/StoreSaleDetailModal.vue';
import NfeEmissionModal from '@/components/admin/fiscal/NfeEmissionModal.vue';
import { vMaska } from "maska/vue";
import axios from 'axios';

const themeStore = useThemeStore();
const companyStore = useCompanyStore();
const appStore = useAppStore();
const userStore = useUserStore();
const router = useRouter();

const loading = ref(false);
const sales = ref<any[]>([]);
const totalSalesCount = ref(0);
const currentPageTotalValue = ref(0);
const companies = ref<any[]>([]);
const companyFilter = ref(null);
const currentPeriod = ref('month');
const page = ref(1);
const itemsPerPage = 30;
const selectedItems = ref<string[]>([]);

const filters = reactive({
    search: '',
    startDate: '',
    endDate: '',
    fiscalStatus: 'Todos',
    financialStatus: 'Todos',
    minValue: null as number | null,
    maxValue: null as number | null,
});

// NOVO STATE DO MODAL DE DETALHES E VÍNCULO DE CLIENTE
const detailModalState = reactive({ show: false });
const selectedOrder = ref<any>(null);

const linkCustomerModal = reactive({
    show: false,
    saleId: null as string | null,
    pendingAction: null as string | null,
    selectedCustomerId: null,
    customers: [] as any[],
    mode: 'search',
    loading: false,
    newCustomer: {
        nome: '',
        cpf_cnpj: '',
        telefone: ''
    }
});

// --- NFC-e STATE ---
const nfceModal = reactive({ show: false, loading: false, orderNumber: '', orderId: null as string | null });
const activeNfceCompany = ref<any>(null);
const selectedNfceEnvironment = ref('producao');

const nfcePercentage = ref(100);
const nfceOriginalItems = ref<any[]>([]);

const nfceForm = reactive({ cpf: '', nome: '', itens: [] as any[], pagamento: { forma: '01', meio: '01', valor: 0 } });
const nfceTotalValue = computed(() => nfceForm.itens.reduce((acc, item) => acc + (item.quantidade * item.valor_unitario), 0));
const nfcePaymentMethods = [{ label: 'Dinheiro', code: '01' }, { label: 'Cartão Crédito', code: '03' }, { label: 'Cartão Débito', code: '04' }, { label: 'PIX', code: '17' }];
const nfceErrorDialog = reactive({ show: false, message: '', details: null as any });

// --- NFE STATE ---
const nfeModalState = reactive({
    show: false,
    orderId: null as string | null,
    draftPayload: null as any,
    sale: null as any
});

// --- MARCAÇÃO MANUAL DE SELO ---
const markEmittedModal = reactive({
    show: false,
    saleId: null as string | null,
    type: 'NFCe',
    numero: '',
    chave: '',
    loading: false
});

// --- SHARE STATE ---
const shareModal = reactive({ show: false, message: '', order: null as any, channel: 'whatsapp', docType: 'NFe', loading: false });

// --- ASSIGN SELLER STATE ---
const salespeopleList = ref<any[]>([]);
const assignSellerModal = reactive({
    show: false,
    sale: null as any,
    newSellerId: null as string | null,
    loading: false,
    isBulk: false
});

// --- RELATORIO STATE ---
const reportModal = reactive({
    show: false,
    startDate: format(new Date(), 'yyyy-MM-dd'),
    endDate: format(new Date(), 'yyyy-MM-dd'),
    loading: false
});

const computedGridTemplate = computed(() => {
    return companyStore.isGlobalView
        ? '50px 70px 90px minmax(180px, 2fr) 120px 120px 110px 100px 110px 100px 150px'
        : '50px 70px 90px minmax(180px, 2fr) 120px 110px 100px 110px 100px 150px';
});

const tenantContextButtons = computed(() => {
    const available = companyStore.availableCompanies?.length ? companyStore.availableCompanies : companies.value;

    const mappedCompanies = (available || []).map((company: any) => {
        const label = company.trade_name || company.name || 'Empresa';
        const normalized = `${label} ${company.name || ''}`.toLowerCase();
        const isRetail = normalized.includes('santos') || normalized.includes('lopes') || normalized.includes('cajuia');
        const isIndustry = normalized.includes('jacky') || normalized.includes('mj');

        return {
            id: company.id,
            name: label,
            icon: isRetail ? 'mdi-storefront' : (isIndustry ? 'mdi-factory' : 'mdi-domain'),
            color: isRetail ? 'orange-darken-2' : (isIndustry ? 'indigo-darken-2' : 'success'),
            isHolding: false
        };
    });

    return [
        ...mappedCompanies,
        { id: 'global', name: 'HOLDING / GLOBAL', icon: 'mdi-domain', color: 'purple', isHolding: true }
    ];
});

const setTenantContext = (contextId: string) => {
    companyFilter.value = null;
    companyStore.setContext(contextId);
    selectedItems.value = [];
};

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

watch(() => filters.startDate, (val) => { if(val) currentPeriod.value = 'custom'; });
watch(() => filters.endDate, (val) => { if(val) currentPeriod.value = 'custom'; });

const clearFilters = () => {
    filters.startDate = '';
    filters.endDate = '';
    filters.fiscalStatus = 'Todos';
    filters.financialStatus = 'Todos';
    filters.minValue = null;
    filters.maxValue = null;
    filters.search = '';
    currentPeriod.value = 'month';
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

const forceNum = (val: any) => {
    if (val === null || val === undefined || val === '') return 0;
    if (typeof val === 'number') return val;
    let s = String(val).trim().replace(/R\$\s?/gi, '').replace(/\s/g, '');
    if (s.includes('.') && s.includes(',')) {
        s = s.replace(/\./g, '').replace(',', '.');
    } else if (s.includes(',')) {
        s = s.replace(',', '.');
    }
    const n = Number(s);
    return isNaN(n) ? 0 : n;
};

// BUSCA DE CLIENTES PARA VÍNCULO
const fetchCustomersQuery = async (query = '') => {
    let q = supabase.from('customers_mj').select('id, nome, cpf, cnpj').order('nome').limit(50);
    if (query && typeof query === 'string' && query.length > 1) {
        q = q.ilike('nome', `%${query}%`);
    }
    const { data } = await q;
    if (data) {
        linkCustomerModal.customers = data.map(c => ({
            id: c.id,
            name: c.nome,
            display: `${c.nome} ${c.cpf ? `(CPF: ${c.cpf})` : c.cnpj ? `(CNPJ: ${c.cnpj})` : ''}`
        }));
    }
};

const confirmLinkCustomer = async () => {
    linkCustomerModal.loading = true;
    try {
        let finalCustId = null;
        let finalCustName = '';

        if (linkCustomerModal.mode === 'new') {
            if (!linkCustomerModal.newCustomer.nome) throw new Error('Nome é obrigatório.');

            const docClean = linkCustomerModal.newCustomer.cpf_cnpj.replace(/\D/g, '');
            const isPJ = docClean.length > 11;

            const payload = {
                nome: linkCustomerModal.newCustomer.nome,
                tipo_pessoa: isPJ ? 'PJ' : 'PF',
                cpf: !isPJ && docClean ? linkCustomerModal.newCustomer.cpf_cnpj : null,
                cnpj: isPJ && docClean ? linkCustomerModal.newCustomer.cpf_cnpj : null,
                telefone: linkCustomerModal.newCustomer.telefone,
                situacao: 'Ativo'
            };

            const { data, error } = await supabase.from('customers_mj').insert([payload]).select('id, nome').single();
            if (error) throw new Error('Erro ao criar cliente: ' + error.message);

            finalCustId = data.id;
            finalCustName = data.nome;
        } else {
            if (!linkCustomerModal.selectedCustomerId) throw new Error('Selecione um cliente.');
            const c = linkCustomerModal.customers.find(x => x.id === linkCustomerModal.selectedCustomerId);
            if (!c) throw new Error('Cliente inválido.');
            finalCustId = c.id;
            finalCustName = c.name;
        }

        // Atualiza a Venda
        const { error: updErr } = await supabase.from('store_sales').update({
            customer_id: finalCustId,
            customer_name: finalCustName
        }).eq('id', linkCustomerModal.saleId);

        if (updErr) throw new Error("Erro ao atualizar venda: " + updErr.message);

        appStore.showSnackbar('Cliente vinculado com sucesso!', 'success');
        linkCustomerModal.show = false;

        await fetchSales();

        if (linkCustomerModal.pendingAction === 'faturar') {
            const sale = sales.value.find(s => s.id === linkCustomerModal.saleId);
            if (sale) await handleFaturar(sale);
        }

    } catch (e: any) {
        appStore.showSnackbar(e.message, 'error');
    } finally {
        linkCustomerModal.loading = false;
    }
};

const getSalesDateRange = () => {
    const now = new Date();
    let start: Date | null = null;
    let end: Date | null = null;

    if (currentPeriod.value === 'today') { start = startOfDay(now); end = endOfDay(now); }
    else if (currentPeriod.value === 'week') { start = startOfWeek(now, { weekStartsOn: 1 }); end = endOfWeek(now, { weekStartsOn: 1 }); }
    else if (currentPeriod.value === 'month') { start = startOfMonth(now); end = endOfMonth(now); }
    else if (currentPeriod.value === 'custom') {
        if (filters.startDate) start = startOfDay(parseISO(filters.startDate));
        if (filters.endDate) end = endOfDay(parseISO(filters.endDate));
    }

    return { start, end };
};

const escapePostgrestLike = (value: string) => value.replace(/[%_]/g, '\\$&').replace(/,/g, ' ');

const applySalesFiltersToQuery = (baseQuery: any) => {
    let query = baseQuery;

    if (!companyStore.isGlobalView && companyStore.context) {
        query = query.eq('company_id', companyStore.context);
    } else if (companyFilter.value) {
        query = query.eq('company_id', companyFilter.value);
    }

    const { start, end } = getSalesDateRange();
    if (currentPeriod.value !== 'all') {
        if (start) query = query.gte('date_sale', format(start, 'yyyy-MM-dd'));
        if (end) query = query.lte('date_sale', format(end, 'yyyy-MM-dd'));
    }

    if (filters.financialStatus !== 'Todos') {
        query = query.eq('financial_status', filters.financialStatus);
    }

    if (filters.minValue !== null && filters.minValue !== '') {
        query = query.gte('total_value', Number(filters.minValue));
    }

    if (filters.maxValue !== null && filters.maxValue !== '') {
        query = query.lte('total_value', Number(filters.maxValue));
    }

    if (filters.search && String(filters.search).trim().length > 0) {
        const raw = String(filters.search).trim();
        const safe = escapePostgrestLike(raw);
        const terms = [
            `customer_name.ilike.%${safe}%`,
            `seller_name.ilike.%${safe}%`
        ];

        if (/^\d+$/.test(raw)) {
            terms.push(`order_number.eq.${Number(raw)}`);
        }

        query = query.or(terms.join(','));
    }

    if (filters.fiscalStatus !== 'Todos') {
        const modelPrefix = '____________________';

        if (filters.fiscalStatus === 'Sem Fiscal') {
            query = query.is('nfe_key', null);
        } else if (filters.fiscalStatus === 'Com NFe') {
            query = query.or(`nfe_key.like.${modelPrefix}55%,nfe_key.eq.MANUAL_NFe,nfe_key.eq.MANUAL_NFE`);
        } else if (filters.fiscalStatus === 'Com NFCe') {
            query = query.or(`nfe_key.like.${modelPrefix}65%,nfe_key.eq.MANUAL_NFCe,nfe_key.eq.MANUAL_NFCE`);
        }
    }

    return query;
};

const mergeById = (...lists: any[][]) => {
    const map = new Map<string, any>();
    lists.flat().filter(Boolean).forEach((item: any) => {
        if (item?.id) map.set(item.id, item);
    });
    return Array.from(map.values());
};

const hydrateSalesPage = async (salesData: any[]) => {
    if (!salesData.length) return [];

    const fiscalKeys = salesData
        .map(s => s.nfe_key)
        .filter((key: string) => key && !String(key).startsWith('MANUAL_'));

    let nfeData: any[] = [];
    let nfceData: any[] = [];

    if (fiscalKeys.length > 0) {
        try {
            const [{ data: nfeByKey }, { data: nfceByKey }] = await Promise.all([
                supabase.from('nfe_outbound').select('id, chave, pdf_link, retorno_sefaz, status').in('status', ['AUTORIZADA', 'autorizado']).in('chave', fiscalKeys),
                supabase.from('nfce_outbound').select('id, chave, pdf_link, retorno_sefaz, status').in('status', ['AUTORIZADA', 'autorizado']).in('chave', fiscalKeys)
            ]);

            nfeData = nfeByKey || [];
            nfceData = nfceByKey || [];
        } catch (e) {
            // Sem erro visual no console para usuário: se a nota não puder ser hidratada por chave,
            // mantém o selo com a própria chave salva na venda.
            nfeData = [];
            nfceData = [];
        }
    }

    return salesData.map(sale => {
        let calcStatus = sale.financial_status || 'Pendente';

        let fiscalDoc = { found: false, type: '', key: '', pdf: '', nuvem_id: '' };

        if (sale.nfe_key) {
            if (sale.nfe_key.startsWith('MANUAL_')) {
                const typeStr = sale.nfe_key.replace('MANUAL_', '');
                fiscalDoc = { found: true, type: typeStr, key: sale.nfe_key, pdf: '', nuvem_id: '' };
            } else {
                let doc = (nfceData || []).find(d => d.chave === sale.nfe_key);
                if (doc) {
                    fiscalDoc = { found: true, type: 'NFCe', key: doc.chave, pdf: doc.pdf_link, nuvem_id: doc.retorno_sefaz?.id_nuvem || doc.retorno_sefaz?.id };
                } else {
                    doc = (nfeData || []).find(d => d.chave === sale.nfe_key);
                    if (doc) {
                        fiscalDoc = { found: true, type: 'NFe', key: doc.chave, pdf: doc.pdf_link, nuvem_id: doc.retorno_sefaz?.id_nuvem || doc.retorno_sefaz?.id };
                    } else {
                        const isNfe = sale.nfe_key.length === 44 && sale.nfe_key.substring(20, 22) === '55';
                        fiscalDoc = { found: true, type: isNfe ? 'NFe' : 'NFCe', key: sale.nfe_key, pdf: '', nuvem_id: '' };
                    }
                }
            }
        }

        // A tela não consulta mais finance_receivables em massa ao carregar a página.
        // Isso remove os 400 no F12 e deixa o status financeiro vindo da própria venda paginada.
        if (fiscalDoc.found && sale.financial_status !== 'Pendente' && sale.financial_status !== 'Cancelado') {
            calcStatus = 'Faturado';
        }

        return {
            ...sale,
            financial_status: calcStatus,
            item_count: sale.items?.length || 0,
            fiscal_doc: fiscalDoc
        };
    });
};

const fetchSales = async () => {
    loading.value = true;

    try {
        const from = (page.value - 1) * itemsPerPage;
        const to = from + itemsPerPage - 1;

        let query = supabase.from('store_sales').select('*', { count: 'exact' });
        query = applySalesFiltersToQuery(query);

        const { data: salesData, error, count } = await query
            .order('order_number', { ascending: false })
            .range(from, to);

        if (error) throw error;

        const total = count || 0;
        const lastPage = Math.max(1, Math.ceil(total / itemsPerPage));

        if (page.value > lastPage) {
            page.value = lastPage;
            return;
        }

        totalSalesCount.value = total;
        const hydratedSales = await hydrateSalesPage(salesData || []);
        sales.value = hydratedSales;
        currentPageTotalValue.value = hydratedSales.reduce((acc, sale) => acc + (Number(sale.total_value) || 0), 0);

        const currentIds = new Set(hydratedSales.map(s => s.id));
        selectedItems.value = selectedItems.value.filter(id => currentIds.has(id));

    } catch (e) {
        console.error("Erro ao buscar vendas:", e);
        sales.value = [];
        totalSalesCount.value = 0;
        currentPageTotalValue.value = 0;
    } finally {
        loading.value = false;
    }
};

const fetchCompanies = async () => {
    const { data } = await supabase.from('companies').select('*');
    if (data) {
        companies.value = data;
        if(companies.value.length > 0) activeNfceCompany.value = companies.value[0];
    }
};

const fetchSalespeople = async () => {
    try {
        const { data } = await supabase.from('profiles').select('id, full_name').order('full_name');
        if (data) salespeopleList.value = data.map(p => ({ id: p.id, nome: p.full_name }));
    } catch (e) { console.error('Erro ao buscar vendedores:', e); }
};

const filteredSales = computed(() => sales.value);

const paginatedSales = computed(() => sales.value);

const totalPages = computed(() => Math.max(1, Math.ceil(totalSalesCount.value / itemsPerPage)));
const filteredTotalValue = computed(() => currentPageTotalValue.value);

const selectAll = computed(() => {
    if (paginatedSales.value.length === 0) return false;
    return paginatedSales.value.every(i => selectedItems.value.includes(i.id));
});

const toggleSelectAll = (val: boolean) => {
    const currentIds = paginatedSales.value.map(i => i.id);
    if (val) {
        const newSet = new Set([...selectedItems.value, ...currentIds]);
        selectedItems.value = Array.from(newSet);
    } else {
        selectedItems.value = selectedItems.value.filter(id => !currentIds.includes(id));
    }
};

const selectedTotalValue = computed(() => {
    return sales.value
        .filter(s => selectedItems.value.includes(s.id))
        .reduce((acc, s) => acc + (Number(s.total_value) || 0), 0);
});


const openDetailModal = (item: any) => {
    selectedOrder.value = { ...item };
    detailModalState.show = true;
};

const handleFaturar = async (sale: any) => {
    try {
        if (!sale.customer_id || String(sale.customer_id).length < 10) {
            linkCustomerModal.saleId = sale.id;
            linkCustomerModal.pendingAction = 'faturar';
            linkCustomerModal.mode = 'search';
            linkCustomerModal.selectedCustomerId = null;
            linkCustomerModal.newCustomer = { nome: '', cpf_cnpj: '', telefone: '' };
            linkCustomerModal.show = true;
            await fetchCustomersQuery();
            return;
        }

        loading.value = true;

        const { data: existingReceivables } = await supabase.from('finance_receivables')
            .select('*').eq('store_sale_id', sale.id);

        if (!existingReceivables || existingReceivables.length === 0) {
            const { data: chartData } = await supabase.from('finance_chart_of_accounts')
                .select('id').eq('type', 'Receita').ilike('name', '%Venda%').limit(1).maybeSingle();

            const { data: bankData } = await supabase.from('finance_accounts')
                .select('id').eq('is_active', true).limit(1).maybeSingle();

            const { data: methodData } = await supabase.from('finance_payment_methods')
                .select('id').limit(1).maybeSingle();

            const newReceivable: any = {
                store_sale_id: sale.id,
                order_number: Number(sale.order_number),
                description: `Venda Loja #${sale.order_number}`,
                value: forceNum(sale.total_value),
                paid_value: forceNum(sale.total_value),
                status: 'pago',
                payment_date: new Date().toISOString().split('T')[0],
                paid_at: new Date().toISOString(),
                due_date: sale.date_sale ? sale.date_sale.split('T')[0] : new Date().toISOString().split('T')[0],
                competence_date: sale.date_sale ? sale.date_sale.split('T')[0] : new Date().toISOString().split('T')[0],
                company_id: sale.company_id || null,
                customer_id: sale.customer_id,
                entity_name: sale.customer_name || 'Consumidor Final',
                created_by: userStore.user?.id || null
            };

            if (chartData) newReceivable.chart_of_accounts_id = chartData.id;
            if (bankData) newReceivable.bank_account_id = bankData.id;
            if (methodData) newReceivable.payment_method_id = methodData.id;

            const { error: insErr } = await supabase.from('finance_receivables').insert([newReceivable]);
            if (insErr) throw new Error("Erro ao criar financeiro: " + insErr.message);
        } else {
            const ids = existingReceivables.filter(r => r.status === 'em_aberto' || r.status === 'pendente').map(r => r.id);
            if (ids.length > 0) {
                const { error: upErr } = await supabase.from('finance_receivables').update({
                    status: 'pago',
                    payment_date: new Date().toISOString().split('T')[0],
                    paid_at: new Date().toISOString(),
                    paid_value: forceNum(sale.total_value)
                }).in('id', ids);
                if (upErr) throw new Error("Erro ao baixar parcelas: " + upErr.message);
            }
        }

        const { error: updateErr } = await supabase.from('store_sales').update({ financial_status: 'Faturado' }).eq('id', sale.id);
        if (updateErr) throw new Error("Erro ao atualizar venda: " + updateErr.message);

        appStore.showSnackbar('Venda faturada e lançada no financeiro com sucesso!', 'success');
        detailModalState.show = false;
        fetchSales();
    } catch (e: any) {
        appStore.showSnackbar(e.message, 'error');
        console.error(e);
    } finally {
        loading.value = false;
    }
};

const reopenFinancial = async (item: any) => {
    if (!confirm(`ATENÇÃO: Deseja reabrir o financeiro da venda #${item.order_number}?\n\nIsso mudará o status para PENDENTE e excluirá as parcelas atuais do Contas a Receber para que você possa lançá-las novamente.\n\nO selo fiscal (NFe/NFCe) será MANTIDO intacto.`)) {
        return;
    }

    loading.value = true;
    try {
        await supabase.from('finance_receivables').delete().eq('store_sale_id', item.id);

        await supabase.from('store_sales').update({
            financial_status: 'Pendente'
        }).eq('id', item.id);

        appStore.showSnackbar('Financeiro reaberto! Você já pode lançar as parcelas novamente.', 'success');
        fetchSales();
    } catch (e: any) {
        console.error(e);
        appStore.showSnackbar('Erro ao reabrir financeiro.', 'error');
    } finally {
        loading.value = false;
    }
};

const removeFinancialBySaleDescription = async (sale: any) => {
    const orderNumber = sale?.order_number;
    if (!orderNumber) return;

    let query = supabase
        .from('finance_receivables')
        .delete()
        .ilike('description', `%${orderNumber}%`);

    if (sale?.company_id) {
        query = query.eq('company_id', sale.company_id);
    }

    const { error } = await query;

    if (error) {
        console.warn('Não foi possível remover parcelas pelo número do pedido:', error.message);
    }
};


const deleteOrder = async (item: any) => {
    if (!confirm(`Cancelar a venda #${item.order_number}?\n\nA venda ficará com status CANCELADO e as parcelas vinculadas serão removidas do financeiro.`)) return;

    loading.value = true;
    try {
        await removeFinancialBySaleDescription(item);

        const { error } = await supabase
            .from('store_sales')
            .update({
                status: 'cancelled',
                financial_status: 'Cancelado',
                updated_at: new Date().toISOString()
            })
            .eq('id', item.id);

        if (error) throw error;

        appStore.showSnackbar('Venda cancelada e financeiro removido.', 'success');
        fetchSales();
    } catch (e: any) {
        console.error(e);
        appStore.showSnackbar(e.message || 'Erro ao cancelar venda.', 'error');
    } finally {
        loading.value = false;
    }
};


const openAssignSeller = (item: any) => {
    assignSellerModal.isBulk = false;
    assignSellerModal.sale = item;
    assignSellerModal.newSellerId = item.seller_id || null;
    assignSellerModal.show = true;
};
const openBulkAssignSeller = () => {
    if (selectedItems.value.length === 0) return;
    assignSellerModal.isBulk = true;
    assignSellerModal.sale = null;
    assignSellerModal.newSellerId = null;
    assignSellerModal.show = true;
};
const confirmAssignSeller = async () => {
    if (!assignSellerModal.newSellerId) return appStore.showSnackbar('Selecione um vendedor.', 'warning');
    assignSellerModal.loading = true;
    try {
        const selectedSeller = salespeopleList.value.find(s => s.id === assignSellerModal.newSellerId);
        const payload = { seller_id: assignSellerModal.newSellerId, seller_name: selectedSeller ? selectedSeller.nome : null };
        if (assignSellerModal.isBulk) {
            await supabase.from('store_sales').update(payload).in('id', selectedItems.value);
            appStore.showSnackbar(`${selectedItems.value.length} vendas atribuídas!`, 'success');
            selectedItems.value = [];
        } else {
            await supabase.from('store_sales').update(payload).eq('id', assignSellerModal.sale.id);
            appStore.showSnackbar('Venda atribuída com sucesso!', 'success');
        }
        assignSellerModal.show = false;
        fetchSales();
    } catch (e: any) { appStore.showSnackbar('Erro: ' + e.message, 'error'); } finally { assignSellerModal.loading = false; }
};

const bulkUpdateFinancial = async (status: string) => {
    if (selectedItems.value.length === 0) return;
    if (!confirm(`Alterar status de ${selectedItems.value.length} vendas para "${status}"?`)) return;
    loading.value = true;
    try {
        await supabase.from('store_sales').update({ financial_status: status }).in('id', selectedItems.value);
        appStore.showSnackbar(`${selectedItems.value.length} vendas atualizadas.`, "success");
        selectedItems.value = [];
        fetchSales();
    } catch (e) { appStore.showSnackbar("Erro na atualização.", "error"); } finally { loading.value = false; }
};

const bulkDelete = async () => {
    if (selectedItems.value.length === 0) return;
    if (!confirm(`Cancelar ${selectedItems.value.length} venda(s) selecionada(s)?\n\nAs vendas ficarão com status CANCELADO e as parcelas vinculadas serão removidas do financeiro.`)) return;

    loading.value = true;
    try {
        const selectedSales = sales.value.filter(s => selectedItems.value.includes(s.id));

        for (const sale of selectedSales) {
            await removeFinancialBySaleDescription(sale);
        }

        const { error } = await supabase
            .from('store_sales')
            .update({
                status: 'cancelled',
                financial_status: 'Cancelado',
                updated_at: new Date().toISOString()
            })
            .in('id', selectedItems.value);

        if (error) throw error;

        appStore.showSnackbar('Vendas canceladas e parcelas removidas do financeiro.', 'success');
        selectedItems.value = [];
        fetchSales();
    } catch(e: any) {
        console.error(e);
        appStore.showSnackbar(e.message || 'Erro ao cancelar vendas.', 'error');
    } finally {
        loading.value = false;
    }
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

const printOrder = async (row: any) => {
  try {
    const brDate = (d: any) => { if (!d) return ""; try { const iso = String(d); const date = iso.includes("T") ? parseISO(iso) : parseISO(`${iso}T00:00:00`); return format(date, "dd/MM/yyyy"); } catch { return String(d); } };
    const num = (val: number) => new Intl.NumberFormat("pt-BR", { minimumFractionDigits: 2, maximumFractionDigits: 2 }).format(Number(val || 0));
    const money = (val: number) => new Intl.NumberFormat("pt-BR", { style: "currency", currency: "BRL" }).format(Number(val || 0));

    const doc = new jsPDF({ orientation: "p", unit: "mm", format: "a4" });
    const pageW = doc.internal.pageSize.getWidth();
    const pageH = doc.internal.pageSize.getHeight();
    const M = 10;
    const boxW = pageW - M * 2;

    const COMPANY = { name: "CONFECCOES MJ - LOJA", cnpj: "53.756.096/0001-89", address: "RUA LUIZ MONTANHAN, 1302", city: "Tietê/SP", phones: "(15) 99847-8789" };

    const topY = 10;
    const headerH = 26;
    doc.setDrawColor(180); doc.setLineWidth(0.3); doc.rect(M, topY, boxW, headerH);
    try { const logoBase64 = await imageToBase64("https://cdn.shopify.com/s/files/1/0661/4574/6991/files/Sem_nome_1080_x_800_px_1080_x_500_px_1080_x_400_px_1000_x_380_px_da020cf2-2bb9-4dac-8dd3-4548cfd2e5ae.png?v=1756811713"); doc.addImage(logoBase64, "PNG", M + 3, topY + 4, 30, 16); } catch (e) { /* ignore */ }

    doc.setFont("helvetica", "bold"); doc.setFontSize(11); doc.text(COMPANY.name, M + 38, topY + 9);
    doc.setFont("helvetica", "normal"); doc.setFontSize(8.5);
    doc.text(`CNPJ: ${COMPANY.cnpj}`, M + 38, topY + 14); doc.text(COMPANY.address, M + 38, topY + 18);
    const rightX = pageW - M;
    doc.text(COMPANY.phones, rightX, topY + 9, { align: "right" });
    doc.text(`Vendedor: ${row.seller_name || 'Sistema'}`, rightX, topY + 19, { align: "right" });

    const barY = topY + headerH + 6;
    const barH = 8;
    doc.setFillColor(230); doc.rect(M, barY, boxW, barH, "F"); doc.setDrawColor(180); doc.rect(M, barY, boxW, barH);
    doc.setFont("helvetica", "bold"); doc.setFontSize(11);
    doc.text(`PEDIDO LOJA N° ${row.order_number}`, pageW / 2, barY + 5.5, { align: "center" });
    doc.setFontSize(10); doc.text(brDate(row.date_sale), pageW - M - 2, barY + 5.5, { align: "right" });

    const clientBoxY = barY + barH + 6;
    doc.setFont("helvetica", "bold"); doc.setFontSize(9.5);
    doc.setFillColor(230); doc.rect(M, clientBoxY, boxW, 7, "F"); doc.setDrawColor(180); doc.rect(M, clientBoxY, boxW, 7);
    doc.text("DADOS DO CLIENTE", M + 2, clientBoxY + 5);

    const cName = row.customer_name || 'Consumidor Final';
    const cDoc = '—';
    const clientRows = [ ["Cliente:", cName, "CNPJ/CPF:", cDoc] ];

    autoTable(doc, {
        startY: clientBoxY + 7, theme: "grid", tableWidth: boxW, margin: { left: M, right: M },
        styles: { fontSize: 8.5, cellPadding: 1.5, textColor: 0, lineColor: [200, 200, 200], lineWidth: 0.2, minCellHeight: 7, valign: "middle" },
        bodyStyles: { fillColor: [255, 255, 255] },
        columnStyles: { 0: { cellWidth: 20, fontStyle: "bold" }, 1: { cellWidth: 75 }, 2: { cellWidth: 20, fontStyle: "bold" }, 3: { cellWidth: 75 } },
        body: clientRows
    });

    let lastY = (doc as any).lastAutoTable.finalY + 5;

    doc.setFont("helvetica", "bold"); doc.setFontSize(9.5);
    doc.setFillColor(230); doc.setDrawColor(180); doc.rect(M, lastY, boxW, 7, "F"); doc.rect(M, lastY, boxW, 7);
    doc.setTextColor(0); doc.text("PRODUTOS", M + 2, lastY + 5);

    const items = row.items || [];
    const productsBody = items.map((it: any, idx: number) => {
        const desc = it.produto?.nome_produto || it.nome_produto || it.descricao || 'Item';
        const qtd = Number(it.produto?.quantidade || it.quantidade || 0);
        const unit = Number(it.produto?.valor_unitario || it.valor_unitario || 0);
        const subtotal = Number(it.produto?.valor_total || it.valor_total || (qtd * unit));

        return [ String(idx + 1), it.codigo || it.produto?.codigo || '—', desc, 'UN', num(qtd), num(unit), num(subtotal) ];
    });

    const totalQtd = items.reduce((acc: number, it: any) => acc + Number(it.produto?.quantidade || it.quantidade || 0), 0);
    const totalVal = Number(row.total_value);

    autoTable(doc, {
        startY: lastY + 7, theme: "grid", tableWidth: boxW, margin: { left: M, right: M },
        headStyles: { fillColor: [245, 245, 245], textColor: 0, fontStyle: "bold", fontSize: 8.5, valign: "middle" },
        styles: { fontSize: 8.3, cellPadding: 1.5, lineColor: [200, 200, 200], lineWidth: 0.2, textColor: 0, minCellHeight: 7, valign: "middle" },
        columnStyles: { 0: { cellWidth: 10, halign: "center" }, 1: { cellWidth: 20 }, 2: { cellWidth: 'auto' }, 3: { cellWidth: 15, halign: "center" }, 4: { cellWidth: 20, halign: "right" }, 5: { cellWidth: 25, halign: "right" }, 6: { cellWidth: 30, halign: "right" } },
        head: [["ITEM", "CÓDIGO", "DESCRIÇÃO", "UND", "QTD", "VR. UNIT", "SUBTOTAL"]],
        body: productsBody.length ? productsBody : [["—", "—", "Nenhum item", "—", "0", "0,00", "0,00"]],
        foot: [["TOTAL", "", "", "", "", num(totalQtd), "", num(totalVal)]],
        footStyles: { fillColor: [240, 240, 240], fontStyle: "bold", halign: "right", valign: "middle" }
    });

    const afterProductsY = (doc as any).lastAutoTable.finalY + 4;
    const rightBoxW = 70;
    const rightBoxX = pageW - M - rightBoxW;
    const totalsBoxH = 14;
    doc.setFillColor(230); doc.rect(rightBoxX, afterProductsY, rightBoxW, totalsBoxH, "F"); doc.setDrawColor(180); doc.rect(rightBoxX, afterProductsY, rightBoxW, totalsBoxH);
    doc.setFont("helvetica", "bold"); doc.setFontSize(9);
    doc.text(`TOTAL PEDIDO: ${money(totalVal)}`, rightBoxX + rightBoxW - 2, afterProductsY + 9, { align: "right" });

    const afterTotalsY = afterProductsY + totalsBoxH + 10;
    const signH = 18;
    let signY = afterTotalsY;
    if (signY + signH > pageH - M) { doc.addPage(); signY = M + 10; }
    doc.setDrawColor(0); doc.setLineWidth(0.3); doc.rect(M, signY, boxW, signH);
    doc.setDrawColor(120); doc.line(M + 50, signY + 12, M + boxW - 50, signY + 12);
    doc.setFont("helvetica", "normal"); doc.setFontSize(8); doc.text("Assinatura do cliente", pageW / 2, signY + 16, { align: "center" });

    doc.save(`Pedido_Loja_${row.order_number}.pdf`);
    appStore.showSnackbar("PDF gerado com sucesso.", "success");

  } catch (e: any) { console.error("printOrder error:", e); appStore.showSnackbar(`Erro ao gerar PDF: ${e?.message || e}`, "error"); }
};

const openMarkEmitted = (item: any, type: string) => {
    if (item.fiscal_doc?.found) {
        return appStore.showSnackbar(`Este pedido já possui uma ${item.fiscal_doc.type} vinculada.`, "warning");
    }
    markEmittedModal.saleId = item.id;
    markEmittedModal.type = type;
    markEmittedModal.numero = item.nfe_number || '';
    markEmittedModal.chave = item.nfe_key || '';
    markEmittedModal.show = true;
};

const confirmMarkEmitted = async () => {
    markEmittedModal.loading = true;
    try {
        const finalKey = markEmittedModal.chave || `MANUAL_${markEmittedModal.type}`;
        const finalNum = markEmittedModal.numero || 'S/N';

        await supabase.from('store_sales').update({
            nfe_number: finalNum,
            nfe_key: finalKey,
            financial_status: 'Faturado'
        }).eq('id', markEmittedModal.saleId);

        appStore.showSnackbar('Selo aplicado com sucesso!', 'success');
        markEmittedModal.show = false;
        fetchSales();
    } catch(e) {
        appStore.showSnackbar('Erro ao aplicar selo.', 'error');
    } finally {
        markEmittedModal.loading = false;
    }
};

const openNfeModal = async (item: any) => {
    if (item.fiscal_doc?.found) {
        return appStore.showSnackbar(`Atenção: Já existe uma ${item.fiscal_doc.type} autorizada para este pedido!`, "warning");
    }

    appStore.showSnackbar("Carregando dados no emissor...", "info");

    nfeModalState.sale = item;
    nfeModalState.orderId = item.id;
    nfeModalState.draftPayload = null;
    nfeModalState.show = true;
};

const handleNfeSuccess = async () => {
    if (!nfeModalState.sale) { fetchSales(); return; }
    try {
        const { data } = await supabase.from('nfe_outbound')
            .select('numero, chave')
            .eq('valor_total', nfeModalState.sale.total_value)
            .order('created_at', { ascending: false }).limit(1).maybeSingle();

        if (data) {
            await supabase.from('store_sales').update({ nfe_number: String(data.numero), nfe_key: data.chave, financial_status: 'Faturado' }).eq('id', nfeModalState.sale.id);
        } else {
             await supabase.from('store_sales').update({ financial_status: 'Faturado' }).eq('id', nfeModalState.sale.id);
        }
    } catch (e) { console.error('Erro NFe DB:', e); }
    fetchSales();
};

const openNfceDialog = async (item: any, withName = true) => {
    if (item.fiscal_doc?.found) {
        return appStore.showSnackbar(`Atenção: Já existe uma ${item.fiscal_doc.type} autorizada para este pedido!`, "warning");
    }

    nfceModal.orderId = item.id;
    nfceModal.orderNumber = item.order_number;
    nfcePercentage.value = 100;
    nfceOriginalItems.value = [];
    selectedNfceEnvironment.value = 'producao';
    activeNfceCompany.value = companies.value.find(c => c.id === item.company_id) || companies.value[0];

    if (!activeNfceCompany.value) return appStore.showSnackbar("Erro: Nenhuma empresa emissora configurada.", "error");

    nfceForm.cpf = ''; nfceForm.nome = ''; nfceForm.itens = [];

    appStore.showSnackbar("Carregando dados da venda...", "info");

    if (withName && item.customer_name) {
        nfceForm.nome = item.customer_name;
        if (item.customer_id) {
            const { data: c } = await supabase.from('customers_mj').select('cpf, cnpj').eq('id', item.customer_id).maybeSingle();
            if (c) { nfceForm.cpf = c.cpf || c.cnpj || ''; }
        } else {
            const { data: c } = await supabase.from('customers_mj').select('cpf, cnpj').ilike('nome', `%${item.customer_name}%`).limit(1).maybeSingle();
            if (c) { nfceForm.cpf = c.cpf || c.cnpj || ''; }
        }
    }

    let items = item.items || [];
    if (!items || items.length === 0) {
        try {
            const { data: fetchedItems } = await supabase.from('store_sale_items').select('*').eq('store_sale_id', item.id);
            if(fetchedItems && fetchedItems.length > 0) items = fetchedItems;
        } catch(e) {}
    }

    if (!items || items.length === 0) {
        appStore.showSnackbar("Adicione-os manualmente.", "warning");
    } else {
        const { data: stockData } = await supabase.from('stock').select('fabric_type, ncm');
        nfceForm.itens = items.map((i: any) => {
            const baseDesc = i.produto?.nome_produto || i.nome_produto || i.nome || i.descricao || i.name || i.fabric_type || 'Item Diverso';
            const tamanho = i.produto?.tamanho || i.tamanho || i.size || '';
            const descFinal = tamanho ? `${baseDesc} - TAM: ${tamanho}` : baseDesc;

            let qtd = forceNum(i.produto?.quantidade ?? i.quantidade ?? i.quantity ?? i.quantity_meters ?? 1);
            if (qtd <= 0) qtd = 1;
            let val = forceNum(i.produto?.valor_unitario ?? i.valor_unitario ?? i.preco_unitario ?? i.unit_price ?? i.produto?.preco ?? i.preco ?? i.produto?.price ?? i.price ?? i.valor);
            if (val === 0) {
                const subtotal = forceNum(i.total_value_items ?? i.total ?? i.valor_total ?? i.produto?.valor_total ?? i.subtotal ?? i.total_price);
                if (subtotal > 0) val = subtotal / qtd;
            }
            if (val === 0 && item.total_value > 0) val = forceNum(item.total_value) / items.length / qtd;
            const stockMatch = (stockData || []).find((p: any) => p.fabric_type === baseDesc || p.fabric_type === i.fabric_type);
            const ncm = stockMatch?.ncm || i.ncm || '61091000';

            return { descricao: descFinal, ncm: ncm, cfop: '5102', quantidade: qtd, valor_unitario: Number(val.toFixed(4)) };
        });
        nfceOriginalItems.value = JSON.parse(JSON.stringify(nfceForm.itens));
    }
    nfceModal.show = true;
};

const submitNFCe = async () => {
    if (!activeNfceCompany.value) return appStore.showSnackbar("Empresa não selecionada.", "error");
    if (nfceForm.itens.length === 0) return appStore.showSnackbar("Adicione itens.", "warning");

    nfceModal.loading = true;

    try {
        const { data: companyData } = await supabase.from('companies').select('nfce_next_number, nfce_series, nfe_environment, crt').eq('id', activeNfceCompany.value.id).single();
        if (companyData) { activeNfceCompany.value.nfce_next_number = companyData.nfce_next_number; activeNfceCompany.value.nfce_series = companyData.nfce_series; activeNfceCompany.value.crt = companyData.crt; }

        const cleanDoc = nfceForm.cpf.replace(/\D/g, '');
        const emitenteCnpjLimpo = activeNfceCompany.value.cnpj.replace(/\D/g, '');

        const cleanName = nfceForm.nome ? nfceForm.nome.trim().replace(/\s+/g, ' ') : '';

        let destinatarioPayload = null;
        if (cleanDoc || cleanName) {
            destinatarioPayload = { indIEDest: 9 };

            if (cleanDoc) destinatarioPayload.cnpj_cpf = cleanDoc;

            if (cleanName && cleanName.length >= 2) {
                destinatarioPayload.nome = cleanName;
            } else if (cleanDoc) {
                destinatarioPayload.nome = 'CONSUMIDOR';
            }
        }

        const payload = {
            ambiente: selectedNfceEnvironment.value,
            serie: activeNfceCompany.value.nfce_series || 1,
            numero: (activeNfceCompany.value.nfce_next_number || 1),
            crt: activeNfceCompany.value.crt || 1,
            destinatario: destinatarioPayload,
            itens: nfceForm.itens.map((i, idx) => ({ ...i, codigo_produto: `ITEM${idx+1}`, ncm: i.ncm.replace(/\D/g, ''), cfop: i.cfop.replace(/\D/g, '') })),
            pagamentos: [{ forma_pagamento: nfceForm.pagamento.forma, valor: nfceTotalValue.value }],
            valor_total: nfceTotalValue.value,
            referencia: `PDV-${nfceModal.orderNumber}-${Date.now()}`,
            orderId: nfceModal.orderId
        };

        let result;
        try {
            result = await sefazService.emitirNFCe(payload, activeNfceCompany.value.cnpj, activeNfceCompany.value.ie);
        } catch (apiErr: any) {
            const msg = apiErr.message || ''; const details = apiErr.response?.data || apiErr.details || apiErr;
            if (msg.includes('Autorizado') || details?.status === 'autorizado') result = details; else throw apiErr;
        }

        const statusFinal = result.status_sefaz || result.status;
        const isAuthorized = (statusFinal === 'autorizado' || statusFinal === 'AUTORIZADA');
        const idNota = result.id || result.id_nuvem;
        let pdfUrl = ''; if (idNota) pdfUrl = sefazService.getProxyNfceDownloadUrl('pdf', idNota);

        await supabase.from('nfce_outbound').insert({
            emitente_cnpj: emitenteCnpjLimpo, numero: result.numero || payload.numero, valor_total: nfceTotalValue.value,
            status: isAuthorized ? 'AUTORIZADA' : 'REJEITADA', chave: result.chave || result.autorizacao?.chave_acesso,
            pdf_link: pdfUrl, ambiente: payload.ambiente, destinatario_nome: nfceForm.nome || 'Consumidor Final', retorno_sefaz: result
        });

        if (!isAuthorized) { nfceErrorDialog.message = result.motivo || result.message || 'Erro na emissão'; nfceErrorDialog.details = result; nfceErrorDialog.show = true; return; }

        appStore.showSnackbar(`NFC-e ${result.numero || payload.numero} emitida!`, 'success');
        const nextNum = Number(result.numero || payload.numero) + 1;
        await supabase.from('companies').update({ nfce_next_number: nextNum }).eq('id', activeNfceCompany.value.id);

        if (nfceModal.orderId) {
            await supabase.from('store_sales').update({
                nfe_number: String(result.numero || payload.numero),
                financial_status: 'Faturado',
                nfe_key: result.chave || result.autorizacao?.chave_acesso
            }).eq('id', nfceModal.orderId);

            const localSale = sales.value.find(s => s.id === nfceModal.orderId);
            if (localSale) {
                localSale.nfe_number = String(result.numero || payload.numero);
                localSale.nfe_key = result.chave || result.autorizacao?.chave_acesso;
                localSale.financial_status = 'Faturado';
                localSale.fiscal_doc = {
                    found: true,
                    type: 'NFCe',
                    key: localSale.nfe_key,
                    pdf: pdfUrl,
                    nuvem_id: idNota
                };
            }
        }

        nfceModal.show = false;
        fetchSales();
        if (pdfUrl) window.open(pdfUrl, '_blank'); else appStore.showSnackbar("Nota autorizada, mas ID para download não encontrado.", "warning");

    } catch (e: any) {
        nfceErrorDialog.message = e.message || "Erro desconhecido"; nfceErrorDialog.details = e.response?.data || e; nfceErrorDialog.show = true;
    } finally { nfceModal.loading = false; }
};

const downloadFiscalDoc = async (item: any) => {
    if (!item.fiscal_doc?.found) return;
    if (item.fiscal_doc.key && item.fiscal_doc.key.includes('MANUAL')) {
        return appStore.showSnackbar("Esta nota foi marcada manualmente e não possui PDF vinculado no sistema.", "warning");
    }
    if (item.fiscal_doc.pdf) { window.open(item.fiscal_doc.pdf, '_blank'); return; }
    try {
        const idNuvem = item.fiscal_doc.nuvem_id;
        if(!idNuvem) throw new Error("ID Nuvem não encontrado para este documento.");
        const endpointMethod = item.fiscal_doc.type === 'NFCe' ? 'getProxyNfceDownloadUrl' : 'getProxyDownloadUrl';
        const url = sefazService[endpointMethod]('pdf', idNuvem);
        window.open(url, '_blank');
    } catch (e: any) { appStore.showSnackbar("Erro ao abrir documento: " + e.message, "error"); }
};

const openShareModal = async (item: any, channel: any, type: any) => {
    shareModal.order = item; shareModal.channel = channel; shareModal.docType = type;
    shareModal.show = true;
    shareModal.message = `Olá! Segue documento referente ao pedido #${item.order_number}.`;
};

const confirmShare = async () => {
    if (!shareModal.order) return;
    shareModal.loading = true;
    try {
        const order = shareModal.order;
        if (order.fiscal_doc?.key?.includes('MANUAL')) {
            throw new Error("Não é possível compartilhar um documento marcado manualmente (PDF inexistente).");
        }

        let file = null;

        if (order.fiscal_doc?.pdf) {
             const response = await axios.get(order.fiscal_doc.pdf, { responseType: 'blob' });
             file = new File([response.data], `${shareModal.docType}_${order.order_number}.pdf`, { type: 'application/pdf' });
        } else if (order.fiscal_doc?.nuvem_id) {
             const idNuvem = order.fiscal_doc.nuvem_id;
             const endpointMethod = shareModal.docType === 'NFCe' ? 'getProxyNfceDownloadUrl' : 'getProxyDownloadUrl';
             const url = sefazService[endpointMethod]('pdf', idNuvem);
             const response = await axios.get(url, { responseType: 'blob' });
             file = new File([response.data], `Doc_${order.order_number}.pdf`, { type: 'application/pdf' });
        }

        if (shareModal.channel === 'whatsapp') {
            if (file && navigator.canShare && navigator.canShare({ files: [file] })) {
                await navigator.share({ files: [file], title: `Doc ${order.order_number}`, text: shareModal.message });
            } else {
                if (file) {
                    const link = document.createElement('a'); link.href = URL.createObjectURL(file); link.download = `Doc_${order.order_number}.pdf`; document.body.appendChild(link); link.click(); document.body.removeChild(link);
                }
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

const generateItemsReport = async () => {
    if (!reportModal.startDate || !reportModal.endDate) {
        appStore.showSnackbar('Selecione as datas.', 'warning');
        return;
    }
    reportModal.loading = true;
    try {
        const sDate = startOfDay(parseISO(reportModal.startDate)).toISOString();
        const eDate = endOfDay(parseISO(reportModal.endDate)).toISOString();

        let query = supabase.from('store_sales')
            .select('items, date_sale, created_at')
            .gte('date_sale', sDate)
            .lte('date_sale', eDate)
            .neq('status', 'cancelled');

        if (companyStore.context && !companyStore.isGlobalView) {
            query = query.eq('company_id', companyStore.context);
        }

        const { data, error } = await query;
        if (error) throw error;

        if (!data || data.length === 0) {
            appStore.showSnackbar('Nenhuma venda encontrada nesse período.', 'info');
            reportModal.loading = false;
            return;
        }

        const itemMap: Record<string, { nome: string, qtd: number, valorTotal: number }> = {};
        data.forEach(sale => {
            const items = sale.items || [];
            items.forEach((it: any) => {
                const prod = it.produto || it;
                const code = prod.codigo || prod.IdProduto || 'S/N';
                const name = prod.nome_produto || prod.descricao || 'Produto Desconhecido';
                const qty = Number(prod.quantidade || 0);
                const val = Number(prod.valor_total || (qty * Number(prod.valor_unitario || 0)));

                const key = `${code}_${name}`;
                if (!itemMap[key]) {
                    itemMap[key] = { nome: name, qtd: 0, valorTotal: 0 };
                }
                itemMap[key].qtd += qty;
                itemMap[key].valorTotal += val;
            });
        });

        const sortedItems = Object.values(itemMap).sort((a, b) => b.qtd - a.qtd);

        const doc = new jsPDF({ orientation: "p", unit: "mm", format: "a4" });
        doc.setFont("helvetica", "bold");
        doc.setFontSize(16);
        doc.text("Relatório de Itens Vendidos", 14, 20);

        doc.setFontSize(10);
        doc.setFont("helvetica", "normal");
        doc.text(`Período: ${format(parseISO(reportModal.startDate), 'dd/MM/yyyy')} a ${format(parseISO(reportModal.endDate), 'dd/MM/yyyy')}`, 14, 28);
        doc.text(`Gerado em: ${format(new Date(), 'dd/MM/yyyy HH:mm')}`, 14, 33);

        const tableData = sortedItems.map(item => [
            item.nome,
            item.qtd.toString(),
            formatCurrency(item.valorTotal)
        ]);

        const totalQtd = sortedItems.reduce((acc, it) => acc + it.qtd, 0);
        const totalGeral = sortedItems.reduce((acc, it) => acc + it.valorTotal, 0);

        autoTable(doc, {
            startY: 40,
            head: [['Produto', 'Quantidade', 'Valor Total']],
            body: tableData,
            foot: [['TOTAL GERAL', totalQtd.toString(), formatCurrency(totalGeral)]],
            theme: 'grid',
            headStyles: { fillColor: [60, 60, 60] },
            footStyles: { fillColor: [240, 240, 240], textColor: [0,0,0], fontStyle: 'bold' }
        });

        doc.save(`Relatorio_Itens_${reportModal.startDate}_a_${reportModal.endDate}.pdf`);
        appStore.showSnackbar('Relatório gerado com sucesso!', 'success');
        reportModal.show = false;

    } catch (e: any) {
        console.error(e);
        appStore.showSnackbar('Erro ao gerar relatório: ' + e.message, 'error');
    } finally {
        reportModal.loading = false;
    }
};

const formatCurrency = (val: any) => new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(Number(val) || 0);
const formatDate = (dateStr: string) => dateStr ? format(parseISO(dateStr), 'dd/MM/yyyy') : '-';
const getCompanyName = (id: string) => companies.value.find(c => c.id === id)?.trade_name || 'N/A';

const getStatusColorClass = (s: string) => {
    if (s === 'completed') return 'chip-success';
    if (s === 'cancelled') return 'chip-danger';
    return 'chip-warning';
};
const formatStatus = (s: string) => {
    const map: Record<string, string> = { 'completed': 'Concluído', 'cancelled': 'Cancelado', 'pending': 'Pendente' };
    return map[s] || s;
};

const getFinancialColorClass = (s: string) => {
    const status = (s || '').toLowerCase();
    if (status.includes('faturado') || status === 'pago') return 'chip-success';
    if (status.includes('parcial')) return 'chip-warning';
    if (status.includes('cancel')) return 'chip-danger';
    return 'chip-default';
};

const getColor = (name: string) => { const colors = ['primary', 'secondary', 'info', 'success', 'warning', 'error']; let hash = 0; if(!name) return 'grey'; for(let i=0; i<name.length; i++) hash = name.charCodeAt(i) + ((hash << 5) - hash); return colors[Math.abs(hash) % colors.length]; };
const zebraClass = (i: number) => themeStore.currentMode!=='light' ? (i%2===0?'zebra-dark-a':'zebra-dark-b') : (i%2===0?'zebra-light-a':'zebra-light-b');

let fetchSalesTimer: ReturnType<typeof setTimeout> | null = null;

const scheduleFetchSales = (resetPage = true) => {
    if (resetPage && page.value !== 1) {
        page.value = 1;
        return;
    }

    if (fetchSalesTimer) clearTimeout(fetchSalesTimer);
    fetchSalesTimer = setTimeout(() => {
        fetchSales();
    }, 350);
};

watch(() => companyStore.context, () => scheduleFetchSales(true));
watch(companyFilter, () => scheduleFetchSales(true));
watch(currentPeriod, () => scheduleFetchSales(true));
watch(filters, () => scheduleFetchSales(true), { deep: true });
watch(page, () => fetchSales());

onMounted(() => {
    fetchCompanies();
    fetchSalespeople();
    fetchSales();
});
</script>

<style scoped lang="scss">
/* Layout Geral */
.sales-layout { position: relative; }
.background-carousel-wrapper { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 0; opacity: 0.6; pointer-events: none; }
.background-overlay { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 1; background: radial-gradient(circle at center, rgba(15, 15, 19, 0.4), rgba(15, 15, 19, 0.98)); backdrop-filter: blur(8px); }
.z-10 { position: relative; z-index: 10; }
.bg-glass-dark { background: rgba(10,10,12,0.85); }
.bg-glass-header { background: rgba(20,20,24,0.55); backdrop-filter: blur(14px); }
.border-bottom-white-05 { border-bottom: 1px solid rgba(255,255,255,0.08); }
.border-thin { border: 1px solid rgba(0,0,0,0.08); }
.bg-white-05 { background: rgba(255,255,255,0.05); }
.bg-black-20 { background: rgba(0,0,0,0.2) !important; }

/* Buttons & Inputs */
.clean-input { border: none; outline: none; background: transparent; font-size: 13px; color: inherit; width: 100%; }
.clean-select :deep(.v-field__input) { min-height: 36px; padding-top: 0; padding-bottom: 0; }
.btn-3d { border-radius: 6px !important; box-shadow: 0 3px 5px rgba(0,0,0,0.15), inset 0 2px 0 rgba(255,255,255,0.25) !important; transition: transform 0.1s ease, box-shadow 0.1s ease; text-transform: none !important; }
.btn-3d:active { transform: translateY(2px); box-shadow: 0 1px 2px rgba(0,0,0,0.15), inset 0 1px 0 rgba(255,255,255,0.2) !important; }
.chip-3d { border-radius: 6px !important; box-shadow: 0 3px 5px rgba(0,0,0,0.12), inset 0 1px 0 rgba(255,255,255,0.25) !important; text-shadow: 0 1px 2px rgba(0,0,0,0.25); }

/* Controles */
.controls-bar { padding: 10px; }
.controls-light { background: transparent; }
.controls-dark { background: transparent; }

.search-wrap { height: 40px; padding: 0 12px; min-width: 360px; max-width: 520px; flex: 1 1 360px; }
.search-light { background: #ffffff; border: 1px solid rgba(0,0,0,0.08); }
.search-dark { background: rgba(255,255,255,0.08); border: 1px solid rgba(255,255,255,0.10); }

/* Table Grid Styles */
.glass-card { background: rgba(30, 30, 35, 0.45); backdrop-filter: blur(25px); border: 1px solid rgba(255,255,255,0.08); }
.grid-scroll { scrollbar-gutter: stable both-edges; width: 100%; }
.custom-scroll::-webkit-scrollbar { width: 8px; height: 8px; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.35); border-radius: 6px; }
.custom-scroll::-webkit-scrollbar-track { background: transparent; }

.grid-header, .grid-row { display: grid; align-items: stretch; width: 100%; }

.cell { padding: 6px 12px; display: flex; align-items: center; border-right: 1px solid rgba(0,0,0,0.08); min-height: 56px; overflow: hidden; }
.center { justify-content: center; text-align: center; }
.right { justify-content: flex-end; text-align: right; }

.grid-header .cell { min-height: 48px; font-size: 11px !important; font-weight: 900; text-transform: uppercase; letter-spacing: .6px; opacity: 0.8; }
.header-text { font-size: 11px !important; }

/* Table Theme Variations */
.grid-surface-light .cell { background: #f5f7fa; color: rgba(0,0,0,0.7); border-color: rgba(0,0,0,0.10) !important; }
.grid-surface-dark .cell { background: rgba(255,255,255,0.08) !important; color: rgba(255,255,255,0.80) !important; border-color: rgba(255,255,255,0.10) !important; }

.grid-row-light .cell { background: #fff; border-color: rgba(0,0,0,0.06) !important; }
.grid-row-light:hover .cell { background: #f7fafc !important; }
.grid-row-dark .cell { background: rgba(255,255,255,0.04); border-color: rgba(255,255,255,0.08) !important; color: rgba(255,255,255,0.85); }
.grid-row-dark:hover .cell { background: rgba(255,255,255,0.07) !important; }
.zebra-light-a .cell { background: #ffffff; }
.zebra-light-b .cell { background: #f8f9fa; }
.zebra-dark-a .cell { background: rgba(255,255,255,0.03) !important; }
.zebra-dark-b .cell { background: rgba(255,255,255,0.015) !important; }

.sticky-head { position: sticky; top: 0; z-index: 10; }
.bg-glass-dark .sticky-head { box-shadow: 0 8px 20px -4px rgba(0, 0, 0, 0.4); }
.bg-grey-lighten-5 .sticky-head { box-shadow: 0 8px 16px -4px rgba(0, 0, 0, 0.12); }

/* Utils */
.pill-ref { font-size: 12px !important; font-weight: 900; font-family: monospace; padding: 4px 6px; border-radius: 0px; white-space: nowrap; }
.underline-ref { text-decoration: underline !important; }
.list-text-11 { font-size: 13px !important; line-height: 1.2 !important; }
.list-text-10 { font-size: 12px !important; line-height: 1.2 !important; }
.lh-1 { line-height: 1.2 !important; }
.letter-spacing-1 { letter-spacing: 1px !important; }

/* Specific Text Classes */
.solid-chip { display: inline-flex; align-items: center; justify-content: center; height: 26px; padding: 0 12px; border-radius: 6px; font-size: 11px; font-weight: 900; color: #fff; white-space: nowrap; text-transform: uppercase; }
.chip-success { background: #2e7d32; }
.chip-info { background: #1976d2; }
.chip-warning { background: #f57f17; }
.chip-danger { background: #c62828; }
.chip-default { background: #455a64; }

/* Actions */
.actions-inline { display: flex; align-items: center; justify-content: center; gap: 8px; }
.action-btn { width: 28px !important; height: 28px !important; min-width: 28px !important; color: #fff !important; }
.action-btn :deep(.v-icon) { color: #fff !important; }
.action-edit { background: #fb8c00 !important; }
.action-more { background: #1b5e20 !important; }
.custom-tooltip { background-color: #333333 !important; color: #ffffff !important; font-size: 11px !important; font-weight: 600 !important; border-radius: 4px; }
.border-dashed { border-style: dashed !important; }

/* Formulários e Modais */
.fixed-dialog { overflow: hidden !important; }
.ui-field :deep(.v-field) { border-radius: 6px !important; }
.input-dense :deep(.v-field) { min-height: 36px !important; padding-top: 0; padding-bottom: 0; }
.input-label { font-size: 11px; font-weight: 900; text-transform: uppercase; color: #757575; display: block; margin-bottom: 4px; }
.row-gap-sm { row-gap: 12px; }
.shadow-up { box-shadow: 0 -4px 6px -1px rgba(0, 0, 0, 0.05); }
.shadow-inner { box-shadow: inset 0 2px 4px rgba(0,0,0,0.05); }
.hover-bg-grey:hover { background-color: rgba(0,0,0,0.03); }

/* Fix checkbox constraints */
:deep(.v-checkbox-btn) { width: 24px !important; height: 24px !important; }
:deep(.v-checkbox-btn .v-selection-control__input) { width: 24px !important; height: 24px !important; }
:deep(.v-checkbox-btn .v-icon) { font-size: 18px !important; }
.chk-fixed { margin: 0 !important; padding: 0 !important; }


/* Ajustes solicitados: contexto superior, ações isoladas e filtros padronizados */
.top-actions {
  gap: 10px;
  padding: 6px;
  border-radius: 16px;
  background: transparent !important;
}

.top-icon-action {
  width: 42px !important;
  height: 42px !important;
  border-radius: 14px !important;
  background: rgba(255,255,255,0.82) !important;
  border: 1px solid rgba(148,163,184,0.22) !important;
  box-shadow: 0 3px 0 rgba(15,23,42,0.10), 0 10px 20px rgba(15,23,42,0.10) !important;
}

.top-new-sale {
  height: 42px !important;
  border-radius: 14px !important;
  box-shadow: 0 3px 0 rgba(21,128,61,0.35), 0 12px 22px rgba(34,197,94,0.20) !important;
}

.context-switcher-row {
  gap: 8px;
  max-width: 100%;
}

.context-btn-3d {
  padding-inline: 12px !important;
  font-size: 9.5px !important;
  letter-spacing: 0.045em !important;
  text-transform: uppercase !important;
  box-shadow: 0 2px 0 rgba(15,23,42,0.10), 0 8px 16px rgba(15,23,42,0.08) !important;
}

.context-btn-idle {
  background: #ffffff !important;
  color: #64748b !important;
  border: 1px solid rgba(148,163,184,0.22) !important;
}

.context-btn-active {
  color: #ffffff !important;
  box-shadow: 0 2px 0 rgba(0,0,0,0.18), 0 10px 20px rgba(15,23,42,0.15) !important;
}

.controls-main-row {
  gap: 12px;
}

.controls-main-row .search-wrap {
  order: 1;
  margin-right: auto;
}

.controls-main-row > .v-menu,
.controls-main-row .period-actions {
  order: 2;
  flex-shrink: 0;
}

.controls-main-row .period-actions {
  gap: 8px;
}

.controls-main-row .v-btn-toggle {
  border-radius: 12px !important;
  overflow: hidden;
  box-shadow: 0 2px 0 rgba(15,23,42,0.08), 0 8px 18px rgba(15,23,42,0.06);
}

.controls-main-row .search-wrap,
.controls-main-row .v-btn,
.controls-main-row .v-btn-toggle {
  min-height: 40px;
}

@media (max-width: 960px) {
  .header-bar {
    align-items: stretch !important;
  }

  .top-actions {
    justify-content: flex-start;
  }

  .context-switcher-row {
    overflow-x: auto;
    flex-wrap: nowrap !important;
    padding-bottom: 4px;
  }

  .controls-main-row .search-wrap {
    order: 1;
    flex-basis: 100%;
    min-width: 100%;
    max-width: 100%;
  }

  .controls-main-row > .v-menu,
  .controls-main-row .period-actions {
    order: 2;
  }

  .controls-main-row .period-actions {
    width: 100%;
    overflow-x: auto;
  }
}



/* Refinamento visual: ações superiores e bandeja de filtros */
.header-bar {
  overflow: visible !important;
}

.top-actions {
  gap: 12px !important;
  padding: 10px 4px 14px 4px !important;
  overflow: visible !important;
  align-self: stretch;
  justify-content: flex-end;
}

.top-actions .v-chip,
.top-actions .v-btn {
  flex-shrink: 0;
}

.top-actions .v-chip {
  height: 42px !important;
  border-radius: 13px !important;
  padding-inline: 14px !important;
  box-shadow: 0 3px 0 rgba(30, 64, 175, 0.28), 0 12px 22px rgba(37, 99, 235, 0.16) !important;
}

.top-icon-action {
  width: 42px !important;
  height: 42px !important;
  min-width: 42px !important;
  border-radius: 14px !important;
  background: linear-gradient(180deg, #ffffff 0%, #f8fafc 100%) !important;
  border: 1px solid rgba(148, 163, 184, 0.22) !important;
  box-shadow: 0 3px 0 rgba(15,23,42,0.10), 0 12px 22px rgba(15,23,42,0.12) !important;
}

.top-new-sale {
  height: 42px !important;
  border-radius: 14px !important;
  padding-inline: 18px !important;
  box-shadow: 0 3px 0 rgba(21,128,61,0.35), 0 12px 22px rgba(34,197,94,0.22) !important;
}

.controls-bar {
  overflow: visible !important;
  padding: 10px 0 !important;
}

.controls-main-row {
  gap: 12px !important;
  align-items: center !important;
}

.controls-main-row .search-wrap {
  order: 1;
  margin-right: auto;
  height: 44px;
  min-width: 380px;
  max-width: 620px;
  border-radius: 16px !important;
  box-shadow: 0 8px 18px rgba(15, 23, 42, 0.05);
}

.filter-trigger-btn {
  order: 2;
  height: 42px !important;
  border-radius: 14px !important;
  background: rgba(255,255,255,0.78) !important;
  border: 1px solid rgba(37, 99, 235, 0.20) !important;
  box-shadow: 0 3px 0 rgba(37, 99, 235, 0.18), 0 10px 18px rgba(37, 99, 235, 0.10) !important;
}

.period-actions {
  order: 3;
  flex-shrink: 0;
}

.period-toggle {
  height: 42px !important;
  border-radius: 14px !important;
  overflow: hidden;
  background: #ffffff;
  border: 1px solid rgba(148, 163, 184, 0.20) !important;
  box-shadow: 0 3px 0 rgba(15,23,42,0.08), 0 10px 20px rgba(15,23,42,0.08) !important;
}

.period-toggle :deep(.v-btn) {
  min-height: 42px !important;
  font-size: 11px !important;
  letter-spacing: 0.02em;
}

.filter-panel {
  width: min(92vw, 460px);
  padding: 0 !important;
  overflow: hidden;
  border-radius: 20px !important;
  border: 1px solid rgba(148,163,184,0.20) !important;
  box-shadow: 0 24px 60px rgba(15, 23, 42, 0.20) !important;
}

.filter-panel-light {
  background: linear-gradient(180deg, #ffffff 0%, #f8fafc 100%) !important;
}

.filter-panel-dark {
  background: linear-gradient(180deg, rgba(30,41,59,0.98) 0%, rgba(15,23,42,0.98) 100%) !important;
}

.filter-panel-header {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 16px 18px;
  background: linear-gradient(135deg, rgba(37,99,235,0.10) 0%, rgba(14,165,233,0.08) 100%);
  border-bottom: 1px solid rgba(148,163,184,0.18);
}

.filter-panel-icon {
  width: 38px;
  height: 38px;
  border-radius: 13px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #2563eb;
  background: rgba(255,255,255,0.88);
  box-shadow: 0 2px 0 rgba(37,99,235,0.12), 0 10px 18px rgba(37,99,235,0.12);
}

.filter-panel-title {
  font-size: 14px;
  font-weight: 900;
  color: #0f172a;
  letter-spacing: -0.01em;
}

.filter-panel-subtitle {
  margin-top: 2px;
  font-size: 11px;
  font-weight: 700;
  color: #64748b;
}

.filter-panel-dark .filter-panel-title {
  color: #ffffff;
}

.filter-panel-dark .filter-panel-subtitle {
  color: rgba(226,232,240,0.72);
}

.filter-section {
  padding: 14px 18px 0 18px;
}

.filter-section-title {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  margin-bottom: 9px;
  font-size: 10px;
  font-weight: 900;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: #475569;
}

.filter-panel-dark .filter-section-title {
  color: rgba(226,232,240,0.80);
}

.filter-grid-2 {
  display: grid;
  grid-template-columns: minmax(0, 1fr) minmax(0, 1fr);
  gap: 10px;
}

.filter-field :deep(.v-field) {
  min-height: 42px !important;
  border-radius: 14px !important;
  background: rgba(255,255,255,0.88) !important;
  box-shadow: inset 0 1px 0 rgba(255,255,255,0.75);
}

.filter-field :deep(.v-field__input) {
  min-height: 42px !important;
  padding-top: 7px !important;
  padding-bottom: 7px !important;
  font-size: 13px !important;
  font-weight: 700;
}

.filter-field :deep(.v-label) {
  font-size: 12px !important;
  font-weight: 700;
}

.filter-panel-footer {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
  margin-top: 16px;
  padding: 14px 18px 18px;
  border-top: 1px solid rgba(148,163,184,0.16);
  background: rgba(248,250,252,0.72);
}

.filter-clear-btn {
  border-radius: 13px !important;
  padding-inline: 18px !important;
  box-shadow: 0 2px 0 rgba(185,28,28,0.10), 0 8px 16px rgba(239,68,68,0.10) !important;
}

@media (max-width: 960px) {
  .top-actions {
    align-self: flex-start;
    justify-content: flex-start;
    flex-wrap: wrap;
    padding-bottom: 10px !important;
  }

  .controls-main-row .search-wrap {
    flex-basis: 100%;
    min-width: 100%;
    max-width: 100%;
  }

  .filter-trigger-btn,
  .period-actions {
    order: 2;
  }

  .period-actions {
    width: 100%;
    overflow-x: auto;
    padding-bottom: 4px;
  }

  .filter-grid-2 {
    grid-template-columns: 1fr;
  }
}

</style>
