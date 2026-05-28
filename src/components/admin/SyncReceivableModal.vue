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
          <div class="text-caption font-weight-black opacity-70 text-uppercase letter-spacing-1 text-teal-darken-3">Módulo de Integração</div>
          <div class="text-h6 font-weight-black text-grey-darken-3 mt-1">
            Sincronização de Recebíveis <span class="text-grey font-weight-regular">| GestãoClick</span>
          </div>
          <div class="text-caption text-grey-darken-1 mt-1">
            Fonte: <b>/recebimentos</b>. Detecta alterações em: Valores, Vencimentos, Status, Nomes e Descrições.
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

        <div v-if="step === 1" class="step-body d-flex align-center justify-center overflow-y-auto custom-scroll bg-grey-lighten-5 h-100">
          <v-card class="pa-8 bg-white border-thin shadow-sm" width="820" elevation="0">
            <div class="d-flex align-center gap-3 mb-6">
               <div class="bg-teal-lighten-5 pa-3 rounded-lg"><v-icon color="teal-darken-2" size="28">mdi-cloud-search</v-icon></div>
               <div>
                  <div class="text-h6 font-weight-black text-grey-darken-3">Critérios de Busca</div>
                  <div class="text-caption text-grey">Defina o período e o status para buscar no ERP.</div>
               </div>
            </div>

            <v-row dense class="row-gap">
              <v-col cols="12" md="6">
                <v-text-field label="Data Início" type="date" v-model="config.startDate" variant="outlined" density="comfortable" color="teal" class="ui-field" />
              </v-col>
              <v-col cols="12" md="6">
                <v-text-field label="Data Fim" type="date" v-model="config.endDate" variant="outlined" density="comfortable" color="teal" class="ui-field" />
              </v-col>
              <v-col cols="12">
                <v-select
                  label="Status ERP"
                  v-model="config.status"
                  :items="statusItems"
                  variant="outlined"
                  density="comfortable"
                  color="teal"
                  class="ui-field"
                  prepend-inner-icon="mdi-filter-variant"
                />
              </v-col>
              <v-col cols="12">
                 <v-checkbox
                    v-model="config.forceUpdate"
                    label="Forçar atualização total (Ignorar verificação de mudanças)"
                    density="compact"
                    color="teal"
                    hide-details
                    class="mt-2"
                 ></v-checkbox>
              </v-col>
            </v-row>

            <v-btn block class="btn-rect mt-8 font-weight-bold letter-spacing-1" height="48" color="teal-darken-2" @click="fetchSyncPreview" :loading="loadingFetch">
              INICIAR ANÁLISE
            </v-btn>
          </v-card>
        </div>

        <div v-else-if="step === 2" class="step-body d-flex flex-column h-100 overflow-hidden">
           <div class="kpi-wrap px-6 pt-5 pb-4 bg-white border-b flex-shrink-0 d-flex" style="gap: 20px;">
              <div class="kpi-card bg-teal-lighten-5 border-teal-lighten-4 pa-4 rounded-lg flex-grow-1">
                 <div class="text-caption font-weight-bold text-teal-darken-3">REGISTROS ENCONTRADOS</div>
                 <div class="text-h4 font-weight-black text-teal-darken-4">{{ syncStats.total }}</div>
                 <div class="text-caption text-teal-darken-3 mt-1">Novos: {{ syncStats.new }} | Atualizações: {{ syncStats.update }}</div>
              </div>
              <div class="kpi-card bg-blue-lighten-5 border-blue-lighten-4 pa-4 rounded-lg flex-grow-1">
                 <div class="text-caption font-weight-bold text-blue-darken-3">VALOR TOTAL</div>
                 <div class="text-h4 font-weight-black text-blue-darken-4">{{ formatCurrency(syncStats.value) }}</div>
              </div>
           </div>

           <div class="flex-grow-1 overflow-y-auto custom-scroll bg-white">
              <div class="grid-header sticky-head grid-sync flex-shrink-0 bg-grey-lighten-4">
                 <div class="cell center"><v-checkbox-btn :model-value="areAllSelected" @update:model-value="toggleSelectAll" density="compact" color="teal" class="chk-fixed" /></div>
                 <div class="cell header-text">ID ERP</div>
                 <div class="cell header-text">Descrição</div>
                 <div class="cell header-text">Cliente / Entidade</div>
                 <div class="cell header-text">Plano de Contas</div>
                 <div class="cell center header-text">Vencimento</div>
                 <div class="cell center header-text">Valor</div>
                 <div class="cell center header-text">Status ERP</div>
                 <div class="cell center header-text">Ação</div>
              </div>

              <div v-if="previewData.length === 0" class="d-flex flex-column align-center justify-center py-10 opacity-60">
                  <v-icon size="64" color="grey-lighten-1">mdi-check-all</v-icon>
                  <div class="text-h6 mt-2 text-grey">Tudo sincronizado!</div>
                  <div class="text-caption">Nenhuma diferença encontrada entre ERP e Banco Local.</div>
              </div>

              <div
                v-for="item in previewData"
                :key="item.uniqueKey"
                class="grid-row grid-sync hover-bg-grey"
                :class="selectedIds.has(item.uniqueKey) ? 'bg-teal-lighten-5' : ''"
                @click="toggleSelection(item.uniqueKey)"
              >
                 <div class="cell center"><v-checkbox-btn :model-value="selectedIds.has(item.uniqueKey)" density="compact" color="teal" class="chk-fixed" /></div>
                 <div class="cell text-caption font-mono font-weight-bold text-grey-darken-2">#{{ item.id }}</div>
                 <div class="cell text-caption font-weight-bold text-truncate" :title="item.descricao">{{ item.descricao }}</div>
                 <div class="cell text-caption text-truncate" :title="item.nome_cliente">{{ item.nome_cliente }}</div>
                 <div class="cell text-caption text-truncate text-blue-grey-darken-2">{{ item.nome_plano_conta || '-' }}</div>
                 <div class="cell center font-mono text-caption" :class="hasDateChanged(item) ? 'text-orange-darken-3 font-weight-bold' : ''">
                    {{ formatDateSimple(item.data_vencimento) }}
                 </div>
                 <div class="cell center font-mono font-weight-black text-caption" :class="hasValueChanged(item) ? 'text-orange-darken-3' : ''">
                    {{ formatCurrency(item.valor_total || item.valor) }}
                 </div>
                 <div class="cell center">
                    <span class="solid-chip" :class="getErpStatus(item.liquidado) === 'pago' ? 'chip-success' : 'chip-warn'">
                        {{ getErpStatus(item.liquidado).toUpperCase() }}
                    </span>
                 </div>
                 <div class="cell center">
                    <span class="status-badge" :class="item.sync_type === 'new' ? 'bg-green-100 text-green-700' : 'bg-blue-100 text-blue-700'">
                        {{ item.sync_type === 'new' ? 'NOVO' : 'ATUALIZAR' }}
                    </span>
                 </div>
              </div>
           </div>
        </div>

        <div v-else-if="step === 3" class="d-flex flex-column align-center justify-center flex-grow-1">
           <v-progress-circular v-model="execution.percent" color="teal-darken-2" size="80" width="8" class="mb-4">
              <span class="text-caption font-weight-bold">{{ Math.ceil(execution.percent) }}%</span>
           </v-progress-circular>
           <div class="text-h6 font-weight-black text-grey-darken-3">Sincronizando...</div>
           <div class="text-caption text-grey mt-1">Processando <b>{{ execution.current }}</b> de <b>{{ execution.total }}</b> registros</div>
        </div>
      </div>

      <div class="sync-foot px-6 py-4 d-flex justify-end bg-white border-t flex-shrink-0" v-if="step !== 3">
         <v-btn variant="outlined" class="btn-rect" @click="close" height="40" color="grey-darken-2">Cancelar</v-btn>
         <v-btn v-if="step === 1" color="teal-darken-2" variant="flat" class="btn-rect ml-3 px-6 font-weight-bold" height="40" @click="fetchSyncPreview" :loading="loadingFetch">
            ANALISAR DADOS <v-icon end>mdi-arrow-right</v-icon>
         </v-btn>
         <v-btn v-if="step === 2" color="success" variant="flat" class="btn-rect ml-3 px-6 font-weight-bold" height="40" @click="executeSync" :disabled="selectedIds.size === 0">
            <v-icon start>mdi-database-sync</v-icon> CONFIRMAR SYNC ({{ selectedIds.size }})
         </v-btn>
      </div>
    </v-card>
  </v-dialog>
