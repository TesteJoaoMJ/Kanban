<template>
  <v-dialog v-model="dialog" max-width="550" transition="dialog-bottom-transition">
    <v-card class="support-premium-card rounded-xl overflow-hidden">

      <div class="glass-noise"></div>
      <div class="glass-gradient"></div>

      <div class="hero-header pa-8 text-center position-relative z-index-2">
        <div class="hero-icon-ring mb-4 mx-auto">
          <v-icon color="amber-accent-2" size="40">mdi-shield-key-outline</v-icon>
        </div>
        <h3 class="text-h5 font-weight-black text-white mb-2 tracking-wide">Recuperação de Acesso</h3>
        <p class="text-blue-grey-lighten-2 text-body-2">
          Não se preocupe. Conectaremos você diretamente ao nosso time de segurança para restaurar sua conta.
        </p>

        <v-btn icon variant="text" class="close-btn" @click="dialog = false">
          <v-icon color="white">mdi-close</v-icon>
        </v-btn>
      </div>

      <v-card-text class="pa-6 position-relative z-index-2">

        <div v-if="!success">

          <div class="diagnostic-card pa-4 rounded-lg mb-6 border-amber-thin">
            <div class="d-flex align-center justify-space-between mb-3">
              <span class="text-caption font-weight-bold text-amber-accent-2 text-uppercase">
                <v-icon start size="x-small">mdi-radar</v-icon> Diagnóstico de Sessão
              </span>
              <span class="text-caption text-grey font-mono">ID: {{ incidentId }}</span>
            </div>

            <div class="meta-grid">
              <div class="meta-item">
                <v-icon size="small" color="blue-grey" class="mr-2">mdi-laptop</v-icon>
                <div class="d-flex flex-column">
                  <span class="text-caption text-grey-darken-1 lh-1">Dispositivo</span>
                  <span class="text-caption text-white font-weight-medium">{{ clientOS }}</span>
                </div>
              </div>

              <div class="meta-item">
                <v-icon size="small" color="blue-grey" class="mr-2">mdi-ip-network</v-icon>
                <div class="d-flex flex-column">
                  <span class="text-caption text-grey-darken-1 lh-1">Rede</span>
                  <span class="text-caption text-white font-weight-medium">{{ clientIP }}</span>
                </div>
              </div>
            </div>
          </div>

          <v-form @submit.prevent="handleSendWhatsapp" ref="formRef">
            <div class="text-caption text-white font-weight-bold ml-1 mb-2">Qual seu e-mail ou usuário?</div>
            <v-text-field
              v-model="email"
              placeholder="ex: seu.nome@empresa.com"
              variant="outlined"
              bg-color="rgba(0,0,0,0.4)"
              color="amber-accent-3"
              class="glass-input-premium"
              prepend-inner-icon="mdi-account-search"
              rounded="lg"
              :rules="[rules.required]"
              :disabled="loading"
            ></v-text-field>
          </v-form>
        </div>

        <div v-else class="text-center py-6 fade-in">
          <div class="success-pulse mb-6 mx-auto">
            <v-icon size="48" color="green-accent-2">mdi-whatsapp</v-icon>
          </div>
          <h3 class="text-h5 font-weight-bold text-white mb-2">Solicitação Aberta!</h3>
          <p class="text-grey-lighten-1 text-body-2 mb-8 px-4">
            O WhatsApp Web foi aberto com seus dados de diagnóstico. Basta enviar a mensagem para iniciar o atendimento prioritário.
          </p>
          <v-btn variant="tonal" color="white" rounded="pill" class="px-8" @click="dialog = false">
            Retornar ao Login
          </v-btn>
        </div>

      </v-card-text>

      <div v-if="!success" class="pa-6 pt-0 d-flex flex-column gap-3 position-relative z-index-2">
        <v-btn
          block
          height="54"
          color="green-accent-4"
          class="whatsapp-glow-btn text-white font-weight-bold text-body-1"
          rounded="lg"
          :loading="loading"
          @click="handleSendWhatsapp"
        >
          <v-icon start size="24" class="mr-2">mdi-whatsapp</v-icon>
          Falar com Suporte Agora
        </v-btn>

        <div class="text-center">
          <v-btn
            variant="text"
            size="small"
            color="grey-lighten-1"
            class="opacity-70 hover-opacity-100"
            @click="dialog = false"
          >
            Cancelar e voltar
          </v-btn>
        </div>
      </div>

    </v-card>
  </v-dialog>
