<template>
  <div v-if="isVisible" class="chat-widget-wrapper">

    <v-scale-transition>
      <v-btn v-if="!isOpen" class="chat-fab glass-fab" icon size="x-large" @click="openChat()">
        <v-badge
          :content="chatStore.totalUnreadCount"
          :model-value="chatStore.totalUnreadCount > 0"
          color="error"
          floating
          offset-x="4"
          offset-y="4"
          class="super-badge pulse-badge"
          max="99"
        >
          <div class="fab-icon-wrapper d-flex align-center justify-center">
             <v-icon size="32" color="white">{{ chatStore.totalUnreadCount > 0 ? 'mdi-forum' : 'mdi-forum-outline' }}</v-icon>
          </div>
        </v-badge>
      </v-btn>
    </v-scale-transition>

    <div v-if="isOpen" class="chat-open-layout">

      <v-slide-x-transition>
<div class="chat-heads-sidebar left-sidebar custom-scrollbar-hidden">
  <transition-group name="bubble-list" tag="div" class="d-flex flex-column gap-3 w-100 h-100 justify-start align-center pb-4">
    <v-tooltip
      v-for="channel in activeChannelsList"
      :key="channel.id"
      location="left"
      :text="channel.name"
    >
      <template v-slot:activator="{ props }">
        <div
          v-bind="props"
          class="floating-bubble"
          :class="{ 'bubble-active': chatStore.activeChannel?.id === channel.id }"
          @click="switchChannel(channel.id)"
        >
          <v-badge
            :content="channel.unread_count"
            color="error"
            floating
            offset-x="8"
            offset-y="8"
            class="strict-badge"
            :model-value="(channel.unread_count || 0) > 0"
          >
            <v-avatar :image="channel.icon_image_url || 'https://ui-avatars.com/api/?name=C'" size="46" class="elevation-4 border-2" :class="chatStore.activeChannel?.id === channel.id ? 'border-primary' : 'border-surface'"></v-avatar>
          </v-badge>
        </div>
      </template>
    </v-tooltip>
  </transition-group>
