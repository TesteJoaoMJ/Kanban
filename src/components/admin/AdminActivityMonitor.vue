<template>
  <div
    class="receivables-layout font-sans fill-height d-flex flex-column relative overflow-hidden"
    :class="isLight ? 'bg-grey-lighten-5 text-grey-darken-4' : 'bg-background-dark text-white'"
  >
    <div class="content-wrapper d-flex flex-column fill-height z-10 relative">

      <div
        class="header-bar px-4 py-3 px-md-6 py-md-4 d-flex flex-column flex-md-row align-md-center justify-space-between flex-shrink-0"
        :class="isLight ? 'bg-white border-b border-grey-lighten-2 shadow-sm' : 'bg-glass-header border-bottom-white-05'"
        style="gap: 12px;"
      >
        <div class="d-flex flex-column">
          <div class="breadcrumb text-caption d-none d-md-block">
            <span class="opacity-70">Monitoramento</span>
            <span class="mx-2 opacity-50">></span>
            <span class="font-weight-bold">Produtividade da Equipe</span>
          </div>
          <div class="d-flex align-center gap-2 mt-1">
             <div class="text-h6 font-weight-black tracking-tight leading-none text-uppercase" :class="isLight ? 'text-grey-darken-4' : 'text-white'">
                Atividade em Tempo Real
             </div>
             <v-chip size="x-small" color="success" class="font-weight-bold ml-2 tracking-widest px-2" variant="flat">
                LIVE
             </v-chip>
          </div>
        </div>

        <div class="d-flex align-center" style="gap: 10px;">
          <v-btn
            color="success"
            variant="flat"
            class="btn-rect px-4 font-weight-bold text-caption text-uppercase letter-spacing-1 flex-shrink-0"
            prepend-icon="mdi-refresh"
            height="40"
            :loading="loading"
            @click="fetchInitialData"
          >
             Sincronizar
          </v-btn>
        </div>
      </div>

      <div class="px-4 px-md-6 py-4 flex-shrink-0">
        <v-row class="ma-0" dense style="gap: 12px; flex-wrap: nowrap; overflow-x: auto;">
            <v-col class="pa-0" style="min-width: 220px;">
              <v-card class="kpi-card kpi-rect bg-gradient-purple hover-elevate py-3 px-4" elevation="2">
                <div class="kpi-bg-icon"><v-icon>mdi-account-group</v-icon></div>
                <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                  <div class="d-flex align-center" style="gap: 8px;">
                    <v-icon size="18" class="opacity-80">mdi-account-multiple</v-icon>
                    <span class="kpi-label">TOTAL EQUIPE</span>
                  </div>
                  <div class="text-h4 font-weight-black my-1">{{ sortedAndFilteredUsers.length }}</div>
                  <div class="kpi-footer mt-1 opacity-80">MONITORADOS</div>
                </div>
              </v-card>
            </v-col>

            <v-col class="pa-0" style="min-width: 220px;">
              <v-card class="kpi-card kpi-rect bg-gradient-green hover-elevate py-3 px-4" elevation="2">
                <div class="kpi-bg-icon"><v-icon>mdi-lan-connect</v-icon></div>
                <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                  <div class="d-flex align-center" style="gap: 8px;">
                    <v-icon size="18" class="opacity-80">mdi-circle-medium</v-icon>
                    <span class="kpi-label">ONLINE AGORA</span>
                  </div>
                  <div class="text-h4 font-weight-black my-1">{{ onlineCount }}</div>
                  <div class="kpi-footer mt-1 opacity-80">CONECTADOS</div>
                </div>
              </v-card>
            </v-col>

            <v-col class="pa-0" style="min-width: 220px;">
              <v-card class="kpi-card kpi-rect bg-gradient-info hover-elevate py-3 px-4" elevation="2">
                <div class="kpi-bg-icon"><v-icon>mdi-chart-areaspline</v-icon></div>
                <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                  <div class="d-flex align-center" style="gap: 8px;">
                    <v-icon size="18" class="opacity-80">mdi-percent</v-icon>
                    <span class="kpi-label">PRODUTIVIDADE MÉDIA</span>
                  </div>
                  <div class="text-h4 font-weight-black my-1">{{ averageProductivity }}%</div>
                  <div class="kpi-footer mt-1 opacity-80">GERAL HOJE</div>
                </div>
              </v-card>
            </v-col>
        </v-row>
      </div>

      <div class="px-4 px-md-6 pt-0 pb-2 flex-shrink-0">
        <div class="controls-bar d-flex flex-column flex-md-row align-start align-md-center justify-space-between" :class="isLight ? 'controls-light' : 'controls-dark'" style="gap: 10px;">

          <div class="d-flex align-center w-100 w-md-auto" style="gap: 10px;">
            <div class="search-wrap d-flex align-center flex-grow-1 flex-md-grow-0" :class="isLight ? 'search-light' : 'search-dark'">
              <v-icon :color="isLight ? 'grey-darken-1' : 'white-70'">mdi-magnify</v-icon>
              <input
                v-model="searchTerm"
                type="text"
                placeholder="Pesquisar (Nome, Cargo, App...)"
                class="clean-input flex-grow-1"
              />
            </div>
          </div>

          <div class="d-flex align-center w-100 w-md-auto justify-end" style="gap: 10px;">
            <v-btn-toggle v-model="viewMode" mandatory density="compact" class="border-thin" :class="isLight ? 'bg-white' : 'bg-surface-variant'" style="height: 40px;">
              <v-btn value="grid" class="px-4 text-caption font-weight-bold" :color="isLight ? 'success' : 'success'">
                <v-icon start size="18">mdi-table</v-icon> Grid
              </v-btn>
              <v-btn value="card" class="px-4 text-caption font-weight-bold" :color="isLight ? 'success' : 'success'">
                <v-icon start size="18">mdi-view-grid</v-icon> Cards
              </v-btn>
            </v-btn-toggle>
          </div>
        </div>
      </div>

      <div class="flex-grow-1 overflow-hidden d-flex flex-column px-4 px-md-6 pb-4">
        <v-card
          class="flex-grow-1 d-flex flex-column rounded-0 border-thin overflow-hidden"
          :class="isLight ? 'bg-white shadow-sm' : 'glass-card border-white-05'"
          :elevation="0"
        >

          <div v-if="loading" class="d-flex flex-column justify-center align-center h-100 py-10 min-w-full">
            <v-progress-circular indeterminate color="success" size="32" width="3"></v-progress-circular>
            <span class="text-caption mt-2 font-weight-bold opacity-60">Sincronizando Atividades...</span>
          </div>

          <div v-else-if="error" class="d-flex flex-column justify-center align-center h-100 py-10 min-w-full opacity-80">
            <v-icon size="48" color="error">mdi-alert-circle-outline</v-icon>
            <span class="text-body-2 font-weight-medium text-error mt-2">{{ error }}</span>
          </div>

          <div v-else-if="viewMode === 'grid'" class="grid-scroll flex-grow-1 overflow-auto custom-scroll relative">
            <div class="grid-header sticky-head" :class="isLight ? 'grid-surface-light' : 'grid-surface-dark'" style="grid-template-columns: 50px minmax(200px, 2fr) 100px 140px 120px 120px minmax(200px, 2fr) 100px; min-width: 1000px;">
              <div class="cell center header-text">#</div>
              <div class="cell header-text">Colaborador / Cargo</div>
              <div class="cell center header-text">Status</div>
              <div class="cell center header-text">Produtividade</div>
              <div class="cell center header-text text-success">Produtivo</div>
              <div class="cell center header-text text-error">Improdutivo</div>
              <div class="cell header-text">Última Atividade</div>
              <div class="cell center header-text">Ações</div>
            </div>

            <div v-if="sortedAndFilteredUsers.length === 0" class="d-flex flex-column justify-center align-center py-10 opacity-60 w-100 absolute h-100">
              <v-icon size="48">mdi-account-search</v-icon>
              <span class="mt-2 text-caption font-weight-bold">Nenhum colaborador encontrado.</span>
            </div>

            <div
              v-else
              v-for="(user, index) in sortedAndFilteredUsers"
              :key="user.id"
              class="grid-row cursor-pointer"
              :class="[isLight ? 'grid-row-light' : 'grid-row-dark', zebraClass(index)]"
              style="grid-template-columns: 50px minmax(200px, 2fr) 100px 140px 120px 120px minmax(200px, 2fr) 100px; min-width: 1000px;"
              @click="openUserModal(user)"
            >
                <div class="cell center">
                    <v-avatar size="28" class="rounded-0 border-thin">
                        <v-img :src="user.avatar_url || '/placeholder.png'"></v-img>
                    </v-avatar>
                </div>
                <div class="cell">
                    <div class="d-flex flex-column" style="min-width: 0;">
                        <span class="list-text-11 font-weight-black text-truncate text-uppercase">{{ user.full_name }}</span>
                        <span class="text-[9px] font-weight-bold opacity-60 text-uppercase">{{ user.custom_role_id || user.role || 'N/A' }}</span>
                    </div>
                </div>
                <div class="cell center">
                    <span class="solid-chip" :class="getStatusChipClass(user.status)">{{ user.status || 'Offline' }}</span>
                </div>
                <div class="cell center">
                    <div class="w-100 d-flex flex-column align-center px-2">
                        <span class="font-mono text-[10px] font-weight-black mb-1" :class="getPercentageColorText(calculateProductivityPercentage(user))">
                            {{ calculateProductivityPercentage(user) }}%
                        </span>
                        <v-progress-linear :model-value="calculateProductivityPercentage(user)" :color="getPercentageColor(calculateProductivityPercentage(user))" height="4" rounded class="w-100"></v-progress-linear>
                    </div>
                </div>
                <div class="cell center font-mono text-[11px] font-weight-bold text-success">{{ formatTime(user.today_productive_seconds) }}</div>
                <div class="cell center font-mono text-[11px] font-weight-bold text-error">{{ formatTime(user.today_unproductive_seconds) }}</div>
                <div class="cell">
                    <div class="d-flex flex-column" style="min-width: 0;">
                        <div class="d-flex align-center gap-1 mb-1">
                            <v-chip size="x-small" :color="getClassificationColor(user.last_classification)" variant="flat" class="text-[8px] font-weight-black px-1 rounded-sm" style="height: 14px;">{{ user.last_classification || 'N/A' }}</v-chip>
                            <span class="text-[9px] opacity-70 font-mono">{{ user.last_activity_time ? new Date(user.last_activity_time).toLocaleTimeString('pt-BR') : '--:--' }}</span>
                        </div>
                        <span class="text-[10px] text-truncate font-weight-medium opacity-90"><v-icon size="10" class="mr-1">mdi-application</v-icon>{{ user.last_application_name || 'Inativo' }}</span>
                    </div>
                </div>
                <div class="cell center">
                    <div class="actions-inline">
                        <v-btn icon size="small" class="action-btn action-view rounded-0" @click.stop="openUserModal(user)" title="Dashboard Completo" variant="flat"><v-icon size="14">mdi-monitor-dashboard</v-icon></v-btn>
                    </div>
                </div>
            </div>
          </div>

          <div v-else class="flex-grow-1 overflow-auto custom-scroll pa-4 pa-md-6" :class="isLight ? 'bg-grey-lighten-4' : 'bg-transparent'">
            <div v-if="Object.keys(groupedUsers).length === 0" class="d-flex flex-column justify-center align-center py-10 opacity-60">
              <v-icon size="48">mdi-account-search</v-icon>
              <span class="mt-2 text-caption font-weight-bold">Nenhum colaborador encontrado.</span>
            </div>

            <div v-for="(group, roleName) in groupedUsers" :key="roleName" class="mb-8">
                <div class="d-flex align-center mb-4 border-b pb-2" :class="isLight ? 'border-grey-lighten-3' : 'border-white-10'">
                    <div class="icon-box bg-primary text-white rounded-0 d-flex align-center justify-center mr-3" style="width: 32px; height: 32px;">
                        <v-icon size="18">mdi-briefcase-outline</v-icon>
                    </div>
                    <h3 class="text-subtitle-1 font-weight-black text-uppercase tracking-wide m-0" :class="isLight ? 'text-grey-darken-4' : 'text-white'">
                        {{ roleName }}
                    </h3>
                    <v-chip size="small" variant="tonal" color="primary" class="ml-3 font-weight-bold">{{ group.length }} Membros</v-chip>
                </div>

                <v-row dense>
                    <v-col v-for="user in group" :key="user.id" cols="12" sm="6" md="4" lg="3">
                        <v-card
                            class="d-flex flex-column h-100 border-thin rounded-0 transition-all card-hover"
                            :class="isLight ? 'bg-white' : 'bg-surface-variant'"
                            elevation="0"
                            @click="openUserModal(user)"
                        >
                            <div class="pa-3 d-flex align-start justify-space-between border-b" :class="isLight ? 'border-grey-lighten-4' : 'border-white-05'">
                                <div class="d-flex gap-3">
                                    <v-badge :color="getStatusColorBadge(user.status)" dot location="bottom right" offset-x="3" offset-y="3">
                                        <v-avatar size="42" class="rounded-0 border-thin">
                                            <v-img :src="user.avatar_url || '/placeholder.png'" cover></v-img>
                                        </v-avatar>
                                    </v-badge>
                                    <div class="d-flex flex-column" style="max-width: 140px;">
                                        <span class="text-caption font-weight-black text-truncate text-uppercase lh-1 mt-1">{{ user.full_name }}</span>
                                        <span class="text-[9px] font-weight-bold opacity-60 text-uppercase mt-1">{{ user.status || 'Offline' }}</span>
                                    </div>
                                </div>
                                <div class="text-right">
                                    <div class="text-h6 font-weight-black lh-1" :class="getPercentageColorText(calculateProductivityPercentage(user))">
                                        {{ calculateProductivityPercentage(user) }}%
                                    </div>
                                </div>
                            </div>

                            <div class="pa-3 flex-grow-1">
                                <v-progress-linear :model-value="calculateProductivityPercentage(user)" :color="getPercentageColor(calculateProductivityPercentage(user))" height="4" rounded class="mb-3"></v-progress-linear>

                                <div class="d-flex justify-space-between text-center mb-3 px-2">
                                    <div class="d-flex flex-column">
                                        <span class="text-[9px] font-weight-black opacity-60 text-uppercase">Total</span>
                                        <span class="text-caption font-mono font-weight-bold">{{ formatTime(calculateTotalTime(user)) }}</span>
                                    </div>
                                    <div class="d-flex flex-column">
                                        <span class="text-[9px] font-weight-black text-success text-uppercase">Produtivo</span>
                                        <span class="text-caption font-mono font-weight-bold">{{ formatTime(user.today_productive_seconds) }}</span>
                                    </div>
                                    <div class="d-flex flex-column">
                                        <span class="text-[9px] font-weight-black text-error text-uppercase">Improd.</span>
                                        <span class="text-caption font-mono font-weight-bold">{{ formatTime(user.today_unproductive_seconds) }}</span>
                                    </div>
                                </div>

                                <div class="bg-black-10 pa-2 rounded-sm border-thin">
                                    <div class="d-flex align-center justify-space-between mb-1">
                                        <v-chip size="x-small" :color="getClassificationColor(user.last_classification)" variant="flat" class="text-[8px] font-weight-black px-1" style="height: 14px;">{{ user.last_classification || 'N/A' }}</v-chip>
                                        <span class="text-[9px] opacity-70 font-mono">{{ user.last_activity_time ? new Date(user.last_activity_time).toLocaleTimeString('pt-BR') : '--:--' }}</span>
                                    </div>
                                    <div class="text-[10px] text-truncate font-weight-medium opacity-90" :title="user.last_window_title">
                                        <v-icon size="10" class="mr-1">mdi-application-outline</v-icon>{{ user.last_application_name || 'Sem Atividade' }}
                                    </div>
                                </div>
                            </div>

                            <div class="pa-2 border-t mt-auto" :class="isLight ? 'bg-grey-lighten-5 border-grey-lighten-4' : 'bg-surface border-white-05'">
                                <v-btn block variant="flat" color="primary" size="small" class="btn-rect font-weight-bold text-caption">
                                    <v-icon start size="14">mdi-monitor-dashboard</v-icon> Dashboard Completo
                                </v-btn>
                            </div>
                        </v-card>
                    </v-col>
                </v-row>
            </div>
          </div>
        </v-card>
      </div>
    </div>

    <UserActivityModal
        v-model="userModalVisible"
        :user="selectedUser"
    />

  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue';
