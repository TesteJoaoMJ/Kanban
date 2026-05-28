<template>
  <div
    class="tasks-layout font-sans fill-height d-flex flex-column position-relative overflow-hidden"
    :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 text-grey-darken-4' : 'bg-glass-dark text-white'"
  >
    <div v-if="themeStore.currentMode !== 'light'" class="background-carousel-wrapper">
      <v-carousel cycle height="100%" hide-delimiters :show-arrows="false" interval="18000" class="fill-height">
        <v-carousel-item src="@/assets/1.jpg" cover></v-carousel-item>
        <v-carousel-item src="@/assets/2.jpg" cover></v-carousel-item>
        <v-carousel-item src="@/assets/3.jpg" cover></v-carousel-item>
      </v-carousel>
      <div class="background-overlay"></div>
    </div>

    <div class="content-wrapper d-flex flex-column fill-height z-10 position-relative">

      <div
          class="header-bar px-4 px-md-6 py-3 py-md-4 d-flex flex-column flex-md-row align-md-center justify-space-between flex-shrink-0"
          :class="themeStore.currentMode === 'light' ? 'bg-white border-b border-grey-lighten-2 shadow-sm' : 'bg-glass-header border-bottom-white-05'"
      >
          <div class="d-flex flex-column">
              <div class="breadcrumb text-caption d-none d-md-block">
                  <span class="opacity-70">Operacional</span>
                  <span class="mx-2 opacity-50">></span>
                  <span class="font-weight-bold">Gerenciador de Tarefas</span>
              </div>
              <div class="d-flex align-center mt-1" style="gap: 8px;">
                 <div class="text-h6 font-weight-black tracking-tight leading-none text-truncate" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">
                    Controle de Atividades
                 </div>
              </div>
          </div>

          <div class="d-flex align-center mt-3 mt-md-0" style="gap: 12px;">
              <v-btn
                  color="teal-darken-3"
                  variant="flat"
                  class="btn-3d px-4 font-weight-bold text-caption text-uppercase letter-spacing-1 flex-shrink-0 shadow-button"
                  prepend-icon="mdi-plus"
                  height="40"
                  @click="openDialog()"
              >
                  Nova Tarefa
              </v-btn>
          </div>
      </div>

      <div class="px-4 px-md-6 pt-4 pb-0 flex-shrink-0">
          <v-row dense>
              <v-col cols="12" sm="3">
                  <v-card class="kpi-card bg-gradient-info hover-elevate py-3 px-4" elevation="2">
                      <div class="kpi-bg-icon"><v-icon>mdi-format-list-checks</v-icon></div>
                      <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                          <div class="d-flex align-center gap-2">
                              <v-icon size="18" class="opacity-80">mdi-clipboard-text-outline</v-icon>
                              <span class="kpi-label">Total Ativas</span>
                          </div>
                          <div class="kpi-number-group my-1">
                              <span class="kpi-value text-h5 font-weight-black">{{ kpis.total }}</span>
                          </div>
                      </div>
                  </v-card>
              </v-col>

              <v-col cols="12" sm="3">
                  <v-card class="kpi-card bg-gradient-warning hover-elevate py-3 px-4" elevation="2">
                      <div class="kpi-bg-icon"><v-icon>mdi-progress-clock</v-icon></div>
                      <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                          <div class="d-flex align-center gap-2">
                              <v-icon size="18" class="opacity-80">mdi-clock-outline</v-icon>
                              <span class="kpi-label">Em Andamento</span>
                          </div>
                          <div class="kpi-number-group my-1">
                              <span class="kpi-value text-h5 font-weight-black">{{ kpis.inProgress }}</span>
                          </div>
                      </div>
                  </v-card>
              </v-col>

              <v-col cols="12" sm="3">
                  <v-card class="kpi-card bg-gradient-danger hover-elevate py-3 px-4" elevation="2">
                      <div class="kpi-bg-icon"><v-icon>mdi-alert-circle-outline</v-icon></div>
                      <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                          <div class="d-flex align-center gap-2">
                              <v-icon size="18" class="opacity-80">mdi-alarm</v-icon>
                              <span class="kpi-label">Atrasadas</span>
                          </div>
                          <div class="kpi-number-group my-1">
                              <span class="kpi-value text-h5 font-weight-black">{{ kpis.overdue }}</span>
                          </div>
                      </div>
                  </v-card>
              </v-col>

              <v-col cols="12" sm="3">
                  <v-card class="kpi-card bg-gradient-success hover-elevate py-3 px-4" elevation="2">
                      <div class="kpi-bg-icon"><v-icon>mdi-check-circle-outline</v-icon></div>
                      <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                          <div class="d-flex align-center justify-space-between">
                              <div class="d-flex align-center gap-2">
                                  <v-icon size="18" class="opacity-80">mdi-check-all</v-icon>
                                  <span class="kpi-label">Concluídas (Mês)</span>
                              </div>
                          </div>
                          <div class="kpi-number-group my-1 d-flex align-end gap-2">
                              <span class="kpi-value text-h5 font-weight-black">{{ kpis.completed }}</span>
                          </div>
                      </div>
                  </v-card>
              </v-col>
          </v-row>
      </div>

      <div class="px-4 px-md-6 pt-4 pb-2 flex-shrink-0">

        <div class="fichario-wrapper d-flex align-end gap-1 overflow-x-auto hide-scrollbar">
            <div
                class="fichario-tab d-flex align-center gap-2"
                :class="{ 'active': currentView === 'my_tasks', 'dark-mode': themeStore.currentMode !== 'light' }"
                @click="currentView = 'my_tasks'"
            >
                <v-icon size="16" class="tab-icon">mdi-clipboard-account-outline</v-icon>
                <span class="text-truncate font-weight-black text-caption text-uppercase tracking-wide">Minhas Tarefas</span>
            </div>
            <div
                v-if="canDelegate"
                class="fichario-tab d-flex align-center gap-2"
                :class="{ 'active': currentView === 'delegated', 'dark-mode': themeStore.currentMode !== 'light' }"
                @click="currentView = 'delegated'"
            >
                <v-icon size="16" class="tab-icon">mdi-account-arrow-right-outline</v-icon>
                <span class="text-truncate font-weight-black text-caption text-uppercase tracking-wide">Delegadas por Mim</span>
            </div>
        </div>

        <div class="controls-bar d-flex align-center justify-space-between flex-wrap shadow-sm rounded-b-lg border-x border-b px-4 py-3" :class="themeStore.currentMode === 'light' ? 'bg-white border-grey-lighten-2' : 'bg-glass-dark border-white-10'" style="gap: 10px;">
          <v-chip-group v-model="statusFilter" mandatory selected-class="bg-teal-darken-3 text-white">
            <v-chip value="all" size="small" variant="outlined" class="font-weight-bold chip-3d">TODAS</v-chip>
            <v-chip value="pendente" size="small" variant="outlined" class="font-weight-bold chip-3d">PENDENTES</v-chip>
            <v-chip value="em_andamento" size="small" variant="outlined" class="font-weight-bold chip-3d">EM ANDAMENTO</v-chip>
            <v-chip value="concluida" size="small" variant="outlined" class="font-weight-bold chip-3d">CONCLUÍDAS</v-chip>
          </v-chip-group>

          <div class="d-flex align-center flex-grow-1 justify-end" style="gap: 10px;">
            <div class="search-wrap d-flex align-center flex-grow-1" :class="themeStore.currentMode === 'light' ? 'search-light bg-grey-lighten-5 border-grey-lighten-2' : 'search-dark bg-black-20 border-white-10'" style="max-width: 350px; border-radius: 6px;">
              <v-icon :color="themeStore.currentMode === 'light' ? 'grey-darken-1' : 'white-70'" class="ml-2">mdi-magnify</v-icon>
              <input v-model="search" type="text" placeholder="Pesquisar tarefas..." class="clean-input flex-grow-1 font-weight-bold pa-2" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'" />
            </div>
            <v-btn variant="flat" class="btn-3d font-weight-bold" height="40" color="teal-darken-3" @click="fetchData" prepend-icon="mdi-refresh">
              Atualizar
            </v-btn>
          </div>
        </div>
      </div>

      <div class="flex-grow-1 px-4 px-md-6 pb-4 overflow-hidden d-flex flex-column mt-2">
          <v-card class="flex-grow-1 d-flex flex-column rounded-lg border-thin overflow-hidden" :class="themeStore.currentMode === 'light' ? 'bg-white shadow-sm' : 'glass-card border-white-05'" :elevation="0">
              <div class="grid-scroll flex-grow-1 overflow-y-auto custom-scroll">

                  <div class="grid-header sticky-head" :class="[themeStore.currentMode === 'light' ? 'grid-surface-light' : 'grid-surface-dark']" style="grid-template-columns: 60px minmax(250px, 2fr) 150px 120px 150px 140px 120px; min-width: 1000px;">
                      <div class="cell center header-text">#</div>
                      <div class="cell header-text pl-4">Tarefa / Descrição</div>
                      <div class="cell center header-text">Responsável</div>
                      <div class="cell center header-text">Prioridade</div>
                      <div class="cell center header-text">Prazo</div>
                      <div class="cell center header-text">Status</div>
                      <div class="cell center header-text">Ações</div>
                  </div>

                  <div v-if="loading" class="d-flex flex-column justify-center align-center h-100 py-10 w-100 min-w-full">
                      <v-progress-circular indeterminate color="teal-darken-3" size="32" width="3"></v-progress-circular>
                  </div>

                  <div v-else-if="filteredData.length === 0" class="d-flex flex-column justify-center align-center h-100 py-10 opacity-60 w-100 min-w-full">
                      <v-icon size="48" class="mb-2">mdi-checkbox-multiple-blank-outline</v-icon>
                      <span class="font-weight-medium">Nenhuma tarefa encontrada.</span>
                  </div>

                  <template v-else>
                      <div v-for="(item, index) in filteredData" :key="item.id"
                           class="grid-row transition-hover"
                           :class="[
                               zebraClass(index),
                               isOverdue(item) ? (themeStore.currentMode === 'light' ? 'bg-red-lighten-5' : 'bg-red-darken-4-alpha') : ''
                           ]"
                           style="grid-template-columns: 60px minmax(250px, 2fr) 150px 120px 150px 140px 120px; min-width: 1000px;"
                           @click="openDialog(item)">

                          <div class="cell center">
                              <v-icon v-if="item.is_immutable" size="16" color="warning" title="Tarefa Imutável (Definida pela Gestão)">mdi-lock</v-icon>
                              <v-icon v-else size="16" class="opacity-30">mdi-text-box-outline</v-icon>
                          </div>

                          <div class="cell pl-4 d-flex flex-column justify-center align-start overflow-hidden">
                              <div class="d-flex align-center gap-2 w-100">
                                  <span v-if="item.requires_alert" class="text-error"><v-icon size="14">mdi-bell-ring</v-icon></span>
                                  <span class="font-weight-bold text-subtitle-2 text-truncate w-100" :class="item.status === 'concluida' ? 'text-decoration-line-through opacity-60' : ''">{{ item.title }}</span>
                              </div>
                              <span class="text-[11px] opacity-70 text-truncate w-100 mt-1">{{ item.description || 'Sem descrição' }}</span>
                          </div>

                          <div class="cell center text-[11px] font-weight-bold text-truncate px-2">
                              {{ getUserName(item.assigned_to) }}
                          </div>

                          <div class="cell center">
                              <v-chip size="x-small" :color="getPriorityColor(item.priority)" class="font-weight-black text-uppercase solid-chip" variant="flat">
                                  {{ item.priority }}
                              </v-chip>
                          </div>

                          <div class="cell center font-mono text-[11px] d-flex flex-column">
                              <span class="font-weight-bold" :class="isOverdue(item) ? 'text-error' : ''">{{ formatDateTime(item.due_date) }}</span>
                              <span v-if="isOverdue(item)" class="text-[9px] text-error font-weight-black text-uppercase mt-1">Atrasada</span>
                          </div>

                          <div class="cell center">
                              <v-chip size="small" :color="getStatusColor(item.status)" variant="tonal" class="font-weight-bold text-uppercase px-3 chip-3d" style="font-size: 10px;">
                                  {{ getStatusLabel(item.status) }}
                              </v-chip>
                          </div>

                          <div class="cell center" @click.stop>
                              <div class="actions-inline d-flex flex-nowrap gap-2">
                                  <v-tooltip v-if="item.status !== 'concluida'" text="Concluir" location="top">
                                      <template v-slot:activator="{ props }">
                                          <v-btn v-bind="props" icon size="small" class="action-btn btn-3d bg-success text-white" @click.stop="quickComplete(item)" variant="flat"><v-icon size="16">mdi-check-bold</v-icon></v-btn>
                                      </template>
                                  </v-tooltip>
                                  <v-tooltip text="Editar / Visualizar" location="top">
                                      <template v-slot:activator="{ props }">
                                          <v-btn v-bind="props" icon size="small" class="action-btn btn-3d action-edit" @click.stop="openDialog(item)" variant="flat"><v-icon size="16">{{ canEditFull(item) ? 'mdi-pencil' : 'mdi-eye' }}</v-icon></v-btn>
                                      </template>
                                  </v-tooltip>
                                  <v-tooltip v-if="canEditFull(item)" text="Excluir Tarefa" location="top">
                                      <template v-slot:activator="{ props }">
                                          <v-btn v-bind="props" icon size="small" class="action-btn btn-3d bg-error text-white" @click.stop="deleteTask(item.id)" variant="flat"><v-icon size="16">mdi-trash-can-outline</v-icon></v-btn>
                                      </template>
                                  </v-tooltip>
                              </div>
                          </div>

                      </div>
                  </template>
              </div>
          </v-card>
      </div>

    </div>

    <v-dialog v-model="dialog" max-width="700" persistent scrollable transition="dialog-bottom-transition">
        <v-card class="rounded-xl shadow-2xl border-thin d-flex flex-column" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-grey-darken-4 text-white'" max-height="90vh">

            <div class="px-5 py-4 border-b d-flex justify-space-between align-center flex-shrink-0" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5' : 'bg-grey-darken-3'">
                <div class="d-flex align-center gap-3">
                    <v-avatar :color="isEditing ? 'blue-lighten-5' : 'teal-lighten-5'" size="40" class="rounded-lg">
                        <v-icon :color="isEditing ? 'blue-darken-3' : 'teal-darken-3'">{{ isEditing ? 'mdi-pencil' : 'mdi-plus' }}</v-icon>
                    </v-avatar>
                    <div>
                        <h3 class="text-subtitle-1 font-weight-black leading-none mb-1 text-uppercase tracking-widest">{{ isEditing ? 'Ficha da Tarefa' : 'Nova Tarefa' }}</h3>
                        <div class="text-caption opacity-70">Detalhes e Execução</div>
                    </div>
                </div>
                <v-btn icon="mdi-close" variant="text" size="small" @click="closeDialog"></v-btn>
            </div>

            <v-card-text class="pa-6 custom-scroll flex-grow-1">
                <v-form ref="formRef" @submit.prevent="saveTask">

                    <div v-if="isEditing && editedItem.is_immutable && !canEditFull(editedItem)" class="pa-3 mb-4 rounded-lg bg-warning-lighten-5 border border-warning text-warning-darken-4 d-flex align-center gap-2">
                        <v-icon size="20">mdi-lock</v-icon>
                        <span class="text-caption font-weight-bold">Esta tarefa foi bloqueada pela gestão. Você só pode alterar o Status.</span>
                    </div>

                    <v-row class="row-gap">
                        <v-col cols="12">
                            <v-text-field
                                v-model="editedItem.title"
                                label="Título da Tarefa*"
                                variant="outlined"
                                density="comfortable"
                                color="teal-darken-3"
                                class="ui-field font-weight-bold"
                                :readonly="!canEditFull(editedItem)"
                                :rules="[v => !!v || 'O título é obrigatório']"
                            ></v-text-field>
                        </v-col>
                        <v-col cols="12">
                            <v-textarea
                                v-model="editedItem.description"
                                label="Descrição / Detalhes"
                                variant="outlined"
                                density="comfortable"
                                color="teal-darken-3"
                                class="ui-field"
                                rows="3"
                                :readonly="!canEditFull(editedItem)"
                            ></v-textarea>
                        </v-col>

                        <v-col cols="12" md="6">
                            <v-select
                                v-model="editedItem.status"
                                :items="statusOptions"
                                item-title="label"
                                item-value="value"
                                label="Status*"
                                variant="outlined"
                                density="comfortable"
                                color="teal-darken-3"
                                class="ui-field font-weight-bold"
                            >
                                <template v-slot:selection="{ item }">
                                    <v-chip size="small" :color="getStatusColor(item.value)" class="font-weight-bold text-uppercase">{{ item.title }}</v-chip>
                                </template>
                            </v-select>
                        </v-col>

                        <v-col cols="12" md="6">
                            <v-select
                                v-model="editedItem.priority"
                                :items="priorityOptions"
                                item-title="label"
                                item-value="value"
                                label="Prioridade*"
                                variant="outlined"
                                density="comfortable"
                                color="teal-darken-3"
                                class="ui-field font-weight-bold"
                                :readonly="!canEditFull(editedItem)"
                            >
                                <template v-slot:selection="{ item }">
                                    <v-chip size="small" :color="getPriorityColor(item.value)" class="font-weight-bold text-uppercase text-white">{{ item.title }}</v-chip>
                                </template>
                            </v-select>
                        </v-col>

                        <v-col cols="12" md="6">
                            <v-text-field
                                v-model="editedItem.due_date"
                                label="Prazo Final (Data e Hora)"
                                type="datetime-local"
                                variant="outlined"
                                density="comfortable"
                                color="teal-darken-3"
                                class="ui-field font-weight-bold"
                                :readonly="!canEditFull(editedItem)"
                            ></v-text-field>
                        </v-col>

                        <v-col cols="12" md="6" v-if="canDelegate">
                            <v-autocomplete
                                v-model="editedItem.assigned_to"
                                :items="userList"
                                item-title="full_name"
                                item-value="id"
                                label="Atribuir para (Responsável)"
                                variant="outlined"
                                density="comfortable"
                                color="teal-darken-3"
                                class="ui-field"
                                :readonly="!canEditFull(editedItem)"
                            ></v-autocomplete>
                        </v-col>

                        <v-col cols="12" v-if="canDelegate && canEditFull(editedItem)">
                            <div class="pa-4 rounded-lg border-thin mt-2" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5' : 'bg-black-20 border-white-10'">
                                <div class="text-subtitle-2 font-weight-black text-uppercase mb-3 opacity-70">Regras de Negócio e Alertas</div>

                                <v-switch
                                    v-model="editedItem.is_immutable"
                                    color="warning"
                                    label="Tarefa Imutável (Somente Leitura)"
                                    hide-details
                                    density="compact"
                                    class="mb-2 font-weight-bold"
                                ></v-switch>
                                <p class="text-[10px] opacity-60 ml-10 mb-4 lh-1">O responsável não poderá alterar título, descrição ou prazo. Apenas o status.</p>

                                <v-switch
                                    v-model="editedItem.requires_alert"
                                    color="error"
                                    label="Ativar Alerta Pop-up em Tela"
                                    hide-details
                                    density="compact"
                                    class="font-weight-bold"
                                ></v-switch>

                                <div v-if="editedItem.requires_alert" class="mt-4 ml-10">
                                    <v-select
                                        v-model="editedItem.alert_interval"
                                        :items="alertIntervalOptions"
                                        item-title="label"
                                        item-value="value"
                                        label="Repetição do Lembrete"
                                        variant="outlined"
                                        density="compact"
                                        color="error"
                                        hide-details
                                        class="ui-field"
                                    ></v-select>
                                    <p class="text-[10px] opacity-60 mt-1 lh-1">O sistema forçará um Pop-up gigante no meio da tela do responsável na frequência selecionada até ele concluir a tarefa.</p>
                                </div>
                            </div>
                        </v-col>

                    </v-row>
                </v-form>
            </v-card-text>

            <div class="pa-4 border-t d-flex justify-space-between align-center flex-shrink-0" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5' : 'bg-grey-darken-3'">
                <v-btn v-if="isEditing && canEditFull(editedItem)" color="error" variant="text" class="font-weight-bold" prepend-icon="mdi-trash-can" @click="deleteTask(editedItem.id)">Excluir</v-btn>
                <div v-else></div>

                <div class="d-flex gap-3">
                    <v-btn variant="outlined" class="btn-3d font-weight-bold" @click="closeDialog" :disabled="isSaving">Cancelar</v-btn>
                    <v-btn color="teal-darken-3" variant="flat" class="btn-3d font-weight-black px-6" @click="saveTask" :loading="isSaving">
                        <v-icon start>mdi-check</v-icon> Salvar Tarefa
                    </v-btn>
                </div>
            </div>
        </v-card>
    </v-dialog>

  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted } from 'vue';
