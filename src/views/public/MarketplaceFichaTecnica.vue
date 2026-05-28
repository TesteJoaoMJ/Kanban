<template>
  <div class="view-wrap ficha-view">
    <div v-if="isLoading" class="loading-state">
      <div class="pulse-ring">
        <v-progress-circular indeterminate color="primary" size="48" width="3" />
      </div>
      <p class="mt-6 text-uppercase font-weight-bold letter-spacing-1 text-muted text-caption">Sincronizando Acervo Técnico...</p>
    </div>

    <v-container v-else class="container-xl ficha-container">
      <div class="ficha-breadcrumb mb-8">
        <v-btn icon variant="text" size="small" class="back-btn mr-2" @click="router.back()">
          <v-icon size="20" color="primary">mdi-arrow-left</v-icon>
        </v-btn>
        <span class="text-caption font-weight-medium text-muted">
          Marketplace <span class="mx-2">/</span> <strong class="text-primary">Engenharia Têxtil</strong>
        </span>
      </div>

      <div class="hero-section rounded-xl pa-8 pa-md-16 mb-12 position-relative overflow-hidden shadow-lg border">
        <div class="hero-bg-texture"></div>
        <div class="hero-bg-orb orb-1"></div>
        <div class="hero-bg-orb orb-2"></div>

        <div class="position-relative z-10 d-flex flex-column align-center text-center">
          <div class="eyebrow-premium mb-6">
            <v-icon size="14" class="mr-2">mdi-shield-check-outline</v-icon> Bases Homologadas
          </div>
          <h1 class="hero-title font-weight-black mb-4">Acervo Técnico</h1>
          <p class="hero-desc text-muted max-w-2xl text-body-1 mx-auto">
            Acesse as especificações de engenharia, laudos de caimento e regras de precificação estruturada do nosso portfólio.
          </p>

          <div class="search-bar mt-10 w-100" style="max-width: 640px;">
            <div class="premium-search-input rounded-pill px-6 d-flex align-center transition-all shadow-md">
              <v-icon color="primary" size="24" class="mr-3">mdi-magnify</v-icon>
              <input
                v-model="searchQuery"
                type="text"
                placeholder="Pesquisar por nome, toque ou composição..."
                class="flex-grow-1 bg-transparent border-0 outline-none text-body-1 font-weight-bold h-100 search-text"
              />
              <v-fade-transition>
                <v-btn v-if="searchQuery" icon="mdi-close-circle" variant="text" size="small" color="grey" @click="searchQuery = ''"></v-btn>
              </v-fade-transition>
            </div>
          </div>
        </div>
      </div>

      <div v-if="filteredFabrics.length" class="ficha-grid">
        <article v-for="fabric in filteredFabrics" :key="fabric.id" class="ficha-card">
          <div class="card-glow-border"></div>

          <div class="ficha-card-inner d-flex flex-column h-100">
            <div class="ficha-media-wrap position-relative cursor-pointer" @click="openFichaViewer(fabric)">
              <img :src="fabric.image_url || '/placeholder.png'" :alt="fabric.name" class="ficha-media" @error="handleImageError" loading="lazy" />

              <div class="ficha-glass-overlay position-absolute inset-0 d-flex align-center justify-center transition-all">
                 <div class="hover-action-pill d-flex align-center gap-2 px-6 py-3 rounded-pill shadow-lg border border-white-10">
                   <v-icon size="20" color="white">mdi-magnify-plus-outline</v-icon>
                   <span class="text-button font-weight-bold text-white letter-spacing-1">AMPLIAR FICHA</span>
                 </div>
              </div>

              <div class="premium-badge-pos" v-if="fabric.base_price > 40">
                <div class="premium-badge shadow-lg"><v-icon size="10" color="warning" class="mr-1">mdi-star</v-icon> PREMIUM</div>
              </div>
            </div>

            <div class="ficha-body pa-6 d-flex flex-column flex-grow-1 position-relative z-10">
              <span class="text-[10px] text-uppercase font-weight-bold text-primary letter-spacing-1 d-block mb-1">
                REF: {{ fabric.id.split('-')[0].toUpperCase() }}
              </span>
              <h2 class="fabric-name text-h6 font-weight-black lh-1 mb-2">{{ fabric.name }}</h2>

              <p class="text-muted text-body-2 mb-6 line-clamp-2" style="line-height: 1.5; min-height: 42px;">
                {{ fabric.description || 'Consulte o laudo técnico anexo para validar caimento, encolhimento e direcionamento de confecção.' }}
              </p>

              <div class="d-flex align-end justify-space-between mt-auto">
                <div class="price-info bg-surface-2 pa-3 rounded-lg border shadow-sm flex-grow-1 mr-3">
                  <span class="text-[9px] text-muted d-block text-uppercase font-weight-black mb-1">Preço Base</span>
                  <span class="text-subtitle-1 font-weight-black lh-1">R$ {{ formatPrice(fabric.base_price) }}<small class="text-muted ml-1 font-weight-medium">/{{ getUnit(fabric) }}</small></span>
                </div>

                <v-btn color="primary" class="font-weight-bold btn-premium-3d rounded-lg px-6 flex-shrink-0" height="52" @click="router.push('/marketplace/descobrir')">
                   ESTAMPAR
                </v-btn>
              </div>
            </div>
          </div>
        </article>
      </div>

      <div v-else class="empty-state text-center py-16 rounded-3xl mt-8 border shadow-sm position-relative overflow-hidden bg-surface">
        <div class="hero-bg-texture opacity-10"></div>
        <div class="position-relative z-10">
          <v-icon size="48" color="primary" class="mb-4">mdi-text-box-search-outline</v-icon>
          <h3 class="text-h5 font-weight-bold mb-2">Nenhum registro encontrado</h3>
          <p class="text-muted text-body-2 max-w-md mx-auto mb-8">Não encontramos nenhuma ficha técnica compatível com a sua pesquisa.</p>
          <v-btn color="primary" variant="flat" class="font-weight-bold rounded-pill px-8 btn-premium-3d" @click="searchQuery = ''">
            LIMPAR BUSCA
          </v-btn>
        </div>
      </div>
    </v-container>

    <Teleport to="body">
      <Transition name="premium-zoom">
        <div v-if="showViewer" class="full-screen-overlay d-flex flex-column">

          <div class="viewer-header pa-4 pa-md-6 d-flex align-center justify-space-between w-100" @click.stop>

            <div class="d-flex align-center gap-4">
              <v-btn icon="mdi-close" variant="flat" color="error" class="btn-3d btn-close-3d" @click="closeFichaViewer"></v-btn>
              <div class="d-flex flex-column text-white text-shadow">
                <span class="text-h6 font-weight-black leading-tight">{{ selectedFabric?.name }}</span>
                <span class="text-caption font-weight-bold text-uppercase letter-spacing-1 opacity-80">Laudo Técnico</span>
              </div>
            </div>

            <div class="d-flex align-center gap-4">
              <v-tooltip location="bottom" text="Compartilhar no WhatsApp">
                <template v-slot:activator="{ props }">
                  <v-btn v-bind="props" icon="mdi-whatsapp" class="btn-3d btn-wa-3d" @click.stop="shareWA"></v-btn>
                </template>
              </v-tooltip>

              <v-tooltip location="bottom" text="Enviar por E-mail">
                <template v-slot:activator="{ props }">
                  <v-btn v-bind="props" icon="mdi-email-outline" class="btn-3d btn-email-3d" @click.stop="shareEmail"></v-btn>
                </template>
              </v-tooltip>

              <div class="v-divider-vertical mx-2 opacity-30" style="height: 30px; width: 1px; background: white;"></div>

              <v-tooltip location="bottom" text="Fazer Download">
                <template v-slot:activator="{ props }">
                  <v-btn v-bind="props" icon="mdi-download" class="btn-3d btn-download-3d" :href="selectedFabric?.image_url" target="_blank" download @click.stop></v-btn>
                </template>
              </v-tooltip>
            </div>
          </div>

          <div
            class="viewer-body flex-grow-1 position-relative overflow-hidden d-flex align-center justify-center w-100"
            @wheel.prevent="handleZoom"
            @click.self="closeFichaViewer"
          >
            <div class="zoom-hint position-absolute d-flex align-center gap-2 rounded-pill px-4 py-2 text-white font-weight-bold text-caption" :class="{ 'opacity-0': scale > 1 }">
              <v-icon size="16">mdi-mouse-scroll-wheel</v-icon> Use o scroll para dar zoom
            </div>

            <img
              :src="selectedFabric?.image_url"
              class="expanded-image shadow-2xl"
              :class="{ 'is-dragging': isDragging, 'can-drag': scale > 1 }"
              :style="{ transform: `translate(${panX}px, ${panY}px) scale(${scale})` }"
              alt="Ficha Técnica Ampliada"
              draggable="false"
              @mousedown.prevent="startDrag"
              @mousemove.prevent="doDrag"
              @mouseup="stopDrag"
              @mouseleave="stopDrag"
            />
          </div>

        </div>
      </Transition>
    </Teleport>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '@/api/supabase'

