<template>
  <v-dialog
    :model-value="show"
    @update:model-value="$emit('close')"
    max-width="1600px"
    height="95vh"
    :fullscreen="mobile"
    scrollable
    transition="dialog-bottom-transition"
    content-class="glass-modal-content"
  >
        <v-card
        class="fill-height d-flex overflow-hidden"
        :class="[themeClass, mobile ? 'flex-column' : 'flex-row']"
        :style="mobile ? 'height: 100dvh; min-height: 0;' : 'min-height: 0;'"
      >

      <div
        class="sidebar-filters d-flex flex-column"
        :class="[
            sidebarClass,
            mobile ? 'border-b w-100 flex-shrink-0' : 'border-r h-100'
        ]"
        :style="mobile ? '' : 'width: 320px; min-width: 320px;'"
      >

        <div class="pa-6 pb-2">
           <div class="d-flex align-center justify-space-between mb-4">
               <div class="d-flex align-center gap-3">
                  <div class="icon-box-md rounded-lg" :class="iconBoxClass">
                     <v-icon size="24" color="primary">mdi-image-multiple</v-icon>
                  </div>
                  <div>
                     <div class="text-[10px] font-weight-bold uppercase opacity-60 letter-spacing-1" :class="textSecondaryClass">Biblioteca</div>
                     <h2 class="text-h6 font-weight-black lh-1" :class="textPrimaryClass">Catálogo</h2>
                  </div>
               </div>
               <v-btn v-if="mobile" icon size="small" variant="text" @click="$emit('close')"><v-icon>mdi-close</v-icon></v-btn>
           </div>

           <v-btn
             block
             size="large"
             :color="viewMode === 'upload' ? 'secondary' : 'primary'"
             :variant="viewMode === 'upload' ? 'tonal' : 'flat'"
             class="font-weight-bold mb-6 rounded-lg"
             @click="toggleViewMode"
           >
             <v-icon start>{{ viewMode === 'upload' ? 'mdi-view-grid' : 'mdi-cloud-upload' }}</v-icon>
             {{ viewMode === 'upload' ? 'Voltar ao Catálogo' : 'Nova Estampa' }}
           </v-btn>

           <div v-if="viewMode === 'catalog'">
               <v-text-field
                 v-model="search"
                 placeholder="Buscar por nome, ID ou tag..."
                 density="compact"
                 variant="outlined"
                 prepend-inner-icon="mdi-magnify"
                 hide-details
                 class="rounded-lg mb-4"
                 :bg-color="inputBgColor"
                 clearable
                 @update:model-value="performSearch"
               ></v-text-field>

               <div class="d-flex align-center justify-space-between">
                   <div class="text-[10px] font-weight-bold uppercase opacity-50 px-1" :class="textSecondaryClass">Filtros Rápidos</div>
                   </div>

               <div class="d-flex flex-wrap gap-2 mb-4 mt-2">
                  <v-chip size="small" filter variant="outlined" :color="filter === 'all' ? 'primary' : ''" @click="filter = 'all'">Todas</v-chip>
                  <v-chip size="small" filter variant="outlined" :color="filter === 'recent' ? 'primary' : ''" @click="filter = 'recent'">Recentes</v-chip>
               </div>

               <v-expand-transition>
                   <div v-if="!mobile || filteredStamps.length > 0">
                       <v-divider class="mb-4 opacity-20"></v-divider>
                       <div class="kpi-box pa-4 rounded-lg border-thin" :class="kpiBoxClass">
                          <div class="d-flex justify-space-between align-center mb-1">
                             <span class="text-[10px] font-weight-bold uppercase opacity-60" :class="textSecondaryClass">Exibindo</span>
                             <v-icon size="14" class="opacity-50">mdi-database</v-icon>
                          </div>
                          <div class="text-h4 font-weight-black lh-1" :class="textPrimaryClass">{{ filteredStamps.length }}</div>
                          <div class="text-caption font-weight-bold text-success mt-1">
                             <v-icon size="small" color="success">mdi-check-circle-outline</v-icon> Resultados
                          </div>
                       </div>
                   </div>
               </v-expand-transition>
           </div>

           <div v-else class="text-center pa-4">
              <v-icon size="48" color="primary" class="mb-2 opacity-50">mdi-cloud-upload-outline</v-icon>
              <div class="text-subtitle-2 font-weight-bold" :class="textPrimaryClass">Modo de Upload</div>
              <p class="text-caption opacity-60" :class="textSecondaryClass">Arraste arquivos ou preencha os dados para cadastrar uma nova arte.</p>
           </div>
        </div>

        <div v-if="!mobile" class="mt-auto pa-4 border-t" :class="borderColorClass">
           <div class="d-flex align-center justify-space-between text-caption opacity-60" :class="textSecondaryClass">
              <span>Sincronizado</span>
              <span class="font-mono">{{ lastSynced }}</span>
           </div>
        </div>
      </div>

      <div class="main-content flex-grow-1 d-flex flex-column bg-pattern relative" style="min-width: 0; min-height: 0;">

         <div v-if="!mobile" class="px-6 py-3 border-b d-flex align-center justify-space-between flex-shrink-0" :class="headerClass">
            <div class="d-flex align-center gap-2">
               <v-icon size="20" class="opacity-50" :color="textPrimaryClass">{{ viewMode === 'upload' ? 'mdi-tray-arrow-up' : 'mdi-grid' }}</v-icon>
               <span class="text-caption font-weight-bold uppercase opacity-60" :class="textPrimaryClass">
                  {{ viewMode === 'upload' ? 'Cadastro de Nova Estampa' : `Resultados da Busca` }}
               </span>
            </div>
            <v-btn icon size="small" variant="text" @click="$emit('close')" :color="textPrimaryClass"><v-icon>mdi-close</v-icon></v-btn>
         </div>

         <div v-if="viewMode === 'catalog'" class="flex-grow-1 overflow-y-auto custom-scrollbar pa-6" style="min-height:0;">

            <div v-if="loading" class="d-flex flex-column justify-center align-center h-100 opacity-50">
               <v-progress-circular indeterminate color="primary" size="48" width="4"></v-progress-circular>
               <span class="mt-4 text-caption font-weight-bold letter-spacing-1 uppercase" :class="textPrimaryClass">Buscando artes...</span>
            </div>

            <div v-else-if="stamps.length === 0" class="d-flex flex-column justify-center align-center h-100 opacity-40" style="min-height: 200px;">
               <div class="icon-circle-lg bg-surface-variant mb-4 d-flex align-center justify-center">
                  <v-icon size="40" :color="textPrimaryClass">mdi-image-search-outline</v-icon>
               </div>
               <div class="text-h6 font-weight-bold" :class="textPrimaryClass">Nenhuma estampa encontrada</div>
               <div class="text-caption" :class="textSecondaryClass">Tente outro termo ou cadastre uma nova.</div>
               <v-btn variant="tonal" color="primary" class="mt-4" @click="viewMode = 'upload'">Cadastrar Nova</v-btn>
            </div>

            <v-row v-else dense>
               <v-col
                 v-for="stamp in filteredStamps"
                 :key="stamp.id"
                 cols="6" sm="4" md="3" lg="3" xl="2"
               >
                  <v-card
                    class="stamp-card cursor-pointer group"
                    :class="cardThemeClass"
                    @click="selectStamp(stamp.id)"
                    v-ripple
                  >
                     <div class="image-wrapper relative aspect-square overflow-hidden bg-pattern-checkered">
                        <v-img
                           :src="stamp.imagem_url"
                           aspect-ratio="1"
                           cover
                           class="transition-transform duration-300 group-hover:scale-110"
                        >
                           <template v-slot:placeholder>
                              <div class="d-flex align-center justify-center fill-height bg-surface-variant">
                                 <v-progress-circular indeterminate color="grey" size="20" width="2"></v-progress-circular>
                              </div>
                           </template>
                           <template v-slot:error>
                               <div class="d-flex align-center justify-center fill-height bg-surface-variant text-caption text-grey">
                                   <v-icon>mdi-image-off</v-icon>
                               </div>
                           </template>
                        </v-img>
                        <div class="overlay-hover absolute inset-0 bg-black-50 d-flex align-center justify-center opacity-0 group-hover:opacity-100 transition-opacity">
                           <v-btn color="white" size="small" variant="flat" class="font-weight-bold text-black">Selecionar</v-btn>
                        </div>
                     </div>
                     <div class="pa-3 border-t" :class="borderColorClass">
                        <div class="text-subtitle-2 font-weight-bold text-truncate mb-1" :class="textPrimaryClass">{{ stamp.nome }}</div>
                        <div class="d-flex justify-space-between align-center">
                           <v-chip size="x-small" variant="outlined" class="font-mono text-[9px] h-16 px-1" :class="textSecondaryClass">ID: {{ String(stamp.id).substring(0,4) }}</v-chip>
                           <v-icon size="14" color="success" v-if="stamp.is_approved">mdi-check-decagram</v-icon>
                        </div>
                     </div>
                  </v-card>
               </v-col>
            </v-row>
         </div>

 <div v-else class="flex-grow-1 overflow-y-auto custom-scrollbar pa-4 md:pa-8" style="min-height:0;">
            <div
               class="upload-container mx-auto d-flex flex-column"
               :class="!mobile ? 'h-100 justify-center' : ''"
               style="max-width: 1200px;"
            >

               <v-row
                  class=""
                  :class="mobile ? 'flex-column-reverse' : 'fill-height align-center'"
                  :style="mobile ? '' : 'min-height: 500px;'"
               >

                  <v-col cols="12" md="7" :class="mobile ? 'flex-grow-0 mt-4' : 'h-100'">
                     <div
                       class="upload-dropzone relative rounded-xl border-dashed d-flex align-center justify-center overflow-hidden transition-all"
                       :class="[
                          isDragging ? 'border-primary bg-primary-opacity' : borderColorClass,
                          newStamp.previewUrl ? 'bg-black' : 'bg-surface-variant',
                          !mobile ? 'h-100' : ''
                       ]"
                       :style="mobile ? 'min-height: 300px;' : 'min-height: 450px;'"
                       style="border-width: 3px;"
                       @dragover.prevent="isDragging = true"
                       @dragleave.prevent="isDragging = false"
                       @drop.prevent="handleDrop"
                       @click="triggerFileInput"
                     >
                        <input type="file" ref="hiddenFileInput" @change="handleFileChange" accept="image/png, image/jpeg" style="display: none;" />

                        <v-img v-if="newStamp.previewUrl" :src="newStamp.previewUrl" class="fill-height width-100" contain>
                           <div class="absolute top-4 right-4">
                              <v-btn icon="mdi-close" size="small" color="white" variant="flat" @click.stop="clearPreview"></v-btn>
                           </div>
                           <div class="absolute bottom-0 left-0 right-0 pa-3 bg-gradient-to-t">
                              <div class="text-white text-caption font-mono text-center">
                                 {{ newStamp.file?.name }} ({{ (newStamp.file?.size / 1024).toFixed(1) }} KB)
                              </div>
                           </div>
                        </v-img>

                        <div v-else class="text-center pa-6 md:pa-10">
                           <div class="icon-circle-xl bg-surface-variant mb-6 mx-auto d-flex align-center justify-center">
                              <v-icon size="64" :color="isDragging ? 'primary' : 'grey'">mdi-cloud-upload</v-icon>
                           </div>
                           <h3 class="text-h5 font-weight-black mb-2" :class="textPrimaryClass">Arraste a imagem aqui</h3>
                           <p class="text-body-1 opacity-60 mb-6" :class="textSecondaryClass">Suporta JPG e PNG de alta resolução.</p>
                           <v-btn size="large" variant="outlined" color="primary" class="font-weight-bold px-8">Selecionar</v-btn>
                        </div>
                     </div>
                  </v-col>

                  <v-col cols="12" md="5" :class="mobile ? 'flex-grow-0 mb-2' : 'h-100'">
                     <div class="pa-2 md:pa-6 d-flex flex-column" :class="!mobile ? 'h-100 justify-center' : ''">
                        <div class="mb-6 md:mb-8">
                           <h3 class="text-h4 font-weight-black mb-2" :class="textPrimaryClass">Nova Arte</h3>
                           <p class="text-body-1 opacity-60" :class="textSecondaryClass">Defina o nome da referência para o catálogo.</p>
                        </div>

                        <v-form ref="formRef">
                           <div class="mb-6 md:mb-8">
                              <label class="text-caption font-weight-bold uppercase opacity-70 mb-2 d-block" :class="textSecondaryClass">Nome da Referência</label>
                              <v-text-field
                                 v-model="newStamp.name"
                                 placeholder="Ex: Floral Verão 2025"
                                 variant="outlined"
                                 density="comfortable"
                                 :bg-color="inputBgColor"
                                 :error-messages="newStamp.nameError"
                                 :rules="[rules.required]"
                                 class="font-weight-bold text-h6"
                              >
                                 <template v-slot:append-inner>
                                    <v-progress-circular v-if="isValidatingName" indeterminate size="24" width="2" color="primary"></v-progress-circular>
                                    <v-icon v-else-if="newStamp.name && !newStamp.nameError" color="success">mdi-check-circle</v-icon>
                                 </template>
                              </v-text-field>

                              <v-expand-transition>
                                 <v-alert v-if="newStamp.nameError" type="error" variant="tonal" density="compact" class="mt-2 text-caption border-dashed">
                                    <template v-slot:prepend><v-icon size="small">mdi-alert-circle</v-icon></template>
                                    <strong>Duplicidade:</strong> {{ newStamp.nameError }}
                                 </v-alert>
                              </v-expand-transition>
                           </div>

                           <div class="pa-4 rounded-lg border border-opacity-10 mb-6 md:mb-8 bg-surface-variant">
                              <div class="d-flex align-center gap-2 mb-2">
                                 <v-icon size="small" color="info">mdi-information-outline</v-icon>
                                 <span class="text-[10px] font-weight-bold uppercase opacity-70" :class="textSecondaryClass">Metadados da Imagem</span>
                              </div>
                              <div class="d-flex justify-space-between text-caption font-mono opacity-80" :class="textSecondaryClass">
                                 <span>Dimensões: {{ meta.width }}x{{ meta.height }}px</span>
                                 <span>Tipo: {{ meta.type }}</span>
                              </div>
                           </div>
                        </v-form>

                        <div class="d-flex flex-column gap-3 mt-2">
                           <v-btn
                              block
                              size="x-large"
                              height="64"
                              color="success"
                              variant="flat"
                              class="font-weight-black shadow-glow-success rounded-xl text-h6"
                              :loading="newStamp.isUploading"
                              :disabled="!isValidUpload"
                              @click="uploadAndRegisterNewStamp"
                           >
                              <v-icon start size="28">mdi-content-save-check</v-icon> Salvar e Selecionar
                           </v-btn>
                           <p class="text-caption text-center opacity-50" :class="textSecondaryClass">A estampa será salva na biblioteca de forma nativa.</p>
                        </div>
                     </div>
                  </v-col>
               </v-row>

            </div>
         </div>

      </div>
    </v-card>
  </v-dialog>
