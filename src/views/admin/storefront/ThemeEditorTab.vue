<template>
  <div class="shopify-builder-shell d-flex flex-column bg-background w-100" style="height: calc(100vh - 120px);">

    <header class="builder-topbar bg-surface border-b px-4 py-3 d-flex align-center justify-space-between flex-shrink-0 z-10 shadow-sm w-100">
      <div class="d-flex align-center gap-4">
        <div class="bg-primary-lighten-5 p-2 rounded-lg text-primary d-flex align-center justify-center border border-primary">
          <v-icon size="20">mdi-palette-swatch-outline</v-icon>
        </div>
        <div>
          <h2 class="text-subtitle-1 font-weight-black lh-1 m-0 text-high-emphasis">Theme Editor</h2>
          <span class="text-[10px] text-medium-emphasis text-uppercase font-weight-bold tracking-widest">Configurações Globais da Loja</span>
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
        <v-btn variant="outlined" color="error" class="text-none font-weight-bold rounded-lg" size="small" @click="resetSettings" :disabled="isSaving">
          Descartar
        </v-btn>
        <v-btn color="primary" class="text-none font-weight-bold rounded-lg shadow-soft" size="small" :loading="isSaving" @click="handleAction" prepend-icon="mdi-content-save">
          Salvar Tema
        </v-btn>
      </div>
    </header>

    <div class="d-flex flex-grow-1 overflow-hidden position-relative w-100">

      <aside class="builder-inspector bg-surface border-e d-flex flex-column flex-shrink-0 shadow-lg h-100" style="width: 450px; min-width: 450px; z-index: 5;">

        <div v-if="!activeSection" class="d-flex flex-column h-100 overflow-hidden">
          <div class="pa-4 border-b bg-background flex-shrink-0">
            <h3 class="text-subtitle-2 font-weight-bold m-0 text-high-emphasis">Painéis de Configuração</h3>
            <p class="text-[10px] text-medium-emphasis m-0 mt-1">Selecione uma área para editar a identidade visual.</p>
          </div>

          <div class="flex-grow-1 overflow-y-auto custom-scrollbar pa-3 d-flex flex-column gap-2">

            <div class="block-list-item cursor-pointer enterprise-card bg-surface" @click="activeSection = 'global'">
              <div class="bg-grey-lighten-4 p-2 rounded mr-3 text-grey-darken-3"><v-icon size="18">mdi-cog-outline</v-icon></div>
              <div class="d-flex flex-column flex-grow-1">
                <strong class="text-body-2 font-weight-bold text-high-emphasis">Regras Globais</strong>
                <span class="text-[10px] text-medium-emphasis">Manutenção e Permissões de Venda</span>
              </div>
              <v-icon size="16" color="grey">mdi-chevron-right</v-icon>
            </div>

            <div class="block-list-item cursor-pointer enterprise-card bg-surface" @click="activeSection = 'popup'">
              <div class="bg-purple-lighten-5 p-2 rounded mr-3 text-purple"><v-icon size="18">mdi-shield-star-outline</v-icon></div>
              <div class="d-flex flex-column flex-grow-1">
                <strong class="text-body-2 font-weight-bold text-high-emphasis">Popup de Boas-Vindas</strong>
                <span class="text-[10px] text-medium-emphasis">Mensagem de segurança (Sessão)</span>
              </div>
              <v-chip size="x-small" :color="localSettings.welcome_popup_enabled ? 'success' : 'grey'" variant="flat" class="mr-2 text-[9px] font-weight-bold px-2">
                {{ localSettings.welcome_popup_enabled ? 'ON' : 'OFF' }}
              </v-chip>
              <v-icon size="16" color="grey">mdi-chevron-right</v-icon>
            </div>

            <div class="block-list-item cursor-pointer enterprise-card bg-surface" @click="activeSection = 'hero'">
              <div class="bg-blue-lighten-5 p-2 rounded mr-3 text-blue"><v-icon size="18">mdi-image-size-select-actual</v-icon></div>
              <div class="d-flex flex-column flex-grow-1">
                <strong class="text-body-2 font-weight-bold text-high-emphasis">Banner Hero (Padrão)</strong>
                <span class="text-[10px] text-medium-emphasis">Primeira dobra do catálogo</span>
              </div>
              <v-icon size="16" color="grey">mdi-chevron-right</v-icon>
            </div>

            <div class="block-list-item cursor-pointer enterprise-card bg-surface" @click="activeSection = 'parallax'">
              <div class="bg-teal-lighten-5 p-2 rounded mr-3 text-teal"><v-icon size="18">mdi-panorama-variant-outline</v-icon></div>
              <div class="d-flex flex-column flex-grow-1">
                <strong class="text-body-2 font-weight-bold text-high-emphasis">Banner Parallax (Fixo)</strong>
                <span class="text-[10px] text-medium-emphasis">Divisor de conteúdo inferior</span>
              </div>
              <v-icon size="16" color="grey">mdi-chevron-right</v-icon>
            </div>

            <div class="block-list-item cursor-pointer enterprise-card bg-surface" @click="activeSection = 'vitrines'">
              <div class="bg-orange-lighten-5 p-2 rounded mr-3 text-orange"><v-icon size="18">mdi-view-carousel-outline</v-icon></div>
              <div class="d-flex flex-column flex-grow-1">
                <strong class="text-body-2 font-weight-bold text-high-emphasis">Vitrines da Home</strong>
                <span class="text-[10px] text-medium-emphasis">Pastas e categorias exibidas</span>
              </div>
              <v-chip size="x-small" color="orange" variant="flat" class="mr-2 text-[9px] font-weight-bold px-2">{{ localSettings.grids_config?.length || 0 }} ativas</v-chip>
              <v-icon size="16" color="grey">mdi-chevron-right</v-icon>
            </div>

          </div>
        </div>

        <div v-else class="d-flex flex-column h-100 bg-surface slide-in-right overflow-hidden">
          <div class="pa-4 border-b bg-background d-flex align-center gap-3 flex-shrink-0">
            <v-btn icon="mdi-arrow-left" size="small" variant="tonal" @click="activeSection = null"></v-btn>
            <div>
              <h3 class="text-subtitle-2 font-weight-bold m-0 text-high-emphasis lh-1">{{ getSectionName(activeSection) }}</h3>
              <span class="text-[10px] text-medium-emphasis">Ajuste os parâmetros abaixo</span>
            </div>
          </div>

          <div class="flex-grow-1 overflow-y-auto custom-scrollbar pa-5 d-flex flex-column gap-6">

            <template v-if="activeSection === 'global'">
              <div class="bg-background border rounded-lg pa-4 d-flex align-center justify-space-between">
                <div class="d-flex align-center gap-3">
                  <v-icon color="error" size="24">mdi-alert-circle-outline</v-icon>
                  <div>
                    <div class="text-subtitle-2 font-weight-bold m-0 lh-1 mb-1">Modo Manutenção</div>
                    <div class="text-[11px] text-medium-emphasis m-0 lh-1">Bloqueia acesso público à loja.</div>
                  </div>
                </div>
                <v-switch v-model="localSettings.maintenance_mode" color="error" inset hide-details density="compact"></v-switch>
              </div>

              <div class="bg-background border rounded-lg pa-4 d-flex align-center justify-space-between">
                <div class="d-flex align-center gap-3">
                  <v-icon color="success" size="24">mdi-file-download-outline</v-icon>
                  <div>
                    <div class="text-subtitle-2 font-weight-bold m-0 lh-1 mb-1">Venda de Arquivos (PSD)</div>
                    <div class="text-[11px] text-medium-emphasis m-0 lh-1">Permite a compra direta digital.</div>
                  </div>
                </div>
                <v-switch v-model="localSettings.allow_psd_sales" color="success" inset hide-details density="compact"></v-switch>
              </div>
            </template>

            <template v-if="activeSection === 'popup'">
              <div class="bg-primary-lighten-5 border border-primary rounded-lg pa-4 d-flex align-center justify-space-between mb-2">
                <div>
                  <div class="text-subtitle-2 font-weight-bold text-primary m-0 lh-1 mb-1">Ativar Popup</div>
                  <div class="text-[11px] text-primary opacity-80 m-0 lh-1">Exibe alerta de tempo da sessão no 1º acesso.</div>
                </div>
                <v-switch v-model="localSettings.welcome_popup_enabled" color="primary" inset hide-details density="compact"></v-switch>
              </div>

              <div v-if="localSettings.welcome_popup_enabled" class="d-flex flex-column gap-5 slide-in-top">
                <div>
                  <label class="text-caption font-weight-bold text-high-emphasis mb-1 d-block">Estilo do Layout</label>
                  <v-select
                    v-model="localSettings.welcome_popup_style"
                    :items="[{title: 'Clássico (Apenas Texto Centralizado)', value: 'classic'}, {title: 'Lado a Lado (Imagem + Texto)', value: 'side-by-side'}]"
                    item-title="title"
                    item-value="value"
                    variant="outlined"
                    density="comfortable"
                    hide-details
                    class="bg-background"
                  ></v-select>
                </div>

                <div v-if="localSettings.welcome_popup_style === 'side-by-side'">
                  <label class="text-caption font-weight-bold text-high-emphasis mb-1 d-block">Imagem Lateral</label>
                  <div v-if="localSettings.welcome_popup_image" class="bg-background border rounded-lg pa-2 d-flex align-center gap-3">
                    <v-img :src="localSettings.welcome_popup_image" width="60" height="60" cover class="rounded border"></v-img>
                    <div class="flex-grow-1">
                      <div class="text-[11px] font-weight-bold">Imagem Carregada</div>
                    </div>
                    <v-btn variant="tonal" size="small" color="primary" class="text-none font-weight-bold" @click="triggerUpload('welcome_popup_image')">Trocar</v-btn>
                  </div>
                  <div v-else class="bg-background border border-dashed rounded-lg pa-6 text-center cursor-pointer hover-bg-light" @click="triggerUpload('welcome_popup_image')">
                    <v-icon size="24" color="primary" class="mb-2">mdi-image-plus</v-icon>
                    <div class="text-[11px] font-weight-bold">Fazer upload de imagem (Retrato)</div>
                  </div>
                </div>
              </div>
            </template>

            <template v-if="activeSection === 'hero'">
              <div>
                <label class="text-caption font-weight-bold text-high-emphasis mb-1 d-block">Imagem de Fundo</label>
                <div v-if="localSettings.hero_bg_url" class="bg-background border rounded-lg pa-3 d-flex align-center gap-4">
                  <v-img :src="localSettings.hero_bg_url" width="120" height="60" cover class="rounded border"></v-img>
                  <div class="flex-grow-1">
                    <div class="text-[11px] font-weight-bold">Banner Carregado</div>
                    <div class="text-[10px] text-primary">1920x800px</div>
                  </div>
                  <v-btn variant="tonal" size="small" color="primary" class="text-none font-weight-bold" @click="triggerUpload('hero_bg_url')">Trocar</v-btn>
                </div>
                <div v-else class="bg-background border border-dashed rounded-lg pa-6 text-center cursor-pointer hover-bg-light" @click="triggerUpload('hero_bg_url')">
                  <v-icon size="32" color="primary" class="mb-2">mdi-image-plus</v-icon>
                  <div class="text-body-2 font-weight-bold">Upload do banner principal</div>
                </div>
              </div>
              <div>
                <label class="text-caption font-weight-bold text-high-emphasis mb-1 d-block">Título</label>
                <input v-model="localSettings.hero_title" type="text" class="modern-input px-3 py-2 text-body-2" placeholder="Ex: Nova Coleção" />
              </div>
              <div>
                <label class="text-caption font-weight-bold text-high-emphasis mb-1 d-block">Subtítulo</label>
                <input v-model="localSettings.hero_subtitle" type="text" class="modern-input px-3 py-2 text-body-2" placeholder="Subtítulo persuasivo" />
              </div>
            </template>

            <template v-if="activeSection === 'parallax'">
              <div>
                <label class="text-caption font-weight-bold text-high-emphasis mb-1 d-block">Imagem Parallax</label>
                <div v-if="localSettings.parallax_bg_url" class="bg-background border rounded-lg pa-3 d-flex align-center gap-4">
                  <v-img :src="localSettings.parallax_bg_url" width="120" height="60" cover class="rounded border"></v-img>
                  <div class="flex-grow-1">
                    <div class="text-[11px] font-weight-bold">Parallax Carregado</div>
                    <div class="text-[10px] text-teal">1920x1080px</div>
                  </div>
                  <v-btn variant="tonal" size="small" color="teal" class="text-none font-weight-bold" @click="triggerUpload('parallax_bg_url')">Trocar</v-btn>
                </div>
                <div v-else class="bg-background border border-dashed rounded-lg pa-6 text-center cursor-pointer hover-bg-light" @click="triggerUpload('parallax_bg_url')">
                  <v-icon size="32" color="teal" class="mb-2">mdi-panorama-variant-outline</v-icon>
                  <div class="text-body-2 font-weight-bold">Upload de parallax</div>
                </div>
              </div>
              <div>
                <label class="text-caption font-weight-bold text-high-emphasis mb-1 d-block">Título da Seção</label>
                <input v-model="localSettings.parallax_title" type="text" class="modern-input px-3 py-2 text-body-2" placeholder="Ex: Qualidade Premium" />
              </div>
              <div>
                <label class="text-caption font-weight-bold text-high-emphasis mb-1 d-block">Texto Persuasivo</label>
                <textarea v-model="localSettings.parallax_text" rows="4" class="modern-input px-3 py-2 text-body-2" style="resize:none"></textarea>
              </div>
            </template>

            <template v-if="activeSection === 'vitrines'">
              <div class="text-caption text-medium-emphasis mb-2">Selecione quais pastas serão exibidas como carrossel/grid na home do catálogo.</div>
              <div class="d-flex flex-column gap-2">
                <article v-for="cat in categories" :key="cat.id" class="bg-background border rounded-lg pa-3 transition-all" :class="isCategoryOnHome(cat.id) ? 'border-orange' : ''">
                  <div class="d-flex justify-space-between align-center w-100">
                    <div class="d-flex align-center gap-3">
                      <v-icon size="20" :color="isCategoryOnHome(cat.id) ? 'orange' : 'grey'">mdi-folder</v-icon>
                      <strong class="text-body-2 font-weight-bold text-high-emphasis d-block lh-1">{{ cat.name }}</strong>
                    </div>
                    <v-switch
                      :model-value="isCategoryOnHome(cat.id)"
                      @update:model-value="val => toggleCategoryOnHome(cat.id, cat.name, val)"
                      color="orange"
                      hide-details
                      density="compact"
                    ></v-switch>
                  </div>
                  <v-expand-transition>
                    <div v-if="isCategoryOnHome(cat.id)" class="w-100 mt-2 pt-2 border-t d-flex align-center justify-space-between">
                      <span class="text-[11px] font-weight-bold text-orange">Limite de Estampas:</span>
                      <input
                        type="number"
                        :value="getCategoryLimit(cat.id)"
                        @input="e => updateCategoryLimit(cat.id, (e.target as HTMLInputElement).value)"
                        min="4" max="20"
                        class="bg-surface border rounded text-center text-orange font-weight-bold px-1 py-1 text-[11px]"
                        style="width: 50px; outline:none;"
                      />
                    </div>
                  </v-expand-transition>
                </article>
              </div>
            </template>

          </div>
        </div>
      </aside>

      <main class="builder-canvas-area flex-grow-1 d-flex flex-column align-stretch custom-scrollbar position-relative w-100" style="background: #eef2f6; overflow-y: auto; overflow-x: hidden; padding-bottom: 120px;">

        <div class="canvas-wrapper transition-all w-100" :class="viewport" style="margin-top: 24px; margin-bottom: 80px;">
          <div class="store-preview-frame shadow-lg w-100" style="background: #ffffff;">

            <header class="border-b px-6 py-4 d-flex justify-space-between align-center sticky-top z-10 w-100" style="background: rgba(255,255,255,0.95); backdrop-filter: blur(10px);">
              <div class="font-weight-black text-subtitle-1 tracking-tighter d-flex align-center gap-2">
                <v-icon color="black">mdi-shape-square-rounded-plus</v-icon> LOGO AQUI
              </div>
              <div class="d-none d-md-flex gap-6 text-caption font-weight-bold text-medium-emphasis">
                <span>Início</span><span>Estamparia</span><span>Catálogo</span>
              </div>
            </header>

            <div class="store-body w-100 position-relative">

              <div v-if="activeSection === 'popup' && localSettings.welcome_popup_enabled" class="absolute-fill z-20 d-flex align-center justify-center pa-4" style="background: rgba(0,0,0,0.6);">
                <v-card class="rounded-xl overflow-hidden shadow-lg border" elevation="24" :style="{ width: localSettings.welcome_popup_style === 'side-by-side' ? '900px' : '500px' }">
                  <div class="d-flex flex-column flex-md-row" :style="{ minHeight: localSettings.welcome_popup_style === 'side-by-side' ? '500px' : 'auto' }">

                    <div v-if="localSettings.welcome_popup_style === 'side-by-side'"
                         class="d-none d-md-block position-relative"
                         style="flex: 1 1 50%; background: rgba(128,128,128,0.1);">
                      <img
                        :src="localSettings.welcome_popup_image || '/placeholder.png'"
                        style="position: absolute; inset: 0; width: 100%; height: 100%; object-fit: cover;"
                      />
                    </div>

                    <div class="d-flex flex-column justify-center align-center text-center pa-8 pa-md-12"
                         :style="{ flex: localSettings.welcome_popup_style === 'side-by-side' ? '1 1 50%' : '1 1 100%' }">
                      <div style="width: 72px; height: 72px; border-radius: 20px; background: rgba(var(--v-theme-primary), 0.1); display: grid; place-items: center;" class="mb-6 mt-2">
                        <v-icon color="primary" size="36">mdi-shield-check-outline</v-icon>
                      </div>

                      <h2 class="text-h4 font-weight-black mb-4 text-high-emphasis">Seja Bem-vindo!</h2>

                      <p class="text-body-1 mb-8 text-medium-emphasis" style="line-height: 1.7; max-width: 360px;">
                        Por medida de segurança este acesso terá a duração de
                        <strong class="text-primary font-weight-black px-2 py-1 mx-1 rounded" style="background: rgba(var(--v-theme-primary), 0.12);">2 horas</strong>.
                        Caso precise acessar novamente, solicite um novo código.
                      </p>

                      <v-btn color="primary" size="x-large" class="rounded-pill font-weight-bold px-8 w-100 mb-2" style="max-width: 320px; letter-spacing: 0.02em;">
                        Entendi, Explorar
                      </v-btn>
                    </div>

                  </div>
                </v-card>
              </div>

              <section class="position-relative d-flex flex-column align-center justify-center text-center px-4" :class="{'active-preview-section': activeSection === 'hero'}" style="height: 450px; background-size: cover; background-position: center;" :style="{ backgroundImage: `linear-gradient(rgba(0,0,0,0.4), rgba(0,0,0,0.7)), url(${localSettings.hero_bg_url || '/placeholder.png'})` }">
                <div class="text-caption font-weight-bold text-primary mb-2 text-uppercase tracking-widest">{{ localSettings.hero_subtitle || 'Studio Collection' }}</div>
                <h1 class="text-white text-h3 font-weight-black mb-6">{{ localSettings.hero_title || 'Design Exclusivo para Marcas Exigentes.' }}</h1>
                <v-btn color="primary" class="font-weight-bold text-none px-8" size="large">Explorar Catálogo</v-btn>
              </section>

              <section class="pa-10 bg-background" :class="{'active-preview-section': activeSection === 'vitrines'}">
                <h2 class="text-h5 font-weight-black mb-8 text-center">Pastas Selecionadas (Vitrines)</h2>
                <div v-if="localSettings.grids_config?.length" class="d-flex flex-column gap-8">
                   <div v-for="grid in localSettings.grids_config" :key="grid.source_id">
                      <div class="d-flex justify-space-between align-center mb-4">
                        <div class="font-weight-bold text-subtitle-1">{{ grid.title }}</div>
                        <div class="text-[10px] font-weight-bold text-medium-emphasis text-uppercase">Exibe até {{ grid.limit }} itens</div>
                      </div>
                      <div class="d-flex gap-4 overflow-hidden">
                        <div v-for="i in 4" :key="i" class="bg-surface border rounded-lg" style="height: 160px; flex: 1;"></div>
                      </div>
                   </div>
                </div>
                <div v-else class="text-center text-disabled py-10 border border-dashed rounded-lg">
                  Nenhuma vitrine configurada para a home.
                </div>
              </section>

              <section class="position-relative d-flex flex-column align-center justify-center text-center px-4 py-16" :class="{'active-preview-section': activeSection === 'parallax'}" style="min-height: 350px; background-size: cover; background-position: center; background-attachment: fixed;" :style="{ backgroundImage: `linear-gradient(rgba(0,0,0,0.6), rgba(0,0,0,0.4)), url(${localSettings.parallax_bg_url || '/placeholder.png'})` }">
                <h3 class="text-h4 font-weight-black text-white mb-4">{{ localSettings.parallax_title || 'Banner Parallax' }}</h3>
                <p class="text-body-1 text-grey-lighten-2 mb-8 max-w-sm mx-auto">{{ localSettings.parallax_text || 'Texto persuasivo...' }}</p>
                <v-btn variant="outlined" color="white" size="large" class="text-none font-weight-bold px-8">Descubra Mais</v-btn>
              </section>

            </div>
          </div>
        </div>

      </main>

    </div>

    <input type="file" ref="fileInput" style="display:none" accept="image/png, image/jpeg, image/webp" @change="handleFileUpload" />
  </div>