import { supabase } from '@/api/supabase';
import type { RealtimeChannel } from '@supabase/supabase-js';
import UserActivityModal from './UserActivityModal.vue';
import { useUserStore } from '@/stores/user';
import { useThemeStore } from '@/stores/theme';

const themeStore = useThemeStore();
const isLight = computed(() => themeStore.currentMode === 'light');

// --- Tipagens ---
interface UserActivityData {
    id: string;
    full_name: string;
    avatar_url: string | null;
    role: string;
    custom_role_id?: string;
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

interface ProductivityRule {
    term: string;
    classification: 'produtivo' | 'improdutivo' | 'neutro';
}

const usersActivity = ref<UserActivityData[]>([]);
const productivityRules = ref<ProductivityRule[]>([]);
const loading = ref(true);
const error = ref<string | null>(null);

const viewMode = ref<'grid' | 'card'>('card');
const searchTerm = ref('');

const selectedUser = ref<UserActivityData | null>(null);
const userModalVisible = ref(false);

let activityChannel: RealtimeChannel | null = null;
let presenceChannel: RealtimeChannel | null = null;

const fetchProductivityRules = async () => {
    try {
        const { data, error: rulesError } = await supabase.from('productivity_rules').select('term, classification');
        if (rulesError) throw rulesError;
        productivityRules.value = data;
    } catch (err: any) { console.error("Erro regras produtividade:", err); }
};

const fetchInitialData = async () => {
    loading.value = true;
    error.value = null;
    try {
        await fetchProductivityRules();
        const { data, error: activityError } = await supabase.rpc('get_user_activity_summary_with_presence');
        if (activityError) throw activityError;

        usersActivity.value = data.map((item: any) => ({
            id: item.user_id,
            full_name: item.full_name ?? 'Desconhecido',
            avatar_url: item.avatar_url,
            role: item.role ?? 'N/A',
            custom_role_id: item.custom_role_id || item.role,
            last_activity_time: item.last_activity_time,
            last_application_name: item.last_application_name,
            last_window_title: item.last_window_title,
            last_classification: item.last_classification,
            today_productive_seconds: item.today_productive_seconds ?? 0,
            today_unproductive_seconds: item.today_unproductive_seconds ?? 0,
            today_neutral_seconds: item.today_neutral_seconds ?? 0,
            status: item.status,
            last_seen: item.last_seen
        }));
    } catch (err: any) {
        error.value = "Falha ao carregar dados: " + err.message;
        usersActivity.value = [];
    } finally {
        loading.value = false;
    }
};

const setupRealtimeSubscriptions = () => {
    if (activityChannel) supabase.removeChannel(activityChannel);
    activityChannel = supabase.channel('public:user_activity')
        .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'user_activity' }, (payload) => {
            const updatedUserId = payload.new.user_id;
            const userIndex = usersActivity.value.findIndex(u => u.id === updatedUserId);
            if (userIndex !== -1) {
                const user = usersActivity.value[userIndex];
                user.last_activity_time = payload.new.created_at;
                user.last_application_name = payload.new.application_name;
                user.last_window_title = payload.new.window_title;
                user.last_classification = payload.new.classification;
                const timeDiffSeconds = 30;
                if (payload.new.classification === 'produtivo') user.today_productive_seconds += timeDiffSeconds;
                else if (payload.new.classification === 'improdutivo') user.today_unproductive_seconds += timeDiffSeconds;
                else user.today_neutral_seconds += timeDiffSeconds;
                usersActivity.value[userIndex] = { ...user };
            } else { fetchInitialData(); }
        }).subscribe();

     if (presenceChannel) supabase.removeChannel(presenceChannel);
     presenceChannel = supabase.channel('public:user_presences')
        .on('postgres_changes', { event: '*', schema: 'public', table: 'user_presences' }, (payload) => {
            const record = payload.new as any || payload.old as any;
            if (!record?.user_id) return;
            const userIndex = usersActivity.value.findIndex(u => u.id === record.user_id);
            if (userIndex !== -1) {
                if (payload.eventType === 'DELETE') usersActivity.value[userIndex].status = 'offline';
                else {
                     usersActivity.value[userIndex].status = record.status ?? 'offline';
                     usersActivity.value[userIndex].last_seen = record.last_seen;
                }
                 usersActivity.value[userIndex] = { ...usersActivity.value[userIndex] };
            }
        }).subscribe();
};

