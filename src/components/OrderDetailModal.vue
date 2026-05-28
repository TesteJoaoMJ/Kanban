<template>
  <v-dialog
    :model-value="show"
    @update:model-value="$emit('close')"
    max-width="1200px"
    persistent
    transition="dialog-bottom-transition"
    class="order-detail-dialog"
  >
    <v-card class="order-modal-card d-flex flex-column overflow-hidden" :class="{ 'light-mode': isLightMode }">

      <div class="modal-header px-6 py-4 d-flex align-center justify-space-between flex-shrink-0"
           :class="isLightMode ? 'bg-white border-b border-grey-lighten-2' : 'bg-header-dark border-b border-white-05'">

        <div class="d-flex align-center gap-4">
          <div class="icon-box-md rounded-lg d-flex align-center justify-center"
               :class="isLightMode ? 'bg-primary-lighten-5 text-primary' : 'bg-primary-gradient elevation-2'">
             <v-icon size="24">mdi-package-variant-closed</v-icon>
          </div>
          <div>
            <h2 class="text-h6 font-weight-bold lh-1 mb-1" :class="isLightMode ? 'text-grey-darken-3' : 'text-white'">
              Pedido #{{ order ? String(order.order_number).padStart(4, '0') : '---' }}
            </h2>
            <div class="d-flex align-center gap-3 text-caption" :class="isLightMode ? 'text-grey-darken-1' : 'text-medium-emphasis'">
              <span class="d-flex align-center"><v-icon size="12" class="mr-1">mdi-calendar</v-icon> {{ order ? formatDate(order.created_at) : '--/--' }}</span>
              <span class="d-flex align-center" v-if="order?.stores"><v-icon size="12" class="mr-1">mdi-store</v-icon> {{ order.stores.name }}</span>
            </div>
          </div>
        </div>

        <v-btn icon variant="text" :color="isLightMode ? 'grey-darken-2' : 'white-50'" @click="$emit('close')">
          <v-icon>mdi-close</v-icon>
        </v-btn>
      </div>

      <div v-if="loading" class="d-flex flex-column align-center justify-center flex-grow-1" style="min-height: 400px">
        <v-progress-circular indeterminate color="primary" size="64" width="4"></v-progress-circular>
        <span class="mt-4 text-caption font-weight-bold text-uppercase tracking-widest" :class="isLightMode ? 'text-grey-darken-2' : 'text-medium-emphasis'">Carregando Detalhes...</span>
      </div>

      <div v-else-if="error" class="d-flex flex-column align-center justify-center flex-grow-1 pa-8">
        <v-icon size="64" color="error" class="mb-4 opacity-50">mdi-alert-circle-outline</v-icon>
        <p class="text-body-1 font-weight-medium mb-4" :class="isLightMode ? 'text-grey-darken-3' : 'text-white'">{{ error }}</p>
        <v-btn color="primary" variant="flat" @click="fetchOrder(orderId)">Tentar Novamente</v-btn>
      </div>

      <div v-else-if="order && focusedItem" class="d-flex flex-column flex-md-row flex-grow-1 overflow-hidden" style="height: 100%;">

        <div class="details-sidebar d-flex flex-column flex-shrink-0"
             :class="isLightMode ? 'bg-grey-lighten-5 border-r border-grey-lighten-2' : 'bg-surface-sidebar border-r border-white-05'">

            <div class="pa-5 pb-2">
                <div class="text-overline font-weight-bold mb-3 opacity-60" :class="isLightMode ? 'text-grey-darken-4' : 'text-white'">Resumo do Pedido</div>

                <div class="info-grid">
                    <div>
                        <div class="label">Cliente</div>
                        <div class="value font-weight-bold text-truncate" :title="order.customer_name">{{ order.customer_name }}</div>
                    </div>
                    <div>
                        <div class="label">Vendedor</div>
                        <div class="value text-truncate">{{ order.profiles?.full_name || 'N/A' }}</div>
                    </div>
                </div>

                <div class="mt-4 pa-3 rounded-lg border d-flex align-center justify-space-between"
                     :class="isLightMode ? 'bg-white border-grey-lighten-2' : 'bg-surface-light border-white-05'">
                    <span class="text-caption font-weight-bold text-uppercase opacity-70">Total</span>
                    <div class="text-h6 font-weight-black lh-1" :class="isLightMode ? 'text-primary' : 'text-white'">
                        {{ formatMeters(totalMeters) }}<span class="text-caption ml-1">m</span>
                    </div>
                </div>
            </div>

            <v-divider class="my-2" :class="isLightMode ? 'border-grey-lighten-2' : 'border-white-05'"></v-divider>

            <div class="flex-grow-1 overflow-y-auto custom-scrollbar px-3 pb-3">
                <div class="text-caption font-weight-bold mb-2 px-2 opacity-50 text-uppercase">Itens do Pedido ({{ order.order_items.length }})</div>

                <div v-for="item in order.order_items" :key="item.id"
                     class="item-nav-card d-flex align-center pa-2 mb-2 rounded-lg cursor-pointer transition-all"
                     :class="[
                        focusedItem.id === item.id
                            ? (isLightMode ? 'bg-primary-lighten-5 border-primary ring-active' : 'bg-primary-surface border-primary')
                            : (isLightMode ? 'bg-white border-transparent hover:bg-grey-lighten-4' : 'bg-transparent border-transparent hover:bg-white-05')
                     ]"
                     @click="selectItem(item)"
                >
                    <v-img :src="item.stamp_image_url || '/placeholder.png'"
                           width="40" height="40" cover class="rounded bg-grey-darken-3 flex-shrink-0 mr-3"></v-img>
                    <div class="flex-grow-1 min-w-0">
                        <div class="text-caption font-weight-bold text-truncate" :class="isLightMode ? 'text-grey-darken-3' : 'text-white'">{{ item.stamp_ref }}</div>
                        <div class="text-[10px] text-truncate opacity-70" :class="isLightMode ? 'text-grey-darken-1' : 'text-grey-lighten-1'">{{ item.fabric_type }}</div>
                    </div>
                    <div class="text-caption font-weight-bold ml-2" :class="isLightMode ? 'text-grey-darken-3' : 'text-white'">{{ formatMeters(item.quantity_meters) }}m</div>
                </div>
            </div>
        </div>

        <div class="main-stage flex-grow-1 d-flex flex-column overflow-y-auto custom-scrollbar" :class="isLightMode ? 'bg-white' : 'bg-surface-body'">

            <div class="hero-section position-relative bg-black d-flex justify-center align-center" style="min-height: 350px; max-height: 450px;">
                <v-img :src="focusedItem.stamp_image_url || '/placeholder.png'"
                       max-height="100%" width="100%" contain class="bg-pattern">
                    <template v-slot:placeholder>
                        <div class="d-flex align-center justify-center fill-height">
                            <v-progress-circular indeterminate color="white-20"></v-progress-circular>
                        </div>
                    </template>
                </v-img>

                <div class="hero-controls position-absolute bottom-0 w-100 pa-4 d-flex justify-center gap-2 gradient-overlay">
                    <v-btn variant="flat" color="white" rounded="pill" size="small" prepend-icon="mdi-magnify-plus-outline"
                           class="text-body-2 font-weight-bold text-black" @click="openZoom(focusedItem)">
                        Ampliar Arte
                    </v-btn>
                    <v-btn variant="flat" color="rgba(255,255,255,0.2)" rounded="pill" size="small" icon="mdi-download"
                           @click="downloadImage(focusedItem.stamp_image_url, focusedItem.stamp_ref)">
                    </v-btn>
                </div>
            </div>

            <div class="content-body pa-6 flex-grow-1">

                <div class="d-flex flex-column flex-sm-row justify-space-between align-start gap-4 mb-6">
                    <div>
                        <div class="d-flex align-center gap-2 mb-1">
                            <v-chip size="x-small" :color="focusedItem.is_op_generated ? 'success' : 'warning'" variant="flat" label class="font-weight-bold text-uppercase">
                                {{ focusedItem.is_op_generated ? 'OP Gerada' : 'Aguardando OP' }}
                            </v-chip>
                            <span class="text-caption font-weight-medium opacity-60">ID: {{ focusedItem.id.split('-')[0] }}</span>
                        </div>
                        <h1 class="text-h4 font-weight-black lh-1" :class="isLightMode ? 'text-grey-darken-4' : 'text-white'">
                            {{ focusedItem.stamp_ref }}
                        </h1>
                    </div>

                    <v-chip :color="getItemDisplay(focusedItem).color" variant="tonal" size="large" label class="font-weight-bold px-4">
                        <v-icon start class="mr-2">{{ getItemDisplay(focusedItem).icon }}</v-icon>
                        {{ getItemDisplay(focusedItem).text }}
                    </v-chip>
                </div>

                <v-divider class="mb-6" :class="isLightMode ? 'border-grey-lighten-2' : 'border-white-05'"></v-divider>

                <div class="specs-grid d-grid gap-4 mb-8">
                    <div class="spec-item pa-3 rounded-lg border" :class="isLightMode ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-surface-light border-white-05'">
                        <div class="label">Tecido / Base</div>
                        <div class="value d-flex align-center gap-2">
                            <v-icon size="small" color="primary">mdi-texture-box</v-icon>
                            {{ focusedItem.fabric_type }}
                        </div>
                    </div>
                    <div class="spec-item pa-3 rounded-lg border" :class="isLightMode ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-surface-light border-white-05'">
                        <div class="label">Quantidade</div>
                        <div class="value d-flex align-center gap-2">
                            <v-icon size="small" color="primary">mdi-ruler</v-icon>
                            {{ formatMeters(focusedItem.quantity_meters) }}m
                        </div>
                    </div>
                    <div class="spec-item pa-3 rounded-lg border" :class="isLightMode ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-surface-light border-white-05'">
                        <div class="label">Tag de Design</div>
                        <div class="value d-flex align-center gap-2">
                            <v-icon size="small" color="primary">mdi-tag-text-outline</v-icon>
                            {{ focusedItem.design_tag || 'N/A' }}
                        </div>
                    </div>
                </div>

                <div class="action-card d-flex align-center gap-4 pa-5 rounded-xl border transition-all"
                     :class="isLightMode ? 'bg-blue-grey-lighten-5 border-blue-grey-lighten-4' : 'bg-surface-card border-white-05'">

                    <div class="icon-circle-lg flex-shrink-0" :class="isLightMode ? 'bg-white text-primary elevation-1' : 'bg-primary-surface text-primary'">
                        <v-icon size="28">mdi-printer-outline</v-icon>
                    </div>

                    <div class="flex-grow-1">
                        <div class="text-subtitle-1 font-weight-bold" :class="isLightMode ? 'text-grey-darken-3' : 'text-white'">Ordem de Produção</div>
                        <div class="text-body-2 opacity-70" :class="isLightMode ? 'text-grey-darken-1' : 'text-grey-lighten-1'">
                            {{ focusedItem.is_op_generated ? 'Documento pronto para impressão e envio.' : 'Gere a OP para iniciar a produção.' }}
                        </div>
                    </div>

                    <v-btn
                        size="large"
                        color="primary"
                        :variant="isLightMode ? 'flat' : 'flat'"
                        prepend-icon="mdi-printer"
                        class="font-weight-bold px-6"
                        :loading="isGeneratingPdf"
                        @click="generateOpPdf(focusedItem)"
                    >
                        {{ focusedItem.is_op_generated ? 'Reimprimir OP' : 'Gerar OP' }}
                    </v-btn>
                </div>

                <div v-if="order.details?.stamp_details" class="mt-6 pa-4 rounded-lg border border-warning-subtle bg-warning-surface">
                    <div class="d-flex align-center gap-2 mb-2 text-warning">
                        <v-icon size="small">mdi-comment-alert-outline</v-icon>
                        <span class="text-caption font-weight-bold text-uppercase">Observações</span>
                    </div>
                    <p class="text-body-2 mb-0 opacity-90" :class="isLightMode ? 'text-grey-darken-3' : 'text-white'">
                        {{ order.details.stamp_details }}
                    </p>
                </div>

            </div>
        </div>

      </div>
    </v-card>

    <v-dialog v-model="showZoom" max-width="95vw" max-height="95vh" class="zoom-dialog">
        <div class="position-relative d-flex align-center justify-center bg-black h-100 rounded-lg overflow-hidden">
            <v-btn icon="mdi-close" variant="tonal" color="white" class="position-absolute top-0 right-0 ma-4 z-20" @click="showZoom = false"></v-btn>
            <v-img :src="zoomedImage" max-height="90vh" max-width="90vw" contain></v-img>
        </div>
    </v-dialog>

  </v-dialog>
