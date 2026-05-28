<template>
  <v-container fluid class="dashboard-view pa-0 bg-animated-image">
    <div class="background-overlay"></div>

    <DashboardBuilderDrawer v-model="showBuilder" @update:layout="handleLayoutUpdate" />

    <div class="content-wrapper pa-4 d-flex flex-column h-100">

      <div class="header-section d-flex align-center justify-space-between mb-6 flex-shrink-0">
        <div class="d-flex align-center text-caption text-white-50">
          <v-icon size="small" class="mr-2 text-white-30">mdi-store-outline</v-icon>
          <span class="letter-spacing-1">Cajuia</span>
          <v-icon size="small" class="mx-2 text-white-20">mdi-chevron-right</v-icon>
          <span class="text-white font-weight-bold">Dashboard</span>
        </div>

        <div class="d-flex align-center gap-3">
           <v-btn
            :variant="store.editMode ? 'flat' : 'text'"
            :color="store.editMode ? 'warning' : 'white'"
            size="small"
            class="glass-btn text-none px-4"
            :class="{ 'border-warning': store.editMode }"
            height="32"
            @click="store.toggleEditMode"
          >
            <v-icon start size="x-small">{{ store.editMode ? 'mdi-check' : 'mdi-pencil-outline' }}</v-icon>
            {{ store.editMode ? 'Salvar Layout' : 'Personalizar' }}
          </v-btn>

          <v-btn icon size="small" variant="text" class="glass-btn-icon" @click="showBuilder = true">
            <v-icon color="white-70" size="small">mdi-cog-outline</v-icon>
          </v-btn>

          <v-divider vertical class="border-white-10 mx-1" style="height: 14px;"></v-divider>

          <div class="glass-chip px-1 py-0 rounded-pill d-flex align-center p-relative">
             <v-menu location="bottom end" content-class="glass-menu mt-2">
                <template v-slot:activator="{ props }">
                   <v-btn v-bind="props" variant="text" height="28" class="text-caption font-weight-bold text-white px-3 text-none">
                      <v-icon start size="x-small" color="primary">mdi-calendar-range</v-icon>
                      {{ periods.find(p => p.value === store.selectedPeriod)?.label }}
                      <v-icon end size="x-small" color="white-50">mdi-chevron-down</v-icon>
                   </v-btn>
                </template>
                <v-list bg-color="transparent" density="compact" class="py-1">
                    <v-list-item v-for="p in periods" :key="p.value" @click="setPeriod(p.value)" class="text-white hover-bg-white-05" density="compact">
                        <v-list-item-title class="text-caption font-weight-bold">{{ p.label }}</v-list-item-title>
                    </v-list-item>
                </v-list>
             </v-menu>
          </div>

          <div class="digital-clock px-3 py-1 rounded-pill glass-chip border-white-10 d-flex align-center">
             <v-icon color="primary" size="small" class="mr-2 icon-pulse">mdi-clock-outline</v-icon>
             <span class="font-weight-black text-caption text-white mono-font">{{ realTimeClock }}</span>
          </div>

          <div class="glass-chip px-3 py-1 rounded-pill d-flex align-center">
            <div class="status-dot success mr-2"></div>
            <span class="text-caption text-white font-weight-medium">Online</span>
          </div>
        </div>
      </div>

      <div class="welcome-banner mb-6 glass-panel pa-6 rounded-xl relative overflow-hidden flex-shrink-0">
         <div class="d-flex align-center justify-space-between relative z-10">
            <div class="d-flex flex-column">
                <div class="d-flex align-center mb-2">
                    <h1 class="text-h4 font-weight-black text-white mr-3 text-shadow">
                        {{ timeBasedGreeting }}, {{ userFirstName }}
                    </h1>
                    <span class="text-h4 wave-hand" role="img" aria-label="wave">👋</span>
                </div>

                <div class="d-flex align-center gap-3 text-white-70">
                    <div class="d-flex align-center gap-2 bg-white-05 px-3 py-1 rounded-lg border border-white-05">
                        <v-icon size="small" color="secondary">mdi-badge-account-horizontal-outline</v-icon>
                        <span class="font-weight-bold text-uppercase text-[10px] letter-spacing-1">{{ userRole }}</span>
                    </div>
                    <span class="text-white-20">•</span>
                    <div class="d-flex align-center gap-2">
                         <v-icon size="small" color="success">mdi-shield-check-outline</v-icon>
                         <span class="text-caption font-weight-medium">{{ accessDescription }}</span>
                    </div>
                </div>
            </div>
            <div class="hidden-sm-and-down">
                 <div class="glass-chip px-4 py-2 rounded-lg d-flex align-center gap-3 border-white-10">
                     <v-avatar color="primary" variant="tonal" size="32" class="rounded-lg">
                        <v-icon size="18">mdi-flash-outline</v-icon>
                     </v-avatar>
                     <div>
                         <div class="text-[10px] text-white-50 text-uppercase font-weight-bold">Status do Sistema</div>
                         <div class="text-caption font-weight-bold text-white">100% Operacional</div>
                     </div>
                 </div>
            </div>
         </div>
         <div class="absolute-decoration glow-effect"></div>
         <v-icon class="absolute-decoration icon-bg" icon="mdi-rhombus-split" />
      </div>

      <div class="flex-grow-1 overflow-y-auto custom-scrollbar pr-2 pb-4">
        <div v-if="store.isLoading && store.widgets.length === 0" class="d-flex align-center justify-center h-100">
            <v-progress-circular indeterminate color="primary" size="64"></v-progress-circular>
        </div>

        <draggable
            v-else
            v-model="store.widgets"
            item-key="id"
            class="v-row v-row--dense"
            handle=".drag-handle-widget"
            :disabled="!store.editMode"
            @end="store.saveLayout"
            animation="200"
        >
            <template #item="{ element }">
                <v-col
                    v-if="element.visible"
                    :cols="12"
                    :md="element.cols > 6 ? 12 : (element.cols < 4 ? 6 : element.cols)"
                    :lg="element.cols"
                    class="transition-all"
                >
                    <div class="h-100 position-relative group" :class="{ 'edit-mode-active': store.editMode }">

                        <div v-if="store.editMode" class="drag-handle-widget">
                            <div class="glass-chip px-3 py-1 rounded-pill d-flex align-center gap-2 border-white-20 shadow-lg pointer-events-none">
                                <v-icon size="small" color="white">mdi-drag</v-icon>
                                <span class="text-caption font-weight-bold text-white">Mover Widget</span>
                            </div>
                        </div>

                        <div
                            v-if="element.type === 'kpi'"
                            class="glass-card pa-5 position-relative overflow-hidden kpi-card d-flex flex-column justify-space-between cursor-pointer"
                            :style="{ height: element.config?.height ? element.config.height + 'px' : '100%', minHeight: '140px' }"
                            @click="!store.editMode ? openWidgetDetail(element) : null"
                        >
                             <div class="absolute-bg-icon" :class="element.config.gradient || 'bg-gradient-primary'">
                                <v-icon>{{ element.config.icon }}</v-icon>
                             </div>

                             <div class="d-flex justify-space-between mb-2 z-1">
                               <span class="text-caption text-white-70 font-weight-bold text-uppercase letter-spacing-1 d-flex align-center gap-2">
                                  <v-icon size="x-small" class="opacity-50">{{ element.config.icon }}</v-icon>
                                  {{ element.title }}
                               </span>

                               <v-chip v-if="element.comparison !== undefined && element.comparison !== 0" size="x-small" :color="element.comparison >= 0 ? 'success' : 'error'" variant="tonal" class="font-weight-bold border-none px-2">
                                 <v-icon start size="x-small">{{ element.comparison >= 0 ? 'mdi-arrow-up' : 'mdi-arrow-down' }}</v-icon>
                                 {{ Math.abs(element.comparison).toFixed(1) }}%
                               </v-chip>
                             </div>

                             <div class="d-flex align-end gap-2 kpi-content z-1">
                               <h2 class="text-h3 font-weight-black text-white kpi-value text-shadow">{{ formatValue(element.value, element.config.format) }}</h2>
                             </div>

                             <div class="mt-2 z-1 opacity-50">
                                 <div v-if="element.title.toLowerCase().includes('faturamento') || element.title.toLowerCase().includes('vendas')">
                                    <v-progress-linear model-value="70" color="white" height="3" rounded class="opacity-50"></v-progress-linear>
                                 </div>
                                 <svg v-else class="sparkline-svg" viewBox="0 0 100 20" preserveAspectRatio="none"><path d="M0,15 Q20,5 40,10 T100,5" fill="none" stroke="rgba(255,255,255,0.3)" stroke-width="2" /></svg>
                             </div>
                        </div>

                        <div
                            v-else-if="element.type === 'chart'"
                            class="glass-panel rounded-xl d-flex flex-column overflow-hidden"
                            :style="{ height: element.config?.height ? element.config.height + 'px' : '100%', minHeight: '280px' }"
                        >
                            <div class="px-4 py-3 border-b border-white-10 d-flex justify-space-between align-center bg-glass-header">
                                <div class="d-flex align-center gap-2">
                                    <v-icon size="small" color="white-50">mdi-chart-box-outline</v-icon>
                                    <span class="text-subtitle-2 font-weight-bold text-white">{{ element.title }}</span>
                                </div>
                            </div>
                            <div class="flex-grow-1 pa-4 position-relative">
                                <apexchart
                                    v-if="!element.loading && element.series"
                                    :type="element.config.chart_type"
                                    height="100%" width="100%"
                                    :options="{ ...element.options, chart: { ...element.options.chart, background: 'transparent', toolbar: { show: false }, events: { dataPointSelection: (e, c, config) => handleChartClick(element, config) } } }"
                                    :series="element.series"
                                ></apexchart>
                                <div v-else class="d-flex align-center justify-center h-100">
                                    <v-progress-circular indeterminate size="24" color="primary"></v-progress-circular>
                                </div>
                            </div>
                        </div>

                       <div
                            v-else-if="element.type === 'list'"
                            class="glass-panel rounded-xl d-flex flex-column overflow-hidden"
                            :style="{ height: element.config?.height ? element.config.height + 'px' : '100%', minHeight: '280px' }"
                        >
                            <div class="px-4 py-3 border-b border-white-10 d-flex justify-space-between align-center bg-glass-header">
                                <div class="d-flex align-center gap-2">
                                    <v-icon size="small" :color="element.config.list_type === 'ranking' ? 'warning' : 'white-50'">
                                        {{ element.config.list_type === 'ranking' ? 'mdi-trophy-outline' : 'mdi-format-list-bulleted' }}
                                    </v-icon>
                                    <span class="text-subtitle-2 font-weight-bold text-white">{{ element.title }}</span>
                                </div>
                                <v-chip size="x-small" color="white-20" variant="flat" class="font-mono text-white font-weight-bold">
                                    {{ element.listData?.length || 0 }}
                                </v-chip>
                            </div>

                            <div class="flex-grow-1 overflow-y-auto custom-scrollbar">
                                <v-table density="compact" class="bg-transparent text-white custom-table hover-rows">
                                    <thead>
                                        <tr>
                                            <th class="text-white-30 text-[10px] text-uppercase font-weight-bold pl-4 bg-glass-header sticky-top">
                                                {{ element.config.columns?.[0] || 'Item' }}
                                            </th>
                                            <th class="text-white-30 text-[10px] text-uppercase font-weight-bold bg-glass-header sticky-top text-right">
                                                {{ getMiddleColumnLabel(element) }}
                                            </th>
                                            <th class="text-right pr-4 text-white-30 text-[10px] text-uppercase font-weight-bold bg-glass-header sticky-top">
                                                {{ element.config.columns?.[2] || 'Total' }}
                                            </th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <tr v-for="(item, i) in element.listData" :key="i" class="transition-colors cursor-pointer">
                                            <td class="pl-4 py-2">
                                                <div class="d-flex align-center">
                                                    <div v-if="element.config.list_type === 'ranking' && i < 3"
                                                        class="mr-3 medal-box d-flex align-center justify-center rounded-circle shadow-sm"
                                                        :class="`medal-${i}`">
                                                        <v-icon size="10" color="white">mdi-trophy</v-icon>
                                                    </div>
                                                    <span v-else-if="element.config.list_type === 'ranking'"
                                                          class="text-caption text-white-30 font-mono mr-3 w-6 text-center">
                                                        {{ i + 1 }}
                                                    </span>
                                                    <span class="text-caption font-weight-bold text-white text-truncate">
                                                        {{ item.displayName || item.name || 'Sem Nome' }}
                                                    </span>
                                                </div>
                                            </td>

                                            <td class="text-caption text-white-50 text-right">
                                                <span v-if="isSalesRanking(element)">
                                                    {{ formatMiddleColumn(item, element) }}
                                                </span>
                                                <span v-else>
                                                    {{ item[element.config.columns?.[1]] || item.sku || '-' }}
                                                </span>
                                            </td>

                                            <td class="text-right pr-4">
                                                <span class="text-caption font-weight-black text-white">
                                                    {{ formatValue(item._val, element.config.format) }}
                                                </span>
                                            </td>
                                        </tr>
                                    </tbody>
                                </v-table>
                                <div v-if="!element.listData || element.listData.length === 0" class="text-center py-8 text-caption text-white-30">
                                    {{ element.loading ? 'Carregando...' : 'Sem dados para exibir' }}
                                </div>
                            </div>
                        </div>
                        </div>
                </v-col>
            </template>
        </draggable>
      </div>
    </div>

    <WidgetDetailModal
        v-model="showDetailModal"
        :widget="selectedWidget"  :title="selectedWidget?.title"
        :subtitle="selectedWidget?.config?.source ? `Fonte: ${formatSource(selectedWidget.config.source)}` : 'Indicador Manual'"
        :icon="selectedWidget?.config?.icon"
        :color="getWidgetColor(selectedWidget)"
    >
        <template #content>
            <div v-if="selectedWidget?.type === 'kpi'">
                <div class="glass-well pa-4 rounded-xl border border-white-10 bg-white-05 mb-4 d-flex align-center justify-space-between">
                    <div>
                        <div class="text-caption text-white-50 text-uppercase font-weight-bold">Valor Atual</div>
                        <h2 class="text-h3 font-weight-black text-white">{{ formatValue(selectedWidget.value, selectedWidget.config.format) }}</h2>
                    </div>
                    <div class="text-right">
                        <div class="text-caption text-white-50 text-uppercase font-weight-bold">Período</div>
                        <div class="text-subtitle-1 text-white font-weight-bold">{{ periods.find(p => p.value === store.selectedPeriod)?.label }}</div>
                    </div>
                </div>

                <div class="text-caption text-white-50">
                    Este indicador é calculado em tempo real baseando-se nos registros da tabela
                    <span class="font-weight-bold text-white font-mono bg-white-10 px-1 rounded">{{ selectedWidget.config.source }}</span>.
                </div>
            </div>

            <div v-else-if="selectedChartPoint" class="py-2">
                <div class="glass-well pa-4 rounded-xl mb-4 border border-primary-30 bg-primary-05">
                    <div class="text-caption text-white-50 mb-1 font-weight-bold text-uppercase">Seleção</div>
                    <div class="d-flex justify-space-between align-end">
                        <span class="text-h5 font-weight-bold text-white">{{ selectedChartPoint.label }}</span>
                        <span class="text-h4 font-weight-black text-primary">{{ formatValue(selectedChartPoint.value, 'currency') }}</span>
                    </div>
                </div>
            </div>
        </template>
        <template #actions>
             <v-btn
                color="primary"
                variant="flat"
                class="px-6 font-weight-bold shadow-glow-primary rounded-lg"
                height="40"
                :to="getSourceRoute(selectedWidget?.config?.source)"
            >
                Gerenciar Registros
                <v-icon end size="small" class="ml-2">mdi-arrow-right</v-icon>
            </v-btn>
        </template>
    </WidgetDetailModal>

  </v-container>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted, computed } from 'vue'
