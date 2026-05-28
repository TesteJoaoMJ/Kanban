<template>
  <v-dialog
    v-model="dialog"
    fullscreen
    persistent
    transition="dialog-bottom-transition"
    class="fixed-dialog"
  >
    <v-card
      class="d-flex flex-column rounded-0 border-0"
      style="height: 100vh; overflow: hidden; width: 100vw;"
      :class="isLight ? 'bg-grey-lighten-4 text-grey-darken-4' : 'bg-background-dark text-white'"
    >
      <div
        class="px-4 py-3 d-flex align-center justify-space-between flex-shrink-0"
        :class="isLight ? 'bg-white border-b border-grey-lighten-2' : 'bg-surface border-b border-white-05'"
      >
        <div class="d-flex align-center gap-3">
            <v-avatar size="42" class="rounded-0 border-thin elevation-1">
                <v-img :src="user?.avatar_url || '/placeholder.png'" cover></v-img>
            </v-avatar>
            <div class="d-flex flex-column justify-center">
                <div class="d-flex align-center gap-2">
                    <span class="text-subtitle-1 font-weight-black leading-none text-uppercase tracking-tight" :class="isLight ? 'text-grey-darken-4' : 'text-white'">
                        {{ user?.full_name ?? 'Carregando...' }}
                    </span>
                    <v-chip v-if="user?.status" size="x-small" :color="getStatusColor(user.status)" variant="flat" class="font-weight-bold text-uppercase rounded-0">
                        {{ user.status }}
                    </v-chip>
                </div>
                <span class="text-[10px] font-weight-bold opacity-60 text-uppercase letter-spacing-1 mt-1">
                    {{ user?.role || 'Monitoramento' }}
                </span>
            </div>
        </div>

        <v-btn icon="mdi-close" variant="text" :color="isLight ? 'grey-darken-2' : 'white'" @click="closeModal"></v-btn>
      </div>

      <div class="flex-shrink-0 border-b" :class="isLight ? 'bg-white border-grey-lighten-2 shadow-sm' : 'bg-surface-variant border-white-05'">
         <v-tabs
            v-model="activeMenu"
            :color="isLight ? 'success' : 'success'"
            align-tabs="start"
            density="compact"
            show-arrows
            class="font-weight-bold"
         >
            <v-tab value="overview" class="text-caption text-uppercase font-weight-black"><v-icon start size="16">mdi-chart-pie</v-icon> Visão Geral</v-tab>
            <v-tab value="activityLog" class="text-caption text-uppercase font-weight-black"><v-icon start size="16">mdi-format-list-bulleted</v-icon> Registros</v-tab>
            <v-tab value="screenshots" class="text-caption text-uppercase font-weight-black"><v-icon start size="16">mdi-monitor-screenshot</v-icon> Galeria</v-tab>
            <v-tab value="stream" class="text-caption text-uppercase font-weight-black"><v-icon start size="16">mdi-monitor-eye</v-icon> Ao Vivo</v-tab>
         </v-tabs>
      </div>

      <div class="flex-grow-1 overflow-y-auto custom-scroll relative w-100">
        <v-window v-model="activeMenu" class="h-100" :touch="false" :transition="false" :reverse-transition="false">

          <v-window-item value="overview" class="h-100">
            <div v-if="user" class="pa-4 pa-md-6 d-flex flex-column gap-4 gap-md-6 min-h-100">

              <v-row dense class="ma-0">
                <v-col cols="12" md="4" class="pa-1">
                  <v-card class="kpi-card kpi-rect bg-gradient-green hover-elevate py-3 px-4" elevation="2">
                    <div class="kpi-bg-icon"><v-icon>mdi-check-circle</v-icon></div>
                    <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                      <div class="d-flex align-center justify-space-between">
                        <div class="d-flex align-center" style="gap: 8px;">
                          <v-icon size="18" class="opacity-80">mdi-check-circle-outline</v-icon>
                          <span class="kpi-label">TEMPO PRODUTIVO</span>
                        </div>
                        <span class="text-caption font-weight-bold opacity-80 bg-black-20 px-2 py-0.5">{{ getPercentage(user.today_productive_seconds, totalDailyTime).toFixed(0) }}%</span>
                      </div>
                      <div class="text-h4 font-weight-black my-1">{{ formatTime(user.today_productive_seconds) }}</div>
                      <div class="kpi-footer mt-1 opacity-80">MÉTRICA DE HOJE</div>
                    </div>
                  </v-card>
                </v-col>

                <v-col cols="12" md="4" class="pa-1">
                  <v-card class="kpi-card kpi-rect bg-gradient-red hover-elevate py-3 px-4" elevation="2">
                    <div class="kpi-bg-icon"><v-icon>mdi-alert-circle</v-icon></div>
                    <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                      <div class="d-flex align-center justify-space-between">
                        <div class="d-flex align-center" style="gap: 8px;">
                          <v-icon size="18" class="opacity-80">mdi-alert-circle-outline</v-icon>
                          <span class="kpi-label">TEMPO IMPRODUTIVO</span>
                        </div>
                        <span class="text-caption font-weight-bold opacity-80 bg-black-20 px-2 py-0.5">{{ getPercentage(user.today_unproductive_seconds, totalDailyTime).toFixed(0) }}%</span>
                      </div>
                      <div class="text-h4 font-weight-black my-1">{{ formatTime(user.today_unproductive_seconds) }}</div>
                      <div class="kpi-footer mt-1 opacity-80">MÉTRICA DE HOJE</div>
                    </div>
                  </v-card>
                </v-col>

                <v-col cols="12" md="4" class="pa-1">
                  <v-card class="kpi-card kpi-rect bg-gradient-info hover-elevate py-3 px-4" elevation="2">
                    <div class="kpi-bg-icon"><v-icon>mdi-minus-circle</v-icon></div>
                    <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                      <div class="d-flex align-center justify-space-between">
                        <div class="d-flex align-center" style="gap: 8px;">
                          <v-icon size="18" class="opacity-80">mdi-minus-circle-outline</v-icon>
                          <span class="kpi-label">TEMPO NEUTRO</span>
                        </div>
                        <span class="text-caption font-weight-bold opacity-80 bg-black-20 px-2 py-0.5">{{ getPercentage(user.today_neutral_seconds, totalDailyTime).toFixed(0) }}%</span>
                      </div>
                      <div class="text-h4 font-weight-black my-1">{{ formatTime(user.today_neutral_seconds) }}</div>
                      <div class="kpi-footer mt-1 opacity-80">MÉTRICA DE HOJE</div>
                    </div>
                  </v-card>
                </v-col>
              </v-row>

              <div v-if="loadingDashboardData" class="flex-grow-1 d-flex flex-column align-center justify-center py-10">
                <v-progress-circular indeterminate color="success" size="48"></v-progress-circular>
                <p class="text-caption mt-3 font-weight-bold opacity-70">Sincronizando métricas...</p>
              </div>

              <v-row v-else dense class="ma-0 flex-grow-1">
                <v-col cols="12" lg="6" class="pa-1 mb-4 mb-lg-0">
                  <v-card flat :class="isLight ? 'bg-white border-thin shadow-sm' : 'bg-surface border-white-05'" class="rounded-0 h-100 d-flex flex-column">
                    <div class="d-flex align-center justify-space-between pa-3 border-b flex-shrink-0" :class="isLight ? 'bg-grey-lighten-5' : 'bg-surface-variant'">
                      <span class="text-caption font-weight-black text-uppercase">Top Aplicações Usadas</span>
                      <v-menu v-model="dateMenu" :close-on-content-click="false" location="bottom end">
                        <template v-slot:activator="{ props }">
                          <v-btn variant="outlined" class="btn-rect px-2" v-bind="props" size="small" :color="isLight ? 'grey-darken-2' : 'white'" height="28">
                            <v-icon start size="14">mdi-calendar</v-icon> {{ formattedSelectedDate }}
                          </v-btn>
                        </template>
                        <v-date-picker v-model="selectedDate" @update:modelValue="dateMenu = false" show-adjacent-months hide-header color="success"></v-date-picker>
                      </v-menu>
                    </div>
                    <v-card-text class="flex-grow-1 pa-2">
                      <apexchart type="bar" height="100%" :options="topAppsOptions" :series="topAppsSeries"></apexchart>
                    </v-card-text>
                  </v-card>
                </v-col>

                <v-col cols="12" lg="6" class="pa-1">
                  <v-card flat :class="isLight ? 'bg-white border-thin shadow-sm' : 'bg-surface border-white-05'" class="rounded-0 h-100 d-flex flex-column">
                    <div class="d-flex align-center justify-space-between pa-3 border-b flex-shrink-0" :class="isLight ? 'bg-grey-lighten-5' : 'bg-surface-variant'">
                      <span class="text-caption font-weight-black text-uppercase">Top Sites/Abas Produtivos</span>
                    </div>
                    <v-card-text class="flex-grow-1 pa-2">
                      <apexchart type="treemap" height="100%" :options="topSitesOptions" :series="topSitesSeries"></apexchart>
                    </v-card-text>
                  </v-card>
                </v-col>
              </v-row>
            </div>
          </v-window-item>

          <v-window-item value="activityLog" class="h-100">
            <div class="pa-4 pa-md-6 h-100 d-flex flex-column">
                <div class="d-flex align-center justify-space-between mb-4 pa-3 border-thin rounded-0 flex-shrink-0" :class="isLight ? 'bg-white shadow-sm' : 'bg-surface border-white-05'">
                  <div class="d-flex align-center gap-2">
                      <v-icon :color="isLight ? 'primary' : 'white'">mdi-format-list-bulleted</v-icon>
                      <span class="text-caption font-weight-black text-uppercase">Registro Analítico</span>
                  </div>
                  <v-menu v-model="dateMenu" :close-on-content-click="false" location="bottom end">
                    <template v-slot:activator="{ props }">
                      <v-btn variant="outlined" class="btn-rect px-2" v-bind="props" size="small" :color="isLight ? 'grey-darken-2' : 'white'" height="28">
                        <v-icon start size="14">mdi-calendar</v-icon> {{ formattedSelectedDate }}
                      </v-btn>
                    </template>
                    <v-date-picker v-model="selectedDate" @update:modelValue="dateMenu = false; loadActivityLogs(user?.id)" show-adjacent-months hide-header color="success"></v-date-picker>
                  </v-menu>
                </div>

                <div v-if="loadingLogs" class="flex-grow-1 d-flex flex-column align-center justify-center">
                    <v-progress-circular indeterminate color="success"></v-progress-circular>
                    <span class="mt-2 text-caption font-weight-bold opacity-70">Buscando...</span>
                </div>

                <div v-else-if="activityLogs.length === 0" class="flex-grow-1 d-flex flex-column align-center justify-center opacity-50">
                  <v-icon size="48" class="mb-2">mdi-clock-remove-outline</v-icon>
                  <span class="text-caption font-weight-bold text-uppercase">Sem registros para esta data.</span>
                </div>

                <v-card v-else class="flex-grow-1 d-flex flex-column rounded-0 border-thin overflow-hidden" :class="isLight ? 'bg-white shadow-sm' : 'bg-surface border-white-05'" elevation="0">
                  <div class="grid-scroll flex-grow-1 overflow-auto custom-scroll relative">
                    <div class="grid-header sticky-head" :class="isLight ? 'grid-surface-light' : 'grid-surface-dark'" style="min-width: 600px; grid-template-columns: 50px 80px minmax(150px, 1.5fr) minmax(200px, 2fr) 100px;">
                      <div class="cell center header-text">#</div>
                      <div class="cell center header-text">Hora</div>
                      <div class="cell header-text">Aplicação</div>
                      <div class="cell header-text">Título da Janela</div>
                      <div class="cell center header-text">Status</div>
                    </div>

                    <div
                      v-for="(item, idx) in activityLogs"
                      :key="item.id"
                      class="grid-row cursor-pointer"
                      :class="[isLight ? 'grid-row-light' : 'grid-row-dark', zebraClass(idx)]"
                      style="min-width: 600px; grid-template-columns: 50px 80px minmax(150px, 1.5fr) minmax(200px, 2fr) 100px;"
                      @click="openActivityDetails(item)"
                    >
                      <div class="cell center text-[10px] font-weight-black opacity-50">{{ idx + 1 }}</div>
                      <div class="cell center font-mono text-[11px] font-weight-black opacity-80">{{ formatLogTime(item.created_at) }}</div>
                      <div class="cell list-text-11 font-weight-bold text-truncate" :title="item.application_name">{{ item.application_name || 'N/A' }}</div>
                      <div class="cell list-text-11 text-truncate opacity-80" :title="item.window_title">{{ item.window_title || '(Sem título)' }}</div>
                      <div class="cell center">
                          <span class="solid-chip" :class="getChipClass(item.classification)">{{ item.classification || 'neutro' }}</span>
                      </div>
                    </div>
                  </div>
                </v-card>
            </div>
          </v-window-item>

          <v-window-item value="screenshots" class="h-100">
            <div class="pa-4 pa-md-6 h-100 d-flex flex-column">
                <div class="d-flex align-center justify-space-between mb-4 pa-3 border-thin rounded-0 flex-shrink-0" :class="isLight ? 'bg-white shadow-sm' : 'bg-surface border-white-05'">
                  <div class="d-flex align-center gap-2">
                      <v-icon :color="isLight ? 'primary' : 'white'">mdi-monitor-screenshot</v-icon>
                      <span class="text-caption font-weight-black text-uppercase">Galeria de Capturas Automáticas</span>
                  </div>
                  <v-btn @click="() => loadScreenshots(user?.id)" :loading="loadingScreenshots" class="btn-rect px-2" variant="outlined" :color="isLight ? 'grey-darken-2' : 'white'" size="small" height="28">
                    <v-icon start size="14">mdi-refresh</v-icon> Atualizar
                  </v-btn>
                </div>

                <div v-if="loadingScreenshots" class="flex-grow-1 d-flex flex-column align-center justify-center">
                    <v-progress-circular indeterminate color="success"></v-progress-circular>
                </div>

                <div v-else-if="screenshots.length === 0" class="flex-grow-1 d-flex flex-column justify-center align-center opacity-50">
                  <v-icon size="48" class="mb-2">mdi-image-off-outline</v-icon>
                  <span class="text-caption font-weight-bold text-uppercase">Nenhuma captura disponível.</span>
                </div>

                <div v-else class="flex-grow-1 overflow-y-auto custom-scroll pr-1 pb-4">
                    <v-row dense>
                      <v-col v-for="screenshot in sortedScreenshots" :key="screenshot.name" cols="12" sm="6" md="4" lg="3">
                          <v-card @click="openImageModal(screenshot.signedUrl)" hover class="rounded-0 border-thin cursor-pointer d-flex flex-column h-100" :class="isLight ? 'bg-white shadow-sm' : 'bg-surface border-white-05'">
                              <v-img :src="screenshot.signedUrl" aspect-ratio="1.77" cover lazy-src="/placeholder.png" class="flex-grow-1">
                                  <template v-slot:placeholder>
                                  <v-row class="fill-height ma-0" align="center" justify="center">
                                      <v-progress-circular indeterminate color="success" size="24"></v-progress-circular>
                                  </v-row>
                                  </template>
                              </v-img>
                              <div class="pa-2 text-center text-[10px] font-weight-black font-mono border-t" :class="isLight ? 'bg-grey-lighten-5' : 'bg-surface-variant border-white-05'">
                                  {{ formatTimestamp(screenshot.name) }}
                              </div>
                          </v-card>
                      </v-col>
                    </v-row>
                </div>
            </div>
          </v-window-item>

          <v-window-item value="stream" class="h-100 pa-0">
            <StreamViewer
              v-if="activeMenu === 'stream' && user"
              :colaborador-id="user.id"
              :user-name="user.full_name"
              @close="activeMenu = 'overview'"
              class="h-100 w-100"
            />
          </v-window-item>

        </v-window>
      </div>
    </v-card>

    <v-navigation-drawer
      v-model="activityDrawer"
      temporary
      location="right"
      :width="$vuetify.display.smAndDown ? '100%' : 450"
      :class="isLight ? 'bg-white border-l' : 'bg-surface border-l border-white-05'"
      elevation="10"
      style="z-index: 3000;"
    >
      <ActivityDetailDrawer
        v-if="selectedActivity"
        :selected-activity="selectedActivity"
        :all-activities="activityLogs"
        @close="activityDrawer = false"
      />
    </v-navigation-drawer>

    <v-dialog v-model="imageModal" max-width="95vw" scrollable>
      <v-card class="rounded-0" :class="isLight ? 'bg-white' : 'bg-surface border border-white-10'">
        <div class="px-4 py-2 border-b d-flex align-center justify-space-between" :class="isLight ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-surface-variant border-white-05'">
          <span class="text-caption font-weight-black text-uppercase letter-spacing-1">Visualizador de Captura</span>
          <v-btn icon="mdi-close" variant="text" size="small" @click="imageModal = false"></v-btn>
        </div>
        <v-card-text class="pa-0 bg-black d-flex align-center justify-center" style="min-height: 60vh;">
          <v-img :src="selectedImageUrl" contain max-height="85vh" class="w-100 h-100"></v-img>
        </v-card-text>
      </v-card>
    </v-dialog>

    <ChartDetailModal v-model="chartDetailModal" :title="chartDetailData.title" :data="chartDetailData.data" />
  </v-dialog>
