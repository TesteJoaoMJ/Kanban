<template>
  <section class="d-flex flex-column gap-4">
    <div class="bg-surface rounded-xl pa-6 d-flex align-center justify-space-between border shadow-sm w-100 overflow-hidden section-hero-card enterprise-card" style="max-height: 120px;">
        <div class="d-flex flex-column justify-center w-75">
          <div class="eyebrow text-emerald mb-1 lh-1">Matéria-Prima</div>
          <h2 class="text-h5 font-weight-black m-0 mb-1 text-high-emphasis text-truncate" style="line-height: 1.2;">Bases Têxteis</h2>
          <p class="text-body-2 text-medium-emphasis m-0 text-truncate">Gerencie os tecidos, fichas técnicas, valores por metro e regras de atacado.</p>
        </div>
        <div class="d-none d-sm-flex align-center justify-center opacity-20" style="width: 80px; height: 80px; flex-shrink: 0;">
           <v-icon size="64" color="emerald">mdi-layers-triple</v-icon>
        </div>
    </div>

    <div class="two-col-grid">
      <article v-for="fabric in props.fabrics" :key="fabric.id" class="bg-surface border rounded-xl pa-4 d-flex align-center gap-4 cursor-pointer hover-elevate enterprise-card" @click="openFabricDrawer(fabric)">
        <div class="bg-emerald-lighten-5 text-emerald rounded-lg d-flex align-center justify-center border overflow-hidden position-relative" style="width:64px; height:64px; flex-shrink: 0;">
          <img v-if="fabric.image_url" :src="fabric.image_url" class="w-100 h-100 object-cover" />
          <v-icon v-else size="28">mdi-file-document-outline</v-icon>
        </div>
        <div class="flex-grow-1 overflow-hidden">
          <div class="d-flex justify-space-between align-center mb-1">
             <strong class="text-body-1 font-weight-bold text-high-emphasis text-truncate">{{ fabric.name }}</strong>
             <v-chip size="x-small" :color="fabric.is_active ? 'success' : 'grey'" variant="tonal" class="font-weight-bold px-1 ml-2">{{ fabric.is_active ? 'Ativo' : 'Oculto' }}</v-chip>
          </div>
          <div class="d-flex align-center justify-space-between">
             <span class="text-caption text-medium-emphasis font-weight-bold">R$ {{ formatPrice(fabric.base_price || fabric.price) }} / {{ fabric.unit || 'm' }}</span>
             <span class="text-[10px] bg-emerald-lighten-5 text-emerald font-weight-bold px-1 rounded border border-emerald" v-if="fabric.price_tiers?.length">
               {{ fabric.price_tiers.length }} regras
             </span>
          </div>
        </div>
      </article>
    </div>

    <div class="drawer-backdrop" v-if="showFabricDrawer" @click.self="closeFabricDrawer">
      <aside class="drawer-panel bg-surface d-flex flex-column h-100">
        <header class="pa-6 border-b d-flex justify-space-between align-center flex-shrink-0" style="background: rgba(var(--v-theme-surface), 0.95); backdrop-filter: blur(12px); z-index: 10;">
          <div>
            <div class="eyebrow text-emerald mb-1 lh-1">Engenharia de Produto</div>
            <h3 class="text-h4 font-weight-black m-0 lh-1 text-high-emphasis letter-spacing-tight">{{ editFabricForm.id ? 'Editar Base Têxtil' : 'Nova Base Têxtil' }}</h3>
          </div>
          <v-btn icon="mdi-close" variant="tonal" class="btn-3d" color="grey" @click="closeFabricDrawer"></v-btn>
        </header>

        <div class="flex-grow-1 bg-background custom-scrollbar overflow-y-auto">
          <form @submit.prevent="saveFabricToDb" class="d-flex flex-column h-100">
            <div class="pa-8 d-flex flex-column gap-6">

              <div class="premium-layout-grid">

                <div class="ficha-column">
                   <div class="eyebrow text-primary mb-3 lh-1">Ficha Técnica</div>
                   <div
                      class="ficha-upload-area bg-surface border rounded-2xl position-relative cursor-pointer shadow-sm hover-elevate transition-all overflow-hidden"
                      @click="triggerImageUpload"
                   >
                      <v-progress-circular v-if="isUploadingImage" indeterminate color="primary" size="48" width="4" class="position-absolute" style="top: 50%; left: 50%; transform: translate(-50%, -50%); z-index: 5;"></v-progress-circular>

                      <template v-else>
                        <img v-if="editFabricForm.image_url" :src="editFabricForm.image_url" class="w-100 h-100 object-contain bg-white" />

                        <div v-else class="empty-ficha-state d-flex flex-column align-center justify-center h-100 pa-6 text-center">
                          <div class="icon-circle mb-4 bg-primary-lighten-5 border border-primary-lighten-3 shadow-sm d-flex align-center justify-center rounded-circle" style="width: 72px; height: 72px;">
                             <v-icon size="36" color="primary">mdi-cloud-upload-outline</v-icon>
                          </div>
                          <h4 class="text-body-1 font-weight-black text-high-emphasis mb-1">Anexar Ficha Técnica</h4>
                          <p class="text-caption text-medium-emphasis m-0">Envie a imagem com as especificações técnicas da base (JPG, PNG).</p>
                        </div>
                      </template>

                      <input type="file" ref="fileInput" accept="image/*" class="d-none" @change="handleImageUpload" />
                   </div>

                   <div class="d-flex justify-center mt-3" v-if="editFabricForm.image_url && !isUploadingImage">
                      <v-btn size="small" color="error" variant="text" class="font-weight-bold" @click.stop="editFabricForm.image_url = ''">
                        <v-icon start>mdi-trash-can-outline</v-icon> Remover Ficha
                      </v-btn>
                   </div>
                </div>

                <div class="dados-column d-flex flex-column gap-5">
                   <section class="bg-surface border rounded-2xl pa-6 shadow-sm">
                      <div class="eyebrow text-primary mb-4 lh-1">Informações Básicas</div>
                      <div class="d-flex flex-column gap-4">
                        <div>
                          <label class="text-[11px] font-weight-bold text-uppercase letter-spacing-1 text-medium-emphasis mb-1 d-block">Nome da Base</label>
                          <input type="text" v-model="editFabricForm.name" required class="modern-input bg-background w-100 px-4 py-3 border rounded-xl text-high-emphasis text-body-1 font-weight-bold" placeholder="Ex: Malha Algodão Premium" />
                        </div>
                        <div>
                          <label class="text-[11px] font-weight-bold text-uppercase letter-spacing-1 text-medium-emphasis mb-1 d-block">Descrição / Caimento</label>
                          <textarea v-model="editFabricForm.description" rows="3" class="modern-input bg-background w-100 px-4 py-3 border rounded-xl text-high-emphasis text-body-2" placeholder="Descreva as propriedades do tecido..." style="resize:none"></textarea>
                        </div>

                        <div class="d-flex gap-4">
                          <div class="flex-grow-1">
                            <label class="text-[11px] font-weight-bold text-uppercase letter-spacing-1 text-medium-emphasis mb-1 d-block">Preço Base (S/ Desconto)</label>
                            <div class="position-relative">
                              <span class="position-absolute text-medium-emphasis font-weight-bold" style="left: 14px; top: 50%; transform: translateY(-50%);">R$</span>
                              <input type="number" step="0.01" min="0" v-model.number="editFabricForm.base_price" required class="modern-input bg-background w-100 pl-10 pr-4 py-3 border rounded-xl text-primary font-weight-black text-h6" />
                            </div>
                          </div>
                          <div class="flex-shrink-0" style="width: 140px;">
                            <label class="text-[11px] font-weight-bold text-uppercase letter-spacing-1 text-medium-emphasis mb-1 d-block">Unidade</label>
                            <select v-model="editFabricForm.unit" class="modern-input bg-background w-100 px-4 py-3 border rounded-xl text-high-emphasis font-weight-bold">
                              <option value="m">Metros (m)</option>
                              <option value="kg">Quilos (kg)</option>
                            </select>
                          </div>
                        </div>
                      </div>
                   </section>

                   <section class="bg-surface border rounded-2xl pa-6 shadow-sm d-flex justify-space-between align-center">
                      <div>
                        <div class="text-[11px] font-weight-bold text-success text-uppercase letter-spacing-1 mb-1">Visibilidade</div>
                        <h4 class="text-body-1 font-weight-black m-0 text-high-emphasis">Disponível no Marketplace</h4>
                      </div>
                      <v-switch v-model="editFabricForm.is_active" color="success" inset hide-details density="compact"></v-switch>
                   </section>
                </div>
              </div>

              <section class="bg-surface border rounded-2xl pa-6 shadow-sm mt-2">
                <div class="d-flex align-center justify-space-between mb-4">
                  <div>
                    <div class="eyebrow text-emerald mb-1 lh-1">Política Comercial</div>
                    <h4 class="text-h6 font-weight-black text-high-emphasis m-0">Regras de Desconto (Atacado)</h4>
                  </div>
                  <v-btn variant="tonal" color="emerald" class="text-none font-weight-bold rounded-lg btn-3d" @click="addTier">
                    <v-icon start size="18">mdi-plus</v-icon> Adicionar Regra
                  </v-btn>
                </div>

                <div class="d-flex flex-column gap-3">
                  <div v-for="(tier, idx) in editFabricForm.price_tiers" :key="idx" class="bg-background border rounded-xl pa-3 d-flex align-center gap-4 transition-all">
                    <div class="d-flex align-center justify-center bg-emerald-lighten-5 text-emerald font-weight-black rounded-lg border border-emerald" style="width: 40px; height: 40px; flex-shrink:0;">
                      #{{ idx + 1 }}
                    </div>
                    <div class="flex-grow-1">
                      <label class="text-[10px] font-weight-bold text-uppercase text-medium-emphasis">A partir de ({{ editFabricForm.unit }})</label>
                      <input type="number" min="1" v-model.number="tier.min_qty" class="modern-input bg-surface w-100 px-3 py-2 border rounded-lg text-high-emphasis font-weight-bold mt-1" required />
                    </div>
                    <v-icon size="24" color="grey-lighten-1" class="mt-5">mdi-arrow-right</v-icon>
                    <div class="flex-grow-1">
                      <label class="text-[10px] font-weight-bold text-uppercase text-medium-emphasis">Novo Preço (R$)</label>
                      <div class="position-relative mt-1">
                        <span class="position-absolute text-success font-weight-bold" style="left: 12px; top: 50%; transform: translateY(-50%);">R$</span>
                        <input type="number" step="0.01" min="0" v-model.number="tier.price" class="modern-input bg-surface border-success text-success font-weight-black w-100 pl-8 pr-3 py-2 rounded-lg" required />
                      </div>
                    </div>
                    <v-btn icon="mdi-trash-can-outline" variant="text" color="error" class="mt-5 rounded-lg" @click="removeTier(idx)"></v-btn>
                  </div>

                  <div v-if="editFabricForm.price_tiers.length === 0" class="text-body-2 text-medium-emphasis text-center py-8 bg-background border border-dashed rounded-xl">
                    <v-icon size="32" class="opacity-50 mb-2">mdi-tag-off-outline</v-icon><br>
                    Nenhuma regra de atacado configurada.<br>A base será vendida apenas pelo preço de varejo.
                  </div>
                </div>
              </section>
            </div>

            <div class="pa-6 border-t mt-auto d-flex justify-space-between align-center bg-surface" style="z-index: 10;">
              <v-btn v-if="editFabricForm.id" variant="text" color="error" class="text-none font-weight-bold" @click="deleteFabricFromDb">
                <v-icon start>mdi-alert-circle-outline</v-icon> Excluir Base
              </v-btn>
              <div v-else></div>
              <div class="d-flex gap-3">
                <v-btn variant="outlined" size="x-large" class="rounded-xl text-none font-weight-bold border bg-surface text-high-emphasis" @click="closeFabricDrawer">Cancelar</v-btn>
                <v-btn color="primary" size="x-large" type="submit" :loading="isSaving" class="font-weight-black px-8 rounded-xl text-none btn-3d">
                  <v-icon start>mdi-content-save-check</v-icon> Gravar no Catálogo
                </v-btn>
              </div>
            </div>
          </form>
        </div>
      </aside>
    </div>
  </section>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { supabase } from '@/api/supabase'

