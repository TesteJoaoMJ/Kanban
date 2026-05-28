<template>
  <div class="d-flex flex-column flex-grow-1 overflow-hidden h-100 pa-6">

    <div class="flex-shrink-0 mb-5 d-flex justify-space-between align-center">
      <div>
        <h3 class="text-h6 font-weight-black text-uppercase tracking-widest text-primary d-flex align-center gap-2">
          <v-icon>mdi-cash-register</v-icon> Prévia Analítica de Folha
        </h3>
        <p class="text-caption font-weight-bold opacity-70 mt-1" style="max-width: 800px;">
          Simulação automática projetada com base no <strong>Salário Base</strong> do cadastro cruzado com as horas extras do <strong>Espelho de Ponto</strong>.
        </p>
      </div>
    </div>

    <v-alert
      v-if="payrollSummary.baseSalary === 0"
      type="warning"
      variant="tonal"
      class="mb-6 border-warning font-weight-bold rounded-sm"
      density="comfortable"
      icon="mdi-alert-decagram"
    >
      <div class="d-flex flex-column">
        <span class="text-body-2 font-weight-black text-uppercase tracking-widest mb-1">Salário Base Não Configurado</span>
        <span class="text-caption opacity-80">Este colaborador está com o salário base zerado na tabela de funcionários. Os cálculos automáticos de hora extra e adicionais serão projetados como R$ 0,00 até que o cadastro seja atualizado.</span>
      </div>
    </v-alert>

    <div class="flex-shrink-0 mb-6">
      <v-row class="d-none d-md-flex">
        <v-col cols="12" sm="4">
          <v-tooltip location="bottom" content-class="premium-tooltip">
            <template v-slot:activator="{ props }">
              <v-card
                v-bind="props"
                class="kpi-card kpi-rect bg-gradient-custom hover-elevate py-4 px-5 cursor-help rounded-sm border-thin"
                :class="isLightMode ? 'bg-grey-lighten-5' : 'bg-black-40 border-white-10'"
                elevation="0"
              >
                <div class="kpi-bg-icon"><v-icon>mdi-cash</v-icon></div>
                <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                  <div class="d-flex align-center" style="gap: 8px;">
                    <v-icon size="18" class="opacity-80">mdi-information-outline</v-icon>
                    <span class="text-[10px] font-weight-black text-uppercase opacity-70 tracking-widest">Vencimento Base</span>
                  </div>
                  <div class="kpi-number-group mt-2 mb-1">
                    <span class="text-h4 font-weight-black font-mono text-shadow-sm" :class="isLightMode ? 'text-grey-darken-4' : 'text-white'">{{ currency(payrollSummary.baseSalary) }}</span>
                  </div>
                  <div class="text-[10px] font-weight-bold text-uppercase opacity-60 tracking-widest">Capturado do Cadastro (employees_mj)</div>
                </div>
              </v-card>
            </template>
            <span class="font-weight-bold text-caption">Salário fixo registrado no contrato base do colaborador. Serve de base para divisão do valor da hora-extra.</span>
          </v-tooltip>
        </v-col>

        <v-col cols="12" sm="4">
          <v-tooltip location="bottom" content-class="premium-tooltip">
            <template v-slot:activator="{ props }">
              <v-card
                v-bind="props"
                class="kpi-card kpi-rect bg-gradient-custom hover-elevate py-4 px-5 cursor-help rounded-sm border-thin"
                :class="isLightMode ? 'bg-green-lighten-5 border-green-lighten-3' : 'bg-green-darken-4 bg-opacity-20 border-white-10'"
                elevation="0"
              >
                <div class="kpi-bg-icon"><v-icon color="success">mdi-trending-up</v-icon></div>
                <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                  <div class="d-flex align-center" style="gap: 8px;">
                    <v-icon size="18" class="text-success opacity-80">mdi-information-outline</v-icon>
                    <span class="text-[10px] font-weight-black text-uppercase text-success tracking-widest">Acréscimos Variáveis</span>
                  </div>
                  <div class="kpi-number-group mt-2 mb-1">
                    <span class="text-h4 font-weight-black text-success font-mono text-shadow-sm">+ {{ currency(payrollSummary.overtimeValue + payrollSummary.nightValue + payrollSummary.riskValue) }}</span>
                  </div>
                  <div class="text-[10px] font-weight-bold text-uppercase text-success opacity-80 tracking-widest">Cálculo Automático de Extras</div>
                </div>
              </v-card>
            </template>
            <span class="font-weight-bold text-caption">Soma monetária de Horas Extras (50/100%), Adicional Noturno (20%) e taxas de insalubridade/periculosidade apuradas no Espelho.</span>
          </v-tooltip>
        </v-col>

        <v-col cols="12" sm="4">
          <v-tooltip location="bottom" content-class="premium-tooltip">
            <template v-slot:activator="{ props }">
              <v-card
                v-bind="props"
                class="kpi-card kpi-rect bg-gradient-custom hover-elevate py-4 px-5 cursor-help rounded-sm border-thin"
                :class="isLightMode ? 'bg-blue-lighten-5 border-blue-lighten-3' : 'bg-blue-darken-4 bg-opacity-20 border-white-10'"
                elevation="0"
              >
                <div class="kpi-bg-icon"><v-icon color="primary">mdi-sigma</v-icon></div>
                <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                  <div class="d-flex align-center" style="gap: 8px;">
                    <v-icon size="18" class="text-primary opacity-80">mdi-information-outline</v-icon>
                    <span class="text-[10px] font-weight-black text-uppercase text-primary tracking-widest">Salário Bruto Estimado</span>
                  </div>
                  <div class="kpi-number-group mt-2 mb-1">
                    <span class="text-h4 font-weight-black text-primary font-mono text-shadow-sm">{{ currency(payrollSummary.grossValue) }}</span>
                  </div>
                  <div class="text-[10px] font-weight-bold text-uppercase text-primary opacity-80 tracking-widest">Projeção Base + Variáveis</div>
                </div>
              </v-card>
            </template>
            <span class="font-weight-bold text-caption">Montante Bruto = (Salário Base) + (Acréscimos Variáveis) + (Proventos Manuais Avulsos).</span>
          </v-tooltip>
        </v-col>
      </v-row>
    </div>

    <v-row class="flex-grow-1 ma-0 overflow-hidden" align="stretch">

      <v-col cols="12" lg="8" class="pa-0 pr-lg-6 d-flex flex-column h-100 pb-2">

          <div class="d-flex align-center justify-space-between mb-3 pl-1">
            <span class="text-caption font-weight-black text-uppercase opacity-70 tracking-widest">
               <v-icon start size="small">mdi-format-list-bulleted-type</v-icon>Extrato de Lançamentos
            </span>
            <v-chip size="x-small" variant="tonal" color="primary" class="font-weight-bold chip-3d tracking-widest text-uppercase rounded-sm px-3">
               {{ payrollRows.length }} Eventos Registrados
            </v-chip>
          </div>

          <div class="flex-grow-1 overflow-hidden d-flex flex-column transition-all grid-container-medium">
            <v-card
              class="flex-grow-1 d-flex flex-column rounded-sm border-thin overflow-hidden relative"
              :class="isLightMode ? 'bg-white shadow-sm' : 'bg-transparent border-white-05'"
              :elevation="0"
            >
              <div class="grid-scroll flex-grow-1 overflow-auto custom-scroll relative">

                <div
                  class="grid-header sticky-head"
                  :class="[isLightMode ? 'grid-surface-light border-b border-grey-lighten-2' : 'grid-surface-dark border-bottom-white-05']"
                  style="grid-template-columns: minmax(180px, 2fr) 120px 140px 140px 150px 60px;"
                >
                  <div class="cell header-text pl-4 border-r-thick">Rubrica Operacional</div>
                  <div class="cell center header-text border-r-thick">Natureza</div>
                  <div class="cell center header-text">Base Parâm.</div>
                  <div class="cell center header-text border-r-thick">Montante</div>
                  <div class="cell center header-text">Origem</div>
                  <div class="cell center header-text">Ação</div>
                </div>

                <div v-if="payrollRows.length === 0" class="d-flex flex-column justify-center align-center h-100 opacity-40 py-12">
                  <v-icon size="40" class="mb-3">mdi-receipt-text-remove-outline</v-icon>
                  <span class="text-caption font-weight-black tracking-widest text-uppercase">Nenhuma rubrica processada.</span>
                </div>

                <div
                  v-else
                  v-for="(evt, idx) in payrollRows"
                  :key="evt.id || idx"
                  class="grid-row hover-bg-row transition-all"
                  :class="[isLightMode ? 'grid-row-light' : 'grid-row-dark', zebraClass(idx)]"
                  style="grid-template-columns: minmax(180px, 2fr) 120px 140px 140px 150px 60px;"
                >
                  <div class="cell pl-4 border-r-thick">
                    <span class="font-weight-black text-[12px] text-truncate w-100" :class="isLightMode ? 'text-grey-darken-4' : 'text-white'" :title="evt.title">
                      {{ evt.title }}
                    </span>
                  </div>

                  <div class="cell center border-r-thick">
                     <v-chip size="x-small" :color="evt.category === 'Provento' ? 'success' : (evt.category === 'Desconto' ? 'error' : 'info')" variant="tonal" class="font-weight-black text-uppercase chip-3d px-2 tracking-widest rounded-sm w-100 justify-center">
                        {{ evt.category }}
                     </v-chip>
                  </div>

                  <div class="cell center">
                    <span class="text-[11px] font-mono opacity-80 font-weight-bold text-truncate" :title="evt.reference">{{ evt.reference }}</span>
                  </div>

                  <div class="cell center border-r-thick">
                     <span class="font-weight-black text-[13px] font-mono" :class="evt.category === 'Desconto' ? 'text-error' : (isLightMode ? 'text-grey-darken-4' : 'text-white')">
                        {{ evt.category === 'Desconto' ? '- ' : '' }}{{ currency(evt.amount) }}
                     </span>
                  </div>

                  <div class="cell center">
                    <span class="text-[10px] font-weight-black text-uppercase tracking-widest opacity-80 d-flex align-center gap-1" :class="evt.automatic ? 'text-primary' : 'text-deep-purple'">
                       <v-icon size="14">{{ evt.automatic ? 'mdi-robot-outline' : 'mdi-hand-back-right-outline' }}</v-icon>
                       {{ evt.automatic ? 'Automático' : 'Avulso' }}
                    </span>
                  </div>

                  <div class="cell center">
                    <v-btn v-if="!evt.automatic" icon="mdi-delete" variant="tonal" color="error" class="btn-3d rounded-sm" size="x-small" @click="deletePayrollEvent(evt.id)"></v-btn>
                    <v-icon v-else size="18" class="opacity-20">mdi-lock-outline</v-icon>
                  </div>
                </div>

              </div>
            </v-card>
          </div>
      </v-col>

      <v-col cols="12" lg="4" class="pa-0 pl-lg-2 pb-2 h-100">
        <div class="pa-6 rounded-sm border-thin h-100 d-flex flex-column shadow-sm relative overflow-hidden" :class="isLightMode ? 'bg-white' : 'bg-black-40 border-white-10 backdrop-blur-md'">

          <v-icon size="180" class="position-absolute opacity-05 text-deep-purple" style="top: -20px; right: -20px; pointer-events: none; transform: rotate(15deg);">mdi-playlist-plus</v-icon>

          <div class="text-subtitle-1 font-weight-black mb-2 text-deep-purple d-flex align-center gap-2 text-uppercase tracking-widest position-relative z-10">
            <v-icon>mdi-playlist-edit</v-icon> Lançamento Avulso
          </div>
          <div class="text-caption opacity-70 font-weight-bold mb-6 position-relative z-10">
            Use este painel para registrar bonificações, prêmios, comissões, adiantamentos ou descontos (ex: vales) de forma pontual neste mês.
          </div>

          <div class="d-flex flex-column gap-5 position-relative z-10">

             <div>
               <label class="text-[10px] font-weight-black text-uppercase opacity-70 tracking-widest mb-1 d-block">Descrição do Evento</label>
               <v-text-field
                 v-model="newPayrollEvent.title"
                 placeholder="Ex: Adiantamento Salarial"
                 variant="outlined"
                 density="comfortable"
                 hide-details
                 color="deep-purple"
                 class="ui-field font-weight-bold"
                 :bg-color="isLightMode ? 'bg-grey-lighten-5' : 'rgba(0,0,0,0.4)'"
               ></v-text-field>
             </div>

             <div>
               <label class="text-[10px] font-weight-black text-uppercase opacity-70 tracking-widest mb-1 d-block">Tipo de Movimentação</label>
               <v-select
                 v-model="newPayrollEvent.category"
                 :items="['Provento', 'Desconto', 'Informativo']"
                 variant="outlined"
                 density="comfortable"
                 hide-details
                 color="deep-purple"
                 class="ui-field font-weight-bold custom-dark-select"
                 :bg-color="isLightMode ? 'bg-grey-lighten-5' : 'rgba(0,0,0,0.4)'"
                 :menu-props="{ theme: isLightMode ? 'light' : 'dark', contentClass: isLightMode ? 'rounded-sm mt-1' : 'dark-dropdown-menu border border-white-10 rounded-sm mt-1' }"
               >
                  <template #selection="{ item }">
                     <div class="d-flex align-center gap-2">
                        <v-icon size="16" :color="item.value === 'Provento' ? 'success' : (item.value === 'Desconto' ? 'error' : 'info')">
                          {{ item.value === 'Provento' ? 'mdi-plus-circle' : (item.value === 'Desconto' ? 'mdi-minus-circle' : 'mdi-information') }}
                        </v-icon>
                        {{ item.title }}
                     </div>
                  </template>
               </v-select>
             </div>

             <v-row dense>
               <v-col cols="6">
                 <div>
                   <label class="text-[10px] font-weight-black text-uppercase opacity-70 tracking-widest mb-1 d-block">Montante (R$)</label>
                   <v-text-field
                     v-model.number="newPayrollEvent.amount"
                     type="number"
                     placeholder="0.00"
                     variant="outlined"
                     density="comfortable"
                     hide-details
                     color="deep-purple"
                     class="ui-field font-weight-black font-mono text-deep-purple"
                     :bg-color="isLightMode ? 'bg-grey-lighten-5' : 'rgba(0,0,0,0.4)'"
                   ></v-text-field>
                 </div>
               </v-col>
               <v-col cols="6">
                 <div>
                   <label class="text-[10px] font-weight-black text-uppercase opacity-70 tracking-widest mb-1 d-block">Ref / Base</label>
                   <v-text-field
                     v-model="newPayrollEvent.reference"
                     placeholder="Ex: 1 Vale"
                     variant="outlined"
                     density="comfortable"
                     hide-details
                     color="deep-purple"
                     class="ui-field font-weight-bold"
                     :bg-color="isLightMode ? 'bg-grey-lighten-5' : 'rgba(0,0,0,0.4)'"
                   ></v-text-field>
                 </div>
               </v-col>
             </v-row>

          </div>

          <v-spacer></v-spacer>
          <v-btn
            variant="flat"
            color="deep-purple"
            size="large"
            class="btn-3d font-weight-black mt-8 w-100 tracking-widest rounded-sm position-relative z-10"
            @click="savePayrollEvent"
            :loading="savingPayroll"
          >
            <v-icon start>mdi-plus-box</v-icon> INJETAR NA FOLHA
          </v-btn>
        </div>
      </v-col>
    </v-row>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed } from 'vue';