// --- Computeds e Processamento ---
const calculateTotalTime = (user: UserActivityData) => user.today_productive_seconds + user.today_unproductive_seconds + user.today_neutral_seconds;
const calculateProductivityPercentage = (user: UserActivityData) => {
    const total = calculateTotalTime(user);
    if (total === 0) return 0;
    return Math.round((user.today_productive_seconds / total) * 100);
};

const filteredUsers = computed(() => {
    if (!searchTerm.value) return usersActivity.value;
    const s = searchTerm.value.toLowerCase();
    return usersActivity.value.filter(u =>
        u.full_name?.toLowerCase().includes(s) ||
        u.role?.toLowerCase().includes(s) ||
        u.custom_role_id?.toLowerCase().includes(s) ||
        u.last_application_name?.toLowerCase().includes(s)
    );
});

const sortedAndFilteredUsers = computed(() => {
    return [...filteredUsers.value].sort((a, b) => {
        const sA = a.status === 'online' ? 0 : 1;
        const sB = b.status === 'online' ? 0 : 1;
        if (sA !== sB) return sA - sB;
        const pA = calculateProductivityPercentage(a);
        const pB = calculateProductivityPercentage(b);
        if (pA !== pB) return pB - pA;
        return (a.full_name ?? '').localeCompare(b.full_name ?? '');
    });
});

