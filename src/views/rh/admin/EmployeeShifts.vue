<template>
  <div class="d-flex flex-column flex-grow-1 overflow-hidden h-100 pa-6">

    <v-row class="h-100 ma-0" align="start">

      <v-col cols="12" lg="7" class="pa-0 pr-lg-6 d-flex flex-column h-100 border-e" :class="isLightMode ? 'border-grey-lighten-2' : 'border-white-10'">

          <div class="d-flex align-center justify-space-between mb-2">
            <h3 class="text-h6 font-weight-black text-uppercase tracking-widest text-primary d-flex align-center gap-2">
              <v-icon>mdi-cogs</v-icon> Templates de Escala Globais
            </h3>
            <v-btn variant="outlined" color="primary" class="btn-3d font-weight-bold text-caption rounded-sm" prepend-icon="mdi-plus" height="36" @click="createNewShiftTemplate">NOVO TEMPLATE</v-btn>
          </div>
          <p class="text-caption font-weight-bold opacity-70 mb-5">
            Crie matrizes de horários para a empresa. Alterar um template afetará todos os colaboradores vinculados a ele.
          </p>

          <div class="d-flex flex-wrap gap-3 pb-4 border-b flex-shrink-0" :class="isLightMode ? 'border-grey-lighten-2' : 'border-white-10'">
            <v-chip
              v-for="template in shiftTemplates"
              :key="template.id"
              size="large"
              class="font-weight-black cursor-pointer chip-3d tracking-widest text-uppercase rounded-sm"
              :color="selectedShiftTemplateId === template.id ? 'primary' : (isLightMode ? 'grey-darken-2' : 'grey-lighten-1')"
              :variant="selectedShiftTemplateId === template.id ? 'flat' : 'outlined'"
              @click="selectedShiftTemplateId = template.id"
            >
              <v-icon start size="small" v-if="selectedShiftTemplateId === template.id">mdi-check-circle</v-icon>{{ template.name }}
            </v-chip>
          </div>

          <div v-if="selectedShiftTemplate" class="flex-grow-1 overflow-y-auto custom-scroll pr-4 mt-4 pb-4">

            <div class="pa-5 rounded-sm border-thin shadow-sm mb-6" :class="isLightMode ? 'bg-grey-lighten-5' : 'bg-black-20 border-white-05'">
              <v-row dense class="mb-2">
                <v-col cols="12" md="8">
                  <div class="text-[10px] font-weight-black text-uppercase opacity-70 tracking-widest mb-1 d-block">Nomenclatura da Matriz</div>
                  <v-text-field v-model="selectedShiftTemplate.name" variant="outlined" density="comfortable" hide-details color="primary" class="ui-field font-weight-black" :bg-color="isLightMode ? 'white' : 'rgba(0,0,0,0.4)'"></v-text-field>
                </v-col>
                <v-col cols="12" md="4">
                  <div class="text-[10px] font-weight-black text-uppercase opacity-70 tracking-widest mb-1 d-block">Carga Semanal (h)</div>
                  <v-text-field v-model.number="selectedShiftTemplate.weekly_hours" type="number" variant="outlined" density="comfortable" hide-details color="primary" class="ui-field font-weight-black font-mono text-primary" :bg-color="isLightMode ? 'white' : 'rgba(0,0,0,0.4)'"></v-text-field>
                </v-col>
              </v-row>

              <v-row dense class="mt-4 pt-4 border-t" :class="isLightMode ? 'border-grey-lighten-2' : 'border-white-10'">
                <v-col cols="12" sm="6" class="d-flex align-center gap-2">
                  <v-switch v-model="selectedShiftTemplate.allow_bank_hours" color="primary" label="Banco de Horas" hide-details density="compact" class="font-weight-bold text-caption flex-grow-0 switch-sm"></v-switch>
                  <v-tooltip location="top" content-class="premium-tooltip" max-width="250">
                    <template v-slot:activator="{ props }"><v-icon v-bind="props" size="16" class="opacity-50 cursor-help">mdi-help-circle-outline</v-icon></template>
                    <span>Permite acumular e compensar horas (Saldo positivo/negativo) ao invés de pagar em pecúnia mensalmente.</span>
                  </v-tooltip>
                </v-col>
                <v-col cols="12" sm="6" class="d-flex align-center gap-2">
                  <v-switch v-model="selectedShiftTemplate.night_shift" color="deep-purple" label="Adicional Noturno (CLT)" hide-details density="compact" class="font-weight-bold text-caption flex-grow-0 switch-sm"></v-switch>
                  <v-tooltip location="top" content-class="premium-tooltip" max-width="250">
                    <template v-slot:activator="{ props }"><v-icon v-bind="props" size="16" class="opacity-50 cursor-help">mdi-help-circle-outline</v-icon></template>
                    <span>Ativa o cômputo da hora ficta (52m30s) e adicional noturno de 20% para jornadas compreendidas entre 22h e 05h.</span>
                  </v-tooltip>
                </v-col>
              </v-row>
            </div>

            <div class="text-caption font-weight-black text-uppercase opacity-70 tracking-widest mb-3">Definição Operacional Diária</div>

            <div class="d-flex flex-column gap-3">
              <div
                v-for="day in selectedShiftTemplate.days"
                :key="day.weekday"
                class="pa-4 rounded-sm border-thin transition-all shadow-sm"
                :class="[day.active ? (isLightMode ? 'bg-white border-primary-lighten-3' : 'bg-black-40 border-primary-darken-2') : (isLightMode ? 'bg-grey-lighten-4 opacity-70' : 'bg-black-20 opacity-50')]"
              >
                <div class="d-flex align-center justify-space-between">
                  <div class="font-weight-black text-body-2 d-flex align-center gap-3 text-uppercase tracking-widest" :class="day.active ? 'text-primary' : 'text-grey'">
                    <v-icon size="20">{{ day.active ? 'mdi-calendar-check' : 'mdi-calendar-remove' }}</v-icon>{{ weekdayName(day.weekday) }}

                    <v-chip v-if="day.active" size="x-small" variant="tonal" color="primary" class="font-weight-bold chip-3d px-2 ml-2 cursor-pointer" @click="mirrorDayToOthers(day)">
                       <v-icon start size="12">mdi-content-copy</v-icon>Espelhar nos demais dias
                    </v-chip>
                  </div>
                  <v-switch v-model="day.active" color="primary" hide-details density="compact" class="switch-sm"></v-switch>
                </div>

                <v-expand-transition>
                  <div v-if="day.active">
                    <v-row dense class="mx-0 mt-4">
                      <v-col cols="6" sm="3" class="pa-1">
                        <label class="text-[9px] font-weight-black text-uppercase opacity-70 tracking-widest mb-1 d-block">Entrada</label>
                        <v-text-field v-model="day.start_time" type="time" variant="outlined" density="compact" hide-details color="primary" class="ui-field font-mono font-weight-bold text-caption" :bg-color="isLightMode ? 'bg-grey-lighten-5' : 'rgba(0,0,0,0.2)'"></v-text-field>
                      </v-col>
                      <v-col cols="6" sm="3" class="pa-1">
                        <label class="text-[9px] font-weight-black text-uppercase opacity-70 tracking-widest mb-1 d-block">Pausa (Ida)</label>
                        <v-text-field v-model="day.break_start" type="time" variant="outlined" density="compact" hide-details color="primary" class="ui-field font-mono font-weight-bold text-caption" :bg-color="isLightMode ? 'bg-grey-lighten-5' : 'rgba(0,0,0,0.2)'"></v-text-field>
                      </v-col>
                      <v-col cols="6" sm="3" class="pa-1">
                        <label class="text-[9px] font-weight-black text-uppercase opacity-70 tracking-widest mb-1 d-block">Pausa (Volta)</label>
                        <v-text-field v-model="day.break_end" type="time" variant="outlined" density="compact" hide-details color="primary" class="ui-field font-mono font-weight-bold text-caption" :bg-color="isLightMode ? 'bg-grey-lighten-5' : 'rgba(0,0,0,0.2)'"></v-text-field>
                      </v-col>
                      <v-col cols="6" sm="3" class="pa-1">
                        <label class="text-[9px] font-weight-black text-uppercase opacity-70 tracking-widest mb-1 d-block">Saída</label>
                        <v-text-field v-model="day.end_time" type="time" variant="outlined" density="compact" hide-details color="primary" class="ui-field font-mono font-weight-bold text-caption" :bg-color="isLightMode ? 'bg-grey-lighten-5' : 'rgba(0,0,0,0.2)'"></v-text-field>
                      </v-col>
                    </v-row>
                  </div>
                </v-expand-transition>
              </div>
            </div>

            <div class="mt-6 pt-5 border-t d-flex justify-end sticky-bottom" style="background: inherit; z-index: 10;" :class="isLightMode ? 'border-grey-lighten-2' : 'border-white-10'">
              <v-btn variant="flat" color="success" class="btn-3d font-weight-black px-10 tracking-widest rounded-sm" size="large" prepend-icon="mdi-content-save-all" :loading="savingTemplate" @click="saveShiftTemplate">
                VALIDAR TEMPLATE GLOBAL
              </v-btn>
            </div>
          </div>
      </v-col>

      <v-col cols="12" lg="5" class="pa-0 pl-lg-6 d-flex flex-column h-100 custom-scroll overflow-y-auto pb-6">

          <div class="mb-3">
            <h3 class="text-subtitle-1 font-weight-black text-uppercase tracking-widest text-primary d-flex align-center gap-2 lh-1">
              <v-icon>mdi-link-variant</v-icon> Vínculo Contratual
            </h3>
            <p class="text-[10px] font-weight-bold opacity-70 mt-1">Acople o colaborador a um Template Global.</p>
          </div>
          <div class="pa-5 rounded-sm border-thin shadow-sm mb-6" :class="isLightMode ? 'bg-blue-lighten-5 border-blue-lighten-4' : 'bg-blue-darken-4 bg-opacity-10 border-blue-darken-3'">

            <label class="text-[10px] font-weight-black text-uppercase opacity-70 tracking-widest mb-1 d-block">Modelo de Jornada (Template Base)</label>
            <v-autocomplete
              v-model="selectedAssignment.shift_template_id"
              :items="shiftTemplates"
              item-title="name"
              item-value="id"
              variant="outlined"
              density="comfortable"
              color="primary"
              hide-details
              class="ui-field mb-4 font-weight-bold"
              :bg-color="isLightMode ? 'white' : 'rgba(0,0,0,0.4)'"
            ></v-autocomplete>

            <label class="text-[10px] font-weight-black text-uppercase opacity-70 tracking-widest mb-1 d-block">Liderança / Gestor Direto</label>
            <v-text-field
              v-model="selectedAssignment.manager"
              placeholder="Ex: João Vitor"
              variant="outlined"
              density="comfortable"
              color="primary"
              hide-details
              class="ui-field mb-4 font-weight-bold"
              :bg-color="isLightMode ? 'white' : 'rgba(0,0,0,0.4)'"
            ></v-text-field>

            <div class="d-flex gap-4 mb-5">
              <div class="flex-grow-1">
                 <label class="text-[10px] font-weight-black text-uppercase opacity-70 tracking-widest mb-1 d-block">Insalubridade (%)</label>
                 <v-autocomplete
                   v-model="selectedAssignment.insalubrity_level"
                   :items="[0, 10, 20, 40]"
                   variant="outlined"
                   density="comfortable"
                   color="primary"
                   hide-details
                   class="ui-field font-weight-bold font-mono"
                   :bg-color="isLightMode ? 'white' : 'rgba(0,0,0,0.4)'"
                 ></v-autocomplete>
              </div>
              <div class="d-flex align-center flex-grow-1 mt-4 px-4 rounded-sm border-thin shadow-sm" :class="isLightMode ? 'bg-white' : 'bg-black-20'">
                <v-switch
                  v-model="selectedAssignment.hazard_pay"
                  color="error"
                  label="Risco Periculosidade"
                  hide-details
                  density="compact"
                  class="font-weight-bold text-caption switch-sm"
                ></v-switch>
              </div>
            </div>

            <v-btn block size="large" variant="flat" color="primary" class="btn-3d font-weight-black tracking-widest rounded-sm" :loading="savingAssignment" @click="saveAssignment">
              CRAVAR CONTRATO
            </v-btn>
          </div>

          <div class="mb-3 mt-2 d-flex align-center justify-space-between">
            <div>
               <h3 class="text-subtitle-1 font-weight-black text-uppercase tracking-widest text-success d-flex align-center gap-2 lh-1">
                 <v-icon>mdi-tablet-dashboard</v-icon> Liberação de Acessos
               </h3>
               <p class="text-[10px] font-weight-bold opacity-70 mt-1 mb-0">Em quais totens esta pessoa bate ponto.</p>
            </div>
            <v-tooltip location="top" content-class="premium-tooltip" max-width="300">
               <template v-slot:activator="{ props }"><v-icon v-bind="props" size="20" class="opacity-50 cursor-help">mdi-help-circle-outline</v-icon></template>
               <span>Se a lista estiver vazia, o colaborador será sumariamente bloqueado no sistema de Kiosks por não pertencer a nenhum polo.</span>
            </v-tooltip>
          </div>
          <div class="pa-5 rounded-sm border-thin shadow-sm mb-6" :class="isLightMode ? 'bg-green-lighten-5 border-green-lighten-4' : 'bg-green-darken-4 bg-opacity-10 border-green-darken-3'">
            <label class="text-[10px] font-weight-black text-uppercase opacity-70 tracking-widest mb-1 d-block text-success">Totens Mapeados</label>
            <v-select
              v-model="employeeKioskIds"
              :items="kiosks"
              item-title="name"
              item-value="id"
              multiple
              chips
              variant="outlined"
              color="success"
              class="ui-field font-weight-bold mb-4"
              :bg-color="isLightMode ? 'white' : 'rgba(0,0,0,0.4)'"
              hide-details
              :menu-props="{ theme: isLightMode ? 'light' : 'dark', contentClass: isLightMode ? 'rounded-sm mt-1' : 'dark-dropdown-menu border border-white-10 rounded-sm mt-1' }"
            ></v-select>
            <v-btn block size="large" variant="flat" color="success" class="btn-3d font-weight-black tracking-widest rounded-sm" :loading="savingAssignmentsGlobal" @click="saveIndividualKiosks">
              <v-icon start>mdi-security</v-icon> AUTORIZAR TERMINAIS
            </v-btn>
          </div>

          <div class="pa-5 rounded-sm border-thin shadow-sm d-flex flex-column" :class="isLightMode ? 'bg-white' : 'bg-black-40 border-white-10'">
            <div class="text-subtitle-2 font-weight-black text-uppercase tracking-widest mb-1 text-primary-lighten-2 d-flex align-center gap-2 lh-1">
              <v-icon size="18">mdi-calendar-alert</v-icon>Exceções Pontuais (Overrides)
            </div>
            <div class="text-[10px] opacity-70 mb-4 font-weight-bold">Troca forçada de horário para um dia específico que foge da regra global.</div>

            <div class="d-flex flex-wrap gap-2 mb-4 align-end">
               <div class="flex-grow-1">
                 <label class="text-[9px] font-weight-black text-uppercase opacity-70 tracking-widest mb-1 d-block">Data</label>
                 <v-text-field v-model="newOverride.date" type="date" variant="outlined" density="compact" hide-details class="ui-field font-weight-bold font-mono text-caption" :bg-color="isLightMode ? 'bg-grey-lighten-5' : 'rgba(0,0,0,0.2)'"></v-text-field>
               </div>
               <div style="width: 85px;">
                 <label class="text-[9px] font-weight-black text-uppercase opacity-70 tracking-widest mb-1 d-block">Entrada</label>
                 <v-text-field v-model="newOverride.start_time" type="time" variant="outlined" density="compact" hide-details class="ui-field font-weight-bold font-mono text-caption text-center" :bg-color="isLightMode ? 'bg-grey-lighten-5' : 'rgba(0,0,0,0.2)'"></v-text-field>
               </div>
               <div style="width: 85px;">
                 <label class="text-[9px] font-weight-black text-uppercase opacity-70 tracking-widest mb-1 d-block">Saída</label>
                 <v-text-field v-model="newOverride.end_time" type="time" variant="outlined" density="compact" hide-details class="ui-field font-weight-bold font-mono text-caption text-center" :bg-color="isLightMode ? 'bg-grey-lighten-5' : 'rgba(0,0,0,0.2)'"></v-text-field>
               </div>
               <v-btn variant="tonal" color="primary-lighten-2" class="btn-3d font-weight-black px-4 rounded-sm" height="38" @click="saveOverride"><v-icon>mdi-plus</v-icon></v-btn>
            </div>

            <div class="d-flex flex-column gap-2 flex-grow-1" style="max-height: 200px; overflow-y: auto;">
              <div v-for="ov in employeeOverrides" :key="ov.id" class="d-flex align-center justify-space-between pa-2 rounded-sm border-thin shadow-sm transition-all hover-card" :class="isLightMode ? 'bg-grey-lighten-5' : 'bg-grey-darken-4'">
                <div class="pl-2">
                  <div class="font-weight-black text-[11px] text-primary-lighten-2 d-flex align-center gap-2"><v-icon size="14">mdi-calendar-edit</v-icon>{{ formatDateSafe(ov.date) }}</div>
                  <div class="text-[10px] font-mono mt-0 opacity-80 font-weight-bold">Das {{ ov.start_time }} às {{ ov.end_time }}</div>
                </div>
                <v-btn icon="mdi-close" variant="text" color="error" size="small" @click="deleteOverride(ov.id)"></v-btn>
              </div>
              <div v-if="employeeOverrides.length === 0" class="text-center py-6 opacity-40 text-[10px] font-weight-bold text-uppercase tracking-widest">
                Sem exceções. Fluxo seguindo a regra geral.
              </div>
            </div>
          </div>
      </v-col>
    </v-row>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, reactive, watch } from 'vue';
