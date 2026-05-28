<template>
  <v-dialog
    :model-value="show"
    @update:model-value="$emit('update:show', $event)"
    :width="mobile ? '100%' : '95vw'"
    :fullscreen="mobile"
    height="96vh"
    persistent
    class="billing-modal-ui font-sans"
    scrim="black opacity-80"
  >
    <v-card class="rounded-0 border-0 bg-white d-flex overflow-hidden fill-height" :class="mobile ? 'flex-column' : 'flex-row'">

      <div
        class="sidebar-summary d-flex flex-column border-r border-grey-lighten-2 bg-grey-lighten-5 transition-all"
        :style="mobile ? 'width: 100%; max-height: 35vh; flex-shrink: 0;' : 'width: 360px; height: 100%; flex-shrink: 0;'"
      >
          <div class="pa-4 pa-md-6 border-b border-grey-lighten-2 bg-white elevation-1 z-10 d-flex justify-space-between align-center">
              <div class="d-flex flex-column gap-1">
                  <div class="text-[10px] font-weight-black text-uppercase text-grey ls-1">Editando Pedido</div>
                  <div class="text-h5 text-md-h4 font-weight-black text-grey-darken-4 leading-none mb-1">
                      #{{ String(localOrder?.order_number || '0000').padStart(4, '0') }}
                  </div>
                  <div class="d-flex align-center gap-2 flex-wrap">
                      <v-chip size="x-small" :color="getStatusColor(localOrder?.financial_status)" variant="flat" class="font-weight-black text-uppercase rounded px-2 chip-3d">
                          {{ localOrder?.financial_status || 'Pendente' }}
                      </v-chip>
                      <span class="text-[11px] font-mono text-grey-darken-1 font-weight-bold bg-grey-lighten-4 px-2 py-1 rounded">
                        {{ formatDate(localOrder?.created_at) }}
                      </span>
                  </div>
              </div>
              <v-btn v-if="mobile" icon size="small" variant="text" @click="$emit('close')">
                  <v-icon>mdi-close</v-icon>
              </v-btn>
          </div>

          <div class="pa-4 pa-md-6 flex-grow-1 overflow-y-auto custom-scroll">
              <v-btn
                  block
                  color="indigo-darken-3"
                  variant="flat"
                  class="btn-3d font-weight-bold mb-6"
                  height="44"
                  prepend-icon="mdi-printer"
                  @click="printOrder"
              >
                  Imprimir Pedido
              </v-btn>

              <div v-if="attachedFiles.length > 0" class="mb-6">
                  <div class="text-[12px] font-weight-black text-uppercase text-grey-darken-3 mb-3 d-flex align-center gap-2">
                      <v-icon size="18" color="primary">mdi-paperclip</v-icon> Arquivos e Comprovantes
                  </div>
                  <div class="d-flex flex-row flex-md-column gap-2 overflow-x-auto pb-2 pb-md-0">
                      <div
                        v-for="(file, idx) in attachedFiles"
                        :key="idx"
                        class="attachment-card d-flex align-center pa-3 rounded-lg bg-white border-thin transition-all hover-elevation-1 group cursor-pointer flex-shrink-0"
                        style="min-width: 200px; max-width: 100%;"
                        @click="openAttachment(file.url)"
                      >
                          <div class="icon-box-xs bg-blue-lighten-5 text-blue-darken-2 rounded mr-3 d-flex align-center justify-center flex-shrink-0" style="width: 36px; height: 36px;">
                              <v-icon size="20">mdi-file-document-outline</v-icon>
                          </div>
                          <div class="d-flex flex-column overflow-hidden flex-grow-1">
                              <span class="text-[12px] font-weight-bold text-grey-darken-3 text-truncate" :title="file.label">
                                  {{ file.label || `Anexo ${idx + 1}` }}
                              </span>
                              <span class="text-[11px] text-grey font-mono font-weight-bold" v-if="file.value">
                                  {{ formatCurrency(file.value) }}
                              </span>
                          </div>
                      </div>
                  </div>
              </div>

              <div class="text-[12px] font-weight-black text-uppercase text-grey-darken-3 mb-3 d-flex align-center gap-2">
                  <v-icon size="18">mdi-scale-balance</v-icon> Resumo e Conferência
              </div>

              <v-card class="pa-0 rounded-lg border-thin bg-white mb-4 shadow-sm relative overflow-hidden" elevation="0">
                  <div class="absolute left-0 top-0 bottom-0" :class="hasDivergence ? 'bg-red' : 'bg-success'" style="width: 6px; position: absolute; height: 100%;"></div>

                  <div class="pa-4 pl-6">
                    <div class="d-flex justify-space-between align-center mb-2">
                        <span class="text-[11px] font-weight-bold text-grey-darken-1 text-uppercase">Total dos Itens</span>
                        <span class="text-subtitle-1 font-weight-black text-grey-darken-4 font-mono">{{ formatCurrency(localOrderHeader.total_value) }}</span>
                    </div>
                    <div class="d-flex justify-space-between align-center mb-2">
                        <span class="text-[11px] font-weight-bold text-grey-darken-1 text-uppercase">Total Parcelado</span>
                        <span class="text-subtitle-1 font-weight-black text-grey-darken-3 font-mono">{{ formatCurrency(totalInstallmentsValue) }}</span>
                    </div>
                    <v-divider class="my-3 border-dashed"></v-divider>
                    <div class="d-flex justify-space-between align-center" :class="hasDivergence ? 'text-red-darken-2' : 'text-success'">
                        <span class="text-[12px] font-weight-black text-uppercase">Diferença</span>
                        <span class="text-h5 font-weight-black font-mono">{{ formatCurrency(divergenceValue) }}</span>
                    </div>
                  </div>
              </v-card>

              <v-expand-transition>
                  <div v-if="hasDivergence" class="d-flex flex-column gap-2">
                      <v-btn size="large" color="red-darken-1" variant="flat" block class="btn-3d font-weight-black text-[12px]" prepend-icon="mdi-magic-staff" @click="distributeValuesEvenly">
                          Auto-Corrigir e Distribuir
                      </v-btn>
                  </div>
              </v-expand-transition>
          </div>

          <div class="pa-4 border-t border-grey-lighten-2 bg-white mt-auto d-flex flex-row flex-md-column gap-3 z-10 shadow-up">
               <v-btn
                  block
                  height="48"
                  color="success"
                  variant="flat"
                  class="btn-3d font-weight-black text-button flex-grow-1 text-white"
                  :loading="isSaving"
                  @click="saveAllChanges"
               >
                  <v-icon start size="20">mdi-content-save-check</v-icon> {{ mobile ? 'Salvar' : 'Salvar Alterações e Faturar' }}
              </v-btn>
              <v-btn
                  v-if="!mobile"
                  block
                  height="40"
                  variant="outlined"
                  color="grey-darken-2"
                  class="btn-3d font-weight-bold text-[12px]"
                  @click="$emit('close')"
                  :disabled="isSaving"
              >
                  Cancelar
              </v-btn>
          </div>
      </div>

      <div class="main-content flex-grow-1 d-flex flex-column relative bg-grey-lighten-3 overflow-hidden" :style="mobile ? 'height: 65vh;' : 'height: 100%;'">

          <div v-if="isLoadingData" class="absolute-center z-50 bg-white pa-8 rounded-xl border-thin shadow-lg text-center">
              <v-progress-circular indeterminate color="primary" size="48" width="4"></v-progress-circular>
              <div class="mt-4 text-caption font-weight-black text-uppercase ls-1 text-grey-darken-2">Carregando e Alinhando Dados...</div>
          </div>

          <div class="flex-grow-1 overflow-y-auto custom-scroll pb-16 px-4 px-md-8 pt-4 pt-md-6">

              <v-card class="mb-8 rounded-xl border-thin shadow-sm bg-white" elevation="0">
                  <div class="pa-4 pa-md-5 border-b d-flex justify-space-between align-center bg-white rounded-t-xl">
                      <div class="d-flex align-center gap-3">
                          <div class="section-number bg-grey-darken-4 text-white">01</div>
                          <div>
                              <h3 class="text-subtitle-1 font-weight-black text-uppercase text-grey-darken-4 ls-1">Dados Comerciais e Fiscais</h3>
                              <div v-if="!mobile" class="text-[12px] font-medium text-grey">Informações do responsável, cliente e endereços para faturamento.</div>
                          </div>
                      </div>
                      <v-btn icon size="small" variant="text" color="grey-darken-1" @click="openHelp('sec1')">
                          <v-icon size="24">mdi-help-circle-outline</v-icon>
                      </v-btn>
                  </div>
                  <div class="pa-4 pa-md-6">
                      <v-row dense class="row-gap-md">
                          <v-col cols="12" md="6">
                              <label class="input-label">Vendedor Responsável</label>
                              <v-autocomplete v-model="localOrderHeader.vendedor_id" :items="auxData.salespeople" item-title="full_name" item-value="id" variant="outlined" density="compact" hide-details class="ui-field bg-white" placeholder="Selecione o vendedor"></v-autocomplete>
                          </v-col>
                          <v-col cols="12" md="6">
                              <label class="input-label">Buscar / Trocar Cliente</label>
                              <v-autocomplete v-model="localOrderHeader.customer_id" :items="auxData.clients" item-title="nome" item-value="id" variant="outlined" density="compact" hide-details class="ui-field bg-blue-lighten-5 text-blue-darken-4 font-weight-bold" placeholder="Buscar no banco de dados..." no-data-text="Nada encontrado">
                                  <template v-slot:item="{ props, item }"><v-list-item v-bind="props" :subtitle="item.raw.cpf_cnpj || 'Sem Doc'"></v-list-item></template>
                              </v-autocomplete>
                          </v-col>

                          <v-col cols="12" class="mt-2">
                             <v-divider class="border-dashed"></v-divider>
                          </v-col>

                          <v-col cols="12" md="2">
                              <label class="input-label">Pessoa</label>
                              <v-select v-model="clientForm.tipo_pessoa" :items="['PF', 'PJ']" variant="outlined" density="compact" hide-details class="ui-field bg-grey-lighten-5"></v-select>
                          </v-col>
                          <v-col cols="12" md="5">
                              <label class="input-label">CPF/CNPJ (Busca Automática)</label>
                              <v-text-field v-model="clientForm.cpf_cnpj" variant="outlined" density="compact" hide-details class="ui-field bg-white font-mono font-weight-bold text-indigo-darken-4" append-inner-icon="mdi-magnify" @click:append-inner="consultarCnpjCpf" @keyup.enter="consultarCnpjCpf"></v-text-field>
                          </v-col>
                          <v-col cols="12" md="5">
                              <label class="input-label">Inscrição Estadual (IE)</label>
                              <v-text-field v-model="clientForm.ie" variant="outlined" density="compact" hide-details class="ui-field bg-white font-mono"></v-text-field>
                          </v-col>

                          <v-col cols="12" md="6">
                              <label class="input-label">Nome / Razão Social</label>
                              <v-text-field v-model="clientForm.nome" variant="outlined" density="compact" hide-details class="ui-field bg-white font-weight-bold"></v-text-field>
                          </v-col>
                          <v-col cols="12" md="6">
                              <label class="input-label">Nome Fantasia (Se PJ)</label>
                              <v-text-field v-model="clientForm.nome_fantasia" variant="outlined" density="compact" hide-details class="ui-field bg-white"></v-text-field>
                          </v-col>

                          <v-col cols="12" md="6">
                              <label class="input-label">Email de Contato</label>
                              <v-text-field v-model="clientForm.email" variant="outlined" density="compact" hide-details class="ui-field bg-white"></v-text-field>
                          </v-col>
                          <v-col cols="12" md="6">
                              <label class="input-label">Telefone / WhatsApp</label>
                              <v-text-field v-model="clientForm.telefone" variant="outlined" density="compact" hide-details class="ui-field bg-white font-weight-bold"></v-text-field>
                          </v-col>

                          <v-col cols="12" md="3">
                              <label class="input-label">CEP (Busca Auto)</label>
                              <v-text-field v-model="clientForm.cep" variant="outlined" density="compact" hide-details class="ui-field bg-white font-mono" append-inner-icon="mdi-magnify" @click:append-inner="consultarCep" @keyup.enter="consultarCep"></v-text-field>
                          </v-col>
                          <v-col cols="12" md="6">
                              <label class="input-label">Endereço (Rua/Av)</label>
                              <v-text-field v-model="clientForm.endereco" variant="outlined" density="compact" hide-details class="ui-field bg-white"></v-text-field>
                          </v-col>
                          <v-col cols="12" md="3">
                              <label class="input-label">Número</label>
                              <v-text-field v-model="clientForm.numero" variant="outlined" density="compact" hide-details class="ui-field bg-white"></v-text-field>
                          </v-col>
                          <v-col cols="12" md="4">
                              <label class="input-label">Bairro</label>
                              <v-text-field v-model="clientForm.bairro" variant="outlined" density="compact" hide-details class="ui-field bg-white"></v-text-field>
                          </v-col>
                          <v-col cols="12" md="5">
                              <label class="input-label">Cidade</label>
                              <v-text-field v-model="clientForm.cidade" variant="outlined" density="compact" hide-details class="ui-field bg-white"></v-text-field>
                          </v-col>
                          <v-col cols="12" md="3">
                              <label class="input-label">Estado (UF)</label>
                              <v-text-field v-model="clientForm.estado" variant="outlined" density="compact" hide-details class="ui-field bg-white text-uppercase" maxlength="2"></v-text-field>
                          </v-col>
                      </v-row>
                  </div>
              </v-card>

              <v-card class="mb-8 rounded-xl border-thin shadow-sm bg-indigo-lighten-5 overflow-hidden" elevation="0">
                  <div class="pa-4 pa-md-5 border-b d-flex justify-space-between align-center bg-white rounded-t-xl">
                      <div class="d-flex align-center gap-3">
                          <div class="section-number bg-indigo text-white">02</div>
                          <div>
                              <h3 class="text-subtitle-1 font-weight-black text-uppercase text-indigo-darken-4 ls-1">Itens e Metragens</h3>
                              <div v-if="!mobile" class="text-[12px] font-medium text-grey">Valide e altere as quantidades finais faturadas.</div>
                          </div>
                      </div>
                      <div class="d-flex align-center gap-3">
                          <v-btn color="indigo-darken-3" variant="flat" size="small" class="btn-3d font-weight-bold px-4" @click="openAddItemModal" prepend-icon="mdi-plus">
                              {{ mobile ? 'Add' : 'Adicionar Item' }}
                          </v-btn>
                          <v-btn icon size="small" variant="text" color="indigo-darken-2" @click="openHelp('sec2')">
                              <v-icon size="24">mdi-help-circle-outline</v-icon>
                          </v-btn>
                      </div>
                  </div>

                  <div class="bg-white table-responsive rounded-b-xl border-t border-indigo-lighten-4">
                      <div class="grid-header grid-items-layout bg-indigo-lighten-5 border-b border-indigo-lighten-4">
                          <div class="cell header-text text-indigo-darken-4">Produto Base</div>
                          <div class="cell header-text text-indigo-darken-4">Ref. Estampa</div>
                          <div class="cell header-text text-indigo-darken-4">Observação do Item</div>
                          <div class="cell center header-text text-indigo-darken-4">Metragem Final</div>
                          <div class="cell center header-text text-indigo-darken-4">Unitário (R$)</div>
                          <div class="cell right header-text text-indigo-darken-4">Total Faturado</div>
                          <div class="cell center header-text text-indigo-darken-4">Ação</div>
                      </div>

                      <div v-for="(item, i) in localItems" :key="i" class="grid-row grid-items-layout hover-bg-row group transition-colors" :class="{'opacity-40 bg-grey-lighten-4': item.excluded_from_invoice}">
                          <div class="cell">
                              <v-autocomplete v-model="item.fabric_type" :items="auxData.products" item-title="name" item-value="name" variant="plain" density="compact" hide-details class="clean-input font-weight-bold text-[13px] text-indigo-darken-4 w-100" @update:model-value="(val) => onItemSelect(item, val)" :disabled="item.excluded_from_invoice"></v-autocomplete>
                          </div>
                          <div class="cell">
                              <input v-model="item.stamp_ref" class="clean-input w-100 text-[13px] font-weight-medium" placeholder="-" :disabled="item.excluded_from_invoice" />
                          </div>
                          <div class="cell">
                              <input v-model="item.notes" class="clean-input w-100 text-[13px] text-grey-darken-2" placeholder="Sem obs" :disabled="item.excluded_from_invoice" />
                              <v-chip v-if="!item.id && item.design_stage" size="x-small" color="orange" variant="flat" class="ml-2 font-weight-black text-[10px] h-16 rounded-sm chip-3d">NOVO</v-chip>
                              <v-chip v-if="item.excluded_from_invoice" size="x-small" color="grey" variant="flat" class="ml-2 font-weight-black text-[10px] h-16 rounded-sm chip-3d">OCULTO</v-chip>
                          </div>

                          <div class="cell center">
                              <div class="d-flex align-center border border-grey-lighten-1 rounded bg-white px-2 py-0 w-100 transition-all hover-border-primary" style="height: 36px;">
                                  <input type="number" v-model.number="item.display_quantity" class="clean-input w-100 text-center font-weight-black text-[14px] text-primary" step="0.1" @input="recalcItem(item)" :disabled="item.excluded_from_invoice" />
                                  <span class="text-[11px] text-grey ml-1 font-weight-black flex-shrink-0">{{ item.is_kg ? 'KG' : 'm' }}</span>
                              </div>
                          </div>
                          <div class="cell center">
                              <div class="border border-grey-lighten-1 rounded bg-white px-2 py-0 w-100 transition-all hover-border-primary" style="height: 36px;">
                                <input type="number" v-model.number="item.unit_price" class="clean-input w-100 text-center text-grey-darken-4 font-weight-bold text-[14px]" step="0.01" @input="recalcItem(item)" :disabled="item.excluded_from_invoice" />
                              </div>
                          </div>
                          <div class="cell right">
                              <span class="font-mono font-weight-black text-[14px] text-success-darken-1" :class="{'text-decoration-line-through text-grey': item.excluded_from_invoice}">
                                  {{ formatCurrency(item.total_value_items) }}
                              </span>
                          </div>

                          <div class="cell center gap-2">
                              <v-btn icon size="small" variant="flat" class="action-btn btn-3d" :class="item.excluded_from_invoice ? 'bg-grey-darken-1' : 'bg-blue-darken-2'" @click="toggleItemExclusion(i)">
                                  <v-icon size="16">{{ item.excluded_from_invoice ? 'mdi-eye-off' : 'mdi-eye' }}</v-icon>
                                  <v-tooltip activator="parent" location="top" content-class="bg-grey-darken-4 text-white font-weight-bold text-caption">{{ item.excluded_from_invoice ? 'Incluir no Romaneio' : 'Ocultar do Romaneio' }}</v-tooltip>
                              </v-btn>
                              <v-btn icon size="small" variant="flat" class="action-btn action-del btn-3d" @click="removeItem(i)">
                                  <v-icon size="16">mdi-trash-can-outline</v-icon>
                                  <v-tooltip activator="parent" location="top" content-class="bg-grey-darken-4 text-white font-weight-bold text-caption">Excluir Item</v-tooltip>
                              </v-btn>
                          </div>
                      </div>
                  </div>
              </v-card>

              <v-card class="mb-8 rounded-xl border-thin shadow-sm bg-green-lighten-5 overflow-hidden" elevation="0">
                  <div class="pa-4 pa-md-5 border-b d-flex justify-space-between align-center bg-white rounded-t-xl flex-wrap gap-3">
                      <div class="d-flex align-center gap-3">
                          <div class="section-number bg-green-darken-2 text-white">03</div>
                          <div>
                              <h3 class="text-subtitle-1 font-weight-black text-uppercase text-green-darken-4 ls-1">Organização Financeira</h3>
                              <div v-if="!mobile" class="text-[12px] font-medium text-grey">Controle de caixa, plano de contas e estruturação de boletos.</div>
                          </div>
                      </div>

                      <div class="d-flex align-center gap-3">
                          <div class="d-flex align-center gap-2 bg-grey-lighten-5 border-thin rounded pa-1">
                              <div class="d-flex align-center bg-white border-thin rounded px-2" style="height: 36px;">
                                 <span class="text-[11px] font-weight-bold text-grey-darken-1 mr-2 text-uppercase">Intervalo (Dias)</span>
                                 <input type="number" v-model.number="daysGap" class="clean-input text-center font-weight-black text-primary text-[14px]" style="width: 45px;" min="1" max="365">
                              </div>
                              <v-btn color="green-darken-3" variant="flat" size="small" height="36" class="btn-3d font-weight-bold px-4" @click="addInstallment" prepend-icon="mdi-cash-plus">
                                  {{ mobile ? 'Nova' : 'Nova Parcela' }}
                              </v-btn>
                          </div>
                          <v-btn icon size="small" variant="text" color="green-darken-3" @click="openHelp('sec3')">
                              <v-icon size="24">mdi-help-circle-outline</v-icon>
                          </v-btn>
                      </div>
                  </div>

                  <div class="bg-white table-responsive rounded-b-xl border-t border-green-lighten-4">
                        <div class="grid-header grid-payments-layout bg-grey-darken-4 border-none shadow-sm z-20">
                           <div class="cell center header-text text-white border-white-10">Status</div>
                           <div class="cell center header-text text-white border-white-10">Vencimento</div>
                           <div class="cell center header-text text-white border-white-10">Competência</div>
                           <div class="cell header-text text-white border-white-10">Descrição (Dinâmica)</div>
                           <div class="cell header-text text-white border-white-10">Plano Contas</div>
                           <div class="cell header-text text-white border-white-10">Banco / Destino</div>
                           <div class="cell header-text text-white border-white-10">Forma Pagto</div>
                           <div class="cell right header-text text-white border-white-10">Valor (R$)</div>
                           <div class="cell center header-text text-white border-none">Ações</div>
                        </div>

                        <div v-if="installments.length === 0" class="pa-10 text-center text-grey-darken-1 bg-white">
                            <v-icon size="48" class="mb-3 opacity-20 text-green-darken-3">mdi-cash-remove</v-icon>
                            <div class="text-[13px] font-weight-bold">O cronograma de recebimentos está vazio.</div>
                        </div>

                        <div v-for="(inst, i) in installments" :key="i" class="grid-row grid-payments-layout hover-bg-row group transition-colors bg-white">
                            <div class="cell center" style="position: relative;">
                                <v-menu location="bottom center" :close-on-content-click="true">
                                    <template v-slot:activator="{ props }">
                                        <v-badge v-if="inst.is_virtual" color="error" content="NÃO SALVO NO BANCO" floating offset-x="-30" offset-y="-5">
                                            <button v-bind="props" class="w-100 py-1 rounded font-weight-black text-[11px] text-uppercase transition-colors border chip-3d" :class="getStatusColorClass(inst.status)" style="height: 36px; min-width: 80px;">
                                                {{ inst.status === 'pago' ? 'PAGO' : 'ABERTO' }}
                                                <v-icon size="14" class="ml-1">mdi-chevron-down</v-icon>
                                            </button>
                                        </v-badge>
                                        <button v-else v-bind="props" class="w-100 py-1 rounded font-weight-black text-[11px] text-uppercase transition-colors border chip-3d" :class="getStatusColorClass(inst.status)" style="height: 36px; min-width: 80px;">
                                            {{ inst.status === 'pago' ? 'PAGO' : 'ABERTO' }}
                                            <v-icon size="14" class="ml-1">mdi-chevron-down</v-icon>
                                        </button>
                                    </template>
                                    <v-list density="compact" class="rounded py-0 border-thin elevation-2">
                                        <v-list-item v-for="s in statusOptions" :key="s.value" :value="s.value" @click="updateStatus(inst, s.value)" class="min-h-32 hover-bg-grey-lighten-5">
                                            <v-list-item-title class="text-[12px] font-weight-black uppercase">{{ s.label }}</v-list-item-title>
                                        </v-list-item>
                                    </v-list>
                                </v-menu>
                            </div>

                            <div class="cell center">
                                <input type="date" v-model="inst.due_date" class="clean-input w-100 text-center font-mono font-weight-bold text-[13px] border border-grey-lighten-1 rounded bg-white px-2 hover-border-primary transition-colors" style="height: 38px;"/>
                            </div>
                            <div class="cell center">
                                <input type="date" v-model="inst.competence_date" class="clean-input w-100 text-center font-mono font-weight-bold text-[13px] border border-grey-lighten-1 rounded bg-white px-2 hover-border-primary transition-colors" style="height: 38px;"/>
                            </div>

                            <div class="cell">
                                <input v-model="inst.description" class="clean-input w-100 text-[13px] font-weight-bold text-grey-darken-3 border border-grey-lighten-1 rounded bg-white px-2 hover-border-primary transition-colors" placeholder="Descrição da parcela..." style="height: 38px;"/>
                            </div>

                            <div class="cell">
                                <select v-model="inst.chart_of_accounts_id" class="clean-input w-100 text-[12px] font-weight-bold text-indigo-darken-4 border border-grey-lighten-1 rounded bg-indigo-lighten-5 px-2 hover-border-primary transition-colors text-truncate" style="height: 38px; cursor: pointer;">
                                    <option :value="null" disabled>Plano de Contas</option>
                                    <option v-for="acc in auxData.chartOfAccounts" :key="acc.id" :value="acc.id">{{ acc.name }}</option>
                                </select>
                            </div>

                            <div class="cell">
                                <select v-model="inst.bank_account_id" class="clean-input w-100 text-[12px] font-weight-bold border border-grey-lighten-1 rounded bg-white px-2 hover-border-primary transition-colors text-truncate" style="height: 38px; cursor: pointer;">
                                    <option :value="null" disabled>Selecione a Conta</option>
                                    <option v-for="acc in auxData.bankAccounts" :key="acc.id" :value="acc.id">{{ acc.name }}</option>
                                </select>
                            </div>
                            <div class="cell">
                                <select v-model="inst.payment_method_id" class="clean-input w-100 text-[12px] font-weight-bold border border-grey-lighten-1 rounded bg-white px-2 hover-border-primary transition-colors text-truncate" style="height: 38px; cursor: pointer;">
                                    <option :value="null" disabled>Meio de Pagamento</option>
                                    <option v-for="pm in auxData.paymentMethods" :key="pm.id" :value="pm.id">{{ pm.name }}</option>
                                </select>
                            </div>

                            <div class="cell right">
                                <div class="d-flex align-center border border-grey-lighten-1 rounded bg-white px-2 w-100 transition-all hover-border-primary" style="height: 38px;">
                                   <span class="text-[12px] font-weight-bold opacity-60 mr-1">R$</span>
                                   <input type="number" v-model.number="inst.value" step="0.01" class="clean-input w-100 text-right font-mono font-weight-black text-[15px] bg-transparent" :class="inst.status === 'pago' ? 'text-green-darken-3' : 'text-grey-darken-4'" />
                                </div>
                            </div>

                            <div class="cell center">
                                <div class="d-flex justify-center w-100 gap-2">
                                    <v-btn icon size="small" variant="flat" class="action-btn action-clone btn-3d" @click="cloneInstallment(i)">
                                        <v-icon size="16">mdi-content-copy</v-icon>
                                        <v-tooltip activator="parent" location="top" content-class="bg-grey-darken-4 text-white font-weight-bold text-caption">Duplicar Parcela</v-tooltip>
                                    </v-btn>
                                    <v-btn icon size="small" variant="flat" class="action-btn action-del btn-3d" @click="removeInstallment(i)">
                                        <v-icon size="16">mdi-close-circle-outline</v-icon>
                                        <v-tooltip activator="parent" location="top" content-class="bg-grey-darken-4 text-white font-weight-bold text-caption">Excluir Parcela</v-tooltip>
                                    </v-btn>
                                </div>
                            </div>
                        </div>
                    </div>
              </v-card>

              <v-card class="mb-6 rounded-xl border-thin shadow-sm bg-amber-lighten-5 overflow-hidden" elevation="0">
                  <div class="pa-4 pa-md-5 border-b bg-white d-flex justify-space-between align-center rounded-t-xl">
                      <div class="d-flex align-center gap-3">
                          <div class="section-number bg-amber-darken-3 text-white">04</div>
                          <h3 class="text-subtitle-1 font-weight-black text-uppercase text-amber-darken-4 ls-1">Observações do Pedido / NF</h3>
                      </div>
                      <v-btn icon size="small" variant="text" color="amber-darken-3" @click="openHelp('sec4')">
                          <v-icon size="24">mdi-help-circle-outline</v-icon>
                      </v-btn>
                  </div>
                  <div class="bg-amber-lighten-5 pa-4 pa-md-6 border-b border-amber-lighten-4 rounded-b-xl">
                      <textarea
                        v-model="localOrderHeader.notes"
                        class="clean-textarea w-100 text-[14px] font-weight-medium text-grey-darken-4 bg-white border-thin rounded-lg pa-4 shadow-sm"
                        rows="4"
                        placeholder="Instruções de entrega, endereços alternativos, dados fiscais para faturamento ou detalhes críticos para a produção..."
                      ></textarea>
                  </div>
              </v-card>

          </div>

      </div>
    </v-card>

    <v-dialog v-model="helpModal.show" max-width="500">
        <v-card class="rounded-xl border-thin shadow-lg">
            <div class="pa-5 border-b bg-grey-lighten-5 d-flex align-center gap-3 text-primary">
                <v-icon size="28">mdi-information</v-icon>
                <h3 class="text-subtitle-1 font-weight-black text-uppercase ls-1">{{ helpModal.title }}</h3>
            </div>
            <div class="pa-6 text-body-2 text-grey-darken-3 font-weight-medium" style="white-space: pre-wrap; line-height: 1.6;">
                {{ helpModal.text }}
            </div>
            <div class="pa-4 border-t d-flex justify-end bg-white">
                <v-btn color="primary" variant="flat" class="btn-3d px-6 font-weight-bold" @click="helpModal.show = false">Entendi</v-btn>
            </div>
        </v-card>
    </v-dialog>

    <v-dialog v-model="showAddItemModal" max-width="700px" persistent :fullscreen="mobile">
        <v-card class="rounded-lg overflow-hidden border-thin elevation-4">
            <div class="px-5 py-4 border-b bg-grey-lighten-5 d-flex justify-space-between align-center">
               <div class="d-flex align-center gap-3">
                  <div class="icon-box-sm rounded d-flex align-center justify-center bg-indigo-darken-3 text-white" style="width: 32px; height: 32px;">
                     <v-icon size="20">mdi-plus</v-icon>
                  </div>
                  <div class="lh-1">
                     <div class="text-[10px] font-weight-black uppercase opacity-60 letter-spacing-1 mb-1">Catálogo</div>
                     <h2 class="text-subtitle-1 font-weight-black">Adicionar Produto</h2>
                  </div>
               </div>
               <v-btn icon size="small" variant="text" @click="showAddItemModal = false"><v-icon>mdi-close</v-icon></v-btn>
            </div>
            <v-card-text class="pa-4 pa-md-6" style="max-height: 80vh; overflow-y: auto;">
                <div class="stamp-hero-container mb-6 rounded-lg relative overflow-hidden transition-all group border-thin cursor-pointer"
                     :class="newItemForm.stamp_image_url ? 'has-image' : 'bg-grey-lighten-4 border-dashed hover-border-primary'"
                     style="min-height: 180px;"
                     @click="showStampCatalog = true"
                >
                   <v-img v-if="newItemForm.stamp_image_url" :src="newItemForm.stamp_image_url" height="180" cover>
                      <div class="absolute inset-0 bg-gradient-to-t from-black/80 via-transparent to-transparent opacity-90"></div>
                      <div class="absolute bottom-0 left-0 p-4 w-100 z-10">
                          <div class="text-white text-subtitle-2 font-weight-black text-truncate">{{ newItemForm.stamp_ref }}</div>
                      </div>
                      <div class="absolute top-3 right-3 d-flex gap-2 z-10">
                         <v-btn icon size="x-small" color="white" variant="flat" class="rounded"><v-icon size="16">mdi-refresh</v-icon></v-btn>
                      </div>
                   </v-img>
                   <div v-else class="d-flex flex-column align-center justify-center h-100 py-8">
                      <v-icon size="40" color="grey" class="mb-2">mdi-image-search-outline</v-icon>
                      <div class="text-subtitle-2 font-weight-black text-grey-darken-1 text-uppercase">Selecionar Estampa / Referência</div>
                      <div class="text-caption text-grey">Clique para abrir o catálogo</div>
                   </div>
                </div>
                <v-form ref="itemFormRef">
                   <v-row dense class="row-gap-md">
                      <v-col cols="12" sm="6">
                         <label class="input-label">Produto (Base)</label>
                         <v-autocomplete v-model="newItemForm.fabric_type" :items="auxData.products" item-title="name" item-value="name" placeholder="Selecione..." variant="outlined" density="compact" :rules="[rules.required]" hide-details="auto" class="ui-field" @update:model-value="onNewItemSelect"></v-autocomplete>
                      </v-col>
                      <v-col cols="6" sm="3">
                         <label class="input-label">Quantidade ({{ selectedProductUnit }})</label>
                         <v-text-field v-model.number="newItemForm.quantity" type="number" variant="outlined" density="compact" :rules="[rules.required, rules.positive]" :disabled="!newItemForm.fabric_type" hide-details="auto" class="ui-field font-weight-bold"></v-text-field>
                         <div v-if="newItemForm.quantity_meters" class="mt-1 text-[10px] font-weight-bold text-indigo">Total: {{ newItemForm.quantity_meters }}m</div>
                      </v-col>
                      <v-col cols="6" sm="3">
                         <label class="input-label">Preço Unitário</label>
                         <v-text-field v-model.number="newItemForm.unit_price" type="number" variant="outlined" density="compact" prefix="R$" hide-details="auto" class="ui-field font-weight-bold"></v-text-field>
                      </v-col>
                      <v-col cols="12">
                         <label class="input-label">Observações Específicas</label>
                         <v-textarea v-model="newItemForm.notes" placeholder="Detalhes para produção..." variant="outlined" rows="2" density="compact" hide-details class="ui-field"></v-textarea>
                      </v-col>
                      <v-col cols="12" class="mt-2">
                          <label class="input-label text-indigo">Tag de Design (Kanban)</label>
                          <v-radio-group v-model="newItemForm.design_stage" inline hide-details density="compact">
                              <v-radio label="Alteração" value="Alteração" color="orange"></v-radio>
                              <v-radio label="Finalização" value="Finalização" color="teal"></v-radio>
                          </v-radio-group>
                      </v-col>
                   </v-row>
                </v-form>
            </v-card-text>
            <v-card-actions class="pa-4 border-t bg-grey-lighten-5 justify-end gap-2">
                <v-btn variant="outlined" color="grey-darken-2" height="40" class="btn-rect px-4 btn-3d font-weight-bold" @click="showAddItemModal = false">Cancelar</v-btn>
                <v-btn color="indigo-darken-3" variant="flat" height="40" class="btn-rect px-6 font-weight-black btn-3d" @click="confirmAddItem" :disabled="!isNewItemFormValid">
                    <v-icon start>mdi-check</v-icon> {{ mobile ? 'Add' : 'Adicionar Item' }}
                </v-btn>
            </v-card-actions>
        </v-card>
    </v-dialog>

    <StampCatalogModal
       :show="showStampCatalog"
       @close="showStampCatalog = false"
       @stamp-selected="handleStampSelection"
    />

  </v-dialog>
