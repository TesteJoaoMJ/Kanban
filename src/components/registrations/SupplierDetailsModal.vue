<template>
  <v-dialog
    :model-value="show"
    @update:model-value="handleUpdateShow"
    max-width="1200px"
    height="75vh"
    max-height="750px"
    persistent
    scrim="black opacity-90"
    transition="dialog-bottom-transition"
    class="fixed-dialog"
  >
    <v-card class="modal-wrapper d-flex flex-row rounded-0 overflow-hidden h-100 font-sans border-thin" :class="isDark ? 'is-dark bg-grey-darken-4 text-white border-white-10' : 'bg-grey-lighten-4 border-grey-darken-2'" elevation="24">

      <div class="sidebar-menu d-flex flex-column flex-shrink-0 text-white shadow-md" :class="isDark ? 'bg-grey-darken-4 border-r border-white-10' : 'bg-grey-darken-4 border-r border-grey-darken-3'" style="width: 270px; z-index: 20;">
          <div class="pa-5 d-flex flex-column align-center text-center border-b border-white-10 relative flex-shrink-0">
              <v-btn icon size="x-small" variant="text" color="white" class="absolute top-2 right-2 d-md-none rounded-0" @click="$emit('close')"><v-icon>mdi-close</v-icon></v-btn>

              <v-avatar size="64" color="success" class="rounded-lg border-white-20 transition-all mb-3 elevation-6">
                  <span class="text-h4 font-weight-black text-white">
                      {{ form.nome ? form.nome.charAt(0).toUpperCase() : 'N' }}
                  </span>
              </v-avatar>

              <h3 class="text-[13px] font-weight-black leading-tight mb-1 text-white uppercase">{{ form.nome || 'NOVO FORNECEDOR' }}</h3>
              <div class="text-[10px] font-weight-bold text-grey-lighten-1 text-uppercase tracking-widest mb-3" style="min-height: 12px;">
                  {{ form.cnpj_cpf || 'DOCUMENTO PENDENTE' }}
              </div>

              <div class="d-flex flex-wrap align-center justify-center gap-2 w-100">
                  <span class="text-[10px] font-weight-bold px-2 py-1 rounded-0 text-uppercase border border-white-10" :class="form.situacao === 'Inativo' ? 'bg-red-darken-3' : 'bg-green-darken-3'">
                      {{ form.situacao || 'ATIVO' }}
                  </span>
                  <span class="text-[10px] font-weight-bold px-2 py-1 rounded-0 text-uppercase border border-white-10" :class="form.status_homologacao === 'Homologado' ? 'bg-blue-darken-3' : 'bg-orange-darken-4'">
                      {{ form.status_homologacao || 'Em Análise' }}
                  </span>
              </div>
          </div>

          <v-tabs v-model="activeTab" direction="vertical" color="white" class="flex-grow-1 custom-scroll" slider-color="success">
              <v-tab :value="0" class="text-none font-weight-bold justify-start px-4 tab-item"><v-icon start size="16" class="opacity-70">mdi-domain</v-icon> Identificação & Fiscal</v-tab>
              <v-tab :value="1" class="text-none font-weight-bold justify-start px-4 tab-item"><v-icon start size="16" class="opacity-70">mdi-map-marker-radius</v-icon> Endereço & Contatos</v-tab>
              <v-tab :value="2" class="text-none font-weight-bold justify-start px-4 tab-item"><v-icon start size="16" class="opacity-70">mdi-cash-fast</v-icon> Financeiro & Homologação</v-tab>
          </v-tabs>
      </div>

      <div class="flex-grow-1 d-flex flex-column overflow-hidden relative" :class="isDark ? 'bg-grey-darken-4' : 'bg-grey-lighten-4'">

          <div class="px-5 py-3 d-flex justify-space-between align-center border-b flex-shrink-0 z-10 shadow-sm" :class="isDark ? 'bg-grey-darken-3 border-white-10' : 'bg-white border-grey-lighten-2'">
              <div class="text-[14px] font-weight-black text-uppercase d-flex align-center gap-2 tracking-widest" :class="isDark ? 'text-white' : 'text-grey-darken-4'">
                  <v-icon color="success" size="18">{{ tabIcons[activeTab] }}</v-icon>
                  {{ tabTitles[activeTab] }}
              </div>
              <div class="d-flex align-center gap-3">
                  <v-btn variant="outlined" class="btn-3d font-weight-bold" height="34" @click="$emit('close')" :color="isDark ? 'white' : 'grey-darken-2'">DESCARTAR</v-btn>
                  <v-btn color="success" variant="elevated" elevation="4" class="btn-3d font-weight-black px-6 text-[12px] tracking-widest" height="34" :loading="isSaving" @click="saveSupplier">
                      <v-icon start size="16">mdi-content-save-check</v-icon> SALVAR
                  </v-btn>
              </div>
          </div>

          <div class="flex-grow-1 overflow-y-auto custom-scroll pa-4">
              <v-form ref="formRef" @submit.prevent class="h-100">
                  <v-window v-model="activeTab" :touch="false" class="overflow-visible h-100">

                      <v-window-item :value="0" class="h-100">
                          <v-card class="rounded-0 border shadow-sm mb-3" :class="isDark ? 'bg-grey-darken-4 border-white-10' : 'bg-white border-grey-lighten-2'" elevation="0">
                              <div class="px-4 py-2 border-b text-[10px] font-weight-black text-uppercase" :class="isDark ? 'bg-grey-darken-3 text-white border-white-10' : 'bg-grey-lighten-4 text-grey-darken-3 border-grey-lighten-2'">Dados Cadastrais</div>
                              <div class="pa-4">
                                  <v-row dense class="row-gap-micro">
                                      <v-col cols="12" md="4"><label class="input-label">CNPJ / CPF *</label><v-text-field v-model="form.cnpj_cpf" variant="outlined" density="compact" hide-details="auto" :color="isDark ? 'success-lighten-1' : 'success'" class="ui-field font-mono font-weight-black" :class="isDark ? 'text-success-lighten-1' : 'text-success'" :rules="[v => !!v || 'Obrigatório']"></v-text-field></v-col>
                                      <v-col cols="12" md="4"><label class="input-label">Tipo</label><v-select v-model="form.tipo_pessoa" :items="['PJ', 'PF', 'EX']" variant="outlined" density="compact" hide-details="auto" color="success" class="ui-field"></v-select></v-col>
                                      <v-col cols="12" md="4"><label class="input-label">Status Base</label><v-select v-model="form.situacao" :items="['Ativo', 'Inativo', 'Bloqueado']" variant="outlined" density="compact" hide-details="auto" color="success" class="ui-field"></v-select></v-col>
                                      <v-col cols="12" md="6"><label class="input-label">Razão Social *</label><v-text-field v-model="form.razao_social" variant="outlined" density="compact" hide-details="auto" color="success" class="ui-field font-weight-bold text-uppercase" :rules="[v => !!v || 'Obrigatório']"></v-text-field></v-col>
                                      <v-col cols="12" md="6"><label class="input-label">Nome Fantasia</label><v-text-field v-model="form.nome" variant="outlined" density="compact" hide-details="auto" color="success" class="ui-field font-weight-bold"></v-text-field></v-col>
                                  </v-row>
                              </div>
                          </v-card>

                          <v-card class="rounded-0 border shadow-sm" :class="isDark ? 'bg-grey-darken-4 border-white-10' : 'bg-white border-grey-lighten-2'" elevation="0">
                              <div class="px-4 py-2 border-b text-[10px] font-weight-black text-uppercase" :class="isDark ? 'bg-grey-darken-3 text-white border-white-10' : 'bg-grey-lighten-4 text-grey-darken-3 border-grey-lighten-2'">Tributação (NFe)</div>
                              <div class="pa-4">
                                  <v-row dense class="row-gap-micro">
                                      <v-col cols="12" md="4"><label class="input-label">IE</label><v-text-field v-model="form.inscricao_estadual" placeholder="Isento/Números" variant="outlined" density="compact" hide-details="auto" color="success" class="ui-field font-mono"></v-text-field></v-col>
                                      <v-col cols="12" md="4"><label class="input-label">IM</label><v-text-field v-model="form.inscricao_municipal" variant="outlined" density="compact" hide-details="auto" color="success" class="ui-field font-mono"></v-text-field></v-col>
                                      <v-col cols="12" md="4"><label class="input-label">CNAE Principal</label><v-text-field v-model="form.cnae" variant="outlined" density="compact" hide-details="auto" color="success" class="ui-field font-mono"></v-text-field></v-col>
                                      <v-col cols="12" md="6"><label class="input-label">Regime Tributário</label><v-select v-model="form.regime_tributario" :items="['1 - Simples Nacional', '3 - Regime Normal', 'Não Informado']" variant="outlined" density="compact" hide-details="auto" color="success" class="ui-field"></v-select></v-col>
                                      <v-col cols="12" md="6"><label class="input-label">Tipo Fornecimento</label><v-select v-model="form.tipo_fornecimento" :items="['Revenda', 'Matéria Prima', 'Uso/Consumo', 'Serviços']" variant="outlined" density="compact" hide-details="auto" color="success" class="ui-field"></v-select></v-col>
                                  </v-row>
                              </div>
                          </v-card>
                      </v-window-item>

                      <v-window-item :value="1" class="h-100">
                          <v-card class="rounded-0 border shadow-sm mb-3" :class="isDark ? 'bg-grey-darken-4 border-white-10' : 'bg-white border-grey-lighten-2'" elevation="0">
                              <div class="px-4 py-2 border-b text-[10px] font-weight-black text-uppercase" :class="isDark ? 'bg-grey-darken-3 text-white border-white-10' : 'bg-grey-lighten-4 text-grey-darken-3 border-grey-lighten-2'">Localização da Matriz</div>
                              <div class="pa-4">
                                  <v-row dense class="row-gap-micro">
                                      <v-col cols="12" md="3"><label class="input-label">CEP</label><v-text-field v-model="form.cep" variant="outlined" density="compact" hide-details="auto" color="success" class="ui-field font-mono font-weight-bold" v-maska="'#####-###'"></v-text-field></v-col>
                                      <v-col cols="12" md="7"><label class="input-label">Logradouro</label><v-text-field v-model="form.logradouro" variant="outlined" density="compact" hide-details="auto" color="success" class="ui-field font-weight-bold text-uppercase"></v-text-field></v-col>
                                      <v-col cols="12" md="2"><label class="input-label">Nº</label><v-text-field v-model="form.numero" variant="outlined" density="compact" hide-details="auto" color="success" class="ui-field font-mono"></v-text-field></v-col>
                                      <v-col cols="12" md="4"><label class="input-label">Complemento</label><v-text-field v-model="form.complemento" variant="outlined" density="compact" hide-details="auto" color="success" class="ui-field"></v-text-field></v-col>
                                      <v-col cols="12" md="4"><label class="input-label">Bairro</label><v-text-field v-model="form.bairro" variant="outlined" density="compact" hide-details="auto" color="success" class="ui-field text-uppercase"></v-text-field></v-col>
                                      <v-col cols="12" md="3"><label class="input-label">Cidade</label><v-text-field v-model="form.cidade" variant="outlined" density="compact" hide-details="auto" color="success" class="ui-field text-uppercase"></v-text-field></v-col>
                                      <v-col cols="12" md="1"><label class="input-label">UF</label><v-text-field v-model="form.estado" variant="outlined" density="compact" hide-details="auto" color="success" class="ui-field text-center text-uppercase" maxlength="2"></v-text-field></v-col>
                                  </v-row>
                              </div>
                          </v-card>

                          <v-card class="rounded-0 border shadow-sm" :class="isDark ? 'bg-grey-darken-4 border-white-10' : 'bg-white border-grey-lighten-2'" elevation="0">
                              <div class="px-4 py-2 border-b text-[10px] font-weight-black text-uppercase" :class="isDark ? 'bg-grey-darken-3 text-white border-white-10' : 'bg-grey-lighten-4 text-grey-darken-3 border-grey-lighten-2'">Contatos Comerciais</div>
                              <div class="pa-4">
                                  <v-row dense class="row-gap-micro">
                                      <v-col cols="12" md="6"><label class="input-label">E-mail Comercial</label><v-text-field v-model="form.email" prepend-inner-icon="mdi-email" variant="outlined" density="compact" hide-details="auto" class="ui-field"></v-text-field></v-col>
                                      <v-col cols="12" md="6"><label class="input-label">E-mail Financeiro/XML</label><v-text-field v-model="form.email_financeiro" prepend-inner-icon="mdi-cash" variant="outlined" density="compact" hide-details="auto" class="ui-field"></v-text-field></v-col>
                                      <v-col cols="12" md="4"><label class="input-label">Celular/WhatsApp</label><v-text-field v-model="form.celular" prepend-inner-icon="mdi-whatsapp" variant="outlined" density="compact" hide-details="auto" class="ui-field font-mono" v-maska="['(##) ####-####', '(##) #####-####']"></v-text-field></v-col>
                                      <v-col cols="12" md="4"><label class="input-label">Telefone Fixo</label><v-text-field v-model="form.telefone" prepend-inner-icon="mdi-phone" variant="outlined" density="compact" hide-details="auto" class="ui-field font-mono" v-maska="['(##) ####-####', '(##) #####-####']"></v-text-field></v-col>
                                      <v-col cols="12" md="4"><label class="input-label">Representante</label><v-text-field v-model="form.contato_nome" prepend-inner-icon="mdi-account-tie" variant="outlined" density="compact" hide-details="auto" class="ui-field"></v-text-field></v-col>
                                  </v-row>
                              </div>
                          </v-card>
                      </v-window-item>

                      <v-window-item :value="2" class="h-100">
                          <v-card class="rounded-0 border shadow-sm mb-3" :class="isDark ? 'bg-grey-darken-4 border-white-10' : 'bg-white border-grey-lighten-2'" elevation="0">
                              <div class="px-4 py-2 border-b text-[10px] font-weight-black text-uppercase" :class="isDark ? 'bg-grey-darken-3 text-white border-white-10' : 'bg-grey-lighten-4 text-grey-darken-3 border-grey-lighten-2'">Dados Bancários / Pagamentos</div>
                              <div class="pa-4">
                                  <v-row dense class="row-gap-micro">
                                      <v-col cols="12" md="3"><label class="input-label">Banco</label><v-text-field v-model="form.banco" placeholder="Ex: 341" variant="outlined" density="compact" hide-details="auto" color="success" class="ui-field"></v-text-field></v-col>
                                      <v-col cols="12" md="2"><label class="input-label">Agência</label><v-text-field v-model="form.agencia" variant="outlined" density="compact" hide-details="auto" color="success" class="ui-field font-mono"></v-text-field></v-col>
                                      <v-col cols="12" md="3"><label class="input-label">Conta/Dígito</label><v-text-field v-model="form.conta" variant="outlined" density="compact" hide-details="auto" color="success" class="ui-field font-mono font-weight-bold"></v-text-field></v-col>
                                      <v-col cols="12" md="4"><label class="input-label">Chave PIX</label><v-text-field v-model="form.pix" variant="outlined" density="compact" hide-details="auto" color="success" class="ui-field font-mono font-weight-black"></v-text-field></v-col>
                                      <v-col cols="12" md="4"><label class="input-label">Pgto Padrão</label><v-select v-model="form.condicao_pagamento" :items="['À Vista', '30 Dias', '30/60/90']" variant="outlined" density="compact" hide-details="auto" color="success" class="ui-field"></v-select></v-col>
                                      <v-col cols="12" md="4"><label class="input-label">Frete Padrão</label><v-select v-model="form.tipo_frete" :items="['CIF', 'FOB']" variant="outlined" density="compact" hide-details="auto" color="success" class="ui-field"></v-select></v-col>
                                  </v-row>
                              </div>
                          </v-card>

                          <v-card class="rounded-0 border shadow-sm" :class="isDark ? 'bg-grey-darken-4 border-white-10' : 'bg-white border-grey-lighten-2'" elevation="0">
                              <div class="px-4 py-2 border-b text-[10px] font-weight-black text-uppercase d-flex justify-space-between align-center" :class="isDark ? 'bg-grey-darken-3 text-white border-white-10' : 'bg-grey-lighten-4 text-grey-darken-3 border-grey-lighten-2'">
                                  <span>Homologação e SLA</span>
                              </div>
                              <div class="pa-4">
                                  <v-row dense class="row-gap-micro">
                                      <v-col cols="12" md="6"><label class="input-label">Status Homologação</label><v-select v-model="form.status_homologacao" :items="['Em Análise', 'Homologado', 'Não Aprovado']" variant="outlined" density="compact" hide-details="auto" color="success" class="ui-field font-weight-bold"></v-select></v-col>
                                      <v-col cols="12" md="6"><label class="input-label">SLA Rating (Qualidade)</label>
                                          <div class="d-flex align-center gap-2 border rounded px-2" style="height: 32px;" :class="isDark ? 'bg-transparent border-white-10' : 'bg-white border-grey-lighten-2'">
                                              <v-rating v-model="form.rating_qualidade" hover half-increments color="amber-darken-2" density="compact" size="small"></v-rating>
                                          </div>
                                      </v-col>
                                      <v-col cols="12">
                                          <label class="input-label">Observações da Homologação</label>
                                          <v-textarea v-model="form.observacoes" variant="outlined" hide-details="auto" rows="2" class="ui-field text-[12px]"></v-textarea>
                                      </v-col>
                                  </v-row>
                              </div>
                          </v-card>
                      </v-window-item>

                  </v-window>
              </v-form>
          </div>
      </div>

    </v-card>
  </v-dialog>