</div>
      </v-slide-x-transition>

      <v-slide-y-reverse-transition appear>
        <v-card
          class="chat-window glassmorphism-card-dialog"
          :class="{'neon-unread-border': isUnreadNeonMode}"
        >

          <div class="chat-wallpaper" :style="{ backgroundImage: `url(${currentWallpaper})` }"></div>
          <div v-if="isWallpaperBlurEnabled" class="chat-wallpaper-blur"></div>

          <v-toolbar color="transparent" density="compact" class="border-b border-opacity-10 header-3d position-relative z-index-2">
            <div class="d-flex align-center cursor-pointer ml-2 w-100" id="universal-users-activator">

              <div v-if="chatStore.activeChannel">
                <div v-if="isPrivateDM" class="position-relative">
                    <v-avatar size="36" class="elevation-3" :image="currentChannelAvatar"></v-avatar>
                </div>
                <div v-else class="group-avatars-stack d-flex align-center">
                  <v-avatar
                    v-for="(member, idx) in groupMembers.slice(0, 3)"
                    :key="member.id"
                    size="32"
                    class="elevation-3 overlapping-avatar border-1 border-surface"
                    :style="{ zIndex: 10 - idx }"
                    :image="member.avatar_url || `https://ui-avatars.com/api/?name=${encodeURIComponent(member.full_name || 'U')}`"
                  ></v-avatar>
                  <v-avatar v-if="groupMembers.length > 3" size="32" color="surface-variant" class="elevation-3 overlapping-avatar border-1 border-surface text-caption font-weight-bold">
                    +{{ groupMembers.length - 3 }}
                  </v-avatar>
                </div>
              </div>
              <v-avatar v-else size="36" color="primary" class="elevation-3">
                <v-icon>mdi-account-search</v-icon>
              </v-avatar>

              <div class="d-flex flex-column ml-3 flex-grow-1 overflow-hidden">
                 <div class="d-flex align-center gap-2">
                   <span class="font-weight-black text-truncate text-subtitle-2 shadow-text" style="line-height: 1.2;">
                     {{ chatStore.activeChannel ? chatStore.activeChannel.name : 'Nova Conversa' }}
                   </span>
                   <v-badge
                     v-if="chatStore.activeChannel && isPrivateDM"
                     dot
                     inline
                     :color="currentChatStatusColor"
                     class="status-dot-inline mt-1"
                   ></v-badge>
                   <v-icon size="16" class="opacity-60 ml-auto mr-2">mdi-chevron-down</v-icon>
                 </div>

                 <span class="text-[10px] opacity-80 text-truncate font-weight-medium text-uppercase mt-n1">
                   <template v-if="!chatStore.activeChannel">Selecione para iniciar</template>
                   <template v-else-if="isPrivateDM">{{ activeUserRoleName || 'Membro' }}</template>
                   <template v-else>{{ groupMembers.length }} membros</template>
                 </span>
              </div>
            </div>

            <v-menu activator="#universal-users-activator" location="bottom start" offset="8" :close-on-content-click="true" width="340">
              <v-card class="glassmorphism-card-dialog border-thin mt-1 dropdown-3d" elevation="24" max-height="500">
                <div class="pa-2 border-b border-opacity-10 bg-black-20 backdrop-blur">
                   <v-text-field
                     v-model="userSearchQuery"
                     placeholder="Buscar usuário..."
                     density="compact"
                     variant="solo-filled"
                     flat
                     hide-details
                     prepend-inner-icon="mdi-magnify"
                     class="search-input-mini"
                     rounded="lg"
                     @click.stop
                   ></v-text-field>
                </div>
                <v-list density="compact" bg-color="transparent" class="py-0 custom-scrollbar-menu" max-height="400">
                  <v-list-item
                    v-for="user in filteredAllUsers"
                    :key="user.id"
                    @click="startChatWithUser(user)"
                    class="border-b border-opacity-10 py-2 chat-dropdown-item"
                  >
                    <template v-slot:prepend>
                      <v-badge dot location="bottom right" :color="isUserOnline(user.id) ? 'success' : 'transparent'">
                        <v-avatar size="40" class="elevation-2" :image="user.avatar_url || `https://ui-avatars.com/api/?name=${encodeURIComponent(user.full_name || 'U')}`"></v-avatar>
                      </v-badge>
                    </template>
                    <v-list-item-title class="font-weight-bold text-body-2">{{ user.full_name || user.username || 'Usuário' }}</v-list-item-title>
                    <v-list-item-subtitle class="text-caption opacity-70">
                       {{ getRoleName(user) }}
                    </v-list-item-subtitle>
                  </v-list-item>

                  <div v-if="filteredAllUsers.length === 0" class="pa-4 text-center opacity-60 text-caption">
                    Nenhum usuário encontrado.
                  </div>
                </v-list>
              </v-card>
            </v-menu>

            <v-menu :close-on-content-click="false" location="bottom end" offset="12">
              <template v-slot:activator="{ props }">
                <v-btn icon="mdi-palette-outline" variant="text" size="small" v-bind="props" class="opacity-80 hover-opacity-100 mr-1"></v-btn>
              </template>
              <v-card width="320" class="glassmorphism-card-dialog border-thin pa-5">
                <div class="d-flex align-center mb-4 border-b border-opacity-10 pb-3">
                   <v-icon color="primary" size="28" class="mr-3">mdi-wallpaper</v-icon>
                   <div>
                      <div class="text-subtitle-2 font-weight-bold">Aparência do Chat</div>
                      <div class="text-caption opacity-70" style="line-height: 1.2;">Personalize o fundo da sua conversa</div>
                   </div>
                </div>

                <div class="text-caption font-weight-bold text-uppercase mb-3 opacity-80">Fundos Padrão</div>

                <div class="d-flex flex-wrap gap-3 mb-4">
                  <div
                    v-for="(bg, index) in defaultWallpapers"
                    :key="index"
                    class="wallpaper-thumb cursor-pointer elevation-2"
                    :class="{'active-wallpaper': currentWallpaper === bg}"
                    :style="{ backgroundImage: `url(${bg})` }"
                    @click="currentWallpaper = bg"
                  >
                     <div v-if="currentWallpaper === bg" class="active-indicator">
                        <v-icon size="16" color="white">mdi-check</v-icon>
                     </div>
                  </div>
                </div>

                <div class="text-caption font-weight-bold text-uppercase mb-2 opacity-80 mt-2">Personalizado</div>
                <v-btn block variant="flat" color="transparent" class="mb-4 text-none custom-upload-btn" @click="triggerCustomWallpaper" height="44">
                   <v-icon start color="primary">mdi-cloud-upload-outline</v-icon>
                   <span class="text-primary font-weight-bold">Fazer upload de imagem</span>
                </v-btn>
                <input type="file" ref="customWallpaperInput" @change="handleCustomWallpaperUpload" accept="image/*" style="display: none" />

                <v-divider class="my-3 border-opacity-10"></v-divider>

                <div class="d-flex align-center justify-space-between mt-2">
                   <div>
                      <div class="text-body-2 font-weight-bold">Desfoque Transparente</div>
                      <div class="text-caption opacity-70" style="font-size: 0.7rem !important;">Melhora a leitura sob as mensagens</div>
                   </div>
                   <v-switch
                     v-model="isWallpaperBlurEnabled"
                     color="primary"
                     hide-details
                     density="compact"
                     inset
                   ></v-switch>
                </div>
              </v-card>
            </v-menu>

            <v-btn icon="mdi-open-in-new" variant="text" size="small" :to="{ name: 'Chat' }" @click.stop="closeChat"></v-btn>
            <v-btn icon="mdi-close" variant="text" size="small" class="mr-1" @click.stop="closeChat"></v-btn>
          </v-toolbar>

          <v-card-text ref="messagesContainer" class="messages-area position-relative z-index-2 flex-grow-1" @scroll="handleScroll" @click="handleChatInteraction">

            <div v-if="!chatStore.activeChannel" class="h-100 d-flex flex-column align-center justify-center opacity-70 text-center px-4">
               <v-avatar size="80" color="surface-variant" class="mb-4 elevation-4">
                  <v-icon size="40">mdi-forum</v-icon>
               </v-avatar>
               <span class="text-body-1 font-weight-black">Nenhuma conversa ativa</span>
               <span class="text-caption mt-1">Clique no título acima para listar os contatos.</span>
            </div>

            <div v-else-if="isLoadingMore" class="d-flex justify-center pa-4 mb-2">
              <v-progress-circular indeterminate color="primary" size="24"></v-progress-circular>
            </div>

            <template v-for="(group, index) in filteredGroupedMessages" :key="index">
              <div class="date-divider"><span>{{ group.date }}</span></div>
              <ChatMessage
                v-for="(message, msgIndex) in group.messages"
                :key="message.id"
                :message="message"
                :is-consecutive="isConsecutiveMessage(message, msgIndex, group.messages)"
                :search-query="''"
                :is-group="!activeChannel?.is_private_dm"
                :all-users="allUsers"
                @show-menu="onShowMenu"
                @view-media="handleViewMedia"
                @reply="handleSwipeReply"
                @scroll-to="scrollToMessage"
                @info="openMessageInfo"
              />
            </template>
          </v-card-text>

          <v-scale-transition>
            <v-btn v-if="showScrollToBottom" class="scroll-bottom-btn" icon="mdi-chevron-down" color="surface" elevation="6" size="small" @click.stop="forceScrollToBottom"></v-btn>
          </v-scale-transition>

          <div class="input-area position-relative z-index-2">

            <div class="preview-area reply-preview" v-if="replyingToMessage">
              <div class="d-flex align-center w-100 overflow-hidden">
                <div v-if="replyingToMessage.message_type === 'image' || replyingToMessage.message_type === 'video'" class="reply-preview-thumb mr-3">
                  <img :src="replyingToMessage.content" class="h-100 w-100" style="object-fit: cover; border-radius: 4px;" />
                </div>
                <div v-else-if="replyingToMessage.message_type === 'audio'" class="reply-preview-thumb bg-primary-lighten-4 d-flex align-center justify-center mr-3 rounded">
                   <v-icon color="primary" size="20">mdi-microphone</v-icon>
                </div>
                <div v-else-if="replyingToMessage.message_type === 'file' || replyingToMessage.message_type === 'document'" class="reply-preview-thumb bg-grey-lighten-2 d-flex align-center justify-center mr-3 rounded">
                   <v-icon color="grey-darken-2" size="20">mdi-file-document</v-icon>
                </div>
                <div class="preview-content flex-grow-1 overflow-hidden">
                  <div class="d-flex align-center mb-1">
                    <v-icon size="small" color="primary">mdi-reply</v-icon>
                    <strong class="ml-1 text-primary text-caption">Respondendo a {{ replyingToMessage.profile?.full_name || 'Usuário' }}</strong>
                  </div>
                  <p class="text-caption text-truncate mb-0 text-medium-emphasis">
                     {{ (!replyingToMessage.message_type || replyingToMessage.message_type === 'text') ? replyingToMessage.content : 'Mídia' }}
                  </p>
                </div>
              </div>
              <v-btn icon="mdi-close" variant="text" size="small" @click.stop="cancelReply" class="ml-2"></v-btn>
            </div>

            <div class="preview-area edit-preview" v-if="editingMessage">
              <div class="preview-content">
                <v-icon size="small" color="warning">mdi-pencil</v-icon>
                <strong class="ml-2 text-warning">Editando mensagem</strong>
                <p class="text-caption text-truncate mb-0 text-medium-emphasis">{{ editingMessage.content }}</p>
              </div>
              <v-btn icon="mdi-close" variant="text" size="small" @click.stop="cancelEdit"></v-btn>
            </div>

            <div class="input-controls d-flex align-center w-100">
              <input type="file" ref="fileInputDesktop" @change="handleFileUpload" multiple style="display: none" />

              <template v-if="!isRecording">
                <v-menu v-model="showEmojiPicker" :close-on-content-click="false" location="top start" offset="10">
                  <template v-slot:activator="{ props }">
                    <v-btn v-bind="props" icon="mdi-emoticon-outline" variant="text" class="text-medium-emphasis mr-1"></v-btn>
                  </template>
                  <v-card width="280" class="pa-2 glassmorphism-card-dialog border-thin">
                     <div class="d-flex flex-wrap justify-center gap-1">
                        <v-btn v-for="emoji in emojisList" :key="emoji" size="small" variant="text" @click.stop="insertEmoji(emoji)" class="emoji-btn">{{ emoji }}</v-btn>
                     </div>
                  </v-card>
                </v-menu>

                <v-btn icon="mdi-paperclip" variant="text" class="text-medium-emphasis mr-2" @click.stop="triggerFileInput"></v-btn>

                <div class="input-field-wrapper flex-grow-1">
                  <v-text-field
                    v-model="newMessage"
                    @keydown.enter.prevent="handleSend"
                    @focus="handleChatInteraction"
                    @click="handleChatInteraction"
                    variant="solo"
                    flat
                    placeholder="Digite uma mensagem"
                    hide-details
                    density="compact"
                    class="chat-text-field"
                    :disabled="!chatStore.activeChannel || isSending || isUploading"
                  ></v-text-field>
                </div>
              </template>

              <template v-else>
                <div class="recording-ui d-flex align-center flex-grow-1 py-1 px-3 rounded-pill mr-2">
                  <v-btn icon="mdi-delete" variant="text" color="grey-darken-1" size="small" class="mr-2" @click.stop="cancelRecording"></v-btn>

                  <div class="mic-pulse-wrapper d-flex align-center mr-3">
                    <v-icon color="error" class="pulse-anim mr-2" size="20">mdi-microphone</v-icon>
                    <span class="text-error font-weight-medium text-body-2">{{ recordingTime }}</span>
                  </div>

                  <div class="live-waveform-container flex-grow-1 position-relative">
                    <div class="waveform-layer d-flex align-center justify-end w-100 h-100">
                      <div class="wave-bar" v-for="(h, i) in recordingWaves" :key="i" :style="{ height: Math.min(h, 100) + '%' }"></div>
                    </div>
                  </div>
                </div>
              </template>

              <div class="action-buttons ml-2">
                <v-btn v-if="!newMessage.trim() && !isRecording" icon="mdi-microphone" variant="text" class="text-medium-emphasis" :disabled="!chatStore.activeChannel" @click.stop="startRecording"></v-btn>
                <v-btn v-else-if="isRecording" icon="mdi-send" color="success" variant="flat" elevation="2" class="pulse-send-btn" @click.stop="stopRecordingAndSend"></v-btn>
                <v-btn v-else icon="mdi-send" color="primary" variant="flat" elevation="2" :loading="isSending" @click.stop="handleSend"></v-btn>
              </div>
            </div>
          </div>
        </v-card>
      </v-slide-y-reverse-transition>

    </div>

    <MessageMenu
      :show="menu.show"
      :x="menu.x"
      :y="menu.y"
      :is-my-message="menu.isMyMessage"
      @update:show="menu.show = $event"
      @action="handleMenuAction"
    />

    <ForwardMessageModal
      v-model="showForwardModal"
      :message="forwardingMessage"
      :channels="chatStore.channels"
      @forward="executeForward"
    />

    <ImageModal
      :show="showMediaModal"
      :image-url="mediaModalUrl"
      :file-name="mediaModalFileName"
      @close="showMediaModal = false"
      @forward="handleMediaForward"
    />

    <v-dialog v-model="showInfoModal" max-width="400" content-class="chat-info-dialog">
      <v-card class="glassmorphism-card-dialog border-thin">
        <v-toolbar color="transparent" density="compact" class="border-b border-opacity-10 header-3d">
          <v-toolbar-title class="text-subtitle-1 font-weight-black">Dados da Mensagem</v-toolbar-title>
          <v-spacer></v-spacer>
          <v-btn icon="mdi-close" variant="text" size="small" @click="showInfoModal = false"></v-btn>
        </v-toolbar>

        <v-card-text class="pa-4 custom-scrollbar">
          <div v-if="infoMessage" class="d-flex flex-column gap-3">
             <div class="message-preview p-3 bg-surface-variant rounded-lg mb-3 px-3 py-2 border border-opacity-10">
                <span class="text-body-2 font-italic opacity-80">
                  "{{ infoMessage.content?.substring(0, 100) }}{{ infoMessage.content?.length > 100 ? '...' : '' }}"
                </span>
             </div>

             <div class="d-flex align-center justify-space-between border-b border-opacity-10 pb-2">
                <div class="d-flex align-center">
                   <v-icon size="20" class="mr-2 opacity-60">mdi-check</v-icon>
                   <span class="text-body-2 font-weight-bold">Enviada</span>
                </div>
                <span class="text-caption opacity-80">{{ formatDateTime(infoMessage.created_at) }}</span>
             </div>

             <div class="d-flex flex-column pt-2">
                <div class="d-flex align-center mb-2">
                   <v-icon size="20" color="info" class="mr-2 text-blue">mdi-check-all</v-icon>
                   <span class="text-body-2 font-weight-bold">Lida por</span>
                </div>

                <div v-if="getReaders(infoMessage).length === 0" class="text-caption opacity-60 ml-8 mb-2">
                   Ninguém visualizou ainda.
                </div>

                <v-list v-else density="compact" bg-color="transparent" class="py-0 ml-6">
                   <v-list-item v-for="reader in getReaders(infoMessage)" :key="reader.id" class="px-0 min-h-0 mb-1">
                      <template v-slot:prepend>
                         <v-avatar size="24" class="elevation-1 mr-3" :image="reader.avatar_url || `https://ui-avatars.com/api/?name=${encodeURIComponent(reader.full_name || 'U')}`"></v-avatar>
                      </template>
                      <v-list-item-title class="text-body-2 font-weight-medium">{{ reader.full_name }}</v-list-item-title>
                   </v-list-item>
                </v-list>
             </div>
          </div>
        </v-card-text>
      </v-card>
    </v-dialog>

  </div>
