<template>
  <v-dialog
    :model-value="show"
    @update:model-value="$emit('update:show', $event)"
    max-width="1200px"
    height="90vh"
    class="enterprise-modal"
    transition="dialog-bottom-transition"
    scrim="black"
  >
    <v-card class="d-flex flex-column fill-height rounded-xl overflow-hidden bg-background-glass border-thin">

      <div class="header-section pt-6 pb-2 px-6 d-flex flex-column align-center flex-shrink-0 relative">

          <v-btn
            icon="mdi-close"
            variant="text"
            size="small"
            class="close-btn text-medium-emphasis"
            @click="$emit('close')"
          ></v-btn>

          <div class="d-flex flex-column align-center gap-2 mb-3">
              <v-avatar
                color="surface-variant"
                size="80"
                class="elevation-4 border-subtle"
              >
                  <span v-if="!client?.avatar_url" class="text-h4 font-weight-black text-primary">
                    {{ client?.nome?.charAt(0)?.toUpperCase() }}
                  </span>
                  <v-img v-else :src="client.avatar_url" cover></v-img>
              </v-avatar>

              <div class="text-center">
                  <h2 class="text-h5 font-weight-bold text-high-emphasis mb-0 line-height-1">
                    {{ client?.nome }}
                  </h2>
                  <div class="d-flex align-center justify-center gap-2 mt-2">
                       <v-chip
                         :color="client?.situacao === 'Ativo' ? 'success' : 'error'"
                         size="x-small"
                         variant="flat"
                         class="font-weight-bold uppercase"
                       >
                         {{ client?.situacao || 'INDEFINIDO' }}
                       </v-chip>

                       <v-chip
                         size="x-small"
                         variant="flat"
                         color="surface-variant"
                         class="font-mono font-weight-bold text-high-emphasis"
                       >
                         ID: {{ client?.gestao_click_id || 'N/A' }}
                       </v-chip>
                  </div>
              </div>
          </div>
      </div>

      <div class="nav-section px-4 pb-4 flex-shrink-0 z-20 sticky-island-wrapper">
          <v-sheet
            class="nav-island rounded-pill elevation-3 d-flex align-center py-1 px-2 mx-auto"
            max-width="850"
            border
          >
              <v-tabs
                v-model="activeTab"
                hide-slider
                height="40"
                class="rounded-pill flex-shrink-0"
                selected-class="tab-active"
                color="primary"
              >
                  <v-tab
                    v-for="(item, index) in navItems"
                    :key="index"
                    :value="index"
                    class="text-capitalize letter-spacing-0 rounded-pill px-4 text-caption font-weight-bold"
                  >
                    <v-icon :icon="item.icon" start size="18"></v-icon>
                    {{ item.label }}
                  </v-tab>
              </v-tabs>

              <v-divider vertical class="mx-2 my-1 border-opacity-25" style="height: 24px"></v-divider>

              <div class="d-flex align-center flex-grow-1 px-2 search-container">
                  <v-icon icon="mdi-magnify" color="medium-emphasis" size="20" class="mr-2"></v-icon>
                  <input
                    type="text"
                    class="island-input text-body-2 font-weight-medium"
                    placeholder="Buscar pedidos, dados..."
                    v-model="searchQuery"
                    @focus="activeTab = 2"
                  >
                  <v-fade-transition>
                    <v-btn
                        v-if="searchQuery"
                        icon="mdi-close-circle"
                        variant="text"
                        size="x-small"
                        color="medium-emphasis"
                        @click="searchQuery = ''"
                    ></v-btn>
                  </v-fade-transition>
              </div>

              <v-divider vertical class="mx-2 my-1 border-opacity-25" style="height: 24px"></v-divider>

              <div class="d-flex align-center gap-1 pr-1">
                  <v-tooltip text="Editar Cliente" location="top" content-class="tooltip-dark">
                      <template v-slot:activator="{ props }">
                          <v-btn
                            icon="mdi-pencil-outline"
                            size="small"
                            variant="text"
                            color="medium-emphasis"
                            v-bind="props"
                            @click="activeTab = 1"
                          ></v-btn>
                      </template>
                  </v-tooltip>

                  <v-menu>
                      <template v-slot:activator="{ props }">
                          <v-btn icon="mdi-dots-vertical" size="small" variant="text" color="medium-emphasis" v-bind="props"></v-btn>
                      </template>
                      <v-list density="compact" class="rounded-lg elevation-10">
                          <v-list-item prepend-icon="mdi-delete" title="Excluir Cliente" color="error" @click="confirmDelete = true"></v-list-item>
                      </v-list>
                  </v-menu>
              </div>

          </v-sheet>
      </div>

      <div class="content-section flex-grow-1 overflow-y-auto bg-surface-subtle custom-scroll pa-4 pa-md-6 relative z-10">
          <v-window v-model="activeTab">

              <v-window-item :value="0">
                  <v-row>
                      <v-col cols="12" md="4">
                          <div class="d-flex flex-column gap-4">

                              <v-card class="enterprise-card border-subtle" flat>
                                  <v-card-title class="text-subtitle-2 font-weight-bold text-uppercase text-medium-emphasis d-flex align-center gap-2 py-3 px-4 border-b-subtle bg-surface-variant-subtle">
                                      <v-icon size="16" color="purple">mdi-credit-card-outline</v-icon> Crédito Loja
                                  </v-card-title>
                                  <div class="pa-4">
                                      <div class="d-flex justify-space-between align-end mb-2">
                                          <span class="text-caption text-medium-emphasis">Disponível</span>
                                          <span class="text-body-2 font-weight-black text-success">{{ formatCurrency((client?.credit_limit || 0) - (client?.credit_used || 0)) }}</span>
                                      </div>
                                      <v-progress-linear
                                          :model-value="((client?.credit_used || 0) / (client?.credit_limit || 1)) * 100"
                                          color="purple"
                                          height="6"
                                          rounded
                                          class="mb-2"
                                      ></v-progress-linear>
                                      <div class="d-flex justify-space-between text-[10px] text-medium-emphasis">
                                          <span>Usado: {{ formatCurrency(client?.credit_used || 0) }}</span>
                                          <span>Limite: {{ formatCurrency(client?.credit_limit || 0) }}</span>
                                      </div>
                                  </div>
                              </v-card>

                              <v-card class="enterprise-card border-subtle" flat>
                                  <v-card-title class="text-subtitle-2 font-weight-bold text-uppercase text-medium-emphasis d-flex align-center gap-2 py-3 px-4 border-b-subtle bg-surface-variant-subtle">
                                      <v-icon size="16">mdi-card-account-details-outline</v-icon> Contatos
                                  </v-card-title>

                                  <v-list density="compact" class="py-2 bg-transparent">
                                      <v-list-item class="px-4">
                                          <template v-slot:prepend><v-icon size="20" color="primary" class="mr-3">mdi-email-outline</v-icon></template>
                                          <v-list-item-title class="text-body-2 font-weight-medium text-high-emphasis">{{ client?.email || '-' }}</v-list-item-title>
                                          <v-list-item-subtitle class="text-caption">Email</v-list-item-subtitle>
                                      </v-list-item>
                                      <v-divider class="my-1 border-opacity-12"></v-divider>
                                      <v-list-item class="px-4">
                                          <template v-slot:prepend><v-icon size="20" color="success" class="mr-3">mdi-whatsapp</v-icon></template>
                                          <v-list-item-title class="text-body-2 font-weight-medium text-high-emphasis">{{ client?.celular || '-' }}</v-list-item-title>
                                          <v-list-item-subtitle class="text-caption">Celular / WhatsApp</v-list-item-subtitle>
                                      </v-list-item>
                                      <v-divider class="my-1 border-opacity-12"></v-divider>
                                      <v-list-item class="px-4">
                                          <template v-slot:prepend><v-icon size="20" color="info" class="mr-3">mdi-phone-classic</v-icon></template>
                                          <v-list-item-title class="text-body-2 font-weight-medium text-high-emphasis">{{ client?.telefone || '-' }}</v-list-item-title>
                                          <v-list-item-subtitle class="text-caption">Telefone Fixo</v-list-item-subtitle>
                                      </v-list-item>
                                  </v-list>
                              </v-card>

                              <v-card class="enterprise-card border-subtle" flat>
                                  <v-card-title class="text-subtitle-2 font-weight-bold text-uppercase text-medium-emphasis d-flex align-center gap-2 py-3 px-4 border-b-subtle bg-surface-variant-subtle">
                                      <v-icon size="16">mdi-map-marker-radius</v-icon> Endereço
                                  </v-card-title>
                                  <div class="pa-4">
                                      <div class="d-flex align-start gap-3">
                                          <v-icon color="medium-emphasis" class="mt-1">mdi-home-map-marker</v-icon>
                                          <div>
                                              <div class="text-body-2 font-weight-bold text-high-emphasis">
                                                  {{ client?.endereco }}, {{ client?.numero }}
                                              </div>
                                              <div class="text-body-2 text-medium-emphasis">
                                                  {{ client?.bairro }}
                                              </div>
                                              <div class="text-body-2 text-medium-emphasis mb-2">
                                                  {{ client?.cidade }} - {{ client?.estado }}
                                              </div>
                                              <v-chip size="x-small" variant="tonal" color="medium-emphasis" class="font-mono">
                                                  CEP: {{ client?.cep }}
                                              </v-chip>
                                          </div>
                                      </div>
                                  </div>
                              </v-card>

                              <v-card class="enterprise-card border-subtle" flat v-if="client?.observacoes">
                                   <v-card-title class="text-subtitle-2 font-weight-bold text-uppercase text-medium-emphasis d-flex align-center gap-2 py-3 px-4 border-b-subtle bg-surface-variant-subtle">
                                      <v-icon size="16">mdi-note-text-outline</v-icon> Observações
                                  </v-card-title>
                                  <div class="pa-4">
                                      <v-alert
                                        variant="tonal"
                                        color="info"
                                        density="compact"
                                        class="text-caption mb-0 text-high-emphasis"
                                        border="start"
                                        icon="mdi-information"
                                      >
                                         {{ client.observacoes }}
                                      </v-alert>
                                  </div>
                              </v-card>

                          </div>
                      </v-col>

                      <v-col cols="12" md="8">
                          <div class="d-flex flex-column gap-4">

                              <div class="d-flex gap-4 flex-wrap">
                                  <v-card class="enterprise-card flex-grow-1 border-subtle pa-4 d-flex align-center gap-4" flat>
                                      <v-avatar color="primary" variant="tonal" rounded="lg">
                                          <v-icon>mdi-currency-usd</v-icon>
                                      </v-avatar>
                                      <div>
                                          <div class="text-caption text-medium-emphasis font-weight-bold text-uppercase">Total Gasto</div>
                                          <div class="text-h6 font-weight-black text-high-emphasis">{{ formatCurrency(financialStats.totalSpent) }}</div>
                                      </div>
                                  </v-card>

                                  <v-card class="enterprise-card flex-grow-1 border-subtle pa-4 d-flex align-center gap-4" flat>
                                      <v-avatar color="info" variant="tonal" rounded="lg">
                                          <v-icon>mdi-ticket-percent-outline</v-icon>
                                      </v-avatar>
                                      <div>
                                          <div class="text-caption text-medium-emphasis font-weight-bold text-uppercase">Ticket Médio</div>
                                          <div class="text-h6 font-weight-black text-high-emphasis">{{ formatCurrency(financialStats.avgTicket) }}</div>
                                      </div>
                                  </v-card>

                                  <v-card class="enterprise-card flex-grow-1 border-subtle pa-4 d-flex align-center gap-4" flat>
                                      <v-avatar color="warning" variant="tonal" rounded="lg">
                                          <v-icon>mdi-shopping-outline</v-icon>
                                      </v-avatar>
                                      <div>
                                          <div class="text-caption text-medium-emphasis font-weight-bold text-uppercase">Total Pedidos</div>
                                          <div class="text-h6 font-weight-black text-high-emphasis">{{ linkedOrders.length }}</div>
                                      </div>
                                  </v-card>
                              </div>

                              <v-card class="enterprise-card border-subtle flex-grow-1" flat>
                                  <div class="d-flex justify-space-between align-center px-4 py-3 border-b-subtle">
                                      <span class="text-subtitle-1 font-weight-bold">Pedidos Recentes</span>
                                      <v-btn variant="text" size="small" color="primary" @click="activeTab = 2">Ver Todos</v-btn>
                                  </div>

                                  <div style="min-height: 200px;">
                                    <v-table class="bg-transparent" density="comfortable">
                                        <thead>
                                            <tr>
                                                <th class="text-caption font-weight-bold text-uppercase text-medium-emphasis">Pedido</th>
                                                <th class="text-caption font-weight-bold text-uppercase text-medium-emphasis">Data</th>
                                                <th class="text-caption font-weight-bold text-uppercase text-medium-emphasis">Status</th>
                                                <th class="text-right text-caption font-weight-bold text-uppercase text-medium-emphasis">Valor</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            <tr v-if="filteredOrders.length === 0">
                                                <td colspan="4" class="text-center py-8 text-medium-emphasis">
                                                    {{ searchQuery ? 'Nenhum pedido encontrado na busca.' : 'Sem histórico recente.' }}
                                                </td>
                                            </tr>
                                            <tr v-for="order in filteredOrders.slice(0, 5)" :key="order.id" class="hover-row">
                                                <td>
                                                    <div class="font-weight-bold text-body-2 text-high-emphasis">#{{ order.order_number }}</div>
                                                    <div class="text-caption text-medium-emphasis text-truncate" style="max-width: 150px;">{{ order.description || 'Pedido Venda' }}</div>
                                                </td>
                                                <td class="text-caption font-mono text-medium-emphasis">{{ formatDate(order.created_at) }}</td>
                                                <td>
                                                    <v-chip :color="getStatusColor(order.status)" size="x-small" variant="tonal" class="font-weight-bold uppercase">
                                                        {{ order.status }}
                                                    </v-chip>
                                                </td>
                                                <td class="text-right font-weight-bold text-body-2 text-high-emphasis">{{ formatCurrency(order.total_value) }}</td>
                                            </tr>
                                        </tbody>
                                    </v-table>
                                  </div>
                              </v-card>

                          </div>
                      </v-col>
                  </v-row>
              </v-window-item>

              <v-window-item :value="1">
                  <v-card class="enterprise-card border-subtle mx-auto" max-width="800" flat>
                      <v-card-title class="px-6 py-4 border-b-subtle d-flex justify-space-between align-center">
                          <span class="text-h6 font-weight-bold">Editar Cadastro</span>
                          <v-btn color="error" variant="text" size="small" prepend-icon="mdi-delete" @click="confirmDelete = true">Excluir</v-btn>
                      </v-card-title>

                      <v-card-text class="pa-6">
                          <v-form ref="formRef" @submit.prevent="saveClient">
                              <v-row dense>
                                  <v-col cols="12" class="mb-2"><span class="text-overline text-medium-emphasis font-weight-bold">Identificação</span></v-col>

                                  <v-col cols="12" md="8"><v-text-field v-model="editedClient.nome" label="Nome Completo *" variant="outlined" density="comfortable" color="primary"></v-text-field></v-col>
                                  <v-col cols="12" md="4"><v-select v-model="editedClient.situacao" label="Situação" :items="['Ativo', 'Inativo']" variant="outlined" density="comfortable" color="primary"></v-select></v-col>

                                  <v-col cols="12" md="6"><v-text-field v-model="editedClient.razao_social" label="Razão Social" variant="outlined" density="comfortable" color="primary"></v-text-field></v-col>
                                  <v-col cols="12" md="3"><v-select v-model="editedClient.tipo_pessoa" label="Tipo" :items="['Fisica', 'Juridica']" variant="outlined" density="comfortable" color="primary"></v-select></v-col>
                                  <v-col cols="12" md="3"><v-text-field v-model="editedClient.cpf_cnpj" label="Documento" variant="outlined" density="comfortable" color="primary"></v-text-field></v-col>

                                  <v-col cols="12" md="3">
                                      <v-text-field
                                          v-model="editedClient.credit_limit"
                                          label="Limite de Crédito (R$)"
                                          variant="outlined"
                                          density="comfortable"
                                          color="purple"
                                          prefix="R$"
                                          type="number"
                                          :disabled="!userStore.isAdmin"
                                          :hint="!userStore.isAdmin ? 'Apenas Admins podem alterar' : ''"
                                          persistent-hint
                                      ></v-text-field>
                                  </v-col>

                                  <v-col cols="12" class="mb-2 mt-4"><span class="text-overline text-medium-emphasis font-weight-bold">Contato & Endereço</span></v-col>

                                  <v-col cols="12" md="6"><v-text-field v-model="editedClient.email" label="Email" prepend-inner-icon="mdi-email-outline" variant="outlined" density="comfortable" color="primary"></v-text-field></v-col>
                                  <v-col cols="12" md="3"><v-text-field v-model="editedClient.celular" label="Celular" prepend-inner-icon="mdi-cellphone" variant="outlined" density="comfortable" color="primary"></v-text-field></v-col>
                                  <v-col cols="12" md="3"><v-text-field v-model="editedClient.telefone" label="Fixo" prepend-inner-icon="mdi-phone" variant="outlined" density="comfortable" color="primary"></v-text-field></v-col>

                                  <v-col cols="12" md="3"><v-text-field v-model="editedClient.cep" label="CEP" variant="outlined" density="comfortable" color="primary"></v-text-field></v-col>
                                  <v-col cols="12" md="6"><v-text-field v-model="editedClient.endereco" label="Logradouro" variant="outlined" density="comfortable" color="primary"></v-text-field></v-col>
                                  <v-col cols="12" md="3"><v-text-field v-model="editedClient.numero" label="Número" variant="outlined" density="comfortable" color="primary"></v-text-field></v-col>
                                  <v-col cols="12" md="4"><v-text-field v-model="editedClient.bairro" label="Bairro" variant="outlined" density="comfortable" color="primary"></v-text-field></v-col>
                                  <v-col cols="12" md="4"><v-text-field v-model="editedClient.cidade" label="Cidade" variant="outlined" density="comfortable" color="primary"></v-text-field></v-col>
                                  <v-col cols="12" md="4"><v-text-field v-model="editedClient.estado" label="UF" variant="outlined" density="comfortable" color="primary"></v-text-field></v-col>

                                  <v-col cols="12" class="mt-4">
                                      <v-textarea v-model="editedClient.observacoes" label="Notas Internas" variant="outlined" density="comfortable" color="primary" rows="3" auto-grow></v-textarea>
                                  </v-col>
                              </v-row>
                          </v-form>
                      </v-card-text>

                      <v-divider class="border-opacity-12"></v-divider>

                      <v-card-actions class="pa-4 bg-surface-variant-subtle d-flex justify-end gap-2">
                          <v-btn variant="text" color="medium-emphasis" @click="resetForm">Descartar</v-btn>
                          <v-btn color="primary" variant="flat" :loading="isSaving" @click="saveClient" class="px-6 font-weight-bold">Salvar Alterações</v-btn>
                      </v-card-actions>
                  </v-card>
              </v-window-item>

              <v-window-item :value="2">
                   <v-card class="enterprise-card border-subtle mx-auto" max-width="1000" flat>
                       <div class="px-6 py-4 border-b-subtle d-flex flex-wrap align-center justify-space-between gap-4 bg-surface z-10 sticky-filter-header">
                            <div class="d-flex align-center gap-2">
                                <v-icon color="primary">mdi-history</v-icon>
                                <h3 class="text-h6 font-weight-bold">Linha do Tempo</h3>
                            </div>

                            <div class="d-flex gap-2 flex-wrap">
                                <v-chip
                                    v-for="f in ['Todos', 'Aprovado', 'Em Produção', 'Entregue', 'Cancelado']"
                                    :key="f"
                                    size="small"
                                    :variant="ordersFilter === f ? 'flat' : 'outlined'"
                                    :color="ordersFilter === f ? 'primary' : 'medium-emphasis'"
                                    @click="ordersFilter = f"
                                    class="cursor-pointer font-weight-bold"
                                >
                                    {{ f }}
                                </v-chip>
                            </div>
                       </div>

                       <div class="pa-6">
                            <div v-if="filteredOrders.length === 0" class="d-flex flex-column align-center justify-center py-12 text-medium-emphasis">
                                <v-icon size="64" class="mb-4 opacity-50">mdi-text-box-search-outline</v-icon>
                                <div class="text-h6">Nenhum pedido encontrado</div>
                                <div class="text-caption">{{ searchQuery ? `Nenhum resultado para "${searchQuery}"` : 'Tente alterar os filtros.' }}</div>
                            </div>

                            <v-timeline v-else density="compact" side="end" line-color="primary" class="pl-2">
                                <v-timeline-item
                                    v-for="order in filteredOrders"
                                    :key="order.id"
                                    :dot-color="getStatusColor(order.status)"
                                    size="small"
                                    fill-dot
                                >
                                    <template v-slot:opposite>
                                        <div class="text-caption font-weight-bold text-medium-emphasis pt-3">{{ formatDate(order.created_at) }}</div>
                                    </template>

                                    <v-card class="border-subtle mb-4" variant="outlined">
                                        <div class="px-4 py-2 bg-surface-variant-subtle d-flex justify-space-between align-center border-b-subtle">
                                            <div class="d-flex align-center gap-2">
                                                <span class="font-weight-bold text-caption text-high-emphasis">#{{ order.order_number }}</span>
                                                <v-chip size="x-small" :color="getStatusColor(order.status)" variant="tonal" class="uppercase font-weight-bold">{{ order.status }}</v-chip>
                                            </div>
                                            <v-tooltip text="Abrir Pedido" location="top" content-class="tooltip-dark">
                                                <template v-slot:activator="{ props }">
                                                    <v-btn
                                                      icon="mdi-open-in-new"
                                                      size="x-small"
                                                      variant="text"
                                                      color="medium-emphasis"
                                                      v-bind="props"
                                                    ></v-btn>
                                                </template>
                                            </v-tooltip>
                                        </div>
                                        <div class="px-4 py-3">
                                            <div class="d-flex justify-space-between align-end">
                                                <div>
                                                    <div class="text-body-2 font-weight-medium text-high-emphasis">{{ order.description || 'Pedido de Venda' }}</div>
                                                    <div class="text-caption text-medium-emphasis mt-1 d-flex gap-2">
                                                        <span><v-icon size="14" start>mdi-ruler</v-icon>{{ order.quantity_meters }}m</span>
                                                    </div>
                                                </div>
                                                <div class="text-right">
                                                    <div class="text-caption text-medium-emphasis uppercase">Total</div>
                                                    <div class="text-subtitle-1 font-weight-black text-success">{{ formatCurrency(order.total_value) }}</div>
                                                </div>
                                            </div>
                                        </div>
                                    </v-card>
                                </v-timeline-item>
                            </v-timeline>
                       </div>
                   </v-card>
              </v-window-item>

          </v-window>
      </div>

      <v-dialog v-model="confirmDelete" max-width="400">
           <v-card class="pa-6 text-center rounded-xl border-error elevation-10">
               <v-icon size="56" color="error" class="mb-4">mdi-alert-circle-outline</v-icon>
               <h3 class="text-h6 font-weight-bold mb-2">Excluir Cliente?</h3>
               <p class="text-body-2 text-medium-emphasis mb-6">Esta ação removerá o cliente permanentemente. Dados históricos podem ser perdidos.</p>
               <div class="d-flex gap-4 justify-center">
                   <v-btn variant="outlined" @click="confirmDelete = false">Cancelar</v-btn>
                   <v-btn color="error" variant="flat" :loading="isDeleting" @click="deleteClient">Confirmar Exclusão</v-btn>
               </div>
           </v-card>
      </v-dialog>

    </v-card>
  </v-dialog>
