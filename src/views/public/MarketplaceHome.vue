<template>
  <div class="marketplace-home min-h-screen bg-background d-flex flex-column position-relative" :class="{ 'is-guest': !isAuthenticated }">

    <div v-if="isLoading" class="flex-grow-1 d-flex flex-column align-center justify-center py-16">
      <v-progress-circular indeterminate color="primary" size="64" width="4"></v-progress-circular>
      <p class="text-medium-emphasis mt-6 font-weight-bold text-uppercase tracking-widest text-caption">Carregando a experiência...</p>
    </div>

    <main v-else class="flex-grow-1 w-100 position-relative pb-guest-spacing header-offset" @click.capture="interceptGuestClick">

      <template v-for="(block, index) in homeBlocks" :key="block._id || `home-block-${index}`">
        <component
          v-if="block.type !== 'promotional_popup' && blockComponents[block.type]"
          :is="blockComponents[block.type]"
          mode="preview"
          :block="block"
          :is-active="false"
          :stamps="stamps"
          :categories="categories"
          :mockups="mockups"
        />
      </template>

      <div v-if="homeBlocks.length === 0" class="text-center py-16 px-6">
        <v-icon size="64" class="opacity-20 mb-4">mdi-storefront-outline</v-icon>
        <h2 class="text-h4 font-weight-black tracking-tighter mb-2 responsive-h4">Loja em Construção</h2>
        <p class="text-body-1 opacity-70">Nossa vitrine está sendo preparada. Volte em breve.</p>
      </div>

    </main>

    <!-- Modal Premium Responsivo -->
    <transition name="fade-scale">
      <div v-if="showPremiumModal" class="gatekeeper-overlay d-flex align-center justify-center">
        <div class="gatekeeper-modal bg-surface shadow-2xl overflow-hidden d-flex flex-column flex-md-row position-relative" @click.stop>

          <v-btn icon size="small" variant="flat" color="black" class="position-absolute top-2 right-2 text-white z-50 elevation-2" @click="showPremiumModal = false">
            <v-icon size="18">mdi-close</v-icon>
          </v-btn>

          <div class="modal-left d-none d-md-block w-50 position-relative overflow-hidden">
             <img v-if="stamps.length > 0"
                  :src="getOptimizedUrl(stamps[0].main_image_url, 1200)"
                  class="stamp-bg-image transition-transform" />
             <div v-else class="w-100 h-100 bg-grey-lighten-3"></div>

             <div class="position-absolute inset-0 z-10" style="background: linear-gradient(to right, rgba(0,0,0,0.1) 0%, transparent 100%);"></div>
          </div>

          <div class="modal-right w-100 w-md-50 pa-6 pa-sm-8 pa-md-16 d-flex flex-column justify-center text-center text-md-left text-high-emphasis bg-white">

            <div class="d-flex align-center gap-2 mb-4 mb-md-6 justify-center justify-md-start kicker-line text-primary">
              <v-icon size="16">mdi-lock-outline</v-icon>
              <span class="text-caption font-weight-bold text-uppercase tracking-widest">Acesso Restrito</span>
            </div>

            <h2 class="text-h4 text-md-h3 font-weight-black mb-4 mb-md-6 tracking-tighter line-height-tight text-high-emphasis responsive-modal-title">
              Uma curadoria exclusiva aguarda você.
            </h2>

            <p class="text-body-1 text-md-h6 opacity-70 mb-8 mb-md-10 font-weight-light line-height-relaxed text-high-emphasis responsive-modal-desc" style="letter-spacing: -0.01em;">
              Preços, downloads de arquivos PSD, mockups premium e o estúdio de simulação 3D são visíveis apenas para lojistas e marcas cadastradas.
            </p>

            <div class="d-flex flex-column gap-3 gap-md-4 max-w-400 mx-auto mx-md-0 w-100 mobile-actions">
              <v-btn color="primary" size="large" class="rounded-lg font-weight-black text-none shadow-lg hover-lift mobile-btn" style="letter-spacing: 0.5px;" @click="goToLogin">
                Fazer Login ou Cadastrar
              </v-btn>
              <v-btn variant="outlined" color="primary" size="large" class="rounded-lg font-weight-bold text-none hover-lift mobile-btn" style="border-width: 2px;" prepend-icon="mdi-whatsapp" @click="talkToRepresentative">
                Falar com Representante
              </v-btn>
            </div>
          </div>

        </div>
      </div>
    </transition>

    <!-- Popup Promocional Responsivo -->
    <transition name="fade-scale">
      <div v-if="showPopup && popupBlock" class="public-popup-overlay">
        <div class="public-popup-card shadow-2xl d-flex flex-column flex-sm-row overflow-hidden rounded-xl" :style="{ backgroundColor: popupBlock.settings.bg_color || '#ffffff' }">

          <div v-if="popupBlock.settings.image_url" class="popup-img d-none d-sm-block" :style="{ backgroundImage: `url('${getOptimizedUrl(popupBlock.settings.image_url, 800)}')` }"></div>

          <!-- Imagem no mobile (se existir) -->
          <div v-if="popupBlock.settings.image_url" class="popup-img-mobile d-block d-sm-none" :style="{ backgroundImage: `url('${getOptimizedUrl(popupBlock.settings.image_url, 600)}')` }"></div>

          <div class="pa-6 pa-sm-8 pa-md-12 d-flex flex-column justify-center flex-grow-1 text-center position-relative content-side">
            <v-btn icon size="small" variant="text" class="position-absolute top-2 right-2 popup-close-btn" @click="closePopup">
              <v-icon class="text-medium-emphasis">mdi-close</v-icon>
            </v-btn>
            <h2 class="text-h5 text-sm-h4 text-md-h3 font-weight-black mb-3 mb-md-4 tracking-tighter responsive-popup-title" :style="{ color: popupBlock.settings.text_color || '#000000' }">{{ popupBlock.settings.title }}</h2>
            <p class="text-body-2 text-sm-body-1 mb-6 mb-md-8 opacity-80 line-height-relaxed responsive-popup-desc" :style="{ color: popupBlock.settings.text_color || '#000000' }">{{ popupBlock.settings.text }}</p>
            <v-btn :color="popupBlock.settings.button_color || 'black'" size="large" class="rounded-lg font-weight-bold px-6 px-md-10 text-none elevation-0 shadow-sm hover-lift w-100 mobile-btn" :class="getTextColorClass(popupBlock.settings.button_color, 'black')">{{ popupBlock.settings.button_text }}</v-btn>
            <span class="text-[10px] mt-4 mt-md-6 opacity-50 cursor-pointer hover-underline font-weight-bold text-uppercase tracking-widest" :style="{ color: popupBlock.settings.text_color || '#000000' }" @click="closePopup">Não, obrigado</span>
          </div>
        </div>
      </div>
    </transition>

  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, computed, provide, defineAsyncComponent } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '@/api/supabase'
