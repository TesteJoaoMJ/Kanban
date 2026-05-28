<template>
  <v-dialog :model-value="show" @update:model-value="$emit('close')" max-width="950px" height="700px" persistent>
    <v-card class="rounded-xl overflow-hidden d-flex flex-column" :class="themeClasses.card">

      <div class="px-6 py-4 border-b d-flex justify-space-between align-center flex-shrink-0" :class="themeClasses.headerBg">
         <div class="d-flex align-center gap-3">
            <div class="icon-box-sm rounded-lg d-flex align-center justify-center elevation-2" :class="isLight ? 'bg-indigo-darken-3 text-white' : 'bg-gradient-indigo shadow-glow-indigo'">
               <v-icon size="20">mdi-domain</v-icon>
            </div>
            <div>
               <h3 class="text-subtitle-1 font-weight-black lh-1" :class="themeClasses.textPrimary">{{ isCreating ? 'Nova Empresa' : 'Editar Empresa' }}</h3>
               <div class="text-caption" :class="themeClasses.textSecondary">Configurações fiscais e cadastrais</div>
            </div>
         </div>
         <v-btn icon="mdi-close" variant="text" size="small" :color="themeClasses.iconColor" @click="$emit('close')"></v-btn>
      </div>

      <div class="d-flex flex-grow-1 overflow-hidden">

         <div class="border-r d-flex flex-column overflow-y-auto custom-scrollbar" style="width: 240px;" :class="themeClasses.sidebarBg">

            <div class="pa-6 text-center border-b" :class="themeClasses.borderColor">
                <v-avatar size="80" class="mb-3 cursor-pointer hover-opacity relative overflow-hidden border" :class="themeClasses.avatarBg" @click="triggerLogoUpload">
                    <v-img v-if="form.logo_url" :src="form.logo_url" cover></v-img>
                    <v-icon v-else size="32" :color="themeClasses.iconMuted">mdi-camera-plus</v-icon>
                    <div class="overlay-upload d-flex align-center justify-center">
                        <span class="text-[9px] text-white font-weight-bold">ALTERAR</span>
                    </div>
                </v-avatar>
                <input type="file" ref="logoInput" class="d-none" accept="image/*" @change="handleLogoUpload">
                <div class="text-caption font-weight-bold text-truncate" :class="themeClasses.textPrimary">{{ form.trade_name || 'Nome Fantasia' }}</div>
                <div class="text-[10px]" :class="themeClasses.textSecondary">{{ formatCNPJ(form.cnpj) || 'CNPJ...' }}</div>
            </div>

            <v-tabs v-model="tab" direction="vertical" :color="isLight ? 'indigo-darken-3' : 'white'" class="flex-grow-1">
                <v-tab value="dados" class="justify-start text-caption font-weight-bold px-6" height="48"><v-icon start size="18">mdi-card-account-details</v-icon> Cadastrais</v-tab>
                <v-tab value="endereco" class="justify-start text-caption font-weight-bold px-6" height="48"><v-icon start size="18">mdi-map-marker</v-icon> Endereço</v-tab>
                <v-tab value="fiscal" class="justify-start text-caption font-weight-bold px-6" height="48"><v-icon start size="18">mdi-file-certificate</v-icon> Fiscal & NFe</v-tab>
                <v-tab value="socios" class="justify-start text-caption font-weight-bold px-6" height="48"><v-icon start size="18">mdi-account-group</v-icon> Sócios</v-tab>
                <v-tab value="lojas" class="justify-start text-caption font-weight-bold px-6" height="48"><v-icon start size="18">mdi-store</v-icon> Lojas</v-tab>
            </v-tabs>
         </div>

         <div class="flex-grow-1 overflow-y-auto custom-scrollbar pa-6" :class="themeClasses.mainBg">
            <v-window v-model="tab" class="fill-height">
                <v-window-item value="dados">
                    <div class="section-title mb-4 text-caption font-weight-bold text-uppercase opacity-60" :class="themeClasses.textLabel">Identificação</div>
                    <v-row dense>
                        <v-col cols="12"><v-text-field v-model="form.name" label="Razão Social" variant="outlined" density="compact" :color="inputColor" :bg-color="inputBg"></v-text-field></v-col>
                        <v-col cols="12"><v-text-field v-model="form.trade_name" label="Nome Fantasia" variant="outlined" density="compact" :color="inputColor" :bg-color="inputBg"></v-text-field></v-col>
                        <v-col cols="6"><v-text-field v-model="form.cnpj" label="CNPJ" v-maska="'##.###.###/####-##'" variant="outlined" density="compact" :color="inputColor" :bg-color="inputBg"></v-text-field></v-col>
                        <v-col cols="6"><v-text-field v-model="form.ie" label="Inscrição Estadual" variant="outlined" density="compact" :color="inputColor" :bg-color="inputBg"></v-text-field></v-col>
                        <v-col cols="12"><v-select v-model="form.crt" :items="crtOptions" item-title="label" item-value="value" label="Regime Tributário (CRT)" variant="outlined" density="compact" :color="inputColor" :bg-color="inputBg"></v-select></v-col>
                    </v-row>
                </v-window-item>

                <v-window-item value="endereco">
                    <div class="section-title mb-4 text-caption font-weight-bold text-uppercase opacity-60" :class="themeClasses.textLabel">Localização</div>
                    <v-row dense>
                        <v-col cols="4"><v-text-field v-model="form.address.cep" label="CEP" v-maska="'#####-###'" variant="outlined" density="compact" :color="inputColor" :bg-color="inputBg" @blur="buscaCep" append-inner-icon="mdi-magnify"></v-text-field></v-col>
                        <v-col cols="8"><v-text-field v-model="form.address.logradouro" label="Logradouro" variant="outlined" density="compact" :color="inputColor" :bg-color="inputBg"></v-text-field></v-col>
                        <v-col cols="4"><v-text-field v-model="form.address.numero" label="Número" variant="outlined" density="compact" :color="inputColor" :bg-color="inputBg"></v-text-field></v-col>
                        <v-col cols="8"><v-text-field v-model="form.address.bairro" label="Bairro" variant="outlined" density="compact" :color="inputColor" :bg-color="inputBg"></v-text-field></v-col>
                        <v-col cols="8"><v-text-field v-model="form.address.municipio" label="Município" variant="outlined" density="compact" :color="inputColor" :bg-color="inputBg"></v-text-field></v-col>
                        <v-col cols="4"><v-text-field v-model="form.address.uf" label="UF" variant="outlined" density="compact" :color="inputColor" :bg-color="inputBg"></v-text-field></v-col>
                        <v-col cols="12"><v-text-field v-model="form.address.cod_municipio" label="Código IBGE (Obrigatório NFe)" variant="outlined" density="compact" :color="inputColor" :bg-color="inputBg"></v-text-field></v-col>
                    </v-row>
                </v-window-item>

                <v-window-item value="fiscal">
                    <div class="pa-4 rounded-lg mb-6 border" :class="isLight ? 'bg-indigo-lighten-5 border-indigo-lighten-4' : 'bg-indigo-darken-4 border-indigo-lighten-1'">
                        <div class="d-flex align-center gap-2 mb-3">
                            <v-icon :color="isLight ? 'indigo-darken-3' : 'white'">mdi-cog-sync</v-icon>
                            <span class="text-caption font-weight-bold text-uppercase" :class="isLight ? 'text-indigo-darken-4' : 'text-white'">Parâmetros NFe</span>
                        </div>
                        <v-row dense>
                            <v-col cols="12" md="4"><v-select v-model="form.environment" :items="['homologacao', 'producao']" label="Ambiente" variant="outlined" density="compact" bg-color="white" color="indigo"></v-select></v-col>
                            <v-col cols="6" md="4"><v-text-field v-model="form.nfe_series" label="Série" type="number" variant="outlined" density="compact" bg-color="white" color="indigo"></v-text-field></v-col>
                            <v-col cols="6" md="4"><v-text-field v-model="form.nfe_next_number" label="Próximo Nº" type="number" variant="outlined" density="compact" bg-color="white" color="indigo"></v-text-field></v-col>
                        </v-row>
                    </div>

                    <div class="pa-4 rounded-lg border border-dashed" :class="themeClasses.well">
                        <div class="d-flex justify-space-between align-center mb-4">
                            <div>
                                <div class="text-caption font-weight-bold text-uppercase" :class="themeClasses.textLabel">Certificado Digital A1</div>
                                <div class="text-[10px]" :class="themeClasses.textSecondary">{{ form.certificate_validity ? `Válido até: ${formatDate(form.certificate_validity)}` : 'Não instalado' }}</div>
                            </div>
                            <v-chip v-if="form.certificate_validity" color="success" size="x-small" label class="font-weight-bold">ATIVO</v-chip>
                        </div>
                        <v-file-input v-model="certFile" label="Selecionar Arquivo .PFX" variant="outlined" density="compact" prepend-icon="mdi-file-certificate" accept=".pfx,.p12" :bg-color="inputBg" :color="inputColor"></v-file-input>
                        <v-text-field v-if="certFile" v-model="certPassword" label="Senha do Certificado" type="password" variant="outlined" density="compact" :bg-color="inputBg" :color="inputColor" class="mt-2"></v-text-field>
                        <v-btn v-if="certFile" :color="isLight ? 'indigo-darken-3' : 'primary'" block size="small" class="mt-3 font-weight-bold" @click="uploadCertificate" :loading="uploadingCert">
                            <v-icon start>mdi-upload</v-icon> Instalar Certificado
                        </v-btn>
                    </div>
                </v-window-item>

                <v-window-item value="socios">
                    <div class="d-flex justify-space-between align-center mb-4">
                        <span class="text-caption font-weight-bold text-uppercase opacity-60" :class="themeClasses.textLabel">Quadro Societário</span>
                        <v-btn size="x-small" variant="tonal" color="primary" prepend-icon="mdi-plus" @click="addPartner">Adicionar</v-btn>
                    </div>
                    <v-table density="compact" :class="themeClasses.tableClass">
                        <thead><tr :class="themeClasses.tableHeader"><th>Nome</th><th>CPF</th><th>Cargo</th><th class="text-right"></th></tr></thead>
                        <tbody>
                            <tr v-for="(partner, idx) in form.partners" :key="idx">
                                <td><input v-model="partner.name" class="clean-input-table w-100" placeholder="Nome Completo" :class="themeClasses.textPrimary"></td>
                                <td><input v-model="partner.cpf" v-maska="'###.###.###-##'" class="clean-input-table w-100" placeholder="CPF" :class="themeClasses.textPrimary"></td>
                                <td><input v-model="partner.role" class="clean-input-table w-100" placeholder="Cargo" :class="themeClasses.textPrimary"></td>
                                <td class="text-right"><v-btn icon="mdi-delete" variant="text" size="x-small" color="error" @click="removePartner(idx)"></v-btn></td>
                            </tr>
                            <tr v-if="form.partners.length === 0"><td colspan="4" class="text-center text-caption py-4 opacity-50">Nenhum sócio registrado.</td></tr>
                        </tbody>
                    </v-table>
                </v-window-item>

                <v-window-item value="lojas">
                    <div class="text-caption font-weight-bold text-uppercase opacity-60 mb-4" :class="themeClasses.textLabel">Lojas Vinculadas</div>
                    <div v-if="linkedStores.length > 0" class="d-flex flex-column gap-2">
                        <div v-for="store in linkedStores" :key="store.id" class="d-flex align-center justify-space-between pa-3 rounded border" :class="themeClasses.well">
                            <div class="d-flex align-center gap-3">
                                <v-icon size="20" color="purple">mdi-store</v-icon>
                                <div>
                                    <div class="text-caption font-weight-bold" :class="themeClasses.textPrimary">{{ store.name }}</div>
                                    <div class="text-[10px]" :class="themeClasses.textSecondary">{{ store.address || 'Endereço não informado' }}</div>
                                </div>
                            </div>
                            <v-chip :color="store.active ? 'success' : 'grey'" size="x-small" label>{{ store.active ? 'Ativa' : 'Inativa' }}</v-chip>
                        </div>
                    </div>
                    <div v-else class="text-center py-8 border border-dashed rounded opacity-50">
                        <v-icon size="32" :color="themeClasses.iconMuted">mdi-store-off</v-icon>
                        <p class="text-caption mt-2">Nenhuma loja vinculada.</p>
                    </div>
                </v-window-item>
            </v-window>
         </div>
      </div>

      <div class="pa-4 border-t d-flex justify-end gap-3 flex-shrink-0" :class="themeClasses.footerBg">
          <v-btn variant="text" :color="themeClasses.textSecondary" @click="$emit('close')">Cancelar</v-btn>
          <v-btn :color="isLight ? 'indigo-darken-3' : 'primary'" variant="flat" class="font-weight-bold px-6" :loading="saving" @click="saveCompany">
              Salvar Alterações
          </v-btn>
      </div>
    </v-card>
  </v-dialog>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted, watch, computed } from 'vue';
