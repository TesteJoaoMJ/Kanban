<template>
  <v-dialog
    :model-value="show"
    @update:model-value="$emit('close')"
    max-width="1300px"
    persistent
    scrollable
    transition="dialog-bottom-transition"
    class="release-modal"
  >
    <v-card :class="['release-modal-card', { 'light-mode': isLightMode }]">
      <div
        class="modal-header px-6 py-4 d-flex align-center justify-space-between flex-shrink-0"
        :class="isLightMode ? 'bg-white border-b' : 'bg-header-dark'"
      >
        <div class="d-flex align-center gap-4">
          <div
            class="icon-box-lg rounded-xl elevation-3 d-flex align-center justify-center"
            :class="isLightMode ? 'bg-primary text-white' : 'bg-primary-gradient'"
          >
            <v-icon :color="isLightMode ? 'white' : 'white'" size="28">mdi-package-variant-closed</v-icon>
          </div>
          <div>
            <h2
              class="text-h6 font-weight-bold lh-1 mb-1"
              :class="isLightMode ? 'text-grey-darken-3' : 'text-white'"
            >
              Liberação de Produção
            </h2>
            <div class="d-flex align-center gap-2 text-caption text-medium-emphasis">
              <v-icon size="12" :color="isLightMode ? 'grey-darken-1' : 'white-50'">mdi-identifier</v-icon>
              <span>Pedido #{{ order?.order_number || '---' }}</span>
            </div>
          </div>
        </div>

        <div class="d-flex align-center gap-2">
          <v-tooltip text="Gerar Resumo (PDF)" location="bottom" content-class="tooltip-contrast">
            <template v-slot:activator="{ props }">
              <v-btn
                v-bind="props"
                icon
                variant="text"
                :color="isLightMode ? 'grey-darken-2' : 'white-70'"
                @click="generateOrderSummaryPdf"
                :loading="isGeneratingPdf"
                :disabled="loadingItems"
              >
                <v-icon>mdi-file-pdf-box</v-icon>
              </v-btn>
            </template>
          </v-tooltip>
          <v-btn
            icon
            variant="text"
            :color="isLightMode ? 'grey-darken-2' : 'white-50'"
            @click="$emit('close')"
          >
            <v-icon>mdi-close</v-icon>
          </v-btn>
        </div>
      </div>

      <v-card-text class="pa-0 d-flex flex-column flex-md-row overflow-hidden" style="height: 75vh;">

        <div
          class="sidebar-panel d-flex flex-column pa-5 flex-shrink-0"
          :class="isLightMode ? 'bg-grey-lighten-4 border-r' : 'bg-surface-light'"
        >
          <div class="mb-6">
            <div class="d-flex justify-space-between align-center mb-2">
              <span class="text-caption font-weight-bold text-uppercase opacity-70">Progresso da Liberação</span>
              <span class="text-caption font-weight-bold">{{ releasedCount }}/{{ localItems.length }}</span>
            </div>
            <v-progress-linear
              :model-value="releaseProgress"
              color="success"
              height="8"
              rounded
              striped
            ></v-progress-linear>
          </div>

          <div class="d-flex flex-column gap-4">

            <div class="metadata-item d-flex align-center gap-3">
              <v-avatar :color="isLightMode ? 'white' : 'rgba(255,255,255,0.05)'" rounded="lg" size="40" :class="{ 'border-solid': isLightMode }">
                <v-icon color="primary" size="20">mdi-account</v-icon>
              </v-avatar>
              <div>
                <div class="text-[10px] text-uppercase font-weight-bold opacity-60">Cliente</div>
                <div class="text-body-2 font-weight-bold truncate-text" :class="isLightMode ? 'text-grey-darken-3' : 'text-white'">
                  {{ order?.customer_name || '...' }}
                </div>
              </div>
            </div>

            <v-divider :class="isLightMode ? 'border-grey-lighten-2' : 'border-white-05'"></v-divider>

            <div class="metadata-item d-flex align-center gap-3">
              <v-avatar :color="isLightMode ? 'white' : 'rgba(255,255,255,0.05)'" rounded="lg" size="40" :class="{ 'border-solid': isLightMode }">
                <v-icon color="info" size="20">mdi-badge-account-horizontal</v-icon>
              </v-avatar>
              <div>
                <div class="text-[10px] text-uppercase font-weight-bold opacity-60">Vendedor</div>
                <div class="text-body-2 font-weight-bold truncate-text" :class="isLightMode ? 'text-grey-darken-3' : 'text-white'">
                  {{ order?.creator_name || '...' }}
                </div>
              </div>
            </div>

            <v-divider :class="isLightMode ? 'border-grey-lighten-2' : 'border-white-05'"></v-divider>

            <div class="metadata-item d-flex align-center gap-3">
              <v-avatar :color="isLightMode ? 'white' : 'rgba(255,255,255,0.05)'" rounded="lg" size="40" :class="{ 'border-solid': isLightMode }">
                <v-icon color="success" size="20">mdi-calendar-check</v-icon>
              </v-avatar>
              <div>
                <div class="text-[10px] text-uppercase font-weight-bold opacity-60">Data de Emissão</div>
                <div class="text-body-2 font-weight-bold" :class="isLightMode ? 'text-grey-darken-3' : 'text-white'">
                  {{ formatDate(order?.created_at) }}
                </div>
              </div>
            </div>

          </div>

          <v-spacer></v-spacer>

          <div class="info-box pa-3 rounded-lg text-caption text-center opacity-70 mt-4"
               :class="isLightMode ? 'bg-blue-lighten-5 text-blue-darken-3' : 'bg-white-05 text-white'">
             <v-icon size="16" class="mb-1">mdi-information-outline</v-icon>
             <div class="lh-1">Revise os itens antes de liberar. A ação gera OP e atualiza o estoque.</div>
          </div>
        </div>

        <div class="main-content flex-grow-1 d-flex flex-column bg-surface-base" :class="isLightMode ? 'bg-white' : 'bg-surface-dark'">

          <div class="flex-grow-1 overflow-y-auto custom-scrollbar pa-6">

            <div v-if="loadingItems" class="d-flex flex-column align-center justify-center py-12 h-100">
              <v-progress-circular indeterminate color="primary" size="48" width="4"></v-progress-circular>
              <span class="mt-4 text-caption text-medium-emphasis">Carregando Itens...</span>
            </div>

            <div v-else class="item-list-container d-flex flex-column gap-3">
               <template v-for="item in paginatedItems" :key="item.id">
                 <div
                    class="item-card rounded-lg overflow-hidden d-flex flex-column flex-sm-row position-relative"
                    :class="[
                       isLightMode ? 'border border-grey-lighten-2 bg-white elevation-0' : 'border border-white-05 bg-surface-card',
                       { 'delayed-item': isItemDelayed(item) }
                    ]"
                  >
                    <div v-if="isItemDelayed(item)" class="delayed-indicator d-flex flex-column align-center justify-center bg-red-lighten-5 px-2 border-r border-red-lighten-4" style="min-width: 60px;">
                        <v-icon color="error" size="24" class="fade-animation mb-1">mdi-alarm-light</v-icon>
                        <span class="text-[10px] font-weight-black text-error text-uppercase text-center lh-1">
                            Atenção<br>
                            {{ getDaysWaiting(item) }} Dias
                        </span>
                    </div>

                    <div class="thumbnail-area position-relative cursor-pointer flex-shrink-0" @click="openImageZoom(item)">
                        <v-img
                            :src="getThumbnailUrl(item.stamp_image_url)"
                            lazy-src="/placeholder.png"
                            class="bg-grey-darken-4"
                            aspect-ratio="1"
                            cover
                            width="140"
                            height="100%"
                        >
                            <template v-slot:placeholder>
                                <div class="d-flex align-center justify-center fill-height bg-grey-darken-4">
                                    <v-icon color="grey-darken-2">mdi-image</v-icon>
                                </div>
                            </template>
                            <div class="overlay-zoom d-flex align-center justify-center">
                                <v-icon color="white" size="24">mdi-magnify-plus-outline</v-icon>
                            </div>
                        </v-img>
                    </div>

                    <div class="pa-4 flex-grow-1 d-flex flex-column justify-space-between min-w-0">
                        <div>
                            <div class="d-flex justify-space-between align-start mb-2">
                                <div class="mr-2 overflow-hidden">
                                    <h3 class="text-subtitle-1 font-weight-bold text-truncate"
                                        :class="isLightMode ? 'text-grey-darken-3' : 'text-white'"
                                        :title="item.stamp_ref">
                                        {{ item.stamp_ref }}
                                    </h3>
                                    <div class="d-flex align-center gap-2 mt-1">
                                        <v-chip size="x-small" :variant="isLightMode ? 'flat' : 'outlined'" :color="isLightMode ? 'grey-lighten-3' : 'white'" class="text-caption px-2">
                                            <span :class="isLightMode ? 'text-grey-darken-3' : 'text-white'">{{ item.fabric_type }}</span>
                                        </v-chip>
                                        <span class="text-caption font-weight-medium" :class="isLightMode ? 'text-grey-darken-1' : 'text-medium-emphasis'">
                                            {{ formatMeters(item.quantity_meters) }}m
                                        </span>
                                    </div>
                                </div>

                                <v-chip
                                    :color="statusInfo(item).color"
                                    size="small"
                                    variant="tonal"
                                    class="font-weight-bold text-uppercase flex-shrink-0"
                                    label
                                >
                                    {{ statusInfo(item).text }}
                                </v-chip>
                            </div>

                            <div class="d-flex flex-wrap gap-2 mt-2" v-if="item.design_tag">
                                <div class="text-[10px] px-2 py-0-5 rounded border"
                                     :class="isLightMode ? 'bg-grey-lighten-4 border-grey-lighten-2 text-grey-darken-2' : 'bg-white-05 border-white-05 text-medium-emphasis'">
                                    Design: <span :class="`text-${designTagMap[item.design_tag]?.color || 'white'}`">{{ item.design_tag }}</span>
                                </div>
                            </div>
                        </div>

                        <div class="d-flex align-center justify-end gap-2 mt-3 pt-3"
                             :class="isLightMode ? 'border-t border-grey-lighten-3' : 'border-t border-white-05'">

                            <v-btn
                                v-if="item.is_op_generated"
                                prepend-icon="mdi-printer-outline"
                                color="info"
                                variant="text"
                                size="small"
                                class="text-none px-2"
                                @click="generateOpPdf(item)"
                            >
                                OP #{{ item.op_number || 'Auto' }}
                            </v-btn>

                            <v-spacer></v-spacer>

                            <v-btn
                                v-if="canReleaseItem(item)"
                                :color="item.has_insufficient_stock ? 'warning' : 'primary'"
                                variant="flat"
                                @click="releaseItemForProduction(item)"
                                :loading="releasing[item.id]"
                                :disabled="item.has_insufficient_stock && !userStore.isAdmin"
                                class="font-weight-bold text-none px-4"
                                size="small"
                            >
                                <v-icon start size="small">{{ item.has_insufficient_stock ? 'mdi-shield-alert' : 'mdi-rocket-launch' }}</v-icon>
                                {{ item.has_insufficient_stock ? 'Forçar' : 'Liberar' }}
                            </v-btn>

                            <div v-else-if="['in_printing', 'in_cutting'].includes(item.status)" class="d-flex align-center text-success px-2">
                                <v-icon start size="small" class="mr-1">mdi-check-circle</v-icon>
                                <span class="text-[11px] font-weight-bold text-uppercase">Em Produção</span>
                            </div>
                        </div>
                    </div>

                    <div v-if="item.has_insufficient_stock" class="bg-warning-darken-4 py-1 px-3 d-flex align-center justify-center flex-sm-column" style="min-width: 30px;">
                        <v-tooltip text="Estoque Insuficiente" location="start" content-class="tooltip-contrast">
                            <template v-slot:activator="{ props }">
                                <v-icon v-bind="props" color="white" size="small">mdi-alert-circle</v-icon>
                            </template>
                        </v-tooltip>
                    </div>
                 </div>
               </template>
            </div>

            <div v-if="!loadingItems && localItems.length === 0" class="d-flex flex-column align-center justify-center h-100 opacity-50">
               <v-icon size="48" class="mb-2">mdi-package-variant</v-icon>
               <span>Nenhum item encontrado</span>
            </div>

          </div>

          <div class="modal-footer px-6 py-3 d-flex align-center justify-space-between flex-shrink-0"
               :class="isLightMode ? 'bg-grey-lighten-4 border-t' : 'bg-surface-light border-t border-white-05'">

             <div class="d-flex align-center gap-4">
                <span class="text-caption" :class="isLightMode ? 'text-grey-darken-1' : 'text-medium-emphasis'">
                   Mostrando {{ paginatedItems.length }} de {{ localItems.length }} itens
                </span>

                <div class="d-flex align-center gap-1">
                   <v-btn icon="mdi-chevron-left" variant="text" size="small" :disabled="currentPage === 1" @click="currentPage--"></v-btn>
                   <span class="text-caption font-weight-bold mx-2">{{ currentPage }} / {{ totalPages }}</span>
                   <v-btn icon="mdi-chevron-right" variant="text" size="small" :disabled="currentPage === totalPages" @click="currentPage++"></v-btn>
                </div>
             </div>

             <div class="d-flex align-center gap-2 opacity-60">
                 <v-icon size="14" color="warning">mdi-speedometer</v-icon>
                 <span class="text-[10px] text-uppercase font-weight-bold">Mantenha o sistema fluido: Evite acumular muitas liberações.</span>
             </div>
          </div>

        </div>
      </v-card-text>
    </v-card>

    <ImageModal
      v-model="showZoom"
      :image-url="zoomedImage"
      :title="zoomedTitle"
    />

  </v-dialog>
