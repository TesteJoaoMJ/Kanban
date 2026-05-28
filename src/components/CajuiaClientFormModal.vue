<template>
  <v-dialog
    :model-value="show"
    @update:model-value="close"
    max-width="800px"
    persistent
    transition="dialog-bottom-transition"
    scrollable
  >
    <v-card class="d-flex flex-column overflow-hidden rounded-xl" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-surface-variant'">

      <div class="px-6 py-5 flex-shrink-0 border-b d-flex align-center justify-space-between" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-surface border-white-05'">
        <div class="d-flex align-center">
          <div class="icon-box bg-gradient-primary mr-4 elevation-3 text-white rounded-lg d-flex align-center justify-center" style="width: 40px; height: 40px;">
            <v-icon size="24">mdi-account-plus</v-icon>
          </div>
          <div>
            <h2 class="text-h6 font-weight-bold text-high-emphasis">Novo Cliente</h2>
            <div class="text-caption text-medium-emphasis">Cadastro para Cajuia Store</div>
          </div>
        </div>
        <v-btn icon variant="text" color="medium-emphasis" @click="close">
          <v-icon>mdi-close</v-icon>
        </v-btn>
      </div>

      <v-card-text class="pa-0 flex-grow-1 overflow-y-auto custom-scrollbar bg-background">
        <v-form ref="form" v-model="valid" @submit.prevent="submitForm">
          <div class="pa-6">

            <div class="d-flex justify-center mb-8">
              <v-btn-toggle
                v-model="formData.tipoPessoa"
                color="primary"
                class="rounded-pill border"
                :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-surface border-white-10'"
                mandatory
                density="default"
                @update:model-value="resetDocumento"
              >
                <v-btn value="Fisica" class="text-none font-weight-bold px-8 rounded-s-pill" prepend-icon="mdi-account">Pessoa Física</v-btn>
                <v-btn value="Juridica" class="text-none font-weight-bold px-8 rounded-e-pill" prepend-icon="mdi-domain">Pessoa Jurídica</v-btn>
              </v-btn-toggle>
            </div>

            <v-row dense>
              <v-col cols="12" md="5">
                  <v-text-field
                    v-model="formData.documento"
                    :label="formData.tipoPessoa === 'Fisica' ? 'CPF' : 'CNPJ'"
                    placeholder="Apenas números"
                    variant="outlined"
                    density="comfortable"
                    bg-color="surface"
                    :rules="[rules.required, rules.documento]"
                    @input="formatDocumento"
                    :maxlength="formData.tipoPessoa === 'Fisica' ? 14 : 18"
                    :loading="loadingCnpj"
                    :append-inner-icon="getCnpjIcon"
                    @click:append-inner="fetchCnpjData"
                  ></v-text-field>
              </v-col>

              <v-col cols="12" md="7">
                  <v-text-field
                    v-model="formData.nome"
                    :label="formData.tipoPessoa === 'Fisica' ? 'Nome Completo' : 'Razão Social'"
                    placeholder="Digite o nome..."
                    variant="outlined"
                    density="comfortable"
                    bg-color="surface"
                    :rules="[rules.required]"
                  ></v-text-field>
              </v-col>

              <v-col cols="12" md="6">
                  <v-text-field
                    v-model="formData.email"
                    label="E-mail"
                    variant="outlined"
                    density="comfortable"
                    bg-color="surface"
                    prepend-inner-icon="mdi-email-outline"
                    :rules="[rules.email]"
                  ></v-text-field>
              </v-col>

              <v-col cols="12" md="6">
                  <v-text-field
                    v-model="formData.telefone"
                    label="WhatsApp / Telefone"
                    variant="outlined"
                    density="comfortable"
                    bg-color="surface"
                    prepend-inner-icon="mdi-whatsapp"
                    @input="formatTelefone"
                    maxlength="15"
                    :rules="[rules.required]"
                  ></v-text-field>
              </v-col>

              <v-col cols="12" class="mt-4">
                 <div class="text-caption font-weight-bold text-uppercase text-medium-emphasis mb-2">Endereço</div>
                 <v-card variant="outlined" class="pa-4 border-dashed bg-surface-light">
                     <v-row dense>
                        <v-col cols="12" sm="4">
                          <v-text-field
                            v-model="formData.endereco.cep"
                            label="CEP"
                            variant="outlined"
                            density="compact"
                            bg-color="surface"
                            append-inner-icon="mdi-magnify"
                            @click:append-inner="fetchCep"
                            @blur="fetchCep"
                            :loading="loadingCep"
                            maxlength="9"
                            :rules="[rules.required]"
                          ></v-text-field>
                        </v-col>
                        <v-col cols="12" sm="8">
                          <v-text-field label="Logradouro" v-model="formData.endereco.logradouro" variant="outlined" density="compact" bg-color="surface" :rules="[rules.required]"></v-text-field>
                        </v-col>
                        <v-col cols="12" sm="4">
                          <v-text-field label="Número" v-model="formData.endereco.numero" variant="outlined" density="compact" bg-color="surface" :rules="[rules.required]"></v-text-field>
                        </v-col>
                        <v-col cols="12" sm="8">
                          <v-text-field label="Complemento" v-model="formData.endereco.complemento" variant="outlined" density="compact" bg-color="surface"></v-text-field>
                        </v-col>
                        <v-col cols="12" sm="5">
                          <v-text-field label="Bairro" v-model="formData.endereco.bairro" variant="outlined" density="compact" bg-color="surface" :rules="[rules.required]"></v-text-field>
                        </v-col>
                        <v-col cols="12" sm="5">
                          <v-text-field label="Cidade" v-model="formData.endereco.cidade" variant="outlined" density="compact" bg-color="surface" :rules="[rules.required]"></v-text-field>
                        </v-col>
                        <v-col cols="12" sm="2">
                          <v-text-field label="UF" v-model="formData.endereco.uf" variant="outlined" density="compact" bg-color="surface" :rules="[rules.required]" maxlength="2"></v-text-field>
                        </v-col>
                     </v-row>
                 </v-card>
              </v-col>
            </v-row>
          </div>
        </v-form>
      </v-card-text>

      <v-divider></v-divider>

      <div class="pa-4 d-flex justify-end gap-3 align-center bg-surface-light">
        <span v-if="errorMessage" class="text-caption text-error font-weight-bold mr-auto ml-2">
            <v-icon start size="small">mdi-alert-circle</v-icon> {{ errorMessage }}
        </span>

        <v-btn
          variant="text"
          color="medium-emphasis"
          @click="close"
          :disabled="saving"
        >
          Cancelar
        </v-btn>

        <v-btn
          color="primary"
          variant="flat"
          class="font-weight-bold px-6"
          @click="submitForm"
          :loading="saving"
        >
          Cadastrar
        </v-btn>
      </div>

    </v-card>
  </v-dialog>
