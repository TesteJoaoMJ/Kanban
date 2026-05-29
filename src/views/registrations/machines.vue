<template>
  <div
    class="machines-layout font-sans fill-height d-flex flex-column relative overflow-hidden"
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
        <div class="d-flex flex-column">
          <div class="breadcrumb text-caption">
            <span class="opacity-70">Cadastros Base</span>
            <span class="mx-2 opacity-50">></span>
            <span class="font-weight-bold">Máquinas</span>
          </div>
          <div class="text-h6 font-weight-black tracking-tight leading-none mt-1" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">
            Gestão de Máquinas e Equipamentos
          </div>
        </div>
        <div class="d-flex align-center" style="gap: 10px;">
          <v-btn
            color="primary"
            variant="flat"
            class="btn-rect px-4 font-weight-bold text-caption text-uppercase letter-spacing-1 shadow-button"
            prepend-icon="mdi-plus-box"
            height="40"
            @click="openModal(null)"
            v-if="userStore.profile.permissions.includes('mfg_maquinas_cadastrar')"
          >
            Nova Máquina
          </v-btn>
        </div>
      </div>

      <div class="px-6 pt-4 pb-2 flex-shrink-0">
        <v-row dense>
          <v-col cols="12" sm="6" md="4">
            <v-card class="kpi-card kpi-rect bg-gradient-blue-grey hover-elevate py-3 px-4" v-ripple elevation="2">
              <div class="kpi-bg-icon"><v-icon>mdi-cog-box</v-icon></div>
              <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height text-white">
                <div class="d-flex align-center" style="gap: 8px;">
                  <v-icon size="18" class="opacity-80">mdi-monitor-dashboard</v-icon>
                  <span class="kpi-label">Total Cadastrado</span>
                </div>
                <div class="kpi-number-group my-1"><span class="kpi-value">{{ totalMachines }}</span></div>
                <div class="kpi-footer mt-1">Máquinas na Base</div>
              </div>
            </v-card>
          </v-col>
          
          <v-col cols="12" sm="6" md="4">
            <v-card class="kpi-card kpi-rect bg-gradient-success hover-elevate py-3 px-4" v-ripple elevation="2">
              <div class="kpi-bg-icon"><v-icon>mdi-format-list-group</v-icon></div>
              <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height text-white">
                <div class="d-flex align-center" style="gap: 8px;">
                  <v-icon size="18" class="opacity-80">mdi-shape-outline</v-icon>
                  <span class="kpi-label">Tipos Distintos</span>
                </div>
                <div class="kpi-number-group my-1"><span class="kpi-value">{{ distinctTypes }}</span></div>
                <div class="kpi-footer mt-1">Setores/Categorias</div>
              </div>
            </v-card>
          </v-col>

          <v-col cols="12" sm="6" md="4">
            <v-card class="kpi-card kpi-rect bg-gradient-orange hover-elevate py-3 px-4" v-ripple elevation="2">
              <div class="kpi-bg-icon"><v-icon>mdi-calendar-plus</v-icon></div>
              <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height text-white">
                <div class="d-flex align-center" style="gap: 8px;">
                  <v-icon size="18" class="opacity-80">mdi-clock-outline</v-icon>
                  <span class="kpi-label">Adicionadas Recentes</span>
                </div>
                <div class="kpi-number-group my-1"><span class="kpi-value">{{ recentMachines }}</span></div>
                <div class="kpi-footer mt-1">Últimos 30 dias</div>
              </div>
            </v-card>
          </v-col>
        </v-row>
      </div>

      <div class="px-6 pt-2 pb-2 flex-shrink-0">
        <div class="controls-bar d-flex align-center justify-space-between" :class="themeStore.currentMode === 'light' ? 'controls-light' : 'controls-dark'">
          <div class="d-flex align-center flex-wrap" style="gap: 10px; width: 100%;">
            <div class="search-wrap d-flex align-center" :class="themeStore.currentMode === 'light' ? 'search-light' : 'search-dark'" style="flex: 2;">
              <v-icon :color="themeStore.currentMode === 'light' ? 'grey-darken-1' : 'white-70'">mdi-magnify</v-icon>
              <input
                v-model="search"
                type="text"
                placeholder="Buscar por nome da máquina..."
                class="clean-input flex-grow-1 ml-2"
                :class="themeStore.currentMode === 'light' ? 'text-grey-darken-3' : 'text-white'"
              />
            </div>
            
            <v-btn variant="text" class="btn-rect ml-auto" height="40" :color="themeStore.currentMode === 'light' ? 'grey-darken-2' : 'grey-lighten-1'" prepend-icon="mdi-refresh" @click="fetchMachines" :loading="loading">
              Atualizar
            </v-btn>
          </div>
        </div>
      </div>

      <div class="flex-grow-1 px-6 pb-6 overflow-hidden d-flex flex-column">
        <v-card class="flex-grow-1 d-flex flex-column rounded-0 border-thin overflow-hidden" :class="themeStore.currentMode === 'light' ? 'bg-white shadow-sm' : 'glass-card border-white-05'" :elevation="0">
          
          <div class="grid-scroll flex-grow-1 overflow-y-auto custom-scroll">
            <div 
              class="grid-header sticky-head" 
              :class="themeStore.currentMode === 'light' ? 'grid-surface-light' : 'grid-surface-dark'"
              :style="dynamicGridLayout"
            >
              <div class="cell header-text pl-6">Nome da Máquina</div>
              <div class="cell header-text">Tipo (Setor)</div>
              <div class="cell header-text">Data de Cadastro</div>
              <div class="cell center header-text" v-if="hasActionPermission">Ações</div>
            </div>

            <div v-if="loading" class="d-flex flex-column justify-center align-center h-100 py-12">
              <v-progress-circular indeterminate color="primary" size="32" width="3"></v-progress-circular>
            </div>
            <div v-else-if="filteredMachines.length === 0" class="d-flex flex-column justify-center align-center h-100 opacity-60 gap-2 py-12">
              <v-icon size="48" color="grey-lighten-1">mdi-monitor-off</v-icon>
              <span class="text-body-2 font-weight-medium text-grey">Nenhuma máquina encontrada.</span>
            </div>

            <div 
              v-else 
              v-for="(m, index) in filteredMachines" 
              :key="m.id" 
              class="grid-row" 
              :class="[themeStore.currentMode === 'light' ? 'grid-row-light' : 'grid-row-dark', zebraClass(index)]"
              :style="dynamicGridLayout"
            >
              
              <div class="cell pl-6">
                <div class="d-flex align-center w-100">
                  <v-avatar :color="getColor(m.nome)" size="32" variant="tonal" class="rounded-0 mr-3 flex-shrink-0 font-weight-bold text-caption">
                    {{ m.nome?.charAt(0)?.toUpperCase() || 'M' }}
                  </v-avatar>
                  <span class="text-truncate list-text-11 font-weight-black text-uppercase">{{ m.nome }}</span>
                </div>
              </div>

              <div class="cell">
                <v-chip size="x-small" variant="outlined" :color="themeStore.currentMode === 'light' ? 'blue-grey-darken-2' : 'blue-grey-lighten-2'" class="font-weight-bold text-uppercase rounded-2px">
                  {{ m.tipo_info?.nome || 'N/A' }}
                </v-chip>
              </div>

              <div class="cell">
                <span class="list-text-10 font-mono font-weight-medium opacity-80">
                  {{ formatDate(m.created_at) }}
                </span>
              </div>

              <div class="cell center" v-if="hasActionPermission">
                <div class="actions-inline">
                  <v-tooltip text="Editar" location="top" content-class="bg-black text-white font-weight-bold" v-if="userStore.profile.permissions.includes('mfg_maquinas_editar')">
                    <template v-slot:activator="{ props }">
                      <v-btn v-bind="props" icon size="x-small" class="action-btn action-edit" @click="openModal(m)">
                        <v-icon size="16">mdi-pencil</v-icon>
                      </v-btn>
                    </template>
                  </v-tooltip>
                  <v-tooltip text="Excluir" location="top" content-class="bg-black text-white font-weight-bold" v-if="userStore.profile.permissions.includes('mfg_maquinas_excluir')">
                    <template v-slot:activator="{ props }">
                      <v-btn v-bind="props" icon size="x-small" class="action-btn action-del" @click="deleteMachine(m.id, m.nome)">
                        <v-icon size="16">mdi-trash-can-outline</v-icon>
                      </v-btn>
                    </template>
                  </v-tooltip>
                </div>
              </div>

            </div>
          </div>
          
          <div class="flex-shrink-0 border-t px-4 py-2 d-flex align-center justify-space-between" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-4 text-grey-darken-3' : 'bg-white-05 text-white'">
            <div class="text-caption opacity-80 font-weight-bold">
              Total nesta visão: <strong class="font-mono">{{ filteredMachines.length }}</strong>
            </div>
          </div>

        </v-card>
      </div>

    </div>

    <MachineDetailsModal v-model:show="modal.show" :machine="modal.data" @refresh="fetchMachines" />
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, reactive } from 'vue';
import { supabase } from '@/api/supabase';
import { useThemeStore } from '@/stores/themeStore';
import { useCompanyStore } from '@/stores/company';
import { useUserStore } from '@/stores/user';
import { format } from 'date-fns';
import MachineDetailsModal from '@/components/registrations/MachineDetailsModal.vue';

