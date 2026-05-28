<template>
  <div v-if="mode === 'settings'" class="mosaic-settings d-flex flex-column gap-6">

    <div class="config-group">
      <div class="config-header d-flex align-center gap-2">
        <v-icon size="16" color="primary">mdi-view-dashboard-variant</v-icon>
        Motor de Layout
      </div>
      <div class="d-flex flex-column gap-4">
        <div>
          <label class="inspector-label">Padrão Organizacional do Grid</label>
          <select v-model="block.settings.layout_style" class="modern-input px-3 font-weight-bold text-primary">
            <option value="editorial">1. Editorial Assimétrico (Clássico)</option>
            <option value="bento">2. Bento Box (Padrão Apple)</option>
            <option value="masonry">3. Masonry Fluido (Pinterest)</option>
            <option value="hero_left">4. Hero Esquerda + Grid Lateral</option>
            <option value="hero_right">5. Grid Lateral + Hero Direita</option>
            <option value="hero_center">6. Hero Central + Asas</option>
            <option value="grid_square">7. Grid Quadrado (2x2 ou 3x3)</option>
            <option value="slider">8. Slider Horizontal Contínuo</option>
            <option value="stacked">9. Cascata Vertical (Stack)</option>
            <option value="diamond">10. Zigue-Zague Estrito</option>
          </select>
        </div>

        <div>
          <label class="inspector-label">Estilo e Textura do Card</label>
          <select v-model="block.settings.card_style" class="modern-input px-3">
            <option value="glass">Glassmorphism (Vidro Desfocado)</option>
            <option value="solid">Sólido Degradê Escuro</option>
            <option value="minimal">Minimalista (Sem overlay fixo)</option>
            <option value="neumorphism">Bordas Flutuantes (Neumorphism)</option>
          </select>
        </div>
      </div>
    </div>

    <div class="config-group">
      <div class="config-header d-flex align-center gap-2">
        <v-icon size="16" color="primary">mdi-ruler-square</v-icon>
        Escala e Espaçamento
      </div>
      <div class="d-flex flex-column gap-5">
        <div>
          <label class="inspector-label d-flex justify-space-between">
            Largura do Bloco (Max-Width)
            <span class="text-primary font-weight-black">{{ block.settings.max_width || 1400 }}px</span>
          </label>
          <input type="range" v-model.number="block.settings.max_width" min="800" max="2560" step="100" class="w-100 modern-range" />
        </div>

        <div>
          <label class="inspector-label d-flex justify-space-between">
            Altura do Mosaico (Min-Height)
            <span class="text-primary font-weight-black">{{ block.settings.min_height || 600 }}px</span>
          </label>
          <input type="range" v-model.number="block.settings.min_height" min="400" max="1200" step="50" class="w-100 modern-range" />
        </div>

        <div>
          <label class="inspector-label d-flex justify-space-between">
            Espaçamento entre Cards (Gap)
            <span class="text-primary font-weight-black">{{ block.settings.grid_gap !== undefined ? block.settings.grid_gap : 16 }}px</span>
          </label>
          <input type="range" v-model.number="block.settings.grid_gap" min="0" max="64" step="4" class="w-100 modern-range" />
        </div>

        <div>
          <label class="inspector-label d-flex justify-space-between">
            Arredondamento das Bordas
            <span class="text-primary font-weight-black">{{ block.settings.border_radius !== undefined ? block.settings.border_radius : 16 }}px</span>
          </label>
          <input type="range" v-model.number="block.settings.border_radius" min="0" max="40" step="4" class="w-100 modern-range" />
        </div>
      </div>
    </div>

    <div class="config-group">
      <div class="config-header d-flex align-center gap-2">
        <v-icon size="16" color="primary">mdi-format-font</v-icon>
        Tipografia e Estilo
      </div>
      <div class="d-flex flex-column gap-4">
        <div>
          <label class="inspector-label">Título da Seção</label>
          <input type="text" v-model="block.settings.title" class="modern-input" placeholder="Ex: Curadoria Editorial" />
        </div>

        <div class="d-flex gap-2">
          <div class="flex-grow-1">
            <label class="inspector-label">Tamanho da Fonte (Cards)</label>
            <select v-model="block.settings.title_size" class="modern-input px-2">
              <option value="small">Pequena</option>
              <option value="medium">Média</option>
              <option value="large">Grande</option>
              <option value="huge">Gigante</option>
            </select>
          </div>
          <div class="flex-grow-1">
            <label class="inspector-label">Estilo</label>
            <select v-model="block.settings.text_transform" class="modern-input px-2">
              <option value="normal">Normal</option>
              <option value="uppercase">MAIÚSCULA</option>
              <option value="lowercase">minúscula</option>
            </select>
          </div>
        </div>

        <div>
          <label class="inspector-label">Peso da Fonte (Cards)</label>
          <div class="bg-surface border rounded-lg d-flex p-1">
            <v-btn flex-grow-1 variant="text" size="small" :color="block.settings.font_weight === 'normal' ? 'primary' : 'default'" @click="block.settings.font_weight = 'normal'">Normal</v-btn>
            <v-btn flex-grow-1 variant="text" size="small" :color="block.settings.font_weight === 'bold' ? 'primary' : 'default'" @click="block.settings.font_weight = 'bold'">Bold</v-btn>
            <v-btn flex-grow-1 variant="text" size="small" :color="block.settings.font_weight === 'black' || !block.settings.font_weight ? 'primary' : 'default'" @click="block.settings.font_weight = 'black'">Black</v-btn>
          </div>
        </div>
      </div>
    </div>

    <div class="config-group">
      <div class="config-header d-flex align-center justify-space-between">
        <div class="d-flex align-center gap-2">
          <v-icon size="16" color="primary">mdi-view-grid-plus</v-icon>
          Conteúdo dos Blocos
        </div>
        <v-btn size="x-small" color="primary" variant="tonal" class="font-weight-bold text-none rounded-lg" @click="addMosaicItem">
          <v-icon start size="14">mdi-plus</v-icon> Novo Bloco
        </v-btn>
      </div>

      <div class="d-flex flex-column gap-4 mt-2">
        <transition-group name="list-anim">
          <div v-for="(mItem, mIndex) in (block.settings.mosaic_items || [])" :key="mIndex" class="pa-4 border rounded-xl bg-background shadow-sm position-relative">

            <div class="d-flex align-center mb-4 gap-2 border-b pb-2">
              <v-chip size="small" :color="mIndex === 0 ? 'primary' : 'grey-darken-2'" class="font-weight-black rounded-lg">
                {{ mIndex + 1 }}
              </v-chip>
              <span class="text-caption font-weight-black text-uppercase tracking-widest flex-grow-1" :class="mIndex === 0 ? 'text-primary' : 'text-medium-emphasis'">
                Bloco {{ mIndex + 1 }}
              </span>
              <v-btn icon size="x-small" color="error" variant="text" @click="removeMosaicItem(mIndex)"><v-icon size="18">mdi-close</v-icon></v-btn>
            </div>

            <div class="d-flex flex-column gap-4">
              <div>
                <label class="inspector-label">Origem da Imagem</label>
                <div class="d-flex gap-2 bg-surface p-1 rounded-lg border">
                  <v-btn flex-grow-1 variant="text" size="small" :color="mItem.type === 'category' || !mItem.type ? 'primary' : 'default'" @click="mItem.type = 'category'">Pasta</v-btn>
                  <v-btn flex-grow-1 variant="text" size="small" :color="mItem.type === 'stamp' ? 'primary' : 'default'" @click="mItem.type = 'stamp'">Estampa</v-btn>
                </div>
              </div>

              <div v-if="mItem.type === 'category' || !mItem.type">
                <v-select v-model="mItem.category_id" :items="categories" item-title="name" item-value="id" variant="outlined" density="compact" hide-details bg-color="white" class="rounded-lg custom-select" placeholder="Escolha a pasta..."></v-select>
              </div>

              <div v-if="mItem.type === 'stamp'">
                <v-autocomplete v-model="mItem.stamp_id" :items="stamps" item-title="title" item-value="id" group-by="category_name" variant="outlined" density="compact" hide-details bg-color="white" class="rounded-lg custom-autocomplete" placeholder="Busque a estampa...">
                  <template v-slot:item="{ props, item }">
                    <v-list-item v-bind="props" :title="item.raw.title">
                      <template v-slot:prepend>
                        <v-avatar rounded="lg" size="32" class="mr-3 border"><v-img :src="item.raw.main_image_url" cover></v-img></v-avatar>
                      </template>
                    </v-list-item>
                  </template>
                </v-autocomplete>
              </div>

              <div>
                <label class="inspector-label">Título Visível (Opcional)</label>
                <input type="text" v-model="mItem.custom_title" class="modern-input" placeholder="Sobrescreve o original..." />
              </div>
            </div>
          </div>
        </transition-group>
      </div>
    </div>

    <div class="config-group">
      <div class="config-header d-flex align-center gap-2">
        <v-icon size="16" color="primary">mdi-palette</v-icon>
        Painel de Cores
      </div>
      <div class="d-flex flex-column gap-4">
        <div class="d-flex align-center gap-3">
          <label class="inspector-label m-0 flex-grow-1">Fundo da Seção Geral</label>
          <input type="color" v-model="block.settings.bg_color" class="color-picker" />
        </div>
        <div class="d-flex align-center gap-3">
          <label class="inspector-label m-0 flex-grow-1">Título da Seção</label>
          <input type="color" v-model="block.settings.text_color" class="color-picker" />
        </div>
        <div class="d-flex align-center gap-3">
          <label class="inspector-label m-0 flex-grow-1">Cor Base do Overlay</label>
          <input type="color" v-model="block.settings.overlay_color" class="color-picker" />
        </div>
      </div>
    </div>

  </div>

  <section v-else
           :id="`block-preview-${block._id}`"
           class="preview-section mosaic-section section-padding px-6 px-md-8 w-100 overflow-hidden"
           :class="[{ 'active-outline': isActive }]"
           :style="{ backgroundColor: block.settings.bg_color || '#ffffff' }">

    <div class="mx-auto w-100 transition-all" :style="{ maxWidth: `${block.settings.max_width || 1400}px` }">

      <div v-if="block.settings.title" class="text-center mb-12 mb-md-16" :style="{ color: block.settings.text_color || '#111827' }">
         <h2 class="text-h3 text-md-h2 font-weight-black m-0 tracking-tighter title-reveal">{{ block.settings.title }}</h2>
      </div>

      <div v-if="!block.settings.mosaic_items || block.settings.mosaic_items.length === 0" class="text-center py-16 opacity-40 border-2 border-dashed rounded-2xl mx-auto" style="max-width: 600px;">
        <v-icon size="64" class="mb-4">mdi-view-dashboard-variant-outline</v-icon>
        <h3 class="text-h6 font-weight-bold">Mosaico não configurado</h3>
      </div>

      <div v-else
           class="mosaic-engine w-100"
           :class="getLayoutEngineClass()"
           :style="{
             gap: `${block.settings.grid_gap !== undefined ? block.settings.grid_gap : 16}px`,
             height: block.settings.layout_style === 'slider' || block.settings.layout_style === 'stacked' ? 'auto' : `clamp(400px, 75vh, ${block.settings.min_height || 600}px)`
           }">

         <div v-for="(mItem, mIndex) in block.settings.mosaic_items" :key="mIndex"
              class="mosaic-block position-relative overflow-hidden group cursor-pointer"
              :class="[
                getBlockRoleClass(mIndex, block.settings.layout_style),
                `card-theme-${block.settings.card_style || 'glass'}`
              ]"
              :style="{
                borderRadius: `${block.settings.border_radius !== undefined ? block.settings.border_radius : 16}px`,
                minHeight: block.settings.layout_style === 'stacked' ? '400px' : 'auto'
              }">

            <img v-if="getMosaicImage(mItem, mIndex)"
                 :src="utils.getOptimizedUrl(getMosaicImage(mItem, mIndex), isBlockLarge(mIndex, block.settings.layout_style) ? 1600 : 800)"
                 class="mosaic-bg-img transition-transform group-hover-zoom" />

            <div v-else class="position-absolute inset-0 d-flex align-center justify-center bg-grey-lighten-3" style="z-index: 0;">
               <v-icon size="48" class="opacity-20">mdi-image-off-outline</v-icon>
            </div>

            <div class="mosaic-overlay transition-all"
                 :style="getOverlayStyle(block.settings.card_style, block.settings.overlay_color)"></div>

            <div class="mosaic-content position-absolute z-10 w-100 h-100 d-flex flex-column justify-end"
                 :class="isBlockLarge(mIndex, block.settings.layout_style) ? 'pa-8 pa-md-14' : 'pa-6 pa-md-8'">

              <div class="content-box transition-transform group-hover-lift">
                <h3 class="text-white title-shadow line-height-tight"
                    :class="[
                      getTypographyClass(),
                      isBlockLarge(mIndex, block.settings.layout_style) ? 'is-large-title' : 'is-small-title'
                    ]"
                    :style="{
                      textTransform: block.settings.text_transform || 'normal',
                      fontWeight: getFontWeight()
                    }">
                  {{ getMosaicTitle(mItem) }}
                </h3>

                <div class="mosaic-link text-white mt-3 d-flex align-center gap-2"
                     :class="[
                       isBlockLarge(mIndex, block.settings.layout_style) ? 'text-h6' : 'text-body-2',
                       { 'text-uppercase tracking-widest font-weight-bold': true }
                     ]">
                   Explorar
                   <v-icon size="20" class="link-icon transition-transform">mdi-arrow-right</v-icon>
                </div>
              </div>

            </div>
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
  categories: any[]
  stamps: any[]
}>()

