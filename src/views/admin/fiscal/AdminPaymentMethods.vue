<template>
  <div
    class="fill-height d-flex flex-column"
    :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 text-grey-darken-4' : 'bg-grey-darken-4 text-white'"
  >
    <v-card
      class="rounded-0 border-b px-6 py-4 d-flex align-center justify-space-between flex-shrink-0"
      :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-grey-darken-3'"
      elevation="0"
    >
      <div class="d-flex align-center">
        <v-avatar color="primary" variant="tonal" size="40" class="mr-4 rounded-lg">
          <v-icon>mdi-credit-card-settings-outline</v-icon>
        </v-avatar>
        <div>
          <h2 class="text-h6 font-weight-black leading-none mb-1">Formas de Pagamento</h2>
          <div class="text-caption opacity-70">
            Gerencie os métodos de pagamento disponíveis para vendas e finanças.
          </div>
        </div>
      </div>
      <v-btn color="primary" variant="flat" prepend-icon="mdi-plus" class="font-weight-bold text-none btn-rect" @click="openModal()">
        Nova Forma
      </v-btn>
    </v-card>

    <div class="px-6 py-3 border-b d-flex gap-3 align-center flex-wrap" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-4' : 'bg-white-05'">
      <v-text-field
        v-model="searchQuery"
        placeholder="Buscar forma de pagamento..."
        prepend-inner-icon="mdi-magnify"
        density="compact"
        variant="outlined"
        hide-details
        class="flex-grow-1 bg-white border-thin btn-rect"
        style="max-width: 400px;"
      ></v-text-field>

      <v-btn-toggle v-model="statusFilter" density="compact" variant="outlined" color="primary" mandatory class="btn-rect bg-white">
        <v-btn value="all" class="text-none font-weight-bold">Todas</v-btn>
        <v-btn value="active" class="text-none font-weight-bold">Ativas</v-btn>
        <v-btn value="inactive" class="text-none font-weight-bold">Ocultas</v-btn>
      </v-btn-toggle>

      <v-spacer></v-spacer>
      <v-btn icon variant="text" size="small" @click="fetchMethods" :loading="loading"><v-icon>mdi-refresh</v-icon></v-btn>
    </div>

    <div class="flex-grow-1 overflow-auto custom-scroll relative">
      <div class="grid-header sticky-head" :class="themeStore.currentMode === 'light' ? 'grid-surface-light' : 'grid-surface-dark'">
        <div class="cell header-text pl-6">FORMA DE PAGAMENTO</div>
        <div class="cell center header-text">ID GESTÃOCLICK</div>
        <div class="cell center header-text">USO NO SISTEMA</div>
        <div class="cell center header-text">STATUS</div>
        <div class="cell center header-text">AÇÕES</div>
      </div>

      <div v-if="loading" class="d-flex justify-center py-10">
        <v-progress-circular indeterminate color="primary" size="40"></v-progress-circular>
      </div>

      <div v-else-if="filteredMethods.length === 0" class="text-center py-10 opacity-60">
        <v-icon size="50" class="mb-3">mdi-card-off-outline</v-icon>
        <div class="text-body-2 font-weight-medium">Nenhuma forma de pagamento corresponde aos filtros.</div>
      </div>

      <div v-else>
        <div
            v-for="(method, idx) in filteredMethods"
            :key="method.id"
            class="grid-row"
            :class="[
                themeStore.currentMode === 'light' ? 'grid-row-light' : 'grid-row-dark',
                zebraClass(idx),
                !method.is_active ? 'opacity-60 grayscale' : ''
            ]"
        >
            <div class="cell pl-6 d-flex align-center">
                <v-icon :color="method.is_active ? 'primary' : 'grey'" size="20" class="mr-3">
                  {{ getIconForMethod(method.name) }}
                </v-icon>
                <span class="font-weight-bold list-text" :class="!method.is_active ? 'text-decoration-line-through' : ''">
                    {{ method.name }}
                </span>
            </div>

            <div class="cell center">
                <span class="font-mono list-text opacity-70">{{ method.gestao_click_id || '---' }}</span>
            </div>

            <div class="cell center">
                <v-progress-circular v-if="method.usageLoading" indeterminate size="16" width="2" color="grey"></v-progress-circular>
                <v-chip v-else size="x-small" :color="method.usageCount > 0 ? 'primary' : 'grey'" variant="tonal" class="font-weight-black px-3">
                    {{ method.usageCount }} VÍNCULOS
                </v-chip>
            </div>

            <div class="cell center">
                <span class="solid-chip" :class="method.is_active ? 'chip-success' : 'chip-danger'">
                    {{ method.is_active ? 'ATIVO' : 'OCULTO' }}
                </span>
            </div>

              <div class="cell center" style="gap: 12px;">

                <v-tooltip text="Clonar" location="top" content-class="custom-tooltip">
                    <template v-slot:activator="{ props }">
                        <v-btn v-bind="props" icon size="small" variant="flat" color="success" class="action-btn text-white" @click="cloneMethod(method)">
                            <v-icon size="18">mdi-content-copy</v-icon>
                        </v-btn>
                    </template>
                </v-tooltip>

                <v-tooltip text="Editar" location="top" content-class="custom-tooltip">
                    <template v-slot:activator="{ props }">
                        <v-btn v-bind="props" icon size="small" variant="flat" color="warning" class="action-btn text-white" @click="openModal(method)">
                            <v-icon size="18">mdi-pencil</v-icon>
                        </v-btn>
                    </template>
                </v-tooltip>

                <v-tooltip :text="method.is_active ? 'Ocultar' : 'Ativar'" location="top" content-class="custom-tooltip">
                    <template v-slot:activator="{ props }">
                        <v-btn v-bind="props" icon size="small" variant="flat" color="info" class="action-btn text-white" @click="toggleStatus(method)">
                            <v-icon size="18">{{ method.is_active ? 'mdi-eye-off' : 'mdi-eye' }}</v-icon>
                        </v-btn>
                    </template>
                </v-tooltip>

                <v-tooltip text="Apagar" location="top" content-class="custom-tooltip">
                    <template v-slot:activator="{ props }">
                        <v-btn v-bind="props" icon size="small" variant="flat" color="error" class="action-btn text-white" @click="confirmDelete(method)" :disabled="method.usageCount > 0">
                            <v-icon size="18">mdi-delete</v-icon>
                        </v-btn>
                    </template>
                </v-tooltip>
            </div>
        </div>
      </div>
    </div>

    <v-dialog v-model="modal.show" max-width="500" persistent>
      <v-card class="rounded-xl overflow-hidden" :class="themeStore.currentMode === 'light' ? 'bg-white shadow-lg' : 'bg-grey-darken-4 border-thin'">

        <div class="pa-5 border-b d-flex align-center justify-space-between" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5' : 'bg-surface-variant'">
          <div class="d-flex align-center">
             <div class="rounded-lg d-flex align-center justify-center mr-3" style="width: 40px; height: 40px; background-color: rgba(25, 118, 210, 0.1);">
                <v-icon color="primary" size="22">{{ modal.isEditing ? 'mdi-credit-card-edit' : 'mdi-credit-card-plus' }}</v-icon>
             </div>
             <div>
                <div class="text-subtitle-1 font-weight-black leading-none mb-1">
                  {{ modal.isEditing ? 'Editar Forma de Pagamento' : 'Nova Forma de Pagamento' }}
                </div>
                <div class="text-caption opacity-60 font-weight-medium">Configuração de finanças</div>
             </div>
          </div>
          <v-btn icon="mdi-close" variant="text" size="small" color="grey" @click="closeModal()"></v-btn>
        </div>

        <v-card-text class="pa-6">
          <v-alert v-if="!modal.isEditing" type="info" variant="tonal" density="compact" class="mb-6 text-caption font-weight-medium">
             Ao criar uma forma de pagamento, ela ficará imediatamente disponível para os vendedores no fechamento de pedidos.
          </v-alert>

          <div class="mb-5">
              <div class="d-flex align-center mb-1">
                 <span class="text-caption font-weight-bold text-uppercase opacity-70">Nome da Forma *</span>
                 <v-tooltip text="O nome exato que aparecerá no PDV e na fatura." location="top" content-class="custom-tooltip">
                    <template v-slot:activator="{ props }">
                       <v-icon v-bind="props" size="14" class="ml-2 opacity-50 cursor-pointer">mdi-help-circle-outline</v-icon>
                    </template>
                 </v-tooltip>
              </div>
              <v-text-field
                v-model="modal.data.name"
                variant="outlined"
                density="comfortable"
                placeholder="Ex: Cartão de Crédito 3x, PIX..."
                hide-details
                color="primary"
                class="font-weight-medium"
              ></v-text-field>
          </div>

          <div class="mb-5">
              <div class="d-flex align-center mb-1">
                 <span class="text-caption font-weight-bold text-uppercase opacity-70">Sincronização GestãoClick</span>
                 <v-tooltip text="Deixe em branco se não souber. Usado apenas pela Holding para sincronizar relatórios com o ERP." location="top" content-class="custom-tooltip">
                    <template v-slot:activator="{ props }">
                       <v-icon v-bind="props" size="14" class="ml-2 opacity-50 cursor-pointer">mdi-help-circle-outline</v-icon>
                    </template>
                 </v-tooltip>
              </div>
              <v-text-field
                v-model="modal.data.gestao_click_id"
                variant="outlined"
                density="comfortable"
                placeholder="Ex: 1045, 992..."
                hide-details
                color="primary"
                class="font-mono"
              ></v-text-field>
          </div>

          <v-card class="pa-3 rounded-lg border-thin d-flex align-center justify-space-between mb-2" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5' : 'bg-surface'">
              <div class="d-flex flex-column">
                  <span class="font-weight-bold text-body-2">Disponibilidade do Método</span>
                  <span class="text-caption opacity-60">Exibir para vendedores no painel?</span>
              </div>
              <v-switch
                v-model="modal.data.is_active"
                color="success"
                hide-details
                inset
                density="compact"
              ></v-switch>
          </v-card>

          <v-expand-transition>
              <div v-if="modal.isEditing && modal.data.id" class="mt-6 pt-4 border-t border-opacity-10">
                 <div class="text-[10px] font-weight-bold text-uppercase opacity-50 mb-2">Metadados do Registro</div>
                 <div class="d-flex justify-space-between text-caption font-mono opacity-70">
                     <span>ID Interno:</span>
                     <span>{{ modal.data.id.split('-')[0] }}...</span>
                 </div>
                 <div class="d-flex justify-space-between text-caption font-mono opacity-70 mt-1">
                     <span>Vínculos (Uso):</span>
                     <span>{{ getUsageCountForEdit(modal.data.id) }} lançamentos</span>
                 </div>
              </div>
          </v-expand-transition>

        </v-card-text>

        <v-card-actions class="pa-4 border-t justify-end" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5' : 'bg-black-20'">
          <v-btn variant="text" class="text-none font-weight-bold px-4" @click="closeModal()">Cancelar</v-btn>
          <v-btn color="primary" variant="flat" class="text-none font-weight-black px-6" :loading="saving" :disabled="!modal.data.name" @click="saveMethod">
            Salvar Registro
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { supabase } from '@/api/supabase';
import { useThemeStore } from '@/stores/themeStore';
import { useAppStore } from '@/stores/app';

