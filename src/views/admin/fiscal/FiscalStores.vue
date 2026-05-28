<template>
  <div
    class="receivables-layout font-sans fill-height d-flex flex-column relative overflow-hidden"
    :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 text-grey-darken-4' : 'bg-glass-dark text-white'"
  >
    <div v-if="themeStore.currentMode !== 'light'" class="background-carousel-wrapper">
        <v-carousel cycle height="100%" hide-delimiters :show-arrows="false" interval="15000" class="fill-height">
            <v-carousel-item src="@/assets/1.jpg" cover></v-carousel-item>
            <v-carousel-item src="@/assets/2.jpg" cover></v-carousel-item>
            <v-carousel-item src="@/assets/3.jpg" cover></v-carousel-item>
        </v-carousel>
        <div class="background-overlay"></div>
    </div>

    <div class="content-wrapper d-flex flex-column fill-height z-10 relative">
        <div
          class="header-bar px-4 py-3 px-md-6 py-md-4 d-flex flex-column flex-md-row align-md-center justify-space-between flex-shrink-0"
          :class="themeStore.currentMode === 'light' ? 'bg-white border-b border-grey-lighten-2 shadow-sm' : 'bg-glass-header border-bottom-white-05'"
          style="gap: 12px;"
        >
          <div class="d-flex flex-column">
            <div class="breadcrumb text-caption d-none d-md-block">
              <span class="opacity-70">Fiscal</span>
              <span class="mx-2 opacity-50">></span>
              <span class="font-weight-bold">Pontos de Venda</span>
            </div>
            <div class="d-flex align-center gap-3 mt-1">
               <div class="icon-box-md rounded-lg elevation-2 d-flex align-center justify-center" style="width: 40px; height: 40px;" :class="themeStore.currentMode === 'light' ? 'bg-purple-darken-3 text-white' : 'bg-purple-transparent text-purple'">
                  <v-icon size="24">mdi-store</v-icon>
               </div>
               <div>
                   <h1 class="text-h6 font-weight-black tracking-tight leading-none" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">
                      Lojas e Unidades
                   </h1>
                   <span class="text-caption opacity-70">Gerencie seus pontos de venda e parâmetros de NFC-e</span>
               </div>
            </div>
          </div>
          <div class="d-flex align-center pb-1 pb-md-0" style="gap: 10px;">
             <v-btn color="purple-darken-2" variant="flat" class="btn-rect px-4 font-weight-bold text-caption text-uppercase letter-spacing-1 shadow-sm" prepend-icon="mdi-store-plus" height="40" @click="openDialog()">
                Nova Loja
            </v-btn>
          </div>
        </div>

        <div class="px-4 px-md-6 py-4 flex-shrink-0">
            <div class="controls-bar d-flex flex-column" :class="themeStore.currentMode === 'light' ? 'controls-light' : 'controls-dark'">
                <div class="search-wrap d-flex align-center w-100" :class="themeStore.currentMode === 'light' ? 'search-light bg-white' : 'search-dark'">
                    <v-icon :color="themeStore.currentMode === 'light' ? 'grey-darken-1' : 'white-70'">mdi-magnify</v-icon>
                    <input
                        v-model="search"
                        type="text"
                        placeholder="Pesquisar por nome da loja, CNPJ ou matriz..."
                        class="clean-input flex-grow-1 ml-2 font-weight-bold"
                        :class="themeStore.currentMode === 'light' ? 'text-grey-darken-3' : 'text-white'"
                    />
                </div>
            </div>
        </div>

        <div class="flex-grow-1 overflow-hidden d-flex flex-column px-4 px-md-6 pb-6">
           <v-card class="flex-grow-1 d-flex flex-column rounded-0 border-thin overflow-hidden" :class="themeStore.currentMode === 'light' ? 'bg-white shadow-sm' : 'glass-card border-white-05'" :elevation="0">
             <div class="grid-scroll flex-grow-1 overflow-auto custom-scroll relative">
               <div class="grid-header sticky-head" :class="themeStore.currentMode === 'light' ? 'grid-surface-light' : 'grid-surface-dark'" style="grid-template-columns: 60px minmax(200px, 2fr) 160px 140px minmax(200px, 1.5fr) 140px 100px; min-width: 1050px;">
                 <div class="cell center header-text">Status</div>
                 <div class="cell header-text">Loja / Apelido</div>
                 <div class="cell center header-text">CNPJ</div>
                 <div class="cell center header-text">ID Integração</div>
                 <div class="cell header-text">Matriz Vinculada</div>
                 <div class="cell center header-text">Ambiente</div>
                 <div class="cell center header-text">Ações</div>
               </div>

               <div v-if="loading" class="d-flex flex-column justify-center align-center h-100 py-10 min-w-full">
                 <v-progress-circular indeterminate color="purple" size="32" width="3"></v-progress-circular>
               </div>

               <div v-else-if="filteredStores.length === 0" class="d-flex flex-column justify-center align-center h-100 opacity-60 py-10 min-w-full">
                   <v-icon size="48" color="grey-lighten-1">mdi-store-remove</v-icon>
                   <span class="text-body-2 font-weight-medium mt-2">Nenhuma loja encontrada.</span>
               </div>

               <div v-else v-for="(item, index) in filteredStores" :key="item.id"
                    class="grid-row"
                    :class="[themeStore.currentMode === 'light' ? 'grid-row-light' : 'grid-row-dark', zebraClass(index)]"
                    style="grid-template-columns: 60px minmax(200px, 2fr) 160px 140px minmax(200px, 1.5fr) 140px 100px; min-width: 1050px;"
               >
                   <div class="cell center">
                       <div class="status-dot rounded-circle" :class="item.active ? 'bg-success pulse-success' : 'bg-grey'"></div>
                   </div>

                   <div class="cell font-weight-bold list-text-11 text-truncate" :title="item.name">
                       <v-icon size="16" class="mr-2 opacity-50">mdi-storefront</v-icon>
                       {{ item.name }}
                   </div>

                   <div class="cell center font-mono font-weight-black list-text-11">{{ formatCNPJ(item.cnpj) || 'N/A' }}</div>

                   <div class="cell center font-mono list-text-11 opacity-80">{{ item.external_id || 'Não def.' }}</div>

                   <div class="cell list-text-11 text-truncate" :title="item.company?.name">
                       <template v-if="item.company">
                          <v-icon size="14" color="grey" class="mr-1">mdi-domain</v-icon>
                          {{ item.company.name }}
                       </template>
                       <v-chip v-else size="x-small" color="error" variant="tonal" class="font-weight-bold">Sem Vínculo</v-chip>
                   </div>

                   <div class="cell center">
                       <v-chip size="x-small" :color="item.environment === 'production' ? 'green-darken-1' : 'orange-darken-1'" variant="flat" class="font-weight-bold text-uppercase text-white">
                          {{ item.environment === 'production' ? 'Produção' : 'Homologação' }}
                       </v-chip>
                   </div>

                   <div class="cell center">
                       <div class="actions-inline">
                           <v-btn icon size="small" class="action-btn action-edit" @click.stop="openDialog(item)" title="Editar" variant="flat"><v-icon size="16">mdi-pencil</v-icon></v-btn>
                           <v-btn icon size="small" class="action-btn" :class="item.active ? 'bg-orange-darken-2' : 'bg-green-darken-2'" @click.stop="toggleStatus(item)" :title="item.active ? 'Desativar' : 'Ativar'" variant="flat"><v-icon size="16">mdi-power</v-icon></v-btn>
                       </div>
                   </div>
               </div>
             </div>
           </v-card>
        </div>
    </div>

    <v-dialog v-model="dialog" width="1100" height="85vh" persistent transition="dialog-bottom-transition" class="fixed-dialog">
        <v-card class="d-flex flex-row overflow-hidden rounded-0 fill-height w-100" height="100%">

            <div class="modal-sidebar pa-0 d-flex flex-column flex-shrink-0 text-white bg-blue-grey-darken-4" style="width: 280px; z-index: 10;">
                <div class="pa-6 text-center border-b border-white-10">
                    <v-avatar size="90" class="mb-3 border elevation-4 bg-white-05">
                        <v-icon size="40" color="white">mdi-store-cog</v-icon>
                    </v-avatar>
                    <div class="text-subtitle-2 font-weight-black text-truncate">{{ editedItem.name || 'Nova Loja' }}</div>
                    <div class="text-caption font-mono opacity-80">{{ formatCNPJ(editedItem.cnpj) || 'CNPJ Não Definido' }}</div>
                </div>

                <div class="flex-grow-1 overflow-y-auto py-2 custom-scroll-dark">
                    <v-tabs v-model="activeTab" direction="vertical" color="white" class="sidebar-tabs">
                        <v-tab value="geral" class="justify-start px-6"><v-icon start size="18">mdi-store-outline</v-icon> Dados da Loja</v-tab>
                        <v-tab value="fiscal" class="justify-start px-6"><v-icon start size="18">mdi-receipt-text-outline</v-icon> Fiscal / NFC-e</v-tab>
                    </v-tabs>
                </div>
            </div>

            <div class="flex-grow-1 d-flex flex-column h-100 overflow-hidden" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5' : 'bg-glass-dark'">

                 <div class="pa-5 border-b d-flex align-center justify-space-between flex-shrink-0 bg-white z-10" :class="themeStore.currentMode === 'light' ? 'border-grey-lighten-2' : 'border-white-10 bg-glass-header'">
                     <div>
                         <div class="text-h6 font-weight-black text-grey-darken-3">{{ activeTab === 'geral' ? 'Identificação da Loja' : 'Parâmetros de Emissão (NFC-e)' }}</div>
                         <div class="text-caption text-grey">Preencha corretamente as informações para garantir o funcionamento do PDV.</div>
                     </div>
                     <v-btn icon="mdi-close" variant="text" color="grey-darken-1" @click="close"></v-btn>
                 </div>

                 <div class="flex-grow-1 overflow-y-auto custom-scroll pa-6 pa-md-8 absolute-fill">
                    <v-form ref="formRef" v-model="valid" @submit.prevent="save" id="storeForm">
                        <v-window v-model="activeTab">

                            <v-window-item value="geral">
                                <v-card class="pa-6 rounded-xl border-thin shadow-xs" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'glass-card border-white-05'" elevation="0">
                                    <div class="text-subtitle-2 font-weight-bold text-uppercase opacity-70 mb-4">Informações Principais</div>
                                    <v-row dense class="row-gap">
                                        <v-col cols="12" md="8"><label class="input-label">Nome da Loja (Apelido) *</label><v-text-field v-model="editedItem.name" variant="outlined" density="comfortable" class="ui-field" bg-color="transparent" :rules="[v => !!v || 'Obrigatório']"></v-text-field></v-col>
                                        <v-col cols="12" md="4"><label class="input-label">ID Integração (Externo)</label><v-text-field v-model="editedItem.external_id" variant="outlined" density="comfortable" class="ui-field" bg-color="transparent"></v-text-field></v-col>
                                        <v-col cols="12"><label class="input-label text-purple-darken-3">Empresa Matriz (Fiscal) *</label><v-select v-model="editedItem.company_id" :items="companies" item-title="name" item-value="id" variant="outlined" density="comfortable" class="ui-field font-weight-bold" bg-color="transparent" :rules="[v => !!v || 'Selecione uma matriz']"></v-select></v-col>
                                        <v-col cols="12" md="6"><label class="input-label">CNPJ Próprio da Filial (Opcional)</label><v-text-field v-model="editedItem.cnpj" v-maska="'##.###.###/####-##'" placeholder="Se vazio, usa o da Matriz" variant="outlined" density="comfortable" class="ui-field font-weight-bold" bg-color="transparent"></v-text-field></v-col>
                                    </v-row>
                                </v-card>
                            </v-window-item>

                            <v-window-item value="fiscal">
                                <v-card class="pa-6 rounded-xl border-thin shadow-xs mb-6" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'glass-card border-white-05'" elevation="0">
                                    <div class="d-flex align-center gap-3 mb-6">
                                        <div class="icon-box bg-orange-lighten-5 text-orange-darken-3 rounded"><v-icon>mdi-receipt-text-outline</v-icon></div>
                                        <div class="text-subtitle-2 font-weight-bold text-uppercase text-grey-darken-3">Ambiente e Numeração</div>
                                    </div>
                                    <v-row dense class="row-gap">
                                        <v-col cols="12" md="4">
                                            <label class="input-label">Ambiente Sefaz</label>
                                            <v-select v-model="editedItem.environment" :items="[{title:'Homologação (Teste)', value:'homologation'}, {title:'Produção (Valendo)', value:'production'}]" variant="outlined" density="comfortable" class="ui-field font-weight-bold" :bg-color="editedItem.environment === 'production' ? (themeStore.currentMode === 'light' ? 'red-lighten-5' : 'rgba(211, 47, 47, 0.1)') : 'transparent'"></v-select>
                                        </v-col>
                                        <v-col cols="12" md="4"><label class="input-label">Série do Cupom</label><v-text-field v-model.number="editedItem.series" type="number" variant="outlined" density="comfortable" class="ui-field" bg-color="transparent"></v-text-field></v-col>
                                        <v-col cols="12" md="4"><label class="input-label text-orange-darken-3">Próxima NFC-e</label><v-text-field v-model.number="editedItem.last_nfe_number" type="number" variant="outlined" density="comfortable" class="ui-field font-weight-bold" bg-color="transparent"></v-text-field></v-col>
                                    </v-row>
                                </v-card>

                                <v-card class="pa-6 rounded-xl border-thin shadow-xs" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'glass-card border-white-05'" elevation="0">
                                    <div class="d-flex align-center gap-3 mb-4">
                                        <div class="icon-box bg-blue-grey-lighten-5 text-blue-grey-darken-3 rounded"><v-icon>mdi-shield-key-outline</v-icon></div>
                                        <div class="text-subtitle-2 font-weight-bold text-uppercase text-grey-darken-3">Credenciais de Segurança Sefaz</div>
                                    </div>
                                    <p class="text-body-2 text-grey-darken-1 mb-4">O Código de Segurança do Contribuinte (CSC) é obrigatório para autorizar cupons fiscais. Obtenha este dado no portal da Sefaz.</p>
                                    <v-row dense class="row-gap">
                                        <v-col cols="12" md="8"><label class="input-label text-blue-grey-darken-3">Token CSC (Alfanumérico)</label><v-text-field v-model="editedItem.csc_token" variant="outlined" density="comfortable" type="password" autocomplete="new-password" placeholder="Ex: A1B2C3D4-E5F6..." class="ui-field" bg-color="transparent"></v-text-field></v-col>
                                        <v-col cols="12" md="4"><label class="input-label text-blue-grey-darken-3">ID do Token</label><v-text-field v-model="editedItem.csc_id" variant="outlined" density="comfortable" placeholder="Ex: 000001" class="ui-field" bg-color="transparent"></v-text-field></v-col>
                                    </v-row>
                                </v-card>
                            </v-window-item>

                        </v-window>
                    </v-form>
                 </div>

                 <div class="pa-4 border-t d-flex justify-end align-center flex-shrink-0 z-10 bg-white shadow-inner-top" :class="themeStore.currentMode === 'light' ? 'border-grey-lighten-2' : 'border-white-10 bg-glass-header'" style="gap: 12px; height: 80px;">
                    <v-btn variant="text" class="font-weight-bold text-grey-darken-1" @click="close" :disabled="saving" height="46">Cancelar</v-btn>
                    <v-btn color="purple-darken-2" variant="flat" class="btn-rect px-8 font-weight-black text-body-1 shadow-sm" height="46" type="submit" form="storeForm" :loading="saving">
                        <v-icon start>mdi-content-save-check</v-icon> Salvar Configurações
                    </v-btn>
                 </div>
            </div>
        </v-card>
    </v-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted, computed } from 'vue';
