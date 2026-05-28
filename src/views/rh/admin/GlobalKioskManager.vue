<template>
  <div class="d-flex flex-column flex-grow-1 overflow-hidden h-100 relative bg-transparent">

    <div class="d-flex flex-grow-1 overflow-hidden h-100 w-100 relative">

      <div
        class="kiosk-list border-e d-flex flex-column transition-all flex-shrink-0 z-10"
        style="width: 380px; min-width: 380px;"
        :class="isLightMode ? 'border-grey-lighten-2 bg-grey-lighten-5' : 'border-white-05 bg-black-20'"
      >
        <div class="px-5 py-4 border-b d-flex align-center justify-space-between flex-shrink-0" :class="isLightMode ? 'border-grey-lighten-2 bg-white' : 'border-white-05 bg-black-40'">
          <div class="d-flex flex-column">
            <span class="text-[9px] font-weight-black text-uppercase tracking-widest opacity-60 mb-n1">Terminais Georreferenciados</span>
            <span class="text-subtitle-2 font-weight-black text-primary">Totens Operacionais</span>
          </div>
          <v-chip size="small" color="primary" class="font-weight-black chip-3d px-3 rounded-sm">{{ kiosks.length }}</v-chip>
        </div>

        <div class="pa-4 border-b flex-shrink-0" :class="isLightMode ? 'border-grey-lighten-2 bg-white' : 'border-white-05 bg-black-20'">
           <v-text-field
             v-model="searchQuery"
             placeholder="Filtrar por totem, cidade ou IP..."
             variant="outlined"
             density="compact"
             hide-details
             prepend-inner-icon="mdi-magnify"
             class="ui-field font-weight-bold"
             :bg-color="isLightMode ? 'bg-grey-lighten-4' : 'rgba(0,0,0,0.4)'"
             :color="isLightMode ? 'primary' : 'white'"
           ></v-text-field>
        </div>

        <div class="flex-grow-1 overflow-y-auto custom-scroll pa-4 d-flex flex-column">
          <div v-if="Object.keys(groupedKiosks).length === 0" class="text-center opacity-40 text-caption font-weight-black mt-10 text-uppercase tracking-widest">
            Nenhum totem localizado.
          </div>

          <div v-for="(group, city) in groupedKiosks" :key="city" class="mb-6">
             <div class="sticky-head d-flex align-center gap-2 mb-3 pa-2 rounded-sm border-thin shadow-sm backdrop-blur-md" :class="isLightMode ? 'bg-white-80 border-grey-lighten-2' : 'bg-black-60 border-white-10 text-white'">
                <v-icon size="14" color="primary">mdi-map-marker-radius-outline</v-icon>
                <span class="text-[10px] font-weight-black text-uppercase tracking-widest">{{ city }}</span>
                <v-chip size="x-small" color="primary" variant="tonal" class="ml-auto font-weight-bold rounded-sm">{{ group.length }}</v-chip>
             </div>

             <div class="d-flex flex-column gap-3">
                <div
                  v-for="k in group" :key="k.id"
                  class="rounded-sm border-thin cursor-pointer transition-all relative overflow-hidden group/card shadow-sm"
                  :class="[
                    selectedKioskAdminId === k.id ? (isLightMode ? 'border-primary shadow-md' : 'border-primary shadow-neon-primary') : (isLightMode ? 'border-grey-lighten-2 hover-bg-row' : 'border-white-10 hover-bg-glass'),
                    isLightMode ? 'kiosk-card-light' : 'kiosk-card-dark'
                  ]"
                  style="min-height: 80px;"
                  @click="selectedKioskAdminId = k.id"
                >
                  <div class="d-flex justify-space-between align-center h-100 relative z-10 pa-3">

                     <div class="d-flex flex-column flex-grow-1 min-w-0 pr-2">
                        <div class="d-flex align-center gap-2 mb-1">
                           <v-icon :color="selectedKioskAdminId === k.id ? 'primary' : (isLightMode ? 'grey' : 'white-50')" size="16">mdi-tablet-dashboard</v-icon>
                           <span class="font-weight-black text-[12px] text-truncate" :class="selectedKioskAdminId === k.id ? 'text-primary' : (isLightMode ? 'text-grey-darken-4' : 'text-white')">{{ k.name }}</span>
                        </div>
                        <div class="text-[9px] font-mono opacity-60 d-flex align-center gap-1 pl-6">
                           <v-icon size="10">mdi-ip-network-outline</v-icon>{{ k.allowed_ip || 'Sem IP Fixo (Dinâmico)' }}
                        </div>
                     </div>

                     <div class="flex-shrink-0 d-flex align-center justify-end">
                        <v-btn icon="mdi-crosshairs-gps" size="small" variant="tonal" color="primary" class="btn-3d rounded-sm bg-white" @click.stop="openDrawer(k)">
                          <v-icon size="16">mdi-map-marker-radius</v-icon>
                          <v-tooltip activator="parent" location="top" text="Inspecionar & Editar Configurações" content-class="premium-tooltip" />
                        </v-btn>
                     </div>
                  </div>

                  <div v-if="selectedKioskAdminId === k.id" class="absolute left-0 top-0 h-100 bg-primary" style="width: 4px; z-index: 20;"></div>
                </div>
             </div>
          </div>
        </div>
      </div>

      <div class="flex-grow-1 d-flex flex-column bg-transparent overflow-hidden relative z-0">
        <div v-if="!selectedKioskAdminId" class="h-100 d-flex flex-column align-center justify-center opacity-30">
          <v-icon size="64" class="mb-3">mdi-gesture-tap-select</v-icon>
          <span class="text-subtitle-1 font-weight-black text-uppercase tracking-widest">Selecione um Totem</span>
          <span class="text-[11px] font-weight-bold uppercase tracking-widest mt-1">Gerencie permissões ao lado</span>
        </div>

        <template v-else>
          <div class="px-6 py-4 border-b d-flex align-center justify-space-between flex-shrink-0" :class="isLightMode ? 'border-grey-lighten-2 bg-white' : 'border-white-05 bg-black-40'">
            <div class="d-flex align-center gap-4">
               <div class="icon-box rounded-sm d-flex align-center justify-center transition-all"
                    :class="isLightMode ? 'bg-primary-lighten-5 text-primary border border-primary-lighten-4' : 'bg-white-05 text-white border border-white-10'"
                    style="width: 36px; height: 36px;">
                  <v-icon size="18">mdi-account-check</v-icon>
               </div>
               <div>
                  <h3 class="text-subtitle-2 font-weight-black text-uppercase tracking-widest lh-1" :class="isLightMode ? 'text-grey-darken-4' : 'text-white'">Permissões: {{ selectedKioskInfo?.name }}</h3>
                  <p class="text-[10px] opacity-60 font-weight-bold text-uppercase tracking-widest mt-1">Colaboradores autorizados na máquina</p>
               </div>
            </div>
            <div class="d-flex gap-3">
              <v-btn variant="tonal" color="primary" class="btn-3d font-weight-bold text-[10px] px-4 rounded-sm" height="34" @click="toggleAllKioskEmployees">
                {{ selectedKioskEmployees.length === employees.length ? 'Desmarcar Todos' : 'Selecionar Todos' }}
              </v-btn>
              <v-btn variant="flat" color="success" class="btn-3d font-weight-black px-6 text-[10px] tracking-widest rounded-sm" height="34" prepend-icon="mdi-content-save-check" @click="saveKioskAssignments" :loading="savingAssignmentsGlobal">
                CRAVAR VÍNCULOS
              </v-btn>
            </div>
          </div>

          <div class="flex-grow-1 overflow-y-auto custom-scroll pa-6" :class="isLightMode ? 'bg-grey-lighten-5' : 'bg-transparent'">
            <v-row dense>
              <v-col cols="12" sm="6" md="4" lg="3" v-for="emp in employees" :key="emp.id">
                <div class="user-perm-card pa-2 rounded-sm border-thin d-flex align-center gap-3 transition-all cursor-pointer h-100 relative overflow-hidden"
                     :class="[
                        isLightMode ? 'bg-white hover-bg-row' : 'bg-grey-darken-4 hover-bg-glass',
                        selectedKioskEmployees.includes(emp.id) ? (isLightMode ? 'border-primary bg-blue-lighten-5' : 'border-primary shadow-neon-primary bg-black-40') : ''
                     ]"
                     @click="toggleEmployeeInKiosk(emp.id)">

                  <div class="checkbox-wrapper flex-shrink-0 pl-1">
                     <v-icon :color="selectedKioskEmployees.includes(emp.id) ? 'primary' : 'grey-lighten-1'" size="18">
                        {{ selectedKioskEmployees.includes(emp.id) ? 'mdi-checkbox-marked-circle' : 'mdi-checkbox-blank-circle-outline' }}
                     </v-icon>
                  </div>

                  <v-avatar size="28" class="border-thin shadow-sm flex-shrink-0" :image="emp.avatar_url || avatarFor(emp.nome)"></v-avatar>

                  <div class="overflow-hidden d-flex flex-column justify-center flex-grow-1 min-w-0" style="line-height: 1.1;">
                    <div class="font-weight-black text-[11px] text-truncate" :class="isLightMode ? 'text-grey-darken-4' : 'text-white'">{{ emp.nome }}</div>
                    <div class="text-[9px] font-weight-bold opacity-60 text-uppercase tracking-tighter text-truncate mt-1">{{ emp.cargo || emp.role || 'Sem cargo' }}</div>
                  </div>
                </div>
              </v-col>
            </v-row>
          </div>
        </template>
      </div>

      <div
        class="kiosk-drawer absolute top-0 bottom-0 shadow-2xl transition-transform d-flex flex-column border-l"
        :class="[
          showDrawer ? 'translate-x-0' : 'translate-x-full',
          isLightMode ? 'bg-white border-grey-lighten-2' : 'bg-grey-darken-4 border-white-10'
        ]"
        style="width: 480px; right: 0; z-index: 100;"
      >
        <div class="px-5 py-4 border-b d-flex align-center justify-space-between flex-shrink-0" :class="isLightMode ? 'bg-primary text-white border-grey-lighten-2' : 'bg-black-40 border-white-10 text-white'">
           <div>
              <h3 class="text-subtitle-1 font-weight-black text-uppercase tracking-widest lh-1 d-flex align-center gap-2">
                <v-icon size="20">mdi-map-marker-radius</v-icon> Inspetoria do Totem
              </h3>
              <p class="text-[10px] font-weight-bold opacity-70 text-uppercase tracking-widest mt-1 mb-0">Arraste o pin no mapa para recalcular a âncora.</p>
           </div>
           <v-btn icon="mdi-close" variant="text" size="small" :color="isLightMode ? 'white' : 'grey'" @click="closeDrawer"></v-btn>
        </div>

        <div class="flex-grow-1 overflow-y-auto custom-scroll d-flex flex-column">
           <div class="relative w-100 border-b flex-shrink-0" :class="isLightMode ? 'border-grey-lighten-2 bg-grey-lighten-4' : 'border-white-10 bg-black'" style="height: 240px;">
              <div id="drawer-map-container" class="w-100 h-100"></div>

              <div class="absolute bottom-2 left-2 z-[1000] pointer-events-none">
                 <v-card class="glass-panel px-3 py-1 rounded-sm border-white-10 shadow-sm" elevation="0" style="background: rgba(18,18,22,0.85) !important;">
                    <div class="text-[9px] font-mono text-white opacity-80">Lat: {{ editingKiosk?.lat?.toFixed(5) || 0 }} / Lng: {{ editingKiosk?.lng?.toFixed(5) || 0 }}</div>
                 </v-card>
              </div>
           </div>

           <div class="pa-6 d-flex flex-column gap-5 flex-grow-1">

              <div>
                <label class="text-[10px] font-weight-black text-uppercase opacity-70 tracking-widest mb-1 d-block" :class="isLightMode ? 'text-grey-darken-4' : 'text-white'">Nomenclatura da Máquina</label>
                <v-text-field v-model="editingKiosk.name" variant="outlined" density="comfortable" hide-details class="ui-field font-weight-bold" :bg-color="isLightMode ? 'bg-grey-lighten-5' : 'rgba(0,0,0,0.2)'" :color="isLightMode ? 'primary' : 'white'"></v-text-field>
              </div>

              <v-row dense>
                 <v-col cols="6">
                   <div>
                     <label class="text-[10px] font-weight-black text-uppercase opacity-70 tracking-widest mb-1 d-block" :class="isLightMode ? 'text-grey-darken-4' : 'text-white'">Restrição de IP</label>
                     <v-text-field v-model="editingKiosk.allowed_ip" placeholder="Ex: 192.168.1.1" variant="outlined" density="comfortable" hide-details class="ui-field font-mono font-weight-bold text-primary" :bg-color="isLightMode ? 'bg-grey-lighten-5' : 'rgba(0,0,0,0.2)'"></v-text-field>
                   </div>
                 </v-col>
                 <v-col cols="6">
                   <div>
                     <label class="text-[10px] font-weight-black text-uppercase opacity-70 tracking-widest mb-1 d-block" :class="isLightMode ? 'text-grey-darken-4' : 'text-white'">Raio Máximo</label>
                     <v-text-field v-model.number="editingKiosk.max_radius_meters" type="number" variant="outlined" density="comfortable" hide-details class="ui-field font-mono font-weight-bold text-warning" :bg-color="isLightMode ? 'bg-grey-lighten-5' : 'rgba(0,0,0,0.2)'"></v-text-field>
                   </div>
                 </v-col>
              </v-row>

              <div class="mt-4 pa-4 rounded-sm border-thin shadow-sm d-flex gap-3 align-start" :class="isLightMode ? 'bg-blue-lighten-5 border-blue-lighten-3' : 'bg-primary-darken-4 bg-opacity-20 border-primary border-opacity-25'">
                 <v-icon color="primary" size="24">mdi-shield-check-outline</v-icon>
                 <div class="d-flex flex-column">
                    <span class="text-[11px] font-weight-black text-uppercase tracking-widest text-primary mb-1">Trava de Perímetro Ativa</span>
                    <span class="text-caption font-weight-bold opacity-80" style="line-height: 1.3;" :class="isLightMode ? 'text-grey-darken-3' : 'text-white'">Qualquer tentativa de registro fora deste círculo azul georreferenciado ou fora do IP designado será bloqueada pelo sistema.</span>
                 </div>
              </div>
           </div>
        </div>

        <div class="pa-4 border-t flex-shrink-0 d-flex justify-end gap-3" :class="isLightMode ? 'bg-grey-lighten-4 border-grey-lighten-2' : 'bg-black-40 border-white-10'">
           <v-btn variant="outlined" class="btn-3d font-weight-bold text-caption px-6 rounded-sm" height="42" @click="closeDrawer" :disabled="savingDrawer">Cancelar</v-btn>
           <v-btn color="success" variant="flat" class="btn-3d font-weight-black text-caption tracking-widest px-8 rounded-sm" height="42" prepend-icon="mdi-content-save-all" @click="saveKioskDetails" :loading="savingDrawer">CRAVAR DADOS</v-btn>
        </div>
      </div>

      <div v-if="showDrawer" class="absolute inset-0 bg-black transition-opacity z-50 cursor-pointer" style="opacity: 0.6;" @click="closeDrawer"></div>

    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch, nextTick, onUnmounted } from 'vue';
