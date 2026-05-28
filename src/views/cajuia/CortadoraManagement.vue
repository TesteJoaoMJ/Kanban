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
            <span class="opacity-70">Operacional</span>
            <span class="mx-2 opacity-50">></span>
            <span class="font-weight-bold">Corte e Separação</span>
          </div>
          <div class="d-flex align-center gap-2 mt-1">
             <div class="text-h6 font-weight-black tracking-tight leading-none" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">
                Gestão de Lotes
             </div>
          </div>
        </div>

        <div class="d-flex align-center overflow-x-auto pb-1 pb-md-0" style="gap: 10px;">
          <v-btn
            color="success"
            variant="flat"
            class="btn-rect px-3 px-md-4 font-weight-bold text-caption text-uppercase letter-spacing-1 flex-shrink-0"
            prepend-icon="mdi-plus"
            height="40"
            @click="openEditModal()"
          >
             Novo Lote / OP
          </v-btn>
        </div>
      </div>

      <div class="px-4 px-md-6 py-2 flex-shrink-0">
        <v-row class="d-none d-md-flex">
          <v-col cols="12" sm="3" v-for="(kpi, idx) in kpiList" :key="idx">
            <v-card
              class="kpi-card kpi-rect bg-gradient-custom hover-elevate py-3 px-4 cursor-pointer"
              :class="[kpi.gradient]"
              v-ripple
              elevation="2"
            >
              <div class="kpi-bg-icon"><v-icon>{{ kpi.icon }}</v-icon></div>
              <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                <div class="d-flex align-center" style="gap: 8px;">
                  <v-icon size="18" class="opacity-80">{{ kpi.icon }}</v-icon>
                  <span class="kpi-label text-uppercase">{{ kpi.label }}</span>
                </div>
                <div class="kpi-number-group my-1">
                  <span class="kpi-value">{{ kpi.value }}</span>
                  <span class="text-caption font-weight-medium ml-1 opacity-70">pçs</span>
                </div>
                <div class="kpi-footer mt-1">{{ kpi.footer }}</div>
              </div>
            </v-card>
          </v-col>
        </v-row>
      </div>

      <div class="px-4 px-md-6 pt-0 pb-2 flex-shrink-0">
        <div class="controls-bar d-flex flex-column" :class="themeStore.currentMode === 'light' ? 'controls-light' : 'controls-dark'" style="gap: 10px;">
          <div class="d-flex align-center justify-space-between" style="gap: 10px;">
            <div class="search-wrap d-flex align-center w-100" :class="themeStore.currentMode === 'light' ? 'search-light' : 'search-dark'">
              <v-icon :color="themeStore.currentMode === 'light' ? 'grey-darken-1' : 'white-70'">mdi-magnify</v-icon>
              <input
                v-model="searchQuery"
                type="text"
                placeholder="Buscar por lote, peça, cor, OP..."
                class="clean-input flex-grow-1 ml-2 font-weight-bold"
              />
            </div>
            <v-btn variant="flat" class="btn-rect flex-shrink-0" height="40" prepend-icon="mdi-refresh" color="primary" @click="fetchTasks">
               Atualizar
            </v-btn>
          </div>
        </div>
      </div>

      <div class="flex-grow-1 overflow-hidden d-flex flex-column transition-all px-4 px-md-6 pb-4">
        <v-card class="flex-grow-1 d-flex flex-column rounded-0 border-thin overflow-hidden" :class="themeStore.currentMode === 'light' ? 'bg-white shadow-sm' : 'glass-card border-white-05'" :elevation="0">

          <div class="grid-scroll flex-grow-1 overflow-auto custom-scroll relative">
            <div class="grid-header sticky-head" :class="themeStore.currentMode === 'light' ? 'grid-surface-light' : 'grid-surface-dark'">
              <div class="cell cell-ref center header-text">ID / OP</div>
              <div class="cell cell-client header-text">Peça / Produto</div>
              <div class="cell center header-text">Cor / Tam.</div>
              <div class="cell center header-text">Qtd</div>
              <div class="cell center header-text">Previsão</div>
              <div class="cell center header-text">Prioridade</div>
              <div class="cell center header-text">Status Atual</div>
              <div class="cell cell-actions center header-text">Ações</div>
            </div>

            <div v-if="loading" class="d-flex flex-column justify-center align-center h-100 py-10 min-w-full">
              <v-progress-circular indeterminate color="primary" size="32" width="3"></v-progress-circular>
            </div>

            <div v-else-if="filteredItems.length === 0" class="d-flex flex-column justify-center align-center h-100 opacity-60 py-10 min-w-full">
              <v-icon size="48" color="grey-lighten-1">mdi-scissors-cutting</v-icon>
              <span class="text-body-2 font-weight-medium text-grey mt-2">Nenhum lote de corte encontrado.</span>
            </div>

            <div
              v-else
              v-for="(item, index) in filteredItems"
              :key="item.id"
              class="grid-row"
              :class="[ themeStore.currentMode === 'light' ? 'grid-row-light' : 'grid-row-dark', zebraClass(index) ]"
            >
                <div class="cell cell-ref center">
                    <span class="pill-ref bg-grey-lighten-3 text-grey-darken-4">{{ item.ordem_producao || item.id.substring(0,6).toUpperCase() }}</span>
                </div>
                <div class="cell cell-client">
                    <div class="d-flex flex-column" style="min-width: 0;">
                        <div class="text-truncate list-text-11 font-weight-black text-primary">{{ item.nome_peca }}</div>
                        <div class="text-truncate text-caption opacity-70">Lote: {{ item.lote || 'N/A' }}</div>
                    </div>
                </div>
                <div class="cell center">
                    <div class="d-flex flex-column align-center">
                        <span class="font-weight-bold">{{ item.tamanho || '-' }}</span>
                        <span class="text-[10px] opacity-70">{{ item.cor || '-' }}</span>
                    </div>
                </div>
                <div class="cell center">
                    <span class="list-text-11 font-mono font-weight-black text-grey-darken-4">{{ item.quantidade }}</span>
                </div>
                <div class="cell center">
                    <span class="list-text-11 font-mono font-weight-medium" :class="isLate(item.data_prevista) ? 'text-red-darken-1' : ''">
                        {{ formatDateSafe(item.data_prevista) }}
                    </span>
                </div>
                <div class="cell center">
                    <v-chip size="x-small" :color="getPriorityColor(item.prioridade)" class="font-weight-bold text-uppercase px-2" variant="tonal">
                        {{ item.prioridade || 'Normal' }}
                    </v-chip>
                </div>
                <div class="cell center">
                    <span class="solid-chip chip-status cursor-pointer hover-scale transition-all" :class="getStatusClass(item.status)" @click="cycleStatus(item)">
                        {{ item.status }}
                        <v-icon right size="12" class="ml-1 opacity-70">mdi-sync</v-icon>
                    </span>
                </div>
                <div class="cell cell-actions center">
                    <div class="actions-inline">
                        <v-btn icon size="x-small" class="action-btn action-print bg-grey-lighten-2 text-grey-darken-3" @click.stop="openLabelModal(item)" variant="flat" title="Gerar Etiqueta (Preset)">
                          <v-icon size="16">mdi-printer</v-icon>
                        </v-btn>
                        <v-btn icon size="x-small" class="action-btn action-edit" @click.stop="openEditModal(item)" variant="flat" title="Editar Lote">
                          <v-icon size="16">mdi-pencil</v-icon>
                        </v-btn>
                        <v-btn icon size="x-small" class="action-btn action-del" @click.stop="deleteItem(item)" variant="flat" title="Excluir Lote">
                          <v-icon size="16">mdi-trash-can-outline</v-icon>
                        </v-btn>
                    </div>
                </div>
            </div>
          </div>
        </v-card>
      </div>
    </div>

    <v-dialog v-model="modal.show" width="1000" persistent scrim="black opacity-80" transition="dialog-bottom-transition" class="fixed-dialog">
        <v-card class="d-flex overflow-hidden rounded-0 fill-height flex-row" height="650">
            <div class="modal-sidebar pa-6 d-flex flex-column text-white" :class="themeStore.currentMode === 'light' ? 'bg-primary' : 'bg-surface-variant'" style="width: 280px; flex-shrink: 0;">
                 <div class="d-flex align-center" style="gap: 12px;">
                    <div class="bg-white-20 p-3 rounded-0 d-flex align-center justify-center" style="width: 48px; height: 48px;">
                        <v-icon size="32" color="white">mdi-scissors-cutting</v-icon>
                    </div>
                    <div>
                        <h3 class="text-h6 font-weight-black leading-tight">{{ modal.form.id ? 'Editando' : 'Novo Lançamento' }}</h3>
                        <div class="text-caption opacity-80">Gestão de Corte</div>
                    </div>
                </div>
                <div class="mt-6 bg-white-10 pa-4 rounded-0">
                    <div class="text-caption font-weight-black opacity-70 mb-1 text-uppercase">Peças no Lote</div>
                    <div class="text-h3 font-weight-black">{{ modal.form.quantidade }}</div>
                </div>
                 <v-spacer></v-spacer>
            </div>

            <div class="flex-grow-1 d-flex flex-column bg-white h-100 overflow-hidden relative">
                 <div class="pa-0 border-b bg-grey-lighten-5 flex-shrink-0">
                    <div class="d-flex align-center justify-space-between px-4 pt-3 pb-0">
                        <v-tabs v-model="modal.activeTab" color="primary" density="comfortable" show-arrows>
                            <v-tab value="basic"><v-icon start size="small">mdi-tag-multiple</v-icon> Peça & Ficha</v-tab>
                            <v-tab value="prod"><v-icon start size="small">mdi-factory</v-icon> Produção & Status</v-tab>
                        </v-tabs>
                        <v-btn icon="mdi-close" variant="text" color="grey-darken-1" @click="modal.show = false"></v-btn>
                    </div>
                </div>

                <div class="flex-grow-1 overflow-y-auto custom-scroll pa-6 bg-white absolute-fill" style="height: calc(100% - 130px);">
                    <v-form @submit.prevent="saveTask" id="taskForm">
                        <v-window v-model="modal.activeTab">
                            <v-window-item value="basic">
                                <div class="text-subtitle-1 font-weight-bold text-grey-darken-3 mb-4">Informações do Produto</div>
                                <v-row class="row-gap">
                                    <v-col cols="12" md="8">
                                        <v-autocomplete
                                            label="Vincular do Estoque (Opcional)"
                                            v-model="modal.form.stock_item_id"
                                            :items="stockItems"
                                            item-title="fabric_type"
                                            item-value="id"
                                            variant="outlined"
                                            color="primary"
                                            density="comfortable"
                                            class="ui-field"
                                            clearable
                                            @update:modelValue="onStockSelect"
                                        ></v-autocomplete>
                                    </v-col>
                                    <v-col cols="12" md="4">
                                        <v-text-field label="Lote" v-model="modal.form.lote" variant="outlined" density="comfortable" color="primary" class="ui-field"></v-text-field>
                                    </v-col>
                                    <v-col cols="12">
                                        <v-text-field label="Nome da Peça / Modelo*" v-model="modal.form.nome_peca" variant="outlined" density="comfortable" color="primary" class="ui-field font-weight-bold"></v-text-field>
                                    </v-col>
                                    <v-col cols="12" md="4">
                                        <v-text-field label="Quantidade*" v-model.number="modal.form.quantidade" type="number" min="1" variant="outlined" density="comfortable" color="primary" class="ui-field font-weight-black"></v-text-field>
                                    </v-col>
                                    <v-col cols="12" md="4">
                                        <v-text-field label="Tamanho(s)" v-model="modal.form.tamanho" variant="outlined" density="comfortable" placeholder="Ex: P, M, G ou Único" class="ui-field"></v-text-field>
                                    </v-col>
                                    <v-col cols="12" md="4">
                                        <v-text-field label="Cor / Estampa" v-model="modal.form.cor" variant="outlined" density="comfortable" class="ui-field"></v-text-field>
                                    </v-col>
                                </v-row>
                            </v-window-item>

                            <v-window-item value="prod">
                                <div class="text-subtitle-1 font-weight-bold text-grey-darken-3 mb-4">Acompanhamento e Prazos</div>
                                <v-row class="row-gap">
                                    <v-col cols="12" md="6">
                                        <v-text-field label="Ordem de Produção (OP)" v-model="modal.form.ordem_producao" variant="outlined" density="comfortable" class="ui-field"></v-text-field>
                                    </v-col>
                                    <v-col cols="12" md="6">
                                        <v-text-field label="Data Prev. Fim" v-model="modal.form.data_prevista" type="date" variant="outlined" density="comfortable" class="ui-field"></v-text-field>
                                    </v-col>
                                    <v-col cols="12" md="6">
                                        <v-select label="Prioridade" v-model="modal.form.prioridade" :items="['Baixa', 'Normal', 'Urgente', 'Imediata']" variant="outlined" density="comfortable" class="ui-field font-weight-bold" :color="getPriorityColor(modal.form.prioridade)"></v-select>
                                    </v-col>
                                    <v-col cols="12" md="6">
                                        <v-select label="Status Atual*" v-model="modal.form.status" :items="statusOptions" variant="outlined" density="comfortable" class="ui-field font-weight-bold" :color="getStatusColor(modal.form.status)"></v-select>
                                    </v-col>
                                    <v-col cols="12">
                                        <v-textarea label="Observações de Corte / Defeitos" v-model="modal.form.observacoes" variant="outlined" rows="3" density="comfortable" class="ui-field"></v-textarea>
                                    </v-col>
                                </v-row>
                            </v-window-item>
                        </v-window>
                    </v-form>
                </div>

                <div class="pa-4 border-t bg-grey-lighten-5 d-flex justify-end align-center flex-shrink-0" style="gap: 12px; height: 80px;">
                    <v-btn variant="outlined" class="btn-rect" height="48" @click="modal.show = false" :disabled="modal.saving">Cancelar</v-btn>
                    <v-btn color="primary" variant="flat" class="btn-rect px-8 font-weight-black text-body-1" height="48" type="submit" form="taskForm" :loading="modal.saving"><v-icon start>mdi-content-save-check</v-icon> Salvar Lote</v-btn>
                </div>
            </div>
        </v-card>
    </v-dialog>

    <LabelGeneratorModal v-model="showLabelModal" :products="selectedProductsForLabel" />

  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, reactive } from 'vue';
