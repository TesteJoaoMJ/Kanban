<template>
  <div class="delivery-calendar-container">
    <div class="d-flex flex-column flex-md-row align-center justify-space-between mb-6 gap-4">
      <div class="d-flex align-center">
        <div class="calendar-icon-box mr-4 elevation-1">
          <v-icon color="primary" size="24">mdi-calendar-multiselect</v-icon>
        </div>
        <div>
          <h3 class="text-h6 font-weight-bold text-high-emphasis">Calendário de Entregas</h3>
          <div class="d-flex align-center text-caption text-medium-emphasis">
            <v-icon size="12" class="mr-1">mdi-information-outline</v-icon>
            Regra: 8 dias + Rota (Ter/Qui/Sáb)
          </div>
        </div>
      </div>

      <div class="d-flex align-center gap-3 flex-wrap justify-center">
        <div class="filter-pill-group elevation-1">
          <button
            class="filter-pill"
            :class="{ active: filterMode === 'delivery' }"
            @click="filterMode = 'delivery'"
          >
            <v-icon size="14" class="mr-1">mdi-truck-delivery-outline</v-icon>
            Previsão Entrega
          </button>
          <div class="divider"></div>
          <button
            class="filter-pill"
            :class="{ active: filterMode === 'all' }"
            @click="filterMode = 'all'"
          >
            <v-icon size="14" class="mr-1">mdi-calendar-check-outline</v-icon>
            Lançamento
          </button>
        </div>

        <div class="month-nav elevation-1">
          <button @click="changeMonth(-1)"><v-icon>mdi-chevron-left</v-icon></button>
          <span>{{ currentMonthLabel }}</span>
          <button @click="changeMonth(1)"><v-icon>mdi-chevron-right</v-icon></button>
        </div>
      </div>
    </div>

    <div class="calendar-wrapper elevation-1 rounded-xl overflow-hidden bg-surface">
      <div class="week-header">
        <div v-for="day in weekDays" :key="day">{{ day }}</div>
      </div>

      <div class="days-grid">
        <div
          v-for="(day, index) in calendarDays"
          :key="index"
          class="day-cell"
          :class="{
            'is-today': day.isToday,
            'other-month': !day.isCurrentMonth,
            'has-events': day.count > 0
          }"
          @click="openDayModal(day)"
        >
          <span class="day-number">{{ day.dateNumber }}</span>

          <div v-if="day.count > 0" class="event-indicator">
            <div class="pulse-dot" :class="day.statusColor"></div>
            <span class="count-badge" :class="day.statusColor">{{ day.displayCount }}</span>
            <span class="status-label" :class="day.statusColor">{{ day.statusLabel }}</span>
          </div>
        </div>
      </div>
    </div>

    <div class="d-flex justify-center gap-6 mt-4">
      <div class="legend-item"><div class="dot green"></div> <span class="text-caption font-weight-medium text-high-emphasis">No Prazo</span></div>
      <div class="legend-item"><div class="dot yellow"></div> <span class="text-caption font-weight-medium text-high-emphasis">Entrega Hoje</span></div>
      <div class="legend-item"><div class="dot red"></div> <span class="text-caption font-weight-medium text-high-emphasis">Atrasado</span></div>
    </div>

    <v-dialog v-model="modal.show" width="1100" height="800" persistent content-class="calendar-modal-fixed">
      <div class="d-flex flex-column flex-md-row bg-surface rounded-xl overflow-hidden h-100 w-100">

        <div class="modal-sidebar bg-grey-lighten-4 pa-6 border-e d-flex flex-column" style="min-width: 300px; width: 300px;">
          <div class="mb-8">
            <div class="text-overline text-grey-darken-1 font-weight-bold mb-1">Visão do Dia</div>
            <h2 class="text-h4 font-weight-black text-grey-darken-4 text-capitalize mb-1">
              {{ modal.date ? formatDate(modal.date, 'dd MMMM') : '' }}
            </h2>
            <div class="text-subtitle-1 text-primary font-weight-bold text-capitalize">
              {{ modal.date ? formatDate(modal.date, 'EEEE') : '' }}
            </div>
          </div>

          <div class="d-flex flex-column gap-3 flex-grow-1">
            <div class="info-card elevation-1">
                <div class="d-flex justify-space-between align-center mb-1">
                    <span class="text-caption font-weight-bold text-grey-darken-1">TOTAL DO DIA</span>
                    <v-icon color="primary" size="20">mdi-clipboard-list-outline</v-icon>
                </div>
                <div class="text-h4 font-weight-black text-grey-darken-3">{{ modal.orders.length }}</div>
                <div class="text-caption text-grey">Pedidos listados</div>
            </div>

            <div class="info-card elevation-1 border-s-4 border-error">
                <div class="d-flex justify-space-between align-center mb-1">
                    <span class="text-caption font-weight-bold text-red-darken-1">ATRASADOS</span>
                    <v-icon color="error" size="20">mdi-alert-circle-outline</v-icon>
                </div>
                <div class="text-h4 font-weight-black text-red">{{ modal.delayedCount }}</div>
                <div class="text-caption text-red-lighten-1">Atenção imediata</div>
            </div>

            <div class="info-card elevation-1 border-s-4 border-success">
                <div class="d-flex justify-space-between align-center mb-1">
                    <span class="text-caption font-weight-bold text-green-darken-1">NO PRAZO</span>
                    <v-icon color="success" size="20">mdi-check-circle-outline</v-icon>
                </div>
                <div class="text-h4 font-weight-black text-success">{{ modal.onTimeCount }}</div>
                <div class="text-caption text-green-darken-1">Produção regular</div>
            </div>
          </div>

          <v-btn variant="flat" color="grey-darken-3" block @click="modal.show = false" class="mt-4 text-none font-weight-bold" size="large">
            <v-icon start>mdi-close</v-icon> Fechar
          </v-btn>
        </div>

        <div class="flex-grow-1 d-flex flex-column h-100 bg-white overflow-hidden">
          <div class="modal-header px-6 py-4 border-b d-flex align-center justify-space-between bg-white flex-shrink-0">
            <div>
              <h3 class="text-h6 font-weight-bold text-grey-darken-4">Lista de Pedidos</h3>
              <div class="d-flex align-center text-caption text-grey-darken-1">
                 <v-icon size="14" class="mr-1">mdi-filter-variant</v-icon>
                 Filtrado por: {{ filterMode === 'delivery' ? 'Data de Entrega' : 'Data de Lançamento' }}
              </div>
            </div>
            <div class="d-flex gap-2">
               <v-chip v-if="modal.delayedCount > 0" color="error" variant="flat" class="font-weight-bold">
                  <v-icon start size="16">mdi-alert</v-icon> {{ modal.delayedCount }} Críticos
               </v-chip>
               <v-chip v-else color="success" variant="tonal" class="font-weight-bold">
                  <v-icon start size="16">mdi-check-all</v-icon> Dia em dia
               </v-chip>
            </div>
          </div>

          <div class="flex-grow-1 overflow-y-auto custom-scrollbar pa-0 bg-white">
            <div v-if="modal.orders.length === 0" class="d-flex flex-column align-center justify-center h-100 opacity-40">
              <v-icon size="80" color="grey-lighten-1" class="mb-2">mdi-package-variant-closed</v-icon>
              <p class="font-weight-bold text-grey mt-2 text-h6">Nenhum pedido para exibir</p>
            </div>

            <div v-else class="orders-table-container">
                <div class="d-flex px-6 py-2 bg-grey-lighten-4 border-b text-caption font-weight-bold text-grey-darken-1 text-uppercase sticky-top">
                    <div style="width: 80px;">ID</div>
                    <div style="width: 250px;">Cliente / Vendedor</div>
                    <div style="width: 120px;" class="text-center">Status</div>
                    <div style="width: 150px;">Detalhes</div>
                    <div style="flex: 1;">Entrega</div>
                    <div style="width: 120px;" class="text-end">Ações</div>
                </div>

                <div
                    v-for="order in modal.orders"
                    :key="order.id"
                    class="order-row px-6 py-3 border-b d-flex align-center hover-bg-grey-lighten-5 transition-fast"
                    :class="order.isDelayed ? 'bg-red-lighten-5' : ''"
                >
                    <div style="width: 80px;" class="d-flex flex-column">
                        <span class="font-weight-black text-body-2 font-mono">#{{ String(order.order_number).padStart(4,'0') }}</span>
                        <v-icon v-if="order.isDelayed" color="error" size="16" class="mt-1" style="width: fit-content;">mdi-alert-circle</v-icon>
                    </div>

                    <div style="width: 250px;" class="d-flex align-center pr-4">
                        <v-avatar :color="getColor(order.customer_name)" size="36" class="mr-3 text-subtitle-2 font-weight-bold text-white elevation-1">
                            {{ order.customer_name?.charAt(0).toUpperCase() }}
                        </v-avatar>
                        <div class="text-truncate">
                            <div class="font-weight-bold text-body-2 text-grey-darken-4 text-truncate" :title="order.customer_name">
                                {{ order.customer_name }}
                            </div>
                            <div class="text-caption text-grey-darken-1 d-flex align-center">
                                <v-icon size="12" class="mr-1">mdi-account-tie</v-icon> {{ order.creator?.full_name?.split(' ')[0] }}
                            </div>
                        </div>
                    </div>

                    <div style="width: 120px;" class="text-center pr-2">
                        <v-chip size="x-small" :color="getStatusColor(order.status)" class="font-weight-bold text-white text-uppercase" variant="flat">
                            {{ getStatusText(order.status) }}
                        </v-chip>
                    </div>

                    <div style="width: 150px;" class="d-flex flex-column text-caption text-grey-darken-3 pr-2">
                        <div class="d-flex align-center mb-1">
                            <v-icon size="14" class="mr-1" color="grey">mdi-ruler</v-icon>
                            <strong>{{ formatNumber(order.quantity_meters) }}m</strong>
                        </div>
                        <div class="d-flex align-center text-truncate" :title="getFabricSummary(order)">
                            <v-icon size="14" class="mr-1" color="grey">mdi-palette</v-icon>
                            {{ getFabricSummary(order) }}
                        </div>
                    </div>

                    <div style="flex: 1;" class="d-flex flex-column justify-center">
                        <div class="text-caption font-weight-bold" :class="getDeliveryDateColor(order)">
                            {{ order.delivery_date_formatted || '--/--' }}
                        </div>
                        <div class="text-[10px] text-grey font-weight-medium">
                            {{ order.deliveryDiffText }}
                        </div>
                    </div>

                    <div style="width: 120px;" class="d-flex justify-end gap-1">
                        <v-btn icon density="compact" variant="text" color="grey-darken-3" @click="$emit('print', order)">
                            <v-icon size="20">mdi-printer</v-icon>
                            <v-tooltip activator="parent" location="top" content-class="light-tooltip">Recibo</v-tooltip>
                        </v-btn>
                        <v-btn icon density="compact" variant="text" color="primary" @click="$emit('edit', order)">
                            <v-icon size="20">mdi-pencil</v-icon>
                            <v-tooltip activator="parent" location="top" content-class="light-tooltip">Editar</v-tooltip>
                        </v-btn>
                        <v-btn icon density="compact" variant="text" color="error" @click="$emit('cancel', order)">
                            <v-icon size="20">mdi-delete</v-icon>
                            <v-tooltip activator="parent" location="top" content-class="light-tooltip">Cancelar</v-tooltip>
                        </v-btn>
                    </div>
                </div>
            </div>
          </div>
        </div>
      </div>
    </v-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, reactive } from 'vue';
