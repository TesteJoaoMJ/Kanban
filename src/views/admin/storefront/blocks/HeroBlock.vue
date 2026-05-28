<template>
  <div v-if="mode === 'settings'" class="premium-hero-settings d-flex flex-column gap-6">

    <div class="mac-card">
      <div class="mac-card-header d-flex justify-space-between align-center">
        <div class="d-flex align-center gap-2">
          <div class="icon-chip bg-primary text-white"><v-icon size="14">mdi-view-carousel-outline</v-icon></div>
          <span class="fw-700 text-sm text-dark">Modo Carrossel</span>
        </div>
        <label class="ios-switch">
          <input type="checkbox" v-model="block.settings.is_carousel">
          <span class="ios-slider"></span>
        </label>
      </div>

      <div v-if="block.settings.is_carousel" class="mac-card-body d-flex gap-3 border-t">
        <div class="flex-1">
          <label class="premium-label">Transição de Fundo</label>
          <select v-model="block.settings.transition_type" class="premium-input">
            <option value="fade">Suave (Fade)</option>
            <option value="slide-x">Deslizar Lateral</option>
            <option value="zoom">Zoom e Fade</option>
          </select>
        </div>
        <div style="width: 100px;">
          <label class="premium-label">Segundos</label>
          <input type="number" v-model.number="block.settings.autoplay_interval" min="2" max="15" class="premium-input text-center" />
        </div>
      </div>

      <div class="mac-card-body d-flex flex-column gap-4 border-t bg-lightest rounded-b-lg">

        <div class="d-flex gap-3">
          <div class="flex-1">
            <label class="premium-label"><v-icon size="12" class="mr-1">mdi-format-font</v-icon> Fonte Global</label>
            <select v-model="block.settings.font_family" class="premium-input font-weight-bold">
              <option value="'Inter', sans-serif">Inter (Moderno)</option>
              <option value="'Montserrat', sans-serif">Montserrat (Geométrico)</option>
              <option value="'Playfair Display', serif">Playfair Display (Clássico)</option>
              <option value="'Bebas Neue', sans-serif">Bebas Neue (Impacto)</option>
            </select>
          </div>

          <div class="flex-1">
            <label class="premium-label text-primary">Altura da Seção (Desktop)</label>
            <select v-model="block.settings.section_height" class="premium-input font-weight-bold text-primary">
              <option value="50vh">Pequeno (50% da Tela)</option>
              <option value="700px">Padrão (700px)</option>
              <option value="80vh">Grande (80% da Tela)</option>
              <option value="100vh">Tela Cheia (100% da Tela)</option>
            </select>
          </div>
        </div>

        <div>
          <div class="d-flex justify-space-between mb-1">
            <label class="premium-label">Escurecimento (Overlay)</label>
            <span class="text-xs fw-700 text-primary">{{ (block.settings.overlay_opacity * 100).toFixed(0) }}%</span>
          </div>
          <input type="range" v-model.number="block.settings.overlay_opacity" step="0.1" min="0" max="0.9" class="premium-range w-100" />
        </div>
      </div>
    </div>

    <div class="slides-manager">
      <div class="d-flex align-center justify-space-between mb-3">
        <span class="text-xs fw-800 tracking-wide text-uppercase text-muted">
          {{ block.settings.is_carousel ? 'Gerenciar Slides' : 'Conteúdo do Banner' }}
        </span>
        <button v-if="block.settings.is_carousel" @click="addSlide" class="btn-clear btn-outline text-xs px-2 py-1">
          <v-icon size="14">mdi-plus</v-icon> Novo Slide
        </button>
      </div>

      <div class="d-flex flex-column gap-2">
        <div v-for="(slide, index) in block.settings.slides" :key="'slide-'+index" class="mac-card slide-accordion-card" :class="{'expanded': expandedSlide === index}">

          <div class="mac-card-header d-flex align-center justify-space-between cursor-pointer" @click="toggleSlide(index)">
            <div class="d-flex align-center gap-3">
              <div class="slide-number">{{ index + 1 }}</div>
              <span class="fw-600 text-sm text-dark">{{ slide.title && slide.show_text ? slide.title.substring(0, 20) + (slide.title.length > 20 ? '...' : '') : 'Slide sem texto' }}</span>
            </div>
            <div class="d-flex align-center gap-1">
              <button v-if="block.settings.slides.length > 1" @click.stop="removeSlide(index)" class="action-icon text-red hover-bg-red">
                <v-icon size="16">mdi-trash-can-outline</v-icon>
              </button>
              <div class="action-icon text-muted">
                <v-icon size="18">{{ expandedSlide === index ? 'mdi-chevron-up' : 'mdi-chevron-down' }}</v-icon>
              </div>
            </div>
          </div>

          <div v-show="expandedSlide === index" class="mac-card-body d-flex flex-column gap-5 border-t bg-lightest">

            <div class="d-flex gap-3">
              <div class="flex-1 d-flex justify-space-between align-center bg-white p-3 rounded-md border shadow-xs">
                <span class="text-xs fw-600 text-dark">Exibir Textos?</span>
                <label class="ios-switch"><input type="checkbox" v-model="slide.show_text"><span class="ios-slider"></span></label>
              </div>
              <div class="flex-1 d-flex justify-space-between align-center bg-white p-3 rounded-md border shadow-xs">
                <span class="text-xs fw-600 text-dark">Exibir Botão?</span>
                <label class="ios-switch"><input type="checkbox" v-model="slide.show_button"><span class="ios-slider"></span></label>
              </div>
            </div>

            <div v-if="slide.show_text" class="d-flex flex-column gap-3 p-4 bg-white border rounded-md shadow-xs relative">
              <div class="section-badge bg-blue text-blue">Tipografia</div>

              <div class="d-flex gap-3 mt-2">
                <div class="flex-1">
                  <label class="premium-label">Efeito do Texto</label>
                  <select v-model="slide.text_effect" class="premium-input">
                    <option value="none">Sólido</option>
                    <option value="shadow-soft">Sombra Suave</option>
                    <option value="shadow-hard">Sombra Dura</option>
                    <option value="glow">Glow/Neon</option>
                  </select>
                </div>
                <div class="flex-1">
                  <label class="premium-label">Animação de Entrada</label>
                  <select v-model="slide.anim_in" class="premium-input">
                    <option value="fade-up">Subir Suave</option>
                    <option value="slide-left">Da Esquerda</option>
                    <option value="zoom-in">Zoom In</option>
                    <option value="fade">Só Aparecer</option>
                  </select>
                </div>
              </div>

              <div class="mt-1">
                <label class="premium-label">Título Principal</label>
                <input type="text" v-model="slide.title" class="premium-input" placeholder="Ex: Nova Coleção" />
              </div>
              <div>
                <label class="premium-label">Subtítulo (Kicker)</label>
                <input type="text" v-model="slide.subtitle" class="premium-input" />
              </div>
              <div>
                <label class="premium-label">Texto de Apoio</label>
                <textarea v-model="slide.text" class="premium-input" rows="2"></textarea>
              </div>
            </div>

            <div v-if="slide.show_button" class="d-flex gap-3 p-4 bg-white border rounded-md shadow-xs border-l-blue relative">
               <div class="section-badge bg-blue text-blue">Ação</div>
               <div class="flex-1 mt-2">
                 <label class="premium-label">Texto</label>
                 <input type="text" v-model="slide.button_text" class="premium-input" />
               </div>
               <div class="flex-1 mt-2">
                 <label class="premium-label">Link</label>
                 <input type="text" v-model="slide.button_link" class="premium-input" />
               </div>
            </div>

            <div class="d-flex flex-column gap-3 p-4 bg-white border rounded-md shadow-xs relative">
              <div class="section-badge bg-purple text-purple">Mídia Fundo</div>

              <div class="mt-2">
                <label class="premium-label">Origem</label>
                <select v-model="slide.bg_type" class="premium-input">
                  <option value="upload">Upload Manual (Computador)</option>
                  <option value="catalog">Vincular a uma Estampa</option>
                </select>
              </div>

              <div v-if="slide.bg_type === 'upload'" class="d-flex flex-column gap-2 mt-1">
                <div v-if="slide.bg_url" class="image-thumb-container">
                  <img :src="slide.bg_url" class="image-thumb" :style="{ objectFit: slide.bg_size || 'cover', objectPosition: slide.bg_position || 'center' }" />
                  <button @click="slide.bg_url = ''" class="btn-thumb-delete"><v-icon size="14">mdi-close</v-icon></button>
                </div>
                <button @click="triggerUpload(index)" class="btn-clear btn-outline border-dashed py-2 w-100">
                  <v-icon size="16" class="mr-1">mdi-cloud-upload-outline</v-icon>
                  {{ slide.bg_url ? 'Substituir Imagem' : 'Selecionar Arquivo' }}
                </button>
              </div>

              <div v-if="slide.bg_type === 'catalog'" class="mt-1 vuetify-override-container">
                <label class="premium-label">Buscar Estampa</label>
                <v-autocomplete
                  v-model="slide.bg_stamp_id" :items="stamps" item-title="title" item-value="id" group-by="category_name"
                  variant="outlined" density="compact" hide-details class="premium-autocomplete">
                  <template v-slot:item="{ props, item }">
                    <v-list-item v-bind="props" :title="item.raw.title" :subtitle="item.raw.ref_code">
                      <template v-slot:prepend><v-avatar rounded="lg" size="32" class="mr-3 border"><v-img :src="item.raw.main_image_url" cover></v-img></v-avatar></template>
                    </v-list-item>
                  </template>
                </v-autocomplete>
              </div>

              <div class="d-flex gap-3 mt-2 border-t pt-3">
                <div class="flex-1">
                  <label class="premium-label">Encaixe da Imagem</label>
                  <select v-model="slide.bg_size" class="premium-input">
                    <option value="cover">Preencher Teto (Pode cortar)</option>
                    <option value="contain">Exibir Inteira (Com bordas)</option>
                    <option value="pattern">Repetir como Textura (Mosaico)</option>
                  </select>
                </div>
                <div class="flex-1">
                  <label class="premium-label">Foco / Alinhamento</label>
                  <select v-model="slide.bg_position" class="premium-input">
                    <option value="top">Topo (Foca na cabeça)</option>
                    <option value="center">Centro (Padrão)</option>
                    <option value="bottom">Base (Foca no chão)</option>
                  </select>
                </div>
              </div>
            </div>

            <div class="d-flex gap-3">
              <div v-if="slide.show_text" class="flex-1 d-flex align-center justify-space-between p-3 bg-white border rounded-md shadow-xs">
                <span class="text-xs fw-600 text-dark">Cor do Texto</span>
                <input type="color" v-model="slide.text_color" class="premium-color-picker" />
              </div>
              <div v-if="slide.show_button" class="flex-1 d-flex align-center justify-space-between p-3 bg-white border rounded-md shadow-xs">
                <span class="text-xs fw-600 text-dark">Cor do Botão</span>
                <input type="color" v-model="slide.button_color" class="premium-color-picker" />
              </div>
            </div>

          </div>
        </div>
      </div>
    </div>

  </div>

  <section v-else
           :id="`block-preview-${block._id}`"
           class="preview-section hero-preview position-relative d-flex flex-column align-center justify-center text-center px-0 px-md-4 overflow-hidden"
           :class="{ 'active-outline': isActive }"
           :style="computedHeroStyle">

    <!-- HELPER INVISÍVEL FICA FORA DO CARROSSEL: Ele quem dita a altura exata da caixa no mobile -->
    <img v-if="block.settings.slides && block.settings.slides[currentIndex]"
         :src="getFinalUrl(block.settings.slides[currentIndex])"
         class="mobile-aspect-helper" />

    <transition-group :name="block.settings.transition_type || 'fade'" tag="div" class="carousel-track">
      <template v-for="(slide, index) in (block.settings.slides || [])" :key="'slide-template-'+index">
        <div v-if="index === currentIndex"
             class="slide-layer"
             :key="'slide-layer-'+index"
             :style="getSlideStyle(slide)">

          <!-- MÁGICA DO MOBILE: Slide fica strictly absolute pra transição perfeita -->
          <img :src="getFinalUrl(slide)" class="mobile-actual-bg" />
          <div class="mobile-overlay" :style="{ backgroundColor: `rgba(0,0,0,${block.settings.overlay_opacity !== undefined ? block.settings.overlay_opacity : 0.5})` }"></div>

          <div v-if="slide.show_text !== false || slide.show_button !== false"
               class="content-wrapper px-4 px-md-0 d-flex flex-column align-center justify-center"
               :class="[`anim-${slide.anim_in || 'fade-up'}`]"
               style="max-width: 900px; width: 100%;">

            <template v-if="slide.show_text !== false">
              <div v-if="slide.subtitle" class="d-inline-block border px-6 py-2 rounded-pill text-caption font-weight-bold mb-4 mb-md-6 tracking-widest text-uppercase glass-kicker" :style="{ borderColor: slide.text_color || '#ffffff', color: slide.text_color || '#ffffff' }">{{ slide.subtitle }}</div>
              <h1 class="text-h4 text-sm-h2 text-md-h1 font-weight-black mb-3 mb-md-6 tracking-tighter" :class="[`effect-${slide.text_effect || 'shadow-soft'}`]" :style="{ color: slide.text_color || '#ffffff' }" style="line-height: 1.05;">{{ slide.title || 'Título Hero' }}</h1>
              <p class="text-body-1 text-md-h5 mb-6 mb-md-10 opacity-90 font-weight-regular max-w-700 mx-auto" :class="[`effect-${slide.text_effect || 'shadow-soft'}`]" :style="{ color: slide.text_color || '#ffffff' }" style="line-height: 1.6;">{{ slide.text || 'O texto de apoio da sua seção entra aqui.' }}</p>
            </template>

            <v-btn v-if="slide.show_button !== false && slide.button_text"
                   :color="slide.button_color || 'white'" :class="utils?.getTextColorClass ? utils.getTextColorClass(slide.button_color, 'white') : ''"
                   size="x-large" class="rounded-lg font-weight-black text-none px-8 px-md-12 elevation-4 hover-lift mt-2 responsive-hero-btn" style="letter-spacing: 0.5px;">
              {{ slide.button_text }}
            </v-btn>
          </div>
        </div>
      </template>
    </transition-group>

    <div v-if="block.settings.is_carousel && (block.settings.slides?.length || 0) > 1" class="carousel-nav z-20">
      <v-btn icon="mdi-chevron-left" @click.stop="prevSlide(); resetAutoplay()" size="small" variant="text" color="white"></v-btn>
      <div class="dots d-flex gap-2 mx-3"><div v-for="(_, i) in (block.settings.slides || [])" :key="'dot-'+i" class="dot" :class="{ active: i === currentIndex }" @click="currentIndex = i; resetAutoplay()"></div></div>
      <v-btn icon="mdi-chevron-right" @click.stop="nextSlide(); resetAutoplay()" size="small" variant="text" color="white"></v-btn>
    </div>

  </section>
