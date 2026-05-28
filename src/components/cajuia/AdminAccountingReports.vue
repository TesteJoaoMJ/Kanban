<template>
  <div class="d-flex flex-column h-100 bg-glass-body-gradient overflow-hidden">

    <div class="px-6 py-4 border-b border-white-10 d-flex justify-space-between align-center flex-shrink-0 bg-glass-header">
      <div class="d-flex align-center gap-4">
        <div class="icon-box bg-info-10 rounded-lg d-flex align-center justify-center elevation-4 border border-white-05" style="width: 42px; height: 42px;">
           <v-icon color="info" size="24">mdi-finance</v-icon>
        </div>
        <div>
          <h2 class="text-subtitle-1 font-weight-black text-white lh-1 mb-1">Demonstrações Financeiras</h2>
          <div class="text-[11px] text-white-50 font-weight-medium d-flex align-center gap-2">
             <v-icon size="8" color="success" class="icon-pulse">mdi-circle</v-icon>
             <span class="text-uppercase letter-spacing-1">Dados em Tempo Real</span>
          </div>
        </div>
      </div>

      <div class="d-flex align-center gap-2 bg-black-20 p-1 rounded-lg border border-white-10">
         <v-btn-toggle v-model="periodPreset" density="compact" mandatory class="bg-transparent mr-2" color="primary">
            <v-btn value="this_month" class="text-[10px] font-weight-bold px-3 h-28 text-none">Este Mês</v-btn>
            <v-btn value="last_month" class="text-[10px] font-weight-bold px-3 h-28 text-none">Mês Passado</v-btn>
            <v-btn value="year" class="text-[10px] font-weight-bold px-3 h-28 text-none">Este Ano</v-btn>
         </v-btn-toggle>

         <div class="d-flex align-center gap-2 px-3 border-l border-white-10 h-20">
            <input type="date" v-model="filterStartDate" class="glass-date-input text-[11px] font-weight-bold text-white font-mono">
            <span class="text-white-30 text-[9px]">ATÉ</span>
            <input type="date" v-model="filterEndDate" class="glass-date-input text-[11px] font-weight-bold text-white font-mono">
         </div>

         <v-btn icon size="x-small" variant="flat" color="primary" class="ml-2 rounded" @click="fetchReport" :loading="loading">
            <v-icon>mdi-refresh</v-icon>
         </v-btn>
         <v-menu>
            <template v-slot:activator="{ props }">
               <v-btn v-bind="props" icon size="x-small" variant="text" color="white-50">
                  <v-icon>mdi-download</v-icon>
               </v-btn>
            </template>
            <v-list density="compact" class="bg-glass-card border-white-10">
               <v-list-item @click="exportReport('pdf')" class="text-white hover-bg-white-05">
                  <template v-slot:prepend><v-icon size="small" color="error">mdi-file-pdf-box</v-icon></template>
                  <v-list-item-title class="text-caption">Exportar PDF</v-list-item-title>
               </v-list-item>
               <v-list-item @click="exportReport('csv')" class="text-white hover-bg-white-05">
                  <template v-slot:prepend><v-icon size="small" color="success">mdi-file-excel</v-icon></template>
                  <v-list-item-title class="text-caption">Exportar CSV</v-list-item-title>
               </v-list-item>
            </v-list>
         </v-menu>
      </div>
    </div>

    <div class="px-6 py-4 grid grid-cols-4 gap-4 flex-shrink-0" v-if="!loading && summaryKpis">
       <div class="glass-card pa-3 rounded-xl border-t-4 border-t-success d-flex flex-column justify-space-between hover-elevate">
          <div class="text-[10px] font-weight-bold text-white-50 text-uppercase mb-1">Receita Bruta</div>
          <div class="text-h6 font-weight-black text-white">{{ formatCurrency(summaryKpis.revenue) }}</div>
          <div class="text-[10px] text-success font-weight-bold mt-1 d-flex align-center">
             <v-icon size="10" class="mr-1">mdi-arrow-up</v-icon> 100%
          </div>
       </div>
       <div class="glass-card pa-3 rounded-xl border-t-4 border-t-warning d-flex flex-column justify-space-between hover-elevate">
          <div class="text-[10px] font-weight-bold text-white-50 text-uppercase mb-1">Custos Variáveis</div>
          <div class="text-h6 font-weight-black text-white">{{ formatCurrency(summaryKpis.costs) }}</div>
          <div class="text-[10px] text-warning font-weight-bold mt-1">
             {{ formatPercent(summaryKpis.costs, summaryKpis.revenue) }} da Receita
          </div>
       </div>
       <div class="glass-card pa-3 rounded-xl border-t-4 border-t-error d-flex flex-column justify-space-between hover-elevate">
          <div class="text-[10px] font-weight-bold text-white-50 text-uppercase mb-1">Despesas Fixas</div>
          <div class="text-h6 font-weight-black text-white">{{ formatCurrency(summaryKpis.expenses) }}</div>
          <div class="text-[10px] text-error font-weight-bold mt-1">
             {{ formatPercent(summaryKpis.expenses, summaryKpis.revenue) }} da Receita
          </div>
       </div>
       <div class="glass-card pa-3 rounded-xl border-t-4 d-flex flex-column justify-space-between hover-elevate"
            :class="summaryKpis.result >= 0 ? 'border-t-info bg-info-05' : 'border-t-error bg-error-05'">
          <div class="text-[10px] font-weight-bold text-white-50 text-uppercase mb-1">Resultado Líquido</div>
          <div class="text-h6 font-weight-black" :class="summaryKpis.result >= 0 ? 'text-info' : 'text-error'">
             {{ formatCurrency(summaryKpis.result) }}
          </div>
          <div class="text-[10px] font-weight-bold mt-1" :class="summaryKpis.result >= 0 ? 'text-info' : 'text-error'">
             Margem Líquida: {{ formatPercent(summaryKpis.result, summaryKpis.revenue) }}
          </div>
       </div>
    </div>

    <div class="flex-grow-1 overflow-hidden d-flex border-t border-white-05 position-relative">

       <div class="flex-grow-1 d-flex flex-column h-100" style="min-width: 500px;">

          <div class="px-6 py-2 d-flex justify-space-between align-center bg-white-02 border-b border-white-05">
             <div class="d-flex align-center gap-2">
                <v-icon size="small" color="white-50">mdi-file-tree</v-icon>
                <span class="text-[10px] font-weight-bold text-white-50 text-uppercase">Estrutura DRE</span>
             </div>
             <div class="d-flex align-center gap-2">
                <v-text-field v-model="search" density="compact" variant="plain" placeholder="Filtrar contas..." hide-details class="text-caption" style="width: 150px;"></v-text-field>
                <v-btn size="x-small" variant="text" color="white-50" @click="toggleAll(true)">Expandir</v-btn>
                <v-btn size="x-small" variant="text" color="white-50" @click="toggleAll(false)">Recolher</v-btn>
             </div>
          </div>

          <div class="grid-header px-6 py-2 border-b border-white-05 bg-black-20 d-flex text-[9px] font-weight-bold text-white-30 text-uppercase tracking-wider">
             <div style="flex: 2;">Conta Contábil</div>
             <div style="width: 80px;" class="text-right">Análise Vert.</div>
             <div style="width: 120px;" class="text-right">Saldo Período</div>
             <div style="width: 40px;"></div>
          </div>

          <div class="flex-grow-1 overflow-y-auto custom-scrollbar px-4 py-2">
             <div v-if="loading" class="d-flex flex-column align-center justify-center mt-20">
                <v-progress-circular indeterminate color="info" size="32" width="3"></v-progress-circular>
                <span class="text-caption text-white-50 mt-3">Consolidando balanço...</span>
             </div>

             <div v-else-if="reportTree.length === 0" class="text-center mt-20 text-caption text-white-30">
                Nenhum lançamento encontrado para este período.
             </div>

             <div v-else class="pb-10">
                <template v-for="node in reportTree" :key="node.id">
                   <div
                      class="dre-row d-flex align-center py-1 px-2 rounded mb-1 border border-transparent hover-highlight transition-all cursor-pointer group"
                      :class="{
                         'bg-white-05': node.is_synthetic && node.level === 0,
                         'bg-white-02': node.is_synthetic && node.level > 0,
                         'bg-primary-10 border-primary-20 shadow-glow-sm': selectedAccount?.id === node.id
                      }"
                      @click="selectAccount(node)"
                   >
                      <div style="flex: 2;" class="d-flex align-center overflow-hidden">
                         <div :style="{ width: (node.level * 24) + 'px' }" class="flex-shrink-0 position-relative h-100">
                            <div v-if="node.level > 0" class="tree-line-v"></div>
                            <div v-if="node.level > 0" class="tree-line-h"></div>
                         </div>

                         <v-btn
                            v-if="node.children.length"
                            icon size="x-small" density="compact" variant="text"
                            :color="node.expanded ? 'white' : 'white-30'"
                            class="mr-1 mt-n1 w-4 h-4"
                            @click.stop="node.expanded = !node.expanded"
                         >
                            <v-icon size="12">{{ node.expanded ? 'mdi-chevron-down' : 'mdi-chevron-right' }}</v-icon>
                         </v-btn>
                         <div v-else class="mr-5"></div>

                         <div class="d-flex flex-column text-truncate">
                            <div class="d-flex align-center">
                               <span class="font-mono text-[10px] font-weight-bold mr-2 text-white-30">{{ node.code }}</span>
                               <span class="text-[11px] text-white text-truncate" :class="{'font-weight-black text-uppercase': node.level === 0, 'font-weight-bold': node.is_synthetic, 'font-weight-regular': !node.is_synthetic}">
                                  {{ node.name }}
                               </span>
                            </div>
                         </div>
                      </div>

                      <div style="width: 80px;" class="text-right">
                         <span class="text-[9px] font-weight-medium text-white-50" v-if="summaryKpis.revenue > 0">
                            {{ formatPercent(node.balance, summaryKpis.revenue) }}
                         </span>
                      </div>

                      <div style="width: 120px;" class="text-right">
                         <span
                            class="font-mono text-[11px] font-weight-bold"
                            :class="node.balance >= 0 ? (node.nature === 'despesa' ? 'text-white' : 'text-success') : 'text-error'"
                         >
                            {{ formatCurrency(node.balance) }}
                         </span>
                      </div>

                      <div style="width: 40px;" class="text-center opacity-0 group-hover:opacity-100 transition-opacity">
                         <v-icon v-if="!node.is_synthetic" size="14" color="primary">mdi-text-box-search-outline</v-icon>
                      </div>
                   </div>
                </template>
             </div>
          </div>
       </div>

       <div class="d-flex flex-column h-100 bg-black-20 border-l border-white-10 transition-all shadow-xl z-10"
            :style="{ width: showDetails ? '500px' : '0px', opacity: showDetails ? 1 : 0 }">

          <div class="border-b border-white-10 px-5 py-4 bg-glass-header flex-shrink-0 d-flex justify-space-between align-start">
             <div>
                <div class="d-flex align-center gap-2 mb-1">
                   <v-chip size="x-small" color="primary" variant="flat" class="font-mono font-weight-bold">{{ selectedAccount?.code }}</v-chip>
                   <span class="text-[10px] font-weight-bold text-white-50 text-uppercase">Razão Analítico</span>
                </div>
                <div class="text-subtitle-2 font-weight-black text-white lh-1-2">{{ selectedAccount?.name }}</div>
                <div class="text-[10px] text-white-50 mt-1">Extrato de movimentações do período</div>
             </div>
             <v-btn icon size="small" variant="text" color="white-50" @click="selectedAccount = null">
                <v-icon>mdi-close</v-icon>
             </v-btn>
          </div>

          <div class="flex-grow-1 overflow-y-auto custom-scrollbar px-4 py-4 bg-black-20">
             <div v-if="loadingDetails" class="d-flex justify-center mt-10"><v-progress-circular indeterminate color="primary" size="24"></v-progress-circular></div>

             <div v-else-if="accountDetails.length === 0" class="d-flex flex-column align-center justify-center mt-10 opacity-50">
                <v-icon size="40" color="white-30">mdi-text-box-remove-outline</v-icon>
                <span class="text-caption text-white-30 mt-2">Sem lançamentos no período.</span>
             </div>

             <div v-else class="timeline-container">
                <div v-for="(entry, index) in accountDetails" :key="index" class="timeline-item position-relative pl-4 pb-4">
                   <div class="absolute-line bg-white-10"></div>
                   <div class="absolute-dot" :class="entry.debit > 0 ? 'bg-error' : 'bg-success'"></div>

                   <div class="glass-card pa-3 rounded-lg border border-white-05 bg-white-02 hover-highlight transition-all">
                      <div class="d-flex justify-space-between align-start mb-2">
                         <div class="d-flex flex-column">
                            <span class="text-[10px] font-weight-bold text-white-70">{{ formatDate(entry.transaction_date) }}</span>
                            <span class="text-[9px] font-mono text-primary cursor-pointer hover:underline" :title="entry.origin_id">#DOC-{{ entry.origin_id ? entry.origin_id.slice(0,6) : 'MAN' }}</span>
                         </div>
                         <div class="text-right">
                            <span class="text-[11px] font-mono font-weight-black" :class="entry.debit > 0 ? 'text-error' : 'text-success'">
                               {{ entry.debit > 0 ? '-' : '+' }} {{ formatNumber(entry.debit > 0 ? entry.debit : entry.credit) }}
                            </span>
                         </div>
                      </div>

                      <div class="text-caption font-weight-medium text-white mb-2 lh-1-4">
                         {{ entry.description }}
                      </div>

                      <div class="d-flex justify-space-between align-center border-t border-white-05 pt-2 mt-2">
                         <span class="text-[9px] text-white-30 font-weight-bold text-uppercase">Saldo Acumulado</span>
                         <span class="text-[10px] font-mono font-weight-bold text-white">{{ formatCurrency(entry.running_balance) }}</span>
                      </div>
                   </div>
                </div>
             </div>
          </div>

          <div class="bg-glass-header border-t border-white-10 px-5 py-3 flex-shrink-0">
             <div class="d-flex justify-space-between align-center">
                <span class="text-caption font-weight-bold text-white-50 text-uppercase">Saldo Final</span>
                <span class="text-h6 font-weight-black text-white">{{ formatCurrency(selectedAccount?.balance || 0) }}</span>
             </div>
          </div>
       </div>

    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, computed, watch } from 'vue'