import { supabase } from '@/api/supabase';
import { vMaska } from 'maska/vue';
import { useThemeStore } from '@/stores/themeStore';
import { useAppStore } from '@/stores/app';

const themeStore = useThemeStore();
const appStore = useAppStore();

const stores = ref<any[]>([]);
const companies = ref<any[]>([]);
const loading = ref(false);
const dialog = ref(false);
const saving = ref(false);
const valid = ref(false);
const formRef = ref<any>(null);
const search = ref('');
const activeTab = ref('geral');

// Objeto base da loja
const defaultItem = {
    id: null,
    name: '',
    company_id: null,
    cnpj: '',
    environment: 'homologation',
    csc_token: '',
    csc_id: '',
    last_nfe_number: 0,
    series: 1,
    active: true,
    external_id: ''
};

const editedItem = reactive({ ...defaultItem });

const fetchData = async () => {
  loading.value = true;
  // Carrega Empresas para o dropdown
  const { data: compData } = await supabase.from('companies').select('id, name').eq('active', true);
  companies.value = compData || [];

  // Carrega Lojas
  const { data, error } = await supabase.from('stores').select('*, company:companies(name)').order('name');

  if(!error && data) {
      // Extração inteligente do JSONB 'settings'
      stores.value = data.map(store => {
          const settings = store.settings || {};
          return {
              ...store,
              cnpj: store.cnpj || settings.cnpj || '',
              environment: store.environment || settings.environment || 'homologation',
              csc_token: settings.csc_token || '',
              csc_id: settings.csc_id || '',
              last_nfe_number: settings.last_nfe_number || 0,
              series: settings.series || 1,
              external_id: store.external_id || settings.external_id || ''
          };
      });
  }
  loading.value = false;
};

