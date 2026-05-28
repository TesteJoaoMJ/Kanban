<template>
  <v-dialog
    :model-value="modelValue"
    @update:model-value="$emit('update:modelValue', $event)"
    :max-width="mobile ? '100%' : '1400'"
    :fullscreen="mobile"
    scrollable
    scrim="black opacity-80"
  >
    <v-card class="rounded-0 overflow-hidden d-flex flex-column font-sans" height="85vh"
      :class="themeStore.currentMode === 'light' ? 'bg-white' : 'glass-card border-white-05'"
    >
      <div class="header-bar px-6 py-4 d-flex align-center justify-space-between flex-shrink-0"
           :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 border-b border-grey-lighten-2 shadow-sm' : 'bg-glass-header border-bottom-white-05'">
        <div class="d-flex flex-column">
          <div class="breadcrumb text-caption text-uppercase font-weight-black ls-1 opacity-70">
            <span>Pedidos</span>
            <span class="mx-2">></span>
            <span class="text-primary">Financeiro</span>
          </div>
          <div class="text-h5 font-weight-black tracking-tight leading-none mt-1"
               :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">
            Recebimentos do Pedido #{{ orderNumberLabel }}
          </div>
          <div class="text-caption font-weight-medium opacity-80 mt-1">
            Cliente / Pagador: <b class="text-indigo-darken-4 font-weight-black">{{ props.order?.customer_name || '-' }}</b>
          </div>
        </div>

        <div class="d-flex align-center gap-3">
          <v-btn-toggle
            v-model="viewMode"
            mandatory
            density="compact"
            variant="outlined"
            color="primary"
            divided
            class="d-none d-md-flex bg-white"
          >
            <v-btn value="current" class="text-caption font-weight-bold px-4">
               Recebimentos Atuais
            </v-btn>
            <v-btn value="legacy" class="text-caption font-weight-bold px-4">
               Legado
            </v-btn>
            <v-btn value="logs" class="text-caption font-weight-bold px-4" prepend-icon="mdi-shield-check">
               Auditoria
            </v-btn>
          </v-btn-toggle>

          <template v-if="viewMode === 'current'">
            <v-tooltip
              :text="plannedRows.length > 0 ? 'Finalize primeiro o Total em aberto abaixo. Assim o pedido não fica com valores duplicados.' : 'Criar uma nova parcela manualmente.'"
              location="bottom"
            >
              <template v-slot:activator="{ props }">
                <span v-bind="props">
                  <v-btn
                    color="success"
                    variant="flat"
                    class="btn-3d px-4 font-weight-bold text-caption text-uppercase"
                    prepend-icon="mdi-plus"
                    height="40"
                    @click="openCreateModal()"
                    :disabled="plannedRows.length > 0"
                  >
                    Nova Parcela
                  </v-btn>
                </span>
              </template>
            </v-tooltip>
          </template>

          <v-btn
            variant="outlined"
            class="btn-3d"
            height="40"
            prepend-icon="mdi-refresh"
            :loading="loadingReceivables"
            :color="themeStore.currentMode === 'light' ? 'grey-darken-3' : 'white'"
            @click="fetchAll()"
          >
            <span class="d-none d-sm-inline">Atualizar</span>
          </v-btn>

          <v-btn icon variant="text" class="icon-rect bg-grey-lighten-3 ml-2" height="40" width="40" @click="$emit('update:modelValue', false)">
            <v-icon color="grey-darken-3">mdi-close</v-icon>
          </v-btn>
        </div>
      </div>

      <div class="px-6 py-4 flex-shrink-0 border-b bg-white z-10 shadow-sm" v-if="viewMode === 'current'">
        <v-row dense class="row-gap-sm">
          <v-col cols="12" sm="3">
            <v-card class="kpi-card kpi-rect bg-gradient-info hover-elevate py-3 px-4" elevation="2">
              <div class="kpi-bg-icon"><v-icon>mdi-tag-text-outline</v-icon></div>
              <div class="d-flex flex-column position-relative z-10">
                <div class="d-flex align-center gap-2">
                  <v-icon size="18" class="opacity-80">mdi-tag-text-outline</v-icon>
                  <span class="kpi-label">Valor do Pedido</span>
                </div>
                <div class="kpi-number-group my-1">
                  <span class="text-body-2 font-weight-medium mr-1 opacity-70">R$</span>
                  <span class="kpi-value">{{ formatCurrencyValue(orderTotal) }}</span>
                </div>
                <div class="kpi-footer mt-1">Total da Venda</div>
              </div>
            </v-card>
          </v-col>

          <v-col cols="12" sm="3">
            <v-card class="kpi-card kpi-rect bg-gradient-purple hover-elevate py-3 px-4" elevation="2">
              <div class="kpi-bg-icon"><v-icon>mdi-cash-multiple</v-icon></div>
              <div class="d-flex flex-column position-relative z-10">
                <div class="d-flex align-center gap-2">
                  <v-icon size="18" class="opacity-80">mdi-cash-multiple</v-icon>
                  <span class="kpi-label">Já programado</span>
                </div>
                <div class="kpi-number-group my-1">
                  <span class="text-body-2 font-weight-medium mr-1 opacity-70">R$</span>
                  <span class="kpi-value">{{ formatCurrencyValue(totalLaunched) }}</span>
                </div>
                <div class="kpi-footer mt-1">Recebimentos criadas no financeiro</div>
              </div>
            </v-card>
          </v-col>

          <v-col cols="12" sm="3">
            <v-card class="kpi-card kpi-rect bg-gradient-green hover-elevate py-3 px-4" elevation="2">
              <div class="kpi-bg-icon"><v-icon>mdi-check-all</v-icon></div>
              <div class="d-flex flex-column position-relative z-10">
                <div class="d-flex align-center gap-2">
                  <v-icon size="18" class="opacity-80">mdi-check-all</v-icon>
                  <span class="kpi-label">Já recebido</span>
                </div>
                <div class="kpi-number-group my-1">
                  <span class="text-body-2 font-weight-medium mr-1 opacity-70">R$</span>
                  <span class="kpi-value">{{ formatCurrencyValue(totalPaid) }}</span>
                </div>
                <div class="kpi-footer mt-1">Dinheiro já confirmado</div>
              </div>
            </v-card>
          </v-col>

          <v-col cols="12" sm="3">
            <v-card class="kpi-card kpi-rect hover-elevate py-3 px-4"
              :class="remainingBalance > 0.05 ? 'bg-gradient-red' : 'bg-gradient-gray'" elevation="2">
              <div class="kpi-bg-icon"><v-icon>mdi-scale-balance</v-icon></div>
              <div class="d-flex flex-column position-relative z-10">
                <div class="d-flex align-center gap-2">
                  <v-icon size="18" class="opacity-80">mdi-scale-balance</v-icon>
                  <span class="kpi-label">Total em aberto</span>
                </div>
                <div class="kpi-number-group my-1">
                  <span class="text-body-2 font-weight-medium mr-1 opacity-70">R$</span>
                  <span class="kpi-value">{{ formatCurrencyValue(Math.max(0, remainingBalance)) }}</span>
                </div>
                <div class="kpi-footer mt-1">Valor que ainda falta lançar/receber</div>
              </div>
            </v-card>
          </v-col>
        </v-row>
      </div>

      <div class="flex-grow-1 d-flex flex-column overflow-hidden bg-grey-lighten-4 pt-4 px-4 px-md-6 pb-6">

        <v-card
          class="d-flex flex-column flex-grow-1 rounded-xl border-thin overflow-hidden shadow-sm"
          :class="themeStore.currentMode === 'light' ? 'bg-white' : 'glass-card'"
          :elevation="0"
        >
          <div class="table-responsive flex-grow-1 overflow-y-auto custom-scroll">

            <template v-if="viewMode === 'current'">
                <div class="section-title px-4 py-4 d-flex align-center justify-space-between"
                     :class="themeStore.currentMode === 'light' ? 'bg-white border-b' : 'bg-white-05 border-bottom-white-05'">
                  <div class="d-flex align-center gap-3">
                    <div class="bg-indigo-darken-3 pa-2 rounded-lg d-flex align-center justify-center text-white"><v-icon size="20">mdi-cash-register</v-icon></div>
                    <div class="d-flex flex-column">
                      <div class="text-subtitle-1 font-weight-black ls-1 text-uppercase text-grey-darken-3">Recebimentos do Pedido</div>
                      <div class="text-[11px] font-weight-medium text-grey">Veja o que já foi criado no financeiro. Clique em “Em aberto” para receber total ou parcialmente.</div>
                    </div>
                  </div>
                  <v-chip class="rounded chip-3d" size="small" variant="flat" color="blue-grey">
                    {{ realReceivables.length }} recebido(s)
                  </v-chip>
                </div>

                <div class="grid-header sticky-head"
                     :class="themeStore.currentMode === 'light' ? 'grid-surface-light' : 'grid-surface-dark'">
                  <div class="cell header-text">Descrição e Comprovantes</div>
                  <div class="cell header-text">Plano de Contas</div>
                  <div class="cell center header-text">Vencimento</div>
                  <div class="cell right header-text">Valor (R$)</div>
                  <div class="cell center header-text">Forma</div>
                  <div class="cell center header-text">Status</div>
                  <div class="cell center header-text">Ações</div>
                </div>

                <div v-if="loadingReceivables" class="d-flex flex-column justify-center align-center py-12 bg-white w-100">
                  <v-progress-circular indeterminate color="primary" size="48" width="4"></v-progress-circular>
                  <span class="text-caption mt-3 font-weight-bold opacity-70">Buscando do financeiro...</span>
                </div>

                <div v-else-if="realReceivables.length === 0" class="d-flex flex-column justify-center align-center opacity-60 gap-2 py-12 bg-white w-100">
                  <v-icon size="56" color="grey-lighten-1">mdi-file-hidden</v-icon>
                  <span class="text-subtitle-2 font-weight-bold text-grey-darken-2">Nenhum recebimento criado ainda</span>
                  <span class="text-caption opacity-70">Use o Total em aberto abaixo para receber total ou parcialmente.</span>
                </div>

                <div
                  v-else
                  v-for="(rec, index) in realReceivables"
                  :key="rec.uniqueKey"
                  class="grid-row hover-bg-row transition-colors"
                  :class="[
                    themeStore.currentMode === 'light' ? 'grid-row-light' : 'grid-row-dark',
                    zebraClass(index)
                  ]"
                >
                  <div class="cell">
                    <div class="d-flex flex-column overflow-hidden w-100 py-2 justify-center">
                      <div class="text-truncate list-text-12 font-weight-black text-grey-darken-4" :title="rec.description">
                        {{ rec.description || 'Recebimento' }}
                      </div>
                      <div class="text-truncate list-text-10 opacity-70 mt-1">
                        ID: <span class="font-mono">{{ rec.id }}</span>
                        <span v-if="rec.company_name_cache" class="ml-2 text-[10px] font-weight-bold text-indigo">[{{ rec.company_name_cache }}]</span>
                      </div>

                      <div class="d-flex flex-wrap gap-2 mt-2">
                        <template v-if="getAttachments(rec).length > 0">
                            <v-chip
                              v-for="(att, i) in getAttachments(rec)"
                              :key="i"
                              size="x-small"
                              color="blue-grey-darken-3"
                              variant="flat"
                              class="px-2 font-weight-bold cursor-pointer chip-3d"
                              prepend-icon="mdi-paperclip"
                              @click.stop="openAttachment(att.url)"
                            >
                              <span class="text-truncate" style="max-width: 150px;">{{ att.filename || `Comprovante ${i+1}` }}</span>
                            </v-chip>
                        </template>
                        <span v-else class="text-[10px] text-grey font-italic opacity-60">Sem comprovantes anexados</span>
                      </div>
                    </div>
                  </div>

                  <div class="cell">
                      <div class="text-truncate list-text-11 font-weight-bold text-indigo-darken-4 px-2 py-1 bg-indigo-lighten-5 rounded border border-indigo-lighten-4" :title="rec.chart_of_accounts?.name">
                          {{ rec.chart_of_accounts?.name || 'Não classificado' }}
                      </div>
                  </div>

                  <div class="cell center">
                    <div class="d-flex align-center border border-grey-lighten-2 rounded px-2 py-1 bg-white">
                        <v-icon size="14" class="mr-1" color="grey-darken-1">mdi-calendar</v-icon>
                        <span class="list-text-11 font-mono font-weight-black text-grey-darken-3">
                        {{ formatDateSimple(rec.due_date) }}
                        </span>
                    </div>
                  </div>

                  <div class="cell right">
                    <span class="list-text-14 font-mono font-weight-black" :class="String(rec.status) === 'pago' ? 'text-success-darken-1' : 'text-grey-darken-4'">
                        {{ formatCurrency(rec.value) }}
                    </span>
                  </div>

                  <div class="cell center">
                    <span class="text-truncate list-text-11 font-weight-bold text-grey-darken-3 bg-grey-lighten-3 px-2 py-1 rounded" :title="getPaymentMethodName(rec.payment_method_id)">
                      {{ getPaymentMethodName(rec.payment_method_id) || '-' }}
                    </span>
                  </div>

                  <div class="cell center">
                    <button
                      type="button"
                      class="solid-chip chip-status chip-3d status-click"
                      :class="statusChipClass(rec)"
                      :title="String(rec.status) === 'pago' ? 'Recebimento já confirmado' : 'Clique para receber este recebimento total ou parcialmente'"
                      @click.stop="String(rec.status) !== 'pago' ? openPaymentConfirm(rec) : null"
                    >
                      {{ statusLabel(rec) }}
                    </button>
                  </div>

                  <div class="cell center">
                    <div class="actions-inline">

                      <v-tooltip text="Editar Recebimento" location="top" content-class="bg-grey-darken-4 text-white font-weight-bold text-caption" v-if="String(rec.status) !== 'pago'">
                          <template v-slot:activator="{ props }">
                             <v-btn v-bind="props" icon size="small" variant="flat" color="orange-darken-3" class="action-btn btn-3d" @click.stop="openEditModal(rec)">
                                <v-icon size="16">mdi-pencil</v-icon>
                             </v-btn>
                          </template>
                      </v-tooltip>

                      <v-tooltip text="Anexar Comprovante" location="top" content-class="bg-grey-darken-4 text-white font-weight-bold text-caption">
                        <template v-slot:activator="{ props }">
                          <v-btn v-bind="props" icon size="small" class="action-btn btn-3d bg-blue-grey" variant="flat" @click.stop="openReceiptPicker(rec)">
                            <v-icon size="16">mdi-upload</v-icon>
                          </v-btn>
                        </template>
                      </v-tooltip>

                      <v-menu location="bottom end">
                          <template v-slot:activator="{ props }">
                              <v-btn v-bind="props" icon size="small" variant="flat" color="green-darken-3" class="action-btn btn-3d ml-1">
                                  <v-icon size="18">mdi-dots-vertical</v-icon>
                              </v-btn>
                          </template>
                          <v-list density="compact" class="py-1 border-thin elevation-4 rounded-lg min-w-200">
                              <template v-if="String(rec.status) !== 'pago'">
                                  <v-list-item @click="openPixModal(rec)" value="link" class="hover-bg-grey-lighten-4">
                                      <template v-slot:prepend><v-icon size="18" color="teal-darken-3" class="mr-2">mdi-qrcode-scan</v-icon></template>
                                      <v-list-item-title class="font-weight-bold text-[12px]">Gerar Pix QR Code</v-list-item-title>
                                  </v-list-item>

                                  <v-list-item @click="prepareBoleto(rec)" value="boleto" class="hover-bg-grey-lighten-4">
                                      <template v-slot:prepend><v-icon size="18" color="indigo-darken-3" class="mr-2">mdi-barcode</v-icon></template>
                                      <v-list-item-title class="font-weight-bold text-[12px]">Emitir Boleto Cora</v-list-item-title>
                                  </v-list-item>

                                  <v-list-item v-if="rec.boleto_url" :href="rec.boleto_url" target="_blank" value="view_boleto" class="hover-bg-grey-lighten-4">
                                      <template v-slot:prepend><v-icon size="18" color="red-darken-3" class="mr-2">mdi-file-pdf-box</v-icon></template>
                                      <v-list-item-title class="font-weight-bold text-[12px] text-red-darken-3">Baixar Boleto</v-list-item-title>
                                  </v-list-item>

                                  <v-divider class="my-1"></v-divider>
                                  <v-list-item @click="openPaymentConfirm(rec)" value="pay" class="hover-bg-green-lighten-5">
                                      <template v-slot:prepend><v-icon size="18" color="success" class="mr-2">mdi-check-circle</v-icon></template>
                                      <v-list-item-title class="font-weight-bold text-[12px] text-success-darken-2">Receber total/parcial</v-list-item-title>
                                  </v-list-item>
                              </template>

                              <template v-else>
                                  <v-list-item @click="handlePrintReceipt(rec)" value="print" class="hover-bg-grey-lighten-4">
                                      <template v-slot:prepend><v-icon size="18" color="blue-grey" class="mr-2">mdi-printer</v-icon></template>
                                      <v-list-item-title class="font-weight-bold text-[12px]">Imprimir Recibo</v-list-item-title>
                                  </v-list-item>
                                  <v-divider class="my-1"></v-divider>
                                  <v-list-item @click="revertPaid(rec)" value="revert" class="hover-bg-red-lighten-5">
                                      <template v-slot:prepend><v-icon size="18" color="error" class="mr-2">mdi-undo</v-icon></template>
                                      <v-list-item-title class="font-weight-bold text-[12px] text-error">Estornar Pagamento</v-list-item-title>
                                  </v-list-item>
                              </template>

                              <v-divider class="my-1"></v-divider>
                               <v-list-item @click="deleteReceivable(rec)" value="delete" class="hover-bg-red-lighten-5">
                                  <template v-slot:prepend><v-icon size="18" color="red-darken-4" class="mr-2">mdi-delete</v-icon></template>
                                  <v-list-item-title class="font-weight-bold text-[12px] text-red-darken-4">Excluir Lançamento</v-list-item-title>
                               </v-list-item>
                          </v-list>
                      </v-menu>

                    </div>
                  </div>
                </div>

                <div v-if="!isFullyLaunched" class="mt-8 border-t border-grey-lighten-2">
                  <div class="section-title px-4 py-4 d-flex align-center justify-space-between bg-orange-lighten-5 border-b border-orange-lighten-4">
                    <div class="d-flex align-center gap-3">
                        <div class="bg-orange-darken-3 pa-2 rounded-lg d-flex align-center justify-center text-white"><v-icon size="20">mdi-calendar-clock</v-icon></div>
                        <div class="d-flex flex-column">
                            <div class="text-subtitle-1 font-weight-black ls-1 text-uppercase text-orange-darken-4">Total em aberto</div>
                            <div class="text-[11px] font-weight-medium text-orange-darken-3">Valor que falta receber neste pedido. Você pode receber tudo ou apenas uma parte; a sobra continua aqui.</div>
                        </div>
                    </div>
                    <v-chip class="rounded chip-3d" size="small" variant="flat" color="orange-darken-3">
                      {{ plannedRows.length }} item(s)
                    </v-chip>
                  </div>

                  <div class="grid-header sticky-head grid-surface-light border-b border-orange-lighten-4" style="grid-template-columns: minmax(280px, 1.5fr) 130px 150px 150px 120px;">
                    <div class="cell header-text text-orange-darken-4">Descrição</div>
                    <div class="cell center header-text text-orange-darken-4">Vencimento</div>
                    <div class="cell right header-text text-orange-darken-4">Valor (R$)</div>
                    <div class="cell center header-text text-orange-darken-4">Status</div>
                    <div class="cell center header-text text-orange-darken-4">Ação</div>
                  </div>

                  <div v-if="plannedRows.length === 0" class="d-flex flex-column justify-center align-center opacity-60 gap-2 py-8 bg-white">
                    <span class="text-caption text-grey font-weight-bold">Nenhum valor em aberto neste pedido.</span>
                  </div>

                  <div
                    v-else
                    v-for="(row, idx) in plannedRows"
                    :key="row.uniqueKey"
                    class="grid-row hover-bg-row transition-colors"
                    :class="zebraClass(idx)"
                    style="grid-template-columns: minmax(280px, 1.5fr) 130px 150px 150px 120px;"
                  >
                    <div class="cell">
                      <div class="text-truncate list-text-11 font-weight-bold text-orange-darken-4" :title="row.description">
                        {{ row.description }}
                      </div>
                    </div>

                    <div class="cell center">
                      <span class="list-text-11 font-mono font-weight-black text-grey-darken-3 border border-orange-lighten-3 bg-white px-2 py-1 rounded">{{ formatDateSimple(row.due_date) }}</span>
                    </div>

                    <div class="cell right">
                      <span class="list-text-13 font-mono font-weight-black text-orange-darken-4">{{ formatCurrency(row.value) }}</span>
                    </div>

                    <div class="cell center">
                      <button
                        type="button"
                        class="solid-chip chip-status chip-3d status-click bg-orange-lighten-4 text-orange-darken-4 border border-orange-lighten-3"
                        title="Clique para receber este valor total ou parcialmente"
                        @click.stop="openPaymentConfirmFromOpenBalance(row)"
                      >
                        Em aberto
                      </button>
                    </div>


                    <div class="cell center">
                      <div class="actions-inline">
                        <v-tooltip text="Receber este valor total ou parcialmente" location="top" content-class="bg-grey-darken-4 text-white font-weight-bold text-caption">
                            <template v-slot:activator="{ props }">
                                <v-btn v-bind="props" icon size="small" class="action-btn btn-3d bg-orange-darken-3" variant="flat" @click.stop="openPaymentConfirmFromOpenBalance(row)" :loading="actionLoadingKey === row.uniqueKey">
                                  <v-icon size="18">mdi-cash-check</v-icon>
                                </v-btn>
                            </template>
                        </v-tooltip>
                      </div>
                    </div>
                  </div>
                </div>

                <div v-else class="pa-6 d-flex justify-center bg-white border-t">
                   <v-alert type="success" variant="tonal" class="rounded-lg border-success text-center elevation-0" density="comfortable" style="max-width: 600px;">
                      <div class="font-weight-black text-subtitle-1 d-flex align-center justify-center gap-2 text-success-darken-2"><v-icon>mdi-check-decagram</v-icon> Pedido sem valor em aberto</div>
                      <div class="text-caption mt-1 text-grey-darken-3 font-weight-medium">
                          O valor criado no financeiro ({{ formatCurrency(totalLaunched) }}) já cobre o valor total do pedido ({{ formatCurrency(orderTotal) }}). Nenhum valor restante encontrado.
                      </div>
                   </v-alert>
                </div>
            </template>

            <template v-if="viewMode === 'logs'">
                <div class="section-title px-4 py-4 d-flex align-center justify-space-between bg-blue-grey-lighten-5 border-b border-blue-grey-lighten-3 text-blue-grey-darken-4">
                  <div class="d-flex align-center gap-3">
                      <div class="bg-blue-grey-darken-2 pa-2 rounded-lg d-flex align-center justify-center text-white"><v-icon size="20">mdi-shield-search</v-icon></div>
                      <div class="d-flex flex-column">
                        <div class="text-subtitle-1 font-weight-black text-uppercase ls-1">Auditoria e Segurança</div>
                        <div class="text-[11px] font-weight-medium">Histórico forense de alterações, baixas e estornos.</div>
                      </div>
                  </div>
                  <v-btn size="small" variant="outlined" prepend-icon="mdi-refresh" @click="fetchAuditLogs" color="blue-grey-darken-2" class="font-weight-bold btn-3d bg-white">Atualizar Logs</v-btn>
                </div>

                <div v-if="loadingLogs" class="d-flex justify-center py-12 bg-white">
                    <v-progress-circular indeterminate color="blue-grey" size="48" width="4"></v-progress-circular>
                </div>

                <div v-else-if="auditLogs.length === 0" class="d-flex flex-column justify-center align-center opacity-60 gap-2 py-12 bg-white">
                  <v-icon size="56" color="blue-grey-lighten-2">mdi-shield-check-outline</v-icon>
                  <span class="text-subtitle-2 font-weight-bold text-blue-grey-darken-2">Nenhum registro de auditoria.</span>
                </div>

                <div v-else class="pa-6 bg-white min-h-[500px]">
                    <v-timeline density="comfortable" side="end" align="start">
                        <v-timeline-item
                            v-for="log in auditLogs"
                            :key="log.id"
                            :dot-color="getLogColor(log.action_type)"
                            size="small"
                        >
                            <div class="d-flex flex-column mb-6">
                                <div class="d-flex align-center justify-space-between mb-1">
                                    <span class="font-weight-black text-[13px] mr-2 text-uppercase" :class="`text-${getLogColor(log.action_type)}-darken-2`">{{ formatLogAction(log.action_type) }}</span>
                                    <span class="text-[11px] opacity-70 font-mono font-weight-bold bg-grey-lighten-4 px-2 py-1 rounded">{{ formatDateTime(log.created_at) }}</span>
                                </div>
                                <div class="text-[12px] font-weight-medium text-grey-darken-3 mb-2">
                                    Responsável: <b class="text-indigo-darken-4">{{ log.profiles?.full_name || 'Sistema Integrado' }}</b>
                                    <span v-if="log.ip_address" class="ml-2 opacity-50 text-[10px] font-mono">(IP/FP: {{ log.ip_address.substring(0,8) }}...)</span>
                                </div>

                                <v-card variant="outlined" class="pa-4 bg-grey-lighten-5 border-thin rounded-lg shadow-sm" v-if="log.payload">
                                    <div class="text-[12px] d-flex flex-column gap-2">
                                        <div v-if="log.payload.description" class="font-weight-black text-grey-darken-4">{{ log.payload.description }}</div>
                                        <div class="d-flex align-center gap-3">
                                            <div v-if="log.payload.value" class="bg-white border px-2 py-1 rounded font-mono font-weight-black text-success-darken-2">R$ {{ formatCurrency(log.payload.value).replace('R$', '').trim() }}</div>
                                            <div v-if="log.payload.method" class="bg-white border px-2 py-1 rounded font-weight-bold text-grey-darken-3"><v-icon size="14" class="mr-1">mdi-credit-card-outline</v-icon> {{ log.payload.method }}</div>
                                        </div>

                                        <div v-if="log.payload.reason" class="text-error font-italic bg-red-lighten-5 px-2 py-1 rounded mt-1">Motivo: {{ log.payload.reason }}</div>

                                        <div v-if="log.payload.attachment_url" class="mt-2 pt-2 border-t border-dashed border-grey-lighten-2">
                                            <v-btn size="small" variant="tonal" color="blue-darken-2" class="font-weight-bold text-caption px-3" height="28" @click="openAttachment(log.payload.attachment_url)">
                                                <v-icon size="14" start>mdi-paperclip</v-icon>
                                                Visualizar Comprovante
                                            </v-btn>
                                        </div>

                                        <div v-if="log.action_type === 'RECEIVABLE_EDITED'" class="bg-orange-lighten-5 border border-orange-lighten-4 pa-3 rounded-lg mt-2">
                                            <div class="text-[10px] font-weight-black text-orange-darken-4 uppercase mb-2">Alterações Detectadas</div>
                                            <div v-for="(change, key) in getDiffs(log.payload, log.old_value)" :key="key" class="d-flex align-center gap-2 mb-1">
                                                <span class="font-weight-black text-grey-darken-3" style="min-width: 80px;">{{ key }}:</span>
                                                <span class="text-decoration-line-through text-grey font-mono">{{ change.from || 'vazio' }}</span>
                                                <v-icon size="14" color="orange-darken-2">mdi-arrow-right-bold</v-icon>
                                                <span class="font-weight-bold text-orange-darken-4 font-mono">{{ change.to || 'vazio' }}</span>
                                            </div>
                                        </div>
                                    </div>
                                </v-card>
                            </div>
                        </v-timeline-item>
                    </v-timeline>
                </div>
            </template>

            <template v-if="viewMode === 'legacy'">
                <div class="section-title px-4 py-4 d-flex align-center justify-space-between bg-amber-lighten-5 border-b border-amber-lighten-3 text-amber-darken-4">
                  <div class="d-flex align-center gap-3">
                      <div class="bg-amber-darken-3 pa-2 rounded-lg d-flex align-center justify-center text-white"><v-icon size="20">mdi-database-clock-outline</v-icon></div>
                      <div class="d-flex flex-column">
                        <div class="text-subtitle-1 font-weight-black text-uppercase ls-1">Consulta Histórica</div>
                        <div class="text-[11px] font-weight-medium">Tabela original: order_payments (Antigo Sistema de Sinais)</div>
                      </div>
                  </div>
                  <v-chip class="rounded chip-3d" size="small" variant="flat" color="amber-darken-3">
                    {{ legacyPayments.length }} registro(s)
                  </v-chip>
                </div>

                <div class="grid-header sticky-head" style="grid-template-columns: minmax(280px, 1.5fr) 140px 160px 140px 140px 120px;"
                     :class="themeStore.currentMode === 'light' ? 'grid-surface-light' : 'grid-surface-dark'">
                  <div class="cell header-text">Descrição Antiga</div>
                  <div class="cell center header-text">Data Pgto</div>
                  <div class="cell right header-text">Valor</div>
                  <div class="cell center header-text">Método</div>
                  <div class="cell center header-text">Comprovante</div>
                  <div class="cell center header-text">Ações</div>
                </div>

                <div v-if="legacyPayments.length === 0" class="d-flex flex-column justify-center align-center opacity-60 gap-2 py-12 bg-white">
                  <v-icon size="56" color="grey-lighten-1">mdi-database-off</v-icon>
                  <span class="text-subtitle-2 font-weight-bold text-grey-darken-2">Nenhum registro legado.</span>
                </div>
                <div v-else v-for="(pay, i) in legacyPayments" :key="i" class="grid-row hover-bg-row transition-colors" :class="zebraClass(i)" style="grid-template-columns: minmax(280px, 1.5fr) 140px 160px 140px 140px 120px;">
                    <div class="cell">
                        <div class="d-flex flex-column">
                            <span class="font-weight-black text-[13px] text-grey-darken-3">{{ pay.payment_type || 'Pagamento' }}</span>
                            <span class="text-[11px] opacity-70 mt-1">{{ pay.notes || 'Sem observação' }}</span>
                        </div>
                    </div>
                    <div class="cell center">
                        <span class="font-mono text-[12px] font-weight-bold border bg-white px-2 py-1 rounded">{{ formatDateSimple(pay.payment_date || pay.created_at) }}</span>
                    </div>
                    <div class="cell right">
                        <span class="font-mono font-weight-black text-[14px] text-orange-darken-4">{{ formatCurrency(pay.amount) }}</span>
                    </div>
                    <div class="cell center">
                        <span class="text-[11px] font-weight-bold bg-grey-lighten-3 px-2 py-1 rounded border text-grey-darken-3">{{ pay.payment_method || 'Não inf.' }}</span>
                    </div>
                    <div class="cell center">
                        <v-btn v-if="pay.receipt_url" size="small" color="blue-grey-darken-2" variant="flat" class="btn-3d font-weight-bold px-3" :href="pay.receipt_url" target="_blank" prepend-icon="mdi-open-in-new">
                            Arquivo
                        </v-btn>
                        <span v-else class="text-[11px] text-grey font-italic">Sem anexo</span>
                    </div>
                    <div class="cell center">
                        <div class="actions-inline">
                            <v-tooltip text="Importar para o Novo Financeiro" location="top" content-class="bg-grey-darken-4 text-white font-weight-bold text-caption">
                                <template v-slot:activator="{ props }">
                                    <v-btn v-bind="props" icon size="small" class="action-btn btn-3d bg-indigo-darken-2" variant="flat" @click.stop="createFromLegacy(pay)">
                                        <v-icon size="16">mdi-bank-transfer-in</v-icon>
                                    </v-btn>
                                </template>
                            </v-tooltip>
                        </div>
                    </div>
                </div>
            </template>

          </div>
        </v-card>
      </div>
    </v-card>

    <input ref="fileInput" type="file" accept="image/*,.pdf" class="d-none" @change="handleReceiptSelected" />

    <v-dialog v-model="createModal.show" width="900" persistent scrim="black opacity-90">
        <v-card class="rounded-xl overflow-hidden d-flex flex-row shadow-xl" height="580">
        <div class="modal-sidebar pa-8 d-flex flex-column text-white bg-indigo-darken-4" style="width: 320px;">
          <div class="d-flex align-center gap-3 mb-8">
            <div class="bg-white-20 pa-3 rounded-circle border border-white-10"><v-icon size="28" color="white">{{ createModal.isEdit ? 'mdi-pencil-outline' : 'mdi-cash-plus' }}</v-icon></div>
            <div>
              <h3 class="text-h6 font-weight-black leading-tight">{{ createModal.isEdit ? 'Editar' : 'Criar' }}</h3>
              <div class="text-caption opacity-70 text-uppercase ls-1">Recebimento</div>
            </div>
          </div>
          <div class="bg-black-20 pa-5 rounded-lg border border-white-05">
            <div class="text-caption font-weight-black opacity-70 mb-2 text-uppercase">Valor deste recebimento</div>
            <div class="text-h4 font-weight-black text-green-accent-2 font-mono text-truncate">{{ formatCurrency(createModal.form.value) }}</div>
          </div>
          <v-spacer></v-spacer>
          <div class="bg-blue-grey-darken-4 pa-4 rounded-lg border border-white-10">
              <v-icon size="20" class="mb-2 text-blue-lighten-2">mdi-information-outline</v-icon>
              <div class="text-[11px] font-weight-medium opacity-90 line-height-1.4">
                 Ao salvar, este valor passa a aparecer no financeiro. Se for menor que o total em aberto, o restante continua separado embaixo para lançar depois.
              </div>
          </div>
        </div>

        <div class="flex-grow-1 d-flex flex-column bg-white h-100 relative">
          <div class="pa-5 border-b d-flex justify-space-between align-center bg-grey-lighten-5">
            <span class="text-subtitle-1 font-weight-black text-grey-darken-3 text-uppercase ls-1">Dados do recebimento</span>
            <v-btn icon="mdi-close" variant="text" color="grey-darken-1" @click="createModal.show = false"></v-btn>
          </div>
          <div class="pa-8 overflow-y-auto custom-scroll flex-grow-1">
            <v-form @submit.prevent="saveReceivable" id="receivableForm">
              <v-row class="row-gap-md">
                <v-col cols="12">
                  <label class="input-label">Descrição da Recebimento / Referência</label>
                  <v-text-field v-model="createModal.form.description" variant="outlined" density="comfortable" hide-details class="ui-field bg-white font-weight-bold" color="indigo" />
                </v-col>
                <v-col cols="12">
                  <label class="input-label">Plano de Contas</label>
                  <v-select v-model="createModal.form.chart_of_accounts_id" :items="auxData.chartOfAccounts" item-title="name" item-value="id" variant="outlined" density="comfortable" hide-details class="ui-field bg-white font-weight-bold text-indigo-darken-4" color="indigo" />
                </v-col>

                <v-col cols="12"><v-divider class="border-dashed my-1"></v-divider></v-col>

                <v-col cols="12" md="4">
                  <label class="input-label">Valor (R$)</label>
                  <v-text-field v-model.number="createModal.form.value" type="number" step="0.01" prefix="R$" variant="outlined" density="comfortable" hide-details class="ui-field bg-white font-weight-black text-success-darken-2" color="success" />
                </v-col>
                <v-col cols="12" md="4">
                  <label class="input-label">Data de Vencimento</label>
                  <v-text-field v-model="createModal.form.due_date" type="date" variant="outlined" density="comfortable" hide-details class="ui-field bg-white font-mono font-weight-bold" color="indigo" />
                </v-col>
                <v-col cols="12" md="4">
                  <label class="input-label">Data Competência</label>
                  <v-text-field v-model="createModal.form.competence_date" type="date" variant="outlined" density="comfortable" hide-details class="ui-field bg-white font-mono" color="indigo" />
                </v-col>

                <v-col cols="12"><v-divider class="border-dashed my-1"></v-divider></v-col>

                <v-col cols="12" md="6">
                  <label class="input-label">Forma de recebimento prevista</label>
                  <v-select v-model="createModal.form.payment_method_id" :items="auxData.paymentMethods" item-title="name" item-value="id" variant="outlined" density="comfortable" hide-details class="ui-field bg-white" clearable placeholder="Não definida" />
                </v-col>
                <v-col cols="12" md="6">
                  <label class="input-label">Banco / destino previsto</label>
                  <v-select v-model="createModal.form.bank_account_id" :items="auxData.bankAccounts" item-title="name" item-value="id" variant="outlined" density="comfortable" hide-details class="ui-field bg-grey-lighten-4" color="indigo" disabled hint="Definido automaticamente ou na baixa" persistent-hint />
                </v-col>

                <v-col cols="12" class="mt-2">
                  <label class="input-label">Observações Internas</label>
                  <v-textarea v-model="createModal.form.notes" variant="outlined" density="comfortable" hide-details rows="2" class="ui-field bg-white" placeholder="Anotações apenas para controle..." />
                </v-col>
              </v-row>
            </v-form>
          </div>
          <div class="pa-5 border-t bg-grey-lighten-5 d-flex justify-end shadow-up z-10" style="gap: 12px;">
            <v-btn variant="outlined" class="btn-3d px-6 font-weight-bold" height="46" color="grey-darken-3" @click="createModal.show = false">Cancelar</v-btn>
            <v-btn color="success" variant="flat" class="btn-3d px-8 font-weight-black text-body-1" height="46" type="submit" form="receivableForm" :loading="createModal.loading"><v-icon start>mdi-check</v-icon> Salvar Recebimento</v-btn>
          </div>
        </div>
      </v-card>
    </v-dialog>

    <v-dialog v-model="boletoConfigModal.show" width="900" persistent scrim="black opacity-90" transition="dialog-bottom-transition">
        <v-card class="rounded-0 overflow-hidden bg-white d-flex flex-row" height="600">
            <div class="bg-indigo-darken-4 text-white pa-6 d-flex flex-column flex-shrink-0" style="width: 320px;">
                <div class="d-flex align-center gap-3 mb-6">
                    <div class="bg-white-10 pa-3 rounded-circle"><v-icon>mdi-barcode-scan</v-icon></div>
                    <div>
                        <div class="text-caption font-weight-bold opacity-60">CORA BANK</div>
                        <div class="text-h6 font-weight-black leading-tight">Configurar Boleto</div>
                    </div>
                </div>

                <div class="mb-4">
                    <div class="text-caption font-weight-bold text-white mb-1">Empresa Emissora</div>
                    <v-select
                        v-model="boletoConfigModal.companyId"
                        :items="allowedCompanies"
                        item-title="name"
                        item-value="id"
                        variant="outlined"
                        density="compact"
                        bg-color="rgba(255,255,255,0.1)"
                        base-color="white"
                        color="white"
                        hide-details
                        :readonly="!isAdminOrFinance"
                        :disabled="!isAdminOrFinance"
                    ></v-select>
                </div>

                <div class="bg-black-20 rounded-lg pa-5 mb-6 border border-white-05">
                    <div class="text-caption font-weight-bold opacity-70 text-uppercase mb-1">Recebimento Selecionada</div>
                    <div class="text-body-2 font-weight-bold leading-tight mb-2 text-truncate">{{ boletoConfigModal.description }}</div>

                    <v-divider class="mb-4 opacity-20"></v-divider>

                    <div class="text-caption font-weight-bold opacity-70 text-uppercase mb-1">Valor Original</div>
                    <div class="text-h4 font-weight-black text-green-accent-2 text-no-wrap overflow-hidden text-truncate">
                       {{ formatCurrency(boletoConfigModal.value) }}
                    </div>
                </div>

                <div class="mt-auto">
                    <v-btn block color="white" variant="outlined" class="mb-2 font-weight-bold btn-3d" @click="boletoConfigModal.show = false">Cancelar</v-btn>
                    <v-btn
                        block
                        color="green-accent-3"
                        variant="flat"
                        class="text-black font-weight-black btn-3d"
                        :loading="boletoConfigModal.loading"
                        @click="executeBoletoGeneration"
                    >
                        Emitir Agora
                    </v-btn>
                </div>
            </div>

            <div class="flex-grow-1 bg-white d-flex flex-column overflow-hidden">
                <div class="px-8 py-6 border-b bg-grey-lighten-5">
                    <h4 class="text-h6 font-weight-black text-indigo-darken-4">Regras de Cobrança</h4>
                    <div class="text-caption font-weight-medium text-grey-darken-1">Defina multas, juros e descontos aplicáveis.</div>
                </div>

                <div class="flex-grow-1 overflow-y-auto pa-8">
                    <v-row dense class="row-gap-md">
                        <v-col cols="12">
                            <label class="input-label text-indigo-darken-3">Data de Vencimento do Boleto</label>
                            <v-text-field
                                v-model="boletoConfigModal.dueDate"
                                type="date"
                                variant="outlined"
                                density="comfortable"
                                color="indigo"
                                bg-color="white"
                                class="ui-field font-mono font-weight-bold"
                            ></v-text-field>
                        </v-col>

                        <v-col cols="12"><v-divider class="my-2 border-dashed"></v-divider></v-col>

                        <v-col cols="6">
                            <label class="input-label">Multa (%) Após Vencimento</label>
                            <v-text-field
                                v-model.number="boletoConfigModal.finePercent"
                                type="number"
                                suffix="%"
                                variant="outlined"
                                density="comfortable"
                                color="indigo"
                                class="ui-field bg-white"
                            ></v-text-field>
                        </v-col>
                        <v-col cols="6">
                            <label class="input-label">Juros (% a.m.)</label>
                            <v-text-field
                                v-model.number="boletoConfigModal.interestPercent"
                                type="number"
                                suffix="%"
                                variant="outlined"
                                density="comfortable"
                                color="indigo"
                                class="ui-field bg-white"
                            ></v-text-field>
                        </v-col>

                        <v-col cols="12" class="mt-4">
                            <label class="input-label text-success">Desconto Antecipado (R$)</label>
                            <v-text-field
                                v-model.number="boletoConfigModal.discountValue"
                                type="number"
                                prefix="R$"
                                variant="outlined"
                                density="comfortable"
                                color="success"
                                class="ui-field bg-white font-weight-bold"
                                placeholder="0,00"
                            ></v-text-field>
                        </v-col>
                    </v-row>
                </div>
            </div>
        </v-card>
    </v-dialog>

    <v-dialog v-model="linkModal.show" width="1200" max-width="98vw" persistent scrim="black opacity-95" transition="dialog-bottom-transition">
      <v-card class="rounded-0 overflow-hidden bg-white d-flex flex-row" height="85vh" style="max-height: 900px;">

         <div class="bg-teal-darken-4 text-white pa-6 d-flex flex-column flex-shrink-0 relative z-20 shadow-xl" style="width: 360px;">
             <div class="d-flex align-center gap-3 mb-8">
                 <div class="bg-white-10 pa-3 rounded-circle border border-white-10"><v-icon>mdi-qrcode-scan</v-icon></div>
                 <div>
                    <div class="text-caption font-weight-bold opacity-60 ls-1">FINANCEIRO DIGITAL</div>
                    <div class="text-h6 font-weight-black leading-tight">Pagamento Pix</div>
                 </div>
             </div>

             <div class="bg-black-20 rounded-lg pa-5 mb-4 border border-white-05">
                 <div class="text-caption font-weight-bold opacity-70 text-uppercase mb-1">Referência</div>
                 <div class="text-body-2 font-weight-bold leading-tight mb-4 text-truncate">{{ linkModal.description }}</div>

                 <v-divider class="mb-4 opacity-20"></v-divider>

                 <div class="text-caption font-weight-bold opacity-70 text-uppercase mb-1">Valor Total</div>
                 <div class="text-h3 font-weight-black text-green-accent-2 font-mono text-no-wrap overflow-hidden text-truncate">
                    {{ formatCurrency(linkModal.value) }}
                 </div>
             </div>

             <div v-if="linkModal.status === 'PAID'" class="bg-green-darken-4 pa-4 rounded-lg d-flex align-center gap-3 mb-4 animate-pop border border-green-lighten-4 shadow-lg">
                 <v-icon size="32" color="white">mdi-check-decagram</v-icon>
                 <div class="text-caption font-weight-bold lh-1 text-white">
                     PAGAMENTO CONFIRMADO<br>
                     <span class="opacity-80 font-weight-regular text-[10px]">Conciliação automática realizada.</span>
                 </div>
             </div>

             <div v-else-if="linkModal.step === 'view'" class="d-flex align-center gap-3 opacity-70 mb-6 bg-white-05 pa-4 rounded-lg border border-white-10">
                 <v-progress-circular indeterminate size="20" width="2" color="white"></v-progress-circular>
                 <span class="text-caption font-weight-bold text-uppercase">Aguardando banco...</span>
             </div>

             <div class="mt-auto d-flex flex-column gap-3">
                 <template v-if="linkModal.step === 'view'">
                     <v-btn block size="large" color="green-darken-1" variant="flat" class="font-weight-black btn-3d text-[13px]" prepend-icon="mdi-whatsapp" @click="sendWhatsapp">
                        Enviar no WhatsApp
                     </v-btn>
                     <v-btn block size="large" color="white" variant="outlined" class="font-weight-bold btn-3d text-[13px]" prepend-icon="mdi-email-outline" @click="sendEmail">
                        Enviar por E-mail
                     </v-btn>
                 </template>
                 <v-btn block size="large" color="grey-lighten-2" variant="text" class="font-weight-bold mt-2" @click="linkModal.show = false">
                    Fechar Janela
                 </v-btn>
             </div>
         </div>

         <div v-if="linkModal.step === 'config'" class="flex-grow-1 relative d-flex flex-column bg-white overflow-hidden">
             <div class="px-6 py-4 bg-grey-lighten-5 border-b d-flex align-center justify-space-between flex-shrink-0">
                 <span class="text-subtitle-2 font-weight-black text-grey-darken-3 uppercase d-flex align-center gap-2">
                    <v-icon size="20" color="teal-darken-3">mdi-cog</v-icon> Configuração do Emissor
                 </span>
                 <v-btn icon="mdi-close" variant="text" color="grey-darken-2" @click="linkModal.show = false"></v-btn>
             </div>

             <div class="flex-grow-1 d-flex flex-column align-center justify-center pa-8 overflow-hidden relative">
                 <div style="max-width: 450px; width: 100%;">
                     <h2 class="text-h4 font-weight-black mb-3 text-center text-teal-darken-4">Escolher Emissor</h2>
                     <p class="text-body-2 font-weight-medium text-grey-darken-1 text-center mb-8">Selecione a empresa que receberá este pagamento Pix. O lançamento financeiro será atribuído a ela automaticamente.</p>

                     <label class="input-label text-teal-darken-3">Empresa / Conta Destino</label>
                     <v-select
                        v-model="linkModal.companyId"
                        :items="allowedCompanies"
                        item-title="name"
                        item-value="id"
                        variant="outlined"
                        class="mb-6 ui-field font-weight-bold bg-white"
                        color="teal"
                        :readonly="!isAdminOrFinance"
                        :disabled="!isAdminOrFinance"
                     ></v-select>

                     <v-btn
                        block
                        color="teal-darken-3"
                        size="x-large"
                        class="font-weight-black btn-3d text-body-1"
                        variant="flat"
                        height="56"
                        :loading="linkModal.loading"
                        @click="executePixGeneration"
                     >
                        Gerar QR Code Agora
                        <v-icon end>mdi-arrow-right</v-icon>
                     </v-btn>
                 </div>
             </div>
         </div>

         <div v-else class="flex-grow-1 relative d-flex flex-column bg-grey-lighten-4 overflow-hidden">
             <div class="px-6 py-4 bg-white border-b d-flex align-center justify-space-between flex-shrink-0 shadow-sm z-10">
                 <span class="text-subtitle-2 font-weight-black text-teal-darken-3 uppercase d-flex align-center gap-2">
                    <v-icon size="20">mdi-eye-outline</v-icon> Visualização do QR Code
                 </span>
                 <v-btn icon="mdi-close" variant="text" color="grey-darken-2" @click="linkModal.show = false"></v-btn>
             </div>

             <div class="flex-grow-1 d-flex align-center justify-center pa-8 overflow-hidden relative bg-dots">
                 <v-card class="elevation-10 rounded-xl border-thin bg-white d-flex align-center justify-center" style="max-height: 90%; max-width: 90%; width: 500px; height: 500px;">
                     <div v-if="linkModal.loading" class="pa-12 d-flex flex-column align-center">
                         <v-progress-circular indeterminate color="teal" size="80" width="6"></v-progress-circular>
                         <span class="mt-8 font-weight-black text-teal-darken-3 text-h6 text-uppercase ls-1">Gerando cobrança...</span>
                     </div>
                     <img
                        v-else
                        :src="linkModal.qrCodeUrl"
                        style="max-width: 85%; max-height: 85%; object-fit: contain; display: block;"
                     />
                 </v-card>
             </div>

             <div class="pa-6 bg-white border-t d-flex flex-column gap-3 flex-shrink-0 z-20 shadow-up">
                 <div class="text-[12px] font-weight-black text-uppercase text-teal-darken-4 pl-1">Código Pix Copia e Cola</div>
                 <div class="d-flex align-center gap-3">
                     <v-text-field
                        :model-value="linkModal.copyPaste"
                        readonly
                        variant="outlined"
                        density="comfortable"
                        hide-details
                        class="font-mono text-body-2 font-weight-bold ui-field bg-grey-lighten-5"
                        color="teal"
                     >
                        <template v-slot:prepend-inner>
                            <v-icon size="20" color="teal-darken-2">mdi-content-copy</v-icon>
                        </template>
                     </v-text-field>
                     <v-btn color="teal-darken-3" height="48" class="px-8 font-weight-black btn-3d text-body-1" @click="copyLink">
                        COPIAR
                     </v-btn>
                 </div>
             </div>
         </div>
      </v-card>
    </v-dialog>

    <v-dialog v-model="paymentConfirmModal.show" width="500" persistent scrim="black opacity-80">
      <v-card class="rounded-xl overflow-hidden d-flex flex-column border-thin shadow-lg">
        <div class="pa-5 border-b d-flex justify-space-between align-center bg-green-lighten-5">
            <span class="text-h6 font-weight-black text-green-darken-4 d-flex align-center gap-2">
                <v-icon size="28">mdi-cash-check</v-icon> Confirmar Recebimento
            </span>
            <v-btn icon="mdi-close" variant="text" color="green-darken-4" @click="paymentConfirmModal.show = false"></v-btn>
        </div>
        <div class="pa-8 bg-white">
            <div class="text-body-2 font-weight-medium text-grey-darken-3 mb-6 bg-grey-lighten-5 pa-4 rounded-lg border-thin">
                Informe quanto entrou, a data e a forma de recebimento. Se receber só uma parte, o restante continua como <b>Total em aberto</b> para lançar depois.
            </div>

            <div class="mb-6 rounded-lg pa-4 border-thin bg-green-lighten-5">
                <div class="text-caption font-weight-black text-green-darken-4 text-uppercase mb-1">Valor original</div>
                <div class="text-h6 font-weight-black text-green-darken-4">{{ formatCurrency(paymentConfirmModal.maxAmount) }}</div>
            </div>

            <label class="input-label text-green-darken-4">Valor recebido agora*</label>
            <v-text-field
                v-model.number="paymentConfirmModal.amount"
                type="number"
                step="0.01"
                prefix="R$"
                variant="outlined"
                density="comfortable"
                hide-details
                color="success"
                class="ui-field mb-4 font-mono font-weight-black"
            ></v-text-field>

            <div v-if="paymentConfirmModal.amount > 0 && paymentConfirmModal.amount < paymentConfirmModal.maxAmount" class="mb-6 rounded-lg pa-3 bg-orange-lighten-5 border border-orange-lighten-3 text-orange-darken-4 text-caption font-weight-bold">
                Recebimento parcial: {{ formatCurrency(paymentConfirmModal.maxAmount - paymentConfirmModal.amount) }} continuará em Total em aberto.
            </div>

            <label class="input-label text-green-darken-4">Forma de Recebimento (Caixa)*</label>
            <v-select
                v-model="paymentConfirmModal.methodId"
                :items="auxData.paymentMethods"
                item-title="name"
                item-value="id"
                variant="outlined"
                density="comfortable"
                hide-details
                class="ui-field mb-6 font-weight-bold"
                color="success"
                placeholder="Selecione como foi pago"
            ></v-select>

            <label class="input-label text-green-darken-4">Data do Recebimento Oficial*</label>
            <v-text-field
                v-model="paymentConfirmModal.paymentDate"
                type="date"
                variant="outlined"
                density="comfortable"
                hide-details
                color="success"
                class="ui-field mb-4 font-mono font-weight-bold"
            ></v-text-field>

            <div class="d-flex gap-3">
                <v-btn variant="tonal" color="primary" class="flex-grow-1 font-weight-black btn-3d text-[12px]" height="44"
                       @click="paymentConfirmModal.paymentDate = String(new Date().toISOString()).split('T')[0]">
                    Usar Data de Hoje
                </v-btn>
                <v-btn variant="tonal" color="warning" class="flex-grow-1 font-weight-black btn-3d text-[12px]" height="44"
                       @click="paymentConfirmModal.paymentDate = paymentConfirmModal.rec?.due_date ? String(paymentConfirmModal.rec.due_date).split('T')[0] : ''">
                    Usar Data do Vencimento
                </v-btn>
            </div>
        </div>
        <div class="pa-5 border-t bg-grey-lighten-5 d-flex justify-end shadow-up z-10" style="gap: 12px;">
            <v-btn variant="outlined" class="btn-3d px-6 font-weight-bold" height="46" color="grey-darken-3" @click="paymentConfirmModal.show = false">Cancelar</v-btn>
            <v-btn color="success" variant="flat" class="btn-3d px-8 font-weight-black text-body-1" height="46"
                   :loading="paymentConfirmModal.loading" @click="confirmMarkPaid">
                Confirmar recebimento
            </v-btn>
        </div>
      </v-card>
    </v-dialog>

  </v-dialog>
