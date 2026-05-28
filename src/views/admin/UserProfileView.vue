<template>
  <div class="view-wrap profile-view" :class="isLightMode ? 'theme-light' : 'theme-dark'">
    <div v-if="isLoading" class="loading-state mj-surface mj-border">
      <v-progress-circular indeterminate color="primary" size="48" width="4" />
      <p>Carregando seu painel...</p>
    </div>

    <v-container v-else class="container-xl profile-container">
      <div class="profile-breadcrumb">
        <v-btn icon variant="tonal" size="small" class="back-btn" @click="router.back()">
          <v-icon>mdi-arrow-left</v-icon>
        </v-btn>
        <span>Portal Administrativo / <strong class="text-primary">{{ currentTabName }}</strong></span>
      </div>

      <div class="profile-layout">
        <aside class="profile-sidebar mj-surface mj-border">
          <div class="user-card">
            <div class="avatar-wrapper" @click="triggerAvatarUpload" :class="{ 'is-uploading': isUploadingAvatar }">
              <div v-if="isUploadingAvatar" class="avatar-loading-overlay">
                <v-progress-circular indeterminate color="white" size="24" width="3" />
              </div>
              <img v-else-if="profile?.avatar_url" :src="profile.avatar_url" alt="Avatar" class="user-avatar" />
              <div v-else class="avatar-placeholder">
                <v-icon size="36">mdi-account</v-icon>
              </div>
              <div class="avatar-overlay">
                <v-icon color="white" size="20">mdi-camera</v-icon>
              </div>
            </div>
            <input type="file" ref="fileInput" accept="image/*" class="d-none" @change="handleAvatarUpload" />

            <h2 class="user-name d-flex align-center justify-center gap-1">
              {{ profile?.full_name || 'Usuário Não Identificado' }}
              <v-icon v-if="userStore.isSuperAdmin" color="warning" size="22" class="vip-glow ml-1" title="Administrador Global">mdi-shield-crown-outline</v-icon>
            </h2>
            <p class="user-email">{{ userStore.user?.email }}</p>
          </div>

          <nav class="profile-nav scrollable-nav">
            <button class="nav-item" :class="{ active: activeTab === 'dados' }" @click="activeTab = 'dados'">
              <v-icon size="20" class="nav-icon">mdi-card-account-details-outline</v-icon>
              Dossiê Pessoal
            </button>
            <button class="nav-item" :class="{ active: activeTab === 'estrutura' }" @click="activeTab = 'estrutura'">
              <v-icon size="20" class="nav-icon">mdi-file-tree</v-icon>
              Hierarquia ERP
            </button>
            <button class="nav-item" :class="{ active: activeTab === 'seguranca' }" @click="activeTab = 'seguranca'">
              <v-icon size="20" class="nav-icon">mdi-shield-lock-outline</v-icon>
              Segurança & IPs
            </button>
            <button class="nav-item" :class="{ active: activeTab === 'preferencias' }" @click="activeTab = 'preferencias'">
              <v-icon size="20" class="nav-icon">mdi-tune-vertical-variant</v-icon>
              Preferências
            </button>
          </nav>

          <div class="sidebar-footer">
            <v-btn variant="text" color="error" block class="logout-btn" @click="handleLogout">
              <v-icon start>mdi-logout-variant</v-icon>
              Encerrar Sessão
            </v-btn>
          </div>
        </aside>

        <main class="profile-content">
          <transition name="fade" mode="out-in">
            <div class="tab-panel mj-surface mj-border" :key="activeTab">
              <component
                :is="currentComponent"
                :profile="profile"
                :user="userStore.user"
                :is-super-admin="userStore.isSuperAdmin"
                :role-name="userCustomRoleName"
                :role-description="roleDescription"
                :raw-permissions="rawPermissions"
                @refresh-profile="fetchProfileData"
              />
            </div>
          </transition>
        </main>
      </div>
    </v-container>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '@/api/supabase'
import { useUserStore } from '@/stores/user'
import { useAppStore } from '@/stores/app'
import { useThemeStore } from '@/stores/theme'
import { storeToRefs } from 'pinia'

