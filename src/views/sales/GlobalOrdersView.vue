<template>
  <div
    class="global-orders-layout font-sans fill-height d-flex flex-column relative overflow-hidden"
    :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 text-grey-darken-4' : 'bg-glass-dark text-white'"
  >
    <div v-if="themeStore.currentMode !== 'light'" class="background-carousel-wrapper">
      <v-carousel cycle height="100%" hide-delimiters :show-arrows="false" interval="15000" class="fill-height">
        <v-carousel-item src="@/assets/1.jpg" cover></v-carousel-item>
        <v-carousel-item src="@/assets/2.jpg" cover></v-carousel-item>
        <v-carousel-item src="@/assets/3.jpg" cover></v-carousel-item>
      </v-carousel>
      <div class="background-overlay"></div>
    </div>

    <div class="content-wrapper d-flex flex-column fill-height z-10 relative">

      <div
        class="header-bar px-4 py-3 px-md-6 py-md-4 d-flex flex-column flex-md-row align-md-center justify-space-between flex-shrink-0"
        :class="themeStore.currentMode === 'light' ? 'bg-white border-b border-grey-lighten-2 shadow-sm' : 'bg-glass-header border-bottom-white-05'"
        style="gap: 12px;"
      >
        <div class="d-flex flex-column">
          <div class="breadcrumb text-caption d-none d-md-block">
            <span class="opacity-70">Vendas</span>
            <span class="mx-2 opacity-50">></span>
            <span class="font-weight-bold">Consulta Global (ERP)</span>
          </div>
          <div class="d-flex align-center gap-2 mt-1">
             <div class="text-h6 font-weight-black tracking-tight leading-none" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">
                Todos os Pedidos
             </div>
             <v-chip size="x-small" color="primary" class="font-weight-bold ml-2 rounded-sm">
                Loja ERP: 523283
             </v-chip>
          </div>
        </div>

        <div class="d-flex align-center overflow-x-auto pb-1 pb-md-0" style="gap: 10px;">
          <v-btn
            color="red-darken-3"
            variant="tonal"
            class="btn-rect rounded-sm px-3 px-md-4 font-weight-bold text-caption text-uppercase letter-spacing-1 flex-shrink-0"
            prepend-icon="mdi-file-pdf-box"
            height="40"
            :loading="reportLoading"
            @click="generateReport('pdf')"
          >
            Exportar PDF
          </v-btn>

          <v-btn
            v-if="userStore.isSuperAdmin"
            color="success"
            variant="flat"
            class="btn-rect rounded-sm px-3 px-md-6 font-weight-bold text-caption text-uppercase letter-spacing-1 flex-shrink-0"
            prepend-icon="mdi-cloud-sync"
            height="40"
            @click="syncFromERP"
          >
            Sincronizar e Salvar
          </v-btn>
        </div>
      </div>

      <div class="px-4 px-md-6 py-2 flex-shrink-0">
        <v-row>
          <v-col cols="12" sm="6" :md="userStore.isSuperAdmin ? 4 : 6">
            <v-card class="kpi-card kpi-rect rounded-sm bg-gradient-info py-3 px-4 elevation-2 border-0">
              <div class="kpi-bg-icon"><v-icon>mdi-shopping-outline</v-icon></div>
              <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                <div class="d-flex align-center" style="gap: 8px;">
                  <v-icon size="18" class="opacity-80">mdi-shopping-outline</v-icon>
                  <span class="kpi-label">Total Pedidos</span>
                </div>
                <div class="kpi-number-group my-1">
                  <span class="kpi-value">{{ kpiTotals.count }}</span>
                </div>
                <div class="kpi-footer mt-1">No período e filtro atual</div>
              </div>
            </v-card>
          </v-col>

          <v-col cols="12" sm="6" md="4" v-if="userStore.isSuperAdmin">
            <v-card class="kpi-card kpi-rect rounded-sm bg-gradient-green py-3 px-4 elevation-2 border-0">
              <div class="kpi-bg-icon"><v-icon>mdi-cash-multiple</v-icon></div>
              <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                <div class="d-flex align-center" style="gap: 8px;">
                  <v-icon size="18" class="opacity-80">mdi-cash-multiple</v-icon>
                  <span class="kpi-label">Faturamento Total</span>
                </div>
                <div class="kpi-number-group my-1">
                  <span class="text-body-2 font-weight-medium mr-1 opacity-70">R$</span>
                  <span class="kpi-value">{{ formatCurrencyValue(kpiTotals.value) }}</span>
                </div>
                <div class="kpi-footer mt-1">Soma do valor bruto</div>
              </div>
            </v-card>
          </v-col>

          <v-col cols="12" sm="6" :md="userStore.isSuperAdmin ? 4 : 6">
            <v-card class="kpi-card kpi-rect rounded-sm bg-gradient-purple py-3 px-4 elevation-2 border-0">
              <div class="kpi-bg-icon"><v-icon>mdi-tape-measure</v-icon></div>
              <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                <div class="d-flex align-center" style="gap: 8px;">
                  <v-icon size="18" class="opacity-80">mdi-tape-measure</v-icon>
                  <span class="kpi-label">Metragem Vendida</span>
                </div>
                <div class="kpi-number-group my-1">
                  <span class="kpi-value">{{ formatMeters(kpiTotals.meters) }}</span>
                  <span class="text-body-2 font-weight-medium ml-1 opacity-70">m</span>
                </div>
                <div class="kpi-footer mt-1">Quantidade de estampas/tecidos</div>
              </div>
            </v-card>
          </v-col>
        </v-row>
      </div>

      <div class="px-4 px-md-6 pt-0 pb-2 flex-shrink-0">
        <div
          class="controls-bar rounded-sm border-thin d-flex flex-column"
          :class="themeStore.currentMode === 'light' ? 'controls-light' : 'controls-dark'"
          style="gap: 10px;"
        >
          <div class="d-flex flex-column flex-md-row align-start align-md-center justify-space-between" style="gap: 10px;">
            <div class="d-flex align-center flex-wrap w-100 w-md-auto" style="gap: 10px;">
              <v-menu location="bottom start" :close-on-content-click="true">
                <template v-slot:activator="{ props }">
                  <v-btn v-bind="props" variant="outlined" class="btn-rect rounded-sm flex-grow-1 flex-md-grow-0" height="40" prepend-icon="mdi-calendar-range" color="primary">
                    Período
                    <v-icon end size="small">mdi-chevron-down</v-icon>
                  </v-btn>
                </template>
                <v-card class="rounded-sm" min-width="220">
                  <v-list density="compact" nav>
                    <v-list-item @click="applyPreset('month')"><v-list-item-title class="font-weight-bold">Este Mês</v-list-item-title></v-list-item>
                    <v-list-item @click="applyPreset('last_month')"><v-list-item-title class="font-weight-bold">Mês Passado</v-list-item-title></v-list-item>
                    <v-list-item @click="applyPreset('year')"><v-list-item-title class="font-weight-bold">Este Ano</v-list-item-title></v-list-item>
                  </v-list>
                </v-card>
              </v-menu>

              <div class="period-nav rounded-sm border-thin d-flex align-center justify-center flex-grow-1 flex-md-grow-0" :class="themeStore.currentMode === 'light' ? 'period-nav-light' : 'period-nav-dark'">
                 <div class="period-label text-caption font-weight-black text-center px-4 d-flex align-center" style="height: 40px;">
                    <input type="date" v-model="filters.start" class="clean-input text-center font-weight-bold mx-1" @change="fetchLocalOrders">
                    <span class="opacity-50 mx-1">até</span>
                    <input type="date" v-model="filters.end" class="clean-input text-center font-weight-bold mx-1" @change="fetchLocalOrders">
                 </div>
              </div>
            </div>

            <div class="d-flex align-center flex-wrap justify-end w-100 w-md-auto" style="gap: 10px;">
              <div class="search-wrap rounded-sm border-thin d-flex align-center flex-grow-1 flex-md-grow-0" :class="themeStore.currentMode === 'light' ? 'search-light' : 'search-dark'" style="min-width: 400px;">
                <v-icon :color="themeStore.currentMode === 'light' ? 'primary' : 'white-70'">mdi-text-box-search-outline</v-icon>
                <input
                  v-model="searchQuery"
                  type="text"
                  placeholder="Pesquisar estampa, serviço, cliente, OP..."
                  class="clean-input flex-grow-1 text-uppercase font-weight-bold pl-2"
                />
                <v-chip v-if="searchQuery" size="x-small" color="primary" class="font-weight-bold ml-2 rounded-sm">Varredura Global</v-chip>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="flex-grow-1 px-4 px-md-6 pb-0 overflow-hidden d-flex flex-column transition-all">
        <v-card
          class="flex-grow-1 d-flex flex-column rounded-sm border-thin overflow-hidden"
          :class="themeStore.currentMode === 'light' ? 'bg-white shadow-sm' : 'glass-card border-white-05'"
          :elevation="0"
        >
          <div class="grid-scroll flex-grow-1 overflow-auto custom-scroll relative">

            <div
              class="grid-header sticky-head"
              :class="[themeStore.currentMode === 'light' ? 'grid-surface-light' : 'grid-surface-dark']"
              :style="{ gridTemplateColumns: gridColumnsTemplate }"
            >
              <div class="cell center header-text"># OP</div>
              <div class="cell header-text">Cliente</div>
              <div class="cell header-text">Vendedor</div>
              <div class="cell center header-text">Data</div>
              <div v-if="userStore.isSuperAdmin" class="cell center header-text">Valor Total</div>
              <div class="cell header-text">Itens e Serviços</div>
              <div class="cell center header-text">Ações</div>
            </div>

            <div v-if="loading" class="d-flex flex-column justify-center align-center h-100 py-10 min-w-full">
              <v-progress-circular indeterminate color="primary" size="48" width="4"></v-progress-circular>
              <span class="text-caption mt-4 font-weight-bold opacity-60">Buscando do banco de dados...</span>
            </div>

            <div v-else-if="paginatedItems.length === 0" class="d-flex flex-column justify-center align-center h-100 opacity-60 gap-2 py-10 min-w-full">
              <v-icon size="48" color="grey-lighten-1">mdi-database-search-outline</v-icon>
              <span class="text-body-2 font-weight-medium text-grey">Nenhum pedido encontrado. Tente sincronizar.</span>
            </div>

            <div
              v-else
              v-for="(item, index) in paginatedItems"
              :key="item.id"
              class="grid-row cursor-pointer"
              @click="openDetailModal(item)"
              :class="[
                themeStore.currentMode === 'light' ? 'grid-row-light' : 'grid-row-dark',
                zebraClass(index)
              ]"
              :style="{ gridTemplateColumns: gridColumnsTemplate }"
            >
                <div class="cell center">
                    <span class="pill-ref rounded-sm text-blue-darken-2 font-weight-black">#{{ item.codigo }}</span>
                </div>
                <div class="cell">
                    <div class="text-truncate list-text-11 font-weight-bold w-100" :title="item.nome_cliente">{{ item.nome_cliente }}</div>
                </div>
                <div class="cell">
                    <div class="text-truncate list-text-11 opacity-80 w-100" :title="item.nome_vendedor">{{ item.nome_vendedor || 'N/A' }}</div>
                </div>
                <div class="cell center">
                    <span class="list-text-11 font-mono font-weight-medium">{{ formatDateSafe(item.data) }}</span>
                </div>

                <div v-if="userStore.isSuperAdmin" class="cell center">
                    <span class="list-text-11 font-mono font-weight-black text-success-darken-2">
                        {{ formatCurrency(item.valor_total) }}
                    </span>
                </div>

                <div class="cell">
                    <div class="text-truncate w-100 list-text-11 text-grey-darken-3 font-weight-medium" :title="getItemsSummary(item)">
                        {{ getItemsSummary(item) }}
                    </div>
                </div>
                <div class="cell center">
                     <v-btn icon size="small" color="primary" variant="tonal" class="rounded-sm" title="Ver Detalhes">
                         <v-icon size="16">mdi-arrow-right</v-icon>
                     </v-btn>
                </div>
            </div>
          </div>

          <div class="flex-shrink-0 border-t px-4 py-2 d-flex flex-column flex-md-row align-center justify-space-between bg-grey-lighten-4 z-20">
            <div class="text-caption opacity-80 mb-2 mb-md-0 font-weight-bold">
               Mostrando <strong>{{ paginatedItems.length }}</strong> de <strong>{{ filteredItems.length }}</strong> registros no cache local.
            </div>

            <v-pagination
              v-model="page"
              :length="pageCount"
              :total-visible="5"
              density="compact"
              active-color="primary"
              variant="tonal"
              size="small"
            ></v-pagination>
          </div>
        </v-card>
      </div>
    </div>

    <v-dialog v-model="syncModal.show" persistent max-width="400">
      <v-card class="pa-6 rounded-sm text-center border-thin" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-grey-darken-4 text-white'">
          <v-icon size="48" color="success" class="mb-4">mdi-cloud-sync</v-icon>
          <h3 class="text-h6 font-weight-black mb-2">Sincronizando ERP</h3>
          <p class="text-caption opacity-70 mb-4">Puxando e salvando pedidos do GestãoClick para o banco de dados seguro da MJProcess.</p>

          <v-progress-linear
            v-model="syncModal.progress"
            color="success"
            height="20"
            striped
            rounded
          >
            <template v-slot:default="{ value }">
               <strong class="text-white" style="font-size: 11px;">{{ Math.ceil(value) }}%</strong>
            </template>
          </v-progress-linear>

          <div class="text-caption font-weight-bold mt-3 font-mono">
              Processado: {{ syncModal.current }} / {{ syncModal.total }} pedidos
          </div>
      </v-card>
    </v-dialog>

    <v-dialog v-model="detailModal.show" max-width="850" scrollable transition="dialog-bottom-transition">
      <div class="modal-content-wrapper rounded-sm shadow-2xl d-flex flex-column overflow-hidden h-100" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-grey-darken-4 border-thin'">

        <div class="modal-header d-flex justify-space-between align-center pa-5 border-b" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-4 border-grey-lighten-2' : 'bg-grey-darken-3 border-white-05'">
           <div>
              <div class="text-[10px] font-weight-black uppercase text-grey tracking-widest mb-1">Detalhes da Venda ERP</div>
              <div class="text-h5 font-weight-black text-blue-darken-3 lh-1">#{{ detailModal.order?.codigo }}</div>
           </div>
           <v-btn icon="mdi-close" variant="text" size="small" @click="detailModal.show = false"></v-btn>
        </div>

        <div class="modal-body flex-grow-1 overflow-y-auto custom-scroll pa-6">

           <div class="info-ticket border-thin rounded-sm d-flex flex-column flex-md-row mb-6 overflow-hidden" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-transparent'">
              <div class="pa-4 flex-grow-1 border-r-md border-b border-b-md-0" :class="themeStore.currentMode === 'light' ? 'border-grey-lighten-2' : 'border-white-05'">
                  <div class="text-[10px] font-weight-black text-grey uppercase tracking-wider mb-1">Cliente / Pagador</div>
                  <div class="text-body-1 font-weight-bold" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">{{ detailModal.order?.nome_cliente }}</div>
              </div>
              <div class="pa-4 flex-grow-1 border-r-md border-b border-b-md-0" :class="themeStore.currentMode === 'light' ? 'border-grey-lighten-2' : 'border-white-05'">
                  <div class="text-[10px] font-weight-black text-grey uppercase tracking-wider mb-1">Vendedor</div>
                  <div class="text-body-2 font-weight-medium" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-3' : 'text-grey-lighten-2'">{{ detailModal.order?.nome_vendedor || 'N/A' }}</div>
              </div>
              <div class="pa-4 flex-grow-1 d-flex flex-column justify-center">
                  <div class="d-flex align-center justify-space-between mb-2">
                      <span class="text-[10px] font-weight-black text-grey uppercase tracking-wider">Data do Pedido</span>
                      <span class="font-mono text-body-2 font-weight-bold">{{ formatDateSafe(detailModal.order?.data) }}</span>
                  </div>
                  <div class="d-flex align-center justify-space-between">
                      <span class="text-[10px] font-weight-black text-grey uppercase tracking-wider">Situação</span>
                      <span class="solid-chip rounded-sm bg-primary text-white" style="height: 20px; font-size: 10px; padding: 0 8px;">{{ detailModal.order?.nome_situacao }}</span>
                  </div>
              </div>
           </div>

           <div v-if="detailModal.order?.produtos && detailModal.order.produtos.length > 0">
               <div class="text-[11px] font-weight-black uppercase mb-2 tracking-widest pl-1" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-2' : 'text-grey-lighten-1'">
                   <v-icon size="14" class="mr-1">mdi-package-variant-closed</v-icon> Produtos
               </div>
               <div class="border-thin rounded-sm overflow-hidden mb-6" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-transparent'">
                   <div class="grid-header border-b" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-4 border-grey-lighten-2' : 'bg-grey-darken-3 border-white-05'" :style="{ display: 'grid', gridTemplateColumns: modalGridColumns, padding: '10px 16px' }">
                       <div class="font-weight-black text-[10px] uppercase text-grey">Qtd</div>
                       <div class="font-weight-black text-[10px] uppercase text-grey">Item / Detalhes</div>
                       <div v-if="userStore.isSuperAdmin" class="font-weight-black text-[10px] uppercase text-grey text-right">Unitário</div>
                       <div v-if="userStore.isSuperAdmin" class="font-weight-black text-[10px] uppercase text-grey text-right">Total</div>
                   </div>

                   <div v-for="(p, i) in detailModal.order?.produtos" :key="'p'+i" class="pa-4 align-center border-b-last-none" :class="themeStore.currentMode === 'light' ? 'border-grey-lighten-3' : 'border-white-05'" :style="{ display: 'grid', gridTemplateColumns: modalGridColumns, borderBottom: '1px solid' }">
                       <div class="font-mono font-weight-black text-body-2">{{ Number(p.produto?.quantidade) }}</div>
                       <div class="pr-3">
                           <div class="font-weight-bold text-body-2 lh-12">{{ p.produto?.nome_produto || 'Produto Genérico' }}</div>
                           <div class="text-[10px] text-grey mt-1 lh-12">{{ p.produto?.detalhes }}</div>
                       </div>
                       <div v-if="userStore.isSuperAdmin" class="font-mono text-right text-caption opacity-80">{{ formatCurrency(p.produto?.valor_venda) }}</div>
                       <div v-if="userStore.isSuperAdmin" class="font-mono font-weight-bold text-right text-body-2">{{ formatCurrency(p.produto?.valor_total) }}</div>
                   </div>
               </div>
           </div>

           <div v-if="detailModal.order?.servicos && detailModal.order.servicos.length > 0">
               <div class="text-[11px] font-weight-black uppercase mb-2 tracking-widest pl-1 text-orange-darken-3">
                   <v-icon size="14" class="mr-1">mdi-room-service-outline</v-icon> Serviços Adicionais
               </div>
               <div class="border-thin rounded-sm overflow-hidden mb-6" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-transparent'">
                   <div class="grid-header border-b" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-4 border-grey-lighten-2' : 'bg-grey-darken-3 border-white-05'" :style="{ display: 'grid', gridTemplateColumns: modalGridColumns, padding: '10px 16px' }">
                       <div class="font-weight-black text-[10px] uppercase text-grey">Qtd</div>
                       <div class="font-weight-black text-[10px] uppercase text-grey">Serviço</div>
                       <div v-if="userStore.isSuperAdmin" class="font-weight-black text-[10px] uppercase text-grey text-right">Unitário</div>
                       <div v-if="userStore.isSuperAdmin" class="font-weight-black text-[10px] uppercase text-grey text-right">Total</div>
                   </div>

                   <div v-for="(s, i) in detailModal.order?.servicos" :key="'s'+i" class="pa-4 align-center border-b-last-none" :class="themeStore.currentMode === 'light' ? 'border-grey-lighten-3' : 'border-white-05'" :style="{ display: 'grid', gridTemplateColumns: modalGridColumns, borderBottom: '1px solid' }">
                       <div class="font-mono font-weight-black text-body-2 text-orange-darken-3">{{ Number(s.servico?.quantidade) }}</div>
                       <div class="pr-3">
                           <div class="font-weight-bold text-body-2 lh-12">{{ s.servico?.nome_servico || s.servico?.nome || 'Serviço' }}</div>
                           <div class="text-[10px] text-grey mt-1 lh-12" v-if="s.servico?.detalhes || s.servico?.observacoes">{{ s.servico?.detalhes || s.servico?.observacoes }}</div>
                       </div>
                       <div v-if="userStore.isSuperAdmin" class="font-mono text-right text-caption opacity-80">{{ formatCurrency(s.servico?.valor_venda) }}</div>
                       <div v-if="userStore.isSuperAdmin" class="font-mono font-weight-bold text-right text-body-2">{{ formatCurrency(s.servico?.valor_total) }}</div>
                   </div>
               </div>
           </div>

        </div>

        <div class="modal-footer pa-5 border-t d-flex justify-space-between align-center flex-shrink-0" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-grey-darken-4 border-white-05'">
            <div class="text-[10px] opacity-50 font-weight-bold uppercase">Registro Interno ERP</div>

            <div v-if="userStore.isSuperAdmin" class="text-right">
                <div class="text-[11px] font-weight-black text-grey uppercase tracking-widest mb-1">Valor Total da Venda</div>
                <div class="text-h4 font-weight-black text-success lh-1">{{ formatCurrency(detailModal.order?.valor_total) }}</div>
            </div>
            <div v-else>
                </div>
        </div>

      </div>
    </v-dialog>

  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, reactive } from 'vue';