import { storeToRefs } from 'pinia';
import { supabase } from '@/api/supabase';
import { useThemeStore } from '@/stores/theme';
import { useTimeTrackingStore } from '@/stores/timeTracking';

const emit = defineEmits(['show-toast']);

// --- STORES ---
const themeStore = useThemeStore();
const timeStore = useTimeTrackingStore();
const isLightMode = computed(() => themeStore.currentMode === 'light');

const {
  selectedEmployeeId,
  payrollSummary,
  payrollRows
} = storeToRefs(timeStore);

// --- ESTADOS LOCAIS ---
const savingPayroll = ref(false);
const newPayrollEvent = reactive({
  title: '',
  category: 'Provento',
  reference: '1',
  amount: null as number | null
});

// --- UTILITÁRIOS ---
const currency = (v: number) => new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(v);
const zebraClass = (index: number) => isLightMode.value ? (index % 2 === 0 ? 'zebra-light-a' : 'zebra-light-b') : (index % 2 === 0 ? 'zebra-dark-a' : 'zebra-dark-b');

// --- MÉTODOS DE FOLHA DE PAGAMENTO ---
async function savePayrollEvent() {
  if (!selectedEmployeeId.value || !newPayrollEvent.title || !newPayrollEvent.amount) {
    emit('show-toast', { message: 'Preencha a descrição e o valor.', color: 'warning' });
    return;
  }

  savingPayroll.value = true;
  try {
    const { error } = await supabase.from('time_tracking_payroll_events').insert({
      employee_id: selectedEmployeeId.value,
      ...newPayrollEvent
    });

    if (error) throw error;

    // Reseta form
    newPayrollEvent.title = '';
    newPayrollEvent.amount = null;
    newPayrollEvent.reference = '1';

    // Atualiza base na store
    emit('show-toast', { message: 'Lançamento manual gravado no holerite.', color: 'success' });
    await timeStore.fetchMonthDynamicData();
  } catch(e: any) {
    emit('show-toast', { message: 'Erro ao cravar lançamento: ' + e.message, color: 'error' });
  } finally {
    savingPayroll.value = false;
  }
}

