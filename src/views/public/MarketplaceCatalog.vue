<template>
  <div class="view-wrap">

    <section class="pb-hero">
      <img
        :src="getOptimizedUrl(settings?.hero_bg_url, 1920)"
        @error="handleImageError"
        alt="Hero Collection"
        class="pb-hero-media"
      />
      <div class="pb-hero-overlay"></div>
      <div class="pb-hero-content">
        <div class="pb-kicker text-primary">{{ settings?.hero_subtitle || 'Studio Collection' }}</div>
        <h1 class="pb-hero-title text-white">{{ settings?.hero_title || 'Design Exclusivo para Marcas Exigentes.' }}</h1>
        <p class="pb-hero-text text-white">Descubra estampas premium, visualize mockups realistas e escale sua produção.</p>
        <div class="pb-hero-actions">
          <button class="pb-btn pb-btn-primary mj-border-radius" @click="goToDiscoverWithFilter(null)">Explorar Catálogo</button>
        </div>
      </div>
    </section>

    <section class="pb-sections">
      <div class="pb-container">

        <template v-for="(grid, index) in validGrids" :key="'grid-'+index">

          <div class="pb-showcase">
            <div class="pb-section-header">
              <h2 class="pb-section-title text-main">{{ grid.title }}</h2>
              <button class="pb-btn-link text-main" @click="goToDiscoverWithFilter(grid.source_id)">
                Ver coleção <v-icon size="16" class="ml-1 pb-icon-arrow">mdi-arrow-right</v-icon>
              </button>
            </div>

            <div class="pb-grid">
              <article
                v-for="stamp in getStampsForGrid(grid)"
                :key="stamp.id"
                class="pb-card"
                :class="{ 'is-wishlisted': isInWishlist(stamp.id) }"
                @click="goToProduct(stamp)"
              >
                <div class="pb-card-media mj-surface mj-border">
                  <img
                    class="pb-card-img"
                    :src="getOptimizedUrl(stamp.main_image_url, 800)"
                    @error="handleImageError"
                    loading="lazy"
                    :alt="stamp.title"
                  />

                  <div class="pb-card-actions-overlay d-none d-md-flex">
                    <div class="pb-actions-bar border">
                      <button
                        class="pb-action-btn pb-wishlist-btn text-muted"
                        :class="{ 'is-active text-error': isInWishlist(stamp.id) }"
                        @click.stop="handleWishlistClick(stamp, $event)"
                        title="Adicionar à Wishlist"
                      >
                        <v-icon size="18" :color="isInWishlist(stamp.id) ? 'error' : ''">
                          {{ isInWishlist(stamp.id) ? 'mdi-heart' : 'mdi-heart-outline' }}
                        </v-icon>

                        <div class="floating-hearts-container">
                          <v-icon
                            v-for="heart in activeHearts[stamp.id]"
                            :key="heart.id"
                            class="particle-heart text-error"
                            :style="{ '--x1': heart.x1, '--x2': heart.x2, '--x3': heart.x3, '--x4': heart.x4, '--scale': heart.scale, '--duration': heart.duration, '--delay': heart.delay }"
                            size="14"
                          >mdi-heart</v-icon>
                        </div>
                      </button>

                      <div class="pb-actions-divider"></div>
                      <button class="pb-action-btn pb-quickview-text flex-grow-1 text-main">Visualizar</button>

                      <template v-if="settings?.allow_psd_sales !== false">
                        <div class="pb-actions-divider"></div>
                        <button
                          class="pb-action-btn pb-cart-btn text-muted"
                          :class="{ 'is-active text-primary': isInCart(stamp.id) }"
                          @click.stop="handleCartClick(stamp)"
                          title="Adicionar PSD ao Carrinho"
                        >
                          <v-icon size="18">{{ isInCart(stamp.id) ? 'mdi-shopping' : 'mdi-shopping-outline' }}</v-icon>
                          <span class="pb-cart-fill bg-primary" :class="{'is-filling': animatingCart === stamp.id}"></span>
                        </button>
                      </template>
                    </div>
                  </div>

                  <div class="pb-mobile-actions d-md-none">
                     <button
                        class="pb-mobile-opt-btn mj-surface mj-border text-muted"
                        :class="{ 'text-error border-error': isInWishlist(stamp.id) }"
                        @click.stop="handleWishlistClick(stamp, $event)"
                     >
                       <v-icon size="16" :color="isInWishlist(stamp.id) ? 'error' : ''">
                         {{ isInWishlist(stamp.id) ? 'mdi-heart' : 'mdi-heart-outline' }}
                       </v-icon>
                     </button>
                  </div>
                </div>

                <div class="pb-card-info">
                  <div class="pb-card-meta">
                    <span class="pb-ref text-muted">{{ stamp.ref_code || 'S/REF' }}</span>
                    <span v-if="settings?.allow_psd_sales !== false && stamp.digital_price" class="pb-price text-main">R$ {{ formatPrice(stamp.digital_price) }}</span>
                  </div>
                  <h3 class="pb-title text-main" :title="stamp.title">{{ stamp.title }}</h3>
                  <span class="pb-category text-muted">{{ getCategoryName(stamp.category_id) || 'Exclusivo' }}</span>
                </div>
              </article>
            </div>
          </div>

          <div v-if="index === 0 && randomMockupPairs.length > 0" class="pb-mockup-showcase my-md-16 my-8">
            <div class="text-center mb-8 mb-md-10">
              <div class="pb-kicker text-primary mb-2">Inspiração</div>
              <h2 class="text-h4 font-weight-black text-main responsive-h4">Aplicações Reais</h2>
              <p class="text-muted responsive-p">Estampas do nosso acervo aplicadas em produtos finais.</p>
            </div>

            <div class="mockup-display-grid">
              <div v-for="(pair, mIdx) in randomMockupPairs" :key="'mockup-'+mIdx" class="mockup-card mj-surface mj-border" @click="goToProduct(pair.stamp)">

                <div class="mockup-media-wrapper bg-background">
                  <div v-if="pair.mockup.mask_url" class="mockup-mask" :style="getMaskStyle(pair)">
                    <div class="pattern-fill" :style="getPatternStyle(pair)"></div>
                  </div>
                  <div v-else class="pattern-fill full" :style="getPatternStyle(pair)"></div>

                  <img v-if="pair.mockup.base_image_url" :src="pair.mockup.base_image_url" class="mockup-base" />

                  <img v-if="pair.mockup.shadow_overlay_url" :src="pair.mockup.shadow_overlay_url" class="mockup-shadow" />
                </div>

                <div class="mockup-info border-t">
                  <div class="overflow-hidden pr-2">
                    <div class="text-caption text-muted text-truncate">{{ pair.mockup.name }}</div>
                    <div class="text-body-2 font-weight-bold text-main text-truncate">{{ pair.stamp.title }}</div>
                  </div>
                  <v-btn icon="mdi-arrow-top-right" size="small" variant="tonal" color="primary"></v-btn>
                </div>

              </div>
            </div>
          </div>

          <div v-if="index === 1 && currentDynamicStamp" class="pb-dynamic-parallax my-md-16 my-8 mj-border rounded-xl overflow-hidden">
            <div class="parallax-bg-wrapper">
              <transition name="slow-fade" mode="in-out">
                <div :key="currentDynamicStamp.id"
                     class="parallax-pattern"
                     :style="{ backgroundImage: `url('${currentDynamicStamp.main_image_url}')` }">
                </div>
              </transition>
            </div>
            <div class="parallax-overlay-dark"></div>
            <div class="parallax-dynamic-content">
               <div class="pb-kicker text-white mb-2">Acervo em Destaque</div>
               <transition name="slide-fade" mode="out-in">
                 <h2 :key="currentDynamicStamp.id" class="text-h3 font-weight-black text-white mb-6 responsive-h3 line-clamp-3">{{ currentDynamicStamp.title }}</h2>
               </transition>
               <button class="pb-btn pb-btn-primary mj-border-radius" style="background: #fff; color: #000;" @click="goToProduct(currentDynamicStamp)">Ver Estampa</button>
            </div>
          </div>

          <div v-if="index === 2 && featuredCategories.length >= 3" class="pb-editorial-mosaic my-md-16 my-8">
            <div class="text-center mb-8 mb-md-10">
              <div class="pb-kicker text-primary mb-2">Curadoria</div>
              <h2 class="text-h4 font-weight-black text-main responsive-h4">Coleções Exclusivas</h2>
            </div>
            <div class="mosaic-grid">
              <div class="mosaic-main mj-surface mj-border" @click="goToDiscoverWithFilter(featuredCategories[0].id)">
                <img :src="getCategoryCover(featuredCategories[0].id)" class="mosaic-bg" @error="handleImageError" />
                <div class="mosaic-overlay">
                  <h3 class="text-h3 font-weight-black text-white mb-2 responsive-h3">{{ featuredCategories[0].name }}</h3>
                  <span class="pb-btn-link text-white">Explorar Coleção <v-icon size="16" class="ml-1">mdi-arrow-right</v-icon></span>
                </div>
              </div>
              <div class="mosaic-side">
                <div class="mosaic-item mj-surface mj-border" @click="goToDiscoverWithFilter(featuredCategories[1].id)">
                  <img :src="getCategoryCover(featuredCategories[1].id)" class="mosaic-bg" @error="handleImageError" />
                  <div class="mosaic-overlay">
                    <h4 class="text-h5 font-weight-bold text-white responsive-h5">{{ featuredCategories[1].name }}</h4>
                  </div>
                </div>
                <div class="mosaic-item mj-surface mj-border" @click="goToDiscoverWithFilter(featuredCategories[2].id)">
                  <img :src="getCategoryCover(featuredCategories[2].id)" class="mosaic-bg" @error="handleImageError" />
                  <div class="mosaic-overlay">
                    <h4 class="text-h5 font-weight-bold text-white responsive-h5">{{ featuredCategories[2].name }}</h4>
                  </div>
                </div>
              </div>
            </div>
          </div>

        </template>

      </div>
    </section>

    <section v-if="settings?.parallax_title || settings?.parallax_bg_url" class="pb-banner">
      <img
        v-if="settings?.parallax_bg_url"
        :src="getOptimizedUrl(settings?.parallax_bg_url, 1920)"
        @error="handleImageError"
        alt="Banner Parallax"
        class="pb-banner-media"
      />
      <div class="pb-banner-overlay"></div>
      <div class="pb-banner-content">
        <h2 class="pb-banner-title text-white responsive-h2">{{ settings?.parallax_title }}</h2>
        <p class="pb-banner-text text-white responsive-p">{{ settings?.parallax_text }}</p>
        <button class="pb-btn pb-btn-outline mj-border-radius mt-6" @click="goToDiscoverWithFilter(null)">Descubra Mais</button>
      </div>
    </section>

    <v-dialog
      v-model="showWelcomePopup"
      :max-width="settings?.welcome_popup_style === 'side-by-side' ? 1000 : 550"
      persistent
      transition="dialog-bottom-transition"
    >
      <v-card class="rounded-xl overflow-hidden border" elevation="24">
        <div class="d-flex flex-column flex-md-row w-100" :style="{ minHeight: settings?.welcome_popup_style === 'side-by-side' ? '550px' : 'auto' }">

          <div v-if="settings?.welcome_popup_style === 'side-by-side'"
               class="d-none d-md-block position-relative"
               style="flex: 1 1 50%; background: rgba(128,128,128,0.1);">
            <img
              :src="getOptimizedUrl(settings?.welcome_popup_image, 800) || '/placeholder.png'"
              style="position: absolute; inset: 0; width: 100%; height: 100%; object-fit: cover;"
            />
          </div>

          <div v-if="settings?.welcome_popup_style === 'side-by-side'"
               class="d-md-none w-100 position-relative flex-shrink-0"
               style="height: 280px; background: rgba(128,128,128,0.1);">
            <img
              :src="getOptimizedUrl(settings?.welcome_popup_image, 600) || '/placeholder.png'"
              style="position: absolute; inset: 0; width: 100%; height: 100%; object-fit: cover;"
            />
          </div>

          <div class="d-flex flex-column justify-center align-center text-center pa-8 pa-md-12"
               :style="{ flex: settings?.welcome_popup_style === 'side-by-side' ? '1 1 50%' : '1 1 100%' }">

            <div style="width: 72px; height: 72px; border-radius: 20px; background: rgba(var(--v-theme-primary), 0.1); display: grid; place-items: center;" class="mb-6 mt-2">
              <v-icon color="primary" size="36">mdi-shield-check-outline</v-icon>
            </div>

            <h2 class="text-h4 font-weight-black mb-4 text-high-emphasis">Seja Bem-vindo à MJ!</h2>

            <p class="text-body-1 mb-8 text-medium-emphasis" style="line-height: 1.7; max-width: 360px; font-size: 1.1rem !important;">
              Por medida de segurança este acesso terá a duração de
              <strong class="text-primary font-weight-black px-2 py-1 mx-1 rounded" style="background: rgba(var(--v-theme-primary), 0.12);">{{ welcomeTimeText }}</strong>.
              Caso precise acessar novamente, solicite um novo código.
            </p>

            <v-btn
              color="primary"
              size="x-large"
              class="rounded-pill font-weight-bold px-8 w-100 mb-2"
              style="max-width: 320px; letter-spacing: 0.02em;"
              @click="showWelcomePopup = false"
            >
              Entendi, Explorar
            </v-btn>
          </div>

        </div>
      </v-card>
    </v-dialog>

  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted, computed } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '@/api/supabase'
