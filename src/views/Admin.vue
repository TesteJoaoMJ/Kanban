<template>
  <div
    class="apple-hub-layout fill-height d-flex flex-column position-relative overflow-hidden"
    :class="isLightMode ? 'bg-apple-light text-grey-darken-4' : 'bg-apple-dark text-white'"
  >
    <div class="ambient-glow" :class="isLightMode ? 'glow-light' : 'glow-dark'"></div>

    <v-fade-transition mode="out-in">

      <div v-if="!selectedView" class="w-100 h-100 d-flex flex-column position-relative z-10" key="hub">

        <div class="px-6 py-8 px-md-10 py-md-10 position-relative z-10 flex-shrink-0">
          <div class="breadcrumb text-caption font-weight-bold opacity-60 mb-2 d-flex align-center tracking-wide">
            <v-icon size="14" class="mr-1">mdi-home</v-icon>
            <span class="cursor-pointer hover-text" @click="$router.push({ name: 'Home' })">Dashboard</span>
            <span class="mx-2 opacity-50">/</span>
            <span>Administração</span>
          </div>

          <h1 class="text-h3 font-weight-black tracking-tight mb-2" style="letter-spacing: -1px !important;">
            Painel de Controle
          </h1>
          <p class="text-body-1 opacity-70 font-weight-medium" style="max-width: 550px;">
            Gerenciamento centralizado de diretrizes, segurança, operação e financeiro.
          </p>
        </div>

        <div class="flex-grow-1 overflow-y-auto custom-scrollbar px-6 px-md-10 pb-12 position-relative z-10">

          <transition name="fade-slide-up" appear>
            <div class="mb-10">
              <v-card
                class="apple-banner d-flex flex-column flex-md-row align-md-center px-6 py-5 rounded-xl"
                :class="isLightMode ? 'apple-banner-light' : 'apple-banner-dark'"
                elevation="0"
              >
                <v-avatar :color="isLightMode ? 'grey-darken-4' : 'white'" size="48" class="mr-5 mb-4 mb-md-0 flex-shrink-0">
                  <v-icon size="24" :color="isLightMode ? 'white' : 'grey-darken-4'">mdi-shield-crown</v-icon>
                </v-avatar>

                <div class="flex-grow-1">
                  <div class="text-[10px] font-weight-black text-uppercase tracking-widest opacity-60 mb-1">
                    Status do Ambiente
                  </div>
                  <div class="text-h6 font-weight-bold mb-1 d-flex align-center gap-3">
                    MJProcess Master

                  </div>
                  <div class="text-caption opacity-80" style="max-width: 700px; line-height: 1.4;">
                    Você está na área restrita. As configurações aplicadas aqui têm efeito global sobre todos os módulos, usuários e integrações do sistema.
                  </div>
                </div>

                <div class="mt-4 mt-md-0 flex-shrink-0 d-flex flex-column align-end">
                  <div class="text-[10px] font-weight-bold text-uppercase tracking-widest opacity-60 mb-1">Horário Local</div>
                  <div class="text-h6 font-weight-bold font-mono">{{ currentTime }}</div>
                </div>
              </v-card>
            </div>
          </transition>

          <transition-group name="staggered-fade" tag="div" class="w-100">
            <div
              v-for="(group, index) in groupedViews"
              :key="group.name"
              class="mb-10"
              :style="{ transitionDelay: `${0.1 * (index + 1)}s` }"
            >
              <div class="d-flex align-center mb-5 ml-1">
                <v-icon :color="group.color" size="small" class="mr-2">{{ group.icon }}</v-icon>
                <h2 class="text-h6 font-weight-bold opacity-90">{{ group.name }}</h2>
              </div>

              <v-row dense>
                <v-col
                  cols="12"
                  sm="6"
                  lg="3"
                  xl="3"
                  v-for="view in group.items"
                  :key="view.key"
                >
                  <v-card
                    class="apple-report-card h-100 d-flex flex-column rounded-xl"
                    :class="isLightMode ? 'card-light' : 'card-dark'"
                    elevation="0"
                    @click="selectedView = view.key"
                  >
                    <div class="glass-reflection"></div>
                    <div class="color-glow" :style="{ backgroundColor: view.color }"></div>

                    <v-card-text class="pa-5 d-flex flex-column h-100 position-relative z-10">
                      <div class="d-flex justify-space-between align-start mb-4">
                          <v-avatar :color="view.color" size="42" class="shadow-sm rounded-lg text-white">
                            <v-icon size="22">{{ view.icon }}</v-icon>
                          </v-avatar>

                          <v-chip v-if="view.badge" size="x-small" :color="view.badgeColor || 'grey-darken-3'" variant="flat" class="font-weight-black text-white px-3 shadow-sm" style="border-radius: 4px;">
                            {{ view.badge }}
                          </v-chip>
                      </div>

                      <h3 class="text-subtitle-1 font-weight-black mb-2" style="letter-spacing: -0.3px;">
                        {{ view.title }}
                      </h3>

                      <p class="text-caption opacity-70 mb-4 flex-grow-1" style="line-height: 1.5;">
                        {{ view.subtitle }}
                      </p>

                      <div class="d-flex align-center text-caption font-weight-bold mt-auto" :style="{ color: isLightMode ? view.color : '#fff' }">
                        Acessar Módulo
                        <v-icon size="14" class="ml-1 transition-transform arrow-icon">mdi-arrow-right</v-icon>
                      </div>
                    </v-card-text>
                  </v-card>
                </v-col>
              </v-row>
            </div>
          </transition-group>

        </div>
      </div>

      <div v-else class="w-100 h-100 d-flex flex-column position-relative z-10" key="module">

        <div v-if="isFullLayout" class="h-100 w-100 relative">
            <v-window v-model="selectedView" class="h-100 w-100" :touch="false">
                <v-window-item value="proofs" class="h-100"><AdminDownPaymentProofs /></v-window-item>
                <v-window-item value="mj_cash" class="h-100"><AdminMjCashManagement /></v-window-item>
                <v-window-item value="mj_receivables" class="h-100"><AdminMjReceivables /></v-window-item>
                <v-window-item value="mj_payables" class="h-100"><AdminMjPayables /></v-window-item>
                <v-window-item value="users" class="h-100"><AdminUserManagement /></v-window-item>
                <v-window-item value="stock" class="h-100"><StockManagement /></v-window-item>
                <v-window-item value="financial_audit" class="h-100"><FinancialAuditView /></v-window-item>
                <v-window-item value="pcp_builder" class="h-100"><AdminPcpBuilder /></v-window-item>
                <v-window-item value="cockpit" class="h-100"><SystemCockpit /></v-window-item>
            </v-window>

            <v-btn
                position="fixed"
                location="bottom left"
                icon="mdi-apps"
                :color="isLightMode ? 'grey-darken-4' : 'white'"
                class="ma-6 elevation-8 btn-sq"
                @click="selectedView = null"
                style="z-index: 9990;"
                size="large"
                v-tooltip="'Voltar ao Painel'"
            ></v-btn>
        </div>

        <div v-else class="flex-grow-1 pa-4 pa-md-8 d-flex flex-column h-100 overflow-hidden">
            <v-card class="flex-grow-1 rounded-xl border-thin shadow-soft overflow-hidden d-flex flex-column transition-colors" :class="isLightMode ? 'bg-white border-grey-lighten-2' : 'bg-grey-darken-4 border-white-10'">
                <div class="pa-4 border-b d-flex align-center flex-shrink-0 transition-colors" :class="isLightMode ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-grey-darken-3 border-white-10'">
                    <v-btn variant="tonal" density="comfortable" size="small" class="font-weight-black rounded-lg mr-4 px-4 text-none tracking-wide" @click="selectedView = null">
                        <v-icon start size="16">mdi-arrow-left</v-icon> Painel Admin
                    </v-btn>
                    <v-divider vertical class="mx-2 opacity-30"></v-divider>
                    <span class="text-subtitle-2 font-weight-black ml-2 tracking-tight" :class="isLightMode ? 'text-grey-darken-4' : 'text-white'">
                        {{ getViewTitle(selectedView) }}
                    </span>
                </div>

                <div class="flex-grow-1 overflow-y-auto custom-scrollbar relative">
                    <v-window v-model="selectedView" class="h-100 w-100" :touch="false">
                        <v-window-item value="reports" class="h-100"><AdminReportsTab /></v-window-item>
                        <v-window-item value="audit" class="h-100"><AdminAuditTab /></v-window-item>
                        <v-window-item value="notifications" class="h-100"><AdminNotificationsTab /></v-window-item>
                        <v-window-item value="prices" class="h-100"><AdminPriceListManagement /></v-window-item>
                        <v-window-item value="monitoring" class="h-100"><AdminActivityMonitor /></v-window-item>
                        <v-window-item value="productivity" class="h-100"><AdminProductivityRules /></v-window-item>
                        <v-window-item value="workSchedules" class="h-100"><WorkScheduleManagement /></v-window-item>
                        <v-window-item value="timeExtensions" class="h-100"><TimeExtensionApproval /></v-window-item>
                    </v-window>
                </div>
            </v-card>
        </div>

      </div>

    </v-fade-transition>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, defineAsyncComponent, onMounted, onUnmounted } from 'vue';
