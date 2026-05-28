<template>
  <div v-if="mode === 'settings'" class="collections-block-settings d-flex flex-column gap-6">

    <div class="config-group">
      <div class="config-header d-flex align-center gap-2">
        <v-icon size="16" color="primary">mdi-layers-outline</v-icon>
        Layout da Curadoria
      </div>
      <div class="d-flex flex-column gap-4">
        <div>
          <label class="inspector-label">Estilo Estrutural</label>
          <select v-model="block.settings.layout_style" class="modern-input px-3">
            <option value="zigzag">Editorial Zig-Zag (Clássico Premium)</option>
            <option value="grid">Lookbook Grid (4 Colunas)</option>
            <option value="list">Índice Editorial (Hover Reveal)</option>
            <option value="featured">Bento Box (Destaque Maior)</option>
          </select>
        </div>

        <div>
          <label class="inspector-label">Tratamento Visual dos Cards</label>
          <select v-model="block.settings.visual_theme" class="modern-input px-3">
            <option value="minimal">Minimalista (Foco na Fotografia)</option>
            <option value="bordered">Com Borda e Sombra Suave</option>
            <option value="glass">Glassmorphism (Overlay Translúcido)</option>
          </select>
        </div>
      </div>
    </div>

    <div class="config-group">
      <div class="config-header d-flex align-center gap-2">
        <v-icon size="16" color="primary">mdi-format-title</v-icon>
        Cabeçalho da Seção
      </div>
      <div class="d-flex flex-column gap-4">
        <div>
          <label class="inspector-label">Título Principal</label>
          <input type="text" v-model="block.settings.title" class="modern-input" placeholder="Ex: Coleções Exclusivas" />
        </div>
        <div>
          <label class="inspector-label">Subtítulo / Kicker</label>
          <input type="text" v-model="block.settings.subtitle" class="modern-input" placeholder="Ex: Descubra" />
        </div>
      </div>
    </div>

    <div class="config-group">
      <div class="config-header d-flex align-center justify-space-between">
        <div class="d-flex align-center gap-2">
          <v-icon size="16" color="primary">mdi-view-list</v-icon>
          Linhas Vinculadas
        </div>
        <v-btn size="x-small" color="primary" variant="tonal" class="font-weight-bold text-none rounded-lg" @click="addItem">
          <v-icon start size="14">mdi-plus</v-icon> Adicionar
        </v-btn>
      </div>

      <div class="d-flex flex-column gap-4 mt-2">
        <transition-group name="list-anim">
          <div v-for="(item, index) in (block.settings.zigzag_items || [])" :key="index" class="pa-4 border rounded-xl bg-background shadow-sm">
            <div class="d-flex justify-space-between align-center mb-4 pb-2 border-b">
              <span class="text-caption font-weight-black text-primary text-uppercase tracking-widest">Coleção {{ index + 1 }}</span>
              <v-btn icon size="x-small" color="error" variant="text" @click="removeItem(index)"><v-icon size="18">mdi-close</v-icon></v-btn>
            </div>

            <div class="d-flex flex-column gap-4">
              <div>
                <label class="inspector-label text-primary">Pasta / Categoria Origem</label>
                <v-select v-model="item.category_id" :items="categories" item-title="name" item-value="id" variant="outlined" density="compact" hide-details class="bg-surface rounded-lg custom-select" placeholder="Escolha a pasta..."></v-select>
              </div>

              <div>
                <label class="inspector-label">Título da Linha</label>
                <input type="text" v-model="item.title" class="modern-input" placeholder="Ex: Alto Verão 26" />
              </div>

              <div>
                <label class="inspector-label">Resumo Narrativo</label>
                <textarea v-model="item.text" rows="2" class="modern-input" style="resize:vertical;" placeholder="O conceito por trás desta linha..."></textarea>
              </div>

              <div>
                <label class="inspector-label">Texto do Botão (Vazio = Oculto)</label>
                <input type="text" v-model="item.button_text" class="modern-input" placeholder="Ex: Explorar Linha" />
              </div>
            </div>
          </div>
        </transition-group>

        <div v-if="!block.settings.zigzag_items || block.settings.zigzag_items.length === 0" class="text-center py-6 opacity-40 border border-dashed rounded-lg">
          <v-icon size="24" class="mb-2">mdi-layers-off-outline</v-icon>
          <div class="text-caption font-weight-medium">Nenhuma coleção adicionada.</div>
        </div>
      </div>
    </div>

    <div class="config-group">
      <div class="config-header d-flex align-center gap-2">
        <v-icon size="16" color="primary">mdi-palette</v-icon>
        Design de Cores
      </div>
      <div class="d-flex flex-column gap-4">
        <div class="d-flex align-center gap-3">
          <label class="inspector-label m-0 flex-grow-1">Fundo da Seção</label>
          <input type="color" v-model="block.settings.bg_color" class="color-picker" />
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
           class="preview-section collections-section section-padding px-6 px-md-8"
           :class="[{ 'active-outline': isActive }, `theme-${block.settings.visual_theme || 'minimal'}`]"
           :style="{ backgroundColor: block.settings.bg_color || 'transparent' }">

    <div class="max-w-1400 mx-auto w-100">

      <div class="text-center mb-16" :style="{ color: block.settings.text_color || '#111827' }">
         <div v-if="block.settings.subtitle" class="font-weight-black text-caption text-uppercase tracking-widest mb-3 opacity-70 kicker-line">
           {{ block.settings.subtitle }}
         </div>
         <h2 class="text-h3 text-md-h2 font-weight-black m-0 tracking-tighter title-reveal">{{ block.settings.title || 'Nossas Linhas' }}</h2>
      </div>

      <div v-if="!block.settings.zigzag_items || block.settings.zigzag_items.length === 0" class="text-center py-16 opacity-40 border-2 border-dashed rounded-2xl mx-auto" style="max-width: 600px;">
        <v-icon size="64" class="mb-4">mdi-shape-plus</v-icon>
        <h3 class="text-h6 font-weight-bold">Nenhuma linha configurada</h3>
        <p class="text-caption">Adicione coleções no painel lateral.</p>
      </div>

      <div v-else-if="block.settings.layout_style === 'zigzag' || !block.settings.layout_style" class="zigzag-wrapper d-flex flex-column">

        <div v-for="(item, i) in block.settings.zigzag_items" :key="i"
             class="zigzag-row d-flex flex-column flex-md-row align-center justify-space-between group"
             :class="i % 2 !== 0 ? 'flex-md-row-reverse' : ''">

          <div class="zigzag-media position-relative rounded-lg overflow-hidden card-styling">
            <v-img v-if="getCollectionImage(item)"
                   :src="utils.getOptimizedUrl(getCollectionImage(item), 800)"
                   cover
                   class="w-100 h-100 transition-transform group-hover-zoom"></v-img>

            <div v-else class="bg-surface w-100 h-100 d-flex align-center justify-center text-medium-emphasis">
              <v-icon size="48" class="opacity-20 mb-2">mdi-image-outline</v-icon>
            </div>
            <div class="hover-overlay"></div>
          </div>

          <div class="zigzag-content py-6 py-md-0"
               :style="{ color: block.settings.text_color || '#111827', textAlign: i % 2 !== 0 ? 'right' : 'left' }">

            <div class="text-caption font-weight-bold text-uppercase tracking-widest mb-4 opacity-50 font-mono">
              0{{ i + 1 }} &mdash; {{ utils.getCategoryName(item.category_id) || 'Linha' }}
            </div>

            <h3 class="text-h4 text-md-h3 font-weight-black mb-6 tracking-tighter line-height-tight">
              {{ item.title || `Coleção ${i+1}` }}
            </h3>

            <p class="text-body-1 opacity-70 mb-8 font-weight-regular line-height-relaxed max-w-400"
               :class="i % 2 !== 0 ? 'ml-auto' : ''" style="white-space: pre-line;">
              {{ item.text || 'Explore nossa curadoria premium desenvolvida com rigor técnico e estético.' }}
            </p>

            <div class="text-button text-caption font-weight-bold text-uppercase tracking-widest border-b-2 d-inline-block pb-1 transition-all hover-expand-border"
                 :style="{ borderColor: block.settings.button_color || 'currentColor' }">
               {{ item.button_text || 'Explorar Linha' }}
            </div>
          </div>

        </div>
      </div>

      <div v-else-if="block.settings.layout_style === 'grid'" class="lookbook-grid">
        <div v-for="(item, i) in block.settings.zigzag_items" :key="i" class="lookbook-card group cursor-pointer" @click="goToDiscover(item)">

          <div class="lookbook-media rounded-lg overflow-hidden mb-4 position-relative card-styling">
             <v-img v-if="getCollectionImage(item)" :src="utils.getOptimizedUrl(getCollectionImage(item), 600)" cover class="transition-transform group-hover-zoom"></v-img>
             <div v-else class="bg-surface w-100 h-100 d-flex align-center justify-center"><v-icon size="32" class="opacity-20">mdi-image-outline</v-icon></div>
             <div class="hover-overlay"></div>
          </div>

          <div class="lookbook-info text-center" :style="{ color: block.settings.text_color || '#111827' }">
            <div class="text-[10px] font-weight-bold text-uppercase tracking-widest mb-1 opacity-50">{{ utils.getCategoryName(item.category_id) }}</div>
            <h4 class="text-h6 font-weight-black tracking-tighter mb-1">{{ item.title || 'Coleção' }}</h4>
            <p class="text-[12px] opacity-70 line-clamp-2 max-w-250 mx-auto">{{ item.text }}</p>
          </div>
        </div>
      </div>

      <div v-else-if="block.settings.layout_style === 'list'" class="editorial-index max-w-1000 mx-auto border-t border-opacity-10" :style="{ borderColor: block.settings.text_color || '#111827' }">
        <div v-for="(item, i) in block.settings.zigzag_items" :key="i"
             class="index-row py-8 border-b border-opacity-10 d-flex align-center justify-space-between group cursor-pointer position-relative"
             :style="{ borderColor: block.settings.text_color || '#111827' }"
             @click="goToDiscover(item)">

          <div class="d-flex align-end gap-6 position-relative z-10">
            <span class="text-h6 font-weight-black opacity-20 font-mono transition-opacity group-hover-opacity-100" :style="{ color: block.settings.text_color || '#111827' }">
              {{ (i + 1).toString().padStart(2, '0') }}
            </span>
            <div>
              <h4 class="text-h4 text-md-h3 font-weight-black tracking-tighter line-height-tight transition-transform group-hover-nudge"
                  :style="{ color: block.settings.text_color || '#111827' }">
                {{ item.title || utils.getCategoryName(item.category_id) || 'Nova Linha' }}
              </h4>
            </div>
          </div>

          <div class="index-reveal-img position-absolute rounded-lg overflow-hidden shadow-lg border d-none d-md-block">
             <v-img v-if="getCollectionImage(item)" :src="utils.getOptimizedUrl(getCollectionImage(item), 400)" cover class="w-100 h-100"></v-img>
          </div>

          <div class="position-relative z-10 opacity-0 transition-all group-hover-opacity-100 group-hover-nudge-left" :style="{ color: block.settings.text_color || '#111827' }">
             <span class="text-caption font-weight-bold text-uppercase tracking-widest d-none d-sm-inline mr-2">{{ item.button_text || 'Ver Coleção' }}</span>
             <v-icon>mdi-arrow-right</v-icon>
          </div>
        </div>
      </div>

      <div v-else-if="block.settings.layout_style === 'featured'" class="bento-featured-grid">
        <div v-for="(item, i) in block.settings.zigzag_items" :key="i"
             class="bento-card group cursor-pointer position-relative overflow-hidden rounded-lg card-styling"
             :class="i === 0 ? 'bento-hero' : 'bento-standard'"
             @click="goToDiscover(item)">

          <v-img v-if="getCollectionImage(item)"
                 :src="utils.getOptimizedUrl(getCollectionImage(item), i === 0 ? 1000 : 600)"
                 cover class="position-absolute inset-0 w-100 h-100 transition-transform group-hover-zoom z-0"></v-img>

          <div class="bento-overlay position-absolute inset-0 z-10 transition-opacity"></div>

          <div class="position-relative z-20 w-100 h-100 d-flex flex-column justify-end pa-6 pa-md-8 text-white">
            <div class="text-[10px] font-weight-bold text-uppercase tracking-widest mb-1 opacity-80">{{ utils.getCategoryName(item.category_id) }}</div>
            <h4 class="font-weight-black tracking-tighter title-shadow" :class="i === 0 ? 'text-h3 mb-3' : 'text-h5 mb-1'">{{ item.title || 'Coleção' }}</h4>
            <p v-if="i === 0" class="text-body-2 opacity-80 mb-6 max-w-400 font-weight-regular text-shadow line-clamp-2">{{ item.text }}</p>
            <div v-if="i === 0">
              <v-btn :color="block.settings.button_color || 'white'" :class="utils.getTextColorClass(block.settings.button_color, 'white')" variant="flat" size="large" class="rounded text-none font-weight-bold px-8">
                {{ item.button_text || 'Ver Coleção' }}
              </v-btn>
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

