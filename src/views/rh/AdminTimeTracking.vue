<template>
  <div
    class="admin-time-layout font-sans fill-height d-flex flex-column relative overflow-hidden"
    :class="isLightMode ? 'bg-grey-lighten-5 text-grey-darken-4' : 'bg-glass-dark text-white'"
  >
    <div v-if="!isLightMode" class="background-carousel-wrapper">
        <v-carousel cycle height="100%" hide-delimiters :show-arrows="false" interval="15000" class="fill-height">
            <v-carousel-item src="@/assets/1.jpg" cover></v-carousel-item>
            <v-carousel-item src="@/assets/2.jpg" cover></v-carousel-item>
            <v-carousel-item src="@/assets/3.jpg" cover></v-carousel-item>
        </v-carousel>
        <div class="background-overlay"></div>
    </div>

    <div class="content-wrapper d-flex flex-column fill-height z-10 relative">

      <div
        class="header-bar px-4 py-3 px-md-6 py-md-4 d-flex flex-column flex-md-row align-md-start justify-space-between flex-shrink-0"
        :class="isLightMode ? 'bg-white border-b border-grey-lighten-2 shadow-sm' : 'bg-glass-header border-bottom-white-05'"
        style="gap: 16px;"
      >
        <div class="d-flex flex-column" style="max-width: calc(100vw - 32px);">

          <div class="breadcrumb text-caption d-none d-md-flex align-center">
            <span class="opacity-70">Recursos Humanos</span>
            <span class="mx-2 opacity-50">></span>
            <template v-if="!selectedEmployeeResolved">
                <span class="font-weight-bold">Comando Central</span>
            </template>
            <template v-else>
                <span class="opacity-70 cursor-pointer hover-opacity" @click="selectedEmployeeId = null">Comando Central</span>
                <span class="mx-2 opacity-50">></span>
                <span class="font-weight-bold text-primary">{{ selectedEmployeeResolved.nome }}</span>
            </template>
          </div>

          <div class="d-flex align-center gap-3 mt-1">
             <div class="text-h5 font-weight-black tracking-tight leading-none d-flex align-center gap-2" :class="isLightMode ? 'text-grey-darken-4' : 'text-white'">
                <v-icon :color="isLightMode ? 'primary' : 'white'" size="28">{{ selectedEmployeeResolved ? 'mdi-account-details' : 'mdi-earth' }}</v-icon>
                {{ selectedEmployeeResolved ? selectedEmployeeResolved.nome : 'Monitoramento Global' }}
             </div>
             <v-chip v-if="selectedEmployeeResolved" size="small" variant="tonal" color="primary" class="font-weight-bold font-mono chip-3d ml-2">
                 {{ selectedEmployeeResolved.cpf || 'Sem CPF' }}
             </v-chip>
          </div>

          <div class="d-flex align-center gap-3 mt-4 overflow-x-auto hide-scrollbar pb-1 w-100">

             <template v-if="!selectedEmployeeResolved">
                 <v-btn
                    size="small" height="28"
                    :variant="globalTab === 'dashboard' ? 'flat' : 'tonal'"
                    :color="globalTab === 'dashboard' ? 'primary' : 'grey'"
                    class="font-weight-bold btn-3d px-4 rounded-pill flex-shrink-0 text-uppercase"
                    style="font-size: 11px; letter-spacing: 0.5px;"
                    prepend-icon="mdi-monitor-dashboard"
                    @click="globalTab = 'dashboard'"
                 > Operação Hoje </v-btn>

                 <v-btn
                    size="small" height="28"
                    :variant="globalTab === 'kiosks' ? 'flat' : 'tonal'"
                    :color="globalTab === 'kiosks' ? 'deep-purple' : 'grey'"
                    class="font-weight-bold btn-3d px-4 rounded-pill flex-shrink-0 text-uppercase"
                    style="font-size: 11px; letter-spacing: 0.5px;"
                    prepend-icon="mdi-tablet-dashboard"
                    @click="globalTab = 'kiosks'"
                 > Gestão de Totens </v-btn>

                 <v-btn
                    size="small" height="28"
                    :variant="globalTab === 'pdf-reader' ? 'flat' : 'tonal'"
                    :color="globalTab === 'pdf-reader' ? 'orange-darken-3' : 'grey'"
                    class="font-weight-bold btn-3d px-4 rounded-pill flex-shrink-0 text-uppercase"
                    style="font-size: 11px; letter-spacing: 0.5px;"
                    prepend-icon="mdi-file-pdf-box"
                    @click="globalTab = 'pdf-reader'"
                 > Leitor PDF (Ponto) </v-btn>
             </template>

             <template v-else>
                 <v-btn v-for="tab in employeeTabs" :key="tab.value"
                    size="small" height="28"
                    :variant="activeTab === tab.value ? 'flat' : 'tonal'"
                    :color="activeTab === tab.value ? tab.color : 'grey'"
                    class="font-weight-bold btn-3d px-4 rounded-pill flex-shrink-0 text-uppercase"
                    style="font-size: 11px; letter-spacing: 0.5px;"
                    :prepend-icon="tab.icon"
                    @click="activeTab = tab.value"
                 > {{ tab.label }} </v-btn>
             </template>

          </div>
        </div>

        <div class="d-none d-md-flex align-center flex-wrap overflow-x-auto pb-1 pb-md-0 mt-3 mt-md-0 justify-end" style="gap: 12px; flex-shrink: 0;">

          <v-btn
            color="info"
            variant="flat"
            class="btn-3d px-4 font-weight-bold text-caption text-uppercase letter-spacing-1 flex-shrink-0"
            prepend-icon="mdi-help-circle"
            height="40"
            @click="showHelpGuide = true"
          >
            Manual
          </v-btn>

          <div class="search-wrap d-flex align-center flex-grow-1 flex-md-grow-0 transition-all rounded-sm"
               :class="isLightMode ? 'bg-grey-lighten-4 border-grey-lighten-3' : 'bg-black-40 border-white-10'"
               style="width: 320px; height: 40px; border: 1px solid;">

            <v-icon :color="isLightMode ? 'primary' : 'white'" size="20" class="ml-3 mr-1 opacity-70">mdi-account-search</v-icon>

            <v-autocomplete
              v-model="selectedEmployeeId"
              :items="employees"
              item-title="nome"
              item-value="id"
              placeholder="Buscar Colaborador..."
              variant="plain"
              density="compact"
              hide-details
              clearable
              class="premium-autocomplete flex-grow-1 font-weight-bold text-body-2"
              :class="isLightMode ? 'text-grey-darken-4' : 'text-white'"
              :menu-props="{
                theme: isLightMode ? 'light' : 'dark',
                contentClass: isLightMode ? 'premium-dropdown-light shadow-md mt-2 rounded-sm' : 'premium-dropdown-dark shadow-neon-elegant mt-2 rounded-sm',
                transition: 'slide-y-transition'
              }"
            >
              <template #item="{ props, item }">
                <v-list-item
                  v-bind="props"
                  class="premium-list-item mx-2 my-1 rounded-sm transition-all"
                  :class="selectedEmployeeId === item.raw.id ? (isLightMode ? 'bg-blue-lighten-5 border-l-primary' : 'bg-primary-darken-4 border-l-primary') : 'border-l-transparent'"
                >
                  <template #prepend>
                    <v-avatar size="32" class="border-thin shadow-sm mr-3 rounded-sm" :class="isLightMode ? 'bg-white' : 'bg-grey-darken-3'">
                      <v-img :src="item.raw.avatar_url || avatarFor(item.raw.nome)"></v-img>
                    </v-avatar>
                  </template>

                  <div class="d-flex flex-column justify-center py-1">
                     <v-list-item-title class="font-weight-black text-body-2 lh-1" :class="isLightMode ? 'text-grey-darken-4' : 'text-white'">
                       {{ item.raw.nome }}
                     </v-list-item-title>

                     <v-list-item-subtitle class="text-[10px] font-weight-bold text-uppercase tracking-widest mt-1" :class="isLightMode ? 'text-primary' : 'text-primary-lighten-2'">
                       {{ item.raw.cargo || item.raw.role || 'Sem cargo' }}
                     </v-list-item-subtitle>
                  </div>

                  <template #append v-if="selectedEmployeeId === item.raw.id">
                    <v-icon color="primary" size="18">mdi-check</v-icon>
                  </template>
                </v-list-item>
              </template>

              <template #no-data>
                <div class="pa-4 text-center">
                  <v-icon size="28" class="opacity-30 mb-2">mdi-account-off</v-icon>
                  <div class="text-[10px] font-weight-bold opacity-70 text-uppercase tracking-widest">Nenhum resultado</div>
                </div>
              </template>
            </v-autocomplete>
          </div>

          <div class="period-nav d-flex align-center justify-center flex-grow-1 flex-md-grow-0 border-thin transition-all" :class="isLightMode ? 'bg-grey-lighten-4' : 'bg-black-40 border-white-10'">
             <v-icon start size="small" class="mr-2 opacity-50" :color="isLightMode ? 'grey-darken-2' : 'white'">mdi-calendar-month</v-icon>
             <div class="d-flex flex-column justify-center h-100 pr-2">
                <span class="text-[9px] font-weight-black text-uppercase tracking-widest opacity-70 lh-1" style="margin-bottom: -2px;">Competência</span>
                <input
                  type="month"
                  v-model="selectedMonth"
                  class="clean-input font-weight-black text-caption font-mono lh-1"
                  :class="isLightMode ? 'text-primary' : 'text-success-lighten-1'"
                  style="cursor: pointer; width: 110px;"
                >
             </div>
          </div>
        </div>
      </div>

      <div class="flex-grow-1 overflow-hidden d-flex flex-column position-relative transition-all" :class="!isLightMode ? 'pa-4 pa-md-6' : ''">
        <v-card
          class="flex-grow-1 d-flex flex-column overflow-hidden relative"
          :class="isLightMode ? 'bg-transparent' : 'glass-card rounded-xl border-white-05'"
          :elevation="0"
        >
           <template v-if="!selectedEmployeeResolved">
             <GlobalDashboard v-if="globalTab === 'dashboard'" />
             <GlobalKioskManager v-if="globalTab === 'kiosks'" @show-toast="handleToast" />

             <div v-if="globalTab === 'pdf-reader'" class="fill-height d-flex flex-column pa-0 pa-md-6">
                 <v-card class="flex-grow-1 rounded-xl border-thin shadow-sm d-flex flex-column" :class="isLightMode ? 'bg-white' : 'glass-card border-white-05'">
                    <div class="px-6 py-5 border-b d-flex align-center justify-space-between flex-wrap gap-3" :class="isLightMode ? 'bg-grey-lighten-5' : 'bg-black-20 border-white-10'">
                        <div class="d-flex align-center gap-3">
                            <v-icon size="32" color="orange-darken-3">mdi-file-pdf-box</v-icon>
                            <div>
                                <div class="text-h6 font-weight-black">Importador Inteligente de Folha de Ponto</div>
                                <div class="text-caption opacity-80 font-weight-medium">Faça upload dos PDFs para mapeamento, visualização e sincronização com o banco de dados.</div>
                            </div>
                        </div>
                        <v-btn v-if="pdfState.parsedResults.length > 0" color="error" variant="text" size="small" class="font-weight-bold" @click="resetPdfState">Limpar Resultados</v-btn>
                    </div>

                    <div class="pa-6 flex-grow-1 d-flex flex-column align-center justify-center custom-scroll" style="overflow-y: auto;">
                        <div v-if="pdfState.parsedResults.length === 0" style="max-width: 600px; width: 100%;" class="text-center">
                            <v-icon size="64" color="orange-lighten-3" class="mb-4">mdi-cloud-upload-outline</v-icon>
                            <v-file-input
                                v-model="pdfState.files"
                                multiple
                                accept=".pdf"
                                label="Selecione os PDFs da Folha de Ponto (Lote)"
                                variant="outlined"
                                density="comfortable"
                                prepend-inner-icon="mdi-file-document-multiple-outline"
                                color="orange-darken-3"
                                class="mb-4 ui-field font-weight-bold text-left"
                                chips
                                show-size
                            ></v-file-input>

                            <v-btn
                                block
                                color="orange-darken-3"
                                size="large"
                                class="font-weight-black btn-3d text-white mt-2"
                                @click="processPdfs"
                                :loading="pdfState.processing"
                                :disabled="pdfState.files.length === 0"
                            >
                                <v-icon start>mdi-cog-sync</v-icon> LER DOCUMENTOS E MAPEAR
                            </v-btn>
                        </div>
                    </div>
                </v-card>
             </div>
           </template>

           <template v-else>
             <EmployeeCockpit v-if="activeTab === 'cockpit'" @show-toast="handleToast" />
             <EmployeeShifts v-if="activeTab === 'jornadas'" @show-toast="handleToast" />
             <EmployeeApprovals v-if="activeTab === 'aprovacoes'" @show-toast="handleToast" @change-tab="activeTab = $event" />
             <EmployeePayroll v-if="activeTab === 'folha'" @show-toast="handleToast" />
             <EmployeeBiometrics v-if="activeTab === 'biometria'" @show-toast="handleToast" />
             <EmployeeAudit v-if="activeTab === 'auditoria'" />
           </template>
        </v-card>
      </div>
    </div>

    <v-dialog v-model="pdfState.showModal" max-width="1100" persistent scrollable transition="dialog-bottom-transition">
        <v-card class="rounded-xl border-thin shadow-2xl h-100 d-flex flex-column" :class="isLightMode ? 'bg-grey-lighten-5' : 'bg-grey-darken-4 text-white'">
            <div class="px-6 py-4 border-b d-flex align-center justify-space-between flex-shrink-0" :class="isLightMode ? 'bg-white' : 'bg-grey-darken-3 border-white-10'">
                <div>
                    <div class="font-weight-black text-h6 d-flex align-center gap-2 text-orange-darken-3">
                        <v-icon>mdi-text-box-search-outline</v-icon> Preview de Importação
                    </div>
                    <div class="text-caption font-weight-bold opacity-70 mt-1">
                        {{ pdfState.parsedResults.length }} Documentos lidos. {{ pdfState.parsedResults.filter(r => r.employeeId).length }} Mapeados perfeitamente.
                    </div>
                </div>
                <v-btn icon="mdi-close" variant="text" @click="pdfState.showModal = false" :disabled="pdfState.saving"></v-btn>
            </div>

            <v-card-text class="pa-6 custom-scroll flex-grow-1" style="max-height: 70vh;">
                <v-expansion-panels variant="accordion" class="rounded-lg">
                    <v-expansion-panel
                        v-for="(result, index) in pdfState.parsedResults"
                        :key="index"
                        :class="isLightMode ? 'bg-white mb-2 border-thin' : 'bg-glass-card mb-2 border-white-10'"
                    >
                        <v-expansion-panel-title class="pa-4 font-weight-bold">
                            <div class="d-flex align-center gap-3 w-100 pr-4">
                                <v-icon size="28" :color="result.employeeId ? 'success' : 'error'">
                                    {{ result.employeeId ? 'mdi-account-check' : 'mdi-account-alert' }}
                                </v-icon>
                                <div class="flex-grow-1 overflow-hidden">
                                    <div class="text-subtitle-2 font-weight-black text-truncate" :class="result.employeeId ? (isLightMode ? 'text-grey-darken-4' : 'text-white') : 'text-error'">
                                        {{ result.extractedName || 'Nome não identificado no PDF' }}
                                    </div>
                                    <div class="text-caption opacity-70 text-truncate font-mono">{{ result.fileName }}</div>
                                </div>
                                <div class="text-right d-none d-sm-block flex-shrink-0">
                                    <v-chip size="small" :color="result.employeeId ? 'success' : 'error'" variant="tonal" class="font-weight-black chip-3d">
                                        {{ result.employeeId ? 'Mapeado' : 'Sem Match' }}
                                    </v-chip>
                                    <div class="text-[10px] font-weight-bold mt-1 opacity-70">
                                        {{ result.days.length }} dias | {{ formatMinutesToHours(result.totalMinutes) }}
                                    </div>
                                </div>
                            </div>
                        </v-expansion-panel-title>

                        <v-expansion-panel-text>
                            <div class="pa-4 pt-0">
                                <v-alert v-if="!result.employeeId" type="error" variant="tonal" density="compact" class="mb-4 text-caption font-weight-bold">
                                    O nome do PDF não bateu com ninguém na base. Selecione manualmente o colaborador abaixo para atrelar os horários:
                                </v-alert>

                                <v-autocomplete
                                    v-if="!result.employeeId"
                                    v-model="result.manualEmployeeId"
                                    :items="employees"
                                    item-title="nome"
                                    item-value="id"
                                    label="Vincular a qual Colaborador?"
                                    variant="outlined"
                                    density="comfortable"
                                    color="orange"
                                    class="mb-4 ui-field font-weight-bold"
                                    @update:model-value="(val) => handleManualMatch(result, val)"
                                >
                                    <template v-slot:item="{ props, item }">
                                        <v-list-item v-bind="props" :title="item.raw.nome" :subtitle="item.raw.cpf || item.raw.role"></v-list-item>
                                    </template>
                                </v-autocomplete>

                                <div v-if="result.days.length === 0" class="text-center py-4 opacity-50 font-italic text-caption">
                                    Nenhum registro de ponto (entradas e saídas) legível encontrado neste documento.
                                </div>

                                <div v-else class="border-thin rounded-lg overflow-hidden" :class="isLightMode ? 'bg-grey-lighten-5' : 'bg-black-20'">
                                    <div class="grid-header px-4 py-2 border-b text-caption font-weight-black text-uppercase opacity-70 d-flex" style="gap: 10px;">
                                        <div style="flex: 1;">Data</div>
                                        <div style="flex: 1;" class="text-center">Turno 1 (E/S)</div>
                                        <div style="flex: 1;" class="text-center">Turno 2 (E/S)</div>
                                        <div style="flex: 1;" class="text-right">Total Dia</div>
                                    </div>
                                    <div v-for="(day, dIdx) in result.days" :key="dIdx" class="grid-row px-4 py-2 border-b d-flex text-body-2 font-mono" :class="isLightMode ? 'bg-white hover:bg-grey-lighten-4' : 'bg-transparent hover:bg-white-05'" style="gap: 10px;">
                                        <div style="flex: 1;" class="font-weight-bold">{{ day.date }}</div>
                                        <div style="flex: 1;" class="text-center">{{ day.t1 || '--:--' }} às {{ day.t2 || '--:--' }}</div>
                                        <div style="flex: 1;" class="text-center">{{ day.t3 || '--:--' }} às {{ day.t4 || '--:--' }}</div>
                                        <div style="flex: 1;" class="text-right font-weight-black text-primary">{{ formatMinutesToHours(day.totalMinutes) }}</div>
                                    </div>
                                    <div class="px-4 py-3 text-right font-weight-black text-subtitle-1" :class="isLightMode ? 'bg-grey-lighten-4 text-orange-darken-4' : 'bg-black-40 text-orange-lighten-2'">
                                        Soma: {{ formatMinutesToHours(result.totalMinutes) }}
                                    </div>
                                </div>
                            </div>
                        </v-expansion-panel-text>
                    </v-expansion-panel>
                </v-expansion-panels>
            </v-card-text>

            <div class="pa-5 border-t d-flex justify-space-between align-center flex-shrink-0" :class="isLightMode ? 'bg-white' : 'bg-grey-darken-3 border-white-10'">
                <div class="text-caption font-weight-bold" :class="isLightMode ? 'text-grey-darken-2' : 'text-white-70'">
                    Apenas documentos com "Match" (Verde) serão sincronizados.
                </div>
                <div class="d-flex gap-3">
                    <v-btn variant="outlined" class="btn-3d font-weight-bold" @click="pdfState.showModal = false" height="46" :disabled="pdfState.saving">Cancelar</v-btn>
                    <v-btn color="orange-darken-3" variant="flat" class="btn-3d font-weight-black text-white px-8" @click="saveBatchToDatabase" height="46" :loading="pdfState.saving" :disabled="!hasAnyReadyToSync">
                        <v-icon start>mdi-cloud-sync</v-icon> SINCRONIZAR COM BANCO DE DADOS
                    </v-btn>
                </div>
            </div>
        </v-card>
    </v-dialog>

    <v-dialog v-model="showHelpGuide" max-width="750" :scrim="isLightMode ? 'black opacity-40' : 'black opacity-80'">
       <v-card class="rounded-xl overflow-hidden shadow-2xl transition-all"
               :class="isLightMode ? 'bg-white border-thin' : 'bg-glass-card border-white-10 text-white'">
          <div class="px-6 py-5 border-b d-flex align-center justify-space-between"
               :class="isLightMode ? 'bg-info text-white' : 'bg-black-40 border-white-05'">
             <div class="text-subtitle-1 font-weight-black text-uppercase tracking-widest d-flex align-center gap-3">
               <v-icon size="24">mdi-school-outline</v-icon> Diretrizes Operacionais (RH)
             </div>
             <v-btn icon="mdi-close" variant="text" color="white" @click="showHelpGuide = false"></v-btn>
          </div>
          <div class="pa-6 custom-scroll" style="max-height: 65vh; overflow-y: auto;">
             <v-timeline density="compact" truncate-line="both">
               <v-timeline-item dot-color="primary" size="small">
                  <div class="font-weight-black text-subtitle-2 text-primary text-uppercase tracking-widest mb-1">Painel Tático Central</div>
                  <p class="text-caption opacity-80 font-weight-medium">Visualiza o pulso da fábrica hoje. Faltas, presenças e atrasos processados em tempo real.</p>
               </v-timeline-item>
               <v-timeline-item dot-color="success" size="small">
                  <div class="font-weight-black text-subtitle-2 text-success text-uppercase tracking-widest mb-1">Gestão de Totens (Kiosks)</div>
                  <p class="text-caption opacity-80 font-weight-medium">Vincule em massa quais colaboradores possuem permissão de registrar o ponto em quais equipamentos/filiais.</p>
               </v-timeline-item>
               <v-timeline-item dot-color="orange-darken-3" size="small">
                  <div class="font-weight-black text-subtitle-2 text-orange-darken-3 text-uppercase tracking-widest mb-1">Importação em Lote (PDF)</div>
                  <p class="text-caption opacity-80 font-weight-medium">O algoritmo de Inteligência mapeia nomes e datas nos PDFs do relógio antigo, permite vínculos manuais e gera os turnos automaticamente no banco de dados para retroativos.</p>
               </v-timeline-item>
             </v-timeline>
          </div>
       </v-card>
    </v-dialog>

    <v-snackbar v-model="snackbar.show" :color="snackbar.color" timeout="4000" location="bottom right" rounded="sm" elevation="24">
      <span class="font-weight-bold px-3 text-white font-mono d-flex align-center gap-2">
        <v-icon size="small">mdi-information-variant</v-icon>{{ snackbar.text }}
      </span>
    </v-snackbar>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, reactive, watch } from 'vue';