</template>

<script setup lang="ts">
import { ref, watch, reactive, computed } from "vue";
import { supabase } from "@/api/supabase";
import { useUserStore } from "@/stores/user";
import { useDashboardStore } from "@/stores/dashboard";
import { useThemeStore } from "@/stores/theme";
import ImageModal from "@/components/ImageModal.vue";
import jsPDF from "jspdf";
import autoTable from "jspdf-autotable";
import { format, addDays, parseISO, differenceInCalendarDays } from "date-fns";
import { ptBR } from "date-fns/locale";

const props = defineProps<{
  show: boolean;
  order: any | null;
}>();
const emit = defineEmits(["close", "update-items"]);

const userStore = useUserStore();
const dashboardStore = useDashboardStore();
const themeStore = useThemeStore();
const isLightMode = computed(() => themeStore.currentMode === 'light');

const releasing = reactive<Record<string, boolean>>({});
const localItems = ref<any[]>([]);
const loadingItems = ref(false);
const fullOrderDetails = ref<any | null>(null);
const isGeneratingPdf = ref(false);

// Pagination
const currentPage = ref(1);
const itemsPerPage = 5;

// Zoom State
const showZoom = ref(false);
const zoomedImage = ref('');
const zoomedTitle = ref('');

// --- Status Maps ---
const statusMap: Record<string, { text: string; color: string; hex: string, icon: string; }> = {
    production_queue: { text: 'Na Fila', color: 'grey', hex: '#9E9E9E', icon: 'mdi-timer-sand' },
    completed: { text: 'Concluído', color: 'success', hex: '#4CAF50', icon: 'mdi-check-circle' },
    in_printing: { text: 'Em Produção', color: 'blue', hex: '#2196F3', icon: 'mdi-printer-3d-nozzle' },
    in_cutting: { text: 'Em Corte', color: 'cyan', hex: '#00BCD4', icon: 'mdi-scissors-cutting' },
    customer_approval: { text: 'Aprovação', color: 'orange', hex: '#FB8C00', icon: 'mdi-account-clock' },
    changes_requested: { text: 'Alteração', color: 'error', hex: '#F44336', icon: 'mdi-alert-circle' },
    approved_by_seller: { text: 'Aprovado', color: 'green', hex: '#66BB6A', icon: 'mdi-check-decagram' },
    design_pending: { text: 'Design', color: 'blue-grey', hex: '#607D8B', icon: 'mdi-palette' },
    pending_stock: { text: 'S/ Estoque', color: 'amber', hex: '#FFB300', icon: 'mdi-package-variant-remove'}
};