import { useMarketplaceCartStore } from '@/stores/marketplaceCart'
import { useMarketplaceUserStore } from '@/stores/marketplaceUser'

const router = useRouter()
const cartStore = useMarketplaceCartStore()
const userStore = useMarketplaceUserStore()
const props = defineProps<{ settings: any }>()

const allStamps = ref<any[]>([])
const allCategories = ref<any[]>([])
const mockups = ref<any[]>([])

// Estados do Popup
const showWelcomePopup = ref(false)
const welcomeTimeText = ref('')

// === LÓGICA DE MOCKUP ===
function getPatternStyle(pair: any) {
  if (!pair.stamp?.main_image_url) return {}
  const bgColor = pair.stamp.dominant_color || '#ffffff'
  return {
    backgroundColor: bgColor,
    backgroundImage: `url('${pair.stamp.main_image_url}')`,
    backgroundSize: '30%',
    backgroundRepeat: 'repeat',
    backgroundPosition: 'center',
  }
}

function getMaskStyle(pair: any) {
  if (!pair.mockup?.mask_url) return {}
  return {
    WebkitMaskImage: `url('${pair.mockup.mask_url}')`,
    maskImage: `url('${pair.mockup.mask_url}')`,
    WebkitMaskSize: 'contain',
    maskSize: 'contain',
    WebkitMaskPosition: 'center',
    maskPosition: 'center',
    WebkitMaskRepeat: 'no-repeat',
    maskRepeat: 'no-repeat',
  }
}

