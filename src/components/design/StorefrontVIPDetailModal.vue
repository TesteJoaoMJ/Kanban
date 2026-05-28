<template>
  <v-dialog v-model="internalShow" max-width="800" persistent scrollable>
    <v-card class="rounded-xl overflow-hidden border" :class="isLightMode ? 'bg-white border-warning-lighten-3' : 'bg-surface-dark border-warning-darken-3'" style="border-width: 2px !important;">
      <div class="vip-bg-glow"></div>

      <div class="pa-5 border-b d-flex align-center justify-space-between position-relative z-10" :class="isLightMode ? 'bg-warning-lighten-5' : 'bg-warning-darken-4-alpha'">
        <div class="d-flex align-center gap-3">
          <v-avatar color="warning" class="shadow-gold text-black font-weight-black"><v-icon>mdi-crown</v-icon></v-avatar>
          <div>
            <h3 class="text-h6 font-weight-black lh-1" :class="isLightMode ? 'text-warning-darken-4' : 'text-warning-lighten-2'">Detalhes VIP: {{ request?.dev_code }}</h3>
            <span class="text-caption font-weight-bold opacity-70" :class="isLightMode ? 'text-warning-darken-3' : 'text-warning-lighten-4'">Solicitação Exclusiva via Marketplace</span>
          </div>
        </div>
        <v-btn icon="mdi-close" variant="text" size="small" @click="closeModal" :color="isLightMode ? 'black' : 'white'" :disabled="isUploading"></v-btn>
      </div>

      <v-card-text class="pa-6 position-relative z-10 custom-scroll" :class="isLightMode ? 'text-grey-darken-4' : 'text-white'">
         <div class="mb-6">
            <div class="text-caption font-weight-black text-uppercase letter-spacing-1 mb-1 opacity-70">Cliente Vip</div>
            <div class="text-h5 font-weight-black text-warning">{{ customerName }}</div>
         </div>

         <div class="mb-6">
            <div class="text-caption font-weight-black text-uppercase letter-spacing-1 mb-2 opacity-70">Briefing / Observações do Cliente</div>
            <div class="pa-5 rounded-xl border text-body-1 shadow-sm" :class="isLightMode ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-black-20 border-white-10'" style="white-space: pre-wrap; line-height: 1.6;">
               {{ briefingNotes }}
            </div>
         </div>

         <div v-if="attachments.length > 0" class="mb-2">
            <div class="text-caption font-weight-black text-uppercase letter-spacing-1 mb-3 opacity-70">Referências Visuais Anexadas ({{ attachments.length }})</div>
            <div class="d-flex flex-wrap gap-4">
               <div v-for="(url, index) in attachments" :key="index" class="attachment-box rounded-xl overflow-hidden border shadow-sm cursor-pointer" :class="isLightMode ? 'border-grey-lighten-2' : 'border-white-10'" @click="openImage(url)">
                  <v-img :src="url" width="140" height="140" cover class="transition-transform hover-scale"></v-img>
                  <div class="pa-2 text-center text-[10px] font-weight-bold text-uppercase opacity-70" :class="isLightMode ? 'bg-grey-lighten-4' : 'bg-grey-darken-4'"><v-icon size="12" class="mr-1">mdi-magnify</v-icon> Ampliar</div>
               </div>
            </div>
         </div>
         <div v-else class="pa-6 text-center border border-dashed rounded-xl opacity-60" :class="isLightMode ? 'border-grey' : 'border-white-20'">
            <v-icon size="32" class="mb-2">mdi-image-off-outline</v-icon>
            <p class="text-body-2 mb-0 font-weight-medium">O cliente não enviou imagens de referência.</p>
         </div>

         <input type="file" ref="vipFileInput" class="d-none" @change="handleFileUpload" accept="image/*,.pdf" />
      </v-card-text>

      <v-card-actions class="pa-5 border-t d-flex justify-end gap-3 position-relative z-10" :class="isLightMode ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-surface-dark border-white-10'">
         <v-btn variant="outlined" :color="isLightMode ? 'grey-darken-2' : 'grey-lighten-1'" class="font-weight-bold btn-3d px-6 rounded-lg text-none" @click="closeModal" :disabled="isUploading">Fechar</v-btn>
         <v-btn color="warning" variant="flat" class="font-weight-black text-black btn-3d px-8 rounded-lg shadow-gold text-none" :loading="isUploading" @click="triggerUpload">
            <v-icon start>mdi-safe-star</v-icon>
            Anexar e Entregar no Cofre (24h)
         </v-btn>
      </v-card-actions>
    </v-card>
  </v-dialog>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { useThemeStore } from '@/stores/theme'
