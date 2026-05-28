<template>
  <div
    class="suppliers-layout font-sans fill-height d-flex flex-column relative overflow-hidden"
    :class="isDark ? 'bg-glass-dark text-white' : 'bg-grey-lighten-5 text-grey-darken-4'"
  >
    <div v-if="isDark" class="background-carousel-wrapper">
      <div class="background-overlay"></div>
    </div>

    <div class="content-wrapper d-flex flex-column fill-height z-10 relative">

      <div
        v-if="!isMobileFullscreen"
        class="header-bar px-4 py-3 px-md-6 py-md-4 d-flex flex-column flex-md-row align-md-start justify-space-between flex-shrink-0"
        :class="isDark ? 'bg-glass-header border-bottom-white-05' : 'bg-white border-b border-grey-lighten-2 shadow-sm'"
        style="gap: 12px;"
      >
        <div class="d-flex flex-column" style="max-width: calc(100vw - 32px);">
          <div class="breadcrumb text-caption d-none d-md-block">
            <span class="opacity-70">Cadastros Base</span>
            <span class="mx-2 opacity-50">></span>
            <span class="font-weight-bold">Fornecedores</span>
          </div>
          <div class="d-flex align-center gap-2 mt-1">
             <div class="text-h6 font-weight-black tracking-tight leading-none" :class="isDark ? 'text-white' : 'text-grey-darken-4'">
                Gestão de Fornecedores e Parceiros
             </div>
          </div>
        </div>

        <div class="d-none d-md-flex align-center overflow-x-auto pb-1 pb-md-0 mt-3 mt-md-0" style="gap: 10px;">
          <v-btn
            variant="elevated"
            elevation="2"
            class="btn-3d px-3 px-md-4 font-weight-bold text-caption text-uppercase letter-spacing-1 flex-shrink-0"
            prepend-icon="mdi-dots-grid"
            height="40"
            :color="isDark ? 'grey-darken-3' : 'white'"
            :class="isDark ? 'text-white' : 'text-grey-darken-3'"
            @click="actionsModal.show = true"
          >
            Ações Globais
          </v-btn>

          <v-btn
            color="success"
            variant="flat"
            class="btn-3d px-3 px-md-4 font-weight-bold text-caption text-uppercase letter-spacing-1 flex-shrink-0 shadow-button"
            prepend-icon="mdi-domain-plus"
            height="40"
            @click="openNewSupplierModal"
          >
             Novo Fornecedor
          </v-btn>
        </div>
      </div>

      <div v-if="!isMobileFullscreen" class="px-4 px-md-6 py-2 flex-shrink-0">
        <v-row class="d-none d-md-flex">
          <v-col cols="12" sm="6" md="4" v-for="(kpi, idx) in kpiList" :key="idx">
            <v-card
              class="kpi-card kpi-3d hover-elevate py-3 px-4 cursor-pointer"
              :class="[kpi.gradient, kpi.active ? 'kpi-active-border' : '']"
              v-ripple
              elevation="6"
              @click="handleKpiClick(kpi.label)"
            >
              <div class="kpi-bg-icon"><v-icon>{{ kpi.icon }}</v-icon></div>
              <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height text-white">
                <div class="d-flex align-center" style="gap: 8px;">
                  <v-icon size="18" class="opacity-80">{{ kpi.icon }}</v-icon>
                  <span class="kpi-label">{{ kpi.label }}</span>
                </div>
                <div class="kpi-number-group my-1">
                  <span class="kpi-value drop-shadow-text">{{ kpi.value }}</span>
                </div>
                <div class="kpi-footer mt-1 opacity-80">{{ kpi.footer }}</div>
              </div>
            </v-card>
          </v-col>
        </v-row>

        <div class="d-block d-md-none kpi-mobile-wrapper my-2">
          <v-window v-model="kpiModel" show-arrows class="elevation-4 rounded-xl overflow-hidden shadow-lg">
             <template v-slot:prev="{ props }">
               <v-btn variant="flat" icon="mdi-chevron-left" @click="props.onClick" color="rgba(0,0,0,0.3)" size="small" class="text-white backdrop-blur-sm"></v-btn>
             </template>
             <template v-slot:next="{ props }">
               <v-btn variant="flat" icon="mdi-chevron-right" @click="props.onClick" color="rgba(0,0,0,0.3)" size="small" class="text-white backdrop-blur-sm"></v-btn>
             </template>

             <v-window-item v-for="(kpi, idx) in kpiList" :key="idx">
                <v-card
                    class="kpi-card-mobile d-flex flex-column align-center justify-center py-6 px-4 text-center relative"
                    :class="[kpi.gradient]"
                    @click="handleKpiClick(kpi.label)"
                    height="140"
                    elevation="0"
                    v-ripple
                >
                    <div class="kpi-bg-icon-mobile"><v-icon>{{ kpi.icon }}</v-icon></div>
                    <div class="d-flex flex-column align-center relative z-10 w-100 text-white">
                        <div class="d-flex align-center justify-center mb-1 bg-white-20 px-3 py-1 rounded-pill backdrop-blur-sm" style="max-width: 80%;">
                            <v-icon size="16" class="mr-2 text-white">{{ kpi.icon }}</v-icon>
                            <span class="text-caption font-weight-black text-uppercase text-white tracking-wide text-truncate">{{ kpi.label }}</span>
                        </div>
                        <div class="text-h3 font-weight-black text-white my-2 text-shadow-sm">
                           {{ kpi.value }}
                        </div>
                        <div class="text-caption text-white font-weight-medium opacity-90">{{ kpi.footer }}</div>
                    </div>
                </v-card>
             </v-window-item>
          </v-window>
          <div class="d-flex justify-center mt-3 gap-2">
              <div
                v-for="(k, i) in kpiList"
                :key="i"
                class="kpi-dot transition-all rounded-circle cursor-pointer"
                :class="kpiModel === i ? 'bg-success w-3 h-3 elevation-2' : 'bg-grey-lighten-2 w-2 h-2 opacity-50'"
                @click="kpiModel = i"
              ></div>
          </div>
        </div>
      </div>

      <div v-if="!isMobileFullscreen" class="px-4 px-md-6 pt-0 pb-2 flex-shrink-0">
        <div v-if="mobile" class="d-flex align-center gap-2">
            <v-btn color="success" variant="flat" class="btn-3d flex-shrink-0 px-4" height="44" prepend-icon="mdi-menu" @click="actionsModal.show = true">Ações</v-btn>
            <div class="flex-grow-1 relative search-wrap rounded border d-flex align-center" :class="isDark ? 'bg-glass-dark border-white-10' : 'bg-white'" style="height: 44px;">
                <input v-model="search" type="text" placeholder="Pesquisar..." class="clean-input w-100 h-100 px-3 font-weight-bold" style="outline: none;" :class="isDark ? 'text-white' : 'text-grey-darken-4'">
                <v-icon size="small" class="mr-3 text-grey-darken-1">mdi-magnify</v-icon>
            </div>
        </div>

        <div v-else class="controls-bar d-flex flex-column rounded-lg elevation-2" :class="isDark ? 'controls-dark' : 'bg-white border-thin'" style="gap: 10px;">
          <div class="d-flex flex-column flex-md-row align-start align-md-center justify-space-between" style="gap: 10px;">
            <div class="d-flex align-center flex-wrap w-100 w-md-auto" style="gap: 10px;">
               <div class="search-wrap d-flex align-center flex-grow-1 flex-md-grow-0 rounded-lg" :class="isDark ? 'search-dark' : 'search-light'" style="width: 350px;">
                <v-icon :color="isDark ? 'white-70' : 'grey-darken-1'">mdi-magnify</v-icon>
                <input v-model="search" type="text" placeholder="Buscar Fantasia, Razão Social ou CNPJ..." class="clean-input flex-grow-1 ml-2" :class="isDark ? 'text-white' : ''" />
              </div>
            </div>

            <div class="d-flex align-center flex-wrap justify-end w-100 w-md-auto" style="gap: 10px;">
              <v-btn variant="outlined" class="btn-3d" height="40" :color="statusFilter === 'Ativo' ? 'success' : (isDark ? 'white' : 'grey-darken-2')" :class="statusFilter === 'Ativo' ? 'bg-green-lighten-5 border-success' : ''" @click="statusFilter = statusFilter === 'Ativo' ? 'Todos' : 'Ativo'">
                <v-icon start size="small">mdi-shield-check</v-icon> <span class="d-none d-sm-inline">Ativos</span>
              </v-btn>

              <v-btn variant="tonal" class="btn-3d" height="40" prepend-icon="mdi-refresh" color="success" @click="fetchSuppliers" :loading="loading">
                Atualizar
              </v-btn>
            </div>
          </div>
        </div>
      </div>

      <v-expand-transition>
        <div v-if="selectedSuppliers.length > 0" class="px-4 px-md-6 pb-2 flex-shrink-0">
          <div class="d-flex align-center justify-space-between pa-2 px-4 rounded-lg elevation-2" :class="isDark ? 'bg-amber-darken-4 border border-amber-darken-3' : 'bg-amber-lighten-5 border border-amber-lighten-4'">
             <div class="d-flex align-center gap-2">
                 <v-icon color="amber-darken-3">mdi-checkbox-multiple-marked</v-icon>
                 <span class="font-weight-bold text-body-2" :class="isDark ? 'text-white' : 'text-amber-darken-4'">{{ selectedSuppliers.length }} fornecedor(es) selecionado(s)</span>
             </div>
             <v-btn variant="text" size="small" :color="isDark ? 'white' : 'grey-darken-2'" class="rounded-0 font-weight-bold" @click="selectedSuppliers = []">Limpar Seleção</v-btn>
          </div>
        </div>
      </v-expand-transition>

      <div
        class="flex-grow-1 overflow-hidden d-flex flex-column transition-all"
        :class="[isMobileFullscreen ? 'absolute top-0 left-0 w-100 h-100 z-20 bg-white' : 'px-4 px-md-6 pb-0', 'grid-container-medium']"
      >
        <v-card class="flex-grow-1 d-flex flex-column rounded-xl border-thin overflow-hidden elevation-3" :class="isDark ? 'glass-card border-white-05' : 'bg-white shadow-sm'" :elevation="0">

          <div v-if="isMobileFullscreen" class="bg-success text-white px-3 py-3 d-flex align-center justify-space-between flex-shrink-0 gap-3 elevation-2 z-30">
             <v-btn icon="mdi-arrow-left" variant="text" color="white" @click="isMobileFullscreen = false" class="flex-shrink-0"></v-btn>
             <div class="flex-grow-1 relative d-flex align-center">
                 <input v-model="search" type="text" placeholder="Pesquisar..." class="w-100 bg-white-20 text-white rounded px-3 pr-8 text-body-2 font-weight-bold outline-none placeholder-white-70" style="border: 1px solid rgba(255,255,255,0.3); height: 40px;">
                 <v-icon v-if="search" size="small" class="text-white cursor-pointer absolute right-2" @click="search = ''">mdi-close</v-icon>
             </div>
          </div>

          <div v-if="!mobile" class="grid-scroll flex-grow-1 overflow-auto custom-scroll relative">
            <div class="grid-header sticky-head" :class="[isDark ? 'grid-surface-dark border-bottom-white-05' : 'grid-surface-light border-b border-grey-lighten-2']" style="grid-template-columns: 50px 2fr 1.5fr 1.5fr 110px 110px;">
              <div class="cell cell-check center"><v-checkbox-btn v-model="selectAll" density="compact" color="success" class="chk-fixed"></v-checkbox-btn></div>
              <div class="cell header-text">Fornecedor / Razão Social</div>
              <div class="cell header-text">Documento Fiscal & CNAE</div>
              <div class="cell header-text">Contato de Relacionamento</div>
              <div class="cell center header-text">Status Base</div>
              <div class="cell center header-text">Ações</div>
            </div>

            <div v-if="loading" class="d-flex flex-column justify-center align-center h-100 py-10 min-w-full">
              <v-progress-circular indeterminate color="success" size="32" width="3"></v-progress-circular>
            </div>
            <div v-else-if="filteredSuppliers.length === 0" class="d-flex flex-column justify-center align-center h-100 opacity-60 gap-2 py-10 min-w-full">
              <v-icon size="48" :color="isDark ? 'white-20' : 'grey-lighten-1'">mdi-domain-off</v-icon>
              <span class="text-body-2 font-weight-medium text-grey">Nenhum resultado.</span>
            </div>

            <div v-else v-for="(sup, index) in paginatedSuppliers" :key="sup.id" class="grid-row" :class="[isDark ? 'grid-row-dark' : 'grid-row-light', zebraClass(index), selectedSuppliers.includes(sup.id) ? (isDark ? 'grid-selected-dark' : 'grid-selected-light') : '']" style="grid-template-columns: 50px 2fr 1.5fr 1.5fr 110px 110px;" @click="openEditModal(sup)">
               <div class="cell center" @click.stop><v-checkbox-btn v-model="selectedSuppliers" :value="sup.id" density="compact" color="success" class="chk-fixed"></v-checkbox-btn></div>

               <div class="cell">
                  <div class="d-flex align-center w-100" style="min-width: 0;">
                        <v-avatar :color="getColor(sup.nome)" size="36" class="rounded-lg mr-3 flex-shrink-0 font-weight-bold text-caption text-white elevation-2">
                          {{ sup.nome?.charAt(0)?.toUpperCase() }}
                        </v-avatar>
                        <div class="d-flex flex-column overflow-hidden" style="min-width: 0;">
                          <span class="text-truncate list-text-11 font-weight-black text-uppercase" :class="sup.situacao === 'Inativo' ? 'text-grey text-decoration-line-through' : (isDark ? 'text-white' : 'text-grey-darken-4')" :title="sup.nome">{{ sup.nome }}</span>
                          <span class="list-text-10 opacity-70 text-truncate mt-1" :class="isDark ? 'text-white' : 'text-grey-darken-3'">{{ sup.razao_social }}</span>
                        </div>
                   </div>
               </div>

               <div class="cell">
                   <div class="d-flex flex-column">
                       <span class="list-text-11 font-mono font-weight-bold opacity-90" :class="isDark ? 'text-white' : 'text-grey-darken-4'">{{ formatDoc(sup.cnpj_cpf) }}</span>
                       <span class="list-text-10 opacity-60 mt-1 font-mono" :class="isDark ? 'text-white' : 'text-grey-darken-3'" v-if="sup.cnae">CNAE: {{ sup.cnae }}</span>
                   </div>
               </div>

               <div class="cell">
                   <div class="d-flex flex-column">
                       <div v-if="sup.email" class="d-flex align-center gap-1 mb-1"><v-icon size="10" class="opacity-70">mdi-email</v-icon><span class="list-text-10 font-weight-medium text-truncate" :class="isDark ? 'text-white' : 'text-grey-darken-3'">{{ sup.email }}</span></div>
                       <div v-if="sup.telefone || sup.celular" class="d-flex align-center gap-1"><v-icon size="10" class="opacity-70">mdi-phone</v-icon><span class="list-text-10 font-weight-medium font-mono" :class="isDark ? 'text-white' : 'text-grey-darken-3'">{{ formatPhone(sup.celular || sup.telefone) }}</span></div>
                   </div>
               </div>

               <div class="cell center">
                   <span class="solid-chip chip-status chip-3d text-[10px]" :class="sup.situacao === 'Inativo' ? 'chip-danger' : 'chip-success'">{{ sup.situacao || 'ATIVO' }}</span>
               </div>

               <div class="cell center">
                   <div class="actions-inline">
                       <v-btn icon size="small" class="action-btn action-edit btn-3d" @click.stop="openEditModal(sup)" variant="flat"><v-icon size="16">mdi-pencil</v-icon></v-btn>
                       <v-btn icon size="small" class="action-btn action-del btn-3d" @click.stop="openDeleteModal(sup)" variant="flat"><v-icon size="16">mdi-trash-can-outline</v-icon></v-btn>
                   </div>
               </div>
            </div>
          </div>

          <div class="flex-shrink-0 border-t px-4 py-2 d-flex flex-column flex-md-row align-center justify-space-between z-20" :class="isDark ? 'bg-surface-variant border-top-white-05' : 'bg-white'">
            <div class="d-flex align-center justify-space-between w-100 w-md-auto mb-2 mb-md-0">
               <div class="text-caption opacity-80" :class="isDark ? 'text-white' : 'text-grey-darken-4'"><strong>{{ filteredSuppliers.length }}</strong> registros no filtro</div>
               <v-btn v-if="mobile && !isMobileFullscreen" size="small" variant="text" color="primary" prepend-icon="mdi-fullscreen" @click="isMobileFullscreen = true">Expandir Lista</v-btn>
            </div>
            <v-pagination v-model="page" :length="totalPages" :total-visible="mobile ? 3 : 5" density="compact" active-color="success" variant="elevated" elevation="2" size="small"></v-pagination>
          </div>
        </v-card>
      </div>
    </div>

    <v-dialog v-model="actionsModal.show" width="450" persistent scrim="black opacity-80">
      <v-card class="rounded-xl overflow-hidden elevation-10" :class="isDark ? 'bg-grey-darken-4' : 'bg-white'">
        <div class="px-6 py-4 border-b d-flex justify-space-between align-center" :class="isDark ? 'bg-grey-darken-3 border-white-10' : 'bg-grey-lighten-4 border-grey-lighten-2'">
          <div><div class="text-overline font-weight-black opacity-70 leading-none" :class="isDark ? 'text-white' : ''">Exportações</div><div class="text-h6 font-weight-black mt-1" :class="isDark ? 'text-white' : ''">Ferramentas de Base</div></div>
          <v-btn icon variant="text" @click="actionsModal.show = false" :color="isDark ? 'white' : 'grey-darken-2'"><v-icon>mdi-close</v-icon></v-btn>
        </div>
        <div class="pa-6">
          <v-row dense>
             <v-col cols="12" sm="6">
                 <v-card class="d-flex flex-column align-center justify-center pa-4 cursor-pointer border-thin h-100 rounded-lg hover-elevate kpi-3d" :class="isDark ? 'bg-grey-darken-3' : 'bg-grey-lighten-5'" @click="exportExcel" v-ripple>
                     <v-icon color="success" size="32" class="mb-2">mdi-microsoft-excel</v-icon>
                     <div class="font-weight-bold text-[11px] text-center text-uppercase" :class="isDark ? 'text-white' : 'text-grey-darken-3'">Exportar CSV</div>
                 </v-card>
             </v-col>
             <v-col cols="12" sm="6">
                 <v-card class="d-flex flex-column align-center justify-center pa-4 cursor-pointer border-thin h-100 rounded-lg hover-elevate kpi-3d" :class="isDark ? 'bg-grey-darken-3' : 'bg-grey-lighten-5'" @click="exportPDF" v-ripple>
                     <v-icon color="red-darken-1" size="32" class="mb-2">mdi-file-pdf-box</v-icon>
                     <div class="font-weight-bold text-[11px] text-center text-uppercase" :class="isDark ? 'text-white' : 'text-grey-darken-3'">Relatório PDF</div>
                 </v-card>
             </v-col>
             <v-col cols="12">
                 <v-card class="d-flex flex-column align-center justify-center pa-4 cursor-pointer border-thin h-100 rounded-lg mt-2 hover-elevate kpi-3d" :class="isDark ? 'bg-grey-darken-3' : 'bg-grey-lighten-5'" @click="triggerFileInput" v-ripple>
                     <v-icon color="blue-darken-1" size="32" class="mb-2">mdi-database-import</v-icon>
                     <div class="font-weight-bold text-[11px] text-center text-uppercase" :class="isDark ? 'text-white' : 'text-grey-darken-3'">Importar Planilha XLSX</div>
                 </v-card>
                 <input type="file" ref="fileInputRef" accept=".xlsx, .xls" class="d-none" @change="handleFileUpload" />
             </v-col>
          </v-row>
        </div>
      </v-card>
    </v-dialog>

    <v-dialog v-model="deleteModal.show" width="450" persistent scrim="black opacity-80">
        <v-card class="rounded-xl text-center pa-6 d-flex flex-column align-center elevation-10" :class="isDark ? 'bg-grey-darken-4' : 'bg-white'">
            <v-avatar color="red-lighten-5" size="80" class="mb-4 text-red-darken-2 rounded-0 elevation-2"><v-icon size="40">mdi-alert-octagon-outline</v-icon></v-avatar>
            <div class="text-h6 font-weight-black text-uppercase mb-2 text-red-darken-1">Apagar Registro</div>
            <div class="text-body-2 mb-6" :class="isDark ? 'text-grey-lighten-1' : 'text-grey-darken-2'">Excluir permanentemente <strong>{{ deleteModal.sup?.nome }}</strong> da base?</div>
            <div class="d-flex w-100" style="gap: 12px;">
                <v-btn class="flex-grow-1 btn-rect font-weight-bold" variant="outlined" height="42" @click="deleteModal.show = false" :color="isDark ? 'white' : 'grey-darken-3'">Cancelar</v-btn>
                <v-btn class="flex-grow-1 btn-rect font-weight-black btn-3d" color="red-darken-3" variant="elevated" elevation="4" height="42" :loading="deleteModal.loading" @click="confirmDelete">Apagar</v-btn>
            </div>
        </v-card>
    </v-dialog>

    <SupplierDetailsModal v-model:show="detailsModal.show" :supplier="detailsModal.supplier" @close="detailsModal.show = false" @refresh="fetchSuppliers" />

  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, reactive, defineAsyncComponent } from 'vue';
