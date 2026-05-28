<template>
  <div class="d-flex flex-column flex-grow-1 overflow-hidden h-100 pa-6 bg-transparent">

    <div class="flex-shrink-0 mb-6 d-flex justify-space-between align-center">
      <div>
        <h3 class="text-h6 font-weight-black text-uppercase tracking-widest text-primary d-flex align-center gap-2 lh-1">
          <v-icon>mdi-shield-eye-outline</v-icon> Auditoria Visual Kiosk
        </h3>
        <p class="text-[11px] font-weight-bold opacity-70 mt-1 mb-0" style="max-width: 800px;">
          Registros fotográficos de segurança coletados no momento do apontamento pelo terminal.
        </p>
      </div>
      <div class="d-flex align-center gap-3">
        <v-chip size="small" variant="tonal" color="primary" class="font-weight-black chip-3d tracking-widest rounded-sm">
          <v-icon start size="14">mdi-camera-iris</v-icon> {{ totalPhotos }} CAPTURAS
        </v-chip>
      </div>
    </div>

    <div class="flex-grow-1 overflow-hidden d-flex flex-column transition-all grid-container-medium">
      <v-card
        class="flex-grow-1 d-flex flex-column rounded-sm border-thin overflow-hidden relative"
        :class="isLightMode ? 'bg-white shadow-sm' : 'bg-transparent border-white-05'"
        :elevation="0"
      >
        <div class="grid-scroll flex-grow-1 overflow-y-auto custom-scroll pa-6 relative">

          <div v-if="auditLogs.length === 0" class="d-flex flex-column justify-center align-center h-100 opacity-30 py-12">
            <v-icon size="64" class="mb-4">mdi-camera-off</v-icon>
            <span class="text-subtitle-1 font-weight-black tracking-widest text-uppercase">Sem Registros Fotográficos</span>
            <span class="text-[11px] font-weight-bold uppercase tracking-widest mt-1 text-center">O colaborador não possui batidas com foto nesta competência.</span>
          </div>

          <div v-else v-for="log in auditLogs" :key="log.dateStr" class="mb-8">

             <div class="sticky-head d-flex align-center gap-3 mb-4 pa-3 rounded-sm border-thin shadow-sm backdrop-blur-md" :class="isLightMode ? 'bg-grey-lighten-4 border-grey-lighten-2' : 'bg-black-60 border-white-10 text-white'" style="top: -24px;">
                <v-icon size="16" color="primary">mdi-calendar-check</v-icon>
                <span class="text-body-2 font-weight-black text-uppercase tracking-widest">{{ log.label }}</span>
                <span class="text-[10px] font-weight-bold opacity-60 text-uppercase tracking-widest">({{ log.weekday }})</span>
                <v-chip size="x-small" color="primary" variant="flat" class="ml-auto font-weight-black rounded-sm">{{ log.punch_photos.length }} FOTOS</v-chip>
             </div>

             <v-row dense>
                <v-col cols="12" sm="6" md="4" lg="3" xl="2" v-for="(photoObj, idx) in log.punch_photos" :key="idx">

                   <v-card
                     class="photo-audit-card rounded-sm border-thin overflow-hidden position-relative group/photo cursor-pointer shadow-sm transition-all"
                     :class="isLightMode ? 'bg-grey-lighten-5 hover-border-primary' : 'bg-black-40 border-white-10 hover-border-primary'"
                     elevation="0"
                     @click="openPhoto(photoObj, log)"
                   >
                      <v-img :src="photoObj.photo" aspect-ratio="4/3" cover class="photo-img transition-all group-hover-scale">
                         <template v-slot:placeholder>
                           <div class="d-flex align-center justify-center fill-height opacity-20">
                             <v-progress-circular indeterminate color="primary"></v-progress-circular>
                           </div>
                         </template>
                      </v-img>

                      <div class="absolute inset-0 bg-black-60 opacity-0 group-hover-opacity-100 d-flex align-center justify-center transition-all z-10 backdrop-blur-sm">
                         <v-icon color="white" size="36">mdi-magnify-plus-outline</v-icon>
                      </div>

                      <div class="absolute bottom-0 left-0 w-100 pa-2 d-flex align-end justify-space-between z-20" style="background: linear-gradient(to top, rgba(0,0,0,0.85) 0%, transparent 100%);">
                         <div class="d-flex flex-column">
                            <span class="text-[8px] text-success font-weight-black text-uppercase tracking-widest mb-n1 d-flex align-center gap-1">
                               <v-icon size="10" color="success">mdi-circle-medium</v-icon> KIOSK_CAM
                            </span>
                            <span class="text-white font-mono text-[14px] font-weight-black lh-1">{{ photoObj.time }}</span>
                         </div>
                         <v-icon color="white" size="14" class="opacity-70">mdi-shield-check</v-icon>
                      </div>
                   </v-card>

                </v-col>
             </v-row>
          </div>

        </div>
      </v-card>
    </div>

    <v-dialog v-model="photoModal.show" max-width="700">
       <v-card class="rounded-sm overflow-hidden shadow-neon-elegant border-white-10 bg-black text-white">

          <div class="pa-4 border-b border-white-10 bg-glass-header d-flex align-center justify-space-between position-absolute top-0 w-100 z-20">
             <div class="d-flex flex-column">
                <span class="text-[10px] font-weight-black text-error text-uppercase tracking-widest d-flex align-center gap-1 mb-1 pulse-rec">
                   <v-icon size="12" color="error">mdi-record-circle</v-icon> AUDIT_LOG
                </span>
                <span class="text-subtitle-1 font-mono font-weight-black lh-1">{{ photoModal.date }} - {{ photoModal.time }}</span>
             </div>
             <div class="d-flex align-center gap-4">
                <div class="text-right d-none d-sm-block">
                   <div class="text-[10px] font-weight-bold opacity-70 text-uppercase tracking-widest">{{ selectedEmployeeResolved?.nome }}</div>
                   <div class="text-[10px] font-mono text-success">ID: {{ selectedEmployeeResolved?.id?.substring(0,8) || '0000' }}</div>
                </div>
                <v-btn icon="mdi-close" variant="tonal" size="small" color="white" class="btn-3d rounded-sm" @click="photoModal.show = false"></v-btn>
             </div>
          </div>

          <v-img :src="photoModal.url" width="100%" class="bg-grey-darken-4" contain style="min-height: 500px; max-height: 80vh; margin-top: 68px;">
             <div class="absolute inset-0 d-flex align-center justify-center pointer-events-none opacity-20">
                <v-icon size="180" color="white">mdi-shield-lock-outline</v-icon>
             </div>
          </v-img>

       </v-card>
    </v-dialog>

  </div>
