<template>
  <div
    class="view-wrap favorites-view font-sans relative"
    :class="isDark ? 'bg-glass-dark text-white' : 'bg-grey-lighten-5 text-grey-darken-4'"
  >
    <div v-if="isDark" class="background-carousel-wrapper">
      <v-carousel cycle height="100%" hide-delimiters :show-arrows="false" interval="15000" class="fill-height">
        <v-carousel-item src="@/assets/1.jpg" cover></v-carousel-item>
        <v-carousel-item src="@/assets/2.jpg" cover></v-carousel-item>
        <v-carousel-item src="@/assets/3.jpg" cover></v-carousel-item>
      </v-carousel>
      <div class="background-overlay"></div>
    </div>

    <div class="inside-folder-glow" :class="{ 'is-inside': currentFolderId !== null }"></div>

    <transition name="slide-up">
      <div
        v-if="isDragging && draggedItemType === 'stamp'"
        class="floating-drop-island d-flex align-center gap-3 px-4 py-3 mj-border shadow-xl mj-surface z-high"
      >
        <span class="text-[10px] font-weight-black text-uppercase opacity-70 letter-spacing-1 ml-2 d-none d-sm-block flex-shrink-0 text-main">
          <v-icon size="14" class="mr-1">mdi-arrow-down-drop-circle-outline</v-icon> Solte em:
        </span>

        <div class="d-flex align-center gap-2 overflow-x-auto custom-scroll-x px-1 pb-1" style="max-width: 80vw;">
            <div
              class="drop-folder-btn btn-3d d-flex align-center justify-center gap-2 px-4 py-2 transition-all flex-shrink-0 no-select mj-surface-2 mj-border text-main"
              :class="dragHoverBack && hoverFolderId === null ? 'drop-active' : ''"
              data-folder-id="home"
              @dragover.prevent.stop
              @dragenter.prevent.stop="hoverFolderId = null; dragHoverBack = true"
              @dragleave.prevent.stop="dragHoverBack = false"
              @drop.prevent.stop="onDropToParent"
            >
              <v-icon size="14" color="primary">mdi-home-variant-outline</v-icon>
              <span class="text-[11px] font-weight-bold">Início</span>
            </div>

            <div
              v-for="folder in availableFoldersToMove" :key="folder.id"
              class="drop-folder-btn btn-3d d-flex align-center justify-center gap-2 px-4 py-2 transition-all flex-shrink-0 no-select mj-surface-2 mj-border text-main"
              :class="hoverFolderId === folder.id ? 'drop-active' : ''"
              :data-folder-id="folder.id"
              @dragover.prevent.stop
              @dragenter.prevent.stop="hoverFolderId = folder.id"
              @dragleave.prevent.stop="hoverFolderId = null"
              @drop.prevent.stop="onDropToFolder($event, folder.id)"
            >
              <v-icon size="14" class="gold-gradient-icon">mdi-folder-star</v-icon>
              <span class="text-[11px] font-weight-bold text-truncate" style="max-width: 120px;">{{ folder.name }}</span>
            </div>
        </div>
      </div>
    </transition>

    <div v-if="isLoading" class="d-flex flex-column justify-center align-center py-16 z-10 relative" style="min-height: 60vh;">
      <v-progress-circular indeterminate color="primary" size="64" width="4"></v-progress-circular>
      <div class="mt-4 font-weight-black text-uppercase letter-spacing-1 opacity-70 text-[11px] text-main">Sincronizando Coleções...</div>
    </div>

    <div v-else class="content-wrapper z-10 relative">

      <section class="favorites-top mj-border mj-surface z-10 relative" style="border-bottom-width: 1px !important; background: transparent !important;">
        <div class="favorites-top-inner px-4 py-4 px-md-8 py-md-6 d-flex flex-column flex-md-row align-md-start justify-space-between" style="gap: 16px;">
          <div class="d-flex flex-column">
            <div class="breadcrumb text-caption d-flex align-center flex-wrap gap-2 font-weight-bold text-uppercase letter-spacing-1 text-muted">
              <span class="cursor-pointer hover-primary transition-colors" @click="navigateToFolder(null)">
                <v-icon size="14" class="mr-1">mdi-home-variant-outline</v-icon> INÍCIO
              </span>
              <template v-for="crumb in folderBreadcrumbs" :key="crumb.id">
                <v-icon size="14" class="opacity-50">mdi-chevron-right</v-icon>
                <span class="cursor-pointer hover-primary transition-colors text-primary" @click="navigateToFolder(crumb.id)">
                  {{ crumb.name }}
                </span>
              </template>
            </div>
            <div class="text-h4 font-weight-black tracking-tight leading-none mt-2 text-main">
              {{ currentFolderId ? folderBreadcrumbs[folderBreadcrumbs.length - 1]?.name : 'Meu Acervo' }}
            </div>
          </div>

          <div class="d-flex align-center mt-2 mt-md-0" style="gap: 10px;">
            <v-btn
              color="primary"
              variant="flat"
              class="btn-3d px-6 font-weight-black text-caption text-uppercase letter-spacing-1 shadow-primary"
              prepend-icon="mdi-folder-plus-outline"
              height="44"
              @click="showCreateFolderModal = true"
            >
              Nova Pasta
            </v-btn>
          </div>
        </div>
      </section>

      <section class="favorites-grid-wrap pt-6 pb-16 z-10 relative">
        <div class="fluid-container">

          <transition name="fade">
            <div
              v-if="isDragging && currentFolderId !== null"
              class="back-dropzone mj-surface mj-border rounded-xl d-flex align-center justify-center mb-6 transition-all"
              :class="dragHoverBack ? 'drop-active border-primary shadow-primary' : 'border-dashed'"
              style="border-width: 2px !important;"
              @dragover.prevent
              @dragenter.prevent="dragHoverBack = true"
              @dragleave.prevent="dragHoverBack = false"
              @drop.prevent.stop="onDropToParent"
            >
              <v-icon size="32" :color="dragHoverBack ? 'primary' : 'inherit'" class="mr-3 text-muted">mdi-arrow-up-left</v-icon>
              <h3 class="text-h6 font-weight-black m-0 text-main" :class="dragHoverBack ? 'text-primary' : ''">Solte para mover à pasta anterior</h3>
            </div>
          </transition>

          <transition name="fade" mode="out-in">
            <div v-if="currentFolders.length > 0" class="mb-10" :key="`folders-${currentFolderId}`">
              <h3 class="text-[11px] font-weight-black text-uppercase letter-spacing-1 mb-4 opacity-70 d-flex align-center gap-2 text-main">
                <v-icon size="14">mdi-folder-multiple</v-icon> Coleções
              </h3>

              <div class="folders-grid">
                <div
                  v-for="folder in currentFolders"
                  :key="folder.id"
                  class="folder-card btn-3d pa-3 position-relative no-select transition-all d-flex align-center gap-4 mj-surface mj-border text-main"
                  :class="[
                    hoverFolderId === folder.id ? 'drop-active' : '',
                    isTouchDragging && draggedItemData?.id === folder.id ? 'is-touch-dragging' : ''
                  ]"
                  :data-folder-id="folder.id"
                  @click="navigateToFolder(folder.id)"

                  draggable="true"
                  @dragstart="onDragStart($event, 'folder', folder)"
                  @dragend="onDragEnd"
                  @dragover.prevent.stop
                  @dragenter.prevent.stop="hoverFolderId = folder.id"
                  @dragleave.prevent.stop="hoverFolderId = null"
                  @drop.prevent.stop="onDropToFolder($event, folder.id)"

                  @touchstart="handleTouchStart($event, 'folder', folder)"
                  @touchmove="handleTouchMove"
                  @touchend="handleTouchEnd"
                  @contextmenu.prevent
                >
                  <div class="folder-icon-wrap rounded-lg pointer-events-none mj-surface-2 position-relative overflow-hidden" style="width: 56px; height: 56px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; box-shadow: inset 0 2px 4px rgba(0,0,0,0.05);">
                    <div class="folder-glow-inner"></div>
                    <v-icon size="32" class="gold-gradient-icon z-10 relative">mdi-folder-star</v-icon>
                  </div>

                  <div class="folder-info d-flex flex-column flex-grow-1 min-w-0 pointer-events-none lh-1">
                    <h4 class="text-body-1 font-weight-black m-0 text-truncate" style="letter-spacing: -0.02em;">{{ folder.name }}</h4>
                    <p class="text-[10px] font-weight-bold text-uppercase letter-spacing-1 opacity-60 m-0 mt-1">{{ getItemsCountInFolder(folder.id) }} itens</p>
                  </div>

                  <v-menu location="bottom end">
                    <template v-slot:activator="{ props }">
                      <v-btn
                        icon="mdi-dots-vertical"
                        variant="text"
                        size="small"
                        class="opacity-50 hover-opacity-100 folder-menu-btn text-main"
                        v-bind="props"
                        @click.stop
                        @touchstart.stop
                      ></v-btn>
                    </template>
                    <v-list density="compact" class="mj-border shadow-lg rounded-lg mj-surface">
                      <v-list-item @click="openFolderOptions(folder)">
                        <template v-slot:prepend><v-icon size="16" class="mr-2 text-main">mdi-pencil</v-icon></template>
                        <v-list-item-title class="text-caption font-weight-bold text-main">Renomear</v-list-item-title>
                      </v-list-item>
                      <v-list-item @click="openMoveModal('folder', folder)" class="d-md-none">
                        <template v-slot:prepend><v-icon size="16" class="mr-2 text-main">mdi-folder-move</v-icon></template>
                        <v-list-item-title class="text-caption font-weight-bold text-main">Mover Pasta</v-list-item-title>
                      </v-list-item>
                      <v-divider class="my-1"></v-divider>
                      <v-list-item @click="deleteFolder(folder.id)">
                        <template v-slot:prepend><v-icon size="16" class="mr-2 text-error">mdi-delete</v-icon></template>
                        <v-list-item-title class="text-caption font-weight-bold text-error">Excluir</v-list-item-title>
                      </v-list-item>
                    </v-list>
                  </v-menu>
                </div>
              </div>
            </div>
          </transition>

          <transition name="fade" mode="out-in">
            <div :key="`stamps-${currentFolderId}`">
              <div class="d-flex align-center justify-space-between mb-4">
                <h3 class="text-[11px] font-weight-black text-uppercase letter-spacing-1 opacity-70 d-flex align-center gap-2 m-0 text-main">
                  <v-icon size="14">mdi-image-multiple</v-icon> Estampas Salvas
                </h3>
                <span class="text-[10px] font-weight-bold opacity-60 mj-surface-2 px-2 py-0.5 rounded text-main">{{ currentStamps.length }} itens</span>
              </div>

              <div v-if="currentStamps.length > 0" class="stamps-masonry">
                <div
                  v-for="item in currentStamps"
                  :key="item.id"
                  class="stamp-card library-card-3d mj-border rounded-xl overflow-hidden position-relative no-select transition-all mj-surface"
                  :class="isTouchDragging && draggedItemData?.id === item.id ? 'is-touch-dragging' : ''"
                  draggable="true"
                  @dragstart="onDragStart($event, 'stamp', item)"
                  @dragend="onDragEnd"
                  @touchstart="handleTouchStart($event, 'stamp', item)"
                  @touchmove="handleTouchMove"
                  @touchend="handleTouchEnd"
                  @contextmenu.prevent
                >
                  <div class="stamp-media-wrap cursor-pointer position-relative w-100" @click="!isTouchDragging && router.push(`/marketplace/produto/${item.stamp.id}`)">

                    <img :src="getOptimizedUrl(item.stamp.main_image_url, 600)" @error="handleImageError" loading="lazy" class="stamp-img w-100" />

                    <div class="position-absolute bottom-0 left-0 w-100 pt-8 pb-3 px-3 bg-gradient-to-t pointer-events-none d-flex align-end justify-space-between">
                      <span class="text-[10px] font-mono font-weight-black text-white bg-black-50 px-2 py-1 rounded backdrop-blur border border-white-10">
                        {{ item.stamp.ref_code }}
                      </span>
                      <v-icon v-if="item.stamp.stamp_type === 'Barrado'" size="14" color="warning">mdi-border-bottom</v-icon>
                    </div>

                    <div class="drag-handle-overlay position-absolute inset-0 d-none d-md-flex align-center justify-center pointer-events-none">
                      <v-icon size="36" color="white" class="drop-shadow-icon">mdi-drag</v-icon>
                    </div>

                    <div class="position-absolute top-0 left-0 w-100 pa-2 d-flex justify-space-between align-start z-20 pointer-events-none">
                      <v-btn
                        icon="mdi-folder-move"
                        :color="isDark ? 'grey-darken-3' : 'white'"
                        size="small"
                        variant="flat"
                        class="btn-3d shadow-soft pointer-events-auto move-btn"
                        @click.stop="openMoveModal('stamp', item)"
                        @touchstart.stop
                        title="Mover para uma Pasta"
                      ></v-btn>

                      <v-btn
                        icon="mdi-heart"
                        color="error"
                        size="small"
                        variant="flat"
                        class="btn-3d shadow-soft pointer-events-auto heart-btn"
                        @click.stop="removeFavorite(item.mapping_id, item.stamp.id)"
                        @touchstart.stop
                        title="Remover dos favoritos"
                      ></v-btn>
                    </div>
                  </div>

                  <div class="stamp-meta pa-3 mj-surface-2 border-t cursor-pointer" :class="isDark ? 'border-white-10' : 'border-grey-lighten-2'" @click="!isTouchDragging && router.push(`/marketplace/produto/${item.stamp.id}`)">
                    <h4 class="text-body-2 font-weight-black m-0 text-truncate lh-1 text-main" :title="item.stamp.title">{{ item.stamp.title }}</h4>
                  </div>
                </div>
              </div>

              <div v-else class="empty-state-premium mj-surface-2 mj-border border-dashed rounded-xl py-16 d-flex flex-column align-center justify-center text-center relative overflow-hidden">
                <div class="empty-glow-orb"></div>
                <v-icon size="64" class="opacity-50 mb-4 text-muted">mdi-shape-plus-outline</v-icon>
                <h3 class="text-h5 font-weight-black m-0 mb-2 text-main">Pasta Vazia</h3>
                <p class="text-body-2 font-weight-bold opacity-70 max-w-sm mx-auto mb-6 lh-1 text-muted">
                  Arraste estampas para cá, ou explore o catálogo para adicionar novos favoritos.
                </p>
                <v-btn color="primary" class="btn-3d font-weight-black px-8" height="44" @click="router.push('/marketplace/catalogo')">
                  Explorar Acervo
                </v-btn>
              </div>
            </div>
          </transition>

        </div>
      </section>
    </div> <v-dialog v-model="showCreateFolderModal" max-width="400">
      <v-card class="rounded-xl overflow-hidden mj-surface mj-border text-main shadow-2xl">
        <div class="pa-4 border-b d-flex align-center justify-space-between mj-surface-2 mj-border">
          <span class="text-subtitle-1 font-weight-black"><v-icon start>mdi-folder-plus</v-icon> Criar Nova Pasta</span>
          <button class="micro-btn-3d neutral icon-only" @click="showCreateFolderModal = false"><v-icon size="14">mdi-close</v-icon></button>
        </div>
        <div class="pa-6">
          <input
            v-model="newFolderName"
            type="text"
            placeholder="Nome da pasta (Ex: Verão 2026)"
            class="mj-input w-100 mj-border rounded-lg px-4 mj-surface-2 text-main"
            autofocus
            @keyup.enter="createFolder"
          />
        </div>
        <div class="pa-4 border-t d-flex justify-end gap-3 mj-border">
          <v-btn variant="outlined" class="btn-3d font-weight-bold" height="40" @click="showCreateFolderModal = false" :color="isDark ? 'white' : 'grey-darken-3'">Cancelar</v-btn>
          <v-btn color="primary" variant="flat" class="btn-3d font-weight-black px-6" height="40" :loading="creatingFolder" @click="createFolder" :disabled="!newFolderName.trim()">
            Criar Pasta
          </v-btn>
        </div>
      </v-card>
    </v-dialog>

    <v-dialog v-model="showMoveModal" max-width="400">
      <v-card class="rounded-xl overflow-hidden mj-surface mj-border text-main shadow-2xl">
        <div class="pa-4 border-b d-flex align-center justify-space-between mj-surface-2 mj-border">
          <span class="text-subtitle-1 font-weight-black"><v-icon start>mdi-folder-move</v-icon> Mover para...</span>
          <button class="micro-btn-3d neutral icon-only" @click="showMoveModal = false"><v-icon size="14">mdi-close</v-icon></button>
        </div>
        <div class="pa-4 custom-scroll" style="max-height: 60vh; overflow-y: auto;">
          <v-list class="bg-transparent pa-0">
            <v-list-item
              v-if="currentFolderId !== null"
              @click="moveToFolder(null)"
              class="mb-2 rounded-lg mj-surface-2 mj-border cursor-pointer transition-all hover-bg-surface"
            >
              <template v-slot:prepend><v-icon color="primary" class="mr-3">mdi-home-variant-outline</v-icon></template>
              <v-list-item-title class="font-weight-bold text-body-2 text-main">Início (Raiz)</v-list-item-title>
            </v-list-item>

            <v-list-item
              v-for="folder in availableFoldersToMove"
              :key="folder.id"
              @click="moveToFolder(folder.id)"
              class="mb-2 rounded-lg mj-surface-2 mj-border cursor-pointer transition-all hover-bg-surface"
            >
              <template v-slot:prepend><v-icon class="gold-gradient-icon mr-3">mdi-folder-star</v-icon></template>
              <v-list-item-title class="font-weight-bold text-body-2 text-main">{{ folder.name }}</v-list-item-title>
            </v-list-item>

            <div v-if="!availableFoldersToMove.length && currentFolderId === null" class="text-center py-6 opacity-50">
              <v-icon size="32" class="mb-2 text-muted">mdi-folder-remove-outline</v-icon>
              <p class="m-0 text-[11px] font-weight-bold text-uppercase letter-spacing-1 text-main">Nenhuma pasta disponível.</p>
            </div>
          </v-list>
        </div>
      </v-card>
    </v-dialog>

    <ImageModal :show="showImageModal" :image-url="selectedImageSrc" :file-name="selectedImageTitle" @close="closeArtModal" />

    <transition name="fade">
      <div v-if="showCopyrightWarning" class="copyright-warning-overlay z-high">
        <div class="copyright-warning-card mj-border">
          <div class="warning-icon-wrap">
            <v-icon size="42" color="error">mdi-shield-alert-outline</v-icon>
          </div>
          <h3 class="warning-title">Ação Interceptada</h3>
          <p class="warning-desc">
            Nossas estampas são protegidas por direitos autorais. O download, cópia de código ou uso de ferramentas de inspeção não são permitidos.
          </p>
          <div class="strike-indicator">
            <div v-for="i in 3" :key="i" class="strike-dot" :class="{ 'filled-error': i <= (3 - copyrightStrikesLeft) }"></div>
          </div>
          <p class="strike-text mb-6" :class="{ 'text-error font-weight-bold': copyrightStrikesLeft === 1 }">
            {{ copyrightStrikesLeft > 0 ? `Aviso ${4 - copyrightStrikesLeft} de 3. Reincidência causará suspensão.` : 'Sua sessão foi bloqueada por violação de segurança.' }}
          </p>
          <v-btn color="error" variant="flat" class="w-100 font-weight-bold text-none rounded-lg btn-3d" height="48" @click="acknowledgeWarning">
            Estou Ciente
          </v-btn>
        </div>
      </div>
    </transition>

  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted, watch } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '@/api/supabase'
