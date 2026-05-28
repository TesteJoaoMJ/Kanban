<template>
  <v-container fluid class="fill-height pa-0 bg-animated-image">
    <div class="background-overlay"></div>

    <div class="content-wrapper d-flex flex-column h-100 w-100">

      <div class="header-section px-6 py-4 d-flex align-center justify-space-between flex-shrink-0 border-b glass-divider">
        <div class="d-flex align-center text-caption text-white-50">
          <v-icon size="small" class="mr-2">mdi-store-cog</v-icon>
          <span>Cajuia</span>
          <v-icon size="small" class="mx-2">mdi-chevron-right</v-icon>
          <span class="text-white-70 font-weight-bold">Admin</span>
          <v-icon size="small" class="mx-2">mdi-chevron-right</v-icon>
          <span class="text-white font-weight-black text-uppercase text-shadow">{{ currentTabName }}</span>
        </div>

        <div class="d-flex align-center gap-3">
          <div class="digital-clock px-3 py-1 rounded-pill glass-chip border-white-10 d-flex align-center">
             <v-icon color="primary" size="small" class="mr-2 icon-pulse">mdi-clock-outline</v-icon>
             <span class="font-weight-black text-caption text-white mono-font">{{ realTimeClock }}</span>
          </div>

          <div class="glass-chip px-3 py-1 rounded-pill d-flex align-center">
            <v-icon size="x-small" color="success" class="mr-2">mdi-circle</v-icon>
            <span class="text-caption text-white font-weight-medium">Online</span>
            <v-divider vertical class="border-white-20 mx-2" style="height: 10px;"></v-divider>
            <v-icon size="x-small" class="mr-1 text-white-50">mdi-sync</v-icon>
            <span class="text-caption text-white-50">{{ lastSyncTime }}</span>
          </div>

          <v-btn icon size="small" variant="text" color="white" class="glass-btn-icon" to="/cajuia/pdv">
            <v-icon>mdi-close</v-icon>
            <v-tooltip activator="parent" location="bottom">Voltar ao PDV</v-tooltip>
          </v-btn>
        </div>
      </div>

      <div class="d-flex flex-grow-1 overflow-hidden">

        <div class="admin-sidebar glass-panel border-r border-white-10 d-flex flex-column py-4">
            <div class="px-4 mb-6 flex-grow-1 overflow-y-auto custom-scrollbar">
                <div class="text-overline text-white-30 font-weight-bold mb-2">Gerenciamento</div>

                <v-btn-toggle v-model="currentTab" color="primary" class="d-flex flex-column gap-2 bg-transparent h-auto" mandatory>

                    <v-btn value="products" class="justify-start px-4 rounded-lg text-none font-weight-bold glass-nav-btn" height="48">
                        <v-icon start class="mr-3">mdi-tshirt-crew</v-icon>
                        Produtos & Estoque
                    </v-btn>

                    <v-btn value="receivables" class="justify-start px-4 rounded-lg text-none font-weight-bold glass-nav-btn" height="48">
                      <v-icon start class="mr-3">mdi-arrow-down-bold-box-outline</v-icon>
                      Contas a Receber
                  </v-btn>

                  <v-btn value="payables" class="justify-start px-4 rounded-lg text-none font-weight-bold glass-nav-btn" height="48">
                      <v-icon start class="mr-3">mdi-arrow-up-bold-box-outline</v-icon>
                      Contas a Pagar
                  </v-btn>

                    <v-btn value="cash" class="justify-start px-4 rounded-lg text-none font-weight-bold glass-nav-btn" height="48">
                        <v-icon start class="mr-3">mdi-safe-square-outline</v-icon>
                        Tesouraria & Caixa
                    </v-btn>

                    <v-btn value="prices" class="justify-start px-4 rounded-lg text-none font-weight-bold glass-nav-btn" height="48">
                        <v-icon start class="mr-3">mdi-cash-multiple</v-icon>
                        Tabelas de Preço
                    </v-btn>

                    <v-btn value="files" class="justify-start px-4 rounded-lg text-none font-weight-bold glass-nav-btn" height="48">
                        <v-icon start class="mr-3">mdi-folder-multiple-outline</v-icon>
                        Arquivos & Relatórios
                    </v-btn>

                    <v-btn value="users" class="justify-start px-4 rounded-lg text-none font-weight-bold glass-nav-btn" height="48">
                        <v-icon start class="mr-3">mdi-account-group</v-icon>
                        Usuários & Acesso
                    </v-btn>

                    <div class="text-overline text-white-30 font-weight-bold mb-2 mt-4">Contábil</div>

                    <v-btn value="accounting_reports" class="justify-start px-4 rounded-lg text-none font-weight-bold glass-nav-btn" height="48">
                        <v-icon start class="mr-3">mdi-finance</v-icon>
                        Demonstrações (DRE)
                    </v-btn>

                    <v-btn value="accounting" class="justify-start px-4 rounded-lg text-none font-weight-bold glass-nav-btn" height="48">
                        <v-icon start class="mr-3">mdi-cogs</v-icon>
                        Configuração Contábil
                    </v-btn>
                    <v-btn value="bank_reconciliation" class="justify-start px-4 rounded-lg text-none font-weight-bold glass-nav-btn" height="48">
                      <v-icon start class="mr-3">mdi-bank-transfer</v-icon>
                      Conciliação (OFX)
                  </v-btn>

                </v-btn-toggle>
            </div>

            <div class="px-4 mt-auto">
                <div class="glass-card pa-3 rounded-lg bg-gradient-dark">
                    <div class="d-flex align-center mb-2">
                        <v-icon color="warning" size="small" class="mr-2">mdi-shield-alert</v-icon>
                        <span class="text-10 font-weight-bold text-white-70">ÁREA RESTRITA</span>
                    </div>
                    <div class="text-10 text-white-50 lh-1">
                        Todas as alterações são auditadas e registradas no log do sistema.
                    </div>
                </div>
            </div>
        </div>

        <div class="flex-grow-1 overflow-hidden position-relative bg-glass-body">
            <v-fade-transition mode="out-in">
                <component :is="activeComponent" key="currentTab" />
            </v-fade-transition>
        </div>

      </div>

    </div>
  </v-container>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted, defineAsyncComponent } from 'vue'
