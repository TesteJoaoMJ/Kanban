<template>
  <div
    class="proofs-layout font-sans fill-height d-flex flex-column relative overflow-hidden"
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
        class="header-bar px-6 py-4 d-flex align-center justify-space-between flex-shrink-0"
        :class="themeStore.currentMode === 'light' ? 'bg-white border-b border-grey-lighten-2 shadow-sm' : 'bg-glass-header border-bottom-white-05'"
      >
        <div class="d-flex flex-column">
          <div class="breadcrumb text-caption">
            <span class="opacity-70">Administrativo</span>
            <span class="mx-2 opacity-50">></span>
            <span class="font-weight-bold">Central de Comprovantes</span>
          </div>
          <div class="text-h6 font-weight-black tracking-tight leading-none mt-1" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">
            Comprovantes e Anexos ({{ filteredProofs.length }})
          </div>
        </div>

        <div class="d-flex align-center" style="gap: 10px;">
          <v-menu location="bottom end" :close-on-content-click="false">
            <template v-slot:activator="{ props }">
              <v-btn
                v-bind="props"
                variant="outlined"
                class="btn-rect"
                height="40"
                prepend-icon="mdi-filter-variant"
                :color="themeStore.currentMode === 'light' ? 'grey-darken-2' : 'white'"
              >
                Filtros
                <v-badge v-if="activeFilterCount > 0" :content="activeFilterCount" color="error" floating dot class="ml-2"></v-badge>
              </v-btn>
            </template>
            <v-card min-width="280" class="rounded-0">
                <v-list density="compact">
                    <v-list-subheader class="font-weight-bold text-uppercase text-caption">Formato</v-list-subheader>
                    <v-list-item @click="setFormatFilter('all')" :active="filters.format === 'all'" color="primary">
                        <template v-slot:prepend><v-icon>mdi-file-outline</v-icon></template>
                        <v-list-item-title>Todos</v-list-item-title>
                    </v-list-item>
                    <v-list-item @click="setFormatFilter('img')" :active="filters.format === 'img'" color="primary">
                        <template v-slot:prepend><v-icon>mdi-image-outline</v-icon></template>
                        <v-list-item-title>Imagens</v-list-item-title>
                    </v-list-item>
                    <v-list-item @click="setFormatFilter('pdf')" :active="filters.format === 'pdf'" color="primary">
                        <template v-slot:prepend><v-icon>mdi-file-pdf-box</v-icon></template>
                        <v-list-item-title>PDF</v-list-item-title>
                    </v-list-item>

                    <v-divider class="my-2"></v-divider>
                    <v-list-subheader class="font-weight-bold text-uppercase text-caption">Ordenar Valor</v-list-subheader>
                    <v-list-item @click="setValueSort('desc')" :active="filters.sort === 'desc'" color="primary">
                        <template v-slot:prepend><v-icon>mdi-sort-numeric-descending</v-icon></template>
                        <v-list-item-title>Maior para Menor</v-list-item-title>
                    </v-list-item>
                    <v-list-item @click="setValueSort('asc')" :active="filters.sort === 'asc'" color="primary">
                        <template v-slot:prepend><v-icon>mdi-sort-numeric-ascending</v-icon></template>
                        <v-list-item-title>Menor para Maior</v-list-item-title>
                    </v-list-item>
                </v-list>
            </v-card>
          </v-menu>

          <v-tooltip text="Exportar Lista (CSV)" location="bottom" content-class="bg-grey-darken-3 text-white font-weight-bold">
            <template v-slot:activator="{ props }">
              <v-btn
                v-bind="props"
                color="success"
                variant="flat"
                class="btn-rect font-weight-bold"
                height="40"
                prepend-icon="mdi-microsoft-excel"
                @click="exportList"
              >
                Exportar
              </v-btn>
            </template>
          </v-tooltip>

          <v-tooltip text="Atualizar Lista" location="bottom" content-class="bg-grey-darken-3 text-white font-weight-bold">
            <template v-slot:activator="{ props }">
              <v-btn
                v-bind="props"
                icon
                variant="text"
                :color="themeStore.currentMode === 'light' ? 'grey-darken-2' : 'white'"
                @click="fetchAllProofs"
                :loading="loading"
              >
                <v-icon>mdi-refresh</v-icon>
              </v-btn>
            </template>
          </v-tooltip>
        </div>
      </div>

      <div class="px-6 pt-4 pb-2 flex-shrink-0">
        <div
          class="controls-bar d-flex flex-column"
          :class="themeStore.currentMode === 'light' ? 'controls-light' : 'controls-dark'"
          style="gap: 10px;"
        >
          <div class="d-flex align-center justify-space-between flex-wrap" style="gap: 10px;">
            <div class="d-flex align-center flex-wrap" style="gap: 10px;">
              <v-menu location="bottom start" :close-on-content-click="true">
                <template v-slot:activator="{ props }">
                  <v-btn v-bind="props" variant="outlined" class="btn-rect" height="40" prepend-icon="mdi-calendar-range" color="primary">
                    {{ quickPeriodLabel }}
                    <v-icon end size="small">mdi-chevron-down</v-icon>
                  </v-btn>
                </template>
                <v-card class="rounded-0" min-width="220">
                  <v-list density="compact" nav>
                    <v-list-item v-for="p in quickPeriodOptions" :key="p.value" @click="setQuickPeriod(p.value)">
                      <v-list-item-title class="text-body-2">{{ p.label }}</v-list-item-title>
                    </v-list-item>
                  </v-list>
                </v-card>
              </v-menu>

              <div class="period-nav d-flex align-center" :class="themeStore.currentMode === 'light' ? 'period-nav-light' : 'period-nav-dark'">
                <v-tooltip text="Período Anterior" location="top" content-class="bg-grey-darken-3 text-white font-weight-bold">
                  <template v-slot:activator="{ props }">
                    <v-btn v-bind="props" icon variant="text" class="icon-rect" height="40" width="40" @click="navigatePeriod(-1)">
                      <v-icon>mdi-chevron-left</v-icon>
                    </v-btn>
                  </template>
                </v-tooltip>
                <div class="period-label text-caption font-weight-black text-center px-3">
                  {{ currentPeriodDisplay }}
                </div>
                <v-tooltip text="Próximo Período" location="top" content-class="bg-grey-darken-3 text-white font-weight-bold">
                  <template v-slot:activator="{ props }">
                    <v-btn v-bind="props" icon variant="text" class="icon-rect" height="40" width="40" @click="navigatePeriod(1)">
                      <v-icon>mdi-chevron-right</v-icon>
                    </v-btn>
                  </template>
                </v-tooltip>
              </div>
            </div>

            <div class="d-flex align-center flex-wrap justify-end" style="gap: 10px;">
              <div class="search-wrap d-flex align-center" :class="themeStore.currentMode === 'light' ? 'search-light' : 'search-dark'">
                <v-icon :color="themeStore.currentMode === 'light' ? 'grey-darken-1' : 'white-70'">mdi-magnify</v-icon>
                <input
                  v-model="filters.search"
                  type="text"
                  placeholder="Buscar cliente, pedido, descrição..."
                  class="clean-input flex-grow-1"
                  @keyup.enter="fetchAllProofs"
                />
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="flex-grow-1 px-6 pb-2 overflow-hidden d-flex flex-column">
        <v-card
          class="flex-grow-1 d-flex flex-column rounded-0 border-thin overflow-hidden"
          :class="themeStore.currentMode === 'light' ? 'bg-white shadow-sm' : 'glass-card border-white-05'"
          :elevation="0"
        >
          <div class="grid-scroll flex-grow-1 overflow-y-auto custom-scroll">
            <div
              class="grid-header sticky-head"
              :class="themeStore.currentMode === 'light' ? 'grid-surface-light' : 'grid-surface-dark'"
            >
              <div class="cell center header-text" style="width: 50px;">#</div>
              <div class="cell header-text" style="width: 120px;">Data Envio</div>
              <div class="cell center header-text" style="width: 100px;">Pedido</div>
              <div class="cell header-text flex-grow-1" style="min-width: 200px;">Cliente / Fonte</div>
              <div class="cell header-text" style="width: 220px;">Descrição do Anexo</div>
              <div class="cell right header-text" style="width: 130px;">Valor (R$)</div>
              <div class="cell center header-text" style="width: 90px;">Formato</div>
              <div class="cell center header-text" style="width: 140px;">Ações</div>
            </div>

            <div v-if="loading" class="d-flex flex-column justify-center align-center h-100 py-16">
              <v-progress-circular indeterminate color="primary" size="48" width="4"></v-progress-circular>
              <span class="text-caption mt-4 font-weight-bold opacity-70">Buscando em múltiplas fontes...</span>
            </div>

            <div v-else-if="paginatedProofs.length === 0" class="d-flex flex-column justify-center align-center h-100 opacity-60 gap-3 py-16">
              <v-icon size="64" color="grey-lighten-1">mdi-file-search-outline</v-icon>
              <span class="text-h6 font-weight-medium text-grey">Nenhum comprovante encontrado.</span>
              <span class="text-caption">Tente alterar o período ou os filtros de busca.</span>
            </div>

            <div
              v-else
              v-for="(item, index) in paginatedProofs"
              :key="item.uniqueId"
              class="grid-row"
              :class="[
                themeStore.currentMode === 'light' ? 'grid-row-light' : 'grid-row-dark',
                zebraClass(index)
              ]"
            >
              <div class="cell center" style="width: 50px;">
                <v-tooltip :text="getSourceLabel(item.origin)" location="right" content-class="bg-grey-darken-3 text-white font-weight-bold">
                  <template v-slot:activator="{ props }">
                    <v-icon v-bind="props" size="20" :color="getSourceColor(item.origin)">
                      {{ getSourceIcon(item.origin) }}
                    </v-icon>
                  </template>
                </v-tooltip>
              </div>

              <div class="cell" style="width: 120px;">
                <div class="d-flex flex-column">
                    <span class="list-text-10 font-mono font-weight-bold">{{ formatDate(item.date) }}</span>
                    <span class="text-[10px] opacity-60">{{ formatTime(item.date) }}</span>
                </div>
              </div>

              <div class="cell center" style="width: 100px;">
                <span class="pill-ref">{{ String(item.order_number).padStart(4, '0') }}</span>
              </div>

              <div class="cell flex-grow-1" style="min-width: 200px;">
                <div class="d-flex flex-column overflow-hidden">
                  <div class="text-truncate list-text-11 font-weight-bold" :title="item.customer_name">
                    {{ item.customer_name }}
                  </div>
                  <div class="d-flex align-center mt-0.5">
                    <span class="text-[10px] opacity-70 border rounded px-1 mr-2">{{ getSourceLabel(item.origin) }}</span>
                    <span class="text-truncate text-[10px] opacity-60">Por: {{ item.creator_name }}</span>
                  </div>
                </div>
              </div>

              <div class="cell" style="width: 220px;">
                <span class="text-truncate list-text-10 opacity-80" :title="item.description">
                  {{ item.description }}
                </span>
              </div>

              <div class="cell right" style="width: 130px;">
                 <span class="list-text-10 font-mono font-weight-black" :class="item.value > 0 ? 'text-success' : 'opacity-50'">
                    {{ formatCurrency(item.value) }}
                 </span>
              </div>

              <div class="cell center" style="width: 90px;">
                <v-chip size="x-small" :color="getFileInfo(item.url).color" variant="tonal" class="font-weight-bold text-uppercase" label>
                  {{ getFileInfo(item.url).ext }}
                </v-chip>
              </div>

              <div class="cell center" style="width: 140px;">
                <div class="actions-inline">
                  <v-tooltip text="Visualizar" location="top" content-class="bg-grey-darken-3 text-white font-weight-bold">
                    <template v-slot:activator="{ props }">
                      <v-btn
                        v-bind="props"
                        icon
                        size="small"
                        class="action-btn action-view"
                        variant="flat"
                        @click="openImageModal(item)"
                      >
                        <v-icon size="18">mdi-eye</v-icon>
                      </v-btn>
                    </template>
                  </v-tooltip>

                  <v-tooltip text="Baixar" location="top" content-class="bg-grey-darken-3 text-white font-weight-bold">
                    <template v-slot:activator="{ props }">
                      <v-btn
                        v-bind="props"
                        icon
                        size="small"
                        class="action-btn action-download"
                        variant="flat"
                        @click="downloadFile(item.url)"
                      >
                        <v-icon size="18">mdi-download</v-icon>
                      </v-btn>
                    </template>
                  </v-tooltip>

                  <v-tooltip text="Ver Pedido" location="top" content-class="bg-grey-darken-3 text-white font-weight-bold">
                    <template v-slot:activator="{ props }">
                      <v-btn
                        v-bind="props"
                        icon
                        size="small"
                        class="action-btn action-info"
                        variant="flat"
                        @click="showOrderDetails(item.order_id)"
                      >
                        <v-icon size="18">mdi-information-variant</v-icon>
                      </v-btn>
                    </template>
                  </v-tooltip>
                </div>
              </div>
            </div>
          </div>

          <div class="flex-shrink-0 border-t px-4 py-2 d-flex align-center justify-space-between" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5' : 'bg-white-05'">
            <div class="text-caption opacity-80">
              Total: <strong>{{ filteredProofs.length }}</strong> registros encontrados
            </div>
            <v-pagination
                v-model="page"
                :length="pageCount"
                :total-visible="6"
                density="compact"
                active-color="primary"
                variant="tonal"
                size="small"
            ></v-pagination>
          </div>
        </v-card>
      </div>
    </div>

    <ImageModal
      :show="showImagePreviewModal"
      :image-url="selectedImageUrl"
      :file-name="selectedImageName"
      @close="showImagePreviewModal = false"
    />

    <OrderDetailModal
      :show="showDetailsModal"
      :order-id="selectedOrderId"
      @close="showDetailsModal = false"
    />
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, reactive, watch } from 'vue';
import { supabase } from '@/api/supabase';
import { format, parseISO, startOfMonth, endOfMonth, startOfWeek, endOfWeek, addMonths, addDays } from 'date-fns';
import { ptBR } from 'date-fns/locale';
import { useThemeStore } from '@/stores/themeStore';
import ImageModal from '@/components/ImageModal.vue';
import OrderDetailModal from '@/components/OrderDetailModal.vue';