const themeStore = useThemeStore();
const appStore = useAppStore();

const TABLE_NAME = 'finance_payment_methods';

const loading = ref(false);
const saving = ref(false);
const methods = ref<any[]>([]);
const searchQuery = ref('');
const statusFilter = ref('active');

const modal = ref({
  show: false,
  isEditing: false,
  data: { id: null as string | null, name: '', gestao_click_id: '', is_active: true }
});

const zebraClass = (i: number) => themeStore.currentMode !== 'light' ? (i % 2 === 0 ? 'zebra-dark-a' : 'zebra-dark-b') : (i % 2 === 0 ? 'zebra-light-a' : 'zebra-light-b');

const filteredMethods = computed(() => {
  let result = methods.value;

  if (searchQuery.value) {
    const q = searchQuery.value.toLowerCase();
    result = result.filter(m => m.name.toLowerCase().includes(q) || (m.gestao_click_id && m.gestao_click_id.toLowerCase().includes(q)));
  }

  if (statusFilter.value === 'active') result = result.filter(m => m.is_active !== false);
  if (statusFilter.value === 'inactive') result = result.filter(m => m.is_active === false);

  return result.sort((a, b) => a.name.localeCompare(b.name));
});

const fetchMethods = async () => {
  loading.value = true;
  try {
    const { data, error } = await supabase.from(TABLE_NAME).select('*').order('name');
    if (error) throw error;

    methods.value = (data || []).map(m => ({
        ...m,
        is_active: m.is_active ?? true,
        usageCount: 0,
        usageLoading: true
    }));

    fetchUsageCounts();

  } catch (err: any) {
    appStore.showSnackbar(`Erro ao buscar: ${err.message}`, 'error');
  } finally {
    loading.value = false;
  }
};

