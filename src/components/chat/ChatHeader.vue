<template>
  <header class="chat-header bg-surface d-flex align-center px-4 w-100 position-relative">

    <v-btn
      v-if="isMobile"
      icon="mdi-arrow-left"
      variant="text"
      class="mr-2 ml-n2"
      color="primary"
      @click="$emit('back')"
    ></v-btn>

    <div class="header-avatar-wrapper mr-3 flex-shrink-0 cursor-pointer" @click="handleOpenProfile">
      <v-badge dot location="bottom right" offset-x="2" offset-y="2" :color="statusColor" :model-value="isDM">
        <v-avatar size="44" :color="avatarColor" variant="tonal">
          <v-img v-if="displayAvatar" :src="displayAvatar" cover></v-img>
          <span v-else class="font-weight-bold">{{ displayInitials }}</span>
        </v-avatar>
      </v-badge>
    </div>

    <div class="header-info-wrapper flex-grow-1 overflow-hidden cursor-pointer" @click="handleOpenProfile">
      <h3 class="contact-name text-truncate mb-0 font-weight-bold text-high-emphasis">{{ displayName }}</h3>
      <p v-if="isDM" class="contact-status text-truncate text-caption mb-0" :class="statusTextClass">{{ statusText }}</p>
      <p v-else class="contact-status text-truncate text-caption mb-0 text-medium-emphasis">{{ dynamicMemberCount }} participantes</p>
    </div>

    <div class="header-actions-wrapper d-flex align-center flex-shrink-0 ml-2">
      <v-btn v-if="isMobile" icon="mdi-magnify" variant="text" class="text-medium-emphasis" @click="showMobileSearch = true"></v-btn>

      <div v-if="!isMobile" class="search-container ml-2">
        <v-text-field
          :model-value="searchQuery"
          @update:model-value="$emit('update:searchQuery', $event)"
          placeholder="Buscar mensagens..."
          variant="solo-filled"
          density="compact"
          hide-details
          flat
          clearable
          prepend-inner-icon="mdi-magnify"
          class="header-search-input"
          rounded="pill"
        ></v-text-field>
      </div>

      <v-menu location="bottom end" z-index="9999999">
        <template v-slot:activator="{ props }">
          <v-btn v-bind="props" icon="mdi-dots-vertical" variant="text" class="text-medium-emphasis ml-1"></v-btn>
        </template>
        <v-list density="compact" class="bg-surface elevation-3 rounded-lg py-1">
          <v-list-item prepend-icon="mdi-folder-multiple-image" @click="handleOpenMedia" class="px-4">
            <v-list-item-title class="text-body-2">Mídia, links e docs</v-list-item-title>
          </v-list-item>
          <v-list-item prepend-icon="mdi-magnify" @click="showMobileSearch = true" v-if="isMobile" class="px-4">
            <v-list-item-title class="text-body-2">Pesquisar</v-list-item-title>
          </v-list-item>
          <v-divider class="my-1 mx-2"></v-divider>
          <v-list-item prepend-icon="mdi-account-circle-outline" @click="handleOpenProfile" class="px-4">
            <v-list-item-title class="text-body-2">Dados do {{ isDM ? 'contato' : 'grupo' }}</v-list-item-title>
          </v-list-item>
        </v-list>
      </v-menu>
    </div>

    <v-slide-y-transition>
      <div v-if="isMobile && showMobileSearch" class="mobile-search-overlay bg-surface d-flex align-center px-2 elevation-2">
        <v-btn icon="mdi-arrow-left" variant="text" color="primary" @click="closeSearch"></v-btn>
        <v-text-field :model-value="searchQuery" @update:model-value="$emit('update:searchQuery', $event)" placeholder="Buscar..." variant="solo-filled" density="compact" hide-details flat clearable autofocus class="header-search-input ml-2 flex-grow-1" rounded="pill"></v-text-field>
      </div>
    </v-slide-y-transition>

    <Teleport to="body">
      <v-slide-x-reverse-transition>
        <div v-if="isMobile && showMobileProfile" class="mobile-native-screen bg-background">
          <v-toolbar color="surface" density="compact" class="elevation-0 flex-shrink-0 px-1 border-b">
            <v-btn icon="mdi-arrow-left" color="primary" @click="showMobileProfile = false"></v-btn>
            <v-toolbar-title class="text-subtitle-1 font-weight-medium ml-2">Dados do {{ isDM ? 'contato' : 'grupo' }}</v-toolbar-title>
          </v-toolbar>

          <div class="flex-grow-1 overflow-y-auto pb-6 profile-content-scroll">
            <div class="bg-surface d-flex flex-column align-center py-6 px-4 mb-3 border-b">
              <v-avatar size="140" :color="avatarColor" class="mb-5 elevation-1">
                <v-img v-if="displayAvatar" :src="displayAvatar" cover></v-img>
                <span v-else class="text-h2 text-white">{{ displayInitials }}</span>
              </v-avatar>
              <h2 class="text-h5 font-weight-bold text-high-emphasis text-center mb-1">{{ displayName }}</h2>
              <p class="text-medium-emphasis text-body-2">{{ isDM ? 'Contato' : dynamicMemberCount + ' participantes' }}</p>

              <div class="d-flex justify-center w-100 mt-4" style="gap: 24px;">
                <div class="action-btn-wrapper" @click="handleOpenMediaFromProfile">
                  <v-btn icon="mdi-folder-multiple-image" color="primary" variant="tonal" size="large"></v-btn>
                  <span class="text-caption mt-1 font-weight-medium">Mídia</span>
                </div>
                <div class="action-btn-wrapper" @click="openMobileSearchFromProfile">
                  <v-btn icon="mdi-magnify" color="primary" variant="tonal" size="large"></v-btn>
                  <span class="text-caption mt-1 font-weight-medium">Buscar</span>
                </div>
                <div class="action-btn-wrapper" @click="$emit('channel-action', { action: 'mute', channel: channel })">
                  <v-btn :icon="channel?.is_muted ? 'mdi-bell-off' : 'mdi-bell'" color="primary" variant="tonal" size="large"></v-btn>
                  <span class="text-caption mt-1 font-weight-medium">{{ channel?.is_muted ? 'Mutado' : 'Silenciar' }}</span>
                </div>
              </div>
            </div>

            <div class="bg-surface mb-3 border-y">
              <v-list lines="one" class="py-0">
                <div v-if="!isDM" class="px-4 py-3 border-b">
                  <div class="text-caption font-weight-bold text-primary mb-1">Descrição</div>
                  <div class="text-body-2 text-medium-emphasis">{{ channel?.description || 'Nenhuma descrição.' }}</div>
                </div>
                <v-list-item @click="handleOpenMediaFromProfile" class="px-4 py-3 border-b hover-effect">
                  <v-list-item-title class="text-body-1 font-weight-medium">Mídia, links e docs</v-list-item-title>
                  <template v-slot:append><v-icon size="small" color="grey-lighten-1">mdi-chevron-right</v-icon></template>
                </v-list-item>
                <v-list-item @click="$emit('channel-action', { action: 'pin', channel: channel })" class="px-4 py-3 hover-effect">
                  <v-list-item-title class="text-body-1">{{ channel?.is_pinned ? 'Desafixar conversa' : 'Fixar conversa' }}</v-list-item-title>
                </v-list-item>
              </v-list>
            </div>

            <div v-if="!isDM" class="bg-surface mb-3 border-y">
              <v-list lines="two" class="py-0">
                <div class="px-4 py-3 text-caption font-weight-bold text-medium-emphasis border-b">
                  {{ groupMembers.length }} participantes
                </div>

                <v-list-item v-if="iAmAdmin" class="border-b text-primary py-2 hover-effect" @click="openAddParticipantsModal">
                  <template v-slot:prepend>
                    <v-avatar color="primary" variant="tonal" size="40" class="mr-3"><v-icon>mdi-account-plus</v-icon></v-avatar>
                  </template>
                  <v-list-item-title class="font-weight-bold">Adicionar membros</v-list-item-title>
                </v-list-item>

                <div v-if="loadingMembers" class="pa-4 d-flex justify-center"><v-progress-circular indeterminate color="primary"></v-progress-circular></div>

                <template v-else>
                  <v-list-item v-for="(member, index) in groupMembers" :key="member.profile_id" :class="{'border-b': index < groupMembers.length - 1}" class="py-2">
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
                          <v-btn v-bind="props" icon="mdi-dots-vertical" variant="text" size="small" color="medium-emphasis" @click.stop></v-btn>
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
                </template>
              </v-list>
            </div>

            <div class="bg-surface border-y mb-6">
              <v-list lines="one" class="py-0">
                <v-list-item v-if="!isDM" @click="$emit('channel-action', { action: 'leave', channel: channel })" class="px-4 py-3 border-b hover-effect">
                  <template v-slot:prepend><v-icon color="error" class="mr-4">mdi-exit-to-app</v-icon></template>
                  <v-list-item-title class="text-error font-weight-bold text-body-1">Sair do grupo</v-list-item-title>
                </v-list-item>
              </v-list>
            </div>
          </div>
        </div>
      </v-slide-x-reverse-transition>
    </Teleport>

    <v-dialog v-model="showAddModal" fullscreen transition="dialog-bottom-transition" z-index="9999999">
      <v-card class="bg-background">
        <v-toolbar color="surface" class="border-b" elevation="0">
          <v-btn icon="mdi-close" @click="showAddModal = false"></v-btn>
          <v-toolbar-title class="font-weight-bold">Adicionar Membros</v-toolbar-title>
          <v-spacer></v-spacer>
          <v-btn color="primary" variant="flat" rounded="pill" class="mr-3 font-weight-bold text-none" :disabled="selectedNewMembers.length === 0" :loading="isAddingMembers" @click="confirmAddMembers">
            Adicionar ({{ selectedNewMembers.length }})
          </v-btn>
        </v-toolbar>

        <div class="pa-3 bg-surface flex-shrink-0 border-b">
          <v-text-field v-model="searchNewMembers" placeholder="Pesquisar contatos..." variant="solo-filled" flat density="compact" hide-details prepend-inner-icon="mdi-magnify" rounded="pill"></v-text-field>
        </div>

        <v-list class="flex-grow-1 overflow-y-auto bg-transparent py-0" lines="one">
          <div v-if="filteredAvailableUsers.length === 0" class="pa-6 text-center text-medium-emphasis">
            Nenhum contato disponível para adicionar.
          </div>
          <v-list-item v-for="user in filteredAvailableUsers" :key="user.id" @click="toggleNewMember(user.id)" class="py-2 border-b">
            <template v-slot:prepend>
              <v-avatar size="44" color="blue-grey-lighten-4" class="mr-3">
                <v-img v-if="user.avatar_url" :src="user.avatar_url" cover></v-img>
                <span v-else class="text-blue-grey-darken-3 font-weight-bold">{{ user.full_name?.charAt(0).toUpperCase() || 'U' }}</span>
              </v-avatar>
            </template>
            <v-list-item-title class="font-weight-medium">{{ user.full_name }}</v-list-item-title>
            <template v-slot:append>
              <v-checkbox-btn :model-value="selectedNewMembers.includes(user.id)" color="primary"></v-checkbox-btn>
            </template>
          </v-list-item>
        </v-list>
      </v-card>
    </v-dialog>

    <Teleport to="body">
      <v-slide-x-reverse-transition>
        <div v-if="isMobile && showMobileMedia" class="mobile-native-screen bg-background">
          <div class="bg-surface flex-shrink-0 elevation-1">
            <v-toolbar color="transparent" density="compact" class="elevation-0 px-1">
              <v-btn icon="mdi-arrow-left" color="primary" @click="showMobileMedia = false"></v-btn>
              <v-toolbar-title class="text-subtitle-1 font-weight-medium ml-2">Mídia, links e docs</v-toolbar-title>
            </v-toolbar>
            <v-tabs v-model="mediaTab" color="primary" align-tabs="start" density="compact" class="px-2" hide-slider>
              <v-tab value="medias" class="text-capitalize rounded-pill px-4 mx-1" :class="{'bg-primary-lighten-4': mediaTab === 'medias'}">Mídia</v-tab>
              <v-tab value="docs" class="text-capitalize rounded-pill px-4 mx-1" :class="{'bg-primary-lighten-4': mediaTab === 'docs'}">Docs</v-tab>
              <v-tab value="links" class="text-capitalize rounded-pill px-4 mx-1" :class="{'bg-primary-lighten-4': mediaTab === 'links'}">Links</v-tab>
            </v-tabs>
          </div>
          <div class="px-4 py-3 flex-shrink-0 bg-background border-b">
             <v-text-field v-model="mediaSearch" placeholder="Buscar..." variant="solo-filled" density="compact" hide-details flat clearable prepend-inner-icon="mdi-magnify" rounded="pill"></v-text-field>
          </div>
          <v-window v-model="mediaTab" class="flex-grow-1 overflow-y-auto bg-background">
            <v-window-item value="medias" class="h-100">
              <div v-if="loadingMedia" class="d-flex justify-center pa-8"><v-progress-circular indeterminate color="primary"/></div>
              <div v-else-if="filteredVisualMedias.length === 0" class="d-flex flex-column align-center justify-center h-100 pa-6 text-medium-emphasis"><v-icon size="48" class="mb-3 opacity-50">mdi-image-off-outline</v-icon><p>Nenhuma mídia encontrada</p></div>
              <div v-else class="media-grid pa-1">
                <div v-for="m in filteredVisualMedias" :key="m.id" class="media-item">
                  <v-img v-if="m.message_type === 'image'" :src="m.content" aspect-ratio="1" cover class="cursor-pointer" @click="openMediaLink(m.content)"></v-img>
                  <div v-else-if="m.message_type === 'video'" class="video-placeholder cursor-pointer d-flex align-center justify-center bg-black" @click="openMediaLink(m.content)"><v-icon color="white" size="32">mdi-play-circle-outline</v-icon></div>
                </div>
              </div>
            </v-window-item>
            <v-window-item value="docs" class="h-100">
              <div v-if="loadingMedia" class="d-flex justify-center pa-8"><v-progress-circular indeterminate color="primary"/></div>
              <div v-else-if="filteredDocMedias.length === 0" class="d-flex flex-column align-center justify-center h-100 pa-6 text-medium-emphasis"><v-icon size="48" class="mb-3 opacity-50">mdi-file-hidden</v-icon><p>Nenhum documento encontrado</p></div>
              <v-list v-else lines="two" class="bg-transparent py-0">
                <v-list-item v-for="d in filteredDocMedias" :key="d.id" @click="openMediaLink(d.content)" class="border-b px-4 py-3 hover-effect">
                  <template v-slot:prepend><div class="doc-icon-wrapper bg-primary-lighten-4 rounded-lg d-flex align-center justify-center mr-4"><v-icon color="primary">mdi-file-document-outline</v-icon></div></template>
                  <v-list-item-title class="font-weight-medium text-body-1 mb-1">{{ extractFileName(d.content) }}</v-list-item-title>
                  <v-list-item-subtitle class="text-caption d-flex align-center text-medium-emphasis">{{ formatDateLocal(d.created_at) }} • {{ d.profile_id === userStore.profile?.id ? 'Você' : (d.profile?.full_name || 'Contato') }}</v-list-item-subtitle>
                </v-list-item>
              </v-list>
            </v-window-item>
            <v-window-item value="links" class="h-100">
              <div v-if="loadingMedia" class="d-flex justify-center pa-8"><v-progress-circular indeterminate color="primary"/></div>
              <div v-else-if="filteredLinkMedias.length === 0" class="d-flex flex-column align-center justify-center h-100 pa-6 text-medium-emphasis"><v-icon size="48" class="mb-3 opacity-50">mdi-link-off</v-icon><p>Nenhum link encontrado</p></div>
              <v-list v-else lines="two" class="bg-transparent py-0">
                <v-list-item v-for="l in filteredLinkMedias" :key="l.id" :href="extractLink(l.content)" target="_blank" class="border-b px-4 py-3 hover-effect">
                  <template v-slot:prepend><div class="doc-icon-wrapper bg-info-lighten-4 rounded-lg d-flex align-center justify-center mr-4"><v-icon color="info">mdi-link</v-icon></div></template>
                  <v-list-item-title class="text-info font-weight-medium text-body-1 mb-1">{{ extractDomain(l.content) }}</v-list-item-title>
                  <v-list-item-subtitle class="text-caption d-flex flex-column"><span class="text-truncate d-inline-block text-medium-emphasis mb-1" style="max-width: 250px;">{{ extractLink(l.content) }}</span></v-list-item-subtitle>
                </v-list-item>
              </v-list>
            </v-window-item>
          </v-window>
        </div>
      </v-slide-x-reverse-transition>
    </Teleport>
  </header>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue';
