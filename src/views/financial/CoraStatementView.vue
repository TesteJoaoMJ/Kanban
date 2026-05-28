<template>
  <div
    class="receivables-layout font-sans fill-height d-flex flex-column relative overflow-hidden"
    :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 text-grey-darken-4' : 'bg-glass-dark text-white'"
  >
    <div v-if="themeStore.currentMode !== 'light'" class="background-carousel-wrapper">
      <v-carousel cycle height="100%" hide-delimiters :show-arrows="false" interval="15000" class="fill-height">
        <v-carousel-item src="@/assets/1.jpg" cover></v-carousel-item>
        <v-carousel-item src="@/assets/2.jpg" cover></v-carousel-item>
        <v-carousel-item src="@/assets/3.jpg" cover></v-carousel-item>
      </v-carousel>
      <div class="background-overlay"></div>
    </div>

    <div class="content-wrapper d-flex flex-column fill-height z-10 relative">

      <div
        class="header-bar px-4 py-3 px-md-6 py-md-4 d-flex flex-column flex-md-row align-md-center justify-space-between flex-shrink-0"
        :class="themeStore.currentMode === 'light' ? 'bg-white border-b border-grey-lighten-2 shadow-sm' : 'bg-glass-header border-bottom-white-05'"
        style="gap: 12px;"
      >
        <div class="d-flex flex-column">
          <div class="breadcrumb text-caption d-none d-md-block">
            <span class="opacity-70">Financeiro</span>
            <span class="mx-2 opacity-50">></span>
            <span class="font-weight-bold">Extrato Bancário (Cora)</span>
          </div>
          <div class="d-flex align-center gap-2 mt-1">
             <div class="text-h6 font-weight-black tracking-tight leading-none" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">
                Extrato Cora
             </div>
             <v-chip size="x-small" :color="headerColor" class="font-weight-bold ml-2">
                {{ headerTitle }}
             </v-chip>
          </div>
        </div>

        <div class="d-flex align-center overflow-x-auto pb-1 pb-md-0" style="gap: 10px;">
          <template v-if="canPerformActions">
            <v-btn
                color="indigo-darken-3"
                variant="flat"
                class="btn-rect px-3 px-md-4 font-weight-bold text-caption text-uppercase letter-spacing-1 flex-shrink-0 shadow-sm"
                prepend-icon="mdi-file-pdf-box"
                height="40"
                :loading="generatingPdf"
                @click="generatePDF(filteredItems, `Extrato_Geral_${filters.start}_${filters.end}`)"
            >
                <span class="d-none d-sm-inline">Relatório Geral</span>
            </v-btn>

            <v-btn
              color="success"
              variant="flat"
              class="btn-rect px-3 px-md-4 font-weight-bold text-caption text-uppercase letter-spacing-1 flex-shrink-0 shadow-sm"
              prepend-icon="mdi-refresh"
              height="40"
              @click="fetchStatement"
              :loading="loading"
            >
               <span class="d-none d-sm-inline">Atualizar</span>
               <v-icon class="d-inline d-sm-none">mdi-refresh</v-icon>
            </v-btn>
          </template>

          <div v-else class="text-caption font-italic opacity-60">
             Visualização Apenas
          </div>
        </div>
      </div>

      <div class="px-4 px-md-6 py-4 flex-shrink-0">
        <div
          class="controls-bar d-flex flex-column rounded-lg bg-white elevation-1 pa-3"
          :class="themeStore.currentMode === 'light' ? '' : 'bg-glass-card'"
          style="gap: 10px;"
        >
          <div class="d-flex flex-column flex-md-row align-start align-md-center justify-space-between" style="gap: 10px;">

            <div class="d-flex align-center flex-wrap w-100 w-md-auto" style="gap: 10px;">

              <div class="d-flex align-center bg-grey-lighten-4 rounded px-1" style="height: 40px; border: 1px solid #e0e0e0;">
                  <button
                    v-for="opt in groupingOptions"
                    :key="opt.value"
                    class="px-3 py-1 text-caption font-weight-bold text-uppercase transition-all rounded-sm"
                    :class="groupingMode === opt.value ? 'bg-white elevation-1 text-primary' : 'text-grey-darken-1 opacity-70 hover:opacity-100'"
                    @click="groupingMode = opt.value"
                  >
                    {{ opt.label }}
                  </button>
              </div>

              <v-menu location="bottom start" :close-on-content-click="true">
                <template v-slot:activator="{ props }">
                  <v-btn v-bind="props" variant="outlined" class="btn-rect" height="40" prepend-icon="mdi-calendar-cursor" color="grey-darken-3">
                    Período Rápido
                    <v-icon end size="small">mdi-chevron-down</v-icon>
                  </v-btn>
                </template>
                <v-card class="rounded-lg elevation-4" min-width="200">
                  <v-list density="compact" nav>
                    <v-list-item v-for="p in quickPeriodOptions" :key="p.value" @click="applyPreset(p.value)" class="mb-1">
                      <v-list-item-title class="text-caption font-weight-bold">{{ p.label }}</v-list-item-title>
                    </v-list-item>
                  </v-list>
                </v-card>
              </v-menu>

              <div class="period-nav d-flex align-center justify-center px-4 rounded bg-blue-lighten-5 text-blue-darken-3 border border-blue-lighten-4" style="height: 40px;">
                 <div class="text-caption font-weight-black">
                    {{ formatDateSafe(filters.start) }} <v-icon size="12" class="mx-1">mdi-arrow-right</v-icon> {{ formatDateSafe(filters.end) }}
                 </div>
              </div>
            </div>

            <div class="d-flex align-center flex-wrap justify-end w-100 w-md-auto" style="gap: 10px;">
              <div class="search-wrap d-flex align-center flex-grow-1 flex-md-grow-0 rounded bg-grey-lighten-5 border-thin px-3" style="height: 40px; min-width: 250px;">
                <v-icon color="grey-darken-1" size="20" class="mr-2">mdi-magnify</v-icon>
                <input
                  v-model="filters.search"
                  type="text"
                  placeholder="Buscar descrição, valor ou documento..."
                  class="clean-input flex-grow-1 text-body-2"
                />
              </div>

              <v-menu v-model="filtersDropdownOpen" location="bottom end" :close-on-content-click="false" :z-index="2500">
                <template v-slot:activator="{ props }">
                  <v-btn
                    v-bind="props"
                    variant="flat"
                    class="btn-rect"
                    height="40"
                    color="grey-darken-3"
                    prepend-icon="mdi-filter-cog"
                  >
                    <span class="d-none d-sm-inline">Filtro</span>
                  </v-btn>
                </template>

                <v-card class="rounded-lg pa-4 elevation-4 border-thin" width="320">
                  <div class="text-subtitle-2 font-weight-black mb-3 text-uppercase text-grey-darken-2">Intervalo Personalizado</div>
                  <v-row dense class="row-gap-2">
                    <v-col cols="12"><label class="text-caption font-weight-bold ml-1">Início</label><v-text-field v-model="filters.start" type="date" variant="outlined" density="compact" hide-details color="primary" class="ui-input" /></v-col>
                    <v-col cols="12"><label class="text-caption font-weight-bold ml-1">Fim</label><v-text-field v-model="filters.end" type="date" variant="outlined" density="compact" hide-details color="primary" class="ui-input" /></v-col>
                  </v-row>
                  <v-btn block color="primary" class="mt-4 btn-rect font-weight-bold shadow-sm" height="36" @click="fetchStatement(); filtersDropdownOpen = false">
                      Aplicar Filtros
                  </v-btn>
                </v-card>
              </v-menu>
            </div>
          </div>
        </div>
      </div>

      <div class="flex-grow-1 overflow-y-auto custom-scroll px-4 px-md-6 pb-6">

        <div v-if="loading" class="d-flex flex-column justify-center align-center py-16">
            <v-progress-circular indeterminate color="primary" size="48" width="4" class="mb-4"></v-progress-circular>
            <span class="text-subtitle-2 font-weight-bold text-grey-darken-1">Sincronizando com Cora Bank...</span>
        </div>

        <div v-else-if="groupedData.length === 0" class="d-flex flex-column justify-center align-center py-16 opacity-60">
            <v-icon size="64" color="grey-lighten-1" class="mb-3">mdi-bank-transfer-off</v-icon>
            <div class="text-h6 font-weight-bold text-grey-darken-1">Nenhuma movimentação</div>
            <div class="text-body-2 text-grey">Tente alterar o período ou os filtros.</div>
        </div>

        <template v-else>
            <div v-for="(group, gIdx) in groupedData" :key="gIdx" class="group-container mb-8">

                <div class="group-header d-flex flex-column flex-sm-row align-start align-sm-center justify-space-between mb-2 px-1">
                    <div class="d-flex align-center gap-3 mb-2 mb-sm-0">
                        <div class="date-badge bg-grey-darken-4 text-white font-weight-black px-3 py-1 rounded elevation-2 text-uppercase text-caption ls-1">
                            {{ group.label }}
                        </div>
                        <span class="text-caption font-weight-bold text-grey-darken-1">
                            {{ group.items.length }} lançamentos
                        </span>
                    </div>
                    <div class="d-flex align-center gap-3">
                        <div class="d-flex align-center px-3 py-1 bg-green-lighten-5 text-green-darken-3 rounded border border-green-lighten-4">
                            <v-icon start size="small" color="green-darken-2">mdi-arrow-up</v-icon>
                            <span class="text-caption font-mono font-weight-black">{{ formatCurrency(group.summary.in) }}</span>
                        </div>
                        <div class="d-flex align-center px-3 py-1 bg-red-lighten-5 text-red-darken-3 rounded border border-red-lighten-4">
                            <v-icon start size="small" color="red-darken-2">mdi-arrow-down</v-icon>
                            <span class="text-caption font-mono font-weight-black">{{ formatCurrency(group.summary.out) }}</span>
                        </div>
                        <v-btn
                            size="small"
                            variant="text"
                            color="grey-darken-2"
                            icon
                            title="Imprimir este grupo"
                            :loading="generatingPdf"
                            @click="generatePDF(group.items, `Relatorio_Cora_${group.label.replace(/\//g, '-')}`)"
                        >
                            <v-icon>mdi-printer</v-icon>
                        </v-btn>
                    </div>
                </div>

                <v-card class="rounded-lg border-thin overflow-hidden shadow-sm" elevation="0">
                    <div class="table-responsive">
                        <div class="grid-statement-layout">
                            <div class="grid-header-row bg-grey-lighten-4 border-b text-grey-darken-2">
                                <div class="cell header-text center">Hora</div>
                                <div class="cell header-text center">Tipo</div>
                                <div class="cell header-text">Descrição / Motivo</div>
                                <div class="cell header-text">Contraparte</div>
                                <div class="cell header-text center">Doc. (CPF/CNPJ)</div>
                                <div class="cell header-text right pr-6">Valor (R$)</div>
                                <div class="cell header-text center">Ações</div>
                            </div>

                            <div
                                v-for="(item, i) in group.items"
                                :key="item.id"
                                class="grid-body-row transition-colors"
                                :class="getRowColorClass(item.type)"
                            >
                                <div class="cell center">
                                    <span class="font-mono text-caption font-weight-bold opacity-80">{{ formatTime(item.createdAt) }}</span>
                                </div>
                                <div class="cell center">
                                    <v-chip
                                        :color="item.type === 'CREDIT' ? 'green-darken-2' : 'red-darken-2'"
                                        size="x-small"
                                        variant="flat"
                                        class="font-weight-black px-2 uppercase"
                                    >
                                        {{ item.type === 'CREDIT' ? 'ENTRADA' : 'SAÍDA' }}
                                    </v-chip>
                                </div>
                                <div class="cell">
                                    <div class="d-flex flex-column" style="max-width: 280px;">
                                        <span class="text-caption font-weight-bold text-truncate" :title="item.transaction.description">
                                            {{ item.transaction.description }}
                                        </span>
                                        <span class="text-[10px] text-grey-darken-1 text-truncate">
                                            {{ item.transaction.title || 'Transferência Bancária' }}
                                        </span>
                                    </div>
                                </div>
                                <div class="cell">
                                    <span class="text-caption font-weight-medium text-grey-darken-3 text-truncate" style="max-width: 200px;" :title="item.transaction.counterParty?.name">
                                        {{ item.transaction.counterParty?.name || '---' }}
                                    </span>
                                </div>
                                <div class="cell center">
                                    <span class="font-mono text-[11px] text-grey-darken-2 bg-white-50 px-1 rounded">
                                        {{ formatDocument(item.transaction.counterParty?.identity) }}
                                    </span>
                                </div>
                                <div class="cell right pr-6">
                                    <span class="font-mono font-weight-black text-body-2" :class="item.type === 'CREDIT' ? 'text-green-darken-3' : 'text-red-darken-3'">
                                        {{ item.type === 'CREDIT' ? '+' : '-' }} {{ formatCurrencyValue(item.amount / 100) }}
                                    </span>
                                </div>
                                <div class="cell center">
                                    <v-btn
                                        icon
                                        size="x-small"
                                        variant="text"
                                        :color="themeStore.currentMode === 'light' ? 'grey-darken-2' : 'white'"
                                        class="opacity-70 hover:opacity-100"
                                        title="Ver Comprovante (Em Breve)"
                                    >
                                        <v-icon>mdi-eye</v-icon>
                                    </v-btn>
                                </div>
                            </div>
                        </div>
                    </div>
                </v-card>

            </div>
        </template>

      </div>
    </div>

    <v-scale-transition>
        <div v-if="feedback.show" class="feedback-toast" :class="feedback.error ? 'is-error' : 'is-success'">
            <div class="d-flex align-center">
                <v-icon color="white" class="mr-3">{{ feedback.error ? 'mdi-alert-circle' : 'mdi-check-circle' }}</v-icon>
                <div>
                    <div class="text-subtitle-2 font-weight-black text-white">{{ feedback.title }}</div>
                    <div class="text-caption text-white opacity-80">{{ feedback.message }}</div>
                </div>
                <v-btn icon size="small" variant="text" color="white" class="ml-auto" @click="feedback.show = false"><v-icon>mdi-close</v-icon></v-btn>
            </div>
        </div>
    </v-scale-transition>

  </div>
