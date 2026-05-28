<template>
  <v-dialog
    :model-value="show"
    @update:model-value="$emit('close')"
    max-width="1200px"
    content-class="backdrop-blur"
    scrollable
  >
    <v-card
      class="rounded-xl border-thin d-flex flex-column"
      :class="isLight ? 'bg-white text-grey-darken-4' : 'glass-panel text-white'"
      style="max-height: 85vh;"
    >
      <div
        class="d-flex align-center justify-space-between px-6 py-4 border-b flex-shrink-0"
        :class="isLight ? 'border-grey-lighten-2 bg-grey-lighten-5' : 'border-white-05 bg-surface-darker'"
      >
        <div class="d-flex align-center">
          <v-avatar
            :color="isLight ? 'red-lighten-5' : 'rgba(239, 83, 80, 0.2)'"
            class="mr-4 rounded-lg"
            size="48"
          >
            <v-icon :color="isLight ? 'red-darken-1' : 'red-accent-2'" size="28">mdi-clock-alert-outline</v-icon>
          </v-avatar>
          <div>
            <h2 class="text-h6 font-weight-black leading-tight">Gerenciamento de Atrasos</h2>
            <div class="text-caption font-weight-medium" :class="isLight ? 'text-grey-darken-1' : 'text-white-70'">
              Você tem <b class="text-error">{{ orders.length }} pedidos</b> com o prazo expirado
            </div>
          </div>
        </div>
        <v-btn icon variant="text" @click="$emit('close')" :color="isLight ? 'grey-darken-2' : 'white'">
          <v-icon>mdi-close</v-icon>
        </v-btn>
      </div>

      <v-card-text class="pa-0 flex-grow-1 overflow-y-auto">
        <v-data-table
          :headers="headers"
          :items="enrichedOrders"
          class="bg-transparent"
          :class="isLight ? 'light-table' : 'dark-table'"
          hover
          :items-per-page="-1"
          sticky-header
        >
          <template v-slot:headers="{ columns, isSorted, getSortIcon, toggleSort }">
            <tr>
              <template v-for="column in columns" :key="column.key">
                <th
                  class="text-caption font-weight-bold text-uppercase"
                  :class="[
                    isLight ? 'text-grey-darken-1 bg-grey-lighten-5' : 'text-white-50 bg-surface-darker',
                    column.align === 'end' ? 'text-right' : 'text-left'
                  ]"
                  :style="{ padding: '12px 16px', borderBottom: isLight ? '1px solid #e0e0e0' : '1px solid rgba(255,255,255,0.1)' }"
                >
                  {{ column.title }}
                </th>
              </template>
            </tr>
          </template>

          <template v-slot:item.order_info="{ item }">
            <div class="py-3">
              <div class="d-flex align-center mb-1">
                <v-chip
                  size="x-small"
                  :color="isLight ? 'grey-darken-3' : 'white'"
                  variant="outlined"
                  class="font-weight-black mr-2 font-mono"
                >
                  #{{ String(item.order_number).padStart(4, '0') }}
                </v-chip>
                <v-chip
                  v-if="item.is_launch"
                  size="x-small"
                  color="purple"
                  variant="flat"
                  class="font-weight-bold letter-spacing-1"
                >LANÇAMENTO</v-chip>
              </div>
              <div class="text-subtitle-2 font-weight-bold mb-1 line-clamp-1" :title="item.customer_name">
                {{ item.customer_name }}
              </div>
              <div class="text-caption d-flex align-center" :class="isLight ? 'text-grey-darken-1' : 'text-white-50'">
                <v-icon size="14" class="mr-1">mdi-account-tie-outline</v-icon>
                {{ item.creator?.full_name?.split(' ')[0] || 'N/A' }}
              </div>
            </div>
          </template>

          <template v-slot:item.delay_analysis="{ item }">
            <div class="py-2">
               <div class="d-flex align-center mb-2">
                  <v-chip
                    size="small"
                    :color="getSeverityColor(item.days_late)"
                    variant="flat"
                    class="font-weight-bold text-white mr-2"
                  >
                    <v-icon start size="16">mdi-timer-sand</v-icon>
                    {{ item.days_late }} dias atrasado
                  </v-chip>
               </div>

               <div class="d-flex flex-column gap-1 text-caption" :class="isLight ? 'text-grey-darken-2' : 'text-white-70'">
                  <div class="d-flex align-center">
                    <span class="opacity-70 mr-2" style="min-width: 60px;">Previsão:</span>
                    <strong :class="isLight ? 'text-red-darken-3' : 'text-red-accent-1'">{{ formatDate(item.delivery_date_obj) }}</strong>
                  </div>
                  <div class="d-flex align-center">
                    <span class="opacity-70 mr-2" style="min-width: 60px;">Rota:</span>
                    <span class="font-mono">{{ getDayOfWeek(item.delivery_date_obj) }}</span>
                  </div>
               </div>
            </div>
          </template>

          <template v-slot:item.status_action="{ item }">
             <div style="width: 180px;">
               <v-select
                  v-model="item.status"
                  :items="statusOptions"
                  item-title="title"
                  item-value="value"
                  variant="outlined"
                  density="compact"
                  hide-details
                  :bg-color="isLight ? 'white' : 'rgba(0,0,0,0.2)'"
                  class="status-select-sm"
                  menu-icon="mdi-chevron-down"
                  @update:model-value="(val) => updateStatus(item, val)"
               >
                  <template v-slot:selection="{ item: selectedItem }">
                     <div class="d-flex align-center">
                       <v-icon :color="selectedItem.raw.color" size="14" class="mr-2">mdi-circle</v-icon>
                       <span class="text-caption font-weight-bold text-truncate">{{ selectedItem.title }}</span>
                     </div>
                  </template>

                  <template v-slot:item="{ props, item: option }">
                    <v-list-item v-bind="props" title="" density="compact">
                      <template v-slot:prepend>
                        <v-icon :color="option.raw.color" size="14">mdi-circle</v-icon>
                      </template>
                      <v-list-item-title class="text-caption font-weight-bold ml-2">
                        {{ option.title }}
                      </v-list-item-title>
                    </v-list-item>
                  </template>
               </v-select>
               <div class="text-caption mt-1 text-center" :class="isLight ? 'text-grey-darken-1' : 'text-white-50'" style="font-size: 0.7rem;">
                  Mude para <b class="text-success">Entregue</b> p/ remover
               </div>
             </div>
          </template>

          <template v-slot:item.actions="{ item }">
            <div class="d-flex justify-end ga-1">
              <v-btn
                icon
                size="small"
                variant="tonal"
                color="primary"
                class="rounded-lg"
                @click="$emit('view-details', item)"
              >
                <v-icon>mdi-eye-outline</v-icon>
                <v-tooltip activator="parent" location="top" content-class="light-tooltip">Ver Detalhes</v-tooltip>
              </v-btn>

              <v-btn
                icon
                size="small"
                variant="tonal"
                color="error"
                class="rounded-lg"
                @click="deleteOrder(item)"
                :loading="loadingDelete === item.id"
              >
                <v-icon>mdi-delete-outline</v-icon>
                <v-tooltip activator="parent" location="top" content-class="light-tooltip">Excluir Pedido</v-tooltip>
              </v-btn>
            </div>
          </template>

          <template v-slot:no-data>
             <div class="d-flex flex-column align-center justify-center py-8 text-medium-emphasis">
                <v-icon size="48" class="mb-2">mdi-check-circle-outline</v-icon>
                <div class="text-body-1 font-weight-bold">Nenhum atraso encontrado!</div>
                <div class="text-caption">Parabéns, todos os pedidos estão dentro do prazo.</div>
             </div>
          </template>
        </v-data-table>
      </v-card-text>
    </v-card>
  </v-dialog>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue';
