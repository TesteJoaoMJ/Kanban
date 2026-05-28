<template>
  <div
    class="clients-layout font-sans fill-height d-flex flex-column relative overflow-hidden"
    :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 text-grey-darken-4' : 'bg-glass-dark text-white'"
  >
    <div v-if="themeStore.currentMode !== 'light'" class="background-carousel-wrapper">
       <div class="background-overlay"></div>
    </div>

    <div class="content-wrapper d-flex flex-column fill-height z-10 relative">

      <div
        class="header-bar px-6 py-4 d-flex align-center justify-space-between flex-shrink-0"
        :class="themeStore.currentMode === 'light' ? 'bg-white border-b border-grey-lighten-2 shadow-sm' : 'bg-glass-header border-bottom-white-05'"
      >
        <div class="d-flex flex-column">
          <div class="breadcrumb text-caption">
            <span class="opacity-70">Cadastros</span>
            <span class="mx-2 opacity-50">></span>
            <span class="font-weight-bold">Clientes</span>
          </div>
          <div class="text-h6 font-weight-black tracking-tight leading-none mt-1" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">
            Gestão de Clientes
          </div>
        </div>

        <div class="d-flex align-center" style="gap: 10px;">
          <v-btn
            color="primary"
            variant="flat"
            class="btn-rect px-4 font-weight-bold text-caption text-uppercase letter-spacing-1"
            prepend-icon="mdi-plus"
            height="40"
            @click="openNewClientModal"
          >
            Novo Cliente
          </v-btn>

          <v-btn
            variant="outlined"
            class="btn-rect"
            height="40"
            prepend-icon="mdi-dots-grid"
            :color="themeStore.currentMode === 'light' ? 'grey-darken-2' : 'white'"
            @click="actionsModal.show = true"
          >
            Ações
          </v-btn>
        </div>
      </div>

      <v-expand-transition>
        <div v-if="pendingSyncCount > 0" class="px-6 pt-4 pb-0 flex-shrink-0">
          <v-alert
            color="orange-darken-2"
            variant="tonal"
            density="compact"
            class="alert-rect border-orange-darken-2"
            icon="mdi-database-refresh-outline"
            closable
            @click:close="pendingSyncCount = 0"
          >
            <div class="d-flex align-center justify-space-between w-100" style="gap: 14px;">
              <div class="text-body-2">
                <span class="font-weight-bold">Divergências Encontradas:</span>
                Detectamos <strong class="text-decoration-underline">{{ pendingSyncCount }} registros</strong> com dados diferentes no ERP ou novos.
              </div>
              <v-btn variant="flat" color="orange-darken-2" height="36" class="btn-rect px-4 font-weight-bold text-white" @click="openSyncWizard">
                Sincronizar
              </v-btn>
            </div>
          </v-alert>
        </div>
      </v-expand-transition>

      <div class="px-6 pt-4 pb-2 flex-shrink-0">
        <v-row dense>
          <v-col cols="12" sm="6" md="3" v-for="(kpi, idx) in kpiList" :key="idx">
            <v-card class="kpi-card kpi-rect bg-gradient-custom hover-elevate py-3 px-4" :class="kpi.gradient" v-ripple elevation="2">
              <div class="kpi-bg-icon"><v-icon>{{ kpi.icon }}</v-icon></div>
              <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                <div class="d-flex align-center" style="gap: 8px;">
                  <v-icon size="18" class="opacity-80">{{ kpi.icon }}</v-icon>
                  <span class="kpi-label">{{ kpi.label }}</span>
                </div>
                <div class="kpi-number-group my-1">
                  <span class="kpi-value">{{ kpi.value }}</span>
                </div>
                <div class="kpi-footer mt-1">{{ kpi.footer }}</div>
              </div>
            </v-card>
          </v-col>
        </v-row>
      </div>

      <div class="px-6 pt-2 pb-2 flex-shrink-0">
        <div
          class="controls-bar d-flex align-center justify-space-between"
          :class="themeStore.currentMode === 'light' ? 'controls-light' : 'controls-dark'"
        >
          <div class="d-flex align-center flex-wrap" style="gap: 10px;">
            <div class="search-wrap d-flex align-center" :class="themeStore.currentMode === 'light' ? 'search-light' : 'search-dark'">
              <v-icon :color="themeStore.currentMode === 'light' ? 'grey-darken-1' : 'white-70'">mdi-magnify</v-icon>
              <input
                v-model="search"
                type="text"
                placeholder="Buscar por nome, documento, cidade..."
                class="clean-input flex-grow-1"
                @input="page = 1"
              />
            </div>

            <div class="d-flex align-center" style="gap: 5px;">
                <v-chip
                    v-for="status in statusFilters"
                    :key="status.value"
                    :color="currentStatusFilter === status.value ? 'primary' : (themeStore.currentMode === 'light' ? 'grey-darken-1' : 'white')"
                    :variant="currentStatusFilter === status.value ? 'flat' : 'outlined'"
                    class="btn-rect font-weight-bold text-caption h-40 px-3 cursor-pointer"
                    style="height: 40px; border-radius: 0;"
                    @click="currentStatusFilter = status.value"
                >
                    {{ status.label }}
                </v-chip>
            </div>
          </div>

          <div class="d-flex align-center" style="gap: 10px;">
            <v-btn
                variant="text"
                class="btn-rect"
                height="40"
                color="grey-darken-1"
                prepend-icon="mdi-refresh"
                @click="fetchClients"
                :loading="loading"
            >
                Atualizar
            </v-btn>
          </div>
        </div>
      </div>

      <div class="flex-grow-1 px-6 pb-2 overflow-hidden d-flex flex-column">
        <v-card
          class="flex-grow-1 d-flex flex-column rounded-0 border-thin overflow-hidden"
          :class="themeStore.currentMode === 'light' ? 'bg-white shadow-sm' : 'glass-card border-white-05'"
          :elevation="0"
        >
          <div class="grid-scroll flex-grow-1 overflow-y-auto custom-scroll">

            <div
              class="grid-header sticky-head"
              :class="[themeStore.currentMode === 'light' ? 'grid-surface-light' : 'grid-surface-dark', 'grid-layout']"
            >
              <div class="cell center header-text">#</div>
              <div class="cell header-text">Cliente / Razão Social</div>
              <div class="cell center header-text">Documento</div>
              <div class="cell header-text">Responsável (Comissão)</div>
              <div class="cell header-text">Localização</div>
              <div class="cell center header-text">Status</div>
              <div class="cell center header-text">Ações</div>
            </div>

            <div v-if="loading" class="d-flex flex-column justify-center align-center h-100 py-12">
              <v-progress-circular indeterminate color="primary" size="32" width="3"></v-progress-circular>
            </div>

            <div v-else-if="filteredClients.length === 0" class="d-flex flex-column justify-center align-center h-100 opacity-60 gap-2 py-12">
              <v-icon size="48" color="grey-lighten-1">mdi-account-off-outline</v-icon>
              <span class="text-body-2 font-weight-medium text-grey">Nenhum cliente encontrado.</span>
            </div>

            <div
              v-else
              v-for="client in paginatedClients"
              :key="client.id"
              class="grid-row grid-layout"
              :class="themeStore.currentMode === 'light' ? 'grid-row-light' : 'grid-row-dark'"
            >
               <div class="cell center">
                  <v-checkbox-btn density="compact" color="primary" class="chk-fixed"></v-checkbox-btn>
               </div>

               <div class="cell">
                  <div class="d-flex align-center w-100" style="min-width: 0;">
                       <v-avatar :color="getColor(client.nome)" size="32" variant="tonal" class="rounded mr-3 flex-shrink-0 font-weight-bold text-caption">
                          {{ client.nome?.charAt(0).toUpperCase() }}
                       </v-avatar>
                       <div class="d-flex flex-column overflow-hidden" style="min-width: 0;">
                          <div class="text-truncate list-text-11 font-weight-bold" :title="client.nome">
                             {{ client.nome }}
                          </div>
                          <div v-if="client.nome_fantasia || client.razao_social" class="text-truncate list-text-10 opacity-70">
                             {{ client.nome_fantasia || client.razao_social }}
                          </div>
                       </div>
                   </div>
               </div>

               <div class="cell center">
                   <span class="list-text-11 font-mono opacity-90">{{ formatDocument(client.cpf || client.cnpj) }}</span>
               </div>

               <div class="cell">
                   <div class="d-flex align-center gap-2">
                       <v-icon size="14" color="amber-darken-3" v-if="client.responsible_salesperson">mdi-crown</v-icon>
                       <div class="d-flex flex-column">
                           <span class="text-caption font-weight-bold" :class="client.responsible_salesperson ? 'text-high-emphasis' : 'text-medium-emphasis opacity-50'">
                               {{ client.responsible_salesperson?.full_name || 'Sem Dono' }}
                           </span>
                           <span v-if="client.responsible_salesperson" class="text-[9px] text-medium-emphasis">Vendedor Responsável</span>
                       </div>
                   </div>
               </div>

               <div class="cell">
                   <div class="d-flex align-center gap-2" v-if="client.cidade || client.estado">
                       <v-icon size="12" class="opacity-50">mdi-map-marker</v-icon>
                       <span class="text-truncate list-text-10 font-weight-bold">{{ client.cidade }}<span v-if="client.cidade && client.estado">, </span>{{ client.estado }}</span>
                   </div>
                   <span v-else class="list-text-10 opacity-40 italic">Sem endereço</span>
               </div>

               <div class="cell center">
                   <span class="solid-chip" :class="isClientActive(client) ? 'chip-success' : 'chip-danger'">
                       {{ isClientActive(client) ? 'Ativo' : 'Inativo' }}
                   </span>
               </div>

               <div class="cell center">
                   <div class="actions-inline">
                       <v-tooltip text="Editar Cadastro" location="top" content-class="bg-grey-darken-3 text-white font-weight-bold">
                           <template v-slot:activator="{ props }">
                               <v-btn v-bind="props" icon size="x-small" class="action-btn action-edit" @click.stop="openEditModal(client)">
                                   <v-icon size="16">mdi-pencil</v-icon>
                               </v-btn>
                           </template>
                       </v-tooltip>

                       <v-tooltip text="Excluir" location="top" content-class="bg-grey-darken-3 text-white font-weight-bold">
                           <template v-slot:activator="{ props }">
                               <v-btn v-bind="props" icon size="x-small" class="action-btn action-del" @click.stop="deleteClient(client)">
                                   <v-icon size="16">mdi-trash-can-outline</v-icon>
                               </v-btn>
                           </template>
                       </v-tooltip>
                   </div>
               </div>
            </div>
          </div>

          <div class="flex-shrink-0 border-t px-4 py-2 d-flex align-center justify-space-between" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5' : 'bg-white-05'">
            <div class="text-caption opacity-80">
              Total: <strong>{{ filteredClients.length }}</strong> clientes | Página {{ page }} de {{ totalPages }}
            </div>
            <v-pagination
              v-model="page"
              :length="totalPages"
              :total-visible="5"
              density="compact"
              active-color="primary"
              variant="tonal"
              size="small"
            ></v-pagination>
          </div>
        </v-card>
      </div>
    </div>

    <v-dialog v-model="actionsModal.show" width="980" persistent scrim="black opacity-75">
      <v-card class="actions-modal rounded-0 overflow-hidden d-flex flex-row" height="620">
        <div class="actions-side">
          <div class="text-overline font-weight-black opacity-80">PAINEL</div>
          <div class="text-h6 font-weight-black mt-1">Ações</div>
          <div class="text-caption opacity-70 mt-2">Ferramentas de gestão de clientes.</div>

          <div class="mt-6 d-flex flex-column" style="gap: 10px;">
            <v-btn class="btn-rect" height="40" color="orange-darken-2" variant="flat" prepend-icon="mdi-cloud-sync" @click="openSyncWizard">
              Sincronizar ERP
            </v-btn>

            <v-btn class="btn-rect" height="40" color="success" variant="flat" prepend-icon="mdi-microsoft-excel" @click="exportExcel">
              Exportar (CSV)
            </v-btn>

            <v-btn class="btn-rect" height="40" color="red-darken-1" variant="flat" prepend-icon="mdi-file-pdf-box" @click="exportPDF">
              Exportar (PDF)
            </v-btn>
          </div>

          <v-spacer></v-spacer>

          <v-btn class="btn-rect" height="40" variant="outlined" color="grey-darken-1" prepend-icon="mdi-close" @click="actionsModal.show = false">
            Fechar
          </v-btn>
        </div>

        <div class="actions-content">
          <div class="actions-top d-flex align-center justify-space-between px-6 py-4">
            <div>
              <div class="text-caption font-weight-black opacity-70 text-uppercase">Atalhos</div>
              <div class="text-subtitle-1 font-weight-black">Configurações rápidas</div>
            </div>
            <v-btn icon variant="text" @click="actionsModal.show = false"><v-icon>mdi-close</v-icon></v-btn>
          </div>

          <div class="px-6 py-5">
            <v-card class="rounded-0 border-thin pa-4" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-white-05'">
              <div class="text-caption font-weight-black opacity-70 text-uppercase mb-2">Relatórios</div>
              <p class="text-body-2 text-grey-darken-1">Utilize o menu lateral para exportar a lista atual de clientes ou sincronizar com o ERP GestãoClick.</p>
            </v-card>
          </div>
        </div>
      </v-card>
    </v-dialog>

    <v-dialog v-model="syncWizard.show" width="900" persistent scrim="black opacity-75">
      <v-card class="rounded-0 overflow-hidden d-flex flex-column" height="650">
        <div class="px-6 py-4 d-flex align-center justify-space-between bg-grey-lighten-5 border-b">
          <div class="d-flex align-center" style="gap: 12px;">
            <div class="bg-orange-darken-2 pa-2 rounded-lg">
              <v-icon color="white">mdi-cloud-sync</v-icon>
            </div>
            <div>
              <div class="text-caption font-weight-black opacity-70 text-uppercase">Integração</div>
              <div class="text-h6 font-weight-black">Sincronização ERP</div>
            </div>
          </div>
          <v-btn icon variant="text" @click="syncWizard.show = false"><v-icon>mdi-close</v-icon></v-btn>
        </div>

        <div class="flex-grow-1 overflow-hidden d-flex flex-column">
            <div v-if="syncWizard.step === 1" class="d-flex flex-column align-center justify-center h-100">
                <v-progress-circular indeterminate color="orange-darken-2" size="64" width="6" class="mb-4"></v-progress-circular>
                <div class="text-h6 font-weight-bold">Analisando base de clientes...</div>
                <div class="text-caption opacity-70">Comparando dados locais com GestãoClick</div>
            </div>

            <div v-else-if="syncWizard.step === 2" class="d-flex flex-column h-100">
                <div class="px-6 py-4 bg-orange-lighten-5 border-b d-flex justify-space-between align-center">
                    <div>
                        <span class="font-weight-bold text-orange-darken-3">{{ syncWizard.previewData.length }}</span>
                        registros encontrados para atualização.
                    </div>
                </div>

                <div class="flex-grow-1 overflow-y-auto custom-scroll">
                    <v-table density="compact" class="text-caption">
                        <thead>
                            <tr>
                                <th>Tipo</th>
                                <th>Cliente</th>
                                <th>Divergência / Info</th>
                                <th class="text-right">Ação</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr v-for="(item, i) in syncWizard.previewData" :key="i">
                                <td>
                                    <span class="solid-chip" :class="item.sync_type === 'new' ? 'chip-success' : 'chip-warning'">
                                        {{ item.sync_type === 'new' ? 'NOVO' : 'ATUALIZAÇÃO' }}
                                    </span>
                                </td>
                                <td class="font-weight-bold">{{ item.nome }}</td>
                                <td class="text-grey-darken-1">{{ item.diff_reason }}</td>
                                <td class="text-right">
                                    <v-icon color="success" size="16">mdi-arrow-right-bold</v-icon>
                                </td>
                            </tr>
                        </tbody>
                    </v-table>
                </div>
            </div>

            <div v-else-if="syncWizard.step === 3" class="d-flex flex-column align-center justify-center h-100">
                <div class="w-50">
                    <v-progress-linear v-model="syncWizard.percent" height="10" color="success" striped class="mb-2"></v-progress-linear>
                    <div class="text-center font-weight-bold">Processando {{ syncWizard.processed }} / {{ syncWizard.total }}</div>
                </div>
            </div>
        </div>

        <div class="px-6 py-4 border-t bg-grey-lighten-5 d-flex justify-end" v-if="syncWizard.step === 2">
            <v-btn variant="text" color="grey-darken-2" @click="syncWizard.show = false">Cancelar</v-btn>
            <v-btn color="success" variant="flat" class="ml-2 btn-rect" @click="executeSync" :disabled="syncWizard.previewData.length === 0">
                Confirmar Sincronização
            </v-btn>
        </div>
      </v-card>
    </v-dialog>

    <v-dialog v-model="editModal.show" width="800" persistent>
        <v-card class="rounded-lg">
            <div class="px-6 py-4 border-b d-flex justify-space-between align-center bg-primary text-white">
                <span class="text-h6 font-weight-bold">{{ editModal.isNew ? 'Novo Cliente' : 'Editar Cliente' }}</span>
                <v-btn icon variant="text" @click="editModal.show = false"><v-icon color="white">mdi-close</v-icon></v-btn>
            </div>
            <div class="pa-6">
                <v-form @submit.prevent="saveClient" ref="formRef">
                    <v-row dense>
                        <v-col cols="12">
                             <v-alert
                                v-if="editModal.isNew"
                                type="info"
                                variant="tonal"
                                density="compact"
                                class="mb-4 text-caption"
                                icon="mdi-account-star"
                            >
                                Você será definido automaticamente como <strong>Vendedor Responsável (Dono)</strong> deste novo cliente. A comissão será sempre vinculada a este responsável.
                            </v-alert>
                            <v-alert
                                v-else-if="editModal.form.vendedor_responsavel_id"
                                type="warning"
                                variant="tonal"
                                density="compact"
                                class="mb-4 text-caption"
                                icon="mdi-crown"
                            >
                                Cliente pertencente a: <strong>{{ getSalespersonName(editModal.form.vendedor_responsavel_id) }}</strong>. Alterar este campo mudará quem recebe comissões futuras.
                            </v-alert>
                        </v-col>

                        <v-col cols="12" md="8">
                            <v-text-field label="Nome / Razão Social *" v-model="editModal.form.nome" variant="outlined" density="compact" color="primary" :rules="[v => !!v || 'Nome obrigatório']"></v-text-field>
                        </v-col>

                         <v-col cols="12" md="4">
                             <v-autocomplete
                                label="Vendedor Responsável (Dono)"
                                v-model="editModal.form.vendedor_responsavel_id"
                                :items="salespeopleList"
                                item-title="full_name"
                                item-value="id"
                                variant="outlined"
                                density="compact"
                                color="amber-darken-3"
                                prepend-inner-icon="mdi-crown"
                                :disabled="!userStore.isAdmin"
                                :hint="!userStore.isAdmin ? 'Apenas Admins podem transferir a carteira' : ''"
                                persistent-hint
                             ></v-autocomplete>
                        </v-col>

                        <v-col cols="12" md="4">
                            <v-text-field label="CPF / CNPJ" v-model="editModal.form.cpf_cnpj" variant="outlined" density="compact" color="primary"></v-text-field>
                        </v-col>

                        <v-col cols="12" md="5">
                            <v-text-field label="Email" v-model="editModal.form.email" variant="outlined" density="compact" color="primary"></v-text-field>
                        </v-col>
                        <v-col cols="12" md="3">
                            <v-text-field label="Telefone" v-model="editModal.form.telefone" variant="outlined" density="compact" color="primary"></v-text-field>
                        </v-col>
                        <v-col cols="12" md="3">
                            <v-text-field
                                label="Crédito (R$)"
                                v-model="editModal.form.credit_limit"
                                variant="outlined"
                                density="compact"
                                color="primary"
                                prefix="R$"
                                type="number"
                                :disabled="!userStore.isAdmin"
                            ></v-text-field>
                        </v-col>

                        <v-col cols="12" md="4">
                            <v-text-field label="CEP" v-model="editModal.form.cep" variant="outlined" density="compact" color="primary"></v-text-field>
                        </v-col>
                        <v-col cols="12" md="5">
                            <v-text-field label="Endereço" v-model="editModal.form.endereco" variant="outlined" density="compact" color="primary"></v-text-field>
                        </v-col>
                        <v-col cols="12" md="5">
                            <v-text-field label="Bairro" v-model="editModal.form.bairro" variant="outlined" density="compact" color="primary"></v-text-field>
                        </v-col>
                        <v-col cols="12" md="5">
                            <v-text-field label="Cidade" v-model="editModal.form.cidade" variant="outlined" density="compact" color="primary"></v-text-field>
                        </v-col>
                        <v-col cols="12" md="2">
                            <v-text-field label="UF" v-model="editModal.form.estado" variant="outlined" density="compact" color="primary"></v-text-field>
                        </v-col>
                    </v-row>
                </v-form>
            </div>
            <div class="px-6 py-4 border-t d-flex justify-end bg-grey-lighten-5">
                <v-btn variant="text" color="grey-darken-1" @click="editModal.show = false">Cancelar</v-btn>
                <v-btn color="primary" variant="flat" class="ml-2 btn-rect" @click="saveClient" :loading="editModal.saving">Salvar</v-btn>
            </div>
        </v-card>
    </v-dialog>

  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted, reactive } from 'vue';