</template>

<script setup lang="ts">
import { ref, watch, computed } from 'vue';
import { supabase } from '@/api/supabase';
import { format, parseISO, addDays } from 'date-fns';
import { ptBR } from 'date-fns/locale';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import { useThemeStore } from '@/stores/theme';

const props = defineProps({
  show: Boolean,
  orderId: String,
  itemId: String,
});
const emit = defineEmits(['close']);

const themeStore = useThemeStore();
const isLightMode = computed(() => themeStore.currentMode === 'light');

const order = ref<any | null>(null);
const loading = ref(false);
const error = ref<string | null>(null);
const isGeneratingPdf = ref(false);
const showZoom = ref(false);
const zoomedImage = ref('');
const localFocusedId = ref<string | null>(null);

// --- Computed Logic ---
const focusedItem = computed(() => {
    if (!order.value?.order_items) return null;
    const targetId = localFocusedId.value || props.itemId;
    if (targetId) return order.value.order_items.find((i: any) => i.id === targetId);
    return order.value.order_items[0]; // Fallback to first
});

const totalMeters = computed(() => {
    if (!order.value?.order_items) return 0;
    return order.value.order_items.reduce((sum: number, i: any) => sum + (i.quantity_meters || 0), 0);
});

// --- Actions ---
const selectItem = (item: any) => {
    localFocusedId.value = item.id;
};

