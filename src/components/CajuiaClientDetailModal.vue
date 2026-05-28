<template>
  <v-dialog
    :model-value="show"
    @update:model-value="close"
    width="1400"
    max-width="98vw"
    height="90vh"
    class="modal-backdrop-blur"
    transition="dialog-bottom-transition"
    scrollable
    persistent
  >
    <v-card class="d-flex flex-column h-100 overflow-hidden border-none" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'glass-detail-card'">

      <div
        class="px-8 py-5 d-flex align-center justify-space-between flex-shrink-0 border-b relative overflow-hidden"
        :class="themeStore.currentMode === 'light' ? 'bg-white border-grey-lighten-2' : 'bg-glass-header border-white-05'"
      >
         <div class="header-bg-glow" :class="clientData.blocked ? 'error' : 'success'" v-if="themeStore.currentMode !== 'light'"></div>

         <div class="d-flex align-center gap-6 relative z-10">
            <div
                class="rounded-xl elevation-4 d-flex align-center justify-center position-relative overflow-hidden border"
                :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-4 border-grey-lighten-2' : 'bg-glass-surface border-white-10'"
                style="width: 72px; height: 72px;"
            >
               <v-avatar size="56" :image="clientData.photo_url || ''" :color="stringToColor(clientData.name)" class="text-white">
                  <span class="text-h5 font-weight-black text-shadow">{{ getInitials(clientData.name) }}</span>
               </v-avatar>
            </div>

            <div>
               <div class="d-flex align-center gap-3 mb-1">
                   <div
                        class="d-flex align-center gap-2 px-2 py-1 rounded border"
                        :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-4 border-grey-lighten-2' : 'bg-white-05 border-white-05'"
                   >
                      <v-icon size="10" :color="clientData.blocked ? 'error' : 'success'" class="icon-pulse">mdi-circle</v-icon>
                      <span class="text-[10px] font-weight-bold text-uppercase letter-spacing-1" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-2' : 'text-white-70'">
                          {{ clientData.blocked ? 'BLOQUEADO' : 'ATIVO' }}
                      </span>
                   </div>
                   <span class="text-overline font-weight-bold letter-spacing-1" :class="themeStore.currentMode === 'light' ? 'text-grey' : 'text-white-30'">
                       ID: #{{ clientData.external_id || clientData.id }}
                   </span>
               </div>
               <h2 class="text-h5 font-weight-black lh-1 mt-1" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white text-shadow'">
                   {{ clientData.name }}
               </h2>
            </div>
         </div>

         <div class="d-flex align-center gap-3">
             <div class="d-flex align-center border rounded-lg pa-1 hidden-sm-and-down" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-glass-surface border-white-10'">
                <v-tooltip text="Relatório PDF" location="bottom" content-class="bg-grey-darken-4 text-white font-weight-bold">
                  <template v-slot:activator="{ props }">
                    <v-btn v-bind="props" icon size="small" variant="text" :color="themeStore.currentMode === 'light' ? 'grey-darken-2' : 'white-70'" @click="printReport" :loading="isPdfGenerating">
                        <v-icon size="20">mdi-printer-outline</v-icon>
                    </v-btn>
                  </template>
                </v-tooltip>
                <v-divider vertical class="my-1 mx-1" :class="themeStore.currentMode === 'light' ? 'border-grey-lighten-2' : 'border-white-10'"></v-divider>
                <v-tooltip text="WhatsApp" location="bottom" content-class="bg-grey-darken-4 text-white font-weight-bold">
                  <template v-slot:activator="{ props }">
                    <v-btn v-bind="props" icon size="small" variant="text" color="success" :href="whatsappLink" target="_blank">
                        <v-icon size="20">mdi-whatsapp</v-icon>
                    </v-btn>
                  </template>
                </v-tooltip>
             </div>
             <v-btn icon variant="text" :color="themeStore.currentMode === 'light' ? 'grey-darken-1' : 'white-70'" class="close-btn" @click="close">
                <v-icon size="28">mdi-close</v-icon>
             </v-btn>
         </div>
      </div>

      <div class="d-flex flex-grow-1 overflow-hidden relative">

          <div
            class="sidebar-panel pa-6 border-r d-flex flex-column overflow-y-auto custom-scrollbar z-20 h-100"
            :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-glass-darker border-white-05'"
          >
              <div class="mb-8 relative">
                 <div class="text-caption font-weight-bold text-uppercase mb-2 d-flex align-center justify-space-between" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-1' : 'text-white-30'">
                    <span>LTV (Total Investido)</span>
                    <v-icon size="16">mdi-finance</v-icon>
                 </div>
                 <div class="kpi-display lh-1 mb-4 text-h3" :class="themeStore.currentMode === 'light' ? 'text-primary' : 'text-white'">
                    {{ formatCurrency(clientData.total_purchases) }}
                 </div>

                 <div class="d-flex align-center gap-3 pa-3 rounded-lg border" :class="themeStore.currentMode === 'light' ? 'bg-white border-grey-lighten-2' : 'bg-white-02 border-white-05'">
                    <div class="icon-circle bg-info-10 text-info">
                       <v-icon size="16">mdi-ticket-percent</v-icon>
                    </div>
                    <div>
                       <div class="text-caption lh-1" :class="themeStore.currentMode === 'light' ? 'text-grey' : 'text-white-50'">Ticket Médio</div>
                       <div class="text-body-2 font-weight-bold" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-3' : 'text-white'">{{ formatCurrency(kpis.avgTicket) }}</div>
                    </div>
                 </div>
              </div>

              <v-divider class="mb-6" :class="themeStore.currentMode === 'light' ? 'border-grey-lighten-2' : 'border-white-05'"></v-divider>

              <div class="mb-6">
                  <div class="d-flex justify-space-between text-[10px] font-weight-bold uppercase mb-1" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-1' : 'text-white-50'">
                      <span>Qualidade do Cadastro</span>
                      <span>{{ profileScore }}%</span>
                  </div>
                  <v-progress-linear :model-value="profileScore" :color="getScoreColor(profileScore)" height="6" rounded :bg-color="themeStore.currentMode === 'light' ? 'grey-lighten-3' : 'rgba(255,255,255,0.1)'"></v-progress-linear>
                  <div v-if="profileScore < 100" class="mt-2 text-[10px] text-warning bg-warning-10 px-2 py-1 rounded border border-warning-20 d-flex align-center">
                      <v-icon start size="10" color="warning">mdi-alert-circle-outline</v-icon>
                      Complete o cadastro para melhor atendimento.
                  </div>
              </div>

              <div class="mt-auto sticky-bottom-sidebar">
                  <div class="pa-4 rounded-xl border" :class="themeStore.currentMode === 'light' ? 'bg-white border-grey-lighten-2' : 'glass-well border-white-05'">
                      <div class="d-flex justify-space-between align-center mb-2">
                          <span class="text-caption font-weight-bold" :class="themeStore.currentMode === 'light' ? 'text-grey' : 'text-white-50'">Última Compra</span>
                          <span class="text-caption font-mono" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-3' : 'text-white'">{{ kpis.lastPurchaseDate }}</span>
                      </div>
                      <div class="d-flex justify-space-between align-center">
                          <span class="text-caption font-weight-bold" :class="themeStore.currentMode === 'light' ? 'text-grey' : 'text-white-50'">Total Pedidos</span>
                          <v-chip size="x-small" :color="themeStore.currentMode === 'light' ? 'primary' : 'white'" variant="outlined" class="font-weight-bold">{{ kpis.totalOrders }}</v-chip>
                      </div>
                  </div>
              </div>
          </div>

          <div class="d-flex flex-column relative flex-grow-1 h-100 min-w-0" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-glass-surface'">

              <div class="d-flex align-center justify-space-between px-6 py-3 border-b flex-shrink-0" :class="themeStore.currentMode === 'light' ? 'border-grey-lighten-2 bg-grey-lighten-5' : 'border-white-05 bg-glass-header'">
                  <v-tabs v-model="tab" color="primary" density="compact" class="bg-transparent">
                      <v-tab value="overview" class="text-caption font-weight-bold text-none rounded-md px-4">Visão Geral</v-tab>
                      <v-tab value="info" class="text-caption font-weight-bold text-none rounded-md px-4">Dados Cadastrais</v-tab>
                      <v-tab value="history" class="text-caption font-weight-bold text-none rounded-md px-4">Histórico</v-tab>
                  </v-tabs>

                  <div v-if="tab === 'info'">
                     <v-fade-transition mode="out-in">
                        <v-btn v-if="!isEditing" color="primary" variant="tonal" size="small" prepend-icon="mdi-pencil" class="font-weight-bold text-none" @click="startEdit">Editar Dados</v-btn>
                        <div v-else class="d-flex gap-2 align-center">
                            <v-btn variant="text" size="small" @click="cancelEdit" :disabled="saving" class="text-none" :color="themeStore.currentMode === 'light' ? 'grey-darken-2' : 'white'">Cancelar</v-btn>
                            <v-btn color="success" variant="flat" size="small" prepend-icon="mdi-content-save-check" class="font-weight-bold text-none" @click="saveEdit" :loading="saving">Salvar</v-btn>
                        </div>
                     </v-fade-transition>
                  </div>
              </div>

              <v-window v-model="tab" class="flex-grow-1 overflow-hidden h-100">

                  <v-window-item value="overview" class="h-100">
                      <div class="h-100 overflow-y-auto custom-scrollbar pa-6">
                          <div class="d-flex align-center justify-space-between mb-4">
                              <div class="text-caption font-weight-bold text-uppercase letter-spacing-1" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-1' : 'text-white-50'">Produtos Favoritos</div>
                              <div class="text-[10px] text-disabled">Baseado no histórico de pedidos</div>
                          </div>

                          <v-table v-if="calculatedTopProducts.length > 0" density="default" class="bg-transparent hover-rows w-100 mb-8" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-3' : 'text-white'">
                              <thead :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-4' : 'bg-glass-darker'">
                                  <tr>
                                      <th class="text-left text-[10px] text-uppercase font-weight-bold pl-4 py-3">Produto</th>
                                      <th class="text-center text-[10px] text-uppercase font-weight-bold py-3">Frequência</th>
                                      <th class="text-center text-[10px] text-uppercase font-weight-bold py-3">Qtd.</th>
                                      <th class="text-right text-[10px] text-uppercase font-weight-bold pr-4 py-3">Total</th>
                                  </tr>
                              </thead>
                              <tbody>
                                  <tr v-for="(prod, i) in calculatedTopProducts" :key="i" class="border-b transition-colors" :class="themeStore.currentMode === 'light' ? 'border-grey-lighten-2' : 'border-white-05'">
                                      <td class="pl-4 py-3">
                                          <div class="d-flex align-center">
                                              <v-avatar size="32" class="mr-3 rounded border" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-4 border-grey-lighten-2' : 'bg-white-05 border-white-05'">
                                                  <v-icon size="16" :color="themeStore.currentMode === 'light' ? 'grey-darken-2' : 'white-70'">mdi-hanger</v-icon>
                                              </v-avatar>
                                              <div class="font-weight-bold text-caption">{{ prod.name }}</div>
                                          </div>
                                      </td>
                                      <td class="text-center py-3"><v-chip size="x-small" :color="themeStore.currentMode === 'light' ? 'grey-darken-2' : 'white'" variant="outlined" class="font-mono">{{ prod.frequency }}x</v-chip></td>
                                      <td class="text-center py-3 text-caption opacity-70">{{ prod.quantity }} un</td>
                                      <td class="text-right pr-4 py-3 text-body-2 font-weight-black text-success font-mono">{{ formatCurrency(prod.total) }}</td>
                                  </tr>
                              </tbody>
                          </v-table>

                          <div v-else class="d-flex flex-column align-center justify-center pa-12 border border-dashed rounded-xl mb-8" :class="themeStore.currentMode === 'light' ? 'border-grey-lighten-2 text-grey' : 'border-white-10 text-white-30'">
                              <v-icon size="40" class="mb-2 opacity-50">mdi-package-variant</v-icon>
                              <div class="text-caption">Sem histórico de produtos.</div>
                          </div>

                          <div class="text-caption font-weight-bold text-uppercase letter-spacing-1 mb-2" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-1' : 'text-white-50'">Anotações Rápidas</div>
                          <div class="pa-1 rounded-lg border" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'glass-well border-white-05'">
                              <v-textarea placeholder="Escreva observações importantes sobre este cliente..." variant="plain" class="text-body-2" hide-details no-resize rows="6" :color="themeStore.currentMode === 'light' ? 'primary' : 'white'"></v-textarea>
                          </div>
                      </div>
                  </v-window-item>

                  <v-window-item value="info" class="h-100">
                      <div class="h-100 overflow-y-auto custom-scrollbar pa-8">
                          <div class="max-w-900 mx-auto">

                              <div v-if="!isEditing" class="d-flex flex-column gap-6 animate-slide-up">

                                  <div class="pa-6 rounded-xl border relative overflow-hidden" :class="themeStore.currentMode === 'light' ? 'bg-white border-grey-lighten-2' : 'glass-panel border-white-05'">
                                      <div class="d-flex align-center justify-space-between mb-6 relative z-10">
                                          <div class="d-flex align-center gap-3">
                                              <div class="icon-box bg-primary-10 text-primary"><v-icon>mdi-card-account-details-outline</v-icon></div>
                                              <div>
                                                  <div class="text-subtitle-2 font-weight-bold" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-3' : 'text-white'">Identificação</div>
                                                  <div class="text-[10px]" :class="themeStore.currentMode === 'light' ? 'text-grey' : 'text-white-50'">Dados legais</div>
                                              </div>
                                          </div>
                                          <v-chip size="small" color="success" variant="tonal" class="font-weight-bold" v-if="clientData.cpf_cnpj">Validado</v-chip>
                                      </div>

                                      <v-row>
                                          <v-col cols="12" md="6">
                                              <div class="info-field-group" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-white-02 border-white-05'">
                                                  <span class="field-label" :class="themeStore.currentMode === 'light' ? 'text-grey' : 'text-white-40'">Nome / Razão Social</span>
                                                  <div class="d-flex align-center justify-space-between">
                                                      <span class="text-body-2 font-weight-medium" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">{{ clientData.name }}</span>
                                                      <v-btn icon size="x-small" variant="text" class="opacity-50" @click="copyToClipboard(clientData.name)"><v-icon size="14">mdi-content-copy</v-icon></v-btn>
                                                  </div>
                                              </div>
                                          </v-col>
                                          <v-col cols="12" md="6">
                                              <div class="info-field-group" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-white-02 border-white-05'">
                                                  <span class="field-label" :class="themeStore.currentMode === 'light' ? 'text-grey' : 'text-white-40'">Documento (CPF/CNPJ)</span>
                                                  <div class="d-flex align-center justify-space-between">
                                                      <span class="text-body-2 font-mono" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">{{ formatDoc(clientData.cpf_cnpj) }}</span>
                                                      <v-btn icon size="x-small" variant="text" class="opacity-50" @click="copyToClipboard(clientData.cpf_cnpj)"><v-icon size="14">mdi-content-copy</v-icon></v-btn>
                                                  </div>
                                              </div>
                                          </v-col>
                                      </v-row>
                                  </div>

                                  <div class="pa-6 rounded-xl border relative" :class="themeStore.currentMode === 'light' ? 'bg-white border-grey-lighten-2' : 'glass-panel border-white-05'">
                                      <div class="d-flex align-center gap-3 mb-6">
                                          <div class="icon-box bg-info-10 text-info"><v-icon>mdi-contacts-outline</v-icon></div>
                                          <div>
                                              <div class="text-subtitle-2 font-weight-bold" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-3' : 'text-white'">Contatos</div>
                                              <div class="text-[10px]" :class="themeStore.currentMode === 'light' ? 'text-grey' : 'text-white-50'">Email e telefone</div>
                                          </div>
                                      </div>

                                      <v-row>
                                          <v-col cols="12" md="6">
                                              <div class="info-field-group" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-white-02 border-white-05'">
                                                  <div class="d-flex align-center justify-space-between mb-1">
                                                      <span class="field-label" :class="themeStore.currentMode === 'light' ? 'text-grey' : 'text-white-40'">E-mail</span>
                                                  </div>
                                                  <div class="d-flex align-center justify-space-between">
                                                      <span class="text-body-2 text-truncate" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">{{ editForm.email || 'Não informado' }}</span>
                                                      <v-btn v-if="editForm.email" icon size="x-small" variant="text" color="primary" :href="`mailto:${editForm.email}`"><v-icon size="14">mdi-open-in-new</v-icon></v-btn>
                                                  </div>
                                              </div>
                                          </v-col>
                                          <v-col cols="12" md="6">
                                              <div class="info-field-group" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-white-02 border-white-05'">
                                                  <div class="d-flex align-center justify-space-between mb-1">
                                                      <span class="field-label" :class="themeStore.currentMode === 'light' ? 'text-grey' : 'text-white-40'">Telefone</span>
                                                  </div>
                                                  <div class="d-flex align-center justify-space-between">
                                                       <span class="text-body-2 font-mono" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">{{ editForm.phone || 'Não informado' }}</span>
                                                       <v-btn v-if="editForm.phone" icon size="x-small" variant="text" color="success" :href="whatsappLink" target="_blank"><v-icon size="14">mdi-whatsapp</v-icon></v-btn>
                                                  </div>
                                              </div>
                                          </v-col>
                                      </v-row>
                                  </div>

                                  <div class="pa-6 rounded-xl border relative" :class="themeStore.currentMode === 'light' ? 'bg-white border-grey-lighten-2' : 'glass-panel border-white-05'">
                                      <div class="d-flex align-center justify-space-between mb-6">
                                          <div class="d-flex align-center gap-3">
                                              <div class="icon-box bg-warning-10 text-warning"><v-icon>mdi-map-marker-radius-outline</v-icon></div>
                                              <div>
                                                  <div class="text-subtitle-2 font-weight-bold" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-3' : 'text-white'">Endereço</div>
                                                  <div class="text-[10px]" :class="themeStore.currentMode === 'light' ? 'text-grey' : 'text-white-50'">Entrega e cobrança</div>
                                              </div>
                                          </div>
                                      </div>

                                      <div v-if="!editForm.address.logradouro">
                                          <v-alert type="warning" variant="tonal" density="compact" class="text-caption">
                                              <strong>Endereço incompleto!</strong> Atualize para permitir entregas.
                                          </v-alert>
                                      </div>

                                      <div v-else class="pa-4 rounded-lg border d-flex align-start justify-space-between" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-white-02 border-white-05'">
                                          <div>
                                              <div class="text-body-1 font-weight-bold mb-1" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">
                                                  {{ editForm.address.logradouro }}, {{ editForm.address.numero }} <span v-if="editForm.address.complemento">({{ editForm.address.complemento }})</span>
                                              </div>
                                              <div class="text-body-2" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-1' : 'text-white-70'">{{ editForm.address.bairro }}</div>
                                              <div class="text-caption mt-2 font-mono opacity-70">{{ editForm.address.cidade }} / {{ editForm.address.uf }} • CEP: {{ editForm.address.cep }}</div>
                                          </div>
                                          <v-btn icon size="small" variant="text" class="opacity-50" @click="copyToClipboard(`${editForm.address.logradouro}, ${editForm.address.numero} - ${editForm.address.cidade}`)">
                                              <v-icon>mdi-content-copy</v-icon>
                                          </v-btn>
                                      </div>
                                  </div>
                              </div>

                              <div v-else class="pa-8 rounded-xl border border-primary animate-slide-up relative" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'glass-panel'">
                                  <div class="text-subtitle-1 font-weight-bold mb-6 d-flex align-center" :class="themeStore.currentMode === 'light' ? 'text-primary' : 'text-white'">
                                      <v-icon color="primary" class="mr-2">mdi-pencil-circle</v-icon> Editando Informações
                                  </div>

                                  <v-row>
                                      <v-col cols="12" md="6">
                                          <v-text-field
                                              label="E-mail"
                                              v-model="editForm.email"
                                              density="comfortable"
                                              variant="outlined"
                                              :bg-color="themeStore.currentMode === 'light' ? 'white' : undefined"
                                              hide-details="auto"
                                              prepend-inner-icon="mdi-email"
                                          ></v-text-field>
                                      </v-col>
                                      <v-col cols="12" md="6">
                                          <v-text-field
                                              label="Telefone / WhatsApp"
                                              v-model="editForm.phone"
                                              density="comfortable"
                                              variant="outlined"
                                              :bg-color="themeStore.currentMode === 'light' ? 'white' : undefined"
                                              hide-details="auto"
                                              prepend-inner-icon="mdi-phone"
                                          ></v-text-field>
                                      </v-col>

                                      <v-col cols="12"><div class="text-caption font-weight-bold uppercase mt-4 mb-2 opacity-70">Endereço</div></v-col>

                                      <v-col cols="12" sm="3">
                                          <v-text-field label="CEP" v-model="editForm.address.cep" density="comfortable" variant="outlined" append-inner-icon="mdi-magnify" @click:append-inner="fetchCep" @blur="fetchCep" :loading="loadingCep" hide-details="auto"></v-text-field>
                                      </v-col>
                                      <v-col cols="12" sm="6">
                                          <v-text-field label="Logradouro" v-model="editForm.address.logradouro" density="comfortable" variant="outlined" hide-details="auto"></v-text-field>
                                      </v-col>
                                      <v-col cols="12" sm="3">
                                          <v-text-field label="Número" v-model="editForm.address.numero" density="comfortable" variant="outlined" hide-details="auto"></v-text-field>
                                      </v-col>
                                      <v-col cols="12" sm="4">
                                          <v-text-field label="Bairro" v-model="editForm.address.bairro" density="comfortable" variant="outlined" hide-details="auto"></v-text-field>
                                      </v-col>
                                      <v-col cols="12" sm="5">
                                          <v-text-field label="Cidade" v-model="editForm.address.cidade" density="comfortable" variant="outlined" hide-details="auto"></v-text-field>
                                      </v-col>
                                      <v-col cols="12" sm="3">
                                          <v-text-field label="UF" v-model="editForm.address.uf" density="comfortable" variant="outlined" hide-details="auto"></v-text-field>
                                      </v-col>
                                  </v-row>
                              </div>

                          </div>
                      </div>
                  </v-window-item>

                  <v-window-item value="history" class="h-100">
                      <div class="h-100 overflow-y-auto custom-scrollbar pa-6">
                          <div v-if="historyLoading" class="d-flex justify-center py-12"><v-progress-circular indeterminate color="primary" size="40"></v-progress-circular></div>
                          <div v-else-if="historyOrders.length === 0" class="d-flex flex-column align-center justify-center py-12 opacity-50">
                              <v-icon size="48" class="mb-3">mdi-receipt-text-off</v-icon>
                              <span class="text-caption">Nenhum pedido encontrado.</span>
                          </div>
                          <div v-else class="timeline-container relative pl-6 border-l ml-4" :class="themeStore.currentMode === 'light' ? 'border-grey-lighten-2' : 'border-white-10'">
                              <div v-for="(order, i) in historyOrders" :key="order.id" class="timeline-item mb-6 relative group fade-in-entry" :style="{ animationDelay: `${i * 50}ms` }">
                                  <div class="absolute -left-[29px] top-4 w-3 h-3 rounded-full border-2 border-surface" :class="getOrderStatusColorClass(order.status)"></div>
                                  <div class="text-caption font-mono mb-2 d-flex align-center gap-2" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-1' : 'text-white-50'">
                                      <v-icon size="12">mdi-calendar-clock</v-icon>{{ formatDate(order.created_at) }}
                                  </div>
                                  <v-expansion-panels variant="accordion" class="glass-expansion-modern">
                                      <v-expansion-panel class="rounded-xl overflow-hidden border" :class="themeStore.currentMode === 'light' ? 'bg-white border-grey-lighten-2' : 'bg-transparent border-white-05'" elevation="0" @group:selected="fetchItemsForOrder(order.id)">
                                          <v-expansion-panel-title class="px-4 py-3 transition-colors" :class="themeStore.currentMode === 'light' ? 'hover:bg-grey-lighten-5' : 'hover-bg-white-05'">
                                              <div class="d-flex w-100 align-center justify-space-between">
                                                  <div>
                                                      <div class="d-flex align-center gap-2 mb-1">
                                                          <span class="text-body-2 font-weight-bold" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">Pedido #{{ order.order_number }}</span>
                                                          <v-chip size="x-small" :color="getOrderStatusColor(order.status)" variant="flat" class="font-weight-bold text-uppercase">{{ order.status || 'Concluído' }}</v-chip>
                                                      </div>
                                                  </div>
                                                  <div class="text-body-1 font-weight-black font-mono mr-4" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">{{ formatCurrency(order.total_value) }}</div>
                                              </div>
                                          </v-expansion-panel-title>
                                          <v-expansion-panel-text :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5' : 'bg-black-20'">
                                              <div class="pt-3">
                                                  <div v-if="loadingItems[order.id]" class="text-center py-2"><v-progress-circular indeterminate size="20" width="2" color="primary"></v-progress-circular></div>
                                                  <div v-else-if="orderItemsCache[order.id]">
                                                      <div v-for="item in orderItemsCache[order.id]" :key="item.id" class="d-flex justify-space-between align-center py-2 border-b" :class="themeStore.currentMode === 'light' ? 'border-grey-lighten-2' : 'border-white-05'">
                                                          <div class="text-caption flex-grow-1" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-3' : 'text-white-70'">{{ item.product_name }}</div>
                                                          <div class="text-caption font-mono mx-4 opacity-70">{{ item.quantity }}x</div>
                                                          <div class="text-caption font-weight-bold font-mono">{{ formatCurrency(item.total_price) }}</div>
                                                      </div>
                                                      <div class="d-flex justify-end mt-3">
                                                          <v-btn size="small" variant="tonal" color="primary" prepend-icon="mdi-file-document-outline" :href="order.sales_order_pdf_url" target="_blank" :disabled="!order.sales_order_pdf_url" class="text-none">Ver Recibo</v-btn>
                                                      </div>
                                                  </div>
                                              </div>
                                          </v-expansion-panel-text>
                                      </v-expansion-panel>
                                  </v-expansion-panels>
                              </div>
                          </div>
                      </div>
                  </v-window-item>

              </v-window>
          </div>
      </div>
    </v-card>
    <v-snackbar v-model="showSnackbar" :timeout="2000" color="surface" location="bottom center">
       <div class="d-flex align-center gap-2"><v-icon color="success" size="small">mdi-check-circle</v-icon><span class="text-high-emphasis text-caption font-weight-bold">{{ snackbarText }}</span></div>
    </v-snackbar>
  </v-dialog>