import { format, startOfMonth, endOfMonth, subMonths, startOfYear, endOfYear } from 'date-fns';
import { useThemeStore } from '@/stores/theme';
import { useAppStore } from '@/stores/app';
import { useUserStore } from '@/stores/user';
import { gestaoApi } from '@/api/gestaoClick';
import { supabase } from '@/api/supabase';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';

const themeStore = useThemeStore();
const appStore = useAppStore();
const userStore = useUserStore();

const loading = ref(false);
const reportLoading = ref(false);
const allOrders = ref<any[]>([]); // Array of Raw JSON data
const searchQuery = ref('');
const page = ref(1);
const itemsPerPage = 30;

const syncModal = reactive({ show: false, progress: 0, total: 0, current: 0 });
const detailModal = reactive({ show: false, order: null as any });

const filters = reactive({
    start: format(startOfMonth(new Date()), 'yyyy-MM-dd'),
    end: format(endOfMonth(new Date()), 'yyyy-MM-dd')
});

const kpiTotals = reactive({ count: 0, value: 0, meters: 0 });

// === GRID COLUMNS COMPUTED ===
const gridColumnsTemplate = computed(() => {
    // Se for admin mostra valor. Se não for admin, tira a coluna de valor (100px a menos) e redistribui.
    return userStore.isSuperAdmin
        ? '80px minmax(200px, 1.5fr) minmax(120px, 1fr) 100px 120px minmax(250px, 2fr) 60px'
        : '80px minmax(200px, 1.5fr) minmax(120px, 1fr) 100px minmax(250px, 2fr) 60px';
});

