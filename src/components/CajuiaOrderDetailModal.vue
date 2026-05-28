<template>
  <v-dialog
    :model-value="show"
    @update:model-value="v => { if (!v) closeModal() }"
    width="1200"
    max-width="95vw"
    height="85vh"
    class="glass-modal-wrapper"
    transition="dialog-bottom-transition"
    scrollable
    persistent
  >
    <v-card class="glass-detail-card d-flex flex-column h-100 overflow-hidden border-none">

      <div class="detail-header px-8 py-5 d-flex align-center justify-space-between flex-shrink-0 border-b border-white-05 bg-glass-header backdrop-blur z-30">
         <div class="header-bg-glow success"></div>

         <div class="d-flex align-center gap-6 relative z-10">
            <div class="detail-icon-box rounded-xl elevation-10 d-flex align-center justify-center position-relative overflow-hidden bg-glass-surface border border-white-10">
               <div class="shine-effect"></div>
               <v-icon size="32" color="white">mdi-receipt-text</v-icon>
            </div>

            <div>
               <div class="d-flex align-center gap-3 mb-1">
                   <div class="d-flex align-center gap-2 px-2 py-1 rounded bg-white-05 border border-white-05">
                      <v-icon size="12" color="success" class="icon-pulse">mdi-check-circle</v-icon>
                      <span class="text-[10px] font-weight-bold text-uppercase letter-spacing-1 text-white-70">
                          {{ order?.status || 'CONCLUÍDO' }}
                      </span>
                   </div>
                   <span class="text-overline text-white-30 font-weight-bold letter-spacing-1">
                       {{ formatDate(order?.created_at) }} • {{ formatTime(order?.created_at) }}
                   </span>
               </div>
               <h2 class="text-h5 font-weight-black text-white lh-1 mt-1 text-shadow">Pedido #{{ order?.order_number }}</h2>
            </div>
         </div>

         <div class="d-flex align-center gap-3">
             <div class="d-flex align-center bg-glass-surface border border-white-10 rounded-lg pa-1 hidden-sm-and-down">
                <v-btn
                    variant="text"
                    color="white-70"
                    class="text-none font-weight-bold px-4 rounded-md hover-bg-white-10"
                    prepend-icon="mdi-file-document-outline"
                    :href="order?.sales_order_pdf_url"
                    target="_blank"
                    :disabled="!order?.sales_order_pdf_url"
                >
                    Visualizar Recibo
                </v-btn>
             </div>

             <v-divider vertical class="border-white-10 py-2 hidden-sm-and-down" style="height: 32px"></v-divider>

             <v-btn icon variant="text" color="white-70" class="close-btn" @click="closeModal">
                <v-icon size="28">mdi-close</v-icon>
             </v-btn>
         </div>
      </div>

      <div class="d-flex flex-grow-1 overflow-hidden relative">

          <div class="sidebar-panel pa-6 border-r border-white-05 bg-glass-darker d-flex flex-column overflow-y-auto custom-scrollbar z-20 h-100">

              <div class="mb-8 relative">
                 <div class="text-caption font-weight-bold text-white-30 text-uppercase mb-2 d-flex align-center justify-space-between">
                    <span>Valor Total</span>
                    <v-icon size="20" color="success">mdi-cash-multiple</v-icon>
                 </div>
                 <div class="kpi-display text-success lh-1 mb-4 text-h3 font-weight-black font-mono">
                    {{ formatCurrency(order?.total_value) }}
                 </div>
                 <div class="variation-card d-flex align-center gap-3 pa-3 rounded-lg bg-white-02 border border-white-05">
                    <div class="icon-circle bg-white-05 text-white">
                       <v-icon size="16">mdi-credit-card-check-outline</v-icon>
                    </div>
                    <div class="overflow-hidden">
                       <div class="text-caption text-white-50 lh-1">Método de Pagamento</div>
                       <div class="text-body-2 font-weight-bold text-white text-truncate">{{ order?.payment_method || 'Não informado' }}</div>
                    </div>
                 </div>
              </div>

              <v-divider class="border-white-05 mb-6"></v-divider>

              <div class="d-flex flex-column gap-4 mb-auto">
                  <div class="section-title text-[10px] font-weight-black text-white-30 text-uppercase letter-spacing-2 mb-2">Cliente & Venda</div>

                  <div class="info-item d-flex gap-3">
                      <v-avatar size="36" color="primary" variant="tonal" class="mt-1">
                          <span class="text-subtitle-2 font-weight-black">{{ getInitials(order?.customer_name) }}</span>
                      </v-avatar>
                      <div class="overflow-hidden">
                          <div class="text-caption text-white-50 font-weight-bold">Cliente</div>
                          <div class="text-body-2 text-white font-weight-bold text-truncate" :title="order?.customer_name">
                             {{ order?.customer_name || 'Consumidor Final' }}
                          </div>
                          <div class="text-caption text-white-30 font-mono" v-if="order?.document">
                              {{ formatDoc(order.document) }}
                          </div>
                      </div>
                  </div>

                  <div class="info-item d-flex gap-3 mt-2">
                      <div class="icon-box-sm bg-white-05 text-white-70"><v-icon size="16">mdi-badge-account-outline</v-icon></div>
                      <div>
                          <div class="text-caption text-white-50 font-weight-bold">Vendedor</div>
                          <div class="text-body-2 text-white">
                             {{ order?.vendedor_nome || 'Sistema' }}
                          </div>
                      </div>
                  </div>
              </div>

              <div class="mt-8 sticky-bottom-sidebar">
                  <div class="glass-well pa-4 rounded-xl border border-white-05">
                      <div class="d-flex justify-space-between align-center mb-2">
                          <span class="text-caption text-white-50 font-weight-bold">Subtotal</span>
                          <span class="text-caption text-white font-mono">{{ formatCurrency(order?.total_value) }}</span>
                      </div>
                      <div class="d-flex justify-space-between align-center mb-2">
                          <span class="text-caption text-white-50 font-weight-bold">Descontos</span>
                          <span class="text-caption text-error font-mono font-weight-bold">- {{ formatCurrency(0) }}</span>
                      </div>
                      <v-divider class="border-white-10 my-2"></v-divider>
                      <div class="d-flex justify-space-between align-center">
                          <span class="text-caption text-white font-weight-black text-uppercase">Total Líquido</span>
                          <span class="text-body-1 text-success font-weight-black">{{ formatCurrency(order?.total_value) }}</span>
                      </div>
                  </div>
              </div>
          </div>

          <div class="main-panel d-flex flex-column bg-glass-surface relative flex-grow-1 h-100 min-w-0">

              <div class="d-flex align-center justify-space-between px-6 py-4 border-b border-white-05 bg-glass-header flex-shrink-0">
                  <div class="d-flex align-center gap-2">
                      <v-icon size="18" color="white-50">mdi-package-variant-closed</v-icon>
                      <span class="text-subtitle-2 font-weight-bold text-white">Itens do Pedido</span>
                      <v-chip size="x-small" color="white" variant="outlined" class="ml-2 font-mono">{{ items.length }}</v-chip>
                  </div>

                  </div>

              <div class="flex-grow-1 overflow-y-auto custom-scrollbar pa-6">

                  <div v-if="items.length === 0" class="d-flex flex-column align-center justify-center h-100 text-center opacity-50">
                      <v-icon size="64" class="mb-4 text-white-20">mdi-cart-off</v-icon>
                      <div class="text-body-1 font-weight-bold text-white-50">Nenhum item encontrado</div>
                  </div>

                  <v-table v-else density="default" class="bg-transparent text-white hover-rows w-100">
                      <thead class="bg-glass-darker backdrop-blur">
                          <tr>
                              <th class="text-left text-white-30 text-[10px] text-uppercase font-weight-bold pl-4 py-3 w-50">Produto / Serviço</th>
                              <th class="text-center text-white-30 text-[10px] text-uppercase font-weight-bold py-3">Qtd</th>
                              <th class="text-right text-white-30 text-[10px] text-uppercase font-weight-bold py-3">Unitário</th>
                              <th class="text-right text-white-30 text-[10px] text-uppercase font-weight-bold pr-4 py-3">Total</th>
                          </tr>
                      </thead>
                      <tbody>
                          <tr v-for="(item, i) in items" :key="i" class="border-b border-white-05 transition-colors group">
                              <td class="pl-4 py-3">
                                  <div class="d-flex align-center">
                                      <v-avatar rounded size="40" class="mr-4 bg-white-05 border border-white-05">
                                          <v-img v-if="item.photo_url" :src="item.photo_url" cover></v-img>
                                          <v-icon v-else size="20" color="white-30">mdi-image-off-outline</v-icon>
                                      </v-avatar>
                                      <div>
                                          <div class="font-weight-bold text-body-2 text-white line-clamp-2" :title="item.name">
                                              {{ item.name || 'Produto sem nome' }}
                                          </div>
                                          <div class="text-[10px] text-white-50 mt-0.5 font-mono" v-if="item.sku">SKU: {{ item.sku }}</div>
                                      </div>
                                  </div>
                              </td>
                              <td class="text-center py-3">
                                  <div class="d-inline-flex px-3 py-1 rounded bg-white-05 font-mono text-caption font-weight-bold">
                                      {{ item.quantity }}
                                  </div>
                              </td>
                              <td class="text-right py-3 text-caption text-white-70 font-mono">
                                  {{ formatCurrency(item.unit_price) }}
                              </td>
                              <td class="text-right pr-4 py-3 text-body-2 font-weight-black text-white font-mono">
                                  {{ formatCurrency(item.total) }}
                              </td>
                          </tr>
                      </tbody>
                  </v-table>

              </div>
          </div>
      </div>
    </v-card>
  </v-dialog>
