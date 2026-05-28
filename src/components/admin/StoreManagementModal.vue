<template>
  <v-dialog
    :model-value="show"
    @update:model-value="$emit('close')"
    max-width="700px"
    persistent
    transition="dialog-bottom-transition"
  >
    <v-card :class="themeClasses.card">
      <div class="pa-5 border-b d-flex justify-space-between align-center" :class="themeClasses.headerBorder">
         <div class="d-flex align-center">
            <div class="icon-box mr-3 elevation-4" :class="isLight ? 'bg-purple-darken-3' : 'bg-purple-gradient shadow-glow-purple'">
               <v-icon color="white" size="20">mdi-store-cog</v-icon>
            </div>
            <div>
               <div class="text-subtitle-1 font-weight-black lh-1" :class="themeClasses.textPrimary">Gerenciar Unidades</div>
               <div class="text-caption" :class="themeClasses.textSecondary">Cadastre lojas físicas e vincule aos CNPJs.</div>
            </div>
         </div>
         <v-btn icon="mdi-close" variant="text" size="small" :color="themeClasses.iconColor" @click="$emit('close')"></v-btn>
      </div>

      <v-card-text class="pa-6" :class="themeClasses.bodyBg">

        <div class="pa-4 rounded-xl border mb-6" :class="themeClasses.well">
            <div class="text-[10px] font-weight-bold text-uppercase mb-2 letter-spacing-1" :class="themeClasses.textLabel">Nova Loja</div>

            <div class="d-flex flex-column gap-3">
                <v-select
                    v-model="newStoreCompanyId"
                    :items="companies"
                    item-title="trade_name"
                    item-value="id"
                    placeholder="Selecione a Empresa Matriz"
                    variant="outlined"
                    density="compact"
                    :bg-color="inputBg"
                    :color="isLight ? 'primary' : 'white'"
                    hide-details
                    class="enterprise-input"
                >
                    <template v-slot:prepend-inner>
                        <v-icon size="18" :color="themeClasses.iconColor">mdi-domain</v-icon>
                    </template>
                </v-select>

                <div class="d-flex gap-2">
                    <v-text-field
                        v-model="newStoreName"
                        placeholder="Nome da Loja (Ex: Filial Shopping)"
                        variant="outlined"
                        density="compact"
                        :bg-color="inputBg"
                        :color="isLight ? 'primary' : 'white'"
                        hide-details
                        class="enterprise-input flex-grow-1"
                        :loading="isCreating"
                        @keyup.enter="createStore"
                    >
                        <template v-slot:prepend-inner>
                            <v-icon size="18" :color="themeClasses.iconColor">mdi-store-plus</v-icon>
                        </template>
                    </v-text-field>

                    <v-btn
                        color="primary"
                        height="40"
                        class="font-weight-bold px-6 rounded-lg text-caption"
                        :class="{ 'shadow-glow-primary': !isLight }"
                        :loading="isCreating"
                        :disabled="!newStoreName || !newStoreCompanyId"
                        @click="createStore"
                    >
                        <v-icon start size="18">mdi-plus</v-icon> Adicionar
                    </v-btn>
                </div>
            </div>
        </div>

        <div class="d-flex justify-space-between align-center mb-2 px-1">
            <span class="text-[10px] font-weight-bold text-uppercase" :class="themeClasses.textLabel">Unidades Cadastradas ({{ stores.length }})</span>
        </div>

        <div class="stores-list custom-scrollbar pr-1" style="max-height: 400px; overflow-y: auto;">
            <div v-if="loading" class="d-flex justify-center py-8">
                <v-progress-circular indeterminate color="primary" size="24" width="3"></v-progress-circular>
            </div>

            <div v-else-if="stores.length === 0" class="text-center py-8 opacity-50">
                <v-icon size="40" class="mb-2" :color="themeClasses.iconMuted">mdi-store-off</v-icon>
                <div class="text-caption" :class="themeClasses.textSecondary">Nenhuma loja cadastrada.</div>
            </div>

            <div v-else v-for="store in stores" :key="store.id"
                 class="store-item d-flex align-center justify-space-between pa-3 mb-2 rounded-lg border transition-all"
                 :class="themeClasses.itemCard"
            >
                <div class="d-flex align-center gap-3 flex-grow-1">
                    <div class="store-icon rounded-lg d-flex align-center justify-center border"
                         :class="[store.active ? 'text-success border-success-subtle' : 'text-grey border-grey-subtle', isLight ? 'bg-white' : 'bg-white-05']">
                        <v-icon size="18">{{ store.active ? 'mdi-store-check' : 'mdi-store-remove' }}</v-icon>
                    </div>

                    <div class="flex-grow-1">
                        <div v-if="editingId === store.id" class="d-flex align-center gap-2">
                            <input
                                v-model="editingName"
                                class="glass-input-edit text-body-2 font-weight-bold flex-grow-1"
                                :class="themeClasses.textPrimary"
                                @keyup.enter="updateStore(store)"
                                autoFocus
                            />
                            <v-btn icon size="x-small" color="success" variant="text" @click="updateStore(store)"><v-icon>mdi-check</v-icon></v-btn>
                            <v-btn icon size="x-small" color="error" variant="text" @click="cancelEdit"><v-icon>mdi-close</v-icon></v-btn>
                        </div>
                        <div v-else>
                            <div class="text-body-2 font-weight-bold lh-1" :class="themeClasses.textPrimary">{{ store.name }}</div>
                            <div class="text-[10px] mt-1 d-flex align-center gap-1" :class="themeClasses.textSecondary">
                                <v-icon size="10" color="primary">mdi-domain</v-icon>
                                {{ store.companies?.trade_name || 'Sem Vínculo' }}
                            </div>
                        </div>
                    </div>
                </div>

                <div class="d-flex align-center gap-1 ml-4">
                    <v-tooltip text="Ativar/Desativar" location="top" :content-class="tooltipClass">
                        <template v-slot:activator="{ props }">
                            <div v-bind="props">
                                <v-switch
                                    :model-value="store.active"
                                    color="success"
                                    density="compact"
                                    hide-details
                                    inset
                                    class="scale-75 mr-1"
                                    @update:model-value="toggleActive(store)"
                                ></v-switch>
                            </div>
                        </template>
                    </v-tooltip>

                    <v-tooltip text="Editar Nome" location="top" :content-class="tooltipClass">
                        <template v-slot:activator="{ props }">
                            <v-btn v-bind="props" icon size="x-small" variant="text" color="info" class="opacity-70 hover-100" @click="startEdit(store)">
                                <v-icon size="18">mdi-pencil-outline</v-icon>
                            </v-btn>
                        </template>
                    </v-tooltip>

                    <v-tooltip text="Excluir Loja" location="top" :content-class="tooltipClass">
                        <template v-slot:activator="{ props }">
                            <v-btn v-bind="props" icon size="x-small" variant="text" color="error" class="opacity-70 hover-100" @click="deleteStore(store)">
                                <v-icon size="18">mdi-trash-can-outline</v-icon>
                            </v-btn>
                        </template>
                    </v-tooltip>
                </div>
            </div>
        </div>
      </v-card-text>
    </v-card>
  </v-dialog>
