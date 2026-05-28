<template>
  <section :id="sectionId" class="stamp-grid-section">

    <div class="grid-header" v-if="settings.title">
      <h2 class="section-title">{{ settings.title }}</h2>
    </div>

    <div v-if="isLoading" class="stamp-grid" :style="gridStyles">
      <div v-for="i in settings.limit" :key="i" class="stamp-skeleton">
        <div class="skeleton-image"></div>
        <div class="skeleton-text short"></div>
        <div class="skeleton-text long"></div>
      </div>
    </div>

    <div v-else class="stamp-grid" :style="gridStyles">
      <article v-for="stamp in stamps" :key="stamp.id" class="stamp-card group">

        <div class="stamp-image-wrapper">
          <img :src="stamp.main_image_url" :alt="stamp.title" loading="lazy" class="stamp-image" />

          <div class="stamp-quick-actions">
            <button
              v-if="settings.show_favorites_button"
              class="action-btn"
              title="Adicionar ao Moodboard"
              @click="addToMoodboard(stamp)"
            >
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"></path></svg>
            </button>
            <button
              v-if="settings.show_mockup_preview"
              class="action-btn"
              title="Ver no Mockup"
            >
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M15 3h4a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-4M10 17l5-5-5-5M13.8 12H3"></path></svg>
            </button>
          </div>
        </div>

        <div class="stamp-info">
          <h3 class="stamp-name">{{ stamp.title }}</h3>
          <span class="stamp-ref">{{ stamp.ref_code }}</span>
        </div>

      </article>
    </div>
  </section>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import type { DynamicStampGrid, CatalogStamp } from '@/types/builder';
import { supabase } from '@/api/supabase'; // Ponte real com o seu banco

const props = defineProps<{
  sectionId: string;
  settings: DynamicStampGrid['settings'];
}>();

const stamps = ref<CatalogStamp[]>([]);
const isLoading = ref(true);

const gridStyles = computed(() => {
  return {
    '--columns-desktop': props.settings.columns_desktop || 4,
    '--columns-mobile': props.settings.columns_mobile || 2,
  };
});

onMounted(async () => {
  // Lógica inteligente de busca via Schema
  try {
    let query = supabase.from('catalog_stamps').select('*').eq('is_active', true);

    if (props.settings.data_source === 'latest') {
      query = query.order('created_at', { ascending: false });
    } else if (props.settings.data_source.startsWith('category:')) {
      const catSlug = props.settings.data_source.split(':')[1];
      // Nota: numa query real com Supabase envolveria um JOIN ou RPC, simulado aqui:
      // query = query.eq('category_slug', catSlug);
    }

    query = query.limit(props.settings.limit || 8);

    const { data, error } = await query;
    if (!error && data) {
      stamps.value = data as CatalogStamp[];
    }
  } catch (err) {
    console.error('Falha ao renderizar secção de estampas:', err);
  } finally {
    isLoading.value = false;
  }
});

function addToMoodboard(stamp: CatalogStamp) {
  // Aqui acionamos o módulo de Commerce/Conversion (Etapa futura)
  console.log('Adicionando ao moodboard local/database:', stamp.ref_code);
  alert(`Estampa ${stamp.ref_code} adicionada ao seu projeto.`);
}
</script>

<style scoped>
.stamp-grid-section {
  padding: 64px 24px;
  max-width: 1440px;
  margin: 0 auto;
}

.grid-header {
  margin-bottom: 40px;
  text-align: center;
}

.section-title {
  font-family: -apple-system, BlinkMacSystemFont, "SF Pro Display", sans-serif;
  font-size: 28px;
  font-weight: 600;
  color: #111;
  letter-spacing: -0.01em;
}

/* CSS Grid Avançado */
.stamp-grid {
  display: grid;
  grid-template-columns: repeat(var(--columns-mobile), 1fr);
  gap: 16px;
}

@media (min-width: 768px) {
  .stamp-grid {
    grid-template-columns: repeat(var(--columns-desktop), 1fr);
    gap: 32px;
  }
}

/* Stamp Card UI Premium */
.stamp-card {
  display: flex;
  flex-direction: column;
  gap: 12px;
  cursor: pointer;
}

.stamp-image-wrapper {
  position: relative;
  width: 100%;
  aspect-ratio: 3 / 4; /* Proporção elegante para estampas */
  background-color: #f3f4f6;
  border-radius: 12px;
  overflow: hidden;
}

.stamp-image {
  width: 100%;
  height: 100%;
  object-fit: cover;
  transition: transform 0.6s cubic-bezier(0.25, 1, 0.5, 1);
}

.stamp-card:hover .stamp-image {
  transform: scale(1.05);
}

/* Ações Hover */
.stamp-quick-actions {
  position: absolute;
  bottom: 16px;
  left: 50%;
  transform: translateX(-50%) translateY(20px);
  display: flex;
  gap: 8px;
  opacity: 0;
  transition: all 0.3s cubic-bezier(0.25, 1, 0.5, 1);
}

.stamp-card:hover .stamp-quick-actions {
  opacity: 1;
  transform: translateX(-50%) translateY(0);
}

.action-btn {
  background: rgba(255, 255, 255, 0.9);
  backdrop-filter: blur(8px);
  border: none;
  border-radius: 50%;
  width: 44px;
  height: 44px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #111;
  box-shadow: 0 4px 12px rgba(0,0,0,0.1);
  cursor: pointer;
  transition: all 0.2s;
}

.action-btn:hover {
  background: #111;
  color: #fff;
  transform: scale(1.1);
}

/* Tipografia do Card */
.stamp-info {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.stamp-name {
  font-size: 14px;
  font-weight: 500;
  color: #111;
  margin: 0;
  font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", sans-serif;
}

.stamp-ref {
  font-size: 13px;
  color: #666;
  font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
}

/* Skeletons Nível Apple */
.stamp-skeleton {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.skeleton-image {
  width: 100%;
  aspect-ratio: 3 / 4;
  background: linear-gradient(90deg, #f0f0f0 25%, #fafafa 50%, #f0f0f0 75%);
  background-size: 200% 100%;
  animation: loading 1.5s infinite;
  border-radius: 12px;
}

.skeleton-text {
  height: 14px;
  border-radius: 4px;
  background: #f0f0f0;
}
.skeleton-text.short { width: 60%; }
.skeleton-text.long { width: 40%; }

@keyframes loading {
  0% { background-position: 200% 0; }
  100% { background-position: -200% 0; }
}
</style>
