<template>
  <section :id="sectionId" class="discover-masonry-section">

    <header class="discover-header" v-if="settings.title || settings.subtitle">
      <h2 v-if="settings.title" class="discover-title">{{ settings.title }}</h2>
      <p v-if="settings.subtitle" class="discover-subtitle">{{ settings.subtitle }}</p>

      <div v-if="settings.show_filters" class="quick-filters">
        <button
          v-for="filter in ['Tudo', 'Florais', 'Geométricos', 'Abstratos', 'Infantil']"
          :key="filter"
          class="filter-chip"
          :class="{ active: activeFilter === filter }"
          @click="activeFilter = filter"
        >
          {{ filter }}
        </button>
      </div>
    </header>

    <div class="masonry-container" ref="masonryContainer">
      <div
        v-for="(column, colIndex) in columns"
        :key="`col-${colIndex}`"
        class="masonry-column"
      >
        <article
          v-for="stamp in column"
          :key="stamp.id"
          class="masonry-card group"
        >
          <div class="card-image-wrapper" :style="{ aspectRatio: stamp.aspectRatio }">
            <img :src="stamp.main_image_url" :alt="stamp.title" loading="lazy" class="card-image" />

            <div class="card-overlay">
              <button class="action-btn primary" @click="addToMoodboard(stamp)" title="Salvar no Moodboard">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"></path></svg>
                Salvar
              </button>
            </div>
          </div>

          <div class="card-footer">
            <h3 class="card-title">{{ stamp.title }}</h3>
            <span class="card-tags" v-if="stamp.tags && stamp.tags.length">
              {{ stamp.tags.slice(0, 2).join(', ') }}
            </span>
          </div>
        </article>
      </div>
    </div>

    <div ref="infiniteScrollTrigger" class="infinite-loading-zone">
      <div v-if="isLoading" class="loading-indicator">
        <div class="spinner"></div>
        <span>A descobrir mais estampas...</span>
      </div>
      <div v-else-if="hasReachedEnd" class="end-of-results">
        <span>Você viu tudo! Volte amanhã para novidades.</span>
      </div>
    </div>

  </section>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted, watch } from 'vue';
import { useMoodboardStore } from '@/stores/moodboard';
import type { CatalogStamp } from '@/types/builder';

// Tipagem estendida para suportar alturas dinâmicas no frontend (Pinterest style)
interface MasonryStamp extends CatalogStamp {
  aspectRatio: string;
}

const props = defineProps<{
  sectionId: string;
  settings: {
    title?: string;
    subtitle?: string;
    show_filters?: boolean;
    columns_desktop?: number;
  };
}>();

const moodboard = useMoodboardStore();
const activeFilter = ref('Tudo');

// ==========================================
// ESTADO DO MASONRY & INFINITE SCROLL
// ==========================================
const rawStamps = ref<MasonryStamp[]>([]);
const columns = ref<MasonryStamp[][]>([]);
const numColumns = ref(4);

const isLoading = ref(false);
const hasReachedEnd = ref(false);
let page = 1;

// Refs de DOM
const masonryContainer = ref<HTMLElement | null>(null);
const infiniteScrollTrigger = ref<HTMLElement | null>(null);
let observer: IntersectionObserver | null = null;

// ==========================================
// LÓGICA CORE: ALGORITMO MASONRY
// ==========================================
// Distribui os itens pela coluna mais curta no momento, para manter o grid denso e perfeito.
function distributeItemsToColumns() {
  // Limpar colunas
  const newCols: MasonryStamp[][] = Array.from({ length: numColumns.value }, () => []);
  // Arrays para rastrear a "altura" simulada de cada coluna
  const colHeights = new Array(numColumns.value).fill(0);

  rawStamps.value.forEach(stamp => {
    // Encontrar a coluna com menor altura acumulada
    let shortestColIndex = 0;
    let minHeight = colHeights[0];

    for (let i = 1; i < numColumns.value; i++) {
      if (colHeights[i] < minHeight) {
        minHeight = colHeights[i];
        shortestColIndex = i;
      }
    }

    // Calcular altura baseada no aspect ratio para balanceamento
    const [w, h] = stamp.aspectRatio.split('/').map(Number);
    const simulatedHeight = (h / w) * 100; // Altura proporcional

    newCols[shortestColIndex].push(stamp);
    colHeights[shortestColIndex] += simulatedHeight;
  });

  columns.value = newCols;
}

