<template>
  <div class="storefront-engine-root" :style="rootStyles">

    <component v-if="schema.settings?.custom_css" :is="'style'">
      {{ schema.settings.custom_css }}
    </component>

    <template v-for="(section, index) in schema.sections" :key="section.id || index">

      <component
        v-if="!section.is_hidden && resolvedComponents[section.type]"
        :is="resolvedComponents[section.type]"
        :settings="section.settings"
        :blocks="section.blocks"
        :section-id="section.id"
      />

      <div v-else-if="!section.is_hidden" class="storefront-missing-component">
        <span class="error-icon">⚠️</span>
        <div>
          <strong>Falha de Motor:</strong> Componente do tipo <code>{{ section.type }}</code> não foi registado no <em>StorefrontRenderer</em>.
        </div>
      </div>

    </template>
  </div>
</template>

<script setup lang="ts">
import { computed, defineAsyncComponent, watchEffect } from 'vue';
import type { PageSchema } from '@/types/builder';

// Contrato estrito com a base de dados/API
const props = defineProps<{
  schema: PageSchema;
}>();

/**
 * REGISTO DE COMPONENTES DINÂMICOS (Code Splitting)
 * Aqui mapeamos a string do JSON ('HeroSection') para o ficheiro Vue real.
 * O uso do `defineAsyncComponent` faz com que o Vite quebre cada secção num ficheiro .js separado (chunks).
 */
const resolvedComponents: Record<string, any> = {
  HeroSection: defineAsyncComponent(() => import('./sections/HeroSection.vue')),
  DynamicStampGrid: defineAsyncComponent(() => import('./sections/DynamicStampGrid.vue')),
  EditorialMosaic: defineAsyncComponent(() => import('./sections/EditorialMosaic.vue')),
  // O sistema cresce aqui. Adicionar nova secção = registar 1 linha aqui.
};

/**
 * APLICAÇÃO DE DEFINIÇÕES GLOBAIS
 * Lê as definições globais da página (cor de fundo, etc) para a raiz do storefront.
 */
const rootStyles = computed(() => {
  return {
    backgroundColor: props.schema?.settings?.background_color || '#F9F9FB', // Fundo premium por defeito
  };
});

/**
 * MOTOR DE SEO DINÂMICO
 * Ao carregar a página (ou trocar o schema no Builder), reescrevemos o DOM para refletir o SEO.
 * (Nota: Numa arquitetura Server Side Rendered como Nuxt, usaríamos o useHead() aqui).
 */
watchEffect(() => {
  if (props.schema?.settings) {
    // 1. Title da página
    if (props.schema.settings.seo_title) {
      document.title = props.schema.settings.seo_title;
    }

    // 2. Meta Description
    if (props.schema.settings.seo_description) {
      let metaDescription = document.querySelector('meta[name="description"]');
      if (!metaDescription) {
        metaDescription = document.createElement('meta');
        metaDescription.setAttribute('name', 'description');
        document.head.appendChild(metaDescription);
      }
      metaDescription.setAttribute('content', props.schema.settings.seo_description);
    }

    // 3. Open Graph Image (Para partilha de links rica no WhatsApp/Redes Sociais)
    if (props.schema.settings.og_image) {
      let ogImage = document.querySelector('meta[property="og:image"]');
      if (!ogImage) {
        ogImage = document.createElement('meta');
        ogImage.setAttribute('property', 'og:image');
        document.head.appendChild(ogImage);
      }
      ogImage.setAttribute('content', props.schema.settings.og_image);
    }
  }
});
</script>

<style scoped>
/* Reset estrutural rigoroso para a engine pública */
.storefront-engine-root {
  width: 100%;
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  overflow-x: hidden;
  position: relative;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}

/* Fallback de erro elegante para garantir governança técnica */
.storefront-missing-component {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 16px 24px;
  background-color: #fef2f2; /* Vermelho muito suave */
  color: #991b1b;
  border: 1px dashed #ef4444;
  margin: 24px auto;
  border-radius: 8px;
  font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace;
  font-size: 14px;
  max-width: 800px;
  width: 90%;
  box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05);
}

.error-icon {
  font-size: 20px;
}
</style>
