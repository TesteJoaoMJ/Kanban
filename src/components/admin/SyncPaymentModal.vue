<template>
  <v-dialog
    :model-value="modelValue"
    @update:model-value="$emit('update:modelValue', $event)"
    width="1750"
    max-width="99vw"
    persistent
    scrim="black opacity-80"
  >
    <v-card class="sync-modal d-flex flex-column" height="920" style="max-height: 92vh;">

      <div class="header-bar px-6 py-4 d-flex align-center justify-space-between flex-shrink-0 bg-white border-b">
        <div class="d-flex flex-column">
          <div class="text-caption font-weight-black opacity-70 text-uppercase letter-spacing-1">Módulo de Integração</div>
          <div class="text-h6 font-weight-black text-grey-darken-3 mt-1">
            Sincronização ERP <span class="text-grey font-weight-regular">| GestãoClick</span>
          </div>
          <div class="text-caption text-grey-darken-1 mt-1">
            Detecta alterações em: <b>Valores, Datas (Venc/Comp/Pag), Status e Descrições</b>.
          </div>
        </div>

        <div class="d-flex align-center" style="gap: 10px;">
          <v-chip v-if="step !== 3" size="small" variant="outlined" color="grey-darken-2" class="chip-mini">
            <v-icon start size="16">mdi-calendar-range</v-icon>
            {{ config.startDate }} → {{ config.endDate }}
          </v-chip>

          <v-btn icon variant="text" density="comfortable" @click="close" :disabled="loadingFetch || execution.processing">
            <v-icon>mdi-close</v-icon>
          </v-btn>
        </div>
      </div>

      <div class="px-6 py-2 flex-shrink-0 bg-grey-lighten-5 border-b">
        <div class="stepbar py-2">
          <div class="step-item" :class="step >= 1 ? 'active' : ''">
            <div class="dot">1</div>
            <div class="lbl">Parâmetros</div>
          </div>
          <div class="line"></div>
          <div class="step-item" :class="step >= 2 ? 'active' : ''">
            <div class="dot">2</div>
            <div class="lbl">Análise & Seleção</div>
          </div>
          <div class="line"></div>
          <div class="step-item" :class="step >= 3 ? 'active success' : ''">
            <div class="dot">3</div>
            <div class="lbl">Processamento</div>
          </div>
        </div>
      </div>

      <div class="flex-grow-1 d-flex flex-column overflow-hidden bg-white">

        <div v-if="step === 1" class="step-body d-flex align-center justify-center overflow-y-auto custom-scroll bg-grey-lighten-5">
          <v-card class="pa-8 bg-white border-thin shadow-sm" width="820" elevation="0">

            <div class="d-flex justify-space-between align-start mb-6">
              <div>
                <div class="text-h6 font-weight-black text-grey-darken-3">Critérios de Busca</div>
                <div class="text-caption text-grey-darken-1 mt-1">
                  O sistema buscará dados no ERP e comparará com a base local.
                </div>
              </div>
            </div>

            <div class="form-section">
              <div class="section-title">
                <v-icon size="18" color="error">mdi-filter-check</v-icon>
                <span>Filtros de Busca</span>
              </div>

              <v-row dense class="row-gap mt-2">
                <v-col cols="12" md="7">
                  <v-select
                    label="Status no ERP"
                    v-model="config.status"
                    :items="statusItems"
                    variant="outlined"
                    density="comfortable"
                    color="error"
                    prepend-inner-icon="mdi-filter-check"
                    class="ui-field"
                    hide-details
                  />
                </v-col>

                <v-col cols="12" md="5" class="d-flex align-center">
                  <v-checkbox
                    v-model="config.onlyNew"
                    label="Ocultar itens idênticos (Sincronizados)"
                    density="compact"
                    color="error"
                    hide-details
                    class="font-weight-bold"
                    messages="Se desmarcado, mostra até o que já está igual."
                  />
                </v-col>
              </v-row>
            </div>

            <div class="form-section mt-6">
              <div class="section-title">
                <v-icon size="18" color="error">mdi-calendar-range</v-icon>
                <span>Período de Vencimento</span>
              </div>

              <div class="d-flex flex-wrap mt-3" style="gap: 10px;">
                <v-btn
                  v-for="opt in dateOptions"
                  :key="opt.id"
                  class="btn-rect"
                  height="42"
                  min-width="160"
                  :variant="config.quickDate === opt.id ? 'flat' : 'outlined'"
                  :color="config.quickDate === opt.id ? 'error' : 'grey-darken-1'"
                  @click="setSyncDate(opt.id)"
                >
                  {{ opt.label }}
                </v-btn>
              </div>

              <v-row dense class="row-gap mt-4">
                <v-col cols="12" md="6">
                  <v-text-field
                    label="Data Início"
                    type="date"
                    v-model="config.startDate"
                    variant="outlined"
                    density="comfortable"
                    color="error"
                    class="ui-field"
                    hide-details
                  />
                </v-col>
                <v-col cols="12" md="6">
                  <v-text-field
                    label="Data Fim"
                    type="date"
                    v-model="config.endDate"
                    variant="outlined"
                    density="comfortable"
                    color="error"
                    class="ui-field"
                    hide-details
                  />
                </v-col>
              </v-row>
            </div>
          </v-card>
        </div>

        <div v-else-if="step === 2" class="step-body d-flex flex-column h-100 overflow-hidden">

          <div v-if="loadingFetch" class="d-flex flex-column align-center justify-center flex-grow-1 bg-white">
            <v-progress-circular indeterminate color="error" size="64" width="6" class="mb-4" />
            <div class="text-h6 font-weight-black text-grey-darken-3">Analisando Dados...</div>
            <div class="text-body-2 text-grey">Comparando valores, datas e status com o ERP.</div>
          </div>

          <div v-else-if="previewData.length === 0" class="d-flex flex-column align-center justify-center flex-grow-1 bg-white">
            <v-icon size="80" color="grey-lighten-2" class="mb-4">mdi-check-all</v-icon>
            <div class="text-h5 font-weight-black text-grey-darken-2">Tudo Sincronizado!</div>
            <p class="text-body-1 text-grey mb-6">Nenhuma diferença encontrada para os filtros selecionados.</p>
            <v-btn variant="outlined" class="btn-rect" color="grey-darken-2" @click="step = 1">Voltar e Ajustar</v-btn>
          </div>

          <div v-else class="d-flex flex-column h-100 overflow-hidden">

            <div class="kpi-wrap px-6 pt-5 pb-4 bg-white border-b flex-shrink-0">
              <div class="kpi-grid">
                <div class="kpi-card">
                  <div class="kpi-top">
                    <div class="kpi-label">Pendentes de Ação</div>
                    <v-icon size="18" color="blue-grey">mdi-database-sync</v-icon>
                  </div>
                  <div class="kpi-value">{{ filteredPreview.length }}</div>
                  <div class="kpi-sub">Novos ou Alterados</div>
                </div>

                <div class="kpi-card warn">
                  <div class="kpi-top">
                    <div class="kpi-label">Sem Loja Definida</div>
                    <v-icon size="18" color="orange">mdi-domain-off</v-icon>
                  </div>
                  <div class="kpi-value">{{ kpiUnassigned.count }}</div>
                  <div class="kpi-sub">{{ formatCurrency(kpiUnassigned.value) }}</div>
                </div>

                <div class="kpi-card success">
                  <div class="kpi-top">
                    <div class="kpi-label">Selecionados p/ Importar</div>
                    <v-icon size="18" color="success">mdi-check-all</v-icon>
                  </div>
                  <div class="kpi-value">{{ selectedIds.size }}</div>
                  <div class="kpi-sub">{{ formatCurrency(totalSelectedValue) }}</div>
                </div>
              </div>

              <div class="toolbar mt-4">
                <v-row dense class="row-gap align-end">
                  <v-col cols="12" md="4">
                    <div class="field-label">Pesquisa Rápida</div>
                    <v-text-field
                      v-model="localSearch"
                      placeholder="Buscar..."
                      prepend-inner-icon="mdi-magnify"
                      variant="outlined"
                      density="compact"
                      hide-details
                      class="ui-field"
                      color="error"
                      clearable
                    />
                  </v-col>

                  <v-col cols="12" md="5">
                    <div class="field-label">Definir Loja em Massa</div>
                    <div class="d-flex align-center" style="gap: 10px;">
                        <v-select
                          v-model="bulkCompanyId"
                          :items="companies"
                          item-title="trade_name"
                          item-value="id"
                          placeholder="Selecione..."
                          variant="outlined"
                          density="compact"
                          hide-details
                          class="ui-field flex-grow-1"
                          clearable
                          color="error"
                          :menu-props="{ maxHeight: 320 }"
                        />
                        <v-btn
                          variant="flat"
                          color="error"
                          class="btn-rect font-weight-black"
                          height="36"
                          prepend-icon="mdi-domain-plus"
                          :disabled="!bulkCompanyId || filteredPreview.length === 0"
                          @click="applyBulkMenuOpen = true"
                        >
                          Aplicar
                        </v-btn>
                        <v-menu v-model="applyBulkMenuOpen" location="bottom end">
                          <v-list density="compact" nav class="rounded-0">
                            <v-list-item @click="applyBulkToSelected" :disabled="selectedIds.size === 0 || !bulkCompanyId">
                              <v-list-item-title class="text-body-2 font-weight-bold"><v-icon start size="18">mdi-check-all</v-icon> Em selecionados</v-list-item-title>
                            </v-list-item>
                            <v-list-item @click="applyBulkToFiltered" :disabled="filteredPreview.length === 0 || !bulkCompanyId">
                              <v-list-item-title class="text-body-2 font-weight-bold"><v-icon start size="18">mdi-filter</v-icon> Em filtrados</v-list-item-title>
                            </v-list-item>
                          </v-list>
                        </v-menu>
                    </div>
                  </v-col>

                  <v-col cols="12" md="3" class="d-flex justify-end">
                    <v-btn variant="outlined" class="btn-rect" height="36" color="grey-darken-2" prepend-icon="mdi-select-all" @click="selectAllFiltered" :disabled="filteredPreview.length === 0">Todos</v-btn>
                    <v-btn variant="outlined" class="btn-rect ml-2" height="36" color="grey-darken-2" prepend-icon="mdi-selection-off" @click="clearSelection" :disabled="selectedIds.size === 0">Limpar</v-btn>
                  </v-col>
                </v-row>
              </div>
            </div>

            <div class="flex-grow-1 d-flex flex-column overflow-hidden bg-white relative border-b" style="min-height: 0;">
              <div class="grid-header sticky-head grid-sync flex-shrink-0 bg-grey-lighten-4">
                <div class="cell center">
                  <v-checkbox-btn :model-value="areAllSelected" @update:model-value="toggleSelectAll" density="compact" color="error" class="chk-fixed" />
                </div>
                <div class="cell header-text">Descrição</div>
                <div class="cell header-text">Beneficiário</div>
                <div class="cell header-text">Plano Contas</div>
                <div class="cell header-text">Loja</div>
                <div class="cell center header-text">Vencimento</div>
                <div class="cell center header-text">Competência</div>
                <div class="cell center header-text">Pagamento</div>

                <div class="cell center header-text">Valor</div>
                <div class="cell center header-text">Status ERP</div>
                <div class="cell center header-text">Ação</div>
              </div>

              <div ref="gridScrollRef" class="grid-scroll flex-grow-1 overflow-y-auto custom-scroll">
                <div
                  v-for="(item, index) in paginatedPreview"
                  :key="item.uniqueKey"
                  class="grid-row grid-sync"
                  :class="[
                    selectedIds.has(item.uniqueKey) ? 'grid-selected' : (index % 2 === 0 ? 'bg-white' : 'bg-grey-lighten-5')
                  ]"
                  @click="toggleSelection(item.uniqueKey)"
                >
                  <div class="cell center" @click.stop>
                    <v-checkbox-btn :model-value="selectedIds.has(item.uniqueKey)" @update:model-value="toggleSelection(item.uniqueKey)" density="compact" color="error" class="chk-fixed" />
                  </div>

                  <div class="cell font-weight-bold text-caption text-truncate" :title="item.descricao">
                    {{ item.descricao }}
                  </div>

                  <div class="cell text-caption text-truncate" :title="item.display_name">
                    {{ item.display_name || '-' }}
                  </div>

                  <div class="cell">
                    <span v-if="item.nome_plano_conta" class="text-caption font-weight-medium text-blue-grey-darken-2 text-truncate" :title="item.nome_plano_conta">
                      {{ item.nome_plano_conta }}
                    </span>
                    <span v-else class="text-caption text-grey opacity-50">-</span>
                  </div>

                  <div class="cell" @click.stop>
                    <v-select
                      v-model="item.company_id"
                      :items="companies"
                      item-title="trade_name"
                      item-value="id"
                      placeholder="(sem loja)"
                      variant="outlined"
                      density="compact"
                      hide-details
                      class="ui-field row-company"
                      clearable
                      color="error"
                      :menu-props="{ maxHeight: 320 }"
                    />
                  </div>

                  <div class="cell center text-caption font-mono">
                    {{ formatDateBr(item.data_vencimento) }}
                  </div>
                  <div class="cell center text-caption font-mono text-blue-grey">
                    {{ formatDateBr(item.preview_competencia) }}
                  </div>
                  <div class="cell center text-caption font-mono" :class="item.preview_pagamento ? 'text-success font-weight-bold' : 'text-grey-lighten-1'">
                    {{ formatDateBr(item.preview_pagamento) || '-' }}
                  </div>

                  <div class="cell center font-mono font-weight-black text-caption">
                    {{ formatCurrency(item.valor_total || item.valor) }}
                  </div>

                  <div class="cell center">
                    <span class="solid-chip" :class="getErpStatus(item.liquidado) === 'pago' ? 'chip-success' : 'chip-warn'">
                      {{ getErpStatus(item.liquidado) === 'pago' ? 'PAGO' : 'ABERTO' }}
                    </span>
                  </div>

                  <div class="cell center">
                    <span class="text-[10px] font-weight-bold text-uppercase" :class="item.sync_type === 'update' ? 'text-info' : 'text-success'">
                      {{ item.sync_type === 'update' ? 'Atualização' : 'Novo' }}
                    </span>
                  </div>
                </div>
              </div>

              <div class="px-6 py-2 bg-grey-lighten-5 d-flex align-center justify-space-between flex-shrink-0 border-t">
                <div class="text-caption font-weight-bold text-grey-darken-3">
                  Total Selecionado: {{ formatCurrency(totalSelectedValue) }}
                </div>
                <v-pagination
                  v-model="page"
                  :length="totalPages"
                  :total-visible="7"
                  density="compact"
                  active-color="error"
                  variant="tonal"
                  size="small"
                  class="ma-0"
                />
              </div>
            </div>
          </div>
        </div>

        <div v-else-if="step === 3" class="step-body d-flex flex-column align-center justify-center flex-grow-1 pa-10 bg-white">
          <div class="w-100 text-center" style="max-width: 560px;">
            <v-progress-linear
              v-model="execution.percent"
              color="success"
              height="24"
              striped
              rounded
              class="mb-6"
            >
              <template v-slot:default="{ value }">
                <strong class="text-white text-caption">{{ Math.ceil(value) }}%</strong>
              </template>
            </v-progress-linear>

            <h3 class="text-h5 font-weight-black text-grey-darken-3 mb-2">Sincronizando Dados</h3>
            <p class="text-body-1 text-grey mb-8">
              Processando <strong>{{ execution.current }}</strong> de <strong>{{ execution.total }}</strong> registros...
            </p>

            <div class="pa-4 bg-grey-lighten-5 border-thin rounded text-left">
              <div class="text-caption font-weight-black text-uppercase text-grey mb-1">Status Atual</div>
              <div class="text-caption font-mono text-truncate">{{ execution.statusText }}</div>
            </div>
          </div>
        </div>

      </div>

      <div class="sync-foot px-6 py-4 d-flex justify-end bg-white border-t flex-shrink-0" style="gap: 12px;" v-if="step !== 3">
        <v-btn variant="outlined" class="btn-rect" height="44" @click="close" :disabled="loadingFetch" color="grey-darken-2">
          Cancelar
        </v-btn>

        <v-btn v-if="step === 1" color="error" variant="flat" class="btn-rect px-6 font-weight-black" height="44" @click="fetchPreview" :loading="loadingFetch">
          ANÁLISE DE DADOS <v-icon end>mdi-arrow-right</v-icon>
        </v-btn>

        <v-btn v-if="step === 2" color="success" variant="flat" class="btn-rect px-6 font-weight-black" height="44" @click="executeSync" :disabled="selectedIds.size === 0">
          <v-icon start>mdi-database-sync</v-icon>
          SINCRONIZAR ({{ selectedIds.size }})
        </v-btn>
      </div>

    </v-card>
  </v-dialog>