const utils = inject<any>('builderUtils')

function addMosaicItem() {
  if (!props.block.settings.mosaic_items) props.block.settings.mosaic_items = []
  props.block.settings.mosaic_items.push({ type: 'category', category_id: null, custom_title: '' })
}

function removeMosaicItem(index: number) {
  props.block.settings.mosaic_items.splice(index, 1)
}

function getMosaicImage(mItem: any, index: number = 0) {
  if (!mItem) return null
  if (mItem.type === 'stamp' && mItem.stamp_id) {
     const stamp = utils.getStampObj(mItem.stamp_id)
     return stamp?.main_image_url || null
  }
  if ((mItem.type === 'category' || !mItem.type) && mItem.category_id) {
     const firstStamp = props.stamps.find(s => s.category_id === mItem.category_id && s.main_image_url)
     return firstStamp?.main_image_url || null
  }
  return null
}

function getMosaicTitle(mItem: any) {
  if (!mItem) return 'Selecionar'
  if (mItem.custom_title) return mItem.custom_title
  if ((mItem.type === 'category' || !mItem.type) && mItem.category_id) {
     return utils.getCategoryName(mItem.category_id) || 'Categoria'
  }
  if (mItem.type === 'stamp' && mItem.stamp_id) {
     const stamp = utils.getStampObj(mItem.stamp_id)
     return stamp ? stamp.title : 'Estampa'
  }
  return 'Nova Linha'
}