</template>

<script setup lang="ts">
import { ref, watch, reactive, computed } from 'vue';
import { supabase } from '@/api/supabase';
import { useThemeStore } from '@/stores/theme';
import { useAppStore } from '@/stores/app';
import { vMaska } from "maska/vue";

const props = defineProps<{ show: boolean; supplier: any }>();
const emit = defineEmits(['update:show', 'close', 'refresh']);
const appStore = useAppStore();
const themeStore = useThemeStore();

const isDark = computed(() => themeStore.currentMode !== 'light');

const activeTab = ref(0);
const isSaving = ref(false);
const formRef = ref<any>(null);

const tabTitles = ['Matriz Fiscal e Geral', 'Localização e Telefones', 'Configurações Financeiras'];
const tabIcons = ['mdi-domain', 'mdi-map-marker-radius', 'mdi-cash-fast'];

// Payload Unificado de Alta Densidade
const getDefaultForm = () => ({
    nome: '', razao_social: '', cnpj_cpf: '', situacao: 'Ativo', tipo_pessoa: 'PJ',
    inscricao_estadual: '', inscricao_municipal: '', cnae: '', regime_tributario: '1 - Simples Nacional', tipo_fornecimento: 'Revenda',
    cep: '', logradouro: '', numero: '', complemento: '', bairro: '', cidade: '', estado: '',
    email: '', email_financeiro: '', telefone: '', celular: '', contato_nome: '',
    banco: '', agencia: '', conta: '', pix: '', condicao_pagamento: 'À Vista', tipo_frete: 'CIF',
    status_homologacao: 'Em Análise', rating_qualidade: 0, observacoes: ''
});