import { format } from 'date-fns'
import { useCajuiaDashboardStore } from '@/stores/cajuiaDashboard'
import { useUserStore } from '@/stores/user'
import { supabase } from '@/api/supabase'
import draggable from 'vuedraggable'
import ApexCharts from 'vue3-apexcharts'
import WidgetDetailModal from '@/components/cajuia/WidgetDetailModal.vue'
import DashboardBuilderDrawer from '@/components/cajuia/DashboardBuilderDrawer.vue'

const store = useCajuiaDashboardStore()
const userStore = useUserStore()
const showBuilder = ref(false)
const showDetailModal = ref(false)
const selectedWidget = ref<any>(null)
const selectedChartPoint = ref<any>(null)
const realTimeClock = ref(format(new Date(), 'HH:mm:ss'))
let clockInterval: NodeJS.Timeout

const timeBasedGreeting = computed(() => {
    const hour = new Date().getHours()
    if (hour < 12) return 'Bom dia'
    if (hour < 18) return 'Boa tarde'
    return 'Boa noite'
})

const userFirstName = computed(() => {
    const name = userStore.profile?.full_name || 'Visitante'
    return name.split(' ')[0]
})

const userRole = computed(() => {
    const role = userStore.profile?.role || 'Usuário'
    return role.charAt(0).toUpperCase() + role.slice(1)
})