import { storeToRefs } from 'pinia';
import { supabase } from '@/api/supabase';
import { useThemeStore } from '@/stores/theme';
import { useTimeTrackingStore } from '@/stores/timeTracking';
import { format } from 'date-fns';

const emit = defineEmits(['show-toast']);

// --- STORES ---
const themeStore = useThemeStore();
const timeStore = useTimeTrackingStore();
const isLightMode = computed(() => themeStore.currentMode === 'light');

const {
  selectedEmployeeId,
  assignments,
  shiftTemplates,
  kiosks,
  kioskUsers,
  employeeOverrides,
  selectedAssignment
} = storeToRefs(timeStore);

// --- ESTADOS LOCAIS ---
const savingAssignment = ref(false);
const savingAssignmentsGlobal = ref(false);
const savingTemplate = ref(false);

const employeeKioskIds = ref<string[]>([]);
const selectedShiftTemplateId = ref<string>('');

const newOverride = reactive({
  date: format(new Date(), 'yyyy-MM-dd'),
  start_time: '08:00',
  end_time: '18:00'
});

// --- COMPUTEDS LOCAIS ---
const selectedShiftTemplate = computed(() => {
  return shiftTemplates.value.find(t => t.id === selectedShiftTemplateId.value) || null;
});

// --- UTILITÁRIOS ---
const uid = () => Math.random().toString(36).substring(2, 10);
const weekdayName = (d: number) => ['Domingo','Segunda','Terça','Quarta','Quinta','Sexta','Sábado'][d] || '';
const formatDateSafe = (dStr: string) => {
  if(!dStr) return '-';
  return dStr.split('T')[0].split('-').reverse().join('/');
};