// Modal grid columns (Sem colunas de valor se não for admin)
const modalGridColumns = computed(() => {
    return userStore.isSuperAdmin ? '60px 1fr 120px 120px' : '60px 1fr';
});

// RESUMO DE ITENS (Numa só string para não esticar a row)
const getItemsSummary = (order: any) => {
    const parts: string[] = [];
    if (order.produtos && order.produtos.length > 0) {
        order.produtos.forEach((p: any) => {
            const qtd = Number(p.produto?.quantidade || 0);
            const nome = p.produto?.nome_produto || p.produto?.detalhes || 'Produto';
            parts.push(`${qtd}x ${nome}`);
        });
    }
    if (order.servicos && order.servicos.length > 0) {
        order.servicos.forEach((s: any) => {
            const qtd = Number(s.servico?.quantidade || 0);
            const nome = s.servico?.nome_servico || s.servico?.nome || 'Serviço';
            parts.push(`${qtd}x ${nome}`);
        });
    }
    return parts.length > 0 ? parts.join(' | ') : 'Nenhum item detalhado';
};

const applyPreset = (preset: string) => {
    const today = new Date();
    if (preset === 'month') {
        filters.start = format(startOfMonth(today), 'yyyy-MM-dd');
        filters.end = format(endOfMonth(today), 'yyyy-MM-dd');
    } else if (preset === 'last_month') {
        filters.start = format(startOfMonth(subMonths(today, 1)), 'yyyy-MM-dd');
        filters.end = format(endOfMonth(subMonths(today, 1)), 'yyyy-MM-dd');
    } else if (preset === 'year') {
        filters.start = format(startOfYear(today), 'yyyy-MM-dd');
        filters.end = format(endOfYear(today), 'yyyy-MM-dd');
    }
    fetchLocalOrders();
};