import { storeToRefs } from 'pinia';
import { format } from 'date-fns';
import { useThemeStore } from '@/stores/theme';
import { useTimeTrackingStore } from '@/stores/timeTracking';
import { supabase } from '@/api/supabase';

// IMPORTAÇÃO DOS COMPONENTES FILHOS
import GlobalDashboard from './admin/GlobalDashboard.vue';
import GlobalKioskManager from './admin/GlobalKioskManager.vue';
import EmployeeCockpit from './admin/EmployeeCockpit.vue';
import EmployeeShifts from './admin/EmployeeShifts.vue';
import EmployeeApprovals from './admin/EmployeeApprovals.vue';
import EmployeePayroll from './admin/EmployeePayroll.vue';
import EmployeeBiometrics from './admin/EmployeeBiometrics.vue';
import EmployeeAudit from './admin/EmployeeAudit.vue';

// STORES
const themeStore = useThemeStore();
const timeStore = useTimeTrackingStore();

const isLightMode = computed(() => themeStore.currentMode === 'light');

// DADOS GLOBAIS DA STORE
const {
  employees,
  selectedEmployeeId,
  selectedMonth,
  selectedEmployeeResolved,
  isLoadingData
} = storeToRefs(timeStore);

// CONTROLES DE UI
const globalTab = ref('dashboard');
const activeTab = ref('cockpit');
const showHelpGuide = ref(false);