import { format } from 'date-fns'

// Importação Dinâmica dos Componentes Filhos
const AdminProductManagement = defineAsyncComponent(() => import('@/components/cajuia/AdminProductManagement.vue'))
const AdminPriceListManagement = defineAsyncComponent(() => import('@/components/cajuia/AdminPriceListManagement.vue'))
const AdminUserManagement = defineAsyncComponent(() => import('@/components/cajuia/AdminUserManagement.vue'))
const CajuiaAdminReportTab = defineAsyncComponent(() => import('@/components/admin/CajuiaAdminReportTab.vue'))
const AdminCashManagement = defineAsyncComponent(() => import('@/components/cajuia/AdminCashManagement.vue'))
const AdminAccountingConfig = defineAsyncComponent(() => import('@/components/cajuia/AdminAccountingConfig.vue'))
const AdminAccountingReports = defineAsyncComponent(() => import('@/components/cajuia/AdminAccountingReports.vue'))
const AdminBankReconciliation = defineAsyncComponent(() => import('@/components/cajuia/AdminBankReconciliation.vue'))
const AdminPayables = defineAsyncComponent(() => import('@/components/cajuia/AdminPayables.vue'))
const AdminReceivables = defineAsyncComponent(() => import('@/components/cajuia/AdminReceivables.vue'))

// Estado
const currentTab = ref('products')
const realTimeClock = ref(format(new Date(), 'HH:mm:ss'))
const lastSyncTime = ref(format(new Date(), 'HH:mm'))
let clockInterval: NodeJS.Timeout

// Computed: Seleção de Componente (CORRIGIDO AQUI)
const activeComponent = computed(() => {
    switch(currentTab.value) {
        case 'products': return AdminProductManagement
        case 'cash': return AdminCashManagement
        case 'prices': return AdminPriceListManagement
        case 'files': return CajuiaAdminReportTab
        case 'users': return AdminUserManagement
        case 'accounting': return AdminAccountingConfig
        case 'accounting_reports': return AdminAccountingReports // <--- ADICIONADO
        case 'bank_reconciliation': return AdminBankReconciliation
        case 'payables': return AdminPayables
        case 'receivables': return AdminReceivables
        default: return AdminProductManagement
    }
})

