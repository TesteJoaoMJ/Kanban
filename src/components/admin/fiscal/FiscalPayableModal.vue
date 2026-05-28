<template>
  <v-dialog
    :model-value="modelValue"
    @update:model-value="$emit('update:modelValue', $event)"
    fullscreen
    transition="dialog-bottom-transition"
    scrollable
    persistent
  >
    <v-card class="bg-background fill-height d-flex flex-column rounded-0 finance-modal-root">

      <div class="px-6 py-3 bg-grey-darken-4 text-white d-flex justify-space-between align-center flex-shrink-0 elevation-3 z-20 h-64">
        <div class="d-flex align-center gap-6">
          <div class="d-flex flex-column">
            <div class="text-overline font-weight-bold text-grey-lighten-1 lh-1 mb-1" style="letter-spacing: 1px;">Fiscal & Financeiro</div>
            <div class="text-h6 font-weight-black text-white lh-1">Lançamento de Despesa</div>
          </div>
          <v-divider vertical class="border-opacity-25" style="height: 32px;"></v-divider>
          <div class="d-flex flex-column">
             <span class="text-[10px] text-grey-lighten-3 uppercase font-weight-bold">Fornecedor Identificado</span>
             <div class="d-flex align-center gap-2">
                <span class="font-weight-bold text-white text-body-2">{{ note?.emitente_nome || 'Fornecedor Desconhecido' }}</span>
                <span class="bg-white text-black px-2 rounded text-[10px] font-mono font-weight-black">
                    {{ extractedCnpj || note?.emitente_cnpj || 'SEM DOC' }}
                </span>
             </div>
          </div>
        </div>
        <div class="d-flex align-center gap-4">
            <div class="text-right d-none d-md-block">
                <span class="text-[10px] text-grey-lighten-3 uppercase font-weight-bold d-block">Valor da Nota (NFe)</span>
                <span class="text-h5 font-mono font-weight-black text-green-accent-3 lh-1">{{ formatCurrency(note?.valor) }}</span>
            </div>
            <v-divider vertical class="border-opacity-25 h-32 mx-2 d-none d-md-block"></v-divider>
            <v-btn icon variant="tonal" color="white" density="comfortable" @click="close">
                <v-icon>mdi-close</v-icon>
            </v-btn>
        </div>
      </div>

      <div class="d-flex flex-grow-1 overflow-hidden bg-grey-lighten-5">

        <div class="d-flex flex-column border-r border-grey-lighten-3 bg-white flex-shrink-0 shadow-right z-10 sidebar-panel" style="width: 360px;">

            <div class="pa-5 border-b border-grey-lighten-2 bg-grey-lighten-5">
                <div class="text-caption font-weight-black text-uppercase text-grey-darken-3 mb-4 d-flex align-center gap-2">
                    <v-icon color="primary" size="18">mdi-tune</v-icon> Configuração Geral
                </div>

                <v-form ref="configForm">
                    <div class="mb-4">
                        <label class="input-label">O que você está pagando?</label>
                        <input
                            v-model="form.description"
                            type="text"
                            class="std-input w-100 font-weight-medium"
                            placeholder="Ex: Compra de Mercadoria"
                            @input="regenerateInstallmentsNames"
                        >
                    </div>

                    <div class="d-flex gap-3 mb-4">
                        <div class="flex-grow-1">
                            <label class="input-label">Valor Total (R$)</label>
                            <input
                                v-model.number="form.value"
                                type="number"
                                step="0.01"
                                class="std-input w-100 font-mono font-weight-black text-right text-grey-darken-3 bg-blue-grey-lighten-5"
                            >
                        </div>
                        <div style="width: 90px;">
                            <label class="input-label">Parcelas</label>
                            <div class="select-wrapper">
                                <select v-model="form.installments" class="std-input w-100 text-center font-weight-bold">
                                    <option v-for="n in [1,2,3,4,5,6,10,12,18,24,36,48,60]" :key="n" :value="n">{{ n }}x</option>
                                </select>
                            </div>
                        </div>
                    </div>

                    <div class="mb-4">
                        <label class="input-label">Vencimento (1ª Parcela)</label>
                        <input
                            v-model="form.dueDate"
                            type="date"
                            class="std-input w-100 text-center font-mono"
                        >
                    </div>

                    <div class="mb-4">
                        <label class="input-label">Categoria (Plano de Contas)</label>
                        <v-combobox
                            v-model="form.category"
                            :items="['Compra de Mercadoria', 'Serviço', 'Imposto', 'Despesa Operacional', 'Investimento', 'Logística', 'Manutenção']"
                            variant="outlined"
                            density="compact"
                            hide-details
                            class="dense-combobox"
                            bg-color="grey-lighten-5"
                        ></v-combobox>
                    </div>

                    <div>
                        <label class="input-label">Observações</label>
                        <textarea
                            v-model="form.obs"
                            rows="3"
                            class="std-input w-100 py-2"
                            style="height: auto; resize: none; line-height: 1.4;"
                            placeholder="Alguma anotação extra?"
                        ></textarea>
                    </div>
                </v-form>
            </div>

            <div class="flex-grow-1 pa-5 overflow-y-auto bg-white">
                <div class="text-[11px] font-weight-black text-uppercase text-grey-darken-1 mb-3 letter-spacing-1">Resumo da NFe</div>

                <div class="info-card">
                    <div class="info-row">
                        <span class="label">Chave de Acesso</span>
                        <div class="value font-mono text-[10px] break-all bg-grey-lighten-4 pa-2 rounded border mt-1 select-all text-grey-darken-3">
                            {{ note?.chave || note?.chave_acesso }}
                        </div>
                    </div>
                    <div class="d-flex justify-space-between mt-3">
                        <div class="info-row">
                            <span class="label">Data Emissão</span>
                            <span class="value font-mono font-weight-bold">{{ formatDate(note?.data_emissao) }}</span>
                        </div>
                        <div class="info-row text-right">
                            <span class="label">Número NFe</span>
                            <span class="value font-mono font-weight-bold">{{ note?.numero || 'N/A' }}</span>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <div class="d-flex flex-column flex-grow-1 overflow-hidden relative bg-white h-100">

            <div class="px-6 py-2 bg-white border-b border-grey-lighten-2 d-flex justify-space-between align-center shadow-sm z-10" style="height: 68px;">
               <div class="d-flex align-center gap-4">
                  <div class="text-subtitle-2 font-weight-black text-grey-darken-3 d-flex align-center gap-2">
                      <v-icon color="grey-darken-1">mdi-format-list-checks</v-icon>
                      Lista de Parcelas
                  </div>

                  <v-divider vertical class="h-24 opacity-20"></v-divider>

                  <div v-if="Math.abs(totalGenerated - form.value) > 0.05" class="d-flex align-center text-error font-weight-bold text-caption bg-error-lighten-5 px-3 py-2 rounded border border-error-lighten-3 transition-all">
                     <v-icon start size="18">mdi-alert</v-icon>
                     Atenção: A soma das parcelas ({{ formatCurrency(totalGenerated) }}) não bate com o total.
                  </div>
                  <div v-else class="d-flex align-center text-success font-weight-bold text-caption bg-green-lighten-5 px-3 py-2 rounded border border-green-lighten-3 transition-all">
                     <v-icon start size="18">mdi-check-circle</v-icon>
                     Tudo certo! Valores conferem.
                  </div>
               </div>

               <div class="d-flex gap-2">
                  <v-menu location="bottom end" :close-on-content-click="false">
                     <template v-slot:activator="{ props }">
                        <v-btn v-bind="props" variant="flat" color="indigo-lighten-5" class="text-indigo-darken-3 font-weight-bold text-caption border border-indigo-lighten-4" height="36">
                           <v-icon start size="18">mdi-lightning-bolt</v-icon> Opções Rápidas <v-icon end size="16">mdi-chevron-down</v-icon>
                        </v-btn>
                     </template>
                     <v-card min-width="280" class="rounded-lg shadow-xl mt-1">
                        <div class="pa-3 bg-grey-lighten-4 text-caption font-weight-bold text-uppercase border-b">Para todas as parcelas:</div>
                        <v-list density="compact" class="py-2">
                            <v-list-item @click="setAllStatus('pago')" density="compact" link class="mb-1">
                               <template v-slot:prepend><div class="bg-green-lighten-1 rounded-circle pa-1 mr-3"><v-icon color="white" size="14">mdi-check</v-icon></div></template>
                               <span class="text-caption font-weight-bold text-grey-darken-3">Marcar todas como <span class="text-green-darken-1">JÁ PAGO</span></span>
                            </v-list-item>
                            <v-list-item @click="setAllStatus('pendente')" density="compact" link>
                               <template v-slot:prepend><div class="bg-amber-lighten-1 rounded-circle pa-1 mr-3"><v-icon color="white" size="14">mdi-clock</v-icon></div></template>
                               <span class="text-caption font-weight-bold text-grey-darken-3">Marcar todas como <span class="text-amber-darken-4">PAGAR DEPOIS</span></span>
                            </v-list-item>

                            <v-divider class="my-2"></v-divider>

                            <div class="px-3 pb-2">
                               <div class="text-[10px] uppercase font-weight-bold text-grey mb-1">Conta Bancária Padrão</div>
                               <select
                                  class="w-100 pa-2 border rounded text-[11px] bg-white outline-none cursor-pointer hover:bg-grey-lighten-5"
                                  @change="(e) => setAllAccount((e.target as HTMLSelectElement).value)"
                               >
                                  <option value="">Selecionar Banco...</option>
                                  <option v-for="acc in bankAccounts" :key="acc.id" :value="acc.id">{{ acc.name }}</option>
                               </select>
                            </div>
                        </v-list>
                     </v-card>
                  </v-menu>

                  <v-btn variant="text" size="small" color="grey-darken-1" prepend-icon="mdi-refresh" @click="generateInstallmentsPreview(true)" class="text-caption font-weight-bold">
                     Resetar
                  </v-btn>
               </div>
            </div>

            <div class="flex-grow-1 overflow-auto bg-grey-lighten-3 pa-6 relative">
               <div class="excel-wrapper bg-white shadow-sm border border-grey-lighten-2 rounded-lg overflow-hidden">
                  <table class="excel-table">
                     <thead>
                        <tr>
                           <th class="w-12 text-center bg-grey-lighten-4 border-r border-b">#</th>
                           <th class="w-36 text-left bg-grey-lighten-4 border-r border-b pl-3">Vencimento</th>
                           <th class="text-left bg-grey-lighten-4 border-r border-b pl-3" style="min-width: 250px;">Descrição da Parcela</th>
                           <th class="w-40 text-right bg-grey-lighten-4 border-r border-b pr-3">Valor (R$)</th>
                           <th class="w-48 text-center bg-grey-lighten-4 border-r border-b">Já pagou essa parcela?</th>
                           <th class="w-64 text-left bg-grey-lighten-4 border-r border-b pl-3">Qual conta usou?</th>
                           <th class="w-48 text-left bg-grey-lighten-4 border-b pl-3">Forma Pagto</th>
                        </tr>
                     </thead>
                     <tbody>
                        <tr
                           v-for="(item, idx) in generatedInstallments"
                           :key="idx"
                           class="excel-row"
                           :class="{'row-paid': item.status === 'pago', 'row-pending': item.status === 'pendente'}"
                        >
                           <td class="text-center font-mono text-grey-darken-1 bg-grey-lighten-5 border-r border-b text-[12px] select-none font-weight-bold">{{ idx + 1 }}</td>

                           <td class="p-0 border-r border-b">
                              <input
                                 type="date"
                                 v-model="item.due_date"
                                 class="cell-input text-center font-mono"
                              >
                           </td>

                           <td class="p-0 border-r border-b">
                              <input
                                 type="text"
                                 v-model="item.description"
                                 class="cell-input font-weight-medium"
                              >
                           </td>

                           <td class="p-0 border-r border-b">
                              <input
                                 type="number"
                                 v-model.number="item.value"
                                 step="0.01"
                                 class="cell-input text-right font-mono font-weight-black text-grey-darken-4 text-[13px]"
                              >
                           </td>

                           <td class="text-center p-0 border-r border-b vertical-middle bg-white">
                              <div class="d-flex justify-center w-100 h-100 align-center px-2">
                                  <button
                                     class="status-btn-pill"
                                     :class="item.status === 'pago' ? 'btn-paid' : 'btn-pending'"
                                     @click="toggleItemStatus(item)"
                                  >
                                     <v-icon :icon="item.status === 'pago' ? 'mdi-check-circle' : 'mdi-calendar-clock'" size="16" start></v-icon>
                                     {{ item.status === 'pago' ? 'SIM, JÁ PAGUEI' : 'NÃO, PAGAR DEPOIS' }}
                                  </button>
                              </div>
                           </td>

                           <td class="p-0 border-r border-b bg-white relative">
                              <div v-if="item.status === 'pago'" class="cell-select-wrapper animate-fade-in">
                                  <select v-model="item.bank_account_id" class="cell-select font-weight-bold text-grey-darken-3">
                                     <option :value="null" disabled>Selecione o Banco...</option>
                                     <option v-for="acc in bankAccounts" :key="acc.id" :value="acc.id">{{ acc.name }}</option>
                                  </select>
                                  <v-icon icon="mdi-chevron-down" size="14" class="select-arrow text-grey"></v-icon>
                              </div>
                              <div v-else class="cell-placeholder text-amber-darken-4 bg-amber-lighten-5">
                                  <v-icon start size="12" color="amber-darken-4">mdi-calendar-arrow-right</v-icon>
                                  Definir no dia do pagto.
                              </div>
                           </td>

                           <td class="p-0 border-b bg-white relative">
                              <div v-if="item.status === 'pago'" class="cell-select-wrapper animate-fade-in">
                                  <select v-model="item.payment_method_id" class="cell-select">
                                     <option :value="null" disabled>Meio...</option>
                                     <option v-for="pm in paymentMethods" :key="pm.id" :value="pm.id">{{ pm.name }}</option>
                                  </select>
                                  <v-icon icon="mdi-chevron-down" size="14" class="select-arrow text-grey"></v-icon>
                              </div>
                              <div v-else class="cell-placeholder bg-grey-lighten-5 text-grey-lighten-1">
                                  -
                              </div>
                           </td>
                        </tr>
                     </tbody>
                     <tfoot>
                        <tr class="bg-grey-darken-4 text-white font-weight-bold">
                           <td colspan="3" class="text-right pr-4 py-3 border-t border-grey-darken-3 text-uppercase text-[11px] letter-spacing-1 text-grey-lighten-1">
                               Total Validado (Soma das Parcelas)
                           </td>
                           <td class="text-right px-3 py-3 border-t border-grey-darken-3 font-mono font-weight-black text-h6 text-green-accent-3">
                               {{ formatCurrency(totalGenerated) }}
                           </td>
                           <td colspan="3" class="border-t border-grey-darken-3 bg-grey-darken-3">
                               <div v-if="Math.abs(totalGenerated - form.value) > 0.05" class="d-flex align-center px-3 text-red-accent-2 text-caption">
                                   <v-icon start size="14" color="red-accent-2">mdi-alert</v-icon>
                                   Diferença de {{ formatCurrency(form.value - totalGenerated) }}
                               </div>
                           </td>
                        </tr>
                     </tfoot>
                  </table>
               </div>
            </div>

            <div class="px-8 py-5 bg-white border-t border-grey-lighten-2 d-flex justify-end align-center gap-6 flex-shrink-0 z-20 shadow-up">
               <v-btn variant="text" height="50" color="grey-darken-1" class="px-6 font-weight-bold rounded-lg text-button" @click="close">
                  CANCELAR OPERAÇÃO
               </v-btn>
               <v-btn
                  color="green-darken-1"
                  variant="flat"
                  height="50"
                  class="px-10 font-weight-black rounded-lg text-white shadow-soft text-button letter-spacing-1"
                  :loading="loading"
                  @click="confirmLaunch"
                  prepend-icon="mdi-check-decagram"
               >
                   CONFIRMAR LANÇAMENTO
               </v-btn>
            </div>

        </div>
      </div>
    </v-card>
  </v-dialog>
