<template>
  <div class="d-flex flex-column h-100 w-100 pa-6">

      <div class="d-flex align-end justify-space-between mb-6 flex-shrink-0">
          <div>
             <h2 class="text-h5 font-weight-black text-white text-shadow">Equipe & Acesso</h2>
             <div class="text-caption text-white-50 mt-1">Gerencie permissões, cadastre vendedores e administradores.</div>
          </div>

          <v-btn
            color="primary"
            variant="flat"
            size="small"
            class="text-none font-weight-bold px-4 shadow-glow-primary"
            height="36"
            prepend-icon="mdi-account-plus"
            @click="showCreateModal = true"
          >
            Novo Membro
          </v-btn>
      </div>

      <div class="d-flex gap-4 mb-6 flex-shrink-0">
           <div class="glass-stat-card flex-grow-1 pa-4 rounded-xl d-flex align-center hover-glow border-l-primary">
              <div class="icon-box bg-primary-10 mr-4 rounded-lg"><v-icon color="primary" size="24">mdi-account-group</v-icon></div>
              <div>
                  <div class="text-[10px] text-white-50 font-weight-bold text-uppercase letter-spacing-1">Total da Equipe</div>
                  <div class="text-h5 font-weight-black text-white">{{ users.length }}</div>
              </div>
           </div>

           <div class="glass-stat-card flex-grow-1 pa-4 rounded-xl d-flex align-center hover-glow border-l-info">
              <div class="icon-box bg-info-10 mr-4 rounded-lg"><v-icon color="info" size="24">mdi-store</v-icon></div>
              <div>
                  <div class="text-[10px] text-white-50 font-weight-bold text-uppercase letter-spacing-1">Vendedores</div>
                  <div class="text-h5 font-weight-black text-white">{{ sellersCount }}</div>
              </div>
           </div>

           <div class="glass-stat-card flex-grow-1 pa-4 rounded-xl d-flex align-center hover-glow border-l-error">
              <div class="icon-box bg-error-10 mr-4 rounded-lg"><v-icon color="error" size="24">mdi-shield-crown</v-icon></div>
              <div>
                  <div class="text-[10px] text-white-50 font-weight-bold text-uppercase letter-spacing-1">Administradores</div>
                  <div class="text-h5 font-weight-black text-white">{{ adminsCount }}</div>
              </div>
           </div>
      </div>

      <div class="glass-panel pa-2 rounded-xl d-flex align-center gap-3 flex-shrink-0 mb-4 border-white-05">
          <div style="width: 300px;">
              <v-text-field
                  v-model="search"
                  density="compact"
                  variant="solo"
                  placeholder="Buscar por nome ou email..."
                  prepend-inner-icon="mdi-magnify"
                  hide-details
                  class="glass-input"
                  bg-color="rgba(0,0,0,0.2)"
              ></v-text-field>
          </div>
          <v-divider vertical class="border-white-10 h-24 my-auto"></v-divider>
          <span class="text-caption text-white-50 font-weight-medium">{{ filteredUsers.length }} membros encontrados</span>
      </div>

      <div class="flex-grow-1 overflow-y-auto custom-scrollbar pr-2 pb-4">
          <div v-if="loading" class="d-flex align-center justify-center h-100">
             <div class="d-flex flex-column align-center">
                 <v-progress-circular indeterminate color="primary" size="40" class="mb-4"></v-progress-circular>
                 <span class="text-caption text-white-50">Carregando equipe...</span>
             </div>
          </div>

          <div v-else-if="filteredUsers.length === 0" class="d-flex flex-column align-center justify-center h-100 opacity-50">
              <v-icon size="64" color="white-30" class="mb-4">mdi-account-off</v-icon>
              <div class="text-h6 text-white-50">Nenhum usuário encontrado</div>
          </div>

          <div v-else class="user-grid">
              <v-card
                  v-for="user in filteredUsers"
                  :key="user.id"
                  class="glass-user-card rounded-xl overflow-hidden d-flex flex-column align-center text-center"
                  flat
              >
                  <div class="card-header-banner w-100" :class="user.role === 'admin_cajuia' ? 'bg-gradient-error' : 'bg-gradient-primary'"></div>

                  <div class="avatar-wrapper">
                      <v-avatar size="80" class="elevation-6 border-4-glass bg-grey-darken-4">
                          <span class="text-h4 font-weight-black text-white">{{ getInitials(user.full_name) }}</span>
                      </v-avatar>
                  </div>

                  <div class="w-100 px-4 mt-3 mb-4 flex-grow-1 d-flex flex-column justify-center">
                      <div class="text-body-1 font-weight-bold text-white mb-0 text-truncate w-100" :title="user.full_name">
                          {{ user.full_name }}
                      </div>
                      <div class="text-caption text-white-50 text-truncate w-100 mb-3" :title="user.email">
                          {{ user.email }}
                      </div>

                      <div>
                          <v-chip
                            :color="getRoleColor(user.role)"
                            variant="tonal"
                            size="small"
                            class="font-weight-black text-uppercase letter-spacing-1 px-3"
                          >
                              {{ getRoleLabel(user.role) }}
                          </v-chip>
                      </div>
                  </div>

                  <v-divider class="w-100 border-white-05"></v-divider>

                  <div class="d-flex w-100 pa-2 gap-2 bg-glass-surface align-center justify-center">
                      <v-menu location="top">
                          <template v-slot:activator="{ props }">
                              <v-btn
                                variant="text"
                                color="white-70"
                                size="small"
                                class="flex-grow-1 font-weight-bold text-none glass-btn-small"
                                v-bind="props"
                                prepend-icon="mdi-account-cog"
                              >
                                 Alterar Função
                              </v-btn>
                          </template>
                          <v-list density="compact" class="glass-menu pa-1 width-180 rounded-lg border-white-10">
                              <v-list-item
                                title="Vendedor"
                                prepend-icon="mdi-store"
                                @click="updateRole(user, 'vendedor_cajuia')"
                                class="rounded mb-1 text-caption text-white"
                                :active="user.role === 'vendedor_cajuia'"
                                color="primary"
                              ></v-list-item>
                              <v-list-item
                                title="Administrador"
                                prepend-icon="mdi-shield-crown"
                                @click="updateRole(user, 'admin_cajuia')"
                                class="rounded mb-1 text-caption text-white"
                                :active="user.role === 'admin_cajuia'"
                                color="error"
                              ></v-list-item>
                          </v-list>
                      </v-menu>

                      <v-btn
                        icon
                        variant="text"
                        color="error"
                        size="small"
                        class="glass-btn-icon-danger"
                        @click="removeAccess(user)"
                      >
                         <v-icon size="20">mdi-delete-outline</v-icon>
                         <v-tooltip activator="parent" location="top">Remover Acesso</v-tooltip>
                      </v-btn>
                  </div>
              </v-card>
          </div>
      </div>

      <v-dialog v-model="showCreateModal" max-width="450" content-class="glass-dialog">
          <v-card class="glass-panel border-white-10 pa-6 rounded-xl">
              <div class="d-flex align-center mb-6">
                  <div class="icon-box bg-gradient-primary mr-4 elevation-4 rounded-lg"><v-icon color="white">mdi-account-plus</v-icon></div>
                  <div>
                      <h3 class="text-h6 text-white font-weight-bold">Novo Acesso</h3>
                      <div class="text-caption text-white-50">Adicionar membro à equipe</div>
                  </div>
                  <v-spacer></v-spacer>
                  <v-btn icon="mdi-close" variant="text" density="compact" color="white" @click="showCreateModal = false"></v-btn>
              </div>

              <v-form @submit.prevent="createUser">
                  <v-text-field
                    v-model="newUser.name"
                    label="Nome Completo"
                    variant="outlined"
                    density="comfortable"
                    class="glass-input mb-3"
                    bg-color="rgba(0,0,0,0.3)"
                    hide-details="auto"
                    placeholder="Ex: João Silva"
                  ></v-text-field>

                  <v-text-field
                    v-model="newUser.email"
                    label="E-mail de Acesso"
                    type="email"
                    variant="outlined"
                    density="comfortable"
                    class="glass-input mb-3"
                    bg-color="rgba(0,0,0,0.3)"
                    hide-details="auto"
                    placeholder="joao@cajuia.com"
                  ></v-text-field>

                  <v-text-field
                    v-model="newUser.password"
                    label="Senha Provisória"
                    type="password"
                    variant="outlined"
                    density="comfortable"
                    class="glass-input mb-4"
                    bg-color="rgba(0,0,0,0.3)"
                    hide-details="auto"
                    placeholder="Mínimo 6 caracteres"
                  ></v-text-field>

                  <div class="text-[11px] text-white-50 mb-2 font-weight-bold text-uppercase ml-1">Nível de Permissão</div>
                  <v-btn-toggle
                    v-model="newUser.role"
                    color="primary"
                    mandatory
                    class="glass-toggle w-100 mb-6 rounded-lg border-white-10"
                    density="comfortable"
                  >
                      <v-btn value="vendedor_cajuia" class="flex-grow-1 text-none font-weight-bold text-caption">
                          <v-icon start size="small">mdi-store</v-icon> Vendedor
                      </v-btn>
                      <v-btn value="admin_cajuia" class="flex-grow-1 text-none font-weight-bold text-caption">
                          <v-icon start size="small">mdi-shield-crown</v-icon> Administrador
                      </v-btn>
                  </v-btn-toggle>

                  <v-btn
                    block
                    color="primary"
                    size="large"
                    class="font-weight-bold shadow-glow-primary rounded-lg text-none"
                    type="submit"
                    :loading="creatingUser"
                  >
                      Criar Acesso
                  </v-btn>
              </v-form>
          </v-card>
      </v-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, reactive } from 'vue'