</template>

<script setup lang="ts">
import { ref, computed, reactive, watch, onMounted, onUnmounted } from 'vue';
import { supabase } from '@/api/supabase';
import { format, parseISO } from 'date-fns';
import { ptBR } from 'date-fns/locale';
import { useAppStore } from '@/stores/app';
import { useThemeStore } from '@/stores/theme';
import { useUserStore } from '@/stores/user';
import { useAuditLogger } from '@/composables/useAuditLogger';
import { useMjCashSessionStore } from '@/stores/mjCashSession';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import QRCode from 'qrcode';
import { coraApi, type CoraBoletoPayload } from '@/api/coraProxy';

const props = defineProps<{
  modelValue: boolean;
  order: any | null;
}>();

const emit = defineEmits(['update:modelValue']);

const appStore = useAppStore();
const themeStore = useThemeStore();
const userStore = useUserStore();
const cashStore = useMjCashSessionStore();
const { logSecureAction, notifyFinancialAdmins } = useAuditLogger();

// --- CORA KEYS MAP ---
const coraKeys: Record<string, string> = {
    '20631721000107': 'int-3VpXneDbEmHHHYFNN8hoIh', // Mr Jacky
    '53756096000189': 'int-23ze6BcCmlV6oqO2TPP01s', // Santos & Lopes
};

