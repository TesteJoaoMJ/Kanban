<template>
  <div class="receivables-layout font-sans fill-height d-flex flex-column relative overflow-hidden" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 text-grey-darken-4' : 'bg-glass-dark text-white'">
    <div class="content-wrapper d-flex flex-column fill-height z-10 relative">

      <div class="header-bar px-4 py-3 px-md-6 py-md-4 d-flex flex-column flex-md-row align-md-start justify-space-between flex-shrink-0" :class="themeStore.currentMode === 'light' ? 'bg-white border-b border-grey-lighten-2 shadow-sm' : 'bg-glass-header border-bottom-white-05'" style="gap: 12px;">
        <div class="d-flex flex-column" style="max-width: calc(100vw - 32px);">
          <div class="breadcrumb text-body-2 d-none d-md-block">
            <span class="opacity-70">Compras</span><span class="mx-2 opacity-50">></span><span class="font-weight-bold">Aprovação de Cotações</span>
          </div>
          <div class="d-flex align-center gap-2 mt-1">
             <div class="text-h5 font-weight-black tracking-tight leading-none">Gestão de Cotações</div>
          </div>

          <div class="d-flex align-center gap-3 mt-3 overflow-x-auto hide-scrollbar pb-1 w-100">
             <v-btn
                v-for="btn in contextButtons"
                :key="btn.id"
                size="x-small"
                height="24"
                :variant="companyStore.context === btn.id ? 'flat' : 'tonal'"
                :color="companyStore.context === btn.id ? (btn.isHolding ? 'purple' : 'warning') : 'grey'"
                class="font-weight-bold btn-3d px-3 rounded-pill flex-shrink-0"
                style="font-size: 10px; letter-spacing: 0.5px;"
                @click="setCompanyFilter(btn.id)"
             >
                {{ btn.name }}
             </v-btn>
          </div>
        </div>

        <div class="d-none d-md-flex align-center overflow-x-auto pb-1 pb-md-0 mt-3 mt-md-0" style="gap: 10px;">
          <v-btn color="warning" variant="flat" class="btn-3d px-6 font-weight-bold text-body-2 text-uppercase letter-spacing-1 shadow-button" prepend-icon="mdi-file-document-edit" height="44" @click="openNewQuotationModal">
             Nova Cotação
          </v-btn>
        </div>
      </div>

      <div class="px-4 px-md-6 py-3 flex-shrink-0 border-b d-flex flex-wrap align-center justify-space-between shadow-sm z-10" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-glass-dark'" style="gap: 16px;">

          <div class="d-flex align-center flex-grow-1" style="max-width: 400px;">
              <v-text-field
                  v-model="filters.search"
                  label="Buscar (Cód, Fornecedor, Solicitante)..."
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
                          <v-icon>mdi-filter-outline</v-icon> Filtrar Cotações
                      </div>
                      <v-text-field v-model="filters.startDate" label="Data Inicial" type="date" variant="outlined" density="comfortable" class="mb-3 ui-field" hide-details></v-text-field>
                      <v-text-field v-model="filters.endDate" label="Data Final" type="date" variant="outlined" density="comfortable" class="mb-3 ui-field" hide-details></v-text-field>
                      <v-autocomplete v-model="filters.supplier" :items="auxData.suppliers" item-title="name" item-value="id" label="Filtrar por Fornecedor" variant="outlined" density="comfortable" class="mb-3 ui-field" hide-details clearable></v-autocomplete>
                      <v-select v-model="filters.status" :items="['Todos', 'pendente', 'aprovada', 'rejeitada']" label="Status da Decisão" variant="outlined" density="comfortable" class="mb-5 ui-field" hide-details></v-select>
                      <v-btn color="warning" block variant="flat" height="44" class="font-weight-bold btn-3d text-body-1 text-black" @click="fetchPurchases">Aplicar Filtros</v-btn>
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
            <div class="grid-header sticky-head border-b" :class="[themeStore.currentMode === 'light' ? 'grid-surface-light' : 'grid-surface-dark']" style="grid-template-columns: 80px 1.5fr 1.5fr 1.2fr 1.5fr 100px 120px 140px 120px 80px 150px; min-width: 1550px;">
              <div class="cell center header-text">Cód.</div>
              <div class="cell header-text">Fornecedor</div>
              <div class="cell header-text">Descrição</div>
              <div class="cell header-text">Solicitante</div>
              <div class="cell header-text text-error">Motivo Rejeição</div>
              <div class="cell center header-text">Emissão</div>
              <div class="cell center header-text">Decisão</div>
              <div class="cell center header-text">Logística</div>
              <div class="cell center header-text">Total</div>
              <div class="cell center header-text">Anexos</div>
              <div class="cell center header-text">Ações</div>
            </div>

            <div v-if="loadingPurchases" class="d-flex flex-column justify-center align-center h-100 py-10 min-w-full">
              <v-progress-circular indeterminate color="warning" size="48" width="4"></v-progress-circular>
            </div>

            <div v-else-if="filteredPurchases.length === 0" class="d-flex flex-column justify-center align-center h-100 py-10 min-w-full opacity-60">
              <v-icon size="64">mdi-file-document-check-outline</v-icon>
              <span class="text-body-1 mt-4 font-weight-bold">Nenhuma cotação encontrada para estes filtros.</span>
            </div>

            <div v-else v-for="(item, index) in paginatedPurchases" :key="item.id" class="grid-row" :class="[themeStore.currentMode === 'light' ? 'grid-row-light' : 'grid-row-dark', zebraClass(index)]" style="grid-template-columns: 80px 1.5fr 1.5fr 1.2fr 1.5fr 100px 120px 140px 120px 80px 150px; min-width: 1550px;">
                <div class="cell center">
                    <span class="pill-ref font-weight-black" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">
                        #{{ formatCode(item) }}
                    </span>
                </div>

                <div class="cell">
                    <span class="font-weight-medium text-grey-darken-4 text-truncate w-100" style="font-size: 14px;" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'" :title="item.supplier_name || item.entity_name">
                        {{ item.is_quotation && item.payment_details?.quotation_options?.length > 1 ? (item.payment_details.quotation_options.length + ' Opções Cadastradas') : (item.supplier_name || item.entity_name) }}
                    </span>
                </div>

                <div class="cell">
                    <span class="text-grey-darken-3 text-truncate w-100" style="font-size: 14px;" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-3' : 'text-white-70'" :title="item.description">{{ item.description }}</span>
                </div>

                <div class="cell">
                    <span class="text-grey-darken-2 text-truncate w-100 font-weight-medium d-flex align-center" style="font-size: 13px;" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-2' : 'text-white-50'" :title="item.created_by_name || 'Desconhecido'">
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

                <div class="cell center"><span class="font-mono font-weight-medium" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white-70'" style="font-size: 14px;">{{ formatDateSafe(item.order_date) }}</span></div>

                <div class="cell center">
                   <v-tooltip :text="item.production_status === 'rejeitado' ? 'Cotação Rejeitada' : (item.is_quotation && isAdmin ? 'Clique para decidir qual fornecedor aprovar' : 'Status da aprovação')" location="top" content-class="tooltip-custom">
                        <template v-slot:activator="{ props }">
                            <v-chip
                                v-bind="props"
                                size="default"
                                variant="flat"
                                :color="item.production_status === 'rejeitado' ? 'error' : (item.is_quotation ? 'warning' : 'success')"
                                class="font-weight-bold text-uppercase px-3 chip-3d"
                                :class="(item.is_quotation && isAdmin) ? 'cursor-pointer hover-elevate' : ''"
                                @click="(item.is_quotation && isAdmin) ? openApprovalModal(item) : null"
                                style="font-size: 11px; height: 28px;"
                            >
                                {{ item.production_status === 'rejeitado' ? 'REJEITADA' : (item.is_quotation ? 'PENDENTE' : 'APROVADA') }}
                            </v-chip>
                        </template>
                    </v-tooltip>
                </div>

                <div class="cell center">
                    <v-tooltip :text="item.production_status !== 'rejeitado' && !item.is_quotation ? 'Atualizar Status de Logística' : ''" location="top" content-class="tooltip-custom" :disabled="item.production_status === 'rejeitado' || item.is_quotation">
                        <template v-slot:activator="{ props }">
                            <v-chip
                                v-bind="props"
                                v-if="item.production_status !== 'rejeitado' && !item.is_quotation"
                                :color="getProductionStatusColor(item.production_status)"
                                variant="flat"
                                class="font-weight-bold text-white text-uppercase px-3 cursor-pointer hover-elevate chip-3d"
                                style="font-size: 11px; height: 28px;"
                                @click.stop="openStatusModal(item)"
                            >
                                {{ formatProductionStatus(item.production_status) }}
                            </v-chip>
                            <span v-else class="text-grey opacity-40 text-caption font-weight-bold">-</span>
                        </template>
                    </v-tooltip>
                </div>

                <div class="cell center"><span class="font-mono font-weight-black text-orange-darken-3" style="font-size: 15px;">{{ formatCurrency(item.total_value) }}</span></div>

                <div class="cell center">
                    <v-tooltip text="Anexos e Comprovantes" location="top" content-class="tooltip-custom">
                        <template v-slot:activator="{ props }">
                            <v-btn v-bind="props" icon size="small" variant="flat" color="primary" class="btn-3d" @click.stop="openAttachmentModal(item)">
                                <v-badge :content="item.attachments?.length || 0" color="error" :model-value="(item.attachments?.length || 0) > 0" offset-x="-5" offset-y="-5">
                                    <v-icon size="18">mdi-paperclip</v-icon>
                                </v-badge>
                            </v-btn>
                        </template>
                    </v-tooltip>
                </div>

                <div class="cell center">
                    <div class="actions-inline d-flex flex-nowrap gap-2">
                        <v-tooltip text="Editar Cotação" location="top" content-class="tooltip-custom">
                            <template v-slot:activator="{ props }">
                                <v-btn v-bind="props" icon size="small" class="action-btn btn-3d action-edit" @click.stop="openEditModal(item)" variant="flat" :disabled="!item.is_quotation"><v-icon size="16">mdi-pencil</v-icon></v-btn>
                            </template>
                        </v-tooltip>

                        <v-tooltip text="Clonar Cotação" location="top" content-class="tooltip-custom">
                            <template v-slot:activator="{ props }">
                                <v-btn v-bind="props" icon size="small" class="action-btn btn-3d bg-blue-grey-lighten-4 text-blue-grey-darken-4" @click.stop="cloneQuotation(item)" variant="flat"><v-icon size="16">mdi-content-copy</v-icon></v-btn>
                            </template>
                        </v-tooltip>

                        <v-tooltip text="Excluir Cotação" location="top" content-class="tooltip-custom">
                            <template v-slot:activator="{ props }">
                                <v-btn v-bind="props" icon size="small" class="action-btn btn-3d action-del" @click.stop="deletePurchase(item.id, item.is_quotation)" variant="flat" :disabled="!isAdmin && !item.is_quotation"><v-icon size="16">mdi-trash-can-outline</v-icon></v-btn>
                            </template>
                        </v-tooltip>
                    </div>
                </div>
            </div>
          </div>
          <div class="flex-shrink-0 border-t px-4 py-2 d-flex align-center justify-space-between z-20" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-surface-variant border-white-05'" v-if="pageCount > 1">
              <div class="text-caption font-weight-bold opacity-70">Página {{ page }} de {{ pageCount }}</div>
              <v-pagination v-model="page" :length="pageCount" :total-visible="5" density="compact" active-color="warning" variant="tonal" size="small"></v-pagination>
          </div>
        </v-card>
      </div>
    </div>

    <v-dialog v-model="statusModal.show" width="450">
        <v-card class="pa-6 rounded-lg border-t-lg border-t-primary">
            <div class="d-flex align-center gap-3 mb-4">
                <v-icon size="36" color="primary">mdi-truck-outline</v-icon>
                <div class="text-h6 font-weight-black leading-none">Status Logístico</div>
            </div>
            <p class="text-body-2 text-grey mb-4">Atualize o andamento da entrega do material após aprovação.</p>

            <v-select v-model="statusModal.status" :items="statusOptions" item-title="label" item-value="value" variant="outlined" density="comfortable" color="primary" hide-details class="font-weight-bold ui-field"></v-select>

            <div class="d-flex justify-end gap-2 mt-6">
                <v-btn variant="text" color="grey-darken-2" class="font-weight-bold btn-3d text-body-2" @click="statusModal.show = false">Cancelar</v-btn>
                <v-btn color="primary" variant="flat" class="font-weight-black px-6 btn-3d text-body-2" height="44" @click="saveProductionStatus" :loading="statusModal.loading">Atualizar</v-btn>
            </div>
        </v-card>
    </v-dialog>

    <v-dialog v-model="attachmentModal.show" max-width="500">
        <v-card class="rounded-lg border-t-lg border-t-primary">
            <div class="px-6 py-4 bg-white border-b d-flex justify-space-between align-center">
                <div class="d-flex align-center gap-2">
                    <v-icon size="24" color="primary">mdi-paperclip</v-icon>
                    <span class="text-h6 font-weight-black text-primary">Comprovantes e NFe</span>
                </div>
                <v-btn icon="mdi-close" variant="text" class="btn-3d" @click="attachmentModal.show = false"></v-btn>
            </div>
            <div class="pa-6">
                <div v-if="attachmentModal.item?.attachments?.length > 0" class="mb-4">
                    <div class="text-caption font-weight-bold mb-2 text-uppercase text-grey">Arquivos Anexados:</div>
                    <div class="d-flex flex-column gap-2">
                        <a v-for="(url, idx) in attachmentModal.item.attachments" :key="idx" :href="url" target="_blank" class="text-primary text-body-2 font-weight-bold d-flex align-center gap-2 bg-grey-lighten-4 pa-2 rounded text-decoration-none border-thin">
                            <v-icon size="18">mdi-file-document-outline</v-icon> Anexo {{ idx + 1 }}
                        </a>
                    </div>
                </div>
                <div v-else class="text-body-2 text-grey mb-4 font-italic bg-grey-lighten-5 pa-4 rounded border-thin text-center">Nenhum comprovante anexado ainda.</div>

                <v-divider class="my-4"></v-divider>

                <div class="text-caption font-weight-bold mb-2 text-uppercase text-grey">Enviar Novo Comprovante / Foto NFe:</div>
                <v-file-input v-model="attachmentModal.files" multiple chips label="Selecionar arquivos..." variant="outlined" density="comfortable" prepend-inner-icon="mdi-cloud-upload" color="primary"></v-file-input>
            </div>
            <div class="pa-4 bg-grey-lighten-4 border-t d-flex justify-end gap-3">
                <v-btn variant="outlined" class="btn-3d font-weight-bold bg-white" @click="attachmentModal.show = false">Fechar</v-btn>
                <v-btn color="primary" variant="flat" class="btn-3d font-weight-black px-6" @click="uploadAttachmentsToPurchase" :loading="attachmentModal.loading">Salvar Anexo</v-btn>
            </div>
        </v-card>
    </v-dialog>

    <v-dialog v-model="approvalModal.show" max-width="1200" persistent scrollable>
        <v-card class="rounded-lg h-100 bg-grey-lighten-4" style="max-height: 90vh;">
            <div class="px-6 py-4 bg-purple-darken-3 text-white d-flex align-center justify-space-between flex-shrink-0">
                <div class="d-flex align-center gap-3">
                    <v-icon size="28">mdi-scale-balance</v-icon>
                    <div>
                        <div class="text-h6 font-weight-black leading-none">Decisão de Cotação e Fornecimento</div>
                        <div class="text-caption opacity-80 mt-1">Analise os detalhes orçados e escolha a opção mais vantajosa.</div>
                    </div>
                </div>
                <v-btn icon="mdi-close" variant="text" class="btn-3d" @click="approvalModal.show = false"></v-btn>
            </div>

            <v-card-text class="pa-0 d-flex flex-column flex-md-row overflow-hidden">
                <div class="bg-white border-r d-flex flex-column" style="width: 380px; flex-shrink: 0; overflow-y: auto;">
                    <div class="pa-5 border-b bg-grey-lighten-5">
                        <div class="text-caption font-weight-bold text-uppercase text-grey mb-1">Referência / Demanda Solicitada</div>
                        <div class="text-body-1 font-weight-black text-grey-darken-4 lh-1-2">{{ approvalModal.item?.description }}</div>
                    </div>
                    <div class="px-5 py-4 text-caption font-weight-black text-purple-darken-3 text-uppercase tracking-wide border-b">
                        Opções Cadastradas ({{ approvalModal.options.length }})
                    </div>
                    <div class="d-flex flex-column px-5 py-4 gap-3 bg-grey-lighten-5 flex-grow-1">
                        <v-card
                            v-for="(quote, idx) in approvalModal.options"
                            :key="idx"
                            variant="outlined"
                            class="rounded-lg cursor-pointer border-thin transition-all relative overflow-hidden"
                            :class="approvalModal.selectedIndex === idx ? 'border-purple-darken-2 bg-purple-lighten-5 shadow-sm' : 'bg-white hover-elevate'"
                            @click="approvalModal.selectedIndex = idx"
                        >
                            <div v-if="approvalModal.selectedIndex === idx" class="position-absolute left-0 top-0 bottom-0 bg-purple-darken-2" style="width: 4px;"></div>
                            <div class="pa-4">
                                <div class="d-flex justify-space-between align-start mb-2">
                                    <div class="font-weight-black text-body-1 lh-1-2" :class="approvalModal.selectedIndex === idx ? 'text-purple-darken-3' : 'text-grey-darken-3'">
                                        {{ getSupplierName(quote.supplier_id) || 'Fornecedor Desconhecido' }}
                                    </div>
                                    <v-icon v-if="approvalModal.selectedIndex === idx" color="purple-darken-2" size="20">mdi-check-circle</v-icon>
                                    <v-icon v-else color="grey-lighten-1" size="20">mdi-radiobox-blank</v-icon>
                                </div>
                                <div class="text-h6 font-weight-black tabular-nums text-orange-darken-3 mb-2">
                                    {{ formatCurrency(calcQuoteTotal(quote)) }}
                                </div>
                                <div class="d-flex align-center justify-space-between text-caption font-weight-bold text-grey-darken-1 pt-2 border-t border-opacity-50">
                                    <span><v-icon size="14" class="mr-1">mdi-package-variant</v-icon>{{ quote.items?.length || 0 }} itens</span>
                                    <span><v-icon size="14" class="mr-1">mdi-credit-card-outline</v-icon>{{ quote.payment?.condition }} ({{ quote.payment?.installments || 1 }}x)</span>
                                </div>
                            </div>
                        </v-card>
                    </div>
                </div>

                <div class="flex-grow-1 bg-grey-lighten-4 d-flex flex-column overflow-y-auto relative custom-scroll" style="min-width: 0;">
                    <template v-if="approvalModal.selectedIndex !== null && approvalModal.options[approvalModal.selectedIndex]">
                        <div class="pa-6">

                            <div class="bg-white border-thin shadow-sm rounded-lg mb-6 overflow-hidden">
                                <div class="bg-grey-lighten-4 border-b px-5 py-3 d-flex align-center justify-space-between">
                                    <div class="d-flex align-center gap-2">
                                        <v-icon size="20" color="purple-darken-2">mdi-format-list-bulleted</v-icon>
                                        <span class="text-subtitle-2 font-weight-black text-uppercase text-grey-darken-3 tracking-wide">Escopo e Preços Ofertados</span>
                                    </div>
                                    <v-chip size="small" color="purple-darken-2" variant="flat" class="font-weight-bold rounded-lg">
                                        {{ approvalModal.options[approvalModal.selectedIndex].items?.length || 0 }} Itens
                                    </v-chip>
                                </div>
                                <div class="overflow-x-auto">
                                    <table class="w-100 text-left" style="border-collapse: collapse;">
                                        <thead>
                                            <tr class="bg-white border-b text-caption font-weight-black text-uppercase text-grey-darken-1">
                                                <th class="pa-4">Material / Serviço Ofertado</th>
                                                <th class="pa-4 text-center">Quantidade</th>
                                                <th class="pa-4 text-right">V. Unitário</th>
                                                <th class="pa-4 text-right">Subtotal</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            <tr v-for="(it, i) in approvalModal.options[approvalModal.selectedIndex].items" :key="i" class="border-b hover:bg-grey-lighten-5 text-body-2 transition-all">
                                                <td class="pa-4 font-weight-bold text-grey-darken-4">{{ it.product_name || it.description || 'Item Sem Nome' }}</td>
                                                <td class="pa-4 text-center font-mono font-weight-medium bg-grey-lighten-5">{{ it.quantity }} <span class="text-caption text-uppercase text-grey-darken-1 ml-1">{{ it.unit_of_measure }}</span></td>
                                                <td class="pa-4 text-right font-mono font-weight-medium">{{ formatCurrencyValue(it.unit_price) }}</td>
                                                <td class="pa-4 text-right font-mono font-weight-black text-orange-darken-3 bg-orange-lighten-5">{{ formatCurrency(it.total_price) }}</td>
                                            </tr>
                                        </tbody>
                                        <tfoot>
                                            <tr class="bg-grey-lighten-4">
                                                <td colspan="3" class="pa-4 text-right text-caption font-weight-black text-uppercase text-grey-darken-2">Valor Total desta Proposta</td>
                                                <td class="pa-4 text-right text-h6 font-weight-black text-orange-darken-4 tabular-nums">{{ formatCurrency(calcQuoteTotal(approvalModal.options[approvalModal.selectedIndex])) }}</td>
                                            </tr>
                                        </tfoot>
                                    </table>
                                </div>
                            </div>

                            <div class="bg-white border-thin shadow-sm rounded-lg overflow-hidden">
                                <div class="bg-grey-lighten-4 border-b px-5 py-3 d-flex align-center gap-2">
                                    <v-icon size="20" color="purple-darken-2">mdi-credit-card-check-outline</v-icon>
                                    <span class="text-subtitle-2 font-weight-black text-uppercase text-grey-darken-3 tracking-wide">Desembolso Financeiro</span>
                                </div>
                                <div class="pa-5">
                                    <v-row dense>
                                        <v-col cols="12" md="6" class="border-r pr-md-4">
                                            <div class="d-flex flex-column gap-3">
                                                <div>
                                                    <div class="text-caption text-grey text-uppercase font-weight-bold tracking-wide">Método Exigido</div>
                                                    <div class="font-weight-black text-body-1">{{ approvalModal.options[approvalModal.selectedIndex].payment?.method || 'Indefinido' }}</div>
                                                </div>
                                                <div>
                                                    <div class="text-caption text-grey text-uppercase font-weight-bold tracking-wide">Condição Oferecida</div>
                                                    <div class="font-weight-black text-body-1">{{ approvalModal.options[approvalModal.selectedIndex].payment?.condition || 'Indefinido' }}</div>
                                                </div>
                                            </div>
                                        </v-col>
                                        <v-col cols="12" md="6" class="pl-md-4">
                                            <div class="text-caption text-grey text-uppercase font-weight-bold tracking-wide mb-2">Projeção de Parcelas</div>
                                            <div class="d-flex flex-column gap-2" v-if="approvalModal.options[approvalModal.selectedIndex].payment?.details?.length > 0">
                                                <div v-for="(p, pIdx) in approvalModal.options[approvalModal.selectedIndex].payment?.details" :key="pIdx" class="d-flex justify-space-between align-center bg-white border border-purple-lighten-4 px-4 py-2 shadow-sm relative overflow-hidden">
                                                    <div class="position-absolute left-0 top-0 bottom-0 bg-purple-lighten-3" style="width: 3px;"></div>
                                                    <span class="font-weight-bold text-grey-darken-3 text-body-2"><span class="text-purple-darken-2 mr-2">{{ pIdx + 1 }}ª</span> {{ formatDateSafe(p.due_date) }}</span>
                                                    <span class="font-weight-black text-purple-darken-3 font-mono text-body-1">{{ formatCurrency(p.value) }}</span>
                                                </div>
                                            </div>
                                            <div v-else class="text-caption text-grey font-italic">Nenhuma parcela configurada.</div>
                                        </v-col>
                                    </v-row>
                                </div>
                            </div>
                        </div>
                    </template>
                    <div v-else class="d-flex flex-column align-center justify-center h-100 opacity-40 bg-grey-lighten-3">
                        <v-icon size="64" class="mb-4">mdi-cursor-default-click-outline</v-icon>
                        <span class="text-body-1 font-weight-bold">Selecione uma opção de fornecedor no menu lateral<br>para analisar o escopo e preços.</span>
                    </div>
                </div>
            </v-card-text>

            <div class="px-6 py-4 bg-white border-t d-flex flex-wrap justify-space-between align-center flex-shrink-0 z-10 relative gap-4">
                <v-text-field v-model="approvalModal.reason" label="Motivo da Rejeição (Preencha para rejeitar todas)" variant="outlined" density="comfortable" hide-details class="ui-field flex-grow-1" style="max-width: 500px;"></v-text-field>
                <div class="d-flex gap-3">
                    <v-btn variant="outlined" color="grey-darken-3" class="btn-3d font-weight-bold" height="48" @click="approvalModal.show = false">Fechar</v-btn>
                    <v-btn color="error" variant="flat" class="btn-3d font-weight-black px-6" height="48" @click="executeRejection" :loading="approvalModal.loading"><v-icon start>mdi-close-thick</v-icon> Rejeitar Todas</v-btn>
                    <v-btn color="success" variant="flat" class="btn-3d font-weight-black px-8 shadow-button" height="48" @click="executeApproval" :loading="approvalModal.loading" :disabled="approvalModal.selectedIndex === null"><v-icon start size="20">mdi-check-decagram</v-icon> APROVAR OPÇÃO SELECIONADA</v-btn>
                </div>
            </div>
        </v-card>
    </v-dialog>

    <v-dialog v-model="modal.show" max-width="1500" persistent scrollable transition="dialog-bottom-transition">
        <v-card class="d-flex flex-column rounded-lg bg-grey-lighten-4 h-100" style="max-height: 95vh;">
            <div class="px-6 py-5 d-flex align-center justify-space-between flex-shrink-0 elevation-2 z-10 relative" :class="themeStore.currentMode === 'light' ? 'bg-gradient-orange-dark text-white' : 'bg-glass-header text-white'">
                <div class="d-flex align-center gap-4">
                    <div class="bg-white-20 rounded-lg d-flex align-center justify-center" style="width: 48px; height: 48px;">
                        <v-icon size="28" color="white">{{ modal.form.id ? 'mdi-file-document-edit' : 'mdi-file-document-plus' }}</v-icon>
                    </div>
                    <div>
                        <div class="text-h5 font-weight-black leading-tight">{{ modal.form.id ? 'Editando Cotação' : 'Nova Cotação' }}</div>
                        <div class="text-caption font-weight-medium opacity-90">Preencha os dados básicos e adicione as opções de fornecedores em abas.</div>
                    </div>
                </div>
                <v-btn icon="mdi-close" variant="text" color="white" size="large" class="btn-3d" @click="modal.show = false"></v-btn>
            </div>

            <v-card-text class="pa-0 custom-scroll d-flex flex-column bg-grey-lighten-4">
                <v-form ref="quotationForm" class="pa-6 d-flex flex-column gap-6">
                    <v-card variant="outlined" class="bg-white rounded-lg border-thin overflow-hidden shadow-sm">
                        <div class="bg-grey-lighten-4 border-b px-5 py-3 d-flex align-center gap-2">
                            <v-icon size="20" color="warning">mdi-information-outline</v-icon>
                            <span class="text-subtitle-2 font-weight-black text-uppercase text-grey-darken-3 tracking-wide">Dados Globais da Demanda</span>
                        </div>
                        <div class="pa-5">
                            <v-row dense class="row-gap">
                                <v-col cols="12" md="4">
                                    <v-text-field v-model="modal.form.description" label="Referência / Motivo da Cotação*" variant="outlined" density="comfortable" color="warning" class="ui-field font-weight-bold" placeholder="Ex: Compra de Tecidos Agosto"></v-text-field>
                                </v-col>
                                <v-col cols="12" md="4">
                                    <v-autocomplete v-model="modal.form.company_id" :items="auxData.companies" item-title="trade_name" item-value="id" label="Empresa (Tenant)*" variant="outlined" density="comfortable" color="warning" class="ui-field font-weight-bold" :disabled="!isAdmin" :readonly="!isAdmin"></v-autocomplete>
                                </v-col>
                                <v-col cols="12" md="4">
                                    <v-autocomplete v-model="modal.form.chart_of_accounts_id" :items="auxData.chartOfAccounts" item-title="name" item-value="id" label="Plano de Contas (Opcional)" variant="outlined" density="comfortable" color="warning" class="ui-field" clearable></v-autocomplete>
                                </v-col>
                                <v-col cols="12" md="2">
                                    <v-text-field v-model="modal.form.order_date" label="Data de Emissão*" type="date" variant="outlined" density="comfortable" color="warning" class="ui-field font-weight-bold"></v-text-field>
                                </v-col>
                                <v-col cols="12" md="2">
                                    <v-text-field v-model="modal.form.delivery_date" label="Prazo Desejado*" type="date" variant="outlined" density="comfortable" color="warning" class="ui-field font-weight-bold"></v-text-field>
                                </v-col>
                                <v-col cols="12" md="4">
                                    <v-textarea v-model="modal.form.notes" label="Justificativa Adicional" variant="outlined" rows="1" density="comfortable" auto-grow class="ui-field"></v-textarea>
                                </v-col>
                                <v-col cols="12" md="4">
                                    <v-file-input v-model="modal.files" multiple chips label="Anexos / Orçamentos (Obrigatório)*" variant="outlined" density="comfortable" prepend-inner-icon="mdi-paperclip" color="warning" class="ui-field font-weight-bold"></v-file-input>
                                    <div v-if="modal.form.attachments?.length > 0" class="mt-2 d-flex gap-2 flex-wrap">
                                        <v-chip v-for="(url, idx) in modal.form.attachments" :key="idx" size="x-small" color="warning" variant="flat" class="font-weight-bold" :href="url" target="_blank" style="cursor: pointer;">
                                            <v-icon start size="14">mdi-file-document-outline</v-icon> Anexo Antigo {{ idx + 1 }}
                                        </v-chip>
                                    </div>
                                </v-col>
                            </v-row>
                        </div>
                    </v-card>

                    <div class="d-flex align-center bg-white border-thin shadow-sm rounded-lg overflow-hidden">
                        <v-tabs v-model="modal.activeTab" bg-color="white" color="warning" slider-color="warning" show-arrows class="flex-grow-1">
                            <v-tab v-for="(quote, idx) in modal.quotes" :key="quote.ui_id" :value="idx" class="font-weight-bold text-uppercase">
                                Opção {{ idx + 1 }}: {{ getSupplierName(quote.supplier_id) || 'Selecionar Fornecedor' }}
                                <v-btn v-if="modal.quotes.length > 1" icon="mdi-close" size="x-small" variant="text" class="ml-2 opacity-50 btn-3d" @click.stop="removeQuoteTab(idx)"></v-btn>
                            </v-tab>
                        </v-tabs>
                        <v-btn variant="flat" color="warning" class="rounded-0 h-100 px-6 font-weight-black btn-3d" @click="addQuoteOption">
                            <v-icon start>mdi-plus</v-icon> NOVA OPÇÃO
                        </v-btn>
                    </div>

                    <v-window v-model="modal.activeTab" class="overflow-visible">
                        <v-window-item v-for="(quote, idx) in modal.quotes" :key="quote.ui_id" :value="idx">

                            <v-card variant="outlined" class="bg-white rounded-lg border-thin overflow-hidden shadow-sm">
                                <div class="bg-orange-lighten-5 border-b px-5 py-3 d-flex align-center gap-2">
                                    <v-icon size="20" color="warning">mdi-domain</v-icon>
                                    <span class="text-subtitle-2 font-weight-black text-uppercase text-orange-darken-4 tracking-wide">Fornecedor desta Opção</span>
                                </div>
                                <div class="pa-5 pb-2">
                                    <v-autocomplete v-model="quote.supplier_id" :items="auxData.suppliers" item-title="name" item-value="id" label="Selecione o Fornecedor*" variant="outlined" density="comfortable" color="warning" class="ui-field font-weight-bold">
                                        <template v-slot:prepend-item>
                                            <v-list-item title="Cadastrar Novo Fornecedor" prepend-icon="mdi-plus-circle" class="text-warning font-weight-black bg-orange-lighten-5" @click="openQuickSupplierModal"></v-list-item>
                                            <v-divider class="my-2"></v-divider>
                                        </template>
                                    </v-autocomplete>
                                </div>

                                <div class="bg-grey-lighten-4 border-y px-5 py-2 d-flex align-center justify-space-between">
                                    <div class="d-flex align-center gap-2"><v-icon size="20" color="warning">mdi-format-list-bulleted</v-icon><span class="text-subtitle-2 font-weight-black text-uppercase text-grey-darken-3 tracking-wide">Itens Orçados</span></div>
                                </div>
                                <div class="pa-5 bg-white border-b border-opacity-50">
                                    <v-row dense align="center" class="row-gap">
                                        <v-col cols="12" md="4">
                                            <v-autocomplete v-model="currentItem.product_id" :items="auxData.products" item-title="name" item-value="id" label="Buscar Produto (Opcional)" variant="outlined" density="comfortable" hide-details color="warning" class="ui-field font-weight-bold" @update:model-value="onProductSelect">
                                                <template v-slot:prepend-item><v-list-item title="Cadastrar Novo Produto" prepend-icon="mdi-plus-circle" class="text-primary font-weight-black bg-blue-lighten-5" @click="openQuickProductModal"></v-list-item><v-divider class="my-2"></v-divider></template>
                                            </v-autocomplete>
                                        </v-col>
                                        <v-col cols="12" md="3" v-if="!currentItem.product_id">
                                            <v-text-field v-model="currentItem.description" label="Descrição Avulsa*" variant="outlined" density="comfortable" hide-details class="ui-field"></v-text-field>
                                        </v-col>
                                        <v-col cols="4" md="1">
                                            <v-select v-model="currentItem.unit_of_measure" :items="['un', 'm', 'kg', 'g', 'l', 'cx', 'par', 'pct']" label="UN*" variant="outlined" density="comfortable" hide-details color="warning" class="ui-field font-weight-bold text-center"></v-select>
                                        </v-col>
                                        <v-col cols="4" md="1">
                                            <v-text-field v-model.number="currentItem.quantity" label="Qtd.*" type="number" min="1" variant="outlined" density="comfortable" hide-details class="ui-field font-weight-bold text-center" @input="calcCurrentTotal"></v-text-field>
                                        </v-col>
                                        <v-col cols="4" md="1">
                                            <v-text-field v-model.number="currentItem.unit_price" label="V. Unit.*" type="number" step="0.01" variant="outlined" density="comfortable" hide-details class="ui-field font-weight-bold text-orange-darken-3" prefix="R$" @input="calcCurrentTotal"></v-text-field>
                                        </v-col>
                                        <v-col cols="12" md="2" class="d-flex justify-end">
                                            <v-btn color="blue-darken-3" variant="flat" height="48" class="btn-3d w-100 font-weight-bold text-body-2" @click="addItemToTab(quote)" :disabled="!isCurrentItemValid"><v-icon start size="20">mdi-plus-thick</v-icon> Adicionar</v-btn>
                                        </v-col>
                                    </v-row>
                                </div>

                                <div class="overflow-auto custom-scroll" style="min-height: 150px; max-height: 300px;">
                                    <div class="grid-header sticky-head grid-surface-light border-b" style="grid-template-columns: 60px 2fr 80px 100px 140px 140px 100px; min-width: 900px;">
                                        <div class="cell center header-text">Seq.</div><div class="cell header-text">Descrição do Item</div><div class="cell center header-text">UN</div><div class="cell center header-text">Qtd</div><div class="cell center header-text">Valor Unit.</div><div class="cell center header-text text-orange-darken-3">Subtotal</div><div class="cell center header-text">Ações</div>
                                    </div>
                                    <div v-if="quote.items.length === 0" class="d-flex flex-column justify-center align-center py-6 opacity-40 bg-grey-lighten-5 h-100 min-w-full">
                                        <span class="text-body-2 font-weight-bold">A lista desta opção está vazia.</span>
                                    </div>
                                    <div v-else v-for="(it, i) in quote.items" :key="it.ui_id" class="grid-row" :class="zebraClass(i)" style="grid-template-columns: 60px 2fr 80px 100px 140px 140px 100px; min-width: 900px;">
                                        <div class="cell center font-weight-black text-grey-darken-1">{{ i + 1 }}</div>
                                        <div class="cell"><span class="font-weight-medium text-grey-darken-4 text-truncate">{{ it.product_name || it.description }}</span></div>
                                        <div class="cell center"><span class="font-weight-bold text-grey-darken-3 text-uppercase">{{ it.unit_of_measure }}</span></div>
                                        <div class="cell center"><span class="font-mono font-weight-medium">{{ it.quantity }}</span></div>
                                        <div class="cell center"><span class="font-mono font-weight-medium">{{ formatCurrencyValue(it.unit_price) }}</span></div>
                                        <div class="cell center bg-orange-lighten-5"><span class="font-mono font-weight-black text-orange-darken-3">{{ formatCurrency(it.total_price) }}</span></div>
                                        <div class="cell center"><v-btn icon size="small" class="action-btn btn-3d action-del" @click="removeItemFromTab(quote, i)" variant="flat"><v-icon size="16">mdi-close-thick</v-icon></v-btn></div>
                                    </div>
                                </div>

                                <div class="bg-grey-lighten-4 border-y px-5 py-2 d-flex align-center justify-space-between mt-4">
                                    <div class="d-flex align-center gap-2"><v-icon size="20" color="warning">mdi-cash-multiple</v-icon><span class="text-subtitle-2 font-weight-black text-uppercase text-grey-darken-3 tracking-wide">Pagamento Oferecido</span></div>
                                </div>
                                <div class="pa-5">
                                    <v-row dense class="row-gap">
                                        <v-col cols="12" md="4"><v-select v-model="quote.payment.method" :items="['Boleto Bancário', 'PIX', 'Cartão de Crédito', 'Transferência Bancária', 'Dinheiro']" label="Forma de Pagamento" variant="outlined" density="comfortable" color="warning" class="ui-field font-weight-bold"></v-select></v-col>
                                        <v-col cols="12" md="4"><v-select v-model="quote.payment.condition" :items="['À Vista', 'Parcelado']" label="Condição" variant="outlined" density="comfortable" color="warning" class="ui-field font-weight-bold" @update:model-value="onConditionChange(quote)"></v-select></v-col>
                                        <v-col cols="12" md="4" v-if="quote.payment.condition === 'Parcelado'"><v-select v-model.number="quote.payment.installments" :items="[2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]" label="Parcelas" variant="outlined" density="comfortable" color="warning" class="ui-field font-weight-bold" @update:model-value="generateInstallmentsForTab(quote)"></v-select></v-col>

                                        <v-col cols="12" v-if="quote.payment.details.length > 0">
                                            <div class="border-thin rounded-lg overflow-hidden mt-2">
                                                <div class="bg-grey-lighten-4 px-4 py-2 text-caption font-weight-black text-uppercase border-b d-flex justify-space-between"><span>Parcelas Mapeadas</span><v-btn size="small" variant="text" color="primary" class="btn-3d" @click="generateInstallmentsForTab(quote)">Recalcular</v-btn></div>
                                                <div class="pa-4 bg-white">
                                                    <v-row dense>
                                                        <v-col cols="12" md="6" v-for="(inst, iIdx) in quote.payment.details" :key="iIdx">
                                                            <div class="d-flex align-center gap-3 mb-2 bg-grey-lighten-5 pa-2 rounded-lg border">
                                                                <div class="text-body-2 font-weight-black text-grey-darken-2" style="width: 40px;">{{ iIdx + 1 }}x</div>
                                                                <v-text-field v-model="inst.due_date" label="Vencimento" type="date" variant="outlined" density="comfortable" hide-details class="bg-white flex-grow-1 ui-field"></v-text-field>
                                                                <v-text-field v-model.number="inst.value" label="Valor (R$)" type="number" step="0.01" variant="outlined" density="comfortable" hide-details class="bg-white flex-grow-1 font-weight-bold text-orange-darken-3 ui-field"></v-text-field>
                                                            </div>
                                                        </v-col>
                                                    </v-row>
                                                </div>
                                            </div>
                                        </v-col>
                                    </v-row>
                                </div>
                                <div class="pa-4 bg-grey-lighten-3 border-t d-flex justify-end align-center shadow-inner">
                                    <div class="d-flex align-center gap-4 bg-white px-6 py-2 rounded-lg elevation-1 border-thin border-warning"><span class="text-body-2 font-weight-black text-uppercase text-grey-darken-2">Valor da Opção:</span><span class="text-h5 font-weight-black text-orange-darken-3 tabular-nums">{{ formatCurrency(calcQuoteTotal(quote)) }}</span></div>
                                </div>
                            </v-card>

                        </v-window-item>
                    </v-window>

                </v-form>
            </v-card-text>

            <div class="px-8 py-5 border-t bg-white d-flex justify-space-between align-center flex-shrink-0 elevation-10 z-10 relative">
                <div class="d-flex align-center gap-2 text-body-2 text-grey font-weight-bold bg-grey-lighten-4 px-4 py-2 rounded-lg border"><v-icon size="20">mdi-account-circle</v-icon> Solicitante: <span class="text-warning text-darken-2 font-weight-black">{{ userStore.profile?.full_name || userStore.user?.email }}</span></div>
                <div class="d-flex gap-3">
                    <v-btn variant="outlined" color="grey-darken-2" class="btn-3d px-8 font-weight-bold text-body-2" height="50" @click="modal.show = false" :disabled="modal.saving">Cancelar</v-btn>
                    <v-btn color="warning" variant="flat" class="btn-3d px-10 font-weight-black text-body-1 text-black shadow-button" height="50" @click="saveQuotation" :loading="modal.saving"><v-icon start size="24" class="mr-2">mdi-content-save-check</v-icon> SALVAR COTAÇÃO</v-btn>
                </div>
            </div>
        </v-card>
    </v-dialog>

    <v-dialog v-model="quickModal.show" :width="quickModal.type === 'supplier' ? 700 : 450">
        <v-card class="pa-6 rounded-lg border-t-lg border-t-warning">
            <div class="d-flex align-center gap-3 mb-6">
                <v-icon size="36" color="warning">{{ quickModal.type === 'product' ? 'mdi-package-variant-closed' : 'mdi-truck-delivery' }}</v-icon>
                <div class="text-h6 font-weight-black leading-none">Cadastro Rápido de {{ quickModal.type === 'product' ? 'Produto' : 'Fornecedor' }}</div>
            </div>

            <template v-if="quickModal.type === 'product'">
                <v-text-field v-model="quickModal.name" label="Nome do Material" variant="outlined" density="comfortable" color="warning" class="font-weight-bold ui-field"></v-text-field>
            </template>

            <template v-else>
                <v-row dense>
                    <v-col cols="12" md="6"><v-text-field v-model="quickModal.supplier.nome" label="Nome / Nome Fantasia*" variant="outlined" density="comfortable" color="warning" class="ui-field font-weight-bold"></v-text-field></v-col>
                    <v-col cols="12" md="6"><v-text-field v-model="quickModal.supplier.razao_social" label="Razão Social" variant="outlined" density="comfortable" color="warning" class="ui-field"></v-text-field></v-col>
                    <v-col cols="12" md="6"><v-text-field v-model="quickModal.supplier.cnpj_cpf" label="CNPJ / CPF*" variant="outlined" density="comfortable" color="warning" class="ui-field font-weight-bold"></v-text-field></v-col>
                    <v-col cols="12" md="6"><v-text-field v-model="quickModal.supplier.telefone" label="Telefone*" variant="outlined" density="comfortable" color="warning" class="ui-field font-weight-bold"></v-text-field></v-col>
                </v-row>
            </template>

            <div class="d-flex justify-end gap-2 mt-4">
                <v-btn variant="text" color="grey-darken-2" class="font-weight-bold btn-3d text-body-2" @click="quickModal.show = false">Cancelar</v-btn>
                <v-btn color="warning" variant="flat" class="font-weight-black px-6 btn-3d text-body-2 text-black" height="44" @click="saveQuickRegistration">Cadastrar</v-btn>
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

