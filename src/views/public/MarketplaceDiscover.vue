<template>
  <div class="view-wrap discover-view" :class="{ 'modal-open': focusedStamp }">
    <section class="discover-top mj-border">
      <div class="discover-top-inner">
        <div class="eyebrow">Acervo</div>
        <h1 class="hero-title compact">Explore estampas com curadoria visual.</h1>

        <div class="search-shell mj-surface mj-border">
          <v-icon size="22" class="search-icon">mdi-magnify</v-icon>
          <input
            v-model="searchQuery"
            type="text"
            class="search-input"
            placeholder="Pesquisar referências, títulos ou temas"
          />
        </div>

        <div class="filter-bar mj-surface-2 mj-border">
          <button class="filter-chip" :class="{ active: activeFilter === null }" @click="activeFilter = null">
            Todas as coleções
          </button>
          <button
            v-for="cat in categories"
            :key="cat.id"
            class="filter-chip"
            :class="{ active: activeFilter === cat.id }"
            @click="activeFilter = cat.id"
          >
            {{ cat.name }}
          </button>
        </div>
      </div>
    </section>

    <section class="discover-grid-wrap">
      <div class="fluid-container">

        <div
          v-if="hasStamps"
          class="masonry-layout-real"
          :style="{
            filter: dynamicBlur > 0 ? `blur(${dynamicBlur}px) grayscale(${dynamicBlur * 4}%)` : 'none',
            transition: dynamicBlur === 0 ? 'filter 0.5s ease-out' : 'none'
          }"
        >
          <div v-for="(col, colIndex) in masonryColumns" :key="`col-${colIndex}`" class="masonry-col">
            <article
              v-for="(stamp, index) in col"
              :key="stamp.unique_key"
              class="masonry-item-real"
              :style="{ animationDelay: `${(index % 15) * 0.03}s` }"
            >
              <div
                class="discover-card mj-surface mj-border"
                :class="{
                  'is-wishlisted': isInWishlist(stamp.id),
                  'degraded-visuals': protectionStore.riskScore >= 40
                }"
                v-track-art="stamp.id"
                @touchstart="handleTouchStart($event, stamp)"
                @touchmove="handleTouchMove"
                @touchend="handleTouchEnd"
              >
                <div class="discover-card-inner" @click="openPinterestModal(stamp)">
                  <img
                    v-if="stamp.main_image_url"
                    :src="getOptimizedUrl(stamp.main_image_url, 500)"
                    alt="Estampa"
                    class="discover-image"
                    loading="lazy"
                  />
                  <div v-else class="discover-placeholder">Sem imagem</div>

                  <div class="discover-overlay">
                    <div class="discover-overlay-inner">
                      <div class="d-flex justify-space-between align-center">
                        <span class="stamp-ref dark-ref">{{ stamp.ref_code }}</span>
                        <span class="text-[10px] font-weight-bold" :class="stamp.stamp_type === 'Barrado' ? 'text-warning' : 'text-primary'">{{ stamp.stamp_type || 'Corrida' }}</span>
                      </div>
                      <h3 class="discover-title">{{ stamp.title }}</h3>
                      <p class="discover-category">{{ stamp.catalog_categories?.name || 'Geral' }}</p>
                    </div>
                  </div>
                </div>

                <button
                  class="heart-btn"
                  :class="{ 'is-liked': isInWishlist(stamp.id) }"
                  @click.stop="handleWishlistClick(stamp)"
                  title="Salvar na Coleção"
                >
                  <v-icon size="20">{{ isInWishlist(stamp.id) ? 'mdi-heart' : 'mdi-heart-outline' }}</v-icon>

                  <div class="floating-hearts-container" v-if="activeHearts[stamp.id]">
                    <v-icon
                      v-for="heart in activeHearts[stamp.id]"
                      :key="heart.id"
                      class="particle-heart text-error"
                      :style="{ '--x1': heart.x1, '--x2': heart.x2, '--x3': heart.x3, '--x4': heart.x4, '--scale': heart.scale, '--duration': heart.duration, '--delay': heart.delay }"
                      size="14"
                    >mdi-heart</v-icon>
                  </div>
                </button>
              </div>
            </article>
          </div>
        </div>

        <div v-else class="empty-state mj-surface mj-border">
          <v-icon size="52">mdi-texture-box</v-icon>
          <h3>Nenhuma estampa encontrada</h3>
          <p>Refine a pesquisa ou altere os filtros para encontrar itens do acervo.</p>
        </div>

        <div ref="scrollSentinel" class="d-flex flex-column align-center justify-center py-10 w-100" style="min-height: 160px; clear: both;">
           <v-progress-circular
              v-show="isLoadingMore && protectionStore.riskScore <= 20"
              indeterminate
              color="primary"
              size="32"
              width="3"
           ></v-progress-circular>

           <transition name="fade">
             <div v-if="protectionStore.riskScore > 20 && !isLoadingMore" class="d-flex flex-column align-center text-center">
               <v-btn
                 color="primary"
                 variant="tonal"
                 class="font-weight-bold px-8 text-none rounded-pill btn-3d"
                 height="48"
                 @click="forceManualLoad"
                 prepend-icon="mdi-chevron-down"
               >
                 Continuar Descobrindo
               </v-btn>
               <span class="text-caption opacity-60 mt-3 d-block" style="max-width: 320px; line-height: 1.4;">
                 Detectamos uma navegação rápida. Clique acima ou interaja com uma estampa para ver mais novidades.
               </span>
             </div>
           </transition>
        </div>

      </div>
    </section>

    <transition name="fade">
      <div v-if="focusedStamp" class="premium-pinterest-overlay" @click.self="closePinterestModal">

        <v-btn icon="mdi-close" variant="flat" class="close-modal-btn" @click="closePinterestModal"></v-btn>

        <div class="modal-scroll-area custom-scrollbar" @click.self="closePinterestModal">

          <div class="focused-hero" @click.self="closePinterestModal">

            <div class="image-showcase">
              <img :src="getOptimizedUrl(focusedStamp.main_image_url, 1200)" class="focused-img" />

              <div class="floating-action-bar">
                <div class="fab-info">
                  <span class="fab-ref">{{ focusedStamp.ref_code }}</span>
                  <span class="fab-title text-truncate">{{ focusedStamp.title }}</span>
                </div>
                <div class="fab-actions">
                  <button
                    class="fab-btn heart"
                    :class="{ 'liked': isInWishlist(focusedStamp.id) }"
                    @click.stop="handleWishlistClick(focusedStamp)"
                  >
                    <v-icon size="20">{{ isInWishlist(focusedStamp.id) ? 'mdi-heart' : 'mdi-heart-outline' }}</v-icon>
                    <div class="floating-hearts-container" v-if="activeHearts[focusedStamp.id]">
                      <v-icon
                        v-for="heart in activeHearts[focusedStamp.id]"
                        :key="heart.id"
                        class="particle-heart text-error"
                        :style="{ '--x1': heart.x1, '--x2': heart.x2, '--x3': heart.x3, '--x4': heart.x4, '--scale': heart.scale, '--duration': heart.duration, '--delay': heart.delay }"
                        size="14"
                      >mdi-heart</v-icon>
                    </div>
                  </button>
                </div>
              </div>
            </div>

            <button class="premium-view-btn mt-12" @click.stop="goToProduct(focusedStamp)">
              <span>Ver Detalhes da Estampa</span>
              <v-icon size="18">mdi-arrow-right</v-icon>
            </button>

          </div>

          <div class="similar-full-width">
            <div class="similar-content">
              <h3 class="similar-title text-center text-main">
                Mais da categoria "{{ focusedStamp.catalog_categories?.name || 'Acervo' }}"
              </h3>

              <div class="masonry-layout-real" v-if="similarMasonryColumns.some(col => col.length > 0)">
                <div v-for="(col, colIndex) in similarMasonryColumns" :key="`sim-col-${colIndex}`" class="masonry-col">
                  <article
                    v-for="stamp in col"
                    :key="stamp.id"
                    class="masonry-item-real"
                  >
                    <div class="discover-card mj-surface mj-border" :class="{'is-wishlisted': isInWishlist(stamp.id)}" @click="openPinterestModal(stamp)">
                      <div class="discover-card-inner">
                        <img :src="getOptimizedUrl(stamp.main_image_url, 400)" class="discover-image" loading="lazy" />
                        <div class="discover-overlay">
                          <div class="discover-overlay-inner">
                            <h3 class="discover-title text-truncate">{{ stamp.title }}</h3>
                          </div>
                        </div>
                      </div>
                      <button class="heart-btn" :class="{ 'is-liked': isInWishlist(stamp.id) }" @click.stop="handleWishlistClick(stamp)">
                        <v-icon size="16">{{ isInWishlist(stamp.id) ? 'mdi-heart' : 'mdi-heart-outline' }}</v-icon>
                        <div class="floating-hearts-container" v-if="activeHearts[stamp.id]">
                          <v-icon
                            v-for="heart in activeHearts[stamp.id]"
                            :key="heart.id"
                            class="particle-heart text-error"
                            :style="{ '--x1': heart.x1, '--x2': heart.x2, '--x3': heart.x3, '--x4': heart.x4, '--scale': heart.scale, '--duration': heart.duration, '--delay': heart.delay }"
                            size="14"
                          >mdi-heart</v-icon>
                        </div>
                      </button>
                    </div>
                  </article>
                </div>
              </div>

              <div v-else class="text-center py-10 opacity-50">
                <v-icon size="40" class="mb-4">mdi-shape-outline</v-icon>
                <p>Nenhuma estampa semelhante encontrada.</p>
              </div>

            </div>
          </div>

        </div>
      </div>
    </transition>

    <v-dialog v-model="showFolderModal" max-width="420" content-class="premium-folder-dialog" transition="dialog-bottom-transition" z-index="100000">
      <v-card class="premium-folder-card pa-2">
        <v-card-title class="text-h6 font-weight-black text-center pt-6 pb-2 text-main">
          Salvar em qual coleção?
        </v-card-title>
        <v-card-text class="pa-4 pt-2 custom-scrollbar" style="max-height: 60vh; overflow-y: auto;">
          <div class="d-flex align-center gap-3 pa-3 rounded-xl border mj-surface-2 cursor-pointer mb-3 folder-option-card" @click="confirmSaveToFolder(null)">
             <v-avatar color="primary" size="48" class="rounded-lg"><v-icon color="white">mdi-home-variant-outline</v-icon></v-avatar>
             <div class="flex-grow-1">
               <h4 class="font-weight-bold text-body-1 m-0 text-main">Início</h4>
               <p class="text-caption text-muted m-0">Coleção principal</p>
             </div>
             <v-btn color="primary" variant="flat" size="small" class="rounded-pill font-weight-bold text-none px-4 save-btn">Salvar</v-btn>
          </div>

          <div
            v-for="folder in userFolders"
            :key="folder.id"
            class="d-flex align-center gap-3 pa-3 rounded-xl border mj-surface-2 cursor-pointer mb-3 folder-option-card"
            @click="confirmSaveToFolder(folder.id)"
          >
             <v-avatar color="surface" size="48" class="rounded-lg border"><v-icon class="gold-gradient-icon">mdi-folder-star</v-icon></v-avatar>
             <div class="flex-grow-1 overflow-hidden">
               <h4 class="font-weight-bold text-body-1 m-0 text-truncate text-main">{{ folder.name }}</h4>
               <p class="text-caption text-muted m-0">Subpasta personalizada</p>
             </div>
             <v-btn color="error" variant="tonal" size="small" class="rounded-pill font-weight-bold text-none px-4 save-btn">Salvar</v-btn>
          </div>

          <v-divider class="my-5 border-color"></v-divider>

          <v-btn block variant="outlined" color="primary" class="rounded-xl font-weight-bold text-none border-dashed create-folder-btn" height="52" @click="router.push('/marketplace/favoritos')">
            <v-icon start>mdi-folder-plus-outline</v-icon> Criar Nova Pasta
          </v-btn>
        </v-card-text>
      </v-card>
    </v-dialog>

    <transition name="fade">
      <div v-if="showCopyrightWarning" class="copyright-warning-overlay">
        <div class="copyright-warning-card mj-border">
          <div class="warning-icon-wrap">
            <v-icon size="42" color="error">mdi-shield-alert-outline</v-icon>
          </div>
          <h3 class="warning-title">Ação Interceptada</h3>
          <p class="warning-desc">
            Nossas estampas são protegidas por direitos autorais. O download, cópia de código ou uso de ferramentas de inspeção não são permitidos.
          </p>

          <div class="strike-indicator">
            <div
              v-for="i in 3"
              :key="i"
              class="strike-dot"
              :class="{ 'filled-error': i <= (3 - copyrightStrikesLeft) }"
            ></div>
          </div>

          <p class="strike-text mb-6" :class="{ 'text-error font-weight-bold': copyrightStrikesLeft === 1 }">
            {{ copyrightStrikesLeft > 0 ? `Aviso ${4 - copyrightStrikesLeft} de 3. Reincidência causará suspensão.` : 'Sua sessão foi bloqueada por violação de segurança.' }}
          </p>

          <v-btn
            color="error"
            variant="flat"
            class="w-100 font-weight-bold text-none rounded-lg btn-3d"
            height="48"
            @click="acknowledgeWarning"
          >
            Estou Ciente
          </v-btn>
        </div>
      </div>
    </transition>

  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted, computed, watch } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { supabase } from '@/api/supabase'
