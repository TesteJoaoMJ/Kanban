<template>
  <v-dialog
    :model-value="internalShow"
    @update:model-value="val => internalShow = val"
    width="1600px"
    height="90vh"
    class="open-orders-modal"
    content-class="glass-modal-content"
    scrollable
  >
    <v-card class="fill-height d-flex flex-row overflow-hidden" :class="themeClass">

      <div class="sidebar-filters d-flex flex-column border-r" :class="sidebarClass" style="width: 280px; min-width: 280px;">

        <div class="pa-5 pb-2">
           <div class="text-overline font-weight-black opacity-60 mb-2">Painel de Controle</div>
           <h2 class="text-h6 font-weight-black lh-1 mb-1">{{ title }}</h2>
           <div class="text-caption opacity-70">
              Gerencie a fila de produção e aprovações.
           </div>
        </div>

        <div class="px-4 py-2">
           <v-text-field
             v-model="searchQuery"
             placeholder="Buscar pedido..."
             density="compact"
             variant="outlined"
             prepend-inner-icon="mdi-magnify"
             hide-details
             class="rounded-lg"
             :bg-color="inputBgColor"
           ></v-text-field>
        </div>

        <v-divider class="my-2 opacity-20"></v-divider>

        <div class="flex-grow-1 overflow-y-auto custom-scrollbar px-3">
           <div class="text-[10px] font-weight-bold uppercase opacity-50 mb-2 px-2 mt-2">Status & Filas</div>

           <div
             v-for="(count, statusKey) in statusDistribution"
             :key="statusKey"
             class="filter-item d-flex align-center justify-space-between pa-3 rounded-lg mb-1 cursor-pointer transition-all"
             :class="[
                activeStatusFilter === statusKey ? activeFilterClass : 'hover-bg opacity-70 hover-opacity-100',
                activeStatusFilter === statusKey ? '' : 'text-medium-emphasis'
             ]"
             @click="toggleStatusFilter(statusKey)"
           >
              <div class="d-flex align-center overflow-hidden">
                 <div class="status-dot-lg mr-3 shadow-glow" :style="{ backgroundColor: getStatusInfo(statusKey).color }"></div>
                 <div class="d-flex flex-column overflow-hidden">
                    <span class="text-caption font-weight-bold text-truncate">{{ getStatusInfo(statusKey).text }}</span>
                    <span class="text-[10px] opacity-60">
                       {{ formatNumber(getStatusVolume(statusKey)) }}m
                    </span>
                 </div>
              </div>
              <v-chip size="x-small" variant="flat" :color="activeStatusFilter === statusKey ? 'white' : 'grey-lighten-2'" :class="activeStatusFilter === statusKey ? 'text-black' : ''" class="font-weight-bold h-20">
                 {{ count }}
              </v-chip>
           </div>
        </div>

        <div class="pa-4 mt-auto border-t" :class="borderColorClass">
           <div class="kpi-summary pa-3 rounded-lg border-thin" :class="kpiBoxClass">
              <div class="d-flex justify-space-between align-center mb-1">
                 <span class="text-[10px] font-weight-bold uppercase opacity-60">Total Listado</span>
                 <v-icon size="14" class="opacity-50">mdi-chart-bar</v-icon>
              </div>
              <div class="text-h6 font-weight-black lh-1">{{ filteredOrders.length }} <span class="text-caption opacity-60">pedidos</span></div>
              <div class="text-caption font-weight-bold text-primary mt-1">{{ formatNumber(totalMetersFiltered) }}m totais</div>
           </div>
        </div>
      </div>

      <div class="main-list flex-grow-1 d-flex flex-column bg-pattern relative" style="min-width: 0;">

         <div class="px-6 py-3 border-b d-flex align-center justify-space-between flex-shrink-0" :class="headerClass">
            <div class="d-flex align-center gap-2">
               <v-icon size="20" class="opacity-50">mdi-format-list-bulleted</v-icon>
               <span class="text-caption font-weight-bold uppercase opacity-60">Listagem de Pedidos</span>
            </div>

            <div class="d-flex align-center gap-2">
               <v-btn size="small" variant="text" color="primary" prepend-icon="mdi-refresh" @click="emit('refresh')">Atualizar</v-btn>
               <v-divider vertical class="h-20 opacity-20 mx-2"></v-divider>
               <v-btn icon size="small" variant="text" @click="$emit('close')"><v-icon>mdi-close</v-icon></v-btn>
            </div>
         </div>

         <div class="flex-grow-1 overflow-y-auto custom-scrollbar pa-0 relative">
            <div v-if="loading" class="d-flex flex-column justify-center align-center h-100 opacity-50">
               <v-progress-circular indeterminate color="primary" size="40"></v-progress-circular>
            </div>

            <div v-else-if="filteredOrders.length === 0" class="d-flex flex-column justify-center align-center h-100 opacity-40">
               <v-icon size="64" class="mb-4">mdi-package-variant-closed</v-icon>
               <div class="text-subtitle-1 font-weight-bold">Nenhum pedido encontrado</div>
            </div>

            <v-table v-else class="rich-table" hover density="comfortable">
               <thead>
                  <tr>
                     <th class="pl-6 text-left" style="width: 60px;">Arte</th>
                     <th class="text-left">Pedido / Cliente</th>
                     <th class="text-left">Data</th>
                     <th class="text-left">Volume</th>
                     <th class="text-left">Status</th>
                     <th class="text-right pr-6" style="width: 100px;">Ação</th>
                  </tr>
               </thead>
               <tbody>
                  <tr
                    v-for="order in filteredOrders"
                    :key="order.id"
                    class="rich-row transition-all cursor-pointer"
                    :class="{ 'row-active': selectedOrder?.id === order.id }"
                    @click="selectOrder(order)"
                  >
                     <td class="pl-6 py-3">
                        <v-avatar rounded="lg" size="48" class="border-thin bg-grey-lighten-4">
                           <v-img :src="getOrderThumbnail(order)" cover>
                              <template v-slot:placeholder>
                                 <div class="d-flex align-center justify-center fill-height bg-grey-lighten-3">
                                    <v-icon size="20" color="grey">mdi-image-off</v-icon>
                                 </div>
                              </template>
                           </v-img>
                        </v-avatar>
                     </td>
                     <td class="py-3">
                        <div class="d-flex flex-column">
                           <div class="d-flex align-center gap-2">
                              <span class="text-caption font-mono font-weight-bold opacity-60">#{{ String(order.order_number).padStart(4, '0') }}</span>
                              <v-icon v-if="order.is_launch" size="12" color="purple" title="Lançamento">mdi-rocket-launch</v-icon>
                           </div>
                           <div class="text-body-2 font-weight-bold text-truncate" style="max-width: 220px;">{{ order.customer_name }}</div>
                           <div class="text-[10px] opacity-60 d-flex align-center gap-1">
                              <v-icon size="10">mdi-account-tie</v-icon>
                              {{ (order.creator?.full_name || order.creator_name || 'N/A').split(' ')[0] }}
                           </div>
                        </div>
                     </td>
                     <td class="text-caption font-weight-medium opacity-80">
                        {{ formatDate(order.created_at) }}
                        <div class="text-[9px] opacity-50">{{ formatTimeAgo(order.created_at) }}</div>
                     </td>
                     <td>
                        <div class="d-flex flex-column">
                           <span class="text-body-2 font-weight-black font-mono">{{ formatNumber(order.quantity_meters) }}m</span>
                           <span class="text-[10px] text-green font-weight-bold">{{ formatCurrency(order.value) }}</span>
                        </div>
                     </td>
                     <td>
                        <v-chip size="x-small" :color="getStatusInfo(order.status).color" variant="flat" class="font-weight-bold uppercase h-20 px-2">
                           {{ getStatusInfo(order.status).text }}
                        </v-chip>
                     </td>
                     <td class="text-right pr-6">
                        <v-btn size="small" icon variant="text" color="primary" class="hover-scale" @click.stop="openDetailModal(order)">
                           <v-icon>mdi-open-in-new</v-icon>
                           <v-tooltip activator="parent" location="top">Abrir Completo</v-tooltip>
                        </v-btn>
                     </td>
                  </tr>
               </tbody>
            </v-table>
         </div>
      </div>

      <div
        v-if="selectedOrder"
        class="preview-sidebar d-flex flex-column border-l bg-surface shadow-left"
        :class="sidebarClass"
        style="width: 380px; min-width: 380px;"
      >
         <div class="px-5 py-4 border-b d-flex align-center justify-space-between bg-glass-header">
            <div>
               <div class="text-overline font-weight-black opacity-60 lh-1 mb-1">Detalhes do Pedido</div>
               <div class="text-h6 font-weight-black">#{{ String(selectedOrder.order_number).padStart(4, '0') }}</div>
            </div>
            <v-btn icon size="small" variant="text" @click="selectedOrder = null"><v-icon>mdi-close</v-icon></v-btn>
         </div>

         <div class="flex-grow-1 overflow-y-auto custom-scrollbar pa-5">

            <div class="info-card pa-4 rounded-xl border-thin mb-4 relative overflow-hidden" :class="kpiBoxClass">
               <div class="d-flex align-center gap-3 mb-3 relative z-10">
                  <v-avatar color="primary" variant="tonal" rounded="lg">
                     <span class="text-h6 font-weight-bold">{{ selectedOrder.customer_name.charAt(0) }}</span>
                  </v-avatar>
                  <div class="overflow-hidden">
                     <div class="text-subtitle-2 font-weight-bold text-truncate">{{ selectedOrder.customer_name }}</div>
                     <div class="text-caption opacity-60">Cliente</div>
                  </div>
               </div>
               <div class="d-grid cols-2 gap-2 relative z-10">
                  <div class="text-caption"><strong class="d-block opacity-60 text-[10px] uppercase">Vendedor</strong> {{ (selectedOrder.creator?.full_name || 'N/A').split(' ')[0] }}</div>
                  <div class="text-caption"><strong class="d-block opacity-60 text-[10px] uppercase">Data</strong> {{ formatDate(selectedOrder.created_at) }}</div>
               </div>
               <v-icon class="absolute-bg-icon" size="80">mdi-account-circle</v-icon>
            </div>

            <div class="mb-4">
               <div class="d-flex justify-space-between align-center mb-2">
                  <span class="text-caption font-weight-bold uppercase opacity-70">Itens do Pedido</span>
                  <span class="text-[10px] opacity-50">{{ selectedOrder.order_items?.length || 0 }} itens</span>
               </div>

               <div class="d-flex flex-column gap-2">
                  <div
                    v-for="item in (selectedOrder.order_items || [])"
                    :key="item.id"
                    class="item-row pa-2 rounded-lg border-thin d-flex align-center gap-3 bg-white hover-bg"
                    :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-glass-card'"
                  >
                     <v-avatar rounded size="40" class="bg-grey-lighten-4 border-thin">
                        <v-img :src="item.stamp_image_url || '/placeholder.png'" cover></v-img>
                     </v-avatar>
                     <div class="flex-grow-1 overflow-hidden">
                        <div class="text-[11px] font-weight-bold text-truncate">{{ item.stamp_ref }}</div>
                        <div class="text-[10px] opacity-60">{{ item.fabric_type }}</div>
                     </div>
                     <div class="text-right">
                        <div class="text-[11px] font-weight-black">{{ formatNumber(item.quantity_meters) }}m</div>
                        <v-chip size="x-small" :color="getStatusInfo(item.status).color" variant="tonal" class="h-16 px-1 font-weight-bold text-[9px]">
                           {{ getStatusInfo(item.status).text }}
                        </v-chip>
                     </div>
                  </div>
               </div>
            </div>

            <div class="mt-4">
               <div class="text-caption font-weight-bold uppercase opacity-70 mb-2">Ações Rápidas</div>
               <v-select
                  v-model="selectedOrder.status"
                  :items="statusOptions"
                  label="Mover Status do Pedido"
                  variant="outlined"
                  density="compact"
                  hide-details
                  item-title="text"
                  item-value="value"
                  :bg-color="inputBgColor"
                  class="mb-3"
                  @update:modelValue="(val) => updateOrderStatus(selectedOrder, val)"
               >
                  <template v-slot:item="{ props, item }">
                     <v-list-item v-bind="props">
                        <template v-slot:prepend>
                           <v-icon :color="item.raw.color" size="small">mdi-circle</v-icon>
                        </template>
                     </v-list-item>
                  </template>
               </v-select>

               <v-btn block variant="flat" color="primary" class="font-weight-bold" @click="openDetailModal(selectedOrder)">
                  <v-icon start>mdi-open-in-new</v-icon>
                  Gerenciar Pedido Completo
               </v-btn>
            </div>

         </div>
      </div>

    </v-card>

    <OrderDetailModal
      :show="showDetailModal"
      :order-id="orderToOpen?.id"
      @close="showDetailModal = false"
    />
  </v-dialog>