</template>

<script setup lang="ts">
import { ref, watch, reactive, computed } from 'vue';
import { gestaoApiCajuia } from '@/api/gestaoClick_Cajuia'; // API CORRETA
import { supabase } from '@/api/supabase';
import { useAppStore } from '@/stores/app';
import { useThemeStore } from '@/stores/theme';
import { format, differenceInDays } from 'date-fns';
import { useCajuiaPDF } from '@/composables/useCajuiaPDF';

const props = defineProps({ show: Boolean, client: Object });
const emit = defineEmits(['close', 'client-updated']);
const appStore = useAppStore();
const themeStore = useThemeStore();
const { generateClientReport, isGenerating: isPdfGenerating } = useCajuiaPDF();

const tab = ref('overview');
const isEditing = ref(false);
const saving = ref(false);
const loadingCep = ref(false);
const historyLoading = ref(false);
const isLoadingDetail = ref(false);
const historyOrders = ref<any[]>([]);
const fullClientData = ref<any>(null);
const orderItemsCache = ref<Record<string, any[]>>({});
const loadingItems = ref<Record<string, boolean>>({});
const allLoadedItems = ref<any[]>([]);
const showSnackbar = ref(false);
const snackbarText = ref('');

const editForm = reactive({
    email: '',
    phone: '',
    address: { cep: '', logradouro: '', numero: '', complemento: '', bairro: '', cidade: '', uf: '' }
});