const themeStore = useThemeStore();
const companyStore = useCompanyStore();
const userStore = useUserStore();

const machines = ref<any[]>([]);
const loading = ref(false);
const search = ref('');

const modal = reactive({ show: false, data: null });

// Helpers
const getColor = (name: string) => {
  const colors = ['primary', 'info', 'success', 'warning', 'blue-grey', 'teal', 'indigo'];
  let hash = 0;
  if(!name) return 'grey';
  for(let i=0; i<name.length; i++) hash = name.charCodeAt(i) + ((hash << 5) - hash);
  return colors[Math.abs(hash) % colors.length];
};

const formatDate = (dateString: string) => {
  if (!dateString) return '-';
  try {
    return format(new Date(dateString), 'dd/MM/yyyy HH:mm');
  } catch (e) {
    return dateString;
  }
};

const zebraClass = (index: number) => {
  if (themeStore.currentMode === 'light') {
    return index % 2 === 0 ? 'zebra-light-a' : 'zebra-light-b';
  }
  return index % 2 === 0 ? 'zebra-dark-a' : 'zebra-dark-b';
};

// Data Fetching
const fetchMachines = async () => {
  loading.value = true;
  try {
    const { data, error } = await supabase
      .from('machines')
      .select(`
        id,
        nome,
        tipo,
        created_at,
        tipo_info:type_machines(nome)
      `)
      .order('created_at', { ascending: false })
      .eq('empresa_id', companyStore.currentCompany?.id);
      
    if (error) throw error;
    machines.value = data || [];
  } catch (error: any) {
    console.error("Erro ao carregar máquinas:", error.message);
  } finally {
    loading.value = false;
  }
};