async function deletePayrollEvent(id: string) {
  if(!confirm("Remover este lançamento manual da folha?")) return;

  try {
    await supabase.from('time_tracking_payroll_events').delete().eq('id', id);
    emit('show-toast', { message: 'Lançamento extornado com sucesso.', color: 'success' });
    await timeStore.fetchMonthDynamicData();
  } catch(e) {
    emit('show-toast', { message: 'Falha ao extornar rubrica.', color: 'error' });
  }
}
</script>

<style lang="scss">
/* Força as opções de tema escuro nos menus */
.dark-dropdown-menu {
  background-color: #1a1a20 !important;
  color: #ffffff !important;
}
.dark-dropdown-menu .v-list {
  background-color: transparent !important;
  color: #ffffff !important;
}
.dark-dropdown-menu .v-list-item:hover {
  background-color: rgba(255, 255, 255, 0.08) !important;
}
</style>

<style scoped lang="scss">
/* Tooltips Premium */
:deep(.premium-tooltip) {
  background: rgba(18, 18, 22, 0.95) !important;
  border: 1px solid rgba(255, 255, 255, 0.15) !important;
  backdrop-filter: blur(10px);
  box-shadow: 0 8px 24px rgba(0,0,0,0.5) !important;
  color: white !important;
  border-radius: 6px;
  padding: 8px 12px;
  max-width: 300px;
  text-align: center;
}

