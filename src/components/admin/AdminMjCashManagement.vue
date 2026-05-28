<template>
  <div
    class="cash-management-layout font-sans fill-height d-flex flex-column relative overflow-hidden"
    :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 text-grey-darken-4' : 'bg-glass-dark text-white'"
  >
    <div v-if="themeStore.currentMode !== 'light'" class="background-carousel-wrapper">
       <div class="background-overlay"></div>
    </div>

    <div class="content-wrapper d-flex flex-column fill-height z-10 relative">

        <div
          class="header-bar px-6 py-4 d-flex align-center justify-space-between flex-shrink-0"
          :class="themeStore.currentMode === 'light' ? 'bg-white border-b border-grey-lighten-2 shadow-sm' : 'bg-glass-header border-bottom-white-05'"
        >
          <div class="d-flex align-center gap-4">
              <div class="d-flex flex-column">
                <div class="breadcrumb text-caption">
                  <span class="opacity-70">Financeiro</span>
                  <span class="mx-2 opacity-50">></span>
                  <span class="font-weight-bold">Gestão de Caixa</span>
                </div>
                <div class="text-h6 font-weight-black tracking-tight leading-none mt-1" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">
                  Monitoramento & Auditoria
                </div>
              </div>

              <div class="ml-6" style="width: 250px;">
                  <v-autocomplete
                      v-model="currentStore"
                      :items="stores"
                      item-title="name"
                      item-value="id"
                      label="Selecionar Loja"
                      variant="outlined"
                      density="compact"
                      hide-details
                      prepend-inner-icon="mdi-store"
                      return-object
                      class="clean-autocomplete"
                      @update:model-value="handleStoreChange"
                  ></v-autocomplete>
              </div>
          </div>

          <div class="d-flex align-center">
             <v-menu location="bottom end" transition="scale-transition">
                <template v-slot:activator="{ props }">
                   <v-btn
                      v-bind="props"
                      color="primary"
                      variant="flat"
                      class="btn-rect px-4 font-weight-bold text-caption text-uppercase letter-spacing-1 shadow-soft"
                      height="40"
                      prepend-icon="mdi-layers-outline"
                   >
                      Ações
                      <v-icon end>mdi-chevron-down</v-icon>
                   </v-btn>
                </template>

                <v-list density="compact" class="rounded-lg border-thin elevation-4" min-width="220" :bg-color="themeStore.currentMode === 'light' ? 'white' : '#1E1E24'">
                    <v-list-subheader class="text-[10px] font-weight-bold text-uppercase opacity-50">Operacional</v-list-subheader>

                    <v-list-item @click="fetchSessions" :disabled="loading" link>
                        <template v-slot:prepend><v-icon class="mr-2 text-primary">mdi-refresh</v-icon></template>
                        <v-list-item-title class="font-weight-bold text-[13px]">Atualizar Lista</v-list-item-title>
                    </v-list-item>

                    <v-divider class="my-1"></v-divider>

                    <v-list-subheader class="text-[10px] font-weight-bold text-uppercase opacity-50">Visualização</v-list-subheader>

                    <v-list-item @click="toggleGlobalMonitor" link>
                        <template v-slot:prepend>
                            <v-icon class="mr-2" :color="isGlobalMonitorMode ? 'amber' : 'grey'">
                                {{ isGlobalMonitorMode ? 'mdi-monitor-dashboard' : 'mdi-monitor' }}
                            </v-icon>
                        </template>
                        <v-list-item-title class="font-weight-bold text-[13px]">
                            {{ isGlobalMonitorMode ? 'Desativar Monitor Global' : 'Ativar Monitor Global' }}
                        </v-list-item-title>
                        <template v-slot:append v-if="isGlobalMonitorMode">
                            <v-icon size="14" color="success">mdi-check</v-icon>
                        </template>
                    </v-list-item>

                    <v-divider class="my-1"></v-divider>

                    <v-list-item @click="openConfigModal" link>
                        <template v-slot:prepend><v-icon class="mr-2 text-grey-darken-1">mdi-cog-outline</v-icon></template>
                        <v-list-item-title class="font-weight-bold text-[13px]">Configurar Caixa</v-list-item-title>
                        <v-list-item-subtitle class="text-[10px]">Definir métodos aceitos</v-list-item-subtitle>
                    </v-list-item>
                </v-list>
             </v-menu>
          </div>
        </div>

        <div class="px-6 pt-4 pb-0 flex-shrink-0">
            <v-row>
              <v-col cols="12" sm="4">
                <v-card class="kpi-card kpi-rect bg-gradient-info hover-elevate py-3 px-4" v-ripple elevation="2">
                  <div class="kpi-bg-icon"><v-icon>mdi-store-clock</v-icon></div>
                  <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height text-white">
                    <div class="d-flex align-center gap-2">
                      <v-icon size="18" class="opacity-80">mdi-cash-register</v-icon>
                      <span class="kpi-label">Caixas Abertos</span>
                    </div>
                    <div class="kpi-number-group my-1">
                      <span class="kpi-value">{{ openSessionsCount }}</span>
                      <span class="text-caption opacity-80 ml-2 font-weight-medium">Ativos Agora</span>
                    </div>
                  </div>
                </v-card>
              </v-col>

              <v-col cols="12" sm="4">
                <v-card class="kpi-card kpi-rect bg-gradient-success hover-elevate py-3 px-4" v-ripple elevation="2">
                  <div class="kpi-bg-icon"><v-icon>mdi-check-all</v-icon></div>
                  <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height text-white">
                    <div class="d-flex align-center gap-2">
                      <v-icon size="18" class="opacity-80">mdi-calendar-check</v-icon>
                      <span class="kpi-label">Fechados (Filtro Atual)</span>
                    </div>
                    <div class="kpi-number-group my-1">
                      <span class="kpi-value">{{ closedCount }}</span>
                      <span class="text-caption opacity-80 ml-2 font-weight-medium">Sessões</span>
                    </div>
                  </div>
                </v-card>
              </v-col>

              <v-col cols="12" sm="4">
                <v-card class="kpi-card kpi-rect bg-gradient-warning hover-elevate py-3 px-4" v-ripple elevation="2">
                  <div class="kpi-bg-icon"><v-icon>mdi-shield-lock-outline</v-icon></div>
                  <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height text-white">
                    <div class="d-flex align-center gap-2">
                      <v-icon size="18" class="opacity-80">mdi-alert-circle-outline</v-icon>
                      <span class="kpi-label">Diferença Acumulada</span>
                    </div>
                    <div class="kpi-number-group my-1">
                      <span class="text-body-2 font-weight-medium mr-1 opacity-70">R$</span>
                      <span class="kpi-value">{{ formatCurrencyValue(totalDifference) }}</span>
                    </div>
                  </div>
                </v-card>
              </v-col>
            </v-row>
        </div>

        <div class="px-6 pt-4 pb-2 flex-shrink-0">
            <div class="controls-bar d-flex align-center justify-space-between" :class="themeStore.currentMode === 'light' ? 'controls-light' : 'controls-dark'">
                <div class="d-flex align-center flex-wrap" style="gap: 10px;">

                    <div class="period-nav d-flex align-center" :class="themeStore.currentMode === 'light' ? 'period-nav-light' : 'period-nav-dark'">
                      <v-btn icon variant="text" class="icon-rect" height="40" width="40" @click="navigatePeriod(-1)" :title="'Anterior'">
                        <v-icon>mdi-chevron-left</v-icon>
                      </v-btn>

                      <v-menu location="bottom center">
                          <template v-slot:activator="{ props }">
                              <div v-bind="props" class="period-label text-caption font-weight-black text-center px-3 cursor-pointer hover-bg-opacity">
                                {{ currentPeriodDisplay }}
                                <v-icon size="12" class="ml-1 opacity-50">mdi-menu-down</v-icon>
                              </div>
                          </template>
                          <v-list density="compact">
                              <v-list-item v-for="p in periodOptions" :key="p.value" @click="setPeriodType(p.value)" :active="periodType === p.value">
                                  <v-list-item-title>{{ p.label }}</v-list-item-title>
                              </v-list-item>
                          </v-list>
                      </v-menu>

                      <v-btn icon variant="text" class="icon-rect" height="40" width="40" @click="navigatePeriod(1)" :title="'Próximo'">
                        <v-icon>mdi-chevron-right</v-icon>
                      </v-btn>
                    </div>

                    <div class="search-wrap d-flex align-center" :class="themeStore.currentMode === 'light' ? 'search-light' : 'search-dark'">
                      <v-icon :color="themeStore.currentMode === 'light' ? 'grey-darken-1' : 'white-70'">mdi-magnify</v-icon>
                      <input
                        v-model="search"
                        type="text"
                        placeholder="Operador, ID..."
                        class="clean-input flex-grow-1"
                      />
                    </div>

                    <div class="d-flex align-center" style="gap: 5px;">
                        <v-chip
                            v-for="st in ['Todos', 'Aberto', 'Fechado']"
                            :key="st"
                            :color="statusFilter === st ? 'primary' : (themeStore.currentMode === 'light' ? 'grey-darken-1' : 'white')"
                            :variant="statusFilter === st ? 'flat' : 'outlined'"
                            class="btn-rect font-weight-bold text-caption h-40 px-3 cursor-pointer"
                            @click="statusFilter = st"
                        >
                            {{ st }}
                        </v-chip>
                    </div>
                </div>
            </div>
        </div>

        <div class="flex-grow-1 px-6 pb-2 overflow-hidden d-flex flex-column">
            <v-card class="flex-grow-1 d-flex flex-column rounded-0 border-thin overflow-hidden" :class="themeStore.currentMode === 'light' ? 'bg-white shadow-sm' : 'glass-card border-white-05'" :elevation="0">
                <div class="grid-scroll flex-grow-1 overflow-y-auto custom-scroll">
                    <div class="grid-header sticky-head" :class="[themeStore.currentMode === 'light' ? 'grid-surface-light' : 'grid-surface-dark', 'grid-layout']">
                        <div class="cell center header-text">Status</div>
                        <div class="cell header-text">Caixa Individual / Loja</div>
                        <div class="cell center header-text">Abertura</div>
                        <div class="cell center header-text">Fechamento</div>
                        <div class="cell right header-text">Fundo Inicial</div>
                        <div class="cell right header-text">Saldo Calculado</div>
                        <div class="cell right header-text">Informado</div>
                        <div class="cell center header-text">Diferença</div>
                        <div class="cell center header-text">Ações</div>
                    </div>

                    <div v-if="loading" class="d-flex flex-column justify-center align-center h-100 py-10">
                        <v-progress-circular indeterminate color="primary" size="32" width="3"></v-progress-circular>
                    </div>

                    <div v-else-if="filteredSessions.length === 0" class="d-flex flex-column justify-center align-center h-100 opacity-60 gap-2 py-10">
                        <v-icon size="48" color="grey-lighten-1">mdi-cash-remove</v-icon>
                        <span class="text-body-2 font-weight-medium text-grey">
                             {{ !userStore.activeStoreId ? 'Selecione uma loja acima.' : 'Nenhuma sessão encontrada.' }}
                        </span>
                    </div>

                    <div v-else v-for="session in filteredSessions" :key="session.id"
                         class="grid-row grid-layout"
                         :class="themeStore.currentMode === 'light' ? 'grid-row-light' : 'grid-row-dark'"
                         @click="openDetails(session)"
                    >
                        <div class="cell center">
                            <div class="status-indicator" :class="session.status === 'open' ? 'bg-success pulse' : 'bg-grey'"></div>
                        </div>

                        <div class="cell">
                            <div class="d-flex flex-column">
                                <span class="list-text-11 font-weight-black text-uppercase">{{ session.user?.full_name || 'Operador' }}</span>
                                <span class="list-text-10 opacity-70 d-flex align-center gap-1">
                                    <v-icon size="10">mdi-store</v-icon> {{ session.store?.name || 'Loja' }}
                                </span>
                            </div>
                        </div>

                        <div class="cell center">
                            <span class="list-text-10 font-mono">{{ formatDate(session.opened_at) }}</span>
                        </div>

                        <div class="cell center">
                            <span v-if="session.closed_at" class="list-text-10 font-mono">{{ formatDate(session.closed_at) }}</span>
                            <span v-else class="text-[10px] font-weight-bold text-success uppercase">Em Aberto</span>
                        </div>

                        <div class="cell right">
                            <span class="list-text-11 font-mono opacity-80">{{ formatCurrency(session.initial_balance) }}</span>
                        </div>

                        <div class="cell right">
                            <span class="list-text-11 font-mono font-weight-bold">{{ formatCurrency(calculateSystemBalance(session)) }}</span>
                        </div>

                        <div class="cell right">
                            <span class="list-text-11 font-mono" :class="session.status === 'open' ? 'opacity-40' : 'text-high-emphasis'">
                                {{ session.status === 'open' ? '-' : formatCurrency(session.final_balance_user || 0) }}
                            </span>
                        </div>

                        <div class="cell center">
                            <span v-if="session.status === 'closed'" class="solid-chip" :class="getDiffColor(getDifference(session))">
                                {{ formatCurrency(getDifference(session)) }}
                            </span>
                            <span v-else class="text-[10px] opacity-50">-</span>
                        </div>

                        <div class="cell center">
                            <div class="d-flex align-center justify-center gap-2">
                                <v-tooltip text="Auditoria Forense (Segurança)" location="top" content-class="tooltip-dark">
                                    <template v-slot:activator="{ props }">
                                        <v-btn v-bind="props" icon size="x-small" variant="tonal" color="error" class="action-btn" @click.stop="openDetails(session)">
                                            <v-icon size="14">mdi-shield-search</v-icon>
                                        </v-btn>
                                    </template>
                                </v-tooltip>

                                <v-tooltip text="Detalhes Financeiros" location="top" content-class="tooltip-dark">
                                    <template v-slot:activator="{ props }">
                                        <v-btn v-bind="props" icon size="x-small" variant="flat" color="primary" class="action-btn" @click.stop="openDetails(session)">
                                            <v-icon size="14">mdi-eye</v-icon>
                                        </v-btn>
                                    </template>
                                </v-tooltip>

                                <v-tooltip text="Reabrir Caixa (Admin)" location="top" content-class="tooltip-dark" v-if="session.status === 'closed'">
                                    <template v-slot:activator="{ props }">
                                        <v-btn v-bind="props" icon size="x-small" variant="flat" color="warning" class="action-btn" @click.stop="reopenSession(session)" :disabled="reopeningId === session.id">
                                            <v-icon size="14">mdi-lock-open-variant-outline</v-icon>
                                        </v-btn>
                                    </template>
                                </v-tooltip>
                            </div>
                        </div>
                    </div>
                </div>
            </v-card>
        </div>
    </div>

    <CashSessionDetailModal
        v-model="showDetailModal"
        :session="selectedSession"
        @refresh="fetchSessions"
    />

    <v-dialog v-model="showConfigModal" max-width="500px">
       <v-card class="rounded-xl overflow-hidden" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'glass-card'">
          <div class="pa-4 border-b d-flex justify-space-between align-center" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5' : 'bg-surface-header'">
             <div class="d-flex align-center gap-3">
                 <v-avatar color="primary" size="40" variant="tonal"><v-icon>mdi-cog</v-icon></v-avatar>
                 <div>
                    <h3 class="text-subtitle-1 font-weight-black">Configuração de Caixa</h3>
                    <div class="text-caption opacity-70">
                        Editando: <strong>{{ currentStore?.name || 'Selecione uma Loja' }}</strong>
                    </div>
                 </div>
             </div>
             <v-btn icon size="small" variant="text" @click="showConfigModal = false"><v-icon>mdi-close</v-icon></v-btn>
          </div>

          <v-card-text class="pa-5" style="max-height: 400px; overflow-y: auto;">
             <v-alert type="info" variant="tonal" density="compact" class="mb-4 text-caption border-thin">
                Marque abaixo os métodos que movimentam o caixa (ex: Dinheiro, PIX). Vendas com métodos marcados somarão no <strong>Saldo Calculado</strong> e exigirão conferência no fechamento.
             </v-alert>

             <div v-if="cashStore.availablePaymentMethods.length === 0" class="text-center py-4">
                 <v-progress-circular indeterminate color="primary"></v-progress-circular>
             </div>

             <v-list density="compact" class="bg-transparent" lines="two">
                 <v-list-item v-for="method in cashStore.availablePaymentMethods" :key="method.id" class="border-b border-dashed" @click="toggleMethod(method.id)">
                     <template v-slot:prepend>
                         <v-checkbox-btn
                            :model-value="selectedCashMethods.includes(method.id)"
                            @update:model-value="toggleMethod(method.id)"
                            color="success"
                         ></v-checkbox-btn>
                     </template>
                     <v-list-item-title class="font-weight-bold text-caption">{{ method.name }}</v-list-item-title>
                     <v-list-item-subtitle class="text-[10px]">ID: {{ method.id.substring(0,8) }}...</v-list-item-subtitle>
                 </v-list-item>
             </v-list>
          </v-card-text>

          <v-card-actions class="pa-4 border-t">
              <v-spacer></v-spacer>
              <v-btn variant="text" @click="showConfigModal = false">Cancelar</v-btn>
              <v-btn color="primary" variant="flat" :loading="savingConfig" @click="saveConfiguration">Salvar Configuração</v-btn>
          </v-card-actions>
       </v-card>
    </v-dialog>

  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from 'vue';
