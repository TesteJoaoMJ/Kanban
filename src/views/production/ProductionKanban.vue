<template>
  <div
    class="pcp-kanban-layout font-sans fill-height d-flex flex-column relative overflow-hidden"
    :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 text-grey-darken-4' : 'bg-glass-dark text-white'"
  >
    <div v-if="themeStore.currentMode !== 'light'" class="background-carousel-wrapper">
      <div class="background-overlay"></div>
    </div>

    <div class="content-wrapper d-flex flex-column fill-height z-10 relative">

      <div
        class="header-bar px-6 py-4 d-flex align-center justify-space-between flex-shrink-0 relative z-high"
        :class="themeStore.currentMode === 'light' ? 'bg-white border-b border-grey-lighten-2 shadow-sm' : 'bg-glass-header border-bottom-white-05'"
      >

        <div class="d-flex align-center gap-2">
           <v-chip-group v-model="flowMode" mandatory density="compact" variant="tonal" class="font-weight-bold">
              <v-chip value="current" filter color="primary" size="small">Fluxo Atual</v-chip>
              <v-chip value="legacy" filter color="error" size="small">Legado</v-chip>
           </v-chip-group>

           <v-btn
            variant="outlined"
            class="btn-rect ml-2"
            height="36"
            prepend-icon="mdi-refresh"
            :loading="store.loading"
            @click="refreshCurrentData"
          >
            Atualizar
          </v-btn>
        </div>
      </div>

      <div class="px-6 pt-3 pb-2 flex-shrink-0 relative z-high">
         <div class="controls-bar d-flex align-center justify-space-between" :class="themeStore.currentMode === 'light' ? 'controls-light' : 'controls-dark'">
            <div class="d-flex align-center flex-wrap w-100 gap-3">
               <div class="search-wrap d-flex align-center" :class="themeStore.currentMode === 'light' ? 'search-light' : 'search-dark'">
                  <v-icon :color="themeStore.currentMode === 'light' ? 'grey-darken-1' : 'white-70'">mdi-magnify</v-icon>
                  <input v-model="filters.search" type="text" placeholder="Buscar Pedido, Cliente ou Ref..." class="clean-input flex-grow-1 font-weight-bold"/>
               </div>

               <div class="d-flex align-center gap-2">
                  <v-menu :close-on-content-click="false">
                      <template v-slot:activator="{ props }">
                          <v-btn v-bind="props" variant="text" size="small" prepend-icon="mdi-filter-variant">Filtro Data</v-btn>
                      </template>
                      <v-card min-width="300" class="pa-4">
                          <v-text-field v-model="filters.dateStart" label="De" type="date" density="compact" variant="outlined"></v-text-field>
                          <v-text-field v-model="filters.dateEnd" label="Até" type="date" density="compact" variant="outlined"></v-text-field>
                      </v-card>
                  </v-menu>
               </div>
            </div>
         </div>
      </div>

      <div class="flex-grow-1 px-6 pb-4 pt-2 overflow-hidden d-flex flex-column relative z-high">
         <div v-if="store.loading" class="d-flex flex-column justify-center align-center h-100 w-100 absolute z-20" style="background: rgba(0,0,0,0.3); backdrop-filter: blur(2px);">
            <v-progress-circular indeterminate color="primary" size="64" width="6"></v-progress-circular>
         </div>

         <div class="kanban-container d-flex flex-grow-1 overflow-x-auto overflow-y-hidden gap-4 custom-scroll-x pb-2">

            <div
                v-for="col in kanbanColumns"
                :key="col.id"
                class="kanban-column d-flex flex-column flex-shrink-0 h-100 rounded-lg overflow-hidden border-thin relative"
                :class="[themeStore.currentMode === 'light' ? 'bg-grey-lighten-4 border-grey-lighten-2' : 'bg-glass-card border-white-05']"
                style="width: 340px; min-width: 340px;"
            >
                <div class="kpi-header position-relative py-3 px-4 flex-shrink-0" :class="col.gradient">
                    <div class="kpi-bg-icon"><v-icon>{{ col.icon }}</v-icon></div>
                    <div class="d-flex flex-column position-relative z-10 text-white">
                        <div class="d-flex align-center justify-space-between mb-1">
                             <div class="d-flex align-center gap-2">
                                <v-icon size="18" class="opacity-90">{{ col.icon }}</v-icon>
                                <span class="font-weight-black text-uppercase text-caption">{{ col.label }}</span>
                             </div>
                             <v-chip size="x-small" color="white" variant="flat" class="font-weight-black text-black">{{ col.items.length }}</v-chip>
                        </div>
                        <div class="text-[10px] opacity-80 font-weight-medium text-truncate">{{ col.footer }}</div>
                    </div>
                </div>

                <draggable
                    :list="col.items"
                    :group="{ name: 'orders', pull: true, put: true }"
                    item-key="orderId"
                    class="kanban-content pa-2 custom-scroll flex-grow-1 overflow-y-auto d-flex flex-column gap-2"
                    ghost-class="ghost-card"
                    :data-col-id="col.id"
                    @end="onDragEnd"
                >
                    <template #item="{ element: card }">
                        <div class="cursor-grab relative" :data-id="card.orderId">
                            <v-card
                                class="production-card rounded-md border-s-4"
                                :class="[
                                    themeStore.currentMode === 'light' ? 'bg-white border-thin' : 'bg-surface-card border-white-05',
                                    card.isLegacy ? 'border-l-legacy' : col.borderClass
                                ]"
                                :style="`border-left-width: 4px !important;`"
                                variant="flat"
                                @click="openOrderDetail(card)"
                            >
                                <div class="pa-3">
                                    <div class="d-flex align-center justify-space-between mb-2">
                                        <v-chip label size="x-small" class="font-weight-black px-1 rounded-sm" :color="col.chipColor" variant="tonal">OP #{{ card.orderNumber }}</v-chip>
                                        <span class="text-[10px] font-mono opacity-60 font-weight-bold">{{ formatDate(card.date) }}</span>
                                    </div>

                                    <div class="text-subtitle-2 font-weight-black leading-tight mb-2 text-uppercase line-clamp-2" :title="card.customerName">
                                        {{ card.customerName }}
                                    </div>

                                    <div class="d-flex align-center justify-space-between">
                                        <div class="d-flex align-center gap-1 opacity-70">
                                            <v-icon size="12">mdi-layers</v-icon>
                                            <span class="text-[11px] font-weight-bold">{{ card.items.length }} itens</span>
                                        </div>
                                        <span class="text-caption font-mono font-weight-black">{{ formatNumber(card.totalMeters) }}m</span>
                                    </div>

                                    <div v-if="card.previews.length" class="mt-3 pt-2 border-t border-dashed border-opacity-25 d-flex align-center gap-1">
                                        <div v-for="(img, idx) in card.previews.slice(0, 4)" :key="idx" class="rounded-sm overflow-hidden border bg-grey-lighten-2" style="width:22px; height:22px;">
                                            <img :src="img" class="w-100 h-100 object-cover" />
                                        </div>
                                        <div v-if="card.previews.length > 4" class="text-[9px] font-weight-bold opacity-60 ml-1">+{{ card.previews.length - 4 }}</div>
                                    </div>

                                    <div v-if="col.id.includes('faturamento')" class="mt-2 pt-1 d-flex justify-end gap-2">
                                         <v-chip size="x-small" :color="card.billingAlert ? 'error' : 'grey'" variant="tonal" class="font-weight-bold">
                                            <v-icon start size="12">mdi-bell</v-icon> Alerta
                                         </v-chip>
                                    </div>
                                </div>
                            </v-card>
                        </div>
                    </template>
                </draggable>
            </div>

         </div>
      </div>
    </div>

    <LaunchDetailModal v-if="launchDetailModal.show" :show="launchDetailModal.show" :order-id="launchDetailModal.orderId" @close="launchDetailModal.show = false" />

    <v-dialog v-model="calandraModal.show" max-width="400">
        <v-card class="rounded-lg">
             <div class="bg-orange-darken-3 px-5 py-3 text-white font-weight-bold">Enviar Lote para Calandra</div>
             <div class="pa-5">
                 <div class="text-caption mb-2">Movendo <strong>{{ calandraModal.items.length }}</strong> itens para Produção.</div>
                 <v-select v-model="calandraModal.machine" :items="store.availableCalandras" label="Selecione a Calandra" variant="outlined" density="compact" class="mb-3"></v-select>
                 <v-select v-model="calandraModal.operator" :items="store.availableOperators" label="Selecione o Operador" variant="outlined" density="compact"></v-select>
             </div>
             <div class="pa-4 border-t d-flex justify-end gap-2">
                 <v-btn variant="text" @click="calandraModal.show = false">Cancelar</v-btn>
                 <v-btn color="orange-darken-3" variant="flat" @click="confirmCalandraBatch">Confirmar</v-btn>
             </div>
        </v-card>
    </v-dialog>

  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, reactive, watch } from 'vue';
