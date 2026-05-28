<template>
  <v-container fluid class="financial-view pa-0 bg-animated-image">
    <div class="background-overlay"></div>

    <div class="content-wrapper pa-4 d-flex flex-column h-100">

      <div class="header-section d-flex align-center justify-space-between mb-4 flex-shrink-0">
        <div class="d-flex align-center text-caption text-white-50">
          <v-icon size="small" class="mr-2">mdi-store</v-icon>
          <span>Cajuia</span>
          <v-icon size="small" class="mx-2">mdi-chevron-right</v-icon>
          <span class="text-white font-weight-bold">Gestão Financeira</span>
        </div>

        <div class="d-flex align-center gap-3">
           <div class="glass-chip px-4 py-1 rounded-pill border-white-10 d-flex align-center bg-black-20 shadow-lg">
              <span class="text-[10px] text-white-50 uppercase mr-2 font-weight-bold">Saldo Consolidado</span>
              <span class="text-body-2 font-weight-black" :class="totalBalance >= 0 ? 'text-success' : 'text-error'">
                  {{ formatCurrency(totalBalance) }}
              </span>
           </div>
           <div class="digital-clock px-3 py-1 rounded-pill glass-chip border-white-10 d-flex align-center">
             <v-icon color="primary" size="small" class="mr-2 icon-pulse">mdi-clock-outline</v-icon>
             <span class="font-weight-black text-caption text-white mono-font">{{ realTimeClock }}</span>
          </div>
        </div>
      </div>

      <v-expand-transition>
        <div v-if="showCharts" class="mb-4 flex-shrink-0">
            <v-row dense>
                <v-col cols="12" md="8">
                    <div class="glass-card pa-4 h-100">
                        <div class="d-flex justify-space-between align-center mb-2">
                            <span class="text-subtitle-2 font-weight-bold text-white">Fluxo de Caixa (30 dias)</span>
                            <div class="d-flex gap-2">
                                <span class="legend-dot bg-success"></span><span class="text-[10px] text-white-50 mr-2">Entradas</span>
                                <span class="legend-dot bg-error"></span><span class="text-[10px] text-white-50">Saídas</span>
                            </div>
                        </div>
                        <apexchart type="area" height="150" :options="cashFlowChartOptions" :series="cashFlowSeries"></apexchart>
                    </div>
                </v-col>
                <v-col cols="12" md="4">
                    <div class="glass-card pa-4 h-100">
                        <span class="text-subtitle-2 font-weight-bold text-white mb-2 d-block">Despesas por Categoria</span>
                        <apexchart type="donut" height="150" :options="categoryChartOptions" :series="categorySeries"></apexchart>
                    </div>
                </v-col>
            </v-row>
        </div>
      </v-expand-transition>

      <div class="d-flex justify-center mb-4 flex-shrink-0 position-relative">
          <div class="absolute-left">
              <v-btn
                variant="text"
                size="small"
                color="white-50"
                :prepend-icon="showCharts ? 'mdi-chevron-up' : 'mdi-chart-box-outline'"
                @click="showCharts = !showCharts"
              >
                  {{ showCharts ? 'Ocultar Gráficos' : 'Ver Gráficos' }}
              </v-btn>
          </div>

          <div class="glass-toggle-group p-1 rounded-xl d-flex bg-black-20 border border-white-10">
              <div
                class="toggle-item px-6 py-2 rounded-lg cursor-pointer transition-all d-flex align-center gap-2"
                :class="{ 'bg-success-gradient shadow-glow-success': activeTab === 'receivables' }"
                @click="activeTab = 'receivables'"
              >
                  <v-icon size="small" :color="activeTab === 'receivables' ? 'white' : 'success'">mdi-arrow-down-bold</v-icon>
                  <span class="text-caption font-weight-bold" :class="activeTab === 'receivables' ? 'text-white' : 'text-white-50'">A Receber</span>
              </div>
              <div
                class="toggle-item px-6 py-2 rounded-lg cursor-pointer transition-all d-flex align-center gap-2"
                :class="{ 'bg-error-gradient shadow-glow-error': activeTab === 'payables' }"
                @click="activeTab = 'payables'"
              >
                  <v-icon size="small" :color="activeTab === 'payables' ? 'white' : 'error'">mdi-arrow-up-bold</v-icon>
                  <span class="text-caption font-weight-bold" :class="activeTab === 'payables' ? 'text-white' : 'text-white-50'">A Pagar</span>
              </div>
          </div>
      </div>

      <v-row dense class="mb-2 flex-shrink-0">
          <v-col cols="6" md="3">
              <div class="glass-card pa-3 d-flex align-center justify-space-between hover-elevate">
                  <div>
                      <div class="text-[10px] text-white-50 font-weight-bold uppercase mb-1">Total Pendente</div>
                      <div class="text-h5 font-weight-black text-white lh-1">{{ formatCurrency(kpis.totalOpen) }}</div>
                  </div>
                  <v-icon color="white-50" size="24">mdi-scale-balance</v-icon>
              </div>
          </v-col>
          <v-col cols="6" md="3">
              <div class="glass-card pa-3 d-flex align-center justify-space-between hover-elevate cursor-pointer" @click="filters.dateStart = today; filters.dateEnd = today">
                  <div>
                      <div class="text-[10px] text-warning font-weight-bold uppercase mb-1">Vence Hoje</div>
                      <div class="text-h5 font-weight-black text-warning lh-1">{{ formatCurrency(kpis.dueToday) }}</div>
                  </div>
                  <v-icon color="warning" size="24">mdi-calendar-today</v-icon>
              </div>
          </v-col>
          <v-col cols="6" md="3">
              <div class="glass-card pa-3 d-flex align-center justify-space-between hover-elevate cursor-pointer" @click="filters.status = 'OVERDUE'">
                  <div>
                      <div class="text-[10px] text-error font-weight-bold uppercase mb-1">Em Atraso</div>
                      <div class="text-h5 font-weight-black text-error lh-1">{{ formatCurrency(kpis.overdue) }}</div>
                  </div>
                  <v-icon color="error" size="24">mdi-alert-circle</v-icon>
              </div>
          </v-col>
          <v-col cols="6" md="3">
              <div class="glass-card pa-3 d-flex align-center justify-space-between hover-elevate">
                  <div>
                      <div class="text-[10px] text-success font-weight-bold uppercase mb-1">Realizado (Mês)</div>
                      <div class="text-h5 font-weight-black text-success lh-1">{{ formatCurrency(kpis.settledMonth) }}</div>
                  </div>
                  <v-icon color="success" size="24">mdi-check-all</v-icon>
              </div>
          </v-col>
      </v-row>

      <div class="glass-panel flex-grow-1 d-flex flex-column overflow-hidden rounded-xl mt-2 border-white-05 shadow-xl">

          <div class="px-4 py-2 border-b border-white-10 d-flex align-center gap-3 bg-glass-header flex-wrap">
              <div style="width: 220px;">
                <v-text-field v-model="filters.search" density="compact" variant="solo" placeholder="Buscar..." prepend-inner-icon="mdi-magnify" hide-details class="glass-input" bg-color="rgba(20,20,25,0.5)" rounded="lg" clearable></v-text-field>
              </div>

              <div class="d-flex align-center gap-2 bg-black-20 rounded-lg px-2 py-1 border border-white-05 h-36">
                  <input type="date" v-model="filters.dateStart" class="date-input-glass font-weight-bold" />
                  <span class="text-white-50 font-weight-bold text-[10px]">ATÉ</span>
                  <input type="date" v-model="filters.dateEnd" class="date-input-glass font-weight-bold" />
              </div>

              <v-chip-group v-model="filters.status" selected-class="text-primary" mandatory>
                  <v-chip value="ALL" size="small" filter variant="outlined" class="border-white-10">Todos</v-chip>
                  <v-chip value="PENDING" size="small" filter variant="outlined" color="warning" class="border-white-10">Abertos</v-chip>
                  <v-chip value="PAID" size="small" filter variant="outlined" color="success" class="border-white-10">Pagos</v-chip>
                  <v-chip value="OVERDUE" size="small" filter variant="outlined" color="error" class="border-white-10">Vencidos</v-chip>
              </v-chip-group>

              <v-spacer></v-spacer>

              <v-menu v-if="activeTab === 'receivables'">
                  <template v-slot:activator="{ props }">
                      <v-btn v-bind="props" icon size="small" variant="text" color="white-50">
                          <v-icon>mdi-database-sync</v-icon>
                          <v-tooltip activator="parent" location="top">Ferramentas de Dados</v-tooltip>
                      </v-btn>
                  </template>
                  <v-list density="compact" class="glass-menu">
                      <v-list-item @click="syncMissingReceivables" prepend-icon="mdi-refresh">
                          <v-list-item-title>Sincronizar Pedidos Antigos</v-list-item-title>
                      </v-list-item>
                  </v-list>
              </v-menu>

              <v-btn v-if="activeTab === 'payables'" color="error" variant="flat" size="small" class="font-weight-bold shadow-glow-error" prepend-icon="mdi-plus" @click="showExpenseModal = true">Nova Despesa</v-btn>
          </div>

          <div class="flex-grow-1 overflow-y-auto custom-scrollbar px-3 py-3 bg-glass-body-gradient">

              <div class="grid-header px-4 py-2 text-[10px] font-weight-bold text-white-50 uppercase mb-2 border-b border-white-05 pb-2">
                  <div class="d-flex align-center gap-1">Vencimento <v-icon size="10">mdi-sort</v-icon></div>
                  <div>Descrição / Origem</div>
                  <div>{{ activeTab === 'receivables' ? 'Cliente / Pedido' : 'Fornecedor / Categoria' }}</div>
                  <div class="text-right">Valor Líquido</div>
                  <div class="text-center">Status</div>
                  <div class="text-center">Ações</div>
              </div>

              <v-progress-linear v-if="loading" indeterminate color="primary" height="2" class="mb-2 bg-transparent"></v-progress-linear>

              <v-slide-y-transition group>
                  <div v-for="item in filteredList" :key="item.id" class="grid-row glass-row mb-2 rounded-lg align-center pa-3 hover-highlight transition-all" :class="getRowBorderClass(item)">
                      <div class="d-flex align-center gap-3">
                          <div class="date-box rounded d-flex flex-column align-center justify-center" :class="getDateBoxColor(item)">
                              <span class="text-[10px] font-weight-bold text-uppercase">{{ getMonthShort(item.due_date) }}</span>
                              <span class="text-h6 font-weight-black lh-1">{{ getDay(item.due_date) }}</span>
                          </div>
                      </div>

                      <div class="d-flex flex-column">
                          <span class="text-caption font-weight-bold text-white text-truncate">{{ item.description }}</span>
                          <span v-if="activeTab === 'receivables'" class="text-[10px] text-white-50 d-flex align-center gap-1">
                              <v-icon size="10" color="white-50">{{ getPaymentIcon(item.payment_method) }}</v-icon>
                              {{ item.payment_method }}
                              <span v-if="item.installment_number" class="text-[9px] bg-white-10 px-1 rounded ml-1">{{ item.installment_number }}/{{ item.total_installments }}</span>
                          </span>
                      </div>

                      <div class="d-flex flex-column">
                          <span class="text-caption font-weight-bold text-white text-truncate">
                              {{ activeTab === 'receivables' ? item.customer_name : (item.supplier_name || 'Fornecedor Diverso') }}
                          </span>
                          <span v-if="activeTab === 'payables'" class="text-[9px] text-white-50 bg-white-05 px-1 rounded align-self-start mt-0.5">
                              {{ item.cajuia_expense_categories?.name || 'Geral' }}
                          </span>
                          <div v-if="activeTab === 'receivables' && item.order_id" class="d-flex align-center gap-1 mt-0.5">
                              <v-chip size="x-small" color="primary" variant="outlined" class="h-16 px-1 cursor-pointer" @click="viewOrder(item.order_id)">
                                  Pedido #{{ item.cajuia_orders?.order_number || '???' }}
                              </v-chip>
                          </div>
                      </div>

                      <div class="text-right">
                          <span class="text-body-2 font-weight-black text-white">{{ formatCurrency(activeTab === 'receivables' ? item.net_value : item.amount) }}</span>
                          <div v-if="item.status === 'PAID'" class="text-[9px] text-success font-weight-bold d-flex align-center justify-end">
                              <v-icon size="10" color="success" class="mr-1">mdi-check-all</v-icon> Pago
                          </div>
                      </div>

                      <div class="text-center">
                          <v-chip size="x-small" :color="getStatusColor(item.status)" variant="tonal" class="font-weight-bold text-uppercase border-opacity-50" style="min-width: 80px; justify-content: center;">
                              {{ getStatusLabel(item.status) }}
                          </v-chip>
                      </div>

                      <div class="d-flex justify-center gap-1">
                          <v-btn
                            v-bind="props"
                            v-if="item.status !== 'PAID' && item.status !== 'CANCELLED'"
                            icon size="x-small"
                            variant="flat"
                            :color="activeTab === 'receivables' ? 'success' : 'error'"
                            class="glass-btn-action"
                            @click="openSettleModal(item)"
                          >
                              <v-icon size="16">{{ activeTab === 'receivables' ? 'mdi-cash-plus' : 'mdi-cash-minus' }}</v-icon>
                          </v-btn>

                          <v-menu location="bottom end" transition="scale-transition">
                              <template v-slot:activator="{ props }">
                                  <v-btn icon="mdi-dots-vertical" size="x-small" variant="text" color="white-50" v-bind="props" class="glass-btn-icon"></v-btn>
                              </template>
                              <v-list density="compact" class="glass-menu border-white-10 pa-1 rounded-lg width-200">
                                  <div v-if="activeTab === 'receivables' && item.order_id">
                                      <v-list-subheader class="text-[10px] font-weight-bold text-uppercase h-24 min-h-0">Ações do Pedido</v-list-subheader>
                                      <v-list-item density="compact" rounded link @click="viewOrder(item.order_id)">
                                          <template v-slot:prepend><v-icon size="small" color="primary">mdi-eye</v-icon></template>
                                          <v-list-item-title class="text-caption">Ver Pedido Completo</v-list-item-title>
                                      </v-list-item>
                                      <v-list-item density="compact" rounded link @click="emitFiscal(item)">
                                          <template v-slot:prepend><v-icon size="small" color="warning">mdi-file-document-outline</v-icon></template>
                                          <v-list-item-title class="text-caption">Emitir Nota (NF-e)</v-list-item-title>
                                      </v-list-item>
                                      <v-list-item density="compact" rounded link @click="printReceipt(item)">
                                          <template v-slot:prepend><v-icon size="small" color="info">mdi-printer</v-icon></template>
                                          <v-list-item-title class="text-caption">Imprimir Recibo</v-list-item-title>
                                      </v-list-item>
                                      <v-divider class="my-1 border-white-10"></v-divider>
                                  </div>

                                  <v-list-item density="compact" rounded link class="text-error" @click="activeTab === 'receivables' ? cancelTitle(item) : deletePayable(item.id)">
                                      <template v-slot:prepend><v-icon size="small" color="error">mdi-delete-outline</v-icon></template>
                                      <v-list-item-title class="text-caption">Excluir/Cancelar</v-list-item-title>
                                  </v-list-item>
                              </v-list>
                          </v-menu>
                      </div>
                  </div>
              </v-slide-y-transition>
          </div>
      </div>
    </div>

    <FinancialSettlementModal v-if="settleItem && activeTab === 'receivables'" v-model="showSettleModal" :title="settleItem" @settled="onSettled" />
    <CajuiaExpenseModal v-model="showExpenseModal" @saved="fetchData" />

    <v-dialog v-model="showPayModal" max-width="400" content-class="glass-dialog-settle">
        <v-card class="glass-modal-card">
            <div class="pa-4 border-b border-white-10 bg-glass-header"><span class="text-h6 text-white font-weight-bold">Confirmar Pagamento</span></div>
            <div class="pa-4 bg-glass-body">
                <v-select label="Conta de Saída" :items="bankAccounts" item-title="name" item-value="id" v-model="paymentAccount" variant="outlined" density="compact" class="glass-input mb-2"></v-select>
                <v-btn block color="error" class="mt-4 font-weight-bold shadow-glow-error" @click="confirmPayment" :loading="loadingPayment">Pagar Agora</v-btn>
            </div>
        </v-card>
    </v-dialog>

  </v-container>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted, watch } from 'vue'