</template>

<script setup lang="ts">
import { ref, reactive, computed, watch, onMounted } from 'vue';
import { supabase } from '@/api/supabase';
import { format, addMonths } from 'date-fns';
import { useAppStore } from '@/stores/app';
import axios from 'axios';

// 1. PROPS & EMITS
const props = defineProps<{
  modelValue: boolean;
  note: any;
  activeCompany?: any;
}>();

const emit = defineEmits(['update:modelValue', 'launched']);

// 2. STATE
const appStore = useAppStore();
const SEFAZ_PROXY_URL = import.meta.env.VITE_SEFAZ_PROXY_URL || 'https://sefaz-proxy-dujl.onrender.com';

const loading = ref(false);
const bankAccounts = ref<any[]>([]);
const paymentMethods = ref<any[]>([]);
const costCenters = ref<any[]>([]);
const generatedInstallments = ref<any[]>([]);
const extractedCnpj = ref('');

const form = reactive({
  description: '',
  value: 0,
  dueDate: '',
  installments: 1,
  category: 'Compra de Mercadoria',
  obs: '',
});

// 3. HELPER FUNCTIONS
const formatCurrency = (val: any) => new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(Number(val) || 0);

const parseDateSafe = (dateStr: string) => {
  if (!dateStr) return new Date();
  const cleanStr = dateStr.substring(0, 10);
  const parts = cleanStr.split('-');
  return new Date(Number(parts[0]), Number(parts[1]) - 1, Number(parts[2]), 12, 0, 0);
};