const designTagMap: Record<string, { color: string, hex: string }> = {
    'Desenvolvimento': { color: 'info', hex: '#03A9F4' },
    'Alteração': { color: 'warning', hex: '#FFB300' },
    'Finalização': { color: 'teal', hex: '#009688' },
    'Aprovado': { color: 'success', hex: '#4CAF50' }
};

// --- Computed Properties ---
const totalPages = computed(() => Math.ceil(localItems.value.length / itemsPerPage) || 1);

const paginatedItems = computed(() => {
    const start = (currentPage.value - 1) * itemsPerPage;
    return localItems.value.slice(start, start + itemsPerPage);
});

const releasedCount = computed(() =>
    localItems.value.filter(i => ['in_printing', 'in_cutting', 'completed'].includes(i.status)).length
);

const releaseProgress = computed(() => {
    if (localItems.value.length === 0) return 0;
    return (releasedCount.value / localItems.value.length) * 100;
});

// --- Logic for Delay Alert ---
const getDaysWaiting = (item: any) => {
    const startDate = item.created_at || props.order?.created_at;
    if (!startDate) return 0;
    return differenceInCalendarDays(new Date(), new Date(startDate));
};

const isItemDelayed = (item: any) => {
    return item.status === 'production_queue' && getDaysWaiting(item) > 3;
};

