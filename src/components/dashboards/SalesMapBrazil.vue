<template>
  <v-card class="map-card d-flex flex-column position-relative" :class="cardClasses" variant="flat">
    <div class="px-4 py-3 border-b d-flex align-center justify-space-between flex-shrink-0" :class="borderClass">
      <div class="d-flex align-center">
        <div class="icon-box-sm mr-3 rounded-lg transition-colors" :class="isLight ? 'bg-indigo-lighten-5 text-indigo-darken-2' : 'bg-indigo-opacity-10 text-indigo'">
             <v-icon size="18">mdi-map-marker-radius</v-icon>
        </div>
        <div>
            <div class="text-subtitle-2 font-weight-bold" :class="textPrimaryClass">Performance Regional</div>
            <div class="text-[10px] opacity-60" :class="textSecondaryClass">
                Total: {{ formatMeters(totalVolume) }}
            </div>
        </div>
      </div>

      <v-btn-toggle
        :model-value="period"
        @update:model-value="$emit('update:period', $event)"
        density="compact"
        class="rounded-lg border"
        :class="isLight ? 'bg-white border-grey-lighten-2' : 'bg-transparent border-white-10'"
        divided
        mandatory
      >
        <v-btn value="month" size="x-small" class="text-[10px] font-weight-bold">Mês</v-btn>
        <v-btn value="year" size="x-small" class="text-[10px] font-weight-bold">Ano</v-btn>
        <v-btn value="all" size="x-small" class="text-[10px] font-weight-bold">Tudo</v-btn>
      </v-btn-toggle>
    </div>

    <div class="map-wrapper flex-grow-1 position-relative" style="height: 500px;">
      <div v-if="showMap" class="h-100 w-100">
        <l-map
          ref="mapRef"
          v-model:zoom="zoom"
          :center="center"
          :use-global-leaflet="false"
          :options="{ attributionControl: false, zoomControl: true, scrollWheelZoom: true }"
          :max-bounds="maxBounds"
          :min-zoom="3"
          style="height: 100%; width: 100%; z-index: 1;"
          @ready="onMapReady"
        >
          <l-tile-layer
            :key="isLight ? 'light-tiles' : 'dark-tiles'"
            :url="tileLayerUrl"
            layer-type="base"
            name="Base Map"
          ></l-tile-layer>

          <l-marker v-if="salesData.Sudoeste > 0" :lat-lng="locations.sudoeste">
            <l-icon :icon-size="[getIconSize(salesData.Sudoeste), getIconSize(salesData.Sudoeste)]" class-name="pulsing-icon-leaflet">
              <div class="pulsing-dot-leaflet" :style="{ '--pulse-color': isLight ? '#3949AB' : '#536DFE' }"></div>
            </l-icon>
            <l-tooltip :options="{ permanent: true, direction: 'top', offset: [0, -getIconSize(salesData.Sudoeste)/2], className: tooltipClass }">
              <div class="map-tooltip-content">
                <strong :class="isLight ? 'text-grey-darken-3' : 'text-grey-lighten-1'">SUDESTE</strong>
                <span :class="isLight ? 'text-indigo-darken-3' : 'text-white'">{{ formatMeters(salesData.Sudoeste) }}</span>
                <div class="percentage-badge bg-indigo-lighten-1 text-white">{{ getPercentage(salesData.Sudoeste) }}%</div>
              </div>
            </l-tooltip>
          </l-marker>

          <l-marker v-if="salesData.Nordeste > 0" :lat-lng="locations.nordeste">
             <l-icon :icon-size="[getIconSize(salesData.Nordeste), getIconSize(salesData.Nordeste)]" class-name="pulsing-icon-leaflet">
              <div class="pulsing-dot-leaflet" :style="{ '--pulse-color': isLight ? '#FB8C00' : '#FFAB40' }"></div>
            </l-icon>
            <l-tooltip :options="{ permanent: true, direction: 'top', offset: [0, -getIconSize(salesData.Nordeste)/2], className: tooltipClass }">
              <div class="map-tooltip-content">
                <strong :class="isLight ? 'text-grey-darken-3' : 'text-grey-lighten-1'">NORDESTE</strong>
                <span :class="isLight ? 'text-orange-darken-3' : 'text-white'">{{ formatMeters(salesData.Nordeste) }}</span>
                <div class="percentage-badge bg-orange text-white">{{ getPercentage(salesData.Nordeste) }}%</div>
              </div>
            </l-tooltip>
          </l-marker>
        </l-map>

        <div class="map-overlay-legend pa-2 rounded-lg elevation-2 d-flex flex-column gap-2" :class="isLight ? 'bg-white/90' : 'bg-black/60'">
            <div class="d-flex align-center gap-2">
                <div class="legend-dot bg-indigo"></div>
                <div class="text-[10px] font-weight-bold" :class="textPrimaryClass">Sudeste</div>
            </div>
            <div class="d-flex align-center gap-2">
                <div class="legend-dot bg-orange"></div>
                <div class="text-[10px] font-weight-bold" :class="textPrimaryClass">Nordeste</div>
            </div>
        </div>
      </div>

      <div v-else class="fill-height d-flex align-center justify-center text-caption opacity-50 bg-grey-lighten-4 w-100 h-100 position-absolute top-0 left-0">
        <v-progress-circular indeterminate color="primary" size="24" class="mr-2"></v-progress-circular>
        Carregando mapa...
      </div>
    </div>
  </v-card>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, nextTick } from 'vue';
