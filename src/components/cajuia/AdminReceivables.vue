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
        <div class="header-bar px-6 py-3 d-flex align-center justify-space-between flex-shrink-0" :class="themeStore.currentMode === 'light' ? 'bg-white border-b border-grey-lighten-2 shadow-sm' : 'bg-glass-header border-bottom-white-05'">
          <div class="d-flex align-center gap-6">
              <div class="d-flex align-center gap-3">
                 <div class="icon-box-xs rounded elevation-1" :class="themeStore.currentMode === 'light' ? 'bg-green-darken-1 text-white' : 'bg-success-transparent text-success'"><v-icon size="16">mdi-finance</v-icon></div>
                 <h1 class="text-subtitle-2 font-weight-black tracking-tight uppercase" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">Contas a Receber</h1>
              </div>
              <v-divider vertical class="h-16" :class="themeStore.currentMode === 'light' ? 'border-grey-lighten-1' : 'border-white-10'"></v-divider>
              <div class="d-flex align-center gap-1">
                  <v-btn icon size="x-small" density="compact" variant="text" :color="themeStore.currentMode === 'light' ? 'grey-darken-2' : 'white-50'" @click="changeMonth(-1)"><v-icon>mdi-chevron-left</v-icon></v-btn>
                  <span class="text-caption font-weight-black uppercase w-100px text-center" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-3' : 'text-white'">{{ currentMonthLabel }}</span>
                  <v-btn icon size="x-small" density="compact" variant="text" :color="themeStore.currentMode === 'light' ? 'grey-darken-2' : 'white-50'" @click="changeMonth(1)"><v-icon>mdi-chevron-right</v-icon></v-btn>
                  <v-btn size="x-small" variant="tonal" color="primary" class="font-weight-bold ml-1 h-24 px-2" @click="goToCurrentMonth">HOJE</v-btn>
              </div>
          </div>
          <div class="d-flex align-center gap-3">
            <div class="px-3 py-0.5 d-flex align-center gap-2 rounded-pill border" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-4 border-grey-lighten-2 text-grey-darken-2' : 'glass-pill border-white-05 text-white-70'">
                <v-icon size="12">mdi-calendar</v-icon> <span class="text-[10px] font-weight-bold font-mono">{{ currentDate }}</span>
            </div>
            <v-btn color="primary" variant="flat" size="small" class="rounded px-3 text-[10px] font-weight-bold" prepend-icon="mdi-plus" height="28" @click="openNewReceivableModal">Novo Lançamento</v-btn>
          </div>
        </div>

        <div class="px-6 py-3 flex-shrink-0">
          <v-row dense>
             <v-col cols="12" sm="6" md="3" v-for="(kpi, idx) in kpiList" :key="idx">
                <v-card class="kpi-card bg-gradient-custom hover-elevate" :class="kpi.gradient" v-ripple>
                  <div class="kpi-bg-icon"><v-icon>{{ kpi.icon }}</v-icon></div>
                  <div class="d-flex flex-column position-relative z-10">
                    <span class="kpi-label">{{ kpi.label }}</span>
                    <div class="kpi-number-group"><span class="text-subtitle-1 font-weight-black mr-1 opacity-70">R$</span><span class="kpi-value">{{ formatCurrencyValue(kpi.value) }}</span></div>
                    <div class="kpi-footer">{{ kpi.footer }}</div>
                  </div>
                </v-card>
             </v-col>
          </v-row>
        </div>

        <div class="px-6 mb-3 flex-shrink-0">
            <div class="d-flex align-center justify-space-between rounded-lg px-2 py-1" :class="themeStore.currentMode === 'light' ? 'bg-white border-thin border-grey-lighten-2' : 'glass-control-bar border-white-05'" style="height: 44px;">
                <div class="d-flex align-center gap-2 flex-grow-1 mr-4">
                     <div class="d-flex align-center gap-2 rounded px-3 transition-all" style="height: 32px; width: 300px;" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 border border-grey-lighten-2 focus-within:border-primary' : 'bg-white-05 border-transparent focus-within:bg-white-10'">
                        <v-icon size="14" :color="themeStore.currentMode === 'light' ? 'grey' : 'white-50'">mdi-magnify</v-icon>
                        <input v-model="search" type="text" placeholder="Pesquisar..." class="clean-input flex-grow-1 text-[11px] font-weight-medium" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-3' : 'text-white'"/>
                    </div>
                    <v-divider vertical class="h-20 my-auto mx-1" :class="themeStore.currentMode === 'light' ? 'border-grey-lighten-2' : 'border-white-10'"></v-divider>
                    <v-select v-model="filters.status" :items="statusOptions" multiple variant="plain" density="compact" hide-details class="status-select-tiny" :menu-props="{ contentClass: 'status-menu-popover' }">
                        <template v-slot:selection>
                            <div class="d-flex align-center gap-1 cursor-pointer opacity-hover">
                                <v-icon size="14" :color="filters.status.length ? 'primary' : (themeStore.currentMode === 'light' ? 'grey-darken-1' : 'white-70')">mdi-filter-variant</v-icon>
                                <span class="text-[11px] font-weight-bold" :class="filters.status.length ? 'text-primary' : (themeStore.currentMode === 'light' ? 'text-grey-darken-2' : 'text-white-70')">{{ filters.status.length > 0 ? filters.status.length + ' selecionados' : 'Filtrar Situação' }}</span>
                                <v-icon size="10" class="ml-1 opacity-50">mdi-chevron-down</v-icon>
                            </div>
                        </template>
                    </v-select>
                </div>
                <div class="d-flex align-center gap-2">
                    <span class="text-[10px] font-weight-bold opacity-50 uppercase mr-1 tracking-wide">Exportar:</span>
                    <v-btn icon size="x-small" width="28" height="28" variant="flat" color="blue-grey-lighten-4" class="rounded-sm" @click="openImportModal">
                        <v-icon color="blue-grey-darken-2" size="16">mdi-upload</v-icon>
                        <v-tooltip activator="parent" location="top" text="Importar (Excel/CSV)" content-class="custom-tooltip-white" />
                    </v-btn>
                    <v-btn icon size="x-small" width="28" height="28" variant="flat" color="#217346" class="rounded-sm" @click="exportExcel">
                        <v-icon color="white" size="14">mdi-microsoft-excel</v-icon>
                        <v-tooltip activator="parent" location="top" text="Excel" content-class="custom-tooltip-white" />
                    </v-btn>
                </div>
            </div>
        </div>

        <div class="flex-grow-1 px-6 pb-4 overflow-hidden">
           <v-card class="fill-height overflow-hidden d-flex flex-column rounded-lg border-thin" :class="themeStore.currentMode === 'light' ? 'bg-white shadow-sm' : 'glass-card border-white-05'" :elevation="0">
             <div class="d-flex px-0 py-2 text-[10px] uppercase tracking-wide font-weight-black border-b" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-4 text-grey-darken-1 border-grey-lighten-2' : 'bg-glass-header text-white-50 border-white-05'">
                 <div style="width: 8%" class="text-center">Nº Ref.</div>
                 <div style="width: 8%" class="text-center">Parcela</div>
                 <div style="width: 25%" class="text-left pl-4">Destinado à / Descrição</div>
                 <div style="width: 12%" class="text-center">Vencimento</div>
                 <div style="width: 12%" class="text-center">Valor</div>
                 <div style="width: 15%" class="text-center">Situação</div>
                 <div style="width: 20%" class="text-center">Ações</div>
             </div>

             <div class="flex-grow-1 overflow-y-auto custom-scroll">
                 <div v-if="loading" class="d-flex flex-column justify-center align-center h-100"><v-progress-circular indeterminate color="primary" size="32" width="3"></v-progress-circular></div>
                 <div v-else-if="monthlyReceivables.length === 0" class="d-flex flex-column justify-center align-center h-100 opacity-50">
                     <v-icon size="48" class="mb-2" :color="themeStore.currentMode === 'light' ? 'grey-lighten-2' : 'white-10'">mdi-calendar-blank-outline</v-icon>
                     <span class="text-[11px] font-weight-bold uppercase" :class="themeStore.currentMode === 'light' ? 'text-grey' : 'text-white-50'">Nenhum recebimento encontrado</span>
                 </div>
                 <div v-else v-for="(item, index) in monthlyReceivables" :key="item.id" class="receivable-row d-flex align-center px-0 transition-all group border-b" :class="[themeStore.currentMode === 'light' ? (index % 2 === 0 ? 'bg-white' : 'bg-grey-lighten-5') : 'border-white-05 hover-bg-glass', themeStore.currentMode === 'light' ? 'border-grey-lighten-1' : '']" style="height: 42px;">
                     <div style="width: 8%" class="d-flex justify-center align-center">
                         <span class="text-[11px] font-mono font-weight-bold opacity-70" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-3' : 'text-white'">{{ getOrderNumber(item) }}</span>
                     </div>
                     <div style="width: 8%" class="d-flex justify-center align-center">
                        <v-chip size="x-small" variant="tonal" class="px-1 h-16 text-[9px] font-weight-black font-mono" :color="getInstallmentInfo(item).color">{{ getInstallmentInfo(item).text }}</v-chip>
                     </div>
                     <div style="width: 25%" class="d-flex align-center px-4 overflow-hidden">
                         <div class="d-flex flex-column justify-center w-100" style="line-height: 1.1;">
                            <span class="text-[11px] font-weight-black text-truncate" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">
                                {{ item.entity_name || item.customer_name || 'Cliente Diverso' }}
                            </span>
                            <span class="text-[10px] text-truncate opacity-80" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-2' : 'text-white-70'">
                                {{ item.description }}
                            </span>
                            <div class="d-flex gap-2 mt-0.5">
                                <span v-if="item.cost_center" class="text-[9px] text-grey d-flex align-center gap-1"><v-icon size="9">mdi-domain</v-icon> {{ item.cost_center }}</span>
                            </div>
                         </div>
                     </div>
                     <div style="width: 12%" class="d-flex justify-center align-center">
                         <span class="text-[11px] font-mono" :class="isOverdue(item) ? 'text-error font-weight-bold' : (themeStore.currentMode === 'light' ? 'text-grey-darken-3' : 'text-white-70')">{{ formatDateSimple(item.due_date) }}</span>
                     </div>
                     <div style="width: 12%" class="d-flex justify-center align-center">
                         <span class="text-[11px] font-mono font-weight-bold" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">{{ formatCurrency(item.value) }}</span>
                     </div>
                     <div style="width: 15%" class="d-flex justify-center align-center">
                         <v-chip size="x-small" :color="getStatusColor(item)" variant="flat" class="font-weight-bold text-uppercase justify-center text-white elevation-0 text-[9px] h-18 px-2 w-75 rounded-pill">{{ getStatusLabel(item) }}</v-chip>
                     </div>
                     <div style="width: 20%" class="d-flex justify-center align-center gap-2">
                         <button class="action-btn info-btn" @click="openBillingModal(item)"><v-icon size="14">mdi-pencil</v-icon><v-tooltip activator="parent" location="top" text="Editar" content-class="custom-tooltip-white" /></button>
                         <button class="action-btn success-btn" @click="updateStatus(item, 'pago')" v-if="item.status !== 'pago'"><v-icon size="14">mdi-check</v-icon><v-tooltip activator="parent" location="top" text="Baixar" content-class="custom-tooltip-white" /></button>
                         <button class="action-btn error-btn" @click="cancelReceivable(item)"><v-icon size="14">mdi-trash-can-outline</v-icon><v-tooltip activator="parent" location="top" text="Excluir" content-class="custom-tooltip-white" /></button>
                     </div>
                 </div>
             </div>
           </v-card>
        </div>
    </div>

    <v-dialog v-model="showBillingModal" max-width="700">
        <v-card class="rounded-xl border-thin shadow-card" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-surface-dark'">
            <div class="pa-5 border-b d-flex justify-space-between align-center" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'border-white-05'">
                <h3 class="text-subtitle-1 font-weight-black" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-3' : 'text-white'">Detalhes do Recebimento</h3>
                <v-btn icon="mdi-close" variant="text" density="compact" @click="showBillingModal = false"></v-btn>
            </div>
            <div class="pa-5">
                <v-form @submit.prevent="saveReceivable">
                    <v-row dense>
                        <v-col cols="12" md="8">
                             <v-text-field label="Descrição" v-model="editForm.description" variant="outlined" density="compact" class="mb-2"></v-text-field>
                        </v-col>
                        <v-col cols="12" md="4">
                             <v-text-field label="Destinado à (Cliente)" v-model="editForm.entity_name" variant="outlined" density="compact" class="mb-2"></v-text-field>
                        </v-col>
                    </v-row>

                    <v-row dense>
                        <v-col cols="4"><v-text-field label="Valor (R$)" v-model="editForm.value" type="number" variant="outlined" density="compact"></v-text-field></v-col>
                        <v-col cols="4"><v-text-field label="Vencimento" v-model="editForm.due_date" type="date" variant="outlined" density="compact"></v-text-field></v-col>
                        <v-col cols="4"><v-text-field label="Competência" v-model="editForm.competency_date" type="date" variant="outlined" density="compact"></v-text-field></v-col>
                    </v-row>

                    <v-row dense>
                        <v-col cols="6">
                            <v-combobox label="Plano de Contas" v-model="editForm.category" :items="['Venda de Produto','Serviços','Reembolso','Outros']" variant="outlined" density="compact"></v-combobox>
                        </v-col>
                        <v-col cols="6">
                            <v-combobox label="Centro de Custo" v-model="editForm.cost_center" :items="['Comercial','Produção','Administrativo']" variant="outlined" density="compact"></v-combobox>
                        </v-col>
                    </v-row>

                    <v-row dense>
                        <v-col cols="6">
                            <v-select label="Status" v-model="editForm.status" :items="['pendente','pago','atrasado','cancelado']" variant="outlined" density="compact"></v-select>
                        </v-col>
                        <v-col cols="6" v-if="editForm.status === 'pago'">
                            <v-text-field label="Data Pagamento" v-model="editForm.payment_date" type="date" variant="outlined" density="compact"></v-text-field>
                        </v-col>
                    </v-row>

                    <div class="d-flex justify-end gap-2 mt-4">
                        <v-btn variant="text" @click="showBillingModal = false">Cancelar</v-btn>
                        <v-btn color="primary" variant="flat" type="submit" :loading="loading">Salvar Alterações</v-btn>
                    </div>
                </v-form>
            </div>
        </v-card>
    </v-dialog>

    <UniversalImportModal
        :show="showImportModal"
        :system-fields="importFields"
        @update:show="showImportModal = $event"
        @import="handleImportData"
    />
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, reactive } from 'vue';
import { supabase } from '@/api/supabase';
import { format, isBefore, parseISO, differenceInDays, startOfMonth, endOfMonth, addMonths } from 'date-fns';
import { ptBR } from 'date-fns/locale';
import { useAppStore } from '@/stores/app';
import * as XLSX from 'xlsx';
import { useThemeStore } from '@/stores/theme';
import UniversalImportModal from '@/components/admin/UniversalImportModal.vue';