const fetchUsageCounts = async () => {
    for (let method of methods.value) {
        try {
            const { count: countRec } = await supabase
                .from('finance_receivables')
                .select('id', { count: 'exact', head: true })
                .or(`payment_method_id.eq.${method.id},payment_method.eq.${method.name}`);

            const { count: countPay } = await supabase
                .from('finance_payables')
                .select('id', { count: 'exact', head: true })
                .or(`payment_method_id.eq.${method.id},payment_method.eq.${method.name}`);

            method.usageCount = (countRec || 0) + (countPay || 0);
        } catch (e) {
            method.usageCount = 0;
        } finally {
            method.usageLoading = false;
        }
    }
};

const getUsageCountForEdit = (id: string) => {
    const method = methods.value.find(m => m.id === id);
    return method ? method.usageCount : 0;
};

const openModal = (method: any = null) => {
  if (method) {
    modal.value.isEditing = true;
    modal.value.data = { ...method };
  } else {
    modal.value.isEditing = false;
    modal.value.data = { id: null, name: '', gestao_click_id: '', is_active: true };
  }
  modal.value.show = true;
};

const cloneMethod = (method: any) => {
    modal.value.isEditing = false;
    modal.value.data = {
        id: null,
        name: `${method.name} (Cópia)`,
        gestao_click_id: '',
        is_active: true
    };
    modal.value.show = true;
};

