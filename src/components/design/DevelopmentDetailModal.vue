<template>
  <v-dialog :model-value="show" @update:model-value="onClose" max-width="1100px" persistent scrollable transition="dialog-bottom-transition">
    <v-card class="dev-modal-card rounded-xl overflow-hidden shadow-lg border-thin" :class="isLight ? 'bg-grey-lighten-5' : 'bg-surface-dark'">

      <div class="px-6 py-4 d-flex align-center justify-space-between border-b flex-shrink-0" :class="isLight ? 'bg-white border-grey-lighten-2' : 'bg-glass-header border-white-05'">
        <div class="d-flex align-center gap-3">
           <v-avatar :color="isAlteration ? 'orange-lighten-1' : 'primary'" size="44" variant="tonal" class="rounded-lg">
              <v-icon>{{ isAlteration ? 'mdi-pencil-ruler' : 'mdi-palette-swatch-outline' }}</v-icon>
           </v-avatar>
           <div>
             <div class="text-h6 font-weight-black lh-1" :class="isLight ? 'text-grey-darken-4' : 'text-white'">
                {{ isAlteration ? 'Alteração de Arte' : 'Novo Desenvolvimento' }}
             </div>
             <div class="text-caption font-weight-bold opacity-70 font-mono mt-1 d-flex align-center gap-2">
                <v-chip size="x-small" :color="isAlteration ? 'orange' : 'primary'" variant="flat" class="font-weight-black">{{ request.dev_code }}</v-chip>
                <span>Responsável: {{ request.designer?.full_name || 'N/A' }}</span>
             </div>
           </div>
        </div>
        <v-btn icon="mdi-close" variant="text" size="small" @click="onClose"></v-btn>
      </div>

      <v-card-text class="pa-0 d-flex flex-column overflow-hidden relative">

        <div class="px-6 py-4 border-b flex-shrink-0" :class="isLight ? 'bg-white' : 'bg-transparent'">
           <v-text-field
              v-model="globalStampName"
              label="Nome da Estampa / Referência Principal"
              variant="outlined"
              density="comfortable"
              prepend-inner-icon="mdi-tag-text-outline"
              hide-details
              :bg-color="isLight ? 'grey-lighten-5' : 'rgba(0,0,0,0.2)'"
              class="font-weight-bold text-primary"
           ></v-text-field>
        </div>

        <div v-if="request.design_items?.length > 1" class="d-flex justify-center pt-4 pb-2 flex-shrink-0" :class="isLight ? 'bg-grey-lighten-5' : 'bg-transparent'">
            <div class="nav-pill d-flex align-center shadow-sm border-thin" :class="isLight ? 'bg-white' : 'bg-surface-card'">
                <v-btn icon="mdi-chevron-left" variant="text" size="small" color="primary" @click="activeTab--" :disabled="activeTab === 0"></v-btn>
                <div class="px-4 text-caption font-weight-bold text-uppercase d-flex flex-column align-center lh-1">
                    <span class="opacity-60 text-[9px] mb-1">Navegação de Itens</span>
                    <span>Item {{ activeTab + 1 }} de {{ request.design_items.length }}</span>
                </div>
                <v-btn icon="mdi-chevron-right" variant="text" size="small" color="primary" @click="activeTab++" :disabled="activeTab === request.design_items?.length - 1"></v-btn>
            </div>
        </div>

        <div class="flex-grow-1 overflow-hidden d-flex flex-column relative" v-if="request.design_items && itemStates.length > 0">
           <v-window v-model="activeTab" class="flex-grow-1" :touch="false">
             <v-window-item v-for="(item, index) in request.design_items" :key="index" class="fill-height">
                <v-row no-gutters class="fill-height">

                   <v-col cols="12" md="6" class="pa-6 border-r custom-scrollbar overflow-y-auto d-flex flex-column gap-5" :style="isLight ? 'border-color: #e0e0e0;' : 'border-color: rgba(255,255,255,0.05);'">

                       <div class="d-flex align-center gap-3 bg-primary-subtle pa-3 rounded-lg border-thin">
                         <v-avatar color="primary" size="36" variant="flat"><v-icon color="white">mdi-account-tie</v-icon></v-avatar>
                         <div class="d-flex flex-column lh-1">
                             <span class="text-[10px] font-weight-black uppercase opacity-60">Cliente / Destino (Item {{ index + 1 }})</span>
                             <span class="text-subtitle-1 font-weight-black text-uppercase">{{ item.customer_name }}</span>
                         </div>
                       </div>

                       <div class="elegant-box">
                          <div class="box-title"><v-icon size="16" class="mr-1">mdi-text-box-outline</v-icon> Observações Técnicas</div>
                          <div class="pa-4 rounded-lg border-thin text-caption opacity-90 mt-1" :class="isLight ? 'bg-white' : 'bg-black-20'" style="white-space: pre-wrap; line-height: 1.5;">
                              {{ item.notes || 'Nenhuma observação extra informada na solicitação.' }}
                          </div>
                       </div>

                       <div v-if="item.attachments && item.attachments.length > 0" class="elegant-box">
                          <div class="box-title"><v-icon size="16" class="mr-1">mdi-image-multiple</v-icon> Referências Iniciais</div>
                          <div class="d-flex gap-3 mt-2 flex-wrap">
                             <v-card v-for="(url, i) in item.attachments" :key="i" class="border-thin rounded-lg overflow-hidden cursor-pointer hover-scale" width="80" height="80" elevation="2" @click="openImage(url)">
                                <v-img :src="url" cover class="w-100 h-100"></v-img>
                             </v-card>
                          </div>
                       </div>

                       <div v-if="currentItemLogs.length > 0" class="elegant-box">
                          <div class="box-title"><v-icon size="16" class="mr-1">mdi-history</v-icon> Histórico de Ajustes e Rejeições</div>
                          <div class="d-flex flex-column gap-3 mt-2">
                             <div v-for="log in currentItemLogs" :key="log.id" class="pa-4 rounded-lg border-thin" :class="log.type === 'leader' ? (isLight ? 'bg-red-lighten-5 border-red-lighten-4' : 'bg-red-darken-4-alpha border-red-darken-3') : (isLight ? 'bg-orange-lighten-5 border-orange-lighten-4' : 'bg-orange-darken-4-alpha border-orange-darken-3')">
                                <div class="d-flex justify-space-between align-start mb-2">
                                   <div class="d-flex align-center gap-1" :class="log.type === 'leader' ? 'text-error' : 'text-warning-darken-3'">
                                       <v-icon size="14">{{ log.type === 'leader' ? 'mdi-account-cancel' : 'mdi-alert' }}</v-icon>
                                       <span class="text-[10px] font-weight-black text-uppercase">{{ log.author }}</span>
                                   </div>
                                   <span class="text-[10px] opacity-70 font-mono">{{ log.dateFormatted }}</span>
                                </div>
                                <div class="text-caption font-weight-medium" :class="log.type === 'leader' ? (isLight ? 'text-red-darken-4' : 'text-red-lighten-4') : (isLight ? 'text-orange-darken-4' : 'text-orange-lighten-2')">{{ log.reason }}</div>
                                <v-card v-if="log.image" @click="openImage(log.image)" class="mt-3 cursor-pointer rounded border-thin overflow-hidden" width="80" height="80" elevation="2">
                                    <v-img :src="log.image" cover class="w-100 h-100"></v-img>
                                </v-card>
                             </div>
                          </div>
                       </div>

                   </v-col>

                   <v-col cols="12" md="6" class="pa-6 d-flex flex-column" :class="isLight ? 'bg-white' : 'bg-transparent'">
                       <div class="text-subtitle-2 font-weight-black text-uppercase mb-4 d-flex align-center justify-space-between">
                           <div class="d-flex align-center gap-2 text-primary">
                               <v-icon>mdi-cloud-upload</v-icon> Anexar Arte Final
                           </div>
                           <v-chip size="x-small" color="primary" variant="tonal" class="font-weight-bold font-mono">Para: {{ item.customer_name }}</v-chip>
                       </div>

                       <div class="upload-dropzone flex-grow-1 d-flex flex-column align-center justify-center rounded-xl position-relative transition-all"
                            :class="[isDragOver[index] ? 'drag-over' : '', isLight ? 'bg-grey-lighten-5 border-dashed-light' : 'bg-surface-card border-dashed-dark']"
                            @dragover.prevent="isDragOver[index] = true"
                            @dragleave.prevent="isDragOver[index] = false"
                            @drop.prevent="handleDrop($event, index)"
                            @click="triggerFileInput(index)">

                           <input type="file" multiple accept="image/png, image/jpeg" class="d-none" :ref="(el) => setFileRef(el, index)" @change="handleFileSelect($event, index)">

                           <template v-if="itemStates[index].previews.length === 0">
                               <div class="icon-circle bg-primary-lighten-5 text-primary mb-4 elevation-2"><v-icon size="40">mdi-tray-arrow-up</v-icon></div>
                               <div class="font-weight-black text-h6" :class="isLight ? 'text-grey-darken-3' : 'text-white'">Arraste as imagens aqui</div>
                               <div class="text-caption opacity-60 font-weight-medium mt-1">ou clique para selecionar no computador</div>
                               <v-chip size="small" class="mt-4 font-weight-bold" color="grey">Formatos: JPG, PNG</v-chip>
                           </template>

                           <template v-else>
                               <div class="w-100 h-100 pa-4 d-flex align-center align-content-start flex-wrap gap-4 overflow-y-auto custom-scrollbar">
                                   <v-card v-for="(preview, pIdx) in itemStates[index].previews" :key="pIdx" class="preview-card border-thin rounded-lg flex-shrink-0 position-relative overflow-visible" width="120" height="120" elevation="6">
                                       <v-img :src="preview" cover class="w-100 h-100 rounded-lg bg-grey-lighten-3"></v-img>
                                       <v-btn icon size="x-small" color="error" class="remove-btn elevation-4" @click.stop="removeFile(index, pIdx)"><v-icon size="14">mdi-close</v-icon></v-btn>
                                   </v-card>

                                   <v-card class="preview-card border-dashed rounded-lg flex-shrink-0 d-flex flex-column align-center justify-center bg-transparent opacity-60 hover-opacity-100 cursor-pointer transition-all" width="120" height="120" elevation="0">
                                       <v-icon size="32" class="mb-1">mdi-plus</v-icon>
                                       <span class="text-caption font-weight-bold uppercase">Adicionar</span>
                                   </v-card>
                               </div>
                           </template>
                       </div>
                   </v-col>

                </v-row>
             </v-window-item>
           </v-window>
        </div>
      </v-card-text>

      <v-card-actions class="pa-4 border-t d-flex justify-space-between flex-shrink-0" :class="isLight ? 'bg-grey-lighten-4 border-grey-lighten-2' : 'bg-surface-card border-white-05'">
        <div class="text-caption font-weight-medium opacity-70 d-flex align-center">
            <v-icon size="18" class="mr-2" color="primary">mdi-information</v-icon>
            Preencha todos os itens antes de concluir.
        </div>
        <div class="d-flex gap-3">
            <v-btn variant="text" class="font-weight-bold px-6" @click="onClose" :disabled="loading">Cancelar</v-btn>
            <v-btn color="success" variant="flat" size="large" class="font-weight-black px-8 shadow-soft" @click="submitDevelopment" :loading="loading" :disabled="!isFormValid">
                <v-icon start>mdi-send-check</v-icon> Concluir & Enviar
            </v-btn>
        </div>
      </v-card-actions>

    </v-card>
  </v-dialog>
  <ImageModal :show="showImageModal" :imageUrl="selectedImageUrl" @close="showImageModal = false" />
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue';
import { useTheme } from 'vuetify';
import { supabase } from '@/api/supabase';
import { useUserStore } from '@/stores/user';
import ImageModal from '@/components/ImageModal.vue';
import { format, parseISO } from 'date-fns';
import { ptBR } from 'date-fns/locale';