import { supabase } from '@/api/supabase';
import axios from 'axios';
import { vMaska } from 'maska/vue';
import { useThemeStore } from '@/stores/theme';

const props = defineProps<{ show: boolean }>();
const emit = defineEmits(['close']);
const themeStore = useThemeStore();

const API_URL = 'https://sefaz-proxy-dujl.onrender.com';

const companies = ref<any[]>([]);
const linkedStores = ref<any[]>([]);
const saving = ref(false);
const uploadingCert = ref(false);
const isCreating = ref(false);
const tab = ref('dados');
const logoInput = ref<HTMLInputElement | null>(null);
const certFile = ref<File[] | null>(null);
const certPassword = ref('');

const crtOptions = [{ label: '1 - Simples Nacional', value: 1 }, { label: '3 - Regime Normal', value: 3 }];

// --- THEME ---
const isLight = computed(() => themeStore.currentMode === 'light');
const inputBg = computed(() => isLight.value ? 'white' : 'rgba(255,255,255,0.05)');
const inputColor = computed(() => isLight.value ? 'indigo' : 'white');

const themeClasses = computed(() => ({
    card: isLight.value ? 'bg-white' : 'glass-modal border-white-10',
    headerBg: isLight.value ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-glass-header border-white-10',
    sidebarBg: isLight.value ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-glass-surface border-white-05',
    mainBg: isLight.value ? 'bg-white' : 'bg-transparent',
    footerBg: isLight.value ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-glass-header border-white-10',
    well: isLight.value ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'glass-well border-white-05',
    textPrimary: isLight.value ? 'text-grey-darken-4' : 'text-white',
    textSecondary: isLight.value ? 'text-grey-darken-1' : 'text-white-50',
    textLabel: isLight.value ? 'text-grey-darken-2' : 'text-white-30',
    iconColor: isLight.value ? 'grey-darken-2' : 'white',
    iconMuted: isLight.value ? 'grey-lighten-2' : 'white-10',
    borderColor: isLight.value ? 'border-grey-lighten-2' : 'border-white-10',
    avatarBg: isLight.value ? 'bg-white border-grey-lighten-2' : 'bg-white-05 border-white-10',
    tableClass: isLight.value ? 'bg-transparent' : 'bg-transparent text-white',
    tableHeader: isLight.value ? 'bg-grey-lighten-4' : 'bg-white-05'
}));