</template>

<script setup lang="ts">
import { ref, computed, reactive, onMounted, watch } from 'vue';
import { useThemeStore } from '@/stores/theme';
import { useUserStore } from '@/stores/user';
import { useCompanyStore } from '@/stores/company';
import { coraApi, type CoraStatementResponse } from '@/api/coraProxy';
import { format, parseISO, isValid, startOfMonth, endOfMonth, startOfWeek, endOfWeek, subDays, getWeek } from 'date-fns';
import { ptBR } from 'date-fns/locale'; // IMPORTANTE: Locale Português
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import logoMj from '@/assets/logo.png';

const themeStore = useThemeStore();
const userStore = useUserStore();
const companyStore = useCompanyStore();

// --- CONFIGURAÇÃO MULTI-CONTAS ---
const coraKeys: Record<string, string> = {
    '20631721000107': 'int-3VpXneDbEmHHHYFNN8hoIh',
    '53756096000189': 'int-23ze6BcCmlV6oqO2TPP01s',
};

// Estados
const loading = ref(false);
const generatingPdf = ref(false);
const statementData = ref<CoraStatementResponse | null>(null);
const entries = computed(() => statementData.value?.entries || []);
const filtersDropdownOpen = ref(false);
const groupingMode = ref<'day' | 'week' | 'month'>('day');
const hasCoraConfig = ref(true);

