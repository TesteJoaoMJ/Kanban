<template>
  <div v-if="mode === 'settings'" class="dual-banner-settings d-flex flex-column gap-6">

    <div class="config-group">
      <div class="config-header d-flex align-center gap-2">
        <v-icon size="16" color="primary">mdi-image-multiple-outline</v-icon>
        Banner 1 (Esquerda)
      </div>
      <div class="d-flex flex-column gap-4">

        <div>
          <label class="inspector-label">Imagem de Fundo</label>
          <div v-if="block.settings.image_1" class="rounded-lg border overflow-hidden bg-background d-flex flex-column mb-3 shadow-sm">
            <img :src="block.settings.image_1" style="height: 100px; width: 100%; object-fit: cover;" />
            <v-btn size="x-small" color="error" variant="flat" class="rounded-0 text-none" block @click="block.settings.image_1 = ''">Remover Imagem</v-btn>
          </div>
          <v-btn v-else block color="primary" variant="tonal" class="text-none font-weight-bold rounded-lg border-dashed border-primary" style="border-width: 1px;" prepend-icon="mdi-cloud-upload-outline" @click="$emit('upload', 'image_1')">
            Upload Banner 1
          </v-btn>
        </div>

        <div>
          <label class="inspector-label">Título Principal</label>
          <input type="text" v-model="block.settings.title_1" class="modern-input" placeholder="Ex: Coleção Verão" />
        </div>

        <div>
          <label class="inspector-label">Subtítulo (Opcional)</label>
          <input type="text" v-model="block.settings.subtitle_1" class="modern-input" placeholder="Ex: Novidades" />
        </div>

        <div class="d-flex gap-3">
          <div class="flex-grow-1">
            <label class="inspector-label">Texto do Botão</label>
            <input type="text" v-model="block.settings.button_text_1" class="modern-input" :placeholder="block.settings.button_text || 'Ex: Explorar'" />
          </div>
          <div class="flex-grow-1">
            <label class="inspector-label">Link</label>
            <input type="text" v-model="block.settings.link_1" class="modern-input" placeholder="Ex: /verao" />
          </div>
        </div>

      </div>
    </div>

    <div class="config-group">
      <div class="config-header d-flex align-center gap-2">
        <v-icon size="16" color="primary">mdi-image-multiple</v-icon>
        Banner 2 (Direita)
      </div>
      <div class="d-flex flex-column gap-4">

        <div>
          <label class="inspector-label">Imagem de Fundo</label>
          <div v-if="block.settings.image_2" class="rounded-lg border overflow-hidden bg-background d-flex flex-column mb-3 shadow-sm">
            <img :src="block.settings.image_2" style="height: 100px; width: 100%; object-fit: cover;" />
            <v-btn size="x-small" color="error" variant="flat" class="rounded-0 text-none" block @click="block.settings.image_2 = ''">Remover Imagem</v-btn>
          </div>
          <v-btn v-else block color="primary" variant="tonal" class="text-none font-weight-bold rounded-lg border-dashed border-primary" style="border-width: 1px;" prepend-icon="mdi-cloud-upload-outline" @click="$emit('upload', 'image_2')">
            Upload Banner 2
          </v-btn>
        </div>

        <div>
          <label class="inspector-label">Título Principal</label>
          <input type="text" v-model="block.settings.title_2" class="modern-input" placeholder="Ex: Coleção Inverno" />
        </div>

        <div>
          <label class="inspector-label">Subtítulo (Opcional)</label>
          <input type="text" v-model="block.settings.subtitle_2" class="modern-input" placeholder="Ex: Ofertas" />
        </div>

        <div class="d-flex gap-3">
          <div class="flex-grow-1">
            <label class="inspector-label">Texto do Botão</label>
            <input type="text" v-model="block.settings.button_text_2" class="modern-input" :placeholder="block.settings.button_text || 'Ex: Explorar'" />
          </div>
          <div class="flex-grow-1">
            <label class="inspector-label">Link</label>
            <input type="text" v-model="block.settings.link_2" class="modern-input" placeholder="Ex: /inverno" />
          </div>
        </div>

      </div>
    </div>

    <div class="config-group">
      <div class="config-header d-flex align-center gap-2">
        <v-icon size="16" color="primary">mdi-palette</v-icon>
        Aparência Compartilhada
      </div>
      <div class="d-flex flex-column gap-4">

        <div>
          <label class="inspector-label d-flex justify-space-between">
            Escurecimento das Imagens (Overlay)
            <span class="text-primary font-weight-black">{{ ((block.settings.overlay_opacity !== undefined ? block.settings.overlay_opacity : 0.3) * 100).toFixed(0) }}%</span>
          </label>
          <input type="range" v-model.number="block.settings.overlay_opacity" min="0" max="0.9" step="0.1" class="w-100 modern-range" />
        </div>

        <div>
          <label class="inspector-label">Estilo da Borda (Espaçamento)</label>
          <select v-model="block.settings.border_style" class="modern-input px-3">
            <option value="gap">Com Espaçamento (Cards Separados)</option>
            <option value="seamless">Seamless (Colados ponta a ponta)</option>
          </select>
        </div>

        <div class="d-flex align-center gap-3">
          <label class="inspector-label m-0 flex-grow-1">Cor dos Textos</label>
          <input type="color" v-model="block.settings.text_color" class="color-picker" />
        </div>

        <div class="d-flex align-center gap-3">
          <label class="inspector-label m-0 flex-grow-1">Cor dos Botões</label>
          <input type="color" v-model="block.settings.button_color" class="color-picker" />
        </div>

      </div>
    </div>

  </div>

  <section v-else
           :id="`block-preview-${block._id}`"
           class="preview-section dual-banner-section section-padding px-8"
           :class="[{ 'active-outline': isActive }]"
           :style="{ backgroundColor: block.settings.bg_color || '#ffffff' }">

    <div class="max-w-1400 mx-auto w-100 d-flex flex-column flex-md-row" :class="block.settings.border_style === 'seamless' ? 'gap-0 rounded-2xl overflow-hidden' : 'gap-6'">

        <div class="flex-grow-1 position-relative d-flex align-center justify-center text-center banner-card group overflow-hidden"
             :class="block.settings.border_style === 'seamless' ? '' : 'rounded-2xl shadow-md'"
             style="height: 450px; background-color: #f1f1f1;">

            <img v-if="block.settings.image_1"
                 :src="utils.getOptimizedUrl(block.settings.image_1, 1200)"
                 class="banner-bg-img transition-transform group-hover-scale" />

            <div class="banner-overlay" :style="{ opacity: block.settings.overlay_opacity !== undefined ? block.settings.overlay_opacity : 0.3 }"></div>

            <div class="position-relative z-10 w-100 px-6 d-flex flex-column align-center" :style="{ color: block.settings.text_color || '#ffffff' }">

               <div v-if="block.settings.subtitle_1" class="text-caption font-weight-bold text-uppercase tracking-widest mb-3 opacity-90 glass-kicker px-4 py-1 rounded-pill d-inline-block border">
                 {{ block.settings.subtitle_1 }}
               </div>

               <h3 class="text-h3 font-weight-black tracking-tighter mb-8 title-shadow">{{ block.settings.title_1 || 'Banner 1' }}</h3>

               <v-btn v-if="block.settings.button_text_1 || block.settings.button_text"
                      :color="block.settings.button_color || 'white'"
                      variant="flat"
                      size="x-large"
                      class="rounded-lg text-none font-weight-bold px-10 hover-lift shadow-lg"
                      :class="utils.getTextColorClass(block.settings.button_color, 'white')">
                 {{ block.settings.button_text_1 || block.settings.button_text || 'Explorar' }}
               </v-btn>
            </div>
        </div>

        <div class="flex-grow-1 position-relative d-flex align-center justify-center text-center banner-card group overflow-hidden"
             :class="block.settings.border_style === 'seamless' ? '' : 'rounded-2xl shadow-md'"
             style="height: 450px; background-color: #e5e5e5;">

            <img v-if="block.settings.image_2"
                 :src="utils.getOptimizedUrl(block.settings.image_2, 1200)"
                 class="banner-bg-img transition-transform group-hover-scale" />

            <div class="banner-overlay" :style="{ opacity: block.settings.overlay_opacity !== undefined ? block.settings.overlay_opacity : 0.3 }"></div>

            <div class="position-relative z-10 w-100 px-6 d-flex flex-column align-center" :style="{ color: block.settings.text_color || '#ffffff' }">

               <div v-if="block.settings.subtitle_2" class="text-caption font-weight-bold text-uppercase tracking-widest mb-3 opacity-90 glass-kicker px-4 py-1 rounded-pill d-inline-block border">
                 {{ block.settings.subtitle_2 }}
               </div>

               <h3 class="text-h3 font-weight-black tracking-tighter mb-8 title-shadow">{{ block.settings.title_2 || 'Banner 2' }}</h3>

               <v-btn v-if="block.settings.button_text_2 || block.settings.button_text"
                      :color="block.settings.button_color || 'white'"
                      variant="flat"
                      size="x-large"
                      class="rounded-lg text-none font-weight-bold px-10 hover-lift shadow-lg"
                      :class="utils.getTextColorClass(block.settings.button_color, 'white')">
                 {{ block.settings.button_text_2 || block.settings.button_text || 'Explorar' }}
               </v-btn>
            </div>
        </div>

    </div>
  </section>
