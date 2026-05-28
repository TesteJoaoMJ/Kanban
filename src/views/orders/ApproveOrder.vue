<template>
  <v-container fluid class="fill-height align-start pa-0 bg-background perspective-container">

    <div
      class="w-100 px-6 py-4 d-flex flex-column flex-md-row justify-space-between align-md-center transition-all position-relative z-index-50"
      :class="headerClasses"
      v-if="order"
    >
      <div class="d-flex align-center">
        <v-btn
          icon
          size="small"
          variant="text"
          class="mr-3"
          :color="isDark ? 'white' : 'grey-darken-3'"
          @click="$router.back()"
        >
          <v-icon>mdi-arrow-left</v-icon>
          <v-tooltip activator="parent" location="bottom">Voltar</v-tooltip>
        </v-btn>

        <div
          class="icon-box-md rounded-lg d-flex align-center justify-center mr-4 elevation-2"
          :class="isDark ? 'bg-gradient-primary glow-effect' : 'bg-white text-primary border-subtle'"
        >
          <v-icon :color="isDark ? 'white' : 'primary'" size="24">mdi-file-document-outline</v-icon>
        </div>

        <div>
          <div class="d-flex align-center gap-2 mb-1">
            <span class="text-ultra-caption font-weight-bold text-uppercase opacity-60 letter-spacing-1">
              Pedido #{{ String(order.order_number || '---').padStart(4, '0') }}
            </span>
            <v-icon size="10" class="opacity-40">mdi-chevron-right</v-icon>
            <span class="text-ultra-caption font-weight-bold opacity-60">
              {{ formatDate(order.created_at) }}
            </span>
          </div>
          <h1 class="text-h5 font-weight-black lh-1 text-truncate" :class="isDark ? 'text-white' : 'text-grey-darken-4'" style="max-width: 400px;">
            {{ order.customer_name }}
          </h1>

          <div class="d-flex align-center mt-1">
            <v-avatar size="16" class="mr-2 border-subtle">
              <v-img v-if="order.designer?.avatar_url" :src="order.designer.avatar_url" cover></v-img>
              <span v-else class="text-[9px] font-weight-bold bg-grey-lighten-3">{{ getDesignerInitials(order) }}</span>
            </v-avatar>
            <span class="text-ultra-caption text-medium-emphasis">
              Designer: <strong :class="isDark ? 'text-white' : 'text-grey-darken-3'">{{ getDesignerName(order) }}</strong>
            </span>
          </div>
        </div>
      </div>

      <div class="d-flex align-center mt-4 mt-md-0 gap-3">
        <div class="kpi-box d-flex align-center px-4 py-2 rounded-lg" :class="kpiClasses">
          <div class="text-right mr-3">
            <div class="text-[9px] font-weight-bold text-uppercase text-medium-emphasis">Total</div>
            <div class="text-h6 font-weight-black lh-1" :class="isDark ? 'text-white' : 'text-grey-darken-4'">
              {{ order.order_items.length }}
            </div>
          </div>
          <v-divider vertical class="h-24 opacity-20"></v-divider>
          <div class="text-right mx-3">
            <div class="text-[9px] font-weight-bold text-uppercase text-medium-emphasis">Pendentes</div>
            <div class="text-h6 font-weight-black text-warning lh-1">
              {{ itemsToApprove.length }}
            </div>
          </div>
          <v-divider vertical class="h-24 opacity-20"></v-divider>
          <div class="text-right ml-3">
            <div class="text-[9px] font-weight-bold text-uppercase text-medium-emphasis">Metragem</div>
            <div class="text-h6 font-weight-black text-success lh-1">
              {{ formatNumber(totalMetersPending) }}m
            </div>
          </div>
        </div>
      </div>
    </div>

    <div v-if="loading" class="d-flex justify-center align-center w-100 py-16">
       <v-progress-circular indeterminate color="primary" size="48" width="4"></v-progress-circular>
    </div>

    <v-col v-else-if="itemsToApprove.length === 0" cols="12" class="text-center py-16 opacity-70">
       <v-icon size="64" class="mb-4 text-success animate-bounce">mdi-check-decagram</v-icon>
       <h3 class="text-h6 font-weight-bold" :class="isDark ? 'text-white' : 'text-grey-darken-3'">Tudo avaliado!</h3>
       <p class="text-caption text-medium-emphasis">Redirecionando...</p>
    </v-col>

    <v-col v-else cols="12" class="pa-6 perspective-grid">
      <v-row>
        <v-col
          v-for="(item, index) in itemsToApprove"
          :key="item.id"
          cols="12" sm="6" md="4" lg="3" xl="2"
          class="pa-3"
        >
          <div class="card-3d-wrapper" :style="{ animationDelay: `${index * 0.15}s` }">
            <div
              class="glass-card-3d d-flex flex-column"
              :class="isDark ? 'dark-glass' : 'light-glass'"
            >
              <div class="card-glow" :class="isDark ? 'orange-glow' : 'yellow-glow'"></div>

              <div class="card-media position-relative flex-shrink-0" style="height: 240px;">
                <v-img
                  :src="item.stamp_image_url || '/placeholder.png'"
                  height="100%"
                  cover
                  class="align-end rounded-t-xl transition-transform"
                  gradient="to top, rgba(0,0,0,0.8), rgba(0,0,0,0) 60%"
                  @click="openImage(item.stamp_image_url)"
                  style="cursor: zoom-in;"
                >
                  <div class="pa-3 w-100 position-relative z-10">
                    <div class="d-flex align-center justify-space-between mb-1">
                      <v-chip size="x-small" color="white" variant="flat" class="font-weight-black text-black font-mono shadow-sm">
                        {{ item.stamp_ref }}
                      </v-chip>
                      <v-btn icon size="x-small" variant="text" color="white" class="glass-btn-icon">
                         <v-icon size="16">mdi-fullscreen</v-icon>
                      </v-btn>
                    </div>
                    <h3 class="text-h6 font-weight-black text-white text-shadow text-truncate">
                      {{ item.fabric_type }}
                    </h3>
                  </div>
                </v-img>
              </div>

              <div class="card-content flex-grow-1 d-flex flex-column pa-0">
                <div class="mj-zebra-list flex-grow-1">
                   <div class="d-flex align-center justify-space-between px-4 py-2 border-b-subtle">
                      <div class="d-flex align-center text-medium-emphasis">
                         <v-icon size="14" class="mr-2">mdi-ruler-square</v-icon>
                         <span class="text-ultra-body">Metragem</span>
                      </div>
                      <span class="text-ultra-body font-weight-bold font-mono">{{ formatNumber(item.quantity_meters) }}m</span>
                   </div>
                   <div class="d-flex align-center justify-space-between px-4 py-2">
                      <div class="d-flex align-center text-medium-emphasis">
                         <v-icon size="14" class="mr-2">mdi-format-paint</v-icon>
                         <span class="text-ultra-body">Variação</span>
                      </div>
                      <span class="text-ultra-body font-weight-bold text-truncate" style="max-width: 100px;">
                        {{ item.color_variant || 'Padrão' }}
                      </span>
                   </div>
                </div>
              </div>

              <div class="pa-3 border-t-subtle d-flex gap-2" :class="isDark ? 'bg-surface-lighten-1' : 'bg-grey-lighten-5'">
                 <v-btn
                    variant="outlined"
                    color="warning"
                    class="flex-grow-1 font-weight-bold text-capitalize letter-spacing-05 border-opacity-50"
                    height="32"
                    size="small"
                    @click="openRejectModal(item)"
                  >
                    <v-icon start size="14">mdi-pencil</v-icon> Ajustar
                  </v-btn>

                  <v-btn
                    color="success"
                    variant="flat"
                    class="flex-grow-1 font-weight-bold text-capitalize letter-spacing-05 elevation-2"
                    height="32"
                    size="small"
                    @click="approveItem(item)"
                  >
                    <v-icon start size="14">mdi-check</v-icon> Aprovar
                  </v-btn>
              </div>

            </div>
          </div>
        </v-col>
      </v-row>
    </v-col>

    <v-dialog v-model="showRejectModal" max-width="450px">
      <v-card class="rounded-lg overflow-hidden elevation-10" :class="isDark ? 'bg-surface-darker border-thin' : 'bg-white'">
        <div class="px-5 py-3 border-b-subtle d-flex align-center bg-warning-lighten-5">
           <v-icon color="warning" class="mr-3">mdi-comment-alert-outline</v-icon>
           <div>
              <h3 class="text-subtitle-2 font-weight-bold text-grey-darken-3 lh-1">Solicitar Ajuste</h3>
              <span class="text-[10px] text-grey-darken-1">Feedback para o designer</span>
           </div>
        </div>

        <v-card-text class="pa-5">
          <div class="d-flex align-center pa-2 rounded mb-4 border-subtle" :class="isDark ? 'bg-surface-lighten-1' : 'bg-grey-lighten-5'">
             <v-avatar rounded size="40" class="mr-3">
               <v-img :src="itemToReject?.stamp_image_url" cover></v-img>
             </v-avatar>
             <div>
                <div class="text-[10px] font-weight-bold text-uppercase opacity-60">Item</div>
                <div class="text-caption font-weight-bold">{{ itemToReject?.stamp_ref }} - {{ itemToReject?.fabric_type }}</div>
             </div>
          </div>

          <v-textarea
            v-model="rejectionComment"
            label="Motivo do ajuste"
            placeholder="Descreva o que precisa ser alterado..."
            variant="outlined"
            density="compact"
            color="warning"
            rows="3"
            auto-grow
            hide-details
            class="text-body-2"
          ></v-textarea>
        </v-card-text>

        <v-card-actions class="px-5 pb-5 pt-0">
          <v-spacer></v-spacer>
          <v-btn variant="text" size="small" @click="showRejectModal = false" class="text-none">Cancelar</v-btn>
          <v-btn
            color="warning"
            variant="flat"
            size="small"
            class="px-4 font-weight-bold text-none elevation-1"
            :disabled="!rejectionComment.trim()"
            @click="rejectItem"
          >
            Confirmar Ajuste
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <ImageModal :show="showImageModal" :image-url="selectedImageUrl" @close="showImageModal = false" />

  </v-container>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { supabase } from '@/api/supabase';