import { storeToRefs } from 'pinia';
import { useThemeStore } from '@/stores/theme';
import { useTimeTrackingStore } from '@/stores/timeTracking';
import { supabase } from '@/api/supabase';

const emit = defineEmits(['show-toast']);

// Stores
const themeStore = useThemeStore();
const timeStore = useTimeTrackingStore();

// Refs Dinâmicas
const isLightMode = computed(() => themeStore.currentMode === 'light');
const { employees, kiosks, kioskUsers } = storeToRefs(timeStore);

// Estados de UI e Formulário
const viewMode = ref<'list'>('list');
const searchQuery = ref('');
const selectedKioskAdminId = ref<string | null>(null);
const selectedKioskEmployees = ref<string[]>([]);
const savingAssignmentsGlobal = ref(false);

// Drawer & Inspect
const showDrawer = ref(false);
const savingDrawer = ref(false);
const editingKiosk = ref<any>({ id:'', name:'', allowed_ip:'', max_radius_meters:50, lat:0, lng:0, store_id:null });

// Mapa Leaflet
let LMap: any = null;
let leafletMarker: any = null;
let leafletCircle: any = null;

// Utilitário Avatar
const avatarFor = (n: string) => {
  if (!n) return '';
  return `https://ui-avatars.com/api/?name=${encodeURIComponent(n)}&background=111&color=fff`;
};