</template>

<script setup lang="ts">
import { reactive, computed } from 'vue';
import { storeToRefs } from 'pinia';
import { useThemeStore } from '@/stores/theme';
import { useTimeTrackingStore } from '@/stores/timeTracking';

// --- STORES ---
const themeStore = useThemeStore();
const timeStore = useTimeTrackingStore();
const isLightMode = computed(() => themeStore.currentMode === 'light');

const { monthMirror, selectedEmployeeResolved } = storeToRefs(timeStore);

// --- COMPUTEDS ---
// Filtra dias que possuem fotos no Kiosk
const auditLogs = computed(() => {
  return monthMirror.value.filter((m: any) => m.punch_photos && m.punch_photos.length > 0);
});

// Calcula total de fotos para o KPI do Header
const totalPhotos = computed(() => {
  return auditLogs.value.reduce((acc, log) => acc + log.punch_photos.length, 0);
});

// --- ESTADOS DO MODAL (LIGHTBOX) ---
const photoModal = reactive({
  show: false,
  url: '',
  time: '',
  date: ''
});

function openPhoto(photoObj: any, logObj: any) {
  photoModal.url = photoObj.photo;
  photoModal.time = photoObj.time;
  photoModal.date = logObj.label;
  photoModal.show = true;
}
</script>

<style scoped lang="scss">
/* Estética Base */
.border-white-05 { border-color: rgba(255, 255, 255, 0.05) !important; }
.border-white-10 { border-color: rgba(255, 255, 255, 0.1) !important; }
.bg-black-40 { background-color: rgba(0,0,0,0.4) !important; }
.bg-black-60 { background-color: rgba(0,0,0,0.6) !important; }
.bg-white-80 { background-color: rgba(255,255,255,0.8) !important; }
.rounded-sm { border-radius: 4px !important; }
.border-thin { border: 1px solid rgba(128, 128, 128, 0.15) !important; }
.shadow-sm { box-shadow: 0 2px 8px rgba(0,0,0,0.06) !important; }

/* Tipografia */
.tracking-widest { letter-spacing: 0.05em; }
.lh-1 { line-height: 1.1; }

/* Scrollbars */
.custom-scroll { scrollbar-gutter: stable; }
.custom-scroll::-webkit-scrollbar { width: 6px; height: 6px; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128, 0.3); border-radius: 4px; }
.custom-scroll::-webkit-scrollbar-track { background: transparent; }

/* Sticky Elements */
.sticky-head { position: sticky; z-index: 10; }
.backdrop-blur-md { backdrop-filter: blur(12px); -webkit-backdrop-filter: blur(12px); }

/* Photo Cards Hover & Efeitos */
.photo-audit-card {
  transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
  border: 1px solid transparent;
}
.photo-audit-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 16px rgba(0,0,0,0.2) !important;
}
.hover-border-primary:hover {
  border-color: rgb(var(--v-theme-primary)) !important;
}

.group-hover-scale { transition: transform 0.3s ease; }
.photo-audit-card:hover .group-hover-scale { transform: scale(1.05); }

.group-hover-opacity-100 { opacity: 0; }
.photo-audit-card:hover .group-hover-opacity-100 { opacity: 1 !important; }

.backdrop-blur-sm { backdrop-filter: blur(4px); }

/* Lightbox Modal Estilos CFTV */
.glass-header { background: rgba(10,10,12,0.6); backdrop-filter: blur(12px); }
.shadow-neon-elegant { box-shadow: 0 12px 40px rgba(0,0,0,0.8), inset 0 0 0 1px rgba(255,255,255,0.05); }

.pulse-rec { animation: pulse-red 1.5s infinite; }
@keyframes pulse-red {
  0% { opacity: 1; }
  50% { opacity: 0.4; }
  100% { opacity: 1; }
}

/* Botões 3D */
.btn-3d { box-shadow: 0 3px 5px rgba(0,0,0,0.1), inset 0 2px 0 rgba(255,255,255,0.15) !important; text-transform: none !important; }
.btn-3d:active { transform: translateY(2px); box-shadow: 0 1px 2px rgba(0,0,0,0.1), inset 0 1px 0 rgba(255,255,255,0.1) !important; }
.chip-3d { box-shadow: 0 2px 4px rgba(0,0,0,0.2), inset 0 1px 0 rgba(255,255,255,0.1) !important; border-radius: 4px !important; }

/* Utilitários Extras */
.absolute { position: absolute; }
.inset-0 { top: 0; left: 0; right: 0; bottom: 0; }
.pointer-events-none { pointer-events: none; }
</style>