const clientData = computed(() => {
    const basic = props.client || {};
    const full = fullClientData.value || {};
    // Prioriza dados do full (que vem da API/Sync recente), fallback para o prop
    return {
        id: basic.id,
        external_id: basic.external_id || basic.id,
        name: basic.name,
        cpf_cnpj: basic.cpf_cnpj || '',
        email: editForm.email || basic.email, // Usa do form reativo se disponível
        city: basic.city,
        state: basic.state,
        blocked: basic.blocked,
        total_purchases: basic.total_purchases || 0,
        photo_url: basic.photo_url,
        raw: full
    };
});

const profileScore = computed(() => {
    let score = 0;
    if (editForm.email) score += 25;
    if (editForm.phone) score += 25;
    if (editForm.address.logradouro) score += 25;
    if (clientData.value.cpf_cnpj) score += 25;
    return score;
});

const getScoreColor = (score: number) => {
    if (score < 50) return 'error';
    if (score < 100) return 'warning';
    return 'success';
}

const whatsappLink = computed(() => {
    if(!editForm.phone) return '#';
    const clean = editForm.phone.replace(/\D/g,'');
    return `https://wa.me/55${clean}`;
});

const kpis = computed(() => {
    const orders = historyOrders.value || [];
    const totalOrders = orders.length;
    const totalVal = clientData.value.total_purchases || 0;
    const avgTicket = totalOrders > 0 ? totalVal / totalOrders : 0;
    let lastDate = '-';
    let daysSince = '-';
    if (orders.length > 0) {
        const last = new Date(orders[0].created_at);
        lastDate = format(last, 'dd/MM/yyyy');
        daysSince = String(differenceInDays(new Date(), last)) + ' dias atrás';
    }
    return { totalOrders, avgTicket, lastPurchaseDate: lastDate, daysSinceLast: daysSince };
});

