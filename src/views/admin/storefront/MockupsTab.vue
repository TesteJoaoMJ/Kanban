<template>
  <section class="d-flex flex-column gap-4">
    <div class="bg-surface rounded-xl pa-6 d-flex align-center justify-space-between border shadow-sm w-100 overflow-hidden section-hero-card enterprise-card" style="max-height: 120px;">
        <div class="d-flex flex-column justify-center w-75">
          <div class="eyebrow text-purple mb-1 lh-1">Renderização</div>
          <h2 class="text-h5 font-weight-black m-0 mb-1 text-high-emphasis text-truncate" style="line-height: 1.2;">Modelos 3D e Mockups</h2>
          <p class="text-body-2 text-medium-emphasis m-0 text-truncate">Gerencie roupas, sombras (multiply) e máscaras.</p>
        </div>
        <div class="d-flex flex-column align-end justify-center">
           <div class="text-h4 font-weight-black text-purple lh-1 m-0">{{ props.mockups.length }}</div>
           <span class="text-[10px] font-weight-bold text-uppercase text-medium-emphasis">Upados</span>
        </div>
    </div>

    <div class="mockup-grid">
      <article v-for="mockup in props.mockups" :key="mockup.id" class="bg-surface border rounded-xl overflow-hidden shadow-sm transition-all cursor-pointer hover-elevate d-flex flex-column enterprise-card" @click="openMockupDrawer(mockup)">

        <div class="position-relative w-100 bg-background flex-shrink-0 mockup-transparency-bg border-b" style="padding-top: 100%;">
          <img v-if="mockup.base_image_url" :src="mockup.base_image_url" class="position-absolute top-0 left-0 w-100 h-100" style="object-fit: contain; z-index: 1;" />
          <img v-if="mockup.shadow_overlay_url" :src="mockup.shadow_overlay_url" class="position-absolute top-0 left-0 w-100 h-100" style="object-fit: contain; z-index: 2; mix-blend-mode: multiply;" />
        </div>

        <div class="pa-4 bg-surface d-flex justify-space-between align-center flex-grow-1">
          <div class="overflow-hidden mr-2">
            <h4 class="text-body-2 font-weight-bold m-0 text-high-emphasis text-truncate">{{ mockup.name }}</h4>
            <p class="text-caption text-medium-emphasis m-0 text-truncate">{{ mockup.mask_url || mockup.shadow_overlay_url ? 'Avançado (C/ Sombras)' : 'Básico' }}</p>
          </div>
          <v-icon size="20" :color="mockup.is_active ? 'success' : 'grey'" class="flex-shrink-0">
             {{ mockup.is_active ? 'mdi-eye-outline' : 'mdi-eye-off-outline' }}
          </v-icon>
        </div>
      </article>
    </div>

    <div class="drawer-backdrop" v-if="showMockupDrawer" @click.self="closeMockupDrawer">
      <aside class="drawer-panel bg-surface d-flex flex-column h-100">
        <header class="pa-6 border-b d-flex justify-space-between align-center flex-shrink-0">
          <div>
            <div class="eyebrow text-purple mb-1 lh-1">Mockups</div>
            <h3 class="text-h5 font-weight-black m-0 lh-1 text-high-emphasis">{{ editMockupForm.id ? 'Editar Modelo' : 'Novo Modelo' }}</h3>
          </div>
          <v-btn icon="mdi-close" variant="text" class="text-medium-emphasis" @click="closeMockupDrawer"></v-btn>
        </header>

        <div class="pa-6 bg-background flex-grow-1 custom-scrollbar overflow-y-auto">
          <form @submit.prevent="saveMockupToDb" class="d-flex flex-column gap-5">
            <section class="bg-surface border rounded-xl pa-5 d-flex flex-column gap-4">
              <div>
                <label class="text-caption font-weight-bold text-high-emphasis mb-1 d-block">Nome do modelo</label>
                <input type="text" v-model="editMockupForm.name" required class="modern-input bg-background w-100 px-3 py-2 border rounded-lg text-high-emphasis" placeholder="Ex: Vestido Longo" />
              </div>
              <div>
                <label class="text-caption font-weight-bold text-high-emphasis mb-1 d-block">Categorias Visíveis</label>
                <v-select
                  v-model="editMockupForm.config.categories"
                  :items="props.categories"
                  item-title="name"
                  item-value="id"
                  multiple
                  chips
                  closable-chips
                  variant="outlined"
                  density="compact"
                  hide-details
                  placeholder="Vazio = Todas"
                  class="bg-background"
                ></v-select>
              </div>
            </section>

            <section class="bg-surface border rounded-xl overflow-hidden d-flex flex-column">
              <div class="pa-4 border-b">
                <label class="text-caption font-weight-bold text-high-emphasis mb-2 d-block">1. Imagem base da roupa (Obrigatório)</label>
                <div v-if="editMockupForm.base_image_url" class="bg-background border rounded-lg pa-3 d-flex align-center gap-3 mockup-transparency-bg">
                  <v-img :src="editMockupForm.base_image_url" width="60" height="60" style="object-fit: contain;" class="bg-white border rounded flex-shrink-0"></v-img>
                  <div class="flex-grow-1">
                    <strong class="text-body-2 text-high-emphasis d-block">Camada Base</strong>
                    <span class="text-[10px] text-primary font-weight-bold bg-primary-lighten-5 px-1 rounded">1080x1080px</span>
                  </div>
                  <v-btn variant="tonal" size="small" color="primary" class="rounded font-weight-bold" @click="triggerRealImageUpload('mockup_base')">Trocar</v-btn>
                </div>
                <div v-else class="bg-background border border-dashed rounded-lg py-6 d-flex flex-column align-center cursor-pointer mockup-transparency-bg" @click="triggerRealImageUpload('mockup_base')">
                  <v-icon size="24" color="primary" class="mb-1">mdi-upload</v-icon>
                  <strong class="text-body-2 text-high-emphasis">Upload PNG transparente</strong>
                </div>
              </div>

              <div class="pa-4 border-b bg-grey-darken-4">
                <label class="text-caption font-weight-bold text-white mb-2 d-block">2. Máscara de recorte</label>
                <div v-if="editMockupForm.mask_url" class="bg-transparent border border-grey-darken-2 rounded-lg pa-3 d-flex align-center gap-3">
                  <v-img :src="editMockupForm.mask_url" width="60" height="60" style="object-fit: contain;" class="bg-white rounded flex-shrink-0"></v-img>
                  <div class="flex-grow-1">
                    <strong class="text-body-2 text-white d-block">Máscara (Alpha)</strong>
                    <span class="text-[10px] text-info font-weight-bold border border-info px-1 rounded text-white">1080x1080px</span>
                  </div>
                  <v-btn variant="tonal" size="small" color="info" class="rounded font-weight-bold" @click="triggerRealImageUpload('mockup_mask')">Trocar</v-btn>
                </div>
                <div v-else class="bg-transparent border border-dashed border-grey-darken-2 rounded-lg py-6 d-flex flex-column align-center cursor-pointer text-white" @click="triggerRealImageUpload('mockup_mask')">
                  <v-icon size="24" color="white" class="mb-1">mdi-content-cut</v-icon>
                  <strong class="text-body-2">Upload PNG preto/branco</strong>
                </div>
              </div>

              <div class="pa-4">
                <label class="text-caption font-weight-bold text-high-emphasis mb-2 d-block">3. Sombra / Multiply</label>
                <div v-if="editMockupForm.shadow_overlay_url" class="bg-background border rounded-lg pa-3 d-flex align-center gap-3 mockup-transparency-bg">
                  <v-img :src="editMockupForm.shadow_overlay_url" width="60" height="60" style="object-fit: contain;" class="bg-white border rounded flex-shrink-0"></v-img>
                  <div class="flex-grow-1">
                    <strong class="text-body-2 text-high-emphasis d-block">Overlay Multiply</strong>
                    <span class="text-[10px] text-primary font-weight-bold bg-primary-lighten-5 px-1 rounded">1080x1080px</span>
                  </div>
                  <v-btn variant="tonal" size="small" color="primary" class="rounded font-weight-bold" @click="triggerRealImageUpload('mockup_shadow')">Trocar</v-btn>
                </div>
                <div v-else class="bg-background border border-dashed rounded-lg py-6 d-flex flex-column align-center cursor-pointer mockup-transparency-bg" @click="triggerRealImageUpload('mockup_shadow')">
                  <v-icon size="24" color="primary" class="mb-1">mdi-theme-light-dark</v-icon>
                  <strong class="text-body-2 text-high-emphasis">Upload PNG de sombras</strong>
                </div>
              </div>
            </section>

            <section class="bg-surface border rounded-xl pa-4 d-flex justify-space-between align-center">
              <div>
                <div class="text-caption font-weight-bold text-success text-uppercase mb-1">Status</div>
                <h4 class="text-body-2 font-weight-bold m-0 text-high-emphasis">Disponível na loja</h4>
              </div>
              <v-switch v-model="editMockupForm.is_active" color="success" inset hide-details density="compact"></v-switch>
            </section>

            <div class="d-flex justify-space-between align-center mt-2 pt-4 border-t">
              <v-btn v-if="editMockupForm.id" variant="text" color="error" class="text-none font-weight-bold" @click="deleteMockupFromDb">Excluir</v-btn>
              <div v-else></div>
              <div class="d-flex gap-3">
                <v-btn variant="outlined" class="rounded-lg text-none font-weight-bold border bg-surface text-high-emphasis" @click="closeMockupDrawer">Cancelar</v-btn>
                <v-btn color="primary" type="submit" :loading="isSaving" elevation="0" class="font-weight-bold px-6 rounded-lg text-none shadow-soft">Salvar Modelo</v-btn>
              </div>
            </div>
          </form>
        </div>
      </aside>
    </div>

    <input type="file" ref="realFileInput" style="display:none" accept="image/png, image/jpeg, image/webp" @change="handleRealUpload" />
  </section>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { supabase } from '@/api/supabase'
