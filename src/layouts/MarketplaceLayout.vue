<template>
  <v-app :theme="themeStore.currentTheme" class="marketplace-app">

    <DynamicWatermark />

    <transition name="fade-overlay">
      <div v-if="protectionStore.isBlocked" class="security-blocking-overlay">
        <div class="blocking-content">
          <v-icon size="64" color="error" class="mb-4">mdi-shield-lock</v-icon>
          <h1>Acesso Temporariamente Restrito</h1>
          <p>
            Detectamos um padrão de navegação incomum. Para garantir a segurança do nosso acervo,
            seu acesso foi pausado por medida preventiva.
          </p>
          <div class="timer-box">
            <span>Seu acesso será restaurado automaticamente em:</span>
            <div class="countdown-timer">{{ formattedBlockTime }}</div>
          </div>
          <v-btn
            variant="tonal"
            color="primary"
            class="mt-6 text-none font-weight-bold"
            @click="checkStatusManual"
          >
            Verificar Status Agora
          </v-btn>
        </div>
      </div>
    </transition>

    <transition name="fade-overlay">
      <div v-if="protectionStore.requiresRevalidation" class="security-revalidation-overlay">
        <div class="revalidation-card mj-surface mj-border">
          <v-icon size="48" color="primary" class="mb-2">mdi-human-greeting-variant</v-icon>
          <h2>Você ainda está aí?</h2>
          <p>Sua navegação está muito rápida. Por favor, confirme que você é humano para continuar explorando o acervo.</p>
          <v-btn
            block
            color="primary"
            height="54"
            class="mt-4 rounded-lg font-weight-bold text-none"
            elevation="0"
            :loading="isValidating"
            @click="handleRevalidation"
          >
            Sou humano, quero continuar
          </v-btn>
        </div>
      </div>
    </transition>

    <v-app-bar flat height="82" border="b" class="navbar-blur">
      <div class="fluid-container d-flex align-center w-100 px-6">
        <div class="logo-area" @click="router.push('/marketplace/home')">
          <v-img src="@/assets/logo.png" width="120" contain />
        </div>

        <v-spacer />

        <div class="nav-actions d-flex align-center gap-2">
          <v-btn icon variant="text" @click="isMoodboardOpen = true">
            <v-icon>mdi-view-quilt-outline</v-icon>
          </v-btn>
          <v-btn icon variant="text" @click="isCartOpen = true">
            <v-badge :content="cartStore.itemCount" color="primary" overlap v-if="cartStore.itemCount > 0">
              <v-icon>mdi-shopping-outline</v-icon>
            </v-badge>
            <v-icon v-else>mdi-shopping-outline</v-icon>
          </v-btn>
          <v-avatar size="38" class="cursor-pointer ml-2" color="surface-variant" @click="router.push('/marketplace/perfil')">
            <v-img :src="userStore.user?.avatarUrl || ''" v-if="userStore.user?.avatarUrl" />
            <v-icon v-else>mdi-account-circle</v-icon>
          </v-avatar>
        </div>
      </div>
    </v-app-bar>

    <CartDrawer v-model="isCartOpen" />
    <MoodboardDrawer v-model="isMoodboardOpen" />

    <v-main>
      <router-view v-slot="{ Component }">
        <transition name="fade-page" mode="out-in">
          <div :class="{'degraded-ux': protectionStore.riskFlag === 'high'}">
            <component :is="Component" />
          </div>
        </transition>
      </router-view>
    </v-main>

    <AppFooter />
  </v-app>
</template>

<script setup lang="ts">
import { ref, onMounted, computed, watch } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useThemeStore } from '@/stores/themeStore'
import { useMarketplaceUserStore } from '@/stores/marketplaceUser'
import { useMarketplaceCartStore } from '@/stores/marketplaceCart'
import { useProtectionStore, type ProtectionContext } from '@/stores/protectionStore'
import DynamicWatermark from '@/components/DynamicWatermark.vue'

const router = useRouter()
const route = useRoute()
const themeStore = useThemeStore()
const userStore = useMarketplaceUserStore()
const cartStore = useMarketplaceCartStore()
const protectionStore = useProtectionStore()

