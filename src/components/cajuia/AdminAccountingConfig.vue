<template>
  <div class="d-flex flex-column h-100 bg-glass-body-gradient overflow-hidden">

    <div class="px-6 py-4 border-b border-white-10 d-flex justify-space-between align-center flex-shrink-0 bg-glass-header">
      <div class="d-flex align-center gap-4">
        <div class="icon-box bg-primary-10 rounded-lg d-flex align-center justify-center elevation-4 border border-white-05" style="width: 42px; height: 42px;">
           <v-icon color="primary" size="24">mdi-book-account</v-icon>
        </div>
        <div>
          <h2 class="text-subtitle-1 font-weight-black text-white lh-1 mb-1">Contabilidade Inteligente</h2>
          <div class="text-[11px] text-white-50 font-weight-medium d-flex align-center gap-2">
             <v-icon size="8" color="success" class="icon-pulse">mdi-circle</v-icon>
             <span class="text-uppercase letter-spacing-1">Sistema Ativo</span>
             <v-divider vertical class="border-white-20 h-10"></v-divider>
             <span>{{ accounts.length }} contas cadastradas</span>
          </div>
        </div>
      </div>

      <div class="glass-toggle-container p-1 rounded-lg border border-white-10 bg-black-20">
        <v-btn-toggle v-model="activeTab" density="compact" mandatory class="bg-transparent" color="primary">
            <v-btn value="chart" class="text-[11px] font-weight-bold px-5 rounded-md text-none letter-spacing-05" height="28">
               <v-icon start size="14" class="mr-1">mdi-file-tree</v-icon> Plano de Contas
            </v-btn>
            <v-btn value="automation" class="text-[11px] font-weight-bold px-5 rounded-md text-none letter-spacing-05" height="28">
               <v-icon start size="14" class="mr-1">mdi-robot-outline</v-icon> Automação
            </v-btn>
        </v-btn-toggle>
      </div>
    </div>

    <div class="flex-grow-1 overflow-hidden position-relative">
      <v-fade-transition mode="out-in">

        <div v-if="activeTab === 'chart'" key="chart" class="h-100 d-flex flex-column">

          <div class="px-6 py-2 d-flex justify-space-between align-center border-b border-white-05 bg-white-02 flex-shrink-0">
             <div class="d-flex align-center gap-2 flex-grow-1" style="max-width: 350px;">
                <v-text-field
                   v-model="search"
                   prepend-inner-icon="mdi-magnify"
                   placeholder="Filtrar contas..."
                   variant="outlined"
                   density="compact"
                   hide-details
                   class="glass-input small-input"
                   bg-color="rgba(0,0,0,0.2)"
                ></v-text-field>
             </div>

             <div class="d-flex align-center gap-2">
                <v-btn size="x-small" variant="text" color="white-70" @click="toggleAll(true)" class="text-none">
                   <v-icon start size="14">mdi-arrow-expand-vertical</v-icon> Expandir
                </v-btn>
                <v-btn size="x-small" variant="text" color="white-70" @click="toggleAll(false)" class="text-none">
                   <v-icon start size="14">mdi-arrow-collapse-vertical</v-icon> Recolher
                </v-btn>
                <v-divider vertical class="border-white-10 mx-1 h-16"></v-divider>
                <v-btn color="primary" size="small" prepend-icon="mdi-plus" class="shadow-glow-primary font-weight-bold px-4 rounded-md" height="32" @click="openAccountModal()">
                   Nova Conta
                </v-btn>
             </div>
          </div>

          <div class="grid-header px-6 py-2 text-[10px] text-white-50 font-weight-bold text-uppercase border-b border-white-05 bg-white-05 flex-shrink-0">
             <div style="flex: 2;">Estrutura / Conta</div>
             <div style="width: 90px;">Natureza</div>
             <div style="width: 80px;">Tipo</div>
             <div style="width: 120px;" class="text-right">Criação</div>
             <div style="width: 80px;" class="text-center">Ações</div>
          </div>

          <div class="flex-grow-1 overflow-y-auto custom-scrollbar px-4 py-2">
             <div v-if="loading" class="d-flex flex-column align-center justify-center mt-12">
                <v-progress-circular indeterminate color="primary" size="32" width="3"></v-progress-circular>
                <span class="text-caption text-white-50 mt-3">Carregando estrutura...</span>
             </div>

             <div v-else class="account-tree-container pb-10">
                <template v-for="account in visibleTreeAccounts" :key="account.id">
                   <div
                      class="tree-row d-flex align-center py-1 px-2 rounded mb-1 border border-transparent hover-border-primary transition-all group"
                      :class="{'bg-white-02': account.is_synthetic, 'opacity-60': !account.is_active}"
                   >
                      <div style="flex: 2;" class="d-flex align-center overflow-hidden">
                         <div :style="{ width: (account.level * 22) + 'px' }" class="flex-shrink-0 d-flex justify-end position-relative h-100 mr-1">
                            <div v-if="account.level > 0" class="tree-line-v"></div>
                            <div v-if="account.level > 0" class="tree-line-h"></div>
                         </div>

                         <v-btn
                            v-if="hasChildren(account.id)"
                            icon size="x-small" density="compact" variant="text"
                            :color="isExpanded(account.id) ? 'primary' : 'white-30'"
                            class="mr-1 mt-n1 w-5 h-5"
                            @click.stop="toggleExpand(account.id)"
                         >
                            <v-icon size="14">{{ isExpanded(account.id) ? 'mdi-chevron-down' : 'mdi-chevron-right' }}</v-icon>
                         </v-btn>
                         <div v-else class="mr-6"></div>

                         <v-icon :icon="getAccountIcon(account.nature, account.is_synthetic)" size="16" class="mr-3 opacity-70" :color="getNatureColor(account.nature)"></v-icon>

                         <div class="d-flex flex-column text-truncate cursor-pointer flex-grow-1" @click="openAccountModal(account)">
                            <div class="d-flex align-center">
                               <span class="font-mono text-[10px] font-weight-bold mr-2 text-white-70 bg-white-05 px-1 rounded border border-white-05">{{ account.code }}</span>
                               <span class="text-caption font-weight-bold text-white text-truncate">{{ account.name }}</span>
                               <v-icon v-if="account.is_system_default" size="10" color="warning" class="ml-2 opacity-70" title="Conta de Sistema">mdi-lock</v-icon>
                            </div>
                         </div>
                      </div>

                      <div style="width: 90px;">
                         <v-chip size="x-small" :color="getNatureColor(account.nature)" variant="tonal" class="font-weight-black text-[9px] uppercase border-none px-2 h-20">
                            {{ account.nature }}
                         </v-chip>
                      </div>

                      <div style="width: 80px;">
                         <span class="text-[10px] font-weight-medium" :class="account.is_synthetic ? 'text-white' : 'text-white-30'">
                            {{ account.is_synthetic ? 'Sintética' : 'Analítica' }}
                         </span>
                      </div>

                      <div style="width: 120px;" class="text-right">
                         <span class="text-[10px] text-white-30 font-mono">{{ formatDate(account.created_at) }}</span>
                      </div>

                      <div style="width: 80px;" class="d-flex justify-center opacity-0 group-hover:opacity-100 transition-opacity">
                         <v-btn icon size="x-small" variant="text" color="primary" density="compact" @click.stop="openAccountModal(account)">
                            <v-icon size="14">mdi-pencil</v-icon>
                         </v-btn>

                         <v-btn
                            v-if="!account.is_system_default"
                            icon size="x-small" variant="text" color="error" density="compact"
                            @click.stop="deleteAccount(account)"
                         >
                            <v-icon size="14">mdi-delete</v-icon>
                         </v-btn>
                      </div>
                   </div>
                </template>
             </div>
          </div>
        </div>

        <div v-else-if="activeTab === 'automation'" key="automation" class="h-100 overflow-y-auto custom-scrollbar d-flex flex-column">
           <div class="pa-6 mx-auto w-100" style="max-width: 960px;">

              <div class="glass-card pa-5 rounded-xl mb-6 d-flex align-center gap-5 bg-gradient-dark border-none shadow-lg position-relative overflow-hidden">
                 <div class="position-absolute top-0 right-0 opacity-05 pointer-events-none">
                    <v-icon size="180" style="transform: rotate(-15deg); margin-right: -30px; margin-top: -30px;">mdi-robot</v-icon>
                 </div>

                 <div class="icon-circle-large bg-primary text-white shadow-glow-primary z-1 flex-shrink-0">
                    <v-icon size="28">mdi-auto-fix</v-icon>
                 </div>
                 <div class="z-1">
                    <h3 class="text-subtitle-1 font-weight-black text-white mb-1">Automação Contábil (De-Para)</h3>
                    <p class="text-caption text-white-70 lh-1-4" style="max-width: 600px;">
                       Para o Cajuia gerar o Livro Diário automaticamente, ele precisa saber onde lançar cada valor.
                       Use os cartões abaixo para ensinar ao sistema qual conta do seu plano corresponde a cada função.
                    </p>
                 </div>
              </div>

              <div class="d-flex flex-column gap-4 pb-10">

                 <div v-for="config in configs" :key="config.key" class="glass-card pa-0 rounded-xl overflow-hidden border-white-05 transition-all hover-highlight">

                    <div class="px-5 py-3 border-b border-white-05 bg-white-02 d-flex justify-space-between align-center">
                       <div class="d-flex align-center gap-3">
                          <v-avatar :color="getConfigColor(config.key)" variant="tonal" rounded="lg" size="32">
                             <v-icon size="18">{{ getConfigIcon(config.key) }}</v-icon>
                          </v-avatar>
                          <div>
                             <div class="text-body-2 font-weight-bold text-white">{{ formatConfigName(config.key) }}</div>
                             <div class="text-[10px] text-white-50 font-weight-bold text-uppercase tracking-wide">{{ getConfigCategory(config.key) }}</div>
                          </div>
                       </div>

                       <v-tooltip location="top" max-width="300" open-on-click>
                          <template v-slot:activator="{ props }">
                             <v-btn v-bind="props" icon variant="text" size="x-small" color="white-30">
                                <v-icon>mdi-help-circle-outline</v-icon>
                             </v-btn>
                          </template>
                          <span class="text-caption">{{ config.description }}</span>
                       </v-tooltip>
                    </div>

                    <div class="pa-5 d-flex flex-wrap gap-6 align-start">

                       <div style="flex: 1; min-width: 300px;">
                          <label class="text-[11px] font-weight-bold text-white-50 mb-2 d-block text-uppercase">Vincular Conta Analítica</label>

                          <v-autocomplete
                             v-model="config.account_id"
                             :items="analyticalAccounts"
                             item-title="displayName"
                             item-value="id"
                             placeholder="Selecione a conta..."
                             variant="outlined"
                             density="compact"
                             hide-details
                             bg-color="rgba(0,0,0,0.2)"
                             class="glass-input account-select"
                             @update:model-value="saveConfig(config)"
                             menu-icon="mdi-chevron-down"
                          >
                             <template v-slot:selection="{ item }">
                                <span class="font-weight-bold text-white text-caption">{{ item.title }}</span>
                             </template>
                             <template v-slot:item="{ props, item }">
                                <v-list-item v-bind="props" class="dense-list-item py-1 min-h-0">
                                   <template v-slot:prepend>
                                      <v-icon size="10" :color="getNatureColor(item.raw.nature)" class="mr-2">mdi-circle</v-icon>
                                   </template>
                                   <v-list-item-title class="font-weight-bold font-mono text-caption">{{ item.raw.code }}</v-list-item-title>
                                   <v-list-item-subtitle class="text-[10px]">{{ item.raw.name }}</v-list-item-subtitle>
                                </v-list-item>
                             </template>
                          </v-autocomplete>

                          <div class="mt-3 d-flex align-center gap-2" v-if="config.account_id">
                             <v-icon color="success" size="14">mdi-check-circle</v-icon>
                             <span class="text-[10px] text-success font-weight-bold">Vinculado: {{ getAccountName(config.account_id) }}</span>
                          </div>
                          <div class="mt-3 d-flex align-center gap-2" v-else>
                             <v-icon color="error" size="14">mdi-alert-circle</v-icon>
                             <span class="text-[10px] text-error font-weight-bold">Ação Necessária: Selecione uma conta</span>
                          </div>
                       </div>

                       <div class="glass-well pa-3 rounded-lg flex-grow-1 border-white-05 position-relative bg-black-20" style="max-width: 450px;">
                          <div class="text-[9px] font-weight-bold text-white-30 text-uppercase mb-2">Simulação de Lançamento</div>

                          <div class="d-flex align-center gap-3">
                             <div class="d-flex flex-column align-center" style="width: 40px;">
                                <div class="text-h6">🏁</div>
                                <div class="h-20 border-l border-dashed border-white-20 my-1"></div>
                                <div class="text-h6">📒</div>
                             </div>

                             <div class="flex-grow-1">
                                <div class="text-caption text-white font-weight-bold mb-1">
                                   {{ getConfigScenario(config.key) }}
                                </div>
                                <div class="text-[10px] font-mono bg-white-05 pa-2 rounded text-white-70 border border-white-05">
                                   <div v-if="config.key.includes('asset')">
                                      <span class="text-success font-weight-black">DÉBITO</span> na conta vinculada
                                      <div class="mt-1 opacity-50">"Entrada de valor no caixa/banco"</div>
                                   </div>
                                   <div v-else-if="config.key.includes('revenue')">
                                      <span class="text-info font-weight-black">CRÉDITO</span> na conta vinculada
                                      <div class="mt-1 opacity-50">"Registro do ganho financeiro"</div>
                                   </div>
                                   <div v-else-if="config.key.includes('discount')">
                                      <span class="text-warning font-weight-black">DÉBITO</span> na conta vinculada
                                      <div class="mt-1 opacity-50">"Registro do custo do desconto"</div>
                                   </div>
                                </div>
                             </div>
                          </div>
                       </div>

                    </div>
                 </div>

              </div>
           </div>
        </div>

      </v-fade-transition>
    </div>

    <v-dialog v-model="showModal" max-width="400px" content-class="glass-modal">
       <v-card class="bg-glass-card border-white-10">
          <div class="pa-4 border-b border-white-10 bg-glass-header d-flex justify-space-between align-center">
             <div class="d-flex align-center gap-2">
                <v-icon color="primary" size="small">{{ editingAccount.id ? 'mdi-pencil' : 'mdi-plus' }}</v-icon>
                <span class="text-subtitle-2 text-white font-weight-bold">{{ editingAccount.id ? 'Editar Conta' : 'Nova Conta' }}</span>
             </div>
             <v-btn icon variant="text" size="small" color="white-50" @click="showModal = false"><v-icon>mdi-close</v-icon></v-btn>
          </div>

          <div class="pa-5 d-flex flex-column gap-3">
             <v-text-field
                v-model="editingAccount.code"
                label="Código Hierárquico"
                placeholder="Ex: 1.1.05"
                variant="outlined"
                density="compact"
                class="glass-input"
                hint="Use pontos para separar níveis"
                persistent-hint
                prepend-inner-icon="mdi-numeric"
             ></v-text-field>

             <v-text-field
                v-model="editingAccount.name"
                label="Nome da Conta"
                placeholder="Ex: Caixa Pequeno"
                variant="outlined"
                density="compact"
                class="glass-input"
                prepend-inner-icon="mdi-tag-text-outline"
             ></v-text-field>

             <div class="d-flex gap-2 align-start">
                <v-select
                   v-model="editingAccount.nature"
                   :items="natureOptions"
                   label="Natureza"
                   variant="outlined"
                   density="compact"
                   class="glass-input w-50"
                   hide-details
                ></v-select>

                <div class="glass-well rounded px-2 py-0 w-50 d-flex align-center border border-white-10" style="height: 40px;">
                   <v-checkbox
                      v-model="editingAccount.is_synthetic"
                      color="primary"
                      hide-details
                      density="compact"
                      class="ma-0 pa-0"
                   >
                      <template v-slot:label>
                         <span class="text-caption font-weight-bold text-white">Sintética?</span>
                      </template>
                   </v-checkbox>
                </div>
             </div>

             <v-autocomplete
                v-model="editingAccount.parent_id"
                :items="syntheticAccounts"
                item-title="displayName"
                item-value="id"
                label="Conta Pai (Agrupadora)"
                placeholder="Selecione..."
                variant="outlined"
                density="compact"
                class="glass-input"
                clearable
                hide-details
             >
                <template v-slot:no-data><div class="pa-2 text-caption">Nenhuma conta sintética disponível</div></template>
             </v-autocomplete>
          </div>

          <div class="pa-4 border-t border-white-10 bg-glass-footer d-flex justify-end gap-2">
             <v-btn color="white-50" variant="text" class="text-none text-caption font-weight-bold" @click="showModal = false">Cancelar</v-btn>
             <v-btn color="primary" variant="flat" class="font-weight-bold shadow-glow-primary text-none px-6 text-caption" @click="saveAccount" :loading="saving">
                Salvar
             </v-btn>
          </div>
       </v-card>
    </v-dialog>

  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { supabase } from '@/api/supabase'