import { supabase } from '@/api/supabase';
import { useThemeStore } from '@/stores/theme';
import { useUserStore } from '@/stores/user';
import { useMjCashSessionStore } from '@/stores/mjCashSession';
import { useAppStore } from '@/stores/app';
import { format, startOfDay, endOfDay, subDays, startOfMonth, endOfMonth, addDays, addMonths } from 'date-fns';
import CashSessionDetailModal from '@/components/admin/CashSessionDetailModal.vue';

const themeStore = useThemeStore();
const userStore = useUserStore();
const cashStore = useMjCashSessionStore();
const appStore = useAppStore();

const loading = ref(false);
const reopeningId = ref<string | null>(null);
const sessions = ref<any[]>([]);
const stores = ref<any[]>([]);
const currentStore = ref<any>(null);
const search = ref('');
const statusFilter = ref('Todos');
const periodType = ref('today');
const currentDateRef = ref(new Date());
const isGlobalMonitorMode = ref(false);

const showDetailModal = ref(false);
const selectedSession = ref<any>(null);

// CONFIG MODAL STATE
const showConfigModal = ref(false);
const savingConfig = ref(false);
const selectedCashMethods = ref<string[]>([]);

const periodOptions = [
    { label: 'Hoje', value: 'today' },
    { label: 'Semana', value: 'week' },
    { label: 'Mês', value: 'month' },
    { label: 'Todos', value: 'all' }
];

