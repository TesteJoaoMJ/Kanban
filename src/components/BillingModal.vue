<template>
  <v-dialog :model-value="show" max-width="800px" persistent scrollable>
    <v-card
      :class="isLightMode ? 'bg-white text-grey-darken-4' : 'glassmorphism-card-dialog text-white'"
      class="rounded-xl overflow-hidden"
    >
      <v-toolbar
        :color="isLightMode ? 'grey-lighten-5' : 'transparent'"
        class="px-2"
        :class="isLightMode ? 'border-b border-grey-lighten-2' : ''"
        density="compact"
      >
        <v-toolbar-title class="font-weight-bold text-body-2 text-uppercase letter-spacing-1">
            <v-icon start size="18" :color="isLightMode ? 'primary' : 'white'" class="mr-2">mdi-invoice-text-outline</v-icon>
            Faturar Pedido #{{ String(order?.order_number || '---').padStart(4, '0') }}
        </v-toolbar-title>
        <v-spacer></v-spacer>
        <v-btn icon size="small" variant="text" :color="isLightMode ? 'grey-darken-1' : 'white'" @click="$emit('close')">
            <v-icon>mdi-close</v-icon>
        </v-btn>
      </v-toolbar>

      <v-card-text v-if="order" class="pa-0">
        <div class="px-6 py-4" :class="isLightMode ? 'bg-white' : ''">
           <div class="d-flex align-center gap-3 pa-3 rounded-lg border-thin"
                :class="isLightMode ? 'bg-blue-lighten-5 border-blue-lighten-4 text-blue-darken-3' : 'bg-white-05 border-white-10'">
               <v-icon :color="isLightMode ? 'blue-darken-2' : 'white-70'">mdi-information-outline</v-icon>
               <p class="text-caption mb-0">
                 Ajuste as metragens finais produzidas para cada item do cliente <strong>{{ order.customer_name }}</strong>. Estes valores gerarão a fatura final.
               </p>
           </div>
        </div>

        <div v-if="editableItems.length > 0">
          <v-table density="compact" class="billing-table bg-transparent">
            <thead>
              <tr :class="isLightMode ? 'bg-grey-lighten-4 text-grey-darken-2' : 'text-white-50'">
                <th class="text-left font-weight-bold text-[10px] text-uppercase py-2 pl-6">Estampa (Ref.)</th>
                <th class="text-left font-weight-bold text-[10px] text-uppercase py-2">Produto (Base)</th>
                <th class="text-center font-weight-bold text-[10px] text-uppercase py-2">Qtd. Pedida</th>
                <th class="text-center font-weight-bold text-[10px] text-uppercase py-2 pr-6" style="width: 180px;">Qtd. Faturada</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="(item, index) in editableItems" :key="item.id"
                  class="transition-colors"
                  :class="[
                    isLightMode
                        ? (index % 2 === 0 ? 'bg-white' : 'bg-grey-lighten-5')
                        : 'hover-bg-glass'
                  ]"
              >
                <td class="text-caption font-weight-bold pl-6 py-3" :class="isLightMode ? 'text-grey-darken-3' : 'text-white'">
                    {{ item.stamp_ref || '---' }}
                </td>
                <td class="text-caption" :class="isLightMode ? 'text-grey-darken-2' : 'text-white-70'">
                    {{ item.fabric_type || 'Padrão' }}
                </td>
                <td class="text-center text-caption font-mono" :class="isLightMode ? 'text-grey-darken-3' : 'text-white'">
                    {{ item.quantity_meters }}m
                </td>
                <td class="pr-6 py-2">
                  <v-text-field
                    v-model.number="item.billed_quantity"
                    type="number"
                    variant="outlined"
                    density="compact"
                    hide-details
                    class="tiny-input"
                    :bg-color="isLightMode ? 'white' : 'rgba(0,0,0,0.2)'"
                    :color="isLightMode ? 'primary' : 'white'"
                    suffix="m"
                  ></v-text-field>
                </td>
              </tr>
            </tbody>
          </v-table>
        </div>

        <div v-else class="d-flex flex-column align-center justify-center py-12 text-grey">
            <v-icon size="48" class="mb-2 opacity-50">mdi-alert-circle-outline</v-icon>
            <p class="text-caption font-weight-bold text-uppercase opacity-70">Nenhum item faturável encontrado</p>
        </div>
      </v-card-text>

      <v-divider :class="isLightMode ? 'border-grey-lighten-2' : 'border-white-10'"></v-divider>

      <v-card-actions class="pa-4" :class="isLightMode ? 'bg-grey-lighten-5' : ''">
        <v-spacer></v-spacer>
        <v-btn
            variant="text"
            size="small"
            class="text-caption font-weight-bold px-4"
            :color="isLightMode ? 'grey-darken-2' : 'white-70'"
            @click="$emit('close')"
        >
            Cancelar
        </v-btn>
        <v-btn
          color="success"
          variant="flat"
          size="small"
          class="text-caption font-weight-bold px-4"
          :class="isLightMode ? 'shadow-sm' : 'shadow-glow-success'"
          @click="saveBilling"
          :loading="isSaving"
          :disabled="editableItems.length === 0"
        >
          <v-icon start size="16">mdi-check-all</v-icon>
          Confirmar Faturamento
        </v-btn>
      </v-card-actions>
    </v-card>
  </v-dialog>
