<template>
  <v-dialog
    :model-value="modelValue"
    @update:model-value="$emit('update:modelValue', $event)"
    max-width="1200px"
    scrollable
    transition="dialog-bottom-transition"
  >
    <v-card class="glass-modal-card h-100 d-flex flex-row overflow-hidden">

      <div class="kpi-sidebar pa-6 d-flex flex-column" style="width: 280px; border-right: 1px solid rgba(255,255,255,0.05); background: rgba(0,0,0,0.2);">
          <div class="icon-box-xl mb-6" :class="kpiData.gradientClass">
              <v-icon color="white" size="36">{{ kpiData.icon }}</v-icon>
          </div>

          <div class="text-overline text-white-50 font-weight-bold mb-1 letter-spacing-1">Indicador</div>
          <div class="text-h5 font-weight-black text-white mb-6 text-shadow">{{ kpiData.label }}</div>

          <v-divider class="border-white-05 mb-6"></v-divider>

          <div class="info-block mb-6">
              <div class="text-caption text-white-50 text-uppercase font-weight-bold mb-2">Origem</div>
              <div class="glass-pill px-3 py-2 d-flex align-center gap-2">
                  <v-icon size="x-small" color="primary">mdi-database</v-icon>
                  <span class="text-caption text-white font-mono">mj_orders</span>
              </div>
          </div>

          <div class="info-block mb-6">
              <div class="text-caption text-white-50 text-uppercase font-weight-bold mb-2">Período</div>
              <div class="d-flex align-center gap-2">
                  <v-icon size="small" color="white-70">mdi-calendar-range</v-icon>
                  <span class="text-caption text-white">{{ kpiData.periodLabel || 'Total' }}</span>
              </div>
          </div>

          <v-spacer></v-spacer>

          <div class="text-center">
              <div class="d-flex align-center justify-center gap-2 text-success mb-1">
                  <v-icon size="10" class="icon-pulse">mdi-circle</v-icon>
                  <span class="text-[10px] font-weight-bold text-uppercase">Ao Vivo</span>
              </div>
              <div class="text-caption text-white-30">Atualizado agora</div>
          </div>
      </div>

      <div class="flex-grow-1 d-flex flex-column bg-glass-surface min-w-0">
          <div class="px-6 py-4 border-b-white-05 d-flex align-center justify-space-between bg-glass-header flex-shrink-0">
             <div class="d-flex align-center gap-3">
                 <span class="text-h6 font-weight-bold text-white">Registros Encontrados</span>
                 <div class="glass-pill px-2 py-0.5">
                    <span class="text-white font-weight-bold">{{ kpiData.items?.length || 0 }}</span>
                 </div>
             </div>
             <v-btn icon variant="text" color="white-50" @click="$emit('update:modelValue', false)">
                <v-icon>mdi-close</v-icon>
             </v-btn>
          </div>

          <div class="flex-grow-1 pa-4 bg-dark-surface custom-scrollbar overflow-y-auto">
              <div v-if="kpiData.items && kpiData.items.length > 0">
                  <v-list bg-color="transparent" class="pa-0">
                      <v-list-item v-for="(item, i) in kpiData.items" :key="i" class="mb-2 rounded-lg glass-list-item pa-3">
                          <template v-slot:prepend>
                              <v-avatar rounded="lg" size="40" class="mr-4 border-white-10 bg-grey-darken-3">
                                  <v-img v-if="item.stamp_image_url" :src="item.stamp_image_url" cover></v-img>
                                  <v-icon v-else size="20" color="white-30">mdi-image-off</v-icon>
                              </v-avatar>
                          </template>

                          <div class="d-flex align-center justify-space-between w-100">
                              <div style="min-width: 0;">
                                  <div class="text-white font-weight-bold text-body-2 mb-1 text-truncate">
                                      {{ item.customer_name }}
                                  </div>
                                  <div class="d-flex align-center gap-2 text-caption text-white-50">
                                      <span class="font-mono bg-white-05 px-1 rounded">#{{ item.order_number }}</span>
                                      <span>•</span>
                                      <span class="text-truncate">{{ item.fabric_type }}</span>
                                  </div>
                              </div>

                              <div class="d-flex align-center gap-4 flex-shrink-0 ml-4">
                                  <div class="text-right">
                                      <div class="text-caption text-white-70 font-mono">{{ formatDate(item.date_ref || item.created_at) }}</div>
                                      <div class="text-[10px] text-white-30">Atualização</div>
                                  </div>
                                  <v-chip size="x-small" :color="getStatusColor(item.status)" variant="flat" class="font-weight-bold text-uppercase border-none">
                                      {{ getStatusLabel(item.status) }}
                                  </v-chip>
                              </div>
                          </div>
                      </v-list-item>
                  </v-list>
              </div>

              <div v-else class="d-flex flex-column align-center justify-center h-100 py-12 text-center opacity-50">
                  <div class="icon-box-xl bg-white-05 mb-4 text-white-30">
                      <v-icon size="32">mdi-clipboard-text-off-outline</v-icon>
                  </div>
                  <div class="text-h6 text-white-30">Sem dados para exibir</div>
                  <div class="text-caption text-white-30">Nenhum registro encontrado neste filtro.</div>
              </div>
          </div>

          <v-divider class="border-white-05"></v-divider>

          <div class="pa-4 bg-glass-header d-flex justify-end gap-3 flex-shrink-0">
              <v-btn variant="text" color="white-50" size="small" @click="$emit('update:modelValue', false)">Fechar</v-btn>
              <v-btn color="primary" variant="flat" size="small" class="px-4 font-weight-bold shadow-glow text-none" prepend-icon="mdi-download">Exportar CSV</v-btn>
          </div>
      </div>
    </v-card>
  </v-dialog>