// --- WATCHERS ---
watch(selectedEmployeeId, (id) => {
  if (id) {
    employeeKioskIds.value = kioskUsers.value
      .filter((ku: any) => ku.employee_id === id)
      .map((ku: any) => ku.kiosk_id);

    if (selectedAssignment.value && selectedAssignment.value.shift_template_id) {
       selectedShiftTemplateId.value = selectedAssignment.value.shift_template_id;
    } else if (shiftTemplates.value.length > 0) {
       selectedShiftTemplateId.value = shiftTemplates.value[0].id;
    }
  }
}, { immediate: true });

// --- AÇÃO: ESPELHAR REGRA DA JORNADA ---
function mirrorDayToOthers(sourceDay: any) {
    if (!selectedShiftTemplate.value) return;

    selectedShiftTemplate.value.days.forEach(day => {
        if (day.weekday !== sourceDay.weekday && day.active) {
            day.start_time = sourceDay.start_time;
            day.break_start = sourceDay.break_start;
            day.break_end = sourceDay.break_end;
            day.end_time = sourceDay.end_time;
        }
    });

    emit('show-toast', { message: `Regra de ${weekdayName(sourceDay.weekday)} espelhada nos demais dias ativos.`, color: 'info' });
}

// --- MÉTODOS DE VÍNCULO E ACESSOS ---
async function saveAssignment() {
  if (!selectedEmployeeId.value) { emit('show-toast',{message:'Selecione um funcionário na busca superior.', color:'warning'}); return;}
  savingAssignment.value = true;
  try {
    const payload = { ...selectedAssignment.value, employee_id: selectedEmployeeId.value };
    if (!payload.id || !payload.id.includes('-')) delete payload.id;

    await supabase.from('time_tracking_assignments').upsert(payload, { onConflict: 'employee_id' });
    emit('show-toast', { message: 'A amarração contratual foi firmada.', color: 'success' });

    timeStore.regenerateMonthMirror();
  } catch(e: any) {
    emit('show-toast', { message: 'Erro na criação de vínculo.', color: 'error' });
  } finally {
    savingAssignment.value = false;
  }
}

