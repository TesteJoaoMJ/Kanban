<template>
  <div class="d-flex flex-column flex-grow-1 overflow-hidden h-100 pa-6 bg-transparent">

    <div class="flex-shrink-0 mb-6 d-flex justify-space-between align-center">
      <div>
        <h3 class="text-h6 font-weight-black text-uppercase tracking-widest text-primary d-flex align-center gap-2 lh-1">
          <v-icon>mdi-face-recognition</v-icon> Biometria FaceID
        </h3>
        <p class="text-[11px] font-weight-bold opacity-70 mt-1 mb-0" style="max-width: 800px;">
          Mapeamento e gravação de <strong>Vetores Neurais</strong>. O sistema extrai 128 descritores únicos da face para liberação sem toque nos terminais (Kiosks).
        </p>
      </div>
      <div class="d-flex align-center gap-3">
        <v-chip size="small" variant="tonal" color="success" class="font-weight-black chip-3d tracking-widest rounded-sm text-uppercase px-3">
          <v-icon start size="14">mdi-database-lock</v-icon> {{ biometricRecords.length }} Assinaturas
        </v-chip>
      </div>
    </div>

    <v-row class="flex-grow-1 ma-0 overflow-hidden" align="stretch">

      <v-col cols="12" lg="7" class="pa-0 pr-lg-6 d-flex flex-column h-100 border-e" :class="isLightMode ? 'border-grey-lighten-2' : 'border-white-10'">

          <div class="d-flex align-center justify-space-between mb-3">
             <span class="text-[10px] font-weight-black text-uppercase opacity-70 tracking-widest text-primary">Scanner em Tempo Real</span>
             <v-tooltip location="top" content-class="premium-tooltip" max-width="300">
               <template v-slot:activator="{ props }"><v-icon v-bind="props" size="14" class="opacity-50 cursor-help">mdi-help-circle-outline</v-icon></template>
               <span>Alinhe o rosto do colaborador no centro do quadro. Remova óculos escuros e máscaras para um mapeamento perfeito.</span>
             </v-tooltip>
          </div>

          <div
            class="scanner-viewport position-relative flex-grow-1 rounded-sm overflow-hidden shadow-sm border-thin mb-4 d-flex align-center justify-center bg-black"
            style="min-height: 400px; max-height: 60vh;"
            :style="isLightMode ? 'border: 2px solid rgba(25, 118, 210, 0.2) !important;' : 'border: 2px solid rgba(25, 118, 210, 0.4) !important;'"
          >
            <video ref="blurVideoRef" autoplay muted playsinline class="position-absolute top-0 left-0 w-100 h-100 blur-bg"></video>
            <div class="position-absolute top-0 left-0 w-100 h-100 bg-black opacity-60 z-0"></div>

            <video ref="videoRef" autoplay muted playsinline class="position-absolute top-0 left-0 w-100 h-100 object-contain z-1"></video>

            <canvas ref="canvasRef" class="position-absolute top-0 left-0 w-100 h-100 object-contain pointer-events-none z-10"></canvas>

            <div v-if="isLoadingModels" class="position-absolute top-0 left-0 w-100 h-100 d-flex flex-column align-center justify-center bg-black-80 z-20 backdrop-blur-md">
                <v-progress-circular indeterminate color="primary" size="64" width="4" class="mb-4"></v-progress-circular>
                <span class="text-[10px] font-weight-black text-uppercase tracking-widest pulse-text text-primary-lighten-1">Iniciando Rede Neural...</span>
            </div>

            <div v-if="showSuccessFlash" class="position-absolute top-0 left-0 w-100 h-100 bg-success z-30 d-flex flex-column align-center justify-center success-flash">
                <v-icon color="white" size="100" class="mb-2 drop-shadow-md">mdi-shield-check</v-icon>
                <span class="text-subtitle-1 font-weight-black text-white tracking-widest text-uppercase drop-shadow-md">Vetor Extraído e Gravado</span>
            </div>

            <template v-else-if="!isLoadingModels">
                <div class="scanner-overlay position-absolute top-0 left-0 w-100 h-100 pointer-events-none z-10">
                  <div class="scanner-laser"></div>
                  <div class="scanner-corner top-left"></div>
                  <div class="scanner-corner top-right"></div>
                  <div class="scanner-corner bottom-left"></div>
                  <div class="scanner-corner bottom-right"></div>
                </div>
            </template>
          </div>

          <div class="d-flex align-end gap-3 flex-shrink-0">
            <div class="flex-grow-1">
               <label class="text-[9px] font-weight-black text-uppercase opacity-70 tracking-widest mb-1 d-block" :class="isLightMode ? 'text-grey-darken-4' : 'text-white'">Nomenclatura do Hash (Opcional)</label>
               <v-text-field
                 v-model="biometricLabel"
                 placeholder="Ex: Face Principal"
                 variant="outlined"
                 density="compact"
                 hide-details
                 class="ui-field font-weight-bold text-caption"
                 :bg-color="isLightMode ? 'bg-grey-lighten-5' : 'rgba(0,0,0,0.2)'"
               ></v-text-field>
            </div>
            <v-btn
              variant="flat"
              color="primary"
              class="btn-3d font-weight-black tracking-widest px-8 rounded-sm"
              height="40"
              prepend-icon="mdi-camera-iris"
              :loading="isCapturing"
              :disabled="isLoadingModels"
              @click="captureFace"
            >
              CAPTURAR VETOR
            </v-btn>
          </div>

      </v-col>

      <v-col cols="12" lg="5" class="pa-0 pl-lg-6 d-flex flex-column h-100">

          <div class="d-flex align-center justify-space-between mb-3">
             <span class="text-[10px] font-weight-black text-uppercase opacity-70 tracking-widest text-success">Assinaturas Firmadas</span>
          </div>

          <div class="flex-grow-1 overflow-hidden d-flex flex-column transition-all grid-container-medium">
            <v-card
              class="flex-grow-1 d-flex flex-column rounded-sm border-thin overflow-hidden relative"
              :class="isLightMode ? 'bg-white shadow-sm' : 'bg-transparent border-white-05'"
              :elevation="0"
            >
              <div class="flex-grow-1 overflow-y-auto custom-scroll pa-4 d-flex flex-column gap-3">

                <div v-if="biometricRecords.length === 0" class="d-flex flex-column justify-center align-center h-100 opacity-40 py-12">
                   <v-icon size="48" class="mb-3">mdi-database-remove-outline</v-icon>
                   <span class="text-[10px] font-weight-black tracking-widest text-uppercase">Nenhum vetor cadastrado.</span>
                </div>

                <div v-else class="d-flex flex-column gap-3">
                  <div
                    v-for="(bio, idx) in biometricRecords"
                    :key="idx"
                    class="pa-3 rounded-sm border-thin d-flex align-center justify-space-between transition-all hover-card shadow-sm"
                    :class="isLightMode ? 'bg-grey-lighten-5 hover-border-success' : 'bg-black-20 border-white-10 hover-border-success'"
                  >
                      <div class="d-flex align-center gap-3 min-w-0">
                        <div class="icon-box rounded-sm d-flex align-center justify-center transition-all flex-shrink-0"
                             :class="isLightMode ? 'bg-green-lighten-5 text-success border border-green-lighten-4' : 'bg-success-darken-4 bg-opacity-20 text-success border border-success border-opacity-25'"
                             style="width: 38px; height: 38px;">
                           <v-icon size="20">mdi-text-recognition</v-icon>
                        </div>
                        <div class="d-flex flex-column min-w-0 overflow-hidden">
                          <div class="font-weight-black text-[12px] text-truncate w-100" :class="isLightMode ? 'text-grey-darken-4' : 'text-white'">{{ bio.label || `Assinatura Vetorial #${idx+1}` }}</div>
                          <div class="text-[9px] font-mono opacity-80 mt-1 d-flex align-center gap-1 text-success font-weight-bold">
                            <v-icon size="10" color="success">mdi-check-network</v-icon>128 descritores lidos com sucesso
                          </div>
                        </div>
                      </div>
                      <v-btn icon="mdi-trash-can-outline" variant="tonal" color="error" class="btn-3d rounded-sm flex-shrink-0" size="small" @click="deleteBiometric(idx)"></v-btn>
                  </div>
                </div>

              </div>

              <div class="pa-4 border-t flex-shrink-0" :class="isLightMode ? 'bg-grey-lighten-4 border-grey-lighten-2' : 'bg-black-40 border-white-10'">
                 <div class="d-flex align-center gap-2 opacity-60">
                    <v-icon size="14">mdi-information</v-icon>
                    <span class="text-[9px] font-weight-bold text-uppercase tracking-widest lh-1">O sistema Kiosk utiliza a melhor assinatura lida no momento do ponto para evitar falsos positivos.</span>
                 </div>
              </div>
            </v-card>
          </div>

      </v-col>
    </v-row>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch, onMounted, onUnmounted } from 'vue';