</template>

<script setup lang="ts">
import { ref, computed, watch, reactive } from 'vue';
import { supabase } from '@/api/supabase';
import { format } from 'date-fns';
import { useAppStore } from '@/stores/app';
import { useUserStore } from '@/stores/user';

const props = defineProps<{
  show: boolean;
  client: any;
}>();

const emit = defineEmits(['update:show', 'close', 'refresh']);
const appStore = useAppStore();
const userStore = useUserStore();

const activeTab = ref(0);
const linkedOrders = ref<any[]>([]);
const isSaving = ref(false);
const isDeleting = ref(false);
const confirmDelete = ref(false);
const formRef = ref<any>(null);
const ordersFilter = ref('Todos');
const searchQuery = ref('');

// Estado reativo para edição
const editedClient = reactive<any>({});

const navItems = [
    { label: 'Visão Geral', icon: 'mdi-view-dashboard-outline' },
    { label: 'Editar Dados', icon: 'mdi-pencil-outline' },
    { label: 'Histórico', icon: 'mdi-history' }
];

// --- COMPUTED PROPERTIES ---
const filteredOrders = computed(() => {
    let orders = linkedOrders.value;

    if (ordersFilter.value !== 'Todos') {
        orders = orders.filter(o => o.status === ordersFilter.value || o.financial_status === ordersFilter.value);
    }

    if (searchQuery.value) {
        const q = searchQuery.value.toLowerCase();
        orders = orders.filter(o =>
            (o.order_number?.toString() || '').includes(q) ||
            (o.description?.toLowerCase() || '').includes(q) ||
            (o.status?.toLowerCase() || '').includes(q)
        );
    }

    return orders;
});

