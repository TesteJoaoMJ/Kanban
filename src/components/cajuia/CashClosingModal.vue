<template>
  <v-dialog
    :model-value="modelValue"
    @update:model-value="$emit('update:modelValue', $event)"
    max-width="560"
    persistent
    transition="dialog-bottom-transition"
  >
    <v-card class="rounded-xl overflow-hidden" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'glass-modal-card'">

      <div
        class="px-6 py-5 border-b d-flex align-center justify-space-between relative"
        :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-glass-header border-white-10'"
      >
        <div class="header-glow-bar-close"></div>

        <div class="d-flex align-center gap-4 z-10">
           <div class="icon-box-close elevation-6 bg-gradient-warning">
              <v-icon color="white" size="28">mdi-cash-lock</v-icon>
           </div>
           <div>
              <div class="d-flex align-center gap-2 mb-1">
                 <span class="text-overline font-weight-bold letter-spacing-2" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-1' : 'text-white-50'">ENCERRAMENTO</span>
                 <v-chip size="x-small" color="warning" variant="flat" class="font-weight-bold px-2 h-16 text-black">
                    TURNO #{{ currentSession?.id?.toString().slice(0,6) }}
                 </v-chip>
              </div>
              <h2 class="text-h6 font-weight-black lh-1" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white text-shadow'">Conferência de Caixa</h2>
           </div>
        </div>

        <div class="d-flex align-center gap-2">
            <v-tooltip location="bottom" text="Imprimir Relatório Parcial (X)" content-class="bg-grey-darken-4 text-white font-weight-bold">
                <template v-slot:activator="{ props }">
                    <v-btn
                        icon
                        variant="tonal"
                        :color="themeStore.currentMode === 'light' ? 'grey-darken-2' : 'white'"
                        class="rounded-lg"
                        v-bind="props"
                        @click="printPartialReport"
                        :loading="generatingReport"
                    >
                        <v-icon>mdi-printer-eye</v-icon>
                    </v-btn>
                </template>
            </v-tooltip>

            <v-btn icon variant="text" :color="themeStore.currentMode === 'light' ? 'grey-darken-1' : 'white-50'" @click="$emit('update:modelValue', false)">
                <v-icon>mdi-close</v-icon>
            </v-btn>
        </div>
      </div>

      <div class="pa-6 z-10" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-glass-body-gradient'">

        <div class="d-flex gap-4 mb-6">
            <div
                class="flex-grow-1 pa-3 rounded-xl border"
                :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'glass-info-box border-white-05'"
            >
                <div class="text-[10px] text-uppercase font-weight-bold mb-1" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-1' : 'text-white-50'">Operador Responsável</div>
                <div class="d-flex align-center gap-2">
                    <v-icon size="16" color="primary">mdi-account-check</v-icon>
                    <span class="text-body-2 font-weight-bold" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-3' : 'text-white'">{{ userStore.profile?.full_name?.split(' ')[0] }}</span>
                </div>
            </div>
            <div
                class="flex-grow-1 pa-3 rounded-xl border"
                :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'glass-info-box border-white-05'"
            >
                <div class="text-[10px] text-uppercase font-weight-bold mb-1" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-1' : 'text-white-50'">Abertura</div>
                <div class="d-flex align-center gap-2">
                    <v-icon size="16" :color="themeStore.currentMode === 'light' ? 'grey-darken-1' : 'white-70'">mdi-clock-start</v-icon>
                    <span class="text-body-2 font-weight-bold" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-3' : 'text-white'">{{ formatTime(currentSession?.opened_at) }}</span>
                </div>
            </div>
        </div>

        <div class="pa-4 rounded-xl border mb-6 d-flex gap-3 align-center" :class="themeStore.currentMode === 'light' ? 'bg-amber-lighten-5 border-amber-lighten-3' : 'glass-alert-box-warning border-warning-20'">
            <div class="icon-circle-small bg-warning-10 text-warning flex-shrink-0">
                <v-icon size="20">mdi-eye-off</v-icon>
            </div>
            <div class="text-caption lh-14" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-3' : 'text-white-70'">
                <strong class="text-warning text-uppercase font-weight-black">Contagem Cega:</strong>
                Para segurança, o saldo esperado não é exibido. Conte o dinheiro físico na gaveta e informe abaixo.
            </div>
        </div>

        <v-form @submit.prevent="submitClosing">

            <div class="form-group mb-6">
                <label class="d-flex justify-space-between align-center mb-2">
                    <span class="text-caption font-weight-bold text-uppercase ml-1" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-2' : 'text-white-50'">Dinheiro em Espécie (Gaveta)</span>
                    <span class="text-[10px] text-black font-weight-bold bg-warning px-2 py-0-5 rounded">OBRIGATÓRIO</span>
                </label>

                <v-text-field
                    v-model="cashAmount"
                    type="number"
                    prefix="R$"
                    placeholder="0,00"
                    variant="outlined"
                    class="glass-input-huge"
                    :bg-color="themeStore.currentMode === 'light' ? 'grey-lighten-5' : 'rgba(0,0,0,0.3)'"
                    :color="themeStore.currentMode === 'light' ? 'primary' : 'white'"
                    hide-details="auto"
                    autofocus
                ></v-text-field>
                <div class="text-right mt-1">
                    <span class="text-[10px]" :class="themeStore.currentMode === 'light' ? 'text-grey' : 'text-white-30'">Informe apenas cédulas e moedas.</span>
                </div>
            </div>

            <v-divider class="mb-6" :class="themeStore.currentMode === 'light' ? 'border-grey-lighten-2' : 'border-white-10'"></v-divider>

            <div class="form-group mb-6">
                <div class="d-flex align-center mb-2 gap-2">
                     <v-icon size="14" :color="themeStore.currentMode === 'light' ? 'grey' : 'white-50'">mdi-text-box-edit</v-icon>
                     <span class="text-caption font-weight-bold text-uppercase" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-2' : 'text-white-50'">Justificativas / Observações</span>
                </div>
                <v-textarea
                    v-model="notes"
                    placeholder="Descreva aqui se houve sangrias não registradas ou divergências..."
                    variant="outlined"
                    :bg-color="themeStore.currentMode === 'light' ? 'grey-lighten-5' : 'rgba(0,0,0,0.2)'"
                    :color="themeStore.currentMode === 'light' ? 'primary' : 'white'"
                    rows="3"
                    hide-details="auto"
                ></v-textarea>
            </div>

            <div class="d-flex gap-3">
                <v-btn
                    variant="outlined"
                    :color="themeStore.currentMode === 'light' ? 'grey-darken-1' : 'white-50'"
                    class="flex-1-1 rounded-lg font-weight-bold"
                    height="56"
                    @click="$emit('update:modelValue', false)"
                >
                    Cancelar
                </v-btn>

                <v-btn
                    color="error"
                    class="flex-grow-1 rounded-lg font-weight-bold shadow-glow-error text-body-1 letter-spacing-1 text-white"
                    height="56"
                    :loading="loading"
                    :disabled="!isValid"
                    @click="submitClosing"
                >
                    <div class="d-flex flex-column align-center lh-1">
                        <div class="d-flex align-center">
                            <v-icon start>mdi-printer</v-icon>
                            <span>ENCERRAR CAIXA</span>
                        </div>
                        <span class="text-[9px] opacity-80 mt-1 font-weight-medium">Gera Relatório Z e Bloqueia PDV</span>
                    </div>
                </v-btn>
            </div>

        </v-form>

      </div>
    </v-card>
  </v-dialog>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { useCashSessionStore } from '@/stores/cashSession'