</template>

<script setup lang="ts">
import { computed, inject, ref, watch, onMounted, onUnmounted } from 'vue'

const props = defineProps<{
  mode: 'settings' | 'preview'
  block: any
  isActive?: boolean
  stamps?: any[]
  categories?: any[]
  mockups?: any[]
}>()

const emit = defineEmits(['upload'])
const utils = inject<any>('builderUtils')

// INJEÇÃO DE DADOS PADRÃO E MIGRAÇÃO
if (!props.block.settings.slides || !Array.isArray(props.block.settings.slides)) {
  props.block.settings.slides = [{
    title: props.block.settings.title || '', subtitle: props.block.settings.subtitle || '', text: props.block.settings.text || '',
    button_text: props.block.settings.button_text || '', button_link: props.block.settings.button_link || '',
    bg_type: props.block.settings.bg_type || 'upload', bg_url: props.block.settings.bg_url || '', bg_stamp_id: props.block.settings.bg_stamp_id || '',
    text_color: props.block.settings.text_color || '#ffffff', button_color: props.block.settings.button_color || '#ffffff',
    show_text: true, show_button: true, text_effect: 'shadow-soft', anim_in: 'fade-up',
    bg_size: 'cover', bg_position: 'center'
  }]
}
if (props.block.settings.is_carousel === undefined) props.block.settings.is_carousel = false
if (props.block.settings.transition_type === undefined) props.block.settings.transition_type = 'fade'
if (props.block.settings.autoplay_interval === undefined) props.block.settings.autoplay_interval = 6
if (props.block.settings.overlay_opacity === undefined) props.block.settings.overlay_opacity = 0.5
if (props.block.settings.font_family === undefined) props.block.settings.font_family = "'Inter', sans-serif"
if (props.block.settings.section_height === undefined) props.block.settings.section_height = '100vh'

