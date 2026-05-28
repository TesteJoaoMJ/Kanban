<template>
  <v-dialog
    v-model="appStore.showConsolidatedStockModal"
    max-width="1000"
    persistent
    transition="dialog-bottom-transition"
  >
    <v-card
      class="rounded-lg shadow-lg border overflow-hidden d-flex flex-column"
      :class="isDark ? 'bg-grey-darken-4 border-grey-darken-3' : 'bg-white border-grey-lighten-2'"
      style="max-height: 85vh;"
    >
      <div
        class="d-flex align-center px-6 py-5 border-b flex-shrink-0"
        :class="isDark ? 'bg-grey-darken-4 border-grey-darken-3' : 'bg-grey-lighten-5 border-grey-lighten-2'"
      >
        <v-avatar :color="isDark ? 'error-darken-3' : 'error-lighten-4'" size="48" class="mr-4 rounded-lg">
          <v-icon color="error" size="28">mdi-alert-decagram-outline</v-icon>
        </v-avatar>

        <div>
          <h2 class="text-h5 font-weight-bold mb-0 tracking-tight" :class="isDark ? 'text-white' : 'text-grey-darken-4'">
            Ruptura de Estoque Detectada
          </h2>
          <div class="text-body-2 mt-1" :class="isDark ? 'text-grey-lighten-1' : 'text-grey-darken-1'">
            <strong class="text-error font-weight-bold">{{ appStore.consolidatedLowStockItems.length }}</strong> materiais operam abaixo da margem de segurança.
          </div>
        </div>

        <v-spacer></v-spacer>

        <v-btn icon variant="plain" density="comfortable" @click="closeModal" color="grey-darken-1">
          <v-icon>mdi-close</v-icon>
        </v-btn>
      </div>

      <div
        class="d-none d-md-grid px-6 py-3 border-b text-caption font-weight-bold text-uppercase letter-spacing-1 opacity-80"
        :class="isDark ? 'bg-grey-darken-3 border-grey-darken-3 text-grey-lighten-1' : 'bg-grey-lighten-4 border-grey-lighten-2 text-grey-darken-2'"
        style="grid-template-columns: 2fr 1fr 2fr 1.5fr; gap: 16px;"
      >
        <div>Material</div>
        <div>Identificação</div>
        <div>Nível de Estoque</div>
        <div class="text-right">Última Movimentação</div>
      </div>

      <div class="flex-grow-1 overflow-y-auto custom-scrollbar position-relative" style="background-color: inherit;">

        <v-overlay
          :model-value="loadingUsages"
          contained
          class="align-center justify-center"
          scrim="black"
          :opacity="isDark ? 0.7 : 0.05"
          z-index="5"
        >
          <div class="d-flex flex-column align-center">
             <v-progress-circular indeterminate color="primary" size="40" width="3" class="mb-3"></v-progress-circular>
             <span class="text-caption font-weight-medium text-primary text-uppercase letter-spacing-1">Consultando histórico...</span>
          </div>
        </v-overlay>

        <div
          v-for="(item, index) in appStore.consolidatedLowStockItems"
          :key="index"
          class="stock-row px-6 py-4 border-b transition-all align-start align-md-center"
          :class="isDark ? 'border-grey-darken-3 hover-bg-dark' : 'border-grey-lighten-2 hover-bg-light'"
        >
          <div class="d-flex align-center overflow-hidden w-100">
            <v-avatar size="36" :color="isDark ? 'grey-darken-3' : 'grey-lighten-3'" class="rounded border mr-3" :class="isDark ? 'border-grey-darken-2' : 'border-grey-lighten-2'">
              <v-icon size="18" :color="isDark ? 'error-lighten-2' : 'error-darken-1'">
                {{ item.fabric_type?.startsWith('CJ') ? 'mdi-fruit-cherries' : 'mdi-texture-box' }}
              </v-icon>
            </v-avatar>
            <div class="text-truncate font-weight-medium text-body-2" :class="isDark ? 'text-white' : 'text-grey-darken-4'" :title="item.fabric_type">
              {{ item.fabric_type }}
            </div>
          </div>

          <div class="w-100 d-flex flex-column gap-1 mt-2 mt-md-0">
            <div class="text-caption font-mono" :class="isDark ? 'text-grey-lighten-1' : 'text-grey-darken-3'">
              <span class="opacity-60 mr-1">ID:</span>{{ item.gestao_click_id || 'LOCAL' }}
            </div>
            <div v-if="item.barcode" class="text-caption font-mono" :class="isDark ? 'text-grey-lighten-1' : 'text-grey-darken-3'">
              <span class="opacity-60 mr-1">EAN:</span>{{ item.barcode }}
            </div>
          </div>

          <div class="w-100 mt-3 mt-md-0 pr-md-4">
            <div class="d-flex justify-space-between text-caption mb-1 font-mono">
              <span class="text-error font-weight-bold">{{ formatNumber(item.available_meters) }} <span class="opacity-70 font-weight-regular">{{ item.unit_of_measure }}</span></span>
              <span class="opacity-60">Mín: {{ formatNumber(item.low_stock_threshold) }} {{ item.unit_of_measure }}</span>
            </div>
            <v-progress-linear
              :model-value="getPercentage(item.available_meters, item.low_stock_threshold)"
              color="error"
              height="6"
              rounded
              :class="isDark ? 'bg-grey-darken-3' : 'bg-grey-lighten-3'"
            ></v-progress-linear>
          </div>

          <div class="w-100 text-md-right text-caption d-flex flex-column justify-center align-md-end mt-3 mt-md-0">
            <template v-if="lastUsages[item.fabric_type]">
              <div class="d-flex align-center justify-md-end gap-1 mb-1">
                <v-icon size="14" color="primary" class="opacity-70">mdi-text-box-search-outline</v-icon>
                <span :class="isDark ? 'text-grey-lighten-2' : 'text-grey-darken-3'">
                  Pedido <strong class="font-mono text-primary">#{{ lastUsages[item.fabric_type].order }}</strong>
                </span>
              </div>
              <div class="opacity-60 font-weight-medium" :class="isDark ? 'text-grey-lighten-3' : 'text-grey-darken-1'">
                {{ lastUsages[item.fabric_type].date }}
              </div>
            </template>
            <template v-else>
              <div class="opacity-50 font-italic d-flex align-center justify-md-end">
                <v-icon size="14" class="mr-1">mdi-history</v-icon>
                Sem registros
              </div>
            </template>
          </div>
        </div>
      </div>

      <div
        class="px-6 py-4 border-t d-flex flex-column flex-sm-row align-sm-center justify-space-between gap-3 flex-shrink-0 z-10"
        :class="isDark ? 'bg-grey-darken-4 border-grey-darken-3' : 'bg-grey-lighten-5 border-grey-lighten-2'"
      >
        <div class="text-caption d-flex align-center" :class="isDark ? 'text-grey-lighten-2 opacity-70' : 'text-grey-darken-2 opacity-80'">
          <v-icon size="16" class="mr-2">mdi-bell-sleep-outline</v-icon>
          Silenciado nas próximas <strong class="ml-1 text-primary">{{ appStore.lowStockSettings.intervalValue }} {{ getUnitLabel(appStore.lowStockSettings.intervalUnit) }}</strong>.
        </div>

        <v-btn
          color="primary"
          variant="flat"
          class="text-none font-weight-bold px-6 rounded-md letter-spacing-1"
          @click="closeModal"
          :block="$vuetify.display.xs"
        >
          Estou Ciente
        </v-btn>
      </div>
    </v-card>
  </v-dialog>
