<template>
  <v-dialog v-model="internalShow" max-width="1400px" persistent class="glassmorphism-card-dialog">
    <v-card>
      <v-toolbar color="transparent">
        <v-toolbar-title class="font-weight-bold d-flex align-center">
          <v-icon start color="purple-lighten-2">mdi-factory</v-icon>
          Pedidos em Aberto (Produção)
        </v-toolbar-title>
        <v-spacer></v-spacer>
        <v-chip color="purple-lighten-2" class="mr-4">
          {{ orders.length }} Pedidos | {{ formatNumber(totalMeters) }}m
        </v-chip>
        <v-btn icon="mdi-close" @click="$emit('close')"></v-btn>
      </v-toolbar>
      <v-divider></v-divider>

      <v-card-text style="max-height: 80vh; overflow-y: auto;" class="custom-scrollbar">
        <v-container fluid>
          <div v-if="orders.length === 0" class="text-center pa-16 text-medium-emphasis">
            <v-icon size="64" class="mb-4">mdi-check-all</v-icon>
            <h3 class="text-h6">Nenhum pedido em aberto!</h3>
            <p>A fila de produção está vazia no momento.</p>
          </div>

          <v-row dense>
            <v-col
              v-for="order in orders"
              :key="order.id"
              cols="12"
              sm="6"
              md="4"
              lg="3"
            >
              <v-card
                class="order-card-production"
                variant="outlined"
                @click="openDetail(order)"
              >
                <div class="card-status-bar" :style="{ backgroundColor: getStatusInfo(order.status).color }"></div>
                <v-card-title class="pb-2 d-flex align-start">
                  <div>
                    <div class="text-caption text-medium-emphasis">#{{ String(order.order_number).padStart(4, '0') }}</div>
                    <div class="text-body-1 font-weight-bold">{{ order.customer_name }}</div>
                  </div>
                  <v-spacer></v-spacer>
                  <v-chip size="small" :color="getStatusInfo(order.status).color" variant="tonal">
                    {{ getStatusInfo(order.status).text }}
                  </v-chip>
                </v-card-title>

                <v-card-text>
                  <v-list-item density="compact" class="pa-0 mb-2">
                    <template v-slot:prepend>
                      <v-icon size="small">mdi-account-tie-outline</v-icon>
                    </template>
                    <v-list-item-title class="text-caption">{{ order.creator?.full_name || 'N/A' }}</v-list-item-title>
                  </v-list-item>

                  <v-list-item density="compact" class="pa-0 mb-2">
                    <template v-slot:prepend>
                      <v-icon size="small">mdi-calendar-start-outline</v-icon>
                    </template>
                    <v-list-item-title class="text-caption">Lançado em: {{ formatDate(order.created_at) }}</v-list-item-title>
                  </v-list-item>

                  <v-divider class="my-3"></v-divider>

                  <div class="d-flex justify-space-between align-center">
                    <div class="text-medium-emphasis text-caption">Metragem Total:</div>
                    <div class="text-h6 font-weight-bold">{{ formatNumber(order.quantity_meters) }}m</div>
                  </div>

                  <div class="mt-2">
                    <div class="text-medium-emphasis text-caption mb-1">Bases no Pedido:</div>
                    <v-chip-group>
                      <v-chip
                        v-for="fabric in getOrderFabrics(order)"
                        :key="fabric"
                        size="x-small"
                        color="blue-grey"
                        variant="tonal"
                      >
                        {{ fabric }}
                      </v-chip>
                    </v-chip-group>
                  </div>

                </v-card-text>
              </v-card>
            </v-col>
          </v-row>
        </v-container>
      </v-card-text>
    </v-card>

    <OrderDetailModal
      :show="showDetailModal"
      :order-id="selectedOrder?.id"
      @close="showDetailModal = false"
    />

  </v-dialog>
</template>

<script setup lang="ts">
import { ref, computed, defineAsyncComponent } from 'vue';
import { format, parseISO } from 'date-fns';
import { ptBR } from 'date-fns/locale';

// Importa o modal de detalhes do pedido
const OrderDetailModal = defineAsyncComponent(() => import('@/components/OrderDetailModal.vue'));

// Props
const props = defineProps({
  show: Boolean,
  orders: {
    type: Array as () => any[],
    default: () => []
  }
});

// Emits
const emit = defineEmits(['close']);

// Estado Interno
const internalShow = computed({
  get: () => props.show,
  set: (val) => {
    if (!val) emit('close');
  }
});

const showDetailModal = ref(false);
const selectedOrder = ref<any | null>(null);

// Status Info (copiado do AdminDashboard para consistência)
const statusInfo: Record<string, { text: string; color: string }> = {
  production_queue: { text: 'Fila Produção', color: '#9E9E9E' }, // grey
  in_printing: { text: 'Impressão', color: '#00BCD4' }, // cyan
  in_cutting: { text: 'Corte', color: '#9C27B0' }, // purple
  // Adicione outros status se necessário
  default: { text: 'Indefinido', color: '#607D8B' } // blue-grey
};

// --- Funções Auxiliares ---

const openDetail = (order: any) => {
  selectedOrder.value = order;
  showDetailModal.value = true;
};

const totalMeters = computed(() => {
  return props.orders.reduce((sum, order) => sum + (order.quantity_meters || 0), 0);
});

const getOrderFabrics = (order: any): string[] => {
  if (order.is_launch && order.order_items) {
    const fabrics = order.order_items.map((item: any) => item.fabric_type);
    return [...new Set(fabrics)] as string[]; // Retorna apenas tecidos únicos
  } else if (order.details?.fabric_type) {
    return [order.details.fabric_type];
  }
  return ['N/A'];
};

const getStatusInfo = (status: string) => {
  return statusInfo[status] || statusInfo.default;
};

const formatNumber = (value: number) => {
  return Number(value || 0).toLocaleString('pt-BR', { maximumFractionDigits: 0 });
};

const formatDate = (dateString: string | null) => {
  if (!dateString) return 'N/A';
  return format(parseISO(dateString), 'dd/MM/yy', { locale: ptBR });
};

</script>

<style scoped lang="scss">
.glassmorphism-card-dialog .v-card {
  backdrop-filter: blur(20px) !important;
  background-color: rgba(40, 40, 45, 0.9) !important;
  border-radius: 12px !important;
  border: 1px solid rgba(255, 255, 255, 0.15);
}

.order-card-production {
  border-radius: 12px;
  background-color: rgba(255, 255, 255, 0.05);
  transition: all 0.2s ease-in-out;
  cursor: pointer;
  position: relative;
  overflow: hidden;

  &:hover {
    transform: translateY(-4px);
    box-shadow: 0 8px 20px rgba(0,0,0,0.3);
    background-color: rgba(255, 255, 255, 0.08);
  }

  .card-status-bar {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 4px;
    box-shadow: 0 0 10px 1px var(--v-theme-primary);
  }

  .v-card-title {
    line-height: 1.3;
  }

  .v-list-item-title {
    line-height: 1.2;
  }
}

.custom-scrollbar::-webkit-scrollbar { width: 6px; }
.custom-scrollbar::-webkit-scrollbar-track { background: transparent; }
.custom-scrollbar::-webkit-scrollbar-thumb {
  background-color: rgba(255, 255, 255, 0.2);
  border-radius: 3px;
}
</style>