const currentCompanyName = computed(() => companyStore.currentCompanyName || 'Empresa');

const headerTitle = computed(() => {
    if (loading.value) return 'BUSCANDO...';
    if (!hasCoraConfig.value) return 'SEM CONFIGURAÇÃO';
    return statementData.value?.header?.businessName || currentCompanyName.value;
});

const headerColor = computed(() => (!hasCoraConfig.value ? 'red-darken-3' : 'pink-darken-3'));

// Filtros
const filters = reactive({
  start: format(subDays(new Date(), 2), 'yyyy-MM-dd'),
  end: format(new Date(), 'yyyy-MM-dd'),
  search: ''
});

// Feedback Toast
const feedback = reactive({ show: false, error: false, title: '', message: '' });
const showFeedback = (title: string, msg: string, isError = false) => {
    feedback.title = title; feedback.message = msg; feedback.error = isError; feedback.show = true;
    setTimeout(() => feedback.show = false, 4000);
};

// Permissões
const canPerformActions = computed(() => {
    const role = userStore.profile?.role?.toLowerCase();
    return userStore.isAdmin || userStore.isSuperAdmin || role === 'financeiro';
});

// Lista Filtrada (Busca)
const filteredItems = computed(() => {
    let items = entries.value;
    if (filters.search) {
        const term = filters.search.toLowerCase();
        items = items.filter(i =>
            i.transaction.description.toLowerCase().includes(term) ||
            (i.transaction.counterParty?.name || '').toLowerCase().includes(term) ||
            String(i.amount).includes(term)
        );
    }
    // Ordenar cronologicamente inverso
    return items.sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());
});

