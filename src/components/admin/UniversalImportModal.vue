<template>
  <v-dialog
    v-model="dialogVisible"
    fullscreen
    transition="dialog-bottom-transition"
    class="universal-import-modal"
    :scrim="false"
  >
    <v-card class="d-flex flex-column fill-height bg-grey-lighten-5 rounded-0">

      <div class="modal-header bg-white border-b px-6 py-3 d-flex align-center justify-space-between flex-shrink-0 elevation-1" style="z-index: 20;">
        <div class="d-flex align-center gap-4">
          <div class="icon-box bg-blue-darken-3 text-white rounded-lg pa-3 elevation-2">
            <v-icon size="24">{{ currentStep === 1 ? 'mdi-upload' : 'mdi-table-edit' }}</v-icon>
          </div>
          <div>
            <div class="text-subtitle-1 font-weight-black text-uppercase text-grey-darken-3">Importador Universal</div>
            <div class="text-caption text-grey-darken-1">
              {{ currentStepDescription }}
            </div>
          </div>
        </div>

        <div class="d-flex align-center gap-3">
          <div v-if="currentStep > 1" class="d-flex align-center bg-grey-lighten-4 rounded px-3 py-1 border">
            <div class="d-flex flex-column mr-4 border-e pr-4">
              <span class="text-caption font-weight-bold text-grey">Registros</span>
              <span class="text-h6 font-weight-black leading-none text-blue-darken-2">{{ rows.length }}</span>
            </div>
             <div class="d-flex flex-column">
              <span class="text-caption font-weight-bold text-grey">Valor Total</span>
              <span class="text-h6 font-weight-black leading-none text-green-darken-2">{{ formatCurrency(totalValue) }}</span>
            </div>
          </div>

          <v-divider vertical class="mx-2"></v-divider>

          <v-btn variant="text" color="grey-darken-2" prepend-icon="mdi-close" @click="close">
            Cancelar / Fechar
          </v-btn>
        </div>
      </div>

      <div class="flex-grow-1 overflow-hidden d-flex flex-column relative">

        <v-fade-transition mode="out-in">
          <div v-if="currentStep === 1" class="fill-height d-flex flex-column align-center justify-center bg-grey-lighten-5">
            <div
                class="upload-zone d-flex flex-column align-center justify-center bg-white elevation-2"
                :class="{'dragging': isDragging}"
                @click="triggerFile"
                @dragover.prevent="isDragging = true"
                @dragleave.prevent="isDragging = false"
                @drop.prevent="handleDrop"
              >
                <div class="icon-circle mb-6 bg-blue-lighten-5">
                  <v-icon size="48" color="blue-darken-2">mdi-cloud-upload</v-icon>
                </div>
                <h3 class="text-h6 font-weight-black mb-2 text-grey-darken-3">Arraste sua planilha aqui</h3>
                <p class="text-body-2 text-grey-darken-1 mb-8 text-center" style="max-width: 300px;">
                  Suportamos arquivos .xlsx, .xls e .csv. O sistema tentará identificar as colunas automaticamente.
                </p>
                <v-btn color="blue-darken-2" size="large" prepend-icon="mdi-folder-open" class="px-8 text-none font-weight-bold rounded-lg elevation-2">
                  Buscar no Computador
                </v-btn>
                <input type="file" ref="fileInput" class="d-none" accept=".xlsx, .xls, .csv" @change="handleFileSelect">
            </div>
          </div>
        </v-fade-transition>

        <v-fade-transition mode="out-in">
          <div v-if="currentStep === 2" class="fill-height d-flex flex-column">

            <div class="toolbar bg-white px-6 py-2 border-b d-flex align-center justify-space-between gap-4">

              <div class="d-flex align-center flex-grow-1 gap-2">
                 <v-expand-transition>
                    <div v-if="selectedIds.size > 0" class="d-flex align-center bg-blue-grey-lighten-5 px-3 py-1 rounded border border-blue-grey-lighten-4">
                       <span class="text-caption font-weight-black text-blue-grey-darken-3 mr-3">{{ selectedIds.size }} SELECIONADOS</span>

                       <v-menu>
                          <template v-slot:activator="{ props }">
                             <v-btn v-bind="props" size="small" color="blue-darken-2" variant="flat" prepend-icon="mdi-domain" class="mr-2 font-weight-bold text-none">
                                Definir Empresa
                             </v-btn>
                          </template>
                          <v-list density="compact" nav>
                             <v-list-item v-for="comp in companiesList" :key="comp.id" @click="bulkUpdate('company_id', comp.id)" :title="comp.trade_name || comp.name"></v-list-item>
                          </v-list>
                       </v-menu>

                        <v-menu>
                          <template v-slot:activator="{ props }">
                             <v-btn v-bind="props" size="small" color="purple-darken-2" variant="flat" prepend-icon="mdi-shape" class="mr-2 font-weight-bold text-none">
                                Plano de Contas
                             </v-btn>
                          </template>
                          <v-list density="compact" nav height="300">
                             <v-list-item v-for="cat in chartList" :key="cat.id" @click="bulkUpdate('chart_of_accounts_id', cat.id)" :title="cat.name"></v-list-item>
                          </v-list>
                       </v-menu>

                       <v-btn size="small" color="red" variant="text" icon="mdi-close" @click="selectedIds.clear()"></v-btn>
                    </div>
                 </v-expand-transition>

                 <v-text-field
                    v-model="filters.search"
                    density="compact"
                    variant="outlined"
                    label="Filtrar dados importados"
                    prepend-inner-icon="mdi-magnify"
                    hide-details
                    bg-color="white"
                    class="ml-auto"
                    style="max-width: 300px;"
                 ></v-text-field>

                 <v-menu :close-on-content-click="false">
                    <template v-slot:activator="{ props }">
                       <v-btn v-bind="props" variant="outlined" color="grey-darken-2" prepend-icon="mdi-filter-variant">
                          Filtro de Datas
                       </v-btn>
                    </template>
                    <v-card min-width="300" class="pa-4">
                       <div class="text-subtitle-2 mb-2 font-weight-bold">Filtrar Vencimento</div>
                       <v-text-field v-model="filters.startDate" type="date" label="De" density="compact" variant="outlined"></v-text-field>
                       <v-text-field v-model="filters.endDate" type="date" label="Até" density="compact" variant="outlined"></v-text-field>
                    </v-card>
                 </v-menu>
              </div>
            </div>

            <div class="grid-header sticky-header bg-grey-lighten-4 border-b">
               <div class="cell center" style="width: 50px">
                  <v-checkbox-btn :model-value="areAllSelected" @update:model-value="toggleSelectAll" density="compact" color="primary"></v-checkbox-btn>
               </div>
               <div class="cell" style="width: 110px">Vencimento</div>
               <div class="cell flex-grow-1">Descrição / Fornecedor</div>
               <div class="cell right" style="width: 120px">Valor</div>
               <div class="cell" style="width: 180px">Plano de Contas</div>
               <div class="cell" style="width: 160px">Empresa/Loja</div>
               <div class="cell center" style="width: 100px">Status</div>
               <div class="cell center" style="width: 60px">Ações</div>
            </div>

            <div class="grid-body flex-grow-1 overflow-y-auto custom-scroll bg-white">
                <div
                  v-for="(row, index) in filteredRows"
                  :key="index"
                  class="grid-row border-b"
                  :class="[
                     index % 2 === 0 ? 'bg-white' : 'bg-grey-lighten-5',
                     selectedIds.has(index) ? 'bg-blue-lighten-5' : ''
                  ]"
                >
                   <div class="cell center" style="width: 50px">
                      <v-checkbox-btn :model-value="selectedIds.has(index)" @update:model-value="toggleSelection(index)" density="compact" color="primary"></v-checkbox-btn>
                   </div>

                   <div class="cell" style="width: 110px">
                      <input type="date" v-model="row.due_date" class="editable-input font-mono text-caption" />
                   </div>

                   <div class="cell flex-grow-1 d-flex flex-column py-1 justify-center">
                      <input type="text" v-model="row.description" class="editable-input font-weight-bold" placeholder="Descrição" />
                      <input type="text" v-model="row.entity_name" class="editable-input text-caption text-grey-darken-1" placeholder="Fornecedor" />
                   </div>

                   <div class="cell right" style="width: 120px">
                      <input type="number" step="0.01" v-model="row.value" class="editable-input text-right font-mono font-weight-black" />
                   </div>

                   <div class="cell" style="width: 180px">
                      <select v-model="row.chart_of_accounts_id" class="editable-select text-caption">
                         <option :value="null">- Selecione -</option>
                         <option v-for="opt in chartList" :key="opt.id" :value="opt.id">{{ opt.name }}</option>
                      </select>
                   </div>

                   <div class="cell" style="width: 160px">
                      <select v-model="row.company_id" class="editable-select text-caption">
                         <option :value="null">- Selecione -</option>
                         <option v-for="opt in companiesList" :key="opt.id" :value="opt.id">{{ opt.trade_name }}</option>
                      </select>
                   </div>

                   <div class="cell center" style="width: 100px">
                       <v-chip
                        size="x-small"
                        :color="getStatusColor(row.status)"
                        variant="flat"
                        class="font-weight-bold text-uppercase"
                        @click="toggleStatus(row)"
                       >
                          {{ row.status || 'Pendente' }}
                       </v-chip>
                   </div>

                   <div class="cell center" style="width: 60px">
                      <v-btn icon size="x-small" variant="text" color="grey" @click="removeRow(index)">
                         <v-icon>mdi-delete</v-icon>
                      </v-btn>
                   </div>
                </div>

                <div v-if="filteredRows.length === 0" class="pa-8 text-center text-grey">
                   <v-icon size="48" class="mb-2">mdi-filter-off</v-icon>
                   <div>Nenhum registro encontrado com os filtros atuais.</div>
                </div>
            </div>

            <div class="modal-footer bg-white border-t px-6 py-4 d-flex align-center justify-space-between flex-shrink-0">
               <div class="d-flex align-center gap-4">
                  <v-switch
                     v-model="options.launchInFinancial"
                     color="success"
                     label="Lançar no Financeiro"
                     hide-details
                     density="compact"
                     inset
                  ></v-switch>
                  <div class="text-caption text-grey-darken-1" style="max-width: 300px;">
                     Se desativado, apenas registrará o pedido sem criar contas a pagar/receber.
                  </div>
               </div>

               <div class="d-flex align-center gap-3">
                  <v-btn variant="outlined" size="large" @click="currentStep = 1" v-if="!props.preLoadedData">
                     Voltar p/ Upload
                  </v-btn>

                  <v-btn
                     color="blue-darken-3"
                     size="large"
                     class="px-8 font-weight-black elevation-2"
                     prepend-icon="mdi-check-all"
                     @click="finalizeImport"
                     :loading="processing"
                  >
                     Confirmar Importação ({{ rows.length }})
                  </v-btn>
               </div>
            </div>

          </div>
        </v-fade-transition>

      </div>
    </v-card>
  </v-dialog>