</template>

<script setup lang="ts">
import { ref, watch, computed } from 'vue';
import { supabase } from '@/api/supabase';
import type { Order, OrderItem } from '@/types';
import { useThemeStore } from '@/stores/theme';

const props = defineProps<{
  show: boolean;
  order: Order | null;
}>();

const emit = defineEmits(['close', 'billed']);
const themeStore = useThemeStore();
const isLightMode = computed(() => themeStore.currentMode === 'light');

const isSaving = ref(false);
const editableItems = ref<Partial<OrderItem>[]>([]);

watch(() => props.order, (newOrder) => {
  if (newOrder && newOrder.order_items) {
    // Cria uma cópia editável dos itens para o formulário
    editableItems.value = newOrder.order_items.map(item => ({
      ...item,
      // Preenche o valor a faturar com o valor original se ainda não tiver sido faturado
      billed_quantity: item.billed_quantity ?? item.quantity_meters
    }));
  } else {
    editableItems.value = [];
  }
}, { immediate: true, deep: true });

const saveBilling = async () => {
  if (!props.order) return;
  isSaving.value = true;
  try {
    const updates = editableItems.value.map(item =>
      supabase
        .from('order_items')
        .update({ billed_quantity: item.billed_quantity })
        .eq('id', item.id)
    );

    await Promise.all(updates);

    const { error: orderUpdateError } = await supabase
      .from('orders')
      .update({ billed_at: new Date().toISOString() })
      .eq('id', props.order.id);

    if (orderUpdateError) throw orderUpdateError;

    emit('billed');
  } catch (error: any) {
    console.error('Erro ao faturar o pedido:', error);
    // Idealmente usar appStore.showSnackbar aqui se disponível
  } finally {
    isSaving.value = false;
  }
};
</script>

<style scoped lang="scss">
/* Dark Mode Styles */
.glassmorphism-card-dialog {
  backdrop-filter: blur(24px) !important;
  background-color: rgba(20, 20, 25, 0.95) !important;
  border: 1px solid rgba(255, 255, 255, 0.08) !important;
}

.bg-white-05 { background-color: rgba(255,255,255,0.05); }
.border-white-10 { border: 1px solid rgba(255,255,255,0.1); }
.text-white-70 { color: rgba(255,255,255,0.7); }
.text-white-50 { color: rgba(255,255,255,0.5); }
.hover-bg-glass:hover { background-color: rgba(255,255,255,0.03); }

/* Light Mode Styles */
.bg-grey-lighten-5 { background-color: #f8fafc !important; }
.bg-blue-lighten-5 { background-color: #eff6ff !important; }
.border-blue-lighten-4 { border: 1px solid #dbeafe !important; }
.border-grey-lighten-2 { border-color: #e2e8f0 !important; }
.border-thin { border-width: 1px; border-style: solid; }
.shadow-sm { box-shadow: 0 1px 2px 0 rgba(0, 0, 0, 0.05); }

/* Utilities */
.gap-3 { gap: 12px; }
.letter-spacing-1 { letter-spacing: 0.5px; }

/* Table Adjustments */
.billing-table {
    :deep(th) { font-size: 10px !important; letter-spacing: 1px; }
    :deep(td) { font-size: 11px !important; }
}

/* Input overrides for density */
.tiny-input :deep(.v-field__input) {
    font-size: 11px;
    padding-top: 6px;
    padding-bottom: 6px;
    min-height: 32px;
}
.tiny-input :deep(.v-field__suffix) {
    font-size: 10px;
    opacity: 0.7;
    padding-top: 8px;
}
</style>