const snackbar = reactive({
  show: false,
  text: '',
  color: 'success'
});

// ABAS DO FUNCIONÁRIO
const employeeTabs = [
  { label: 'Espelho', value: 'cockpit', icon: 'mdi-calendar-check', color: 'primary' },
  { label: 'Jornadas', value: 'jornadas', icon: 'mdi-briefcase-clock', color: 'info' },
  { label: 'Tratamentos', value: 'aprovacoes', icon: 'mdi-check-decagram', color: 'warning' },
  { label: 'Folha', value: 'folha', icon: 'mdi-cash-multiple', color: 'success' },
  { label: 'Biometria', value: 'biometria', icon: 'mdi-face-recognition', color: 'deep-purple' },
  { label: 'Auditoria', value: 'auditoria', icon: 'mdi-shield-eye-outline', color: 'red-darken-1' }
];

// UTILITÁRIOS
const avatarFor = (n: string) => {
  if (!n) return '';
  return `https://ui-avatars.com/api/?name=${encodeURIComponent(n)}&background=111&color=fff`;
};

const formatDateSafe = (dStr: string) => {
  if (!dStr) return '-';
  return dStr.split('T')[0].split('-').reverse().join('/');
};

const formatMinutesToHours = (mins: number) => {
    const h = Math.floor(mins / 60);
    const m = mins % 60;
    return `${h}h${m.toString().padStart(2, '0')}m`;
};