import { supabase } from '@/api/supabase';
import { useUserStore } from '@/stores/user';
import { format, isToday, isYesterday, parseISO } from 'date-fns';
import { ptBR } from 'date-fns/locale';

const props = defineProps<{
  channel: any;
  onlineUsers: any[];
  searchQuery: string;
  isMobile: boolean;
}>();

const emit = defineEmits(['update:searchQuery', 'toggle-repository', 'back', 'open-info', 'channel-action']);
const userStore = useUserStore();

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
  if (targetId === userStore.profile?.id) return false; // Não pode gerir a si mesmo aqui
  if (iAmAdmin.value) return true; // Admin gere todos (a RPC bloqueia deletar outro admin)
  if (iAmMod.value && !isUserAdmin(targetId) && !isUserMod(targetId)) return true; // Mod gere usuário comum
  return false;
};

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

    // Atualiza o estado local para refletir na UI instantaneamente
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
    groupMembers.value = groupMembers.value.filter(m => m.profile_id !== targetId);
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
  const existingIds = groupMembers.value.map(m => m.profile_id);
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
    await fetchGroupMembers(); // Recarrega a lista
  } catch (err: any) {
    alert(err.message || 'Erro ao adicionar membros.');
  }
  isAddingMembers.value = false;
};

// ==========================================
// LÓGICA DE DADOS DO CABEÇALHO
// ==========================================
const isDM = computed(() => {
  try { return !props.channel ? false : props.channel.is_private_dm === true || props.channel.type === 'dm'; } catch (e) { return false; }
});