// Computed Properties (Search, KPIs & Layout)
const hasActionPermission = computed(() => {
  const perms = userStore.profile?.permissions || [];
  return perms.includes('mfg_maquinas_editar') || perms.includes('mfg_maquinas_excluir');
});

const dynamicGridLayout = computed(() => ({
  gridTemplateColumns: hasActionPermission.value 
    ? '2fr 1.5fr 1.5fr 100px' 
    : '2fr 1.5fr 1.5fr'
}));

const filteredMachines = computed(() => {
  let list = machines.value;
  if (search.value) {
    const s = search.value.toLowerCase();
    list = list.filter(m => 
      m.nome?.toLowerCase().includes(s)
    );
  }
  return list;
});

const totalMachines = computed(() => machines.value.length);

const distinctTypes = computed(() => {
  const types = new Set(machines.value.map(m => m.tipo_info?.nome).filter(Boolean));
  return types.size;
});

const recentMachines = computed(() => {
  const thirtyDaysAgo = new Date();
  thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
  return machines.value.filter(m => new Date(m.created_at) >= thirtyDaysAgo).length;
});

// Actions
const openModal = (m: any) => {
   modal.data = m;
   modal.show = true;
};

const deleteMachine = async (id: string, name: string) => {
  if(confirm(`Tem certeza que deseja excluir a máquina "${name}"?`)) {
    try {
      loading.value = true;
      const { error } = await supabase.from('machines').delete().eq('id', id);
      if(error) throw error;
      await fetchMachines();
    } catch(error: any) {
      alert("Erro ao deletar: " + error.message);
    } finally {
      loading.value = false;
    }
  }
};

onMounted(fetchMachines);
</script>

<style scoped>
.machines-layout {
  position: relative;
}

.background-carousel-wrapper {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  z-index: 0;
  pointer-events: none;
  opacity: 0.6;
}

.background-overlay {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  z-index: 1;
  background: radial-gradient(circle at center, rgba(15, 15, 19, 0.6), rgba(15, 15, 19, 0.98));
  backdrop-filter: blur(10px);
}

.z-10 { position: relative; z-index: 10; }
.bg-glass-dark { background: rgba(10,10,12,0.85); }
.bg-glass-header { background: rgba(20,20,24,0.55); backdrop-filter: blur(14px); }
.border-bottom-white-05 { border-bottom: 1px solid rgba(255,255,255,0.08); }
.border-thin { border: 1px solid rgba(0,0,0,0.08); }
.bg-white-05 { background: rgba(255,255,255,0.05); }