const formatDate = (d: string) => d ? format(parseDateSafe(d), 'dd/MM/yyyy') : '-';

// 4. DATA LOADING
const loadFinancialAuxData = async () => {
  try {
    const [accs, methods, costs] = await Promise.all([
      supabase.from('finance_accounts').select('id, name').eq('is_active', true),
      supabase.from('finance_payment_methods').select('id, name'),
      supabase.from('finance_cost_centers').select('id, name'),
    ]);
    bankAccounts.value = accs.data || [];
    paymentMethods.value = methods.data || [];
    costCenters.value = costs.data || [];
  } catch (e) {
    console.error('Erro ao carregar dados financeiros', e);
  }
};

// 5. BUSINESS LOGIC
const generateInstallmentsPreview = (forceReset = false) => {
  if (
    !forceReset &&
    generatedInstallments.value.length > 0 &&
    (generatedInstallments.value[0] as any).is_xml_imported
  )
    return;

  const count = Number(form.installments) || 1;
  const total = Number(form.value) || 0;
  const baseDate = parseDateSafe(form.dueDate);
  const baseValue = Number((total / count).toFixed(2));
  const diff = Number((total - baseValue * count).toFixed(2));

  const newInst = [];
  for (let i = 0; i < count; i++) {
    const isLast = i === count - 1;
    const val = isLast ? Number((baseValue + diff).toFixed(2)) : baseValue;
    const date = format(addMonths(baseDate, i), 'yyyy-MM-dd');

    newInst.push({
      description: `${form.description || props.note?.emitente_nome} (${i + 1}/${count})`,
      value: val,
      due_date: date,
      status: 'pendente',
      bank_account_id: null,
      payment_method_id: null,
      is_xml_imported: false,
    });
  }
  generatedInstallments.value = newInst;
};

