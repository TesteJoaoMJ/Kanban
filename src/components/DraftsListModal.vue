<template>
  <v-dialog
    :model-value="show"
    @update:model-value="$emit('close')"
    max-width="1300px"
    height="90vh"
    scrollable
    transition="dialog-bottom-transition"
    content-class="fixed-dialog"
  >
    <v-card class="fill-height d-flex flex-row overflow-hidden rounded-xl shadow-lg" :class="themeClass">

      <div class="d-flex flex-column border-r" :class="sidebarClass" style="width: 280px; min-width: 280px;">
        <div class="pa-6 pb-4">
           <div class="d-flex align-center gap-3 mb-8">
              <div class="bg-primary pa-3 d-flex align-center justify-center rounded-lg shadow-sm" style="width: 48px; height: 48px;">
                 <v-icon size="24" color="white">mdi-notebook-edit-outline</v-icon>
              </div>
              <div>
                 <div class="text-[10px] font-weight-black text-uppercase opacity-60 letter-spacing-1">Gerenciador</div>
                 <h2 class="text-h6 font-weight-black leading-none" :class="textPrimaryClass">Rascunhos</h2>
              </div>
           </div>

           <div class="d-flex flex-column gap-3">
              <v-card
                class="kpi-card kpi-rect bg-gradient-info py-3 px-4 rounded-lg shadow-sm"
                elevation="0"
              >
                 <div class="kpi-bg-icon"><v-icon>mdi-folder-open</v-icon></div>
                 <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                    <div class="d-flex align-center gap-2 mb-1">
                       <v-icon size="16" class="opacity-80 text-white">mdi-folder-multiple-outline</v-icon>
                       <span class="kpi-label text-white">Rascunhos Salvos</span>
                    </div>
                    <div class="text-h4 font-weight-black text-white mt-1">{{ drafts.length }}</div>
                    <div class="kpi-footer text-white mt-1 opacity-80">Total em Memória</div>
                 </div>
              </v-card>

              <v-card
                class="kpi-card kpi-rect bg-gradient-green py-3 px-4 rounded-lg shadow-sm"
                elevation="0"
              >
                 <div class="kpi-bg-icon"><v-icon>mdi-check-decagram</v-icon></div>
                 <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                    <div class="d-flex align-center gap-2 mb-1">
                       <v-icon size="16" class="opacity-80 text-white">mdi-check-circle-outline</v-icon>
                       <span class="kpi-label text-white">Prontos p/ Lançar</span>
                    </div>
                    <div class="text-h4 font-weight-black text-white mt-1">{{ launchableCount }}</div>
                    <div class="kpi-footer text-white mt-1 opacity-80">Estoque Disponível</div>
                 </div>
              </v-card>
           </div>
        </div>

        <div class="mt-auto pa-5 border-t" :class="borderColorClass">
           <v-btn block variant="flat" class="font-weight-bold text-caption rounded-lg" color="red-darken-1" :disabled="drafts.length === 0" @click="confirmClearAll" height="44">
              <v-icon start size="18">mdi-delete-sweep</v-icon> Limpar Todos
           </v-btn>
        </div>
      </div>

      <div class="flex-grow-1 d-flex flex-column relative" :class="isLight ? 'bg-white' : 'bg-glass-dark'" style="min-width: 0;">

         <div class="px-6 py-3 border-b d-flex align-center justify-space-between flex-shrink-0" :class="headerClass" style="height: 64px;">
            <div class="d-flex align-center gap-2">
                <span class="text-subtitle-1 font-weight-black" :class="textPrimaryClass">Lista de Rascunhos</span>
            </div>

            <div class="d-flex align-center gap-4">
                <div class="search-wrap rounded-lg d-flex align-center" :class="isLight ? 'search-light' : 'search-dark'" style="width: 280px; height: 40px;">
                    <v-icon size="18" :color="isLight ? 'grey-darken-1' : 'white-70'">mdi-magnify</v-icon>
                    <input
                        v-model="search"
                        placeholder="Pesquisar rascunho..."
                        class="clean-input flex-grow-1 text-caption font-weight-bold ml-2"
                    />
                </div>
                <v-btn icon variant="text" class="rounded-lg" color="grey" @click="$emit('close')">
                    <v-icon>mdi-close</v-icon>
                </v-btn>
            </div>
         </div>

         <div class="flex-grow-1 overflow-hidden d-flex flex-column bg-grey-lighten-4" :class="isLight ? 'bg-grey-lighten-4' : 'bg-transparent'">
            <v-card class="flex-grow-1 d-flex flex-column rounded-0 border-0" :elevation="0" :class="isLight ? 'bg-white' : 'bg-transparent'">
                <div class="grid-scroll flex-grow-1 overflow-y-auto overflow-x-hidden custom-scroll relative">

                    <div class="grid-header sticky-head grid-items-layout" :class="isLight ? 'grid-surface-light' : 'grid-surface-dark'">
                        <div class="cell center header-text">#</div>
                        <div class="cell center header-text">Ref.</div>
                        <div class="cell header-text">Nome do Rascunho</div>
                        <div class="cell header-text">Cliente</div>
                        <div class="cell center header-text">Qtd</div>
                        <div class="cell center header-text">Data</div>
                        <div class="cell center header-text">Status</div>
                        <div class="cell center header-text">Ações</div>
                    </div>

                    <div v-if="filteredDrafts.length === 0" class="d-flex flex-column justify-center align-center h-100 opacity-40 py-12">
                       <v-icon size="64" color="grey-lighten-1" class="mb-3">mdi-file-hidden-outline</v-icon>
                       <div class="text-subtitle-1 font-weight-black text-uppercase text-grey">Nenhum rascunho salvo</div>
                    </div>

                    <template v-for="(draft, idx) in filteredDrafts" :key="draft.id">
                        <div
                            class="grid-row cursor-pointer transition-colors grid-items-layout group"
                            :class="[
                                isLight ? 'grid-row-light' : 'grid-row-dark',
                                zebraClass(idx),
                                expandedId === draft.id ? 'grid-selected-light border-l-4 border-l-primary' : ''
                            ]"
                            @click="toggleExpand(draft.id)"
                        >
                            <div class="cell center font-weight-bold text-[11px] opacity-60">{{ idx + 1 }}</div>

                            <div class="cell center">
                                <span class="pill-ref" :class="isLight ? 'bg-grey-lighten-3 text-grey-darken-3' : 'bg-grey-darken-3 text-white'">
                                    {{ String(draft.data.order_number || 'N/A').padStart(4, '0') }}
                                </span>
                            </div>

                            <div class="cell d-flex align-center">
                                <v-icon size="16" class="mr-2 opacity-40 transition-transform" :class="{'rotate-90 text-primary opacity-100': expandedId === draft.id}">
                                    mdi-chevron-right
                                </v-icon>
                                <span class="list-text-main font-weight-bold text-uppercase text-truncate" :class="textPrimaryClass">
                                    {{ draft.name }}
                                </span>
                            </div>

                            <div class="cell">
                                <div class="text-truncate list-text-sub font-weight-medium opacity-80" :class="textPrimaryClass">
                                    {{ getClientName(draft.originalDraft) }}
                                </div>
                            </div>

                            <div class="cell center">
                                <span class="font-mono font-weight-black text-[12px]" :class="textPrimaryClass">
                                    {{ draft.data.orderItems.length }}
                                </span>
                                <span class="text-[9px] opacity-60 ml-1">Itens</span>
                            </div>

                            <div class="cell center">
                                <span class="text-[11px] font-weight-bold text-uppercase opacity-70" :class="textPrimaryClass">
                                    {{ formatTimeAgo(draft.createdAt) }}
                                </span>
                            </div>

                            <div class="cell center">
                                <span class="solid-chip" :class="draft.isLaunchable ? 'chip-success' : 'chip-warning'">
                                    {{ draft.isLaunchable ? 'OK' : 'PEND' }}
                                </span>
                            </div>

                            <div class="cell center" @click.stop>
                                <div class="actions-inline">
                                    <v-tooltip text="Carregar Rascunho" location="top" content-class="bg-black font-weight-bold text-[10px]">
                                        <template v-slot:activator="{ props }">
                                            <v-btn v-bind="props" icon size="small" class="action-btn action-load" variant="flat" @click.stop="$emit('load', draft.originalDraft)">
                                                <v-icon size="16">mdi-upload</v-icon>
                                            </v-btn>
                                        </template>
                                    </v-tooltip>

                                    <v-tooltip text="Clonar Rascunho" location="top" content-class="bg-blue-darken-4 font-weight-bold text-[10px]">
                                        <template v-slot:activator="{ props }">
                                            <v-btn v-bind="props" icon size="small" class="action-btn action-clone" variant="flat" :loading="isCloning === draft.id" @click.stop="handleCloneDraft(draft.originalDraft)">
                                                <v-icon size="16">mdi-content-copy</v-icon>
                                            </v-btn>
                                        </template>
                                    </v-tooltip>

                                    <v-tooltip text="Ver PDF" location="top" content-class="bg-black font-weight-bold text-[10px]">
                                        <template v-slot:activator="{ props }">
                                            <v-btn v-bind="props" icon size="small" class="action-btn action-view" variant="flat" :loading="isGeneratingPdf" @click.stop="handlePreview(draft.originalDraft)">
                                                <v-icon size="16">mdi-file-pdf-box</v-icon>
                                            </v-btn>
                                        </template>
                                    </v-tooltip>

                                    <v-tooltip v-if="hasDownPayment(draft)" text="Gerar Recibo" location="top" content-class="bg-black font-weight-bold text-[10px]">
                                        <template v-slot:activator="{ props }">
                                            <v-btn v-bind="props" icon size="small" class="action-btn action-receipt" variant="flat" :loading="isGeneratingReceipt === draft.id" @click.stop="handleGenerateDraftReceipt(draft)">
                                                <v-icon size="16">mdi-receipt-text</v-icon>
                                            </v-btn>
                                        </template>
                                    </v-tooltip>

                                    <v-tooltip text="Excluir" location="top" content-class="bg-red-darken-4 font-weight-bold text-[10px]">
                                        <template v-slot:activator="{ props }">
                                            <v-btn v-bind="props" icon size="small" class="action-btn action-del" variant="flat" @click.stop="$emit('delete', draft.id)">
                                                <v-icon size="16">mdi-trash-can-outline</v-icon>
                                            </v-btn>
                                        </template>
                                    </v-tooltip>
                                </div>
                            </div>
                        </div>

                        <v-expand-transition>
                            <div v-if="expandedId === draft.id" class="details-row border-b" :class="isLight ? 'bg-blue-grey-lighten-5' : 'bg-grey-darken-4'">
                                <div class="pa-4 pl-12">
                                    <div class="d-flex align-center justify-space-between mb-3">
                                        <div class="d-flex align-center gap-2">
                                            <v-icon size="16" color="primary">mdi-format-list-checks</v-icon>
                                            <span class="text-[11px] font-weight-black text-uppercase opacity-70" :class="textPrimaryClass">Itens no Rascunho</span>
                                        </div>
                                        <v-btn size="small" variant="text" color="warning" class="font-weight-bold" @click="debugDraftStructure(draft.originalDraft)">
                                            <v-icon start size="16">mdi-bug</v-icon> Debug Data
                                        </v-btn>
                                    </div>

                                    <div class="rounded-lg border overflow-hidden" :class="isLight ? 'bg-white' : 'bg-surface-variant'">
                                        <div class="d-flex py-2 px-4 text-[10px] font-weight-black text-uppercase opacity-70 border-b" :class="isLight ? 'bg-grey-lighten-4' : 'bg-grey-darken-3'">
                                            <div style="flex: 1">Produto / Tecido</div>
                                            <div style="width: 200px">Estampa / Referência</div>
                                            <div style="width: 100px" class="text-right">Quantidade</div>
                                        </div>
                                        <div v-for="(item, i) in draft.data.orderItems" :key="i" class="d-flex py-2 px-4 border-b text-[12px] transition-colors" :class="isLight ? 'hover-grey' : 'hover-grey-dark'">
                                            <div style="flex: 1" class="font-weight-bold" :class="isLight ? 'text-grey-darken-3' : 'text-white'">
                                                {{ item.fabric_type || 'Produto Diverso' }}
                                            </div>
                                            <div style="width: 200px" class="text-caption opacity-80 text-truncate">{{ item.stamp_ref || '-' }}</div>
                                            <div style="width: 100px" class="text-right font-mono font-weight-bold">{{ item.quantity }}</div>
                                        </div>
                                        <div v-if="(!draft.data.orderItems || draft.data.orderItems.length === 0)" class="pa-4 text-center text-caption italic opacity-50">
                                            Nenhum item adicionado à lista.
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </v-expand-transition>
                    </template>
                </div>
            </v-card>
         </div>
      </div>
    </v-card>
  </v-dialog>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue';