</template>

<script setup lang="ts">
import { ref, watch, nextTick, computed, onMounted, onUnmounted, reactive } from 'vue';
import { useRoute } from 'vue-router';
import { useUserStore } from '@/stores/user';
import { useChatStore } from '@/stores/chat';
import { useOnlineStatusStore } from '@/stores/onlineStatus';
import { useThemeStore } from '@/stores/theme';
import { supabase } from '@/api/supabase';
import { isToday, isYesterday, format, parseISO, differenceInMinutes } from 'date-fns';
import { ptBR } from 'date-fns/locale';

import ChatMessage from './chat/ChatMessage.vue';
import MessageMenu from './chat/MessageMenu.vue';
import ForwardMessageModal from './chat/ForwardMessageModal.vue';
import ImageModal from '@/components/ImageModal.vue';

// Importação nativa das imagens padrão do Wallpaper
import img1 from '@/assets/1.jpg';
import img2 from '@/assets/2.jpg';
import img3 from '@/assets/3.jpg';
import img4 from '@/assets/4.jpg';
import img5 from '@/assets/5.jpg';

const defaultWallpapers = [img1, img2, img3, img4, img5];
const currentWallpaper = ref(defaultWallpapers[0]);
const isWallpaperBlurEnabled = ref(true);

const customWallpaperInput = ref<HTMLInputElement | null>(null);

const triggerCustomWallpaper = () => {
    customWallpaperInput.value?.click();
};

const handleCustomWallpaperUpload = (event: Event) => {
    const target = event.target as HTMLInputElement;
    if (target.files && target.files.length > 0) {
        const file = target.files[0];
        const reader = new FileReader();
        reader.onload = (e) => {
            if (e.target?.result) {
                currentWallpaper.value = e.target.result as string;
            }
        };
        reader.readAsDataURL(file);
    }
    // Reseta o input para permitir upload da mesma imagem se necessário
    if (customWallpaperInput.value) customWallpaperInput.value.value = '';
};