const props = defineProps<{
  fabrics: any[]
}>()

const emit = defineEmits(['refresh'])

const showFabricDrawer = ref(false)
const editFabricForm = ref<any>({ price_tiers: [], image_url: '' })
const isSaving = ref(false)

// Estados de Imagem
const fileInput = ref<HTMLInputElement | null>(null)
const isUploadingImage = ref(false)

// Ação do Pai para o botão "Novo Cadastro"
function handleAction() {
  openFabricDrawer(null)
}
defineExpose({ handleAction })

function formatPrice(value: number) {
  return Number(value || 0).toLocaleString('pt-BR', { minimumFractionDigits: 2, maximumFractionDigits: 2 })
}

function openFabricDrawer(f: any) {
  editFabricForm.value = f ? { ...f, price_tiers: f.price_tiers || [] } : {
    id: null, name: '', description: '', base_price: 0, unit: 'm', is_active: true, price_tiers: [], image_url: ''
  }
  showFabricDrawer.value = true
}

function closeFabricDrawer() {
  showFabricDrawer.value = false
}

// UPLOAD DA IMAGEM DA FICHA TÉCNICA
function triggerImageUpload() {
  fileInput.value?.click()
}

async function handleImageUpload(event: Event) {
  const target = event.target as HTMLInputElement
  if (!target.files || target.files.length === 0) return

  const file = target.files[0]
  const fileExt = file.name.split('.').pop()
  const fileName = `fabric_ficha_${Date.now()}.${fileExt}`
  const filePath = `fabrics/${fileName}`

  isUploadingImage.value = true
  try {
    const { error: uploadError } = await supabase.storage.from('catalog-assets').upload(filePath, file)
    if (uploadError) throw uploadError

    const { data } = supabase.storage.from('catalog-assets').getPublicUrl(filePath)
    editFabricForm.value.image_url = data.publicUrl
  } catch (e: any) {
    console.error('Erro no upload da ficha técnica:', e)
    alert('Falha ao subir a imagem.')
  } finally {
    isUploadingImage.value = false
    if (target) target.value = ''
  }
}

