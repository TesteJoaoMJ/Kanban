<template>
  <div class="view-wrap checkout-layout">

    <div v-if="isLoading" class="loading-screen mj-surface">
      <v-progress-circular indeterminate color="primary" size="52" width="4" />
      <p>Preparando ambiente seguro...</p>
    </div>

    <div v-else-if="!activeStamp" class="error-screen mj-surface">
      <div class="error-icon-wrap"><v-icon size="56" color="error">mdi-alert-circle-outline</v-icon></div>
      <h2>Item não encontrado</h2>
      <p>Não foi possível localizar o arquivo digital selecionado para compra.</p>
      <v-btn color="primary" size="large" class="mt-4 error-btn" @click="router.push('/marketplace/descobrir')">
        Voltar ao Acervo
      </v-btn>
    </div>

    <div v-else class="checkout-container">
      <div class="checkout-grid" :class="{ 'pix-active': pixGenerated && paymentStatus !== 'paid' }">

        <main class="checkout-main">

          <header class="checkout-header">
            <div class="brand-area" @click="router.push('/marketplace')">
              <v-icon size="28" color="primary">mdi-shield-check</v-icon>
              <span class="brand-text">Checkout Seguro</span>
            </div>
            <v-btn variant="text" size="small" color="primary" prepend-icon="mdi-arrow-left" @click="router.back()" class="font-weight-bold">
              Voltar à Loja
            </v-btn>
          </header>

          <div class="checkout-steps">

            <section class="step-card mj-surface mj-border" :class="{ 'step-done': currentStep > 1, 'd-none': pixGenerated && paymentStatus !== 'paid' }">
              <div class="step-header">
                <div class="step-number">1</div>
                <h2 class="step-title">Dados do Comprador</h2>
                <v-btn v-if="currentStep > 1 && paymentStatus === 'pending' && !pixGenerated" variant="text" size="small" color="primary" class="font-weight-bold" @click="currentStep = 1">
                  Editar
                </v-btn>
              </div>

              <transition name="expand">
                <div v-if="currentStep === 1" class="step-body">
                  <div class="form-grid">
                    <div class="form-group full-width">
                      <label>E-mail de Acesso (Login)</label>
                      <input type="email" :value="customerData.email" disabled class="mj-input disabled mj-border" />
                    </div>
                    <div class="form-group full-width">
                      <label>Nome Completo / Razão Social</label>
                      <input v-model="customerData.name" type="text" class="mj-input active mj-surface-2 mj-border" placeholder="Como deseja ser chamado" />
                    </div>
                    <div class="form-group">
                      <label>CPF ou CNPJ</label>
                      <input v-model="customerData.document" type="text" class="mj-input active mj-surface-2 mj-border" placeholder="Apenas números" />
                    </div>
                    <div class="form-group">
                      <label>WhatsApp (Opcional)</label>
                      <input v-model="customerData.phone" type="text" class="mj-input active mj-surface-2 mj-border" placeholder="(00) 00000-0000" />
                    </div>
                  </div>

                  <v-btn color="primary" size="x-large" block class="continue-btn mt-8" @click="proceedToPayment" :disabled="!customerData.name || !customerData.document">
                    Continuar para Pagamento
                  </v-btn>
                </div>
              </transition>

              <div v-if="currentStep > 1" class="step-summary">
                <p><strong>{{ customerData.name }}</strong> — {{ customerData.document }}</p>
                <p>{{ customerData.email }}</p>
              </div>
            </section>

            <section class="step-card mj-surface mj-border" :class="{ 'step-active': currentStep === 2, 'step-success': paymentStatus === 'paid', 'pix-modal-mode': pixGenerated && paymentStatus === 'pending' }">
              <div class="step-header" v-if="!pixGenerated || paymentStatus === 'paid'">
                <div class="step-number" v-if="paymentStatus !== 'paid'">2</div>
                <div class="step-number success-icon" v-else><v-icon size="16">mdi-check</v-icon></div>
                <h2 class="step-title">{{ paymentStatus === 'paid' ? 'Pagamento Aprovado' : 'Finalizar Pedido' }}</h2>
              </div>

              <transition name="expand">
                <div v-if="currentStep === 2 && !pixGenerated" class="step-body">
                  <div class="payment-method selected mj-surface-2 mj-border">
                    <div class="method-info">
                      <div class="pix-icon-wrap"><v-icon color="#32BCAD" size="28">mdi-clover</v-icon></div>
                      <div>
                        <strong>PIX (Liberação Imediata)</strong>
                        <span>O arquivo em alta resolução (PSD) será liberado na mesma hora.</span>
                      </div>
                    </div>
                    <v-icon color="primary" size="24">mdi-check-circle</v-icon>
                  </div>

                  <div class="security-badge mt-4">
                    <v-icon size="18" color="success">mdi-shield-lock-outline</v-icon>
                    Transação 100% segura. Suas informações são criptografadas.
                  </div>

                  <v-btn color="success" size="x-large" block class="continue-btn mt-6 generate-pix-btn" @click="generateRealPixTransaction" :loading="isGeneratingPix">
                    <v-icon start size="22">mdi-qrcode-scan</v-icon>
                    Gerar Código PIX
                  </v-btn>
                </div>
              </transition>

              <transition name="fade">
                <div v-if="pixGenerated && paymentStatus === 'pending'" class="pix-massive-area">
                  <div class="pix-massive-header">
                    <v-icon color="#32BCAD" size="42">mdi-clover</v-icon>
                    <h3>Pagamento via PIX</h3>
                    <p>O seu código foi gerado com sucesso. Escaneie o QR Code abaixo ou utilize o Pix Copia e Cola para finalizar a compra do seu arquivo digital.</p>
                  </div>

                  <div class="pix-massive-content">
                    <div class="qr-code-showcase">
                      <div class="qr-frame">
                        <qrcode-vue
                          v-if="pixCopyPaste"
                          :value="pixCopyPaste"
                          :size="260"
                          level="M"
                          render-as="svg"
                        />
                        <v-progress-circular v-else indeterminate color="primary" size="48"></v-progress-circular>
                      </div>
                      <div class="qr-value">
                        <span>Valor a pagar:</span>
                        <strong>R$ {{ formatPrice(activeStamp.digital_price || 190.00) }}</strong>
                      </div>
                    </div>

                    <div class="copy-paste-showcase">
                      <label>Pix Copia e Cola</label>
                      <div class="copy-input-group">
                        <input type="text" :value="pixCopyPaste" readonly class="copy-input-massive" @click="copyPixCode" />
                        <v-btn color="primary" class="copy-btn-massive" @click="copyPixCode" elevation="0">
                          <v-icon start>mdi-content-copy</v-icon> COPIAR
                        </v-btn>
                      </div>
                    </div>
                  </div>

                  <div class="polling-indicator mj-surface-2 mj-border">
                    <v-progress-circular indeterminate color="primary" size="24" width="3" />
                    <div>
                      <strong>Aguardando confirmação do banco...</strong>
                      <span>Esta tela será atualizada automaticamente assim que o pagamento for reconhecido.</span>
                    </div>
                  </div>
                </div>
              </transition>

              <transition name="expand">
                <div v-if="paymentStatus === 'paid'" class="step-body success-area text-center">
                  <div class="success-animation">
                    <v-icon size="96" color="success">mdi-check-circle</v-icon>
                  </div>
                  <h3 class="success-title">Pagamento Confirmado!</h3>
                  <p class="success-subtitle">Sua estampa digital já está liberada. Você pode acessá-la a qualquer momento na sua biblioteca.</p>

                  <div class="success-actions">
                    <v-btn color="primary" size="x-large" block prepend-icon="mdi-folder-download-outline" class="font-weight-bold" @click="router.push('/marketplace/perfil')">
                      Ir para Minha Biblioteca
                    </v-btn>
                    <v-btn variant="text" color="primary" size="large" block class="mt-3 font-weight-bold" @click="router.push('/marketplace/descobrir')">
                      Continuar Explorando
                    </v-btn>
                  </div>
                </div>
              </transition>

            </section>
          </div>
        </main>

        <aside class="checkout-sidebar" :class="{ 'd-none': pixGenerated && paymentStatus !== 'paid' }">
          <div class="summary-card mj-surface mj-border">
            <h3 class="summary-title">Resumo do Arquivo</h3>

            <div class="summary-item">
              <div class="item-image-wrap">
                <img :src="activeStamp.main_image_url || '/placeholder.png'" alt="Estampa" class="item-image" />
                <span class="item-qty-badge">1</span>
              </div>
              <div class="item-details">
                <span class="item-ref">{{ activeStamp.ref_code }}</span>
                <h4 class="item-name">{{ activeStamp.title }}</h4>
                <p class="item-type">Arquivo Digital (PSD Alta Resolução)</p>
              </div>
              <div class="item-price text-right">
                R$ {{ formatPrice(activeStamp.digital_price || 190.00) }}
              </div>
            </div>

            <div class="summary-divider mj-border"></div>

            <div class="summary-totals">
              <div class="total-row subtotal">
                <span>Subtotal</span>
                <span>R$ {{ formatPrice(activeStamp.digital_price || 190.00) }}</span>
              </div>
              <div class="total-row total">
                <span>Total a pagar</span>
                <span class="total-highlight">R$ {{ formatPrice(activeStamp.digital_price || 190.00) }}</span>
              </div>
              <p class="taxes-notice">Impostos inclusos. Nenhuma taxa adicional será cobrada.</p>
            </div>
          </div>
        </aside>

      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { supabase } from '@/api/supabase'