import { formatDistanceToNow, format } from 'date-fns';
import { ptBR } from 'date-fns/locale';
import { useThemeStore } from '@/stores/theme';
import { useOrderPDF } from '@/composables/useOrderPDF';
import { useUserStore } from '@/stores/user';
import { useAppStore } from '@/stores/app';
import { supabase } from '@/api/supabase';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import QRCode from 'qrcode';

// --- TYPES ---
interface Draft {
  id: string;
  name: string;
  created_at: string;
  draft_data: any;
  reserved_order_number: number | null;
}

interface GestaoClickProduct {
    id: string;
    nome: string;
    estoque: number | string;
}

// --- PROPS & EMITS ---
const props = defineProps<{
  show: boolean;
  drafts: Draft[];
  products: GestaoClickProduct[];
  clientList?: any[];
  paymentMethods?: any[];
}>();

const emit = defineEmits(['close', 'load', 'delete', 'launch']);
const themeStore = useThemeStore();
const userStore = useUserStore();
const appStore = useAppStore();
const { previewQuotePdf, isGeneratingPdf } = useOrderPDF();
const search = ref('');
const isGeneratingReceipt = ref<string | null>(null);
const isCloning = ref<string | null>(null);
const expandedId = ref<string | null>(null);

const toggleExpand = (id: string) => {
    expandedId.value = expandedId.value === id ? null : id;
};