const appStore = useAppStore();
const themeStore = useThemeStore();
const companyStore = useCompanyStore();
const userStore = useUserStore();

const loadingPurchases = ref(false);
const purchases = ref<any[]>([]);

const page = ref(1);
const itemsPerPage = 20;

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
    page.value = 1;
    fetchPurchases();
});


const formatCode = (item: any) => {
    if (!item) return '';
    if (item.codigo) return String(item.codigo).padStart(5, '0');
    if (item.sequential_id) return String(item.sequential_id).padStart(5, '0');
    return item.id ? item.id.substring(0, 6).toUpperCase() : 'NOVO';
};

// FILTROS COM BUSCA GLOBAL
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
            (p.created_by_name && p.created_by_name.toLowerCase().includes(s))
        );
    }

    if (filters.startDate) result = result.filter(p => p.order_date >= filters.startDate);
    if (filters.endDate) result = result.filter(p => p.order_date <= filters.endDate);
    if (filters.supplier) result = result.filter(p => p.supplier_id === filters.supplier);

    if (filters.status !== 'Todos') {
        if (filters.status === 'pendente') result = result.filter(p => p.is_quotation);
        else if (filters.status === 'aprovada') result = result.filter(p => !p.is_quotation && p.production_status !== 'rejeitado');
        else if (filters.status === 'rejeitada') result = result.filter(p => p.production_status === 'rejeitado');
    }
    return result;
});

