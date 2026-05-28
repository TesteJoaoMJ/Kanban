<template>
  <v-dialog
    :model-value="modelValue"
    @update:modelValue="$emit('update:modelValue', $event)"
    max-width="600px"
    persistent
  >
    <v-theme-provider theme="dark">
      <v-card color="grey-darken-4">
        <v-toolbar color="grey-darken-3" density="compact">
          <v-toolbar-title class="text-subtitle-1">{{ title || 'Detalhes do Ponto' }}</v-toolbar-title>
          <v-spacer></v-spacer>
          <v-btn icon @click="$emit('update:modelValue', false)">
            <v-icon>mdi-close</v-icon>
          </v-btn>
        </v-toolbar>

        <v-card-text class="pa-4">
          <p class="text-medium-emphasis mb-4">
            Detalhes sobre o ponto de dados selecionado:
          </p>

          <v-list bg-color="transparent" density="compact">
            <v-list-item
              v-for="(value, key) in data"
              :key="key"
              class="pa-0"
            >
              <v-list-item-title class="text-caption text-medium-emphasis">{{ key }}</v-list-item-title>
              <v-list-item-subtitle class="text-body-1 font-weight-bold">{{ value }}</v-list-item-subtitle>
              <v-divider class="my-2"></v-divider>
            </v-list-item>
          </v-list>

        </v-card-text>

        <v-divider></v-divider>
        <v-card-actions>
          <v-spacer></v-spacer>
          <v-btn
            color="white"
            variant="text"
            @click="$emit('update:modelValue', false)"
          >
            Fechar
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-theme-provider>
  </v-dialog>
</template>

<script setup lang="ts">
import { computed } from 'vue';

// --- Props ---
const props = defineProps<{
  modelValue: boolean; // Controla a visibilidade (v-model)
  title: string;       // Título do modal
  data: Record<string, any>; // Objeto com os dados a serem exibidos
}>();

// --- Emits ---
const emit = defineEmits(['update:modelValue']);

</script>

<style scoped>
.v-list-item-title {
  text-transform: uppercase;
}
.v-list-item-subtitle {
  white-space: normal; /* Garante que o texto quebre a linha */
}
</style>
