<template>
  <v-dialog
    :model-value="show"
    @update:model-value="$emit('close')"
    max-width="900px"
    scrollable
    content-class="glass-dialog"
  >
    <v-card class="glass-modal border-white-10">
      <div class="pa-6 border-b border-white-10 bg-glass-header d-flex align-center justify-space-between">
        <div class="d-flex align-center gap-4">
          <div class="icon-box bg-gradient-info elevation-10">
            <v-icon color="white" size="28">mdi-notebook-edit-outline</v-icon>
          </div>
          <div>
            <h2 class="text-h6 font-weight-black text-white lh-1">Gerenciador de Rascunhos</h2>
            <div class="text-caption text-white-50 mt-1">
              Visualize detalhes, retome vendas pendentes ou descarte rascunhos antigos.
            </div>
          </div>
        </div>
        <v-btn icon variant="text" color="white-50" @click="$emit('close')">
          <v-icon>mdi-close</v-icon>
        </v-btn>
      </div>

      <v-card-text class="pa-4 bg-glass-body-gradient custom-scrollbar">

        <div v-if="loading" class="d-flex flex-column align-center justify-center py-12">
           <v-progress-circular indeterminate color="primary" size="48" class="mb-4"></v-progress-circular>
           <span class="text-caption text-white-50">Sincronizando rascunhos...</span>
        </div>

        <div v-else-if="!drafts || drafts.length === 0" class="text-center py-16">
          <div class="icon-circle-large bg-white-05 mx-auto mb-4">
             <v-icon size="48" class="text-white-20">mdi-file-hidden</v-icon>
          </div>
          <h3 class="text-subtitle-1 font-weight-bold text-white-50">Nenhum rascunho encontrado</h3>
          <p class="text-caption text-white-30">Salve uma venda em andamento para acessá-la aqui depois.</p>
        </div>

        <v-expansion-panels v-else variant="accordion" class="glass-panels">
          <v-expansion-panel
            v-for="draft in drafts"
            :key="draft.id"
            class="glass-panel-item mb-2 rounded-lg border border-white-05 bg-transparent"
            elevation="0"
          >
            <v-expansion-panel-title class="py-3 px-4 hover-bg-white-05 transition-colors" expand-icon="mdi-chevron-down" collapse-icon="mdi-chevron-up">
               <div class="d-flex align-center justify-space-between w-100 mr-4">

                  <div class="d-flex align-center gap-4">
                      <div class="d-flex flex-column align-center justify-center bg-white-05 rounded px-3 py-1" style="min-width: 60px;">
                          <span class="text-[10px] text-white-30 font-weight-bold text-uppercase">Pedido</span>
                          <span class="text-subtitle-2 font-weight-black text-warning">#{{ draft.order_number }}</span>
                      </div>

                      <div class="d-flex flex-column">
                          <div class="text-subtitle-2 font-weight-bold text-white text-truncate" style="max-width: 200px;">
                              {{ draft.customer_name || 'Consumidor Final' }}
                          </div>
                          <div class="d-flex align-center gap-3 text-caption text-white-50">
                              <span class="d-flex align-center"><v-icon size="12" class="mr-1">mdi-clock-outline</v-icon> {{ formatDate(draft.created_at) }}</span>
                              <span class="d-flex align-center"><v-icon size="12" class="mr-1">mdi-hanger</v-icon> {{ draft.item_count }} itens</span>
                          </div>
                      </div>
                  </div>

                  <div class="d-flex align-center gap-4">
                      <div class="text-right hidden-sm-and-down">
                          <div class="text-[10px] text-white-50 font-weight-bold text-uppercase">Total Salvo</div>
                          <div class="text-h6 font-weight-black text-success lh-1">{{ formatCurrency(draft.total_value) }}</div>
                      </div>

                      <div class="d-flex align-center gap-2 ml-2" @click.stop>
                          <v-btn
                            color="primary"
                            variant="flat"
                            size="small"
                            class="text-none font-weight-bold px-3 rounded-lg shadow-glow-primary"
                            @click="$emit('load', draft)"
                          >
                            <v-icon start size="16">mdi-upload</v-icon> Carregar
                          </v-btn>
                          <v-btn
                            color="error"
                            variant="text"
                            icon
                            size="small"
                            class="opacity-50 hover-opacity-100"
                            @click="$emit('delete', draft.id)"
                          >
                            <v-icon>mdi-delete-outline</v-icon>
                          </v-btn>
                      </div>
                  </div>
               </div>
            </v-expansion-panel-title>

            <v-expansion-panel-text class="bg-black-20">
                <div class="pt-2">
                    <div class="d-flex flex-wrap gap-4 mb-4 border-b border-white-05 pb-3">
                        <div class="glass-chip px-3 py-1 rounded-pill border border-white-10 d-flex align-center gap-2">
                            <v-icon size="14" color="info">mdi-credit-card-outline</v-icon>
                            <span class="text-caption text-white-70">{{ draft.draft_data?.paymentMethod?.nome || 'Não definido' }}</span>
                        </div>
                        <div class="glass-chip px-3 py-1 rounded-pill border border-white-10 d-flex align-center gap-2" v-if="draft.draft_data?.activePriceList">
                            <v-icon size="14" color="warning">mdi-tag-text-outline</v-icon>
                            <span class="text-caption text-white-70">Tabela: {{ draft.draft_data.activePriceList.name }}</span>
                        </div>
                        <div class="glass-chip px-3 py-1 rounded-pill border border-white-10 d-flex align-center gap-2" v-if="draft.draft_data?.discount?.value > 0">
                            <v-icon size="14" color="error">mdi-sale</v-icon>
                            <span class="text-caption text-white-70">Desc: {{ draft.draft_data.discount.value }} ({{ draft.draft_data.discount.type === 'percent' ? '%' : 'R$' }})</span>
                        </div>
                        <div class="glass-chip px-3 py-1 rounded-pill border border-white-10 d-flex align-center gap-2" v-if="draft.draft_data?.notes">
                            <v-icon size="14" color="white-50">mdi-note-text-outline</v-icon>
                            <span class="text-caption text-white-70 text-truncate" style="max-width: 300px;">"{{ draft.draft_data.notes }}"</span>
                        </div>
                    </div>

                    <div class="rounded-lg overflow-hidden border border-white-05">
                        <v-table density="compact" class="bg-transparent text-caption">
                            <thead>
                                <tr class="bg-white-05">
                                    <th class="text-white-50 font-weight-bold">Produto</th>
                                    <th class="text-right text-white-50 font-weight-bold">Qtd</th>
                                    <th class="text-right text-white-50 font-weight-bold">Unit.</th>
                                    <th class="text-right text-white-50 font-weight-bold">Total</th>
                                </tr>
                            </thead>
                            <tbody>
                                <tr v-for="(item, i) in draft.draft_data?.cart || []" :key="i" class="hover-bg-white-05">
                                    <td class="text-white py-2">
                                        <div class="d-flex align-center gap-2">
                                            <v-avatar size="24" rounded="sm" class="bg-white-10">
                                                <v-img :src="item.photo_url || '/placeholder.png'" cover></v-img>
                                            </v-avatar>
                                            <span class="text-truncate" style="max-width: 200px;">{{ item.product_name }}</span>
                                        </div>
                                    </td>
                                    <td class="text-right text-white font-mono">{{ item.quantity }}</td>
                                    <td class="text-right text-white-70">{{ formatCurrency(item.unit_price) }}</td>
                                    <td class="text-right text-white font-weight-bold">{{ formatCurrency(item.total_price) }}</td>
                                </tr>
                            </tbody>
                        </v-table>
                    </div>
                </div>
            </v-expansion-panel-text>
          </v-expansion-panel>
        </v-expansion-panels>
      </v-card-text>

      <div class="pa-4 border-t border-white-10 bg-glass-footer d-flex justify-between align-center">
         <span class="text-caption text-white-30 ml-2">Total de {{ drafts.length }} rascunhos salvos</span>
         <v-btn variant="text" color="white-70" @click="$emit('close')" class="text-none px-6 rounded-lg">Fechar</v-btn>
      </div>
    </v-card>
  </v-dialog>