import { supabase } from '@/api/supabase';
import { useAppStore } from '@/stores/app';
import { useThemeStore } from '@/stores/theme';
import { useUserStore } from '@/stores/user';
import { format, parseISO, isPast } from 'date-fns';

const appStore = useAppStore();
const themeStore = useThemeStore();
const userStore = useUserStore();

// Estado
const loading = ref(false);
const isSaving = ref(false);
const dialog = ref(false);
const isEditing = ref(false);
const formRef = ref<any>(null);

const currentView = ref('my_tasks'); // 'my_tasks' | 'delegated'
const statusFilter = ref('all');
const search = ref('');

const allTasks = ref<any[]>([]);
const userList = ref<any[]>([]);
const userMap = ref<Record<string, string>>({}); // id -> name

const alertIntervalOptions = [
    { label: 'Avisar apenas uma vez', value: 0 },
    { label: 'A cada 15 minutos', value: 15 },
    { label: 'A cada 30 minutos', value: 30 },
    { label: 'A cada 1 hora', value: 60 },
    { label: 'A cada 3 horas', value: 180 },
];

// Formulário
const editedItem = ref<any>({
    id: null,
    title: '',
    description: '',
    status: 'pendente',
    priority: 'media',
    due_date: '',
    assigned_to: null,
    is_immutable: false,
    requires_alert: false,
    alert_interval: 0
});