</template>

<script setup lang="ts">
import { ref, reactive, computed, watch, onMounted, nextTick } from 'vue';
import { supabase } from '@/api/supabase';
import { gestaoApi } from '@/api/gestaoClick';
import { format, startOfMonth, endOfMonth, startOfYear, endOfYear, subMonths, parseISO, isSameDay } from 'date-fns';
import { useAppStore } from '@/stores/app';

const props = defineProps<{ modelValue: boolean }>();
const emit = defineEmits(['update:modelValue', 'synced']);
const appStore = useAppStore();

const step = ref(1);
const loadingFetch = ref(false);
const applyBulkMenuOpen = ref(false);
const companies = ref<any[]>([]);
const localSearch = ref('');
const localChartFilters = ref<string[]>([]);
const companyFilterId = ref<string | null>(null);
const page = ref(1);
const itemsPerPage = 50;
const gridScrollRef = ref<HTMLElement | null>(null);
const bulkCompanyId = ref<string | null>(null);

const config = reactive({
  erpSource: 'gestaoclick',
  status: 'todos',
  quickDate: 'this_month',
  startDate: format(startOfMonth(new Date()), 'yyyy-MM-dd'),
  endDate: format(endOfMonth(new Date()), 'yyyy-MM-dd'),
  onlyNew: true
});