// PRECIFICAÇÃO
function addTier() {
  editFabricForm.value.price_tiers.push({ min_qty: 0, price: 0 })
}

function removeTier(i: number) {
  editFabricForm.value.price_tiers.splice(i, 1)
}

// CRUD NO BANCO
async function saveFabricToDb() {
  isSaving.value = true
  try {
    const payload = {
      name: editFabricForm.value.name,
      description: editFabricForm.value.description,
      base_price: editFabricForm.value.base_price,
      unit: editFabricForm.value.unit,
      price_tiers: editFabricForm.value.price_tiers,
      is_active: editFabricForm.value.is_active,
      image_url: editFabricForm.value.image_url // A nova coluna da Ficha Técnica
    }

    if (editFabricForm.value.id) {
      const { data, error } = await supabase.from('catalog_fabrics').update(payload).eq('id', editFabricForm.value.id).select()
      if (error) throw error
    } else {
      const { data, error } = await supabase.from('catalog_fabrics').insert([payload]).select()
      if (error) throw error
    }

    closeFabricDrawer()
    emit('refresh')
  } catch(e: any) {
    alert(`ERRO: ${e.message}`)
    console.error("Erro completo:", e)
  } finally {
    isSaving.value = false
  }
}

async function deleteFabricFromDb() {
  if (confirm('Atenção: Excluir esta base apagará a referência para os pedidos que dependem dela. Tem certeza?')) {
    await supabase.from('catalog_fabrics').delete().eq('id', editFabricForm.value.id)
    closeFabricDrawer()
    emit('refresh')
  }
}
</script>