import { format, startOfMonth, endOfMonth, startOfWeek, endOfWeek, eachDayOfInterval, addMonths, isSameDay, isWithinInterval, parseISO, differenceInCalendarDays, isBefore, startOfToday, addDays } from 'date-fns';
import { ptBR } from 'date-fns/locale';

const props = defineProps<{
  orders: any[]
}>();

const emit = defineEmits(['edit', 'cancel', 'print']);

const currentDate = ref(new Date());
const filterMode = ref<'delivery' | 'all'>('delivery');
const weekDays = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];

// --- LÓGICA DE DATAS (8 DIAS + ROTA) ---

const closedStatuses = ['delivered', 'completed', 'cancelled', 'ready_for_delivery'];

// Função para encontrar a próxima Terça (2), Quinta (4) ou Sábado (6)
const getNextDeliveryDay = (date: Date): Date => {
  const newDate = new Date(date);
  while (true) {
    const dayOfWeek = newDate.getDay();
    if ([2, 4, 6].includes(dayOfWeek)) return newDate;
    newDate.setDate(newDate.getDate() + 1);
  }
};

const calculateDeliveryDate = (orderDateStr: string) => {
    if (!orderDateStr) return null;
    try {
        const start = parseISO(orderDateStr);
        // Regra: Data Emissão + 8 dias corridos
        const baseDate = addDays(start, 8);
        // Ajuste: Próximo dia válido de rota (Ter/Qui/Sáb)
        return getNextDeliveryDay(baseDate);
    } catch (e) { return null; }
};