// Opções
const statusOptions = [
    { label: 'Pendente', value: 'pendente' },
    { label: 'Em Andamento', value: 'em_andamento' },
    { label: 'Concluída', value: 'concluida' },
    { label: 'Cancelada', value: 'cancelada' }
];

const priorityOptions = [
    { label: 'Baixa', value: 'baixa' },
    { label: 'Média', value: 'media' },
    { label: 'Alta', value: 'alta' },
    { label: 'Urgente', value: 'urgente' }
];

// Computed & Permissões
const canDelegate = computed(() => {
    const role = userStore.profile?.role;
    return role === 'super_admin' || role === 'admin' || role === 'leader';
});

const canEditFull = (task: any) => {
    if (!task.id) return true; // Nova tarefa
    if (userStore.profile?.id === task.created_by) return true; // Criador pode tudo
    if (userStore.profile?.role === 'super_admin' || userStore.profile?.role === 'admin') return true; // Admin pode tudo
    if (!task.is_immutable) return true; // Se não for imutável, responsável pode editar
    return false; // Se for imutável e ele não é o dono/admin, bloqueia
};

const isOverdue = (task: any) => {
    if (task.status === 'concluida' || task.status === 'cancelada') return false;
    if (!task.due_date) return false;
    return isPast(new Date(task.due_date));
};

