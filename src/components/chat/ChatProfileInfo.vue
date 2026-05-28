<template>
  <div class="profile-info-container d-flex flex-column h-100 bg-background">
    <v-toolbar color="surface" elevation="1" density="comfortable" class="flex-shrink-0">
      <v-btn icon="mdi-arrow-left" variant="text" @click="$emit('close')"></v-btn>
      <v-toolbar-title class="font-weight-bold text-subtitle-1 px-1">
        Dados do {{ channel?.is_private_dm ? 'contato' : 'grupo' }}
      </v-toolbar-title>
    </v-toolbar>

    <div class="profile-content-scroll flex-grow-1 overflow-y-auto pb-4">

      <div class="bg-surface d-flex flex-column align-center py-6 px-4 mb-2 elevation-1">
        <v-avatar size="140" :color="channel?.is_private_dm ? 'primary' : 'blue-grey'" class="mb-4 elevation-2 cursor-pointer avatar-hover">
          <v-img v-if="channel?.icon_image_url" :src="channel.icon_image_url" cover></v-img>
          <span v-else class="text-h2 text-white">{{ channel?.name?.substring(0,2).toUpperCase() || 'C' }}</span>
        </v-avatar>
        <h2 class="text-h5 font-weight-bold text-high-emphasis text-center mb-1">{{ channel?.name }}</h2>
        <p class="text-body-1 text-medium-emphasis mb-4">
          {{ channel?.is_private_dm ? 'Contato' : `Grupo · ${members.length} participantes` }}
        </p>

        <div class="d-flex justify-center w-100 gap-4">
          <div class="action-btn-wrapper" @click="$emit('open-media')">
            <v-btn icon="mdi-folder-multiple-image" color="primary" variant="tonal" size="large"></v-btn>
            <span class="text-caption mt-1 font-weight-medium">Mídia</span>
          </div>
          <div class="action-btn-wrapper" @click="$emit('action', 'search')">
            <v-btn icon="mdi-magnify" color="primary" variant="tonal" size="large"></v-btn>
            <span class="text-caption mt-1 font-weight-medium">Buscar</span>
          </div>
          <div class="action-btn-wrapper" @click="$emit('action', 'mute')">
            <v-btn :icon="channel?.is_muted ? 'mdi-bell-off' : 'mdi-bell'" color="primary" variant="tonal" size="large"></v-btn>
            <span class="text-caption mt-1 font-weight-medium">{{ channel?.is_muted ? 'Mutado' : 'Silenciar' }}</span>
          </div>
        </div>
      </div>

      <v-list class="bg-surface mb-2 elevation-1 py-0" lines="one">
        <div v-if="!channel?.is_private_dm" class="px-4 py-3 border-bottom">
          <div class="text-caption font-weight-bold text-primary mb-1">Descrição</div>
          <div class="text-body-2 text-medium-emphasis">{{ channel?.description || 'Nenhuma descrição.' }}</div>
        </div>

        <v-list-item prepend-icon="mdi-folder-multiple-image" @click="$emit('open-media')" class="border-bottom hover-effect">
          <v-list-item-title class="font-weight-medium">Mídia, links e docs</v-list-item-title>
          <template v-slot:append><v-icon size="small" color="grey">mdi-chevron-right</v-icon></template>
        </v-list-item>

        <v-list-item prepend-icon="mdi-pin-outline" class="hover-effect" @click="$emit('action', 'pin')">
          <v-list-item-title class="font-weight-medium">{{ channel?.is_pinned ? 'Desafixar conversa' : 'Fixar conversa' }}</v-list-item-title>
        </v-list-item>
      </v-list>

      <v-list v-if="!channel?.is_private_dm" class="bg-surface mb-2 elevation-1 py-0" lines="two">
        <div class="px-4 py-3 text-caption font-weight-bold text-medium-emphasis border-bottom">
          {{ members.length }} participantes
        </div>

        <v-list-item v-if="iAmAdmin" @click="openAddParticipantsModal" class="border-bottom text-primary py-2 hover-effect">
          <template v-slot:prepend>
            <v-avatar color="primary" variant="tonal" size="40" class="mr-3"><v-icon>mdi-account-plus</v-icon></v-avatar>
          </template>
          <v-list-item-title class="font-weight-bold">Adicionar participantes</v-list-item-title>
        </v-list-item>

        <v-list-item v-for="(member, index) in members" :key="member.profile_id" :class="{'border-bottom': index < members.length - 1}" class="py-2 hover-effect">
          <template v-slot:prepend>
            <v-avatar size="40" color="blue-grey" class="mr-3">
              <v-img v-if="member.avatar_url" :src="member.avatar_url"></v-img>
              <span v-else class="text-white text-caption">{{ member.full_name?.charAt(0).toUpperCase() || 'U' }}</span>
            </v-avatar>
          </template>
          <v-list-item-title class="font-weight-medium">{{ member.full_name }}</v-list-item-title>

          <v-list-item-subtitle v-if="isUserAdmin(member.profile_id)"><v-chip size="x-small" color="success" class="mt-1 font-weight-bold px-2">Admin</v-chip></v-list-item-subtitle>
          <v-list-item-subtitle v-else-if="isUserMod(member.profile_id)"><v-chip size="x-small" color="warning" class="mt-1 font-weight-bold px-2">Moderador</v-chip></v-list-item-subtitle>
          <v-list-item-subtitle v-else class="text-caption mt-1">Participante</v-list-item-subtitle>

          <template v-slot:append v-if="canManageMember(member.profile_id)">
            <v-menu location="bottom end">
              <template v-slot:activator="{ props }">
                <v-btn v-bind="props" icon="mdi-dots-vertical" variant="text" size="small" color="medium-emphasis"></v-btn>
              </template>
              <v-list density="compact" class="bg-surface elevation-3 rounded-lg py-1">
                <template v-if="iAmAdmin">
                  <v-list-item v-if="!isUserAdmin(member.profile_id)" @click="changeMemberRole(member.profile_id, 'admin')">
                    <v-list-item-title class="text-success font-weight-medium">Tornar Administrador</v-list-item-title>
                  </v-list-item>
                  <v-list-item v-if="isUserAdmin(member.profile_id)" @click="changeMemberRole(member.profile_id, 'user')">
                    <v-list-item-title class="text-error font-weight-medium">Remover Admin</v-list-item-title>
                  </v-list-item>
                  <v-list-item v-if="!isUserMod(member.profile_id) && !isUserAdmin(member.profile_id)" @click="changeMemberRole(member.profile_id, 'mod')">
                    <v-list-item-title class="text-warning font-weight-medium">Tornar Moderador</v-list-item-title>
                  </v-list-item>
                  <v-list-item v-if="isUserMod(member.profile_id)" @click="changeMemberRole(member.profile_id, 'user')">
                    <v-list-item-title class="text-error font-weight-medium">Remover Moderador</v-list-item-title>
                  </v-list-item>
                </template>
                <v-list-item @click="removeMember(member.profile_id)" base-color="error">
                  <v-list-item-title class="font-weight-bold">Remover do grupo</v-list-item-title>
                </v-list-item>
              </v-list>
            </v-menu>
          </template>
        </v-list-item>
      </v-list>

      <v-list class="bg-surface elevation-1 py-0 mb-6" lines="one">
        <v-list-item prepend-icon="mdi-exit-to-app" base-color="error" class="border-bottom hover-effect" @click="$emit('action', 'leave')">
          <v-list-item-title class="font-weight-bold text-error">Sair do {{ channel?.is_private_dm ? 'chat' : 'grupo' }}</v-list-item-title>
        </v-list-item>
      </v-list>
    </div>

    <v-dialog v-model="showAddModal" max-width="450" scrollable z-index="999999">
      <v-card class="bg-background rounded-xl d-flex flex-column" style="max-height: 80vh;">
        <v-toolbar color="surface" class="border-b flex-shrink-0" elevation="0">
          <v-btn icon="mdi-close" @click="showAddModal = false"></v-btn>
          <v-toolbar-title class="font-weight-bold text-h6">Adicionar Membros</v-toolbar-title>
        </v-toolbar>

        <div class="pa-3 bg-surface flex-shrink-0 border-b">
          <v-text-field v-model="searchNewMembers" placeholder="Pesquisar contatos..." variant="solo-filled" flat density="compact" hide-details prepend-inner-icon="mdi-magnify" rounded="pill"></v-text-field>
        </div>

        <v-card-text class="pa-0 flex-grow-1 overflow-y-auto">
          <v-list class="bg-transparent py-0" lines="one">
            <div v-if="filteredAvailableUsers.length === 0" class="pa-6 text-center text-medium-emphasis">
              Nenhum contato disponível para adicionar.
            </div>
            <v-list-item v-for="user in filteredAvailableUsers" :key="user.id" @click="toggleNewMember(user.id)" class="py-2 border-b hover-effect">
              <template v-slot:prepend>
                <v-avatar size="44" color="blue-grey-lighten-4" class="mr-3">
                  <v-img v-if="user.avatar_url" :src="user.avatar_url" cover></v-img>
                  <span v-else class="text-blue-grey-darken-3 font-weight-bold">{{ user.full_name?.charAt(0).toUpperCase() || 'U' }}</span>
                </v-avatar>
              </template>
              <v-list-item-title class="font-weight-medium">{{ user.full_name }}</v-list-item-title>
              <template v-slot:append>
                <v-checkbox-btn :model-value="selectedNewMembers.includes(user.id)" color="primary" class="pe-none"></v-checkbox-btn>
              </template>
            </v-list-item>
          </v-list>
        </v-card-text>

        <v-card-actions class="pa-4 bg-surface flex-shrink-0 border-top justify-end">
          <v-btn variant="text" color="medium-emphasis" class="font-weight-bold" @click="showAddModal = false">Cancelar</v-btn>
          <v-btn color="primary" variant="flat" rounded="pill" class="px-6 font-weight-bold" :disabled="selectedNewMembers.length === 0" :loading="isAddingMembers" @click="confirmAddMembers">
            Adicionar ({{ selectedNewMembers.length }})
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

  </div>