const pageCount = computed(() => Math.ceil(filteredPurchases.value.length / itemsPerPage));
const paginatedPurchases = computed(() => {
    const start = (page.value - 1) * itemsPerPage;
    return filteredPurchases.value.slice(start, start + itemsPerPage);
});

watch(filters, () => { page.value = 1; }, { deep: true });

const auxData = reactive({ suppliers: [] as any[], products: [] as any[], companies: [] as any[], chartOfAccounts: [] as any[], mrJackyId: null as any });

const attachmentModal = reactive({ show: false, loading: false, item: null as any, files: [] as File[] });
const statusModal = reactive({ show: false, loading: false, item: null as any, status: '' });

const statusOptions = [
    { value: 'indefinido', label: 'Pendente' },
    { value: 'em_producao', label: 'Comprado' },
    { value: 'a_caminho', label: 'A Caminho' },
    { value: 'entregue', label: 'Recebido' },
    { value: 'devolucao', label: 'Devolução' },
    { value: 'cancelado', label: 'Cancelado' }
];

const formatProductionStatus = (status: string) => statusOptions.find(s => s.value === status)?.label || 'INDEFINIDO';
const getProductionStatusColor = (status: string) => {
    switch(status) {
        case 'entregue': return 'success';
        case 'a_caminho': return 'info';
        case 'em_producao': return 'primary';
        case 'com_fornecedor': return 'warning';
        case 'devolucao': return 'deep-purple';
        case 'cancelado': return 'error';
        default: return 'grey';
    }
};

