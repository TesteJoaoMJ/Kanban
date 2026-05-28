<template>
  <v-app :theme="themeStore.currentMode === 'glass' ? 'dark' : themeStore.currentMode">
    <router-view />

    <LowStockAlertModal />
    <GlobalUpdateAlert />

    <SessionExpiredModal />

    <v-snackbar
      v-model="appStore.snackbar.show"
      :color="appStore.snackbar.color"
      :timeout="appStore.snackbar.timeout"
      location="top right"
      class="mt-12"
      elevation="24"
    >
      <div class="d-flex align-center gap-2">
        <v-icon v-if="appStore.snackbar.color === 'success'" icon="mdi-check-circle" color="white"></v-icon>
        <v-icon v-if="appStore.snackbar.color === 'warning'" icon="mdi-alert" color="white"></v-icon>
        <v-icon v-if="appStore.snackbar.color === 'error'" icon="mdi-alert-circle" color="white"></v-icon>
        <span class="font-weight-bold">{{ appStore.snackbar.text }}</span>
      </div>

      <template v-slot:actions>
        <v-btn
          color="white"
          variant="text"
          icon="mdi-close"
          size="small"
          @click="appStore.snackbar.show = false"
        >
        </v-btn>
      </template>
    </v-snackbar>
  </v-app>
</template>

<script lang="ts" setup>
import { onMounted, onUnmounted } from 'vue'
import { useThemeStore } from '@/stores/theme'
import { useAppStore } from '@/stores/app'
import { useUserStore } from '@/stores/user'
import { supabase } from '@/api/supabase'
import { useRouter } from 'vue-router'
import LowStockAlertModal from '@/components/LowStockAlertModal.vue'
import GlobalUpdateAlert from '@/components/GlobalUpdateAlert.vue'
import SessionExpiredModal from '@/components/SessionExpiredModal.vue'
import { useAuditLogger } from '@/composables/useAuditLogger'

const themeStore = useThemeStore()
const appStore = useAppStore()
const userStore = useUserStore()
const router = useRouter()

const { initTelemetrySync } = useAuditLogger()

let stockCheckInterval: NodeJS.Timeout

const checkStock = async () => {
  try {
      if (!userStore.isLoggedIn) return;
      if (!userStore.profile) {
        await userStore.fetchProfile()
      }

      if (userStore.profile) {
        await appStore.fetchGlobalConfigs()
        await appStore.checkConsolidatedLowStock(userStore.profile)
      }
  } catch (e) {
      console.warn("Falha no background checkStock ignorada:", e);
  }
}

onMounted(() => {
  localStorage.removeItem('explicit_logout');
  themeStore.init()
  initTelemetrySync()

  // Ignora o erro se falhar na inicialização
  supabase.auth.getSession().then(({ data }) => {
    if (data.session) {
      checkStock()
    }
  }).catch(() => {})

  supabase.auth.onAuthStateChange((event, session) => {
    if (event === 'SIGNED_IN' && session) {
      checkStock()
    }
  })

  stockCheckInterval = setInterval(() => {
    if (userStore.user && document.visibilityState === 'visible') {
      checkStock()
    }
  }, 10 * 60 * 1000)
})

onUnmounted(() => {
  if (stockCheckInterval) clearInterval(stockCheckInterval)
})
</script>

<style scoped>
.gap-2 {
  gap: 8px;
}
</style>