import { supabase } from '@/api/supabase'
import { format, isBefore, isToday, startOfMonth, endOfMonth, parseISO, isSameMonth, subDays } from 'date-fns'
import { ptBR } from 'date-fns/locale'
import { useRouter } from 'vue-router'
import FinancialSettlementModal from '@/components/cajuia/FinancialSettlementModal.vue'
import CajuiaExpenseModal from '@/components/cajuia/CajuiaExpenseModal.vue'

const router = useRouter()
const activeTab = ref<'receivables' | 'payables'>('receivables')
const loading = ref(false)
const loadingPayment = ref(false)
const listData = ref<any[]>([])
const bankAccounts = ref<any[]>([])
const showCharts = ref(true)

// Modais
const showSettleModal = ref(false)
const showPayModal = ref(false)
const showExpenseModal = ref(false)
const settleItem = ref<any>(null)
const paymentAccount = ref(null)

// Clock
const realTimeClock = ref(format(new Date(), 'HH:mm:ss'))
const lastSyncTime = ref('--:--')
let clockInterval: NodeJS.Timeout
const today = format(new Date(), 'yyyy-MM-dd')

const filters = ref({
    search: '', status: 'ALL',
    dateStart: format(startOfMonth(new Date()), 'yyyy-MM-dd'),
    dateEnd: format(endOfMonth(new Date()), 'yyyy-MM-dd')
})

