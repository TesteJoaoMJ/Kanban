<template>
  <v-dialog :model-value="show" @update:model-value="$emit('close')" max-width="95%" persistent>
    <v-card class="glassmorphism-card comparative-modal-card">

      <v-toolbar color="transparent">
        <v-toolbar-title class="font-weight-bold d-flex align-center">
          <v-icon start class="mr-2" color="primary">mdi-compare-horizontal</v-icon>
          Relatório Comparativo de Períodos
        </v-toolbar-title>
        <v-spacer></v-spacer>
        <v-btn
          @click="openAIChat"
          color="cyan-lighten-1"
          variant="flat"
          class="mr-4 modern-btn--gradient-ai"
        >
          <v-icon start>mdi-robot-happy-outline</v-icon>
          Análise com IA
        </v-btn>
        <v-btn icon="mdi-close" variant="text" @click="$emit('close')"></v-btn>
      </v-toolbar>

      <v-container fluid class="main-container">
        <v-row class="fill-height">

          <v-col :md="showAIChat ? 9 : 12" class="content-col">
            <v-card class="glassmorphism-card results-card" elevation="0">

              <v-expansion-panels v-model="panel" variant="accordion" class="filter-panel">
                <v-expansion-panel class="glassmorphism-card" elevation="0" value="filters">
                  <v-expansion-panel-title class="filter-header-title">
                    <v-icon start>mdi-filter-variant</v-icon>
                    Filtros e Parâmetros
                    <v-spacer></v-spacer>
                    <span v-if="dataA" class="text-caption text-medium-emphasis mr-4">
                      Comparando Período A ({{ filtersA.startDate }} a {{ filtersA.endDate }})
                      com Período B ({{ filtersB.startDate }} a {{ filtersB.endDate }})
                    </span>
                  </v-expansion-panel-title>
                  <v-expansion-panel-text>
                    <v-row>
                      <v-col cols="12" md="5">
                        <div class="filter-label">Período A (Base)</div>
                        <v-row dense>
                          <v-col cols="6">
                            <v-text-field v-model="filtersA.startDate" type="date" label="Data de Início A" density="compact" variant="outlined"></v-text-field>
                          </v-col>
                          <v-col cols="6">
                            <v-text-field v-model="filtersA.endDate" type="date" label="Data de Fim A" density="compact" variant="outlined"></v-text-field>
                          </v-col>
                        </v-row>
                      </v-col>

                      <v-col cols="12" md="5">
                        <div class="filter-label">Período B (Comparação)</div>
                        <v-row dense>
                          <v-col cols="6">
                            <v-text-field v-model="filtersB.startDate" type="date" label="Data de Início B" density="compact" variant="outlined"></v-text-field>
                          </v-col>
                          <v-col cols="6">
                            <v-text-field v-model="filtersB.endDate" type="date" label="Data de Fim B" density="compact" variant="outlined"></v-text-field>
                          </v-col>
                        </v-row>
                      </v-col>

                      <v-col cols="12" md="2" class="d-flex align-end">
                        <v-btn
                          @click="runComparison"
                          :loading="loading"
                          color="primary"
                          variant="flat"
                          block
                          size="large"
                          class="modern-btn--gradient"
                        >
                          <v-icon start>mdi-chart-line</v-icon>
                          Gerar
                        </v-btn>
                      </v-col>
                    </v-row>
                  </v-expansion-panel-text>
                </v-expansion-panel>
              </v-expansion-panels>

              <v-tabs v-model="tab" color="primary" bg-color="transparent" class="sticky-tabs" grow>
                <v-tab value="overview">Visão Geral (KPIs)</v-tab>
                <v-tab value="analysis">Análise de Clientes</v-tab>
                <v-tab value="sellers">Vendedores</v-tab>
                <v-tab value="customers">Clientes</v-tab>
                <v-tab value="fabrics">Bases (Tecidos)</v-tab>
              </v-tabs>

              <v-card-text class="results-content">
                <v-skeleton-loader v-if="loading" type="article@3"></v-skeleton-loader>

                <v-empty-state
                  v-else-if="!dataA && !dataB && !error"
                  icon="mdi-filter-variant"
                  title="Selecione os Períodos"
                  text="Escolha dois períodos (A e B) e clique em 'Gerar Comparativo' para ver os dados."
                ></v-empty-state>

                <v-alert
                  v-else-if="error"
                  type="error"
                  variant="tonal"
                  border="start"
                  icon="mdi-alert-circle-outline"
                  title="Erro ao Gerar Relatório"
                >
                  {{ error }}
                </v-alert>

                <v-window v-model="tab" v-else-if="dataA && dataB">
                  <v-window-item value="overview">
                    <div class="section-title">Principais KPIs (Período A vs Período B)</div>
                    <v-row dense>
                      <v-col cols="12" md="4" sm="6">
                        <ComparativeKpi
                          title="Faturamento Total"
                          :valueA="dataA.kpis.total_revenue"
                          :valueB="dataB.kpis.total_revenue"
                          format="currency"
                          :sparklineData="dataA.sales_trend_data"
                        />
                      </v-col>
                      <v-col cols="12" md="4" sm="6">
                        <ComparativeKpi
                          title="Total de Pedidos"
                          :valueA="dataA.kpis.total_orders"
                          :valueB="dataB.kpis.total_orders"
                        />
                      </v-col>
                      <v-col cols="12" md="4" sm="6">
                        <ComparativeKpi
                          title="Ticket Médio"
                          :valueA="dataA.kpis.avg_ticket"
                          :valueB="dataB.kpis.avg_ticket"
                          format="currency"
                        />
                      </v-col>
                      <v-col cols="12" md="4" sm="6">
                        <ComparativeKpi
                          title="Metragem Total"
                          :valueA="dataA.kpis.total_meters"
                          :valueB="dataB.kpis.total_meters"
                          format="decimal"
                        />
                      </v-col>
                      <v-col cols="12" md="4" sm="6">
                        <ComparativeKpi
                          title="Novos Clientes"
                          :valueA="dataA.kpis.new_customers"
                          :valueB="dataB.kpis.new_customers"
                        />
                      </v-col>
                      <v-col cols="12" md="4" sm="6">
                         <ComparativeKpi
                          title="Média por Pedido (m)"
                          :valueA="dataA.kpis.avg_meters_per_order"
                          :valueB="dataB.kpis.avg_meters_per_order"
                          format="decimal"
                        />
                      </v-col>
                    </v-row>

                    <div class="section-title mt-8">Metragem por Região (m)</div>
                     <apexchart
                        type="bar"
                        height="250"
                        :options="regionChartOptions"
                        :series="regionChartSeries"
                      ></apexchart>
                  </v-window-item>

                  <v-window-item value="analysis">
                    <div class="section-title">Análise de Churn de Clientes (Período A vs Período B)</div>
                    <v-row dense>
                      <v-col cols="12" md="4">
                        <ComparativeKpi
                          title="Clientes Novos (em A)"
                          :valueA="customerAnalysis.newCustomers.length"
                          :valueB="0"
                        />
                      </v-col>
                      <v-col cols="12" md="4">
                        <ComparativeKpi
                          title="Clientes Perdidos (de B)"
                          :valueA="0"
                          :valueB="customerAnalysis.lostCustomers.length"
                        />
                      </v-col>
                      <v-col cols="12" md="4">
                        <ComparativeKpi
                          title="Clientes Recorrentes"
                          :valueA="customerAnalysis.returningCustomers.length"
                          :valueB="customerAnalysis.returningCustomers.length"
                        />
                      </v-col>
                    </v-row>
                    <v-row>
                      <v-col cols="12" md="4">
                        <v-text-field v-model="searchNew" label="Buscar Clientes Novos..." dense variant="outlined" prepend-inner-icon="mdi-magnify" clearable class="mb-2"></v-text-field>
                        <v-data-table
                          :headers="customerTableHeaders"
                          :items="customerAnalysis.newCustomersTable"
                          :search="searchNew"
                          density="compact"
                          class="glassmorphism-table"
                          :items-per-page="5"
                        ></v-data-table>
                      </v-col>
                      <v-col cols="12" md="4">
                        <v-text-field v-model="searchLost" label="Buscar Clientes Perdidos..." dense variant="outlined" prepend-inner-icon="mdi-magnify" clearable class="mb-2"></v-text-field>
                        <v-data-table
                          :headers="customerTableHeaders"
                          :items="customerAnalysis.lostCustomersTable"
                          :search="searchLost"
                          density="compact"
                          class="glassmorphism-table"
                          :items-per-page="5"
                        ></v-data-table>
                      </v-col>
                      <v-col cols="12" md="4">
                        <v-text-field v-model="searchReturning" label="Buscar Clientes Recorrentes..." dense variant="outlined" prepend-inner-icon="mdi-magnify" clearable class="mb-2"></v-text-field>
                        <v-data-table
                          :headers="customerTableHeaders"
                          :items="customerAnalysis.returningCustomersTable"
                          :search="searchReturning"
                          density="compact"
                          class="glassmorphism-table"
                          :items-per-page="5"
                        ></v-data-table>
                      </v-col>
                    </v-row>
                  </v-window-item>

                  <v-window-item value="sellers">
                    <apexchart
                      type="bar"
                      height="500"
                      :options="sellerChartOptions"
                      :series="sellerChartSeries"
                    ></apexchart>
                  </v-window-item>

                  <v-window-item value="customers">
                    <apexchart
                      type="bar"
                      height="500"
                      :options="customerChartOptions"
                      :series="customerChartSeries"
                    ></apexchart>
                  </v-window-item>

                  <v-window-item value="fabrics">
                     <apexchart
                      type="bar"
                      height="500"
                      :options="fabricChartOptions"
                      :series="fabricChartSeries"
                    ></apexchart>
                  </v-window-item>

                </v-window>
              </v-card-text>
            </v-card>
          </v-col>

          <v-col v-if="showAIChat" cols="12" md="3" class="ai-col">
            <v-card class="glassmorphism-card ai-card" elevation="0">
              <v-toolbar color="transparent" density="compact">
                <v-toolbar-title class="font-weight-bold text-cyan-lighten-2">
                  <v-icon start>mdi-robot-happy-outline</v-icon>
                  Análise com IA
                </v-toolbar-title>
                <v-btn icon="mdi-close" variant="text" @click="showAIChat = false"></v-btn>
              </v-toolbar>

              <v-card-text class="ai-content">
                <div v-if="!isAssistantInitialized" class="text-center pa-8">
                  <v-progress-circular indeterminate color="cyan"></v-progress-circular>
                  <p class="text-caption mt-4">Inicializando assistente...</p>
                </div>

                <div v-else class="chat-messages" ref="chatMessagesRef">
                  <div v-for="msg in messages" :key="msg.id" class="message" :class="msg.role">
                    <div v-if="msg.role === 'assistant'" v-html="renderMarkdown(msg.content)"></div>
                    <div v-else>{{ msg.content }}</div>
                  </div>

                  <div v-if="messages.length <= 1 && dataA" class="message system">
                    <div class="text-subtitle-2 mb-2">Sugestões de Análise:</div>
                    <v-chip
                      v-for="prompt in promptStarters"
                      :key="prompt"
                      @click="sendAIPrompt(prompt)"
                      class="ma-1"
                      color="primary"
                      variant="outlined"
                      size="small"
                    >
                      {{ prompt }}
                    </v-chip>
                  </div>

                  <div v-if="isAIThinking" class="message assistant">
                    <v-progress-circular indeterminate color="cyan" size="20" class="mr-2"></v-progress-circular>
                    Analisando...
                  </div>
                </div>
              </v-card-text>

              <v-card-actions class="ai-actions">
                <v-textarea
                  v-model="aiPrompt"
                  label="Faça uma pergunta sobre os dados..."
                  variant="solo"
                  bg-color="rgba(0,0,0,0.2)"
                  flat
                  density="compact"
                  rows="3"
                  hide-details
                  :disabled="!isAssistantInitialized || isAIThinking"
                  @keydown.enter.prevent="sendAIPrompt()"
                ></v-textarea>
                <v-btn
                  @click="sendAIPrompt()"
                  icon="mdi-send"
                  color="cyan"
                  variant="flat"
                  class="ml-2"
                  :loading="isAIThinking"
                  :disabled="!isAssistantInitialized"
                ></v-btn>
              </v-card-actions>
            </v-card>
          </v-col>

        </v-row>
      </v-container>
    </v-card>
  </v-dialog>