import { format, isAfter, startOfDay, parseISO } from 'date-fns';
import { useProductionStore } from '@/stores/production';
import { useThemeStore } from '@/stores/theme';
import { useAppStore } from '@/stores/app';
import { supabase } from '@/api/supabase';
import draggable from 'vuedraggable';
import LaunchDetailModal from '@/components/LaunchDetailModal.vue';

const store = useProductionStore();
const themeStore = useThemeStore();
const appStore = useAppStore();

// STATE
const flowMode = ref<'current' | 'legacy'>('current');
const filters = reactive({ search: '', dateStart: '', dateEnd: '' });

// MODALS
const launchDetailModal = reactive({ show: false, orderId: '' });
const calandraModal = reactive({ show: false, machine: null, operator: '', items: [] as any[] });

// ---------------------------------------------------------------------------
// DATA PROCESSING (Core Logic)
// ---------------------------------------------------------------------------

const refreshCurrentData = () => {
    store.fetchManagementItems();
    store.fetchBillingOrders();
    store.fetchExpeditionData();
};

const getRawList = () => {
    // Combina todas as listas em uma única fonte de verdade
    let combined = [
        ...(store.managementList || []),
        ...(store.billingList || []),
        ...(store.expeditionList || []),
        ...(store.ghostOrders || [])
    ];

    // Filtro Legacy vs Current
    const cutoffDate = new Date('2026-01-05T00:00:00-03:00').getTime();
    combined = combined.filter(i => {
        const dStr = i.created_at || i.order?.created_at;
        const dTime = dStr ? new Date(dStr).getTime() : 0;
        if (flowMode.value === 'legacy') return dTime < cutoffDate;
        return dTime >= cutoffDate;
    });

    // Remover duplicatas
    const map = new Map();
    combined.forEach(i => { if(i.id) map.set(i.id, i); });
    return Array.from(map.values());
};