props.block.settings.slides.forEach((slide: any) => {
  if (slide.bg_size === undefined) slide.bg_size = 'cover'
  if (slide.bg_position === undefined) slide.bg_position = 'center'
})

// O PULO DO GATO PARA RESPONSIVIDADE NA ALTURA
const computedHeroStyle = computed(() => {
  const baseStyle: any = {
    backgroundColor: props.block.settings.bg_color || '#000000',
    fontFamily: props.block.settings.font_family || `'Inter', sans-serif`
  };

  if (window.innerWidth > 600) {
    baseStyle.height = props.block.settings.section_height || '100vh';
  }

  return baseStyle;
});

// ESTADO DO ACCORDION CUSTOMIZADO
const expandedSlide = ref<number>(0)
const toggleSlide = (index: number) => { expandedSlide.value = expandedSlide.value === index ? -1 : index }

// UPLOAD DE IMAGEM
const triggerUpload = (index: number) => { emit('upload', `slides.${index}.bg_url`) }

// LOGICA DO CARROSSEL
const currentIndex = ref(0)
let timer: any = null

const nextSlide = () => { if (props.block.settings.slides?.length) currentIndex.value = (currentIndex.value + 1) % props.block.settings.slides.length }
const prevSlide = () => { if (props.block.settings.slides?.length) currentIndex.value = (currentIndex.value - 1 + props.block.settings.slides.length) % props.block.settings.slides.length }
const startAutoplay = () => { stopAutoplay(); if (props.block.settings.is_carousel && props.mode === 'preview') { timer = setInterval(nextSlide, (props.block.settings.autoplay_interval || 5) * 1000) } }
const stopAutoplay = () => { if (timer) clearInterval(timer) }
const resetAutoplay = () => { startAutoplay() }