import { format } from 'date-fns';
import { useRoute } from 'vue-router';
import { useThemeStore } from '@/stores/theme';

const route = useRoute();
const themeStore = useThemeStore();

const isLightMode = computed(() => themeStore.currentMode === 'light');

// Importação Dinâmica de Componentes
const StockManagement = defineAsyncComponent(() => import('@/views/admin/StockManagement.vue'));
const AdminAuditTab = defineAsyncComponent(() => import('@/components/admin/AdminAuditTab.vue'));
const AdminReportsTab = defineAsyncComponent(() => import('@/components/admin/AdminReportsTab.vue'));
const AdminNotificationsTab = defineAsyncComponent(() => import('@/components/admin/AdminNotificationsTab.vue'));
const AdminPriceListManagement = defineAsyncComponent(() => import('@/components/admin/AdminPriceListManagement.vue'));
const AdminUserManagement = defineAsyncComponent(() => import('@/components/admin/AdminUserManagement.vue'));
const AdminDownPaymentProofs = defineAsyncComponent(() => import('@/components/admin/AdminDownPaymentProofs.vue'));
const AdminActivityMonitor = defineAsyncComponent(() => import('@/components/admin/AdminActivityMonitor.vue'));
const AdminProductivityRules = defineAsyncComponent(() => import('@/components/admin/AdminProductivityRules.vue'));
const WorkScheduleManagement = defineAsyncComponent(() => import('@/components/admin/WorkScheduleManagement.vue'));
const TimeExtensionApproval = defineAsyncComponent(() => import('@/components/admin/TimeExtensionApproval.vue'));
const AdminMjCashManagement = defineAsyncComponent(() => import('@/components/admin/AdminMjCashManagement.vue'));
const AdminMjReceivables = defineAsyncComponent(() => import('@/components/admin/AdminMjReceivables.vue'));
const AdminMjPayables = defineAsyncComponent(() => import('@/components/admin/AdminMjPayables.vue'));
const FinancialAuditView = defineAsyncComponent(() => import('@/views/admin/FinancialAuditView.vue'));
const AdminPcpBuilder = defineAsyncComponent(() => import('@/components/admin/AdminPcpBuilder.vue'));
const SystemCockpit = defineAsyncComponent(() => import('@/views/admin/SystemCockpit.vue'));