</template>

<script setup lang="ts">
import { ref, watch, computed } from 'vue';
import { useAppStore } from '@/stores/app';
import { useThemeStore } from '@/stores/theme';
import { supabase } from '@/api/supabase';
import { formatDistanceToNow } from 'date-fns';
import { ptBR } from 'date-fns/locale';

const appStore = useAppStore();
const themeStore = useThemeStore();

const isDark = computed(() => themeStore.currentMode !== 'light');

const lastUsages = ref<Record<string, any>>({});
const loadingUsages = ref(false);

const formatNumber = (val: any) => {
  const num = Number(val);
  return isNaN(num) ? '0' : num.toLocaleString('pt-BR', { maximumFractionDigits: 2 });
};

const getPercentage = (current: number, min: number) => {
    if (!min || min === 0) return 0;
    const perc = (current / min) * 100;
    return perc > 100 ? 100 : (perc < 0 ? 0 : perc);
};

const getUnitLabel = (unit: string) => {
    if (unit === 'seconds') return 'segundos';
    if (unit === 'minutes') return 'minutos';
    return 'horas';
};

const fetchLastUsages = async () => {
    loadingUsages.value = true;
    try {
        const itemsToFetch = appStore.consolidatedLowStockItems.map(i => i.fabric_type);

        for (const fabric of itemsToFetch) {
            // CORREÇÃO APLICADA AQUI: quantity substituído por quantity_unit
            const { data, error } = await supabase
                .from('order_items')
                .select('quantity_meters, quantity_unit, unit_of_measure, orders!inner(order_number, created_at)')
                .eq('fabric_type', fabric)
                .order('created_at', { ascending: false })
                .limit(1)
                .maybeSingle();

            if (error) {
                console.warn(`Aviso ao buscar histórico do tecido: ${fabric}`, error.message);
                continue;
            }

            if (data && data.orders) {
                // CORREÇÃO APLICADA AQUI: usar quantity_unit no fallback
                const qtyUsed = data.quantity_meters || data.quantity_unit || 0;
                lastUsages.value[fabric] = {
                    qty: formatNumber(qtyUsed),
                    order: data.orders.order_number,
                    date: formatDistanceToNow(new Date(data.orders.created_at), { addSuffix: true, locale: ptBR })
                };
            }
        }
    } catch (e) {
        console.error("Erro ao buscar histórico de consumo do estoque:", e);
    } finally {
        loadingUsages.value = false;
    }
};

