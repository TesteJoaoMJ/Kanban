<template>
  <v-container fluid class="pa-6 bg-background-app">

    <div class="header-section mb-6 animate-fade-in-down">
      <div class="d-flex flex-column flex-md-row justify-space-between align-md-center ga-4">
        <div class="d-flex align-center">
          <div
            class="icon-box-lg mr-4 elevation-6 rounded-xl d-flex align-center justify-center transition-swing"
            :class="isLight ? 'bg-primary-lighten-1 text-white' : 'bg-primary text-white'"
          >
            <v-icon size="28">mdi-school</v-icon>
          </div>
          <div>
            <div class="d-flex align-center text-caption font-weight-bold mb-1 opacity-70" :class="textSecondaryClass">
              <span class="mr-2">MJ PROCESS</span>
              <v-icon size="x-small" class="mr-2">mdi-chevron-right</v-icon>
              <span>ACADEMIA</span>
            </div>
            <h1 class="text-h4 font-weight-black" :class="textPrimaryClass">
              Central de Treinamento
            </h1>
          </div>
        </div>

        <div class="d-flex align-center px-4 py-3 rounded-xl border-thin backdrop-blur" :class="cardBgClass">
          <div class="mr-4 text-right">
            <div class="text-subtitle-2 font-weight-bold text-uppercase" :class="textSecondaryClass">Seu Progresso</div>
            <div class="text-caption font-weight-medium" :class="completionPercentage === 100 ? 'text-success' : 'text-primary'">
              {{ completedModulesCount }} de {{ totalModulesCount }} concluídos
            </div>
          </div>
          <v-progress-circular
            :model-value="completionPercentage"
            :size="54"
            :width="6"
            :color="completionPercentage === 100 ? 'success' : 'primary'"
            class="font-weight-bold text-caption"
            :class="isLight && completionPercentage !== 100 ? 'text-primary-darken-1' : ''"
          >
            {{ Math.round(completionPercentage) }}%
          </v-progress-circular>
        </div>
      </div>
    </div>

    <v-row class="animate-fade-in-up" style="animation-delay: 0.1s">
      <v-col cols="12" xl="8" lg="8">
        <v-card class="rounded-xl border-thin overflow-hidden d-flex flex-column h-100" :class="cardBgClass">

          <div class="player-wrapper position-relative bg-black d-flex align-center justify-center">
            <template v-if="activeModule.id">
              <video
                v-if="activeModule.module_type === 'video'"
                :key="'vid-'+activeModule.id"
                :src="activeModule.content_url"
                controls
                controlslist="nodownload"
                crossorigin="anonymous"
                playsinline
                class="w-100 h-100 object-fit-contain"
                @ended="markAsCompleted(activeModule.id)"
              ></video>

              <iframe
                v-else-if="activeModule.module_type === 'pdf'"
                :key="'pdf-'+activeModule.id"
                :src="activeModule.content_url"
                class="w-100 h-100 border-0 bg-white"
              ></iframe>

              <v-img
                v-else-if="activeModule.module_type === 'image'"
                :key="'img-'+activeModule.id"
                :src="activeModule.content_url"
                class="w-100 h-100"
                contain
              ></v-img>
            </template>
            <div v-else class="d-flex flex-column align-center justify-center w-100 h-100 opacity-50">
              <v-icon size="64" color="white" class="mb-4">mdi-play-network-outline</v-icon>
              <span class="text-white text-h6">Selecione um módulo para começar</span>
            </div>
          </div>

          <div class="pa-6 d-flex flex-column flex-grow-1" v-if="activeModule.id">
            <div class="d-flex align-start justify-space-between mb-4">
              <div>
                <v-chip size="small" :color="getModuleColor(activeModule.module_type)" class="mb-2 font-weight-bold text-uppercase" variant="flat">
                  {{ getModuleTypeName(activeModule.module_type) }}
                </v-chip>
                <h2 class="text-h4 font-weight-bold" :class="textPrimaryClass">{{ activeModule.title }}</h2>
              </div>
              <v-btn
                v-if="activeModule.module_type === 'pdf' || activeModule.module_type === 'image'"
                icon="mdi-download"
                variant="tonal"
                color="primary"
                :href="activeModule.content_url"
                target="_blank"
                download
                class="shadow-soft"
              >
              </v-btn>
            </div>

            <v-divider class="mb-6" :class="borderClass"></v-divider>

            <div class="mt-auto bg-surface-variant-opacity rounded-lg pa-4 border-thin" :class="isLight ? 'bg-grey-lighten-4' : 'bg-white-05'">
              <div v-if="!isCompleted(activeModule.id)" class="d-flex flex-column flex-md-row align-md-center justify-space-between ga-4">
                <div v-if="activeModule.module_type === 'pdf' || activeModule.module_type === 'image'" class="flex-grow-1">
                  <v-checkbox
                    v-model="readConfirmation"
                    hide-details
                    color="primary"
                  >
                    <template v-slot:label>
                      <span class="text-body-2 font-weight-medium" :class="textPrimaryClass">
                        Declaro que li e compreendi o conteúdo deste {{ activeModule.module_type === 'pdf' ? 'documento' : 'informativo' }}.
                      </span>
                    </template>
                  </v-checkbox>
                </div>
                <div v-else class="text-body-2" :class="textSecondaryClass">
                  Assista ao vídeo até o final para conclusão automática ou clique ao lado.
                </div>

                <v-btn
                  :disabled="(activeModule.module_type === 'pdf' || activeModule.module_type === 'image') && !readConfirmation"
                  color="success"
                  variant="flat"
                  @click="markAsCompleted(activeModule.id)"
                  size="large"
                  prepend-icon="mdi-check-circle-outline"
                  class="text-none font-weight-bold btn-rect shadow-glow"
                >
                  Concluir Módulo
                </v-btn>
              </div>
              <div v-else class="d-flex align-center text-success py-2">
                <div class="icon-box-sm bg-success-opacity-10 rounded-circle mr-3 d-flex align-center justify-center">
                  <v-icon>mdi-check-decagram</v-icon>
                </div>
                <div>
                  <div class="font-weight-bold text-subtitle-1">Módulo Concluído</div>
                  <div class="text-caption opacity-80">Você já finalizou este treinamento.</div>
                </div>
              </div>
            </div>
          </div>
        </v-card>
      </v-col>

      <v-col cols="12" xl="4" lg="4">
        <v-card class="rounded-xl border-thin h-100 d-flex flex-column" :class="cardBgClass">
          <div class="pa-5 border-b" :class="borderClass">
            <h3 class="text-h6 font-weight-bold d-flex align-center" :class="textPrimaryClass">
              <v-icon start color="primary">mdi-format-list-bulleted</v-icon>
              Conteúdo do Curso
            </h3>
          </div>

          <div class="flex-grow-1 overflow-y-auto custom-scroll pa-2" style="max-height: calc(100vh - 250px);">

            <template v-if="documentModules.length > 0">
              <div class="px-4 pt-4 pb-2 text-caption font-weight-bold text-uppercase opacity-60" :class="textPrimaryClass">Documentação Técnica</div>
              <div class="px-2">
                <v-card
                  v-for="(moduleItem, index) in documentModules"
                  :key="moduleItem.id"
                  @click="selectModule(moduleItem)"
                  class="playlist-item mb-2 border-thin rounded-lg transition-swing"
                  :class="[
                    activeModule.id === moduleItem.id ? (isLight ? 'bg-primary-lighten-5 border-primary text-primary' : 'bg-primary-opacity-10 border-primary text-primary-lighten-1') : 'bg-transparent cursor-pointer hover-overlay',
                    isLight ? 'border-grey-lighten-2' : 'border-white-05'
                  ]"
                  elevation="0"
                >
                  <div class="d-flex align-center pa-3">
                    <div class="text-caption font-mono font-weight-bold opacity-50 mr-3 w-4 text-center">{{ index + 1 }}</div>
                    <div class="icon-box-sm rounded mr-3" :class="activeModule.id === moduleItem.id ? 'bg-primary text-white' : (isLight ? 'bg-grey-lighten-3 text-grey-darken-1' : 'bg-white-05 text-grey-lighten-1')">
                      <v-icon size="16">{{ moduleItem.module_type === 'pdf' ? 'mdi-file-pdf-box' : 'mdi-image-outline' }}</v-icon>
                    </div>
                    <div class="flex-grow-1 min-width-0">
                      <div class="text-body-2 font-weight-bold text-truncate" :class="activeModule.id === moduleItem.id ? '' : textPrimaryClass">
                        {{ moduleItem.title }}
                      </div>
                      <div class="text-[10px] text-uppercase" :class="activeModule.id === moduleItem.id ? 'opacity-80' : textSecondaryClass">
                        {{ moduleItem.module_type === 'pdf' ? 'PDF' : 'Imagem' }}
                      </div>
                    </div>
                    <v-icon v-if="isCompleted(moduleItem.id)" color="success" size="20" class="ml-2">mdi-check-circle</v-icon>
                  </div>
                </v-card>
              </div>
            </template>

            <template v-if="videoModules.length > 0">
              <div class="px-4 pt-4 pb-2 text-caption font-weight-bold text-uppercase opacity-60" :class="textPrimaryClass">Videoaulas</div>
              <div class="px-2 pb-4">
                <v-card
                  v-for="(moduleItem, index) in videoModules"
                  :key="moduleItem.id"
                  @click="selectModule(moduleItem)"
                  class="playlist-item mb-2 border-thin rounded-lg transition-swing"
                  :class="[
                    activeModule.id === moduleItem.id ? (isLight ? 'bg-primary-lighten-5 border-primary text-primary' : 'bg-primary-opacity-10 border-primary text-primary-lighten-1') : 'bg-transparent cursor-pointer hover-overlay',
                    isLight ? 'border-grey-lighten-2' : 'border-white-05'
                  ]"
                  elevation="0"
                >
                  <div class="d-flex align-center pa-3">
                    <div class="text-caption font-mono font-weight-bold opacity-50 mr-3 w-4 text-center">{{ index + 1 }}</div>
                    <div class="icon-box-sm rounded mr-3" :class="activeModule.id === moduleItem.id ? 'bg-primary text-white' : (isLight ? 'bg-grey-lighten-3 text-grey-darken-1' : 'bg-white-05 text-grey-lighten-1')">
                      <v-icon size="16">mdi-play</v-icon>
                    </div>
                    <div class="flex-grow-1 min-width-0">
                      <div class="text-body-2 font-weight-bold text-truncate" :class="activeModule.id === moduleItem.id ? '' : textPrimaryClass">
                        {{ moduleItem.title }}
                      </div>
                      <div class="text-[10px] text-uppercase" :class="activeModule.id === moduleItem.id ? 'opacity-80' : textSecondaryClass">Vídeo</div>
                    </div>
                    <v-icon v-if="isCompleted(moduleItem.id)" color="success" size="20" class="ml-2">mdi-check-circle</v-icon>
                  </div>
                </v-card>
              </div>
            </template>

          </div>
        </v-card>
      </v-col>
    </v-row>

    <v-dialog v-model="showCompletionDialog" max-width="500">
      <v-card class="rounded-xl border-thin text-center pa-6" :class="cardBgClass">
        <v-icon color="warning" size="80" class="mb-4">mdi-trophy</v-icon>
        <h2 class="text-h4 font-weight-black mb-2" :class="textPrimaryClass">Parabéns!</h2>
        <p class="text-body-1 mb-6" :class="textSecondaryClass">Você concluiu 100% da sua trilha de treinamento inicial na MJ Process. Você está pronto para decolar nas vendas!</p>
        <v-btn color="primary" variant="flat" size="large" class="btn-rect font-weight-bold shadow-glow" @click="showCompletionDialog = false">
          Fechar
        </v-btn>
      </v-card>
    </v-dialog>

  </v-container>
