<template>
  <div class="shopify-builder-shell d-flex flex-column bg-background w-100" style="height: calc(100vh - 120px);">

    <header class="builder-topbar bg-surface border-b px-4 py-3 d-flex align-center justify-space-between flex-shrink-0 z-10 shadow-sm w-100">
      <div class="d-flex align-center gap-4">
        <div class="bg-indigo-lighten-5 p-2 rounded-lg text-indigo d-flex align-center justify-center border border-indigo">
          <v-icon size="20">mdi-view-quilt</v-icon>
        </div>
        <div>
          <h2 class="text-subtitle-1 font-weight-black lh-1 m-0 text-high-emphasis">Page Builder</h2>
          <span class="text-[10px] text-medium-emphasis text-uppercase font-weight-bold tracking-widest">Edição da Home Pública</span>
        </div>
      </div>

      <div class="viewport-controls bg-background border rounded-lg p-1 d-flex gap-1">
        <button class="vp-btn" :class="{ 'active': viewport === 'desktop' }" @click="viewport = 'desktop'" title="Visualização Desktop">
          <v-icon size="18">mdi-monitor</v-icon>
        </button>
        <button class="vp-btn" :class="{ 'active': viewport === 'mobile' }" @click="viewport = 'mobile'" title="Visualização Mobile">
          <v-icon size="18">mdi-cellphone</v-icon>
        </button>
      </div>

      <div class="d-flex gap-3">
        <v-btn variant="outlined" color="error" class="text-none font-weight-bold rounded-lg" size="small" @click="loadLayoutData" :disabled="isSaving">
          Descartar Alterações
        </v-btn>
        <v-btn color="primary" class="text-none font-weight-bold rounded-lg shadow-soft" size="small" :loading="isSaving" @click="handleAction" prepend-icon="mdi-content-save">
          Salvar Layout
        </v-btn>
      </div>
    </header>

    <div class="d-flex flex-grow-1 overflow-hidden position-relative w-100">

      <aside class="builder-inspector bg-surface border-e d-flex flex-column flex-shrink-0 shadow-lg h-100" style="width: 500px; min-width: 500px; z-index: 5;">

        <div v-if="!activeBlock" class="d-flex flex-column h-100 overflow-hidden">
          <div class="pa-4 border-b bg-background flex-shrink-0">
            <h3 class="text-subtitle-2 font-weight-bold m-0 text-high-emphasis">Seções da Página</h3>
            <p class="text-[10px] text-medium-emphasis m-0 mt-1">Arraste para reordenar ou clique para editar.</p>
          </div>

          <div class="flex-grow-1 overflow-y-auto custom-scrollbar pa-3 d-flex flex-column gap-2" id="inspector-scroll-area">
            <div class="block-list-item static opacity-70">
              <v-icon size="18" class="mr-3">mdi-page-layout-header</v-icon>
              <span class="text-body-2 font-weight-bold flex-grow-1">Cabeçalho (Global)</span>
              <v-icon size="14">mdi-lock-outline</v-icon>
            </div>

            <transition-group name="list-anim">
              <div v-for="(block, index) in homeBlocks" :key="block._id"
                   class="block-list-item cursor-pointer enterprise-card bg-surface"
                   @click="selectBlock(block)">
                <v-icon size="18" class="mr-3 text-medium-emphasis">mdi-drag-horizontal-variant</v-icon>
                <div class="d-flex flex-column flex-grow-1 overflow-hidden">
                  <strong class="text-body-2 font-weight-bold text-high-emphasis text-truncate">{{ getBlockTypeName(block.type) }}</strong>
                  <span class="text-[10px] text-medium-emphasis text-truncate">{{ block.settings.title || 'Sem título configurado' }}</span>
                </div>

                <div class="d-flex flex-column gap-1 ml-2" @click.stop>
                  <v-btn icon size="x-small" variant="text" density="compact" :disabled="index === 0" @click="moveBlock(index, -1)"><v-icon size="16">mdi-chevron-up</v-icon></v-btn>
                  <v-btn icon size="x-small" variant="text" density="compact" :disabled="index === homeBlocks.length - 1" @click="moveBlock(index, 1)"><v-icon size="16">mdi-chevron-down</v-icon></v-btn>
                </div>
              </div>
            </transition-group>

            <div v-if="homeBlocks.length === 0" class="text-center py-8 opacity-50">
              <v-icon size="32" class="mb-2">mdi-layers-off-outline</v-icon>
              <div class="text-caption">Nenhum bloco adicionado</div>
            </div>

            <div class="block-list-item static opacity-70 mt-auto">
              <v-icon size="18" class="mr-3">mdi-page-layout-footer</v-icon>
              <span class="text-body-2 font-weight-bold flex-grow-1">Rodapé (Global)</span>
              <v-icon size="14">mdi-lock-outline</v-icon>
            </div>
          </div>

          <div class="pa-4 border-t bg-background flex-shrink-0">
            <v-menu location="top center" :close-on-content-click="true">
              <template v-slot:activator="{ props }">
                <v-btn v-bind="props" color="primary" variant="tonal" block class="text-none font-weight-bold rounded-lg border-dashed border-primary" style="border-width: 1px;">
                  <v-icon start>mdi-plus</v-icon> Adicionar Seção
                </v-btn>
              </template>
              <v-list class="bg-surface rounded-lg border shadow-lg pa-2 custom-scrollbar" width="460" max-height="450">
                <div class="text-caption font-weight-bold text-medium-emphasis px-3 py-2 text-uppercase tracking-widest">Componentes Estruturais</div>

                <v-list-item @click="addBlock('promo_marquee')" class="rounded mb-1 hover-bg-light bg-indigo-lighten-5">
                  <template v-slot:prepend><v-icon color="indigo">mdi-message-text-outline</v-icon></template>
                  <v-list-item-title class="text-body-2 font-weight-bold text-indigo">Faixa Promocional</v-list-item-title>
                  <v-list-item-subtitle class="text-[10px] text-indigo">Texto rotativo de avisos (Topo).</v-list-item-subtitle>
                </v-list-item>

                <v-list-item @click="addBlock('hero')" class="rounded mb-1 hover-bg-light">
                  <template v-slot:prepend><v-icon color="indigo">mdi-image-size-select-actual</v-icon></template>
                  <v-list-item-title class="text-body-2 font-weight-bold">Banner Hero</v-list-item-title>
                  <v-list-item-subtitle class="text-[10px]">Abertura gigante de impacto com CTA.</v-list-item-subtitle>
                </v-list-item>

                <v-list-item @click="addBlock('trust_carousel')" class="rounded mb-1 hover-bg-light">
                  <template v-slot:prepend><v-icon color="teal">mdi-view-carousel-outline</v-icon></template>
                  <v-list-item-title class="text-body-2 font-weight-bold">Marcas Parceiras</v-list-item-title>
                  <v-list-item-subtitle class="text-[10px]">Carrossel infinito de logos (Trust).</v-list-item-subtitle>
                </v-list-item>

                <v-list-item @click="addBlock('dual_banner')" class="rounded mb-1 hover-bg-light">
                  <template v-slot:prepend><v-icon color="deep-purple">mdi-view-split-vertical</v-icon></template>
                  <v-list-item-title class="text-body-2 font-weight-bold">Banners Duplos</v-list-item-title>
                  <v-list-item-subtitle class="text-[10px]">Dois banners de destaque lado a lado.</v-list-item-subtitle>
                </v-list-item>

                <v-list-item @click="addBlock('zigzag_collections')" class="rounded mb-1 hover-bg-light">
                  <template v-slot:prepend><v-icon color="cyan">mdi-vector-polyline</v-icon></template>
                  <v-list-item-title class="text-body-2 font-weight-bold">Coleções Dinâmicas</v-list-item-title>
                  <v-list-item-subtitle class="text-[10px]">Zigue-Zague, Grid ou Listas Editoriais.</v-list-item-subtitle>
                </v-list-item>

                <v-list-item @click="addBlock('text_with_image')" class="rounded mb-1 hover-bg-light">
                  <template v-slot:prepend><v-icon color="light-blue">mdi-card-text-outline</v-icon></template>
                  <v-list-item-title class="text-body-2 font-weight-bold">Texto com Imagem</v-list-item-title>
                  <v-list-item-subtitle class="text-[10px]">Bloco lado a lado de conteúdo.</v-list-item-subtitle>
                </v-list-item>

                <v-list-item @click="addBlock('collection')" class="rounded mb-1 hover-bg-light">
                  <template v-slot:prepend><v-icon color="teal">mdi-view-grid-outline</v-icon></template>
                  <v-list-item-title class="text-body-2 font-weight-bold">Vitrine de Estampas</v-list-item-title>
                  <v-list-item-subtitle class="text-[10px]">Catálogo dinâmico, grid ou slider.</v-list-item-subtitle>
                </v-list-item>

                <v-list-item @click="addBlock('mockup_grid')" class="rounded mb-1 hover-bg-light">
                  <template v-slot:prepend><v-icon color="pink">mdi-tshirt-crew-outline</v-icon></template>
                  <v-list-item-title class="text-body-2 font-weight-bold">Grid de Mockups</v-list-item-title>
                  <v-list-item-subtitle class="text-[10px]">Estampas aplicadas em produtos 3D reais.</v-list-item-subtitle>
                </v-list-item>

                <v-list-item @click="addBlock('giant_mockup')" class="rounded mb-1 hover-bg-light">
                  <template v-slot:prepend><v-icon color="red">mdi-star-four-points-outline</v-icon></template>
                  <v-list-item-title class="text-body-2 font-weight-bold">Mockup Gigante</v-list-item-title>
                  <v-list-item-subtitle class="text-[10px]">Destaque colossal flutuante para campanhas.</v-list-item-subtitle>
                </v-list-item>

                <v-list-item @click="addBlock('mosaic')" class="rounded mb-1 hover-bg-light">
                  <template v-slot:prepend><v-icon color="orange">mdi-view-dashboard-variant-outline</v-icon></template>
                  <v-list-item-title class="text-body-2 font-weight-bold">Mosaico Editorial</v-list-item-title>
                  <v-list-item-subtitle class="text-[10px]">Layout assimétrico estilo revista de moda.</v-list-item-subtitle>
                </v-list-item>

                <v-list-item @click="addBlock('testimonials')" class="rounded mb-1 hover-bg-light">
                  <template v-slot:prepend><v-icon color="amber">mdi-comment-quote-outline</v-icon></template>
                  <v-list-item-title class="text-body-2 font-weight-bold">Depoimentos</v-list-item-title>
                  <v-list-item-subtitle class="text-[10px]">Prova social de clientes em cards flutuantes.</v-list-item-subtitle>
                </v-list-item>

                <v-list-item @click="addBlock('services')" class="rounded mb-1 hover-bg-light">
                  <template v-slot:prepend><v-icon color="blue">mdi-printer-3d</v-icon></template>
                  <v-list-item-title class="text-body-2 font-weight-bold">Soluções Industriais</v-list-item-title>
                  <v-list-item-subtitle class="text-[10px]">Destaque para maquinário, corte e estamparia.</v-list-item-subtitle>
                </v-list-item>

                <v-list-item @click="addBlock('parallax')" class="rounded mb-1 hover-bg-light">
                  <template v-slot:prepend><v-icon color="purple">mdi-panorama-variant-outline</v-icon></template>
                  <v-list-item-title class="text-body-2 font-weight-bold">Banner Parallax</v-list-item-title>
                  <v-list-item-subtitle class="text-[10px]">Fundo fixo com CTA final imersivo.</v-list-item-subtitle>
                </v-list-item>

                <v-list-item @click="addBlock('editorial_text')" class="rounded hover-bg-light">
                  <template v-slot:prepend><v-icon color="grey-darken-2">mdi-format-align-center</v-icon></template>
                  <v-list-item-title class="text-body-2 font-weight-bold">Manifesto / Texto Livre</v-list-item-title>
                  <v-list-item-subtitle class="text-[10px]">Texto corrido com suporte a Letra Capitular.</v-list-item-subtitle>
                </v-list-item>

                <v-divider class="my-2"></v-divider>

                <v-list-item @click="addBlock('promotional_popup')" class="rounded hover-bg-light bg-primary-lighten-5">
                  <template v-slot:prepend><v-icon color="primary">mdi-message-badge-outline</v-icon></template>
                  <v-list-item-title class="text-body-2 font-weight-bold text-primary">Popup Promocional</v-list-item-title>
                  <v-list-item-subtitle class="text-[10px] text-primary">Modal de captura de leads / descontos.</v-list-item-subtitle>
                </v-list-item>
              </v-list>
            </v-menu>
          </div>
        </div>

        <div v-else class="d-flex flex-column h-100 bg-surface slide-in-right overflow-hidden">
          <div class="pa-4 border-b bg-background d-flex align-center gap-3 flex-shrink-0">
            <v-btn icon="mdi-arrow-left" size="small" variant="tonal" @click="activeBlock = null"></v-btn>
            <div>
              <h3 class="text-subtitle-2 font-weight-bold m-0 text-high-emphasis lh-1">{{ getBlockTypeName(activeBlock.type) }}</h3>
              <span class="text-[10px] text-medium-emphasis">Configurações granulares</span>
            </div>
            <v-btn icon="mdi-delete-outline" color="error" size="small" variant="text" class="ml-auto" @click="removeActiveBlock" title="Excluir bloco"></v-btn>
          </div>

          <div class="flex-grow-1 overflow-y-auto custom-scrollbar pa-5 d-flex flex-column gap-6" id="inspector-scroll-area-edit">
             <component
               :is="blockComponents[activeBlock.type]"
               v-if="blockComponents[activeBlock.type]"
               mode="settings"
               :block="activeBlock"
               :stamps="stampsWithCategory"
               :categories="props.categories"
               :mockups="props.mockups"
               @upload="triggerUpload"
             />
             <div v-else class="text-center opacity-50 py-10">
               Componente de configuração não encontrado para o tipo: {{ activeBlock.type }}
             </div>
          </div>
        </div>
      </aside>

      <main class="builder-canvas-area flex-grow-1 d-flex flex-column align-stretch custom-scrollbar position-relative w-100" style="background: #eef2f6; overflow-y: auto; overflow-x: hidden; padding-bottom: 120px;" id="canvas-scroll-area">

        <div v-for="block in homeBlocks" :key="'popup-'+block._id">
          <component
            v-if="block.type === 'promotional_popup' && (activeBlock?._id === block._id)"
            :is="blockComponents[block.type]"
            mode="preview"
            :block="block"
            :is-active="true"
            @click="selectBlockFromCanvas(block)"
          />
        </div>

        <div class="canvas-wrapper transition-all w-100" :class="viewport" style="margin-top: 24px; margin-bottom: 80px;">
          <div class="store-preview-frame shadow-lg w-100" style="background: #ffffff;">

            <header class="border-b px-6 py-4 d-flex justify-space-between align-center sticky-top z-10 w-100" style="background: rgba(255,255,255,0.95); backdrop-filter: blur(10px);">
              <div class="font-weight-black text-h6 tracking-tighter d-flex align-center gap-2">
                <v-icon color="black">mdi-shape-square-rounded-plus</v-icon> SUA MARCA
              </div>
              <div class="d-none d-md-flex gap-6 text-caption font-weight-bold text-medium-emphasis">
                <span>Studio</span><span>Estamparia</span><span>Corte a Laser</span><span>Catálogo</span>
              </div>
              <div class="d-flex gap-2">
                <v-btn color="black" variant="flat" class="text-white font-weight-bold rounded px-4 text-caption" size="small">Entrar</v-btn>
              </div>
            </header>

            <div class="store-body w-100">
              <div v-if="homeBlocks.length === 0" class="text-center py-16 text-disabled bg-background border-b border-dashed ma-8 rounded-lg">
                <v-icon size="48" class="mb-4 opacity-30">mdi-view-dashboard-variant-outline</v-icon>
                <h3 class="text-h6 font-weight-bold text-high-emphasis m-0">A Página Inicial está Vazia</h3>
                <p class="text-body-2 mt-2">Clique em "Adicionar Seção" no painel lateral para começar a montar a sua vitrine.</p>
              </div>

              <template v-for="block in homeBlocks" :key="block._id">
                <component
                  v-if="block.type !== 'promotional_popup' && blockComponents[block.type]"
                  :is="blockComponents[block.type]"
                  mode="preview"
                  :block="block"
                  :is-active="activeBlock?._id === block._id"
                  :stamps="props.stamps"
                  :categories="props.categories"
                  :mockups="props.mockups"
                  @click="selectBlockFromCanvas(block)"
                />
              </template>
            </div>

            <footer class="bg-grey-darken-4 text-white px-8 py-16 mt-auto w-100">
              <div class="d-flex flex-column flex-md-row justify-space-between gap-12 max-w-1200 mx-auto w-100">
                <div style="max-width: 400px;">
                  <div class="font-weight-black text-h4 mb-4 tracking-tighter">SUA MARCA</div>
                  <p class="text-body-1 text-grey-lighten-1 line-height-relaxed">A melhor infraestrutura de ponta para atender sua confecção de moda. Do design exclusivo à entrega do tecido.</p>
                </div>
                <div class="d-flex gap-16">
                  <div>
                    <h4 class="font-weight-bold mb-6 text-uppercase tracking-widest text-caption">Navegação</h4>
                    <div class="d-flex flex-column gap-3 text-body-2 text-grey-lighten-1">
                      <span>Catálogo</span><span>Serviços</span><span>Sobre Nós</span><span>Contato</span>
                    </div>
                  </div>
                </div>
              </div>
              <div class="max-w-1200 mx-auto w-100 mt-16 pt-8 border-t border-grey-darken-2 d-flex justify-space-between align-center">
                 <span class="text-caption text-grey-lighten-2">&copy; 2026 Powered by Storefront Platform.</span>
              </div>
            </footer>

          </div>
        </div>
      </main>

    </div>

    <input type="file" ref="fileInput" style="display:none" accept="image/png, image/jpeg, image/webp" @change="handleFileUpload" />
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, nextTick, computed, provide, defineAsyncComponent } from 'vue'
import { supabase } from '@/api/supabase'
import imageCompression from 'browser-image-compression'

