<template>
  <div
    class="sales-area-layout font-sans fill-height d-flex flex-column relative overflow-hidden"
    :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 text-grey-darken-4' : 'bg-glass-dark text-white'"
  >
    <div v-if="themeStore.currentMode !== 'light'" class="background-carousel-wrapper">
      <v-carousel cycle height="100%" hide-delimiters :show-arrows="false" interval="15000" class="fill-height">
        <v-carousel-item src="@/assets/1.jpg" cover></v-carousel-item>
        <v-carousel-item src="@/assets/2.jpg" cover></v-carousel-item>
        <v-carousel-item src="@/assets/3.jpg" cover></v-carousel-item>
      </v-carousel>
      <div class="background-overlay"></div>
    </div>

    <div class="content-wrapper d-flex flex-column fill-height z-10 relative">
      <Transition name="context-island-float">
        <div v-show="isContextIslandFloating" class="floating-context-island">
          <div class="floating-island-inner">
            <v-btn
              v-for="btn in tenantContextButtons"
              :key="btn.id"
              size="x-small"
              height="26"
              :variant="companyStore.context === btn.id ? 'flat' : 'text'"
              :color="companyStore.context === btn.id ? (btn.isHolding ? 'purple' : btn.color) : undefined"
              class="font-weight-black btn-context-3d floating-context-btn rounded-lg"
              :class="companyStore.context === btn.id ? 'btn-context-active' : 'btn-context-idle'"
              @click="setTenantContext(btn.id)"
            >
              {{ btn.name }}
            </v-btn>
          </div>
        </div>
      </Transition>
      <div
        class="header-bar sales-hero px-4 px-md-6 py-4 d-flex align-center justify-space-between flex-shrink-0 flex-wrap gap-3"
        :class="themeStore.currentMode === 'light' ? 'bg-white border-b border-grey-lighten-2 shadow-sm' : 'bg-glass-header border-bottom-white-05'"
      >
        <div class="d-flex flex-column">
          <div class="breadcrumb text-caption mb-1">
            <span class="opacity-70">Comercial</span>
            <span class="mx-2 opacity-50">></span>
            <span class="font-weight-bold">Área de Vendas</span>
          </div>
          <div class="text-h6 text-md-h5 font-weight-black tracking-tight leading-none mt-1">
            Gestão & Saúde de Vendas
          </div>

          <Transition name="context-dock">
            <div v-show="!isContextIslandFloating" class="context-switcher context-switcher-docked d-flex align-center flex-wrap mt-3">
              <v-btn
                v-for="btn in tenantContextButtons"
                :key="btn.id"
                size="x-small"
                height="24"
                :variant="companyStore.context === btn.id ? 'flat' : 'elevated'"
                :color="companyStore.context === btn.id ? (btn.isHolding ? 'purple' : btn.color) : undefined"
                class="font-weight-black btn-context-3d btn-context-pill px-3 rounded-lg flex-shrink-0"
                :class="companyStore.context === btn.id ? 'btn-context-active' : 'btn-context-idle'"
                @click="setTenantContext(btn.id)"
              >
                {{ btn.name }}
              </v-btn>
            </div>
          </Transition>
        </div>

        <div class="d-flex align-center flex-wrap gap-2 w-100 w-sm-auto justify-end">
          <div class="period-nav period-nav-premium d-flex align-center" :class="themeStore.currentMode === 'light' ? 'period-nav-light' : 'period-nav-dark'">
            <v-btn icon variant="text" size="small" class="icon-rect" @click="handlePeriodChange(-1)"><v-icon>mdi-chevron-left</v-icon></v-btn>
            <div class="period-label text-caption font-weight-black uppercase px-2 px-md-4" style="min-width: 140px; text-align: center;">{{ salesStore.periodLabel }}</div>
            <v-btn icon variant="text" size="small" class="icon-rect" @click="handlePeriodChange(1)"><v-icon>mdi-chevron-right</v-icon></v-btn>
          </div>
          <v-btn color="primary" variant="flat" class="btn-rect refresh-premium px-4 px-md-6 font-weight-bold" prepend-icon="mdi-refresh" @click="refreshAll" :loading="loadingAll" height="40">Atualizar</v-btn>
        </div>
      </div>

      <div class="flex-grow-1 overflow-y-auto custom-scroll px-4 px-md-6 pb-6">
        <v-row dense class="mt-4 mb-4">
          <v-col cols="12" sm="6" md="3" lg="" v-for="(kpi, idx) in dashboardKpis" :key="idx">
            <v-card class="kpi-card kpi-rect kpi-premium bg-gradient-custom py-3 px-4 hover-elevate h-100" :class="kpi.gradient" elevation="2">
              <div class="kpi-bg-icon"><v-icon>{{ kpi.icon }}</v-icon></div>
              <div class="d-flex flex-column z-10 position-relative fill-height justify-space-between">
                <div class="d-flex align-center gap-2">
                  <v-icon size="18" class="opacity-80">{{ kpi.icon }}</v-icon>
                  <span class="kpi-label uppercase">{{ kpi.label }}</span>
                </div>
                <div class="kpi-number-group my-1">
                  <span class="text-body-2 font-weight-medium mr-1 opacity-70">{{ kpi.prefix }}</span>
                  <span class="kpi-value">{{ kpi.value }}</span>
                </div>
                <div class="kpi-footer opacity-80">{{ kpi.footer }}</div>
              </div>
            </v-card>
          </v-col>

          <v-col cols="12" sm="6" md="3" lg="">
              <v-card class="kpi-card kpi-rect kpi-premium bg-gradient-purple py-3 px-4 hover-elevate h-100" elevation="2">
              <div class="kpi-bg-icon"><v-icon>mdi-cash-clock</v-icon></div>
              <div class="d-flex flex-column z-10 position-relative fill-height justify-space-between">
                <div class="d-flex align-center gap-2">
                  <v-icon size="18" class="opacity-80">mdi-cash-clock</v-icon>
                  <span class="kpi-label uppercase">{{ receivablesKpiTitle }}</span>
                </div>
                <div class="kpi-number-group my-1">
                  <span class="text-body-2 font-weight-medium mr-1 opacity-70">R$</span>
                  <span class="kpi-value">{{ formatCurrencyValue(localReceivables.pending) }}</span>
                </div>
                <div class="kpi-footer opacity-80">{{ receivablesKpiFooter }}</div>
              </div>
            </v-card>
          </v-col>
        </v-row>

        <v-row class="mb-6">
          <v-col cols="12" md="8">
            <v-card class="rounded-0 dashboard-panel-premium border-thin pa-4 h-100" :class="themeStore.currentMode === 'light' ? 'bg-white shadow-sm' : 'glass-card'">
              <div class="text-subtitle-2 font-weight-black mb-4 d-flex align-center">
                <v-icon start color="primary" class="mr-2">mdi-chart-line</v-icon> {{ chartTitle }}
              </div>
              <apexchart type="line" height="350" :options="chartOptions" :series="dashboardChartData.series"></apexchart>
            </v-card>
          </v-col>

          <v-col cols="12" md="4">
            <v-card class="rounded-0 dashboard-panel-premium border-thin h-100 d-flex flex-column" :class="themeStore.currentMode === 'light' ? 'bg-white shadow-sm' : 'glass-card'">
              <div class="pa-4 border-b d-flex align-center justify-space-between bg-white-05">
                <span class="text-subtitle-2 font-weight-black d-flex align-center">
                  <v-icon start color="amber-accent-4" class="mr-2">mdi-trophy-variant</v-icon> RANKING
                </span>
                <v-btn-toggle v-model="salesStore.rankingFilter" density="compact" mandatory color="primary" variant="outlined" class="btn-rect">
                  <v-btn value="money" size="x-small" class="btn-rect">R$</v-btn>
                  <v-btn value="area" size="x-small" class="btn-rect">{{ volumeToggleLabel }}</v-btn>
                </v-btn-toggle>
              </div>
              <div class="flex-grow-1 overflow-y-auto custom-scroll" style="max-height: 400px;">
                <div
                  v-for="(seller, index) in dashboardSellerRanking"
                  :key="seller.id"
                  class="d-flex align-center pa-3 border-b hover-action pointer"
                  @click="openSellerModal(seller)"
                >
                  <div class="rank-badge mr-4" :class="getRankClass(index)">{{ index + 1 }}</div>
                  <v-avatar size="38" class="mr-3 border" color="grey-lighten-3">
                    <v-img v-if="seller.avatar" :src="seller.avatar"></v-img>
                    <v-icon v-else color="grey">mdi-account</v-icon>
                  </v-avatar>
                  <div class="flex-grow-1">
                    <div class="text-body-2 font-weight-bold">{{ seller.name }}</div>
                    <v-progress-linear :model-value="seller.pct" :color="getRankColor(index)" height="4" rounded class="mt-1"></v-progress-linear>
                  </div>
                  <div class="text-right ml-4 font-weight-black text-body-2">
                    {{ salesStore.rankingFilter === 'money' ? salesStore.formatCurrency(seller.value) : formatVolume(seller.area) }}
                  </div>
                </div>
              </div>
            </v-card>
          </v-col>
        </v-row>

        <v-row class="mb-6">
          <v-col cols="12">
            <div class="text-subtitle-1 font-weight-black mb-3 px-1 d-flex align-center">
              <v-icon start color="primary" class="mr-2">mdi-store-clock</v-icon> {{ performanceSectionTitle }}
            </div>
          </v-col>

          <v-col
            v-for="filial in filteredStorePerformance"
            :key="filial.id"
            cols="12" sm="6" md="4" lg="3"
          >
            <v-card class="rounded-0 border-thin pa-4 hover-lift h-100" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'glass-card'">
              <div class="d-flex align-center justify-space-between mb-4">
                <div class="text-body-1 font-weight-bold">{{ filial.name }}</div>
                <v-chip size="x-small" :color="filial.performance >= 100 ? 'success' : 'warning'" variant="flat" class="font-weight-black">
                  {{ filial.performance }}% Meta
                </v-chip>
              </div>
              <div class="excel-stat-row mb-1">
                <span class="label text-uppercase font-weight-bold opacity-60" style="font-size: 10px;">Vendido</span>
                <span class="value text-primary font-weight-black text-body-2">{{ salesStore.formatCurrency(filial.total) }}</span>
              </div>
              <v-divider class="my-2 border-opacity-10"></v-divider>
              <div class="excel-stat-row">
                <span class="label text-uppercase font-weight-bold opacity-60" style="font-size: 10px;">Volume</span>
                <span class="value text-body-2">{{ formatVolume(filial.area) }}</span>
              </div>
              <v-progress-linear :model-value="filial.performance" color="primary" height="6" rounded class="mt-4"></v-progress-linear>
            </v-card>
          </v-col>

          <v-col cols="12" sm="6" md="4" lg="3" v-for="i in 2" :key="'ghost-' + i">
              <v-card class="rounded-0 border-thin pa-4 h-100 opacity-30 border-dashed" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-4' : 'bg-white-05'">
                <div class="d-flex align-center justify-center fill-height flex-column py-8">
                   <v-icon size="40" color="grey">mdi-store-plus</v-icon>
                   <div class="text-caption font-weight-black text-grey mt-3 text-uppercase">Configurar Unidade</div>
                </div>
              </v-card>
          </v-col>
        </v-row>

        <v-row>
          <v-col cols="12" lg="6">
            <v-card class="rounded-0 border-thin d-flex flex-column h-100" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'glass-card'">
              <div class="pa-4 bg-red-darken-4 text-white font-weight-black uppercase d-flex align-center justify-space-between">
                <span><v-icon start>mdi-alert-octagon</v-icon> RISCO DE CHURN (+30 DIAS)</span>
                <v-chip size="small" color="white" variant="flat" class="text-red-darken-4 font-weight-bold">{{ filteredInactiveList.length }}</v-chip>
              </div>

              <div class="pa-3 border-b d-flex gap-2 flex-wrap" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-4' : 'bg-white-05'">
                <v-text-field v-model="filters.inactiveSearch" density="compact" variant="outlined" label="Buscar cliente..." prepend-inner-icon="mdi-magnify" hide-details bg-color="white" class="btn-rect flex-grow-1"></v-text-field>
                <v-select v-model="filters.inactiveStore" :items="['Todas', ...availableStores]" density="compact" variant="outlined" label="Filial" hide-details style="max-width: 150px;" bg-color="white" class="btn-rect w-100 w-sm-auto"></v-select>
              </div>

              <div class="grid-header sticky-head bg-grey-darken-4 text-white d-none d-sm-grid" style="display: grid; grid-template-columns: 1fr 100px 80px 150px;">
                <div class="cell header-text">CLIENTE / VENDEDOR</div>
                <div class="cell center header-text">ÚLTIMA</div>
                <div class="cell center header-text">OFF</div>
                <div class="cell center header-text">AÇÕES</div>
              </div>

              <div class="flex-grow-1 overflow-y-auto custom-scroll" style="max-height: 500px;">
                <div v-for="(item, i) in paginatedInactiveList" :key="item.id" class="grid-row" :style="$vuetify.display.smAndUp ? 'display: grid; grid-template-columns: 1fr 100px 80px 150px;' : 'display: grid; grid-template-columns: 1fr 110px;'" :class="zebraClass(i)">
                  <div class="cell d-flex flex-column align-start overflow-hidden">
                    <span class="font-weight-bold text-truncate list-text">{{ item.nome || item.razao_social }}</span>
                    <span class="text-caption opacity-60">Vendedor: {{ item.last_seller }}</span>
                  </div>
                  <div class="cell center opacity-70 list-text d-none d-sm-flex">{{ formatDate(item.last_buy) }}</div>
                  <div class="cell center d-none d-sm-flex"><span class="churn-days">{{ item.days_inactive }}d</span></div>
                  <div class="cell center gap-1">
                    <v-btn icon size="small" variant="flat" color="primary" class="action-btn" @click="handlePrintOrder(item.last_order_id)" :disabled="!item.last_order_id"><v-icon>mdi-printer</v-icon></v-btn>
                    <v-btn icon size="small" variant="flat" color="success" class="action-btn" :href="`https://wa.me/55${cleanPhone(item.celular)}`" target="_blank"><v-icon>mdi-whatsapp</v-icon></v-btn>
                  </div>
                </div>
              </div>
              <v-pagination v-model="pagination.inactivePage" :length="inactiveTotalPages" density="compact" class="py-2 border-t" active-color="error"></v-pagination>
            </v-card>
          </v-col>

          <v-col cols="12" lg="6">
              <v-card class="rounded-0 border-thin d-flex flex-column h-100" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'glass-card'">
              <div class="pa-4 bg-green-darken-3 text-white font-weight-black uppercase d-flex align-center justify-space-between">
                <span><v-icon start>mdi-account-star</v-icon> NOVOS & REATIVADOS</span>
                <v-chip size="small" color="white" variant="flat" class="text-green-darken-4 font-weight-bold">{{ filteredActiveList.length }}</v-chip>
              </div>

              <div class="pa-3 border-b d-flex gap-2" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-4' : 'bg-white-05'">
                <v-text-field v-model="filters.activeSearch" density="compact" variant="outlined" label="Pesquisar ativos..." prepend-inner-icon="mdi-magnify" hide-details bg-color="white" class="btn-rect w-100"></v-text-field>
              </div>

              <div class="grid-header sticky-head bg-grey-darken-4 text-white d-none d-sm-grid" style="display: grid; grid-template-columns: 1fr 100px 100px 100px;">
                <div class="cell header-text">CLIENTE / STATUS</div>
                <div class="cell center header-text">VALOR</div>
                <div class="cell center header-text">VENDEDOR</div>
                <div class="cell center header-text">AÇÕES</div>
              </div>

              <div class="flex-grow-1 overflow-y-auto custom-scroll" style="max-height: 500px;">
                <div v-for="(item, i) in paginatedActiveList" :key="item.id" class="grid-row" :style="$vuetify.display.smAndUp ? 'display: grid; grid-template-columns: 1fr 100px 100px 100px;' : 'display: grid; grid-template-columns: 1fr 110px;'" :class="zebraClass(i)">
                  <div class="cell d-flex flex-column align-start overflow-hidden">
                    <span class="font-weight-bold text-truncate list-text">{{ item.nome }}</span>
                    <v-chip size="x-small" :color="item.type === 'Novo' ? 'blue' : 'orange'" class="mt-1 font-weight-black">{{ item.type }}</v-chip>
                  </div>
                  <div class="cell center font-weight-black text-success list-text">{{ salesStore.formatCurrency(item.val) }}</div>
                  <div class="cell center text-truncate opacity-70 list-text d-none d-sm-flex">{{ item.seller }}</div>
                  <div class="cell center gap-1">
                    <v-btn icon size="small" variant="flat" color="primary" class="action-btn" @click="handlePrintOrder(item.current_order_id)"><v-icon>mdi-printer</v-icon></v-btn>
                    <v-btn icon size="small" variant="flat" color="success" class="action-btn" :href="`https://wa.me/55${cleanPhone(item.celular)}`" target="_blank"><v-icon>mdi-whatsapp</v-icon></v-btn>
                  </div>
                </div>
              </div>
              <v-pagination v-model="pagination.activePage" :length="activeTotalPages" density="compact" class="py-2 border-t" active-color="success"></v-pagination>
            </v-card>
          </v-col>
        </v-row>

        <v-expand-transition>
          <div v-if="showLogs" class="bg-black text-green-accent-3 font-mono text-caption pa-3 mt-4 border-t overflow-auto rounded shadow-xl" style="max-height: 150px; line-height: 1.4;">
            <div class="font-weight-bold mb-1 border-b border-green-900 pb-1">> MJ_INTEGRITY_ENGINE: CROSS-REFERENCING SALES DATA</div>
            <div v-for="(log, idx) in engineLogs" :key="idx" :class="log.color">{{ log.msg }}</div>
          </div>
        </v-expand-transition>
      </div>

      <div class="flex-shrink-0 px-6 py-2 border-t bg-grey-lighten-4 d-flex justify-start">
        <div class="text-caption opacity-80 cursor-pointer d-flex align-center" @click="showLogs = !showLogs">
          <v-icon size="small" class="mr-1">{{ showLogs ? 'mdi-chevron-down' : 'mdi-chevron-up' }}</v-icon>
          Verificação de Integridade de Dados (Vendas vs Financeiro)
        </div>
      </div>
    </div>

    <v-dialog v-model="sellerModal.show" width="1200" height="90vh" persistent scrim="black">
      <v-card class="d-flex flex-column flex-md-row fill-height rounded-0 border-thin overflow-hidden">
        <div
          class="pa-6 d-flex flex-column align-center text-center transition-all bg-grey-darken-4 text-white"
          style="min-width: 300px; width: 100%; max-width: 300px;"
          :class="{'w-100 max-w-none': $vuetify.display.smAndDown}"
        >
          <v-avatar size="100" class="elevation-10 mb-4 border-lg" color="white-05">
            <v-img v-if="sellerModal.data?.avatar" :src="sellerModal.data.avatar" cover></v-img>
            <v-icon v-else size="60" color="grey">mdi-account-outline</v-icon>
          </v-avatar>
          <div class="text-h6 font-weight-black mb-1">{{ sellerModal.data?.name }}</div>
          <v-chip color="white-05" variant="flat" size="small" class="mb-6 font-weight-bold">Performance do Ciclo</v-chip>

          <v-divider class="w-100 border-opacity-25 mb-6"></v-divider>

          <div class="w-100 d-flex flex-column gap-3">
            <div class="pa-3 rounded text-left border bg-white-05">
              <div class="text-caption opacity-50 font-weight-bold">LÍQUIDO NO PERÍODO</div>
              <div class="text-h6 font-weight-black text-green-accent-4">{{ salesStore.formatCurrency(sellerModal.data?.value || 0) }}</div>
            </div>
            <div class="pa-3 rounded text-left border bg-white-05">
              <div class="text-caption opacity-50 font-weight-bold">VOLUME PRODUZIDO</div>
              <div class="text-h6 font-weight-black text-light-blue-accent-4">{{ formatVolume(sellerModal.data?.area || 0) }}</div>
            </div>
          </div>

          <v-spacer class="d-none d-md-flex"></v-spacer>

          <div class="w-100 d-flex flex-column gap-2 mt-6">
            <v-btn block color="info" variant="flat" class="btn-rect font-weight-black" size="small" prepend-icon="mdi-file-pdf-box" @click="handlePrintAllOrders" :loading="isBatchPrinting">Exportar PDFs</v-btn>
            <v-btn block color="error" variant="flat" class="btn-rect font-weight-black" size="small" @click="sellerModal.show = false">Fechar</v-btn>
          </div>
        </div>

        <div class="flex-grow-1 d-flex flex-column overflow-hidden" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-glass-dark'">
          <div class="pa-4 border-b d-flex align-center justify-space-between bg-grey-lighten-4">
             <span class="text-subtitle-1 font-weight-black text-grey-darken-4 d-flex align-center">
                <v-icon start color="primary" class="mr-2">mdi-format-list-bulleted</v-icon> PEDIDOS VINCULADOS
             </span>
             <v-btn icon="mdi-close" variant="text" size="x-small" @click="sellerModal.show = false" class="d-md-none"></v-btn>
          </div>

          <div class="grid-header bg-grey-darken-3 text-white d-none d-sm-grid" style="display: grid; grid-template-columns: 120px 1fr 120px 100px 80px;">
            <div class="cell header-text">DATA</div>
            <div class="cell header-text">CLIENTE</div>
            <div class="cell center header-text">VALOR</div>
            <div class="cell center header-text">M²</div>
            <div class="cell center header-text">AÇÕES</div>
          </div>

          <div class="flex-grow-1 overflow-y-auto custom-scroll">
            <div v-for="(order, i) in sortedSellerOrders" :key="order.id" class="grid-row" :style="$vuetify.display.smAndUp ? 'display: grid; grid-template-columns: 120px 1fr 120px 100px 80px;' : 'display: grid; grid-template-columns: 1fr 120px 60px;'" :class="zebraClass(i)">
              <div class="cell border-v font-weight-bold list-text d-none d-sm-flex">{{ formatDate(order.date) }}</div>
              <div class="cell border-v text-truncate font-weight-black list-text overflow-hidden">{{ order.client }}</div>
              <div class="cell border-v center text-success font-weight-bold list-text">{{ salesStore.formatCurrency(order.value) }}</div>
              <div class="cell border-v center list-text d-none d-sm-flex">{{ formatVolume(order.meters || 0) }}</div>
              <div class="cell center">
                <v-btn icon size="small" color="primary" variant="flat" class="action-btn" @click="handlePrintOrder(order.id)"><v-icon>mdi-printer</v-icon></v-btn>
              </div>
            </div>
          </div>
        </div>
      </v-card>
    </v-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onBeforeUnmount, watch } from 'vue';