</template>

<script setup lang="ts">
import { ref, reactive, computed, defineAsyncComponent, watch, nextTick } from 'vue';
import { useCrmStore } from '@/stores/crm';
import { useOpenAIAssistant } from '@/composables/useOpenAIAssistant';
import { formatISO, subDays, startOfMonth, endOfMonth } from 'date-fns';
import VueApexCharts from 'vue3-apexcharts';
import { marked } from 'marked';
import DOMPurify from 'dompurify';

// Componentes
const apexchart = VueApexCharts;
const ComparativeKpi = defineAsyncComponent(() => import('@/components/admin/crm/ComparativeKpi.vue'));

// Props & Emits
const props = defineProps<{ show: boolean }>();
const emit = defineEmits(['close']);

// Store e Estado
const crmStore = useCrmStore();
const loading = ref(false); // Loading dos dados do relatório
const error = ref<string | null>(null);
const tab = ref('overview');
const panel = ref([]); // Painel de filtro começa fechado

// Datas Padrão
const today = new Date();
const startOfCurrentMonth = formatISO(startOfMonth(today), { representation: 'date' });
const endOfCurrentMonth = formatISO(today, { representation: 'date' });
const startOfLastMonth = formatISO(startOfMonth(subDays(startOfCurrentMonth, 2)), { representation: 'date' });
const endOfLastMonth = formatISO(endOfMonth(subDays(startOfCurrentMonth, 2)), { representation: 'date' });