</template>

<script setup lang="ts">
import { ref, onMounted, computed, watch } from 'vue';
import { supabase } from '@/api/supabase';
import { useUserStore } from '@/stores/user';
import { useThemeStore } from '@/stores/theme';

type TrainingModule = {
  id: string;
  title: string;
  module_type: 'video' | 'pdf' | 'image';
  content_url: string;
  module_order: number;
};

const userStore = useUserStore();
const themeStore = useThemeStore();

// Theme Helpers
const isLight = computed(() => themeStore.currentMode === 'light');
const textPrimaryClass = computed(() => isLight.value ? 'text-grey-darken-4' : 'text-white');
const textSecondaryClass = computed(() => isLight.value ? 'text-grey-darken-1' : 'text-grey-lighten-1');
const cardBgClass = computed(() => isLight.value ? 'bg-white shadow-soft' : 'glass-panel');
const borderClass = computed(() => isLight.value ? 'border-grey-lighten-2' : 'border-white-05');

const allModules = ref<TrainingModule[]>([]);
const activeModule = ref<TrainingModule>({ id: '', title: '', module_type: 'video', content_url: '', module_order: 0 });
const completedModules = ref<Set<string>>(new Set());
const readConfirmation = ref(false);
const showCompletionDialog = ref(false);

const videoModules = computed(() => allModules.value.filter(m => m.module_type === 'video'));
const documentModules = computed(() => allModules.value.filter(m => m.module_type === 'pdf' || m.module_type === 'image'));
const totalModulesCount = computed(() => allModules.value.length);
const completedModulesCount = computed(() => completedModules.value.size);

