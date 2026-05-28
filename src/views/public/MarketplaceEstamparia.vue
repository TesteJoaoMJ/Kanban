<template>
  <div class="estamparia-view fill-height w-100" :class="isDark ? 'theme-dark' : 'theme-light'">

    <div class="hero-background">
      <div class="ambient-glow gradient-1"></div>
      <div class="ambient-glow gradient-2"></div>
      <div class="noise-overlay"></div>
    </div>

    <div class="content-container">

      <section class="hero-section">
        <div class="eyebrow mj-border-radius">Alta Definição Têxtil</div>
        <h1 class="hero-title">Estamparia Digital. <br/><span class="text-primary">O limite é a sua imaginação.</span></h1>
        <p class="hero-subtitle">
          Cores vibrantes, resolução fotográfica e toque zero. Transforme suas ideias em tecidos exclusivos com a mais alta tecnologia de sublimação e impressão digital do mercado.
        </p>

        <div class="hero-actions">
          <button class="action-btn btn-primary mj-border-radius" @click="openWhatsApp">
            <v-icon start size="20" class="mr-2">mdi-whatsapp</v-icon>
            Falar com Representante
          </button>

          <button class="action-btn btn-glass mj-border-radius" @click="goToLogin">
            <v-icon start size="20" class="mr-2">mdi-tshirt-crew-outline</v-icon>
            Login: Estampar meu Tecido
          </button>
        </div>
      </section>

      <section class="features-grid">
        <div class="feature-card glass-panel mj-border-radius">
          <div class="feature-icon-wrap mj-border-radius">
            <v-icon size="32" color="primary">mdi-palette-advanced</v-icon>
          </div>
          <h3 class="feature-title">Cores Infinitas</h3>
          <p class="feature-desc">Nenhum limite de cilindros ou telas. Reproduzimos gradientes complexos e imagens fotográficas com fidelidade absoluta.</p>
        </div>

        <div class="feature-card glass-panel mj-border-radius">
          <div class="feature-icon-wrap mj-border-radius">
            <v-icon size="32" color="primary">mdi-speedometer</v-icon>
          </div>
          <h3 class="feature-title">Agilidade Extrema</h3>
          <p class="feature-desc">Setup zero. Seu design passa do computador direto para o tecido em tempo recorde, ideal para fast-fashion e reposições.</p>
        </div>

        <div class="feature-card glass-panel mj-border-radius">
          <div class="feature-icon-wrap mj-border-radius">
            <v-icon size="32" color="primary">mdi-leaf</v-icon>
          </div>
          <h3 class="feature-title">Ecológico</h3>
          <p class="feature-desc">Processo limpo com tintas à base de água. Redução drástica no consumo de água em comparação à estamparia convencional.</p>
        </div>
      </section>

      <section class="gallery-section">
        <h2 class="section-heading">Qualidade que se pode sentir.</h2>
        <div class="gallery-mosaic">
          <div class="gallery-item large glass-panel mj-border-radius">
            <div class="image-placeholder d-flex align-center justify-center h-100 w-100">
               <v-icon size="48" class="opacity-20">mdi-image-outline</v-icon>
               <span class="position-absolute text-caption font-weight-bold opacity-40">Resolução Fotográfica</span>
            </div>
          </div>
          <div class="gallery-item glass-panel mj-border-radius">
             <div class="image-placeholder d-flex align-center justify-center h-100 w-100">
               <v-icon size="48" class="opacity-20">mdi-texture</v-icon>
            </div>
          </div>
          <div class="gallery-item glass-panel mj-border-radius">
             <div class="image-placeholder d-flex align-center justify-center h-100 w-100">
               <v-icon size="48" class="opacity-20">mdi-palette-swatch-outline</v-icon>
            </div>
          </div>
        </div>
      </section>

    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useRouter } from 'vue-router'
import { useThemeStore } from '@/stores/themeStore'

const router = useRouter()
const themeStore = useThemeStore()
const isDark = computed(() => themeStore.currentMode !== 'light')