// === LÓGICA DO CARRINHO ===
const animatingCart = ref<string | null>(null)

function isInCart(stampId: string) {
  if (!cartStore || !cartStore.items) return false
  return cartStore.items.some((i: any) => i.stampId === stampId && i.type === 'psd')
}

function handleCartClick(stamp: any) {
  if (props.settings?.allow_psd_sales === false) return

  const exists = isInCart(stamp.id)

  if (exists) {
    const cartItem = cartStore.items.find(i => i.stampId === stamp.id && i.type === 'psd')
    if (cartItem) cartStore.removeItem(cartItem.id)
  } else {
    const price = stamp.digital_price || 59.90
    cartStore.addPsdToCart(stamp, price)

    animatingCart.value = stamp.id
    setTimeout(() => { animatingCart.value = null }, 600)
  }
}

// === LÓGICA DE WISHLIST ===
const activeHearts = ref<Record<string, any[]>>({})
let heartIdCounter = 0

// Reativo, pega direto da store
const isInWishlist = (id: string) => userStore.wishlist.includes(id)

async function handleWishlistClick(stamp: any, event: Event) {
  if (!userStore.isAuthenticated) {
    alert('Por favor, faça login para salvar estampas nos seus favoritos!')
    return
  }

  const isAdding = !isInWishlist(stamp.id)

  // Dispara a animação se estiver adicionando
  if (isAdding) {
    if (!activeHearts.value[stamp.id]) activeHearts.value[stamp.id] = []

    const newHearts = Array.from({ length: 6 }).map(() => ({
      id: heartIdCounter++,
      x1: (Math.random() - 0.5) * 30 + 'px',
      x2: (Math.random() - 0.5) * 60 + 'px',
      x3: (Math.random() - 0.5) * 40 + 'px',
      x4: (Math.random() - 0.5) * 80 + 'px',
      scale: 0.6 + Math.random() * 0.8,
      duration: 1.0 + Math.random() * 0.8 + 's',
      delay: Math.random() * 0.3 + 's'
    }))

    activeHearts.value[stamp.id].push(...newHearts)
    setTimeout(() => {
      if (activeHearts.value[stamp.id]) {
        activeHearts.value[stamp.id] = activeHearts.value[stamp.id].filter(
          h => !newHearts.some(nh => nh.id === h.id)
        )
      }
    }, 2500)
  }

  // Atualiza Store e Banco de dados
  await userStore.toggleWishlist(stamp.id)
}