// CARREGA OS DADOS DO CACHE (SUPABASE)
const fetchLocalOrders = async () => {
    loading.value = true;
    try {
        const { data, error } = await supabase
            .from('erp_orders_cache')
            .select('raw_data')
            .gte('data', filters.start)
            .lte('data', filters.end)
            .order('data', { ascending: false });

        if (error) throw error;

        allOrders.value = (data || []).map(d => d.raw_data);
        page.value = 1;
    } catch (error: any) {
        console.error(error);
        appStore.showSnackbar('Erro ao ler cache local. Certifique-se de que a tabela erp_orders_cache foi criada.', 'error');
    } finally {
        loading.value = false;
    }
};

// BUSCA DO GESTÃO CLICK E SALVA NO SUPABASE EM LOTES (SUPER ADMIN)
const syncFromERP = async () => {
    syncModal.progress = 0;
    syncModal.current = 0;
    syncModal.total = 0;
    syncModal.show = true;

    try {
        const responseData = await gestaoApi.buscarVendas({
            data_inicio: filters.start,
            data_fim: filters.end
        });

        if (!responseData || responseData.length === 0) {
            appStore.showSnackbar('Nenhum pedido encontrado no ERP para este período.', 'info');
            syncModal.show = false;
            return;
        }

        syncModal.total = responseData.length;
        const chunkSize = 40;

        for (let i = 0; i < responseData.length; i += chunkSize) {
            const chunk = responseData.slice(i, i + chunkSize);

            const payload = chunk.map(o => ({
                id: Number(o.id),
                codigo: o.codigo,
                cliente_nome: o.nome_cliente,
                vendedor_nome: o.nome_vendedor,
                data: o.data,
                valor_total: Number(o.valor_total),
                raw_data: o
            }));

            const { error } = await supabase.from('erp_orders_cache').upsert(payload, { onConflict: 'id' });

            if (error) throw error;

            syncModal.current += chunk.length;
            syncModal.progress = (syncModal.current / syncModal.total) * 100;
        }

        appStore.showSnackbar(`Sincronização de ${syncModal.total} pedidos concluída!`, 'success');

        await fetchLocalOrders();

    } catch (error: any) {
        console.error(error);
        appStore.showSnackbar('Falha ao sincronizar dados. Verifique sua conexão e a estrutura da tabela.', 'error');
    } finally {
        setTimeout(() => { syncModal.show = false; }, 800);
    }
};