import QrcodeVue from 'qrcode.vue'

// Integração com o Banco Cora Proxy
import { coraApi } from '@/api/coraProxy'

const router = useRouter()
const route = useRoute()

// Chave da Empresa Oficial para receber o dinheiro (Igual ao NewOrder)
const MR_JACKY_CORA_ID = 'int-3VpXneDbEmHHHYFNN8hoIh'

// Estado
const isLoading = ref(true)
const currentStep = ref(1)
const paymentStatus = ref<'pending' | 'paid' | 'failed'>('pending')
const isGeneratingPix = ref(false)
const pixGenerated = ref(false)
const pixCopyPaste = ref('')
const coraInvoiceId = ref('')
const transactionId = ref<string | null>(null)
let pollingInterval: any = null

// Dados
const activeStamp = ref<any>(null)
const customerData = ref({
  email: '',
  name: '',
  document: '',
  phone: ''
})

onMounted(async () => {
  isLoading.value = true

  try {
    const { data: { session } } = await supabase.auth.getSession()
    if (!session) {
      router.push('/marketplace-login')
      return
    }
    customerData.value.email = session.user.email || ''

    const { data: leadData } = await supabase
      .from('public_leads')
      .select('*')
      .eq('email', customerData.value.email)
      .maybeSingle()

    if (leadData) {
      customerData.value.name = leadData.name || ''
      customerData.value.document = leadData.document || ''
      customerData.value.phone = leadData.phone || ''
    }

    const stampId = route.query.digital_stamp
    if (!stampId) {
      isLoading.value = false
      return
    }

    const { data: stampData } = await supabase
      .from('catalog_stamps')
      .select('*')
      .eq('id', stampId)
      .maybeSingle()

    if (stampData) {
      activeStamp.value = stampData
    }

  } catch (error) {
    console.error('Erro no checkout:', error)
  } finally {
    isLoading.value = false
  }
})