import { useUserStore } from '@/stores/user';
import { useTheme } from 'vuetify';
import { formatDistanceToNow } from 'date-fns';
import { ptBR } from 'date-fns/locale';
import ImageModal from '@/components/ImageModal.vue';

// --- TYPES ---
type OrderItem = {
  id: string; fabric_type: string; stamp_ref: string; quantity_meters: number;
  stamp_image_url: string; status: string; color_variant?: string;
};
type Order = {
  id: string; customer_name: string; created_at: string; order_number?: number;
  order_items: OrderItem[];
  designer?: { full_name: string; avatar_url?: string };
};

// --- STATE ---
const route = useRoute();
const router = useRouter();
const userStore = useUserStore();
const theme = useTheme();
const order = ref<Order | null>(null);
const loading = ref(true);
const orderId = route.params.id as string;

const showRejectModal = ref(false);
const itemToReject = ref<OrderItem | null>(null);
const rejectionComment = ref('');

const showImageModal = ref(false);
const selectedImageUrl = ref('');

// --- THEME ---
const isDark = computed(() => theme.global.current.value.dark);

const headerClasses = computed(() => isDark.value
  ? 'glass-panel border-b-0'
  : 'bg-white shadow-sm border-b-solid border-grey-lighten-2');

const kpiClasses = computed(() => isDark.value
  ? 'glass-panel border-white-05'
  : 'bg-grey-lighten-5 border-subtle');