const router = useRouter()
const isLoading = ref(true)
const fabrics = ref<any[]>([])
const searchQuery = ref('')
const showViewer = ref(false)
const selectedFabric = ref<any>(null)

// ==========================================
// LÓGICA DE ZOOM E PAN NATIVA
// ==========================================
const scale = ref(1)
const panX = ref(0)
const panY = ref(0)
const isDragging = ref(false)
const startX = ref(0)
const startY = ref(0)

const handleZoom = (e: WheelEvent) => {
  const zoomFactor = 0.15
  let newScale = scale.value + (e.deltaY > 0 ? -zoomFactor : zoomFactor)

  if (newScale <= 1) {
    newScale = 1
    panX.value = 0
    panY.value = 0
  }
  if (newScale > 5) newScale = 5
  scale.value = newScale
}

const startDrag = (e: MouseEvent) => {
  if (scale.value <= 1) return
  isDragging.value = true
  startX.value = e.clientX - panX.value
  startY.value = e.clientY - panY.value
}

const doDrag = (e: MouseEvent) => {
  if (!isDragging.value) return
  panX.value = e.clientX - startX.value
  panY.value = e.clientY - startY.value
}

const stopDrag = () => {
  isDragging.value = false
}

const resetZoom = () => {
  scale.value = 1
  panX.value = 0
  panY.value = 0
}