const filteredStores = computed(() => {
    if (!search.value) return stores.value;
    const term = search.value.toLowerCase();
    const numTerm = term.replace(/\D/g, '');
    return stores.value.filter(s =>
        s.name?.toLowerCase().includes(term) ||
        s.company?.name?.toLowerCase().includes(term) ||
        (numTerm.length > 0 && s.cnpj?.includes(numTerm))
    );
});

const openDialog = (item?: any) => {
    activeTab.value = 'geral';
    Object.assign(editedItem, item || defaultItem);
    dialog.value = true;
};

const close = () => {
    dialog.value = false;
    setTimeout(() => Object.assign(editedItem, defaultItem), 300);
};

const save = async () => {
  if (!formRef.value) return;
  const { valid: isValid } = await formRef.value.validate();
  if (!isValid) return;

  saving.value = true;
  try {
    // Monta o payload da tabela stores
    const payload: any = {
        name: editedItem.name,
        company_id: editedItem.company_id,
        active: editedItem.active
    };

    if (editedItem.id) payload.id = editedItem.id;

    // Configurações Fiscais vão para a coluna JSONB `settings`
    const settings = {
        cnpj: editedItem.cnpj?.replace(/\D/g, ''),
        environment: editedItem.environment,
        csc_token: editedItem.csc_token,
        csc_id: editedItem.csc_id,
        last_nfe_number: Number(editedItem.last_nfe_number),
        series: Number(editedItem.series),
        external_id: editedItem.external_id
    };

    payload.settings = settings;

    const { error } = await supabase.from('stores').upsert(payload);

    if (error) throw error;

    appStore.showSnackbar("Loja configurada com sucesso!", "success");
    await fetchData();
    close();
  } catch (error: any) {
      appStore.showSnackbar('Erro ao salvar: ' + (error.message || 'Verifique os dados'), 'error');
  } finally {
      saving.value = false;
  }
};

