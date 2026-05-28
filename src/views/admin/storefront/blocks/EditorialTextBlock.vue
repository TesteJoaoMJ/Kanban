<template>
  <div v-if="mode === 'settings'" class="editorial-block-settings d-flex flex-column gap-6">

    <div class="config-group">
      <div class="config-header d-flex align-center gap-2">
        <v-icon size="16" color="primary">mdi-format-align-center</v-icon>
        Conteúdo e Tipografia
      </div>
      <div class="d-flex flex-column gap-4">
        <div>
          <label class="inspector-label">Título do Manifesto</label>
          <input type="text" v-model="block.settings.title" class="modern-input" placeholder="Ex: Nossa História" />
        </div>

        <div>
          <label class="inspector-label">Texto Principal (Corpo)</label>
          <textarea v-model="block.settings.text" rows="6" class="modern-input" style="resize:vertical;" placeholder="Escreva o texto editorial da sua marca aqui..."></textarea>
        </div>

        <div class="d-flex align-center justify-space-between mt-2 pa-3 bg-surface border rounded-lg">
          <div>
            <label class="inspector-label m-0 text-primary">Letra Capitular (Revista)</label>
            <p class="text-[10px] text-medium-emphasis m-0">Destaca a 1ª letra do texto.</p>
          </div>
          <v-switch v-model="block.settings.use_dropcap" color="primary" hide-details density="compact"></v-switch>
        </div>
      </div>
    </div>

    <div class="config-group">
      <div class="config-header d-flex align-center gap-2">
        <v-icon size="16" color="primary">mdi-page-layout-body</v-icon>
        Estrutura Visual
      </div>
      <div class="d-flex flex-column gap-4">

        <div>
          <label class="inspector-label">Alinhamento do Texto</label>
          <div class="bg-surface border rounded-lg d-flex p-1">
            <v-btn flex-grow-1 variant="text" size="small" :color="block.settings.align === 'left' ? 'primary' : 'default'" @click="block.settings.align = 'left'"><v-icon>mdi-format-align-left</v-icon></v-btn>
            <v-btn flex-grow-1 variant="text" size="small" :color="block.settings.align === 'center' || !block.settings.align ? 'primary' : 'default'" @click="block.settings.align = 'center'"><v-icon>mdi-format-align-center</v-icon></v-btn>
            <v-btn flex-grow-1 variant="text" size="small" :color="block.settings.align === 'right' ? 'primary' : 'default'" @click="block.settings.align = 'right'"><v-icon>mdi-format-align-right</v-icon></v-btn>
          </div>
        </div>

        <div>
          <label class="inspector-label">Largura de Leitura (Container)</label>
          <select v-model="block.settings.container_width" class="modern-input px-3">
            <option value="narrow">Estreito (Ideal para muita leitura)</option>
            <option value="medium">Médio (Padrão)</option>
            <option value="wide">Largo (Textos curtos)</option>
          </select>
        </div>

        <div>
          <label class="inspector-label">Tamanho da Fonte (Corpo)</label>
          <select v-model="block.settings.font_size" class="modern-input px-3">
            <option value="normal">Normal (Elegante)</option>
            <option value="large">Grande (Impacto)</option>
            <option value="huge">Gigante (Manifesto)</option>
          </select>
        </div>

      </div>
    </div>

    <div class="config-group">
      <div class="config-header d-flex align-center gap-2">
        <v-icon size="16" color="primary">mdi-cursor-default-click-outline</v-icon>
        Ação Final
      </div>
      <div class="d-flex flex-column gap-4">
        <div>
          <label class="inspector-label">Texto do Botão (Vazio = Sem Botão)</label>
          <input type="text" v-model="block.settings.button_text" class="modern-input" placeholder="Ex: Conhecer a Fábrica" />
        </div>
        <div>
          <label class="inspector-label">Link do Botão</label>
          <input type="text" v-model="block.settings.button_link" class="modern-input" placeholder="Ex: /sobre-nos" />
        </div>
      </div>
    </div>

    <div class="config-group">
      <div class="config-header d-flex align-center gap-2">
        <v-icon size="16" color="primary">mdi-palette</v-icon>
        Cores da Seção
      </div>
      <div class="d-flex flex-column gap-4">
        <div class="d-flex align-center gap-3">
          <label class="inspector-label m-0 flex-grow-1">Fundo da Seção</label>
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
           class="preview-section editorial-section section-padding px-8 border-b"
           :class="[{ 'active-outline': isActive }]"
           :style="{ backgroundColor: block.settings.bg_color || '#ffffff' }">

    <div class="w-100 mx-auto transition-all"
         :class="getContainerWidthClass()"
         :style="{
           textAlign: block.settings.align || 'center',
           color: block.settings.text_color || '#111827'
         }">

      <h3 v-if="block.settings.title" class="text-h3 font-weight-black mb-10 tracking-tighter line-height-tight">
        {{ block.settings.title }}
      </h3>

      <div class="editorial-body opacity-90 font-weight-light line-height-relaxed"
           :class="[
             getFontSizeClass(),
             block.settings.use_dropcap && (block.settings.align === 'left' || !block.settings.align) ? 'has-dropcap' : ''
           ]"
           style="white-space: pre-line;">
        {{ block.settings.text || 'O manifesto da sua marca entra aqui. Escreva sobre seus valores, o processo meticuloso de desenvolvimento das estampas ou a história que fundamenta a sua coleção. Um bom texto aproxima o cliente da marca.' }}
      </div>

      <div class="mt-12" v-if="block.settings.button_text">
        <v-btn :color="block.settings.button_color || 'primary'"
               size="x-large"
               class="rounded-lg font-weight-bold text-none px-12 shadow-sm hover-lift"
               :class="utils.getTextColorClass(block.settings.button_color, 'primary')">
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

