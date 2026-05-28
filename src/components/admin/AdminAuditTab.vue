<template>
  <div class="admin-chat-audit-container" :class="{ 'is-mobile': isMobile }">

    <aside v-show="!isMobile || !activeChannel" class="audit-sidebar bg-surface border-e d-flex flex-column h-100">
      <div class="pa-3 border-b d-flex flex-column gap-2 bg-surface-variant-light flex-shrink-0">
        <div class="d-flex align-center gap-2 mb-1 pl-1">
            <v-icon color="primary" size="24">mdi-shield-crown</v-icon>
            <h2 class="text-subtitle-1 font-weight-black text-grey-darken-3 mb-0 lh-1">Comando de Chat</h2>
        </div>

        <v-text-field
          v-model="channelSearch"
          placeholder="Buscar conversa..."
          variant="solo-filled"
          flat
          hide-details
          density="compact"
          prepend-inner-icon="mdi-magnify"
          clearable
          class="compact-input"
        ></v-text-field>

        <v-autocomplete
          v-model="userFilter"
          :items="allProfilesList"
          item-title="full_name"
          item-value="id"
          placeholder="Filtrar por participante..."
          variant="solo-filled"
          flat
          hide-details
          density="compact"
          prepend-inner-icon="mdi-account-filter"
          clearable
          class="compact-input"
        >
          <template v-slot:item="{ props, item }">
            <v-list-item v-bind="props">
              <template v-slot:prepend>
                <v-avatar size="24" class="mr-2 border">
                  <v-img v-if="item.raw.avatar_url" :src="item.raw.avatar_url"></v-img>
                  <span v-else class="text-[10px] font-weight-bold">{{ item.raw.full_name?.charAt(0) }}</span>
                </v-avatar>
              </template>
            </v-list-item>
          </template>
        </v-autocomplete>
      </div>

      <div class="sidebar-list-container flex-grow-1 overflow-y-auto custom-scrollbar px-1 py-2">
        <div v-if="filteredChannels.length === 0" class="text-center pa-4 text-caption text-grey">
            Nenhuma conversa atende aos filtros atuais.
        </div>
        <v-list nav class="pa-0 bg-transparent">
          <v-list-item
            v-for="channel in filteredChannels"
            :key="channel.id"
            @click="selectChannel(channel)"
            :active="activeChannel?.id === channel.id"
            lines="two"
            active-color="primary"
            class="mb-1 rounded-lg transition-all"
          >
            <template v-slot:prepend>
              <v-badge :model-value="channel.is_locked" color="error" icon="mdi-lock" location="bottom right" offset-x="3" offset-y="3">
                 <v-avatar size="40" :color="channel.is_deleted ? 'error' : (channel.is_private_dm ? 'blue-lighten-4' : 'grey-lighten-3')">
                   <v-img v-if="channel.icon_image_url" :src="channel.icon_image_url" cover></v-img>
                   <v-icon v-else :color="channel.is_deleted ? 'white' : 'blue-darken-2'" :icon="channel.is_private_dm ? 'mdi-account-multiple' : 'mdi-account-group'"></v-icon>
                 </v-avatar>
              </v-badge>
            </template>
            <v-list-item-title class="font-weight-bold text-body-2 text-grey-darken-3">
               {{ getChannelName(channel) }}
            </v-list-item-title>
            <v-list-item-subtitle class="text-caption d-flex align-center mt-1">
              <v-icon size="12" class="mr-1" :color="channel.is_deleted ? 'error' : 'grey'">
                 {{ channel.is_deleted ? 'mdi-delete' : (channel.is_private_dm ? 'mdi-message-text' : 'mdi-forum') }}
              </v-icon>
              <span :class="{'text-error font-weight-medium': channel.is_deleted}">
                 {{ channel.is_deleted ? 'Canal Apagado' : (channel.is_private_dm ? 'Chat Direto' : 'Grupo') }}
              </span>
            </v-list-item-subtitle>
          </v-list-item>
        </v-list>
      </div>
    </aside>

    <component :is="isMobile ? 'Teleport' : 'div'" :to="isMobile ? 'body' : null" class="h-100 flex-grow-1 min-w-0">
      <v-slide-x-reverse-transition>
        <main
          v-if="showChat"
          class="audit-main bg-surface d-flex flex-column h-100 position-relative"
          :class="{ 'mobile-fullscreen': isMobile }"
        >

          <div v-if="!activeChannel" class="d-flex flex-column align-center justify-center fill-height text-medium-emphasis w-100">
              <v-avatar color="grey-lighten-4" size="80" class="mb-4">
                  <v-icon size="40" color="grey">mdi-shield-search</v-icon>
              </v-avatar>
              <p class="text-h6 font-weight-bold text-grey-darken-2">Modo Sentinela</p>
              <p class="text-body-2">Selecione uma conversa ao lado para auditar.</p>
          </div>

          <template v-else>
              <header class="chat-header d-flex align-center px-3 py-2 border-b bg-white flex-shrink-0 z-10 shadow-sm w-100">
                  <v-btn v-if="isMobile" icon="mdi-arrow-left" variant="text" size="small" class="mr-2" @click="activeChannel = null"></v-btn>

                  <div class="flex-grow-1 min-w-0 d-flex flex-column justify-center">
                      <div class="d-flex align-center">
                         <h3 class="text-subtitle-1 font-weight-black mb-0 text-truncate lh-1">{{ getChannelName(activeChannel) }}</h3>
                         <v-chip v-if="activeChannel.is_locked" color="error" size="x-small" class="ml-2 font-weight-bold" prepend-icon="mdi-lock">BLOQUEADO</v-chip>
                      </div>

                      <div class="d-flex align-center mt-1">
                         <span class="text-[10px] text-grey font-weight-bold mr-2 text-uppercase">{{ activeParticipants.length }} MEMBROS:</span>
                         <div class="d-flex flex-wrap gap-1 align-center max-w-[60%]">
                             <v-tooltip v-for="p in activeParticipants.slice(0, 8)" :key="p.id" location="bottom">
                                 <template v-slot:activator="{ props }">
                                     <v-avatar v-bind="props" size="20" class="border cursor-pointer">
                                         <v-img v-if="p.avatar_url" :src="p.avatar_url"></v-img>
                                         <span v-else class="text-[9px] font-weight-bold bg-grey-lighten-2 w-100 h-100 d-flex align-center justify-center">{{ p.full_name?.charAt(0) }}</span>
                                     </v-avatar>
                                 </template>
                                 <span>{{ p.full_name }}</span>
                             </v-tooltip>
                             <span v-if="activeParticipants.length > 8" class="text-[10px] text-grey ml-1 font-weight-bold">+{{ activeParticipants.length - 8 }}</span>
                         </div>
                      </div>
                  </div>

                  <div class="d-flex align-center gap-2">
                      <v-btn
                         :color="activeChannel.is_locked ? 'success' : 'warning'"
                         variant="tonal"
                         size="small"
                         :prepend-icon="activeChannel.is_locked ? 'mdi-lock-open-variant' : 'mdi-lock'"
                         @click="toggleChatLock"
                         :disabled="activeChannel.is_deleted"
                         class="font-weight-bold hidden-sm-and-down"
                      >
                         {{ activeChannel.is_locked ? 'Desbloquear' : 'Silenciar Chat' }}
                      </v-btn>

                      <v-btn
                         v-if="isMobile"
                         :color="activeChannel.is_locked ? 'success' : 'warning'"
                         variant="tonal"
                         size="small"
                         icon
                         @click="toggleChatLock"
                         :disabled="activeChannel.is_deleted"
                      >
                         <v-icon>{{ activeChannel.is_locked ? 'mdi-lock-open-variant' : 'mdi-lock' }}</v-icon>
                      </v-btn>

                      <v-btn
                         v-if="!isIntervening"
                         color="error"
                         variant="flat"
                         size="small"
                         prepend-icon="mdi-account-hard-hat"
                         @click="ativarIntervencao"
                         :disabled="activeChannel.is_deleted"
                         class="font-weight-bold"
                      >
                         Intervir
                      </v-btn>
                  </div>
              </header>

              <div ref="messagesContainer" class="messages-area flex-grow-1 overflow-y-auto custom-scrollbar pattern-bg pa-3 pa-md-6 w-100">

                   <div v-if="loadingMessages" class="d-flex justify-center py-8">
                       <v-progress-circular indeterminate color="primary"></v-progress-circular>
                   </div>

                   <div v-else-if="messages.length === 0" class="text-center py-8 text-grey font-italic">
                      Nenhuma atividade registrada nesta conversa.
                   </div>

                   <div v-else class="d-flex flex-column gap-3">
                       <div
                          v-for="msg in messages"
                          :key="msg.id"
                          class="audit-bubble pa-3 rounded-xl position-relative d-flex gap-3 shadow-sm"
                          :class="getBubbleClasses(msg)"
                          :style="{ maxWidth: isMobile ? '90%' : '75%' }"
                       >
                          <v-avatar v-if="msg.message_type !== 'admin'" size="32" color="grey-lighten-3" class="flex-shrink-0 mt-1 elevation-1">
                              <v-img v-if="msg.profiles?.avatar_url" :src="msg.profiles.avatar_url" />
                              <span v-else class="text-caption font-weight-bold">{{ msg.profiles?.full_name?.charAt(0) || 'U' }}</span>
                          </v-avatar>

                          <div class="flex-grow-1 min-w-0">
                              <div class="d-flex align-center justify-space-between mb-1 gap-2 border-b pb-1">
                                  <span v-if="msg.message_type === 'admin'" class="font-weight-black text-[13px] text-white d-flex align-center">
                                      <v-icon size="16" class="mr-1">mdi-alert-decagram</v-icon> ALERTA DA ADMINISTRAÇÃO
                                  </span>
                                  <span v-else class="font-weight-bold text-[13px]" :class="msg.profile_id === userStore.profile?.id ? 'text-primary' : 'text-grey-darken-3'">
                                      {{ msg.profiles?.full_name || 'Usuário Desconhecido' }}
                                  </span>

                                  <div class="d-flex align-center gap-2">
                                      <span class="text-[10px]" :class="msg.message_type === 'admin' ? 'text-white opacity-80' : 'text-grey'">{{ formatDate(msg.created_at) }}</span>
                                      <v-btn
                                          v-if="isIntervening && !msg.is_deleted"
                                          icon="mdi-delete-empty"
                                          variant="text"
                                          :color="msg.message_type === 'admin' ? 'white' : 'error'"
                                          size="x-small"
                                          density="comfortable"
                                          v-tooltip="'Apagar à força'"
                                          @click="deleteMessage(msg.id)"
                                      ></v-btn>
                                  </div>
                              </div>

                              <div v-if="msg.target_users && msg.target_users.length > 0" class="text-[10px] text-purple-darken-2 font-weight-bold mb-2 mt-1 d-flex align-center bg-purple-lighten-5 pa-1 rounded">
                                  <v-icon size="12" class="mr-1">mdi-eye-off</v-icon>
                                  Sussurro para: {{ getTargetNames(msg.target_users) }}
                              </div>

                              <div v-if="!msg.is_deleted">
                                 <div v-if="getMediaType(msg.content) !== 'text'" class="mt-2 mb-2">
                                     <img v-if="getMediaType(msg.content) === 'image'" :src="msg.content" class="rounded-lg border bg-white" style="max-width: 100%; max-height: 300px; object-fit: contain;">
                                     <video v-else-if="getMediaType(msg.content) === 'video'" :src="msg.content" controls class="rounded-lg border bg-black" style="max-width: 100%; max-height: 300px;"></video>
                                     <audio v-else-if="getMediaType(msg.content) === 'audio'" :src="msg.content" controls class="w-100 mt-1"></audio>
                                     <a v-else :href="msg.content" target="_blank" class="d-inline-flex align-center gap-1 text-decoration-none bg-grey-lighten-4 pa-3 rounded-lg text-body-2 text-primary border w-100">
                                        <v-icon size="24">mdi-file-document-outline</v-icon>
                                        <div>
                                           <strong class="d-block text-black">Arquivo de Documento</strong>
                                           <span class="text-[10px] text-grey">Clique para baixar/abrir</span>
                                        </div>
                                     </a>
                                 </div>

                                 <p v-else class="text-[14px] mb-0" :class="msg.message_type === 'admin' ? 'text-white font-weight-medium' : 'text-grey-darken-3'" style="white-space: pre-wrap; line-height: 1.4;">{{ msg.content }}</p>

                                 <div v-if="msg.is_edited" class="pa-2 rounded mt-2 text-[11px] border" :class="msg.message_type === 'admin' ? 'bg-white text-error border-white opacity-90' : 'bg-orange-50 text-orange-darken-4 border-orange-200'">
                                    <v-icon size="12" class="mr-1 mb-1">mdi-pencil-clock</v-icon>
                                    <strong>Texto Original:</strong><br><span class="font-italic">"{{ msg.original_content }}"</span>
                                  </div>
                              </div>

                              <div v-else class="bg-red-50 text-red-darken-4 pa-2 rounded mt-1 text-[11px] border border-red-200">
                                <v-icon size="12" class="mr-1 mb-1">mdi-delete-clock</v-icon>
                                <strong class="text-uppercase">Mensagem Interceptada (Apagada):</strong><br>
                                <span v-if="getMediaType(msg.original_content) !== 'text'">
                                   Anexo removido: <a :href="msg.original_content" target="_blank" class="text-red-darken-4 text-decoration-underline font-weight-bold">Abrir Mídia Oculta</a>
                                </span>
                                <span v-else class="font-italic">"{{ msg.original_content || 'Sem registro anterior' }}"</span>
                              </div>
                          </div>
                       </div>
                   </div>
              </div>

              <v-slide-y-reverse-transition>
                  <div v-if="isIntervening" class="pa-3 border-t bg-white flex-shrink-0 z-10 shadow-sm w-100">
                      <div class="d-flex align-center gap-2 mb-2 px-1 flex-wrap">
                         <v-switch
                           v-model="sendAsAdminAlert"
                           color="error"
                           density="compact"
                           hide-details
                           inset
                         >
                           <template v-slot:label>
                              <span class="text-caption font-weight-bold text-error d-flex align-center">
                                 <v-icon size="16" class="mr-1">mdi-alert-decagram</v-icon> <span class="hidden-xs">Alerta de Sistema</span>
                              </span>
                           </template>
                         </v-switch>

                         <v-divider vertical class="mx-1 hidden-xs"></v-divider>

                         <div style="flex: 1; min-width: 150px;" v-if="!sendAsAdminAlert">
                            <v-select
                               v-model="whisperTargets"
                               :items="activeParticipants"
                               item-title="full_name"
                               item-value="id"
                               label="Sussurrar para..."
                               multiple
                               chips
                               closable-chips
                               density="compact"
                               hide-details
                               variant="solo-filled"
                               flat
                               class="bg-grey-lighten-4 border rounded-lg compact-select"
                               prepend-inner-icon="mdi-eye-off"
                            >
                               <template v-slot:selection="{ item, index }">
                                   <v-chip v-if="index < 1" size="x-small" color="purple-darken-2" variant="flat">{{ item.title.split(' ')[0] }}</v-chip>
                                   <span v-if="index === 1" class="text-[10px] text-grey ml-1">(+{{ whisperTargets.length - 1 }})</span>
                               </template>
                            </v-select>
                         </div>
                      </div>

                      <div class="d-flex align-end gap-2 pa-1" :class="sendAsAdminAlert ? 'admin-input-wrapper' : (whisperTargets.length > 0 ? 'whisper-input-wrapper' : 'normal-input-wrapper')">
                          <v-textarea
                              v-model="newMessage"
                              :placeholder="sendAsAdminAlert ? 'ALERTA CRÍTICO PARA TODOS...' : (whisperTargets.length > 0 ? 'Sussurro secreto...' : 'Mensagem pública...')"
                              variant="solo"
                              flat
                              hide-details
                              auto-grow
                              rows="1"
                              max-rows="4"
                              density="compact"
                              class="flex-grow-1 compact-textarea"
                              @keydown.enter.exact.prevent="sendAdminMessage"
                          ></v-textarea>

                          <v-btn
                             :color="sendAsAdminAlert ? 'error' : (whisperTargets.length > 0 ? 'purple-darken-2' : 'primary')"
                             :icon="sendAsAdminAlert ? 'mdi-bullhorn' : (whisperTargets.length > 0 ? 'mdi-incognito' : 'mdi-send')"
                             variant="flat"
                             class="flex-shrink-0 mb-1 pulse-btn"
                             @click="sendAdminMessage"
                             :loading="sending"
                          ></v-btn>
                      </div>
                  </div>
              </v-slide-y-reverse-transition>
          </template>
        </main>
      </v-slide-x-reverse-transition>
    </component>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, computed, nextTick } from 'vue';