const bgClass = computed(() => isLightMode.value ? 'bg-grey-lighten-5' : 'bg-grey-darken-4');
const cardClass = computed(() => isLightMode.value ? 'bg-white border-grey-lighten-2' : 'bg-surface-variant border-white-10');
const textPrimary = computed(() => isLightMode.value ? 'text-grey-darken-4' : 'text-white');
const textSecondary = computed(() => isLightMode.value ? 'text-grey-darken-1' : 'text-white-70');

const themeStore = useThemeStore();

type ProofItem = {
  uniqueId: string;
  id: string;
  order_id: string;
  order_number: string | number;
  customer_name: string;
  creator_name: string;
  date: string;
  url: string;
  description: string;
  origin: 'orders' | 'receivables' | 'legacy_payments';
  value: number;
};

const loading = ref(false);
const allProofs = ref<ProofItem[]>([]);
const page = ref(1);
const itemsPerPage = 30;

const filters = reactive({
    search: '',
    format: 'all',
    sort: 'desc'
});

const showImagePreviewModal = ref(false);
const selectedImageUrl = ref('');
const selectedImageName = ref('');
const showDetailsModal = ref(false);
const selectedOrderId = ref<string | null>(null);

const quickPeriod = ref<'today' | 'week' | 'month' | 'all'>('month');
const currentDateRef = ref(new Date());

