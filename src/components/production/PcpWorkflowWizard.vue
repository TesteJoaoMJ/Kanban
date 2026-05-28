<template>
  <div class="pcp-wizard-wrapper">

    <div class="wizard-fab-container" :class="{ 'fab-hidden': isOpen }">
      <div class="wizard-speech-bubble" v-show="showSpeechBubble">
        <div class="bubble-content">
          <span class="bubble-title">Não sabe por onde começar?</span>
          <span class="bubble-text">Crie seu fluxo completo em 3 passos! 🪄</span>
        </div>
        <div class="bubble-tail"></div>
      </div>

      <button class="wizard-fab" @click="openWizard" @mouseenter="showSpeechBubble = true" @mouseleave="hideSpeechBubble">
        <div class="fab-shine"></div>
        <div class="avatar-wrapper">
          <v-icon size="34" color="white">mdi-robot-excited-outline</v-icon>
        </div>
      </button>
    </div>

    <v-dialog
      v-model="isOpen"
      max-width="950"
      persistent
      transition="dialog-bottom-transition"
      attach="body"
      style="z-index: 99999;"
    >
      <v-card class="wizard-card rounded-xl overflow-hidden bg-surface border shadow-2xl">

        <div class="wizard-header bg-alternate pa-6 border-b d-flex justify-space-between align-center relative overflow-hidden">
          <div class="header-glow"></div>
          <div class="relative z-10 d-flex align-center gap-4">
            <div class="icon-box bg-primary rounded-lg d-flex align-center justify-center shadow-lg" style="width: 48px; height: 48px;">
              <v-icon color="white" size="28">mdi-magic-staff</v-icon>
            </div>
            <div>
              <h2 class="text-h5 font-weight-black text-primary letter-spacing-1 tracking-tight lh-1 mb-1">
                Assistente de Workflow
              </h2>
              <p class="text-caption text-secondary font-weight-medium mb-0">Inteligência artificial baseada no seu nicho.</p>
            </div>
          </div>
          <v-btn icon="mdi-close" variant="tonal" size="small" color="secondary" class="z-10" @click="isOpen = false"></v-btn>
        </div>

        <div class="wizard-progress-bar">
          <div class="progress-fill" :style="{ width: `${(step / 3) * 100}%` }"></div>
        </div>

        <v-window v-model="step" class="wizard-content custom-scrollbar bg-surface" style="min-height: 500px;">

          <v-window-item :value="1" class="pa-8">
            <div class="text-center mb-8">
              <h3 class="text-h5 font-weight-black text-primary">Qual é o nicho da sua operação?</h3>
              <p class="text-body-2 text-secondary mt-2">Selecionaremos as melhores práticas baseadas no seu setor.</p>
            </div>

            <div class="niche-grid">
              <div
                v-for="(niche, index) in niches"
                :key="niche.id"
                class="niche-card animated-card"
                :class="{ 'active': selectedNiche === niche.id }"
                :style="{ animationDelay: `${index * 0.05}s` }"
                @click="selectedNiche = niche.id"
              >
                <div class="niche-icon-wrapper" :class="{ 'bg-primary text-white': selectedNiche === niche.id, 'bg-grey-lighten-4 text-grey-darken-2': selectedNiche !== niche.id }">
                  <v-icon size="28">{{ niche.icon }}</v-icon>
                </div>
                <span class="mt-4 font-weight-bold text-[14px]">{{ niche.name }}</span>
              </div>
            </div>
          </v-window-item>

          <v-window-item :value="2" class="pa-8">
            <div class="text-center mb-8">
              <h3 class="text-h5 font-weight-black text-primary">Ajustes Finos do Processo</h3>
              <p class="text-body-2 text-secondary mt-2">Ligue ou desligue recursos para moldar o esqueleto do fluxo.</p>
            </div>

            <div class="questions-grid">
              <div class="question-item bg-alternate pa-5 rounded-xl border d-flex flex-column gap-3 hover-elevate transition-all">
                <div class="d-flex align-center gap-3 mb-2">
                  <v-icon color="indigo">mdi-import</v-icon>
                  <p class="font-weight-black text-subtitle-1 mb-0">Origem dos Pedidos</p>
                </div>
                <v-radio-group v-model="config.origin" inline color="indigo" hide-details class="mt-0">
                  <v-radio label="ERP / Vendas" value="erp"></v-radio>
                  <v-radio label="E-commerce" value="ecommerce"></v-radio>
                  <v-radio label="Manual" value="manual"></v-radio>
                </v-radio-group>
              </div>

              <div class="question-item bg-alternate pa-5 rounded-xl border d-flex justify-space-between align-start hover-elevate transition-all">
                <div>
                  <div class="d-flex align-center gap-2 mb-1">
                    <v-icon color="blue" size="20">mdi-account-check</v-icon>
                    <p class="font-weight-black text-subtitle-2 mb-0">Aprovação de Cliente</p>
                  </div>
                  <p class="text-[11px] text-secondary lh-1-2 pe-4">Exige aprovação de artes, orçamentos ou amostras antes da produção?</p>
                </div>
                <v-switch v-model="config.hasCustomerApproval" color="blue" hide-details inset density="compact"></v-switch>
              </div>

              <div class="question-item bg-alternate pa-5 rounded-xl border d-flex justify-space-between align-start hover-elevate transition-all">
                <div>
                  <div class="d-flex align-center gap-2 mb-1">
                    <v-icon color="error" size="20">mdi-shield-alert</v-icon>
                    <p class="font-weight-black text-subtitle-2 mb-0">Qualidade & Retrabalho</p>
                  </div>
                  <p class="text-[11px] text-secondary lh-1-2 pe-4">Incluir etapa de inspeção com devolução obrigatória por falhas?</p>
                </div>
                <v-switch v-model="config.hasQualityControl" color="error" hide-details inset density="compact"></v-switch>
              </div>

              <div class="question-item bg-alternate pa-5 rounded-xl border d-flex justify-space-between align-start hover-elevate transition-all">
                <div>
                  <div class="d-flex align-center gap-2 mb-1">
                    <v-icon color="purple" size="20">mdi-robot-industrial</v-icon>
                    <p class="font-weight-black text-subtitle-2 mb-0">Apontamento Operacional</p>
                  </div>
                  <p class="text-[11px] text-secondary lh-1-2 pe-4">Coletar dados de qual máquina e qual operador executou a tarefa?</p>
                </div>
                <v-switch v-model="config.hasMachineTracking" color="purple" hide-details inset density="compact"></v-switch>
              </div>

              <div class="question-item bg-alternate pa-5 rounded-xl border d-flex justify-space-between align-start hover-elevate transition-all">
                <div>
                  <div class="d-flex align-center gap-2 mb-1">
                    <v-icon color="teal" size="20">mdi-package-variant-closed</v-icon>
                    <p class="font-weight-black text-subtitle-2 mb-0">Baixa de Estoque</p>
                  </div>
                  <p class="text-[11px] text-secondary lh-1-2 pe-4">O fluxo deve incluir separação de matéria-prima antes de produzir?</p>
                </div>
                <v-switch v-model="config.hasStockIntegration" color="teal" hide-details inset density="compact"></v-switch>
              </div>

               <div class="question-item bg-alternate pa-5 rounded-xl border d-flex justify-space-between align-start hover-elevate transition-all">
                <div>
                  <div class="d-flex align-center gap-2 mb-1">
                    <v-icon color="success" size="20">mdi-truck-fast</v-icon>
                    <p class="font-weight-black text-subtitle-2 mb-0">Logística e Expedição</p>
                  </div>
                  <p class="text-[11px] text-secondary lh-1-2 pe-4">O item vai para faturamento e despacho ao final do processo?</p>
                </div>
                <v-switch v-model="config.hasBilling" color="success" hide-details inset density="compact"></v-switch>
              </div>
            </div>
          </v-window-item>

          <v-window-item :value="3" class="pa-8 d-flex flex-column align-center justify-center text-center relative overflow-hidden" style="min-height: 500px;">

            <div class="success-particles absolute inset-0 pointer-events-none opacity-30"></div>

            <div class="preview-hero mb-8 position-relative">
               <div class="hero-glow-bg"></div>
               <div class="hero-icon-pulse">
                 <v-icon size="80" color="primary" class="relative z-10">mdi-auto-fix</v-icon>
               </div>
            </div>
            <h3 class="text-h3 font-weight-black text-primary mb-4 letter-spacing-1 tracking-tight">Tudo Pronto!</h3>
            <p class="text-body-1 text-secondary max-w-500 mb-10 lh-relaxed">
              Estruturamos a melhor arquitetura para o modelo de <b class="text-primary">{{ currentNicheName }}</b>.
              Criaremos as abas, botões internos, formulários e regras de rota automaticamente no quadro.
            </p>

            <button class="btn-generate premium-btn" @click="generateWorkflow" :disabled="isGenerating">
              <span class="btn-shine"></span>
              <span class="relative z-10 d-flex align-center font-weight-black text-[16px]">
                <v-icon class="mr-3" size="24" :class="{'mdi-spin': isGenerating}">{{ isGenerating ? 'mdi-loading' : 'mdi-creation' }}</v-icon>
                {{ isGenerating ? 'MOLDANDO FLUXO...' : 'GERAR WORKFLOW AGORA' }}
              </span>
            </button>
          </v-window-item>

        </v-window>

        <div class="wizard-footer bg-alternate pa-5 border-t d-flex justify-space-between align-center" v-if="step < 3">
          <v-btn variant="text" class="font-weight-bold" color="secondary" :disabled="step === 1" @click="step--">
            <v-icon start>mdi-arrow-left</v-icon> Voltar
          </v-btn>

          <div class="step-indicators d-flex gap-3">
            <div class="step-dot" :class="{ 'active': step >= 1 }"></div>
            <div class="step-dot" :class="{ 'active': step >= 2 }"></div>
            <div class="step-dot" :class="{ 'active': step >= 3 }"></div>
          </div>

          <v-btn color="primary" variant="flat" class="px-8 rounded-lg font-weight-black shadow-lg" :disabled="step === 1 && !selectedNiche" @click="step++">
            Próximo <v-icon end>mdi-arrow-right</v-icon>
          </v-btn>
        </div>

      </v-card>
    </v-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { useDynamicPcpStore } from '@/stores/dynamicPcpStore';
