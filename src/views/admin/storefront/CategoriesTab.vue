<template>
  <section class="d-flex flex-column gap-4">
    <div class="bg-surface rounded-xl pa-6 d-flex align-center justify-space-between border shadow-sm w-100 overflow-hidden section-hero-card enterprise-card" style="max-height: 120px;">
        <div class="d-flex flex-column justify-center w-75">
          <div class="eyebrow text-primary mb-1 lh-1">Organização</div>
          <h2 class="text-h5 font-weight-black m-0 mb-1 text-high-emphasis text-truncate" style="line-height: 1.2;">Pastas do Catálogo</h2>
          <p class="text-body-2 text-medium-emphasis m-0 text-truncate">Crie coleções para agrupar estampas no marketplace.</p>
        </div>
        <div class="d-none d-sm-flex align-center justify-center opacity-20" style="width: 80px; height: 80px; flex-shrink: 0;">
           <v-icon size="64" color="primary">mdi-folder-outline</v-icon>
        </div>
    </div>

    <div class="modern-folder-grid">
      <article v-for="cat in props.categories" :key="cat.id" class="bg-surface border rounded-xl pa-5 d-flex flex-column gap-3 transition-all hover-elevate enterprise-card">
        <div class="d-flex justify-space-between align-center">
          <div class="bg-background border text-medium-emphasis rounded-lg d-flex align-center justify-center" style="width:40px; height:40px;">
             <v-icon size="20">mdi-folder</v-icon>
          </div>
          <v-chip size="x-small" :color="cat.is_active ? 'success' : 'error'" variant="tonal" class="font-weight-bold">
            {{ cat.is_active ? 'Ativa' : 'Inativa' }}
          </v-chip>
        </div>
        <div>
          <h4 class="text-subtitle-1 font-weight-bold m-0 text-high-emphasis lh-1 mb-1">{{ cat.name }}</h4>
          <span class="text-caption text-medium-emphasis d-block m-0">{{ getStampCountByCategory(cat.id) }} estampas vinculadas</span>
        </div>
        <div class="d-flex gap-2 mt-auto align-self-end w-100 pt-2">
          <v-btn size="small" color="primary" variant="tonal" class="text-none font-weight-bold flex-grow-1 rounded-lg" @click="openEditCategory(cat)">
            <v-icon start size="14">mdi-pencil</v-icon> Editar
          </v-btn>
          <v-btn size="small" color="error" variant="tonal" class="text-none font-weight-bold flex-grow-1 rounded-lg" @click="deleteCategory(cat.id)">
            <v-icon start size="14">mdi-delete</v-icon> Excluir
          </v-btn>
        </div>
      </article>
    </div>

    <div class="modal-backdrop" v-if="showCategoryModal" @click.self="closeCategoryModal">
      <div class="bg-surface pa-6 rounded-xl border shadow-lg" style="width: 100%; max-width: 400px;">
        <div class="eyebrow text-primary mb-1 lh-1">{{ editCategoryId ? 'Editar categoria' : 'Nova categoria' }}</div>
        <h3 class="text-h5 font-weight-bold mt-0 mb-2 text-high-emphasis">{{ editCategoryId ? 'Renomear pasta' : 'Criar pasta do catálogo' }}</h3>
        <p class="text-body-2 text-medium-emphasis mb-5">Organize suas estampas por coleções.</p>

        <label class="text-caption font-weight-bold text-high-emphasis mb-1 d-block">Nome da Pasta</label>
        <input type="text" v-model="newCategoryName" placeholder="Ex: Inverno 26" class="modern-input bg-background w-100 px-3 py-2 border rounded-lg text-high-emphasis mb-6" />

        <div class="d-flex justify-end gap-3">
          <v-btn variant="outlined" class="rounded-lg text-none border text-high-emphasis bg-surface" @click="closeCategoryModal">Cancelar</v-btn>
          <v-btn color="primary" elevation="0" class="font-weight-bold rounded-lg text-none px-6" :loading="isSaving" @click="saveCategoryToDb">Salvar</v-btn>
        </div>
      </div>
    </div>
  </section>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { supabase } from '@/api/supabase'

const props = defineProps<{
  categories: any[],
  stamps: any[]
}>()

const emit = defineEmits(['refresh'])

const showCategoryModal = ref(false)
const newCategoryName = ref('')
const editCategoryId = ref<string | null>(null)
const isSaving = ref(false)

function getStampCountByCategory(catId: string) {
  return props.stamps.filter(s => s.category_id === catId).length
}

// Ação do Pai para o botão "Novo Cadastro"
function handleAction() {
  editCategoryId.value = null
  newCategoryName.value = ''
  showCategoryModal.value = true
}
defineExpose({ handleAction })

function openEditCategory(cat: any) {
  editCategoryId.value = cat.id
  newCategoryName.value = cat.name
  showCategoryModal.value = true
}

function closeCategoryModal() {
  showCategoryModal.value = false
  newCategoryName.value = ''
  editCategoryId.value = null
}

async function saveCategoryToDb() {
  if (!newCategoryName.value) return
  isSaving.value = true
  try {
    if (editCategoryId.value) {
      const { error } = await supabase.from('catalog_categories')
        .update({ name: newCategoryName.value })
        .eq('id', editCategoryId.value)
      if (error) throw error
    } else {
      const slug = newCategoryName.value.toLowerCase().replace(/[^a-z0-9]+/g, '-') + '-' + Date.now()
      const { error } = await supabase.from('catalog_categories').insert([{ name: newCategoryName.value, slug, is_active: true }])
      if (error) throw error
    }
    closeCategoryModal()
    emit('refresh')
  } catch (err: any) {
    alert('Erro ao salvar categoria: ' + err.message)
  } finally {
    isSaving.value = false
  }
}

async function deleteCategory(id: string) {
  if (confirm('Excluir?')) {
    await supabase.from('catalog_categories').delete().eq('id', id)
    emit('refresh')
  }
}
</script>

<style scoped>
.section-hero-card {
  border-radius: 24px !important;
  background: linear-gradient(135deg, rgba(var(--v-theme-primary), 0.10), rgba(var(--v-theme-primary), 0.02) 45%, rgba(var(--v-theme-surface), 1));
}

.modern-folder-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 18px; }

.modern-input {
  min-height: 46px; width: 100%; border: 1px solid rgba(var(--v-theme-on-surface), 0.10);
  background: rgba(var(--v-theme-surface), 0.88); border-radius: 14px; transition: all 0.18s ease;
}
.modern-input:focus {
  border-color: rgb(var(--v-theme-primary)); box-shadow: 0 0 0 4px rgba(var(--v-theme-primary), 0.14);
}

.modal-backdrop {
  position: fixed; inset: 0; z-index: 9999; background: rgba(3, 7, 18, 0.52);
  backdrop-filter: blur(8px); display: flex; justify-content: center; align-items: center;
}

.hover-elevate { transition: transform 0.22s ease, box-shadow 0.22s ease, border-color 0.22s ease; }
.hover-elevate:hover {
  transform: translateY(-4px);
  box-shadow: 0 1px 0 rgba(255,255,255,0.4) inset, 0 22px 44px rgba(15, 23, 42, 0.10) !important;
  border-color: rgba(var(--v-theme-primary), 0.24) !important;
}
</style>