// --- COMPUTED ---
const itemsToApprove = computed(() => {
  return order.value?.order_items.filter(item => item.status === 'customer_approval') || [];
});

const totalMetersPending = computed(() => {
    return itemsToApprove.value.reduce((sum, item) => sum + (Number(item.quantity_meters) || 0), 0);
});

// --- HELPERS ---
const formatNumber = (value: number) => Number(value || 0).toLocaleString('pt-BR', { minimumFractionDigits: 1, maximumFractionDigits: 2 });
const formatDate = (dateString: string) => {
  if (!dateString) return '';
  return formatDistanceToNow(new Date(dateString), { addSuffix: true, locale: ptBR });
};
const getDesignerName = (order: Order): string => order.designer?.full_name || 'Designer';
const getDesignerInitials = (order: Order): string => {
    const name = order.designer?.full_name || '?';
    return name.charAt(0).toUpperCase();
};

// --- METHODS ---
const fetchOrderForApproval = async () => {
  loading.value = true;
  try {
    const { data, error: fetchError } = await supabase
      .from('orders')
      .select('id, customer_name, order_number, created_at, designer:designer_id(full_name, avatar_url), order_items(*)')
      .eq('id', orderId)
      .single();

    if (fetchError || !data) throw new Error('Pedido não encontrado.');
    order.value = data;

    if (itemsToApprove.value.length === 0) {
      setTimeout(() => router.push({ name: 'Approvals' }), 1500);
    }
  } catch (e: any) {
    console.error(e);
  } finally {
    loading.value = false;
  }
};

