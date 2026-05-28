<template>
  <v-menu
    :model-value="show"
    @update:model-value="$emit('update:show', $event)"
    :target="[x, y]"
    absolute
    transition="scale-transition"
    origin="top left"
    content-class="bg-transparent elevation-0"
  >
    <v-list class="glass-list" density="compact" nav>

      <v-list-item @click="$emit('action', 'reply')" class="menu-action-item" :ripple="false">
        <template v-slot:prepend>
          <v-icon size="small" class="mr-3 action-icon">mdi-reply-outline</v-icon>
        </template>
        <v-list-item-title class="action-title">Responder</v-list-item-title>
      </v-list-item>

      <v-list-item v-if="isMyMessage" @click="$emit('action', 'edit')" class="menu-action-item" :ripple="false">
        <template v-slot:prepend>
          <v-icon size="small" class="mr-3 action-icon">mdi-pencil-outline</v-icon>
        </template>
        <v-list-item-title class="action-title">Editar</v-list-item-title>
      </v-list-item>

      <v-list-item @click="$emit('action', 'forward')" class="menu-action-item" :ripple="false">
        <template v-slot:prepend>
          <v-icon size="small" class="mr-3 action-icon">mdi-share-outline</v-icon>
        </template>
        <v-list-item-title class="action-title">Encaminhar</v-list-item-title>
      </v-list-item>

      <v-divider v-if="isMyMessage" class="my-1 border-opacity-25"></v-divider>

      <v-list-item v-if="isMyMessage" @click="$emit('action', 'delete')" class="menu-action-item delete-item" :ripple="false">
        <template v-slot:prepend>
          <v-icon size="small" class="mr-3 text-error">mdi-delete-outline</v-icon>
        </template>
        <v-list-item-title class="text-error font-weight-bold">Excluir</v-list-item-title>
      </v-list-item>

    </v-list>
  </v-menu>
</template>

<script setup lang="ts">
defineProps<{
  show: boolean;
  isMyMessage: boolean;
  x: number;
  y: number;
}>();

defineEmits(['update:show', 'action']);
</script>

<style scoped>
/* O container principal de vidro */
.glass-list {
  /* Usa a cor nativa do tema (branco no Light, grafite no Dark) com 85% de opacidade */
  background-color: rgba(var(--v-theme-surface), 0.85) !important;
  backdrop-filter: blur(16px) saturate(180%);
  -webkit-backdrop-filter: blur(16px) saturate(180%);

  border-radius: 12px !important;
  border: 1px solid rgba(128, 128, 128, 0.15) !important;
  padding: 6px !important;
  min-width: 180px;

  /* Sombra elegante que dá profundidade sem contorno agressivo */
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.15), 0 2px 8px rgba(0, 0, 0, 0.05) !important;
}

/* O item da lista */
.menu-action-item {
  background-color: transparent !important;
  border-radius: 8px !important;
  margin-bottom: 2px;
  transition: background-color 0.2s ease;
  cursor: pointer;
}

/* Força a remoção do fundo esquisito padrão do Vuetify nas opções */
.menu-action-item :deep(.v-list-item__overlay),
.menu-action-item :deep(.v-list-item__underlay) {
  display: none !important;
}

/* Cor do Hover (passar o mouse) adaptável ao tema */
.menu-action-item:hover {
  background-color: rgba(var(--v-theme-on-surface), 0.08) !important;
}

/* Efeito vermelho ao passar o mouse em Excluir */
.delete-item:hover {
  background-color: rgba(var(--v-theme-error), 0.1) !important;
}

/* Ícones adaptáveis */
.action-icon {
  color: rgba(var(--v-theme-on-surface), 0.6) !important;
}

/* Títulos adaptáveis */
.action-title {
  font-size: 0.95rem;
  letter-spacing: 0.3px;
  font-weight: 500;
  color: rgba(var(--v-theme-on-surface), 0.9) !important;
}
</style>