const statusItems = [
  { title: 'Todos (Abertos e Pagos)', value: 'todos' },
  { title: 'Apenas Em Aberto', value: 'ab' },
  { title: 'Apenas Pagos (Liquidados)', value: 'pg' }
];

const dateOptions = [
  { id: 'this_month', label: 'Este Mês' },
  { id: 'last_month', label: 'Mês Passado' },
  { id: 'this_year', label: 'Este Ano' }
];

const previewData = ref<any[]>([]);
const selectedIds = ref(new Set<string>());

const execution = reactive({ processing: false, percent: 0, current: 0, total: 0, statusText: '' });

watch(() => props.modelValue, (val) => { if (val) { resetModal(); fetchCompanies(); } });
onMounted(() => fetchCompanies());
watch(() => [localSearch.value, localChartFilters.value, companyFilterId.value], async () => { page.value = 1; await nextTick(); if (gridScrollRef.value) gridScrollRef.value.scrollTop = 0; }, { deep: true });

const resetModal = () => {
  step.value = 1;
  previewData.value = [];
  selectedIds.value.clear();
  localSearch.value = '';
  localChartFilters.value = [];
  companyFilterId.value = null;
  bulkCompanyId.value = null;
  page.value = 1;
  execution.processing = false;
};

const close = () => emit('update:modelValue', false);