import { useUserStore } from '@/stores/user'
import { useAppStore } from '@/stores/app'
import { useThemeStore } from '@/stores/theme'
import { useCashReport } from '@/composables/useCashReport'
import { format } from 'date-fns'

const props = defineProps({ modelValue: Boolean })
const emit = defineEmits(['update:modelValue', 'session-closed'])

const cashStore = useCashSessionStore()
const userStore = useUserStore()
const appStore = useAppStore()
const themeStore = useThemeStore()
const { generateClosingReport } = useCashReport()

const loading = ref(false)
const generatingReport = ref(false)
const cashAmount = ref('')
const notes = ref('')

const currentSession = computed(() => cashStore.currentSession)
const isValid = computed(() => cashAmount.value !== '' && !isNaN(parseFloat(cashAmount.value)) && parseFloat(cashAmount.value) >= 0)

const formatTime = (iso: string | undefined) => iso ? format(new Date(iso), 'HH:mm') : '--:--'

watch(() => props.modelValue, (val) => {
    if (val) { cashAmount.value = ''; notes.value = ''; }
})

const printPartialReport = async () => {
    generatingReport.value = true
    try {
        if (!cashStore.currentSession) return

        const sessionSnapshot = {
            ...cashStore.currentSession,
            final_balance_system: cashStore.summary.current_balance,
            final_balance_user: 0,
            difference: 0
        }

        await generateClosingReport(
            sessionSnapshot,
            cashStore.movements,
            userStore.activeStoreName,
            userStore.profile?.full_name || 'Operador',
            'RELATÓRIO PARCIAL (X)'
        )
        appStore.showSnackbar('Relatório Parcial gerado.', 'info')
    } catch(e) {
        appStore.showSnackbar('Erro ao gerar parcial.', 'error')
    } finally {
        generatingReport.value = false
    }
}

