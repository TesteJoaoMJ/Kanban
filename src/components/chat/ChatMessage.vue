<template>
  <div
    class="message-row"
    :id="'msg-' + message.id"
    :class="{
      'is-mine': isMine,
      'is-other': !isMine,
      'is-system': isSystem || isAdminAlert,
      'is-consecutive': isConsecutive
    }"
  >
    <div v-if="isSystem" class="system-message">
      <span>{{ message.content }}</span>
    </div>

    <div v-else-if="isAdminAlert" class="admin-alert-message elevation-3">
      <v-icon size="18" class="mr-2 text-white">mdi-alert-decagram</v-icon>
      <span v-html="message.content"></span>
    </div>

    <div v-else class="w-100 position-relative"
         @touchstart="handleTouchStart"
         @touchmove="handleTouchMove"
         @touchend="handleTouchEnd"
    >
      <div class="swipe-icon-container">
        <v-icon size="24" class="text-medium-emphasis" :style="iconStyle">mdi-reply</v-icon>
      </div>

      <div class="bubble-wrapper d-flex flex-column"
           :class="{ 'align-end': isMine, 'align-start': !isMine }"
           :style="swipeStyle"
      >
        <div class="message-bubble"
             :class="{
                'media-bubble': isMediaOnly && !isPng && !message.is_deleted && !hasCaption,
                'png-bubble': isPng && !message.is_deleted && !hasCaption,
                'media-with-caption': isMediaOnly && hasCaption && !message.is_deleted,
                'audio-bubble': isAudio && !message.is_deleted,
                'is-whisper': isWhisper
             }"
             @contextmenu.prevent="openMenu"
        >
          <div v-if="isWhisper" class="whisper-header">
             <v-icon size="12" class="mr-1">mdi-eye-off</v-icon>
             <span>Sussurro da Administração</span>
          </div>

          <div v-if="!isMine && isGroup && !isConsecutive && !message.is_deleted" class="sender-name font-weight-bold text-caption mb-1" :style="{ color: userColor }">
              {{ message.profile?.full_name || 'Usuário' }}
          </div>

          <template v-if="message.is_deleted">
            <div class="deleted-message d-flex align-center font-italic pa-2" style="opacity: 0.7;">
              <v-icon size="18" class="mr-2 opacity-60">mdi-cancel</v-icon>
              <span style="font-size: 0.95rem;">Mensagem apagada</span>
            </div>
            <span class="meta-spacer"></span>
          </template>

          <template v-else>
            <div class="hover-actions-container">
              <v-menu v-model="showReactionMenu" location="top" :close-on-content-click="true" offset="8">
                <template v-slot:activator="{ props }">
                  <div class="hover-action-btn" v-bind="props" title="Reagir">
                    <v-icon size="18" class="icon-force-gray">mdi-emoticon-outline</v-icon>
                  </div>
                </template>
                <div class="quick-reactions-bar elevation-4 glassmorphism-menu">
                  <span v-for="emoji in quickReactions" :key="emoji" class="quick-emoji" @click.stop="toggleReaction(emoji)">
                    {{ emoji }}
                  </span>
                </div>
              </v-menu>

              <div v-if="isMine" class="hover-action-btn" @click.stop="emit('info', message)" title="Dados da Mensagem">
                <v-icon size="18" class="icon-force-gray">mdi-information-variant</v-icon>
              </div>

              <div class="hover-action-btn" @click.stop="openMenu($event)" title="Opções">
                <v-icon size="20" class="icon-force-gray">mdi-chevron-down</v-icon>
              </div>
            </div>

            <div v-if="repliedMessage" class="reply-block cursor-pointer" @click="scrollToOriginal(repliedMessage.id)">
              <div v-if="repliedMessage.message_type === 'image' || repliedMessage.message_type === 'video'" class="reply-thumb-wrapper">
                <img :src="repliedMessage.content" class="reply-thumb" alt="Thumbnail" />
                <div v-if="repliedMessage.message_type === 'video'" class="video-overlay">
                  <v-icon size="16" color="white">mdi-play</v-icon>
                </div>
              </div>
              <div v-else-if="repliedMessage.message_type === 'audio'" class="reply-thumb-wrapper bg-primary-lighten-4 d-flex align-center justify-center">
                <v-icon color="primary" size="20">mdi-microphone</v-icon>
              </div>
              <div v-else-if="repliedMessage.message_type === 'file' || repliedMessage.message_type === 'document'" class="reply-thumb-wrapper bg-grey-lighten-2 d-flex align-center justify-center">
                <v-icon color="grey-darken-2" size="20">mdi-file-document</v-icon>
              </div>

              <div class="reply-content">
                <span class="reply-author font-weight-bold" :class="isMine ? 'text-primary' : 'text-purple'">
                  {{ replyAuthor }}
                </span>
                <span class="reply-text text-truncate">{{ replyText }}</span>
              </div>
            </div>

            <div v-if="isImage" class="media-container cursor-pointer" @click="viewMedia(message.content)">
              <img :src="message.content" class="media-image" :class="{'bg-transparent': isPng, 'bg-grey-lighten-3': !isPng, 'rounded-bottom-0': hasCaption}" alt="Imagem" />
            </div>

            <div v-else-if="isVideo" class="media-container cursor-pointer" @click="viewMedia(message.content)">
              <div class="video-wrapper bg-black d-flex align-center justify-center" :class="{'rounded-bottom-0': hasCaption}">
                <v-icon color="white" size="48">mdi-play-circle</v-icon>
                <span class="video-duration text-caption">Vídeo</span>
              </div>
            </div>

            <div v-else-if="isFile" class="document-container cursor-pointer" :class="{'rounded-bottom-0': hasCaption}" @click="openLink(message.content)">
              <div class="doc-icon-box">
                <v-icon size="32" color="white">mdi-file-document</v-icon>
              </div>
              <div class="doc-info overflow-hidden">
                <span class="doc-name text-truncate d-block font-weight-medium">{{ extractFileName(message.content) }}</span>
                <span class="doc-meta text-caption text-uppercase d-block mt-1">ARQUIVO • PDF/DOC</span>
              </div>
              <span v-if="!hasCaption" class="meta-spacer"></span>
            </div>

            <div v-else-if="isAudio" class="audio-container d-flex flex-column">
              <audio
                ref="audioElement"
                :src="message.content"
                @timeupdate="handleTimeUpdate"
                @loadedmetadata="handleLoadedMetadata"
                @ended="handleEnded"
                style="display:none;"
              ></audio>

              <div class="d-flex align-center w-100">
                <v-avatar size="36" :image="avatarUrl" class="mr-2 flex-shrink-0" v-if="!isMine"></v-avatar>

                <v-btn
                  :icon="isPlaying ? 'mdi-pause' : 'mdi-play'"
                  variant="text"
                  size="small"
                  class="play-btn flex-shrink-0"
                  @click.stop="toggleAudio"
                ></v-btn>

                <div class="audio-timeline flex-grow-1 mx-2 position-relative cursor-pointer" @click="seekAudio">
                  <div v-if="isExtractingPeaks" class="d-flex align-center justify-center h-100">
                    <v-progress-linear indeterminate size="16" width="2" color="currentcolor" opacity="0.5"></v-progress-linear>
                  </div>

                  <template v-else>
                    <div class="waveform-layer bg-layer">
                      <div class="wave-bar" v-for="(h, i) in waveHeights" :key="'bg'+i" :style="{ height: Math.max(h, 15) + '%' }"></div>
                    </div>

                    <div class="waveform-layer fg-layer" :style="{ width: audioProgress + '%' }">
                      <div class="wave-bar active" v-for="(h, i) in waveHeights" :key="'fg'+i" :style="{ height: Math.max(h, 15) + '%' }"></div>
                    </div>
                  </template>
                </div>

                <v-avatar size="36" :image="avatarUrl" class="ml-2 flex-shrink-0" v-if="isMine"></v-avatar>
              </div>

              <div class="audio-times text-caption font-weight-medium px-1" :class="isMine ? 'text-right mr-11' : 'ml-11'">
                <span class="opacity-70">{{ isPlaying || audioProgress > 0 ? audioCurrentTime : audioDuration }}</span>
              </div>

              <span v-if="!hasCaption" class="meta-spacer" style="height: 4px;"></span>
            </div>

            <div v-else class="message-text position-relative">
              <span class="text-content" v-html="highlightedContent"></span>
              <span class="meta-spacer"></span>
            </div>

            <div v-if="hasCaption" class="caption-text position-relative">
               <span class="text-content" v-html="highlightedCaption"></span>
               <span class="meta-spacer"></span>
            </div>
          </template>

          <div class="message-meta" :class="{ 'meta-overlay': isMediaOnly && !isPng && !message.is_deleted && !hasCaption, 'meta-png': isPng && !message.is_deleted && !hasCaption }">
            <span v-if="message.is_edited && !message.is_deleted" class="edited-text mr-1">Editada</span>
            <span class="time">{{ formattedTime }}</span>

            <template v-if="isMine && !message.is_deleted">
              <v-icon v-if="computedStatus === 'sending'" size="14" class="status-icon ml-1" style="opacity: 0.6;">mdi-clock-outline</v-icon>

              <v-icon v-else-if="computedStatus === 'error'" size="16" color="error" class="status-icon ml-1 cursor-pointer" title="Falha. Clique para tentar." @click.stop="resendMsg">mdi-alert-circle</v-icon>

              <v-icon v-else-if="computedStatus === 'read'" size="16" class="status-icon ml-1 text-blue">mdi-check-all</v-icon>

              <v-icon v-else-if="computedStatus === 'delivered'" size="16" class="status-icon ml-1" style="opacity: 0.6;">mdi-check-all</v-icon>

              <v-icon v-else size="16" class="status-icon ml-1" style="opacity: 0.6;">mdi-check</v-icon>
            </template>
          </div>

          <div v-if="localReactions && Object.keys(localReactions).length > 0 && !message.is_deleted" class="reactions-display">
            <div
              v-for="(users, emoji) in localReactions"
              :key="emoji"
              class="reaction-pill"
              :class="{'mine': users.includes(userStore.profile?.id)}"
              @click.stop="toggleReaction(emoji)"
            >
               <span class="reaction-emoji">{{ emoji }}</span>
               <span class="reaction-count" v-if="users.length > 1">{{ users.length }}</span>
            </div>
          </div>
        </div>

        <div v-if="isMine && messageReaders.length > 0 && !message.is_deleted" class="readers-preview d-flex align-center justify-end mt-1 pr-1 w-100">
           <v-icon size="14" color="grey-darken-1" class="mr-1">mdi-eye-check-outline</v-icon>
           <span class="text-caption text-grey-darken-1 mr-1 cursor-pointer" style="font-size: 0.65rem !important;">
              {{ messageReaders.slice(0, 3).map(r => r.full_name.split(' ')[0]).join(', ') }}
              <template v-if="messageReaders.length > 3"> e +{{ messageReaders.length - 3 }}</template>
           </span>

           <v-menu location="bottom end" offset="4">
              <template v-slot:activator="{ props }">
                 <v-icon v-bind="props" size="16" color="grey-darken-1" class="cursor-pointer hover-action-blue">mdi-chevron-down</v-icon>
              </template>
              <v-list density="compact" class="elevation-4 rounded-lg border-thin glassmorphism-menu" bg-color="surface" width="220">
                 <v-list-subheader class="text-caption font-weight-bold text-uppercase pb-0">Visto por</v-list-subheader>
                 <v-list-item v-for="reader in messageReaders" :key="reader.id" class="px-3 py-2 border-b border-opacity-10">
                    <template v-slot:prepend>
                       <v-avatar size="28" :image="reader.avatar_url || `https://ui-avatars.com/api/?name=${encodeURIComponent(reader.full_name || 'U')}`" class="mr-3 elevation-1 border-1 border-surface"></v-avatar>
                    </template>
                    <v-list-item-title class="text-body-2 font-weight-medium">{{ reader.full_name }}</v-list-item-title>
                 </v-list-item>
              </v-list>
           </v-menu>
        </div>

      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onUnmounted, onMounted, watch } from 'vue';