</template>

<script setup lang="ts">
import { ref, watch, computed } from 'vue'
import { supabase } from '@/api/supabase'
import imageCompression from 'browser-image-compression'

const props = defineProps<{
  storeSettings: any,
  categories: any[],
  stamps: any[],
  pendingAccountLeads: any[],
  pendingDesignLeads: any[]
}>()

const emit = defineEmits(['refresh'])

// ESTADO GLOBAL
const localSettings = ref({ ...props.storeSettings })
const activeSection = ref<string | null>(null)
const viewport = ref<'desktop' | 'mobile'>('desktop')
const isSaving = ref(false)

// CONTROLES DE ARQUIVO
const fileInput = ref<HTMLInputElement | null>(null)
const pendingFiles = ref<Record<string, File>>({})
const currentUploadField = ref('')

// INICIALIZAÇÃO DE VARIÁVEIS FALTANTES
watch(() => props.storeSettings, (newVal) => {
  resetSettings()
}, { deep: true, immediate: true })

function resetSettings() {
  localSettings.value = { ...props.storeSettings }
  if (!localSettings.value.grids_config) localSettings.value.grids_config = []
  if (localSettings.value.welcome_popup_enabled === undefined) localSettings.value.welcome_popup_enabled = false
  if (!localSettings.value.welcome_popup_style) localSettings.value.welcome_popup_style = 'classic'
  pendingFiles.value = {}
}