const userStore = useUserStore();
const chatStore = useChatStore();
const themeStore = useThemeStore();
const onlineStatusStore = useOnlineStatusStore();
const route = useRoute();

const isOpen = ref(false);
const isVisible = computed(() => !route.path.startsWith('/cajuia') && route.name !== 'Chat');
const messagesContainer = ref<any>(null);
const showScrollToBottom = ref(false);
const userHasScrolledUp = ref(false);
let scrollTimeout: NodeJS.Timeout;

const isUnreadNeonMode = ref(false);

const activeChannel = computed(() => chatStore.activeChannel);
const isPrivateDM = computed(() => activeChannel.value?.is_private_dm);
const isLoadingMore = computed(() => chatStore.isLoadingMore);

const menu = reactive({ show: false, x: 0, y: 0, message: null as any | null, isMyMessage: false });
const showForwardModal = ref(false);
const forwardingMessage = ref<any | null>(null);

const showMediaModal = ref(false);
const mediaModalUrl = ref('');
const mediaModalFileName = ref('');

const showInfoModal = ref(false);
const infoMessage = ref<any>(null);

const openMessageInfo = (msg: any) => {
    infoMessage.value = msg;
    showInfoModal.value = true;
};

const formatDateTime = (dateStr: string) => {
    if (!dateStr) return '';
    return format(parseISO(dateStr), "dd/MM/yyyy 'às' HH:mm", { locale: ptBR });
};

// ATUALIZADO: Usando inferência para ler o ID caso o read_by não exista
const getReaders = (msg: any) => {
    let readerIds = msg.read_by || [];

    // Simulação/Inferência para DMs quando o Supabase não tem a coluna read_by preenchida
    if (readerIds.length === 0 && msg.status === 'read' && msg.channel_id) {
        const channel = chatStore.channels.find(c => c.id === msg.channel_id);
        if (channel && channel.is_private_dm && channel.other_participant_id) {
            readerIds = [channel.other_participant_id];
        }
    }

    if (!Array.isArray(readerIds)) return [];

    const filtered = readerIds.filter((id: string) => id !== msg.profile_id);
    return filtered.map((id: string) => {
        const u = allUsers.value.find(user => user.id === id);
        return u || { id, full_name: 'Usuário' };
    });
};

const showEmojiPicker = ref(false);
const emojisList = ['😀','😂','😅','😉','😍','🥰','😘','😜','😎','🤩','🤔','🤨','😐','😑','😶','🙄','😏','😮','🤐','😯','😪','😫','🥱','😴','😌','😛','🤤','😒','😓','😔','😕','🙃','🤑','😲','☹️','🙁','😖','😞','😟','😤','😢','😭','😦','😧','😨','😩','🤯','😬','😰','😱','🥵','🥶','😳','🤪','😵','😡','😠','🤬','😷','🤒','🤕','🤢','🤮','🤧','😇','🥳','🥺','🤠','🤡','🤥','🤫','🤭','🧐','🤓','😈','👿','👹','👺','💀','👻','👽','🤖','💩','😺','😸','😹','😻','😼','😽','🙀','😿','😾'];
const insertEmoji = (emoji: string) => { newMessage.value += emoji; };

let realtimeSubscription: any;

const initRealtimeSync = () => {
    if (realtimeSubscription) return;

    realtimeSubscription = supabase.channel('chat-master-sync')
      .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'messages' }, async (payload) => {
          const newMsg = payload.new;
          const myId = userStore.user?.id;

          if (!myId) return;

          await chatStore.fetchChannels(myId);

          const channel = chatStore.channels.find((c: any) => c.id === newMsg.channel_id);
          if (!channel) return;

          if (chatStore.activeChannel?.id === newMsg.channel_id) {
              const { data: fullMsg } = await supabase.from('messages').select('*').eq('id', newMsg.id).single();

              if (fullMsg) {
                  const { data: profile } = await supabase.from('profiles').select('id, full_name, avatar_url, role').eq('id', fullMsg.profile_id).single();
                  fullMsg.profile = profile || null;

                  if (fullMsg.reply_to_message_id) {
                      const { data: rep } = await supabase.from('messages').select('*').eq('id', fullMsg.reply_to_message_id).single();
                      if (rep) {
                          const { data: repProf } = await supabase.from('profiles').select('full_name').eq('id', rep.profile_id).single();
                          rep.profile = repProf || null;
                          fullMsg.reply_to_message = rep;
                      }
                  }

                  if (!chatStore.messages.some((m: any) => m.id === fullMsg.id)) {
                      chatStore.messages.push(fullMsg);
                      setTimeout(() => forceScrollToBottom(), 150);
                  }
              }
          }

          if (newMsg.profile_id !== myId && !isOpen.value) {
              isUnreadNeonMode.value = true;
              await switchChannel(newMsg.channel_id, true);
              isOpen.value = true;
              setTimeout(() => forceScrollToBottom(), 300);
          }
      })
      .on('postgres_changes', { event: 'UPDATE', schema: 'public', table: 'messages' }, (payload) => {
          const updatedMsg = payload.new;
          const index = chatStore.messages.findIndex((m: any) => m.id === updatedMsg.id);
          if (index !== -1) {
              chatStore.messages[index].reactions = updatedMsg.reactions;
              chatStore.messages[index].content = updatedMsg.content;
              chatStore.messages[index].is_deleted = updatedMsg.is_deleted;
              chatStore.messages[index].is_edited = updatedMsg.is_edited;
              chatStore.messages[index].status = updatedMsg.status;
              chatStore.messages[index].read_by = updatedMsg.read_by;
          }
      })
      .subscribe();
};

const handleChatInteraction = () => {
    if (isUnreadNeonMode.value) {
        isUnreadNeonMode.value = false;
        if (chatStore.activeChannel && chatStore.markAsRead) {
            chatStore.markAsRead(chatStore.activeChannel.id);
        }
    }
};

const filteredGroupedMessages = computed(() => {
    let items = chatStore.messages || [];

    const myId = userStore.profile?.id;
    const myRole = userStore.profile?.role;
    const isAdmin = myRole === 'admin' || myRole === 'super_admin';

    items = items.filter(msg => {
        if (!msg.target_users || msg.target_users.length === 0) return true;
        if (msg.profile_id === myId) return true;
        if (isAdmin) return true;
        if (msg.target_users.includes(myId)) return true;
        return false;
    });

    if (!items.length) return [];

    const groups: { date: string; messages: any[] }[] = [];
    let lastDate = '';

    items.forEach(msg => {
        const date = new Date(msg.created_at);
        let formattedDate: string;
        if (isToday(date)) formattedDate = 'Hoje';
        else if (isYesterday(date)) formattedDate = 'Ontem';
        else formattedDate = format(date, "d 'de' MMMM", { locale: ptBR });

        if (formattedDate !== lastDate) {
            groups.push({ date: formattedDate, messages: [] });
            lastDate = formattedDate;
        }
        groups[groups.length - 1].messages.push(msg);
    });
    return groups;
});