const otherParticipantProfile = computed(() => {
  try { return (!isDM.value || !Array.isArray(props.channel?.members) || !userStore.profile?.id) ? null : props.channel.members.find((m: any) => m.id !== userStore.profile?.id) || null; } catch (e) { return null; }
});

const otherParticipantStatus = computed(() => {
  try {
    const profile = otherParticipantProfile.value;
    return (!profile || !Array.isArray(props.onlineUsers)) ? null : props.onlineUsers.find((u: any) => u.id === profile.id || u.user_id === profile.id) || null;
  } catch (e) { return null; }
});

const displayName = computed(() => {
  try { return !props.channel ? 'Carregando...' : (isDM.value && otherParticipantProfile.value) ? (otherParticipantProfile.value.full_name || 'Contato') : (props.channel.name || 'Grupo'); } catch (e) { return 'Conversa'; }
});

const displayAvatar = computed(() => {
  try { return (isDM.value && otherParticipantProfile.value) ? otherParticipantProfile.value.avatar_url : props.channel?.icon_image_url; } catch (e) { return null; }
});

const displayInitials = computed(() => {
  const name = displayName.value;
  if (!name || name === 'Carregando...') return '?';
  const words = name.split(' ').filter(Boolean);
  return words.length > 1 ? `${words[0][0]}${words[1][0]}`.toUpperCase() : name.substring(0, 2).toUpperCase();
});