// === LÓGICA MOCKUPS E INTERAÇÕES ===
const randomMockupPairs = ref<any[]>([])
const currentDynamicStamp = ref<any>(null)
let parallaxTimer: any = null

const featuredCategories = computed(() => {
  const catsWithImages = allCategories.value.filter(c => {
    if (!c.name || c.name.length === 0) return false;
    // Garante que a categoria tem pelo menos UMA estampa com imagem válida
    return allStamps.value.some(s => s.category_id === c.id && s.main_image_url);
  });
  return catsWithImages.slice().reverse().slice(0, 3);
})

function getCategoryCover(categoryId: string) {
  // Procura a primeira estampa da categoria que OBRIGATORIAMENTE tenha imagem
  const stamp = allStamps.value.find(s => s.category_id === categoryId && s.main_image_url)
  return stamp ? getOptimizedUrl(stamp.main_image_url, 800) : '/placeholder.png'
}

function generateInteractions() {
  // 1. Cria um banco de dados temporário só com estampas que possuem imagem
  const stampsWithImages = allStamps.value.filter(s => s.main_image_url && s.main_image_url.trim() !== '');

  // 2. Aplica nos Mockups (Inspiração)
  if (mockups.value.length > 0 && stampsWithImages.length > 0) {
    const pairs = []
    for(let i = 0; i < 4; i++) {
       const m = mockups.value[Math.floor(Math.random() * mockups.value.length)]
       // Sorteia apenas das estampas com imagem
       const s = stampsWithImages[Math.floor(Math.random() * stampsWithImages.length)]
       pairs.push({ mockup: m, stamp: s })
    }
    randomMockupPairs.value = pairs
  }

  // 3. Aplica no Parallax Dinâmico (Acervo em Destaque)
  if (stampsWithImages.length > 0) {
    // Pega a primeira estampa válida para o banner
    currentDynamicStamp.value = stampsWithImages[Math.floor(Math.random() * stampsWithImages.length)]

    parallaxTimer = setInterval(() => {
      currentDynamicStamp.value = stampsWithImages[Math.floor(Math.random() * stampsWithImages.length)]
    }, 4000)
  }
}

onUnmounted(() => {
  if (parallaxTimer) clearInterval(parallaxTimer)
})

// === LOAD DE DADOS PADRÃO E HIDRATAÇÃO DA SESSÃO ===
onMounted(async () => {
  // HIDRATAÇÃO DA SESSÃO (Garante que a Store sabe quem é o usuário logo no carregamento)
  try {
    const { data: { session } } = await supabase.auth.getSession()
    if (session) {
      const { data: leadData } = await supabase.from('public_leads').select('*').eq('email', session.user.email).maybeSingle()
      if (leadData) {
        if (!userStore.user) {
          await userStore.setUser({
            id: leadData.id,
            name: leadData.name || '',
            email: leadData.email,
            phone: leadData.phone,
            document: leadData.document,
            avatarUrl: leadData.avatar_url
          })
        }

        // LÓGICA DO POPUP DE BOAS-VINDAS
        const activeCode = localStorage.getItem('mj_active_code')
        // Só exibe se a funcionalidade estiver ativada nas configurações globais
        if (props.settings?.welcome_popup_enabled && activeCode && leadData.temp_auth_expires_at) {
          const popupKey = `mj_welcome_shown_${activeCode}`
          if (!localStorage.getItem(popupKey)) {

            // Calcula o tempo restante amigável
            const expires = new Date(leadData.temp_auth_expires_at)
            const diffMins = Math.round((expires.getTime() - new Date().getTime()) / 60000)

            if (diffMins > 60) {
              const hrs = Math.floor(diffMins / 60)
              welcomeTimeText.value = `${hrs} hora${hrs > 1 ? 's' : ''}`
            } else {
              welcomeTimeText.value = `${diffMins} minutos`
            }

            showWelcomePopup.value = true
            localStorage.setItem(popupKey, 'true')
          }
        }
      }
    }
  } catch (e) {
    console.error('Erro na hidratação da sessão', e)
  }

  // Carregamento normal da página
  try {
    const { data: catData } = await supabase.from('catalog_categories').select('*').order('name')
    allCategories.value = catData || []

    const { data: stampData } = await supabase.from('catalog_stamps').select('*, catalog_categories(name)').eq('is_active', true).order('created_at', { ascending: false }).limit(500)
    allStamps.value = stampData || []

    const { data: mockData } = await supabase.from('catalog_mockups').select('*').eq('is_active', true)
    mockups.value = mockData || []

    generateInteractions()
  } catch (error) { console.error('Erro ao carregar loja', error) }
})

