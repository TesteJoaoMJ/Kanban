<template>
  <div v-if="mode === 'settings'" class="text-image-settings d-flex flex-column gap-6">

    <div class="config-group">
      <div class="config-header d-flex align-center gap-2">
        <v-icon size="16" color="primary">mdi-image-size-select-large</v-icon>
        Mídia e Posição
      </div>
      <div class="d-flex flex-column gap-4">
        <div>
          <label class="inspector-label">Layout da Seção</label>
          <div class="d-flex gap-2">
            <v-btn flex-grow-1 variant="outlined" :color="block.settings.image_position === 'left' ? 'primary' : 'grey'" class="text-none" @click="block.settings.image_position = 'left'">
              <v-icon start>mdi-format-horizontal-align-left</v-icon> Imagem na Esquerda
            </v-btn>
            <v-btn flex-grow-1 variant="outlined" :color="block.settings.image_position === 'right' ? 'primary' : 'grey'" class="text-none" @click="block.settings.image_position = 'right'">
              Imagem na Direita <v-icon end>mdi-format-horizontal-align-right</v-icon>
            </v-btn>
          </div>
        </div>

        <div>
          <label class="inspector-label">Imagem do Bloco (Retrato 4:5)</label>
          <div v-if="block.settings.image_url" class="rounded-lg border overflow-hidden bg-background d-flex flex-column mb-3 shadow-sm position-relative">
            <img :src="block.settings.image_url" style="height: 180px; width: 100%; object-fit: cover;" />
            <div class="pa-2 bg-surface d-flex justify-space-between align-center border-t">
              <span class="text-[10px] text-truncate px-2 font-weight-medium text-medium-emphasis">Imagem Carregada</span>
              <v-btn size="x-small" color="error" variant="text" icon="mdi-delete" @click="block.settings.image_url = ''"></v-btn>
            </div>
          </div>
          <v-btn v-else block color="primary" variant="tonal" class="text-none font-weight-bold rounded-lg border-dashed border-primary" style="border-width: 1px;" prepend-icon="mdi-cloud-upload-outline" @click="$emit('upload', 'image_url')">
            Fazer Upload da Imagem
          </v-btn>
        </div>
      </div>
    </div>

    <div class="config-group">
      <div class="config-header d-flex align-center gap-2">
        <v-icon size="16" color="primary">mdi-format-text</v-icon>
        Conteúdo Textual
      </div>
      <div class="d-flex flex-column gap-4">
        <div>
          <label class="inspector-label">Título Principal</label>
          <input type="text" v-model="block.settings.title" class="modern-input" placeholder="Ex: Nossa Essência" />
        </div>

        <div>
          <label class="inspector-label">Kicker (Subtítulo Acima)</label>
          <input type="text" v-model="block.settings.subtitle" class="modern-input" placeholder="Ex: Sobre a Marca" />
        </div>

        <div>
          <label class="inspector-label">Texto de Corpo</label>
          <textarea v-model="block.settings.text" rows="5" class="modern-input" style="resize:vertical;" placeholder="Conte a história da sua coleção ou do seu processo produtivo..."></textarea>
        </div>

        <div>
          <label class="inspector-label">Alinhamento do Texto</label>
          <div class="bg-surface border rounded-lg d-flex p-1">
            <v-btn flex-grow-1 variant="text" size="small" :color="block.settings.align === 'left' ? 'primary' : 'default'" @click="block.settings.align = 'left'"><v-icon>mdi-format-align-left</v-icon></v-btn>
            <v-btn flex-grow-1 variant="text" size="small" :color="block.settings.align === 'center' ? 'primary' : 'default'" @click="block.settings.align = 'center'"><v-icon>mdi-format-align-center</v-icon></v-btn>
            <v-btn flex-grow-1 variant="text" size="small" :color="block.settings.align === 'right' ? 'primary' : 'default'" @click="block.settings.align = 'right'"><v-icon>mdi-format-align-right</v-icon></v-btn>
          </div>
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
          <label class="inspector-label">Texto do Botão (Vazio para ocultar)</label>
          <input type="text" v-model="block.settings.button_text" class="modern-input" placeholder="Ex: Saiba Mais" />
        </div>

        <div class="d-flex align-center gap-3">
          <label class="inspector-label m-0 flex-grow-1">Cor do Fundo</label>
          <input type="color" v-model="block.settings.bg_color" class="color-picker" />
        </div>

        <div class="d-flex align-center gap-3">
          <label class="inspector-label m-0 flex-grow-1">Cor do Texto</label>
          <input type="color" v-model="block.settings.text_color" class="color-picker" />
        </div>

        <div class="d-flex align-center gap-3">
          <label class="inspector-label m-0 flex-grow-1">Cor do Botão</label>
          <input type="color" v-model="block.settings.button_color" class="color-picker" />
        </div>
      </div>
    </div>

  </div>

  <section v-else
           :id="`block-preview-${block._id}`"
           class="preview-section text-image-section section-padding px-8"
           :class="{ 'active-outline': isActive }"
           :style="{ backgroundColor: block.settings.bg_color || 'transparent' }">

    <div class="max-w-1200 mx-auto w-100 d-flex flex-column flex-md-row gap-10 gap-md-16 align-center layout-transition"
         :class="{'flex-md-row-reverse': block.settings.image_position === 'right'}">

      <div class="flex-grow-1 w-100 rounded-xl overflow-hidden shadow-lg border border-opacity-10 image-wrapper group" style="max-width: 540px;">
        <v-img v-if="block.settings.image_url"
               :src="utils.getOptimizedUrl(block.settings.image_url, 1000)"
               cover
               class="transition-transform group-hover-scale"
               style="aspect-ratio: 4/5;"></v-img>

        <div v-else class="bg-surface d-flex flex-column align-center justify-center text-medium-emphasis" style="aspect-ratio: 4/5;">
          <v-icon size="64" class="opacity-20 mb-4">mdi-image-outline</v-icon>
          <span class="text-caption font-weight-bold text-uppercase tracking-widest opacity-50">Espaço para Imagem</span>
        </div>
      </div>

      <div class="flex-grow-1 w-100 text-content-wrapper"
           :style="{
             color: block.settings.text_color || '#111827',
             textAlign: block.settings.align || 'left'
           }">

         <div v-if="block.settings.subtitle" class="font-weight-bold text-caption text-uppercase tracking-widest mb-4 opacity-70 text-kicker">
           {{ block.settings.subtitle }}
         </div>

         <h2 class="text-h3 text-md-h2 font-weight-black mb-6 tracking-tighter line-height-tight"
             v-html="block.settings.title || 'Sua História Aqui'"></h2>

         <p class="text-body-1 opacity-80 mb-10 font-weight-regular text-body-relaxed"
            :class="block.settings.align === 'center' ? 'mx-auto' : (block.settings.align === 'right' ? 'ml-auto' : '')"
            style="white-space: pre-line; max-width: 600px;">
           {{ block.settings.text || 'Use este espaço para descrever a essência da sua marca, os detalhes de uma coleção exclusiva ou o processo produtivo da sua fábrica.' }}
         </p>

         <v-btn v-if="block.settings.button_text"
                :color="block.settings.button_color || 'black'"
                size="x-large"
                class="rounded-lg font-weight-bold text-none px-12 shadow-sm hover-lift"
                :class="utils.getTextColorClass(block.settings.button_color, 'black')">
           {{ block.settings.button_text }}
         </v-btn>

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