const handleToast = (payload: { message: string, color: string }) => {
  snackbar.text = payload.message;
  snackbar.color = payload.color;
  snackbar.show = true;
};

watch(selectedEmployeeId, (newId) => {
  if (newId) {
    activeTab.value = 'cockpit';
    timeStore.fetchMonthDynamicData();
  }
});

// ==========================================
// LÓGICA DO EXTRATOR DE PDF E SYNC BANCO
// ==========================================
interface ParsedDay {
    date: string;
    t1: string | null;
    t2: string | null;
    t3: string | null;
    t4: string | null;
    totalMinutes: number;
}

interface ParsedResult {
    fileName: string;
    extractedName: string;
    employeeId: string | null;
    manualEmployeeId: string | null;
    employeeMatch: any | null;
    days: ParsedDay[];
    totalMinutes: number;
}

const pdfState = reactive({
    files: [] as File[],
    targetDate: '',
    processing: false,
    saving: false,
    showModal: false,
    parsedResults: [] as ParsedResult[]
});

const hasAnyReadyToSync = computed(() => {
    return pdfState.parsedResults.some(r => r.employeeId && r.days.length > 0);
});

const resetPdfState = () => {
    pdfState.files = [];
    pdfState.targetDate = '';
    pdfState.parsedResults = [];
};