import { useMarketplaceUserStore } from '@/stores/marketplaceUser'
import { useThemeStore } from '@/stores/theme'
import { useProtectionStore } from '@/stores/protectionStore'
import ImageModal from '@/components/ImageModal.vue'

const router = useRouter()
const userStore = useMarketplaceUserStore()
const themeStore = useThemeStore()
const protectionStore = useProtectionStore()

const isDark = computed(() => themeStore.currentMode !== 'light')
const isLoading = ref(true)

// ==========================================
// ESTADOS DB-DRIVEN
// ==========================================
const userLeadId = ref<string | null>(null)
const folders = ref<any[]>([])
const favoritesItems = ref<any[]>([])

const currentFolderId = ref<string | null>(null)
const showCreateFolderModal = ref(false)
const newFolderName = ref('')
const creatingFolder = ref(false)

const showMoveModal = ref(false)
const itemToMove = ref<any>(null)
const typeToMove = ref<'stamp' | 'folder'>('stamp')

const showImageModal = ref(false)
const selectedImageSrc = ref('')
const selectedImageTitle = ref('')

// ==========================================
// ANTI-PLÁGIO (IGUAL DISCOVER)
// ==========================================
const showCopyrightWarning = ref(false)
const copyrightStrikesLeft = ref(3)

