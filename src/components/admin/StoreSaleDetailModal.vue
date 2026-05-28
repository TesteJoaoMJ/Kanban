<template>
  <v-dialog
    :model-value="modelValue"
    @update:model-value="$emit('update:modelValue', $event)"
    :width="mobile ? '100%' : '95vw'"
    :fullscreen="mobile"
    height="96vh"
    persistent
    class="billing-modal-ui font-sans"
    scrim="black opacity-80"
  >
    <v-card class="rounded-0 border-0 d-flex overflow-hidden fill-height transition-all" :class="[mobile ? 'flex-column' : 'flex-row', isDark ? 'bg-grey-darken-4 text-white' : 'bg-white']">

      <div
        class="sidebar-summary d-flex flex-column border-r transition-all"
        :class="isDark ? 'bg-grey-darken-3 border-white-10' : 'bg-grey-lighten-5 border-grey-lighten-2'"
        :style="mobile ? 'width: 100%; max-height: 35vh; flex-shrink: 0;' : 'width: 360px; height: 100%; flex-shrink: 0;'"
      >
          <div class="pa-4 pa-md-6 border-b elevation-1 z-10 d-flex justify-space-between align-center" :class="isDark ? 'bg-grey-darken-4 border-white-10' : 'bg-white border-grey-lighten-2'">
              <div class="d-flex flex-column gap-1">
                  <div class="text-[10px] font-weight-black text-uppercase ls-1" :class="isDark ? 'text-white-70' : 'text-grey'">Gestão de Venda (PDV)</div>
                  <div class="text-h5 text-md-h4 font-weight-black leading-none mb-1" :class="isDark ? 'text-blue-lighten-2' : 'text-primary'">
                      #{{ String(localOrder?.order_number || '0000').padStart(4, '0') }}
                  </div>
                  <div class="d-flex align-center gap-2 flex-wrap mt-1">
                      <v-chip size="x-small" :color="getStatusColor(localOrder?.financial_status)" variant="flat" class="font-weight-black text-uppercase rounded px-2 chip-3d">
                          {{ localOrder?.financial_status || 'Pendente' }}
                      </v-chip>
                      <span class="text-[11px] font-mono font-weight-bold px-2 py-1 rounded" :class="isDark ? 'bg-white-05 text-white-70' : 'bg-grey-lighten-4 text-grey-darken-1'">
                        {{ formatDate(localOrder?.date_sale || localOrder?.created_at) }}
                      </span>
                  </div>
              </div>
              <v-btn v-if="mobile" icon size="small" variant="text" @click="closeModal">
                  <v-icon>mdi-close</v-icon>
              </v-btn>
          </div>

          <div class="pa-4 pa-md-6 flex-grow-1 overflow-y-auto custom-scroll">
              <v-btn block color="primary" variant="flat" class="btn-3d font-weight-bold mb-3" height="44" prepend-icon="mdi-file-document-outline" @click="printA4Detailed">
                  Imprimir Romaneio (A4)
              </v-btn>

              <v-btn block color="deep-orange" variant="flat" class="btn-3d font-weight-bold mb-6" height="44" prepend-icon="mdi-printer-pos" @click="printNonFiscalReceipt">
                  Recibo S/ Valor Fiscal (80mm)
              </v-btn>

              <div class="text-[12px] font-weight-black text-uppercase mb-3 d-flex align-center gap-2" :class="isDark ? 'text-white-70' : 'text-grey-darken-3'">
                  <v-icon size="18">mdi-scale-balance</v-icon> Resumo e Conferência
              </div>

              <v-card class="pa-0 rounded-lg border-thin mb-4 shadow-sm relative overflow-hidden" :class="isDark ? 'bg-grey-darken-4 border-white-10' : 'bg-white'" elevation="0">
                  <div class="absolute left-0 top-0 bottom-0" :class="hasDivergence ? 'bg-red' : 'bg-success'" style="width: 6px; position: absolute; height: 100%;"></div>

                  <div class="pa-4 pl-6">
                    <div class="d-flex justify-space-between align-center mb-2">
                        <span class="text-[11px] font-weight-bold text-uppercase" :class="isDark ? 'text-white-70' : 'text-grey-darken-1'">Total dos Itens</span>
                        <span class="text-subtitle-1 font-weight-black font-mono" :class="isDark ? 'text-white' : 'text-grey-darken-4'">{{ formatCurrency(localOrderHeader.total_value) }}</span>
                    </div>
                    <div class="d-flex justify-space-between align-center mb-2">
                        <span class="text-[11px] font-weight-bold text-uppercase" :class="isDark ? 'text-white-70' : 'text-grey-darken-1'">Total Lançamentos</span>
                        <span class="text-subtitle-1 font-weight-black font-mono" :class="isDark ? 'text-white-70' : 'text-grey-darken-3'">{{ formatCurrency(totalInstallmentsValue) }}</span>
                    </div>
                    <v-divider class="my-3 border-dashed" :class="isDark ? 'border-white-20' : ''"></v-divider>
                    <div class="d-flex justify-space-between align-center" :class="hasDivergence ? 'text-red-darken-1' : 'text-success'">
                        <span class="text-[12px] font-weight-black text-uppercase">Diferença</span>
                        <span class="text-h5 font-weight-black font-mono">{{ formatCurrency(divergenceValue) }}</span>
                    </div>
                  </div>
              </v-card>

              <v-expand-transition>
                  <div v-if="hasDivergence" class="d-flex flex-column gap-2">
                      <v-btn size="large" color="red-darken-2" variant="flat" block class="btn-3d font-weight-black text-[12px]" prepend-icon="mdi-magic-staff" @click="distributeValuesEvenly">
                          Auto-Corrigir Lançamentos
                      </v-btn>
                  </div>
              </v-expand-transition>
          </div>

          <div class="pa-4 border-t mt-auto d-flex flex-row flex-md-column gap-3 z-10 shadow-up" :class="isDark ? 'bg-grey-darken-4 border-white-10' : 'bg-white border-grey-lighten-2'">
               <v-btn block height="48" color="success" variant="flat" class="btn-3d font-weight-black flex-grow-1 text-white tracking-widest" :loading="isSaving" @click="saveAllChanges">
                  <v-icon start size="20">mdi-content-save-check</v-icon> SALVAR ALTERAÇÕES
              </v-btn>

              <v-btn v-if="localOrder?.financial_status?.toLowerCase() === 'pendente'" block height="40" color="orange-darken-2" variant="flat" class="btn-3d font-weight-bold flex-grow-1 text-white" :loading="isSaving" @click="faturarAgora">
                  <v-icon start size="18">mdi-cash-check</v-icon> Faturar Agora
              </v-btn>

              <v-btn v-if="!mobile" block height="40" variant="outlined" :color="isDark ? 'grey-lighten-1' : 'grey-darken-2'" class="btn-3d font-weight-bold text-[12px]" @click="closeModal" :disabled="isSaving">
                  Cancelar
              </v-btn>
          </div>
      </div>

      <div class="main-content flex-grow-1 d-flex flex-column relative overflow-hidden" :class="isDark ? 'bg-black-20' : 'bg-grey-lighten-3'" :style="mobile ? 'height: 65vh;' : 'height: 100%;'">

          <div v-if="isLoadingData" class="absolute-center z-50 pa-8 rounded-xl border-thin shadow-lg text-center" :class="isDark ? 'bg-grey-darken-4' : 'bg-white'">
              <v-progress-circular indeterminate color="primary" size="48" width="4"></v-progress-circular>
              <div class="mt-4 text-caption font-weight-black text-uppercase ls-1">Carregando Dados da Venda...</div>
          </div>

          <div class="flex-grow-1 overflow-y-auto custom-scroll pb-16 px-4 px-md-8 pt-4 pt-md-6">

              <v-card class="mb-8 rounded-xl border-thin shadow-sm" :class="isDark ? 'bg-grey-darken-3 border-white-10' : 'bg-white'" elevation="0">
                  <div class="pa-4 pa-md-5 border-b d-flex justify-space-between align-center rounded-t-xl" :class="isDark ? 'bg-grey-darken-4 border-white-10' : 'bg-white border-grey-lighten-2'">
                      <div class="d-flex align-center gap-3">
                          <div class="section-number bg-primary-gradient text-white">01</div>
                          <div>
                              <h3 class="text-subtitle-1 font-weight-black text-uppercase ls-1" :class="isDark ? 'text-white' : 'text-grey-darken-4'">Dados Comerciais e Fiscais</h3>
                              <div v-if="!mobile" class="text-[12px] font-medium" :class="isDark ? 'text-white-70' : 'text-grey'">Informações do responsável, cliente e endereços para faturamento.</div>
                          </div>
                      </div>
                  </div>
                  <div class="pa-4 pa-md-6">
                      <v-row dense class="row-gap-md">
                          <v-col cols="12" md="6">
                              <label class="input-label">Vendedor Responsável</label>
                              <v-autocomplete v-model="localOrderHeader.vendedor_id" :items="auxData.salespeople" item-title="full_name" item-value="id" variant="outlined" density="compact" hide-details class="ui-field font-weight-bold" :class="isDark ? 'bg-grey-darken-4' : 'bg-white'" placeholder="Selecione o vendedor"></v-autocomplete>
                          </v-col>
                          <v-col cols="12" md="6">
                              <label class="input-label">Buscar / Trocar Cliente</label>
                              <div class="d-flex align-center gap-2">
                                  <v-autocomplete
                                      v-model="localOrderHeader.customer_id"
                                      :items="auxData.clients"
                                      item-title="nome"
                                      item-value="id"
                                      variant="outlined"
                                      density="compact"
                                      hide-details
                                      class="ui-field font-weight-bold flex-grow-1"
                                      :class="isDark ? 'bg-blue-darken-4 text-white' : 'bg-blue-lighten-5 text-blue-darken-4'"
                                      placeholder="Buscar no banco de dados..."
                                      no-data-text="Nada encontrado"
                                      @update:search="handleClientSearch"
                                  >
                                      <template v-slot:item="{ props, item }"><v-list-item v-bind="props" :subtitle="item.raw.cpf_cnpj || 'Sem Doc'"></v-list-item></template>
                                  </v-autocomplete>
                                  <v-tooltip text="Cadastrar Novo Cliente" location="top">
                                      <template v-slot:activator="{ props }">
                                          <v-btn v-bind="props" icon="mdi-account-plus" color="success" variant="tonal" class="btn-3d flex-shrink-0" height="40" width="40" @click="quickClientModal.show = true"></v-btn>
                                      </template>
                                  </v-tooltip>
                              </div>
                          </v-col>

                          <v-col cols="12" class="mt-2"><v-divider class="border-dashed" :class="isDark ? 'border-white-20' : ''"></v-divider></v-col>

                          <v-col cols="12" md="2">
                              <label class="input-label">Pessoa</label>
                              <v-select v-model="clientForm.tipo_pessoa" :items="['PF', 'PJ']" variant="outlined" density="compact" hide-details class="ui-field" :class="isDark ? 'bg-grey-darken-4' : 'bg-grey-lighten-5'"></v-select>
                          </v-col>
                          <v-col cols="12" md="5">
                              <label class="input-label">CPF/CNPJ (Busca Auto BrasilAPI)</label>
                              <v-text-field v-model="clientForm.cpf_cnpj" variant="outlined" density="compact" hide-details class="ui-field font-mono font-weight-bold" :class="isDark ? 'bg-grey-darken-4 text-blue-lighten-2' : 'bg-white text-indigo-darken-4'" append-inner-icon="mdi-magnify" @click:append-inner="consultarCnpjCpf" @keyup.enter="consultarCnpjCpf" v-maska="['###.###.###-##', '##.###.###/####-##']"></v-text-field>
                          </v-col>
                          <v-col cols="12" md="5">
                              <label class="input-label">Inscrição Estadual (IE)</label>
                              <v-text-field v-model="clientForm.ie" variant="outlined" density="compact" hide-details class="ui-field font-mono" :class="isDark ? 'bg-grey-darken-4' : 'bg-white'"></v-text-field>
                          </v-col>

                          <v-col cols="12" md="6">
                              <label class="input-label">Nome / Razão Social</label>
                              <v-text-field v-model="clientForm.nome" variant="outlined" density="compact" hide-details class="ui-field font-weight-bold" :class="isDark ? 'bg-grey-darken-4' : 'bg-white'"></v-text-field>
                          </v-col>
                          <v-col cols="12" md="6">
                              <label class="input-label">Nome Fantasia</label>
                              <v-text-field v-model="clientForm.nome_fantasia" variant="outlined" density="compact" hide-details class="ui-field" :class="isDark ? 'bg-grey-darken-4' : 'bg-white'"></v-text-field>
                          </v-col>

                          <v-col cols="12" md="6">
                              <label class="input-label">Email de Contato</label>
                              <v-text-field v-model="clientForm.email" variant="outlined" density="compact" hide-details class="ui-field" :class="isDark ? 'bg-grey-darken-4' : 'bg-white'"></v-text-field>
                          </v-col>
                          <v-col cols="12" md="6">
                              <label class="input-label">Telefone / WhatsApp</label>
                              <v-text-field v-model="clientForm.telefone" variant="outlined" density="compact" hide-details class="ui-field font-weight-bold" :class="isDark ? 'bg-grey-darken-4' : 'bg-white'" v-maska="'(##) #####-####'"></v-text-field>
                          </v-col>

                          <v-col cols="12" md="3">
                              <label class="input-label">CEP</label>
                              <v-text-field v-model="clientForm.cep" variant="outlined" density="compact" hide-details class="ui-field font-mono" :class="isDark ? 'bg-grey-darken-4' : 'bg-white'" append-inner-icon="mdi-magnify" @click:append-inner="consultarCep" @keyup.enter="consultarCep" v-maska="'#####-###'"></v-text-field>
                          </v-col>
                          <v-col cols="12" md="6">
                              <label class="input-label">Endereço (Rua/Av)</label>
                              <v-text-field v-model="clientForm.endereco" variant="outlined" density="compact" hide-details class="ui-field" :class="isDark ? 'bg-grey-darken-4' : 'bg-white'"></v-text-field>
                          </v-col>
                          <v-col cols="12" md="3">
                              <label class="input-label">Número</label>
                              <v-text-field v-model="clientForm.numero" variant="outlined" density="compact" hide-details class="ui-field" :class="isDark ? 'bg-grey-darken-4' : 'bg-white'"></v-text-field>
                          </v-col>
                          <v-col cols="12" md="4">
                              <label class="input-label">Bairro</label>
                              <v-text-field v-model="clientForm.bairro" variant="outlined" density="compact" hide-details class="ui-field" :class="isDark ? 'bg-grey-darken-4' : 'bg-white'"></v-text-field>
                          </v-col>
                          <v-col cols="12" md="5">
                              <label class="input-label">Cidade</label>
                              <v-text-field v-model="clientForm.cidade" variant="outlined" density="compact" hide-details class="ui-field" :class="isDark ? 'bg-grey-darken-4' : 'bg-white'"></v-text-field>
                          </v-col>
                          <v-col cols="12" md="3">
                              <label class="input-label">Estado (UF)</label>
                              <v-text-field v-model="clientForm.estado" variant="outlined" density="compact" hide-details class="ui-field text-uppercase" :class="isDark ? 'bg-grey-darken-4' : 'bg-white'" maxlength="2"></v-text-field>
                          </v-col>
                      </v-row>
                  </div>
              </v-card>

              <v-card class="mb-8 rounded-xl border-thin shadow-sm overflow-hidden" :class="isDark ? 'bg-grey-darken-3 border-white-10' : 'bg-indigo-lighten-5'" elevation="0">
                  <div class="pa-4 pa-md-5 border-b d-flex justify-space-between align-center rounded-t-xl" :class="isDark ? 'bg-indigo-darken-4 border-indigo-darken-2' : 'bg-white border-indigo-lighten-4'">
                      <div class="d-flex align-center gap-3">
                          <div class="section-number bg-indigo text-white">02</div>
                          <div>
                              <h3 class="text-subtitle-1 font-weight-black text-uppercase ls-1" :class="isDark ? 'text-white' : 'text-indigo-darken-4'">Itens Faturados</h3>
                              <div v-if="!mobile" class="text-[12px] font-medium" :class="isDark ? 'text-indigo-lighten-4' : 'text-grey'">Valide e altere os itens vendidos.</div>
                          </div>
                      </div>
                      <v-btn color="indigo-darken-3" variant="flat" size="small" class="btn-3d font-weight-bold px-4" @click="openAddItemModal" prepend-icon="mdi-plus">
                          {{ mobile ? 'Add' : 'Adicionar Item' }}
                      </v-btn>
                  </div>

                  <div class="table-responsive rounded-b-xl border-t" :class="isDark ? 'bg-grey-darken-4 border-white-10' : 'bg-white border-indigo-lighten-4'">
                      <div class="grid-header grid-items-layout border-b z-20" :class="isDark ? 'bg-grey-darken-4 border-white-10' : 'bg-indigo-lighten-5 border-indigo-lighten-4'">
                          <div class="cell header-text" :class="isDark ? 'text-indigo-lighten-2' : 'text-indigo-darken-4'">Produto Base</div>
                          <div class="cell center header-text" :class="isDark ? 'text-indigo-lighten-2' : 'text-indigo-darken-4'">Tamanho</div>
                          <div class="cell center header-text" :class="isDark ? 'text-indigo-lighten-2' : 'text-indigo-darken-4'">SKU / NCM</div>
                          <div class="cell center header-text" :class="isDark ? 'text-indigo-lighten-2' : 'text-indigo-darken-4'">Qtd Final</div>
                          <div class="cell center header-text" :class="isDark ? 'text-indigo-lighten-2' : 'text-indigo-darken-4'">Unitário (R$)</div>
                          <div class="cell right header-text" :class="isDark ? 'text-indigo-lighten-2' : 'text-indigo-darken-4'">Total Faturado</div>
                          <div class="cell center header-text" :class="isDark ? 'text-indigo-lighten-2' : 'text-indigo-darken-4'">Ação</div>
                      </div>

                      <div v-if="localItems.length === 0" class="pa-10 text-center opacity-50">Nenhum item lançado.</div>

                      <div v-for="(item, i) in localItems" :key="i" class="grid-row grid-items-layout hover-bg-row group transition-colors" :class="[isDark ? 'grid-row-dark' : 'grid-row-light', {'opacity-40 bg-grey-lighten-4': item.excluded_from_invoice}]">
                          <div class="cell">
                              <v-autocomplete v-model="item.fabric_type" :items="auxData.products" item-title="name" item-value="name" variant="plain" density="compact" hide-details class="clean-input font-weight-bold text-[13px] w-100" :class="isDark ? 'text-white' : 'text-indigo-darken-4'" @update:model-value="(val) => onItemSelect(item, val)" :disabled="item.excluded_from_invoice"></v-autocomplete>
                          </div>
                          <div class="cell center">
                              <input v-model="item.size" class="clean-input w-100 text-[13px] font-weight-black font-mono text-center" placeholder="U" :disabled="item.excluded_from_invoice" :class="isDark ? 'text-white' : ''" />
                          </div>

                          <div class="cell center flex-column align-center justify-center">
                              <span class="font-mono text-[11px] font-weight-bold opacity-80 d-block" :class="isDark ? 'text-white' : ''">SKU: {{ item.codigo || 'S/N' }}</span>
                              <span class="font-mono text-[10px] font-weight-bold opacity-60 d-block" :class="isDark ? 'text-white' : ''">NCM: {{ item.ncm || 'S/N' }}</span>
                          </div>

                          <div class="cell center">
                              <div class="d-flex align-center border rounded px-2 py-0 w-100 transition-all hover-border-primary" :class="isDark ? 'bg-grey-darken-3 border-white-20' : 'bg-white border-grey-lighten-1'" style="height: 36px;">
                                  <input type="number" v-model.number="item.display_quantity" class="clean-input w-100 text-center font-weight-black text-[14px]" :class="isDark ? 'text-blue-lighten-2' : 'text-primary'" step="0.1" @input="recalcItem(item)" :disabled="item.excluded_from_invoice" />
                                  <span class="text-[11px] font-weight-black flex-shrink-0" :class="isDark ? 'text-white-70' : 'text-grey'">UN</span>
                              </div>
                          </div>
                          <div class="cell center">
                              <div class="border rounded px-2 py-0 w-100 transition-all hover-border-primary" :class="isDark ? 'bg-grey-darken-3 border-white-20' : 'bg-white border-grey-lighten-1'" style="height: 36px;">
                                <input type="number" v-model.number="item.unit_price" class="clean-input w-100 text-center font-weight-bold text-[14px]" :class="isDark ? 'text-white' : 'text-grey-darken-4'" step="0.01" @input="recalcItem(item)" :disabled="item.excluded_from_invoice" />
                              </div>
                          </div>
                          <div class="cell right">
                              <span class="font-mono font-weight-black text-[14px]" :class="item.excluded_from_invoice ? 'text-decoration-line-through text-grey' : (isDark ? 'text-success-lighten-1' : 'text-success-darken-1')">
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

              <v-card class="mb-8 rounded-xl border-thin shadow-sm overflow-hidden" :class="isDark ? 'bg-grey-darken-3 border-white-10' : 'bg-green-lighten-5'" elevation="0">
                  <div class="pa-4 pa-md-5 border-b d-flex justify-space-between align-center rounded-t-xl flex-wrap gap-3" :class="isDark ? 'bg-green-darken-4 border-green-darken-2' : 'bg-white border-green-lighten-4'">
                      <div class="d-flex align-center gap-3">
                          <div class="section-number bg-green-darken-2 text-white">03</div>
                          <div>
                              <h3 class="text-subtitle-1 font-weight-black text-uppercase ls-1" :class="isDark ? 'text-white' : 'text-green-darken-4'">Organização Financeira</h3>
                              <div v-if="!mobile" class="text-[12px] font-medium" :class="isDark ? 'text-green-lighten-4' : 'text-grey'">Lançamentos de caixa atrelados à venda.</div>
                          </div>
                      </div>

                      <div class="d-flex align-center gap-3">
                          <div class="d-flex align-center gap-2 border-thin rounded pa-1" :class="isDark ? 'bg-grey-darken-4' : 'bg-grey-lighten-5'">
                              <div class="d-flex align-center border-thin rounded px-2" :class="isDark ? 'bg-grey-darken-3' : 'bg-white'" style="height: 36px;">
                                 <span class="text-[11px] font-weight-bold mr-2 text-uppercase" :class="isDark ? 'text-white-70' : 'text-grey-darken-1'">Intervalo (Dias)</span>
                                 <input type="number" v-model.number="daysGap" class="clean-input text-center font-weight-black text-[14px]" :class="isDark ? 'text-blue-lighten-2' : 'text-primary'" style="width: 45px;" min="1" max="365">
                              </div>
                              <v-btn color="green-darken-3" variant="flat" size="small" height="36" class="btn-3d font-weight-bold px-4" @click="addInstallment" prepend-icon="mdi-cash-plus">
                                  {{ mobile ? 'Nova' : 'Nova Parcela' }}
                              </v-btn>
                          </div>
                      </div>
                  </div>

                  <div class="table-responsive rounded-b-xl border-t" :class="isDark ? 'bg-grey-darken-4 border-white-10' : 'bg-white border-green-lighten-4'">
                        <div class="grid-header grid-payments-layout border-none shadow-sm z-20" :class="isDark ? 'bg-green-darken-4' : 'bg-grey-darken-4'">
                           <div class="cell center header-text text-white border-white-10">Status</div>
                           <div class="cell center header-text text-white border-white-10">Vencimento</div>
                           <div class="cell header-text text-white border-white-10">Plano Contas</div>
                           <div class="cell header-text text-white border-white-10">Banco / Destino</div>
                           <div class="cell header-text text-white border-white-10">Forma Pagto</div>
                           <div class="cell right header-text text-white border-white-10">Valor (R$)</div>
                           <div class="cell center header-text text-white border-none">Ações</div>
                        </div>

                        <div v-if="installments.length === 0" class="pa-10 text-center">
                            <v-icon size="48" class="mb-3 opacity-20" :class="isDark ? 'text-white' : 'text-green-darken-3'">mdi-cash-remove</v-icon>
                            <div class="text-[13px] font-weight-bold opacity-60">Nenhum lançamento no sistema.</div>
                        </div>

                        <div v-for="(inst, i) in installments" :key="i" class="grid-row grid-payments-layout hover-bg-row group transition-colors" :class="isDark ? 'grid-row-dark' : 'grid-row-light'">
                            <div class="cell center">
                                <v-menu location="bottom center" :close-on-content-click="true">
                                    <template v-slot:activator="{ props }">
                                        <button v-bind="props" class="w-100 py-1 rounded font-weight-black text-[11px] text-uppercase transition-colors border chip-3d" :class="getStatusColorClass(inst.status)" style="height: 36px;">
                                            {{ inst.status === 'pago' ? 'PAGO' : 'ABERTO' }}
                                            <v-icon size="14" class="ml-1">mdi-chevron-down</v-icon>
                                        </button>
                                    </template>
                                    <v-list density="compact" class="rounded py-0 border-thin elevation-2" :class="isDark ? 'bg-grey-darken-4 text-white' : 'bg-white'">
                                        <v-list-item v-for="s in statusOptions" :key="s.value" :value="s.value" @click="updateStatus(inst, s.value)" class="min-h-32 hover-bg-grey-lighten-5">
                                            <v-list-item-title class="text-[12px] font-weight-black uppercase">{{ s.label }}</v-list-item-title>
                                        </v-list-item>
                                    </v-list>
                                </v-menu>
                            </div>

                            <div class="cell center">
                                <input type="date" v-model="inst.due_date" class="clean-input w-100 text-center font-mono font-weight-bold text-[13px] border rounded px-2 hover-border-primary transition-colors" :class="isDark ? 'bg-grey-darken-3 border-white-20 text-white' : 'bg-white border-grey-lighten-1'" style="height: 38px;"/>
                            </div>

                            <div class="cell">
                                <select v-model="inst.chart_of_accounts_id" disabled class="clean-input w-100 text-[12px] font-weight-bold border rounded px-2 text-truncate opacity-70" :class="isDark ? 'bg-grey-darken-3 border-white-20 text-white' : 'bg-indigo-lighten-5 border-grey-lighten-1 text-indigo-darken-4'" style="height: 38px; cursor: not-allowed;">
                                    <option :value="null" disabled>Plano de Contas</option>
                                    <option v-for="acc in auxData.chartOfAccounts" :key="acc.id" :value="acc.id">{{ acc.name }}</option>
                                </select>
                            </div>

                            <div class="cell">
                                <select v-model="inst.bank_account_id" disabled class="clean-input w-100 text-[12px] font-weight-bold border rounded px-2 text-truncate opacity-70" :class="isDark ? 'bg-grey-darken-3 border-white-20 text-white' : 'bg-white border-grey-lighten-1'" style="height: 38px; cursor: not-allowed;">
                                    <option :value="null" disabled>Selecione a Conta</option>
                                    <option v-for="acc in auxData.bankAccounts" :key="acc.id" :value="acc.id">{{ acc.name }}</option>
                                </select>
                            </div>

                            <div class="cell">
                                <select v-model="inst.payment_method_id" class="clean-input w-100 text-[12px] font-weight-bold border rounded px-2 hover-border-primary transition-colors text-truncate" :class="isDark ? 'bg-grey-darken-3 border-white-20 text-white' : 'bg-white border-grey-lighten-1'" style="height: 38px; cursor: pointer;">
                                    <option :value="null" disabled>Meio de Pagamento</option>
                                    <option v-for="pm in auxData.paymentMethods" :key="pm.id" :value="pm.id">{{ pm.name }}</option>
                                </select>
                            </div>

                            <div class="cell right">
                                <div class="d-flex align-center border rounded px-2 w-100 transition-all hover-border-primary" :class="isDark ? 'bg-grey-darken-3 border-white-20' : 'bg-white border-grey-lighten-1'" style="height: 38px;">
                                   <span class="text-[12px] font-weight-bold opacity-60 mr-1" :class="isDark ? 'text-white' : ''">R$</span>
                                   <input type="number" v-model.number="inst.value" step="0.01" class="clean-input w-100 text-right font-mono font-weight-black text-[15px] bg-transparent" :class="inst.status === 'pago' ? 'text-green-darken-2' : (isDark ? 'text-white' : 'text-grey-darken-4')" />
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

              <v-card class="mb-6 rounded-xl border-thin shadow-sm overflow-hidden" :class="isDark ? 'bg-grey-darken-3 border-white-10' : 'bg-amber-lighten-5'" elevation="0">
                  <div class="pa-4 pa-md-5 border-b d-flex justify-space-between align-center rounded-t-xl" :class="isDark ? 'bg-amber-darken-4 border-amber-darken-2' : 'bg-white border-amber-lighten-4'">
                      <div class="d-flex align-center gap-3">
                          <div class="section-number bg-amber-darken-3 text-white">04</div>
                          <h3 class="text-subtitle-1 font-weight-black text-uppercase ls-1" :class="isDark ? 'text-white' : 'text-amber-darken-4'">Observações da Venda</h3>
                      </div>
                  </div>
                  <div class="pa-4 pa-md-6 border-b rounded-b-xl" :class="isDark ? 'bg-grey-darken-4 border-white-10' : 'bg-amber-lighten-5 border-amber-lighten-4'">
                      <textarea
                        v-model="localOrderHeader.notes"
                        class="clean-textarea w-100 text-[14px] font-weight-medium border-thin rounded-lg pa-4 shadow-sm"
                        :class="isDark ? 'bg-grey-darken-3 text-white border-white-20' : 'bg-white text-grey-darken-4'"
                        rows="4"
                        placeholder="Instruções de entrega, dados fiscais para faturamento ou detalhes críticos..."
                      ></textarea>
                  </div>
              </v-card>

          </div>
      </div>
    </v-card>

    <v-dialog v-model="showAddItemModal" max-width="500px" persistent :fullscreen="mobile">
        <v-card class="rounded-lg overflow-hidden border-thin shadow-2xl" :class="isDark ? 'bg-grey-darken-4 text-white' : 'bg-white'">
            <div class="px-5 py-4 border-b d-flex justify-space-between align-center" :class="isDark ? 'bg-grey-darken-3 border-white-10' : 'bg-grey-lighten-5 border-grey-lighten-2'">
               <div class="d-flex align-center gap-3">
                  <div class="icon-box-sm rounded d-flex align-center justify-center bg-indigo-darken-3 text-white" style="width: 32px; height: 32px;">
                     <v-icon size="20">mdi-plus</v-icon>
                  </div>
                  <div class="lh-1">
                     <h2 class="text-subtitle-1 font-weight-black">Adicionar Produto</h2>
                  </div>
               </div>
               <v-btn icon size="small" variant="text" @click="showAddItemModal = false"><v-icon>mdi-close</v-icon></v-btn>
            </div>
            <v-card-text class="pa-5">
                <v-form ref="itemFormRef">
                   <v-row dense class="row-gap-md">
                      <v-col cols="12">
                         <label class="input-label">Produto Base</label>
                         <v-autocomplete v-model="newItemForm.fabric_type" :items="auxData.products" item-title="name" item-value="name" placeholder="Selecione o produto..." variant="outlined" density="compact" :rules="[rules.required]" hide-details="auto" class="ui-field font-weight-bold" :class="isDark ? 'bg-grey-darken-3' : 'bg-white'" @update:model-value="onNewItemSelect"></v-autocomplete>
                      </v-col>
                      <v-col cols="6">
                         <label class="input-label">Tamanho / Grade</label>
                         <v-text-field v-model="newItemForm.size" variant="outlined" density="compact" hide-details="auto" class="ui-field font-weight-bold font-mono text-center" :class="isDark ? 'bg-grey-darken-3' : 'bg-white'" placeholder="U"></v-text-field>
                      </v-col>
                      <v-col cols="6">
                         <label class="input-label">Quantidade (UN)</label>
                         <v-text-field v-model.number="newItemForm.quantity" type="number" variant="outlined" density="compact" :rules="[rules.required, rules.positive]" hide-details="auto" class="ui-field font-weight-black text-center text-primary" :class="isDark ? 'bg-grey-darken-3' : 'bg-white'"></v-text-field>
                      </v-col>
                      <v-col cols="12">
                         <label class="input-label">Preço Unitário</label>
                         <v-text-field v-model.number="newItemForm.unit_price" type="number" variant="outlined" density="compact" prefix="R$" hide-details="auto" class="ui-field font-weight-black text-right" :class="isDark ? 'bg-grey-darken-3' : 'bg-white'"></v-text-field>
                      </v-col>
                   </v-row>
                </v-form>
            </v-card-text>
            <v-card-actions class="pa-4 border-t justify-end gap-2" :class="isDark ? 'bg-grey-darken-3 border-white-10' : 'bg-grey-lighten-5 border-grey-lighten-2'">
                <v-btn variant="outlined" :color="isDark ? 'white' : 'grey-darken-2'" height="40" class="btn-rect px-4 btn-3d font-weight-bold" @click="showAddItemModal = false">Cancelar</v-btn>
                <v-btn color="indigo-darken-3" variant="flat" height="40" class="btn-rect px-6 font-weight-black btn-3d" @click="confirmAddItem" :disabled="!newItemForm.fabric_type || newItemForm.quantity <= 0">
                    <v-icon start>mdi-check</v-icon> Adicionar
                </v-btn>
            </v-card-actions>
        </v-card>
    </v-dialog>

    <v-dialog v-model="quickClientModal.show" max-width="400px" persistent>
        <v-card class="rounded-lg overflow-hidden border-thin shadow-2xl" :class="isDark ? 'bg-grey-darken-4 text-white' : 'bg-white'">
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
                        <label class="input-label">CPF ou CNPJ</label>
                        <v-text-field v-model="quickClientModal.cpf_cnpj" variant="outlined" density="compact" hide-details class="ui-field font-mono font-weight-bold text-primary" v-maska="['###.###.###-##', '##.###.###/####-##']"></v-text-field>
                    </v-col>
                    <v-col cols="12">
                        <label class="input-label">Nome ou Razão Social</label>
                        <v-text-field v-model="quickClientModal.nome" variant="outlined" density="compact" hide-details class="ui-field font-weight-bold"></v-text-field>
                    </v-col>
                    <v-col cols="12">
                        <label class="input-label">Telefone / WhatsApp</label>
                        <v-text-field v-model="quickClientModal.telefone" variant="outlined" density="compact" hide-details class="ui-field font-weight-bold" v-maska="'(##) #####-####'"></v-text-field>
                    </v-col>
                </v-row>
            </v-card-text>
            <v-card-actions class="pa-4 border-t justify-end gap-2" :class="isDark ? 'bg-grey-darken-3 border-white-10' : 'bg-grey-lighten-5'">
                <v-btn variant="outlined" :color="isDark ? 'white' : 'grey-darken-2'" height="40" class="btn-rect px-4 btn-3d font-weight-bold" @click="quickClientModal.show = false">Cancelar</v-btn>
                <v-btn color="success" variant="flat" height="40" class="btn-rect px-6 font-weight-black btn-3d" @click="saveQuickClient" :loading="quickClientModal.loading" :disabled="!quickClientModal.nome">
                    <v-icon start>mdi-check</v-icon> Salvar Cliente
                </v-btn>
            </v-card-actions>
        </v-card>
    </v-dialog>

  </v-dialog>