const filtersA = reactive({ startDate: startOfCurrentMonth, endDate: endOfCurrentMonth });
const filtersB = reactive({ startDate: startOfLastMonth, endDate: endOfLastMonth });

const dataA = ref<any>(null);
const dataB = ref<any>(null);

// ========================================================
// LÓGICA DO ASSISTENTE DE IA
// ========================================================
const {
  initializeChat,
  sendMessage,
  messages,
  isLoading: isAIThinking,
  isInitialized: isAssistantInitialized,
} = useOpenAIAssistant();

const showAIChat = ref(false);
const aiPrompt = ref('');
const chatMessagesRef = ref<HTMLElement | null>(null);

// [NOVO] Prompts pré-definidos
const promptStarters = ref([
  "Faça um resumo executivo da comparação",
  "Quais vendedores mais cresceram?",
  "Quais clientes perdemos (churn)?",
  "Compare o faturamento das bases 'Crepe' vs 'Viscolinho'"
]);

// Inicializa o chat da IA quando o modal é aberto
watch(() => props.show, (newVal) => {
  if (newVal && !isAssistantInitialized.value) {
    initializeChat();
  }
});

// [CORREÇÃO DE LÓGICA DA IA]
// Adiciona uma mensagem de contexto *instrutiva* quando a IA é inicializada.
watch(isAssistantInitialized, (newVal) => {
  if (newVal && messages.value.length <= 1) { // Só envia se for a msg de "Olá"
    messages.value.push({
      id: 'system-context',
      role: 'system',
      content: 'Estou pronto. Os dados de comparação estão carregados (se você já clicou em "Gerar").\n\n**Faça perguntas diretas sobre os dados** ou use as sugestões.'
    });
  }
});