// Agrupamento para a visão de Cards
const groupedUsers = computed(() => {
    const groups: Record<string, UserActivityData[]> = {};
    sortedAndFilteredUsers.value.forEach(user => {
        const rName = user.custom_role_id || user.role || 'Outros';
        if (!groups[rName]) groups[rName] = [];
        groups[rName].push(user);
    });
    return groups;
});

// KPIs Globais
const onlineCount = computed(() => usersActivity.value.filter(u => u.status === 'online').length);
const averageProductivity = computed(() => {
    if (usersActivity.value.length === 0) return 0;
    const totalPerc = usersActivity.value.reduce((acc, u) => acc + calculateProductivityPercentage(u), 0);
    return Math.round(totalPerc / usersActivity.value.length);
});

// --- Formatação e Estilos ---
const formatTime = (sec: number) => {
    if (sec === 0) return '0m';
    const h = Math.floor(sec / 3600);
    const m = Math.floor((sec % 3600) / 60);
    if (h > 0) return `${h}h ${m}m`;
    return `${m}m`;
};

const zebraClass = (i:number) => !isLight.value ? (i%2===0?'zebra-dark-a':'zebra-dark-b') : (i%2===0?'zebra-light-a':'zebra-light-b');

const getClassificationColor = (c: string | null) => {
    switch (c) {
        case 'produtivo': return 'success';
        case 'improdutivo': return 'error';
        default: return 'grey';
    }
};

