<template>
  <aside class="chat-sidebar-container d-flex flex-column h-100 bg-surface">

    <header class="sidebar-header d-flex align-center justify-space-between px-4">
      <h2 class="text-h6 font-weight-bold text-high-emphasis mb-0">Conversas</h2>
      <div class="header-actions">
        <v-btn icon="mdi-message-plus-outline" variant="text" color="primary" @click="$emit('open-new-chat-modal', 'contacts')"></v-btn>
      </div>
    </header>

    <div class="search-container px-4 py-2">
      <v-text-field
        v-model="search"
        placeholder="Pesquisar..."
        variant="solo-filled"
        flat
        density="compact"
        hide-details
        clearable
        prepend-inner-icon="mdi-magnify"
        class="search-input"
        rounded="pill"
      ></v-text-field>
    </div>

    <div class="channels-list-wrapper flex-grow-1" @scroll="closeAllSwipes">
      <div v-if="filteredChannels.length === 0" class="empty-state d-flex flex-column align-center justify-center h-100 pa-4 text-center">
        <v-icon size="48" class="text-disabled mb-2">mdi-message-text-outline</v-icon>
        <p class="text-medium-emphasis">Nenhuma conversa encontrada.</p>
      </div>

      <div
        v-for="channel in filteredChannels"
        :key="channel.id"
        class="swipe-container"
      >
        <div v-if="isMobile && touchState.activeId === channel.id" class="swipe-actions-bg d-flex">
          <div class="swipe-action-btn bg-info" @click.stop="handleActionAndClose('pin', channel)">
            <v-icon color="white">mdi-pin</v-icon>
            <span>Fixar</span>
          </div>
          <div class="swipe-action-btn bg-warning" @click.stop="openMuteModal(channel)">
            <v-icon color="white">{{ channel.is_muted ? 'mdi-bell-ring' : 'mdi-bell-off' }}</v-icon>
            <span>Silenciar</span>
          </div>
          <div class="swipe-action-btn bg-error" @click.stop="openDeleteModal(channel)">
            <v-icon color="white">mdi-delete</v-icon>
            <span>Apagar</span>
          </div>
        </div>

        <div
          class="channel-item"
          :class="{
            'is-swiping': touchState.activeId === channel.id && touchState.isDragging,
            'pinned': channel.is_pinned
          }"
          :style="{ transform: touchState.activeId === channel.id ? `translateX(${touchState.offset}px)` : 'translateX(0px)' }"
          @click="selectChannel(channel.id)"
          @touchstart="isMobile ? onTouchStart($event, channel.id) : null"
          @touchmove="isMobile ? onTouchMove($event, channel.id) : null"
          @touchend="isMobile ? onTouchEnd(channel.id) : null"
        >
          <div class="item-overlay" :class="{'active': channel.id === activeChannelId}"></div>

          <div class="item-avatar mr-3">
            <v-badge
              dot
              location="bottom right"
              offset-x="2"
              offset-y="2"
              :color="isUserOnline(channel) ? 'success' : 'grey-lighten-1'"
              :model-value="Boolean(channel.is_private_dm)"
            >
              <v-avatar size="52" :color="channel.is_private_dm ? 'primary' : 'blue-grey'" variant="tonal">
                <v-img v-if="channel.icon_image_url" :src="channel.icon_image_url" cover />
                <span v-else class="font-weight-bold text-white">{{ getChannelInitials(channel) }}</span>
              </v-avatar>
            </v-badge>
          </div>

          <div class="item-content flex-grow-1 overflow-hidden">
            <div class="d-flex align-center justify-space-between mb-1">
              <h4 class="channel-name text-truncate font-weight-bold text-high-emphasis mb-0 pr-2">
                {{ channel.name || 'Sem Nome' }}
              </h4>
              <span class="meta-time text-caption" :class="channel.unread_count > 0 ? 'text-whatsapp-green font-weight-bold' : 'text-medium-emphasis'">
                {{ formatTimestamp(channel.last_message_created_at) }}
              </span>
            </div>

            <div class="d-flex align-center justify-space-between">
              <p class="channel-preview text-truncate text-body-2 mb-0 d-flex align-center" :class="channel.unread_count > 0 ? 'text-high-emphasis font-weight-medium' : 'text-medium-emphasis'">
                <v-icon v-if="getPreviewIcon(channel.last_message_content)" size="16" class="mr-1 opacity-70">
                  {{ getPreviewIcon(channel.last_message_content) }}
                </v-icon>
                {{ getMessagePreviewText(channel.last_message_content) }}
              </p>

              <div class="meta-badges d-flex align-center flex-shrink-0 ml-2">
                <v-icon v-if="channel.is_muted" size="16" color="grey-lighten-1" class="mr-1">mdi-bell-off</v-icon>
                <v-icon v-if="channel.is_pinned" size="16" color="grey-lighten-1" class="mr-1">mdi-pin</v-icon>
                <div v-if="channel.unread_count > 0" class="unread-badge bg-whatsapp-green text-white font-weight-bold d-flex align-center justify-center">
                  {{ channel.unread_count }}
                </div>
              </div>
            </div>
          </div>

          <div v-if="!isMobile" class="item-actions-desktop">
            <v-menu location="bottom end">
              <template v-slot:activator="{ props }">
                <v-btn v-bind="props" icon="mdi-chevron-down" variant="text" size="small" class="bg-surface elevation-2" @click.stop></v-btn>
              </template>
              <v-list density="compact" class="bg-surface elevation-3 rounded-lg py-1">
                <v-list-item @click.stop="handleActionAndClose('pin', channel)" :prepend-icon="channel.is_pinned ? 'mdi-pin-off-outline' : 'mdi-pin-outline'">
                  <v-list-item-title>{{ channel.is_pinned ? 'Desafixar' : 'Fixar' }}</v-list-item-title>
                </v-list-item>
                <v-list-item @click.stop="openMuteModal(channel)" :prepend-icon="channel.is_muted ? 'mdi-bell-outline' : 'mdi-bell-off-outline'">
                  <v-list-item-title>{{ channel.is_muted ? 'Reativar som' : 'Silenciar' }}</v-list-item-title>
                </v-list-item>
                <v-divider class="my-1"></v-divider>
                <v-list-item @click.stop="openDeleteModal(channel)" prepend-icon="mdi-delete-outline" base-color="error">
                  <v-list-item-title>Apagar conversa</v-list-item-title>
                </v-list-item>
              </v-list>
            </v-menu>
          </div>
        </div>
      </div>
    </div>

    <v-dialog v-model="showMuteModal" max-width="380" z-index="9999999">
      <v-card class="rounded-xl bg-surface">
        <v-card-title class="text-h6 font-weight-bold pa-4 pb-2">Silenciar notificações</v-card-title>
        <v-card-text class="pa-4 pt-0">
          <p class="text-body-2 text-medium-emphasis mb-4">Outros participantes não verão que você silenciou esta conversa. Você ainda receberá notificações se for mencionado.</p>
          <v-radio-group v-model="muteDuration" color="primary" hide-details>
            <v-radio label="1 hora" value="1h" class="mb-2"></v-radio>
            <v-radio label="8 horas" value="8h" class="mb-2"></v-radio>
            <v-radio label="12 horas" value="12h" class="mb-2"></v-radio>
            <v-radio label="1 dia" value="1d" class="mb-2"></v-radio>
            <v-radio label="1 semana" value="1w" class="mb-2"></v-radio>
            <v-radio label="Sempre" value="always" class="mb-2"></v-radio>
          </v-radio-group>
        </v-card-text>
        <v-card-actions class="pa-4 pt-0 justify-end">
          <v-btn variant="text" color="medium-emphasis" @click="showMuteModal = false" class="text-none font-weight-bold">Cancelar</v-btn>
          <v-btn color="primary" variant="flat" rounded="pill" class="px-6 text-none font-weight-bold" @click="confirmMute">Silenciar</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <v-dialog v-model="showDeleteModal" max-width="420" persistent z-index="9999999">
      <v-card class="rounded-xl bg-surface overflow-hidden">
        <v-fade-transition leave-absolute>
          <div v-if="deleteStatus === 'success'" class="d-flex flex-column align-center justify-center pa-8 h-100 position-absolute bg-surface w-100" style="z-index: 10;">
            <v-avatar color="success" size="64" class="mb-4 elevation-2"><v-icon color="white" size="36">mdi-check</v-icon></v-avatar>
            <h3 class="text-h6 font-weight-bold text-success">Conversa Apagada</h3>
          </div>
          <div v-else-if="deleteStatus === 'loading'" class="d-flex flex-column align-center justify-center pa-8 h-100 position-absolute bg-surface w-100" style="z-index: 10;">
            <v-progress-circular indeterminate color="error" size="48" width="4"></v-progress-circular>
            <p class="mt-4 text-medium-emphasis font-weight-medium">Apagando histórico...</p>
          </div>
        </v-fade-transition>
        <div class="pa-6 text-center">
          <div class="d-flex justify-center mb-4"><div class="delete-icon-wrapper shake-animation"><v-icon color="error" size="40">mdi-delete-empty</v-icon></div></div>
          <h3 class="text-h5 font-weight-bold text-high-emphasis mb-2">Apagar esta conversa?</h3>
          <p class="text-body-2 text-medium-emphasis mb-4">As mensagens serão removidas deste dispositivo e o backup em nuvem associado a você será apagado.</p>
          <div class="bg-error-lighten-5 text-error pa-3 rounded-lg text-caption text-left d-flex align-start mb-6 border-error">
            <v-icon size="16" class="mr-2 mt-1">mdi-shield-alert-outline</v-icon>
            <span>Por questões de auditoria interna, uma cópia criptografada será mantida nos servidores para administradores.</span>
          </div>
          <div class="d-flex flex-column gap-2">
            <v-btn color="error" variant="flat" size="large" rounded="pill" class="font-weight-bold w-100 mb-3" @click="confirmDelete">Apagar Conversa</v-btn>
            <v-btn variant="text" size="large" color="medium-emphasis" class="font-weight-bold w-100" @click="showDeleteModal = false">Cancelar</v-btn>
          </div>
        </div>
      </v-card>
    </v-dialog>

    <Teleport to="body">
      <transition name="slide-down-fade">
        <div v-if="notification.show" class="whatsapp-toast-notification" @click="handleNotificationClick">
          <v-avatar size="48" class="toast-avatar elevation-2">
            <v-img v-if="notification.avatar" :src="notification.avatar" cover></v-img>
            <span v-else class="text-white font-weight-bold">{{ notification.title.substring(0, 2).toUpperCase() }}</span>
          </v-avatar>
          <div class="toast-content overflow-hidden flex-grow-1 ml-3">
            <h4 class="text-subtitle-2 font-weight-bold mb-0 text-truncate text-high-emphasis">{{ notification.title }}</h4>
            <p class="text-body-2 mb-0 text-truncate opacity-80 d-flex align-center">
              <v-icon v-if="getPreviewIcon(notification.content)" size="16" class="mr-1">
                {{ getPreviewIcon(notification.content) }}
              </v-icon>
              {{ getMessagePreviewText(notification.content) }}
            </p>
          </div>
          <div class="toast-actions ml-2">
            <v-btn icon="mdi-chevron-down" variant="text" size="small" class="opacity-60 hover-opacity-100" @click.stop="notification.show = false"></v-btn>
          </div>
        </div>
      </transition>
    </Teleport>

  </aside>