// --- Actions ---

// CORREÇÃO: Função para solicitar imagem comprimida do servidor se for do Supabase
const getThumbnailUrl = (url: string | null | undefined) => {
    if (!url) return '/placeholder.png';

    // Se for uma imagem do Supabase Storage, pedimos uma versão reduzida em vez de baixar o arquivo inteiro.
    // Isso elimina o lag/stuttering no frontend ao carregar a lista.
    if (url.includes('supabase.co/storage/v1/object/public/')) {
        const hasQueryParams = url.includes('?');
        // Pede largura máxima de 250px e qualidade 60 para a miniatura
        return `${url}${hasQueryParams ? '&' : '?'}width=250&quality=60`;
    }

    return url;
};

const openImageZoom = (item: any) => {
    if(!item.stamp_image_url) return;
    // O modal continua recebendo a URL original (alta qualidade)
    zoomedImage.value = item.stamp_image_url;
    zoomedTitle.value = item.stamp_ref;
    showZoom.value = true;
};

const formatDate = (dateString: string) => {
    if(!dateString) return '--/--';
    return format(new Date(dateString), 'dd/MM/yyyy');
}

const statusInfo = (item: any) => {
    if (item.has_insufficient_stock) {
        return { text: 'Estoque Baixo', color: 'warning', hex: '#FFB300', icon: 'mdi-alert-octagon' };
    }
    if (item.status === 'design_pending' && item.design_tag) {
        const tagInfo = designTagMap[item.design_tag];
        if (tagInfo) {
            return {
                text: item.design_tag,
                color: tagInfo.color,
                hex: tagInfo.hex,
                icon: 'mdi-palette'
            };
        }
    }
    return statusMap[item.status] || { text: item.status, color: 'default', hex: '#9E9E9E', icon: 'mdi-help-circle' };
};

const fetchFullOrderDetails = async (orderId: string) => {
  loadingItems.value = true;
  localItems.value = [];
  try {
    const { data, error } = await supabase
      .from("orders")
      .select("*, created_by:profiles!created_by(full_name), order_items(*, has_insufficient_stock)")
      .eq("id", orderId)
      .maybeSingle();

    if (error) throw error;
    if (data) {
        fullOrderDetails.value = data;
        localItems.value = data.order_items.sort((a: any, b: any) => a.id.localeCompare(b.id));
    }
  } catch (err) {
    console.error("Erro ao buscar detalhes completos do pedido:", err);
  } finally {
    loadingItems.value = false;
  }
};

watch(
  () => props.show,
  (newVal) => {
    if (newVal && props.order) {
      currentPage.value = 1;
      fetchFullOrderDetails(props.order.id);
    } else {
      localItems.value = [];
      fullOrderDetails.value = null;
    }
  },
  { immediate: true }
);

const canReleaseItem = (item: any) => {
  return item.status === "production_queue";
};

const releaseItemForProduction = async (item: any) => {
  let confirmationText = `Tem certeza que deseja liberar o item "${item.stamp_ref}" para a produção? A data de início será resetada para HOJE.`;

  if (item.has_insufficient_stock && userStore.isAdmin) {
      confirmationText = `ATENÇÃO, ADMINISTRADOR!\n\nEste item NÃO possui estoque suficiente.\n\nTem certeza que deseja FORÇAR a liberação do item "${item.stamp_ref}" para a produção?`;
  }

  if (!confirm(confirmationText)) return;

  releasing[item.id] = true;
  try {
    const { error: rpcError } = await supabase.rpc(
      "release_item_to_production_v2",
      {
        p_item_id: item.id,
      }
    );

    if (rpcError) throw rpcError;

    const foundItem = localItems.value.find((i) => i.id === item.id);
    if (foundItem) {
      foundItem.status = "in_printing";
      foundItem.has_insufficient_stock = false;
    }

    emit("update-items");
    await dashboardStore.fetchProductionSchedule();

  } catch (err: any) {
    console.error("Erro ao liberar item para produção:", err);
    alert(`Falha ao liberar o item: ${err.message}`);
  } finally {
    releasing[item.id] = false;
  }
};

const formatMeters = (meters: number) =>
  Number(meters || 0).toLocaleString("pt-BR", {
    minimumFractionDigits: 0,
    maximumFractionDigits: 1,
  });