const currentPeriodDisplay = computed(() => {
    if (isGlobalMonitorMode.value) return 'Monitoramento Global';
    if (periodType.value === 'today') return format(currentDateRef.value, 'dd/MM/yyyy');
    if (periodType.value === 'month') return format(currentDateRef.value, 'MM/yyyy');
    if (periodType.value === 'week') return 'Semana Atual';
    return 'Todo o Período';
});

// --- REABRIR CAIXA (NOVA FUNÇÃO) ---
const reopenSession = async (session: any) => {
    if (!confirm(`ATENÇÃO: Deseja realmente REABRIR o caixa de ${session.user?.full_name || 'Operador'}? Ele voltará a aceitar lançamentos e o saldo será recalculado.`)) return;

    reopeningId.value = session.id;
    appStore.showSnackbar('Reabrindo caixa...', 'info');

    try {
        const { error } = await supabase.from('mj_cash_sessions').update({
            status: 'open',
            closed_at: null,
            final_balance_system: null,
            final_balance_user: null,
            difference: null,
            user_breakdown: null,
            notes: session.notes ? session.notes + '\n[REABERTO POR ADMIN]' : '[REABERTO POR ADMIN]'
        }).eq('id', session.id);

        if (error) throw error;

        // Opcional: Registra uma movimentação invisível de auditoria informando a reabertura
        await supabase.from('mj_cash_movements').insert({
            session_id: session.id,
            user_id: userStore.user?.id,
            type: 'opening',
            amount: 0,
            description: 'Sessão Reaberta por Administrador'
        });

        appStore.showSnackbar('Caixa reaberto com sucesso!', 'success');
        fetchSessions();
    } catch (e: any) {
        console.error(e);
        appStore.showSnackbar('Erro ao reabrir caixa: ' + e.message, 'error');
    } finally {
        reopeningId.value = null;
    }
};

