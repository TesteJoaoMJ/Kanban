<template>
  <v-dialog :model-value="modelValue" @update:model-value="$emit('update:modelValue', $event)" max-width="1200px" scrollable transition="dialog-bottom-transition">
    <v-card class="glass-modal-card h-100">

      <div class="modal-header-glass pa-4 d-flex align-center justify-space-between flex-wrap gap-4">
        <div class="d-flex align-center">
          <v-avatar color="primary" variant="tonal" rounded="lg" size="48" class="mr-4">
            <span class="text-h6 font-weight-bold">{{ item?.customer_name?.charAt(0) }}</span>
          </v-avatar>
          <div>
            <div class="d-flex align-center gap-2">
              <span class="text-h6 font-weight-bold text-white">{{ item?.customer_name }}</span>
              <v-chip size="x-small" color="white" variant="outlined" class="font-mono">#{{ item?.order_number }}</v-chip>
            </div>
            <div class="d-flex align-center gap-2 mt-1">
              <v-icon size="x-small" color="primary">mdi-store-outline</v-icon>
              <span class="text-caption text-white-70">{{ item?.store_name || 'Loja Principal' }}</span>
              <span class="text-caption text-white-30">•</span>
              <v-icon size="x-small" color="white-50">mdi-account-tie</v-icon>
              <span class="text-caption text-white-70">{{ item?.creator_name || 'Vendedor' }}</span>
            </div>
          </div>
        </div>

        <div class="d-flex align-center gap-3 action-buttons">
           <v-btn size="small" variant="tonal" color="info" prepend-icon="mdi-chat-processing-outline" class="px-4">Chat Pedido</v-btn>
           <v-divider vertical class="border-white-10 mx-2" style="height: 20px"></v-divider>

           <v-btn
             v-if="item?.status === 'design_pending'"
             size="small" color="primary" variant="flat" prepend-icon="mdi-play"
             class="px-4 shadow-glow"
             @click="$emit('start-design', item)"
           >
             Iniciar Criação
           </v-btn>

           <v-btn
             v-if="['in_design', 'changes_requested'].includes(item?.status)"
             size="small" color="success" variant="flat" prepend-icon="mdi-check-all"
             class="px-4 shadow-glow"
             @click="$emit('finish-design', item)"
           >
             Finalizar Arte
           </v-btn>

           <v-btn icon size="small" variant="text" color="white-50" @click="$emit('update:modelValue', false)">
             <v-icon>mdi-close</v-icon>
           </v-btn>
        </div>
      </div>

      <v-divider class="border-white-10"></v-divider>

      <v-card-text class="pa-0 d-flex flex-row h-100 relative overflow-hidden">
        <div class="left-panel pa-6 custom-scrollbar" style="width: 35%; border-right: 1px solid rgba(255,255,255,0.05);">
            <div class="text-subtitle-2 text-uppercase text-white-30 font-weight-bold mb-4 letter-spacing-1">Especificações do Item</div>

            <div class="metadata-grid">
               <div class="meta-box">
                  <div class="meta-label">Tecido Base</div>
                  <div class="meta-value text-primary">{{ item?.fabric_type || 'N/A' }}</div>
               </div>
               <div class="meta-box">
                  <div class="meta-label">Metragem</div>
                  <div class="meta-value">{{ item?.quantity_meters }}m</div>
               </div>
               <div class="meta-box">
                  <div class="meta-label">Data Entrada</div>
                  <div class="meta-value">{{ formatDate(item?.created_at) }}</div>
               </div>
               <div class="meta-box">
                  <div class="meta-label">Previsão</div>
                  <div class="meta-value text-warning">{{ item?.deadline || '24h' }}</div>
               </div>
            </div>

            <v-divider class="border-white-10 my-6"></v-divider>

            <div class="text-subtitle-2 text-uppercase text-white-30 font-weight-bold mb-3 letter-spacing-1">Notas do Vendedor</div>
            <div class="glass-well pa-4 rounded-lg text-body-2 text-white-70">
                {{ item?.notes || 'Nenhuma observação adicional fornecida pelo vendedor.' }}
            </div>

            <div class="mt-6">
                <div class="d-flex align-center justify-space-between mb-2">
                    <span class="text-subtitle-2 text-white-50">Status Atual</span>
                    <v-chip size="small" :color="getStatusColor(item?.status)" variant="flat" class="font-weight-bold">
                        {{ getStatusLabel(item?.status) }}
                    </v-chip>
                </div>
                <v-progress-linear :model-value="getProgress(item?.status)" :color="getStatusColor(item?.status)" height="4" rounded></v-progress-linear>
            </div>
        </div>

        <div class="right-panel flex-grow-1 pa-6 custom-scrollbar bg-black-05">
            <div class="text-subtitle-2 text-uppercase text-white-30 font-weight-bold mb-4 letter-spacing-1">Referências & Arquivos</div>

            <div v-if="item?.attachments && item.attachments.length > 0" class="image-grid">
                <div v-for="(img, idx) in item.attachments" :key="idx" class="reference-card glass-card">
                    <v-img :src="img" aspect-ratio="1" cover class="rounded-lg">
                        <template v-slot:placeholder><v-skeleton-loader type="image" color="transparent"></v-skeleton-loader></template>
                    </v-img>
                    <div class="overlay-actions">
                        <v-btn icon size="small" variant="flat" color="white" class="text-black"><v-icon>mdi-magnify</v-icon></v-btn>
                        <v-btn icon size="small" variant="flat" color="white" class="text-black ml-2"><v-icon>mdi-download</v-icon></v-btn>
                    </div>
                </div>
            </div>
            <div v-else class="empty-state py-10 text-center border-dashed-white-10 rounded-xl">
                <v-icon size="48" color="white-20" class="mb-2">mdi-image-off-outline</v-icon>
                <div class="text-caption text-white-30">Sem imagens de referência anexadas.</div>
            </div>

            <div class="mt-8">
               <div class="text-subtitle-2 text-uppercase text-white-30 font-weight-bold mb-4 letter-spacing-1">Histórico Rápido</div>
               <v-timeline density="compact" align="start" side="end" class="custom-timeline">
                  <v-timeline-item dot-color="primary" size="x-small">
                     <div class="text-caption text-white-50">{{ formatDate(item?.created_at) }}</div>
                     <div class="text-body-2 text-white font-weight-bold">Pedido Criado</div>
                  </v-timeline-item>
                  <v-timeline-item v-if="item?.status !== 'design_pending'" dot-color="info" size="x-small">
                     <div class="text-caption text-white-50">Há 2 horas</div>
                     <div class="text-body-2 text-white font-weight-bold">Design Iniciado</div>
                  </v-timeline-item>
               </v-timeline>
            </div>
        </div>
      </v-card-text>
    </v-card>
  </v-dialog>