// Carregamento dinâmico do pdf.js pelo CDN
const loadPdfJs = async () => {
  if ((window as any).pdfjsLib) return (window as any).pdfjsLib;
  return new Promise((resolve, reject) => {
    const script = document.createElement('script');
    script.src = 'https://cdnjs.cloudflare.com/ajax/libs/pdf.js/2.16.105/pdf.min.js';
    script.onload = () => {
      (window as any).pdfjsLib.GlobalWorkerOptions.workerSrc = 'https://cdnjs.cloudflare.com/ajax/libs/pdf.js/2.16.105/pdf.worker.min.js';
      resolve((window as any).pdfjsLib);
    };
    script.onerror = reject;
    document.head.appendChild(script);
  });
};

const timeToMinutes = (t: string) => {
    if (!t) return 0;
    const [h, m] = t.split(':').map(Number);
    return h * 60 + m;
};

const normalizeName = (name: string) => {
    if (!name) return '';
    return name.normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase().trim();
};

const processPdfs = async () => {
    if (!pdfState.files.length) return;
    pdfState.processing = true;
    pdfState.resultText = 'Iniciando varredura com ordenação matemática de coordenadas...\n';

    try {
        const pdfjs: any = await loadPdfJs();
        let output = "=== RELATÓRIO DE PONTO EXTRAÍDO ===\n\n";

        const targetDateStr = pdfState.targetDate ? formatDateSafe(pdfState.targetDate) : null;
        const targetShort = targetDateStr ? targetDateStr.substring(0, 5) : null;

        for (const file of pdfState.files) {
            const arrayBuffer = await file.arrayBuffer();
            const pdf = await pdfjs.getDocument({ data: arrayBuffer }).promise;

            let fullText = '';
            for (let i = 1; i <= pdf.numPages; i++) {
                const page = await pdf.getPage(i);
                const content = await page.getTextContent();

                content.items.sort((a: any, b: any) => {
                    const yDiff = b.transform[5] - a.transform[5];
                    if (Math.abs(yDiff) > 5) return yDiff;
                    return a.transform[4] - b.transform[4];
                });

                fullText += content.items.map((s: any) => s.str).join(' ') + ' ';
            }

            let textFlat = fullText.replace(/\s+/g, ' ');
            textFlat = textFlat.replace(/(\d{2})\s*:\s*(\d{2})/g, '$1:$2');

            let employeeName = file.name.replace('.pdf', '');
            const nameMatch = textFlat.match(/(?:Nome|Funcion[áa]rio|Empregado)[:\s]*([A-ZÀ-Ÿa-zà-ÿ\s]{5,40})(?=\s|C|$)/i);
            if (nameMatch && nameMatch[1].trim().length > 5) {
                employeeName = nameMatch[1].trim().split(/\s{2,}/)[0];
            }

            const normalizedExtracted = normalizeName(employeeName);
            const matchedEmployee = employees.value.find(e => normalizeName(e.nome) === normalizedExtracted);

            const resultObj: ParsedResult = {
                fileName: file.name,
                extractedName: employeeName,
                employeeId: matchedEmployee ? matchedEmployee.id : null,
                manualEmployeeId: null,
                employeeMatch: matchedEmployee || null,
                days: [],
                totalMinutes: 0
            };

            // REGEX CORRIGIDA: Só aceita Dias (01-31) e Meses (01-12) válidos.
            const dateRegex = /\b(0[1-9]|[12]\d|3[01])\/(0[1-9]|1[0-2])(?:\/\d{2,4})?\b/g;
            const dateMatches = [...textFlat.matchAll(dateRegex)];

            let processedDates = new Set();

            for (const dMatch of dateMatches) {
                const dateStr = dMatch[0]; // Captura a data inteira e higienizada
                if (targetShort && !dateStr.includes(targetShort)) continue;
                if (processedDates.has(dateStr)) continue;

                const substr = textFlat.substring(dMatch.index, dMatch.index + 300);
                // Captura estritamente horas entre 00 e 23 e minutos entre 00 e 59
                let times = [...substr.matchAll(/((?:[01]\d|2[0-3]):[0-5]\d)/g)].map(m => m[1]);
                times = times.filter((item, pos, arr) => pos === 0 || item !== arr[pos-1]);

                if (times.length >= 2) {
                    processedDates.add(dateStr);
                    let dayMins = 0;
                    let t1 = null, t2 = null, t3 = null, t4 = null;

                    if (times.length >= 4) {
                        t1 = times[0]; t2 = times[1]; t3 = times[2]; t4 = times[3];
                        const m1 = timeToMinutes(t1), m2 = timeToMinutes(t2);
                        if (m2 >= m1) dayMins += (m2 - m1);
                        const m3 = timeToMinutes(t3), m4 = timeToMinutes(t4);
                        if (m4 >= m3) dayMins += (m4 - m3);
                    }
                    else if (times.length === 3) {
                         t1 = times[0]; t2 = times[1]; t3 = times[2];
                         const m1 = timeToMinutes(t1), m2 = timeToMinutes(t2);
                         if (m2 >= m1) dayMins += (m2 - m1);
                    }
                    else {
                        t1 = times[0]; t2 = times[times.length - 1];
                        const m1 = timeToMinutes(t1), m2 = timeToMinutes(t2);
                        if (m2 >= m1) dayMins += (m2 - m1);
                    }

                    resultObj.totalMinutes += dayMins;

                    let finalDateStr = dateStr;
                    if (finalDateStr.length === 5) finalDateStr += `/${new Date().getFullYear()}`;

                    resultObj.days.push({
                        date: finalDateStr,
                        t1, t2, t3, t4,
                        totalMinutes: dayMins
                    });
                }
            }

            pdfState.parsedResults.push(resultObj);
        }

        pdfState.showModal = true;
    } catch (e) {
        console.error(e);
        handleToast({ message: 'Erro crítico na leitura dos PDFs.', color: 'error' });
    } finally {
        pdfState.processing = false;
    }
};