</template>

<script setup lang="ts">
import { ref, watch, computed, shallowRef } from 'vue';
import { useDisplay } from 'vuetify';
import { supabase } from '@/api/supabase';
import { useThemeStore } from '@/stores/theme';
import apexchart from 'vue3-apexcharts';
import StreamViewer from './StreamViewer.vue';
import ActivityDetailDrawer from './ActivityDetailDrawer.vue';
import ChartDetailModal from './ChartDetailModal.vue';

const themeStore = useThemeStore();
const isLight = computed(() => themeStore.currentMode === 'light');

// --- Interfaces ---
interface UserActivityData {
    id: string;
    full_name: string;
    avatar_url: string | null;
    role: string;
    last_activity_time: string | null;
    last_application_name: string | null;
    last_window_title: string | null;
    last_classification: string | null;
    today_productive_seconds: number;
    today_unproductive_seconds: number;
    today_neutral_seconds: number;
    status?: 'online' | 'offline' | 'away';
    last_seen?: string | null;
}
interface ScreenshotFile {
  name: string;
  id: string;
  signedUrl?: string;
}
interface ActivityLogItem {
  id: string;
  application_name?: string;
  window_title?: string;
  path?: string | null;
  pid?: number | string | null;
  classification?: 'produtivo' | 'improdutivo' | 'neutro' | string | null;
  created_at: string;
}