// --- THEME COMPUTED ---
const isLight = computed(() => themeStore.currentMode === 'light');
const themeClass = computed(() => isLight.value ? 'bg-white text-grey-darken-4' : 'bg-glass-dark text-white');
const sidebarClass = computed(() => isLight.value ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-glass-sidebar border-white-10');
const headerClass = computed(() => isLight.value ? 'bg-white border-grey-lighten-2' : 'bg-glass-header border-white-05');
const textPrimaryClass = computed(() => isLight.value ? 'text-grey-darken-4' : 'text-white');
const borderColorClass = computed(() => isLight.value ? 'border-grey-lighten-2' : 'border-white-10');

// Helper Zebrado
const zebraClass = (i:number) => themeStore.currentMode!=='light' ? (i%2===0?'zebra-dark-a':'zebra-dark-b') : (i%2===0?'zebra-light-a':'zebra-light-b');

// --- LOGIC ---
const checkStockForDraft = (draft: Draft): boolean => {
    if (!props.products || props.products.length === 0) return false;
    if (!draft.draft_data || !draft.draft_data.orderItems || draft.draft_data.orderItems.length === 0) return true;

    const stockMap = new Map<string, number>();
    props.products.forEach(p => stockMap.set(p.nome, parseFloat(p.estoque as string) || 0));

    const requiredStock = new Map<string, number>();
    draft.draft_data.orderItems.forEach((item: any) => {
        if (item.fabric_type) {
            const currentRequired = requiredStock.get(item.fabric_type) || 0;
            requiredStock.set(item.fabric_type, currentRequired + (item.quantity || 0));
        }
    });

    for (const [fabric, required] of requiredStock.entries()) {
        const available = stockMap.get(fabric) || 0;
        if (required > available) return false;
    }
    return true;
};

const draftsWithStatus = computed(() => {
    if (!props.drafts) return [];
    return props.drafts.map(draft => {
        const compatibleData = {
            order_number: draft.reserved_order_number,
            orderItems: draft.draft_data?.orderItems || []
        };
        return {
            id: draft.id,
            name: draft.name,
            createdAt: draft.created_at,
            data: compatibleData,
            isLaunchable: checkStockForDraft(draft),
            originalDraft: draft
        };
    }).sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());
});

