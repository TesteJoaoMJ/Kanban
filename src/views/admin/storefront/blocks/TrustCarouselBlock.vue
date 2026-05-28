<template>
  <div v-if="mode === 'settings'" class="trust-block-settings d-flex flex-column gap-6">

    <div class="config-group">
      <div class="config-header d-flex align-center gap-2">
        <v-icon size="16" color="primary">mdi-view-carousel-outline</v-icon>
        Estrutura e Comportamento
      </div>
      <div class="d-flex flex-column gap-4">
        <div>
          <label class="inspector-label">Layout da Seção</label>
          <select v-model="block.settings.layout_style" class="modern-input px-3">
            <option value="marquee">Linha Única Contínua (Infinito)</option>
            <option value="stacked">Empilhado Duplo (Esquerda/Direita)</option>
            <option value="grid">Grid Estático Centralizado (Premium)</option>
          </select>
        </div>

        <div>
          <label class="inspector-label">Tema Visual das Logos</label>
          <select v-model="block.settings.logo_theme" class="modern-input px-3">
            <option value="monochrome">Monocromático Sutil (Ganha cor no Hover)</option>
            <option value="original">Cores Originais (Opacidade 80%)</option>
            <option value="high-contrast">Alto Contraste (Branco puro para fundos escuros)</option>
          </select>
        </div>

        <div v-if="block.settings.layout_style !== 'grid'">
          <label class="inspector-label d-flex justify-space-between">
            Velocidade da Animação
            <span class="text-primary font-weight-black">{{ block.settings.speed || 40 }}s</span>
          </label>
          <input type="range" v-model.number="block.settings.speed" min="15" max="80" step="5" class="w-100 modern-range" />
          <p class="text-[10px] text-medium-emphasis mt-1 m-0">Menor o tempo = Mais rápido. Padrão suave: 40s.</p>
        </div>
      </div>
    </div>

    <div class="config-group">
      <div class="config-header d-flex align-center gap-2">
        <v-icon size="16" color="primary">mdi-format-title</v-icon>
        Textos da Seção
      </div>
      <div class="d-flex flex-column gap-4">
        <div>
          <label class="inspector-label">Título</label>
          <input type="text" v-model="block.settings.title" class="modern-input" placeholder="Ex: Marcas que confiam no nosso acervo" />
        </div>
        <div>
          <label class="inspector-label">Subtítulo (Kicker)</label>
          <input type="text" v-model="block.settings.subtitle" class="modern-input" placeholder="Ex: Nossos Parceiros" />
        </div>
      </div>
    </div>

    <div class="config-group">
      <div class="config-header d-flex align-center justify-space-between">
        <div class="d-flex align-center gap-2">
          <v-icon size="16" color="primary">mdi-domain</v-icon>
          Logos das Marcas
        </div>
        <v-btn size="x-small" color="primary" variant="tonal" class="font-weight-bold text-none rounded" @click="addLogo">
          <v-icon start size="14">mdi-plus</v-icon> Adicionar
        </v-btn>
      </div>

      <div class="d-flex flex-column gap-3 mt-2">
        <transition-group name="list-anim">
          <div v-for="(logo, lIdx) in (block.settings.logos || [])" :key="lIdx" class="logo-config-item pa-3 border rounded-lg bg-background d-flex align-center gap-3 shadow-sm">

            <div class="bg-surface rounded border d-flex align-center justify-center overflow-hidden flex-shrink-0" style="width: 70px; height: 46px; position: relative;">
              <img v-if="logo.image_url" :src="logo.image_url" style="width: 100%; height: 100%; object-fit: contain; padding: 4px;" />
              <v-icon v-else size="20" class="opacity-30">mdi-image</v-icon>
            </div>

            <v-btn variant="outlined" size="small" color="primary" class="flex-grow-1 text-none font-weight-bold" style="border-width: 1px;" @click="$emit('upload', `logos.${lIdx}.image_url`)">
              {{ logo.image_url ? 'Trocar Logo' : 'Fazer Upload' }}
            </v-btn>

            <v-btn icon size="small" color="error" variant="text" class="flex-shrink-0" @click="removeLogo(lIdx)">
              <v-icon size="18">mdi-delete-outline</v-icon>
            </v-btn>

          </div>
        </transition-group>

        <div v-if="!block.settings.logos || block.settings.logos.length === 0" class="text-center py-6 opacity-40 border border-dashed rounded-lg">
          <v-icon size="24" class="mb-2">mdi-domain-off</v-icon>
          <div class="text-caption font-weight-medium">Nenhuma logo adicionada</div>
        </div>
      </div>
    </div>

    <div class="config-group">
      <div class="config-header d-flex align-center gap-2">
        <v-icon size="16" color="primary">mdi-palette</v-icon>
        Design do Fundo
      </div>
      <div class="d-flex flex-column gap-4">
        <div>
          <label class="inspector-label">Imagem de Fundo (Opcional)</label>
          <div v-if="block.settings.bg_url" class="rounded-lg border overflow-hidden bg-background d-flex flex-column mb-3 shadow-sm position-relative">
            <img :src="block.settings.bg_url" style="height: 80px; width: 100%; object-fit: cover;" />
            <v-btn size="x-small" color="error" variant="flat" class="rounded-0 text-none" block @click="block.settings.bg_url = ''">Remover Fundo</v-btn>
          </div>
          <v-btn v-else block color="primary" variant="tonal" class="text-none font-weight-bold rounded-lg border-dashed border-primary" style="border-width: 1px;" prepend-icon="mdi-cloud-upload-outline" @click="$emit('upload', 'bg_url')">
            Upload Fundo Texturizado
          </v-btn>
        </div>

        <div v-if="block.settings.bg_url">
          <label class="inspector-label d-flex justify-space-between">
            Escurecimento da Imagem
            <span class="text-primary font-weight-black">{{ ((block.settings.overlay_opacity !== undefined ? block.settings.overlay_opacity : 0.7) * 100).toFixed(0) }}%</span>
          </label>
          <input type="range" v-model.number="block.settings.overlay_opacity" min="0" max="0.9" step="0.1" class="w-100 modern-range" />
        </div>

        <div class="d-flex align-center gap-3">
          <label class="inspector-label m-0 flex-grow-1">Cor de Fundo Base</label>
          <input type="color" v-model="block.settings.bg_color" class="color-picker" />
        </div>

        <div class="d-flex align-center gap-3">
          <label class="inspector-label m-0 flex-grow-1">Cor do Texto</label>
          <input type="color" v-model="block.settings.text_color" class="color-picker" />
        </div>
      </div>
    </div>

  </div>

  <section v-else
           :id="`block-preview-${block._id}`"
           class="preview-section trust-carousel-section position-relative section-padding overflow-hidden"
           :class="[{ 'active-outline': isActive }]"
           :style="computedStyle">

    <div class="position-relative z-index-2 w-100 py-4 py-md-8">

      <div class="text-center mb-10 mb-md-16" :style="{ color: block.settings.text_color || '#111827' }">
         <div v-if="block.settings.subtitle" class="font-weight-black text-caption text-uppercase tracking-widest mb-3 opacity-70 kicker-line">
           {{ block.settings.subtitle }}
         </div>
         <h3 class="text-h4 text-md-h3 font-weight-black tracking-tighter title-shadow-light">
           {{ block.settings.title || 'Marcas que confiam na nossa qualidade' }}
         </h3>
      </div>

      <div v-if="validLogos.length === 0" class="w-100 text-center text-medium-emphasis py-8 font-weight-medium border border-dashed rounded-xl mx-auto max-w-600">
        <v-icon size="48" class="mb-3 opacity-30">mdi-domain-off</v-icon><br/>
        Adicione logos de parceiros no painel lateral.
      </div>

      <div v-else-if="block.settings.layout_style === 'grid'" class="trust-grid-container max-w-1200 mx-auto px-6">
         <div v-for="(logo, lIdx) in validLogos" :key="`g-${lIdx}`" class="logo-grid-item d-flex align-center justify-center pa-6">
            <img :src="utils.getOptimizedUrl(logo.image_url, 400)"
                 class="trust-logo"
                 :class="getThemeClass()"
                 alt="Marca Parceira" />
         </div>
      </div>

      <div v-else-if="block.settings.layout_style === 'stacked' && validLogos.length > 2" class="d-flex flex-column gap-6 gap-md-10">

         <div class="marquee-container logo-marquee">
           <div class="marquee-track track-left" :style="{ animationDuration: `${block.settings.speed || 40}s` }">
             <div v-for="(logo, lIdx) in stackedLogos.row1" :key="`s1a-${lIdx}`" class="logo-wrapper">
                <img :src="utils.getOptimizedUrl(logo.image_url, 400)" class="trust-logo" :class="getThemeClass()" />
             </div>
           </div>
           <div class="marquee-track track-left" aria-hidden="true" :style="{ animationDuration: `${block.settings.speed || 40}s` }">
             <div v-for="(logo, lIdx) in stackedLogos.row1" :key="`s1b-${lIdx}`" class="logo-wrapper">
                <img :src="utils.getOptimizedUrl(logo.image_url, 400)" class="trust-logo" :class="getThemeClass()" />
             </div>
           </div>
         </div>

         <div class="marquee-container logo-marquee">
           <div class="marquee-track track-right" :style="{ animationDuration: `${(block.settings.speed || 40) * 1.1}s` }">
             <div v-for="(logo, lIdx) in stackedLogos.row2" :key="`s2a-${lIdx}`" class="logo-wrapper">
                <img :src="utils.getOptimizedUrl(logo.image_url, 400)" class="trust-logo" :class="getThemeClass()" />
             </div>
           </div>
           <div class="marquee-track track-right" aria-hidden="true" :style="{ animationDuration: `${(block.settings.speed || 40) * 1.1}s` }">
             <div v-for="(logo, lIdx) in stackedLogos.row2" :key="`s2b-${lIdx}`" class="logo-wrapper">
                <img :src="utils.getOptimizedUrl(logo.image_url, 400)" class="trust-logo" :class="getThemeClass()" />
             </div>
           </div>
         </div>

      </div>

      <div v-else class="marquee-container logo-marquee">
        <div class="marquee-track track-left" :style="{ animationDuration: `${block.settings.speed || 40}s` }">
          <div v-for="(logo, lIdx) in validLogos" :key="`ma-${lIdx}`" class="logo-wrapper">
             <img :src="utils.getOptimizedUrl(logo.image_url, 400)" class="trust-logo" :class="getThemeClass()" />
          </div>
        </div>
        <div class="marquee-track track-left" aria-hidden="true" :style="{ animationDuration: `${block.settings.speed || 40}s` }">
          <div v-for="(logo, lIdx) in validLogos" :key="`mb-${lIdx}`" class="logo-wrapper">
             <img :src="utils.getOptimizedUrl(logo.image_url, 400)" class="trust-logo" :class="getThemeClass()" />
          </div>
        </div>
      </div>

    </div>
  </section>
