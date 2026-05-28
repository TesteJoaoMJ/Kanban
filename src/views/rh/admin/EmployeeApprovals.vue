<template>
  <div class="h-100 pa-6">
    <v-row class="h-100 ma-0" align="stretch">

      <v-col cols="12" md="6" class="pa-0 pr-md-5 d-flex flex-column h-100">
          <div class="d-flex align-center justify-space-between mb-5">
            <div class="text-subtitle-1 font-weight-black text-warning text-uppercase tracking-widest d-flex align-center gap-2">
              <v-icon>mdi-alert-decagram</v-icon>Tratamentos e Correções
            </div>
          </div>

          <div class="flex-grow-1 overflow-y-auto custom-scroll pr-3">
            <div v-if="corrections.length === 0" class="pa-10 text-center opacity-50 font-weight-bold border-dashed rounded-xl border-thin">
              Nenhum chamado de correção pendente.
            </div>

            <div v-for="cor in corrections" :key="cor.id" class="pa-5 rounded-xl border-thin mb-4 shadow-sm transition-all hover-card" :class="isLightMode ? 'bg-white' : 'bg-grey-darken-4'">
                <div class="d-flex justify-space-between align-start mb-3">
                  <v-chip size="small" color="warning" variant="flat" class="font-weight-black font-mono text-uppercase chip-3d px-4">
                    {{ formatDateSafe(cor.date) }}
                  </v-chip>
                  <v-btn icon="mdi-trash-can-outline" size="small" variant="text" color="error" @click="deleteCorrection(cor.id)"></v-btn>
                </div>
                <div class="text-caption font-weight-bold opacity-70 mb-1 text-uppercase tracking-widest">Relato do Colaborador:</div>
                <p class="text-body-2 font-italic opacity-90 mb-5 pa-3 rounded-lg border-thin" :class="isLightMode ? 'bg-grey-lighten-5' : 'bg-grey-darken-3'">
                  "{{ cor.justification }}"
                </p>
                <v-btn block variant="tonal" color="primary" class="font-weight-bold btn-3d" @click="$emit('change-tab', 'cockpit')">
                  Abrir Espelho para Ajuste
                </v-btn>
            </div>
          </div>

          <div class="mt-5 pt-5 border-t" :class="isLightMode ? 'border-grey-lighten-2' : 'border-white-10'">
            <div class="text-caption font-weight-black text-uppercase opacity-70 tracking-widest mb-3">Abertura Manual de Chamado</div>
            <v-text-field v-model="newCorrection.date" type="date" label="Data Base" variant="outlined" density="comfortable" class="ui-field mb-3 font-weight-bold font-mono" :bg-color="isLightMode ? 'white' : 'grey-darken-4'"></v-text-field>
            <v-textarea v-model="newCorrection.justification" label="Motivo/Justificativa" rows="2" variant="outlined" density="comfortable" class="ui-field mb-4 font-weight-bold" :bg-color="isLightMode ? 'white' : 'grey-darken-4'"></v-textarea>
            <v-btn block variant="flat" color="warning" class="btn-3d font-weight-black tracking-widest" size="large" prepend-icon="mdi-plus" @click="saveCorrection" :loading="isSavingCorrection">
              REGISTRAR CHAMADO
            </v-btn>
          </div>
      </v-col>

      <v-col cols="12" md="6" class="pa-0 pl-md-5 d-flex flex-column border-s h-100" :class="isLightMode ? 'border-grey-lighten-2' : 'border-white-10'">
          <div class="d-flex align-center justify-space-between mb-5">
            <div class="text-subtitle-1 font-weight-black text-primary text-uppercase tracking-widest d-flex align-center gap-2">
              <v-icon>mdi-door-open</v-icon>Liberação Extraordinária (Kiosk)
            </div>
            <v-btn variant="outlined" size="small" color="primary" class="btn-3d font-weight-bold" @click="openOvertimeRequestModal">
              Nova Permissão
            </v-btn>
          </div>

          <div class="flex-grow-1 overflow-y-auto custom-scroll pr-3">
            <div v-if="overtimeRequests.length === 0" class="pa-10 text-center opacity-50 font-weight-bold border-dashed rounded-xl border-thin">
              Nenhuma janela de hora extra solicitada.
            </div>

            <div v-for="req in overtimeRequests" :key="req.id" class="pa-5 rounded-xl border-thin mb-4 shadow-sm transition-all hover-card" :class="isLightMode ? 'bg-white' : 'bg-grey-darken-4'">
                <div class="d-flex justify-space-between align-center mb-4">
                  <span class="font-weight-black text-body-1 font-mono text-primary d-flex align-center gap-2">
                    <v-icon size="small" color="primary">mdi-calendar</v-icon>{{ formatDateSafe(req.date) }}
                  </span>
                  <v-chip size="small" :color="approvalColor(req.status)" variant="flat" class="font-weight-black text-uppercase chip-3d px-4 tracking-widest">
                    {{ req.status }}
                  </v-chip>
                </div>

                <div class="text-caption font-mono font-weight-black opacity-80 mb-4 px-3 py-2 rounded-lg border-thin d-inline-block" :class="isLightMode ? 'bg-grey-lighten-5' : 'bg-grey-darken-3'">
                  Janela: {{ req.start_time }} até {{ req.end_time }}
                </div>
                <p class="text-body-2 font-weight-medium opacity-80 mb-5">{{ req.reason }}</p>

                <div class="d-flex gap-3" v-if="req.status === 'Pendente'">
                  <v-btn flex-grow-1 variant="flat" color="success" class="btn-3d font-weight-black tracking-widest" @click="updateOvertimeStatus(req.id, 'Aprovado')">
                    <v-icon start>mdi-check</v-icon> AUTORIZAR
                  </v-btn>
                  <v-btn flex-grow-1 variant="tonal" color="error" class="btn-3d font-weight-bold" @click="updateOvertimeStatus(req.id, 'Rejeitado')">
                    NEGAR
                  </v-btn>
                </div>

                <v-btn v-if="req.status === 'Aprovado'" block variant="outlined" color="primary" class="btn-3d font-weight-black mt-3 tracking-widest border-primary" prepend-icon="mdi-kiosk" @click="releaseToKiosk(req)">
                  INJETAR PERMISSÃO NO KIOSK
                </v-btn>
            </div>
          </div>

          <div class="mt-5 pt-5 border-t pa-5 rounded-xl shadow-sm border-thin" :class="isLightMode ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-grey-darken-4 border-white-10'">
            <div class="d-flex justify-space-between align-center mb-3">
                <div class="text-caption font-weight-black text-uppercase opacity-70 tracking-widest lh-1">Parâmetro: Cooldown Global Kiosks (Minutos)</div>
                <v-btn size="small" variant="flat" color="primary" class="btn-3d font-weight-bold px-4" @click="saveGlobalSettings" :loading="isSavingSettings">Gravar</v-btn>
            </div>
            <v-text-field
              v-model.number="legalRules.kiosk_cooldown_minutes"
              type="number"
              variant="outlined"
              density="comfortable"
              hide-details
              class="ui-field font-weight-black font-mono text-primary"
              :bg-color="isLightMode ? 'white' : 'grey-darken-3'"
            ></v-text-field>
          </div>
      </v-col>

    </v-row>
  </div>