import { storeToRefs } from 'pinia';
import * as faceapi from 'face-api.js';
import { supabase } from '@/api/supabase';
import { useThemeStore } from '@/stores/theme';
import { useTimeTrackingStore } from '@/stores/timeTracking';

// Dispara eventos para o pai (Notificações)
const emit = defineEmits(['show-toast']);

// --- STORES ---
const themeStore = useThemeStore();
const timeStore = useTimeTrackingStore();
const isLightMode = computed(() => themeStore.currentMode === 'light');

const { selectedEmployeeId, selectedEmployeeResolved } = storeToRefs(timeStore);

// --- ESTADOS LOCAIS ---
const biometricLabel = ref('');
const isLoadingModels = ref(false);
const isCapturing = ref(false);
const showSuccessFlash = ref(false);
const biometricRecords = ref<any[]>([]);

// Referências da DOM
const videoRef = ref<HTMLVideoElement | null>(null);
const blurVideoRef = ref<HTMLVideoElement | null>(null);
const canvasRef = ref<HTMLCanvasElement | null>(null);

// Variáveis de Controle da Câmera
let videoStream: MediaStream | null = null;
let detectionInterval: ReturnType<typeof setInterval> | null = null;
let faceModelsLoaded = false;

// --- UTILITÁRIOS ---
const uid = () => Math.random().toString(36).substring(2, 10);

