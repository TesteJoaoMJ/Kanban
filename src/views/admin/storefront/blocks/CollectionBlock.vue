<template>
  <div v-if="mode === 'settings'" class="premium-collection-settings d-flex flex-column gap-6">

    <div class="mac-card">
      <div class="mac-card-header d-flex justify-space-between align-center border-b">
        <div class="d-flex align-center gap-2">
          <div class="icon-chip bg-primary text-white"><v-icon size="14">mdi-database-search</v-icon></div>
          <span class="fw-700 text-sm text-dark">Curadoria de Estampas</span>
        </div>
      </div>

      <div class="mac-card-body d-flex flex-column gap-4 bg-lightest">
        <div class="d-flex flex-column gap-3 p-4 bg-white border rounded-md shadow-xs relative">
          <div class="section-badge bg-blue text-blue">Origem</div>

          <div class="mt-2">
            <label class="premium-label">Modo de Seleção</label>
            <select v-model="block.settings.selection_type" class="premium-input">
              <option value="auto">Automático (Por Pasta)</option>
              <option value="manual">Manual (Escolha a Dedo)</option>
            </select>
          </div>

          <template v-if="block.settings.selection_type === 'auto' || !block.settings.selection_type">
            <div class="d-flex gap-3">
              <div class="flex-grow-1">
                <label class="premium-label">Pasta Origem</label>
                <select v-model="block.settings.category_id" class="premium-input">
                  <option value="all">Lançamentos Gerais</option>
                  <option v-for="cat in categories" :key="cat.id" :value="cat.id">{{ cat.name }}</option>
                </select>
              </div>
              <div style="width: 80px;">
                <label class="premium-label">Limite</label>
                <input type="number" v-model.number="block.settings.limit" min="4" max="40" class="premium-input text-center" />
              </div>
            </div>
          </template>

          <template v-else>
            <div class="vuetify-override-container mt-1">
              <label class="premium-label">Buscar Estampas</label>
              <v-autocomplete
                v-model="block.settings.selected_stamps"
                :items="stamps"
                item-title="title"
                item-value="id"
                group-by="category_name"
                multiple chips closable-chips
                variant="outlined" density="compact" hide-details
                class="premium-autocomplete">
                <template v-slot:item="{ props, item }">
                  <v-list-item v-bind="props" :title="item.raw.title" :subtitle="item.raw.ref_code">
                    <template v-slot:prepend>
                      <v-avatar rounded="lg" size="32" class="mr-3 border bg-grey-lighten-4">
                        <v-img :src="item.raw.main_image_url" cover></v-img>
                      </v-avatar>
                    </template>
                  </v-list-item>
                </template>
              </v-autocomplete>
            </div>
          </template>
        </div>
      </div>
    </div>

    <div class="mac-card">
      <div class="mac-card-header d-flex align-center gap-2 border-b">
        <div class="icon-chip bg-purple text-white"><v-icon size="14">mdi-eye-outline</v-icon></div>
        <span class="fw-700 text-sm text-dark">Conteúdo e Exibição</span>
      </div>

      <div class="mac-card-body d-flex flex-column gap-4 bg-lightest">
        <div class="p-4 bg-white border rounded-md shadow-xs">
          <div class="mb-4">
            <label class="premium-label">Título da Seção</label>
            <input type="text" v-model="block.settings.title" class="premium-input" placeholder="Ex: Nossos Lançamentos" />
          </div>

          <div class="d-flex gap-3">
             <div class="flex-1">
               <label class="premium-label">Texto do Link</label>
               <input type="text" v-model="block.settings.button_text" class="premium-input" placeholder="Ex: Ver Tudo" />
             </div>
             <div class="flex-1">
               <label class="premium-label">URL do Link</label>
               <input type="text" v-model="block.settings.button_link" class="premium-input" placeholder="/marketplace/descobrir" />
             </div>
          </div>
        </div>

        <div class="d-flex align-center justify-space-between p-4 bg-white border rounded-md shadow-xs">
          <div class="d-flex flex-column">
            <span class="text-sm fw-700 text-dark">Exibir Preços?</span>
            <span class="text-xs text-muted">Mostra o valor digital da estampa nos cards</span>
          </div>
          <label class="ios-switch">
            <input type="checkbox" v-model="block.settings.show_prices">
            <span class="ios-slider"></span>
          </label>
        </div>
      </div>
    </div>

    <div class="mac-card">
      <div class="mac-card-header d-flex align-center gap-2 border-b">
        <div class="icon-chip bg-green text-white"><v-icon size="14">mdi-palette-outline</v-icon></div>
        <span class="fw-700 text-sm text-dark">Estilo e Cores</span>
      </div>

      <div class="mac-card-body d-flex flex-column gap-3 bg-lightest">

        <div>
          <label class="premium-label">Fonte da Seção</label>
          <select v-model="block.settings.font_family" class="premium-input">
            <option value="'Inter', sans-serif">Inter (Moderno)</option>
            <option value="'Montserrat', sans-serif">Montserrat (Geométrico)</option>
            <option value="'Playfair Display', serif">Playfair Display (Elegante)</option>
            <option value="'Bebas Neue', sans-serif">Bebas Neue (Impacto)</option>
          </select>
        </div>

        <div class="d-flex gap-3 mt-2">
          <div class="flex-1">
            <label class="premium-label">Cor de Fundo da Seção</label>
            <div class="color-input-wrapper">
              <input type="color" v-model="block.settings.bg_color" class="color-swatch-sm" />
              <input type="text" v-model="block.settings.bg_color" class="color-hex-input" placeholder="#FFFFFF" />
            </div>
          </div>

          <div class="flex-1">
            <label class="premium-label">Cor dos Textos</label>
            <div class="color-input-wrapper">
              <input type="color" v-model="block.settings.text_color" class="color-swatch-sm" />
              <input type="text" v-model="block.settings.text_color" class="color-hex-input" placeholder="#000000" />
            </div>
          </div>
        </div>

        <div class="mt-2">
          <label class="premium-label">Estilo dos Cards</label>
          <select v-model="block.settings.card_style" class="premium-input">
            <option value="standard">Padrão (Bordas Leves)</option>
            <option value="minimalist">Minimalista (Sem Borda)</option>
            <option value="elevated">Elevado (Sombra Apple)</option>
          </select>
        </div>

      </div>
    </div>

  </div>

  <section v-else
           :id="`block-preview-${block._id}`"
           class="pb-sections preview-engine"
           :class="[{ 'active-outline': isActive }]"
           :style="{
             backgroundColor: block.settings.bg_color || 'transparent',
             fontFamily: block.settings.font_family || `'Inter', sans-serif`
           }">

    <div class="pb-container">
      <div class="pb-showcase">

        <div class="pb-section-header" :style="{ borderColor: block.settings.text_color ? `${block.settings.text_color}33` : '' }">
          <h2 class="pb-section-title" :style="{ color: block.settings.text_color || '' }">
            {{ block.settings.title || 'Vitrine de Estampas' }}
          </h2>
          <button v-if="block.settings.button_text" class="pb-btn-link" :style="{ color: block.settings.text_color || '' }" @click="goToLink(block.settings.button_link)">
            {{ block.settings.button_text }} <v-icon size="16" class="ml-1 pb-icon-arrow">mdi-arrow-right</v-icon>
          </button>
        </div>

        <div v-if="computedItems.length === 0" class="empty-state-container text-center py-16">
          <v-icon size="64" class="mb-4 opacity-20">mdi-hanger</v-icon>
          <h3 class="text-h6 font-weight-bold opacity-40">Nenhuma estampa selecionada</h3>
        </div>

        <div v-else class="pb-grid">
          <article
            v-for="(stamp, idx) in computedItems"
            :key="stamp.id || idx"
            class="pb-card"
            :class="[
               { 'is-wishlisted': isInWishlist(stamp.id) },
               `style-${block.settings.card_style || 'standard'}`
            ]"
            @click="goToProduct(stamp)"
          >
            <div class="pb-card-media mj-surface mj-border">
              <img class="pb-card-img" :src="utils.getOptimizedUrl(stamp.main_image_url, 800)" loading="lazy" :alt="stamp.title" @error="handleImageError" />

              <div class="pb-card-actions-overlay d-none d-md-flex">
                <div class="pb-actions-bar border">
                  <button class="pb-action-btn pb-wishlist-btn" @click.stop="handleWishlistClick(stamp, $event)">
                    <v-icon size="18" :color="isInWishlist(stamp.id) ? 'error' : ''">
                      {{ isInWishlist(stamp.id) ? 'mdi-heart' : 'mdi-heart-outline' }}
                    </v-icon>
                    <div class="floating-hearts-container">
                      <v-icon v-for="heart in activeHearts[stamp.id]" :key="heart.id" class="particle-heart text-error" :style="heart.style" size="14">mdi-heart</v-icon>
                    </div>
                  </button>

                  <div class="pb-actions-divider"></div>
                  <button class="pb-action-btn pb-quickview-text flex-grow-1">Visualizar</button>

                  <div class="pb-actions-divider"></div>
                  <button class="pb-action-btn pb-cart-btn" :class="{ 'is-active': isInCart(stamp.id) }" @click.stop="handleCartClick(stamp)">
                    <v-icon size="18" :color="isInCart(stamp.id) ? 'primary' : ''">{{ isInCart(stamp.id) ? 'mdi-shopping' : 'mdi-shopping-outline' }}</v-icon>
                    <span class="pb-cart-fill bg-primary" :class="{'is-filling': animatingCart === stamp.id}"></span>
                  </button>
                </div>
              </div>

              <div class="pb-mobile-actions d-md-none">
                 <button class="pb-mobile-opt-btn mj-surface mj-border" :class="{ 'text-error border-error': isInWishlist(stamp.id) }" @click.stop="handleWishlistClick(stamp, $event)">
                   <v-icon size="16">{{ isInWishlist(stamp.id) ? 'mdi-heart' : 'mdi-heart-outline' }}</v-icon>
                 </button>
              </div>
            </div>

            <div class="pb-card-info">
              <div class="pb-card-meta">
                <span class="pb-ref" :style="{ color: block.settings.text_color ? `${block.settings.text_color}99` : '' }">{{ stamp.ref_code || 'S/REF' }}</span>
                <span v-if="block.settings.show_prices !== false && stamp.digital_price" class="pb-price" :style="{ color: block.settings.text_color || '' }">
                  R$ {{ formatPrice(stamp.digital_price) }}
                </span>
              </div>
              <h3 class="pb-title" :style="{ color: block.settings.text_color || '' }">{{ stamp.title || 'Nova Estampa' }}</h3>
              <span class="pb-category" :style="{ color: block.settings.text_color ? `${block.settings.text_color}80` : '' }">
                {{ utils.getCategoryName(stamp.category_id) || 'Premium' }}
              </span>
            </div>
          </article>
        </div>

      </div>
    </div>
  </section>