import { useThemeStore } from '@/stores/themeStore';
import { useSalesAreaStore } from '@/stores/salesArea';
import { useCompanyStore } from '@/stores/company';
import { useAppStore } from '@/stores/app';
import { supabase } from '@/api/supabase';
import { format, parseISO, startOfMonth, endOfMonth, subDays, differenceInDays, isBefore } from 'date-fns';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';

const themeStore = useThemeStore();
const salesStore = useSalesAreaStore();
const companyStore = useCompanyStore();
const appStore = useAppStore();

const showLogs = ref(false);
const isBatchPrinting = ref(false);
const loadingAll = ref(false);
const isContextIslandFloating = ref(false);
const engineLogs = ref<any[]>([]);

const localReceivables = reactive({
  pending: 0,
  verifiedOrders: 0
});

const retailSales = ref<any[]>([]);
const retailSalesHistory = ref<any[]>([]);
const retailCustomers = ref<any[]>([]);

const normalizeText = (value: any) => String(value || '').toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '');
const safeNumber = (value: any) => Number(value || 0) || 0;

const tenantContextButtons = computed(() => {
  const companies = companyStore.availableCompanies || [];
  const companyButtons = companies.map((company: any) => {
    const name = company.trade_name || company.name || company.nome || 'Empresa';
    const normalized = normalizeText(name);
    const isRetail = normalized.includes('santos') || normalized.includes('lopes') || normalized.includes('cajuia');
    const isIndustry = normalized.includes('jacky') || normalized.includes('mr');

    return {
      id: company.id,
      name: isRetail ? 'SANTOS & LOPES' : isIndustry ? 'MR JACKY' : name,
      color: isRetail ? 'orange-darken-2' : 'green-darken-1',
      isHolding: false
    };
  });

  return [
    ...companyButtons,
    { id: 'global', name: 'HOLDING / GLOBAL', color: 'purple', isHolding: true }
  ];
});