onMounted(startAutoplay)
onUnmounted(stopAutoplay)
watch(() => props.block.settings.is_carousel, startAutoplay)
watch(() => props.block.settings.autoplay_interval, startAutoplay)

const addSlide = () => {
  props.block.settings.slides.push({
    title: 'Novo Slide', subtitle: '', text: 'Conteúdo descritivo', button_text: 'Saiba Mais', button_link: '',
    bg_type: 'upload', bg_url: '', text_color: '#ffffff', button_color: '#ffffff', show_text: true, show_button: true, text_effect: 'shadow-soft', anim_in: 'fade-up',
    bg_size: 'cover', bg_position: 'center'
  })
  expandedSlide.value = props.block.settings.slides.length - 1
}

const removeSlide = (index: number) => {
  props.block.settings.slides.splice(index, 1)
  if (currentIndex.value >= props.block.settings.slides.length) currentIndex.value = 0
  if (expandedSlide.value === index) expandedSlide.value = Math.max(0, index - 1)
}

// FUNÇÃO PARA BUSCAR A URL FINAL DA IMAGEM
const getFinalUrl = (slide: any) => {
  if (!slide) return 'https://images.unsplash.com/photo-1558591710-4b4a1ae0f04d?q=80&w=1920';
  let bgUrl = slide.bg_url;

  if (slide.bg_type === 'catalog' && slide.bg_stamp_id) {
    const stamp = utils?.getStampObj ? utils.getStampObj(slide.bg_stamp_id) : null;
    if (stamp && stamp.main_image_url) bgUrl = stamp.main_image_url;
  }

  const isPattern = slide.bg_size === 'pattern';
  const targetWidth = isPattern ? 600 : 1920;

  return bgUrl ? (utils?.getOptimizedUrl ? utils.getOptimizedUrl(bgUrl, targetWidth) : bgUrl) : 'https://images.unsplash.com/photo-1558591710-4b4a1ae0f04d?q=80&w=1920';
};

