<template>
  <v-dialog
    v-model="dialog"
    width="1600"
    max-width="98vw"
    height="90vh"
    class="glass-modal-wrapper"
    transition="dialog-bottom-transition"
    scrollable
  >
    <div class="glass-detail-card d-flex flex-column h-100 overflow-hidden">

      <div class="detail-header px-8 py-5 d-flex align-center justify-space-between flex-shrink-0 border-b border-white-05 bg-glass-header backdrop-blur z-30">
         <div class="header-bg-glow" :class="color"></div>

         <div class="d-flex align-center gap-6 relative z-10">
            <div class="detail-icon-box rounded-xl elevation-10 d-flex align-center justify-center position-relative overflow-hidden" :class="`bg-${color}-gradient`">
               <div class="shine-effect"></div>
               <v-icon color="white" size="36">{{ icon || 'mdi-chart-box' }}</v-icon>
            </div>

            <div>
               <div class="d-flex align-center gap-3 mb-1">
                   <div class="d-flex align-center gap-2 px-2 py-1 rounded bg-white-05 border border-white-05">
                      <v-icon size="12" :color="color" class="icon-pulse">mdi-circle</v-icon>
                      <span class="text-[10px] font-weight-bold text-uppercase letter-spacing-1 text-white-70">Ao Vivo</span>
                   </div>
                   <span class="text-overline text-white-30 font-weight-bold letter-spacing-1">ID: #{{ widget?.id || 'REF-001' }}</span>
               </div>
               <h2 class="text-h5 font-weight-black text-white lh-1 mt-1 text-shadow">{{ title || 'Detalhes do Indicador' }}</h2>
            </div>
         </div>

         <div class="d-flex align-center gap-3">
             <div class="d-flex align-center bg-glass-surface border border-white-10 rounded-lg pa-1 hidden-sm-and-down">
                <v-tooltip text="Exportar Dados (CSV)" location="bottom">
                  <template v-slot:activator="{ props }">
                    <v-btn v-bind="props" icon size="small" variant="text" color="white-70" class="rounded-md hover-bg-white-10">
                        <v-icon size="20">mdi-download-outline</v-icon>
                    </v-btn>
                  </template>
                </v-tooltip>

                <v-divider vertical class="my-1 mx-1 border-white-10"></v-divider>

                <v-tooltip text="Atualizar Agora" location="bottom">
                  <template v-slot:activator="{ props }">
                    <v-btn v-bind="props" icon size="small" variant="text" color="white-70" class="rounded-md hover-bg-white-10" :loading="loadingDetails" @click="forceRefresh">
                        <v-icon size="20">mdi-refresh</v-icon>
                    </v-btn>
                  </template>
                </v-tooltip>
             </div>

             <v-divider vertical class="border-white-10 py-2 hidden-sm-and-down" style="height: 32px"></v-divider>

             <v-btn icon variant="text" color="white-70" class="close-btn" @click="dialog = false">
                <v-icon size="28">mdi-close</v-icon>
             </v-btn>
         </div>
      </div>

      <div class="d-flex flex-grow-1 overflow-hidden relative">

          <div class="sidebar-panel pa-6 border-r border-white-05 bg-glass-darker d-flex flex-column overflow-y-auto custom-scrollbar z-20 h-100">

              <div class="mb-8 relative">
                 <div class="text-caption font-weight-bold text-white-30 text-uppercase mb-2 d-flex align-center justify-space-between">
                    <span>Total Consolidado</span>
                    <v-tooltip text="Soma total calculada com base nos filtros ativos e registros visíveis." location="end" max-width="200">
                        <template v-slot:activator="{ props }">
                            <v-icon v-bind="props" size="16" color="white-30" class="cursor-help hover-text-white">mdi-help-circle-outline</v-icon>
                        </template>
                    </v-tooltip>
                 </div>

                 <div class="kpi-display text-white lh-1 mb-4" :class="formattedValue.length > 10 ? 'text-h4' : 'text-h3'">
                    {{ formattedValue }}
                 </div>

                 <div class="variation-card d-flex align-center gap-3 pa-3 rounded-lg bg-white-02 border border-white-05">
                    <div class="icon-circle bg-success-10 text-success">
                       <v-icon size="16">mdi-trending-up</v-icon>
                    </div>
                    <div>
                       <div class="text-caption text-white-50 lh-1">Variação (30d)</div>
                       <div class="text-body-2 font-weight-bold text-success">+12.5% <span class="text-white-30 font-weight-regular">vs mês anterior</span></div>
                    </div>
                 </div>
              </div>

              <v-divider class="border-white-05 mb-6"></v-divider>

              <div class="d-flex flex-column gap-4 mb-auto">
                  <div class="section-title text-[10px] font-weight-black text-white-30 text-uppercase letter-spacing-2 mb-2">Metadados</div>

                  <div class="info-item d-flex gap-3">
                      <v-icon size="20" color="primary" class="mt-1">mdi-database-search-outline</v-icon>
                      <div>
                          <div class="text-caption text-white-50 font-weight-bold">Fonte de Dados</div>
                          <div class="text-body-2 text-white font-mono bg-white-05 px-2 py-0.5 rounded d-inline-block mt-1 text-truncate max-w-150">
                             {{ widget?.config?.source || 'system_default' }}
                          </div>
                      </div>
                  </div>

                  <div class="info-item d-flex gap-3">
                      <v-icon size="20" color="warning" class="mt-1">mdi-function-variant</v-icon>
                      <div>
                          <div class="text-caption text-white-50 font-weight-bold">Operação</div>
                          <div class="text-body-2 text-white">
                             {{ widget?.config?.operation?.toUpperCase() || 'CONTAGEM' }}
                             <span class="text-white-30">em</span>
                             <span class="font-mono text-white-70">{{ widget?.config?.column || 'ID' }}</span>
                          </div>
                      </div>
                  </div>
              </div>

              <div v-if="actions.route" class="mt-8 sticky-bottom-sidebar">
                  <div class="glass-well pa-4 rounded-xl border border-white-05 text-center">
                      <div class="text-caption text-white-50 mb-3 lh-14">
                         Acesse o gerenciamento completo:
                      </div>
                      <v-btn
                        block
                        :color="color"
                        variant="flat"
                        class="font-weight-bold rounded-lg letter-spacing-1"
                        :to="actions.route"
                        prepend-icon="mdi-open-in-new"
                      >
                         {{ actions.label }}
                      </v-btn>
                  </div>
              </div>
          </div>

          <div class="main-panel d-flex flex-column bg-glass-surface relative flex-grow-1 h-100 min-w-0">

              <div class="d-flex align-center justify-space-between px-6 py-3 border-b border-white-05 bg-glass-header flex-shrink-0">
                  <v-tabs v-model="activeTab" :color="color" density="compact" class="bg-transparent">
                      <v-tab value="breakdown" class="text-caption font-weight-bold text-none rounded-md px-4">
                          Visão Detalhada
                      </v-tab>
                      <v-tab value="history" class="text-caption font-weight-bold text-none rounded-md px-4">
                          Histórico & Auditoria
                      </v-tab>
                  </v-tabs>

                  <div class="d-flex align-center" style="width: 240px;">
                     <v-text-field
                        v-model="searchQuery"
                        placeholder="Buscar nos registros..."
                        density="compact"
                        variant="outlined"
                        hide-details
                        prepend-inner-icon="mdi-magnify"
                        color="white"
                        class="glass-input text-caption"
                        bg-color="rgba(0,0,0,0.2)"
                     ></v-text-field>
                  </div>
              </div>

              <v-window v-model="activeTab" class="flex-grow-1 overflow-hidden h-100">

                  <v-window-item value="breakdown" class="h-100">
                      <div class="h-100 overflow-y-auto custom-scrollbar relative">

                          <v-table v-if="filteredDetails.length > 0" density="default" class="bg-transparent text-white hover-rows w-100">
                              <thead class="sticky-header bg-glass-darker backdrop-blur z-10">
                                  <tr>
                                      <th class="text-left text-white-30 text-[10px] text-uppercase font-weight-bold pl-8 py-4 w-40">Identificação</th>
                                      <th class="text-left text-white-30 text-[10px] text-uppercase font-weight-bold py-4 w-25">Metadados</th>
                                      <th class="text-right text-white-30 text-[10px] text-uppercase font-weight-bold py-4 w-20">Valor & Impacto</th>
                                      <th class="text-center text-white-30 text-[10px] text-uppercase font-weight-bold pr-8 py-4 w-15">Ações</th>
                                  </tr>
                              </thead>
                              <tbody>
                                  <tr v-for="(item, i) in filteredDetails" :key="i" class="border-b border-white-05 transition-colors group">
                                      <td class="pl-8 py-3">
                                          <div class="d-flex align-center">
                                              <div class="mr-4 text-white-30 font-mono text-caption opacity-50">{{ String(i + 1).padStart(2, '0') }}</div>
                                              <v-avatar size="40" class="mr-4 rounded-lg bg-white-05 border border-white-05">
                                                 <v-img v-if="item.image" :src="item.image" cover></v-img>
                                                 <span v-else class="text-h6 font-weight-bold text-white-30">{{ item.label.charAt(0) }}</span>
                                              </v-avatar>
                                              <div>
                                                  <div class="font-weight-bold text-body-2 text-white mb-1 line-clamp-1" :title="item.label">
                                                      {{ item.label }}
                                                  </div>
                                                  <div class="d-flex align-center gap-2">
                                                      <v-chip size="x-small" :color="item.active ? 'success' : 'grey'" variant="flat" class="px-1 h-auto py-0.5 text-[10px] font-weight-bold text-uppercase rounded-sm">
                                                          {{ item.active ? 'Ativo' : 'Inativo' }}
                                                      </v-chip>
                                                      <span
                                                        class="text-[10px] font-mono text-white-30 copy-trigger cursor-pointer hover-text-white d-flex align-center"
                                                        @click.stop.prevent="copyToClipboard(item.original?.id || item.label)"
                                                      >
                                                          {{ item.original?.id ? String(item.original.id).substring(0, 8) : '---' }}
                                                          <v-icon size="10" class="ml-1">mdi-content-copy</v-icon>
                                                      </span>
                                                  </div>
                                              </div>
                                          </div>
                                      </td>
                                      <td class="py-3">
                                          <div class="d-flex flex-column gap-1">
                                              <div v-if="item.sub" class="d-flex align-center gap-2 text-caption text-white-70">
                                                  <v-icon size="14" color="white-30">mdi-barcode</v-icon>
                                                  <span class="font-mono">{{ item.sub }}</span>
                                              </div>
                                              <div v-if="item.date" class="d-flex align-center gap-2 text-caption text-white-50">
                                                  <v-icon size="14" color="white-30">mdi-calendar</v-icon>
                                                  <span>{{ item.date }}</span>
                                              </div>
                                          </div>
                                      </td>
                                      <td class="text-right py-3">
                                          <div class="font-weight-black text-body-1 text-white">{{ item.valFormatted }}</div>
                                          <div class="d-flex align-center justify-end gap-2 mt-1">
                                             <v-progress-linear :model-value="item.percent" :color="color" height="4" rounded class="opacity-60" style="width: 80px;"></v-progress-linear>
                                             <span class="text-[10px] font-mono text-white-30 w-8 text-right">{{ item.percent.toFixed(0) }}%</span>
                                          </div>
                                      </td>
                                      <td class="text-center pr-8 py-3">
                                          <div class="d-flex justify-center gap-1 row-actions">
                                              <v-tooltip text="Copiar ID Completo" location="top">
                                                 <template v-slot:activator="{ props }">
                                                    <v-btn
                                                        v-bind="props"
                                                        icon size="x-small"
                                                        variant="text"
                                                        color="white"
                                                        class="bg-white-05 hover-bg-white-10 text-white-70"
                                                        @click.stop.prevent="copyToClipboard(item.original?.id)"
                                                    >
                                                       <v-icon size="16">mdi-content-copy</v-icon>
                                                    </v-btn>
                                                 </template>
                                              </v-tooltip>

                                              <v-tooltip text="Ver Detalhes" location="top">
                                                 <template v-slot:activator="{ props }">
                                                    <v-btn v-bind="props" icon size="x-small" variant="text" :color="color" class="bg-white-05 hover-bg-white-10">
                                                       <v-icon size="16">mdi-open-in-new</v-icon>
                                                    </v-btn>
                                                 </template>
                                              </v-tooltip>
                                          </div>
                                      </td>
                                  </tr>
                              </tbody>
                          </v-table>

                          <div v-else-if="loadingDetails" class="d-flex flex-column align-center justify-center h-100">
                              <v-progress-circular indeterminate :color="color" size="60" width="4"></v-progress-circular>
                              <div class="mt-6 text-body-1 font-weight-bold text-white">Carregando dados...</div>
                          </div>

                          <div v-else class="d-flex flex-column align-center justify-center h-100 text-center pa-12">
                              <div class="empty-glow-box mb-6 rounded-circle d-flex align-center justify-center">
                                  <v-icon size="48" color="white-20">mdi-filter-variant-remove</v-icon>
                              </div>
                              <h3 class="text-body-1 font-weight-bold text-white-50 mb-1">Nenhum registro encontrado</h3>
                              <div class="text-caption text-white-30">Tente ajustar os filtros ou busque por outro termo.</div>
                          </div>
                      </div>
                  </v-window-item>

                  <v-window-item value="history" class="h-100">
                      <div class="h-100 overflow-y-auto custom-scrollbar pa-8">
                          <div class="max-w-800 mx-auto">

                             <v-alert
                                icon="mdi-clock-time-eight-outline"
                                border="start"
                                :color="color"
                                variant="tonal"
                                class="mb-8 border-opacity-50"
                                density="compact"
                             >
                                <template v-slot:title>
                                    <span class="text-subtitle-2 font-weight-bold">Timeline de Atividades</span>
                                </template>
                                <div class="text-caption opacity-80">
                                    Exibindo as últimas alterações e sincronizações registradas para este indicador.
                                </div>
                             </v-alert>

                             <div class="timeline-container relative pl-6 border-l border-white-10">
                                <div
                                    v-for="(item, i) in filteredDetails.slice(0, 10)"
                                    :key="i"
                                    class="timeline-item mb-8 relative group fade-in-entry"
                                    :style="{ animationDelay: `${i * 100}ms` }"
                                >
                                   <div class="absolute -left-[29px] top-1 w-3 h-3 rounded-full border-2 border-[#121214]" :class="`bg-${color}`"></div>

                                   <div class="text-caption text-white-50 font-mono mb-2 d-flex align-center gap-2">
                                       <v-icon size="12" color="white-30">mdi-calendar-clock</v-icon>
                                       {{ item.date || 'Data Desconhecida' }}
                                   </div>

                                   <div class="glass-well pa-4 rounded-xl border border-white-05 hover-border-white-10 transition-all">
                                       <div class="d-flex justify-space-between align-start mb-3">
                                          <div class="d-flex align-center gap-3">
                                              <v-avatar :color="`${color}-darken-4`" size="32" variant="tonal">
                                                  <v-icon size="16" :color="color">mdi-update</v-icon>
                                              </v-avatar>
                                              <div>
                                                  <div class="text-body-2 font-weight-bold text-white lh-1">Registro Atualizado</div>
                                                  <div class="text-[10px] text-white-50 mt-0.5">Sincronização Automática</div>
                                              </div>
                                          </div>
                                          <v-chip size="x-small" variant="outlined" color="white-30" class="font-mono">SYSTEM</v-chip>
                                       </div>

                                       <v-divider class="border-white-05 mb-3"></v-divider>

                                       <div class="text-caption text-white-70 lh-14">
                                          O item <strong class="text-white">{{ item.label }}</strong> foi processado.
                                          Impacto no total: <span :class="`text-${color}`" class="font-weight-bold">{{ item.valFormatted }}</span>.
                                       </div>

                                       <div class="d-flex align-center mt-3 pt-2 border-t border-white-05 border-dashed">
                                            <v-icon size="12" color="white-30" class="mr-2">mdi-identifier</v-icon>
                                            <span class="text-[10px] font-mono text-white-30">{{ item.sub || 'N/A' }}</span>
                                       </div>
                                   </div>
                                </div>
                             </div>
                          </div>
                      </div>
                  </v-window-item>

              </v-window>
          </div>

      </div>

    </div>
    <v-snackbar v-model="showSnackbar" :timeout="2000" color="surface" location="bottom center">
       <div class="d-flex align-center gap-2">
          <v-icon color="success" size="small">mdi-check-circle</v-icon>
          <span class="text-white text-caption font-weight-bold">{{ snackbarText }}</span>
       </div>
    </v-snackbar>
  </v-dialog>
