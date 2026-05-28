<template>
  <v-dialog
    :model-value="show"
    @update:model-value="v => { if (!v) closeModal() }"
    max-width="800px"
    scrollable
  >
    <v-card class="glass-card rounded-xl">
      <v-card-title class="d-flex align-center pa-4 text-white header-glass-overlay">
        <v-avatar size="32" color="primary" class="mr-3 font-weight-bold text-caption">
            {{ client?.name?.charAt(0) || 'C' }}
        </v-avatar>
        <div>
            <div class="text-body-1 font-weight-bold">Histórico de Compras</div>
            <div class="text-caption text-white-50">{{ client?.name }}</div>
        </div>
        <v-spacer></v-spacer>
        <div class="text-right mr-4">
            <div class="text-caption text-white-50">Total Gasto</div>
            <div class="text-body-2 font-weight-black text-success">{{ formatCurrency(totalSpent) }}</div>
        </div>
        <v-btn icon="mdi-close" variant="text" size="small" color="white" class="opacity-70 hover-100" @click="closeModal"></v-btn>
      </v-card-title>

      <v-divider class="glass-divider"></v-divider>

      <v-card-text class="pa-0 custom-scrollbar">
         <div v-if="loading" class="d-flex justify-center align-center py-10">
             <v-progress-circular indeterminate color="primary" size="32"></v-progress-circular>
         </div>

         <div v-else-if="orders.length === 0" class="d-flex flex-column align-center justify-center py-10 text-white-50">
             <v-icon size="48" class="mb-2 opacity-30">mdi-cart-off</v-icon>
             <span class="text-caption">Nenhuma compra encontrada para este cliente.</span>
         </div>

         <v-table v-else density="compact" class="bg-transparent text-white">
            <thead>
                <tr class="bg-glass-header">
                    <th class="text-left text-caption text-white-50 pl-6">Data</th>
                    <th class="text-left text-caption text-white-50">Pedido</th>
                    <th class="text-center text-caption text-white-50">Pagamento</th>
                    <th class="text-right text-caption text-white-50 pr-6">Valor</th>
                </tr>
            </thead>
            <tbody>
                <tr v-for="order in orders" :key="order.id" class="hover-row border-b border-white-05">
                    <td class="pl-6 py-3">
                        <div class="text-body-2 font-weight-medium">{{ formatDate(order.created_at) }}</div>
                        <div class="text-caption text-white-50">{{ formatTime(order.created_at) }}</div>
                    </td>
                    <td>
                        <span class="text-caption font-mono text-primary font-weight-bold">#{{ order.order_number }}</span>
                    </td>
                    <td class="text-center">
                         <v-chip size="x-small" variant="tonal" class="text-uppercase font-weight-bold px-2" :color="getPaymentColor(order.payment_method)">
                             {{ order.payment_method }}
                         </v-chip>
                    </td>
                    <td class="text-right pr-6 text-body-2 font-weight-bold">{{ formatCurrency(order.total_value) }}</td>
                </tr>
            </tbody>
         </v-table>
      </v-card-text>

      <v-divider class="glass-divider"></v-divider>

      <v-card-actions class="pa-3 d-flex justify-end footer-glass-overlay">
         <v-btn color="white" variant="text" size="small" class="text-none opacity-70" @click="closeModal">Fechar</v-btn>
      </v-card-actions>

    </v-card>
  </v-dialog>
</template>

<script setup lang="ts">
import { ref, watch, computed } from 'vue';
import { supabase } from '@/api/supabase';
import { format } from 'date-fns';

const props = defineProps({
  show: Boolean,
  client: Object
});

const emit = defineEmits(['close']);
const orders = ref<any[]>([]);
const loading = ref(false);

const totalSpent = computed(() => {
    return orders.value.reduce((acc, curr) => acc + (Number(curr.total_value) || 0), 0);
});

const fetchClientHistory = async () => {
    if (!props.client?.name) return;

    loading.value = true;
    orders.value = [];

    try {
        // Busca pedidos locais pelo nome do cliente (já que IDs podem variar entre sistemas)
        const { data, error } = await supabase
            .from('cajuia_orders')
            .select('*')
            .ilike('customer_name', props.client.name.trim())
            .order('created_at', { ascending: false });

        if (!error && data) {
            orders.value = data;
        }
    } catch (e) {
        console.error("Erro ao buscar histórico", e);
    } finally {
        loading.value = false;
    }
};

watch(() => props.show, (newVal) => {
    if (newVal) fetchClientHistory();
});

const closeModal = () => emit('close');
const formatCurrency = (val: number) => new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(val || 0);
const formatDate = (dateString: string) => dateString ? format(new Date(dateString), 'dd/MM/yyyy') : '-';
const formatTime = (dateString: string) => dateString ? format(new Date(dateString), 'HH:mm') : '-';
const getPaymentColor = (method: string) => {
  const m = method?.toLowerCase() || '';
  if (m.includes('pix')) return 'teal';
  if (m.includes('dinheiro')) return 'green';
  return 'blue';
};
</script>

<style scoped>
.glass-card {
  backdrop-filter: blur(16px);
  background-color: rgba(20, 20, 25, 0.9);
  border: 1px solid rgba(255, 255, 255, 0.08);
  color: #fff;
}
.header-glass-overlay { background-color: rgba(255, 255, 255, 0.03); border-bottom: 1px solid rgba(255, 255, 255, 0.08); }
.footer-glass-overlay { background-color: rgba(20, 20, 25, 0.8); border-top: 1px solid rgba(255, 255, 255, 0.08); }
.glass-divider { border-color: rgba(255, 255, 255, 0.08) !important; }
.bg-glass-header { background: rgba(255, 255, 255, 0.05); }
.border-white-05 { border-color: rgba(255, 255, 255, 0.05) !important; }
.hover-row:hover { background: rgba(255, 255, 255, 0.03); }
.text-white-50 { color: rgba(255, 255, 255, 0.5) !important; }
.custom-scrollbar::-webkit-scrollbar { width: 6px; }
.custom-scrollbar::-webkit-scrollbar-track { background: transparent; }
.custom-scrollbar::-webkit-scrollbar-thumb { background: rgba(255, 255, 255, 0.15); border-radius: 3px; }
</style>