</template>

<script setup lang="ts">
import { ref, reactive, computed, watch } from 'vue';
import { supabase } from '@/api/supabase';
import { gestaoApi } from '@/api/gestaoClick';
import { format, startOfMonth, endOfMonth, parseISO } from 'date-fns';
import { useAppStore } from '@/stores/app';
import { useCompanyStore } from '@/stores/company'; // NOVO IMPORT DA EMPRESA

const props = defineProps<{ modelValue: boolean }>();
const emit = defineEmits(['update:modelValue', 'synced']);
const appStore = useAppStore();
const companyStore = useCompanyStore();

const step = ref(1);
const loadingFetch = ref(false);
const previewData = ref<any[]>([]);
const selectedIds = ref(new Set<string>());
const execution = reactive({ processing: false, percent: 0, current: 0, total: 0 });

const config = reactive({
  startDate: format(startOfMonth(new Date()), 'yyyy-MM-dd'),
  endDate: format(endOfMonth(new Date()), 'yyyy-MM-dd'),
  status: 'todos',
  forceUpdate: false
});

const statusItems = [
  { title: 'Todos', value: 'todos' },
  { title: 'Em Aberto', value: 'ab' },
  { title: 'Recebidos', value: 'pg' }
];

const syncStats = computed(() => ({
    total: previewData.value.length,
    new: previewData.value.filter(i => i.sync_type === 'new').length,
    update: previewData.value.filter(i => i.sync_type === 'update').length,
    value: previewData.value.reduce((acc, i) => acc + (Number(i.valor_total || i.valor) || 0), 0)
}));