import { supabase } from '@/api/supabase'
import { format, startOfMonth, endOfMonth, startOfYear, subMonths } from 'date-fns'
import jsPDF from 'jspdf'
import autoTable from 'jspdf-autotable'

const loading = ref(false)
const loadingDetails = ref(false)
const periodPreset = ref('this_month')
const filterStartDate = ref(format(startOfMonth(new Date()), 'yyyy-MM-dd'))
const filterEndDate = ref(format(endOfMonth(new Date()), 'yyyy-MM-dd'))
const search = ref('')

const rawReportData = ref<any[]>([])
const selectedAccount = ref<any>(null)
const accountDetails = ref<any[]>([])

const showDetails = computed(() => !!selectedAccount.value)

// --- WATCHERS DE FILTRO ---
watch(periodPreset, (val) => {
    const today = new Date()
    if (val === 'this_month') {
        filterStartDate.value = format(startOfMonth(today), 'yyyy-MM-dd')
        filterEndDate.value = format(endOfMonth(today), 'yyyy-MM-dd')
    } else if (val === 'last_month') {
        const last = subMonths(today, 1)
        filterStartDate.value = format(startOfMonth(last), 'yyyy-MM-dd')
        filterEndDate.value = format(endOfMonth(last), 'yyyy-MM-dd')
    } else if (val === 'year') {
        filterStartDate.value = format(startOfYear(today), 'yyyy-MM-dd')
        filterEndDate.value = format(endOfMonth(today), 'yyyy-MM-dd')
    }
    fetchReport()
})