const setSyncDate = (type: string) => {
  config.quickDate = type;
  const now = new Date();
  if (type === 'this_month') { config.startDate = format(startOfMonth(now), 'yyyy-MM-dd'); config.endDate = format(endOfMonth(now), 'yyyy-MM-dd'); }
  else if (type === 'last_month') { const last = subMonths(now, 1); config.startDate = format(startOfMonth(last), 'yyyy-MM-dd'); config.endDate = format(endOfMonth(last), 'yyyy-MM-dd'); }
  else if (type === 'this_year') { config.startDate = format(startOfYear(now), 'yyyy-MM-dd'); config.endDate = format(endOfYear(now), 'yyyy-MM-dd'); }
};

const fetchCompanies = async () => {
  const { data } = await supabase.from('companies').select('id, trade_name').order('trade_name');
  companies.value = data || [];
};

const resolveEntityInfo = (item: any) => {
  if (item.nome_funcionario) return { name: item.nome_funcionario, type: 'funcionario' };
  if (item.nome_fornecedor) return { name: item.nome_fornecedor, type: 'fornecedor' };
  if (item.nome_cliente) return { name: item.nome_cliente, type: 'cliente' };
  if (item.nome_transportadora) return { name: item.nome_transportadora, type: 'transportadora' };
  return { name: item.nome_entidade || 'Beneficiário Desconhecido', type: 'unknown' };
};