function calculateColumnsLayout() {
  const width = window.innerWidth;
  if (width < 640) numColumns.value = 2; // Mobile
  else if (width < 1024) numColumns.value = 3; // Tablet
  else numColumns.value = props.settings.columns_desktop || 4; // Desktop

  distributeItemsToColumns();
}

// ==========================================
// LÓGICA CORE: DATA FETCHING & INFINITE SCROLL
// ==========================================
async function fetchMoreStamps() {
  if (isLoading.value || hasReachedEnd.value) return;

  isLoading.value = true;

  try {
    // SIMULAÇÃO DE API (Substitua por supabase.from('catalog_stamps').range(...))
    await new Promise(resolve => setTimeout(resolve, 800));

    const newBatch: MasonryStamp[] = Array.from({ length: 12 }).map((_, i) => {
      const isPortrait = Math.random() > 0.5;
      const aspect = isPortrait ? '3/4' : (Math.random() > 0.5 ? '4/5' : '1/1'); // Variação de tamanhos
      const idStr = `stamp_${page}_${i}`;

      return {
        id: idStr,
        slug: idStr,
        ref_code: `REF-${Math.floor(Math.random() * 10000)}`,
        title: `Estampa Editorial ${page}-${i}`,
        description: null,
        category_id: null,
        // Usando imagens placeholder estéticas para o preview
        main_image_url: `https://picsum.photos/seed/${idStr}/600/${isPortrait ? '800' : '600'}`,
        seamless_pattern_url: null,
        dominant_color: null,
        tags: ['Orgânico', 'Tendência'],
        is_active: true,
        aspectRatio: aspect
      };
    });

    if (page >= 4) { // Simulando fim do catálogo após 4 páginas
      hasReachedEnd.value = true;
    } else {
      rawStamps.value.push(...newBatch);
      distributeItemsToColumns();
      page++;
    }
  } finally {
    isLoading.value = false;
  }
}

function setupIntersectionObserver() {
  if (!infiniteScrollTrigger.value) return;

  observer = new IntersectionObserver((entries) => {
    const target = entries[0];
    if (target.isIntersecting) {
      fetchMoreStamps();
    }
  }, { rootMargin: '400px' }); // Começa a carregar 400px ANTES de chegar no fim

  observer.observe(infiniteScrollTrigger.value);
}

// ==========================================
// CICLO DE VIDA
// ==========================================
onMounted(() => {
  calculateColumnsLayout();
  window.addEventListener('resize', calculateColumnsLayout);
  setupIntersectionObserver();
  fetchMoreStamps(); // Carregamento inicial
});

onUnmounted(() => {
  window.removeEventListener('resize', calculateColumnsLayout);
  if (observer) observer.disconnect();
});

// Re-filtra e reseta o layout se o filtro mudar
watch(activeFilter, () => {
  rawStamps.value = [];
  page = 1;
  hasReachedEnd.value = false;
  fetchMoreStamps();
});

function addToMoodboard(stamp: CatalogStamp) {
  moodboard.addItem(stamp);
}
</script>

<style scoped>
/* ==========================================================================
   DESIGN MASONRY ESTILO APPLE/PINTEREST
============================================================================= */
.discover-masonry-section {
  padding: 40px 24px 100px 24px;
  max-width: 1600px;
  margin: 0 auto;
  min-height: 100vh;
}

/* HEADER & FILTROS */
.discover-header {
  text-align: center;
  margin-bottom: 48px;
}

.discover-title {
  font-family: -apple-system, BlinkMacSystemFont, "SF Pro Display", sans-serif;
  font-size: clamp(2rem, 4vw, 3rem);
  font-weight: 700;
  color: #111;
  letter-spacing: -0.02em;
  margin: 0 0 12px 0;
}