// --- KPIs DO TOPO ---
const summaryKpis = computed(() => {
    // Calcula totais baseados nas contas Raiz (Nível 0)
    // Assumindo que a estrutura do banco tem naturezas definidas corretamente
    let revenue = 0
    let expenses = 0
    let costs = 0

    // Varre a lista bruta para somar (mais seguro que depender da árvore filtrada)
    rawReportData.value.forEach(acc => {
        // Pega apenas contas sintéticas de nível 1 ou 2 que representam os grandes grupos
        if (acc.nature === 'receita' && !acc.parent_id) revenue += Number(acc.balance)
        // Custos geralmente são despesas específicas, mas simplificando:
        if (acc.nature === 'despesa' && !acc.parent_id) expenses += Number(acc.balance)
    })

    // Ajuste simples: considerar Revenue - Expenses = Result
    // Num sistema real, identificaríamos CMV (Custos) separadamente via código da conta (ex: 3.x vs 4.x)
    const result = revenue - expenses

    return { revenue, expenses, costs: 0, result }
})

// --- LÓGICA DE ÁRVORE RECURSIVA ---
const reportTree = computed(() => {
    if (rawReportData.value.length === 0) return []

    const map = new Map()
    const roots: any[] = []

    // 1. Inicializa Mapa
    rawReportData.value.forEach(item => {
        map.set(item.id, {
            ...item,
            children: [],
            expanded: true,
            balance: Number(item.balance) || 0
        })
    })

    // 2. Constrói Hierarquia e Soma Sintéticos
    // Ordena por código para processar de baixo pra cima ou recursivamente
    // Função Recursiva de Soma
    const calculateBalance = (node: any) => {
        const children = rawReportData.value.filter(i => i.parent_id === node.id).map(i => map.get(i.id))
        if (children.length > 0) {
            let sum = 0
            children.forEach(child => sum += calculateBalance(child))
            // Se for sintética, o saldo é a soma dos filhos. Se analítica, mantém o do banco.
            if (node.is_synthetic) node.balance = sum
        }
        return node.balance
    }

    // Identifica Raízes e inicia cálculo
    rawReportData.value.forEach(item => {
        if (!item.parent_id) {
            const node = map.get(item.id)
            calculateBalance(node)
            roots.push(node)
        }
    })

    // 3. Flat List para v-for (com suporte a expand/collapse e busca)
    const flatList: any[] = []

    const flatten = (nodes: any[], level = 0) => {
        nodes.sort((a, b) => a.code.localeCompare(b.code, undefined, { numeric: true }))

        nodes.forEach(node => {
            // Filtro de busca
            if (search.value && !node.name.toLowerCase().includes(search.value.toLowerCase()) && !node.code.includes(search.value)) {
                // Se não der match, verifica se algum filho dá match (para manter o pai visível)
                // Implementação simplificada: se tem busca, mostra tudo que der match flat
                return
            }

            node.level = level
            flatList.push(node)

            if (node.expanded) {
                const children = rawReportData.value.filter(i => i.parent_id === node.id).map(i => map.get(i.id))
                if (children.length > 0) {
                    node.children = children
                    flatten(children, level + 1)
                } else {
                    node.children = []
                }
            }
        })
    }

    flatten(roots)
    return flatList
})

