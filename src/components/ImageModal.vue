<template>
  <v-dialog
    :model-value="props.show"
    :fullscreen="isMobile || scale > 1"
    :max-width="isMobile || scale > 1 ? undefined : '1200px'"
    transition="fade-transition"
    class="whatsapp-media-modal"
    z-index="9999999"
    @update:modelValue="closeModal"
  >
    <v-card
      class="media-viewer-root w-100 position-relative d-flex align-center justify-center overflow-hidden"
      :class="{ 'rounded-0': isMobile || scale > 1, 'rounded-xl elevation-24 desktop-modal': !isMobile && scale === 1 }"
      @touchstart="handleTouchStart"
      @touchmove="handleTouchMove"
      @touchend="handleTouchEnd"
    >
      <v-btn
        icon
        :color="uiVisible ? 'rgba(0,0,0,0.6)' : 'primary'"
        class="floating-ui-toggle text-white"
        size="large"
        elevation="8"
        @click.stop="uiVisible = !uiVisible"
      >
        <v-icon size="24">{{ uiVisible ? 'mdi-eye-off-outline' : 'mdi-eye-outline' }}</v-icon>
        <v-tooltip activator="parent" location="left">
          {{ uiVisible ? 'Ocultar Menus' : 'Mostrar Menus' }}
        </v-tooltip>
      </v-btn>

      <transition name="fade-slide-down">
        <div
          v-show="uiVisible"
          class="ui-overlay-top px-2 py-3 d-flex align-center w-100 position-absolute top-0 left-0"
          :class="isLightMode ? 'glass-header-light' : 'glass-header-dark'"
          @click.stop
        >
          <v-btn icon variant="text" :color="dynamicColor" @click="closeModal">
            <v-icon size="28">{{ isMobile ? 'mdi-arrow-left' : 'mdi-close' }}</v-icon>
          </v-btn>

          <div class="media-info ml-2 flex-grow-1 overflow-hidden d-flex flex-column justify-center">
            <div class="text-subtitle-1 font-weight-bold text-truncate lh-1" :class="dynamicTextColor">
              {{ extractedFileName }}
            </div>
            <div class="text-caption opacity-80 lh-1 mt-1 d-flex align-center" :class="dynamicTextColor">
              <span v-if="!isMobile" class="font-weight-bold mr-1">{{ fileExtension }}</span>
              <span v-if="!isMobile && fileSizeFormatted" class="mr-2">• {{ fileSizeFormatted }}</span>
              <span v-if="!isMobile">•</span>
              <span :class="{'ml-2': !isMobile}">MJ Process • Visualização Segura</span>
            </div>
          </div>

          <v-menu
            v-model="showShareMenu"
            :close-on-content-click="true"
            location="bottom end"
            transition="scale-transition"
            origin="top right"
          >
            <template v-slot:activator="{ props: menuProps }">
              <v-btn icon variant="text" :color="dynamicColor" class="mr-1" v-bind="menuProps" @click.stop>
                <v-icon>mdi-share</v-icon>
              </v-btn>
            </template>

            <v-list density="compact" class="bg-surface rounded-lg elevation-8 mt-1 py-1" min-width="220">
              <v-list-item @click="shareViaWhatsApp">
                <template v-slot:prepend><v-icon color="success" class="mr-3 opacity-80">mdi-whatsapp</v-icon></template>
                <v-list-item-title class="font-weight-medium text-body-2">Via WhatsApp</v-list-item-title>
              </v-list-item>
              <v-list-item @click="shareViaEmail">
                <template v-slot:prepend><v-icon color="info" class="mr-3 opacity-80">mdi-email-outline</v-icon></template>
                <v-list-item-title class="font-weight-medium text-body-2">Via E-mail</v-list-item-title>
              </v-list-item>
              <v-divider class="my-1"></v-divider>
              <v-list-item @click="forwardMediaInternal">
                <template v-slot:prepend><v-icon color="primary" class="mr-3 opacity-80">mdi-chat-processing-outline</v-icon></template>
                <v-list-item-title class="font-weight-medium text-body-2">Via Chat MJProcess</v-list-item-title>
              </v-list-item>
            </v-list>
          </v-menu>

          <v-btn icon variant="text" :color="dynamicColor" class="mr-1" @click.stop="copyMediaUrl">
            <v-icon>mdi-link-variant</v-icon>
          </v-btn>

          <v-btn icon variant="text" :color="dynamicColor" :href="currentImageUrl" target="_blank" download @click.stop>
            <v-icon>mdi-download</v-icon>
          </v-btn>
        </div>
      </transition>

      <div
        class="media-content-wrapper position-relative w-100"
        :class="{ 'fullscreen-wrapper': isMobile || scale > 1 }"
        :style="swipeStyle"
        @wheel.prevent="handleZoom"
      >
        <v-progress-circular
          v-if="isLoading"
          indeterminate
          color="white"
          size="48"
          class="position-absolute loading-spinner"
        ></v-progress-circular>

        <iframe
          v-if="isPdf"
          :src="currentImageUrl"
          class="pdf-element bg-grey-darken-4"
          @load="isLoading = false"
          @error="isLoading = false"
          frameborder="0"
        ></iframe>

        <video
          v-else-if="isVideo"
          ref="videoRef"
          :src="currentImageUrl"
          controls
          playsinline
          preload="metadata"
          class="media-element"
          @loadeddata="isLoading = false"
          @error="isLoading = false"
          @click.stop
        ></video>

        <img
          v-else
          :key="currentImageUrl"
          ref="imgRef"
          :src="currentImageUrl"
          :alt="extractedFileName"
          class="media-element"
          :class="{ 'is-dragging': isDragging, 'can-drag': scale > 1 }"
          :style="{ transform: `translate(${panX}px, ${panY}px) scale(${scale})` }"
          @mousedown.prevent="startDrag"
          @mousemove.prevent="doDrag"
          @mouseup="stopDrag"
          @mouseleave="stopDrag"
          @load="isLoading = false"
          @error="isLoading = false"
          draggable="false"
        />
      </div>

      <transition name="fade">
        <v-btn
          v-show="allImages.length > 1 && uiVisible && currentIndex > 0"
          icon="mdi-chevron-left"
          variant="flat"
          color="rgba(0,0,0,0.5)"
          class="nav-btn nav-left text-white"
          size="large"
          :ripple="false"
          @click.stop="prevImage"
        ></v-btn>
      </transition>

      <transition name="fade">
        <v-btn
          v-show="allImages.length > 1 && uiVisible && currentIndex < allImages.length - 1"
          icon="mdi-chevron-right"
          variant="flat"
          color="rgba(0,0,0,0.5)"
          class="nav-btn nav-right text-white"
          size="large"
          :ripple="false"
          @click.stop="nextImage"
        ></v-btn>
      </transition>

      <transition name="fade-slide-up">
        <div
          v-show="allImages.length > 1 && uiVisible"
          class="thumbnails-container w-100 position-absolute bottom-0 left-0 d-flex flex-column align-center pb-4 pt-10"
          @click.stop
        >
          <div class="text-white text-caption font-weight-black mb-2 opacity-90 drop-shadow-text">
            {{ currentIndex + 1 }} DE {{ allImages.length }}
          </div>
          <div class="d-flex gap-2 overflow-x-auto px-4 custom-scrollbar w-100 justify-center align-end" style="max-width: 100%;">
            <v-avatar
              v-for="(img, idx) in allImages"
              :key="idx"
              rounded="lg"
              size="64"
              class="thumbnail-item cursor-pointer flex-shrink-0 bg-grey-darken-4"
              :class="currentIndex === idx ? 'thumbnail-active' : 'opacity-50 hover-opacity-100'"
              @click="goToImage(idx)"
            >
              <v-img :src="img" cover></v-img>
            </v-avatar>
          </div>
        </div>
      </transition>
    </v-card>

    <v-snackbar v-model="showSnackbar" :timeout="2000" color="grey-darken-4" location="bottom center" z-index="9999999">
      Link da mídia copiado
    </v-snackbar>
  </v-dialog>