const toggleStatus = async (item: any) => {
    const newVal = !item.active;
    await supabase.from('stores').update({ active: newVal }).eq('id', item.id);
    item.active = newVal;
    appStore.showSnackbar(`Loja ${newVal ? 'Ativada' : 'Desativada'} com sucesso.`, "success");
};

const formatCNPJ = (v: string) => v?.replace(/^(\d{2})(\d{3})(\d{3})(\d{4})(\d{2})/, "$1.$2.$3/$4-$5");
const zebraClass = (i:number) => themeStore.currentMode !== 'light' ? (i%2===0?'zebra-dark-a':'zebra-dark-b') : (i%2===0?'zebra-light-a':'zebra-light-b');

onMounted(() => { fetchData(); });
</script>

<style scoped lang="scss">
/* --- LAYOUT GLOBAL PADRÃO --- */
.receivables-layout { position: relative; }
.bg-glass-dark { background: rgba(10,10,12,0.85); }
.bg-glass-header { background: rgba(20,20,24,0.55); backdrop-filter: blur(14px); }
.border-bottom-white-05 { border-bottom: 1px solid rgba(255,255,255,0.08); }
.btn-rect { border-radius: 0 !important; text-transform: none !important; font-weight: 800; }
.shadow-inner-top { box-shadow: inset 0 2px 4px rgba(0,0,0,0.02); }