// --- ACTIONS ---
const fetchReport = async () => {
    loading.value = true
    selectedAccount.value = null
    try {
        const { data, error } = await supabase.rpc('cajuia_get_period_balance', {
            p_start_date: filterStartDate.value,
            p_end_date: filterEndDate.value
        })
        if (error) throw error
        rawReportData.value = data || []
    } catch (e) {
        console.error(e)
    } finally {
        loading.value = false
    }
}

const selectAccount = async (account: any) => {
    if (account.is_synthetic) {
        account.expanded = !account.expanded // Toggle expand
        return
    }

    selectedAccount.value = account
    loadingDetails.value = true
    accountDetails.value = []

    try {
        const { data, error } = await supabase
            .from('cajuia_journal_items')
            .select(`
                debit, credit, history, created_at,
                cajuia_journal_entries!inner (
                    transaction_date, description, origin_id, origin_type
                )
            `)
            .eq('account_id', account.id)
            .gte('cajuia_journal_entries.transaction_date', filterStartDate.value)
            .lte('cajuia_journal_entries.transaction_date', filterEndDate.value)
            .order('created_at', { ascending: true })

        if(error) throw error

        // Calcula saldo acumulado (Running Balance)
        let runningBalance = 0
        // Define fator de soma/subtração baseado na natureza
        const isDebitPositive = account.nature === 'ativo' || account.nature === 'despesa'

        accountDetails.value = data.map((i: any) => {
            const debit = Number(i.debit) || 0
            const credit = Number(i.credit) || 0

            if (isDebitPositive) runningBalance += (debit - credit)
            else runningBalance += (credit - debit)

            return {
                id: i.created_at,
                transaction_date: i.cajuia_journal_entries.transaction_date,
                description: i.cajuia_journal_entries.description,
                origin_id: i.cajuia_journal_entries.origin_id,
                debit,
                credit,
                running_balance: runningBalance
            }
        })

    } catch (e) {
        console.error(e)
    } finally {
        loadingDetails.value = false
    }
}