function addItem() {
  if (!props.block.settings.zigzag_items) props.block.settings.zigzag_items = []
  props.block.settings.zigzag_items.push({ category_id: null, title: '', text: '', button_text: 'Explorar' })
}

function removeItem(index: number) {
  props.block.settings.zigzag_items.splice(index, 1)
}

function getCollectionImage(item: any) {
  if (!item.category_id) return null
  const stamp = props.stamps.find(s => s.category_id === item.category_id && s.main_image_url)
  return stamp ? stamp.main_image_url : null
}

function goToDiscover(item: any) {
  // Apenas placeholder, o redirecionamento real é tratado no MarketplaceHome.vue
}
</script>

<style scoped>
/* ==========================================
   ESTILOS DO INSPECTOR (SETTINGS)
   ========================================== */
.config-group { border: 1px solid rgba(var(--v-theme-on-surface), 0.08); border-radius: 12px; padding: 20px; background: rgba(var(--v-theme-surface), 0.8); backdrop-filter: blur(8px); margin-bottom: 16px; }
.config-header { font-size: 12px; font-weight: 800; margin-bottom: 20px; color: rgb(var(--v-theme-on-surface)); text-transform: uppercase; letter-spacing: 0.08em; border-bottom: 1px solid rgba(var(--v-theme-on-surface), 0.06); padding-bottom: 12px; }
.inspector-label { display: block; font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.06em; margin-bottom: 8px; color: rgba(var(--v-theme-on-surface), 0.7); }