import { useMarketplaceUserStore } from '@/stores/marketplaceUser'
import { useProtectionStore } from '@/stores/protectionStore'

const router = useRouter()
const route = useRoute()
const userStore = useMarketplaceUserStore()
const protectionStore = useProtectionStore()

const props = defineProps<{ settings: any }>()

const searchQuery = ref('')
const activeFilter = ref<string | null>(null)

const allStamps = ref<any[]>([])
const categories = ref<any[]>([])

const numColumns = ref(5)
const masonryColumns = ref<any[][]>([[], [], [], [], []])
let loopCounter = 0

const scrollVelocity = ref(0)
const dynamicBlur = computed(() => {
  return scrollVelocity.value > 1.2 ? Math.min((scrollVelocity.value - 1.2) * 2.5, 12) : 0
})

const hasStamps = computed(() => masonryColumns.value.some(col => col.length > 0))

const isLoadingMore = ref(false)
const scrollSentinel = ref<HTMLElement | null>(null)
let observer: IntersectionObserver | null = null

const placeholderStamps = Array.from({ length: 12 }).map((_, i) => ({
  id: `mock-${i}`,
  ref_code: `REF-00${i + 1}`,
  title: `Carregando...`,
  main_image_url: '',
  category_id: null,
  stamp_type: 'Corrida',
  catalog_categories: { name: 'Aguarde' },
  dominant_color: i % 2 === 0 ? '#111111' : '#dddddd',
  description: 'Carregando itens do catálogo.'
}))