import { useMarketplaceUserStore } from '@/stores/marketplaceUser'

const router = useRouter()
const userStore = useMarketplaceUserStore()

const isAuthenticated = computed(() => userStore.isAuthenticated)
const showPremiumModal = ref(false)
const isLoading = ref(true)
const homeBlocks = ref<any[]>([])

const categories = ref<any[]>([])
const stamps = ref<any[]>([])
const mockups = ref<any[]>([])

const showPopup = ref(false)
const popupBlock = computed(() => homeBlocks.value.find(b => b.type === 'promotional_popup'))

// REUTILIZAÇÃO DOS BLOCOS DO BUILDER
const blockComponents: Record<string, any> = {
  promotional_popup: defineAsyncComponent(() => import('@/views/admin/storefront/blocks/PromotionalPopupBlock.vue')),
  promo_marquee: defineAsyncComponent(() => import('@/views/admin/storefront/blocks/PromoMarqueeBlock.vue')),
  hero: defineAsyncComponent(() => import('@/views/admin/storefront/blocks/HeroBlock.vue')),
  trust_carousel: defineAsyncComponent(() => import('@/views/admin/storefront/blocks/TrustCarouselBlock.vue')),
  zigzag_collections: defineAsyncComponent(() => import('@/views/admin/storefront/blocks/ZigzagCollectionsBlock.vue')),
  text_with_image: defineAsyncComponent(() => import('@/views/admin/storefront/blocks/TextWithImageBlock.vue')),
  collection: defineAsyncComponent(() => import('@/views/admin/storefront/blocks/CollectionBlock.vue')),
  mockup_grid: defineAsyncComponent(() => import('@/views/admin/storefront/blocks/MockupGridBlock.vue')),
  giant_mockup: defineAsyncComponent(() => import('@/views/admin/storefront/blocks/GiantMockupBlock.vue')),
  mosaic: defineAsyncComponent(() => import('@/views/admin/storefront/blocks/MosaicBlock.vue')),
  testimonials: defineAsyncComponent(() => import('@/views/admin/storefront/blocks/TestimonialsBlock.vue')),
  services: defineAsyncComponent(() => import('@/views/admin/storefront/blocks/ServicesBlock.vue')),
  parallax: defineAsyncComponent(() => import('@/views/admin/storefront/blocks/ParallaxBlock.vue')),
  editorial_text: defineAsyncComponent(() => import('@/views/admin/storefront/blocks/EditorialTextBlock.vue')),
  dual_banner: defineAsyncComponent(() => import('@/views/admin/storefront/blocks/DualBannerBlock.vue'))
}