function getSectionName(sec: string | null) {
  const map: Record<string, string> = {
    'global': 'Regras Globais',
    'popup': 'Popup de Boas-Vindas',
    'hero': 'Banner Hero',
    'parallax': 'Banner Parallax',
    'vitrines': 'Vitrines da Home'
  }
  return sec ? map[sec] : ''
}

// LOGICA DE VITRINES
function isCategoryOnHome(id: string) {
  return localSettings.value.grids_config?.some((g: any) => g.type === 'category' && g.source_id === id)
}

function getCategoryLimit(id: string) {
  const g = localSettings.value.grids_config?.find((g: any) => g.type === 'category' && g.source_id === id)
  return g ? g.limit : 8
}

function toggleCategoryOnHome(id: string, name: string, val: boolean) {
  if (val && !isCategoryOnHome(id)) {
    localSettings.value.grids_config.push({ title: name, type: 'category', source_id: id, limit: 8 })
  } else if (!val) {
    localSettings.value.grids_config = localSettings.value.grids_config.filter((g: any) => !(g.type === 'category' && g.source_id === id))
  }
}

function updateCategoryLimit(id: string, limitStr: string) {
  const limit = parseInt(limitStr) || 8
  const g = localSettings.value.grids_config?.find((g: any) => g.type === 'category' && g.source_id === id)
  if (g) g.limit = limit
}

