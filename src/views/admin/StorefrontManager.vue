<template>
  <div
    class="storefront-layout font-sans fill-height d-flex flex-column relative overflow-hidden"
    :class="isLightMode ? 'bg-grey-lighten-5 text-grey-darken-4' : 'bg-glass-dark text-white'"
  >
    <div v-if="!isLightMode" class="background-carousel-wrapper">
      <v-carousel cycle height="100%" hide-delimiters :show-arrows="false" interval="15000" class="fill-height">
        <v-carousel-item src="@/assets/1.jpg" cover></v-carousel-item>
        <v-carousel-item src="@/assets/2.jpg" cover></v-carousel-item>
        <v-carousel-item src="@/assets/3.jpg" cover></v-carousel-item>
      </v-carousel>
      <div class="background-overlay"></div>
    </div>

    <div class="content-wrapper d-flex flex-column flex-grow-1 z-10 relative">

      <div
        v-if="!['builder', 'leads_kanban'].includes(activeTab)"
        class="header-bar px-6 py-4 d-flex flex-column flex-md-row align-md-center justify-space-between flex-shrink-0 relative"
        :class="isLightMode ? 'bg-white border-b border-grey-lighten-2 shadow-sm' : 'bg-glass-header border-bottom-white-05'"
      >
        <div class="d-flex flex-column">
          <div class="breadcrumb text-caption">
            <span class="opacity-70">MJ Process</span>
            <span class="mx-2 opacity-50">></span>
            <span class="font-weight-bold">Marketplace B2B</span>
          </div>
          <div class="text-h6 font-weight-black tracking-tight leading-none mt-1" :class="isLightMode ? 'text-grey-darken-4' : 'text-white'">
            {{ getTabTitle(activeTab) }}
          </div>
        </div>

        <div class="d-flex align-center mt-4 mt-md-0" style="gap: 10px;">
          <div
            class="status-chip border rounded d-none d-sm-flex align-center gap-2 text-caption font-weight-bold px-3"
            style="height: 40px;"
            :class="isLightMode ? 'bg-grey-lighten-4 border-grey-lighten-2 text-grey-darken-3' : 'bg-surface-card border-white-10 text-white'"
          >
            <span class="status-dot pulsing-dot" :class="isLoading ? 'bg-warning' : 'bg-success'"></span>
            {{ isLoading ? 'Sincronizando' : 'Online e Sincronizado' }}
          </div>

          <v-btn
            v-if="['stamps', 'categories', 'mockups', 'themes', 'fabrics'].includes(activeTab)"
            color="primary"
            variant="flat"
            class="btn-rect btn-3d text-none font-weight-bold"
            height="40"
            :prepend-icon="['themes'].includes(activeTab) ? 'mdi-content-save-all' : 'mdi-plus-box-multiple'"
            @click="triggerChildAction"
            :loading="isLoading"
          >
            {{ ['themes'].includes(activeTab) ? 'Gravar Tema' : 'Novo Cadastro' }}
          </v-btn>
        </div>
      </div>

      <div
        class="flex-grow-1 overflow-hidden d-flex flex-column relative"
        :class="['builder', 'leads_kanban'].includes(activeTab) ? 'pa-0' : 'pa-4 pa-md-6'"
      >
        <div v-if="isLoading && ['builder', 'leads_kanban'].includes(activeTab)" class="d-flex flex-column align-center justify-center py-16 fill-height">
          <v-progress-circular indeterminate color="primary" size="64" width="6" class="mb-4" />
          <p class="opacity-70 font-weight-medium text-caption">Carregando módulos do Marketplace...</p>
        </div>

        <div v-else class="d-flex flex-column h-100 w-100 custom-scroll overflow-y-auto overflow-x-hidden">
          <BuilderTab v-if="activeTab === 'builder'" ref="activeTabRef" :categories="categories" :stamps="stamps" :mockups="mockups" @refresh="loadRealData" />
          <ThemeEditorTab v-else-if="activeTab === 'themes'" ref="activeTabRef" :storeSettings="storeSettings" :categories="categories" :stamps="stamps" :pendingAccountLeads="pendingAccountLeads" :pendingDesignLeads="pendingDesignLeads" @refresh="loadRealData" />
          <StampsTab v-else-if="activeTab === 'stamps'" ref="activeTabRef" :stamps="stamps" :categories="categories" @refresh="loadRealData" />
          <CategoriesTab v-else-if="activeTab === 'categories'" ref="activeTabRef" :categories="categories" :stamps="stamps" @refresh="loadRealData" />
          <FabricsTab v-else-if="activeTab === 'fabrics'" ref="activeTabRef" :fabrics="fabrics" @refresh="loadRealData" />
          <MockupsTab v-else-if="activeTab === 'mockups'" ref="activeTabRef" :mockups="mockups" :categories="categories" @refresh="loadRealData" />
          <AccountApprovalsTab v-else-if="activeTab === 'account_approvals'" ref="activeTabRef" :leads="leads" @refresh="loadRealData" />
          <LeadsTab v-else-if="activeTab === 'leads'" ref="activeTabRef" :leads="leads" @refresh="loadRealData" />
          <LeadsKanbanTab v-else-if="activeTab === 'leads_kanban'" ref="activeTabRef" :leads="leads" @refresh="loadRealData" />
          <DesignClientsTab v-else-if="activeTab === 'design_clients'" ref="activeTabRef" :leads="leads" :vaultedDeliveries="vaultedDeliveries" @refresh="loadRealData" />
        </div>
      </div>

    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, computed, watch } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { supabase } from '@/api/supabase'