.controls-bar { border: 1px solid rgba(0,0,0,0.08); padding: 10px; border-radius: 8px; }
.controls-dark { border-color: rgba(255,255,255,0.1); }
.search-wrap { height: 44px; padding: 0 16px; border: 1px solid rgba(0,0,0,0.08); display: flex; align-items: center; border-radius: 6px; }
.search-dark { border-color: rgba(255,255,255,0.1); background: rgba(255,255,255,0.02); }
.clean-input { border: none; outline: none; flex: 1; font-size: 14px; background: transparent; }

.background-carousel-wrapper { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 0; opacity: 0.6; pointer-events: none; }
.background-overlay { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 1; background: radial-gradient(circle at center, rgba(15, 15, 19, 0.4), rgba(15, 15, 19, 0.98)); backdrop-filter: blur(8px); }
.z-10 { position: relative; z-index: 10; }
.bg-purple-transparent { background: rgba(156, 39, 176, 0.15); }

/* --- GRID FLUIDA C/ COLUNAS SEPARADAS --- */
.grid-scroll { scrollbar-gutter: stable; -webkit-overflow-scrolling: touch; }
.custom-scroll::-webkit-scrollbar { width: 8px; height: 8px; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.35); border-radius: 6px; }
.custom-scroll::-webkit-scrollbar-track { background: transparent; }

