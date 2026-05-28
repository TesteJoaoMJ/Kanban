<template>
  <div class="d-flex flex-column h-100 bg-glass-body-gradient overflow-hidden">

    <div class="px-6 py-4 border-b border-white-10 d-flex justify-space-between align-center flex-shrink-0 bg-glass-header z-10 elevation-4">
      <div class="d-flex align-center gap-4">
        <div class="icon-box bg-error-10 rounded-xl d-flex align-center justify-center elevation-6 border border-white-10" style="width: 52px; height: 52px;">
           <v-icon color="error" size="28">mdi-arrow-up-bold-box-outline</v-icon>
        </div>
        <div>
          <div class="d-flex align-center gap-3 mb-1">
             <h2 class="text-h6 font-weight-black text-white lh-1">Contas a Pagar</h2>
             <v-chip size="x-small" color="error" variant="flat" class="font-weight-bold px-3 uppercase tracking-widest text-[9px]">
                Saídas
             </v-chip>
          </div>
          <div class="text-[11px] text-white-50 font-weight-medium d-flex align-center gap-3">
             <span class="d-flex align-center gap-1">
                <v-icon size="12" color="white-30">mdi-calendar-clock</v-icon>
                Competência: {{ getMonthName(currentMonth) }}
             </span>
             <v-divider vertical class="border-white-20 h-10"></v-divider>
             <span class="text-white-70">
                <strong class="text-white">{{ filteredList.length }}</strong> lançamentos ativos
             </span>
          </div>
        </div>
      </div>

      <div class="d-flex align-center gap-3">
         <div class="glass-toggle-container p-1 rounded-lg border border-white-10 bg-black-20">
            <v-btn-toggle v-model="statusFilter" density="compact" mandatory class="bg-transparent" color="error">
                <v-btn value="open" class="text-[10px] font-weight-bold px-4 h-28 text-none letter-spacing-05">
                   <v-icon start size="12">mdi-clock-outline</v-icon> A Pagar
                </v-btn>
                <v-btn value="paid" class="text-[10px] font-weight-bold px-4 h-28 text-none letter-spacing-05">
                   <v-icon start size="12">mdi-check-all</v-icon> Baixadas
                </v-btn>
                <v-btn value="all" class="text-[10px] font-weight-bold px-4 h-28 text-none letter-spacing-05">Todas</v-btn>
            </v-btn-toggle>
         </div>

         <v-btn color="error" size="small" prepend-icon="mdi-plus" class="shadow-glow-error font-weight-bold px-5 h-36 rounded-lg text-none tracking-wide" @click="openModal()">
            Nova Despesa
         </v-btn>
      </div>
    </div>

    <div class="px-6 py-4 grid grid-cols-4 gap-4 flex-shrink-0" v-if="!loading">
       <div class="glass-card pa-4 rounded-xl border-l-4 border-l-white-30 d-flex flex-column justify-space-between hover-elevate transition-all">
          <div class="d-flex justify-space-between align-start">
             <div class="text-[10px] font-weight-bold text-white-50 text-uppercase tracking-wider">A Pagar (Mês)</div>
             <v-icon color="white-30" size="16">mdi-calendar-month</v-icon>
          </div>
          <div class="text-h5 font-weight-black text-white mt-1">{{ formatCurrency(kpis.totalMonth) }}</div>
          <div class="text-[10px] text-white-30 mt-1">Fluxo previsto</div>
       </div>

       <div class="glass-card pa-4 rounded-xl border-l-4 border-l-success d-flex flex-column justify-space-between hover-elevate transition-all bg-success-05">
          <div class="d-flex justify-space-between align-start">
             <div class="text-[10px] font-weight-bold text-success text-uppercase tracking-wider">Pago Mês</div>
             <v-icon color="success" size="16">mdi-cash-check</v-icon>
          </div>
          <div class="text-h5 font-weight-black text-success mt-1">{{ formatCurrency(kpis.paidMonth) }}</div>
          <div class="text-[10px] text-success-50 mt-1">Saída confirmada</div>
       </div>

       <div class="glass-card pa-4 rounded-xl border-l-4 border-l-error d-flex flex-column justify-space-between hover-elevate transition-all bg-error-05">
          <div class="d-flex justify-space-between align-start">
             <div class="text-[10px] font-weight-bold text-error text-uppercase tracking-wider">Vencido / Hoje</div>
             <v-icon color="error" size="16">mdi-alert-circle-outline</v-icon>
          </div>
          <div class="text-h5 font-weight-black text-error mt-1">{{ formatCurrency(kpis.overdue) }}</div>
          <div class="text-[10px] text-error-50 mt-1">Atenção necessária</div>
       </div>

       <div class="glass-card pa-4 rounded-xl border-l-4 border-l-warning d-flex flex-column justify-space-between hover-elevate transition-all bg-warning-05">
          <div class="d-flex justify-space-between align-start">
             <div class="text-[10px] font-weight-bold text-warning text-uppercase tracking-wider">Total Aberto</div>
             <v-icon color="warning" size="16">mdi-scale-balance</v-icon>
          </div>
          <div class="text-h5 font-weight-black text-warning mt-1">{{ formatCurrency(kpis.totalOpen) }}</div>
          <div class="text-[10px] text-warning-50 mt-1">Passivo circulante</div>
       </div>
    </div>

    <div class="flex-grow-1 overflow-hidden d-flex flex-column border-t border-white-05 position-relative bg-black-20">

       <div class="px-6 py-3 d-flex justify-space-between align-center bg-glass-header border-b border-white-05">
          <div class="d-flex align-center gap-3 w-50">
             <div style="width: 250px;">
                <v-text-field
                   v-model="search"
                   density="compact"
                   variant="outlined"
                   placeholder="Buscar fornecedor, descrição..."
                   prepend-inner-icon="mdi-magnify"
                   hide-details
                   class="glass-input small-input"
                   bg-color="rgba(0,0,0,0.2)"
                ></v-text-field>
             </div>

             <div class="d-flex align-center gap-2 px-3 py-1 rounded bg-white-05 border border-white-05">
                <v-icon size="14" color="white-50">mdi-calendar-range</v-icon>
                <input type="date" v-model="filterDateStart" class="glass-date-input text-[10px] font-mono">
                <span class="text-[9px] text-white-30">a</span>
                <input type="date" v-model="filterDateEnd" class="glass-date-input text-[10px] font-mono">
             </div>
          </div>

          <div class="d-flex align-center gap-2">
             <span v-if="selectedIds.length > 0" class="text-[10px] font-weight-bold text-error mr-2 fade-transition">
                {{ selectedIds.length }} selecionados ({{ formatCurrency(selectedTotal) }})
             </span>
             <v-btn icon size="x-small" variant="text" color="white-50" title="Imprimir Relatório">
                <v-icon>mdi-printer-outline</v-icon>
             </v-btn>
          </div>
       </div>

       <div class="flex-grow-1 overflow-y-auto custom-scrollbar px-6 py-4">
          <div class="grid-header px-4 py-2 mb-2 d-flex align-center text-[9px] font-weight-bold text-white-30 text-uppercase tracking-wider border-b border-white-05">
             <div style="width: 40px;" class="text-center">
                <v-checkbox-btn v-model="selectAll" density="compact" color="white-50"></v-checkbox-btn>
             </div>
             <div style="width: 100px;">Vencimento</div>
             <div style="flex: 2;">Fornecedor / Descrição</div>
             <div style="flex: 1;">Categoria</div>
             <div style="width: 140px;" class="text-right">Valor</div>
             <div style="width: 110px;" class="text-center">Status</div>
             <div style="width: 140px;" class="text-center">Ações</div>
          </div>

          <div v-if="loading" class="d-flex justify-center mt-20"><v-progress-circular indeterminate color="error" size="32" width="3"></v-progress-circular></div>

          <div v-else-if="filteredList.length === 0" class="d-flex flex-column align-center justify-center mt-20 opacity-50">
             <v-icon size="48" color="white-30" class="mb-2">mdi-cash-remove</v-icon>
             <span class="text-caption text-white-30">Nenhum lançamento encontrado.</span>
          </div>

          <template v-else>
             <div v-for="item in filteredList" :key="item.id"
                  class="payable-row glass-card pa-0 mb-2 rounded-lg border border-white-05 d-flex align-center hover-highlight transition-all position-relative overflow-hidden"
                  :class="getRowClass(item)"
             >
                <div class="absolute-left-bar" :class="getBarColor(item)"></div>

                <div style="width: 40px;" class="text-center py-3 pl-2">
                   <v-checkbox-btn v-model="selectedIds" :value="item.id" density="compact" color="error"></v-checkbox-btn>
                </div>

                <div style="width: 100px;" class="py-3 d-flex flex-column justify-center">
                   <span class="text-[11px] font-mono font-weight-bold" :class="getDateColor(item)">{{ formatDate(item.due_date) }}</span>
                   <span class="text-[9px] text-white-30 mt-0.5">{{ getRelativeDay(item.due_date) }}</span>
                </div>

                <div style="flex: 2;" class="py-3 pr-4 d-flex flex-column justify-center overflow-hidden">
                   <div class="d-flex align-center gap-2">
                      <span class="text-[11px] font-weight-bold text-white text-truncate">{{ item.supplier_name || 'Fornecedor Diverso' }}</span>
                      <v-icon v-if="item.notes" size="10" color="white-30" title="Possui notas">mdi-note-text-outline</v-icon>
                   </div>
                   <div class="d-flex align-center gap-1 mt-1 text-[10px] text-white-50">
                      <v-icon size="10">mdi-file-document-outline</v-icon>
                      <span class="text-truncate">{{ item.description }}</span>
                   </div>
                </div>

                <div style="flex: 1;" class="py-3 d-flex align-center">
                   <v-chip size="x-small" color="white-10" variant="flat" class="text-[9px] font-weight-medium text-white-70 px-2 h-20 border border-white-05">
                      <v-icon start size="10" class="mr-1">mdi-tag-outline</v-icon>
                      {{ item.cajuia_expense_categories?.name || 'Geral' }}
                   </v-chip>
                </div>

                <div style="width: 140px;" class="py-3 pr-4 text-right d-flex flex-column justify-center">
                   <span class="text-[12px] font-mono font-weight-black text-white tracking-tight">{{ formatCurrency(item.amount) }}</span>
                   <span v-if="item.status === 'PAID'" class="text-[9px] text-white-30">
                      Pago: {{ formatCurrency(item.amount_paid) }}
                   </span>
                </div>

                <div style="width: 110px;" class="py-3 text-center d-flex align-center justify-center">
                   <v-chip size="x-small" :color="getStatusColor(item)" variant="tonal" class="font-weight-bold h-20 px-2 uppercase text-[9px] tracking-wide border-none">
                      <v-icon start size="10" v-if="item.status === 'PAID'">mdi-check-all</v-icon>
                      {{ getStatusLabel(item) }}
                   </v-chip>
                </div>

                <div style="width: 140px;" class="py-3 pr-2 d-flex justify-center align-center gap-1 opacity-80 hover:opacity-100">
                   <template v-if="item.status !== 'PAID' && item.status !== 'CANCELLED'">
                      <v-tooltip text="Confirmar Pagamento" location="top">
                         <template v-slot:activator="{ props }">
                            <v-btn v-bind="props" icon size="x-small" variant="flat" color="error" class="rounded shadow-glow-sm w-6 h-6" @click="openSettleModal(item)">
                               <v-icon size="14">mdi-cash-check</v-icon>
                            </v-btn>
                         </template>
                      </v-tooltip>
                      <v-tooltip text="Editar" location="top">
                         <template v-slot:activator="{ props }">
                            <v-btn v-bind="props" icon size="x-small" variant="text" color="white-50" class="w-6 h-6" @click="editItem(item)">
                               <v-icon size="14">mdi-pencil</v-icon>
                            </v-btn>
                         </template>
                      </v-tooltip>
                   </template>

                   <v-menu location="bottom end">
                      <template v-slot:activator="{ props }">
                         <v-btn v-bind="props" icon size="x-small" variant="text" color="white-30" class="w-6 h-6">
                            <v-icon size="14">mdi-dots-vertical</v-icon>
                         </v-btn>
                      </template>
                      <v-list density="compact" class="bg-glass-card border-white-10 rounded-lg pa-1 width-150">
                         <v-list-item v-if="item.status === 'PAID'" @click="undoPayment(item)" class="rounded hover-bg-white-05 mb-1" density="compact">
                            <template v-slot:prepend><v-icon size="small" color="warning">mdi-undo</v-icon></template>
                            <v-list-item-title class="text-[10px]">Estornar Baixa</v-list-item-title>
                         </v-list-item>
                         <v-list-item @click="deleteItem(item)" class="text-error rounded hover-bg-white-05" density="compact">
                            <template v-slot:prepend><v-icon size="small">mdi-delete-outline</v-icon></template>
                            <v-list-item-title class="text-[10px]">Excluir Lançamento</v-list-item-title>
                         </v-list-item>
                      </v-list>
                   </v-menu>
                </div>
             </div>
          </template>
       </div>
    </div>

    <v-dialog v-model="showSettleModalState" max-width="450px" content-class="glass-modal">
       <v-card class="bg-glass-card border-white-10">
          <div class="pa-4 border-b border-white-10 bg-glass-header d-flex justify-space-between align-center">
             <div class="d-flex align-center gap-2">
                <v-icon color="error" size="small">mdi-cash-minus</v-icon>
                <span class="text-subtitle-2 font-weight-bold text-white">Baixa de Pagamento</span>
             </div>
             <v-btn icon variant="text" size="small" color="white-50" @click="showSettleModalState = false"><v-icon>mdi-close</v-icon></v-btn>
          </div>

          <div class="pa-5">
             <div class="glass-well pa-3 rounded-lg mb-5 border border-white-05 bg-white-02">
                <div class="d-flex justify-space-between align-start mb-1">
                   <span class="text-[10px] text-white-50 font-weight-bold text-uppercase">Fornecedor</span>
                   <span class="text-[10px] text-white-50 font-weight-bold text-uppercase">Vencimento</span>
                </div>
                <div class="d-flex justify-space-between align-center">
                   <span class="text-body-2 font-weight-bold text-white text-truncate mr-2">{{ selectedItem?.supplier_name || 'Diverso' }}</span>
                   <span class="text-caption font-mono" :class="isOverdue(selectedItem) ? 'text-error' : 'text-white'">{{ formatDate(selectedItem?.due_date) }}</span>
                </div>
                <div class="text-h5 font-weight-black text-error mt-2 text-right">{{ formatCurrency(selectedItem?.amount) }}</div>
             </div>

             <div class="d-flex flex-column gap-3">
                <v-select
                   v-model="paymentAccount"
                   :items="bankAccounts"
                   item-title="name"
                   item-value="id"
                   label="Conta de Saída (Banco/Caixa)"
                   placeholder="De onde saiu o dinheiro?"
                   variant="outlined" density="compact" class="glass-input"
                   return-object
                   hide-details
                   menu-icon="mdi-chevron-down"
                >
                   <template v-slot:prepend-inner><v-icon size="small" color="white-50">mdi-bank</v-icon></template>
                </v-select>

                <div class="d-flex gap-3">
                   <v-text-field
                      v-model="paymentDate"
                      type="date"
                      label="Data Pagamento"
                      variant="outlined" density="compact" class="glass-input w-50"
                      hide-details
                   ></v-text-field>
                   <v-text-field
                      v-model.number="interestAmount"
                      label="Juros/Multa"
                      type="number" step="0.01" min="0"
                      variant="outlined" density="compact" class="glass-input w-50 text-error"
                      hide-details prefix="R$"
                   ></v-text-field>
                </div>
                 <div class="d-flex gap-3">
                   <v-text-field
                      v-model="paymentDocument"
                      label="Documento (Obs)"
                      variant="outlined" density="compact" class="glass-input w-50"
                      hide-details
                   ></v-text-field>
                   <v-text-field
                      v-model.number="discountAmount"
                      label="Desconto"
                      type="number" step="0.01" min="0"
                      variant="outlined" density="compact" class="glass-input w-50 text-success"
                      hide-details prefix="R$"
                   ></v-text-field>
                </div>

                <div class="glass-card pa-3 rounded border border-white-10 bg-black-20 mt-1">
                   <div class="d-flex justify-space-between text-[10px] text-white-50 mb-1">
                      <span>Valor Original</span>
                      <span>{{ formatCurrency(selectedItem?.amount) }}</span>
                   </div>
                   <div class="d-flex justify-space-between align-center">
                      <span class="text-caption font-weight-bold text-white text-uppercase">Valor Pago (Saída)</span>
                      <span class="text-h6 font-mono font-weight-black text-white">{{ formatCurrency(calculatedTotalPaid) }}</span>
                   </div>
                </div>
             </div>
          </div>

          <div class="pa-4 border-t border-white-10 bg-glass-footer d-flex justify-end gap-2">
             <v-btn variant="text" color="white-50" class="text-none" @click="showSettleModalState = false">Cancelar</v-btn>
             <v-btn color="error" variant="flat" class="font-weight-bold shadow-glow-error text-none px-6" @click="confirmPayment" :loading="processing">
                <v-icon start size="16">mdi-check</v-icon> Confirmar
             </v-btn>
          </div>
       </v-card>
    </v-dialog>

    <CajuiaExpenseModal v-model="showCreateModal" @saved="fetchData" />

  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, computed, watch } from 'vue'