</template>

<script setup lang="ts">
import { inject } from 'vue'

const props = defineProps<{
  mode: 'settings' | 'preview'
  block: any
  isActive?: boolean
}>()

const emit = defineEmits(['upload'])
const utils = inject<any>('builderUtils')
</script>

<style scoped>
/* ==========================================
   ESTILOS DO INSPECTOR (SETTINGS)
   ========================================== */
.config-group { border: 1px solid rgba(var(--v-theme-on-surface), 0.08); border-radius: 12px; padding: 20px; background: rgba(var(--v-theme-surface), 0.8); backdrop-filter: blur(8px); }
.config-header { font-size: 12px; font-weight: 800; margin-bottom: 20px; color: rgb(var(--v-theme-on-surface)); text-transform: uppercase; letter-spacing: 0.08em; border-bottom: 1px solid rgba(var(--v-theme-on-surface), 0.06); padding-bottom: 12px; }
.inspector-label { display: block; font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.06em; margin-bottom: 8px; color: rgba(var(--v-theme-on-surface), 0.7); }

.modern-input { min-height: 44px; width: 100%; border: 1px solid rgba(var(--v-theme-on-surface), 0.15); background: rgb(var(--v-theme-surface)); border-radius: 8px; transition: all 0.2s; font-size: 14px; padding: 0 14px; }
.modern-input:focus { border-color: rgb(var(--v-theme-primary)); outline: none; box-shadow: 0 0 0 4px rgba(var(--v-theme-primary), 0.1); }
.color-picker { width: 100%; height: 44px; border-radius: 8px; border: 1px solid rgba(var(--v-theme-on-surface), 0.15); cursor: pointer; }
.modern-range { cursor: pointer; }