const accessDescription = computed(() => {
    const role = userStore.profile?.role
    if (role === 'admin') return 'Acesso Irrestrito ao Sistema'
    if (role === 'vendedor') return 'Gestão de Clientes e Vendas'
    if (role === 'producao') return 'Controle de Estoque e Produção'
    return 'Visualização de Dashboards'
})

const periods = [
    { label: 'Hoje', value: 'today' },
    { label: '7 Dias', value: 'week' },
    { label: 'Este Mês', value: 'month' }
]

const setPeriod = (val: any) => {
    store.selectedPeriod = val;
    store.refreshAllData();
    setTimeout(() => syncKpisWithRealData(), 500)
}

const handleLayoutUpdate = () => {
    syncKpisWithRealData()
}

const formatValue = (val: any, type?: string) => {
    if (val === undefined || val === null) return '-'
    if (type === 'currency') return new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(Number(val))
    if (type === 'percent') return `${Number(val).toFixed(1)}%`
    if (type === 'number') return new Intl.NumberFormat('pt-BR').format(Number(val))
    return val
}

const formatSource = (source: string) => {
    if(!source) return 'Sistema'
    return source.replace('cajuia_', '').replace('_', ' ').toUpperCase()
}

const getWidgetColor = (w: any) => {
    const map: any = { 'bg-gradient-primary': 'primary', 'bg-gradient-success': 'success', 'bg-gradient-warning': 'warning', 'bg-gradient-error': 'error', 'bg-gradient-info': 'info' }
    return map[w?.config?.gradient] || 'primary'
}