const appStore = useAppStore();
const themeStore = useThemeStore();

const loading = ref(false);
const allReceivables = ref<any[]>([]);
const search = ref('');
const showBillingModal = ref(false);
const currentMonthDate = ref(new Date());
const filters = reactive({ status: [] as string[] });
const showImportModal = ref(false);

const editForm = reactive({
    id: '', description: '', entity_name: '', value: 0,
    due_date: '', competency_date: '', payment_date: '',
    category: '', cost_center: '', status: ''
});

const statusOptions = ['Em Aberto', 'Pago', 'Atrasado'];

const importFields = [
    { key: 'description', label: 'Descrição', required: true, type: 'string' },
    { key: 'entity_name', label: 'Destinado à (Cliente)', required: true, type: 'string' },
    { key: 'due_date', label: 'Data Vencimento', required: true, type: 'date' },
    { key: 'competency_date', label: 'Data Competência', type: 'date' },
    { key: 'payment_date', label: 'Data Pagamento', type: 'date' },
    { key: 'value', label: 'Valor', required: true, type: 'number' },
    { key: 'category', label: 'Plano de Contas', type: 'string' },
    { key: 'cost_center', label: 'Centro de Custo', type: 'string' },
    { key: 'payment_method', label: 'Forma de Pagamento', type: 'string' }
];