</template>

<script setup lang="ts">
import { ref, watch, onMounted, computed } from 'vue';
import { supabase } from '@/api/supabase';
import { useUserStore } from '@/stores/user';

const props = defineProps<{
  channel: any;
  isMobile: boolean;
}>();

const emit = defineEmits(['close', 'action', 'open-media']);
const userStore = useUserStore();
const members = ref<any[]>([]);

// ==========================================
// ESTADOS LOCAIS PARA CARGOS
// ==========================================
const localAdminIds = ref<string[]>([]);
const localModIds = ref<string[]>([]);

watch(() => props.channel, (newVal) => {
  if (newVal) {
    localAdminIds.value = newVal.admin_ids || [];
    localModIds.value = newVal.moderator_ids || [];
  }
}, { immediate: true, deep: true });

const isUserAdmin = (id: string) => localAdminIds.value.includes(id);
const isUserMod = (id: string) => localModIds.value.includes(id);

const iAmAdmin = computed(() => userStore.profile?.id ? isUserAdmin(userStore.profile.id) : false);
const iAmMod = computed(() => userStore.profile?.id ? isUserMod(userStore.profile.id) : false);

const canManageMember = (targetId: string) => {
  if (targetId === userStore.profile?.id) return false;
  if (iAmAdmin.value) return true;
  if (iAmMod.value && !isUserAdmin(targetId) && !isUserMod(targetId)) return true;
  return false;
};

