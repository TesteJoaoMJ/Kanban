<template>
  <div class="h-100 d-flex flex-column relative overflow-hidden">

    <div class="px-6 py-4 d-flex align-center justify-space-between border-b border-white-05 flex-shrink-0 bg-glass-header backdrop-blur z-20">
      <div class="d-flex align-center gap-4 flex-grow-1">
        <div class="detail-icon-box rounded-xl bg-gradient-cajuia d-flex align-center justify-center elevation-10 border border-white-10">
           <v-icon color="white" size="28">mdi-cloud-circle</v-icon>
        </div>
        <div>
           <h2 class="text-subtitle-1 font-weight-black text-white lh-1 text-shadow">Cajuia Drive</h2>
           <div class="d-flex align-center gap-2 mt-1">
               <span class="text-caption text-white-50">Bucket: <span class="text-primary font-mono">cajuia</span></span>
               <v-icon size="4" color="white-30">mdi-circle</v-icon>
               <span class="text-caption text-white-50">{{ files.length }} arquivos</span>
           </div>
        </div>

        <v-divider vertical class="border-white-10 h-32 mx-4"></v-divider>

        <div style="width: 350px;" class="search-wrapper">
            <v-text-field
                v-model="search"
                density="compact"
                variant="solo"
                placeholder="Buscar documentos, recibos..."
                prepend-inner-icon="mdi-magnify"
                hide-details
                class="glass-input-search"
                bg-color="rgba(0,0,0,0.2)"
            >
                <template v-slot:append-inner>
                    <v-progress-circular v-if="loading" indeterminate size="20" width="2" color="primary"></v-progress-circular>
                </template>
            </v-text-field>
        </div>
      </div>

      <div class="d-flex align-center gap-2">
         <div class="view-toggle bg-black-20 rounded-lg p-1 border border-white-05 mr-2">
             <v-btn
                size="x-small"
                :color="viewMode === 'grid' ? 'primary' : 'white-50'"
                variant="text"
                icon="mdi-view-grid"
                @click="viewMode = 'grid'"
             ></v-btn>
             <v-btn
                size="x-small"
                :color="viewMode === 'list' ? 'primary' : 'white-50'"
                variant="text"
                icon="mdi-view-list"
                @click="viewMode = 'list'"
             ></v-btn>
         </div>

         <v-btn
            color="primary"
            variant="flat"
            class="text-none font-weight-bold px-4 rounded-lg shadow-glow-primary h-40 border border-white-10"
            prepend-icon="mdi-cloud-upload-outline"
            @click="triggerUpload"
            :loading="uploading"
         >
            Upload
         </v-btn>

         <v-btn
            color="white"
            variant="outlined"
            class="text-none font-weight-bold px-4 rounded-lg border-white-10 hover-bg-white-05 h-40"
            prepend-icon="mdi-folder-plus-outline"
            @click="openCreateFolderModal"
         >
            Nova Pasta
         </v-btn>

         <input type="file" ref="fileInput" class="d-none" @change="handleFileUpload" accept="application/pdf,image/*" />
      </div>
    </div>

    <div class="px-6 pt-2 border-b border-white-05 bg-glass-surface z-10">
        <v-tabs
            v-model="activeTab"
            bg-color="transparent"
            color="white"
            density="compact"
            show-arrows
            class="glass-tabs"
            slider-color="primary"
        >
            <v-tab value="all" class="folder-tab text-caption font-weight-bold text-none rounded-t-lg letter-spacing-1 px-4">
                <v-icon start size="small" class="mr-2">mdi-apps</v-icon> Todos
            </v-tab>

            <v-tab
                v-for="folder in folders"
                :key="folder.name"
                :value="folder.name"
                class="folder-tab text-caption font-weight-bold text-none rounded-t-lg letter-spacing-1 px-4"
            >
                <v-icon start size="small" :color="folder.color || 'white'" class="mr-2">{{ folder.icon || 'mdi-folder-outline' }}</v-icon>
                {{ folder.name }}

                <v-menu v-if="!folder.isSystem" location="bottom">
                    <template v-slot:activator="{ props }">
                        <v-icon
                            v-bind="props"
                            size="14"
                            class="ml-2 opacity-0 tab-hover-show transition-all hover-text-white"
                        >mdi-dots-vertical</v-icon>
                    </template>
                    <v-list density="compact" class="glass-menu pa-1">
                        <v-list-item @click="deleteCategory(folder.name)" class="text-error text-caption rounded">
                            <template v-slot:prepend><v-icon size="small">mdi-delete</v-icon></template>
                            Excluir Pasta
                        </v-list-item>
                    </v-list>
                </v-menu>
            </v-tab>
        </v-tabs>
    </div>

    <div class="flex-grow-1 overflow-y-auto custom-scrollbar p-relative bg-glass-body">

        <div v-if="loading" class="d-flex flex-column align-center justify-center h-100 py-12 fade-in">
            <div class="loader-ring mb-4"></div>
            <span class="text-caption text-white-50 font-weight-bold letter-spacing-2">CARREGANDO ARQUIVOS...</span>
        </div>

        <div v-else-if="filteredFiles.length === 0" class="d-flex flex-column align-center justify-center h-100 py-12 opacity-50 fade-in">
            <div class="icon-circle-lg bg-white-05 mb-6 border border-white-05 elevation-10">
                <v-icon size="64" color="white-30">mdi-folder-open-outline</v-icon>
            </div>
            <span class="text-h6 font-weight-bold text-white-50">Esta pasta está vazia</span>
            <span class="text-caption text-white-30 mt-1">Faça upload de arquivos ou mova itens para cá.</span>
            <v-btn variant="text" color="primary" class="mt-4" @click="triggerUpload">Fazer Upload Agora</v-btn>
        </div>

        <div v-else-if="viewMode === 'grid'" class="pa-6 fade-in">
            <v-row dense>
                <v-col cols="12" class="d-flex align-center justify-space-between mb-4">
                    <span class="text-caption text-white-50 font-weight-bold text-uppercase letter-spacing-1">
                        {{ filteredFiles.length }} Arquivos em <span class="text-primary">{{ activeTab === 'all' ? 'Todos' : activeTab }}</span>
                    </span>
                </v-col>

                <v-col
                    v-for="file in filteredFiles"
                    :key="file.id"
                    cols="12" sm="6" md="4" lg="3" xl="2"
                >
                    <v-hover v-slot="{ isHovering, props }">
                        <v-card
                            v-bind="props"
                            class="glass-file-card d-flex flex-column h-100 group relative overflow-hidden"
                            :class="{'hover-active': isHovering}"
                        >
                            <div class="file-preview relative d-flex align-center justify-center bg-gradient-file rounded-t-lg overflow-hidden">
                                <v-icon size="56" :color="getFileIconColor(file.file_type)" class="drop-shadow-lg file-icon transition-transform duration-300">
                                    {{ getFileIcon(file.file_type) }}
                                </v-icon>

                                <div class="absolute inset-0 bg-black-60 backdrop-blur-sm d-flex align-center justify-center gap-2 opacity-0 group-hover:opacity-100 transition-all duration-300">
                                    <v-btn icon size="small" color="white" variant="flat" class="rounded-circle glass-action-btn" :href="file.file_url" target="_blank">
                                        <v-icon size="18">mdi-eye</v-icon>
                                        <v-tooltip activator="parent" location="top">Visualizar</v-tooltip>
                                    </v-btn>
                                    <v-btn icon size="small" color="white" variant="flat" class="rounded-circle glass-action-btn" @click="moveFile(file)">
                                        <v-icon size="18">mdi-folder-move</v-icon>
                                        <v-tooltip activator="parent" location="top">Mover</v-tooltip>
                                    </v-btn>
                                </div>
                            </div>

                            <div class="pa-3 flex-grow-1 d-flex flex-column bg-glass-surface-card">
                                <div class="d-flex justify-space-between align-start mb-1">
                                    <div class="text-subtitle-2 font-weight-bold text-white text-truncate flex-grow-1 pr-2" :title="file.title">
                                        {{ file.title }}
                                    </div>
                                    <v-menu location="bottom end">
                                        <template v-slot:activator="{ props }">
                                            <v-btn icon variant="text" density="compact" size="x-small" v-bind="props" color="white-50" class="hover-text-white">
                                                <v-icon size="16">mdi-dots-vertical</v-icon>
                                            </v-btn>
                                        </template>
                                        <v-list density="compact" class="glass-menu border-white-10 pa-1 rounded-lg">
                                            <v-list-item @click="renameFile(file)" link rounded class="text-caption">
                                                <template v-slot:prepend><v-icon size="small" class="mr-2">mdi-pencil</v-icon></template> Renomear
                                            </v-list-item>
                                            <v-divider class="my-1 border-white-05"></v-divider>
                                            <v-list-item @click="deleteFile(file)" link rounded class="text-caption text-error">
                                                <template v-slot:prepend><v-icon size="small" class="mr-2" color="error">mdi-trash-can</v-icon></template> Excluir
                                            </v-list-item>
                                        </v-list>
                                    </v-menu>
                                </div>

                                <div class="d-flex align-center justify-space-between mt-auto pt-3 border-t border-white-05">
                                    <span class="text-[10px] text-white-50 font-mono">{{ formatDate(file.created_at) }}</span>
                                    <v-chip size="x-small" variant="tonal" :color="getFileTypeColor(file.file_type)" class="font-weight-bold px-2 h-18 border-0">
                                        {{ getExtension(file.file_type) }}
                                    </v-chip>
                                </div>
                            </div>
                        </v-card>
                    </v-hover>
                </v-col>
            </v-row>
        </div>

        <div v-else class="pa-0 fade-in h-100">
            <v-table density="comfortable" class="bg-transparent text-white w-100 h-100 hover-table">
                <thead class="bg-glass-header sticky-header backdrop-blur">
                    <tr>
                        <th class="text-left text-caption font-weight-bold text-white-50 text-uppercase pl-6 w-50">Nome</th>
                        <th class="text-left text-caption font-weight-bold text-white-50 text-uppercase">Data</th>
                        <th class="text-left text-caption font-weight-bold text-white-50 text-uppercase">Tipo</th>
                        <th class="text-left text-caption font-weight-bold text-white-50 text-uppercase">Pasta</th>
                        <th class="text-center text-caption font-weight-bold text-white-50 text-uppercase w-10">Ações</th>
                    </tr>
                </thead>
                <tbody>
                    <tr v-for="file in filteredFiles" :key="file.id" class="border-b border-white-05 transition-colors group">
                        <td class="pl-6 py-3">
                            <div class="d-flex align-center">
                                <v-avatar size="32" :color="getFileTypeColor(file.file_type)" variant="tonal" class="mr-3 rounded">
                                    <v-icon size="18">{{ getFileIcon(file.file_type) }}</v-icon>
                                </v-avatar>
                                <div>
                                    <div class="text-body-2 font-weight-bold text-white">{{ file.title }}</div>
                                </div>
                            </div>
                        </td>
                        <td class="text-caption text-white-70 font-mono">{{ formatDate(file.created_at) }}</td>
                        <td>
                            <v-chip size="x-small" variant="tonal" :color="getFileTypeColor(file.file_type)" class="font-weight-bold">
                                {{ getExtension(file.file_type) }}
                            </v-chip>
                        </td>
                        <td>
                            <div class="d-flex align-center text-caption text-white-70">
                                <v-icon size="14" class="mr-1 text-white-30">mdi-folder</v-icon> {{ file.category }}
                            </div>
                        </td>
                        <td class="text-center">
                            <div class="d-flex justify-center gap-1 opacity-50 group-hover:opacity-100 transition-opacity">
                                <v-btn icon size="x-small" variant="text" color="primary" :href="file.file_url" target="_blank"><v-icon>mdi-eye</v-icon></v-btn>
                                <v-btn icon size="x-small" variant="text" color="white" @click="moveFile(file)"><v-icon>mdi-folder-move</v-icon></v-btn>
                                <v-btn icon size="x-small" variant="text" color="error" @click="deleteFile(file)"><v-icon>mdi-trash-can</v-icon></v-btn>
                            </div>
                        </td>
                    </tr>
                </tbody>
            </v-table>
        </div>
    </div>

    <v-dialog v-model="showCreateTabModal" max-width="450px" persistent content-class="glass-modal-fixed">
        <v-card class="glass-card border-white-10 d-flex flex-column h-100 overflow-hidden">
            <div class="px-6 py-5 border-b border-white-10 d-flex align-center justify-space-between bg-glass-header">
                <div class="d-flex align-center gap-3">
                    <div class="icon-circle bg-white-05 border border-white-10">
                        <v-icon size="20" color="white">mdi-folder-plus</v-icon>
                    </div>
                    <div>
                        <h3 class="text-subtitle-1 font-weight-bold text-white lh-1">Nova Pasta</h3>
                        <div class="text-[10px] text-white-50 mt-1">Organize seus arquivos por categoria</div>
                    </div>
                </div>
                <v-btn icon="mdi-close" variant="text" size="small" color="white-50" @click="showCreateTabModal = false"></v-btn>
            </div>

            <div class="pa-6 flex-grow-1 bg-glass-body-modal">
                <label class="text-caption font-weight-bold text-white-70 text-uppercase mb-2 d-block">Nome da Pasta</label>
                <v-text-field
                    v-model="newFolder.name"
                    placeholder="Ex: Contratos, Marketing..."
                    variant="outlined"
                    density="comfortable"
                    class="glass-input-modal mb-6"
                    bg-color="rgba(0,0,0,0.3)"
                    prepend-inner-icon="mdi-folder-outline"
                    autofocus
                    hide-details
                ></v-text-field>

                <label class="text-caption font-weight-bold text-white-70 text-uppercase mb-2 d-block">Ícone & Cor</label>
                <div class="d-flex gap-4">
                    <div class="flex-grow-1">
                        <div class="icon-grid d-flex flex-wrap gap-2">
                            <div
                                v-for="icon in availableIcons"
                                :key="icon"
                                class="icon-option rounded-lg d-flex align-center justify-center cursor-pointer transition-all"
                                :class="{'active-icon ring-2 ring-primary bg-primary-20': newFolder.icon === icon, 'bg-white-05 hover-bg-white-10': newFolder.icon !== icon}"
                                @click="newFolder.icon = icon"
                            >
                                <v-icon size="20" :color="newFolder.icon === icon ? 'white' : 'white-50'">{{ icon }}</v-icon>
                            </div>
                        </div>
                    </div>

                    <div class="d-flex flex-column gap-2">
                        <div
                            v-for="color in availableColors"
                            :key="color.val"
                            class="color-option rounded-circle cursor-pointer transition-transform hover-scale"
                            :class="{'ring-2 ring-white': newFolder.color === color.val}"
                            :style="{ backgroundColor: color.hex }"
                            @click="newFolder.color = color.val"
                        ></div>
                    </div>
                </div>

                <div class="mt-6 pa-3 rounded-lg bg-white-05 border border-white-05 d-flex align-center justify-center">
                    <span class="text-caption text-white-50 mr-2">Preview:</span>
                    <v-chip size="small" class="font-weight-bold" :color="newFolder.color || 'white'" variant="flat">
                        <v-icon start size="small">{{ newFolder.icon }}</v-icon> {{ newFolder.name || 'Nome da Pasta' }}
                    </v-chip>
                </div>
            </div>

            <div class="pa-4 border-t border-white-10 d-flex justify-end gap-2 bg-glass-footer">
                <v-btn variant="text" color="white-70" class="text-none font-weight-bold px-4" @click="showCreateTabModal = false">Cancelar</v-btn>
                <v-btn
                    color="primary"
                    variant="flat"
                    class="text-none font-weight-bold shadow-glow-primary px-6"
                    @click="createCategory"
                    :disabled="!newFolder.name"
                >
                    Criar Pasta
                </v-btn>
            </div>
        </v-card>
    </v-dialog>

    <v-dialog v-model="showMoveModal" max-width="400px" persistent content-class="glass-modal-fixed">
        <v-card class="glass-card border-white-10 d-flex flex-column">
            <div class="modal-header px-5 py-4 border-b border-white-10 d-flex align-center justify-space-between bg-glass-header">
                <div class="d-flex align-center gap-2 text-white">
                    <v-icon size="small" color="primary">mdi-folder-move</v-icon>
                    <span class="text-subtitle-1 font-weight-bold">Mover Arquivo</span>
                </div>
                <v-btn icon="mdi-close" variant="text" size="small" color="white-50" @click="showMoveModal = false"></v-btn>
            </div>
            <div class="pa-6">
                <div class="mb-4 d-flex align-center gap-3 pa-3 rounded-lg bg-white-05 border border-white-05">
                    <v-icon :color="getFileIconColor(fileToMove?.file_type)">{{ getFileIcon(fileToMove?.file_type) }}</v-icon>
                    <span class="text-caption text-white font-weight-bold text-truncate">{{ fileToMove?.title }}</span>
                </div>
                <v-select
                    v-model="targetCategory"
                    :items="folderNames"
                    label="Selecione a Pasta"
                    variant="outlined"
                    density="comfortable"
                    class="glass-input-modal"
                    bg-color="rgba(0,0,0,0.3)"
                    hide-details
                ></v-select>
            </div>
            <div class="pa-4 border-t border-white-10 d-flex justify-end gap-2 bg-glass-footer">
                <v-btn variant="text" color="white-70" class="text-none" @click="showMoveModal = false">Cancelar</v-btn>
                <v-btn color="primary" variant="flat" class="text-none font-weight-bold shadow-glow-primary" @click="confirmMoveFile" :loading="moving">Mover</v-btn>
            </div>
        </v-card>
    </v-dialog>

  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, computed, reactive } from 'vue'
