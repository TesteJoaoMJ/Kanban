<template>
  <v-dialog :model-value="show" @update:model-value="closeModal" max-width="550px" persistent>
    <v-card class="rounded-xl overflow-hidden shadow-2xl" :class="isLightMode ? 'bg-white' : 'glassmorphism-card border-white-10'">

      <div class="px-6 py-4 d-flex align-center justify-space-between border-b" :class="isLightMode ? 'border-grey-lighten-2 bg-grey-lighten-5' : 'border-white-10 bg-black-20'">
        <div class="d-flex align-center gap-3">
            <v-avatar size="36" :color="isLightMode ? 'primary-lighten-5' : 'rgba(255,255,255,0.1)'" class="text-primary rounded-lg border-thin">
                <v-icon size="20" :color="isLightMode ? 'primary' : 'white'">mdi-cloud-upload-outline</v-icon>
            </v-avatar>
            <span class="text-subtitle-1 font-weight-black text-uppercase tracking-tight" :class="isLightMode ? 'text-grey-darken-4' : 'text-white'">{{ title }}</span>
        </div>
        <v-btn icon="mdi-close" variant="text" size="small" @click="closeModal" :color="isLightMode ? 'grey-darken-2' : 'white-70'"></v-btn>
      </div>

      <v-card-text class="pa-6">
        <div class="mb-5 pa-4 rounded-lg border-thin d-flex gap-3" :class="isLightMode ? 'bg-blue-lighten-5 border-blue-lighten-4' : 'bg-blue-darken-4-alpha border-blue-darken-3'">
           <v-icon color="primary" class="mt-1">mdi-information</v-icon>
           <div>
               <p class="text-body-2 font-weight-medium lh-1-4" :class="isLightMode ? 'text-blue-darken-4' : 'text-white-80'">
                  Anexe o arquivo de arte final para o pedido de <strong>{{ order?.customer_name || 'Cliente' }}</strong>.
               </p>
               <span class="text-caption opacity-70">A arte ficará disponível para aprovação e registrada no histórico do pedido.</span>
           </div>
        </div>

        <v-file-input
          v-model="artFile"
          label="Anexar arquivo (Imagem, PDF, Corel...)"
          accept="image/*,.pdf,.cdr,.ai,.zip,.rar"
          variant="outlined"
          prepend-inner-icon="mdi-paperclip"
          prepend-icon=""
          :bg-color="isLightMode ? 'white' : 'rgba(0,0,0,0.2)'"
          :rules="[fileRule]"
          density="comfortable"
          class="mb-3 font-weight-medium"
        ></v-file-input>

        <v-textarea
          v-model="comment"
          label="Observações / Link Externo (Opcional)"
          variant="outlined"
          rows="3"
          counter
          auto-grow
          :bg-color="isLightMode ? 'white' : 'rgba(0,0,0,0.2)'"
          density="comfortable"
          class="text-body-2"
        ></v-textarea>

        <v-expand-transition>
            <v-alert v-if="error" type="error" variant="tonal" class="mt-2 text-caption font-weight-bold border-radius-sm" closable @click:close="error = null">
              {{ error }}
            </v-alert>
        </v-expand-transition>
      </v-card-text>

      <div class="px-6 py-4 d-flex justify-end align-center gap-3 border-t" :class="isLightMode ? 'border-grey-lighten-2 bg-grey-lighten-5' : 'border-white-10 bg-black-20'">
        <v-btn variant="text" class="font-weight-bold btn-rect" :color="isLightMode ? 'grey-darken-2' : 'white-70'" @click="closeModal">Cancelar</v-btn>
        <v-btn
          color="primary"
          variant="flat"
          class="font-weight-black px-6 btn-rect shadow-soft"
          height="44"
          @click="submitFile"
          :loading="isUploading"
          :disabled="isFileSelected"
        >
          <v-icon start>mdi-send-check</v-icon>
          Finalizar Envio
        </v-btn>
      </div>
    </v-card>
  </v-dialog>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue';