import imageCompression from 'browser-image-compression'

const props = defineProps<{
  mockups: any[],
  categories: any[]
}>()

const emit = defineEmits(['refresh'])

const showMockupDrawer = ref(false)
const editMockupForm = ref<any>({})
const isSaving = ref(false)

const realFileInput = ref<HTMLInputElement | null>(null)
const pendingFiles = ref<Record<string, File>>({})
const currentUploadField = ref('')

// Ação do Pai para o botão "Novo Cadastro"
function handleAction() {
  openMockupDrawer(null)
}
defineExpose({ handleAction })

function openMockupDrawer(m: any) {
  editMockupForm.value = m
    ? { ...m, config: m.config || { categories: [] } }
    : { id: null, name: '', base_image_url: '', mask_url: null, shadow_overlay_url: null, is_active: true, config: { categories: [] } }
  showMockupDrawer.value = true
}

function closeMockupDrawer() {
  showMockupDrawer.value = false
  delete pendingFiles.value['mockup_base']
  delete pendingFiles.value['mockup_mask']
  delete pendingFiles.value['mockup_shadow']
}

function triggerRealImageUpload(field: string) {
  currentUploadField.value = field
  realFileInput.value?.click()
}

async function handleRealUpload(event: Event) {
  const target = event.target as HTMLInputElement
  const file = target.files?.[0]
  if (!file) return

  try {
    const compressed = await imageCompression(file, { maxSizeMB: 1, maxWidthOrHeight: 1920, useWebWorker: true, fileType: 'image/webp' })
    const localUrl = URL.createObjectURL(compressed)
    pendingFiles.value[currentUploadField.value] = compressed

    if (currentUploadField.value === 'mockup_base') editMockupForm.value.base_image_url = localUrl
    else if (currentUploadField.value === 'mockup_mask') editMockupForm.value.mask_url = localUrl
    else if (currentUploadField.value === 'mockup_shadow') editMockupForm.value.shadow_overlay_url = localUrl
  } catch (e) {
    alert('Erro na compressão da imagem.')
  }

  if (target) target.value = ''
}