import { supabase } from '@/api/supabase'
import { useUserStore } from '@/stores/user'
import { useAppStore } from '@/stores/app'
import { format } from 'date-fns'

// Types
type FolderConfig = { name: string; icon: string; color: string; isSystem: boolean }

const userStore = useUserStore()
const appStore = useAppStore()
const files = ref<any[]>([]) // Corrigido nome da variável para 'files'
const folderConfigs = ref<FolderConfig[]>([])
const loading = ref(true)
const uploading = ref(false)
const moving = ref(false)
const activeTab = ref('all')
const search = ref('')
const viewMode = ref('grid')

// Modals State
const showCreateTabModal = ref(false)
const showMoveModal = ref(false)
const fileToMove = ref<any>(null)
const targetCategory = ref('')
const fileInput = ref<HTMLInputElement | null>(null)

// New Folder Form
const newFolder = reactive({
    name: '',
    icon: 'mdi-folder',
    color: 'primary'
})

// Icons and Colors for selection
const availableIcons = [
    'mdi-folder', 'mdi-folder-star', 'mdi-folder-account', 'mdi-folder-image',
    'mdi-folder-key', 'mdi-finance', 'mdi-chart-pie', 'mdi-file-document',
    'mdi-cloud', 'mdi-briefcase', 'mdi-receipt', 'mdi-cart'
]
const availableColors = [
    { val: 'primary', hex: '#2979ff' },
    { val: 'success', hex: '#00e676' },
    { val: 'warning', hex: '#ffea00' },
    { val: 'error', hex: '#ff1744' },
    { val: 'info', hex: '#00e5ff' },
    { val: 'purple', hex: '#d500f9' },
]