</template>

<script setup lang="ts">
import { format } from 'date-fns'

defineProps<{
  show: boolean
  drafts: any[]
  loading: boolean
}>()

defineEmits(['close', 'load', 'delete'])

const formatDate = (date: string) => {
    if(!date) return '-'
    return format(new Date(date), 'dd/MM HH:mm')
}

const formatCurrency = (val: number) => new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(val)
</script>

<style scoped lang="scss">
/* Glass System */
.glass-dialog { backdrop-filter: blur(4px); }
.glass-modal {
    background: rgba(30, 30, 35, 0.9);
    backdrop-filter: blur(24px);
    box-shadow: 0 24px 60px rgba(0,0,0,0.6);
    border-radius: 20px;
}
.bg-glass-header { background: rgba(255, 255, 255, 0.03); }
.bg-glass-footer { background: rgba(20, 20, 25, 0.6); }
.bg-glass-body-gradient { background: linear-gradient(to bottom, rgba(0,0,0,0.1), rgba(0,0,0,0.3)); }

/* Expansion Panels Override */
.glass-panels :deep(.v-expansion-panel-title__overlay) { opacity: 0 !important; }
.glass-panels :deep(.v-expansion-panel-text__wrapper) { padding: 0 16px 16px 16px; }
.glass-panel-item { transition: all 0.2s ease; }
.glass-panel-item:hover { border-color: rgba(255,255,255,0.15) !important; }

/* Utils */
.icon-box { width: 48px; height: 48px; border-radius: 14px; display: flex; align-items: center; justify-content: center; }
.icon-circle-large { width: 80px; height: 80px; border-radius: 50%; display: flex; align-items: center; justify-content: center; }
.bg-gradient-info { background: linear-gradient(135deg, #29b6f6, #0277bd); }

.text-white-70 { color: rgba(255,255,255,0.7) !important; }
.text-white-50 { color: rgba(255,255,255,0.5) !important; }
.text-white-30 { color: rgba(255,255,255,0.3) !important; }
.text-white-20 { color: rgba(255,255,255,0.2) !important; }

.border-white-10 { border-color: rgba(255,255,255,0.1) !important; }
.border-white-05 { border-color: rgba(255,255,255,0.05) !important; }
.bg-white-05 { background: rgba(255,255,255,0.05); }
.bg-white-10 { background: rgba(255,255,255,0.1); }
.bg-black-20 { background: rgba(0,0,0,0.2); }

.hover-bg-white-05:hover { background: rgba(255,255,255,0.05); }
.shadow-glow-primary { box-shadow: 0 0 15px rgba(var(--v-theme-primary), 0.3); }
.hover-opacity-100:hover { opacity: 1 !important; }

.custom-scrollbar::-webkit-scrollbar { width: 6px; }
.custom-scrollbar::-webkit-scrollbar-thumb { background: rgba(255,255,255,0.1); border-radius: 3px; }
.lh-1 { line-height: 1; }
.gap-2 { gap: 8px; } .gap-3 { gap: 12px; } .gap-4 { gap: 16px; }
</style>