</template>

<script setup lang="ts">
import { ref, computed, inject, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useMarketplaceCartStore } from '@/stores/marketplaceCart'
import { useMarketplaceUserStore } from '@/stores/marketplaceUser'

const props = defineProps<{
  mode: 'settings' | 'preview'
  block: any
  isActive?: boolean
  categories: any[]
  stamps: any[]
}>()

const utils = inject<any>('builderUtils')
const router = useRouter()

const cartStore = props.mode === 'preview' ? useMarketplaceCartStore() : null
const userStore = props.mode === 'preview' ? useMarketplaceUserStore() : null

// INIT DEFAULT SETTINGS
onMounted(() => {
  if (props.mode === 'settings') {
    if (props.block.settings.selection_type === undefined) props.block.settings.selection_type = 'auto'
    if (props.block.settings.limit === undefined) props.block.settings.limit = 8
    if (props.block.settings.show_prices === undefined) props.block.settings.show_prices = true
    if (props.block.settings.card_style === undefined) props.block.settings.card_style = 'standard'
    if (props.block.settings.font_family === undefined) props.block.settings.font_family = "'Inter', sans-serif"
    if (props.block.settings.bg_color === undefined) props.block.settings.bg_color = '#ffffff'
    if (props.block.settings.text_color === undefined) props.block.settings.text_color = '#000000'
  }
})