const areAllSelected = computed(() => previewData.value.length > 0 && selectedIds.value.size === previewData.value.length);

watch(() => props.modelValue, (val) => { if(val) reset(); });

const reset = () => {
    step.value = 1; previewData.value = []; selectedIds.value.clear(); execution.processing = false;
    config.startDate = format(startOfMonth(new Date()), 'yyyy-MM-dd');
    config.endDate = format(endOfMonth(new Date()), 'yyyy-MM-dd');
};

const close = () => emit('update:modelValue', false);
const toggleSelectAll = (val: boolean) => { if(val) previewData.value.forEach(i => selectedIds.value.add(i.uniqueKey)); else selectedIds.value.clear(); };
const toggleSelection = (key: string) => { if(selectedIds.value.has(key)) selectedIds.value.delete(key); else selectedIds.value.add(key); };

// -- HELPERS --
const formatCurrency = (val: any) => new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(Number(val) || 0);
const formatDateSimple = (d: any) => d ? format(parseISO(d), 'dd/MM/yy') : '-';
const getErpStatus = (val: any) => ['1','s','sim','pago','true'].includes(String(val).toLowerCase()) ? 'pago' : 'em_aberto';
const sanitize = (t: any) => t ? String(t).trim() : null;

const safeDate = (d: any) => {
    if (!d) return null;
    try {
        if (typeof d === 'string' && d.length >= 10 && d.match(/^\d{4}-\d{2}-\d{2}/)) return d.substring(0, 10);
        return format(parseISO(d), 'yyyy-MM-dd');
    } catch { return null; }
};

