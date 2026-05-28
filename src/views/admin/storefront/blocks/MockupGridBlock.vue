<template>
  <div v-if="mode === 'settings'" class="premium-mockup-settings d-flex flex-column gap-6">

    <div class="mac-card">
      <div class="mac-card-header d-flex justify-space-between align-center border-b">
        <div class="d-flex align-center gap-2">
          <div class="icon-chip bg-primary text-white"><v-icon size="14">mdi-tshirt-crew-outline</v-icon></div>
          <span class="fw-700 text-sm text-dark">Itens do Grid (Máx: 12)</span>
        </div>
        <v-btn size="x-small" color="primary" variant="tonal" class="font-weight-bold text-none rounded" @click="addGridItem" :disabled="(block.settings.grid_items || []).length >= 12">
          <v-icon start size="14">mdi-plus</v-icon> Adicionar
        </v-btn>
      </div>

      <div class="mac-card-body d-flex flex-column gap-4 bg-lightest">
        <transition-group name="list-anim">
          <div v-for="(gItem, gIndex) in (block.settings.grid_items || [])" :key="gIndex" class="p-4 bg-white border rounded-md shadow-xs relative">
            <div class="d-flex justify-space-between align-center mb-3 pb-2 border-b">
              <span class="text-xs fw-800 text-primary text-uppercase tracking-widest">Mockup {{ gIndex + 1 }}</span>
              <v-btn icon size="x-small" color="error" variant="text" @click="removeGridItem(gIndex)" density="comfortable"><v-icon size="16">mdi-close</v-icon></v-btn>
            </div>

            <div class="d-flex flex-column gap-3">
              <div class="vuetify-override-container">
                <label class="premium-label text-primary">1. Estampa (Módulo de Repetição)</label>
                <v-autocomplete
                  v-model="gItem.stamp_id"
                  :items="stamps"
                  item-title="title"
                  item-value="id"
                  group-by="category_name"
                  variant="outlined"
                  density="compact"
                  hide-details
                  class="premium-autocomplete"
                  placeholder="Selecione a estampa...">
                  <template v-slot:item="{ props, item }">
                    <v-list-item v-bind="props" :title="item.raw.title">
                      <template v-slot:prepend>
                        <v-avatar rounded="lg" size="32" class="mr-3 border"><v-img :src="item.raw.main_image_url" cover></v-img></v-avatar>
                      </template>
                    </v-list-item>
                  </template>
                </v-autocomplete>
              </div>

              <div class="vuetify-override-container">
                <label class="premium-label text-primary">2. Mockup 3D (Máscara)</label>
                <v-autocomplete
                  v-model="gItem.mockup_id"
                  :items="mockups"
                  item-title="name"
                  item-value="id"
                  variant="outlined"
                  density="compact"
                  hide-details
                  class="premium-autocomplete"
                  placeholder="Selecione o modelo...">
                  <template v-slot:item="{ props, item }">
                    <v-list-item v-bind="props" :title="item.raw.name">
                      <template v-slot:prepend>
                        <v-avatar rounded="lg" size="32" class="mr-3 border bg-grey-lighten-4"><v-img :src="item.raw.base_image_url" style="object-fit: contain;"></v-img></v-avatar>
                      </template>
                    </v-list-item>
                  </template>
                </v-autocomplete>
              </div>
            </div>
          </div>
        </transition-group>
      </div>
    </div>

    <div class="mac-card">
      <div class="mac-card-header d-flex align-center gap-2 border-b">
        <div class="icon-chip bg-purple text-white"><v-icon size="14">mdi-format-title</v-icon></div>
        <span class="fw-700 text-sm text-dark">Textos e Cabeçalho</span>
      </div>

      <div class="mac-card-body d-flex flex-column gap-3 bg-lightest">
        <div class="p-4 bg-white border rounded-md shadow-xs d-flex flex-column gap-3">
          <div>
            <label class="premium-label">Título Principal</label>
            <input type="text" v-model="block.settings.title" class="premium-input" placeholder="Ex: Aplicações Reais" />
          </div>
          <div>
            <label class="premium-label">Subtítulo (Kicker)</label>
            <input type="text" v-model="block.settings.subtitle" class="premium-input" placeholder="Ex: Inspiração" />
          </div>
          <div>
            <label class="premium-label">Texto de Apoio</label>
            <textarea v-model="block.settings.text" rows="2" class="premium-input" style="height: auto; padding-top: 8px;" placeholder="Ex: Estampas aplicadas em produtos finais."></textarea>
          </div>
          <div>
            <label class="premium-label">Ação Final: Texto do Botão (Vazio = Oculto)</label>
            <input type="text" v-model="block.settings.button_text" class="premium-input" placeholder="Ex: Ver Todos os Mockups" />
          </div>
        </div>
      </div>
    </div>

    <div class="mac-card">
      <div class="mac-card-header d-flex align-center gap-2 border-b">
        <div class="icon-chip bg-green text-white"><v-icon size="14">mdi-palette-outline</v-icon></div>
        <span class="fw-700 text-sm text-dark">Design e Cores</span>
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
            <label class="premium-label">Cor de Fundo (Bloco)</label>
            <div class="color-input-wrapper">
              <input type="color" v-model="block.settings.bg_color" class="color-swatch-sm" />
              <input type="text" v-model="block.settings.bg_color" class="color-hex-input" placeholder="transparent" />
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
           class="pb-mockup-showcase preview-engine"
           :class="[{ 'active-outline': isActive }]"
           :style="{
             backgroundColor: block.settings.bg_color || 'transparent',
             fontFamily: block.settings.font_family || `'Inter', sans-serif`
           }">

    <div class="pb-container">

      <div class="text-center mb-10 max-w-800 mx-auto">
        <div v-if="block.settings.subtitle" class="pb-kicker mb-2" :style="{ color: block.settings.text_color || 'rgb(var(--v-theme-primary))' }">
          {{ block.settings.subtitle }}
        </div>
        <h2 class="text-h4 text-md-h3 font-weight-black tracking-tighter" :style="{ color: block.settings.text_color || 'var(--text-main)' }">
          {{ block.settings.title || 'Aplicações Reais' }}
        </h2>
        <p v-if="block.settings.text" class="mt-4" :style="{ color: block.settings.text_color ? `${block.settings.text_color}cc` : 'var(--text-muted)' }">
          {{ block.settings.text }}
        </p>
      </div>

      <div v-if="!block.settings.grid_items || block.settings.grid_items.length === 0" class="text-center py-16 opacity-40 border-2 border-dashed rounded-xl mx-auto" style="max-width: 600px;" :style="{ color: block.settings.text_color || 'inherit' }">
        <v-icon size="48" class="mb-4">mdi-tshirt-v-outline</v-icon>
        <h3 class="text-subtitle-1 font-weight-bold">Nenhum mockup configurado</h3>
        <p class="text-caption">Adicione produtos no painel de configurações.</p>
      </div>

      <div v-else class="mockup-display-grid">
        <div v-for="(gItem, idx) in (block.settings.grid_items || [])" :key="idx" class="mockup-card" :class="[`style-${block.settings.card_style || 'standard'}`]" @click="goToProduct(gItem)">

          <div class="mockup-media-wrapper">
            <template v-if="gItem.mockup_id && utils.getMockupObj(gItem.mockup_id)">
              <div v-if="utils.getMockupObj(gItem.mockup_id).mask_url" class="mockup-mask" :style="getMaskStyle(gItem)">
                <div class="pattern-fill" :style="getPatternStyle(gItem)"></div>
              </div>
              <div v-else class="pattern-fill full" :style="getPatternStyle(gItem)"></div>

              <img :src="utils.getOptimizedUrl(utils.getMockupObj(gItem.mockup_id).base_image_url, 1080)" class="mockup-base" />

              <img v-if="utils.getMockupObj(gItem.mockup_id).shadow_overlay_url"
                   :src="utils.getOptimizedUrl(utils.getMockupObj(gItem.mockup_id).shadow_overlay_url, 1080)"
                   class="mockup-shadow" />
            </template>

            <div v-else class="w-100 h-100 d-flex flex-column align-center justify-center bg-grey-lighten-4">
              <v-icon size="48" color="grey-lighten-2" class="mb-2">mdi-tshirt-crew</v-icon>
              <span class="text-[10px] text-medium-emphasis font-weight-bold text-uppercase tracking-widest">Incompleto</span>
            </div>
          </div>

          <div class="mockup-info border-t" :style="{ borderColor: block.settings.text_color ? `${block.settings.text_color}1a` : 'rgba(0,0,0,0.1)' }">
            <div class="overflow-hidden">
              <div class="text-caption text-truncate font-weight-medium" :style="{ color: block.settings.text_color ? `${block.settings.text_color}99` : 'var(--text-muted)' }">
                {{ utils.getMockupObj(gItem.mockup_id)?.name || 'Modelo Base' }}
              </div>
              <div class="text-body-2 font-weight-black text-truncate tracking-tighter mt-1" :style="{ color: block.settings.text_color || 'var(--text-main)' }">
                {{ utils.getStampObj(gItem.stamp_id)?.title || 'Configurar Produto' }}
              </div>
            </div>
            <v-btn icon="mdi-arrow-top-right" size="small" variant="tonal" :color="block.settings.text_color ? '' : 'primary'" :style="{ color: block.settings.text_color || '' }"></v-btn>
          </div>

        </div>
      </div>

      <div class="text-center mt-12" v-if="block.settings.button_text">
         <v-btn color="primary" variant="flat" size="large" class="rounded-lg font-weight-bold text-none px-10 shadow-sm hover-lift" :style="block.settings.text_color && block.settings.text_color !== '#000000' && block.settings.text_color !== '#fff' ? { backgroundColor: block.settings.text_color, color: '#fff' } : {}">
           {{ block.settings.button_text }}
         </v-btn>
      </div>

    </div>
  </section>
