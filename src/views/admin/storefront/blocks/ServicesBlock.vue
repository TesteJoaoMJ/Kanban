<template>
  <div v-if="mode === 'settings'" class="services-settings d-flex flex-column gap-6">

    <div class="config-group">
      <div class="config-header d-flex align-center gap-2">
        <v-icon size="16" color="primary">mdi-text-box-outline</v-icon>
        Apresentação da Seção
      </div>
      <div class="d-flex flex-column gap-4">
        <div>
          <label class="inspector-label">Título Principal</label>
          <input type="text" v-model="block.settings.title" class="modern-input" placeholder="Ex: Soluções Industriais" />
        </div>
        <div>
          <label class="inspector-label">Subtítulo (Kicker)</label>
          <input type="text" v-model="block.settings.subtitle" class="modern-input" placeholder="Ex: Parque Fabril" />
        </div>
        <div>
          <label class="inspector-label">Texto de Apoio</label>
          <textarea v-model="block.settings.text" rows="2" class="modern-input" style="resize:vertical;" placeholder="Explicar a infraestrutura..."></textarea>
        </div>
      </div>
    </div>

    <div class="config-group">
      <div class="config-header d-flex align-center justify-space-between">
        <div class="d-flex align-center gap-2">
          <v-icon size="16" color="primary">mdi-factory</v-icon>
          Serviços Oferecidos
        </div>
        <v-btn size="x-small" color="primary" variant="tonal" class="font-weight-bold text-none rounded" @click="addService" :disabled="(block.settings.services_list || []).length >= 6">
          <v-icon start size="14">mdi-plus</v-icon> Novo
        </v-btn>
      </div>

      <div class="d-flex flex-column gap-4 mt-2">
        <transition-group name="list-anim">
          <div v-for="(srv, sIndex) in (block.settings.services_list || [])" :key="sIndex" class="pa-4 border rounded-xl bg-background shadow-sm position-relative">

            <div class="d-flex justify-space-between align-center mb-4 border-b pb-2">
              <span class="text-caption font-weight-black text-primary text-uppercase tracking-widest">Serviço {{ sIndex + 1 }}</span>
              <v-btn icon size="x-small" color="error" variant="text" @click="removeService(sIndex)"><v-icon size="18">mdi-close</v-icon></v-btn>
            </div>

            <div class="d-flex flex-column gap-3">
              <div>
                <label class="inspector-label">Nome do Serviço</label>
                <input type="text" v-model="srv.title" class="modern-input" placeholder="Ex: Corte a Laser" />
              </div>

              <div>
                <label class="inspector-label">Descrição</label>
                <textarea v-model="srv.text" rows="3" class="modern-input" style="resize:vertical;" placeholder="Detalhe as vantagens do serviço..."></textarea>
              </div>

              <div>
                <label class="inspector-label d-flex justify-space-between align-center">
                  Ícone MDI (Material Design)
                  <a href="https://pictogrammers.com/library/mdi/" target="_blank" class="text-[10px] text-primary text-decoration-underline">Ver Lista</a>
                </label>
                <div class="d-flex gap-2">
                  <div class="bg-surface border rounded-lg d-flex align-center justify-center flex-shrink-0" style="width: 44px; height: 44px;">
                    <v-icon :color="srv.icon_color || block.settings.primary_color || 'primary'">{{ srv.icon || 'mdi-cube-outline' }}</v-icon>
                  </div>
                  <input type="text" v-model="srv.icon" class="modern-input flex-grow-1" placeholder="Ex: mdi-laser-pointer" />
                </div>
              </div>

              <div>
                <label class="inspector-label">Cor do Ícone (Hex)</label>
                <input type="color" v-model="srv.icon_color" class="color-picker" />
              </div>
            </div>

          </div>
        </transition-group>

        <div v-if="!block.settings.services_list || block.settings.services_list.length === 0" class="text-center py-6 opacity-40 border border-dashed rounded-lg">
          <v-icon size="24" class="mb-2">mdi-cogs</v-icon>
          <div class="text-caption font-weight-medium">Nenhum serviço adicionado.</div>
        </div>
      </div>
    </div>

    <div class="config-group">
      <div class="config-header d-flex align-center gap-2">
        <v-icon size="16" color="primary">mdi-palette</v-icon>
        Design Global
      </div>
      <div class="d-flex flex-column gap-4">
        <div class="d-flex align-center gap-3">
          <label class="inspector-label m-0 flex-grow-1">Fundo da Seção</label>
          <input type="color" v-model="block.settings.bg_color" class="color-picker" />
        </div>
        <div class="d-flex align-center gap-3">
          <label class="inspector-label m-0 flex-grow-1">Fundo dos Cards</label>
          <input type="color" v-model="block.settings.card_bg_color" class="color-picker" />
        </div>
        <div class="d-flex align-center gap-3">
          <label class="inspector-label m-0 flex-grow-1">Cor dos Textos</label>
          <input type="color" v-model="block.settings.text_color" class="color-picker" />
        </div>
      </div>
    </div>

  </div>

  <section v-else
           :id="`block-preview-${block._id}`"
           class="preview-section services-section section-padding px-8"
           :class="[{ 'active-outline': isActive }]"
           :style="{ backgroundColor: block.settings.bg_color || '#ffffff' }">

    <div class="max-w-1200 mx-auto w-100">

      <div class="text-center mb-16" :style="{ color: block.settings.text_color || '#111827' }">
         <div v-if="block.settings.subtitle" class="font-weight-bold text-caption text-uppercase tracking-widest mb-3 opacity-70 kicker-line">
           {{ block.settings.subtitle }}
         </div>
         <h2 class="text-h3 text-md-h2 font-weight-black m-0 tracking-tighter title-reveal">{{ block.settings.title || 'Soluções Industriais' }}</h2>
         <p v-if="block.settings.text" class="text-h6 mt-6 opacity-70 font-weight-regular max-w-800 mx-auto line-height-relaxed" style="white-space: pre-line;">
           {{ block.settings.text }}
         </p>
      </div>

      <div class="grid-services" :class="getGridColsClass()">

         <div v-for="(srv, sIndex) in getValidServices" :key="sIndex"
              class="service-card rounded-2xl pa-10 text-center transition-all hover-elevate border group"
              :style="{ backgroundColor: block.settings.card_bg_color || '#f8fafc', borderColor: 'rgba(0,0,0,0.03)' }">

            <div class="icon-wrapper mb-8 d-inline-flex align-center justify-center rounded-circle transition-all group-hover-bg"
                 :style="{ backgroundColor: 'rgba(0,0,0,0.03)', width: '96px', height: '96px' }">
               <v-icon size="48" :color="srv.icon_color || '#111827'" class="transition-transform group-hover-scale">
                 {{ srv.icon || 'mdi-check-circle-outline' }}
               </v-icon>
            </div>

            <h4 class="text-h5 font-weight-black mb-4 tracking-tighter" :style="{ color: block.settings.text_color || '#111827' }">
              {{ srv.title || 'Serviço Premium' }}
            </h4>

            <p class="text-body-1 opacity-70 m-0" style="line-height: 1.7;" :style="{ color: block.settings.text_color || '#111827' }">
              {{ srv.text || 'Descrição detalhada sobre a qualidade, agilidade e excelência que você entrega neste serviço específico.' }}
            </p>
         </div>

      </div>
    </div>
  </section>