const openZoom = (item: any) => {
    if (!item.stamp_image_url) return;
    zoomedImage.value = item.stamp_image_url;
    showZoom.value = true;
};

const downloadImage = async (url: string, name: string) => {
    try {
        const response = await fetch(url, { mode: 'cors', cache: 'no-store' });
        if (!response.ok) throw new Error('Network response was not ok');
        const blob = await response.blob();
        const link = document.createElement('a');
        link.href = URL.createObjectURL(blob);
        link.download = `${name.replace(/\s+/g, '_')}.png`;
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
    } catch (e) {
        console.warn('CORS Blocked or Error, opening in new tab', e);
        window.open(url, '_blank');
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

// --- PDF Logic (Ported from ReleaseOrderModal) ---
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
    // Return transparent pixel or placeholder if fails
    return 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';
  }
};

const generateOpPdf = async (item: any) => {
  if (!order.value) return;
  isGeneratingPdf.value = true;
  try {
    const { data: opNumber, error: rpcError } = await supabase.rpc("generate_op_number", { p_item_id: item.id });
    if (rpcError) throw rpcError;

    // Fetch Schedule if exists, else today
    const { data: schedule } = await supabase.from("production_schedule").select("scheduled_date").eq("order_item_id", item.id).maybeSingle();
    const scheduleDate = (schedule && schedule.scheduled_date) ? parseISO(schedule.scheduled_date) : new Date();

    const hasStockIssues = item.has_insufficient_stock; // Simplified check for item
    const extraDays = hasStockIssues ? 2 : 0;
    const completionDate = addBusinessDays(scheduleDate, 3 + extraDays);
    const forecastDate = getNextDeliveryDay(completionDate);

    const formattedOpNumber = String(opNumber).padStart(4, "0");
    const formattedForecastDate = format(forecastDate, "dd/MM/yyyy", { locale: ptBR });
    const formattedOrderNumber = String(order.value.order_number).padStart(4, "0");

    const doc = new jsPDF();

    const [logoBase64, artBase64] = await Promise.all([
      imageToBase64("https://cdn.shopify.com/s/files/1/0661/4574/6991/files/Sem_nome_1080_x_800_px_1080_x_500_px_1080_x_400_px_1000_x_380_px_da020cf2-2bb9-4dac-8dd3-4548cfd2e5ae.png?v=1756811713"),
      imageToBase64(item.stamp_image_url || ""),
    ]);

    const drawHeader = (w: number) => {
        const logoProps = doc.getImageProperties(logoBase64);
        const logoWidth = 50;
        const logoHeight = (logoProps.height * logoWidth) / logoProps.width;
        doc.addImage(logoBase64, "PNG", 15, 12, logoWidth, logoHeight);
        doc.setFontSize(9).setTextColor(100);
        doc.text(["MR JACKY - 20.631.721/0001-07", "RUA LUIZ MONTANHAN, 1302 TIRO DE GUERRA", "Fone: (15) 99847-8789"], w - 15, 15, { align: "right" });
    }

    const drawPage = (title: string) => {
        const w = doc.internal.pageSize.width;
        const h = doc.internal.pageSize.height;
        drawHeader(w);

        doc.setFontSize(10).setFont('helvetica', 'bold').setTextColor(0, 0, 0);
        doc.text(title, w / 2, 40, { align: "center" });

        doc.setFontSize(18).setTextColor(0);
        doc.text(`OP #${formattedOpNumber}`, 15, 45);
        doc.setFontSize(12);
        doc.text(`Pedido #${formattedOrderNumber}`, w - 15, 45, { align: "right" });
        doc.setLineWidth(0.5).line(15, 50, w - 15, 50);

        autoTable(doc, {
            startY: 55,
            head: [["CLIENTE", "VENDEDOR", "EMISSÃO", "PREVISÃO"]],
            body: [[ order.value.customer_name, order.value.profiles?.full_name || "N/A", format(new Date(order.value.created_at), "dd/MM/yyyy", { locale: ptBR }), formattedForecastDate ]],
            theme: "striped", headStyles: { fillColor: [41, 128, 185] },
        });

        autoTable(doc, {
            startY: (doc as any).lastAutoTable.finalY + 10,
            head: [["PRODUTO (BASE)", "SERVIÇO (ESTAMPA)", "QUANTIDADE"]],
            body: [[item.fabric_type, item.stamp_ref, `${item.quantity_meters}m`]],
            theme: "grid", headStyles: { fillColor: [41, 128, 185] },
        });

        const artY = (doc as any).lastAutoTable.finalY + 15;
        doc.setFontSize(12).setFont("helvetica", "bold").text("ARTE APROVADA", 15, artY);

        const maxImgH = h - artY - 25;
        const imgProps = doc.getImageProperties(artBase64);
        const ratio = Math.min((w - 30) / imgProps.width, maxImgH / imgProps.height);
        const imgW = imgProps.width * ratio;
        const imgH = imgProps.height * ratio;
        const imgX = (w - imgW) / 2;

        doc.setDrawColor(200); doc.rect(imgX - 1, artY + 5 - 1, imgW + 2, imgH + 2);
        doc.addImage(artBase64, "PNG", imgX, artY + 5, imgW, imgH);
    };

    drawPage("VIA DA PRODUÇÃO");
    doc.addPage();
    drawPage("VIA PARA ARQUIVAMENTO");

    doc.save(`OP-${formattedOpNumber}-${item.stamp_ref}.pdf`);
  } catch (e: any) {
    alert(`Erro ao gerar PDF: ${e.message}`);
  } finally {
    isGeneratingPdf.value = false;
  }
};