// Função utilitária para misturar arrays (Fisher-Yates)
function shuffleArray(array: any[]) {
  const newArray = [...array]
  for (let i = newArray.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [newArray[i], newArray[j]] = [newArray[j], newArray[i]];
  }
  return newArray
}

const baseFilteredStamps = computed(() => {
  let list = allStamps.value.length ? [...allStamps.value] : [...placeholderStamps]

  if (activeFilter.value) {
    list = list.filter((s) => s.category_id === activeFilter.value)
  }

  if (searchQuery.value.trim()) {
    const q = searchQuery.value.toLowerCase()
    list = list.filter(
      (s) =>
        s.ref_code?.toLowerCase().includes(q) ||
        s.title?.toLowerCase().includes(q) ||
        s.description?.toLowerCase?.().includes(q)
    )
  }
  return list
})

function appendMoreStamps() {
  if (!baseFilteredStamps.value.length) return

  let block = baseFilteredStamps.value.map(s => ({ ...s, unique_key: `${s.id}-loop${loopCounter}-${crypto.randomUUID()}` }))

  if (loopCounter > 0) {
    block = shuffleArray(block)
  }

  block.forEach((stamp, index) => {
    masonryColumns.value[index % numColumns.value].push(stamp)
  })

  loopCounter++
}

function calculateColumns() {
  const width = window.innerWidth
  let newColsCount = 10
  if (width <= 767) newColsCount = 2
  else if (width <= 959) newColsCount = 3
  else if (width <= 1199) newColsCount = 4
  else if (width <= 1440) newColsCount = 5
  else if (width <= 1920) newColsCount = 6
  else if (width <= 2560) newColsCount = 8

  if (numColumns.value !== newColsCount || !hasStamps.value) {
    numColumns.value = newColsCount
    const allItems = masonryColumns.value.flat()
    const newCols: any[][] = Array.from({ length: numColumns.value }, () => [])

    allItems.forEach((stamp, index) => {
      newCols[index % numColumns.value].push(stamp)
    })

    masonryColumns.value = newCols
  }
}

let lastScrollY = typeof window !== 'undefined' ? window.scrollY : 0
let lastTimestamp = performance.now()
let decayTimer: ReturnType<typeof setTimeout> | null = null

function handleScroll() {
  const currentScrollY = window.scrollY
  const now = performance.now()
  const dt = now - lastTimestamp

  if (dt > 0) {
    const distance = Math.abs(currentScrollY - lastScrollY)
    const speed = distance / dt
    scrollVelocity.value = speed
  }

  lastScrollY = currentScrollY
  lastTimestamp = now

  if (decayTimer) clearTimeout(decayTimer)
  decayTimer = setTimeout(() => {
    scrollVelocity.value = 0
  }, 120)
}