.modern-input { min-height: 44px; width: 100%; border: 1px solid rgba(var(--v-theme-on-surface), 0.15); background: rgb(var(--v-theme-surface)); border-radius: 8px; transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1); font-size: 14px; color: rgb(var(--v-theme-on-surface)); padding: 0 14px; box-shadow: inset 0 1px 2px rgba(0,0,0,0.03); }
.modern-input:focus { border-color: rgb(var(--v-theme-primary)); box-shadow: 0 0 0 4px rgba(var(--v-theme-primary), 0.15); outline: none; }
textarea.modern-input { padding-top: 12px; line-height: 1.5; }

.color-picker { width: 100%; height: 44px; border-radius: 8px; border: 1px solid rgba(var(--v-theme-on-surface), 0.15); padding: 4px; cursor: pointer; background: rgb(var(--v-theme-surface)); transition: border-color 0.2s; }
.color-picker:hover { border-color: rgb(var(--v-theme-primary)); }

/* ==========================================
   ESTILOS DO PREVIEW CANVAS
   ========================================== */
.text-image-section {
  transition: outline 0.2s, background-color 0.4s ease;
  outline: 2px solid transparent;
  outline-offset: -2px;
  cursor: pointer;
}
.text-image-section:hover { outline-color: rgba(var(--v-theme-primary), 0.4); }
.active-outline { outline-color: rgb(var(--v-theme-primary)) !important; box-shadow: inset 0 0 0 4px rgba(var(--v-theme-primary), 0.2); z-index: 2; }

.section-padding { padding-top: 100px; padding-bottom: 100px; }

/* Transição suave ao inverter a posição da imagem (Esq/Dir) */
.layout-transition { transition: flex-direction 0.5s cubic-bezier(0.4, 0, 0.2, 1); }

.image-wrapper {
  position: relative;
  /* Uma leve sombra elegante que lembra molduras físicas */
  box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.15);
}

.group-hover-scale {
  transition: transform 0.6s cubic-bezier(0.25, 0.46, 0.45, 0.94);
}
.image-wrapper:hover .group-hover-scale {
  transform: scale(1.05);
}

.text-content-wrapper {
  padding: 20px 0;
}

.line-height-tight { line-height: 1.15; }
.text-body-relaxed { line-height: 1.8; font-size: 1.125rem; }
.text-kicker { color: rgba(var(--v-theme-primary), 1); }

.hover-lift { transition: transform 0.25s cubic-bezier(0.4, 0, 0.2, 1), box-shadow 0.25s cubic-bezier(0.4, 0, 0.2, 1); }
.hover-lift:hover { transform: translateY(-3px); box-shadow: 0 15px 30px rgba(0,0,0,0.15) !important; }

@media(max-width: 960px) {
  .section-padding { padding-top: 60px; padding-bottom: 60px; }
  .text-content-wrapper { text-align: center !important; }
  .text-body-relaxed { margin-left: auto; margin-right: auto; font-size: 1rem; }
}
</style>