// LÓGICA DE AGRUPAMENTO (COM PT-BR)
const groupedData = computed(() => {
    const groups: Record<string, { label: string, dateObj: Date, items: any[], summary: { in: number, out: number } }> = {};

    filteredItems.value.forEach(item => {
        const date = parseISO(item.createdAt);
        if (!isValid(date)) return;

        let key = '';
        let label = '';

        if (groupingMode.value === 'day') {
            key = format(date, 'yyyy-MM-dd');
            // FORMATO BR: 10/02/2026 (Terça-feira)
            label = format(date, 'dd/MM/yyyy (EEEE)', { locale: ptBR });
        } else if (groupingMode.value === 'week') {
            const week = getWeek(date, { locale: ptBR });
            const year = date.getFullYear();
            key = `${year}-W${week}`;
            label = `Semana ${week} de ${year}`;
        } else { // month
            key = format(date, 'yyyy-MM');
            label = format(date, 'MMMM yyyy', { locale: ptBR }).toUpperCase();
        }

        if (!groups[key]) {
            groups[key] = { label, dateObj: date, items: [], summary: { in: 0, out: 0 } };
        }

        groups[key].items.push(item);

        // Sumarização
        const val = item.amount / 100;
        if (item.type === 'CREDIT') groups[key].summary.in += val;
        else groups[key].summary.out += val;
    });

    // Converter para array e ordenar (mais recente primeiro)
    return Object.values(groups).sort((a, b) => b.dateObj.getTime() - a.dateObj.getTime());
});

