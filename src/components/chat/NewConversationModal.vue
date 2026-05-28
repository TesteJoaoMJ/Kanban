<template>
  <v-dialog
    v-model="dialog"
    :fullscreen="isMobile"
    max-width="500px"
    scrollable
    transition="dialog-bottom-transition"
    @keydown.esc="close"
  >
    <v-card class="d-flex flex-column h-100 bg-surface rounded-xl overflow-hidden">

      <v-toolbar color="surface" elevation="0" class="flex-shrink-0 border-bottom">
        <v-btn :icon="view === 'contacts' ? 'mdi-close' : 'mdi-arrow-left'" variant="text" @click="goBack"></v-btn>

        <v-toolbar-title class="font-weight-bold text-h6 px-1">
          {{ view === 'contacts' ? 'Nova conversa' : view === 'group_step1' ? 'Novo grupo' : 'Dados do grupo' }}
        </v-toolbar-title>

        <v-spacer></v-spacer>

        <v-btn
          v-if="view === 'group_step1'"
          icon="mdi-arrow-right"
          color="primary"
          variant="flat"
          class="mr-3"
          size="small"
          :disabled="selectedUsers.length === 0"
          @click="view = 'group_step2'"
        ></v-btn>

        <v-btn
          v-if="view === 'group_step2'"
          color="primary"
          variant="flat"
          rounded="pill"
          class="font-weight-bold mr-3 text-none px-4"
          :disabled="!groupName.trim() || isCreatingGroup"
          :loading="isCreatingGroup"
          @click="createGroup"
        >
          Criar Grupo
        </v-btn>
      </v-toolbar>

      <div v-if="view !== 'group_step2'" class="pa-3 bg-surface flex-shrink-0">
        <v-text-field
          v-model="searchQuery"
          placeholder="Pesquisar contatos..."
          variant="solo-filled"
          flat
          density="compact"
          hide-details
          prepend-inner-icon="mdi-magnify"
          rounded="pill"
          class="search-input"
        ></v-text-field>
      </div>

      <div
        v-if="view === 'group_step1' && selectedUsers.length > 0"
        class="selected-chips-area bg-surface px-4 py-3 d-flex flex-shrink-0 border-bottom"
        style="overflow-x: auto; white-space: nowrap; gap: 16px;"
      >
        <div v-for="user in selectedUsers" :key="user.id" class="d-inline-flex flex-column align-center position-relative" style="width: 56px">
          <div class="position-relative">
            <v-avatar size="48" color="primary">
              <v-img v-if="user.avatar_url" :src="user.avatar_url" cover></v-img>
              <span v-else class="text-white">{{ user.full_name?.charAt(0).toUpperCase() || 'U' }}</span>
            </v-avatar>
            <v-btn
              icon="mdi-close"
              size="20"
              color="grey-darken-3"
              class="position-absolute bg-surface"
              style="bottom: -2px; right: -4px; border-radius: 50%; border: 1px solid rgba(128,128,128,0.2)"
              @click="toggleUser(user)"
            ></v-btn>
          </div>
          <span class="text-caption text-truncate w-100 text-center mt-1 text-medium-emphasis">{{ user.full_name?.split(' ')[0] }}</span>
        </div>
      </div>

      <v-card-text class="pa-0 flex-grow-1 overflow-y-auto bg-background">

        <v-list v-if="view === 'contacts'" class="bg-transparent py-2" lines="two">
          <v-list-item @click="view = 'group_step1'" class="contact-item px-4 py-3 mb-2">
            <template v-slot:prepend>
              <v-avatar color="primary" size="48" class="mr-4 elevation-1">
                <v-icon color="white" size="24">mdi-account-group</v-icon>
              </v-avatar>
            </template>
            <v-list-item-title class="font-weight-bold text-body-1">Novo grupo</v-list-item-title>
            <v-list-item-subtitle class="text-caption mt-1">Reúna sua equipe em um chat</v-list-item-subtitle>
          </v-list-item>

          <div class="px-5 py-2 text-caption font-weight-bold text-medium-emphasis text-uppercase tracking-wide">
            Contatos ({{ filteredUsers.length }})
          </div>

          <v-list-item
            v-for="user in filteredUsers"
            :key="user.id"
            @click="startDM(user.id)"
            class="contact-item px-4 py-2"
          >
            <template v-slot:prepend>
              <v-avatar size="48" color="blue-grey-lighten-4" class="mr-4">
                <v-img v-if="user.avatar_url" :src="user.avatar_url" cover></v-img>
                <span v-else class="text-blue-grey-darken-3 font-weight-bold text-h6">{{ user.full_name?.charAt(0).toUpperCase() || 'U' }}</span>
              </v-avatar>
            </template>
            <v-list-item-title class="font-weight-bold text-high-emphasis mb-1">{{ user.full_name || 'Usuário Sem Nome' }}</v-list-item-title>
            <v-list-item-subtitle class="text-caption text-medium-emphasis">{{ user.role || 'Usuário' }}</v-list-item-subtitle>
          </v-list-item>
        </v-list>

        <v-list v-if="view === 'group_step1'" class="bg-transparent py-2" lines="one">
          <div class="px-5 py-2 text-caption font-weight-bold text-medium-emphasis text-uppercase tracking-wide">
            Selecione os participantes
          </div>

          <v-list-item
            v-for="user in filteredUsers"
            :key="user.id"
            @click="toggleUser(user)"
            class="contact-item px-4 py-2"
          >
            <template v-slot:prepend>
              <v-avatar size="48" color="blue-grey-lighten-4" class="mr-4 position-relative">
                <v-img v-if="user.avatar_url" :src="user.avatar_url" cover></v-img>
                <span v-else class="text-blue-grey-darken-3 font-weight-bold text-h6">{{ user.full_name?.charAt(0).toUpperCase() || 'U' }}</span>
                <v-scale-transition>
                  <div v-if="isSelected(user)" class="position-absolute w-100 h-100 d-flex align-center justify-center rounded-circle" style="background: rgba(var(--v-theme-primary), 0.85); top:0; left:0; z-index: 2;">
                    <v-icon color="white" size="28">mdi-check</v-icon>
                  </div>
                </v-scale-transition>
              </v-avatar>
            </template>
            <v-list-item-title class="font-weight-medium">{{ user.full_name }}</v-list-item-title>
          </v-list-item>
        </v-list>

        <div v-if="view === 'group_step2'" class="pa-6 d-flex flex-column align-center text-center">

          <input type="file" ref="avatarInputRef" accept="image/*" class="d-none" @change="handleAvatarSelected" />

          <v-avatar size="120" color="surface-variant" class="mb-6 elevation-1 cursor-pointer position-relative group-avatar-hover" @click="triggerAvatarUpload">
            <v-img v-if="avatarPreview" :src="avatarPreview" cover></v-img>
            <v-icon v-else size="48" color="grey-darken-1">mdi-camera-plus</v-icon>

            <v-overlay :model-value="isCreatingGroup" contained class="align-center justify-center rounded-circle">
              <v-progress-circular indeterminate color="primary"></v-progress-circular>
            </v-overlay>
          </v-avatar>

          <v-text-field
            v-model="groupName"
            placeholder="Nome do grupo"
            variant="underlined"
            class="w-100 mb-2 text-h6"
            autofocus
            counter="35"
            color="primary"
          ></v-text-field>

          <p class="text-body-2 text-medium-emphasis mt-1 mb-6">Você será o administrador principal do grupo.</p>

          <v-sheet rounded="lg" class="bg-surface w-100 text-left overflow-hidden border">
            <div class="px-4 py-3 bg-surface-variant font-weight-bold text-caption text-uppercase border-bottom">
              Participantes ({{ selectedUsers.length }}) e Permissões
            </div>

            <v-list lines="one" density="compact" class="bg-transparent py-0">
              <v-list-item v-for="(user, i) in selectedUsers" :key="user.id" :class="{'border-bottom': i < selectedUsers.length - 1}">
                <template v-slot:prepend>
                  <v-avatar size="32" color="blue-grey-lighten-4" class="mr-3">
                    <v-img v-if="user.avatar_url" :src="user.avatar_url" cover></v-img>
                    <span v-else class="text-blue-grey-darken-3 text-caption font-weight-bold">{{ user.full_name?.charAt(0).toUpperCase() || 'U' }}</span>
                  </v-avatar>
                </template>

                <v-list-item-title class="text-body-2 font-weight-medium">
                  {{ user.full_name }}
                </v-list-item-title>
                <v-list-item-subtitle v-if="isAdmin(user.id) || isMod(user.id)">
                  <v-chip size="x-small" :color="isAdmin(user.id) ? 'success' : 'warning'" class="mt-1 font-weight-bold px-2">
                    {{ isAdmin(user.id) ? 'Admin' : 'Moderador' }}
                  </v-chip>
                </v-list-item-subtitle>

                <template v-slot:append>
                  <v-menu location="bottom end">
                    <template v-slot:activator="{ props }">
                      <v-btn v-bind="props" icon="mdi-dots-vertical" variant="text" size="small" color="medium-emphasis"></v-btn>
                    </template>
                    <v-list density="compact" class="bg-surface elevation-3 rounded-lg py-1">
                      <v-list-item @click="toggleRole(user.id, 'admin')">
                        <v-list-item-title :class="{'text-success font-weight-bold': isAdmin(user.id)}">
                          {{ isAdmin(user.id) ? 'Remover Admin' : 'Tornar Administrador' }}
                        </v-list-item-title>
                      </v-list-item>
                      <v-list-item @click="toggleRole(user.id, 'mod')" v-if="!isAdmin(user.id)">
                        <v-list-item-title :class="{'text-warning font-weight-bold': isMod(user.id)}">
                          {{ isMod(user.id) ? 'Remover Moderador' : 'Tornar Moderador' }}
                        </v-list-item-title>
                      </v-list-item>
                    </v-list>
                  </v-menu>
                </template>
              </v-list-item>
            </v-list>
          </v-sheet>
        </div>

      </v-card-text>
    </v-card>
  </v-dialog>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { supabase } from '@/api/supabase'
