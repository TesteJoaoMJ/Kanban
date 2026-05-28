<template>
  <v-dialog
    :model-value="modelValue"
    @update:model-value="$emit('update:modelValue', $event)"
    persistent
    max-width="550"
    content-class="submission-modal"
  >
    <v-card class="overflow-hidden rounded-xl border-thin elevation-24" :class="cardThemeClass">

        <div class="header-status pa-8 text-center relative overflow-hidden" :class="headerBgClass">
            <div class="absolute-bg-pattern"></div>

            <div class="relative z-10">
                <div class="status-icon-wrapper mx-auto mb-6 elevation-10 rounded-circle d-flex align-center justify-center" :class="iconBgClass">
                    <v-icon v-if="status.step === 'processing'" size="48" color="white" class="spin-slow">mdi-loading</v-icon>
                    <v-icon v-else-if="status.step === 'success'" size="48" color="white" class="animate-pop">mdi-check-bold</v-icon>
                    <v-icon v-else-if="status.step === 'error'" size="48" color="white" class="animate-shake">mdi-alert-circle</v-icon>
                </div>

                <h2 class="text-h5 font-weight-black mb-2" :class="textPrimaryClass">{{ titleText }}</h2>
                <p class="text-body-2 font-weight-medium opacity-80" :class="textSecondaryClass">{{ userMessage || 'Processando solicitação...' }}</p>
            </div>
        </div>

        <div class="px-8 py-6">
            <div class="d-flex flex-column gap-4">

                <div class="step-item d-flex align-center gap-4" :class="getStepOpacity(1)">
                    <div class="step-indicator" :class="getStepIndicatorClass(1)">
                        <v-icon size="14" color="white" v-if="currentStep > 1">mdi-check</v-icon>
                        <span v-else class="text-[10px] font-weight-bold">1</span>
                    </div>
                    <div class="flex-grow-1">
                        <div class="text-caption font-weight-bold uppercase" :class="textSecondaryClass">Criação do Pedido</div>
                        <div class="text-[10px] opacity-60">Gerando ID e salvando itens</div>
                    </div>
                    <v-progress-circular v-if="currentStep === 1 && status.step !== 'error'" indeterminate size="16" width="2" color="primary"></v-progress-circular>
                </div>

                <div class="step-item d-flex align-center gap-4" :class="getStepOpacity(2)">
                    <div class="step-indicator" :class="getStepIndicatorClass(2)">
                        <v-icon size="14" color="white" v-if="currentStep > 2">mdi-check</v-icon>
                        <span v-else class="text-[10px] font-weight-bold">2</span>
                    </div>
                    <div class="flex-grow-1">
                        <div class="text-caption font-weight-bold uppercase" :class="textSecondaryClass">Financeiro</div>
                        <div class="text-[10px] opacity-60">Lançando contas a receber/pagar</div>
                    </div>
                    <v-progress-circular v-if="currentStep === 2 && status.step !== 'error'" indeterminate size="16" width="2" color="primary"></v-progress-circular>
                </div>

                <div class="step-item d-flex align-center gap-4" :class="getStepOpacity(3)">
                    <div class="step-indicator" :class="getStepIndicatorClass(3)">
                        <v-icon size="14" color="white" v-if="currentStep > 3">mdi-check</v-icon>
                        <span v-else class="text-[10px] font-weight-bold">3</span>
                    </div>
                    <div class="flex-grow-1">
                        <div class="text-caption font-weight-bold uppercase" :class="textSecondaryClass">Integração</div>
                        <div class="text-[10px] opacity-60">Sincronizando estoque e ERP</div>
                    </div>
                    <v-progress-circular v-if="currentStep === 3 && status.step !== 'error'" indeterminate size="16" width="2" color="primary"></v-progress-circular>
                </div>

            </div>

            <v-expand-transition>
                <div v-if="status.step === 'error' && devMessage" class="mt-6 pa-3 rounded bg-red-lighten-5 border border-red-lighten-4">
                    <div class="d-flex align-center gap-2 mb-1 text-error">
                        <v-icon size="14">mdi-bug</v-icon>
                        <span class="text-[10px] font-weight-bold uppercase">Detalhe Técnico</span>
                    </div>
                    <div class="text-caption font-mono text-red-darken-3 break-all lh-1">{{ devMessage }}</div>
                </div>
            </v-expand-transition>
        </div>

        <div class="pa-6 pt-0 d-flex flex-column gap-3">
             <v-btn
                v-if="status.step === 'success'"
                block
                color="success"
                size="large"
                class="font-weight-bold rounded-lg shadow-soft"
                @click="$emit('close')"
             >
                Concluir e Ver Pedido
             </v-btn>

             <v-btn
                v-if="status.step === 'error'"
                block
                color="grey-darken-3"
                size="large"
                class="font-weight-bold rounded-lg"
                @click="$emit('close')"
             >
                Fechar e Corrigir
             </v-btn>

             <div v-if="status.step === 'processing'" class="text-center">
                 <span class="text-[10px] text-medium-emphasis font-weight-medium uppercase letter-spacing-1">Por favor aguarde...</span>
             </div>
        </div>

    </v-card>
  </v-dialog>