const filteredDrafts = computed(() => {
    if (!search.value) return draftsWithStatus.value;
    const q = search.value.toLowerCase();
    return draftsWithStatus.value.filter(d =>
        d.name.toLowerCase().includes(q) ||
        String(d.data.order_number).includes(q) ||
        getClientName(d.originalDraft).toLowerCase().includes(q)
    );
});

const launchableCount = computed(() => draftsWithStatus.value.filter(d => d.isLaunchable).length);

const formatTimeAgo = (dateStr: string) => {
    return formatDistanceToNow(new Date(dateStr), { addSuffix: true, locale: ptBR });
};

// --- HELPER FUNCTIONS ---
const findDeepKey = (obj: any, key: string, maxDepth = 5, currentDepth = 0): any => {
    if (!obj || typeof obj !== 'object' || currentDepth > maxDepth) return undefined;
    if (Object.prototype.hasOwnProperty.call(obj, key)) return obj[key];
    for (const k in obj) {
        if (Object.prototype.hasOwnProperty.call(obj, k) && typeof obj[k] === 'object') {
             const result = findDeepKey(obj[k], key, maxDepth, currentDepth + 1);
             if (result !== undefined) return result;
        }
    }
    return undefined;
};

const getClientName = (draft: any) => {
    const name = findDeepKey(draft.draft_data, 'customer_name');
    if (name) return name;
    const id = findDeepKey(draft.draft_data, 'customer_id');
    if (id && props.clientList) {
        const client = props.clientList.find((c: any) => c.id === id);
        if (client) return client.nome;
    }
    return 'Cliente não selecionado';
};

const handlePreview = (draft: any) => {
    const clientName = getClientName(draft);
    const sellerName = userStore.profile?.full_name || 'Vendedor';
    previewQuotePdf(draft.draft_data, clientName, sellerName);
};

const confirmClearAll = () => {
    if (confirm('Atenção: Isso apagará TODOS os seus rascunhos. Deseja continuar?')) {
       // O componente pai precisa interceptar e apagar, ou emite um evento especifico:
       // emit('deleteAll'); (Apenas simulando comportamento que existia)
    }
};

const debugDraftStructure = (draft: any) => {
    console.log(draft);
    appStore.showSnackbar("Dados impressos no Console (F12)", "info");
};

// --- CLONE LOGIC ---
const handleCloneDraft = async (draft: any) => {
    const newName = prompt('Nome para o novo rascunho clonado:', `${draft.name} (Cópia)`);
    if (!newName) return;

    isCloning.value = draft.id;
    try {
        const { data: nextNumber, error: numError } = await supabase.rpc('get_next_order_number');
        const newOrderNumber = numError ? Date.now() : nextNumber;

        // Zera cabeçalho e pagamentos, mantendo exclusivamente a lista de itens
        const newDraftData = {
            orderHeader: {
                customer_id: null,
                customer_name: '',
                vendedor_id: userStore.user?.id,
                observation: ''
            },
            orderItems: JSON.parse(JSON.stringify(draft.draft_data?.orderItems || [])).map((item: any) => {
                item.status = 'design_pending';
                return item;
            }),
            paymentDetails: {
                entry_value: 0,
                entry_method_id: null,
                installment_payment_method_id: null,
                type: 'vista',
                installments: [],
                installments_count: 1,
                installments_interval: 30,
                first_due_date: format(new Date(), 'yyyy-MM-dd'),
                downPayments: [],
                generatePix: true
            }
        };

        const payload = {
            user_id: userStore.profile?.id,
            name: newName,
            draft_data: newDraftData,
            reserved_order_number: newOrderNumber
        };

        const { data, error } = await supabase.from('order_drafts').insert(payload).select().single();
        if (error) throw error;

        appStore.showSnackbar('Rascunho clonado com sucesso!', 'success');
        // Insere o novo rascunho visualmente direto na prop
        props.drafts.unshift(data);

    } catch (e: any) {
        appStore.showSnackbar('Erro ao clonar: ' + e.message, 'error');
    } finally {
        isCloning.value = null;
    }
};