const computedItems = computed(() => {
  if (!props.block || !props.stamps) return []
  const type = props.block.settings.selection_type || 'auto'
  if (type === 'manual') {
    const ids = props.block.settings.selected_stamps || []
    return ids.map((id: string) => props.stamps.find(s => s.id === id)).filter(Boolean)
  } else {
    const catId = props.block.settings.category_id || 'all'
    const limit = props.block.settings.limit || 8
    let list = [...props.stamps]
    if (catId && catId !== 'all') list = list.filter(s => s.category_id === catId)
    return list.slice(0, limit)
  }
})

// === LÓGICA DO CARRINHO E WISHLIST ===
const animatingCart = ref<string | null>(null)
const activeHearts = ref<Record<string, any[]>>({})
let heartIdCounter = 0

const isInCart = (id: string) => cartStore?.items?.some((i: any) => i.stampId === id && i.type === 'psd') || false
const isInWishlist = (id: string) => userStore?.wishlist?.includes(id) || false

function handleCartClick(stamp: any) {
  if (props.mode === 'settings' || !cartStore) return
  if (isInCart(stamp.id)) {
    const cartItem = cartStore.items.find(i => i.stampId === stamp.id && i.type === 'psd')
    if (cartItem) cartStore.removeItem(cartItem.id)
  } else {
    cartStore.addPsdToCart(stamp, stamp.digital_price || 59.90)
    animatingCart.value = stamp.id
    setTimeout(() => { animatingCart.value = null }, 600)
  }
}