</template>

<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { parseISO, isValid, format } from 'date-fns'
import { ptBR } from 'date-fns/locale'

const props = defineProps({
  modelValue: Boolean,
  widget: Object,
  title: String,
  subtitle: String,
  icon: String,
  color: { type: String, default: 'primary' }
})

const emit = defineEmits(['update:modelValue'])

// Estado Local
const dialog = computed({
  get: () => props.modelValue,
  set: (val) => emit('update:modelValue', val)
})
const activeTab = ref('breakdown')
const loadingDetails = ref(false)
const detailsList = ref<any[]>([])
const searchQuery = ref('')
const showSnackbar = ref(false)
const snackbarText = ref('')

// Computed: Filtro de busca
const filteredDetails = computed(() => {
   if (!searchQuery.value) return detailsList.value
   const q = searchQuery.value.toLowerCase()
   return detailsList.value.filter(item =>
      item.label.toLowerCase().includes(q) ||
      (item.sub && item.sub.toLowerCase().includes(q))
   )
})

// Helpers de Formatação
const formatCurrency = (val: number) => new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(val)
const formatNumber = (val: number) => new Intl.NumberFormat('pt-BR').format(val)
const formatDateSmart = (val: string) => {
    if (!val) return '-'
    try {
        const date = parseISO(val)
        if (isValid(date)) return format(date, 'dd/MM/yyyy HH:mm', { locale: ptBR })
        return val
    } catch { return val }
}