// --- MOTOR BIOMÉTRICO (FACE-API.JS) ---
async function loadFaceModels() {
  if (faceModelsLoaded) return;
  const urls = ['/models/face-api', 'https://raw.githubusercontent.com/justadudewhohacks/face-api.js/master/weights'];

  for (const baseUrl of urls) {
    try {
      await Promise.all([
        faceapi.nets.ssdMobilenetv1.loadFromUri(baseUrl),
        faceapi.nets.faceLandmark68Net.loadFromUri(baseUrl),
        faceapi.nets.faceRecognitionNet.loadFromUri(baseUrl),
      ]);
      faceModelsLoaded = true;
      return;
    } catch (e) {
      console.warn(`Falha ao carregar modelos de: ${baseUrl}`);
    }
  }
}

async function startWebcam() {
  if (!selectedEmployeeResolved.value) return;

  stopWebcam();
  isLoadingModels.value = true;

  try {
    await loadFaceModels();

    videoStream = await navigator.mediaDevices.getUserMedia({
      video: { facingMode: 'user', width: { ideal: 1280 }, height: { ideal: 720 } }
    });

    if (videoRef.value && blurVideoRef.value) {
      videoRef.value.srcObject = videoStream;
      blurVideoRef.value.srcObject = videoStream;

      videoRef.value.onloadedmetadata = () => {
        isLoadingModels.value = false;
        setTimeout(startFaceTracking, 100);
      };
    }
  } catch (error) {
    isLoadingModels.value = false;
    emit('show-toast', { message: 'Falha na obtenção do fluxo de câmera. Verifique permissões.', color: 'error' });
  }
}