import { supabase } from '@/api/supabase';
import { useAppStore } from '@/stores/app';
import { useUserStore } from '@/stores/user';
import { useCompanyStore } from '@/stores/company';
import { useThemeStore } from '@/stores/theme';
import { format } from 'date-fns';
import LabelGeneratorModal from '@/components/admin/LabelGeneratorModal.vue';

const appStore = useAppStore();
const userStore = useUserStore();
const companyStore = useCompanyStore();
const themeStore = useThemeStore();

// --- STATE ---
const loading = ref(false);
const allTasks = ref<any[]>([]);
const stockItems = ref<any[]>([]);
const searchQuery = ref('');

const statusOptions = ['Corte', 'Costura Piloto', 'Costura Produção', 'Envio a Loja', 'Concluído'];

// --- MODAL CADASTRO ---
const modal = reactive({
    show: false,
    saving: false,
    activeTab: 'basic',
    form: { id: '', stock_item_id: null, nome_peca: '', quantidade: 1, lote: '', tamanho: '', cor: '', prioridade: 'Normal', data_prevista: '', status: 'Corte', observacoes: '', ordem_producao: '' }
});

// --- ESTADO IMPRESSÃO LABEL GENERATOR ---
const showLabelModal = ref(false);
const selectedProductsForLabel = ref<any[]>([]);