const initializeForm = async (note: any) => {
  if(!note) return;

  extractedCnpj.value = (note.emitente_cnpj || '').replace(/\D/g, '');

  form.description = note.emitente_nome || 'Lançamento NFe';
  form.value = Number(note.valor);
  form.installments = 1;
  form.obs = `Ref. NFe ${note.numero || (note.chave ? note.chave.substring(25, 34) : 'S/N')}`;

  const emissionDateStr = note.data_emissao
    ? note.data_emissao.substring(0, 10)
    : new Date().toISOString().substring(0, 10);
  const emissionDateObj = parseDateSafe(emissionDateStr);
  const initialDueDate = addMonths(emissionDateObj, 1);
  form.dueDate = format(initialDueDate, 'yyyy-MM-dd');

  // XML Import Logic
let imported = false;
  const cnpj = props.activeCompany?.cnpj?.replace(/\D/g, '');
  const id = note.chave; // SEMPRE USAR A CHAVE DE ACESSO!

  if (id && cnpj) {
    try {
      const url = `${SEFAZ_PROXY_URL}/api/baixar-xml/${id}?cnpj=${cnpj}`;
      const response = await axios.get(url, { responseType: 'text' });
      const parser = new DOMParser();
      const xmlDoc = parser.parseFromString(response.data, 'text/xml');

      if (!extractedCnpj.value) {
          const emitCnpj = xmlDoc.querySelector('emit > CNPJ');
          const emitCpf = xmlDoc.querySelector('emit > CPF');
          if (emitCnpj) extractedCnpj.value = emitCnpj.textContent || '';
          else if (emitCpf) extractedCnpj.value = emitCpf.textContent || '';
      }

      const dups = xmlDoc.querySelectorAll('dup');

      if (dups && dups.length > 0) {
        const extracted = [];
        for (let i = 0; i < dups.length; i++) {
          const el = dups[i];
          const vDup = el.querySelector('vDup')?.textContent;
          const dVenc = el.querySelector('dVenc')?.textContent;

          if (vDup && dVenc) {
            extracted.push({
              description: `${note.emitente_nome} (Parc. ${i + 1}/${dups.length})`,
              value: Number(vDup),
              due_date: dVenc,
              status: 'pendente',
              bank_account_id: null,
              payment_method_id: null,
              is_xml_imported: true,
            });
          }
        }

        if (extracted.length > 0) {
          form.installments = extracted.length;
          generatedInstallments.value = extracted;
          if(extracted[0].due_date) form.dueDate = extracted[0].due_date;
          imported = true;
          appStore.showSnackbar(`${extracted.length} parcelas importadas do XML!`, 'success');
        }
      }
      else {
          console.log("Nenhuma duplicata (dup) encontrada. Assumindo parcela única.");
          form.installments = 1;
          generateInstallmentsPreview(true);
          imported = true;
      }

    } catch (e) {
      console.warn('Erro ao processar XML para parcelas:', e);
    }
  }

  if (!imported) {
    generateInstallmentsPreview(true);
  }
};