import { useUserStore } from '@/stores/user'
import { useChatStore } from '@/stores/chat'

const dialog = ref(false)
const view = ref<'contacts' | 'group_step1' | 'group_step2'>('contacts')
const users = ref<any[]>([])
const selectedUsers = ref<any[]>([])
const groupName = ref('')
const searchQuery = ref('')

// Controle de Imagem do Grupo
const avatarInputRef = ref<HTMLInputElement | null>(null)
const avatarFile = ref<File | null>(null)
const avatarPreview = ref<string | null>(null)
const isCreatingGroup = ref(false)

// Controle de Cargos
const groupAdmins = ref<string[]>([])
const groupMods = ref<string[]>([])

const userStore = useUserStore()
const chatStore = useChatStore()
const emit = defineEmits(['close', 'conversation-started', 'group-created'])

const isMobile = ref(window.innerWidth <= 767)

onMounted(() => {
  window.addEventListener('resize', () => { isMobile.value = window.innerWidth <= 767 })
  fetchUsers()
})

const open = () => {
  view.value = 'contacts'
  dialog.value = true
  searchQuery.value = ''
  selectedUsers.value = []
  groupName.value = ''
  avatarFile.value = null
  avatarPreview.value = null
  groupAdmins.value = []
  groupMods.value = []
  isCreatingGroup.value = false
  fetchUsers()
}

