<template>
  <v-dialog
    v-model="internalShow"
    width="1400"
    height="95vh"
    persistent
    scrim="black opacity-80"
    transition="dialog-bottom-transition"
    class="fixed-dialog"
  >
    <v-card class="d-flex flex-row overflow-hidden rounded-xl fill-height shadow-2xl" :class="isDark ? 'bg-grey-darken-4 text-white' : 'bg-white'">

      <div class="modal-sidebar d-flex flex-column h-100 flex-shrink-0" :class="isDark ? 'bg-grey-darken-4 border-r border-white-10' : 'bg-grey-lighten-5 border-r border-grey-lighten-2'" style="width: 280px; z-index: 10;">
        <div class="pa-6 d-flex flex-column align-center text-center relative">
           <v-hover v-slot="{ isHovering, props }">
              <v-avatar v-bind="props" size="100" rounded="circle" class="elevation-2 border-white-20 relative cursor-pointer mb-3 transition-all" :class="isDark ? 'bg-grey-darken-3' : 'bg-white'" @click="triggerAvatarUpload">
                  <v-img v-if="editedUser.avatar_url" :src="editedUser.avatar_url" cover></v-img>
                  <v-icon v-else size="46" :color="isDark ? 'white-50' : 'grey-lighten-1'">mdi-camera-account</v-icon>
                  <div class="absolute-fill d-flex align-center justify-center rounded-circle transition-all" :class="isHovering ? 'bg-black-50 opacity-100' : 'opacity-0'">
                      <v-icon color="white" size="32">mdi-cloud-upload</v-icon>
                  </div>
              </v-avatar>
           </v-hover>
           <input type="file" ref="avatarInput" class="d-none" accept="image/*" @change="onAvatarChange">

           <div class="text-subtitle-1 font-weight-black text-uppercase line-height-1-2 px-2 text-truncate w-100" :class="isDark ? 'text-white' : 'text-blue-grey-darken-4'">
             {{ editedUser.full_name || 'Novo Colaborador' }}
           </div>
           <div class="text-caption font-mono mt-1 text-truncate w-100" :class="isDark ? 'text-white-70' : 'text-grey-darken-1'">
             {{ editedUser.email || 'Email pendente' }}
           </div>

           <v-chip size="small" :color="editedUser.is_active ? 'success' : 'error'" variant="tonal" class="mt-4 font-weight-bold text-uppercase px-4">
               {{ editedUser.is_active ? 'Acesso Liberado' : 'Conta Bloqueada' }}
           </v-chip>
        </div>

        <v-tabs v-model="activeTab" direction="vertical" :color="isDark ? 'primary-lighten-2' : 'primary-darken-1'" bg-color="transparent" class="flex-grow-1 mt-2">
          <v-tab value="basic" class="justify-start font-weight-bold text-body-2 pl-6 h-14 transition-all hover-grey">
            <v-icon start size="20" class="mr-4 opacity-70">mdi-card-account-details-outline</v-icon> Identificação Base
          </v-tab>
          <v-tab value="links" class="justify-start font-weight-bold text-body-2 pl-6 h-14 transition-all hover-grey">
            <v-icon start size="20" class="mr-4 opacity-70">mdi-sitemap-outline</v-icon> Vínculos & Regras
          </v-tab>
          <v-tab value="permissions" class="justify-start font-weight-bold text-body-2 pl-6 h-14 transition-all hover-grey">
            <v-icon start size="20" class="mr-4 opacity-70">mdi-shield-lock-outline</v-icon> Permissões de Acesso
          </v-tab>
          <v-tab value="integrations" class="justify-start font-weight-bold text-body-2 pl-6 h-14 transition-all hover-grey">
            <v-icon start size="20" class="mr-4 opacity-70">mdi-api</v-icon> Integrações Externas
          </v-tab>
        </v-tabs>
      </div>

      <div class="flex-grow-1 d-flex flex-column h-100 overflow-hidden relative">
         <div class="pa-5 px-8 border-b d-flex justify-space-between align-center z-10 flex-shrink-0" :class="isDark ? 'bg-grey-darken-4 border-white-10' : 'bg-white border-grey-lighten-2'">
            <div class="d-flex flex-column">
                <span class="text-caption font-weight-black opacity-60 text-uppercase tracking-widest">Painel Administrativo</span>
                <span class="text-h6 font-weight-black tracking-tight" :class="isDark ? 'text-white' : 'text-blue-grey-darken-4'">Configuração de Perfil</span>
            </div>
            <v-btn icon="mdi-close" variant="tonal" color="grey" size="small" class="btn-3d" @click="closeModal"></v-btn>
         </div>

         <div class="flex-grow-1 overflow-y-auto custom-scroll pa-6 pa-md-8 relative" :class="isDark ? 'bg-grey-darken-5' : 'bg-grey-lighten-5'">
            <v-form ref="userForm" @submit.prevent="saveUser" id="userForm">
               <v-window v-model="activeTab" class="w-100" :touch="false">

                   <v-window-item value="basic">
                       <div class="section-card">
                           <v-row class="row-gap">
                              <v-col cols="12" md="6">
                                 <label class="input-label">Nome Completo *</label>
                                 <v-text-field v-model="editedUser.full_name" variant="outlined" density="comfortable" class="ui-field" :rules="[rules.required]" placeholder="Ex: João Silva"></v-text-field>
                              </v-col>
                              <v-col cols="12" md="6">
                                 <label class="input-label">E-mail de Acesso *</label>
                                 <v-text-field v-model="editedUser.email" type="email" variant="outlined" density="comfortable" class="ui-field" :rules="isEdit ? [] : [rules.required, rules.email]" :disabled="isEdit" append-inner-icon="mdi-email-outline"></v-text-field>
                              </v-col>
                              <v-col cols="12" md="6" v-if="!isEdit">
                                 <label class="input-label">Senha Inicial *</label>
                                 <v-text-field v-model="editedUser.password" type="password" variant="outlined" density="comfortable" class="ui-field" :rules="[rules.required, rules.minLength(6)]" placeholder="Mínimo de 6 caracteres" append-inner-icon="mdi-lock-outline"></v-text-field>
                              </v-col>
                              <v-col cols="12" md="6">
                                 <label class="input-label text-orange-darken-3">PIN Numérico (Opcional - PDV)</label>
                                 <v-text-field v-model="editedUser.security_pin" type="text" variant="outlined" density="comfortable" class="ui-field font-weight-bold" placeholder="Ex: 1234" maxlength="6" append-inner-icon="mdi-dialpad"></v-text-field>
                              </v-col>
                           </v-row>

                           <div class="mt-8 pa-4 rounded-lg d-flex align-center justify-space-between border-thin" :class="isDark ? 'bg-grey-darken-4 border-white-10' : 'bg-grey-lighten-4'">
                              <div>
                                 <div class="font-weight-black text-body-2 uppercase">Status da Conta</div>
                                 <div class="text-caption opacity-70">Desative para bloquear o acesso instantaneamente. O histórico não é apagado.</div>
                              </div>
                              <v-switch v-model="editedUser.is_active" color="success" hide-details density="compact" inset></v-switch>
                           </div>
                       </div>
                   </v-window-item>

                   <v-window-item value="links">
                       <div class="section-card mb-6">
                           <h4 class="text-subtitle-2 font-weight-black text-uppercase opacity-70 mb-4">Estrutura & Financeiro</h4>
                           <v-row class="row-gap-sm">
                              <v-col cols="12" md="6">
                                 <label class="input-label text-primary">Vincular Pessoa Física (RH)</label>
                                 <v-autocomplete v-model="editedUser.employee_id" :items="auxData.employeesList" item-title="nome" item-value="id" variant="outlined" density="comfortable" class="ui-field" clearable placeholder="Busque o funcionário"></v-autocomplete>
                              </v-col>
                              <v-col cols="12" md="6">
                                 <label class="input-label">Empresa Matriz Padrão (Holding)</label>
                                 <v-autocomplete v-model="editedUser.company_id" :items="auxData.companiesList" item-title="trade_name" item-value="id" variant="outlined" density="comfortable" class="ui-field" clearable placeholder="Contexto base de trabalho"></v-autocomplete>
                              </v-col>
                              <v-col cols="12" md="6">
                                 <label class="input-label">Unidade Física Base (Loja)</label>
                                 <v-select v-model="editedUser.store_id" :items="auxData.stores" item-title="name" item-value="id" variant="outlined" density="comfortable" class="ui-field" clearable placeholder="Filial principal"></v-select>
                              </v-col>
                              <v-col cols="12" md="6">
                                 <label class="input-label text-orange-darken-3">Comissão Base do Vendedor (%)</label>
                                 <v-text-field v-model.number="editedUser.commission_percentage" type="number" suffix="%" variant="outlined" density="comfortable" class="ui-field font-weight-bold" placeholder="0.00"></v-text-field>
                              </v-col>
                           </v-row>
                       </div>

                       <div class="section-card">
                           <h4 class="text-subtitle-2 font-weight-black text-uppercase opacity-70 mb-4">Comportamentos Específicos</h4>
                           <v-row dense class="row-gap-sm">
                               <v-col cols="12" sm="6">
                                   <div class="behavior-card" :class="editedUser.can_move_cash ? 'active-amber' : ''">
                                       <div class="d-flex align-center justify-space-between mb-2">
                                           <span class="text-caption font-weight-black uppercase">Caixa PDV</span>
                                           <v-switch v-model="editedUser.can_move_cash" color="warning" density="compact" hide-details inset></v-switch>
                                       </div>
                                       <span class="text-[11px] opacity-70 leading-tight">Pode abrir, fechar, sangrar e suprir o caixa da loja.</span>
                                   </div>
                               </v-col>
                               <v-col cols="12" sm="6">
                                   <div class="behavior-card" :class="editedUser.is_design_leader ? 'active-purple' : ''">
                                       <div class="d-flex align-center justify-space-between mb-2">
                                           <span class="text-caption font-weight-black uppercase">Líder Design</span>
                                           <v-switch v-model="editedUser.is_design_leader" color="deep-purple" density="compact" hide-details inset></v-switch>
                                       </div>
                                       <span class="text-[11px] opacity-70 leading-tight">Visão global do Kanban, avalia a equipe.</span>
                                   </div>
                               </v-col>
                               <v-col cols="12" sm="6">
                                   <div class="behavior-card" :class="editedUser.requires_design_approval ? 'active-red' : ''">
                                       <div class="d-flex align-center justify-space-between mb-2">
                                           <span class="text-caption font-weight-black uppercase">Requer Avaliação (Júnior)</span>
                                           <v-switch v-model="editedUser.requires_design_approval" color="error" density="compact" hide-details inset></v-switch>
                                       </div>
                                       <span class="text-[11px] opacity-70 leading-tight">Artes criadas ficam retidas até um líder aprovar.</span>
                                   </div>
                               </v-col>
                               <v-col cols="12" sm="6">
                                   <div class="behavior-card" :class="editedUser.can_approve_design ? 'active-blue' : ''">
                                       <div class="d-flex align-center justify-space-between mb-2">
                                           <span class="text-caption font-weight-black uppercase">Sub-Líder (Aprovador)</span>
                                           <v-switch v-model="editedUser.can_approve_design" color="info" density="compact" hide-details inset></v-switch>
                                       </div>
                                       <span class="text-[11px] opacity-70 leading-tight">Pode aprovar artes no lugar do líder oficial.</span>
                                   </div>
                               </v-col>
                           </v-row>
                       </div>
                   </v-window-item>

                   <v-window-item value="permissions">
                       <div class="bg-primary-lighten-5 border-thin border-primary-lighten-3 rounded-lg pa-5 mb-6 d-flex align-center gap-5 shadow-sm" :class="isDark ? 'bg-grey-darken-4 border-white-10' : ''">
                           <div class="flex-grow-1">
                               <div class="d-flex align-center gap-3 mb-1">
                                   <v-icon :color="isDark ? 'primary-lighten-2' : 'primary-darken-2'" size="24">mdi-briefcase-download</v-icon>
                                   <span class="font-weight-black text-subtitle-1 text-uppercase tracking-tight" :class="isDark ? 'text-white' : 'text-primary-darken-3'">Herdar Template de Cargo</span>
                               </div>
                               <p class="text-caption mb-0 opacity-80" :class="isDark ? 'text-white' : 'text-primary-darken-4'">Selecione um cargo para preencher a matriz de permissões instantaneamente.</p>
                           </div>
                           <div style="min-width: 320px;">
                               <v-autocomplete
                                   v-model="editedUser.custom_role_id"
                                   :items="auxData.customRoles"
                                   item-title="name"
                                   item-value="id"
                                   variant="outlined"
                                   density="compact"
                                   :bg-color="isDark ? 'grey-darken-3' : 'white'"
                                   hide-details
                                   clearable
                                   placeholder="Buscar template..."
                                   @update:model-value="handleRoleTemplateSelection"
                                   class="ui-field"
                               >
                                   <template v-slot:item="{ props, item }">
                                       <v-list-item v-bind="props" :subtitle="item.raw.is_supervisor ? 'Possui nível de Supervisão' : 'Operacional'">
                                           <template v-slot:prepend><v-icon :color="item.raw.is_supervisor ? 'warning' : 'grey'" class="mr-3">mdi-briefcase</v-icon></template>
                                       </v-list-item>
                                   </template>
                               </v-autocomplete>
                           </div>
                       </div>

                       <div class="d-flex rounded-lg border-thin overflow-hidden shadow-sm" :class="isDark ? 'bg-grey-darken-4 border-white-10' : 'bg-white'" style="height: 55vh; min-height: 500px;">

                           <div class="flex-shrink-0 d-flex flex-column h-100" :class="isDark ? 'bg-grey-darken-3 border-r border-white-10' : 'bg-grey-lighten-5 border-r border-grey-lighten-2'" style="width: 280px;">
                               <v-list density="compact" nav bg-color="transparent" class="pa-3 flex-grow-1 overflow-y-auto custom-scroll">
                                   <v-list-item
                                       v-for="(mod, idx) in updatedPermissionTree"
                                       :key="mod.module"
                                       :active="activePermissionModule === idx"
                                       @click="activePermissionModule = idx"
                                       :active-color="isDark ? 'primary-lighten-1' : 'primary-darken-1'"
                                       class="mb-1 rounded-md transition-colors"
                                       :class="isDark ? 'hover-bg-grey' : 'hover-bg-grey'"
                                   >
                                       <template v-slot:prepend>
                                           <v-icon size="18" :color="activePermissionModule === idx ? 'primary' : 'grey'" class="opacity-80">{{ mod.icon }}</v-icon>
                                       </template>
                                       <v-list-item-title class="text-caption font-weight-bold">{{ mod.module }}</v-list-item-title>
                                   </v-list-item>
                               </v-list>
                           </div>

                           <div class="flex-grow-1 h-100 overflow-y-auto custom-scroll bg-texture pa-6">
                               <div class="mb-4">
                                   <h3 class="text-h6 font-weight-black tracking-tight mb-1" :class="isDark ? 'text-white' : 'text-blue-grey-darken-4'">{{ currentModuleData?.module }}</h3>
                                   <p class="text-caption opacity-70">Libere o acesso às telas usando as chaves de seleção. Utilize os controles avançados para impor restrições.</p>
                               </div>

                               <v-expansion-panels variant="accordion" class="elevation-0 bg-transparent gap-2">
                                   <v-expansion-panel
                                       v-for="cat in currentModuleData?.categories"
                                       :key="cat.name"
                                       class="border-thin rounded-lg overflow-hidden mb-3"
                                       :class="isDark ? 'bg-grey-darken-4 border-white-10' : 'bg-white border-grey-lighten-2'"
                                   >
                                       <v-expansion-panel-title class="font-weight-black text-caption text-uppercase tracking-wider py-3" :class="isDark ? 'bg-grey-darken-3' : 'bg-grey-lighten-4'">
                                           <v-icon size="16" class="mr-3 opacity-60">mdi-folder-open-outline</v-icon> {{ cat.name }}
                                       </v-expansion-panel-title>

                                       <v-expansion-panel-text class="pa-0">
                                           <div class="d-flex flex-column">
                                               <div v-for="(perm, pIdx) in cat.items" :key="perm.value" class="px-4 py-3 d-flex align-center justify-space-between transition-colors" :class="[pIdx < cat.items.length - 1 ? 'border-b' : '', isDark ? 'border-white-05 hover-bg-grey' : 'border-grey-lighten-3 hover-bg-grey', editedUser.permissions.includes(perm.value) ? (isDark ? 'bg-primary-darken-4 opacity-90' : 'bg-blue-lighten-5') : '']">

                                                   <v-checkbox-btn v-model="editedUser.permissions" :value="perm.value" color="primary" class="flex-shrink-0 mr-3"></v-checkbox-btn>

                                                   <div class="flex-grow-1 cursor-pointer" @click="togglePermission(perm.value)">
                                                       <span class="text-body-2 font-weight-bold">{{ perm.label }}</span>
                                                   </div>

                                                   <div class="d-flex align-center gap-2 flex-shrink-0 ml-4" v-if="editedUser.permissions.includes(perm.value)">

                                                       <v-btn-toggle
                                                           v-model="editedUser.read_only_permissions"
                                                           multiple
                                                           variant="outlined"
                                                           density="compact"
                                                           class="rounded btn-group-strict"
                                                       >
                                                           <v-btn :value="perm.value" size="small" class="text-none px-2" :color="isReadOnlyActive(perm.value) ? 'warning' : 'grey'">
                                                               <v-icon start size="14">{{ isReadOnlyActive(perm.value) ? 'mdi-eye-off' : 'mdi-pencil-outline' }}</v-icon>
                                                               <span class="text-[10px] font-weight-bold">{{ isReadOnlyActive(perm.value) ? 'Só Leitura' : 'Edição' }}</span>
                                                           </v-btn>
                                                       </v-btn-toggle>

                                                       <v-btn
                                                           v-if="perm.tables && perm.tables.length > 0"
                                                           variant="outlined"
                                                           size="small"
                                                           class="text-none px-2 rounded btn-group-strict"
                                                           :color="isDeleteActive(perm) ? 'error' : 'grey'"
                                                           @click="toggleDelete(perm)"
                                                           style="height: 32px;"
                                                       >
                                                           <v-icon start size="14">{{ isDeleteActive(perm) ? 'mdi-delete-empty' : 'mdi-delete-off' }}</v-icon>
                                                           <span class="text-[10px] font-weight-bold">{{ isDeleteActive(perm) ? 'Pode Excluir' : 'Sem Exclusão' }}</span>
                                                       </v-btn>
                                                   </div>
                                               </div>
                                           </div>
                                       </v-expansion-panel-text>
                                   </v-expansion-panel>
                               </v-expansion-panels>

                           </div>
                       </div>
                   </v-window-item>

                   <v-window-item value="integrations">
                       <div class="section-card">
                           <h4 class="text-subtitle-2 font-weight-black text-uppercase opacity-70 mb-4">Integrações de API Externas</h4>
                           <v-row class="row-gap">
                              <v-col cols="12" md="6">
                                 <label class="input-label">ID Integração ERP (GestãoClick)</label>
                                 <v-text-field v-model="editedUser.gestao_click_id" variant="outlined" density="comfortable" class="ui-field" placeholder="Apenas Números" append-inner-icon="mdi-sync"></v-text-field>
                              </v-col>
                              <v-col cols="12" md="6">
                                 <label class="input-label">ID Assistente IA (Thread Memory)</label>
                                 <v-text-field v-model="editedUser.assistant_thread_id" variant="outlined" density="comfortable" class="ui-field" placeholder="Automático" readonly hint="Gerado automaticamente pela IA para manter contexto." persistent-hint append-inner-icon="mdi-robot-outline"></v-text-field>
                              </v-col>
                           </v-row>
                       </div>
                   </v-window-item>

               </v-window>
            </v-form>
         </div>

         <div class="pa-5 px-8 border-t d-flex justify-end align-center flex-shrink-0 z-10 shadow-up" :class="isDark ? 'bg-grey-darken-5 border-white-10' : 'bg-white border-grey-lighten-2'" style="gap: 12px;">
            <v-btn variant="tonal" class="btn-3d font-weight-bold px-6 text-none" height="44" color="grey" @click="closeModal" :disabled="isSaving">Cancelar</v-btn>
            <v-btn color="primary" variant="flat" class="btn-3d px-10 font-weight-black text-body-2 text-none" height="44" type="submit" form="userForm" :loading="isSaving">
                <v-icon start size="20">mdi-content-save</v-icon> Salvar Colaborador
            </v-btn>
         </div>
      </div>
    </v-card>
  </v-dialog>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted } from 'vue';