const theme = useTheme();
const isLight = computed(() => !theme.global.current.value.dark);

const props = defineProps({
  show: Boolean,
  request: { type: Object, default: () => ({ id: null, design_items: [], designer: {}, profile: {}, request_type: 'development' }) }
});
const emit = defineEmits(['close', 'completed']);

const userStore = useUserStore();
const loading = ref(false);
const showImageModal = ref(false);
const selectedImageUrl = ref('');

// Refs
const activeTab = ref(0);
const globalStampName = ref('');
const isDragOver = ref<boolean[]>([]);
const itemStates = ref<{ files: File[], previews: string[] }[]>([]);
const rejectionLogs = ref<any[]>([]);
const fileInputRefs = ref<HTMLInputElement[]>([]);

const isAlteration = computed(() => props.request.request_type === 'alteration');

const isFormValid = computed(() => {
    if (!globalStampName.value.trim()) return false;
    return itemStates.value.some(state => state.files.length > 0);
});

const currentItemLogs = computed(() => {
    const logs: any[] = [];

    // 1. Logs da Liderança (Globais daquele Request)
    rejectionLogs.value.forEach(r => {
        logs.push({
            id: 'ldr_' + r.id,
            type: 'leader',
            author: r.leader?.full_name || 'Liderança',
            date: new Date(r.created_at),
            dateFormatted: formatDate(r.created_at),
            reason: r.reason,
            image: r.rejected_image_url
        });
    });

    // 2. Logs do Vendedor/Cliente (Específicos do Item da aba atual)
    const activeItemObj = props.request.design_items?.[activeTab.value];
    if (activeItemObj?.adjustment_log) {
        const parts = activeItemObj.adjustment_log.split(/\[DEVOLUÇÃO VENDEDOR - /).filter((p: string) => p.trim());
        parts.forEach((p: string, pIdx: number) => {
            if (p.includes(']:')) {
                const [dateStr, ...rest] = p.split(']:');
                const reason = rest.join(']:').trim();
                logs.push({
                    id: `vnd_${activeTab.value}_${pIdx}`,
                    type: 'seller',
                    author: props.request.profile?.full_name || 'Vendedor',
                    date: new Date(),
                    dateFormatted: dateStr,
                    reason: reason,
                    image: null
                });
            } else if (!p.includes('-----') && p.trim()) {
                 logs.push({
                    id: `vnd_leg_${activeTab.value}_${pIdx}`,
                    type: 'seller',
                    author: props.request.profile?.full_name || 'Vendedor',
                    date: new Date(0),
                    dateFormatted: 'Ajuste (Sem Data)',
                    reason: p.trim(),
                    image: null
                });
            }
        });
    }
    return logs.sort((a, b) => b.date.getTime() - a.date.getTime());
});

watch(() => props.show, async (newValue) => {
  if (newValue && props.request.dev_code) {
    activeTab.value = 0;

    const firstCustomer = props.request.design_items?.[0]?.customer_name || 'Cliente';
    globalStampName.value = props.request.new_stamp?.name || `${firstCustomer} - ${props.request.dev_code}`;

    const itemsLen = props.request.design_items?.length || 0;
    itemStates.value = Array.from({ length: itemsLen }, () => ({ files: [], previews: [] }));
    isDragOver.value = Array.from({ length: itemsLen }, () => false);
    fileInputRefs.value = [];

    await fetchRejectionLogs();
  } else {
    itemStates.value.forEach(state => {
        state.previews.forEach(p => URL.revokeObjectURL(p));
    });
    itemStates.value = [];
  }
});

const fetchRejectionLogs = async () => {
    try {
        const { data } = await supabase.from('design_rejection_logs')
           .select('*, leader:profiles!leader_id(full_name)')
           .eq('item_id', props.request.id)
           .order('created_at', { ascending: false });
        rejectionLogs.value = data || [];
    } catch(e) {
        console.error(e);
    }
};

const setFileRef = (el: any, index: number) => {
    if (el) fileInputRefs.value[index] = el as HTMLInputElement;
};

const triggerFileInput = (index: number) => {
    if (fileInputRefs.value[index]) {
        fileInputRefs.value[index].click();
    }
};

const formatDate = (iso: string) => format(parseISO(iso), "dd/MM/yyyy HH:mm", { locale: ptBR });

const handleDrop = (e: DragEvent, index: number) => {
    isDragOver.value[index] = false;
    const files = e.dataTransfer?.files;
    if (files && files.length > 0) {
        addFilesToItem(Array.from(files), index);
    }
};

const handleFileSelect = (e: Event, index: number) => {
    const input = e.target as HTMLInputElement;
    if (input.files && input.files.length > 0) {
        addFilesToItem(Array.from(input.files), index);
        input.value = '';
    }
};

const addFilesToItem = (files: File[], index: number) => {
    const validFiles = files.filter(f => f.type.startsWith('image/'));
    const state = itemStates.value[index];
    validFiles.forEach(file => {
        state.files.push(file);
        state.previews.push(URL.createObjectURL(file));
    });
};

const removeFile = (itemIndex: number, fileIndex: number) => {
    const state = itemStates.value[itemIndex];
    URL.revokeObjectURL(state.previews[fileIndex]);
    state.files.splice(fileIndex, 1);
    state.previews.splice(fileIndex, 1);
};

const openImage = (url: string) => {
  selectedImageUrl.value = url;
  showImageModal.value = true;
};

const onClose = () => {
  emit('close');
};

const submitDevelopment = async () => {
  if (!isFormValid.value || !userStore.profile) return;
  loading.value = true;

  try {
    const newDesignItems = JSON.parse(JSON.stringify(props.request.design_items));
    const allUploadedUrls: string[] = [];
    let coverUrl = '';

    for (let i = 0; i < itemStates.value.length; i++) {
       const state = itemStates.value[i];
       const itemUrls: string[] = [];

       for (let j = 0; j < state.files.length; j++) {
           const file = state.files[j];
           const fileExt = file.name.split('.').pop();
           const filePath = `stamp-library/${Date.now()}_item${i}_img${j}.${fileExt}`;

           const { error: uploadError } = await supabase.storage.from('arts').upload(filePath, file);
           if (uploadError) throw new Error(`Falha no upload (Item ${i+1}): ${uploadError.message}`);

           const { data: urlData } = supabase.storage.from('arts').getPublicUrl(filePath);
           itemUrls.push(urlData.publicUrl);
           allUploadedUrls.push(urlData.publicUrl);

           if (!coverUrl) coverUrl = urlData.publicUrl;
       }

       if (itemUrls.length > 0) {
           newDesignItems[i].uploaded_arts = itemUrls;
           newDesignItems[i].stamp_image_url = itemUrls[0];
       }
    }

    if (!coverUrl) coverUrl = props.request.final_art_url || '';

    // =========================================================
    // CORREÇÃO GESTÃOCLICK (EVITAR O ERRO "NOT NULL")
    // Gera um ID falso caso não exista na estampa vinculada
    // =========================================================
    let serviceId = props.request.new_stamp?.gestao_click_service_id || null;
    if (!serviceId) {
        serviceId = String(Date.now()); // Fallback seguro
    }

    let stampId = props.request.new_stamp_id;
    if (stampId) {
        await supabase.from('stamp_library').update({
            name: globalStampName.value,
            image_url: coverUrl,
            is_approved_for_sale: false
        }).eq('id', stampId);
    } else {
        const { data: newStamp, error: stampError } = await supabase
          .from('stamp_library')
          .insert({
            name: globalStampName.value,
            image_url: coverUrl,
            is_approved_for_sale: false,
            gestao_click_service_id: serviceId
          })
          .select()
          .single();
        if (stampError) throw stampError;
        stampId = newStamp.id;
    }

    const { error: updateError } = await supabase
      .from('design_requests')
      .update({
        status: 'pending_approval',
        final_art_url: coverUrl,
        additional_arts: allUploadedUrls.length > 0 ? allUploadedUrls : props.request.additional_arts,
        design_items: newDesignItems,
        new_stamp_id: stampId
      })
      .eq('id', props.request.id);

    if (updateError) throw updateError;

    await supabase.from('notifications').insert({
      recipient_id: props.request.created_by,
      sender_id: userStore.profile.id,
      content: `O desenvolvimento "${globalStampName.value}" foi concluído/atualizado.`,
      redirect_url: '/approvals'
    });

    emit('completed');
    onClose();

  } catch (error: any) {
    console.error("Erro ao submeter:", error);
    alert(`Erro: ${error.message || 'Erro desconhecido'}`);
  } finally {
    loading.value = false;
  }
};
</script>

<style scoped lang="scss">
/* MODAL SIZE & BG */
.dev-modal-card { max-height: 88vh; display: flex; flex-direction: column; }
.bg-surface-dark { background: rgba(28, 28, 33, 0.98); }
.bg-glass-header { background: rgba(255,255,255,0.03); }

/* BORDERS */
.border-white-05 { border-color: rgba(255,255,255,0.05) !important; }
.border-thin { border: 1px solid rgba(128,128,128,0.2) !important; }
.border-dashed-light { border: 2px dashed #cfd8dc !important; }
.border-dashed-dark { border: 2px dashed rgba(255,255,255,0.15) !important; }

/* ELEGANT BOXES */
.elegant-box { display: flex; flex-direction: column; gap: 4px; }
.box-title { font-size: 0.75rem; font-weight: 900; text-transform: uppercase; letter-spacing: 0.5px; opacity: 0.7; display: flex; align-items: center; }

/* DROPZONE */
.upload-dropzone { transition: all 0.2s ease; cursor: pointer; min-height: 300px; }
.drag-over { border-color: var(--v-theme-primary) !important; background: rgba(var(--v-theme-primary), 0.08) !important; transform: scale(1.02); }
.icon-circle { width: 72px; height: 72px; border-radius: 50%; display: flex; align-items: center; justify-content: center; }
.icon-box-header { width: 48px; height: 48px; border-radius: 12px; display: flex; align-items: center; justify-content: center; }

/* PREVIEWS */
.preview-card { border-color: rgba(128,128,128,0.2) !important; }
.remove-btn { position: absolute; top: -6px; right: -6px; z-index: 10; opacity: 0; transition: opacity 0.2s; }
.preview-card:hover .remove-btn { opacity: 1; }

/* NAVEGAÇÃO PÍLULA (NAV-PILL) */
.nav-pill { border-radius: 50px; padding: 2px; }
.hover-scale { transition: transform 0.2s; }
.hover-scale:hover { transform: scale(1.05); }

/* OTHERS */
.bg-primary-subtle { background: rgba(var(--v-theme-primary), 0.08); }
.bg-red-darken-4-alpha { background: rgba(183, 28, 28, 0.15); }
.bg-orange-darken-4-alpha { background: rgba(230, 81, 0, 0.15); }
.lh-1 { line-height: 1.1; }
.custom-scrollbar::-webkit-scrollbar { width: 6px; }
.custom-scrollbar::-webkit-scrollbar-thumb { background-color: rgba(128, 128, 128, 0.3); border-radius: 3px; }
</style>