function stopWebcam() {
  if (detectionInterval) {
    clearInterval(detectionInterval);
    detectionInterval = null;
  }
  if (videoStream) {
    videoStream.getTracks().forEach(t => t.stop());
    videoStream = null;
  }
}

function startFaceTracking() {
  if (!videoRef.value || !canvasRef.value) return;
  if (detectionInterval) clearInterval(detectionInterval);

  const displaySize = { width: videoRef.value.videoWidth, height: videoRef.value.videoHeight };
  canvasRef.value.width = displaySize.width;
  canvasRef.value.height = displaySize.height;
  faceapi.matchDimensions(canvasRef.value, displaySize);

  detectionInterval = setInterval(async () => {
    if (!videoRef.value || !canvasRef.value || videoRef.value.readyState !== 4) return;
    try {
      const detection = await faceapi.detectSingleFace(videoRef.value).withFaceLandmarks();
      const ctx = canvasRef.value.getContext('2d');
      if (!ctx) return;

      ctx.clearRect(0, 0, canvasRef.value.width, canvasRef.value.height);

      if (detection) {
        const resized = faceapi.resizeResults(detection, displaySize);
        faceapi.draw.drawDetections(canvasRef.value, resized);
        faceapi.draw.drawFaceLandmarks(canvasRef.value, resized);
      }
    } catch(e) {}
  }, 100);
}

// --- MÉTODOS DE BANCO DE DADOS ---
async function captureFace() {
  if (!videoRef.value || !selectedEmployeeResolved.value) return;

  isCapturing.value = true;
  try {
    const detection = await faceapi.detectSingleFace(videoRef.value).withFaceLandmarks().withFaceDescriptor();

    if (!detection) {
      emit('show-toast', { message: 'Rosto evadido dos sensores. Posicione-se ao centro da lente.', color: 'warning' });
      return;
    }

    const record = {
      id: uid(),
      label: biometricLabel.value || `Assinatura Vetorial #${biometricRecords.value.length + 1}`,
      descriptor: Array.from(detection.descriptor)
    };

    biometricRecords.value.push(record);

    const { error } = await supabase.from('employees_mj').update({ face_descriptors: biometricRecords.value }).eq('id', selectedEmployeeId.value);
    if(error) throw error;

    biometricLabel.value = '';
    showSuccessFlash.value = true;
    setTimeout(() => { showSuccessFlash.value = false; }, 1500);
    emit('show-toast', { message: 'Vetor gravado com sucesso.', color: 'success' });

  } catch (e) {
    emit('show-toast', { message: 'A IA falhou em processar o vetor.', color: 'error' });
  } finally {
    isCapturing.value = false;
  }
}

async function deleteBiometric(idx: number) {
  if (!confirm('Deseja realmente expurgar esta assinatura vetorial do banco?')) return;

  const backup = [...biometricRecords.value];
  biometricRecords.value.splice(idx, 1);

  try {
    const { error } = await supabase.from('employees_mj').update({ face_descriptors: biometricRecords.value }).eq('id', selectedEmployeeId.value);
    if (error) throw error;
    emit('show-toast', { message: 'Vetor removido com sucesso.', color: 'success' });
  } catch (e) {
    biometricRecords.value = backup;
    emit('show-toast', { message: 'Erro ao remover assinatura.', color: 'error' });
  }
}

// --- CICLO DE VIDA DO COMPONENTE ---
const syncLocalRecords = () => {
  if (selectedEmployeeResolved.value && selectedEmployeeResolved.value.face_descriptors) {
    biometricRecords.value = [...selectedEmployeeResolved.value.face_descriptors];
  } else {
    biometricRecords.value = [];
  }
};

watch(selectedEmployeeId, () => {
  syncLocalRecords();
  startWebcam();
});

onMounted(() => {
  syncLocalRecords();
  startWebcam();
});

onUnmounted(() => {
  stopWebcam();
});
</script>