const loadingReceivables = ref(false);
const viewMode = ref('current');

const receivables = ref<any[]>([]);
const normalizingReceivables = ref(false);
const legacyPayments = ref<any[]>([]);

const auditLogs = ref<any[]>([]);
const loadingLogs = ref(false);

const realtimeChannel = ref<any>(null);
const realtimeStatus = ref('DISCONNECTED');

const actionLoadingId = ref<string | null>(null);
const actionLoadingKey = ref<string | null>(null);
const printLoadingId = ref<string | null>(null);

const fileInput = ref<HTMLInputElement | null>(null);
const pendingReceiptFor = ref<any | null>(null);

// Aux
const auxData = reactive({
  bankAccounts: [] as any[],
  paymentMethods: [] as any[],
  companies: [] as any[],
  chartOfAccounts: [] as any[]
});

const orderNumberLabel = computed(() => props.order?.order_number ?? props.order?.orderNumber ?? '-');

const isAdminOrFinance = computed(() => {
    const role = userStore.profile?.role?.toLowerCase() || '';
    return userStore.isAdmin || userStore.isGlobalAdmin || role === 'financeiro' || role === 'admin' || role === 'super_admin';
});

const allowedCompanies = computed(() => {
    if (isAdminOrFinance.value) {
        return auxData.companies;
    }
    return auxData.companies.filter(c => c.cnpj && c.cnpj.replace(/\D/g, '') === '20631721000107');
});