import { supabase } from '@/api/supabase'
import { format, isBefore, isToday, parseISO, startOfMonth, endOfMonth } from 'date-fns'
import { useAppStore } from '@/stores/app'
import CajuiaExpenseModal from '@/components/cajuia/CajuiaExpenseModal.vue'

const appStore = useAppStore()
const loading = ref(false)
const processing = ref(false)
const list = ref<any[]>([])
const bankAccounts = ref<any[]>([])
const search = ref('')
const statusFilter = ref('open')
const filterDateStart = ref(format(startOfMonth(new Date()), 'yyyy-MM-dd'))
const filterDateEnd = ref(format(endOfMonth(new Date()), 'yyyy-MM-dd'))
const currentMonth = ref(new Date().getMonth())

// Seleção
const selectedIds = ref<string[]>([])
const selectAll = computed({
    get: () => filteredList.value.length > 0 && selectedIds.value.length === filteredList.value.length,
    set: (val) => { selectedIds.value = val ? filteredList.value.map(i => i.id) : [] }
})
const selectedTotal = computed(() => {
    return list.value.filter(i => selectedIds.value.includes(i.id)).reduce((acc, i) => acc + Number(i.amount), 0)
})

// Modais
const showCreateModal = ref(false)
const showSettleModalState = ref(false)
const selectedItem = ref<any>(null)
const paymentAccount = ref(null)
const paymentDate = ref(format(new Date(), 'yyyy-MM-dd'))
const paymentDocument = ref('')
const interestAmount = ref(0)
const discountAmount = ref(0)