const statusOptions = [{ label: 'Todos', value: 'ALL' }, { label: 'Pendentes', value: 'PENDING' }, { label: 'Pagos', value: 'PAID' }, { label: 'Vencidos', value: 'OVERDUE' }]

// --- DATA FETCHING (Com Join de Pedidos) ---
const fetchData = async () => {
    loading.value = true
    try {
        const table = activeTab.value === 'receivables' ? 'cajuia_receivables' : 'cajuia_payables'
        // Join importante: cajuia_orders(order_number) para mostrar o número do pedido
        let query = supabase.from(table).select(
            activeTab.value === 'payables'
            ? '*, cajuia_expense_categories(name)'
            : '*, cajuia_orders(order_number)'
        )

        const { data, error } = await query.order('due_date', { ascending: true })
        if (error) throw error
        listData.value = data || []
        lastSyncTime.value = format(new Date(), 'HH:mm')
    } catch (e) { console.error(e) } finally { loading.value = false }
}

const fetchAccounts = async () => {
    const { data } = await supabase.from('cajuia_bank_accounts').select('id, name, current_balance')
    bankAccounts.value = data || []
    if (data && data.length > 0) paymentAccount.value = data[0].id
}

watch(activeTab, () => fetchData())

// --- CHART DATA (ApexCharts) ---
const cashFlowSeries = computed(() => {
    // Mock de dados por enquanto (idealmente agrupar listData por dia)
    return [{ name: 'Entradas', data: [30, 40, 35, 50, 49, 60, 70] }, { name: 'Saídas', data: [20, 25, 10, 30, 20, 15, 20] }]
})
const cashFlowChartOptions = {
    chart: { type: 'area', toolbar: { show: false }, background: 'transparent' },
    colors: ['#00e676', '#ff5252'],
    stroke: { curve: 'smooth', width: 2 },
    theme: { mode: 'dark' },
    grid: { show: false },
    dataLabels: { enabled: false },
    xaxis: { labels: { show: false }, axisBorder: { show: false }, axisTicks: { show: false } },
    yaxis: { show: false }
}