const form = reactive<any>(getDefaultForm());

watch(() => props.show, (newVal) => {
    if (newVal) {
        activeTab.value = 0;
        Object.assign(form, getDefaultForm());
        if (props.supplier && Object.keys(props.supplier).length > 0) {
            Object.keys(props.supplier).forEach(key => {
                if(props.supplier[key] !== null && props.supplier[key] !== undefined) form[key] = props.supplier[key];
            });
        }
        if(formRef.value) formRef.value.resetValidation();
    }
});

const handleUpdateShow = (val: boolean) => { if (!val) emit('close'); };

const saveSupplier = async () => {
    const { valid } = await formRef.value.validate();
    if (!valid) { activeTab.value = 0; return appStore.showSnackbar('Faltam dados obrigatórios.', 'warning'); }

    isSaving.value = true;
    try {
        const payload = { ...form };
        payload.updated_at = new Date().toISOString();
        if (payload.cnpj_cpf) payload.cnpj_cpf = payload.cnpj_cpf.replace(/\D/g, '');
        if (payload.cep) payload.cep = payload.cep.replace(/\D/g, '');

        if (!props.supplier?.id) {
            delete payload.id;
            const { error } = await supabase.from('suppliers_mj').insert(payload);
            if (error) throw error;
            appStore.showSnackbar('Fornecedor criado!', 'success');
        } else {
            const { error } = await supabase.from('suppliers_mj').update(payload).eq('id', props.supplier.id);
            if (error) throw error;
            appStore.showSnackbar('Fornecedor atualizado!', 'success');
        }

        emit('refresh');
        emit('close');
    } catch (error: any) {
        appStore.showSnackbar(`Erro: ${error.message}`, 'error');
    } finally {
        isSaving.value = false;
    }
};
</script>

