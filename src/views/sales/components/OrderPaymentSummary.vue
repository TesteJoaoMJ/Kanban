<template>
  <div class="payment-summary-container h-100 d-flex flex-column font-sans">

    <div class="d-flex flex-column flex-sm-row align-start align-sm-center justify-space-between gap-3 mb-4 px-1 flex-shrink-0">
        <div class="d-flex align-center gap-2">
            <div class="icon-box-sm rounded-0 d-flex align-center justify-center" :class="isLight ? 'bg-grey-lighten-3 text-grey-darken-3' : 'bg-surface-light text-white'">
                <v-icon size="20">mdi-finance</v-icon>
            </div>
            <div>
                <div class="text-caption font-weight-black text-uppercase opacity-70 letter-spacing-1" :class="textSecondaryClass">Financeiro</div>
                <h3 class="text-subtitle-2 font-weight-black leading-none" :class="textPrimaryClass">Definição de Pagamento</h3>
            </div>
        </div>

        <div class="px-3 py-1 border d-flex align-center justify-center gap-2 w-100 w-sm-auto" :class="[statusBadgeClass, isLight ? 'bg-white' : 'bg-surface']" style="border-radius: 4px;">
            <v-icon size="14" :color="remainingBalance <= 0.01 ? 'success' : 'warning'">
                {{ remainingBalance <= 0.01 ? 'mdi-check-circle' : 'mdi-alert-circle' }}
            </v-icon>
            <span class="text-[10px] font-weight-black text-uppercase" :class="remainingBalance <= 0.01 ? 'text-success' : 'text-warning'">
                {{ remainingBalance <= 0.01 ? 'Totalmente Pago' : 'Pendente' }}
            </span>
        </div>
    </div>

    <v-expand-transition>
        <div v-if="availableCredit > 0" class="mb-4 rounded-0 overflow-hidden border transition-all" :class="useCredit ? 'bg-purple-lighten-5 border-purple-lighten-3' : 'bg-surface border-thin'">
            <div class="px-4 py-3 d-flex flex-column flex-sm-row align-start align-sm-center justify-space-between gap-3">
                <div class="d-flex align-center gap-3">
                    <div class="rounded-0 pa-2" :class="useCredit ? 'bg-purple text-white' : 'bg-grey-lighten-3 text-grey'">
                        <v-icon size="18">mdi-wallet-outline</v-icon>
                    </div>
                    <div>
                        <div class="text-[10px] font-weight-black text-uppercase" :class="useCredit ? 'text-purple-darken-3' : 'text-medium-emphasis'">Saldo em Loja</div>
                        <div class="text-subtitle-2 font-weight-black" :class="useCredit ? 'text-purple-darken-2' : 'text-high-emphasis'">
                            {{ formatCurrency(availableCredit) }}
                        </div>
                    </div>
                </div>

                <div class="d-flex align-center w-100 w-sm-auto justify-space-between justify-sm-end gap-3 border-t border-sm-none pt-2 pt-sm-0 mt-2 mt-sm-0">
                    <span class="text-[10px] font-weight-black text-uppercase d-sm-none" :class="useCredit ? 'text-purple-darken-3' : 'text-medium-emphasis'">Utilizar Saldo?</span>
                    <v-switch
                        v-model="useCredit"
                        color="purple"
                        density="compact"
                        hide-details
                        inset
                        class="ma-0"
                    >
                        <template v-slot:label>
                             <span class="text-[10px] font-weight-black text-uppercase ml-2 d-none d-sm-inline">{{ useCredit ? 'Ativado' : 'Usar Saldo' }}</span>
                        </template>
                    </v-switch>
                </div>
            </div>

            <div v-if="useCredit" class="px-4 pb-4 pt-2 border-t border-purple-lighten-4">
                 <v-row dense align="center" class="row-gap-sm">
                    <v-col cols="12" sm="6">
                        <label class="input-label text-purple-darken-3">Valor a Abater</label>
                        <v-text-field
                            v-model.number="localCreditValue"
                            type="number"
                            variant="outlined"
                            density="compact"
                            hide-details="auto"
                            prefix="R$"
                            class="ui-field bg-white"
                            color="purple"
                            :max="availableCredit"
                            @update:model-value="handleCreditChange"
                        ></v-text-field>
                    </v-col>
                    <v-col cols="12" sm="6">
                        <div class="text-[10px] text-purple-darken-2 font-weight-bold lh-1 opacity-80 mt-2 mt-sm-0">
                            <v-icon size="12" class="mr-1">mdi-information</v-icon>
                            Registrado como "Crédito Loja".
                        </div>
                    </v-col>
                 </v-row>
            </div>
        </div>
    </v-expand-transition>

    <v-form ref="formRef" v-model="formValid" class="flex-grow-1 d-flex flex-column overflow-hidden">
      <div class="d-flex flex-column flex-md-row gap-4 flex-grow-1 overflow-y-auto overflow-md-hidden pb-4 pb-md-0">

        <div class="d-flex flex-column" style="flex: 1; min-width: 280px;">
           <div class="pa-4 rounded-0 border-thin h-100 d-flex flex-column" :class="[bgSurfaceClass]">
              <div class="d-flex align-center gap-2 mb-2">
                 <v-icon color="grey-darken-1" size="16">mdi-text-box-edit-outline</v-icon>
                 <span class="text-[10px] font-weight-black text-uppercase opacity-70" :class="textPrimaryClass">Observações p/ Produção e Fiscal</span>
              </div>
              <v-textarea
                 v-model="localOrderHeader.observation"
                 placeholder="Instruções de entrega, dados fiscais..."
                 variant="outlined"
                 density="comfortable"
                 hide-details
                 class="flex-grow-1 ui-field mt-2"
                 :bg-color="isLight ? 'white' : undefined"
                 no-resize
                 :rows="4"
              ></v-textarea>
           </div>
        </div>

        <div class="d-flex flex-column gap-3 overflow-y-visible overflow-md-auto custom-scroll pr-1" style="flex: 1.5;">

           <div class="pa-4 rounded-0 border-thin relative overflow-hidden" :class="totalCardClass">
              <div class="absolute bottom-0 left-0 h-1 bg-white opacity-20 transition-all"
                  :style="{ width: ((totalValue - remainingBalance) / totalValue * 100) + '%' }">
              </div>

              <div class="d-flex flex-column flex-sm-row justify-space-between align-start align-sm-center gap-2 relative z-10">
                  <div class="d-flex align-center gap-2 opacity-70">
                      <v-icon size="20">mdi-scale-balance</v-icon>
                      <span class="text-caption font-weight-bold text-uppercase letter-spacing-1">Status do Saldo</span>
                  </div>

                  <div class="text-left text-sm-right mt-1 mt-sm-0">
                      <div class="text-[10px] font-weight-black text-uppercase opacity-60 mb-1">
                          {{ remainingBalance <= 0.01 ? 'Situação' : 'Falta Pagar' }}
                      </div>
                      <div class="text-h5 font-weight-black font-mono"
                          :class="remainingBalance > 0.01 ? 'text-warning' : 'text-success'">
                          {{ remainingBalance <= 0.01 ? 'QUITADO' : formatCurrency(remainingBalance) }}
                      </div>
                  </div>
              </div>
          </div>

           <v-expand-transition>
             <div v-if="isPixSelected" class="pa-3 rounded border-thin d-flex flex-column flex-sm-row align-start align-sm-center justify-space-between gap-3 bg-blue-lighten-5 border-blue-lighten-4">
                <div class="d-flex align-center gap-3">
                    <div class="rounded-circle bg-blue pa-2 text-white">
                        <v-icon size="20">mdi-qrcode-scan</v-icon>
                    </div>
                    <div>
                        <div class="text-subtitle-2 font-weight-black text-blue-darken-3">Gerar QR Code Pix?</div>
                        <div class="text-[10px] text-blue-darken-2 font-weight-medium lh-1">
                            {{ localPayment.generatePix ? 'O cliente pagará agora na tela.' : 'O cliente pagará depois (apenas registrar).' }}
                        </div>
                    </div>
                </div>
                <div class="w-100 w-sm-auto d-flex justify-end">
                    <v-switch
                        v-model="localPayment.generatePix"
                        color="blue-darken-2"
                        hide-details
                        inset
                        density="compact"
                    ></v-switch>
                </div>
             </div>
           </v-expand-transition>

           <div class="pa-4 rounded-0 border-thin transition-all" :class="[bgSurfaceClass]">
               <div class="d-flex align-center justify-space-between mb-3">
                   <div class="d-flex align-center gap-2">
                       <v-icon color="success" size="18">mdi-hand-coin</v-icon>
                       <span class="text-subtitle-2 font-weight-black" :class="textPrimaryClass">
                           Entrada / Sinais
                       </span>
                   </div>
                   <v-btn
                        size="small"
                        variant="flat"
                        color="success"
                        class="btn-rect font-weight-bold px-3"
                        height="28"
                        prepend-icon="mdi-plus"
                        @click="addDownPayment"
                    >
                        Adicionar
                    </v-btn>
               </div>

               <div v-if="localPayment.downPayments.length > 0" class="d-flex flex-column gap-3">
                   <div v-for="(dp, index) in localPayment.downPayments" :key="index" class="d-flex flex-column gap-2 pa-3 border-thin rounded-0 bg-white relative group">

                       <div class="d-flex flex-column flex-sm-row align-stretch align-sm-center gap-2 w-100">
                           <v-text-field
                              v-model.number="dp.value"
                              type="number"
                              label="Valor (R$)"
                              variant="outlined"
                              density="compact"
                              hide-details
                              class="ui-field flex-grow-1"
                              color="success"
                              @update:model-value="generateInstallments"
                           ></v-text-field>

                           <div class="d-flex align-center gap-2 flex-grow-1 w-100">
                               <v-autocomplete
                                  v-model="dp.method_id"
                                  :items="filteredPaymentMethods"
                                  item-title="nome"
                                  item-value="id"
                                  label="Método"
                                  variant="outlined"
                                  density="compact"
                                  hide-details
                                  class="ui-field flex-grow-1"
                                  color="success"
                               ></v-autocomplete>

                               <v-btn
                                    icon
                                    size="small"
                                    variant="text"
                                    color="error"
                                    class="rounded-0 flex-shrink-0 bg-red-lighten-5 border-thin"
                                    @click="removeDownPayment(index)"
                                >
                                    <v-icon>mdi-trash-can-outline</v-icon>
                                </v-btn>
                           </div>
                       </div>

                       <div class="d-flex flex-column flex-sm-row align-start align-sm-center mt-1 w-100">
                           <v-file-input
                              v-if="!dp.proof_url"
                              @update:modelValue="(files) => handleProofUpload(files, index)"
                              label="Anexar Comprovante"
                              variant="filled"
                              density="compact"
                              prepend-icon="mdi-paperclip"
                              hide-details
                              class="ui-field text-caption w-100 tiny-file-input"
                              bg-color="grey-lighten-4"
                              :loading="dp.uploading"
                           ></v-file-input>

                           <div v-else class="d-flex align-center justify-space-between w-100 pa-2 border rounded-0 bg-green-lighten-5 border-green-lighten-4">
                               <div class="d-flex align-center gap-2 overflow-hidden">
                                   <v-icon size="16" color="success">mdi-file-check</v-icon>
                                   <div class="d-flex flex-column">
                                       <span class="text-[10px] font-weight-black text-green-darken-3 lh-1">Comprovante Salvo</span>
                                       <a :href="dp.proof_url" target="_blank" class="text-[9px] text-decoration-underline text-grey-darken-1">Visualizar Anexo</a>
                                   </div>
                               </div>
                               <v-btn icon size="x-small" variant="text" color="error" title="Remover Anexo" @click="removeProof(index)">
                                   <v-icon size="16">mdi-close</v-icon>
                               </v-btn>
                           </div>
                       </div>
                   </div>

                   <div class="d-flex justify-end align-center border-t pt-2 border-dashed border-success">
                       <span class="text-[10px] font-weight-black text-uppercase text-grey mr-2">Total Pago</span>
                       <span class="text-subtitle-2 font-weight-black text-success">{{ formatCurrency(totalDownPayment) }}</span>
                   </div>
               </div>

               <div v-else class="text-center text-caption text-grey py-4 border-dashed border-thin rounded-0 opacity-70">
                   Nenhum sinal registrado. O valor total será parcelado.
               </div>
           </div>

           <v-expand-transition>
               <div v-if="remainingBalance > 0.01" class="pa-4 rounded-0 border-thin relative" :class="[bgSurfaceClass]">
                   <div class="d-flex align-center gap-2 mb-4">
                       <v-icon color="orange-darken-2" size="18">mdi-calendar-clock</v-icon>
                       <span class="text-subtitle-2 font-weight-black" :class="textPrimaryClass">
                           Parcelamento do Restante
                       </span>
                   </div>

                    <div class="d-flex p-1 rounded-0 border-thin mb-4 bg-white">
                        <button
                            type="button"
                            class="flex-1 text-center py-2 px-3 text-[10px] font-weight-black uppercase transition-all w-50"
                            :class="localPayment.type === 'vista' ? 'bg-grey-darken-3 text-white' : 'text-grey hover-bg-grey-lighten-4'"
                            @click="setPaymentType('vista')"
                        >
                            À Vista (1x)
                        </button>
                        <button
                            type="button"
                            class="flex-1 text-center py-2 px-3 text-[10px] font-weight-black uppercase transition-all w-50"
                            :class="localPayment.type === 'parcelado' ? 'bg-grey-darken-3 text-white' : 'text-grey hover-bg-grey-lighten-4'"
                            @click="setPaymentType('parcelado')"
                        >
                            Parcelado
                        </button>
                    </div>

                   <v-row dense class="mb-4 row-gap-sm">
                       <v-col cols="12" :md="localPayment.type === 'parcelado' ? 4 : 12">
                           <label class="input-label" :class="textSecondaryClass">Forma de Pagamento</label>
                           <v-autocomplete
                               v-model="localPayment.installment_payment_method_id"
                               :items="paymentMethods"
                               item-title="nome"
                               item-value="id"
                               variant="outlined"
                               density="compact"
                               hide-details
                               class="ui-field bg-white"
                               color="primary"
                               @update:model-value="generateInstallments"
                               :rules="[v => !!v || 'Obrigatório']"
                           ></v-autocomplete>
                       </v-col>

                       <template v-if="localPayment.type === 'parcelado'">
                           <v-col cols="6" sm="3" md="2">
                               <label class="input-label" :class="textSecondaryClass">Qtd.</label>
                               <v-text-field
                                   v-model.number="localPayment.installments_count"
                                   type="number"
                                   variant="outlined"
                                   density="compact"
                                   hide-details
                                   min="1"
                                   class="ui-field bg-white"
                                   @update:model-value="generateInstallments"
                               ></v-text-field>
                           </v-col>
                           <v-col cols="6" sm="3" md="2">
                               <label class="input-label" :class="textSecondaryClass">Intervalo</label>
                               <v-select
                                   v-model.number="localPayment.installments_interval"
                                   :items="[15, 30, 45, 60]"
                                   variant="outlined"
                                   density="compact"
                                   hide-details
                                   class="ui-field bg-white"
                                   @update:model-value="generateInstallments"
                               ></v-select>
                           </v-col>
                           <v-col cols="12" sm="6" md="4">
                               <label class="input-label" :class="textSecondaryClass">1º Vencimento</label>
                               <v-text-field
                                   v-model="localPayment.first_due_date"
                                   type="date"
                                   variant="outlined"
                                   density="compact"
                                   hide-details
                                   class="ui-field bg-white"
                                   @update:model-value="generateInstallments"
                               ></v-text-field>
                           </v-col>
                       </template>
                   </v-row>

                   <div v-if="localPayment.installments.length > 0" class="rounded-0 border-thin overflow-x-auto bg-white">
                       <v-table density="compact" class="table-parcelas" style="min-width: 250px;">
                           <thead>
                               <tr :class="isLight ? 'bg-grey-lighten-4' : 'bg-surface-variant'">
                                   <th class="text-left font-weight-black text-[10px] uppercase opacity-70" style="width: 40px">#</th>
                                   <th class="text-left font-weight-black text-[10px] uppercase opacity-70" style="min-width: 120px;">Vencimento</th>
                                   <th class="text-right font-weight-black text-[10px] uppercase opacity-70" style="min-width: 90px;">Valor</th>
                               </tr>
                           </thead>
                           <tbody>
                               <tr v-for="(inst, index) in localPayment.installments" :key="index" class="hover-bg-subtle transition-colors">
                                   <td class="font-weight-bold opacity-60 text-caption">{{ index + 1 }}x</td>
                                   <td class="py-1">
                                       <input type="date" v-model="inst.due_date" class="clean-input w-100 font-mono text-caption font-weight-bold" :class="textPrimaryClass">
                                   </td>
                                   <td class="text-right py-1">
                                       <input
                                         type="number"
                                         step="0.01"
                                         v-model.lazy="inst.value"
                                         @change="handleInstallmentValueChange(index, $event.target.value)"
                                         class="clean-input w-100 text-right font-weight-bold font-mono text-caption"
                                         :class="textPrimaryClass"
                                       >
                                   </td>
                               </tr>
                           </tbody>
                       </v-table>
                   </div>
               </div>
           </v-expand-transition>
        </div>
      </div>
    </v-form>
  </div>