// --- RECIBO LOGIC ---
const parseMoneySafe = (value: any): number => {
  if (value === null || value === undefined || value === '') return 0;
  if (typeof value === 'number') return value;
  const strVal = String(value).trim();
  if (strVal.includes(',') && !strVal.toLowerCase().includes('e')) {
     const normalized = strVal.replace(/\./g, '').replace(',', '.');
     return parseFloat(normalized) || 0;
  }
  return parseFloat(strVal) || 0;
};

const hasDownPayment = (draftWrapper: any) => {
    const draft = draftWrapper.originalDraft;
    const downPayments = findDeepKey(draft.draft_data, 'downPayments');
    if (Array.isArray(downPayments) && downPayments.length > 0) {
        const total = downPayments.reduce((acc: number, dp: any) => acc + (parseMoneySafe(dp.value) || 0), 0);
        if (total > 0) return true;
    }
    let rawVal = findDeepKey(draft.draft_data, 'entry_value');
    if (rawVal === undefined) rawVal = findDeepKey(draft.draft_data, 'sinal');
    if (rawVal === undefined) rawVal = findDeepKey(draft.draft_data, 'down_payment');
    return parseMoneySafe(rawVal) > 0;
};

const formatCurrency = (val: any) => new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(Number(val)||0);

const imageToBase64 = (urlOrFile: string | File): Promise<string> => new Promise((resolve, reject) => {
    const img = new Image();
    img.crossOrigin = 'Anonymous';
    img.onload = () => {
        const canvas = document.createElement('canvas');
        canvas.width = img.width;
        canvas.height = img.height;
        const ctx = canvas.getContext('2d');
        if (ctx) {
            ctx.drawImage(img, 0, 0);
            resolve(canvas.toDataURL('image/png'));
        } else {
            reject(new Error('Canvas context error'));
        }
    };
    img.onerror = reject;
    if (typeof urlOrFile === 'string') img.src = urlOrFile;
    else img.src = URL.createObjectURL(urlOrFile);
});

const addHeader = async (doc: jsPDF, orderNum: number | null | undefined, title: string, yOffset = 0) => {
    const pageWidth = doc.internal.pageSize.width;
    const margin = 15;
    try {
        const logoUrl = 'https://cdn.shopify.com/s/files/1/0661/4574/6991/files/Sem_nome_1080_x_800_px_1080_x_500_px_1080_x_400_px_1000_x_380_px_da020cf2-2bb9-4dac-8dd3-4548cfd2e5ae.png?v=1756811713';
        const logoBase64 = await imageToBase64(logoUrl);
        const logoProps = doc.getImageProperties(logoBase64);
        const logoWidth = 45;
        const logoHeight = (logoProps.height * logoWidth) / logoProps.width;
        doc.addImage(logoBase64, 'PNG', margin, 12 + yOffset, logoWidth, logoHeight);
    } catch (e) { }

    doc.setFont('helvetica', 'bold');
    doc.setFontSize(14);
    doc.text(title, pageWidth / 2, 20 + yOffset, { align: 'center' });
    if (orderNum) {
        doc.setFontSize(12);
        doc.setTextColor(0, 0, 0);
        doc.text(`Pedido / Romaneio Nº: ${String(orderNum).padStart(4, '0')}`, pageWidth / 2, 28 + yOffset, { align: 'center' });
    }
    doc.setFont('helvetica', 'normal');
    doc.setFontSize(8);
    doc.setTextColor(100);
    doc.text([
      "MATRIZ:",
      "MR JACKY - 20.631.721/0001-07",
      "R. Luiz Montanhan, 1302 - Tiete, SP",
      "Contato: (15) 99781-8102"
    ], pageWidth - margin, 15 + yOffset, { align: 'right' });
    doc.setLineWidth(0.5);
    doc.line(margin, 38 + yOffset, pageWidth - margin, 38 + yOffset);
};

const addFooter = (doc: jsPDF) => {
    const pageCount = (doc as any).internal.getNumberOfPages();
    const pageWidth = doc.internal.pageSize.width;
    const pageHeight = doc.internal.pageSize.height;
    doc.setFontSize(8).setTextColor(150);
    for (let i = 1; i <= pageCount; i++) {
        doc.setPage(i);
        doc.text(`Gerado com MJProcess em ${format(new Date(), 'dd/MM/yyyy HH:mm')}`, 15, pageHeight - 3);
        doc.text(`Página ${i} de ${pageCount}`, pageWidth - 15, pageHeight - 3, { align: 'right' });
    }
};