// --- COMPUTED ---

const systemFolders: FolderConfig[] = [
    { name: 'Geral', icon: 'mdi-folder-home', color: 'white-70', isSystem: true },
    { name: 'Fechamentos', icon: 'mdi-cash-register', color: 'success', isSystem: true },
    { name: 'Recibos', icon: 'mdi-receipt-text', color: 'warning', isSystem: true },
    { name: 'Clientes', icon: 'mdi-account-details', color: 'info', isSystem: true },
]

const folders = computed(() => {
    const all = [...systemFolders]
    // Add stored custom folders
    folderConfigs.value.forEach(fc => {
        if (!all.find(f => f.name === fc.name)) {
            all.push(fc)
        }
    })
    // Add ad-hoc folders from existing files (fallback)
    const fileCats = new Set(files.value.map(f => f.category).filter(Boolean))
    fileCats.forEach(cat => {
        if (!all.find(f => f.name === cat) && cat !== 'CONFIG_FOLDERS') {
            all.push({ name: cat, icon: 'mdi-folder-outline', color: 'white-70', isSystem: false })
        }
    })
    return all
})

const folderNames = computed(() => folders.value.map(f => f.name))

const filteredFiles = computed(() => {
    let list = files.value.filter(f => f.category !== 'CONFIG_FOLDERS')

    if (activeTab.value !== 'all') {
        list = list.filter(f => f.category === activeTab.value)
    }

    if (search.value) {
        const q = search.value.toLowerCase()
        list = list.filter(f => f.title.toLowerCase().includes(q))
    }

    return list
})