import { format, differenceInCalendarDays, parseISO, isValid } from 'date-fns';
import { ptBR } from 'date-fns/locale';
import { supabase } from '@/api/supabase';
import { useThemeStore } from '@/stores/theme';

const props = defineProps<{
  show: boolean;
  orders: any[];
}>();

const emit = defineEmits(['close', 'view-details', 'refresh']);
const themeStore = useThemeStore();
const isLight = computed(() => themeStore.currentMode === 'light');

const loadingDelete = ref<string | null>(null);

const headers = [
  { title: 'Pedido / Cliente', key: 'order_info', align: 'start', width: '30%' },
  { title: 'Status do Prazo', key: 'delay_analysis', align: 'start', width: '30%' },
  { title: 'Ação Rápida', key: 'status_action', align: 'center', width: '25%' },
  { title: '', key: 'actions', align: 'end', sortable: false },
];

const statusOptions = [
  { title: 'Aguard. Design', value: 'design_pending', color: 'blue-grey' },
  { title: 'Em Aprovação', value: 'customer_approval', color: 'orange' },
  { title: 'Fila Produção', value: 'production_queue', color: 'indigo' },
  { title: 'Finalizado (Faturar)', value: 'completed', color: 'teal' },
  { title: 'Entregue (Remover)', value: 'delivered', color: 'success' },
  { title: 'Cancelado (Remover)', value: 'cancelled', color: 'grey' },
];