const categorySeries = computed(() => [44, 55, 13]) // Mock
const categoryChartOptions = {
    chart: { type: 'donut', background: 'transparent' },
    labels: ['Fixo', 'Variável', 'Pessoal'],
    colors: ['#29b6f6', '#ffa726', '#ef5350'],
    theme: { mode: 'dark' },
    legend: { position: 'right' },
    plotOptions: { pie: { donut: { size: '65%' } } }
}

// --- KPI & LOGIC ---
const kpis = computed(() => {
    const todayObj = new Date()
    const open = listData.value.filter(i => i.status === 'PENDING' || i.status === 'OVERDUE')
    const valKey = activeTab.value === 'receivables' ? 'net_value' : 'amount'

    return {
        totalOpen: open.reduce((acc, i) => acc + Number(i[valKey]), 0),
        dueToday: open.filter(i => isToday(parseISO(i.due_date))).reduce((acc, i) => acc + Number(i[valKey]), 0),
        overdue: listData.value.filter(i => isOverdue(i)).reduce((acc, i) => acc + Number(i[valKey]), 0),
        settledMonth: listData.value.filter(i => i.status === 'PAID' && i.payment_date && isSameMonth(parseISO(i.payment_date), todayObj)).reduce((acc, i) => acc + (i.amount_paid || Number(i[valKey])), 0)
    }
})

