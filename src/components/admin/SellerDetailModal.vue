<template>
  <v-dialog
    v-model="store.showSellerModal"
    fullscreen
    transition="dialog-bottom-transition"
    :scrim="false"
  >
    <v-card class="bg-grey-lighten-4 rounded-0">
      <v-toolbar color="surface" elevation="1" density="comfortable" class="border-b">
        <v-btn icon @click="store.showSellerModal = false">
          <v-icon>mdi-close</v-icon>
        </v-btn>
        <v-toolbar-title class="text-subtitle-1 font-weight-bold d-flex align-center">
          <v-icon start color="primary" class="mr-2">mdi-account-details</v-icon>
          Detalhamento de Performance: {{ details?.name }}
        </v-toolbar-title>
        <v-spacer></v-spacer>
        <v-toolbar-items>
          <div class="d-flex align-center px-4 text-caption text-grey">
            Período: <span class="font-weight-bold text-black ml-1">{{ store.periodLabel }}</span>
          </div>
          <v-divider vertical inset class="my-3"></v-divider>
          <v-btn variant="text" @click="store.showSellerModal = false">Fechar</v-btn>
        </v-toolbar-items>
      </v-toolbar>

      <div class="d-flex flex-column flex-md-row fill-height" style="height: calc(100vh - 48px); overflow: hidden;">

        <div class="sidebar-info pa-6 bg-white border-e h-100 overflow-y-auto custom-scroll" style="width: 100%; max-width: 320px; flex-shrink: 0;">
          <div class="d-flex flex-column align-center text-center mb-6">
            <v-avatar size="120" color="grey-lighten-2" class="elevation-3 mb-4">
              <v-img v-if="details?.avatar" :src="details.avatar" cover></v-img>
              <span v-else class="text-h3 font-weight-bold text-grey-darken-1">{{ details?.name?.charAt(0) }}</span>
            </v-avatar>
            <div class="text-h6 font-weight-black mb-1">{{ details?.name }}</div>
            <div class="text-caption opacity-60 bg-grey-lighten-4 px-2 py-1 rounded">ID: {{ details?.id }}</div>
          </div>

          <v-divider class="mb-6"></v-divider>

          <div class="text-overline font-weight-black mb-4 text-grey-darken-2">Resumo do Período</div>

          <div class="metadata-grid">
            <v-card variant="outlined" class="meta-item mb-3 pa-3 bg-grey-lighten-5 border-thin">
              <div class="d-flex justify-space-between align-center mb-1">
                <div class="text-caption font-weight-bold text-uppercase opacity-60">Total Vendido</div>
                <v-icon color="green" size="small">mdi-currency-usd</v-icon>
              </div>
              <div class="text-h5 font-weight-black text-green-darken-2">{{ store.formatCurrency(details?.total || 0) }}</div>
            </v-card>

            <v-card variant="outlined" class="meta-item mb-3 pa-3 bg-grey-lighten-5 border-thin">
              <div class="d-flex justify-space-between align-center mb-1">
                <div class="text-caption font-weight-bold text-uppercase opacity-60">Volume (Área)</div>
                <v-icon color="blue" size="small">mdi-ruler-square</v-icon>
              </div>
              <div class="text-h6 font-weight-bold text-blue-darken-2">{{ details?.area?.toFixed(2) }} m²</div>
            </v-card>

            <v-card variant="outlined" class="meta-item mb-3 pa-3 bg-grey-lighten-5 border-thin">
              <div class="d-flex justify-space-between align-center mb-1">
                <div class="text-caption font-weight-bold text-uppercase opacity-60">Qtd. Pedidos</div>
                <v-icon color="orange" size="small">mdi-receipt</v-icon>
              </div>
              <div class="text-h6 font-weight-bold text-grey-darken-3">{{ details?.orders?.length || 0 }}</div>
            </v-card>

            <v-card variant="outlined" class="meta-item mb-3 pa-3 bg-grey-lighten-5 border-thin">
              <div class="d-flex justify-space-between align-center mb-1">
                <div class="text-caption font-weight-bold text-uppercase opacity-60">Ticket Médio</div>
                <v-icon color="purple" size="small">mdi-chart-line</v-icon>
              </div>
              <div class="text-h6 font-weight-bold text-purple-darken-2">
                {{ store.formatCurrency(details?.orders?.length ? details.total / details.orders.length : 0) }}
              </div>
            </v-card>
          </div>
        </div>

        <div class="flex-grow-1 d-flex flex-column h-100 bg-grey-lighten-5">
          <div class="pa-4 border-b bg-white d-flex align-center justify-space-between">
            <div class="text-subtitle-2 font-weight-black text-uppercase text-grey-darken-2">
              Histórico de Vendas ({{ details?.orders?.length || 0 }})
            </div>
            <v-chip size="small" color="primary" variant="flat">Ordenado por Data</v-chip>
          </div>

          <div class="flex-grow-1 overflow-y-auto pa-4 custom-scroll">
            <v-card class="border-thin rounded-0 elevation-0">
               <v-table density="compact" class="admin-table">
                  <thead>
                    <tr class="bg-grey-lighten-3 text-caption font-weight-bold text-uppercase">
                      <th class="text-left py-3 pl-4">Data</th>
                      <th class="text-left">Pedido #</th>
                      <th class="text-left">Cliente</th>
                      <th class="text-right">Metragem</th>
                      <th class="text-right">Valor Total</th>
                      <th class="text-center pr-4">Status</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr v-for="order in sortedOrders" :key="order.id" class="hover-row transition-swing">
                      <td class="text-caption font-weight-medium pl-4 text-grey-darken-2">
                        {{ formatDate(order.created_at) }}
                      </td>
                      <td class="text-caption font-weight-bold text-primary">
                        #{{ order.id.slice(0,8) }}
                      </td>
                      <td class="text-caption text-truncate font-weight-bold" style="max-width: 250px;">
                        {{ order.customer?.nome || order.customer?.razao_social || 'Consumidor Final' }}
                      </td>
                      <td class="text-caption text-right font-mono">
                        {{ Number(order.quantity_meters).toFixed(2) }} m²
                      </td>
                      <td class="text-caption font-weight-black text-right text-green-darken-2 font-mono">
                        {{ store.formatCurrency(order.total_value) }}
                      </td>
                      <td class="text-center pr-4">
                        <v-chip
                          size="x-small"
                          label
                          :color="getStatusColor(order.status)"
                          class="font-weight-bold text-uppercase px-2"
                        >
                          {{ translateStatus(order.status) }}
                        </v-chip>
                      </td>
                    </tr>
                    <tr v-if="!details?.orders?.length">
                      <td colspan="6" class="text-center py-8 text-grey">
                        Nenhum pedido encontrado para este vendedor neste período.
                      </td>
                    </tr>
                  </tbody>
               </v-table>
            </v-card>
          </div>
        </div>
      </div>
    </v-card>
  </v-dialog>