async function uploadPendingFile(field: string) {
  const f = pendingFiles.value[field]
  if (!f) return null
  const ext = f.name.split('.').pop() || 'webp'
  const path = `uploads/asset_${Date.now()}.${ext}`
  const { error } = await supabase.storage.from('catalog-assets').upload(path, f, { upsert: false })
  if (error) throw error
  delete pendingFiles.value[field]
  return supabase.storage.from('catalog-assets').getPublicUrl(path).data.publicUrl
}

async function saveMockupToDb() {
  isSaving.value = true
  try {
    if (pendingFiles.value['mockup_base']) editMockupForm.value.base_image_url = await uploadPendingFile('mockup_base')
    if (pendingFiles.value['mockup_mask']) editMockupForm.value.mask_url = await uploadPendingFile('mockup_mask')
    if (pendingFiles.value['mockup_shadow']) editMockupForm.value.shadow_overlay_url = await uploadPendingFile('mockup_shadow')

    const payload = {
      name: editMockupForm.value.name,
      base_image_url: editMockupForm.value.base_image_url,
      mask_url: editMockupForm.value.mask_url,
      shadow_overlay_url: editMockupForm.value.shadow_overlay_url,
      config: editMockupForm.value.config,
      is_active: editMockupForm.value.is_active
    }

    if (editMockupForm.value.id) {
      const { error } = await supabase.from('catalog_mockups').update(payload).eq('id', editMockupForm.value.id)
      if (error) throw error
    } else {
      const { error } = await supabase.from('catalog_mockups').insert([payload])
      if (error) throw error
    }

    closeMockupDrawer()
    emit('refresh')
  } catch(e: any) {
    alert(`Erro ao salvar mockup: ${e.message}`)
    console.error("Erro completo do DB:", e)
  } finally {
    isSaving.value = false
  }
}