// AGRUPAMENTO E FILTRO DE TOTENS POR CIDADE/LOJA
const groupedKiosks = computed(() => {
  const groups: Record<string, any[]> = {};
  kiosks.value.forEach(k => {
     // Filtro de busca
     if (searchQuery.value) {
        const term = searchQuery.value.toLowerCase();
        const city = k.stores?.name?.toLowerCase() || '';
        if (!k.name.toLowerCase().includes(term) && !k.allowed_ip?.includes(term) && !city.includes(term)) return;
     }
     const city = k.stores?.name || 'Sede / Global';
     if (!groups[city]) groups[city] = [];
     groups[city].push(k);
  });
  return groups;
});

// Observa seleção de totem para carregar checkboxes
watch(selectedKioskAdminId, (kId) => {
  if (!kId) {
    selectedKioskEmployees.value = [];
  } else {
    selectedKioskEmployees.value = kioskUsers.value
      .filter((ku: any) => ku.kiosk_id === kId)
      .map((ku: any) => ku.employee_id);
  }
});

const selectedKioskInfo = computed(() => kiosks.value.find(k => k.id === selectedKioskAdminId.value));

// Ações de Checkbox
const toggleEmployeeInKiosk = (empId: string) => {
  const idx = selectedKioskEmployees.value.indexOf(empId);
  if (idx > -1) selectedKioskEmployees.value.splice(idx, 1);
  else selectedKioskEmployees.value.push(empId);
};