const confirmLaunch = async () => {
  loading.value = true;
  try {
    if (Math.abs(totalGenerated.value - Number(form.value)) > 0.05) {
      if (!confirm('O valor total das parcelas difere do valor da nota. Continuar?')) {
        loading.value = false;
        return;
      }
    }

    const payloads = generatedInstallments.value.map((item) => ({
      description: item.description,
      entity_name: props.note.emitente_nome,
      value: Number(item.value),
      due_date: item.due_date,
      status: item.status,
      category: form.category,
      notes: `${item.description} - Ref: ${props.note.chave ? props.note.chave.substring(0, 10) : ''}... - CNPJ: ${props.note.emitente_cnpj || extractedCnpj.value} - ${form.obs || ''}`,
      origin_nfe_key: props.note.chave,
      payment_date: item.status === 'pago' ? new Date().toISOString() : null,
      bank_account_id: item.status === 'pago' ? item.bank_account_id : null,
      payment_method_id: item.status === 'pago' ? item.payment_method_id : null,
    }));

    const { error } = await supabase.from('finance_payables').insert(payloads);
    if (error) throw error;

    await supabase
      .from('dfe_entries')
      .update({ status_processamento: 'contas_a_pagar_gerado' })
      .eq('chave', props.note.chave);

    emit('launched', payloads);
    close();
    appStore.showSnackbar('Lançamento realizado com sucesso!', 'success');
  } catch (e: any) {
    console.error(e);
    appStore.showSnackbar('Erro ao lançar: ' + e.message, 'error');
  } finally {
    loading.value = false;
  }
};