const formattedValue = computed(() => {
    if (!props.widget) return '---'
    const val = Number(props.widget.value) || 0
    const fmt = props.widget.config?.format
    if (fmt === 'currency') return formatCurrency(val)
    if (fmt === 'percent') return `${val.toFixed(1)}%`
    return formatNumber(val)
})

const actions = computed(() => {
    const s = props.widget?.config?.source || ''
    if (s.includes('products')) return { label: 'Gerenciar Estoque', route: { name: 'CajuiaPDV' } }
    if (s.includes('orders')) return { label: 'Ver Pedidos', route: { name: 'CajuiaOrders' } }
    if (s.includes('clients')) return { label: 'Base de Clientes', route: { name: 'CajuiaClients' } }
    return { label: '', route: null }
})

// Watcher para carregar dados ao abrir
watch(() => props.modelValue, (isOpen) => {
    if (isOpen && props.widget) {
        loadData()
    }
})

const forceRefresh = () => {
   loadData()
   showToast('Dados atualizados com sucesso')
}

const loadData = () => {
   loadingDetails.value = true
   activeTab.value = 'breakdown'
   searchQuery.value = ''

   setTimeout(() => {
       if (props.widget?.listData && Array.isArray(props.widget.listData)) {
            mapStoreDataToDetails(props.widget.listData);
       } else {
            detailsList.value = []
       }
       loadingDetails.value = false
   }, 600)
}