const toggleAll = (expand: boolean) => {
    // Atualiza estado de expansão na lista bruta para refletir no computed
    rawReportData.value.forEach(n => n.expanded = expand)
    // Força reatividade (hack simples)
    rawReportData.value = [...rawReportData.value]
}

const exportReport = (type: string) => {
    // Implementação simplificada de exportação
    alert(`Exportação ${type.toUpperCase()} em desenvolvimento.`)
}

// --- UTILS ---
const formatCurrency = (val: number) => new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(val)
const formatNumber = (val: number) => new Intl.NumberFormat('pt-BR', { minimumFractionDigits: 2 }).format(val)
const formatPercent = (val: number, total: number) => {
    if (!total || total === 0) return '0%'
    return ((val / total) * 100).toFixed(1) + '%'
}
const formatDate = (d: string) => format(new Date(d), 'dd/MM/yyyy')

onMounted(() => {
    fetchReport()
})
</script>

<style scoped lang="scss">
/* Layout */
.bg-glass-header { background: rgba(30, 30, 35, 0.95); backdrop-filter: blur(16px); }
.bg-glass-body-gradient { background: linear-gradient(180deg, #121212 0%, #1e1e24 100%); }
.bg-black-20 { background: rgba(0,0,0,0.3); }
.bg-info-10 { background: rgba(var(--v-theme-info), 0.15); }
.bg-white-05 { background: rgba(255,255,255,0.05); }
.bg-white-02 { background: rgba(255,255,255,0.02); }
.bg-primary-10 { background: rgba(var(--v-theme-primary), 0.15); }
.bg-info-05 { background: rgba(var(--v-theme-info), 0.05); }
.bg-error-05 { background: rgba(var(--v-theme-error), 0.05); }

.border-white-05 { border-color: rgba(255,255,255,0.05) !important; }
.border-white-10 { border-color: rgba(255,255,255,0.1) !important; }
.border-primary-20 { border-color: rgba(var(--v-theme-primary), 0.3) !important; }
.border-t-4 { border-top-width: 4px !important; }
.border-t-success { border-top-color: #00c853 !important; }
.border-t-warning { border-top-color: #ffca28 !important; }
.border-t-error { border-top-color: #ff5252 !important; }
.border-t-info { border-top-color: #00b0ff !important; }

/* Grid e Flex */
.grid { display: grid; }
.grid-cols-4 { grid-template-columns: repeat(4, 1fr); }
.gap-4 { gap: 16px; }

/* Inputs */
.glass-date-input {
    background: transparent; border: none; color: white; outline: none; width: 80px;
    &::-webkit-calendar-picker-indicator { filter: invert(1); cursor: pointer; opacity: 0.6; transform: scale(0.8); }
}

/* Árvore Visual */
.tree-line-v { position: absolute; left: 50%; top: -50%; bottom: 0; width: 1px; background: rgba(255, 255, 255, 0.1); }
.tree-line-h { position: absolute; left: 50%; top: 50%; width: 50%; height: 1px; background: rgba(255, 255, 255, 0.1); }

/* Timeline (Razão) */
.timeline-item { border-left: 1px dashed rgba(255,255,255,0.1); margin-left: 10px; }
.absolute-dot {
    position: absolute; left: -4px; top: 15px; width: 7px; height: 7px; border-radius: 50%;
    box-shadow: 0 0 5px rgba(0,0,0,0.5);
}

/* Cards & Listas */
.glass-card { background: rgba(255, 255, 255, 0.03); backdrop-filter: blur(5px); border: 1px solid rgba(255,255,255,0.05); }
.dre-row { transition: all 0.2s; }
.hover-highlight:hover { background: rgba(255,255,255,0.08); }
.hover-elevate:hover { transform: translateY(-2px); box-shadow: 0 5px 15px rgba(0,0,0,0.3); background: rgba(255,255,255,0.06); }

.custom-scrollbar::-webkit-scrollbar { width: 5px; }
.custom-scrollbar::-webkit-scrollbar-thumb { background: rgba(255, 255, 255, 0.2); border-radius: 3px; }

.lh-1 { line-height: 1; }
.lh-1-2 { line-height: 1.2; }
.lh-1-4 { line-height: 1.4; }
.h-20 { height: 20px; } .h-28 { height: 28px; } .w-4 { width: 16px; } .h-4 { height: 16px; }
.shadow-glow-sm { box-shadow: 0 0 10px rgba(var(--v-theme-primary), 0.2); }
.icon-pulse { animation: pulse 2s infinite; }
@keyframes pulse { 0% { opacity: 1; } 50% { opacity: 0.5; } 100% { opacity: 1; } }
.group:hover .opacity-0 { opacity: 1; }
</style>