import { supabase } from '@/api/supabase'
import { useAppStore } from '@/stores/app'

const appStore = useAppStore()
const users = ref<any[]>([])
const loading = ref(false)
const search = ref('')
const showCreateModal = ref(false)
const creatingUser = ref(false)

const newUser = reactive({
    name: '',
    email: '',
    password: '',
    role: 'vendedor_cajuia'
})

// Computed Properties
const adminsCount = computed(() => users.value.filter(u => u.role === 'admin_cajuia').length)
const sellersCount = computed(() => users.value.filter(u => u.role === 'vendedor_cajuia').length)

const filteredUsers = computed(() => {
    if (!search.value) return users.value
    const q = search.value.toLowerCase()
    return users.value.filter(u =>
        (u.full_name && u.full_name.toLowerCase().includes(q)) ||
        (u.email && u.email.toLowerCase().includes(q))
    )
})

// Fetch Users Logic
const fetchUsers = async () => {
    loading.value = true
    try {
        // Busca perfis
        const { data: profiles, error: profilesError } = await supabase.from('profiles').select('id, full_name, email')
        if (profilesError) throw profilesError

        // Busca permissões Cajuia
        const { data: permissions, error: permsError } = await supabase.from('cajuia_permissions').select('*')
        if (permsError) throw permsError

        // Merge: Só mostra usuários que têm alguma permissão na Cajuia
        users.value = profiles.map(p => {
            const perm = permissions.find(item => item.user_id === p.id)
            return {
                ...p,
                role: perm ? perm.role : null
            }
        }).filter(u => u.role !== null) // Filtra quem não tem acesso à Cajuia

    } catch (e) {
        console.error(e)
        appStore.showSnackbar('Erro ao carregar equipe.', 'error')
    } finally {
        loading.value = false
    }
}