watch(() => protectionStore.accessStatus, (newStatus) => {
  if (newStatus === 'blocked') {
    localStorage.removeItem('mj_active_code')
    router.push({ name: 'MarketplaceLogin', query: { blocked: 'true' } })
  }
})

function triggerPlagiarismWarning(e: Event) {
  e.preventDefault()
  if (showCopyrightWarning.value) return;
  protectionStore.registerPlagiarismAttempt()
  const strikes = protectionStore.plagiarismStrikes
  copyrightStrikesLeft.value = Math.max(0, 3 - strikes)
  showCopyrightWarning.value = true
}

function acknowledgeWarning() {
  showCopyrightWarning.value = false;
  if (protectionStore.plagiarismStrikes >= 3 || protectionStore.accessStatus === 'blocked') {
    localStorage.removeItem('mj_active_code');
    router.push({ name: 'MarketplaceLogin', query: { blocked: 'true' } });
  }
}

function handleSecurityKeydown(e: KeyboardEvent) {
  if (e.key === 'F12') { triggerPlagiarismWarning(e); return; }
  if (e.ctrlKey && e.shiftKey && ['I', 'J', 'C'].includes(e.key.toUpperCase())) { triggerPlagiarismWarning(e); return; }
  if (e.ctrlKey && ['U', 'S', 'P'].includes(e.key.toUpperCase())) { triggerPlagiarismWarning(e); return; }
}

