<template>
  <section :id="sectionId" class="editorial-mosaic-section">

    <header v-if="settings.title" class="mosaic-header">
      <h2 class="mosaic-title">{{ settings.title }}</h2>
    </header>

    <div
      class="mosaic-grid"
      :class="`gap-${settings.gap_size || 'small'}`"
    >
      <div
        v-for="(item, index) in (settings.items || defaultItems)"
        :key="index"
        class="mosaic-item group"
        :style="{
          gridColumn: `span ${item.col_span || 1}`,
          gridRow: `span ${item.row_span || 1}`
        }"
      >
        <a v-if="item.link_url" :href="item.link_url" class="mosaic-link">
          <img :src="item.image_url" alt="Editorial" loading="lazy" class="mosaic-image" />
          <div class="mosaic-overlay">
            <span class="overlay-text">Descobrir</span>
          </div>
        </a>
        <div v-else class="mosaic-link">
          <img :src="item.image_url" alt="Editorial" loading="lazy" class="mosaic-image" />
        </div>
      </div>
    </div>

  </section>
</template>

<script setup lang="ts">
import { computed } from 'vue';
import type { EditorialMosaic } from '@/types/builder';

const props = defineProps<{
  sectionId: string;
  settings: EditorialMosaic['settings'];
}>();

// Itens de exemplo caso o Builder ainda não tenha enviado dados reais
const defaultItems = [
  { image_url: 'https://images.unsplash.com/photo-1618220179428-22790b46a0eb?q=80&w=800', link_url: null, col_span: 2, row_span: 2 },
  { image_url: 'https://images.unsplash.com/photo-1620799140188-3b2a02fd9a77?q=80&w=800', link_url: null, col_span: 1, row_span: 1 },
  { image_url: 'https://images.unsplash.com/photo-1574634534894-89d7576c8259?q=80&w=800', link_url: null, col_span: 1, row_span: 1 },
];
</script>

<style scoped>
.editorial-mosaic-section {
  padding: 64px 24px;
  max-width: 1440px;
  margin: 0 auto;
}

.mosaic-header {
  text-align: center;
  margin-bottom: 40px;
}

.mosaic-title {
  font-family: -apple-system, BlinkMacSystemFont, "SF Pro Display", sans-serif;
  font-size: clamp(24px, 4vw, 36px);
  font-weight: 700;
  color: #111;
  letter-spacing: -0.02em;
}

/* CSS Grid Base */
.mosaic-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
  grid-auto-rows: 300px; /* Altura base da linha */
  grid-auto-flow: dense; /* Preenche os buracos automaticamente */
}

/* Tamanhos de Espaçamento Controlados pelo Builder */
.gap-none { gap: 0; }
.gap-small { gap: 16px; }
.gap-medium { gap: 24px; }
.gap-large { gap: 40px; }

/* Item Individual */
.mosaic-item {
  position: relative;
  border-radius: 12px;
  overflow: hidden;
  background: #f4f4f5;
}

/* No mobile, forçamos os itens a não expandirem demasiadas colunas, quebrando o grid */
@media (max-width: 768px) {
  .mosaic-item {
    grid-column: span 1 !important;
    grid-row: span 1 !important;
  }
  .mosaic-grid {
    grid-auto-rows: 250px;
  }
}

.mosaic-link {
  display: block;
  width: 100%;
  height: 100%;
  position: relative;
}

.mosaic-image {
  width: 100%;
  height: 100%;
  object-fit: cover;
  transition: transform 0.7s cubic-bezier(0.25, 1, 0.5, 1);
}

.mosaic-item:hover .mosaic-image {
  transform: scale(1.05);
}

.mosaic-overlay {
  position: absolute;
  top: 0; left: 0; right: 0; bottom: 0;
  background: rgba(0, 0, 0, 0.2);
  display: flex;
  align-items: center;
  justify-content: center;
  opacity: 0;
  transition: opacity 0.3s ease;
}

.mosaic-item:hover .mosaic-overlay {
  opacity: 1;
}

.overlay-text {
  background: rgba(255, 255, 255, 0.9);
  color: #111;
  padding: 12px 24px;
  border-radius: 99px;
  font-size: 14px;
  font-weight: 600;
  transform: translateY(20px);
  transition: transform 0.4s cubic-bezier(0.25, 1, 0.5, 1);
}

.mosaic-item:hover .overlay-text {
  transform: translateY(0);
}
</style>