import { supabase } from '@/api/supabase';
import { useAppStore } from '@/stores/app';
import { useThemeStore } from '@/stores/theme';
import { useUserStore } from '@/stores/user';
import type { VForm } from 'vuetify/components';

const props = defineProps<{
    user: any | null,
    auxData: any
}>();

const emit = defineEmits(['close', 'saved']);

const appStore = useAppStore();
const themeStore = useThemeStore();
const userStore = useUserStore();

const isDark = computed(() => themeStore.currentMode !== 'light');
const internalShow = ref(true);
const activeTab = ref('basic');
const isSaving = ref(false);
const userForm = ref<VForm | null>(null);
const avatarInput = ref<HTMLInputElement | null>(null);

const activePermissionModule = ref(0);

// ÁRVORE DE PERMISSÕES 100% REVISADA (COMPLETA E INCLUINDO ESTOQUE)
const updatedPermissionTree = computed(() => {
    return [
        {
            module: 'Visão Geral & Tarefas',
            icon: 'mdi-view-dashboard',
            categories: [
                { name: 'Dashboard Principal', items: [
                    { value: 'view_dashboard', label: 'Acessar Dashboard ERP', tables: [] },
                    { value: 'view_tasks', label: 'Gerenciar Tarefas/Projetos', tables: ['tasks'] },
                    { value: 'operacional_corte', label: 'Acessar Painel Cortadora a Laser', tables: [] }
                ]}
            ]
        },
        {
            module: 'Cadastros Base',
            icon: 'mdi-database-edit',
            categories: [
                { name: 'Entidades Comerciais', items: [
                    { value: 'cad_clients', label: 'Gestão de Clientes', tables: ['customers_mj'] },
                    { value: 'cad_suppliers', label: 'Gestão de Fornecedores', tables: ['suppliers_mj'] },
                    { value: 'cad_machines', label: 'Gestão de Máquinas', tables: ['machines_mj'] },
                    { value: 'cad_machines_adicionar', label: 'Gestão de Máquinas Adicionar', tables: ['machines_mj'] },
                    { value: 'cad_machines_editar', label: 'Gestão de Máquinas Editar', tables: ['machines_mj'] },
                    { value: 'cad_machines_excluir', label: 'Gestão de Máquinas Excluir', tables: ['machines_mj'] }
                ]}
            ]
        },
        {
            module: 'Vendas & Negociações',
            icon: 'mdi-storefront',
            categories: [
                { name: 'Operacional', items: [
                    { value: 'sales_my_orders', label: 'Minhas Vendas (Criar/Editar)', tables: ['orders'] },
                    { value: 'sales_store', label: 'Vendas Balcão (Loja / PDV)', tables: ['store_sales'] },
                    { value: 'sales_management', label: 'Gestão Global de Pedidos', tables: ['orders'] }
                ]},
                { name: 'Consultas Gerais', items: [
                    { value: 'sales_global_consult', label: 'Consulta Global (Ref. Vendidas)', tables: [] },
                    { value: 'sales_price_list', label: 'Visualizar Tabela de Preços', tables: [] },
                    { value: 'sales_didatic', label: 'Material Didático de Vendas', tables: [] }
                ]},
                { name: 'Gerencial', items: [
                    { value: 'admin_sales_area', label: 'Gráficos e Estatísticas de Vendas', tables: [] }
                ]}
            ]
        },
        {
            module: 'Produtos & Compras',
            icon: 'mdi-package-variant',
            categories: [
                { name: 'Controle de Estoque', items: [
                    { value: 'prod_stock', label: 'Consultar Estoque (Leitura)', tables: ['stock'] },
                    { value: 'prod_stock_mgmt', label: 'Gestão de Estoque (Lançar/Ajustar)', tables: ['stock'] }
                ]},
                { name: 'Processos de Compra', items: [
                    { value: 'pur_quotations', label: 'Cotações de Compra', tables: [] },
                    { value: 'pur_products', label: 'Gestão de Produtos', tables: [] },
                    { value: 'pur_services', label: 'Ordem de Serviços (Terceiros)', tables: [] }
                ]}
            ]
        },
        {
            module: 'Design Gráfico',
            icon: 'mdi-palette-swatch',
            categories: [
                { name: 'Workflow do Estúdio', items: [
                    { value: 'des_kanban', label: 'Visualizar Kanban Design', tables: [] },
                    { value: 'des_request', label: 'Solicitar Desenvolvimento', tables: [] },
                    { value: 'mfg_approvals', label: 'Aprovações de Arte', tables: [] },
                    { value: 'des_catalog', label: 'Catálogo de Estampas (Interno)', tables: [] }
                ]}
            ]
        },
        {
            module: 'Produção Industrial',
            icon: 'mdi-factory',
            categories: [
                { name: 'Chão de Fábrica', items: [
                    { value: 'mfg_launches', label: 'Painel de Lançamentos', tables: [] },
                    { value: 'mfg_control', label: 'Acesso Geral ao PCP', tables: [] },

                    { value: 'mfg_colecao', label: 'Kanban Coleção', tables: [] },
                    { value: 'mfg_colecao_arrastar', label: 'Arrastar card em coleção', tables: [] },
                    { value: 'mfg_colecao_editar', label: 'Editar card em coleção', tables: [] },
                    { value: 'mfg_colecao_excluir', label: 'Excluir card em coleção', tables: [] },
                    { value: 'mfg_colecao_cadastrar', label: 'Cadastrar card em coleção', tables: [] },

                    { value: 'mfg_producao', label: 'Kanban Produção', tables: [] },
                    { value: 'mfg_producao_arrastar', label: 'Arrastar card em produção', tables: [] },
                    { value: 'mfg_producao_editar', label: 'Editar card em produção', tables: [] },
                    { value: 'mfg_producao_excluir', label: 'Excluir card em produção', tables: [] },
                    { value: 'mfg_producao_cadastrar', label: 'Cadastrar card em produção', tables: [] },

                    { value: 'mfg_printing', label: 'Estação de Impressão (Módulo Solo)', tables: [] },
                    { value: 'mfg_release', label: 'Liberação e Qualidade', tables: [] },
                    { value: 'mfg_in_production', label: 'Rastreio Em Produção', tables: [] }
                ]},
                { name: 'Controle de Abas do PCP', items: [
                    { value: 'pcp_tab_design', label: 'Aba: Design (Finalização)', tables: [] },
                    { value: 'pcp_tab_pcp', label: 'Aba: PCP Geral', tables: [] },
                    { value: 'pcp_tab_separacao', label: 'Aba: Separação', tables: [] },
                    { value: 'pcp_tab_impressao', label: 'Aba: Impressão', tables: [] },
                    { value: 'pcp_tab_calandra', label: 'Aba: Calandra', tables: [] },
                    { value: 'pcp_tab_faturamento', label: 'Aba: Faturamento', tables: [] },
                    { value: 'pcp_tab_liberacao', label: 'Aba: Expedição', tables: [] }
                ]}
            ]
        },
        {
            module: 'Logística & Frota',
            icon: 'mdi-truck',
            categories: [
                { name: 'Expedição e Veículos', items: [
                    { value: 'log_delivery', label: 'Controle de Entregas', tables: [] },
                    { value: 'fleet_vehicles', label: 'Gestão de Veículos', tables: [] },
                    { value: 'fleet_refueling', label: 'Registro de Abastecimento', tables: [] }
                ]}
            ]
        },
        {
            module: 'Financeiro',
            icon: 'mdi-finance',
            categories: [
                { name: 'Caixa e Bancos', items: [
                    { value: 'fin_receivables', label: 'Contas a Receber', tables: ['finance_receivables'] },
                    { value: 'fin_payables', label: 'Contas a Pagar', tables: ['finance_payables'] },
                    { value: 'fin_accounts', label: 'Contas Bancárias e Conciliação', tables: ['finance_accounts'] },
                    { value: 'fin_statement', label: 'Extrato Bancário', tables: ['finance_transactions'] }
                ]}
            ]
        },
        {
            module: 'Fiscal & Tributário',
            icon: 'mdi-file-document',
            categories: [
                { name: 'Documentos Fiscais', items: [
                    { value: 'fisc_nfe_sell', label: 'Emissor NFe (Venda)', tables: [] },
                    { value: 'fisc_nfe_buy', label: 'Monitor NFe (Compras)', tables: [] },
                    { value: 'fisc_nfce_sell', label: 'Emissor NFCe', tables: [] },
                    { value: 'fisc_cte_issuer', label: 'Emissor CTe', tables: [] }
                ]},
                { name: 'Cadastros Contábeis', items: [
                    { value: 'fisc_companies', label: 'Empresas / Holding', tables: [] },
                    { value: 'fisc_stores', label: 'Lojas / Filiais', tables: [] },
                    { value: 'fisc_chart', label: 'Plano de Contas', tables: [] },
                    { value: 'fisc_pay_methods', label: 'Formas de Pagamento', tables: [] },
                    { value: 'fisc_tax_rules', label: 'Regras Tributárias (ICMS)', tables: [] }
                ]}
            ]
        },
        {
            module: 'Relatórios Gerenciais',
            icon: 'mdi-chart-box',
            categories: [
                { name: 'Financeiro e Vendas', items: [
                    { value: 'view_reports', label: 'Acessar Hub de Relatórios', tables: [] },
                    { value: 'rep_fin_payables', label: 'Relatório Contas a Pagar', tables: [] },
                    { value: 'rep_fin_receivables', label: 'Relatório Contas a Receber', tables: [] },
                    { value: 'rep_fin_dre', label: 'Relatório DRE', tables: [] },
                    { value: 'rep_sales', label: 'Relatórios e Auditoria de Vendas', tables: [] }
                ]},
                { name: 'Movimentação e Estoque', items: [
                    { value: 'rep_stock_movements', label: 'Relatório de Movimentações (Entrada/Saída)', tables: [] },
                    { value: 'rep_stock_inventory', label: 'Inventário e Saldo', tables: [] }
                ]}
            ]
        },
        {
            module: 'Recursos Humanos',
            icon: 'mdi-account-group',
            categories: [
                { name: 'Time e Controle', items: [
                    { value: 'cad_employees', label: 'Dossiê Colaboradores', tables: ['employees_mj'] },
                    { value: 'rh_ponto', label: 'Gestão de Ponto Eletrônico e Totem', tables: [] },
                    { value: 'rh_beneficios', label: 'Gestão de Benefícios', tables: [] }
                ]}
            ]
        },
        {
            module: 'Marketplace B2B',
            icon: 'mdi-storefront-outline',
            categories: [
                { name: 'Administração do Hub', items: [
                    { value: 'admin_integrations', label: 'Acesso Global ao Hub B2B (Layout/VIP)', tables: [] }
                ]}
            ]
        },
        {
            module: 'Loja Varejo (Cajuia)',
            icon: 'mdi-shopping',
            categories: [
                { name: 'Sistema Loja Cajuia', items: [
                    { value: 'cajuia_dashboard', label: 'Painel Vendedor / Dashboard', tables: [] },
                    { value: 'cajuia_orders', label: 'Gestão de Pedidos Cajuia', tables: [] },
                    { value: 'cajuia_nfe', label: 'Emissor NFe Cajuia', tables: [] },
                    { value: 'cajuia_clients', label: 'Base de Clientes Cajuia', tables: [] },
                    { value: 'cajuia_financial', label: 'Financeiro Cajuia', tables: [] },
                    { value: 'cajuia_admin', label: 'Administração Cajuia', tables: [] }
                ]}
            ]
        },
        {
            module: 'Administração Sistema',
            icon: 'mdi-shield-crown',
            categories: [
                { name: 'Segurança Global', items: [
                    { value: 'admin_general', label: 'Painel Geral de Configurações (Admin Master)', tables: [] },
                    { value: 'config_low_stock_alerts', label: 'Configurar Alertas Automáticos (SRE)', tables: [] }
                ]}
            ]
        }
    ];
});