const blockComponents: Record<string, any> = {
  promotional_popup: defineAsyncComponent(() => import('./blocks/PromotionalPopupBlock.vue')),
  promo_marquee: defineAsyncComponent(() => import('./blocks/PromoMarqueeBlock.vue')),
  hero: defineAsyncComponent(() => import('./blocks/HeroBlock.vue')),
  trust_carousel: defineAsyncComponent(() => import('./blocks/TrustCarouselBlock.vue')),
  zigzag_collections: defineAsyncComponent(() => import('./blocks/ZigzagCollectionsBlock.vue')),
  text_with_image: defineAsyncComponent(() => import('./blocks/TextWithImageBlock.vue')),
  collection: defineAsyncComponent(() => import('./blocks/CollectionBlock.vue')),
  mockup_grid: defineAsyncComponent(() => import('./blocks/MockupGridBlock.vue')),
  giant_mockup: defineAsyncComponent(() => import('./blocks/GiantMockupBlock.vue')),
  mosaic: defineAsyncComponent(() => import('./blocks/MosaicBlock.vue')),
  testimonials: defineAsyncComponent(() => import('./blocks/TestimonialsBlock.vue')),
  services: defineAsyncComponent(() => import('./blocks/ServicesBlock.vue')),
  parallax: defineAsyncComponent(() => import('./blocks/ParallaxBlock.vue')),
  editorial_text: defineAsyncComponent(() => import('./blocks/EditorialTextBlock.vue')),
  dual_banner: defineAsyncComponent(() => import('./blocks/DualBannerBlock.vue'))
}