// --- FORM STATE ---
const defaultForm = {
    id: null, name: '', trade_name: '', cnpj: '', ie: '', crt: 1,
    address: { logradouro: '', numero: '', bairro: '', cep: '', uf: '', municipio: '', cod_municipio: '' },
    environment: 'homologacao', nfe_series: 1, nfe_next_number: 1, certificate_validity: null,
    logo_url: null, partners: [] as any[]
};
const form = reactive<any>(JSON.parse(JSON.stringify(defaultForm)));

// --- ACTIONS ---
const selectCompany = (comp: any) => {
    isCreating.value = false;
    Object.assign(form, JSON.parse(JSON.stringify(defaultForm)));
    Object.assign(form, JSON.parse(JSON.stringify(comp)));
    if(!form.address) form.address = { ...defaultForm.address };
    if(!form.partners) form.partners = [];
    loadLinkedStores(comp.id);
    tab.value = 'dados';
};

const startNew = () => {
    isCreating.value = true;
    Object.assign(form, JSON.parse(JSON.stringify(defaultForm)));
    linkedStores.value = [];
    tab.value = 'dados';
};

const loadLinkedStores = async (id: string) => {
    const { data } = await supabase.from('stores').select('*').eq('company_id', id);
    linkedStores.value = data || [];
};