const isConsecutiveMessage = (message: any, index: number, group: any[]) => {
    if (index === 0) return false;
    const prevMessage = group[index - 1];
    const timeDiff = differenceInMinutes(new Date(message.created_at), new Date(prevMessage.created_at));
    return prevMessage.profile_id === message.profile_id && timeDiff < 5 && prevMessage.message_type !== 'system' && message.message_type !== 'system';
};

const activeChannelsList = computed(() => {
  return [...chatStore.channels].sort((a, b) => {
     const timeA = new Date(a.last_message_at || a.updated_at || 0).getTime();
     const timeB = new Date(b.last_message_at || b.updated_at || 0).getTime();
     if (timeB !== timeA) return timeB - timeA;
     return (b.unread_count || 0) - (a.unread_count || 0);
  });
});

const allUsers = ref<any[]>([]);
const userSearchQuery = ref('');

const fetchAllUsers = async () => {
   const { data, error } = await supabase
     .from('profiles')
     .select('id, full_name, username, avatar_url, role, custom_roles:custom_role_id(name)')
     .eq('is_active', true)
     .neq('id', userStore.user?.id);

   if (!error && data) {
       allUsers.value = data;
   }
};

const filteredAllUsers = computed(() => {
    if (!userSearchQuery.value) return allUsers.value;
    const q = userSearchQuery.value.toLowerCase();
    return allUsers.value.filter(u =>
        (u.full_name || '').toLowerCase().includes(q) ||
        (u.username || '').toLowerCase().includes(q) ||
        (u.custom_roles?.name || u.role || '').toLowerCase().includes(q)
    );
});

const getRoleName = (profile: any) => {
    if (!profile) return 'Usuário';
    if (profile.custom_roles && profile.custom_roles.name) return profile.custom_roles.name;
    if (profile.custom_role && profile.custom_role.name) return profile.custom_role.name;
    return profile.role === 'super_admin' ? 'Administrador' : (profile.role || 'Usuário');
};

const activeUserRoleName = ref('');
watch(() => chatStore.activeChannel, async (newChannel) => {
    if (!newChannel || !newChannel.is_private_dm || !newChannel.other_participant_id) {
        activeUserRoleName.value = '';
        return;
    }
    const targetUser = allUsers.value.find(u => u.id === newChannel.other_participant_id);
    if (targetUser) {
        activeUserRoleName.value = getRoleName(targetUser);
    } else {
        const { data: profile } = await supabase.from('profiles').select('role, custom_role_id').eq('id', newChannel.other_participant_id).single();
        if (profile) {
            if (profile.custom_role_id) {
                const { data: roleData } = await supabase.from('custom_roles').select('name').eq('id', profile.custom_role_id).single();
                activeUserRoleName.value = roleData?.name || profile.role;
            } else {
                activeUserRoleName.value = profile.role === 'super_admin' ? 'Administrador' : (profile.role || 'Usuário');
            }
        }
    }
}, { immediate: true });

const startChatWithUser = async (user: any) => {
    const existingChannel = chatStore.channels.find(c => c.is_private_dm && c.other_participant_id === user.id);
    if (existingChannel) {
        await switchChannel(existingChannel.id);
        return;
    }

    const { data: channelId, error } = await supabase.rpc('find_or_create_dm_channel', {
        p_user1_id: userStore.user!.id,
        p_user2_id: user.id
    });

    if (!error && channelId) {
        await chatStore.fetchChannels(userStore.user!.id);
        await switchChannel(channelId);
    }
};

const currentChannelAvatar = computed(() => chatStore.activeChannel?.icon_image_url || 'https://ui-avatars.com/api/?name=Chat');

const currentChatStatusColor = computed(() => {
    if (!chatStore.activeChannel || !isPrivateDM.value) return 'transparent';
    const targetId = chatStore.activeChannel.other_participant_id;

    const onlineUsers = onlineStatusStore.onlineUsers || [];
    const statusObj = onlineUsers.find((u: any) => u.user_id === targetId || u.id === targetId || u.profile_id === targetId);

    if (!statusObj) return 'grey-lighten-1';

    const status = statusObj.status || 'online';
    if (status === 'online') return 'success';
    if (status === 'away') return 'warning';
    if (status === 'busy') return 'error';
    return 'success';
});

const isUserOnline = (userId: string) => {
   const onlineUsers = onlineStatusStore.onlineUsers || [];
   return onlineUsers.some((u: any) => u.user_id === userId || u.id === userId || u.profile_id === userId);
};

const groupMembers = computed(() => {
    if (!chatStore.activeChannel || chatStore.activeChannel.is_private_dm) return [];
    return (chatStore.activeChannel as any).members || [];
});

const newMessage = ref('');
const isSending = ref(false);
const replyingToMessage = ref<any>(null);
const editingMessage = ref<any>(null);

const onShowMenu = ({ event, message }: { event: MouseEvent | TouchEvent, message: any }) => {
    const clientX = (event as MouseEvent).clientX || (event as TouchEvent).touches[0].clientX;
    const clientY = (event as MouseEvent).clientY || (event as TouchEvent).touches[0].clientY;

    menu.show = true;
    menu.x = clientX;
    menu.y = clientY;
    menu.message = message;
    menu.isMyMessage = message.profile_id === userStore.profile?.id;
};

const handleMenuAction = async (action: string) => {
    if (!menu.message) return;
    const message = menu.message;
    menu.show = false;

    switch(action) {
        case 'delete':
            if (confirm('Tem certeza que deseja excluir esta mensagem?')) {
                await supabase.from('messages').update({ is_deleted: true, content: 'Mensagem apagada' }).eq('id', message.id);
            }
            break;
        case 'edit':
            cancelReply();
            editingMessage.value = message;
            newMessage.value = message.content;
            break;
        case 'reply':
            handleSwipeReply(message);
            break;
        case 'forward':
            forwardingMessage.value = message;
            showForwardModal.value = true;
            break;
    }
};

const handleSwipeReply = (message: any) => {
    cancelEdit();
    replyingToMessage.value = message;
};

const cancelEdit = () => { editingMessage.value = null; newMessage.value = ''; };
const cancelReply = () => { replyingToMessage.value = null; };
const cancelAction = () => { cancelEdit(); cancelReply(); };

const executeForward = async ({ channels: channelIds, message }: { channels: number[], message: any}) => {
    if (!message || channelIds.length === 0 || !userStore.profile) return;
    for (const channelId of channelIds) {
        await supabase.from('messages').insert({
            content: message.content,
            channel_id: channelId,
            profile_id: userStore.profile.id,
            message_type: message.message_type
        });
    }
    showForwardModal.value = false;
    forceScrollToBottom();
};

const handleViewMedia = ({ url, fileName }: { url: string, fileName: string }) => {
    mediaModalUrl.value = url;
    mediaModalFileName.value = fileName;
    showMediaModal.value = true;
};

const handleMediaForward = (media: { url: string, type: string, name: string }) => {
    forwardingMessage.value = { content: media.url, message_type: media.type };
    showMediaModal.value = false;
    showForwardModal.value = true;
};

const switchChannel = async (channelId: number, isAutoOpen = false) => {
  if (chatStore.activeChannel?.id === channelId) return;
  await chatStore.setActiveChannel(channelId);

  if (!isAutoOpen) {
      isUnreadNeonMode.value = false;
  }

  cancelAction();
  forceScrollToBottom();
};