</template>

<script setup lang="ts">
import { format, parseISO } from 'date-fns';

const props = defineProps(['modelValue', 'item']);
const emit = defineEmits(['update:modelValue', 'start-design', 'finish-design']);

const formatDate = (dateString: string) => {
    if(!dateString) return '-';
    try { return format(parseISO(dateString), 'dd/MM/yy HH:mm'); } catch { return dateString; }
}

const getStatusLabel = (s: string) => {
    const map: any = { 'design_pending': 'Aguardando', 'in_design': 'Em Criação', 'changes_requested': 'Alteração', 'customer_approval': 'Aprovação' };
    return map[s] || s;
}

const getStatusColor = (s: string) => {
    const map: any = { 'design_pending': 'grey', 'in_design': 'info', 'changes_requested': 'error', 'customer_approval': 'warning' };
    return map[s] || 'primary';
}

const getProgress = (s: string) => {
    const map: any = { 'design_pending': 10, 'in_design': 50, 'changes_requested': 50, 'customer_approval': 80, 'finalizing': 90 };
    return map[s] || 0;
}
</script>

<style scoped lang="scss">
.glass-modal-card {
    background: rgba(20, 20, 25, 0.85) !important;
    backdrop-filter: blur(25px) saturate(180%);
    border: 1px solid rgba(255, 255, 255, 0.08);
    box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.5);
    border-radius: 16px;
}

.modal-header-glass {
    background: linear-gradient(180deg, rgba(255,255,255,0.03) 0%, rgba(255,255,255,0) 100%);
    border-bottom: 1px solid rgba(255,255,255,0.05);
}

.metadata-grid {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 12px;
}

.meta-box {
    background: rgba(255,255,255,0.03);
    border: 1px solid rgba(255,255,255,0.05);
    padding: 10px;
    border-radius: 8px;
}

.meta-label { font-size: 10px; text-transform: uppercase; color: rgba(255,255,255,0.4); font-weight: 700; margin-bottom: 4px; }
.meta-value { font-size: 13px; color: white; font-weight: 600; }

.glass-well { background: rgba(0,0,0,0.2); border: 1px solid rgba(255,255,255,0.05); }
.bg-black-05 { background: rgba(0,0,0,0.15); }

.image-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(120px, 1fr)); gap: 12px; }
.reference-card { position: relative; overflow: hidden; border: 1px solid rgba(255,255,255,0.1); border-radius: 8px; transition: all 0.2s; }
.reference-card:hover { transform: translateY(-2px); border-color: rgba(var(--v-theme-primary), 0.5); }
.overlay-actions {
    position: absolute; inset: 0; background: rgba(0,0,0,0.6);
    display: flex; align-items: center; justify-content: center;
    opacity: 0; transition: opacity 0.2s;
}
.reference-card:hover .overlay-actions { opacity: 1; }

.border-dashed-white-10 { border: 1px dashed rgba(255,255,255,0.1); }
.custom-scrollbar::-webkit-scrollbar { width: 6px; }
.custom-scrollbar::-webkit-scrollbar-thumb { background: rgba(255, 255, 255, 0.1); border-radius: 3px; }
.shadow-glow { box-shadow: 0 0 15px rgba(var(--v-theme-primary), 0.2); }
</style>