const approveItem = async (item: OrderItem) => {
    await processDecision(item, true);
};

const openRejectModal = (item: OrderItem) => {
  itemToReject.value = item;
  rejectionComment.value = '';
  showRejectModal.value = true;
};

const rejectItem = async () => {
  if (!itemToReject.value || !rejectionComment.value.trim()) return;
  await processDecision(itemToReject.value, false, rejectionComment.value.trim());
};

const openImage = (url: string) => {
    if (!url) return;
    selectedImageUrl.value = url;
    showImageModal.value = true;
};

const processDecision = async (item: OrderItem, isApproved: boolean, comment?: string) => {
  loading.value = true;
  try {
    if (isApproved) {
        const { error: rpcError } = await supabase.rpc('process_seller_item_decision', {
            p_item_id: item.id,
            p_decision: 'approved_by_seller',
            p_comment: `Arte para "${item.stamp_ref}" aprovada.`,
            p_profile_id: userStore.profile?.id
        });
        if (rpcError) throw rpcError;
    } else {
        const { error: rpcError } = await supabase.rpc('request_item_changes', {
            p_item_id: item.id,
            p_comment: comment,
            p_profile_id: userStore.profile?.id
        });
        if (rpcError) throw rpcError;
    }

    // Opcional: Notificação
    await supabase.rpc('notify_designers_about_decision', {
        p_item_id: item.id,
        p_sender_id: userStore.profile?.id,
        p_is_approved: isApproved
    });

    await fetchOrderForApproval();
  } catch(e: any) {
    console.error(`Erro: ${e.message}`);
  } finally {
    showRejectModal.value = false;
    loading.value = false;
  }
};

onMounted(fetchOrderForApproval);
</script>

<style scoped lang="scss">
/* --- 3D & PHYSICS (Shared with Approvals.vue) --- */
.perspective-container { perspective: 1000px; }
.perspective-grid { transform-style: preserve-3d; }

.card-3d-wrapper {
  position: relative; width: 100%; height: 100%;
  animation: floatY 6s ease-in-out infinite;
  transform-style: preserve-3d; will-change: transform;
}
.card-3d-wrapper:hover { animation-play-state: paused; }

@keyframes floatY {
  0%, 100% { transform: translateY(0); }
  50% { transform: translateY(-10px); }
}