// --- DATA FETCHING ---

const fetchFiles = async () => {
    loading.value = true
    try {
        const { data, error } = await supabase
            .from('user_reports')
            .select('*')
            .order('created_at', { ascending: false })

        if (error) throw error
        files.value = data || []

        // Restore folders from dummy config files
        const configs = data?.filter(f => f.category === 'CONFIG_FOLDERS') || []
        folderConfigs.value = configs.map(c => ({
            name: c.title,
            icon: c.file_path || 'mdi-folder',
            color: c.file_type || 'white',
            isSystem: false
        }))

    } catch (e) {
        console.error("Erro ao buscar arquivos:", e)
    } finally {
        loading.value = false
    }
}

// --- ACTIONS ---

const openCreateFolderModal = () => {
    newFolder.name = ''
    newFolder.icon = 'mdi-folder'
    newFolder.color = 'primary'
    showCreateTabModal.value = true
}

const createCategory = async () => {
    if(!newFolder.name.trim()) return

    try {
        // Save folder config as a hidden file entry
        const { error } = await supabase.from('user_reports').insert({
            user_id: userStore.user?.id,
            title: newFolder.name,
            category: 'CONFIG_FOLDERS',
            file_path: newFolder.icon, // Hack to store icon
            file_type: newFolder.color, // Hack to store color
            file_url: '#'
        })

        if (error) throw error

        folderConfigs.value.push({
            name: newFolder.name,
            icon: newFolder.icon,
            color: newFolder.color,
            isSystem: false
        })

        activeTab.value = newFolder.name
        showCreateTabModal.value = false
        appStore.showSnackbar(`Pasta "${newFolder.name}" criada.`, 'success')

    } catch (e) {
        appStore.showSnackbar('Erro ao criar pasta.', 'error')
    }
}