</template>

<script setup lang="ts">
import { ref, watch, reactive, computed } from 'vue';
import { supabase } from '@/api/supabase';
import { useAppStore } from '@/stores/app';
import { useThemeStore } from '@/stores/theme';
import { format } from 'date-fns';
import { useDisplay } from 'vuetify';

type StampItem = { id: string; nome: string; imagem_url?: string; is_approved?: boolean; created_at?: string; };

const props = defineProps<{ show: boolean; }>();
const emit = defineEmits(['close', 'stamp-selected']);
const appStore = useAppStore();
const themeStore = useThemeStore();
const { mobile } = useDisplay();

const viewMode = ref<'catalog' | 'upload'>('catalog');
const search = ref('');
const loading = ref(false);
const stamps = ref<StampItem[]>([]);
const filter = ref('all');
const lastSynced = ref(format(new Date(), 'HH:mm'));
const isValidatingName = ref(false);

const newStamp = reactive({
    name: '',
    file: null as File | null,
    previewUrl: '',
    isUploading: false,
    nameError: ''
});
const meta = reactive({ width: 0, height: 0, type: '-' });

let searchTimeout: NodeJS.Timeout;
let stampNameCheckTimeout: NodeJS.Timeout;

const hiddenFileInput = ref<HTMLInputElement | null>(null);
const isDragging = ref(false);