<style lang="scss">
/* Tooltip Premium Global */
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
.bg-black-80 { background-color: rgba(0,0,0,0.85) !important; }
.rounded-sm { border-radius: 4px !important; }
.border-thin { border: 1px solid rgba(128, 128, 128, 0.15) !important; }
.shadow-sm { box-shadow: 0 2px 8px rgba(0,0,0,0.06) !important; }

/* Tipografia */
.tracking-widest { letter-spacing: 0.05em; }
.lh-1 { line-height: 1.1; }

/* Botões 3D e Chips */
.btn-3d { box-shadow: 0 3px 5px rgba(0,0,0,0.1), inset 0 2px 0 rgba(255,255,255,0.15) !important; text-transform: none !important; }
.btn-3d:active { transform: translateY(2px); box-shadow: 0 1px 2px rgba(0,0,0,0.1), inset 0 1px 0 rgba(255,255,255,0.1) !important; }
.chip-3d { box-shadow: 0 2px 4px rgba(0,0,0,0.2), inset 0 1px 0 rgba(255,255,255,0.1) !important; border-radius: 4px !important; }

/* Cards Hover */
.hover-card { transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1); border: 1px solid transparent; }
.hover-card:hover { transform: translateY(-2px); box-shadow: 0 8px 16px rgba(0,0,0,0.15) !important; }
.hover-border-success:hover { border-color: rgb(var(--v-theme-success)) !important; }

/* Scrollbars */
.custom-scroll { scrollbar-gutter: stable; }
.custom-scroll::-webkit-scrollbar { width: 5px; height: 5px; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128, 0.3); border-radius: 4px; }

.ui-field :deep(.v-field) { border-radius: 4px !important; }
.d-block { display: block; }
.backdrop-blur-md { backdrop-filter: blur(12px); -webkit-backdrop-filter: blur(12px); }
.drop-shadow-md { filter: drop-shadow(0 4px 6px rgba(0,0,0,0.4)); }

/* --- BIOMETRIA SCANNER HUD ENTERPRISE --- */
.scanner-overlay {
  box-shadow: inset 0 0 80px rgba(0,0,0,0.9);
}

.object-contain { object-fit: contain; }
.blur-bg { filter: blur(40px); opacity: 0.6; transform: scale(1.15); }

.success-flash {
  animation: flashFade 1.5s ease-out forwards;
  backdrop-filter: blur(8px);
}

@keyframes flashFade {
  0% { opacity: 0; }
  15% { opacity: 0.95; }
  80% { opacity: 0.95; }
  100% { opacity: 0; }
}

/* Cantos do Scanner (Retícula HUD Militar) */
.scanner-corner { position: absolute; width: 50px; height: 50px; border-style: solid; border-color: rgba(25, 118, 210, 0.9); box-shadow: 0 0 10px rgba(25, 118, 210, 0.5); }
.top-left { top: 30px; left: 30px; border-width: 4px 0 0 4px; border-top-left-radius: 6px; }
.top-right { top: 30px; right: 30px; border-width: 4px 4px 0 0; border-top-right-radius: 6px; }
.bottom-left { bottom: 30px; left: 30px; border-width: 0 0 4px 4px; border-bottom-left-radius: 6px; }
.bottom-right { bottom: 30px; right: 30px; border-width: 0 4px 4px 0; border-bottom-right-radius: 6px; }

/* Linha Laser */
.scanner-laser {
  position: absolute; top: 0; left: 0; width: 100%; height: 2px; background: rgba(25, 118, 210, 0.8);
  box-shadow: 0 0 20px rgba(25, 118, 210, 1), 0 0 40px rgba(25, 118, 210, 0.8); animation: scan 2.5s infinite linear; z-index: 15;
}

@keyframes scan {
  0% { top: 5%; opacity: 0; }
  10% { opacity: 1; }
  90% { opacity: 1; }
  100% { top: 95%; opacity: 0; }
}

.pulse-text { animation: pulse 1.5s infinite; }
@keyframes pulse { 0% { opacity: 0.4; } 50% { opacity: 1; } 100% { opacity: 0.4; } }
</style>