const financialStats = computed(() => {
    const total = linkedOrders.value.reduce((acc, o) => acc + (Number(o.total_value) || 0), 0);
    const count = linkedOrders.value.length;
    return {
        totalSpent: total,
        avgTicket: count > 0 ? total / count : 0
    };
});

// --- WATCHERS ---
watch(() => props.show, (newVal) => {
    if (newVal && props.client) {
        activeTab.value = 0;
        searchQuery.value = '';
        ordersFilter.value = 'Todos';
        resetForm();
        fetchLinkedOrders();
    }
});

// --- HELPER FUNCTIONS ---
const formatDate = (dateString: string) => dateString ? format(new Date(dateString), 'dd/MM/yyyy') : '-';

const formatCurrency = (value: any) => {
  const num = Number(value);
  return isNaN(num) ? 'R$ 0,00' : new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(num);
};

const getStatusColor = (status: string) => {
    if (!status) return 'grey';
    const s = status.toLowerCase();
    if (s.includes('aprovado') || s.includes('entregue') || s.includes('pago')) return 'success';
    if (s.includes('produção') || s.includes('andamento')) return 'info';
    if (s.includes('pendente') || s.includes('aguardando')) return 'warning';
    if (s.includes('cancelado')) return 'error';
    return 'grey';
};