const filteredList = computed(() => {
    return listData.value.filter(item => {
        if (filters.value.status !== 'ALL') {
            if(filters.value.status === 'OVERDUE') return isOverdue(item)
            if(item.status !== filters.value.status) return false
        }
        if (filters.value.dateStart && item.due_date < filters.value.dateStart) return false
        if (filters.value.dateEnd && item.due_date > filters.value.dateEnd) return false
        if (filters.value.search) {
            const q = filters.value.search.toLowerCase()
            const desc = item.description?.toLowerCase() || ''
            const ent = (activeTab.value === 'receivables' ? item.customer_name : item.supplier_name)?.toLowerCase() || ''
            const ord = item.cajuia_orders?.order_number?.toString() || ''
            if (!desc.includes(q) && !ent.includes(q) && !ord.includes(q)) return false
        }
        return true
    })
})

const totalBalance = computed(() => bankAccounts.value.reduce((acc, b) => acc + Number(b.current_balance), 0))

// --- ACTIONS ESPECÍFICAS DE PEDIDO ---
const viewOrder = (orderId: string) => {
    // Redirecionar para a tela de Pedidos, talvez filtrando pelo ID (Feature futura)
    router.push({ name: 'CajuiaOrders' })
}

const emitFiscal = (item: any) => {
    alert(`Enviando Pedido #${item.cajuia_orders?.order_number} para SEFAZ... (Mock)`)
}