import { supabase } from '@/api/supabase';
import { gestaoApi } from '@/api/gestaoClick';
import { useThemeStore } from '@/stores/themeStore';
import { useAppStore } from '@/stores/app';
import { useUserStore } from '@/stores/user';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import { format } from 'date-fns';

const themeStore = useThemeStore();
const appStore = useAppStore();
const userStore = useUserStore();

// STATE
const loading = ref(false);
const clients = ref<any[]>([]);
const search = ref('');
const currentStatusFilter = ref('active');
const pendingSyncCount = ref(0);
const autoSyncInterval = ref<any>(null);
const actionsModal = reactive({ show: false });
const salespeopleList = ref<any[]>([]); // Lista de vendedores para o select

// PAGINAÇÃO
const page = ref(1);
const itemsPerPage = 30;

const statusFilters = [
    { label: 'Todos', value: 'all' },
    { label: 'Ativos', value: 'active' },
    { label: 'Inativos', value: 'inactive' }
];

// KPIS
const kpiList = computed(() => {
    const total = clients.value.length;
    const active = clients.value.filter(c => isClientActive(c)).length;
    const inactive = total - active;
    const currentMonth = new Date().toISOString().slice(0,7);
    const newClients = clients.value.filter(c => c.created_at?.startsWith(currentMonth)).length;

    return [
        { label: 'Total Clientes', value: total, footer: 'Base cadastrada', icon: 'mdi-account-group', gradient: 'bg-gradient-info' },
        { label: 'Ativos', value: active, footer: 'Disponíveis para venda', icon: 'mdi-account-check', gradient: 'bg-gradient-success' },
        { label: 'Novos (Mês)', value: newClients, footer: 'Crescimento', icon: 'mdi-account-plus', gradient: 'bg-gradient-purple' },
        { label: 'Inativos', value: inactive, footer: 'Bloqueados', icon: 'mdi-account-off', gradient: 'bg-gradient-red' },
    ];
});