// ==========================================
// FUNÇÕES BÁSICAS
// ==========================================
const fetchMembers = async () => {
  if (!props.channel || props.channel.is_private_dm) {
    members.value = [];
    return;
  }
  const { data, error } = await supabase.rpc('get_all_channel_members', { p_channel_id: Number(props.channel.id) });
  if (!error && data) members.value = data;
};

watch(() => props.channel?.id, fetchMembers);
onMounted(fetchMembers);

// ==========================================
// FUNÇÕES DE GESTÃO (RPC)
// ==========================================
const changeMemberRole = async (targetId: string, role: 'admin' | 'mod' | 'user') => {
  try {
    const { error } = await supabase.rpc('update_member_role', {
      p_channel_id: Number(props.channel.id),
      p_target_user_id: targetId,
      p_new_role: role
    });
    if (error) throw error;

    localAdminIds.value = localAdminIds.value.filter(id => id !== targetId);
    localModIds.value = localModIds.value.filter(id => id !== targetId);
    if (role === 'admin') localAdminIds.value.push(targetId);
    if (role === 'mod') localModIds.value.push(targetId);
  } catch (err: any) {
    alert(err.message || 'Erro ao alterar cargo.');
  }
};

const removeMember = async (targetId: string) => {
  if (!confirm('Tem certeza que deseja remover este participante?')) return;
  try {
    const { error } = await supabase.rpc('remove_group_member', {
      p_channel_id: Number(props.channel.id),
      p_target_user_id: targetId
    });
    if (error) throw error;
    members.value = members.value.filter(m => m.profile_id !== targetId);
  } catch (err: any) {
    alert(err.message || 'Erro ao remover participante.');
  }
};