const mapStoreDataToDetails = (data: any[]) => {
    if (!data) return;
    const w = props.widget;
    const totalVal = Number(w.value) || 1;
    const isMoney = w.config?.format === 'currency';

    detailsList.value = data.map(item => {
        let rawVal = 0;
        if (item.value !== undefined) rawVal = item.value;
        else if (item._val !== undefined) rawVal = item._val;
        else if (item.total_value !== undefined) rawVal = item.total_value;
        else if (item.price !== undefined) rawVal = item.price;
        rawVal = Number(rawVal);

        let fmtVal = '';
        if (isMoney) {
             fmtVal = formatCurrency(rawVal);
        } else {
             fmtVal = formatNumber(rawVal);
             if (w.config?.source?.includes('products')) fmtVal += ' un';
        }

        const label = item.displayName || item.customer_name || item.name || item.product_name || `Registro #${item.id}`;

        let sub = '';
        let date = '';
        if (item.sku) sub = `SKU: ${item.sku}`;
        else if (item.id) sub = `ID: ${String(item.id).substring(0, 8)}`;

        if (item.created_at) date = formatDateSmart(item.created_at);

        const percent = totalVal > 0 ? Math.min((rawVal / totalVal) * 100, 100) : 0;

        const active = item.status !== 'inactive' && item.active !== false;

        return {
            label,
            sub,
            date,
            valFormatted: fmtVal,
            percent,
            active,
            image: item.image_url || null,
            original: item
        }
    });
}