const enrichedOrders = computed(() => {
  const now = new Date();
  now.setHours(0, 0, 0, 0);

  return props.orders.map(order => {
    let daysLate = 0;
    if (order.delivery_date_obj) {
      const delivery = new Date(order.delivery_date_obj);
      delivery.setHours(0, 0, 0, 0);
      daysLate = differenceInCalendarDays(now, delivery);
    }

    return {
      ...order,
      days_late: daysLate
    };
  }).sort((a, b) => b.days_late - a.days_late);
});

// Funções Auxiliares
const formatDate = (date: Date | string) => {
  if (!date) return '-';
  const d = typeof date === 'string' ? parseISO(date) : date;
  return isValid(d) ? format(d, 'dd/MM/yyyy', { locale: ptBR }) : '-';
};

const getDayOfWeek = (date: Date | string) => {
  if (!date) return '';
  const d = typeof date === 'string' ? parseISO(date) : date;
  return isValid(d) ? format(d, 'EEEE', { locale: ptBR }).toUpperCase() : '';
};

const getSeverityColor = (days: number) => {
  if (days <= 3) return 'amber-darken-2'; // Atraso leve (amarelo/laranja)
  if (days <= 7) return 'deep-orange-darken-1'; // Atraso médio (laranja escuro)
  return 'red-accent-4'; // Crítico (vermelho)
};

// Ações
const updateStatus = async (item: any, newStatus: string) => {
  try {
    const { error } = await supabase
      .from('orders')
      .update({ status: newStatus })
      .eq('id', item.id);

    if (error) throw error;
    emit('refresh');
  } catch (error) {
    console.error('Erro ao atualizar status:', error);
    alert('Erro ao atualizar status.');
  }
};

const deleteOrder = async (item: any) => {
  if (!confirm(`Tem certeza que deseja EXCLUIR o pedido #${item.order_number}? Essa ação não pode ser desfeita.`)) return;

  loadingDelete.value = item.id;
  try {
    const { error } = await supabase
      .from('orders')
      .delete()
      .eq('id', item.id);

    if (error) throw error;
    emit('refresh');
  } catch (error) {
    console.error('Erro ao excluir:', error);
    alert('Erro ao excluir pedido.');
  } finally {
    loadingDelete.value = null;
  }
};
</script>

<style scoped>
/* Base Modal Styles */
.backdrop-blur {
  backdrop-filter: blur(8px);
}
.glass-panel {
  background: rgba(30, 30, 35, 0.85);
  backdrop-filter: blur(20px);
  border: 1px solid rgba(255, 255, 255, 0.08);
}
.bg-surface-darker {
  background-color: rgba(0, 0, 0, 0.2);
}
.border-white-05 {
  border-color: rgba(255, 255, 255, 0.05) !important;
}

/* Text Colors Light/Dark */
.text-white-70 { color: rgba(255, 255, 255, 0.7); }
.text-white-50 { color: rgba(255, 255, 255, 0.5); }
.text-error { color: #FF5252; }

/* Table Styles - Dark Mode */
.dark-table :deep(th) {
  color: rgba(255, 255, 255, 0.5) !important;
}
.dark-table :deep(td) {
  border-bottom: 1px solid rgba(255, 255, 255, 0.05) !important;
  color: white;
}
.dark-table :deep(tr:hover) {
  background-color: rgba(255, 255, 255, 0.03) !important;
}

/* Table Styles - Light Mode */
.light-table :deep(th) {
  color: #616161 !important;
}
.light-table :deep(td) {
  border-bottom: 1px solid #e0e0e0 !important;
  color: #212121;
}
.light-table :deep(tr:hover) {
  background-color: #f5f5f5 !important;
}

/* Line Clamp for long names */
.line-clamp-1 {
  display: -webkit-box;
  -webkit-line-clamp: 1;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

/* Custom Select styling */
.status-select-sm :deep(.v-field__input) {
  padding-top: 6px;
  padding-bottom: 6px;
  min-height: 32px;
}
</style>