// --- DATA ACTIONS ---
const fetchLinkedOrders = async () => {
    if (!props.client?.nome) return;
    try {
        const { data, error } = await supabase
            .from('orders')
            .select('*')
            .eq('customer_name', props.client.nome)
            .order('created_at', { ascending: false });

        if (error) throw error;
        linkedOrders.value = data || [];
    } catch (error) {
        console.error("Erro ao buscar pedidos:", error);
    }
};

const resetForm = () => {
    if (!props.client) return;
    Object.assign(editedClient, JSON.parse(JSON.stringify(props.client)));
    editedClient.cpf_cnpj = props.client.cnpj || props.client.cpf;
};

const saveClient = async () => {
    const { valid } = await formRef.value.validate();
    if (!valid) return;

    isSaving.value = true;
    try {
        // Cria uma cópia limpa do objeto para não afetar o formulário visualmente
        const payload = JSON.parse(JSON.stringify(editedClient));

        // Lógica de CPF/CNPJ para os campos corretos do banco
        if (payload.tipo_pessoa === 'Juridica') {
            payload.cnpj = payload.cpf_cnpj;
            payload.cpf = null;
        } else {
            payload.cpf = payload.cpf_cnpj;
            payload.cnpj = null;
        }

        // --- LIMPEZA DE CAMPOS VIRTUAIS (CORREÇÃO DEFINITIVA) ---
        delete payload.cpf_cnpj;   // Campo usado no v-model do formulário
        delete payload.cnpj_cpf;   // Campo virtual vindo da lista de Clientes (Clients.vue) << O CULPADO
        delete payload.cidade_uf;  // Campo virtual de localidade

        // Garantir tipagem correta para o crédito
        if (payload.credit_limit) {
            payload.credit_limit = Number(payload.credit_limit);
        }

        // Atualiza data
        payload.updated_at = new Date();

        const { error } = await supabase.from('customers_mj').update(payload).eq('id', props.client.id);
        if (error) throw error;

        appStore.showSnackbar('Cliente atualizado!', 'success');
        emit('refresh');
    } catch (error: any) {
        console.error("Erro ao salvar:", error);
        appStore.showSnackbar(`Erro: ${error.message}`, 'error');
    } finally {
        isSaving.value = false;
    }
};