const printReceipt = (item: any) => {
    alert('Imprimindo Recibo...')
}

const syncMissingReceivables = async () => {
    // Lógica para buscar pedidos sem financeiro e criar
    alert('Buscando pedidos sem financeiro...')
}

// --- CRUD ACTIONS ---
const openSettleModal = (item: any) => {
    settleItem.value = item
    if (activeTab.value === 'receivables') showSettleModal.value = true
    else showPayModal.value = true
}

const onSettled = () => { fetchData(); fetchAccounts(); }

const confirmPayment = async () => {
    if (!paymentAccount.value || !settleItem.value) return
    loadingPayment.value = true
    try {
        const amount = settleItem.value.amount
        await supabase.from('cajuia_payables').update({ status: 'PAID', payment_date: new Date().toISOString(), bank_account_id: paymentAccount.value }).eq('id', settleItem.value.id)
        const acc = bankAccounts.value.find(a => a.id === paymentAccount.value)
        if(acc) await supabase.from('cajuia_bank_accounts').update({ current_balance: Number(acc.current_balance) - Number(amount) }).eq('id', acc.id)
        showPayModal.value = false; fetchData(); fetchAccounts();
    } catch(e) { console.error(e) } finally { loadingPayment.value = false }
}

const deletePayable = async (id: string) => {
    if(confirm('Excluir?')) { await supabase.from('cajuia_payables').delete().eq('id', id); fetchData(); }
}

const cancelTitle = async (item: any) => {
    if(!confirm('Cancelar título?')) return
    await supabase.from('cajuia_receivables').update({ status: 'CANCELLED' }).eq('id', item.id)
    fetchData()
}