const avatarColor = computed(() => (isDM.value ? 'primary' : 'blue-grey'));

const statusColor = computed(() => {
  if (!otherParticipantStatus.value) return 'grey-lighten-1';
  switch (otherParticipantStatus.value.status) { case 'online': return 'success'; case 'away': return 'warning'; default: return 'grey-lighten-1'; }
});

const statusTextClass = computed(() => {
  if (!otherParticipantStatus.value) return 'text-medium-emphasis';
  return otherParticipantStatus.value.status === 'online' ? 'text-success font-weight-medium' : (otherParticipantStatus.value.status === 'away' ? 'text-warning font-weight-medium' : 'text-medium-emphasis');
});

const statusText = computed(() => {
  try {
    if (!otherParticipantStatus.value) return 'Offline';
    if (otherParticipantStatus.value.status === 'online') return 'Online';
    if (otherParticipantStatus.value.status === 'away') return 'Ausente';
    const lastActivity = otherParticipantStatus.value.last_seen || props.channel?.last_message_at;
    if (!lastActivity) return 'Offline';
    const date = typeof lastActivity === 'string' ? parseISO(lastActivity) : new Date(lastActivity);
    if (isToday(date)) return `Visto por último hoje às ${format(date, 'HH:mm')}`;
    if (isYesterday(date)) return `Visto por último ontem às ${format(date, 'HH:mm')}`;
    return `Visto por último em ${format(date, "dd/MM/yy 'às' HH:mm", { locale: ptBR })}`;
  } catch (e) { return 'Offline'; }
});

