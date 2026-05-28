<template>
  <div class="d-flex flex-column flex-grow-1 overflow-hidden">

    <div class="px-4 px-md-6 py-4 flex-shrink-0">
      <v-row class="d-none d-md-flex">
        <v-col cols="12" sm="4" v-for="(kpi, idx) in kpiList" :key="idx">
          <v-card
            class="kpi-card kpi-rect bg-gradient-custom hover-elevate py-4 px-5 cursor-default"
            :class="[kpi.gradient]"
            elevation="3"
          >
            <div class="kpi-bg-icon"><v-icon>{{ kpi.icon }}</v-icon></div>
            <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
              <div class="d-flex align-center" style="gap: 10px;">
                <v-icon size="20" class="opacity-80">{{ kpi.icon }}</v-icon>
                <span class="kpi-label text-uppercase tracking-widest">{{ kpi.label }}</span>
              </div>
              <div class="kpi-number-group mt-2 mb-1">
                <span class="text-h3 font-weight-black font-mono text-shadow-sm">{{ kpi.value }}</span>
              </div>
              <div class="kpi-footer opacity-80 font-weight-bold text-uppercase tracking-wide">{{ kpi.footer }}</div>
            </div>
          </v-card>
        </v-col>
      </v-row>

      <div class="d-block d-md-none kpi-mobile-wrapper my-2">
        <v-window v-model="kpiModel" show-arrows class="elevation-4 rounded-xl overflow-hidden shadow-lg">
           <template v-slot:prev="{ props }">
             <v-btn variant="flat" icon="mdi-chevron-left" @click="props.onClick" color="rgba(0,0,0,0.3)" size="small" class="text-white backdrop-blur-sm"></v-btn>
           </template>
           <template v-slot:next="{ props }">
             <v-btn variant="flat" icon="mdi-chevron-right" @click="props.onClick" color="rgba(0,0,0,0.3)" size="small" class="text-white backdrop-blur-sm"></v-btn>
           </template>

           <v-window-item v-for="(kpi, idx) in kpiList" :key="idx">
              <v-card
                  class="kpi-card-mobile d-flex flex-column align-center justify-center py-6 px-4 text-center relative"
                  :class="[kpi.gradient]"
                  height="140"
                  elevation="0"
              >
                  <div class="kpi-bg-icon-mobile"><v-icon>{{ kpi.icon }}</v-icon></div>
                  <div class="d-flex flex-column align-center relative z-10 w-100">
                      <div class="d-flex align-center justify-center mb-1 bg-white-20 px-3 py-1 rounded-pill backdrop-blur-sm" style="max-width: 80%;">
                          <v-icon size="16" class="mr-2 text-white">{{ kpi.icon }}</v-icon>
                          <span class="text-caption font-weight-black text-uppercase text-white tracking-wide text-truncate">{{ kpi.label }}</span>
                      </div>
                      <div class="text-h3 font-weight-black text-white my-2 text-shadow-sm font-mono">
                         {{ kpi.value }}
                      </div>
                      <div class="text-caption text-white font-weight-medium opacity-90">{{ kpi.footer }}</div>
                  </div>
              </v-card>
           </v-window-item>
        </v-window>
        <div class="d-flex justify-center mt-3 gap-2">
            <div
              v-for="(k, i) in kpiList"
              :key="i"
              class="kpi-dot transition-all rounded-circle cursor-pointer"
              :class="kpiModel === i ? 'bg-success w-3 h-3 elevation-2' : 'bg-grey-lighten-2 w-2 h-2 opacity-50'"
              @click="kpiModel = i"
            ></div>
        </div>
      </div>
    </div>

    <div class="flex-grow-1 overflow-hidden d-flex flex-column px-4 px-md-6 pb-6 transition-all grid-container-medium">
      <v-card
        class="flex-grow-1 d-flex flex-column rounded-xl border-thin overflow-hidden relative"
        :class="isLightMode ? 'bg-white shadow-sm' : 'bg-transparent border-white-05'"
        :elevation="0"
      >
        <div class="grid-scroll flex-grow-1 overflow-auto custom-scroll relative">

          <div
            class="grid-header sticky-head"
            :class="[isLightMode ? 'grid-surface-light border-b border-grey-lighten-2' : 'grid-surface-dark border-bottom-white-05']"
            style="grid-template-columns: minmax(260px, 2fr) 90px 90px 90px 90px 90px 90px minmax(130px, 1fr);"
          >
            <div class="cell header-text pl-6 border-r-thick">Colaborador</div>
            <div class="cell center header-text text-teal-darken-2">Ent. Prev</div>
            <div class="cell center header-text text-teal-darken-2 border-r-thick">Saí. Prev</div>
            <div class="cell center header-text text-primary">Entrada 1</div>
            <div class="cell center header-text text-warning">Saída 1</div>
            <div class="cell center header-text text-primary">Entrada 2</div>
            <div class="cell center header-text text-warning border-r-thick">Saída 2</div>
            <div class="cell center header-text pr-6">Status Operacional</div>
          </div>

          <div v-if="globalTodayList.length === 0" class="d-flex flex-column justify-center align-center h-100 opacity-60 gap-2 py-10 min-w-full">
            <v-icon size="48" color="grey-lighten-1">mdi-account-search-outline</v-icon>
            <span class="text-body-2 font-weight-medium text-grey tracking-widest text-uppercase mt-2">Nenhum registro encontrado para hoje.</span>
          </div>

          <div
            v-else
            v-for="(emp, idx) in paginatedList"
            :key="emp.id"
            class="grid-row hover-bg-row cursor-pointer transition-all"
            :class="[isLightMode ? 'grid-row-light' : 'grid-row-dark', zebraClass(idx)]"
            style="grid-template-columns: minmax(260px, 2fr) 90px 90px 90px 90px 90px 90px minmax(130px, 1fr);"
            @click="selectEmployee(emp.id)"
          >
            <div class="cell pl-6 d-flex align-center gap-4 border-r-thick">
              <v-avatar size="38" class="border-thin shadow-sm flex-shrink-0" :class="isLightMode ? 'bg-white' : 'bg-grey-darken-3'" :image="emp.avatar_url || avatarFor(emp.nome)"></v-avatar>
              <div class="d-flex flex-column overflow-hidden">
                <div class="font-weight-black list-text-11 text-truncate" :class="isLightMode ? 'text-grey-darken-4' : 'text-white'">{{ emp.nome }}</div>
                <div class="text-[10px] font-weight-bold opacity-70 text-uppercase tracking-widest mt-1 text-truncate">{{ emp.cargo || emp.role || 'Sem cargo' }}</div>
              </div>
            </div>

            <div class="cell center bg-opacity-sutil">
              <span class="font-mono text-caption font-weight-bold" :class="isLightMode ? 'text-teal-darken-3' : 'text-teal-lighten-2'">
                {{ getExpectedTime(emp.shiftLabel, 0) }}
              </span>
            </div>
            <div class="cell center border-r-thick bg-opacity-sutil">
              <span class="font-mono text-caption font-weight-bold" :class="isLightMode ? 'text-teal-darken-3' : 'text-teal-lighten-2'">
                {{ getExpectedTime(emp.shiftLabel, 1) }}
              </span>
            </div>

            <div class="cell center font-mono text-body-2 font-weight-black" :class="emp.punches[0] ? 'text-primary' : 'opacity-20'">
              {{ emp.punches[0] || '--:--' }}
            </div>
            <div class="cell center font-mono text-body-2 font-weight-black" :class="emp.punches[1] ? 'text-warning' : 'opacity-20'">
              {{ emp.punches[1] || '--:--' }}
            </div>
            <div class="cell center font-mono text-body-2 font-weight-black" :class="emp.punches[2] ? 'text-primary' : 'opacity-20'">
              {{ emp.punches[2] || '--:--' }}
            </div>
            <div class="cell center border-r-thick font-mono text-body-2 font-weight-black" :class="emp.punches[3] ? 'text-warning' : 'opacity-20'">
              {{ emp.punches[3] || '--:--' }}
            </div>

            <div class="cell center pr-6">
              <span class="solid-chip chip-status chip-3d" :class="getStatusChipClass(emp.status)">
                {{ emp.status }}
              </span>
            </div>
          </div>

        </div>

        <div class="flex-shrink-0 border-t px-6 py-3 d-flex flex-column flex-md-row align-center justify-space-between z-20"
             :class="isLightMode ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-black-40 border-top-white-05 backdrop-blur-md'">
          <div class="text-caption font-weight-bold opacity-70 mb-2 mb-md-0 text-uppercase tracking-widest">
             <v-icon size="small" class="mr-1">mdi-account-multiple</v-icon>
             Total de <strong :class="isLightMode ? 'text-primary' : 'text-white'">{{ globalTodayList.length }}</strong> registros operacionais
          </div>
          <v-pagination
            v-model="page"
            :length="pageCount"
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
</template>