const getRejectionReason = (item: any) => {
    if (item.production_status !== 'rejeitado' || !item.audit_log) return 'Cotação Rejeitada';
    const rejectLog = item.audit_log.slice().reverse().find((log: any) => log.action === 'Cotação Rejeitada');
    return rejectLog ? rejectLog.details : 'Rejeitada (Sem justificativa registrada)';
};

const quickModal = reactive({ show: false, type: '', name: '', supplier: { nome: '', razao_social: '', cnpj_cpf: '', telefone: '', celular: '', email: '', cidade: '', estado: '' } });

const modal = reactive({
    show: false, saving: false, files: [] as File[],
    form: { id: '', description: '', chart_of_accounts_id: null, order_date: '', delivery_date: '', notes: '', company_id: null as any, attachments: [] as string[] },
    quotes: [] as any[],
    activeTab: 0
});

const getSupplierName = (id: string) => {
    const sup = auxData.suppliers.find(s => s.id === id);
    return sup ? sup.name : '';
};

const generateEmptyQuote = () => ({
    ui_id: Math.random().toString(36).substr(2, 9),
    supplier_id: null,
    items: [],
    payment: { method: 'Boleto Bancário', condition: 'À Vista', installments: 1, details: [] }
});

const addQuoteOption = () => {
    modal.quotes.push(generateEmptyQuote());
    modal.activeTab = modal.quotes.length - 1;
};