const getSlideStyle = (slide: any) => {
  if (!slide) return {};
  const opacity = props.block.settings.overlay_opacity !== undefined ? props.block.settings.overlay_opacity : 0.5;
  const finalImage = getFinalUrl(slide);
  const isPattern = slide.bg_size === 'pattern';

  return {
    backgroundImage: `linear-gradient(rgba(0,0,0,${opacity}), rgba(0,0,0,${opacity})), url('${finalImage}')`,
    backgroundSize: isPattern ? 'auto' : (slide.bg_size || 'cover'),
    backgroundPosition: slide.bg_position || 'center',
    backgroundRepeat: isPattern ? 'repeat' : 'no-repeat'
  };
}
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Bebas+Neue&family=Inter:wght@400;500;600;700;800&family=Montserrat:wght@400;700;900&family=Playfair+Display:ital,wght@0,400;0,700;0,900;1,400&display=swap');

/* ==========================================
   UI CUSTOMIZADA PREMIUM
   ========================================== */
.premium-hero-settings { font-family: 'Inter', sans-serif; }
.fw-600 { font-weight: 600; }
.fw-700 { font-weight: 700; }
.fw-800 { font-weight: 800; }
.text-xs { font-size: 11px; }
.text-sm { font-size: 13px; }
.text-dark { color: #0f172a; }
.text-muted { color: #64748b; }
.text-blue { color: #2563eb; }
.text-purple { color: #7c3aed; }
.bg-blue { background: rgba(59, 130, 246, 0.1); }
.bg-purple { background: rgba(124, 58, 237, 0.1); }
.bg-lightest { background: #f8fafc; }
.border-l-blue { border-left: 3px solid #3b82f6 !important; }

/* CONTAINERS E CARDS */
.mac-card { background: #ffffff; border: 1px solid #e2e8f0; border-radius: 12px; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.02), 0 2px 4px -1px rgba(0,0,0,0.02); transition: all 0.2s; }
.mac-card-header { padding: 14px 16px; border-radius: 12px; }
.mac-card-body { padding: 16px; }
.slide-accordion-card.expanded { border-color: #cbd5e1; box-shadow: 0 10px 15px -3px rgba(0,0,0,0.05); margin-bottom: 8px; margin-top: 8px; }

/* INPUTS */
.premium-label { display: block; font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.05em; color: #64748b; margin-bottom: 6px; }
.premium-input { width: 100%; height: 36px; padding: 0 12px; font-size: 13px; font-weight: 500; color: #1e293b; background: #ffffff; border: 1px solid #cbd5e1; border-radius: 8px; transition: all 0.2s ease; outline: none; box-shadow: inset 0 1px 2px rgba(0,0,0,0.02); }
.premium-input:focus { border-color: #3b82f6; box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.15); }
select.premium-input { appearance: none; background-image: url("data:image/svg+xml;charset=US-ASCII,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20width%3D%22292.4%22%20height%3D%22292.4%22%3E%3Cpath%20fill%3D%22%2364748b%22%20d%3D%22M287%2069.4a17.6%2017.6%200%200%200-13-5.4H18.4c-5%200-9.3%201.8-12.9%205.4A17.6%2017.6%200%200%200%200%2082.2c0%205%201.8%209.3%205.4%2012.9l128%20127.9c3.6%203.6%207.8%205.4%2012.8%205.4s9.2-1.8%2012.8-5.4L287%2095c3.5-3.5%205.4-7.8%205.4-12.8%200-5-1.9-9.2-5.5-12.8z%22%2F%3E%3C%2Fsvg%3E"); background-repeat: no-repeat; background-position: right 12px center; background-size: 10px auto; padding-right: 32px; }
textarea.premium-input { height: auto; padding-top: 8px; resize: vertical; }

/* RANGE E COLOR PICKER */
.premium-range { accent-color: #3b82f6; cursor: pointer; height: 4px; border-radius: 4px; }
.premium-color-picker { -webkit-appearance: none; appearance: none; width: 32px; height: 32px; border: none; border-radius: 50%; cursor: pointer; padding: 0; background: transparent; box-shadow: inset 0 0 0 1px rgba(0,0,0,0.1), 0 2px 4px rgba(0,0,0,0.05); transition: transform 0.2s; }
.premium-color-picker:hover { transform: scale(1.1); }
.premium-color-picker::-webkit-color-swatch-wrapper { padding: 0; }
.premium-color-picker::-webkit-color-swatch { border: none; border-radius: 50%; }

/* O VERDADEIRO SWITCH DE IOS */
.ios-switch { position: relative; display: inline-block; width: 40px; height: 22px; }
.ios-switch input { opacity: 0; width: 0; height: 0; }
.ios-slider { position: absolute; cursor: pointer; top: 0; left: 0; right: 0; bottom: 0; background-color: #cbd5e1; transition: .3s; border-radius: 22px; }
.ios-slider:before { position: absolute; content: ""; height: 18px; width: 18px; left: 2px; bottom: 2px; background-color: white; transition: .3s; border-radius: 50%; box-shadow: 0 2px 4px rgba(0,0,0,0.2); }
input:checked + .ios-slider { background-color: #3b82f6; }
input:checked + .ios-slider:before { transform: translateX(18px); }

/* BOTOES E ICONES */
.btn-clear { display: inline-flex; align-items: center; justify-content: center; font-weight: 600; border-radius: 8px; cursor: pointer; transition: all 0.2s; background: transparent; border: none; outline: none; }
.btn-outline { border: 1px solid #cbd5e1; color: #475569; background: #ffffff; }
.btn-outline:hover { border-color: #94a3b8; background: #f1f5f9; color: #0f172a; }
.border-dashed { border-style: dashed; }
.action-icon { width: 28px; height: 28px; display: flex; align-items: center; justify-content: center; border-radius: 6px; transition: 0.2s; }
.action-icon:hover { background: #f1f5f9; color: #0f172a; }
.text-red { color: #ef4444; }
.hover-bg-red:hover { background: #fef2f2; color: #dc2626; }

/* LAYOUT E DISTINÇÕES VISUAIS */
.icon-chip { width: 24px; height: 24px; border-radius: 6px; display: flex; align-items: center; justify-content: center; }
.slide-number { width: 24px; height: 24px; background: #e2e8f0; color: #475569; font-size: 12px; font-weight: 800; display: flex; align-items: center; justify-content: center; border-radius: 6px; }
.section-badge { position: absolute; top: -10px; left: 12px; font-size: 10px; font-weight: 800; text-transform: uppercase; padding: 2px 8px; border-radius: 12px; letter-spacing: 0.05em; border: 1px solid rgba(0,0,0,0.05); }

/* UPLOAD DE IMAGEM THUMBNAIL */
.image-thumb-container { position: relative; width: 100%; height: 100px; border-radius: 8px; border: 1px solid #e2e8f0; overflow: hidden; background: #f1f5f9; }
.image-thumb { width: 100%; height: 100%; display: block; }
.btn-thumb-delete { position: absolute; top: 6px; right: 6px; width: 24px; height: 24px; border-radius: 50%; background: rgba(255,255,255,0.9); backdrop-filter: blur(4px); display: flex; align-items: center; justify-content: center; color: #ef4444; border: 1px solid rgba(0,0,0,0.1); cursor: pointer; transition: 0.2s; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
.btn-thumb-delete:hover { background: #ef4444; color: white; transform: scale(1.1); }

/* VUETIFY OVERRIDES */
.vuetify-override-container :deep(.v-field) { border-radius: 8px !important; border: 1px solid #cbd5e1 !important; box-shadow: inset 0 1px 2px rgba(0,0,0,0.02) !important; background: #ffffff !important; }
.vuetify-override-container :deep(.v-field__outline) { display: none !important; }
.vuetify-override-container :deep(.v-field__input) { min-height: 36px !important; padding-top: 0 !important; padding-bottom: 0 !important; font-size: 13px !important; font-weight: 500 !important; }


/* ==========================================
   ANIMAÇÕES E PREVIEW CANVAS
   ========================================== */
.hero-preview { transition: outline 0.2s; outline: 2px solid transparent; outline-offset: -2px; cursor: pointer; }
.hero-preview:hover { outline-color: rgba(var(--v-theme-primary), 0.4); }
.active-outline { outline-color: rgb(var(--v-theme-primary)) !important; box-shadow: inset 0 0 0 4px rgba(var(--v-theme-primary), 0.2); z-index: 2; }
.carousel-track { position: absolute; top: 0; left: 0; width: 100%; height: 100%; }
.slide-layer { position: absolute; top: 0; left: 0; width: 100%; height: 100%; display: flex; flex-direction: column; align-items: center; justify-content: center; }

.mobile-aspect-helper { display: none; }
.mobile-actual-bg { display: none; }
.mobile-overlay { display: none; }
.content-wrapper { position: relative; z-index: 10; }

/* FIX INFALÍVEL DE TRANSICAO E RESPONSIVIDADE NO MOBILE */
@media (max-width: 599px) {
  .hero-preview[style] {
    height: auto !important;
    min-height: unset !important;
    padding: 0 !important;
  }

  .mobile-aspect-helper {
    display: block !important;
    width: 100%;
    height: auto;
    visibility: hidden; /* Dita a altura da caixa, mas não aparece */
    pointer-events: none;
  }

  /* O container das animações DEVE ser absolute ocupando o espaço que o helper abriu */
  .carousel-track {
    position: absolute !important;
    top: 0; left: 0; right: 0; bottom: 0;
    width: 100%; height: 100%;
  }

  /* As camadas do slide TEM QUE SER absolute para não empurrarem o layout no fade */
  .slide-layer {
    position: absolute !important;
    top: 0; left: 0; right: 0; bottom: 0;
    width: 100%; height: 100% !important;
    background: none !important; /* Desativa a imagem de fundo CSS (cover) */
  }

  /* A imagem real daquele slide ocupa a área 100% que o helper abriu */
  .mobile-actual-bg {
    display: block !important;
    position: absolute;
    top: 0; left: 0;
    width: 100%;
    height: 100%;
    object-fit: cover; /* Cover numa caixa com a proporção exata da foto não corta NADA */
    z-index: 0;
  }

  .mobile-overlay {
    display: block !important;
    position: absolute;
    inset: 0;
    z-index: 1;
  }

  .content-wrapper {
    position: absolute !important;
    inset: 0;
    z-index: 10;
    padding: 24px 16px !important;
    display: flex;
    flex-direction: column;
    justify-content: center;
  }

  /* Reduz os textos no celular pra caberem direito sobre a imagem */
  .text-sm-h2 { font-size: 2rem !important; }
  .text-md-h5 { font-size: 1.1rem !important; line-height: 1.4 !important; }
  .responsive-hero-btn { width: 100%; margin-top: 16px !important; }
}

.glass-kicker { background: rgba(255, 255, 255, 0.05); backdrop-filter: blur(10px); border-color: rgba(255, 255, 255, 0.2) !important; }
.effect-none { text-shadow: none !important; }
.effect-shadow-soft { text-shadow: 0 4px 12px rgba(0,0,0,0.4); }
.effect-shadow-hard { text-shadow: 0 4px 8px rgba(0,0,0,0.9), 0 2px 4px rgba(0,0,0,0.8); }
.effect-glow { text-shadow: 0 0 10px currentColor, 0 0 20px currentColor, 0 0 40px rgba(0,0,0,0.5); }
.content-wrapper { opacity: 0; animation-fill-mode: forwards; }
.anim-fade-up { animation: textFadeUp 0.8s cubic-bezier(0.16, 1, 0.3, 1) 0.2s forwards; }
@keyframes textFadeUp { from { opacity: 0; transform: translateY(40px); } to { opacity: 1; transform: translateY(0); } }
.anim-slide-left { animation: textSlideLeft 0.8s cubic-bezier(0.16, 1, 0.3, 1) 0.2s forwards; }
@keyframes textSlideLeft { from { opacity: 0; transform: translateX(80px); } to { opacity: 1; transform: translateX(0); } }
.anim-zoom-in { animation: textZoomIn 0.8s cubic-bezier(0.16, 1, 0.3, 1) 0.2s forwards; }
@keyframes textZoomIn { from { opacity: 0; transform: scale(0.8); } to { opacity: 1; transform: scale(1); } }
.anim-fade { animation: textFade 1s ease 0.2s forwards; }
@keyframes textFade { from { opacity: 0; } to { opacity: 1; } }
.fade-enter-active, .fade-leave-active { transition: opacity 1s ease-in-out; }
.fade-enter-from, .fade-leave-to { opacity: 0; }
.slide-x-enter-active, .slide-x-leave-active { transition: all 0.8s cubic-bezier(0.4, 0, 0.2, 1); }
.slide-x-enter-from { transform: translateX(100%); opacity: 0; }
.slide-x-leave-to { transform: translateX(-100%); opacity: 0; }
.zoom-enter-active, .zoom-leave-active { transition: all 1.2s ease-out; }
.zoom-enter-from { transform: scale(1.1); opacity: 0; }
.zoom-leave-to { transform: scale(0.95); opacity: 0; }
.hover-lift { transition: transform 0.25s cubic-bezier(0.4, 0, 0.2, 1), box-shadow 0.25s cubic-bezier(0.4, 0, 0.2, 1); }
.hover-lift:hover { transform: translateY(-4px); box-shadow: 0 20px 40px rgba(0,0,0,0.2) !important; }
.carousel-nav { position: absolute; bottom: 24px; left: 50%; transform: translateX(-50%); display: flex; align-items: center; padding: 4px 16px; border-radius: 40px; background: rgba(0, 0, 0, 0.25); backdrop-filter: blur(8px); }
.dot { width: 8px; height: 8px; border-radius: 50%; background: rgba(255, 255, 255, 0.4); cursor: pointer; transition: all 0.3s; }
.dot:hover { background: rgba(255, 255, 255, 0.8); }
.dot.active { background: white; transform: scale(1.4); }
</style>
