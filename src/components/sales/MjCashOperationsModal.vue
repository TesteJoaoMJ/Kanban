<template>
  <v-dialog
    :model-value="modelValue"
    @update:model-value="$emit('update:modelValue', $event)"
    max-width="900"
    persistent
    content-class="glass-modal-content"
    transition="dialog-bottom-transition"
  >
    <v-card class="fill-height d-flex flex-row overflow-hidden" :class="themeClass">

      <div class="sidebar-info d-flex flex-column pa-6 border-r" :class="sidebarClass" style="width: 300px; min-width: 300px;">
        <div class="d-flex align-center gap-3 mb-6">
           <div class="icon-box-md rounded-lg" :class="type === 'supply' ? 'bg-gradient-success shadow-success' : 'bg-gradient-error shadow-error'">
              <v-icon size="24" color="white">{{ type === 'supply' ? 'mdi-cash-plus' : 'mdi-cash-minus' }}</v-icon>
           </div>
           <div>
              <div class="text-[10px] font-weight-bold uppercase opacity-60 letter-spacing-1">Movimentação</div>
              <h2 class="text-h6 font-weight-black lh-1" :class="textPrimaryClass">
                {{ type === 'supply' ? 'Suprimento' : 'Sangria' }}
              </h2>
           </div>
        </div>

        <div class="info-box pa-4 rounded-lg border-thin mb-4" :class="infoBoxClass">
           <div class="d-flex gap-3">
              <v-icon :color="type === 'supply' ? 'success' : 'error'" size="20" class="mt-1">
                {{ type === 'supply' ? 'mdi-arrow-up-circle' : 'mdi-arrow-down-circle' }}
              </v-icon>
              <div>
                 <div class="text-subtitle-2 font-weight-bold" :class="type === 'supply' ? 'text-success' : 'text-error'">
                    {{ type === 'supply' ? 'Entrada Manual' : 'Retirada Manual' }}
                 </div>
                 <div class="text-caption opacity-70 lh-14 mt-1">
                    {{ type === 'supply'
                        ? 'Adicionar dinheiro ao caixa para troco ou reforço.'
                        : 'Retirar dinheiro do caixa para depósito ou despesa.'
                    }}
                 </div>
              </div>
           </div>
        </div>

        <div class="mt-auto opacity-50 text-caption">
           <p>Esta operação será registrada no relatório de fechamento do operador <strong>{{ userName }}</strong>.</p>
        </div>
      </div>

      <div class="main-content flex-grow-1 d-flex flex-column bg-pattern pa-8 justify-center">

         <v-form @submit.prevent="submitOperation">
            <div class="mb-8">
               <label class="text-caption font-weight-bold uppercase opacity-60 mb-2 d-block ml-1">Valor da Operação</label>
               <div class="currency-input-wrapper relative" :class="[inputWrapperClass, type === 'supply' ? 'focus-success' : 'focus-error']">
                  <span class="currency-symbol opacity-50 text-h5 font-weight-bold">R$</span>
                  <input
                     v-model="amount"
                     type="number"
                     class="big-input text-h3 font-weight-black w-100 text-right"
                     :class="textPrimaryClass"
                     placeholder="0,00"
                     step="0.01"
                     min="0"
                     autofocus
                     ref="amountInput"
                  />
               </div>
            </div>

            <div class="mb-8">
               <v-textarea
                  v-model="description"
                  label="Motivo / Descrição"
                  :placeholder="type === 'supply' ? 'Ex: Reforço de troco trazido pelo gerente.' : 'Ex: Pagamento de fornecedor ou sangria de segurança.'"
                  variant="outlined"
                  rows="2"
                  no-resize
                  :bg-color="inputBgColor"
                  :color="themeStore.currentMode === 'light' ? 'primary' : 'white'"
               ></v-textarea>
            </div>

            <div class="d-flex gap-4">
               <v-btn
                  variant="text"
                  size="large"
                  height="56"
                  class="flex-1-1 font-weight-bold rounded-lg"
                  :color="textSecondaryColor"
                  @click="$emit('update:modelValue', false)"
               >
                  Cancelar
               </v-btn>

               <v-btn
                  :color="type === 'supply' ? 'success' : 'error'"
                  size="large"
                  height="56"
                  class="flex-grow-1 font-weight-black rounded-lg"
                  :class="type === 'supply' ? 'shadow-glow-success' : 'shadow-glow-error'"
                  :loading="loading"
                  :disabled="!isValid"
                  @click="submitOperation"
               >
                  <v-icon start class="mr-2">mdi-check</v-icon>
                  Confirmar {{ type === 'supply' ? 'Suprimento' : 'Sangria' }}
               </v-btn>
            </div>
         </v-form>

      </div>
    </v-card>
  </v-dialog>
</template>