// Create User via Edge Function (Bypassing client-side restriction)
const createUser = async () => {
    if(!newUser.email || !newUser.password || !newUser.name) {
        appStore.showSnackbar('Preencha todos os campos.', 'warning')
        return
    }
    creatingUser.value = true

    try {
        const { data, error } = await supabase.functions.invoke('create-user', {
            body: {
                email: newUser.email,
                password: newUser.password,
                email_confirm: true,
                user_metadata: { full_name: newUser.name }
            }
        })

        if (error) throw error

        if (data && data.user) {
             // Após criar o Auth User, insere a permissão na tabela cajuia_permissions
             const { error: permError } = await supabase
                .from('cajuia_permissions')
                .insert({ user_id: data.user.id, role: newUser.role })

             if (permError) {
                 console.error('Erro ao definir permissão:', permError)
                 appStore.showSnackbar('Usuário criado, mas falha na permissão.', 'warning')
             } else {
                 appStore.showSnackbar('Membro adicionado com sucesso!', 'success')
             }

             showCreateModal.value = false
             resetForm()
             fetchUsers()
        }
    } catch (e: any) {
        console.error(e)
        appStore.showSnackbar('Erro: ' + (e.message || 'Falha ao criar usuário'), 'error')
    } finally {
        creatingUser.value = false
    }
}

const resetForm = () => {
    newUser.name = ''
    newUser.email = ''
    newUser.password = ''
    newUser.role = 'vendedor_cajuia'
}

const updateRole = async (user: any, role: string) => {
    if (user.role === role) return // Sem mudança

    const { error } = await supabase
        .from('cajuia_permissions')
        .upsert({ user_id: user.id, role: role }, { onConflict: 'user_id' })

    if(!error) {
        user.role = role
        appStore.showSnackbar(`Função alterada para ${getRoleLabel(role)}`, 'success')
    } else {
        appStore.showSnackbar('Erro ao alterar função.', 'error')
    }
}

const removeAccess = async (user: any) => {
    if(!confirm(`Tem certeza que deseja remover o acesso de ${user.full_name}? O usuário não poderá mais logar na Cajuia.`)) return

    const { error } = await supabase
        .from('cajuia_permissions')
        .delete()
        .eq('user_id', user.id)

    if(!error) {
        fetchUsers()
        appStore.showSnackbar('Acesso removido com sucesso.', 'success')
    } else {
        appStore.showSnackbar('Erro ao remover acesso.', 'error')
    }
}