</template>

<script setup lang="ts">
import { reactive, computed, ref } from 'vue';
import { storeToRefs } from 'pinia';
import { supabase } from '@/api/supabase';
import { format } from 'date-fns';
import { useThemeStore } from '@/stores/theme';
import { useTimeTrackingStore } from '@/stores/timeTracking';

// Dispara eventos para o componente pai
const emit = defineEmits(['show-toast', 'change-tab']);

// --- STORES ---
const themeStore = useThemeStore();
const timeStore = useTimeTrackingStore();
const isLightMode = computed(() => themeStore.currentMode === 'light');

const {
  selectedEmployeeId,
  corrections,
  overtimeRequests,
  legalRules,
  selectedAssignment
} = storeToRefs(timeStore);

// --- ESTADOS LOCAIS ---
const isSavingCorrection = ref(false);
const isSavingSettings = ref(false);
const newCorrection = reactive({
  date: format(new Date(), 'yyyy-MM-dd'),
  justification: ''
});

// --- UTILITÁRIOS ---
const formatDateSafe = (dStr: string) => {
  if (!dStr) return '-';
  return dStr.split('T')[0].split('-').reverse().join('/');
};

const approvalColor = (s: string) => s === 'Aprovado' ? 'success' : (s === 'Rejeitado' ? 'error' : 'warning');

// --- MÉTODOS DE CORREÇÃO (CHAMADOS MANUAIS) ---
async function saveCorrection() {
  if (!selectedEmployeeId.value || !newCorrection.date || !newCorrection.justification) return;
  isSavingCorrection.value = true;
  try {
    const { error } = await supabase.from('time_tracking_corrections').insert({
      employee_id: selectedEmployeeId.value,
      ...newCorrection
    });
    if (error) throw error;

    newCorrection.justification = '';
    emit('show-toast', { message: 'Chamado de correção registrado com sucesso.', color: 'success' });
    await timeStore.fetchMonthDynamicData();
  } catch (e: any) {
    emit('show-toast', { message: 'Erro ao registrar chamado: ' + e.message, color: 'error' });
  } finally {
    isSavingCorrection.value = false;
  }
}

async function deleteCorrection(id: string) {
  try {
    await supabase.from('time_tracking_corrections').delete().eq('id', id);
    emit('show-toast', { message: 'Correção removida.', color: 'success' });
    await timeStore.fetchMonthDynamicData();
  } catch (e) {
    emit('show-toast', { message: 'Erro ao remover correção.', color: 'error' });
  }
}