</template>

<script setup lang="ts">
import { computed } from 'vue';
import { format } from 'date-fns';

const props = defineProps({
  show: Boolean,
  order: Object
});

const emit = defineEmits(['close']);

const items = computed(() => {
    // Se o objeto order tiver itens aninhados, use-os.
    // Caso contrário, use a lógica de fallback para visualização.
    if (props.order?.items && Array.isArray(props.order.items) && props.order.items.length > 0) {
        return props.order.items;
    }

    // Fallback apenas se não houver itens reais (para evitar tela vazia em mocks)
    // Em produção, idealmente mostraria estado vazio se a lista vier vazia do backend.
    return [
        {
            name: 'Venda Avulsa / Serviço (Sem detalhamento)',
            quantity: 1,
            unit_price: props.order?.total_value || 0,
            total: props.order?.total_value || 0
        }
    ];
});

const closeModal = () => {
  emit('close');
};

// Formatters
const formatCurrency = (val: number) => new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(val || 0);
const formatDate = (dateString: string) => dateString ? format(new Date(dateString), 'dd/MM/yyyy') : '-';
const formatTime = (dateString: string) => dateString ? format(new Date(dateString), 'HH:mm') : '-';
const formatDoc = (doc: string) => {
    if (!doc) return '';
    return doc.length > 11
        ? doc.replace(/^(\d{2})(\d{3})(\d{3})(\d{4})(\d{2})/, "$1.$2.$3/$4-$5")
        : doc.replace(/^(\d{3})(\d{3})(\d{3})(\d{2})/, "$1.$2.$3-$4");
};
const getInitials = (name: string) => name ? name.substring(0, 2).toUpperCase() : '??';