import { useUserStore } from '@/stores/user';
import { useChatStore } from '@/stores/chat';
import { supabase } from '@/api/supabase';
import { format, parseISO } from 'date-fns';

const props = defineProps<{
  message: any;
  isConsecutive: boolean;
  searchQuery: string;
  isGroup: boolean;
  allUsers?: any[];
}>();

const emit = defineEmits(['show-menu', 'view-media', 'reply', 'scroll-to', 'info']);
const userStore = useUserStore();
const chatStore = useChatStore();

const isMine = computed(() => props.message.profile_id === userStore.profile?.id);
const isAdminAlert = computed(() => props.message.message_type === 'admin');
const isWhisper = computed(() => props.message.target_users && props.message.target_users.length > 0);
const hasCaption = computed(() => !!props.message.caption && props.message.caption.trim().length > 0);

// INTELIGÊNCIA DE INFERÊNCIA DE LEITURA (Resolve a falta do read_by no banco)
const messageReaders = computed(() => {
    let readBy = props.message.read_by || [];

    // Se a mensagem está como Lida no DB mas não tem ninguém no array (ex: DM)
    if (readBy.length === 0 && props.message.status === 'read' && props.message.channel_id) {
         const channel = chatStore.channels?.find((c: any) => c.id === props.message.channel_id);
         if (channel && channel.is_private_dm && channel.other_participant_id) {
             readBy = [channel.other_participant_id];
         }
    }

    if (!Array.isArray(readBy) || !props.allUsers) return [];

    const otherIds = readBy.filter((id: string) => id !== props.message.profile_id);
    return otherIds.map(id => {
        const user = props.allUsers!.find(u => u.id === id);
        return user || { id, full_name: 'Usuário', avatar_url: '' };
    });
});

