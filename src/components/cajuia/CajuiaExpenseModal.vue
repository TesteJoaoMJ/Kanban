<template>
  <v-dialog
    :model-value="modelValue"
    @update:model-value="$emit('update:modelValue', $event)"
    max-width="800"
    content-class="glass-dialog-expense"
    persistent
  >
    <v-card class="glass-modal-card">
      <div class="px-6 py-4 border-b border-white-10 bg-glass-header d-flex align-center justify-space-between">
        <div class="d-flex align-center gap-4">
           <div class="icon-box-lg bg-gradient-error elevation-10 pulsing-animation">
              <v-icon color="white" size="28">mdi-bank-minus</v-icon>
           </div>
           <div>
              <h3 class="text-h6 font-weight-black text-white lh-1">Nova Despesa / Conta</h3>
              <div class="text-caption text-white-50 mt-1 d-flex align-center gap-2">
                  <v-icon size="12" color="warning">mdi-alert-circle-outline</v-icon>
                  Preencha os dados para o fluxo de caixa
              </div>
           </div>
        </div>
        <div class="d-flex align-center gap-2">
            <v-chip size="small" variant="outlined" color="white" class="font-mono text-caption">
                {{ form.posting_date }}
            </v-chip>
            <v-btn icon variant="text" color="white-50" @click="close">
                <v-icon>mdi-close</v-icon>
            </v-btn>
        </div>
      </div>

      <div class="d-flex flex-grow-1">
          <div class="sidebar-steps pa-4 border-r border-white-10" style="width: 200px; background: rgba(0,0,0,0.2);">
              <v-list bg-color="transparent" density="compact" nav class="pa-0">
                  <v-list-item
                    value="basic"
                    :active="step === 1"
                    @click="step = 1"
                    rounded="lg"
                    active-class="bg-white-10 text-white font-weight-bold"
                    class="mb-1 text-white-50"
                  >
                      <template v-slot:prepend><v-icon size="small">mdi-file-document-outline</v-icon></template>
                      <v-list-item-title>Dados Básicos</v-list-item-title>
                  </v-list-item>

                  <v-list-item
                    value="recurrence"
                    :active="step === 2"
                    @click="step = 2"
                    rounded="lg"
                    active-class="bg-white-10 text-white font-weight-bold"
                    class="mb-1 text-white-50"
                  >
                      <template v-slot:prepend><v-icon size="small">mdi-repeat</v-icon></template>
                      <v-list-item-title>Recorrência</v-list-item-title>
                  </v-list-item>

                  <v-list-item
                    value="details"
                    :active="step === 3"
                    @click="step = 3"
                    rounded="lg"
                    active-class="bg-white-10 text-white font-weight-bold"
                    class="mb-1 text-white-50"
                  >
                      <template v-slot:prepend><v-icon size="small">mdi-paperclip</v-icon></template>
                      <v-list-item-title>Anexos & Obs</v-list-item-title>
                  </v-list-item>
              </v-list>

              <v-divider class="my-4 border-white-10"></v-divider>

              <div class="pa-3 rounded-lg bg-error-10 border border-error-20">
                  <span class="text-[10px] text-error font-weight-bold text-uppercase d-block mb-1">Total Previsto</span>
                  <span class="text-h6 font-weight-black text-white">{{ formatCurrency(totalPreview) }}</span>
                  <span class="text-[10px] text-white-50 d-block mt-1" v-if="installmentsList.length > 1">
                      {{ installmentsList.length }} lançamentos
                  </span>
              </div>
          </div>

          <div class="flex-grow-1 pa-6 bg-glass-body overflow-y-auto custom-scrollbar" style="max-height: 600px;">

              <v-window v-model="step">

                  <v-window-item :value="1">
                      <v-row dense>
                          <v-col cols="12">
                              <label class="text-caption text-white-50 font-weight-bold mb-1 d-block">Descrição da Despesa *</label>
                              <v-text-field
                                  v-model="form.description"
                                  placeholder="Ex: Compra de Material de Escritório"
                                  variant="outlined"
                                  density="compact"
                                  class="glass-input"
                                  bg-color="rgba(255,255,255,0.03)"
                                  hide-details="auto"
                              ></v-text-field>
                          </v-col>

                          <v-col cols="12" md="6">
                              <label class="text-caption text-white-50 font-weight-bold mb-1 d-block">Valor *</label>
                              <v-text-field
                                  v-model="form.amount"
                                  type="number"
                                  prefix="R$"
                                  placeholder="0,00"
                                  variant="outlined"
                                  density="compact"
                                  class="glass-input"
                                  bg-color="rgba(255,255,255,0.03)"
                                  hide-details="auto"
                              ></v-text-field>
                          </v-col>

                          <v-col cols="12" md="6">
                              <label class="text-caption text-white-50 font-weight-bold mb-1 d-block">Vencimento (1ª Parc) *</label>
                              <v-text-field
                                  v-model="form.due_date"
                                  type="date"
                                  variant="outlined"
                                  density="compact"
                                  class="glass-input"
                                  bg-color="rgba(255,255,255,0.03)"
                                  hide-details="auto"
                              ></v-text-field>
                          </v-col>

                          <v-col cols="12" md="6">
                              <label class="text-caption text-white-50 font-weight-bold mb-1 d-block">Plano de Contas (Categoria) *</label>
                              <v-select
                                  v-model="form.category_id"
                                  :items="categories"
                                  item-title="name"
                                  item-value="id"
                                  placeholder="Selecione..."
                                  variant="outlined"
                                  density="compact"
                                  class="glass-input"
                                  bg-color="rgba(255,255,255,0.03)"
                                  hide-details="auto"
                                  :loading="loadingCats"
                              >
                                  <template v-slot:item="{ props, item }">
                                      <v-list-item v-bind="props" :subtitle="item.raw.type === 'fixed' ? 'Despesa Fixa' : 'Despesa Variável'"></v-list-item>
                                  </template>
                              </v-select>
                          </v-col>

                          <v-col cols="12" md="6">
                              <label class="text-caption text-white-50 font-weight-bold mb-1 d-block">Conta de Saída (Prevista)</label>
                              <v-select
                                  v-model="form.bank_account_id"
                                  :items="bankAccounts"
                                  item-title="name"
                                  item-value="id"
                                  placeholder="Onde vai sair o dinheiro?"
                                  variant="outlined"
                                  density="compact"
                                  class="glass-input"
                                  bg-color="rgba(255,255,255,0.03)"
                                  hide-details="auto"
                              ></v-select>
                          </v-col>

                          <v-col cols="12">
                              <v-divider class="my-4 border-white-10"></v-divider>
                              <div class="d-flex align-center justify-space-between mb-2">
                                  <label class="text-caption text-white-50 font-weight-bold">Fornecedor / Favorecido</label>
                                  <span class="text-[10px] text-primary cursor-pointer font-weight-bold hover-underline">Cadastrar Novo</span>
                              </div>
                              <v-row dense>
                                  <v-col cols="8">
                                      <v-text-field
                                          v-model="form.supplier_name"
                                          placeholder="Nome ou Razão Social"
                                          variant="outlined"
                                          density="compact"
                                          class="glass-input"
                                          bg-color="rgba(255,255,255,0.03)"
                                          hide-details="auto"
                                          prepend-inner-icon="mdi-account-tie"
                                      ></v-text-field>
                                  </v-col>
                                  <v-col cols="4">
                                      <v-text-field
                                          v-model="form.supplier_doc"
                                          placeholder="CPF/CNPJ"
                                          variant="outlined"
                                          density="compact"
                                          class="glass-input"
                                          bg-color="rgba(255,255,255,0.03)"
                                          hide-details="auto"
                                          v-maska="['###.###.###-##', '##.###.###/####-##']"
                                      ></v-text-field>
                                  </v-col>
                              </v-row>
                          </v-col>
                      </v-row>
                  </v-window-item>

                  <v-window-item :value="2">
                      <div class="glass-well pa-4 rounded-lg mb-4 border border-white-05">
                          <v-radio-group v-model="form.recurrence_type" inline hide-details class="mb-2">
                              <v-radio value="single" label="Lançamento Único" color="primary"></v-radio>
                              <v-radio value="installments" label="Parcelado (Ex: 12x)" color="warning"></v-radio>
                              <v-radio value="recurrent" label="Recorrente (Assinatura/Fixo)" color="info"></v-radio>
                          </v-radio-group>
                      </div>

                      <div v-if="form.recurrence_type === 'installments'" class="animation-fade-in">
                          <v-row dense>
                              <v-col cols="12" md="6">
                                  <v-text-field
                                      v-model.number="form.installments_count"
                                      label="Nº de Parcelas"
                                      type="number"
                                      min="2"
                                      max="48"
                                      variant="outlined"
                                      density="compact"
                                      class="glass-input"
                                  ></v-text-field>
                              </v-col>
                              <v-col cols="12" md="6">
                                  <v-select
                                      v-model="form.frequency"
                                      :items="frequencyOptions"
                                      label="Periodicidade"
                                      variant="outlined"
                                      density="compact"
                                      class="glass-input"
                                  ></v-select>
                              </v-col>
                          </v-row>
                      </div>

                      <div v-if="form.recurrence_type === 'recurrent'" class="animation-fade-in">
                          <v-alert type="info" variant="tonal" density="compact" class="mb-4 text-caption border-opacity-20">
                              Isso vai projetar lançamentos futuros para controle de fluxo de caixa.
                          </v-alert>
                          <v-row dense>
                              <v-col cols="12" md="6">
                                  <v-select
                                      v-model="form.frequency"
                                      :items="frequencyOptions"
                                      label="Repetir a cada"
                                      variant="outlined"
                                      density="compact"
                                      class="glass-input"
                                  ></v-select>
                              </v-col>
                              <v-col cols="12" md="6">
                                  <v-text-field
                                      v-model.number="form.recurrence_limit"
                                      label="Projetar por (meses)"
                                      type="number"
                                      min="1"
                                      max="60"
                                      variant="outlined"
                                      density="compact"
                                      class="glass-input"
                                  ></v-text-field>
                              </v-col>
                          </v-row>
                      </div>

                      <div class="mt-4" v-if="installmentsList.length > 0">
                          <label class="text-caption text-white-50 font-weight-bold mb-2 d-block">Pré-visualização dos Lançamentos</label>
                          <div class="bg-black-20 rounded-lg overflow-hidden border border-white-05" style="max-height: 250px; overflow-y: auto;">
                              <div v-for="(item, index) in installmentsList" :key="index" class="d-flex justify-space-between align-center px-3 py-2 border-b border-white-05">
                                  <div class="d-flex align-center gap-2">
                                      <span class="text-[10px] bg-white-10 px-1 rounded text-white-70">{{ index + 1 }}</span>
                                      <span class="text-caption text-white">{{ item.description }}</span>
                                  </div>
                                  <div class="d-flex align-center gap-4">
                                      <span class="text-caption font-mono text-white-50">{{ formatDate(item.due_date) }}</span>
                                      <span class="text-body-2 font-weight-bold text-white">{{ formatCurrency(item.amount) }}</span>
                                  </div>
                              </div>
                          </div>
                      </div>
                  </v-window-item>

                  <v-window-item :value="3">
                      <v-textarea
                          v-model="form.notes"
                          label="Observações Internas"
                          variant="outlined"
                          class="glass-input mb-4"
                          rows="3"
                          placeholder="Detalhes sobre a compra, número da NF, etc."
                      ></v-textarea>

                      <div class="upload-zone pa-6 rounded-xl border-dashed border-white-20 text-center cursor-pointer hover-bg-white-05 transition-all">
                          <v-icon size="32" color="white-30" class="mb-2">mdi-cloud-upload-outline</v-icon>
                          <div class="text-caption text-white-50">Clique ou arraste o comprovante/boleto aqui</div>
                          </div>
                  </v-window-item>
              </v-window>
          </div>
      </div>

      <div class="px-6 py-4 border-t border-white-10 bg-glass-header d-flex justify-space-between align-center">
          <v-btn v-if="step > 1" variant="text" color="white-50" @click="step--">Voltar</v-btn>
          <div v-else></div>

          <div class="d-flex gap-2">
              <v-btn v-if="step < 3" color="primary" variant="flat" @click="step++">Próximo</v-btn>
              <v-btn v-else color="success" variant="flat" class="font-weight-bold shadow-glow-success px-6" :loading="saving" @click="save">
                  <v-icon start>mdi-check</v-icon> Confirmar Lançamento
              </v-btn>
          </div>
      </div>
    </v-card>
  </v-dialog>