// === SISTEMA DE PROTEÇÃO CONTRA PLÁGIO ===
const showCopyrightWarning = ref(false)
const copyrightStrikesLeft = ref(3)

watch(() => protectionStore.accessStatus, (newStatus) => {
  if (newStatus === 'blocked') {
    localStorage.removeItem('mj_active_code')
    router.push({ name: 'MarketplaceLogin', query: { blocked: 'true' } })
  }
})

function triggerPlagiarismWarning(e: Event) {
  e.preventDefault()

  if (showCopyrightWarning.value) return;

  protectionStore.registerPlagiarismAttempt()
  const strikes = protectionStore.plagiarismStrikes

  copyrightStrikesLeft.value = Math.max(0, 3 - strikes)
  showCopyrightWarning.value = true
}

function acknowledgeWarning() {
  showCopyrightWarning.value = false;

  if (protectionStore.plagiarismStrikes >= 3 || protectionStore.accessStatus === 'blocked') {
    localStorage.removeItem('mj_active_code');
    router.push({ name: 'MarketplaceLogin', query: { blocked: 'true' } });
  }
}

function handleSecurityKeydown(e: KeyboardEvent) {
  if (e.key === 'F12') { triggerPlagiarismWarning(e); return; }
  if (e.ctrlKey && e.shiftKey && ['I', 'J', 'C'].includes(e.key.toUpperCase())) { triggerPlagiarismWarning(e); return; }
  if (e.ctrlKey && ['U', 'S', 'P'].includes(e.key.toUpperCase())) { triggerPlagiarismWarning(e); return; }
}

function handleGlobalContextMenu(e: MouseEvent) {
  triggerPlagiarismWarning(e)
}

watch([searchQuery, activeFilter], () => {
  masonryColumns.value = Array.from({ length: numColumns.value }, () => [])
  loopCounter = 0
  appendMoreStamps()
})

watch(() => route.query.filter, (newFilter) => {
  if (newFilter) activeFilter.value = newFilter as string
  else activeFilter.value = null
})

onMounted(async () => {
  calculateColumns()

  await protectionStore.initializeGuard()
  protectionStore.setContext('discover')

  window.addEventListener('resize', calculateColumns)
  window.addEventListener('scroll', handleScroll, { passive: true })

  window.addEventListener('contextmenu', handleGlobalContextMenu)
  window.addEventListener('keydown', handleSecurityKeydown)

  try {
    const { data: { session } } = await supabase.auth.getSession()
    if (session && !userStore.user) {
      const { data: leadData } = await supabase.from('public_leads').select('*').eq('email', session.user.email).maybeSingle()
      if (leadData) {
        await userStore.setUser({
          id: leadData.id,
          name: leadData.name || '',
          email: leadData.email,
          phone: leadData.phone,
          document: leadData.document,
          avatarUrl: leadData.avatar_url
        })
      }
    }
  } catch (e) {}

  if (route.query.filter) {
    activeFilter.value = route.query.filter as string
  }

  try {
    const { data: catData } = await supabase.from('catalog_categories').select('id, name').eq('is_active', true).order('name')
    categories.value = catData || []

    const { data: stampData } = await supabase.from('catalog_stamps').select('*, catalog_categories(name)').eq('is_active', true).order('created_at', { ascending: false })

    allStamps.value = stampData ? shuffleArray(stampData) : []

    if (!hasStamps.value) appendMoreStamps()
  } catch (error) {}

  observer = new IntersectionObserver((entries) => {
    if (entries[0].isIntersecting && baseFilteredStamps.value.length > 0) {
      if (protectionStore.riskScore > 20) return;

      if (isLoadingMore.value) return;
      isLoadingMore.value = true;

      setTimeout(() => {
        appendMoreStamps();
        setTimeout(() => { isLoadingMore.value = false; }, 100);
      }, 200);
    }
  }, { rootMargin: '1200px' })

  if (scrollSentinel.value) {
    observer.observe(scrollSentinel.value)
  }
})

onUnmounted(() => {
  if (observer) observer.disconnect()
  window.removeEventListener('resize', calculateColumns)
  window.removeEventListener('scroll', handleScroll)
  window.removeEventListener('contextmenu', handleGlobalContextMenu)
  window.removeEventListener('keydown', handleSecurityKeydown)
})

function forceManualLoad() {
  protectionStore.logInteraction('manual_load', 'pagination');
  isLoadingMore.value = true;
  setTimeout(() => {
    appendMoreStamps();
    setTimeout(() => { isLoadingMore.value = false; }, 100);
  }, 350);
}

// ==========================================
// MÉTODOS DE RENDERIZAÇÃO
// ==========================================
function getOptimizedUrl(originalUrl: string | null | undefined, targetWidth: number) {
  if (!originalUrl) return '/placeholder.png'
  if (!originalUrl.includes('supabase.co') || !originalUrl.includes('/object/public/')) return originalUrl

  try {
    const urlParts = originalUrl.split('/object/public/')
    const pathAndBucket = urlParts[1]
    const firstSlashIndex = pathAndBucket.indexOf('/')
    const bucket = pathAndBucket.substring(0, firstSlashIndex)

    let filePath = pathAndBucket.substring(firstSlashIndex + 1)
    if (filePath.includes('?')) filePath = filePath.split('?')[0]

    filePath = decodeURIComponent(filePath)

    const { data } = supabase.storage.from(bucket).getPublicUrl(filePath, {
      transform: { width: targetWidth }
    })

    return data.publicUrl
  } catch (err) {
    return originalUrl
  }
}