interface AppRankingData { application_name: string; total_seconds: number; classification: string; }
interface SiteRankingData { window_title: string; total_seconds: number; }

const props = defineProps<{ modelValue: boolean; user: UserActivityData | null; }>();
const emit = defineEmits(['update:modelValue']);

const { mobile } = useDisplay();
const dialog = ref(props.modelValue);
const activeMenu = ref('overview');

const screenshots = ref<ScreenshotFile[]>([]);
const loadingScreenshots = ref(false);
const imageModal = ref(false);
const selectedImageUrl = ref<string | null>(null);

const activityLogs = ref<ActivityLogItem[]>([]);
const loadingLogs = ref(false);
const selectedDate = ref(new Date());
const dateMenu = ref(false);
const activityDrawer = ref(false);
const selectedActivity = shallowRef<ActivityLogItem | null>(null);

const chartDetailModal = ref(false);
const chartDetailData = ref({ title: '', data: {} });

const loadingDashboardData = ref(false);
const realTopApps = ref<AppRankingData[]>([]);
const realTopSites = ref<SiteRankingData[]>([]);

const formattedSelectedDate = computed(() => selectedDate.value.toLocaleDateString('pt-BR', { day: '2-digit', month: '2-digit', year: 'numeric' }));
const sortedScreenshots = computed(() => [...screenshots.value].sort((a, b) => b.name.localeCompare(a.name)));