// --- PDF GENERATION LOGIC ---
const imageToBase64 = async (url: string): Promise<string> => {
  try {
    const response = await fetch(url, { mode: 'cors', cache: 'no-store' });
    if (!response.ok) throw new Error(`Fetch failed: ${response.status}`);
    const blob = await response.blob();
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onloadend = () => resolve(reader.result as string);
      reader.onerror = reject;
      reader.readAsDataURL(blob);
    });
  } catch (e) {
    console.warn("Falha ao carregar imagem para PDF:", e);
    return 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';
  }
};

const generateOrderSummaryPdf = async () => {
    if (!fullOrderDetails.value) {
        alert("Aguarde os detalhes do pedido serem carregados.");
        return;
    }
    isGeneratingPdf.value = true;
    try {
        const order = fullOrderDetails.value;
        const doc = new jsPDF();
        const pageWidth = doc.internal.pageSize.width;

        const logoUrl = 'https://cdn.shopify.com/s/files/1/0661/4574/6991/files/Sem_nome_1080_x_800_px_1080_x_500_px_1080_x_400_px_1000_x_380_px_da020cf2-2bb9-4dac-8dd3-4548cfd2e5ae.png?v=1756811713';
        const logoBase64 = await imageToBase64(logoUrl);
        const logoProps = doc.getImageProperties(logoBase64);
        const logoWidth = 50;
        const logoHeight = (logoProps.height * logoWidth) / logoProps.width;
        doc.addImage(logoBase64, 'PNG', 15, 12, logoWidth, logoHeight);

        doc.setFontSize(9); doc.setTextColor(100);
        doc.text(["MR JACKY - 20.631.721/0001-07", "RUA LUIZ MONTANHAN, 1302 TIRO DE GUERRA - TIETE - SP CEP: 18.532-000", "Fone/Celular: (15) 99847-8789 | E-mail: mrjackyfinanceiro@gmail.com"], pageWidth - 15, 15, { align: 'right' });

        doc.setFontSize(18).setTextColor(0).text(`Resumo do Pedido #${String(order.order_number).padStart(4, '0')}`, 15, 45);
        doc.setLineWidth(0.5).line(15, 50, pageWidth - 15, 50);

        autoTable(doc, {
            startY: 55,
            body: [
                ['Cliente', order.customer_name],
                ['Vendedor', order.created_by?.full_name || 'N/A'],
                ['Data do Lançamento', format(parseISO(order.created_at), 'dd/MM/yyyy HH:mm', { locale: ptBR })],
                ['Faturamento', order.billed_at ? `Faturado em ${format(parseISO(order.billed_at), 'dd/MM/yyyy')}` : 'Aguardando Faturamento'],
            ],
            theme: 'striped', styles: { fontSize: 9 }, bodyStyles: { cellWidth: 'wrap' }, columnStyles: { 0: { fontStyle: 'bold' } },
        });

        let currentY = (doc as any).lastAutoTable.finalY + 5;

        // INJEÇÃO DA OBSERVAÇÃO NO RESUMO DO PEDIDO
        const orderNotes = String(order.notes || order.details?.observation || "").trim();
        if (orderNotes) {
            doc.setFillColor(255, 243, 224);
            doc.setDrawColor(255, 183, 77);
            doc.setLineWidth(0.3);
            const splitNotes = doc.splitTextToSize(orderNotes, pageWidth - 34);
            const notesHeight = (splitNotes.length * 4) + 8;
            doc.rect(15, currentY, pageWidth - 30, notesHeight, "FD");
            doc.setFont("helvetica", "bold");
            doc.setTextColor(230, 81, 0);
            doc.text("OBSERVAÇÕES DO VENDEDOR / PEDIDO:", 17, currentY + 5);
            doc.setFont("helvetica", "normal");
            doc.setTextColor(0);
            doc.text(splitNotes, 17, currentY + 10);
            currentY += notesHeight + 10;
        } else {
            currentY += 5;
        }

        doc.setFontSize(12).setFont('helvetica', 'bold').setTextColor(0).text('Itens do Pedido', 15, currentY + 5);

        const tableBody = await Promise.all(order.order_items.map(async (item: any) => {
            let opText = 'Não Liberada';
            if (item.is_op_generated) {
                const { data: opNumber, error } = await supabase.rpc('generate_op_number', { p_item_id: item.id });
                if (error) {
                    console.error(`Erro ao buscar OP para item ${item.id}:`, error);
                    opText = 'Erro';
                } else {
                    opText = `#${String(opNumber).padStart(4, '0')}`;
                }
            }
            return [
                item.stamp_ref,
                item.fabric_type,
                `${formatMeters(item.quantity_meters)}m`,
                statusInfo(item).text,
                opText,
            ];
        }));

        autoTable(doc, {
            startY: currentY + 8,
            head: [['Estampa (Ref.)', 'Produto (Base)', 'Qtd.', 'Status', 'OP']],
            body: tableBody,
            theme: 'grid',
            headStyles: { fillColor: [41, 128, 185] },
            columnStyles: { 3: { cellWidth: 35 } },
            willDrawCell: (data) => {
                if (data.section === 'body' && data.column.index === 3) {
                    const item = order.order_items[data.row.index];
                    const sInfo = statusInfo(item);
                    const color = sInfo.hex.match(/\w\w/g)?.map((x) => parseInt(x, 16));
                    if (color) {
                       doc.setFillColor(color[0], color[1], color[2]);
                       doc.setTextColor(255, 255, 255);
                    }
                }
            },
        });

        const allStatusObjects = { ...statusMap, ...Object.fromEntries(Object.entries(designTagMap).map(([key, value]) => [key, { ...value, text: key }])) };
        const legendData = Object.values(allStatusObjects)
            .filter((v, i, a) => a.findIndex(t => t.hex === v.hex) === i)
            .map(s => ({ text: s.text, color: s.hex.match(/\w\w/g)?.map((x) => parseInt(x, 16)) }));

        doc.setFontSize(10).setFont('helvetica', 'bold').setTextColor(0).text('Legenda de Status', 15, (doc as any).lastAutoTable.finalY + 10);
        let startY = (doc as any).lastAutoTable.finalY + 15;
        legendData.forEach((legend) => {
            if (legend.color) {
                doc.setFillColor(legend.color[0], legend.color[1], legend.color[2]);
                doc.rect(15, startY - 2.5, 3, 3, 'F');
                doc.setFontSize(8).setFont('helvetica', 'normal').setTextColor(0,0,0);
                doc.text(legend.text, 20, startY);
                startY += 5;
            }
        });

        const pageHeight = doc.internal.pageSize.height;
        doc.setFontSize(9).setTextColor(150).text('Gerado com MJProcess', pageWidth / 2, pageHeight - 10, { align: 'center' });

        doc.save(`Resumo_Pedido_${String(order.order_number).padStart(4, '0')}.pdf`);

    } catch (error) {
        console.error("Erro ao gerar PDF de resumo:", error);
        alert("Ocorreu um erro ao gerar o PDF. Verifique o console para mais detalhes.");
    } finally {
        isGeneratingPdf.value = false;
    }
};