const selectedView = ref<string | null>(null);
const currentTime = ref('');
const isOnline = ref(navigator.onLine);
let clockInterval: any;

// Módulos que ocupam 100% da viewport sem padding (Full Layout)
const fullLayoutViews = [
    'proofs',
    'mj_cash',
    'mj_receivables',
    'mj_payables',
    'users',
    'stock',
    'financial_audit',
    'cockpit',
    'pcp_builder',
];
const isFullLayout = computed(() => selectedView.value && fullLayoutViews.includes(selectedView.value));

// Definição dos Cards do Menu Principal
const adminViews = [
  { key: 'stock', title: 'Controle de Estoque', subtitle: 'Gestão de rolos e metragens.', icon: 'mdi-warehouse', color: '#009688', group: 'Gestão Operacional' },
  { key: 'prices', title: 'Tabela de Preços', subtitle: 'Configuração de valores base.', icon: 'mdi-currency-usd', color: '#7E57C2', group: 'Gestão Operacional' },
  { key: 'proofs', title: 'Comprovantes', subtitle: 'Validação de sinais.', icon: 'mdi-receipt-text-check', color: '#009688', group: 'Gestão Operacional' },
  { key: 'pcp_builder', title: 'Workflow Builder', subtitle: 'Motor BPMN de Produção', icon: 'mdi-sitemap-outline', color: '#E91E63', group: 'Gestão Operacional', badge: 'PRO', badgeColor: '#D32F2F' },

  { key: 'users', title: 'Gestão de Usuários', subtitle: 'Controle de acessos e roles.', icon: 'mdi-account-supervisor-circle', color: '#607D8B', group: 'Governança', badge: 'Admin', badgeColor: '#455A64' },
  { key: 'workSchedules', title: 'Escalas de Trabalho', subtitle: 'Horários e turnos.', icon: 'mdi-calendar-clock', color: '#3F51B5', group: 'Governança' },
  { key: 'productivity', title: 'Regras Produtividade', subtitle: 'Blacklist e monitoramento.', icon: 'mdi-cogs', color: '#00BCD4', group: 'Governança' },

  { key: 'cockpit', title: 'Cockpit Nuclear', subtitle: 'Saúde do Sistema SRE', icon: 'mdi-radioactive', color: '#f85149', group: 'Monitoramento', badge: 'Status', badgeColor: '#f85149' },
  { key: 'reports', title: 'Relatórios BI', subtitle: 'Métricas de desempenho.', icon: 'mdi-chart-box-outline', color: '#2196F3', group: 'Monitoramento' },
  { key: 'monitoring', title: 'Atividade Live', subtitle: 'Usuários online agora.', icon: 'mdi-monitor-dashboard', color: '#FF9800', group: 'Monitoramento', badge: 'Live', badgeColor: '#D32F2F' },
  { key: 'audit', title: 'Logs do Sistema', subtitle: 'Logs técnicos gerais.', icon: 'mdi-history', color: '#03A9F4', group: 'Monitoramento' },

  { key: 'notifications', title: 'Broadcast', subtitle: 'Alertas globais.', icon: 'mdi-bullhorn', color: '#FFC107', group: 'Sistema' },
  { key: 'timeExtensions', title: 'Aprovações de Tempo', subtitle: 'Extensões de horário.', icon: 'mdi-timer-sand', color: '#E91E63', group: 'Sistema' },

  // FINANCEIRO MJ
  { key: 'mj_cash', title: 'Auditoria de Caixa', subtitle: 'Conferência financeira.', icon: 'mdi-cash-register', color: '#00E676', group: 'Financeiro MJ' },
  { key: 'mj_receivables', title: 'Contas a Receber', subtitle: 'Gestão de recebíveis.', icon: 'mdi-finance', color: '#E040FB', group: 'Financeiro MJ' },
  { key: 'mj_payables', title: 'Notas de Entrada', subtitle: 'Sincronização SEFAZ.', icon: 'mdi-cloud-sync', color: '#FF5722', group: 'Financeiro MJ' },
  { key: 'financial_audit', title: 'Auditoria Financeira', subtitle: 'Logs de baixas e estornos.', icon: 'mdi-shield-search', color: '#673AB7', group: 'Financeiro MJ' },
];