import { supabase } from '@/api/supabase';
import { format } from 'date-fns';
import { ptBR } from 'date-fns/locale';
import { useUserStore } from '@/stores/user';

const userStore = useUserStore();
const isMobile = ref(window.innerWidth <= 768);
const handleResize = () => { isMobile.value = window.innerWidth <= 768; };

type Channel = { id: number; name: string; icon_image_url: string | null; is_private_dm: boolean; is_deleted: boolean; dm_participant_ids: string[]; is_locked: boolean };
type Message = { id: number; content: string; original_content: string; created_at: string; is_deleted: boolean; is_edited: boolean; profile_id: string; message_type: string; target_users: string[] | null; profiles: { full_name: string; avatar_url: string } };

const channels = ref<Channel[]>([]);
const messages = ref<Message[]>([]);
const activeParticipants = ref<any[]>([]);

const allProfilesList = ref<any[]>([]);
const profilesMap = ref(new Map<string, { full_name: string, avatar_url: string }>());
const channelMembersMap = ref(new Map<number, Set<string>>());
const channelSearch = ref('');
const userFilter = ref<string | null>(null);

const activeChannel = ref<Channel | null>(null);
const loadingMessages = ref(false);

const isIntervening = ref(false);
const sendAsAdminAlert = ref(false);
const whisperTargets = ref<string[]>([]);
const newMessage = ref('');
const sending = ref(false);
const messagesContainer = ref<HTMLElement | null>(null);