const currentModuleData = computed(() => {
    if (activePermissionModule.value >= 0 && activePermissionModule.value < updatedPermissionTree.value.length) {
        return updatedPermissionTree.value[activePermissionModule.value];
    }
    return null;
});

const isEdit = computed(() => !!props.user);

const rules = {
  required: (v: any) => !!v || 'Campo obrigatório',
  email: (v: string) => /.+@.+\..+/.test(v) || 'E-mail inválido',
  minLength: (len: number) => (v: string) => (v && v.length >= len) || `Mínimo ${len} caracteres`
};

const editedUser = reactive<any>({
  id: null,
  full_name: '',
  email: '',
  password: '',
  role: null,
  cajuia_role: null,
  gestao_click_id: null,
  store_id: null,
  employee_id: null,
  company_id: null,
  custom_role_id: null,
  can_access_crm: false,
  can_move_cash: true,
  is_active: true,
  security_pin: '',
  avatar_url: null,
  assistant_thread_id: null,
  commission_percentage: 0,
  permissions: [] as string[],
  read_only_permissions: [] as string[],
  delete_permissions: [] as string[],
  is_design_leader: false,
  requires_design_approval: false,
  can_approve_design: false
});

onMounted(() => {
    if (props.user) {
        Object.assign(editedUser, {
            ...props.user,
            email: props.user.email || '',
            commission_percentage: props.user.commission_percentage || 0,
            employee_id: props.user.employee_id || null,
            company_id: props.user.company_id || null,
            custom_role_id: props.user.custom_role_id || null,
            is_active: props.user.is_active !== false,
            security_pin: props.user.security_pin || '',
            is_design_leader: props.user.is_design_leader || false,
            requires_design_approval: props.user.requires_design_approval || false,
            can_approve_design: props.user.can_approve_design || false,
        });
        editedUser.permissions = Array.isArray(props.user.permissions) ? [...props.user.permissions] : [];
        editedUser.read_only_permissions = Array.isArray(props.user.read_only_permissions) ? [...props.user.read_only_permissions] : [];
        editedUser.delete_permissions = Array.isArray(props.user.delete_permissions) ? [...props.user.delete_permissions] : [];
    }
});