</template>

<script setup lang="ts">
import { ref, computed, reactive, onMounted, onUnmounted } from 'vue';
import { format, isToday, isYesterday, parseISO } from 'date-fns';
import { supabase } from '@/api/supabase'; // Importe do Supabase adicionado para o Listener Global
import { useOnlineStatusStore } from '@/stores/onlineStatus';
import { useChatStore } from '@/stores/chat';
import { useUserStore } from '@/stores/user';

const props = defineProps<{
  channels: any[];
  activeChannelId: number | null;
  isMobile: boolean;
  isChatActive: boolean;
}>();

const emit = defineEmits(['select-channel', 'open-new-chat-modal', 'channel-action']);

const search = ref('');
const onlineStatusStore = useOnlineStatusStore();
const chatStore = useChatStore();
const userStore = useUserStore();

// Estados dos Modais
const showMuteModal = ref(false);
const showDeleteModal = ref(false);
const channelToAct = ref<any>(null);
const muteDuration = ref('8h');
const deleteStatus = ref<'idle' | 'loading' | 'success'>('idle');

// Estado da Notificação Global
const notification = reactive({
  show: false,
  title: '',
  content: '',
  avatar: '',
  channelId: null as number | null
});
let toastTimeout: any = null;
let globalMessageListener: any = null;