</template>

<script setup lang="ts">
import { ref, reactive, computed, watch, onMounted } from 'vue';
import * as XLSX from 'xlsx';
import { format, parseISO } from 'date-fns';

interface SystemField {
    key: string;
    label: string;
    required?: boolean;
    type?: 'date' | 'number' | 'string' | 'reference';
    validationList?: any[];
}

const props = defineProps<{
  show: boolean,
  systemFields: SystemField[],
  preLoadedData?: any[] // Support for API data (Sync)
}>();

const emit = defineEmits(['update:show', 'import']);

// --- Estado ---
const dialogVisible = computed({
  get: () => props.show,
  set: (val) => emit('update:show', val)
});

const currentStep = ref(1);
const processing = ref(false);
const rows = ref<any[]>([]);
const isDragging = ref(false);
const fileInput = ref<HTMLInputElement | null>(null);
const options = reactive({ launchInFinancial: true });

// Filtros internos
const filters = reactive({
   search: '',
   startDate: '',
   endDate: ''
});

// Seleção
const selectedIds = ref(new Set<number>());

// --- Helpers de Listas (Extraídos dos systemFields para facilitar) ---
const chartList = computed(() => {
   const field = props.systemFields.find(f => f.key === 'chart_of_accounts_id');
   return field?.validationList || [];
});

