<template>
  <div v-if="mode === 'settings'" class="giant-mockup-settings d-flex flex-column gap-6">

    <div class="config-group">
      <div class="config-header d-flex align-center gap-2">
        <v-icon size="16" color="primary">mdi-ruler-square</v-icon>
        Estrutura e Dimensões
      </div>
      <div class="d-flex flex-column gap-4">

        <div>
          <label class="inspector-label">Posição do Mockup na Tela</label>
          <select v-model="block.settings.layout_style" class="modern-input px-3">
            <option value="left">Esquerda (Texto na Direita)</option>
            <option value="right">Direita (Texto na Esquerda)</option>
            <option value="top">Topo (Texto Embaixo Centralizado)</option>
            <option value="bottom">Rodapé (Texto Em Cima Centralizado)</option>
          </select>
        </div>

        <div>
          <label class="inspector-label d-flex justify-space-between">
            Tamanho do Mockup (Escala)
            <span class="text-primary font-weight-black">{{ block.settings.mockup_size || 600 }}px</span>
          </label>
          <input type="range" v-model.number="block.settings.mockup_size" min="300" max="1000" step="20" class="w-100 modern-range" />
        </div>

        <div>
          <label class="inspector-label d-flex justify-space-between">
            Distância entre Mockup e Texto
            <span class="text-primary font-weight-black">{{ block.settings.content_gap !== undefined ? block.settings.content_gap : 64 }}px</span>
          </label>
          <input type="range" v-model.number="block.settings.content_gap" min="0" max="200" step="8" class="w-100 modern-range" />
          <p class="text-[10px] text-medium-emphasis mt-1 m-0">Aumente para criar respiro (whitespace) digno de marcas de luxo.</p>
        </div>

      </div>
    </div>

    <div class="config-group">
      <div class="config-header d-flex align-center gap-2">
        <v-icon size="16" color="primary">mdi-star-four-points-outline</v-icon>
        Produto em Destaque
      </div>
      <div class="d-flex flex-column gap-4">

        <div>
          <label class="inspector-label">Tipo de Imagem</label>
          <div class="d-flex gap-2 bg-surface p-1 rounded-lg border">
            <v-btn flex-grow-1 variant="text" size="small" :color="block.settings.image_type === 'system' || !block.settings.image_type ? 'primary' : 'default'" class="text-none font-weight-bold" @click="block.settings.image_type = 'system'">
              Gerar 3D (Sistema)
            </v-btn>
            <v-btn flex-grow-1 variant="text" size="small" :color="block.settings.image_type === 'upload' ? 'primary' : 'default'" class="text-none font-weight-bold" @click="block.settings.image_type = 'upload'">
              Upload PNG Custom
            </v-btn>
          </div>
        </div>

        <template v-if="block.settings.image_type === 'system' || !block.settings.image_type">
          <div class="pa-3 bg-indigo-lighten-5 border border-indigo-lighten-3 rounded-lg d-flex flex-column gap-3">
            <div>
              <label class="inspector-label text-indigo-darken-2">1. Mockup Base</label>
              <v-autocomplete
                v-model="block.settings.mockup_id"
                :items="mockups"
                item-title="name"
                item-value="id"
                variant="outlined"
                density="compact"
                hide-details
                bg-color="white"
                class="rounded-lg custom-autocomplete"
                placeholder="Busque o modelo...">
                <template v-slot:item="{ props, item }">
                  <v-list-item v-bind="props" :title="item.raw.name">
                    <template v-slot:prepend>
                      <v-avatar rounded="lg" size="32" class="mr-3 border bg-white"><v-img :src="item.raw.base_image_url" style="object-fit: contain;"></v-img></v-avatar>
                    </template>
                  </v-list-item>
                </template>
              </v-autocomplete>
            </div>

            <div>
              <label class="inspector-label text-indigo-darken-2">2. Estampa a Aplicar</label>
              <v-autocomplete
                v-model="block.settings.stamp_id"
                :items="stamps"
                item-title="title"
                item-value="id"
                group-by="category_name"
                variant="outlined"
                density="compact"
                hide-details
                bg-color="white"
                class="rounded-lg custom-autocomplete"
                placeholder="Selecione a estampa...">
                <template v-slot:item="{ props, item }">
                  <v-list-item v-bind="props" :title="item.raw.title">
                    <template v-slot:prepend>
                      <v-avatar rounded="lg" size="32" class="mr-3 border"><v-img :src="item.raw.main_image_url" cover></v-img></v-avatar>
                    </template>
                  </v-list-item>
                </template>
              </v-autocomplete>
            </div>
          </div>
        </template>

        <template v-else>
          <div class="pa-3 bg-grey-lighten-4 border rounded-lg">
            <label class="inspector-label">Upload de Produto (Fundo Transparente)</label>
            <div v-if="block.settings.image_url" class="rounded border overflow-hidden bg-white d-flex flex-column mb-2 shadow-sm position-relative">
              <img :src="block.settings.image_url" style="height: 140px; width: 100%; object-fit: contain; padding: 10px;" />
              <div class="pa-2 bg-surface d-flex justify-space-between align-center border-t">
                <span class="text-[10px] text-truncate font-weight-bold">Imagem Carregada</span>
                <v-btn size="x-small" color="error" variant="text" icon="mdi-delete" @click="block.settings.image_url = ''"></v-btn>
              </div>
            </div>
            <v-btn block color="primary" variant="tonal" class="text-none font-weight-bold rounded-lg border-dashed border-primary" style="border-width: 1px;" prepend-icon="mdi-cloud-upload-outline" @click="$emit('upload', 'image_url')">
              Fazer Upload (PNG)
            </v-btn>
          </div>
        </template>
      </div>
    </div>

    <div class="config-group">
      <div class="config-header d-flex align-center gap-2">
        <v-icon size="16" color="primary">mdi-format-text-variant</v-icon>
        Copywriting da Campanha
      </div>
      <div class="d-flex flex-column gap-4">
        <div>
          <label class="inspector-label">Título Principal (Aceita HTML básico)</label>
          <textarea v-model="block.settings.title" rows="2" class="modern-input" style="resize:vertical;" placeholder="Ex: O Caimento <br/><span class='text-primary'>Perfeito.</span>"></textarea>
        </div>

        <div>
          <label class="inspector-label">Texto Persuasivo</label>
          <textarea v-model="block.settings.text" rows="3" class="modern-input" style="resize:vertical;" placeholder="Por que esse produto é incrível?"></textarea>
        </div>

        <div class="border-t pt-2">
          <label class="inspector-label">Texto do Botão (Vazio = Sem Botão)</label>
          <input type="text" v-model="block.settings.button_text" class="modern-input" placeholder="Ex: Acessar Simulador" />
        </div>

        <div>
          <label class="inspector-label">Link do Botão</label>
          <input type="text" v-model="block.settings.button_link" class="modern-input" placeholder="Ex: /produtos/destaque" />
        </div>
      </div>
    </div>

    <div class="config-group">
      <div class="config-header d-flex align-center gap-2">
        <v-icon size="16" color="primary">mdi-lightbulb-on-outline</v-icon>
        Cores e Iluminação
      </div>
      <div class="d-flex flex-column gap-4">
        <div class="d-flex align-center gap-3">
          <label class="inspector-label m-0 flex-grow-1">Cor do Fundo</label>
          <input type="color" v-model="block.settings.bg_color" class="color-picker" />
        </div>
        <div class="d-flex align-center gap-3">
          <label class="inspector-label m-0 flex-grow-1">Luz de Palco (Glow atrás da peça)</label>
          <input type="color" v-model="block.settings.glow_color" class="color-picker" />
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
           class="preview-section giant-mockup-section section-padding px-6 px-md-8 overflow-hidden"
           :class="[{ 'active-outline': isActive }]"
           :style="{ backgroundColor: block.settings.bg_color || '#ffffff' }">

    <div class="max-w-1400 mx-auto w-100 d-flex align-center justify-center transition-all"
         :class="getLayoutClasses()"
         :style="{ gap: `${block.settings.content_gap !== undefined ? block.settings.content_gap : 64}px` }">

       <div class="d-flex align-center justify-center position-relative stage-container transition-all flex-shrink-0"
            :style="{
              width: '100%',
              maxWidth: `${block.settings.mockup_size || 600}px`,
              aspectRatio: '1/1'
            }">

          <div class="stage-glow" :style="{
            background: `radial-gradient(circle, ${block.settings.glow_color || 'rgba(var(--v-theme-primary), 0.15)'} 0%, rgba(255,255,255,0) 70%)`
          }"></div>

          <div class="floating-product w-100 h-100 position-relative z-10 d-flex align-center justify-center">

            <template v-if="block.settings.image_type === 'system' || !block.settings.image_type">
              <div class="position-relative w-100 h-100 mockup-composer drop-shadow-super">

                 <template v-if="block.settings.mockup_id && utils.getMockupObj(block.settings.mockup_id)">

                    <div v-if="block.settings.stamp_id && utils.getStampObj(block.settings.stamp_id)"
                         class="layer layer-stamp"
                         :style="{ backgroundImage: `url('${utils.getOptimizedUrl(utils.getStampObj(block.settings.stamp_id).main_image_url, 1400)}')` }">
                    </div>

                    <img :src="utils.getOptimizedUrl(utils.getMockupObj(block.settings.mockup_id).base_image_url, 1400)"
                         class="layer layer-base" />

                    <img v-if="utils.getMockupObj(block.settings.mockup_id).shadow_overlay_url"
                         :src="utils.getOptimizedUrl(utils.getMockupObj(block.settings.mockup_id).shadow_overlay_url, 1400)"
                         class="layer layer-shadow" />
                 </template>

                 <div v-else class="bg-grey-lighten-4 w-100 h-100 d-flex align-center justify-center rounded-circle border border-dashed">
                    <v-icon size="100" color="grey-lighten-2">mdi-tshirt-crew</v-icon>
                 </div>
              </div>
            </template>

            <template v-else>
              <img v-if="block.settings.image_url"
                   :src="utils.getOptimizedUrl(block.settings.image_url, 1400)"
                   class="w-100 h-100 drop-shadow-super"
                   style="object-fit: contain;" />
              <div v-else class="bg-grey-lighten-4 w-100 h-100 d-flex align-center justify-center rounded-circle border border-dashed">
                 <v-icon size="100" color="grey-lighten-2">mdi-star-four-points</v-icon>
              </div>
            </template>

          </div>
       </div>

       <div class="text-content transition-all"
            :class="getTextAlignmentClasses()"
            :style="{
              color: block.settings.text_color || '#111827',
              maxWidth: isVerticalLayout() ? '800px' : '500px'
            }">

          <h2 class="text-h2 text-md-h1 font-weight-black m-0 tracking-tighter line-height-tight mb-8"
              v-html="block.settings.title || 'O Caimento <br/><span class=\'text-primary\'>Perfeito.</span>'">
          </h2>

          <p class="text-h6 opacity-80 mb-12 font-weight-regular text-body-relaxed"
             :class="isVerticalLayout() ? 'mx-auto max-w-600' : ''"
             style="white-space: pre-line;">
            {{ block.settings.text || 'Tecnologia têxtil de ponta combinada com estampas em alta definição. Uma experiência visual e tátil sem precedentes, projetada para elevar sua coleção.' }}
          </p>

          <v-btn v-if="block.settings.button_text"
                 :color="block.settings.button_color || 'primary'"
                 size="x-large"
                 class="rounded-lg font-weight-black text-none px-12 shadow-lg hover-lift"
                 :class="utils.getTextColorClass(block.settings.button_color, 'primary')"
                 style="letter-spacing: 0.5px;">
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
  stamps: any[]
  mockups: any[]
}>()

