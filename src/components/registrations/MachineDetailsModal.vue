<template>
  <v-dialog :model-value="show" @update:model-value="$emit('update:show', $event)" max-width="500" persistent>
    <v-card class="rounded-xl overflow-hidden border-thin shadow-2xl">
      <div class="pa-6 bg-grey-lighten-4 border-b">
        <div class="d-flex align-center gap-3">
          <v-avatar color="primary" variant="tonal" class="rounded-lg"><v-icon>mdi-cog-box</v-icon></v-avatar>
          <h2 class="text-h6 font-weight-black">{{ form.id ? 'Editar Máquina' : 'Nova Máquina' }}</h2>
        </div>
      </div>

      <div class="pa-6">
        <v-form ref="formRef" @submit.prevent="save">
          <v-row dense>
            <v-col cols="12">
              <v-text-field v-model="form.nome" label="Nome da Máquina *" variant="outlined" density="compact" :rules="[v => !!v || 'Obrigatório']"></v-text-field>
            </v-col>
            <v-col cols="12">
              <v-autocomplete 
                v-model="form.tipo" 
                :items="machineTypes" 
                item-title="nome" 
                item-value="id" 
                label="Tipo de Máquina *" 
                variant="outlined" 
                density="compact" 
                :rules="[v => !!v || 'Obrigatório']"
                no-data-text="Nenhum tipo encontrado"
              >
                <template v-slot:append-item>
                  <v-divider></v-divider>
                  <v-list-item @click="openNewTypeModal" class="py-3 hover-bg-light">
                    <template v-slot:prepend>
                      <v-icon color="primary" class="mr-2">mdi-plus-circle-outline</v-icon>
                    </template>
                    <v-list-item-title class="text-primary font-weight-black text-uppercase tracking-widest text-caption">
                      Cadastrar Novo Tipo
                    </v-list-item-title>
                  </v-list-item>
                </template>
              </v-autocomplete>
            </v-col>
          </v-row>
        </v-form>
      </div>

      <div class="pa-6 d-flex justify-end border-t bg-grey-lighten-5">
        <v-btn variant="text" @click="$emit('update:show', false)" class="font-weight-bold">Cancelar</v-btn>
        <v-btn color="primary" variant="flat" class="ml-3 font-weight-bold px-6" :loading="loading" @click="save">Salvar Máquina</v-btn>
      </div>
    </v-card>
  </v-dialog>

  <v-dialog v-model="newTypeModal.show" max-width="400" persistent>
    <v-card class="rounded-xl border-thin shadow-2xl">
      <div class="pa-4 bg-primary text-white d-flex align-center gap-2">
        <v-icon>mdi-shape-plus</v-icon>
        <span class="font-weight-black text-body-1">Novo Tipo de Máquina</span>
      </div>
      
      <div class="pa-6">
        <v-text-field
          v-model="newTypeModal.nome"
          label="Nome do Setor / Tipo *"
          variant="outlined"
          density="compact"
          hide-details="auto"
          placeholder="Ex: Embalagem, Lavagem..."
          @keyup.enter="saveNewType"
          autofocus
        ></v-text-field>
      </div>

      <div class="pa-4 d-flex justify-end gap-3 border-t bg-grey-lighten-4">
        <v-btn variant="outlined" class="font-weight-bold border-thin" color="grey-darken-2" @click="newTypeModal.show = false">Cancelar</v-btn>
        <v-btn color="primary" variant="flat" class="font-weight-bold px-6" :loading="newTypeModal.loading" @click="saveNewType">Salvar Tipo</v-btn>
      </div>
    </v-card>
  </v-dialog>
</template>

<script setup lang="ts">
import { ref, watch, onMounted, reactive } from 'vue';
import { supabase } from '@/api/supabase';
import { useAppStore } from '@/stores/app';
import { useCompanyStore } from '@/stores/company';

const props = defineProps(['show', 'machine']);
const emit = defineEmits(['update:show', 'refresh']);
const appStore = useAppStore();
const companyStore = useCompanyStore();

const form = ref<any>({});
const machineTypes = ref<any[]>([]);
const loading = ref(false);
const formRef = ref();

// Controle do Modal de Novo Tipo
const newTypeModal = reactive({
  show: false,
  nome: '',
  loading: false
});

// Função para buscar os tipos no banco
const fetchTypes = async () => {
  try {
    const { data, error } = await supabase.from('type_machines').select('id, nome').order('nome').eq('empresa_id', companyStore.currentCompany?.id);
    if (error) throw error;
    machineTypes.value = data || [];
  } catch (error: any) {
    console.error("Erro ao buscar type_machines:", error.message);
  }
};

// Quando abre o modal de edição/criação de Máquina
watch(() => props.show, async (val) => {
  if (val) {
    form.value = props.machine ? { ...props.machine } : { nome: '', tipo: null };
    if (machineTypes.value.length === 0) await fetchTypes();
  }
});

// Inicialização
onMounted(() => {
  fetchTypes();
});

// ----------------------------------------------------
// AÇÕES DO MINI-MODAL (TIPO)
// ----------------------------------------------------
const openNewTypeModal = () => {
  newTypeModal.nome = '';
  newTypeModal.show = true;
};

const saveNewType = async () => {
  if (!newTypeModal.nome.trim()) {
    return appStore.showSnackbar("Por favor, digite o nome do tipo.", "warning");
  }

  newTypeModal.loading = true;
  try {
    // Insere e já pede para retornar os dados criados (.select().single())
    const { data, error } = await supabase
      .from('type_machines')
      .insert({ nome: newTypeModal.nome.trim(), empresa_id: companyStore.currentCompany?.id })
      .select('id, nome')
      .single();

    if (error) throw error;

    appStore.showSnackbar("Novo tipo cadastrado!", "success");
    
    // Atualiza a lista por trás
    await fetchTypes();

    // Auto-seleciona o novo tipo no formulário da máquina
    if (data) {
      form.value.tipo = data.id;
    }

    newTypeModal.show = false;
  } catch (error: any) {
    console.error("Erro ao cadastrar tipo:", error.message);
    appStore.showSnackbar("Falha ao salvar o tipo: " + error.message, "error");
  } finally {
    newTypeModal.loading = false;
  }
};

// ----------------------------------------------------
// AÇÕES DO MODAL PRINCIPAL (MÁQUINA)
// ----------------------------------------------------
const save = async () => {
  const { valid } = await formRef.value.validate();
  if (!valid) return;

  loading.value = true;
  try {
    const payload = {
      nome: form.value.nome,
      tipo: form.value.tipo
    };

    if (form.value.id) {
      const { error } = await supabase.from('machines').update(payload).eq('id', form.value.id);
      if (error) throw error;
      appStore.showSnackbar("Máquina atualizada!", "success");
    } else {
      const { error } = await supabase.from('machines').insert(payload);
      if (error) throw error;
      appStore.showSnackbar("Máquina cadastrada com sucesso!", "success");
    }
    
    emit('refresh'); 
    emit('update:show', false); 
  } catch (error: any) {
    console.error("Erro Supabase:", error);
    appStore.showSnackbar("Falha ao salvar: " + error.message, "error");
  } finally {
    loading.value = false;
  }
};
</script>

<style scoped>
.hover-bg-light:hover {
  background-color: #f5f7fa !important;
  cursor: pointer;
}
.tracking-widest {
  letter-spacing: 0.05em;
}
.border-thin {
  border: 1px solid rgba(0,0,0,0.08) !important;
}
</style>