// ==========================================
// OS 10 MOTORES DE LAYOUT CSS GRID/FLEX
// ==========================================
function getLayoutEngineClass() {
  const style = props.block.settings.layout_style || 'editorial'
  return `engine-${style}`
}

function getBlockRoleClass(index: number, layoutStyle: string) {
  const style = layoutStyle || 'editorial'

  if (style === 'editorial') return index === 0 ? 'span-hero' : 'span-normal'
  if (style === 'bento') return (index === 0 || index === 3 || index === 4) ? 'span-wide' : 'span-square'
  if (style === 'masonry') return index % 5 === 0 ? 'span-hero' : (index % 3 === 0 ? 'span-tall' : 'span-square')
  if (style === 'hero_left') return index === 0 ? 'span-hero-left' : 'span-normal'
  if (style === 'hero_right') return index === 0 ? 'span-hero-right' : 'span-normal'
  if (style === 'hero_center') return index === 1 ? 'span-hero-center' : 'span-normal'
  if (style === 'grid_square') return 'span-square-strict'
  if (style === 'slider') return 'span-slider-item'
  if (style === 'stacked') return 'span-stack-full'
  if (style === 'diamond') return index % 2 === 0 ? 'span-wide' : 'span-square'

  return 'span-normal'
}

function isBlockLarge(index: number, layoutStyle: string) {
  const role = getBlockRoleClass(index, layoutStyle)
  return ['span-hero', 'span-wide', 'span-hero-left', 'span-hero-right', 'span-hero-center', 'span-stack-full'].includes(role)
}