// Opções de Agrupamento
const groupingOptions = [
    { label: 'Dia', value: 'day' },
    { label: 'Semana', value: 'week' },
    { label: 'Mês', value: 'month' }
];

// Opções Período Rápido
const quickPeriodOptions = [
    { label: 'Hoje', value: 'today' },
    { label: 'Ontem', value: 'yesterday' },
    { label: 'Esta Semana', value: 'week' },
    { label: 'Este Mês', value: 'month' },
];

const applyPreset = (preset: string) => {
    const today = new Date();
    if (preset === 'today') {
        filters.start = format(today, 'yyyy-MM-dd');
        filters.end = format(today, 'yyyy-MM-dd');
    } else if (preset === 'yesterday') {
        filters.start = format(subDays(today, 1), 'yyyy-MM-dd');
        filters.end = format(subDays(today, 1), 'yyyy-MM-dd');
    } else if (preset === 'week') {
        filters.start = format(startOfWeek(today, { weekStartsOn: 1 }), 'yyyy-MM-dd');
        filters.end = format(endOfWeek(today, { weekStartsOn: 1 }), 'yyyy-MM-dd');
    } else if (preset === 'month') {
        filters.start = format(startOfMonth(today), 'yyyy-MM-dd');
        filters.end = format(endOfMonth(today), 'yyyy-MM-dd');
    }
    fetchStatement();
};