</template>

<script setup lang="ts">
import { ref, computed, watch, reactive, onMounted, defineAsyncComponent } from 'vue';
import { useAppStore } from '@/stores/app';
import { supabase } from '@/api/supabase';
import { format, parseISO, addDays } from 'date-fns';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import { useDisplay } from 'vuetify';
import axios from 'axios';

const StampCatalogModal = defineAsyncComponent(() => import('@/components/StampCatalogModal.vue'));

const props = defineProps<{
    show: boolean;
    order: any;
}>();

const emit = defineEmits(['update:show', 'close', 'refresh']);
const appStore = useAppStore();
const { mobile } = useDisplay();

const isSaving = ref(false);
const isLoadingData = ref(false);
const showAddItemModal = ref(false);
const showStampCatalog = ref(false);
const tempMeters = ref<number | null>(null);

const daysGap = ref(30);

const localOrder = ref<any>(null);
const localOrderHeader = reactive({
    customer_id: null as string | null,
    vendedor_id: null as string | null,
    total_value: 0,
    notes: ''
});
const localItems = ref<any[]>([]);
const itemsToDelete = ref<string[]>([]);
const installments = ref<any[]>([]);
const attachedFiles = ref<any[]>([]);

// FORM DO NOVO ITEM
const newItemForm = reactive({
    fabric_type: '',
    quantity: 0,
    quantity_meters: 0,
    unit_price: 0,
    stamp_ref: '',
    stamp_ref_id: '',
    stamp_image_url: '',
    notes: '',
    gestao_click_product_id: '',
    unit_of_measure: 'm',
    rendimento: 0,
    design_stage: 'Alteração'
});