const processedOrders = computed(() => {
    const now = startOfToday();
    return props.orders.map(o => {
        const dDate = calculateDeliveryDate(o.created_at);
        const isActive = !closedStatuses.includes(o.status);

        let diffText = '';
        if (dDate) {
            const diff = differenceInCalendarDays(dDate, now);
            if (diff < 0) diffText = `${Math.abs(diff)} dias atrás`;
            else if (diff === 0) diffText = 'Hoje';
            else diffText = `Em ${diff} dias`;
        }

        return {
            ...o,
            delivery_date_obj: dDate,
            delivery_date_formatted: dDate ? format(dDate, 'dd/MM/yyyy') : null,
            isActive,
            deliveryDiffText: diffText
        };
    });
});

const currentMonthLabel = computed(() => format(currentDate.value, 'MMMM yyyy', { locale: ptBR }));

const changeMonth = (delta: number) => {
  currentDate.value = addMonths(currentDate.value, delta);
};

const calendarDays = computed(() => {
  const monthStart = startOfMonth(currentDate.value);
  const monthEnd = endOfMonth(currentDate.value);
  const start = startOfWeek(monthStart);
  const end = endOfWeek(monthEnd);

  const days = eachDayOfInterval({ start, end });
  const today = startOfToday();

  return days.map(day => {
    let dayOrders = [];

    if (filterMode.value === 'delivery') {
      // Filtra pela DATA DE ENTREGA (calculada com a regra de 8 dias + rota)
      dayOrders = processedOrders.value.filter(o =>
        o.delivery_date_obj &&
        isSameDay(o.delivery_date_obj, day) &&
        o.status !== 'cancelled'
      );
    } else {
      // Filtra pela DATA DE CRIAÇÃO
      dayOrders = processedOrders.value.filter(o =>
        isSameDay(parseISO(o.created_at), day)
      );
    }

    // Calcular status do dia
    let delayedCount = 0;
    let todayCount = 0;

    dayOrders.forEach(o => {
        const dDate = o.delivery_date_obj;
        // Atraso = Data Entrega < Hoje E Pedido Ativo
        if (dDate && isBefore(dDate, today) && o.isActive) {
            delayedCount++;
        }
        // Hoje = Data Entrega == Hoje E Pedido Ativo
        if (dDate && isSameDay(dDate, today) && o.isActive) {
            todayCount++;
        }
    });

    let statusColor = 'green';
    let statusLabel = 'No Prazo';
    let displayCount = dayOrders.length;

    if (delayedCount > 0) {
        statusColor = 'red';
        statusLabel = 'Atrasado';
        displayCount = delayedCount;
    } else if (todayCount > 0) {
        statusColor = 'yellow';
        statusLabel = 'Hoje';
        displayCount = todayCount;
    } else if (dayOrders.length > 0 && dayOrders.every(o => !o.isActive)) {
        statusColor = 'grey';
        statusLabel = 'Finalizado';
    }

    return {
      dateObj: day,
      dateNumber: format(day, 'd'),
      isCurrentMonth: isSameDay(day, monthStart) || isWithinInterval(day, { start: monthStart, end: monthEnd }),
      isToday: isSameDay(day, today),
      count: dayOrders.length,
      displayCount,
      orders: dayOrders,
      statusColor,
      statusLabel,
      delayedCount
    };
  });
});