async function deleteMockupFromDb() {
  if (confirm('Excluir mockup?')) {
    await supabase.from('catalog_mockups').delete().eq('id', editMockupForm.value.id)
    closeMockupDrawer()
    emit('refresh')
  }
}
</script>

<style scoped>
.section-hero-card {
  border-radius: 24px !important;
  background: linear-gradient(135deg, rgba(var(--v-theme-primary), 0.10), rgba(var(--v-theme-primary), 0.02) 45%, rgba(var(--v-theme-surface), 1));
}

.mockup-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(270px, 1fr)); gap: 20px; align-items: stretch; }

.mockup-transparency-bg {
  background-image:
    linear-gradient(45deg, rgba(var(--v-theme-on-surface), 0.05) 25%, transparent 25%),
    linear-gradient(-45deg, rgba(var(--v-theme-on-surface), 0.05) 25%, transparent 25%),
    linear-gradient(45deg, transparent 75%, rgba(var(--v-theme-on-surface), 0.05) 75%),
    linear-gradient(-45deg, transparent 75%, rgba(var(--v-theme-on-surface), 0.05) 75%);
  background-size: 20px 20px;
  background-position: 0 0, 0 10px, 10px -10px, -10px 0px;
}

.modern-input {
  min-height: 46px; width: 100%; border: 1px solid rgba(var(--v-theme-on-surface), 0.10);
  background: rgba(var(--v-theme-surface), 0.88); border-radius: 14px; transition: all 0.18s ease;
}
.modern-input:focus {
  border-color: rgb(var(--v-theme-primary)); box-shadow: 0 0 0 4px rgba(var(--v-theme-primary), 0.14);
}

.drawer-backdrop {
  position: fixed; inset: 0; z-index: 9999; background: rgba(3, 7, 18, 0.52);
  backdrop-filter: blur(8px); display: flex; justify-content: flex-end;
}
.drawer-panel { width: min(640px, 100vw); box-shadow: -18px 0 44px rgba(15,23,42,0.18); }

.custom-scrollbar::-webkit-scrollbar { width: 8px; height: 8px; }
.custom-scrollbar::-webkit-scrollbar-thumb { background: rgba(var(--v-theme-on-surface), 0.14); border-radius: 999px; }

.hover-elevate { transition: transform 0.22s ease, box-shadow 0.22s ease, border-color 0.22s ease; }
.hover-elevate:hover {
  transform: translateY(-4px);
  box-shadow: 0 1px 0 rgba(255,255,255,0.4) inset, 0 22px 44px rgba(15, 23, 42, 0.10) !important;
  border-color: rgba(var(--v-theme-primary), 0.24) !important;
}
</style>