const handleManualMatch = (result: ParsedResult, employeeId: string | null) => {
    if (employeeId) {
        const emp = employees.value.find(e => e.id === employeeId);
        result.employeeId = employeeId;
        result.employeeMatch = emp || null;
    } else {
        result.employeeId = null;
        result.employeeMatch = null;
    }
};

const saveBatchToDatabase = async () => {
    const validResults = pdfState.parsedResults.filter(r => r.employeeId && r.days.length > 0);
    if (!validResults.length) return handleToast({ message: 'Nenhum dado com Match ou dias válidos para salvar.', color: 'warning' });

    pdfState.saving = true;
    try {
        // Usamos um Map para evitar que o array tenha registros duplicados para o mesmo Funcionario + Data
        const payloadsMap = new Map();

        const cleanTime = (timeStr) => {
            if (!timeStr) return null;
            const [h, m] = timeStr.split(':').map(Number);
            if (h >= 0 && h <= 23 && m >= 0 && m <= 59) return timeStr;
            return null; // Mata qualquer lixo que passar
        };

        for (const res of validResults) {
            for (const day of res.days) {
                const [d, m, y] = day.date.split('/');

                // PROTEÇÃO FINAL CONTRA LIXO DO PDF
                if (!y || !m || !d || Number(m) < 1 || Number(m) > 12 || Number(d) < 1 || Number(d) > 31) {
                    console.warn(`Data inválida detectada e ignorada: ${day.date}`);
                    continue;
                }

                const isoDate = `${y}-${m}-${d}`;

                // Cria uma chave única baseada no ID do Funcionario e na Data
                const uniqueKey = `${res.employeeId}_${isoDate}`;

                // O Map garante que, se a chave já existir neste lote, ele substitui pela última leitura válida
                  payloadsMap.set(uniqueKey, {
                    employee_id: res.employeeId,
                    date: isoDate,
                    in1: cleanTime(day.t1),
                    out1: cleanTime(day.t2),
                    in2: cleanTime(day.t3),
                    out2: cleanTime(day.t4),
                    balance_minutes: day.totalMinutes,
                    status: 'Regular'
                });
            }
        }

        // Converte o Map de volta para um Array limpo
        const payloads = Array.from(payloadsMap.values());

        if (payloads.length === 0) {
             pdfState.saving = false;
             return handleToast({ message: 'Nenhuma data válida encontrada para sincronizar.', color: 'warning' });
        }

        // Fazemos Upsert direcionado para a tabela e constraint corretas
        const { error } = await supabase
            .from('time_tracking_logs')
            .upsert(payloads, { onConflict: 'employee_id, date' });

        if (error) throw error;

        handleToast({ message: 'Lote sincronizado com sucesso e retroativos registrados!', color: 'success' });
        pdfState.showModal = false;

        // Recarrega se o funcionário da tela atual foi afetado
        if (selectedEmployeeId.value) {
            timeStore.fetchMonthDynamicData();
        }

    } catch (e: any) {
        console.error(e);
        handleToast({ message: 'Erro ao salvar no banco: ' + e.message, color: 'error' });
    } finally {
        pdfState.saving = false;
    }
};