onUnmounted(() => {
  if (pollingInterval) clearInterval(pollingInterval)
})

function formatPrice(value: number) {
  return Number(value || 0).toLocaleString('pt-BR', { minimumFractionDigits: 2, maximumFractionDigits: 2 })
}

async function proceedToPayment() {
  if (!customerData.value.name || !customerData.value.document) {
    alert('Preencha o Nome e CPF/CNPJ para emitir a cobrança.')
    return
  }

  await supabase.from('public_leads')
    .upsert({
      email: customerData.value.email,
      name: customerData.value.name,
      document: customerData.value.document,
      phone: customerData.value.phone
    }, { onConflict: 'email' })

  currentStep.value = 2
}

// === GERAÇÃO DO PIX E PONTE COM O ARQUIVO ===
async function generateRealPixTransaction() {
  isGeneratingPix.value = true

  try {
    const price = activeStamp.value.digital_price || 190.00
    const priceInCents = Math.round(price * 100)
    const cleanDocument = customerData.value.document.replace(/\D/g, '')

    // 1. A PONTE VITAL: Salva a compra para o cliente e pega a URL secreta.
    const { data: purchaseData, error: dbError } = await supabase.from('digital_purchases').insert({
      client_email: customerData.value.email,
      stamp_id: activeStamp.value.id,
      status: 'pending',
      price_paid: price,
      file_url: activeStamp.value.digital_file_url
    }).select('id').single()

    if (dbError) throw dbError
    transactionId.value = purchaseData.id

    // 2. Chama a Cora para gerar o PIX passando a chave da MR JACKY explícita
    const coraResponse = await coraApi.generatePix({
      amount: priceInCents,
      code: `DIG-${transactionId.value.substring(0,8)}`, // Evita IDs muito grandes pro banco
      customer: {
        name: customerData.value.name,
        identity: cleanDocument
      }
    }, MR_JACKY_CORA_ID); // <--- CHAVE EXATA DE QUEM RECEBE O DINHEIRO

    if (!coraResponse) {
      throw new Error('Retorno vazio da API Cora.')
    }

    // 3. Pega a String do Copia e Cola independente do formato da Cora
    pixCopyPaste.value = coraResponse.emv || coraResponse.payment_options?.pix?.emv || '';
    coraInvoiceId.value = coraResponse.id || '';

    pixGenerated.value = true

    // 4. Inicia o Polling com a configuração de segurança exata
    startPixPolling()

  } catch (error: any) {
    console.error('Erro ao gerar PIX:', error)
    alert(`Falha na comunicação com o banco: ${error.message}`)
  } finally {
    isGeneratingPix.value = false
  }
}