const totalDailyTime = computed(() => {
  if (!props.user) return 0;
  return (props.user.today_productive_seconds ?? 0) + (props.user.today_unproductive_seconds ?? 0) + (props.user.today_neutral_seconds ?? 0);
});

const getPercentage = (value: number, total: number) => total === 0 ? 0 : (value / total) * 100;

// --- UTILS CSS ---
const zebraClass = (i:number) => !isLight.value ? (i%2===0?'zebra-dark-a':'zebra-dark-b') : (i%2===0?'zebra-light-a':'zebra-light-b');
const getChipClass = (c: string | null | undefined) => {
    if (!c) return 'bg-grey text-white';
    if (c.toLowerCase() === 'produtivo') return 'chip-success';
    if (c.toLowerCase() === 'improdutivo') return 'chip-danger';
    return 'chip-warn';
};
const getStatusColor = (status: string | null | undefined) => {
  switch (status) {
    case 'online': return 'success';
    case 'away': return 'warning';
    default: return 'grey';
  }
}

// --- GRÁFICOS APEXCHARTS ---
const topAppsSeries = computed(() => [{ name: 'Tempo (segundos)', data: realTopApps.value.map(app => app.total_seconds) }]);
const topAppsOptions = computed(() => ({
  chart: { type: 'bar', toolbar: { show: false }, background: 'transparent', events: { dataPointSelection: handleChartClick }, zoom: { enabled: false } },
  theme: { mode: isLight.value ? 'light' : 'dark' },
  colors: ['#2e7d32'],
  plotOptions: { bar: { horizontal: true, borderRadius: 0, dataLabels: { position: 'top' } } },
  dataLabels: { enabled: true, offsetX: 30, style: { fontSize: '10px', colors: [isLight.value ? '#555' : '#ccc'] }, formatter: (val: number) => formatTime(val) },
  xaxis: { categories: realTopApps.value.map(app => app.application_name), labels: { style: { fontSize: '9px' }, formatter: (val: number) => `${(val / 3600).toFixed(1)}h` } },
  yaxis: { labels: { style: { fontSize: '10px', fontWeight: 'bold' } } },
  tooltip: { theme: isLight.value ? 'light' : 'dark', y: { formatter: (val: number) => formatTime(val) } }
}));