// --- KPIs ---
const kpiList = computed(() => {
    let total = 0, corte = 0, costura = 0, pronto = 0;
    allTasks.value.forEach(t => {
        total += Number(t.quantidade || 0);
        if (t.status === 'Corte') corte += Number(t.quantidade || 0);
        if (t.status.includes('Costura')) costura += Number(t.quantidade || 0);
        if (t.status === 'Concluído' || t.status === 'Envio a Loja') pronto += Number(t.quantidade || 0);
    });

    return [
        { label: 'Total Registrado', value: total, footer: 'Todas as peças', icon: 'mdi-layers', gradient: 'bg-gradient-purple' },
        { label: 'Na Mesa de Corte', value: corte, footer: 'Aguardando Laser', icon: 'mdi-scissors-cutting', gradient: 'bg-gradient-warning' },
        { label: 'Em Costura (Facção)', value: costura, footer: 'Piloto e Produção', icon: 'mdi-sewing-machine', gradient: 'bg-gradient-info' },
        { label: 'Prontos para Loja', value: pronto, footer: 'Liberados', icon: 'mdi-check-decagram', gradient: 'bg-gradient-green' },
    ];
});

const filteredItems = computed(() => {
    let result = allTasks.value;
    if (searchQuery.value) {
        const q = searchQuery.value.toLowerCase();
        result = result.filter(t =>
            (t.nome_peca && t.nome_peca.toLowerCase().includes(q)) ||
            (t.lote && t.lote.toLowerCase().includes(q)) ||
            (t.ordem_producao && t.ordem_producao.toLowerCase().includes(q)) ||
            (t.cor && t.cor.toLowerCase().includes(q))
        );
    }
    return result;
});