const kanbanColumns = computed(() => {
    const rawData = getRawList();

    // Definição das Colunas (Status + Config Visual)
    // Separação Especial: Faturamento Bloqueado vs Liberado
    const cols = [
        {
            id: 'design',
            label: 'DESIGN',
            icon: 'mdi-pencil-ruler',
            gradient: 'bg-gradient-blue',
            borderClass: 'border-l-blue',
            chipColor: 'blue',
            statuses: ['design_pending', 'customer_approval', 'changes_requested', 'approved_by_seller', 'approved_by_designer']
        },
        {
            id: 'pcp',
            label: 'PCP / FILA',
            icon: 'mdi-chart-timeline-variant',
            gradient: 'bg-gradient-purple',
            borderClass: 'border-l-purple',
            chipColor: 'purple',
            statuses: ['design_released', 'waiting_separation']
        },
        {
            id: 'separacao',
            label: 'EM SEPARAÇÃO',
            icon: 'mdi-basket-outline',
            gradient: 'bg-gradient-cyan',
            borderClass: 'border-l-cyan',
            chipColor: 'cyan',
            statuses: ['in_separation']
        },
        {
            id: 'impressao',
            label: 'IMPRESSÃO',
            icon: 'mdi-printer-3d-nozzle',
            gradient: 'bg-gradient-warning',
            borderClass: 'border-l-warning',
            chipColor: 'amber',
            statuses: ['waiting_print', 'printing']
        },
        {
            id: 'calandra',
            label: 'CALANDRA',
            icon: 'mdi-fire',
            gradient: 'bg-gradient-orange',
            borderClass: 'border-l-orange',
            chipColor: 'orange',
            statuses: ['printed', 'waiting_calandra', 'in_calandra', 'in_production']
        },
        // COLUNA NOVA: A FATURAR (BLOQUEADO/OCULTO)
        {
            id: 'faturamento_blocked',
            label: 'A FATURAR (RETIDO)',
            icon: 'mdi-eye-off',
            gradient: 'bg-gradient-grey',
            borderClass: 'border-l-grey',
            chipColor: 'grey',
            statuses: ['billing_pending'],
            filter: (i:any) => i.billing_queue_visible === false // Filtra apenas os ocultos
        },
        // COLUNA NOVA: LIBERADO FATURAMENTO (VISIVEL)
        {
            id: 'faturamento_ready',
            label: 'LIBERADO FATURAMENTO',
            icon: 'mdi-cash-clock',
            gradient: 'bg-gradient-dark',
            borderClass: 'border-l-dark',
            chipColor: 'black',
            statuses: ['billing_pending', 'Em Aberto', 'Parcialmente Faturado'],
            filter: (i:any) => i.billing_queue_visible === true // Filtra apenas os visiveis
        },
        {
            id: 'faturado',
            label: 'FATURADO',
            icon: 'mdi-cash-check',
            gradient: 'bg-gradient-green',
            borderClass: 'border-l-green',
            chipColor: 'green',
            statuses: ['Faturado']
        },
        {
            id: 'expedicao',
            label: 'EXPEDIÇÃO',
            icon: 'mdi-truck-fast',
            gradient: 'bg-gradient-teal',
            borderClass: 'border-l-teal',
            chipColor: 'teal',
            statuses: ['waiting_release', 'ready_for_delivery', 'completed']
        }
    ];

    // Processar dados para cada coluna
    return cols.map(c => {
        let items = rawData.filter((i: any) => {
            // 1. Checa status
            const hasStatus = c.statuses.includes(i.status) || c.statuses.includes(i.financial_status);
            if (!hasStatus) return false;
            // 2. Aplica filtro extra se houver (para separar faturamento)
            if (c.filter && !c.filter(i)) return false;
            return true;
        });

        // Filtros Globais (Busca e Data)
        if (filters.search) {
            const s = filters.search.toLowerCase();
            items = items.filter((i: any) =>
                String(i.order_number||i.order?.order_number||'').includes(s) ||
                String(i.customer_name||i.order?.customer_name||'').toLowerCase().includes(s)
            );
        }
        if (filters.dateStart) {
             const start = new Date(filters.dateStart);
             items = items.filter((i:any) => new Date(i.created_at || i.order?.created_at) >= start);
        }

        // AGRUPAMENTO POR PEDIDO (Card Generation)
        const groups: Record<string, any> = {};

        items.forEach((item: any) => {
            let oid = item.order_id || item.order?.id || item.id;
            // Fallback para itens órfãos
            if (!oid && item.order_number) oid = `loose-${item.order_number}`;
            if (!oid) return;

            if (!groups[oid]) {
                const orderObj = item.order || item;
                groups[oid] = {
                    orderId: oid,
                    orderNumber: item.order_number || item.order?.order_number || '?',
                    customerName: item.customer_name || item.order?.customer_name || 'Consumidor',
                    date: item.created_at || orderObj.created_at,
                    items: [], // Lista de itens deste pedido nesta coluna
                    totalMeters: 0,
                    previews: [],
                    billingAlert: item.billing_alert || orderObj.billing_alert,
                    isLegacy: flowMode.value === 'legacy'
                };
            }
            groups[oid].items.push(item);
            groups[oid].totalMeters += Number(item.quantity_meters || 0);

            // Imagem preview
            const img = item.stamp_image_url || item.print_file_url;
            if(img && !groups[oid].previews.includes(img)) groups[oid].previews.push(img);
        });

        const cards = Object.values(groups).sort((a: any, b: any) => {
            return new Date(b.date).getTime() - new Date(a.date).getTime();
        });

        const totalMeters = cards.reduce((acc, c) => acc + c.totalMeters, 0);

        return {
            ...c,
            items: cards, // Cards agrupados
            footer: `${formatNumber(totalMeters)}m Totais`
        };
    });
});