import ProfileIdentityTab from '@/components/admin/profile/ProfileIdentityTab.vue'
import ProfileHierarchyTab from '@/components/admin/profile/ProfileHierarchyTab.vue'
import ProfileSecurityTab from '@/components/admin/profile/ProfileSecurityTab.vue'
import ProfilePreferencesTab from '@/components/admin/profile/ProfilePreferencesTab.vue'

const router = useRouter()
const userStore = useUserStore()
const appStore = useAppStore()
const themeStore = useThemeStore()
const { profile } = storeToRefs(userStore)

const isLightMode = computed(() => themeStore.currentMode === 'light')
const isLoading = ref(true)
const activeTab = ref('dados')
const fileInput = ref<HTMLInputElement | null>(null)
const isUploadingAvatar = ref(false)

const userCustomRoleName = ref('')
const roleDescription = ref('')
const rawPermissions = ref<string[]>([])

const menuItems = [
  { id: 'dados', label: 'Dossiê Pessoal', component: ProfileIdentityTab },
  { id: 'estrutura', label: 'Hierarquia ERP', component: ProfileHierarchyTab },
  { id: 'seguranca', label: 'Segurança & IPs', component: ProfileSecurityTab },
  { id: 'preferencias', label: 'Preferências', component: ProfilePreferencesTab },
]

const currentTabName = computed(() => menuItems.find(i => i.id === activeTab.value)?.label || 'Minha Conta')

const currentComponent = computed(() => {
  const tab = menuItems.find(i => i.id === activeTab.value)
  return tab ? tab.component : ProfileIdentityTab
})

const fetchHierarchyData = async () => {
  if (!profile.value?.custom_role_id) {
    rawPermissions.value = profile.value?.permissions || []
    return
  }
  try {
    const { data } = await supabase.from('custom_roles').select('*').eq('id', profile.value.custom_role_id).single()
    if (data) {
      userCustomRoleName.value = data.name
      roleDescription.value = data.description || ''
      rawPermissions.value = data.permissions || []
    }
  } catch (err) {
    console.error('Erro ao buscar cargo customizado', err)
  }
}

const fetchProfileData = async () => {
  await userStore.fetchProfile()
  await fetchHierarchyData()
}

const triggerAvatarUpload = () => { fileInput.value?.click() }

const handleAvatarUpload = async (event: Event) => {
  const file = (event.target as HTMLInputElement).files?.[0];
  if (!file) return;
  try {
    isUploadingAvatar.value = true;
    const path = `avatars/${userStore.user?.id}-${Date.now()}.${file.name.split('.').pop()}`;
    const { error } = await supabase.storage.from('customer_assets').upload(path, file);
    if (error) throw error;
    const { data: { publicUrl } } = supabase.storage.from('customer_assets').getPublicUrl(path);
    await supabase.from('profiles').update({ avatar_url: publicUrl }).eq('id', profile.value?.id);
    await fetchProfileData();
    appStore.showSnackbar('Imagem atualizada.', 'success');
  } catch {
    appStore.showSnackbar('Erro no upload de imagem.', 'error');
  } finally {
    isUploadingAvatar.value = false;
  }
}

const handleLogout = async () => { await userStore.signOut(); router.push('/login') }

onMounted(async () => {
  await fetchHierarchyData()
  isLoading.value = false
})
</script>

<style scoped>
/* =========================================================
   VARIÁVEIS DE TEMA (ESSENCIAL PARA O VISUAL DO ERP)
========================================================= */
.theme-light {
  --bg-main: #fbfbfd;
  --bg-glass: rgba(255, 255, 255, 0.7);
  --bg-surface-2: #ffffff;
  --border-color: rgba(0, 0, 0, 0.05);
  --text-main: #1d1d1f;
  --text-muted: rgba(29, 29, 31, 0.6);
  --shadow-premium: 0 4px 24px rgba(0, 0, 0, 0.03), 0 1px 2px rgba(0,0,0,0.01);
  --hover-shadow: 0 12px 32px rgba(0, 0, 0, 0.08);
  --surface-shadow: 0 8px 30px rgba(0, 0, 0, 0.04);
}