const toggleAllKioskEmployees = () => {
  if (selectedKioskEmployees.value.length === employees.value.length) selectedKioskEmployees.value = [];
  else selectedKioskEmployees.value = employees.value.map(e => e.id);
};

// Salvar Vínculos
const saveKioskAssignments = async () => {
  if (!selectedKioskAdminId.value) return;
  savingAssignmentsGlobal.value = true;
  try {
    await supabase.from('time_tracking_kiosk_users').delete().eq('kiosk_id', selectedKioskAdminId.value);
    if (selectedKioskEmployees.value.length > 0) {
      const payload = selectedKioskEmployees.value.map(empId => ({ kiosk_id: selectedKioskAdminId.value, employee_id: empId }));
      await supabase.from('time_tracking_kiosk_users').insert(payload);
    }
    const { data } = await supabase.from('time_tracking_kiosk_users').select('*');
    if (data) timeStore.kioskUsers = data;
    emit('show-toast', { message: 'Acessos atualizados com sucesso.', color: 'success' });
  } catch(e: any) {
    emit('show-toast', { message: 'Erro ao gravar vínculos.', color: 'error' });
  } finally {
    savingAssignmentsGlobal.value = false;
  }
};

// --- LOGICA DE DRAWER E MAPS (DRAG PIN) ---
const injectLeaflet = (): Promise<any> => {
  return new Promise((resolve) => {
    if ((window as any).L) return resolve((window as any).L);
    const css = document.createElement('link');
    css.rel = 'stylesheet'; css.href = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.css';
    document.head.appendChild(css);
    const script = document.createElement('script');
    script.src = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.js';
    script.onload = () => resolve((window as any).L);
    document.head.appendChild(script);
  });
};