// ---------------------------------------------------------------------------
// DRAG N DROP HANDLER
// ---------------------------------------------------------------------------
const onDragEnd = async (event: any) => {
    const { item, to, from } = event;
    // O item arrastado é um DOM element que tem dataset.id (orderId)
    const orderId = item.dataset.id;

    // As colunas (droppables) devem ter data-col-id
    const targetColId = to.dataset.colId;
    const sourceColId = from.dataset.colId;

    if (!orderId || !targetColId || targetColId === sourceColId) return;

    // Encontrar o objeto do pedido (Card) na coluna de origem
    const sourceCol = kanbanColumns.value.find(c => c.id === sourceColId);
    const card = sourceCol?.items.find((x: any) => x.orderId === orderId);

    if (!card) return;

    const itemIds = card.items.map((i: any) => i.id);

    // LÓGICA DE TRANSIÇÃO

    // 1. Caso especial: Faturamento Bloqueado <-> Liberado
    if (targetColId === 'faturamento_ready' && sourceColId === 'faturamento_blocked') {
        await store.setBillingVisibility([orderId], true);
        refreshCurrentData();
        return;
    }
    if (targetColId === 'faturamento_blocked' && sourceColId === 'faturamento_ready') {
        await store.setBillingVisibility([orderId], false);
        refreshCurrentData();
        return;
    }

    // 2. Mapeamento de Coluna para Status
    const statusMap: Record<string, string> = {
        'design': 'design_pending',
        'pcp': 'design_released',
        'separacao': 'in_separation',
        'impressao': 'waiting_print',
        'calandra': 'printed', // Trigger modal se necessário
        'faturamento_blocked': 'billing_pending', // Assume oculto
        'faturamento_ready': 'billing_pending', // Assume visivel
        'expedicao': 'waiting_release',
        'faturado': 'Faturado'
    };

    const targetStatus = statusMap[targetColId];
    if (!targetStatus) return;

    // 3. Validação de Calandra (Precisa de máquina)
    if (targetColId === 'calandra') {
        // Se vier de impressão, normalmente vai para 'printed'.
        // Se o usuário quiser jogar direto pra 'in_production', precisaria do modal.
        // Vamos mover para 'printed' (Fila Calandra) por padrão no drag.
        // O modal abre apenas se ele clicar no botão de ação.
        // Simplificando o fluxo: Drag -> Fila.
    }

    if (confirm(`Mover ${card.items.length} itens do Pedido #${card.orderNumber} para ${targetColId.toUpperCase()}?`)) {
        try {
            // Atualiza status dos itens
            await store.batchUpdateStatus(itemIds, targetStatus, 'kanban_drag');

            // Se moveu para faturamento_ready, garante visibilidade
            if (targetColId === 'faturamento_ready') {
                await store.setBillingVisibility([orderId], true);
            }
            // Se moveu para faturamento_blocked, garante ocultação
            if (targetColId === 'faturamento_blocked') {
                await store.setBillingVisibility([orderId], false);
            }

            appStore.showSnackbar('Movido com sucesso!', 'success');
            refreshCurrentData();
        } catch (e) {
            appStore.showSnackbar('Erro ao mover itens.', 'error');
        }
    }
};