// --- MÉTODOS DE HORA EXTRA E KIOSK ---
async function openOvertimeRequestModal() {
  const date = prompt('Forneça o selo temporal da liberação (YYYY-MM-DD):', format(new Date(), 'yyyy-MM-dd'));
  if (date) {
    try {
      const { error } = await supabase.from('time_tracking_overtime_requests').insert({
        employee_id: selectedEmployeeId.value,
        date,
        start_time: '18:00',
        end_time: '20:00',
        reason: 'Ajuste Sistêmico Manual',
        manager: selectedAssignment.value.manager
      });
      if (error) throw error;
      emit('show-toast', { message: 'Permissão criada com sucesso.', color: 'success' });
      await timeStore.fetchMonthDynamicData();
    } catch(e: any) {
      emit('show-toast', { message: 'Erro ao criar permissão.', color: 'error' });
    }
  }
}

async function updateOvertimeStatus(id: string, status: string) {
  try {
    await supabase.from('time_tracking_overtime_requests').update({ status }).eq('id', id);
    await timeStore.fetchMonthDynamicData();
  } catch(e) {
    emit('show-toast', { message: 'Erro ao atualizar status.', color: 'error' });
  }
}

async function releaseToKiosk(req: any) {
  try {
    const { error } = await supabase.from('time_tracking_kiosk_releases').insert({
      employee_id: req.employee_id,
      date: req.date,
      window_start: req.start_time,
      window_end: req.end_time,
      reason: 'Ordem de Operador Superior',
      approved: true
    });
    if (error) throw error;
    emit('show-toast', { message: 'Permissão injetada com sucesso nos terminais Kiosk.', color: 'success' });
    await timeStore.fetchMonthDynamicData();
  } catch(e: any) {
    emit('show-toast', { message: 'Falha ao injetar permissão no Kiosk.', color: 'error' });
  }
}

// --- PARÂMETROS GLOBAIS ---
async function saveGlobalSettings() {
  isSavingSettings.value = true;
  try {
     const payload = { ...legalRules.value, id: 1 };
     const { error } = await supabase.from('time_tracking_settings').upsert(payload);
     if (error) throw error;
     emit('show-toast', { message: 'Parâmetros globais atualizados.', color: 'success' });
  } catch (e: any) {
     emit('show-toast', { message: 'Erro ao atualizar configurações: ' + e.message, color: 'error' });
  } finally {
     isSavingSettings.value = false;
  }
}
</script>

<style scoped lang="scss">
/* Bordas e Sombras */
.border-thin { border: 1px solid rgba(0,0,0,0.08) !important; }
.shadow-sm { box-shadow: 0 2px 8px rgba(0,0,0,0.06) !important; }
.bg-white { background-color: #ffffff; }
.bg-grey-darken-4 { background-color: #212121; }
.bg-grey-darken-3 { background-color: #424242; }

/* Tipografia */
.tracking-widest { letter-spacing: 0.05em; }
.lh-1 { line-height: 1.1; }

/* Scrollbars Modernas */
.custom-scroll { scrollbar-gutter: stable; }
.custom-scroll::-webkit-scrollbar { width: 6px; height: 6px; }
.custom-scroll::-webkit-scrollbar-track { background: transparent; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128, 0.3); border-radius: 4px; }

/* Animações e Cards */
.transition-all { transition: all 0.3s ease; }
.hover-card { transition: transform 0.2s ease, box-shadow 0.2s ease; }
.hover-card:hover { transform: translateY(-2px); box-shadow: 0 8px 24px rgba(0,0,0,0.1) !important; }

/* Utilitários Visuais Específicos */
.border-dashed { border-style: dashed !important; }
.border-white-10 { border-color: rgba(255, 255, 255, 0.1) !important; }
.border-s { border-left: 1px solid rgba(128, 128, 128, 0.2) !important; }
.border-t { border-top: 1px solid rgba(128, 128, 128, 0.2) !important; }

.ui-field :deep(.v-field) { border-radius: 4px !important; }

/* Botões 3D e Chips */
.btn-3d {
  border-radius: 4px !important;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1), inset 0 1px 0 rgba(255,255,255,0.2) !important;
  transition: transform 0.1s ease, box-shadow 0.1s ease;
  text-transform: none !important;
}
.btn-3d:active {
  transform: translateY(2px);
  box-shadow: 0 1px 2px rgba(0,0,0,0.1), inset 0 1px 0 rgba(255,255,255,0.1) !important;
}
.chip-3d {
  box-shadow: 0 2px 4px rgba(0,0,0,0.1), inset 0 1px 0 rgba(255,255,255,0.2) !important;
  border-radius: 4px !important;
}
</style>