const validGrids = computed(() => {
  if (!props.settings?.grids_config) return []
  return props.settings.grids_config.filter((grid: any) => {
    if (!allStamps.value.length) return true
    return allStamps.value.some(s => s.category_id === grid.source_id)
  })
})

function getOptimizedUrl(originalUrl: string | null | undefined, targetWidth: number) {
  if (!originalUrl) return ''
  if (!originalUrl.includes('supabase.co') || !originalUrl.includes('/object/public/')) return originalUrl
  try {
    const parts = originalUrl.split('/object/public/')
    const pathBucket = parts[1]
    const slashIdx = pathBucket.indexOf('/')
    const bucket = pathBucket.substring(0, slashIdx)
    let filePath = pathBucket.substring(slashIdx + 1)
    if (filePath.includes('?')) filePath = filePath.split('?')[0]
    filePath = decodeURIComponent(filePath)
    const { data } = supabase.storage.from(bucket).getPublicUrl(filePath, { transform: { width: targetWidth } })
    return data.publicUrl
  } catch (err) { return originalUrl }
}

function handleImageError(event: Event) {
  const img = event.target as HTMLImageElement
  if (!img.src.includes('placeholder.png')) img.src = '/placeholder.png'
}

function getStampsForGrid(gridConfig: any) {
  if (!allStamps.value.length) return []
  let list = [...allStamps.value]
  if (gridConfig.type === 'category' && gridConfig.source_id) {
    list = list.filter((s) => s.category_id === gridConfig.source_id)
  }
  return list.slice(0, gridConfig.limit || 8)
}

function getCategoryName(id: string | null) {
  const cat = allCategories.value.find(c => c.id === id)
  return cat ? cat.name : ''
}

function formatPrice(val: number) {
  return Number(val || 0).toLocaleString('pt-BR', { minimumFractionDigits: 2, maximumFractionDigits: 2 })
}

function goToDiscoverWithFilter(categoryId: string | null) {
  if (categoryId) router.push({ path: '/marketplace/descobrir', query: { filter: categoryId } })
  else router.push('/marketplace/descobrir')
}

function goToProduct(stamp: any) { router.push(`/marketplace/produto/${stamp.id}`) }
</script>

<style scoped>
/* =========================================
   FUNDAÇÃO E CSS VARS DO PORTAL
========================================== */
.view-wrap {
  padding-top: 64px;
  font-family: 'Inter', sans-serif;
  background: transparent;
  overflow-x: hidden;
  width: 100%;
}
button { font-family: inherit; cursor: pointer; border: none; outline: none; background: transparent; transition: all 0.2s ease; }

.mj-border-radius { border-radius: 4px !important; }

/* Correção de cor do texto */
.text-main { color: var(--text-main) !important; }
.text-muted { color: var(--text-muted) !important; }
.text-error { color: #ef4444 !important; }
.border-error { border-color: #ef4444 !important; }

.pb-sections { padding: clamp(40px, 6vw, 80px) 0; width: 100%; }

/* CONTAINER: Box-sizing rigoroso para não estourar lateral */
.pb-container {
  max-width: 1700px;
  padding: 0 clamp(16px, 4vw, 56px);
  margin: 0 auto;
  width: 100%;
  box-sizing: border-box;
}

.pb-showcase { margin-bottom: clamp(40px, 5vw, 80px); }

/* =========================================
   CABEÇALHOS DE SEÇÃO
========================================== */
.pb-section-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-end;
  gap: 16px;
  margin-bottom: clamp(20px, 4vw, 40px);
  padding-bottom: 16px;
}
.pb-section-title {
  font-size: clamp(1.3rem, 3vw, 2.4rem);
  font-weight: 900;
  letter-spacing: -0.02em;
  margin: 0;
  line-height: 1.1;
}
.pb-btn-link {
  font-size: clamp(11px, 1vw, 13px);
  font-weight: 700;
  letter-spacing: 0.05em;
  text-transform: uppercase;
  display: inline-flex;
  align-items: center;
  padding-bottom: 2px;
  white-space: nowrap;
}
.pb-btn-link:hover { color: rgb(var(--v-theme-primary)) !important; }

/* =========================================
   GRID ESTAMPAS E MOCKUPS
========================================== */
.pb-grid {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 32px 24px;
  width: 100%;
}
.mockup-display-grid {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 24px;
  width: 100%;
}

@media (max-width: 1400px) {
  .pb-grid { grid-template-columns: repeat(3, minmax(0, 1fr)); }
  .mockup-display-grid { grid-template-columns: repeat(3, minmax(0, 1fr)); }
}
@media (max-width: 959px) {
  .pb-grid { grid-template-columns: repeat(2, minmax(0, 1fr)); }
  .mockup-display-grid { grid-template-columns: repeat(2, minmax(0, 1fr)); }
}
@media (max-width: 599px) {
  .pb-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: 16px 12px;
  }
  .pb-container {
    padding: 0 16px;
    overflow: hidden;
  }
  .mockup-display-grid { grid-template-columns: repeat(1, minmax(0, 1fr)); }
}