const auxData = reactive({
    bankAccounts: [] as any[],
    costCenters: [] as any[],
    chartOfAccounts: [] as any[],
    paymentMethods: [] as any[],
    clients: [] as any[],
    salespeople: [] as any[],
    products: [] as any[],
    companies: [] as any[],
    defaultCompanyId: null as string | null,
    defaultPaymentMethodId: null as string | null
});

const clientForm = reactive({
    id: null as string | null,
    tipo_pessoa: 'PF',
    nome: '',
    nome_fantasia: '',
    cpf_cnpj: '',
    ie: '',
    email: '',
    telefone: '',
    cep: '',
    endereco: '',
    numero: '',
    bairro: '',
    cidade: '',
    estado: '',
    situacao: 'Ativo'
});

const statusOptions = [
    { label: 'Aberto', value: 'em_aberto' },
    { label: 'Pago', value: 'pago' },
    { label: 'Atrasado', value: 'atrasado' },
    { label: 'Canc.', value: 'cancelado' }
];

const rules = { required: (v: any) => !!v || 'Obrigatório.', positive: (v: number | null) => (v != null && v > 0) || '> 0' };

const helpModal = reactive({
    show: false,
    title: '',
    text: ''
});

const openHelp = (section: string) => {
    if (section === 'sec1') {
        helpModal.title = '01. Dados Comerciais e Fiscais';
        helpModal.text = 'Aqui você define quem é o cliente e o vendedor responsável.\n\nOs dados fiscais (CPF/CNPJ, Inscrição Estadual) e de endereço (CEP, Rua, Bairro, etc.) são utilizados na hora de emitir a Nota Fiscal (NFe ou NFCe).\n\nCampos Obrigatórios:\n- Vendedor Responsável\n- Cliente (Busca no banco)';
    } else if (section === 'sec2') {
        helpModal.title = '02. Itens e Metragens';
        helpModal.text = 'Revise ou adicione os itens que serão faturados neste pedido.\n\nVocê pode alterar a quantidade final produzida (Metragem Final) e o valor unitário. O botão "olho" permite ocultar um item do romaneio final sem excluí-lo do banco de dados (útil para testes ou refações).\n\nCampos Obrigatórios:\n- Produto Base\n- Metragem Final\n- Valor Unitário';
    } else if (section === 'sec3') {
        helpModal.title = '03. Parcelas e Financeiro';
        helpModal.text = 'Organize como o cliente pagará o pedido.\n\nO valor total das parcelas deve bater EXATAMENTE com o total dos itens ativos.\nAs parcelas de "Sinal" que já foram pagas aparecerão aqui, as demais ficarão como "Em Aberto" até a baixa final.\n\nCampos Obrigatórios (para cada parcela):\n- Data de Vencimento\n- Competência\n- Plano de Contas\n- Conta Bancária\n- Forma de Pagamento\n- Valor';
    } else if (section === 'sec4') {
        helpModal.title = '04. Observações';
        helpModal.text = 'Adicione qualquer observação extra, instrução de entrega ou detalhe crítico.\n\nEste texto será salvo no pedido e poderá ser impresso no recibo ou na nota de produção.';
    }
    helpModal.show = true;
};