function handleGlobalContextMenu(e: MouseEvent) {
  triggerPlagiarismWarning(e)
}

// ==========================================
// DRAG AND DROP ESTADOS
// ==========================================
const isDragging = ref(false)
const dragHoverBack = ref(false)
const hoverFolderId = ref<string | null>(null)
const draggedItemType = ref('')
const draggedItemData = ref<any>(null)

const isTouchDragging = ref(false)
const activeTouchClone = ref<HTMLElement | null>(null)
let touchPressTimer: any = null

// ==========================================
// COMPUTEDS
// ==========================================
const folderBreadcrumbs = computed(() => {
  const crumbs = []
  let curr = currentFolderId.value
  while (curr) {
    const f = folders.value.find(x => x.id === curr)
    if (f) {
      crumbs.unshift(f)
      curr = f.parent_id || null
    } else {
      break
    }
  }
  return crumbs
})

const currentFolders = computed(() => {
  return folders.value.filter(f => (f.parent_id || null) === currentFolderId.value)
})

const currentStamps = computed(() => {
  return favoritesItems.value.filter(s => (s.folder_id || null) === currentFolderId.value)
})

const availableFoldersToMove = computed(() => {
  return folders.value.filter(f => {
    if (f.id === currentFolderId.value) return false
    if (typeToMove.value === 'folder' && itemToMove.value) {
      if (f.id === itemToMove.value.id) return false
      if (f.parent_id === itemToMove.value.id) return false
    }
    return true
  })
})