import { useAppStore } from '@/stores/app'
import { format } from 'date-fns'

const appStore = useAppStore()
const activeTab = ref('chart')
const loading = ref(false)
const saving = ref(false)
const search = ref('')
const accounts = ref<any[]>([])
const configs = ref<any[]>([])
const showModal = ref(false)
const expandedIds = ref<Set<string>>(new Set())

const editingAccount = ref({
    id: null,
    code: '',
    name: '',
    nature: 'ativo',
    parent_id: null,
    is_synthetic: false,
    is_system_default: false
})

const natureOptions = [
    { title: 'Ativo', value: 'ativo' },
    { title: 'Passivo', value: 'passivo' },
    { title: 'Receita', value: 'receita' },
    { title: 'Despesa', value: 'despesa' },
    { title: 'Patrimônio', value: 'patrimonio' }
]

// --- COMPUTED / LOGIC ---
const sortedAccounts = computed(() => [...accounts.value].sort((a, b) => a.code.localeCompare(b.code, undefined, { numeric: true })))
const syntheticAccounts = computed(() => sortedAccounts.value.filter(a => a.is_synthetic).map(a => ({ ...a, displayName: `${a.code} - ${a.name}` })))
const analyticalAccounts = computed(() => sortedAccounts.value.filter(a => !a.is_synthetic).map(a => ({ ...a, displayName: `${a.code} - ${a.name}` })))