import "leaflet/dist/leaflet.css";
import { LMap, LTileLayer, LMarker, LTooltip, LIcon } from "@vue-leaflet/vue-leaflet";
import { useThemeStore } from '@/stores/theme';

const props = defineProps<{
  salesData: { Sudoeste: number; Nordeste: number };
  period: string;
}>();

const emit = defineEmits(['update:period']);

const themeStore = useThemeStore();
const isLight = computed(() => themeStore.currentMode === 'light');

// Estilos
const cardClasses = computed(() => isLight.value ? 'bg-white shadow-soft' : 'glass-panel');
const borderClass = computed(() => isLight.value ? 'border-grey-lighten-2' : 'border-white-05');
const textPrimaryClass = computed(() => isLight.value ? 'text-grey-darken-4' : 'text-white');
const textSecondaryClass = computed(() => isLight.value ? 'text-grey-darken-1' : 'text-grey-lighten-1');
const tooltipClass = computed(() => isLight.value ? 'leaflet-tooltip-light' : 'leaflet-tooltip-dark');

const tileLayerUrl = computed(() => isLight.value
    ? 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager_nolabels/{z}/{x}/{y}{r}.png'
    : 'https://{s}.basemaps.cartocdn.com/dark_nolabels/{z}/{x}/{y}{r}.png'
);

const mapRef = ref(null);
const showMap = ref(false);
const zoom = ref(3.8);
const center = ref([-14.2, -51.9]);
const maxBounds = ref([[-33.75, -73.98], [5.27, -32.38]]);

const locations = { sudoeste: [-23.5505, -46.6333], nordeste: [-7.9556, -36.2044] };
const totalVolume = computed(() => (props.salesData.Sudoeste || 0) + (props.salesData.Nordeste || 0));

const getIconSize = (regionValue: number) => {
  if (totalVolume.value === 0) return 30;
  const percentage = (regionValue / totalVolume.value);
  return 30 + (percentage * 50); // Min 30px, Max 80px
};

const getPercentage = (val: number) => {
    if(!totalVolume.value) return 0;
    return Math.round((val / totalVolume.value) * 100);
}

const formatMeters = (value: number) => {
    if (!value) return "0m";
    if (value >= 1000) return `${(value / 1000).toFixed(1)}km`;
    return `${Number(value.toFixed(0)).toLocaleString('pt-BR')}m`;
};

const onMapReady = async () => {
  await nextTick();
  setTimeout(() => {
    if (mapRef.value && (mapRef.value as any).leafletObject) {
      (mapRef.value as any).leafletObject.invalidateSize();
    }
  }, 200);
};

onMounted(() => { setTimeout(() => { showMap.value = true; }, 300); });
</script>

<style lang="scss">
.map-card { border-radius: 16px; overflow: hidden; min-height: 500px; }
.map-wrapper { background-color: transparent; }

/* Tooltips */
.leaflet-tooltip-dark {
  background-color: rgba(30, 31, 49, 0.9) !important;
  backdrop-filter: blur(8px);
  border: 1px solid rgba(255,255,255,0.1);
  color: white;
  border-radius: 8px;
  padding: 8px !important;
}
.leaflet-tooltip-light {
  background-color: rgba(255, 255, 255, 0.95) !important;
  backdrop-filter: blur(8px);
  border: 1px solid rgba(0,0,0,0.1);
  color: #333;
  border-radius: 8px;
  padding: 8px !important;
  box-shadow: 0 4px 15px rgba(0,0,0,0.1);
}
.leaflet-tooltip-top::before { display: none; }

.map-tooltip-content {
  display: flex; flex-direction: column; align-items: center; white-space: nowrap;
  strong { font-size: 0.7rem; font-weight: 700; margin-bottom: 2px; }
  span { font-size: 0.9rem; font-weight: 800; margin-bottom: 4px; }
}
.percentage-badge {
    font-size: 0.65rem; font-weight: bold; padding: 2px 6px; border-radius: 4px;
}

/* Pulsing Icon */
.pulsing-icon-leaflet .pulsing-dot-leaflet {
  width: 100%; height: 100%;
  background-color: var(--pulse-color);
  border-radius: 50%; position: relative;
  box-shadow: 0 0 15px var(--pulse-color);
  opacity: 0.9;
  border: 2px solid rgba(255,255,255,0.8);
  &::before {
    content: ''; position: absolute; inset: -4px; border-radius: 50%;
    background-color: var(--pulse-color);
    animation: map-pulse 2s infinite;
    z-index: -1; opacity: 0.6;
  }
}
@keyframes map-pulse {
  0% { transform: scale(0.9); opacity: 0.6; }
  70% { transform: scale(2.0); opacity: 0; }
  100% { transform: scale(0.9); opacity: 0; }
}

/* Legend Overlay */
.map-overlay-legend {
    position: absolute; bottom: 20px; left: 20px; z-index: 1000;
    pointer-events: none;
    border: 1px solid rgba(255,255,255,0.1);
    backdrop-filter: blur(4px);
}
.legend-dot { width: 8px; height: 8px; border-radius: 50%; }
</style>