const utils = inject<any>('builderUtils')

// Lógica para empurrar o Mockup e o Texto de acordo com o Select de Layout
function getLayoutClasses() {
  const style = props.block.settings.layout_style || 'left'

  if (style === 'left') return 'flex-column flex-md-row'
  if (style === 'right') return 'flex-column flex-md-row-reverse'
  if (style === 'top') return 'flex-column'
  if (style === 'bottom') return 'flex-column-reverse'

  return 'flex-column flex-md-row'
}

// Retorna se o layout é de empilhamento vertical (top/bottom) para centralizar o texto
function isVerticalLayout() {
  const style = props.block.settings.layout_style || 'left'
  return style === 'top' || style === 'bottom'
}

// Alinha o texto ao centro se o Mockup estiver em cima/baixo, ou à esquerda/direita se estiver nas laterais
function getTextAlignmentClasses() {
  if (isVerticalLayout()) return 'text-center'

  // Se o mockup tá na Esquerda, o texto da direita fica alinhado a esquerda (natural)
  const style = props.block.settings.layout_style || 'left'
  if (style === 'left') return 'text-center text-md-left'
  if (style === 'right') return 'text-center text-md-left' // Pode mudar para text-md-right se quiser espelhado extremo

  return 'text-left'
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
.modern-range { cursor: pointer; accent-color: rgb(var(--v-theme-primary)); }

/* ==========================================
   ESTILOS DO PREVIEW (CANVAS)
   ========================================== */
.giant-mockup-section { transition: all 0.4s ease; outline: 2px solid transparent; outline-offset: -2px; cursor: pointer; }
.giant-mockup-section:hover { outline-color: rgba(var(--v-theme-primary), 0.4); }
.active-outline { outline-color: rgb(var(--v-theme-primary)) !important; box-shadow: inset 0 0 0 4px rgba(var(--v-theme-primary), 0.2); z-index: 5; }

.section-padding { padding-top: 140px; padding-bottom: 140px; }

/* RESPONSIVIDADE FORÇADA (MOBILE SEMPRE EMPILHA) */
@media(max-width: 960px) {
  .section-padding { padding-top: 80px; padding-bottom: 80px; }
  .text-content { max-width: 100% !important; text-align: center !important; }
}

/* TIPOGRAFIA */
.line-height-tight { line-height: 1.05; }
.text-body-relaxed { line-height: 1.8; }
.max-w-600 { max-width: 600px; }

/* ==========================================
   MÁGICA DO MOCKUP GIGANTE (STAGE & FLOAT)
   ========================================== */

.stage-container {
  perspective: 1000px;
}

/* O brilho radial sutil atrás do produto */
.stage-glow {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  width: 75%;
  height: 75%;
  border-radius: 50%;
  /* A cor do background agora vem via inline-style no template, permitindo customização! */
  filter: blur(60px);
  z-index: 1;
  transition: background 0.4s ease;
}

/* Animação suave de flutuação vertical contínua */
.floating-product {
  animation: floatProduct 6s ease-in-out infinite;
}

@keyframes floatProduct {
  0% { transform: translateY(0px); }
  50% { transform: translateY(-20px); } /* Flutuação mais perceptível */
  100% { transform: translateY(0px); }
}

/* Sombra projetada do produto colossal para dar realismo (Aceita PNGs com alpha) */
.drop-shadow-super {
  filter: drop-shadow(0 40px 50px rgba(0, 0, 0, 0.25));
}

/* COMPOSIÇÃO 3D CSS (Camadas Isoladas) */
.mockup-composer {
  width: 100%;
  height: 100%;
}
.layer {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  pointer-events: none;
}
/* A estampa precisa ser Cover no fundo */
.layer-stamp {
  background-size: cover;
  background-position: center;
  z-index: 2;
}
/* A base e a sombra precisam ser CONTAIN para não estourar as bordas do produto 3D */
.layer-base {
  object-fit: contain;
  z-index: 3;
}
.layer-shadow {
  object-fit: contain;
  mix-blend-mode: multiply;
  z-index: 4;
}

/* INTERAÇÕES DE BOTÃO E TEXTO */
.hover-lift { transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1); }
.hover-lift:hover { transform: translateY(-4px) scale(1.02); box-shadow: 0 20px 40px rgba(0,0,0,0.2) !important; }

/* Animação de entrada do texto */
.text-content {
  animation: slideInFade 1s cubic-bezier(0.16, 1, 0.3, 1);
  flex-grow: 1; /* Garante que ocupe o espaço restante do Flexbox */
}

@keyframes slideInFade {
  0% { opacity: 0; transform: translateX(30px); }
  100% { opacity: 1; transform: translateX(0); }
}

/* Permite que tags de span injetadas via textarea assumam as cores corretas */
:deep(.text-primary) { color: rgb(var(--v-theme-primary)) !important; }
</style>