// LÓGICA DE PESQUISA GLOBAL
const filteredItems = computed(() => {
    let result = allOrders.value;
    const term = searchQuery.value.trim().toLowerCase();

    if (term) {
        result = result.filter(order => {
            if (order.nome_cliente && order.nome_cliente.toLowerCase().includes(term)) return true;
            if (String(order.codigo).includes(term)) return true;
            if (order.nome_vendedor && order.nome_vendedor.toLowerCase().includes(term)) return true;

            if (order.produtos && Array.isArray(order.produtos)) {
                const encontrouProd = order.produtos.some((p: any) => {
                    const nome = p.produto?.nome_produto ? p.produto.nome_produto.toLowerCase() : '';
                    const detalhes = p.produto?.detalhes ? p.produto.detalhes.toLowerCase() : '';
                    return nome.includes(term) || detalhes.includes(term);
                });
                if (encontrouProd) return true;
            }

            if (order.servicos && Array.isArray(order.servicos)) {
                const encontrouServ = order.servicos.some((s: any) => {
                    const nome = s.servico?.nome_servico ? s.servico.nome_servico.toLowerCase() : (s.servico?.nome ? s.servico.nome.toLowerCase() : '');
                    const detalhes = s.servico?.detalhes ? s.servico.detalhes.toLowerCase() : (s.servico?.observacoes ? s.servico.observacoes.toLowerCase() : '');
                    return nome.includes(term) || detalhes.includes(term);
                });
                if (encontrouServ) return true;
            }

            return false;
        });
    }

    let totalValue = 0;
    let totalMeters = 0;
    result.forEach(o => {
        totalValue += Number(o.valor_total || 0);
        if (o.produtos) {
            o.produtos.forEach((p: any) => {
                totalMeters += Number(p.produto?.quantidade || 0);
            });
        }
    });

    kpiTotals.count = result.length;
    kpiTotals.value = totalValue;
    kpiTotals.meters = totalMeters;

    return result;
});