// ==========================================
// INICIALIZAÇÃO
// ==========================================
onMounted(async () => {
  isLoading.value = true
  try {
    const { data, error } = await supabase
      .from('catalog_fabrics')
      .select('*')
      .eq('is_active', true)
      .order('name', { ascending: true })
    if (error) throw error
    if (data) fabrics.value = data
  } catch (error) {
    console.error('Erro:', error)
  } finally {
    isLoading.value = false
  }
})

const filteredFabrics = computed(() => {
  if (!searchQuery.value) return fabrics.value
  const q = searchQuery.value.toLowerCase()
  return fabrics.value.filter(f =>
    f.name?.toLowerCase().includes(q) || f.composition?.toLowerCase().includes(q)
  )
})

function openFichaViewer(fabric: any) {
  selectedFabric.value = fabric
  resetZoom()
  showViewer.value = true
}

function closeFichaViewer() {
  showViewer.value = false
}

function formatPrice(v: number) {
  return Number(v || 0).toLocaleString('pt-BR', { minimumFractionDigits: 2 })
}

function getUnit(f: any) {
  return f?.unit?.toLowerCase() === 'kg' ? 'kg' : 'm'
}

function handleImageError(event: Event) {
  const img = event.target as HTMLImageElement
  if (!img.src.includes('placeholder.png')) {
    img.src = '/placeholder.png'
  }
}

// ==========================================
// COMPARTILHAMENTO
// ==========================================
const shareWA = () => {
  const text = encodeURIComponent(`Confira a Ficha Técnica da Base ${selectedFabric.value.name} no MJ Process:\n${selectedFabric.value.image_url}`)
  window.open(`https://wa.me/?text=${text}`, '_blank')
}

const shareEmail = () => {
  const subject = encodeURIComponent(`Ficha Técnica: ${selectedFabric.value.name}`)
  const body = encodeURIComponent(`Olá, segue link da ficha técnica: ${selectedFabric.value.image_url}`)
  window.location.href = `mailto:?subject=${subject}&body=${body}`
}
</script>

<style scoped>
/* Respeita o Dark Mode Nativo do Usuário (Variáveis Originais) */
.view-wrap {
  padding-top: 80px;
  min-height: 100vh;
  background: var(--bg-main);
  color: var(--text-main);
}

.ficha-container {
  padding-bottom: 80px;
}

/* UTILITÁRIOS GERAIS */
.lh-1 { line-height: 1.1 !important; }
.letter-spacing-1 { letter-spacing: 0.05em; }
.transition-all { transition: all 0.3s ease; }
.bg-surface-2 { background: var(--bg-surface-2); }
.text-muted { color: var(--text-muted); }
.border { border: 1px solid var(--border-color) !important; }

/* Adicionado para limitar a descrição em 2 linhas */
.line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
  text-overflow: ellipsis;
}

/* LOADING */
.loading-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 60vh;
}
.pulse-ring {
  padding: 24px;
  border-radius: 50%;
  background: rgba(var(--v-theme-primary), 0.05);
  animation: pulse-ring-anim 2s infinite cubic-bezier(0.66, 0, 0, 1);
}
@keyframes pulse-ring-anim {
  0% { box-shadow: 0 0 0 0 rgba(var(--v-theme-primary), 0.15); }
  100% { box-shadow: 0 0 0 30px rgba(var(--v-theme-primary), 0); }
}

