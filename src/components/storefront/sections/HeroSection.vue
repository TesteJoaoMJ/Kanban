<template>
  <section
    :id="sectionId"
    class="hero-section"
    :class="[`height-${settings.height}`, `layout-${settings.layout}`]"
  >
    <div class="hero-media-container">
      <video
        v-if="settings.background_video_url"
        :src="settings.background_video_url"
        autoplay
        loop
        muted
        playsinline
        class="hero-media object-cover"
      ></video>
      <img
        v-else-if="settings.background_image_url"
        :src="settings.background_image_url"
        :alt="settings.title"
        class="hero-media object-cover"
        loading="eager"
      />
    </div>

    <div
      class="hero-overlay"
      :style="{
        backgroundColor: settings.overlay_color || '#000000',
        opacity: settings.overlay_opacity ?? 0.4
      }"
    ></div>

    <div class="hero-content">
      <h1
        class="hero-title"
        :style="{ color: settings.text_color || '#FFFFFF' }"
      >
        {{ settings.title }}
      </h1>

      <p
        v-if="settings.subtitle"
        class="hero-subtitle"
        :style="{ color: settings.text_color || '#FFFFFF' }"
      >
        {{ settings.subtitle }}
      </p>

      <div v-if="blocks && blocks.length > 0" class="hero-actions">
        <template v-for="block in blocks" :key="block.id">

          <a
            v-if="block.type === 'ButtonBlock'"
            :href="block.settings.url"
            :target="block.settings.open_in_new_tab ? '_blank' : '_self'"
            class="storefront-btn"
            :class="`btn-${block.settings.style}`"
          >
            {{ block.settings.label }}
          </a>

          <component
            v-else-if="block.type === 'TextBlock'"
            :is="block.settings.html_tag"
            :style="{ color: block.settings.color, textAlign: block.settings.alignment }"
            class="storefront-text-block"
          >
            {{ block.settings.content }}
          </component>

        </template>
      </div>
    </div>
  </section>
</template>

<script setup lang="ts">
import type { HeroSection } from '@/types/builder';

defineProps<{
  sectionId: string;
  settings: HeroSection['settings'];
  blocks: HeroSection['blocks'];
}>();
</script>

<style scoped>
/* Reset e Base */
.hero-section {
  position: relative;
  width: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  overflow: hidden;
  background-color: #1a1a1a;
}

/* Tamanhos configuráveis pelo Builder */
.height-small { min-height: 40vh; }
.height-medium { min-height: 60vh; }
.height-large { min-height: 80vh; }
.height-viewport { min-height: 100vh; }

/* Layouts */
.layout-split { align-items: center; justify-content: flex-start; padding-left: 10%; }
.layout-boxed .hero-media-container { padding: 24px; border-radius: 24px; }

/* Mídia e Overlay */
.hero-media-container {
  position: absolute;
  top: 0; left: 0; right: 0; bottom: 0;
  width: 100%; height: 100%;
  z-index: 1;
}

.hero-media {
  width: 100%;
  height: 100%;
  object-fit: cover;
  object-position: center;
  transition: transform 10s ease; /* Efeito Ken Burns sutil */
}

.hero-section:hover .hero-media {
  transform: scale(1.03);
}

.hero-overlay {
  position: absolute;
  top: 0; left: 0; right: 0; bottom: 0;
  z-index: 2;
  transition: opacity 0.3s ease;
}

/* Conteúdo central */
.hero-content {
  position: relative;
  z-index: 3;
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
  max-width: 800px;
  padding: 0 24px;
}

.layout-split .hero-content {
  align-items: flex-start;
  text-align: left;
}

.hero-title {
  font-family: -apple-system, BlinkMacSystemFont, "SF Pro Display", "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
  font-size: clamp(2.5rem, 5vw, 5rem);
  font-weight: 700;
  letter-spacing: -0.02em;
  line-height: 1.05;
  margin: 0 0 16px 0;
  text-wrap: balance;
}

.hero-subtitle {
  font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", "Segoe UI", Roboto, Helvetica, sans-serif;
  font-size: clamp(1.125rem, 2vw, 1.5rem);
  font-weight: 400;
  opacity: 0.9;
  margin: 0 0 32px 0;
  max-width: 600px;
  text-wrap: pretty;
}

/* Botões Nível Premium */
.hero-actions {
  display: flex;
  gap: 16px;
  flex-wrap: wrap;
}

.storefront-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: 14px 28px;
  font-size: 15px;
  font-weight: 600;
  border-radius: 999px; /* Pílula elegante */
  text-decoration: none;
  transition: all 0.2s cubic-bezier(0.25, 1, 0.5, 1);
  cursor: pointer;
  letter-spacing: -0.01em;
}

.btn-primary {
  background-color: #ffffff;
  color: #000000;
  box-shadow: 0 4px 14px rgba(0,0,0,0.1);
}

.btn-primary:hover {
  transform: translateY(-2px);
  box-shadow: 0 6px 20px rgba(0,0,0,0.15);
}

.btn-ghost {
  background-color: transparent;
  color: #ffffff;
  border: 1px solid rgba(255,255,255,0.3);
  backdrop-filter: blur(10px);
}

.btn-ghost:hover {
  background-color: rgba(255,255,255,0.1);
  border-color: rgba(255,255,255,0.5);
}
</style>