const openDrawer = async (kiosk: any) => {
  editingKiosk.value = JSON.parse(JSON.stringify(kiosk)); // Clona objeto para não alterar a tabela direto
  showDrawer.value = true;

  await nextTick();
  const L = await injectLeaflet();

  if (!LMap) {
    LMap = L.map('drawer-map-container', { zoomControl: false, attributionControl: false });
    const tiles = L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', { maxZoom: 19 });
    if (!isLightMode.value) tiles.options.className = 'dark-map-tiles';
    tiles.addTo(LMap);
  }

  LMap.setView([editingKiosk.value.lat, editingKiosk.value.lng], 18);

  // Timeout obrigatório para Leaflet renderizar tiles certas após display: block / resize
  setTimeout(() => { LMap.invalidateSize(); }, 300);

  if (leafletCircle) leafletCircle.remove();
  if (leafletMarker) leafletMarker.remove();

  leafletCircle = L.circle([editingKiosk.value.lat, editingKiosk.value.lng], {
    color: '#1976D2', fillColor: '#1976D2', fillOpacity: 0.15,
    radius: editingKiosk.value.max_radius_meters, weight: 2
  }).addTo(LMap);

  const customIcon = L.divIcon({
    className: 'custom-kiosk-marker',
    html: `<div class="pulse-pin-container"><div class="pulse-core"></div></div>`,
    iconSize: [24, 24],
    iconAnchor: [12, 12]
  });

  leafletMarker = L.marker([editingKiosk.value.lat, editingKiosk.value.lng], {
      draggable: true,
      icon: customIcon
  }).addTo(LMap);

  // Anima o círculo junto com o drag
  leafletMarker.on('drag', (e: any) => {
     const newPos = e.target.getLatLng();
     leafletCircle.setLatLng(newPos);
  });

  // Atualiza coords ao soltar o pin
  leafletMarker.on('dragend', (e: any) => {
     const newPos = e.target.getLatLng();
     editingKiosk.value.lat = newPos.lat;
     editingKiosk.value.lng = newPos.lng;
  });
};