const addWatermark = async (doc: jsPDF) => {
    const totalPages = (doc as any).internal.getNumberOfPages();
    const pageWidth = doc.internal.pageSize.getWidth();
    const pageHeight = doc.internal.pageSize.getHeight();
    let logoBase64: string | null = null;
    try {
        const logoUrl = 'https://cdn.shopify.com/s/files/1/0661/4574/6991/files/Sem_nome_1080_x_800_px_1080_x_500_px_1080_x_400_px_1000_x_380_px_da020cf2-2bb9-4dac-8dd3-4548cfd2e5ae.png?v=1756811713';
        logoBase64 = await imageToBase64(logoUrl);
    } catch (e) { }

    for (let i = 1; i <= totalPages; i++) {
        doc.setPage(i);
        doc.saveGraphicsState();
        doc.setGState(new (doc as any).GState({ opacity: 0.08 }));
        if (logoBase64) {
            const logoProps = doc.getImageProperties(logoBase64);
            const logoWidth = pageWidth * 0.75;
            const logoHeight = (logoProps.height * logoWidth) / logoProps.width;
            doc.addImage(logoBase64, 'PNG', (pageWidth - logoWidth) / 2, (pageHeight - logoHeight) / 2, logoWidth, logoHeight);
        }
        doc.setGState(new (doc as any).GState({ opacity: 0.7 }));
        doc.setFont('helvetica', 'bold'); doc.setFontSize(18); doc.setTextColor(255, 150, 150);
        const text = 'recibo';
        const yStep = 50;
        for (let y = 25; y < pageHeight - 15; y += yStep) { doc.text(text, 6, y, { angle: 90 }); }
        for (let y = 25; y < pageHeight - 15; y += yStep) { doc.text(text, pageWidth - 6, y, { angle: -90 }); }
        doc.restoreGraphicsState();
    }
};

const addWarningsFooter = (doc: jsPDF, startY: number) => {
    const pageWidth = doc.internal.pageSize.width; const margin = 15; let currentY = startY;
    doc.setLineWidth(0.5); doc.setDrawColor(180, 180, 180); doc.line(margin, currentY, pageWidth - margin, currentY); currentY += 5;
    doc.setFontSize(9).setFont('helvetica', 'bold'); doc.text('Observações Importantes:', margin, currentY); currentY += 5;
    doc.setFontSize(8).setFont('helvetica', 'normal');
    const warnings = [
        '- Em caso de desistência o sinal não será devolvido.',
        '- Todos tecidos com processo de estamparia vem com em medidas de 1cm cada lado de ourela em branco.',
        '- Para pedidos pedimos 30% de sinal do valor total do pedido e o restante do pagamento será feito um dia antes da entrega!',
        '- Poderá haver variações:', '  - Nas cores do desenho 10% para mais ou para menos', '  - Nas quantidade MTS-KGS 15% para mais ou para menos'
    ];
    warnings.forEach(warning => { const lines = doc.splitTextToSize(warning, pageWidth - (margin * 2)); doc.text(lines, margin, currentY); currentY += (lines.length * 4); });
    return currentY;
};