// ==========================================
// INTERCEPTADOR DE CLIQUES (GATEKEEPER)
// ==========================================
function interceptGuestClick(e: Event) {
  if (isAuthenticated.value) return

  const target = e.target as HTMLElement;

  // Ignorar cliques em botões de navegação do carrossel
  if (target.closest('.carousel-nav-btn, .carousel-nav')) {
      return;
  }

  const isClickable = target.closest(`
    button:not(.carousel-nav-btn),
    a,
    .pb-card,
    .mockup-card,
    .zigzag-row,
    .lookbook-card,
    .index-row,
    .bento-card,
    .mosaic-block,
    .pb-btn-link,
    .pb-action-btn
  `);

  if (isClickable) {
    e.stopPropagation();
    e.preventDefault();
    showPremiumModal.value = true;
  }
}

function goToLogin() {
  showPremiumModal.value = false;
  router.push('/marketplace/login');
}

function talkToRepresentative() {
  window.open('https://wa.me/5511999999999?text=Olá,%20gostaria%20de%20ter%20acesso%20ao%20acervo%20exclusivo%20de%20estampas.', '_blank');
}

// Funções Utilitárias Globais injetadas nos blocos
function getTextColorClass(hexColor: string | undefined, defaultColor: string) {
  const color = hexColor || defaultColor;
  if (color === '#ffffff' || color === 'white' || color.toLowerCase() === '#fff') return 'text-black'
  return 'text-white'
}

function getOptimizedUrl(url: string | null | undefined, targetWidth: number) {
  if (!url) return '/placeholder.png'
  if (url.startsWith('blob:') || url.startsWith('data:')) return url
  if (!url.includes('supabase.co') || !url.includes('/object/public/')) return url
  try {
    const parts = url.split('/object/public/'); const pathBucket = parts[1]
    const slashIdx = pathBucket.indexOf('/'); const bucket = pathBucket.substring(0, slashIdx)
    let filePath = pathBucket.substring(slashIdx + 1)
    if (filePath.includes('?')) filePath = filePath.split('?')[0]
    const { data } = supabase.storage.from(bucket).getPublicUrl(decodeURIComponent(filePath), { transform: { width: targetWidth } })
    return data.publicUrl
  } catch (e) { return url }
}

function getStampObj(id: string) { return stamps.value.find(s => s.id === id) }
function getMockupObj(id: string) { return mockups.value.find(m => m.id === id) }
function getCategoryName(id: string) { return categories.value.find(c => c.id === id)?.name || '' }

// Provê utilitários para TODOS os blocos renderizados na vitrine
provide('builderUtils', { getOptimizedUrl, getTextColorClass, getStampObj, getMockupObj, getCategoryName })