import { supabase } from '@/api/supabase';
import { useThemeStore } from '@/stores/theme';
import { useAppStore } from '@/stores/app';
import { useDisplay } from 'vuetify';
import * as XLSX from 'xlsx';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import { format } from 'date-fns';

const SupplierDetailsModal = defineAsyncComponent(() => import('@/components/registrations/SupplierDetailsModal.vue'));

const themeStore = useThemeStore();
const appStore = useAppStore();
const { mobile } = useDisplay();

// Reatividade Global Master do Pinia
const isDark = computed(() => themeStore.currentMode !== 'light');

const loading = ref(false);
const suppliers = ref<any[]>([]);
const search = ref('');
const statusFilter = ref('Todos');
const selectedSuppliers = ref<string[]>([]);
const page = ref(1);
const itemsPerPage = 30;
const isMobileFullscreen = ref(false);
const kpiModel = ref(0);

const fileInputRef = ref<HTMLInputElement | null>(null);
const actionsModal = reactive({ show: false });
const deleteModal = reactive({ show: false, loading: false, sup: null as any });
const detailsModal = reactive({ show: false, supplier: null as any });

const getColor = (name: string) => {
    const colors = ['deep-orange', 'amber', 'blue-grey', 'brown', 'teal', 'indigo'];
    let hash = 0;
    if(!name) return 'grey';
    for(let i=0; i<name.length; i++) hash = name.charCodeAt(i) + ((hash << 5) - hash);
    return colors[Math.abs(hash) % colors.length];
};