</template>

<script setup lang="ts">
import { ref, computed, watch, defineAsyncComponent, reactive } from 'vue';
import { format, parseISO, formatDistanceToNow } from 'date-fns';
import { ptBR } from 'date-fns/locale';
import { supabase } from '@/api/supabase';
import { useAppStore } from '@/stores/app';
import { useThemeStore } from '@/stores/theme';

// --- COMPONENTS & STORES ---
const OrderDetailModal = defineAsyncComponent(() => import('@/components/OrderDetailModal.vue'));
const appStore = useAppStore();
const themeStore = useThemeStore();

// --- PROPS & EMITS ---
const props = defineProps({
  show: Boolean,
  title: { type: String, default: 'Pedidos em Aberto' },
  orders: { type: Array as () => any[], default: () => [] }
});
const emit = defineEmits(['close', 'status-updated', 'refresh']);

// --- STATE ---
const internalShow = computed({
  get: () => props.show,
  set: (val) => { if (!val) { searchQuery.value = ''; activeStatusFilter.value = null; selectedOrder.value = null; emit('close'); } }
});

const searchQuery = ref('');
const activeStatusFilter = ref<string | null>(null);
const loading = ref(false);
const localOrders = ref<any[]>([]);
const selectedOrder = ref<any | null>(null); // Pedido selecionado para o preview lateral
const showDetailModal = ref(false);
const orderToOpen = ref<any | null>(null); // Pedido para abrir no modal completo