// --- FUNÇÕES ---

// Faz o Join com Stock para pegar os dados originais reais
const fetchTasks = async () => {
    loading.value = true;
    try {
        const { data, error } = await supabase
            .from('cajuia_corte_tasks')
            .select(`
                *,
                stock:stock_item_id (
                    barcode,
                    base_price,
                    gestao_click_id
                )
            `)
            .order('created_at', { ascending: false });

        if (error) throw error;
        allTasks.value = data || [];
    } catch (e: any) {
        appStore.showSnackbar('Erro ao buscar lotes: ' + e.message, 'error');
    } finally {
        loading.value = false;
    }
};

const fetchStock = async () => {
    try {
        const { data } = await supabase.from('stock').select('id, fabric_type').limit(300);
        stockItems.value = data || [];
    } catch (e) {
        console.warn("Estoque não carregado", e);
    }
};

const onStockSelect = (id: any) => {
    const item = stockItems.value.find(i => i.id === id);
    if (item && !modal.form.nome_peca) {
        modal.form.nome_peca = item.fabric_type;
    }
};

const openEditModal = (item?: any) => {
    modal.activeTab = 'basic';
    if (item) {
        Object.assign(modal.form, item);
    } else {
        Object.assign(modal.form, { id: '', stock_item_id: null, nome_peca: '', quantidade: 1, lote: '', tamanho: '', cor: '', prioridade: 'Normal', data_prevista: '', status: 'Corte', observacoes: '', ordem_producao: '' });
    }
    modal.show = true;
};