</template>

<script setup lang="ts">
import { inject, onMounted } from 'vue'
import { useRouter } from 'vue-router'

const props = defineProps<{
  mode: 'settings' | 'preview'
  block: any
  isActive?: boolean
  stamps: any[]
  mockups: any[]
}>()

const utils = inject<any>('builderUtils')
const router = useRouter()

// INIT DEFAULT SETTINGS
onMounted(() => {
  if (props.mode === 'settings') {
    if (props.block.settings.font_family === undefined) props.block.settings.font_family = "'Inter', sans-serif"
    if (props.block.settings.bg_color === undefined) props.block.settings.bg_color = '' // usa fundo transparente / default page bg
    if (props.block.settings.text_color === undefined) props.block.settings.text_color = ''
    if (props.block.settings.card_style === undefined) props.block.settings.card_style = 'standard'
  }
})

function addGridItem() {
  if (!props.block.settings.grid_items) props.block.settings.grid_items = []
  if (props.block.settings.grid_items.length < 12) {
    props.block.settings.grid_items.push({ stamp_id: null, mockup_id: null })
  }
}

function removeGridItem(index: number) {
  props.block.settings.grid_items.splice(index, 1)
}

function goToProduct(gItem: any) {
  if (props.mode === 'preview' && gItem.stamp_id) {
    router.push(`/marketplace/produto/${gItem.stamp_id}`)
  }
}