const getSourceRoute = (source: string) => {
    if(source === 'cajuia_orders') return { name: 'CajuiaOrders' }
    if(source === 'cajuia_products') return { name: 'CajuiaPDV' }
    if(source === 'cajuia_clients') return { name: 'CajuiaClients' }
    return null
}

const openWidgetDetail = (widget: any) => {
    if (widget.type === 'chart') return
    selectedWidget.value = widget; selectedChartPoint.value = null; showDetailModal.value = true
}

const handleChartClick = (widget: any, config: any) => {
    const idx = config.dataPointIndex; if (idx === -1) return
    const label = config.w.globals.labels[idx]; const value = config.w.globals.series[config.seriesIndex][idx]
    selectedWidget.value = widget; selectedChartPoint.value = { label, value }; showDetailModal.value = true
}

// --- FUNÇÕES DE EXIBIÇÃO INTELIGENTE DE RANKING ---
const isSalesRanking = (w: any) => {
    return w.config?.list_type === 'ranking' &&
           (w.config?.source === 'cajuia_order_items' || w.config?.source === 'cajuia_products')
}

const getMiddleColumnLabel = (w: any) => {
    if (w.config?.columns?.[1]) return w.config.columns[1]
    if (isSalesRanking(w)) {
        // Se ordenado por quantidade, mostra Valor. Se por Valor, mostra Qtd.
        return w.config.column === 'quantity' || w.config.column === 'quantity_in_stock' ? 'Valor (R$)' : 'Qtd'
    }
    return 'Detalhe'
}