const calculatedTotalPaid = computed(() => {
    const original = Number(selectedItem.value?.amount) || 0
    return Math.max(0, original + interestAmount.value - discountAmount.value)
})

// --- KPIS ---
const kpis = computed(() => {
    const today = new Date()
    const monthData = list.value.filter(i => new Date(i.due_date).getMonth() === currentMonth.value)

    return {
        totalMonth: monthData.reduce((acc, i) => acc + Number(i.amount), 0),
        paidMonth: monthData.filter(i => i.status === 'PAID').reduce((acc, i) => acc + (Number(i.amount_paid) || Number(i.amount)), 0),
        overdue: list.value.filter(i => isOverdue(i)).reduce((acc, i) => acc + Number(i.amount), 0),
        totalOpen: list.value.filter(i => i.status !== 'PAID' && i.status !== 'CANCELLED').reduce((acc, i) => acc + Number(i.amount), 0)
    }
})

const filteredList = computed(() => {
    let items = list.value
    if (statusFilter.value === 'open') items = items.filter(i => i.status !== 'PAID' && i.status !== 'CANCELLED')
    if (statusFilter.value === 'paid') items = items.filter(i => i.status === 'PAID')

    items = items.filter(i => i.due_date >= filterDateStart.value && i.due_date <= filterDateEnd.value)

    if (search.value) {
        const q = search.value.toLowerCase()
        items = items.filter(i => i.description?.toLowerCase().includes(q) || i.supplier_name?.toLowerCase().includes(q))
    }

    return items.sort((a, b) => new Date(a.due_date).getTime() - new Date(b.due_date).getTime())
})