const close = () => {
  dialog.value = false
  emit('close')
}

const goBack = () => {
  if (view.value === 'group_step2') {
    view.value = 'group_step1'
  } else if (view.value === 'group_step1') {
    view.value = 'contacts'
    searchQuery.value = ''
  } else {
    close()
  }
}

async function fetchUsers() {
  const { data, error } = await supabase.from('profiles').select('*')
  if (!error && data) {
    users.value = data.filter(u => u.id !== userStore.profile?.id)
  }
}

const filteredUsers = computed(() => {
  if (!searchQuery.value) return users.value
  const term = searchQuery.value.toLowerCase()
  return users.value.filter(u => u.full_name?.toLowerCase().includes(term))
})

const isSelected = (user: any) => selectedUsers.value.some(u => u.id === user.id)

const toggleUser = (user: any) => {
  if (isSelected(user)) {
    selectedUsers.value = selectedUsers.value.filter(u => u.id !== user.id)
    groupAdmins.value = groupAdmins.value.filter(id => id !== user.id)
    groupMods.value = groupMods.value.filter(id => id !== user.id)
  } else {
    selectedUsers.value.push(user)
  }
}

// === Gestão de Imagem ===
const triggerAvatarUpload = () => {
  if (avatarInputRef.value) avatarInputRef.value.click()
}