</template>

<script setup lang="ts">
import { computed } from 'vue';
import { useThemeStore } from '@/stores/theme';

const props = defineProps<{
  modelValue: boolean;
  status: { step: string };
  userMessage: string;
  devMessage?: string;
  clientName?: string;
}>();

defineEmits(['update:modelValue', 'close', 'whatsapp']);
const themeStore = useThemeStore();

const currentStep = computed(() => {
    // Lógica simplificada de progresso baseada na mensagem do usuário ou status
    // Idealmente o composable passaria o número do passo, mas vamos inferir
    if (props.status.step === 'success') return 4;
    if (props.status.step === 'error') return 1; // Ou onde parou

    const msg = props.userMessage.toLowerCase();
    if (msg.includes('financeiro')) return 2;
    if (msg.includes('estoque') || msg.includes('erp')) return 3;
    return 1;
});

const titleText = computed(() => {
    switch (props.status.step) {
        case 'success': return 'Sucesso!';
        case 'error': return 'Algo deu errado';
        default: return 'Lançando Pedido';
    }
});

// THEME CLASSES
const cardThemeClass = computed(() => themeStore.currentMode === 'light' ? 'bg-white' : 'bg-surface border-white-10');
const textPrimaryClass = computed(() => themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white');
const textSecondaryClass = computed(() => themeStore.currentMode === 'light' ? 'text-grey-darken-1' : 'text-white-70');

const headerBgClass = computed(() => {
    if (props.status.step === 'success') return 'bg-success-gradient';
    if (props.status.step === 'error') return 'bg-error-gradient';
    return themeStore.currentMode === 'light' ? 'bg-grey-lighten-4' : 'bg-surface-variant';
});

const iconBgClass = computed(() => {
    if (props.status.step === 'success') return 'bg-green-darken-1';
    if (props.status.step === 'error') return 'bg-red-darken-1';
    return 'bg-primary';
});

const getStepIndicatorClass = (step: number) => {
    if (currentStep.value > step) return 'bg-success text-white';
    if (currentStep.value === step) return 'bg-primary text-white scale-110 shadow-glow';
    return themeStore.currentMode === 'light' ? 'bg-grey-lighten-2 text-grey-darken-1' : 'bg-white-10 text-white-50';
};

const getStepOpacity = (step: number) => {
    if (currentStep.value >= step) return 'opacity-100';
    return 'opacity-40';
};

</script>

<style scoped lang="scss">
.submission-modal { overflow: visible; }
.relative { position: relative; }
.absolute-bg-pattern {
    position: absolute; top: 0; left: 0; width: 100%; height: 100%;
    background-image: radial-gradient(rgba(255,255,255,0.1) 1px, transparent 1px);
    background-size: 10px 10px; opacity: 0.5; z-index: 0;
}
.z-10 { position: relative; z-index: 10; }
.status-icon-wrapper { width: 80px; height: 80px; border: 4px solid rgba(255,255,255,0.2); }
.bg-success-gradient { background: linear-gradient(135deg, #66BB6A 0%, #43A047 100%); color: white !important; }
.bg-error-gradient { background: linear-gradient(135deg, #EF5350 0%, #C62828 100%); color: white !important; }

.step-indicator {
    width: 24px; height: 24px; border-radius: 50%;
    display: flex; align-items: center; justify-content: center;
    transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}
.scale-110 { transform: scale(1.1); }
.shadow-glow { box-shadow: 0 0 10px rgba(var(--v-theme-primary), 0.4); }

.animate-pop { animation: popIn 0.5s cubic-bezier(0.175, 0.885, 0.32, 1.275); }
.spin-slow { animation: spin 2s linear infinite; }
.animate-shake { animation: shake 0.5s; }

@keyframes popIn { 0% { transform: scale(0); } 100% { transform: scale(1); } }
@keyframes spin { 100% { transform: rotate(360deg); } }
@keyframes shake { 0%, 100% { transform: translateX(0); } 25% { transform: translateX(-5px); } 75% { transform: translateX(5px); } }

.shadow-soft { box-shadow: 0 10px 20px -10px rgba(0,0,0,0.1); }
.break-all { word-break: break-all; }
.lh-1 { line-height: 1.2; }
.text-white-70 { color: rgba(255,255,255,0.7); }
.border-white-10 { border-color: rgba(255,255,255,0.1) !important; }
</style>