// --- ACTIONS ---
const fetchData = async () => {
    loading.value = true
    try {
        const { data, error } = await supabase
            .from('cajuia_payables')
            .select('*, cajuia_expense_categories(name)')
            .order('due_date', { ascending: true })
        if (error) throw error
        list.value = data || []

        const { data: accs } = await supabase.from('cajuia_accounts').select('*').eq('nature', 'ativo').eq('is_synthetic', false)
        bankAccounts.value = accs || []
    } catch (e) { console.error(e) } finally { loading.value = false }
}

const openModal = () => { showCreateModal.value = true }

const openSettleModal = (item: any) => {
    selectedItem.value = item
    interestAmount.value = 0
    discountAmount.value = 0
    paymentDocument.value = ''
    paymentDate.value = format(new Date(), 'yyyy-MM-dd')
    showSettleModalState.value = true
}

const confirmPayment = async () => {
    if (!paymentAccount.value) { appStore.showSnackbar('Selecione a conta de saída.', 'warning'); return }
    processing.value = true
    try {
        await supabase.from('cajuia_payables').update({
            status: 'PAID',
            payment_date: paymentDate.value,
            bank_account_id: paymentAccount.value.id,
            amount_paid: calculatedTotalPaid.value,
            notes: paymentDocument.value ? `Doc: ${paymentDocument.value}` : null
        }).eq('id', selectedItem.value.id)

        showSettleModalState.value = false
        fetchData()
        appStore.showSnackbar('Pagamento registrado!', 'success')
    } catch (e) {
        appStore.showSnackbar('Erro ao processar.', 'error')
    } finally {
        processing.value = false
    }
}

