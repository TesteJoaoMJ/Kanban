<template>
  <div class="dashboard-manager fill-height position-relative">

    <div
      v-if="userStore.isSuperAdmin"
      class="super-admin-controls d-flex align-center justify-end px-6 py-2 position-absolute w-100"
      :class="isLight ? 'bg-control-light' : 'bg-control-dark'"
      style="z-index: 99; top: 0; right: 0; height: 50px; backdrop-filter: blur(10px);"
    >
      <span
        class="text-caption font-weight-bold mr-3 text-uppercase letter-spacing-1"
        :class="isLight ? 'text-grey-darken-2' : 'text-grey-lighten-1'"
      >
        Modo de Visualização:
      </span>

      <v-btn-toggle
        v-model="currentViewMode"
        density="compact"
        variant="outlined"
        divided
        class="rounded-lg"
        color="primary"
        mandatory
      >
        <v-btn value="holding" prepend-icon="mdi-domain" size="small" class="text-none font-weight-bold" :color="isLight ? 'grey-darken-3' : 'white'">
          Holding (Financeiro)
        </v-btn>
        <v-btn value="operational" prepend-icon="mdi-factory" size="small" class="text-none font-weight-bold" :color="isLight ? 'grey-darken-3' : 'white'">
          Operacional (MJ)
        </v-btn>
      </v-btn-toggle>
    </div>

    <div class="h-100 w-100" :style="{ paddingTop: userStore.isSuperAdmin ? '50px' : '0' }">
      <v-fade-transition mode="out-in">
        <component :is="resolvedDashboardComponent" :key="componentKey" />
      </v-fade-transition>
    </div>

  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, defineAsyncComponent } from 'vue';
import { useUserStore } from '@/stores/user';
import { useThemeStore } from '@/stores/theme';

// --- STORES ---
const userStore = useUserStore();
const themeStore = useThemeStore();

// --- COMPUTED THEME ---
const isLight = computed(() => themeStore.currentMode === 'light');

// --- COMPONENTS (Async Loading) ---
const SuperAdminDashboard = defineAsyncComponent(() => import('@/views/admin/SuperAdminDashboard.vue'));
const AdminDashboard = defineAsyncComponent(() => import('@/components/dashboards/AdminDashboard.vue'));
const DesignerDashboard = defineAsyncComponent(() => import('@/components/dashboards/DesignerDashboard.vue'));
const ProducaoDashboard = defineAsyncComponent(() => import('@/components/dashboards/ProducaoDashboard.vue'));
const VendedorDashboard = defineAsyncComponent(() => import('@/components/dashboards/VendedorDashboard.vue'));
const FinanceiroDashboard = defineAsyncComponent(() => import('@/components/dashboards/FinanceiroDashboard.vue'));

// --- NOVOS DASHBOARDS CAJUIA ---
const CortadoraDashboard = defineAsyncComponent(() => import('@/views/cajuia/CortadoraDashboard.vue'));
const CajuiaSellerDashboard = defineAsyncComponent(() => import('@/views/cajuia/SellerDashboard.vue'));

// --- STATE ---
const currentViewMode = ref<'holding' | 'operational'>(userStore.isSuperAdmin ? 'holding' : 'operational');

// --- LÓGICA DE SELEÇÃO DE DASHBOARD ---
const resolvedDashboardComponent = computed(() => {
  if (userStore.isSuperAdmin && currentViewMode.value === 'holding') {
    return SuperAdminDashboard;
  }

  const customRoleId = userStore.profile?.custom_role_id;
  const roleLegacy = userStore.profile?.role;

  // 1. PRIORIDADE: Mapeamento pelas novas Roles (custom_role_id)
  if (customRoleId) {
    switch (customRoleId) {
      // Cortadora Cajuia
      case '844dafaf-a9db-4854-9ae2-f88d04880b37':
        return CortadoraDashboard;

      // Vendedor Cajuia
      case 'd3ced007-e281-4f6f-9030-f7ba55b6a67c':
        return CajuiaSellerDashboard;

      // Vendedor MJ
      case '45f7b0ff-b4ec-4691-b841-d3cb9975cfaf':
        return VendedorDashboard;

      // Financeiro
      case '719ae2a7-9a7d-4038-907f-f28bf6deac6f':
        return FinanceiroDashboard;

      // Designer / Líder de Design
      case 'e71590f0-9310-483c-b71f-ad4e74102505':
      case '9b6fa119-7f46-458e-a60a-404046d13840':
        return DesignerDashboard;

      // Impressor
      case '406d3255-d701-491f-9650-41a02c8e34d7':
        return ProducaoDashboard;

      // Cargos Administrativos / PCP / Diretoria / Full-Stack
      case '04b3c83f-0b32-4e26-8df9-6bc7ec679cee': // Diretora Comercial
      case '54cebf6b-d867-44d4-8b64-4ea58944b5bf': // Diretor Produção
      case 'a4723970-edfa-46ad-b5aa-25cb8fffe458': // Full-Stack
      case '4cf1eb8e-d5fc-4bd3-821a-05f77c25ecfc': // PCP
        return AdminDashboard;
    }
  }

  // 2. FALLBACK: Modo Operacional para usuários sem custom_role_id ainda
  switch (roleLegacy) {
    case 'super_admin':
    case 'admin':
    case 'gerente':
      return AdminDashboard;
    case 'financeiro':
      return FinanceiroDashboard;
    case 'designer':
      return DesignerDashboard;
    case 'producao':
      return ProducaoDashboard;
    case 'vendedor':
      return VendedorDashboard;
    default:
      console.warn(`Role e Custom Role não mapeadas. Carregando VendedorDashboard por padrão.`);
      return VendedorDashboard;
  }
});

const componentKey = computed(() => {
  if (userStore.isSuperAdmin && currentViewMode.value === 'holding') return 'holding';
  return `operational-${userStore.profile?.custom_role_id || userStore.profile?.role}`;
});

// --- LIFECYCLE ---
onMounted(() => {
  if (!userStore.isSuperAdmin) {
    currentViewMode.value = 'operational';
  }
});
</script>

<style scoped>
.dashboard-manager {
  background-color: transparent !important;
}

.bg-control-light {
  background: rgba(255, 255, 255, 0.9);
  border-bottom: 1px solid rgba(0, 0, 0, 0.05);
}

.bg-control-dark {
  background: rgba(30, 30, 35, 0.6);
  border-bottom: 1px solid rgba(255, 255, 255, 0.08);
}

.super-admin-controls .v-btn {
  border-color: rgba(128, 128, 128, 0.2) !important;
}
.super-admin-controls .v-btn--active {
  background-color: rgb(var(--v-theme-primary)) !important;
  color: white !important;
}
</style>