// --- Data Fetching ---
const fetchOrder = async (id: string) => {
  loading.value = true;
  error.value = null;
  try {
    const { data, error: err } = await supabase
      .from('orders')
      .select('*, profiles:created_by (full_name), stores (name), order_items(*, has_insufficient_stock)')
      .eq('id', id)
      .single();
    if (err) throw err;
    order.value = data;
    // Set focus if not set or if current focus not in new data
    if (!localFocusedId.value || !data.order_items.some((i:any) => i.id === localFocusedId.value)) {
        localFocusedId.value = props.itemId || data.order_items?.[0]?.id || null;
    }
  } catch (e: any) {
    error.value = e.message;
  } finally {
    loading.value = false;
  }
};

// --- Helpers ---
const getItemDisplay = (item: any) => {
    if (item.has_insufficient_stock) return { text: 'Estoque Baixo', color: 'warning', icon: 'mdi-alert-octagon' };
    const map: any = {
        'production_queue': { text: 'Fila', color: 'indigo', icon: 'mdi-timer-sand' },
        'in_printing': { text: 'Produção', color: 'blue', icon: 'mdi-printer' },
        'in_cutting': { text: 'Corte', color: 'cyan', icon: 'mdi-scissors-cutting' },
        'completed': { text: 'Finalizado', color: 'teal', icon: 'mdi-check-circle' },
    };
    return map[item.status] || { text: item.status, color: 'grey', icon: 'mdi-circle-small' };
};