const closeModal = () => { modal.value.show = false; };

const saveMethod = async () => {
  saving.value = true;
  try {
    const payload = {
      name: modal.value.data.name,
      gestao_click_id: modal.value.data.gestao_click_id || null,
      is_active: modal.value.data.is_active
    };

    if (modal.value.isEditing) {
      const { error } = await supabase.from(TABLE_NAME).update(payload).eq('id', modal.value.data.id);
      if (error) throw error;
      appStore.showSnackbar('Forma atualizada com sucesso!', 'success');
    } else {
      const { error } = await supabase.from(TABLE_NAME).insert([payload]);
      if (error) throw error;
      appStore.showSnackbar('Forma registrada com sucesso!', 'success');
    }

    closeModal();
    fetchMethods();
  } catch (err: any) {
    if (err.code === '23505') {
        appStore.showSnackbar(`Já existe uma forma com este nome.`, 'error');
    } else {
        appStore.showSnackbar(`Erro ao salvar: ${err.message}`, 'error');
    }
  } finally {
    saving.value = false;
  }
};

const toggleStatus = async (method: any) => {
  const newStatus = !method.is_active;
  try {
    const { error } = await supabase.from(TABLE_NAME).update({ is_active: newStatus }).eq('id', method.id);
    if (error) throw error;
    method.is_active = newStatus;
    appStore.showSnackbar(newStatus ? 'Forma ativada e visível!' : 'Forma ocultada do sistema.', 'success');
  } catch (err: any) {
    appStore.showSnackbar(`Erro: ${err.message}`, 'error');
  }
};

const confirmDelete = async (method: any) => {
    if (method.usageCount > 0) {
        appStore.showSnackbar(`Esta forma está vinculada a ${method.usageCount} lançamentos. Use o botão Ocultar para não quebrar o banco.`, 'warning');
        return;
    }

    if (!confirm(`Tem certeza que deseja apagar DEFINITIVAMENTE a forma "${method.name}"?\nEsta ação não pode ser desfeita.`)) return;

    try {
        const { error } = await supabase.from(TABLE_NAME).delete().eq('id', method.id);
        if (error) throw error;
        appStore.showSnackbar('Forma apagada com sucesso.', 'success');
        methods.value = methods.value.filter(m => m.id !== method.id);
    } catch (e: any) {
        appStore.showSnackbar(`Erro ao apagar: ${e.message}`, 'error');
    }
};