const submitClosing = async () => {
    if (!isValid.value) return
    if(!confirm('ATENÇÃO: Esta ação é irreversível. O turno será encerrado e o relatório Z será gerado. Confirmar?')) return

    loading.value = true
    try {
        const val = Number(cashAmount.value)
        const result = await cashStore.closeSession(val, notes.value)

        generateClosingReport(
            result.session,
            result.movements,
            userStore.activeStoreName,
            userStore.profile?.full_name || 'Operador'
        )

        appStore.showSnackbar('Caixa encerrado com sucesso!', 'success')
        emit('session-closed', result)
        emit('update:modelValue', false)

    } catch (e: any) {
        console.error(e)
        appStore.showSnackbar(e.message, 'error')
    } finally {
        loading.value = false
    }
}
</script>

<style scoped lang="scss">
.glass-modal-card { background: #121214; border: 1px solid rgba(255, 255, 255, 0.1); border-radius: 24px; box-shadow: 0 50px 100px -20px rgba(0,0,0,0.9); position: relative; }
.bg-glass-header { background: rgba(255, 255, 255, 0.03); }
.header-glow-bar-close { position: absolute; top: 0; left: 0; width: 4px; height: 100%; background: linear-gradient(to bottom, #ffea00, #ff6f00); box-shadow: 2px 0 15px rgba(255, 171, 0, 0.5); }
.icon-box-close { width: 56px; height: 56px; border-radius: 16px; display: flex; align-items: center; justify-content: center; border: 1px solid rgba(255,255,255,0.1); }
.bg-gradient-warning { background: linear-gradient(135deg, #ffca28, #ff6f00); }

/* Giant Input */
.glass-input-huge :deep(.v-field__input) {
    font-size: 1.8rem; font-weight: 900; text-align: right; padding-top: 10px; padding-bottom: 10px;
}

/* Theme Classes */
.glass-alert-box-warning { background: rgba(255, 193, 7, 0.05); border-color: rgba(255, 193, 7, 0.2) !important; }
.bg-warning-10 { background: rgba(255, 193, 7, 0.15); }
.border-warning-20 { border-color: rgba(255, 193, 7, 0.2) !important; }

.glass-info-box { background: rgba(255,255,255,0.03); }
.icon-circle-small { width: 36px; height: 36px; border-radius: 50%; display: flex; align-items: center; justify-content: center; }

.text-white-30 { color: rgba(255,255,255,0.3) !important; }
.text-white-50 { color: rgba(255,255,255,0.5) !important; }
.text-white-70 { color: rgba(255,255,255,0.7) !important; }
.bg-black-20 { background: rgba(0,0,0,0.2); }
.border-white-05 { border-color: rgba(255,255,255,0.05) !important; }
.border-white-10 { border-color: rgba(255,255,255,0.1) !important; }

.lh-1 { line-height: 1; } .lh-14 { line-height: 1.4; }
.h-16 { height: 16px; }
.gap-2 { gap: 8px; } .gap-3 { gap: 12px; } .gap-4 { gap: 16px; }
.z-10 { position: relative; z-index: 10; }
</style>