</template>

<script setup lang="ts">
import { computed, inject } from 'vue'

const props = defineProps<{
  mode: 'settings' | 'preview'
  block: any
  isActive?: boolean
}>()

const emit = defineEmits(['upload'])
const utils = inject<any>('builderUtils')

function addLogo() {
  if (!props.block.settings.logos) props.block.settings.logos = []
  props.block.settings.logos.push({ image_url: '' })
}

function removeLogo(index: number) {
  props.block.settings.logos.splice(index, 1)
}

const validLogos = computed(() => {
  return (props.block.settings.logos || []).filter((l: any) => l.image_url)
})

// Divide as logos em duas linhas para o layout Stacked
const stackedLogos = computed(() => {
  const logos = validLogos.value
  const mid = Math.ceil(logos.length / 2)
  return {
    row1: logos.slice(0, mid),
    row2: logos.slice(mid)
  }
})

// Lógica de Temas CSS das Logos
function getThemeClass() {
  const theme = props.block.settings.logo_theme || 'monochrome'
  if (theme === 'high-contrast') return 'theme-high-contrast'
  if (theme === 'original') return 'theme-original'
  return 'theme-monochrome' // Default Premium
}

// Background Dinâmico com suporte a Overlay
const computedStyle = computed(() => {
  const opacity = props.block.settings.overlay_opacity !== undefined ? props.block.settings.overlay_opacity : 0.7
  const baseColor = props.block.settings.bg_color || '#f8fafc'

  if (props.block.settings.bg_url) {
    return {
      backgroundColor: baseColor,
      backgroundImage: `linear-gradient(rgba(0,0,0,${opacity}), rgba(0,0,0,${opacity})), url('${utils.getOptimizedUrl(props.block.settings.bg_url, 1920)}')`,
      backgroundSize: 'cover',
      backgroundPosition: 'center',
      backgroundAttachment: 'fixed' // Leve toque parallax no fundo
    }
  }

  return { backgroundColor: baseColor }
})
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
.modern-range { cursor: pointer; accent-color: rgb(var(--v-theme-primary)); }