const utils = inject<any>('builderUtils')

// Controle de Largura do Container para leitura confortável
function getContainerWidthClass() {
  const width = props.block.settings.container_width || 'medium'
  if (width === 'narrow') return 'max-w-600'
  if (width === 'wide') return 'max-w-1000'
  return 'max-w-800' // Padrão
}

// Controle de Escala Tipográfica
function getFontSizeClass() {
  const size = props.block.settings.font_size || 'normal'
  if (size === 'large') return 'text-h5 text-md-h4'
  if (size === 'huge') return 'text-h4 text-md-h3'
  return 'text-h6' // Padrão Elegante
}
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
textarea.modern-input { padding-top: 12px; }
.color-picker { width: 100%; height: 44px; border-radius: 8px; border: 1px solid rgba(var(--v-theme-on-surface), 0.15); cursor: pointer; }

/* ==========================================
   ESTILOS DO PREVIEW (CANVAS)
   ========================================== */
.editorial-section { transition: all 0.4s ease; outline: 2px solid transparent; outline-offset: -2px; cursor: pointer; }
.editorial-section:hover { outline-color: rgba(var(--v-theme-primary), 0.4); }
.active-outline { outline-color: rgb(var(--v-theme-primary)) !important; box-shadow: inset 0 0 0 4px rgba(var(--v-theme-primary), 0.2); z-index: 2; }

.section-padding { padding-top: 120px; padding-bottom: 120px; }

/* UTILITÁRIOS DE LARGURA E TEXTO */
.max-w-600 { max-width: 600px; }
.max-w-800 { max-width: 800px; }
.max-w-1000 { max-width: 1000px; }

.line-height-tight { line-height: 1.1; }
.line-height-relaxed { line-height: 1.8; }

/* EFEITO EDITORIAL: DROP CAP (Letra Capitular)
  Funciona pegando a primeira letra do bloco e transformando ela numa letra gigante que flutua à esquerda.
*/
.has-dropcap::first-letter {
  float: left;
  font-size: 4.5em;
  line-height: 0.8;
  padding-top: 4px;
  padding-right: 12px;
  padding-left: 0;
  font-weight: 900;
  color: rgb(var(--v-theme-primary)); /* Usa a cor primária da loja para a letra destaque */
}

/* INTERAÇÕES */
.hover-lift { transition: all 0.3s cubic-bezier(0.16, 1, 0.3, 1); }
.hover-lift:hover { transform: translateY(-4px); box-shadow: 0 20px 40px rgba(0,0,0,0.15) !important; }
</style>