// --- CARREGAR LOJAS ---
const loadStores = async () => {
    try {
        const { data } = await supabase.from('stores').select('id, name').eq('active', true);
        if (data) {
            stores.value = data;
            if (userStore.activeStoreId) {
                currentStore.value = data.find(s => s.id === userStore.activeStoreId);
            } else if (data.length > 0) {
                currentStore.value = data[0];
                handleStoreChange(data[0]);
            }
        }
    } catch (e) { console.error("Erro ao carregar lojas", e); }
};

const handleStoreChange = (store: any) => {
    if (!store) return;
    userStore.setAdminStore(store);
    fetchSessions();
};

// --- CONFIGURAÇÃO ---
const openConfigModal = async () => {
    if (!userStore.activeStoreId) {
        appStore.showSnackbar("Selecione uma loja no topo para configurar o caixa dela.", "warning");
        return;
    }

    try {
        await cashStore.fetchPaymentMethods();
        await cashStore.fetchStoreConfig(userStore.activeStoreId);
        selectedCashMethods.value = [...cashStore.storeCashMethodIds];
        showConfigModal.value = true;
    } catch (e: any) {
        appStore.showSnackbar("Erro ao carregar configurações: " + e.message, "error");
    }
};

const toggleMethod = (id: string) => {
    if (selectedCashMethods.value.includes(id)) {
        selectedCashMethods.value = selectedCashMethods.value.filter(m => m !== id);
    } else {
        selectedCashMethods.value.push(id);
    }
};