function getItemsCountInFolder(folderId: string) {
  const directStamps = favoritesItems.value.filter(s => s.folder_id === folderId).length
  const directFolders = folders.value.filter(f => f.parent_id === folderId).length
  return directStamps + directFolders
}

// ==========================================
// LIFECYCLE E DB CALLS
// ==========================================
onMounted(async () => {
  isLoading.value = true
  try {
    if (!userStore.isAuthenticated) {
      router.push('/marketplace-login')
      return
    }

    await protectionStore.initializeGuard()
    protectionStore.setContext('favorites')
    window.addEventListener('contextmenu', handleGlobalContextMenu)
    window.addEventListener('keydown', handleSecurityKeydown)

    const { data: { session } } = await supabase.auth.getSession()
    if (session?.user?.email) {
      const { data: lead } = await supabase.from('public_leads').select('id').eq('email', session.user.email).maybeSingle()
      if (lead) userLeadId.value = lead.id
    }

    await loadDatabaseData()
  } catch (error) {
    console.error('Erro na inicialização:', error)
  } finally {
    isLoading.value = false
  }
})

onUnmounted(() => {
  window.removeEventListener('contextmenu', handleGlobalContextMenu)
  window.removeEventListener('keydown', handleSecurityKeydown)
})

async function loadDatabaseData() {
  if (!userLeadId.value) return

  const { data: fData } = await supabase.from('marketplace_favorite_folders').select('*').eq('lead_id', userLeadId.value).order('created_at', { ascending: true })
  if (fData) folders.value = fData

  const { data: mData } = await supabase.from('marketplace_favorite_items').select('*').eq('lead_id', userLeadId.value)
  const mappings = mData || []

  if (!userStore.wishlist || userStore.wishlist.length === 0) {
    favoritesItems.value = []
    return
  }

  const { data: sData } = await supabase.from('catalog_stamps').select('*').in('id', userStore.wishlist).eq('is_active', true)

  if (sData) {
    favoritesItems.value = sData.map(stamp => {
      const mapping = mappings.find(m => m.stamp_id === stamp.id)
      return {
        id: mapping ? mapping.id : `temp_${stamp.id}`,
        mapping_id: mapping?.id || null,
        stamp_id: stamp.id,
        folder_id: mapping?.folder_id || null,
        stamp: stamp
      }
    })
  }
}

// ==========================================
// AÇÕES CRUD
// ==========================================
async function createFolder() {
  if (!newFolderName.value.trim() || !userLeadId.value) return
  creatingFolder.value = true

  try {
    const payload: any = {
      lead_id: userLeadId.value,
      name: newFolderName.value.trim()
    }
    if (currentFolderId.value) {
      payload.parent_id = currentFolderId.value
    }

    const { data, error } = await supabase.from('marketplace_favorite_folders').insert(payload).select().single()

    if (error) throw error
    if (data) folders.value.push(data)

    newFolderName.value = ''
    showCreateFolderModal.value = false
  } catch(e: any) {
    alert('Erro ao criar pasta: ' + e.message)
  } finally {
    creatingFolder.value = false
  }
}

function navigateToFolder(id: string | null) {
  currentFolderId.value = id
}

async function removeFavorite(mappingId: string, stampId: string) {
  await userStore.toggleWishlist(stampId)
  if (mappingId && !mappingId.startsWith('temp_')) {
    try { await supabase.from('marketplace_favorite_items').delete().eq('id', mappingId) } catch(e) {}
  }
  favoritesItems.value = favoritesItems.value.filter(s => s.stamp_id !== stampId)
}

async function deleteFolder(folderId: string) {
  if(!confirm('Excluir esta pasta? Suas estampas NÃO serão apagadas, retornarão para o INÍCIO.')) return

  try {
    await supabase.from('marketplace_favorite_folders').delete().eq('id', folderId)
    folders.value = folders.value.filter(f => f.id !== folderId)

    favoritesItems.value.forEach(item => {
      if (item.folder_id === folderId) item.folder_id = null
    })
    folders.value.forEach(f => {
      if (f.parent_id === folderId) f.parent_id = null
    })

  } catch(e: any) {
    alert('Erro ao excluir: ' + e.message)
  }
}

async function executeDropLogic(targetFolderId: string | null) {
  if (draggedItemType.value === 'stamp' && userLeadId.value) {
    const item = favoritesItems.value.find(s => s.stamp_id === draggedItemData.value.stamp_id)
    if (item && item.folder_id !== targetFolderId) {
      item.folder_id = targetFolderId
      try {
        const { data, error } = await supabase.from('marketplace_favorite_items').upsert({
          id: item.mapping_id || undefined,
          lead_id: userLeadId.value,
          stamp_id: item.stamp_id,
          folder_id: targetFolderId
        }, { onConflict: 'lead_id,stamp_id' }).select().single()

        if (data) item.mapping_id = data.id
      } catch (e) { console.error(e) }
    }
  } else if (draggedItemType.value === 'folder' && userLeadId.value) {
    if (draggedItemData.value.id === targetFolderId) return
    const f = folders.value.find(x => x.id === draggedItemData.value.id)
    if (f && f.parent_id !== targetFolderId) {
      f.parent_id = targetFolderId
      try { await supabase.from('marketplace_favorite_folders').update({ parent_id: targetFolderId }).eq('id', f.id) } catch(e) {}
    }
  }
}

function executeDropToParent() {
  const targetId = currentFolderId.value ? (folders.value.find(f => f.id === currentFolderId.value)?.parent_id || null) : null
  executeDropLogic(targetId)
}

// ==========================================
// FALLBACK MODAL (MOVIMENTAÇÃO)
// ==========================================
function openMoveModal(type: 'stamp' | 'folder', item: any) {
  typeToMove.value = type
  itemToMove.value = item
  showMoveModal.value = true
}