</template>

<script setup lang="ts">
import { ref, reactive, watch, computed } from 'vue'
import { gestaoApiCajuia } from '@/api/gestaoClick_Cajuia' // INTEGRAÇÃO CORRETA
import { useAppStore } from '@/stores/app'
import { useThemeStore } from '@/stores/theme'

const props = defineProps({ show: Boolean })
const emit = defineEmits(['close', 'client-created'])
const appStore = useAppStore()
const themeStore = useThemeStore()

const form = ref<any>(null)
const valid = ref(false)
const saving = ref(false)
const loadingCep = ref(false)
const loadingCnpj = ref(false)
const errorMessage = ref<string | null>(null)

const formData = reactive({
  tipoPessoa: 'Fisica' as 'Fisica' | 'Juridica',
  nome: '',
  documento: '',
  email: '',
  telefone: '',
  endereco: { cep: '', logradouro: '', numero: '', complemento: '', bairro: '', cidade: '', uf: '' }
})

const rules = {
  required: (v: string) => !!v || 'Obrigatório',
  email: (v: string) => !v || /.+@.+\..+/.test(v) || 'E-mail inválido',
  documento: (v: string) => {
      if(!v) return 'Obrigatório'
      const clean = v.replace(/\D/g, '')
      if(formData.tipoPessoa === 'Fisica' && clean.length !== 11) return 'CPF inválido'
      if(formData.tipoPessoa === 'Juridica' && clean.length !== 14) return 'CNPJ inválido'
      return true
  }
}

const getCnpjIcon = computed(() => {
    if (loadingCnpj.value) return 'mdi-loading mdi-spin';
    return formData.tipoPessoa === 'Juridica' ? 'mdi-magnify' : undefined;
});

watch(() => props.show, (val) => {
  if (val) {
    Object.assign(formData, {
      tipoPessoa: 'Fisica',
      nome: '', documento: '', email: '', telefone: '',
      endereco: { cep: '', logradouro: '', numero: '', complemento: '', bairro: '', cidade: '', uf: '' }
    });
    errorMessage.value = null;
    if(form.value) form.value.resetValidation();
  }
})

const resetDocumento = () => {
    formData.documento = '';
    if(form.value) form.value.resetValidation();
}