import { useThemeStore } from '@/stores/theme'

import BuilderTab from './storefront/BuilderTab.vue'
import ThemeEditorTab from './storefront/ThemeEditorTab.vue'
import StampsTab from './storefront/StampsTab.vue'
import CategoriesTab from './storefront/CategoriesTab.vue'
import FabricsTab from './storefront/FabricsTab.vue'
import MockupsTab from './storefront/MockupsTab.vue'
import AccountApprovalsTab from './storefront/AccountApprovalsTab.vue'
import LeadsTab from './storefront/LeadsTab.vue'
import LeadsKanbanTab from './storefront/LeadsKanbanTab.vue'
import DesignClientsTab from './storefront/DesignClientsTab.vue'

const themeStore = useThemeStore()
const isLightMode = computed(() => themeStore.currentMode === 'light')

const router = useRouter()
const route = useRoute()

// A Aba é controlada pela URL (?tab=...) injetada pelo default.vue
const activeTab = ref(route.query.tab as string || 'builder')
const activeTabRef = ref<any>(null)
const isLoading = ref(true)

const storeSettings = ref<any>({
  id: null, hero_title: '', hero_subtitle: '', hero_bg_url: '',
  parallax_title: '', parallax_text: '', parallax_bg_url: '',
  maintenance_mode: false, allow_psd_sales: true, grids_config: []
})
const stamps = ref<any[]>([])
const categories = ref<any[]>([])
const mockups = ref<any[]>([])
const leads = ref<any[]>([])
const fabrics = ref<any[]>([])
const vaultedDeliveries = ref<any[]>([])

const pendingAccountLeads = computed(() => leads.value.filter(l => l.account_status === 'pending'))
const pendingDesignLeads = computed(() => leads.value.filter(l => l.design_access_status === 'pending'))

// Fica escutando mudanças na URL feitas pela sidebar global
watch(() => route.query.tab, (newTab) => {
  if (newTab) {
    activeTab.value = newTab as string
  }
})