</template>

<script setup lang="ts">
import { computed } from 'vue'

const props = defineProps<{
  mode: 'settings' | 'preview'
  block: any
  isActive?: boolean
}>()

function addService() {
  if (!props.block.settings.services_list) props.block.settings.services_list = []
  props.block.settings.services_list.push({ title: '', text: '', icon: 'mdi-star-outline', icon_color: '#3b82f6' })
}

function removeService(index: number) {
  props.block.settings.services_list.splice(index, 1)
}

// Retorna lista padrão para Preview se estiver vazio
const getValidServices = computed(() => {
  const list = props.block.settings.services_list
  if (!list || list.length === 0) {
    return [
      { title: 'Estamparia Digital', text: 'Alta definição em bases sintéticas e naturais com fidelidade de cores impressionante, utilizando tintas certificadas.', icon: 'mdi-printer-3d', icon_color: '#3b82f6' },
      { title: 'Corte a Laser', text: 'Precisão milimétrica e selagem de bordas para peças prontas para a costura rápida, sem desperdício de tecido.', icon: 'mdi-laser-pointer', icon_color: '#06b6d4' },
      { title: 'Private Label', text: 'Desenvolvimento de produtos acabados (cangas, lenços, pareôs) embalados e com a etiqueta da sua marca.', icon: 'mdi-beach', icon_color: '#f59e0b' }
    ]
  }
  return list
})