.list-anim-enter-active, .list-anim-leave-active { transition: all 0.3s ease; }
.list-anim-enter-from, .list-anim-leave-to { opacity: 0; transform: translateX(-20px); }

/* ==========================================
   ESTILOS DO PREVIEW (CANVAS)
   ========================================== */
.trust-carousel-section { transition: outline 0.2s; outline: 2px solid transparent; outline-offset: -2px; cursor: pointer; }
.trust-carousel-section:hover { outline-color: rgba(var(--v-theme-primary), 0.4); }
.active-outline { outline-color: rgb(var(--v-theme-primary)) !important; box-shadow: inset 0 0 0 4px rgba(var(--v-theme-primary), 0.2); z-index: 2; }

.section-padding { padding-top: 80px; padding-bottom: 80px; }
.kicker-line { color: rgb(var(--v-theme-primary)); }
.title-shadow-light { text-shadow: 0 2px 10px rgba(255,255,255,0.1); }

/* ------------------------------------------
   ESTILO 1: GRID ESTÁTICO PREMIUM
   ------------------------------------------ */
.trust-grid-container {
  display: flex;
  flex-wrap: wrap;
  justify-content: center;
  align-items: center;
  gap: 32px 64px;
}
.logo-grid-item {
  width: 180px;
  height: 80px;
}
@media(max-width: 768px) {
  .trust-grid-container { gap: 16px 32px; }
  .logo-grid-item { width: 120px; height: 60px; }
}

