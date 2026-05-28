<template>
  <v-dialog
    v-model="isExpired"
    max-width="420"
    persistent
    transition="dialog-bottom-transition"
    class="blurred-backdrop-dialog"
  >
    <v-card
      class="premium-glass-card text-center overflow-visible"
      :class="isDark ? 'dark-glass' : 'light-glass'"
      elevation="0"
    >
      <div class="ambient-glow" :class="isDark ? 'glow-red-dark' : 'glow-red-light'"></div>

      <div class="pa-8 position-relative z-10">

        <div class="icon-3d-wrapper mx-auto mb-8">
          <div class="icon-3d-inner d-flex align-center justify-center">
            <v-icon size="42" color="white">mdi-lock-alert</v-icon>
          </div>
          <div class="icon-shadow"></div>
        </div>

        <h2
          class="text-h5 font-weight-black mb-3 letter-spacing-tight"
          :class="isDark ? 'text-white' : 'text-grey-darken-4'"
        >
          Sessão Encerrada
        </h2>

        <p
          class="text-body-2 mb-8 font-weight-medium"
          :class="isDark ? 'text-white-70' : 'text-grey-darken-1'"
          style="line-height: 1.6;"
        >
          Para proteger seus dados, desconectamos você por inatividade. Acesse novamente para continuar trabalhando com segurança.
        </p>

        <button class="btn-3d-auth w-100 font-weight-black text-uppercase tracking-widest d-flex align-center justify-center gap-3" @click="reloadAndLogin">
          <v-icon size="22">mdi-fingerprint</v-icon>
          Autenticar Novamente
        </button>

      </div>
    </v-card>
  </v-dialog>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted, computed } from 'vue';
import { supabase } from '@/api/supabase';
import { useRouter, useRoute } from 'vue-router';
import { useThemeStore } from '@/stores/theme';

const isExpired = ref(false);
const router = useRouter();
const route = useRoute();
const themeStore = useThemeStore();

let authSubscription: any;
let heartbeatTimer: any;

const isDark = computed(() => themeStore.currentMode !== 'light');

// Lógica blindada para detectar se o usuário está fora do ERP
const isPublicRoute = computed(() => {
  const path = route.path?.toLowerCase() || '';

  // Lista de caminhos exatos que são públicos
  const publicPaths = ['/', '/landing', '/marketplace-login', '/terms', '/privacy', '/login'];

  // Se for uma das rotas acima ou se estiver em qualquer tela do marketplace
  if (publicPaths.includes(path) || path.startsWith('/marketplace')) {
    return true;
  }

  // Regra extra via meta tags do vue-router (caso você use)
  if (route.meta && (route.meta.public === true || route.meta.requiresAuth === false)) {
    return true;
  }

  // Regra baseada no nome da rota
  if (route.name === 'Login') {
    return true;
  }

  return false;
});

const triggerExpiration = () => {
  // Se o usuário clicou em "Sair" de propósito, ignora!
  if (localStorage.getItem('explicit_logout') === 'true') return;

  // A MÁGICA AQUI: Bloqueia a abertura do modal se for rota pública/marketplace
  if (isPublicRoute.value) return;

  if (!isExpired.value) {
    isExpired.value = true;
  }
};

const verifySessionWithServer = async () => {
  // Aborta a verificação se já estivermos no meio de um logout manual ou se já expirou
  if (isExpired.value || localStorage.getItem('explicit_logout') === 'true') return;

  // Não perde tempo pingando o servidor se estiver em rota pública
  if (isPublicRoute.value) return;

  const { data, error } = await supabase.auth.getUser();
  if (error || !data.user) {
    triggerExpiration();
  }
};

const handleStorageChange = (e: StorageEvent) => {
  if (e.key && e.key.includes('-auth-token') && !e.newValue) {
    triggerExpiration();
  }
};

onMounted(() => {
  const { data } = supabase.auth.onAuthStateChange((event) => {
    if (event === 'SIGNED_OUT' || event === 'USER_DELETED') {
      triggerExpiration();
    }
  });
  authSubscription = data.subscription;

  window.addEventListener('storage', handleStorageChange);
  window.addEventListener('focus', verifySessionWithServer);
  heartbeatTimer = setInterval(verifySessionWithServer, 3 * 60 * 1000);
});

onUnmounted(() => {
  if (authSubscription) authSubscription.unsubscribe();
  window.removeEventListener('storage', handleStorageChange);
  window.removeEventListener('focus', verifySessionWithServer);
  clearInterval(heartbeatTimer);
});

const reloadAndLogin = () => {
  const keysToRemove = Object.keys(localStorage).filter(k => k.includes('auth-token') || k.includes('supabase'));
  keysToRemove.forEach(k => localStorage.removeItem(k));
  window.location.reload();
};
</script>