async function copyPixCode() {
  try {
    await navigator.clipboard.writeText(pixCopyPaste.value)
    alert('✅ Código PIX copiado com sucesso! Abra o app do seu banco e cole.')
  } catch (err) {
    console.error('Falha ao copiar', err)
  }
}

// Polling verificando a fatura na Cora com a Chave de Cliente
function startPixPolling() {
  if (!coraInvoiceId.value) return

  if (pollingInterval) clearInterval(pollingInterval)

  pollingInterval = setInterval(async () => {
    if (paymentStatus.value === 'paid') {
      clearInterval(pollingInterval)
      return
    }

    try {
      // Passando a chave para o Proxy poder consultar a fatura correta!
      const res = await coraApi.checkStatus(coraInvoiceId.value, MR_JACKY_CORA_ID);

      if (res && res.status === 'PAID') {
        paymentStatus.value = 'paid'
        clearInterval(pollingInterval)
        await confirmPaymentInDatabase()
      }
    } catch (e) {
      console.warn('Erro no polling do PIX', e)
    }
  }, 4000)
}

// === LÓGICA CONSOLIDADA NO BANCO DE DADOS (Liberar Cliente + Financeiro ERP) ===
async function confirmPaymentInDatabase() {
  if (!transactionId.value) return
  try {
    // 1. Libera o Arquivo pro Cliente baixar
    await supabase.from('digital_purchases').update({
      status: 'paid'
    }).eq('id', transactionId.value)

    // 2. INJETA NO ERP FINANCEIRO (Exatamente como no OrderPaymentsModal)
    const price = activeStamp.value.digital_price || 190.00;

    // Busca os dados padrões no banco do ERP
    const { data: accounts } = await supabase.from('finance_accounts').select('id').ilike('name', '%cora%').limit(1).maybeSingle();
    const { data: methods } = await supabase.from('finance_payment_methods').select('id').ilike('name', '%pix%').limit(1).maybeSingle();
    const { data: cats } = await supabase.from('finance_chart_of_accounts').select('id').ilike('name', '%venda%').limit(1).maybeSingle();
    const { data: mrJacky } = await supabase.from('companies').select('id').ilike('name', '%jacky%').limit(1).maybeSingle();

    const today = new Date().toISOString().split('T')[0];

    await supabase.from('finance_receivables').insert({
        description: `Venda Digital - Estampa ${activeStamp.value.ref_code}`,
        value: price,
        paid_value: price,
        status: 'pago',
        due_date: today,
        payment_date: today,
        receipt_date: today,
        paid_at: new Date().toISOString(),
        bank_account_id: accounts?.id || null,
        payment_method_id: methods?.id || null,
        chart_of_accounts_id: cats?.id || null,
        company_id: mrJacky?.id || null,
        entity_name: customerData.value.name,
        notes: `Venda Automática gerada pelo Marketplace (ID Compra Digital: ${transactionId.value.substring(0,8)})`
    });

  } catch (e) {
    console.error('Erro crítico ao consolidar pagamento na base', e)
  }
}
</script>

