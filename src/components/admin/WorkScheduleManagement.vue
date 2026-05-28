<template>
  <v-container fluid>
    <v-row>
      <v-col cols="12">
        <v-card>
          <v-card-title class="d-flex align-center">
            Gerenciamento de Horários de Trabalho
            <v-spacer></v-spacer>
            <v-btn color="primary" @click="openScheduleDialog(null)">
              <v-icon start>mdi-plus</v-icon> Adicionar Horário
            </v-btn>
          </v-card-title>
          <v-card-text>
            <v-select
              v-model="selectedUserFilter"
              :items="userListForFilter"
              label="Filtrar por Usuário (ou Geral)"
              clearable
              item-title="full_name"
              item-value="id"
              density="compact"
              class="mb-4"
              @update:modelValue="fetchSchedules"
            ></v-select>

            <v-data-table
              :headers="headers"
              :items="schedules"
              :loading="loadingSchedules"
              items-per-page="10"
              hover
            >
              <template v-slot:item.user_id="{ item }">
                {{ getUserName(item.user_id) || 'Geral (Todos)' }}
              </template>
              <template v-slot:item.day_of_week="{ item }">
                {{ formatDayOfWeek(item.day_of_week) }}
              </template>
               <template v-slot:item.start_time="{ item }">
                {{ formatTime(item.start_time) }}
              </template>
              <template v-slot:item.end_time="{ item }">
                {{ formatTime(item.end_time) }}
              </template>
              <template v-slot:item.actions="{ item }">
                <v-icon small class="me-2" @click="openScheduleDialog(item)">mdi-pencil</v-icon>
                <v-icon small color="error" @click="confirmDelete(item)">mdi-delete</v-icon>
              </template>
               <template v-slot:loading>
                <v-skeleton-loader type="table-row@5"></v-skeleton-loader>
              </template>
              <template v-slot:no-data>
                <v-alert type="info" class="mt-4">Nenhum horário encontrado.</v-alert>
              </template>
            </v-data-table>
          </v-card-text>
        </v-card>
      </v-col>
    </v-row>

    <v-dialog v-model="scheduleDialog" persistent max-width="600px">
      <v-card>
        <v-card-title>
          <span class="headline">{{ editingSchedule?.id ? 'Editar Horário' : 'Novo Horário' }}</span>
        </v-card-title>
        <v-card-text>
          <v-form ref="scheduleFormRef">
            <v-checkbox
              v-model="isGeneralSchedule"
              label="Aplicar a todos os usuários (Horário Geral)"
              :disabled="!!editingSchedule?.id && !editingSchedule?.is_general"
               @change="currentSchedule.user_id = null"
            ></v-checkbox>

            <v-select
              v-model="currentSchedule.user_id"
              :items="userList"
              label="Usuário Específico"
              item-title="full_name"
              item-value="id"
              :disabled="isGeneralSchedule || (!!editingSchedule?.id && editingSchedule?.is_general)"
              :rules="isGeneralSchedule ? [] : [v => !!v || 'Usuário é obrigatório']"
              clearable
              class="mb-3"
            ></v-select>

            <v-select
              v-model="currentSchedule.day_of_week"
              :items="daysOfWeek"
              label="Dia da Semana"
              item-title="text"
              item-value="value"
              :rules="[v => v !== null && v !== undefined || 'Dia da semana é obrigatório']"
              class="mb-3"
            ></v-select>

            <v-row>
              <v-col cols="12" sm="6">
                 <v-text-field
                    v-model="currentSchedule.start_time"
                    label="Horário de Início"
                    type="time"
                    :rules="[v => !!v || 'Horário de início é obrigatório']"
                    required
                  ></v-text-field>
              </v-col>
              <v-col cols="12" sm="6">
                 <v-text-field
                    v-model="currentSchedule.end_time"
                    label="Horário de Fim"
                    type="time"
                    :rules="[v => !!v || 'Horário de fim é obrigatório', v => v > currentSchedule.start_time || 'Deve ser após o início']"
                    required
                  ></v-text-field>
              </v-col>
            </v-row>
             <v-alert v-if="saveError" type="error" density="compact" class="mt-4">{{ saveError }}</v-alert>
          </v-form>
        </v-card-text>
        <v-card-actions>
          <v-spacer></v-spacer>
          <v-btn color="blue darken-1" text @click="closeScheduleDialog">Cancelar</v-btn>
          <v-btn color="blue darken-1" :loading="savingSchedule" @click="saveSchedule">Salvar</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

     <v-dialog v-model="deleteDialog" persistent max-width="400px">
      <v-card>
        <v-card-title class="headline">Confirmar Exclusão</v-card-title>
        <v-card-text>
          Tem certeza que deseja excluir este horário para
          <strong>{{ getUserName(scheduleToDelete?.user_id) || 'Geral' }}</strong>
          no dia <strong>{{ formatDayOfWeek(scheduleToDelete?.day_of_week) }}</strong>?
        </v-card-text>
        <v-card-actions>
          <v-spacer></v-spacer>
          <v-btn color="grey darken-1" text @click="deleteDialog = false">Cancelar</v-btn>
          <v-btn color="red darken-1" :loading="deletingSchedule" @click="deleteScheduleConfirm">Excluir</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

  </v-container>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from 'vue';
