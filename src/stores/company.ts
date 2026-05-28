// src/stores/company.ts
import { ref, computed } from 'vue'
import { defineStore } from 'pinia'
import { supabase } from '@/api/supabase'
import { useUserStore } from './user'
import { useRouter } from 'vue-router'

export interface Company {
  id: string
  name: string
  cnpj?: string
  trade_name?: string
  logo_url?: string
}

export const useCompanyStore = defineStore('company', () => {
  const router = useRouter()
  const userStore = useUserStore()

  // State
  const context = ref<string | 'global'>('global')
  const availableCompanies = ref<Company[]>([])
  const isLoading = ref(false)

  // --- NOVO: MODO DEMO GLOBAL ---
  const isDemoMode = ref<boolean>(localStorage.getItem('mjprocess_demo_mode') === 'true')

  function toggleDemoMode() {
    isDemoMode.value = !isDemoMode.value
    localStorage.setItem('mjprocess_demo_mode', String(isDemoMode.value))
    // Recarrega a página para forçar todas as telas a remontarem com/sem os dados mockados
    window.location.reload()
  }
  // ------------------------------

  // Getters
  const isGlobalView = computed(() => context.value === 'global')

  const currentCompany = computed(() => {
    if (isGlobalView.value) return null
    return availableCompanies.value.find(c => c.id === context.value) || null
  })

  // Modificado para mascarar os dados caso o Modo Demo esteja ativo
  const currentCompanyName = computed(() => {
    if (isDemoMode.value) return 'FICTÍCIA S.A. (DEMO)'
    if (isGlobalView.value) return 'Visão Global (Holding)'
    return currentCompany.value?.trade_name || currentCompany.value?.name || 'Empresa Selecionada'
  })

  const currentCompanyCnpj = computed(() => {
    if (isDemoMode.value) return '00000000000100'
    return currentCompany.value?.cnpj?.replace(/\D/g, '') || null
  })

  const currentCompanyLogo = computed(() => {
    if (isGlobalView.value || !currentCompany.value?.logo_url) {
      return '/logomjlm.png'
    }
    return currentCompany.value.logo_url
  })

  // Actions
  async function loadCompanies() {
    isLoading.value = true
    try {
      const { data, error } = await supabase
        .from('companies')
        .select('id, trade_name, name, cnpj, logo_url')
        .eq('active', true)
        .order('name', { ascending: true })

      if (error) throw error

      availableCompanies.value = data || []
    } catch (e) {
      console.error('Erro ao carregar empresas:', e)
    } finally {
      isLoading.value = false
    }
  }

  function setContext(newContext: string | 'global') {
    if (context.value === newContext) return

    context.value = newContext
    localStorage.setItem('activeContext', newContext)
  }

  async function initialize() {
    await loadCompanies()

    const savedContext = localStorage.getItem('activeContext')

    if (savedContext && savedContext !== 'global') {
      const exists = availableCompanies.value.some(c => c.id === savedContext)
      if (exists) {
        context.value = savedContext
        return
      }
    }

    context.value = 'global'
  }

  return {
    context,
    availableCompanies,
    isLoading,
    isGlobalView,
    isDemoMode,
    currentCompany,
    currentCompanyName,
    currentCompanyCnpj,
    currentCompanyLogo,
    loadCompanies,
    setContext,
    initialize,
    toggleDemoMode
  }
})