const calculatedTopProducts = computed(() => {
    if (allLoadedItems.value.length === 0) return [];
    const map = new Map();
    allLoadedItems.value.forEach(item => {
        const key = item.product_name;
        if (!map.has(key)) map.set(key, { name: key, quantity: 0, total: 0, frequency: 0 });
        const entry = map.get(key);
        entry.quantity += item.quantity;
        entry.total += item.total_price;
        entry.frequency += 1;
    });
    return Array.from(map.values()).sort((a, b) => b.total - a.total).slice(0, 5);
});

watch(() => props.show, async (val) => {
    if (val && props.client) {
        tab.value = 'overview';
        isEditing.value = false;
        orderItemsCache.value = {};
        allLoadedItems.value = [];
        // Carrega dados iniciais do prop para o form
        editForm.email = props.client.email || '';
        editForm.phone = props.client.phone || '';
        // Idealmente aqui faríamos um fetch detalhado no ERP se tivéssemos endpoint específico rápido
        // Como o sync já traz quase tudo, usamos o que temos e buscamos histórico
        await fetchHistory();
    }
});

const saveEdit = async () => {
    saving.value = true;
    try {
        // ATUALIZAÇÃO NO ERP (GestãoClick)
        // Precisamos construir o payload correto para o endpoint PUT /clientes/{id}
        // Nota: A API do GestãoClick pode exigir payload completo.
        // Aqui assumimos uma atualização parcial via API Wrapper ou Logica de Sync

        // Como o wrapper atual não tem 'updateCustomer', vamos simular salvando no Supabase local
        // para persistir as edições de contato feitas aqui.

        const updates = {
            email: editForm.email,
            phone: editForm.phone,
            city: editForm.address.cidade,
            state: editForm.address.uf,
            // address full... se tiver campos no banco
        };

        const { error } = await supabase
            .from('cajuia_clients')
            .update(updates)
            .eq('id', props.client?.id);

        if(error) throw error;

        showToast('Dados atualizados localmente!');
        isEditing.value = false;
        emit('client-updated');
    } catch (error) {
        showToast('Erro ao salvar alterações.');
    } finally {
        saving.value = false;
    }
};

