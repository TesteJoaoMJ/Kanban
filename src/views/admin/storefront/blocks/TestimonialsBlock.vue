<template>
  <div v-if="mode === 'settings'" class="premium-testimonials-settings d-flex flex-column gap-6">

    <div class="mac-card">
      <div class="mac-card-header d-flex align-center gap-2 border-b">
        <div class="icon-chip bg-purple text-white"><v-icon size="14">mdi-format-quote-close</v-icon></div>
        <span class="fw-700 text-sm text-dark">Cabeçalho da Seção</span>
      </div>
      <div class="mac-card-body d-flex flex-column gap-3 bg-lightest">
        <div class="p-4 bg-white border rounded-md shadow-xs d-flex flex-column gap-3">
          <div>
            <label class="premium-label">Título Principal</label>
            <input type="text" v-model="block.settings.title" class="premium-input" placeholder="Ex: O que dizem sobre nós" />
          </div>
          <div>
            <label class="premium-label">Subtítulo (Kicker)</label>
            <input type="text" v-model="block.settings.subtitle" class="premium-input" placeholder="Ex: Prova Social" />
          </div>
          <div>
            <label class="premium-label">Texto de Apoio</label>
            <textarea v-model="block.settings.text" rows="2" class="premium-input" style="height: auto; padding-top: 8px;" placeholder="Contextualize as avaliações..."></textarea>
          </div>
        </div>
      </div>
    </div>

    <div class="mac-card">
      <div class="mac-card-header d-flex align-center justify-space-between border-b">
        <div class="d-flex align-center gap-2">
          <div class="icon-chip bg-primary text-white"><v-icon size="14">mdi-comment-account-outline</v-icon></div>
          <span class="fw-700 text-sm text-dark">Depoimentos</span>
        </div>
        <v-btn size="x-small" color="primary" variant="tonal" class="font-weight-bold text-none rounded" @click="addTestimonial">
          <v-icon start size="14">mdi-plus</v-icon> Adicionar
        </v-btn>
      </div>

      <div class="mac-card-body d-flex flex-column gap-4 bg-lightest">
        <transition-group name="list-anim">
          <div v-for="(test, tIndex) in (block.settings.testimonials_list || [])" :key="tIndex" class="p-4 bg-white border rounded-md shadow-xs relative">

            <div class="d-flex justify-space-between align-center mb-3 pb-2 border-b">
              <span class="text-xs fw-800 text-primary text-uppercase tracking-widest">Avaliação {{ tIndex + 1 }}</span>
              <v-btn icon size="x-small" color="error" variant="text" @click="removeTestimonial(tIndex)" density="comfortable"><v-icon size="16">mdi-close</v-icon></v-btn>
            </div>

            <div class="d-flex flex-column gap-3">
              <div class="d-flex gap-3">
                <div class="flex-1">
                  <label class="premium-label">Nome / Empresa</label>
                  <input type="text" v-model="test.author" class="premium-input" placeholder="Ex: Maria S." />
                </div>
                <div class="flex-1">
                  <label class="premium-label">Cargo / Função</label>
                  <input type="text" v-model="test.role" class="premium-input" placeholder="Ex: Estilista" />
                </div>
              </div>

              <div>
                <label class="premium-label">Depoimento</label>
                <textarea v-model="test.text" rows="3" class="premium-input" style="height: auto; padding-top: 8px;" placeholder="Escreva a avaliação aqui..."></textarea>
              </div>

              <div>
                <label class="premium-label d-flex justify-space-between align-center">
                  <span>Nota (Estrelas)</span>
                  <span class="text-amber font-weight-black"><v-icon size="14" class="mb-1">mdi-star</v-icon> {{ test.rating || 5 }}</span>
                </label>
                <input type="range" v-model.number="test.rating" min="1" max="5" step="1" class="w-100 premium-range text-amber" />
              </div>
            </div>

          </div>
        </transition-group>

        <div v-if="!block.settings.testimonials_list || block.settings.testimonials_list.length === 0" class="text-center py-6 opacity-40 border border-dashed rounded-lg bg-white">
          <v-icon size="24" class="mb-2">mdi-comment-off-outline</v-icon>
          <div class="text-caption font-weight-medium">Nenhum depoimento adicionado.</div>
        </div>
      </div>
    </div>

    <div class="mac-card">
      <div class="mac-card-header d-flex align-center gap-2 border-b">
        <div class="icon-chip bg-green text-white"><v-icon size="14">mdi-palette-outline</v-icon></div>
        <span class="fw-700 text-sm text-dark">Design e Cores</span>
      </div>

      <div class="mac-card-body d-flex flex-column gap-4 bg-lightest">

        <div>
          <label class="premium-label">Fonte da Seção</label>
          <select v-model="block.settings.font_family" class="premium-input">
            <option value="'Inter', sans-serif">Inter (Moderno)</option>
            <option value="'Montserrat', sans-serif">Montserrat (Geométrico)</option>
            <option value="'Playfair Display', serif">Playfair Display (Elegante)</option>
            <option value="'Bebas Neue', sans-serif">Bebas Neue (Impacto)</option>
          </select>
        </div>

        <div class="p-3 bg-white border rounded-md shadow-xs d-flex flex-column gap-3">
          <span class="text-xs fw-800 text-dark text-uppercase tracking-widest border-b pb-2">Seção Geral</span>

          <div class="d-flex gap-3">
            <div class="flex-1">
              <label class="premium-label">Fundo da Seção</label>
              <div class="color-input-wrapper">
                <input type="color" v-model="block.settings.bg_color" class="color-swatch-sm" />
                <input type="text" v-model="block.settings.bg_color" class="color-hex-input" placeholder="#f8fafc" />
              </div>
            </div>
            <div class="flex-1">
              <label class="premium-label">Cor dos Títulos</label>
              <div class="color-input-wrapper">
                <input type="color" v-model="block.settings.text_color" class="color-swatch-sm" />
                <input type="text" v-model="block.settings.text_color" class="color-hex-input" placeholder="#0f172a" />
              </div>
            </div>
          </div>
        </div>

        <div class="p-3 bg-white border rounded-md shadow-xs d-flex flex-column gap-3">
          <span class="text-xs fw-800 text-dark text-uppercase tracking-widest border-b pb-2">Cards de Depoimento</span>

          <div class="d-flex gap-3">
            <div class="flex-1">
              <label class="premium-label">Fundo do Card</label>
              <div class="color-input-wrapper">
                <input type="color" v-model="block.settings.card_bg_color" class="color-swatch-sm" />
                <input type="text" v-model="block.settings.card_bg_color" class="color-hex-input" placeholder="#ffffff" />
              </div>
            </div>
            <div class="flex-1">
              <label class="premium-label">Texto do Card</label>
              <div class="color-input-wrapper">
                <input type="color" v-model="block.settings.card_text_color" class="color-swatch-sm" />
                <input type="text" v-model="block.settings.card_text_color" class="color-hex-input" placeholder="#0f172a" />
              </div>
            </div>
          </div>
        </div>

      </div>
    </div>

  </div>

  <section v-else
           :id="`block-preview-${block._id}`"
           class="preview-engine testimonials-section section-padding px-8"
           :class="[{ 'active-outline': isActive }]"
           :style="{
             backgroundColor: block.settings.bg_color || '#f8fafc',
             fontFamily: block.settings.font_family || `'Inter', sans-serif`
           }">

    <div class="max-w-1200 mx-auto w-100">

      <div class="text-center mb-16" :style="{ color: block.settings.text_color || '#0f172a' }">
         <div v-if="block.settings.subtitle" class="font-weight-bold text-caption text-uppercase tracking-widest mb-3" :style="{ color: block.settings.text_color ? `${block.settings.text_color}b3` : 'var(--v-theme-primary)' }">
           {{ block.settings.subtitle }}
         </div>
         <h2 class="text-h3 text-md-h2 font-weight-black m-0 tracking-tighter">{{ block.settings.title || 'O que dizem sobre nós' }}</h2>
         <p v-if="block.settings.text" class="text-h6 mt-6 font-weight-regular max-w-800 mx-auto line-height-relaxed" :style="{ color: block.settings.text_color ? `${block.settings.text_color}b3` : 'rgba(15, 23, 42, 0.7)' }">
           {{ block.settings.text }}
         </p>
      </div>

      <div class="grid-mock-3">

         <div v-for="(test, tIndex) in getValidTestimonials" :key="tIndex"
              class="testimonial-card border rounded-2xl pa-8 pa-md-10 shadow-lg hover-lift position-relative overflow-hidden group"
              :style="{ backgroundColor: block.settings.card_bg_color || '#ffffff' }">

            <v-icon class="position-absolute water-mark-quote opacity-05 transition-opacity group-hover-opacity-10" :style="{ color: block.settings.card_text_color || '#0f172a' }">mdi-format-quote-open</v-icon>

            <div class="position-relative z-10 d-flex flex-column h-100">

              <div class="d-flex gap-1 mb-8">
                 <v-icon v-for="s in (test.rating || 5)" :key="s" color="amber-darken-1" size="22">mdi-star</v-icon>
                 <v-icon v-for="s in (5 - (test.rating || 5))" :key="`empty-${s}`" color="grey-lighten-2" size="22">mdi-star-outline</v-icon>
              </div>

              <p class="text-h6 mb-10 font-italic line-height-relaxed flex-grow-1" :style="{ color: block.settings.card_text_color || '#0f172a' }">
                "{{ test.text || 'Excelente trabalho e qualidade surpreendente. A entrega foi super rápida e o atendimento impecável.' }}"
              </p>

              <div class="d-flex align-center gap-4 pt-6 border-t" :style="{ borderColor: block.settings.card_text_color ? `${block.settings.card_text_color}1a` : 'rgba(0,0,0,0.1)' }">
                 <v-avatar color="primary" class="font-weight-bold rounded-lg text-h6 text-white shadow-sm" size="56">
                   {{ (test.author || 'Cliente').charAt(0).toUpperCase() }}
                 </v-avatar>
                 <div>
                   <div class="font-weight-black text-body-1 tracking-tight" :style="{ color: block.settings.card_text_color || '#0f172a' }">
                     {{ test.author || 'Nome do Cliente' }}
                   </div>
                   <div class="text-caption mt-1 font-weight-medium text-uppercase tracking-widest" :style="{ color: block.settings.card_text_color ? `${block.settings.card_text_color}99` : 'rgba(15, 23, 42, 0.6)' }">
                     {{ test.role || 'Cargo / Empresa' }}
                   </div>
                 </div>
              </div>

            </div>
         </div>

      </div>
    </div>
  </section>
