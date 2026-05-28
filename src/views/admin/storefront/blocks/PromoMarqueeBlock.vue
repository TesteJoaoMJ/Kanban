<template>
  <div v-if="mode === 'settings'" class="marquee-block-settings d-flex flex-column gap-6">

    <div class="config-group">
      <div class="config-header d-flex align-center gap-2">
        <v-icon size="16" color="primary">mdi-message-text-outline</v-icon>
        Mensagem Rotativa
      </div>
      <div class="d-flex flex-column gap-4">
        <div>
          <label class="inspector-label">Texto da Promoção</label>
          <input type="text" v-model="block.settings.text" class="modern-input" placeholder="Ex: FRETE GRÁTIS PARA COMPRAS ACIMA DE R$ 1.500,00" />
          <p class="text-[10px] text-medium-emphasis mt-1 m-0">O texto será automaticamente repetido para criar o efeito infinito.</p>
        </div>
      </div>
    </div>

    <div class="config-group">
      <div class="config-header d-flex align-center gap-2">
        <v-icon size="16" color="primary">mdi-palette</v-icon>
        Cores da Faixa
      </div>
      <div class="d-flex flex-column gap-4">
        <div class="d-flex align-center gap-3">
          <label class="inspector-label m-0 flex-grow-1">Cor de Fundo</label>
          <input type="color" v-model="block.settings.bg_color" class="color-picker" />
        </div>

        <div class="d-flex align-center gap-3">
          <label class="inspector-label m-0 flex-grow-1">Cor do Texto</label>
          <input type="color" v-model="block.settings.text_color" class="color-picker" />
        </div>
      </div>
    </div>

  </div>

  <section v-else
           :id="`block-preview-${block._id}`"
           class="preview-section promo-marquee-section"
           :class="{ 'active-outline': isActive }"
           :style="{
             backgroundColor: block.settings.bg_color || '#000000',
             color: block.settings.text_color || '#ffffff'
           }">

    <div class="marquee-container py-2 cursor-pointer">
      <div class="marquee-content text-caption font-weight-black text-uppercase tracking-widest">
        <span class="marquee-item" v-for="n in 12" :key="n">
          {{ block.settings.text || 'CONFIGURE O TEXTO DA PROMOÇÃO NO PAINEL LATERAL' }}
          <span class="mx-6 opacity-30 text-h6 lh-1">•</span>
        </span>
      </div>
    </div>

  </section>
</template>

<script setup lang="ts">
const props = defineProps<{
  mode: 'settings' | 'preview'
  block: any
  isActive?: boolean
}>()
</script>

<style scoped>
/* ==========================================
   ESTILOS DO INSPECTOR (SETTINGS)
   ========================================== */
.config-group { border: 1px solid rgba(var(--v-theme-on-surface), 0.08); border-radius: 12px; padding: 20px; background: rgba(var(--v-theme-surface), 0.8); backdrop-filter: blur(8px); }
.config-header { font-size: 12px; font-weight: 800; margin-bottom: 20px; color: rgb(var(--v-theme-on-surface)); text-transform: uppercase; letter-spacing: 0.08em; border-bottom: 1px solid rgba(var(--v-theme-on-surface), 0.06); padding-bottom: 12px; }
.inspector-label { display: block; font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.06em; margin-bottom: 8px; color: rgba(var(--v-theme-on-surface), 0.7); }

.modern-input { min-height: 44px; width: 100%; border: 1px solid rgba(var(--v-theme-on-surface), 0.15); background: rgb(var(--v-theme-surface)); border-radius: 8px; transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1); font-size: 14px; color: rgb(var(--v-theme-on-surface)); padding: 0 14px; box-shadow: inset 0 1px 2px rgba(0,0,0,0.03); }
.modern-input:focus { border-color: rgb(var(--v-theme-primary)); box-shadow: 0 0 0 4px rgba(var(--v-theme-primary), 0.15); outline: none; }

.color-picker { width: 100%; height: 44px; border-radius: 8px; border: 1px solid rgba(var(--v-theme-on-surface), 0.15); padding: 4px; cursor: pointer; background: rgb(var(--v-theme-surface)); transition: border-color 0.2s; }
.color-picker:hover { border-color: rgb(var(--v-theme-primary)); }

/* ==========================================
   ESTILOS DO PREVIEW CANVAS
   ========================================== */
.promo-marquee-section {
  overflow: hidden;
  white-space: nowrap;
  transition: outline 0.2s;
  outline: 2px solid transparent;
  outline-offset: -2px;
  z-index: 10;
  position: relative;
  box-shadow: 0 2px 10px rgba(0,0,0,0.05);
}
.promo-marquee-section:hover { outline-color: rgba(var(--v-theme-primary), 0.4); }
.active-outline { outline-color: rgb(var(--v-theme-primary)) !important; box-shadow: inset 0 0 0 4px rgba(var(--v-theme-primary), 0.2); z-index: 12; }

.marquee-container {
  width: 100%;
  overflow: hidden;
  display: flex;
}

.marquee-content {
  display: inline-flex;
  align-items: center;
  /* Animação ultra suave com aceleração de hardware */
  will-change: transform;
  animation: marquee 35s linear infinite;
}

/* Efeito Premium: Pausa a animação ao passar o mouse para o cliente conseguir ler */
.marquee-container:hover .marquee-content {
  animation-play-state: paused;
}

.marquee-item {
  display: flex;
  align-items: center;
  letter-spacing: 0.15em; /* Tipografia espaçada típica de moda de luxo */
}

@keyframes marquee {
  0% { transform: translate3d(0, 0, 0); }
  /* Desloca 50% porque o conteúdo é dobrado, criando o loop perfeito */
  100% { transform: translate3d(-50%, 0, 0); }
}
</style>