</template>

<script setup lang="ts">
import { ref, computed, watch, reactive } from 'vue';
import { useAppStore } from '@/stores/app';
import { useCompanyStore } from '@/stores/company';
import { supabase } from '@/api/supabase';
import { format, parseISO, addDays } from 'date-fns';
import { useDisplay, useTheme } from 'vuetify';
import axios from 'axios';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import { vMaska } from "maska/vue";
import logoCajuia from '@/assets/logocajuia.png';

const props = defineProps<{ modelValue: boolean; sale: any; }>();
const emit = defineEmits(['update:modelValue', 'close', 'refresh', 'print-nfce']);

const appStore = useAppStore();
const companyStore = useCompanyStore();
const { mobile } = useDisplay();
const theme = useTheme();
const isDark = computed(() => theme.global.current.value.dark);
const zebraClass = (index: number) => isDark.value ? (index % 2 === 0 ? 'zebra-dark-a' : 'zebra-dark-b') : (index % 2 === 0 ? 'zebra-light-a' : 'zebra-light-b');

const isSaving = ref(false);
const isLoadingData = ref(false);
const showAddItemModal = ref(false);

const daysGap = ref(30);

const localOrder = ref<any>(null);
const localOrderHeader = reactive({ customer_id: null as string | null, vendedor_id: null as string | null, total_value: 0, notes: '' });
const localItems = ref<any[]>([]);
const itemsToDelete = ref<string[]>([]);
const installments = ref<any[]>([]);