const deleteItem = async (item: any) => {
    if(!confirm('Tem certeza? Essa ação é irreversível.')) return
    await supabase.from('cajuia_payables').delete().eq('id', item.id)
    fetchData()
}

const undoPayment = async (item: any) => {
    if(!confirm('Estornar este pagamento? O status voltará para Aberto.')) return
    await supabase.from('cajuia_payables').update({
        status: 'PENDING', payment_date: null, amount_paid: null, bank_account_id: null
    }).eq('id', item.id)
    fetchData()
}

const editItem = (item: any) => {
   // Para simplificar, poderíamos reutilizar o modal de criação passando props
   // ou abrir um modal específico. Deixo placeholder funcional
   appStore.showSnackbar('Funcionalidade de edição rápida em desenvolvimento', 'info')
}

// --- UTILS ---
const isOverdue = (i: any) => i.status !== 'PAID' && i.status !== 'CANCELLED' && isBefore(parseISO(i.due_date), new Date()) && !isToday(parseISO(i.due_date))
const getStatusColor = (i: any) => {
    if (i.status === 'PAID') return 'success'
    if (i.status === 'CANCELLED') return 'grey'
    if (isOverdue(i)) return 'error'
    if (isToday(parseISO(i.due_date))) return 'warning'
    return 'info'
}
const getStatusLabel = (i: any) => i.status === 'PAID' ? 'PAGO' : (isOverdue(i) ? 'ATRASADO' : (i.status === 'CANCELLED' ? 'CANCELADO' : 'ABERTO'))
const getRowClass = (i: any) => {
    if (i.status === 'PAID' || i.status === 'CANCELLED') return 'opacity-60 bg-white-02'
    return 'bg-white-05'
}
const getBarColor = (i: any) => {
    if (i.status === 'PAID') return 'bg-success'
    if (isOverdue(i)) return 'bg-error'
    if (isToday(parseISO(i.due_date))) return 'bg-warning'
    return 'bg-white-20'
}
const getDateColor = (i: any) => isOverdue(i) ? 'text-error' : (isToday(parseISO(i.due_date)) ? 'text-warning' : 'text-white')
const getRelativeDay = (d: string) => isToday(parseISO(d)) ? 'VENCE HOJE' : ''
const getMonthName = (m: number) => ['Janeiro','Fevereiro','Março','Abril','Maio','Junho','Julho','Agosto','Setembro','Outubro','Novembro','Dezembro'][m]