async function fetchStorefrontData() {
  isLoading.value = true
  try {
    const { data: { session } } = await supabase.auth.getSession()
    if (session && !userStore.user) {
      const { data: leadData } = await supabase.from('public_leads').select('*').eq('email', session.user.email).maybeSingle()
      if (leadData) {
        await userStore.setUser({
          id: leadData.id, name: leadData.name || '', email: leadData.email,
          phone: leadData.phone, document: leadData.document, avatarUrl: leadData.avatar_url
        })
      }
    }

    const [settingsRes, catRes, stampRes, mockRes] = await Promise.all([
      supabase.from('storefront_settings').select('home_blocks, maintenance_mode').order('updated_at', { ascending: false }).limit(1).maybeSingle(),
      supabase.from('catalog_categories').select('id, name').order('name'),
      supabase.from('catalog_stamps').select('id, title, ref_code, main_image_url, category_id, digital_price, dominant_color').order('created_at', { ascending: false }),
      supabase.from('catalog_mockups').select('id, name, base_image_url, shadow_overlay_url, mask_url').order('created_at', { ascending: false })
    ])

    if (catRes.data) categories.value = catRes.data
    if (stampRes.data) stamps.value = stampRes.data
    if (mockRes.data) mockups.value = mockRes.data

    if (settingsRes.data && settingsRes.data.home_blocks) {
      const blocks = Array.isArray(settingsRes.data.home_blocks) ? settingsRes.data.home_blocks : []
      homeBlocks.value = blocks.map((b, i) => ({ ...b, _id: b._id || `block-${i}-${b.type}` }))
    }

    // Popup de promoção
    if (popupBlock.value) {
      const hasSeenPopup = sessionStorage.getItem('hasSeenPromoPopup')
      if (!hasSeenPopup) {
        const delayMs = (popupBlock.value.settings.delay || 3) * 1000
        setTimeout(() => { showPopup.value = true }, delayMs)
      }
    }

  } catch (err) {
    console.error('Erro ao carregar a vitrine:', err)
  } finally {
    isLoading.value = false
  }
}

function closePopup() {
  showPopup.value = false
  sessionStorage.setItem('hasSeenPromoPopup', 'true')
}

onMounted(() => fetchStorefrontData())
</script>

<style scoped>
/* FUNDAÇÃO MOBILE-FIRST E PROTEÇÃO CONTRA OVERFLOW */
.marketplace-home {
  width: 100%;
  max-width: 100vw;
  overflow-x: hidden;
  box-sizing: border-box;
}

main {
  width: 100%;
  max-width: 100vw;
  overflow-x: hidden;
  box-sizing: border-box;
}

/* ==========================================
   BLINDAGEM GLOBAL DE GRID PARA OS BLOCOS FILHOS
   ========================================== */
main :deep(.pb-container) {
  box-sizing: border-box;
  max-width: 100vw;
  overflow: hidden;
  padding-left: 16px !important;
  padding-right: 16px !important;
}

/* Fix para garantir que blocos contêiner acompanhem as grids em telas pequenas */
main :deep(.pb-grid),
main :deep(.mockup-display-grid) {
  display: grid;
  width: 100%;
  grid-template-columns: repeat(4, minmax(0, 1fr)) !important;
  gap: 24px;
}

@media (max-width: 1400px) {
  main :deep(.pb-grid), main :deep(.mockup-display-grid) { grid-template-columns: repeat(3, minmax(0, 1fr)) !important; gap: 20px;}
}
@media (max-width: 959px) {
  main :deep(.pb-grid), main :deep(.mockup-display-grid) { grid-template-columns: repeat(2, minmax(0, 1fr)) !important; gap: 16px;}
}
/* No mobile, force para 2 colunas para manter a grid compacta sem espremer ou 1 dependendo do seu estilo */
@media (max-width: 599px) {
  main :deep(.pb-grid) { grid-template-columns: repeat(2, minmax(0, 1fr)) !important; gap: 12px !important; }
  main :deep(.mockup-display-grid) { grid-template-columns: repeat(1, minmax(0, 1fr)) !important; gap: 16px !important; }
}

main :deep(.pb-card),
main :deep(.mockup-card),
main :deep(.pb-card-info),
main :deep(.mockup-info) {
  min-width: 0 !important;
  width: 100%;
}

/* Evita que texto longo quebre a grid para fora */
main :deep(.pb-title) {
  max-width: 100%;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}


/* ==========================================
   A MÁGICA DOS BLURS (HOVER DO VISITANTE)
   ========================================== */