const newItemForm = reactive({ fabric_type: '', size: 'U', quantity: 1, unit_price: 0, gestao_click_product_id: '', ncm: '', sku: '' });
const quickClientModal = reactive({ show: false, nome: '', cpf_cnpj: '', telefone: '', loading: false });

const auxData = reactive({ bankAccounts: [] as any[], chartOfAccounts: [] as any[], paymentMethods: [] as any[], clients: [] as any[], salespeople: [] as any[], products: [] as any[] });
const clientForm = reactive({ id: null as string | null, tipo_pessoa: 'PF', nome: '', nome_fantasia: '', cpf_cnpj: '', ie: '', email: '', telefone: '', cep: '', endereco: '', numero: '', bairro: '', cidade: '', estado: '', situacao: 'Ativo' });

const statusOptions = [{ label: 'Aberto', value: 'em_aberto' }, { label: 'Pago', value: 'pago' }, { label: 'Atrasado', value: 'atrasado' }, { label: 'Canc.', value: 'cancelado' }];
const rules = { required: (v: any) => !!v || 'Obrigatório.', positive: (v: number | null) => (v != null && v > 0) || '> 0' };

const getStatusColor = (status: string) => { if (!status) return 'grey'; const s = status.toLowerCase(); if (s.includes('pago') || s.includes('faturado') || s === 'completed') return 'success'; if (s.includes('parcial')) return 'warning'; if (s.includes('cancel')) return 'error'; return 'grey-darken-2'; };
const getStatusColorClass = (status: string) => { if (status === 'pago') return 'text-success bg-green-lighten-5 border-success'; if (status === 'atrasado') return 'text-error bg-red-lighten-5 border-error'; if (status === 'cancelado') return 'text-grey bg-grey-lighten-4 border-grey'; return 'text-orange-darken-3 bg-white border-orange-lighten-4'; };
const formatDate = (d: any) => { if (!d) return '-'; try { return format(parseISO(d), 'dd/MM/yyyy'); } catch { return d; } };
const formatCurrency = (v: number) => new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(v || 0);