const showSidebar = computed(() => !isMobile.value || !activeChannel.value);
const showChat = computed(() => !isMobile.value || !!activeChannel.value);

const filteredChannels = computed(() => {
  let result = channels.value;
  if (channelSearch.value) {
      const searchLower = channelSearch.value.toLowerCase();
      result = result.filter(c => getChannelName(c).toLowerCase().includes(searchLower));
  }
  if (userFilter.value) {
      result = result.filter(c => {
          const membersSet = channelMembersMap.value.get(c.id);
          return membersSet && membersSet.has(userFilter.value!);
      });
  }
  return result;
});

onMounted(async () => {
  window.addEventListener('resize', handleResize);
  console.log('[AUDIT - INIT] Iniciando auditoria...');

  const { data: profilesData } = await supabase.from('profiles').select('id, full_name, avatar_url');
  if (profilesData) {
      allProfilesList.value = profilesData;
      profilesData.forEach(p => profilesMap.value.set(p.id, p));
  }

  const { data: allMembers } = await supabase.from('admin_channel_members').select('channel_id, profile_id');
  if (allMembers) {
      allMembers.forEach(m => {
          if (!channelMembersMap.value.has(m.channel_id)) channelMembersMap.value.set(m.channel_id, new Set());
          channelMembersMap.value.get(m.channel_id)!.add(m.profile_id);
      });
  }

  const { data } = await supabase.from('admin_channels').select('*').order('created_at', { ascending: false });
  channels.value = data || [];
});