/* Bordas e Sombras Gerais */
.border-thin { border: 1px solid rgba(128,128,128,0.15) !important; }
.shadow-sm { box-shadow: 0 2px 8px rgba(0,0,0,0.06) !important; }
.bg-white { background-color: #ffffff; }

/* Tipografia */
.tracking-widest { letter-spacing: 0.05em; }
.tracking-tighter { letter-spacing: -0.05em; }
.text-shadow-sm { text-shadow: 0 2px 4px rgba(0,0,0,0.3); }

/* Animações e Cards */
.transition-all { transition: all 0.2s ease; }
.hover-elevate { transition: transform 0.2s ease, box-shadow 0.2s ease; }
.hover-elevate:hover { transform: translateY(-3px); box-shadow: 0 12px 24px rgba(0,0,0,0.15) !important; }

/* === DARK MODE & GLASSMORPHISM === */
.bg-black-40 { background-color: rgba(0, 0, 0, 0.4) !important; }
.border-white-10 { border-color: rgba(255,255,255,0.1) !important; }
.border-white-05 { border-color: rgba(255,255,255,0.05) !important; }
.border-bottom-white-05 { border-bottom: 1px solid rgba(255,255,255,0.08); }
.opacity-05 { opacity: 0.05; }
.backdrop-blur-md { backdrop-filter: blur(16px); -webkit-backdrop-filter: blur(16px); }

/* === GRID LAYOUT FLUIDO === */
.grid-scroll { scrollbar-gutter: stable; -webkit-overflow-scrolling: touch; }
.custom-scroll::-webkit-scrollbar { width: 6px; height: 6px; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.35); border-radius: 4px; }
.custom-scroll::-webkit-scrollbar-track { background: transparent; }