// Reatividade de Raio ao digitar no input
watch(() => editingKiosk.value.max_radius_meters, (newVal) => {
   if (leafletCircle) leafletCircle.setRadius(newVal || 10);
});

const closeDrawer = () => {
    showDrawer.value = false;
};

const saveKioskDetails = async () => {
   savingDrawer.value = true;
   try {
      const payload = {
         name: editingKiosk.value.name,
         allowed_ip: editingKiosk.value.allowed_ip,
         max_radius_meters: editingKiosk.value.max_radius_meters,
         lat: editingKiosk.value.lat,
         lng: editingKiosk.value.lng
      };

      const { error } = await supabase.from('time_tracking_kiosks').update(payload).eq('id', editingKiosk.value.id);
      if (error) throw error;

      // Atualiza a store local
      const idx = timeStore.kiosks.findIndex((k: any) => k.id === editingKiosk.value.id);
      if (idx !== -1) {
         timeStore.kiosks[idx] = { ...timeStore.kiosks[idx], ...payload };
      }

      showDrawer.value = false;
      emit('show-toast', { message: 'Totem atualizado com sucesso.', color: 'success' });
   } catch(e) {
      emit('show-toast', { message: 'Erro ao atualizar totem.', color: 'error' });
   } finally {
      savingDrawer.value = false;
   }
};

onUnmounted(() => {
    if (LMap) LMap.remove();
});
</script>

<style lang="scss">
/* Filtro global para tiles do mapa dark mode */
.dark-map-tiles { filter: invert(100%) hue-rotate(180deg) brightness(85%) contrast(110%) !important; }

/* Tooltip Premium */
.premium-tooltip {
  background: rgba(18, 18, 22, 0.95) !important;
  border: 1px solid rgba(255, 255, 255, 0.15) !important;
  backdrop-filter: blur(10px); box-shadow: 0 8px 24px rgba(0,0,0,0.5) !important;
  color: white !important; border-radius: 4px; padding: 4px 8px; font-weight: 800; text-transform: uppercase; font-size: 9px !important; letter-spacing: 0.05em;
}

/* Pin Estilizado */
.custom-kiosk-marker .pulse-pin-container {
  width: 24px; height: 24px; display: flex; align-items: center; justify-content: center; position: relative;
}
.custom-kiosk-marker .pulse-core {
  width: 14px; height: 14px; background: #1976D2; border: 2px solid white; border-radius: 50%; box-shadow: 0 0 10px rgba(0,0,0,0.8); z-index: 2;
}
.custom-kiosk-marker .pulse-pin-container::after {
  content: ''; position: absolute; inset: 0; background: rgba(25, 118, 210, 0.6); border-radius: 50%; z-index: 1; animation: pulse-gps 2s infinite;
}
@keyframes pulse-gps {
  0% { transform: scale(0.8); opacity: 1; }
  100% { transform: scale(2.5); opacity: 0; }
}
</style>

<style scoped lang="scss">
/* Estética Base */
.border-white-05 { border-color: rgba(255, 255, 255, 0.05) !important; }
.bg-black-20 { background-color: rgba(0,0,0,0.2) !important; }
.bg-black-40 { background-color: rgba(0,0,0,0.4) !important; }
.bg-black-60 { background-color: rgba(0,0,0,0.6) !important; }
.bg-white-80 { background-color: rgba(255,255,255,0.8) !important; }
.rounded-sm { border-radius: 4px !important; }
.border-thin { border: 1px solid rgba(128, 128, 128, 0.15) !important; }