const formatMiddleColumn = (item: any, w: any) => {
    // Se ordenado por quantidade, mostra o valor monetário no meio
    if (w.config.column === 'quantity' || w.config.column === 'quantity_in_stock') {
        return formatValue(item.total_price, 'currency')
    }
    // Se ordenado por valor, mostra a quantidade no meio
    return (item.quantity || 0) + ' un'
}

const syncKpisWithRealData = async () => {
    try {
        const inventoryWidgets = store.widgets.filter(w =>
            w.type === 'kpi' &&
            (w.title.toLowerCase().includes('estoque') || w.title.toLowerCase().includes('inventário'))
        )

        if (inventoryWidgets.length > 0) {
            const { data: products } = await supabase.from('cajuia_products').select('price, quantity_in_stock')
            if (products) {
                const totalValue = products.reduce((acc, p) => acc + ((p.quantity_in_stock || 0) * (p.price || 0)), 0)
                inventoryWidgets.forEach(w => {
                    w.value = totalValue
                    w.config.format = 'currency'
                })
            }
        }

        const salesWidgets = store.widgets.filter(w =>
            w.type === 'kpi' &&
            (w.title.toLowerCase().includes('faturamento') || w.title.toLowerCase().includes('vendas'))
        )

        if (salesWidgets.length > 0) {
            const now = new Date()
            let startDate = new Date()
            if (store.selectedPeriod === 'today') startDate.setHours(0,0,0,0)
            if (store.selectedPeriod === 'week') startDate.setDate(now.getDate() - 7)
            if (store.selectedPeriod === 'month') startDate.setDate(1)

            const { data: orders } = await supabase
                .from('cajuia_orders')
                .select('total_value')
                .gte('created_at', startDate.toISOString())

            if (orders) {
                const totalSales = orders.reduce((acc, o) => acc + (Number(o.total_value) || 0), 0)
                salesWidgets.forEach(w => {
                    w.value = totalSales
                    w.config.format = 'currency'
                })
            }
        }

        const clientWidgets = store.widgets.filter(w => w.type === 'kpi' && w.title.toLowerCase().includes('clientes'))
        if(clientWidgets.length > 0) {
             const { count } = await supabase.from('cajuia_clients').select('*', { count: 'exact', head: true })
             clientWidgets.forEach(w => w.value = count || 0)
        }

    } catch (e) {
        console.error("Erro sync real:", e)
    }
}