const defaultCompanyId = computed(() => {
    const mrJacky = auxData.companies.find(c => c.cnpj && c.cnpj.replace(/\D/g, '') === '20631721000107');
    if (!isAdminOrFinance.value && mrJacky) return mrJacky.id;
    if (props.order?.company_id) return props.order.company_id;
    if (mrJacky) return mrJacky.id;
    if (allowedCompanies.value.length > 0) return allowedCompanies.value[0].id;
    return null;
});

const isUuid = (v: any) => typeof v === 'string' && /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(v);
const resolvedOrderId = computed(() => {
  const o: any = props.order || {};
  if (o.id && isUuid(o.id)) return o.id;
  if (o.uuid) return o.uuid;
  return o.id || o.order_id || null;
});

const toDateKey = (d: any): string => (d ? String(d).substring(0, 10) : '');
const formatCurrency = (val: any) => new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(Number(val) || 0);
const formatCurrencyValue = (val: any) => new Intl.NumberFormat('pt-BR', { minimumFractionDigits: 2 }).format(Number(val) || 0);
const formatDateSimple = (date: any) => {
  const s = toDateKey(date);
  if (!s) return '-';
  try { return format(parseISO(s), 'dd/MM/yy'); } catch { return s; }
};
const formatDateTime = (iso: string) => iso ? format(parseISO(iso), 'dd/MM/yyyy HH:mm') : '-';

const zebraClass = (index: number) => themeStore.currentMode !== 'light' ? (index % 2 === 0 ? 'zebra-dark-a' : 'zebra-dark-b') : (index % 2 === 0 ? 'zebra-light-a' : 'zebra-light-b');
const getPaymentMethodName = (id: any) => auxData.paymentMethods.find(p => p.id === id)?.name || '-';
const isPaidStatus = (status: any) => String(status || '').toLowerCase() === 'pago';
const isOpenStatus = (status: any) => !isPaidStatus(status);
const statusLabel = (rec: any) => (isPaidStatus(rec.status) ? 'Pago' : 'Em aberto');
const statusChipClass = (rec: any) => (isPaidStatus(rec.status) ? 'chip-success' : 'chip-warn');

const orderTotal = computed(() => Number(props.order?.total_value || 0));
const paidReceivables = computed(() => (receivables.value || []).filter(r => isPaidStatus(r.status)));
const openReceivables = computed(() => (receivables.value || []).filter(r => isOpenStatus(r.status)));
const totalPaid = computed(() => paidReceivables.value.reduce((s, r) => s + (Number(r.value) || 0), 0));
const totalOpen = computed(() => Math.max(0, orderTotal.value - totalPaid.value));
const totalLaunched = computed(() => totalPaid.value + openReceivables.value.reduce((s, r) => s + (Number(r.value) || 0), 0));
const remainingBalance = computed(() => totalOpen.value);
const totalPlanned = computed(() => plannedRows.value.reduce((s, r) => s + (Number(r.value) || 0), 0));
const isFullyLaunched = computed(() => remainingBalance.value <= 0.05);

const consolidatedOpenReceivable = computed(() => {
  return [...openReceivables.value].sort((a, b) => {
    const da = toDateKey(a.due_date);
    const db = toDateKey(b.due_date);
    if (da !== db) return da.localeCompare(db);
    return String(a.created_at || '').localeCompare(String(b.created_at || ''));
  })[0] || null;
});