const deleteClient = async () => {
    if (!props.client?.id) return;
    isDeleting.value = true;
    try {
        const { error } = await supabase.from('customers_mj').delete().eq('id', props.client.id);
        if (error) throw error;
        appStore.showSnackbar('Cliente excluído.', 'success');
        emit('refresh');
        emit('close');
    } catch (error: any) {
         if (error.code === '23503') appStore.showSnackbar('Impossível excluir: Cliente possui vínculos.', 'warning');
         else appStore.showSnackbar(`Erro: ${error.message}`, 'error');
    } finally {
        isDeleting.value = false;
        confirmDelete.value = false;
    }
};
</script>

<style scoped lang="scss">
.enterprise-modal {
    z-index: 2000;
}

.bg-background-glass {
    background: rgba(var(--v-theme-surface), 0.96) !important;
    backdrop-filter: blur(10px);
}

.bg-surface-subtle {
    background: rgba(var(--v-theme-surface-variant), 0.3) !important;
}

.bg-surface-variant-subtle {
    background: rgba(var(--v-theme-surface-variant), 0.5) !important;
}

.border-subtle {
    border: 1px solid rgba(var(--v-border-color), 0.15) !important;
}

.border-b-subtle {
    border-bottom: 1px solid rgba(var(--v-border-color), 0.15) !important;
}