const saveTask = async () => {
    if (!modal.form.nome_peca) return appStore.showSnackbar('O nome da peça é obrigatório.', 'warning');

    modal.saving = true;
    try {
        const payload: any = {
            nome_peca: modal.form.nome_peca,
            quantidade: Number(modal.form.quantidade) || 1,
            status: modal.form.status || 'Corte',
            prioridade: modal.form.prioridade || 'Normal',
            lote: modal.form.lote || null,
            tamanho: modal.form.tamanho || null,
            cor: modal.form.cor || null,
            observacoes: modal.form.observacoes || null,
            ordem_producao: modal.form.ordem_producao || null,
            data_prevista: modal.form.data_prevista || null,
            stock_item_id: modal.form.stock_item_id || null,
            company_id: companyStore.context !== 'global' ? companyStore.context : null,
            user_id: userStore.user?.id || null
        };

        let err;
        if (modal.form.id) {
            const { error } = await supabase.from('cajuia_corte_tasks').update(payload).eq('id', modal.form.id);
            err = error;
        } else {
            const { error } = await supabase.from('cajuia_corte_tasks').insert(payload);
            err = error;
        }

        if (err) throw err;

        appStore.showSnackbar('Lote salvo com sucesso!', 'success');
        modal.show = false;
        fetchTasks();
    } catch (e: any) {
        appStore.showSnackbar('Erro ao salvar: ' + (e.message || e.details || 'Falha no banco de dados'), 'error');
    } finally {
        modal.saving = false;
    }
};

const deleteItem = async (item: any) => {
    if (!confirm(`Deseja excluir o lote da peça ${item.nome_peca}?`)) return;
    try {
        await supabase.from('cajuia_corte_tasks').delete().eq('id', item.id);
        appStore.showSnackbar('Excluído.', 'success');
        fetchTasks();
    } catch (e) {
        appStore.showSnackbar('Erro ao excluir', 'error');
    }
};

