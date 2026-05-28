<template>
  <v-dialog
    :model-value="show"
    @update:model-value="handleUpdateShow"
    :fullscreen="isMobile"
    :max-width="isMobile ? undefined : 900"
    persistent
    transition="dialog-bottom-transition"
    style="z-index: 9999999;"
  >
    <v-card class="upload-preview-card d-flex flex-column bg-surface overflow-hidden"
            :class="{'rounded-0 h-100': isMobile, 'rounded-xl desktop-modal': !isMobile}">

      <v-toolbar color="rgba(0,0,0,0.65)" density="comfortable" class="flex-shrink-0 absolute-toolbar text-white" elevation="0">
        <v-btn icon="mdi-close" variant="text" color="white" @click="cancel"></v-btn>
        <v-toolbar-title class="font-weight-medium text-body-1 px-1">
          {{ files.length > 1 ? `${currentIndex + 1} de ${files.length} selecionados` : 'Enviar arquivo' }}
        </v-toolbar-title>
        <v-spacer></v-spacer>
      </v-toolbar>

      <div class="preview-main-area flex-grow-1 position-relative d-flex align-center justify-center w-100 overflow-hidden">

        <div class="transparent-pattern-bg"></div>

        <v-btn v-if="files.length > 1 && currentIndex > 0 && !isMobile" icon="mdi-chevron-left" class="nav-btn nav-left elevation-4" color="surface" @click="prevFile"></v-btn>

        <transition name="fade" mode="out-in">
          <div :key="currentIndex" class="media-render-container w-100 h-100 d-flex align-center justify-center pa-4 pa-md-8">

            <img v-if="currentFileType === 'image'" :src="currentFileUrl" class="preview-media elevation-10 rounded-lg" alt="Preview" />

            <video v-else-if="currentFileType === 'video'" :src="currentFileUrl" controls class="preview-media elevation-10 rounded-lg" playsinline autoplay></video>

            <div v-else class="document-preview d-flex flex-column align-center justify-center pa-8 rounded-xl elevation-10 bg-surface-variant w-100" style="max-width: 400px; z-index: 2;">
              <div class="doc-icon-wrapper bg-error rounded-circle d-flex align-center justify-center mb-6 elevation-4">
                <v-icon size="64" color="white">mdi-file-document-outline</v-icon>
              </div>
              <h3 class="text-h6 font-weight-bold text-center text-truncate w-100 px-4 mb-2 text-high-emphasis">{{ currentFile?.name }}</h3>
              <div class="d-flex align-center gap-2 text-medium-emphasis">
                <v-chip size="small" color="primary" variant="flat">{{ currentFileExt }}</v-chip>
                <span class="text-body-2 font-weight-medium">{{ formatSize(currentFile?.size || 0) }}</span>
              </div>
            </div>

          </div>
        </transition>

        <v-btn v-if="files.length > 1 && currentIndex < files.length - 1 && !isMobile" icon="mdi-chevron-right" class="nav-btn nav-right elevation-4" color="surface" @click="nextFile"></v-btn>
      </div>

      <div v-if="files.length > 1" class="thumbnail-carousel bg-grey-darken-4 py-3 px-4 d-flex align-center gap-3 overflow-x-auto border-top-dark">
        <div
          v-for="(file, index) in files"
          :key="'thumb-'+index"
          class="thumbnail-item cursor-pointer rounded-lg overflow-hidden position-relative flex-shrink-0"
          :class="{'active-thumb elevation-4': currentIndex === index}"
          @click="currentIndex = index"
        >
          <v-img v-if="getFileType(file) === 'image'" :src="getObjectUrl(file)" cover class="w-100 h-100"></v-img>

          <div v-else-if="getFileType(file) === 'video'" class="w-100 h-100 bg-black d-flex align-center justify-center position-relative">
             <video :src="getObjectUrl(file)" class="w-100 h-100" style="object-fit: cover; opacity: 0.5;"></video>
             <v-icon color="white" size="24" class="position-absolute">mdi-play-circle</v-icon>
          </div>

          <div v-else class="w-100 h-100 bg-surface-variant d-flex flex-column align-center justify-center">
            <v-icon color="error" size="20" class="mb-1">mdi-file-document</v-icon>
            <span class="text-caption font-weight-bold" style="font-size: 0.6rem !important;">{{ getFileExtension(file.name) }}</span>
          </div>
        </div>
      </div>

      <div class="preview-footer bg-surface pa-3 flex-shrink-0 d-flex align-center shadow-top">
        <v-text-field
          v-model="caption"
          placeholder="Adicione uma legenda..."
          variant="solo-filled"
          flat
          density="comfortable"
          hide-details
          rounded="pill"
          class="caption-input flex-grow-1 mr-3"
          @keydown.enter.prevent="send"
          autofocus
        >
          <template v-slot:prepend-inner>
             <v-icon color="medium-emphasis" class="ml-2">mdi-text</v-icon>
          </template>
        </v-text-field>

        <v-btn color="#00a884" icon="mdi-send" size="large" elevation="3" class="send-fab flex-shrink-0 text-white" @click="send" :loading="isSending"></v-btn>
      </div>

    </v-card>
  </v-dialog>
</template>

<script setup lang="ts">
import { ref, computed, watch, onBeforeUnmount } from 'vue';

const props = defineProps<{
  show: boolean;
  files: File[];
  isMobile: boolean;
  isSending?: boolean;
}>();