const realReceivables = computed(() => {
  // No topo ficam os recebimentos que já aconteceram. O valor ainda em aberto fica embaixo,
  // para o usuário não confundir uma sobra parcial com uma parcela já recebida.
  return paidReceivables.value.map((r) => {
      const companyName = auxData.companies.find(c => c.id === r.company_id)?.name;
      return {
        ...r,
        value: Number(r.value) || 0,
        uniqueKey: 'real-' + r.id,
        company_name_cache: companyName
      };
    }).sort((a, b) => {
      const da = toDateKey(a.due_date);
      const db = toDateKey(b.due_date);
      if (da !== db) return da.localeCompare(db);
      return String(a.created_at || '').localeCompare(String(b.created_at || ''));
    });
});

const plannedRows = computed(() => {
  const remaining = Math.max(0, remainingBalance.value);
  if (remaining <= 0.05) return [];

  const details = props.order?.details || {};
  const schedule = details?.installments_schedule || details?.installments || [];
  const nextScheduleItem = Array.isArray(schedule)
    ? schedule.find((inst: any) => {
        const value = Number(inst?.value ?? inst?.valor ?? inst?.amount ?? 0);
        return value > 0;
      })
    : null;

  const openRow = consolidatedOpenReceivable.value;

  return [{
    uniqueKey: `open-balance-${orderNumberLabel.value}`,
    sourceReceivableId: openRow?.id || null,
    description: `Total em aberto - Pedido #${orderNumberLabel.value}`,
    value: remaining,
    due_date: openRow?.due_date || nextScheduleItem?.due_date || nextScheduleItem?.vencimento || new Date().toISOString().substring(0, 10),
    payment_method_id: openRow?.payment_method_id || null,
    chart_of_accounts_id: openRow?.chart_of_accounts_id || null,
    bank_account_id: openRow?.bank_account_id || null,
    notes: openRow?.notes || '',
    status: 'open_balance'
  }];
});

const getAttachments = (rec: any) => {
  let atts: any[] = [];
  if (rec.billing_items_snapshot) {
    try {
      const arr = typeof rec.billing_items_snapshot === 'string' ? JSON.parse(rec.billing_items_snapshot) : rec.billing_items_snapshot;
      if (Array.isArray(arr)) {
        arr.forEach((x: any) => {
            if (x.type === 'receipt' || x.url) atts.push(x);
        });
      }
    } catch {}
  }
  const desc = String(rec.description || '').toLowerCase();
  const isSignalCandidate = desc.includes('sinal') || desc.includes('entrada') || (String(rec.status) === 'pago' && atts.length === 0);

  if (isSignalCandidate && props.order?.details) {
      const details = props.order.details;
      if (Array.isArray(details.downPayments)) {
          details.downPayments.forEach((dp: any, i: number) => {
              if (dp.proof_url && Math.abs(Number(dp.value) - Number(rec.value)) < 0.1) {
                  if (!atts.some(a => a.url === dp.proof_url)) atts.push({ type: 'receipt', url: dp.proof_url, filename: `Comp. Sinal ${i+1}` });
              }
          });
      }
      const url = props.order.down_payment_proof_url || details.entry_proof_url || details.payment_proof || details.comprovante_url;
      if (url) {
           const entryVal = Number(details.entry_value || 0);
           if (Math.abs(entryVal - Number(rec.value)) < 0.1 || desc.includes('sinal')) {
               if (!atts.some(a => a.url === url)) atts.push({ type: 'receipt', url: url, filename: 'Comprovante Sinal' });
           }
      }
  }

  if (legacyPayments.value.length > 0) {
      legacyPayments.value.forEach((pay: any) => {
          if (pay.receipt_url && Math.abs(Number(pay.amount) - Number(rec.value)) < 0.1) {
               if (!atts.some(a => a.url === pay.receipt_url)) atts.push({ type: 'receipt', url: pay.receipt_url, filename: `Comp. Legado` });
          }
      });
  }

  return atts;
};

const openAttachment = (url: string) => { if (url) window.open(url, '_blank'); };

const formatLogAction = (type: string) => {
    const map: Record<string, string> = {
        'PAYMENT_RECEIVED': 'Pagamento Recebido', 'PAYMENT_REVERTED': 'Estorno Realizado',
        'RECEIVABLE_CREATED': 'Recebimento Criada', 'RECEIVABLE_EDITED': 'Recebimento Editado',
        'RECEIVABLE_DELETED': 'Recebimento Excluída', 'RECEIVABLE_ATTACHMENT': 'Anexo Inserido'
    };
    return map[type] || type;
};

const getLogColor = (type: string) => {
    if (type.includes('RECEIVED')) return 'success';
    if (type.includes('REVERTED')) return 'error';
    if (type.includes('DELETED')) return 'red';
    if (type.includes('EDITED')) return 'warning';
    return 'grey';
};

const getDiffs = (current: any, old: any) => {
    if (!old) return {};
    const diffs: any = {};
    for (const key in current) {
        if (current[key] !== old[key] && key !== 'updated_at' && key !== 'billing_items_snapshot') {
            diffs[key] = { from: old[key], to: current[key] };
        }
    }
    return diffs;
};

const fetchAuditLogs = async () => {
    const orderId = resolvedOrderId.value;
    if (!orderId) return;
    loadingLogs.value = true;
    try {
        const { data, error } = await supabase.from('finance_audit_logs').select('*, profiles(full_name)').eq('entity_id', orderId).order('created_at', { ascending: false });
        if(error) throw error;
        auditLogs.value = data || [];
    } catch (e) {} finally { loadingLogs.value = false; }
};

const fetchAuxiliaryData = async () => {
  const { data: acc } = await supabase.from('finance_accounts').select('id, name');
  if(acc) auxData.bankAccounts = acc;
  const { data: met } = await supabase.from('finance_payment_methods').select('id, name');
  if(met) auxData.paymentMethods = met;
  const { data: comps } = await supabase.from('companies').select('*');
  if(comps) auxData.companies = comps;
  const { data: cats } = await supabase.from('finance_chart_of_accounts').select('id, name');
  if(cats) auxData.chartOfAccounts = cats;
};

const normalizeOpenReceivablesIfNeeded = async (rows: any[]) => {
  const orderId = resolvedOrderId.value;
  if (!orderId || normalizingReceivables.value) return false;

  const total = Number(orderTotal.value) || 0;
  if (total <= 0) return false;

  const paidRows = (rows || []).filter(r => isPaidStatus(r.status));
  const openRows = (rows || []).filter(r => isOpenStatus(r.status));
  const paid = paidRows.reduce((sum, r) => sum + (Number(r.value) || 0), 0);
  const targetOpen = Math.max(0, total - paid);

  if (openRows.length === 0) return false;

  normalizingReceivables.value = true;
  try {
    if (targetOpen <= 0.05) {
      const idsToDelete = openRows.map(r => r.id).filter(Boolean);
      if (idsToDelete.length > 0) {
        const { error } = await supabase.from('finance_receivables').delete().in('id', idsToDelete);
        if (error) throw error;
      }
      return true;
    }

    const sortedOpen = [...openRows].sort((a, b) => {
      const da = toDateKey(a.due_date);
      const db = toDateKey(b.due_date);
      if (da !== db) return da.localeCompare(db);
      return String(a.created_at || '').localeCompare(String(b.created_at || ''));
    });

    const primary = sortedOpen[0];
    const others = sortedOpen.slice(1);
    const needsUpdate = Math.abs((Number(primary.value) || 0) - targetOpen) > 0.05
      || String(primary.description || '').toLowerCase() !== `total em aberto - pedido #${orderNumberLabel.value}`.toLowerCase();

    if (needsUpdate) {
      const { error } = await supabase.from('finance_receivables').update({
        description: `Total em aberto - Pedido #${orderNumberLabel.value}`,
        value: Number(targetOpen.toFixed(2)),
        status: 'em_aberto',
        notes: `${primary.notes || ''} [Ajustado automaticamente pelo modal: sobras em aberto foram unificadas em uma única parcela.]`.trim()
      }).eq('id', primary.id);
      if (error) throw error;
    }

    const idsToDelete = others.map(r => r.id).filter(Boolean);
    if (idsToDelete.length > 0) {
      const { error } = await supabase.from('finance_receivables').delete().in('id', idsToDelete);
      if (error) throw error;
    }

    return needsUpdate || idsToDelete.length > 0;
  } finally {
    normalizingReceivables.value = false;
  }
};

const fetchReceivables = async () => {
  const orderId = resolvedOrderId.value;
  if (!orderId) return;
  loadingReceivables.value = true;
  try {
    const { data, error } = await supabase
        .from('finance_receivables')
        .select('*, chart_of_accounts:finance_chart_of_accounts(id, name)')
        .eq('order_id', orderId)
        .order('due_date', { ascending: true });
    if (error) throw error;

    const rows = data || [];
    const normalized = await normalizeOpenReceivablesIfNeeded(rows);

    if (normalized) {
      const { data: normalizedData, error: refetchError } = await supabase
        .from('finance_receivables')
        .select('*, chart_of_accounts:finance_chart_of_accounts(id, name)')
        .eq('order_id', orderId)
        .order('due_date', { ascending: true });
      if (refetchError) throw refetchError;
      receivables.value = normalizedData || [];
    } else {
      receivables.value = rows;
    }
  } catch (e: any) {
    appStore.showSnackbar('Erro ao carregar recebimentos: ' + (e.message || 'falha no banco'), 'error');
  } finally { loadingReceivables.value = false; }
};

const fetchLegacy = async () => {
  const orderId = resolvedOrderId.value;
  if(!orderId) return;
  try {
    const { data } = await supabase.from('order_payments').select('*').eq('order_id', orderId);
    legacyPayments.value = data || [];
  } catch(e) {}
};

const fetchAll = async () => {
  await Promise.all([fetchAuxiliaryData(), fetchReceivables(), fetchLegacy()]);
  setupRealtimeListener();
};

const setupRealtimeListener = () => {
  const orderId = resolvedOrderId.value;
  if (!orderId) return;
  if (realtimeChannel.value) supabase.removeChannel(realtimeChannel.value);
  realtimeStatus.value = 'CONNECTING';
  realtimeChannel.value = supabase.channel(`order-receivables-${orderId}`)
    .on('postgres_changes', { event: '*', schema: 'public', table: 'finance_receivables', filter: `order_id=eq.${orderId}` }, () => fetchReceivables())
    .subscribe((status: any) => { realtimeStatus.value = String(status); });
};

const createModal = reactive({
  show: false,
  loading: false,
  isEdit: false,
  editingId: null as string | null,
  form: { description: '', value: 0, due_date: '', competence_date: '', bank_account_id: null as any, payment_method_id: null as any, chart_of_accounts_id: null as any, notes: '' }
});

const paymentConfirmModal = reactive({
  show: false,
  loading: false,
  rec: null as any,
  paymentDate: '',
  methodId: null as any,
  amount: 0,
  maxAmount: 0
});

const linkModal = reactive({
  show: false, loading: false, step: 'config', value: 0, description: '', qrCodeUrl: '', copyPaste: '', invoiceId: '', status: 'PENDING', checkInterval: null as NodeJS.Timeout | null, associatedRecId: null as string | null, companyId: null as any
});

const boletoConfigModal = reactive({
    show: false, loading: false, targetInstallment: null as any, value: 0, description: '', dueDate: '', finePercent: 0, interestPercent: 0, discountValue: 0, companyId: null as any
});

const prepareBoleto = (rec: any) => {
    boletoConfigModal.targetInstallment = rec; boletoConfigModal.value = Number(rec.value); boletoConfigModal.description = rec.description;
    boletoConfigModal.dueDate = rec.due_date ? String(rec.due_date).split('T')[0] : format(new Date(), 'yyyy-MM-dd');
    boletoConfigModal.finePercent = 0; boletoConfigModal.interestPercent = 0; boletoConfigModal.discountValue = 0;
    boletoConfigModal.companyId = defaultCompanyId.value; boletoConfigModal.show = true;
};

const executeBoletoGeneration = async () => {
    const rec = boletoConfigModal.targetInstallment;
    if (!rec) return;

    if (!boletoConfigModal.companyId) { appStore.showSnackbar('Selecione uma empresa emissora.', 'error'); return; }

    const selectedCompany = auxData.companies.find(c => c.id === boletoConfigModal.companyId);
    let targetCoraId = null;
    const companyCnpj = selectedCompany?.cnpj ? selectedCompany.cnpj.replace(/\D/g, '') : '';

    if (companyCnpj && coraKeys[companyCnpj]) targetCoraId = coraKeys[companyCnpj];
    else targetCoraId = selectedCompany?.cora_client_id || selectedCompany?.client_id || selectedCompany?.id;

    let identity = props.order?.customer?.cpf_cnpj || props.order?.customer?.cnpj || props.order?.customer?.cpf;
    if (!identity && props.order?.customer_id) {
        const { data: client } = await supabase.from('customers_mj').select('*').eq('id', props.order.customer_id).maybeSingle();
        if (client) identity = client.cpf_cnpj || client.cnpj || client.cpf || client.documento;
    }

    if (!identity) { appStore.showSnackbar('Cliente sem CPF/CNPJ. Impossível emitir boleto.', 'error'); return; }
    identity = identity.replace(/\D/g, '');

    if (companyCnpj && identity === companyCnpj) { appStore.showSnackbar('Erro: Auto-cobrança não permitida (CNPJ Cliente igual ao Emissor).', 'error'); return; }

    boletoConfigModal.loading = true;
    const resolvedClientName = props.order?.customer_name || props.order?.customer?.nome || props.order?.customer?.name || props.order?.customer?.razao_social || 'Cliente';

    try {
        const coraBank = auxData.bankAccounts.find(b => b.name.toLowerCase().includes('cora'));
        const coraMethod = auxData.paymentMethods.find(m => m.name.toLowerCase().includes('boleto'));

        const payload: CoraBoletoPayload = {
            code: `PARC-${rec.id.substring(0,8)}-${Date.now().toString().substring(9)}`,
            customer: { name: resolvedClientName, email: props.order?.customer?.email || 'financeiro@mjprocess.com.br', document: { identity: identity, type: identity.length > 11 ? 'CNPJ' : 'CPF' } },
            services: [{ name: 'Venda de Produtos', description: rec.description, amount: Math.round(Number(rec.value) * 100) }],
            payment_terms: { due_date: boletoConfigModal.dueDate, fine: boletoConfigModal.finePercent > 0 ? { rate: boletoConfigModal.finePercent } : undefined, interest: boletoConfigModal.interestPercent > 0 ? { rate: boletoConfigModal.interestPercent } : undefined, discount: boletoConfigModal.discountValue > 0 ? { type: 'FIXED', value: boletoConfigModal.discountValue } : undefined },
            payment_forms: ['BANK_SLIP', 'PIX']
        };

        const result = await coraApi.generateBoleto(payload, targetCoraId);
        const boletoUrl = result.payment_options?.bank_slip?.url;

        if (boletoUrl) window.open(boletoUrl, '_blank');

        const currentSnap = rec.billing_items_snapshot ? (typeof rec.billing_items_snapshot === 'string' ? JSON.parse(rec.billing_items_snapshot) : rec.billing_items_snapshot) : [];
        const newAttachments = [ ...currentSnap, { type: 'boleto', url: boletoUrl, filename: 'Boleto Cora.pdf', created_at: new Date().toISOString() } ];

        const { error: updateError } = await supabase.from('finance_receivables').update({
            boleto_url: boletoUrl, boleto_barcode: result.payment_options?.bank_slip?.barcode, boleto_digitable: result.payment_options?.bank_slip?.digitable,
            payment_method_id: coraMethod?.id || rec.payment_method_id, bank_account_id: coraBank?.id || rec.bank_account_id, company_id: boletoConfigModal.companyId,
            billing_items_snapshot: newAttachments, notes: (rec.notes || '') + ` [Boleto Gerado: ${format(new Date(), 'dd/MM HH:mm')}]`
        }).eq('id', rec.id);

        if (updateError) throw updateError;

        appStore.showSnackbar(`Boleto emitido e aberto em nova aba!`, 'success');
        boletoConfigModal.show = false;
        setTimeout(() => fetchAll(), 500);

    } catch (e: any) { appStore.showSnackbar(`Erro ao emitir: ${e.message}`, 'error'); } finally { boletoConfigModal.loading = false; }
};