// ==========================================
// CONTROLES DE TIPOGRAFIA E CORES
// ==========================================
function getTypographyClass() {
  const size = props.block.settings.title_size || 'large'
  if (size === 'small') return 'typo-small'
  if (size === 'medium') return 'typo-medium'
  if (size === 'large') return 'typo-large'
  if (size === 'huge') return 'typo-huge'
  return 'typo-large'
}

function getFontWeight() {
  const weight = props.block.settings.font_weight || 'black'
  if (weight === 'normal') return '400'
  if (weight === 'bold') return '700'
  return '900' // Black
}

function hexToRgb(hex: string) {
  var result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex || '#000000');
  return result ? `${parseInt(result[1], 16)}, ${parseInt(result[2], 16)}, ${parseInt(result[3], 16)}` : '0,0,0';
}

function getOverlayStyle(cardStyle: string, hexColor: string) {
  const rgb = hexToRgb(hexColor || '#000000')
  if (cardStyle === 'solid') return { background: `linear-gradient(to top, rgba(${rgb}, 0.9) 0%, rgba(${rgb}, 0.3) 50%, transparent 100%)` }
  if (cardStyle === 'minimal') return { background: `linear-gradient(to top, rgba(${rgb}, 0.6) 0%, transparent 40%)` }
  if (cardStyle === 'neumorphism') return { background: `rgba(${rgb}, 0.2)`, boxShadow: 'inset 0 0 0 1px rgba(255,255,255,0.2)' }
  // Glass default
  return { background: `linear-gradient(to top, rgba(${rgb}, 0.7) 0%, transparent 80%)`, backdropFilter: 'blur(2px)' }
}
</script>