<style scoped>
.fixed-dialog { overflow: hidden !important; }
.btn-3d { border-radius: 4px !important; text-transform: none !important; letter-spacing: 0.5px; box-shadow: 0 3px 5px rgba(0,0,0,0.15), inset 0 2px 0 rgba(255,255,255,0.25) !important; transition: transform 0.1s ease, box-shadow 0.1s ease;}
.btn-3d:active { transform: translateY(2px); box-shadow: 0 1px 2px rgba(0,0,0,0.15), inset 0 1px 0 rgba(255,255,255,0.2) !important; }

/* Campos Hiper Densos, agora 100% responsivos Dark/Light */
.modal-wrapper.is-dark .ui-field :deep(.v-field) { background: rgba(255,255,255,0.05) !important; color: white; border-color: rgba(255,255,255,0.1) !important; }
.modal-wrapper:not(.is-dark) .ui-field :deep(.v-field) { background: #fff !important; }
.ui-field :deep(.v-field) { border-radius: 2px !important; font-size: 11px; }
.ui-field :deep(.v-field__input) { min-height: 28px !important; padding-top: 2px !important; padding-bottom: 2px !important; }

.modal-wrapper.is-dark .input-label { color: #B0BEC5; }
.modal-wrapper:not(.is-dark) .input-label { color: #757575; }
.input-label { display: block; font-size: 9px; font-weight: 800; text-transform: uppercase; margin-bottom: 2px; letter-spacing: 0.2px; }

.tracking-widest { letter-spacing: 0.05em; }
.border-white-20 { border: 1px solid rgba(255,255,255,0.2) !important; }
.border-white-10 { border-color: rgba(255,255,255,0.1) !important; }
.shadow-sm { box-shadow: 0 1px 2px rgba(0,0,0,0.05) !important; }
.row-gap-micro { row-gap: 6px; margin-top: 0; }

.custom-scroll::-webkit-scrollbar { width: 6px; height: 6px; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.3); border-radius: 4px; }

.tab-item { border-bottom: 1px solid rgba(255,255,255,0.05); min-height: 42px; font-size: 11px; }
.tab-item.v-tab--selected { background: rgba(255,255,255,0.1); border-right: 3px solid #4CAF50; }
</style>