// LOGICA DE UPLOAD
function triggerUpload(field: string) {
  currentUploadField.value = field
  fileInput.value?.click()
}

async function handleFileUpload(event: Event) {
  const target = event.target as HTMLInputElement
  const file = target.files?.[0]
  if (!file) return

  try {
    const compressed = await imageCompression(file, { maxSizeMB: 1, maxWidthOrHeight: 1920, useWebWorker: true, fileType: 'image/webp' })
    const localUrl = URL.createObjectURL(compressed)

    // Atualiza preview local
    ;(localSettings.value as any)[currentUploadField.value] = localUrl
    // Salva na fila para subir no handleAction
    pendingFiles.value[currentUploadField.value] = compressed
  } catch (e) {
    alert('Erro ao processar imagem.')
  }
  target.value = ''
}

async function uploadFileToStorage(field: string) {
  const f = pendingFiles.value[field]
  if (!f) return null
  const ext = 'webp'
  const path = `storefront/asset_${Date.now()}_${Math.random().toString(36).substring(7)}.${ext}`
  const { error } = await supabase.storage.from('catalog-assets').upload(path, f)
  if (error) throw error
  delete pendingFiles.value[field]
  return supabase.storage.from('catalog-assets').getPublicUrl(path).data.publicUrl
}

// AÇÃO DE SALVAR
async function handleAction() {
  isSaving.value = true
  try {
    // Faz o upload real dos arquivos pendentes e substitui os object URLs por URLs públicas
    for (const field of Object.keys(pendingFiles.value)) {
       const publicUrl = await uploadFileToStorage(field)
       if (publicUrl) {
         ;(localSettings.value as any)[field] = publicUrl
       }
    }

    const payload = { ...localSettings.value, updated_at: new Date().toISOString() }
    let res
    if (payload.id) {
      res = await supabase.from('storefront_settings').update(payload).eq('id', payload.id).select()
    } else {
      delete payload.id // Insere novo registro caso não exista
      res = await supabase.from('storefront_settings').insert([payload]).select()
    }

    if (res.error) throw res.error
    alert('Configurações do Tema salvas com sucesso!')
    emit('refresh')
  } catch (error: any) {
    alert(`Erro ao salvar: ${error.message}`)
  } finally {
    isSaving.value = false
  }
}