async function saveIndividualKiosks() {
  if (!selectedEmployeeId.value) return;
  savingAssignmentsGlobal.value = true;
  try {
    await supabase.from('time_tracking_kiosk_users').delete().eq('employee_id', selectedEmployeeId.value);

    if (employeeKioskIds.value.length > 0) {
      const payload = employeeKioskIds.value.map(kId => ({
        kiosk_id: kId,
        employee_id: selectedEmployeeId.value
      }));
      await supabase.from('time_tracking_kiosk_users').insert(payload);
    }

    const { data } = await supabase.from('time_tracking_kiosk_users').select('*');
    if (data) timeStore.kioskUsers = data;

    emit('show-toast', { message: 'Acessos a totens atualizados.', color: 'success' });
  } catch(e: any) {
    emit('show-toast', { message: 'Erro ao vincular totens. Verifique permissões RLS.', color: 'error' });
  } finally {
    savingAssignmentsGlobal.value = false;
  }
}

// --- MÉTODOS DE EXCEÇÕES (OVERRIDES) ---
async function saveOverride() {
  if (!selectedEmployeeId.value || !newOverride.date) return;
  try {
    await supabase.from('time_tracking_overrides').insert({
      employee_id: selectedEmployeeId.value,
      ...newOverride
    });
    emit('show-toast', { message: 'A exceção operou sobre as regras normais.', color: 'success' });
    await timeStore.fetchMonthDynamicData();
  } catch(e: any) {
    emit('show-toast', { message: 'Falha na injeção de override.', color: 'error' });
  }
}