const close = () => emit('update:modelValue', false);

// 6. COMPUTEDS & WATCHERS
const totalGenerated = computed(() => {
  return generatedInstallments.value.reduce((acc, item) => acc + (Number(item.value) || 0), 0);
});

const regenerateInstallmentsNames = () => {
  generatedInstallments.value.forEach((item, idx) => {
    item.description = `${form.description || props.note?.emitente_nome} (${idx + 1}/${generatedInstallments.value.length})`;
  });
};

const toggleItemStatus = (item: any) => {
  item.status = item.status === 'pago' ? 'pendente' : 'pago';

  // UX Melhorada: Se mudar para pago e não tiver conta, já seta a primeira
  if (item.status === 'pago' && !item.bank_account_id && bankAccounts.value.length > 0) {
      item.bank_account_id = bankAccounts.value[0].id;
  }
};

const setAllStatus = (status: 'pago' | 'pendente') => {
  generatedInstallments.value.forEach((i) => {
      i.status = status;
      // Auto-set bank if paying all
      if (status === 'pago' && !i.bank_account_id && bankAccounts.value.length > 0) {
          i.bank_account_id = bankAccounts.value[0].id;
      }
  });
};

const setAllAccount = (accountId: string) => {
  if (!accountId) return;
  generatedInstallments.value.forEach((i) => {
    if (i.status === 'pago') i.bank_account_id = accountId;
  });
};