const totalInstallmentsValue = computed(() => installments.value.reduce((acc, i) => acc + (Number(i.value) || 0), 0));
const divergenceValue = computed(() => localOrderHeader.total_value - totalInstallmentsValue.value);
const hasDivergence = computed(() => Math.abs(divergenceValue.value) > 0.05);

const closeModal = () => { emit('update:modelValue', false); emit('close'); };

// --- DEFAULTS ---
const getDefaultChartId = () => auxData.chartOfAccounts.find(c => c.name.toLowerCase().includes('venda de produto'))?.id || auxData.chartOfAccounts[0]?.id;
const getDefaultBankId = () => auxData.bankAccounts.find(x => x.name.toLowerCase().includes('cora'))?.id || auxData.bankAccounts[0]?.id;

// --- BUSCAS DE DADOS BRASILAPI/VIACEP ---
const consultarCnpjCpf = async () => {
    const doc = clientForm.cpf_cnpj.replace(/\D/g, '');
    if (doc.length === 14) {
        try {
            appStore.showSnackbar('Consultando CNPJ...', 'info');
            const { data } = await axios.get(`https://brasilapi.com.br/api/cnpj/v1/${doc}`);
            clientForm.nome = data.razao_social || ''; clientForm.nome_fantasia = data.nome_fantasia || ''; clientForm.cep = data.cep || '';
            clientForm.endereco = `${data.logradouro || ''} ${data.complemento || ''}`.trim(); clientForm.numero = data.numero || '';
            clientForm.bairro = data.bairro || ''; clientForm.cidade = data.municipio || ''; clientForm.estado = data.uf || ''; clientForm.tipo_pessoa = 'PJ';
            appStore.showSnackbar('Dados da empresa carregados.', 'success');
        } catch(e) { appStore.showSnackbar('CNPJ não encontrado.', 'error'); }
    } else if (doc.length === 11) { clientForm.tipo_pessoa = 'PF'; }
};

