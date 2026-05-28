<template>
  <v-dialog :model-value="show" @update:model-value="$emit('close')" max-width="1200px" persistent>
    <v-card class="bg-grey-lighten-5 h-100 rounded-xl overflow-hidden" style="max-height: 90vh;">
        <div class="px-6 py-4 border-b bg-white d-flex justify-space-between align-center">
            <div class="d-flex align-center gap-3">
                <div class="icon-box bg-teal-darken-3 text-white rounded-lg">
                    <v-icon>mdi-file-document-multiple-outline</v-icon>
                </div>
                <div>
                    <h3 class="text-subtitle-1 font-weight-black text-grey-darken-4 lh-1">Monitor Fiscal (NFe)</h3>
                    <div class="text-caption text-grey-darken-1">Acompanhe as notas emitidas por empresa.</div>
                </div>
            </div>
            <v-btn icon="mdi-close" variant="text" color="grey" @click="$emit('close')"></v-btn>
        </div>

        <div class="pa-4 border-b bg-white d-flex flex-wrap gap-4 align-center">
            <v-select
                v-model="selectedCompanyCnpj"
                :items="companies"
                item-title="trade_name"
                item-value="cnpj"
                label="Selecione a Empresa"
                variant="outlined" density="compact"
                hide-details style="width: 300px;"
                @update:model-value="fetchNotes"
            ></v-select>
            <v-btn prepend-icon="mdi-refresh" variant="tonal" color="blue-darken-3" @click="fetchNotes" :loading="loading">Atualizar</v-btn>
        </div>

        <div class="flex-grow-1 overflow-y-auto pa-4 custom-scrollbar">
            <v-card class="border rounded-lg shadow-sm" flat>
                <v-table hover>
                    <thead>
                        <tr class="bg-grey-lighten-4 text-uppercase text-caption font-weight-bold">
                            <th>Número</th>
                            <th>Emissão</th>
                            <th>Valor</th>
                            <th>Destinatário</th>
                            <th>Chave</th>
                            <th class="text-center">Status</th>
                            <th class="text-right">Ações</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr v-if="loading" class="text-center"><td colspan="7" class="pa-4">Carregando notas...</td></tr>
                        <tr v-else-if="notes.length === 0" class="text-center"><td colspan="7" class="pa-4 text-grey">Nenhuma nota encontrada.</td></tr>
                        <tr v-else v-for="note in notes" :key="note.id">
                            <td class="font-weight-bold">{{ note.numero }}</td>
                            <td>{{ formatDate(note.emissao) }}</td>
                            <td class="font-mono">{{ formatCurrency(note.valor) }}</td>
                            <td>{{ note.destinatario_nome || 'Consumidor Final' }}</td>
                            <td class="text-caption text-grey font-mono">{{ note.chave }}</td>
                            <td class="text-center">
                                <v-chip size="x-small" :color="getStatusColor(note.situacao_sefaz)" class="font-weight-bold text-uppercase">{{ note.situacao_sefaz }}</v-chip>
                            </td>
                            <td class="text-right">
                                <div class="d-flex justify-end gap-2">
                                    <v-btn size="x-small" color="primary" variant="tonal" :href="getPdfUrl(note.chave)" target="_blank" prepend-icon="mdi-file-pdf-box">DANFE</v-btn>
                                    <v-btn size="x-small" color="info" variant="tonal" :href="getXmlUrl(note.id)" target="_blank" prepend-icon="mdi-xml">XML</v-btn>
                                </div>
                            </td>
                        </tr>
                    </tbody>
                </v-table>
            </v-card>
        </div>
    </v-card>
  </v-dialog>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { supabase } from '@/api/supabase';
import axios from 'axios';

const props = defineProps<{ show: boolean }>();
const emit = defineEmits(['close']);

const API_URL = 'https://sefaz-proxy-dujl.onrender.com';
const companies = ref<any[]>([]);
const selectedCompanyCnpj = ref<string | null>(null);
const notes = ref<any[]>([]);
const loading = ref(false);

const fetchNotes = async () => {
   if(!selectedCompanyCnpj.value) return;
   loading.value = true;
   try {
      const res = await axios.get(`${API_URL}/api/consultar-notas`, {
         params: { cnpj: selectedCompanyCnpj.value }
      });
      notes.value = res.data.data || [];
   } catch(e) { console.error(e); }
   finally { loading.value = false; }
};

onMounted(async () => {
   const { data } = await supabase.from('companies').select('cnpj, trade_name').eq('active', true);
   companies.value = data || [];
   if(companies.value.length) {
      selectedCompanyCnpj.value = companies.value[0].cnpj;
      fetchNotes();
   }
});

const getStatusColor = (s: string) => {
    const status = s?.toLowerCase();
    if(status === 'autorizada') return 'success';
    if(status === 'cancelada') return 'error';
    return 'warning';
};

const formatDate = (d: string) => new Date(d).toLocaleString('pt-BR');
const formatCurrency = (v: number) => new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(v);
const getPdfUrl = (chave: string) => `${API_URL}/api/danfe/${chave}`;
const getXmlUrl = (id: string) => `${API_URL}/api/baixar-xml/${id}`;
</script>

<style scoped>
.icon-box { width: 40px; height: 40px; display: flex; align-items: center; justify-content: center; }
.lh-1 { line-height: 1.2; }
.custom-scrollbar::-webkit-scrollbar { width: 8px; }
.custom-scrollbar::-webkit-scrollbar-thumb { background: #bdbdbd; border-radius: 4px; }
</style>