</template>

<script setup lang="ts">
import { defineProps, defineEmits, ref, computed, watch, onMounted, onUnmounted } from 'vue';
import { useThemeStore } from '@/stores/theme';

const props = defineProps({
  show: Boolean,
  imageUrl: String,
  images: { type: Array, default: () => [] },
  fileName: String,
});

const emit = defineEmits(['close', 'forward']);

const themeStore = useThemeStore();
const imgRef = ref<HTMLImageElement | null>(null);
const videoRef = ref<HTMLVideoElement | null>(null);
const isLoading = ref(true);
const showSnackbar = ref(false);
const showShareMenu = ref(false);
const isMobile = ref(window.innerWidth <= 768);
const fileSizeFormatted = ref('');

// ==========================================
// CONTROLE DE INTERFACE (MANUAL)
// ==========================================
const uiVisible = ref(true);

// ==========================================
// ZOOM E PAN (Movimentação)
// ==========================================
const scale = ref(1);
const panX = ref(0);
const panY = ref(0);
const isDragging = ref(false);
const startX = ref(0);
const startY = ref(0);

const handleZoom = (e: WheelEvent) => {
  if (isPdf.value || isVideo.value) return;
  const zoomFactor = 0.15;
  let newScale = scale.value + (e.deltaY > 0 ? -zoomFactor : zoomFactor);

  if (newScale <= 1) {
    newScale = 1;
    panX.value = 0;
    panY.value = 0;
  }

  if (newScale > 6) newScale = 6;
  scale.value = newScale;
};