const renderMarkdown = (text: string) => {
  return DOMPurify.sanitize(marked(text));
};

// Abre o painel de chat
const openAIChat = () => {
  showAIChat.value = true;
};

// [CORREÇÃO DE LÓGICA DA IA]
// Envia a *pergunta* do usuário, mas adiciona o *contexto dos filtros*
// para que a IA possa construir a consulta SQL correta.
const sendAIPrompt = async (promptText?: string) => {
  const prompt = promptText || aiPrompt.value;
  if (!prompt.trim() || isAIThinking.value) return;

  // Adiciona o contexto de data crucial que a IA precisa
  const context = `
Contexto de Períodos:
- Período A: ${filtersA.startDate} a ${filtersA.endDate}
- Período B: ${filtersB.startDate} a ${filtersB.endDate}

Pergunta do Usuário:
${prompt}
  `;

  // Adiciona a *pergunta simples* ao chat para o usuário ver
  messages.value.push({
    id: `user_${Date.now()}`,
    role: 'user',
    content: prompt
  });

  aiPrompt.value = ''; // Limpa o input

  // Envia o *prompt completo com contexto* para o backend
  await sendMessage(context);
};

// Auto-scroll do chat
watch(messages, () => {
  nextTick(() => {
    if (chatMessagesRef.value) {
      chatMessagesRef.value.scrollTop = chatMessagesRef.value.scrollHeight;
    }
  });
}, { deep: true });
// ========================================================
// FIM DA LÓGICA DE IA
// ========================================================