const saveConfiguration = async () => {
    if (!userStore.activeStoreId) return;
    savingConfig.value = true;
    try {
        await cashStore.saveStoreConfig(userStore.activeStoreId, selectedCashMethods.value);
        appStore.showSnackbar("Configuração de caixa salva com sucesso!", "success");
        showConfigModal.value = false;
    } catch (e) {
        appStore.showSnackbar("Erro ao salvar config.", "error");
    } finally {
        savingConfig.value = false;
    }
};

// --- FETCH CORE ---
const fetchSessions = async () => {
    loading.value = true;
    try {
        let query = supabase
            .from('mj_cash_sessions')
            .select(`
                *,
                user:profiles(full_name),
                store:stores(name),
                movements:mj_cash_movements(*)
            `)
            .order('opened_at', { ascending: false });

        if (!isGlobalMonitorMode.value && userStore.activeStoreId) {
             query = query.eq('store_id', userStore.activeStoreId);
        }

        if (!isGlobalMonitorMode.value) {
            const d = currentDateRef.value;
            if (periodType.value === 'today') {
                query = query.gte('opened_at', startOfDay(d).toISOString()).lte('opened_at', endOfDay(d).toISOString());
            } else if (periodType.value === 'week') {
                query = query.gte('opened_at', subDays(d, 7).toISOString());
            } else if (periodType.value === 'month') {
                query = query.gte('opened_at', startOfMonth(d).toISOString()).lte('opened_at', endOfMonth(d).toISOString());
            } else {
                query = query.limit(300);
            }
        } else {
            query = query.or(`status.eq.open,opened_at.gte.${startOfDay(new Date()).toISOString()}`);
        }

        const { data, error } = await query;
        if (!error && data) {
            sessions.value = data;
        }
    } catch (e) {
        console.error("Erro:", e);
    } finally {
        loading.value = false;
    }
};