// ==========================================
// RENDERIZADOR NATIVO (IDÊNTICO AO CATALOG)
// ==========================================
function getPatternStyle(gItem: any) {
  const stamp = utils.getStampObj(gItem.stamp_id)
  if (!stamp || !stamp.main_image_url) return {}

  const bgColor = stamp.dominant_color || '#ffffff'
  return {
    backgroundColor: bgColor,
    backgroundImage: `url('${utils.getOptimizedUrl(stamp.main_image_url, 1080)}')`,
    backgroundSize: '30%',
    backgroundRepeat: 'repeat',
    backgroundPosition: 'center',
  }
}

function getMaskStyle(gItem: any) {
  const mockup = utils.getMockupObj(gItem.mockup_id)
  if (!mockup || !mockup.mask_url) return {}

  const maskUrl = utils.getOptimizedUrl(mockup.mask_url, 1080)

  return {
    WebkitMaskImage: `url('${maskUrl}')`,
    maskImage: `url('${maskUrl}')`,
    WebkitMaskSize: 'contain',
    maskSize: 'contain',
    WebkitMaskPosition: 'center',
    maskPosition: 'center',
    WebkitMaskRepeat: 'no-repeat',
    maskRepeat: 'no-repeat',
  }
}
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Bebas+Neue&family=Inter:wght@400;500;600;700;800&family=Montserrat:wght@400;700;900&family=Playfair+Display:ital,wght@0,400;0,700;0,900;1,400&display=swap');

/* ==========================================
   UI CUSTOMIZADA PREMIUM (SETTINGS)
   ========================================== */