/* --- GLASS CARD 3D --- */
.glass-card-3d {
  width: 100%; height: 100%; border-radius: 20px;
  position: relative; overflow: hidden;
  transform-style: preserve-3d;
  transition: all 0.4s cubic-bezier(0.34, 1.56, 0.64, 1);
}
.glass-card-3d:hover { transform: translateY(-8px) scale(1.02); }

/* Theme Styles */
.dark-glass {
  background: rgba(20, 20, 25, 0.85); backdrop-filter: blur(25px);
  border: 1px solid rgba(255, 255, 255, 0.1);
  box-shadow: 0 20px 50px rgba(0, 0, 0, 0.5);
}
.dark-glass:hover {
  border-color: rgba(255, 255, 255, 0.3); background: rgba(30, 30, 40, 0.95);
  box-shadow: 0 30px 60px rgba(0,0,0,0.8);
}

.light-glass {
  background: rgba(255, 255, 255, 0.95); backdrop-filter: blur(25px);
  border: 1px solid rgba(0, 0, 0, 0.08);
  box-shadow: 0 10px 30px rgba(0, 0, 0, 0.1);
}
.light-glass:hover {
  background: #ffffff; border-color: rgba(255, 152, 0, 0.4); /* Warning Color Focus */
  box-shadow: 0 20px 40px rgba(255, 152, 0, 0.15);
}

/* Glow */
.card-glow {
  position: absolute; top: -50%; left: -50%; width: 200%; height: 200%;
  opacity: 0.15; pointer-events: none; z-index: 1;
  background: radial-gradient(circle, rgba(255,255,255,0.1), transparent 60%);
  transition: opacity 0.5s;
}
.glass-card-3d:hover .card-glow { opacity: 0.3; }
.orange-glow { background: radial-gradient(circle, rgba(255, 152, 0, 0.4), transparent 60%); }
.yellow-glow { background: radial-gradient(circle, rgba(255, 215, 0, 0.3), transparent 60%); }

/* --- TYPOGRAPHY (ULTRA DENSE) --- */
.text-ultra-caption { font-size: 10px; letter-spacing: 0.5px; }
.text-ultra-body { font-size: 11px; }
.lh-1 { line-height: 1.2; }
.letter-spacing-1 { letter-spacing: 1px; }
.letter-spacing-05 { letter-spacing: 0.5px; }

/* --- BORDERS & UTILS --- */
.border-b-subtle { border-bottom: 1px solid rgba(128,128,128, 0.1); }
.border-t-subtle { border-top: 1px solid rgba(128,128,128, 0.1); }
.border-subtle { border: 1px solid rgba(128,128,128, 0.15); }
.border-white-05 { border: 1px solid rgba(255,255,255,0.05); }

/* --- HEADER PANEL --- */
.glass-panel {
  background: rgba(30, 30, 35, 0.6); backdrop-filter: blur(16px);
  border: 1px solid rgba(255, 255, 255, 0.08);
  box-shadow: 0 8px 32px rgba(0,0,0,0.3);
}

/* --- ICON BOX --- */
.icon-box-md { width: 40px; height: 40px; flex-shrink: 0; }
.bg-gradient-primary { background: linear-gradient(135deg, #1976D2, #1565C0); }
.glow-effect { box-shadow: 0 0 15px rgba(25, 118, 210, 0.3); }

/* --- ZEBRA LIST --- */
.mj-zebra-list > *:nth-child(odd) { background-color: rgba(128,128,128, 0.04); }

/* --- ANIMATIONS --- */
@keyframes bounce { 0%, 100% { transform: translateY(0); } 50% { transform: translateY(-10px); } }
.animate-bounce { animation: bounce 2s infinite; }

.card-media img { transition: transform 0.6s ease; }
.glass-card-3d:hover .card-media img { transform: scale(1.1); }

.z-index-50 { z-index: 50; }
.gap-2 { gap: 8px; }
.gap-3 { gap: 12px; }
.h-24 { height: 24px; }
</style>