const props = defineProps<{
  categories: any[],
  stamps: any[],
  mockups: any[]
}>()

const emit = defineEmits(['refresh'])

const settingsId = ref<string | null>(null)
const homeBlocks = ref<any[]>([])
const isSaving = ref(false)
const activeBlock = ref<any | null>(null)
const viewport = ref<'desktop' | 'mobile'>('desktop')

const fileInput = ref<HTMLInputElement | null>(null)
const pendingFiles = ref<Record<string, File>>({})
const currentUploadField = ref('')

const stampsWithCategory = computed(() => {
  return props.stamps.map(s => {
    const cat = props.categories.find(c => c.id === s.category_id)
    return { ...s, category_name: cat ? cat.name : 'Sem Categoria' }
  })
})

provide('builderUtils', {
  getOptimizedUrl,
  getTextColorClass,
  getStampObj,
  getMockupObj,
  getCategoryName
})

async function loadLayoutData() {
  activeBlock.value = null
  try {
    const { data } = await supabase.from('storefront_settings').select('id, home_blocks').order('updated_at', { ascending: false }).limit(1).maybeSingle()
    if (data) {
      settingsId.value = data.id
      let blocks = Array.isArray(data.home_blocks) ? data.home_blocks : []
      homeBlocks.value = blocks.map(b => {
        const settings = { ...b.settings }
        if (b.type === 'mockup_grid' && !settings.grid_items) settings.grid_items = [{ stamp_id: null, mockup_id: null }]
        if (b.type === 'testimonials' && (!settings.testimonials_list || settings.testimonials_list.length === 0)) settings.testimonials_list = [{ author: 'Marca X', role: 'Cliente', text: 'Bom serviço.', rating: 5 }]
        if (b.type === 'mosaic' && !settings.mosaic_items) settings.mosaic_items = [{type: 'category'}, {type: 'category'}, {type: 'category'}]
        if (b.type === 'zigzag_collections' && !settings.zigzag_items) settings.zigzag_items = []
        if (b.type === 'trust_carousel' && !settings.logos) settings.logos = []

        return { _id: generateId(), type: b.type, settings }
      })
    }
  } catch (err) {
    console.error('Erro ao carregar layout:', err)
  }
}