const fetchCep = async () => {
    const cep = editForm.address.cep.replace(/[^0-9]/g, '');
    if (cep.length !== 8) return;
    loadingCep.value = true;
    try {
        const res = await fetch(`https://viacep.com.br/ws/${cep}/json/`);
        const data = await res.json();
        if (!data.erro) {
            editForm.address.logradouro = data.logradouro;
            editForm.address.bairro = data.bairro;
            editForm.address.cidade = data.localidade;
            editForm.address.uf = data.uf;
        }
    } finally { loadingCep.value = false; }
};

const fetchHistory = async () => {
    historyLoading.value = true;
    try {
        const searchName = clientData.value.name ? clientData.value.name.split(' ')[0] : '';
        // Busca histórico local do Cajuia Orders
        const { data: orders } = await supabase.from('cajuia_orders')
            .select('*, profiles(full_name)')
            .ilike('customer_name', `%${searchName}%`) // Busca aproximada por nome
            .order('created_at', { ascending: false });

        historyOrders.value = orders || [];

        // Carrega itens dos últimos pedidos para popular "Produtos Favoritos"
        if (orders && orders.length > 0) {
            const recentIds = orders.slice(0, 5).map(o => o.id);
            const { data: items } = await supabase.from('cajuia_order_items').select('*').in('order_id', recentIds);
            if (items) {
                allLoadedItems.value.push(...items);
                items.forEach(item => {
                    if(!orderItemsCache.value[item.order_id]) orderItemsCache.value[item.order_id] = [];
                    orderItemsCache.value[item.order_id].push(item);
                });
            }
        }
    } catch(e) { console.error(e); } finally { historyLoading.value = false; }
};