async function deleteOverride(id: string) {
  try {
    await supabase.from('time_tracking_overrides').delete().eq('id', id);
    await timeStore.fetchMonthDynamicData();
  } catch(e) {}
}

// --- MÉTODOS DE TEMPLATES GLOBAIS ---
function createNewShiftTemplate() {
  const newTmpl = {
    id: uid(),
    name: 'Nova Jornada Customizada',
    code: 'NEW-01',
    weekly_hours: 44,
    allow_bank_hours: true,
    night_shift: false,
    requires_manager_approval: true,
    days: [1,2,3,4,5].map(d => ({
      weekday: d, active: true, start_time: '08:00', break_start: '12:00', break_end: '13:00', end_time: '18:00'
    })).concat([{ weekday: 6, active: false }, { weekday: 0, active: false }] as any[])
  };

  timeStore.shiftTemplates.push(newTmpl);
  selectedShiftTemplateId.value = newTmpl.id;
}

async function saveShiftTemplate() {
  if (!selectedShiftTemplate.value) return;
  savingTemplate.value = true;
  try {
    const payload = { ...selectedShiftTemplate.value };
    if (!payload.id.includes('-')) delete payload.id;

    await supabase.from('time_tracking_shift_templates').upsert(payload);
    emit('show-toast', { message: 'Template Global sincronizado com o banco.', color: 'success' });

    const { data: st } = await supabase.from('time_tracking_shift_templates').select('*');
    if (st) timeStore.shiftTemplates = st;
  } catch (e: any) {
    emit('show-toast', { message: 'Falha crítica ao gravar template: ' + e.message, color: 'error' });
  } finally {
    savingTemplate.value = false;
  }
}
</script>