</template>

<script setup lang="ts">
import { ref, watch, computed, onMounted, nextTick } from 'vue';
import { format, addDays } from 'date-fns';
import { useThemeStore } from '@/stores/theme';
import { supabase } from '@/api/supabase';
import { useAppStore } from '@/stores/app';

const props = defineProps<{
  totalValue: number;
  paymentDetails: any;
  orderHeader: any;
  paymentMethods: any[];
  isGeneratingPdf: boolean;
  isSaving: boolean;
  isValid: boolean;
  hideActions: boolean;
  availableCredit: number;
  creditUsedValue: number;
}>();

const emit = defineEmits(['update:paymentDetails', 'update:orderHeader', 'update:isValid', 'update:creditUsedValue']);
const themeStore = useThemeStore();
const appStore = useAppStore();
const formRef = ref<any>(null);

const isLight = computed(() => themeStore.currentMode === 'light');

// Inicializa estrutura
const preparePaymentStructure = (data: any) => {
    const p = JSON.parse(JSON.stringify(data));
    if (p.generatePix === undefined) p.generatePix = true;

    if (!p.downPayments) {
        p.downPayments = [];
        if (Number(p.entry_value) > 0) {
            p.downPayments.push({
                value: p.entry_value,
                method_id: p.entry_method_id,
                proof_url: null,
                uploading: false
            });
        }
    }
    return p;
};