<style scoped>
/* ==========================================
   ESTILOS DO INSPECTOR (SETTINGS)
   ========================================== */
.config-group { border: 1px solid rgba(var(--v-theme-on-surface), 0.08); border-radius: 12px; padding: 20px; background: rgba(var(--v-theme-surface), 0.8); backdrop-filter: blur(8px); margin-bottom: 16px;}
.config-header { font-size: 12px; font-weight: 800; margin-bottom: 20px; color: rgb(var(--v-theme-on-surface)); text-transform: uppercase; letter-spacing: 0.08em; border-bottom: 1px solid rgba(var(--v-theme-on-surface), 0.06); padding-bottom: 12px; }
.inspector-label { display: block; font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.06em; margin-bottom: 8px; color: rgba(var(--v-theme-on-surface), 0.7); }

.modern-input { min-height: 44px; width: 100%; border: 1px solid rgba(var(--v-theme-on-surface), 0.15); background: rgb(var(--v-theme-surface)); border-radius: 8px; transition: all 0.2s; font-size: 14px; padding: 0 14px; }
.modern-input:focus { border-color: rgb(var(--v-theme-primary)); outline: none; box-shadow: 0 0 0 4px rgba(var(--v-theme-primary), 0.1); }
.color-picker { width: 100%; height: 44px; border-radius: 8px; border: 1px solid rgba(var(--v-theme-on-surface), 0.15); cursor: pointer; }
.modern-range { cursor: pointer; accent-color: rgb(var(--v-theme-primary)); }