const saveCompany = async () => {
    saving.value = true;
    try {
        const payload = {
            name: form.name, trade_name: form.trade_name, cnpj: form.cnpj.replace(/\D/g, ''),
            ie: form.ie, crt: Number(form.crt), address: form.address, environment: form.environment,
            nfe_series: Number(form.nfe_series), nfe_next_number: Number(form.nfe_next_number),
            logo_url: form.logo_url, partners: form.partners
        };
        if (form.id) await supabase.from('companies').update(payload).eq('id', form.id);
        else await supabase.from('companies').insert(payload);
        emit('close');
        alert('Salvo com sucesso!');
    } catch (e) { alert('Erro ao salvar.'); console.error(e); }
    finally { saving.value = false; }
};

const triggerLogoUpload = () => logoInput.value?.click();
const handleLogoUpload = async (event: any) => {
    const file = event.target.files[0];
    if (!file) return;
    const fileName = `logos/${Date.now()}_${file.name}`;
    const { error } = await supabase.storage.from('media').upload(fileName, file);
    if (error) return alert('Erro upload');
    const { data } = supabase.storage.from('media').getPublicUrl(fileName);
    form.logo_url = data.publicUrl;
};

const uploadCertificate = async () => {
    if (!certFile.value || !certPassword.value) return alert('Selecione arquivo e senha.');
    uploadingCert.value = true;
    try {
        const file = Array.isArray(certFile.value) ? certFile.value[0] : certFile.value;
        const reader = new FileReader();
        reader.readAsDataURL(file as Blob);
        reader.onload = async () => {
            const base64 = (reader.result as string).split(',')[1];
            await axios.put(`${API_URL}/api/empresas/${form.cnpj.replace(/\D/g, '')}/certificado`, {
                certificado_base64: base64, password: certPassword.value
            });
            const validity = new Date(); validity.setFullYear(validity.getFullYear() + 1);
            form.certificate_validity = validity.toISOString();
            await supabase.from('companies').update({ certificate_validity: form.certificate_validity }).eq('id', form.id);
            alert('Certificado instalado!');
            certFile.value = null; certPassword.value = '';
        };
    } catch (e: any) { alert('Erro: ' + (e.response?.data?.error || e.message)); }
    finally { uploadingCert.value = false; }
};