// ==========================================
// CONTROLES DE ESTADO NATIVO E MÍDIA
// ==========================================
const showMobileSearch = ref(false);
const showMobileProfile = ref(false);
const showMobileMedia = ref(false);
const mediaSearch = ref('');
const groupMembers = ref<any[]>([]);
const loadingMembers = ref(false);

const closeSearch = () => { showMobileSearch.value = false; emit('update:searchQuery', ''); };
const dynamicMemberCount = computed(() => groupMembers.value.length > 0 ? groupMembers.value.length : (Array.isArray(props.channel?.members) ? props.channel.members.length : 0));

const fetchGroupMembers = async () => {
  if (!props.channel || !props.channel.id || isDM.value) return;
  loadingMembers.value = true;
  const { data, error } = await supabase.rpc('get_all_channel_members', { p_channel_id: Number(props.channel.id) });
  if (!error && data) groupMembers.value = data;
  loadingMembers.value = false;
};

watch(() => props.channel, (newChannel) => {
  showMobileProfile.value = false; showMobileMedia.value = false; showMobileSearch.value = false; mediaSearch.value = '';
  if (newChannel && !isDM.value) fetchGroupMembers();
}, { immediate: true });

const handleOpenProfile = () => { if (props.isMobile) { showMobileProfile.value = true; if (!isDM.value && groupMembers.value.length === 0) fetchGroupMembers(); } else { emit('open-info'); } };
const handleOpenMedia = () => { if (props.isMobile) { showMobileMedia.value = true; fetchMedias(); } else { emit('toggle-repository'); } };
const handleOpenMediaFromProfile = () => { showMobileMedia.value = true; fetchMedias(); };
const openMobileSearchFromProfile = () => { showMobileProfile.value = false; showMobileSearch.value = true; };