const getChannelName = (channel: Channel): string => {
    if (!channel.is_private_dm) return channel.name || 'Grupo';
    if (!channel.dm_participant_ids || channel.dm_participant_ids.length === 0) return 'Chat Privado';
    return channel.dm_participant_ids.map(id => (profilesMap.value.get(id)?.full_name || 'Desconhecido').split(' ')[0]).join(' & ');
};

const getTargetNames = (targetIds: string[]) => {
    if (!targetIds) return '';
    return targetIds.map(id => (profilesMap.value.get(id)?.full_name || 'Desconhecido').split(' ')[0]).join(', ');
};

const getMediaType = (content: string) => {
    if (!content || !content.startsWith('http')) return 'text';
    const url = content.toLowerCase();
    if (/\.(jpeg|jpg|gif|png|webp|svg)(\?.*)?$/.test(url)) return 'image';
    if (/\.(mp4|webm|ogg|mov)(\?.*)?$/.test(url)) return 'video';
    if (/\.(mp3|wav|ogg|m4a|weba|opus)(\?.*)?$/.test(url)) return 'audio';
    return 'file';
};

const selectChannel = async (channel: Channel) => {
  console.log(`[AUDIT - SELECT] Abrindo canal ID ${channel.id}`);
  activeChannel.value = channel;
  isIntervening.value = false;
  sendAsAdminAlert.value = false;
  whisperTargets.value = [];
  newMessage.value = '';

  const { data: members } = await supabase.from('admin_channel_members').select('profile_id, profiles(id, full_name, avatar_url)').eq('channel_id', channel.id);
  activeParticipants.value = members?.map(m => m.profiles).filter(Boolean) || [];

  await fetchMessages();
};