.discover-subtitle {
  font-size: 1.125rem;
  color: #71717a;
  margin: 0 0 32px 0;
}

.quick-filters {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 12px;
  flex-wrap: wrap;
}

.filter-chip {
  background: #f4f4f5;
  border: none;
  padding: 10px 20px;
  border-radius: 99px;
  font-size: 14px;
  font-weight: 600;
  color: #3f3f46;
  cursor: pointer;
  transition: all 0.2s cubic-bezier(0.25, 1, 0.5, 1);
}

.filter-chip:hover {
  background: #e4e4e7;
  transform: translateY(-2px);
}

.filter-chip.active {
  background: #111;
  color: #fff;
  box-shadow: 0 4px 12px rgba(0,0,0,0.1);
}

/* MASONRY GRID REAL */
.masonry-container {
  display: flex;
  gap: 24px;
  align-items: flex-start; /* Essencial para as colunas não esticarem */
}

.masonry-column {
  display: flex;
  flex-direction: column;
  gap: 24px;
  flex: 1;
  min-width: 0; /* Previne overflow */
}

/* CARTÃO INDIVIDUAL */
.masonry-card {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.card-image-wrapper {
  position: relative;
  width: 100%;
  border-radius: 16px;
  overflow: hidden;
  background-color: #f4f4f5;
  cursor: zoom-in;
}

.card-image {
  width: 100%;
  height: 100%;
  object-fit: cover;
  transition: transform 0.6s cubic-bezier(0.25, 1, 0.5, 1);
  will-change: transform;
}

.masonry-card:hover .card-image {
  transform: scale(1.04);
}

/* OVERLAY PINTEREST STYLE */
.card-overlay {
  position: absolute;
  top: 0; left: 0; right: 0; bottom: 0;
  background: rgba(0, 0, 0, 0.2);
  opacity: 0;
  transition: opacity 0.3s ease;
  display: flex;
  align-items: flex-start;
  justify-content: flex-end;
  padding: 16px;
  pointer-events: none; /* Deixa o clique passar para o router-link (página dedicada) se houvesse */
}

.masonry-card:hover .card-overlay {
  opacity: 1;
}

.action-btn {
  pointer-events: auto; /* Reativa o clique só no botão */
  display: flex;
  align-items: center;
  gap: 6px;
  background: #e60023; /* Tom de vermelho conversão */
  color: #fff;
  border: none;
  padding: 10px 16px;
  border-radius: 99px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transform: translateY(-10px);
  transition: all 0.3s cubic-bezier(0.25, 1, 0.5, 1);
}

.masonry-card:hover .action-btn {
  transform: translateY(0);
}

.action-btn:hover {
  background: #ad081b;
  box-shadow: 0 4px 12px rgba(230, 0, 35, 0.3);
}

/* FOOTER DO CARD */
.card-footer {
  padding: 0 4px;
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
}

.card-title {
  font-size: 14px;
  font-weight: 600;
  color: #111;
  margin: 0;
  line-height: 1.4;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.card-tags {
  font-size: 12px;
  color: #71717a;
  white-space: nowrap;
}

/* INFINITE SCROLL INDICATOR */
.infinite-loading-zone {
  margin-top: 64px;
  padding: 40px 0;
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 100px;
}

.loading-indicator {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 16px;
  color: #71717a;
  font-size: 14px;
  font-weight: 500;
}

.spinner {
  width: 32px;
  height: 32px;
  border: 3px solid #f4f4f5;
  border-top-color: #111;
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

.end-of-results {
  font-size: 15px;
  color: #71717a;
  font-weight: 500;
  background: #f4f4f5;
  padding: 16px 32px;
  border-radius: 99px;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

/* Mobile Adjustments */
@media (max-width: 640px) {
  .discover-masonry-section { padding: 24px 16px; }
  .masonry-container { gap: 16px; }
  .masonry-column { gap: 16px; }
  .card-overlay { opacity: 1; background: transparent; padding: 12px; }
  .action-btn { transform: translateY(0); padding: 8px 12px; font-size: 12px; }
  .action-btn svg { width: 14px; height: 14px; }
}
</style>
