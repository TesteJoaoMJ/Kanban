<template>
  <v-dialog
    :model-value="show"
    @update:model-value="$emit('update:show', $event)"
    max-width="700"
    scrollable
  >
    <v-card class="rounded-xl overflow-hidden bg-surface">
      <div class="px-6 py-4 bg-primary text-white d-flex align-center justify-space-between shadow-md">
        <div>
           <div class="d-flex align-center gap-2 mb-1">
              <v-icon size="20" color="white">mdi-cash-check</v-icon>
              <span class="text-subtitle-2 font-weight-bold uppercase letter-spacing-1">Baixa de Parcelas</span>
           </div>
           <div class="text-caption opacity-80">
              Pedido #{{ String(order?.order_number || '0000').padStart(4, '0') }} - {{ order?.customer_name }}
           </div>
        </div>
        <v-btn icon variant="text" density="compact" color="white" @click="$emit('close')">
           <v-icon>mdi-close</v-icon>
        </v-btn>
      </div>

      <v-card-text class="pa-0 bg-background">
         <div v-if="loading" class="d-flex justify-center align-center py-12">
             <v-progress-circular indeterminate color="primary" size="32"></v-progress-circular>
         </div>

         <div v-else-if="installments.length === 0" class="d-flex flex-column align-center justify-center py-12 text-medium-emphasis">
             <v-icon size="48" class="mb-2 opacity-50">mdi-cash-off</v-icon>
             <p class="text-caption">Nenhuma parcela encontrada para este pedido.</p>
         </div>

         <div v-else class="d-flex flex-column">
             <div
                v-for="(inst, index) in installments"
                :key="inst.id || index"
                class="px-6 py-4 border-b border-opacity-10 d-flex align-center justify-space-between transition-all hover:bg-surface-variant"
                :class="{ 'bg-green-lighten-5': inst.status === 'pago' }"
             >
                <div class="d-flex align-center gap-4">
                    <div class="d-flex flex-column align-center justify-center rounded-lg border pa-2 bg-surface" style="width: 60px;">
                        <span class="text-[10px] font-weight-bold text-uppercase text-medium-emphasis">{{ getMonth(inst.due_date) }}</span>
                        <span class="text-h6 font-weight-black lh-1">{{ getDay(inst.due_date) }}</span>
                    </div>

                    <div>
                        <div class="text-subtitle-2 font-weight-bold text-high-emphasis mb-0.5">
                            {{ inst.description || `Parcela ${index + 1}` }}
                        </div>
                        <div class="d-flex align-center gap-2 text-caption">
                            <v-chip size="x-small" :color="getStatusColor(inst.status)" variant="flat" class="font-weight-bold uppercase h-20">
                                {{ formatStatus(inst.status) }}
                            </v-chip>
                            <span class="text-medium-emphasis">{{ getPaymentMethodName(inst.payment_method_id) }}</span>
                        </div>
                    </div>
                </div>

                <div class="text-right">
                    <div class="text-subtitle-1 font-weight-black text-high-emphasis mb-1">
                        {{ formatCurrency(inst.value) }}
                    </div>

                    <div v-if="inst.status === 'pago'">
                        <div class="text-[10px] font-weight-bold text-success d-flex align-center justify-end gap-1">
                            <v-icon size="12">mdi-check-all</v-icon> Recebido
                        </div>
                        <div class="text-[9px] text-medium-emphasis mt-0.5">
                            em {{ formatDate(inst.payment_date) }}
                        </div>
                    </div>

                    <v-btn
                        v-else
                        size="small"
                        color="primary"
                        variant="flat"
                        class="font-weight-bold px-4"
                        prepend-icon="mdi-cash-plus"
                        @click="confirmPayment(inst)"
                        :loading="processingId === inst.id"
                        :disabled="!!processingId"
                    >
                        Receber
                    </v-btn>
                </div>
             </div>
         </div>
      </v-card-text>

      <div class="px-6 py-3 bg-surface border-t d-flex justify-end gap-2">
          <v-btn variant="text" color="medium-emphasis" @click="$emit('close')">Fechar</v-btn>
      </div>
    </v-card>

    <v-dialog v-model="confirmDialog" max-width="400" persistent>
        <v-card class="rounded-xl pa-4 text-center">
            <div class="icon-circle-lg bg-primary-lighten-5 text-primary mx-auto mb-4">
                <v-icon size="32">mdi-hand-coin</v-icon>
            </div>
            <h3 class="text-h6 font-weight-bold mb-2">Confirmar Recebimento?</h3>
            <p class="text-body-2 text-medium-emphasis mb-4">
                Você confirma o recebimento de <strong>{{ formatCurrency(selectedInst?.value) }}</strong> referente à parcela <strong>{{ selectedInst?.description }}</strong>?
            </p>
            <p class="text-caption text-grey mb-6">
                Essa ação irá lançar o valor no caixa e não poderá ser desfeita por aqui.
            </p>

            <div class="d-flex gap-3">
                <v-btn variant="outlined" block class="flex-grow-1" @click="confirmDialog = false" :disabled="isConfirming">Cancelar</v-btn>
                <v-btn color="success" variant="flat" block class="flex-grow-1 font-weight-bold" @click="processPayment" :loading="isConfirming">
                    Confirmar
                </v-btn>
            </div>
        </v-card>
    </v-dialog>

  </v-dialog>
</template>

<script setup lang="ts">
import { ref, watch, onMounted } from 'vue';
import { supabase } from '@/api/supabase';
import { useUserStore } from '@/stores/user';
import { useAppStore } from '@/stores/app';
import { format, parseISO } from 'date-fns';
import { ptBR } from 'date-fns/locale';