// COMPUTED
const currentMonthLabel = computed(() => format(currentMonthDate.value, "MMM yyyy", { locale: ptBR }));
const currentDate = computed(() => format(new Date(), "dd/MM/yyyy"));

const kpiList = computed(() => [
    { label: 'A Receber (Aberto)', value: kpis.value.totalOpen, footer: `${kpis.value.countOpen} títulos pendentes`, icon: 'mdi-finance', gradient: 'bg-gradient-info' },
    { label: 'Total Recebido', value: kpis.value.totalReceived, footer: 'Confirmados em conta', icon: 'mdi-cash-check', gradient: 'bg-gradient-green' },
    { label: 'Em Atraso', value: kpis.value.totalOverdue, footer: `${kpis.value.countOverdue} títulos vencidos`, icon: 'mdi-alert-circle', gradient: 'bg-gradient-red' },
    { label: 'Projeção Total', value: kpis.value.totalProjected, footer: 'Volume total do mês', icon: 'mdi-chart-line', gradient: 'bg-gradient-purple' },
]);

const monthlyReceivables = computed(() => {
    const start = startOfMonth(currentMonthDate.value);
    const end = endOfMonth(currentMonthDate.value);
    let list = allReceivables.value.filter(item => { const d = parseISO(item.due_date); return d >= start && d <= end; });

    if (search.value) {
        const term = search.value.toLowerCase();
        list = list.filter(i =>
            i.description?.toLowerCase().includes(term) ||
            (i.entity_name || i.customer_name)?.toLowerCase().includes(term)
        );
    }
    if (filters.status.length > 0) {
        list = list.filter(i => filters.status.includes(getStatusLabel(i)));
    }
    return list.sort((a, b) => new Date(a.due_date).getTime() - new Date(b.due_date).getTime());
});