<style scoped>
/* =========================================================
   ESTILOS PREMIUM CHECKOUT
========================================================= */

.checkout-layout {
  min-height: 100vh;
  background: var(--bg-main);
  color: var(--text-main);
  padding-top: 82px;
}

.loading-screen, .error-screen {
  min-height: calc(100vh - 82px);
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  text-align: center;
  gap: 16px;
}

.error-icon-wrap {
  width: 90px;
  height: 90px;
  border-radius: 24px;
  background: rgba(239, 68, 68, 0.1);
  display: grid;
  place-items: center;
  margin-bottom: 8px;
}

.error-btn {
  border-radius: 14px !important;
  font-weight: 800 !important;
  letter-spacing: 0.02em;
}

.checkout-container {
  width: min(1280px, 100%);
  margin: 0 auto;
  padding: 0;
}

.checkout-grid {
  display: grid;
  grid-template-columns: 1fr 440px;
  min-height: calc(100vh - 82px);
  transition: all 0.4s ease;
}

.checkout-grid.pix-active {
  grid-template-columns: 1fr;
  max-width: 800px;
  margin: 0 auto;
}

.checkout-main {
  padding: 48px 64px 80px;
  border-right: 1px solid var(--border-color);
  background: var(--bg-main);
}

.checkout-grid.pix-active .checkout-main {
  border-right: none;
  padding: 48px 24px 80px;
}

.checkout-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 48px;
}

.brand-area {
  display: flex;
  align-items: center;
  gap: 12px;
  cursor: pointer;
}

.brand-text {
  font-size: 1.5rem;
  font-weight: 900;
  letter-spacing: -0.02em;
  color: var(--text-main);
}

.checkout-steps {
  display: flex;
  flex-direction: column;
  gap: 24px;
}

.step-card {
  border-radius: 24px;
  padding: 32px;
  transition: all 0.3s ease;
}

.step-card.pix-modal-mode {
  padding: 0;
  background: transparent;
  border: none;
  box-shadow: none;
}

.step-done {
  opacity: 0.6;
}

.step-done:hover {
  opacity: 1;
}

.step-active {
  box-shadow: 0 0 0 2px rgba(var(--v-theme-primary), 0.5);
}

.step-success {
  box-shadow: 0 0 0 2px #10b981;
}

.step-header {
  display: flex;
  align-items: center;
  gap: 16px;
}

.step-number {
  width: 32px;
  height: 32px;
  border-radius: 50%;
  background: var(--text-main);
  color: var(--bg-main);
  display: grid;
  place-items: center;
  font-size: 15px;
  font-weight: 900;
}

.success-icon {
  background: #10b981;
  color: #fff;
}

.step-title {
  margin: 0;
  font-size: 1.3rem;
  font-weight: 900;
  flex: 1;
  letter-spacing: -0.01em;
}

.step-body {
  margin-top: 28px;
  padding-left: 48px;
}

.step-summary {
  margin-top: 16px;
  padding-left: 48px;
  font-size: 1rem;
  color: var(--text-muted);
}

.form-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 20px;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.form-group.full-width {
  grid-column: 1 / -1;
}