const getStatusColor = (status: string) => {
    const map: any = { 'pendente': 'grey-darken-1', 'em_andamento': 'warning', 'concluida': 'success', 'cancelada': 'error' };
    return map[status] || 'grey';
};

const getStatusLabel = (status: string) => {
    const map: any = { 'pendente': 'Pendente', 'em_andamento': 'Andamento', 'concluida': 'Concluída', 'cancelada': 'Cancelada' };
    return map[status] || status;
};

const getPriorityColor = (priority: string) => {
    const map: any = { 'baixa': 'blue-grey', 'media': 'info', 'alta': 'orange-darken-3', 'urgente': 'red-darken-3' };
    return map[priority] || 'grey';
};

const getUserName = (id: string) => userMap.value[id] || 'Não atribuído';

const formatDateTime = (isoString: string) => {
    if (!isoString) return 'Sem Prazo';
    try { return format(parseISO(isoString), 'dd/MM/yyyy HH:mm'); }
    catch { return isoString; }
};

const formatForInput = (isoString: string) => {
    if (!isoString) return '';
    const date = new Date(isoString);
    date.setMinutes(date.getMinutes() - date.getTimezoneOffset());
    return date.toISOString().slice(0, 16);
};

const zebraClass = (i: number) => themeStore.currentMode === 'light' ? (i % 2 === 0 ? 'zebra-light-a' : 'zebra-light-b') : (i % 2 === 0 ? 'zebra-dark-a' : 'zebra-dark-b');

