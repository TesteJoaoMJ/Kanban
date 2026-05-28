<template>
  <v-theme-provider :theme="currentThemeName" with-background class="fill-height">
    <div class="login-wrapper fill-height">

      <div class="background-carousel">
        <div
          v-for="(bg, index) in backgrounds"
          :key="index"
          class="bg-slide"
          :style="{ backgroundImage: `url(${bg})` }"
          :class="{ 'active': currentBgIndex === index }"
        ></div>
        <div class="bg-overlay-gradient" :class="overlayClass"></div>
      </div>

      <div class="particles-container"></div>

      <v-container fluid class="fill-height position-relative z-index-2 pa-0">
        <v-row class="fill-height ma-0" no-gutters>

          <v-col cols="12" md="6" lg="7" class="d-none d-md-flex flex-column py-12 px-16 left-column">
            <div class="brand-center fade-in-left delay-1 my-auto">
              <div class="digital-clock mb-8 text-white">
                <span class="time font-weight-black lh-1">{{ currentTime }}</span>
                <span class="date text-h6 font-weight-light text-grey-lighten-1 d-block mt-n1">{{ currentDate }}</span>
              </div>

              <h1 class="display-title font-weight-black text-white mb-6 lh-1 text-shadow-lg">
                Gestão Inteligente<br>
                <span class="text-blue-accent-2">Para o seu Negócio.</span>
              </h1>

              <div class="message-slider">
                <v-window v-model="currentMessageIndex" :show-arrows="false" vertical class="h-auto" direction="vertical">
                  <v-window-item v-for="(msg, i) in marketingMessages" :key="i" :value="i">
                    <p class="text-h6 text-grey-lighten-2 font-weight-regular max-width-650 line-height-relaxed slide-text text-shadow-md">
                      {{ msg.text }}
                    </p>
                  </v-window-item>
                </v-window>

                <div class="d-flex mt-8">
                  <div
                    v-for="(_, i) in marketingMessages"
                    :key="i"
                    class="slider-dot mr-3"
                    :class="{ 'active': currentMessageIndex === i }"
                    @click="currentMessageIndex = i"
                  ></div>
                </div>
              </div>
            </div>

            <div class="brand-footer d-flex align-center gap-6 text-caption text-grey-lighten-3 fade-in-up delay-2 text-shadow-sm">
              <router-link :to="{ name: 'Privacy' }" class="footer-link hover-bright">
                <v-icon size="small" class="mr-2">mdi-shield-check-outline</v-icon> Política de Privacidade
              </router-link>
              <router-link :to="{ name: 'Terms' }" class="footer-link hover-bright">Termos de Uso</router-link>
              <span class="opacity-50">|</span>
              <span class="opacity-70">Versão 2.5.0 (Stable)</span>
            </div>
          </v-col>

          <v-col
            cols="12"
            md="6"
            lg="5"
            class="right-column d-flex flex-column justify-center align-center position-relative pr-md-16 pr-lg-16"
          >
            <div class="right-backdrop" :class="{ 'light-backdrop': isLightMode }"></div>

            <div class="d-flex flex-column align-center mb-6 fade-in-down" style="z-index: 10;">
              <v-img
                :src="logoSrc"
                width="180"
                height="100"
                contain
                class="mb-2 drop-shadow-logo"
              ></v-img>
            </div>

            <v-card
              class="login-card pa-10 rounded-xl elevation-24"
              :class="cardClasses"
              width="100%"
              max-width="440"
            >
              <div class="text-center mb-8">
                <h2 class="text-h5 font-weight-bold mb-2" :class="textPrimaryClass">Bem-vindo</h2>
                <p class="text-body-2" :class="textSecondaryClass">Faça login para acessar sua conta</p>
              </div>

              <v-form @submit.prevent="handleLogin" ref="formRef">

                <div class="mb-5">
                  <v-text-field
                    v-model="email"
                    label="E-mail Corporativo"
                    variant="outlined"
                    :bg-color="inputBgColor"
                    :color="primaryColor"
                    class="premium-input"
                    hide-details="auto"
                    rounded="lg"
                    prepend-inner-icon="mdi-email-outline"
                    :rules="[rules.required]"
                    :theme="currentThemeName"
                  ></v-text-field>
                </div>

                <div class="mb-2">
                  <v-text-field
                    v-model="password"
                    :type="showPassword ? 'text' : 'password'"
                    label="Senha"
                    variant="outlined"
                    :bg-color="inputBgColor"
                    :color="primaryColor"
                    class="premium-input"
                    hide-details="auto"
                    rounded="lg"
                    prepend-inner-icon="mdi-lock-outline"
                    :append-inner-icon="showPassword ? 'mdi-eye-off' : 'mdi-eye'"
                    @click:append-inner="showPassword = !showPassword"
                    :rules="[rules.required]"
                    :theme="currentThemeName"
                  ></v-text-field>
                </div>

                <div class="d-flex justify-space-between align-center mb-8">
                  <v-checkbox
                    v-model="rememberMe"
                    label="Lembrar de mim"
                    :color="primaryColor"
                    density="compact"
                    hide-details
                    class="remember-checkbox ml-n2"
                    :class="textSecondaryClass"
                  ></v-checkbox>

                  <a
                    href="#"
                    class="text-caption text-decoration-none font-weight-bold hover-link"
                    :class="linkClass"
                    @click.prevent="forgotPasswordWhatsappRef?.open(email)"
                  >
                    Esqueceu a senha?
                  </a>
                </div>

                <v-btn
                  block
                  height="56"
                  :color="btnColor"
                  class="login-btn text-body-1 font-weight-bold mb-6 text-white"
                  rounded="lg"
                  type="submit"
                  :loading="loading"
                  elevation="10"
                >
                  ACESSAR SISTEMA
                </v-btn>

                <div class="landing-hook text-center mt-2 pt-5">
                  <span class="text-body-2" :class="textSecondaryClass">Não é cliente ainda?</span>
                  <router-link
                    :to="{ name: 'Landing' }"
                    class="landing-link text-decoration-none font-weight-bold ml-1 d-inline-flex align-center"
                    :class="linkClass"
                  >
                    Veja nosso sistema
                    <v-icon size="small" class="ml-1 arrow-icon">mdi-arrow-right</v-icon>
                  </router-link>
                </div>

              </v-form>

            </v-card>

            <div class="d-md-none mt-8 text-center text-caption" :class="isLightMode ? 'text-grey-darken-1' : 'text-grey'">
              &copy; 2025 MJSystem Enterprise
            </div>

          </v-col>
        </v-row>
      </v-container>

      <v-snackbar
        v-model="showError"
        color="red-darken-4"
        location="top right"
        elevation="10"
        rounded="lg"
        timeout="4000"
        transition="slide-x-reverse-transition"
      >
        <div class="d-flex align-center">
          <v-icon class="mr-3">mdi-alert-circle</v-icon>
          <div>
            <div class="font-weight-bold">Falha no Acesso</div>
            <div class="text-caption">{{ errorMessage }}</div>
          </div>
        </div>
      </v-snackbar>

      <ForgotPasswordWhatsappModal ref="forgotPasswordWhatsappRef" />

    </div>
  </v-theme-provider>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted, computed } from 'vue';