// ==========================================
// LISTENER GLOBAL DE MENSAGENS E TOAST
// ==========================================
onMounted(() => {
  // Inscreve-se na tabela inteira de mensagens para atualizar o sidebar e disparar toasts
  globalMessageListener = supabase
    .channel('global-sidebar-messages')
    .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'messages' }, async (payload) => {
      const msg = payload.new;

      // Ignora mensagens enviadas por nós mesmos
      if (msg.profile_id === userStore.profile?.id) return;

      // Verifica se a mensagem pertence a um canal onde estamos
      const channelIndex = chatStore.channels.findIndex(c => c.id === msg.channel_id);
      if (channelIndex !== -1) {
        const channel = chatStore.channels[channelIndex];

        // Ignora se o canal estiver silenciado (Opcional)
        if (channel.is_muted) return;

        // Atualiza os dados locais do Sidebar
        channel.last_message_content = msg.content;
        channel.last_message_created_at = msg.created_at;

        // Se a mensagem não é do chat atualmente ativo, dispara as lógicas
        if (msg.channel_id !== props.activeChannelId) {
          channel.unread_count = (channel.unread_count || 0) + 1;

          // Busca dados de quem enviou para montar a notificação
          const { data: sender } = await supabase.from('profiles').select('full_name, avatar_url').eq('id', msg.profile_id).single();

          const title = channel.is_private_dm ? (sender?.full_name || 'Usuário') : `${sender?.full_name?.split(' ')[0] || 'Alguém'} em ${channel.name}`;
          const avatar = channel.is_private_dm ? (sender?.avatar_url || '') : channel.icon_image_url;

          // Exibe a Notificação Toast
          showNotification(title, msg.content, avatar, msg.channel_id);
        }

        // Reordena o Sidebar em tempo real (Mantendo Fixados no Topo)
        chatStore.channels.sort((a, b) => {
          if (a.is_pinned && !b.is_pinned) return -1;
          if (!a.is_pinned && b.is_pinned) return 1;
          return new Date(b.last_message_created_at).getTime() - new Date(a.last_message_created_at).getTime();
        });
      }
    })
    .subscribe();
});