// -- FETCH & DIFF LOGIC --
const fetchSyncPreview = async () => {
    loadingFetch.value = true;
    try {
        const params: any = { limit: 1000, itens_por_pagina: 1000, data_inicio: config.startDate, data_fim: config.endDate };
        if(config.status === 'ab') params.liquidado = '0';
        if(config.status === 'pg') params.liquidado = '1';

        let apiData = [];
        try {
             apiData = await gestaoApi.buscarRecebimentos(params);
        } catch(err) {
             throw new Error("Falha ao comunicar com a API do GestãoClick.");
        }

        if (!Array.isArray(apiData)) apiData = [];

        const apiIds = apiData.map((i: any) => String(i.id));
        const localMap = new Map<string, any>();

        const chunkSize = 500;
        for (let i = 0; i < apiIds.length; i += chunkSize) {
            const chunk = apiIds.slice(i, i + chunkSize);
            const { data: existing } = await supabase.from('finance_receivables')
                .select('id, gestao_click_id, value, due_date, status, description, entity_name, payment_date')
                .in('gestao_click_id', chunk);
            existing?.forEach(e => localMap.set(String(e.gestao_click_id), e));
        }

        const diffs = apiData.map((item: any) => {
            const local = localMap.get(String(item.id));
            const erpVal = parseFloat(item.valor_total || item.valor || 0);
            const erpStatus = getErpStatus(item.liquidado);
            const erpDue = safeDate(item.data_vencimento);
            const erpPay = erpStatus === 'pago' ? (safeDate(item.data_liquidacao) || safeDate(item.data_recebimento) || erpDue) : null;
            const erpName = item.nome_cliente || item.cliente_nome;

            if (!local) return { ...item, uniqueKey: String(item.id), sync_type: 'new', _local: null };
            if (config.forceUpdate) return { ...item, uniqueKey: String(item.id), sync_type: 'update', _local: local };

            let changed = false;
            if (Math.abs(erpVal - Number(local.value)) > 0.02) changed = true;
            if (erpStatus !== local.status) changed = true;
            if (erpDue !== local.due_date) changed = true;
            if (erpPay && local.payment_date && erpPay !== local.payment_date) changed = true;
            if (sanitize(item.descricao) !== sanitize(local.description)) changed = true;
            if (sanitize(erpName) !== sanitize(local.entity_name)) changed = true;

            return changed ? { ...item, uniqueKey: String(item.id), sync_type: 'update', _local: local } : null;
        }).filter(Boolean);

        previewData.value = diffs;
        selectedIds.value.clear();
        diffs.forEach(d => selectedIds.value.add(d.uniqueKey));

        step.value = 2;
    } catch(e: any) {
        appStore.showSnackbar(e.message, 'error');
    } finally {
        loadingFetch.value = false;
    }
};

const hasValueChanged = (item: any) => item._local && Math.abs((item.valor_total || item.valor) - Number(item._local.value)) > 0.02;
const hasDateChanged = (item: any) => item._local && safeDate(item.data_vencimento) !== item._local.due_date;

// -- EXECUTE --
const executeSync = async () => {
    execution.processing = true;
    step.value = 3;
    const toProcess = previewData.value.filter(i => selectedIds.value.has(i.uniqueKey));
    execution.total = toProcess.length;
    execution.current = 0;

    let success = 0;
    const chartCache = new Map<string, string>();

    for(const item of toProcess) {
        try {
            const chartName = item.nome_plano_conta || item.plano_conta_nome || item.categoria;
            let chartId = null;

            if(chartName) {
                if(chartCache.has(chartName)) {
                    chartId = chartCache.get(chartName);
                } else {
                    const { data: c } = await supabase.from('finance_chart_of_accounts').select('id').eq('name', chartName).eq('type', 'Receita').maybeSingle();
                    if(c) {
                        chartId = c.id;
                        chartCache.set(chartName, c.id);
                    } else {
                        const tempCode = `ERP-${Math.floor(Math.random() * 100000)}`;
                        const { data: newC } = await supabase.from('finance_chart_of_accounts').insert({
                            name: chartName, type: 'Receita', active: true, code: tempCode, is_group: false
                        }).select('id').single();
                        if (newC) { chartId = newC.id; chartCache.set(chartName, newC.id); }
                    }
                }
            }

            const clientName = item.nome_cliente || item.cliente_nome;
            let customerId = null;
            if (clientName) {
                 const { data: cust } = await supabase.from('customers_mj').select('id').ilike('nome', clientName).limit(1).maybeSingle();
                 if(cust) customerId = cust.id;
            }

            // ATENÇÃO: Agora com company_id amarrada ao contexto atual
            const payload = {
                gestao_click_id: String(item.id),
                company_id: companyStore.context || null,
                description: sanitize(item.descricao) || `Título Importado #${item.id}`,
                value: parseFloat(item.valor_total || item.valor) || 0,
                due_date: safeDate(item.data_vencimento),
                competence_date: safeDate(item.data_competencia || item.data_vencimento),
                payment_date: getErpStatus(item.liquidado) === 'pago' ? (safeDate(item.data_liquidacao) || safeDate(item.data_recebimento) || safeDate(item.data_vencimento)) : null,
                status: getErpStatus(item.liquidado),
                entity_name: clientName,
                customer_id: customerId,
                chart_of_accounts_id: chartId,
                notes: item.observacoes ? String(item.observacoes) : null,
                paid_value: getErpStatus(item.liquidado) === 'pago' ? (parseFloat(item.valor_total || item.valor) || 0) : 0
            };

            if (!payload.due_date) payload.due_date = new Date().toISOString().substring(0, 10);

            const { data: existing } = await supabase.from('finance_receivables').select('id').eq('gestao_click_id', payload.gestao_click_id).maybeSingle();

            let opError = null;

            if (existing) {
                const { error } = await supabase.from('finance_receivables').update(payload).eq('id', existing.id);
                opError = error;
            } else {
                const { error } = await supabase.from('finance_receivables').insert(payload);
                opError = error;
            }

            if (opError) throw new Error(opError.message);
            success++;
        } catch(err) {
            console.error("Erro item:", item.id, err);
        }

        execution.current++;
        execution.percent = (execution.current / execution.total) * 100;
        if(execution.current % 10 === 0) await new Promise(r => setTimeout(r, 10));
    }

    appStore.showSnackbar(`${success} registros sincronizados com sucesso!`, 'success');
    emit('synced');
    close();
};
</script>