.modern-input { min-height: 44px; width: 100%; border: 1px solid rgba(var(--v-theme-on-surface), 0.15); background: rgb(var(--v-theme-surface)); border-radius: 8px; transition: all 0.2s; font-size: 14px; padding: 0 14px; }
.modern-input:focus { border-color: rgb(var(--v-theme-primary)); outline: none; box-shadow: 0 0 0 4px rgba(var(--v-theme-primary), 0.1); }
textarea.modern-input { padding-top: 12px; }
.color-picker { width: 100%; height: 44px; border-radius: 8px; border: 1px solid rgba(var(--v-theme-on-surface), 0.15); cursor: pointer; }

/* ==========================================
   ESTILOS DO PREVIEW (CANVAS REFINADO)
   ========================================== */
.collections-section { transition: outline 0.2s; outline: 2px solid transparent; outline-offset: -2px; cursor: pointer; }
.collections-section:hover { outline-color: rgba(var(--v-theme-primary), 0.4); }
.active-outline { outline-color: rgb(var(--v-theme-primary)) !important; box-shadow: inset 0 0 0 4px rgba(var(--v-theme-primary), 0.1); z-index: 2; }

.section-padding { padding-top: 100px; padding-bottom: 100px; }
.kicker-line { color: rgb(var(--v-theme-primary)); }
.line-height-relaxed { line-height: 1.6; }
.line-height-tight { line-height: 1.05; }
.max-w-400 { max-width: 400px; }
.max-w-250 { max-width: 250px; }