const localPayment = ref(preparePaymentStructure(props.paymentDetails));
const localOrderHeader = ref(JSON.parse(JSON.stringify(props.orderHeader)));
const localCreditValue = ref(props.creditUsedValue || 0);
const useCredit = ref(false);
const formValid = ref(false);

const textPrimaryClass = computed(() => isLight.value ? 'text-grey-darken-4' : 'text-white');
const textSecondaryClass = computed(() => isLight.value ? 'text-grey-darken-1' : 'text-white-70');
const borderClass = computed(() => isLight.value ? 'border-grey-lighten-2' : 'border-white-10');
const bgSurfaceClass = computed(() => isLight.value ? 'bg-grey-lighten-5' : 'bg-glass-card');
const totalCardClass = computed(() => isLight.value ? 'bg-grey-darken-3 text-white' : 'bg-surface-light border-white-10');
const statusBadgeClass = computed(() => isLight.value ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-glass-card border-white-10');

const filteredPaymentMethods = computed(() => {
    return props.paymentMethods.filter(m => {
        const name = String(m.nome).toLowerCase();
        return !name.includes('crédito loja') && !name.includes('saldo');
    });
});

const totalDownPayment = computed(() => {
    return localPayment.value.downPayments.reduce((acc: number, dp: any) => acc + (Number(dp.value) || 0), 0);
});

const remainingBalance = computed(() => {
    const total = Number(props.totalValue) || 0;
    const credit = Number(localCreditValue.value) || 0;
    return Math.max(0, parseFloat((total - totalDownPayment.value - credit).toFixed(2)));
});

const hasActiveSignal = computed(() => {
    return localPayment.value.downPayments.some((dp: any) => Number(dp.value) > 0);
});

const isPixSelected = computed(() => {
    const isPix = (id: string | null) => {
        if (!id) return false;
        const method = props.paymentMethods.find(m => m.id === id);
        return method && (method.nome.toLowerCase().includes('pix') || method.nome.toLowerCase().includes('instantâneo'));
    };

    if (isPix(localPayment.value.entry_method_id)) return true;
    if (localPayment.value.downPayments && localPayment.value.downPayments.some((dp: any) => isPix(dp.method_id))) return true;
    if (remainingBalance.value > 0.01 && isPix(localPayment.value.installment_payment_method_id)) return true;

    return false;
});

watch(hasActiveSignal, (isActive) => {
    if (isActive) {
        const threeDaysLater = addDays(new Date(), 3);
        localPayment.value.first_due_date = format(threeDaysLater, 'yyyy-MM-dd');

        if (localPayment.value.type === 'vista') {
            localPayment.value.type = 'parcelado';
            localPayment.value.installments_count = 1;
        }
    } else {
        localPayment.value.first_due_date = format(new Date(), 'yyyy-MM-dd');
    }
    generateInstallments();
});

const formatCurrency = (value: number) => new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(value);

watch(() => props.paymentDetails, (newDetails) => {
    if (JSON.stringify(newDetails) !== JSON.stringify(localPayment.value)) {
        localPayment.value = preparePaymentStructure(newDetails);
        generateInstallments();
    }
}, { deep: true });

watch(() => props.orderHeader, (newHeader) => {
    if (JSON.stringify(newHeader) !== JSON.stringify(localOrderHeader.value)) {
        localOrderHeader.value = JSON.parse(JSON.stringify(newHeader));
    }
}, { deep: true });

const handleProofUpload = async (files: File | File[], index: number) => {
    const file = Array.isArray(files) ? files[0] : files;
    if (!file) return;

    const dp = localPayment.value.downPayments[index];
    dp.uploading = true;

    try {
        const fileName = `drafts/${Date.now()}-${file.name.replace(/\s/g, '_')}`;
        const { data, error } = await supabase.storage.from('proofs').upload(fileName, file);
        if (error) throw error;
        const { data: publicUrlData } = supabase.storage.from('proofs').getPublicUrl(data.path);
        dp.proof_url = publicUrlData.publicUrl;
        dp.file = null;
        appStore.showSnackbar("Comprovante salvo na nuvem!", "success");
    } catch (e: any) {
        console.error("Erro upload:", e);
        appStore.showSnackbar("Erro ao enviar anexo: " + e.message, "error");
    } finally {
        dp.uploading = false;
    }
};

const removeProof = (index: number) => {
    localPayment.value.downPayments[index].proof_url = null;
};

const addDownPayment = () => {
    const suggestedValue = remainingBalance.value > 0 ? remainingBalance.value : 0;
    localPayment.value.downPayments.push({
        value: suggestedValue,
        method_id: null,
        proof_url: null,
        uploading: false
    });
    generateInstallments();
};

const removeDownPayment = (index: number) => {
    localPayment.value.downPayments.splice(index, 1);
    generateInstallments();
};

watch(useCredit, (active) => {
    if (!active) localCreditValue.value = 0;
    else if (localCreditValue.value === 0) {
        const needed = props.totalValue - totalDownPayment.value;
        localCreditValue.value = Math.min(props.availableCredit, needed);
    }
    emit('update:creditUsedValue', localCreditValue.value);
    generateInstallments();
});

const handleCreditChange = () => {
    if (localCreditValue.value > props.availableCredit) localCreditValue.value = props.availableCredit;
    if (localCreditValue.value > props.totalValue) localCreditValue.value = props.totalValue;
    emit('update:creditUsedValue', localCreditValue.value);
    generateInstallments();
};

const setPaymentType = (type: 'vista' | 'parcelado') => {
    localPayment.value.type = type;
    if (type === 'vista') localPayment.value.installments_count = 1;
    else if (localPayment.value.installments_count < 2) localPayment.value.installments_count = 2;
    generateInstallments();
};

const generateInstallments = () => {
  localPayment.value.installments = [];
  const balance = remainingBalance.value;

  if (balance <= 0.01) return;

  const methodId = localPayment.value.installment_payment_method_id;
  let startDate: Date = localPayment.value.first_due_date ? new Date(localPayment.value.first_due_date + 'T12:00:00') : new Date();

  if (localPayment.value.type === 'vista') {
    localPayment.value.installments.push({
        due_date: format(startDate, 'yyyy-MM-dd'),
        value: balance,
        payment_method_id: methodId
    });
    return;
  }

  const count = parseInt(localPayment.value.installments_count) || 2;
  const interval = parseInt(localPayment.value.installments_interval) || 30;
  const valuePerInstallment = Math.floor((balance / count) * 100) / 100;
  let currentSum = 0;

  for (let i = 0; i < count; i++) {
    let val = valuePerInstallment;
    if (i === count - 1) { val = parseFloat((balance - currentSum).toFixed(2)); }
    currentSum += val;
    const dueDate = addDays(startDate, i * interval);
    localPayment.value.installments.push({
        due_date: format(dueDate, 'yyyy-MM-dd'),
        value: val,
        payment_method_id: methodId
    });
  }
};

const handleInstallmentValueChange = (changedIndex: number, newValue: string) => {
  const numericVal = parseFloat(newValue);
  if (isNaN(numericVal)) return;
  localPayment.value.installments[changedIndex].value = numericVal;
};

watch(() => props.totalValue, () => generateInstallments());

watch([localPayment, remainingBalance, formValid, useCredit, localCreditValue], () => {
    const signalsValid = localPayment.value.downPayments.length === 0 ||
                         localPayment.value.downPayments.every((dp: any) => dp.value > 0 && !!dp.method_id);
    let isCreditValid = true;
    if (useCredit.value) isCreditValid = localCreditValue.value > 0 && localCreditValue.value <= props.availableCredit;
    let isInstallmentValid = true;
    if (remainingBalance.value > 0.01) {
        isInstallmentValid = !!localPayment.value.installment_payment_method_id && localPayment.value.installments.length > 0;
    }
    const isTotalCovered = remainingBalance.value <= 0.01 || localPayment.value.installments.length > 0;
    const hasAnyPayment = (localPayment.value.downPayments.length > 0) || (useCredit.value && localCreditValue.value > 0) || (remainingBalance.value > 0.01 && localPayment.value.installments.length > 0);
    const isValid = signalsValid && isCreditValid && isInstallmentValid && isTotalCovered && hasAnyPayment && (formValid.value === true || formValid.value === null);

    emit('update:isValid', isValid);
    emit('update:paymentDetails', localPayment.value);
}, { deep: true, immediate: true });

watch(localOrderHeader, (val) => emit('update:orderHeader', val), { deep: true });

onMounted(() => {
    if (localCreditValue.value > 0) useCredit.value = true;
    generateInstallments();
});
</script>

<style scoped lang="scss">
.payment-summary-container { font-family: 'Roboto', sans-serif; }
.lh-1 { line-height: 1; }
.leading-none { line-height: 1; }
.gap-2 { gap: 8px; } .gap-3 { gap: 12px; } .gap-4 { gap: 16px; }
.row-gap-sm { row-gap: 12px; }
.icon-box-sm { width: 32px; height: 32px; }
.btn-rect { border-radius: 0 !important; text-transform: none !important; }
.bg-glass-card { background-color: rgba(255, 255, 255, 0.05); }
.border-thin { border: 1px solid rgba(0,0,0,0.12) !important; }
.ui-field :deep(.v-field) { border-radius: 0 !important; }
.ui-field :deep(.v-field__input) { min-height: 36px !important; padding-top: 6px !important; padding-bottom: 6px !important; font-size: 13px; }
.ui-field :deep(.v-field__prepend-inner) { margin-right: 8px !important; }
.input-label { font-size: 10px; font-weight: 800; text-transform: uppercase; display: block; margin-bottom: 4px; opacity: 0.7; }
.tiny-file-input :deep(.v-input__control) { min-height: 32px !important; }
.tiny-file-input :deep(.v-field__input) { padding-top: 4px !important; padding-bottom: 4px !important; font-size: 11px !important; }
.clean-input {
    background: transparent; border: none; outline: none; padding: 0;
    border-bottom: 1px solid transparent; transition: border-color 0.2s;
    &:focus { border-bottom-color: rgba(var(--v-theme-primary), 0.5); }
    &:hover { border-bottom-color: rgba(128,128,128,0.2); }
}
.table-parcelas th { text-transform: uppercase; letter-spacing: 0.5px; }

/* Auxiliares responsivos para flexbox */
.flex-1 { flex: 1 1 0%; }
.w-50 { width: 50% !important; }
</style>