// ==========================================
// MÍDIA MOBILE
// ==========================================
const mediaTab = ref('medias');
const loadingMedia = ref(false);
const fetchedMedias = ref<any[]>([]);

const fetchMedias = async () => {
  if (!props.channel?.id) return;
  loadingMedia.value = true;
  const { data } = await supabase.from('messages').select('id, content, message_type, created_at, profile_id, profile:profiles(full_name)').eq('channel_id', props.channel.id).neq('is_deleted', true).order('created_at', { ascending: false });
  if (data) fetchedMedias.value = data;
  loadingMedia.value = false;
};

const filteredVisualMedias = computed(() => fetchedMedias.value.filter(m => ['image', 'video', 'audio'].includes(m.message_type)));
const filteredDocMedias = computed(() => fetchedMedias.value.filter(m => m.message_type === 'file').filter(d => !mediaSearch.value || extractFileName(d.content).toLowerCase().includes(mediaSearch.value.toLowerCase())));
const filteredLinkMedias = computed(() => fetchedMedias.value.filter(m => m.message_type === 'text' && /(https?:\/\/[^\s]+)/g.test(m.content)).filter(l => !mediaSearch.value || l.content.toLowerCase().includes(mediaSearch.value.toLowerCase())));

const extractLink = (text: string) => text.match(/(https?:\/\/[^\s]+)/g)?.[0] || '';
const extractDomain = (text: string) => { const link = extractLink(text); try { return new URL(link).hostname.replace('www.', ''); } catch (e) { return 'Link'; } };
const extractFileName = (url: string) => decodeURIComponent(url.split('/').pop() || '') || 'Documento';
const formatDateLocal = (dateStr: string) => isToday(parseISO(dateStr)) ? 'Hoje' : (isYesterday(parseISO(dateStr)) ? 'Ontem' : format(parseISO(dateStr), 'dd/MM/yy'));
const openMediaLink = (url: string) => { if (url) window.open(url, '_blank'); };
</script>