</template>

<script setup lang="ts">
import { computed, onMounted } from 'vue'

const props = defineProps<{
  mode: 'settings' | 'preview'
  block: any
  isActive?: boolean
}>()

// INIT DEFAULT SETTINGS
onMounted(() => {
  if (props.mode === 'settings') {
    if (props.block.settings.font_family === undefined) props.block.settings.font_family = "'Inter', sans-serif"
    if (props.block.settings.bg_color === undefined) props.block.settings.bg_color = '#f8fafc'
    if (props.block.settings.text_color === undefined) props.block.settings.text_color = '#0f172a'
    if (props.block.settings.card_bg_color === undefined) props.block.settings.card_bg_color = '#ffffff'
    if (props.block.settings.card_text_color === undefined) props.block.settings.card_text_color = '#0f172a'
  }
})

function addTestimonial() {
  if (!props.block.settings.testimonials_list) props.block.settings.testimonials_list = []
  props.block.settings.testimonials_list.push({ author: '', role: '', text: '', rating: 5 })
}

function removeTestimonial(index: number) {
  props.block.settings.testimonials_list.splice(index, 1)
}

// Retorna uma lista padrão caso o usuário não tenha adicionado nada ainda, para não ficar buraco no canvas
const getValidTestimonials = computed(() => {
  const list = props.block.settings.testimonials_list
  if (!list || list.length === 0) {
    return [
      { author: 'Marca X', role: 'Estilista Chefe', text: 'Os tecidos são impecáveis e a resolução da estamparia elevou muito o nível da nossa nova coleção de alto verão.', rating: 5 },
      { author: 'João C.', role: 'Diretor Criativo', text: 'A melhor parceria que já fizemos. Além da qualidade do corte a laser, o sistema deles para visualizar as estampas é surreal.', rating: 5 },
      { author: 'Boutique Y', role: 'Comercial', text: 'Agilidade na entrega e um catálogo absurdamente vasto. Nunca mais tivemos problemas com ruptura de estoque.', rating: 4 }
    ]
  }
  return list
})
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Bebas+Neue&family=Inter:wght@400;500;600;700;800&family=Montserrat:wght@400;700;900&family=Playfair+Display:ital,wght@0,400;0,700;0,900;1,400&display=swap');