watch(() => createModal.form.payment_method_id, (newVal) => {
    if (!newVal || !auxData.paymentMethods.length) return;
    const methodObj = auxData.paymentMethods.find(m => m.id === newVal);
    const methodName = methodObj?.name?.toLowerCase() || '';
    const isPix = methodName.includes('pix');
    const targetBankKeyword = isPix ? 'cora' : 'sicredi';
    const targetBank = auxData.bankAccounts.find(b => b.name.toLowerCase().includes(targetBankKeyword));
    if (targetBank) createModal.form.bank_account_id = targetBank.id;
});

const openCreateModal = (prefill?: any) => {
  createModal.isEdit = false; createModal.editingId = null;
  const today = format(new Date(), 'yyyy-MM-dd');
  const defaultCategory = auxData.chartOfAccounts.find(c => String(c.name).toLowerCase().includes('venda de produto'));

  createModal.form.description = prefill?.description || `Recebimento - Pedido #${orderNumberLabel.value}`;
  createModal.form.value = Number(prefill?.value || 0);
  createModal.form.due_date = prefill?.due_date || today;
  createModal.form.competence_date = prefill?.competence_date || today;
  createModal.form.payment_method_id = prefill?.payment_method_id || null;
  createModal.form.bank_account_id = null;
  createModal.form.chart_of_accounts_id = prefill?.chart_of_accounts_id || (defaultCategory ? defaultCategory.id : null);
  createModal.form.notes = prefill?.notes || '';
  createModal.show = true;
};

const openEditModal = (rec: any) => {
  createModal.isEdit = true; createModal.editingId = rec.id;
  createModal.form.description = rec.description; createModal.form.value = Number(rec.value);
  createModal.form.due_date = rec.due_date ? String(rec.due_date).split('T')[0] : '';
  createModal.form.competence_date = rec.competence_date ? String(rec.competence_date).split('T')[0] : '';
  createModal.form.payment_method_id = rec.payment_method_id;
  createModal.form.bank_account_id = rec.bank_account_id;
  createModal.form.chart_of_accounts_id = rec.chart_of_accounts_id;
  createModal.form.notes = rec.notes;
  createModal.show = true;
};

const saveReceivable = async () => {
  const orderId = resolvedOrderId.value;
  if (!orderId) return;

  createModal.loading = true;
  const user = userStore.profile?.full_name || 'Usuário';

  try {
    const resolvedClientName = props.order?.customer_name || props.order?.customer?.nome || props.order?.customer?.name || props.order?.customer?.razao_social || props.order?.cliente || 'Cliente Não Identificado';
    const cleanId = (val: any) => (val && String(val).trim() !== '') ? val : null;

    let payload: any = {
      description: createModal.form.description,
      value: Number(createModal.form.value) || 0,
      due_date: createModal.form.due_date || null,
      competence_date: createModal.form.competence_date || null,
      bank_account_id: cleanId(createModal.form.bank_account_id),
      payment_method_id: cleanId(createModal.form.payment_method_id),
      chart_of_accounts_id: cleanId(createModal.form.chart_of_accounts_id),
      notes: createModal.form.notes || '',
      order_id: cleanId(orderId),
      customer_id: cleanId(props.order?.customer_id),
      company_id: cleanId(defaultCompanyId.value),
      entity_name: resolvedClientName,
      created_by: userStore.user?.id // <-- OBRIGATÓRIO PARA A AUDITORIA
    };

    if (createModal.isEdit && createModal.editingId) {
        // Lógica de Edição (Mantida intacta)
        const { data: oldData } = await supabase.from('finance_receivables').select('*').eq('id', createModal.editingId).single();
        const { error: updateError } = await supabase.from('finance_receivables').update(payload).eq('id', createModal.editingId);
        if (updateError) throw updateError;

        await logSecureAction('RECEIVABLE_EDITED', payload, orderId, oldData);
        if(oldData && oldData.value !== payload.value) {
            await notifyFinancialAdmins('Recebimento Editado', `${user} alterou o recebimento de ${formatCurrency(oldData.value)} para ${formatCurrency(payload.value)}.`, `/sales/orders/${orderId}`);
        }
        appStore.showSnackbar('Recebimento atualizado!', 'success');
    } else {
        const valueToLaunch = Number(payload.value) || 0;
        if (valueToLaunch <= 0) {
            appStore.showSnackbar('Informe um valor maior que zero.', 'warning');
            return;
        }

        if (remainingBalance.value > 0.05 && valueToLaunch > remainingBalance.value + 0.05) {
            appStore.showSnackbar(`O valor informado é maior que o total em aberto (${formatCurrency(remainingBalance.value)}).`, 'warning');
            return;
        }

        const { error: insertError } = await supabase.from('finance_receivables').insert({ ...payload, status: 'em_aberto' });
        if (insertError) throw insertError;

        await logSecureAction('RECEIVABLE_CREATED', payload, orderId);

        const stillOpen = Math.max(0, remainingBalance.value - valueToLaunch);
        if (stillOpen > 0.05) {
            appStore.showSnackbar(`Recebimento criado. Restante em aberto: ${formatCurrency(stillOpen)}.`, 'success');
        } else {
            appStore.showSnackbar('Recebimento criado e pedido totalmente programado!', 'success');
        }
    }

    createModal.show = false;
    fetchReceivables();
  } catch (e: any) {
      appStore.showSnackbar('Erro ao salvar: ' + (e.message || 'Falha no banco'), 'error');
  } finally {
      createModal.loading = false;
  }
};

const openPaymentConfirm = (rec: any) => {
  paymentConfirmModal.rec = rec;
  paymentConfirmModal.paymentDate = format(new Date(), 'yyyy-MM-dd');
  paymentConfirmModal.methodId = rec.payment_method_id || null;
  paymentConfirmModal.maxAmount = Number(rec.value) || 0;
  paymentConfirmModal.amount = Number(rec.value) || 0;
  paymentConfirmModal.show = true;
};

const openPaymentConfirmFromOpenBalance = (row: any) => {
  const source = row?.sourceReceivableId
    ? receivables.value.find(r => r.id === row.sourceReceivableId)
    : consolidatedOpenReceivable.value;

  openPaymentConfirm({
    ...(source || {}),
    id: source?.id || null,
    is_open_balance: true,
    description: row.description || `Total em aberto - Pedido #${orderNumberLabel.value}`,
    value: Number(row.value) || 0,
    due_date: row.due_date || source?.due_date || format(new Date(), 'yyyy-MM-dd'),
    payment_method_id: row.payment_method_id || source?.payment_method_id || null,
    bank_account_id: row.bank_account_id || source?.bank_account_id || null,
    chart_of_accounts_id: row.chart_of_accounts_id || source?.chart_of_accounts_id || null,
    notes: row.notes || source?.notes || ''
  });
};

const ensureOpenBalanceReceivable = async (amount: number, baseRec: any, dueDate?: string) => {
  const orderId = resolvedOrderId.value;
  if (!orderId || amount <= 0.05) return;

  const cleanId = (val: any) => (val && String(val).trim() !== '') ? val : null;
  const existingOpen = openReceivables.value.find(r => r.id && r.id !== baseRec?.id) || null;
  const description = `Total em aberto - Pedido #${orderNumberLabel.value}`;
  const payload: any = {
    description,
    value: Number(amount.toFixed(2)),
    due_date: dueDate || baseRec?.due_date || format(new Date(), 'yyyy-MM-dd'),
    competence_date: dueDate || baseRec?.competence_date || baseRec?.due_date || format(new Date(), 'yyyy-MM-dd'),
    bank_account_id: cleanId(baseRec?.bank_account_id),
    payment_method_id: cleanId(baseRec?.payment_method_id),
    chart_of_accounts_id: cleanId(baseRec?.chart_of_accounts_id),
    notes: `${baseRec?.notes || ''} [Sobra mantida como Total em aberto após recebimento parcial.]`.trim(),
    order_id: cleanId(orderId),
    customer_id: cleanId(props.order?.customer_id),
    company_id: cleanId(baseRec?.company_id || defaultCompanyId.value),
    entity_name: props.order?.customer_name || props.order?.customer?.nome || props.order?.customer?.name || props.order?.customer?.razao_social || props.order?.cliente || 'Cliente Não Identificado',
    status: 'em_aberto',
    created_by: userStore.user?.id
  };

  if (existingOpen?.id) {
    const { error } = await supabase.from('finance_receivables').update(payload).eq('id', existingOpen.id);
    if (error) throw error;
  } else {
    const { error } = await supabase.from('finance_receivables').insert(payload);
    if (error) throw error;
  }
};

const confirmMarkPaid = async () => {
  const rec = paymentConfirmModal.rec;
  if (!rec) return;

  const receivedAmount = Number(paymentConfirmModal.amount) || 0;
  const originalAmount = Number(paymentConfirmModal.maxAmount || rec.value) || 0;

  if (receivedAmount <= 0) {
      appStore.showSnackbar('Informe um valor recebido maior que zero.', 'warning');
      return;
  }

  if (receivedAmount > originalAmount + 0.05) {
      appStore.showSnackbar(`O valor recebido não pode passar de ${formatCurrency(originalAmount)}.`, 'warning');
      return;
  }

  if (!paymentConfirmModal.methodId) {
      appStore.showSnackbar('Selecione a forma de recebimento.', 'warning');
      return;
  }

  paymentConfirmModal.loading = true;
  const selectedDate = paymentConfirmModal.paymentDate || format(new Date(), 'yyyy-MM-dd');
  const methodId = paymentConfirmModal.methodId;
  const user = userStore.profile?.full_name || 'Usuário';
  const isPartial = receivedAmount < originalAmount - 0.05;
  const remainingAfterPayment = Math.max(0, originalAmount - receivedAmount);
  const orderId = resolvedOrderId.value;

  try {
      const cleanId = (val: any) => (val && String(val).trim() !== '') ? val : null;
      const resolvedClientName = props.order?.customer_name || props.order?.customer?.nome || props.order?.customer?.name || props.order?.customer?.razao_social || props.order?.cliente || 'Cliente Não Identificado';

      const paidPayload: any = {
          description: rec.description || `Recebimento - Pedido #${orderNumberLabel.value}`,
          status: 'pago',
          value: receivedAmount,
          due_date: rec.due_date || selectedDate,
          competence_date: rec.competence_date || rec.due_date || selectedDate,
          paid_at: new Date().toISOString(),
          receipt_date: selectedDate,
          paid_value: receivedAmount,
          payment_date: selectedDate,
          bank_account_id: cleanId(rec.bank_account_id),
          payment_method_id: methodId,
          chart_of_accounts_id: cleanId(rec.chart_of_accounts_id),
          notes: `${rec.notes || ''}${isPartial ? ` [Recebimento parcial: entrou ${formatCurrency(receivedAmount)} de ${formatCurrency(originalAmount)}. Restante: ${formatCurrency(remainingAfterPayment)}.]` : ''}`.trim(),
          order_id: cleanId(orderId),
          customer_id: cleanId(props.order?.customer_id),
          company_id: cleanId(rec.company_id || defaultCompanyId.value),
          entity_name: resolvedClientName,
          created_by: userStore.user?.id
      };

      if (rec.id) {
        const { error: paidError } = await supabase.from('finance_receivables').update(paidPayload).eq('id', rec.id);
        if (paidError) throw paidError;
      } else {
        const { error: insertPaidError } = await supabase.from('finance_receivables').insert(paidPayload);
        if (insertPaidError) throw insertPaidError;
      }

      if (isPartial) {
        await ensureOpenBalanceReceivable(remainingAfterPayment, { ...rec, id: rec.id || null, payment_method_id: methodId }, rec.due_date || selectedDate);
      }

      await cashStore.logExtraction(
          'ORDER_PAYMENTS_BAIXA',
          receivedAmount,
          methodId,
          `#${orderNumberLabel.value}`,
          { id: rec.id || 'open-balance', desc: rec.description, partial: isPartial, original_value: originalAmount, remaining: remainingAfterPayment }
      );

      try {
          await cashStore.checkActiveSession();
          if (cashStore.isSessionOpen && cashStore.currentSession) {
              if (cashStore.storeCashMethodIds.length === 0) {
                  await cashStore.fetchStoreConfig(cashStore.currentSession.store_id);
              }
              if (cashStore.isCashMethod(methodId)) {
                  await cashStore.registerMovement(
                      'in_audit',
                      receivedAmount,
                      `${isPartial ? 'Recebimento parcial' : 'Recebimento'} (Pedido #${orderNumberLabel.value})`,
                      resolvedOrderId.value
                  );
              }
          }
      } catch (cashErr) {
          console.error("Falha ao integrar com o caixa:", cashErr);
      }

      const attachments = getAttachments(rec);
      const lastAttachment = attachments.length > 0 ? attachments[attachments.length - 1].url : null;

      await logSecureAction(
          'PAYMENT_RECEIVED',
          {
              value: receivedAmount,
              original_value: originalAmount,
              remaining: remainingAfterPayment,
              partial: isPartial,
              description: rec.description,
              attachment_url: lastAttachment,
              method: getPaymentMethodName(methodId)
          },
          resolvedOrderId.value
      );

      await notifyFinancialAdmins(
          isPartial ? 'Recebimento Parcial Confirmado' : 'Recebimento Confirmado',
          `O usuário ${user} confirmou o recebimento de ${formatCurrency(receivedAmount)} no Pedido #${orderNumberLabel.value} para a data ${formatDateSimple(selectedDate)}.${isPartial ? ` Restante em aberto: ${formatCurrency(remainingAfterPayment)}.` : ''}`,
          `/sales/orders/${resolvedOrderId.value}`
      );

      appStore.showSnackbar(isPartial ? `Recebimento parcial confirmado. Restante em aberto: ${formatCurrency(remainingAfterPayment)}.` : 'Recebimento confirmado!', 'success');
      await fetchReceivables();
      paymentConfirmModal.show = false;
  } catch(e:any) {
      appStore.showSnackbar('Erro: ' + e.message, 'error');
  } finally {
      paymentConfirmModal.loading = false;
  }
};