const selectedCompany = computed(() => {
  if (companyStore.isGlobalView || companyStore.context === 'global') return null;
  return (companyStore.availableCompanies || []).find((company: any) => company.id === companyStore.context) || null;
});

const selectedCompanyName = computed(() => selectedCompany.value?.trade_name || selectedCompany.value?.name || 'Holding');
const selectedCompanyNormalized = computed(() => normalizeText(selectedCompanyName.value));
const isRetailContext = computed(() => !companyStore.isGlobalView && (selectedCompanyNormalized.value.includes('santos') || selectedCompanyNormalized.value.includes('lopes') || selectedCompanyNormalized.value.includes('cajuia')));
const isIndustryContext = computed(() => !companyStore.isGlobalView && !isRetailContext.value);
const isHoldingContext = computed(() => companyStore.isGlobalView || companyStore.context === 'global');

const setTenantContext = async (contextId: string) => {
  companyStore.setContext(contextId as any);
  await refreshAll();
};

const extractRetailUnits = (items: any) => {
  const list = Array.isArray(items) ? items : [];
  if (!list.length) return 1;

  const total = list.reduce((sum, item) => {
    const product = item?.produto || item?.product || item || {};
    const qty = product.quantidade ?? product.quantity ?? product.qtd ?? item.quantidade ?? item.quantity ?? item.qtd ?? 0;
    return sum + safeNumber(qty);
  }, 0);

  return total > 0 ? total : list.length;
};