// Processamento de Dados
const filteredData = computed(() => {
    let list = allTasks.value;
    const myId = userStore.profile?.id;

    // Filtro de Fichário
    if (currentView.value === 'my_tasks') {
        list = list.filter(t => t.assigned_to === myId || (t.created_by === myId && !t.assigned_to));
    } else if (currentView.value === 'delegated') {
        list = list.filter(t => t.created_by === myId && t.assigned_to !== myId);
    }

    // Filtro de Status
    if (statusFilter.value !== 'all') {
        list = list.filter(t => t.status === statusFilter.value);
    }

    // Busca
    if (search.value) {
        const s = search.value.toLowerCase();
        list = list.filter(t =>
            t.title.toLowerCase().includes(s) ||
            (t.description && t.description.toLowerCase().includes(s)) ||
            getUserName(t.assigned_to).toLowerCase().includes(s)
        );
    }

    // Ordenação: Atrasados primeiro, depois por prioridade, depois data.
    return list.sort((a, b) => {
        const aOver = isOverdue(a) ? 1 : 0;
        const bOver = isOverdue(b) ? 1 : 0;
        if (aOver !== bOver) return bOver - aOver;

        const prioMap: any = { 'urgente': 4, 'alta': 3, 'media': 2, 'baixa': 1 };
        const pA = prioMap[a.priority] || 0;
        const pB = prioMap[b.priority] || 0;
        if (pA !== pB) return pB - pA;

        return new Date(a.due_date || '2099-01-01').getTime() - new Date(b.due_date || '2099-01-01').getTime();
    });
});