// -- LÓGICA DE COMPARAÇÃO PROFUNDA (DEEP DIFF) --
const hasRecordChanged = (apiItem: any, localItem: any) => {
  // 1. Status
  const apiStatus = getErpStatus(apiItem.liquidado);
  if (apiStatus !== localItem.status) return true;

  // 2. Valores (tolerância de 0.01)
  const apiVal = parseFloat(apiItem.valor_total || apiItem.valor || 0);
  const localVal = parseFloat(localItem.value || 0);
  if (Math.abs(apiVal - localVal) > 0.01) return true;

  // 3. Data de Vencimento
  const apiDue = safeDate(apiItem.data_vencimento);
  const localDue = localItem.due_date;
  if (apiDue !== localDue) return true;

  // 4. Data de Competência (se houver no API)
  const apiComp = safeDate(apiItem.preview_competencia) || apiDue;
  const localComp = localItem.competence_date;
  if (apiComp && localComp && apiComp !== localComp) return true;

  // 5. Data de Pagamento (se status pago)
  if (apiStatus === 'pago') {
      const apiPay = safeDate(apiItem.preview_pagamento) || apiDue;
      const localPay = localItem.payment_date;
      if (apiPay && localPay && apiPay !== localPay) return true;
  }

  // 6. Descrição (opcional, pode gerar muito ruído, mas usuário pediu "tudo")
  const apiDesc = sanitizeText(apiItem.descricao);
  const localDesc = sanitizeText(localItem.description);
  if (apiDesc !== localDesc) return true;

  return false;
};