const getRetailSaleDate = (sale: any) => sale.date_sale || sale.created_at || sale.updated_at;
const getRetailCustomerName = (sale: any) => sale.customer_name || sale.client_name || sale.entity_name || 'Consumidor Final';
const getRetailSellerName = (sale: any) => sale.seller_name || sale.creator_name || sale.created_by_name || 'Sem vendedor';
const getRetailSaleValue = (sale: any) => safeNumber(sale.total_value || sale.value || sale.total || sale.amount);
const getRetailSaleUnits = (sale: any) => extractRetailUnits(sale.items);
const getRetailSaleCompanyId = (sale: any) => sale.company_id || sale.store_id || null;
const getRetailCompanyName = (sale: any) => {
  const company = (companyStore.availableCompanies || []).find((c: any) => c.id === getRetailSaleCompanyId(sale));
  return company?.trade_name || company?.name || 'Santos & Lopes';
};

const filteredRetailSalesForContext = computed(() => {
  if (isIndustryContext.value) return [];
  if (isRetailContext.value && selectedCompany.value?.id) {
    return retailSales.value.filter(sale => getRetailSaleCompanyId(sale) === selectedCompany.value.id);
  }
  return retailSales.value;
});

const filteredRetailHistoryForContext = computed(() => {
  if (isIndustryContext.value) return [];
  if (isRetailContext.value && selectedCompany.value?.id) {
    return retailSalesHistory.value.filter(sale => getRetailSaleCompanyId(sale) === selectedCompany.value.id);
  }
  return retailSalesHistory.value;
});

const industryOrdersInPeriod = computed(() => isRetailContext.value ? [] : salesStore.ordersInPeriod);
const retailSalesInPeriod = computed(() => filteredRetailSalesForContext.value);

const currentVolumeLabel = computed(() => isRetailContext.value ? 'un' : isHoldingContext.value ? 'vol.' : 'm²');
const volumeToggleLabel = computed(() => isRetailContext.value ? 'UN' : isHoldingContext.value ? 'VOL' : 'M²');
const chartTitle = computed(() => isRetailContext.value ? 'TENDÊNCIA DE PERFORMANCE - SANTOS & LOPES' : isHoldingContext.value ? 'TENDÊNCIA DE PERFORMANCE - HOLDING' : 'TENDÊNCIA DE PERFORMANCE - MR JACKY');
const performanceSectionTitle = computed(() => isHoldingContext.value ? 'PERFORMANCE POR EMPRESA' : 'PERFORMANCE POR UNIDADE');
const receivablesKpiTitle = computed(() => isRetailContext.value ? 'Receitas do PDV' : isHoldingContext.value ? 'Receitas de Vendas' : 'Receitas de Vendas');
const receivablesKpiFooter = computed(() => isRetailContext.value ? 'Aberto no PDV / financeiro' : 'Aberto (Validado com vendas)');

const formatVolume = (value: number) => {
  const val = safeNumber(value);
  if (isRetailContext.value) return `${Math.round(val).toLocaleString('pt-BR')} un`;
  if (isHoldingContext.value) return `${val.toLocaleString('pt-BR', { maximumFractionDigits: 1 })} vol.`;
  return `${val.toLocaleString('pt-BR', { minimumFractionDigits: 1, maximumFractionDigits: 1 })} m²`;
};


// --- REFRESH CENTRALIZADO ---
const handlePeriodChange = async (dir: number) => {
  salesStore.setPeriod(dir);
  await refreshAll();
};

const refreshAll = async () => {
  loadingAll.value = true;
  engineLogs.value = [];
  try {
    await Promise.all([
      salesStore.fetchData(),
      fetchRetailData()
    ]);
    await fetchFinanceKPIs();
  } finally {
    loadingAll.value = false;
  }
};

/**
 * LÓGICA DE KPI: CRUZAMENTO DE VENDAS E RECEBÍVEIS
 * Esta função busca recebíveis em aberto que possuem um order_id associado,
 * garantindo que sejam lançamentos de vendas reais.
 */
const fetchRetailData = async () => {
  try {
    const now = salesStore.currentDate;
    const startDate = format(startOfMonth(now), 'yyyy-MM-dd');
    const endDate = format(endOfMonth(now), 'yyyy-MM-dd');

    let currentQuery = supabase
      .from('store_sales')
      .select('id, order_number, company_id, customer_name, seller_name, total_value, items, date_sale, created_at, status, financial_status')
      .gte('date_sale', startDate)
      .lte('date_sale', endDate)
      .neq('status', 'cancelled')
      .order('date_sale', { ascending: false })
      .limit(5000);

    let historyQuery = supabase
      .from('store_sales')
      .select('id, order_number, company_id, customer_name, seller_name, total_value, items, date_sale, created_at, status, financial_status')
      .neq('status', 'cancelled')
      .order('date_sale', { ascending: false })
      .limit(10000);

    if (isRetailContext.value && selectedCompany.value?.id) {
      currentQuery = currentQuery.eq('company_id', selectedCompany.value.id);
      historyQuery = historyQuery.eq('company_id', selectedCompany.value.id);
    }

    const [{ data: currentSales, error: currentError }, { data: historySales, error: historyError }] = await Promise.all([currentQuery, historyQuery]);

    if (currentError) throw currentError;
    if (historyError) throw historyError;

    retailSales.value = currentSales || [];
    retailSalesHistory.value = historySales || [];

    const customerMap = new Map<string, any>();
    (historySales || []).forEach((sale: any) => {
      const name = getRetailCustomerName(sale);
      const key = normalizeText(name);
      if (!key || key === 'consumidor final') return;
      if (!customerMap.has(key)) {
        customerMap.set(key, {
          id: key,
          nome: name,
          razao_social: name,
          celular: sale.customer_phone || sale.phone || sale.whatsapp || '',
          telefone: sale.customer_phone || sale.phone || sale.whatsapp || '',
          email: sale.customer_email || '',
          created_at: getRetailSaleDate(sale),
          store_name: getRetailCompanyName(sale)
        });
      }
    });
    retailCustomers.value = Array.from(customerMap.values());
  } catch (e: any) {
    console.error('Erro ao carregar vendas Santos & Lopes:', e);
    addEngineLog('Erro ao carregar PDV Santos & Lopes: ' + (e.message || 'erro desconhecido'), 'text-red-accent-2');
    retailSales.value = [];
    retailSalesHistory.value = [];
    retailCustomers.value = [];
  }
};

/**
 * LÓGICA DE KPI: cruza o financeiro com o contexto atual.
 * MR Jacky usa pedidos (orders). Santos & Lopes usa PDV (store_sales/store_sale_id).
 */
const fetchFinanceKPIs = async () => {
  try {
    addEngineLog('Engine: Analisando lançamentos de vendas...', 'text-white');

    const now = salesStore.currentDate;
    const startDate = format(startOfMonth(now), 'yyyy-MM-dd');
    const endDate = format(endOfMonth(now), 'yyyy-MM-dd');

    let totalPending = 0;
    let validCount = 0;

    if (!isRetailContext.value) {
      const { data, error } = await supabase
        .from('finance_receivables')
        .select('value, discount, status, order_id, customer_id')
        .not('order_id', 'is', null)
        .neq('status', 'pago')
        .gte('due_date', startDate)
        .lte('due_date', endDate);

      if (error) throw error;

      (data || []).forEach(rec => {
        totalPending += safeNumber(rec.value) - safeNumber(rec.discount);
        validCount++;
      });
    }

    if (!isIndustryContext.value) {
      let query = supabase
        .from('finance_receivables')
        .select('value, discount, status, store_sale_id, company_id')
        .not('store_sale_id', 'is', null)
        .neq('status', 'pago')
        .gte('due_date', startDate)
        .lte('due_date', endDate);

      if (isRetailContext.value && selectedCompany.value?.id) query = query.eq('company_id', selectedCompany.value.id);

      const { data, error } = await query;
      if (!error) {
        (data || []).forEach(rec => {
          totalPending += safeNumber(rec.value) - safeNumber(rec.discount);
          validCount++;
        });
      }
    }

    localReceivables.pending = totalPending;
    localReceivables.verifiedOrders = validCount;

    addEngineLog(`Integridade: ${validCount} lançamentos cruzados com sucesso.`, 'text-green-accent-3');
    addEngineLog(`Total Pendente em Vendas: ${formatCurrency(totalPending)}`, 'text-yellow-accent-1');
  } catch (e: any) {
    console.error('Integrity Engine Failure:', e);
    addEngineLog('Erro no motor de integridade: ' + (e.message || 'Erro de Schema'), 'text-red-accent-2');
  }
};

const addEngineLog = (msg: string, color: string) => {
  engineLogs.value.push({ msg: `[${new Date().toLocaleTimeString()}] ${msg}`, color });
};

// --- UTILITÁRIOS ---
const formatCurrency = (val: number) => new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(val || 0);
const formatCurrencyValue = (val: number) => new Intl.NumberFormat('pt-BR', { minimumFractionDigits: 2 }).format(val || 0);

const formatDate = (d: any) => {
  if (!d) return '-';
  try { return format(typeof d === 'string' ? parseISO(d) : new Date(d), 'dd/MM/yyyy'); }
  catch { return '-'; }
};

const cleanPhone = (p: string) => p ? p.replace(/\D/g, '') : '';