const fetchMessages = async () => {
    if(!activeChannel.value) return;
    loadingMessages.value = true;

    const { data } = await supabase.from('admin_messages')
        .select('*, profiles(full_name, avatar_url)')
        .eq('channel_id', activeChannel.value.id)
        .order('created_at', { ascending: true });

    messages.value = data as any;
    loadingMessages.value = false;
    scrollToBottom();
};

const toggleChatLock = async () => {
    if(!activeChannel.value || !userStore.profile?.id) return;
    const isLocking = !activeChannel.value.is_locked;
    if(!confirm(`Tem certeza que deseja ${isLocking ? 'BLOQUEAR' : 'DESBLOQUEAR'} este chat?`)) return;

    await supabase.from('channels').update({ is_locked: isLocking }).eq('id', activeChannel.value.id);
    activeChannel.value.is_locked = isLocking;

    await supabase.from('messages').insert({
        content: isLocking ? '🔒 A ADMINISTRAÇÃO BLOQUEOU ESTE CHAT. Apenas moderadores podem enviar mensagens.' : '🔓 A ADMINISTRAÇÃO DESBLOQUEOU O CHAT. Envios liberados.',
        channel_id: activeChannel.value.id,
        profile_id: userStore.profile.id,
        message_type: 'admin'
    });

    await fetchMessages();
};

