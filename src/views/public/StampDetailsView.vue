<template>
  <div class="stamp-details-page">

    <div v-if="isLoading" class="stamp-layout skeleton-mode">
      <div class="media-gallery skeleton-pulse"></div>
      <div class="info-sidebar">
        <div class="skel-text title"></div>
        <div class="skel-text ref"></div>
        <div class="skel-text desc mt"></div>
        <div class="skel-text desc"></div>
        <div class="skel-button mt-lg"></div>
      </div>
    </div>

    <div v-else-if="!stamp" class="empty-state">
      <h2>Estampa não encontrada</h2>
      <p>A estampa que procura pode ter sido removida ou o link é inválido.</p>
      <button class="btn-secondary" @click="goBack">Voltar ao Catálogo</button>
    </div>

    <main v-else class="stamp-layout">

      <section class="media-gallery">
        <div class="main-image-wrapper" @mousemove="handleZoom" @mouseleave="resetZoom" ref="imageWrapper">
          <img
            :src="stamp.main_image_url"
            :alt="stamp.title"
            class="main-image"
            :style="zoomStyle"
          />
          <div class="zoom-hint">Passe o rato para ampliar</div>
        </div>

        <div class="thumbnail-list" v-if="stamp.seamless_pattern_url">
          <button class="thumb-btn active">
            <img :src="stamp.main_image_url" alt="Visão Geral" />
          </button>
          <button class="thumb-btn">
            <img :src="stamp.seamless_pattern_url" alt="Padrão Contínuo" />
          </button>
        </div>
      </section>

      <aside class="info-sidebar">

        <nav class="breadcrumbs">
          <a href="/">Home</a>
          <span class="separator">/</span>
          <a href="/descobrir">Catálogo</a>
          <span class="separator">/</span>
          <span class="current">{{ stamp.title }}</span>
        </nav>

        <header class="stamp-header">
          <h1 class="stamp-title">{{ stamp.title }}</h1>
          <p class="stamp-ref">Ref: <span>{{ stamp.ref_code }}</span></p>
        </header>

        <div class="stamp-description" v-if="stamp.description">
          <p>{{ stamp.description }}</p>
        </div>
        <div class="stamp-description empty-desc" v-else>
          <p>Padrão exclusivo de alta resolução. Perfeito para aplicações em moda, decoração e estamparia digital.</p>
        </div>

        <div class="stamp-attributes" v-if="stamp.tags && stamp.tags.length > 0">
          <h3>Características</h3>
          <div class="tags-wrapper">
            <span v-for="tag in stamp.tags" :key="tag" class="tag-badge">{{ tag }}</span>
          </div>
        </div>

        <div class="commercial-actions">

          <button class="btn-primary huge" @click="addToMoodboard" :class="{ 'added': isAddedToMoodboard }">
            <svg v-if="!isAddedToMoodboard" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"></path></svg>
            <svg v-else width="20" height="20" viewBox="0 0 24 24" fill="currentColor" stroke="none"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"></path></svg>
            {{ isAddedToMoodboard ? 'No seu Moodboard' : 'Adicionar ao Moodboard' }}
          </button>

          <button class="btn-secondary huge" @click="openMockupViewer">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="3" width="18" height="18" rx="2" ry="2"/><circle cx="8.5" cy="8.5" r="1.5"/><polyline points="21 15 16 10 5 21"/></svg>
            Testar em Mockup 3D
          </button>
        </div>

        <div class="trust-badges">
          <div class="badge">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
            <span>Licenciamento Exclusivo</span>
          </div>
          <div class="badge">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"></path><polyline points="3.27 6.96 12 12.01 20.73 6.96"></polyline><line x1="12" y1="22.08" x2="12" y2="12"></line></svg>
            <span>Ficheiro em Alta Resolução</span>
          </div>
        </div>

      </aside>
    </main>

  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useMoodboardStore } from '@/stores/moodboard';
import type { CatalogStamp } from '@/types/builder';

const route = useRoute();
const router = useRouter();
const moodboard = useMoodboardStore();

const isLoading = ref(true);
const stamp = ref<CatalogStamp | null>(null);

// ==========================================
// EFEITO DE ZOOM NÍVEL APPLE (Lupa na Imagem)
// ==========================================
const imageWrapper = ref<HTMLElement | null>(null);
const zoomStyle = ref({ transformOrigin: 'center center', transform: 'scale(1)' });

function handleZoom(event: MouseEvent) {
  if (!imageWrapper.value) return;
  const { left, top, width, height } = imageWrapper.value.getBoundingClientRect();

  // Calcula a posição do rato em percentagem (0 a 100%)
  const x = ((event.clientX - left) / width) * 100;
  const y = ((event.clientY - top) / height) * 100;

  zoomStyle.value = {
    transformOrigin: `${x}% ${y}%`,
    transform: 'scale(1.8)' // Nível de aproximação do tecido
  };
}