const cycleStatus = async (item: any) => {
    const idx = statusOptions.indexOf(item.status);
    const next = statusOptions[(idx + 1) % statusOptions.length];
    item.status = next;
    try {
        await supabase.from('cajuia_corte_tasks').update({ status: next }).eq('id', item.id);
    } catch (e) {
        appStore.showSnackbar('Falha ao sincronizar status no banco.', 'error');
    }
};

// ==========================================
// INTEGRAÇÃO PERFEITA COM O LABEL STUDIO
// ==========================================
const openLabelModal = (item: any) => {
    // Busca os dados reais que vieram do banco pelo JOIN
    const stockData = item.stock || {};

    selectedProductsForLabel.value = [{
        name: item.nome_peca,
        // Prioriza o Barcode Original do Estoque, depois Lote, depois o ID
        barcode: stockData.barcode || item.lote || item.id.substring(0, 8),
        // Prioriza o Preço Original do Estoque
        price: stockData.base_price || 0,
        // SKU = ID ERP ou Ordem Produção
        sku: stockData.gestao_click_id || item.ordem_producao || 'OP-000'
    }];

    showLabelModal.value = true;
};

// --- UTILS CSS ---
const formatDateSafe = (dateString: string) => {
    if (!dateString) return '-';
    return dateString.split('T')[0].split('-').reverse().join('/');
};
const isLate = (dateString: string) => {
    if (!dateString) return false;
    return dateString < format(new Date(), 'yyyy-MM-dd');
};
const zebraClass = (i: number) => themeStore.currentMode !== 'light' ? (i % 2 === 0 ? 'zebra-dark-a' : 'zebra-dark-b') : (i % 2 === 0 ? 'zebra-light-a' : 'zebra-light-b');

const getStatusColor = (s: string) => {
    if (s === 'Concluído') return 'success';
    if (s === 'Envio a Loja') return 'info';
    if (s.includes('Costura')) return 'deep-purple';
    return 'warning';
};

const getStatusClass = (s: string) => {
    if (s === 'Concluído') return 'bg-green-darken-1';
    if (s === 'Envio a Loja') return 'bg-blue-darken-1';
    if (s.includes('Costura')) return 'bg-deep-purple-darken-1';
    return 'bg-orange-darken-2';
};

const getPriorityColor = (p: string) => {
    if (p === 'Imediata') return 'red-darken-2';
    if (p === 'Urgente') return 'orange-darken-3';
    if (p === 'Baixa') return 'blue-grey';
    return 'teal-darken-2';
};

onMounted(() => {
    fetchStock();
    fetchTasks();
});
</script>

<style scoped>
.receivables-layout { position: relative; }
.bg-glass-dark { background: rgba(10,10,12,0.85); }
.bg-glass-header { background: rgba(20,20,24,0.55); backdrop-filter: blur(14px); }
.border-bottom-white-05 { border-bottom: 1px solid rgba(255,255,255,0.08); }
.btn-rect { border-radius: 0 !important; text-transform: none !important; font-weight: 800; }
.controls-bar { border: 1px solid rgba(0,0,0,0.08); padding: 10px; }
.search-wrap { height: 40px; padding: 0 12px; border: 1px solid rgba(0,0,0,0.08); display: flex; align-items: center; flex: 1; }
.clean-input { border: none; outline: none; flex: 1; font-size: 14px; }

/* ---------------------------------------------------------
   GRID DEFINITION CONSERTADA E ESPAÇOSA
--------------------------------------------------------- */
.grid-header, .grid-row {
    display: grid;
    align-items: stretch;
    width: 100%;
    /* Mínimo de largura para não engolir os botões em telas normais */
    min-width: 980px;
    /* A última coluna (Ações) recebe 120px fixos para caber perfeitamente os 3 botões lado a lado */
    grid-template-columns: 80px minmax(200px, 1fr) 100px 80px 100px 110px 130px 120px;
}

.cell {
    padding: 6px 8px;
    display: flex;
    align-items: center;
    border-right: 1px solid rgba(0,0,0,0.08);
    border-bottom: 1px solid rgba(0,0,0,0.08);
    min-height: 54px;
    overflow: hidden;
    transition: background-color 0.2s ease;
}