const quickPeriodOptions = [
  { label: 'Hoje', value: 'today' },
  { label: 'Essa semana', value: 'week' },
  { label: 'Esse mês', value: 'month' },
  { label: 'Todo o período', value: 'all' }
];

const quickPeriodLabel = computed(() => quickPeriodOptions.find(o => o.value === quickPeriod.value)?.label || 'Período');

const currentPeriodDisplay = computed(() => {
  if (quickPeriod.value === 'today') return format(currentDateRef.value, 'dd/MM/yyyy');
  if (quickPeriod.value === 'week') {
    const start = startOfWeek(currentDateRef.value);
    const end = endOfWeek(currentDateRef.value);
    return `${format(start, 'dd/MM', { locale: ptBR })} - ${format(end, 'dd/MM', { locale: ptBR })}`;
  }
  if (quickPeriod.value === 'month') return format(currentDateRef.value, 'MMM yyyy', { locale: ptBR });
  return 'Geral';
});

const setQuickPeriod = (val: 'today' | 'week' | 'month' | 'all') => {
  quickPeriod.value = val;
  currentDateRef.value = new Date();
  fetchAllProofs();
};

const navigatePeriod = (dir: number) => {
  if (quickPeriod.value === 'all') return;
  if (quickPeriod.value === 'month') currentDateRef.value = addMonths(currentDateRef.value, dir);
  else if (quickPeriod.value === 'today') currentDateRef.value = addDays(currentDateRef.value, dir);
  else if (quickPeriod.value === 'week') currentDateRef.value = addDays(currentDateRef.value, dir * 7);
  fetchAllProofs();
};