const startDrag = (e: MouseEvent) => {
  if (scale.value <= 1) return;
  isDragging.value = true;
  startX.value = e.clientX - panX.value;
  startY.value = e.clientY - panY.value;
};

const doDrag = (e: MouseEvent) => {
  if (!isDragging.value) return;
  panX.value = e.clientX - startX.value;
  panY.value = e.clientY - startY.value;
};

const stopDrag = () => {
  isDragging.value = false;
};

const resetZoom = () => {
  scale.value = 1;
  panX.value = 0;
  panY.value = 0;
};

// ==========================================
// GERENCIAMENTO DO CARROSSEL
// ==========================================
const currentIndex = ref(0);

const allImages = computed(() => {
  let list: string[] = [];
  if (props.images && props.images.length > 0) {
    list = props.images as string[];
  } else if (props.imageUrl) {
    list = [props.imageUrl];
  }
  return Array.from(new Set(list));
});

const currentImageUrl = computed(() => allImages.value[currentIndex.value] || '');

const preloadImages = () => {
  if (!allImages.value.length) return;
  const nextIdx = currentIndex.value + 1;
  const prevIdx = currentIndex.value - 1;
  if (nextIdx < allImages.value.length) new Image().src = allImages.value[nextIdx];
  if (prevIdx >= 0) new Image().src = allImages.value[prevIdx];
};

const goToImage = (idx: number) => {
  if (currentIndex.value === idx) return;
  isLoading.value = true;
  fileSizeFormatted.value = '';
  currentIndex.value = idx;
  resetZoom();
  if (!isMobile.value) fetchFileSize(currentImageUrl.value);
};

const nextImage = () => {
  if (currentIndex.value < allImages.value.length - 1) goToImage(currentIndex.value + 1);
};

const prevImage = () => {
  if (currentIndex.value > 0) goToImage(currentIndex.value - 1);
};

watch(currentIndex, preloadImages);

// ==========================================
// TEMAS DINÂMICOS
// ==========================================
const isLightMode = computed(() => themeStore.currentMode === 'light');
const dynamicColor = computed(() => isLightMode.value ? 'black' : 'white');
const dynamicTextColor = computed(() => isLightMode.value ? 'text-black' : 'text-white');

// ==========================================
// SWIPE PARA FECHAR (MOBILE)
// ==========================================
const swipeOffset = ref(0);
const startTouchY = ref(0);
const isSwiping = ref(false);
const SWIPE_THRESHOLD = 120;

const handleTouchStart = (e: TouchEvent) => {
  if (isPdf.value || !isMobile.value || showShareMenu.value || scale.value > 1) return;
  startTouchY.value = e.touches[0].clientY;
  isSwiping.value = true;
};

const handleTouchMove = (e: TouchEvent) => {
  if (!isSwiping.value || isPdf.value || !isMobile.value || scale.value > 1) return;
  const currentY = e.touches[0].clientY;
  swipeOffset.value = currentY - startTouchY.value;
};

const handleTouchEnd = () => {
  if (!isSwiping.value || isPdf.value || !isMobile.value || scale.value > 1) return;
  isSwiping.value = false;

  if (Math.abs(swipeOffset.value) > SWIPE_THRESHOLD) {
    closeModal();
  } else {
    swipeOffset.value = 0;
  }
};

const swipeStyle = computed(() => {
  if (!swipeOffset.value || !isMobile.value || scale.value > 1) return { transition: 'transform 0.3s cubic-bezier(0.2, 0.8, 0.2, 1)', transform: 'translateY(0)' };
  return {
    transition: 'none',
    transform: `translateY(${swipeOffset.value}px)`,
    opacity: 1 - (Math.abs(swipeOffset.value) / (window.innerHeight / 1.5))
  };
});

