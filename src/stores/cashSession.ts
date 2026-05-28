import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { supabase } from '@/api/supabase'
import { useUserStore } from './user'
import type { CashSession, CashMovement, CashSummary } from '@/types/cash'

export const useCashSessionStore = defineStore('cashSession', () => {
  const userStore = useUserStore()

  // Estado
  const currentSession = ref<CashSession | null>(null)
  const movements = ref<CashMovement[]>([])
  const isLoading = ref(false)
  const isSessionChecked = ref(false)

  // Getters
  const isSessionOpen = computed(() => currentSession.value?.status === 'open')

  const summary = computed<CashSummary>(() => {
    const openingBalance = Number(currentSession.value?.initial_balance || 0)
    const s = { opening: openingBalance, sales_cash: 0, supply: 0, bleed: 0, current_balance: 0 }

    movements.value.forEach(m => {
      const val = Number(m.amount)
      if (m.type === 'sale_cash') s.sales_cash += val
      if (m.type === 'supply') s.supply += val
      if (m.type === 'bleed') s.bleed += Math.abs(val)
    })

    const totalMovements = movements.value.reduce((acc, m) => acc + Number(m.amount), 0)
    const hasOpeningMovementInList = movements.value.some(m => m.type === 'opening')

    if (hasOpeningMovementInList) {
        s.current_balance = totalMovements
    } else {
        s.current_balance = s.opening + totalMovements
    }
    return s
  })

  // Actions
  async function checkActiveSession() {
    if (!userStore.user?.id) return
    if (userStore.isAdmin && !userStore.activeStoreId) {
        currentSession.value = null
        movements.value = []
        isSessionChecked.value = true
        return
    }

    isLoading.value = true
    try {
      let query = supabase.from('cajuia_cash_sessions').select('*').eq('user_id', userStore.user.id).eq('status', 'open')
      if (userStore.activeStoreId) query = query.eq('store_id', userStore.activeStoreId)

      const { data, error } = await query.maybeSingle()
      if (error) throw error

      if (data) {
        currentSession.value = data
        await fetchMovements(data.id)
      } else {
        currentSession.value = null
        movements.value = []
      }
    } catch (e) {
      console.error('Erro ao verificar sessão:', e)
    } finally {
      isLoading.value = false
      isSessionChecked.value = true
    }
  }

  async function fetchMovements(sessionId: string) {
    const { data, error } = await supabase.from('cajuia_cash_movements').select('*').eq('session_id', sessionId).order('created_at', { ascending: true })
    if (!error && data) movements.value = data
  }

  async function openSession(initialAmount: number) {
    if (!userStore.user?.id) throw new Error('Usuário não logado')
    if (!userStore.activeStoreId) throw new Error('Selecione uma loja')
    if (isSessionOpen.value) throw new Error('Já existe sessão aberta')

    isLoading.value = true
    try {
      const { data: session, error } = await supabase.from('cajuia_cash_sessions').insert({
          user_id: userStore.user.id,
          store_id: userStore.activeStoreId,
          initial_balance: initialAmount,
          status: 'open',
          opened_at: new Date().toISOString()
        }).select().single()

      if (error) throw error

      await supabase.from('cajuia_cash_movements').insert({
        session_id: session.id,
        user_id: userStore.user.id,
        type: 'opening',
        amount: initialAmount,
        description: 'Abertura de Caixa'
      })

      currentSession.value = session
      movements.value = []
      await fetchMovements(session.id)
      return session
    } catch (e) { throw e } finally { isLoading.value = false }
  }

  async function registerMovement(type: 'sale_cash' | 'supply' | 'bleed', amount: number, description: string, orderId: string | null = null) {
    if (!currentSession.value) throw new Error('Nenhuma sessão aberta')
    const finalAmount = type === 'bleed' ? -Math.abs(amount) : Math.abs(amount)

    const { data, error } = await supabase.from('cajuia_cash_movements').insert({
        session_id: currentSession.value.id,
        user_id: userStore.user!.id,
        type,
        amount: finalAmount,
        description,
        order_id: orderId
      }).select().single()

    if (error) throw error
    if (data) movements.value.push(data)
    return data
  }

  // --- MODIFICADO PARA RETORNAR HISTÓRICO ---
  async function closeSession(userCountedAmount: number, notes: string = '') {
    if (!currentSession.value) throw new Error('Nenhuma sessão aberta')

    isLoading.value = true
    try {
      const systemBalance = summary.value.current_balance
      const difference = userCountedAmount - systemBalance

      const { data, error } = await supabase.from('cajuia_cash_sessions').update({
          status: 'closed',
          closed_at: new Date().toISOString(),
          final_balance_system: systemBalance,
          final_balance_user: userCountedAmount,
          difference: difference,
          notes: notes
        }).eq('id', currentSession.value.id).select().single()

      if (error) throw error

      // Snapshot dos dados para o relatório antes de limpar
      const result = {
        session: data,
        movements: [...movements.value],
        summary: { ...summary.value }
      }

      // Limpa estado local
      currentSession.value = null
      movements.value = []

      return result
    } catch (e) {
      console.error('Erro ao fechar caixa:', e)
      throw e
    } finally {
      isLoading.value = false
    }
  }

  return { currentSession, movements, isLoading, isSessionChecked, isSessionOpen, summary, checkActiveSession, openSession, registerMovement, closeSession }
})