<style scoped>
.section-hero-card {
  border-radius: 24px !important;
  background: linear-gradient(135deg, rgba(var(--v-theme-primary), 0.10), rgba(var(--v-theme-primary), 0.02) 45%, rgba(var(--v-theme-surface), 1));
}

.two-col-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(340px, 1fr)); gap: 24px; }

.modern-input {
  width: 100%; border: 1px solid rgba(var(--v-theme-on-surface), 0.10);
  background: rgba(var(--v-theme-surface), 0.88); transition: all 0.18s ease; outline: none;
}
.modern-input:focus {
  border-color: rgb(var(--v-theme-primary)); box-shadow: 0 0 0 4px rgba(var(--v-theme-primary), 0.14);
}

.drawer-backdrop {
  position: fixed; inset: 0; z-index: 9999; background: rgba(3, 7, 18, 0.52);
  backdrop-filter: blur(8px); display: flex; justify-content: flex-end;
}
/* Painel mais largo para acomodar o Grid Premium */
.drawer-panel { width: min(840px, 100vw); box-shadow: -18px 0 44px rgba(15,23,42,0.18); }

.custom-scrollbar::-webkit-scrollbar { width: 8px; height: 8px; }
.custom-scrollbar::-webkit-scrollbar-thumb { background: rgba(var(--v-theme-on-surface), 0.14); border-radius: 999px; }

