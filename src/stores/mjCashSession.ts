import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { supabase } from '@/api/supabase'
import { useUserStore } from './user'

export type MjCashSession = {
  id: string
  status: 'open' | 'closed'
  initial_balance: number
  store_id: string
  user_id: string
  final_balance_system?: number
  final_balance_user?: number
  difference?: number
  opened_at: string
  closed_at?: string
  notes?: string
}

export type MjCashMovement = {
  id: string
  type: 'sale_cash' | 'supply' | 'bleed' | 'opening' | 'in_audit' | 'out_audit'
  amount: number
  description: string
  order_id?: string | null
  user_id?: string
  created_at: string
  source_table?: string
  source_id?: string
  note?: string
}

export const useMjCashSessionStore = defineStore('mjCashSession', () => {
  const userStore = useUserStore()

  const currentSession = ref<MjCashSession | null>(null)
  const movements = ref<MjCashMovement[]>([])
  const isLoading = ref(false)
  const isSessionChecked = ref(false)

  // Lista de métodos disponíveis no sistema (ID/Nome) para o select de configuração
  const availablePaymentMethods = ref<any[]>([])

  // IDs dos métodos que SÃO CONSIDERADOS CAIXA
  const storeCashMethodIds = ref<string[]>([])

  // Estado Calculado (Auditado) - Fonte da Verdade
  const auditSummary = ref({
    opening: 0,
    orders_total: 0,
    supply: 0,
    bleed: 0,
    audit_in: 0,
    audit_out: 0,
    calculated_balance: 0
  })

  const isSessionOpen = computed(() => currentSession.value?.status === 'open')

  // Computed mantido para compatibilidade, mas agora usa os dados auditados
  const summary = computed(() => {
    return {
      opening: auditSummary.value.opening,
      sales_cash: auditSummary.value.orders_total,
      supply: auditSummary.value.supply,
      bleed: auditSummary.value.bleed,
      current_balance: auditSummary.value.calculated_balance
    }
  })

  // --- AUDITORIA LOCAL STORAGE ---
  function addToAuditLog(action: string, details: any) {
      try {
          const logEntry = {
              timestamp: new Date().toISOString(),
              user: userStore.user?.email || 'unknown',
              store: userStore.activeStoreId,
              action,
              details
          }

          const currentLog = JSON.parse(localStorage.getItem('mj_cash_audit_log') || '[]')
          currentLog.push(logEntry)
          if (currentLog.length > 1000) currentLog.shift()

          localStorage.setItem('mj_cash_audit_log', JSON.stringify(currentLog))
      } catch (e) {
          console.warn("Falha ao gravar audit log", e)
      }
  }

  // --- CONFIGURAÇÃO E MÉTODOS ---

  async function fetchPaymentMethods() {
      if (availablePaymentMethods.value.length > 0) return

      const { data } = await supabase
        .from('finance_payment_methods')
        .select('id, name, gestao_click_id')
        .order('name')

      if (data) availablePaymentMethods.value = data
  }

  function getMethodName(id: string | null): string {
      if (!id) return 'Não Identificado'
      const method = availablePaymentMethods.value.find(m => m.id === id || m.gestao_click_id === id)
      return method ? method.name : 'Outros / Manual'
  }

  function isCashMethod(methodIdOrName: string | null | undefined): boolean {
      if (!methodIdOrName) return false;

      const sId = String(methodIdOrName).toLowerCase();

      // 1. Fallback Imediato
      if (sId.includes('dinheiro') || sId.includes('espécie') || sId.includes('especie')) {
          return true;
      }

      // 2. Verifica se o ID passado já é um dos IDs de caixa (UUID direto)
      if (storeCashMethodIds.value.includes(sId)) return true;

      // 3. Busca o método na lista completa
      if (availablePaymentMethods.value.length > 0) {
          const found = availablePaymentMethods.value.find(m =>
              m.id === sId ||
              String(m.gestao_click_id) === sId ||
              m.name.toLowerCase() === sId
          );

          if (found) {
              if (storeCashMethodIds.value.includes(found.id)) return true;
              if (found.name.toLowerCase().includes('dinheiro') || found.name.toLowerCase().includes('espécie')) {
                  return true;
              }
          }
      }

      return false;
  }

  async function fetchStoreConfig(storeId: string) {
      if (!storeId) return
      await fetchPaymentMethods()

      try {
          const { data, error } = await supabase
            .from('stores')
            .select('settings')
            .eq('id', storeId)
            .single()

          if (error) throw error

          if (data?.settings?.cash_method_ids && Array.isArray(data.settings.cash_method_ids)) {
              storeCashMethodIds.value = data.settings.cash_method_ids
          } else {
              const moneyDefaults = availablePaymentMethods.value
                  .filter(m => ['dinheiro', 'espécie', 'especie'].some(k => m.name.toLowerCase().includes(k)))
                  .map(m => m.id)
              storeCashMethodIds.value = moneyDefaults
          }
      } catch (e) {
          console.warn('[MjCashStore] Erro ao carregar config da loja (Usando padrão):', e)
          storeCashMethodIds.value = []
      }
  }

  async function saveStoreConfig(storeId: string, methodIds: string[]) {
      try {
          const { data: current } = await supabase.from('stores').select('settings').eq('id', storeId).single()
          const currentSettings = current?.settings || {}
          const newSettings = { ...currentSettings, cash_method_ids: methodIds }

          const { error } = await supabase
            .from('stores')
            .update({ settings: newSettings })
            .eq('id', storeId)

          if (error) throw error
          storeCashMethodIds.value = methodIds
          addToAuditLog('CONFIG_UPDATE', { methodIds })

          if (currentSession.value) await recalculateSessionBalance()

          return true
      } catch (e) {
          console.error('[MjCashStore] Erro ao salvar config:', e)
          throw e
      }
  }

  // --- RECALCULO BLINDADO (CORE) ---
  async function recalculateSessionBalance() {
      if (!currentSession.value) return 0

      isLoading.value = true
      try {
          if(availablePaymentMethods.value.length === 0) await fetchPaymentMethods();
          if(storeCashMethodIds.value.length === 0) await fetchStoreConfig(currentSession.value.store_id);

          // 1. Fundo de Abertura
          const opening = Number(currentSession.value.initial_balance || 0)

          // 2. Movimentos Manuais (Suprimento, Sangria e Auditoria)
          const { data: manualMoves } = await supabase
              .from('mj_cash_movements')
              .select('*')
              .eq('session_id', currentSession.value.id)

          let supplyTotal = 0
          let bleedTotal = 0
          let auditInTotal = 0
          let auditOutTotal = 0
          let pdvCashTotal = 0

          if (manualMoves) {
              manualMoves.forEach(m => {
                  const val = Number(m.amount)
                  if (m.type === 'supply') supplyTotal += val
                  if (m.type === 'bleed') bleedTotal += Math.abs(val)
                  if (m.type === 'in_audit') auditInTotal += Math.abs(val)
                  if (m.type === 'out_audit') auditOutTotal += Math.abs(val)
                  if (m.type === 'sale_cash') pdvCashTotal += val
              })
          }

          // 3. Pedidos Vinculados (FÁBRICA)
          const { data: sessionOrders } = await supabase
              .from('orders')
              .select('id, total_value, details, status, order_number')
              .eq('cash_session_id', currentSession.value.id)
              .neq('status', 'cancelled')

          let ordersCashTotal = 0

          if (sessionOrders) {
              sessionOrders.forEach(order => {
                  const details = order.details || {}

                  if (details.downPayments && Array.isArray(details.downPayments)) {
                      details.downPayments.forEach((dp: any) => {
                          const isCash = isCashMethod(dp.method_id);
                          if (isCash) {
                              ordersCashTotal += Number(dp.value || 0)
                          }
                      })
                  }
                  else if (details.entry_value && Number(details.entry_value) > 0) {
                      const mId = details.entry_method || details.entry_method_id;
                      const isCash = isCashMethod(mId);
                      if (isCash) {
                          ordersCashTotal += Number(details.entry_value)
                      }
                  }

                  if (details.installments && details.installments.length === 1 && (!details.downPayments || details.downPayments.length === 0) && (!details.entry_value || Number(details.entry_value) === 0)) {
                      const inst = details.installments[0]
                      const isCash = isCashMethod(inst.payment_method_id);
                      if (isCash) {
                           ordersCashTotal += Number(inst.value)
                      }
                  }
              })
          }

          // 3.5 BUSCAR BAIXAS MANUAIS (OrderPaymentsModal)
          let baixasCashTotal = 0;
          const sessionStart = currentSession.value.opened_at;
          const { data: sessionReceivables } = await supabase
              .from('finance_receivables')
              .select('id, value, paid_value, payment_method_id, order_id')
              .eq('status', 'pago')
              .eq('created_by', currentSession.value.user_id)
              .gte('paid_at', sessionStart);

          if (sessionReceivables) {
              sessionReceivables.forEach(rec => {
                  if (isCashMethod(rec.payment_method_id)) {
                      const alreadyCountedInOrders = sessionOrders && sessionOrders.some(o => o.id === rec.order_id);
                      if (!alreadyCountedInOrders) {
                          baixasCashTotal += Number(rec.paid_value || rec.value || 0);
                      }
                  }
              });
          }

          // 4. Fechamento da Conta
          const finalBalance = opening + supplyTotal - Math.abs(bleedTotal) + ordersCashTotal + pdvCashTotal + auditInTotal - auditOutTotal + baixasCashTotal;

          // Atualiza estado reativo
          auditSummary.value = {
              opening,
              orders_total: ordersCashTotal + pdvCashTotal + baixasCashTotal,
              supply: supplyTotal,
              bleed: bleedTotal,
              audit_in: auditInTotal,
              audit_out: auditOutTotal,
              calculated_balance: finalBalance
          }

          return finalBalance

      } catch (e) {
          console.error('Erro ao auditar saldo:', e)
          return 0
      } finally {
          isLoading.value = false
      }
  }

  // --- SESSÃO E MOVIMENTOS ---

  async function checkActiveSession() {
    if (userStore.isAdmin && !userStore.activeStoreId) {
        currentSession.value = null
        movements.value = []
        isSessionChecked.value = true
        return
    }

    if (!userStore.activeStoreId || !userStore.user?.id) {
        isLoading.value = false
        isSessionChecked.value = true
        return
    }

    await fetchStoreConfig(userStore.activeStoreId)

    isLoading.value = true
    try {
      const { data, error } = await supabase
        .from('mj_cash_sessions')
        .select('*')
        .eq('store_id', userStore.activeStoreId)
        .eq('user_id', userStore.user.id)
        .eq('status', 'open')
        .order('opened_at', { ascending: false })
        .limit(1)

      if (error) throw error

      if (data && data.length > 0) {
        currentSession.value = data[0]
        await fetchMovements(data[0].id)
        await recalculateSessionBalance()
      } else {
        currentSession.value = null
        movements.value = []
      }
    } catch (e) {
      console.error('[MJCaixa] Erro ao verificar sessão:', e)
    } finally {
      isLoading.value = false
      isSessionChecked.value = true
    }
  }

  async function fetchMovements(sessionId: string) {
    const { data, error } = await supabase
        .from('mj_cash_movements')
        .select('*')
        .eq('session_id', sessionId)
        .order('created_at', { ascending: true })

    if (!error && data) movements.value = data
  }

  async function openSession(initialAmount: number) {
    if (!userStore.user?.id) throw new Error('Usuário não logado')
    if (!userStore.activeStoreId) throw new Error('Selecione uma loja')
    if (isSessionOpen.value && currentSession.value) return currentSession.value

    isLoading.value = true
    try {
      const todayDate = new Date().toISOString().split('T')[0];

      const { data: existingSessions } = await supabase
        .from('mj_cash_sessions')
        .select('*, user:profiles(full_name)')
        .eq('store_id', userStore.activeStoreId)
        .eq('user_id', userStore.user.id)
        .eq('status', 'open')
        .gte('opened_at', `${todayDate}T00:00:00`)

      if (existingSessions && existingSessions.length > 0) {
         const existing = existingSessions[0];
         currentSession.value = existing;
         await fetchMovements(existing.id);
         await recalculateSessionBalance();
         return existing;
      }

      const { data: session, error } = await supabase.from('mj_cash_sessions').insert({
          user_id: userStore.user.id,
          store_id: userStore.activeStoreId,
          initial_balance: initialAmount,
          status: 'open',
          opened_at: new Date().toISOString()
        }).select().single()

      if (error) throw error

      await supabase.from('mj_cash_movements').insert({
        session_id: session.id,
        user_id: userStore.user.id,
        type: 'opening',
        amount: initialAmount,
        description: `Abertura de Caixa Individual`
      })

      addToAuditLog('OPEN_SESSION', { initialAmount, sessionId: session.id })
      currentSession.value = session
      movements.value = []
      await fetchMovements(session.id)
      await recalculateSessionBalance()
      return session

    } catch (e) {
        throw e
    } finally {
        isLoading.value = false
    }
  }

  async function registerMovement(type: any, amount: number, description: string, orderId: string | null = null) {
    if (!currentSession.value) throw new Error('Nenhuma sessão aberta')

    if (currentSession.value.status === 'closed') {
        await checkActiveSession();
        throw new Error('O caixa foi fechado. Atualize a página.');
    }

    const finalAmount = type === 'bleed' ? -Math.abs(amount) : Math.abs(amount)

    const { data, error } = await supabase.from('mj_cash_movements').insert({
        session_id: currentSession.value.id,
        user_id: userStore.user!.id,
        type,
        amount: finalAmount,
        description,
        order_id: orderId
      }).select().single()

    if (error) throw error
    if (data) movements.value.push(data)

    addToAuditLog('MOVEMENT', { type, amount: finalAmount, description, orderId })
    await recalculateSessionBalance()
    return data
  }

  async function forceCloseSession(sessionId: string) {
     const { error } = await supabase.from('mj_cash_sessions').update({
        status: 'closed',
        closed_at: new Date().toISOString(),
        notes: 'Fechamento Administrativo Forçado'
     }).eq('id', sessionId)

     if (error) throw error
     addToAuditLog('FORCE_CLOSE', { sessionId })

     if (currentSession.value?.id === sessionId) {
         currentSession.value = null
         movements.value = []
     }
  }

  async function closeSession(userCountedAmount: number, notes: string = '') {
    if (!currentSession.value) throw new Error('Nenhuma sessão aberta')

    await fetchPaymentMethods()

    isLoading.value = true
    try {
      const sessionId = currentSession.value.id
      const systemBalance = await recalculateSessionBalance() || 0
      const difference = userCountedAmount - systemBalance

      const { data: sessionOrders } = await supabase
        .from('orders')
        .select('order_number, total_value, details, customer_name')
        .eq('cash_session_id', sessionId)
        .neq('status', 'cancelled')

      const detailedReport: any[] = []

      if (sessionOrders) {
          sessionOrders.forEach((order: any) => {
              const details = order.details || {}
              const orderRef = `#${order.order_number}`
              const totalVal = Number(order.total_value || 0)
              let entryTotal = 0;

              if (details.downPayments && Array.isArray(details.downPayments)) {
                  details.downPayments.forEach((dp: any, idx: number) => {
                      const val = Number(dp.value)
                      if (val > 0) {
                          entryTotal += val
                          const methodName = getMethodName(dp.method_id)
                          const isCash = isCashMethod(dp.method_id)

                          detailedReport.push({
                              ref: orderRef,
                              client: order.customer_name,
                              method: methodName,
                              amount: val,
                              type: isCash ? 'Entrada (Dinheiro)' : 'Entrada (Digital)',
                              isCash: isCash
                          })
                      }
                  });
              }
              else if (Number(details.entry_value) > 0) {
                  const val = Number(details.entry_value)
                  entryTotal += val
                  const methodName = getMethodName(details.entry_method)
                  const isCash = isCashMethod(details.entry_method)

                  detailedReport.push({
                      ref: orderRef,
                      client: order.customer_name,
                      method: methodName,
                      amount: val,
                      type: isCash ? 'Entrada (Dinheiro)' : 'Entrada (Digital)',
                      isCash: isCash
                  })
              }

              const remaining = totalVal - entryTotal
              if (remaining > 0.01) {
                  let methodLabel = 'A Prazo / A Receber';
                  if (details.payment_method) methodLabel = getMethodName(details.payment_method);
                  else if (details.installment_payment_method_id) methodLabel = getMethodName(details.installment_payment_method_id);

                  detailedReport.push({
                      ref: orderRef,
                      client: order.customer_name,
                      method: methodLabel,
                      amount: remaining,
                      type: 'Saldo a Receber',
                      isCash: false
                  })
              }
          })
      }

      // BUSCA TODOS OS RECEBIMENTOS DO TURNO (PDV E FÁBRICA/ERP)
      const sessionStartStr = currentSession.value.opened_at;
      const sessionEndStr = new Date().toISOString();

      const { data: allReceivables } = await supabase
          .from('finance_receivables')
          .select('*, payment_method:finance_payment_methods(name), store_sales(id, order_number, customer_name), orders(id, order_number, customer_name)')
          .eq('status', 'pago')
          .eq('created_by', currentSession.value.user_id)
          .gte('paid_at', sessionStartStr)
          .lte('paid_at', sessionEndStr);

      if (allReceivables && allReceivables.length > 0) {
          allReceivables.forEach((rec: any) => {
              const isPdv = !!rec.store_sale_id;
              const refNumber = isPdv ? rec.store_sales?.order_number : rec.orders?.order_number;
              const cName = isPdv ? rec.store_sales?.customer_name : rec.orders?.customer_name;
              const sourceLabel = isPdv ? 'Venda PDV' : 'Baixa Parcela';
              const isCash = isCashMethod(rec.payment_method_id);

              detailedReport.push({
                  ref: `#${refNumber || 'S/N'}`,
                  client: `${cName || 'Consumidor'}`,
                  method: rec.payment_method?.name || (isCash ? 'Dinheiro' : 'Digital'),
                  amount: Number(rec.value || rec.paid_value),
                  type: sourceLabel,
                  isCash: isCash
              });
          });
      }

      const { data, error } = await supabase.from('mj_cash_sessions').update({
          status: 'closed',
          closed_at: sessionEndStr,
          final_balance_system: systemBalance,
          final_balance_user: userCountedAmount,
          difference: difference,
          notes: notes
        }).eq('id', sessionId).select().single()

      if (error) throw error

      addToAuditLog('CLOSE_SESSION', {
          systemBalance,
          userCountedAmount,
          difference,
          totalDigitalSales: detailedReport.length
      })

      const result = {
        session: data,
        movements: [...movements.value],
        summary: { ...summary.value },
        detailedSales: detailedReport
      }

      currentSession.value = null
      movements.value = []

      return result
    } catch (e) {
      throw e
    } finally {
      isLoading.value = false
    }
  }

  // ==========================================================================
  // FERRAMENTAS DE AUDITORIA E SIMULAÇÃO (CAIXA PRETA)
  // ==========================================================================

  // 1. Grava tudo que passa pelas telas de venda/baixa
  async function logExtraction(origin: string, amount: number, methodId: string | null, orderRef: string, payload: any = {}) {
      if (!currentSession.value) return;
      try {
          await fetchPaymentMethods();
          await supabase.from('mj_cash_extraction_audit').insert({
              session_id: currentSession.value.id,
              amount: Number(amount),
              method_name: getMethodName(methodId),
              origin: origin,
              is_cash: isCashMethod(methodId),
              created_by: userStore.user?.id,
              order_ref: orderRef,
              raw_payload: payload
          });
      } catch (e) {
          console.error("Falha ao registrar log de extração", e);
      }
  }

  // 2. Simula o que o PDF vai puxar se fechar agora
  async function simulateExtraction() {
      if (!currentSession.value) throw new Error('Nenhuma sessão aberta');
      await fetchPaymentMethods();

      const sessionId = currentSession.value.id;
      const detailedReport: any[] = [];

      // A. Busca Pedidos (Simulação)
      const { data: sessionOrders } = await supabase
        .from('orders')
        .select('order_number, total_value, details, customer_name')
        .eq('cash_session_id', sessionId)
        .neq('status', 'cancelled');

      if (sessionOrders) {
          sessionOrders.forEach((order: any) => {
              const details = order.details || {};
              const orderRef = `#${order.order_number}`;

              if (details.downPayments && Array.isArray(details.downPayments)) {
                  details.downPayments.forEach((dp: any) => {
                      if (Number(dp.value) > 0) {
                          detailedReport.push({
                              ref: orderRef,
                              client: order.customer_name,
                              method: getMethodName(dp.method_id),
                              amount: Number(dp.value),
                              type: isCashMethod(dp.method_id) ? 'Entrada (Dinheiro)' : 'Entrada (Digital)',
                              isCash: isCashMethod(dp.method_id),
                              source: 'Orders JSON'
                          });
                      }
                  });
              } else if (Number(details.entry_value) > 0) {
                  detailedReport.push({
                      ref: orderRef,
                      client: order.customer_name,
                      method: getMethodName(details.entry_method),
                      amount: Number(details.entry_value),
                      type: isCashMethod(details.entry_method) ? 'Entrada (Dinheiro)' : 'Entrada (Digital)',
                      isCash: isCashMethod(details.entry_method),
                      source: 'Orders JSON (Legacy)'
                  });
              }
          });
      }

      // B. Busca Recebimentos/Baixas (Simulação)
      const sessionStartStr = currentSession.value.opened_at;
      const sessionEndStr = new Date().toISOString();

      const { data: allReceivables } = await supabase
          .from('finance_receivables')
          .select('*, payment_method:finance_payment_methods(name), store_sales(id, order_number, customer_name), orders(id, order_number, customer_name)')
          .eq('status', 'pago')
          .eq('created_by', currentSession.value.user_id)
          .gte('paid_at', sessionStartStr)
          .lte('paid_at', sessionEndStr);

      if (allReceivables) {
          allReceivables.forEach((rec: any) => {
              const isPdv = !!rec.store_sale_id;
              const refNumber = isPdv ? rec.store_sales?.order_number : rec.orders?.order_number;
              const isCash = isCashMethod(rec.payment_method_id);

              detailedReport.push({
                  ref: `#${refNumber || 'S/N'}`,
                  client: `${isPdv ? rec.store_sales?.customer_name : rec.orders?.customer_name}`,
                  method: rec.payment_method?.name || (isCash ? 'Dinheiro' : 'Digital'),
                  amount: Number(rec.value || rec.paid_value),
                  type: isPdv ? 'Venda PDV' : 'Baixa Parcela',
                  isCash: isCash,
                  source: 'Finance Receivables'
              });
          });
      }

      // C. Puxa os logs da caixa preta para confrontar
      const { data: auditLogs } = await supabase
          .from('mj_cash_extraction_audit')
          .select('*')
          .eq('session_id', sessionId)
          .order('created_at', { ascending: true });

      return {
          extracted: detailedReport, // O que o PDF vai ver
          audited: auditLogs || []   // O que os botões mandaram
      };
  }

  return {
      currentSession,
      movements,
      isLoading,
      isSessionChecked,
      isSessionOpen,
      summary,
      auditSummary,
      availablePaymentMethods,
      storeCashMethodIds,
      checkActiveSession,
      openSession,
      registerMovement,
      closeSession,
      forceCloseSession,
      isCashMethod,
      fetchStoreConfig,
      saveStoreConfig,
      fetchPaymentMethods,
      recalculateSessionBalance,
      logExtraction,
      simulateExtraction
  }
})