const zebraClass = (i: number) => {
  if (themeStore.currentMode !== 'light') return i % 2 === 0 ? 'zebra-dark-a' : 'zebra-dark-b';
  return i % 2 === 0 ? 'zebra-light-a' : 'zebra-light-b';
};

const getRankClass = (idx: number) => idx === 0 ? 'rank-gold' : idx === 1 ? 'rank-silver' : idx === 2 ? 'rank-bronze' : 'rank-normal';
const getRankColor = (idx: number) => idx === 0 ? '#FFD700' : idx === 1 ? '#C0C0C0' : idx === 2 ? '#CD7F32' : 'grey';

// --- FILTROS ---
const filters = reactive({ inactiveSearch: '', inactiveStore: 'Todas', activeSearch: '', activeStore: 'Todas' });
const pagination = reactive({ inactivePage: 1, activePage: 1, perPage: 20 });

const dashboardKpis = computed(() => {
  const industryRevenue = industryOrdersInPeriod.value.reduce((acc, o) => acc + safeNumber(o.total_value), 0);
  const industryVolume = industryOrdersInPeriod.value.reduce((acc, o) => acc + safeNumber(o.quantity_meters), 0);
  const industryCount = industryOrdersInPeriod.value.length;

  const retailRevenue = retailSalesInPeriod.value.reduce((acc, sale) => acc + getRetailSaleValue(sale), 0);
  const retailVolume = retailSalesInPeriod.value.reduce((acc, sale) => acc + getRetailSaleUnits(sale), 0);
  const retailCount = retailSalesInPeriod.value.length;

  const revenue = industryRevenue + retailRevenue;
  const volume = industryVolume + retailVolume;
  const count = industryCount + retailCount;
  const ticket = count > 0 ? revenue / count : 0;

  let received = 0;
  if (!isRetailContext.value) {
    received += salesStore.receivables.reduce((acc: number, r: any) => acc + safeNumber(r.paid_value), 0);
  }
  if (!isIndustryContext.value) {
    received += retailSalesInPeriod.value
      .filter((sale: any) => ['faturado', 'pago', 'quitado', 'completed'].includes(String(sale.financial_status || sale.status || '').toLowerCase()))
      .reduce((acc: number, sale: any) => acc + getRetailSaleValue(sale), 0);
  }

  return [
    {
      label: isRetailContext.value ? 'Faturamento PDV' : isHoldingContext.value ? 'Faturamento Holding' : 'Faturamento (Vendas)',
      value: formatCurrency(revenue),
      prefix: '', suffix: '',
      footer: `${count} venda(s) no período`,
      icon: 'mdi-currency-usd',
      gradient: 'bg-gradient-green'
    },
    {
      label: isRetailContext.value ? 'Peças Vendidas' : isHoldingContext.value ? 'Volume Comercial' : 'Produção (Metragem)',
      value: isRetailContext.value ? Math.round(volume).toLocaleString('pt-BR') : volume.toLocaleString('pt-BR', { maximumFractionDigits: 1 }),
      prefix: '', suffix: isRetailContext.value ? 'un' : isHoldingContext.value ? '' : 'm²',
      footer: isRetailContext.value ? 'Itens vendidos no PDV' : isHoldingContext.value ? 'Metragem + unidades vendidas' : 'Área total processada',
      icon: isRetailContext.value ? 'mdi-tshirt-crew' : 'mdi-layers-outline',
      gradient: 'bg-gradient-info'
    },
    {
      label: 'Financeiro (Recebido)',
      value: formatCurrency(received),
      prefix: '', suffix: '',
      footer: `Em aberto: ${formatCurrency(localReceivables.pending)}`,
      icon: 'mdi-cash-check',
      gradient: 'bg-gradient-purple'
    },
    {
      label: 'Ticket Médio',
      value: formatCurrency(ticket),
      prefix: '', suffix: '',
      footer: 'Por venda realizada',
      icon: 'mdi-trending-up',
      gradient: 'bg-gradient-warning'
    }
  ];
});

const dashboardSellerRanking = computed(() => {
  const map = new Map<string, any>();

  if (!isRetailContext.value) {
    salesStore.sellerRanking.forEach((seller: any) => {
      map.set(`mj-${seller.id}`, { ...seller, id: `mj-${seller.id}`, source: 'MR Jacky' });
    });
  }

  if (!isIndustryContext.value) {
    retailSalesInPeriod.value.forEach((sale: any) => {
      const sellerName = getRetailSellerName(sale);
      const key = `pdv-${normalizeText(sellerName)}`;
      const value = getRetailSaleValue(sale);
      const units = getRetailSaleUnits(sale);

      if (!map.has(key)) {
        map.set(key, { id: key, name: sellerName, avatar: null, value: 0, area: 0, count: 0, orders: [], source: 'Santos & Lopes' });
      }

      const current = map.get(key);
      current.value += value;
      current.area += units;
      current.count += 1;
      current.orders.push({
        id: `store:${sale.id}`,
        date: getRetailSaleDate(sale),
        client: getRetailCustomerName(sale),
        value,
        meters: units,
        source: 'Santos & Lopes'
      });
    });
  }

  const list = Array.from(map.values());
  const totalBase = list.reduce((acc, item) => acc + (salesStore.rankingFilter === 'money' ? item.value : item.area), 0);
  return list
    .sort((a, b) => salesStore.rankingFilter === 'money' ? b.value - a.value : b.area - a.area)
    .map(seller => ({ ...seller, pct: totalBase > 0 ? ((salesStore.rankingFilter === 'money' ? seller.value : seller.area) / totalBase) * 100 : 0 }));
});

const dashboardChartData = computed(() => {
  const labels = salesStore.chartData.labels || [];
  const moneyData = new Array(labels.length).fill(0);
  const volumeData = new Array(labels.length).fill(0);

  if (!isRetailContext.value) {
    (salesStore.chartData.series?.[0]?.data || []).forEach((v: any, i: number) => moneyData[i] += safeNumber(v));
    (salesStore.chartData.series?.[1]?.data || []).forEach((v: any, i: number) => volumeData[i] += safeNumber(v));
  }

  if (!isIndustryContext.value) {
    retailSalesInPeriod.value.forEach((sale: any) => {
      const rawDate = getRetailSaleDate(sale);
      if (!rawDate) return;
      const label = format(parseISO(String(rawDate).slice(0, 10)), 'dd/MM');
      const idx = labels.indexOf(label);
      if (idx >= 0) {
        moneyData[idx] += getRetailSaleValue(sale);
        volumeData[idx] += getRetailSaleUnits(sale);
      }
    });
  }

  return {
    labels,
    series: [
      { name: 'Vendas (R$)', type: 'column', data: moneyData.map(v => Number(v.toFixed(2))) },
      { name: isRetailContext.value ? 'Peças (un)' : isHoldingContext.value ? 'Volume' : 'Metragem (m²)', type: 'line', data: volumeData.map(v => Number(v.toFixed(2))) }
    ]
  };
});

const availableStores = computed(() => {
  const stores = new Set<string>();
  if (!isRetailContext.value) salesStore.inactiveCustomersList.forEach(i => i.store_name && stores.add(i.store_name));
  if (!isIndustryContext.value) retailCustomers.value.forEach(c => c.store_name && stores.add(c.store_name));
  return Array.from(stores).filter(s => s && !s.toUpperCase().includes('TESTE'));
});

const filteredStorePerformance = computed(() => {
  const result: any[] = [];

  if (!isRetailContext.value) {
    const industryItems = salesStore.storePerformance.filter(f => !f.name.toUpperCase().includes('TESTE'));
    if (isHoldingContext.value) {
      const total = industryItems.reduce((acc, item) => acc + safeNumber(item.total), 0);
      const area = industryItems.reduce((acc, item) => acc + safeNumber(item.area), 0);
      if (total || area) result.push({ id: 'mr-jacky', name: 'MR Jacky', total, area, performance: Math.min((total / 50000) * 100, 100).toFixed(0) });
    } else {
      result.push(...industryItems);
    }
  }

  if (!isIndustryContext.value) {
    const grouped = new Map<string, any>();
    retailSalesInPeriod.value.forEach((sale: any) => {
      const id = getRetailSaleCompanyId(sale) || 'santos-lopes';
      const name = getRetailCompanyName(sale);
      if (!grouped.has(id)) grouped.set(id, { id, name, total: 0, area: 0, count: 0 });
      const current = grouped.get(id);
      current.total += getRetailSaleValue(sale);
      current.area += getRetailSaleUnits(sale);
      current.count += 1;
    });

    grouped.forEach(item => {
      result.push({ ...item, avg: item.count ? item.total / item.count : 0, performance: Math.min((item.total / 50000) * 100, 100).toFixed(0) });
    });
  }

  return result;
});