import { supabase } from '@/api/supabase';
import { useUserStore } from '@/stores/user';
import { useThemeStore } from '@/stores/theme';

const props = defineProps({
  show: Boolean,
  order: Object as () => any | null,
  title: {
    type: String,
    default: 'Anexar Arquivo de Arte'
  }
});
const emit = defineEmits(['close', 'uploaded']);

const userStore = useUserStore();
const themeStore = useThemeStore();
const isLightMode = computed(() => themeStore.currentMode === 'light');

const isUploading = ref(false);
const artFile = ref<File[] | File | null>([]);
const comment = ref('');
const error = ref<string | null>(null);

const isFileSelected = computed(() => {
  if (Array.isArray(artFile.value)) {
    return artFile.value.length === 0;
  }
  return !artFile.value;
});

const fileRule = (value: File[] | File | undefined | null) => {
    if (!value || (Array.isArray(value) && value.length === 0)) return 'O anexo é obrigatório.';
    return true;
};

const closeModal = () => {
  artFile.value = [];
  comment.value = '';
  error.value = null;
  emit('close');
};

const submitFile = async () => {
  error.value = null;

  let fileToUpload: File | null = null;
  if (Array.isArray(artFile.value)) {
    fileToUpload = artFile.value[0] || null;
  } else if (artFile.value instanceof File) {
    fileToUpload = artFile.value;
  }

  if (!fileToUpload || !(fileToUpload instanceof File)) {
    error.value = "Nenhum arquivo válido selecionado. Por favor, anexe um arquivo.";
    return;
  }

  if (!props.order || !userStore.profile) {
    error.value = "Erro interno: dados do pedido ou do usuário estão faltando. Tente recarregar a página.";
    return;
  }

  isUploading.value = true;

  const newStatus = props.title.toLowerCase().includes('finaliza') ? 'finalizing' : 'customer_approval';
  const sanitizedFileName = fileToUpload.name.replace(/\s/g, '_');

  const timestamp = Date.now();
  const filePath = `${props.order.id}/${newStatus}/${timestamp}-${sanitizedFileName}`;

  try {
    const { error: uploadError } = await supabase.storage
        .from('arts')
        .upload(filePath, fileToUpload, { upsert: true });
    if (uploadError) throw uploadError;

    const { data: urlData } = supabase.storage.from('arts').getPublicUrl(filePath);

    let description = `Arquivo "${fileToUpload.name}" anexado.`;
    if (comment.value.trim()) {
        description += ` Comentário: "${comment.value.trim()}"`;
    }
    const { error: logError } = await supabase
      .from('order_logs')
      .insert({
        order_id: props.order.id,
        profile_id: userStore.profile.id,
        log_type: 'FILE_UPLOAD',
        description: description,
        metadata: { file_url: urlData.publicUrl }
      });
    if (logError) throw logError;

    emit('uploaded', urlData.publicUrl);
    closeModal();

  } catch (err: any) {
    console.error('Erro no upload de arquivo:', err);
    error.value = `Erro: ${err.message}`;
  } finally {
    isUploading.value = false;
  }
};
</script>

<style scoped>
.glassmorphism-card {
  backdrop-filter: blur(24px) saturate(120%) !important;
  background-color: rgba(25, 25, 30, 0.85) !important;
}
.bg-black-20 { background-color: rgba(0, 0, 0, 0.2); }
.border-white-10 { border-color: rgba(255, 255, 255, 0.1) !important; }
.text-white-80 { color: rgba(255, 255, 255, 0.8); }
.text-white-70 { color: rgba(255, 255, 255, 0.7); }
.bg-blue-darken-4-alpha { background-color: rgba(13, 71, 161, 0.15); }
.tracking-tight { letter-spacing: -0.3px; }
.lh-1-4 { line-height: 1.4; }
.btn-rect { border-radius: 6px; text-transform: none; }
.shadow-soft { box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15); }
.border-thin { border: 1px solid rgba(128, 128, 128, 0.2); }
.border-radius-sm { border-radius: 8px; }
</style>