/* HERO SECTION */
.hero-section {
  background: var(--bg-surface);
  border-color: rgba(var(--v-border-color), 0.08) !important;
}

.hero-bg-texture {
  position: absolute;
  inset: 0;
  background-image: radial-gradient(var(--border-color) 1px, transparent 1px);
  background-size: 24px 24px;
  opacity: 0.3;
  pointer-events: none;
}

.hero-bg-orb {
  position: absolute;
  border-radius: 50%;
  filter: blur(80px);
  opacity: 0.1;
  pointer-events: none;
  animation: float-orb 10s infinite ease-in-out alternate;
}
.orb-1 { width: 400px; height: 400px; background: rgb(var(--v-theme-primary)); top: -100px; left: -100px; }
.orb-2 { width: 500px; height: 500px; background: #F59E0B; bottom: -150px; right: -150px; animation-delay: -5s; }
@keyframes float-orb { 100% { transform: translate(30px, 40px) scale(1.1); } }

.eyebrow-premium {
  display: inline-flex;
  align-items: center;
  padding: 6px 16px;
  border-radius: 999px;
  background: rgba(var(--v-theme-primary), 0.1);
  color: rgb(var(--v-theme-primary));
  font-weight: 900;
  font-size: 11px;
  letter-spacing: 0.15em;
  text-transform: uppercase;
  border: 1px solid rgba(var(--v-theme-primary), 0.2);
}

.premium-search-input {
  height: 64px;
  background: var(--bg-surface-2);
  border: 1px solid var(--border-color);
}
.search-text { color: var(--text-main); }
.premium-search-input:focus-within {
  border-color: rgba(var(--v-theme-primary), 0.5);
  box-shadow: 0 0 0 4px rgba(var(--v-theme-primary), 0.1), 0 15px 40px rgba(0,0,0,0.12) !important;
  transform: translateY(-2px);
}

/* =========================================================
   GRID PREMIUM CARDS Efeito Apple
========================================================= */
.ficha-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(360px, 1fr));
  gap: 32px;
}

.ficha-card {
  border-radius: 28px;
  background: transparent;
  position: relative;
  z-index: 1;
}

.ficha-card-inner {
  background: var(--bg-surface);
  border-radius: 28px;
  overflow: hidden;
  box-shadow: 0 10px 30px rgba(0,0,0,0.06);
  border: 1px solid var(--border-color);
  transition: transform 0.4s cubic-bezier(0.16, 1, 0.3, 1), box-shadow 0.4s ease;
  position: relative;
  z-index: 2;
}

.card-glow-border {
  position: absolute;
  inset: -2px;
  border-radius: 30px;
  background: linear-gradient(135deg, rgba(var(--v-theme-primary), 0.8), transparent 40%, transparent 60%, rgba(var(--v-theme-primary), 0.8));
  opacity: 0;
  transition: opacity 0.4s ease;
  z-index: 0;
}

.ficha-card:hover .card-glow-border { opacity: 1; }
.ficha-card:hover .ficha-card-inner {
  transform: translateY(-6px);
  box-shadow: 0 24px 48px rgba(0,0,0,0.15);
  border-color: transparent;
}

/* IMAGEM E OVERLAY DO CARD */
.ficha-media-wrap {
  width: 100%;
  height: 380px;
  background: var(--bg-surface-2);
  border-bottom: 1px solid var(--border-color);
  overflow: hidden;
}

.ficha-media {
  width: 100%;
  height: 100%;
  object-fit: cover;
  object-position: top center;
  transition: transform 0.6s cubic-bezier(0.25, 1, 0.5, 1);
}

.ficha-glass-overlay {
  background: rgba(0, 0, 0, 0.4);
  opacity: 0;
  backdrop-filter: blur(6px);
  -webkit-backdrop-filter: blur(6px);
}
.hover-action-pill { transform: translateY(20px); transition: transform 0.4s cubic-bezier(0.175, 0.885, 0.32, 1.275); background: rgba(0,0,0,0.6); }

.ficha-card:hover .ficha-media { transform: scale(1.04); }
.ficha-card:hover .ficha-glass-overlay { opacity: 1; }
.ficha-card:hover .hover-action-pill { transform: translateY(0); }

/* BADGE */
.premium-badge-pos { position: absolute; top: 16px; right: 16px; z-index: 5; }
.premium-badge {
  background: rgba(30, 41, 59, 0.9);
  backdrop-filter: blur(8px);
  color: #fff;
  padding: 6px 12px;
  border-radius: 999px;
  font-size: 10px;
  font-weight: 900;
  letter-spacing: 0.1em;
  text-transform: uppercase;
  border: 1px solid rgba(255,255,255,0.1);
  display: flex; align-items: center;
}


