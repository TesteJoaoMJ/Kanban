<template>
  <v-dialog
    v-model="internalShow"
    fullscreen
    transition="dialog-bottom-transition"
    style="z-index: 9999999;"
  >
    <v-card class="bg-background d-flex flex-column h-100">

      <v-toolbar color="surface" elevation="1" density="comfortable" class="flex-shrink-0">
        <v-btn icon="mdi-arrow-left" variant="text" @click="internalShow = false"></v-btn>
        <v-toolbar-title class="font-weight-bold text-subtitle-1">
          Mídia, links e docs
        </v-toolbar-title>
        <template v-slot:extension>
          <v-tabs v-model="tab" color="primary" align-tabs="center" class="w-100" bg-color="surface">
            <v-tab value="media" class="flex-grow-1 font-weight-bold">Mídia</v-tab>
            <v-tab value="docs" class="flex-grow-1 font-weight-bold">Docs</v-tab>
            <v-tab value="links" class="flex-grow-1 font-weight-bold">Links</v-tab>
          </v-tabs>
        </template>
      </v-toolbar>

      <v-card-text class="pa-0 flex-grow-1 overflow-y-auto bg-background position-relative">

        <div v-if="loading" class="d-flex justify-center align-center h-100">
          <v-progress-circular indeterminate color="primary"></v-progress-circular>
        </div>

        <v-window v-else v-model="tab" class="h-100">

          <v-window-item value="media" class="h-100 pa-1">
            <div v-if="mediaItems.length === 0" class="empty-state">
              <v-icon size="64" color="grey-lighten-1">mdi-image-off-outline</v-icon>
              <p class="mt-4 text-medium-emphasis">Nenhuma mídia encontrada nesta conversa.</p>
            </div>
            <v-row v-else dense>
              <v-col v-for="item in mediaItems" :key="item.id" cols="4" sm="3" md="2" class="pa-1">
                <v-card flat class="media-card rounded-0 cursor-pointer" @click="openMedia(item)">
                  <v-img v-if="item.message_type === 'image'" :src="item.content" aspect-ratio="1" cover class="bg-grey-lighten-2">
                    <template v-slot:placeholder>
                      <div class="d-flex align-center justify-center fill-height">
                        <v-progress-circular indeterminate color="grey-lighten-1"></v-progress-circular>
                      </div>
                    </template>
                  </v-img>
                  <div v-else-if="item.message_type === 'video'" class="video-preview position-relative bg-black w-100 h-100 d-flex align-center justify-center">
                     <v-icon color="white" size="32">mdi-play-circle-outline</v-icon>
                  </div>
                </v-card>
              </v-col>
            </v-row>
          </v-window-item>

          <v-window-item value="docs" class="h-100">
            <div v-if="docItems.length === 0" class="empty-state">
              <v-icon size="64" color="grey-lighten-1">mdi-file-document-remove-outline</v-icon>
              <p class="mt-4 text-medium-emphasis">Nenhum documento encontrado nesta conversa.</p>
            </div>
            <v-list v-else bg-color="transparent" lines="two">
              <v-list-item v-for="item in docItems" :key="item.id" class="border-bottom" @click="downloadFile(item.content)">
                <template v-slot:prepend>
                  <v-avatar color="error" variant="tonal" rounded size="48" class="mr-3">
                    <v-icon size="28">mdi-file-pdf-box</v-icon>
                  </v-avatar>
                </template>
                <v-list-item-title class="font-weight-medium text-truncate">{{ extractFileName(item.content) }}</v-list-item-title>
                <v-list-item-subtitle class="text-caption mt-1">{{ formatDate(item.created_at) }} • Arquivo</v-list-item-subtitle>
              </v-list-item>
            </v-list>
          </v-window-item>

          <v-window-item value="links" class="h-100">
            <div v-if="linkItems.length === 0" class="empty-state">
              <v-icon size="64" color="grey-lighten-1">mdi-link-variant-off</v-icon>
              <p class="mt-4 text-medium-emphasis">Nenhum link compartilhado nesta conversa.</p>
            </div>
            <v-list v-else bg-color="transparent" lines="two">
              <v-list-item v-for="item in linkItems" :key="item.id" class="border-bottom px-4 py-3" @click="openLink(extractLink(item.content))">
                <template v-slot:prepend>
                  <v-avatar color="primary" variant="tonal" rounded size="48" class="mr-3">
                    <v-icon size="24">mdi-link-variant</v-icon>
                  </v-avatar>
                </template>
                <v-list-item-title class="font-weight-medium text-primary text-decoration-underline">{{ extractLink(item.content) }}</v-list-item-title>
                <v-list-item-subtitle class="text-caption mt-1 text-truncate">{{ item.content }}</v-list-item-subtitle>
              </v-list-item>
            </v-list>
          </v-window-item>

        </v-window>
      </v-card-text>
    </v-card>
  </v-dialog>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue';