import { supabase } from '@/api/supabase'; // Ajuste o caminho se necessário
import { useUserStore } from '@/stores/user'; // Ajuste o caminho se necessário
import { VForm } from 'vuetify/components'; // Importa VForm para tipagem

interface Schedule {
  id?: number;
  user_id: string | null;
  day_of_week: number;
  start_time: string; // Formato HH:MM ou HH:MM:SS
  end_time: string; // Formato HH:MM ou HH:MM:SS
  is_general: boolean;
  created_at?: string;
}

interface UserProfile {
  id: string;
  full_name: string;
  // Outros campos do perfil, se necessário
}

const userStore = useUserStore();
const schedules = ref<Schedule[]>([]);
const userList = ref<UserProfile[]>([]);
const loadingSchedules = ref(false);
const scheduleDialog = ref(false);
const deleteDialog = ref(false);
const savingSchedule = ref(false);
const deletingSchedule = ref(false);
const saveError = ref<string | null>(null);
const selectedUserFilter = ref<string | null>(null);

const editingSchedule = ref<Schedule | null>(null);
const scheduleToDelete = ref<Schedule | null>(null);
const currentSchedule = ref<Schedule>({
  user_id: null,
  day_of_week: 1, // Default para Segunda
  start_time: '07:00',
  end_time: '17:30',
  is_general: false,
});
const isGeneralSchedule = ref(false); // Controla o checkbox
const scheduleFormRef = ref<InstanceType<typeof VForm> | null>(null); // Referência para o formulário

const headers = [
  { title: 'Usuário', key: 'user_id', sortable: true },
  { title: 'Dia da Semana', key: 'day_of_week', sortable: true },
  { title: 'Início', key: 'start_time', sortable: false },
  { title: 'Fim', key: 'end_time', sortable: false },
  { title: 'Ações', key: 'actions', sortable: false, align: 'end' },
] as const; // Define headers como 'readonly' para VDataTable

const daysOfWeek = [
  { text: 'Domingo', value: 0 },
  { text: 'Segunda-feira', value: 1 },
  { text: 'Terça-feira', value: 2 },
  { text: 'Quarta-feira', value: 3 },
  { text: 'Quinta-feira', value: 4 },
  { text: 'Sexta-feira', value: 5 },
  { text: 'Sábado', value: 6 },
];

// Computed property para incluir a opção "Geral" no filtro
const userListForFilter = computed(() => {
  return [
    { id: '__GENERAL__', full_name: 'Geral (Todos)' }, // Opção especial para filtrar horários gerais
    ...userList.value,
  ];
});


