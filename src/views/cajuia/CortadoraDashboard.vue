<template>
  <v-container fluid class="pa-6">
    <div class="d-flex flex-column flex-md-row align-md-center justify-space-between mb-8 gap-4">
      <div>
        <h1 class="text-h4 font-weight-bold text-primary d-flex align-center">
          <v-icon size="36" class="mr-3">mdi-content-cut</v-icon>
          Corte e Preparação
        </h1>
        <p class="text-body-1 text-medium-emphasis mt-1">
          Gerencie a fila da máquina a laser, separe para pilotagem e etiquete o retorno.
        </p>
      </div>
      <div class="d-flex gap-3">
        <v-btn color="primary" prepend-icon="mdi-printer" variant="tonal">
          Imprimir Relatório
        </v-btn>
        <v-btn color="primary" prepend-icon="mdi-refresh" @click="carregarDados">
          Atualizar
        </v-btn>
      </div>
    </div>

    <v-row class="mb-6">
      <v-col cols="12" sm="4">
        <v-card border elevation="0" class="rounded-xl pa-4 d-flex align-center">
          <v-avatar color="warning-lighten-4" size="56" class="mr-4 text-warning">
            <v-icon size="32">mdi-laser-pointer</v-icon>
          </v-avatar>
          <div>
            <div class="text-caption text-medium-emphasis text-uppercase font-weight-bold">Aguardando Corte</div>
            <div class="text-h4 font-weight-black">{{ filaCorte.length }}</div>
          </div>
        </v-card>
      </v-col>
      <v-col cols="12" sm="4">
        <v-card border elevation="0" class="rounded-xl pa-4 d-flex align-center">
          <v-avatar color="info-lighten-4" size="56" class="mr-4 text-info">
            <v-icon size="32">mdi-sewing-machine</v-icon>
          </v-avatar>
          <div>
            <div class="text-caption text-medium-emphasis text-uppercase font-weight-bold">Em Pilotagem / Costura</div>
            <div class="text-h4 font-weight-black">{{ emCostura.length }}</div>
          </div>
        </v-card>
      </v-col>
      <v-col cols="12" sm="4">
        <v-card border elevation="0" class="rounded-xl pa-4 d-flex align-center">
          <v-avatar color="success-lighten-4" size="56" class="mr-4 text-success">
            <v-icon size="32">mdi-check-decagram</v-icon>
          </v-avatar>
          <div>
            <div class="text-caption text-medium-emphasis text-uppercase font-weight-bold">Prontos Hoje</div>
            <div class="text-h4 font-weight-black">{{ prontos.length }}</div>
          </div>
        </v-card>
      </v-col>
    </v-row>

    <v-row>
      <v-col cols="12" md="4">
        <v-card border elevation="0" class="rounded-xl bg-surface h-100 d-flex flex-column">
          <v-card-title class="pa-4 border-b d-flex align-center justify-space-between">
            <span class="font-weight-bold">1. Máquina a Laser</span>
            <v-chip size="small" color="warning" variant="flat">{{ filaCorte.length }}</v-chip>
          </v-card-title>

          <v-card-text class="pa-4 flex-grow-1 overflow-y-auto" style="max-height: 600px;">
            <div v-if="filaCorte.length === 0" class="text-center text-medium-emphasis py-8">
              Nenhuma peça na fila.
            </div>

            <v-card
              v-for="item in filaCorte"
              :key="item.id"
              border
              elevation="0"
              class="mb-3 rounded-lg transition-swing hover-card"
            >
              <div class="pa-3">
                <div class="d-flex justify-space-between align-center mb-2">
                  <span class="font-weight-bold text-body-1">{{ item.modelo }}</span>
                  <v-chip size="x-small" color="primary" variant="tonal">{{ item.tamanho }}</v-chip>
                </div>
                <div class="text-caption text-medium-emphasis mb-3">
                  <v-icon size="14" class="mr-1">mdi-texture</v-icon> Tecido: {{ item.tecido }}
                </div>
                <v-btn block color="primary" variant="flat" size="small" @click="moverParaCostura(item)">
                  <v-icon left size="16" class="mr-1">mdi-check</v-icon>
                  Concluir Corte e Enviar
                </v-btn>
              </div>
            </v-card>
          </v-card-text>
        </v-card>
      </v-col>

      <v-col cols="12" md="4">
        <v-card border elevation="0" class="rounded-xl bg-surface h-100 d-flex flex-column">
          <v-card-title class="pa-4 border-b d-flex align-center justify-space-between">
            <span class="font-weight-bold">2. Pilotagem / Costura</span>
            <v-chip size="small" color="info" variant="flat">{{ emCostura.length }}</v-chip>
          </v-card-title>

          <v-card-text class="pa-4 flex-grow-1 overflow-y-auto" style="max-height: 600px;">
             <div v-if="emCostura.length === 0" class="text-center text-medium-emphasis py-8">
              Nenhuma peça em costura no momento.
            </div>

            <v-card
              v-for="item in emCostura"
              :key="item.id"
              border
              elevation="0"
              class="mb-3 rounded-lg"
            >
              <div class="pa-3">
                <div class="d-flex justify-space-between align-center mb-1">
                  <span class="font-weight-bold">{{ item.modelo }}</span>
                  <span class="text-caption text-medium-emphasis">Lote: #{{ item.id }}</span>
                </div>
                <div class="text-caption text-info mb-3 d-flex align-center">
                  <v-icon size="14" class="mr-1">mdi-clock-outline</v-icon> Aguardando retorno
                </div>
                <div class="d-flex gap-2">
                  <v-btn flex-grow-1 color="secondary" variant="tonal" size="small" prepend-icon="mdi-printer">
                    Etiqueta
                  </v-btn>
                  <v-btn flex-grow-1 color="success" variant="flat" size="small" @click="receberDaCostura(item)">
                    Receber
                  </v-btn>
                </div>
              </div>
            </v-card>
          </v-card-text>
        </v-card>
      </v-col>

      <v-col cols="12" md="4">
        <v-card border elevation="0" class="rounded-xl bg-surface h-100 d-flex flex-column">
          <v-card-title class="pa-4 border-b d-flex flex-column gap-3">
            <div class="d-flex align-center justify-space-between w-100">
              <span class="font-weight-bold">3. Prontos p/ Loja</span>
              <v-chip size="small" color="success" variant="flat">{{ prontos.length }}</v-chip>
            </div>
            <v-text-field
              v-model="bipagemInput"
              label="Bipar Etiqueta (Código)"
              variant="outlined"
              density="compact"
              hide-details
              prepend-inner-icon="mdi-barcode-scan"
              @keyup.enter="biparPeca"
            ></v-text-field>
          </v-card-title>

          <v-card-text class="pa-4 flex-grow-1 overflow-y-auto" style="max-height: 520px;">
            <div v-if="prontos.length === 0" class="text-center text-medium-emphasis py-8">
              Nenhuma peça pronta ainda.
            </div>

            <v-list lines="two" class="bg-transparent pa-0">
              <v-list-item
                v-for="item in prontos"
                :key="item.id"
                class="border rounded-lg mb-2 bg-surface"
              >
                <template v-slot:prepend>
                  <v-avatar color="success-lighten-4" class="text-success">
                    <v-icon>mdi-check</v-icon>
                  </v-avatar>
                </template>
                <v-list-item-title class="font-weight-bold">{{ item.modelo }}</v-list-item-title>
                <v-list-item-subtitle>Tam: {{ item.tamanho }} | Cód: #{{ item.id }}</v-list-item-subtitle>
                <template v-slot:append>
                  <v-btn icon="mdi-tag-multiple" variant="text" size="small" color="primary" tooltip="Enviar para Loja"></v-btn>
                </template>
              </v-list-item>
            </v-list>
          </v-card-text>
        </v-card>
      </v-col>
    </v-row>
  </v-container>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from 'vue';