const completionPercentage = computed(() => {
  if (totalModulesCount.value === 0) return 0;
  return (completedModulesCount.value / totalModulesCount.value) * 100;
});

// Watcher para disparar o popup de conclusão apenas quando bater 100% na sessão atual
watch(completionPercentage, (newVal, oldVal) => {
    if (newVal === 100 && oldVal < 100 && oldVal > 0) {
        showCompletionDialog.value = true;
    }
});

const isCompleted = (moduleId: string) => completedModules.value.has(moduleId);

const selectModule = (moduleItem: TrainingModule) => {
  activeModule.value = moduleItem;
  readConfirmation.value = false;
};

const markAsCompleted = async (moduleId: string) => {
  if (isCompleted(moduleId) || !userStore.profile) return;
  try {
    const { error } = await supabase.from('training_progress').insert({
      user_id: userStore.profile.id,
      module_id: moduleId,
    });
    if (error) throw error;

    // Atualiza o set local para reatividade imediata
    const novaLista = new Set(completedModules.value);
    novaLista.add(moduleId);
    completedModules.value = novaLista;

  } catch (err) {
    console.error('Erro ao marcar como concluído:', err);
  }
};

const getModuleTypeName = (type: string) => {
    switch(type) {
        case 'video': return 'Videoaula';
        case 'pdf': return 'Documento PDF';
        case 'image': return 'Informativo';
        default: return 'Material';
    }
};

