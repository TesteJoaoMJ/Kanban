<template>
  <v-card class="order-client-card mb-4" :class="cardThemeClass" elevation="0">
    <div class="px-4 py-3 d-flex align-center gap-2 border-b border-opacity-10 bg-surface-variant">
      <v-icon size="16" color="primary">mdi-account-box-outline</v-icon>
      <span class="text-subtitle-2 font-weight-bold" :class="textPrimaryClass">Dados do Cliente e Venda</span>
    </div>

    <v-card-text class="pa-4">
      <v-form ref="formRef">
        <v-row dense>
          <v-col cols="12" md="8">
            <div class="text-caption font-weight-bold mb-1 ml-1 opacity-70" :class="textSecondaryClass">Cliente</div>
            <v-autocomplete
              :model-value="customerId"
              @update:model-value="$emit('update:customerId', $event)"
              v-model:search="clientSearch"
              :items="clientList"
              :item-title="(item) => item.nome || item.name"
              item-value="id"
              variant="outlined"
              placeholder="Pesquise por nome, fantasia, CPF ou CNPJ..."
              :loading="isSearchingClients"
              :custom-filter="customFilter"
              density="comfortable"
              hide-details="auto"
              class="required-field"
              menu-icon="mdi-chevron-down"
              :bg-color="inputBgColor"
              :color="themeStore.currentMode === 'light' ? 'primary' : 'white'"
            >
              <template v-slot:selection="{ item }">
                <span class="text-body-2 font-weight-medium">{{ item.raw.nome || item.raw.name }}</span>
                <span v-if="item.raw.cpf_cnpj" class="text-caption text-medium-emphasis ml-2 hidden-sm-and-down">
                   ({{ item.raw.cpf_cnpj }})
                </span>
              </template>

              <template v-slot:item="{ props, item }">
                <v-list-item v-bind="props" :title="item.raw.nome || item.raw.name" class="py-2">
                   <template v-slot:subtitle>
                      <div class="d-flex align-center gap-2 mt-1">
                          <span class="text-caption font-mono bg-grey-lighten-4 px-1 rounded text-black" v-if="item.raw.cpf_cnpj">
                             {{ item.raw.cpf_cnpj }}
                          </span>
                          <span class="text-[10px] text-medium-emphasis" v-if="item.raw.cidade">
                             {{ item.raw.cidade }}
                          </span>
                      </div>
                   </template>
                   <template v-slot:append>
                       <v-chip size="x-small" :color="item.raw.situacao === 'Inativo' ? 'error' : 'success'" variant="flat" class="text-[9px] font-weight-bold">
                           {{ item.raw.situacao || 'Ativo' }}
                       </v-chip>
                   </template>
                </v-list-item>
              </template>

              <template v-slot:append-inner>
                 <v-tooltip text="Cadastrar Novo Cliente" location="top" content-class="bg-black text-caption font-weight-bold">
                    <template v-slot:activator="{ props }">
                      <v-btn
                        v-bind="props"
                        icon
                        size="small"
                        variant="tonal"
                        color="primary"
                        class="rounded ml-1"
                        @click="$emit('create-client')"
                        style="height: 28px; width: 28px;"
                      >
                         <v-icon size="16">mdi-plus</v-icon>
                      </v-btn>
                    </template>
                 </v-tooltip>
              </template>

              <template v-slot:no-data>
                <div class="pa-4 text-center">
                   <span class="text-caption text-medium-emphasis d-block mb-2">Cliente não encontrado no banco de dados.</span>
                   <v-btn size="small" color="primary" variant="tonal" @click="$emit('create-client')">Cadastrar Novo</v-btn>
                </div>
              </template>
            </v-autocomplete>
          </v-col>

          <v-col cols="12" md="4">
            <div class="text-caption font-weight-bold mb-1 ml-1 opacity-70" :class="textSecondaryClass">Vendedor Responsável</div>
            <v-autocomplete
              :model-value="safeVendedorId"
              @update:model-value="$emit('update:vendedorId', $event)"
              :items="salespeopleList"
              item-title="full_name"
              item-value="id"
              variant="outlined"
              :loading="loadingSalespeople"
              :disabled="loadingSalespeople"
              density="comfortable"
              hide-details="auto"
              menu-icon="mdi-chevron-down"
              :bg-color="inputBgColor"
              :placeholder="loadingSalespeople ? 'Carregando vendedores...' : 'Selecione...'"
              :color="themeStore.currentMode === 'light' ? 'primary' : 'white'"
            >
               <template v-slot:selection="{ item }">
                   <div class="d-flex align-center gap-2">
                       <v-avatar size="20" color="primary" variant="tonal">
                           <span class="text-[10px] font-weight-bold">{{ getInitials(item.raw.full_name) }}</span>
                       </v-avatar>
                       <span class="text-body-2 font-weight-medium text-truncate">{{ item.raw.full_name }}</span>
                   </div>
               </template>

               <template v-slot:item="{ props, item }">
                  <v-list-item v-bind="props" density="compact">
                      <template v-slot:prepend>
                          <v-avatar size="24" color="grey-lighten-3" class="mr-2">
                              <span class="text-caption font-weight-bold text-grey-darken-3">{{ getInitials(item.raw.full_name) }}</span>
                          </v-avatar>
                      </template>
                  </v-list-item>
               </template>
            </v-autocomplete>
          </v-col>
        </v-row>
      </v-form>
    </v-card-text>
  </v-card>
</template>

<script setup lang="ts">
import { ref, watch, computed } from 'vue';
import { supabase } from '@/api/supabase';
import { useThemeStore } from '@/stores/theme';