const closeModal = () => {
    internalShow.value = false;
    emit('close');
};

const handleRoleTemplateSelection = (roleId: string | null) => {
    if (!roleId) return;
    const role = props.auxData.customRoles.find((r: any) => r.id === roleId);
    if (role) {
        editedUser.permissions = Array.isArray(role.permissions) ? [...role.permissions] : [];
        editedUser.read_only_permissions = Array.isArray(role.read_only_permissions) ? [...role.read_only_permissions] : [];
        editedUser.delete_permissions = Array.isArray(role.delete_permissions) ? [...role.delete_permissions] : [];
        appStore.showSnackbar(`As permissões do cargo '${role.name}' foram injetadas com sucesso!`, 'info');
    }
};

const togglePermission = (val: string) => {
    const idx = editedUser.permissions.indexOf(val);
    if (idx > -1) editedUser.permissions.splice(idx, 1);
    else editedUser.permissions.push(val);
};

const isReadOnlyActive = (permValue: string) => editedUser.read_only_permissions.includes(permValue);

const isDeleteActive = (permItem: any) => {
    if (!permItem.tables || permItem.tables.length === 0) return false;
    return permItem.tables.every((table: string) => editedUser.delete_permissions.includes(table));
};

const toggleReadOnly = (permValue: string) => {
    const list = editedUser.read_only_permissions;
    const index = list.indexOf(permValue);
    if (index > -1) list.splice(index, 1);
    else list.push(permValue);
};