const formatDoc = (doc: string) => {
    if (!doc) return 'Não Informado';
    doc = doc.replace(/\D/g, '');
    if (doc.length === 14) return doc.replace(/^(\d{2})(\d{3})(\d{3})(\d{4})(\d{2})/, "$1.$2.$3/$4-$5");
    if (doc.length === 11) return doc.replace(/^(\d{3})(\d{3})(\d{3})(\d{2})/, "$1.$2.$3-$4");
    return doc;
};

const formatPhone = (phone: string) => {
    if (!phone) return '';
    phone = phone.replace(/\D/g, '');
    if (phone.length === 11) return phone.replace(/^(\d{2})(\d{5})(\d{4})/, "($1) $2-$3");
    if (phone.length === 10) return phone.replace(/^(\d{2})(\d{4})(\d{4})/, "($1) $2-$3");
    return phone;
};

const fetchSuppliers = async () => {
    loading.value = true;
    try {
        const { data, error } = await supabase.from('suppliers_mj').select('*').order('nome', { ascending: true });
        if (error) throw error;
        suppliers.value = data || [];
    } catch (e) {
        appStore.showSnackbar("Erro ao consultar a base", "error");
    } finally {
        loading.value = false;
    }
};

const filteredSuppliers = computed(() => {
    let list = [...suppliers.value];
    if (statusFilter.value !== 'Todos') list = list.filter(s => s.situacao === statusFilter.value);
    if (search.value) {
        const s = search.value.toLowerCase();
        list = list.filter(sup => sup.nome?.toLowerCase().includes(s) || sup.razao_social?.toLowerCase().includes(s) || sup.cnpj_cpf?.includes(s));
    }
    return list;
});