onUnmounted(() => {
  if (globalMessageListener) {
    supabase.removeChannel(globalMessageListener);
  }
});

const showNotification = (title: string, content: string, avatar: string, channelId: number) => {
  notification.title = title;
  notification.content = content;
  notification.avatar = avatar;
  notification.channelId = channelId;
  notification.show = true;

  // Toca o som global (se estiver ativado na store)
  chatStore.playNotificationSound();

  clearTimeout(toastTimeout);
  toastTimeout = setTimeout(() => {
    notification.show = false;
  }, 4000); // Exibe por 4 segundos
};

const handleNotificationClick = () => {
  notification.show = false;
  if (notification.channelId) {
    selectChannel(notification.channelId);
  }
};

// ==========================================
// FILTROS E AÇÕES DE CLICK
// ==========================================
const filteredChannels = computed(() => {
    if (!search.value) return chatStore.channels || [];
    const term = search.value.toLowerCase();
    return chatStore.channels.filter(c => (c.name || '').toLowerCase().includes(term));
});

const selectChannel = (channelId: number) => {
  if (touchState.wasDragging) {
    touchState.wasDragging = false;
    return;
  }
  closeAllSwipes();
  emit('select-channel', channelId);
};

const handleChannelAction = (action: 'pin' | 'mute' | 'delete', channel: any) => {
    emit('channel-action', { action, channel });
};

const handleActionAndClose = (action: 'pin' | 'mute' | 'delete', channel: any) => {
  handleChannelAction(action, channel);
  closeAllSwipes();
};

const openMuteModal = (channel: any) => {
  channelToAct.value = channel;
  muteDuration.value = '8h';
  showMuteModal.value = true;
  closeAllSwipes();
};

const openDeleteModal = (channel: any) => {
  channelToAct.value = channel;
  deleteStatus.value = 'idle';
  showDeleteModal.value = true;
  closeAllSwipes();
};

const confirmMute = async () => {
  if (channelToAct.value && userStore.profile?.id) {
    await chatStore.toggleMuteChannel(channelToAct.value, userStore.profile.id);
  }
  showMuteModal.value = false;
  channelToAct.value = null;
};

const confirmDelete = async () => {
  if (!channelToAct.value || !userStore.profile?.id) return;
  deleteStatus.value = 'loading';
  const channelIdToDelete = channelToAct.value.id;
  const userId = userStore.profile.id;

  setTimeout(async () => {
    deleteStatus.value = 'success';
    await chatStore.deleteChannel(channelIdToDelete, userId);
    if (props.activeChannelId === channelIdToDelete) emit('select-channel', null);

    setTimeout(() => {
      showDeleteModal.value = false;
      channelToAct.value = null;
    }, 1200);
  }, 1000);
};