const companiesList = computed(() => {
   const field = props.systemFields.find(f => f.key === 'company_id');
   return field?.validationList || [];
});

// --- Computed Stats ---
const totalValue = computed(() => rows.value.reduce((acc, row) => acc + (Number(row.value) || 0), 0));
const currentStepDescription = computed(() => {
    if(currentStep.value === 1) return 'Faça upload ou aguarde o carregamento dos dados.';
    return 'Revise os dados, faça correções em massa e confirme a importação.';
});

// --- Watchers para Dados Pré-carregados ---
watch(() => props.show, (newVal) => {
   if (newVal) {
      if (props.preLoadedData && props.preLoadedData.length > 0) {
         // Se vier dados do pai (Sync), carrega e vai pro passo 2
         loadDataFromArray(props.preLoadedData);
      } else {
         // Se não, reseta para upload
         currentStep.value = 1;
         rows.value = [];
      }
      selectedIds.value.clear();
      filters.search = '';
      filters.startDate = '';
      filters.endDate = '';
   }
});

// --- Lógica de Grid e Filtro ---
const filteredRows = computed(() => {
   let result = rows.value.map((r, i) => ({...r, _originalIndex: i})); // Keep track of index

   if (filters.search) {
      const lower = filters.search.toLowerCase();
      result = result.filter(r =>
         (r.description && r.description.toLowerCase().includes(lower)) ||
         (r.entity_name && r.entity_name.toLowerCase().includes(lower))
      );
   }

   if (filters.startDate) {
      result = result.filter(r => r.due_date >= filters.startDate);
   }
   if (filters.endDate) {
      result = result.filter(r => r.due_date <= filters.endDate);
   }

   return result;
});