import { supabase } from '@/api/supabase';

const props = defineProps<{
  show: boolean;
  channel: any;
  onlineUsers?: any[];
}>();

const emit = defineEmits(['update:show']);

const internalShow = computed({
  get: () => props.show,
  set: (val) => emit('update:show', val)
});

const tab = ref('media');
const loading = ref(false);
const allMessages = ref<any[]>([]);

// Filtros baseados no message_type ou no conteúdo da mensagem
const mediaItems = computed(() => allMessages.value.filter(m => m.message_type === 'image' || m.message_type === 'video'));
const docItems = computed(() => allMessages.value.filter(m => m.message_type === 'file' || m.message_type === 'document'));
const linkItems = computed(() => allMessages.value.filter(m => m.message_type === 'text' && m.content && m.content.includes('http')));

// Função para buscar todas as mensagens do canal no momento em que a tela abre
const fetchMediaMessages = async () => {
  if (!props.channel?.id || !internalShow.value) return;
  loading.value = true;

  const { data, error } = await supabase
    .from('messages')
    .select('*')
    .eq('channel_id', props.channel.id)
    .eq('is_deleted', false)
    .order('created_at', { ascending: false });

  if (!error && data) {
    allMessages.value = data;
  } else {
    console.error('Erro ao buscar mídias/arquivos do canal:', error);
  }
  loading.value = false;
};

// Sempre que o modal for aberto, garante que ele resete para a tab de mídia e faça a busca limpa
watch(internalShow, (newVal) => {
  if (newVal) {
    tab.value = 'media';
    fetchMediaMessages();
  }
});

// Funções utilitárias
const formatDate = (dateString: string) => {
  const date = new Date(dateString);
  return date.toLocaleDateString('pt-BR');
};

const extractFileName = (url: string) => {
  try {
    const parts = url.split('/');
    let name = parts[parts.length - 1];
    name = decodeURIComponent(name); // Remove %20 e formata bonitinho
    // Tenta remover o timestamp colocado no backend se existir
    return name.includes('_') ? name.split('_').slice(1).join('_') : name;
  } catch (e) {
    return 'Documento';
  }
};

const extractLink = (text: string) => {
  if (!text) return '';
  const match = text.match(/(https?:\/\/[^\s]+)/g);
  return match ? match[0] : text;
};

// Ações de clique
const openMedia = (item: any) => {
  window.open(item.content, '_blank');
};

const downloadFile = (url: string) => {
  window.open(url, '_blank');
};

const openLink = (url: string) => {
  window.open(url, '_blank');
};
</script>

<style scoped>
.empty-state {
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  height: 100%;
  padding: 2rem;
  text-align: center;
}

.media-card {
  transition: transform 0.2s, opacity 0.2s;
  aspect-ratio: 1;
  overflow: hidden;
}

.media-card:hover {
  transform: scale(0.98);
  opacity: 0.9;
}

.video-preview {
  aspect-ratio: 1;
}

.border-bottom {
  border-bottom: 1px solid rgba(128, 128, 128, 0.08);
}
</style>