onMounted(() => loadLayoutData())

async function handleAction() {
  if (!settingsId.value) {
    alert("Erro: Storefront Settings ID não encontrado. Preencha a aba de Temas primeiro.")
    return
  }
  isSaving.value = true
  try {
    for (const fileKey in pendingFiles.value) {
      const file = pendingFiles.value[fileKey]
      const match = fileKey.match(/^block_([^_]+)_(.+)$/)
      if (match) {
          const blockId = match[1]; const fieldPath = match[2]
          const block = homeBlocks.value.find(b => b._id === blockId)
          if (block) {
              const ext = file.name.split('.').pop() || 'webp'
              const pathName = `storefront/block_${Date.now()}_${Math.random().toString(36).substring(7)}.${ext}`
              await supabase.storage.from('catalog-assets').upload(pathName, file, { upsert: false })
              const publicUrl = supabase.storage.from('catalog-assets').getPublicUrl(pathName).data.publicUrl

              const pathArr = fieldPath.split('.')
              if (pathArr.length === 1) block.settings[pathArr[0]] = publicUrl
              else if (pathArr.length === 3) block.settings[pathArr[0]][parseInt(pathArr[1])][pathArr[2]] = publicUrl
          }
      }
    }

    const cleanBlocks = homeBlocks.value.map(block => ({ type: block.type, settings: block.settings }))
    const { error } = await supabase.from('storefront_settings').update({ home_blocks: cleanBlocks, updated_at: new Date().toISOString() }).eq('id', settingsId.value)
    if (error) throw error
    alert("Estrutura da Home salva com sucesso!")
    pendingFiles.value = {}
    emit('refresh')
  } catch (err: any) {
    alert(`Erro ao salvar layout: ${err.message}`)
  } finally {
    isSaving.value = false
  }
}