async function loadRealData() {
  isLoading.value = true
  try {
    const { data: configData } = await supabase.from('storefront_settings').select('*').order('updated_at', { ascending: false }).limit(1).maybeSingle()
    if (configData) storeSettings.value = { ...storeSettings.value, ...configData }

    const { data: catData } = await supabase.from('catalog_categories').select('*').order('name')
    categories.value = catData || []

    const { data: stampData } = await supabase.from('catalog_stamps').select(`*, catalog_categories(name)`).order('created_at', { ascending: false }).limit(5000)
    stamps.value = stampData || []

    const { data: mockData } = await supabase.from('catalog_mockups').select('*').order('created_at', { ascending: false })
    if (mockData) mockups.value = mockData.map(m => ({ ...m, config: m.config || { categories: [] } }))

    const { data: leadsData } = await supabase.from('public_leads').select('*').order('created_at', { ascending: false })
    leads.value = leadsData || []

    const { data: fabricData } = await supabase.from('catalog_fabrics').select('*').order('name', { ascending: true })
    fabrics.value = fabricData || []

    const { data: vaultData } = await supabase.from('client_design_deliveries').select('*').order('created_at', { ascending: false })
    vaultedDeliveries.value = vaultData || []
  } catch (error) {
    console.error('Erro loadRealData:', error)
  } finally {
    isLoading.value = false
  }
}

onMounted(() => loadRealData())

function triggerChildAction() {
  if (activeTabRef.value?.handleAction) {
    activeTabRef.value.handleAction()
  }
}

function getTabTitle(tab: string) {
  const t: any = {
    builder: 'Arquitetura de Página',
    themes: 'Painel da Loja (Editor)',
    stamps: 'Acervo de Estampas',
    categories: 'Estrutura de Pastas',
    fabrics: 'Bases Têxteis',
    mockups: 'Mockups 3D',
    leads: 'Base de Clientes B2B',
    leads_kanban: 'Pipeline de Contatos',
    design_clients: 'Estúdio Exclusivo para Clientes',
    account_approvals: 'Contas Pendentes'
  }
  return t[tab] || 'Painel Marketplace'
}
</script>

<style scoped>
/* ==========================================================================
   ESTILOS PREMIUM (Estilo Kanban e Receivables)
========================================================================== */
.storefront-layout {
  position: relative;
  width: 100%;
  height: 100%;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.font-sans { font-family: 'Inter', -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; }
.tracking-tight { letter-spacing: -0.02em; }
.letter-spacing-1 { letter-spacing: 0.05em; }

/* Efeitos Background Dark Mode */
.background-carousel-wrapper { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 0; opacity: 0.6; pointer-events: none; }
.background-overlay { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 1; background: radial-gradient(circle at center, rgba(15, 15, 19, 0.4), rgba(15, 15, 19, 0.98)); backdrop-filter: blur(8px); }

/* Modificadores de Glassmorphism */
.bg-glass-dark { background: rgba(10,10,12,0.85); }
.bg-glass-header { background: rgba(20,20,24,0.55); backdrop-filter: blur(14px); }
.border-bottom-white-05 { border-bottom: 1px solid rgba(255,255,255,0.08); }
.border-white-10 { border-color: rgba(255,255,255,0.1) !important; }
.bg-surface-card { background: rgba(255,255,255,0.05); }

/* Botões 3D Técnicos */
.btn-rect { border-radius: 0 !important; text-transform: none !important; font-weight: 800; }
.btn-3d {
  border-radius: 6px !important;
  box-shadow: 0 3px 5px rgba(0,0,0,0.15), inset 0 2px 0 rgba(255,255,255,0.25) !important;
  transition: transform 0.1s ease, box-shadow 0.1s ease;
  text-transform: none !important;
}
.btn-3d:active {
  transform: translateY(2px);
  box-shadow: 0 1px 2px rgba(0,0,0,0.15), inset 0 1px 0 rgba(255,255,255,0.2) !important;
}

/* Ponto de Status Pulsante */
.status-dot { width: 8px; height: 8px; border-radius: 50%; display: inline-block; }
.pulsing-dot { animation: pulse-opacity 2s infinite; }
@keyframes pulse-opacity {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.5; }
}
.bg-success { background-color: #22c55e !important; }
.bg-warning { background-color: #f59e0b !important; }

/* Custom Scrollbars */
.custom-scroll { scrollbar-gutter: stable; }
.custom-scroll::-webkit-scrollbar { width: 8px; height: 8px; }
.custom-scroll::-webkit-scrollbar-track { background: transparent; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128, 0.3); border-radius: 4px; }
</style>