defineExpose({ handleAction })
</script>

<style scoped>
/* FUNDAÇÃO IGUAL AO BUILDER */
.shopify-builder-shell { border: 1px solid rgba(var(--v-theme-on-surface), 0.12); }
.builder-topbar { height: 64px; }
.viewport-controls { display: flex; }
.vp-btn { width: 32px; height: 32px; border-radius: 6px; display: flex; align-items: center; justify-content: center; color: rgba(var(--v-theme-on-surface), 0.5); transition: all 0.2s; border: none; }
.vp-btn:hover { color: rgb(var(--v-theme-on-surface)); background: rgba(var(--v-theme-on-surface), 0.05); }
.vp-btn.active { background: rgb(var(--v-theme-surface)); color: rgb(var(--v-theme-primary)); box-shadow: 0 2px 6px rgba(0,0,0,0.08); }

/* LISTA DO MENU */
.block-list-item { display: flex; align-items: center; padding: 12px 14px; border-radius: 8px; border: 1px solid rgba(var(--v-theme-on-surface), 0.08); transition: all 0.2s; margin-bottom: 8px;}
.block-list-item.cursor-pointer:hover { border-color: rgba(var(--v-theme-primary), 0.4); box-shadow: 0 4px 12px rgba(15,23,42,0.05); transform: translateX(2px); }
.hover-bg-light:hover { background: rgba(var(--v-theme-on-surface), 0.04); }