// Ajusta a quantidade de colunas do grid dependendo do número de serviços (para sempre ficar harmônico)
function getGridColsClass() {
  const len = getValidServices.value.length
  if (len === 1) return 'grid-cols-1 max-w-600 mx-auto'
  if (len === 2 || len === 4) return 'grid-cols-2 max-w-1000 mx-auto'
  return 'grid-cols-3' // Ideal para 3 ou 6
}
</script>

<style scoped>
/* ==========================================
   ESTILOS DO INSPECTOR (SETTINGS)
   ========================================== */
.config-group { border: 1px solid rgba(var(--v-theme-on-surface), 0.08); border-radius: 12px; padding: 20px; background: rgba(var(--v-theme-surface), 0.8); backdrop-filter: blur(8px); }
.config-header { font-size: 12px; font-weight: 800; margin-bottom: 20px; color: rgb(var(--v-theme-on-surface)); text-transform: uppercase; letter-spacing: 0.08em; border-bottom: 1px solid rgba(var(--v-theme-on-surface), 0.06); padding-bottom: 12px; }
.inspector-label { display: block; font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.06em; margin-bottom: 8px; color: rgba(var(--v-theme-on-surface), 0.7); }

.modern-input { min-height: 44px; width: 100%; border: 1px solid rgba(var(--v-theme-on-surface), 0.15); background: rgb(var(--v-theme-surface)); border-radius: 8px; transition: all 0.2s; font-size: 14px; padding: 0 14px; }
.modern-input:focus { border-color: rgb(var(--v-theme-primary)); outline: none; box-shadow: 0 0 0 4px rgba(var(--v-theme-primary), 0.1); }
textarea.modern-input { padding-top: 12px; }
.color-picker { width: 100%; height: 44px; border-radius: 8px; border: 1px solid rgba(var(--v-theme-on-surface), 0.15); cursor: pointer; }

/* Animação para a lista de itens no painel lateral */
.list-anim-enter-active, .list-anim-leave-active { transition: all 0.3s ease; }
.list-anim-enter-from, .list-anim-leave-to { opacity: 0; transform: scale(0.95); }

/* ==========================================
   ESTILOS DO PREVIEW (CANVAS)
   ========================================== */
.services-section { transition: all 0.4s ease; outline: 2px solid transparent; outline-offset: -2px; cursor: pointer; }
.services-section:hover { outline-color: rgba(var(--v-theme-primary), 0.4); }
.active-outline { outline-color: rgb(var(--v-theme-primary)) !important; box-shadow: inset 0 0 0 4px rgba(var(--v-theme-primary), 0.2); z-index: 2; }

.section-padding { padding-top: 120px; padding-bottom: 120px; }
.kicker-line { color: rgb(var(--v-theme-primary)); }
.line-height-relaxed { line-height: 1.7; }

/* GRID DE SERVIÇOS */
.grid-services { display: grid; gap: 32px; align-items: stretch; }
.grid-cols-1 { grid-template-columns: 1fr; }
.grid-cols-2 { grid-template-columns: repeat(2, 1fr); }
.grid-cols-3 { grid-template-columns: repeat(3, 1fr); }

@media(max-width: 960px) {
  .grid-cols-3 { grid-template-columns: repeat(2, 1fr); }
}
@media(max-width: 600px) {
  .grid-services { grid-template-columns: 1fr !important; }
  .section-padding { padding-top: 80px; padding-bottom: 80px; }
}

/* CARDS E INTERAÇÕES */
.hover-elevate { transition: transform 0.3s cubic-bezier(0.16, 1, 0.3, 1), box-shadow 0.3s cubic-bezier(0.16, 1, 0.3, 1); }
.hover-elevate:hover {
  transform: translateY(-8px);
  box-shadow: 0 30px 60px -12px rgba(0, 0, 0, 0.12) !important;
}

/* ÍCONE */
.icon-wrapper { transition: background-color 0.4s ease; }
.group:hover .group-hover-bg { background-color: rgba(0,0,0,0.06) !important; }

.group-hover-scale { transition: transform 0.4s cubic-bezier(0.16, 1, 0.3, 1); }
.group:hover .group-hover-scale { transform: scale(1.15); }
</style>