const consultarCep = async () => {
    const cep = clientForm.cep.replace(/\D/g, '');
    if (cep.length === 8) {
        try {
            appStore.showSnackbar('Consultando CEP...', 'info');
            const { data } = await axios.get(`https://viacep.com.br/ws/${cep}/json/`);
            if(!data.erro) { clientForm.endereco = data.logradouro || ''; clientForm.bairro = data.bairro || ''; clientForm.cidade = data.localidade || ''; clientForm.estado = data.uf || ''; appStore.showSnackbar('Endereço preenchido.', 'success'); }
            else { appStore.showSnackbar('CEP não encontrado.', 'error'); }
        } catch(e) { appStore.showSnackbar('Erro ao buscar CEP.', 'error'); }
    }
};

let clientSearchTimeout: any;
const handleClientSearch = (val: string) => {
    if (!val || val.length < 3) return;
    clearTimeout(clientSearchTimeout);
    clientSearchTimeout = setTimeout(async () => {
        const { data, error } = await supabase.from('customers_mj').select('id, nome, cnpj, cpf').ilike('nome', `%${val}%`).limit(30);
        if (error) console.error(error);
        if (data) {
            data.forEach((d: any) => {
                const cDoc = d.cnpj || d.cpf || '-';
                if (!auxData.clients.find(c => c.id === d.id)) auxData.clients.push({ id: d.id, nome: d.nome, cpf_cnpj: cDoc });
            });
        }
    }, 500);
};

// --- QUICK CLIENT ---
const saveQuickClient = async () => {
    quickClientModal.loading = true;
    try {
        const docLimpo = quickClientModal.cpf_cnpj.replace(/\D/g, '');
        const isPj = docLimpo.length > 11;
        const payload = {
            nome: quickClientModal.nome,
            cpf: !isPj ? docLimpo : null,
            cnpj: isPj ? docLimpo : null,
            telefone: quickClientModal.telefone,
            tipo_pessoa: isPj ? 'PJ' : 'PF'
        };
        const { data, error } = await supabase.from('customers_mj').insert(payload).select('id, nome').single();
        if (error) throw error;

        auxData.clients.push({ id: data.id, nome: data.nome, cpf_cnpj: docLimpo });
        localOrderHeader.customer_id = data.id;
        clientForm.nome = data.nome;
        clientForm.cpf_cnpj = docLimpo;
        clientForm.telefone = payload.telefone;
        clientForm.tipo_pessoa = payload.tipo_pessoa;
        clientForm.id = data.id;

        quickClientModal.show = false;
        quickClientModal.nome = ''; quickClientModal.cpf_cnpj = ''; quickClientModal.telefone = '';
        appStore.showSnackbar('Cliente cadastrado e selecionado!', 'success');
    } catch(e: any) {
        appStore.showSnackbar('Erro ao cadastrar cliente: ' + e.message, 'error');
    } finally {
        quickClientModal.loading = false;
    }
};

// --- ITENS ---
const openAddItemModal = () => { Object.assign(newItemForm, { fabric_type: '', size: 'U', quantity: 1, unit_price: 0, gestao_click_product_id: '', ncm: '', sku: '' }); showAddItemModal.value = true; };
const onNewItemSelect = (val: string) => { const prod = auxData.products.find(p => p.name === val); if(prod) { newItemForm.gestao_click_product_id = prod.code; newItemForm.unit_price = parseFloat(prod.valor_venda || '0'); newItemForm.ncm = prod.ncm; newItemForm.sku = prod.code; } };

const confirmAddItem = () => {
    const totalVal = (Number(newItemForm.quantity) * Number(newItemForm.unit_price)).toFixed(2);
    localItems.value.push({
        fabric_type: newItemForm.fabric_type, size: newItemForm.size, display_quantity: Number(newItemForm.quantity),
        unit_price: Number(newItemForm.unit_price), total_value_items: totalVal, codigo: newItemForm.sku, ncm: newItemForm.ncm,
        gestao_click_product_id: newItemForm.gestao_click_product_id, excluded_from_invoice: false, id: undefined
    });
    recalcTotal(); showAddItemModal.value = false;
};

const recalcItem = (item: any) => { item.total_value_items = (Number(item.display_quantity) * Number(item.unit_price)).toFixed(2); recalcTotal(); };
const recalcTotal = () => { localOrderHeader.total_value = localItems.value.reduce((acc, i) => { if (i.excluded_from_invoice) return acc; return acc + Number(i.total_value_items); }, 0); };
const toggleItemExclusion = (idx: number) => { const item = localItems.value[idx]; item.excluded_from_invoice = !item.excluded_from_invoice; recalcTotal(); };
const removeItem = (idx: number) => { const item = localItems.value[idx]; if (item.id) itemsToDelete.value.push(item.id); localItems.value.splice(idx, 1); recalcTotal(); };
const onItemSelect = (item: any, val: string) => { const prod = auxData.products.find(p => p.name === val); if(prod) { item.gestao_click_product_id = prod.code; item.unit_price = parseFloat(prod.valor_venda || '0'); item.codigo = prod.code; item.ncm = prod.ncm; recalcItem(item); } };

// --- PARCELAS ---
const updateInstallmentDescriptions = () => {
    const orderNumber = localOrder.value?.order_number || 'S/N';
    const total = installments.value.length;
    installments.value.forEach((inst, index) => {
        const isSignal = String(inst.description || '').toLowerCase().includes('sinal') || inst.is_signal || inst.status === 'pago';
        let baseName = 'Parcela';
        if (isSignal) { baseName = 'Sinal'; } else if (index === total - 1 && !isSignal) { baseName = 'Restante'; }
        inst.description = `${baseName} ${index + 1}/${total} - Pedido #${orderNumber}`;
    });
};

const addInstallment = () => {
    let nextDate = new Date();
    if (installments.value.length > 0) { const lastInst = installments.value[installments.value.length - 1]; nextDate = addDays(parseISO(lastInst.due_date), daysGap.value); }
    const dateStr = format(nextDate, 'yyyy-MM-dd');
    installments.value.push({ description: `Nova Parcela`, value: 0, due_date: dateStr, competence_date: dateStr, status: 'em_aberto', bank_account_id: getDefaultBankId(), chart_of_accounts_id: getDefaultChartId(), order_id: null, customer_id: localOrderHeader.customer_id });
    updateInstallmentDescriptions();
};

const cloneInstallment = (idx: number) => { const { id, is_virtual, ...rest } = installments.value[idx]; installments.value.splice(idx + 1, 0, { ...rest, id: null, is_virtual: true }); updateInstallmentDescriptions(); };
const removeInstallment = (idx: number) => { installments.value.splice(idx, 1); updateInstallmentDescriptions(); };
const distributeValuesEvenly = () => { const totalOrder = localOrderHeader.total_value; const paidInstallments = installments.value.filter(i => i.status === 'pago'); const openInstallments = installments.value.filter(i => i.status !== 'pago'); if (openInstallments.length === 0) return; const totalPaid = paidInstallments.reduce((acc, i) => acc + (Number(i.value) || 0), 0); const remainingToDistribute = Number((totalOrder - totalPaid).toFixed(2)); const count = openInstallments.length; const rawShare = Math.floor((remainingToDistribute / count) * 100) / 100; let distributedSoFar = 0; openInstallments.forEach((inst, index) => { if (index === count - 1) { inst.value = Number((remainingToDistribute - distributedSoFar).toFixed(2)); } else { inst.value = rawShare; distributedSoFar += rawShare; } }); };
const updateStatus = (inst: any, status: string) => { inst.status = status; if (status === 'pago' && !inst.payment_date) inst.payment_date = new Date().toISOString().split('T')[0]; };