/* Tipografia */
.tracking-widest { letter-spacing: 0.05em; }
.tracking-tighter { letter-spacing: -0.05em; }
.lh-1 { line-height: 1.1; }

/* Cards de Kiosk na Lista Esquerda (Map Gradients) */
.kiosk-card-light {
  background: linear-gradient(90deg, #ffffff 40%, rgba(255,255,255,0.6) 100%), url("data:image/svg+xml,%3Csvg width='40' height='40' viewBox='0 0 40 40' xmlns='http://www.w3.org/2000/svg'%3E%3Cpath d='M0 0h40v40H0V0zm20 20h20v20H20V20zM0 20h20v20H0V20z' fill='%231976d2' fill-opacity='0.03' fill-rule='evenodd'/%3E%3C/svg%3E");
  background-size: cover; background-position: right center;
}
.kiosk-card-dark {
  background: linear-gradient(90deg, #1e1e24 40%, rgba(30,30,36,0.6) 100%), url("data:image/svg+xml,%3Csvg width='40' height='40' viewBox='0 0 40 40' xmlns='http://www.w3.org/2000/svg'%3E%3Cpath d='M0 0h40v40H0V0zm20 20h20v20H20V20zM0 20h20v20H0V20z' fill='%231976d2' fill-opacity='0.1' fill-rule='evenodd'/%3E%3C/svg%3E");
  background-size: cover; background-position: right center;
}

/* Cards de Usuário */
.user-perm-card { transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1); border-left: 2px solid transparent !important; height: 44px; }
.user-perm-card:hover { transform: translateY(-1px); }
.border-primary { border-color: rgb(var(--v-theme-primary)) !important; border-left-color: rgb(var(--v-theme-primary)) !important; }
.shadow-neon-primary { box-shadow: inset 0 0 15px rgba(var(--v-theme-primary), 0.15); }

/* Glassmorphism e Inspeção */
.glass-header { background: rgba(20,20,25,0.7); backdrop-filter: blur(12px); -webkit-backdrop-filter: blur(12px); }
.glass-panel { background: rgba(24, 24, 28, 0.85) !important; backdrop-filter: blur(20px); border: 1px solid rgba(255,255,255,0.1) !important; }
.shadow-neon-elegant { box-shadow: 0 12px 40px rgba(0,0,0,0.6), inset 0 0 0 1px rgba(255,255,255,0.05); }

/* Drawer Deslizante */
.kiosk-drawer {
  transform: translateX(100%);
}
.kiosk-drawer.translate-x-0 {
  transform: translateX(0);
}
.kiosk-drawer.translate-x-full {
  transform: translateX(100%);
}

.metadata-row {
  display: flex; flex-direction: column; gap: 2px;
  .label { font-size: 8px; text-transform: uppercase; font-weight: 900; opacity: 0.5; letter-spacing: 0.1em; }
  .value { font-size: 11px; font-weight: 800; line-height: 1.2; }
}

/* Botões e Interações */
.btn-3d { box-shadow: 0 3px 5px rgba(0,0,0,0.1), inset 0 2px 0 rgba(255,255,255,0.15) !important; text-transform: none !important; }
.btn-3d:active { transform: translateY(2px); box-shadow: 0 1px 2px rgba(0,0,0,0.1), inset 0 1px 0 rgba(255,255,255,0.1) !important; }
.chip-3d { box-shadow: 0 2px 4px rgba(0,0,0,0.2), inset 0 1px 0 rgba(255,255,255,0.1); border-radius: 4px !important; }

.group-hover-opacity-100 { opacity: 0; }
.group:hover .group-hover-opacity-100 { opacity: 1 !important; }
.hover-bg-glass:hover { background: rgba(255,255,255,0.03) !important; }
.hover-bg-row:hover { background: #f1f5f9 !important; }

/* Scrollbars */
.custom-scroll { scrollbar-gutter: stable; }
.custom-scroll::-webkit-scrollbar { width: 4px; height: 4px; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128, 0.3); border-radius: 4px; }

.ui-field :deep(.v-field) { border-radius: 4px !important; }

.absolute { position: absolute; }
.inset-0 { top: 0; left: 0; right: 0; bottom: 0; }
.z-50 { z-index: 50; }
.z-100 { z-index: 100; }
</style>