import { useAppStore } from '@/stores/app';

const isOpen = ref(false);
const step = ref(1);
const showSpeechBubble = ref(false);
const isFirstLoad = ref(true);
const isGenerating = ref(false);

const pcpStore = useDynamicPcpStore();
const appStore = useAppStore();

let hideTimeout: any;

onMounted(() => {
  // Mostra o balão automaticamente ao carregar
  setTimeout(() => { showSpeechBubble.value = true; }, 1500);
  // Esconde depois de 8 segundos se o usuário não interagir
  setTimeout(() => { showSpeechBubble.value = false; isFirstLoad.value = false; }, 8000);
});

function hideSpeechBubble() {
  hideTimeout = setTimeout(() => { showSpeechBubble.value = false; }, 500);
}

function openWizard() {
  step.value = 1;
  isOpen.value = true;
  showSpeechBubble.value = false;
  isFirstLoad.value = false;
  if(hideTimeout) clearTimeout(hideTimeout);
}

// ESTADO DO WIZARD
const selectedNiche = ref<string | null>(null);
const config = ref({
  origin: 'erp',
  hasCustomerApproval: false,
  hasQualityControl: true,
  hasMachineTracking: true,
  hasStockIntegration: true,
  hasBilling: true
});

const niches = [
  { id: 'confeccao', name: 'Confecção / Moda', icon: 'mdi-tshirt-crew' },
  { id: 'estamparia', name: 'Gráfica / Estamparia', icon: 'mdi-palette' },
  { id: 'textil', name: 'Indústria Têxtil', icon: 'mdi-factory' },
  { id: 'engenharia', name: 'Engenharia / Obras', icon: 'mdi-ruler-square' },
  { id: 'oficina', name: 'Oficina / Manutenção', icon: 'mdi-car-wrench' },
  { id: 'alimentacao', name: 'Restaurante / Padaria', icon: 'mdi-silverware-fork-knife' },
  { id: 'varejo', name: 'Varejo / Separação', icon: 'mdi-storefront' },
  { id: 'servicos', name: 'Prestação de Serviços', icon: 'mdi-briefcase-account' },
  { id: 'generico', name: 'Fluxo Genérico', icon: 'mdi-sitemap' }
];