// --- FILTRAGEM FRONT-END ---
const filteredSessions = computed(() => {
    let list = sessions.value;
    if (isGlobalMonitorMode.value) {
        if (statusFilter.value === 'Todos') return list;
    }
    if (statusFilter.value === 'Aberto') list = list.filter(s => s.status === 'open');
    if (statusFilter.value === 'Fechado') list = list.filter(s => s.status === 'closed');
    if (search.value) {
        const term = search.value.toLowerCase();
        list = list.filter(s =>
            s.user?.full_name?.toLowerCase().includes(term) ||
            s.store?.name?.toLowerCase().includes(term)
        );
    }
    return list;
});

// --- KPIs ---
const openSessionsCount = computed(() => sessions.value.filter(s => s.status === 'open').length);
const closedCount = computed(() => filteredSessions.value.filter(s => s.status === 'closed').length);
const totalDifference = computed(() => {
    return filteredSessions.value
        .filter(s => s.status === 'closed')
        .reduce((acc, s) => acc + getDifference(s), 0);
});

// --- ACTIONS ---
const navigatePeriod = (dir: number) => {
    if (isGlobalMonitorMode.value) return;
    if (periodType.value === 'today') currentDateRef.value = addDays(currentDateRef.value, dir);
    else if (periodType.value === 'month') currentDateRef.value = addMonths(currentDateRef.value, dir);
    else if (periodType.value === 'week') currentDateRef.value = addDays(currentDateRef.value, dir * 7);
    fetchSessions();
};