const revertPaid = async (rec: any) => {
  actionLoadingId.value = rec.id;
  const user = userStore.profile?.full_name || 'Usuário';

  try {
      await supabase.from('finance_receivables').update({
          status: 'em_aberto', paid_at: null, receipt_date: null, paid_value: 0, payment_date: null
      }).eq('id', rec.id);

      // --- CAIXA PRETA: LOG DO ESTORNO (VALOR NEGATIVO) ---
      await cashStore.logExtraction(
          'ORDER_PAYMENTS_ESTORNO',
          -Math.abs(Number(rec.value)),
          rec.payment_method_id,
          `#${orderNumberLabel.value}`,
          { id: rec.id, desc: rec.description }
      );

      try {
          await cashStore.checkActiveSession();
          if (cashStore.isSessionOpen && cashStore.currentSession) {
              if (cashStore.storeCashMethodIds.length === 0) {
                  await cashStore.fetchStoreConfig(cashStore.currentSession.store_id);
              }
              if (cashStore.isCashMethod(rec.payment_method_id)) {
                  await cashStore.registerMovement(
                      'out_audit',
                      Number(rec.value),
                      `Estorno Recebimento (Pedido #${orderNumberLabel.value})`,
                      resolvedOrderId.value
                  );
              }
          }
      } catch (cashErr) {
          console.error("Falha ao reverter no caixa:", cashErr);
      }

      await logSecureAction('PAYMENT_REVERTED', { value: rec.value, description: rec.description, reason: 'Estorno manual' }, resolvedOrderId.value);
      await notifyFinancialAdmins('Estorno Realizado', `ATENÇÃO: Pagamento de ${formatCurrency(rec.value)} foi estornado por ${user} no Pedido #${orderNumberLabel.value}.`, `/sales/orders/${resolvedOrderId.value}`);

      appStore.showSnackbar('Estornado!', 'success');
      fetchReceivables();
  } catch(e:any) {
      appStore.showSnackbar('Erro: ' + e.message, 'error');
  } finally {
      actionLoadingId.value = null;
  }
};

const deleteReceivable = async (rec: any) => {
    if(!confirm('Tem certeza que deseja excluir este lançamento?')) return;
    try {
        await supabase.from('finance_receivables').delete().eq('id', rec.id);
        await logSecureAction('RECEIVABLE_DELETED', { description: rec.description, value: rec.value }, resolvedOrderId.value);

        appStore.showSnackbar('Excluído.', 'success');
        fetchReceivables();
    } catch(e:any) { appStore.showSnackbar('Erro: ' + e.message, 'error'); }
};

const createFromPlanned = (row: any) => {
    openPaymentConfirmFromOpenBalance(row);
};

const createFromLegacy = (pay: any) => {
  const dateVal = pay.payment_date || pay.created_at ? String(pay.payment_date || pay.created_at).split('T')[0] : '';
  const typeName = pay.payment_type || 'Pagamento';
  const desc = `${typeName} - #${orderNumberLabel.value}`;
  let methodId = null;
  if (pay.payment_method) {
      const legacyMethod = String(pay.payment_method).toLowerCase().trim();
      const match = auxData.paymentMethods.find(m => m.name.toLowerCase().includes(legacyMethod) || legacyMethod.includes(m.name.toLowerCase()));
      if (match) methodId = match.id;
  }
  openCreateModal({ description: desc.substring(0, 100), value: Number(pay.amount || 0), due_date: dateVal, competence_date: dateVal, payment_method_id: methodId, notes: pay.notes ? `[Obs original: ${pay.notes}]` : '' });
};

const openPixModal = (rec: any) => {
    linkModal.value = rec.value; linkModal.description = rec.description; linkModal.associatedRecId = rec.id; linkModal.status = 'PENDING';
    linkModal.qrCodeUrl = ''; linkModal.copyPaste = ''; linkModal.step = 'config'; linkModal.companyId = defaultCompanyId.value; linkModal.show = true;
};

const executePixGeneration = async () => {
    const rec = { value: linkModal.value, description: linkModal.description, id: linkModal.associatedRecId || '00' };

    if (!linkModal.companyId) { appStore.showSnackbar('Selecione uma empresa emissora.', 'error'); return; }

    const selectedCompany = auxData.companies.find(c => c.id === linkModal.companyId);
    let targetCoraId = null;
    const companyCnpj = selectedCompany?.cnpj ? selectedCompany.cnpj.replace(/\D/g, '') : '';

    if (companyCnpj && coraKeys[companyCnpj]) targetCoraId = coraKeys[companyCnpj];
    else targetCoraId = selectedCompany?.cora_client_id || selectedCompany?.client_id || selectedCompany?.id;

    let identity = props.order?.customer?.cpf_cnpj || props.order?.customer?.cnpj || props.order?.customer?.cpf;
    if (!identity && props.order?.customer_id) {
        try {
            const customerId = String(props.order.customer_id);
            const isUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(customerId);
            const query = supabase.from('customers_mj').select('*').limit(1);
            if (isUuid) query.eq('id', customerId); else query.eq('gestao_click_id', customerId);
            const { data: client } = await query.maybeSingle();
            if (client) identity = client.cpf_cnpj || client.cnpj || client.cpf || client.documento;
        } catch (err) { console.error("Falha no fallback de cliente:", err); }
    }

    if (!identity) { appStore.showSnackbar('Cliente sem CPF/CNPJ cadastrado. Impossível gerar Pix.', 'warning'); return; }
    identity = identity.replace(/\D/g, '');

    if (companyCnpj && identity === companyCnpj) { appStore.showSnackbar('Erro: Auto-cobrança não permitida (CNPJ Cliente igual ao Emissor).', 'error'); return; }

    linkModal.loading = true;
    const resolvedClientName = props.order?.customer_name || props.order?.customer?.nome || props.order?.customer?.name || props.order?.customer?.razao_social || 'Cliente';

    try {
        const result = await coraApi.generatePix({ amount: Math.round(Number(rec.value) * 100), code: `PARC-${rec.id.substring(0,8)}`, customer: { name: resolvedClientName, identity: identity } }, targetCoraId);
        linkModal.qrCodeUrl = result.qrCodeUrl; linkModal.copyPaste = result.emv; linkModal.invoiceId = result.id; linkModal.step = 'view';
        if (linkModal.associatedRecId) await supabase.from('finance_receivables').update({ company_id: linkModal.companyId }).eq('id', linkModal.associatedRecId);
        startPixPolling();
    } catch (e: any) { appStore.showSnackbar('Erro ao gerar QR Code Cora: ' + e.message, 'error'); } finally { linkModal.loading = false; }
};

const startPixPolling = () => {
    if (linkModal.checkInterval) clearInterval(linkModal.checkInterval);
    linkModal.checkInterval = setInterval(async () => {
        if (!linkModal.invoiceId || linkModal.status === 'PAID') return;
        try {
            const res = await coraApi.checkStatus(linkModal.invoiceId);
            if (res && res.status === 'PAID') {
                linkModal.status = 'PAID'; clearInterval(linkModal.checkInterval!);
                if (linkModal.associatedRecId) {
                    const today = format(new Date(), 'yyyy-MM-dd');
                    const coraBank = auxData.bankAccounts.find(b => b.name.toLowerCase().includes('cora'));

                    await supabase.from('finance_receivables').update({ status: 'pago', paid_at: new Date().toISOString(), receipt_date: today, paid_value: linkModal.value, payment_date: today, bank_account_id: coraBank?.id || null, created_by: userStore.user?.id }).eq('id', linkModal.associatedRecId);

                    // --- CAIXA PRETA: LOG DE EXTRAÇÃO DO PIX AUTOMÁTICO ---
                    const pixMethodId = auxData.paymentMethods.find(m => m.name.toLowerCase().includes('pix'))?.id || null;
                    await cashStore.logExtraction(
                        'ORDER_PAYMENTS_PIX_AUTO',
                        linkModal.value,
                        pixMethodId,
                        `#${orderNumberLabel.value}`,
                        { id: linkModal.associatedRecId, desc: "PIX Automático Cora" }
                    );

                    fetchReceivables();
                }
                appStore.showSnackbar('Pagamento Pix Confirmado!', 'success');
            }
        } catch (err) {}
    }, 4000);
};

const copyLink = () => { navigator.clipboard.writeText(linkModal.copyPaste); appStore.showSnackbar('Copia e Cola copiado!', 'success'); };
const sendWhatsapp = () => {
    let phone = props.order?.customer?.phone || props.order?.whatsapp || props.order?.customer?.celular || '';
    phone = phone.replace(/\D/g, '');
    const text = `Olá *${props.order?.customer_name || 'Cliente'}*,\n\n` + `Segue o QR Code Pix para pagamento da parcela: *${linkModal.description}*\n` + `Valor: *${formatCurrency(linkModal.value)}*\n\n` + `Copie e cole o código abaixo no seu banco:\n\n` + `${linkModal.copyPaste}`;
    let url = '';
    if (phone.length >= 10) { const targetPhone = phone.startsWith('55') ? phone : `55${phone}`; url = `https://api.whatsapp.com/send?phone=${targetPhone}&text=${encodeURIComponent(text)}`; }
    else { url = `https://api.whatsapp.com/send?text=${encodeURIComponent(text)}`; appStore.showSnackbar('Telefone não encontrado. Selecione o contato no WhatsApp.', 'info'); }
    window.open(url, '_blank');
};
const sendEmail = () => {
    const email = props.order?.customer?.email || '';
    const subject = `Pagamento Pedido #${orderNumberLabel.value} - MR JACKY`;
    const body = `Olá, segue código Pix para pagamento: \n\n${linkModal.copyPaste}\n\nValor: ${formatCurrency(linkModal.value)}`;
    window.location.href = `mailto:${email}?subject=${encodeURIComponent(subject)}&body=${encodeURIComponent(body)}`;
};

const imageToBase64 = (urlOrFile: string | File): Promise<string> => new Promise((resolve, reject) => {
    const img = new Image(); img.crossOrigin = 'Anonymous';
    img.onload = () => {
        const canvas = document.createElement('canvas'); canvas.width = img.width; canvas.height = img.height;
        const ctx = canvas.getContext('2d');
        if (ctx) { ctx.drawImage(img, 0, 0); resolve(canvas.toDataURL('image/png')); } else { reject(new Error('Canvas context error')); }
    };
    img.onerror = reject;
    if (typeof urlOrFile === 'string') img.src = urlOrFile; else img.src = URL.createObjectURL(urlOrFile);
});

const addHeader = async (doc: jsPDF, orderNum: any, title: string, yOffset = 0) => {
    const pageWidth = doc.internal.pageSize.width; const margin = 15;
    try {
        const logoUrl = 'https://cdn.shopify.com/s/files/1/0661/4574/6991/files/Sem_nome_1080_x_800_px_1080_x_500_px_1080_x_400_px_1000_x_380_px_da020cf2-2bb9-4dac-8dd3-4548cfd2e5ae.png?v=1756811713';
        const logoBase64 = await imageToBase64(logoUrl); const logoProps = doc.getImageProperties(logoBase64);
        const logoWidth = 45; const logoHeight = (logoProps.height * logoWidth) / logoProps.width;
        doc.addImage(logoBase64, 'PNG', margin, 12 + yOffset, logoWidth, logoHeight);
    } catch (e) { }
    doc.setFont('helvetica', 'bold'); doc.setFontSize(14); doc.text(title, pageWidth / 2, 20 + yOffset, { align: 'center' });
    if (orderNum) { doc.setFontSize(12); doc.setTextColor(0, 0, 0); doc.text(`Pedido / Ref Nº: ${String(orderNum).padStart(4, '0')}`, pageWidth / 2, 28 + yOffset, { align: 'center' }); }
    doc.setFont('helvetica', 'normal'); doc.setFontSize(8); doc.setTextColor(100);
    doc.text([ "MATRIZ:", "MR JACKY - 20.631.721/0001-07", "R. Luiz Montanhan, 1302 - Tiete, SP", "Contato: (15) 99781-8102" ], pageWidth - margin, 15 + yOffset, { align: 'right' });
    doc.setLineWidth(0.5); doc.line(margin, 38 + yOffset, pageWidth - margin, 38 + yOffset);
};

const addFooter = (doc: jsPDF) => {
    const pageCount = (doc as any).internal.getNumberOfPages(); const pageWidth = doc.internal.pageSize.width; const pageHeight = doc.internal.pageSize.height;
    doc.setFontSize(8).setTextColor(150);
    for (let i = 1; i <= pageCount; i++) {
        doc.setPage(i); doc.text(`Gerado com MJProcess em ${format(new Date(), 'dd/MM/yyyy HH:mm')}`, 15, pageHeight - 3); doc.text(`Página ${i} de ${pageCount}`, pageWidth - 15, pageHeight - 3, { align: 'right' });
    }
};

const addWatermark = async (doc: jsPDF) => {
    const totalPages = (doc as any).internal.getNumberOfPages(); const pageWidth = doc.internal.pageSize.getWidth(); const pageHeight = doc.internal.pageSize.getHeight();
    let logoBase64: string | null = null;
    try { const logoUrl = 'https://cdn.shopify.com/s/files/1/0661/4574/6991/files/Sem_nome_1080_x_800_px_1080_x_500_px_1080_x_400_px_1000_x_380_px_da020cf2-2bb9-4dac-8dd3-4548cfd2e5ae.png?v=1756811713'; logoBase64 = await imageToBase64(logoUrl); } catch (e) { }
    for (let i = 1; i <= totalPages; i++) {
        doc.setPage(i); doc.saveGraphicsState(); doc.setGState(new (doc as any).GState({ opacity: 0.08 }));
        if (logoBase64) { const logoProps = doc.getImageProperties(logoBase64); const logoWidth = pageWidth * 0.75; const logoHeight = (logoProps.height * logoWidth) / logoProps.width; doc.addImage(logoBase64, 'PNG', (pageWidth - logoWidth) / 2, (pageHeight - logoHeight) / 2, logoWidth, logoHeight); }
        doc.setGState(new (doc as any).GState({ opacity: 0.7 })); doc.setFont('helvetica', 'bold'); doc.setFontSize(18); doc.setTextColor(255, 150, 150);
        const text = 'recibo'; const yStep = 50;
        for (let y = 25; y < pageHeight - 15; y += yStep) { doc.text(text, 6, y, { angle: 90 }); doc.text(text, pageWidth - 6, y, { angle: -90 }); }
        doc.restoreGraphicsState();
    }
};

const addWarningsFooter = (doc: jsPDF, startY: number) => {
    const pageWidth = doc.internal.pageSize.width; const margin = 15; let currentY = startY;
    doc.setLineWidth(0.5); doc.setDrawColor(180, 180, 180); doc.line(margin, currentY, pageWidth - margin, currentY); currentY += 5;
    doc.setFontSize(9).setFont('helvetica', 'bold'); doc.text('Observações Importantes:', margin, currentY); currentY += 5; doc.setFontSize(8).setFont('helvetica', 'normal');
    const warnings = [ '- Em caso de desistência o sinal não será devolvido.', '- Todos tecidos com processo de estamparia vem com em medidas de 1cm cada lado de ourela em branco.', '- Para pedidos pedimos 30% de sinal do valor total do pedido e o restante do pagamento será feito um dia antes da entrega!', '- Poderá haver variações:', '  - Nas cores do desenho 10% para mais ou para menos', '  - Nas quantidade MTS-KGS 15% para mais ou para menos' ];
    warnings.forEach(warning => { const lines = doc.splitTextToSize(warning, pageWidth - (margin * 2)); doc.text(lines, margin, currentY); currentY += (lines.length * 4); });
    return currentY;
};