const handleSend = async () => {
  if (!newMessage.value.trim() || isSending.value || !chatStore.activeChannel) return;

  const content = newMessage.value;
  const channelId = chatStore.activeChannel.id;
  const userId = userStore.user?.id;
  if (!userId) return;

  isSending.value = true;

  try {
    if (editingMessage.value) {
        await supabase.from('messages').update({
           content,
           is_edited: true,
           edited_from: editingMessage.value.content
        }).eq('id', editingMessage.value.id);
    } else {
        const replyId = replyingToMessage.value ? replyingToMessage.value.id : null;
        await chatStore.sendMessage(content, channelId, userId, replyId);
    }
  } catch (e) {
    console.error("Erro ao enviar:", e);
  } finally {
    isSending.value = false;
    newMessage.value = '';
    cancelAction();
    forceScrollToBottom();
  }
};

const fileInputDesktop = ref<HTMLInputElement | null>(null);
const isUploading = ref(false);

const triggerFileInput = () => { fileInputDesktop.value?.click(); };

const handleFileUpload = async (event: any) => {
    const target = event.target as HTMLInputElement;
    if (!target.files || target.files.length === 0) return;
    const file = target.files[0];
    if (!file || !chatStore.activeChannel || !userStore.user) return;

    isUploading.value = true;
    try {
        const fileExt = file.name.split('.').pop();
        const fileName = `${Date.now()}-${Math.random().toString(36).substring(7)}.${fileExt}`;
        const filePath = `channel_${chatStore.activeChannel.id}/${fileName}`;

        const { error } = await supabase.storage.from('media').upload(filePath, file);
        if (error) throw error;

        const { data: urlData } = supabase.storage.from('media').getPublicUrl(filePath);

        let type = 'file';
        if (file.type.startsWith('image/')) type = 'image';
        else if (file.type.startsWith('video/')) type = 'video';
        else if (file.type.startsWith('audio/')) type = 'audio';

        const replyId = replyingToMessage.value ? replyingToMessage.value.id : null;
        await chatStore.sendMessage(urlData.publicUrl, chatStore.activeChannel.id, userStore.user.id, replyId, type, file.name);
        forceScrollToBottom();
    } catch (err) { console.error("Upload error", err); }
    finally {
        isUploading.value = false;
        target.value = '';
        cancelAction();
    }
};

const isRecording = ref(false);
const mediaRecorder = ref<MediaRecorder | null>(null);
const audioChunks = ref<Blob[]>([]);
const recordingTime = ref('00:00');
let recordingInterval: number;
const cancelCurrentRecording = ref(false);
const recordingWaves = ref<number[]>([]);

let audioContext: AudioContext | null = null;
let analyser: AnalyserNode | null = null;
let microphone: MediaStreamAudioSourceNode | null = null;
let animationFrameId: number;

const startRecording = async () => {
  try {
    const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
    mediaRecorder.value = new MediaRecorder(stream);
    audioChunks.value = [];
    recordingWaves.value = [];
    cancelCurrentRecording.value = false;

    audioContext = new (window.AudioContext || (window as any).webkitAudioContext)();
    analyser = audioContext.createAnalyser();
    microphone = audioContext.createMediaStreamSource(stream);
    microphone.connect(analyser);
    analyser.fftSize = 256;
    const bufferLength = analyser.frequencyBinCount;
    const dataArray = new Uint8Array(bufferLength);

    const drawWave = () => {
      if (!isRecording.value) return;
      analyser!.getByteFrequencyData(dataArray);
      let sum = 0;
      for(let i = 0; i < bufferLength; i++) { sum += dataArray[i]; }
      let average = sum / bufferLength;
      let percent = Math.min(100, Math.max(10, (average / 128) * 100));

      recordingWaves.value.push(percent);
      if (recordingWaves.value.length > 35) { recordingWaves.value.shift(); }
      animationFrameId = requestAnimationFrame(drawWave);
    };

    mediaRecorder.value.ondataavailable = event => audioChunks.value.push(event.data);

    mediaRecorder.value.onstop = async () => {
      stream.getTracks().forEach(track => track.stop());
      cancelAnimationFrame(animationFrameId);
      if (audioContext && audioContext.state !== 'closed') { audioContext.close(); }

      if (cancelCurrentRecording.value) {
        cancelCurrentRecording.value = false;
        return;
      }

      const mimeType = MediaRecorder.isTypeSupported('audio/webm') ? 'audio/webm' : 'audio/mp4';
      const audioBlob = new Blob(audioChunks.value, { type: mimeType });
      const ext = mimeType === 'audio/mp4' ? 'mp4' : 'webm';
      const fileName = `audio_${Date.now()}.${ext}`;
      const filePath = `channel_${chatStore.activeChannel!.id}/${fileName}`;

      isUploading.value = true;
      const { data, error } = await supabase.storage.from('media').upload(filePath, audioBlob);
      if (!error) {
         const { data: { publicUrl } } = supabase.storage.from('media').getPublicUrl(data.path);
         const replyId = replyingToMessage.value ? replyingToMessage.value.id : null;
         await chatStore.sendMessage(publicUrl, chatStore.activeChannel!.id, userStore.user!.id, replyId, 'audio');
         forceScrollToBottom();
      }
      isUploading.value = false;
    };

    mediaRecorder.value.start();
    isRecording.value = true;
    let seconds = 0;

    recordingInterval = window.setInterval(() => {
      seconds++;
      const min = Math.floor(seconds / 60).toString().padStart(2, '0');
      const sec = (seconds % 60).toString().padStart(2, '0');
      recordingTime.value = `${min}:${sec}`;
    }, 1000);

    drawWave();
  } catch (err) {
    alert('Não foi possível acessar o microfone. Verifique as permissões.');
  }
};

const cancelRecording = () => {
  cancelCurrentRecording.value = true;
  if (mediaRecorder.value) mediaRecorder.value.stop();
  resetRecordingState();
};

const stopRecordingAndSend = () => {
  cancelCurrentRecording.value = false;
  if (mediaRecorder.value) mediaRecorder.value.stop();
  resetRecordingState();
};

const resetRecordingState = () => {
  isRecording.value = false;
  window.clearInterval(recordingInterval);
  recordingTime.value = '00:00';
  recordingWaves.value = [];
};

const openChat = async (channelId?: number) => {
  if (channelId && chatStore.activeChannel?.id !== channelId) {
      await switchChannel(channelId);
  }
  isOpen.value = true;
  _executeScroll('auto');
};

const closeChat = () => { isOpen.value = false; };

const scrollToMessage = (msgId: string | number) => {
    const el = document.getElementById(`msg-${msgId}`);
    if (el) {
        el.scrollIntoView({ behavior: 'smooth', block: 'center' });
        el.classList.add('highlight-pulse');
        setTimeout(() => { el.classList.remove('highlight-pulse'); }, 2000);
    }
};

const _executeScroll = (behavior: 'smooth' | 'auto') => {
  nextTick(() => {
    setTimeout(() => {
      const el = messagesContainer.value?.$el;
      if (el) el.scrollTo({ top: el.scrollHeight, behavior });
    }, 150);
  });
};

const forceScrollToBottom = () => {
  userHasScrolledUp.value = false;
  showScrollToBottom.value = false;
  _executeScroll('smooth');
};