const deleteCategory = async (catName: string) => {
    if(!confirm(`Tem certeza que deseja excluir a pasta "${catName}"?`)) return

    try {
        await supabase.from('user_reports').delete().eq('category', 'CONFIG_FOLDERS').eq('title', catName)

        const filesInCat = files.value.filter(f => f.category === catName)
        for (const f of filesInCat) {
            await supabase.from('user_reports').update({ category: 'Geral' }).eq('id', f.id)
            f.category = 'Geral'
        }

        folderConfigs.value = folderConfigs.value.filter(f => f.name !== catName)
        if (activeTab.value === catName) activeTab.value = 'all'

        appStore.showSnackbar('Pasta excluída.', 'success')
    } catch(e) {
        appStore.showSnackbar('Erro ao excluir pasta.', 'error')
    }
}

const triggerUpload = () => { fileInput.value?.click() }

const handleFileUpload = async (event: Event) => {
    const target = event.target as HTMLInputElement
    if (!target.files || target.files.length === 0) return
    const file = target.files[0]
    uploading.value = true

    try {
        const userId = userStore.user?.id
        const category = (activeTab.value === 'all' || activeTab.value === 'CONFIG_FOLDERS') ? 'Geral' : activeTab.value
        const fileName = `${Date.now()}_${file.name}`
        const filePath = `${userId}/${fileName}`

        // UPLOAD PARA BUCKET 'cajuia'
        const { error: upErr } = await supabase.storage.from('cajuia').upload(filePath, file)
        if (upErr) throw upErr

        const { data: urlData } = supabase.storage.from('cajuia').getPublicUrl(filePath)

        const { data: newFile, error: dbErr } = await supabase.from('user_reports').insert({
            user_id: userId,
            title: file.name,
            file_url: urlData.publicUrl,
            file_path: filePath,
            category: category,
            file_type: file.type
        }).select().single()

        if (dbErr) throw dbErr

        files.value.unshift(newFile)
        appStore.showSnackbar('Upload concluído!', 'success')

    } catch (e) {
        console.error(e)
        appStore.showSnackbar('Erro no upload.', 'error')
    } finally {
        uploading.value = false
        if (fileInput.value) fileInput.value.value = ''
    }
}