// Main Watcher
watch(
  () => props.note,
  async (newNote) => {
    if (newNote && props.modelValue) {
      await initializeForm(newNote);
    }
  },
  { immediate: true }
);

// Form Reactive Watcher
watch(() => [form.installments, form.value, form.dueDate], () => {
  generateInstallmentsPreview(true);
});

// 7. LIFECYCLE
onMounted(() => {
  loadFinancialAuxData();
});
</script>

<style scoped lang="scss">
.finance-modal-root {
    font-family: 'Inter', 'Roboto', sans-serif;
}

/* SIDEBAR INPUTS */
.input-label {
    font-size: 10px;
    font-weight: 800;
    text-transform: uppercase;
    color: #616161;
    display: block;
    margin-bottom: 4px;
    letter-spacing: 0.05em;
}

.std-input {
    height: 38px;
    border: 1px solid #E0E0E0;
    border-radius: 6px;
    background-color: #FAFAFA;
    padding: 0 10px;
    font-size: 13px;
    outline: none;
    transition: all 0.2s;
    color: #424242;

    &:focus {
        border-color: #2196F3;
        background-color: #FFF;
        box-shadow: 0 0 0 3px rgba(33, 150, 243, 0.1);
    }
}
.select-wrapper {
    position: relative;
    &::after {
        content: "▼";
        font-size: 8px;
        position: absolute;
        right: 8px;
        top: 50%;
        transform: translateY(-50%);
        pointer-events: none;
        color: #757575;
    }
}

.dense-combobox :deep(.v-field__input) {
    min-height: 38px;
    padding-top: 0;
    padding-bottom: 0;
    font-size: 13px;
}

/* EXCEL GRID STYLES */
.excel-wrapper {
    width: 100%;
}

.excel-table {
    width: 100%;
    border-collapse: separate;
    border-spacing: 0;
    table-layout: fixed;
}

.excel-table th {
    font-size: 11px;
    font-weight: 800;
    color: #616161;
    padding: 10px 12px;
    text-transform: uppercase;
    letter-spacing: 0.05em;
    position: sticky;
    top: 0;
    z-index: 10;
}