const toggleDelete = (permItem: any) => {
    const list = editedUser.delete_permissions;
    if (!permItem.tables || permItem.tables.length === 0) {
        appStore.showSnackbar('Nenhuma tabela associada para exclusão neste módulo.', 'info');
        return;
    }
    const active = isDeleteActive(permItem);
    if (active) {
        permItem.tables.forEach((table: string) => {
            const idx = list.indexOf(table);
            if (idx > -1) list.splice(idx, 1);
        });
    } else {
        permItem.tables.forEach((table: string) => {
            if (!list.includes(table)) list.push(table);
        });
    }
};

const triggerAvatarUpload = () => avatarInput.value?.click();

const onAvatarChange = async (e: any) => {
    const file = e.target.files[0];
    if (!file) return;
    appStore.showSnackbar('Enviando foto, aguarde...', 'info');
    try {
        const fileExt = file.name.split('.').pop();
        const baseId = editedUser.id || 'novo_usuario';
        const fileName = `${baseId}-${Date.now()}.${fileExt}`;
        const { error: uploadError } = await supabase.storage.from('avatars').upload(fileName, file, { cacheControl: '3600', upsert: false });
        if (uploadError) throw new Error("Bloqueio de Segurança (RLS) ou erro de permissão.");
        const { data } = supabase.storage.from('avatars').getPublicUrl(fileName);
        editedUser.avatar_url = `${data.publicUrl}?t=${Date.now()}`;
        appStore.showSnackbar('Avatar carregado com sucesso!', 'success');
    } catch (err: any) {
        appStore.showSnackbar(`Erro: ${err.message}`, 'error');
    } finally {
        if (avatarInput.value) avatarInput.value.value = '';
    }
};

