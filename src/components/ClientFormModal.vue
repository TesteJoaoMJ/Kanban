<template>
  <v-dialog
    :model-value="show"
    @update:model-value="$emit('close')"
    max-width="1100px"
    persistent
    transition="dialog-bottom-transition"
    :content-class="themeStore.currentMode === 'light' ? '' : 'glass-modal-content'"
  >
    <v-card class="fill-height d-flex flex-row overflow-hidden rounded-xl" :class="themeClass">

      <div class="sidebar-info d-flex flex-column pa-6 border-r" :class="sidebarClass" style="width: 280px; min-width: 280px;">
        <div class="d-flex align-center gap-3 mb-6">
           <div class="icon-box-md rounded-lg elevation-1" :class="iconBoxClass">
              <v-icon size="24">mdi-account-plus</v-icon>
           </div>
           <div>
              <div class="text-[10px] font-weight-bold uppercase opacity-60 letter-spacing-1">Cadastro</div>
              <h2 class="text-h6 font-weight-black lh-1" :class="textPrimaryClass">Novo Cliente</h2>
           </div>
        </div>

        <div class="info-card pa-4 rounded-lg border-thin mb-4" :class="infoCardClass">
           <div class="d-flex align-center gap-2 mb-2 text-info">
              <v-icon size="18">mdi-magic-staff</v-icon>
              <span class="font-weight-bold text-caption">Dica Automática</span>
           </div>
           <p class="text-caption opacity-70 lh-14">
              Ao digitar o <strong>CEP</strong> ou <strong>CNPJ</strong>, o sistema buscará os dados automaticamente para agilizar o cadastro.
           </p>
        </div>
      </div>

      <div class="main-content flex-grow-1 d-flex flex-column" :class="mainContentClass">

        <div class="px-8 py-5 border-b d-flex justify-space-between align-center" :class="headerBorderClass">
            <h3 class="text-subtitle-1 font-weight-bold" :class="textPrimaryClass">Dados Cadastrais</h3>
            <v-btn icon size="small" variant="text" :color="themeStore.currentMode === 'light' ? 'grey-darken-1' : 'white'" @click="$emit('close')">
                <v-icon>mdi-close</v-icon>
            </v-btn>
        </div>

        <div class="flex-grow-1 overflow-y-auto custom-scrollbar pa-8">
           <v-form ref="clientForm" @submit.prevent="submit">

              <v-row dense class="mb-2">
                 <v-col cols="12" md="3">
                    <v-select
                       v-model="client.tipo_pessoa"
                       :items="tiposPessoa"
                       item-title="text"
                       item-value="value"
                       label="Tipo"
                       variant="outlined"
                       density="comfortable"
                       :bg-color="inputBgColor"
                       :color="inputFocusColor"
                       :rules="[rules.required]"
                    ></v-select>
                 </v-col>
                 <v-col cols="12" md="5">
                    <v-text-field
                       v-model="client.nome"
                       label="Nome Completo / Razão Social"
                       variant="outlined"
                       density="comfortable"
                       :bg-color="inputBgColor"
                       :color="inputFocusColor"
                       :rules="[rules.required]"
                    ></v-text-field>
                 </v-col>
                 <v-col cols="12" md="4">
                    <v-text-field
                       v-model="client.cpf_cnpj"
                       :label="client.tipo_pessoa === 'PJ' ? 'CNPJ' : 'CPF'"
                       variant="outlined"
                       density="comfortable"
                       :bg-color="inputBgColor"
                       :color="inputFocusColor"
                       :append-inner-icon="client.tipo_pessoa === 'PJ' ? 'mdi-magnify' : ''"
                       @click:append-inner="buscarCnpj"
                       :loading="isSearchingCnpj"
                       v-maska:[mascaraDoc]
                    ></v-text-field>
                 </v-col>
              </v-row>

              <v-row dense class="mb-4">
                 <v-col cols="12" md="6">
                    <v-text-field
                       v-model="client.email"
                       label="E-mail Principal"
                       prepend-inner-icon="mdi-email-outline"
                       variant="outlined"
                       density="comfortable"
                       :bg-color="inputBgColor"
                       :color="inputFocusColor"
                    ></v-text-field>
                 </v-col>
                 <v-col cols="12" md="3">
                    <v-text-field
                       v-model="client.celular"
                       label="Celular / WhatsApp"
                       variant="outlined"
                       density="comfortable"
                       :bg-color="inputBgColor"
                       :color="inputFocusColor"
                       v-maska="'(##) #####-####'"
                    ></v-text-field>
                 </v-col>
                 <v-col cols="12" md="3">
                    <v-text-field
                       v-model="client.telefone"
                       label="Telefone Fixo"
                       variant="outlined"
                       density="comfortable"
                       :bg-color="inputBgColor"
                       :color="inputFocusColor"
                       v-maska="'(##) ####-####'"
                    ></v-text-field>
                 </v-col>
              </v-row>

              <div class="text-caption font-weight-bold uppercase opacity-50 mb-3" :class="textPrimaryClass">Endereço</div>

              <v-row dense>
                 <v-col cols="12" md="3">
                    <v-text-field
                       v-model="client.endereco.cep"
                       label="CEP"
                       variant="outlined"
                       density="comfortable"
                       :bg-color="inputBgColor"
                       :color="inputFocusColor"
                       @blur="buscarCep"
                       append-inner-icon="mdi-map-marker-radius"
                       v-maska="'#####-###'"
                       :loading="isSearchingCep"
                    ></v-text-field>
                 </v-col>
                 <v-col cols="12" md="6">
                    <v-text-field
                       v-model="client.endereco.logradouro"
                       label="Rua / Logradouro"
                       variant="outlined"
                       density="comfortable"
                       :bg-color="inputBgColor"
                       :color="inputFocusColor"
                    ></v-text-field>
                 </v-col>
                 <v-col cols="12" md="3">
                    <v-text-field
                       v-model="client.endereco.numero"
                       label="Número"
                       variant="outlined"
                       density="comfortable"
                       :bg-color="inputBgColor"
                       :color="inputFocusColor"
                    ></v-text-field>
                 </v-col>
                 <v-col cols="12" md="4">
                    <v-text-field
                       v-model="client.endereco.bairro"
                       label="Bairro"
                       variant="outlined"
                       density="comfortable"
                       :bg-color="inputBgColor"
                       :color="inputFocusColor"
                    ></v-text-field>
                 </v-col>
                 <v-col cols="12" md="4">
                    <v-text-field
                       v-model="client.endereco.nome_cidade"
                       label="Cidade / Estado"
                       variant="outlined"
                       density="comfortable"
                       readonly
                       :bg-color="inputBgColor"
                       :color="inputFocusColor"
                    ></v-text-field>
                 </v-col>
                 <v-col cols="12" md="4">
                    <v-text-field
                       v-model="client.endereco.complemento"
                       label="Complemento"
                       variant="outlined"
                       density="comfortable"
                       :bg-color="inputBgColor"
                       :color="inputFocusColor"
                    ></v-text-field>
                 </v-col>
              </v-row>

              <v-alert v-if="errorMessage" type="error" variant="tonal" density="compact" class="mt-4 border-dashed" closable @click:close="errorMessage = null">
                 {{ errorMessage }}
              </v-alert>

           </v-form>
        </div>

        <div class="pa-6 border-t" :class="[headerBorderClass, themeStore.currentMode === 'light' ? 'bg-grey-lighten-5' : '']">
           <v-btn
              block
              size="large"
              color="primary"
              variant="flat"
              class="font-weight-black rounded-lg shadow-glow-primary text-uppercase letter-spacing-1"
              :loading="isSubmitting"
              @click="submit"
           >
              <v-icon start>mdi-content-save</v-icon> Salvar Cliente
           </v-btn>
        </div>

      </div>
    </v-card>
  </v-dialog>