<script setup lang="ts">
import { computed, ref, watch } from 'vue';
import { useThemeStore } from '@/stores/theme';
import { useTimeTrackingStore } from '@/stores/timeTracking';

// Stores
const themeStore = useThemeStore();
const timeStore = useTimeTrackingStore();

// Computeds Básicos
const isLightMode = computed(() => themeStore.currentMode === 'light');

// Mapeamento dos Dados da Store
const employees = computed(() => timeStore.employees);
const globalTodayStats = computed(() => timeStore.globalTodayStats);
const globalTodayList = computed(() => timeStore.globalTodayList);

// PAGINAÇÃO
const page = ref(1);
const itemsPerPage = 30;

const pageCount = computed(() => Math.ceil(globalTodayList.value.length / itemsPerPage));

const paginatedList = computed(() => {
  const start = (page.value - 1) * itemsPerPage;
  const end = start + itemsPerPage;
  return globalTodayList.value.slice(start, end);
});

// Volta para página 1 se a lista mudar de tamanho ou resetar
watch(() => globalTodayList.value.length, () => {
  page.value = 1;
});

// KPI State
const kpiModel = ref(0);
const kpiList = computed(() => ([
  { label: 'Efetivo Ativo', value: employees.value.length, footer: 'Base Total Cadastrada', icon: 'mdi-account-group', gradient: 'bg-gradient-info' },
  { label: 'Presenças Hoje', value: globalTodayStats.value.present, footer: 'Operação em Andamento', icon: 'mdi-account-check', gradient: 'bg-gradient-green' },
  { label: 'Faltas / Atrasos', value: globalTodayStats.value.missing, footer: 'Atenção Necessária', icon: 'mdi-alert-circle', gradient: 'bg-gradient-red' },
]));

