<template>
  <v-dialog
    :model-value="modelValue"
    @update:model-value="$emit('update:modelValue', $event)"
    max-width="500"
    content-class="glass-dialog-settle"
    persistent
  >
    <v-card class="glass-modal-card">
      <div class="px-5 py-4 border-b border-white-10 d-flex align-center justify-space-between bg-glass-header">
        <div class="d-flex align-center gap-3">
           <div class="icon-box-sm bg-gradient-success elevation-5">
              <v-icon color="white" size="20">mdi-cash-check</v-icon>
           </div>
           <div>
              <h3 class="text-subtitle-2 font-weight-bold text-white lh-1">Baixar Título</h3>
              <div class="text-[10px] text-white-50 font-weight-medium mt-0.5">
                  {{ title?.description }}
              </div>
           </div>
        </div>
        <v-btn icon variant="text" size="small" color="white-50" @click="close">
            <v-icon>mdi-close</v-icon>
        </v-btn>
      </div>

      <div class="pa-5 bg-glass-body">
        <v-form ref="form" @submit.prevent="confirmSettlement">

            <div class="d-flex justify-space-between mb-4 pa-3 rounded bg-white-05 border border-white-05">
                <div class="d-flex flex-column">
                    <span class="text-[10px] text-white-50 uppercase">Vencimento</span>
                    <span class="text-body-2 font-weight-bold text-white">{{ formatDate(title?.due_date) }}</span>
                </div>
                <div class="d-flex flex-column text-right">
                    <span class="text-[10px] text-white-50 uppercase">Valor Original</span>
                    <span class="text-body-2 font-weight-bold text-white">{{ formatCurrency(title?.net_value) }}</span>
                </div>
            </div>

            <div class="d-flex gap-3 mb-2">
                <v-text-field
                    v-model="paymentDate"
                    type="date"
                    label="Data do Pagamento"
                    variant="outlined"
                    density="compact"
                    class="glass-input"
                    bg-color="rgba(0,0,0,0.3)"
                    hide-details="auto"
                ></v-text-field>

                <v-select
                    v-model="selectedAccount"
                    :items="accounts"
                    item-title="name"
                    item-value="id"
                    label="Conta de Destino"
                    variant="outlined"
                    density="compact"
                    class="glass-input"
                    bg-color="rgba(0,0,0,0.3)"
                    hide-details="auto"
                    :loading="loadingAccounts"
                ></v-select>
            </div>

            <div class="d-flex gap-3 mb-4">
                <v-text-field
                    v-model.number="additions"
                    label="Juros / Multa"
                    prefix="R$"
                    type="number"
                    variant="outlined"
                    density="compact"
                    class="glass-input"
                    bg-color="rgba(0,0,0,0.3)"
                    hide-details
                ></v-text-field>

                <v-text-field
                    v-model.number="discounts"
                    label="Desconto"
                    prefix="R$"
                    type="number"
                    variant="outlined"
                    density="compact"
                    class="glass-input"
                    bg-color="rgba(0,0,0,0.3)"
                    hide-details
                ></v-text-field>
            </div>

            <div class="currency-input-wrapper mb-4 d-flex align-center px-3 py-3 rounded-lg border border-white-10 bg-success-10">
                <div class="d-flex flex-column mr-auto">
                    <span class="text-[10px] font-weight-bold text-success text-uppercase">Total Recebido</span>
                    <span class="text-[9px] text-white-50">Confira o valor final</span>
                </div>
                <span class="text-h6 font-weight-bold text-success mr-2">R$</span>
                <input
                    type="number"
                    v-model="finalAmount"
                    class="glass-input-transparent text-h4 font-weight-black text-white w-100 text-right"
                    step="0.01"
                />
            </div>

            <v-btn
                v-if="!showPixDisplay"
                block
                variant="outlined"
                color="primary"
                class="mb-3 border-dashed"
                prepend-icon="mdi-qrcode"
                @click="generatePix"
                :loading="loadingPix"
            >
                Gerar Cobrança Pix Cora
            </v-btn>

            <v-btn
                block
                height="48"
                color="success"
                class="font-weight-bold rounded-lg shadow-glow-success"
                :loading="processing"
                type="submit"
            >
                <v-icon start>mdi-check-circle-outline</v-icon>
                Confirmar Recebimento
            </v-btn>
        </v-form>
      </div>
    </v-card>

    <v-dialog v-model="showPixDisplay" max-width="400" persistent>
        <v-card class="glass-modal-card">
            <div class="px-5 py-3 border-b border-white-10 d-flex align-center justify-space-between bg-glass-header">
                <span class="text-subtitle-1 font-weight-bold text-white">Pix Gerado</span>
                <v-btn icon variant="text" size="small" color="white-50" @click="showPixDisplay = false">
                    <v-icon>mdi-close</v-icon>
                </v-btn>
            </div>
            <div class="pa-6 text-center bg-glass-body">
                 <div class="bg-white pa-2 rounded mb-4 d-inline-block">
                    <img
                        v-if="pixData.qrCodeUrl"
                        :src="pixData.qrCodeUrl"
                        style="width: 200px; height: 200px; display: block;"
                    />
                 </div>

                 <div class="text-caption text-white-50 mb-2">Pix Copia e Cola</div>
                 <v-text-field
                    readonly
                    v-model="pixData.emv"
                    variant="outlined"
                    density="compact"
                    class="glass-input"
                    bg-color="rgba(0,0,0,0.3)"
                    append-inner-icon="mdi-content-copy"
                    @click:append-inner="copyToClipboard(pixData.emv)"
                 ></v-text-field>

                 <v-alert
                    density="compact"
                    type="info"
                    variant="tonal"
                    class="mt-4 text-caption text-left"
                    color="blue"
                 >
                    Após o cliente pagar, clique em <strong>Confirmar Recebimento</strong> na tela anterior para baixar o título.
                 </v-alert>
            </div>
            <div class="pa-4 border-t border-white-10 bg-glass-header">
                <v-btn block color="primary" @click="showPixDisplay = false">
                    Voltar para Baixar
                </v-btn>
            </div>
        </v-card>
    </v-dialog>

  </v-dialog>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { supabase } from '@/api/supabase'