const paginatedSuppliers = computed(() => {
    const start = (page.value - 1) * itemsPerPage;
    return filteredSuppliers.value.slice(start, start + itemsPerPage);
});

const totalPages = computed(() => Math.ceil(filteredSuppliers.value.length / itemsPerPage) || 1);
const selectAll = computed({
    get: () => paginatedSuppliers.value.length > 0 && selectedSuppliers.value.length === paginatedSuppliers.value.length,
    set: (val) => { if (val) selectedSuppliers.value = paginatedSuppliers.value.map(c => c.id); else selectedSuppliers.value = []; }
});

const totalSuppliers = computed(() => suppliers.value.length);
const activeSuppliers = computed(() => suppliers.value.filter(s => s.situacao === 'Ativo').length);
const inactiveSuppliers = computed(() => suppliers.value.filter(s => s.situacao !== 'Ativo').length);

const kpiList = computed(() => ([
  { label: 'Total Cadastrado', value: totalSuppliers.value, footer: 'Base de Dados', icon: 'mdi-domain', gradient: 'bg-gradient-blue-grey', active: false },
  { label: 'Ativos', value: activeSuppliers.value, footer: 'Aptos para compra', icon: 'mdi-check-decagram', gradient: 'bg-gradient-success', active: false },
  { label: 'Inativos', value: inactiveSuppliers.value, footer: 'Bloqueados', icon: 'mdi-alert-octagon', gradient: 'bg-gradient-orange', active: false },
]));