const setPeriodType = (type: string) => {
    isGlobalMonitorMode.value = false;
    periodType.value = type;
    currentDateRef.value = new Date();
    fetchSessions();
};

const toggleGlobalMonitor = () => {
    isGlobalMonitorMode.value = !isGlobalMonitorMode.value;
    if (isGlobalMonitorMode.value) {
        statusFilter.value = 'Todos';
        fetchSessions();
    } else {
        setPeriodType('today');
    }
};

const openDetails = (session: any) => {
    selectedSession.value = session;
    showDetailModal.value = true;
};

// --- MATH & HELPERS ---
const calculateSystemBalance = (session: any) => {
    const initial = Number(session.initial_balance || 0);
    if (!session.movements || session.movements.length === 0) return Number(session.final_balance_system || initial);

    const movementsSum = session.movements
        .filter((m: any) => m.type !== 'opening')
        .reduce((acc: number, m: any) => acc + Number(m.amount), 0);

    return initial + movementsSum;
};

const getDifference = (session: any) => {
    if (session.status === 'open') return 0;
    const sys = calculateSystemBalance(session);
    const user = Number(session.final_balance_user || 0);
    return user - sys;
};

const formatCurrency = (val: number) => new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(val);
const formatCurrencyValue = (val: number) => new Intl.NumberFormat('pt-BR', { minimumFractionDigits: 2 }).format(val);
const formatDate = (date: string) => date ? format(new Date(date), 'dd/MM HH:mm') : '-';
const getDiffColor = (diff: number) => {
    if (Math.abs(diff) < 0.01) return 'chip-success';
    return diff > 0 ? 'chip-info' : 'chip-error';
};

onMounted(() => {
    loadStores();
    fetchSessions();
});
</script>

<style scoped lang="scss">
.cash-management-layout { position: relative; }
.background-carousel-wrapper { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 0; opacity: 0.6; pointer-events: none; }
.background-overlay { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 1; background: radial-gradient(circle at center, rgba(15, 15, 19, 0.4), rgba(15, 15, 19, 0.98)); backdrop-filter: blur(8px); }
.z-10 { position: relative; z-index: 10; }

.bg-glass-dark { background: rgba(10,10,12,0.85); }
.bg-glass-header { background: rgba(20,20,24,0.55); backdrop-filter: blur(14px); }
.bg-white-05 { background: rgba(255,255,255,0.05); }
.border-bottom-white-05 { border-bottom: 1px solid rgba(255,255,255,0.08); }
.border-white-05 { border-color: rgba(255,255,255,0.05) !important; }

/* GRID AJUSTADA PARA 3 BOTÕES NA ÚLTIMA COLUNA */
.grid-layout { display: grid; grid-template-columns: 60px minmax(200px, 1fr) 120px 120px 120px 120px 120px 120px 120px; align-items: stretch; width: 100%; }
.cell { padding: 8px 10px; display: flex; align-items: center; border-right: 1px solid rgba(0,0,0,0.08); border-bottom: 1px solid rgba(0,0,0,0.08); min-height: 56px; overflow: hidden; }
.center { justify-content: center; text-align: center; }
.right { justify-content: flex-end; text-align: right; }
.grid-header .cell { min-height: 44px; font-size: 11px; font-weight: 900; text-transform: uppercase; letter-spacing: .6px; }
.header-text { font-size: 11px; }