const isClientActive = (client: any) => {
    // 1. Se é NOVO (criado nos últimos 60 dias), é ATIVO (Prospect)
    if (client.created_at) {
        const createdDate = parseISO(client.created_at);
        const daysSinceCreation = differenceInDays(new Date(), createdDate);
        if (daysSinceCreation <= 60) return true;
    }

    // 2. Se não é novo e não tem data de compra -> INATIVO
    if (!client.last_purchase_date) return false;

    // 3. Se tem compra, verifica se foi nos últimos 60 dias
    const lastOrder = parseISO(client.last_purchase_date);
    const daysSincePurchase = differenceInDays(new Date(), lastOrder);
    return daysSincePurchase <= 60;
};

// FETCH
const fetchClients = async () => {
    loading.value = true;
    console.log("[DEBUG] [fetchClients] Iniciando busca...");
    try {
        // Fetch Clientes com Vendedor Responsável (Join)
        const { data, error } = await supabase
            .from('customers_mj')
            .select(`
                *,
                responsible_salesperson:vendedor_responsavel_id (
                    id, full_name
                )
            `)
            .order('nome', { ascending: true });

        if (error) throw error;
        clients.value = data || [];
        console.log(`[DEBUG] [fetchClients] ${clients.value.length} clientes carregados.`);

        checkBackgroundSync();
    } catch (e: any) {
        console.error("[DEBUG] [fetchClients] Erro:", e);
        appStore.showSnackbar('Erro ao carregar clientes', 'error');
    } finally {
        loading.value = false;
    }
};