const getStatusChipClass = (s: string | null | undefined) => {
    if (s === 'online') return 'chip-success';
    if (s === 'away') return 'chip-warn';
    return 'bg-grey text-white';
};

const getStatusColorBadge = (s: string | null | undefined) => {
    if (s === 'online') return 'success';
    if (s === 'away') return 'warning';
    return 'grey';
};

const getPercentageColor = (perc: number) => {
    if (perc >= 70) return 'success';
    if (perc >= 40) return 'warning';
    return 'error';
};

const getPercentageColorText = (perc: number) => {
    if (perc >= 70) return 'text-success';
    if (perc >= 40) return 'text-warning';
    return 'text-error';
};

// --- Ações ---
const openUserModal = (user: UserActivityData) => { selectedUser.value = user; userModalVisible.value = true; };

onMounted(() => { fetchInitialData(); setupRealtimeSubscriptions(); });
onUnmounted(() => {
    if (activityChannel) supabase.removeChannel(activityChannel);
    if (presenceChannel) supabase.removeChannel(presenceChannel);
});
</script>

<style scoped lang="scss">
/* Layouts e Bases (Mesmo padrão do Receivables) */
.bg-background-dark { background: #0f0f13; }
.bg-glass-dark { background: rgba(15,15,18,0.95); }
.bg-glass-header { background: rgba(20,20,24,0.55); backdrop-filter: blur(14px); }
.bg-surface-variant { background: rgba(255,255,255,0.05); }
.border-bottom-white-05 { border-bottom: 1px solid rgba(255,255,255,0.08); }
.border-white-05 { border-color: rgba(255,255,255,0.05) !important; }
.border-white-10 { border-color: rgba(255,255,255,0.1) !important; }
.btn-rect { border-radius: 0 !important; text-transform: none !important; font-weight: 800; letter-spacing: 0.5px; }

.bg-black-10 { background: rgba(0,0,0,0.1); }
.bg-black-20 { background: rgba(0,0,0,0.2); }

/* Controls e Search */
.controls-bar { border: 1px solid rgba(0,0,0,0.08); padding: 10px; }
.search-wrap { height: 40px; padding: 0 12px; border: 1px solid rgba(0,0,0,0.08); display: flex; align-items: center; min-width: 300px; flex: 1; }
.clean-input { border: none; outline: none; flex: 1; font-size: 12px; }

/* Grid System com Bordas Rígidas Corrigidas */
.grid-scroll { scrollbar-gutter: stable; -webkit-overflow-scrolling: touch; }
.custom-scroll::-webkit-scrollbar { width: 8px; height: 8px; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.35); border-radius: 0px; }