// Ação Principal de Geração
const runComparison = async () => {
  loading.value = true;
  error.value = null;
  dataA.value = null;
  dataB.value = null;
  messages.value = []; // Limpa o chat da IA

  try {
    const { dataA: resultA, dataB: resultB } = await crmStore.fetchComparativeReport(filtersA, filtersB);
    dataA.value = resultA;
    dataB.value = resultB;
    tab.value = 'overview'; // Reseta para a tab principal
    panel.value = []; // Fecha o painel de filtro
  } catch (err: any) {
    error.value = err.message || 'Ocorreu um erro desconhecido.';
  } finally {
    loading.value = false;
  }
};

// ========================================================
// LÓGICA DE DADOS COMPUTADOS (GRÁFICOS, LISTAS)
// ========================================================

// --- [ ✅ CORREÇÃO DO BUG ] ---
const customerAnalysis = computed(() => {
  if (!dataA.value || !dataB.value) {
    // Retorna um objeto padrão para evitar o 'undefined'
    return {
      newCustomers: [], lostCustomers: [], returningCustomers: [],
      newCustomersTable: [], lostCustomersTable: [], returningCustomersTable: []
    };
  }
  const setA = dataA.value.customerSet as Set<string>;
  const setB = dataB.value.customerSet as Set<string>;

  const newCustomers = [...setA].filter(c => !setB.has(c));
  const lostCustomers = [...setB].filter(c => !setA.has(c));
  const returningCustomers = [...setA].filter(c => setB.has(c));

  // Formata para v-data-table
  return {
    newCustomers,
    lostCustomers,
    returningCustomers,
    newCustomersTable: newCustomers.map(c => ({ name: c })),
    lostCustomersTable: lostCustomers.map(c => ({ name: c })),
    returningCustomersTable: returningCustomers.map(c => ({ name: c }))
  };
});

// --- Novas refs para pesquisa na data-table ---
const searchNew = ref('');
const searchLost = ref('');
const searchReturning = ref('');
const customerTableHeaders = ref([
  { title: 'Nome do Cliente', key: 'name' }
]);