// --- SYNC PROPS ---
watch(() => props.orders, (newOrders) => {
  localOrders.value = newOrders.map(order => reactive({ ...order, isLoading: false }));
  // Mantém seleção se ainda existir
  if (selectedOrder.value) {
     const stillExists = localOrders.value.find(o => o.id === selectedOrder.value.id);
     selectedOrder.value = stillExists || null;
  }
}, { immediate: true });

// --- COMPUTED: STYLES ---
const themeClass = computed(() => themeStore.currentMode === 'light' ? 'bg-white text-grey-darken-3' : 'bg-glass-dark text-white');
const sidebarClass = computed(() => themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-glass-sidebar border-white-10');
const headerClass = computed(() => themeStore.currentMode === 'light' ? 'border-grey-lighten-2 bg-white' : 'border-white-05 bg-glass-header');
const kpiBoxClass = computed(() => themeStore.currentMode === 'light' ? 'bg-white border-grey-lighten-2' : 'bg-surface-light border-white-10');
const inputBgColor = computed(() => themeStore.currentMode === 'light' ? 'white' : 'rgba(0,0,0,0.2)');
const borderColorClass = computed(() => themeStore.currentMode === 'light' ? 'border-grey-lighten-2' : 'border-white-10');
const activeFilterClass = computed(() => themeStore.currentMode === 'light' ? 'bg-grey-darken-3 text-white shadow-lg' : 'bg-primary text-white shadow-glow');

// --- COMPUTED: DATA ---
const filteredOrders = computed(() => {
  let list = localOrders.value;
  if (searchQuery.value) {
    const q = searchQuery.value.toLowerCase();
    list = list.filter(o =>
       (o.customer_name?.toLowerCase().includes(q)) ||
       (String(o.order_number).includes(q)) ||
       (o.creator?.full_name || '').toLowerCase().includes(q)
    );
  }
  if (activeStatusFilter.value) {
     list = list.filter(o => o.status === activeStatusFilter.value);
  }
  return list;
});

const totalMetersFiltered = computed(() => filteredOrders.value.reduce((acc, o) => acc + (Number(o.quantity_meters) || 0), 0));
const totalMeters = computed(() => localOrders.value.reduce((acc, o) => acc + (Number(o.quantity_meters) || 0), 0));
const totalValue = computed(() => localOrders.value.reduce((acc, o) => acc + (Number(o.value) || 0), 0));
const averageTicket = computed(() => localOrders.value.length ? totalValue.value / localOrders.value.length : 0);

const statusDistribution = computed(() => {
   const dist: Record<string, number> = {};
   localOrders.value.forEach(o => { dist[o.status] = (dist[o.status] || 0) + 1; });
   return dist;
});

// --- CONSTANTS ---
const statusInfo: Record<string, { text: string; color: string }> = {
  design_pending: { text: 'Fila Design', color: '#78909C' },
  customer_approval: { text: 'Aprovação', color: '#FFA726' },
  production_queue: { text: 'Fila Produção', color: '#9E9E9E' },
  in_printing: { text: 'Impressão', color: '#00BCD4' },
  in_cutting: { text: 'Corte', color: '#9C27B0' },
  completed: { text: 'Concluído', color: '#66BB6A' },
  delivered: { text: 'Entregue', color: '#42A5F5' },
  changes_requested: { text: 'Alteração', color: '#EF5350' },
  approved_by_seller: { text: 'Aprovado', color: '#9CCC65' },
  pending_stock: { text: 'Sem Estoque', color: '#FFCA28' },
  default: { text: 'Indefinido', color: '#607D8B' }
};

const statusOptions = [
  { value: 'production_queue', text: 'Mover para Produção', color: statusInfo.production_queue.color },
  { value: 'in_printing', text: 'Mover para Impressão', color: statusInfo.in_printing.color },
  { value: 'in_cutting', text: 'Mover para Corte', color: statusInfo.in_cutting.color },
  { value: 'completed', text: 'Finalizar (Faturamento)', color: statusInfo.completed.color },
];

// --- ACTIONS ---
const toggleStatusFilter = (status: string) => {
   activeStatusFilter.value = activeStatusFilter.value === status ? null : status;
};

const selectOrder = (order: any) => {
   selectedOrder.value = order;
};

const openDetailModal = (order: any) => {
   orderToOpen.value = order;
   showDetailModal.value = true;
};

const updateOrderStatus = async (order: any, newStatus: string) => {
  if (!order || !newStatus) return;
  order.isLoading = true;
  try {
    const { error } = await supabase.from('orders').update({ status: newStatus }).eq('id', order.id);
    if (error) throw error;
    order.status = newStatus;
    appStore.showSnackbar(`Status atualizado para ${getStatusInfo(newStatus).text}`, 'success');
    emit('status-updated');
  } catch (e: any) {
    appStore.showSnackbar(e.message, 'error');
  } finally { order.isLoading = false; }
};

// --- HELPERS ---
const getStatusInfo = (status: string) => statusInfo[status] || statusInfo.default;
const getStatusVolume = (status: string) => localOrders.value.filter(o => o.status === status).reduce((acc, o) => acc + (Number(o.quantity_meters) || 0), 0);
const formatNumber = (val: number) => Number(val || 0).toLocaleString('pt-BR', { maximumFractionDigits: 0 });
const formatCurrency = (val: number) => new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(val || 0);
const formatDate = (date: string) => date ? format(parseISO(date), 'dd/MM/yyyy', { locale: ptBR }) : '-';
const formatTimeAgo = (date: string) => date ? formatDistanceToNow(parseISO(date), { addSuffix: true, locale: ptBR }) : '';

const getOrderThumbnail = (order: any) => {
   if (order.order_items && order.order_items.length > 0) {
      const itemWithImg = order.order_items.find((i: any) => i.stamp_image_url);
      return itemWithImg ? itemWithImg.stamp_image_url : '/placeholder.png';
   }
   return '/placeholder.png';
};
</script>

<style scoped lang="scss">
/* --- Base Styles --- */
.glass-modal-content { backdrop-filter: blur(20px); }
.bg-glass-dark { background: rgba(20, 20, 25, 0.98); }
.bg-glass-sidebar { background: rgba(30, 30, 35, 0.5); }
.bg-glass-header { background: rgba(255, 255, 255, 0.03); }
.bg-glass-card { background: rgba(255, 255, 255, 0.05); }
.bg-surface-light { background: rgba(255, 255, 255, 0.05); }
.bg-pattern { background-image: radial-gradient(rgba(128,128,128,0.1) 1px, transparent 1px); background-size: 20px 20px; }

/* --- Borders & Text --- */
.border-white-10 { border-color: rgba(255, 255, 255, 0.1) !important; }
.border-white-05 { border-color: rgba(255, 255, 255, 0.05) !important; }
.lh-1 { line-height: 1; }
.h-20 { height: 20px; } .h-16 { height: 16px; }
.gap-1 { gap: 4px; } .gap-2 { gap: 8px; } .gap-3 { gap: 12px; }
.d-grid { display: grid; } .cols-2 { grid-template-columns: repeat(2, 1fr); }
.shadow-glow { box-shadow: 0 0 10px rgba(var(--v-theme-primary), 0.4); }
.shadow-left { box-shadow: -5px 0 20px rgba(0,0,0,0.1); }

/* --- Specific Components --- */
.status-dot-lg { width: 10px; height: 10px; border-radius: 50%; flex-shrink: 0; }
.hover-bg:hover { background-color: rgba(128, 128, 128, 0.1); }
.cursor-pointer { cursor: pointer; }

/* --- Table Styling --- */
.rich-table {
   background: transparent !important;
   th { font-size: 11px !important; text-transform: uppercase; opacity: 0.6; font-weight: 700; letter-spacing: 0.5px; }
   td { height: 64px !important; border-bottom: 1px solid rgba(128,128,128,0.1) !important; }
}
.row-active {
   background-color: rgba(var(--v-theme-primary), 0.1) !important;
   position: relative;
   &::before {
      content: ''; position: absolute; left: 0; top: 0; bottom: 0; width: 4px; background: rgb(var(--v-theme-primary));
   }
}
.rich-row:hover:not(.row-active) { background-color: rgba(128,128,128,0.05); }

/* --- Decorative --- */
.absolute-bg-icon { position: absolute; right: -20px; bottom: -20px; opacity: 0.05; transform: rotate(-15deg); pointer-events: none; }
.relative { position: relative; }
.z-10 { position: relative; z-index: 10; }

/* --- Scrollbar --- */
.custom-scrollbar::-webkit-scrollbar { width: 5px; }
.custom-scrollbar::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.3); border-radius: 4px; }
</style>