watch(() => appStore.showConsolidatedStockModal, (newVal) => {
    if (newVal) {
        lastUsages.value = {};
        fetchLastUsages();
    }
});

const closeModal = () => {
  appStore.showConsolidatedStockModal = false;
};
</script>

<style scoped>
/* Fontes e Tipografia */
.font-mono { font-family: 'JetBrains Mono', 'Fira Code', Consolas, monospace; }
.letter-spacing-1 { letter-spacing: 0.5px !important; }
.tracking-tight { letter-spacing: -0.5px !important; }

/* Grid responsivo da tabela */
.stock-row {
    display: flex;
    flex-direction: column;
    gap: 8px;
}

@media (min-width: 960px) {
    .stock-row {
        display: grid;
        grid-template-columns: 2fr 1fr 2fr 1.5fr;
        gap: 16px;
    }
}

/* Scrollbar invisível mas funcional */
.custom-scrollbar::-webkit-scrollbar { width: 6px; }
.custom-scrollbar::-webkit-scrollbar-track { background: transparent; }
.custom-scrollbar::-webkit-scrollbar-thumb { background: rgba(128, 128, 128, 0.2); border-radius: 10px; }
.custom-scrollbar::-webkit-scrollbar-thumb:hover { background: rgba(128, 128, 128, 0.4); }

/* Efeitos de Hover (Enterprise Subtle) */
.transition-all { transition: all 0.2s ease-in-out; }
.hover-bg-light:hover { background-color: #f9fafb !important; }
.hover-bg-dark:hover { background-color: #1e1e1e !important; }

/* Utilities */
.w-100 { width: 100%; }
.gap-1 { gap: 4px; }
.gap-3 { gap: 12px; }
.z-10 { z-index: 10; }
</style>