const kpis = computed(() => {
    const start = startOfMonth(currentMonthDate.value);
    const end = endOfMonth(currentMonthDate.value);
    const monthItems = allReceivables.value.filter(item => { const d = parseISO(item.due_date); return d >= start && d <= end; });
    const open = monthItems.filter(i => !['pago', 'confirmado', 'cancelado'].includes(i.status));
    const paid = monthItems.filter(i => ['pago', 'confirmado'].includes(i.status));
    const overdue = open.filter(i => isOverdue(i));

    return {
        totalProjected: monthItems.filter(i => i.status !== 'cancelado').reduce((acc, i) => acc + (Number(i.value)||0), 0),
        totalOpen: open.reduce((acc, i) => acc + (Number(i.value)||0), 0),
        countOpen: open.length,
        totalReceived: paid.reduce((acc, i) => acc + (Number(i.value)||0), 0),
        totalOverdue: overdue.reduce((acc, i) => acc + (Number(i.value)||0), 0),
        countOverdue: overdue.length
    };
});

// HELPERS
const formatCurrency = (val: any) => new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(Number(val) || 0);
const formatCurrencyValue = (val: any) => new Intl.NumberFormat('pt-BR', { minimumFractionDigits: 2 }).format(Number(val) || 0);
const formatDateSimple = (date: string) => date ? format(parseISO(date), 'dd/MM/yyyy') : '-';
const isOverdue = (item: any) => (!['pago', 'confirmado', 'cancelado'].includes(item.status) && isBefore(parseISO(item.due_date), new Date()) && differenceInDays(new Date(), parseISO(item.due_date)) >= 1);
const getStatusLabel = (item: any) => { if (item.status === 'pago' || item.status === 'confirmado') return 'Pago'; if (item.status === 'cancelado') return 'Cancelado'; if (isOverdue(item)) return 'Atrasado'; if (item.status === 'faturado') return 'Faturado'; return 'Em Aberto'; };
const getStatusColor = (item: any) => {
    const s = getStatusLabel(item);
    if (s === 'Pago') return 'success';
    if (s === 'Atrasado') return 'error';
    if (s === 'Faturado') return 'info';
    if (s === 'Cancelado') return 'grey';
    return 'warning';
};
const getOrderNumber = (item: any) => {
    if (!item.description) return item.id ? item.id.slice(0,4) : 'N/A';
    const match = item.description?.match(/Pedido #(\d+)/i);
    return match ? match[1] : (item.order_id ? item.order_id : item.description.slice(0, 8));
};

const getInstallmentInfo = (item: any) => {
    const current = item.installment_number || item.parcela_atual;
    const total = item.installments_total || item.total_parcelas;
    if (current && total && total > 1) return { text: `${current}/${total}`, color: 'primary' };
    if (item.description && /\d+\/\d+/.test(item.description)) {
         const match = item.description.match(/(\d+)\/(\d+)/);
         if(match) return { text: match[0], color: 'primary' };
    }
    return { text: 'ÚNICA', color: 'grey' };
};

// ACTIONS
const changeMonth = (amount: number) => { currentMonthDate.value = addMonths(currentMonthDate.value, amount); };
const goToCurrentMonth = () => { currentMonthDate.value = new Date(); };

const openBillingModal = (item: any) => {
    Object.assign(editForm, item);
    // Fallback se entity_name estiver vazio
    if(!editForm.entity_name) editForm.entity_name = item.customer_name;
    showBillingModal.value = true;
};

const openNewReceivableModal = () => {
    Object.assign(editForm, { id: '', description: '', entity_name: '', value: 0, due_date: format(new Date(), 'yyyy-MM-dd'), status: 'pendente' });
    showBillingModal.value = true;
};

const saveReceivable = async () => {
    loading.value = true;
    try {
        const { id, ...data } = editForm;
        if(id) {
            await supabase.from('finance_receivables').update(data).eq('id', id);
            appStore.showSnackbar('Atualizado!', 'success');
        } else {
            await supabase.from('finance_receivables').insert(data);
            appStore.showSnackbar('Criado!', 'success');
        }
        showBillingModal.value = false;
        fetchReceivables();
    } catch {
        appStore.showSnackbar('Erro ao salvar.', 'error');
    } finally { loading.value = false; }
};

const cancelReceivable = async (item: any) => { if(confirm('Cancelar título?')) updateStatus(item, 'cancelado'); };
const updateStatus = async (item: any, status: string) => {
    try {
        const payload: any = { status };
        if(status === 'pago') payload.payment_date = new Date().toISOString();
        await supabase.from('finance_receivables').update(payload).eq('id', item.id);
        item.status = status;
        appStore.showSnackbar('Status atualizado.', 'success');
    } catch { appStore.showSnackbar('Erro', 'error'); }
};

const exportExcel = () => {
    const ws = XLSX.utils.json_to_sheet(monthlyReceivables.value.map(i => ({
        "Ref": getOrderNumber(i),
        "Parcela": getInstallmentInfo(i).text,
        "Vencimento": i.due_date ? format(parseISO(i.due_date), 'dd/MM/yyyy') : '-',
        "Cliente": i.entity_name || i.customer_name,
        "Valor": i.value,
        "Status": getStatusLabel(i),
        "Plano Contas": i.category,
        "Centro Custo": i.cost_center
    })));
    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, "Financeiro");
    XLSX.writeFile(wb, `Financeiro_${format(currentMonthDate.value, 'MM_yyyy')}.xlsx`);
};