// Helpers
const getRoleColor = (r: string) => r === 'admin_cajuia' ? 'error' : 'primary'
const getRoleLabel = (r: string) => r === 'admin_cajuia' ? 'Admin' : 'Vendedor'
const getInitials = (name: string) => name ? name.substring(0, 2).toUpperCase() : '??'

onMounted(fetchUsers)
</script>

<style scoped lang="scss">
/* Grid Layout */
.user-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));
    gap: 20px;
}

/* Glass Cards */
.glass-panel, .glass-stat-card {
    background: rgba(30, 30, 35, 0.4);
    backdrop-filter: blur(12px);
    border: 1px solid rgba(255, 255, 255, 0.08);
    box-shadow: 0 8px 32px rgba(0,0,0,0.2);
}

.glass-user-card {
    background: rgba(30, 30, 35, 0.4);
    backdrop-filter: blur(16px);
    border: 1px solid rgba(255, 255, 255, 0.08);
    transition: all 0.3s ease;
    position: relative;
    height: 100%;

    &:hover {
        background: rgba(30, 30, 35, 0.6);
        transform: translateY(-6px);
        border-color: rgba(255, 255, 255, 0.15);
        box-shadow: 0 12px 30px rgba(0,0,0,0.3);
    }
}

/* Banner Header do Card */
.card-header-banner {
    height: 70px;
    position: absolute;
    top: 0; left: 0;
    opacity: 0.8;
    mask-image: linear-gradient(to bottom, black 0%, transparent 100%);
    -webkit-mask-image: linear-gradient(to bottom, black 0%, transparent 100%);
}
.bg-gradient-primary { background: linear-gradient(135deg, rgba(var(--v-theme-primary), 0.8), rgba(var(--v-theme-primary), 0.3)); }
.bg-gradient-error { background: linear-gradient(135deg, rgba(var(--v-theme-error), 0.8), rgba(var(--v-theme-error), 0.3)); }

/* Avatar Styling */
.avatar-wrapper {
    margin-top: 25px;
    position: relative;
    z-index: 2;
}
.border-4-glass { border: 4px solid rgba(30, 30, 35, 0.8); }

/* Inputs */
.glass-input :deep(.v-field) {
    border-radius: 10px !important;
    border: 1px solid rgba(255,255,255,0.1);
    color: white !important;
    font-size: 0.9rem;
    &.v-field--focused { border-color: rgba(var(--v-theme-primary), 0.5); }
}
.glass-toggle { background: rgba(0,0,0,0.3) !important; border: 1px solid rgba(255,255,255,0.1); }

/* Buttons */
.glass-btn-small { transition: all 0.2s; &:hover { background: rgba(255,255,255,0.05); color: white !important; } }
.glass-btn-icon-danger { transition: all 0.2s; &:hover { background: rgba(var(--v-theme-error), 0.15); transform: scale(1.1); } }

/* Menus */
.glass-menu { background: rgba(30, 30, 35, 0.95) !important; backdrop-filter: blur(10px); border: 1px solid rgba(255,255,255,0.1); }

/* KPIs */
.border-l-primary { border-left: 4px solid rgb(var(--v-theme-primary)); }
.border-l-info { border-left: 4px solid rgb(var(--v-theme-info)); }
.border-l-error { border-left: 4px solid rgb(var(--v-theme-error)); }
.icon-box { width: 44px; height: 44px; display: flex; align-items: center; justify-content: center; }
.bg-primary-10 { background: rgba(var(--v-theme-primary), 0.15); }
.bg-info-10 { background: rgba(var(--v-theme-info), 0.15); }
.bg-error-10 { background: rgba(var(--v-theme-error), 0.15); }

/* Utils */
.text-shadow { text-shadow: 0 2px 10px rgba(0,0,0,0.5); }
.shadow-glow-primary { box-shadow: 0 0 15px rgba(var(--v-theme-primary), 0.3); }
.text-white-50 { color: rgba(255,255,255,0.5) !important; }
.border-white-05 { border-color: rgba(255, 255, 255, 0.05) !important; }
.border-white-10 { border-color: rgba(255, 255, 255, 0.1) !important; }
.bg-glass-surface { background: rgba(255, 255, 255, 0.03); }
.width-180 { width: 180px; }
.h-24 { height: 24px; }
.letter-spacing-1 { letter-spacing: 1px; }

/* Scrollbar */
.custom-scrollbar::-webkit-scrollbar { width: 6px; }
.custom-scrollbar::-webkit-scrollbar-track { background: rgba(0,0,0,0.1); }
.custom-scrollbar::-webkit-scrollbar-thumb { background: rgba(255, 255, 255, 0.15); border-radius: 3px; }
</style>