const fetchUsers = async () => {
  // Assume que userStore.fetchUsers() busca e armazena os usuários
  // Se não existir, implemente a busca aqui:
  try {
    const { data, error } = await supabase
      .from('profiles') // Ou sua tabela de usuários
      .select('id, full_name')
      .order('full_name');
    if (error) throw error;
    userList.value = data || []; // Armazena localmente (CORRETO)
    // NÃO deve haver chamada para userStore.setUsers ou similar aqui
  } catch (error: any) {
    console.error('Erro ao buscar usuários:', error.message);
    // Tratar erro (ex: mostrar snackbar)
  }
};

const fetchSchedules = async () => {
  loadingSchedules.value = true;
  try {
    let query = supabase.from('work_schedules').select('*');

    if (selectedUserFilter.value && selectedUserFilter.value !== '__GENERAL__') {
       // Filtra pelo usuário específico OU horários gerais (para que o usuário veja ambos se aplicável)
       query = query.or(`user_id.eq.${selectedUserFilter.value},is_general.eq.true`);
    } else if (selectedUserFilter.value === '__GENERAL__') {
      // Filtra APENAS horários gerais
      query = query.eq('is_general', true);
    }
     // Se nenhum filtro selecionado, busca todos

    const { data, error } = await query.order('is_general', { ascending: false }).order('user_id').order('day_of_week'); // Ordena

    if (error) throw error;
    schedules.value = data || [];
  } catch (error: any) {
    console.error('Erro ao buscar horários:', error.message);
     // Tratar erro (ex: mostrar snackbar)
     schedules.value = []; // Limpa em caso de erro
  } finally {
    loadingSchedules.value = false;
  }
};

const getUserName = (userId: string | null) => {
  if (!userId) return null;
  const user = userList.value.find(u => u.id === userId);
  return user?.full_name || userId.substring(0, 8); // Retorna nome ou ID curto
};

const formatDayOfWeek = (day: number | null | undefined) => {
  if (day === null || day === undefined) return '';
  const foundDay = daysOfWeek.find(d => d.value === day);
  return foundDay?.text || `Dia ${day}`;
};

// Formata HH:MM:SS para HH:MM se os segundos forem 00
const formatTime = (timeStr: string | null | undefined) => {
  if (!timeStr) return '';
  if (timeStr.length === 8 && timeStr.endsWith(':00')) {
    return timeStr.substring(0, 5);
  }
  return timeStr;
}

const openScheduleDialog = (schedule: Schedule | null) => {
  saveError.value = null; // Limpa erro anterior
  if (schedule) {
    editingSchedule.value = { ...schedule }; // Copia para edição
    currentSchedule.value = { ...schedule };
    isGeneralSchedule.value = schedule.is_general;
     // Garante que o formato de hora tenha segundos se não tiver
     if (currentSchedule.value.start_time && currentSchedule.value.start_time.length === 5) {
       currentSchedule.value.start_time += ':00';
     }
     if (currentSchedule.value.end_time && currentSchedule.value.end_time.length === 5) {
       currentSchedule.value.end_time += ':00';
     }
  } else {
    editingSchedule.value = null;
    isGeneralSchedule.value = false;
    currentSchedule.value = { // Reseta para o padrão
      user_id: null,
      day_of_week: 1,
      start_time: '07:00:00', // Inclui segundos
      end_time: '17:30:00', // Inclui segundos
      is_general: false,
    };
  }
  scheduleDialog.value = true;
};

const closeScheduleDialog = () => {
  scheduleDialog.value = false;
  editingSchedule.value = null;
   // Resetar o formulário pode ser necessário se houver validações persistentes
   // scheduleFormRef.value?.reset(); // Descomente se necessário
   scheduleFormRef.value?.resetValidation();
};