/* =========================================
   CARDS DE ESTAMPA
========================================== */
.pb-card {
  display: flex;
  flex-direction: column;
  cursor: pointer;
  transition: transform 0.4s ease;
  min-width: 0;
  width: 100%;
}
.pb-card-media {
  position: relative;
  width: 100%;
  aspect-ratio: 1 / 1;
  overflow: hidden;
  margin-bottom: 16px;
  border-radius: 4px;
  transition: box-shadow 0.4s ease, border-color 0.3s ease;
}

.pb-card.is-wishlisted .pb-card-media {
  box-shadow: 0 0 0 2px #ef4444 !important;
  border-color: transparent !important;
}

.pb-card-img { width: 100%; height: 100%; object-fit: cover; transition: transform 0.8s ease; }

@media (hover: hover) and (pointer: fine) {
  .pb-card:hover .pb-card-media {
    transform: translateY(-4px);
    box-shadow: 0 16px 40px rgba(0,0,0,0.15);
  }
  .pb-card:not(.is-wishlisted):hover .pb-card-media {
    border-color: rgba(var(--v-theme-primary), 0.4) !important;
  }

  .pb-card:hover .pb-card-img { transform: scale(1.05); }

  .pb-card-actions-overlay { position: absolute; inset: 0; background: rgba(0,0,0,0.15); align-items: flex-end; justify-content: center; padding: 20px; opacity: 0; transition: opacity 0.4s ease; z-index: 4; }
  .pb-card:hover .pb-card-actions-overlay { opacity: 1; }

  .pb-actions-bar {
    background-color: rgba(var(--bg-surface-rgb, 255, 255, 255), 0.85);
    backdrop-filter: blur(12px); border-radius: 99px; box-shadow: 0 8px 32px rgba(0,0,0,0.15);
    display: flex; align-items: center; width: 100%; max-width: 280px; height: 48px;
    transform: translateY(15px); transition: transform 0.4s cubic-bezier(0.16, 1, 0.3, 1);
  }
  .pb-card:hover .pb-actions-bar { transform: translateY(0); }

  .pb-actions-divider { width: 1px; height: 24px; background: rgba(128, 128, 128, 0.15); }
  .pb-action-btn { display: flex; align-items: center; justify-content: center; height: 100%; position: relative; }
  .pb-action-btn:hover { background: rgba(128, 128, 128, 0.05); }
  .pb-wishlist-btn, .pb-cart-btn { width: 48px; border-radius: 50%; }
  .pb-quickview-text { font-size: 12px; font-weight: 800; text-transform: uppercase; letter-spacing: 0.1em; padding: 0 16px; }
}