const copyToClipboard = async (text: any) => {
   if (!text) return
   try {
      await navigator.clipboard.writeText(String(text))
      showToast('Copiado para a área de transferência!')
   } catch (err) {
      console.error('Erro ao copiar', err)
      showToast('Não foi possível copiar o texto.')
   }
}

const showToast = (msg: string) => {
   snackbarText.value = msg
   showSnackbar.value = true
}
</script>

<style scoped lang="scss">
.glass-modal-wrapper { backdrop-filter: blur(10px); }
.glass-detail-card {
    background: #12121481; /* Cor base sólida escura para performance */
    border: 1px solid rgba(255, 255, 255, 0.08);
    border-radius: 24px;
    box-shadow: 0 50px 100px -20px rgba(0,0,0,0.9);
}

/* HEADER */
.detail-header { position: relative; overflow: hidden; }
.header-bg-glow {
    position: absolute; top: -100%; left: -20%; width: 140%; height: 300%; opacity: 0.08; filter: blur(80px); pointer-events: none;
    background: radial-gradient(circle, currentColor, transparent 70%);
    &.primary { color: rgb(var(--v-theme-primary)); }
    &.success { color: #00e676; }
}
.detail-icon-box { width: 64px; height: 64px; }
.shine-effect {
    position: absolute; top: 0; left: 0; width: 100%; height: 100%;
    background: linear-gradient(135deg, rgba(255,255,255,0.1) 0%, transparent 50%);
}

/* LAYOUT */
.sidebar-panel { width: 280px; flex-shrink: 0; min-width: 260px; max-width: 320px; }
.sticky-bottom-sidebar { position: sticky; bottom: 0; padding-top: 20px; background: linear-gradient(to top, #0e0e10 80%, transparent); }
.sticky-header { position: sticky; top: 0; box-shadow: 0 1px 0 rgba(255,255,255,0.05); }

/* TYPOGRAPHY */
.kpi-display { font-weight: 900; line-height: 1; letter-spacing: -1px; }
.text-shadow { text-shadow: 0 2px 10px rgba(0,0,0,0.5); }
.line-clamp-1 { display: -webkit-box; -webkit-line-clamp: 1; -webkit-box-orient: vertical; overflow: hidden; }
.max-w-150 { max-width: 150px; }
.max-w-800 { max-width: 800px; }
.w-40 { width: 40%; } .w-25 { width: 25%; } .w-20 { width: 20%; } .w-15 { width: 15%; }

/* COMPONENTS */
.glass-well { background: rgba(255,255,255,0.02); }
.glass-input :deep(.v-field__outline__start), .glass-input :deep(.v-field__outline__end) { border-color: rgba(255,255,255,0.1) !important; }
.icon-circle { width: 32px; height: 32px; display: flex; align-items: center; justify-content: center; border-radius: 50%; }
.empty-glow-box { width: 120px; height: 120px; background: radial-gradient(circle, rgba(255,255,255,0.03), transparent 70%); border: 1px solid rgba(255,255,255,0.05); }

/* ACTIONS HOVER EFFECT */
.row-actions {
    opacity: 0.4; /* Visível, mas discreto (40% opacidade) */
    transition: all 0.2s ease-in-out;
}

/* Quando passar o mouse na LINHA, os ícones ficam 100% visíveis */
.group:hover .row-actions {
    opacity: 1;
    transform: translateX(0);
}

/* COLORS & GRADIENTS */
.bg-glass-header { background: rgba(18, 18, 20, 0.596); }
.bg-glass-darker { background: rgba(14, 14, 16, 0.534); }
.bg-glass-surface { background: linear-gradient(to bottom right, rgba(255,255,255,0.01), transparent); }
.bg-primary-gradient { background: linear-gradient(135deg, rgb(var(--v-theme-primary)), #1565C0); }
.bg-white-02 { background: rgba(255,255,255,0.02); }
.bg-white-05 { background: rgba(255,255,255,0.05); }
.bg-info-10 { background: rgba(var(--v-theme-info), 0.1); }
.bg-success-10 { background: rgba(0, 230, 118, 0.1); }
.text-white-30 { color: rgba(255,255,255,0.3) !important; }
.text-white-50 { color: rgba(255,255,255,0.5) !important; }
.text-white-70 { color: rgba(255,255,255,0.7) !important; }

/* UTILS */
.border-white-05 { border-color: rgba(255,255,255,0.05) !important; }
.border-white-10 { border-color: rgba(255,255,255,0.1) !important; }
.gap-1 { gap: 4px; } .gap-2 { gap: 8px; } .gap-3 { gap: 12px; } .gap-4 { gap: 16px; } .gap-6 { gap: 24px; }
.cursor-help { cursor: help; }
.hover-rows tr:hover td { background: rgba(255,255,255,0.02); }
.hover-bg-white-10:hover { background: rgba(255,255,255,0.1) !important; }
.hover-text-white:hover { color: white !important; }
.hover-border-white-10:hover { border-color: rgba(255,255,255,0.1) !important; }
.close-btn:hover { background: rgba(255,0,0,0.1); color: #ff5252 !important; transform: rotate(90deg); transition: all 0.3s; }
.icon-pulse { animation: pulse 2s infinite; }
@keyframes pulse { 0% { opacity: 0.5; } 50% { opacity: 1; } 100% { opacity: 0.5; } }

/* ANIMATIONS */
.fade-in-entry { opacity: 0; transform: translateY(10px); animation: fadeInUp 0.5s forwards; }
@keyframes fadeInUp { to { opacity: 1; transform: translateY(0); } }

/* SCROLLBAR */
.custom-scrollbar::-webkit-scrollbar { width: 6px; }
.custom-scrollbar::-webkit-scrollbar-track { background: transparent; }
.custom-scrollbar::-webkit-scrollbar-thumb { background: rgba(255,255,255,0.1); border-radius: 3px; }
.custom-scrollbar::-webkit-scrollbar-thumb:hover { background: rgba(255,255,255,0.2); }
</style>