/* ==========================================
   UI CUSTOMIZADA PREMIUM (SETTINGS)
   ========================================== */
.premium-testimonials-settings { font-family: 'Inter', sans-serif; }
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
.premium-range { accent-color: #f59e0b; cursor: pointer; height: 6px; border-radius: 4px; }

/* Color Picker Retangular (Padrão Zigzag/MacOS) */
.color-input-wrapper { display: flex; align-items: center; gap: 8px; height: 36px; padding: 0 8px; background: #ffffff; border: 1px solid #cbd5e1; border-radius: 8px; box-shadow: inset 0 1px 2px rgba(0,0,0,0.02); transition: all 0.2s ease; }
.color-input-wrapper:focus-within { border-color: #3b82f6; box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.15); }
.color-swatch-sm { -webkit-appearance: none; appearance: none; width: 20px; height: 20px; border: 1px solid #e2e8f0; border-radius: 4px; padding: 0; cursor: pointer; background: transparent; }
.color-swatch-sm::-webkit-color-swatch-wrapper { padding: 0; }
.color-swatch-sm::-webkit-color-swatch { border: none; border-radius: 3px; }
.color-hex-input { border: none; outline: none; background: transparent; font-size: 13px; font-weight: 500; color: #1e293b; width: 100%; text-transform: uppercase; }

/* Animação lista */
.list-anim-enter-active, .list-anim-leave-active { transition: all 0.3s ease; }
.list-anim-enter-from, .list-anim-leave-to { opacity: 0; transform: scale(0.95); }

/* ==========================================
   ESTILOS DO PREVIEW (CANVAS)
   ========================================== */
.preview-engine { transition: background-color 0.3s ease; outline: 2px solid transparent; outline-offset: -2px; cursor: pointer; }
.preview-engine:hover { outline-color: rgba(var(--v-theme-primary), 0.3); }
.active-outline { outline-color: rgb(var(--v-theme-primary)) !important; box-shadow: inset 0 0 0 4px rgba(var(--v-theme-primary), 0.1); position: relative; z-index: 10; }

.section-padding { padding-top: clamp(60px, 8vw, 120px); padding-bottom: clamp(60px, 8vw, 120px); }
.max-w-1200 { max-width: 1200px; }
.max-w-800 { max-width: 800px; }

.line-height-relaxed { line-height: 1.7; }

/* GRID DE DEPOIMENTOS */
.grid-mock-3 {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 32px;
  align-items: stretch; /* Garante que todos os cards fiquem com a mesma altura na linha */
}

@media(max-width: 1024px) {
  .grid-mock-3 { grid-template-columns: repeat(2, 1fr); }
}
@media(max-width: 768px) {
  .grid-mock-3 { grid-template-columns: 1fr; }
}

/* CARDS E INTERAÇÕES */
.testimonial-card {
  border-color: rgba(0,0,0,0.05) !important;
  transition: transform 0.4s cubic-bezier(0.16, 1, 0.3, 1), box-shadow 0.4s cubic-bezier(0.16, 1, 0.3, 1), background-color 0.3s ease;
}

.hover-lift { transition: transform 0.4s ease, box-shadow 0.4s ease; }
.hover-lift:hover {
  transform: translateY(-8px);
  box-shadow: 0 30px 60px -12px rgba(0, 0, 0, 0.15) !important;
}

/* MARCA D'ÁGUA DE ASPAS (Estilo de Revista) */
.water-mark-quote {
  top: -20px;
  right: -10px;
  font-size: 200px;
  line-height: 1;
  pointer-events: none;
  z-index: 0;
}
.opacity-05 { opacity: 0.03; }
.group-hover-opacity-10 { opacity: 0.08 !important; }
</style>