const computedStatus = computed(() => {
    if (props.message.status === 'sending' || props.message.status === 'error') {
        return props.message.status;
    }

    // A cor Azul AGORA DEPENDE 100% DE TER ALGUÉM NA LISTA (Ou status explicitly read)
    if (messageReaders.value.length > 0 || props.message.status === 'read') {
        return 'read';
    }

    if (props.message.status === 'delivered') {
        return 'delivered';
    }

    return 'sent';
});


const showReactionMenu = ref(false);
const quickReactions = ['👍', '❤️', '😂', '😮', '😢', '🙏'];
const localReactions = ref(props.message.reactions || {});

watch(() => props.message.reactions, (newVal) => {
   localReactions.value = newVal || {};
}, { deep: true });

const toggleReaction = async (emoji: string) => {
    const myId = userStore.profile?.id;
    if (!myId || props.message.is_deleted) return;

    const current = JSON.parse(JSON.stringify(localReactions.value || {}));
    if (!current[emoji]) current[emoji] = [];

    if (current[emoji].includes(myId)) {
        current[emoji] = current[emoji].filter((id: string) => id !== myId);
        if (current[emoji].length === 0) delete current[emoji];
    } else {
        current[emoji].push(myId);
    }

    localReactions.value = current;

    try {
        const { error } = await supabase.from('messages').update({ reactions: current }).eq('id', props.message.id);
        if (error) console.error("Erro ao salvar reação:", error);
    } catch (e) {
        console.error("Erro na request de reação", e);
    }
    showReactionMenu.value = false;
};