.grid-header, .grid-row { display: grid; align-items: stretch; width: 100%; }
.cell { padding: 6px 12px; display: flex; align-items: center; border-right: 1px solid rgba(0,0,0,0.08); border-bottom: 1px solid rgba(0,0,0,0.08); min-height: 54px; overflow: hidden; transition: background-color 0.2s ease; }
.header-text { font-size: 11px !important; font-weight: 800; text-transform: uppercase; letter-spacing: 0.5px; opacity: 0.8; background: inherit; }
.center { justify-content: center; text-align: center; }
.list-text-11 { font-size: 13px !important; line-height: 1.2 !important; }

.grid-surface-light .cell { background: #f8fafc; color: rgba(0,0,0,0.8); border-color: rgba(0,0,0,0.08) !important; }
.grid-surface-dark .cell { background: rgba(255,255,255,0.05); color: rgba(255,255,255,0.9); border-color: rgba(255,255,255,0.08) !important; }
.grid-row-light .cell { border-color: rgba(0,0,0,0.05) !important; }
.grid-row-dark .cell { border-color: rgba(255,255,255,0.05) !important; }
.zebra-light-a .cell { background: #ffffff; }
.zebra-light-b .cell { background: #fcfcfc; }
.zebra-dark-a .cell { background: rgba(0,0,0,0.15); }
.zebra-dark-b .cell { background: rgba(255,255,255,0.02); }
.grid-row-light:hover .cell { background: #f1f5f9 !important; }
.grid-row-dark:hover .cell { background: rgba(255,255,255,0.08) !important; }

.sticky-head { position: sticky; top: 0; z-index: 20; box-shadow: 0 8px 16px -4px rgba(0, 0, 0, 0.08); }
.bg-glass-dark .sticky-head { box-shadow: 0 8px 20px -4px rgba(0, 0, 0, 0.3); }

/* Status Dot e Actions */
.status-dot { width: 10px; height: 10px; }
.pulse-success { box-shadow: 0 0 0 rgba(76, 175, 80, 0.4); animation: pulse 2s infinite; }
@keyframes pulse { 0% { box-shadow: 0 0 0 0 rgba(76, 175, 80, 0.4); } 70% { box-shadow: 0 0 0 6px rgba(76, 175, 80, 0); } 100% { box-shadow: 0 0 0 0 rgba(76, 175, 80, 0); } }

.actions-inline { display: flex; gap: 6px; justify-content: center; }
.action-btn { width: 32px !important; height: 32px !important; border-radius: 6px !important; color: #fff !important; }
.action-edit { background: #455A64 !important; }

/* --- MODAL E FORMULÁRIO --- */
.fixed-dialog { overflow: hidden !important; }
.absolute-fill { height: 100%; overflow-y: auto; }
.ui-field :deep(.v-field) { border-radius: 6px !important; }
.row-gap { row-gap: 16px; margin-top: 4px;}
.input-label { display: block; font-size: 11px; font-weight: 800; text-transform: uppercase; color: #757575; margin-bottom: 6px; letter-spacing: 0.5px; }
.bg-glass-dark .input-label { color: rgba(255,255,255,0.7); }
.icon-box { width: 36px; height: 36px; display: flex; align-items: center; justify-content: center; }

/* SIDEBAR TABS - COR SLATE/CHUMBO ELEGANTE */
.bg-blue-grey-darken-4 { background-color: #263238 !important; }
.custom-scroll-dark::-webkit-scrollbar { width: 4px; }
.custom-scroll-dark::-webkit-scrollbar-thumb { background: rgba(255,255,255,0.2); border-radius: 2px; }
.sidebar-tabs :deep(.v-btn) { justify-content: flex-start; text-align: left; height: 52px; font-size: 13px; font-weight: 700; letter-spacing: 0.3px; border-radius: 0; opacity: 0.7;}
.sidebar-tabs :deep(.v-btn--active) { background-color: rgba(255,255,255,0.1); border-right: 4px solid #fff; opacity: 1; }
</style>