const getIconForMethod = (name: string) => {
  const n = name.toLowerCase();
  if (n.includes('pix')) return 'mdi-qrcode-scan';
  if (n.includes('boleto')) return 'mdi-barcode';
  if (n.includes('dinheiro') || n.includes('espécie')) return 'mdi-cash';
  if (n.includes('crédito') || n.includes('credito')) return 'mdi-credit-card-outline';
  if (n.includes('débito') || n.includes('debito')) return 'mdi-credit-card-fast';
  if (n.includes('transferência') || n.includes('ted') || n.includes('depósito')) return 'mdi-bank-transfer';
  return 'mdi-currency-usd';
};

onMounted(() => {
  fetchMethods();
});
</script>

<style scoped>
.btn-rect { border-radius: 4px !important; }
.bg-white-05 { background-color: rgba(255,255,255,0.05); }
.bg-black-20 { background-color: rgba(0,0,0,0.2); }
.border-thin { border: 1px solid rgba(128,128,128,0.2); }

/* Shadow customizada no modal claro */
.shadow-lg { box-shadow: 0 15px 40px rgba(0,0,0,0.15) !important; }

/* Grid Estilo Premium MJ (Redimensionado) */
.grid-header, .grid-row {
    display: grid;
    /* Ajustado para diminuir o nome e dar respiro absoluto aos botões */
    grid-template-columns: minmax(200px, 1fr) 180px 180px 120px 200px;
    align-items: stretch;
    width: 100%;
    border-bottom: 1px solid rgba(0,0,0,0.08);
}

.cell {
    padding: 8px 16px;
    display: flex;
    align-items: center;
    border-right: 1px solid rgba(128,128,128,0.1);
    min-height: 56px;
    overflow: hidden;
}

.header-text { font-size: 10px; font-weight: 900; text-transform: uppercase; letter-spacing: 0.5px; }
.list-text { font-size: 13px !important; }
.center { justify-content: center; text-align: center; }

/* Cores da Grid */
.grid-surface-light .cell { background: #f5f7fa; color: rgba(0,0,0,0.6); border-color: rgba(0,0,0,0.08); }
.grid-surface-dark .cell { background: rgba(255,255,255,0.04); color: #ccc; border-color: rgba(255,255,255,0.05); }

.grid-row-light .cell { border-color: rgba(0,0,0,0.06); }
.grid-row-light:hover .cell { background: #f7fafc !important; }

.grid-row-dark .cell { border-color: rgba(255,255,255,0.05); }
.grid-row-dark:hover .cell { background: rgba(255,255,255,0.05) !important; }

.zebra-light-a .cell { background: #ffffff; }
.zebra-light-b .cell { background: #fafafa; }
.zebra-dark-a .cell { background: rgba(255,255,255,0.01); }
.zebra-dark-b .cell { background: rgba(255,255,255,0.03); }

/* Botões de Ação Quadrados Minimalistas */
.action-btn {
    width: 32px !important;
    height: 32px !important;
    border-radius: 6px !important;
    transition: transform 0.2s ease, box-shadow 0.2s ease !important;
}
.action-btn:hover:not(:disabled) {
    transform: translateY(-2px);
    box-shadow: 0 4px 10px rgba(0,0,0,0.2) !important;
    filter: brightness(1.1);
}
.v-theme--light .action-btn:hover {
    color: white !important;
}

/* Chips Sólidos */
.solid-chip {
    display: inline-flex; align-items: center; justify-content: center;
    height: 24px; padding: 0 10px; border-radius: 6px;
    font-size: 10px; font-weight: 900; color: #fff; text-transform: uppercase;
}
.chip-success { background: #2e7d32; }
.chip-danger { background: #c62828; }

/* Custom Scroll */
.custom-scroll::-webkit-scrollbar { width: 8px; height: 8px; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.3); border-radius: 4px; }
.custom-scroll::-webkit-scrollbar-track { background: transparent; }

.grayscale { filter: grayscale(100%); }
</style>