const topSitesSeries = computed(() => [{ data: realTopSites.value.map(site => ({ x: site.window_title, y: site.total_seconds })) }]);
const topSitesOptions = computed(() => ({
  chart: { type: 'treemap', toolbar: { show: false }, background: 'transparent', events: { dataPointSelection: handleChartClick }, zoom: { enabled: false } },
  theme: { mode: isLight.value ? 'light' : 'dark' },
  colors: ['#3B93A5', '#F7B844', '#ADD8C7', '#EC3C65', '#CDD7B6'],
  plotOptions: { treemap: { distributed: true, enableShades: false, dataLabels: { format: 'scale', style: { fontSize: '11px', fontWeight: 'bold' } } } },
  tooltip: { theme: isLight.value ? 'light' : 'dark', y: { formatter: (val: number) => formatTime(val) } }
}));

watch(() => props.modelValue, (newValue) => {
  dialog.value = newValue;
   if (newValue && props.user?.id) handleMenuChange(activeMenu.value, props.user.id);
   if (!newValue) setTimeout(() => { activeMenu.value = 'overview'; activityDrawer.value = false; realTopApps.value = []; realTopSites.value = []; }, 300);
});

watch(activeMenu, (newMenu) => {
   if (dialog.value && props.user?.id) handleMenuChange(newMenu, props.user.id);
   if (newMenu !== 'activityLog') activityDrawer.value = false;
});