const handleGenerateDraftReceipt = async (draftWrapper: any) => {
    const draft = draftWrapper.originalDraft;
    let amount = 0;
    let paymentMethod = 'Não informado';

    const downPayments = findDeepKey(draft.draft_data, 'downPayments');
    if (Array.isArray(downPayments) && downPayments.length > 0) {
        amount = downPayments.reduce((acc: number, dp: any) => acc + (parseMoneySafe(dp.value) || 0), 0);
        const lines = downPayments.map((dp: any) => {
            const val = parseMoneySafe(dp.value);
            if (val <= 0) return null;
            let mName = 'Sinal';
            if (props.paymentMethods) {
                const found = props.paymentMethods.find(pm => String(pm.id) === String(dp.method_id));
                if (found) mName = found.nome;
            } else if (dp.method_name) {
                mName = dp.method_name;
            }
            return `${formatCurrency(val)} (${mName})`;
        }).filter((l: any) => l !== null);

        if (lines.length > 0) paymentMethod = lines.join('\n');
    } else {
        let rawVal = findDeepKey(draft.draft_data, 'entry_value');
        if (rawVal === undefined) rawVal = findDeepKey(draft.draft_data, 'sinal');
        if (rawVal === undefined) rawVal = findDeepKey(draft.draft_data, 'down_payment');
        amount = parseMoneySafe(rawVal);
        const methodLegacy = findDeepKey(draft.draft_data, 'entry_method') || findDeepKey(draft.draft_data, 'forma_pagamento');
        if (methodLegacy) paymentMethod = methodLegacy;
    }

    if (amount <= 0) {
        appStore.showSnackbar('Este rascunho não possui valor de sinal válido.', 'warning');
        return;
    }

    isGeneratingReceipt.value = draftWrapper.id;

    try {
        const orderNum = draft.reserved_order_number;
        const clientName = getClientName(draft);
        const clientCpfCnpj = findDeepKey(draft.draft_data, 'customer_cpf_cnpj') || 'Não informado';
        const paymentTypeTitle = 'Sinal (Rascunho)';
        const pdfFileName = `Recibo_Sinal_${String(orderNum).padStart(4, '0')}.pdf`;

        const qrCodeContent = window.location.href;
        const qrCodeDataUrl = await QRCode.toDataURL(qrCodeContent, { width: 175, margin: 1 });

        const doc = new jsPDF('p', 'mm', 'a4');
        const pageWidth = doc.internal.pageSize.width; const pageHeight = doc.internal.pageSize.height;
        const midPointY = pageHeight / 2; const margin = 15;
        const orderNumberText = String(orderNum).padStart(4, '0');

        const introText = `A MR JACKY confirma o recebimento do valor descrito abaixo, referente a ${paymentTypeTitle} do Pedido de Venda nº ${orderNumberText}.`;
        const qrSize = 25; const qrGap = 5; const tableWidth = pageWidth - margin * 2 - qrSize - qrGap;

        const tableHead = [['Cliente', 'CPF/CNPJ', 'Valor Total', 'Detalhamento']];
        const tableBody = [[ clientName, clientCpfCnpj, formatCurrency(amount), paymentMethod ]];
        const dataDoPagamento = `Tiete, ${format(new Date(), "dd 'de' MMMM 'de' yyyy", { locale: ptBR })}.`;

        const generateViaContent = async (yOffset: number, viaTitle: string) => {
            await addHeader(doc, orderNum, `Recibo de ${paymentTypeTitle}`, yOffset);
            doc.setFontSize(8).setTextColor(150).text(viaTitle, pageWidth - margin, yOffset + 10, { align: 'right' });
            const startY = yOffset + 48;
            doc.setFontSize(10).setFont('helvetica', 'normal').setTextColor(0, 0, 0); doc.text(introText, margin, startY, { maxWidth: pageWidth - margin * 2 });
            const tableStartY = startY + 12; const qrX = margin + tableWidth + qrGap;

            autoTable(doc, {
                startY: tableStartY, head: tableHead, body: tableBody, theme: 'striped',
                headStyles: { fillColor: yOffset === 0 ? [220, 230, 250] : [70, 100, 200], textColor: yOffset === 0 ? 0 : [255, 255, 255], fontStyle: 'bold' },
                columnStyles: { 0: { cellWidth: 'auto' }, 1: { cellWidth: 40 }, 2: { cellWidth: 35, halign: 'right' }, 3: { cellWidth: 35 } },
                styles: { overflow: 'linebreak', cellPadding: 2 },
                tableWidth: tableWidth, margin: { left: margin },
            });
            doc.addImage(qrCodeDataUrl, 'PNG', qrX, tableStartY, qrSize, qrSize);
            doc.setFontSize(7).setTextColor(100).text('Validar', qrX + qrSize / 2, tableStartY + qrSize + 3, { align: 'center' });

            let finalY = (doc as any).lastAutoTable.finalY + 10;
            finalY = addWarningsFooter(doc, finalY);

            const signatureY = Math.min(finalY + 15, (yOffset === 0 ? midPointY : pageHeight) - 20);
            const signatureWidth = (pageWidth - margin * 3) / 2; const signatureX1 = margin; const signatureX2 = margin * 2 + signatureWidth;
            doc.setLineWidth(0.3).setDrawColor(0, 0, 0);
            doc.line(signatureX1, signatureY, signatureX1 + signatureWidth, signatureY); doc.setFontSize(9).setTextColor(0, 0, 0).text('MR JACKY', signatureX1 + signatureWidth / 2, signatureY + 5, { align: 'center' });
            doc.line(signatureX2, signatureY, signatureX2 + signatureWidth, signatureY); doc.setFontSize(9).setTextColor(0, 0, 0).text(clientName, signatureX2 + signatureWidth / 2, signatureY + 5, { align: 'center' });
            const dateY = signatureY + 15; doc.setFontSize(9).setFont('helvetica', 'normal').text(dataDoPagamento, pageWidth / 2, dateY, { align: 'center' });
        };

        await generateViaContent(0, 'Via da Empresa');
        doc.setLineDashPattern([2, 2], 0); doc.line(5, midPointY, pageWidth - 5, midPointY); doc.setLineDashPattern([], 0);
        doc.setFontSize(8).setTextColor(150).text('- - - - corte aqui - - - -', pageWidth / 2, midPointY - 1, { align: 'center' });
        await generateViaContent(midPointY, 'Via do Cliente');
        await addWatermark(doc); addFooter(doc);

        doc.save(pdfFileName);
        appStore.showSnackbar('Recibo gerado!', 'success');

    } catch (e: any) {
        console.error("PDF Error", e);
        appStore.showSnackbar("Erro PDF: " + e.message, "error");
    } finally {
        isGeneratingReceipt.value = null;
    }
};
</script>

<style scoped lang="scss">
/* FIXED MODAL STYLE */
.fixed-dialog { overflow: hidden !important; }

/* UTILS */
.lh-1 { line-height: 1; }
.gap-2 { gap: 8px; } .gap-3 { gap: 12px; } .gap-4 { gap: 16px; }
.leading-none { line-height: 1 !important; }
.border-thin { border: 1px solid rgba(0,0,0,0.08); }
.border-t-thin { border-top: 1px solid rgba(0,0,0,0.08); }