</template>

<script setup lang="ts">
import { ref, computed, watch, onMounted } from 'vue'
import { supabase } from '@/api/supabase'
import { format, addMonths, addWeeks, parseISO } from 'date-fns'
import { vMaska } from "maska/vue"

const props = defineProps(['modelValue'])
const emit = defineEmits(['update:modelValue', 'saved'])

// State
const step = ref(1)
const saving = ref(false)
const categories = ref<any[]>([])
const bankAccounts = ref<any[]>([])
const loadingCats = ref(false)

const form = ref({
    description: '',
    amount: '',
    due_date: format(new Date(), 'yyyy-MM-dd'),
    posting_date: format(new Date(), 'dd/MM/yyyy'),
    category_id: null,
    bank_account_id: null,
    supplier_name: '',
    supplier_doc: '',
    notes: '',
    recurrence_type: 'single', // single, installments, recurrent
    installments_count: 2,
    frequency: 'monthly',
    recurrence_limit: 12
})

const frequencyOptions = [
    { title: 'Mensal', value: 'monthly' },
    { title: 'Semanal', value: 'weekly' },
    { title: 'Anual', value: 'yearly' }
]

// Computed Lógica de Parcelas
const installmentsList = computed(() => {
    const list = []
    const amount = Number(form.value.amount) || 0
    if (amount <= 0) return []

    const baseDate = form.value.due_date ? parseISO(form.value.due_date) : new Date()

    if (form.value.recurrence_type === 'single') {
        list.push({
            description: form.value.description,
            due_date: baseDate,
            amount: amount,
            installment: 1,
            total: 1
        })
    }
    else if (form.value.recurrence_type === 'installments') {
        const count = Math.max(2, Number(form.value.installments_count))
        const installmentValue = amount / count // Valor total dividido

        for (let i = 0; i < count; i++) {
            let date = baseDate
            if (form.value.frequency === 'monthly') date = addMonths(baseDate, i)
            if (form.value.frequency === 'weekly') date = addWeeks(baseDate, i)

            list.push({
                description: `${form.value.description} (${i+1}/${count})`,
                due_date: date,
                amount: installmentValue,
                installment: i + 1,
                total: count
            })
        }
    }
    else if (form.value.recurrence_type === 'recurrent') {
        const count = Math.max(1, Number(form.value.recurrence_limit))
        // No recorrente, o valor é FIXO por mês (ex: Aluguel)

        for (let i = 0; i < count; i++) {
            let date = baseDate
            if (form.value.frequency === 'monthly') date = addMonths(baseDate, i)

            list.push({
                description: `${form.value.description} - Ref. ${format(date, 'MM/yyyy')}`,
                due_date: date,
                amount: amount,
                installment: i + 1,
                total: count
            })
        }
    }
    return list
})