const formatMeters = (v: number) => Number(v || 0).toLocaleString('pt-BR', { maximumFractionDigits: 1 });
const formatDate = (d: string) => d ? format(parseISO(d), 'dd/MM/yyyy') : '-';

watch(() => props.show, (val) => {
    if (val && props.orderId) {
        fetchOrder(props.orderId);
    }
});
watch(() => props.itemId, (newId) => {
    if (newId) localFocusedId.value = newId;
});
</script>

<style scoped lang="scss">
/* THEME VARIABLES & BASE */
.order-modal-card {
  background-color: #121212;
  color: white;
  border-radius: 12px !important;
  border: 1px solid rgba(255, 255, 255, 0.1);

  &.light-mode {
      background-color: #FFFFFF;
      color: #333;
      border: none;
  }
}

/* SIDEBAR */
.details-sidebar {
    width: 320px;
    @media (max-width: 960px) { width: 100%; height: auto; border-right: none; border-bottom: 1px solid rgba(255,255,255,0.1); }
}

.item-nav-card {
    border: 1px solid transparent;
    &:hover { transform: translateX(4px); }
    &.ring-active { box-shadow: 0 0 0 2px rgba(var(--v-theme-primary), 0.3); }
}

/* MAIN CONTENT */
.main-stage { position: relative; }