function generateId() { return Math.random().toString(36).substring(2, 9) }

function addBlock(type: string) {
  const newBlock = { _id: generateId(), type: type, settings: getInitialSettingsForType(type) }
  homeBlocks.value.push(newBlock)
  selectBlock(newBlock)
}

function selectBlock(block: any) {
  if (block.type === 'mockup_grid' && !block.settings.grid_items) block.settings.grid_items = [{ stamp_id: null, mockup_id: null }]
  if (block.type === 'testimonials' && (!block.settings.testimonials_list || block.settings.testimonials_list.length === 0)) block.settings.testimonials_list = [{ author: 'Marca X', role: 'Cliente', text: 'Incrível', rating: 5 }]
  if (block.type === 'mosaic' && !block.settings.mosaic_items) block.settings.mosaic_items = [{ type: 'category' }, { type: 'category' }, { type: 'category' }]
  if (block.type === 'zigzag_collections' && !block.settings.zigzag_items) block.settings.zigzag_items = []
  if (block.type === 'trust_carousel' && !block.settings.logos) block.settings.logos = []

  activeBlock.value = block
  nextTick(() => {
    setTimeout(() => {
      const el = document.getElementById(`block-preview-${block._id}`)
      const scrollArea = document.getElementById('canvas-scroll-area')
      if (el && scrollArea) scrollArea.scrollTo({ top: el.offsetTop - 80, behavior: 'smooth' })
    }, 50)
  })
}

