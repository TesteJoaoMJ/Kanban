<template>
  <div
    class="apple-hub-layout fill-height d-flex flex-column position-relative overflow-x-hidden"
    :class="isLightMode ? 'bg-apple-light text-grey-darken-4' : 'bg-apple-dark text-white'"
  >
    <!-- Background Gradient Sutil -->
    <div class="ambient-glow" :class="isLightMode ? 'glow-light' : 'glow-dark'"></div>

    <!-- Header Elegante -->
    <div class="px-6 py-8 px-md-10 py-md-10 position-relative z-10 flex-shrink-0">
      <div class="breadcrumb text-caption font-weight-bold opacity-60 mb-2 d-flex align-center tracking-wide">
        <v-icon size="14" class="mr-1">mdi-home</v-icon>
        <span class="cursor-pointer hover-text" @click="$router.push({ name: 'Home' })">Dashboard</span>
        <span class="mx-2 opacity-50">/</span>
        <span>Relatórios</span>
      </div>

      <h1 class="text-h3 font-weight-black tracking-tight mb-2" style="letter-spacing: -1px !important;">
        Central de Análises
      </h1>
      <p class="text-body-1 opacity-70 font-weight-medium" style="max-width: 550px;">
        Métricas e inteligência de negócios. Escolha um módulo abaixo para visualizar os dados detalhados da sua operação.
      </p>
    </div>

    <div class="flex-grow-1 overflow-y-auto custom-scrollbar px-6 px-md-10 pb-12 position-relative z-10">

      <!-- Banner Multi-Tenant Estilo Apple (Glass) -->
      <transition name="fade-slide-up" appear>
        <div class="mb-10" v-show="showContent">
          <v-card
            class="apple-banner d-flex flex-column flex-md-row align-md-center px-6 py-5 rounded-xl"
            :class="isLightMode ? 'apple-banner-light' : 'apple-banner-dark'"
            elevation="0"
          >
            <v-avatar :color="isLightMode ? 'grey-darken-4' : 'white'" size="48" class="mr-5 mb-4 mb-md-0 flex-shrink-0">
              <v-icon size="24" :color="isLightMode ? 'white' : 'grey-darken-4'">
                {{ isGlobalView ? 'mdi-earth' : 'mdi-domain' }}
              </v-icon>
            </v-avatar>

            <div class="flex-grow-1">
              <div class="text-[10px] font-weight-black text-uppercase tracking-widest opacity-60 mb-1">
                Contexto de Exibição
              </div>
              <div class="text-h6 font-weight-bold mb-1">
                {{ isGlobalView ? 'Visão Global (Holding)' : companyName }}
              </div>
              <div class="text-caption opacity-80" style="max-width: 700px; line-height: 1.4;">
                Os relatórios estão processando dados referentes a este ambiente. Você pode alternar a empresa ativa a qualquer momento no menu lateral esquerdo para recalcular os indicadores.
              </div>
            </div>

            <div class="mt-4 mt-md-0 flex-shrink-0">
              <v-chip
                variant="outlined"
                size="small"
                class="font-weight-bold px-4"
                :color="isLightMode ? 'grey-darken-3' : 'white'"
              >
                Sincronizado
              </v-chip>
            </div>
          </v-card>
        </div>
      </transition>

      <!-- Categorias de Relatórios -->
      <transition-group name="staggered-fade" tag="div" class="w-100">
        <div
          v-for="(category, index) in reportCategories"
          :key="category.title"
          class="mb-10"
          v-show="showContent"
          :style="{ transitionDelay: `${0.1 * (index + 1)}s` }"
        >
          <div class="d-flex align-center mb-5 ml-1">
            <h2 class="text-h6 font-weight-bold opacity-90">{{ category.title }}</h2>
          </div>

          <v-row dense>
            <v-col
              cols="12"
              sm="6"
              lg="3"
              xl="3"
              v-for="report in category.reports"
              :key="report.routeName"
            >
              <!-- Card 3D Premium -->
              <v-card
                class="apple-report-card h-100 d-flex flex-column rounded-xl"
                :class="isLightMode ? 'card-light' : 'card-dark'"
                elevation="0"
                @click="handleReportClick(report.routeName)"
              >
                <!-- Reflexo estilo vidro na parte superior -->
                <div class="glass-reflection"></div>
                <!-- Brilho colorido de fundo dependendo da cor do relatório -->
                <div class="color-glow" :class="`bg-${report.color}`"></div>

                <v-card-text class="pa-5 d-flex flex-column h-100 position-relative z-10">
                  <v-avatar :color="report.color" size="42" class="mb-4 shadow-sm rounded-lg text-white">
                    <v-icon size="22">{{ report.icon }}</v-icon>
                  </v-avatar>

                  <h3 class="text-subtitle-1 font-weight-black mb-2" style="letter-spacing: -0.3px;">
                    {{ report.title }}
                  </h3>

                  <p class="text-caption opacity-70 mb-4 flex-grow-1" style="line-height: 1.5;">
                    {{ report.description }}
                  </p>

                  <div class="d-flex align-center text-caption font-weight-bold mt-auto" :class="`text-${report.color}`">
                    Abrir Relatório
                    <v-icon size="14" class="ml-1 transition-transform arrow-icon">mdi-arrow-right</v-icon>
                  </div>
                </v-card-text>

                <!-- Overlay de Loading ao Clicar -->
                <div v-if="loadingRoute === report.routeName" class="loading-overlay d-flex align-center justify-center position-absolute w-100 h-100 top-0 left-0 z-20">
                   <v-progress-circular indeterminate size="24" :color="report.color" width="3"></v-progress-circular>
                </div>
              </v-card>
            </v-col>
          </v-row>
        </div>
      </transition-group>

    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { useThemeStore } from '@/stores/theme';