const areAllSelected = computed(() => filteredRows.value.length > 0 && selectedIds.value.size === filteredRows.value.length);

const toggleSelectAll = (val: boolean) => {
   if (val) {
      filteredRows.value.forEach((_, idx) => selectedIds.value.add(idx)); // Use visual index for simplicity in this context or original ID
   } else {
      selectedIds.value.clear();
   }
};

const toggleSelection = (index: number) => {
   if (selectedIds.value.has(index)) selectedIds.value.delete(index);
   else selectedIds.value.add(index);
};

const removeRow = (index: number) => {
   rows.value.splice(index, 1);
   selectedIds.value.delete(index);
};

// --- Carregamento de Dados ---

// 1. Via Array (API Sync)
const loadDataFromArray = (data: any[]) => {
   rows.value = data.map(item => {
      // Tenta mapear automaticamente campos comuns
      let chartId = item.chart_of_accounts_id || null;

      // Se não tiver ID, mas tiver nome (vindo do Excel ou API com join), tenta achar
      if (!chartId && item.categoria) {
         chartId = findIdByName(chartList.value, item.categoria);
      }

      return {
         description: item.description || item.descricao || '',
         entity_name: item.entity_name || item.nome_fornecedor || '',
         value: Number(item.value || item.valor || item.valor_total || 0),
         due_date: formatDateSafe(item.due_date || item.data_vencimento),
         status: normalizeStatus(item.status || item.liquidado),
         chart_of_accounts_id: chartId,
         company_id: item.company_id || null, // Pai deve passar se possível
         notes: item.notes || item.observacoes || ''
      };
   });
   currentStep.value = 2;
};