const fetchStatement = async () => {
    loading.value = true;
    statementData.value = null;
    hasCoraConfig.value = true;

    try {
        const currentCnpj = companyStore.currentCompanyCnpj?.replace(/\D/g, '') || '';
        const targetClientId = coraKeys[currentCnpj];

        if (!targetClientId && !companyStore.isGlobalView) {
            hasCoraConfig.value = false;
            return;
        }

        const response = await coraApi.getBankStatement({
            start: filters.start,
            end: filters.end
        }, targetClientId);

        statementData.value = response;
        if (response.entries?.length > 0) showFeedback('Sucesso', 'Extrato atualizado.', false);

    } catch (error: any) {
        console.error(error);
        showFeedback('Erro', error.message || 'Falha ao buscar extrato.', true);
    } finally {
        loading.value = false;
    }
};

// Conversão de Imagem para Base64 (para PDF)
const imageToBase64 = async (url: string): Promise<string> => {
  try {
      const res = await fetch(url);
      const blob = await res.blob();
      return await new Promise((resolve, reject) => {
        const reader = new FileReader();
        reader.onload = () => resolve(String(reader.result));
        reader.onerror = reject;
        reader.readAsDataURL(blob);
      });
  } catch { return ''; }
};

// --- GERAÇÃO DE PDF (COM CORES NAS ROWS) ---
const generatePDF = async (items: any[], reportTitle: string) => {
    if (items.length === 0) return showFeedback('Aviso', 'Nada para exportar.', true);

    generatingPdf.value = true;
    try {
        const doc = new jsPDF({ orientation: 'p', unit: 'mm', format: 'a4' });
        const pageW = doc.internal.pageSize.getWidth();
        const M = 10; // Margem
        const boxW = pageW - (M * 2);

        // --- CABEÇALHO ---
        // Logo
        try {
            const logoBase64 = await imageToBase64(logoMj);
            if (logoBase64) doc.addImage(logoBase64, 'PNG', M + 2, 10, 30, 15);
        } catch (e) { /* ignore */ }

        // Dados Empresa (Direita)
        doc.setFontSize(8);
        doc.setFont("helvetica", "bold");
        const companyName = currentCompanyName.value.toUpperCase();
        const cnpj = companyStore.currentCompanyCnpj || '---';
        doc.text(companyName, pageW - M, 14, { align: 'right' });
        doc.setFont("helvetica", "normal");
        doc.text(`CNPJ: ${cnpj}`, pageW - M, 18, { align: 'right' });
        doc.text(`Emissão: ${format(new Date(), 'dd/MM/yyyy HH:mm', { locale: ptBR })}`, pageW - M, 22, { align: 'right' });

        // Título Relatório
        doc.setDrawColor(200, 200, 200);
        doc.line(M, 30, pageW - M, 30);

        doc.setFontSize(14);
        doc.setFont("helvetica", "bold");
        doc.setTextColor(40, 40, 40);
        doc.text("EXTRATO BANCÁRIO - CORA", M, 38);

        doc.setFontSize(10);
        doc.setTextColor(100, 100, 100);
        doc.text(reportTitle.replace(/_/g, ' '), M, 44);

        // --- TABELA ---
        const tableBody = items.map(item => [
            formatDateTime(item.createdAt),
            item.type === 'CREDIT' ? 'ENTRADA' : 'SAÍDA',
            item.transaction.description + (item.transaction.title ? ` (${item.transaction.title})` : ''),
            item.transaction.counterParty?.name || '-',
            formatCurrency(item.amount / 100)
        ]);

        // Totais para o rodapé
        const totalIn = items.filter(i => i.type === 'CREDIT').reduce((acc, i) => acc + (i.amount/100), 0);
        const totalOut = items.filter(i => i.type === 'DEBIT').reduce((acc, i) => acc + (i.amount/100), 0);
        const saldo = totalIn - totalOut;

        autoTable(doc, {
            startY: 50,
            head: [['DATA/HORA', 'TIPO', 'DESCRIÇÃO', 'CONTRAPARTE', 'VALOR']],
            body: tableBody,
            theme: 'grid',
            headStyles: {
                fillColor: [33, 33, 33],
                textColor: 255,
                fontStyle: 'bold',
                fontSize: 8,
                halign: 'center'
            },
            bodyStyles: {
                fontSize: 7,
                cellPadding: 3
            },
            columnStyles: {
                0: { cellWidth: 30, halign: 'center' },
                1: { cellWidth: 20, halign: 'center', fontStyle: 'bold' },
                2: { cellWidth: 'auto' }, // Descrição flexível
                3: { cellWidth: 40 },
                4: { cellWidth: 30, halign: 'right', fontStyle: 'bold' }
            },
            // CORREÇÃO: Aplica cores nas linhas (didParseCell)
            didParseCell: (data) => {
                if (data.section === 'body') {
                    // O indice 1 é a coluna TIPO (ENTRADA ou SAÍDA)
                    const type = data.row.raw[1];

                    if (type === 'ENTRADA') {
                        // Fundo Verde Claro para toda a linha
                        data.cell.styles.fillColor = [232, 245, 233];
                        // Texto Verde Escuro
                        data.cell.styles.textColor = [27, 94, 32];
                    } else if (type === 'SAÍDA') {
                        // Fundo Vermelho Claro para toda a linha
                        data.cell.styles.fillColor = [255, 235, 238];
                        // Texto Vermelho Escuro
                        data.cell.styles.textColor = [183, 28, 28];
                    }
                }
            }
        });

        // --- CAIXA DE TOTAIS ---
        const finalY = (doc as any).lastAutoTable.finalY + 10;

        doc.setFillColor(245, 245, 245);
        doc.rect(pageW - M - 70, finalY, 70, 26, 'F');
        doc.setDrawColor(200);
        doc.rect(pageW - M - 70, finalY, 70, 26, 'S');

        doc.setFontSize(9);
        doc.setTextColor(0);

        doc.text("Total Entradas:", pageW - M - 65, finalY + 6);
        doc.setTextColor(27, 94, 32); doc.setFont("helvetica", "bold");
        doc.text(formatCurrency(totalIn), pageW - M - 5, finalY + 6, { align: 'right' });

        doc.setTextColor(0); doc.setFont("helvetica", "normal");
        doc.text("Total Saídas:", pageW - M - 65, finalY + 13);
        doc.setTextColor(183, 28, 28); doc.setFont("helvetica", "bold");
        doc.text(formatCurrency(totalOut), pageW - M - 5, finalY + 13, { align: 'right' });

        doc.setDrawColor(200);
        doc.line(pageW - M - 65, finalY + 17, pageW - M - 5, finalY + 17);

        doc.setTextColor(0); doc.setFont("helvetica", "bold");
        doc.text("Saldo do Período:", pageW - M - 65, finalY + 22);
        doc.setTextColor(saldo >= 0 ? 27 : 183, saldo >= 0 ? 94 : 28, saldo >= 0 ? 32 : 28);
        doc.text(formatCurrency(saldo), pageW - M - 5, finalY + 22, { align: 'right' });

        doc.save(`${reportTitle}.pdf`);
        showFeedback('Download', 'Relatório gerado com sucesso.', false);

    } catch (error: any) {
        console.error("Erro PDF:", error);
        showFeedback('Erro', 'Falha ao gerar PDF.', true);
    } finally {
        generatingPdf.value = false;
    }
};