const totalPreview = computed(() => {
    return installmentsList.value.reduce((acc, item) => acc + item.amount, 0)
})

// Hooks
watch(() => props.modelValue, (val) => {
    if(val) {
        resetForm()
        if(categories.value.length === 0) loadData()
    }
})

const loadData = async () => {
    loadingCats.value = true
    const [cats, banks] = await Promise.all([
        supabase.from('cajuia_expense_categories').select('*').order('name'),
        supabase.from('cajuia_bank_accounts').select('*').eq('is_active', true)
    ])
    categories.value = cats.data || []
    bankAccounts.value = banks.data || []
    loadingCats.value = false
}

const resetForm = () => {
    step.value = 1
    form.value = {
        description: '', amount: '', due_date: format(new Date(), 'yyyy-MM-dd'), posting_date: format(new Date(), 'dd/MM/yyyy'),
        category_id: null, bank_account_id: null, supplier_name: '', supplier_doc: '', notes: '',
        recurrence_type: 'single', installments_count: 2, frequency: 'monthly', recurrence_limit: 12
    }
}

const save = async () => {
    if(!form.value.description || !form.value.amount) return
    saving.value = true
    try {
        const payload = installmentsList.value.map(inst => ({
            description: inst.description,
            amount: inst.amount,
            due_date: inst.due_date.toISOString(),
            category_id: form.value.category_id,
            bank_account_id: form.value.bank_account_id,
            supplier_name: form.value.supplier_name,
            notes: form.value.notes,
            status: 'PENDING',
            installment_number: inst.installment,
            total_installments: inst.total
        }))

        const { error } = await supabase.from('cajuia_payables').insert(payload)
        if(error) throw error

        emit('saved')
        close()
    } catch(e) {
        console.error(e)
        alert('Erro ao salvar despesas.')
    } finally {
        saving.value = false
    }
}