const pageCount = computed(() => Math.ceil(filteredItems.value.length / itemsPerPage) || 1);

const paginatedItems = computed(() => {
    const start = (page.value - 1) * itemsPerPage;
    return filteredItems.value.slice(start, start + itemsPerPage);
});

// Ações
const openDetailModal = (order: any) => {
    detailModal.order = order;
    detailModal.show = true;
};

// Utils
const formatDateSafe = (dateString: string) => dateString ? dateString.split('-').reverse().join('/') : '-';
const formatCurrency = (val: any) => new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(Number(val) || 0);
const formatCurrencyValue = (val: any) => new Intl.NumberFormat('pt-BR', { minimumFractionDigits: 2 }).format(Number(val) || 0);
const formatMeters = (val: any) => new Intl.NumberFormat('pt-BR').format(Number(val) || 0);
const zebraClass = (i: number) => themeStore.currentMode !== 'light' ? (i % 2 === 0 ? 'zebra-dark-a' : 'zebra-dark-b') : (i % 2 === 0 ? 'zebra-light-a' : 'zebra-light-b');

// GERAÇÃO DE PDF (Apenas se for Admin)
const imageToBase64 = async (url: string): Promise<string> => {
    try {
        const res = await fetch(url);
        const blob = await res.blob();
        return new Promise((resolve) => {
            const reader = new FileReader();
            reader.onload = () => resolve(reader.result as string);
            reader.readAsDataURL(blob);
        });
    } catch { return ''; }
};