const handleKpiClick = (label: string) => {
    if (label === 'Ativos') statusFilter.value = 'Ativo';
    else if (label === 'Inativos') statusFilter.value = 'Inativo';
    else statusFilter.value = 'Todos';
};

const zebraClass = (i:number) => isDark.value ? (i%2===0?'zebra-dark-a':'zebra-dark-b') : (i%2===0?'zebra-light-a':'zebra-light-b');

const openNewSupplierModal = () => { detailsModal.supplier = null; detailsModal.show = true; };
const openEditModal = (sup: any) => { detailsModal.supplier = sup; detailsModal.show = true; };
const openDeleteModal = (sup: any) => { deleteModal.sup = sup; deleteModal.show = true; };

const confirmDelete = async () => {
    deleteModal.loading = true;
    try {
        await supabase.from('suppliers_mj').delete().eq('id', deleteModal.sup.id);
        appStore.showSnackbar("Apagado com sucesso.", "success");
        fetchSuppliers();
    } catch(e) { appStore.showSnackbar("Erro ao apagar", "error"); } finally { deleteModal.loading = false; deleteModal.show = false; }
};

const exportExcel = () => {
    const csvRows = [];
    const headers = ['Fantasia', 'Razao Social', 'CNPJ/CPF', 'Email', 'Telefone', 'Status'];
    csvRows.push(headers.join(';'));
    filteredSuppliers.value.forEach(s => {
        const row = [s.nome || '', s.razao_social || '', s.cnpj_cpf || '', s.email || '', s.celular || s.telefone || '', s.situacao || 'Ativo'];
        csvRows.push(row.map(r => `"${String(r).replace(/"/g, '""')}"`).join(';'));
    });
    const blob = new Blob([new Uint8Array([0xEF, 0xBB, 0xBF]), csvRows.join('\n')], { type: 'text/csv;charset=utf-8;' });
    const link = document.createElement("a"); link.href = URL.createObjectURL(blob); link.download = `Fornecedores_${format(new Date(), 'ddMMyyyy')}.csv`; link.click();
    actionsModal.show = false;
};