async function handleWishlistClick(stamp: any, event: Event) {
  if (props.mode === 'settings' || !userStore) return
  if (!userStore.isAuthenticated) return alert('Faça login para salvar favoritos.')

  const isAdding = !isInWishlist(stamp.id)
  if (isAdding) {
    if (!activeHearts.value[stamp.id]) activeHearts.value[stamp.id] = []
    const newHearts = Array.from({ length: 5 }).map(() => ({
      id: heartIdCounter++,
      style: {
        '--x1': (Math.random() - 0.5) * 30 + 'px', '--x2': (Math.random() - 0.5) * 60 + 'px',
        '--x3': (Math.random() - 0.5) * 40 + 'px', '--x4': (Math.random() - 0.5) * 80 + 'px',
        '--scale': 0.6 + Math.random() * 0.8, '--duration': 1.0 + Math.random() * 0.8 + 's', '--delay': Math.random() * 0.3 + 's'
      }
    }))
    activeHearts.value[stamp.id].push(...newHearts)
    setTimeout(() => { activeHearts.value[stamp.id] = [] }, 2500)
  }
  await userStore.toggleWishlist(stamp.id)
}

function handleImageError(e: Event) { (e.target as HTMLImageElement).src = '/placeholder.png' }
function formatPrice(v: number) { return Number(v || 0).toLocaleString('pt-BR', { minimumFractionDigits: 2 }) }
function goToProduct(s: any) { if (props.mode === 'preview') router.push(`/marketplace/produto/${s.id}`) }
function goToLink(l: string) { if (props.mode === 'preview' && l) router.push(l) }
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Bebas+Neue&family=Inter:wght@400;500;600;700;800&family=Montserrat:wght@400;700;900&family=Playfair+Display:ital,wght@0,400;0,700;0,900;1,400&display=swap');