</script>

<style scoped lang="scss">
.glass-modal-wrapper { backdrop-filter: blur(10px); }
.glass-detail-card {
    background: #12121486;
    border: 1px solid rgba(255, 255, 255, 0.08);
    border-radius: 24px;
    box-shadow: 0 50px 100px -20px rgba(0,0,0,0.9);
}

/* HEADER */
.detail-header { position: relative; overflow: hidden; }
.header-bg-glow {
    position: absolute; top: -100%; left: -20%; width: 140%; height: 300%; opacity: 0.08; filter: blur(80px); pointer-events: none;
    background: radial-gradient(circle, currentColor, transparent 70%);
    &.success { color: #00e676; }
    &.primary { color: rgb(var(--v-theme-primary)); }
}
.detail-icon-box { width: 64px; height: 64px; }
.shine-effect {
    position: absolute; top: 0; left: 0; width: 100%; height: 100%;
    background: linear-gradient(135deg, rgba(255,255,255,0.1) 0%, transparent 50%);
}

/* LAYOUT & SIDEBAR */
.sidebar-panel { width: 320px; flex-shrink: 0; min-width: 300px; }
.sticky-bottom-sidebar { margin-top: auto; padding-top: 20px; }

/* COLORS & SURFACES */
.bg-glass-header { background: rgba(18, 18, 20, 0.6); }
.bg-glass-darker { background: rgba(14, 14, 16, 0.5); }
.bg-glass-surface { background: linear-gradient(to bottom right, rgba(255,255,255,0.01), transparent); }
.bg-white-02 { background: rgba(255,255,255,0.02); }
.bg-white-05 { background: rgba(255,255,255,0.05); }
.icon-box-sm { width: 32px; height: 32px; display: flex; align-items: center; justify-content: center; border-radius: 8px; }
.icon-circle { width: 40px; height: 40px; display: flex; align-items: center; justify-content: center; border-radius: 50%; }
.glass-well { background: rgba(255,255,255,0.02); }

/* TYPOGRAPHY */
.lh-1 { line-height: 1; }
.text-shadow { text-shadow: 0 2px 10px rgba(0,0,0,0.5); }
.font-mono { font-family: 'Roboto Mono', monospace; letter-spacing: -0.5px; }
.line-clamp-2 { display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; }

.text-white-30 { color: rgba(255,255,255,0.3) !important; }
.text-white-50 { color: rgba(255,255,255,0.5) !important; }
.text-white-70 { color: rgba(255,255,255,0.7) !important; }

/* UTILS */
.border-white-05 { border-color: rgba(255,255,255,0.05) !important; }
.border-white-10 { border-color: rgba(255,255,255,0.1) !important; }
.hover-bg-white-10:hover { background: rgba(255,255,255,0.1) !important; }
.close-btn:hover { background: rgba(255,0,0,0.1); color: #ff5252 !important; transform: rotate(90deg); transition: all 0.3s; }
.icon-pulse { animation: pulse 2s infinite; }
@keyframes pulse { 0% { opacity: 0.5; } 50% { opacity: 1; } 100% { opacity: 0.5; } }

/* SCROLLBAR */
.custom-scrollbar::-webkit-scrollbar { width: 6px; }
.custom-scrollbar::-webkit-scrollbar-track { background: transparent; }
.custom-scrollbar::-webkit-scrollbar-thumb { background: rgba(255,255,255,0.1); border-radius: 3px; }
.custom-scrollbar::-webkit-scrollbar-thumb:hover { background: rgba(255,255,255,0.2); }

/* TABLE */
.hover-rows tr:hover td { background: rgba(255,255,255,0.03); }
</style>