import { coraApi } from '@/api/coraProxy' // Certifique-se que o caminho está correto
import { format } from 'date-fns'

const props = defineProps({
    modelValue: Boolean,
    title: Object as any
})
const emit = defineEmits(['update:modelValue', 'settled'])

// Estados Base
const accounts = ref<any[]>([])
const loadingAccounts = ref(false)
const processing = ref(false)

// Estados do Formulário
const paymentDate = ref(format(new Date(), 'yyyy-MM-dd'))
const selectedAccount = ref<string | null>(null)
const additions = ref(0)
const discounts = ref(0)
const manualFinalAmount = ref<number | null>(null)

// Estados do Pix Cora
const loadingPix = ref(false)
const showPixDisplay = ref(false)
const pixData = ref({ qrCodeUrl: '', emv: '', id: '' })

// Computados
const baseValue = computed(() => Number(props.title?.net_value) || 0)

const finalAmount = computed({
    get: () => {
        if (manualFinalAmount.value !== null) return manualFinalAmount.value
        return Math.max(0, baseValue.value + additions.value - discounts.value)
    },
    set: (val) => {
        manualFinalAmount.value = val
    }
})

watch(() => props.modelValue, async (val) => {
    if (val) {
        // Reset state
        paymentDate.value = format(new Date(), 'yyyy-MM-dd')
        additions.value = 0
        discounts.value = 0
        manualFinalAmount.value = null
        selectedAccount.value = props.title?.bank_account_id || null
        showPixDisplay.value = false

        if (accounts.value.length === 0) await fetchAccounts()
    }
})

const fetchAccounts = async () => {
    loadingAccounts.value = true
    const { data } = await supabase.from('cajuia_bank_accounts').select('id, name').eq('is_active', true)
    accounts.value = data || []
    loadingAccounts.value = false
}