const exportPDF = () => {
    const doc = new jsPDF(); doc.text(`Relatório de Fornecedores`, 14, 15);
    autoTable(doc, { startY: 25, head: [['Razão Social / Fantasia', 'CNPJ', 'Status']], body: filteredSuppliers.value.map(c => [c.razao_social || c.nome, c.cnpj_cpf || '-', c.situacao || 'Ativo']) });
    doc.save(`Fornecedores_${format(new Date(), 'ddMMyyyy')}.pdf`); actionsModal.show = false;
};

const triggerFileInput = () => { fileInputRef.value?.click(); };
const handleFileUpload = async (event: any) => {
    const file = event.target.files?.[0]; if (!file) return;
    appStore.showSnackbar('Lendo...', 'info');
    const reader = new FileReader();
    reader.onload = async (e) => {
        try {
            const data = new Uint8Array(e.target?.result as ArrayBuffer);
            const workbook = XLSX.read(data, { type: 'array' });
            const jsonData = XLSX.utils.sheet_to_json(workbook.Sheets[workbook.SheetNames[0]]);
            let count = 0;
            for (const row of jsonData as any[]) {
                const nome = row['Nome'] || row['Fantasia'];
                if (nome) {
                    await supabase.from('suppliers_mj').insert({ nome, razao_social: row['Razão Social'] || nome, cnpj_cpf: row['CNPJ'], situacao: 'Ativo' });
                    count++;
                }
            }
            appStore.showSnackbar(`${count} importados!`, 'success'); fetchSuppliers(); actionsModal.show = false;
        } catch (error) { appStore.showSnackbar('Falha', 'error'); } finally { if (fileInputRef.value) fileInputRef.value.value = ''; }
    };
    reader.readAsArrayBuffer(file);
};