const saveUser = async () => {
  if (!userForm.value) return;

  const { valid } = await userForm.value.validate();
  if (!valid) { appStore.showSnackbar('Verifique os campos obrigatórios!', 'warning'); return; }

  isSaving.value = true;
  try {
    const profilePayload = {
        full_name: editedUser.full_name,
        email: editedUser.email,
        role: editedUser.role,
        gestao_click_id: editedUser.gestao_click_id || null,
        store_id: editedUser.store_id || null,
        employee_id: editedUser.employee_id || null,
        company_id: editedUser.company_id || null,
        custom_role_id: editedUser.custom_role_id || null,
        can_access_crm: editedUser.can_access_crm,
        can_move_cash: editedUser.can_move_cash,
        is_active: editedUser.is_active,
        security_pin: editedUser.security_pin || null,
        avatar_url: editedUser.avatar_url,
        commission_percentage: editedUser.commission_percentage,
        permissions: editedUser.permissions,
        read_only_permissions: editedUser.read_only_permissions,
        delete_permissions: editedUser.delete_permissions
    };

    let currentUserId = editedUser.id;

    if (isEdit.value) {
      const { error } = await supabase.from('profiles').update(profilePayload).eq('id', editedUser.id);
      if (error) throw error;

      if (editedUser.cajuia_role) {
          await supabase.from('cajuia_permissions').upsert({ user_id: editedUser.id, role: editedUser.cajuia_role }, { onConflict: 'user_id' });
      } else {
          await supabase.from('cajuia_permissions').delete().eq('user_id', editedUser.id);
      }
    } else {
      const { error } = await supabase.functions.invoke('create-user', { body: { ...profilePayload, email: editedUser.email, password: editedUser.password } });
      if (error) throw error;

      // BLINDAGEM DO ERRO 406
      let { data: newProf } = await supabase.from('profiles').select('id').eq('email', editedUser.email).maybeSingle();

      if (!newProf) {
          await new Promise(resolve => setTimeout(resolve, 1000));
          const { data: retryProf } = await supabase.from('profiles').select('id').eq('email', editedUser.email).maybeSingle();
          newProf = retryProf;
      }

      if (newProf) currentUserId = newProf.id;
    }

    if (currentUserId) {
        await supabase.from('design_user_permissions').upsert({
            user_id: currentUserId,
            is_leader: editedUser.is_design_leader,
            requires_leader_approval: editedUser.requires_design_approval,
            can_approve_for_leader: editedUser.can_approve_design
        }, { onConflict: 'user_id' });
    }

    appStore.showSnackbar('Configurações aplicadas com sucesso!', 'success');

    if (currentUserId === userStore.user?.id) {
        await userStore.fetchProfile();
    }

    emit('saved');
  } catch (err: any) {
    appStore.showSnackbar('Erro ao salvar: ' + err.message, 'error');
  } finally {
    isSaving.value = false;
  }
};
</script>