const fetchSalespeople = async () => {
    try {
        const { data, error } = await supabase
            .from('profiles')
            .select('id, full_name')
            .or('role.eq.vendedor,role.eq.admin')
            .order('full_name');

        if (error) throw error;
        salespeopleList.value = data || [];
    } catch (e) {
        console.error("Erro ao buscar vendedores:", e);
    }
};

const filteredClients = computed(() => {
    let list = clients.value;

    if (currentStatusFilter.value === 'active') list = list.filter(c => isClientActive(c));
    if (currentStatusFilter.value === 'inactive') list = list.filter(c => !isClientActive(c));

    if (search.value) {
        const s = search.value.toLowerCase();
        list = list.filter(c =>
            c.nome?.toLowerCase().includes(s) ||
            c.cpf?.includes(s) ||
            c.cnpj?.includes(s) ||
            c.cidade?.toLowerCase().includes(s) ||
            c.responsible_salesperson?.full_name?.toLowerCase().includes(s) // Busca por dono
        );
    }
    return list;
});

// PAGINAÇÃO COMPUTADA
const paginatedClients = computed(() => {
    const start = (page.value - 1) * itemsPerPage;
    const end = start + itemsPerPage;
    return filteredClients.value.slice(start, end);
});

const totalPages = computed(() => {
    return Math.ceil(filteredClients.value.length / itemsPerPage);
});