<style scoped>
.gap-3 { gap: 12px; }
.tracking-widest { letter-spacing: 1.5px; }
.letter-spacing-tight { letter-spacing: -0.5px; }
.z-10 { position: relative; z-index: 10; }
.text-white-70 { color: rgba(255, 255, 255, 0.7) !important; }

/* -------------------------------------
   Cartão de Vidro (Glassmorphism)
-------------------------------------- */
.premium-glass-card {
  border-radius: 28px !important;
  backdrop-filter: blur(40px);
  -webkit-backdrop-filter: blur(40px);
  box-shadow: 0 24px 60px rgba(0, 0, 0, 0.4), inset 0 1px 0 rgba(255, 255, 255, 0.2) !important;
}

.dark-glass {
  background: rgba(25, 25, 30, 0.65) !important;
  border: 1px solid rgba(255, 255, 255, 0.08);
}

.light-glass {
  background: rgba(255, 255, 255, 0.75) !important;
  border: 1px solid rgba(255, 255, 255, 0.6);
  box-shadow: 0 24px 60px rgba(0, 0, 0, 0.15), inset 0 1px 0 rgba(255, 255, 255, 0.8) !important;
}

/* -------------------------------------
   Brilho Ambiente Fundo do Cartão
-------------------------------------- */
.ambient-glow {
  position: absolute;
  top: -20%;
  left: 50%;
  transform: translateX(-50%);
  width: 250px;
  height: 250px;
  border-radius: 50%;
  filter: blur(60px);
  z-index: 0;
  pointer-events: none;
}
.glow-red-dark { background: rgba(239, 68, 68, 0.25); }
.glow-red-light { background: rgba(239, 68, 68, 0.15); }

/* -------------------------------------
   Ícone 3D Magnético Flutuante
-------------------------------------- */
.icon-3d-wrapper {
  position: relative;
  width: 80px;
  height: 80px;
}
.icon-3d-inner {
  width: 100%;
  height: 100%;
  border-radius: 24px;
  background: linear-gradient(135deg, #EF4444, #B91C1C);
  box-shadow:
    inset 0 2px 4px rgba(255, 255, 255, 0.4),
    inset 0 -4px 8px rgba(0, 0, 0, 0.2),
    0 10px 20px rgba(239, 68, 68, 0.4);
  animation: float-icon 4s ease-in-out infinite;
  position: relative;
  z-index: 2;
}
.icon-shadow {
  position: absolute;
  bottom: -15px;
  left: 50%;
  transform: translateX(-50%);
  width: 50px;
  height: 10px;
  background: rgba(0, 0, 0, 0.2);
  border-radius: 50%;
  filter: blur(4px);
  animation: shadow-pulse 4s ease-in-out infinite;
  z-index: 1;
}

@keyframes float-icon {
  0%, 100% { transform: translateY(0); }
  50% { transform: translateY(-10px); }
}
@keyframes shadow-pulse {
  0%, 100% { transform: translateX(-50%) scale(1); opacity: 0.6; }
  50% { transform: translateX(-50%) scale(0.8); opacity: 0.3; }
}

/* -------------------------------------
   Botão 3D Autenticação
-------------------------------------- */
.btn-3d-auth {
  height: 60px;
  border-radius: 16px;
  background: linear-gradient(145deg, #2563EB, #1D4ED8);
  color: #ffffff;
  border: none;
  outline: none;
  cursor: pointer;
  position: relative;
  box-shadow:
    0 6px 0 #1E3A8A,
    0 16px 24px rgba(37, 99, 235, 0.4),
    inset 0 2px 0 rgba(255, 255, 255, 0.25);
  transition: all 0.15s cubic-bezier(0.34, 1.56, 0.64, 1);
}

.btn-3d-auth:hover {
  filter: brightness(1.1);
  transform: translateY(-2px);
  box-shadow:
    0 8px 0 #1E3A8A,
    0 20px 30px rgba(37, 99, 235, 0.5),
    inset 0 2px 0 rgba(255, 255, 255, 0.3);
}

.btn-3d-auth:active {
  transform: translateY(6px);
  box-shadow:
    0 0 0 #1E3A8A,
    0 4px 10px rgba(37, 99, 235, 0.3),
    inset 0 2px 4px rgba(0, 0, 0, 0.2);
}
</style>

<style>
/* =========================================================
   ESTILO GLOBAL: O FAMOSO "BLUR DE FUNDO" DO SISTEMA
   Isso desfoca o site inteiro atrás do modal quando ele abre
========================================================= */
.blurred-backdrop-dialog ~ .v-overlay__scrim {
  background: rgba(0, 0, 0, 0.45) !important;
  backdrop-filter: blur(16px) saturate(120%) !important;
  -webkit-backdrop-filter: blur(16px) saturate(120%) !important;
}
</style>