.hero-section {
    background-color: #000;
    .bg-pattern { opacity: 0.8; }
}

.gradient-overlay {
    background: linear-gradient(to top, rgba(0,0,0,0.8), transparent);
}

.icon-circle-lg {
    width: 48px; height: 48px; border-radius: 50%;
    display: flex; align-items: center; justify-content: center;
}

.bg-primary-gradient { background: linear-gradient(135deg, rgb(var(--v-theme-primary)), #1565c0); }
.bg-primary-surface { background: rgba(var(--v-theme-primary), 0.15); }
.bg-surface-card { background: rgba(255,255,255,0.03); }
.bg-header-dark { background-color: #1e1e24; }
.bg-surface-sidebar { background-color: #18181b; }
.bg-surface-body { background-color: #121212; }
.bg-warning-surface { background: rgba(255, 193, 7, 0.1); }

.border-white-05 { border-color: rgba(255,255,255,0.05) !important; }
.border-warning-subtle { border-color: rgba(255, 193, 7, 0.3) !important; }

/* TYPOGRAPHY & UTILS */
.info-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; }
.specs-grid { grid-template-columns: repeat(auto-fit, minmax(140px, 1fr)); }
.label { font-size: 10px; text-transform: uppercase; font-weight: 700; opacity: 0.6; margin-bottom: 2px; }
.value { font-size: 13px; font-weight: 600; }
.gap-2 { gap: 8px; } .gap-3 { gap: 12px; } .gap-4 { gap: 16px; }
.lh-1 { line-height: 1.2; }

/* SCROLLBARS */
.custom-scrollbar::-webkit-scrollbar { width: 6px; }
.custom-scrollbar::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.3); border-radius: 3px; }
.light-mode .custom-scrollbar::-webkit-scrollbar-thumb { background: rgba(0,0,0,0.2); }
</style>