const kpis = computed(() => {
    const list = currentView.value === 'my_tasks'
        ? allTasks.value.filter(t => t.assigned_to === userStore.profile?.id)
        : allTasks.value.filter(t => t.created_by === userStore.profile?.id && t.assigned_to !== userStore.profile?.id);

    return {
        total: list.filter(t => t.status !== 'cancelada').length,
        inProgress: list.filter(t => t.status === 'em_andamento').length,
        completed: list.filter(t => t.status === 'concluida').length,
        overdue: list.filter(t => isOverdue(t)).length
    };
});

// Ações
const fetchUsers = async () => {
    const { data } = await supabase.from('profiles').select('id, full_name').order('full_name');
    if (data) {
        userList.value = data;
        const map: Record<string, string> = {};
        data.forEach(u => map[u.id] = u.full_name);
        userMap.value = map;
    }
};

const fetchData = async () => {
    loading.value = true;
    try {
        const { data, error } = await supabase.from('app_tasks').select('*').order('created_at', { ascending: false });
        if (error) throw error;
        allTasks.value = data || [];
    } catch (e: any) {
        appStore.showSnackbar('Erro ao buscar tarefas: ' + e.message, 'error');
    } finally {
        loading.value = false;
    }
};

const openDialog = (item?: any) => {
    if (item) {
        isEditing.value = true;
        editedItem.value = { ...item, due_date: formatForInput(item.due_date) };
        if(editedItem.value.alert_interval === undefined) editedItem.value.alert_interval = 0;
    } else {
        isEditing.value = false;
        editedItem.value = {
            id: null, title: '', description: '', status: 'pendente', priority: 'media',
            due_date: '', assigned_to: userStore.profile?.id, is_immutable: false, requires_alert: false, alert_interval: 0
        };
    }
    dialog.value = true;
};

const closeDialog = () => { dialog.value = false; };