.border-opacity-12 {
    border-color: rgba(var(--v-border-color), 0.12) !important;
}

.border-opacity-25 {
    border-color: rgba(var(--v-border-color), 0.25) !important;
}

.enterprise-card {
    border-radius: 12px;
    background: rgb(var(--v-theme-surface));
    box-shadow: 0 1px 3px rgba(0,0,0,0.05);
    overflow: hidden;
}

.nav-island {
    background: rgb(var(--v-theme-surface)) !important;
    border-color: rgba(var(--v-border-color), 0.2) !important;
    transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

.island-input {
    border: none;
    outline: none;
    background: transparent;
    color: rgb(var(--v-theme-on-surface));
    width: 100%;
    height: 100%;
    padding: 0 4px;
}
.island-input::placeholder {
    color: rgba(var(--v-theme-on-surface), 0.5);
    font-size: 13px;
}

.tab-active {
    background: rgba(var(--v-theme-primary), 0.1);
    color: rgb(var(--v-theme-primary)) !important;
}

.close-btn { position: absolute; top: 12px; right: 12px; z-index: 20; }
.sticky-top { position: sticky; top: 0; }
.line-height-1 { line-height: 1.1; }
.gap-1 { gap: 4px; }
.gap-2 { gap: 8px; }
.gap-4 { gap: 16px; }

.custom-scroll::-webkit-scrollbar { width: 8px; }
.custom-scroll::-webkit-scrollbar-track { background: transparent; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(var(--v-theme-on-surface), 0.15); border-radius: 4px; }
.custom-scroll:hover::-webkit-scrollbar-thumb { background: rgba(var(--v-theme-on-surface), 0.25); }

.hover-row:hover {
    background-color: rgba(var(--v-theme-on-surface), 0.03);
}

.sticky-filter-header {
    position: sticky;
    top: 0;
    z-index: 10;
}

/* FIX TOOLTIP */
:deep(.tooltip-dark) {
    background-color: #333 !important;
    color: white !important;
    font-weight: 600;
    font-size: 11px;
    border-radius: 6px;
}
</style>