const saveSchedule = async () => {
  saveError.value = null; // Limpa erro anterior
  const { valid } = await scheduleFormRef.value?.validate() ?? { valid: false };
  if (!valid) return;

  savingSchedule.value = true;
  try {
    const scheduleData: Omit<Schedule, 'id' | 'created_at'> = {
      user_id: isGeneralSchedule.value ? null : currentSchedule.value.user_id,
      day_of_week: currentSchedule.value.day_of_week,
      start_time: currentSchedule.value.start_time.length === 5 ? `${currentSchedule.value.start_time}:00` : currentSchedule.value.start_time, // Garante segundos
      end_time: currentSchedule.value.end_time.length === 5 ? `${currentSchedule.value.end_time}:00` : currentSchedule.value.end_time, // Garante segundos
      is_general: isGeneralSchedule.value,
    };

     // Verifica conflito antes de salvar (Geral vs Específico no mesmo dia)
     if (isGeneralSchedule.value) {
       const existingSpecific = schedules.value.find(s =>
         !s.is_general && s.day_of_week === scheduleData.day_of_week
       );
       if (existingSpecific && !editingSchedule.value) { // Só checa em novas entradas gerais
         throw new Error(`Já existe um horário específico para ${getUserName(existingSpecific.user_id)} neste dia. Remova-o primeiro.`);
       }
     } else {
       const existingGeneral = schedules.value.find(s =>
         s.is_general && s.day_of_week === scheduleData.day_of_week
       );
       if (existingGeneral && !editingSchedule.value) { // Só checa em novas entradas específicas
          throw new Error(`Já existe um horário geral para este dia. Remova-o primeiro se quiser definir um específico.`);
       }
        // Verifica se já existe um horário para ESTE usuário neste dia (evita duplicata exata)
        const existingUserDay = schedules.value.find(s =>
         s.user_id === scheduleData.user_id &&
         s.day_of_week === scheduleData.day_of_week &&
         s.id !== editingSchedule.value?.id // Ignora o próprio registro ao editar
       );
       if (existingUserDay) {
         throw new Error(`Este usuário já possui um horário definido para ${formatDayOfWeek(scheduleData.day_of_week)}.`);
       }
     }


    let error;
    if (editingSchedule.value?.id) {
      // Atualizar
      const { error: updateError } = await supabase
        .from('work_schedules')
        .update(scheduleData)
        .eq('id', editingSchedule.value.id);
      error = updateError;
    } else {
      // Inserir
      const { error: insertError } = await supabase
        .from('work_schedules')
        .insert(scheduleData);
      error = insertError;
    }

    if (error) throw error;

    closeScheduleDialog();
    await fetchSchedules(); // Recarrega a lista
  } catch (error: any) {
    console.error('Erro ao salvar horário:', error.message);
    saveError.value = `Erro ao salvar: ${error.message}`; // Mostra erro no dialog
    // Tratar erro (ex: mostrar snackbar)
  } finally {
    savingSchedule.value = false;
  }
};

const confirmDelete = (schedule: Schedule) => {
  scheduleToDelete.value = schedule;
  deleteDialog.value = true;
};

const deleteScheduleConfirm = async () => {
  if (!scheduleToDelete.value?.id) return;

  deletingSchedule.value = true;
  try {
    const { error } = await supabase
      .from('work_schedules')
      .delete()
      .eq('id', scheduleToDelete.value.id);

    if (error) throw error;

    deleteDialog.value = false;
    scheduleToDelete.value = null;
    await fetchSchedules(); // Recarrega a lista
  } catch (error: any) {
    console.error('Erro ao excluir horário:', error.message);
    // Tratar erro (ex: mostrar snackbar)
    alert(`Erro ao excluir: ${error.message}`); // Simples alert por enquanto
  } finally {
    deletingSchedule.value = false;
  }
};

onMounted(async () => {
  await fetchUsers(); // Busca usuários primeiro
  await fetchSchedules(); // Depois busca os horários
});
</script>

<style scoped>
/* Estilos adicionais se necessário */
.v-data-table {
  min-height: 300px; /* Evita que a tabela fique muito pequena quando vazia */
}
</style>
