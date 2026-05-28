<template>
  <div class="custom-chart-wrapper relative" style="width: 100%; height: 100%;">
    <apexchart
        v-if="loaded && data.series && data.series.length > 0"
        ref="chartRef"
        type="bar"
        height="100%"
        width="100%"
        :options="chartOptions"
        :series="computedSeries"
    ></apexchart>

    <div v-else class="absolute inset-0 d-flex align-center justify-center bg-glass-overlay">
        <v-progress-circular indeterminate color="primary"></v-progress-circular>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, ref, onMounted } from 'vue';
import VueApexCharts from 'vue3-apexcharts';

const props = defineProps({
    data: { type: Object, required: true },
});

const emit = defineEmits(['bar-click']);
const loaded = ref(false);

const chartOptions = computed(() => ({
    chart: {
        type: 'bar',
        toolbar: { show: false },
        fontFamily: 'Roboto, sans-serif',
        background: 'transparent',
        events: {
            dataPointSelection: (event: any, chartContext: any, config: any) => {
                emit('bar-click', config.dataPointIndex);
            }
        },
        animations: { enabled: true }
    },
    theme: { mode: 'dark' },
    plotOptions: {
        bar: { borderRadius: 4, columnWidth: '40%', distributed: false, dataLabels: { position: 'top' } }
    },
    dataLabels: { enabled: false },
    xaxis: {
        categories: props.data.categories || [],
        axisBorder: { show: false },
        axisTicks: { show: false },
        labels: { style: { colors: 'rgba(255,255,255,0.5)', fontSize: '11px', fontWeight: 600, fontFamily: 'Roboto Mono' } },
        tooltip: { enabled: false }
    },
    yaxis: { show: true, labels: { style: { colors: 'rgba(255,255,255,0.3)', fontSize: '10px' } }, grid: { show: true } },
    grid: { show: true, borderColor: 'rgba(255,255,255,0.03)', strokeDashArray: 4, padding: { top: 0, right: 0, bottom: 0, left: 10 } },
    colors: ['#40C4FF'],
    fill: { type: 'gradient', gradient: { shade: 'dark', type: 'vertical', shadeIntensity: 0.5, inverseColors: false, opacityFrom: 1, opacityTo: 0.6, stops: [0, 100] } },
    legend: { show: false },
    tooltip: { theme: 'dark', style: { fontSize: '12px' }, y: { formatter: (val: number) => `${val} Artes` }, marker: { show: true } },
}));

const computedSeries = computed(() => props.data.series || []);

onMounted(() => {
    // Delay para garantir DOM
    setTimeout(() => {
        loaded.value = true;
    }, 300);
});
</script>

<style scoped>
.bg-glass-overlay { background: rgba(0,0,0,0.1); backdrop-filter: blur(2px); }
</style>