const props = defineProps<{
    show: boolean;
    order: any;
}>();

const emit = defineEmits(['update:show', 'close', 'refresh']);

const userStore = useUserStore();
const appStore = useAppStore();

const loading = ref(false);
const installments = ref<any[]>([]);
const paymentMethods = ref<any[]>([]);
const confirmDialog = ref(false);
const selectedInst = ref<any>(null);
const processingId = ref<string | null>(null);
const isConfirming = ref(false);

const fetchInstallments = async () => {
    if (!props.order?.id) return;
    loading.value = true;
    try {
        const { data, error } = await supabase
            .from('finance_receivables')
            .select('*')
            .eq('order_id', props.order.id)
            .order('due_date', { ascending: true });

        if (error) throw error;
        installments.value = data || [];

        const { data: methods } = await supabase.from('finance_payment_methods').select('id, name');
        paymentMethods.value = methods || [];

    } catch (e) {
        console.error("Erro ao buscar parcelas:", e);
        appStore.showSnackbar("Erro ao carregar parcelas.", "error");
    } finally {
        loading.value = false;
    }
};

const confirmPayment = (inst: any) => {
    selectedInst.value = inst;
    confirmDialog.value = true;
};

const processPayment = async () => {
    if (!selectedInst.value || !userStore.user?.id) return;
    isConfirming.value = true;
    processingId.value = selectedInst.value.id;

    try {
        const now = new Date().toISOString();
        const inst = selectedInst.value;

        // 1. Atualiza Recebível (PAGO)
        const { error: updateError } = await supabase
            .from('finance_receivables')
            .update({
                status: 'pago',
                payment_date: now,
                received_by: userStore.user.id,
                updated_at: now
            })
            .eq('id', inst.id);

        if (updateError) throw updateError;

        // 2. Insere Transação Financeira
        let targetAccountId = inst.bank_account_id;
        if (!targetAccountId) {
             const { data: defaultAcc } = await supabase.from('finance_accounts').select('id').eq('is_active', true).limit(1).maybeSingle();
             targetAccountId = defaultAcc?.id;
        }

        if (targetAccountId) {
            await supabase.from('finance_transactions').insert({
                account_id: targetAccountId,
                description: `Receb. Vendedor: ${inst.description} (Pedido #${props.order.order_number})`,
                amount: inst.value,
                type: 'INCOME',
                status: 'COMPLETED',
                transaction_date: now,
                created_by: userStore.user.id
            });

            await supabase.rpc('increment_account_balance', {
                p_account_id: targetAccountId,
                p_amount: inst.value
            });
        }

        // 3. Log de Auditoria
        await supabase.from('system_audit_logs').insert({
            action: 'payment_received',
            entity: 'finance_receivables',
            entity_id: inst.id,
            user_id: userStore.user.id,
            details: {
                order_number: props.order.order_number,
                amount: inst.value,
                method: getPaymentMethodName(inst.payment_method_id)
            }
        });

        // 4. NOTIFICAÇÃO PARA ADMINS/FINANCEIRO
        // Busca usuários com papel admin ou financeiro
        const { data: admins } = await supabase.from('profiles').select('id').or('role.eq.admin,role.eq.financeiro');
        if (admins && admins.length > 0) {
            const notificationsPayload = admins.map(admin => ({
                user_id: admin.id,
                title: 'Pagamento Confirmado',
                message: `O vendedor recebeu R$${formatCurrency(inst.value)} do Pedido #${props.order.order_number}.`,
                type: 'financial_alert',
                is_read: false
            }));
            // Insere na tabela 'notifications' (ou user_notifications, verifique seu schema)
            // Assumindo tabela 'notifications' geral
            await supabase.from('notifications').insert(notificationsPayload.map(n => ({
                recipient_id: n.user_id,
                content: `${n.title}: ${n.message}`,
                redirect_url: '/admin/financeiro/recebiveis'
            })));
        }

        appStore.showSnackbar("Pagamento confirmado e Admin notificado!", "success");
        confirmDialog.value = false;
        await fetchInstallments();
        emit('refresh');

    } catch (e: any) {
        console.error("Erro ao processar pagamento:", e);
        appStore.showSnackbar("Erro ao processar: " + e.message, "error");
    } finally {
        isConfirming.value = false;
        processingId.value = null;
        selectedInst.value = null;
    }
};

const getPaymentMethodName = (id: string) => {
    const m = paymentMethods.value.find(x => x.id === id);
    return m ? m.name : '---';
};

const getMonth = (dateStr: string) => dateStr ? format(parseISO(dateStr), 'MMM', { locale: ptBR }) : '-';
const getDay = (dateStr: string) => dateStr ? format(parseISO(dateStr), 'dd') : '-';
const formatDate = (dateStr: string) => dateStr ? format(parseISO(dateStr), 'dd/MM/yyyy HH:mm') : '-';
const formatCurrency = (val: number) => new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(val || 0);
const formatStatus = (s: string) => s === 'em_aberto' ? 'Aberto' : (s === 'pago' ? 'Pago' : s);
const getStatusColor = (s: string) => s === 'pago' ? 'success' : (s === 'atrasado' ? 'error' : 'warning');

watch(() => props.show, (val) => {
    if (val) fetchInstallments();
});
</script>

<style scoped>
.lh-1 { line-height: 1; }
.h-20 { height: 20px; }
.gap-2 { gap: 8px; }
.gap-4 { gap: 16px; }
.hover\:bg-surface-variant:hover { background-color: rgba(0,0,0,0.03); }
.icon-circle-lg { width: 64px; height: 64px; border-radius: 50%; display: flex; align-items: center; justify-content: center; }
</style>