const close = () => emit('update:modelValue', false)
const formatCurrency = (v: number) => new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(v)
const formatDate = (d: Date) => format(d, 'dd/MM/yyyy')
</script>

<style scoped lang="scss">
.glass-dialog-expense { backdrop-filter: blur(10px); }
.glass-modal-card { background: #121212; border: 1px solid rgba(255,255,255,0.1); border-radius: 16px; display: flex; flex-direction: column; max-height: 90vh; }
.bg-glass-header { background: rgba(255,255,255,0.03); }
.bg-glass-body { background: linear-gradient(to right, rgba(0,0,0,0.2), transparent); }

/* Sidebar Steps */
.sidebar-steps { height: 100%; display: flex; flex-direction: column; }

/* Form inputs */
.glass-input :deep(.v-field) { border-radius: 8px; border: 1px solid rgba(255,255,255,0.1); color: white; font-size: 0.85rem; }
.glass-well { background: rgba(255,255,255,0.02); }

/* Icons & Colors */
.icon-box-lg { width: 48px; height: 48px; border-radius: 12px; display: flex; align-items: center; justify-content: center; }
.bg-gradient-error { background: linear-gradient(135deg, #ff5252, #b71c1c); }
.bg-error-10 { background: rgba(255, 82, 82, 0.1); }
.border-error-20 { border-color: rgba(255, 82, 82, 0.2) !important; }
.border-white-10 { border-color: rgba(255,255,255,0.1) !important; }
.text-white-50 { color: rgba(255,255,255,0.5) !important; }

.hover-bg-white-05:hover { background: rgba(255,255,255,0.05); }
.custom-scrollbar::-webkit-scrollbar { width: 6px; }
.custom-scrollbar::-webkit-scrollbar-thumb { background: rgba(255,255,255,0.15); border-radius: 4px; }

.pulsing-animation { animation: pulse 2s infinite; }
@keyframes pulse { 0% { box-shadow: 0 0 0 0 rgba(255, 82, 82, 0.4); } 70% { box-shadow: 0 0 0 10px rgba(255, 82, 82, 0); } 100% { box-shadow: 0 0 0 0 rgba(255, 82, 82, 0); } }
</style>