// ==========================================
// PROCESSAMENTO DE ARQUIVO
// ==========================================
const isVideo = computed(() => /\.(mp4|webm|ogg|mov)(\?.*)?$/i.test(currentImageUrl.value || ''));
const isPdf = computed(() => /\.(pdf)(\?.*)?$/i.test(currentImageUrl.value || ''));

const extractedFileName = computed(() => {
  if (props.fileName && allImages.value.length <= 1) return props.fileName;
  if (!currentImageUrl.value) return 'Mídia';
  try {
    let name = currentImageUrl.value.split('/').pop() || 'Mídia';
    name = decodeURIComponent(name);
    return name.includes('_') ? name.split('_').slice(1).join('_') : name;
  } catch (e) {
    return 'Mídia';
  }
});

const fileExtension = computed(() => {
  const name = extractedFileName.value;
  const ext = name.split('.').pop();
  return (ext && ext.length <= 4) ? ext.toUpperCase() : (isVideo.value ? 'VÍDEO' : 'IMAGEM');
});

const fetchFileSize = async (url: string) => {
  if (!url || url.startsWith('data:')) return;
  try {
    const res = await fetch(url, { method: 'HEAD' });
    const bytes = res.headers.get('content-length');
    if (bytes) {
      const size = parseInt(bytes, 10);
      fileSizeFormatted.value = size < 1048576
        ? (size / 1024).toFixed(1) + ' KB'
        : (size / 1048576).toFixed(2) + ' MB';
    }
  } catch (e) {
    fileSizeFormatted.value = '';
  }
};

// ==========================================
// AÇÕES DE COMPARTILHAMENTO
// ==========================================
const shareText = computed(() => `Confira este arquivo que compartilhei com você:\n${currentImageUrl.value}`);
const shareViaWhatsApp = () => window.open(`https://wa.me/?text=${encodeURIComponent(shareText.value)}`, '_blank');
const shareViaEmail = () => window.location.href = `mailto:?subject=${encodeURIComponent('Arquivo compartilhado via MJ Process')}&body=${encodeURIComponent(shareText.value)}`;

const forwardMediaInternal = () => {
  emit('forward', { url: currentImageUrl.value, type: isVideo.value ? 'video' : isPdf.value ? 'file' : 'image', name: extractedFileName.value });
  closeModal();
};

const copyMediaUrl = async () => {
  if (currentImageUrl.value) {
    try {
      await navigator.clipboard.writeText(currentImageUrl.value);
      showSnackbar.value = true;
    } catch (err) {}
  }
};

const closeModal = () => {
  if (videoRef.value) videoRef.value.pause();
  swipeOffset.value = 0;
  showShareMenu.value = false;
  resetZoom();
  emit('close');
};

// ==========================================
// CICLO DE VIDA
// ==========================================
watch(() => props.show, (isVisible) => {
  if (isVisible) {
    let startIdx = 0;
    if (props.imageUrl && allImages.value.length > 0) {
      const found = allImages.value.indexOf(props.imageUrl);
      if (found > -1) startIdx = found;
    }
    currentIndex.value = startIdx;
    isLoading.value = true;
    swipeOffset.value = 0;
    showShareMenu.value = false;
    uiVisible.value = true;
    resetZoom();
    preloadImages();

    if (!isMobile.value && currentImageUrl.value) {
      fetchFileSize(currentImageUrl.value);
    }
  } else {
    if (videoRef.value) videoRef.value.pause();
  }
});

const updateMobileStatus = () => { isMobile.value = window.innerWidth <= 768; };
onMounted(() => window.addEventListener('resize', updateMobileStatus));
onUnmounted(() => window.removeEventListener('resize', updateMobileStatus));
</script>

<style scoped lang="scss">
:deep(.v-overlay__content) {
  margin: 0 !important;
  border-radius: 0 !important;
}

.whatsapp-media-modal :deep(.v-overlay__scrim) {
  background: rgba(0, 0, 0, 0.4); /* Fundo externo leve e transparente */
}

/* O MODAL DE VOLTA À FORMA ORIGINAL
  Fundo Desfocado (Blur) para dar o visual de vidro fosco ao invés de tela preta sólida
*/
.media-viewer-root {
  background-color: rgba(20, 20, 20, 0.65) !important;
  backdrop-filter: blur(16px);
  -webkit-backdrop-filter: blur(16px);
  overflow: hidden;
  user-select: none;
  transition: all 0.3s ease; /* Transição suave caso mude pra fullscreen */
}

