<template>
  <v-card class="kpi-card glassmorphism-card" elevation="0">
    <div class="d-flex justify-space-between align-start">
      <div class="kpi-title">{{ title }}</div>
      <div class="kpi-change" :class="changeColor">
        <v-icon size="small">{{ changeIcon }}</v-icon>
        <span>{{ changeText }}</span>
      </div>
    </div>

    <div class="d-flex align-end mt-2">
      <div class="kpi-value-a">
        {{ formatValue(valueA) }}
      </div>
      <div class="kpi-value-b text-medium-emphasis">
        vs {{ formatValue(valueB) }}
      </div>
    </div>

    <apexchart
      v-if="sparklineSeries"
      type="area"
      height="50"
      :options="sparklineOptions"
      :series="sparklineSeries"
    ></apexchart>
  </v-card>
</template>

<script setup lang="ts">
import { computed } from 'vue';
import VueApexCharts from 'vue3-apexcharts';

// Importa o componente ApexCharts
const apexchart = VueApexCharts;

const props = defineProps<{
  title: string;
  valueA: number;
  valueB: number;
  format?: 'currency' | 'decimal' | 'integer';
  sparklineData?: { day: string, total_revenue: number }[];
}>();

const formatValue = (value: number): string => {
  if (props.format === 'currency') {
    return new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(value || 0);
  }
  if (props.format === 'decimal') {
    return (value || 0).toFixed(2);
  }
  return new Intl.NumberFormat('pt-BR').format(value || 0);
};

const change = computed(() => {
  if (props.valueB === 0) {
    return props.valueA > 0 ? Infinity : 0; // Crescimento infinito se saiu de 0
  }
  if (isNaN(props.valueB) || isNaN(props.valueA)) return 0;
  return ((props.valueA - props.valueB) / props.valueB);
});

const changeText = computed(() => {
  if (change.value === Infinity) return 'Novo';
  if (isNaN(change.value)) return 'N/A';
  return `${(change.value * 100).toFixed(1)}%`;
});

const changeIcon = computed(() => {
  if (change.value > 0) return 'mdi-arrow-up-thin';
  if (change.value < 0) return 'mdi-arrow-down-thin';
  return 'mdi-minus';
});

const changeColor = computed(() => {
  if (change.value > 0) return 'text-success';
  if (change.value < 0) return 'text-error';
  return 'text-medium-emphasis';
});

// --- Configuração do Sparkline ---
const sparklineSeries = computed(() => {
  if (!props.sparklineData) return null;
  return [{
    name: props.title,
    data: props.sparklineData.map(d => d.total_revenue.toFixed(2))
  }];
});

const sparklineColor = computed(() => change.value >= 0 ? '#00E396' : '#FF4560');

const sparklineOptions = computed(() => ({
  chart: {
    type: 'area',
    height: 50,
    sparkline: { enabled: true },
  },
  stroke: {
    curve: 'smooth',
    width: 2,
  },
  fill: {
    type: 'gradient',
    gradient: {
      opacityFrom: 0.4,
      opacityTo: 0,
    }
  },
  colors: [sparklineColor.value],
  tooltip: {
    theme: 'dark',
    x: {
      formatter: (val: number, opts: any) => {
        return props.sparklineData ? props.sparklineData[opts.dataPointIndex].day : '';
      },
    },
    y: {
      formatter: (val: number) => formatValue(val),
      title: {
        formatter: () => '',
      },
    },
  },
}));

</script>

<style scoped lang="scss">
.kpi-card {
  padding: 16px;
  border-radius: 12px;
  height: 100%;
}
/* Estilo Glassmorphism (herdado do Admin.vue) */
.glassmorphism-card {
  background-color: rgba(30, 31, 49, 0.7) !important;
  backdrop-filter: blur(10px) saturate(150%);
  border: 1px solid rgba(255, 255, 255, 0.1);
}
.kpi-title {
  font-weight: 600;
  color: #B0BEC5;
  font-size: 0.9rem;
}
.kpi-value-a {
  font-size: 1.75rem;
  font-weight: 700;
  line-height: 1.2;
  color: #fff;
}
.kpi-value-b {
  font-size: 0.9rem;
  font-weight: 500;
  margin-left: 8px;
  line-height: 1;
}
.kpi-change {
  font-size: 1rem;
  font-weight: 700;
}
</style>