function moveToFolder(targetFolderId: string | null) {
  draggedItemType.value = typeToMove.value
  draggedItemData.value = itemToMove.value
  executeDropLogic(targetFolderId)
  showMoveModal.value = false
}

function openFolderOptions(folder: any) {
  const newName = prompt('Renomear pasta:', folder.name)
  if (newName && newName.trim()) {
    updateFolderName(folder.id, newName.trim())
  }
}

async function updateFolderName(id: string, newName: string) {
  try {
    await supabase.from('marketplace_favorite_folders').update({ name: newName }).eq('id', id)
    const f = folders.value.find(x => x.id === id)
    if (f) f.name = newName
  } catch (e) {}
}

// ==========================================
// DRAG AND DROP NATIVO (DESKTOP)
// ==========================================
function onDragStart(event: DragEvent, type: string, data: any) {
  isDragging.value = true
  draggedItemType.value = type
  draggedItemData.value = data
  if (event.dataTransfer) {
    event.dataTransfer.effectAllowed = 'move'
    const img = new Image()
    img.src = 'data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7'
    event.dataTransfer.setDragImage(img, 0, 0)
  }
}

function onDragEnd() {
  isDragging.value = false
  hoverFolderId.value = null
  dragHoverBack.value = false
}

function onDropToFolder(event: DragEvent, targetFolderId: string) {
  hoverFolderId.value = null
  executeDropLogic(targetFolderId)
}

function onDropToParent() {
  dragHoverBack.value = false
  executeDropToParent()
}

// ==========================================
// DRAG AND DROP CUSTOMIZADO (MOBILE TOUCH)
// ==========================================
function handleTouchStart(event: TouchEvent, type: 'stamp' | 'folder', data: any) {
  touchPressTimer = setTimeout(() => {
    isTouchDragging.value = true
    isDragging.value = true
    draggedItemType.value = type
    draggedItemData.value = data

    if (navigator.vibrate) navigator.vibrate(50)

    const targetElem = (event.target as HTMLElement).closest('.stamp-card, .folder-card') as HTMLElement
    if (targetElem) {
      const clone = targetElem.cloneNode(true) as HTMLElement
      const rect = targetElem.getBoundingClientRect()

      clone.style.position = 'fixed'
      clone.style.zIndex = '9999'
      clone.style.width = `${rect.width}px`
      clone.style.height = `${rect.height}px`
      clone.style.opacity = '0.9'
      clone.style.transform = 'scale(1.05) rotate(2deg)'
      clone.style.boxShadow = '0 20px 40px rgba(0,0,0,0.4)'
      clone.style.pointerEvents = 'none'

      const touch = event.touches[0]
      const offsetX = touch.clientX - rect.left
      const offsetY = touch.clientY - rect.top

      clone.dataset.offsetX = String(offsetX)
      clone.dataset.offsetY = String(offsetY)
      clone.style.left = `${touch.clientX - offsetX}px`
      clone.style.top = `${touch.clientY - offsetY}px`

      document.body.appendChild(clone)
      activeTouchClone.value = clone
    }
  }, 400)
}

function handleTouchMove(event: TouchEvent) {
  if (!isTouchDragging.value) { clearTimeout(touchPressTimer); return }
  if (event.cancelable) event.preventDefault()

  if (activeTouchClone.value) {
    const touch = event.touches[0]
    const offsetX = Number(activeTouchClone.value.dataset.offsetX || 0)
    const offsetY = Number(activeTouchClone.value.dataset.offsetY || 0)

    activeTouchClone.value.style.left = `${touch.clientX - offsetX}px`
    activeTouchClone.value.style.top = `${touch.clientY - offsetY}px`

    activeTouchClone.value.style.display = 'none'
    const elemBelow = document.elementFromPoint(touch.clientX, touch.clientY)
    activeTouchClone.value.style.display = 'block'

    if (elemBelow) {
      const folderCard = elemBelow.closest('.folder-card') as HTMLElement
      const dropBtn = elemBelow.closest('.drop-folder-btn') as HTMLElement
      const backZone = elemBelow.closest('.back-dropzone')

      if (folderCard) {
        hoverFolderId.value = folderCard.dataset.folderId || null
        dragHoverBack.value = false
      } else if (dropBtn) {
        const fid = dropBtn.dataset.folderId
        if (fid === 'home') {
          dragHoverBack.value = true
          hoverFolderId.value = null
        } else {
          hoverFolderId.value = fid || null
          dragHoverBack.value = false
        }
      } else if (backZone) {
        dragHoverBack.value = true
        hoverFolderId.value = null
      } else {
        hoverFolderId.value = null
        dragHoverBack.value = false
      }
    }
  }
}

function handleTouchEnd(event: TouchEvent) {
  clearTimeout(touchPressTimer)
  if (!isTouchDragging.value) return

  const touch = event.changedTouches[0]

  if (activeTouchClone.value) {
    activeTouchClone.value.style.display = 'none'
    const elemBelow = document.elementFromPoint(touch.clientX, touch.clientY)

    if (elemBelow) {
      const folderCard = elemBelow.closest('.folder-card') as HTMLElement
      const dropBtn = elemBelow.closest('.drop-folder-btn') as HTMLElement
      const backZone = elemBelow.closest('.back-dropzone')

      if (folderCard && folderCard.dataset.folderId) {
        executeDropLogic(folderCard.dataset.folderId)
      } else if (dropBtn && dropBtn.dataset.folderId) {
        if (dropBtn.dataset.folderId === 'home') executeDropToParent()
        else executeDropLogic(dropBtn.dataset.folderId)
      } else if (backZone) {
        executeDropToParent()
      }
    }
    activeTouchClone.value.remove()
    activeTouchClone.value = null
  }

  isTouchDragging.value = false
  isDragging.value = false
  hoverFolderId.value = null
  dragHoverBack.value = false
}