// ==========================================
// ESTADOS E MÉTODOS PINTEREST MODAL & FOLDERS
// ==========================================
const focusedStamp = ref<any>(null)
const similarMasonryColumns = ref<any[][]>([[], [], [], [], [], []])
const showFolderModal = ref(false)
const stampToSave = ref<any>(null)
const userFolders = ref<any[]>([])
const activeHearts = ref<Record<string, any[]>>({})
let heartIdCounter = 0

function openPinterestModal(stamp: any) {
  if (isLongPress) return;
  protectionStore.logInteraction('zoom', stamp.id);
  focusedStamp.value = stamp;
  document.body.style.overflow = 'hidden';

  let similar = allStamps.value.filter(s => s.category_id === stamp.category_id && s.id !== stamp.id);
  similar = shuffleArray(similar).slice(0, 30);

  // Configurado para 3 colunas no mobile
  const colsCount = window.innerWidth < 768 ? 3 : window.innerWidth < 1200 ? 5 : 7;
  const newCols: any[][] = Array.from({ length: colsCount }, () => []);
  similar.forEach((s, idx) => newCols[idx % colsCount].push(s));
  similarMasonryColumns.value = newCols;
}

function closePinterestModal() {
  focusedStamp.value = null;
  document.body.style.overflow = '';
}

function goToProduct(stamp: any) {
  if (isLongPress) return;
  closePinterestModal();
  router.push(`/marketplace/produto/${stamp.id}`);
}

const isInWishlist = (id: string) => userStore.wishlist.includes(id)

function loadFolders() {
  if (!userStore.user) return;
  const saved = localStorage.getItem(`mj_folders_${userStore.user.id}`);
  userFolders.value = saved ? JSON.parse(saved) : [];
}

async function handleWishlistClick(stamp: any) {
  if (!userStore.isAuthenticated) {
    alert('Por favor, faça login para salvar estampas nos seus favoritos!');
    return;
  }

  protectionStore.logInteraction('favorite', stamp.id);

  if (isInWishlist(stamp.id)) {
    await userStore.toggleWishlist(stamp.id);
    const savedAssignments = localStorage.getItem(`mj_fav_assign_${userStore.user?.id}`);
    if (savedAssignments) {
       let assignments = JSON.parse(savedAssignments);
       delete assignments[stamp.id];
       localStorage.setItem(`mj_fav_assign_${userStore.user?.id}`, JSON.stringify(assignments));
    }
  } else {
    stampToSave.value = stamp;
    loadFolders();
    showFolderModal.value = true;
  }
}

async function confirmSaveToFolder(folderId: string | null) {
  if (!stampToSave.value) return;

  triggerHeartAnimation(stampToSave.value.id);
  await userStore.toggleWishlist(stampToSave.value.id);

  const savedAssignments = localStorage.getItem(`mj_fav_assign_${userStore.user?.id}`);
  let assignments: Record<string, string | null> = savedAssignments ? JSON.parse(savedAssignments) : {};
  assignments[stampToSave.value.id] = folderId;
  localStorage.setItem(`mj_fav_assign_${userStore.user?.id}`, JSON.stringify(assignments));

  showFolderModal.value = false;
  stampToSave.value = null;
}

function triggerHeartAnimation(stampId: string) {
  if (!activeHearts.value[stampId]) activeHearts.value[stampId] = [];
  const newHearts = Array.from({ length: 6 }).map(() => ({
    id: heartIdCounter++,
    x1: (Math.random() - 0.5) * 30 + 'px', x2: (Math.random() - 0.5) * 60 + 'px',
    x3: (Math.random() - 0.5) * 40 + 'px', x4: (Math.random() - 0.5) * 80 + 'px',
    scale: 0.6 + Math.random() * 0.8, duration: 1.0 + Math.random() * 0.8 + 's', delay: Math.random() * 0.3 + 's'
  }));
  activeHearts.value[stampId].push(...newHearts);
  setTimeout(() => {
    if (activeHearts.value[stampId]) {
      activeHearts.value[stampId] = activeHearts.value[stampId].filter(h => !newHearts.some(nh => nh.id === h.id));
    }
  }, 2500);
}

// ==========================================
// EVENTOS DE TOQUE
// ==========================================
let touchTimer: ReturnType<typeof setTimeout> | null = null
let isLongPress = false
let touchStartPos = { x: 0, y: 0 }

function handleTouchStart(e: TouchEvent, stamp: any) {
  isLongPress = false
  touchStartPos = { x: e.touches[0].clientX, y: e.touches[0].clientY }

  touchTimer = setTimeout(() => {
    isLongPress = true
    openPinterestModal(stamp)
    if (navigator.vibrate) navigator.vibrate(50)
  }, 450)
}

function handleTouchMove(e: TouchEvent) {
  const moveX = Math.abs(e.touches[0].clientX - touchStartPos.x)
  const moveY = Math.abs(e.touches[0].clientY - touchStartPos.y)
  if (moveX > 10 || moveY > 10) {
    if (touchTimer) clearTimeout(touchTimer)
  }
}

function handleTouchEnd() {
  if (touchTimer) clearTimeout(touchTimer)
}
</script>

<style scoped>
.view-wrap {
  padding-top: 82px;
}

.discover-view {
  min-height: calc(100vh - 82px);
}