// ACTIONS
const openOrderDetail = (card: any) => {
    // Abre modal de detalhes do pedido/itens
    // Você pode reutilizar o LaunchDetailModal ou criar um OrderDetailModal
    launchDetailModal.orderId = card.orderId;
    launchDetailModal.show = true;
};

// BATCH ACTION (Calandra Modal)
const confirmCalandraBatch = async () => {
    if(!calandraModal.items.length) return;
    const ids = calandraModal.items.map(i => i.id);
    // Simula envio em lote chamando endpoint ou loop
    for(const id of ids) {
       await store.moveStage(id, 'in_production', 'batch_calandra', { machine: calandraModal.machine, operator: calandraModal.operator });
    }
    calandraModal.show = false;
    refreshCurrentData();
    appStore.showSnackbar('Enviado para Calandra', 'success');
};

// HELPERS
const formatDate = (d: string) => d ? format(new Date(d), 'dd/MM/yy') : '-';
const formatNumber = (v: number) => new Intl.NumberFormat('pt-BR', { minimumFractionDigits: 0, maximumFractionDigits: 0 }).format(v || 0);

onMounted(() => {
    refreshCurrentData();
    store.fetchOperators();
    store.fetchMachines('calandra');
});
</script>

<style scoped lang="scss">
/* Layout Geral */
.pcp-kanban-layout { position: relative; height: 100vh; background-color: #f5f5f5; }
.bg-glass-dark { background: rgba(10,10,12,0.95); }
.bg-glass-header { background: rgba(20,20,24,0.85); backdrop-filter: blur(14px); }
.background-carousel-wrapper { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 0; opacity: 0.2; pointer-events: none; }
.background-overlay { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 1; background: #121212; }

.z-high { z-index: 10; }
.z-low { z-index: 1; }

/* Controles */
.controls-bar { padding: 0 10px; }
.search-wrap {
    height: 40px; border-radius: 4px; padding: 0 12px; min-width: 300px;
}
.search-light { background: #fff; border: 1px solid #e0e0e0; }
.search-dark { background: rgba(255,255,255,0.05); border: 1px solid rgba(255,255,255,0.1); }
.clean-input { border: none; outline: none; background: transparent; font-size: 13px; color: inherit; height: 100%; width: 100%; }
.btn-rect { border-radius: 4px !important; text-transform: none !important; font-weight: 700; letter-spacing: 0.5px; }

/* Kanban Container */
.kanban-container {
    gap: 16px;
    padding-bottom: 8px;
}
.kanban-column {
    transition: background-color 0.2s;
    display: flex; flex-direction: column;
}

/* Headers KPI Style (Gradientes) */
.kpi-header { overflow: hidden; border-bottom: 1px solid rgba(0,0,0,0.05); }
.bg-gradient-blue { background: linear-gradient(135deg, #2196F3, #1565C0); }
.bg-gradient-purple { background: linear-gradient(135deg, #9C27B0, #6A1B9A); }
.bg-gradient-cyan { background: linear-gradient(135deg, #00BCD4, #00838F); }
.bg-gradient-warning { background: linear-gradient(135deg, #FFC107, #FF8F00); }
.bg-gradient-orange { background: linear-gradient(135deg, #FF9800, #EF6C00); }
.bg-gradient-grey { background: linear-gradient(135deg, #78909C, #455A64); } /* A Faturar Bloqueado */
.bg-gradient-dark { background: linear-gradient(135deg, #263238, #000000); } /* Liberado Fat */
.bg-gradient-green { background: linear-gradient(135deg, #4CAF50, #2E7D32); }
.bg-gradient-teal { background: linear-gradient(135deg, #009688, #004D40); }

.kpi-bg-icon { position: absolute; right: -15px; bottom: -15px; opacity: 0.2; transform: rotate(-15deg); }
.kpi-bg-icon .v-icon { font-size: 80px; color: white; }

/* Cards */
.production-card {
    transition: transform 0.2s, box-shadow 0.2s;
    cursor: grab;
    position: relative;
    user-select: none;
}
.production-card:active { cursor: grabbing; transform: scale(0.98); }
.production-card:hover { transform: translateY(-2px); box-shadow: 0 4px 12px rgba(0,0,0,0.15) !important; z-index: 2; }

/* Bordas Coloridas Laterais */
.border-l-blue { border-left-color: #2196F3 !important; }
.border-l-purple { border-left-color: #9C27B0 !important; }
.border-l-cyan { border-left-color: #00BCD4 !important; }
.border-l-warning { border-left-color: #FFC107 !important; }
.border-l-orange { border-left-color: #FF9800 !important; }
.border-l-grey { border-left-color: #78909C !important; }
.border-l-dark { border-left-color: #263238 !important; }
.border-l-green { border-left-color: #4CAF50 !important; }
.border-l-teal { border-left-color: #009688 !important; }
.border-l-legacy { border-left-color: #D32F2F !important; }

/* Ghost Card (Drag Placeholder) */
.ghost-card {
    opacity: 0.4;
    background: #e0e0e0;
    border: 2px dashed #999 !important;
    box-shadow: none !important;
}

/* Scrollbars */
.custom-scroll::-webkit-scrollbar { width: 6px; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.3); border-radius: 3px; }
.custom-scroll-x::-webkit-scrollbar { height: 8px; }
.custom-scroll-x::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.3); border-radius: 4px; }
.custom-scroll-x::-webkit-scrollbar-track { background: transparent; }

/* Utility */
.bg-glass-card { background: rgba(255,255,255,0.03); border: 1px solid rgba(255,255,255,0.08); }
.bg-surface-card { background-color: rgba(255, 255, 255, 0.05); }
.line-clamp-2 { display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; }
</style>