// Lógica dos Botões de Ação
function openWhatsApp() {
  const phone = '5511999999999' // Substitua pelo número real da empresa
  const message = 'Olá! Estava navegando no Acervo Digital e gostaria de falar com um representante sobre Estamparia Digital.'
  window.open(`https://wa.me/${phone}?text=${encodeURIComponent(message)}`, '_blank')
}

function goToLogin() {
  router.push('/marketplace-login')
}
</script>

<style scoped>
/* ========================================================
   VARIÁVEIS E BASE
======================================================== */
.estamparia-view {
  position: relative;
  min-height: 100vh;
  padding-top: 90px;
  padding-bottom: 100px;
  overflow-x: hidden;
}

.theme-dark {
  --bg-base: #0a0a0c;
  --text-main: #ffffff;
  --text-muted: rgba(255, 255, 255, 0.65);
  --glass-bg: rgba(255, 255, 255, 0.03);
  --glass-border: rgba(255, 255, 255, 0.08);
  --btn-glass-bg: rgba(255, 255, 255, 0.05);
  --btn-glass-hover: rgba(255, 255, 255, 0.1);
  background-color: var(--bg-base);
}

.theme-light {
  --bg-base: #f8f9fa;
  --text-main: #111111;
  --text-muted: rgba(0, 0, 0, 0.6);
  --glass-bg: rgba(255, 255, 255, 0.7);
  --glass-border: rgba(0, 0, 0, 0.06);
  --btn-glass-bg: rgba(0, 0, 0, 0.04);
  --btn-glass-hover: rgba(0, 0, 0, 0.08);
  background-color: var(--bg-base);
}

/* O ARREDONDAMENTO SUTIL EXIGIDO (2px a 4px) */
.mj-border-radius {
  border-radius: 4px !important;
}

/* ========================================================
   BACKGROUND ANIMADO E NOISE
======================================================== */
.hero-background {
  position: fixed;
  top: 0;
  left: 0;
  width: 100vw;
  height: 100vh;
  z-index: 0;
  pointer-events: none;
  overflow: hidden;
}

.ambient-glow {
  position: absolute;
  border-radius: 50%;
  filter: blur(120px);
  opacity: 0.4;
  animation: float 20s infinite alternate ease-in-out;
}

.gradient-1 {
  width: 60vw;
  height: 60vw;
  background: radial-gradient(circle, rgba(var(--v-theme-primary), 0.3) 0%, transparent 70%);
  top: -20%;
  left: -10%;
}

.gradient-2 {
  width: 50vw;
  height: 50vw;
  background: radial-gradient(circle, rgba(var(--v-theme-info), 0.2) 0%, transparent 70%);
  bottom: -10%;
  right: -10%;
  animation-delay: -10s;
}

.noise-overlay {
  position: absolute;
  inset: 0;
  background-image: url('data:image/svg+xml;utf8,%3Csvg viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg"%3E%3Cfilter id="noiseFilter"%3E%3CfeTurbulence type="fractalNoise" baseFrequency="0.65" numOctaves="3" stitchTiles="stitch"/%3E%3C/filter%3E%3Crect width="100%25" height="100%25" filter="url(%23noiseFilter)" opacity="0.04"/%3E%3C/svg%3E');
  mix-blend-mode: overlay;
}

@keyframes float {
  0% { transform: translate(0, 0) scale(1); }
  100% { transform: translate(5%, 10%) scale(1.1); }
}

/* ========================================================
   LAYOUT CONTAINER
======================================================== */
.content-container {
  position: relative;
  z-index: 10;
  width: 100%;
  max-width: 1280px;
  margin: 0 auto;
  padding: 0 24px;
  display: flex;
  flex-direction: column;
  gap: 120px;
}

/* ========================================================
   HERO SECTION
======================================================== */
.hero-section {
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
  padding-top: 60px;
}

.eyebrow {
  display: inline-flex;
  align-items: center;
  padding: 6px 16px;
  background: rgba(var(--v-theme-primary), 0.15);
  color: rgb(var(--v-theme-primary));
  font-weight: 800;
  font-size: 11px;
  letter-spacing: 0.15em;
  text-transform: uppercase;
  margin-bottom: 24px;
}