// --- FUNÇÕES DE SEGURANÇA (SANITY CHECK) ---
const sanitizeUUID = (val: any) => {
    if (!val) return null;
    const str = String(val).trim();
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    return uuidRegex.test(str) ? str : null;
};

const sanitizeValue = (val: any) => {
    if (val === null || val === undefined || String(val).trim() === '' || val === 'null') return null;
    return String(val);
};

// --- HELPERS ---
const getStatusColor = (status: string) => {
    if (!status) return 'grey';
    const s = status.toLowerCase();
    if (s.includes('pago') || s.includes('faturado') || s === 'completed') return 'success';
    if (s.includes('parcial')) return 'warning';
    if (s.includes('cancel')) return 'error';
    return 'grey-darken-2';
};

const getStatusColorClass = (status: string) => {
    if (status === 'pago') return 'text-success bg-green-lighten-5 border-success';
    if (status === 'atrasado') return 'text-error bg-red-lighten-5 border-error';
    if (status === 'cancelado') return 'text-grey bg-grey-lighten-4 border-grey';
    return 'text-orange-darken-3 bg-white border-orange-lighten-4';
};

const formatDate = (d: any) => { if (!d) return '-'; try { return format(parseISO(d), 'dd/MM/yy HH:mm'); } catch { return d; } };
const formatCurrency = (v: number) => new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(v || 0);