const setFormatFilter = (fmt: string) => { filters.format = fmt; page.value = 1; };
const setValueSort = (sort: string) => { filters.sort = sort; page.value = 1; };

const fetchAllProofs = async () => {
  loading.value = true;
  allProofs.value = [];
  page.value = 1;

  try {
    let startStr = '2000-01-01';
    let endStr = '2099-12-31';

    if (quickPeriod.value !== 'all') {
      let s: Date, e: Date;
      const d = currentDateRef.value;
      if (quickPeriod.value === 'today') { s = d; e = d; }
      else if (quickPeriod.value === 'week') { s = startOfWeek(d); e = endOfWeek(d); }
      else { s = startOfMonth(d); e = endOfMonth(d); }
      startStr = format(s, 'yyyy-MM-dd');
      endStr = format(e, 'yyyy-MM-dd');
    }

    const startIso = `${startStr}T00:00:00`;
    const endIso = `${endStr}T23:59:59`;

    console.group('--- DEBUG FETCH PROOFS ---');
    console.log('Period:', startIso, 'to', endIso);

    // 1. ORDERS: Comprovante de Entrada/Sinal
    const p1 = supabase
      .from('orders')
      .select('id, order_number, customer_name, created_at, down_payment_proof_url, details, creator:orders_created_by_fkey(full_name)')
      .neq('down_payment_proof_url', null)
      .gte('created_at', startIso)
      .lte('created_at', endIso)
      .order('created_at', { ascending: false });

    // 2. ORDER_PAYMENTS: Pagamentos com comprovante (Legado)
    // Usa explicitamente a constraint para evitar ambiguidade
    const p2 = supabase
      .from('order_payments')
      .select(`
        id, order_id, amount, payment_date, receipt_url, payment_type, created_at, notes,
        orders:orders!order_payments_order_id_fkey(order_number, customer_name),
        creator:profiles!order_payments_created_by_fkey(full_name)
      `)
      .neq('receipt_url', null)
      .gte('payment_date', startIso)
      .lte('payment_date', endIso);

    // 3. FINANCE_RECEIVABLES: Parcelas com anexo
    // Otimização: Filtra quem tem snapshot != null e diferente de array vazio "[]"
    const p3 = supabase
      .from('finance_receivables')
      .select(`
        id, description, value, due_date, payment_date, created_at, billing_items_snapshot,
        orders:finance_receivables_order_id_fkey(order_number, customer_name, creator:orders_created_by_fkey(full_name))
      `)
      .gte('created_at', startIso)
      .lte('created_at', endIso)
      .not('billing_items_snapshot', 'is', null)
      .neq('billing_items_snapshot', '[]'); // Filtra arrays vazios direto no banco

    const [resOrders, resLegacy, resFinance] = await Promise.all([p1, p2, p3]);

    console.log('Orders Result:', resOrders.data?.length);
    console.log('Legacy Payments Result:', resLegacy.data?.length);
    console.log('Finance Receivables Result:', resFinance.data?.length);

    const merged: ProofItem[] = [];

    // --- PROCESSAR ORDERS ---
    (resOrders.data || []).forEach((o: any) => {
      merged.push({
        uniqueId: `ord-${o.id}`,
        id: o.id,
        order_id: o.id,
        order_number: o.order_number,
        customer_name: o.customer_name || 'Consumidor',
        creator_name: o.creator?.full_name || 'Sistema',
        date: o.created_at,
        url: o.down_payment_proof_url,
        description: 'Comprovante de Sinal (Antigo)',
        origin: 'orders',
        value: Number(o.details?.entry_value || 0)
      });
    });

    // --- PROCESSAR LEGACY (order_payments) ---
    (resLegacy.data || []).forEach((p: any) => {
        const order = p.orders || {};
        const creator = p.creator || {};
        merged.push({
            uniqueId: `leg-${p.id}`,
            id: p.id,
            order_id: p.order_id,
            order_number: order.order_number || '---',
            customer_name: order.customer_name || 'Desconhecido',
            creator_name: creator.full_name || 'Sistema',
            date: p.payment_date || p.created_at,
            url: p.receipt_url,
            description: `${p.payment_type || 'Pagamento'} (${p.notes || ''})`,
            origin: 'legacy_payments',
            value: Number(p.amount || 0)
        });
    });

    // --- PROCESSAR FINANCE (Novo) ---
    (resFinance.data || []).forEach((r: any) => {
        const order = r.orders || {};
        const orderNum = order.order_number || '-';
        const custName = order.customer_name || 'Desconhecido';
        const creator = order.creator?.full_name || 'Sistema';
        const date = r.payment_date ? `${r.payment_date}T12:00:00` : r.created_at;

        let attachments: any[] = [];
        try {
            attachments = typeof r.billing_items_snapshot === 'string' ? JSON.parse(r.billing_items_snapshot) : r.billing_items_snapshot;
        } catch {
            console.warn('Falha ao parsear snapshot do ID:', r.id);
        }

        if (Array.isArray(attachments)) {
            attachments.forEach((att, idx) => {
                // Tenta encontrar URL em propriedades comuns
                const finalUrl = att.url || att.link || att.src || (typeof att === 'string' && att.includes('http') ? att : null);

                if (finalUrl) {
                    merged.push({
                        uniqueId: `fin-snap-${r.id}-${idx}`,
                        id: r.id,
                        order_id: r.order_id || r.id,
                        order_number: orderNum,
                        customer_name: custName,
                        creator_name: creator,
                        date: date,
                        url: finalUrl,
                        description: `${r.description} (${att.filename || 'Anexo'})`,
                        origin: 'receivables',
                        value: Number(r.value)
                    });
                } else {
                    // DEBUG: Se chegou aqui, o objeto existe mas não tem URL reconhecida
                    console.warn('Item ignorado (sem URL) no ID:', r.id, 'Keys:', Object.keys(att));
                }
            });
        }
    });

    console.log('Total Merged Proofs:', merged.length);
    console.groupEnd();

    allProofs.value = merged;

  } catch (err) {
    console.error('Erro CRÍTICO ao buscar comprovantes:', err);
  } finally {
    loading.value = false;
  }
};