</template>

<script setup lang="ts">
import { computed } from 'vue';
import { useSalesAreaStore } from '@/stores/salesArea';
import { format } from 'date-fns';

const store = useSalesAreaStore();

// Dados do Vendedor Selecionado vindos da Store
const details = computed(() => store.selectedSellerDetails);

// Ordenar pedidos por data decrescente
const sortedOrders = computed(() => {
  if (!details.value?.orders) return [];
  return [...details.value.orders].sort((a: any, b: any) =>
    new Date(b.created_at).getTime() - new Date(a.created_at).getTime()
  );
});

const formatDate = (d: string) => format(new Date(d), 'dd/MM/yyyy HH:mm');

const getStatusColor = (status: string) => {
  switch (status) {
    case 'completed':
    case 'delivered': return 'green';
    case 'production': return 'blue';
    case 'design_pending': return 'orange';
    case 'finance_pending': return 'red';
    default: return 'grey';
  }
};

const translateStatus = (status: string) => {
  const map: Record<string, string> = {
    'completed': 'Concluído',
    'delivered': 'Entregue',
    'production': 'Produção',
    'design_pending': 'Design Pend.',
    'finance_pending': 'Financeiro',
    'cancelled': 'Cancelado'
  };
  return map[status] || status;
};
</script>

<style scoped>
.admin-table th {
  font-size: 0.75rem !important;
  letter-spacing: 0.5px;
  color: #555;
  height: 48px !important;
}
.admin-table td {
  height: 44px !important;
}
.hover-row:hover { background-color: rgba(0,0,0,0.02) !important; }
.border-thin { border: 1px solid rgba(0,0,0,0.12); }
.border-e { border-right: 1px solid rgba(0,0,0,0.12); }
.font-mono { font-family: monospace; letter-spacing: -0.5px; }
.custom-scroll::-webkit-scrollbar { width: 8px; }
.custom-scroll::-webkit-scrollbar-thumb { background: #ccc; border-radius: 4px; }
.custom-scroll::-webkit-scrollbar-track { background: #f1f1f1; }
</style>