/* UI SETTINGS (Igual HeroBlock) */
.premium-collection-settings { font-family: 'Inter', sans-serif; }
.fw-600 { font-weight: 600; }
.fw-700 { font-weight: 700; }
.text-xs { font-size: 11px; }
.text-sm { font-size: 13px; }
.text-dark { color: #0f172a; }
.text-muted { color: #64748b; }
.text-blue { color: #2563eb; }
.text-purple { color: #7c3aed; }
.text-green { color: #16a34a; }
.bg-blue { background: rgba(59, 130, 246, 0.1); }
.bg-purple { background: rgba(124, 58, 237, 0.1); }
.bg-green { background: rgba(22, 163, 74, 0.1); }
.bg-lightest { background: #f8fafc; }

.mac-card { background: #ffffff; border: 1px solid #e2e8f0; border-radius: 12px; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.02); overflow: hidden; }
.mac-card-header { padding: 14px 16px; }
.mac-card-body { padding: 16px; }
.icon-chip { width: 24px; height: 24px; border-radius: 6px; display: flex; align-items: center; justify-content: center; }
.section-badge { position: absolute; top: -10px; left: 12px; font-size: 10px; font-weight: 800; text-transform: uppercase; padding: 2px 8px; border-radius: 12px; letter-spacing: 0.05em; border: 1px solid rgba(0,0,0,0.05); }

.premium-label { display: block; font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.05em; color: #64748b; margin-bottom: 6px; }
.premium-input { width: 100%; height: 36px; padding: 0 12px; font-size: 13px; font-weight: 500; color: #1e293b; background: #ffffff; border: 1px solid #cbd5e1; border-radius: 8px; outline: none; transition: all 0.2s ease; }
.premium-input:focus { border-color: #3b82f6; box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.15); }

/* Switch iOS */
.ios-switch { position: relative; display: inline-block; width: 40px; height: 22px; }
.ios-switch input { opacity: 0; width: 0; height: 0; }
.ios-slider { position: absolute; cursor: pointer; inset: 0; background-color: #cbd5e1; transition: .3s; border-radius: 22px; }
.ios-slider:before { position: absolute; content: ""; height: 18px; width: 18px; left: 2px; bottom: 2px; background-color: white; transition: .3s; border-radius: 50%; box-shadow: 0 2px 4px rgba(0,0,0,0.2); }
input:checked + .ios-slider { background-color: #3b82f6; }
input:checked + .ios-slider:before { transform: translateX(18px); }

/* WRAPPER PARA O COLOR PICKER (PADRÃO ZIGZAG) */
.color-input-wrapper { display: flex; align-items: center; gap: 8px; height: 36px; padding: 0 8px; background: #ffffff; border: 1px solid #cbd5e1; border-radius: 8px; box-shadow: inset 0 1px 2px rgba(0,0,0,0.02); transition: all 0.2s ease; }
.color-input-wrapper:focus-within { border-color: #3b82f6; box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.15); }
.color-swatch-sm { -webkit-appearance: none; appearance: none; width: 20px; height: 20px; border: 1px solid #e2e8f0; border-radius: 4px; padding: 0; cursor: pointer; background: transparent; }
.color-swatch-sm::-webkit-color-swatch-wrapper { padding: 0; }
.color-swatch-sm::-webkit-color-swatch { border: none; border-radius: 3px; }
.color-hex-input { border: none; outline: none; background: transparent; font-size: 13px; font-weight: 500; color: #1e293b; width: 100%; text-transform: uppercase; }

/* VUETIFY OVERRIDES */
.vuetify-override-container :deep(.v-field) { border-radius: 8px !important; border: 1px solid #cbd5e1 !important; background: white !important; }
.vuetify-override-container :deep(.v-field__outline) { display: none !important; }
.vuetify-override-container :deep(.v-field__input) { min-height: 36px !important; padding-top: 0 !important; padding-bottom: 0 !important; font-size: 13px !important; font-weight: 500 !important; }

/* PREVIEW ENGINE */
.preview-engine { transition: background-color 0.3s ease; outline: 2px solid transparent; outline-offset: -2px; }
.preview-engine:hover { outline-color: rgba(var(--v-theme-primary), 0.3); }
.active-outline { outline-color: rgb(var(--v-theme-primary)) !important; box-shadow: inset 0 0 0 4px rgba(var(--v-theme-primary), 0.1); position: relative; z-index: 10; }

button { font-family: inherit; cursor: pointer; border: none; outline: none; background: transparent; transition: all 0.2s ease; }

.pb-sections { padding: clamp(40px, 6vw, 100px) 0; }
.pb-container { max-width: 1700px; padding: 0 clamp(16px, 4vw, 56px); margin: 0 auto; width: 100%; }
.pb-section-header { display: flex; justify-content: space-between; align-items: flex-end; margin-bottom: clamp(24px, 4vw, 48px); padding-bottom: 16px; border-bottom: 1px solid rgba(0,0,0,0.05); transition: border-color 0.3s ease; }
.pb-section-title { font-size: clamp(1.6rem, 3.5vw, 2.8rem); font-weight: 900; letter-spacing: -0.02em; margin: 0; transition: color 0.3s ease; }
.pb-btn-link { font-size: 13px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.05em; display: inline-flex; align-items: center; border-bottom: 1px solid transparent; transition: color 0.3s ease; }
.pb-btn-link:hover { border-color: currentColor; }

/* Grid Estampas */
.pb-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 32px 24px; }
@media (max-width: 1200px) { .pb-grid { grid-template-columns: repeat(3, 1fr); } }
@media (max-width: 850px) { .pb-grid { grid-template-columns: repeat(2, 1fr); } }

/* Cards Style: Standard */
.pb-card { display: flex; flex-direction: column; cursor: pointer; }
.pb-card-media { position: relative; aspect-ratio: 1/1; overflow: hidden; margin-bottom: 16px; background: #f8f8f8; transition: all 0.5s cubic-bezier(0.16, 1, 0.3, 1); }
.pb-card-img { width: 100%; height: 100%; object-fit: cover; transition: transform 1s ease; }
.pb-card:hover .pb-card-img { transform: scale(1.08); }

.style-standard .pb-card-media { border-radius: 8px; border: 1px solid rgba(0,0,0,0.04); }
.style-standard:hover .pb-card-media { box-shadow: 0 12px 30px rgba(0,0,0,0.1); transform: translateY(-4px); }

/* Card Style: Minimalist */
.style-minimalist .pb-card-media { border-radius: 0; border: none; }
.style-minimalist .pb-title { font-size: 14px; text-transform: uppercase; letter-spacing: 0.02em; }

/* Card Style: Elevated (Apple Style) */
.style-elevated .pb-card-media { border-radius: 20px; border: 1px solid rgba(0,0,0,0.02); box-shadow: 0 10px 20px rgba(0,0,0,0.04); }
.style-elevated:hover .pb-card-media { box-shadow: 0 30px 60px rgba(0,0,0,0.12); transform: translateY(-8px) scale(1.02); }

/* Overlay e Ações */
.pb-card-actions-overlay { position: absolute; inset: 0; background: rgba(0,0,0,0.05); align-items: flex-end; justify-content: center; padding: 20px; opacity: 0; transition: opacity 0.3s ease; }
.pb-card:hover .pb-card-actions-overlay { opacity: 1; }
.pb-actions-bar { background: rgba(255,255,255,0.9); backdrop-filter: blur(10px); border-radius: 40px; display: flex; align-items: center; width: 100%; height: 48px; transform: translateY(10px); transition: transform 0.4s ease; }
.pb-card:hover .pb-actions-bar { transform: translateY(0); }
.pb-action-btn { width: 48px; height: 48px; display: flex; align-items: center; justify-content: center; border-radius: 50%; color: #000; }
.pb-quickview-text { font-size: 11px; font-weight: 800; text-transform: uppercase; letter-spacing: 0.1em; }

/* Info Text */
.pb-card-info { display: flex; flex-direction: column; transition: color 0.3s ease; }
.pb-card-meta { display: flex; justify-content: space-between; align-items: center; margin-bottom: 4px; }
.pb-ref { font-family: monospace; font-size: 11px; font-weight: 700; opacity: 0.6; transition: color 0.3s ease; }
.pb-price { font-size: 13px; font-weight: 900; transition: color 0.3s ease; }
.pb-title { font-size: 15px; font-weight: 700; line-height: 1.3; margin: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; transition: color 0.3s ease; }
.pb-category { font-size: 11px; font-weight: 600; text-transform: uppercase; letter-spacing: 0.05em; opacity: 0.5; transition: color 0.3s ease; }

/* Animações Hearts */
.pb-card.is-wishlisted .pb-card-media { box-shadow: 0 0 0 2px #ef4444 !important; border-color: transparent !important; }
.particle-heart { position: absolute; left: 50%; bottom: 50%; transform: translate(-50%, 0) scale(0); opacity: 0; animation: floatZigZag var(--duration) ease-out forwards; animation-delay: var(--delay); pointer-events: none; }
@keyframes floatZigZag {
  0% { transform: translate(-50%, 0) scale(0); opacity: 0; }
  15% { transform: translate(calc(-50% + var(--x1)), -30px) scale(var(--scale)); opacity: 1; }
  100% { transform: translate(calc(-50% + var(--x4)), -140px) scale(calc(var(--scale) * 0.5)); opacity: 0; }
}

.pb-mobile-actions { position: absolute; top: 12px; right: 12px; z-index: 5; }
.pb-mobile-opt-btn { background: var(--bg-surface); border: 1px solid var(--border-color); border-radius: 50%; width: 36px; height: 36px; display: flex; align-items: center; justify-content: center; box-shadow: 0 4px 12px rgba(0,0,0,0.15); }
.pb-mobile-opt-btn.text-error { color: #ef4444 !important; border-color: #ef4444 !important;}
</style>