// --- COMPUTEDS ---
const selectedProduct = computed(() => auxData.products.find(p => p.name === newItemForm.fabric_type));
const selectedProductUnit = computed(() => (selectedProduct.value?.unit_of_measure || selectedProduct.value?.unidade || 'm').toLowerCase());
const selectedProductRendimento = computed(() => parseFloat(selectedProduct.value?.rendimento || '0'));
const isNewItemFormValid = computed(() => !!newItemForm.fabric_type && !!newItemForm.quantity && newItemForm.quantity > 0 && !!newItemForm.stamp_ref);

const totalInstallmentsValue = computed(() => installments.value.reduce((acc, i) => acc + (Number(i.value) || 0), 0));
const divergenceValue = computed(() => localOrderHeader.total_value - totalInstallmentsValue.value);
const hasDivergence = computed(() => Math.abs(divergenceValue.value) > 0.05);

// --- APIs PUBLICAS (BRASILAPI E VIACEP) ---
const consultarCnpjCpf = async () => {
    const doc = clientForm.cpf_cnpj.replace(/\D/g, '');
    if (doc.length === 14) {
        try {
            appStore.showSnackbar('Consultando CNPJ...', 'info');
            const { data } = await axios.get(`https://brasilapi.com.br/api/cnpj/v1/${doc}`);
            clientForm.nome = data.razao_social || '';
            clientForm.nome_fantasia = data.nome_fantasia || '';
            clientForm.cep = data.cep || '';
            clientForm.endereco = `${data.logradouro || ''} ${data.complemento || ''}`.trim();
            clientForm.numero = data.numero || '';
            clientForm.bairro = data.bairro || '';
            clientForm.cidade = data.municipio || '';
            clientForm.estado = data.uf || '';
            clientForm.tipo_pessoa = 'PJ';
            appStore.showSnackbar('Dados da empresa carregados.', 'success');
        } catch(e) { appStore.showSnackbar('CNPJ não encontrado.', 'error'); }
    } else if (doc.length === 11) {
        clientForm.tipo_pessoa = 'PF';
    }
};

const consultarCep = async () => {
    const cep = clientForm.cep.replace(/\D/g, '');
    if (cep.length === 8) {
        try {
            appStore.showSnackbar('Consultando CEP...', 'info');
            const { data } = await axios.get(`https://viacep.com.br/ws/${cep}/json/`);
            if(!data.erro) {
                clientForm.endereco = data.logradouro || '';
                clientForm.bairro = data.bairro || '';
                clientForm.cidade = data.localidade || '';
                clientForm.estado = data.uf || '';
                appStore.showSnackbar('Endereço preenchido.', 'success');
            } else {
                appStore.showSnackbar('CEP não encontrado.', 'error');
            }
        } catch(e) { appStore.showSnackbar('Erro ao buscar CEP.', 'error'); }
    }
};

// --- LÓGICA NOVO ITEM ---
const openAddItemModal = () => { Object.assign(newItemForm, { fabric_type: '', quantity: 0, quantity_meters: 0, unit_price: 0, stamp_ref: '', stamp_ref_id: '', stamp_image_url: '', notes: '', gestao_click_product_id: '', unit_of_measure: 'm', rendimento: 0, design_stage: 'Alteração' }); tempMeters.value = null; showAddItemModal.value = true; };
const onNewItemSelect = (val: string) => { const prod = auxData.products.find(p => p.name === val); if(prod) { newItemForm.gestao_click_product_id = prod.code; newItemForm.unit_price = parseFloat(prod.valor_venda || '0'); newItemForm.unit_of_measure = (prod.unidade || 'm').toLowerCase(); newItemForm.rendimento = parseFloat(prod.rendimento || '0'); } };
const handleStampSelection = (stamp: any) => { if (!stamp) return; newItemForm.stamp_ref_id = stamp.id; newItemForm.stamp_ref = stamp.nome; newItemForm.stamp_image_url = stamp.image_url || stamp.imagem_url; showStampCatalog.value = false; };
watch(tempMeters, (v) => { if (selectedProductUnit.value === 'kg' && selectedProductRendimento.value && v) newItemForm.quantity = parseFloat((v / selectedProductRendimento.value).toFixed(2)); });
watch(() => newItemForm.quantity, (v) => { if (selectedProductUnit.value === 'kg' && selectedProductRendimento.value && v) newItemForm.quantity_meters = parseFloat((v * selectedProductRendimento.value).toFixed(2)); else newItemForm.quantity_meters = v; });

const confirmAddItem = () => {
    const isKg = newItemForm.unit_of_measure === 'kg';
    const displayQty = newItemForm.quantity;
    const totalVal = (Number(displayQty) * Number(newItemForm.unit_price)).toFixed(2);

    localItems.value.push({
        fabric_type: newItemForm.fabric_type,
        quantity_meters: Number(newItemForm.quantity_meters),
        quantity_unit: isKg ? Number(newItemForm.quantity) : null,
        display_quantity: Number(displayQty),
        unit_price: Number(newItemForm.unit_price),
        total_value_items: totalVal,
        is_kg: isKg,
        unit_of_measure: newItemForm.unit_of_measure,
        rendimento: newItemForm.rendimento,
        stamp_ref: newItemForm.stamp_ref,
        stamp_image_url: newItemForm.stamp_image_url,
        notes: newItemForm.notes,
        gestao_click_product_id: newItemForm.gestao_click_product_id,
        order_id: localOrder.value?.id,
        design_tag: newItemForm.design_stage,
        excluded_from_invoice: false,
        id: undefined
    });
    recalcTotal();
    showAddItemModal.value = false;
};

// --- ATUALIZAR DESCRIÇÃO DINAMICAMENTE ---
const updateInstallmentDescriptions = () => {
    const orderNumber = localOrder.value?.order_number || 'S/N';
    const total = installments.value.length;

    installments.value.forEach((inst, index) => {
        const isSignal = String(inst.description || '').toLowerCase().includes('sinal') || inst.is_signal || inst.status === 'pago';
        let baseName = 'Parcela';

        if (isSignal) {
             baseName = 'Sinal';
        } else if (index === total - 1 && !isSignal) {
             baseName = 'Restante';
        }

        inst.description = `${baseName} ${index + 1}/${total} - Pedido #${orderNumber}`;
    });
};

// Adivinhação inteligente de banco (Sicredi vs Cora)
const guessBankIdFn = (orderData: any) => {
    if (!auxData.bankAccounts.length) return null;
    const oStr = JSON.stringify(orderData || {}).toLowerCase();

    const isCora = oStr.includes('sem nota') || oStr.includes('cora') || oStr.includes('cajuia');
    const isSicredi = oStr.includes('com nota') || oStr.includes('sicredi');

    let target = isCora ? 'cora' : (isSicredi ? 'sicredi' : 'levi');
    if (!isCora && !isSicredi) target = 'sicredi';

    let b = auxData.bankAccounts.find(x => x.name.toLowerCase().includes(target));
    if (!b) b = auxData.bankAccounts.find(x => x.name.toLowerCase().includes(target === 'cora' ? 'sicredi' : 'cora'));

    return b ? b.id : auxData.bankAccounts[0]?.id;
};

// --- DATA FETCH ---
const fetchAuxiliaryData = async () => {
    try {
        const [banks, costs, charts, methods, clients, profiles, stock, companiesRes] = await Promise.all([
            supabase.from('finance_accounts').select('id, name').eq('is_active', true),
            supabase.from('finance_cost_centers').select('id, name'),
            supabase.from('finance_chart_of_accounts').select('id, name').eq('type', 'Receita'),
            supabase.from('finance_payment_methods').select('id, name'),
            supabase.from('customers_mj').select('id, nome, cpf, cnpj').limit(1000).order('nome'),
            supabase.from('profiles').select('id, full_name'),
            supabase.from('stock').select('*').eq('verification', true),
            supabase.from('companies').select('id, trade_name')
        ]);

        auxData.bankAccounts = banks.data || [];
        auxData.costCenters = costs.data || [];
        auxData.chartOfAccounts = charts.data || [];
        auxData.paymentMethods = methods.data || [];
        auxData.clients = (clients.data || []).map(c => ({ id: c.id, nome: c.nome, cpf_cnpj: c.cnpj || c.cpf || '-' }));
        auxData.salespeople = profiles.data || [];
        auxData.companies = companiesRes.data || [];

        // CATCH DEFAULT MR JACKY
        const mrJacky = auxData.companies.find(c => c.trade_name.toLowerCase().includes('jacky'));
        auxData.defaultCompanyId = mrJacky ? mrJacky.id : (auxData.companies[0]?.id || null);

        // CATCH DEFAULT FORMA PAGAMENTO ("Não Informado")
        let naoInformado = auxData.paymentMethods.find(p => p.name.toLowerCase().includes('não informado'));
        if (!naoInformado && auxData.paymentMethods.length > 0) {
            naoInformado = auxData.paymentMethods[0];
        }
        auxData.defaultPaymentMethodId = naoInformado?.id || null;

        const uniqueProducts = new Map();
        (stock.data || []).forEach(s => {
            if (!uniqueProducts.has(s.fabric_type)) {
                uniqueProducts.set(s.fabric_type, {
                    name: s.fabric_type,
                    code: s.gestao_click_id,
                    unidade: s.unit_of_measure,
                    rendimento: s.rendimento,
                    valor_venda: s.base_price,
                    estoque: s.quantity_meters
                });
            }
        });
        auxData.products = Array.from(uniqueProducts.values()).sort((a,b) => a.name.localeCompare(b.name));
    } catch (e) { console.error('Erro aux:', e); }
};