import { useRouter } from 'vue-router';
import { useUserStore } from '@/stores/user';
import { useThemeStore } from '@/stores/themeStore';
import { supabase } from '@/api/supabase';

import logoDark from '@/assets/logo.png';
import logoLight from '@/assets/logo.png';

import ForgotPasswordWhatsappModal from '@/components/ForgotPasswordWhatsappModal.vue';

import bg1 from '@/assets/1.jpg';
import bg2 from '@/assets/2.jpg';
import bg3 from '@/assets/3.jpg';
import bg4 from '@/assets/4.jpg';
import bg5 from '@/assets/5.jpg';

const router = useRouter();
const userStore = useUserStore();
const themeStore = useThemeStore();

const forgotPasswordWhatsappRef = ref<InstanceType<typeof ForgotPasswordWhatsappModal> | null>(null);

const email = ref('');
const password = ref('');
const rememberMe = ref(true);
const showPassword = ref(false);
const loading = ref(false);
const showError = ref(false);
const errorMessage = ref('');

const currentTime = ref('');
const currentDate = ref('');

const backgrounds = ref([ bg1, bg2, bg3, bg4, bg5 ]);
const currentBgIndex = ref(0);
const currentMessageIndex = ref(0);

const marketingMessages = [
  { text: 'Plataforma unificada para gestão industrial e comercial em tempo real.' },
  { text: 'Controle total da produção, do corte à entrega final.' },
  { text: 'Inteligência de dados integrada para impulsionar suas vendas no varejo.' },
  { text: 'Segurança corporativa avançada e auditoria completa de ações.' }
];

let bgInterval: any;
let msgInterval: any;
let clockInterval: any;

const rules = {
  required: (v: string) => !!v || 'Campo obrigatório',
};

const isLightMode = computed(() => themeStore.currentMode === 'light');
const isGlassMode = computed(() => themeStore.currentMode === 'glass');
const isDarkMode = computed(() => themeStore.currentMode === 'dark');