// --- CARREGAMENTO INICIAL ---
const fetchAuxiliaryData = async () => {
    try {
        const [banks, charts, methods, clients, profiles, stock] = await Promise.all([
            supabase.from('finance_accounts').select('id, name').eq('is_active', true),
            supabase.from('finance_chart_of_accounts').select('id, name').eq('type', 'Receita'),
            supabase.from('finance_payment_methods').select('id, name').eq('is_active', true).order('name'),
            supabase.from('customers_mj').select('id, nome, cpf, cnpj').limit(50).order('nome'),
            supabase.from('profiles').select('id, full_name'),
            supabase.from('stock').select('id, fabric_type, barcode, gestao_click_id, ncm, base_price, unit_of_measure, rendimento')
        ]);
        auxData.bankAccounts = banks.data || []; auxData.chartOfAccounts = charts.data || []; auxData.paymentMethods = methods.data || [];
        auxData.clients = (clients.data || []).map(c => ({ id: c.id, nome: c.nome, cpf_cnpj: c.cnpj || c.cpf || '-' }));
        auxData.salespeople = profiles.data || [];

        const uniqueProducts = new Map();
        (stock.data || []).forEach(s => {
            const n = s.fabric_type;
            if (n && !uniqueProducts.has(n)) { uniqueProducts.set(n, { name: n, code: s.barcode || s.gestao_click_id || 'S/N', ncm: s.ncm || 'S/N', valor_venda: s.base_price }); }
        });
        auxData.products = Array.from(uniqueProducts.values()).sort((a,b) => a.name.localeCompare(b.name));
    } catch (e) { console.error('Erro aux:', e); }
};

const fetchOrderData = async (sale: any) => {
    isLoadingData.value = true;
    installments.value = []; localItems.value = []; localOrder.value = null; itemsToDelete.value = [];

    try {
        localOrder.value = sale;
        localOrderHeader.total_value = Number(sale.total_value) || 0;
        localOrderHeader.customer_id = sale.customer_id;
        localOrderHeader.vendedor_id = sale.seller_id;
        localOrderHeader.notes = sale.notes || '';
        clientForm.nome = sale.customer_name || '';

        if (sale.customer_id) loadClientDetails(sale.customer_id);

        if (sale.items && Array.isArray(sale.items)) {
            localItems.value = sale.items.map((i: any, index: number) => {
                const stockProd = auxData.products.find(p => p.name === (i.produto?.nome_produto || i.descricao));
                return {
                    id: i.id || `temp_${index}`,
                    fabric_type: i.produto?.nome_produto || i.descricao || 'Item',
                    display_quantity: Number(i.produto?.quantidade || i.quantidade || 1),
                    unit_price: Number(i.produto?.valor_unitario || i.valor_unitario || 0),
                    total_value_items: Number(i.produto?.valor_total || i.valor_total || 0),
                    size: i.produto?.tamanho || i.tamanho || 'U',
                    codigo: stockProd?.code || i.produto?.codigo || i.codigo || 'S/N',
                    ncm: stockProd?.ncm || i.produto?.ncm || i.ncm || 'S/N',
                    excluded_from_invoice: !!i.excluded_from_invoice
                }
            });
        }

        const { data: recs } = await supabase.from('finance_receivables')
            .select('*')
            .eq('store_sale_id', sale.id)
            .order('due_date');

        if (recs && recs.length > 0) {
            installments.value = recs.map(r => ({ ...r, chart_of_accounts_id: r.chart_of_accounts_id || getDefaultChartId(), bank_account_id: r.bank_account_id || getDefaultBankId() }));
        }
        updateInstallmentDescriptions();
    } catch (e) { console.error(e); } finally { isLoadingData.value = false; }
};