.form-group label {
  font-size: 0.85rem;
  font-weight: 800;
  color: var(--text-main);
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.mj-input {
  height: 56px;
  padding: 0 16px;
  border-radius: 14px;
  font-size: 1.05rem;
  color: var(--text-main);
  outline: none;
  transition: all 0.2s;
}

.mj-input.disabled {
  background: var(--bg-surface);
  color: var(--text-muted);
  cursor: not-allowed;
}

.mj-input.active:focus {
  border-color: rgba(var(--v-theme-primary), 0.6);
  box-shadow: 0 0 0 4px rgba(var(--v-theme-primary), 0.1);
  background: var(--bg-surface);
}

.continue-btn {
  border-radius: 16px !important;
  font-weight: 900 !important;
  letter-spacing: 0.02em;
}

.payment-method {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 24px;
  border-radius: 20px;
  border: 2px solid transparent;
  cursor: pointer;
}

.payment-method.selected {
  border-color: rgb(var(--v-theme-primary));
  background: rgba(var(--v-theme-primary), 0.04);
}

.method-info {
  display: flex;
  align-items: center;
  gap: 16px;
}

.pix-icon-wrap {
  width: 48px;
  height: 48px;
  border-radius: 12px;
  background: rgba(50, 188, 173, 0.15);
  display: grid;
  place-items: center;
}

.method-info div {
  display: flex;
  flex-direction: column;
}

.method-info strong {
  font-size: 1.15rem;
  font-weight: 900;
  color: var(--text-main);
}

.method-info span {
  font-size: 0.9rem;
  color: var(--text-muted);
  margin-top: 4px;
}

.security-badge {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 10px;
  padding: 12px;
  border-radius: 12px;
  font-size: 0.9rem;
  color: var(--text-muted);
  font-weight: 700;
}

.generate-pix-btn {
  background: linear-gradient(135deg, #10b981, #059669) !important;
  color: white !important;
}

.pix-massive-area {
  display: flex;
  flex-direction: column;
  gap: 32px;
  animation: slideUp 0.5s cubic-bezier(0.16, 1, 0.3, 1);
}

@keyframes slideUp {
  from { opacity: 0; transform: translateY(40px); }
  to { opacity: 1; transform: translateY(0); }
}

.pix-massive-header {
  text-align: center;
  max-width: 600px;
  margin: 0 auto;
}

.pix-massive-header h3 {
  font-size: 2.2rem;
  font-weight: 900;
  color: var(--text-main);
  margin: 12px 0 8px;
  letter-spacing: -0.02em;
}

.pix-massive-header p {
  font-size: 1.05rem;
  color: var(--text-muted);
  line-height: 1.6;
}

.pix-massive-content {
  background: var(--bg-surface);
  border: 1px solid var(--border-color);
  border-radius: 32px;
  padding: 40px;
  box-shadow: var(--surface-shadow);
  display: flex;
  flex-direction: column;
  gap: 40px;
}

.qr-code-showcase {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 24px;
}

.qr-frame {
  padding: 20px;
  background: #ffffff;
  border-radius: 28px;
  border: 4px solid var(--border-strong);
  box-shadow: 0 20px 40px rgba(0,0,0,0.08);
  display: flex;
  align-items: center;
  justify-content: center;
  min-width: 300px;
  min-height: 300px;
}

.qr-value {
  display: flex;
  flex-direction: column;
  align-items: center;
  background: rgba(var(--v-theme-primary), 0.08);
  padding: 12px 32px;
  border-radius: 999px;
  border: 1px solid rgba(var(--v-theme-primary), 0.2);
}

.qr-value span {
  font-size: 0.85rem;
  font-weight: 800;
  color: rgb(var(--v-theme-primary));
  text-transform: uppercase;
  letter-spacing: 0.08em;
}

.qr-value strong {
  font-size: 1.8rem;
  font-weight: 900;
  color: var(--text-main);
  letter-spacing: -0.02em;
}

.copy-paste-showcase {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.copy-paste-showcase label {
  font-size: 1rem;
  font-weight: 800;
  color: var(--text-main);
  text-align: center;
}

.copy-input-group {
  display: flex;
  gap: 12px;
  background: var(--bg-surface-2);
  padding: 8px;
  border-radius: 20px;
  border: 1px solid var(--border-color);
}

.copy-input-massive {
  flex: 1;
  background: transparent;
  border: none;
  padding: 0 16px;
  font-family: monospace;
  font-size: 1rem;
  color: var(--text-muted);
  outline: none;
  cursor: text;
}

.copy-btn-massive {
  border-radius: 14px !important;
  font-weight: 900 !important;
  height: 52px !important;
  padding: 0 24px !important;
  letter-spacing: 0.05em;
}

.polling-indicator {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 16px;
  padding: 24px;
  border-radius: 20px;
  text-align: left;
}

.polling-indicator div {
  display: flex;
  flex-direction: column;
}

.polling-indicator strong {
  color: var(--text-main);
  font-size: 1.1rem;
  font-weight: 800;
}

.polling-indicator span {
  color: var(--text-muted);
  font-size: 0.9rem;
  margin-top: 4px;
}

.success-animation {
  margin-bottom: 24px;
  animation: scaleBounce 0.6s cubic-bezier(0.175, 0.885, 0.32, 1.275);
}

@keyframes scaleBounce {
  0% { transform: scale(0); }
  100% { transform: scale(1); }
}

.success-title {
  font-size: 2.4rem;
  font-weight: 900;
  color: var(--text-main);
  margin-bottom: 12px;
  letter-spacing: -0.02em;
}

.success-subtitle {
  color: var(--text-muted);
  font-size: 1.1rem;
  max-width: 460px;
  margin: 0 auto 40px;
  line-height: 1.6;
}

.success-actions {
  max-width: 360px;
  margin: 0 auto;
}

.checkout-sidebar {
  background: var(--bg-surface);
  padding: 48px;
  min-height: calc(100vh - 82px);
  transition: opacity 0.3s;
}

.summary-card {
  position: sticky;
  top: 120px;
  padding: 32px;
  border-radius: 24px;
  box-shadow: var(--surface-shadow);
}

.summary-title {
  font-size: 1.3rem;
  font-weight: 900;
  margin-bottom: 32px;
}

.summary-item {
  display: flex;
  gap: 16px;
  align-items: center;
}

.item-image-wrap {
  position: relative;
  width: 72px;
  height: 72px;
}

.item-image {
  width: 100%;
  height: 100%;
  object-fit: cover;
  border-radius: 14px;
  background: var(--bg-surface-2);
}

.item-qty-badge {
  position: absolute;
  top: -8px;
  right: -8px;
  background: rgba(var(--v-theme-primary), 0.9);
  color: #fff;
  width: 22px;
  height: 22px;
  border-radius: 50%;
  display: grid;
  place-items: center;
  font-size: 11px;
  font-weight: bold;
}

.item-details {
  flex: 1;
}

.item-ref {
  font-size: 0.75rem;
  font-weight: 800;
  color: var(--text-muted);
  letter-spacing: 0.1em;
  text-transform: uppercase;
}

.item-name {
  font-size: 1.05rem;
  font-weight: 800;
  margin: 2px 0 4px;
  color: var(--text-main);
  line-height: 1.2;
}

.item-type {
  font-size: 0.85rem;
  color: var(--text-muted);
}

.item-price {
  font-weight: 900;
  font-size: 1.1rem;
  color: var(--text-main);
}

.summary-divider {
  height: 1px;
  margin: 32px 0;
  border-bottom: 1px solid var(--border-color);
}

.summary-totals {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.total-row {
  display: flex;
  justify-content: space-between;
  font-size: 1rem;
  color: var(--text-main);
  font-weight: 700;
}

.total-row.total {
  margin-top: 12px;
  align-items: center;
}

.total-row.total span:first-child {
  font-size: 1.1rem;
  font-weight: 800;
}

.total-highlight {
  font-size: 2rem;
  font-weight: 900;
  letter-spacing: -0.02em;
}

.taxes-notice {
  font-size: 0.85rem;
  color: var(--text-muted);
  margin-top: 24px;
  text-align: center;
}

.expand-enter-active,
.expand-leave-active {
  transition: all 0.4s cubic-bezier(0.16, 1, 0.3, 1);
  max-height: 800px;
  opacity: 1;
  overflow: hidden;
}

.expand-enter-from,
.expand-leave-to {
  max-height: 0;
  opacity: 0;
  padding-top: 0;
  padding-bottom: 0;
  margin-top: 0;
}

@media (max-width: 1024px) {
  .checkout-grid {
    grid-template-columns: 1fr;
    display: flex;
    flex-direction: column-reverse;
  }

  .checkout-main {
    padding: 32px 24px;
    border-right: none;
  }

  .checkout-sidebar {
    padding: 32px 24px;
    border-bottom: 1px solid var(--border-color);
    background: var(--bg-surface-2);
    min-height: auto;
  }

  .summary-card {
    position: static;
    padding: 0;
    border: none;
    box-shadow: none;
    background: transparent;
  }
}

@media (max-width: 599px) {
  .form-grid { grid-template-columns: 1fr; }
  .step-body { padding-left: 0; }
  .step-summary { padding-left: 0; }
  .copy-input-group { flex-direction: column; padding: 12px; }
  .copy-input-group .v-btn { width: 100%; height: 56px !important; }
  .pix-massive-content { padding: 24px; }
  .qr-frame { min-width: 100%; }
  .polling-indicator { flex-direction: column; text-align: center; }
}
</style>