</template>

<script setup lang="ts">
import { ref } from 'vue';

const dialog = ref(false);
const email = ref('');
const loading = ref(false);
const success = ref(false);
const formRef = ref<any>(null); // ADICIONADO: Referência para o formulário Vuetify

// Metadados
const clientIP = ref('Detectando...');
const clientOS = ref('Identificando...');
const timeStr = ref('');
const incidentId = ref(Math.random().toString(36).substring(2, 8).toUpperCase());

const rules = {
  required: (v: string) => !!v || 'Por favor, informe sua identificação.',
};

// Detecção de OS Melhorada
const detectOS = () => {
  const userAgent = window.navigator.userAgent;
  const platform = window.navigator.platform;
  const macosPlatforms = ['Macintosh', 'MacIntel', 'MacPPC', 'Mac68K'];
  const windowsPlatforms = ['Win32', 'Win64', 'Windows', 'WinCE'];
  const iosPlatforms = ['iPhone', 'iPad', 'iPod'];

  if (macosPlatforms.indexOf(platform) !== -1) return 'macOS Workstation';
  if (iosPlatforms.indexOf(platform) !== -1) return 'iOS Mobile';
  if (windowsPlatforms.indexOf(platform) !== -1) return 'Windows PC';
  if (/Android/.test(userAgent)) return 'Android Mobile';
  if (/Linux/.test(platform)) return 'Linux System';
  return 'Dispositivo Genérico';
};

const open = (prefill: string = '') => {
  email.value = prefill;
  success.value = false;
  loading.value = false;
  dialog.value = true;
  timeStr.value = new Date().toLocaleTimeString('pt-BR');

  clientOS.value = detectOS();
  fetchIP();
};

const fetchIP = async () => {
  try {
    const res = await fetch('https://api.ipify.org?format=json');
    if(res.ok) {
      const data = await res.json();
      clientIP.value = data.ip;
    }
  } catch { clientIP.value = 'Rede Privada/VPN'; }
};

const handleSendWhatsapp = async () => {
  // CORREÇÃO AQUI: Usando formRef.value.validate() em vez de querySelector
  let valid = true;
  if (formRef.value) {
    const validationResult = await formRef.value.validate();
    valid = validationResult.valid;
  }

  // Se não for válido e também não tiver email (fallback), cancela
  if (!valid && !email.value) return;

  loading.value = true;

  // UX: Pequeno delay para dar sensação de processamento seguro
  await new Promise(resolve => setTimeout(resolve, 1200));

  const phone = '5515991876055'; // Seu número
  const text = `🔐 *SUPORTE DE ACESSO (PRIORITÁRIO)*\n\n` +
               `Olá, preciso de ajuda para recuperar meu acesso.\n\n` +
               `👤 *Usuário:* ${email.value}\n` +
               `🎫 *Ticket:* #${incidentId.value}\n` +
               `💻 *Sistema:* ${clientOS.value}\n` +
               `🌐 *IP:* ${clientIP.value}\n\n` +
               `_Aguardando instruções de reset._`;

  const url = `https://wa.me/${phone}?text=${encodeURIComponent(text)}`;

  window.open(url, '_blank');

  loading.value = false;
  success.value = true;
};

defineExpose({ open });
</script>

<style scoped lang="scss">
.support-premium-card {
  background: #0f0f13;
  border: 1px solid rgba(255, 255, 255, 0.08);
  box-shadow: 0 50px 100px -20px rgba(0, 0, 0, 0.8);
  position: relative;
}