watch(() => props.user?.id, (newUserId, oldUserId) => {
    if (newUserId && newUserId !== oldUserId) {
        resetState();
        if (dialog.value) handleMenuChange(activeMenu.value, newUserId);
    }
});

watch(selectedDate, (newDate, oldDate) => {
  if (newDate.toDateString() !== oldDate?.toDateString() && props.user?.id) {
    if (activeMenu.value === 'overview') loadDashboardData(props.user.id);
    else if (activeMenu.value === 'activityLog') loadActivityLogs(props.user.id);
  }
});

function handleMenuChange(newMenu: string, userId: string) {
    if (newMenu === 'overview' && realTopApps.value.length === 0) loadDashboardData(userId);
    if (newMenu === 'screenshots' && screenshots.value.length === 0) loadScreenshots(userId);
    if (newMenu === 'activityLog' && activityLogs.value.length === 0) loadActivityLogs(userId);
}

function openActivityDetails(activity: ActivityLogItem) { selectedActivity.value = activity; activityDrawer.value = true; }
function resetState() { screenshots.value = []; activityLogs.value = []; selectedDate.value = new Date(); activeMenu.value = 'overview'; activityDrawer.value = false; selectedActivity.value = null; realTopApps.value = []; realTopSites.value = []; }
const closeModal = () => emit('update:modelValue', false);

const formatTime = (totalSeconds: number) => {
    if (!totalSeconds || totalSeconds < 0) totalSeconds = 0;
    const hours = Math.floor(totalSeconds / 3600);
    const minutes = Math.floor((totalSeconds % 3600) / 60);
    const seconds = Math.floor(totalSeconds % 60);
    let result = '';
    if (hours > 0) result += `${hours}h `;
    if (minutes > 0 || hours > 0) result += `${minutes}m`;
    else if (hours === 0 && minutes === 0) result = `${seconds}s`;
    if (hours > 0 && minutes === 0) result = `${hours}h 0m`;
    return result.trim();
};