<style scoped lang="scss">
.sync-modal { background: #fff; border-radius: 0; }
.btn-rect { border-radius: 6px; text-transform: none; letter-spacing: 0; }
.chip-mini { border-radius: 6px; font-weight: 700; }
.stepbar { display: flex; align-items: center; justify-content: space-between; max-width: 600px; margin: 0 auto; }
.step-item { display: flex; flex-direction: column; align-items: center; gap: 6px; min-width: 120px; }
.step-item .dot { width: 32px; height: 32px; border-radius: 50%; background: #ECEFF1; display: flex; align-items: center; justify-content: center; font-weight: 900; color: #90A4AE; font-size: 13px; }
.step-item .lbl { font-size: 11px; font-weight: 800; text-transform: uppercase; color: #90A4AE; }
.step-item.active .dot { background: #00796B; color: #fff; box-shadow: 0 4px 10px rgba(0, 121, 107, 0.3); }
.step-item.active .lbl { color: #00796B; }
.stepbar .line { flex: 1; height: 2px; background: #ECEFF1; margin: 0 10px; margin-bottom: 18px; }

.grid-sync { display: grid; grid-template-columns: 44px 80px 2fr 1.5fr 1.5fr 100px 100px 100px 100px; align-items: center; border-bottom: 1px solid #f0f0f0; }
.cell { padding: 8px 12px; display: flex; align-items: center; border-right: 1px solid #f0f0f0; min-height: 48px; }
.header-text { font-size: 11px; font-weight: 800; text-transform: uppercase; color: #616161; }
.center { justify-content: center; text-align: center; }
.solid-chip { display: inline-flex; align-items: center; justify-content: center; height: 20px; padding: 0 8px; border-radius: 4px; font-size: 10px; font-weight: 900; color: #fff; }
.chip-success { background: #2E7D32; }
.chip-warn { background: #F57F17; }
.status-badge { display: inline-block; padding: 2px 6px; border-radius: 4px; font-size: 10px; font-weight: 800; }
.bg-green-100 { background: #E8F5E9; } .text-green-700 { color: #2E7D32; }
.bg-blue-100 { background: #E3F2FD; } .text-blue-700 { color: #1565C0; }
.hover-bg-grey:hover .cell { background: #F5F5F5; }
.custom-scroll::-webkit-scrollbar { width: 8px; }
.custom-scroll::-webkit-scrollbar-thumb { background: #ccc; border-radius: 4px; }
</style>