/* Themes */
.grid-surface-light .cell { background: #f5f7fa; color: rgba(0,0,0,0.7); border-color: rgba(0,0,0,0.10); }
.grid-surface-dark .cell { background: rgba(255,255,255,0.08); color: rgba(255,255,255,0.80); border-color: rgba(255,255,255,0.10); }
.grid-row-light .cell { background: #fff; border-color: rgba(0,0,0,0.08); }
.grid-row-light:hover .cell { background: #f7fafc; cursor: pointer; }
.grid-row-dark .cell { background: rgba(255,255,255,0.04); border-color: rgba(255,255,255,0.08); }
.grid-row-dark:hover .cell { background: rgba(255,255,255,0.07); cursor: pointer; }

/* Period Nav */
.period-nav { border-radius: 0; height: 40px; overflow: hidden; border: 1px solid rgba(0,0,0,0.12); }
.period-nav-light { background: #fafafa; }
.period-nav-dark { border-color: rgba(255,255,255,0.10); background: rgba(255,255,255,0.06); }
.period-label { min-width: 160px; display: flex; align-items: center; justify-content: center; height: 40px; }

/* Search & Controls */
.search-wrap { height: 40px; border-radius: 0; padding: 0 12px; min-width: 300px; max-width: 500px; flex: 1 1 300px; }
.search-light { background: #f4f6f8; border: 1px solid rgba(0,0,0,0.08); }
.search-dark { background: rgba(255,255,255,0.08); border: 1px solid rgba(255,255,255,0.10); }
.clean-input { border: none; outline: none; background: transparent; font-size: 12px; color: inherit; width: 100%; }
.btn-rect { border-radius: 0 !important; text-transform: none !important; font-weight: 800; }
.shadow-soft { box-shadow: 0 4px 12px rgba(0,0,0,0.1); }

/* KPIs */
.kpi-card { border: 1px solid rgba(255,255,255,0.15); color: white; min-height: 100px; position: relative; overflow: hidden; }
.kpi-rect { border-radius: 0 !important; }
.kpi-bg-icon { position: absolute; right: -20px; bottom: -20px; opacity: 0.15; transform: rotate(-15deg); pointer-events: none; z-index: 0; i { font-size: 100px; color: white; } }
.kpi-label { font-size: 11px; font-weight: 900; letter-spacing: .2px; text-transform: uppercase; }
.kpi-value { font-size: 20px; font-weight: 900; line-height: 1; }
.bg-gradient-info { background: linear-gradient(135deg, #0288d1, #005b9f); }
.bg-gradient-success { background: linear-gradient(135deg, #2e7d32, #1b5e20); }
.bg-gradient-warning { background: linear-gradient(135deg, #FFB300, #F57F17); }

/* UTILS */
.status-indicator { width: 10px; height: 10px; border-radius: 50%; }
.pulse { animation: pulse-green 2s infinite; }
@keyframes pulse-green { 0% { box-shadow: 0 0 0 0 rgba(0, 200, 83, 0.7); } 70% { box-shadow: 0 0 0 10px rgba(0, 200, 83, 0); } 100% { box-shadow: 0 0 0 0 rgba(0, 200, 83, 0); } }

.list-text-11 { font-size: 11px !important; line-height: 1.25 !important; }
.list-text-10 { font-size: 10px !important; line-height: 1.25 !important; }
.solid-chip { display: inline-flex; align-items: center; justify-content: center; height: 22px; padding: 0 10px; border-radius: 6px; font-size: 10px; font-weight: 900; color: #fff; white-space: nowrap; text-transform: uppercase; }
.chip-success { background: #2e7d32; }
.chip-info { background: #1976d2; }
.chip-error { background: #c62828; }
.h-40 { height: 40px !important; }
.action-btn { width: 28px !important; height: 28px !important; border-radius: 6px !important; color: #fff !important; }
.hover-bg-opacity:hover { background: rgba(0,0,0,0.05); }

/* FIX TOOLTIP */
:deep(.tooltip-dark) { background-color: #333 !important; color: white !important; font-weight: 600; font-size: 11px; border-radius: 6px; }
.custom-scroll::-webkit-scrollbar { width: 6px; }
.custom-scroll::-webkit-scrollbar-track { background: transparent; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.4); border-radius: 4px; }
.h-24 { height: 24px; }

/* FIX AUTOCOMPLETE */
.clean-autocomplete :deep(.v-field__outline) { --v-field-border-opacity: 0.1; }
.clean-autocomplete :deep(.v-field__input) { min-height: 36px; padding-top: 0; padding-bottom: 0; font-size: 13px; font-weight: 600; }
</style>