const visibleTreeAccounts = computed(() => {
    let list = sortedAccounts.value
    if(search.value) {
        const q = search.value.toLowerCase()
        return list.filter(a => a.name.toLowerCase().includes(q) || a.code.includes(q)).map(a => ({ ...a, level: 0 }))
    }
    const parentMap = new Map(list.map(a => [a.id, a]))
    return list.filter(account => {
        if (!account.parent_id) return true
        let curr = parentMap.get(account.parent_id)
        while(curr) {
            if (!expandedIds.value.has(curr.id)) return false
            curr = curr.parent_id ? parentMap.get(curr.parent_id) : null
        }
        return true
    }).map(account => {
        let level = 0
        let curr = parentMap.get(account.parent_id)
        while(curr) { level++; curr = curr.parent_id ? parentMap.get(curr.parent_id) : null }
        return { ...account, level }
    })
})

const hasChildren = (id: string) => accounts.value.some(a => a.parent_id === id)
const isExpanded = (id: string) => expandedIds.value.has(id)

// --- ACTIONS ---
const toggleExpand = (id: string) => { if (expandedIds.value.has(id)) expandedIds.value.delete(id); else expandedIds.value.add(id); }
const toggleAll = (expand: boolean) => {
    if (expand) expandedIds.value = new Set(accounts.value.filter(a => a.is_synthetic).map(a => a.id))
    else expandedIds.value.clear()
}