// ==========================================
// ADICIONAR PARTICIPANTES EM MASSA
// ==========================================
const showAddModal = ref(false);
const allSystemUsers = ref<any[]>([]);
const searchNewMembers = ref('');
const selectedNewMembers = ref<string[]>([]);
const isAddingMembers = ref(false);

const openAddParticipantsModal = async () => {
  selectedNewMembers.value = [];
  searchNewMembers.value = '';
  showAddModal.value = true;

  if (allSystemUsers.value.length === 0) {
    const { data } = await supabase.from('profiles').select('*');
    if (data) allSystemUsers.value = data;
  }
};

const filteredAvailableUsers = computed(() => {
  const existingIds = members.value.map(m => m.profile_id);
  const available = allSystemUsers.value.filter(u => !existingIds.includes(u.id));
  if (!searchNewMembers.value) return available;
  const term = searchNewMembers.value.toLowerCase();
  return available.filter(u => u.full_name?.toLowerCase().includes(term));
});

const toggleNewMember = (id: string) => {
  if (selectedNewMembers.value.includes(id)) {
    selectedNewMembers.value = selectedNewMembers.value.filter(uid => uid !== id);
  } else {
    selectedNewMembers.value.push(id);
  }
};

const confirmAddMembers = async () => {
  if (selectedNewMembers.value.length === 0) return;
  isAddingMembers.value = true;
  try {
    const { error } = await supabase.rpc('add_group_members', {
      p_channel_id: Number(props.channel.id),
      p_new_member_ids: selectedNewMembers.value
    });
    if (error) throw error;

    showAddModal.value = false;
    await fetchMembers();
  } catch (err: any) {
    alert(err.message || 'Erro ao adicionar membros.');
  }
  isAddingMembers.value = false;
};
</script>

<style scoped>
.profile-info-container { width: 100%; height: 100%; border-left: 1px solid rgba(128, 128, 128, 0.15); }
.profile-content-scroll { overflow-y: auto; }
.profile-content-scroll::-webkit-scrollbar { width: 6px; }
.profile-content-scroll::-webkit-scrollbar-thumb { background-color: rgba(128, 128, 128, 0.3); border-radius: 4px; }
.border-bottom { border-bottom: 1px solid rgba(128, 128, 128, 0.08); }
.border-top { border-top: 1px solid rgba(128, 128, 128, 0.08); }
.action-btn-wrapper { display: flex; flex-direction: column; align-items: center; cursor: pointer; transition: opacity 0.2s; }
.action-btn-wrapper:hover { opacity: 0.8; }
.gap-4 { gap: 16px; }
.avatar-hover:hover { opacity: 0.9; }
.hover-effect { transition: background-color 0.2s; cursor: pointer; }
.hover-effect:active, .hover-effect:hover { background-color: rgba(128, 128, 128, 0.05); }
</style>