// Utilitários Locais de UI
const getExpectedTime = (shiftLabel: string, index: 0 | 1) => {
  if (!shiftLabel || shiftLabel === 'Folga' || shiftLabel === 'Sem Escala') return '--:--';
  const parts = shiftLabel.split(' as ');
  return parts[index] || '--:--';
};

const zebraClass = (index: number) => {
  return isLightMode.value
    ? (index % 2 === 0 ? 'zebra-light-a' : 'zebra-light-b')
    : (index % 2 === 0 ? 'zebra-dark-a' : 'zebra-dark-b');
};

const getStatusChipClass = (status: string) => {
  if (status === 'Presente' || status === 'Extra / Kiosk') return 'chip-success';
  if (status === 'Atrasado' || status === 'Falta') return 'chip-danger';
  if (status === 'Aguardando') return 'chip-warn';
  return 'bg-grey text-white'; // Sem Escala
};

const avatarFor = (n: string) => {
  if (!n) return '';
  return `https://ui-avatars.com/api/?name=${encodeURIComponent(n)}&background=111&color=fff`;
};

// Ação de Selecionar Funcionaário
const selectEmployee = (id: string) => {
  timeStore.selectedEmployeeId = id;
};
</script>

<style scoped lang="scss">
/* Bordas e Sombras Gerais */
.border-thin { border: 1px solid rgba(0,0,0,0.08) !important; }
.shadow-sm { box-shadow: 0 2px 8px rgba(0,0,0,0.06) !important; }
.bg-white { background-color: #ffffff; }

/* Tipografia */
.tracking-widest { letter-spacing: 0.05em; }
.tracking-wide { letter-spacing: 0.02em; }
.lh-1 { line-height: 1.1; }
.text-shadow-sm { text-shadow: 0 2px 4px rgba(0,0,0,0.3); }

/* Animações e Cards */
.transition-all { transition: all 0.2s ease; }
.hover-elevate { transition: transform 0.2s ease, box-shadow 0.2s ease; }
.hover-elevate:hover { transform: translateY(-3px); box-shadow: 0 12px 24px rgba(0,0,0,0.15) !important; }

/* === DARK MODE & GLASSMORPHISM === */
.bg-glass-dark { background: rgba(10,10,12,0.85); }
.glass-card { background: rgba(24, 24, 28, 0.4) !important; backdrop-filter: blur(24px); border: 1px solid rgba(255,255,255,0.08) !important; }
.border-bottom-white-05 { border-bottom: 1px solid rgba(255,255,255,0.08); }
.border-top-white-05 { border-top: 1px solid rgba(255,255,255,0.08); }
.backdrop-blur-md { backdrop-filter: blur(12px); -webkit-backdrop-filter: blur(12px); }

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
    min-height: 56px;
    overflow: hidden;
    transition: background-color 0.2s ease;
}