const generateReport = async (type: string) => {
    if (!userStore.isSuperAdmin) {
        return appStore.showSnackbar('Exportação disponível apenas para administradores.', 'warning');
    }

    if (filteredItems.value.length === 0) {
        return appStore.showSnackbar('Nenhum dado para exportar.', 'warning');
    }

    reportLoading.value = true;
    try {
        const doc = new jsPDF({ orientation: 'p', unit: 'mm', format: 'a4' });
        const pageWidth = doc.internal.pageSize.width;
        const pageHeight = doc.internal.pageSize.height;
        const logoUrl = 'https://cdn.shopify.com/s/files/1/0661/4574/6991/files/Sem_nome_1080_x_800_px_1080_x_500_px_1080_x_400_px_1000_x_380_px_da020cf2-2bb9-4dac-8dd3-4548cfd2e5ae.png?v=1756811713';
        const logoBase64 = await imageToBase64(logoUrl);

        const renderCoverPage = () => {
            if (logoBase64) doc.addImage(logoBase64, 'PNG', 15, 15, 35, 12);

            doc.setFontSize(22).setFont('helvetica', 'bold').setTextColor(30, 30, 30);
            doc.text("RELATÓRIO GLOBAL DE VENDAS ERP", pageWidth / 2, 50, { align: 'center' });

            doc.setFontSize(11).setFont('helvetica', 'normal').setTextColor(100);
            doc.text(`Período Base: ${formatDateSafe(filters.start)} até ${formatDateSafe(filters.end)}`, pageWidth / 2, 60, { align: 'center' });

            if (searchQuery.value) {
                doc.setTextColor(46, 125, 50);
                doc.text(`Filtro Ativo: "${searchQuery.value.toUpperCase()}"`, pageWidth / 2, 66, { align: 'center' });
            }

            const drawCoverKpi = (label: string, val: string, color: number[], x: number, y: number) => {
                doc.setFillColor(color[0], color[1], color[2]);
                doc.roundedRect(x, y, 80, 32, 3, 3, 'F');
                doc.setDrawColor(color[0]-30, color[1]-30, color[2]-30);
                doc.roundedRect(x, y, 80, 32, 3, 3, 'S');

                doc.setFontSize(9).setFont('helvetica', 'bold').setTextColor(120, 120, 120);
                doc.text(label.toUpperCase(), x + 40, y + 10, { align: 'center' });

                doc.setFontSize(18).setFont('helvetica', 'bold').setTextColor(30, 30, 30);
                doc.text(val, x + 40, y + 23, { align: 'center' });
            };

            const xLeft = (pageWidth / 2) - 85;
            const xRight = (pageWidth / 2) + 5;

            drawCoverKpi("Total de Pedidos", String(kpiTotals.count), [240, 244, 248], xLeft, 85);
            drawCoverKpi("Faturamento Bruto", formatCurrency(kpiTotals.value), [232, 248, 235], xRight, 85);
            drawCoverKpi("Metragem Total", `${formatMeters(kpiTotals.meters)} m`, [243, 229, 245], xLeft, 125);
            drawCoverKpi("Loja Origem", "ERP 523283", [255, 248, 225], xRight, 125);

            const nowStr = format(new Date(), 'dd/MM/yyyy HH:mm');
            doc.setFontSize(8).setTextColor(150);
            doc.text(`Gerado em ${nowStr} por ${userStore.user?.email || 'Sistema'}`, pageWidth / 2, pageHeight - 15, { align: 'center' });
        };

        renderCoverPage();
        doc.addPage();

        if (logoBase64) doc.addImage(logoBase64, 'PNG', 15, 10, 30, 10);
        doc.setFontSize(14).setFont('helvetica', 'bold').setTextColor(20);
        doc.text("Detalhamento de Pedidos Filtrados", 15, 32);

        const columns = [
            { header: 'Ref', dataKey: 'ref' },
            { header: 'Data', dataKey: 'date_str' },
            { header: 'Cliente', dataKey: 'entity' },
            { header: 'Vendedor', dataKey: 'seller' },
            { header: 'Resumo Itens/Serviços', dataKey: 'items' },
            { header: 'Valor', dataKey: 'value' }
        ];

        const tableBody = filteredItems.value.map(row => {
            const summary = getItemsSummary(row);
            return {
                ref: `#${row.codigo}`,
                date_str: formatDateSafe(row.data),
                entity: row.nome_cliente.substring(0, 25),
                seller: (row.nome_vendedor || '-').substring(0, 15),
                items: summary.substring(0, 45) + '...',
                value: formatCurrency(row.valor_total)
            };
        });

        autoTable(doc, {
            startY: 38,
            columns: columns,
            body: tableBody,
            theme: 'grid',
            styles: { fontSize: 7, cellPadding: 2.5, textColor: 50, lineColor: [200, 200, 200], lineWidth: 0.1 },
            headStyles: { fillColor: [40, 40, 40], textColor: 255, fontStyle: 'bold', halign: 'center' },
            columnStyles: {
                ref: { cellWidth: 16, fontStyle: 'bold', halign: 'center' },
                date_str: { cellWidth: 18, halign: 'center' },
                entity: { cellWidth: 'auto' },
                seller: { cellWidth: 30 },
                items: { cellWidth: 50 },
                value: { cellWidth: 24, halign: 'right', fontStyle: 'bold', textColor: [46, 125, 50] }
            },
            didDrawPage: () => {
                doc.setFontSize(7).setTextColor(150);
                doc.text(`Pág ${doc.internal.getNumberOfPages()}`, pageWidth - 15, pageHeight - 10, { align: 'right' });
            }
        });

        doc.save(`Relatorio_Global_Vendas_${format(new Date(), 'yyyyMMdd_HHmm')}.pdf`);
        appStore.showSnackbar('PDF Gerado com Sucesso!', 'success');

    } catch (e: any) {
        console.error(e);
        appStore.showSnackbar('Erro ao gerar PDF', 'error');
    } finally {
        reportLoading.value = false;
    }
};

onMounted(() => {
    fetchLocalOrders();
});
</script>

<style scoped lang="scss">
.global-orders-layout { position: relative; }
.bg-glass-dark { background: rgba(10,10,12,0.85); }
.bg-glass-header { background: rgba(20,20,24,0.55); backdrop-filter: blur(14px); }
.border-bottom-white-05 { border-bottom: 1px solid rgba(255,255,255,0.08); }
.background-carousel-wrapper { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 0; opacity: 0.6; pointer-events: none; }
.background-overlay { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 1; background: radial-gradient(circle at center, rgba(15, 15, 19, 0.4), rgba(15, 15, 19, 0.98)); backdrop-filter: blur(8px); }
.z-10 { position: relative; z-index: 10; }

