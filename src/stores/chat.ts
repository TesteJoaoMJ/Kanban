import { defineStore } from 'pinia'
import { supabase } from '@/api/supabase'
import type { Channel, Message, Presence } from '@/types'
import { useUserStore } from '@/stores/user'
import { ref } from 'vue'

export const useChatStore = defineStore('chat', () => {
  const channels = ref<Channel[]>([])
  const activeChannel = ref<Channel | null>(null)
  const messages = ref<Message[]>([])
  const onlineUsers = ref<Presence[]>([])
  const totalUnreadCount = ref(0)
  let messageSubscription: any = null
  let sound: HTMLAudioElement | null = null

  const hasMoreMessages = ref(true)
  const isLoadingMore = ref(false)
  const MESSAGES_PER_PAGE = 50
  let notificationBuffer: any[] = []
  let notificationTimer: ReturnType<typeof setTimeout> | null = null

  async function fetchChannels(userId: string) {
    const { data: memberData, error: memberError } = await supabase
      .from('channel_members')
      .select('channel_id, is_pinned, is_muted')
      .eq('profile_id', userId)

    if (memberError || !memberData) {
      channels.value = []
      return
    }

    const channelIds = memberData.map(cm => cm.channel_id)
    if (channelIds.length === 0) {
      channels.value = []
      return
    }

    const { data: rpcData, error } = await supabase.rpc('get_my_channels_with_unread_and_preview');
    if (error || !rpcData) return;

    const { data: rawChannels } = await supabase
      .from('channels')
      .select('id, dm_participant_ids')
      .in('id', channelIds);

    const channelToOtherUser = new Map();
    const otherUserIds = new Set<string>();

    rawChannels?.forEach(c => {
      if (c.dm_participant_ids && c.dm_participant_ids.length > 0) {
        const otherId = c.dm_participant_ids.find((id: string) => id !== userId);
        if (otherId) {
          channelToOtherUser.set(c.id, otherId);
          otherUserIds.add(otherId);
        }
      }
    });

    let profilesMap = new Map();
    if (otherUserIds.size > 0) {
      const { data: profiles } = await supabase
        .from('profiles')
        .select('id, full_name, username, avatar_url')
        .in('id', Array.from(otherUserIds));

      if (profiles) {
        profilesMap = new Map(profiles.map(p => [p.id, p]));
      }
    }

    const settingsMap = new Map(memberData.map(m => [m.channel_id, { is_pinned: m.is_pinned, is_muted: m.is_muted }]));

    const enrichedChannels = rpcData.map((channel: any) => {
      let finalName = channel.name;
      let finalAvatar = channel.icon_image_url;
      let otherParticipantId = channel.other_participant_id;

      if (channel.is_private_dm) {
        otherParticipantId = channelToOtherUser.get(channel.id);
        const otherProfile = profilesMap.get(otherParticipantId);

        if (otherProfile) {
          finalName = otherProfile.full_name || otherProfile.username || 'Contato';
          finalAvatar = otherProfile.avatar_url;
        }
      }

      return {
        ...channel,
        name: finalName,
        icon_image_url: finalAvatar,
        other_participant_id: otherParticipantId,
        is_pinned: settingsMap.get(channel.id)?.is_pinned ?? false,
        is_muted: settingsMap.get(channel.id)?.is_muted ?? false,
      }
    });

    enrichedChannels.sort((a: any, b: any) => (b.is_pinned ? 1 : 0) - (a.is_pinned ? 1 : 0));
    channels.value = enrichedChannels as Channel[];
  }

  function unsubscribeFromMessages() {
    if (messageSubscription) {
      supabase.removeChannel(messageSubscription)
      messageSubscription = null
    }
  }

  async function setActiveChannel(channelId: number) {
    unsubscribeFromMessages()

    const { data, error } = await supabase
      .from('channels')
      .select('*, members:profiles!channel_members(*)')
      .eq('id', channelId)
      .single()

    if (error) {
      activeChannel.value = null
    } else {
      let finalChannel = { ...data };
      const myId = useUserStore().profile?.id;

      if (finalChannel.is_private_dm && finalChannel.dm_participant_ids) {
         const otherUserId = finalChannel.dm_participant_ids.find((id: string) => id !== myId);

         if (otherUserId) {
            const { data: otherProfile } = await supabase.from('profiles').select('id, full_name, username, avatar_url').eq('id', otherUserId).single();
            if (otherProfile) {
              finalChannel.name = otherProfile.full_name || otherProfile.username || 'Contato';
              finalChannel.icon_image_url = otherProfile.avatar_url;
              finalChannel.other_participant_id = otherProfile.id;
            }
         }
      }

      activeChannel.value = finalChannel as Channel
      await fetchMessages(channelId)

      // MARCAR COMO LIDAS (READ RECEIPTS)
      if (myId) {
        await supabase.from('messages')
          .update({ status: 'read' })
          .eq('channel_id', channelId)
          .neq('profile_id', myId)
          .neq('status', 'read');
      }

      subscribeToMessages(channelId)
    }
  }

  async function fetchMessages(channelId: number) {
    hasMoreMessages.value = true
    const { data, error } = await supabase
      .from('messages')
      .select('*, profile:profiles(*)')
      .eq('channel_id', channelId)
      .order('created_at', { ascending: false })
      .limit(MESSAGES_PER_PAGE)

    if (!error && data) {
      messages.value = (data as Message[]).reverse()
      if (data.length < MESSAGES_PER_PAGE) hasMoreMessages.value = false
    } else {
      messages.value = []
      hasMoreMessages.value = false
    }
  }

  async function loadMoreMessages(channelId: number) {
    if (!hasMoreMessages.value || isLoadingMore.value || messages.value.length === 0) return

    isLoadingMore.value = true
    const oldestMessageDate = messages.value[0].created_at

    const { data, error } = await supabase
      .from('messages')
      .select('*, profile:profiles(*)')
      .eq('channel_id', channelId)
      .lt('created_at', oldestMessageDate)
      .order('created_at', { ascending: false })
      .limit(MESSAGES_PER_PAGE)

    if (!error && data && data.length > 0) {
      const olderMessages = (data as Message[]).reverse()
      messages.value = [...olderMessages, ...messages.value]
      if (data.length < MESSAGES_PER_PAGE) hasMoreMessages.value = false
    } else {
      hasMoreMessages.value = false
    }
    isLoadingMore.value = false
  }

  function subscribeToMessages(channelId: number) {
    messageSubscription = supabase
      .channel(`messages:channel=${channelId}`)
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'messages', filter: `channel_id=eq.${channelId}` },
        async (payload) => {
          if (payload.eventType === 'INSERT') {

            // TRAVA DE SEGURANÇA CONTRA DUPLICATAS DA UI OTIMISTA
            const existingIndex = messages.value.findIndex(m => m.id === payload.new.id);

            if (existingIndex === -1) {
              const { data: profile } = await supabase.from('profiles').select('*').eq('id', payload.new.profile_id).single()
              if (profile) messages.value.push({ ...payload.new, profile } as Message)
            }

            // Se for mensagem da outra pessoa e eu estou no chat, já marca como lido na hora
            const myId = useUserStore().profile?.id;
            if (myId && payload.new.profile_id !== myId && activeChannel.value?.id === channelId) {
               await supabase.from('messages').update({ status: 'read' }).eq('id', payload.new.id);
            }

          } else if (payload.eventType === 'UPDATE') {
            const index = messages.value.findIndex(m => m.id === payload.new.id);
            if (index !== -1) messages.value[index] = { ...messages.value[index], ...payload.new } as Message;
          } else if (payload.eventType === 'DELETE') {
            messages.value = messages.value.filter(m => m.id !== payload.old.id);
          }
        },
      ).subscribe()
  }

 async function sendMessage(content: string, channelId: number, userId: string, replyToMessageId?: string | number | null, messageType: string = 'text', caption: string | null = null) {
    if (!content.trim() && messageType === 'text') return

    const userStore = useUserStore();
    const senderProfile = userStore.profile;

    // 1. Criar Mensagem Otimista
    const tempId = `temp-${Date.now()}`;
    const tempMessage = {
      id: tempId,
      content,
      channel_id: channelId,
      profile_id: userId,
      reply_to_message_id: replyToMessageId,
      message_type: messageType,
      caption: caption,
      status: 'sending',
      created_at: new Date().toISOString(),
      profile: senderProfile
    };

    messages.value.push(tempMessage as any);

    // 2. Disparar pro Banco
    const payload: any = { content, channel_id: channelId, profile_id: userId, message_type: messageType, caption };
    if (replyToMessageId) payload.reply_to_message_id = replyToMessageId;

    const { data, error } = await supabase.from('messages').insert(payload).select().single();

    // 3. Avaliar resultado do Banco e atualizar UI
    const index = messages.value.findIndex(m => m.id === tempId);
    if (error) {
      if (index !== -1) messages.value[index].status = 'error';
    } else {
      if (index !== -1) {
        const existsReal = messages.value.find(m => m.id === data.id);
        if (existsReal) {
          messages.value.splice(index, 1);
        } else {
          messages.value[index] = { ...messages.value[index], ...data } as any;
        }
      }

      // ---> CORREÇÃO DA SIDEBAR (RESTAURAR CHAT APAGADO) <---
      try {
        const currentChannel = channels.value.find(c => c.id === channelId) || activeChannel.value;
        if (currentChannel) {
          // 1. Garante que a relação no banco seja recriada para ambos
          if (currentChannel.is_private_dm && currentChannel.dm_participant_ids) {
             const membersToUpsert = currentChannel.dm_participant_ids.map((id: string) => ({
                channel_id: channelId,
                profile_id: id
             }));
             await supabase.from('channel_members').upsert(membersToUpsert, { onConflict: 'channel_id,profile_id', ignoreDuplicates: true });
          } else {
             await supabase.from('channel_members').upsert({
                channel_id: channelId,
                profile_id: userId
             }, { onConflict: 'channel_id,profile_id', ignoreDuplicates: true });
          }

          // 2. Se a conversa não estava na lista local, recarrega a sidebar
          if (!channels.value.some(c => c.id === channelId)) {
             await fetchChannels(userId);
          }
        }
      } catch (err) {
        console.error("Erro ao restaurar canal na sidebar:", err);
      }
      // ---> FIM DA CORREÇÃO <---

      // --- INÍCIO DA INTEGRAÇÃO COM NOTIFICAÇÕES GLOBAIS ---
      try {
        const currentChannel = channels.value.find(c => c.id === channelId) || activeChannel.value;

        if (currentChannel && senderProfile) {
          let recipients: string[] = [];

          if (currentChannel.is_private_dm && currentChannel.dm_participant_ids) {
            recipients = currentChannel.dm_participant_ids.filter((id: string) => id !== userId);
          } else {
            const { data: members } = await supabase
              .from('channel_members')
              .select('profile_id')
              .eq('channel_id', channelId)
              .neq('profile_id', userId);

            if (members) {
              recipients = members.map((m: any) => m.profile_id);
            }
          }

          if (recipients.length > 0) {
            const senderName = senderProfile.full_name || senderProfile.username || 'Usuário';
            const avatarUrl = senderProfile.avatar_url || `https://ui-avatars.com/api/?name=${encodeURIComponent(senderName)}&background=1976D2&color=fff`;
            const msgPreview = messageType === 'text' ? content : '📎 Enviou um anexo';

            const notificationContent = `[CHAT]${senderName}||${avatarUrl}||${msgPreview}||${channelId}`;

            const notificationsToInsert = recipients.map(recId => ({
              recipient_id: recId,
              sender_id: senderProfile.id,
              type: 'chat',
              content: notificationContent,
              redirect_url: `/chat?channel=${channelId}`
            }));

            notificationBuffer.push(...notificationsToInsert);

            if (!notificationTimer) {
              notificationTimer = setTimeout(() => {
                const batch = [...notificationBuffer];
                notificationBuffer = [];
                notificationTimer = null;

                if (batch.length > 0) {
                  supabase.from('notifications').insert(batch).then(({ error: notifError }) => {
                    if (notifError) console.error("Erro no lote de notificação:", notifError);
                  });
                }
              }, 500);
            }
          }
        }
      } catch (err) {
         console.error("Falha na integração de notificação global:", err);
      }
      // --- FIM DA INTEGRAÇÃO ---
    }
  }

  async function resendMessage(msg: any) {
    messages.value = messages.value.filter(m => m.id !== msg.id);
    await sendMessage(msg.content, msg.channel_id, msg.profile_id, msg.reply_to_message_id, msg.message_type, msg.caption);
  }

  function setOnlineUsers(presences: any) {
    const newOnlineUsers: Presence[] = []
    for (const id in presences) newOnlineUsers.push(presences[id][0])
    onlineUsers.value = newOnlineUsers
  }

  async function togglePinChannel(channel: Channel, userId: string) {
    const newPinnedStatus = !channel.is_pinned;
    const channelInStore = channels.value.find(c => c.id === channel.id);
    if (channelInStore) {
      channelInStore.is_pinned = newPinnedStatus;
      channels.value.sort((a, b) => (b.is_pinned ? 1 : 0) - (a.is_pinned ? 1 : 0));
    }
    const { error } = await supabase.from('channel_members').update({ is_pinned: newPinnedStatus }).eq('channel_id', channel.id).eq('profile_id', userId);
    if (error && channelInStore) {
      channelInStore.is_pinned = !newPinnedStatus;
      channels.value.sort((a, b) => (b.is_pinned ? 1 : 0) - (a.is_pinned ? 1 : 0));
    }
  }

  async function toggleMuteChannel(channel: Channel, userId: string) {
    const newMutedStatus = !channel.is_muted;
    const channelInStore = channels.value.find(c => c.id === channel.id);
    if (channelInStore) channelInStore.is_muted = newMutedStatus;
    const { error } = await supabase.from('channel_members').update({ is_muted: newMutedStatus }).eq('channel_id', channel.id).eq('profile_id', userId);
    if (error && channelInStore) channelInStore.is_muted = !newMutedStatus;
  }

  async function deleteChannel(channelId: number, userId: string) {
      const { error } = await supabase.from('channel_members').delete().eq('channel_id', channelId).eq('profile_id', userId);
      if (!error) {
          channels.value = channels.value.filter(c => c.id !== channelId);
          if (activeChannel.value?.id === channelId) {
              activeChannel.value = null;
              messages.value = [];
              unsubscribeFromMessages();
          }
      }
  }

  function initializeSound(element: HTMLAudioElement) { sound = element }
  function setTotalUnreadCount(count: number) { totalUnreadCount.value = count }
  function playNotificationSound() { if (sound) { sound.currentTime = 0; sound.play().catch(e => e) } }

  return {
    channels, activeChannel, messages, onlineUsers, totalUnreadCount,
    hasMoreMessages, isLoadingMore,
    fetchChannels, setActiveChannel, fetchMessages, loadMoreMessages,
    sendMessage, resendMessage, setOnlineUsers, initializeSound, setTotalUnreadCount,
    playNotificationSound, togglePinChannel, toggleMuteChannel, deleteChannel
  }
})