// Helpers Visuais
const isOverdue = (item: any) => item.status !== 'PAID' && item.status !== 'CANCELLED' && isBefore(parseISO(item.due_date), new Date()) && !isToday(parseISO(item.due_date))
const getStatusColor = (s: string) => ({ PAID: 'success', PENDING: 'warning', OVERDUE: 'error', CANCELLED: 'grey' }[s] || 'grey')
const getStatusLabel = (s: string) => ({ PAID: 'Liquidado', PENDING: 'Aberto', OVERDUE: 'Vencido', CANCELLED: 'Cancelado' }[s] || s)
const getDateBoxColor = (item: any) => {
    if (item.status === 'PAID') return 'bg-success-10 text-success border-success'
    if (isOverdue(item)) return 'bg-error-10 text-error border-error'
    if (item.status === 'PENDING' && isToday(parseISO(item.due_date))) return 'bg-warning-10 text-warning border-warning'
    return 'bg-white-05 text-white border-white-10'
}
const getRowBorderClass = (item: any) => {
    if (item.status === 'PAID') return 'border-l-success'
    if (isOverdue(item)) return 'border-l-error'
    if (item.status === 'PENDING' && isToday(parseISO(item.due_date))) return 'border-l-warning'
    return ''
}
const getPaymentIcon = (method: string) => {
    const m = method?.toLowerCase() || ''
    if (m.includes('pix')) return 'mdi-qrcode'
    if (m.includes('dinheiro')) return 'mdi-cash'
    if (m.includes('boleto')) return 'mdi-barcode'
    if (m.includes('cartão')) return 'mdi-credit-card'
    return 'mdi-currency-usd'
}
const formatCurrency = (v: number) => new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(v)
const formatDate = (d: string) => d ? format(parseISO(d), 'dd/MM/yyyy') : '-'
const getDay = (d: string) => d ? format(parseISO(d), 'dd') : ''
const getMonthShort = (d: string) => d ? format(parseISO(d), 'MMM', { locale: ptBR }) : ''

onMounted(() => {
    fetchData()
    fetchAccounts()
    clockInterval = setInterval(() => realTimeClock.value = format(new Date(), 'HH:mm:ss'), 1000)
})
onUnmounted(() => clearInterval(clockInterval))
</script>