// --- EXPORT FUNCTIONS ---

const exportExcel = () => {
    console.log("[DEBUG] [exportExcel] Iniciando...");
    try {
        const headers = ['Nome', 'Documento', 'Email', 'Telefone', 'Cidade', 'Estado', 'Vendedor Resp.', 'Status'];
        const rows = filteredClients.value.map(c => [
            c.nome,
            c.cpf || c.cnpj || '',
            c.email || '',
            c.telefone || '',
            c.cidade || '',
            c.estado || '',
            c.responsible_salesperson?.full_name || 'N/A',
            isClientActive(c) ? 'Ativo' : 'Inativo'
        ]);

        const csvContent = [
            headers.join(';'),
            ...rows.map(r => r.map(field => `"${String(field || '').replace(/"/g, '""')}"`).join(';'))
        ].join('\n');

        const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
        const url = URL.createObjectURL(blob);
        const link = document.createElement("a");
        link.setAttribute("href", url);
        link.setAttribute("download", `clientes_mj_${format(new Date(), 'ddMMyyyy_HHmm')}.csv`);
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
        appStore.showSnackbar("Exportação CSV gerada!", "success");
    } catch (e: any) {
        console.error("[DEBUG] [exportExcel] Erro:", e);
        appStore.showSnackbar("Erro ao exportar CSV", "error");
    }
};

const exportPDF = () => {
    try {
        const doc = new jsPDF();
        doc.text("Relatório de Clientes - MJ Process", 14, 15);
        doc.setFontSize(10);
        doc.text(`Gerado em: ${format(new Date(), 'dd/MM/yyyy HH:mm')}`, 14, 22);

        const columns = [
            { header: 'Nome', dataKey: 'nome' },
            { header: 'Documento', dataKey: 'doc' },
            { header: 'Email', dataKey: 'email' },
            { header: 'Telefone', dataKey: 'tel' },
            { header: 'Cidade', dataKey: 'city' },
            { header: 'Dono', dataKey: 'owner' },
            { header: 'Status', dataKey: 'status' },
        ];

        const data = filteredClients.value.map(c => ({
            nome: c.nome,
            doc: formatDocument(c.cpf || c.cnpj),
            email: c.email || '',
            tel: formatPhone(c.telefone || ''),
            city: `${c.cidade || ''} - ${c.estado || ''}`,
            owner: c.responsible_salesperson?.full_name || '-',
            status: isClientActive(c) ? 'Ativo' : 'Inativo'
        }));

        autoTable(doc, {
            head: [columns.map(c => c.header)],
            body: data.map(obj => columns.map(col => obj[col.dataKey as keyof typeof obj])),
            startY: 30,
            styles: { fontSize: 8 },
            headStyles: { fillColor: [66, 66, 66] }
        });

        doc.save(`clientes_mj_${format(new Date(), 'ddMMyyyy_HHmm')}.pdf`);
        appStore.showSnackbar("Exportação PDF gerada!", "success");
    } catch (e: any) {
        console.error("[DEBUG] [exportPDF] Erro:", e);
        appStore.showSnackbar("Erro ao exportar PDF", "error");
    }
};

// --- SMART SYNC LOGIC ---

const syncWizard = reactive({
    show: false,
    step: 1,
    previewData: [] as any[],
    processed: 0,
    total: 0,
    percent: 0
});