.marketplace-home.is-guest :deep(.pb-card-media::before),
.marketplace-home.is-guest :deep(.mockup-media-wrapper::before),
.marketplace-home.is-guest :deep(.zigzag-media::before),
.marketplace-home.is-guest :deep(.lookbook-media::before),
.marketplace-home.is-guest :deep(.index-reveal-img::before),
.marketplace-home.is-guest :deep(.bento-card::before),
.marketplace-home.is-guest :deep(.mosaic-block::before) {
  content: ''; position: absolute; inset: 0; background: rgba(255, 255, 255, 0.1);
  backdrop-filter: blur(0px); z-index: 50; opacity: 0; transition: all 0.4s cubic-bezier(0.16, 1, 0.3, 1); pointer-events: none;
}

.marketplace-home.is-guest :deep(.pb-card-media::after),
.marketplace-home.is-guest :deep(.mockup-media-wrapper::after),
.marketplace-home.is-guest :deep(.zigzag-media::after),
.marketplace-home.is-guest :deep(.lookbook-media::after),
.marketplace-home.is-guest :deep(.index-reveal-img::after),
.marketplace-home.is-guest :deep(.bento-card::after),
.marketplace-home.is-guest :deep(.mosaic-block::after) {
  content: '\F033E'; font-family: "Material Design Icons"; position: absolute; top: 50%; left: 50%;
  transform: translate(-50%, -30%) scale(0.8); background: rgb(var(--v-theme-primary)); color: white;
  width: 56px; height: 56px; border-radius: 50%; display: flex; align-items: center; justify-content: center;
  font-size: 24px; z-index: 51; opacity: 0; transition: all 0.4s cubic-bezier(0.175, 0.885, 0.32, 1.275);
  pointer-events: none; box-shadow: 0 10px 30px rgba(var(--v-theme-primary), 0.4);
}

.marketplace-home.is-guest :deep(.pb-card:hover .pb-card-media::before),
.marketplace-home.is-guest :deep(.mockup-card:hover .mockup-media-wrapper::before),
.marketplace-home.is-guest :deep(.zigzag-row:hover .zigzag-media::before),
.marketplace-home.is-guest :deep(.lookbook-card:hover .lookbook-media::before),
.marketplace-home.is-guest :deep(.index-row:hover .index-reveal-img::before),
.marketplace-home.is-guest :deep(.bento-card:hover::before),
.marketplace-home.is-guest :deep(.mosaic-block:hover::before) { opacity: 1; backdrop-filter: blur(24px); }

.marketplace-home.is-guest :deep(.pb-card:hover .pb-card-media::after),
.marketplace-home.is-guest :deep(.mockup-card:hover .mockup-media-wrapper::after),
.marketplace-home.is-guest :deep(.zigzag-row:hover .zigzag-media::after),
.marketplace-home.is-guest :deep(.lookbook-card:hover .lookbook-media::after),
.marketplace-home.is-guest :deep(.index-row:hover .index-reveal-img::after),
.marketplace-home.is-guest :deep(.bento-card:hover::after),
.marketplace-home.is-guest :deep(.mosaic-block:hover::after) { opacity: 1; transform: translate(-50%, -50%) scale(1); }

/* ==========================================
   MODAL PREMIUM (GATEKEEPER) - RESPONSIVO
   ========================================== */