onMounted(async () => {
    if (!userStore.profile) await userStore.fetchProfile();
    await store.loadDashboard()
    await syncKpisWithRealData()
    clockInterval = setInterval(() => { realTimeClock.value = format(new Date(), 'HH:mm:ss') }, 1000)
})

onUnmounted(() => clearInterval(clockInterval))
</script>

<style scoped lang="scss">
.dashboard-view { width: 100vw; height: 100vh; overflow: hidden; }
.bg-animated-image { position: relative; z-index: 1; background: transparent; }
.background-overlay { position: absolute; inset: 0; background: rgba(10, 10, 15, 0.4); z-index: -1; }
.content-wrapper { position: relative; z-index: 2; width: 100%; }

/* Glass System */
.glass-panel, .glass-card, .glass-modal, .glass-menu {
  background: rgba(30, 30, 35, 0.5);
  backdrop-filter: blur(16px);
  -webkit-backdrop-filter: blur(16px);
  border: 1px solid rgba(255, 255, 255, 0.1);
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
}
.glass-card { border-radius: 16px; transition: transform 0.2s; }
.bg-glass-header { background: rgba(255, 255, 255, 0.02); }
.glass-chip { background: rgba(255, 255, 255, 0.08); border: 1px solid rgba(255,255,255,0.05); }
.glass-btn { background: rgba(255, 255, 255, 0.05); border: 1px solid rgba(255, 255, 255, 0.15); }
.glass-btn-icon { background: rgba(255, 255, 255, 0.05); border-radius: 8px; }

/* Animation: Waving Hand */
.wave-hand {
  display: inline-block;
  animation: wave-animation 2.5s infinite;
  transform-origin: 70% 70%;
  margin-left: 10px;
}

@keyframes wave-animation {
    0% { transform: rotate( 0.0deg) }
   10% { transform: rotate(14.0deg) }
   20% { transform: rotate(-8.0deg) }
   30% { transform: rotate(14.0deg) }
   40% { transform: rotate(-4.0deg) }
   50% { transform: rotate(10.0deg) }
   60% { transform: rotate( 0.0deg) }
  100% { transform: rotate( 0.0deg) }
}

