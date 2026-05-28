<template>
  <div v-if="mode === 'settings'" class="popup-block-settings d-flex flex-column gap-6">

    <div class="config-group">
      <div class="config-header d-flex align-center gap-2">
        <v-icon size="16" color="primary">mdi-message-badge-outline</v-icon>
        Aparência do Popup
      </div>
      <div class="d-flex flex-column gap-4">
        <div>
          <label class="inspector-label">Título de Chamada</label>
          <input type="text" v-model="block.settings.title" class="modern-input" placeholder="Ex: Ganhe 10% de Desconto" />
        </div>

        <div>
          <label class="inspector-label">Texto de Convite</label>
          <textarea v-model="block.settings.text" rows="3" class="modern-input" style="resize:vertical;" placeholder="Cadastre-se para receber novidades..."></textarea>
        </div>

        <div>
          <label class="inspector-label">Imagem de Destaque (Lateral)</label>
          <div v-if="block.settings.image_url" class="rounded-lg border overflow-hidden bg-background d-flex flex-column mb-3 shadow-sm">
            <img :src="block.settings.image_url" style="height: 120px; object-fit: cover;" />
            <v-btn size="small" color="error" variant="flat" class="rounded-0 text-none" block @click="block.settings.image_url = ''">
              Remover Imagem
            </v-btn>
          </div>
          <v-btn block color="primary" variant="tonal" class="text-none font-weight-bold rounded-lg border-dashed border-primary" style="border-width: 1px;" prepend-icon="mdi-cloud-upload-outline" @click="$emit('upload', 'image_url')">
            {{ block.settings.image_url ? 'Trocar Imagem' : 'Upload de Imagem' }}
          </v-btn>
        </div>

        <div>
          <label class="inspector-label">Atraso para abrir (Segundos)</label>
          <input type="number" v-model.number="block.settings.delay" min="0" class="modern-input" />
          <p class="text-[10px] text-medium-emphasis mt-1 m-0">Tempo após o carregamento da página.</p>
        </div>
      </div>
    </div>

    <div class="config-group">
      <div class="config-header d-flex align-center gap-2">
        <v-icon size="16" color="primary">mdi-palette</v-icon>
        Ação e Cores
      </div>
      <div class="d-flex flex-column gap-4">
        <div>
          <label class="inspector-label">Texto do Botão / Form</label>
          <input type="text" v-model="block.settings.button_text" class="modern-input" placeholder="Ex: Quero o Desconto" />
        </div>

        <div class="d-flex align-center gap-3">
          <label class="inspector-label m-0 flex-grow-1">Cor do Texto</label>
          <input type="color" v-model="block.settings.text_color" class="color-picker" />
        </div>

        <div class="d-flex align-center gap-3">
          <label class="inspector-label m-0 flex-grow-1">Cor de Fundo</label>
          <input type="color" v-model="block.settings.bg_color" class="color-picker" />
        </div>

        <div class="d-flex align-center gap-3">
          <label class="inspector-label m-0 flex-grow-1">Cor do Botão</label>
          <input type="color" v-model="block.settings.button_color" class="color-picker" />
        </div>
      </div>
    </div>
  </div>

  <div v-else-if="mode === 'preview' && isActive" class="preview-popup-overlay">
    <div class="preview-popup-card shadow-2xl d-flex overflow-hidden rounded-xl animate-popup" :style="{ backgroundColor: block.settings.bg_color || '#ffffff' }">

      <div v-if="block.settings.image_url"
           class="popup-img"
           :style="{ backgroundImage: `url('${utils.getOptimizedUrl(block.settings.image_url, 800)}')` }">
      </div>

      <div class="pa-10 d-flex flex-column justify-center flex-grow-1 text-center position-relative content-side">
        <v-icon class="position-absolute top-4 right-4 text-medium-emphasis cursor-pointer hover-rotate transition-transform">mdi-close</v-icon>

        <h2 class="text-h4 font-weight-black mb-4 tracking-tighter" :style="{ color: block.settings.text_color || '#000000' }">
          {{ block.settings.title || '10% OFF' }}
        </h2>

        <p class="text-body-1 mb-8 opacity-80" :style="{ color: block.settings.text_color || '#000000', lineHeight: '1.6' }">
          {{ block.settings.text || 'Cadastre-se na nossa newsletter para receber novidades e descontos exclusivos na sua primeira compra.' }}
        </p>

        <v-btn :color="block.settings.button_color || 'black'"
               size="x-large"
               class="rounded-lg font-weight-bold px-10 text-none elevation-0 shadow-sm transition-transform hover-scale"
               :class="utils.getTextColorClass(block.settings.button_color, 'black')">
          {{ block.settings.button_text || 'Inscrever-se' }}
        </v-btn>

        <span class="text-[10px] mt-4 opacity-50 cursor-pointer hover-underline" :style="{ color: block.settings.text_color || '#000000' }">
          Não, obrigado. Quero pagar o preço cheio.
        </span>
      </div>

    </div>
  </div>
