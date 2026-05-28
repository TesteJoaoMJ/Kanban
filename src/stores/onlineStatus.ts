import { defineStore } from 'pinia';
import { ref } from 'vue';

// Interface para garantir a estrutura dos dados de presença
interface Presence {
  user_id: string;
  status: 'online' | 'away' | 'offline';
  [key: string]: any;
}

export const useOnlineStatusStore = defineStore('onlineStatus', () => {
  const onlineUsers = ref<Presence[]>([]);

  function setOnlineUsers(presences: any) {
    const newOnlineUsers: Presence[] = [];
    // O objeto de presenças do Supabase tem o ID do usuário como chave
    for (const id in presences) {
      // Cada usuário pode ter múltiplas presenças, pegamos a primeira
      if (presences[id] && presences[id].length > 0) {
        newOnlineUsers.push(presences[id][0] as Presence);
      }
    }
    onlineUsers.value = newOnlineUsers;
  }

  return {
    onlineUsers,
    setOnlineUsers,
  };
});