const fetchData = async () => {
    loading.value = true
    try {
        const [accRes, cfgRes] = await Promise.all([
            supabase.from('cajuia_accounts').select('*').order('code'),
            supabase.from('cajuia_accounting_configs').select('*')
        ])
        accounts.value = accRes.data || []
        configs.value = cfgRes.data || []

        // Expande apenas o nível raiz (nível 0) por padrão
        const rootIds = accounts.value.filter(a => !a.parent_id).map(a => a.id)
        rootIds.forEach(id => expandedIds.value.add(id))

        ensureDefaultConfigs()
    } catch (e) {
        appStore.showSnackbar('Erro ao carregar dados.', 'error')
    } finally {
        loading.value = false
    }
}

const ensureDefaultConfigs = () => {
    const defaults = [
        { key: 'default_asset_account', description: 'Conta de Ativo (Caixa ou Banco) onde o dinheiro das vendas à vista será depositado.' },
        { key: 'default_revenue_account', description: 'Conta de Receita onde será registrado o ganho da venda.' },
        { key: 'default_discount_account', description: 'Conta de Despesa onde será registrado o custo dos descontos.' }
    ]
    defaults.forEach(def => {
        if (!configs.value.find(c => c.key === def.key)) {
            configs.value.push({ key: def.key, account_id: null, description: def.description })
        }
    })
}