.premium-mockup-settings { font-family: 'Inter', sans-serif; }
.fw-600 { font-weight: 600; }
.fw-700 { font-weight: 700; }
.fw-800 { font-weight: 800; }
.text-xs { font-size: 11px; }
.text-sm { font-size: 13px; }
.text-dark { color: #0f172a; }
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

/* Color Picker Retangular (Padrão Zigzag/MacOS) */
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

/* Animação lista */
.list-anim-enter-active, .list-anim-leave-active { transition: all 0.3s ease; }
.list-anim-enter-from, .list-anim-leave-to { opacity: 0; transform: scale(0.95); }

/* ==========================================
   ESTILOS DO PREVIEW
   ========================================== */
.preview-engine { transition: background-color 0.3s ease; outline: 2px solid transparent; outline-offset: -2px; }
.preview-engine:hover { outline-color: rgba(var(--v-theme-primary), 0.3); }
.active-outline { outline-color: rgb(var(--v-theme-primary)) !important; box-shadow: inset 0 0 0 4px rgba(var(--v-theme-primary), 0.1); position: relative; z-index: 10; }

.pb-mockup-showcase { padding: clamp(40px, 6vw, 100px) 0; }
.pb-container { max-width: 1700px; padding: 0 clamp(16px, 4vw, 56px); margin: 0 auto; width: 100%; }
.pb-kicker { font-size: clamp(10px, 1.2vw, 13px); font-weight: 800; letter-spacing: 0.15em; text-transform: uppercase; transition: color 0.3s ease;}

/* GRID 4 COLUNAS */
.mockup-display-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 32px 24px; }
@media (max-width: 1400px) { .mockup-display-grid { grid-template-columns: repeat(3, 1fr); } }
@media (max-width: 959px) { .mockup-display-grid { grid-template-columns: repeat(2, 1fr); } }
@media (max-width: 599px) { .mockup-display-grid { grid-template-columns: repeat(1, 1fr); } }

/* CARD DE MOCKUP - REFINADO COM VARIAÇÕES */
.mockup-card {
  display: flex;
  flex-direction: column;
  overflow: hidden;
  cursor: pointer;
  transition: transform 0.4s ease, box-shadow 0.4s ease, border-color 0.4s ease;
}

/* Card Style: Standard */
.style-standard { border-radius: 12px; background: var(--bg-surface, #ffffff); border: 1px solid rgba(0,0,0,0.05); }
.style-standard:hover { transform: translateY(-6px); box-shadow: 0 24px 48px rgba(0,0,0,0.12); border-color: rgba(var(--v-theme-primary), 0.4); }

/* Card Style: Minimalist */
.style-minimalist { border-radius: 0; background: transparent; border: none; }
.style-minimalist .mockup-media-wrapper { border-radius: 0; }
.style-minimalist:hover .pattern-fill { transform: scale(1.05); }

/* Card Style: Elevated (Apple Style) */
.style-elevated { border-radius: 20px; background: var(--bg-surface, #ffffff); border: 1px solid rgba(0,0,0,0.02); box-shadow: 0 10px 20px rgba(0,0,0,0.04); }
.style-elevated:hover { transform: translateY(-8px); box-shadow: 0 30px 60px rgba(0,0,0,0.12); border-color: rgba(var(--v-theme-primary), 0.2); }

/* CAIXA DA IMAGEM TRAVADA EM 1080x1080 (1:1) */
.mockup-media-wrapper {
  position: relative;
  width: 100%;
  aspect-ratio: 1 / 1;
  overflow: hidden;
  background: #f8fafc;
}

/* O MOTOR MÁGICO 3D */
.mockup-mask, .pattern-fill, .mockup-base, .mockup-shadow {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
}

.mockup-base, .mockup-shadow {
  object-fit: contain;
  pointer-events: none;
  z-index: 2;
}

.mockup-shadow {
  mix-blend-mode: multiply;
  z-index: 3;
}

.pattern-fill.full {
  inset: 0;
}

/* A ANIMAÇÃO DE ZOOM É APENAS NA ESTAMPA, NÃO NA ROUPA! */
.pattern-fill {
  transition: transform 0.8s cubic-bezier(0.25, 0.46, 0.45, 0.94);
  z-index: 1;
}
.mockup-card:hover .pattern-fill {
  transform: scale(1.1);
}

/* FOOTER DO CARD MINIMALISTA */
.mockup-info {
  padding: 16px 20px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  background: inherit;
  transition: border-color 0.3s ease;
}

.hover-lift { transition: all 0.3s ease; }
.hover-lift:hover { transform: translateY(-4px); box-shadow: 0 15px 30px rgba(0,0,0,0.15) !important; }
</style>