const fetchItemsForOrder = async (orderId: string) => {
    if (orderItemsCache.value[orderId]) return;
    loadingItems.value[orderId] = true;
    try {
        const { data } = await supabase.from('cajuia_order_items').select('*').eq('order_id', orderId);
        if (data) {
            orderItemsCache.value[orderId] = data;
            allLoadedItems.value.push(...data);
        }
    } catch (e) { console.error("Erro ao buscar itens", e); } finally { loadingItems.value[orderId] = false; }
}

const printReport = async () => { await generateClientReport(clientData.value, historyOrders.value); };
const startEdit = () => { isEditing.value = true; };
const cancelEdit = () => { isEditing.value = false; };
const close = () => emit('close');
const showToast = (msg: string) => { snackbarText.value = msg; showSnackbar.value = true; };
const copyToClipboard = (text: string) => { navigator.clipboard.writeText(text); showToast('Copiado!'); };

const formatCurrency = (val: number) => new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(val || 0);
const formatDoc = (doc: string) => doc ? (doc.length > 11 ? doc.replace(/^(\d{2})(\d{3})(\d{3})(\d{4})(\d{2})/, "$1.$2.$3/$4-$5") : doc.replace(/^(\d{3})(\d{3})(\d{3})(\d{2})/, "$1.$2.$3-$4")) : '---';
const getInitials = (name: string) => name ? name.substring(0, 2).toUpperCase() : '??';
const formatDate = (d: string) => d ? format(new Date(d), 'dd/MM/yyyy HH:mm') : '--/--/----';
const stringToColor = (str: string) => '#333'; // Cor neutra padrão
const getOrderStatusColor = (status: string) => {
    if(status === 'cancelled') return 'error';
    if(status === 'pending') return 'warning';
    return 'success';
}
const getOrderStatusColorClass = (status: string) => {
    if(status === 'cancelled') return 'bg-error';
    if(status === 'pending') return 'bg-warning';
    return 'bg-success';
}
</script>