const removeQuoteTab = (index: number) => {
    modal.quotes.splice(index, 1);
    if (modal.activeTab >= modal.quotes.length) modal.activeTab = Math.max(0, modal.quotes.length - 1);
};

const calcQuoteTotal = (quote: any) => {
    return quote.items.reduce((acc: number, curr: any) => acc + Number(curr.total_price), 0);
};

const initialItemState = { ui_id: '', product_id: null, product_name: '', description: '', unit_of_measure: 'un', quantity: 1, unit_price: 0, total_price: 0 };
const currentItem = ref({ ...initialItemState });

const onProductSelect = (prodId: any) => { if (!prodId) { currentItem.value.product_name = ''; return; } const prod = auxData.products.find(p => p.id === prodId); if (prod) { currentItem.value.product_name = prod.name; currentItem.value.description = prod.name; if (!currentItem.value.unit_price) { currentItem.value.unit_price = prod.default_price || 0; calcCurrentTotal(); } } };
const calcCurrentTotal = () => { currentItem.value.total_price = (Number(currentItem.value.quantity) || 0) * (Number(currentItem.value.unit_price) || 0); };
const isCurrentItemValid = computed(() => (currentItem.value.product_id || currentItem.value.description.trim().length > 0) && currentItem.value.quantity > 0 && currentItem.value.unit_price > 0);