.header-text { font-size: 14px !important; font-weight: 800; text-transform: uppercase; letter-spacing: 0.5px; line-height: 1.2; }
.grid-header .cell { min-height: 44px; }
.center { justify-content: center; text-align: center; }
.list-text-11 { font-size: 16px !important; line-height: 1.2 !important; }

/* Themes */
.grid-surface-light .cell { background: #f5f7fa; color: rgba(0,0,0,0.9); border-color: rgba(0,0,0,0.12) !important; }
.grid-surface-dark .cell { background: rgba(255,255,255,0.08); color: rgba(255,255,255,0.95); border-color: rgba(255,255,255,0.1) !important; }

.grid-row-light .cell { border-color: rgba(0,0,0,0.08) !important; }
.grid-row-dark .cell { border-color: rgba(255,255,255,0.08) !important; }

.zebra-light-a .cell { background: #ffffff; }
.zebra-light-b .cell { background: #f0f4f8; }
.zebra-dark-a .cell { background: rgba(0,0,0,0.15); }
.zebra-dark-b .cell { background: rgba(255,255,255,0.03); }

.grid-row-light:hover .cell { background: #e3f2fd !important; }
.grid-row-dark:hover .cell { background: rgba(255,255,255,0.12) !important; }

/* KPIs */
.kpi-card { color: white; position: relative; min-height: 110px; overflow: hidden; }
.kpi-bg-icon { position: absolute; right: -20px; bottom: -20px; opacity: 0.15; transform: rotate(-15deg); }
.kpi-bg-icon .v-icon { font-size: 100px; color: white; }
.bg-gradient-info { background: linear-gradient(135deg, #0288d1, #005b9f); }
.bg-gradient-green { background: linear-gradient(135deg, #2e7d32, #1b5e20); }
.bg-gradient-purple { background: linear-gradient(135deg, #7b1fa2, #4a148c); }
.bg-gradient-warning { background: linear-gradient(135deg, #FFB300, #F57F17); }
.kpi-label { font-size: 12px; font-weight: 900; letter-spacing: .2px; }
.kpi-value { font-size: 26px; font-weight: 900; line-height: 1; }
.kpi-footer { font-size: 11px; opacity: .9; font-weight: 700; }

.pill-ref { font-size: 12px !important; font-weight: 900; font-family: monospace; padding: 4px 6px; border-radius: 0px; white-space: nowrap; }
.solid-chip { display: inline-flex; align-items: center; justify-content: center; height: 28px; padding: 0 12px; border-radius: 0px; font-size: 12px !important; font-weight: 900; color: #fff; text-transform: uppercase; white-space: nowrap; }
.hover-scale:hover { transform: scale(1.05); }

/* ---------------------------------------------------------
   BOTÕES DE AÇÃO: GARANTIA DE ÍCONES VISÍVEIS
--------------------------------------------------------- */
.actions-inline {
    display: flex;
    gap: 6px;
    justify-content: center;
    align-items: center;
    flex-wrap: nowrap; /* Não quebra de linha nunca */
}
.action-btn {
    width: 28px !important;
    height: 28px !important;
    border-radius: 6px !important;
    color: #fff !important;
}
.action-edit { background: #1976d2 !important; }
.action-del { background: #c62828 !important; }

.ui-field :deep(.v-field) { border-radius: 0 !important; }
.row-gap { row-gap: 14px; }
.fixed-dialog { overflow: hidden !important; }
.absolute-fill { height: 100%; overflow-y: auto; }

/* Moldura e Sticky Head */
.flex-grow-1.overflow-hidden > .v-card.flex-grow-1 { border: 1px solid rgba(0,0,0,0.12) !important; }
.bg-glass-dark .flex-grow-1.overflow-hidden > .v-card.flex-grow-1 { border: 1px solid rgba(255,255,255,0.12) !important; }
.sticky-head { position: sticky; top: 0; z-index: 20; box-shadow: 0 8px 16px -4px rgba(0, 0, 0, 0.12); }
.bg-glass-dark .sticky-head { box-shadow: 0 8px 20px -4px rgba(0, 0, 0, 0.4); }
</style>