.hero-title {
  font-size: clamp(2.5rem, 6vw, 4.5rem);
  font-weight: 900;
  color: var(--text-main);
  line-height: 1.05;
  letter-spacing: -0.03em;
  margin-bottom: 24px;
  max-width: 900px;
}

.hero-subtitle {
  font-size: clamp(1.1rem, 2vw, 1.25rem);
  color: var(--text-muted);
  line-height: 1.6;
  max-width: 700px;
  margin-bottom: 48px;
}

.hero-actions {
  display: flex;
  gap: 16px;
  flex-wrap: wrap;
  justify-content: center;
}

/* ========================================================
   BOTÕES 3D (Estilo exigido)
======================================================== */
.action-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  height: 52px;
  padding: 0 28px;
  font-weight: 800;
  font-size: 14px;
  letter-spacing: 0.05em;
  text-transform: uppercase;
  cursor: pointer;
  transition: all 0.2s cubic-bezier(0.25, 1, 0.5, 1);
}

.btn-primary {
  background: rgb(var(--v-theme-primary));
  color: #ffffff;
  box-shadow: 0 4px 0 rgba(0,0,0,0.2), inset 0 2px 0 rgba(255,255,255,0.2);
  border: none;
}

.btn-primary:active {
  transform: translateY(4px);
  box-shadow: 0 0 0 rgba(0,0,0,0.2), inset 0 1px 0 rgba(255,255,255,0.1);
}

.btn-glass {
  background: var(--btn-glass-bg);
  color: var(--text-main);
  border: 1px solid var(--glass-border);
  backdrop-filter: blur(8px);
  -webkit-backdrop-filter: blur(8px);
  box-shadow: 0 4px 0 rgba(0,0,0,0.05);
}

.btn-glass:hover {
  background: var(--btn-glass-hover);
}

.btn-glass:active {
  transform: translateY(4px);
  box-shadow: 0 0 0 rgba(0,0,0,0);
}

/* ========================================================
   GLASSMORPHISM PANELS & CARDS
======================================================== */
.glass-panel {
  background: var(--glass-bg);
  border: 1px solid var(--glass-border);
  backdrop-filter: blur(24px);
  -webkit-backdrop-filter: blur(24px);
  box-shadow: 0 24px 48px rgba(0, 0, 0, 0.05);
}

.features-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 24px;
}

.feature-card {
  padding: 32px;
  display: flex;
  flex-direction: column;
  transition: transform 0.3s ease;
}

.feature-card:hover {
  transform: translateY(-5px);
}

.feature-icon-wrap {
  width: 56px;
  height: 56px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: rgba(var(--v-theme-primary), 0.1);
  margin-bottom: 24px;
}

.feature-title {
  font-size: 1.25rem;
  font-weight: 800;
  color: var(--text-main);
  margin-bottom: 12px;
  letter-spacing: -0.01em;
}

.feature-desc {
  font-size: 0.95rem;
  color: var(--text-muted);
  line-height: 1.6;
}

/* ========================================================
   GALERIA MOSAICO
======================================================== */
.section-heading {
  font-size: 2.5rem;
  font-weight: 900;
  color: var(--text-main);
  letter-spacing: -0.03em;
  margin-bottom: 40px;
  text-align: center;
}

.gallery-mosaic {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  grid-auto-rows: 250px;
  gap: 20px;
}

.gallery-item {
  position: relative;
  overflow: hidden;
}

.gallery-item.large {
  grid-column: span 2;
  grid-row: span 2;
}

.image-placeholder {
  background: rgba(0,0,0,0.02);
}
.theme-dark .image-placeholder {
  background: rgba(255,255,255,0.02);
}

/* ========================================================
   RESPONSIVIDADE
======================================================== */
@media (max-width: 767px) {
  .content-container { gap: 80px; }
  .hero-actions { flex-direction: column; width: 100%; }
  .action-btn { width: 100%; }
  .gallery-mosaic { grid-template-columns: 1fr; grid-auto-rows: 200px; }
  .gallery-item.large { grid-column: span 1; grid-row: span 1; }
}
</style>