const filteredProofs = computed(() => {
  let list = allProofs.value;

  if (filters.search) {
    const s = filters.search.toLowerCase();
    list = list.filter(p =>
      String(p.order_number).includes(s) ||
      p.customer_name.toLowerCase().includes(s) ||
      p.description.toLowerCase().includes(s)
    );
  }

  if (filters.format !== 'all') {
      list = list.filter(p => {
          const ext = p.url.split('.').pop()?.toLowerCase() || '';
          const isImg = ['jpg','jpeg','png','webp'].includes(ext);
          const isPdf = ext === 'pdf';
          return filters.format === 'img' ? isImg : isPdf;
      });
  }

  list.sort((a, b) => {
      if (filters.sort === 'desc') return b.value - a.value;
      return a.value - b.value;
  });

  return list;
});

const paginatedProofs = computed(() => {
  const start = (page.value - 1) * itemsPerPage;
  return filteredProofs.value.slice(start, start + itemsPerPage);
});

const pageCount = computed(() => Math.ceil(filteredProofs.value.length / itemsPerPage));
const activeFilterCount = computed(() => (filters.format !== 'all' ? 1 : 0) + (filters.search ? 1 : 0));

const formatDate = (d: string) => d ? format(parseISO(d), 'dd/MM/yy') : '-';
const formatTime = (d: string) => d ? format(parseISO(d), 'HH:mm') : '';
const formatCurrency = (val: number) => new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(val);