const userColor = computed(() => {
    const str = props.message.profile_id || 'default';
    let hash = 0;
    for (let i = 0; i < str.length; i++) {
        hash = str.charCodeAt(i) + ((hash << 5) - hash);
    }
    const h = Math.abs(hash) % 360;
    return `hsl(${h}, 80%, 35%)`;
});

const detectedType = computed(() => {
  const type = props.message.message_type;
  const content = props.message.content || '';

  if (type === 'system' || !props.message.profile_id) return 'system';
  if (type && type !== 'text') return type;

  if (content.startsWith('http')) {
    const url = content.toLowerCase();
    if (/\.(jpeg|jpg|gif|png|webp|bmp|svg)(\?.*)?$/.test(url)) return 'image';
    if (/\.(mp4|webm|ogg|mov)(\?.*)?$/.test(url)) return 'video';
    if (/\.(mp3|wav|ogg|m4a|weba)(\?.*)?$/.test(url)) return 'audio';
    if (/\.(pdf|doc|docx|xls|xlsx|txt|csv|zip|rar)(\?.*)?$/.test(url)) return 'file';

    if (url.includes('/storage/v1/object/public/')) {
       return 'file';
    }
  }
  return 'text';
});

const isSystem = computed(() => detectedType.value === 'system');
const isImage = computed(() => detectedType.value === 'image');
const isVideo = computed(() => detectedType.value === 'video');
const isFile = computed(() => detectedType.value === 'file' || detectedType.value === 'document');
const isAudio = computed(() => detectedType.value === 'audio');

const isMediaOnly = computed(() => isImage.value || isVideo.value);
const isPng = computed(() => isImage.value && props.message.content?.toLowerCase().includes('.png'));

const repliedMessage = computed(() => {
  if (!props.message.reply_to_message_id) return null;
  if (props.message.reply_to_message) return props.message.reply_to_message;
  return chatStore.messages.find((m: any) => m.id === props.message.reply_to_message_id) || null;
});

const replyAuthor = computed(() => {
  if (!repliedMessage.value) return 'Usuário';
  if (repliedMessage.value.profile_id === userStore.profile?.id) return 'Você';
  return repliedMessage.value.profile?.full_name || 'Contato';
});

const replyText = computed(() => {
  if (!repliedMessage.value) return 'Mensagem';
  if (repliedMessage.value.is_deleted) return '🚫 Mensagem apagada';
  if (repliedMessage.value.message_type === 'image') return '📷 Foto';
  if (repliedMessage.value.message_type === 'video') return '🎥 Vídeo';
  if (repliedMessage.value.message_type === 'audio') return '🎵 Áudio';
  if (repliedMessage.value.message_type === 'file' || repliedMessage.value.message_type === 'document') return '📄 Documento';
  return repliedMessage.value.content || 'Mensagem';
});

const scrollToOriginal = (id: number | string) => {
  emit('scroll-to', id);
};

const touchStartX = ref(0);
const touchStartY = ref(0);
const currentTranslate = ref(0);
const isSwiping = ref(false);

const handleTouchStart = (e: TouchEvent) => {
  if (props.message.is_deleted || isSystem.value || isAdminAlert.value) return;
  touchStartX.value = e.touches[0].clientX;
  touchStartY.value = e.touches[0].clientY;
  isSwiping.value = true;
  currentTranslate.value = 0;
};