// ==========================================
// FORMATAÇÃO E RECONHECIMENTO VISUAL
// ==========================================
const getChannelInitials = (channel: any): string => {
  const name = channel.name || '?';
  const words = name.split(' ').filter(Boolean);
  if (words.length > 1) return `${words[0][0]}${words[1][0]}`.toUpperCase();
  return name.substring(0, 2).toUpperCase();
};

const isUserOnline = (channel: any): boolean => {
  if (!channel.is_private_dm || !channel.other_participant_id) return false;
  return onlineStatusStore.onlineUsers.some(p => p.user_id === channel.other_participant_id && p.status === 'online');
};

const formatTimestamp = (timestamp: string | null): string => {
  if (!timestamp) return '';
  try {
    const date = parseISO(timestamp);
    if (isToday(date)) return format(date, 'HH:mm');
    if (isYesterday(date)) return 'Ontem';
    return format(date, 'dd/MM/yy');
  } catch (error) {
    return '';
  }
};

const getMessagePreviewText = (content: string) => {
  if (!content) return 'Nenhuma mensagem';
  if (content === 'Mensagem excluída' || content === '[mensagem apagada]') return 'Mensagem apagada';
  if (content.startsWith('http') && content.includes('supabase.co')) {
    const url = content.toLowerCase();
    if (/\.(jpeg|jpg|gif|png|webp|bmp|svg)(\?.*)?$/.test(url)) return 'Foto';
    if (/\.(mp4|mov)(\?.*)?$/.test(url)) return 'Vídeo';
    if (/\.(mp3|wav|ogg|m4a|weba|webm|opus)(\?.*)?$/.test(url)) return 'Áudio';
    if (/\.(pdf|doc|docx|xls|xlsx|txt|csv|zip|rar)(\?.*)?$/.test(url)) return 'Documento';
    return 'Arquivo';
  }
  return content;
};

const getPreviewIcon = (content: string) => {
  if (!content) return null;
  if (content === 'Mensagem excluída' || content === '[mensagem apagada]') return 'mdi-cancel';
  if (content.startsWith('http') && content.includes('supabase.co')) {
    const url = content.toLowerCase();
    if (/\.(jpeg|jpg|gif|png|webp|bmp|svg)(\?.*)?$/.test(url)) return 'mdi-camera';
    if (/\.(mp4|mov)(\?.*)?$/.test(url)) return 'mdi-video';
    if (/\.(mp3|wav|ogg|m4a|weba|webm|opus)(\?.*)?$/.test(url)) return 'mdi-microphone';
    if (/\.(pdf|doc|docx|xls|xlsx|txt|csv|zip|rar)(\?.*)?$/.test(url)) return 'mdi-file-document-outline';
    return 'mdi-paperclip';
  }
  return null;
};

// ==========================================
// LÓGICA DE SWIPE BLINDADA (DESLIZAR NO MOBILE)
// ==========================================
const touchState = reactive({
  activeId: null as number | null,
  startX: 0,
  startY: 0,
  currentX: 0,
  offset: 0,
  isDragging: false,
  directionLocked: false,
  wasDragging: false
});

const MAX_SWIPE = -210;
const THRESHOLD = 10;

const onTouchStart = (e: TouchEvent, id: number) => {
  if (touchState.activeId !== null && touchState.activeId !== id) {
    closeAllSwipes();
    return;
  }
  touchState.activeId = id;
  touchState.startX = e.touches[0].clientX;
  touchState.startY = e.touches[0].clientY;
  touchState.currentX = touchState.startX;
  touchState.isDragging = false;
  touchState.directionLocked = false;
  touchState.wasDragging = false;
};

const onTouchMove = (e: TouchEvent, id: number) => {
  if (touchState.activeId !== id) return;
  const currentX = e.touches[0].clientX;
  const currentY = e.touches[0].clientY;
  const diffX = currentX - touchState.startX;
  const diffY = currentY - touchState.startY;

  if (!touchState.directionLocked) {
    if (Math.abs(diffY) > Math.abs(diffX) && Math.abs(diffY) > THRESHOLD) {
      touchState.activeId = null;
      return;
    }
    if (Math.abs(diffX) > Math.abs(diffY) && Math.abs(diffX) > THRESHOLD) {
      touchState.directionLocked = true;
      touchState.isDragging = true;
    }
    if (!touchState.directionLocked) return;
  }

  if (touchState.isDragging) {
    touchState.currentX = currentX;
    let diff = touchState.currentX - touchState.startX;
    if (touchState.offset === MAX_SWIPE && diff > 0) diff = MAX_SWIPE + diff;
    if (diff > 0) diff = 0;
    if (diff < MAX_SWIPE) diff = MAX_SWIPE;
    touchState.offset = diff;
    e.preventDefault();
  }
};