const isCartOpen = ref(false)
const isMoodboardOpen = ref(false)
const isValidating = ref(false)

// Inicialização do Guardião Global
onMounted(async () => {
  await protectionStore.initializeGuard()
  updateContext(route.path)
})

// Monitora a mudança de rota para atualizar o contexto de risco
watch(() => route.path, (newPath) => {
  updateContext(newPath)
})

function updateContext(path: string) {
  let context: ProtectionContext = 'unknown'

  if (path.includes('/home')) context = 'unknown'
  else if (path.includes('/descobrir')) context = 'discover'
  else if (path.includes('/catalogo')) context = 'catalog'
  else if (path.includes('/produto')) context = 'art_detail'
  else if (path.includes('/checkout')) context = 'checkout'

  protectionStore.setContext(context)
}

// Lógica de Revalidação Manual (Nível 2)
async function handleRevalidation() {
  isValidating.value = true
  // Simula um pequeno delay para processamento humano
  await new Promise(resolve => setTimeout(resolve, 800))
  await protectionStore.clearRevalidation()
  isValidating.value = false
}

async function checkStatusManual() {
  await protectionStore.fetchStatusFromBackend()
}

// Formata o tempo restante de bloqueio
const formattedBlockTime = computed(() => {
  if (!protectionStore.blockedUntil) return 'Aguarde...'
  const target = new Date(protectionStore.blockedUntil).getTime()
  const now = new Date().getTime()
  const diff = target - now

  if (diff <= 0) return '00:00'

  const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60))
  const seconds = Math.floor((diff % (1000 * 60)) / 1000)
  return `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`
})
</script>

<style scoped lang="scss">
.navbar-blur {
  background: rgba(var(--v-theme-surface), 0.75) !important;
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
}

/* ESTILO APPLE-LEVEL PARA O BLOQUEIO */
.security-blocking-overlay {
  position: fixed;
  inset: 0;
  z-index: 9999999;
  background: rgba(0, 0, 0, 0.9);
  backdrop-filter: blur(20px);
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
  text-align: center;
  padding: 40px;

  .blocking-content {
    max-width: 500px;
    h1 { font-size: 2.2rem; font-weight: 900; letter-spacing: -0.04em; margin-bottom: 16px; }
    p { font-size: 1.1rem; opacity: 0.7; line-height: 1.5; }

    .timer-box {
      margin-top: 32px;
      padding: 24px;
      background: rgba(255, 255, 255, 0.05);
      border-radius: 20px;
      border: 1px solid rgba(255, 255, 255, 0.1);

      .countdown-timer {
        font-size: 3.5rem;
        font-family: 'JetBrains Mono', monospace;
        font-weight: 800;
        color: var(--v-theme-primary);
        margin-top: 8px;
      }
    }
  }
}

/* OVERLAY DE REVALIDAÇÃO */
.security-revalidation-overlay {
  position: fixed;
  inset: 0;
  z-index: 9999998;
  background: rgba(var(--v-theme-surface), 0.6);
  backdrop-filter: blur(8px);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 24px;

  .revalidation-card {
    background: var(--bg-surface);
    width: 100%;
    max-width: 400px;
    padding: 32px;
    border-radius: 28px;
    text-align: center;
    box-shadow: 0 30px 60px rgba(0,0,0,0.2);

    h2 { font-weight: 800; margin-bottom: 8px; }
    p { color: var(--text-muted); font-size: 0.95rem; }
  }
}

/* DEGRADAÇÃO DE UX (BLUR LEVE NAS IMAGENS) */
.degraded-ux {
  filter: blur(2px);
  pointer-events: none; /* Dificulta scraping manual/cliques */
  transition: filter 1s ease;
}

.fade-overlay-enter-active, .fade-overlay-leave-active { transition: opacity 0.5s ease; }
.fade-overlay-enter-from, .fade-overlay-leave-to { opacity: 0; }

.fade-page-enter-active, .fade-page-leave-active { transition: opacity 0.2s ease, transform 0.2s ease; }
.fade-page-enter-from { opacity: 0; transform: translateY(10px); }
.fade-page-leave-to { opacity: 0; transform: translateY(-10px); }
</style>