const buscaCep = async () => {
    const cep = form.address.cep?.replace(/\D/g, '');
    if (cep?.length === 8) {
        try {
            const res = await axios.get(`https://viacep.com.br/ws/${cep}/json/`);
            if (!res.data.erro) {
                form.address.logradouro = res.data.logradouro; form.address.bairro = res.data.bairro;
                form.address.municipio = res.data.localidade; form.address.uf = res.data.uf; form.address.cod_municipio = res.data.ibge;
            }
        } catch {}
    }
};

const addPartner = () => form.partners.push({ name: '', cpf: '', role: 'Sócio' });
const removePartner = (idx: number) => form.partners.splice(idx, 1);
const formatCNPJ = (v: string) => v?.replace(/^(\d{2})(\d{3})(\d{3})(\d{4})(\d{2})/, "$1.$2.$3/$4-$5");
const formatDate = (d: string) => d ? new Date(d).toLocaleDateString('pt-BR') : '-';

defineExpose({ selectCompany, startNew });
</script>

<style scoped lang="scss">
.glass-modal { background: rgba(30, 30, 35, 0.95) !important; border: 1px solid rgba(255,255,255,0.1); border-radius: 16px; backdrop-filter: blur(20px); }
.glass-well { background: rgba(255,255,255,0.02); }
.bg-glass-header { background: rgba(255, 255, 255, 0.03); }
.bg-glass-surface { background: #121214; }
.bg-gradient-indigo { background: linear-gradient(135deg, #303f9f, #1a237e); }
.shadow-glow-indigo { box-shadow: 0 4px 20px rgba(48, 63, 159, 0.4); }
.border-white-10 { border-color: rgba(255,255,255,0.1) !important; }
.border-white-05 { border-color: rgba(255,255,255,0.05) !important; }
.text-white-50 { color: rgba(255,255,255,0.5); }
.text-white-30 { color: rgba(255,255,255,0.3); }
.bg-white-05 { background: rgba(255,255,255,0.05); }
.icon-box-sm { width: 36px; height: 36px; }
.lh-1 { line-height: 1.2; }
.custom-scrollbar::-webkit-scrollbar { width: 4px; }
.custom-scrollbar::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.2); border-radius: 2px; }
.hover-opacity:hover .overlay-upload { opacity: 1; }
.overlay-upload { position: absolute; bottom: 0; left: 0; width: 100%; background: rgba(0,0,0,0.6); padding: 4px; opacity: 0; transition: opacity 0.2s; }
.clean-input-table { background: transparent; border: none; outline: none; padding: 4px 0; font-size: 0.85rem; border-bottom: 1px solid transparent; }
.clean-input-table:focus { border-bottom: 1px solid currentColor; }
</style>