.gatekeeper-overlay { position: fixed; inset: 0; z-index: 10000; background: rgba(15, 23, 42, 0.85); backdrop-filter: blur(20px); padding: 16px; display: flex; align-items: center; justify-content: center; }
.gatekeeper-modal { width: 100%; max-width: 1080px; background: #ffffff !important; border-radius: 12px; }
.modal-left { background-color: #f8fafc; }
.stamp-bg-image { width: 100%; height: 100%; object-fit: cover; animation: slowZoom 20s linear infinite; }
@keyframes slowZoom { 0% { transform: scale(1); } 50% { transform: scale(1.15); } 100% { transform: scale(1); } }
.text-high-emphasis { color: #000000 !important; }
.font-weight-light { font-weight: 300 !important; }
.kicker-line { letter-spacing: 0.2em; font-size: 11px; }
.line-height-relaxed { line-height: 1.6; }
.max-w-400 { max-width: 400px; }
.hover-lift { transition: transform 0.3s ease, box-shadow 0.3s ease; }
.hover-lift:hover { transform: translateY(-4px); box-shadow: 0 20px 40px rgba(0,0,0,0.15) !important; }

@media (max-width: 599px) {
  .gatekeeper-modal { flex-direction: column; max-width: 100%; max-height: 95vh; overflow-y: auto; }
  .modal-right { padding: 32px 20px !important; width: 100% !important; }
  .responsive-modal-title { font-size: 1.6rem !important; line-height: 1.2 !important; margin-bottom: 12px !important; }
  .responsive-modal-desc { font-size: 0.95rem !important; line-height: 1.5 !important; margin-bottom: 24px !important; }
  .mobile-actions { width: 100% !important; }
  .mobile-btn { width: 100% !important; font-size: 0.85rem !important; height: 48px !important; }
}

/* ==========================================
   POPUP PROMOCIONAL RESPONSIVO
   ========================================== */
.public-popup-overlay { position: fixed; inset: 0; z-index: 9999; background: rgba(15, 23, 42, 0.7); backdrop-filter: blur(8px); display: flex; align-items: center; justify-content: center; padding: 16px; }
.public-popup-card { width: 100%; max-width: 800px; min-height: 400px; box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.35); }
.public-popup-card :deep(h2), .public-popup-card :deep(p), .public-popup-card :deep(span) { color: #000000 !important; }

/* Imagem lateral Desktop */
.popup-img { width: 45%; background-size: cover; background-position: center; position: relative; }
.popup-img::after { content: ''; position: absolute; inset: 0; background: linear-gradient(to right, rgba(255,255,255,0) 80%, rgba(255,255,255,0.05) 100%); }

/* Imagem Topo Mobile */
.popup-img-mobile { width: 100%; height: 200px; background-size: cover; background-position: center; position: relative; }

.content-side { width: 55%; padding: 40px; }
.hover-underline:hover { text-decoration: underline; opacity: 0.8 !important; }
.popup-close-btn { z-index: 10; }

@media (max-width: 599px) {
  .public-popup-card { flex-direction: column; max-height: 90vh; overflow-y: auto;}
  .content-side { width: 100%; padding: 24px 16px !important; }
  .responsive-popup-title { font-size: 1.4rem !important; line-height: 1.2 !important; margin-bottom: 8px !important; }
  .responsive-popup-desc { font-size: 0.9rem !important; line-height: 1.4 !important; margin-bottom: 16px !important; }
}

@media (max-width: 599px) { .responsive-h4 { font-size: 1.5rem !important; } }
.fade-scale-enter-active, .fade-scale-leave-active { transition: all 0.5s cubic-bezier(0.16, 1, 0.3, 1); }
.fade-scale-enter-from, .fade-scale-leave-to { opacity: 0; transform: scale(0.98) translateY(10px); }

/* ==========================================
   COMPENSAÇÃO DO HEADER PARA NÃO CORTAR O TOPO
   ========================================== */
.header-offset {
  padding-top: 80px;
}
@media (max-width: 959px) {
  .header-offset {
    padding-top: 64px; /* Altura exata do app-bar no mobile */
  }
}

/* ==========================================
   FIX DO COMPONENTE HERO SECTION (Mobile)
   ========================================== */
main :deep(.hero-preview) {
  height: calc(100vh - 80px) !important;
  min-height: 600px !important;
}

@media (max-width: 959px) {
  main :deep(.hero-preview) {
     height: calc(100vh - 64px) !important;
     min-height: 500px !important;
  }
}

/* Garante que os carrosseis não fiquem espremidos */
main :deep(.hero-preview .carousel-track),
main :deep(.hero-preview .slide-layer) {
  height: 100% !important;
  width: 100% !important;
}

/* ==========================================
   TEXT-WITH-IMAGE E DUAL BANNER (Mobile Fixes)
   ========================================== */
@media (max-width: 599px) {
  main :deep(.pb-text-image) {
    flex-direction: column !important; /* Empilha a imagem e o texto */
    text-align: center; /* Centraliza o texto no mobile */
  }
  main :deep(.pb-text-image > div) {
    width: 100% !important; /* Ocupa 100% da largura */
    padding: 16px !important; /* Reduz o padding */
  }
  main :deep(.pb-dual-banner) {
    flex-direction: column !important;
  }
  main :deep(.pb-dual-banner > div) {
    width: 100% !important;
    height: 300px !important; /* Dá uma altura fixa razoável pros banners empilhados */
  }
}

</style>