const currentNicheName = computed(() => niches.find(n => n.id === selectedNiche.value)?.name || '');

async function generateWorkflow() {
  isGenerating.value = true;
  try {
    // A function no store precisa estar preparada para receber o hasStockIntegration, se não estiver, ela ignora.
    await pcpStore.generateWizardWorkflow(selectedNiche.value, config.value);
    appStore.showSnackbar('🪄 Workflow gerado com sucesso! A tela será atualizada.', 'success');

    setTimeout(() => {
       isOpen.value = false;
       isGenerating.value = false;
       // Força um pequeno refresh visual
       window.dispatchEvent(new Event('resize'));
    }, 1000);

  } catch (error: any) {
    appStore.showSnackbar('Erro ao gerar workflow: ' + error.message, 'error');
    isGenerating.value = false;
  }
}
</script>

<style scoped>
/* ==============================================
   BOTÃO FLUTUANTE (FAB) COM BALÃO
============================================== */
.wizard-fab-container {
  position: fixed;
  bottom: 40px;
  right: 40px;
  z-index: 9900;
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  transition: opacity 0.3s, transform 0.3s;
}

.fab-hidden {
  opacity: 0;
  pointer-events: none;
  transform: translateY(20px) scale(0.8);
}

.wizard-speech-bubble {
  position: absolute;
  bottom: 85px;
  right: 10px;
  background: linear-gradient(135deg, #ffffff 0%, #f8fafc 100%);
  border: 1px solid #e2e8f0;
  border-radius: 16px;
  padding: 16px 20px;
  box-shadow: 0 15px 35px -5px rgba(0, 0, 0, 0.15), 0 5px 15px rgba(0, 0, 0, 0.05);
  width: max-content;
  max-width: 280px;
  transform-origin: bottom right;
  animation: pop-in 0.5s cubic-bezier(0.175, 0.885, 0.32, 1.275) forwards, float-bubble 4s ease-in-out infinite alternate;
}

.bubble-content { display: flex; flex-direction: column; gap: 4px; }
.bubble-title { font-size: 14px; font-weight: 900; color: #0f172a; letter-spacing: -0.02em; }
.bubble-text { font-size: 12px; font-weight: 600; color: #64748b; line-height: 1.4; }

.bubble-tail {
  position: absolute;
  bottom: -8px;
  right: 24px;
  width: 16px;
  height: 16px;
  background: #f8fafc;
  border-right: 1px solid #e2e8f0;
  border-bottom: 1px solid #e2e8f0;
  transform: rotate(45deg);
}

.wizard-fab {
  width: 72px;
  height: 72px;
  border-radius: 50%;
  background: linear-gradient(135deg, #4f46e5 0%, #1e1b4b 100%);
  border: 3px solid #ffffff;
  box-shadow: 0 15px 30px -5px rgba(79, 70, 229, 0.6), 0 0 0 0 rgba(79, 70, 229, 0.4);
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  position: relative;
  overflow: hidden;
  animation: pulse-ring 3s infinite;
  transition: transform 0.3s cubic-bezier(0.175, 0.885, 0.32, 1.275), box-shadow 0.3s;
}

.wizard-fab:hover {
  transform: scale(1.1) translateY(-5px);
  box-shadow: 0 25px 40px -5px rgba(79, 70, 229, 0.8), 0 0 0 0 rgba(79, 70, 229, 0);
}

.avatar-wrapper { position: relative; z-index: 2; transition: transform 0.3s ease; }
.wizard-fab:hover .avatar-wrapper { transform: rotate(-15deg) scale(1.15); }

.fab-shine {
  position: absolute; top: 0; left: -150%; width: 50%; height: 100%;
  background: linear-gradient(to right, rgba(255,255,255,0) 0%, rgba(255,255,255,0.4) 50%, rgba(255,255,255,0) 100%);
  transform: skewX(-25deg); z-index: 1; animation: shine-effect 4s cubic-bezier(0.4, 0, 0.2, 1) infinite;
}

/* ==============================================
   MODAL UI & INTERFACES (PREMIUM)
============================================== */
.wizard-card {
  border: 1px solid rgba(255,255,255,0.2) !important;
  background: rgba(255, 255, 255, 0.98) !important;
  backdrop-filter: blur(20px);
}
.bg-surface { background-color: transparent; }
.bg-alternate { background-color: #f8fafc; }
.border { border: 1px solid #e2e8f0; }

/* HEADER */
.wizard-header { background: linear-gradient(to right, #f8fafc, #ffffff); }
.header-glow { position: absolute; right: -50px; top: -50px; width: 200px; height: 200px; background: radial-gradient(circle, rgba(79, 70, 229, 0.1) 0%, transparent 70%); border-radius: 50%; }

/* PROGRESS BAR */
.wizard-progress-bar { height: 4px; background: #e2e8f0; width: 100%; position: relative; }
.progress-fill { height: 100%; background: linear-gradient(90deg, #4f46e5, #ec4899); transition: width 0.5s cubic-bezier(0.25, 0.8, 0.25, 1); }

/* GRID DE NICHOS */
.niche-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
  gap: 20px;
}
.niche-card {
  background: #ffffff;
  border: 2px solid #e2e8f0;
  border-radius: 16px;
  padding: 24px;
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
  cursor: pointer;
  transition: all 0.3s cubic-bezier(0.175, 0.885, 0.32, 1.275);
  color: #64748b;
  opacity: 0;
  animation: slide-up-fade 0.6s forwards;
}
.niche-icon-wrapper { width: 64px; height: 64px; border-radius: 50%; display: flex; align-items: center; justify-content: center; transition: 0.3s; margin-bottom: 8px; }
.niche-card:hover { border-color: #cbd5e1; transform: translateY(-4px); box-shadow: 0 15px 25px -5px rgba(0,0,0,0.05); }
.niche-card.active { border-color: #4f46e5; background: #f5f3ff; color: #1e1b4b; box-shadow: 0 0 0 4px rgba(79, 70, 229, 0.1); transform: translateY(-4px); }
.niche-card.active .niche-icon-wrapper { background: #4f46e5 !important; color: white !important; box-shadow: 0 10px 20px rgba(79, 70, 229, 0.3); }

/* PERGUNTAS GRID */
.questions-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; }
@media (max-width: 768px) { .questions-grid { grid-template-columns: 1fr; } }
.question-item { background: #ffffff; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.02); border: 1px solid #f1f5f9; }
.hover-elevate:hover { transform: translateY(-2px); box-shadow: 0 10px 20px -5px rgba(0,0,0,0.08); border-color: #cbd5e1; }

/* DOTS */
.step-dot { width: 10px; height: 10px; border-radius: 50%; background: #cbd5e1; transition: 0.4s cubic-bezier(0.175, 0.885, 0.32, 1.275); }
.step-dot.active { background: #4f46e5; transform: scale(1.4); }

/* BOTÃO GERAR (ULTRA PREMIUM) */
.premium-btn {
  background: linear-gradient(135deg, #111827 0%, #374151 100%);
  color: #ffffff;
  padding: 20px 48px;
  border-radius: 16px;
  border: none;
  cursor: pointer;
  position: relative;
  overflow: hidden;
  box-shadow: 0 20px 40px rgba(17, 24, 39, 0.3), inset 0 1px 0 rgba(255,255,255,0.2);
  transition: all 0.3s ease;
}
.premium-btn:hover { transform: translateY(-4px); box-shadow: 0 25px 50px rgba(17, 24, 39, 0.4), inset 0 1px 0 rgba(255,255,255,0.3); }
.premium-btn:active { transform: translateY(2px); box-shadow: 0 10px 20px rgba(17, 24, 39, 0.3); }
.premium-btn:disabled { opacity: 0.8; cursor: not-allowed; transform: none; background: #374151; }
.btn-shine { position: absolute; top: 0; left: -100%; width: 50%; height: 100%; background: linear-gradient(to right, rgba(255,255,255,0) 0%, rgba(255,255,255,0.2) 50%, rgba(255,255,255,0) 100%); transform: skewX(-25deg); animation: shine 3s infinite; }

/* ANIMAÇÕES GERAIS */
@keyframes slide-up-fade { 0% { opacity: 0; transform: translateY(20px); } 100% { opacity: 1; transform: translateY(0); } }
@keyframes pop-in { 0% { opacity: 0; transform: scale(0.8) translateY(15px); } 100% { opacity: 1; transform: scale(1) translateY(0); } }
@keyframes float-bubble { 0%, 100% { transform: translateY(0); } 50% { transform: translateY(-8px); } }
@keyframes shine-effect { 0% { left: -150%; } 20% { left: 200%; } 100% { left: 200%; } }
@keyframes shine { 0% { left: -100%; } 20% { left: 200%; } 100% { left: 200%; } }
@keyframes pulse-ring { 0% { box-shadow: 0 0 0 0 rgba(79, 70, 229, 0.5); } 70% { box-shadow: 0 0 0 25px rgba(79, 70, 229, 0); } 100% { box-shadow: 0 0 0 0 rgba(79, 70, 229, 0); } }

.hero-icon-pulse { animation: hero-pulse 2s infinite alternate ease-in-out; }
@keyframes hero-pulse { 0% { transform: scale(1); filter: drop-shadow(0 0 10px rgba(79, 70, 229, 0.4)); } 100% { transform: scale(1.1); filter: drop-shadow(0 0 25px rgba(79, 70, 229, 0.8)); } }
.hero-glow-bg { position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%); width: 180px; height: 180px; background: radial-gradient(circle, rgba(79, 70, 229, 0.15) 0%, transparent 70%); border-radius: 50%; z-index: 0; }

.success-particles { background-image: radial-gradient(#cbd5e1 2px, transparent 2px); background-size: 30px 30px; animation: pan-bg 20s linear infinite; }
@keyframes pan-bg { 0% { background-position: 0 0; } 100% { background-position: 300px 300px; } }
</style>