.list-anim-enter-active, .list-anim-leave-active { transition: all 0.3s ease; }
.list-anim-enter-from, .list-anim-leave-to { opacity: 0; transform: scale(0.95); }

/* ==========================================
   ESTILOS DO PREVIEW E MOTORES DE GRID
   ========================================== */
.mosaic-section { transition: all 0.4s ease; outline: 2px solid transparent; outline-offset: -2px; cursor: pointer; }
.mosaic-section:hover { outline-color: rgba(var(--v-theme-primary), 0.4); }
.active-outline { outline-color: rgb(var(--v-theme-primary)) !important; box-shadow: inset 0 0 0 4px rgba(var(--v-theme-primary), 0.2); z-index: 2; }

.section-padding { padding-top: 100px; padding-bottom: 100px; }
.title-reveal { letter-spacing: -0.03em; }

/* OS 10 MOTORES MÁGICOS DE CSS GRID */

/* 1. Editorial Assimétrico */
.engine-editorial { display: grid; grid-template-columns: 1.5fr 1fr; grid-auto-rows: 1fr; }
.engine-editorial .span-hero { grid-column: 1 / 2; grid-row: span 2; }
.engine-editorial .span-normal { grid-column: span 1; grid-row: span 1; }

/* 2. Bento Box */
.engine-bento { display: grid; grid-template-columns: repeat(4, 1fr); grid-auto-rows: 1fr; }
.engine-bento .span-wide { grid-column: span 2; grid-row: span 1; }
.engine-bento .span-square { grid-column: span 1; grid-row: span 1; }

/* 3. Masonry */
.engine-masonry { display: grid; grid-template-columns: repeat(4, 1fr); grid-auto-rows: 250px; }
.engine-masonry .span-hero { grid-column: span 2; grid-row: span 2; }
.engine-masonry .span-tall { grid-column: span 1; grid-row: span 2; }
.engine-masonry .span-square { grid-column: span 1; grid-row: span 1; }

/* 4. Hero Left */
.engine-hero_left { display: grid; grid-template-columns: 2fr 1fr 1fr; grid-auto-rows: 1fr; }
.engine-hero_left .span-hero-left { grid-column: 1 / 2; grid-row: span 2; }
.engine-hero_left .span-normal { grid-column: span 1; grid-row: span 1; }

/* 5. Hero Right */
.engine-hero_right { display: grid; grid-template-columns: 1fr 1fr 2fr; grid-auto-rows: 1fr; }
.engine-hero_right .span-hero-right { grid-column: 3 / 4; grid-row: span 2; }
.engine-hero_right .span-normal { grid-column: span 1; grid-row: span 1; }

/* 6. Hero Center */
.engine-hero_center { display: grid; grid-template-columns: 1fr 2fr 1fr; grid-auto-rows: 1fr; }
.engine-hero_center .span-hero-center { grid-column: 2 / 3; grid-row: span 2; }
.engine-hero_center .span-normal { grid-column: span 1; grid-row: span 1; }

/* 7. Grid Quadrado Estrito */
.engine-grid_square { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); grid-auto-rows: 1fr; }
.engine-grid_square .span-square-strict { aspect-ratio: 1/1; height: auto; }

/* 8. Slider Horizontal */
.engine-slider { display: flex; overflow-x: auto; scroll-snap-type: x mandatory; padding-bottom: 16px; }
.engine-slider .span-slider-item { min-width: 400px; height: 500px; scroll-snap-align: center; flex-shrink: 0; }

/* 9. Cascata Vertical (Stack) */
.engine-stacked { display: flex; flex-direction: column; }
.engine-stacked .span-stack-full { width: 100%; height: 400px; }