const getFileInfo = (url: string) => {
  if (!url) return { ext: '?', color: 'grey' };
  const ext = url.split('.').pop()?.toLowerCase().split('?')[0] || '?';
  if (['jpg', 'jpeg', 'png', 'webp'].includes(ext)) return { ext: 'IMG', color: 'purple' };
  if (['pdf'].includes(ext)) return { ext: 'PDF', color: 'error' };
  return { ext: ext.toUpperCase().substring(0, 4), color: 'info' };
};

const getSourceLabel = (origin: string) => {
    if (origin === 'orders') return 'Sinal (Pedido)';
    if (origin === 'legacy_payments') return 'Pagamento (Legado)';
    return 'Financeiro (Novo)';
};

const getSourceIcon = (origin: string) => {
    if (origin === 'orders') return 'mdi-flag-checkered';
    if (origin === 'legacy_payments') return 'mdi-history';
    return 'mdi-cash-check';
};

const getSourceColor = (origin: string) => {
    if (origin === 'orders') return 'primary';
    if (origin === 'legacy_payments') return 'warning';
    return 'success';
};

const zebraClass = (index: number) => {
  if (themeStore.currentMode !== 'light') return index % 2 === 0 ? 'zebra-dark-a' : 'zebra-dark-b';
  return index % 2 === 0 ? 'zebra-light-a' : 'zebra-light-b';
};