const dashboardInactiveCustomersList = computed(() => {
  const list: any[] = [];
  if (!isRetailContext.value) list.push(...salesStore.inactiveCustomersList);

  if (!isIndustryContext.value) {
    const lastBuyMap = new Map<string, any>();
    filteredRetailHistoryForContext.value.forEach((sale: any) => {
      const name = getRetailCustomerName(sale);
      const key = normalizeText(name);
      if (!key || key === 'consumidor final') return;
      const date = new Date(getRetailSaleDate(sale));
      const existing = lastBuyMap.get(key);
      if (!existing || date > existing.date) {
        lastBuyMap.set(key, { date, sale, name });
      }
    });

    const inactiveLimit = subDays(new Date(), 30);
    lastBuyMap.forEach(({ date, sale, name }, key) => {
      if (isBefore(date, inactiveLimit)) {
        list.push({
          id: `pdv-${key}`,
          nome: name,
          razao_social: name,
          celular: sale.customer_phone || sale.phone || '',
          store_name: getRetailCompanyName(sale),
          last_buy: date,
          last_order_id: `store:${sale.id}`,
          days_inactive: differenceInDays(new Date(), date),
          last_seller: getRetailSellerName(sale),
          source: 'Santos & Lopes'
        });
      }
    });
  }

  return list.sort((a, b) => new Date(b.last_buy).getTime() - new Date(a.last_buy).getTime());
});

const dashboardActiveNewsList = computed(() => {
  const list: any[] = [];
  if (!isRetailContext.value) list.push(...salesStore.activeNewsList);

  if (!isIndustryContext.value) {
    const processed = new Set<string>();
    retailSalesInPeriod.value.forEach((sale: any) => {
      const name = getRetailCustomerName(sale);
      const key = normalizeText(name);
      if (!key || processed.has(key) || key === 'consumidor final') return;
      processed.add(key);

      const hasPrevious = filteredRetailHistoryForContext.value.some((history: any) => normalizeText(getRetailCustomerName(history)) === key && new Date(getRetailSaleDate(history)) < salesStore.periodStart);
      list.push({
        id: `pdv-${key}`,
        nome: name,
        type: hasPrevious ? 'Reativado' : 'Novo',
        seller: getRetailSellerName(sale),
        val: getRetailSaleValue(sale),
        current_order_id: `store:${sale.id}`,
        current_order_date: getRetailSaleDate(sale),
        whatsapp: sale.customer_phone || sale.phone || '',
        celular: sale.customer_phone || sale.phone || ''
      });
    });
  }

  return list.sort((a, b) => new Date(b.current_order_date).getTime() - new Date(a.current_order_date).getTime());
});

const filteredInactiveList = computed(() => {
  let list = [...dashboardInactiveCustomersList.value];
  const search = filters.inactiveSearch.toLowerCase();
  return list.filter(i => {
    const ms = !search || i.nome?.toLowerCase().includes(search) || i.last_seller?.toLowerCase().includes(search);
    const mst = filters.inactiveStore === 'Todas' || i.store_name === filters.inactiveStore;
    return ms && mst;
  });
});

const filteredActiveList = computed(() => {
  let list = [...dashboardActiveNewsList.value];
  const search = filters.activeSearch.toLowerCase();
  return list.filter(i => !search || i.nome?.toLowerCase().includes(search) || i.seller?.toLowerCase().includes(search));
});

const paginatedInactiveList = computed(() => {
  const start = (pagination.inactivePage - 1) * pagination.perPage;
  return filteredInactiveList.value.slice(start, start + pagination.perPage);
});

const paginatedActiveList = computed(() => {
  const start = (pagination.activePage - 1) * pagination.perPage;
  return filteredActiveList.value.slice(start, start + pagination.perPage);
});

const inactiveTotalPages = computed(() => Math.max(1, Math.ceil(filteredInactiveList.value.length / pagination.perPage)));
const activeTotalPages = computed(() => Math.max(1, Math.ceil(filteredActiveList.value.length / pagination.perPage)));

// --- MODAL VENDEDOR ---
const sellerModal = reactive({ show: false, data: null as any });
const sortedSellerOrders = computed(() => {
  if (!sellerModal.data?.orders) return [];
  return [...sellerModal.data.orders].sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime());
});
const openSellerModal = (seller: any) => { sellerModal.data = seller; sellerModal.show = true; };

// --- IMPRESSÃO ---
const handlePrintOrder = async (orderId: any) => {
  if (!orderId) { appStore.showSnackbar('Pedido não vinculado.', 'error'); return; }
  try {
    const money = (val: number) => new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(Number(val || 0));

    if (String(orderId).startsWith('store:')) {
      const saleId = String(orderId).replace('store:', '');
      const { data: sale, error } = await supabase
        .from('store_sales')
        .select('*')
        .eq('id', saleId)
        .maybeSingle();

      if (error) throw error;
      if (!sale) return;

      const doc = new jsPDF();
      doc.setFont('helvetica', 'bold').setFontSize(14);
      doc.text('SANTOS & LOPES - DOCUMENTO DE VENDA', 10, 20);
      doc.setFontSize(10).text(`N°: ${sale.order_number || sale.id}`, 190, 20, { align: 'right' });
      doc.line(10, 25, 200, 25);
      doc.text(`Cliente: ${getRetailCustomerName(sale)}`, 10, 35);
      doc.text(`Vendedor: ${getRetailSellerName(sale)}`, 10, 41);
      doc.text(`Data: ${formatDate(getRetailSaleDate(sale))}`, 10, 47);

      const rows = (Array.isArray(sale.items) ? sale.items : []).map((item: any) => {
        const product = item?.produto || item?.product || item || {};
        const name = product.nome_produto || product.descricao || product.nome || product.name || 'Item';
        const qty = product.quantidade ?? product.quantity ?? product.qtd ?? item.quantidade ?? item.quantity ?? item.qtd ?? 1;
        const total = product.valor_total ?? product.total ?? product.total_value ?? item.valor_total ?? item.total ?? item.total_value ?? 0;
        return [name, String(qty), money(total)];
      });

      autoTable(doc, { startY: 55, head: [['ITEM', 'QTD', 'TOTAL']], body: rows.length ? rows : [['Venda sem itens detalhados', '-', money(getRetailSaleValue(sale))]] });
      doc.save(`PDV_${sale.order_number || sale.id}.pdf`);
      return;
    }

    const [ { data: order }, { data: items } ] = await Promise.all([
      supabase.from('orders').select('*, creator:created_by(full_name)').eq('id', orderId).maybeSingle(),
      supabase.from('order_items').select('*').eq('order_id', orderId)
    ]);
    if (!order) return;

    const doc = new jsPDF();
    doc.setFont('helvetica', 'bold').setFontSize(14);
    doc.text('MR JACKY - DOCUMENTO DE VENDA', 10, 20);
    doc.setFontSize(10).text(`N°: ${order.order_number}`, 190, 20, { align: 'right' });
    doc.line(10, 25, 200, 25);
    doc.text(`Cliente: ${order.customer_name}`, 10, 35);
    const pBody = (items || []).map(it => [it.fabric_type, it.stamp_ref, `${it.quantity_meters}m`, money(it.total_value_items)]);
    autoTable(doc, { startY: 45, head: [['BASE', 'REF', 'QTD', 'TOTAL']], body: pBody });
    doc.save(`Pedido_${order.order_number}.pdf`);
  } catch (e) { console.error(e); }
};

const handlePrintAllOrders = async () => {
  const orders = sortedSellerOrders.value;
  if (!orders.length) return;
  isBatchPrinting.value = true;
  try {
      for (const o of orders) {
          await handlePrintOrder(o.id);
          await new Promise(r => setTimeout(r, 400));
      }
  } finally { isBatchPrinting.value = false; }
};

// --- GRÁFICO ---
const chartOptions = computed(() => ({
  chart: { toolbar: { show: false }, background: 'transparent', foreColor: themeStore.currentMode === 'light' ? '#333' : '#fff' },
  stroke: { curve: 'smooth', width: 4 },
  colors: ['#2E7D32', '#0288D1'],
  labels: dashboardChartData.labels,
  xaxis: { axisBorder: { show: false } },
  yaxis: [{ title: { text: 'Financeiro (R$)' } }, { opposite: true, title: { text: isRetailContext.value ? 'Peças (un)' : isHoldingContext.value ? 'Volume' : 'M²' } }],
  grid: { borderColor: 'rgba(128,128,128,0.1)', strokeDashArray: 5 },
  legend: { position: 'top', horizontalAlign: 'right' }
}));

const handleContextIslandScroll = () => {
  isContextIslandFloating.value = window.scrollY > 120;
};

onMounted(async () => {
  handleContextIslandScroll();
  window.addEventListener('scroll', handleContextIslandScroll, { passive: true });
  if (!companyStore.availableCompanies?.length) {
    await companyStore.initialize?.();
  }
  await refreshAll();
});

watch(() => companyStore.context, () => {
  refreshAll();
});


onBeforeUnmount(() => {
  window.removeEventListener('scroll', handleContextIslandScroll);
});

</script>