/* ==========================================
   ESTILOS DO PREVIEW (CANVAS)
   ========================================== */
.dual-banner-section { transition: all 0.4s ease; outline: 2px solid transparent; outline-offset: -2px; cursor: pointer; }
.dual-banner-section:hover { outline-color: rgba(var(--v-theme-primary), 0.4); }
.active-outline { outline-color: rgb(var(--v-theme-primary)) !important; box-shadow: inset 0 0 0 4px rgba(var(--v-theme-primary), 0.2); z-index: 2; }

.section-padding { padding-top: 80px; padding-bottom: 80px; }

/* ESTRUTURA DO BANNER */
.banner-card {
  flex-basis: 50%;
  cursor: pointer;
}

.banner-bg-img {
  position: absolute;
  top: 0; left: 0;
  width: 100%; height: 100%;
  object-fit: cover;
  z-index: 0;
}

.banner-overlay {
  position: absolute;
  top: 0; left: 0;
  width: 100%; height: 100%;
  background-color: #000000;
  z-index: 1;
  transition: opacity 0.4s ease;
}

/* INTERAÇÕES DE HOVER (Premium Touch) */
.group-hover-scale { transition: transform 0.8s cubic-bezier(0.25, 0.46, 0.45, 0.94); }
.group:hover .group-hover-scale { transform: scale(1.08); }

/* Aumenta sutilmente o escurecimento no hover para destacar o botão */
.group:hover .banner-overlay { opacity: calc(var(--op) + 0.15) !important; }

.hover-lift { transition: all 0.3s cubic-bezier(0.16, 1, 0.3, 1); }
.group:hover .hover-lift { transform: translateY(-4px); box-shadow: 0 20px 40px rgba(0,0,0,0.3) !important; }

/* ESTILOS DE TEXTO */
.title-shadow { text-shadow: 0 4px 12px rgba(0,0,0,0.4); }
.glass-kicker {
  background: rgba(255, 255, 255, 0.1);
  backdrop-filter: blur(8px);
  border-color: rgba(255, 255, 255, 0.2) !important;
}

@media(max-width: 960px) {
  .section-padding { padding-top: 40px; padding-bottom: 40px; }
  .banner-card { height: 350px !important; }
}
</style>