const moveFile = (file: any) => {
    fileToMove.value = file
    targetCategory.value = file.category
    showMoveModal.value = true
}

const confirmMoveFile = async () => {
    if (!fileToMove.value || !targetCategory.value) return
    moving.value = true
    try {
        const { error } = await supabase.from('user_reports').update({ category: targetCategory.value }).eq('id', fileToMove.value.id)
        if (error) throw error

        const idx = files.value.findIndex(f => f.id === fileToMove.value.id)
        if (idx !== -1) files.value[idx].category = targetCategory.value

        showMoveModal.value = false
        appStore.showSnackbar('Arquivo movido.', 'success')
    } catch (e) {
        appStore.showSnackbar('Erro ao mover.', 'error')
    } finally { moving.value = false }
}

const deleteFile = async (file: any) => {
    if (!confirm('Excluir permanentemente?')) return
    try {
        if (file.file_path) {
            await supabase.storage.from('cajuia').remove([file.file_path])
        }
        await supabase.from('user_reports').delete().eq('id', file.id)
        files.value = files.value.filter(f => f.id !== file.id)
        appStore.showSnackbar('Arquivo excluído.', 'success')
    } catch (e) { appStore.showSnackbar('Erro ao excluir.', 'error') }
}

const renameFile = (file: any) => {
    const newName = prompt("Renomear para:", file.title)
    if (newName) {
        supabase.from('user_reports').update({ title: newName }).eq('id', file.id).then(({error}) => {
            if(!error) file.title = newName
        })
    }
}