const addBusinessDays = (startDate: Date, days: number): Date => {
  const newDate = new Date(startDate);
  let addedDays = 0;
  while (addedDays < days) {
    newDate.setDate(newDate.getDate() + 1);
    if (newDate.getDay() !== 0) addedDays++;
  }
  return newDate;
};

const getNextDeliveryDay = (date: Date): Date => {
  const newDate = new Date(date);
  newDate.setDate(newDate.getDate() + 1);
  while (true) {
    if ([2, 4, 6].includes(newDate.getDay())) return newDate;
    newDate.setDate(newDate.getDate() + 1);
  }
};

const generateOpPdf = async (item: any) => {
  const parentOrder = fullOrderDetails.value;
  if (!parentOrder) {
    alert("Os detalhes completos do pedido ainda estão carregando. Tente novamente em um instante.");
    return;
  }

  isGeneratingPdf.value = true;
  try {
    const { data: opNumber, error: rpcError } = await supabase.rpc("generate_op_number", { p_item_id: item.id });
    if (rpcError) throw rpcError;

    const { data: schedule } = await supabase
      .from("production_schedule")
      .select("scheduled_date")
      .eq("order_item_id", item.id)
      .maybeSingle();

    const scheduleDate = (schedule && schedule.scheduled_date)
        ? parseISO(schedule.scheduled_date)
        : new Date();

    const hasStockIssues = parentOrder.order_items.some((i: any) => i.has_insufficient_stock || i.status === 'pending_stock');
    const extraDays = hasStockIssues ? 2 : 0;

    const completionDate = addBusinessDays(scheduleDate, 3 + extraDays);
    const forecastDate = getNextDeliveryDay(completionDate);
    const formattedOpNumber = String(opNumber).padStart(4, "0");
    const formattedForecastDate = format(forecastDate, "dd/MM/yyyy", { locale: ptBR });
    const formattedOrderNumber = String(parentOrder.order_number).padStart(4, "0");

    const doc = new jsPDF();

    // Na OP o PDF continua buscando a imagem em altíssima qualidade (URL original)
    const [logoBase64, artBase64] = await Promise.all([
      imageToBase64("https://cdn.shopify.com/s/files/1/0661/4574/6991/files/Sem_nome_1080_x_800_px_1080_x_500_px_1080_x_400_px_1000_x_380_px_da020cf2-2bb9-4dac-8dd3-4548cfd2e5ae.png?v=1756811713"),
      imageToBase64(item.stamp_image_url || ""),
    ]);

    const drawCommonHeader = () => {
      const pageWidth = doc.internal.pageSize.width;
      const logoProps = doc.getImageProperties(logoBase64);
      const logoWidth = 50;
      const logoHeight = (logoProps.height * logoWidth) / logoProps.width;
      doc.addImage(logoBase64, "PNG", 15, 12, logoWidth, logoHeight);

      doc.setFontSize(9).setTextColor(100);
      doc.text(
        [ "MR JACKY - 20.631.721/0001-07", "RUA LUIZ MONTANHAN, 1302 TIRO DE GUERRA - TIETE - SP CEP: 18.532-000", "Fone/Celular: (15) 99847-8789 | E-mail: mrjackyfinanceiro@gmail.com" ],
        pageWidth - 15, 15, { align: "right" }
      );
    };

    const drawProductionVia = () => {
      const pageHeight = doc.internal.pageSize.height;
      const pageWidth = doc.internal.pageSize.width;
      drawCommonHeader();

      doc.setFontSize(10).setFont('helvetica', 'bold').setTextColor(0, 0, 0);
      doc.text("VIA DA PRODUÇÃO", pageWidth / 2, 40, { align: "center" });

      doc.setFontSize(18).setTextColor(0);
      doc.text(`OP #${formattedOpNumber}`, 15, 45);
      doc.setFontSize(12);
      doc.text(`Pedido #${formattedOrderNumber}`, pageWidth - 15, 45, { align: "right" });
      doc.setLineWidth(0.5).line(15, 50, pageWidth - 15, 50);

      autoTable(doc, {
        startY: 55,
        head: [["CLIENTE", "VENDEDOR", "EMISSÃO", "PREVISÃO DE ENTREGA"]],
        body: [[ parentOrder.customer_name, parentOrder.created_by?.full_name || "N/A", format(new Date(parentOrder.created_at), "dd/MM/yyyy", { locale: ptBR }), formattedForecastDate, ]],
        theme: "striped", headStyles: { fillColor: [41, 128, 185] },
      });

      autoTable(doc, {
        startY: (doc as any).lastAutoTable.finalY + 10,
        head: [["PRODUTO (BASE)", "SERVIÇO (ESTAMPA)", "QUANTIDADE"]],
        body: [[item.fabric_type, item.stamp_ref, `${item.quantity_meters}m`]],
        theme: "grid", headStyles: { fillColor: [41, 128, 185] },
      });

      let currentY = (doc as any).lastAutoTable.finalY + 10;

      // INJEÇÃO DA OBSERVAÇÃO DO PEDIDO NA VIA DE PRODUÇÃO
      const notesContent = String(parentOrder.notes || parentOrder.details?.observation || "").trim();
      if (notesContent) {
          doc.setFillColor(255, 243, 224);
          doc.setDrawColor(255, 183, 77);
          doc.setLineWidth(0.3);
          doc.setFont("helvetica", "normal");
          doc.setFontSize(8.5);
          const splitNotes = doc.splitTextToSize(notesContent, pageWidth - 34);
          const notesHeight = (splitNotes.length * 4) + 8;
          doc.rect(15, currentY, pageWidth - 30, notesHeight, "FD");
          doc.setFont("helvetica", "bold");
          doc.setTextColor(230, 81, 0);
          doc.text("OBSERVAÇÕES DO VENDEDOR / PEDIDO:", 17, currentY + 5);
          doc.setFont("helvetica", "normal");
          doc.setTextColor(0);
          doc.text(splitNotes, 17, currentY + 10);
          currentY += notesHeight + 10;
      } else {
          currentY += 5;
      }

      const artStartY = currentY;
      doc.setFontSize(12).setFont("helvetica", "bold").setTextColor(0,0,0).text("ARTE APROVADA", 15, artStartY);
      doc.setFontSize(10).setFont('helvetica', 'normal').setTextColor(100).text(`Cliente: ${parentOrder.customer_name}`, 15, artStartY + 5);
      const artY = artStartY + 10;
      const maxImgWidth = pageWidth - 30; const maxImgHeight = pageHeight - artY - 25;
      const imgProps = doc.getImageProperties(artBase64);
      const ratio = Math.min( maxImgWidth / imgProps.width, maxImgHeight / imgProps.height );
      const imgWidth = imgProps.width * ratio; const imgHeight = imgProps.height * ratio;
      const imgXCentered = (pageWidth - imgWidth) / 2;
      doc.setDrawColor(180, 180, 180).setLineWidth(0.5).rect(imgXCentered - 1, artY - 1, imgWidth + 2, imgHeight + 2, "S");
      doc.addImage(artBase64, "PNG", imgXCentered, artY, imgWidth, imgHeight);

      doc.setFontSize(9).setTextColor(150).text("OP gerada com MJProcess", pageWidth / 2, pageHeight - 15, { align: "center", });
    };

    const drawArchiveVia = () => {
      const pageHeight = doc.internal.pageSize.height;
      const pageWidth = doc.internal.pageSize.width;
      drawCommonHeader();

      doc.setFontSize(18).setTextColor(0);
      doc.text(`OP #${formattedOpNumber}`, 15, 45);

      doc.setFontSize(10).setFont('helvetica', 'bold').setTextColor(150, 0, 0);
      doc.text("VIA PARA ARQUIVAMENTO", pageWidth / 2, 40, { align: "center" });
      doc.setTextColor(0);

      doc.setFontSize(12);
      doc.text(`Pedido #${formattedOrderNumber}`, pageWidth - 15, 45, { align: "right" });
      doc.setLineWidth(0.5).line(15, 50, pageWidth - 15, 50);

      autoTable(doc, {
        startY: 55,
        theme: "grid",
        headStyles: { fillColor: [41, 128, 185] },
        head: [['CLIENTE', 'REFERÊNCIA (ESTAMPA)', 'PRODUTO (BASE)']],
        body: [[parentOrder.customer_name, item.stamp_ref, item.fabric_type]],
      });

      let currentY = (doc as any).lastAutoTable.finalY + 10;

      // INJEÇÃO DA OBSERVAÇÃO DO PEDIDO NA VIA DE ARQUIVO
      const notesContent = String(parentOrder.notes || parentOrder.details?.observation || "").trim();
      if (notesContent) {
          doc.setFillColor(255, 243, 224);
          doc.setDrawColor(255, 183, 77);
          doc.setLineWidth(0.3);
          doc.setFont("helvetica", "normal");
          doc.setFontSize(8.5);
          const splitNotes = doc.splitTextToSize(notesContent, pageWidth - 34);
          const notesHeight = (splitNotes.length * 4) + 8;
          doc.rect(15, currentY, pageWidth - 30, notesHeight, "FD");
          doc.setFont("helvetica", "bold");
          doc.setTextColor(230, 81, 0);
          doc.text("OBSERVAÇÕES DO VENDEDOR / PEDIDO:", 17, currentY + 5);
          doc.setFont("helvetica", "normal");
          doc.setTextColor(0);
          doc.text(splitNotes, 17, currentY + 10);
          currentY += notesHeight + 10;
      } else {
          currentY += 5;
      }

      const artStartY = currentY;
      doc.setFontSize(12).setFont("helvetica", "bold").setTextColor(0,0,0).text("ARTE APROVADA", 15, artStartY);
      const artY = artStartY + 5;
      const maxImgWidth = pageWidth - 30; const maxImgHeight = pageHeight - artY - 25;
      const imgProps = doc.getImageProperties(artBase64);
      const ratio = Math.min( maxImgWidth / imgProps.width, maxImgHeight / imgProps.height );
      const imgWidth = imgProps.width * ratio; const imgHeight = imgProps.height * ratio;
      const imgXCentered = (pageWidth - imgWidth) / 2;
      doc.setDrawColor(180, 180, 180).setLineWidth(0.5).rect(imgXCentered - 1, artY - 1, imgWidth + 2, imgHeight + 2, "S");
      doc.addImage(artBase64, "PNG", imgXCentered, artY, imgWidth, imgHeight);

      doc.setFontSize(9).setTextColor(150).text("OP gerada com MJProcess", pageWidth / 2, pageHeight - 15, { align: "center", });
    };

    drawProductionVia();
    doc.addPage();
    drawArchiveVia();

    doc.save(`OP-${formattedOpNumber}-${parentOrder.customer_name}-${item.stamp_ref}.pdf`);
  } catch (error) {
    console.error("Erro ao gerar PDF:", error);
    alert("Não foi possível gerar o PDF. Verifique se as imagens estão acessíveis e tente novamente.");
  } finally {
      isGeneratingPdf.value = false;
  }
};