const norm = (str: any) => String(str || '').trim().toLowerCase().replace(/[^\w\s]/gi, '');

const extractErpData = (erp: any) => {
    let endereco = { logradouro: '', numero: '', bairro: '', cidade: '', estado: '', cep: '' };

    if (erp.enderecos && Array.isArray(erp.enderecos) && erp.enderecos.length > 0) {
        const endObj = erp.enderecos[0].endereco;
        if (endObj) {
            endereco.logradouro = endObj.logradouro || '';
            endereco.numero = endObj.numero || '';
            endereco.bairro = endObj.bairro || '';
            endereco.cidade = endObj.nome_cidade || endObj.cidade || '';
            endereco.estado = endObj.estado || '';
            endereco.cep = endObj.cep || '';
        }
    }

    return {
        email: erp.email || '',
        telefone: erp.telefone || erp.celular || '',
        endereco: endereco.logradouro,
        numero: endereco.numero,
        bairro: endereco.bairro,
        cidade: endereco.cidade,
        estado: endereco.estado,
        cep: endereco.cep
    };
};

const hasDataDiff = (erp: any, local: any) => {
    const erpData = extractErpData(erp);

    const checks = [
        { erp: erpData.email, local: local.email, label: 'Email' },
        { erp: erpData.telefone, local: local.telefone, label: 'Telefone' },
        { erp: erpData.endereco, local: local.endereco, label: 'Endereço' },
        { erp: erpData.bairro, local: local.bairro, label: 'Bairro' },
        { erp: erpData.cidade, local: local.cidade, label: 'Cidade' },
        { erp: erpData.cep, local: local.cep, label: 'CEP' },
    ];

    const diffs: string[] = [];
    checks.forEach(c => {
        if (c.erp && norm(c.erp) !== norm(c.local)) {
            diffs.push(`${c.label} (${c.local || 'vazio'} -> ${c.erp})`);
        }
    });

    return diffs.length > 0 ? diffs.join(', ') : null;
};

const checkBackgroundSync = async () => {
    console.log("[DEBUG] [Sync] Verificando atualizações em segundo plano...");
    try {
        const erpClients = await gestaoApi.buscarClientes();
        const localDocMap = new Map(clients.value.map(c => [norm(c.cpf || c.cnpj), c]));

        let updates = 0;

        erpClients.forEach((erp: any) => {
            const doc = norm(erp.cpf || erp.cnpj || erp.cpf_cnpj);
            const local = localDocMap.get(doc);

            if (!local) {
                updates++;
            } else {
                if (hasDataDiff(erp, local)) updates++;
            }
        });

        console.log(`[DEBUG] [Sync] ${updates} divergências encontradas.`);
        pendingSyncCount.value = updates;
    } catch (e) {
        console.warn("[DEBUG] [Sync] Falha na verificação silenciosa:", e);
    }
};

const openSyncWizard = async () => {
    actionsModal.show = false;
    syncWizard.show = true;
    syncWizard.step = 1;
    syncWizard.previewData = [];

    console.log("[DEBUG] [SyncWizard] Iniciando análise completa...");

    try {
        const erpClients = await gestaoApi.buscarClientes('', 1);
        const localDocMap = new Map(clients.value.map(c => [norm(c.cpf || c.cnpj || c.cpf_cnpj), c]));

        const preview: any[] = [];

        for (const erp of erpClients) {
            const doc = norm(erp.cpf || erp.cnpj || erp.cpf_cnpj);
            if (!doc || doc.length < 5) continue;

            const local = localDocMap.get(doc);

            if (!local) {
                preview.push({
                    sync_type: 'new',
                    nome: erp.nome || erp.razao_social,
                    diff_reason: 'Novo no ERP',
                    payload: mapErpToDb(erp),
                    local_id: null
                });
            } else {
                const diffs = hasDataDiff(erp, local);
                if (diffs) {
                    preview.push({
                        sync_type: 'update',
                        nome: local.nome,
                        diff_reason: diffs,
                        payload: mapErpToDb(erp),
                        local_id: local.id
                    });
                }
            }
        }

        syncWizard.previewData = preview;
        syncWizard.step = 2;
    } catch (e) {
        console.error("[DEBUG] [SyncWizard] Erro:", e);
        appStore.showSnackbar("Erro ao buscar dados do ERP", "error");
        syncWizard.show = false;
    }
};

const mapErpToDb = (erp: any) => {
    const erpData = extractErpData(erp);
    const status = (erp.ativo === '1' || erp.ativo === true) ? 'Ativo' : 'Inativo';
    const limit = (str: string, len: number) => str ? String(str).substring(0, len) : null;

    return {
        gestao_click_id: String(erp.id),
        nome: limit(erp.razao_social || erp.nome, 255),
        nome_fantasia: limit(erp.nome_fantasia || erp.nome, 255),
        razao_social: limit(erp.razao_social, 255), // Adicionado campo faltante
        cpf: (erp.cpf || erp.cpf_cnpj)?.length <= 11 ? (erp.cpf || erp.cpf_cnpj) : null,
        cnpj: (erp.cnpj || erp.cpf_cnpj)?.length > 11 ? (erp.cnpj || erp.cpf_cnpj) : null,
        email: limit(erpData.email, 150),
        telefone: limit(erpData.telefone, 20),
        cep: limit(erpData.cep, 10),
        endereco: limit(erpData.endereco, 200),
        numero: limit(erpData.numero, 20),
        bairro: limit(erpData.bairro, 100),
        cidade: limit(erpData.cidade, 100),
        estado: limit(erpData.estado, 2),
        situacao: status
    };
};