<style scoped lang="scss">
.fixed-dialog { overflow: hidden !important; }
.absolute-fill { position: absolute; top: 0; left: 0; width: 100%; height: 100%; }
.opacity-0 { opacity: 0; }
.opacity-100 { opacity: 1; }
.transition-all { transition: all 0.3s ease; }
.transition-colors { transition: background-color 0.2s ease, border-color 0.2s ease; }
.cursor-pointer { cursor: pointer; }

/* Themes & Borders */
.border-white-05 { border: 1px solid rgba(255,255,255,0.05) !important; }
.border-white-10 { border: 1px solid rgba(255,255,255,0.1) !important; }
.border-white-20 { border: 1px solid rgba(255,255,255,0.2) !important; }
.bg-black-50 { background: rgba(0,0,0,0.5); }
.hover-bg-grey:hover { background-color: rgba(128,128,128,0.08); }

/* Typography */
.tracking-tight { letter-spacing: -0.5px !important; }
.tracking-wider { letter-spacing: 0.1em !important; }
.line-height-1-2 { line-height: 1.2; }

/* Form Fields & Sections */
.input-label {
    font-size: 11px;
    font-weight: 900;
    text-transform: uppercase;
    color: #757575;
    display: block;
    margin-bottom: 6px;
    letter-spacing: 0.5px;
}
.v-theme--dark .input-label { color: #bdbdbd; }
.ui-field :deep(.v-field) { border-radius: 8px !important; }
.row-gap { row-gap: 16px; margin-top: 4px; }
.row-gap-sm { row-gap: 12px; margin-top: 4px; }

/* Section Cards (Clean SaaS look) */
.section-card {
    background: transparent;
    border: none;
}
.behavior-card {
    border: 1px solid rgba(128,128,128,0.2);
    border-radius: 8px;
    padding: 16px;
    height: 100%;
    transition: all 0.2s;
}
.behavior-card.active-amber { border-color: #FFA000; background: rgba(255, 160, 0, 0.05); }
.behavior-card.active-purple { border-color: #7B1FA2; background: rgba(123, 31, 162, 0.05); }
.behavior-card.active-red { border-color: #D32F2F; background: rgba(211, 47, 47, 0.05); }
.behavior-card.active-blue { border-color: #0288D1; background: rgba(2, 136, 209, 0.05); }

/* Switches & Buttons */
.modern-switch :deep(.v-switch__track) { background-color: rgba(128,128,128,0.2) !important; opacity: 1; }
.modern-switch :deep(.v-switch__thumb) { box-shadow: 0 2px 4px rgba(0,0,0,0.15); }
.modern-switch :deep(.v-label) { font-size: 13px !important; font-weight: 700; opacity: 0.9; }

.btn-group-strict {
    border: 1px solid rgba(128,128,128,0.3) !important;
}

.btn-3d {
    border-radius: 8px !important;
    box-shadow: 0 3px 5px rgba(0,0,0,0.1), inset 0 2px 0 rgba(255,255,255,0.15) !important;
    transition: transform 0.1s ease, box-shadow 0.1s ease;
}
.btn-3d:active { transform: translateY(2px); box-shadow: 0 1px 2px rgba(0,0,0,0.1), inset 0 1px 0 rgba(255,255,255,0.1) !important; }

/* Scrollbars */
.custom-scroll::-webkit-scrollbar { width: 6px; height: 6px; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.2); border-radius: 4px; }
.custom-scroll::-webkit-scrollbar-track { background: transparent; }

.bg-texture { background-image: radial-gradient(rgba(128,128,128,0.1) 1px, transparent 1px); background-size: 20px 20px; }
</style>