/* TRATAMENTO VISUAL (THEMES) */
.theme-minimal .card-styling { border: none; background: #f8fafc; }
.theme-bordered .card-styling { border: 1px solid rgba(0,0,0,0.05); box-shadow: 0 10px 30px -10px rgba(0,0,0,0.08); background: #ffffff; }
.theme-glass .card-styling { border: 1px solid rgba(255,255,255,0.2); backdrop-filter: blur(10px); background: rgba(255,255,255,0.05); }

/* ------------------------------------------
   LAYOUT 1: ZIGZAG EDITORIAL (COMPACTO)
   ------------------------------------------ */
.zigzag-wrapper { gap: 80px; } /* Menos gap que antes, mais coeso */

.zigzag-row {
  max-width: 1000px; /* Trava a largura máxima para não esgarçar em telas ultrawide */
  margin: 0 auto;
  gap: 48px;
}

.zigzag-media {
  width: 45%;
  max-width: 460px; /* IMAGEM NUNCA FICA GIGANTE */
  aspect-ratio: 4 / 5; /* Retrato clássico */
}

.zigzag-content {
  width: 55%;
  max-width: 480px;
}

/* ------------------------------------------
   LAYOUT 2: LOOKBOOK GRID (4 COLUNAS)
   ------------------------------------------ */
.lookbook-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 40px 24px;
}
.lookbook-media {
  aspect-ratio: 4 / 5;
  width: 100%;
}

@media(max-width: 1280px) { .lookbook-grid { grid-template-columns: repeat(3, 1fr); } }
@media(max-width: 960px) { .lookbook-grid { grid-template-columns: repeat(2, 1fr); } }
@media(max-width: 600px) { .lookbook-grid { grid-template-columns: repeat(1, 1fr); max-width: 380px; margin: 0 auto; } }

/* ------------------------------------------
   LAYOUT 3: ÍNDICE EDITORIAL (LISTA)
   ------------------------------------------ */
.index-row {
  overflow: visible; /* Necessário para a imagem flutuante vazar */
}

.group-hover-opacity-100 { opacity: 1 !important; }
.group-hover-nudge { transition: transform 0.4s cubic-bezier(0.16, 1, 0.3, 1); }
.group:hover .group-hover-nudge { transform: translateX(8px); }

.group-hover-nudge-left { transition: all 0.4s cubic-bezier(0.16, 1, 0.3, 1); }
.group:hover .group-hover-nudge-left { transform: translateX(-8px); }

/* Imagem Flutuante Mágica */
.index-reveal-img {
  width: 220px;
  aspect-ratio: 3 / 4;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%) scale(0.9) rotate(-3deg);
  opacity: 0;
  pointer-events: none;
  z-index: 20;
  transition: all 0.5s cubic-bezier(0.25, 0.46, 0.45, 0.94);
}
.group:hover .index-reveal-img {
  opacity: 1;
  transform: translate(-50%, -50%) scale(1) rotate(2deg);
  box-shadow: 0 30px 60px -15px rgba(0,0,0,0.3);
}