// Visual Helpers
const formatDate = (d: string) => format(new Date(d), 'dd/MM/yyyy HH:mm')
const getExtension = (type: string) => type?.split('/')[1]?.toUpperCase().slice(0, 4) || 'FILE'
const getFileIcon = (type: string) => {
    if(type?.includes('pdf')) return 'mdi-file-pdf-box'
    if(type?.includes('image')) return 'mdi-file-image'
    if(type?.includes('spreadsheet') || type?.includes('excel')) return 'mdi-file-excel'
    return 'mdi-file-document-outline'
}
const getFileIconColor = (type: string) => {
    if(type?.includes('pdf')) return 'error'
    if(type?.includes('image')) return 'primary'
    if(type?.includes('spreadsheet')) return 'success'
    return 'white'
}
const getFileTypeColor = (type: string) => {
    if(type?.includes('pdf')) return 'error'
    if(type?.includes('image')) return 'primary'
    return 'grey'
}
const getCategoryIcon = (cat: string) => {
    const folder = folders.value.find(f => f.name === cat)
    return folder ? { icon: folder.icon, color: folder.color } : { icon: 'mdi-folder', color: 'white' }
}
const isSystemCategory = (cat: string) => ['Geral', 'Fechamentos', 'Recibos', 'Clientes'].includes(cat)

onMounted(fetchFiles)
</script>

<style scoped lang="scss">
/* GLASS CORE */
.glass-file-card {
    background: rgba(30, 30, 35, 0.4);
    border: 1px solid rgba(255, 255, 255, 0.08);
    border-radius: 16px;
    overflow: hidden;
    transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);

    &:hover {
        transform: translateY(-6px);
        background: rgba(40, 40, 45, 0.6);
        border-color: rgba(var(--v-theme-primary), 0.4);
        box-shadow: 0 12px 30px rgba(0,0,0,0.3);
    }
}

.glass-card {
    background: rgba(25, 25, 30, 0.95);
    border: 1px solid rgba(255, 255, 255, 0.1);
    border-radius: 16px;
    box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.5);
    overflow: hidden;
}

.glass-header { background: rgba(255,255,255,0.03); }
.glass-surface { background: rgba(255,255,255,0.015); }
.glass-surface-card { background: rgba(255,255,255,0.01); }
.glass-body { background: radial-gradient(circle at top left, rgba(40,40,45,0.3), transparent 70%); }
.glass-footer { background: rgba(0,0,0,0.4); }