const currentThemeName = computed(() => isLightMode.value ? 'light' : 'dark');
const logoSrc = computed(() => isLightMode.value ? logoLight : logoDark);

const cardClasses = computed(() => {
  if (isGlassMode.value) return 'glass-card';
  if (isLightMode.value) return 'light-card border';
  return 'dark-card border-dark';
});

const textPrimaryClass = computed(() => isLightMode.value ? 'text-grey-darken-3' : 'text-white');
const textSecondaryClass = computed(() => isLightMode.value ? 'text-grey-darken-1' : 'text-grey-lighten-1');
const linkClass = computed(() => isLightMode.value ? 'text-blue-darken-2' : 'text-blue-accent-1');

const inputBgColor = computed(() => {
  if (isGlassMode.value) return 'rgba(40,40,45,0.6)';
  if (isLightMode.value) return 'rgba(0,0,0,0.04)';
  return 'rgba(255,255,255,0.05)';
});

const primaryColor = computed(() => isLightMode.value ? 'blue-darken-2' : 'blue-accent-2');
const btnColor = computed(() => isLightMode.value ? 'blue-darken-3' : 'blue-accent-3');
const overlayClass = computed(() => isLightMode.value ? 'overlay-strong' : 'overlay-normal');

const updateClock = () => {
  const now = new Date();
  currentTime.value = now.toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' });
  currentDate.value = now.toLocaleDateString('pt-BR', { weekday: 'long', day: 'numeric', month: 'long' });
};

const handleLogin = async () => {
  if (!email.value || !password.value) {
    errorMessage.value = 'Informe suas credenciais.';
    showError.value = true;
    return;
  }

  loading.value = true;
  try {
    const { error } = await supabase.auth.signInWithPassword({
      email: email.value,
      password: password.value,
    });

    if (error) throw error;

    await userStore.fetchSession();
    router.push({ name: 'Hub' });

  } catch (err: any) {
    console.error('Login Error:', err);
    errorMessage.value = err.message === 'Invalid login credentials'
      ? 'E-mail ou senha incorretos.'
      : 'Erro de conexão com o servidor.';
    showError.value = true;
  } finally {
    loading.value = false;
  }
};

onMounted(() => {
  themeStore.initTheme();
  updateClock();
  clockInterval = setInterval(updateClock, 1000);

  bgInterval = setInterval(() => {
    currentBgIndex.value = (currentBgIndex.value + 1) % backgrounds.value.length;
  }, 10000);

  msgInterval = setInterval(() => {
    currentMessageIndex.value = (currentMessageIndex.value + 1) % marketingMessages.length;
  }, 6000);
});

onUnmounted(() => {
  clearInterval(bgInterval);
  clearInterval(msgInterval);
  clearInterval(clockInterval);
});
</script>

<style scoped lang="scss">
.login-wrapper {
  position: relative;
  width: 100vw;
  height: 100vh;
  overflow: hidden;
  background-color: #050505;
  font-family: 'Roboto', sans-serif;
}

/* BACKGROUND */
.background-carousel, .bg-slide, .bg-overlay-gradient {
  position: absolute; top: 0; left: 0; width: 100%; height: 100%; pointer-events: none;
}
.bg-slide {
  background-size: cover; background-position: center; opacity: 0;
  transition: opacity 1.5s ease-in-out, transform 20s linear; transform: scale(1);
}
.bg-slide.active { opacity: 1; transform: scale(1.05); }

/* Gradiente Suave */
.bg-overlay-gradient {
  transition: background 0.5s ease;
  z-index: 0;
}
.overlay-normal {
  background: linear-gradient(to right, rgba(0,0,0,0.1) 0%, rgba(0,0,0,0.3) 40%, rgba(0, 0, 0, 0.781) 100%);
}
.overlay-strong {
  background: linear-gradient(to right, rgba(0,0,0,0.4) 0%, rgba(0,0,0,0.5) 40%, rgba(20, 20, 20, 0.4) 100%);
}

.particles-container {
  position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 1;
  background-image: radial-gradient(rgba(255,255,255,0.1) 1px, transparent 1px);
  background-size: 60px 60px; opacity: 0.2; pointer-events: none;
}

/* LEFT COLUMN (Branding) */
.display-title {
  font-size: 3.5rem; line-height: 1.1; letter-spacing: -1px;
}
.digital-clock .time {
  font-size: 4rem; line-height: 1; letter-spacing: -2px;
}
.max-width-650 { max-width: 650px; }
.drop-shadow-logo { filter: drop-shadow(0 4px 10px rgba(0,0,0,0.5)); }
.text-shadow-lg { text-shadow: 0 4px 20px rgba(0,0,0,0.9); }
.text-shadow-md { text-shadow: 0 2px 10px rgba(0,0,0,0.8); }
.text-shadow-sm { text-shadow: 0 1px 4px rgba(0,0,0,0.8); }
.lh-1 { line-height: 1; }

