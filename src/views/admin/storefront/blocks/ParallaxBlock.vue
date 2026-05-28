<template>
  <div v-if="mode === 'settings'" class="parallax-block-settings d-flex flex-column gap-6">

    <div class="config-group">
      <div class="config-header d-flex align-center gap-2">
        <v-icon size="16" color="primary">mdi-format-text</v-icon>
        Conteúdo da Chamada
      </div>
      <div class="d-flex flex-column gap-4">
        <div>
          <label class="inspector-label">Título de Impacto</label>
          <input type="text" v-model="block.settings.title" class="modern-input" placeholder="Ex: Crie peças únicas hoje." />
        </div>
        <div>
          <label class="inspector-label">Texto de Apoio</label>
          <textarea v-model="block.settings.text" rows="3" class="modern-input" style="resize:vertical;" placeholder="Deixe um recado final inspirador para o cliente..."></textarea>
        </div>
      </div>
    </div>

    <div class="config-group">
      <div class="config-header d-flex align-center gap-2">
        <v-icon size="16" color="primary">mdi-cursor-default-click</v-icon>
        Botão de Ação (CTA)
      </div>
      <div class="d-flex flex-column gap-4">
        <div>
          <label class="inspector-label">Texto do Botão (Vazio = Oculto)</label>
          <input type="text" v-model="block.settings.button_text" class="modern-input" placeholder="Ex: Falar com Especialista" />
        </div>
        <div>
          <label class="inspector-label">Link de Destino</label>
          <input type="text" v-model="block.settings.button_link" class="modern-input" placeholder="Ex: /contato" />
        </div>
      </div>
    </div>

    <div class="config-group">
      <div class="config-header d-flex align-center gap-2">
        <v-icon size="16" color="primary">mdi-panorama-variant-outline</v-icon>
        Imagem Parallax
      </div>
      <div class="d-flex flex-column gap-4">
        <div>
          <label class="inspector-label">Origem do Fundo</label>
          <select v-model="block.settings.bg_type" class="modern-input px-3">
            <option value="upload">Upload de Imagem (Recomendado)</option>
            <option value="catalog">Estampa do Catálogo</option>
          </select>
        </div>

        <div v-if="block.settings.bg_type === 'upload' || !block.settings.bg_type">
          <label class="inspector-label">Upload de Fundo</label>
          <div v-if="block.settings.bg_url" class="rounded-lg border overflow-hidden bg-background d-flex flex-column mb-3 shadow-sm">
            <img :src="block.settings.bg_url" style="height: 120px; width: 100%; object-fit: cover;" />
            <v-btn size="small" color="error" variant="flat" class="rounded-0 text-none" block @click="block.settings.bg_url = ''">Remover</v-btn>
          </div>
          <v-btn v-else block color="primary" variant="tonal" class="text-none font-weight-bold rounded-lg border-dashed border-primary" style="border-width: 1px;" prepend-icon="mdi-cloud-upload-outline" @click="$emit('upload', 'bg_url')">
            Enviar Imagem de Alta Resolução
          </v-btn>
        </div>

        <div v-if="block.settings.bg_type === 'catalog'">
          <label class="inspector-label">Vincular Estampa</label>
          <v-autocomplete
            v-model="block.settings.bg_stamp_id"
            :items="stamps"
            item-title="title"
            item-value="id"
            group-by="category_name"
            variant="outlined"
            density="compact"
            hide-details
            class="bg-surface rounded-lg custom-autocomplete"
            placeholder="Busque com foto...">
            <template v-slot:item="{ props, item }">
              <v-list-item v-bind="props" :title="item.raw.title">
                <template v-slot:prepend>
                  <v-avatar rounded="lg" size="40" class="mr-3 border"><v-img :src="item.raw.main_image_url" cover></v-img></v-avatar>
                </template>
              </v-list-item>
            </template>
          </v-autocomplete>
        </div>

        <div>
          <label class="inspector-label d-flex justify-space-between">
            Filtro de Escurecimento
            <span class="text-primary font-weight-black">{{ ((block.settings.overlay_opacity !== undefined ? block.settings.overlay_opacity : 0.6) * 100).toFixed(0) }}%</span>
          </label>
          <input type="range" v-model.number="block.settings.overlay_opacity" min="0" max="0.9" step="0.1" class="w-100 modern-range" />
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
          <label class="inspector-label m-0 flex-grow-1">Cor do Texto</label>
          <input type="color" v-model="block.settings.text_color" class="color-picker" />
        </div>
        <div class="d-flex align-center gap-3">
          <label class="inspector-label m-0 flex-grow-1">Cor do Botão</label>
          <input type="color" v-model="block.settings.button_color" class="color-picker" />
        </div>
      </div>
    </div>

  </div>

  <section v-else
           :id="`block-preview-${block._id}`"
           class="preview-section parallax-section position-relative d-flex flex-column align-center justify-center text-center px-6 border-b"
           :class="[{ 'active-outline': isActive }]"
           :style="{
             minHeight: '70vh',
             backgroundImage: computedBgImage,
             color: block.settings.text_color || '#ffffff'
           }">

    <div class="z-10 w-100 position-relative content-reveal">

      <v-icon size="64" color="white" class="mb-8 opacity-70 drop-shadow">mdi-diamond-stone</v-icon>

      <h3 class="text-h3 text-md-h2 font-weight-black mb-6 tracking-tighter max-w-1000 mx-auto title-shadow" style="line-height: 1.1;">
        {{ block.settings.title || 'Título de Impacto' }}
      </h3>

      <p class="text-h6 text-md-h5 opacity-90 mb-12 max-w-800 mx-auto font-weight-light text-shadow" style="line-height: 1.8;">
        {{ block.settings.text || 'O texto de fechamento da sua home page. Use este bloco para inspirar o cliente a tomar a ação principal do seu site.' }}
      </p>

      <v-btn v-if="block.settings.button_text"
             :color="block.settings.button_color || 'white'"
             :class="utils.getTextColorClass(block.settings.button_color, 'white')"
             size="x-large"
             class="rounded-lg font-weight-bold text-none px-12 shadow-lg hover-lift"
             style="letter-spacing: 0.5px;">
        {{ block.settings.button_text }}
      </v-btn>

    </div>
  </section>