const openAccountModal = (account: any = null) => {
    editingAccount.value = account ? { ...account } : { id: null, code: '', name: '', nature: 'ativo', parent_id: null, is_synthetic: false, is_system_default: false }
    showModal.value = true
}

const saveAccount = async () => {
    if(!editingAccount.value.code || !editingAccount.value.name) return
    saving.value = true
    try {
        const payload = {
            code: editingAccount.value.code,
            name: editingAccount.value.name,
            nature: editingAccount.value.nature,
            parent_id: editingAccount.value.parent_id,
            is_synthetic: editingAccount.value.is_synthetic
        }
        if(editingAccount.value.id) await supabase.from('cajuia_accounts').update(payload).eq('id', editingAccount.value.id)
        else await supabase.from('cajuia_accounts').insert(payload)
        showModal.value = false
        fetchData()
        appStore.showSnackbar('Conta salva com sucesso!', 'success')
    } catch(e) {
        appStore.showSnackbar('Erro ao salvar conta.', 'error')
    } finally {
        saving.value = false
    }
}

const deleteAccount = async (account: any) => {
    if(hasChildren(account.id)) { appStore.showSnackbar('Não é possível excluir conta que possui subcontas.', 'warning'); return; }
    if(!confirm(`Excluir "${account.name}"?`)) return
    try {
        await supabase.from('cajuia_accounts').delete().eq('id', account.id)
        fetchData()
        appStore.showSnackbar('Conta excluída.', 'success')
    } catch(e) { appStore.showSnackbar('Erro ao excluir.', 'error') }
}