// UTILITÁRIO IMAGEM
function getOptimizedUrl(originalUrl: string | null | undefined, targetWidth: number) {
  if (!originalUrl) return '/placeholder.png'
  if (!originalUrl.includes('supabase.co') || !originalUrl.includes('/object/public/')) return originalUrl
  try {
    const urlParts = originalUrl.split('/object/public/')
    const bucket = urlParts[1].substring(0, urlParts[1].indexOf('/'))
    let filePath = urlParts[1].substring(urlParts[1].indexOf('/') + 1)
    if (filePath.includes('?')) filePath = filePath.split('?')[0]
    const { data } = supabase.storage.from(bucket).getPublicUrl(decodeURIComponent(filePath), { transform: { width: targetWidth } })
    return data.publicUrl
  } catch (err) { return originalUrl }
}

function handleImageError(event: Event) {
  const img = event.target as HTMLImageElement
  if (!img.src.includes('placeholder.png')) img.src = '/placeholder.png'
}

function closeArtModal() {
  showImageModal.value = false
}
</script>

<style scoped lang="scss">
/* =========================================================================
   MARKETPLACE FAVORITES - NATURAL FLUID LAYOUT
========================================================================= */
.view-wrap { padding-top: 82px; }
.favorites-view { min-height: 100vh; }
.fluid-container { width: 100%; padding-left: 24px; padding-right: 24px; margin: 0 auto; max-width: 1800px; }

@media (max-width: 959px) {
  .view-wrap { padding-top: 0; padding-bottom: 96px; }
  .favorites-view { min-height: 100vh; }
}
@media (max-width: 767px) {
  .fluid-container { padding-left: 12px; padding-right: 12px; }
}

.font-sans { font-family: 'Inter', -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; }
.lh-1 { line-height: 1.2 !important; }
.letter-spacing-1 { letter-spacing: 0.05em; }
.transition-all { transition: all 0.3s cubic-bezier(0.25, 0.8, 0.25, 1); }

/* MODIFICADORES GLASS/DARK NATURAIS (VARIÁVEIS DO DISCOVER) */
.bg-glass-dark { background-color: var(--bg-main); }
.bg-glass-header { background: rgba(20,20,24,0.55); backdrop-filter: blur(14px); }
.border-bottom-white-05 { border-bottom: 1px solid rgba(255,255,255,0.08); }
.border-white-10 { border-color: rgba(255,255,255,0.1) !important; }
.border-white-20 { border-color: rgba(255,255,255,0.2) !important; }
.bg-black-20 { background-color: rgba(0,0,0,0.2); }
.bg-black-50 { background-color: rgba(0,0,0,0.5); }

/* ANIMAÇÃO DE "MERGULHO" NA PASTA (DEEP DIVE) */
.inside-folder-glow {
   position: fixed;
   top: 0; left: 0; right: 0; bottom: 0;
   background: radial-gradient(circle at top, rgba(var(--v-theme-primary), 0.15) 0%, transparent 60%);
   opacity: 0;
   transform: scale(1.1);
   pointer-events: none;
   transition: opacity 0.8s ease, transform 0.8s cubic-bezier(0.25, 0.8, 0.25, 1);
   z-index: 0;
}
.inside-folder-glow.is-inside {
   opacity: 1;
   transform: scale(1);
}

/* CARROSSEL BACKGROUND */
.background-carousel-wrapper { position: fixed; top: 0; left: 0; width: 100vw; height: 100vh; z-index: 0; opacity: 0.6; pointer-events: none; }
.background-overlay { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 1; background: radial-gradient(circle at center, rgba(15, 15, 19, 0.4), rgba(15, 15, 19, 0.98)); backdrop-filter: blur(8px); }

/* 3D BUTTONS */
.btn-3d {
  border-radius: 12px !important;
  box-shadow: 0 3px 6px rgba(0,0,0,0.15), inset 0 2px 0 rgba(255,255,255,0.25) !important;
  transition: transform 0.1s ease, box-shadow 0.1s ease;
  text-transform: none !important;
}
.btn-3d:active {
  transform: translateY(2px);
  box-shadow: 0 1px 2px rgba(0,0,0,0.15), inset 0 1px 0 rgba(255,255,255,0.2) !important;
}
.micro-btn-3d {
  height: 28px; padding: 0 10px; border-radius: 8px; border-bottom: 2px solid rgba(0,0,0,0.15); transition: all 0.1s ease; cursor: pointer; display: inline-flex; align-items: center; justify-content: center; color: white;
}
.micro-btn-3d:active { transform: translateY(1px); border-bottom-width: 1px; margin-top: 1px; }
.icon-only { width: 28px; padding: 0; }
.neutral { background: linear-gradient(180deg, rgba(var(--v-theme-surface), 1), rgba(var(--v-theme-background), 1)); border-color: rgba(var(--v-theme-on-surface), 0.15); color: rgba(var(--v-theme-on-surface), 0.8); }
.shadow-primary { box-shadow: 0 8px 24px rgba(var(--v-theme-primary), 0.3) !important; }

/* DRAG & DROP */
.no-select { -webkit-touch-callout: none; -webkit-user-select: none; user-select: none; }
.pointer-events-none { pointer-events: none; }
.is-touch-dragging { opacity: 0.3 !important; transform: scale(0.95); }

/* ILHA FLUTUANTE DE PASTAS */
.floating-drop-island {
  position: fixed;
  bottom: 24px;
  left: 50%;
  transform: translateX(-50%);
  border-radius: 100px;
  z-index: 9999;
  max-width: 95vw;
}
@media (max-width: 600px) {
  .floating-drop-island { border-radius: 20px; bottom: 16px; flex-direction: column; align-items: flex-start; }
}
.drop-folder-btn { border-radius: 50px !important; }
.drop-active { background: rgba(var(--v-theme-primary), 0.2) !important; border-color: rgb(var(--v-theme-primary)) !important; transform: scale(1.05); }
.slide-up-enter-active, .slide-up-leave-active { transition: all 0.4s cubic-bezier(0.25, 0.8, 0.25, 1); }
.slide-up-enter-from, .slide-up-leave-to { opacity: 0; transform: translate(-50%, 50px); }