const handleTouchMove = (e: TouchEvent) => {
  if (!isSwiping.value) return;
  const currentX = e.touches[0].clientX;
  const currentY = e.touches[0].clientY;
  const diffX = currentX - touchStartX.value;
  const diffY = currentY - touchStartY.value;

  if (Math.abs(diffY) > Math.abs(diffX) && currentTranslate.value === 0) {
    isSwiping.value = false;
    return;
  }

  if (diffX > 0) {
    currentTranslate.value = diffX > 70 ? 70 + (diffX - 70) * 0.2 : diffX;
  }
};

const handleTouchEnd = () => {
  if (currentTranslate.value > 50) {
    if (navigator.vibrate) navigator.vibrate(40);
    emit('reply', props.message);
  }
  isSwiping.value = false;
  currentTranslate.value = 0;
};

const swipeStyle = computed(() => {
  if (currentTranslate.value > 0) {
    return {
      transform: `translateX(${currentTranslate.value}px)`,
      transition: isSwiping.value ? 'none' : 'transform 0.4s cubic-bezier(0.175, 0.885, 0.32, 1.2)'
    };
  }
  return { transition: 'transform 0.4s cubic-bezier(0.175, 0.885, 0.32, 1.2)' };
});

const iconStyle = computed(() => {
  const progress = Math.min(currentTranslate.value / 50, 1);
  return {
    opacity: progress,
    transform: `scale(${0.5 + (progress * 0.5)})`
  };
});

const audioElement = ref<HTMLAudioElement | null>(null);
const isPlaying = ref(false);
const audioCurrentTime = ref('00:00');
const audioDuration = ref('00:00');
const audioProgress = ref(0);
const waveHeights = ref<number[]>([]);
const isExtractingPeaks = ref(false);
const numberOfBars = 35;

const formatSeconds = (secs: number) => {
  if (isNaN(secs) || !isFinite(secs)) return '00:00';
  const m = Math.floor(secs / 60).toString().padStart(2, '0');
  const s = Math.floor(secs % 60).toString().padStart(2, '0');
  return `${m}:${s}`;
};

const extractPeaks = async (url: string) => {
  if (!url) return;
  isExtractingPeaks.value = true;
  try {
    const response = await fetch(url);
    const arrayBuffer = await response.arrayBuffer();
    const audioCtx = new (window.AudioContext || (window as any).webkitAudioContext)();
    const audioBuffer = await audioCtx.decodeAudioData(arrayBuffer);
    const channelData = audioBuffer.getChannelData(0);

    const blockSize = Math.floor(channelData.length / numberOfBars);
    const peaks = [];

    for (let i = 0; i < numberOfBars; i++) {
      let start = blockSize * i;
      let sum = 0;
      for (let j = 0; j < blockSize; j++) {
        sum += Math.abs(channelData[start + j]);
      }
      peaks.push(sum / blockSize);
    }

    const max = Math.max(...peaks);
    waveHeights.value = peaks.map(p => (p / max) * 100);

  } catch (error) {
    waveHeights.value = Array.from({length: numberOfBars}, () => Math.random() * 60 + 20);
  } finally {
    isExtractingPeaks.value = false;
  }
};

onMounted(() => {
  if (isAudio.value && !props.message.is_deleted) {
    extractPeaks(props.message.content);
  }
});

const handleLoadedMetadata = () => {
  if (audioElement.value) {
    if (audioElement.value.duration === Infinity) {
      audioElement.value.currentTime = 1e101;
      setTimeout(() => {
        if(audioElement.value) {
          audioElement.value.currentTime = 0;
          audioDuration.value = formatSeconds(audioElement.value.duration);
        }
      }, 100);
    } else {
      audioDuration.value = formatSeconds(audioElement.value.duration);
    }
  }
};

const resendMsg = () => {
  if (props.message.status === 'error') {
    chatStore.resendMessage(props.message);
  }
};

const handleTimeUpdate = () => {
  if (audioElement.value) {
    audioCurrentTime.value = formatSeconds(audioElement.value.currentTime);
    audioProgress.value = (audioElement.value.currentTime / audioElement.value.duration) * 100;
  }
};

const handleEnded = () => {
  isPlaying.value = false;
  audioProgress.value = 0;
  if (audioElement.value) {
    audioCurrentTime.value = '00:00';
    audioElement.value.currentTime = 0;
  }
};

const toggleAudio = () => {
  if (!audioElement.value) return;
  if (isPlaying.value) {
    audioElement.value.pause();
    isPlaying.value = false;
  } else {
    audioElement.value.play();
    isPlaying.value = true;
  }
};

const seekAudio = (e: MouseEvent) => {
  if (!audioElement.value || !audioElement.value.duration) return;
  const rect = (e.currentTarget as HTMLElement).getBoundingClientRect();
  const clickPosition = e.clientX - rect.left;
  const percentage = clickPosition / rect.width;

  audioElement.value.currentTime = percentage * audioElement.value.duration;
  audioProgress.value = percentage * 100;
};