const executeSync = async () => {
    console.log("[DEBUG] [SyncWizard] Executando...");
    syncWizard.step = 3;
    syncWizard.total = syncWizard.previewData.length;
    syncWizard.processed = 0;

    for (const item of syncWizard.previewData) {
        try {
            console.log(`[DEBUG] Salvando ${item.nome}... Payload:`, item.payload);

            if (item.sync_type === 'new') {
                const { error } = await supabase.from('customers_mj').insert(item.payload);
                if (error) {
                    console.error("Erro insert Supabase:", error);
                    throw error;
                }
            } else {
                const { error } = await supabase.from('customers_mj').update(item.payload).eq('id', item.local_id);
                if (error) {
                    console.error("Erro update Supabase:", error);
                    throw error;
                }
            }
        } catch (e: any) {
            console.error(`[DEBUG] ERRO ao salvar item ${item.nome}:`, e.message, e.details, e);
        }
        syncWizard.processed++;
        syncWizard.percent = (syncWizard.processed / syncWizard.total) * 100;
        await new Promise(r => setTimeout(r, 50));
    }

    appStore.showSnackbar("Sincronização concluída!", "success");
    syncWizard.show = false;
    pendingSyncCount.value = 0;
    fetchClients();
};

// --- EDIT/CRUD LOGIC ---
const editModal = reactive({
    show: false,
    isNew: false,
    saving: false,
    form: {} as any
});

const openNewClientModal = () => {
    editModal.form = {
        // Logica: Se for novo, o vendedor logado é o responsável
        vendedor_responsavel_id: userStore.user?.id
    };
    editModal.isNew = true;
    editModal.show = true;
};

const openEditModal = (client: any) => {
    editModal.form = {
        ...client,
        cpf_cnpj: client.cpf || client.cnpj
    };
    editModal.isNew = false;
    editModal.show = true;
};

const saveClient = async () => {
    const { valid } = await formRef.value.validate();
    if (!valid) return;

    editModal.saving = true;

    try {
        // 1. Preparação Básica do Payload Local
        const payload = JSON.parse(JSON.stringify(editModal.form));

        // Tratamento de Documento (CPF/CNPJ)
        const doc = payload.cpf_cnpj?.replace(/\D/g, '');
        if (doc) {
            if (doc.length > 11) { payload.cnpj = doc; payload.cpf = null; }
            else { payload.cpf = doc; payload.cnpj = null; }
        }

        // 2. LÓGICA DE INTEGRAÇÃO "AUTO-REGISTER" (O Pulo do Gato)
        // Se o cliente não tem vínculo com o ERP (gestao_click_id vazio), cria lá agora!
        if (!payload.gestao_click_id) {
            try {
                const erpPayload = {
                    nome: payload.nome,
                    nome_fantasia: payload.nome, // Fallback
                    cpf_cnpj: doc,
                    email: payload.email,
                    telefone: payload.telefone,
                    // Mapeando endereço do formulário simplificado para o objeto do ERP
                    enderecos: [{
                        endereco: {
                            cep: payload.cep,
                            logradouro: payload.endereco, // Campo "Endereço" do form vira logradouro
                            numero: 'S/N', // Form de edição simples não tem número, enviamos padrão
                            bairro: payload.bairro,
                            cidade: payload.cidade,
                            estado: payload.estado
                        }
                    }],
                    tipo_pessoa: (doc && doc.length > 11) ? 'PJ' : 'PF'
                };

                // Envia para o GestãoClick
                const newErpClient = await gestaoApi.cadastrarCliente(erpPayload);

                // Se deu certo, pega o ID e vincula no payload que vai pro Supabase
                if (newErpClient && newErpClient.id) {
                    payload.gestao_click_id = String(newErpClient.id);
                    appStore.showSnackbar("Cliente sincronizado e criado no ERP com sucesso!", "success");
                }
            } catch (erpError: any) {
                console.error("Erro ao criar no ERP durante edição:", erpError);
                // Não interrompe o fluxo de salvar local, mas avisa
                appStore.showSnackbar(`Aviso: Salvo localmente, mas falhou no ERP: ${erpError.message}`, "warning");
            }
        }

        // 3. Limpeza Final e Salvamento no Banco (Supabase)
        delete payload.cpf_cnpj;
        delete payload.responsible_salesperson;
        delete payload.orders;
        delete payload.last_purchase_date;
        payload.updated_at = new Date();

        if (editModal.isNew) {
            await supabase.from('customers_mj').insert(payload);
        } else {
            // Agora atualiza garantindo que o gestao_click_id vai junto se foi gerado acima
            await supabase.from('customers_mj').update(payload).eq('id', payload.id);
        }

        showNotify("Salvo com sucesso!", "success");
        editModal.show = false;
        fetchClients();

    } catch (e: any) {
        showNotify("Erro crítico ao salvar: " + e.message, "error");
    } finally {
        editModal.saving = false;
    }
};

const deleteClient = async (client: any) => {
    if(!confirm(`Excluir ${client.nome}?`)) return;
    const { error } = await supabase.from('customers_mj').delete().eq('id', client.id);
    if (!error) {
        appStore.showSnackbar("Cliente excluído.", "success");
        fetchClients();
    } else {
        console.error("[DeleteClient] Erro:", error);
        appStore.showSnackbar("Erro ao excluir.", "error");
    }
};

// UTIL
const formatDocument = (val: string) => val || '-';
const formatPhone = (val: string) => val || '-';
const getColor = (name: string) => { const colors = ['primary', 'secondary', 'info', 'success', 'warning', 'error']; let hash = 0; if(!name) return 'grey'; for(let i=0; i<name.length; i++) hash = name.charCodeAt(i) + ((hash << 5) - hash); return colors[Math.abs(hash) % colors.length]; };

const getSalespersonName = (id: string) => {
    const sp = salespeopleList.value.find(s => s.id === id);
    return sp ? sp.full_name : 'Desconhecido';
};

onMounted(() => {
    fetchSalespeople();
    fetchClients();
    autoSyncInterval.value = setInterval(checkBackgroundSync, 120000);
});

onUnmounted(() => {
    clearInterval(autoSyncInterval.value);
});
</script>

<style scoped lang="scss">
/* LAYOUT */
.clients-layout { position: relative; }
.background-carousel-wrapper { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 0; opacity: 0.6; pointer-events: none; }
.background-overlay { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 1; background: radial-gradient(circle at center, rgba(15, 15, 19, 0.4), rgba(15, 15, 19, 0.98)); backdrop-filter: blur(8px); }
.z-10 { position: relative; z-index: 10; }