</template>

<script setup lang="ts">
import { ref, reactive, computed } from 'vue';
import { useUserStore } from '@/stores/user';
import { useThemeStore } from '@/stores/theme';
import { MaskInput } from 'maska';
import { supabase } from '@/api/supabase';

const vMaska = {
  mounted(el: any, binding: any) {
    const value = binding.value;
    const arg = binding.arg;
    const options = { mask: arg || value };
    new MaskInput(el, options);
  },
  updated(el: any, binding: any) {
    const value = binding.value;
    const arg = binding.arg;
    const options = { mask: arg || value };
    new MaskInput(el, options);
  }
};

const props = defineProps({ show: Boolean });
const emit = defineEmits(['close', 'client-created']);

const userStore = useUserStore();
const themeStore = useThemeStore();
const clientForm = ref<any>(null);
const isSubmitting = ref(false);
const isSearchingCnpj = ref(false);
const isSearchingCep = ref(false);
const errorMessage = ref<string | null>(null);

const themeClass = computed(() => themeStore.currentMode === 'light' ? 'bg-white text-grey-darken-3' : 'bg-glass-dark text-white');
const sidebarClass = computed(() => themeStore.currentMode === 'light' ? 'bg-grey-lighten-4 border-grey-lighten-2' : 'bg-glass-sidebar border-white-10');
const mainContentClass = computed(() => themeStore.currentMode === 'light' ? 'bg-white' : 'bg-pattern');
const textPrimaryClass = computed(() => themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white');
const iconBoxClass = computed(() => themeStore.currentMode === 'light' ? 'bg-white text-primary border border-grey-lighten-2' : 'bg-surface-light text-primary');
const infoCardClass = computed(() => themeStore.currentMode === 'light' ? 'bg-white border-grey-lighten-2' : 'bg-surface-light border-white-10');
const inputBgColor = computed(() => themeStore.currentMode === 'light' ? 'white' : 'rgba(0,0,0,0.2)');
const inputFocusColor = computed(() => 'primary');
const headerBorderClass = computed(() => themeStore.currentMode === 'light' ? 'border-grey-lighten-2' : 'border-white-10');

const createDefaultClient = () => ({
  nome: '', tipo_pessoa: 'PF' as 'PF'|'PJ'|'ES', cpf_cnpj: '', email: '', telefone: '', celular: '',
  endereco: { cep: '', logradouro: '', numero: '', complemento: '', bairro: '', nome_cidade: '', estado: '' }
});
const client = ref(createDefaultClient());

const tiposPessoa = [{ text: 'Pessoa Física', value: 'PF' }, { text: 'Pessoa Jurídica', value: 'PJ' }, { text: 'Estrangeiro', value: 'ES' }];
const rules = { required: (v: any) => !!v || 'Campo obrigatório.' };
const mascaraDoc = computed(() => client.value.tipo_pessoa === 'PJ' ? '##.###.###/####-##' : '###.###.###-##');

const resetForm = () => { client.value = createDefaultClient(); errorMessage.value = null; };
const closeDialog = () => { resetForm(); emit('close'); };

const buscarCep = async () => {
    const cep = client.value.endereco.cep?.replace(/\D/g, '');
    if (!cep || cep.length !== 8) return;

    isSearchingCep.value = true;
    try {
        const res = await fetch(`https://viacep.com.br/ws/${cep}/json/`);
        const data = await res.json();
        if (data.erro) throw new Error('CEP inválido.');
        client.value.endereco.logradouro = data.logradouro;
        client.value.endereco.bairro = data.bairro;
        client.value.endereco.nome_cidade = `${data.localidade} / ${data.uf}`;
        client.value.endereco.estado = data.uf;
    } catch (e: any) { errorMessage.value = e.message; }
    finally { isSearchingCep.value = false; }
};

const buscarCnpj = async () => {
    const cnpj = client.value.cpf_cnpj?.replace(/\D/g, '');
    if(!cnpj || cnpj.length !== 14) { errorMessage.value = 'CNPJ inválido'; return; }
    isSearchingCnpj.value = true; errorMessage.value = null;
    try {
        const res = await fetch(`https://brasilapi.com.br/api/cnpj/v1/${cnpj}`);
        if(!res.ok) throw new Error('CNPJ não encontrado.');
        const data = await res.json();
        client.value.nome = data.razao_social;
        client.value.email = data.email;
        client.value.telefone = data.ddd_telefone_1;
        client.value.endereco.cep = data.cep;
        client.value.endereco.logradouro = data.logradouro;
        client.value.endereco.numero = data.numero;
        client.value.endereco.complemento = data.complemento;
        client.value.endereco.bairro = data.bairro;
        if(client.value.endereco.cep) await buscarCep();
    } catch(e: any) { errorMessage.value = e.message; }
    finally { isSearchingCnpj.value = false; }
};

const submit = async () => {
    const { valid } = await clientForm.value.validate();
    if(!valid) return;
    isSubmitting.value = true; errorMessage.value = null;
    try {
        const dbPayload = {
            nome: client.value.nome,
            nome_fantasia: client.value.nome,
            razao_social: client.value.nome,
            cpf: client.value.tipo_pessoa === 'PF' ? client.value.cpf_cnpj : null,
            cnpj: client.value.tipo_pessoa === 'PJ' ? client.value.cpf_cnpj : null,
            email: client.value.email,
            telefone: client.value.telefone || client.value.celular,
            cidade: client.value.endereco.nome_cidade?.split('/')[0]?.trim(),
            estado: client.value.endereco.estado,
            situacao: 'Ativo',
            created_at: new Date().toISOString()
        };

        const { data: newClient, error } = await supabase
            .from('customers_mj')
            .insert(dbPayload)
            .select()
            .single();

        if (error) throw error;

        emit('client-created', newClient);
        closeDialog();
    } catch(e: any) {
        errorMessage.value = e.message;
    }
    finally { isSubmitting.value = false; }
};
</script>

<style scoped lang="scss">
.glass-modal-content { backdrop-filter: blur(20px); }
.bg-glass-dark { background: #121214; }
.bg-glass-sidebar { background: rgba(255, 255, 255, 0.03); }
.bg-surface-light { background: rgba(255, 255, 255, 0.05); }
.border-white-10 { border-color: rgba(255, 255, 255, 0.1) !important; }
.border-grey-lighten-2 { border-color: #E0E0E0 !important; }
.icon-box-md { width: 48px; height: 48px; display: flex; align-items: center; justify-content: center; }
.shadow-glow-primary { box-shadow: 0 0 20px rgba(var(--v-theme-primary), 0.3); }
.custom-scrollbar::-webkit-scrollbar { width: 6px; }
.custom-scrollbar::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.3); border-radius: 3px; }
.bg-pattern { background-image: radial-gradient(rgba(128,128,128,0.1) 1px, transparent 1px); background-size: 20px 20px; }
.lh-1 { line-height: 1; } .lh-14 { line-height: 1.4; }
</style>