const handlePrintReceipt = async (rec: any) => {
    if (!props.order) return;
    printLoadingId.value = rec.id;
    try {
        const orderNum = props.order.order_number; const clientName = props.order.customer_name || 'Cliente'; const clientCpfCnpj = props.order.customer?.cpf_cnpj || 'Não informado';
        const amount = Number(rec.value); const method = getPaymentMethodName(rec.payment_method_id) || 'Diversos'; const description = rec.description || `Recebimento ${formatCurrency(amount)}`;
        const pdfFileName = `Recibo_${String(orderNum).padStart(4, '0')}_Parc_${rec.id}.pdf`;
        const qrCodeContent = window.location.href; const qrCodeDataUrl = await QRCode.toDataURL(qrCodeContent, { width: 175, margin: 1 });
        const doc = new jsPDF('p', 'mm', 'a4'); const pageWidth = doc.internal.pageSize.width; const pageHeight = doc.internal.pageSize.height; const midPointY = pageHeight / 2; const margin = 15; const orderNumberText = String(orderNum).padStart(4, '0');
        const introText = `A MR JACKY confirma o recebimento do valor descrito abaixo, referente a pagamento do Pedido de Venda nº ${orderNumberText}.`;
        const qrSize = 25; const qrGap = 5; const tableWidth = pageWidth - margin * 2 - qrSize - qrGap;
        const tableHead = [['Cliente', 'CPF/CNPJ', 'Valor Pago', 'Detalhes / Forma']]; const tableBody = [[ clientName, clientCpfCnpj, formatCurrency(amount), `${description} (${method})` ]];
        const dataDoPagamento = `Tiete, ${format(new Date(), "dd 'de' MMMM 'de' yyyy", { locale: ptBR })}.`;

        const generateViaContent = async (yOffset: number, viaTitle: string) => {
            await addHeader(doc, orderNum, `Recibo de Pagamento`, yOffset);
            doc.setFontSize(8).setTextColor(150).text(viaTitle, pageWidth - margin, yOffset + 10, { align: 'right' });
            const startY = yOffset + 48; doc.setFontSize(10).setFont('helvetica', 'normal').setTextColor(0, 0, 0); doc.text(introText, margin, startY, { maxWidth: pageWidth - margin * 2 });
            const tableStartY = startY + 12; const qrX = margin + tableWidth + qrGap;
            autoTable(doc, { startY: tableStartY, head: tableHead, body: tableBody, theme: 'striped', headStyles: { fillColor: yOffset === 0 ? [220, 230, 250] : [70, 100, 200], textColor: yOffset === 0 ? 0 : [255, 255, 255], fontStyle: 'bold' }, columnStyles: { 0: { cellWidth: 'auto' }, 1: { cellWidth: 40 }, 2: { cellWidth: 35, halign: 'right' }, 3: { cellWidth: 50 } }, styles: { overflow: 'linebreak', cellPadding: 2 }, tableWidth: tableWidth, margin: { left: margin }, });
            doc.addImage(qrCodeDataUrl, 'PNG', qrX, tableStartY, qrSize, qrSize); doc.setFontSize(7).setTextColor(100).text('Validar', qrX + qrSize / 2, tableStartY + qrSize + 3, { align: 'center' });
            let finalY = (doc as any).lastAutoTable.finalY + 10; finalY = addWarningsFooter(doc, finalY);
            const signatureY = Math.min(finalY + 15, (yOffset === 0 ? midPointY : pageHeight) - 20); const signatureWidth = (pageWidth - margin * 3) / 2; const signatureX1 = margin; const signatureX2 = margin * 2 + signatureWidth;
            doc.setLineWidth(0.3).setDrawColor(0, 0, 0); doc.line(signatureX1, signatureY, signatureX1 + signatureWidth, signatureY); doc.setFontSize(9).setTextColor(0, 0, 0).text('MR JACKY', signatureX1 + signatureWidth / 2, signatureY + 5, { align: 'center' });
            doc.line(signatureX2, signatureY, signatureX2 + signatureWidth, signatureY); doc.setFontSize(9).setTextColor(0, 0, 0).text(clientName, signatureX2 + signatureWidth / 2, signatureY + 5, { align: 'center' });
            const dateY = signatureY + 15; doc.setFontSize(9).setFont('helvetica', 'normal').text(dataDoPagamento, pageWidth / 2, dateY, { align: 'center' });
        };

        await generateViaContent(0, 'Via da Empresa');
        doc.setLineDashPattern([2, 2], 0); doc.line(5, midPointY, pageWidth - 5, midPointY); doc.setLineDashPattern([], 0);
        doc.setFontSize(8).setTextColor(150).text('- - - - corte aqui - - - -', pageWidth / 2, midPointY - 1, { align: 'center' });
        await generateViaContent(midPointY, 'Via do Cliente'); await addWatermark(doc); addFooter(doc);

        doc.save(pdfFileName); appStore.showSnackbar('Recibo gerado com sucesso!', 'success');
    } catch (e:any) { console.error(e); appStore.showSnackbar('Erro ao gerar recibo: ' + e.message, 'error'); } finally { printLoadingId.value = null; }
}

const openReceiptPicker = (rec: any) => { pendingReceiptFor.value = rec; if(fileInput.value) { fileInput.value.value = ''; fileInput.value.click(); } };

const handleReceiptSelected = async (e: Event) => {
  const input = e.target as HTMLInputElement; const file = input.files?.[0]; const rec = pendingReceiptFor.value;
  if (!file || !rec?.id) return;
  try {
    const bucket = 'proofs'; const ext = file.name.split('.').pop() || 'bin'; const path = `receivables/${rec.id}/${Date.now()}.${ext}`;
    const { error: upErr } = await supabase.storage.from(bucket).upload(path, file, { upsert: true });
    if (upErr) throw upErr;
    const { data: pub } = supabase.storage.from(bucket).getPublicUrl(path); const url = pub?.publicUrl;
    const currentAttachments = getAttachments(rec); const newAttachments = [...currentAttachments, { type: 'receipt', url, filename: file.name, created_at: new Date().toISOString() }];
    await supabase.from('finance_receivables').update({ billing_items_snapshot: newAttachments }).eq('id', rec.id);
    await logSecureAction('RECEIVABLE_ATTACHMENT', { description: rec.description, filename: file.name, url: url }, resolvedOrderId.value);
    appStore.showSnackbar('Comprovante anexado!', 'success'); await fetchReceivables();
  } catch (err: any) { appStore.showSnackbar('Erro upload: ' + err.message, 'error'); }
};

watch(viewMode, (val) => { if(val === 'logs') fetchAuditLogs(); });
watch(() => props.modelValue, (v) => { if(v) fetchAll(); });
onMounted(() => { if(props.modelValue) fetchAll(); });
onUnmounted(() => { if (realtimeChannel.value) supabase.removeChannel(realtimeChannel.value); if (linkModal.checkInterval) clearInterval(linkModal.checkInterval); });
</script>

<style scoped lang="scss">
.btn-rect { border-radius: 6px !important; text-transform: none !important; font-weight: 900; }
.icon-rect { border-radius: 6px !important; }
.bg-glass-header { background: rgba(20,20,24,0.55); backdrop-filter: blur(14px); }
.border-bottom-white-05 { border-bottom: 1px solid rgba(255,255,255,0.08); }
.border-thin { border: 1px solid rgba(0,0,0,0.08); }
.glass-card { background: rgba(30, 30, 35, 0.45); backdrop-filter: blur(25px); border: 1px solid rgba(255,255,255,0.08); }
.bg-white-05 { background: rgba(255,255,255,0.05); }
.bg-white-10 { background: rgba(255,255,255,0.1); }
.bg-white-20 { background: rgba(255,255,255,0.2); }

.kpi-bg-icon { position: absolute; right: -20px; bottom: -20px; opacity: 0.15; transform: rotate(-15deg); pointer-events: none; z-index: 0; }
.kpi-bg-icon .v-icon { font-size: 100px; color: white; }
.kpi-card { border: 1px solid rgba(255,255,255,0.15); color: white; min-height: 110px; position: relative; overflow: hidden; transition: all 0.2s ease; border-radius: 8px !important; }
.bg-gradient-green { background: linear-gradient(135deg, #2e7d32, #1b5e20); }
.bg-gradient-red { background: linear-gradient(135deg, #c62828, #8e0000); }
.bg-gradient-purple { background: linear-gradient(135deg, #7b1fa2, #4a148c); }
.bg-gradient-info { background: linear-gradient(135deg, #0288d1, #01579b); }
.bg-gradient-gray { background: linear-gradient(135deg, #757575, #424242); }
.kpi-label { font-size: 13px; font-weight: 900; letter-spacing: .2px; text-transform: uppercase; }
.kpi-value { font-size: 24px; font-weight: 900; letter-spacing: .2px; }
.kpi-footer { font-size: 12px; opacity: .9; font-weight: 700; }

.grid-scroll { scrollbar-gutter: stable both-edges; width: 100%; }
.custom-scroll::-webkit-scrollbar { width: 8px; height: 8px; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.35); border-radius: 6px; }
.custom-scroll::-webkit-scrollbar-track { background: transparent; }

/* Grid Layout Reformulado - Coluna Plano de Contas Adicionada */
.grid-header, .grid-row {
    display: grid;
    align-items: stretch;
    width: 100%;
    grid-template-columns: minmax(280px, 1.5fr) 180px 120px 140px 160px 120px 150px;
    min-width: 1300px; /* Garante que as colunas respirem no scroll horizontal */
}

.cell { padding: 10px 12px; display: flex; align-items: center; border-right: 1px solid rgba(0,0,0,0.08); border-bottom: 1px solid rgba(0,0,0,0.08); min-height: 56px; overflow: hidden; }
.center { justify-content: center; text-align: center; }
.grid-header .cell { min-height: 44px; font-size: 11px; font-weight: 900; text-transform: uppercase; letter-spacing: .6px; }
.header-text { font-size: 11px; color: rgba(0,0,0,0.7); }

.grid-surface-light .cell { background: #f5f7fa; color: rgba(0,0,0,0.9); border-color: rgba(0,0,0,0.10); }
.grid-surface-dark .cell { background: rgba(255,255,255,0.08); color: rgba(255,255,255,0.80); border-color: rgba(255,255,255,0.10); }

.grid-row-light .cell { background: #fff; border-color: rgba(0,0,0,0.08); transition: background-color 0.2s ease; }
.grid-row-light:hover .cell { background: #F8FAFC !important; cursor: default; }
.grid-row-dark .cell { background: rgba(255,255,255,0.04); border-color: rgba(255,255,255,0.08); }
.grid-row-dark:hover .cell { background: rgba(255,255,255,0.07); }

.zebra-light-a .cell { background: #ffffff; }
.zebra-light-b .cell { background: #fafafa; }
.zebra-dark-a .cell { background: rgba(255,255,255,0.03); }
.zebra-dark-b .cell { background: rgba(255,255,255,0.06); }
.sticky-head { position: sticky; top: 0; z-index: 10; box-shadow: 0 4px 6px -4px rgba(0,0,0,0.1); }

.list-text-10 { font-size: 11px !important; line-height: 1.25 !important; }
.list-text-11 { font-size: 12px !important; line-height: 1.25 !important; }

.solid-chip { display: inline-flex; align-items: center; justify-content: center; height: 26px; padding: 0 14px; border-radius: 8px; font-size: 11px; font-weight: 900; color: #fff; white-space: nowrap; text-transform: uppercase; }
.chip-status { min-width: 90px; }
.chip-success { background: #2e7d32; }
.chip-warn { background: #f57f17; }
.chip-info { background: #1976d2; }

/* Botões 3D e Estilização */
.btn-3d {
    border-radius: 6px !important;
    box-shadow: 0 3px 5px rgba(0,0,0,0.15), inset 0 2px 0 rgba(255,255,255,0.25) !important;
    transition: transform 0.1s ease, box-shadow 0.1s ease;
}
.btn-3d:active {
    transform: translateY(2px);
    box-shadow: 0 1px 2px rgba(0,0,0,0.15), inset 0 1px 0 rgba(255,255,255,0.2) !important;
}

.chip-3d {
    box-shadow: 0 3px 5px rgba(0,0,0,0.12), inset 0 1px 0 rgba(255,255,255,0.25) !important;
    text-shadow: 0 1px 2px rgba(0,0,0,0.25);
}

.actions-inline { display: flex; align-items: center; justify-content: center; gap: 8px; }
.action-btn { width: 32px !important; height: 32px !important; border-radius: 6px !important; color: #fff !important; }
.action-btn :deep(.v-icon) { color: #fff !important; }
.action-edit { background: #1976d2 !important; }
.action-pay { background: #2e7d32 !important; }
.action-revert { background: #f57f17 !important; }

.ui-field :deep(.v-field) { border-radius: 6px !important; }
.ui-field :deep(.v-field__input) { min-height: 44px !important; padding-top: 6px !important; padding-bottom: 6px !important; font-size: 14px; font-weight: bold; }
.ui-field :deep(.v-field__prepend-inner) { margin-right: 8px !important; }
.row-gap { row-gap: 16px; }


.status-click {
    border: none;
    cursor: pointer;
    transition: transform .16s ease, filter .16s ease, box-shadow .16s ease;
}
.status-click:hover {
    transform: translateY(-1px);
    filter: brightness(1.05);
}
.grid-row {
    animation: rowFadeSlide .28s ease both;
}
.kpi-card {
    animation: softFloatIn .32s ease both;
}
.v-dialog .v-card {
    animation: modalRise .24s ease both;
}
@keyframes rowFadeSlide {
    from { opacity: 0; transform: translateY(8px); }
    to { opacity: 1; transform: translateY(0); }
}
@keyframes softFloatIn {
    from { opacity: 0; transform: translateY(10px) scale(.985); }
    to { opacity: 1; transform: translateY(0) scale(1); }
}
@keyframes modalRise {
    from { opacity: 0; transform: translateY(16px) scale(.985); }
    to { opacity: 1; transform: translateY(0) scale(1); }
}

/* Tooltips */
:global(.v-overlay__content.custom-tooltip) { background-color: #212121 !important; color: #ffffff !important; font-size: 11px !important; font-weight: 600 !important; border-radius: 4px; padding: 4px 8px; }

/* Animações e Extras */
.animate-pop { animation: popIn 0.5s cubic-bezier(0.175, 0.885, 0.32, 1.275) forwards; }
@keyframes popIn { 0% { transform: scale(0.5); opacity: 0; } 100% { transform: scale(1); opacity: 1; } }
.bg-black-20 { background: rgba(0,0,0,0.2); }
.bg-blue-grey-darken-4 { background-color: #263238 !important; }
.text-green-accent-2 { color: #69F0AE !important; }
.lh-1 { line-height: 1.2; }
.shadow-up { box-shadow: 0 -4px 10px rgba(0,0,0,0.05); }
.bg-dots { background-image: radial-gradient(#e0e0e0 1px, transparent 1px); background-size: 20px 20px; }
</style>