<style scoped lang="scss">
.sales-area-layout { position: relative; }
.background-carousel-wrapper { position: absolute; inset: 0; z-index: 0; opacity: 0.5; pointer-events: none; }
.background-overlay { position: absolute; inset: 0; background: radial-gradient(circle, transparent, #000); backdrop-filter: blur(5px); }

.bg-glass-dark { background: rgba(10,10,12,0.85); }
.bg-glass-header { background: rgba(20,20,24,0.55); backdrop-filter: blur(14px); }
.border-bottom-white-05 { border-bottom: 1px solid rgba(255,255,255,0.08); }
.border-thin { border: 1px solid rgba(0,0,0,0.08); }

.btn-rect { border-radius: 0 !important; text-transform: none !important; font-weight: 800; }
.icon-rect { border-radius: 0 !important; }

.controls-light { background: #ffffff; }
.controls-dark { background: rgba(30,30,35,0.55); backdrop-filter: blur(16px); border: 1px solid rgba(255,255,255,0.08); }

.period-nav { border-radius: 0; height: 40px; overflow: hidden; border: 1px solid rgba(0,0,0,0.12); }
.period-nav-light { background: #fafafa; }
.period-nav-dark { border: 1px solid rgba(255,255,255,0.10); background: rgba(255,255,255,0.06); }

.grid-header, .grid-row { display: grid; align-items: stretch; width: 100%; border-bottom: 1px solid rgba(0,0,0,0.08); }
.cell { padding: 8px 12px; display: flex; align-items: center; border-right: 1px solid rgba(0,0,0,0.04); min-height: 48px; overflow: hidden; }
.header-text { font-size: 11px; font-weight: 900; text-transform: uppercase; letter-spacing: 0.5px; }
.list-text { font-size: 13px !important; }

.grid-surface-light { background: #f5f7fa; color: rgba(0,0,0,0.7); }
.grid-row-light:hover { background: #f7fafc !important; }
.zebra-light-a { background: #ffffff; }
.zebra-light-b { background: #fafafa; }
.zebra-dark-a { background: rgba(255,255,255,0.02); }
.zebra-dark-b { background: rgba(255,255,255,0.05); }

.rank-badge {
  width: 26px; height: 26px; border-radius: 6px;
  display: flex; align-items: center; justify-content: center;
  font-size: 11px; font-weight: 900; color: white;
}
.rank-gold { background: linear-gradient(135deg, #FFD700, #DAA520); }
.rank-silver { background: linear-gradient(135deg, #C0C0C0, #A9A9A9); }
.rank-bronze { background: linear-gradient(135deg, #CD7F32, #8B4513); }
.rank-normal { background: #455A64; }

.kpi-card { position: relative; overflow: hidden; color: white; transition: transform 0.3s; &:hover { transform: translateY(-3px); } }
.kpi-rect { border-radius: 0 !important; }
.kpi-bg-icon { position: absolute; right: -10px; bottom: -10px; opacity: 0.15; font-size: 60px; transform: rotate(-15deg); }
.kpi-label { font-size: 10px; font-weight: 900; letter-spacing: 1px; }
.kpi-value { font-size: 22px; font-weight: 900; }
.kpi-footer { font-size: 10px; font-weight: 700; }

.bg-gradient-green { background: linear-gradient(135deg, #1b5e20, #43a047); }
.bg-gradient-info { background: linear-gradient(135deg, #01579b, #0288d1); }
.bg-gradient-purple { background: linear-gradient(135deg, #4527a0, #673ab7); }
.bg-gradient-warning { background: linear-gradient(135deg, #e65100, #ff9800); }

.excel-stat-row { display: flex; justify-content: space-between; align-items: center; }
.churn-days { background: #ffebee; color: #c62828; padding: 2px 8px; border-radius: 10px; font-weight: 900; font-size: 10px; }
.pointer { cursor: pointer; }
.action-btn { width: 32px !important; height: 32px !important; border-radius: 4px !important; }
.glass-card { background: rgba(30, 30, 35, 0.45); backdrop-filter: blur(25px); border: 1px solid rgba(255,255,255,0.08); }



.btn-context-3d {
  min-width: 112px;
  box-shadow: 0 2px 0 rgba(0,0,0,.12), 0 8px 16px rgba(15,23,42,.12) !important;
  transition: transform .16s ease, box-shadow .16s ease, opacity .16s ease;
}
.btn-context-3d:hover { transform: translateY(-1px); }
.btn-context-active { color: #fff !important; }
.btn-context-idle { background: rgba(255,255,255,.86) !important; color: #475569 !important; }
.context-switcher { max-width: min(900px, calc(100vw - 48px)); overflow-x: auto; scrollbar-width: none; }
.context-switcher::-webkit-scrollbar { display: none; }

@media (max-width: 600px) {
  .period-nav { width: 100%; justify-content: space-between; }
  .grid-header { display: none !important; }
  .grid-row { border: 1px solid rgba(0,0,0,0.1); margin-bottom: 8px; border-radius: 4px; padding: 8px; }
  .cell { border-right: none; min-height: auto; padding: 4px; }
}

/* ===== Refinamento visual SalesArea: padrão SuperAdminDashboard ===== */
.sales-hero {
  position: relative;
  margin: 12px 16px 0;
  border-radius: 22px !important;
  overflow: visible !important;
  border: 1px solid rgba(148, 163, 184, 0.18) !important;
  background:
    radial-gradient(circle at 92% 18%, rgba(34,197,94,0.16), transparent 28%),
    radial-gradient(circle at 8% 12%, rgba(59,130,246,0.12), transparent 30%),
    linear-gradient(135deg, rgba(255,255,255,0.96) 0%, rgba(248,250,252,0.98) 52%, rgba(236,253,245,0.86) 100%) !important;
  box-shadow:
    0 18px 42px rgba(15, 23, 42, 0.08),
    inset 0 1px 0 rgba(255,255,255,0.92) !important;
}

.bg-glass-header.sales-hero {
  background:
    radial-gradient(circle at 92% 18%, rgba(34,197,94,0.18), transparent 28%),
    radial-gradient(circle at 8% 12%, rgba(59,130,246,0.14), transparent 30%),
    linear-gradient(135deg, rgba(15,23,42,0.86) 0%, rgba(30,41,59,0.80) 100%) !important;
  border-color: rgba(255,255,255,0.09) !important;
}

.sales-hero .breadcrumb {
  font-size: 10px;
  font-weight: 900;
  letter-spacing: .08em;
  text-transform: uppercase;
  color: #64748b;
}

.sales-hero .text-h6,
.sales-hero .text-md-h5 {
  letter-spacing: -0.04em;
}

/* Botões de contexto mais bonitos, separados e 3D sutil */
.context-switcher-premium {
  width: fit-content;
  max-width: min(980px, calc(100vw - 48px));
  padding: 7px;
  gap: 8px;
  border-radius: 18px;
  background: rgba(255,255,255,0.80);
  border: 1px solid rgba(148, 163, 184, 0.22);
  box-shadow:
    0 12px 26px rgba(15, 23, 42, 0.10),
    inset 0 1px 0 rgba(255,255,255,0.88);
  backdrop-filter: blur(14px);
  overflow-x: auto;
  overflow-y: hidden;
  scrollbar-width: none;
}

.bg-glass-header .context-switcher-premium {
  background: rgba(15, 23, 42, 0.58);
  border-color: rgba(255,255,255,0.12);
}

.context-switcher-premium::-webkit-scrollbar,
.context-buttons-row::-webkit-scrollbar {
  display: none;
}

.context-switcher-label {
  align-items: center;
  gap: 5px;
  height: 30px;
  padding: 0 9px;
  border-right: 1px solid rgba(148, 163, 184, 0.20);
  color: #64748b;
  font-size: 10px;
  font-weight: 900;
  text-transform: uppercase;
  letter-spacing: .08em;
  white-space: nowrap;
}

.context-buttons-row {
  display: flex;
  align-items: center;
  gap: 8px;
  overflow-x: auto;
  scrollbar-width: none;
}

.btn-context-pill {
  min-width: 118px !important;
  height: 30px !important;
  padding-inline: 14px !important;
  border-radius: 11px !important;
  font-size: 9.5px !important;
  letter-spacing: .055em !important;
  text-transform: uppercase !important;
}

.btn-context-3d {
  box-shadow: none !important;
  transition:
    transform .16s ease,
    box-shadow .16s ease,
    background .16s ease,
    color .16s ease,
    filter .16s ease;
}

.btn-context-3d:hover {
  transform: translateY(-1px);
  filter: saturate(1.05);
}

.btn-context-3d:active {
  transform: translateY(1px);
}

.btn-context-active {
  color: #fff !important;
  box-shadow:
    0 2px 0 rgba(0,0,0,.20),
    0 10px 20px rgba(15,23,42,.16) !important;
}

.btn-context-idle {
  color: #475569 !important;
  background: rgba(248,250,252,.78) !important;
  border: 1px solid rgba(148,163,184,.16) !important;
  box-shadow:
    0 2px 0 rgba(15,23,42,.06),
    0 8px 16px rgba(15,23,42,.05) !important;
}

.bg-glass-header .btn-context-idle {
  color: rgba(255,255,255,.82) !important;
  background: rgba(255,255,255,.08) !important;
  border-color: rgba(255,255,255,.12) !important;
}

/* Navegação do período e botão Atualizar */
.period-nav-premium {
  border-radius: 14px !important;
  height: 42px !important;
  padding: 3px;
  overflow: hidden;
  box-shadow:
    0 8px 18px rgba(15,23,42,.08),
    inset 0 1px 0 rgba(255,255,255,.80);
}

.period-nav-light {
  background: rgba(255,255,255,.86) !important;
  border-color: rgba(148,163,184,.22) !important;
}

.period-nav-dark {
  background: rgba(255,255,255,.08) !important;
  border-color: rgba(255,255,255,.12) !important;
}

.icon-rect {
  border-radius: 10px !important;
}

.period-label {
  color: #334155;
  letter-spacing: .03em;
}

.bg-glass-header .period-label {
  color: rgba(255,255,255,.86);
}

.refresh-premium {
  border-radius: 13px !important;
  box-shadow:
    0 2px 0 rgba(0,0,0,.16),
    0 10px 20px rgba(37,99,235,.18) !important;
}

/* Cards e painéis menos quadrados, mais dashboard */
.kpi-rect {
  border-radius: 18px !important;
}

.kpi-premium {
  min-height: 126px;
  border: 1px solid rgba(255,255,255,.22);
  box-shadow:
    0 16px 28px rgba(15,23,42,.13),
    inset 0 1px 0 rgba(255,255,255,.18) !important;
}

.kpi-card:hover {
  transform: translateY(-4px);
  box-shadow:
    0 20px 38px rgba(15,23,42,.17),
    inset 0 1px 0 rgba(255,255,255,.22) !important;
}

.dashboard-panel-premium {
  border-radius: 22px !important;
  border-color: rgba(148,163,184,.18) !important;
  box-shadow:
    0 16px 34px rgba(15,23,42,.07),
    inset 0 1px 0 rgba(255,255,255,.74) !important;
  overflow: hidden;
}

.dashboard-panel-premium :deep(.v-card),
.dashboard-panel-premium {
  background-clip: padding-box;
}

.sales-area-layout .rounded-0 {
  border-radius: 22px !important;
}

.rank-badge {
  border-radius: 999px !important;
  box-shadow:
    0 2px 0 rgba(0,0,0,.12),
    0 8px 14px rgba(15,23,42,.10);
}

.action-btn {
  border-radius: 10px !important;
  box-shadow:
    0 2px 0 rgba(0,0,0,.12),
    0 8px 14px rgba(15,23,42,.12) !important;
}

@media (max-width: 960px) {
  .sales-hero {
    margin: 10px 10px 0;
    border-radius: 18px !important;
  }

  .context-switcher-premium {
    width: 100%;
    max-width: 100%;
  }

  .context-buttons-row {
    width: 100%;
  }

  .btn-context-pill {
    min-width: 108px !important;
    font-size: 8.5px !important;
    padding-inline: 10px !important;
  }
}

@media (max-width: 600px) {
  .period-nav-premium {
    width: 100%;
    justify-content: space-between;
  }

  .refresh-premium {
    width: 100%;
  }

  .sales-hero {
    align-items: stretch !important;
  }
}


/* ===== Contexto no padrão AdminMjReceivables: sem background cortando botões ===== */
.context-switcher-premium,
.context-switcher-docked {
  width: auto !important;
  max-width: 100% !important;
  padding: 0 !important;
  gap: 9px !important;
  border-radius: 0 !important;
  background: transparent !important;
  border: none !important;
  box-shadow: none !important;
  backdrop-filter: none !important;
  overflow: visible !important;
}

.context-buttons-row,
.context-switcher-label {
  display: none !important;
}

.btn-context-pill {
  min-width: 96px !important;
  height: 24px !important;
  padding-inline: 12px !important;
  border-radius: 8px !important;
  font-size: 8.5px !important;
  letter-spacing: .06em !important;
  text-transform: uppercase !important;
}

.btn-context-3d {
  transition:
    transform .16s ease,
    box-shadow .16s ease,
    background .16s ease,
    color .16s ease,
    filter .16s ease;
}

.btn-context-3d:hover {
  transform: translateY(-1px);
}

.btn-context-3d:active {
  transform: translateY(1px);
}

.btn-context-active {
  color: #fff !important;
  box-shadow:
    0 2px 0 rgba(0,0,0,.18),
    0 8px 16px rgba(15,23,42,.18) !important;
}

.btn-context-idle {
  color: #64748b !important;
  background: rgba(255,255,255,.88) !important;
  border: 1px solid rgba(148,163,184,.20) !important;
  box-shadow:
    0 2px 0 rgba(15,23,42,.07),
    0 8px 14px rgba(15,23,42,.08) !important;
}

.bg-glass-header .btn-context-idle {
  color: rgba(255,255,255,.82) !important;
  background: rgba(255,255,255,.08) !important;
  border-color: rgba(255,255,255,.12) !important;
}

/* Dock/re-dock animation in header */
.context-switcher-docked {
  transform-origin: top left;
  will-change: opacity, transform, filter;
}

.context-dock-enter-active,
.context-dock-leave-active {
  transition: opacity .28s ease, transform .34s cubic-bezier(.2,.9,.25,1), filter .28s ease;
}

.context-dock-enter-from,
.context-dock-leave-to {
  opacity: 0;
  transform: translateY(-8px) scale(.96);
  filter: blur(4px);
}

.context-dock-enter-to,
.context-dock-leave-from {
  opacity: 1;
  transform: translateY(0) scale(1);
  filter: blur(0);
}

/* Ilha flutuante ao rolar igual ao SuperAdminDashboard */
.floating-context-island {
  position: fixed;
  top: 18px;
  left: 50%;
  transform: translateX(-50%);
  z-index: 50;
  pointer-events: auto;
  animation: islandSoftHover 5.8s ease-in-out infinite .6s;
}

.floating-context-island::before {
  content: '';
  position: absolute;
  inset: -10px;
  pointer-events: none;
  border-radius: 26px;
  background: radial-gradient(circle at 50% 50%, rgba(59,130,246,0.13), transparent 62%);
  opacity: .75;
  animation: islandGlow 3.6s ease-in-out infinite;
}

.floating-island-inner {
  position: relative;
  z-index: 2;
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 7px;
  border-radius: 18px;
  background: rgba(255,255,255,.88);
  border: 1px solid rgba(148,163,184,.22);
  box-shadow:
    0 18px 38px rgba(15,23,42,.16),
    inset 0 1px 0 rgba(255,255,255,.90);
  backdrop-filter: blur(16px);
}

.floating-context-btn {
  min-width: 94px !important;
  height: 26px !important;
  padding-inline: 11px !important;
  border-radius: 9px !important;
  font-size: 8.5px !important;
  letter-spacing: .055em !important;
}

.context-island-float-enter-active {
  transition:
    opacity .38s ease,
    transform .52s cubic-bezier(.18, 1.15, .28, 1),
    filter .34s ease;
}

.context-island-float-leave-active {
  transition:
    opacity .30s ease,
    transform .42s cubic-bezier(.22, .8, .28, 1),
    filter .28s ease;
}

.context-island-float-enter-from {
  opacity: 0;
  transform: translateX(-50%) translateY(-42px) scale(.82);
  filter: blur(10px);
}

.context-island-float-enter-to {
  opacity: 1;
  transform: translateX(-50%) translateY(0) scale(1);
  filter: blur(0);
}

.context-island-float-leave-from {
  opacity: 1;
  transform: translateX(-50%) translateY(0) scale(1);
  filter: blur(0);
}

.context-island-float-leave-to {
  opacity: 0;
  transform: translateX(-50%) translateY(-34px) scale(.88);
  filter: blur(9px);
}

@keyframes islandSoftHover {
  0%, 100% { margin-top: 0; }
  50% { margin-top: -2px; }
}

@keyframes islandGlow {
  0%, 100% {
    opacity: .45;
    transform: scale(.96);
  }
  50% {
    opacity: .78;
    transform: scale(1.02);
  }
}

@media (max-width: 960px) {
  .context-switcher-docked {
    gap: 7px !important;
    overflow-x: auto !important;
    flex-wrap: nowrap !important;
    scrollbar-width: none;
  }

  .context-switcher-docked::-webkit-scrollbar {
    display: none;
  }

  .btn-context-pill,
  .floating-context-btn {
    min-width: 86px !important;
    font-size: 7.8px !important;
    padding-inline: 8px !important;
  }

  .floating-context-island {
    top: auto;
    bottom: 18px;
    max-width: calc(100vw - 20px);
  }

  .floating-context-island::before {
    display: none;
  }

  .floating-island-inner {
    max-width: calc(100vw - 20px);
    overflow-x: auto;
    scrollbar-width: none;
  }

  .floating-island-inner::-webkit-scrollbar {
    display: none;
  }
}

</style>