const saveConfig = async (config: any) => {
    try {
        await supabase.from('cajuia_accounting_configs').upsert({ key: config.key, account_id: config.account_id, description: config.description })
        appStore.showSnackbar('Configuração salva!', 'success')
    } catch(e) { appStore.showSnackbar('Erro ao salvar configuração.', 'error') }
}

const getAccountName = (id: string) => accounts.value.find(a => a.id === id)?.name

// --- HELPER VISUAIS ---
const getAccountIcon = (nature: string, isSynthetic: boolean) => {
    if (isSynthetic) return 'mdi-folder-outline'
    switch(nature) {
        case 'ativo': return 'mdi-wallet-outline'; case 'passivo': return 'mdi-file-document-outline'; case 'receita': return 'mdi-arrow-up-circle-outline'; case 'despesa': return 'mdi-arrow-down-circle-outline'; default: return 'mdi-circle-small'
    }
}
const getNatureColor = (nature: string) => {
    switch(nature) { case 'ativo': return 'primary'; case 'passivo': return 'error'; case 'receita': return 'success'; case 'despesa': return 'warning'; default: return 'grey' }
}
const getConfigIcon = (key: string) => {
    if(key.includes('revenue')) return 'mdi-cash-plus'; if(key.includes('asset')) return 'mdi-bank'; if(key.includes('discount')) return 'mdi-tag-minus'; return 'mdi-cog'
}
const getConfigColor = (key: string) => {
    if(key.includes('revenue')) return 'success'; if(key.includes('asset')) return 'primary'; if(key.includes('discount')) return 'warning'; return 'grey'
}
const getConfigCategory = (key: string) => {
    if(key.includes('revenue')) return 'Faturamento'; if(key.includes('asset')) return 'Tesouraria'; if(key.includes('discount')) return 'Comercial'; return 'Geral'
}
const getConfigScenario = (key: string) => {
    if(key.includes('asset')) return 'Quando entra dinheiro...'; if(key.includes('revenue')) return 'Quando uma venda é feita...'; if(key.includes('discount')) return 'Quando há desconto...'; return 'Em operação padrão...'
}
const formatConfigName = (key: string) => {
    const map: Record<string, string> = { 'default_asset_account': 'Conta de Caixa/Banco', 'default_revenue_account': 'Receita de Vendas', 'default_discount_account': 'Descontos Concedidos' }
    return map[key] || key
}
const formatDate = (d: string) => d ? format(new Date(d), 'dd/MM/yyyy') : '-'