.border-r-thick {
  border-right: 2px solid rgba(128,128,128,0.15) !important;
}

.bg-opacity-sutil {
  background: rgba(128, 128, 128, 0.03);
}

.header-text { font-weight: 900; text-transform: uppercase; letter-spacing: 0.5px; line-height: 1.2; font-size: 11px !important; }
.center { justify-content: center; text-align: center; }

.grid-header .cell {
    min-height: 48px;
    opacity: 0.9;
}

.list-text-11 { font-size: 13px; line-height: 1.2 !important; }

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
.zebra-dark-b .cell { background: rgba(255,255,255,0.0) !important; }
.grid-row-dark:hover .cell { background: rgba(255,255,255,0.06) !important; }

/* === COMPONENTES VISUAIS (CHIPS E PILLS) === */
.solid-chip { display: inline-flex; align-items: center; justify-content: center; height: 26px; padding: 0 14px; font-weight: 900; color: #fff; text-transform: uppercase; white-space: nowrap; font-size: 10px; letter-spacing: 0.05em; }
.chip-status { min-width: 90px; }
.chip-success { background: #2e7d32; }
.chip-warn { background: #f57f17; }
.chip-danger { background: #c62828; }

.chip-3d { border-radius: 6px !important; box-shadow: 0 2px 4px rgba(0,0,0,0.15), inset 0 1px 0 rgba(255,255,255,0.2) !important; text-shadow: 0 1px 2px rgba(0,0,0,0.3); }

/* === KPI CARDS DESKTOP & MOBILE === */
.kpi-card { color: white; position: relative; min-height: 120px; overflow: hidden; border-radius: 12px;}
.kpi-bg-icon { position: absolute; right: -15px; bottom: -15px; opacity: 0.15; transform: rotate(-15deg); }
.kpi-bg-icon .v-icon { font-size: 110px; color: white; }
.kpi-bg-icon-mobile { position: absolute; right: -5px; bottom: -5px; opacity: 0.15; transform: rotate(-10deg); }
.kpi-bg-icon-mobile .v-icon { font-size: 60px; color: white; }

.bg-gradient-info { background: linear-gradient(135deg, #0288d1, #005b9f); }
.bg-gradient-green { background: linear-gradient(135deg, #2e7d32, #1b5e20); }
.bg-gradient-red { background: linear-gradient(135deg, #c62828, #8e0000); }

.kpi-label { font-size: 11px; font-weight: 900; letter-spacing: 1px; }
.kpi-value { font-size: 32px; font-weight: 900; }
.kpi-footer { font-size: 10px; opacity: .8; font-weight: 700; }
</style>