import { supabase } from '@/api/supabase';
import { useAppStore } from '@/stores/app';

const appStore = useAppStore();

interface PecaCorte {
  id: string;
  nome_peca: string;
  quantidade: number;
  observacoes: string;
  status: string;
}

const todasTarefas = ref<PecaCorte[]>([]);
const bipagemInput = ref('');

// Computed Properties que filtram a lista principal automaticamente
const filaCorte = computed(() => todasTarefas.value.filter(t => t.status === 'Corte'));
const emCostura = computed(() => todasTarefas.value.filter(t => t.status === 'Costura Piloto' || t.status === 'Costura Produção'));
const prontos = computed(() => todasTarefas.value.filter(t => t.status === 'Envio a Loja' || t.status === 'Concluído'));

const carregarDados = async () => {
  const { data, error } = await supabase
    .from('cajuia_corte_tasks')
    .select('*')
    .order('created_at', { ascending: false });

  if (!error && data) {
    todasTarefas.value = data;
  }
};

const alterarStatus = async (item: PecaCorte, novoStatus: string) => {
  // Atualiza UI imediatamente para parecer super rápido
  item.status = novoStatus;

  // Salva no banco em background
  const { error } = await supabase.from('cajuia_corte_tasks').update({ status: novoStatus }).eq('id', item.id);

  if (error) {
    appStore.showSnackbar('Erro ao atualizar status', 'error');
  }
};

// --- FUNÇÃO CORRIGIDA DO ERRO ---
const biparPeca = async () => {
  if (!bipagemInput.value) return;

  // Tenta encontrar a peça bipada pelo ID do lote (ou código da etiqueta se você usar outro)
  const pecaEncontrada = todasTarefas.value.find(p => p.id === bipagemInput.value.trim());

  if (pecaEncontrada) {
    // Ao bipar, move a peça direto para a coluna de prontos (Envio a Loja)
    await alterarStatus(pecaEncontrada, 'Envio a Loja');
    appStore.showSnackbar(`Peça ${pecaEncontrada.nome_peca} finalizada e pronta para loja!`, 'success');
  } else {
    appStore.showSnackbar('Código não encontrado na lista atual.', 'error');
  }

  // Limpa o input e foca de novo (se necessário) para o próximo bip
  bipagemInput.value = '';
};

onMounted(() => {
  carregarDados();
});
</script>

<style scoped>
.gap-3 {
  gap: 12px;
}
.gap-4 {
  gap: 16px;
}
.hover-card:hover {
  border-color: rgb(var(--v-theme-primary)) !important;
  transform: translateY(-2px);
}
/* Esconde a barra de rolagem de forma elegante, mas mantém o scroll */
.overflow-y-auto::-webkit-scrollbar {
  width: 6px;
}
.overflow-y-auto::-webkit-scrollbar-thumb {
  background-color: rgba(var(--v-theme-on-surface), 0.2);
  border-radius: 4px;
}
</style>