// --- Opções base para todos os gráficos ---
const baseChartOptions = computed(() => ({
  chart: {
    type: 'bar',
    height: 500,
    toolbar: { show: true, tools: { download: true, selection: true, zoom: true, zoomin: true, zoomout: true, pan: true } },
    foreColor: '#E0E0E0',
  },
  plotOptions: {
    bar: {
      horizontal: false,
      columnWidth: '80%',
      borderRadius: 4,
      borderRadiusApplication: 'end',
    },
  },
  dataLabels: { enabled: false },
  stroke: { show: true, width: 2, colors: ['transparent'] },
  xaxis: {
    categories: [],
    labels: {
      style: { colors: '#B0BEC5', fontSize: '10px' },
      trim: true,
      rotate: -45,
      maxHeight: 100,
    },
  },
  yaxis: {
    title: { text: 'Metragem (m)', style: { color: '#B0BEC5', fontWeight: 600 } },
    labels: { style: { colors: '#B0BEC5' }, formatter: (val: number) => val.toFixed(0) },
  },
  fill: { opacity: 1 },
  tooltip: {
    theme: 'dark',
    shared: true,
    intersect: false,
    y: { formatter: (val: number) => `${val.toFixed(2)} m` }
  },
  grid: { borderColor: 'rgba(255, 255, 255, 0.1)' },
  legend: {
    show: true,
    position: 'top',
    horizontalAlign: 'left',
    markers: { radius: 12 }
  },
  colors: ['#00E396', '#008FFB'] // Período A (Verde), Período B (Azul)
}));

/**
 * Helper para processar rankings comparativos.
 */
const getComparativeRanking = (
  mapA: Map<string, any>,
  mapB: Map<string, any>,
  valueField: 'meters' | 'value',
  topN = 15
) => {
  const combined = new Map<string, { a: number, b: number }>();

  mapA.forEach((data, name) => {
    combined.set(name, { a: data[valueField] || 0, b: 0 });
  });

  mapB.forEach((data, name) => {
    const existing = combined.get(name) || { a: 0, b: 0 };
    existing.b = data[valueField] || 0;
    combined.set(name, existing);
  });

  const sorted = Array.from(combined.entries())
    .map(([name, values]) => ({ name, ...values }))
    .sort((a, b) => Math.max(b.a, b.b) - Math.max(a.a, a.b)) // Ordena pelo maior valor em qualquer período
    .slice(0, topN);

  return {
    categories: sorted.map(item => item.name),
    series: [
      { name: `Período A (${filtersA.endDate.split('-')[1]})`, data: sorted.map(item => item.a.toFixed(2)) },
      { name: `Período B (${filtersB.endDate.split('-')[1]})`, data: sorted.map(item => item.b.toFixed(2)) },
    ],
  };
};

// --- Gráfico de Vendedores ---
const sellerChartData = computed(() => {
  if (!dataA.value || !dataB.value) return { categories: [], series: [] };
  return getComparativeRanking(
    dataA.value.sellerMap,
    dataB.value.sellerMap,
    'meters', 15
  );
});
const sellerChartOptions = computed(() => ({
  ...baseChartOptions.value,
  xaxis: { ...baseChartOptions.value.xaxis, categories: sellerChartData.value.categories },
  yaxis: { ...baseChartOptions.value.yaxis, title: { text: 'Metragem (m)' } },
  title: { text: 'Ranking de Vendedores (Top 15 por Metragem)', align: 'left', style: { fontSize: '16px', color: '#FFF' } }
}));
const sellerChartSeries = computed(() => sellerChartData.value.series);

// --- Gráfico de Clientes ---
const customerChartData = computed(() => {
  if (!dataA.value || !dataB.value) return { categories: [], series: [] };
  return getComparativeRanking(
    dataA.value.customerMap,
    dataB.value.customerMap,
    'meters', 15
  );
});
const customerChartOptions = computed(() => ({
  ...baseChartOptions.value,
  xaxis: { ...baseChartOptions.value.xaxis, categories: customerChartData.value.categories },
  yaxis: { ...baseChartOptions.value.yaxis, title: { text: 'Metragem (m)' } },
  colors: ['#FF4560', '#FEB019'], // Cliente A (Vermelho), Cliente B (Laranja)
  title: { text: 'Ranking de Clientes (Top 15 por Metragem)', align: 'left', style: { fontSize: '16px', color: '#FFF' } }
}));
const customerChartSeries = computed(() => customerChartData.value.series);