onMounted(async () => {
  await timeStore.loadAllData();
});
</script>

<style lang="scss">
/* --- AUTOCOMPLETE PREMIUM --- */
.premium-autocomplete :deep(.v-field__input) {
  padding-top: 0 !important;
  padding-bottom: 0 !important;
  min-height: 40px !important;
  font-size: 13px;
}
.premium-autocomplete :deep(.v-field__clearable) { margin-right: 8px; }
.premium-autocomplete :deep(.v-field__outline),
.premium-autocomplete :deep(.v-field__overlay) { display: none !important; }

/* DROPDOWNS GLASSMORPHISM */
:deep(.premium-dropdown-dark) {
  background: rgba(20, 20, 25, 0.85) !important;
  backdrop-filter: blur(24px) !important;
  -webkit-backdrop-filter: blur(24px) !important;
  border: 1px solid rgba(255, 255, 255, 0.1) !important;
  padding: 8px 0;
}
:deep(.premium-dropdown-light) {
  background: rgba(255, 255, 255, 0.95) !important;
  backdrop-filter: blur(24px) !important;
  -webkit-backdrop-filter: blur(24px) !important;
  border: 1px solid rgba(0, 0, 0, 0.08) !important;
  padding: 8px 0;
}

/* ITENS DA LISTA */
:deep(.premium-list-item) {
  min-height: 50px !important;
  border-left: 3px solid transparent;
}
:deep(.premium-list-item:hover) { background: rgba(var(--v-theme-primary), 0.1) !important; }
:deep(.border-l-primary) { border-left-color: rgb(var(--v-theme-primary)) !important; }
:deep(.border-l-transparent) { border-left-color: transparent !important; }
</style>

