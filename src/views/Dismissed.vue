<template>
  <div class="auth-wrapper font-sans">

    <transition name="fade-bg" mode="in-out">
      <div
        :key="currentImageIndex"
        class="bg-image"
        :style="{ backgroundImage: `url(${images[currentImageIndex]})` }"
      ></div>
    </transition>

    <div class="bg-overlay"></div>

    <v-container fluid class="fill-height pa-0 ma-0 position-relative z-10">
      <v-row class="fill-height ma-0" align="center">

        <v-col cols="12" md="7" lg="8" class="d-none d-md-flex flex-column justify-end pa-12 pb-16 fill-height">
          <div class="mb-4">
            <h1 class="text-h2 font-weight-black text-white mb-2 leading-tight tracking-tighter">
              MJProcess<span class="text-red-lighten-1">.</span>
            </h1>
            <p class="text-h6 text-grey-lighten-2 font-weight-regular" style="max-width: 480px;">
              Plataforma Integrada de Gestão, Manufatura e Recursos Humanos.
            </p>
            <div class="d-flex align-center gap-4 mt-6 text-caption text-white opacity-60 font-mono">
              <span class="d-flex align-center gap-1"><v-icon size="14">mdi-shield-check</v-icon> IAM Security</span>
              <span>|</span>
              <span class="d-flex align-center gap-1"><v-icon size="14">mdi-server-network</v-icon> Cloud Sync Active</span>
            </div>
          </div>
        </v-col>

        <v-col cols="12" md="5" lg="4" class="d-flex align-center justify-center pa-6">

          <v-card class="white-glass-card rounded-xl pa-9 text-center d-flex flex-column align-center w-100" max-width="460" elevation="24">

            <img :src="logoDark" alt="Logo MJProcess" class="logo-img mb-7" />

            <v-avatar color="red-lighten-5" size="80" class="mb-5 border-light">
              <v-icon size="40" color="red-darken-3">mdi-account-cancel-outline</v-icon>
            </v-avatar>

            <div class="text-overline text-red-darken-3 font-weight-black mb-1 tracking-widest">Segurança Corporativa</div>
            <h2 class="text-h5 font-weight-black text-grey-darken-4 mb-5 tracking-tight">Acesso Suspenso</h2>

            <v-divider class="w-100 mb-5 border-opacity-25"></v-divider>

            <p class="text-body-2 text-grey-darken-2 mb-7 px-2" style="line-height: 1.6;">
              Prezado(a) colaborador(a), sua credencial de acesso foi temporariamente revogada pelo <strong>Departamento de Recursos Humanos</strong>. Seu dossiê consta como inativo na base central.
            </p>

            <div class="info-box pa-4 mb-7 text-left d-flex gap-3 align-start w-100 rounded-lg border-thin">
              <v-icon color="grey-darken-2" size="20" class="mt-1 flex-shrink-0">mdi-information-outline</v-icon>
              <span class="text-[11px] text-grey-darken-3 font-weight-medium" style="line-height: 1.4;">
                Se você acredita que isto é um erro do sistema ou seu afastamento já terminou, por favor, entre em contato imediatamente com seu gestor ou o RH da Unidade.
              </span>
            </div>

            <v-btn
              color="grey-darken-4"
              variant="flat"
              size="large"
              block
              class="font-weight-black tracking-widest text-caption rounded-lg"
              height="54"
              :loading="loading"
              @click="handleLogout"
            >
              <v-icon start size="18">mdi-logout-variant</v-icon>
              SAIR E RETORNAR AO LOGIN
            </v-btn>

            <div class="mt-7 text-[10px] text-grey-darken-1 font-mono d-flex flex-column align-center gap-1 opacity-80">
               <span>Sessão Auditada via IAM</span>
               <span>{{ currentIp }}</span>
            </div>

          </v-card>

        </v-col>

      </v-row>
    </v-container>

  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue';
import { supabase } from '@/api/supabase';
import { useRouter } from 'vue-router';
import { useUserStore } from '@/stores/user';

// Importando a logo localmente para evitar imagem quebrada
import logoDark from '@/assets/logo.png';

const router = useRouter();
const userStore = useUserStore();
const loading = ref(false);
const currentIp = ref('Carregando IP...');