.btn-rect { text-transform: none !important; font-weight: 800; }
.controls-bar { padding: 10px; }
.controls-light { background: #ffffff; }
.controls-dark { background: rgba(30,30,35,0.55); backdrop-filter: blur(16px); }
.search-wrap { height: 40px; padding: 0 12px; display: flex; align-items: center; flex: 1; }
.search-light { background: #f4f6f8; }
.search-dark { background: rgba(255,255,255,0.08); }
.clean-input { border: none; outline: none; flex: 1; font-size: 13px; background: transparent; color: inherit; }

.period-nav { height: 40px; overflow: hidden; }
.period-nav-light { background: #fafafa; }
.period-nav-dark { background: rgba(255,255,255,0.06); }

/* Grid e Scroll */
.grid-scroll { scrollbar-gutter: stable; -webkit-overflow-scrolling: touch; }
.custom-scroll::-webkit-scrollbar { width: 8px; height: 8px; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.35); border-radius: 6px; }
.custom-scroll::-webkit-scrollbar-track { background: transparent; }

.grid-header, .grid-row {
    display: grid;
    align-items: stretch;
    width: 100%;
}

/* FIXA ALTURA DA LINHA E EVITA QUEBRA DE TEXTO */
.cell {
    padding: 6px 12px;
    display: flex;
    align-items: center;
    border-right: 1px solid rgba(0,0,0,0.08);
    border-bottom: 1px solid rgba(0,0,0,0.08);
    height: 48px; /* Altura cravada, não estica */
    overflow: hidden;
    white-space: nowrap;
    transition: background-color 0.2s ease;
}

.grid-header .cell {
    height: 44px; /* Altura do cabeçalho */
    font-size: 14px !important;
    font-weight: 800;
    text-transform: uppercase;
    letter-spacing: 0.5px;
    line-height: 1.2;
}

.center { justify-content: center; text-align: center; }
.list-text-11 { font-size: 14px !important; line-height: 1.2 !important; }
.pill-ref { font-size: 12px !important; font-family: monospace; padding: 4px 8px; white-space: nowrap; background: rgba(0,0,0,0.05); }

/* Themes do Grid */
.grid-surface-light .cell { background: #f5f7fa; color: rgba(0,0,0,0.9); border-color: rgba(0,0,0,0.12) !important; }
.grid-surface-dark .cell { background: rgba(255,255,255,0.08); color: rgba(255,255,255,0.95); border-color: rgba(255,255,255,0.1) !important; }
.grid-row-light .cell { border-color: rgba(0,0,0,0.08) !important; }
.grid-row-dark .cell { border-color: rgba(255,255,255,0.08) !important; }
.zebra-light-a .cell { background: #ffffff; }
.zebra-light-b .cell { background: #f0f4f8; }
.zebra-dark-a .cell { background: rgba(0,0,0,0.15); }
.zebra-dark-b .cell { background: rgba(255,255,255,0.03); }
.grid-row-light:hover .cell { background: #e3f2fd !important; }
.grid-row-dark:hover .cell { background: rgba(255,255,255,0.12) !important; }

/* KPIs */
.kpi-card { color: white; position: relative; min-height: 110px; overflow: hidden; }
.kpi-bg-icon { position: absolute; right: -20px; bottom: -20px; opacity: 0.15; transform: rotate(-15deg); }
.kpi-bg-icon .v-icon { font-size: 100px; color: white; }
.bg-gradient-info { background: linear-gradient(135deg, #0288d1, #005b9f); }
.bg-gradient-green { background: linear-gradient(135deg, #2e7d32, #1b5e20); }
.bg-gradient-purple { background: linear-gradient(135deg, #7b1fa2, #4a148c); }
.kpi-label { font-size: 12px; font-weight: 900; letter-spacing: .2px; text-transform: uppercase; }
.kpi-value { font-size: 24px; font-weight: 900; }
.kpi-footer { font-size: 11px; opacity: .9; font-weight: 700; }

/* Utilitários Visuais */
.flex-grow-1.overflow-hidden > .v-card.flex-grow-1 { border: 1px solid rgba(0,0,0,0.12) !important; }
.bg-glass-dark .flex-grow-1.overflow-hidden > .v-card.flex-grow-1 { border: 1px solid rgba(255,255,255,0.12) !important; }
.sticky-head { position: sticky; top: 0; z-index: 20; box-shadow: 0 8px 16px -4px rgba(0, 0, 0, 0.12); }
.bg-glass-dark .sticky-head { box-shadow: 0 8px 20px -4px rgba(0, 0, 0, 0.4); }

.border-thin { border: 1px solid rgba(128,128,128,0.2) !important; }
.border-b-last-none:last-child { border-bottom: none !important; }
.rounded-sm { border-radius: 4px !important; }
.lh-1 { line-height: 1 !important; }
.lh-12 { line-height: 1.2 !important; }

/* MODAL DE DETALHES ELEGANTE */
.modal-content-wrapper { max-height: 90vh; }
.glassmorphism-card-dialog { background: rgba(30, 30, 35, 0.95) !important; backdrop-filter: blur(20px); }
.info-ticket { overflow: hidden; }
.border-r-md { border-right: 1px solid rgba(128,128,128,0.2); }
@media (max-width: 960px) { .border-r-md { border-right: none; } }
.solid-chip { display: inline-flex; align-items: center; justify-content: center; height: 28px; padding: 0 12px; font-weight: 900; text-transform: uppercase; }
</style>