// Computed: Título do Header (CORRIGIDO AQUI)
const currentTabName = computed(() => {
    switch(currentTab.value) {
        case 'products': return 'Catálogo de Produtos'
        case 'cash': return 'Tesouraria Diária'
        case 'prices': return 'Gestão de Preços'
        case 'files': return 'Arquivos & Relatórios'
        case 'users': return 'Controle de Acesso'
        case 'accounting': return 'Configurações Contábeis'
        case 'accounting_reports': return 'Demonstrações Financeiras' // <--- ADICIONADO
        case 'bank_reconciliation': return 'Conciliação Bancária'
        case 'payables': return 'Contas a Pagar'
        case 'receivables': return 'Contas a Receber'
        default: return 'Admin'
    }
})

// Lifecycle
onMounted(() => {
    clockInterval = setInterval(() => {
        realTimeClock.value = format(new Date(), 'HH:mm:ss')
    }, 1000)
})

onUnmounted(() => {
    if(clockInterval) clearInterval(clockInterval)
})
</script>

<style scoped lang="scss">
.bg-animated-image { position: relative; width: 100vw; height: 100vh; overflow: hidden; background: #0f0f0f65; z-index: 1; }
.background-overlay { position: absolute; top: 0; left: 0; right: 0; bottom: 0; background: rgba(10, 10, 15, 0.4); z-index: -1; }
.content-wrapper { position: relative; z-index: 2; }

/* Glass System */
.glass-divider { border-color: rgba(255, 255, 255, 0.08) !important; }
.glass-chip { background: rgba(255, 255, 255, 0.08); border: 1px solid rgba(255,255,255,0.05); }
.glass-panel { background: rgba(30, 30, 35, 0.6); backdrop-filter: blur(20px); }
.glass-card { background: rgba(255, 255, 255, 0.03); border: 1px solid rgba(255, 255, 255, 0.05); }
.bg-glass-body { background: rgba(20, 20, 20, 0.3); backdrop-filter: blur(10px); }
.bg-gradient-dark { background: linear-gradient(135deg, rgba(30,30,30,0.8), rgba(10,10,10,0.9)); }

/* Navigation Buttons */
.glass-nav-btn {
    background: transparent !important;
    color: rgba(255, 255, 255, 0.6) !important;
    border: 1px solid transparent;
    transition: all 0.3s ease;
    justify-content: flex-start !important;

    &:hover {
        background: rgba(255, 255, 255, 0.05) !important;
        color: white !important;
    }
}

/* Active State for Toggle */
:deep(.v-btn--active) {
    background: rgba(var(--v-theme-primary), 0.15) !important;
    color: rgb(var(--v-theme-primary)) !important;
    border: 1px solid rgba(var(--v-theme-primary), 0.3);
    box-shadow: 0 0 15px rgba(var(--v-theme-primary), 0.2);

    .v-icon { color: rgb(var(--v-theme-primary)); }
}

/* Utilities */
.admin-sidebar { width: 280px; flex-shrink: 0; }
.custom-scrollbar::-webkit-scrollbar { width: 4px; }
.custom-scrollbar::-webkit-scrollbar-thumb { background: rgba(255, 255, 255, 0.1); border-radius: 2px; }

.text-white-30 { color: rgba(255, 255, 255, 0.3) !important; }
.text-white-50 { color: rgba(255, 255, 255, 0.5) !important; }
.text-white-70 { color: rgba(255, 255, 255, 0.7) !important; }
.border-white-10 { border-color: rgba(255, 255, 255, 0.1) !important; }
.border-white-20 { border-color: rgba(255, 255, 255, 0.2) !important; }
.mono-font { font-family: 'Roboto Mono', monospace; letter-spacing: -0.5px; }
.icon-pulse { animation: pulse 2s infinite; }
.text-shadow { text-shadow: 0 2px 10px rgba(0,0,0,0.5); }
.gap-2 { gap: 8px; } .gap-3 { gap: 12px; }

/* Correção de Tamanho de Fonte */
.text-10 { font-size: 10px !important; }

.lh-1 { line-height: 1.2; }

@keyframes pulse { 0% { opacity: 1; } 50% { opacity: 0.6; } 100% { opacity: 1; } }
</style>