/* KPI CARDS */
.kpi-card { color: white; position: relative; min-height: 110px; overflow: hidden; }
.kpi-bg-icon { position: absolute; right: -20px; bottom: -20px; opacity: 0.15; transform: rotate(-15deg); }
.kpi-bg-icon .v-icon { font-size: 100px; color: white; }
.bg-gradient-info { background: linear-gradient(135deg, #0288d1, #005b9f); }
.bg-gradient-green { background: linear-gradient(135deg, #2e7d32, #1b5e20); }
.kpi-label { font-size: 12px; font-weight: 900; letter-spacing: .2px; }
.kpi-footer { font-size: 11px; opacity: .9; font-weight: 700; }

/* SEARCH BAR */
.search-wrap { border: 1px solid rgba(0,0,0,0.08); }
.search-light { background: #f4f6f8; }
.search-dark { background: rgba(255,255,255,0.08); border-color: rgba(255,255,255,0.10); }
.clean-input { border: none; outline: none; background: transparent; font-size: 12px; color: inherit; padding: 0; width: 100%; }

/* THEME & GLASS */
.bg-glass-dark { background: rgba(15, 15, 20, 0.95); }
.bg-glass-sidebar { background: rgba(25, 25, 30, 0.98); }
.bg-glass-header { background: rgba(20,20,24,0.55); backdrop-filter: blur(14px); }
.border-white-05 { border-bottom: 1px solid rgba(255,255,255,0.08); }
.border-white-10 { border-color: rgba(255, 255, 255, 0.1) !important; }

/* GRID SYSTEM CSS RÍGIDO */
.grid-items-layout {
    display: grid;
    align-items: stretch;
    width: 100%;
    grid-template-columns: 45px 80px minmax(100px, 1.5fr) minmax(120px, 2fr) 60px 100px 90px 160px; /* Aumentei de 140px pra 160px pra caber o botão */
    border-bottom: 1px solid rgba(0,0,0,0.08);
}

.cell {
    padding: 6px 8px;
    display: flex;
    align-items: center;
    border-right: 1px solid rgba(0,0,0,0.08);
    min-height: 54px;
    overflow: hidden;
    transition: background-color 0.2s ease;
}
.cell:last-child { border-right: none; }

.center { justify-content: center; text-align: center; }

.grid-header .cell {
    min-height: 44px;
    font-size: 12px;
    font-weight: 800;
    text-transform: uppercase;
    letter-spacing: 0.5px;
    line-height: 1.2;
}

.grid-surface-light .cell { background: #f5f7fa; color: rgba(0,0,0,0.9); }
.grid-surface-dark .cell { background: rgba(255,255,255,0.08); color: rgba(255,255,255,0.95); border-color: rgba(255,255,255,0.1) !important; }

/* Bordas suaves */
.grid-row-light .cell { border-color: rgba(0,0,0,0.08) !important; }
.grid-row-dark .cell { border-color: rgba(255,255,255,0.08) !important; }

/* Zebrado Forte Elegante */
.zebra-light-a .cell { background: #ffffff; }
.zebra-light-b .cell { background: #f0f4f8; }
.zebra-dark-a .cell { background: rgba(0,0,0,0.15); }
.zebra-dark-b .cell { background: rgba(255,255,255,0.03); }

/* Hover e Selection */
.grid-row-light:hover .cell { background: #e3f2fd !important; }
.grid-row-dark:hover .cell { background: rgba(255,255,255,0.12) !important; }
.grid-selected-light .cell { background: #e8f5e9 !important; }

/* CHIPS & ACTIONS */
.pill-ref { font-size: 11px; font-weight: 900; font-family: monospace; padding: 4px 6px; border-radius: 4px; white-space: nowrap; }
.solid-chip { display: inline-flex; align-items: center; justify-content: center; height: 24px; padding: 0 10px; border-radius: 4px; font-size: 10px; font-weight: 900; color: #fff; white-space: nowrap; text-transform: uppercase; }
.chip-success { background: #2e7d32; }
.chip-warning { background: #f57f17; }

.actions-inline { display: flex; align-items: center; justify-content: center; gap: 4px; }
.action-btn { width: 28px !important; height: 28px !important; border-radius: 6px !important; color: #fff !important; }
.action-load { background: #1976d2 !important; }
.action-view { background: #546e7a !important; }
.action-receipt { background: #00897b !important; }
.action-del { background: #c62828 !important; }
.action-clone { background: #0277bd !important; } /* Cor do botão de clonar */

/* TEXTS */
.list-text-main { font-size: 13px !important; line-height: 1.2 !important; }
.list-text-sub { font-size: 12px !important; line-height: 1.2 !important; }

/* HOVERS E TRANSITIONS */
.hover-grey:hover { background-color: #f5f5f5 !important; }
.hover-grey-dark:hover { background-color: rgba(255,255,255,0.05) !important; }
.rotate-90 { transform: rotate(90deg); }
.transition-transform { transition: transform 0.2s ease; }

/* SCROLL E STICKY */
.custom-scroll::-webkit-scrollbar { width: 8px; height: 8px; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.35); border-radius: 6px; }
.custom-scroll::-webkit-scrollbar-track { background: transparent; }
.sticky-head { position: sticky; top: 0; z-index: 10; box-shadow: 0 4px 10px rgba(0,0,0,0.05); }
.bg-glass-dark .sticky-head { box-shadow: 0 4px 12px rgba(0,0,0,0.3); }
</style>