// --- Gráfico de Bases (Tecidos) ---
const fabricChartData = computed(() => {
  if (!dataA.value || !dataB.value) return { categories: [], series: [] };
  return getComparativeRanking(
    dataA.value.fabricMap,
    dataB.value.fabricMap,
    'meters', 15
  );
});
const fabricChartOptions = computed(() => ({
  ...baseChartOptions.value,
  xaxis: { ...baseChartOptions.value.xaxis, categories: fabricChartData.value.categories },
  yaxis: { ...baseChartOptions.value.yaxis, title: { text: 'Metragem (m)' } },
  colors: ['#775DD0', '#546E7A'], // Base A (Roxo), Base B (Cinza)
  title: { text: 'Ranking de Bases (Top 15 por Metragem)', align: 'left', style: { fontSize: '16px', color: '#FFF' } }
}));
const fabricChartSeries = computed(() => fabricChartData.value.series);

// --- Gráfico de Região ---
const regionChartOptions = computed(() => ({
  ...baseChartOptions.value,
  height: 250,
  xaxis: { ...baseChartOptions.value.xaxis, categories: ['Sudoeste', 'Nordeste'], rotate: 0 },
  yaxis: { ...baseChartOptions.value.yaxis, title: { text: 'Metragem (m)' } },
  title: { text: 'Comparativo por Região', align: 'left', style: { fontSize: '16px', color: '#FFF' } }
}));
const regionChartSeries = computed(() => {
  if (!dataA.value || !dataB.value) return [];
  return [
    {
      name: `Período A (${filtersA.endDate.split('-')[1]})`,
      data: [
        dataA.value.salesByRegion.Sudoeste.toFixed(2),
        dataA.value.salesByRegion.Nordeste.toFixed(2)
      ]
    },
    {
      name: `Período B (${filtersB.endDate.split('-')[1]})`,
      data: [
        dataB.value.salesByRegion.Sudoeste.toFixed(2),
        dataB.value.salesByRegion.Nordeste.toFixed(2)
      ]
    },
  ];
});

</script>

<style scoped lang="scss">
/* Estilo Glassmorphism principal (baseado no Admin.vue) */
.glassmorphism-card {
  background-color: rgba(30, 31, 49, 0.7) !important;
  backdrop-filter: blur(15px) saturate(180%);
  -webkit-backdrop-filter: blur(15px) saturate(180%);
  border-radius: 16px;
  border: 1px solid rgba(255, 255, 255, 0.1);
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.2);
  color: #e0e0e0;
}

.comparative-modal-card {
  background: rgba(20, 20, 30, 0.9) !important;
  max-height: 95vh;
  display: flex;
  flex-direction: column;
}

.main-container {
  height: calc(95vh - 64px); /* Altura do modal - toolbar */
  padding-top: 0 !important;
}

.content-col {
  height: 100%;
  /* Transição de largura ao abrir/fechar o chat */
  transition: all 0.3s ease-in-out;
}

/* Novo Painel de Chat IA */
.ai-col {
  height: 100%;
  transition: all 0.3s ease-in-out;
  /* Animação de "surgir" */
  animation: slideInFromRight 0.5s ease-out;
}

@keyframes slideInFromRight {
  from {
    transform: translateX(100%);
    opacity: 0;
  }
  to {
    transform: translateX(0);
    opacity: 1;
  }
}

.ai-card {
  height: 100%;
  display: flex;
  flex-direction: column;
  background-color: rgba(10, 10, 20, 0.8) !important;
}

.ai-content {
  flex-grow: 1;
  overflow-y: auto;
  padding: 0 16px;
}

.ai-actions {
  border-top: 1px solid rgba(255, 255, 255, 0.1);
  padding: 16px;
}