const groupedViews = computed(() => {
  const groups: Record<string, { name: string, color: string, icon: string, items: any[] }> = {
    'Gestão Operacional': { name: 'Operações e Setup', color: '#4CAF50', icon: 'mdi-domain', items: [] },
    'Financeiro MJ': { name: 'Controle Financeiro', color: '#00E676', icon: 'mdi-bank', items: [] },
    'Governança': { name: 'Acessos & Pessoas', color: '#3F51B5', icon: 'mdi-shield-account', items: [] },
    'Monitoramento': { name: 'Monitoramento & BI', color: '#FF9800', icon: 'mdi-radar', items: [] },
    'Sistema': { name: 'Ferramentas do Sistema', color: '#9E9E9E', icon: 'mdi-console', items: [] },
  };
  adminViews.forEach(view => { if (groups[view.group]) groups[view.group].items.push(view); });
  return Object.values(groups);
});

const getViewTitle = (key: string | null) => {
    if (!key) return '';
    return adminViews.find(v => v.key === key)?.title || 'Módulo Administrativo';
};

const updateClock = () => { currentTime.value = format(new Date(), 'HH:mm'); };

onMounted(() => {
  updateClock();
  clockInterval = setInterval(updateClock, 1000);
  window.addEventListener('online', () => { isOnline.value = true; });
  window.addEventListener('offline', () => { isOnline.value = false; });

  if (route.query.view && typeof route.query.view === 'string') {
      selectedView.value = route.query.view;
  }
});