const formatDocumento = () => {
  let v = formData.documento.replace(/\D/g, '')
  if (formData.tipoPessoa === 'Fisica') {
    v = v.substring(0, 11)
    v = v.replace(/(\d{3})(\d)/, '$1.$2')
    v = v.replace(/(\d{3})(\d)/, '$1.$2')
    v = v.replace(/(\d{3})(\d{1,2})$/, '$1-$2')
  } else {
    v = v.substring(0, 14)
    v = v.replace(/^(\d{2})(\d)/, '$1.$2')
    v = v.replace(/^(\d{2})\.(\d{3})(\d)/, '$1.$2.$3')
    v = v.replace(/\.(\d{3})(\d)/, '.$1/$2')
    v = v.replace(/(\d{4})(\d)/, '$1-$2')
  }
  formData.documento = v
}

const formatTelefone = () => {
  let v = formData.telefone.replace(/\D/g, '')
  v = v.substring(0, 11)
  v = v.replace(/^(\d{2})(\d)/g, '($1) $2')
  v = v.replace(/(\d)(\d{4})$/, '$1-$2')
  formData.telefone = v
}

const fetchCnpjData = async () => {
    if (formData.tipoPessoa !== 'Juridica') return;
    const cnpjClean = formData.documento.replace(/\D/g, '');
    if (cnpjClean.length !== 14) return;

    loadingCnpj.value = true;
    errorMessage.value = null;

    try {
        const res = await fetch(`https://brasilapi.com.br/api/cnpj/v1/${cnpjClean}`);
        if (!res.ok) throw new Error('CNPJ não encontrado.');
        const data = await res.json();

        formData.nome = data.razao_social || data.nome_fantasia || '';
        formData.email = data.email || '';
        if(data.ddd_telefone_1) {
             let fone = data.ddd_telefone_1.replace(/\D/g, '');
             formData.telefone = fone; // Aplicar máscara se necessário
        }
        if(data.cep) formData.endereco.cep = String(data.cep).replace(/^(\d{5})(\d{3})/, '$1-$2');
        formData.endereco.logradouro = data.logradouro || '';
        formData.endereco.numero = data.numero || '';
        formData.endereco.complemento = data.complemento || '';
        formData.endereco.bairro = data.bairro || '';
        formData.endereco.cidade = data.municipio || '';
        formData.endereco.uf = data.uf || '';

        appStore.showSnackbar('Dados carregados com sucesso!', 'success');
    } catch (error: any) {
        errorMessage.value = error.message;
    } finally {
        loadingCnpj.value = false;
    }
};

const fetchCep = async () => {
  const cep = formData.endereco.cep.replace(/\D/g, '')
  if (cep.length !== 8) return

  loadingCep.value = true;
  try {
    const res = await fetch(`https://viacep.com.br/ws/${cep}/json/`)
    const data = await res.json()
    if (!data.erro) {
      formData.endereco.logradouro = data.logradouro
      formData.endereco.bairro = data.bairro
      formData.endereco.cidade = data.localidade
      formData.endereco.uf = data.uf
    }
  } finally {
    loadingCep.value = false
  }
}

const submitForm = async () => {
  const { valid: isValid } = await form.value.validate()
  if (!isValid) return

  saving.value = true
  errorMessage.value = null;

  try {
    const payload: any = {
      nome: formData.nome,
      tipo_pessoa: formData.tipoPessoa,
      cpf_cnpj: formData.documento.replace(/\D/g, ''),
      email: formData.email,
      telefone: formData.telefone,
      enderecos: [{
          endereco: {
            logradouro: formData.endereco.logradouro,
            numero: formData.endereco.numero,
            complemento: formData.endereco.complemento,
            bairro: formData.endereco.bairro,
            nome_cidade: formData.endereco.cidade, // GestãoClick pede ID ou nome
            estado: formData.endereco.uf,
            cep: formData.endereco.cep
          }
      }]
    }

    const res = await gestaoApiCajuia.cadastrarCliente(payload)

    emit('client-created', {
        id: res.id || Date.now(),
        nome: formData.nome,
        cpf_cnpj: formData.documento
    })
    close()

  } catch (e: any) {
    console.error(e)
    errorMessage.value = e.message || 'Erro ao criar cliente.';
    appStore.showSnackbar('Erro ao cadastrar.', 'error')
  } finally {
    saving.value = false
  }
}

const close = () => emit('close')
</script>

<style scoped>
.bg-gradient-primary { background: linear-gradient(135deg, rgb(var(--v-theme-primary)), rgba(var(--v-theme-primary), 0.8)); }
.custom-scrollbar::-webkit-scrollbar { width: 6px; }
.custom-scrollbar::-webkit-scrollbar-track { background: transparent; }
.custom-scrollbar::-webkit-scrollbar-thumb { background: rgba(var(--v-theme-on-surface), 0.2); border-radius: 3px; }
</style>