</template>

<script setup lang="ts">
import { ref, watch, computed } from 'vue';
import { supabase } from '@/api/supabase';
import { useThemeStore } from '@/stores/theme';

const props = defineProps<{ show: boolean }>();
const emit = defineEmits(['close', 'change']);
const themeStore = useThemeStore();

const stores = ref<any[]>([]);
const companies = ref<any[]>([]);
const loading = ref(false);
const isCreating = ref(false);
const newStoreName = ref('');
const newStoreCompanyId = ref<string | null>(null);
const editingId = ref<string | null>(null);
const editingName = ref('');

// --- THEME LOGIC ---
const isLight = computed(() => themeStore.currentMode === 'light');

const tooltipClass = computed(() => isLight.value
    ? 'bg-grey-darken-3 text-white font-weight-bold elevation-4'
    : 'bg-white text-black font-weight-bold elevation-4'
);

const inputBg = computed(() => isLight.value ? 'white' : 'rgba(255,255,255,0.05)');

const themeClasses = computed(() => ({
    card: isLight.value ? 'bg-white rounded-xl' : 'glass-modal border-white-10',
    headerBorder: isLight.value ? 'border-grey-lighten-2 bg-grey-lighten-5' : 'border-white-10 bg-glass-header',
    bodyBg: isLight.value ? 'bg-white' : 'bg-glass-surface',
    well: isLight.value ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'glass-well border-white-05',
    textPrimary: isLight.value ? 'text-grey-darken-4' : 'text-white',
    textSecondary: isLight.value ? 'text-grey-darken-1' : 'text-white-50',
    textLabel: isLight.value ? 'text-grey-darken-1' : 'text-white-30',
    iconColor: isLight.value ? 'grey-darken-2' : 'white',
    iconMuted: isLight.value ? 'grey-lighten-1' : 'white-10',
    itemCard: isLight.value
        ? 'bg-white border-grey-lighten-2 hover-bg-grey-lighten-5'
        : 'bg-white-02 border-white-05 hover-border-white-10'
}));