const modal = reactive({
  show: false,
  date: null as Date | null,
  orders: [] as any[],
  delayedCount: 0,
  onTimeCount: 0
});

const openDayModal = (day: any) => {
  if (day.orders.length === 0) return;
  const today = startOfToday();

  modal.date = day.dateObj;

  modal.orders = day.orders.map((o: any) => {
      const dDate = o.delivery_date_obj;
      const isDelayed = dDate && isBefore(dDate, today) && o.isActive;
      const isToday = dDate && isSameDay(dDate, today) && o.isActive;
      return { ...o, isDelayed, isToday };
  });

  modal.delayedCount = modal.orders.filter((o:any) => o.isDelayed).length;
  modal.onTimeCount = modal.orders.length - modal.delayedCount;
  modal.show = true;
};

// Formatters
const formatDate = (date: Date, fmt: string) => format(date, fmt, { locale: ptBR });
const formatNumber = (val: number) => new Intl.NumberFormat('pt-BR', { maximumFractionDigits: 0 }).format(val || 0);

const getStatusText = (status: string) => {
    const map: Record<string, string> = {
        'production_queue': 'Fila Produção', 'in_production': 'Em Produção', 'in_printing': 'Impressão',
        'design_pending': 'Design', 'customer_approval': 'Aprovação', 'changes_requested': 'Alteração',
        'ready_for_delivery': 'Pronto p/ Entrega', 'completed': 'Aguard. Fat.', 'delivered': 'Entregue', 'cancelled': 'Cancelado',
        'in_queue': 'Na Fila', 'approved_by_seller': 'Aprov. Vendedor'
    };
    return map[status] || status;
};