<style scoped lang="scss">
.modal-backdrop-blur { backdrop-filter: blur(8px); }

/* LAYOUT */
.glass-detail-card {
    background: rgba(30, 30, 35, 0.95);
    border: 1px solid rgba(255, 255, 255, 0.08);
}
.sidebar-panel { width: 320px; flex-shrink: 0; min-width: 300px; }
.sticky-bottom-sidebar { margin-top: auto; padding-top: 20px; }

/* THEME UTILS */
.bg-glass-header { background: rgba(255, 255, 255, 0.02); }
.bg-glass-darker { background: rgba(0, 0, 0, 0.2); }
.bg-glass-surface { background: rgba(255, 255, 255, 0.01); }
.glass-well { background: rgba(255,255,255,0.03); }

.bg-white-02 { background: rgba(255,255,255,0.02); }
.bg-white-05 { background: rgba(255,255,255,0.05); }
.bg-black-20 { background: rgba(0,0,0,0.2); }

.bg-info-10 { background: rgba(var(--v-theme-info), 0.1); }
.bg-warning-10 { background: rgba(var(--v-theme-warning), 0.1); }
.bg-primary-10 { background: rgba(var(--v-theme-primary), 0.1); }

.border-white-05 { border-color: rgba(255,255,255,0.05) !important; }
.border-white-10 { border-color: rgba(255,255,255,0.1) !important; }