function resetZoom() {
  zoomStyle.value = {
    transformOrigin: 'center center',
    transform: 'scale(1)'
  };
}

// ==========================================
// LÓGICA DE DADOS E COMERCIAL
// ==========================================
const isAddedToMoodboard = computed(() => {
  if (!stamp.value) return false;
  return moodboard.items.some(item => item.stamp.id === stamp.value!.id);
});

onMounted(async () => {
  // O router pegaria o slug real da URL: const slug = route.params.slug;
  const slug = 'estampa-teste'; // Simulado

  try {
    // Aqui seria a chamada à API real: supabase.from('catalog_stamps').select('*').eq('slug', slug)
    await new Promise(resolve => setTimeout(resolve, 800)); // Simula latência de rede

    // Dados injetados para a demo premium
    stamp.value = {
      id: 'stamp_999',
      slug: 'tropical-monstera-dark',
      ref_code: 'REF-8472M',
      title: 'Tropical Monstera Dark Mode',
      description: 'Uma reinterpretação sofisticada e obscura da folhagem tropical clássica. Ideal para coleções de outono/inverno em tecidos de seda ou viscose premium.',
      category_id: null,
      main_image_url: 'https://images.unsplash.com/photo-1618220179428-22790b46a0eb?q=80&w=1500', // Imagem em alta
      seamless_pattern_url: 'https://images.unsplash.com/photo-1618220179428-22790b46a0eb?q=80&w=500',
      dominant_color: '#1a1a1a',
      tags: ['Tropical', 'Dark', 'Premium', 'Botânico'],
      is_active: true
    };

    // Dinamismo de SEO na página dedicada
    document.title = `${stamp.value.title} | Catálogo Exclusivo`;
  } catch (error) {
    console.error(error);
  } finally {
    isLoading.value = false;
  }
});

function addToMoodboard() {
  if (!stamp.value) return;
  moodboard.addItem(stamp.value);
}

function openMockupViewer() {
  alert("O Motor de Renderização de Mockups em Canvas será aberto aqui!");
  // Próxima etapa!
}

function goBack() {
  router.back();
}
</script>

<style scoped>
/* ==========================================================================
   DESIGN DA PÁGINA DEDICADA (Estilo Zara / Shopify Premium)
============================================================================= */
.stamp-details-page {
  width: 100%;
  min-height: 100vh;
  background-color: #ffffff;
  padding-bottom: 100px;
}

.stamp-layout {
  display: flex;
  flex-direction: column;
  max-width: 1440px;
  margin: 0 auto;
}

@media (min-width: 1024px) {
  .stamp-layout {
    flex-direction: row;
    align-items: flex-start;
  }
}

/* --------------------------------------------------------------------------
   LADO ESQUERDO: GALERIA STICKY
----------------------------------------------------------------------------- */
.media-gallery {
  width: 100%;
  position: relative;
}

@media (min-width: 1024px) {
  .media-gallery {
    width: 60%;
    position: sticky;
    top: 0; /* Cola no topo da tela quando rola o lado direito */
    height: 100vh;
    padding: 40px;
    display: flex;
    gap: 24px;
  }
}

.main-image-wrapper {
  width: 100%;
  height: 60vh;
  background-color: #f4f4f5;
  overflow: hidden;
  position: relative;
  cursor: crosshair;
}

@media (min-width: 1024px) {
  .main-image-wrapper {
    height: calc(100vh - 80px); /* Ocupa a tela inteira com padding */
    border-radius: 16px;
    flex: 1;
  }
}

.main-image {
  width: 100%;
  height: 100%;
  object-fit: cover;
  transition: transform 0.1s ease-out; /* Suavidade no zoom da Lupa */
  will-change: transform;
}

.zoom-hint {
  position: absolute;
  bottom: 24px;
  left: 50%;
  transform: translateX(-50%);
  background: rgba(255, 255, 255, 0.8);
  backdrop-filter: blur(8px);
  padding: 8px 16px;
  border-radius: 99px;
  font-size: 12px;
  font-weight: 500;
  color: #111;
  opacity: 0;
  transition: opacity 0.3s;
  pointer-events: none;
}

.main-image-wrapper:hover .zoom-hint { opacity: 1; }

.thumbnail-list {
  display: flex;
  gap: 12px;
  padding: 16px;
  overflow-x: auto;
}

@media (min-width: 1024px) {
  .thumbnail-list {
    flex-direction: column;
    padding: 0;
    width: 80px;
    overflow-x: visible;
  }
}