.excel-table td {
    vertical-align: middle;
    height: 56px; /* Aumentado para mais respiro */
    position: relative;
    border-bottom: 1px solid #E0E0E0;
}

/* Inputs da Tabela */
.cell-input {
    width: 100%;
    height: 100%;
    position: absolute;
    top: 0;
    left: 0;
    padding: 0 12px;
    border: none;
    outline: none;
    background: transparent;
    font-size: 13px;
    color: #212121;

    &:focus {
        background-color: #E3F2FD;
        box-shadow: inset 0 0 0 2px #2196F3;
        z-index: 5;
    }
}

.cell-select-wrapper {
    position: relative;
    width: 100%;
    height: 100%;
    display: flex;
    align-items: center;
}

.cell-select {
    width: 100%;
    height: 100%;
    position: absolute;
    top: 0;
    left: 0;
    padding: 0 28px 0 12px;
    border: none;
    outline: none;
    background: transparent;
    font-size: 12px;
    cursor: pointer;
    appearance: none;
    font-weight: 600;
    color: #424242;

    &:focus {
        background-color: #E3F2FD;
        box-shadow: inset 0 0 0 2px #2196F3;
    }
}

.select-arrow {
    position: absolute;
    right: 8px;
    pointer-events: none;
    color: #757575;
}

.cell-placeholder {
    width: 100%;
    height: 100%;
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 6px;
    font-size: 11px;
    font-weight: 600;
}

/* STATUS BUTTON PILL - MUITO DIDÁTICO */
.status-btn-pill {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    height: 32px;
    width: 160px; /* Largura fixa boa */
    border-radius: 50px; /* Pill shape */
    font-size: 10px;
    font-weight: 900;
    cursor: pointer;
    user-select: none;
    transition: all 0.2s;
    letter-spacing: 0.05em;
    gap: 6px;
    border: 1px solid transparent;

    &:hover { transform: translateY(-1px); box-shadow: 0 4px 8px rgba(0,0,0,0.1); }
    &:active { transform: translateY(0); }
}

.btn-paid {
    background-color: #E8F5E9; /* Verde bem claro */
    color: #2E7D32; /* Verde escuro texto */
    border-color: #A5D6A7;

    &:hover { background-color: #C8E6C9; }
}

.btn-pending {
    background-color: #FFF8E1; /* Laranja/Amarelo bem claro */
    color: #F57C00; /* Laranja escuro texto */
    border-color: #FFE082;

    &:hover { background-color: #FFECB3; }
}

/* LINHAS */
.row-paid td {
    background-color: #F1F8E9 !important;
}
.row-paid input, .row-paid select {
    color: #1B5E20;
    font-weight: 600;
}
.row-paid td:first-child {
    border-left: 4px solid #4CAF50;
}

.row-pending td:first-child {
    border-left: 4px solid #FF9800;
}

.vertical-middle {
    vertical-align: middle;
}

.info-card {
    display: flex;
    flex-direction: column;
    gap: 8px;
}
.info-row {
    display: flex;
    flex-direction: column;
}
.info-row .label {
    font-size: 9px;
    font-weight: 800;
    color: #9E9E9E;
    text-transform: uppercase;
    margin-bottom: 2px;
}
.info-row .value {
    font-size: 12px;
    color: #424242;
}

.shadow-right { box-shadow: 4px 0 24px rgba(0,0,0,0.04); }
.shadow-up { box-shadow: 0 -4px 20px rgba(0,0,0,0.08); }
.shadow-soft { box-shadow: 0 4px 12px rgba(0,128,0,0.2); }
.lh-1 { line-height: 1; }
.lh-1-2 { line-height: 1.2; }
.h-32 { height: 32px; }
.h-64 { height: 64px; }
.min-h-32 { min-height: 32px; }
.animate-fade-in { animation: fadeIn 0.3s ease-out forwards; }
@keyframes fadeIn { from { opacity: 0; transform: translateY(-2px); } to { opacity: 1; transform: translateY(0); } }
</style>