.theme-dark {
  --bg-main: #000000;
  --bg-glass: rgba(18, 18, 20, 0.6);
  --bg-surface-2: rgba(255, 255, 255, 0.02);
  --border-color: rgba(255, 255, 255, 0.06);
  --text-main: #f5f5f7;
  --text-muted: rgba(245, 245, 247, 0.6);
  --shadow-premium: 0 20px 50px rgba(0, 0, 0, 0.5), inset 0 1px 0 rgba(255,255,255,0.03);
  --hover-shadow: 0 16px 40px rgba(0, 0, 0, 0.6);
  --surface-shadow: 0 10px 40px rgba(0, 0, 0, 0.4);
}

.mj-surface { background: var(--bg-glass); backdrop-filter: blur(50px) saturate(180%); -webkit-backdrop-filter: blur(50px) saturate(180%); }
.mj-surface-2 { background: var(--bg-surface-2); }
.mj-border { border: 1px solid var(--border-color) !important; }

/* =========================================================
   ESTILOS IDÊNTICOS AO MARKETPLACE (COM RAIO DE 2PX)
========================================================= */
.view-wrap {
  padding-top: 82px;
}

.profile-view {
  min-height: calc(100vh - 82px);
  background: var(--bg-main);
  color: var(--text-main);
  transition: background 0.3s ease;
}

.loading-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 60vh;
  gap: 16px;
  border-radius: 2px;
  margin: 40px auto;
  max-width: 600px;
  color: var(--text-muted);
}

.profile-container {
  padding-top: 34px;
  padding-bottom: 60px;
}

.profile-breadcrumb {
  display: flex;
  align-items: center;
  gap: 12px;
  color: var(--text-muted);
  font-size: 12px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.08em;
  margin-bottom: 24px;
}

.back-btn {
  border-radius: 2px !important;
}

.profile-layout {
  display: grid;
  grid-template-columns: 290px 1fr;
  gap: 32px;
  align-items: start;
}

/* --- SIDEBAR --- */
.profile-sidebar {
  border-radius: 2px;
  overflow: hidden;
  position: sticky;
  top: 110px;
  display: flex;
  flex-direction: column;
  box-shadow: var(--surface-shadow);
}

.user-card {
  padding: 36px 24px;
  text-align: center;
  border-bottom: 1px solid var(--border-color);
  background: linear-gradient(180deg, rgba(var(--v-theme-primary), 0.03), transparent);
}

.avatar-wrapper {
  width: 96px;
  height: 96px;
  margin: 0 auto 16px;
  border-radius: 2px;
  position: relative;
  cursor: pointer;
  overflow: hidden;
  border: 4px solid var(--bg-surface);
  box-shadow: 0 12px 28px rgba(0,0,0,0.12);
  transition: transform 0.2s ease, box-shadow 0.2s ease;
}

.avatar-wrapper:hover:not(.is-uploading) {
  transform: scale(1.05);
  box-shadow: 0 16px 32px rgba(0,0,0,0.18);
}

.avatar-loading-overlay {
  position: absolute;
  inset: 0;
  background: rgba(var(--v-theme-primary), 0.8);
  display: grid;
  place-items: center;
  z-index: 2;
}