import { useCompanyStore } from '@/stores/company';
import { useUserStore } from '@/stores/user'; // <-- IMPORTADO O USER STORE

const router = useRouter();
const themeStore = useThemeStore();
const companyStore = useCompanyStore();
const userStore = useUserStore(); // <-- INICIALIZADO

const showContent = ref(false);
const loadingRoute = ref<string | null>(null);

const isLightMode = computed(() => themeStore.currentMode === 'light');
const isGlobalView = computed(() => companyStore.isGlobalView);
const companyName = computed(() => companyStore.currentCompanyName || 'Empresa Indefinida');

// 1. Criamos a lista base com a chave "permission" em cada relatório
const allReportCategories = [
  {
    title: 'Análise Financeira',
    reports: [
      {
        title: 'DRE (Resultados)',
        description: 'Demonstrativo de Resultado do Exercício. Visualize lucro, receitas e despesas.',
        icon: 'mdi-chart-waterfall',
        color: 'success',
        routeName: 'FinancialDreReport',
        permission: 'rep_fin_dre'
      },
      {
        title: 'Contas a Receber',
        description: 'Acompanhe pagamentos pendentes, faturamentos e clientes inadimplentes.',
        icon: 'mdi-cash-plus',
        color: 'info',
        routeName: 'FinancialReceivablesReport',
        permission: 'rep_fin_receivables'
      },
      {
        title: 'Contas a Pagar',
        description: 'Controle despesas operacionais, pagamentos a fornecedores e obrigações.',
        icon: 'mdi-cash-minus',
        color: 'error',
        routeName: 'FinancialPayablesReport',
        permission: 'rep_fin_payables'
      }
    ]
  },
  {
    title: 'Performance de Vendas',
    reports: [
      {
        title: 'Vendas Detalhadas',
        description: 'Ranking de vendedores, clientes e curva ABC de produtos faturados.',
        icon: 'mdi-chart-bell-curve-cumulative',
        color: 'primary',
        routeName: 'SalesReport',
        permission: 'rep_sales'
      },
      {
        title: 'Compliance de Preços',
        description: 'Confrontação de pedidos contra a tabela de estoque. Identifique descontos indevidos e divergências.',
        icon: 'mdi-shield-search',
        color: 'deep-purple',
        routeName: 'SalesAuditReport',
        permission: 'rep_sales'
      }
    ]
  },
  {
    title: 'Estoque & Logística',
    reports: [
      {
        title: 'Movimentações de Estoque',
        description: 'Auditoria completa de entradas, saídas, perdas e ajustes manuais de produtos.',
        icon: 'mdi-dolly',
        color: 'warning',
        routeName: 'StockMovementsReport',
        permission: 'rep_stock_movements'
      }
    ]
  }
];

// 2. Filtramos dinamicamente com base nas permissões reais do usuário
const reportCategories = computed(() => {
  // Se for super admin, nem precisa filtrar
  if (userStore.isSuperAdmin) return allReportCategories;

  return allReportCategories.map(category => {
    return {
      ...category,
      // Só mantém os relatórios que o usuário possui a permissão na árvore
      reports: category.reports.filter(report => userStore.hasPermission(report.permission))
    };
  }).filter(category => category.reports.length > 0); // Se a categoria ficar vazia (ex: sem acesso financeiro), esconde ela
});

const handleReportClick = (routeName: string) => {
  if (loadingRoute.value) return;
  loadingRoute.value = routeName;

  // Pequeno delay para exibir o loading no card e fazer uma transição elegante
  setTimeout(() => {
    router.push({ name: routeName });
  }, 400);
};

onMounted(() => {
  setTimeout(() => {
    showContent.value = true;
  }, 50);
});
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
.leading-tight { line-height: 1.2 !important; }
.hover-text:hover { opacity: 1 !important; color: rgb(var(--v-theme-primary)); }

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

/* OVERLAY DE CARREGAMENTO */
.loading-overlay {
  background: inherit;
  backdrop-filter: blur(8px);
  border-radius: 20px;
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