.desktop-modal {
  /* Volta as bordas arredondadas e o brilho */
  border: 1px solid rgba(255, 255, 255, 0.08);
}

/* BOTÃO FLUTUANTE DE UI */
.floating-ui-toggle {
  position: absolute;
  top: 90px; /* Logo abaixo do header */
  right: 20px;
  z-index: 100;
  transition: transform 0.2s ease, opacity 0.2s ease;
}
.floating-ui-toggle:hover {
  transform: scale(1.1);
}

/* O SEGREDO DA ESTABILIDADE DO CARROSSEL:
  Definimos uma altura fixa para o container. Assim o modal nunca
  fica encolhendo ou esticando quando a foto muda.
*/
.media-content-wrapper {
  height: 85vh; /* Altura fixa garantida no desktop */
  display: flex;
  align-items: center;
  justify-content: center;
  overflow: hidden;
}

/* Quando entra em fullscreen via zoom, a altura vira 100vh */
.fullscreen-wrapper {
  height: 100vh !important;
}

/* IMAGEM RESPONSIVA:
  Sempre será exibida inteira, sem cortar, respeitando a altura do modal
*/
.media-element {
  max-width: 100%;
  max-height: 100%;
  object-fit: contain; /* Nunca corta a imagem */
  display: block;
  margin: auto;
  transition: transform 0.15s ease-out;
  will-change: transform;
}

.can-drag {
  cursor: grab !important;
}

.is-dragging {
  cursor: grabbing !important;
  transition: none !important;
}

video.media-element {
  min-width: 50vw;
  min-height: 50vh;
}

.pdf-element {
  width: 85vw;
  height: 90vh;
  max-width: 1200px;
  border: none;
}

/* ===================================== */
/* MENUS E INTERFACE */
/* ===================================== */

.ui-overlay-top {
  height: 72px;
  z-index: 50;
  transition: background-color 0.3s ease;
}

.glass-header-dark {
  background: rgba(15, 15, 15, 0.7);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  border-bottom: 1px solid rgba(255, 255, 255, 0.05);
}

.glass-header-light {
  background: rgba(255, 255, 255, 0.8);
  backdrop-filter: blur(16px);
  -webkit-backdrop-filter: blur(16px);
  border-bottom: 1px solid rgba(0, 0, 0, 0.08);
}

.lh-1 { line-height: 1.2; }

/* ANIMAÇÕES */
.fade-slide-down-enter-active,
.fade-slide-down-leave-active {
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}
.fade-slide-down-enter-from,
.fade-slide-down-leave-to {
  opacity: 0;
  transform: translateY(-100%);
}

.fade-slide-up-enter-active,
.fade-slide-up-leave-active {
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}
.fade-slide-up-enter-from,
.fade-slide-up-leave-to {
  opacity: 0;
  transform: translateY(100%);
}

.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.3s ease;
}
.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}

.loading-spinner {
  z-index: 10;
  pointer-events: none;
}

/* NAVEGAÇÃO */
.nav-btn {
  position: absolute;
  top: 50%;
  transform: translateY(-50%);
  z-index: 20;
  backdrop-filter: blur(4px);
  border: 1px solid rgba(255,255,255,0.1);
  transition: transform 0.2s ease, background 0.2s ease;
}
.nav-btn:hover { background: rgba(0,0,0,0.8) !important; transform: translateY(-50%) scale(1.1); }
.nav-left { left: 16px; }
.nav-right { right: 16px; }

/* MINIATURAS */
.thumbnails-container {
  background: linear-gradient(to top, rgba(0,0,0,0.85) 0%, rgba(0,0,0,0.4) 70%, transparent 100%);
  z-index: 30;
  pointer-events: auto;
}

.thumbnail-item {
  border: 2px solid transparent;
  transition: all 0.25s cubic-bezier(0.2, 0.8, 0.2, 1);
}

.thumbnail-active {
  border-color: #fff;
  opacity: 1 !important;
  transform: translateY(-6px) scale(1.05);
  box-shadow: 0 4px 15px rgba(0,0,0,0.6);
}

.hover-opacity-100:hover { opacity: 0.8 !important; }
.drop-shadow-text { text-shadow: 0 2px 4px rgba(0,0,0,0.8); letter-spacing: 1px; }

.custom-scrollbar::-webkit-scrollbar { height: 4px; }
.custom-scrollbar::-webkit-scrollbar-thumb {
  background: rgba(255,255,255,0.25);
  border-radius: 4px;
}
</style>