.slider-dot {
  width: 10px; height: 10px; border-radius: 50%; background: rgba(255,255,255,0.2);
  cursor: pointer; transition: all 0.3s;
  &.active { width: 30px; border-radius: 5px; background: #448AFF; }
}

.footer-link {
  color: rgba(255,255,255,0.7); text-decoration: none; transition: 0.2s;
  display: flex; align-items: center;
  &:hover { color: white; }
}

/* RIGHT COLUMN (Login Form) */
.right-backdrop {
  position: absolute; top: 0; right: 0; width: 100%; height: 100%;
  z-index: -1;
  transition: background 0.3s;
}
.light-backdrop {
  background: rgba(255,255,255,0.2);
  backdrop-filter: blur(10px);
}

/* --- CARD VARIATIONS --- */
.login-card {
  transition: all 0.3s ease;
}

/* Glass Mode */
.glass-card {
  background: rgba(30, 30, 35, 0.397) !important;
  backdrop-filter: blur(40px);
  -webkit-backdrop-filter: blur(40px);
  border: 1px solid rgba(255, 255, 255, 0.08);
  box-shadow: 0 30px 60px -12px rgba(0, 0, 0, 0.8) !important;
}

/* Light Mode (Sólido) */
.light-card {
  background: rgba(255, 255, 255, 0.96) !important;
  backdrop-filter: blur(10px);
  border: 1px solid rgba(0,0,0,0.05) !important;
  box-shadow: 0 20px 40px -10px rgba(0, 0, 0, 0.2) !important;
}

/* Dark Mode (Sólido) */
.dark-card {
  background: #1E1E1E !important;
  border: 1px solid rgba(255, 255, 255, 0.05) !important;
  box-shadow: 0 20px 40px -10px rgba(0, 0, 0, 0.6) !important;
}

/* Inputs Premium */
.premium-input :deep(.v-field) {
  border-radius: 8px !important;
  border: 1px solid rgba(128, 128, 128, 0.2);
  transition: all 0.3s ease;
}
.premium-input :deep(.v-field--focused) {
  border-color: #448AFF !important;
  box-shadow: 0 0 0 3px rgba(68, 138, 255, 0.2);
}
.v-theme--light .premium-input :deep(.v-field--focused) {
    background: #ffffff !important;
}
.v-theme--dark .premium-input :deep(.v-field--focused) {
    background: rgba(0,0,0,0.8) !important;
}

.login-btn {
  letter-spacing: 1px;
  transition: 0.2s;
  &:hover { filter: brightness(1.1); transform: translateY(-1px); }
}

/* --- GANCHO DA LANDING PAGE --- */
.landing-hook {
  border-top: 1px solid rgba(128, 128, 128, 0.2);
}
.landing-link {
  transition: all 0.3s ease;
}
.landing-link:hover {
  text-decoration: none !important;
  filter: brightness(1.2);
}
.landing-link:hover .arrow-icon {
  transform: translateX(4px);
}
.arrow-icon {
  transition: transform 0.3s ease;
}

.gap-6 { gap: 24px; }
.hover-link:hover { text-decoration: underline; }
.hover-bright:hover { color: white !important; }

/* Animations */
.fade-in-down { animation: fadeInDown 0.8s ease-out forwards; opacity: 0; }
.fade-in-left { animation: fadeInLeft 0.8s ease-out forwards; opacity: 0; }
.fade-in-up { animation: fadeInUp 0.8s ease-out forwards; opacity: 0; }

@keyframes fadeInDown { from { opacity: 0; transform: translateY(-20px); } to { opacity: 1; transform: translateY(0); } }
@keyframes fadeInLeft { from { opacity: 0; transform: translateX(-20px); } to { opacity: 1; transform: translateX(0); } }
@keyframes fadeInUp { from { opacity: 0; transform: translateY(20px); } to { opacity: 1; transform: translateY(0); } }

.delay-1 { animation-delay: 0.2s; }
.delay-2 { animation-delay: 0.4s; }

/* Responsividade */
@media (max-width: 960px) {
  .bg-overlay-gradient {
    background: linear-gradient(to bottom, rgba(0,0,0,0.4) 0%, rgba(0,0,0,0.8) 100%);
  }
  .display-title { font-size: 2.5rem; }
  .digital-clock .time { font-size: 3rem; }
  .left-column { display: none !important; }
}
</style>