/* ------------------------------------------
   ESTILO 2 & 3: MARQUEES INFINITOS
   ------------------------------------------ */
.marquee-container {
  display: flex;
  width: 100%;
  overflow: hidden;
  /* Máscara de Fade nas bordas (Premium UX) */
  -webkit-mask-image: linear-gradient(to right, transparent, black 10%, black 90%, transparent);
  mask-image: linear-gradient(to right, transparent, black 10%, black 90%, transparent);
}

.marquee-track {
  display: flex;
  align-items: center;
  gap: 100px;
  padding-right: 100px;
  will-change: transform;
}

/* Duas direções para o layout "Stacked" (Esquerda e Direita) */
.track-left { animation: scrollLeft linear infinite; }
.track-right { animation: scrollRight linear infinite; }

.marquee-container:hover .marquee-track {
  animation-play-state: paused;
}

@keyframes scrollLeft {
  0% { transform: translate3d(0, 0, 0); }
  100% { transform: translate3d(-100%, 0, 0); }
}
@keyframes scrollRight {
  0% { transform: translate3d(-100%, 0, 0); }
  100% { transform: translate3d(0, 0, 0); }
}

.logo-wrapper {
  display: flex;
  align-items: center;
  justify-content: center;
  min-width: 160px;
  height: 80px;
}

/* ------------------------------------------
   TEMAS VISUAIS DAS LOGOS
   ------------------------------------------ */
.trust-logo {
  max-width: 100%;
  max-height: 50px;
  object-fit: contain;
  transition: filter 0.4s cubic-bezier(0.4, 0, 0.2, 1), transform 0.4s cubic-bezier(0.4, 0, 0.2, 1), opacity 0.4s;
}

/* Tema 1: Monochrome (Padrão) */
.theme-monochrome { filter: grayscale(100%) opacity(0.4); }
.logo-wrapper:hover .theme-monochrome, .logo-grid-item:hover .theme-monochrome { filter: grayscale(0%) opacity(1); transform: scale(1.05); }

/* Tema 2: Original Colors */
.theme-original { opacity: 0.7; }
.logo-wrapper:hover .theme-original, .logo-grid-item:hover .theme-original { opacity: 1; transform: scale(1.05); }

/* Tema 3: High Contrast (Força branco via brightness - Útil para fundos pretos) */
.theme-high-contrast { filter: brightness(0) invert(1) opacity(0.6); }
.logo-wrapper:hover .theme-high-contrast, .logo-grid-item:hover .theme-high-contrast { opacity: 1; transform: scale(1.05); }
</style>