// 2. Via Arquivo (Upload)
const triggerFile = () => fileInput.value?.click();
const handleFileSelect = (e: any) => { if (e.target.files[0]) processFile(e.target.files[0]); };
const handleDrop = (e: DragEvent) => { isDragging.value = false; if (e.dataTransfer?.files[0]) processFile(e.dataTransfer.files[0]); };

const processFile = (file: File) => {
    const reader = new FileReader();
    reader.onload = (e) => {
        const data = new Uint8Array(e.target?.result as ArrayBuffer);
        const workbook = XLSX.read(data, { type: 'array' });
        const firstSheet = workbook.Sheets[workbook.SheetNames[0]];
        const jsonData = XLSX.utils.sheet_to_json(firstSheet); // Auto header

        rows.value = jsonData.map((row: any) => {
            // Mapping Inteligente Baseado em Nomes Comuns de Colunas
            const keys = Object.keys(row).map(k => k.toLowerCase());

            const getKey = (hints: string[]) => Object.keys(row).find(k => hints.some(h => k.toLowerCase().includes(h)));

            const descKey = getKey(['descri', 'histórico', 'memorial']);
            const valKey = getKey(['valor', 'total', 'líquido']);
            const dateKey = getKey(['vencimento', 'data', 'dt_venc']);
            const entityKey = getKey(['fornecedor', 'nome', 'participante', 'favorecido']);
            const catKey = getKey(['categoria', 'plano', 'natureza', 'classific']);
            const statusKey = getKey(['status', 'situação']);

            // Tratamento de Data do Excel
            let finalDate = new Date().toISOString().split('T')[0];
            if (dateKey && row[dateKey]) {
                if (typeof row[dateKey] === 'number') {
                    finalDate = new Date(Math.round((row[dateKey] - 25569)*86400*1000)).toISOString().split('T')[0];
                } else {
                   // Tentar parsear string PT-BR
                   const parts = String(row[dateKey]).split('/');
                   if(parts.length === 3) finalDate = `${parts[2]}-${parts[1]}-${parts[0]}`;
                   else finalDate = String(row[dateKey]).substring(0,10);
                }
            }

            // Tratamento de Valor
            let finalValue = 0;
            if (valKey && row[valKey]) {
               if (typeof row[valKey] === 'string') {
                  finalValue = parseFloat(row[valKey].replace('R$', '').replace('.', '').replace(',', '.').trim());
               } else {
                  finalValue = Number(row[valKey]);
               }
            }

            // Matching de Plano de Contas
            let chartId = null;
            if (catKey && row[catKey]) {
               chartId = findIdByName(chartList.value, row[catKey]);
            }

            return {
                description: descKey ? row[descKey] : 'Importado via Excel',
                entity_name: entityKey ? row[entityKey] : '',
                value: finalValue,
                due_date: finalDate,
                status: statusKey ? normalizeStatus(row[statusKey]) : 'pendente',
                chart_of_accounts_id: chartId,
                company_id: null,
                notes: ''
            };
        });
        currentStep.value = 2;
    };
    reader.readAsArrayBuffer(file);
};

// --- Helpers de Lógica ---
const findIdByName = (list: any[], search: string) => {
   if (!search) return null;
   const s = String(search).toLowerCase().trim();
   // Busca Exata
   const exact = list.find(i => (i.name || i.trade_name || '').toLowerCase() === s);
   if (exact) return exact.id;

   // Busca Parcial
   const partial = list.find(i => (i.name || i.trade_name || '').toLowerCase().includes(s));
   if (partial) return partial.id;

   return null;
};

const normalizeStatus = (val: any) => {
   const s = String(val).toLowerCase();
   if (['pago', 'liquidado', 'baixa', 'sim', '1', 'true'].some(x => s.includes(x))) return 'pago';
   if (['atrasado', 'vencido'].some(x => s.includes(x))) return 'atrasado';
   return 'pendente';
};