const saveTask = async () => {
    const { valid } = await formRef.value.validate();
    if (!valid) return;

    isSaving.value = true;
    try {
        const payload = { ...editedItem.value };

        if (!payload.due_date) payload.due_date = null;
        else payload.due_date = new Date(payload.due_date).toISOString();

        if (!payload.requires_alert) payload.alert_interval = 0;

        const isNewlyCompleted = payload.status === 'concluida' && (!isEditing.value || allTasks.value.find(t=>t.id===payload.id)?.status !== 'concluida');

        if (isNewlyCompleted) {
            payload.completed_at = new Date().toISOString();
        }

        if (isEditing.value) {
            const { error } = await supabase.from('app_tasks').update(payload).eq('id', payload.id);
            if (error) throw error;
        } else {
            delete payload.id;
            payload.created_by = userStore.profile?.id;

            const { error } = await supabase.from('app_tasks').insert([payload]);
            if (error) throw error;

            // DISPARO DE NOVA TAREFA
            if (payload.assigned_to && payload.assigned_to !== userStore.profile?.id) {
                await supabase.from('notifications').insert({
                    recipient_id: payload.assigned_to,
                    sender_id: userStore.profile?.id,
                    type: 'task',
                    content: `[TASK_DELEGATED]::Nova tarefa atribuída a você: "${payload.title}"`,
                    redirect_url: '/tasks',
                });
            }
        }

        // DISPARO DE TAREFA CONCLUÍDA
        if (isNewlyCompleted && payload.created_by && payload.created_by !== userStore.profile?.id) {
            await supabase.from('notifications').insert({
                recipient_id: payload.created_by,
                sender_id: userStore.profile?.id,
                type: 'task_completed',
                content: `[TASK_COMPLETED]::A tarefa "${payload.title}" foi concluída por ${userStore.profile?.full_name || 'um usuário'}!`,
                redirect_url: '/tasks'
            });
        }

        appStore.showSnackbar('Tarefa salva com sucesso!', 'success');
        closeDialog();
        fetchData();
    } catch (e: any) {
        appStore.showSnackbar('Erro ao salvar: ' + e.message, 'error');
    } finally {
        isSaving.value = false;
    }
};

const quickComplete = async (item: any) => {
    try {
        const { error } = await supabase.from('app_tasks').update({ status: 'concluida', completed_at: new Date().toISOString() }).eq('id', item.id);
        if (error) throw error;

        if (item.created_by && item.created_by !== userStore.profile?.id) {
            await supabase.from('notifications').insert({
                recipient_id: item.created_by,
                sender_id: userStore.profile?.id,
                type: 'task_completed',
                content: `[TASK_COMPLETED]::A tarefa "${item.title}" foi concluída por ${userStore.profile?.full_name || 'um usuário'}!`,
                redirect_url: '/tasks'
            });
        }

        appStore.showSnackbar('Tarefa concluída! Ótimo trabalho.', 'success');
        fetchData();
    } catch (e: any) {
        appStore.showSnackbar('Erro: ' + e.message, 'error');
    }
};

const deleteTask = async (id: string) => {
    if (!confirm('Deseja realmente excluir esta tarefa permanentemente?')) return;
    try {
        const { error } = await supabase.from('app_tasks').delete().eq('id', id);
        if (error) throw error;
        appStore.showSnackbar('Tarefa excluída.', 'success');
        closeDialog();
        fetchData();
    } catch (e: any) {
        appStore.showSnackbar('Erro ao excluir: ' + e.message, 'error');
    }
};

onMounted(async () => {
    await fetchUsers();
    await fetchData();
});
</script>

<style scoped lang="scss">
@import "@/styles/settings.scss";