// Utils
const formatCurrency = (val: number) => new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(val);
const formatCurrencyValue = (val: number) => new Intl.NumberFormat('pt-BR', { minimumFractionDigits: 2 }).format(val);
const formatDateSafe = (dateString?: string) => {
    if (!dateString) return '-';
    const [y, m, d] = dateString.split('-');
    return `${d}/${m}/${y}`;
};
const formatDateTime = (isoString: string) => {
    if (!isoString) return '-';
    try {
        const date = parseISO(isoString);
        if (!isValid(date)) return '-';
        return format(date, 'dd/MM/yyyy HH:mm', { locale: ptBR });
    } catch { return '-'; }
};
const formatTime = (isoString: string) => {
    if (!isoString) return '-';
    try { return format(parseISO(isoString), 'HH:mm'); } catch { return '-'; }
};
const formatDocument = (doc: string | undefined) => {
    if (!doc) return '-';
    if (doc.length === 11) return doc.replace(/(\d{3})(\d{3})(\d{3})(\d{2})/, '$1.$2.$3-$4');
    if (doc.length === 14) return doc.replace(/(\d{2})(\d{3})(\d{3})(\d{4})(\d{2})/, '$1.$2.$3/$4-$5');
    return doc;
};

// Cores das linhas
const getRowColorClass = (type: string) => {
    // Opacidade controlada para legibilidade
    return type === 'CREDIT' ? 'bg-green-soft border-l-4-green' : 'bg-red-soft border-l-4-red';
};