.grid-header, .grid-row {
    display: grid;
    align-items: stretch;
}
.cell {
    padding: 6px 12px;
    display: flex;
    align-items: center;
    border-right: 1px solid rgba(0,0,0,0.08);
    border-bottom: 1px solid rgba(0,0,0,0.08);
    min-height: 52px;
    overflow: hidden;
    transition: background-color 0.2s ease;
}
.header-text { font-size: 11px !important; font-weight: 900; text-transform: uppercase; letter-spacing: 0.5px; }
.center { justify-content: center; text-align: center; }

/* Overrides Absolutos de Borda para o Grid */
.grid-surface-light .cell { background: #f5f7fa; color: rgba(0,0,0,0.7); border-right: 1px solid rgba(0,0,0,0.1) !important; border-bottom: 1px solid rgba(0,0,0,0.1) !important; }
.grid-surface-dark .cell { background: rgba(255,255,255,0.05); color: rgba(255,255,255,0.8); border-right: 1px solid rgba(255,255,255,0.05) !important; border-bottom: 1px solid rgba(255,255,255,0.05) !important; }
.grid-row-light .cell { border-right: 1px solid rgba(0,0,0,0.08) !important; border-bottom: 1px solid rgba(0,0,0,0.08) !important; }
.grid-row-dark .cell { border-right: 1px solid rgba(255,255,255,0.05) !important; border-bottom: 1px solid rgba(255,255,255,0.05) !important; }

/* Zebrado e Hover */
.zebra-light-a .cell { background: #ffffff; }
.zebra-light-b .cell { background: #fcfcfc; }
.zebra-dark-a .cell { background: rgba(0,0,0,0.2); }
.zebra-dark-b .cell { background: rgba(255,255,255,0.02); }
.grid-row-light:hover .cell { background: #e3f2fd !important; }
.grid-row-dark:hover .cell { background: rgba(255,255,255,0.1) !important; }
.card-hover:hover { border-color: #1976d2 !important; box-shadow: 0 4px 12px rgba(0,0,0,0.1) !important; cursor: pointer; }

/* Sticky Header */
.sticky-head { position: sticky; top: 0; z-index: 20; box-shadow: 0 4px 12px rgba(0,0,0,0.05); }

/* Elementos de UI */
.solid-chip { display: inline-flex; align-items: center; justify-content: center; height: 24px; padding: 0 10px; font-size: 10px !important; font-weight: 900; color: #fff; text-transform: uppercase; white-space: nowrap; }
.chip-success { background: #2e7d32; }
.chip-warn { background: #f57f17; }
.list-text-11 { font-size: 12px !important; line-height: 1.2 !important; }

.actions-inline { display: flex; gap: 4px; justify-content: center; flex-wrap: wrap; }
.action-btn { width: 28px !important; height: 28px !important; border-radius: 0 !important; color: #fff !important; }
.action-view { background: #1976d2 !important; }
.action-details { background: #546e7a !important; }

/* KPI Cards com Gradiente */
.kpi-card { color: white; position: relative; min-height: 110px; overflow: hidden; border: none !important; }
.kpi-rect { border-radius: 0 !important; }
.kpi-bg-icon { position: absolute; right: -20px; bottom: -20px; opacity: 0.15; transform: rotate(-15deg); }
.kpi-bg-icon .v-icon { font-size: 100px; color: white; }
.bg-gradient-green { background: linear-gradient(135deg, #2e7d32, #1b5e20); }
.bg-gradient-red { background: linear-gradient(135deg, #c62828, #8e0000); }
.bg-gradient-info { background: linear-gradient(135deg, #0288d1, #005b9f); }
.bg-gradient-purple { background: linear-gradient(135deg, #7b1fa2, #4a148c); }
.kpi-label { font-size: 12px; font-weight: 900; letter-spacing: .2px; }
.kpi-footer { font-size: 10px; font-weight: 900; letter-spacing: 1px; }

/* Utils */
.lh-1 { line-height: 1; }
.tracking-tight { letter-spacing: -0.5px !important; }
.tracking-widest { letter-spacing: 1px !important; }
</style>