.thumb-btn {
  width: 80px;
  height: 106px;
  flex-shrink: 0;
  border: 2px solid transparent;
  border-radius: 8px;
  overflow: hidden;
  cursor: pointer;
  transition: all 0.2s;
  background: #f4f4f5;
}
.thumb-btn img { width: 100%; height: 100%; object-fit: cover; }
.thumb-btn.active, .thumb-btn:hover { border-color: #111; }

/* --------------------------------------------------------------------------
   LADO DIREITO: INFORMAÇÕES E CONVERSÃO
----------------------------------------------------------------------------- */
.info-sidebar {
  width: 100%;
  padding: 32px 24px;
  display: flex;
  flex-direction: column;
  font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", sans-serif;
}

@media (min-width: 1024px) {
  .info-sidebar {
    width: 40%;
    padding: 80px 80px 80px 40px;
    min-height: 100vh; /* Permite scroll natural */
  }
}

.breadcrumbs {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 13px;
  color: #71717a;
  margin-bottom: 32px;
}
.breadcrumbs a { color: #111; text-decoration: none; transition: opacity 0.2s; }
.breadcrumbs a:hover { opacity: 0.7; }
.separator { color: #d4d4d8; }

.stamp-header { margin-bottom: 24px; }
.stamp-title {
  font-family: -apple-system, BlinkMacSystemFont, "SF Pro Display", sans-serif;
  font-size: 32px;
  font-weight: 700;
  color: #111;
  letter-spacing: -0.02em;
  margin: 0 0 8px 0;
  line-height: 1.1;
}
.stamp-ref { font-size: 14px; color: #71717a; margin: 0; }
.stamp-ref span { font-family: ui-monospace, monospace; color: #111; }

.stamp-description {
  font-size: 16px;
  line-height: 1.6;
  color: #3f3f46;
  margin-bottom: 40px;
}
.empty-desc { font-style: italic; color: #a1a1aa; }

.stamp-attributes { margin-bottom: 40px; }
.stamp-attributes h3 { font-size: 14px; font-weight: 600; color: #111; text-transform: uppercase; letter-spacing: 0.05em; margin: 0 0 16px 0; border-bottom: 1px solid #e4e4e7; padding-bottom: 8px; }
.tags-wrapper { display: flex; flex-wrap: wrap; gap: 8px; }
.tag-badge { background: #f4f4f5; color: #3f3f46; font-size: 13px; padding: 6px 12px; border-radius: 4px; font-weight: 500; }

.commercial-actions {
  display: flex;
  flex-direction: column;
  gap: 16px;
  margin-bottom: 48px;
}

.btn-primary.huge, .btn-secondary.huge {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 12px;
  width: 100%;
  padding: 18px;
  border-radius: 8px; /* Quadrado arredondado premium em vez de pílula aqui */
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s cubic-bezier(0.25, 1, 0.5, 1);
  border: none;
}

.btn-primary.huge { background: #111; color: #fff; }
.btn-primary.huge:hover { background: #333; transform: translateY(-2px); box-shadow: 0 10px 20px rgba(0,0,0,0.1); }
.btn-primary.huge.added { background: #10b981; /* Verde sucesso */ }

.btn-secondary.huge { background: #fff; color: #111; border: 1px solid #d4d4d8; }
.btn-secondary.huge:hover { border-color: #111; background: #fafafa; }

.trust-badges {
  display: flex;
  flex-direction: column;
  gap: 12px;
  background: #fafafa;
  padding: 24px;
  border-radius: 12px;
}
.badge { display: flex; align-items: center; gap: 12px; font-size: 14px; color: #52525b; font-weight: 500; }
.badge svg { color: #111; }

/* --------------------------------------------------------------------------
   SKELETON LOADER
----------------------------------------------------------------------------- */
.skeleton-pulse { background: linear-gradient(90deg, #f4f4f5 25%, #e4e4e7 50%, #f4f4f5 75%); background-size: 200% 100%; animation: pulse 1.5s infinite; }
.skel-text { height: 16px; border-radius: 4px; background: #f4f4f5; margin-bottom: 12px; }
.skel-text.title { height: 40px; width: 80%; margin-bottom: 24px; }
.skel-text.ref { width: 30%; }
.skel-text.desc { width: 100%; }
.skel-text.desc.mt { margin-top: 32px; width: 90%; }
.skel-button { height: 56px; border-radius: 8px; background: #f4f4f5; margin-top: 48px; }
@keyframes pulse { 0% { background-position: 200% 0; } 100% { background-position: -200% 0; } }

.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 60vh;
  text-align: center;
}
.empty-state h2 { font-size: 24px; color: #111; margin-bottom: 8px; }
.empty-state p { color: #71717a; margin-bottom: 24px; }
</style>