.pb-mobile-actions { position: absolute; top: 8px; right: 8px; z-index: 5; }
.pb-mobile-opt-btn { border-radius: 50%; width: 32px; height: 32px; display: flex; align-items: center; justify-content: center; box-shadow: 0 4px 12px rgba(0,0,0,0.15); position: relative; }
.pb-mobile-opt-btn.text-error { color: #ef4444 !important; }

.pb-card-info {
  display: flex;
  flex-direction: column;
  min-width: 0;
  width: 100%;
}
.pb-card-meta { display: flex; justify-content: space-between; align-items: center; margin-bottom: 6px; }
.pb-ref { font-family: monospace; font-size: 11px; font-weight: 700; }
.pb-price { font-size: 13px; font-weight: 800; }
.pb-title {
  font-size: 15px;
  font-weight: 800;
  line-height: 1.3;
  margin: 0 0 4px 0;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  max-width: 100%;
}
.pb-category { font-size: 11px; font-weight: 600; text-transform: uppercase; letter-spacing: 0.05em; }

@media (max-width: 599px) {
  .pb-card-media { margin-bottom: 12px; }
  .pb-title { font-size: 13px; }
  .pb-price { font-size: 12px; }
  .pb-ref { font-size: 10px; }
  .pb-category { font-size: 9px; }
}

/* =========================================
   ANIMAÇÕES (HEARTS E CART)
========================================== */
.floating-hearts-container { position: absolute; bottom: 50%; left: 0; right: 0; pointer-events: none; z-index: 10; }
.particle-heart { position: absolute; transform: translate(-50%, 0) scale(0); opacity: 0; animation: floatZigZag var(--duration) ease-out forwards; animation-delay: var(--delay); }
.particle-heart.text-error { color: #ef4444 !important; }

@keyframes floatZigZag {
  0% { transform: translate(-50%, 0) scale(0); opacity: 0; }
  15% { transform: translate(calc(-50% + var(--x1)), -25px) scale(var(--scale)); opacity: 1; }
  40% { transform: translate(calc(-50% + var(--x2)), -50px) scale(calc(var(--scale) * 1.1)); opacity: 0.9; }
  75% { transform: translate(calc(-50% + var(--x3)), -90px) scale(calc(var(--scale) * 0.9)); opacity: 0.5; }
  100% { transform: translate(calc(-50% + var(--x4)), -130px) scale(calc(var(--scale) * 0.5)); opacity: 0; }
}

.pb-wishlist-btn.is-active v-icon, .pb-mobile-opt-btn.is-active v-icon { animation: heartBeat 0.4s ease-out; }
@keyframes heartBeat { 0% { transform: scale(1); } 50% { transform: scale(1.4); } 100% { transform: scale(1); } }

.pb-cart-btn .pb-cart-fill { position: absolute; inset: 0; border-radius: 50%; transform: scale(0); opacity: 0; z-index: -1; pointer-events: none; }
.pb-cart-fill.is-filling { animation: cartRipple 0.6s ease-out forwards; }
@keyframes cartRipple { 0% { transform: scale(0); opacity: 0.5; } 100% { transform: scale(2.5); opacity: 0; } }

/* =========================================
   MOCKUPS APLICADOS
========================================== */
.pb-mockup-showcase { padding: 40px 0; }

.mockup-card {
  display: flex;
  flex-direction: column;
  border-radius: 4px;
  overflow: hidden;
  cursor: pointer;
  transition: transform 0.4s ease, box-shadow 0.4s ease;
  min-width: 0;
}
.mockup-card:hover {
  transform: translateY(-6px);
  box-shadow: 0 24px 48px rgba(0,0,0,0.12);
  border-color: rgba(var(--v-theme-primary), 0.5) !important;
}

.mockup-media-wrapper {
  position: relative;
  width: 100%;
  aspect-ratio: 1 / 1;
  overflow: hidden;
}

.mockup-base, .mockup-shadow, .pattern-fill, .mockup-mask {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
}
.mockup-base, .mockup-shadow { object-fit: contain; pointer-events: none; }
.pattern-fill.full { inset: 0; }
.pattern-fill { transition: transform 0.6s ease; }
.mockup-card:hover .pattern-fill { transform: scale(1.05); }
.mockup-shadow { mix-blend-mode: multiply; }

.mockup-info { padding: 16px 20px; display: flex; align-items: center; justify-content: space-between; background: var(--bg-surface); min-width: 0; }

/* =========================================
   PARALLAX DINÂMICO
========================================== */
.pb-dynamic-parallax { position: relative; height: clamp(350px, 50vh, 600px); display: flex; align-items: center; justify-content: center; }
.parallax-bg-wrapper { position: absolute; inset: 0; width: 100%; height: 100%; overflow: hidden; }
.parallax-pattern { position: absolute; inset: 0; background-size: 25%; background-repeat: repeat; opacity: 0.8; }
.parallax-overlay-dark { position: absolute; inset: 0; background: linear-gradient(to right, rgba(0,0,0,0.85) 0%, rgba(0,0,0,0.3) 100%); z-index: 1; }
.parallax-dynamic-content { position: relative; z-index: 2; width: 100%; max-width: 1000px; padding: 0 clamp(20px, 4vw, 40px); }

.line-clamp-3 {
  display: -webkit-box;
  -webkit-line-clamp: 3;
  -webkit-box-orient: vertical;
  overflow: hidden;
  white-space: normal;
}

.slow-fade-enter-active, .slow-fade-leave-active { transition: opacity 1.5s ease; }
.slow-fade-enter-from, .slow-fade-leave-to { opacity: 0; }
.slide-fade-enter-active { transition: all 0.5s ease-out; }
.slide-fade-leave-active { transition: all 0.3s ease-in; }
.slide-fade-enter-from { transform: translateY(10px); opacity: 0; }
.slide-fade-leave-to { transform: translateY(-10px); opacity: 0; }

@media (max-width: 599px) {
  .pb-dynamic-parallax { height: 380px; text-align: center; }
  .parallax-overlay-dark { background: linear-gradient(to top, rgba(0,0,0,0.85) 0%, rgba(0,0,0,0.4) 100%); }
  .parallax-dynamic-content { display: flex; flex-direction: column; align-items: center; }
  .parallax-dynamic-content .pb-btn { width: 100%; }
}

/* =========================================
   MOSAICO EDITORIAL
========================================== */
.pb-editorial-mosaic { padding: 40px 0; }
.mosaic-grid {
  display: grid;
  grid-template-columns: 1.5fr 1fr;
  gap: 24px;
  height: clamp(400px, 60vh, 600px);
}
.mosaic-side { display: grid; grid-template-rows: 1fr 1fr; gap: 24px; }

.mosaic-main, .mosaic-item {
  position: relative;
  border-radius: 4px;
  overflow: hidden;
  cursor: pointer;
}
.mosaic-bg {
  position: absolute; inset: 0; width: 100%; height: 100%; object-fit: cover;
  transition: transform 0.8s ease;
}
.mosaic-main:hover .mosaic-bg, .mosaic-item:hover .mosaic-bg { transform: scale(1.08); }
.mosaic-overlay {
  position: absolute; inset: 0;
  background: linear-gradient(to top, rgba(0,0,0,0.85) 0%, rgba(0,0,0,0.1) 60%, transparent 100%);
  display: flex; flex-direction: column; justify-content: flex-end;
  padding: clamp(20px, 3vw, 32px);
  z-index: 2;
}

@media (max-width: 959px) {
  .mosaic-grid { grid-template-columns: 1fr; height: auto; }
  .mosaic-main { height: 350px; }
  .mosaic-side { grid-template-columns: 1fr 1fr; grid-template-rows: 1fr; height: 220px; gap: 16px; }
}
@media (max-width: 599px) {
  .mosaic-main { height: 300px; }
  .mosaic-side { grid-template-columns: 1fr; grid-template-rows: repeat(2, 180px); height: auto; gap: 16px; }
}

/* =========================================
   HERO E BANNER FIXO
========================================== */
.pb-hero { position: relative; height: clamp(400px, 75vh, 850px); display: flex; align-items: center; justify-content: center; overflow: hidden; background: #000; }
.pb-hero-media { position: absolute; inset: 0; width: 100%; height: 100%; object-fit: cover; opacity: 0.65; }
.pb-hero-overlay { position: absolute; inset: 0; background: linear-gradient(180deg, rgba(0,0,0,0.1) 0%, rgba(0,0,0,0.8) 100%); }
.pb-hero-content { position: relative; z-index: 2; text-align: center; max-width: 900px; padding: 0 24px; animation: fadeIn 0.8s ease-out; width: 100%; }
@keyframes fadeIn { from { opacity: 0; transform: translateY(10px); } to { opacity: 1; transform: translateY(0); } }

.pb-kicker { font-size: clamp(10px, 1.2vw, 13px); font-weight: 800; letter-spacing: 0.15em; text-transform: uppercase; margin-bottom: 16px; }
.pb-hero-title { font-size: clamp(2rem, 6vw, 4.5rem); font-weight: 900; line-height: 1.05; letter-spacing: -0.03em; margin: 0 0 20px 0; text-shadow: 0 4px 12px rgba(0,0,0,0.3); }
.pb-hero-text { font-size: clamp(0.95rem, 1.5vw, 1.25rem); font-weight: 400; line-height: 1.6; margin: 0 auto 40px; max-width: 680px; opacity: 0.9; }

@media (max-width: 599px) {
  .responsive-h2 { font-size: 1.8rem !important; line-height: 1.2 !important; }
  .responsive-h3 { font-size: 1.6rem !important; line-height: 1.2 !important; }
  .responsive-h4 { font-size: 1.4rem !important; line-height: 1.2 !important; }
  .responsive-h5 { font-size: 1.2rem !important; line-height: 1.2 !important; }
  .responsive-p { font-size: 0.9rem !important; }
}

.pb-btn { display: inline-flex; align-items: center; justify-content: center; height: 52px; padding: 0 36px; font-size: 14px; font-weight: 700; letter-spacing: 0.05em; text-transform: uppercase; border-radius: 4px; transition: all 0.3s ease; }
.pb-btn-primary { background: rgb(var(--v-theme-primary)); color: #fff; box-shadow: 0 4px 0 rgba(0,0,0,0.2), inset 0 2px 0 rgba(255,255,255,0.2); }
.pb-btn-primary:active { transform: translateY(4px); box-shadow: 0 0 0 rgba(0,0,0,0.2), inset 0 1px 0 rgba(255,255,255,0.1); }

@media (max-width: 599px) {
  .pb-hero-actions { display: flex; flex-direction: column; width: 100%; }
  .pb-hero-actions .pb-btn { width: 100%; }
}

.pb-banner { position: relative; height: 50vh; min-height: 350px; display: flex; align-items: center; justify-content: center; overflow: hidden; background: #000; margin-top: 40px;}
.pb-banner-media { position: absolute; inset: 0; width: 100%; height: 100%; object-fit: cover; opacity: 0.6; }
@supports (background-attachment: fixed) { .pb-banner { background-attachment: fixed; } }
.pb-banner-overlay { position: absolute; inset: 0; background: linear-gradient(0deg, rgba(0,0,0,0.6) 0%, rgba(0,0,0,0.2) 100%); }
.pb-banner-content { position: relative; z-index: 2; text-align: center; max-width: 800px; padding: 0 24px; width: 100%; }
.pb-banner-title { font-size: clamp(1.8rem, 4vw, 3.5rem); font-weight: 900; letter-spacing: -0.02em; margin-bottom: 16px; }
.pb-btn-outline { background: transparent; border: 2px solid #fff; color: #fff; box-shadow: 0 4px 0 rgba(0,0,0,0.2); }
.pb-btn-outline:active { background: #fff; color: #000; transform: translateY(4px); box-shadow: 0 0 0 rgba(0,0,0,0.2); }

@media (max-width: 599px) {
  .pb-banner-content .pb-btn { width: 100%; }
}

.pb-actions-bar .pb-quickview-text { color: #111 !important; }
.pb-actions-bar .pb-action-btn.text-muted:not(.is-active) { color: #666 !important; }
</style>