const onTouchEnd = (id: number) => {
  if (touchState.activeId !== id) return;
  if (touchState.isDragging) touchState.wasDragging = true;
  touchState.isDragging = false;
  touchState.directionLocked = false;

  if (touchState.offset < (MAX_SWIPE / 2.5)) {
    touchState.offset = MAX_SWIPE;
  } else {
    touchState.offset = 0;
    setTimeout(() => { if (!touchState.isDragging) touchState.activeId = null; }, 300);
  }

  setTimeout(() => { touchState.wasDragging = false; }, 100);
};

const getTransform = (id: number) => {
  if (touchState.activeId === id) return `translateX(${touchState.offset}px)`;
  return 'translateX(0px)';
};

const closeAllSwipes = () => {
  if (touchState.activeId !== null) {
    touchState.isDragging = false;
    touchState.offset = 0;
    setTimeout(() => { if (!touchState.isDragging) touchState.activeId = null; }, 300);
  }
  touchState.directionLocked = false;
};
</script>

<style lang="scss" scoped>
.chat-sidebar-container {
  width: 100%;
  height: 100%;
  border-right: 1px solid rgba(128, 128, 128, 0.15);
  overflow-x: hidden;
}

.sidebar-header {
  height: 60px;
  flex-shrink: 0;
}

.search-container {
  flex-shrink: 0;
  border-bottom: 1px solid rgba(128, 128, 128, 0.1);
}

.search-input {
  :deep(.v-field) {
    background-color: rgba(128, 128, 128, 0.08) !important;
  }
  :deep(.v-field__input) {
    min-height: 40px !important;
    padding-top: 8px;
    padding-bottom: 8px;
  }
}

.channels-list-wrapper {
  overflow-y: auto;
  overflow-x: hidden;
  &::-webkit-scrollbar { width: 6px; }
  &::-webkit-scrollbar-thumb { background-color: rgba(128, 128, 128, 0.3); border-radius: 4px; }
}

/* ========================================= */
/* ESTRUTURA DOS ITENS E SWIPE (MOBILE)      */
/* ========================================= */
.swipe-container {
  position: relative;
  width: 100%;
  overflow: hidden;
  isolation: isolate;
  z-index: 0;
}

.swipe-actions-bg {
  position: absolute;
  top: 0;
  right: 0;
  height: 100%;
  width: 210px; /* 70px x 3 botões */
  justify-content: flex-end;
  z-index: 1;
}

.swipe-action-btn {
  width: 70px;
  height: 100%;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  color: white;
  cursor: pointer;
  font-size: 0.7rem;
  font-weight: 500;

  v-icon { margin-bottom: 4px; }
}

/* O item da conversa */
.channel-item {
  position: relative;
  z-index: 2;
  background-color: rgb(var(--v-theme-surface));
  display: flex;
  flex-direction: row;
  align-items: center;
  padding: 12px 16px;
  cursor: pointer;
  transition: transform 0.3s cubic-bezier(0.2, 0.8, 0.2, 1);
  will-change: transform;
  touch-action: pan-y;

  &.is-swiping {
    transition: none !important;
  }

  &.pinned {
    background-image: linear-gradient(to right, transparent, rgba(128, 128, 128, 0.05));
  }

  &::after {
    content: '';
    position: absolute;
    bottom: 0;
    right: 0;
    width: calc(100% - 80px);
    height: 1px;
    background-color: rgba(128, 128, 128, 0.1);
  }

  &:hover .item-actions-desktop {
    opacity: 1;
    pointer-events: auto;
    transform: translateY(0);
  }

  &:hover .item-overlay {
    background-color: rgba(128, 128, 128, 0.06);
  }

  transform: translateZ(0);
}

.item-overlay {
  position: absolute;
  top: 0; left: 0; width: 100%; height: 100%;
  background-color: transparent;
  pointer-events: none;
  z-index: 1;
  transition: background-color 0.2s ease;

  &.active {
    background-color: rgba(var(--v-theme-primary), 0.1) !important;
  }
}