</template>

<script setup lang="ts">
import { format, parseISO } from 'date-fns';

const props = defineProps(['modelValue', 'kpiData']);
const emit = defineEmits(['update:modelValue']);

const formatDate = (d: string) => {
    if (!d) return '-';
    try { return format(parseISO(d), 'dd/MM HH:mm'); } catch { return d; }
}

const getStatusLabel = (s: string) => ({ 'design_pending': 'Fila', 'in_design': 'Criando', 'changes_requested': 'Alteração', 'customer_approval': 'Aprovação', 'ready_for_production': 'Liberado', 'completed': 'Finalizado' }[s] || s);
const getStatusColor = (s: string) => ({ 'design_pending': 'blue-grey', 'in_design': 'info', 'changes_requested': 'error', 'customer_approval': 'warning', 'ready_for_production': 'success', 'completed': 'success' }[s] || 'grey');
</script>

<style scoped lang="scss">
.glass-modal-card { background: #14151a !important; border: 1px solid rgba(255, 255, 255, 0.1); box-shadow: 0 50px 100px -20px rgba(0,0,0,0.8); border-radius: 20px; }
.bg-glass-surface { background: linear-gradient(135deg, rgba(255,255,255,0.01) 0%, transparent 100%); }
.bg-glass-header { background: rgba(255, 255, 255, 0.02); }
.bg-dark-surface { background: #0F1014; }
.border-b-white-05 { border-bottom: 1px solid rgba(255,255,255,0.05); }
.border-white-05 { border: 1px solid rgba(255,255,255,0.05); }
.border-white-10 { border: 1px solid rgba(255,255,255,0.1); }

.icon-box-xl { width: 64px; height: 64px; border-radius: 16px; display: flex; align-items: center; justify-content: center; background: rgba(255,255,255,0.05); border: 1px solid rgba(255,255,255,0.1);
    &.gradient-error { box-shadow: 0 0 30px rgba(255, 82, 82, 0.15); color: #FF5252; }
    &.gradient-warning { box-shadow: 0 0 30px rgba(255, 171, 64, 0.15); color: #FFAB40; }
    &.gradient-success { box-shadow: 0 0 30px rgba(105, 240, 174, 0.15); color: #69F0AE; }
    &.gradient-info { box-shadow: 0 0 30px rgba(64, 196, 255, 0.15); color: #40C4FF; }
    &.gradient-purple { box-shadow: 0 0 30px rgba(171, 71, 188, 0.15); color: #AB47BC; }
}

.glass-pill { background: rgba(255,255,255,0.05); border-radius: 50px; border: 1px solid rgba(255,255,255,0.05); }
.glass-list-item { background: rgba(255,255,255,0.02); border: 1px solid transparent; transition: all 0.2s; &:hover { background: rgba(255,255,255,0.05); border-color: rgba(255,255,255,0.1); transform: translateX(4px); } }
.text-shadow { text-shadow: 0 2px 10px rgba(0,0,0,0.5); }
.icon-pulse { animation: pulse 2s infinite; }
@keyframes pulse { 0% { opacity: 0.5; } 50% { opacity: 1; } 100% { opacity: 0.5; } }
.custom-scrollbar::-webkit-scrollbar { width: 6px; }
.custom-scrollbar::-webkit-scrollbar-track { background: rgba(255, 255, 255, 0.02); }
.custom-scrollbar::-webkit-scrollbar-thumb { background: rgba(255, 255, 255, 0.1); border-radius: 3px; }
.shadow-glow { box-shadow: 0 0 15px rgba(var(--v-theme-primary), 0.3); }
</style>