/* ------------------------------------------
   LAYOUT 4: BENTO FEATURED
   ------------------------------------------ */
.bento-featured-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  grid-auto-rows: 280px; /* Altura da linha menor para o mosaico ficar compacto */
  gap: 20px;
}
.bento-hero {
  grid-column: span 2;
  grid-row: span 2;
}

@media(max-width: 1024px) {
  .bento-featured-grid { grid-template-columns: repeat(3, 1fr); }
}
@media(max-width: 768px) {
  .bento-featured-grid { grid-template-columns: repeat(2, 1fr); grid-auto-rows: 240px; }
  .bento-hero { grid-column: span 2; grid-row: span 1; } /* Vira um banner largo no mobile */
}
@media(max-width: 500px) {
  .bento-featured-grid { grid-template-columns: 1fr; }
  .bento-hero { grid-column: span 1; }
}

/* OVERLAYS E HOVERS GERAIS */
.bento-overlay {
  background: linear-gradient(to top, rgba(0,0,0,0.85) 0%, rgba(0,0,0,0.1) 60%, transparent 100%);
}
.group:hover .bento-overlay { background: linear-gradient(to top, rgba(0,0,0,0.95) 0%, rgba(0,0,0,0.3) 60%, rgba(0,0,0,0.1) 100%); }

.hover-overlay {
  position: absolute; inset: 0; background: rgba(0,0,0,0.08); opacity: 0; transition: opacity 0.4s ease; z-index: 5; pointer-events: none;
}
.group:hover .hover-overlay { opacity: 1; }

.group-hover-zoom { transition: transform 0.8s cubic-bezier(0.25, 0.46, 0.45, 0.94); }
.group:hover .group-hover-zoom { transform: scale(1.06); }

.hover-expand-border { border-color: transparent !important; background-image: linear-gradient(to right, currentColor 0%, currentColor 100%); background-position: 0 100%; background-repeat: no-repeat; background-size: 0 2px; transition: background-size 0.3s ease; }
.group:hover .hover-expand-border { background-size: 100% 2px; }

.title-shadow { text-shadow: 0 4px 12px rgba(0,0,0,0.4); }
.text-shadow { text-shadow: 0 2px 8px rgba(0,0,0,0.6); }

/* Ajustes Mobile ZigZag */
@media(max-width: 960px) {
  .zigzag-row { flex-direction: column !important; text-align: center !important; gap: 32px; }
  .zigzag-media { width: 100%; max-width: 400px; margin: 0 auto; }
  .zigzag-content { width: 100%; max-width: 100%; }
  .zigzag-row .max-w-400 { margin-left: auto !important; margin-right: auto !important; }
}
</style>