watch(() => companyStore.context, () => fetchStatement());
onMounted(() => fetchStatement());
</script>

<style scoped lang="scss">
/* Layout Geral */
.receivables-layout { position: relative; }
.bg-glass-dark { background: rgba(10,10,12,0.95); }
.bg-glass-header { background: rgba(20,20,24,0.85); backdrop-filter: blur(10px); }
.border-bottom-white-05 { border-bottom: 1px solid rgba(255,255,255,0.08); }
.btn-rect { border-radius: 4px !important; text-transform: none !important; font-weight: 800; letter-spacing: 0.5px; }
.clean-input { border: none; outline: none; flex: 1; font-size: 13px; }
.ls-1 { letter-spacing: 1px; }
.gap-2 { gap: 8px; } .gap-3 { gap: 12px; }

/* Grid Layout Customizado com Header Fixo e Alinhado */
.table-responsive {
    overflow-x: auto;
    -webkit-overflow-scrolling: touch;
}

.grid-statement-layout {
    display: table; /* Fallback simples */
    width: 100%;
    min-width: 1000px; /* Garante que não esmague em telas pequenas */
}

/* Header e Row Definitions */
.grid-header-row, .grid-body-row {
    display: grid;
    /* Hora | Tipo | Descrição | Contraparte | Doc | Valor | Ações */
    grid-template-columns: 80px 100px minmax(250px, 2fr) minmax(200px, 1fr) 140px 140px 60px;
    align-items: center;
}

.cell {
    padding: 8px 12px;
    display: flex;
    align-items: center;
    border-right: 1px solid rgba(0,0,0,0.05);
    min-height: 48px;
    font-size: 12px;
}
.cell:last-child { border-right: none; }

.header-text {
    font-size: 11px;
    font-weight: 900;
    text-transform: uppercase;
    letter-spacing: 0.5px;
    color: #616161;
}

.center { justify-content: center; text-align: center; }
.right { justify-content: flex-end; text-align: right; }

/* Cores das Linhas (Fundo Opaco) */
.bg-green-soft { background-color: rgba(76, 175, 80, 0.08); }
.bg-red-soft { background-color: rgba(244, 67, 54, 0.08); }
.border-l-4-green { border-left: 4px solid #2e7d32 !important; }
.border-l-4-red { border-left: 4px solid #c62828 !important; }

.hover-opacity-100:hover { opacity: 1 !important; }

/* Inputs Customizados */
.ui-input :deep(.v-field__input) { min-height: 32px !important; padding-top: 4px; padding-bottom: 4px; font-size: 13px; }

/* Feedback Toast */
.feedback-toast {
    position: fixed;
    bottom: 24px;
    right: 24px;
    padding: 16px 20px;
    border-radius: 8px;
    box-shadow: 0 10px 30px rgba(0,0,0,0.3);
    z-index: 9999;
    min-width: 300px;
}
.feedback-toast.is-success { background: #2e7d32; }
.feedback-toast.is-error { background: #c62828; }

/* Background */
.background-carousel-wrapper { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 0; }
.background-overlay { position: absolute; top: 0; left: 0; width: 100%; height: 100%; background: rgba(10,10,12,0.85); z-index: 1; }
</style>