const ativarIntervencao = async () => {
   if (!activeChannel.value || !userStore.profile?.id) return;
   console.log(`[AUDIT - INTERVENÇÃO] Injetando Admin no grupo...`);
   const { error } = await supabase.from('channel_members').upsert({ channel_id: activeChannel.value.id, profile_id: userStore.profile.id }, { onConflict: 'channel_id,profile_id' });
   if(!error){
       isIntervening.value = true;
       scrollToBottom();
   } else {
       alert("Erro de permissão: " + error.message);
   }
};

const sendAdminMessage = async () => {
    if (!newMessage.value.trim() || !activeChannel.value || !userStore.profile?.id) return;
    sending.value = true;

    const payload = {
        content: newMessage.value.trim(),
        channel_id: activeChannel.value.id,
        profile_id: userStore.profile.id,
        message_type: sendAsAdminAlert.value ? 'admin' : 'text',
        target_users: whisperTargets.value.length > 0 ? whisperTargets.value : null
    };

    console.log('[AUDIT - ENVIO] Disparando:', payload);
    const { error } = await supabase.from('messages').insert(payload);

    if(!error) {
        newMessage.value = '';
        whisperTargets.value = [];
        await fetchMessages();
    } else {
        alert("Falha: " + error.message);
    }
    sending.value = false;
};

const deleteMessage = async (msgId: number) => {
    if (!confirm("Apagar à força para todos?")) return;
    await supabase.from('messages').update({ is_deleted: true, content: '[MENSAGEM INTERCEPTADA PELA AUDITORIA]' }).eq('id', msgId);
    await fetchMessages();
};

const getBubbleClasses = (msg: Message) => {
    if (msg.message_type === 'admin') return 'admin-alert-msg align-self-center w-100 mt-4 mb-4 mx-4';
    let classes = msg.profile_id === userStore.profile?.id ? 'bg-primary-lighten-5 border-primary align-self-end' : 'bg-white border-grey align-self-start';
    if (msg.target_users && msg.target_users.length > 0) classes += ' is-whisper';
    return classes;
};

const scrollToBottom = () => {
    nextTick(() => {
        if (messagesContainer.value) messagesContainer.value.scrollTop = messagesContainer.value.scrollHeight;
    });
};

const formatDate = (dateString: string) => format(new Date(dateString), "dd/MM/yy HH:mm", { locale: ptBR });
</script>

<style scoped lang="scss">
/* ========================================= */
/* A TRAVA MESTRE DO SCROLL (IGUAL O CHAT)   */
/* ========================================= */
.admin-chat-audit-container {
    width: 100%;
    /* Altura cravada subtraindo os cabeçalhos fixos do Admin Vue */
    height: calc(100vh - 165px);
    display: flex;
    flex-direction: row;
    overflow: hidden; /* Proíbe o vazamento de layout */

    &.is-mobile { flex-direction: column; height: 100%; }
}