<style scoped lang="scss">
.financial-view { height: 100vh; width: 100vw; overflow: hidden; }
.bg-animated-image { background: #12121200; position: relative; z-index: 1; }
.background-overlay { position: absolute; inset: 0; background: rgba(10, 10, 15, 0.5); z-index: -1; }
.content-wrapper { position: relative; z-index: 2; }

/* Glass Components */
.glass-panel, .glass-card, .glass-modal-card {
    background: rgba(30, 30, 35, 0.6);
    backdrop-filter: blur(16px);
    border: 1px solid rgba(255, 255, 255, 0.08);
    box-shadow: 0 8px 32px rgba(0,0,0,0.3);
}
.glass-card { border-radius: 16px; transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1); }
.glass-modal-card { background: #1e1e24; border-radius: 16px; border: 1px solid rgba(255,255,255,0.1); }
.glass-menu { background: rgba(30, 30, 35, 0.95) !important; backdrop-filter: blur(12px); }
.glass-dialog-settle { backdrop-filter: blur(5px); }

/* Toggle Group */
.bg-success-gradient { background: linear-gradient(135deg, #00c853, #006025); }
.bg-error-gradient { background: linear-gradient(135deg, #d32f2f, #b71c1c); }
.shadow-glow-success { box-shadow: 0 0 15px rgba(0, 200, 83, 0.4); }
.shadow-glow-error { box-shadow: 0 0 15px rgba(211, 47, 47, 0.4); }
.shadow-glow-warning { box-shadow: 0 0 15px rgba(255, 193, 7, 0.4); }
.shadow-glow-info { box-shadow: 0 0 15px rgba(41, 182, 246, 0.4); }

/* Table Styles */
.grid-header, .grid-row { display: grid; grid-template-columns: 80px 2fr 1.5fr 1fr 100px 80px; gap: 16px; align-items: center; }
.glass-row {
    background: rgba(255,255,255,0.02);
    border: 1px solid rgba(255,255,255,0.03);
    border-left-width: 3px; border-left-color: transparent;
    transition: all 0.2s;
}
.border-l-success { border-left-color: #00e676 !important; }
.border-l-error { border-left-color: #ff5252 !important; }
.border-l-warning { border-left-color: #ffca28 !important; }
.hover-highlight:hover { background: rgba(255,255,255,0.05); transform: translateX(2px); }

/* Icons & Glows */
.icon-box-lg { width: 50px; height: 50px; border-radius: 14px; display: flex; align-items: center; justify-content: center; }
.icon-box-sm { width: 36px; height: 36px; border-radius: 10px; display: flex; align-items: center; justify-content: center; }
.bg-gradient-warning { background: linear-gradient(135deg, #ffca28, #ff6f00); }
.bg-gradient-info { background: linear-gradient(135deg, #29b6f6, #01579b); }
.bg-gradient-primary { background: linear-gradient(135deg, rgb(var(--v-theme-primary)), #1565c0); }

.bg-glow-success { position: absolute; width: 100px; height: 100px; background: #00e676; filter: blur(60px); opacity: 0.15; top: -20px; right: -20px; z-index: 0; }
.bg-glow-error { position: absolute; width: 100px; height: 100px; background: #ff5252; filter: blur(60px); opacity: 0.15; top: -20px; right: -20px; z-index: 0; }
.bg-glow-warning { position: absolute; width: 100px; height: 100px; background: #ffca28; filter: blur(60px); opacity: 0.15; top: -20px; right: -20px; z-index: 0; }
.bg-glow-info { position: absolute; width: 100px; height: 100px; background: #29b6f6; filter: blur(60px); opacity: 0.15; top: -20px; right: -20px; z-index: 0; }

.hover-elevate:hover { transform: translateY(-4px); box-shadow: 0 12px 40px rgba(0,0,0,0.4); }
.z-index-1 { position: relative; z-index: 1; }

/* UI Utils */
.text-white-50 { color: rgba(255,255,255,0.5) !important; }
.border-white-05 { border-color: rgba(255,255,255,0.05) !important; }
.border-white-10 { border-color: rgba(255,255,255,0.1) !important; }
.border-white-20 { border-color: rgba(255,255,255,0.2) !important; }
.bg-black-20 { background: rgba(0,0,0,0.2); }
.bg-glass-header { background: rgba(255, 255, 255, 0.03); }
.bg-glass-body { background: #1e1e24; }
.bg-glass-body-gradient { background: linear-gradient(to bottom, rgba(255,255,255,0.01), transparent); }
.glass-input :deep(.v-field) { border-radius: 8px; border: 1px solid rgba(255,255,255,0.1); color: white; font-size: 0.85rem; }
.glass-btn-action { transition: transform 0.2s; &:hover { transform: scale(1.1); } }
.glass-btn-icon { background: rgba(255,255,255,0.05); border-radius: 8px; transition: 0.2s; &:hover { background: rgba(255,255,255,0.1); } }

.date-box { width: 40px; height: 40px; border: 1px solid; }
.bg-success-10 { background: rgba(0, 230, 118, 0.15); border-color: rgba(0, 230, 118, 0.3); }
.bg-error-10 { background: rgba(255, 82, 82, 0.15); border-color: rgba(255, 82, 82, 0.3); }
.bg-warning-10 { background: rgba(255, 202, 40, 0.15); border-color: rgba(255, 202, 40, 0.3); }
.bg-white-05 { background: rgba(255,255,255,0.05); }

/* Custom Scrollbar & Inputs */
.custom-scrollbar::-webkit-scrollbar { width: 5px; }
.custom-scrollbar::-webkit-scrollbar-track { background: transparent; }
.custom-scrollbar::-webkit-scrollbar-thumb { background: rgba(255, 255, 255, 0.15); border-radius: 4px; }
.date-input-glass { background: transparent; border: none; color: white; font-family: 'Roboto Mono', monospace; font-size: 0.75rem; outline: none; width: 90px; &::-webkit-calendar-picker-indicator { filter: invert(1); cursor: pointer; opacity: 0.5; transform: scale(0.8); } }

/* Animations */
.icon-pulse { animation: pulse 2s infinite; }
@keyframes pulse { 0% { opacity: 1; } 50% { opacity: 0.6; } 100% { opacity: 1; } }
.pulsing-animation { animation: pulse-ring 2s infinite; }
@keyframes pulse-ring { 0% { box-shadow: 0 0 0 0 rgba(255, 255, 255, 0.1); } 70% { box-shadow: 0 0 0 10px rgba(255, 255, 255, 0); } 100% { box-shadow: 0 0 0 0 rgba(255, 255, 255, 0); } }
.h-16 { height: 16px; } .h-24 { height: 24px; } .h-36 { height: 36px; } .h-40 { height: 40px; }
.lh-1 { line-height: 1; } .gap-1 { gap: 4px; } .gap-2 { gap: 8px; } .gap-3 { gap: 12px; } .gap-4 { gap: 16px; }
.cursor-help { cursor: help; } .cursor-pointer { cursor: pointer; } .absolute-left { position: absolute; left: 0; }
</style>