/* UTILS */
.detail-icon-box { width: 48px; height: 48px; box-shadow: 0 4px 10px rgba(var(--v-theme-primary), 0.3); }
.bg-gradient-cajuia { background: linear-gradient(135deg, #ff6f00, #ffca28); }
.bg-gradient-file { background: linear-gradient(to bottom, rgba(255,255,255,0.03), rgba(0,0,0,0.2)); }
.icon-circle-lg { width: 80px; height: 80px; border-radius: 50%; display: flex; align-items: center; justify-content: center; border: 1px solid rgba(255,255,255,0.05); }

.text-shadow { text-shadow: 0 2px 4px rgba(0,0,0,0.3); }
.lh-1 { line-height: 1; }
.h-32 { height: 32px; } .h-40 { height: 40px; } .h-18 { height: 18px; }

.border-white-05 { border-color: rgba(255, 255, 255, 0.05) !important; }
.border-white-10 { border-color: rgba(255, 255, 255, 0.1) !important; }
.hover-bg-white-05:hover { background: rgba(255, 255, 255, 0.05); }
.hover-bg-white-10:hover { background: rgba(255, 255, 255, 0.1); }
.hover-text-white:hover { color: white !important; }
.hover-red:hover { color: #ff5252 !important; opacity: 1 !important; cursor: pointer; }

/* INPUTS */
.glass-input-search :deep(.v-field) {
    border-radius: 8px;
    font-size: 0.8rem;
    border: 1px solid rgba(255,255,255,0.1);
    transition: border 0.2s;
}
.glass-input-search :deep(.v-field--focused) { border-color: rgb(var(--v-theme-primary)); }
.glass-input-modal :deep(.v-field) { border-radius: 10px; background: rgba(0,0,0,0.3); border: 1px solid rgba(255,255,255,0.1); color: white; }

/* TABS */
.glass-tabs { border-bottom: 1px solid rgba(255,255,255,0.05); }
.folder-tab { opacity: 0.6; transition: all 0.2s; }
.folder-tab:hover { opacity: 1; background: rgba(255,255,255,0.02); }
:deep(.v-tab--selected) { opacity: 1; background: linear-gradient(to top, rgba(var(--v-theme-primary), 0.15), transparent); color: white !important; border-bottom: 2px solid rgb(var(--v-theme-primary)); }

/* SCROLLBAR */
.custom-scrollbar::-webkit-scrollbar { width: 5px; }
.custom-scrollbar::-webkit-scrollbar-track { background: transparent; }
.custom-scrollbar::-webkit-scrollbar-thumb { background: rgba(255,255,255,0.15); border-radius: 3px; }

/* LIST TABLE */
.hover-table tbody tr:hover { background: rgba(255,255,255,0.03) !important; }
.sticky-header { position: sticky; top: 0; z-index: 5; }

/* ANIMATIONS */
.fade-in { animation: fadeIn 0.4s ease; }
@keyframes fadeIn { from { opacity: 0; transform: translateY(10px); } to { opacity: 1; transform: translateY(0); } }
.hover-scale:hover { transform: scale(1.1); }
.shadow-glow-primary { box-shadow: 0 0 15px rgba(var(--v-theme-primary), 0.3); }
.drop-shadow-lg { filter: drop-shadow(0 4px 6px rgba(0,0,0,0.5)); }
.group:hover .opacity-0 { opacity: 1 !important; }
.transition-opacity { transition: opacity 0.2s ease; }
.transition-transform { transition: transform 0.3s ease; }
.file-preview { height: 140px; position: relative; }
.glass-modal-fixed { border-radius: 16px; overflow: hidden; }

/* ICONS GRID */
.icon-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 8px; }
.icon-option { width: 40px; height: 40px; border: 1px solid rgba(255,255,255,0.1); }
.active-icon { border-color: rgb(var(--v-theme-primary)); box-shadow: 0 0 10px rgba(var(--v-theme-primary), 0.3); }
.color-option { width: 24px; height: 24px; }
</style>
