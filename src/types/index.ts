export interface User {
  id: string;
  username: string;
  avatar_url: string;
  full_name: string;
  role: string;
}

export interface Channel {
  id: number;
  name: string;
  is_group: boolean; // Adicionado para diferenciar grupos
  created_by: string;
  is_private_dm: boolean;
  dm_participant_ids: string[];
  members: User[];
  messages: Message[];
}

export interface Message {
  id: number;
  channel_id: number;
  profile_id: string;
  content: string;
  created_at: string;
  is_deleted: boolean;
  deleted_at: string | null;
  deleted_by: string | null;
  is_edited: boolean;
  edited_at: string | null;
  profile: User;
}

// Interface para o estado de presença de um usuário
export interface Presence {
  user_id: string;
  online_at: string;
}