/* FOLDERS GRID (AJUSTADO PARA CABER MAIS PASTAS) */
.folders-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(180px, 1fr));
  gap: 16px;
}
.folder-card { cursor: pointer; border-radius: 16px; }
.folder-card:hover { transform: translateY(-4px); border-color: rgba(var(--v-theme-primary), 0.4) !important; box-shadow: var(--hover-shadow); }
.drag-over-light { background: rgba(var(--v-theme-primary), 0.05); border-color: rgb(var(--v-theme-primary)) !important; transform: scale(1.05); }
.drag-over-dark { background: rgba(var(--v-theme-primary), 0.2); border-color: rgb(var(--v-theme-primary)) !important; transform: scale(1.05); }
.folder-menu-btn { pointer-events: auto; }
.gold-gradient-icon { background: linear-gradient(135deg, #d4af37, #f3e5ab, #d4af37); -webkit-background-clip: text; -webkit-text-fill-color: transparent; filter: drop-shadow(0 2px 4px rgba(212, 175, 55, 0.3)); }

/* =========================================================================
   STAMPS MASONRY 3D (MÁXIMO DE COLUNAS HORIZONTAIS)
========================================================================= */
.stamps-masonry {
  column-count: 2;
  column-gap: 12px;
}
@media (min-width: 600px) { .stamps-masonry { column-count: 4; column-gap: 16px; } }
@media (min-width: 960px) { .stamps-masonry { column-count: 6; column-gap: 20px; } }
@media (min-width: 1280px) { .stamps-masonry { column-count: 7; } }
@media (min-width: 1600px) { .stamps-masonry { column-count: 9; } }
@media (min-width: 1920px) { .stamps-masonry { column-count: 11; } }

.library-card-3d {
  break-inside: avoid;
  margin-bottom: 20px;
  transform: perspective(1000px) rotateY(0deg) rotateX(0deg);
  box-shadow: 0 4px 12px rgba(0,0,0,0.1);
  transform-style: preserve-3d;
  will-change: transform, box-shadow;
}

.library-card-3d:hover {
  transform: perspective(1000px) rotateY(-2deg) rotateX(1deg) scale(1.02);
  box-shadow: -6px 12px 24px rgba(0,0,0,0.25);
  z-index: 10;
  border-color: rgba(var(--v-theme-primary), 0.5) !important;
}

.stamp-media-wrap { overflow: hidden; border-radius: 12px 12px 0 0; }
.stamp-img { width: 100%; height: auto; display: block; transition: transform 0.5s cubic-bezier(0.25, 1, 0.5, 1); }
.library-card-3d:hover .stamp-img { transform: scale(1.04); }

.bg-gradient-to-t { background: linear-gradient(to top, rgba(0,0,0,0.85) 0%, transparent 60%); }
.drag-handle-overlay { background: rgba(0,0,0,0.3); }
.library-card-3d:hover .drag-handle-overlay { opacity: 1 !important; }
.drop-shadow-icon { filter: drop-shadow(0 2px 8px rgba(0,0,0,0.5)); }

.heart-btn { opacity: 0; transform: scale(0.8); transition: all 0.2s ease; }
/* Botão de mover ESTAMPA SEMPRE VISÍVEL para o usuário saber que a função existe */
.move-btn { opacity: 1; transform: scale(1); transition: all 0.2s ease; }
.library-card-3d:hover .heart-btn { opacity: 1; transform: scale(1); }

/* DROPZONE E EMPTY STATES */
.back-dropzone { min-height: 80px; }
.empty-glow-orb { position: absolute; width: 300px; height: 300px; background: radial-gradient(circle, rgba(var(--v-theme-primary), 0.1) 0%, transparent 70%); top: 50%; left: 50%; transform: translate(-50%, -50%); pointer-events: none; }
.hover-bg-light:hover { background-color: rgba(0,0,0,0.04) !important; }
.hover-bg-dark:hover { background-color: rgba(255,255,255,0.04) !important; }
.hover-primary:hover { color: rgb(var(--v-theme-primary)) !important; }

/* ANTI PLAGIARISM */
.copyright-warning-overlay { position: fixed; inset: 0; z-index: 99999; display: flex; align-items: center; justify-content: center; background: rgba(0, 0, 0, 0.4); backdrop-filter: blur(8px); -webkit-backdrop-filter: blur(8px); padding: 24px; }
.copyright-warning-card { width: 100%; max-width: 420px; background: rgba(24, 24, 27, 0.85); backdrop-filter: blur(20px); -webkit-backdrop-filter: blur(20px); border-radius: 24px; padding: 32px; text-align: center; box-shadow: 0 25px 50px rgba(0,0,0,0.5), inset 0 1px 0 rgba(255,255,255,0.1); }
.warning-icon-wrap { width: 72px; height: 72px; margin: 0 auto 20px; border-radius: 50%; background: rgba(239, 68, 68, 0.15); display: flex; align-items: center; justify-content: center; }
.warning-title { color: #fff; font-size: 1.5rem; font-weight: 800; letter-spacing: -0.02em; margin-bottom: 12px; }
.warning-desc { color: rgba(255, 255, 255, 0.7); font-size: 0.95rem; line-height: 1.5; margin-bottom: 24px; }
.strike-indicator { display: flex; justify-content: center; gap: 12px; margin-bottom: 16px; }
.strike-dot { width: 45px; height: 6px; border-radius: 3px; background: rgba(255, 255, 255, 0.15); transition: background-color 0.4s ease; }
.strike-dot.filled-error { background: #ef4444; box-shadow: 0 0 12px rgba(239, 68, 68, 0.4); }
.strike-text { font-size: 0.85rem; color: rgba(255, 255, 255, 0.5); margin: 0; }

@media (max-width: 767px) {
  .library-card-3d { margin-bottom: 12px; }
  .heart-btn { opacity: 1; transform: scale(1); }
  .header-bar { gap: 16px; }
}
</style>