</script>

<style scoped lang="scss">
/* Default (Dark / Glass) Styles */
.release-modal-card {
  background-color: #1e1e24;
  color: white;
  border-radius: 12px;
  border: 1px solid rgba(255, 255, 255, 0.08);

  &.light-mode {
     background-color: #ffffff;
     color: #1e1e24;
     border: none;
     border-radius: 8px; /* Slightly squarer for enterprise feel */
  }
}

.sidebar-panel {
    width: 280px;
    @media (max-width: 960px) {
        width: 100%;
        height: auto;
        border-right: none;
        border-bottom: 1px solid rgba(255,255,255,0.05);
    }
}

.bg-header-dark { background-color: #27272f; border-bottom: 1px solid rgba(255,255,255,0.05); }
.bg-surface-dark { background-color: #121212; }
.bg-surface-light { background-color: #2c2c35; }
.bg-surface-card { background-color: #23232a; }

/* Light Mode Specifics Override */
.light-mode {
    .bg-surface-base { background-color: #ffffff; }
    .border-b { border-bottom: 1px solid #e0e0e0 !important; }
    .border-r { border-right: 1px solid #e0e0e0 !important; }
    .border-t { border-top: 1px solid #e0e0e0 !important; }
    .border { border-color: #e0e0e0 !important; }
    .border-dashed { border-style: dashed; }
    .border-solid { border: 1px solid #e0e0e0; }
}

.item-card {
  transition: all 0.2s;
  &:hover {
      transform: translateY(-2px);
      box-shadow: 0 4px 8px rgba(0,0,0,0.1);
  }
}

/* --- ANIMATIONS FOR DELAYED ITEMS --- */
@keyframes pulse-red {
    0% { box-shadow: 0 0 0 0 rgba(244, 67, 54, 0.4); border-color: rgba(244, 67, 54, 0.8) !important; }
    70% { box-shadow: 0 0 0 6px rgba(244, 67, 54, 0); border-color: rgba(244, 67, 54, 0.2) !important; }
    100% { box-shadow: 0 0 0 0 rgba(244, 67, 54, 0); border-color: rgba(244, 67, 54, 0.8) !important; }
}

@keyframes fade-in-out {
    0%, 100% { opacity: 0.4; transform: scale(0.9); }
    50% { opacity: 1; transform: scale(1.1); }
}

.delayed-item {
    animation: pulse-red 2s infinite;
    border: 1px solid rgb(var(--v-theme-error)) !important;
}

.fade-animation {
    animation: fade-in-out 1.5s infinite ease-in-out;
}
/* ----------------------------------- */

.bg-primary-gradient { background: linear-gradient(135deg, rgb(var(--v-theme-primary)), #1565c0); }
.icon-box-lg { width: 48px; height: 48px; }

.thumbnail-area {
  width: 140px;
  min-height: 120px;
  overflow: hidden;

  @media (max-width: 600px) { width: 100%; height: 180px; }

  &:hover .overlay-zoom { opacity: 1; }
}

.overlay-zoom {
  position: absolute; inset: 0;
  background: rgba(0,0,0,0.5);
  opacity: 0; transition: opacity 0.2s;
}

.text-medium-emphasis { color: rgba(255,255,255,0.7) !important; }
.border-white-05 { border-color: rgba(255,255,255,0.05) !important; }
.bg-white-05 { background: rgba(255,255,255,0.05); }
.gap-2 { gap: 8px; } .gap-3 { gap: 12px; } .gap-4 { gap: 16px; }
.lh-1 { line-height: 1.2; }
.truncate-text {
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
    max-width: 180px;
}

/* Scrollbar styling */
.custom-scrollbar::-webkit-scrollbar { width: 8px; }
.custom-scrollbar::-webkit-scrollbar-track { background: transparent; }
.custom-scrollbar::-webkit-scrollbar-thumb {
    background: rgba(128,128,128,0.3);
    border-radius: 4px;
}
.light-mode .custom-scrollbar::-webkit-scrollbar-thumb { background: rgba(0,0,0,0.2); }
</style>