const formatCurrency = (v: number) => new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(v)
const formatDate = (d: string) => d ? format(parseISO(d), 'dd/MM/yyyy') : '-'

onMounted(() => fetchData())
watch([filterDateStart, filterDateEnd], fetchData)
</script>

<style scoped lang="scss">
/* Glass Core */
.bg-glass-header { background: rgba(30, 30, 35, 0.95); backdrop-filter: blur(20px); }
.bg-glass-body-gradient { background: linear-gradient(135deg, #0f0f13 0%, #1a1a20 100%); }
.glass-card { background: rgba(255, 255, 255, 0.03); backdrop-filter: blur(10px); }
.glass-well { background: rgba(0,0,0,0.3); }
.bg-black-20 { background: rgba(0,0,0,0.25); }
.bg-white-02 { background: rgba(255,255,255,0.02); }
.bg-white-05 { background: rgba(255,255,255,0.05); }
.bg-white-20 { background: rgba(255,255,255,0.2); }

.bg-error-10 { background: rgba(255, 82, 82, 0.15); }
.bg-error-05 { background: rgba(255, 82, 82, 0.05); }
.bg-warning-05 { background: rgba(255, 193, 7, 0.05); }
.bg-success-05 { background: rgba(0, 200, 83, 0.05); }

.border-white-05 { border-color: rgba(255,255,255,0.05) !important; }
.border-white-10 { border-color: rgba(255,255,255,0.1) !important; }
.border-l-4 { border-left-width: 4px !important; border-left-style: solid; }
.border-l-error { border-left-color: #ff5252 !important; }
.border-l-warning { border-left-color: #ffca28 !important; }
.border-l-success { border-left-color: #00c853 !important; }
.border-l-white-30 { border-left-color: rgba(255,255,255,0.3) !important; }

/* Visuals */
.absolute-left-bar { position: absolute; left: 0; top: 0; bottom: 0; width: 4px; }
.hover-elevate:hover { transform: translateY(-2px); box-shadow: 0 8px 20px rgba(0,0,0,0.3); border-color: rgba(255,255,255,0.15); }
.hover-highlight:hover { background: rgba(255,255,255,0.06); border-color: rgba(255,255,255,0.15); }
.shadow-glow-error { box-shadow: 0 0 20px rgba(255, 82, 82, 0.4); }

/* Inputs */
.glass-input :deep(.v-field) { border-radius: 8px !important; border: 1px solid rgba(255,255,255,0.1); color: white; font-size: 0.85rem; }
.glass-input.small-input :deep(.v-field__input) { min-height: 32px; padding-top: 4px; padding-bottom: 4px; }
.glass-date-input { background: transparent; border: none; color: white; width: 80px; outline: none; filter: invert(1); cursor: pointer; }

/* Utils */
.grid { display: grid; } .grid-cols-4 { grid-template-columns: repeat(4, 1fr); } .gap-4 { gap: 16px; }
.lh-1 { line-height: 1; } .h-28 { height: 28px; } .h-36 { height: 36px; } .w-6 { width: 24px; } .h-6 { height: 24px; }
.tracking-widest { letter-spacing: 0.1em; } .tracking-wider { letter-spacing: 0.05em; }
.custom-scrollbar::-webkit-scrollbar { width: 5px; } .custom-scrollbar::-webkit-scrollbar-thumb { background: rgba(255, 255, 255, 0.2); border-radius: 3px; }
</style>