.grid-header, .grid-row {
    display: grid;
    align-items: stretch;
    width: 100%;
}

.cell {
    padding: 8px 12px;
    display: flex;
    align-items: center;
    border-right: 1px solid rgba(128,128,128,0.08);
    border-bottom: 1px solid rgba(128,128,128,0.08);
    min-height: 48px;
    overflow: hidden;
    transition: background-color 0.2s ease;
}

.border-r-thick { border-right: 2px solid rgba(128,128,128,0.15) !important; }
.header-text { font-weight: 900; text-transform: uppercase; font-size: 10px !important; letter-spacing: 0.05em; }
.center { justify-content: center; text-align: center; }

.grid-header .cell { min-height: 44px; opacity: 0.9; }

.sticky-head { position: sticky; top: 0; z-index: 20; box-shadow: 0 8px 16px -4px rgba(0, 0, 0, 0.08); }
.grid-surface-dark .sticky-head { box-shadow: 0 8px 20px -4px rgba(0, 0, 0, 0.5); }

/* Cores e Zebras */
.grid-surface-light .cell { background: #f5f7fa; color: rgba(0,0,0,0.9); border-color: rgba(0,0,0,0.08) !important; }
.grid-row-light .cell { border-color: rgba(0,0,0,0.05) !important; }
.zebra-light-a .cell { background: #ffffff; }
.zebra-light-b .cell { background: #f9fbfc; }
.grid-row-light:hover .cell { background: #f1f5f9 !important; }

.grid-surface-dark .cell {
  background: rgba(20,20,25,0.9) !important;
  color: rgba(255,255,255,0.85) !important;
  border-color: rgba(255,255,255,0.05) !important;
}
.grid-row-dark .cell {
  background: transparent;
  border-color: rgba(255,255,255,0.05) !important;
  color: rgba(255,255,255,0.9);
}
.zebra-dark-a .cell { background: rgba(255,255,255,0.02) !important; }
.zebra-dark-b .cell { background: transparent !important; }
.grid-row-dark:hover .cell { background: rgba(255,255,255,0.06) !important; }

/* === COMPONENTES VISUAIS (CHIPS E PILLS) === */
.chip-3d { border-radius: 4px !important; box-shadow: 0 2px 4px rgba(0,0,0,0.15), inset 0 1px 0 rgba(255,255,255,0.2) !important; text-shadow: 0 1px 2px rgba(0,0,0,0.3); }

/* === KPI CARDS DESKTOP === */
.kpi-card { color: white; position: relative; min-height: 100px; overflow: hidden; }
.kpi-bg-icon { position: absolute; right: -15px; bottom: -15px; opacity: 0.12; transform: rotate(-15deg); }
.kpi-bg-icon .v-icon { font-size: 90px; color: white; }

.bg-gradient-info { background: linear-gradient(135deg, #0288d1, #005b9f); }
.bg-gradient-green { background: linear-gradient(135deg, #2e7d32, #1b5e20); }
.bg-gradient-purple { background: linear-gradient(135deg, #7b1fa2, #4a148c); }

/* UTILITÁRIOS FORMS E BOTÕES */
.rounded-sm { border-radius: 4px !important; }
.ui-field :deep(.v-field) { border-radius: 4px !important; }
.d-block { display: block; }

.btn-3d {
  border-radius: 4px !important;
  box-shadow: 0 3px 5px rgba(0,0,0,0.15), inset 0 2px 0 rgba(255,255,255,0.25) !important;
  transition: transform 0.1s ease, box-shadow 0.1s ease;
  text-transform: none !important;
}
.btn-3d:active {
  transform: translateY(2px);
  box-shadow: 0 1px 2px rgba(0,0,0,0.15), inset 0 1px 0 rgba(255,255,255,0.1) !important;
}
</style>