// Imagens do Carrossel (Placeholder robustos para garantir funcionamento)
const images = [
  'https://images.unsplash.com/photo-1472214103451-9374bd1c798e?q=80&w=2070', // Montanha e Névoa
  'https://images.unsplash.com/photo-1448375240586-882707db8855?q=80&w=2070', // Floresta Verdejante
  'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?q=80&w=2073', // Praia Tropical
  'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?q=80&w=2070', // Cordilheira ao Pôr do Sol
  'https://images.unsplash.com/photo-1433086966358-54859d0ed716?q=80&w=2070', // Cascata e Natureza
  'https://images.unsplash.com/photo-1519681393784-d120267933ba?q=80&w=2070', // Picos Nevados e Estrelas
  'https://images.unsplash.com/photo-1476514525535-07fb3b4ae5f1?q=80&w=2070', // Lago Reflexivo
  'https://images.unsplash.com/photo-1505820013142-f86a3439c5b2?q=80&w=2071', // Floresta de Outono
  'https://images.unsplash.com/photo-1473580044384-7ba9967e16a0?q=80&w=2070', // Dunas e Deserto
  'https://images.unsplash.com/photo-1531366936337-77cf5e615ed9?q=80&w=2070'  // Aurora Boreal
];
const currentImageIndex = ref(0);
let carouselInterval: any;

const fetchIp = async () => {
  try {
    const res = await fetch('https://api.ipify.org?format=json');
    const data = await res.json();
    currentIp.value = `IP Registrado: ${data.ip}`;
  } catch (e) {
    currentIp.value = 'IP: Indisponível';
  }
};

const handleLogout = async () => {
  loading.value = true;
  try {
    // Tenta deslogar do Supabase Auth
    await supabase.auth.signOut();
  } catch (error) {
    console.error('Erro Auth signOut:', error);
  } finally {
    // Garante que o store local seja limpo e redireciona
    userStore.signOut();
    router.push('/login');
    loading.value = false;
  }
};

onMounted(() => {
  fetchIp();
  // Inicia o carrossel
  if (images.length > 1) {
    carouselInterval = setInterval(() => {
      currentImageIndex.value = (currentImageIndex.value + 1) % images.length;
    }, 8000); // 8 segundos por imagem
  }
});

onUnmounted(() => {
  // Limpa o intervalo para evitar vazamento de memória
  if (carouselInterval) clearInterval(carouselInterval);
});
</script>

<style scoped>
/* Layout Principal - Garante que o fundo ocupe a tela toda */
.auth-wrapper {
  position: relative;
  min-height: 100vh;
  width: 100vw;
  overflow: hidden;
  background-color: #0a0a0c; /* Fundo escuro de fallback corporativo */
}

/* =======================================
   BACKGROUND CARROSSEL
   ======================================= */
.bg-image {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background-size: cover;
  background-position: center;
  z-index: 0;
  will-change: opacity, transform;
  /* Aplica a animação de zoom de 15 segundos */
  animation: slowZoom 15s linear forwards;
}

/* Keyframes do efeito Ken Burns (Zoom in suave) */
@keyframes slowZoom {
  0% {
    transform: scale(1);
  }
  100% {
    transform: scale(1.15); /* Aumenta 15% gradativamente */
  }
}

/* Transição suave Cross-Fade */
.fade-bg-enter-active,
.fade-bg-leave-active {
  transition: opacity 2s ease-in-out;
}
.fade-bg-enter-from,
.fade-bg-leave-to {
  opacity: 0;
}

/* Overlay Gradiente (Escuro -> Transparente) */
.bg-overlay {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: linear-gradient(90deg, rgba(10,10,12,0.9) 0%, rgba(10,10,12,0.6) 50%, rgba(10,10,12,0.3) 100%);
  z-index: 1;
}

/* =======================================
   UTILITÁRIOS E TIPOGRAFIA
   ======================================= */
.z-10 { z-index: 10; }
.position-relative { position: relative; }
.leading-tight { line-height: 1.1; }
.tracking-widest { letter-spacing: 0.15em; }
.tracking-tight { letter-spacing: -0.02em; }
.tracking-tighter { letter-spacing: -0.05em; }
.border-thin { border: 1px solid rgba(0,0,0,0.06); }
.border-light { border: 1px solid rgba(0,0,0,0.03) !important; }

/* =======================================
   O CARD BRANCO GLASSMORPHISM (CLEAN)
   ======================================= */
.white-glass-card {
  background: rgba(255, 255, 255, 0.96) !important;
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  border: 1px solid rgba(255, 255, 255, 1);
  box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25) !important;
}

.logo-img {
  width: auto;
  height: 38px;
  object-fit: contain;
}

.info-box {
  background-color: rgba(0, 0, 0, 0.02);
}

.v-btn {
  text-transform: none !important;
  font-size: 11px !important;
}
</style>