/* 10. Diamond / ZigZag Grid */
.engine-diamond { display: grid; grid-template-columns: repeat(3, 1fr); grid-auto-rows: 300px; }
.engine-diamond .span-wide { grid-column: span 2; }
.engine-diamond .span-square { grid-column: span 1; }

/* RESPONSIVIDADE FORÇADA PARA MOBILE E TABLET */
@media(max-width: 1024px) {
  .engine-editorial, .engine-hero_left, .engine-hero_right, .engine-hero_center { grid-template-columns: 1fr 1fr; }
  .engine-bento, .engine-masonry, .engine-diamond { grid-template-columns: repeat(2, 1fr); }
  .span-hero, .span-hero-left, .span-hero-right, .span-hero-center { grid-column: span 2 !important; }
}

@media(max-width: 600px) {
  /* Em telas pequenas, TODOS os grids viram 1 coluna ou Slider */
  .mosaic-engine:not(.engine-slider) { grid-template-columns: 1fr !important; grid-auto-rows: 350px !important; }
  .mosaic-engine:not(.engine-slider) > div { grid-column: span 1 !important; grid-row: span 1 !important; }
  .engine-slider .span-slider-item { min-width: 280px; height: 400px; }
  .section-padding { padding-top: 60px; padding-bottom: 60px; }
}

/* ==========================================
   ESTÉTICA DOS CARDS E TIPOGRAFIA
   ========================================== */
.mosaic-block {
  /* O border-radius e gap vêm via inline style do Vue para controle total */
  background-color: #f1f5f9;
  box-shadow: 0 10px 30px -10px rgba(0,0,0,0.1);
  transform: translateZ(0); /* Anti-aliasing Safari */
}

.mosaic-bg-img {
  position: absolute; inset: 0; width: 100%; height: 100%; object-fit: cover; z-index: 0;
}

.mosaic-overlay {
  position: absolute; inset: 0; z-index: 1; transition: all 0.4s ease;
}

/* Themes Extras Hover */
.card-theme-neumorphism { border: 1px solid rgba(255,255,255,0.3); }
.group:hover .card-theme-glass .mosaic-overlay { backdrop-filter: blur(8px); background: rgba(0,0,0,0.4) !important; }
.group:hover .card-theme-solid .mosaic-overlay { background: linear-gradient(to top, rgba(0,0,0,0.95) 0%, rgba(0,0,0,0.5) 100%) !important; }

/* Tipografia Dinâmica */
.typo-small { font-size: 1.25rem; }
.typo-medium { font-size: 1.75rem; }
.typo-large { font-size: clamp(2rem, 3vw, 2.5rem); }
.typo-huge { font-size: clamp(2.5rem, 5vw, 4rem); letter-spacing: -0.04em; }

.is-large-title { margin-bottom: 16px; }
.is-small-title { margin-bottom: 8px; }
.title-shadow { text-shadow: 0 4px 16px rgba(0,0,0,0.5); }
.line-height-tight { line-height: 1.05; }

/* Interações Hover Padrão Ouro */
.group-hover-zoom { transition: transform 1s cubic-bezier(0.25, 0.46, 0.45, 0.94); }
.group:hover .group-hover-zoom { transform: scale(1.1); }

.content-box { transition: transform 0.4s cubic-bezier(0.16, 1, 0.3, 1); }
.group:hover .group-hover-lift { transform: translateY(-8px); }

.mosaic-link { opacity: 0; transform: translateY(15px); transition: all 0.4s cubic-bezier(0.16, 1, 0.3, 1); }
.group:hover .mosaic-link { opacity: 1; transform: translateY(0); }
.group:hover .link-icon { transform: translateX(6px); }

/* Scrollbar do Slider */
.engine-slider::-webkit-scrollbar { height: 6px; }
.engine-slider::-webkit-scrollbar-track { background: rgba(0,0,0,0.05); border-radius: 10px; }
.engine-slider::-webkit-scrollbar-thumb { background: rgba(var(--v-theme-primary), 0.3); border-radius: 10px; }
</style>