const addItemToTab = (quote: any) => {
    if (!isCurrentItemValid.value) return;
    quote.items.push({ ...currentItem.value, ui_id: Math.random().toString(36).substr(2, 9) });
    currentItem.value = { ...initialItemState, ui_id: Math.random().toString(36).substr(2, 9) };
    if (quote.payment.condition === 'À Vista') generateInstallmentsForTab(quote);
};

const removeItemFromTab = (quote: any, index: number) => {
    quote.items.splice(index, 1);
    if (quote.payment.condition === 'À Vista') generateInstallmentsForTab(quote);
};

const onConditionChange = (quote: any) => {
    if (quote.payment.condition === 'À Vista') { quote.payment.installments = 1; }
    else { if (quote.payment.installments === 1) quote.payment.installments = 2; }
    generateInstallmentsForTab(quote);
};

const generateInstallmentsForTab = (quote: any) => {
    const total = calcQuoteTotal(quote);
    const count = quote.payment.installments;
    const baseDate = new Date(modal.form.delivery_date || new Date());
    quote.payment.details = [];
    let instVal = parseFloat((total / count).toFixed(2));
    let diff = total - (instVal * count);
    for (let i = 0; i < count; i++) {
        let val = instVal; if (i === count - 1) val += diff;
        const d = new Date(baseDate); d.setMonth(d.getMonth() + i);
        quote.payment.details.push({ due_date: d.toISOString().split('T')[0], value: Number(val.toFixed(2)) });
    }
};

onMounted(async () => {
    await fetchAuxData();
    await fetchPurchases();
});

const fetchAuxData = async () => {
    if (companyStore.isDemoMode) {
        auxData.suppliers = [
            { id: 'fake-sup-1', name: 'Fornecedor Fictício Alfa' },
            { id: 'fake-sup-2', name: 'Fornecedor Fictício Beta' }
        ];
        auxData.products = [
            { id: 'fake-prod-1', name: 'Malha Fictícia PV', default_price: 15.50 },
            { id: 'fake-prod-2', name: 'Fio de Costura Fictício', default_price: 2.00 }
        ];
        auxData.companies = [
            { id: 'fake-comp-1', trade_name: 'INDÚSTRIA FICTÍCIA' },
            { id: 'fake-comp-2', trade_name: 'VAREJO FICTÍCIO' }
        ];
        auxData.chartOfAccounts = [
            { id: 'fake-acc-1', name: 'Despesas Fictícias c/ Produção' }
        ];
        auxData.mrJackyId = 'fake-comp-1';
        return;
    }

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

    if (companyStore.isDemoMode) {
        purchases.value = [
            {
                id: 'fake-quote-1',
                is_quotation: true,
                production_status: 'pendente',
                description: 'Compra de Tecidos Agosto (Fictício)',
                supplier_name: '2 Opções Cadastradas',
                entity_name: '2 Opções Cadastradas',
                created_by_name: 'Gestor Demo',
                order_date: new Date().toISOString(),
                total_value: 14500.50,
                attachments: [],
                payment_details: {
                    quotation_options: [
                        { supplier_id: 'fake-sup-1', items: [{product_name: 'Malha PV', quantity: 1000, unit_price: 10, total_price: 10000}], payment: { method: 'Boleto', condition: 'Parcelado', installments: 3, details: [] } },
                        { supplier_id: 'fake-sup-2', items: [{product_name: 'Malha PV', quantity: 1000, unit_price: 11, total_price: 11000}], payment: { method: 'PIX', condition: 'À Vista', installments: 1, details: [] } }
                    ]
                }
            },
            {
                id: 'fake-quote-3',
                is_quotation: false,
                production_status: 'rejeitado',
                description: 'Máquina de Costura Nova',
                supplier_name: 'Indústria Fictícia S.A.',
                entity_name: 'Indústria Fictícia S.A.',
                created_by_name: 'Carlos PCP',
                order_date: new Date(Date.now() - 172800000).toISOString(),
                total_value: 12000.00,
                attachments: [],
                audit_log: [{ action: 'Cotação Rejeitada', details: 'Valor muito acima do orçamento.' }],
                payment_details: {}
            }
        ];
        loadingPurchases.value = false;
        return;
    }

    try {
        let query = supabase.from('purchases')
            .select('*, purchase_items(*)')
            .eq('purchase_type', 'product')
            .order('created_at', { ascending: false });

        if (!isAdmin.value) {
            query = query.eq('created_by', userStore.user?.id);
        } else {
            query = query.or(`is_quotation.eq.true,origin.eq.quotation`);
            if (!companyStore.isGlobalView && companyStore.context) {
                query = query.eq('company_id', companyStore.context);
            }
        }

        const { data, error } = await query;
        if (error) throw error;

        // Filtra apenas cotações (is_quotation) ou que originaram de cotação (origin = quotation)
        purchases.value = (data || []).filter((p: any) => p.is_quotation || p.origin === 'quotation');
    } catch(e) { appStore.showSnackbar('Erro ao buscar cotações', 'error'); }
    finally { loadingPurchases.value = false; }
};

// ========================================================
// DECISÃO DO ADMIN (Modal de Escolha)
// ========================================================
const approvalModal = reactive({ show: false, loading: false, item: null as any, reason: '', options: [] as any[], selectedIndex: null as number | null });

const openApprovalModal = (item: any) => {
    approvalModal.item = item;
    approvalModal.reason = '';

    if (item.payment_details?.quotation_options && item.payment_details.quotation_options.length > 0) {
        approvalModal.options = item.payment_details.quotation_options;
    } else {
        approvalModal.options = [{
            supplier_id: item.supplier_id,
            items: item.purchase_items || [],
            payment: item.payment_details || { condition: 'À Vista', installments: 1, details: [] }
        }];
    }
    approvalModal.selectedIndex = null;
    approvalModal.show = true;
};

const executeApproval = async () => {
    if (companyStore.isDemoMode) return appStore.showSnackbar('Ação não permitida em modo demonstração', 'warning');
    if (approvalModal.selectedIndex === null) return appStore.showSnackbar('Selecione uma opção de fornecedor.', 'warning');

    approvalModal.loading = true;
    try {
        const item = approvalModal.item;
        const selectedQuote = approvalModal.options[approvalModal.selectedIndex];
        const supInfo = auxData.suppliers.find(s => s.id === selectedQuote.supplier_id);

        const finalPaymentDetails = { ...selectedQuote.payment };
        delete finalPaymentDetails.quotation_options;

        const currentLogs = item.audit_log || [];
        const newLog = {
            date: new Date().toISOString(),
            user: userStore.profile?.full_name || userStore.user?.email,
            action: 'Cotação Aprovada',
            details: `Aprovado com ${supInfo?.name || 'Fornecedor'}. Movido para Compras.`
        };

        const updatePayload = {
            is_quotation: false,
            production_status: 'indefinido',
            supplier_id: selectedQuote.supplier_id,
            supplier_name: supInfo?.name || 'Fornecedor',
            total_value: calcQuoteTotal(selectedQuote),
            payment_details: finalPaymentDetails,
            audit_log: [...currentLogs, newLog]
        };

        const { error } = await supabase.from('purchases').update(updatePayload).eq('id', item.id);
        if(error) throw error;

        await supabase.from('purchase_items').delete().eq('purchase_id', item.id);
        const itemsPayload = selectedQuote.items.map((i:any) => ({
            purchase_id: item.id,
            product_id: i.product_id,
            description: i.product_id ? i.product_name : i.description,
            quantity: i.quantity,
            unit_of_measure: i.unit_of_measure,
            unit_price: i.unit_price,
            total_price: i.total_price
        }));
        await supabase.from('purchase_items').insert(itemsPayload);

        appStore.showSnackbar('Cotação Aprovada com sucesso!', 'success');
        approvalModal.show = false;
        fetchPurchases();
    } catch (e: any) {
        appStore.showSnackbar('Erro ao aprovar: ' + e.message, 'error');
    } finally {
        approvalModal.loading = false;
    }
};