<style scoped lang="scss">
/* --- TEMA E LAYOUT ENTERPRISE --- */
.admin-time-layout { position: relative; }

/* DARK MODE & GLASSMORPHISM */
.bg-glass-dark { background: rgba(10,10,12,0.85); }
.bg-glass-header { background: rgba(20,20,24,0.55); backdrop-filter: blur(14px); -webkit-backdrop-filter: blur(14px); }
.bg-glass-card { background: rgba(24, 24, 28, 0.65) !important; backdrop-filter: blur(24px); -webkit-backdrop-filter: blur(24px); }
.bg-black-40 { background-color: rgba(0, 0, 0, 0.4) !important; }
.bg-white-05 { background-color: rgba(255, 255, 255, 0.05) !important; }

/* BORDAS & SOMBRAS */
.border-thin { border: 1px solid rgba(0,0,0,0.08) !important; }
.border-bottom-white-05 { border-bottom: 1px solid rgba(255,255,255,0.08) !important; }
.border-white-10 { border-color: rgba(255, 255, 255, 0.1) !important; }
.border-white-20 { border-color: rgba(255, 255, 255, 0.2) !important; }

.shadow-sm { box-shadow: 0 2px 8px rgba(0,0,0,0.06) !important; }
.shadow-md { box-shadow: 0 4px 12px rgba(0,0,0,0.1) !important; }

/* FUNDO ANIMADO DARK MODE */
.background-carousel-wrapper {
  position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 0; pointer-events: none; opacity: 0.6;
}
.background-overlay {
  position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 1;
  background: radial-gradient(circle at center, rgba(15, 15, 19, 0.4), rgba(15, 15, 19, 0.98));
  backdrop-filter: blur(8px);
}

/* CAIXAS DE PESQUISA E DATAS */
.search-wrap { height: 40px; padding: 0 12px; display: flex; align-items: center; border-radius: 6px; }
.period-nav { height: 40px; padding: 0 16px; display: flex; align-items: center; border-radius: 6px; }

.clean-input { border: none; outline: none; background: transparent; padding: 0; }
.clean-input::-webkit-calendar-picker-indicator { filter: invert(1); cursor: pointer; opacity: 0.6; transition: 0.3s; }
.clean-input::-webkit-calendar-picker-indicator:hover { opacity: 1; }
.bg-grey-lighten-4 .clean-input::-webkit-calendar-picker-indicator { filter: none; }

/* BOTÕES 3D */
.btn-3d {
  border-radius: 6px !important;
  box-shadow: 0 3px 5px rgba(0,0,0,0.15), inset 0 2px 0 rgba(255,255,255,0.25) !important;
  transition: transform 0.1s ease, box-shadow 0.1s ease;
  text-transform: none !important;
}
.btn-3d:active {
  transform: translateY(2px);
  box-shadow: 0 1px 2px rgba(0,0,0,0.15), inset 0 1px 0 rgba(255,255,255,0.2) !important;
}
.chip-3d { border-radius: 4px !important; box-shadow: 0 2px 4px rgba(0,0,0,0.12), inset 0 1px 0 rgba(255,255,255,0.25) !important; text-shadow: 0 1px 2px rgba(0,0,0,0.25); }

/* UTILITÁRIOS E TIPOGRAFIA */
.ui-field :deep(.v-field) { border-radius: 6px !important; }
.hover-opacity:hover { opacity: 1 !important; transition: opacity 0.2s; }
.hover-bg-glass:hover { background: rgba(255,255,255,0.04) !important; cursor: pointer; }
.tracking-widest { letter-spacing: 0.05em; }
.ls-1 { letter-spacing: 0.5px; }
.lh-1 { line-height: 1.1; }
.transition-all { transition: all 0.3s ease; }

.hide-scrollbar::-webkit-scrollbar { display: none; }
.hide-scrollbar { -ms-overflow-style: none; scrollbar-width: none; }

.custom-scroll { scrollbar-gutter: stable; }
.custom-scroll::-webkit-scrollbar { width: 6px; height: 6px; }
.custom-scroll::-webkit-scrollbar-track { background: transparent; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128, 0.3); border-radius: 4px; }
</style>