.text-error { color: #ef4444 !important; }

.eyebrow {
  display: inline-flex;
  align-items: center;
  min-height: 30px;
  padding: 0 14px;
  border-radius: 999px;
  background: rgba(var(--v-theme-primary), 0.12);
  color: rgb(var(--v-theme-primary));
  font-weight: 800;
  font-size: 12px;
  letter-spacing: 0.12em;
  text-transform: uppercase;
  margin-bottom: 12px;
}

.hero-title.compact {
  margin: 0;
  color: var(--text-main);
  letter-spacing: -0.04em;
  line-height: 1.02;
  font-size: clamp(2.2rem, 4vw, 4rem);
}

.discover-top {
  padding: 46px 0 28px;
  background: linear-gradient(180deg, rgba(var(--v-theme-primary), 0.06), transparent 90%);
}

.discover-top-inner {
  width: min(1200px, calc(100% - 32px));
  margin: 0 auto;
  text-align: center;
}

.search-shell {
  margin: 28px auto 0;
  max-width: 820px;
  min-height: 68px;
  display: flex;
  align-items: center;
  gap: 14px;
  padding: 0 20px;
  border-radius: 18px;
}

.search-icon {
  color: var(--text-muted);
}

.search-input {
  width: 100%;
  height: 56px;
  border: 0;
  background: transparent;
  color: var(--text-main);
  box-shadow: none;
  font-size: 1.05rem;
  outline: none;
}

.search-input::placeholder {
  color: var(--text-muted);
}

.filter-bar {
  margin: 22px auto 0;
  max-width: 1200px;
  padding: 10px;
  border-radius: 999px;
  display: flex;
  gap: 10px;
  flex-wrap: wrap;
  justify-content: center;
}

.filter-chip {
  min-height: 42px;
  padding: 0 18px;
  border: 1px solid transparent;
  background: transparent;
  color: var(--text-muted);
  border-radius: 999px;
  font-size: 12px;
  font-weight: 800;
  text-transform: uppercase;
  letter-spacing: 0.08em;
  cursor: pointer;
  transition: all 0.2s ease;
}

.filter-chip.active,
.filter-chip:hover {
  background: var(--bg-surface);
  color: var(--text-main);
  border-color: var(--border-color);
}

.discover-grid-wrap {
  padding: 40px 0 20px;
}

.fluid-container {
  width: 100%;
  padding-left: 24px;
  padding-right: 24px;
  margin: 0 auto;
}

.masonry-layout-real {
  display: flex;
  gap: 20px;
  align-items: flex-start;
  will-change: filter;
}

.masonry-col {
  display: flex;
  flex-direction: column;
  gap: 20px;
  flex: 1;
  min-width: 0;
}

.masonry-item-real {
  position: relative;
  transform: translateZ(0);
  animation: masonryFadeIn 0.6s cubic-bezier(0.2, 0.8, 0.2, 1) both;
}

@keyframes masonryFadeIn {
  from { opacity: 0; transform: translateY(20px); }
  to { opacity: 1; transform: translateY(0); }
}

.discover-card {
  position: relative;
  border-radius: 20px;
  background: var(--bg-surface);
  transition: transform 0.25s ease, box-shadow 0.25s ease, border-color 0.25s ease;
  border: 2px solid transparent;
  cursor: pointer;
}

.discover-card-inner {
  border-radius: 18px;
  overflow: hidden;
  position: relative;
}

.discover-card.is-wishlisted {
  box-shadow: 0 0 0 2px #ef4444 !important;
  border-color: transparent !important;
}

.discover-card:not(.is-wishlisted):hover {
  transform: translateY(-4px);
  box-shadow: var(--hover-shadow);
  border-color: rgba(var(--v-theme-primary), 0.36);
}

.discover-card.is-wishlisted:hover {
  transform: translateY(-4px);
  box-shadow: 0 16px 32px rgba(239, 68, 68, 0.25) !important;
}

.discover-image {
  width: 100%;
  height: auto;
  min-height: 220px;
  background-color: var(--bg-surface-2);
  display: block;
  transition: opacity 0.3s ease, filter 0.6s ease;
  pointer-events: none;
  -webkit-user-drag: none;
}

.degraded-visuals .discover-image {
  filter: blur(8px) grayscale(60%) contrast(1.4);
}

.degraded-visuals:hover .discover-image {
  filter: blur(0px) grayscale(0%) contrast(1);
  transition: filter 0.2s ease;
}

.discover-placeholder {
  min-height: 250px;
  display: grid;
  place-items: center;
  color: var(--text-muted);
  background: var(--bg-surface-2);
}

.discover-overlay {
  position: absolute;
  inset: 0;
  display: flex;
  align-items: end;
  background: linear-gradient(180deg, rgba(0, 0, 0, 0.02) 30%, rgba(0, 0, 0, 0.8) 100%);
  opacity: 0;
  transition: opacity 0.25s ease;
  pointer-events: none;
}

.discover-card:hover .discover-overlay {
  opacity: 1;
}

.discover-overlay-inner {
  width: 100%;
  padding: 20px;
}

.stamp-ref.dark-ref {
  color: #ffffff;
  font-size: 10px;
  font-weight: 800;
  letter-spacing: 0.12em;
  text-transform: uppercase;
}

.discover-title {
  margin: 4px 0 0;
  color: #ffffff;
  font-weight: 800;
  letter-spacing: -0.02em;
  font-size: 1.15rem;
  line-height: 1.1;
}

.discover-category {
  margin-top: 6px;
  font-size: 10px;
  font-weight: 700;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: #ffffff;
  opacity: 0.84;
}

.heart-btn {
  position: absolute;
  top: 12px;
  right: 12px;
  z-index: 10;
  width: 38px;
  height: 38px;
  border-radius: 50%;
  background: rgba(0,0,0,0.25);
  backdrop-filter: blur(6px);
  -webkit-backdrop-filter: blur(6px);
  border: 1px solid rgba(255,255,255,0.2);
  color: #ffffff;
  display: grid;
  place-items: center;
  cursor: pointer;
  opacity: 0;
  transform: translateY(-5px);
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

.discover-card:hover .heart-btn {
  opacity: 1;
  transform: translateY(0);
}

.heart-btn:hover {
  background: rgba(0,0,0,0.6);
  transform: scale(1.1);
}

.heart-btn.is-liked {
  opacity: 1;
  transform: translateY(0);
  background: #ffffff;
  color: #ef4444;
  border-color: transparent;
  animation: heart-bounce 0.5s cubic-bezier(0.175, 0.885, 0.32, 1.275);
}

@keyframes heart-bounce {
  0% { transform: scale(1); }
  50% { transform: scale(1.35); }
  100% { transform: scale(1); }
}

.btn-3d {
  box-shadow: 0 4px 6px rgba(0,0,0,0.1), inset 0 2px 0 rgba(255,255,255,0.1) !important;
  transition: transform 0.1s ease, box-shadow 0.1s ease;
}
.btn-3d:active {
  transform: translateY(2px);
  box-shadow: 0 1px 2px rgba(0,0,0,0.1), inset 0 1px 0 rgba(255,255,255,0.1) !important;
}

.floating-hearts-container {
  position: absolute;
  bottom: 50%;
  left: 50%;
  pointer-events: none;
  z-index: 100;
  overflow: visible;
}

.particle-heart {
  position: absolute;
  transform: translate(-50%, 0) scale(0);
  opacity: 0;
  animation: floatZigZag var(--duration) ease-out forwards;
  animation-delay: var(--delay);
}

@keyframes floatZigZag {
  0% { transform: translate(-50%, 0) scale(0); opacity: 0; }
  15% { transform: translate(calc(-50% + var(--x1)), -25px) scale(var(--scale)); opacity: 1; }
  40% { transform: translate(calc(-50% + var(--x2)), -50px) scale(calc(var(--scale) * 1.1)); opacity: 0.9; }
  75% { transform: translate(calc(-50% + var(--x3)), -90px) scale(calc(var(--scale) * 0.9)); opacity: 0.5; }
  100% { transform: translate(calc(-50% + var(--x4)), -130px) scale(calc(var(--scale) * 0.5)); opacity: 0; }
}

.fade-enter-active, .fade-leave-active {
  transition: opacity 0.3s ease;
}
.fade-enter-from, .fade-leave-to {
  opacity: 0;
}

/* =========================================================
   PINTEREST MODAL ULTRA PREMIUM (REFATORADO)
========================================================= */
.premium-pinterest-overlay {
  position: fixed; inset: 0; z-index: 9999;
  background: rgba(0, 0, 0, 0.45);
  backdrop-filter: blur(10px); -webkit-backdrop-filter: blur(10px);
  display: flex; flex-direction: column;
}

.close-modal-btn {
  position: fixed; top: 24px; left: 24px; z-index: 10000;
  background: rgba(var(--v-theme-surface), 0.5) !important;
  backdrop-filter: blur(12px);
  color: var(--text-main) !important;
  box-shadow: 0 4px 12px rgba(0,0,0,0.1) !important;
}
.close-modal-btn:hover { background: rgba(var(--v-theme-surface), 0.9) !important; }

.modal-scroll-area {
  height: 100%; overflow-y: auto; overflow-x: hidden;
  display: flex; flex-direction: column;
  -webkit-overflow-scrolling: touch;
}

.focused-hero {
  min-height: 85vh;
  display: flex; flex-direction: column; align-items: center; justify-content: center;
  padding: 60px 20px 40px; /* Reduzido padding inferior */
  flex-shrink: 0;
}

.image-showcase {
  position: relative; max-width: 800px; width: 100%;
  display: flex; flex-direction: column; align-items: center;
}

/* Apenas a imagem sem fundos ao redor */
.focused-img {
  width: auto; max-width: 100%; max-height: 80vh; object-fit: contain;
  border-radius: 28px;
  box-shadow: 0 20px 60px rgba(0,0,0,0.3);
  display: block;
}

/* Floating Action Bar (Apenas Informações e Favorito) */
.floating-action-bar {
  position: absolute; bottom: -28px;
  background: rgba(var(--v-theme-surface), 0.85);
  backdrop-filter: blur(16px); -webkit-backdrop-filter: blur(16px);
  border: 1px solid var(--border-color);
  border-radius: 999px;
  padding: 8px 12px 8px 24px;
  display: flex; align-items: center; justify-content: space-between; gap: 32px;
  box-shadow: 0 16px 40px rgba(0,0,0,0.15);
  width: max-content; max-width: 95%;
  z-index: 10;
}

.fab-info { display: flex; flex-direction: column; max-width: 250px; }
.fab-ref { font-size: 10px; font-weight: 800; color: var(--text-muted); letter-spacing: 0.1em; }
.fab-title { font-size: 15px; font-weight: 800; color: var(--text-main); }

.fab-actions { display: flex; align-items: center; gap: 8px; flex-shrink: 0; }

.fab-btn {
  position: relative;
  width: 44px; height: 44px; border-radius: 50%;
  display: flex; align-items: center; justify-content: center;
  cursor: pointer; transition: all 0.2s ease;
  background: var(--bg-surface-2); color: var(--text-main);
  border: 1px solid var(--border-color);
}
.fab-btn:hover { background: var(--bg-surface); transform: scale(1.05); }

.fab-btn.heart.liked {
  background: #fff; color: #ef4444; border-color: transparent;
  animation: heart-bounce 0.5s cubic-bezier(0.175, 0.885, 0.32, 1.275);
  box-shadow: 0 4px 12px rgba(239, 68, 68, 0.2);
}

/* Botão Premium (Abaixo do Destaque) */
.premium-view-btn {
  background-color: #a14b12;
  color: #ffffff;
  border: none;
  padding: 10px 24px;
  border-radius: 999px;
  font-size: 13px;
  font-weight: 500;
  letter-spacing: 0.05em;
  display: inline-flex;
  align-items: center;
  gap: 8px;
  cursor: pointer;
  transition: all 0.3s ease;
  box-shadow: 0 8px 20px rgba(161, 75, 18, 0.3);
  z-index: 10;
}

.premium-view-btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 12px 24px rgba(161, 75, 18, 0.4);
  background-color: #8c400f;
}

/* Seção Inferior (Cascata de Semelhantes) */
.similar-full-width {
  background: rgba(var(--v-theme-surface), 0.65);
  backdrop-filter: blur(32px); -webkit-backdrop-filter: blur(32px);
  border-top: 1px solid rgba(var(--v-theme-on-surface), 0.1);
  width: 100%; flex-grow: 1;
  border-top-left-radius: 48px; border-top-right-radius: 48px;
  box-shadow: 0 -20px 60px rgba(0,0,0,0.1);
  padding: 60px 24px 80px;
  position: relative; z-index: 2;
}

.similar-content { max-width: 1600px; margin: 0 auto; }
.similar-title {
  font-weight: 300 !important;
  font-size: 1.6rem;
  letter-spacing: 0.04em;
}


/* =========================================================
   MODAL DE PASTA (PREMIUM BOTTOM SHEET) - Z-INDEX SUPERIOR
========================================================= */
:deep(.premium-folder-dialog) {
  align-items: flex-end;
}
@media (min-width: 768px) {
  :deep(.premium-folder-dialog) { align-items: center; }
}

.premium-folder-card {
  background: rgba(var(--v-theme-surface), 0.95) !important;
  backdrop-filter: blur(24px) !important; -webkit-backdrop-filter: blur(24px) !important;
  border: 1px solid var(--border-color) !important;
  border-radius: 32px !important;
  box-shadow: 0 30px 60px rgba(0,0,0,0.2) !important;
}

.folder-option-card {
  background: var(--bg-surface-2) !important;
  border: 1px solid var(--border-color) !important;
  transition: all 0.2s ease;
}
.folder-option-card:hover {
  background: var(--bg-surface) !important;
  border-color: rgba(var(--v-theme-primary), 0.3) !important;
  transform: translateX(4px);
}

.save-btn { opacity: 0; transform: translateX(-10px); transition: all 0.2s ease; }
.folder-option-card:hover .save-btn { opacity: 1; transform: translateX(0); }

.create-folder-btn { background: rgba(var(--v-theme-primary), 0.05); border-color: rgba(var(--v-theme-primary), 0.3) !important; }
.create-folder-btn:hover { background: rgba(var(--v-theme-primary), 0.1); }

.gold-gradient-icon { background: linear-gradient(135deg, #d4af37, #f3e5ab, #d4af37); -webkit-background-clip: text; -webkit-text-fill-color: transparent; filter: drop-shadow(0 2px 4px rgba(212, 175, 55, 0.3)); }

/* =========================================================
   GLASSMORPHISM - AVISO DE PLÁGIO
========================================================= */
.copyright-warning-overlay {
  position: fixed; inset: 0; z-index: 99999;
  display: flex; align-items: center; justify-content: center;
  background: rgba(0, 0, 0, 0.4); backdrop-filter: blur(8px); -webkit-backdrop-filter: blur(8px);
  padding: 24px;
}

.copyright-warning-card {
  width: 100%; max-width: 420px;
  background: rgba(24, 24, 27, 0.85); backdrop-filter: blur(20px); -webkit-backdrop-filter: blur(20px);
  border-radius: 24px; padding: 32px; text-align: center;
  box-shadow: 0 25px 50px rgba(0,0,0,0.5), inset 0 1px 0 rgba(255,255,255,0.1);
}

.warning-icon-wrap { width: 72px; height: 72px; margin: 0 auto 20px; border-radius: 50%; background: rgba(239, 68, 68, 0.15); display: flex; align-items: center; justify-content: center; }
.warning-title { color: #fff; font-size: 1.5rem; font-weight: 800; letter-spacing: -0.02em; margin-bottom: 12px; }
.warning-desc { color: rgba(255, 255, 255, 0.7); font-size: 0.95rem; line-height: 1.5; margin-bottom: 24px; }
.strike-indicator { display: flex; justify-content: center; gap: 12px; margin-bottom: 16px; }
.strike-dot { width: 45px; height: 6px; border-radius: 3px; background: rgba(255, 255, 255, 0.15); transition: background-color 0.4s ease; }
.strike-dot.filled-error { background: #ef4444; box-shadow: 0 0 12px rgba(239, 68, 68, 0.4); }
.strike-text { font-size: 0.85rem; color: rgba(255, 255, 255, 0.5); margin: 0; }

@media (max-width: 959px) {
  .view-wrap { padding-top: 0; padding-bottom: 96px; }
  .discover-view { min-height: 100vh; }

  .focused-hero { min-height: 50vh; padding: 70px 16px 40px; }
  .focused-img { max-height: 60vh; }

  .floating-action-bar { bottom: -20px; gap: 16px; padding: 8px 12px 8px 20px; }
  .fab-info { max-width: 180px; }
  .fab-title { font-size: 13px; }

  .similar-full-width { padding: 40px 16px; border-top-left-radius: 32px; border-top-right-radius: 32px; }
  .close-modal-btn { top: 12px; left: 12px; }
}

@media (max-width: 767px) {
  .fluid-container { padding-left: 12px; padding-right: 12px; }
  .masonry-layout-real { gap: 8px; }
  .masonry-col { gap: 8px; }
  .discover-card { border-radius: 12px; }
  .discover-card-inner { border-radius: 10px; }

  .heart-btn { opacity: 1 !important; transform: translateY(0) !important; background: rgba(0,0,0,0.45); width: 26px; height: 26px; top: 6px; right: 6px; border-color: transparent; }
  .heart-btn .v-icon { font-size: 14px !important; }
  .heart-btn.is-liked { background: #ffffff; }

  .discover-overlay-inner { padding: 8px; }
  .discover-title { font-size: 0.75rem; line-height: 1.1; }
  .discover-category { font-size: 8px; margin-top: 2px; }
  .discover-top-inner { width: min(100%, calc(100% - 24px)); }

  .save-btn { opacity: 1; transform: none; }

  .fab-info { max-width: 140px; }
  .focused-img { border-radius: 20px; }
  .similar-title { font-size: 1.2rem; }
}
</style>