.text-white-30 { color: rgba(255,255,255,0.3) !important; }
.text-white-50 { color: rgba(255,255,255,0.5) !important; }
.text-white-70 { color: rgba(255,255,255,0.7) !important; }
.text-white-40 { color: rgba(255,255,255,0.4) !important; }

/* DECORATION */
.header-bg-glow {
    position: absolute; top: -100%; left: -20%; width: 140%; height: 300%; opacity: 0.08; filter: blur(80px); pointer-events: none;
    background: radial-gradient(circle, currentColor, transparent 70%);
    &.success { color: #00e676; }
    &.error { color: #ff5252; }
}

.icon-box { width: 40px; height: 40px; display: flex; align-items: center; justify-content: center; border-radius: 10px; }
.icon-circle { width: 32px; height: 32px; display: flex; align-items: center; justify-content: center; border-radius: 50%; }

/* INPUTS */
.info-field-group {
    padding: 12px;
    border-radius: 8px;
    border-width: 1px; border-style: solid;
    transition: background 0.2s;
}
.field-label { font-size: 10px; font-weight: bold; text-transform: uppercase; letter-spacing: 1px; }

/* SCROLLBAR */
.custom-scrollbar::-webkit-scrollbar { width: 6px; }
.custom-scrollbar::-webkit-scrollbar-track { background: transparent; }
.custom-scrollbar::-webkit-scrollbar-thumb {
    background: rgba(128,128,128, 0.2);
    border-radius: 3px;
}
.custom-scrollbar::-webkit-scrollbar-thumb:hover { background: rgba(128,128,128, 0.4); }

.lh-1 { line-height: 1; }
.icon-pulse { animation: pulse 2s infinite; }
@keyframes pulse { 0% { opacity: 0.5; } 50% { opacity: 1; } 100% { opacity: 0.5; } }
</style>