/* Layout Base */
.tasks-layout { position: relative; }
.bg-glass-dark { background: rgba(10,10,12,0.85); }
.bg-surface-dark { background-color: #1a1a20; }
.bg-glass-header { background: rgba(20,20,24,0.55); backdrop-filter: blur(14px); }
.border-bottom-white-05 { border-bottom: 1px solid rgba(255,255,255,0.08); }
.border-white-10 { border: 1px solid rgba(255,255,255,0.1) !important; }
.bg-black-20 { background: rgba(0,0,0,0.2) !important; }

/* Backgrounds (Dark Mode) */
.background-carousel-wrapper { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 0; opacity: 0.6; pointer-events: none; }
.background-overlay { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 1; background: radial-gradient(circle at center, rgba(15, 15, 19, 0.4), rgba(15, 15, 19, 0.98)); backdrop-filter: blur(8px); }
.z-10 { position: relative; z-index: 10; }

/* Botões */
.btn-3d { border-radius: 6px !important; box-shadow: 0 3px 5px rgba(0,0,0,0.15), inset 0 2px 0 rgba(255,255,255,0.25) !important; transition: transform 0.1s ease, box-shadow 0.1s ease; text-transform: none !important; }
.btn-3d:active { transform: translateY(2px); box-shadow: 0 1px 2px rgba(0,0,0,0.15), inset 0 1px 0 rgba(255,255,255,0.2) !important; }
.chip-3d { border-radius: 6px !important; box-shadow: 0 3px 5px rgba(0,0,0,0.12), inset 0 1px 0 rgba(255,255,255,0.25) !important; text-shadow: 0 1px 2px rgba(0,0,0,0.25); }
.shadow-button { box-shadow: 0 4px 15px rgba(0, 105, 92, 0.3); }

/* FICHÁRIO TABS ESTILO PASTAS */
.fichario-wrapper { border-bottom: 2px solid #00695C; padding-bottom: 0; }
.fichario-tab { padding: 10px 18px; background: #e0e0e0; color: #616161; border-radius: 8px 8px 0 0; cursor: pointer; transition: all 0.2s ease; border: 1px solid #bdbdbd; border-bottom: none; position: relative; max-width: 220px; }
.fichario-tab:hover { background: #eeeeee; }
.fichario-tab.active { background: #00695C; color: #ffffff; border-color: #00695C; padding-bottom: 12px; margin-bottom: -2px; z-index: 2; box-shadow: 0 -3px 8px rgba(0,0,0,0.1); }
.fichario-tab.dark-mode { background: rgba(255,255,255,0.05); color: #9e9e9e; border-color: rgba(255,255,255,0.1); }
.fichario-tab.dark-mode:hover { background: rgba(255,255,255,0.1); }
.fichario-tab.dark-mode.active { background: #00695C; color: #ffffff; border-color: #00695C; }
.hide-scrollbar::-webkit-scrollbar { height: 0px; display: none; }

/* Controles */
.controls-bar { border: 1px solid rgba(0,0,0,0.08); border-radius: 0; padding: 10px; }
.search-wrap { height: 40px; border-radius: 6px; padding: 0 12px; }
.search-light { background: #f4f6f8; border: 1px solid rgba(0,0,0,0.08); }
.search-dark { background: rgba(255,255,255,0.08); border: 1px solid rgba(255,255,255,0.10); }
.clean-input { border: none; outline: none; background: transparent; font-size: 13px; color: inherit; width: 100%; }

/* Grid */
.grid-scroll { scrollbar-gutter: stable; -webkit-overflow-scrolling: touch; }
.custom-scroll::-webkit-scrollbar { width: 6px; height: 6px; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.3); border-radius: 4px; }
.grid-header { display: grid; align-items: stretch; width: 100%; border-bottom: 1px solid rgba(0,0,0,0.08); position: sticky; top: 0; z-index: 10; }
.grid-row { display: grid; align-items: stretch; width: 100%; }
.cell { padding: 8px 10px; display: flex; align-items: center; border-right: 1px solid rgba(0,0,0,0.08); border-bottom: 1px solid rgba(0,0,0,0.08); min-height: 52px; overflow: hidden; }
.center { justify-content: center; text-align: center; }
.header-text { font-size: 11px; font-weight: 900; text-transform: uppercase; letter-spacing: 0.5px; opacity: 0.8; padding: 12px 8px; }

.grid-surface-light .cell { background: #f5f7fa; color: rgba(0,0,0,0.7); border-color: rgba(0,0,0,0.12) !important; }
.grid-surface-dark .cell { background: rgba(255,255,255,0.08) !important; color: rgba(255,255,255,0.80) !important; border-color: rgba(255,255,255,0.10) !important; }

.zebra-light-a .cell { background: #fff; }
.zebra-light-b .cell { background: #f8fafc; }
.zebra-dark-a .cell { background: rgba(255,255,255,0.02); border-color: rgba(255,255,255,0.08) !important; }
.zebra-dark-b .cell { background: transparent; border-color: rgba(255,255,255,0.08) !important; }

.transition-hover:hover .cell { filter: brightness(0.95); cursor: pointer; }
.bg-glass-dark .transition-hover:hover .cell { filter: brightness(1.2); }

/* Cores e Helpers */
.solid-chip { display: inline-flex; align-items: center; justify-content: center; height: 22px; padding: 0 10px; border-radius: 6px; font-size: 10px; font-weight: 900; color: #fff; white-space: nowrap; }
.bg-red-lighten-5 { background-color: #fef2f2 !important; }
.bg-red-darken-4-alpha { background-color: rgba(183, 28, 28, 0.15) !important; }
.glass-card { background: rgba(30, 30, 35, 0.45); backdrop-filter: blur(25px); border: 1px solid rgba(255,255,255,0.08); }
.lh-1 { line-height: 1.1; }
.ui-field :deep(.v-field) { border-radius: 6px !important; }
.row-gap { row-gap: 12px; margin-top: 4px; }
.actions-inline { display: flex; gap: 6px; justify-content: center; }
.action-btn { width: 30px !important; height: 30px !important; }
.action-edit { background: #1976d2 !important; color: white !important;}

/* KPI Cards */
.kpi-card { border: 1px solid rgba(255,255,255,0.15); color: white; min-height: 100px; position: relative; overflow: hidden; border-radius: 8px !important; transition: all 0.2s ease; }
.kpi-bg-icon { position: absolute; right: -15px; bottom: -15px; opacity: 0.15; transform: rotate(-15deg); pointer-events: none; }
.kpi-bg-icon .v-icon { font-size: 80px; color: white; }
.bg-gradient-success { background: linear-gradient(135deg, #2e7d32, #1b5e20); }
.bg-gradient-danger { background: linear-gradient(135deg, #c62828, #8e0000); }
.bg-gradient-warning { background: linear-gradient(135deg, #f57c00, #e65100); }
.bg-gradient-info { background: linear-gradient(135deg, #0288d1, #005b9f); }
.kpi-label { font-size: 11px; font-weight: 900; text-transform: uppercase; letter-spacing: 0.5px; }
</style>