const fetchOrderData = async (order: any) => {
    isLoadingData.value = true;
    installments.value = [];
    localItems.value = [];
    localOrder.value = null;
    itemsToDelete.value = [];
    attachedFiles.value = [];

    try {
        let defaultChartId = auxData.chartOfAccounts.find(c => c.name.toLowerCase().includes('venda de produto'))?.id;
        if (!defaultChartId && auxData.chartOfAccounts.length > 0) defaultChartId = auxData.chartOfAccounts[0].id;

        const defaultBankId = guessBankIdFn(order);

        if (order.is_store_sale) {
            localOrder.value = order;
            localOrderHeader.total_value = Number(order.total_value) || 0;
            localOrderHeader.customer_id = order.customer_id;
            clientForm.nome = order.customer_name || '';
            if (order.items && Array.isArray(order.items)) {
                localItems.value = order.items.map((i: any) => ({
                    fabric_type: i.produto?.nome_produto || i.descricao || 'Item',
                    display_quantity: Number(i.produto?.quantidade || i.quantidade || 0),
                    unit_price: Number(i.produto?.valor_unitario || i.valor_unitario || 0),
                    total_value_items: Number(i.produto?.valor_total || i.valor_total || 0),
                    stamp_ref: i.referencia || '-',
                    notes: i.observacoes || '-',
                    is_kg: false,
                    quantity_meters: Number(i.produto?.quantidade || i.quantidade || 0),
                    quantity_unit: null,
                    excluded_from_invoice: false
                }));
            }
            const { data: recs } = await supabase.from('finance_receivables')
                .select('*')
                .ilike('description', `%${order.order_number}%`);
            if (recs) {
                installments.value = recs.filter(r => {
                      const valMatch = Math.abs(Number(r.value) - localOrderHeader.total_value) < 0.1;
                      return valMatch;
                }).map(r => ({
                    ...r,
                    chart_of_accounts_id: r.chart_of_accounts_id || defaultChartId,
                    bank_account_id: r.bank_account_id || defaultBankId
                }));
            }
        } else {
            const { data } = await supabase.from('orders').select('*, customers_mj(*), creator:created_by(full_name), stores(company_id)').eq('id', order.id).maybeSingle();
            if (data) {
                localOrder.value = data;
                localOrderHeader.customer_id = data.customer_id;
                localOrderHeader.vendedor_id = data.created_by;
                localOrderHeader.total_value = Number(data.total_value) || 0;
                localOrderHeader.notes = data.notes || '';

                const finalBankId = guessBankIdFn(data);

                if (data.details && data.details.downPayments && Array.isArray(data.details.downPayments)) {
                    data.details.downPayments.forEach((dp: any, i: number) => {
                        if (dp.proof_url) {
                            attachedFiles.value.push({ label: `Sinal ${i + 1} (${dp.method_id || 'Pagamento'})`, url: dp.proof_url, value: Number(dp.value) });
                        }
                    });
                }
                if (data.down_payment_proof_url && attachedFiles.value.length === 0) {
                     attachedFiles.value.push({ label: 'Comprovante de Sinal (Legado)', url: data.down_payment_proof_url, value: Number(data.details?.entry_value || 0) });
                }
                if (data.customer_id) loadClientDetails(data.customer_id);
                const { data: items } = await supabase.from('order_items').select('*').eq('order_id', data.id);
                localItems.value = (items || []).map(i => ({
                    id: i.id, fabric_type: i.fabric_type, stamp_ref: i.stamp_ref, quantity_meters: i.quantity_meters,
                    quantity_unit: i.quantity_unit, display_quantity: i.quantity_unit ? i.quantity_unit : i.quantity_meters, is_kg: !!i.quantity_unit,
                    notes: i.notes, gestao_click_product_id: i.gestao_click_product_id, total_value_items: i.total_value_items,
                    unit_price: (Number(i.total_value_items) / (Number(i.quantity_unit || i.quantity_meters) || 1)).toFixed(2),
                    design_tag: i.design_tag, status: i.status, unit_of_measure: i.unit_of_measure, rendimento: i.rendimento,
                    excluded_from_invoice: i.excluded_from_invoice
                }));

                const { data: dbRecs } = await supabase.from('finance_receivables').select('*').eq('order_id', data.id).order('due_date');
                const schedule = data.details?.installments_schedule || [];

                let loadedRecs: any[] = [];

                if (dbRecs && dbRecs.length > 0) {
                    loadedRecs = dbRecs.map(r => ({
                        ...r,
                        chart_of_accounts_id: r.chart_of_accounts_id || defaultChartId,
                        bank_account_id: r.bank_account_id || finalBankId
                    }));
                }

                if (schedule.length > 0) {
                    const matchedDbIds = new Set();

                    schedule.forEach((sch: any) => {
                        const matchInDb = loadedRecs.find(r =>
                            !matchedDbIds.has(r.id) &&
                            Math.abs(Number(r.value) - Number(sch.value)) < 0.1 &&
                            r.due_date === sch.due_date
                        );

                        if (matchInDb) {
                            matchedDbIds.add(matchInDb.id);
                        } else {
                            loadedRecs.push({
                                description: sch.description || `Parcela`,
                                value: Number(sch.value),
                                due_date: sch.due_date,
                                competence_date: sch.competence_date || sch.due_date,
                                status: 'em_aberto',
                                bank_account_id: sch.bank_account_id || finalBankId,
                                payment_method_id: sch.payment_method_id || null,
                                cost_center_id: sch.cost_center_id || null,
                                chart_of_accounts_id: sch.chart_of_accounts_id || defaultChartId,
                                order_id: data.id,
                                customer_id: data.customer_id,
                                id: null,
                                is_virtual: true // SINALIZAÇÃO PARA A BADGE
                            });
                        }
                    });
                }

                if (loadedRecs.length === 0) {
                    const orderTotal = Number(data.total_value || 0);
                    const today = new Date().toISOString().split('T')[0];
                    loadedRecs.push({
                        description: `Restante - Pedido #${data.order_number}`,
                        value: orderTotal,
                        due_date: today,
                        competence_date: today,
                        status: 'em_aberto',
                        bank_account_id: finalBankId,
                        chart_of_accounts_id: defaultChartId,
                        order_id: data.id,
                        customer_id: data.customer_id,
                        id: null,
                        is_virtual: true // SINALIZAÇÃO PARA A BADGE
                    });
                }

                loadedRecs.sort((a, b) => new Date(a.due_date).getTime() - new Date(b.due_date).getTime());
                installments.value = loadedRecs;
                updateInstallmentDescriptions();
            }
        }
    } catch (e) { console.error(e); } finally { isLoadingData.value = false; }
};

const loadClientDetails = async (clientId: string) => {
    try {
        const { data } = await supabase.from('customers_mj').select('*').eq('id', clientId).single();
        if (data) {
            const isPj = data.cnpj || (data.cpf_cnpj && String(data.cpf_cnpj).replace(/\D/g, '').length > 11);
            Object.assign(clientForm, {
                id: data.id,
                tipo_pessoa: isPj ? 'PJ' : 'PF',
                nome: data.nome,
                nome_fantasia: data.nome_fantasia,
                cpf_cnpj: data.cnpj || data.cpf || data.cpf_cnpj,
                ie: data.ie,
                email: data.email,
                telefone: data.telefone || data.celular,
                cep: data.cep,
                endereco: data.endereco,
                numero: data.numero,
                bairro: data.bairro,
                cidade: data.cidade,
                estado: data.estado,
                situacao: data.situacao || 'Ativo'
            });
        }
    } catch (e) { console.error("Erro cliente:", e); }
};

watch(() => localOrderHeader.customer_id, (newId) => { if (newId) loadClientDetails(newId); });

// --- RECALCULOS E HELPERS ---
const recalcItem = (item: any) => {
    item.total_value_items = (Number(item.display_quantity) * Number(item.unit_price)).toFixed(2);
    if (item.is_kg) { item.quantity_unit = Number(item.display_quantity); item.quantity_meters = (Number(item.display_quantity) * Number(item.rendimento || 0)).toFixed(2); }
    else { item.quantity_meters = Number(item.display_quantity); item.quantity_unit = null; }
    recalcTotal();
};

const recalcTotal = () => {
    localOrderHeader.total_value = localItems.value.reduce((acc, i) => {
        if (i.excluded_from_invoice) return acc;
        return acc + Number(i.total_value_items);
    }, 0);
};

const toggleItemExclusion = (idx: number) => {
    const item = localItems.value[idx];
    item.excluded_from_invoice = !item.excluded_from_invoice;
    recalcTotal();
};

const addInstallment = () => {
    let defaultChartId = auxData.chartOfAccounts.find(c => c.name.toLowerCase().includes('venda de produto'))?.id;
    if (!defaultChartId && auxData.chartOfAccounts.length > 0) defaultChartId = auxData.chartOfAccounts[0].id;

    const finalBankId = guessBankIdFn(localOrder.value);

    let nextDate = new Date();
    if (installments.value.length > 0) {
        const lastInst = installments.value[installments.value.length - 1];
        nextDate = addDays(parseISO(lastInst.due_date), daysGap.value);
    }
    const dateStr = format(nextDate, 'yyyy-MM-dd');

    installments.value.push({
        description: `Nova Parcela`,
        value: 0,
        due_date: dateStr,
        competence_date: dateStr,
        status: 'em_aberto',
        bank_account_id: finalBankId,
        chart_of_accounts_id: defaultChartId,
        order_id: localOrder.value?.id,
        customer_id: localOrderHeader.customer_id,
        is_virtual: true // INJEÇÃO DA BADGE
    });
    updateInstallmentDescriptions();
};

const cloneInstallment = (idx: number) => {
    const { id, is_virtual, ...rest } = installments.value[idx];
    installments.value.splice(idx + 1, 0, { ...rest, id: null, is_virtual: true });
    updateInstallmentDescriptions();
};

const removeInstallment = (idx: number) => {
    installments.value.splice(idx, 1);
    updateInstallmentDescriptions();
};

const distributeValuesEvenly = () => { const totalOrder = localOrderHeader.total_value; const paidInstallments = installments.value.filter(i => i.status === 'pago'); const openInstallments = installments.value.filter(i => i.status !== 'pago'); if (openInstallments.length === 0) return; const totalPaid = paidInstallments.reduce((acc, i) => acc + (Number(i.value) || 0), 0); const remainingToDistribute = Number((totalOrder - totalPaid).toFixed(2)); const count = openInstallments.length; const rawShare = Math.floor((remainingToDistribute / count) * 100) / 100; let distributedSoFar = 0; openInstallments.forEach((inst, index) => { if (index === count - 1) { inst.value = Number((remainingToDistribute - distributedSoFar).toFixed(2)); } else { inst.value = rawShare; distributedSoFar += rawShare; } }); };
const updateStatus = (inst: any, status: string) => { inst.status = status; if (status === 'pago' && !inst.payment_date) inst.payment_date = new Date().toISOString().split('T')[0]; };
const openAttachment = (url: string) => { if (url) window.open(url, '_blank'); };
const removeItem = (idx: number) => { const item = localItems.value[idx]; if (item.id) itemsToDelete.value.push(item.id); localItems.value.splice(idx, 1); recalcTotal(); };
const onItemSelect = (item: any, val: string) => { const prod = auxData.products.find(p => p.name === val); if(prod) { item.gestao_click_product_id = prod.code; item.unit_price = parseFloat(prod.valor_venda || '0'); item.is_kg = (prod.unidade || 'm').toLowerCase() === 'kg'; item.rendimento = parseFloat(prod.rendimento || '0'); recalcItem(item); } };