<style lang="scss" scoped>
/* Os estilos continuam os mesmos da sua versão anterior limpa */
.chat-header { height: 60px; flex-shrink: 0; border-bottom: 1px solid rgba(128, 128, 128, 0.15); z-index: 10; }
.header-info-wrapper { display: flex; flex-direction: column; justify-content: center; min-width: 0; }
.contact-name { font-size: 1.05rem; line-height: 1.2; }
.contact-status { line-height: 1.2; }
.search-container { width: 240px; transition: width 0.3s ease; }
.mobile-search-overlay {
  position: absolute;
  top: 0; left: 0; right: 0; bottom: 0;
  width: 100%; height: 100%;
  z-index: 5000000;
}
.header-search-input :deep(.v-field) { background-color: rgba(128, 128, 128, 0.08) !important; }
.header-search-input :deep(.v-field__input) { padding-top: 6px; padding-bottom: 6px; min-height: 36px !important; }
.mobile-native-screen {
  position: fixed;
  top: 0; left: 0; right: 0; bottom: 0;
  width: 100vw; height: 100dvh;
  z-index: 5000000; /* Acima do chat (999999), abaixo dos menus (9999999) */
  display: flex;
  flex-direction: column;
}
.border-b { border-bottom: 1px solid rgba(128, 128, 128, 0.15); }
.border-y { border-top: 1px solid rgba(128, 128, 128, 0.15); border-bottom: 1px solid rgba(128, 128, 128, 0.15); }
.bg-primary-lighten-4 { background-color: rgba(var(--v-theme-primary), 0.1) !important; }
.bg-info-lighten-4 { background-color: rgba(var(--v-theme-info), 0.1) !important; }
.hover-effect { cursor: pointer; }
.hover-effect:active { background-color: rgba(128, 128, 128, 0.05); }
.doc-icon-wrapper { width: 48px; height: 48px; flex-shrink: 0; }
.media-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 2px; }
.media-item { aspect-ratio: 1; position: relative; overflow: hidden; }
.video-placeholder { width: 100%; height: 100%; }
.profile-content-scroll { overflow-y: auto; }
.profile-content-scroll::-webkit-scrollbar { width: 4px; }
.profile-content-scroll::-webkit-scrollbar-thumb { background-color: rgba(128, 128, 128, 0.3); border-radius: 4px; }
.action-btn-wrapper { display: flex; flex-direction: column; align-items: center; cursor: pointer; transition: opacity 0.2s; }
.action-btn-wrapper:hover { opacity: 0.8; }
</style>
