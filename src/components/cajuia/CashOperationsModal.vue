<template>
  <v-dialog
    :model-value="modelValue"
    @update:model-value="$emit('update:modelValue', $event)"
    max-width="500"
    content-class="glass-dialog-ops"
  >
    <v-card class="rounded-xl overflow-hidden" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'glass-modal-card'">

      <div
        class="px-6 py-5 border-b d-flex align-center justify-space-between relative transition-colors"
        :class="[
            isBleed ? 'glow-red' : 'glow-blue',
            themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-glass-header border-white-10'
        ]"
      >
        <div class="header-glow-bar-ops" :class="isBleed ? 'bg-red' : 'bg-blue'"></div>

        <div class="d-flex align-center gap-4 z-10">
           <div class="icon-box-ops elevation-6 transition-colors" :class="isBleed ? 'bg-gradient-error' : 'bg-gradient-info'">
              <v-icon color="white" size="28">{{ isBleed ? 'mdi-cash-minus' : 'mdi-cash-plus' }}</v-icon>
           </div>
           <div>
              <div class="d-flex align-center gap-2 mb-1">
                 <span class="text-overline font-weight-bold letter-spacing-2" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-1' : 'text-white-50'">OPERAÇÃO</span>
                 <v-chip size="x-small" :color="isBleed ? 'error' : 'info'" variant="flat" class="font-weight-bold px-2 h-16 text-white">
                    {{ isBleed ? 'SAÍDA' : 'ENTRADA' }}
                 </v-chip>
              </div>
              <h2 class="text-h6 font-weight-black lh-1" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white text-shadow'">
                  {{ isBleed ? 'Sangria de Caixa' : 'Suprimento de Caixa' }}
              </h2>
           </div>
        </div>

        <v-btn icon variant="text" :color="themeStore.currentMode === 'light' ? 'grey-darken-1' : 'white-50'" @click="$emit('update:modelValue', false)">
            <v-icon>mdi-close</v-icon>
        </v-btn>
      </div>

      <div class="pa-6 z-10" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-glass-body-gradient'">

        <div class="d-flex justify-center mb-6">
             <div class="p-1 rounded-lg d-flex border" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-4 border-grey-lighten-2' : 'bg-glass-surface border-white-10'">
                 <button
                    class="toggle-btn px-4 py-2 rounded-md text-caption font-weight-bold transition-all"
                    :class="!isBleed ? 'bg-info text-white shadow-glow-blue' : (themeStore.currentMode === 'light' ? 'text-grey-darken-1 hover:text-info' : 'text-white-50 hover:text-white')"
                    @click="localType = 'supply'"
                 >
                    <v-icon start size="small">mdi-arrow-down-bold</v-icon> Suprimento
                 </button>
                 <button
                    class="toggle-btn px-4 py-2 rounded-md text-caption font-weight-bold transition-all"
                    :class="isBleed ? 'bg-error text-white shadow-glow-red' : (themeStore.currentMode === 'light' ? 'text-grey-darken-1 hover:text-error' : 'text-white-50 hover:text-white')"
                    @click="localType = 'bleed'"
                 >
                    <v-icon start size="small">mdi-arrow-up-bold</v-icon> Sangria
                 </button>
             </div>
        </div>

        <v-form @submit.prevent="submitOperation">

            <div class="form-group mb-6">
                <label class="text-caption font-weight-bold text-uppercase mb-2 d-block ml-1" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-2' : 'text-white-50'">Valor da Operação</label>
                <div
                    class="currency-input-wrapper relative border transition-all"
                    :class="[
                        isBleed ? 'focus-red' : 'focus-blue',
                        themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-black-20 border-white-10'
                    ]"
                >
                    <span class="currency-symbol" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-1' : 'text-white-50'">R$</span>
                    <input
                        type="number"
                        v-model="amount"
                        class="big-input font-weight-black text-h4 w-100 text-right pr-4"
                        :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'"
                        placeholder="0,00"
                        step="0.01"
                        min="0"
                        autofocus
                    />
                </div>
            </div>

            <div class="form-group mb-6">
                <label class="text-caption font-weight-bold text-uppercase mb-2 d-block ml-1" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-2' : 'text-white-50'">
                    Motivo / Descrição {{ isBleed ? '(Obrigatório)' : '(Opcional)' }}
                </label>
                <v-textarea
                    v-model="description"
                    :placeholder="isBleed ? 'Ex: Pagamento Fornecedor X, Retirada para Depósito...' : 'Ex: Troco inicial extra, Aporte...'"
                    variant="outlined"
                    :bg-color="themeStore.currentMode === 'light' ? 'grey-lighten-5' : 'rgba(0,0,0,0.2)'"
                    class="rounded-lg"
                    rows="2"
                    hide-details="auto"
                ></v-textarea>
            </div>

            <v-btn
                block
                height="56"
                :color="isBleed ? 'error' : 'info'"
                class="font-weight-bold rounded-lg text-body-1 letter-spacing-1 text-white"
                :class="isBleed ? 'shadow-glow-red' : 'shadow-glow-blue'"
                :loading="loading"
                :disabled="!isValid"
                @click="submitOperation"
            >
                <v-icon start class="mr-2">{{ isBleed ? 'mdi-cash-minus' : 'mdi-cash-plus' }}</v-icon>
                CONFIRMAR {{ isBleed ? 'SAÍDA' : 'ENTRADA' }}
            </v-btn>

        </v-form>
      </div>
    </v-card>
  </v-dialog>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { useCashSessionStore } from '@/stores/cashSession'