.hover-elevate { transition: transform 0.22s ease, box-shadow 0.22s ease, border-color 0.22s ease; }
.hover-elevate:hover {
  transform: translateY(-4px);
  box-shadow: 0 1px 0 rgba(255,255,255,0.4) inset, 0 22px 44px rgba(15, 23, 42, 0.10) !important;
  border-color: rgba(var(--v-theme-primary), 0.24) !important;
}

.btn-3d { border-radius: 12px !important; box-shadow: 0 3px 5px rgba(0,0,0,0.15), inset 0 2px 0 rgba(255,255,255,0.25) !important; transition: transform 0.1s ease, box-shadow 0.1s ease; text-transform: none !important; }
.btn-3d:active { transform: translateY(2px); box-shadow: 0 1px 2px rgba(0,0,0,0.15), inset 0 1px 0 rgba(255,255,255,0.2) !important; }

/* GRID PREMIUM DO FORMULÁRIO */
.premium-layout-grid {
  display: grid;
  grid-template-columns: 280px 1fr;
  gap: 32px;
  align-items: start;
}

.ficha-upload-area {
  aspect-ratio: 1 / 1.414; /* Proporção de papel A4 vertical */
  width: 100%;
  border-style: dashed !important;
  border-width: 2px !important;
  background: var(--bg-surface-2);
}
.ficha-upload-area:hover {
  border-color: rgb(var(--v-theme-primary)) !important;
  background: rgba(var(--v-theme-primary), 0.03) !important;
}

.object-cover { object-fit: cover; }
.object-contain { object-fit: contain; }
.letter-spacing-1 { letter-spacing: 0.05em; }
.letter-spacing-tight { letter-spacing: -0.02em; }
.lh-1 { line-height: 1.1 !important; }
.transition-all { transition: all 0.2s ease; }

@media (max-width: 767px) {
  .premium-layout-grid {
    grid-template-columns: 1fr;
    gap: 24px;
  }
  .ficha-upload-area {
    aspect-ratio: auto;
    height: 360px;
  }
}
</style>