onMounted(() => fetchData())
</script>

<style scoped lang="scss">
/* Inputs e Selects */
.glass-input :deep(.v-field) {
    border-radius: 8px !important;
    border: 1px solid rgba(255, 255, 255, 0.1);
    color: white !important;
    font-size: 0.8rem;
    transition: all 0.2s;
    &.v-field--focused { border-color: rgba(var(--v-theme-primary), 0.5); background: rgba(0,0,0,0.4); }
}
.glass-input.small-input :deep(.v-field__input) { min-height: 32px; padding-top: 4px; padding-bottom: 4px; }

/* Cards e Paineis */
.glass-card { background: rgba(255, 255, 255, 0.03); border: 1px solid rgba(255, 255, 255, 0.08); backdrop-filter: blur(10px); }
.hover-highlight:hover { background: rgba(255, 255, 255, 0.05); border-color: rgba(255, 255, 255, 0.15); transform: translateY(-1px); }

/* Toggle de Abas */
.glass-toggle-container { background: rgba(0,0,0,0.3); }

/* Árvore */
.tree-row { position: relative; border: 1px solid transparent; &:hover { background: rgba(255,255,255,0.03); border-color: rgba(255,255,255,0.08); } }
.tree-line-v { position: absolute; left: 50%; top: -50%; bottom: 0; width: 1px; background: rgba(255, 255, 255, 0.1); }
.tree-line-h { position: absolute; left: 50%; top: 50%; width: 50%; height: 1px; background: rgba(255, 255, 255, 0.1); }

/* Layout Geral */
.grid-header { display: flex; align-items: center; gap: 8px; }
.icon-box { display: flex; align-items: center; justify-content: center; }
.bg-glass-header { background: rgba(30, 30, 35, 0.85); backdrop-filter: blur(20px); }
.bg-glass-card { background: #1e1e24; border-radius: 12px; }
.bg-gradient-dark { background: linear-gradient(135deg, #1a1a1f 0%, #25252b 100%); }

/* Utilitários */
.bg-white-02 { background: rgba(255,255,255,0.02); }
.bg-white-05 { background: rgba(255,255,255,0.05); }
.bg-black-20 { background: rgba(0,0,0,0.2); }
.bg-primary-10 { background: rgba(var(--v-theme-primary), 0.15); }
.border-white-05 { border-color: rgba(255,255,255,0.05) !important; }
.border-white-10 { border-color: rgba(255,255,255,0.1) !important; }
.text-xs { font-size: 10px !important; }
.lh-1 { line-height: 1; }
.lh-1-4 { line-height: 1.4; }
.w-5 { width: 20px; } .h-5 { height: 20px; } .h-20 { height: 20px; }
.shadow-glow-primary { box-shadow: 0 0 15px rgba(var(--v-theme-primary), 0.3); }
.icon-pulse { animation: pulse 2s infinite; }
@keyframes pulse { 0% { opacity: 1; } 50% { opacity: 0.5; } 100% { opacity: 1; } }
.custom-scrollbar::-webkit-scrollbar { width: 5px; }
.custom-scrollbar::-webkit-scrollbar-thumb { background: rgba(255, 255, 255, 0.15); border-radius: 3px; }
.group:hover .group-hover\:opacity-100 { opacity: 1; }
.pointer-events-none { pointer-events: none; }
</style>