const fetchReceivables = async () => {
    loading.value = true;
    try {
        const { data } = await supabase.from('finance_receivables').select('*').order('due_date', { ascending: true });
        allReceivables.value = data || [];
    } catch (e) { console.error(e); } finally { loading.value = false; }
};

// IMPORTAÇÃO
const openImportModal = () => showImportModal.value = true;

const handleImportData = async (data: any[]) => {
    loading.value = true;
    try {
        const payloads = data.map(row => ({
            description: row.description || 'Importado',
            entity_name: row.entity_name || 'Cliente Diverso',
            value: row.value || 0,
            due_date: row.due_date ? format(new Date(row.due_date), 'yyyy-MM-dd') : format(new Date(), 'yyyy-MM-dd'),
            competency_date: row.competency_date ? format(new Date(row.competency_date), 'yyyy-MM-dd') : null,
            payment_date: row.payment_date ? format(new Date(row.payment_date), 'yyyy-MM-dd') : null,
            category: row.category || 'Vendas',
            cost_center: row.cost_center || 'Comercial',
            payment_method: row.payment_method,
            status: row.payment_date ? 'pago' : 'pendente'
        }));

        const { error } = await supabase.from('finance_receivables').insert(payloads);
        if (error) throw error;

        appStore.showSnackbar(`${payloads.length} recebíveis importados!`, 'success');
        fetchReceivables();
    } catch (e: any) {
        appStore.showSnackbar('Erro: ' + e.message, 'error');
    } finally {
        loading.value = false;
        showImportModal.value = false;
    }
};