import { supabase } from '@/api/supabase'

const props = defineProps<{
  show: boolean
  request: any
}>()

const emit = defineEmits(['close', 'deliver'])

const themeStore = useThemeStore()
const internalShow = ref(props.show)
const isUploading = ref(false)
const vipFileInput = ref<HTMLInputElement | null>(null)

watch(() => props.show, (val) => { internalShow.value = val })
watch(internalShow, (val) => { if (!val) emit('close') })

const isLightMode = computed(() => themeStore.currentMode === 'light')

const customerName = computed(() => {
  if (props.request?.design_items && props.request.design_items.length > 0) {
    return props.request.design_items[0].customer_name || 'Cliente VIP'
  }
  return 'Cliente VIP'
})

const briefingNotes = computed(() => {
  if (props.request?.design_items && props.request.design_items.length > 0) {
    return props.request.design_items[0].notes || 'Nenhuma observação informada.'
  }
  return 'Nenhuma observação informada.'
})

const attachments = computed(() => {
  if (props.request?.design_items && props.request.design_items.length > 0) {
    return props.request.design_items[0].attachments || []
  }
  return []
})

const closeModal = () => {
  if (!isUploading.value) internalShow.value = false
}

const openImage = (url: string) => {
  window.open(url, '_blank')
}

// UPLOAD ISOLADO: Sem relação com pedidos, orders ou logs do ERP
const triggerUpload = () => {
  vipFileInput.value?.click()
}

const handleFileUpload = async (event: Event) => {
  const target = event.target as HTMLInputElement
  if (!target.files || target.files.length === 0) return

  const file = target.files[0]
  isUploading.value = true

  try {
    const fileExt = file.name.split('.').pop()
    const filePath = `vip-deliveries/storefront_${Date.now()}_${Math.random().toString(36).substr(2, 5)}.${fileExt}`

    // Faz o upload pro bucket de artes
    const { error } = await supabase.storage.from('arts').upload(filePath, file)
    if (error) throw error

    const { data: { publicUrl } } = supabase.storage.from('arts').getPublicUrl(filePath)

    // Manda a URL limpa de volta pro Kanban concluir a entrega
    emit('deliver', publicUrl)

  } catch (error: any) {
    alert('Erro ao anexar a arte: ' + error.message)
  } finally {
    isUploading.value = false
    if (target) target.value = ''
  }
}
</script>

<style scoped>
.bg-surface-dark { background-color: #1a1a20; }
.bg-warning-darken-4-alpha { background-color: rgba(245, 158, 11, 0.15) !important; }
.bg-black-20 { background-color: rgba(0, 0, 0, 0.2); }
.border-white-10 { border-color: rgba(255, 255, 255, 0.1) !important; }
.border-white-20 { border-color: rgba(255, 255, 255, 0.2) !important; }

.vip-bg-glow {
  position: absolute;
  top: -30%; right: -30%;
  width: 150%; height: 150%;
  background: radial-gradient(circle at center, rgba(245, 158, 11, 0.08) 0%, transparent 50%);
  pointer-events: none;
}
.shadow-gold { box-shadow: 0 4px 15px rgba(245, 158, 11, 0.3) !important; }
.btn-3d { box-shadow: 0 3px 5px rgba(0,0,0,0.15), inset 0 2px 0 rgba(255,255,255,0.2) !important; transition: transform 0.1s ease; }
.btn-3d:active { transform: translateY(2px); box-shadow: 0 1px 2px rgba(0,0,0,0.15) !important; }
.letter-spacing-1 { letter-spacing: 0.05em; }

.attachment-box { transition: all 0.3s ease; }
.attachment-box:hover { transform: translateY(-4px); box-shadow: 0 8px 20px rgba(0,0,0,0.15) !important; border-color: #f59e0b !important; }
.hover-scale { transition: transform 0.4s ease; }
.attachment-box:hover .hover-scale { transform: scale(1.08); }

.custom-scroll::-webkit-scrollbar { width: 6px; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(245, 158, 11, 0.3); border-radius: 6px; }
</style>