function selectBlockFromCanvas(block: any) { selectBlock(block) }

function removeActiveBlock() {
  if (!activeBlock.value) return
  if (confirm("Remover este bloco?")) {
    homeBlocks.value = homeBlocks.value.filter(b => b._id !== activeBlock.value._id)
    activeBlock.value = null
  }
}

function moveBlock(index: number, direction: number) {
  const newIndex = index + direction
  if (newIndex < 0 || newIndex >= homeBlocks.value.length) return
  const item = homeBlocks.value.splice(index, 1)[0]
  homeBlocks.value.splice(newIndex, 0, item)
}

function triggerUpload(fieldPath: string) {
  currentUploadField.value = fieldPath
  fileInput.value?.click()
}

async function handleFileUpload(event: Event) {
  const target = event.target as HTMLInputElement
  const file = target.files?.[0]
  if (!file || !activeBlock.value) return

  try {
    const compressed = await imageCompression(file, { maxSizeMB: 1.5, maxWidthOrHeight: 1920, useWebWorker: true, fileType: 'image/webp' })
    const localUrl = URL.createObjectURL(compressed)

    const pathArr = currentUploadField.value.split('.')
    if (pathArr.length === 1) activeBlock.value.settings[pathArr[0]] = localUrl
    else if (pathArr.length === 3) activeBlock.value.settings[pathArr[0]][parseInt(pathArr[1])][pathArr[2]] = localUrl

    pendingFiles.value[`block_${activeBlock.value._id}_${currentUploadField.value}`] = compressed
  } catch (e) { alert('Erro ao processar imagem.') }
  if (target) target.value = ''
}