onUnmounted(() => {
  if (audioElement.value) {
    audioElement.value.pause();
    audioElement.value.currentTime = 0;
  }
});

const formattedTime = computed(() => {
  if (!props.message.created_at) return '';
  return format(parseISO(props.message.created_at), 'HH:mm');
});

const avatarUrl = computed(() => {
  return props.message.profile?.avatar_url || '';
});

const highlightedContent = computed(() => {
  if (!props.message.content) return '';
  let text = props.message.content;

  if (props.searchQuery) {
    const regex = new RegExp(`(${props.searchQuery})`, 'gi');
    text = text.replace(regex, '<mark class="bg-warning text-black px-1 rounded">$1</mark>');
  }

  const urlRegex = /(https?:\/\/[^\s]+)/g;
  return text.replace(urlRegex, '<a href="$1" target="_blank" class="text-primary text-decoration-underline">$1</a>');
});

const highlightedCaption = computed(() => {
  if (!props.message.caption) return '';
  let text = props.message.caption;

  if (props.searchQuery) {
    const regex = new RegExp(`(${props.searchQuery})`, 'gi');
    text = text.replace(regex, '<mark class="bg-warning text-black px-1 rounded">$1</mark>');
  }

  const urlRegex = /(https?:\/\/[^\s]+)/g;
  return text.replace(urlRegex, '<a href="$1" target="_blank" class="text-primary text-decoration-underline">$1</a>');
});

const openMenu = (event: MouseEvent | TouchEvent) => {
  emit('show-menu', { event, message: props.message });
};

const openLink = (url: string) => {
  if (url) window.open(url, '_blank');
};

const viewMedia = (url: string) => {
  if (url) {
    emit('view-media', { url, fileName: extractFileName(url) });
  }
};

const extractFileName = (url: string) => {
  if (!url) return 'Documento';
  try {
    const parts = url.split('/');
    let name = parts[parts.length - 1];
    name = decodeURIComponent(name);
    return name.includes('_') ? name.split('_').slice(1).join('_') : name;
  } catch (e) {
    return 'Documento';
  }
};
</script>

<style lang="scss" scoped>
.message-row {
  display: flex;
  width: 100%;
  margin-bottom: 4px;
  position: relative;

  &:not(.is-consecutive) {
    margin-top: 12px;
  }

  &.is-mine { justify-content: flex-end; }
  &.is-other { justify-content: flex-start; }
  &.is-system {
    justify-content: center;
    margin: 16px 0;
  }
}

.swipe-icon-container {
  position: absolute;
  left: 12px;
  top: 50%;
  transform: translateY(-50%);
  z-index: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  pointer-events: none;
}

.bubble-wrapper {
  position: relative;
  z-index: 2;
  width: 100%;
  will-change: transform;
}

.system-message {
  padding: 6px 16px;
  border-radius: 12px;
  font-size: 0.75rem;
  font-weight: 500;
  text-align: center;
  max-width: 85%;

  background-color: rgba(255, 255, 255, 0.85);
  backdrop-filter: blur(8px);
  -webkit-backdrop-filter: blur(8px);
  color: rgba(0, 0, 0, 0.8);
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.08), 0 0 0 1px rgba(255, 255, 255, 0.4) inset;

  @media (prefers-color-scheme: dark) {
    background-color: rgba(30, 41, 59, 0.75);
    color: rgba(255, 255, 255, 0.9);
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.3), 0 0 0 1px rgba(255, 255, 255, 0.05) inset;
  }
}