/* =========================================================
   OVERLAY PREMIUM (TELA CHEIA NATIVA COM ZOOM)
========================================================= */
.full-screen-overlay {
  position: fixed;
  inset: 0;
  z-index: 999999;
  background: rgba(10, 10, 12, 0.85); /* Vidro fosco super dark */
  backdrop-filter: blur(24px);
  -webkit-backdrop-filter: blur(24px);
  user-select: none;
}

.viewer-header {
  position: absolute;
  top: 0; left: 0; right: 0;
  z-index: 100;
  background: linear-gradient(to bottom, rgba(0,0,0,0.8) 0%, transparent 100%);
  padding-bottom: 40px !important;
}
.text-shadow { text-shadow: 0 2px 10px rgba(0,0,0,0.8); }

/* CONTROLES DE ZOOM */
.viewer-body {
  cursor: default;
}
.can-drag { cursor: grab !important; }
.is-dragging { cursor: grabbing !important; transition: none !important; }

.expanded-image {
  max-width: 90%;
  max-height: 90vh;
  object-fit: contain;
  border-radius: 16px;
  transition: transform 0.15s ease-out;
  will-change: transform;
}

.zoom-hint {
  bottom: 40px;
  background: rgba(0,0,0,0.6);
  border: 1px solid rgba(255,255,255,0.1);
  backdrop-filter: blur(8px);
  transition: opacity 0.3s;
  pointer-events: none;
  z-index: 50;
}

/* =========================================================
   BOTÕES 3D PREMIUM GERAIS E COMPARTILHAMENTO
========================================================= */
.gap-4 { gap: 16px; } /* Garante que os botões não colem */

.btn-premium-3d {
  background: linear-gradient(180deg, rgba(var(--v-theme-primary), 1) 0%, rgba(var(--v-theme-primary-darken-1), 1) 100%) !important;
  box-shadow: 0 4px 14px rgba(var(--v-theme-primary), 0.4), inset 0 2px 0 rgba(255,255,255,0.2) !important;
  border: none !important;
  color: white !important;
  transition: transform 0.1s, box-shadow 0.1s !important;
}
.btn-premium-3d:active {
  transform: translateY(2px) !important;
  box-shadow: 0 1px 2px rgba(var(--v-theme-primary), 0.3), inset 0 1px 0 rgba(255,255,255,0.1) !important;
}

/* Estilo Base para botões redondos no Header */
.btn-3d {
  width: 48px !important;
  height: 48px !important;
  border-radius: 50% !important;
  color: white !important;
  border: none !important;
  transition: transform 0.15s, box-shadow 0.15s !important;
}
.btn-3d:hover { transform: translateY(-3px); filter: brightness(1.1); }
.btn-3d:active { transform: translateY(2px); filter: brightness(0.9); }

.btn-close-3d {
  background: linear-gradient(180deg, #EF4444 0%, #B91C1C 100%) !important;
  box-shadow: 0 4px 14px rgba(239, 68, 68, 0.4), inset 0 2px 0 rgba(255,255,255,0.3) !important;
}

.btn-wa-3d {
  background: linear-gradient(180deg, #25D366 0%, #128C7E 100%) !important;
  box-shadow: 0 4px 14px rgba(37, 211, 102, 0.4), inset 0 2px 0 rgba(255,255,255,0.3) !important;
}

.btn-email-3d {
  background: linear-gradient(180deg, #3B82F6 0%, #2563EB 100%) !important;
  box-shadow: 0 4px 14px rgba(59, 130, 246, 0.4), inset 0 2px 0 rgba(255,255,255,0.3) !important;
}

.btn-download-3d {
  background: linear-gradient(180deg, #4B5563 0%, #374151 100%) !important;
  box-shadow: 0 4px 14px rgba(75, 85, 99, 0.5), inset 0 2px 0 rgba(255,255,255,0.2) !important;
}

/* ANIMAÇÃO FULLSCREEN MODAL */
.premium-zoom-enter-active,
.premium-zoom-leave-active {
  transition: all 0.4s cubic-bezier(0.16, 1, 0.3, 1);
}
.premium-zoom-enter-from,
.premium-zoom-leave-to {
  opacity: 0;
  transform: scale(0.97);
}

@media (max-width: 767px) {
  .ficha-grid { grid-template-columns: 1fr; gap: 24px; }
  .hero-section { padding: 32px 20px !important; }
  .hero-title { font-size: 2rem !important; }
  .btn-3d { width: 40px !important; height: 40px !important; }
}
</style>