const formatLogTime = (isoString: string): string => {
   try { return new Date(isoString).toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit', second: '2-digit' }); } catch (e) { return 'N/A'; }
}

function handleChartClick(event: any, chartContext: any, config: any) {
  const dataPointIndex = config.dataPointIndex;
  let title = '', data = {};

  if (config.w.config.xaxis.categories) {
    const appData = realTopApps.value[dataPointIndex];
    if (!appData) return;
    title = `Detalhes: ${appData.application_name}`;
    data = { 'Aplicação': appData.application_name, 'Tempo Total': formatTime(appData.total_seconds), 'Classificação': appData.classification };
  } else {
    const siteData = realTopSites.value[dataPointIndex];
    if (!siteData) return;
    title = `Detalhes: ${siteData.window_title}`;
    data = { 'Site/Aba': siteData.window_title, 'Tempo Total': formatTime(siteData.total_seconds), 'Classificação': 'Produtivo' };
  }
  chartDetailData.value = { title, data };
  chartDetailModal.value = true;
}

async function loadDashboardData(userId: string) {
  loadingDashboardData.value = true;
  const isoDate = selectedDate.value.toISOString().split('T')[0];
  try {
    const { data: appData } = await supabase.rpc('get_app_usage_ranking', { p_user_id: userId, p_date: isoDate });
    realTopApps.value = (appData || []) as AppRankingData[];
    const { data: siteData } = await supabase.rpc('get_productive_sites_ranking', { p_user_id: userId, p_date: isoDate });
    realTopSites.value = (siteData || []) as SiteRankingData[];
  } catch (err: any) { console.error(err); } finally { loadingDashboardData.value = false; }
}

async function loadActivityLogs(userId: string) {
  loadingLogs.value = true;
  activityLogs.value = [];
  const startDate = new Date(selectedDate.value); startDate.setHours(0, 0, 0, 0);
  const endDate = new Date(selectedDate.value); endDate.setHours(23, 59, 59, 999);
  try {
    const { data } = await supabase.from('user_activity').select('id, created_at, application_name, window_title, path, pid, classification')
      .eq('user_id', userId).gte('created_at', startDate.toISOString()).lte('created_at', endDate.toISOString())
      .order('created_at', { ascending: false }).limit(500);
    activityLogs.value = (data || []) as ActivityLogItem[];
  } catch (err: any) { console.error(err); } finally { loadingLogs.value = false; }
}

async function loadScreenshots(userId: string) {
  loadingScreenshots.value = true;
  screenshots.value = [];
  try {
    const { data: fileList } = await supabase.storage.from('screenshots').list(`user_screenshots/${userId}`, { limit: 50, sortBy: { column: 'created_at', order: 'desc' }});
    const validFiles = fileList?.filter(file => file.name !== '.emptyFolderPlaceholder') ?? [];
    const urlPromises = validFiles.map(async (file) => {
        const { data: urlData } = await supabase.storage.from('screenshots').createSignedUrl(`user_screenshots/${userId}/${file.name}`, 60 * 5);
        return { ...file, signedUrl: urlData?.signedUrl };
    });
    screenshots.value = (await Promise.all(urlPromises)).filter(f => f.signedUrl) as ScreenshotFile[];
  } catch (err: any) { console.error(err); } finally { loadingScreenshots.value = false; }
}

function openImageModal(url: string | undefined) { if (url) { selectedImageUrl.value = url; imageModal.value = true; } }

function formatTimestamp(fileName: string): string {
    const match = fileName.match(/screenshot-(\d{4}-\d{2}-\d{2}T\d{2}-\d{2}-\d{2}-\d{3}Z)\./);
    if (match && match[1]) {
        try { return new Date(match[1].replace(/-(\d{2}Z)$/, '.$1').replace(/-(\d{2})\./, ':$1.').replace(/-(\d{2}):/, ':$1:')).toLocaleString('pt-BR', { dateStyle: 'short', timeStyle: 'short' }); } catch (e) {}
    }
    return fileName.split('.')[0];
}
</script>

<style scoped lang="scss">
/* Fixes de Modal no Vuetify */
.fixed-dialog { margin: 0; padding: 0; overflow: hidden !important; }

/* Bases e Layouts de Vuetify */
.bg-background-dark { background: #0f0f13; }
.bg-glass-dark { background: rgba(15,15,18,0.95); }
.bg-surface-variant { background: rgba(255,255,255,0.05); }
.border-white-05 { border-color: rgba(255,255,255,0.05) !important; }
.border-white-10 { border-color: rgba(255,255,255,0.1) !important; }
.btn-rect { border-radius: 0 !important; text-transform: none !important; font-weight: 800; letter-spacing: 0.5px; }
.bg-black-20 { background: rgba(0,0,0,0.2); }

/* Remove fundos do V-Tabs */
:deep(.v-slide-group__content) { background: transparent !important; }
:deep(.v-tab) { border-radius: 0 !important; }

/* Scrollbars */
.grid-scroll { scrollbar-gutter: stable; -webkit-overflow-scrolling: touch; }
.custom-scroll::-webkit-scrollbar { width: 6px; height: 6px; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.3); border-radius: 4px; }
.custom-scroll::-webkit-scrollbar-track { background: transparent; }

/* Grid System Analítica */
.grid-header, .grid-row {
    display: grid;
    align-items: stretch;
    border-bottom: 1px solid rgba(0,0,0,0.08);
}
.cell {
    padding: 6px 12px;
    display: flex;
    align-items: center;
    border-right: 1px solid rgba(0,0,0,0.08);
    min-height: 40px;
    overflow: hidden;
    transition: background-color 0.2s ease;
}
.header-text { font-size: 10px !important; font-weight: 900; text-transform: uppercase; letter-spacing: 0.5px; }
.center { justify-content: center; text-align: center; }

/* Grid Light/Dark Borders */
.grid-surface-light .cell { background: #f5f7fa; color: rgba(0,0,0,0.7); border-color: rgba(0,0,0,0.1) !important; }
.grid-surface-dark .cell { background: rgba(255,255,255,0.05); color: rgba(255,255,255,0.8); border-color: rgba(255,255,255,0.05) !important; }
.grid-row-light .cell { border-color: rgba(0,0,0,0.08) !important; }
.grid-row-dark .cell { border-color: rgba(255,255,255,0.05) !important; }
.grid-row { border-bottom: none !important; }

/* Zebrado e Hover da Grid */
.zebra-light-a .cell { background: #ffffff; }
.zebra-light-b .cell { background: #fcfcfc; }
.zebra-dark-a .cell { background: rgba(0,0,0,0.2); }
.zebra-dark-b .cell { background: rgba(255,255,255,0.02); }
.grid-row-light:hover .cell { background: #e3f2fd !important; }
.grid-row-dark:hover .cell { background: rgba(255,255,255,0.1) !important; }

/* Sticky Header */
.sticky-head { position: sticky; top: 0; z-index: 20; box-shadow: 0 4px 12px rgba(0,0,0,0.05); }
.bg-glass-dark .sticky-head { box-shadow: 0 4px 12px rgba(0,0,0,0.3); }

/* Chips Customizados */
.solid-chip { display: inline-flex; align-items: center; justify-content: center; height: 20px; padding: 0 8px; border-radius: 0px; font-size: 9px !important; font-weight: 900; color: #fff; text-transform: uppercase; white-space: nowrap; }
.chip-success { background: #2e7d32; }
.chip-warn { background: #0288d1; }
.chip-danger { background: #c62828; }
.list-text-11 { font-size: 11px !important; line-height: 1.2 !important; }

/* KPI Cards com Gradiente */
.kpi-card { color: white; position: relative; min-height: 90px; overflow: hidden; border: none !important; }
.kpi-rect { border-radius: 0 !important; }
.kpi-bg-icon { position: absolute; right: -15px; bottom: -15px; opacity: 0.15; transform: rotate(-15deg); }
.kpi-bg-icon .v-icon { font-size: 80px; color: white; }
.bg-gradient-green { background: linear-gradient(135deg, #2e7d32, #1b5e20); }
.bg-gradient-red { background: linear-gradient(135deg, #c62828, #8e0000); }
.bg-gradient-info { background: linear-gradient(135deg, #0288d1, #005b9f); }
.kpi-label { font-size: 11px; font-weight: 900; letter-spacing: .2px; }
.kpi-footer { font-size: 9px; font-weight: 900; letter-spacing: 0.5px; }

/* Utilities Extras */
.lh-1 { line-height: 1; }
.tracking-tight { letter-spacing: -0.5px !important; }
.min-h-100 { min-height: 100%; }
</style>