// --- DATA FETCHING ---
const fetchStores = async () => {
    loading.value = true;
    const { data, error } = await supabase.from('stores').select('*, companies(trade_name)').order('created_at', { ascending: true });
    stores.value = data || [];
    const { data: compData } = await supabase.from('companies').select('id, trade_name').eq('active', true);
    companies.value = compData || [];
    loading.value = false;
};

// --- CRUD OPERATIONS ---
const createStore = async () => {
    if (!newStoreName.value.trim() || !newStoreCompanyId.value) return;
    isCreating.value = true;
    try {
        const { error } = await supabase.from('stores').insert({
            name: newStoreName.value, active: true, company_id: newStoreCompanyId.value
        });
        if (error) throw error;
        newStoreName.value = '';
        await fetchStores();
        emit('change');
    } catch (e) { alert('Erro ao criar loja.'); }
    finally { isCreating.value = false; }
};

const startEdit = (store: any) => { editingId.value = store.id; editingName.value = store.name; };
const cancelEdit = () => { editingId.value = null; editingName.value = ''; };

const updateStore = async (store: any) => {
    if (!editingName.value.trim()) return;
    try {
        await supabase.from('stores').update({ name: editingName.value }).eq('id', store.id);
        store.name = editingName.value;
        cancelEdit();
        emit('change');
    } catch (e) { alert('Erro ao atualizar.'); }
};

const toggleActive = async (store: any) => {
    const newState = !store.active;
    store.active = newState;
    try {
        await supabase.from('stores').update({ active: newState }).eq('id', store.id);
        emit('change');
    } catch (e) { store.active = !newState; }
};

const deleteStore = async (store: any) => {
    if (!confirm(`Excluir "${store.name}"?`)) return;
    try {
        await supabase.from('stores').delete().eq('id', store.id);
        await fetchStores();
        emit('change');
    } catch (e) { alert('Não foi possível excluir.'); }
};

watch(() => props.show, (val) => { if (val) fetchStores(); });
</script>

<style scoped lang="scss">
/* THEME UTILS */
.glass-modal { background: rgba(30, 30, 35, 0.95) !important; border: 1px solid rgba(255,255,255,0.1); border-radius: 16px; backdrop-filter: blur(20px); }
.glass-well { background: rgba(255,255,255,0.02); }
.bg-glass-header { background: rgba(255, 255, 255, 0.03); }
.bg-glass-surface { background: #121214; }

.hover-bg-grey-lighten-5:hover { background-color: #F5F5F5 !important; }
.hover-border-white-10:hover { border-color: rgba(255,255,255,0.15) !important; background: rgba(255,255,255,0.03); }

/* ELEMENTS */
.icon-box { width: 32px; height: 32px; display: flex; align-items: center; justify-content: center; border-radius: 8px; }
.store-icon { width: 36px; height: 36px; }
.bg-purple-gradient { background: linear-gradient(135deg, #7b1fa2, #4a148c); }
.shadow-glow-purple { box-shadow: 0 4px 15px rgba(123, 31, 162, 0.4); }
.shadow-glow-primary { box-shadow: 0 0 20px rgba(var(--v-theme-primary), 0.3); }

/* INPUT OVERRIDES FOR ENTERPRISE LOOK */
.enterprise-input :deep(.v-field) {
    border-radius: 8px !important;
    font-size: 0.85rem;
}
.glass-input-edit {
    background: transparent;
    border-bottom: 1px solid currentColor;
    padding: 2px 4px;
    outline: none;
}

.lh-1 { line-height: 1.2; }
.letter-spacing-1 { letter-spacing: 0.5px; }
.opacity-50 { opacity: 0.5; }
.opacity-70 { opacity: 0.7; }
.hover-100:hover { opacity: 1; }
.scale-75 { transform: scale(0.75); transform-origin: right center; }

/* BORDERS */
.border-success-subtle { border: 1px solid rgba(76, 175, 80, 0.3) !important; }
.border-grey-subtle { border: 1px solid rgba(158, 158, 158, 0.3) !important; }
.border-white-05 { border-color: rgba(255,255,255,0.05) !important; }
.border-white-10 { border-color: rgba(255,255,255,0.1) !important; }
.bg-white-02 { background: rgba(255,255,255,0.02); }
.bg-white-05 { background: rgba(255,255,255,0.05); }

.custom-scrollbar::-webkit-scrollbar { width: 4px; }
.custom-scrollbar::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.3); border-radius: 2px; }
</style>