const handleScroll = async () => {
  clearTimeout(scrollTimeout);
  scrollTimeout = setTimeout(async () => {
    const el = messagesContainer.value?.$el;
    if (el) {
      const { scrollTop, scrollHeight, clientHeight } = el;
      const isNearBottom = scrollHeight - scrollTop - clientHeight < 150;
      showScrollToBottom.value = !isNearBottom;
      userHasScrolledUp.value = !isNearBottom;

      if (scrollTop < 50 && chatStore.hasMoreMessages && !chatStore.isLoadingMore && chatStore.activeChannel) {
        const oldScrollHeight = scrollHeight;
        await chatStore.loadMoreMessages(chatStore.activeChannel.id);
        nextTick(() => { el.scrollTop = el.scrollHeight - oldScrollHeight; });
      }
    }
  }, 100);
};

defineExpose({ openChat, closeChat });

onMounted(() => {
    fetchAllUsers();
    initRealtimeSync();
});

onUnmounted(() => {
    if (realtimeSubscription) {
        supabase.removeChannel(realtimeSubscription);
    }
});

watch(() => chatStore.messages, () => { if (!userHasScrolledUp.value) _executeScroll('smooth'); }, { deep: true });
</script>

<style scoped lang="scss">
.chat-widget-wrapper {
  position: fixed;
  bottom: 24px;
  right: 24px;
  z-index: 1050;
  display: flex;
  align-items: flex-end;
  flex-direction: column;
}

/* =======================================
   SISTEMA DE WALLPAPER E BLUR
   ======================================= */
.chat-wallpaper {
  position: absolute;
  top: 0; left: 0; right: 0; bottom: 0;
  background-size: cover;
  background-position: center;
  background-repeat: no-repeat;
  z-index: 0;
  transition: background-image 0.5s ease;
  border-radius: 20px;
}

.chat-wallpaper-blur {
  position: absolute;
  top: 0; left: 0; right: 0; bottom: 0;
  backdrop-filter: blur(8px);
  -webkit-backdrop-filter: blur(8px);
  background: rgba(255, 255, 255, 0.4);
  z-index: 1;
  border-radius: 20px;
  transition: all 0.3s ease;
}

.v-theme--dark .chat-wallpaper-blur {
  background: rgba(0, 0, 0, 0.5);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
}

.wallpaper-thumb {
  width: 52px;
  height: 52px;
  border-radius: 10px;
  background-size: cover;
  background-position: center;
  position: relative;
  transition: transform 0.2s;
  overflow: hidden;
  &:hover { transform: scale(1.08); z-index: 10; }
}

.active-wallpaper {
  border: 2px solid rgb(var(--v-theme-primary));
  transform: scale(1.05);
}