onUnmounted(() => { clearInterval(clockInterval); });
</script>

<style scoped>
/* FUNDO AMBIENTE APPLE */
.apple-hub-layout {
  transition: background-color 0.5s ease;
}
.bg-apple-light { background-color: #f5f5f7; }
.bg-apple-dark { background-color: #000000; }

.ambient-glow {
  position: absolute;
  top: -10%;
  left: -10%;
  width: 50vw;
  height: 50vh;
  border-radius: 50%;
  filter: blur(100px);
  pointer-events: none;
  z-index: 0;
  opacity: 0.5;
}
.glow-light { background: radial-gradient(circle, rgba(0, 122, 255, 0.05), transparent); }
.glow-dark { background: radial-gradient(circle, rgba(255, 255, 255, 0.03), transparent); }

/* UTILITÁRIOS DE TEXTO */
.tracking-widest { letter-spacing: 0.15em !important; }
.tracking-wide { letter-spacing: 0.05em !important; }
.tracking-tight { letter-spacing: -0.5px !important; }
.leading-tight { line-height: 1.2 !important; }
.hover-text:hover { opacity: 1 !important; color: rgb(var(--v-theme-primary)); }
.lh-1 { line-height: 1 !important; }

.btn-sq { border-radius: 6px !important; }
.status-dot { width: 8px; height: 8px; border-radius: 50%; }
.pulse-anim { animation: pulse 2s infinite; }
@keyframes pulse {
    0% { transform: scale(1); opacity: 1; }
    50% { transform: scale(1.2); opacity: 0.6; }
    100% { transform: scale(1); opacity: 1; }
}

.shadow-soft { box-shadow: 0 4px 16px rgba(0,0,0,0.06) !important; }
.shadow-sm { box-shadow: 0 2px 8px rgba(0,0,0,0.04) !important; }
.border-white-10 { border-color: rgba(255, 255, 255, 0.1) !important; }
.border-white-05 { border-color: rgba(255, 255, 255, 0.05) !important; }

/* BANNER CONTEXTO (FROSTED GLASS CLEAN) */
.apple-banner {
  backdrop-filter: blur(20px);
  -webkit-backdrop-filter: blur(20px);
  border-radius: 20px !important;
}
.apple-banner-light {
  background: rgba(255, 255, 255, 0.6) !important;
  border: 1px solid rgba(0, 0, 0, 0.05) !important;
  box-shadow: 0 4px 24px rgba(0, 0, 0, 0.02) !important;
}
.apple-banner-dark {
  background: rgba(30, 30, 35, 0.4) !important;
  border: 1px solid rgba(255, 255, 255, 0.1) !important;
  box-shadow: 0 4px 24px rgba(0, 0, 0, 0.2) !important;
}

/* CARDS 3D PREMIUM (APPLE STYLE) */
.apple-report-card {
  position: relative;
  overflow: hidden;
  cursor: pointer;
  transition: all 0.4s cubic-bezier(0.2, 0.8, 0.2, 1);
  border-radius: 20px !important;
}

/* Modo Light */
.apple-report-card.card-light {
  background: linear-gradient(145deg, #ffffff 0%, #f9f9fb 100%) !important;
  border: 1px solid rgba(0, 0, 0, 0.04) !important;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.03), inset 0 1px 0 rgba(255, 255, 255, 1) !important;
}
.apple-report-card.card-light:hover {
  transform: translateY(-6px) scale(1.02);
  box-shadow: 0 12px 32px rgba(0, 0, 0, 0.08), 0 4px 8px rgba(0, 0, 0, 0.03), inset 0 1px 0 rgba(255, 255, 255, 1) !important;
}

/* Modo Dark */
.apple-report-card.card-dark {
  background: linear-gradient(145deg, #1c1c1e 0%, #121214 100%) !important;
  border: 1px solid rgba(255, 255, 255, 0.06) !important;
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.2), inset 0 1px 0 rgba(255, 255, 255, 0.05) !important;
}
.apple-report-card.card-dark:hover {
  transform: translateY(-6px) scale(1.02);
  border-color: rgba(255, 255, 255, 0.15) !important;
  box-shadow: 0 16px 40px rgba(0, 0, 0, 0.4), 0 6px 12px rgba(0, 0, 0, 0.2), inset 0 1px 0 rgba(255, 255, 255, 0.1) !important;
}

/* REFLEXOS E BRILHOS INTERNOS */
.glass-reflection {
  position: absolute;
  top: 0; left: 0; right: 0;
  height: 100%;
  background: linear-gradient(135deg, rgba(255, 255, 255, 0.1) 0%, rgba(255, 255, 255, 0) 40%);
  pointer-events: none;
  z-index: 1;
}

.color-glow {
  position: absolute;
  width: 120px;
  height: 120px;
  bottom: -40px;
  right: -40px;
  border-radius: 50%;
  filter: blur(40px);
  opacity: 0.1;
  pointer-events: none;
  z-index: 0;
  transition: opacity 0.4s ease, transform 0.4s ease;
}

.apple-report-card:hover .color-glow {
  opacity: 0.25;
  transform: scale(1.2);
}

.card-light .color-glow { opacity: 0.08; }
.card-light:hover .color-glow { opacity: 0.15; }

/* ANIMAÇÃO DA SETA */
.arrow-icon {
  transition: transform 0.3s cubic-bezier(0.2, 0.8, 0.2, 1);
}
.apple-report-card:hover .arrow-icon {
  transform: translateX(4px);
}

/* ANIMAÇÕES DE ENTRADA */
.fade-slide-up-enter-active {
  transition: opacity 0.8s ease, transform 0.8s cubic-bezier(0.2, 0.8, 0.2, 1);
}
.fade-slide-up-enter-from {
  opacity: 0;
  transform: translateY(20px);
}

.staggered-fade-enter-active {
  transition: opacity 0.6s ease, transform 0.6s cubic-bezier(0.2, 0.8, 0.2, 1);
}
.staggered-fade-enter-from {
  opacity: 0;
  transform: translateY(15px);
}

/* CUSTOM SCROLLBAR */
.custom-scrollbar::-webkit-scrollbar { width: 6px; }
.custom-scrollbar::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.2); border-radius: 6px; }
.custom-scrollbar:hover::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.4); }
</style>