const rules = { required: (v: string) => !!v.trim() || 'Campo obrigatório.' };

const themeClass = computed(() => themeStore.currentMode === 'light' ? 'bg-white text-grey-darken-3' : 'bg-glass-dark text-white');
const sidebarClass = computed(() => themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-glass-sidebar border-white-10');
const headerClass = computed(() => themeStore.currentMode === 'light' ? 'bg-white border-grey-lighten-2' : 'bg-glass-header border-white-05');
const cardThemeClass = computed(() => themeStore.currentMode === 'light' ? 'bg-white border-grey-lighten-2 shadow-sm' : 'bg-glass-card border-white-10');
const inputBgColor = computed(() => themeStore.currentMode === 'light' ? 'white' : 'rgba(0,0,0,0.2)');
const textPrimaryClass = computed(() => themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white');
const textSecondaryClass = computed(() => themeStore.currentMode === 'light' ? 'text-grey-darken-1' : 'text-white-50');
const iconBoxClass = computed(() => themeStore.currentMode === 'light' ? 'bg-blue-lighten-5 text-blue-darken-3' : 'bg-surface-light text-primary');
const borderColorClass = computed(() => themeStore.currentMode === 'light' ? 'border-grey-lighten-2' : 'border-white-10');
const kpiBoxClass = computed(() => themeStore.currentMode === 'light' ? 'bg-white border-grey-lighten-2' : 'bg-surface-light border-white-10');

const filteredStamps = computed(() => {
    let list = stamps.value;
    if (filter.value === 'recent') list = list.slice(0, 20);
    return list;
});

const isValidUpload = computed(() => {
    return !!newStamp.file && !!newStamp.name && !newStamp.nameError && !isValidatingName.value;
});

const toggleViewMode = () => {
    viewMode.value = viewMode.value === 'catalog' ? 'upload' : 'catalog';
    if (viewMode.value === 'catalog') performSearch();
};

const performSearch = () => {
  if (viewMode.value === 'upload') return;
  loading.value = true;
  clearTimeout(searchTimeout);

  searchTimeout = setTimeout(async () => {
    try {
      const searchTerm = search.value || '';

      let query = supabase
        .from('stamp_library')
        .select('id, name, image_url, is_approved_for_sale')
        .order('created_at', { ascending: false })
        .limit(100);

      if (searchTerm) {
         query = query.ilike('name', `%${searchTerm}%`);
      }

      const { data: images, error } = await query;
      if (error) console.error("Erro Supabase:", error);

      stamps.value = (images || []).map(img => ({
          id: img.id,
          nome: img.name,
          imagem_url: img.image_url,
          is_approved: img.is_approved_for_sale !== false
      }));

    } catch (error) {
        console.error("Erro na busca:", error);
        stamps.value = [];
    } finally {
        loading.value = false;
    }
  }, 600);
};

const selectStamp = (stampId: string) => {
    const selectedStamp = stamps.value.find(s => s.id === stampId);
    if (selectedStamp) {
        emit('stamp-selected', selectedStamp);
        emit('close');
    }
};

const triggerFileInput = () => hiddenFileInput.value?.click();

const handleFile = (file: File | null) => {
  if (!file || !file.type.startsWith('image/')) {
    if (file) appStore.showSnackbar('Formato inválido. Use PNG ou JPG.', 'error');
    return;
  }
  newStamp.file = file;
  if (newStamp.previewUrl) URL.revokeObjectURL(newStamp.previewUrl);
  newStamp.previewUrl = URL.createObjectURL(file);

  const img = new Image();
  img.onload = () => { meta.width = img.width; meta.height = img.height; meta.type = file.type.split('/')[1].toUpperCase(); };
  img.src = newStamp.previewUrl;
};

const handleFileChange = (e: Event) => handleFile((e.target as HTMLInputElement).files?.[0] || null);
const handleDrop = (e: DragEvent) => { isDragging.value = false; handleFile(e.dataTransfer?.files[0] || null); };
const clearPreview = () => {
  if (newStamp.previewUrl) URL.revokeObjectURL(newStamp.previewUrl);
  Object.assign(newStamp, { file: null, previewUrl: '' });
  meta.width = 0; meta.height = 0;
  if (hiddenFileInput.value) hiddenFileInput.value.value = '';
};

watch(() => newStamp.name, (newName) => {
  if (!newName) { newStamp.nameError = ''; return; }
  isValidatingName.value = true;
  clearTimeout(stampNameCheckTimeout);
  stampNameCheckTimeout = setTimeout(async () => {
    try {
      const { data } = await supabase.from('stamp_library').select('id, name').ilike('name', newName).maybeSingle();
      newStamp.nameError = data ? `Nome em uso (ID: ${String(data.id).substring(0,4)}).` : '';
    } catch (error) { console.error("Erro ao verificar nome:", error); }
    finally { isValidatingName.value = false; }
  }, 800);
});

const sanitizeName = (name: string) => name.replace(/\s/g, '_').replace(/[^\w.\-]/g, '');
const uploadFile = async (file: File, bucket: string, path: string) => {
  const { error } = await supabase.storage.from(bucket).upload(path, file, { upsert: true });
  if (error) throw error;
  return supabase.storage.from(bucket).getPublicUrl(path).data.publicUrl;
};

const uploadAndRegisterNewStamp = async () => {
  if (!isValidUpload.value) return;
  newStamp.isUploading = true;
  try {
    const path = `public/${Date.now()}-${sanitizeName(newStamp.file!.name)}`;
    const url = await uploadFile(newStamp.file!, 'stamp-library', path);

    const payload = {
        name: newStamp.name,
        image_url: url,
        is_approved_for_sale: true,
        gestao_click_service_id: String(Date.now()) // CORREÇÃO: Passa um ID numérico fake para evitar o erro do banco NOT NULL
    };

    const { data, error } = await supabase.from('stamp_library').insert(payload).select().single();
    if (error) throw error;

    appStore.showSnackbar(`Estampa "${newStamp.name}" salva com sucesso!`, 'success');

    stamps.value.unshift({
        id: data.id,
        nome: data.name,
        imagem_url: url,
        is_approved: true
    });

    selectStamp(data.id);

  } catch (error: any) {
      console.error("Erro completo:", error);
      appStore.showSnackbar(`Erro ao salvar: ${error.message}`, 'error');
  } finally {
      newStamp.isUploading = false;
  }
};

watch(() => props.show, (newVal) => {
  if (newVal) {
    viewMode.value = 'catalog';
    search.value = '';
    performSearch();
    clearPreview();
    Object.assign(newStamp, { name: '', file: null, isUploading: false, nameError: '' });
    lastSynced.value = format(new Date(), 'HH:mm');
  }
});
</script>

<style scoped lang="scss">
/* ESTILOS ORIGINAIS MANTIDOS IGUAIS */
.glass-modal-content { backdrop-filter: blur(20px); }
.bg-glass-dark { background: rgba(30, 30, 35, 0.95); }
.bg-glass-sidebar { background: rgba(30, 30, 35, 0.5); }
.bg-glass-header { background: rgba(255, 255, 255, 0.03); }
.bg-glass-card { background: rgba(255, 255, 255, 0.05); }
.bg-surface-light { background: rgba(255, 255, 255, 0.05); }
.bg-pattern { background-image: radial-gradient(rgba(128,128,128,0.1) 1px, transparent 1px); background-size: 20px 20px; }
.bg-pattern-checkered {
    background-image: linear-gradient(45deg, #ccc 25%, transparent 25%), linear-gradient(-45deg, #ccc 25%, transparent 25%), linear-gradient(45deg, transparent 75%, #ccc 75%), linear-gradient(-45deg, transparent 75%, #ccc 75%);
    background-size: 20px 20px;
    background-position: 0 0, 0 10px, 10px -10px, -10px 0px;
    background-color: #eee;
}

.border-white-10 { border-color: rgba(255, 255, 255, 0.1) !important; }
.border-white-05 { border-color: rgba(255, 255, 255, 0.05) !important; }
.border-grey-lighten-2 { border-color: #E0E0E0 !important; }

.text-white-50 { color: rgba(255,255,255,0.5); }
.lh-1 { line-height: 1; }
.gap-3 { gap: 12px; } .gap-2 { gap: 8px; }
.relative { position: relative; }
.absolute { position: absolute; }
.inset-0 { top: 0; left: 0; right: 0; bottom: 0; }
.top-2 { top: 8px; } .right-2 { right: 8px; } .bottom-0 { bottom: 0; }
.top-4 { top: 16px; } .right-4 { right: 16px; }
.h-16 { height: 16px; }
.cursor-pointer { cursor: pointer; }
.opacity-0 { opacity: 0; }
.group:hover .group-hover\:scale-110 { transform: scale(1.1); }
.group:hover .group-hover\:opacity-100 { opacity: 1; }
.transition-transform { transition: transform 0.3s ease; }
.transition-opacity { transition: opacity 0.3s ease; }
.bg-black-50 { background: rgba(0,0,0,0.5); }
.bg-gradient-to-t { background: linear-gradient(to top, rgba(0,0,0,0.8), transparent); }

.icon-box-md { width: 40px; height: 40px; display: flex; align-items: center; justify-content: center; }
.icon-circle-lg { width: 80px; height: 80px; border-radius: 50%; }
.icon-circle-xl { width: 120px; height: 120px; border-radius: 50%; }
.bg-surface-variant { background-color: rgba(128, 128, 128, 0.1); }

.stamp-card {
    border-radius: 12px;
    border: 1px solid;
    overflow: hidden;
    transition: all 0.2s ease;
    &:hover { transform: translateY(-4px); box-shadow: 0 8px 20px rgba(0,0,0,0.2); }
}

.upload-dropzone {
    cursor: pointer;
    transition: all 0.3s ease;
    &:hover { background-color: rgba(var(--v-theme-primary), 0.05); border-color: rgba(var(--v-theme-primary), 0.5); }
    &.bg-primary-opacity { background-color: rgba(var(--v-theme-primary), 0.1); }
}

.custom-scrollbar {
  -webkit-overflow-scrolling: touch;
  overscroll-behavior: contain;
}
.custom-scrollbar::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.3); border-radius: 3px; }
</style>