.chat-messages {
  display: flex;
  flex-direction: column;
  gap: 12px;
  padding-bottom: 16px;

  .message {
    padding: 10px 14px;
    border-radius: 12px;
    max-width: 90%;
    word-break: break-word;

    &.user {
      background-color: rgba(0, 143, 251, 0.2);
      align-self: flex-end;
    }
    &.assistant {
      background-color: rgba(30, 31, 49, 0.9);
      align-self: flex-start;

      :deep(p) { margin-bottom: 8px; }
      :deep(ul) { padding-left: 20px; }
      :deep(strong) { color: #00E396; }
    }
    &.system {
      background-color: rgba(100, 116, 139, 0.2);
      border: 1px dashed rgba(100, 116, 139, 0.5);
      color: #cbd5e1;
      font-size: 0.85rem;
      align-self: center;
      max-width: 100%;
    }
  }
}


/* Painel de Filtro */
.filter-panel {
  margin-bottom: 16px;
  .v-expansion-panel {
    background-color: transparent !important;
  }
}
.filter-header-title {
  font-weight: 600;
  font-size: 1rem;
}

.results-card {
  background-color: rgba(30, 31, 49, 0.5) !important;
  height: 100%;
  display: flex;
  flex-direction: column;
}

.sticky-tabs {
  position: sticky;
  top: 0;
  z-index: 2;
  background-color: rgba(30, 31, 49, 0.8) !important;
  backdrop-filter: blur(10px);
}

.results-content {
  flex-grow: 1;
  overflow-y: auto;
  padding: 16px;
}

.filter-label {
  font-size: 0.9rem;
  font-weight: 600;
  color: #B0BEC5;
  margin-bottom: 10px;
  display: block;
}

.section-title {
  font-size: 1.2rem;
  font-weight: bold;
  color: #fff;
  margin-bottom: 16px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.2);
  padding-bottom: 8px;
}

/* Estilo para as Tabs */
.v-tab {
  font-weight: 600;
  color: #B0BEC5;
}
.v-tab--selected {
  color: #00E396 !important; /* Verde neon */
}

/* Análise de Clientes (Novas Tabelas) */
.analysis-title {
  font-size: 1.1rem;
  font-weight: 700;
  margin-bottom: 8px;
}
.analysis-value {
  font-size: 2.5rem;
  font-weight: 900;
  color: #fff;
  line-height: 1;
  margin-bottom: 16px;
}

.analysis-list {
  max-height: 200px;
  overflow-y: auto;
}
.v-list {
  background-color: transparent !important;
}
.v-list-item {
  padding-inline-start: 0 !important;
  color: #e0e0e0;
}

/* [NOVO] Estilo para V-Data-Table */
.glassmorphism-table {
  background-color: transparent !important;
  border-radius: 8px;
  border: 1px solid rgba(255, 255, 255, 0.1);

  :deep(.v-data-table__wrapper) {
    background-color: rgba(30, 31, 49, 0.5) !important;
    border-radius: 8px;
  }
  :deep(th) {
    color: #B0BEC5 !important;
    font-weight: 600;
  }
  :deep(td) {
    color: #E0E0E0;
    border-bottom: 1px solid rgba(255, 255, 255, 0.1) !important;
  }
  :deep(.v-data-table-footer) {
    color: #B0BEC5;
  }
  :deep(tr:hover) {
    background-color: rgba(255, 255, 255, 0.05) !important;
  }
}

/* Botões Gradiente */
.modern-btn--gradient {
  background: linear-gradient(45deg, #00E396, #008FFB);
  color: white;
  font-weight: 700;
  box-shadow: 0 4px 15px rgba(0, 227, 150, 0.3);
  transition: all 0.3s ease;
  &:hover {
    transform: translateY(-2px);
    box-shadow: 0 6px 20px rgba(0, 143, 251, 0.4);
  }
}

.modern-btn--gradient-ai {
  background: linear-gradient(45deg, #00ACC1, #26C6DA);
  color: white;
  font-weight: 700;
  box-shadow: 0 4px 15px rgba(0, 172, 193, 0.3);
  transition: all 0.3s ease;
  &:hover {
    transform: translateY(-2px);
    box-shadow: 0 6px 20px rgba(38, 198, 218, 0.4);
  }
}
</style>
