<template>
  <v-card class="d-flex flex-column" style="height: 100%" flat color="transparent">
    <v-card-title class="d-flex align-center pa-4">
      <template v-if="selectedActivity">
        <v-icon :color="getClassificationColor(selectedActivity?.classification)" class="mr-3" size="28">
          {{ getClassificationIcon(selectedActivity?.classification) }}
        </v-icon>
        <span class="font-weight-bold">Detalhes da Atividade</span>
      </template>
      <template v-else>
        <span class="font-weight-bold">Carregando Detalhes...</span>
      </template>
      <v-spacer />
      <v-btn icon="mdi-close" variant="text" @click="$emit('close')" />
    </v-card-title>
    <v-divider />

    <template v-if="selectedActivity">
      <v-card-text class="flex-grow-1 overflow-y-auto pa-4">
        <div class="mb-5 pb-5 border-b">
          <div class="text-caption text-medium-emphasis mb-1">Aplicação</div>
          <div class="font-weight-bold text-body-1 mb-2">{{ selectedActivity.application_name ?? 'N/A' }}</div>

          <div class="text-caption text-medium-emphasis mb-1">Título Completo da Janela</div>
          <div class="text-body-2 mb-2">{{ selectedActivity.window_title ?? 'N/A' }}</div>

          <div class="text-caption text-medium-emphasis mb-1">Caminho de Instalação</div>
          <div class="text-body-2 text-medium-emphasis" style="word-break: break-all;">
            {{ selectedActivity.path || 'Não disponível' }}
          </div>
        </div>

        <v-row dense class="mb-5 pb-5 border-b">
          <v-col cols="6">
            <div class="text-caption text-medium-emphasis">ID do Processo (PID)</div>
            <div class="font-weight-bold">{{ selectedActivity.pid || 'N/A' }}</div>
          </v-col>
          <v-col cols="6">
            <div class="text-caption text-medium-emphasis">Classificação</div>
            <v-chip :color="getClassificationColor(selectedActivity?.classification)" size="small" label variant="flat">
              {{ selectedActivity?.classification || 'neutro' }}
            </v-chip>
          </v-col>
            <v-col cols="12" class="mt-2">
              <div class="text-caption text-medium-emphasis">Registrado em</div>
              <div class="font-weight-bold">{{ formatDateTime(selectedActivity.created_at) }}</div>
            </v-col>
        </v-row>

        <div>
          <div class="text-subtitle-1 font-weight-bold mb-2">
            Ocorrências no Período ({{ allOccurrences.length }})
          </div>
          <v-virtual-scroll v-if="allOccurrences.length > 0" :items="allOccurrences" height="250" item-height="40">
            <template v-slot:default="{ item }">
              <v-list-item density="compact">
                <template v-slot:prepend>
                  <v-icon size="x-small" class="mr-2">mdi-clock-outline</v-icon>
                </template>
                <v-list-item-title class="text-body-2">{{ formatDateTime(item) }}</v-list-item-title>
              </v-list-item>
            </template>
          </v-virtual-scroll>
          <div v-else class="text-caption text-medium-emphasis pa-4 text-center">
             Nenhuma outra ocorrência desta atividade no período selecionado.
          </div>
        </div>

      </v-card-text>

      <v-divider />
      <v-card-actions class="pa-4">
        <v-spacer/>
        <v-btn variant="outlined" @click="$emit('close')">Fechar</v-btn>
      </v-card-actions>
    </template>

    <template v-else>
         <v-card-text class="d-flex justify-center align-center flex-grow-1">
             <v-progress-circular indeterminate color="primary"></v-progress-circular>
             <span class="ml-3">Carregando dados...</span>
         </v-card-text>
    </template>
  </v-card>
</template>

<script setup lang="ts">
import { computed } from 'vue';

// Definição da interface
interface Activity {
  application_name?: string;
  window_title?: string;
  path?: string | null;
  pid?: number | string | null;
  classification?: 'produtivo' | 'improdutivo' | 'neutro' | string | null;
  created_at: string;
}

const props = defineProps<{
  selectedActivity: Activity | null | undefined;
  allActivities: any[];
}>();

const emit = defineEmits(['close']);

// --- Computeds ---

const allOccurrences = computed(() => {
  if (!props.selectedActivity || !props.allActivities || !props.selectedActivity.path || !props.selectedActivity.window_title) return [];
  return props.allActivities
    .filter(a => a.path === props.selectedActivity?.path && a.window_title === props.selectedActivity?.window_title)
    .map(a => a.created_at)
    .sort((a, b) => new Date(b).getTime() - new Date(a).getTime());
});

// --- Métodos ---

function formatDateTime(isoString: string): string {
  if (!isoString) return 'N/A';
  try {
    return new Date(isoString).toLocaleString('pt-BR', { dateStyle: 'short', timeStyle: 'medium' });
  } catch (e) {
    console.error("Erro ao formatar data:", isoString, e);
    return isoString;
  }
}

/**
 * [CORRIGIDO] Retorna o nome da cor sem 'isChip' ou códigos hex.
 * O Vuetify (no dark theme) cuidará da cor real.
 */
const getClassificationColor = (classification: string | null | undefined): string => {
  if (!classification) return 'grey-darken-1';
  switch (classification.toLowerCase()) {
    case 'produtivo': return 'success';
    case 'improdutivo': return 'error';
    default: return 'grey-darken-1'; // 'neutro'
  }
};

/**
 * [PADRONIZADO] Usa os ícones 'outline' para consistência com o modal principal.
 */
const getClassificationIcon = (classification: string | null | undefined): string => {
  if (!classification) return 'mdi-circle-outline';
  switch (classification.toLowerCase()) {
    case 'produtivo': return 'mdi-check-circle-outline';
    case 'improdutivo': return 'mdi-alert-circle-outline';
    default: return 'mdi-circle-outline'; // 'neutro'
  }
};
</script>

<style scoped>
/* Estilo para as bordas-divisorias no dark theme */
.border-b {
  border-bottom: 1px solid rgba(255, 255, 255, 0.12);
}
.v-virtual-scroll {
  padding: 0;
}
.v-list-item {
  padding-left: 0 !important;
  padding-right: 0 !important;
}
</style>