const emit = defineEmits(['update:show', 'cancel', 'send']);

const caption = ref('');
const currentIndex = ref(0);

// Cache de URLs para evitar vazamento de memória (Memory Leak)
const urlCache = new Map<File, string>();

const currentFile = computed(() => props.files[currentIndex.value] || null);
const currentFileType = computed(() => currentFile.value ? getFileType(currentFile.value) : '');
const currentFileUrl = computed(() => currentFile.value ? getObjectUrl(currentFile.value) : '');
const currentFileExt = computed(() => currentFile.value ? getFileExtension(currentFile.value.name) : '');

const handleUpdateShow = (val: boolean) => {
  if (!val) cancel();
};

const getObjectUrl = (file: File) => {
  if (!urlCache.has(file)) {
    urlCache.set(file, URL.createObjectURL(file));
  }
  return urlCache.get(file) as string;
};

const revokeAllUrls = () => {
  urlCache.forEach(url => URL.revokeObjectURL(url));
  urlCache.clear();
};

// Reinicia os estados toda vez que o modal abre com novos arquivos
watch(() => props.show, (newVal) => {
  if (newVal) {
    currentIndex.value = 0;
    caption.value = '';
  } else {
    // Dá um tempinho antes de revogar para a animação de fechamento não bugar a imagem
    setTimeout(() => { revokeAllUrls(); }, 300);
  }
});

onBeforeUnmount(() => {
  revokeAllUrls();
});

const getFileType = (file: File) => {
  if (file.type.startsWith('image/')) return 'image';
  if (file.type.startsWith('video/')) return 'video';
  return 'document';
};

const formatSize = (bytes: number) => {
  if (bytes === 0) return '0 Bytes';
  const k = 1024;
  const sizes = ['B', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
};

const getFileExtension = (filename: string) => {
  return filename.split('.').pop()?.toUpperCase() || 'FILE';
};

const nextFile = () => {
  if (currentIndex.value < props.files.length - 1) currentIndex.value++;
};

const prevFile = () => {
  if (currentIndex.value > 0) currentIndex.value--;
};

const cancel = () => {
  emit('update:show', false);
  emit('cancel');
};

const send = () => {
  emit('send', { files: props.files, caption: caption.value.trim() });
};
</script>

<style scoped lang="scss">
.upload-preview-card {
  box-shadow: 0 12px 40px rgba(0,0,0,0.4) !important;
}

/* Tamanho fixo elegante no desktop */
.desktop-modal {
  height: 85vh;
  max-height: 900px;
}

.absolute-toolbar {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  z-index: 10;
  backdrop-filter: blur(8px);
  -webkit-backdrop-filter: blur(8px);
}

.preview-main-area {
  background-color: #0b141a; /* Fundo escuro estilo whatsapp */
}

/* Textura quadriculada para ver imagens com fundo transparente perfeitamente */
.transparent-pattern-bg {
  position: absolute;
  top: 0; left: 0; right: 0; bottom: 0;
  background-image: linear-gradient(45deg, #1e1e1e 25%, transparent 25%),
                    linear-gradient(-45deg, #1e1e1e 25%, transparent 25%),
                    linear-gradient(45deg, transparent 75%, #1e1e1e 75%),
                    linear-gradient(-45deg, transparent 75%, #1e1e1e 75%);
  background-size: 20px 20px;
  background-position: 0 0, 0 10px, 10px -10px, -10px 0px;
  opacity: 0.5;
  z-index: 1;
}

.media-render-container {
  z-index: 2; /* Fica acima da textura */
}

.preview-media {
  max-width: 100%;
  max-height: 100%;
  object-fit: contain;
  background-color: transparent;
}

.doc-icon-wrapper {
  width: 100px;
  height: 100px;
}

.nav-btn {
  position: absolute;
  top: 50%;
  transform: translateY(-50%);
  z-index: 5;
  opacity: 0.7;
  transition: opacity 0.2s;
  &:hover { opacity: 1; }
}
.nav-left { left: 24px; }
.nav-right { right: 24px; }

.thumbnail-carousel {
  height: 88px;
  border-top: 1px solid rgba(255,255,255,0.1);
  &::-webkit-scrollbar { height: 6px; }
  &::-webkit-scrollbar-thumb { background-color: rgba(255,255,255,0.2); border-radius: 6px; }
}

.thumbnail-item {
  width: 64px;
  height: 64px;
  border: 2px solid transparent;
  opacity: 0.5;
  transition: all 0.2s ease;
  background-color: #111;

  &.active-thumb {
    opacity: 1;
    border-color: rgb(var(--v-theme-primary));
    transform: scale(1.08);
  }
}

.shadow-top {
  box-shadow: 0 -4px 16px rgba(0,0,0,0.05);
  z-index: 5;
}

.caption-input {
  :deep(.v-field) {
    background-color: rgba(var(--v-theme-surface-variant), 0.5) !important;
  }
  :deep(.v-field__input) {
    padding-top: 12px;
    padding-bottom: 12px;
  }
}

.send-fab {
  background-color: #00a884 !important;
  color: white !important;
  transition: transform 0.2s;
  &:hover { transform: scale(1.05); }
}

/* Transições Suaves */
.fade-enter-active, .fade-leave-active {
  transition: opacity 0.25s ease, transform 0.25s ease;
}
.fade-enter-from, .fade-leave-to {
  opacity: 0;
  transform: scale(0.98);
}
</style>