const fetchPreview = async () => {
  loadingFetch.value = true;
  try {
    const params: any = { limit: 500, itens_por_pagina: 500, data_inicio: config.startDate, data_fim: config.endDate, loja_id: 523283 };
    if (config.status === 'ab') params.liquidado = '0';
    else if (config.status === 'pg') params.liquidado = '1';

    let apiData = await gestaoApi.buscarPagamentos(params);
    if (!Array.isArray(apiData)) apiData = [];

    // Mapeamento e Normalização das Datas para Preview
    let mapped = apiData.map((item: any) => {
      const entityInfo = resolveEntityInfo(item);
      return {
        ...item,
        uniqueKey: String(item.id),
        nome_plano_conta: item.nome_plano_conta || item.categoria || null,
        display_name: entityInfo.name,
        tipo_entidade: entityInfo.type,
        company_id: null,
        sync_type: 'new',
        // Normalização importante: tenta pegar qualquer campo que pareça data
        preview_competencia: item.data_competencia || item.competencia || item.data_vencimento,
        preview_pagamento: item.data_liquidacao || item.data_pagamento || (item.liquidado == '1' ? item.data_vencimento : null)
      };
    });

    // Lógica de Comparação com Banco Local
    const apiIds = mapped.map((i: any) => String(i.id));
    const localMap = new Map<string, any>();
    const chunkSize = 500;

    // Busca em lotes no Supabase
    for (let i = 0; i < apiIds.length; i += chunkSize) {
      const chunk = apiIds.slice(i, i + chunkSize);
      const { data: existing } = await supabase
        .from('finance_payables')
        .select('id, gestao_click_id, status, value, due_date, competence_date, payment_date, description')
        .in('gestao_click_id', chunk);

      existing?.forEach(e => localMap.set(String(e.gestao_click_id), e));
    }

    // Classificação (Novo vs Atualização vs Ignorado)
    mapped = mapped.map((item: any) => {
      const localItem = localMap.get(String(item.id));

      if (!localItem) {
        return { ...item, sync_type: 'new' }; // Não existe -> Novo
      }

      // Existe -> Verifica se mudou algo
      if (hasRecordChanged(item, localItem)) {
        return { ...item, sync_type: 'update' }; // Mudou -> Update
      }

      // Se config.onlyNew for true, retorna null para filtrar. Senão retorna update (ou podemos criar um status 'synced' mas a grid espera 'update' ou 'new')
      return config.onlyNew ? null : { ...item, sync_type: 'update' }; // Se quiser ver os iguais, marca como 'update' (overwrite)
    }).filter((i: any) => i !== null);

    previewData.value = mapped;
    selectedIds.value.clear();
    step.value = 2;
    await nextTick();
    if (gridScrollRef.value) gridScrollRef.value.scrollTop = 0;
  } catch (e: any) {
    appStore.showSnackbar('Erro ao buscar dados: ' + (e?.message || 'Falha'), 'error');
  } finally {
    loadingFetch.value = false;
  }
};

const uniqueChartNames = computed(() => { const s = new Set<string>(); previewData.value.forEach(i => { if (i.nome_plano_conta) s.add(i.nome_plano_conta); }); return Array.from(s).sort(); });
const filteredPreview = computed(() => {
  let items = previewData.value;
  if (localSearch.value) { const search = localSearch.value.toLowerCase(); items = items.filter(i => (i.descricao || '').toLowerCase().includes(search) || (i.display_name || '').toLowerCase().includes(search)); }
  if (localChartFilters.value?.length) { const set = new Set(localChartFilters.value); items = items.filter(i => i.nome_plano_conta && set.has(i.nome_plano_conta)); }
  if (companyFilterId.value) { items = items.filter(i => i.company_id === companyFilterId.value); }
  return items;
});
const totalPages = computed(() => Math.max(1, Math.ceil(filteredPreview.value.length / itemsPerPage)));
const paginatedPreview = computed(() => { const start = (page.value - 1) * itemsPerPage; return filteredPreview.value.slice(start, start + itemsPerPage); });
const areAllSelected = computed(() => filteredPreview.value.length > 0 && filteredPreview.value.every(i => selectedIds.value.has(i.uniqueKey)));
const totalSelectedValue = computed(() => previewData.value.filter(i => selectedIds.value.has(i.uniqueKey)).reduce((acc, i) => acc + (parseFloat(i.valor_total || i.valor || 0)), 0));
const kpiUnassigned = computed(() => { const items = filteredPreview.value; let count = 0; let value = 0; for (const i of items) { if (!i.company_id) { count++; value += Number(i.valor_total || i.valor || 0); } } return { count, value }; });

const toggleSelectAll = (val: boolean) => { if (val) filteredPreview.value.forEach(i => selectedIds.value.add(i.uniqueKey)); else filteredPreview.value.forEach(i => selectedIds.value.delete(i.uniqueKey)); };
const toggleSelection = (id: string) => { if (selectedIds.value.has(id)) selectedIds.value.delete(id); else selectedIds.value.add(id); };
const selectAllFiltered = () => filteredPreview.value.forEach(i => selectedIds.value.add(i.uniqueKey));
const clearSelection = () => selectedIds.value.clear();
const applyBulkToSelected = () => { applyBulkMenuOpen.value = false; if (!bulkCompanyId.value) return; const id = bulkCompanyId.value; previewData.value.forEach(item => { if (selectedIds.value.has(item.uniqueKey)) item.company_id = id; }); appStore.showSnackbar('Loja aplicada nos selecionados.', 'success'); };
const applyBulkToFiltered = () => { applyBulkMenuOpen.value = false; if (!bulkCompanyId.value) return; const id = bulkCompanyId.value; filteredPreview.value.forEach(item => { item.company_id = id; }); appStore.showSnackbar('Loja aplicada nos filtrados.', 'success'); };