onMounted(fetchSuppliers);
</script>

<style scoped lang="scss">
/* Idêntico ao AdminMjReceivables.vue */
.suppliers-layout { position: relative; }
.bg-glass-dark { background: rgba(10,10,12,0.85); }
.bg-glass-header { background: rgba(20,20,24,0.55); backdrop-filter: blur(14px); }
.border-bottom-white-05 { border-bottom: 1px solid rgba(255,255,255,0.08); }
.border-top-white-05 { border-top: 1px solid rgba(255,255,255,0.08); }
.border-white-10 { border: 1px solid rgba(255,255,255,0.1) !important; }
.controls-bar { border: 1px solid rgba(0,0,0,0.08); padding: 10px; transition: background 0.3s; }
.controls-dark { background: rgba(35,35,40,0.8); border: 1px solid rgba(255,255,255,0.05); }
.search-wrap { height: 40px; padding: 0 12px; display: flex; align-items: center; min-width: 300px; flex: 1; }

@media (max-width: 600px) { .search-wrap { min-width: 100%; } }
.search-light { background: #f4f6f8; border: 1px solid rgba(0,0,0,0.08); }
.search-dark { background: rgba(0,0,0,0.2); border: 1px solid rgba(255,255,255,0.10); }
.clean-input { border: none; outline: none; flex: 1; font-size: 13px; }

.grid-scroll { scrollbar-gutter: stable; -webkit-overflow-scrolling: touch; }
.custom-scroll::-webkit-scrollbar { width: 8px; height: 8px; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.35); border-radius: 6px; }
.custom-scroll::-webkit-scrollbar-track { background: transparent; }

.grid-header, .grid-row { display: grid; align-items: stretch; width: 100%; }
.cell { padding: 6px 8px; display: flex; align-items: center; border-right: 1px solid rgba(0,0,0,0.08); border-bottom: 1px solid rgba(0,0,0,0.08); min-height: 54px; overflow: hidden; transition: background-color 0.2s ease; }
.header-text { font-weight: 800; text-transform: uppercase; letter-spacing: 0.5px; line-height: 1.2; }
.center { justify-content: center; text-align: center; }
.grid-header .cell { min-height: 44px; font-weight: 800; text-transform: uppercase; letter-spacing: 0.5px; line-height: 1.2; }
.list-text-11 { line-height: 1.2 !important; }

.grid-container-medium .header-text { font-size: 12px !important; }
.grid-container-medium .list-text-11 { font-size: 13px !important; }

:deep(.v-checkbox-btn) { width: 24px !important; height: 24px !important; }
:deep(.v-checkbox-btn .v-selection-control__input) { width: 24px !important; height: 24px !important; }
:deep(.v-checkbox-btn .v-icon) { font-size: 18px !important; }
.chk-fixed { margin: 0 !important; padding: 0 !important; }

.background-carousel-wrapper { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 0; opacity: 0.6; pointer-events: none; }
.background-overlay { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 1; background: radial-gradient(circle at center, rgba(15, 15, 19, 0.4), rgba(15, 15, 19, 0.98)); backdrop-filter: blur(8px); }