function getTextColorClass(hexColor: string | undefined, defaultColor: string) {
  const color = hexColor || defaultColor;
  if (color === '#ffffff' || color === 'white') return 'text-black'
  return 'text-white'
}

function getOptimizedUrl(url: string | null | undefined, targetWidth: number) {
  if (!url) return '/placeholder.png'
  if (url.startsWith('blob:')) return url
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

function getStampObj(id: string) { return props.stamps.find(s => s.id === id) }
function getMockupObj(id: string) { return props.mockups.find(m => m.id === id) }
function getCategoryName(id: string) { return props.categories.find(c => c.id === id)?.name || '' }

function getInitialSettingsForType(type: string) {
  switch (type) {
    case 'promotional_popup': return { title: '10% OFF', text: 'Cadastre-se na newsletter', image_url: '', button_text: 'Eu Quero', bg_color: '#ffffff', button_color: '#000000', delay: 3, text_color: '#000000' }
    case 'promo_marquee': return { text: 'FRETE GRÁTIS ACIMA DE R$ 1.500', bg_color: '#000000', text_color: '#ffffff' }
    case 'trust_carousel': return { title: 'Marcas parceiras', logos: [], bg_color: '#f8fafc', text_color: '#111827', overlay_opacity: 0.7, bg_url: '' }
    case 'zigzag_collections': return { title: 'Linhas', zigzag_items: [], bg_color: '#ffffff', text_color: '#111827', button_color: '#000000', visual_theme: 'modern', layout_style: 'zigzag' }
    case 'text_with_image': return { title: 'Nossa Essência', image_url: '', image_position: 'left', align: 'left', bg_color: '#ffffff', text_color: '#111827' }
    case 'hero': return { title: 'Nova Coleção', bg_type: 'upload', overlay_opacity: 0.5, text_color: '#ffffff' }
    case 'dual_banner': return { title_1: 'Banner 1', title_2: 'Banner 2', text_color: '#ffffff', overlay_opacity: 0.3, border_style: 'gap' }
    case 'collection': return { title: 'Lançamentos', selection_type: 'auto', category_id: 'all', limit: 8, bg_color: '#ffffff', text_color: '#111827', layout_style: 'grid', aspect_ratio: 'portrait' }
    case 'mockup_grid': return { title: 'Grid de Mockups', grid_items: [{ stamp_id: null, mockup_id: null }], bg_color: '#f8fafc', text_color: '#111827' }
    case 'giant_mockup': return { title: 'O Caimento <br/><span class="text-primary">Perfeito.</span>', image_type: 'system', bg_color: '#ffffff', text_color: '#111827' }
    case 'mosaic': return { title: 'Mosaico', mosaic_items: [{type: 'category'}, {type: 'category'}, {type: 'category'}], bg_color: '#ffffff', text_color: '#111827' }
    case 'testimonials': return { title: 'O que dizem', testimonials_list: [], bg_color: '#f8fafc', text_color: '#111827', card_bg_color: '#ffffff' }
    case 'services': return { title: 'Serviços', bg_color: '#ffffff', text_color: '#111827', card_bg_color: '#f8fafc' }
    case 'parallax': return { title: 'Destaque', bg_type: 'upload', overlay_opacity: 0.6, text_color: '#ffffff' }
    case 'editorial_text': return { title: 'Manifesto', align: 'center', bg_color: '#ffffff', text_color: '#111827', container_width: 'medium', font_size: 'normal' }
    default: return {}
  }
}

function getBlockTypeName(type: string) {
  const names: Record<string, string> = {
    'promotional_popup': 'Popup Promocional', 'hero': 'Banner Hero', 'dual_banner': 'Banners Duplos',
    'collection': 'Vitrine de Estampas', 'mockup_grid': 'Grid de Mockups', 'giant_mockup': 'Mockup Gigante',
    'mosaic': 'Mosaico Editorial', 'testimonials': 'Depoimentos', 'services': 'Soluções Industriais',
    'parallax': 'Banner Parallax', 'editorial_text': 'Manifesto', 'promo_marquee': 'Faixa Promocional',
    'trust_carousel': 'Marcas Parceiras', 'zigzag_collections': 'Coleções Dinâmicas', 'text_with_image': 'Texto com Imagem'
  }
  return names[type] || 'Bloco Desconhecido'
}

defineExpose({ handleAction })
</script>

<style scoped>
.shopify-builder-shell { border: 1px solid rgba(var(--v-theme-on-surface), 0.12); }
.builder-topbar { height: 64px; }
.viewport-controls { display: flex; }
.vp-btn { width: 32px; height: 32px; border-radius: 6px; display: flex; align-items: center; justify-content: center; color: rgba(var(--v-theme-on-surface), 0.5); transition: all 0.2s; border: none; }
.vp-btn:hover { color: rgb(var(--v-theme-on-surface)); background: rgba(var(--v-theme-on-surface), 0.05); }
.vp-btn.active { background: rgb(var(--v-theme-surface)); color: rgb(var(--v-theme-primary)); box-shadow: 0 2px 6px rgba(0,0,0,0.08); }

.block-list-item { display: flex; align-items: center; padding: 12px 14px; border-radius: 8px; border: 1px solid rgba(var(--v-theme-on-surface), 0.08); transition: all 0.2s; margin-bottom: 8px;}
.block-list-item.cursor-pointer:hover { border-color: rgba(var(--v-theme-primary), 0.4); box-shadow: 0 4px 12px rgba(15,23,42,0.05); transform: translateX(2px); }
.block-list-item.static { background: rgba(var(--v-theme-on-surface), 0.03); }
.hover-bg-light:hover { background: rgba(var(--v-theme-on-surface), 0.04); }

.builder-canvas-area { background-image: radial-gradient(circle, rgba(var(--v-theme-on-surface), 0.05) 1px, transparent 1px); background-size: 20px 20px; scroll-behavior: smooth; }
.canvas-wrapper { margin: 0 auto; transition: width 0.4s cubic-bezier(0.25, 1, 0.5, 1); }

/* A MÁGICA PRA ENGOLIR A TELA INTEIRA TA AQUI */
.canvas-wrapper.desktop { width: 100% !important; max-width: none !important; padding: 0 32px; }
.canvas-wrapper.mobile { width: 400px; max-width: 100%; padding: 0 10px; margin: 0 auto; }

.store-preview-frame { border-radius: 8px; overflow: hidden; border: 1px solid rgba(var(--v-theme-on-surface), 0.1); min-height: 800px; position: relative; }

.list-anim-move, .list-anim-enter-active, .list-anim-leave-active { transition: all 0.3s ease; }
.list-anim-enter-from, .list-anim-leave-to { opacity: 0; transform: translateY(15px); }
.list-anim-leave-active { position: absolute; }
.slide-in-right { animation: slideInRight 0.3s cubic-bezier(0.25, 1, 0.5, 1); }
@keyframes slideInRight { from { transform: translateX(100%); opacity: 0; } to { transform: translateX(0); opacity: 1; } }

.custom-scrollbar::-webkit-scrollbar { width: 6px; }
.custom-scrollbar::-webkit-scrollbar-thumb { background: rgba(var(--v-theme-on-surface), 0.15); border-radius: 10px; }
</style>