.bg-glass-dark { background: rgba(10,10,12,0.85); }
.bg-glass-header { background: rgba(20,20,24,0.55); backdrop-filter: blur(14px); }
.border-bottom-white-05 { border-bottom: 1px solid rgba(255,255,255,0.08); }
.border-thin { border: 1px solid rgba(0,0,0,0.08); }
.bg-white-05 { background: rgba(255,255,255,0.05); }

/* CONTROLS */
.controls-bar { border: 1px solid rgba(0,0,0,0.08); border-radius: 0; padding: 10px; }
.controls-light { background: #ffffff; }
.controls-dark { background: rgba(30,30,35,0.55); backdrop-filter: blur(16px); border: 1px solid rgba(255,255,255,0.08); }

.search-wrap { height: 40px; border-radius: 0; padding: 0 12px; min-width: 300px; max-width: 500px; flex: 1 1 300px; }
.search-light { background: #f4f6f8; border: 1px solid rgba(0,0,0,0.08); }
.search-dark { background: rgba(255,255,255,0.08); border: 1px solid rgba(255,255,255,0.10); }
.clean-input { border: none; outline: none; background: transparent; font-size: 12px; color: inherit; width: 100%; }

.btn-rect { border-radius: 0 !important; text-transform: none !important; font-weight: 800; }
.alert-rect { border-radius: 0 !important; }
.h-40 { height: 40px; }

/* KPIs */
.kpi-card { border: 1px solid rgba(255,255,255,0.15); color: white; min-height: 100px; position: relative; overflow: hidden; }
.kpi-rect { border-radius: 0 !important; }
.kpi-bg-icon { position: absolute; right: -20px; bottom: -20px; opacity: 0.15; transform: rotate(-15deg); pointer-events: none; z-index: 0; }
.kpi-bg-icon .v-icon { font-size: 80px; color: white; }
.kpi-label { font-size: 11px; font-weight: 900; letter-spacing: .2px; text-transform: uppercase; }
.kpi-value { font-size: 20px; font-weight: 900; letter-spacing: .2px; }
.kpi-footer { font-size: 10px; opacity: .9; font-weight: 700; }

.bg-gradient-info { background: linear-gradient(135deg, #0288d1, #005b9f); }
.bg-gradient-success { background: linear-gradient(135deg, #2e7d32, #1b5e20); }
.bg-gradient-purple { background: linear-gradient(135deg, #7b1fa2, #4a148c); }
.bg-gradient-red { background: linear-gradient(135deg, #c62828, #8e0000); }

/* GRID LAYOUT FIX */
.glass-card { background: rgba(30, 30, 35, 0.45); backdrop-filter: blur(25px); border: 1px solid rgba(255,255,255,0.08); }
.grid-scroll { scrollbar-gutter: stable both-edges; }
.custom-scroll::-webkit-scrollbar { width: 8px; height: 8px; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.35); border-radius: 6px; }
.custom-scroll::-webkit-scrollbar-track { background: transparent; }

.grid-header, .grid-row { display: grid; align-items: stretch; width: 100%; border-bottom: 1px solid rgba(0,0,0,0.08); }

/* DEFINIÇÃO EXATA DAS COLUNAS */
.grid-layout {
  grid-template-columns: 50px 2fr 120px 200px 1.5fr 100px 100px;
}

.cell { padding: 8px 10px; display: flex; align-items: center; border-right: 1px solid rgba(0,0,0,0.08); min-height: 52px; overflow: hidden; }
.center { justify-content: center; text-align: center; }

.grid-header .cell { min-height: 44px; font-size: 11px; font-weight: 900; text-transform: uppercase; letter-spacing: .6px; }
.header-text { font-size: 11px; }

.grid-surface-light .cell { background: #f5f7fa; color: rgba(0,0,0,0.7); border-color: rgba(0,0,0,0.10); }
.grid-surface-dark .cell { background: rgba(255,255,255,0.08); color: rgba(255,255,255,0.80); border-color: rgba(255,255,255,0.10); }

.grid-row-light .cell { background: #fff; border-color: rgba(0,0,0,0.08); }
.grid-row-light:hover .cell { background: #f7fafc; }
.grid-row-dark .cell { background: rgba(255,255,255,0.04); border-color: rgba(255,255,255,0.08); }
.grid-row-dark:hover .cell { background: rgba(255,255,255,0.07); }

.sticky-head { position: sticky; top: 0; z-index: 10; }

/* UTILS */
.list-text-11 { font-size: 11px !important; line-height: 1.25 !important; }
.list-text-10 { font-size: 10px !important; line-height: 1.25 !important; }
.cursor-pointer { cursor: pointer; }

.solid-chip { display: inline-flex; align-items: center; justify-content: center; height: 22px; padding: 0 10px; border-radius: 6px; font-size: 10px; font-weight: 900; color: #fff; white-space: nowrap; text-transform: uppercase; }
.chip-success { background: #2e7d32; }
.chip-warning { background: #f57f17; }
.chip-danger { background: #c62828; }

.actions-inline { display: flex; align-items: center; justify-content: center; gap: 6px; }
.action-btn { width: 28px !important; height: 28px !important; border-radius: 6px !important; color: #fff !important; }
.action-edit { background: #fb8c00 !important; }
.action-del { background: #c62828 !important; }
.chk-fixed { margin: 0 !important; padding: 0 !important; }

/* ACTIONS MODAL */
.actions-side {
  width: 300px;
  padding: 24px;
  background: linear-gradient(135deg, rgba(244,67,54,0.12), rgba(0,0,0,0.02));
  border-right: 1px solid rgba(0,0,0,0.08);
  display: flex;
  flex-direction: column;
}
.actions-content { flex: 1; display: flex; flex-direction: column; }
.actions-top { border-bottom: 1px solid rgba(0,0,0,0.08); background: rgba(0,0,0,0.02); }
</style>