const ensureChartOfAccounts = async (chartName: string) => {
  if (!chartName) return null;
  const name = chartName.trim();
  const { data: existing } = await supabase.from('finance_chart_of_accounts').select('id').eq('name', name).eq('type', 'Despesa').maybeSingle();
  if (existing) return existing.id;
  const newCode = `ERP-${Date.now().toString().slice(-5)}`;
  const { data: created } = await supabase.from('finance_chart_of_accounts').insert({ name, type: 'Despesa', code: newCode, active: true, is_group: false }).select('id').single();
  return created?.id;
};

const executeSync = async () => {
  execution.processing = true;
  step.value = 3;
  const itemsToProcess = previewData.value.filter(i => selectedIds.value.has(i.uniqueKey));
  execution.total = itemsToProcess.length;
  execution.current = 0;

  const chartCache = new Map<string, string>();
  const { data: localSuppliers } = await supabase.from('customers_mj').select('id, gestao_click_id');
  const supplierMap = new Map<string, string>();
  localSuppliers?.forEach(c => { if (c.gestao_click_id) supplierMap.set(String(c.gestao_click_id), c.id); });

  let successCount = 0;
  for (const item of itemsToProcess) {
    try {
      execution.statusText = item.descricao;
      const chartName = item.nome_plano_conta;
      let chartId: string | null = null;
      if (chartName) {
        if (chartCache.has(chartName)) chartId = chartCache.get(chartName)!;
        else { const id = await ensureChartOfAccounts(chartName); if (id) { chartId = id; chartCache.set(chartName, id); } }
      }
      const status = getErpStatus(item.liquidado);
      let supplier_uuid: string | null = null;
      if (item.fornecedor_id) supplier_uuid = supplierMap.get(String(item.fornecedor_id)) || null;

      // PAYLOAD ATUALIZADO COM DATAS CORRETAS
      const payload: any = {
        gestao_click_id: String(item.id),
        description: sanitizeText(item.descricao),
        value: parseFloat(item.valor_total || item.valor || 0),
        discount: parseFloat(item.desconto || 0),

        // DATAS: Usa a lógica de preview que já normalizou os campos
        due_date: safeDate(item.data_vencimento),
        competence_date: safeDate(item.preview_competencia),
        payment_date: safeDate(item.preview_pagamento),

        status: status,
        supplier_id: supplier_uuid,
        entity_name: sanitizeText(item.display_name),
        notes: `Centro Custo: ${item.nome_centro_custo || '-'}`,
        chart_of_accounts_id: chartId,
        company_id: item.company_id || null,
      };

      const { data: existingRecord } = await supabase.from('finance_payables').select('id').eq('gestao_click_id', payload.gestao_click_id).maybeSingle();
      if (existingRecord) await supabase.from('finance_payables').update(payload).eq('id', existingRecord.id);
      else await supabase.from('finance_payables').insert(payload);
      successCount++;
    } catch (err) { console.error(err); }
    execution.current++;
    execution.percent = (execution.current / execution.total) * 100;
    if (execution.current % 10 === 0) await new Promise(r => setTimeout(r, 10));
  }
  appStore.showSnackbar(`${successCount} itens atualizados!`, 'success');
  emit('synced');
  close();
};

const getErpStatus = (val: any) => { const s = String(val).toLowerCase(); if (['1', 's', 'sim', 'true', 'confirmado', 'pago'].includes(s)) return 'pago'; return 'pendente'; };
const formatCurrency = (val: any) => new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(Number(val) || 0);
const formatDateBr = (date: string) => (date ? format(parseISO(date), 'dd/MM/yy') : '-');
const sanitizeText = (text: any) => text ? String(text).replace(/[\u0000-\u001F\u007F-\u009F]/g, '').trim() : null;
const safeDate = (dateStr: any) => { if (!dateStr) return null; try { return format(parseISO(dateStr), 'yyyy-MM-dd'); } catch { return null; } };
</script>

<style scoped lang="scss">
/* Ajuste no Grid para acomodar as novas colunas de data */
.grid-sync {
  display: grid;
  grid-template-columns: 44px minmax(200px, 1fr) minmax(180px, 1fr) 140px 160px 90px 90px 90px 110px 90px 80px;
  width: 100%;
  align-items: stretch;
}