/* INPUTS E FORMS */
.modern-input { min-height: 42px; width: 100%; border: 1px solid rgba(var(--v-theme-on-surface), 0.15); background: rgba(var(--v-theme-surface), 0.88); border-radius: 8px; outline: none;}
.modern-input:focus { border-color: rgb(var(--v-theme-primary)); box-shadow: 0 0 0 3px rgba(var(--v-theme-primary), 0.1); }

/* CANVAS PREVIEW */
.builder-canvas-area { background-image: radial-gradient(circle, rgba(var(--v-theme-on-surface), 0.05) 1px, transparent 1px); background-size: 20px 20px; scroll-behavior: smooth; }
.canvas-wrapper { margin: 0 auto; transition: width 0.4s cubic-bezier(0.25, 1, 0.5, 1); }
.canvas-wrapper.desktop { width: 100% !important; max-width: none !important; padding: 0 32px; }
.canvas-wrapper.mobile { width: 400px; max-width: 100%; padding: 0 10px; margin: 0 auto; }
.store-preview-frame { border-radius: 8px; overflow: hidden; border: 1px solid rgba(var(--v-theme-on-surface), 0.1); min-height: 800px; position: relative; }

/* OVERLAYS E HIGHIGHTS DO CANVAS */
.absolute-fill { position: absolute; inset: 0; }
.active-preview-section { position: relative; }
.active-preview-section::after { content: ''; position: absolute; inset: 0; border: 4px solid rgb(var(--v-theme-primary)); pointer-events: none; z-index: 10; box-shadow: inset 0 0 0 2px rgba(255,255,255,0.5); }

/* ANIMAÇÕES */
.slide-in-right { animation: slideInRight 0.3s cubic-bezier(0.25, 1, 0.5, 1); }
@keyframes slideInRight { from { transform: translateX(100%); opacity: 0; } to { transform: translateX(0); opacity: 1; } }

.slide-in-top { animation: slideInTop 0.2s ease-out; }
@keyframes slideInTop { from { transform: translateY(-10px); opacity: 0; } to { transform: translateY(0); opacity: 1; } }

.custom-scrollbar::-webkit-scrollbar { width: 6px; }
.custom-scrollbar::-webkit-scrollbar-thumb { background: rgba(var(--v-theme-on-surface), 0.15); border-radius: 10px; }
</style>