const props = defineProps<{
  customerId: number | string | null;
  vendedorId: string | null;
  clientList: any[];
  salespeopleList: any[];
  loadingSalespeople: boolean;
}>();

const emit = defineEmits(['update:customerId', 'update:vendedorId', 'create-client', 'update:clientList']);
const themeStore = useThemeStore();

const clientSearch = ref('');
const isSearchingClients = ref(false);
let searchTimeout: NodeJS.Timeout;

// THEME COMPUTEDS
const cardThemeClass = computed(() => themeStore.currentMode === 'light' ? 'bg-white border-grey-lighten-2 shadow-sm' : 'bg-surface border-white-10');
const textPrimaryClass = computed(() => themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white');
const textSecondaryClass = computed(() => themeStore.currentMode === 'light' ? 'text-grey-darken-1' : 'text-white-70');
const inputBgColor = computed(() => themeStore.currentMode === 'light' ? undefined : 'rgba(255,255,255,0.03)');

// LÓGICA DE CORREÇÃO DO UUID DO VENDEDOR
const safeVendedorId = computed(() => {
    if (props.loadingSalespeople) return null;
    const exists = props.salespeopleList.some(s => s.id === props.vendedorId);
    return exists ? props.vendedorId : null;
});

const getInitials = (name: string) => {
    if (!name) return 'V';
    return name.split(' ').map(n => n[0]).join('').substring(0, 2).toUpperCase();
};

// Função auxiliar para remover acentos e ignorar case
const normalizeStr = (str: string) => {
    if (!str) return '';
    return str.normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase().trim();
};

// FILTRO INTELIGENTE LOCAL (MANTIDO POR SEGURANÇA PARA A LISTA JÁ CARREGADA)
const customFilter = (value: string, query: string, item: any) => {
    if (!query) return true;

    const textoBuscado = normalizeStr(query);
    const nomeDoCliente = normalizeStr(item.raw.nome || item.raw.name);

    const cpfCnpjDoCliente = (item.raw.cpf_cnpj || '').replace(/\D/g, '');
    const numerosDaBusca = query.replace(/\D/g, '');

    return nomeDoCliente.includes(textoBuscado) ||
           (numerosDaBusca.length > 0 && cpfCnpjDoCliente.includes(numerosDaBusca));
};

watch(clientSearch, (newValue) => {
  if (!newValue || typeof newValue !== 'string' || newValue.trim().length < 2) return;

  const clienteSelecionado = props.clientList.find(c => c.id === props.customerId);
  const nomeSelecionado = clienteSelecionado ? (clienteSelecionado.nome || clienteSelecionado.name || '') : '';

  if (newValue === nomeSelecionado) {
      return;
  }

  isSearchingClients.value = true;
  clearTimeout(searchTimeout);

  searchTimeout = setTimeout(async () => {
    try {
      const termo = newValue.trim();
      const termoSeguro = termo.replace(/,/g, ' '); // Evita quebrar a string do OR no Supabase
      const termoLimpoNumeros = termo.replace(/\D/g, '');

      // MONTA A QUERY DE BUSCA LOCAL NO SUPABASE
      let queryOr = `nome.ilike.%${termoSeguro}%,razao_social.ilike.%${termoSeguro}%,nome_fantasia.ilike.%${termoSeguro}%`;

      // Se a pessoa digitou números, tenta buscar nos campos de documento também
      if (termoLimpoNumeros.length > 0) {
          queryOr += `,cpf.ilike.%${termoLimpoNumeros}%,cnpj.ilike.%${termoLimpoNumeros}%`;
      }

      const { data: clientsFromDb, error } = await supabase
        .from('customers_mj')
        .select('*')
        .or(queryOr)
        .limit(30);

      if (error) throw error;

      // MAPEA OS DADOS DO BANCO PARA O FORMATO QUE O SISTEMA ESPERA (Compatibilidade GestãoClick)
      const mappedClients = (clientsFromDb || []).map(c => ({
         ...c,
         id: c.gestao_click_id || c.id, // O sistema espera o gestao_click_id como 'id'
         nome: c.nome || c.razao_social || c.nome_fantasia,
         cpf_cnpj: c.cpf || c.cnpj
      }));

      // CACHE ACUMULATIVO PARA NÃO PERDER O CLIENTE SELECIONADO OU BUSCAS ANTERIORES
      const mapClientes = new Map();
      props.clientList.forEach(c => mapClientes.set(c.id, c));
      mappedClients.forEach(c => mapClientes.set(c.id, c));

      emit('update:clientList', Array.from(mapClientes.values()));
    } catch (error) {
       console.error("Erro na busca de clientes no Supabase:", error);
    } finally {
      isSearchingClients.value = false;
    }
  }, 400);
});
</script>

<style scoped lang="scss">
/* UTILS */
.gap-2 { gap: 8px; }
.border-white-10 { border-color: rgba(255, 255, 255, 0.1) !important; }
.bg-surface { background-color: rgba(30, 30, 35, 0.6) !important; backdrop-filter: blur(10px); }
.bg-surface-variant { background-color: rgba(128, 128, 128, 0.05); }

/* Shadow leve para modo claro */
.shadow-sm { box-shadow: 0 1px 3px rgba(0,0,0,0.05) !important; border: 1px solid #E0E0E0; }

/* Ajustes finos nos inputs */
:deep(.v-field__outline) {
    --v-field-border-opacity: 0.15;
}
:deep(.v-field--focused .v-field__outline) {
    --v-field-border-opacity: 0.8;
}
</style>