.item-avatar, .item-content, .item-actions-desktop {
  position: relative;
  z-index: 2;
}

.item-avatar { flex-shrink: 0; }
.item-content { display: flex; flex-direction: column; justify-content: center; min-width: 0; height: 100%; }
.channel-name { line-height: 1.2; font-size: 1.05rem; }
.channel-preview { line-height: 1.4; font-size: 0.9rem; }

/* ========================================= */
/* METADADOS E BADGES                        */
/* ========================================= */
.meta-time { font-size: 0.75rem; white-space: nowrap; }
.meta-badges { height: 20px; }

.text-whatsapp-green { color: #25D366 !important; }
.bg-whatsapp-green { background-color: #25D366 !important; }

.unread-badge {
  min-width: 20px;
  height: 20px;
  padding: 0 6px;
  border-radius: 10px;
  font-size: 0.7rem;
  line-height: 1;
}

/* ========================================= */
/* HOVER ACTIONS (DESKTOP)                   */
/* ========================================= */
.item-actions-desktop {
  position: absolute;
  right: 16px;
  top: 50%;
  margin-top: -14px;
  opacity: 0;
  pointer-events: none;
  transform: translateY(5px);
  transition: all 0.2s ease;
}

/* ========================================= */
/* ANIMAÇÕES DO MODAL DE EXCLUIR             */
/* ========================================= */
@keyframes shake {
  0%, 100% { transform: rotate(0deg); }
  20% { transform: rotate(-12deg); }
  40% { transform: rotate(12deg); }
  60% { transform: rotate(-12deg); }
  80% { transform: rotate(12deg); }
}

.shake-animation {
  animation: shake 0.6s ease-in-out infinite;
  transform-origin: bottom center;
}

.delete-icon-wrapper {
  width: 80px;
  height: 80px;
  border-radius: 50%;
  background-color: rgba(var(--v-theme-error), 0.1);
  display: flex;
  align-items: center;
  justify-content: center;
}

.bg-error-lighten-5 { background-color: rgba(var(--v-theme-error), 0.05); }
.border-error { border: 1px solid rgba(var(--v-theme-error), 0.2); }

/* ========================================= */
/* ESTILOS DO POPUP ESTILO WHATSAPP (TOAST)  */
/* ========================================= */
.whatsapp-toast-notification {
  position: fixed;
  top: 24px;
  left: 50%;
  transform: translateX(-50%);
  z-index: 9999999;
  width: 90%;
  max-width: 380px;
  border-radius: 100px; /* Bordas bem arredondadas estilo iOS */
  padding: 10px 16px;
  display: flex;
  align-items: center;
  cursor: pointer;
  box-shadow: 0 10px 40px rgba(0,0,0,0.12);

  /* Light Mode Glassmorphism */
  background: rgba(255, 255, 255, 0.85);
  backdrop-filter: blur(16px);
  -webkit-backdrop-filter: blur(16px);
  border: 1px solid rgba(255, 255, 255, 0.6);

  transition: all 0.3s cubic-bezier(0.175, 0.885, 0.32, 1.2);

  &:hover {
    transform: translateX(-50%) translateY(-2px);
    box-shadow: 0 15px 45px rgba(0,0,0,0.15);
  }

  /* Adaptação automática e impecável para o Dark Mode */
  @media (prefers-color-scheme: dark) {
    background: rgba(30, 41, 59, 0.85);
    border: 1px solid rgba(255, 255, 255, 0.1);
    box-shadow: 0 10px 40px rgba(0,0,0,0.4);

    .text-high-emphasis { color: #ffffff !important; }
    .opacity-80 { color: rgba(255, 255, 255, 0.8); }
    .opacity-60 { color: rgba(255, 255, 255, 0.6); }
  }
}

.toast-avatar { border: 2px solid rgba(128, 128, 128, 0.1); }
.hover-opacity-100:hover { opacity: 1 !important; }

/* Animações de Entrada e Saída (Fade-Slide) */
.slide-down-fade-enter-active {
  transition: all 0.4s cubic-bezier(0.175, 0.885, 0.32, 1.2);
}
.slide-down-fade-leave-active {
  transition: all 0.3s ease-in;
}
.slide-down-fade-enter-from,
.slide-down-fade-leave-to {
  transform: translateX(-50%) translateY(-40px);
  opacity: 0;
}
</style>