.grid-surface-light .cell { background: #f5f7fa; color: rgba(0,0,0,0.9); border-color: rgba(0,0,0,0.12) !important; }
.grid-row-light .cell { border-color: rgba(0,0,0,0.08) !important; }
.zebra-light-a .cell { background: #ffffff; }
.zebra-light-b .cell { background: #f0f4f8; }
.grid-row-light:hover .cell { background: #e3f2fd !important; }
.grid-selected-light .cell { background: #e8f5e9 !important; }

.grid-surface-dark .cell { background: rgba(255,255,255,0.08) !important; color: rgba(255,255,255,0.80) !important; border-color: rgba(255,255,255,0.10) !important; backdrop-filter: none !important; }
.grid-row-dark .cell { background: rgba(255,255,255,0.04); border-color: rgba(255,255,255,0.08) !important; color: rgba(255,255,255,0.85); }
.zebra-dark-a .cell { background: rgba(255,255,255,0.04) !important; }
.zebra-dark-b .cell { background: rgba(255,255,255,0.015) !important; }
.grid-row-dark:hover .cell { background: rgba(255,255,255,0.07) !important; box-shadow: inset 2px 0 0 #4CAF50; }
.grid-selected-dark .cell { background: rgba(76, 175, 80, 0.2) !important; }

.v-theme--dark { .text-grey-darken-4, .text-grey-darken-3, .text-grey-darken-2, .text-grey-darken-1, .text-grey { color: rgba(255,255,255,0.9) !important; } }

.kpi-card { color: white; position: relative; min-height: 110px; overflow: hidden; border-radius: 8px; }
.kpi-3d { box-shadow: 0 8px 16px rgba(0,0,0,0.15), inset 0 2px 4px rgba(255,255,255,0.15) !important; border: 1px solid rgba(255,255,255,0.1); transition: transform 0.2s ease; }
.kpi-3d:hover { transform: translateY(-3px); }
.kpi-bg-icon { position: absolute; right: -20px; bottom: -20px; opacity: 0.15; transform: rotate(-15deg); }
.kpi-bg-icon .v-icon { font-size: 100px; color: white; }
.kpi-bg-icon-mobile { position: absolute; right: -5px; bottom: -5px; opacity: 0.15; transform: rotate(-10deg); }
.kpi-bg-icon-mobile .v-icon { font-size: 60px; color: white; }
.drop-shadow-text { text-shadow: 0 2px 4px rgba(0,0,0,0.3); }

.bg-gradient-blue-grey { background: linear-gradient(135deg, #455a64, #263238); }
.bg-gradient-success { background: linear-gradient(135deg, #2e7d32, #1b5e20); }
.bg-gradient-orange { background: linear-gradient(135deg, #ef6c00, #bf360c); }
.kpi-label { font-size: 12px; font-weight: 900; letter-spacing: .2px; text-transform: uppercase; }
.kpi-value { font-size: 26px; font-weight: 900; font-family: monospace; }

.solid-chip { display: inline-flex; align-items: center; justify-content: center; height: 28px; padding: 0 12px; font-weight: 900; color: #fff; text-transform: uppercase; white-space: nowrap; }
.chip-status { min-width: 70px; }
.chip-success { background: #2e7d32; }
.chip-danger { background: #c62828; }

.actions-inline { display: flex; gap: 4px; justify-content: center; flex-wrap: nowrap !important; }
.action-btn { width: 28px !important; height: 28px !important; color: #fff !important; }
.action-edit { background: #1976d2 !important; }
.action-del { background: #c62828 !important; }

.btn-3d { border-radius: 6px !important; box-shadow: 0 4px 6px rgba(0,0,0,0.15), inset 0 1px 1px rgba(255,255,255,0.2) !important; transition: transform 0.1s ease, box-shadow 0.1s ease; text-transform: none !important; }
.btn-3d:active { transform: translateY(2px); box-shadow: 0 2px 3px rgba(0,0,0,0.1) !important; }
.action-btn-3d { border-radius: 6px !important; box-shadow: 0 2px 4px rgba(0,0,0,0.15), inset 0 1px 1px rgba(255,255,255,0.2) !important; transition: all 0.15s ease; }
.action-btn-3d:hover { transform: translateY(-2px); box-shadow: 0 4px 8px rgba(0,0,0,0.2), inset 0 1px 1px rgba(255,255,255,0.2) !important; }
.chip-3d { border-radius: 6px !important; box-shadow: 0 2px 4px rgba(0,0,0,0.12), inset 0 1px 0 rgba(255,255,255,0.25) !important; text-shadow: 0 1px 2px rgba(0,0,0,0.25); }

.flex-grow-1.overflow-hidden > .v-card.flex-grow-1 { border: 1px solid rgba(0,0,0,0.12) !important; }
.bg-glass-dark .flex-grow-1.overflow-hidden > .v-card.flex-grow-1 { border: 1px solid rgba(255,255,255,0.12) !important; }
.sticky-head { position: sticky; top: 0; z-index: 20; box-shadow: 0 8px 16px -4px rgba(0, 0, 0, 0.12); }
.bg-glass-dark .sticky-head { box-shadow: 0 8px 20px -4px rgba(0, 0, 0, 0.4); }
</style>