// --- FUNÇÃO DE IMPRESSÃO ---
const imageToBase64 = async (url: string): Promise<string> => {
  const res = await fetch(url);
  if (!res.ok) throw new Error('Falha ao carregar imagem');
  const blob = await res.blob();
  return await new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onerror = () => reject(new Error('Falha ao ler imagem'));
    reader.onload = () => resolve(String(reader.result));
    reader.readAsDataURL(blob);
  });
};

const printOrder = async () => {
  if (isSaving.value) return;
  if (!localOrder.value?.order_number) { appStore.showSnackbar("Pedido inválido para impressão.", "error"); return; }

  if (localOrder.value.is_store_sale) {
      const doc = new jsPDF();
      doc.text(`Pedido Loja #${localOrder.value.order_number}`, 10, 10);
      doc.text(`Cliente: ${localOrder.value.customer_name || 'Consumidor'}`, 10, 20);

      const visibleItems = localItems.value.filter(i => !i.excluded_from_invoice);

      autoTable(doc, {
          startY: 30,
          head: [['Item', 'Qtd', 'Valor']],
          body: visibleItems.map(i => [i.fabric_type, i.display_quantity, formatCurrency(i.total_value_items)])
      });
      doc.save(`Venda_Loja_${localOrder.value.order_number}.pdf`);
      return;
  }

  if (confirm("Deseja salvar as alterações antes de imprimir?")) {
      await saveAllChanges();
  }

  try {
    const orderId = localOrder.value.id;
    const brDate = (d: any) => { if (!d) return ""; try { const iso = String(d); const date = iso.includes("T") ? parseISO(iso) : parseISO(`${iso}T00:00:00`); return format(date, "dd/MM/yyyy"); } catch { return String(d); } };
    const onlyDigits = (v: any) => String(v ?? "").replace(/\D/g, "");
    const formatDoc = (v: any) => { const doc = onlyDigits(v); if (doc.length === 14) return doc.replace(/^(\d{2})(\d{3})(\d{3})(\d{4})(\d{2})$/, "$1.$2.$3/$4-$5"); if (doc.length === 11) return doc.replace(/^(\d{3})(\d{3})(\d{3})(\d{2})$/, "$1.$2.$3-$4"); return v ? String(v) : ""; };
    const money = (val: number) => new Intl.NumberFormat("pt-BR", { style: "currency", currency: "BRL" }).format(Number(val || 0));
    const num = (val: number) => new Intl.NumberFormat("pt-BR", { minimumFractionDigits: 2, maximumFractionDigits: 2 }).format(Number(val || 0));

    const order = localOrder.value;
    const c = { ...order.customer, ...order.customers_mj, ...clientForm };

    const visibleItems = localItems.value.filter(i => !i.excluded_from_invoice);

    const { data: stockRows } = await supabase.from("stock").select("fabric_type, gestao_click_id, ncm");
    const { data: paymentMethods } = await supabase.from("finance_payment_methods").select("id, name");

    const stockMap = new Map<string, any>((stockRows || []).map((s: any) => [String(s.fabric_type || "").trim().toLowerCase(), s]));
    const paymentMap = new Map<string, string>((paymentMethods || []).map((p: any) => [p.id, p.name]));

    const clienteNome = String(c.nome || c.razao_social || c.nome_fantasia || order.customer_name || "").trim() || "—";
    const docCliente = formatDoc(c.cpf_cnpj || c.cnpj || c.cpf || "");
    const addressLine = [ String(c.endereco || "").trim(), c.numero ? `, ${c.numero}` : "", c.bairro ? ` - ${c.bairro}` : "" ].join("").trim();
    const cep = String(c.cep || "").trim();
    const cidade = String(c.cidade || "").trim();
    const estado = String(c.estado || "").trim();
    const telefone = String(c.telefone || c.celular || "").trim();
    const email = String(c.email || "").trim();

    const productsBody = visibleItems.map((it: any, idx: number) => {
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

    const totalProdutos = localOrderHeader.total_value;
    const totalQtd = visibleItems.reduce((acc: number, it: any) => {
       const q = (it.quantity_unit && Number(it.quantity_unit) > 0) ? it.quantity_unit : it.quantity_meters;
       return acc + Number(q || 0);
    }, 0);

    const payRows = installments.value.map((r: any) => {
      const venc = brDate(r.due_date);
      const val = Number(r.value || 0);
      let nomeForma = "—";
      if (r.payment_method_id && paymentMap.has(r.payment_method_id)) { nomeForma = paymentMap.get(r.payment_method_id)!; } else if (r.payment_method) { nomeForma = String(r.payment_method); }
      const obs = String(r.description || "").trim() || "Parcela referente ao pedido.";
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
    const clientRows = [ ["Cliente:", clienteNome, "CNPJ/CPF:", docCliente || "—"], ["Endereço:", addressLine || "—", "CEP:", cep || "—"], ["Cidade:", cidade || "—", "Estado:", estado || "—"], ["Telefone:", telefone || "—", "E-mail:", email || "—"] ];
    autoTable(doc, { startY: clientBoxY + 7, theme: "grid", tableWidth: boxW, margin: { left: M, right: M }, styles: { fontSize: 8.5, cellPadding: 1.5, textColor: 0, lineColor: [200, 200, 200], lineWidth: 0.2, minCellHeight: 7, valign: "middle" }, bodyStyles: { fillColor: [255, 255, 255] }, columnStyles: { 0: { cellWidth: 20, fontStyle: "bold" }, 1: { cellWidth: 75 }, 2: { cellWidth: 20, fontStyle: "bold" }, 3: { cellWidth: 75 } }, body: clientRows });

    let lastY = (doc as any).lastAutoTable.finalY + 5;
    const notesContent = String(order.notes || "").trim();

    if (notesContent) {
        doc.setFillColor(255, 243, 224); doc.setDrawColor(255, 183, 77); doc.setFont("helvetica", "normal"); doc.setFontSize(8.5);
        const splitNotes = doc.splitTextToSize(notesContent, boxW - 4);
        const notesHeight = (splitNotes.length * 4) + 8;
        doc.rect(M, lastY, boxW, notesHeight, "F"); doc.rect(M, lastY, boxW, notesHeight);
        doc.setFont("helvetica", "bold"); doc.setTextColor(230, 81, 0); doc.text("OBSERVAÇÕES DO PEDIDO:", M + 2, lastY + 4);
        doc.setFont("helvetica", "normal"); doc.setTextColor(0); doc.text(splitNotes, M + 2, lastY + 9);
        lastY += notesHeight + 5;
    }

    doc.setFont("helvetica", "bold"); doc.setFontSize(9.5); doc.setFillColor(230); doc.setDrawColor(180); doc.rect(M, lastY, boxW, 7, "F"); doc.rect(M, lastY, boxW, 7); doc.setTextColor(0); doc.text("PRODUTOS", M + 2, lastY + 5);

    autoTable(doc, {
        startY: lastY + 7, theme: "grid", tableWidth: boxW, margin: { left: M, right: M },
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
    doc.setFont("helvetica", "bold"); doc.setFontSize(9.5); doc.setFillColor(230); doc.rect(M, afterTotalsY, boxW, 7, "F"); doc.setDrawColor(180); doc.rect(M, afterTotalsY, boxW, 7); doc.text("FINANCEIRO / PARCELAS", M + 2, afterTotalsY + 5);

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

// --- SAVE (COM TRAVA DE ERRO NA TELA, FIX DO UUID E REMOÇÃO DO SPAM DE NOTIFICAÇÕES) ---
const saveAllChanges = async () => {
    if (!confirm("Tem certeza que deseja salvar todas as edições deste pedido?")) return;

    isSaving.value = true;
    try {
        const invalidInstallments = installments.value.filter(i => !i.due_date || !i.competence_date || i.value === "" || i.value === null);
        if (invalidInstallments.length > 0) {
            appStore.showSnackbar("Erro: Existem parcelas sem Data de Vencimento, Competência ou Valor.", "warning");
            isSaving.value = false;
            return;
        }

        let defaultChartId = auxData.chartOfAccounts.find(c => c.name.toLowerCase().includes('venda de produto'))?.id;
        if (!defaultChartId && auxData.chartOfAccounts.length > 0) defaultChartId = auxData.chartOfAccounts[0].id;

        // STORE SALES
        if (localOrder.value.is_store_sale) {
             const updatedJsonItems = localItems.value.map(i => ({
                 produto: {
                    nome_produto: i.fabric_type,
                    quantidade: i.display_quantity,
                    valor_unitario: i.unit_price,
                    valor_total: i.total_value_items
                 },
                 referencia: i.stamp_ref,
                 observacoes: i.notes
             }));

             if (localOrder.value.id) {
                 await supabase.from('store_sales').update({
                     items: updatedJsonItems,
                     total_value: localOrderHeader.total_value
                 }).eq('id', localOrder.value.id);
             }

             appStore.showSnackbar("Venda de loja atualizada.", "success");
             emit('refresh');
             emit('close');
             return;
        }

        // NATIVE ORDERS
        if (clientForm.id) {
             const payload: any = { ...clientForm };
             delete payload.cpf_cnpj; delete payload.id;
             await supabase.from('customers_mj').update(payload).eq('id', clientForm.id);
        }

        if (itemsToDelete.value.length > 0) {
            await supabase.from('order_items').delete().in('id', itemsToDelete.value);
        }

        const newItemsList = localItems.value.filter(i => !i.id);
        const existingItemsList = localItems.value.filter(i => i.id);

        if (existingItemsList.length > 0) {
            const updatePayload = existingItemsList.map(item => ({
                id: item.id,
                order_id: localOrder.value.id,
                fabric_type: item.fabric_type || 'Indefinido',
                quantity_meters: Number(item.quantity_meters) || 0,
                quantity_unit: Number(item.quantity_unit) || null,
                total_value_items: Number(item.total_value_items) || 0,
                stamp_ref: item.stamp_ref || '',
                notes: item.notes || null,
                gestao_click_product_id: sanitizeValue(item.gestao_click_product_id),
                // STATUS FOI REMOVIDO DAQUI PARA NÃO DISPARAR O TRIGGER DE NOTIFICAÇÃO DO BANCO!
                design_tag: item.design_tag || 'Alteração',
                unit_of_measure: item.unit_of_measure || (item.is_kg ? 'kg' : 'm'),
                rendimento: item.rendimento,
                excluded_from_invoice: item.excluded_from_invoice
            }));
            await supabase.from('order_items').upsert(updatePayload);
        }

        if (newItemsList.length > 0) {
            const insertPayload = newItemsList.map(item => ({
                order_id: localOrder.value.id,
                fabric_type: item.fabric_type || 'Indefinido',
                quantity_meters: Number(item.quantity_meters) || 0,
                quantity_unit: Number(item.quantity_unit) || null,
                total_value_items: Number(item.total_value_items) || 0,
                stamp_ref: item.stamp_ref || '',
                stamp_image_url: item.stamp_image_url,
                notes: item.notes || null,
                gestao_click_product_id: sanitizeValue(item.gestao_click_product_id),
                status: 'design_pending', // No insert não tem problema pois não aciona o AFTER UPDATE
                design_tag: item.design_tag || 'Desenvolvimento',
                unit_of_measure: item.unit_of_measure || (item.is_kg ? 'kg' : 'm'),
                rendimento: item.rendimento,
                excluded_from_invoice: item.excluded_from_invoice
            }));
            await supabase.from('order_items').insert(insertPayload);
        }

        const currentDetails = localOrder.value.details || {};
        const updatedDetails = {
            ...currentDetails,
            observation: localOrderHeader.notes,
            installments_schedule: installments.value.map(i => ({
                description: i.description,
                value: Number(i.value),
                due_date: i.due_date,
                competence_date: i.competence_date,
                status: i.status,
                payment_method_id: sanitizeUUID(i.payment_method_id) || sanitizeUUID(auxData.defaultPaymentMethodId),
                bank_account_id: sanitizeUUID(i.bank_account_id),
                cost_center_id: sanitizeUUID(i.cost_center_id),
                chart_of_accounts_id: sanitizeUUID(i.chart_of_accounts_id) || sanitizeUUID(defaultChartId)
            }))
        };

        await supabase.from('orders').update({
            total_value: localOrderHeader.total_value,
            customer_id: sanitizeUUID(localOrderHeader.customer_id),
            created_by: sanitizeUUID(localOrderHeader.vendedor_id),
            notes: localOrderHeader.notes,
            details: updatedDetails,
            customer_name: clientForm.nome || localOrder.value.customer_name
        }).eq('id', localOrder.value.id);

        const currentIds = installments.value.map(i => i.id).filter(Boolean);
        const { data: dbRecs } = await supabase.from('finance_receivables').select('id, status').eq('order_id', localOrder.value.id);

        if (dbRecs) {
            const toDel = dbRecs
                .filter(r => !currentIds.includes(r.id) && r.status !== 'pago')
                .map(r => r.id);

            if (toDel.length > 0) {
                await supabase.from('finance_receivables').delete().in('id', toDel);
            }
        }

        // PREPARA AS PARCELAS E BLINDA OS UUIDS
        const allItemsPayload = installments.value.map((inst, idx) => {
            const { id, is_virtual, ...rest } = inst;

            const finalPaymentMethod = sanitizeUUID(inst.payment_method_id) || sanitizeUUID(auxData.defaultPaymentMethodId);
            const finalCompanyId = sanitizeUUID(localOrder.value?.stores?.company_id) || sanitizeUUID(auxData.defaultCompanyId);

            return {
                ...rest,
                order_id: sanitizeUUID(localOrder.value.id),
                customer_id: sanitizeUUID(localOrderHeader.customer_id),
                company_id: finalCompanyId,
                description: inst.description || `Parcela ${idx+1}`,
                value: Number(inst.value),
                due_date: inst.due_date || new Date().toISOString(),
                competence_date: inst.competence_date || new Date().toISOString(),
                payment_date: inst.status === 'pago' ? (inst.payment_date || new Date().toISOString()) : null,
                status: inst.status,
                bank_account_id: sanitizeUUID(inst.bank_account_id),
                payment_method_id: finalPaymentMethod,
                cost_center_id: sanitizeUUID(inst.cost_center_id),
                chart_of_accounts_id: sanitizeUUID(inst.chart_of_accounts_id) || sanitizeUUID(defaultChartId),
                created_by: sanitizeUUID(localOrderHeader.vendedor_id),
                id: sanitizeUUID(inst.id)
            }
        });

        const toInsert = allItemsPayload.filter(i => !i.id).map(({ id, ...rest }) => rest);
        const toUpdate = allItemsPayload.filter(i => i.id);

        // LANÇA ERRO REAL NA TELA SE O SUPABASE RECUSAR
        if (toInsert.length > 0) {
            const { error: insErr } = await supabase.from('finance_receivables').insert(toInsert);
            if (insErr) throw insErr;
        }
        if (toUpdate.length > 0) {
            const { error: updErr } = await supabase.from('finance_receivables').upsert(toUpdate);
            if (updErr) throw updErr;
        }

        appStore.showSnackbar("Edições salvas com sucesso!", "success");
        emit('refresh');
        emit('close');

    } catch (e: any) {
        console.error("Erro crítico no saveAllChanges:", e);
        appStore.showSnackbar("ERRO DO BANCO: " + (e.message || e.details || JSON.stringify(e)), "error");
    } finally {
        isSaving.value = false;
    }
};

watch(() => props.show, (val) => {
    if (val && props.order) fetchOrderData(props.order);
}, { immediate: true });

onMounted(() => { fetchAuxiliaryData(); });
</script>

<style scoped lang="scss">
.billing-modal-ui { font-family: 'Roboto', sans-serif; }
.lh-1 { line-height: 1; }
.gap-1 { gap: 4px; } .gap-2 { gap: 8px; } .gap-3 { gap: 12px; }
.section-number { width: 28px; height: 28px; display: flex; align-items: center; justify-content: center; border-radius: 6px; font-weight: 900; font-size: 13px; }
.input-label { font-size: 11px; font-weight: 800; text-transform: uppercase; color: #616161; display: block; margin-bottom: 4px; letter-spacing: 0.5px; }
.ui-field :deep(.v-field) { border-radius: 6px !important; border-color: rgba(0,0,0,0.12) !important; }
.ui-field :deep(.v-field__input) { min-height: 40px !important; padding-top: 6px !important; padding-bottom: 6px !important; font-size: 14px; font-weight: 500; }
.row-gap-sm { row-gap: 12px; }
.row-gap-md { row-gap: 16px; }
.custom-scroll::-webkit-scrollbar { width: 8px; height: 8px; }
.custom-scroll::-webkit-scrollbar-track { background: #f1f1f1; }
.custom-scroll::-webkit-scrollbar-thumb { background: #bdbdbd; border-radius: 4px; }
.border-thin { border: 1px solid rgba(0,0,0,0.12) !important; }
.absolute-center { position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%); }
.attachment-card { border: 1px solid #e0e0e0; cursor: pointer; transition: all 0.2s; }
.attachment-card:hover { border-color: #bdbdbd; background-color: #FAFAFA; transform: translateX(2px); }
.btn-rect { border-radius: 4px !important; text-transform: none !important; letter-spacing: 0 !important; }

/* === COMPONENTES ADMINMJRECEIVABLES === */
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
    border-radius: 6px !important;
    box-shadow: 0 3px 5px rgba(0,0,0,0.12), inset 0 1px 0 rgba(255,255,255,0.25) !important;
    text-shadow: 0 1px 2px rgba(0,0,0,0.25);
}

.clean-input {
    border: none;
    outline: none;
    background: transparent;
    font-size: 13px;
    padding: 4px 6px;
    border-radius: 4px;
    &:focus {
        background-color: #e3f2fd;
        color: #1565C0;
        font-weight: bold;
    }
}

.clean-textarea {
    border: none;
    outline: none;
    background: transparent;
    resize: none;
    &:focus {
        background-color: #FFF8E1;
        border-color: #FFB300 !important;
    }
}

.stamp-hero-container { position: relative; border-radius: 8px; overflow: hidden; }
.hover-border-primary:hover { border-color: #1976D2 !important; background-color: #F5F5F5; }
.shadow-up { box-shadow: 0 -4px 12px -1px rgba(0, 0, 0, 0.1); }
.border-dashed { border-style: dashed !important; }
.border-error-glow { border: 1px solid #ffcdd2; background-color: #ffebee; color: #c62828; }

/* === NOVO: TABLE RESPONSIVE WRAPPER === */
.table-responsive {
    overflow-x: auto;
    -webkit-overflow-scrolling: touch;
}

.grid-header {
    z-index: 20;
    border-bottom: 1px solid rgba(0,0,0,0.08);
    position: sticky;
    top: 0;
    background-color: #f5f7fa;
    box-shadow: 0 4px 6px -4px rgba(0, 0, 0, 0.1);
}

.grid-row {
    border-bottom: 1px solid rgba(0,0,0,0.06);
}

.cell {
    padding: 8px 10px;
    display: flex;
    align-items: center;
    border-right: 1px solid rgba(0,0,0,0.05);
    font-size: 13px;
}
.cell:last-child { border-right: none; }

.header-text {
    padding: 12px 10px;
    font-size: 11px;
    font-weight: 900;
    text-transform: uppercase;
    letter-spacing: 0.5px;
    display: flex;
    align-items: center;
    color: rgba(0,0,0,0.7);
}

.cell.center, .header-text.center { justify-content: center; text-align: center; }
.cell.right, .header-text.right { justify-content: flex-end; text-align: right; }

.hover-bg-row:hover { background-color: #F8FAFC; cursor: default; }

/* LAYOUT ATUALIZADO (Larguras aumentadas) */
.grid-items-layout {
    display: grid;
    grid-template-columns: 20% 12% 1fr 160px 160px 160px 100px;
    align-items: stretch;
    min-width: 1300px;
}

.grid-payments-layout {
    display: grid;
    grid-template-columns: 100px 130px 130px 1.5fr 220px 140px 140px 140px 90px;
    align-items: stretch;
    min-width: 1250px;
}

/* BOTÕES DE AÇÃO IDÊNTICOS */
.action-btn { width: 28px !important; height: 28px !important; border-radius: 6px !important; color: #fff !important; margin: 0 4px; }
.action-edit { background: #ff9900 !important; }
.action-clone { background: #199201 !important; }
.action-del { background: #c62828 !important; }

/* UTILS ADICIONAIS */
.border-white-10 { border-color: rgba(255,255,255,0.1) !important; }
.bg-grey-darken-4 { background-color: #212121 !important; }
.border-none { border: none !important; }
</style>