// === LÓGICA PIX CORA ===
const generatePix = async () => {
    // Validações
    const client = props.title?.client || props.title?.cajuia_clients; // Tenta pegar de join
    const identity = client?.cpf_cnpj || client?.cpf || client?.cnpj;
    const name = client?.nome || client?.name || 'Cliente Cajuia';

    if (!identity) {
        alert('Erro: O cliente vinculado a este título não possui CPF/CNPJ cadastrado. Necessário para emitir Pix Cora.')
        return
    }

    if (finalAmount.value <= 0) {
        alert('O valor para gerar o Pix deve ser maior que zero.')
        return
    }

    loadingPix.value = true
    try {
        const amountInCents = Math.round(finalAmount.value * 100)

        const result = await coraApi.generatePix({
            amount: amountInCents,
            code: `TIT-${props.title.id}-${Date.now()}`, // ID único ref ao Título
            customer: {
                name: name,
                identity: identity,
                email: client?.email
            }
        })

        pixData.value = result
        showPixDisplay.value = true

    } catch (error: any) {
        console.error(error)
        alert(`Erro ao gerar Pix: ${error.message}`)
    } finally {
        loadingPix.value = false
    }
}

const copyToClipboard = async (text: string) => {
    try {
        await navigator.clipboard.writeText(text)
        alert('Código Pix copiado!')
    } catch (e) {
        console.error('Erro ao copiar', e)
    }
}

// === LÓGICA DE BAIXA (SETTLEMENT) ===
const confirmSettlement = async () => {
    if (!selectedAccount.value || finalAmount.value < 0) {
        alert('Selecione uma conta e verifique o valor.')
        return
    }

    processing.value = true
    try {
        // 1. Atualiza o título para PAGO
        const { error } = await supabase.from('cajuia_receivables').update({
            status: 'PAID',
            payment_date: new Date().toISOString(), // Ou usa paymentDate.value se quiser respeitar a data do input
            amount_paid: finalAmount.value,
            fine_amount: additions.value,
            discount_amount: discounts.value,
            bank_account_id: selectedAccount.value,
            updated_at: new Date().toISOString()
        }).eq('id', props.title.id)

        if (error) throw error

        // 2. Atualiza Saldo da Conta Bancária (Incremento simples)
        // Nota: Em produção com alta concorrência, use uma RPC (function) do Supabase "increment_balance"
        const { data: acc } = await supabase
            .from('cajuia_bank_accounts')
            .select('current_balance')
            .eq('id', selectedAccount.value)
            .single()

        if (acc) {
            await supabase.from('cajuia_bank_accounts').update({
                current_balance: Number(acc.current_balance) + Number(finalAmount.value)
            }).eq('id', selectedAccount.value)
        }

        emit('settled')
        close()
    } catch (e) {
        console.error(e)
        alert('Erro ao baixar título.')
    } finally {
        processing.value = false
    }
}

const close = () => emit('update:modelValue', false)
const formatCurrency = (v: number) => new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(v)
const formatDate = (d: string) => d ? format(new Date(d), 'dd/MM/yyyy') : '-'
</script>

<style scoped lang="scss">
.glass-dialog-settle { backdrop-filter: blur(5px); }
.glass-modal-card {
    background: #1e1e24; border: 1px solid rgba(255,255,255,0.1);
    border-radius: 16px; box-shadow: 0 20px 60px rgba(0,0,0,0.8);
}
.bg-glass-header { background: rgba(255, 255, 255, 0.03); }
.bg-glass-body { background: #1e1e24; }
.bg-white-05 { background: rgba(255,255,255,0.05); }
.bg-success-10 { background: rgba(0, 230, 118, 0.1); }
.border-white-05 { border-color: rgba(255,255,255,0.05); }
.border-white-10 { border-color: rgba(255,255,255,0.1); }
.text-white-50 { color: rgba(255,255,255,0.5); }
.icon-box-sm { width: 36px; height: 36px; border-radius: 10px; display: flex; align-items: center; justify-content: center; }
.bg-gradient-success { background: linear-gradient(135deg, #00e676, #006025); }

/* Inputs com visual Glass */
.glass-input :deep(.v-field) {
    border-radius: 8px !important;
    border: 1px solid rgba(255,255,255,0.1);
    color: white !important;
}
.glass-input-transparent {
    background: transparent;
    border: none;
    outline: none;
    font-family: 'Roboto Mono', monospace;
}
.shadow-glow-success { box-shadow: 0 0 15px rgba(0,230,118,0.3); }

/* Borda tracejada para o botão auxiliar */
.border-dashed { border-style: dashed !important; border-width: 1px; }
</style>