const getModuleColor = (type: string) => {
    switch(type) {
        case 'video': return 'primary';
        case 'pdf': return 'error';
        case 'image': return 'info';
        default: return 'grey';
    }
};

const fetchTrainingData = async () => {
  if (!userStore.profile) return;

  const { data: modulesData, error: modulesError } = await supabase
    .from('training_modules')
    .select('*')
    .order('module_order', { ascending: true });
  if (modulesError) { console.error("Erro ao buscar módulos:", modulesError); return; }

  allModules.value = modulesData;

  const { data: progressData, error: progressError } = await supabase
    .from('training_progress')
    .select('module_id')
    .eq('user_id', userStore.profile.id);
  if (progressError) { console.error("Erro ao buscar progresso:", progressError); return; }

  completedModules.value = new Set(progressData.map(p => p.module_id));

  if (allModules.value.length > 0) {
    // Seleciona o primeiro não concluído, ou o primeiro da lista
    const firstIncomplete = allModules.value.find(m => !isCompleted(m.id));
    activeModule.value = firstIncomplete || allModules.value[0];
  }
};

onMounted(async () => {
    if(!userStore.profile) await userStore.fetchSession();
    fetchTrainingData();
});
</script>

<style scoped lang="scss">
/* --- ANIMATIONS --- */
.animate-fade-in-down { animation: fadeInDown 0.6s cubic-bezier(0.2, 0.8, 0.2, 1); }
.animate-fade-in-up { animation: fadeInUp 0.6s cubic-bezier(0.2, 0.8, 0.2, 1) backwards; }
@keyframes fadeInDown { from { opacity: 0; transform: translateY(-20px); } to { opacity: 1; transform: translateY(0); } }
@keyframes fadeInUp { from { opacity: 0; transform: translateY(20px); } to { opacity: 1; transform: translateY(0); } }

/* --- BASE (Glassmorphism & Theme Match) --- */
.bg-background-app { background: transparent; min-height: 100vh; }
.glass-panel { background: rgba(30, 30, 35, 0.7); backdrop-filter: blur(16px); border: 1px solid rgba(255, 255, 255, 0.08); box-shadow: 0 8px 32px rgba(0,0,0,0.3); }
.border-white-05 { border-color: rgba(255,255,255,0.05) !important; }
.bg-white-05 { background: rgba(255,255,255,0.05); }
.bg-primary-opacity-10 { background: rgba(var(--v-theme-primary), 0.1); }
.bg-success-opacity-10 { background: rgba(76, 175, 80, 0.1); }

.bg-white { background-color: #ffffff; }
.shadow-soft { box-shadow: 0 4px 20px rgba(0,0,0,0.05) !important; }
.shadow-glow { box-shadow: 0 0 15px rgba(var(--v-theme-primary), 0.4); }

.btn-rect { border-radius: 0 !important; text-transform: none !important; }

/* --- SCROLLBAR --- */
.custom-scroll::-webkit-scrollbar { width: 4px; }
.custom-scroll::-webkit-scrollbar-track { background: transparent; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128, 128, 128, 0.3); border-radius: 4px; }
.custom-scroll::-webkit-scrollbar-thumb:hover { background: rgba(128, 128, 128, 0.6); }

/* --- PLAYER --- */
.player-wrapper {
  aspect-ratio: 16 / 9;
  width: 100%;
  border-bottom: 1px solid rgba(128,128,128,0.1);
}
.object-fit-contain { object-fit: contain; }

/* --- PLAYLIST ITEM --- */
.playlist-item {
  transform: translateY(0);
}
.hover-overlay:hover {
  background: rgba(128,128,128,0.05) !important;
  transform: translateX(4px);
}
.w-4 { width: 1rem; }
.min-width-0 { min-width: 0; }

.icon-box-lg { width: 48px; height: 48px; }
.icon-box-sm { width: 32px; height: 32px; display: flex; align-items: center; justify-content: center; }
</style>