/* Decorativos da Welcome Banner */
.absolute-decoration { position: absolute; pointer-events: none; }
.icon-bg { right: -20px; bottom: -30px; font-size: 150px; opacity: 0.05; transform: rotate(15deg); }
.glow-effect {
    top: -50%; left: -20%; width: 80%; height: 200%;
    background: radial-gradient(circle, rgba(var(--v-theme-primary), 0.15), transparent 70%);
    filter: blur(60px);
}

/* Drag Handle */
.drag-handle-widget {
    position: absolute;
    top: 0; left: 0; right: 0; bottom: 0;
    z-index: 100;
    background: rgba(10, 10, 15, 0.6);
    backdrop-filter: blur(3px);
    display: flex; align-items: center; justify-content: center;
    cursor: move;
    border-radius: 16px;
    transition: opacity 0.2s;
}

/* KPI Card */
.kpi-card { transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1); }
.kpi-card:hover {
    transform: translateY(-4px);
    border-color: rgba(255,255,255,0.2);
    box-shadow: 0 20px 40px rgba(0,0,0,0.4);
}

.absolute-bg-icon {
    position: absolute;
    bottom: -20px; right: -20px;
    opacity: 0.15;
    transform: rotate(-15deg);
    z-index: 0;
    pointer-events: none;
    transition: transform 0.5s;
}
.absolute-bg-icon .v-icon { font-size: 160px; line-height: 1; }
.kpi-card:hover .absolute-bg-icon { transform: rotate(-5deg) scale(1.1); opacity: 0.2; }

/* Gradients */
.bg-gradient-primary { .v-icon { background: linear-gradient(135deg, rgb(var(--v-theme-primary)), transparent); -webkit-background-clip: text; -webkit-text-fill-color: transparent; color: rgb(var(--v-theme-primary)); } }
.bg-gradient-success { .v-icon { background: linear-gradient(135deg, #00c853, transparent); -webkit-background-clip: text; -webkit-text-fill-color: transparent; color: #00c853; } }
.bg-gradient-warning { .v-icon { background: linear-gradient(135deg, #ffca28, transparent); -webkit-background-clip: text; -webkit-text-fill-color: transparent; color: #ffca28; } }
.bg-gradient-info { .v-icon { background: linear-gradient(135deg, #29b6f6, transparent); -webkit-background-clip: text; -webkit-text-fill-color: transparent; color: #29b6f6; } }
.bg-gradient-error { .v-icon { background: linear-gradient(135deg, #ef5350, transparent); -webkit-background-clip: text; -webkit-text-fill-color: transparent; color: #ef5350; } }

.z-1 { position: relative; z-index: 1; }
.sparkline-svg { position: absolute; bottom: 0; left: 0; width: 100%; height: 40px; opacity: 0.4; pointer-events: none; }

/* Utils */
.text-shadow { text-shadow: 0 2px 10px rgba(0,0,0,0.5); }
.hover-rows tr:hover td { background: rgba(255,255,255,0.05) !important; }
.custom-scrollbar::-webkit-scrollbar { width: 5px; }
.custom-scrollbar::-webkit-scrollbar-thumb { background: rgba(255, 255, 255, 0.15); border-radius: 3px; }
.medal-box { width: 20px; height: 20px; }
.medal-0 { background: linear-gradient(45deg, #FFD700, #FDB931); }
.medal-1 { background: linear-gradient(45deg, #E0E0E0, #BDBDBD); }
.medal-2 { background: linear-gradient(45deg, #CD7F32, #A0522D); }
.status-dot { width: 8px; height: 8px; border-radius: 50%; }
.status-dot.success { background-color: #00e676; box-shadow: 0 0 8px rgba(0, 230, 118, 0.5); }
.border-warning { border-color: rgba(var(--v-theme-warning), 0.5) !important; }
.edit-mode-active { border: 1px dashed rgba(var(--v-theme-warning), 0.5); border-radius: 16px; }
.pointer-events-none { pointer-events: none; }
.bg-white-05 { background: rgba(255,255,255,0.05); }
.bg-primary-05 { background: rgba(var(--v-theme-primary), 0.1); }
.border-primary-30 { border-color: rgba(var(--v-theme-primary), 0.3) !important; }
</style>