const executeRejection = async () => {
    if (companyStore.isDemoMode) return appStore.showSnackbar('Ação não permitida em modo demonstração', 'warning');
    approvalModal.loading = true;
    try {
        const item = approvalModal.item;
        const currentLogs = item.audit_log || [];
        const newLog = {
            date: new Date().toISOString(),
            user: userStore.profile?.full_name || userStore.user?.email,
            action: 'Cotação Rejeitada',
            details: `Motivo: ${approvalModal.reason || 'Sem justificativa.'}`
        };

        const { error } = await supabase.from('purchases').update({
            production_status: 'rejeitado',
            audit_log: [...currentLogs, newLog]
        }).eq('id', item.id);

        if(error) throw error;

        appStore.showSnackbar('Cotação Rejeitada.', 'error');
        approvalModal.show = false;
        fetchPurchases();
    } catch (e: any) {
        appStore.showSnackbar('Erro: ' + e.message, 'error');
    } finally {
        approvalModal.loading = false;
    }
};

// ========================================================
// AÇÕES DO MODAL DE CRIAÇÃO (Novo/Editar/Clonar)
// ========================================================
const openNewQuotationModal = () => {
    const defaultCompanyId = isAdmin.value ? (companyStore.context || auxData.mrJackyId || (auxData.companies.length ? auxData.companies[0].id : null)) : userStore.profile?.company_id;

    modal.form = {
        id: '', description: '', chart_of_accounts_id: null,
        order_date: new Date().toISOString().split('T')[0],
        delivery_date: new Date().toISOString().split('T')[0],
        notes: '', company_id: defaultCompanyId, attachments: []
    };
    modal.files = [];
    modal.quotes = [generateEmptyQuote()];
    modal.activeTab = 0;
    currentItem.value = { ...initialItemState, ui_id: Math.random().toString(36).substr(2, 9) };
    modal.show = true;
};

const openEditModal = (item: any) => {
    modal.form = { ...item, attachments: item.attachments || [] };
    modal.files = [];
    if (item.payment_details?.quotation_options && item.payment_details.quotation_options.length > 0) {
        modal.quotes = item.payment_details.quotation_options;
    } else {
        modal.quotes = [{
            ui_id: Math.random().toString(36).substr(2, 9),
            supplier_id: item.supplier_id,
            items: (item.purchase_items || []).map((i:any) => ({...i, product_name: i.description, ui_id: Math.random().toString(36).substr(2, 9)})),
            payment: item.payment_details || { method: 'Boleto Bancário', condition: 'À Vista', installments: 1, details: [] }
        }];
    }
    modal.activeTab = 0;
    modal.show = true;
};

const cloneQuotation = (item: any) => {
    openEditModal(item);
    setTimeout(() => {
        modal.form.id = '';
        modal.form.description = `${modal.form.description} (Cópia)`;
    }, 100);
};