<script setup lang="ts">
import { ref, computed, watch, nextTick } from 'vue';
import { useMjCashSessionStore } from '@/stores/mjCashSession';
import { useUserStore } from '@/stores/user';
import { useAppStore } from '@/stores/app';
import { useThemeStore } from '@/stores/theme';

const props = defineProps<{
    modelValue: boolean;
    type: 'supply' | 'bleed'; // suprimento ou sangria
}>();

const emit = defineEmits(['update:modelValue', 'operation-completed']);

const cashStore = useMjCashSessionStore();
const userStore = useUserStore();
const appStore = useAppStore();
const themeStore = useThemeStore();

const amount = ref('');
const description = ref('');
const loading = ref(false);
const amountInput = ref<HTMLInputElement | null>(null);

// THEME COMPUTED
const themeClass = computed(() => themeStore.currentMode === 'light' ? 'bg-white text-grey-darken-3' : 'bg-glass-dark text-white');
const sidebarClass = computed(() => themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-glass-sidebar border-white-10');
const textPrimaryClass = computed(() => themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white');
const textSecondaryColor = computed(() => themeStore.currentMode === 'light' ? 'grey-darken-1' : 'white-50');
const infoBoxClass = computed(() => themeStore.currentMode === 'light' ? 'bg-white border-grey-lighten-2' : 'bg-surface-light border-white-10');
const inputWrapperClass = computed(() => themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 border-grey-lighten-3' : 'bg-black-opacity border-white-10');
const inputBgColor = computed(() => themeStore.currentMode === 'light' ? 'grey-lighten-5' : 'rgba(0,0,0,0.2)');
const userName = computed(() => userStore.profile?.full_name?.split(' ')[0] || 'Operador');

const isValid = computed(() => amount.value !== '' && !isNaN(parseFloat(amount.value)) && parseFloat(amount.value) > 0 && description.value.length > 3);

watch(() => props.modelValue, async (val) => {
    if (val) {
        amount.value = '';
        description.value = '';
        await nextTick();
        amountInput.value?.focus();
    }
});

const submitOperation = async () => {
    if (!isValid.value) return;
    loading.value = true;
    try {
        const val = Number(amount.value);
        // Chama a store correta. 'supply' ou 'bleed'
        await cashStore.registerMovement(
            props.type,
            val,
            description.value
        );

        appStore.showSnackbar(`${props.type === 'supply' ? 'Suprimento' : 'Sangria'} realizada com sucesso!`, 'success');
        emit('operation-completed');
        emit('update:modelValue', false);
    } catch (e: any) {
        appStore.showSnackbar(e.message || 'Erro ao registrar operação.', 'error');
    } finally {
        loading.value = false;
    }
};
</script>

<style scoped lang="scss">
.glass-modal-content { backdrop-filter: blur(20px); }
.bg-glass-dark { background: #121214; }
.bg-glass-sidebar { background: rgba(255, 255, 255, 0.03); }
.bg-surface-light { background: rgba(255, 255, 255, 0.05); }
.bg-black-opacity { background: rgba(0, 0, 0, 0.2); }
.bg-pattern { background-image: radial-gradient(rgba(128,128,128,0.1) 1px, transparent 1px); background-size: 20px 20px; }

/* Gradients */
.bg-gradient-success { background: linear-gradient(135deg, #00e676, #006025); }
.bg-gradient-error { background: linear-gradient(135deg, #ff5252, #b71c1c); }

/* Shadows */
.shadow-success { box-shadow: 0 4px 15px rgba(0, 230, 118, 0.3); }
.shadow-error { box-shadow: 0 4px 15px rgba(255, 82, 82, 0.3); }
.shadow-glow-success { box-shadow: 0 0 25px rgba(0, 230, 118, 0.4); }
.shadow-glow-error { box-shadow: 0 0 25px rgba(255, 82, 82, 0.4); }

/* Borders */
.border-white-10 { border-color: rgba(255, 255, 255, 0.1) !important; }
.border-grey-lighten-2 { border-color: #E0E0E0 !important; }

/* Inputs */
.currency-input-wrapper {
    border: 1px solid; border-radius: 16px; padding: 24px; display: flex; align-items: center; transition: all 0.3s;
    &.focus-success:focus-within { border-color: #00e676; box-shadow: 0 0 20px rgba(0, 230, 118, 0.1); }
    &.focus-error:focus-within { border-color: #ff5252; box-shadow: 0 0 20px rgba(255, 82, 82, 0.1); }
}
.big-input { background: transparent; border: none; outline: none; font-family: 'Roboto Mono', monospace; }
input::-webkit-outer-spin-button, input::-webkit-inner-spin-button { -webkit-appearance: none; margin: 0; }

.icon-box-md { width: 48px; height: 48px; display: flex; align-items: center; justify-content: center; }
.lh-1 { line-height: 1; } .lh-14 { line-height: 1.4; }
.h-20 { height: 20px; }
.gap-3 { gap: 12px; } .gap-4 { gap: 16px; }
</style>