const handleAvatarSelected = (event: Event) => {
  const target = event.target as HTMLInputElement
  if (target.files && target.files.length > 0) {
    avatarFile.value = target.files[0]
    avatarPreview.value = URL.createObjectURL(avatarFile.value)
  }
}

// === Gestão de Cargos ===
const isAdmin = (id: string) => groupAdmins.value.includes(id)
const isMod = (id: string) => groupMods.value.includes(id)

const toggleRole = (userId: string, role: 'admin' | 'mod') => {
  if (role === 'admin') {
    if (isAdmin(userId)) {
      groupAdmins.value = groupAdmins.value.filter(id => id !== userId)
    } else {
      groupAdmins.value.push(userId)
      groupMods.value = groupMods.value.filter(id => id !== userId) // Remove de mod se virar admin
    }
  } else {
    if (isMod(userId)) {
      groupMods.value = groupMods.value.filter(id => id !== userId)
    } else {
      groupMods.value.push(userId)
    }
  }
}

// === Criar Chat Direto ===
async function startDM(userId: string) {
  if (!userStore.profile?.id) return
  const { data, error } = await supabase.rpc('find_or_create_dm_channel', {
    p_user1_id: userStore.profile.id,
    p_user2_id: userId,
  })
  if (!error && data) {
    emit('conversation-started', data)
    close()
  }
}

// === Concluir Criação do GRUPO com Foto e Cargos ===
async function createGroup() {
  if (!groupName.value.trim() || selectedUsers.value.length === 0 || !userStore.profile?.id) return

  isCreatingGroup.value = true
  const memberIds = selectedUsers.value.map(u => u.id)

  const { data, error } = await supabase.rpc('create_group_channel', {
    channel_name: groupName.value,
    member_ids: memberIds,
    p_admin_ids: groupAdmins.value,
    p_moderator_ids: groupMods.value
  })

  if (!error && data) {
    const newChannelId = Array.isArray(data) ? data[0]?.channel_id : data

    // Upload de Imagem, caso o usuário tenha selecionado
    if (avatarFile.value && newChannelId) {
      const fileExt = avatarFile.value.name.split('.').pop()
      const fileName = `group_${newChannelId}_${Date.now()}.${fileExt}`

      const { error: uploadError } = await supabase.storage.from('group_avatars').upload(fileName, avatarFile.value)

      if (!uploadError) {
        const { data: { publicUrl } } = supabase.storage.from('group_avatars').getPublicUrl(fileName)
        await supabase.from('channels').update({ icon_image_url: publicUrl }).eq('id', newChannelId)
      }
    }

    emit('group-created', { id: newChannelId })
    close()
  } else {
    console.error('Erro ao criar grupo:', error)
  }

  isCreatingGroup.value = false
}

defineExpose({ open, close })
</script>

<style scoped>
.contact-item {
  transition: background-color 0.2s ease;
  cursor: pointer;
}

.contact-item:hover {
  background-color: rgba(var(--v-theme-primary), 0.05);
}

.border-bottom {
  border-bottom: 1px solid rgba(128, 128, 128, 0.1);
}

.border {
  border: 1px solid rgba(128, 128, 128, 0.15);
}

.search-input :deep(.v-field) {
  background-color: rgba(128, 128, 128, 0.06) !important;
}

.selected-chips-area::-webkit-scrollbar {
  height: 4px;
}

.selected-chips-area::-webkit-scrollbar-thumb {
  background-color: rgba(128, 128, 128, 0.3);
  border-radius: 4px;
}

.group-avatar-hover {
  transition: opacity 0.2s ease, transform 0.2s ease;
}

.group-avatar-hover:hover {
  opacity: 0.8;
  transform: scale(0.98);
}
</style>