<style lang="scss">
/* Força as opções de tema escuro nos menus */
.dark-dropdown-menu { background-color: #1a1a20 !important; color: #ffffff !important; }
.dark-dropdown-menu .v-list { background-color: transparent !important; color: #ffffff !important; }
.dark-dropdown-menu .v-list-item:hover { background-color: rgba(255, 255, 255, 0.08) !important; }

/* Tooltip Premium */
:global(.premium-tooltip) {
  background: rgba(18, 18, 22, 0.95) !important; border: 1px solid rgba(255, 255, 255, 0.15) !important;
  backdrop-filter: blur(10px); box-shadow: 0 8px 24px rgba(0,0,0,0.5) !important;
  color: white !important; border-radius: 4px; padding: 6px 12px; font-weight: 700; line-height: 1.3; font-size: 10px !important; letter-spacing: 0.02em;
}
</style>

<style scoped lang="scss">
/* Estética Base */
.border-white-05 { border-color: rgba(255, 255, 255, 0.05) !important; }
.border-white-10 { border-color: rgba(255, 255, 255, 0.1) !important; }
.bg-black-20 { background-color: rgba(0,0,0,0.2) !important; }
.bg-black-40 { background-color: rgba(0,0,0,0.4) !important; }
.rounded-sm { border-radius: 4px !important; }
.border-thin { border: 1px solid rgba(128, 128, 128, 0.15) !important; }

/* Tipografia */
.tracking-widest { letter-spacing: 0.05em; }
.lh-1 { line-height: 1.1; }

/* Botões e Interações */
.btn-3d { box-shadow: 0 3px 5px rgba(0,0,0,0.1), inset 0 2px 0 rgba(255,255,255,0.15) !important; text-transform: none !important; }
.btn-3d:active { transform: translateY(2px); box-shadow: 0 1px 2px rgba(0,0,0,0.1), inset 0 1px 0 rgba(255,255,255,0.1) !important; }
.chip-3d { box-shadow: 0 2px 4px rgba(0,0,0,0.2), inset 0 1px 0 rgba(255,255,255,0.1); border-radius: 4px !important; }
.hover-card:hover { transform: translateY(-1px); box-shadow: 0 6px 12px rgba(0,0,0,0.1) !important; }
.transition-all { transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1); }

/* Switch menor */
.switch-sm :deep(.v-switch__track) { height: 16px !important; }
.switch-sm :deep(.v-switch__thumb) { width: 12px !important; height: 12px !important; }

/* Forms e Inputs */
.ui-field :deep(.v-field) { border-radius: 4px !important; }
.ui-field :deep(.v-field__input) { text-align: center; }

/* Scrollbars */
.custom-scroll { scrollbar-gutter: stable; }
.custom-scroll::-webkit-scrollbar { width: 4px; height: 4px; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128, 0.3); border-radius: 4px; }

.d-block { display: block; }
</style>