.admin-alert-message {
  padding: 8px 20px;
  border-radius: 8px;
  font-size: 0.85rem;
  font-weight: 700;
  text-align: center;
  max-width: 90%;
  background: linear-gradient(135deg, #d32f2f, #b71c1c);
  color: white;
  border-left: 6px solid #ffeb3b;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.message-bubble {
  position: relative;
  max-width: 65%;
  padding: 6px 8px;
  border-radius: 16px;
  box-shadow: 0 2px 5px rgba(0,0,0,0.1), inset 0 1px 1px rgba(255,255,255,0.2);
  display: flex;
  flex-direction: column;
  word-wrap: break-word;
  backdrop-filter: blur(10px);
  -webkit-backdrop-filter: blur(10px);

  @media (max-width: 768px) {
    max-width: 85%;
  }

  .is-mine & {
    background-color: rgba(217, 253, 211, 0.95);
    color: #111b21;
    border-top-right-radius: 4px;

    &.is-consecutive { border-top-right-radius: 16px; }

    @media (prefers-color-scheme: dark) {
      background-color: rgba(0, 92, 75, 0.92);
      color: #e9edef;
      box-shadow: 0 2px 5px rgba(0,0,0,0.3), inset 0 1px 1px rgba(255,255,255,0.05);
    }
  }

  .is-other & {
    background-color: rgba(255, 255, 255, 0.95);
    color: #111b21;
    border-top-left-radius: 4px;

    &.is-consecutive { border-top-left-radius: 16px; }

    @media (prefers-color-scheme: dark) {
      background-color: rgba(32, 44, 51, 0.92);
      color: #e9edef;
      box-shadow: 0 2px 5px rgba(0,0,0,0.3), inset 0 1px 1px rgba(255,255,255,0.05);
    }
  }

  &.media-bubble {
    padding: 2px; background-color: transparent !important;
    box-shadow: none; backdrop-filter: none;
  }

  &.png-bubble {
    background: transparent !important; box-shadow: none !important;
    padding: 0 !important; backdrop-filter: none;
  }

  &.media-with-caption { padding: 4px; }
  &.audio-bubble { width: 320px; padding: 6px 10px; @media (max-width: 768px) { width: 290px; } }

  &.is-whisper {
      border: 2px dashed #9c27b0;
      background-color: rgba(243, 229, 245, 0.95) !important;

      .whisper-header {
          font-size: 0.65rem; color: #7b1fa2; font-weight: bold; text-transform: uppercase;
          margin-bottom: 4px; display: flex; align-items: center; border-bottom: 1px solid rgba(156, 39, 176, 0.2); padding-bottom: 2px;
      }
  }
}

.sender-name { line-height: 1.2; }
.message-text { font-size: 0.95rem; line-height: 1.4; padding: 2px 4px 6px 4px; }
.caption-text { font-size: 0.95rem; line-height: 1.4; padding: 6px 6px 4px 6px; }
.text-content { white-space: pre-wrap; }
.meta-spacer { display: inline-block; width: 75px; height: 12px; background: transparent; }
.deleted-message { padding-right: 48px; }

.message-meta {
  position: absolute; bottom: 4px; right: 8px; display: flex; align-items: center;
  font-size: 0.65rem; color: rgba(0, 0, 0, 0.45);
  @media (prefers-color-scheme: dark) { color: rgba(255, 255, 255, 0.6); }

  &.meta-overlay {
    bottom: 8px; right: 8px; background-color: rgba(0, 0, 0, 0.4); padding: 2px 6px; border-radius: 12px; color: white;
    @media (prefers-color-scheme: dark) { color: white; }
  }

  &.meta-png { text-shadow: 1px 1px 2px rgba(0,0,0,0.8); color: white !important; }
}

.edited-text { font-size: 0.6rem; font-style: italic; opacity: 0.8; }
.time { margin-top: 2px; }

/* FIX DEFINITIVO DOS TICKS DE STATUS */
.status-icon { color: #9e9e9e !important; }
.status-icon.text-blue { color: #2196F3 !important; }

.reply-block {
  display: flex; background-color: rgba(0, 0, 0, 0.05); border-radius: 8px; margin-bottom: 6px; overflow: hidden;
  border-left: 4px solid rgb(var(--v-theme-primary)); max-height: 50px;
  @media (prefers-color-scheme: dark) { background-color: rgba(255, 255, 255, 0.05); }
}

.reply-thumb-wrapper { width: 50px; height: 50px; flex-shrink: 0; position: relative; }
.reply-thumb { width: 100%; height: 100%; object-fit: cover; }
.video-overlay { position: absolute; top: 0; left: 0; right: 0; bottom: 0; display: flex; align-items: center; justify-content: center; background-color: rgba(0,0,0,0.3); }

.reply-content { padding: 6px 10px; display: flex; flex-direction: column; min-width: 0; justify-content: center; }
.reply-author { font-size: 0.8rem; margin-bottom: 2px; }
.reply-text { font-size: 0.8rem; opacity: 0.8; }

.media-container { border-radius: 12px; overflow: hidden; position: relative; min-width: 200px; min-height: 200px; }
.media-image { width: 100%; max-width: 350px; max-height: 350px; object-fit: contain; border-radius: 12px; display: block; }

.rounded-bottom-0 { border-bottom-left-radius: 0 !important; border-bottom-right-radius: 0 !important; }
.video-wrapper { width: 100%; height: 250px; border-radius: 12px; position: relative; }
.video-duration { position: absolute; bottom: 8px; left: 8px; color: white; background: rgba(0,0,0,0.5); padding: 2px 6px; border-radius: 8px; }

.document-container {
  display: flex; align-items: center; background-color: rgba(0, 0, 0, 0.05); padding: 8px; border-radius: 10px; margin-bottom: 2px;
  @media (prefers-color-scheme: dark) { background-color: rgba(255, 255, 255, 0.05); }
}

.doc-icon-box { width: 48px; height: 48px; background-color: #ff5252; border-radius: 8px; display: flex; justify-content: center; align-items: center; flex-shrink: 0; margin-right: 12px; }

.audio-container { width: 100%; }
.audio-timeline { height: 28px; display: flex; align-items: center; }
.play-btn { color: currentColor !important; }

.waveform-layer { position: absolute; top: 50%; transform: translateY(-50%); display: flex; align-items: center; gap: 2px; height: 20px; }

.bg-layer { width: 100%; }
.fg-layer {
  left: 0; overflow: hidden; transition: width 0.1s linear; color: rgb(var(--v-theme-primary));
  .is-mine & { color: #0b937f; }
}

.wave-bar { width: 3px; border-radius: 2px; flex-shrink: 0; background-color: currentColor; opacity: 0.3; &.active { opacity: 1; } }

.opacity-70 { opacity: 0.7; }

/* ========================================= */
/* HOVER ACTIONS - CORES BLINDADAS (BRANCO/CINZA E AZUL) */
/* ========================================= */
.hover-actions-container {
  position: absolute; top: 2px; right: 6px; display: flex; align-items: center; gap: 4px;
  z-index: 5; opacity: 0; transition: opacity 0.2s;
}

.message-bubble:hover .hover-actions-container { opacity: 1; }
@media (max-width: 768px) { .hover-actions-container { opacity: 1 !important; } }

.hover-action-btn {
  display: flex; align-items: center; justify-content: center; cursor: pointer;
  background: rgba(255, 255, 255, 0.95) !important;
  backdrop-filter: blur(4px);
  border-radius: 50%; width: 26px; height: 26px;
  border: 1px solid rgba(0, 0, 0, 0.05);
  box-shadow: 0 2px 8px rgba(0,0,0,0.08);

  /* Branco acinzentado forçado */
  color: #9e9e9e !important;
  transition: all 0.2s cubic-bezier(0.25, 0.8, 0.25, 1);
}

.icon-force-gray {
  color: #9e9e9e !important;
  transition: color 0.2s !important;
}

/* Hover Azul Apple/Shopify */
.hover-action-btn:hover {
   transform: scale(1.15) translateY(-2px);
   background: rgba(255, 255, 255, 1) !important;
   color: #2196F3 !important;
   box-shadow: 0 4px 12px rgba(33, 150, 243, 0.2);
}

.hover-action-btn:hover .icon-force-gray {
   color: #2196F3 !important;
}

/* Ajuste Dark Mode */
@media (prefers-color-scheme: dark) {
  .hover-action-btn {
    background: rgba(40, 40, 45, 0.8) !important;
    border: 1px solid rgba(255, 255, 255, 0.1);
  }
  .hover-action-btn, .icon-force-gray {
    color: #b0bec5 !important;
  }

  .hover-action-btn:hover, .hover-action-btn:hover .icon-force-gray {
     color: #4fc3f7 !important;
  }
}

.hover-action-blue { transition: color 0.2s; }
.hover-action-blue:hover { color: #2196F3 !important; }

.quick-reactions-bar { display: flex; border-radius: 24px; padding: 6px 12px; gap: 8px; }

.glassmorphism-menu {
  backdrop-filter: blur(12px); -webkit-backdrop-filter: blur(12px);
  background-color: rgba(var(--v-theme-surface), 0.95) !important;
}

.quick-emoji { font-size: 1.25rem; cursor: pointer; transition: transform 0.2s; &:hover { transform: scale(1.3) translateY(-2px); } }

.reactions-display { display: flex; flex-wrap: wrap; gap: 4px; position: absolute; bottom: -10px; left: 8px; z-index: 3; }

.reaction-pill {
  display: flex; align-items: center; background: rgba(255,255,255, 0.95); border: 1px solid rgba(0,0,0,0.05);
  box-shadow: 0 1px 2px rgba(0,0,0,0.1); border-radius: 12px; padding: 2px 6px; font-size: 0.75rem; cursor: pointer; user-select: none;
  transition: transform 0.1s, background-color 0.2s;

  &.mine { background: rgba(var(--v-theme-primary), 0.1); border: 1px solid rgba(var(--v-theme-primary), 0.3); }
  &:hover { transform: scale(1.05); }

  @media (prefers-color-scheme: dark) {
    background: rgba(30,40,50, 0.95); border: 1px solid rgba(255,255,255,0.05); box-shadow: 0 1px 2px rgba(0,0,0,0.3);
    &.mine { background: rgba(var(--v-theme-primary), 0.2); }
  }
}
.reaction-count {
  margin-left: 4px; font-weight: 600; color: rgba(0,0,0,0.6);
  @media (prefers-color-scheme: dark) { color: rgba(255,255,255,0.7); }
}
</style>