const openImageModal = (item: ProofItem) => {
  selectedImageUrl.value = item.url;
  selectedImageName.value = `${item.description} - Pedido ${item.order_number}`;
  showImagePreviewModal.value = true;
};

const showOrderDetails = (orderId: string) => {
  if (!orderId) return;
  selectedOrderId.value = orderId;
  showDetailsModal.value = true;
};

const downloadFile = (url: string) => window.open(url, '_blank');

const exportList = () => {
    let csv = 'Data,Hora,Pedido,Cliente,Descricao,Valor,Link\n';
    filteredProofs.value.forEach(row => {
        csv += `${formatDate(row.date)},${formatTime(row.date)},${row.order_number},"${row.customer_name}","${row.description}",${row.value.toFixed(2)},${row.url}\n`;
    });

    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
    const link = document.createElement('a');
    link.href = URL.createObjectURL(blob);
    link.setAttribute('download', `comprovantes_export_${format(new Date(), 'ddMMyy')}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
};

onMounted(fetchAllProofs);

watch(allProofs, (newVal) => {
    newVal.sort((a,b) => new Date(b.date).getTime() - new Date(a.date).getTime());
});
</script>

<style scoped lang="scss">
/* Layout Styles */
.proofs-layout { position: relative; }
.background-carousel-wrapper { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 0; opacity: 0.6; pointer-events: none; }
.background-overlay { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 1; background: radial-gradient(circle at center, rgba(15, 15, 19, 0.4), rgba(15, 15, 19, 0.98)); backdrop-filter: blur(8px); }
.z-10 { position: relative; z-index: 10; }

.bg-glass-dark { background: rgba(10,10,12,0.85); }
.bg-glass-header { background: rgba(20,20,24,0.55); backdrop-filter: blur(14px); }
.border-bottom-white-05 { border-bottom: 1px solid rgba(255,255,255,0.08); }
.border-thin { border: 1px solid rgba(0,0,0,0.08); }
.bg-white-05 { background: rgba(255,255,255,0.05); }

.btn-rect { border-radius: 0 !important; text-transform: none !important; font-weight: 800; }
.icon-rect { border-radius: 0 !important; }
.clean-input { border: none; outline: none; background: transparent; font-size: 13px; color: inherit; }

.controls-bar { border: 1px solid rgba(0,0,0,0.08); border-radius: 0; padding: 10px; }
.controls-light { background: #ffffff; }
.controls-dark { background: rgba(30,30,35,0.55); backdrop-filter: blur(16px); border: 1px solid rgba(255,255,255,0.08); }

.period-nav { border-radius: 0; height: 40px; overflow: hidden; }
.period-nav-light { border: 1px solid rgba(0,0,0,0.12); background: #fafafa; }
.period-nav-dark { border: 1px solid rgba(255,255,255,0.10); background: rgba(255,255,255,0.06); }
.period-label { min-width: 190px; display: flex; align-items: center; justify-content: center; height: 40px; }

.search-wrap { height: 40px; border-radius: 0; padding: 0 12px; min-width: 360px; max-width: 520px; flex: 1 1 360px; }
.search-light { background: #f4f6f8; border: 1px solid rgba(0,0,0,0.08); }
.search-dark { background: rgba(255,255,255,0.08); border: 1px solid rgba(255,255,255,0.10); }

.glass-card { background: rgba(30, 30, 35, 0.45); backdrop-filter: blur(25px); border: 1px solid rgba(255,255,255,0.08); }
.grid-scroll { scrollbar-gutter: stable both-edges; }
.custom-scroll::-webkit-scrollbar { width: 8px; height: 8px; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.35); border-radius: 6px; }
.custom-scroll::-webkit-scrollbar-track { background: transparent; }

.grid-header, .grid-row { display: flex; align-items: stretch; width: 100%; border-bottom: 1px solid rgba(0,0,0,0.08); }
.cell { padding: 8px 12px; display: flex; align-items: center; border-right: 1px solid rgba(0,0,0,0.08); min-height: 50px; overflow: hidden; }
.center { justify-content: center; text-align: center; }
.right { justify-content: flex-end; text-align: right; }

.grid-header .cell { min-height: 44px; font-size: 12px; font-weight: 900; text-transform: uppercase; letter-spacing: .6px; }
.header-text { font-size: 12px; }

.grid-surface-light .cell { background: #f5f7fa; color: rgba(0,0,0,0.7); border-color: rgba(0,0,0,0.10); }
.grid-surface-dark .cell { background: rgba(255,255,255,0.08); color: rgba(255,255,255,0.80); border-color: rgba(255,255,255,0.10); }

.grid-row-light .cell { background: #fff; border-color: rgba(0,0,0,0.08); }
.grid-row-light:hover .cell { background: #f7fafc !important; }

.grid-row-dark .cell { background: rgba(255,255,255,0.04); border-color: rgba(255,255,255,0.08); }
.grid-row-dark:hover .cell { background: rgba(255,255,255,0.07) !important; }

.zebra-light-a .cell { background: #ffffff; }
.zebra-light-b .cell { background: #fafafa; }
.zebra-dark-a .cell { background: rgba(255,255,255,0.03); }
.zebra-dark-b .cell { background: rgba(255,255,255,0.06); }

.sticky-head { position: sticky; top: 0; z-index: 10; }

.pill-ref { font-size: 11px; font-weight: 900; font-family: monospace; background: rgba(0,0,0,0.06); padding: 4px 8px; border-radius: 6px; }
.list-text-11 { font-size: 13px !important; line-height: 1.25 !important; }
.list-text-10 { font-size: 12px !important; line-height: 1.25 !important; }

.actions-inline { display: flex; align-items: center; justify-content: center; gap: 8px; }
.action-btn { width: 28px !important; height: 28px !important; border-radius: 6px !important; color: #fff !important; }
.action-btn :deep(.v-icon) { color: #fff !important; }

.action-view { background: #7b1fa2 !important; }
.action-download { background: #0288d1 !important; }
.action-info { background: #455a64 !important; }
</style>