const getStatusColor = (status: string) => {
    const map: Record<string, string> = {
        'production_queue': 'blue-grey', 'in_production': 'info', 'in_printing': 'indigo',
        'design_pending': 'purple', 'customer_approval': 'orange', 'changes_requested': 'deep-orange',
        'ready_for_delivery': 'teal', 'completed': 'success', 'delivered': 'light-blue', 'cancelled': 'error',
        'approved_by_seller': 'light-green'
    };
    return map[status] || 'grey';
};

const getDeliveryDateColor = (order: any) => {
    if (order.isDelayed) return 'text-error';
    if (order.isToday) return 'text-warning';
    return 'text-grey-darken-3';
};

const getColor = (name: string) => {
    const colors = ['primary', 'secondary', 'teal', 'orange', 'indigo', 'pink', 'deep-purple'];
    let hash = 0; if(!name) return 'grey';
    for(let i=0; i<name.length; i++) hash = name.charCodeAt(i) + ((hash << 5) - hash);
    return colors[Math.abs(hash) % colors.length];
};

const getFabricSummary = (order: any) => {
    if (order.order_items && order.order_items.length > 0) {
        const first = order.order_items[0].fabric_type;
        const count = order.order_items.length;
        return count > 1 ? `${first} +${count - 1}` : first;
    }
    return order.details?.fabric_type || 'Tecido N/A';
};
</script>

<style scoped lang="scss">
.delivery-calendar-container { width: 100%; }