.sync-modal { background: #fff; border-radius: 0; }
.border-thin { border: 1px solid rgba(0,0,0,0.08); }
.shadow-sm { box-shadow: 0 2px 10px rgba(0,0,0,0.06); }
.step-body { min-height: 0; }
.letter-spacing-1 { letter-spacing: 1px; }
.btn-rect { border-radius: 6px; text-transform: none; letter-spacing: 0; font-weight: 900; }
.ui-field :deep(.v-field) { border-radius: 6px; }
.chip-mini { border-radius: 8px !important; font-weight: 900; }
.row-gap { row-gap: 14px; }
.form-section { padding: 14px; background: #fafafa; border: 1px solid rgba(0,0,0,0.06); border-radius: 10px; }
.section-title { display: flex; align-items: center; gap: 10px; font-weight: 900; color: #455A64; text-transform: uppercase; letter-spacing: .6px; font-size: 12px; }
.stepbar { display: flex; align-items: center; justify-content: space-between; max-width: 760px; margin: 0 auto; }
.step-item { display: flex; flex-direction: column; align-items: center; gap: 8px; min-width: 160px; }
.step-item .dot { width: 34px; height: 34px; border-radius: 50%; background: #ECEFF1; display: flex; align-items: center; justify-content: center; font-weight: 900; color: #90A4AE; font-size: 14px; }
.step-item .lbl { font-size: 11px; font-weight: 900; letter-spacing: .5px; text-transform: uppercase; color: #90A4AE; }
.step-item.active .dot { background: #D32F2F; color: #fff; box-shadow: 0 4px 10px rgba(211, 47, 47, 0.3); }
.step-item.active .lbl { color: #D32F2F; }
.step-item.success .dot { background: #43A047; color: #fff; }
.stepbar .line { flex: 1; height: 2px; background: #ECEFF1; margin: 0 16px; margin-bottom: 18px; }
.kpi-wrap { background: #fff; }
.kpi-grid { display: grid; grid-template-columns: 220px 220px 220px 1fr; gap: 12px; align-items: stretch; }
.kpi-card { border: 1px solid rgba(0,0,0,0.08); background: #fafafa; border-radius: 12px; padding: 12px 14px; }
.kpi-card.success { background: #f1f8e9; border-color: rgba(67,160,71,0.25); }
.kpi-card.warn { background: #fff3e0; border-color: rgba(245,127,23,0.25); }
.kpi-top { display:flex; align-items:center; justify-content:space-between; gap:10px; }
.kpi-label { font-size: 11px; font-weight: 900; letter-spacing: .6px; text-transform: uppercase; color: #546E7A; }
.kpi-value { font-size: 28px; font-weight: 1000; color: #263238; line-height: 1.1; margin-top: 6px; }
.kpi-sub { font-size: 12px; color: #607D8B; font-weight: 800; }
.toolbar { padding: 14px; background: #fff; border: 1px solid rgba(0,0,0,0.06); border-radius: 12px; }
.field-label { font-size: 11px; font-weight: 900; letter-spacing: .6px; text-transform: uppercase; color: #607D8B; margin-bottom: 6px; }
.grid-header .cell { background: #f5f5f5; font-size: 11px; font-weight: 900; text-transform: uppercase; color: #616161; border-bottom: 2px solid #e0e0e0; }
.cell { padding: 8px 12px; display: flex; align-items: center; border-right: 1px solid rgba(0,0,0,0.05); border-bottom: 1px solid rgba(0,0,0,0.05); overflow: hidden; font-size: 12px; }
.center { justify-content: center; text-align: center; }
.text-truncate { white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.bg-grey-lighten-5 { background-color: #fafafa !important; }
.grid-row:hover .cell { background: #e3f2fd !important; }
.grid-selected .cell { background: #ffebee !important; }
.sticky-head { position: sticky; top: 0; z-index: 5; box-shadow: 0 2px 4px rgba(0,0,0,0.05); }
.solid-chip { display: inline-flex; align-items: center; justify-content: center; height: 20px; padding: 0 8px; border-radius: 6px; font-size: 10px; font-weight: 1000; color: #fff; text-transform: uppercase; }
.chip-success { background: #2e7d32; }
.chip-warn { background: #f57f17; }
.grid-scroll { scrollbar-gutter: stable; overflow-y: auto; height: 100%; display: block; }
.custom-scroll::-webkit-scrollbar { width: 8px; height: 8px; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(0,0,0,0.2); border-radius: 6px; }
.custom-scroll::-webkit-scrollbar-track { background: transparent; }
:deep(.v-checkbox-btn .v-selection-control__input) { width: 20px; height: 20px; }
.chk-fixed { margin: 0 !important; }
.row-company :deep(.v-field) { background: #f7f7f7; }
</style>