const saveQuotation = async () => {
    if (companyStore.isDemoMode) return appStore.showSnackbar('Ação não permitida em modo demonstração', 'warning');
    const targetCompanyId = modal.form.company_id;

    if (!targetCompanyId) { appStore.showSnackbar('Nenhuma empresa selecionada.', 'warning'); return; }
    if (!modal.form.description) { appStore.showSnackbar('A Descrição Global é obrigatória.', 'warning'); return; }

    // VALIDAÇÃO DE ANEXO OBRIGATÓRIO
    const isNew = !modal.form.id;
    const hasExistingAttachments = !isNew && modal.form.attachments && modal.form.attachments.length > 0;
    const hasNewFiles = modal.files && modal.files.length > 0;

    if (!hasExistingAttachments && !hasNewFiles) {
        appStore.showSnackbar('É obrigatório anexar pelo menos um arquivo ou orçamento para enviar a cotação para aprovação.', 'error');
        return;
    }

    const invalidQuote = modal.quotes.find(q => !q.supplier_id || q.items.length === 0);
    if (invalidQuote) { appStore.showSnackbar('Existem opções sem fornecedor ou sem itens. Verifique as abas.', 'warning'); return; }

    modal.saving = true;
    try {
        // Realiza o Upload dos Arquivos (se houverem)
        let newAttachmentUrls: string[] = [];
        if (hasNewFiles) {
            for (const file of modal.files) {
                const fp = `purchases/${Date.now()}-${Math.random().toString(36).substring(7)}.${file.name.split('.').pop()}`;
                const { error } = await supabase.storage.from('finance-attachments').upload(fp, file);
                if (!error) {
                    const { data } = supabase.storage.from('finance-attachments').getPublicUrl(fp);
                    if (data?.publicUrl) newAttachmentUrls.push(data.publicUrl);
                }
            }
        }

        const mainQuote = modal.quotes[0];
        const supInfo = auxData.suppliers.find(s => s.id === mainQuote.supplier_id);

        const purchaseHeader = {
            purchase_type: 'product',
            is_quotation: true,
            origin: 'quotation',
            description: modal.form.description,
            supplier_id: mainQuote.supplier_id,
            supplier_name: supInfo?.name || 'Vários Fornecedores',
            entity_name: supInfo?.name || 'Vários Fornecedores',
            chart_of_accounts_id: modal.form.chart_of_accounts_id,
            order_date: modal.form.order_date,
            delivery_date: modal.form.delivery_date,
            total_value: calcQuoteTotal(mainQuote),
            move_stock: false,
            notes: modal.form.notes,
            company_id: targetCompanyId,
            attachments: isNew ? newAttachmentUrls : [...(modal.form.attachments || []), ...newAttachmentUrls],
            payment_details: {
                ...mainQuote.payment,
                quotation_options: modal.quotes
            },
        } as any;

        if (isNew) {
            purchaseHeader.created_by = userStore.user?.id;
            purchaseHeader.created_by_name = userStore.profile?.full_name || userStore.user?.email;
            purchaseHeader.production_status = 'pendente';
            purchaseHeader.audit_log = [{ date: new Date().toISOString(), user: purchaseHeader.created_by_name, action: 'Criação', details: `${modal.quotes.length} opção(ões) de fornecimento anexadas.` }];

            const { data: hd, error: he } = await supabase.from('purchases').insert(purchaseHeader).select('id').single();
            if (he) throw he;

            const itemsPayload = mainQuote.items.map((i:any) => ({
                purchase_id: hd.id,
                product_id: i.product_id,
                description: i.product_id ? i.product_name : i.description,
                quantity: i.quantity,
                unit_of_measure: i.unit_of_measure,
                unit_price: i.unit_price,
                total_price: i.total_price
            }));
            await supabase.from('purchase_items').insert(itemsPayload);

        } else {
            purchaseHeader.updated_at = new Date().toISOString();
            purchaseHeader.updated_by_name = userStore.profile?.full_name || userStore.user?.email;
            await supabase.from('purchases').update(purchaseHeader).eq('id', modal.form.id);

            await supabase.from('purchase_items').delete().eq('purchase_id', modal.form.id);
            const itemsPayload = mainQuote.items.map((i:any) => ({
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

        appStore.showSnackbar('Cotação Salva e enviada!', 'success');
        modal.show = false; fetchPurchases();
    } catch(e: any) { appStore.showSnackbar('Erro ao salvar: ' + e.message, 'error'); }
    finally { modal.saving = false; }
};

// ========================================================
// OUTRAS FUNÇÕES AUXILIARES
// ========================================================
const deletePurchase = async (id: string, isQuotation: boolean) => {
    if (companyStore.isDemoMode) return appStore.showSnackbar('Ação não permitida em modo demonstração', 'warning');
    if (!isAdmin.value && !isQuotation) { appStore.showSnackbar('Você não pode excluir uma cotação que já foi aprovada.', 'error'); return; }
    if (!confirm('Excluir permanentemente esta cotação?')) return;
    try { await supabase.from('purchases').delete().eq('id', id); fetchPurchases(); } catch(e) { appStore.showSnackbar('Erro ao excluir', 'error'); }
};

const openAttachmentModal = (item: any) => { attachmentModal.item = item; attachmentModal.files = []; attachmentModal.show = true; };
const uploadAttachmentsToPurchase = async () => {
    if (companyStore.isDemoMode) return appStore.showSnackbar('Ação não permitida em modo demonstração', 'warning');
    const filesArray = Array.isArray(attachmentModal.files) ? attachmentModal.files : (attachmentModal.files ? [attachmentModal.files] : []);
    if (filesArray.length === 0) return;
    attachmentModal.loading = true;
    try {
        const urls = [];
        for (const file of filesArray) {
            const fp = `purchases/${Date.now()}-${Math.random().toString(36).substring(7)}.${file.name.split('.').pop()}`;
            const { error } = await supabase.storage.from('finance-attachments').upload(fp, file);
            if (!error) { const { data } = supabase.storage.from('finance-attachments').getPublicUrl(fp); if (data?.publicUrl) urls.push(data.publicUrl); }
        }
        const updatedAttachments = [...(attachmentModal.item.attachments || []), ...urls];
        await supabase.from('purchases').update({ attachments: updatedAttachments }).eq('id', attachmentModal.item.id);
        appStore.showSnackbar('Anexo salvo!', 'success'); attachmentModal.show = false; fetchPurchases();
    } catch(e: any) { appStore.showSnackbar('Erro: ' + e.message, 'error'); } finally { attachmentModal.loading = false; }
};

const openStatusModal = (item: any) => { statusModal.item = item; statusModal.status = item.production_status || 'indefinido'; statusModal.show = true; };
const saveProductionStatus = async () => {
    if (companyStore.isDemoMode) return appStore.showSnackbar('Ação não permitida em modo demonstração', 'warning');
    statusModal.loading = true;
    try {
        const item = statusModal.item;
        const currentLogs = item.audit_log || [];
        const newLog = { date: new Date().toISOString(), user: userStore.profile?.full_name || userStore.user?.email, action: 'Alteração Logística', details: `De "${formatProductionStatus(item.production_status)}" para "${formatProductionStatus(statusModal.status)}"` };
        const { error } = await supabase.from('purchases').update({ production_status: statusModal.status, audit_log: [...currentLogs, newLog] }).eq('id', item.id);
        if (error) throw error;
        appStore.showSnackbar('Status Atualizado!', 'success'); statusModal.show = false; fetchPurchases();
    } catch(e: any) { appStore.showSnackbar('Erro: ' + e.message, 'error'); } finally { statusModal.loading = false; }
};

const openQuickSupplierModal = () => { quickModal.type = 'supplier'; quickModal.supplier = { nome: '', razao_social: '', cnpj_cpf: '', telefone: '', celular: '', email: '', cidade: '', estado: '' }; quickModal.show = true; };
const openQuickProductModal = () => { quickModal.type = 'product'; quickModal.name = ''; quickModal.show = true; };
const saveQuickRegistration = async () => {
    if (companyStore.isDemoMode) return appStore.showSnackbar('Ação não permitida em modo demonstração', 'warning');
    try {
        if (quickModal.type === 'supplier') {
            const spl = quickModal.supplier;
            if (!spl.nome || !spl.cnpj_cpf || !spl.telefone) return appStore.showSnackbar('Preencha Nome, Documento e Telefone.', 'warning');
            const { data } = await supabase.from('suppliers_mj').insert({ nome: spl.nome, razao_social: spl.razao_social || spl.nome, cnpj_cpf: spl.cnpj_cpf, telefone: spl.telefone }).select('id, nome').single();
            if (data) { auxData.suppliers.push({ id: data.id, name: data.nome }); modal.quotes[modal.activeTab].supplier_id = data.id; }
        } else {
            if (!quickModal.name) return;
            const { data } = await supabase.from('stock').insert({ fabric_type: quickModal.name, unit_of_measure: 'un', base_price: 0, available_meters: 0 }).select('id, fabric_type, base_price').single();
            if (data) { auxData.products.push({ id: data.id, name: data.fabric_type, default_price: data.base_price }); currentItem.value.product_id = data.id; onProductSelect(data.id); }
        }
        quickModal.show = false; appStore.showSnackbar('Cadastrado!', 'success');
    } catch(e) { appStore.showSnackbar('Erro no cadastro rápido.', 'error'); }
};

// RELATÓRIOS (EXPORTAÇÃO)
const exportListToPDF = () => {
    const doc = new jsPDF('landscape');
    doc.setFont("helvetica", "bold");
    doc.setFontSize(16);
    doc.text("Relatório de Cotações", 14, 15);
    doc.setFontSize(10);
    doc.setFont("helvetica", "normal");
    doc.text(`Gerado em: ${new Date().toLocaleString('pt-BR')}`, 14, 22);

    const tableData = filteredPurchases.value.map(i => [
        formatCode(i),
        i.supplier_name || i.entity_name || 'Múltiplos',
        i.description || '-',
        i.created_by_name || 'Desconhecido',
        formatDateSafe(i.order_date),
        i.production_status === 'rejeitado' ? 'Rejeitada' : (i.is_quotation ? 'Pendente' : 'Aprovada'),
        formatCurrency(i.total_value)
    ]);

    autoTable(doc, {
        startY: 30,
        theme: "grid",
        head: [["Cód", "Fornecedor(es)", "Descrição", "Solicitante", "Emissão", "Status Decisão", "Valor Estimado"]],
        body: tableData,
        styles: { fontSize: 9, cellPadding: 3 },
        headStyles: { fillColor: [40, 40, 40], textColor: 255, fontStyle: 'bold' }
    });

    doc.save("Relatorio_Cotacoes.pdf");
};

const exportToExcel = () => {
    const data = filteredPurchases.value.map(i => ({
        "Cód": formatCode(i),
        "Fornecedor(es)": i.supplier_name || i.entity_name || 'Múltiplos',
        "Descrição": i.description,
        "Solicitante": i.created_by_name || 'Desconhecido',
        "Emissão": formatDateSafe(i.order_date),
        "Status Decisão": i.production_status === 'rejeitado' ? 'Rejeitada' : (i.is_quotation ? 'Pendente' : 'Aprovada'),
        "Valor Estimado": i.total_value
    }));
    const ws = XLSX.utils.json_to_sheet(data);
    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, "Cotacoes");
    XLSX.writeFile(wb, "Relatorio_Cotacoes.xlsx");
};


const formatDateSafe = (d: string) => { if (!d) return '-'; return d.split('T')[0].split('-').reverse().join('/'); };
const formatCurrency = (val:any) => new Intl.NumberFormat('pt-BR', {style:'currency',currency:'BRL'}).format(Number(val)||0);
const formatCurrencyValue = (val:any) => new Intl.NumberFormat('pt-BR', {minimumFractionDigits:2}).format(Number(val)||0);
const zebraClass = (i:number) => themeStore.currentMode!=='light' ? (i%2===0?'zebra-dark-a':'zebra-dark-b') : (i%2===0?'zebra-light-a':'zebra-light-b');
</script>

<style scoped lang="scss">
/* FIX GLOBAL PARA O TOOLTIP DE MODO CLARO */
:global(.tooltip-custom) {
    background-color: #212121 !important;
    color: #ffffff !important;
    font-weight: 700 !important;
    font-size: 12px !important;
    border-radius: 6px !important;
    box-shadow: 0px 4px 10px rgba(0,0,0,0.3) !important;
}

.receivables-layout { position: relative; }
.bg-glass-dark {
    .text-grey-darken-4,
    .text-grey-darken-3,
    .text-grey-darken-2,
    .text-grey-darken-1,
    .text-grey {
        color: rgba(255,255,255,0.9) !important;
    }
}
.bg-glass-header { background: rgba(20,20,24,0.55); backdrop-filter: blur(14px); }
.border-bottom-white-05 { border-bottom: 1px solid rgba(255,255,255,0.08); }
.bg-gradient-orange-dark { background: linear-gradient(135deg, #EF6C00, #BF360C); border: 1px solid rgba(255,255,255,0.1); }
.ui-field :deep(.v-field) { border-radius: 6px !important; background-color: #ffffff; font-size: 14px; }

.grid-scroll { scrollbar-gutter: stable; -webkit-overflow-scrolling: touch; }
.custom-scroll::-webkit-scrollbar { width: 8px; height: 8px; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.35); border-radius: 6px; }
.custom-scroll::-webkit-scrollbar-track { background: transparent; }

.grid-header, .grid-row { display: grid; align-items: stretch; width: 100%; min-width: 1220px; }

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

.grid-header .cell { min-height: 44px; font-size: 16px !important; font-weight: 900; text-transform: uppercase; letter-spacing: 0.5px; line-height: 1.2; }

.sticky-head { position: sticky; top: 0; z-index: 20; box-shadow: 0 8px 16px -4px rgba(0, 0, 0, 0.12); }
.bg-glass-dark .sticky-head { box-shadow: 0 8px 20px -4px rgba(0, 0, 0, 0.4); }

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

.flex-grow-1.overflow-hidden > .v-card.flex-grow-1 { border: 1px solid rgba(0,0,0,0.12) !important; }
.bg-glass-dark .flex-grow-1.overflow-hidden > .v-card.flex-grow-1 { border: 1px solid rgba(255,255,255,0.12) !important; }

.actions-inline {
    display: flex;
    gap: 8px;
    justify-content: center;
    flex-wrap: nowrap !important;
    white-space: nowrap;
}

/* Base dos botões de ação */
.action-btn {
    width: 34px !important;
    height: 34px !important;
    color: #fff !important;
}
.action-edit { background: #1976d2 !important; }
.action-del { background: #c62828 !important; }

/* EFEITO 3D E ARREDONDAMENTO PARA BOTÕES */
.btn-3d {
    border-radius: 6px !important;
    box-shadow: 0 3px 5px rgba(0,0,0,0.15), inset 0 2px 0 rgba(255,255,255,0.25) !important;
    transition: transform 0.1s ease, box-shadow 0.1s ease;
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
.shadow-button { box-shadow: 0 4px 15px rgba(230, 81, 0, 0.4); }
.bg-white-20 { background-color: rgba(255,255,255,0.2); }
.tracking-wide { letter-spacing: 0.5px; }
.lh-1-2 { line-height: 1.2; }
.hide-scrollbar::-webkit-scrollbar { display: none; }
.hide-scrollbar { -ms-overflow-style: none; scrollbar-width: none; }
</style>