.user-avatar {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.avatar-placeholder {
  width: 100%;
  height: 100%;
  display: grid;
  place-items: center;
  background: var(--bg-surface-2);
  color: var(--text-muted);
}

.avatar-overlay {
  position: absolute;
  inset: 0;
  background: rgba(0,0,0,0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  opacity: 0;
  transition: opacity 0.2s ease;
}

.avatar-wrapper:hover:not(.is-uploading) .avatar-overlay {
  opacity: 1;
}

.user-name {
  color: var(--text-main);
  font-size: 1.15rem;
  font-weight: 800;
  margin: 0;
  letter-spacing: -0.01em;
}

.user-email {
  color: var(--text-muted);
  font-size: 0.85rem;
  margin-top: 4px;
}

.profile-nav {
  display: flex;
  flex-direction: column;
  padding: 16px;
  gap: 6px;
}

.nav-item {
  display: flex;
  align-items: center;
  gap: 14px;
  width: 100%;
  min-height: 50px;
  padding: 0 16px;
  border: 0;
  background: transparent;
  color: var(--text-muted);
  font-size: 0.95rem;
  font-weight: 700;
  border-radius: 2px;
  transition: all 0.2s ease;
  position: relative;
}

.nav-item:hover {
  background: var(--bg-surface-2);
  color: var(--text-main);
}

.nav-item.active {
  background: rgba(var(--v-theme-primary), 0.1);
  color: rgb(var(--v-theme-primary));
}

.nav-icon {
  opacity: 0.7;
}

.nav-item.active .nav-icon {
  opacity: 1;
}

.nav-badge {
  position: absolute;
  right: 16px;
  background: rgb(var(--v-theme-primary));
  color: #fff;
  font-size: 11px;
  font-weight: 800;
  padding: 2px 8px;
  border-radius: 2px;
  box-shadow: 0 4px 10px rgba(var(--v-theme-primary), 0.3);
}

.sidebar-footer {
  padding: 16px;
  margin-top: auto;
  border-top: 1px solid var(--border-color);
}

.logout-btn {
  border-radius: 2px !important;
  font-weight: 800 !important;
}

/* --- MAIN CONTENT --- */
.tab-panel {
  border-radius: 2px;
  padding: 36px;
  min-height: 600px;
  box-shadow: var(--surface-shadow);
}

.panel-header {
  margin-bottom: 36px;
  padding-bottom: 24px;
  border-bottom: 1px solid var(--border-color);
}

.panel-title {
  color: var(--text-main);
  font-size: 1.8rem;
  font-weight: 800;
  letter-spacing: -0.02em;
  margin: 0;
}

.panel-desc {
  color: var(--text-muted);
  font-size: 1rem;
  margin-top: 6px;
}

/* FORMULÁRIOS */
.form-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 24px;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.form-group label {
  color: var(--text-main);
  font-size: 0.85rem;
  font-weight: 800;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.mj-input {
  width: 100%;
  height: 56px;
  padding: 0 18px;
  border-radius: 2px;
  color: var(--text-main);
  font-size: 1.05rem;
  outline: none;
  transition: all 0.2s ease;
}

.mj-input:focus {
  border-color: rgba(var(--v-theme-primary), 0.65);
  box-shadow: 0 0 0 4px rgba(var(--v-theme-primary), 0.12);
  background: var(--bg-surface);
}

.form-actions {
  margin-top: 32px;
  display: flex;
  justify-content: flex-end;
}

.action-btn {
  border-radius: 2px !important;
  font-weight: 800 !important;
  padding: 0 36px !important;
  letter-spacing: 0.02em;
}

.security-section h4 {
  color: var(--text-main);
  font-size: 1.2rem;
  font-weight: 800;
}

/* TIMELINE DE PEDIDOS E PILOTOS */
.timeline-container {
  display: flex;
  flex-direction: column;
  gap: 24px;
}

.order-card {
  border-radius: 2px;
  padding: 28px;
  transition: transform 0.25s ease, box-shadow 0.25s ease;
}

.order-card:hover {
  transform: translateY(-4px);
  box-shadow: var(--hover-shadow);
}

.order-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 24px;
  padding-bottom: 20px;
  border-bottom: 1px solid var(--border-color);
}

.order-meta {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.order-id {
  color: var(--text-main);
  font-weight: 900;
  font-size: 1.2rem;
  letter-spacing: -0.01em;
}

.order-date {
  color: var(--text-muted);
  font-size: 0.9rem;
}

.order-status-badge {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 8px 16px;
  border-radius: 2px;
  font-size: 0.8rem;
  font-weight: 800;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  background: var(--bg-surface);
}

.status-dot {
  width: 8px;
  height: 8px;
  border-radius: 2px;
}

/* Status Colors */
.order-status-badge.pending, .order-status-badge.pending_payment { color: #d97706; background: rgba(245, 158, 11, 0.1); }
.order-status-badge.pending .status-dot, .order-status-badge.pending_payment .status-dot { background: #f59e0b; box-shadow: 0 0 0 3px rgba(245, 158, 11, 0.2); }

.order-status-badge.approved, .order-status-badge.in_production { color: #2563eb; background: rgba(59, 130, 246, 0.1); }
.order-status-badge.approved .status-dot, .order-status-badge.in_production .status-dot { background: #3b82f6; box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.2); }

.order-status-badge.completed, .order-status-badge.delivered, .order-status-badge.paid, .order-status-badge.shipped { color: #059669; background: rgba(16, 185, 129, 0.1); }
.order-status-badge.completed .status-dot, .order-status-badge.delivered .status-dot, .order-status-badge.paid .status-dot, .order-status-badge.shipped .status-dot { background: #10b981; box-shadow: 0 0 0 3px rgba(16, 185, 129, 0.2); }

.order-status-badge.cancelled, .order-status-badge.canceled { color: #dc2626; background: rgba(239, 68, 68, 0.1); }
.order-status-badge.cancelled .status-dot, .order-status-badge.canceled .status-dot { background: #ef4444; box-shadow: 0 0 0 3px rgba(239, 68, 68, 0.2); }

.order-items {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.order-item {
  display: flex;
  align-items: center;
  gap: 20px;
  padding: 12px;
  border-radius: 2px;
  background: var(--bg-surface);
}

.pilot-item {
  align-items: flex-start;
  padding: 20px;
}

.item-thumb {
  width: 72px;
  height: 72px;
  border-radius: 2px;
  object-fit: cover;
}

.pilot-item .item-thumb {
  width: 110px;
  height: 110px;
}

.item-info {
  flex: 1;
  display: flex;
  flex-direction: column;
}

.item-info strong {
  color: var(--text-main);
  font-size: 1.05rem;
  font-weight: 800;
}

.item-specs {
  color: var(--text-muted);
  font-size: 0.85rem;
  margin-top: 2px;
}

.item-price {
  color: var(--text-main);
}

.order-footer {
  margin-top: 24px;
  padding-top: 20px;
  border-top: 1px dashed var(--border-color);
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.total-label {
  color: var(--text-muted);
  font-weight: 800;
  text-transform: uppercase;
  font-size: 0.85rem;
  letter-spacing: 0.05em;
}

.total-value {
  font-size: 1.6rem;
  font-weight: 900;
  letter-spacing: -0.02em;
}

/* TABELA DE TRANSAÇÕES */
.table-responsive {
  overflow-x: auto;
}
.mj-table {
  border-collapse: collapse;
}
.mj-table th, .mj-table td {
  padding: 12px 16px;
}
.mj-table tr:not(:last-child) {
  border-bottom: 1px solid var(--border-color);
}

/* BIBLIOTECA PSD */
.library-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 24px;
}

.library-card {
  border-radius: 2px;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  transition: transform 0.25s ease, box-shadow 0.25s ease;
}

.library-card:hover {
  transform: translateY(-6px);
  box-shadow: var(--hover-shadow);
  border-color: rgba(var(--v-theme-primary), 0.3);
}

.library-image-wrap {
  position: relative;
  width: 100%;
  height: 200px;
}

.library-image {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.resolution-badge {
  position: absolute;
  top: 12px;
  right: 12px;
  background: rgba(0,0,0,0.7);
  color: #fff;
  backdrop-filter: blur(8px);
  padding: 4px 10px;
  border-radius: 2px;
  font-size: 10px;
  font-weight: 900;
  letter-spacing: 0.1em;
}

.library-info {
  padding: 24px;
  display: flex;
  flex-direction: column;
  flex: 1;
}

.lib-ref {
  color: var(--text-muted);
  font-size: 0.75rem;
  font-weight: 800;
  letter-spacing: 0.1em;
  text-transform: uppercase;
  margin-bottom: 8px;
}

.lib-title {
  color: var(--text-main);
  font-size: 1.15rem;
  font-weight: 800;
  line-height: 1.2;
  margin: 0 0 10px;
}

.lib-date {
  color: var(--text-muted);
  font-size: 0.85rem;
  margin-bottom: auto;
}

.download-btn {
  border-radius: 2px !important;
  font-weight: 800 !important;
  letter-spacing: 0.02em;
}

/* CARRINHO TAB */
.cart-list {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.cart-item {
  display: flex;
  align-items: center;
  gap: 24px;
  padding: 20px;
  border-radius: 2px;
}

.cart-image {
  width: 90px;
  height: 90px;
  border-radius: 2px;
  object-fit: cover;
}

.cart-info {
  flex: 1;
  display: flex;
  flex-direction: column;
}

.badge-physical, .badge-digital {
  font-size: 9px;
  font-weight: 800;
  text-transform: uppercase;
  letter-spacing: 0.1em;
  padding: 2px 6px;
  border-radius: 2px;
}

.badge-physical { background: rgba(var(--v-theme-primary), 0.15); color: rgb(var(--v-theme-primary)); }
.badge-digital { background: rgba(16, 185, 129, 0.15); color: #10b981; }

.cart-ref {
  color: var(--text-muted);
  font-size: 0.75rem;
  font-weight: 800;
  letter-spacing: 0.1em;
  text-transform: uppercase;
}

.cart-title {
  color: var(--text-main);
  font-size: 1.2rem;
  font-weight: 800;
  margin: 4px 0 6px;
}

.cart-specs {
  color: var(--text-muted);
  font-size: 0.9rem;
}

.remove-cart-btn {
  background: var(--bg-surface);
  border-radius: 2px;
}

.remove-cart-btn:hover {
  background: rgba(239, 68, 68, 0.1);
}

.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  text-align: center;
  padding: 80px 20px;
  color: var(--text-muted);
}

.empty-icon-wrap {
  width: 90px;
  height: 90px;
  border-radius: 2px;
  display: grid;
  place-items: center;
  margin-bottom: 24px;
}

.empty-state h4 {
  color: var(--text-main);
  font-size: 1.4rem;
  font-weight: 800;
  margin: 0 0 10px;
}

.empty-state p {
  margin-bottom: 24px;
  max-width: 420px;
  line-height: 1.6;
}

/* =========================================================
   DESTAQUES VIP DOURADOS SUTIS
========================================================= */
.vip-nav-btn.active {
  background: rgba(245, 158, 11, 0.1) !important;
}
.vip-text-gradient {
  background: linear-gradient(45deg, #F59E0B, #FCD34D, #F59E0B);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  font-weight: 900;
}
.vip-glow {
  filter: drop-shadow(0 0 8px rgba(245, 158, 11, 0.6));
}
.shadow-gold {
  box-shadow: 0 4px 15px rgba(245, 158, 11, 0.3) !important;
}
.vip-locked-state {
  border: 1px solid rgba(245, 158, 11, 0.3) !important;
  background: linear-gradient(180deg, rgba(245, 158, 11, 0.05) 0%, transparent 100%);
  padding: 80px 20px;
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
}

/* =========================================================
   COFRE DE ARTES VIP (3D GALLERY) & AUTODESTRUIÇÃO
========================================================= */
.vip-vault-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));
  gap: 24px;
}

.art-3d-wrapper {
  perspective: 1000px;
  transform-style: preserve-3d;
}

.art-3d-card {
  position: relative;
  border-radius: 2px;
  overflow: hidden;
  cursor: pointer;
  transform: rotateY(-12deg) rotateX(4deg);
  transition: transform 0.4s cubic-bezier(0.2, 0.8, 0.2, 1), box-shadow 0.4s ease;
  box-shadow: -10px 15px 25px rgba(0,0,0,0.3);
  background: #000;
  border: 1px solid rgba(255,255,255,0.1);
  aspect-ratio: 1;
}

.art-3d-card:hover {
  transform: rotateY(-4deg) rotateX(2deg) scale(1.05);
  box-shadow: -5px 10px 30px rgba(245, 158, 11, 0.4);
  border-color: #f59e0b;
}

.art-media-container {
  width: 100%;
  height: 100%;
}

.art-img-filter {
  transition: filter 0.4s ease;
}
.art-3d-card:hover .art-img-filter {
  filter: blur(2px) brightness(0.6);
}

.art-overlay {
  position: absolute;
  inset: 0;
  opacity: 0;
  transition: opacity 0.3s ease;
  background: rgba(0,0,0,0.4);
}

.art-3d-card:hover .art-overlay {
  opacity: 1;
}

/* ANIMAÇÃO DE AUTODESTRUIÇÃO (FOGO/DERRETIMENTO) */
.destructing {
  animation: burn-out 1.2s forwards cubic-bezier(0.4, 0, 0.2, 1);
  pointer-events: none;
}

@keyframes burn-out {
  0% { transform: scale(1); filter: brightness(1) sepia(0); opacity: 1; }
  20% { transform: scale(1.1); filter: brightness(2) sepia(1) hue-rotate(-50deg) saturate(5); box-shadow: 0 0 50px #ef4444; }
  50% { transform: scale(0.8) rotate(10deg); filter: blur(8px) brightness(3); opacity: 0.8; }
  100% { transform: scale(0) rotate(-15deg); filter: blur(15px); opacity: 0; }
}

.plagiarism-snackbar {
  z-index: 10000 !important;
}

.animate-pulse {
  animation: pulse 1s infinite;
}

@keyframes pulse {
  0% { transform: scale(1); opacity: 1; }
  50% { transform: scale(1.2); opacity: 0.8; }
  100% { transform: scale(1); opacity: 1; }
}

/* =========================================================
   PINTEREST MASONRY GRID (FAVORITOS)
========================================================= */
.pinterest-grid {
  column-count: 2;
  column-gap: 20px;
}
@media (min-width: 768px) {
  .pinterest-grid { column-count: 3; }
}
@media (min-width: 1024px) {
  .pinterest-grid { column-count: 4; }
}
@media (min-width: 1440px) {
  .pinterest-grid { column-count: 5; }
}

.pinterest-item {
  break-inside: avoid;
  margin-bottom: 20px;
  border-radius: 2px;
  overflow: hidden;
  transition: transform 0.25s ease, box-shadow 0.25s ease;
}
.pinterest-item:hover {
  transform: translateY(-4px);
  box-shadow: 0 16px 32px rgba(0,0,0,0.1);
}
.shadow-soft {
  box-shadow: 0 8px 24px rgba(0,0,0,0.15) !important;
}

/* Transições */
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.2s ease, transform 0.2s ease;
}
.fade-enter-from,
.fade-leave-to {
  opacity: 0;
  transform: translateY(10px);
}

/* RESPONSIVIDADE */
@media (max-width: 1199px) {
  .library-grid { grid-template-columns: repeat(2, 1fr); }
}

@media (max-width: 959px) {
  .profile-layout { grid-template-columns: 1fr; }
  .profile-sidebar { position: static; box-shadow: none; }
  .form-grid { grid-template-columns: 1fr; }
}

@media (max-width: 767px) {
  .tab-panel { padding: 24px; min-height: 400px; border-radius: 2px; }
  .panel-title { font-size: 1.4rem; }
  .library-grid { grid-template-columns: 1fr; }

  .order-item { flex-direction: column; align-items: flex-start; gap: 12px; }
  .item-thumb { width: 100%; height: 140px; }
  .pilot-item .item-thumb { width: 100%; height: 180px; }
  .item-price { margin-top: 8px; text-align: left; }

  .profile-container { width: min(100%, calc(100% - 20px)); padding-top: 20px; }
  .order-header { flex-direction: column; gap: 16px; }
  .order-footer { flex-direction: column; align-items: flex-start; gap: 8px; }

  .cart-item { flex-direction: column; align-items: flex-start; gap: 16px; position: relative; }
  .cart-image { width: 100%; height: 180px; }
  .remove-cart-btn { position: absolute; top: 16px; right: 16px; }

  .vip-vault-grid { grid-template-columns: repeat(2, 1fr); gap: 12px; }

  .mobile-price-left {
     align-items: flex-start !important;
     text-align: left !important;
     margin-top: 12px;
     width: 100%;
  }
  .mobile-price-left .v-btn, .mobile-price-left .bg-warning-lighten-5 {
     width: 100%;
     max-width: 100% !important;
     text-align: center !important;
     justify-content: center;
  }
}
</style>