</template>

<script setup lang="ts">
import { computed, inject } from 'vue'

const props = defineProps<{
  mode: 'settings' | 'preview'
  block: any
  isActive?: boolean
  stamps?: any[]
}>()

const emit = defineEmits(['upload'])
const utils = inject<any>('builderUtils')

// Calcula o background com opacidade embutida no CSS (linear-gradient + url)
const computedBgImage = computed(() => {
  const opacity = props.block.settings.overlay_opacity !== undefined ? props.block.settings.overlay_opacity : 0.6

  if (props.block.settings.bg_type === 'catalog' && props.block.settings.bg_stamp_id && props.stamps) {
    const stamp = utils.getStampObj(props.block.settings.bg_stamp_id)
    if (stamp && stamp.main_image_url) {
      return `linear-gradient(rgba(0,0,0,${opacity}), rgba(0,0,0,${opacity})), url('${utils.getOptimizedUrl(stamp.main_image_url, 1920)}')`
    }
  }

  if (props.block.settings.bg_url) {
    return `linear-gradient(rgba(0,0,0,${opacity}), rgba(0,0,0,${opacity})), url('${utils.getOptimizedUrl(props.block.settings.bg_url, 1920)}')`
  }

  return `linear-gradient(rgba(0,0,0,${opacity}), rgba(0,0,0,${opacity})), url('https://images.unsplash.com/photo-1618220179428-22790b46a013?auto=format&fit=crop&w=1920')`
})
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
.modern-range { cursor: pointer; }

/* ==========================================
   ESTILOS DO PREVIEW (CANVAS)
   ========================================== */
.parallax-section {
  transition: outline 0.2s;
  outline: 2px solid transparent;
  outline-offset: -2px;
  cursor: pointer;

  /* A MÁGICA DO PARALLAX */
  background-attachment: fixed;
  background-position: center;
  background-repeat: no-repeat;
  background-size: cover;

  /* Previne falhas de renderização em alguns browsers mobile */
  transform: translateZ(0);
}
.parallax-section:hover { outline-color: rgba(var(--v-theme-primary), 0.4); }
.active-outline { outline-color: rgb(var(--v-theme-primary)) !important; box-shadow: inset 0 0 0 4px rgba(var(--v-theme-primary), 0.2); z-index: 2; }

/* SOMBRAS E LEGIBILIDADE */
.title-shadow { text-shadow: 0 10px 30px rgba(0,0,0,0.4); }
.text-shadow { text-shadow: 0 4px 12px rgba(0,0,0,0.5); }
.drop-shadow { filter: drop-shadow(0 4px 6px rgba(0,0,0,0.3)); }

/* INTERAÇÕES */
.hover-lift { transition: all 0.3s cubic-bezier(0.16, 1, 0.3, 1); }
.hover-lift:hover { transform: translateY(-4px); box-shadow: 0 20px 40px rgba(0,0,0,0.3) !important; }

/* REVEAL SUAVE NO RENDER */
.content-reveal {
  animation: slideUpFade 0.8s cubic-bezier(0.16, 1, 0.3, 1);
}
@keyframes slideUpFade {
  0% { opacity: 0; transform: translateY(20px); }
  100% { opacity: 1; transform: translateY(0); }
}

/* FIX PARA IOS (iOS tem problemas com background-attachment: fixed) */
@supports (-webkit-touch-callout: none) {
  .parallax-section {
    background-attachment: scroll; /* No iOS o efeito Parallax CSS nativo engasga, mudamos para scroll limpo */
  }
}
</style>