onMounted(fetchReceivables);
</script>

<style scoped lang="scss">
/* (Mesmos estilos do AdminMjAccountsPayable para consistência visual total) */
.receivables-layout { color: white; position: relative; }
.background-carousel-wrapper { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 0; pointer-events: none; opacity: 0.6; }
.background-overlay { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 1; background: radial-gradient(circle at center, rgba(15, 15, 19, 0.24), rgba(15, 15, 19, 0.98)); backdrop-filter: blur(12px); }
.z-10 { position: relative; z-index: 10; }
.kpi-card { height: 80px; border-radius: 12px; padding: 12px; position: relative; overflow: hidden; border: 1px solid rgba(255,255,255,0.1); cursor: pointer; transition: all 0.3s ease; color: white; }
.kpi-card:hover { transform: translateY(-4px); box-shadow: 0 12px 30px rgba(0,0,0,0.4); filter: brightness(1.1); }
.kpi-bg-icon { position: absolute; right: -10px; bottom: -10px; opacity: 0.15; transform: rotate(-20deg); pointer-events: none; }
.kpi-bg-icon .v-icon { font-size: 80px; color: white; }
.kpi-label { font-size: 0.7rem; font-weight: 700; text-transform: uppercase; letter-spacing: 1px; opacity: 0.9; margin-bottom: 2px; }
.kpi-number-group { display: flex; align-items: baseline; line-height: 1; margin-bottom: 4px; }
.kpi-value { font-size: 1.4rem; font-weight: 900; }
.kpi-footer { font-size: 0.65rem; font-family: monospace; background: rgba(0,0,0,0.2); padding: 1px 6px; border-radius: 4px; width: fit-content; }
.bg-gradient-info { background: linear-gradient(135deg, #00b0ff, #0081cb); }
.bg-gradient-green { background: linear-gradient(135deg, #00c853, #006025); }
.bg-gradient-red { background: linear-gradient(135deg, #ff5252, #c62828); }
.bg-gradient-purple { background: linear-gradient(135deg, #ab47bc, #7b1fa2); }
.bg-glass-dark { background: #0f0f13; }
.bg-glass-header { background: rgba(30, 30, 35, 0.4); backdrop-filter: blur(16px); }
.glass-card { background: rgba(30, 30, 35, 0.3); backdrop-filter: blur(20px); }
.glass-pill { background: rgba(255,255,255,0.08); border-radius: 50px; }
.glass-control-bar { background: rgba(255,255,255,0.03); backdrop-filter: blur(10px); }
.bg-white-05 { background: rgba(255,255,255,0.05); }
.bg-white-10 { background: rgba(255,255,255,0.1); }
.border-white-05 { border-color: rgba(255,255,255,0.05) !important; }
.border-white-10 { border-color: rgba(255,255,255,0.1) !important; }
.action-btn { width: 32px; height: 32px; border-radius: 6px; display: flex; align-items: center; justify-content: center; border: 1px solid rgba(128,128,128,0.2); cursor: pointer; transition: all 0.2s ease; }
.action-btn:hover { transform: translateY(-2px); }
.info-btn { background: rgba(33, 150, 243, 0.1); color: #2196F3; }
.info-btn:hover { background: #2196F3; color: white; }
.success-btn { background: rgba(76, 175, 80, 0.1); color: #4CAF50; }
.success-btn:hover { background: #4CAF50; color: white; }
.warning-btn { background: rgba(255, 152, 0, 0.1); color: #FF9800; }
.warning-btn:hover { background: #FF9800; color: white; }
.primary-btn { background: rgba(103, 58, 183, 0.1); color: #673AB7; }
.primary-btn:hover { background: #673AB7; color: white; }
.error-btn { background: rgba(244, 67, 54, 0.1); color: #F44336; }
.error-btn:hover { background: #F44336; color: white; }
.clean-input { border: none; outline: none; background: transparent; padding: 0; }
.status-select-tiny :deep(.v-field__input) { padding-top: 0 !important; padding-bottom: 0 !important; min-height: 32px; display: flex; align-items: center; }
.status-select-tiny :deep(.v-field__append-inner) { display: none; }
.receivable-row { transition: all 0.2s ease; cursor: default; }
.receivable-row:hover { transform: scale(0.998); }
.receivable-row.bg-white:hover { background: #f8fafc !important; }
.hover-bg-glass:hover { background: rgba(255,255,255,0.04); }
.custom-scroll::-webkit-scrollbar { width: 4px; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.3); border-radius: 4px; }
.icon-box-xs { width: 32px; height: 32px; display: flex; align-items: center; justify-content: center; }
.gap-1 { gap: 4px; } .gap-2 { gap: 8px; } .gap-3 { gap: 12px; } .gap-6 { gap: 24px; }
.opacity-hover:hover { opacity: 0.8; }
.focus-within\:border-primary:focus-within { border-color: #1976D2 !important; }
.bg-surface-dark { background-color: #1E1E24; }
:global(.custom-tooltip-white) { background-color: #FFFFFF !important; color: #000000 !important; font-size: 10px !important; font-weight: 700; padding: 4px 8px; border-radius: 4px; }
</style>