const loadClientDetails = async (clientId: string) => {
    try {
        const { data } = await supabase.from('customers_mj').select('*').eq('id', clientId).single();
        if (data) {
            const docVal = data.cnpj || data.cpf || '';
            const isPj = data.cnpj ? true : (data.tipo_pessoa === 'PJ');
            Object.assign(clientForm, {
                id: data.id,
                tipo_pessoa: isPj ? 'PJ' : 'PF',
                nome: data.nome,
                nome_fantasia: data.nome_fantasia,
                cpf_cnpj: docVal,
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

// --- FATURAR DIRETO DO MODAL ---
const faturarAgora = async () => {
    if (!localOrderHeader.customer_id) {
        appStore.showSnackbar("Erro: Cadastre e selecione o cliente desta venda antes de faturar!", "error");
        return;
    }

    if (installments.value.length === 0) {
        const today = new Date().toISOString().split('T')[0];
        installments.value.push({
            description: `PDV #${localOrder.value.order_number}`,
            value: localOrderHeader.total_value,
            due_date: today,
            competence_date: today,
            status: 'pago',
            payment_date: today,
            bank_account_id: getDefaultBankId(),
            chart_of_accounts_id: getDefaultChartId(),
            payment_method_id: auxData.paymentMethods[0]?.id || null,
            order_id: null,
            customer_id: localOrderHeader.customer_id,
            id: null,
            is_virtual: true
        });
    } else {
        installments.value.forEach(inst => {
            inst.status = 'pago';
            if (!inst.payment_date) inst.payment_date = inst.due_date || new Date().toISOString().split('T')[0];
        });
    }

    localOrder.value.financial_status = 'Faturado';
    await saveAllChanges();
};

// --- SAVE ---
const saveAllChanges = async () => {
    if (!localOrderHeader.customer_id) {
        appStore.showSnackbar("Erro: Selecione ou cadastre o cliente antes de salvar!", "error");
        return;
    }

    if (!confirm("Salvar todas as edições deste pedido?")) return;
    isSaving.value = true;
    try {
        const invalidInstallments = installments.value.filter(i => !i.due_date || !i.competence_date || i.value === "" || i.value === null);
        if (invalidInstallments.length > 0) { appStore.showSnackbar("Existem parcelas sem Data ou Valor.", "warning"); isSaving.value = false; return; }

        if (clientForm.id) {
            const docLimpo = clientForm.cpf_cnpj ? clientForm.cpf_cnpj.replace(/\D/g, '') : '';
            const isPj = clientForm.tipo_pessoa === 'PJ' || docLimpo.length > 11;

            const payloadToUpdate: any = {
                tipo_pessoa: clientForm.tipo_pessoa,
                nome: clientForm.nome,
                nome_fantasia: clientForm.nome_fantasia,
                cpf: !isPj ? docLimpo : null,
                cnpj: isPj ? docLimpo : null,
                ie: clientForm.ie,
                email: clientForm.email,
                telefone: clientForm.telefone,
                cep: clientForm.cep,
                endereco: clientForm.endereco,
                numero: clientForm.numero,
                bairro: clientForm.bairro,
                cidade: clientForm.cidade,
                estado: clientForm.estado,
                situacao: clientForm.situacao
            };
            const { error: errUpdate } = await supabase.from('customers_mj').update(payloadToUpdate).eq('id', clientForm.id);
            if (errUpdate) console.error("Erro ao atualizar cliente:", errUpdate);
        }

        const updatedJsonItems = localItems.value.map(i => ({
             produto: { nome_produto: i.fabric_type, quantidade: i.display_quantity, valor_unitario: i.unit_price, valor_total: i.total_value_items, tamanho: i.size, codigo: i.codigo, ncm: i.ncm },
             observacoes: i.notes || null,
             excluded_from_invoice: i.excluded_from_invoice
        }));

        const s = auxData.salespeople.find(x => x.id === localOrderHeader.vendedor_id);

        // Faz o UPDATE com .select() para forçar o Supabase a devolver o que alterou
        const { data: updateData, error: updateError } = await supabase.from('store_sales').update({
             items: updatedJsonItems,
             total_value: localOrderHeader.total_value,
             customer_id: localOrderHeader.customer_id,
             customer_name: clientForm.nome || localOrder.value.customer_name,
             seller_id: localOrderHeader.vendedor_id,
             seller_name: s ? s.full_name : localOrder.value.seller_name,
             notes: localOrderHeader.notes,
             financial_status: localOrder.value.financial_status
        })
        .eq('id', localOrder.value.id)
        .select(); // <--- ISSO AQUI É A BALA DE PRATA

        // Trava 1: Erro real de sintaxe
        if (updateError) throw updateError;

        // Trava 2: Erro silencioso do RLS (Se retornar vazio, o RLS bloqueou)
        if (!updateData || updateData.length === 0) {
            throw new Error("O banco bloqueou a atualização silenciosamente! Verifique o RLS de store_sales.");
        }

        const currentIds = installments.value.map(i => i.id).filter(Boolean);
        const { data: dbRecs } = await supabase.from('finance_receivables')
            .select('id, status')
            .eq('store_sale_id', localOrder.value.id);

        if (dbRecs) {
            const toDel = dbRecs.filter(r => !currentIds.includes(r.id) && r.status !== 'pago').map(r => r.id);
            if (toDel.length > 0) await supabase.from('finance_receivables').delete().in('id', toDel);
        }

const allItemsPayload = installments.value.map((inst, idx) => {
            const { id, is_virtual, ...rest } = inst;
            const methodName = auxData.paymentMethods.find(m => m.id === inst.payment_method_id)?.name || 'Parcela';
            return {
                ...rest,
                company_id: companyStore.context !== 'global' ? companyStore.context : null,
                order_id: null,
                store_sale_id: localOrder.value.id,
                order_number: Number(localOrder.value.order_number),
                customer_id: localOrderHeader.customer_id,
                entity_name: clientForm.nome || localOrder.value.customer_name || 'Consumidor Final',
                description: inst.description || `PDV #${localOrder.value.order_number} - ${methodName}`,
                value: Number(inst.value),
                paid_value: inst.status === 'pago' ? Number(inst.value) : 0,
                due_date: inst.due_date,
                competence_date: inst.competence_date || inst.due_date,
                payment_date: inst.status === 'pago' ? (inst.payment_date || inst.due_date) : null,

                // 👇 AQUI ESTÁ A CORREÇÃO MÁGICA 👇
                paid_at: inst.status === 'pago' ? (inst.paid_at || new Date().toISOString()) : null,

                status: inst.status,
                bank_account_id: inst.bank_account_id || getDefaultBankId(),
                payment_method_id: inst.payment_method_id || auxData.paymentMethods[0]?.id || null,
                chart_of_accounts_id: inst.chart_of_accounts_id || getDefaultChartId()
            }
        });

        const toInsert = allItemsPayload.filter((i, idx) => !installments.value[idx].id);
        const toUpdate = allItemsPayload.filter((i, idx) => installments.value[idx].id).map((i, idx) => ({ ...i, id: installments.value[idx].id }));

        if (toInsert.length > 0) {
            for (const item of toInsert) {
                const { error } = await supabase.from('finance_receivables').insert(item);
                if (error && error.code !== '23505') console.warn(error);
            }
        }
        if (toUpdate.length > 0) await supabase.from('finance_receivables').upsert(toUpdate);

        appStore.showSnackbar("Venda de balcão atualizada!", "success");
        emit('refresh'); closeModal();
    } catch (e: any) { appStore.showSnackbar("Erro: " + e.message, "error"); } finally { isSaving.value = false; }
};

// --- IMPRESSÃO ---
const imageToBase64 = async (url: string): Promise<string> => {
  try { const res = await fetch(url); const blob = await res.blob(); return new Promise((resolve) => { const reader = new FileReader(); reader.onload = () => resolve(String(reader.result)); reader.readAsDataURL(blob); }); } catch(e) { return ''; }
};

const printNonFiscalReceipt = async () => {
    appStore.showSnackbar('Gerando recibo 80mm...', 'info');
    try {
        const pageW = 80;
        const estHeight = 150 + (localItems.value.length * 10) + (installments.value.length * 5) + (localOrderHeader.notes ? 20 : 0);
        const doc = new jsPDF({ orientation: "p", unit: "mm", format: [pageW, estHeight] });
        let y = 5;

        try { const logoB64 = await imageToBase64(logoCajuia); const logoW = 36; const logoH = 16; doc.addImage(logoB64, "PNG", (pageW / 2) - (logoW / 2), y, logoW, logoH); y += logoH + 4; } catch (e) { }

        doc.setFont("helvetica", "bold"); doc.setFontSize(12);
        doc.text(companyStore.currentCompanyName, pageW / 2, y, { align: "center" }); y += 5;
        doc.setFontSize(8); doc.setFont("helvetica", "normal");

        doc.setFont("helvetica", "bold"); doc.setFontSize(10);
        doc.text("RECIBO DE VENDA (NÃO FISCAL)", pageW / 2, y, { align: "center" }); y += 6;

        doc.setFont("helvetica", "normal"); doc.setFontSize(8);
        doc.text(`Venda: #${localOrder.value.order_number} - Data: ${formatDate(localOrder.value.date_sale)}`, pageW / 2, y, { align: "center" }); y += 8;

        const cName = clientForm.nome || localOrder.value.customer_name || 'Consumidor Final';
        const cDoc = clientForm.cpf_cnpj || '';
        const s = auxData.salespeople.find(x => x.id === localOrderHeader.vendedor_id);
        const sName = s ? s.full_name : localOrder.value.seller_name;

        doc.setFont("helvetica", "bold"); doc.text("DADOS DA VENDA", 2, y); y += 4;
        doc.setFont("helvetica", "normal"); doc.text(`Cliente: ${cName}`, 2, y); y += 4;
        if(cDoc) { doc.text(`CPF/CNPJ: ${cDoc}`, 2, y); y += 4; }
        doc.text(`Vendedor: ${sName}`, 2, y); y += 4;
        doc.setLineWidth(0.2); doc.line(2, y, pageW - 2, y); y += 4;
        doc.setFont("helvetica", "bold"); doc.text("QTD   DESCRIÇÃO              TOTAL", 2, y); y += 4;
        doc.line(2, y, pageW - 2, y); y += 4;

        doc.setFont("helvetica", "normal");
        localItems.value.forEach((item: any) => {
            if (item.excluded_from_invoice) return;
            const descText = `${item.fabric_type} (Tam: ${item.size})`;
            const desc = doc.splitTextToSize(descText, 40);
            doc.text(`${item.display_quantity} UN`, 2, y); doc.text(desc, 16, y); doc.text(`${formatCurrency(item.total_value_items)}`, pageW - 2, y, { align: "right" });
            y += (desc.length * 4);
        });
        doc.line(2, y, pageW - 2, y); y += 5;

        doc.setFont("helvetica", "bold"); doc.setFontSize(12);
        doc.text(`TOTAL R$:`, 2, y); doc.text(formatCurrency(localOrderHeader.total_value), pageW - 2, y, { align: "right" }); y += 6;

        doc.setFontSize(8); doc.setFont("helvetica", "normal");
        if (installments.value.length > 0) {
            const pmap = new Map(auxData.paymentMethods.map(p => [p.id, p.name]));
            const pgtosText = installments.value.map(p => `${pmap.get(p.payment_method_id) || 'Dinheiro'}: ${formatCurrency(p.value)}`).join(' | ');
            const splitPgtos = doc.splitTextToSize(`PGTO: ${pgtosText}`, pageW - 4); doc.text(splitPgtos, 2, y); y += (splitPgtos.length * 4) + 2;
        }

        if(localOrderHeader.notes) { const splitNotes = doc.splitTextToSize("Obs: " + localOrderHeader.notes, pageW - 4); doc.text(splitNotes, 2, y); y += (splitNotes.length * 4) + 2; }
        y += 4; doc.setFont("helvetica", "bold"); doc.text("OBRIGADO PELA PREFERÊNCIA!", pageW / 2, y, { align: "center" });

        doc.autoPrint(); window.open(URL.createObjectURL(doc.output('blob')), '_blank');
    } catch(e) { appStore.showSnackbar('Erro ao imprimir recibo', 'error'); }
};

const printA4Detailed = async () => {
    appStore.showSnackbar('Gerando Romaneio A4...', 'info');
    try {
        const doc = new jsPDF({ orientation: "p", unit: "mm", format: "a4" });
        const pageW = doc.internal.pageSize.getWidth(); const pageH = doc.internal.pageSize.getHeight();
        const M = 12; const boxW = pageW - M * 2;

        doc.setDrawColor(150); doc.setLineWidth(0.3); doc.rect(M, 10, boxW, 28);
        try { const logoBase64 = await imageToBase64(logoCajuia); doc.addImage(logoBase64, "PNG", M + 4, 14, 40, 20); } catch (e) { }

        doc.setFont("helvetica", "bold"); doc.setFontSize(14);
        doc.text("ROMANEIO DE VENDA", pageW / 2, 20, { align: "center" });
        doc.setFontSize(10); doc.setTextColor(100);
        doc.text(`Empresa: ${companyStore.currentCompanyName}`, pageW / 2, 26, { align: "center" });
        doc.text(`Data: ${formatDate(localOrder.value.date_sale)}`, pageW / 2, 32, { align: "center" });

        doc.setFontSize(12); doc.setTextColor(200, 50, 50);
        doc.text(`PEDIDO #${localOrder.value.order_number}`, pageW - M - 4, 25, { align: "right" });

        let currentY = 44;
        doc.setTextColor(0); doc.setFontSize(10);

        doc.setFillColor(240); doc.rect(M, currentY, (boxW/2) - 2, 30, "F"); doc.rect(M, currentY, (boxW/2) - 2, 30, "S");
        doc.setFont("helvetica", "bold"); doc.text("DADOS DO CLIENTE", M + 4, currentY + 6);
        doc.setFont("helvetica", "normal"); doc.setFontSize(9);
        const cName = clientForm.nome || localOrder.value.customer_name || 'Consumidor Final';
        const cDoc = clientForm.cpf_cnpj || 'Não Informado';
        const cPhone = clientForm.telefone || 'Não Informado';
        doc.text(`Nome: ${cName}`, M + 4, currentY + 13);
        doc.text(`Doc: ${cDoc}`, M + 4, currentY + 19);
        doc.text(`Tel: ${cPhone}`, M + 4, currentY + 25);

        const rightBoxX = M + (boxW/2) + 2;
        doc.setFillColor(240); doc.rect(rightBoxX, currentY, (boxW/2) - 2, 30, "F"); doc.rect(rightBoxX, currentY, (boxW/2) - 2, 30, "S");
        doc.setFont("helvetica", "bold"); doc.setFontSize(10); doc.text("DADOS DO VENDEDOR", rightBoxX + 4, currentY + 6);
        doc.setFont("helvetica", "normal"); doc.setFontSize(9);
        const s = auxData.salespeople.find(x => x.id === localOrderHeader.vendedor_id);
        const sName = s ? s.full_name : localOrder.value.seller_name;
        doc.text(`Nome: ${sName}`, rightBoxX + 4, currentY + 13);
        doc.text(`Status Venda: ${localOrder.value.financial_status?.toUpperCase()}`, rightBoxX + 4, currentY + 25);

        currentY += 36;

        doc.setFont("helvetica", "bold"); doc.setFontSize(11); doc.text("PRODUTOS VENDIDOS", M, currentY);
        currentY += 4;
        const productsBody = localItems.value.filter(i => !i.excluded_from_invoice).map((it: any) => [
            it.codigo || 'S/N',
            it.fabric_type || 'Item',
            it.size || 'U',
            it.display_quantity || 1,
            formatCurrency(it.unit_price),
            formatCurrency(it.total_value_items)
        ]);

        autoTable(doc, {
            startY: currentY, theme: "grid", margin: { left: M, right: M },
            headStyles: { fillColor: [50, 50, 50], textColor: 255, fontStyle: "bold", fontSize: 9 },
            styles: { fontSize: 8.5 }, columnStyles: { 3: { halign: 'center' }, 4: { halign: 'right' }, 5: { halign: 'right' } },
            head: [["CÓDIGO", "PRODUTO", "TAMANHO", "QTD", "VL UNIT", "TOTAL"]],
            body: productsBody
        });

        currentY = (doc as any).lastAutoTable.finalY + 10;

        doc.setFont("helvetica", "bold"); doc.setFontSize(11); doc.text("LANÇAMENTOS FINANCEIROS", M, currentY);
        currentY += 4;
        const pmap = new Map(auxData.paymentMethods.map(p => [p.id, p.name]));
        const paymentsBody = installments.value.map((p: any) => [
            pmap.get(p.payment_method_id) || 'Dinheiro',
            formatDate(p.due_date),
            p.status?.toUpperCase(),
            formatCurrency(p.value)
        ]);

        autoTable(doc, {
            startY: currentY, theme: "grid", margin: { left: M, right: M }, tableWidth: boxW * 0.6,
            headStyles: { fillColor: [100, 150, 100], textColor: 255, fontStyle: "bold", fontSize: 9 },
            styles: { fontSize: 8.5 }, columnStyles: { 2: { halign: 'center' }, 3: { halign: 'right', fontStyle: 'bold' } },
            head: [["MÉTODO DE PAGAMENTO", "DATA", "STATUS", "VALOR (R$)"]],
            body: paymentsBody.length > 0 ? paymentsBody : [["Nenhum lançamento", "-", "-", "-"]]
        });

        const rightInfoX = M + (boxW * 0.6) + 4;
        const rightInfoW = boxW * 0.4 - 4;

        doc.setFillColor(245); doc.rect(rightInfoX, currentY, rightInfoW, 20, "F"); doc.rect(rightInfoX, currentY, rightInfoW, 20, "S");
        doc.setFont("helvetica", "bold"); doc.setFontSize(14);
        doc.text("TOTAL GERAL", rightInfoX + rightInfoW / 2, currentY + 8, { align: "center" });
        doc.setTextColor(0, 100, 0);
        doc.text(formatCurrency(localOrderHeader.total_value), rightInfoX + rightInfoW / 2, currentY + 16, { align: "center" });

        currentY = Math.max((doc as any).lastAutoTable.finalY, currentY + 20) + 10;

        if (localOrderHeader.notes) {
            doc.setTextColor(0); doc.setFont("helvetica", "bold"); doc.setFontSize(10); doc.text("OBSERVAÇÕES DA VENDA:", M, currentY);
            doc.setFont("helvetica", "normal"); doc.setFontSize(9);
            const splitNotes = doc.splitTextToSize(localOrderHeader.notes, boxW);
            doc.text(splitNotes, M, currentY + 6);
            currentY += (splitNotes.length * 5) + 10;
        }

        currentY += 20;
        if (currentY > pageH - 30) { doc.addPage(); currentY = 30; }
        doc.setDrawColor(0); doc.line(M + 20, currentY, M + 80, currentY); doc.line(pageW - M - 80, currentY, pageW - M - 20, currentY);
        doc.setFontSize(9); doc.text("Assinatura do Vendedor", M + 50, currentY + 5, { align: "center" }); doc.text("Assinatura do Cliente", pageW - M - 50, currentY + 5, { align: "center" });

        doc.autoPrint(); window.open(URL.createObjectURL(doc.output('blob')), '_blank');
    } catch(e) { appStore.showSnackbar('Erro ao imprimir A4', 'error'); }
};

watch(() => props.modelValue, (val) => { if (val && props.sale) { fetchAuxiliaryData().then(() => fetchOrderData(props.sale)); } }, { immediate: true });
</script>

<style scoped lang="scss">
.billing-modal-ui { font-family: 'Roboto', sans-serif; }
.lh-1 { line-height: 1; }
.gap-1 { gap: 4px; } .gap-2 { gap: 8px; } .gap-3 { gap: 12px; }
.section-number { width: 28px; height: 28px; display: flex; align-items: center; justify-content: center; border-radius: 6px; font-weight: 900; font-size: 13px; }
.input-label { font-size: 11px; font-weight: 800; text-transform: uppercase; color: #616161; display: block; margin-bottom: 4px; letter-spacing: 0.5px; }
.ui-field :deep(.v-field) { border-radius: 6px !important; border-color: rgba(0,0,0,0.12) !important; }
.ui-field :deep(.v-field__input) { min-height: 40px !important; padding-top: 6px !important; padding-bottom: 6px !important; font-size: 14px; font-weight: 500; }
.row-gap-md { row-gap: 16px; }
.custom-scroll::-webkit-scrollbar { width: 8px; height: 8px; }
.custom-scroll::-webkit-scrollbar-track { background: transparent; }
.custom-scroll::-webkit-scrollbar-thumb { background: #bdbdbd; border-radius: 4px; }
.border-thin { border: 1px solid rgba(0,0,0,0.12) !important; }
.absolute-center { position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%); }

/* 3D Buttons & Chips */
.btn-3d { border-radius: 6px !important; box-shadow: 0 3px 5px rgba(0,0,0,0.15), inset 0 2px 0 rgba(255,255,255,0.25) !important; transition: transform 0.1s ease, box-shadow 0.1s ease; text-transform: none !important; }
.btn-3d:active { transform: translateY(2px); box-shadow: 0 1px 2px rgba(0,0,0,0.15), inset 0 1px 0 rgba(255,255,255,0.2) !important; }
.chip-3d { border-radius: 6px !important; box-shadow: 0 3px 5px rgba(0,0,0,0.12), inset 0 1px 0 rgba(255,255,255,0.25) !important; text-shadow: 0 1px 2px rgba(0,0,0,0.25); }

/* Clean Inputs */
.clean-input { border: none; outline: none; background: transparent; font-size: 13px; padding: 4px 6px; border-radius: 4px; transition: background 0.2s; width: 100%; }
.clean-input:focus { background-color: #e3f2fd; color: #1565C0; font-weight: bold; }
.bg-grey-darken-4 .clean-input:focus { background-color: #37474f; color: #64b5f6; }
.clean-textarea { border: none; outline: none; background: transparent; resize: none; transition: background 0.2s; }
.clean-textarea:focus { background-color: #FFF8E1; border-color: #FFB300 !important; }
.bg-grey-darken-4 .clean-textarea:focus { background-color: #424242; border-color: #ffca28 !important; }

/* Grid Responsivo */
.table-responsive { overflow-x: auto; -webkit-overflow-scrolling: touch; }
.grid-header { z-index: 20; position: sticky; top: 0; box-shadow: 0 4px 6px -4px rgba(0, 0, 0, 0.1); }
.grid-header, .grid-row { display: grid; align-items: stretch; width: 100%; border-bottom: 1px solid rgba(0,0,0,0.08); }
.cell { padding: 8px 10px; display: flex; align-items: center; border-right: 1px solid rgba(0,0,0,0.05); font-size: 13px; }
.cell:last-child { border-right: none; }
.header-text { padding: 12px 10px; font-size: 11px; font-weight: 900; text-transform: uppercase; letter-spacing: 0.5px; display: flex; align-items: center; }
.cell.center, .header-text.center { justify-content: center; text-align: center; }
.cell.right, .header-text.right { justify-content: flex-end; text-align: right; }

.hover-bg-row:hover { background-color: #F8FAFC; cursor: default; }
.bg-grey-darken-4 .hover-bg-row:hover { background-color: #2c2c2c; }

/* Layouts de Colunas */
.grid-items-layout { grid-template-columns: 2fr 100px 1.5fr 140px 140px 140px 100px; min-width: 1100px; }
.grid-payments-layout { grid-template-columns: 120px 140px 1.5fr 180px 160px 160px 120px; min-width: 1200px; }

/* Botões da Tabela */
.action-btn { width: 28px !important; height: 28px !important; border-radius: 6px !important; color: #fff !important; margin: 0 4px; }
.action-clone { background: #199201 !important; }
.action-del { background: #c62828 !important; }

/* Themes & Utils */
.border-white-10 { border-color: rgba(255,255,255,0.1) !important; }
.border-white-20 { border-color: rgba(255,255,255,0.2) !important; }
.border-none { border: none !important; }
.bg-black-20 { background-color: rgba(0,0,0,0.2) !important; }
.bg-white-05 { background-color: rgba(255,255,255,0.05) !important; }
.bg-primary-gradient { background: linear-gradient(135deg, #1976D2, #1565C0); }
.hover-border-primary:hover { border-color: #1976D2 !important; }
</style>