import { useAppStore } from '@/stores/app'
import { useThemeStore } from '@/stores/theme'

const props = defineProps({
    modelValue: Boolean,
    type: { type: String as () => 'supply' | 'bleed', default: 'supply' }
})
const emit = defineEmits(['update:modelValue', 'completed'])

const cashStore = useCashSessionStore()
const appStore = useAppStore()
const themeStore = useThemeStore()

const localType = ref<'supply' | 'bleed'>('supply')
const amount = ref('')
const description = ref('')
const loading = ref(false)

const isBleed = computed(() => localType.value === 'bleed')

const isValid = computed(() => {
    const val = parseFloat(amount.value)
    if (isNaN(val) || val <= 0) return false
    if (isBleed.value && description.value.length < 3) return false
    return true
})

watch(() => props.modelValue, (val) => {
    if (val) {
        localType.value = props.type
        amount.value = ''
        description.value = ''
    }
})

const submitOperation = async () => {
    if (!isValid.value) return
    loading.value = true
    try {
        await cashStore.registerMovement(
            localType.value,
            Number(amount.value),
            description.value || (isBleed.value ? 'Sangria Avulsa' : 'Suprimento Avulso')
        )
        appStore.showSnackbar('Operação registrada com sucesso!', 'success')
        emit('completed')
        emit('update:modelValue', false)
    } catch (e: any) {
        appStore.showSnackbar('Erro: ' + e.message, 'error')
    } finally {
        loading.value = false
    }
}
</script>

<style scoped lang="scss">
.glass-modal-card { background: #121214; border: 1px solid rgba(255, 255, 255, 0.1); border-radius: 24px; box-shadow: 0 50px 100px -20px rgba(0,0,0,0.9); position: relative; }
.bg-glass-header { background: rgba(255, 255, 255, 0.03); }

/* Dynamic Colors */
.header-glow-bar-ops { position: absolute; top: 0; left: 0; width: 4px; height: 100%; transition: background 0.3s; }
.bg-red { background: #ff5252; box-shadow: 2px 0 15px rgba(255, 82, 82, 0.5); }
.bg-blue { background: #2196f3; box-shadow: 2px 0 15px rgba(33, 150, 243, 0.5); }

.bg-gradient-error { background: linear-gradient(135deg, #ff5252, #b71c1c); }
.bg-gradient-info { background: linear-gradient(135deg, #2196f3, #0d47a1); }
.shadow-glow-red { box-shadow: 0 0 20px rgba(255, 82, 82, 0.4); }
.shadow-glow-blue { box-shadow: 0 0 20px rgba(33, 150, 243, 0.4); }

.icon-box-ops { width: 56px; height: 56px; border-radius: 16px; display: flex; align-items: center; justify-content: center; border: 1px solid rgba(255,255,255,0.1); }

/* Toggle */
.glass-toggle-container { background: rgba(0,0,0,0.3); }
.toggle-btn { border: none; outline: none; cursor: pointer; }

/* Inputs */
.currency-input-wrapper { border-radius: 16px; padding: 16px; display: flex; align-items: center; transition: all 0.3s ease; }
.currency-input-wrapper.focus-blue:focus-within { border-color: #2196f3; box-shadow: 0 0 15px rgba(33, 150, 243, 0.2); }
.currency-input-wrapper.focus-red:focus-within { border-color: #ff5252; box-shadow: 0 0 15px rgba(255, 82, 82, 0.2); }

.currency-symbol { font-size: 1.5rem; font-weight: bold; margin-right: 8px; }
.big-input { background: transparent; border: none; outline: none; font-family: 'Roboto Mono', monospace; }
input::-webkit-outer-spin-button, input::-webkit-inner-spin-button { -webkit-appearance: none; margin: 0; }

/* Utils */
.text-white-30 { color: rgba(255,255,255,0.3) !important; }
.text-white-50 { color: rgba(255,255,255,0.5) !important; }
.border-white-10 { border-color: rgba(255,255,255,0.1) !important; }
.bg-black-20 { background: rgba(0,0,0,0.2); }

.lh-1 { line-height: 1; }
.h-16 { height: 16px; }
.z-10 { position: relative; z-index: 10; }
.gap-2 { gap: 8px; } .gap-4 { gap: 16px; }
</style>