.active-indicator {
  position: absolute;
  top: 0; left: 0; right: 0; bottom: 0;
  background: rgba(var(--v-theme-primary), 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
}

.custom-upload-btn {
  border: 2px dashed rgba(var(--v-theme-primary), 0.3) !important;
  background-color: rgba(var(--v-theme-primary), 0.05) !important;
  transition: all 0.2s;
  border-radius: 8px;
  &:hover {
     background-color: rgba(var(--v-theme-primary), 0.1) !important;
     border-color: rgba(var(--v-theme-primary), 0.6) !important;
  }
}

.z-index-2 { z-index: 2; }
.position-relative { position: relative; }

/* =======================================
   FAB GLASSMORPHISM PREMIUM
   ======================================= */
.chat-fab.glass-fab {
  background: linear-gradient(135deg, rgba(var(--v-theme-primary), 0.95), rgba(var(--v-theme-secondary), 0.85)) !important;
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  border: 1px solid rgba(255, 255, 255, 0.3);
  box-shadow: 0 10px 30px rgba(var(--v-theme-primary), 0.4), inset 0 2px 4px rgba(255,255,255,0.4) !important;
  transition: all 0.4s cubic-bezier(0.34, 1.56, 0.64, 1);
  overflow: visible !important;
}
.chat-fab.glass-fab:hover {
  transform: scale(1.1) translateY(-4px);
  box-shadow: 0 15px 40px rgba(var(--v-theme-primary), 0.6), inset 0 2px 4px rgba(255,255,255,0.5) !important;
}

.super-badge :deep(.v-badge__badge) { font-size: 0.85rem !important; height: 24px !important; min-width: 24px !important; border-radius: 12px !important; border: 2px solid white; box-shadow: 0 4px 10px rgba(0,0,0,0.4); z-index: 100 !important; transform: translate(20%, -20%) !important; }
.pulse-badge :deep(.v-badge__badge) { animation: badgePulse 2s infinite; }
@keyframes badgePulse { 0% { transform: translate(20%, -20%) scale(1); } 50% { transform: translate(20%, -20%) scale(1.1); } 100% { transform: translate(20%, -20%) scale(1); } }

.chat-open-layout { display: flex; flex-direction: row; align-items: flex-end; gap: 16px; margin-bottom: 8px; }

.left-sidebar {
  display: flex; flex-direction: column; height: 600px; max-height: 80vh; overflow-y: auto; overflow-x: hidden;
  width: 90px !important; padding: 16px 0 !important; align-items: center;
  background: rgba(255, 255, 255, 0.4); backdrop-filter: blur(16px); -webkit-backdrop-filter: blur(16px);
  border: 1px solid rgba(255, 255, 255, 0.5); border-radius: 24px; box-shadow: 0 8px 32px 0 rgba(0, 0, 0, 0.1);
}

.v-theme--dark .left-sidebar { background: rgba(30, 30, 35, 0.4); border: 1px solid rgba(255, 255, 255, 0.1); box-shadow: 0 8px 32px 0 rgba(0, 0, 0, 0.3); }

.custom-scrollbar-hidden { scrollbar-width: none; &::-webkit-scrollbar { display: none; } }

.floating-bubble { cursor: pointer; position: relative; transition: transform 0.3s cubic-bezier(0.34, 1.56, 0.64, 1); border-radius: 50%; &:hover { transform: scale(1.15) translateY(-2px); z-index: 10; } }
.bubble-active { transform: scale(1.1); filter: brightness(1.2); }

.bubble-list-move { transition: transform 0.5s cubic-bezier(0.34, 1.56, 0.64, 1); }
.bubble-list-enter-active, .bubble-list-leave-active { transition: all 0.4s ease; }
.bubble-list-enter-from { opacity: 0; transform: translateY(20px); }
.bubble-list-leave-to { opacity: 0; transform: scale(0.8); position: absolute; }

.neon-unread-border {
  border: 1px solid rgba(0, 195, 255, 0.5) !important; box-shadow: 0 0 8px rgba(0, 195, 255, 0.4), inset 0 0 4px rgba(0, 195, 255, 0.2);
  animation: neonPulseLight 2s infinite alternate ease-in-out; cursor: pointer;
}
.v-theme--dark .neon-unread-border { border: 1px solid rgba(0, 229, 255, 0.6) !important; box-shadow: 0 0 10px rgba(0, 229, 255, 0.5), inset 0 0 5px rgba(0, 229, 255, 0.3); }

@keyframes neonPulseLight { 0% { box-shadow: 0 0 4px rgba(0, 195, 255, 0.2), inset 0 0 2px rgba(0, 195, 255, 0.1); } 100% { box-shadow: 0 0 15px rgba(0, 195, 255, 0.6), inset 0 0 8px rgba(0, 195, 255, 0.3); } }

.chat-window { width: 400px; max-width: 85vw; height: 600px; max-height: 80vh; display: flex; flex-direction: column; transition: box-shadow 0.3s ease, border 0.3s ease; position: relative; }

.glassmorphism-card-dialog {
  backdrop-filter: blur(25px) saturate(200%); -webkit-backdrop-filter: blur(25px) saturate(200%);
  background-color: rgba(30, 30, 35, 0.9) !important; border-radius: 20px !important;
  box-shadow: 0 20px 50px rgba(0,0,0,0.6), inset 0 1px 0 rgba(255,255,255,0.1); border: 1px solid rgba(255, 255, 255, 0.1);
}
.v-theme--light .glassmorphism-card-dialog { background-color: rgba(255, 255, 255, 0.95) !important; box-shadow: 0 20px 50px rgba(0,0,0,0.15), inset 0 1px 0 rgba(255,255,255,0.5); border: 1px solid rgba(0, 0, 0, 0.1); }

.status-dot-inline :deep(.v-badge__badge) { width: 10px; height: 10px; border-radius: 50%; }

.header-3d { background: linear-gradient(to bottom, rgba(255,255,255,0.05), transparent) !important; }
.dropdown-3d { border-radius: 16px !important; }
.chat-dropdown-item { transition: background 0.2s; &:hover { background: rgba(var(--v-theme-primary), 0.1); } }
.search-input-mini :deep(.v-field__input) { font-size: 0.85rem; padding-top: 4px; padding-bottom: 4px; }

.group-avatars-stack { position: relative; width: 70px; }
.overlapping-avatar { position: absolute; transition: transform 0.2s ease; }
.overlapping-avatar:nth-child(1) { left: 0; }
.overlapping-avatar:nth-child(2) { left: 18px; }
.overlapping-avatar:nth-child(3) { left: 36px; }

.messages-area { flex: 1 1 0; min-height: 0; overflow-y: auto; overflow-x: hidden; padding: 16px 5%; display: flex; flex-direction: column; background-color: transparent !important; background-image: none !important; }

.date-divider { display: flex; justify-content: center; align-items: center; padding: 16px 0; z-index: 2; }
.date-divider span { padding: 6px 16px; border-radius: 12px; font-size: 0.75rem; font-weight: 600; text-transform: uppercase; background-color: rgba(255, 255, 255, 0.85); backdrop-filter: blur(8px); color: rgba(0, 0, 0, 0.7); box-shadow: 0 1px 3px rgba(0, 0, 0, 0.08), 0 0 0 1px rgba(255, 255, 255, 0.4) inset; }
.v-theme--dark .date-divider span { background-color: rgba(30, 41, 59, 0.75); color: rgba(255, 255, 255, 0.9); box-shadow: 0 1px 3px rgba(0, 0, 0, 0.3), 0 0 0 1px rgba(255, 255, 255, 0.05) inset; }

.shadow-text { text-shadow: 0 1px 2px rgba(0,0,0,0.2); }

.input-area { display: flex; flex-direction: column; padding: 12px 16px; flex-shrink: 0; z-index: 5; background: rgba(255, 255, 255, 0.9); backdrop-filter: blur(20px); -webkit-backdrop-filter: blur(20px); border-top: 1px solid rgba(0, 0, 0, 0.08); border-bottom-left-radius: 20px; border-bottom-right-radius: 20px; }
.v-theme--dark .input-area { background: rgba(30, 30, 35, 0.85); border-top: 1px solid rgba(255, 255, 255, 0.08); }

.input-controls { display: flex; align-items: center; }

.input-field-wrapper { background-color: rgba(0, 0, 0, 0.05); border-radius: 24px; padding: 4px 16px; display: flex; align-items: center; min-height: 44px; transition: all 0.3s; }
.v-theme--dark .input-field-wrapper { background-color: rgba(0, 0, 0, 0.4); border: 1px solid rgba(255, 255, 255, 0.05); box-shadow: inset 0 2px 4px rgba(0,0,0,0.2); }
.chat-text-field :deep(.v-field) { background: transparent !important; box-shadow: none !important; }
.chat-text-field :deep(.v-field__input) { padding: 8px 0 !important; min-height: auto !important; }

.recording-ui { background-color: rgba(0, 0, 0, 0.05); border: 1px solid rgba(0, 0, 0, 0.03); }
.v-theme--dark .recording-ui { background-color: rgba(0, 0, 0, 0.4); border: 1px solid rgba(255, 255, 255, 0.05); box-shadow: inset 0 2px 4px rgba(0,0,0,0.2); }

.preview-area { display: flex; justify-content: space-between; align-items: center; padding: 8px 12px; background-color: rgba(128, 128, 128, 0.05); border-radius: 8px 8px 0 0; margin-bottom: 8px; border-left: 4px solid; }
.reply-preview { border-left-color: rgb(var(--v-theme-primary)); }
.edit-preview { border-left-color: rgb(var(--v-theme-warning)); }
.reply-preview-thumb { width: 40px; height: 40px; flex-shrink: 0; position: relative; }

.emoji-btn { font-size: 1.2rem; min-width: 32px !important; padding: 0 !important; }
.pulse-send-btn { animation: pulse-primary 2s infinite; }
@keyframes pulse-primary { 0% { transform: scale(1); } 50% { transform: scale(1.1); } 100% { transform: scale(1); } }
.pulse-anim { animation: blink 1.5s infinite ease-in-out; }
@keyframes blink { 0% { opacity: 1; transform: scale(1); } 50% { opacity: 0.6; transform: scale(1.1); } 100% { opacity: 1; transform: scale(1); } }

.live-waveform-container { height: 24px !important; min-height: 24px !important; max-height: 24px !important; overflow: hidden; display: flex; align-items: center; }
.live-waveform-container .waveform-layer { height: 100%; gap: 2px; }
.live-waveform-container .wave-bar { width: 3px; background-color: rgb(var(--v-theme-primary)); border-radius: 2px; flex-shrink: 0; transition: height 0.1s ease; }

.scroll-bottom-btn { position: absolute; bottom: 90px; right: 20px; z-index: 10; opacity: 0.9; }

.custom-scrollbar::-webkit-scrollbar { width: 6px; }
.custom-scrollbar::-webkit-scrollbar-thumb { background: rgba(128, 128, 128, 0.3); border-radius: 4px; }
.custom-scrollbar-menu::-webkit-scrollbar { width: 4px; }
.custom-scrollbar-menu::-webkit-scrollbar-thumb { background: rgba(128, 128, 128, 0.3); border-radius: 4px; }

:deep(.highlight-pulse) { animation: highlightPulse 2s ease-out; border-radius: 8px; }
@keyframes highlightPulse { 0% { background-color: rgba(var(--v-theme-primary), 0.3); } 100% { background-color: transparent; } }

.strict-badge :deep(.v-badge__badge) { transform: scale(0.75) !important; transform-origin: center !important; z-index: 10 !important; }

.chat-info-dialog .message-preview {
  background-color: rgba(var(--v-theme-on-surface), 0.05) !important;
  color: rgba(var(--v-theme-on-surface), 0.9) !important;
}

.chat-info-dialog .text-body-2,
.chat-info-dialog .text-caption,
.chat-info-dialog .text-subtitle-1 {
  color: rgba(var(--v-theme-on-surface), 0.8) !important;
}
</style>