/* Background Effects */
.glass-noise {
  position: absolute; top:0; left:0; right:0; bottom:0;
  background-image: url("data:image/svg+xml,%3Csvg viewBox='0 0 200 200' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='noiseFilter'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.8' numOctaves='3' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23noiseFilter)' opacity='0.03'/%3E%3C/svg%3E");
  pointer-events: none; z-index: 0;
}
.glass-gradient {
  position: absolute; top:0; left:0; width:100%; height:100%;
  background: radial-gradient(circle at top center, rgba(255, 171, 0, 0.06), transparent 60%);
  pointer-events: none; z-index: 0;
}

/* Header Styles */
.hero-header {
  background: linear-gradient(to bottom, rgba(255, 255, 255, 0.03), transparent);
  border-bottom: 1px solid rgba(255, 255, 255, 0.05);
}
.hero-icon-ring {
  width: 80px; height: 80px; border-radius: 50%;
  background: rgba(255, 193, 7, 0.1);
  border: 1px solid rgba(255, 193, 7, 0.2);
  box-shadow: 0 0 30px rgba(255, 193, 7, 0.15);
  display: flex; align-items: center; justify-content: center;
}
.close-btn { position: absolute; top: 16px; right: 16px; opacity: 0.7; }
.tracking-wide { letter-spacing: 0.5px; }

/* Diagnostic Card */
.diagnostic-card {
  background: rgba(0, 0, 0, 0.3);
  border: 1px dashed rgba(255, 255, 255, 0.15);
  transition: all 0.3s ease;
}
.diagnostic-card:hover {
  background: rgba(0, 0, 0, 0.5);
  border-color: rgba(255, 215, 64, 0.4);
}
.border-amber-thin { border-color: rgba(255, 193, 7, 0.15); }

.meta-grid {
  display: grid; grid-template-columns: 1fr 1fr; gap: 12px;
}
.meta-item {
  display: flex; align-items: center;
  background: rgba(255, 255, 255, 0.03);
  padding: 8px 12px; border-radius: 8px;
}
.lh-1 { line-height: 1.2; }
.font-mono { font-family: 'Courier New', Courier, monospace; letter-spacing: -0.5px; }

/* Inputs & Buttons */
.glass-input-premium :deep(.v-field) {
  border-radius: 12px !important;
  border: 1px solid rgba(255, 255, 255, 0.1);
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}
.glass-input-premium :deep(.v-field--focused) {
  background: rgba(0, 0, 0, 0.6) !important;
  border-color: #FFD740 !important;
  box-shadow: 0 0 0 4px rgba(255, 215, 64, 0.15);
}

.whatsapp-glow-btn {
  background: linear-gradient(135deg, #00C853 0%, #00E676 100%);
  box-shadow: 0 8px 25px rgba(0, 230, 118, 0.3);
  transition: transform 0.2s, box-shadow 0.2s;
  letter-spacing: 0.5px;
}
.whatsapp-glow-btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 12px 30px rgba(0, 230, 118, 0.4);
}

/* Success Animation */
.success-pulse {
  width: 90px; height: 90px; margin: 0 auto;
  border-radius: 50%;
  background: rgba(0, 230, 118, 0.1);
  border: 2px solid #00E676;
  display: flex; align-items: center; justify-content: center;
  animation: pulse-ring 2s infinite;
}
@keyframes pulse-ring {
  0% { box-shadow: 0 0 0 0 rgba(0, 230, 118, 0.4); }
  70% { box-shadow: 0 0 0 20px rgba(0, 230, 118, 0); }
  100% { box-shadow: 0 0 0 0 rgba(0, 230, 118, 0); }
}

.fade-in { animation: fadeIn 0.6s ease-out; }
@keyframes fadeIn { from { opacity: 0; transform: translateY(10px); } to { opacity: 1; transform: translateY(0); } }

.hover-opacity-100:hover { opacity: 1 !important; }
.gap-3 { gap: 12px; }
</style>