/* Header & Filters */
.calendar-icon-box {
  width: 48px; height: 48px;
  background: linear-gradient(135deg, #e3f2fd, #bbdefb);
  border-radius: 12px;
  display: flex; align-items: center; justify-content: center;
}

.filter-pill-group {
  display: flex; background: white; border-radius: 50px; padding: 4px; border: 1px solid #e0e0e0;
}
.filter-pill {
  padding: 6px 16px; border-radius: 20px; font-size: 0.75rem; font-weight: 700; color: #757575; transition: all 0.2s; display: flex; align-items: center;
  &.active { background: #1976D2; color: white; box-shadow: 0 2px 6px rgba(25, 118, 210, 0.3); }
  &:hover:not(.active) { background: #f5f5f5; }
}
.divider { width: 1px; background: #e0e0e0; margin: 4px 0; }

.month-nav {
  display: flex; align-items: center; gap: 12px; background: white; padding: 4px 12px; border-radius: 50px; border: 1px solid #e0e0e0;
  span { font-weight: 800; font-size: 0.85rem; text-transform: capitalize; min-width: 100px; text-align: center; color: #424242; }
  button { width: 28px; height: 28px; border-radius: 50%; display: flex; align-items: center; justify-content: center; color: #757575; &:hover { background: #f5f5f5; color: #1976D2; } }
}

/* Calendar Grid */
.calendar-wrapper { border: 1px solid #e0e0e0; }
.week-header {
  display: grid; grid-template-columns: repeat(7, 1fr); background: #f9fafb; border-bottom: 1px solid #e0e0e0;
  div { padding: 12px; text-align: center; font-size: 0.7rem; font-weight: 700; text-transform: uppercase; color: #9e9e9e; letter-spacing: 1px; }
}
.days-grid { display: grid; grid-template-columns: repeat(7, 1fr); }
.day-cell {
  position: relative; min-height: 100px; border-right: 1px solid #f0f0f0; border-bottom: 1px solid #f0f0f0; padding: 8px; cursor: pointer; transition: background 0.2s; display: flex; flex-direction: column; align-items: center; justify-content: center;
  &:hover { background: #fafafa; }
  &.other-month { background: #fcfcfc; .day-number { color: #bdbdbd; } }
  &.is-today { background: #e3f2fd40; .day-number { background: #1976D2; color: white; width: 24px; height: 24px; border-radius: 50%; display: flex; align-items: center; justify-content: center; } }
  &:nth-child(7n) { border-right: none; }
}
.day-number { font-size: 0.85rem; font-weight: 600; color: #616161; margin-bottom: auto; align-self: flex-start; margin-left: 4px; margin-top: 4px; }

/* Pulse & Badge */
.event-indicator { display: flex; flex-direction: column; align-items: center; margin-bottom: auto; margin-top: auto; position: relative; }
.pulse-dot {
  width: 16px; height: 16px; border-radius: 50%; position: absolute; z-index: 0; opacity: 0.6;
  &.red { background: #FF5252; animation: pulse-red 2s infinite; }
  &.yellow { background: #FFCA28; animation: pulse-yellow 2s infinite; }
  &.green { background: #66BB6A; animation: pulse-green 2s infinite; }
  &.grey { background: #9E9E9E; }
}
.count-badge {
  position: relative; z-index: 1; font-size: 0.75rem; font-weight: 800; color: white; width: 28px; height: 28px; border-radius: 50%; display: flex; align-items: center; justify-content: center; box-shadow: 0 3px 6px rgba(0,0,0,0.15);
  &.red { background: #D32F2F; } &.yellow { background: #F57C00; } &.green { background: #388E3C; } &.grey { background: #757575; }
}
.status-label { margin-top: 4px; font-size: 0.65rem; font-weight: 800; text-transform: uppercase; letter-spacing: 0.5px;
  &.red { color: #D32F2F; } &.yellow { color: #EF6C00; } &.green { color: #2E7D32; } &.grey { color: #616161; }
}

@keyframes pulse-red { 0% { transform: scale(1); opacity: 0.6; } 100% { transform: scale(2.5); opacity: 0; } }
@keyframes pulse-yellow { 0% { transform: scale(1); opacity: 0.6; } 100% { transform: scale(2.5); opacity: 0; } }
@keyframes pulse-green { 0% { transform: scale(1); opacity: 0.6; } 100% { transform: scale(2.5); opacity: 0; } }

/* Legend */
.legend-item { display: flex; align-items: center; gap: 6px; }
.dot { width: 10px; height: 10px; border-radius: 50%; &.green { background: #388E3C; } &.yellow { background: #F57C00; } &.red { background: #D32F2F; } }

/* Modal Cards */
.stat-card { padding: 12px; border-radius: 12px; display: flex; align-items: center; gap: 12px; }
.stat-icon { width: 40px; height: 40px; border-radius: 10px; display: flex; align-items: center; justify-content: center; }
.info-card { padding: 16px; border-radius: 12px; background: white; border: 1px solid #e0e0e0; }

.order-row { transition: background-color 0.2s; cursor: pointer; }
.hover-bg-grey-lighten-5:hover { background-color: #f5f5f5 !important; }
.sticky-top { position: sticky; top: 0; z-index: 5; }

.action-icon-btn:hover { background-color: rgba(0,0,0,0.05); }

.custom-scrollbar::-webkit-scrollbar { width: 6px; }
.custom-scrollbar::-webkit-scrollbar-thumb { background: #bdbdbd; border-radius: 4px; }

:global(.light-tooltip) {
    background-color: #212121 !important;
    color: white !important;
    font-weight: 600 !important;
    font-size: 0.75rem !important;
    padding: 6px 12px !important;
    border-radius: 4px !important;
}

:global(.calendar-modal-fixed) {
    overflow: hidden !important;
    border-radius: 24px !important;
    box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25) !important;
}
</style>