.audit-sidebar {
    width: 340px;
    flex-shrink: 0;
    .is-mobile & { width: 100%; }
}

/* Campos compactos na barra lateral para economizar espaço */
.compact-input :deep(.v-field__input) {
    min-height: 36px !important;
    padding-top: 4px;
    padding-bottom: 4px;
}

.audit-main {
    flex: 1 1 auto;
    display: flex;
    flex-direction: column;
    min-width: 0;
    height: 100%;
    overflow: hidden; /* Chave do sucesso do flex */
}

/* SOBREPOSIÇÃO TELA CHEIA PARA MOBILE */
.mobile-fullscreen {
    position: fixed !important;
    top: 0 !important;
    left: 0 !important;
    right: 0 !important;
    bottom: 0 !important;
    height: 100dvh !important;
    width: 100vw !important;
    z-index: 9999999 !important;
    background-color: rgb(var(--v-theme-background));
}

/* O SEGREDO DO SCROLL PERFEITO INTERNO */
.messages-area {
    flex: 1 1 auto;
    min-height: 0;
    overflow-y: auto;
}

.pattern-bg {
    background-color: #efeae2;
    background-image: url("data:image/svg+xml,%3Csvg width='60' height='60' viewBox='0 0 60 60' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='none' fill-rule='evenodd'%3E%3Cg fill='%23000000' fill-opacity='0.04'%3E%3Cpath d='M36 34v-4h-2v4h-4v2h4v4h2v-4h4v-2h-4zm0-30V0h-2v4h-4v2h4v4h2V6h4V4h-4zM6 34v-4H4v4H0v2h4v4h2V6h4V4H6z'/%3E%3C/g%3E%3C/g%3E%3C/svg%3E");
}

.audit-bubble {
    border: 1px solid transparent;
    transition: all 0.2s;

    &.border-grey { border-color: rgba(128,128,128,0.15) !important; }
    &.border-primary { border-color: rgba(var(--v-theme-primary), 0.2) !important; }

    &.is-whisper {
        border: 2px dashed #9c27b0 !important;
        background-color: #f3e5f5 !important;
    }
}

/* ALERTA DO ADMINISTRADOR */
.admin-alert-msg {
    background: linear-gradient(135deg, #d32f2f, #b71c1c) !important;
    color: white !important;
    border-left: 8px solid #ffeb3b !important;
    box-shadow: 0 8px 24px rgba(211, 47, 47, 0.4) !important;
    animation: pulse-alert 2.5s infinite;
}

@keyframes pulse-alert {
    0% { box-shadow: 0 0 0 0 rgba(211, 47, 47, 0.5); }
    70% { box-shadow: 0 0 0 8px rgba(211, 47, 47, 0); }
    100% { box-shadow: 0 0 0 0 rgba(211, 47, 47, 0); }
}

/* INPUT DA INTERVENÇÃO */
.normal-input-wrapper { background-color: rgba(128, 128, 128, 0.08); border-radius: 24px; }
.whisper-input-wrapper { background-color: rgba(156, 39, 176, 0.08); border: 2px dashed #9c27b0; border-radius: 24px; }
.admin-input-wrapper { background-color: rgba(211, 47, 47, 0.1); border: 2px solid #d32f2f; border-radius: 24px; :deep(textarea) { color: #d32f2f !important; font-weight: bold; } }

.compact-textarea :deep(.v-field__input) {
    min-height: 40px !important;
    padding-top: 8px;
    padding-bottom: 8px;
}
.compact-select :deep(.v-field__input) {
    min-height: 36px !important;
    padding-top: 4px;
    padding-bottom: 4px;
}

.pulse-btn {
    animation: gentleBounce 2s infinite ease-in-out;
}
@keyframes gentleBounce { 0%, 100% { transform: scale(1); } 50% { transform: scale(1.05); } }

.lh-1 { line-height: 1.2; }
.text-\[9px\] { font-size: 9px !important; }
.text-\[10px\] { font-size: 10px !important; }
.text-\[11px\] { font-size: 11px !important; }
.text-\[13px\] { font-size: 13px !important; }
.text-\[14px\] { font-size: 14px !important; }

.custom-scrollbar::-webkit-scrollbar { width: 6px; }
.custom-scrollbar::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.3); border-radius: 4px; }
.bg-surface-variant-light { background-color: rgba(128,128,128,0.04); }
</style>
