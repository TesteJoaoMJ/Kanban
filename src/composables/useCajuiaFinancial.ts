// src/composables/useCajuiaFinancial.ts
import { ref } from 'vue'
import { supabase } from '@/api/supabase'
import { addMonths, parseISO, format } from 'date-fns'

export function useCajuiaFinancial() {
  const isProcessing = ref(false)

  // Cache simples para não buscar contas toda hora
  const bankAccountsCache = ref<any[]>([])

  const fetchBankAccounts = async () => {
    if (bankAccountsCache.value.length > 0) return bankAccountsCache.value
    const { data } = await supabase.from('cajuia_bank_accounts').select('id, name, type')
    bankAccountsCache.value = data || []
    return data || []
  }

  // Função Principal: Gera o Financeiro a partir de uma Venda
  const generateReceivablesFromOrder = async (
    orderId: string,
    orderNumber: number,
    customer: any,
    payments: any[], // Array de { method: { nome: string }, amount: number }
    installments: number = 1,
    firstDueDate: string, // YYYY-MM-DD
    cardFeePercentage: number = 0
  ) => {
    isProcessing.value = true
    try {
      const accounts = await fetchBankAccounts()

      // Mapeamento Inteligente de Contas
      const getAccountId = (methodName: string) => {
        const lower = methodName.toLowerCase()
        if (lower.includes('dinheiro')) return accounts.find(a => a.type === 'safe')?.id
        if (lower.includes('pix')) return accounts.find(a => a.type === 'bank')?.id
        if (lower.includes('cartão') || lower.includes('credito') || lower.includes('debito')) return accounts.find(a => a.type === 'gateway')?.id
        return accounts.find(a => a.type === 'safe')?.id // Fallback
      }

      const receivablesPayload: any[] = []

      // Itera sobre cada forma de pagamento usada na venda
      for (const payment of payments) {
        const method = payment.method.nome
        const amount = Number(payment.amount)
        const accountId = getAccountId(method)
        const isCashOrPix = method.toLowerCase().includes('dinheiro') || method.toLowerCase().includes('pix')

        // Se for Dinheiro/Pix, é uma parcela única e já paga (A Vista)
        if (isCashOrPix) {
          receivablesPayload.push({
            order_id: orderId,
            customer_name: customer.nome || 'Consumidor',
            customer_doc: customer.cpf_cnpj || '',
            description: `Venda #${orderNumber} - ${method}`,
            installment_number: 1,
            total_installments: 1,
            issue_date: new Date().toISOString(),
            due_date: new Date().toISOString(), // Vence hoje
            payment_date: new Date().toISOString(), // Pago hoje
            competency_date: new Date().toISOString(),
            gross_value: amount,
            net_value: amount, // Sem taxa
            // amount_paid removido pois a coluna não existe no banco
            status: 'PAID',
            payment_method: method,
            bank_account_id: accountId
          })
        }
        // Se for Cartão ou Outros, respeita o parcelamento
        else {
          const installmentValue = amount / installments
          const feePerInstallment = (installmentValue * (cardFeePercentage / 100))
          const netPerInstallment = installmentValue - feePerInstallment
          const baseDate = firstDueDate ? parseISO(firstDueDate) : new Date()

          for (let i = 0; i < installments; i++) {
            const dueDate = addMonths(baseDate, i)

            receivablesPayload.push({
              order_id: orderId,
              customer_name: customer.nome || 'Consumidor',
              customer_doc: customer.cpf_cnpj || '',
              description: `Venda #${orderNumber} - Parc ${i+1}/${installments} (${method})`,
              installment_number: i + 1,
              total_installments: installments,
              issue_date: new Date().toISOString(),
              due_date: dueDate.toISOString(),
              competency_date: new Date().toISOString(),
              payment_date: null, // Em aberto
              gross_value: Number(installmentValue.toFixed(2)),
              net_value: Number(netPerInstallment.toFixed(2)),
              tax_fee_amount: Number(feePerInstallment.toFixed(2)),
              // amount_paid removido
              status: 'PENDING',
              payment_method: method,
              bank_account_id: accountId
            })
          }
        }
      }

      // Inserção em Lote no Supabase
      if (receivablesPayload.length > 0) {
        const { error } = await supabase.from('cajuia_receivables').insert(receivablesPayload)
        if (error) {
            console.error('Erro detalhado Supabase (Receivables):', error)
            throw error
        }
      }

      return true

    } catch (error) {
      console.error('Erro ao gerar financeiro:', error)
      return false
    } finally {
      isProcessing.value = false
    }
  }

  return { generateReceivablesFromOrder, isProcessing }
}