</template>

<script setup lang="ts">
import { inject } from 'vue'

const props = defineProps<{
  mode: 'settings' | 'preview'
  block: any
  isActive?: boolean
}>()

const emit = defineEmits(['upload', 'click'])

// Injeta os utilitários providenciados pelo BuilderTab.vue pai
const utils = inject<any>('builderUtils')
</script>

<style scoped>
/* ==========================================
   ESTILOS DO INSPECTOR (SETTINGS)
   ========================================== */
.config-group { border: 1px solid rgba(var(--v-theme-on-surface), 0.08); border-radius: 12px; padding: 20px; background: rgba(var(--v-theme-surface), 0.8); backdrop-filter: blur(8px); }
.config-header { font-size: 12px; font-weight: 800; margin-bottom: 20px; color: rgb(var(--v-theme-on-surface)); text-transform: uppercase; letter-spacing: 0.08em; border-bottom: 1px solid rgba(var(--v-theme-on-surface), 0.06); padding-bottom: 12px; }
.inspector-label { display: block; font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.06em; margin-bottom: 8px; color: rgba(var(--v-theme-on-surface), 0.7); }

.modern-input { min-height: 44px; width: 100%; border: 1px solid rgba(var(--v-theme-on-surface), 0.15); background: rgb(var(--v-theme-surface)); border-radius: 8px; transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1); font-size: 14px; color: rgb(var(--v-theme-on-surface)); padding: 0 14px; box-shadow: inset 0 1px 2px rgba(0,0,0,0.03); }
.modern-input:focus { border-color: rgb(var(--v-theme-primary)); box-shadow: 0 0 0 4px rgba(var(--v-theme-primary), 0.15); outline: none; }
textarea.modern-input { padding-top: 12px; line-height: 1.5; }

.color-picker { width: 100%; height: 44px; border-radius: 8px; border: 1px solid rgba(var(--v-theme-on-surface), 0.15); padding: 4px; cursor: pointer; background: rgb(var(--v-theme-surface)); transition: border-color 0.2s; }
.color-picker:hover { border-color: rgb(var(--v-theme-primary)); }

/* ==========================================
   ESTILOS DO PREVIEW CANVAS (OVERLAY)
   ========================================== */
.preview-popup-overlay {
  position: absolute;
  inset: 0;
  z-index: 50;
  background: rgba(15, 23, 42, 0.6);
  backdrop-filter: blur(8px);
  display: flex;
  align-items: center;
  justify-content: center;
  pointer-events: none; /* Deixa os cliques passarem se não estiver ativo */
}

/* O card captura os cliques para simular a interação */
.preview-popup-card {
  width: 750px;
  max-width: 90%;
  min-height: 400px;
  pointer-events: auto;
  box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.35);
  border: 1px solid rgba(255,255,255,0.1);
}

.popup-img {
  width: 45%;
  background-size: cover;
  background-position: center;
  position: relative;
}

/* Pseudo-elemento para dar um leve gradiente na transição da imagem pro texto */
.popup-img::after {
  content: '';
  position: absolute;
  top: 0; right: 0; bottom: 0; left: 0;
  background: linear-gradient(to right, rgba(0,0,0,0) 80%, rgba(0,0,0,0.05) 100%);
}

.content-side {
  width: 55%;
}

.hover-rotate:hover { transform: rotate(90deg); }
.hover-scale:hover { transform: scale(1.03); }
.hover-underline:hover { text-decoration: underline; opacity: 0.8 !important; }

.animate-popup {
  animation: popupScale 0.4s cubic-bezier(0.175, 0.885, 0.32, 1.275) forwards;
}

@keyframes popupScale {
  0% { transform: scale(0.9); opacity: 0; }
  100% { transform: scale(1); opacity: 1; }
}

@media(max-width: 600px) {
  .preview-popup-card { flex-direction: column; width: 340px; }
  .popup-img { width: 100%; height: 200px; }
  .content-side { width: 100%; padding: 32px 24px !important; }
}
</style>