/* CONTROLS */
.controls-bar { border: 1px solid rgba(0,0,0,0.08); border-radius: 0; padding: 10px; }
.controls-light { background: #ffffff; }
.controls-dark { background: rgba(30,30,35,0.55); backdrop-filter: blur(16px); border: 1px solid rgba(255,255,255,0.08); }
.search-wrap { height: 40px; border-radius: 0; padding: 0 12px; }
.search-light { background: #f4f6f8; border: 1px solid rgba(0,0,0,0.08); }
.search-dark { background: rgba(255,255,255,0.08); border: 1px solid rgba(255,255,255,0.10); }
.clean-input { border: none; outline: none; background: transparent; font-size: 12px; color: inherit; width: 100%; }
.btn-rect { border-radius: 0 !important; text-transform: none !important; font-weight: 800; }

/* KPIs */
.kpi-card { border: 1px solid rgba(255,255,255,0.15); color: white; min-height: 100px; position: relative; overflow: hidden; }
.kpi-rect { border-radius: 0 !important; }
.kpi-bg-icon { position: absolute; right: -20px; bottom: -20px; opacity: 0.15; transform: rotate(-15deg); pointer-events: none; z-index: 0; }
.kpi-bg-icon .v-icon { font-size: 80px; color: white; }
.kpi-label { font-size: 11px; font-weight: 900; letter-spacing: .2px; text-transform: uppercase; }
.kpi-value { font-size: 24px; font-weight: 900; letter-spacing: .2px; font-family: monospace; }
.kpi-footer { font-size: 10px; opacity: .9; font-weight: 700; text-transform: uppercase; }
.bg-gradient-blue-grey { background: linear-gradient(135deg, #546e7a, #37474f); }
.bg-gradient-success { background: linear-gradient(135deg, #2e7d32, #1b5e20); }
.bg-gradient-orange { background: linear-gradient(135deg, #ef6c00, #bf360c); }

/* GRID LAYOUT */
.glass-card { background: rgba(30, 30, 35, 0.45); backdrop-filter: blur(25px); border: 1px solid rgba(255,255,255,0.08); }
.grid-scroll { scrollbar-gutter: stable both-edges; }
.custom-scroll::-webkit-scrollbar { width: 8px; height: 8px; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.35); border-radius: 0px; }

.grid-header, .grid-row { display: grid; align-items: stretch; width: 100%; border-bottom: 1px solid rgba(0,0,0,0.08); }
.cell { padding: 8px 10px; display: flex; align-items: center; border-right: 1px solid rgba(0,0,0,0.08); min-height: 52px; overflow: hidden; }
.cell:last-child { border-right: none; }
.center { justify-content: center; text-align: center; }

.grid-header .cell { min-height: 44px; font-size: 11px; font-weight: 900; text-transform: uppercase; letter-spacing: .6px; }
.header-text { font-size: 11px; }

.grid-surface-light .cell { background: #f5f7fa; color: rgba(0,0,0,0.7); border-color: rgba(0,0,0,0.10); }
.grid-surface-dark .cell { background: rgba(255,255,255,0.08); color: rgba(255,255,255,0.80); border-color: rgba(255,255,255,0.10); }

.grid-row-light .cell { background: #fff; border-color: rgba(0,0,0,0.08); color: #333; }
.zebra-light-a .cell { background: #ffffff; }
.zebra-light-b .cell { background: #f8fafc; }
.grid-row-light:hover .cell { background: #f1f5f9; cursor: pointer; }

.grid-row-dark .cell { background: rgba(255,255,255,0.04); border-color: rgba(255,255,255,0.08); }
.zebra-dark-a .cell { background: rgba(15, 23, 42, 0.82); }
.zebra-dark-b .cell { background: rgba(30, 41, 59, 0.72); }
.grid-row-dark:hover .cell { background: rgba(59, 130, 246, 0.08); cursor: pointer; }

.sticky-head { position: sticky; top: 0; z-index: 10; }
.list-text-11 { font-size: 11px !important; line-height: 1.25 !important; }
.list-text-10 { font-size: 10px !important; line-height: 1.25 !important; }
.rounded-2px { border-radius: 2px !important; }

/* ACTIONS */
.actions-inline { display: flex; align-items: center; justify-content: center; gap: 6px; }
.action-btn { width: 28px !important; height: 28px !important; border-radius: 4px !important; color: #fff !important; }
.action-edit { background: #1976d2 !important; }
.action-del { background: #c62828 !important; }
</style>