const formatDateSafe = (val: any) => {
   if (!val) return new Date().toISOString().split('T')[0];
   try {
      return String(val).substring(0, 10);
   } catch {
      return new Date().toISOString().split('T')[0];
   }
};

const formatCurrency = (val: number) => {
   return new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(val);
};

const getStatusColor = (status: string) => {
   if (status === 'pago') return 'success';
   if (status === 'atrasado') return 'error';
   return 'orange';
};

const toggleStatus = (row: any) => {
   row.status = row.status === 'pago' ? 'pendente' : 'pago';
};

// --- Ações em Massa ---
const bulkUpdate = (field: string, value: any) => {
   selectedIds.value.forEach(index => {
      // Precisamos mapear o índice visual para o array real se estivermos filtrando,
      // mas aqui selectedIds armazena o indice do filteredRows para simplificar a UI
      const row = filteredRows.value[index];
      if (row) {
         // Atualiza no array original via referência
         const realIndex = row._originalIndex;
         if (rows.value[realIndex]) {
            rows.value[realIndex][field] = value;
         }
      }
   });
   // Feedback visual
   const fieldName = field === 'company_id' ? 'Empresa' : 'Plano de Contas';
   // Aqui você poderia colocar um snackbar se tivesse acesso à store
};

// --- Finalização ---
const finalizeImport = () => {
   processing.value = true;
   setTimeout(() => {
      // Limpa dados auxiliares antes de enviar
      const cleanData = rows.value.map(({ _originalIndex, ...rest }) => ({
         ...rest,
         _options: options
      }));

      emit('import', cleanData);
      emit('update:show', false);
      processing.value = false;
   }, 600);
};

const close = () => {
   emit('update:show', false);
};
</script>

<style scoped lang="scss">
.universal-import-modal {
  font-family: 'Roboto', sans-serif;
}

.modal-header { height: 80px; }
.modal-footer { height: 80px; }

.upload-zone {
  width: 600px; height: 400px;
  border: 2px dashed #E0E0E0; border-radius: 16px;
  cursor: pointer; transition: all 0.3s ease;
}
.upload-zone:hover, .upload-zone.dragging {
  border-color: #1565C0; background-color: #E3F2FD; transform: scale(1.01);
}

.icon-circle {
  width: 80px; height: 80px; border-radius: 50%;
  display: flex; align-items: center; justify-content: center;
}

/* CSS Grid para Tabela (Mesma identidade do AdminMjAccountsPayable) */
.grid-header, .grid-row {
   display: flex;
   align-items: center;
}

.cell {
   padding: 0 12px;
   font-size: 13px;
   overflow: hidden;
   white-space: nowrap;
   text-overflow: ellipsis;
   height: 48px;
   display: flex;
   align-items: center;
}

.grid-header .cell {
   font-weight: 900;
   text-transform: uppercase;
   letter-spacing: 0.5px;
   color: #616161;
   font-size: 11px;
}

.grid-row:hover {
   background-color: #E3F2FD !important; /* Azul bem claro no hover */
}

.center { justify-content: center; text-align: center; }
.right { justify-content: flex-end; text-align: right; }

/* Inputs Editáveis na Tabela - Estilo "Excel" */
.editable-input {
   width: 100%;
   background: transparent;
   border: none;
   outline: none;
   padding: 4px 0;
   border-bottom: 1px solid transparent;
   transition: border 0.2s;
}
.editable-input:focus {
   border-bottom: 1px solid #1565C0;
   background: #fff;
}

.editable-select {
   width: 100%;
   background: transparent;
   border: none;
   outline: none;
   cursor: pointer;
   color: #424242;
}

.custom-scroll::-webkit-scrollbar { width: 8px; }
.custom-scroll::-webkit-scrollbar-thumb { background-color: #BDBDBD; border-radius: 4px; }
.custom-scroll::-webkit-scrollbar-track { background: transparent; }

.gap-2 { gap: 8px; }
.gap-3 { gap: 12px; }
.gap-4 { gap: 16px; }
</style>
