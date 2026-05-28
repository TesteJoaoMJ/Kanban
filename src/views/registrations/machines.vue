<template>
  <div class="machines-layout font-sans fill-height d-flex flex-column bg-grey-lighten-5">
    
    <div class="header-bar px-6 py-4 bg-white border-b shadow-sm">
      <div class="d-flex justify-space-between align-center mb-6">
        <div>
          <div class="text-caption font-weight-bold text-uppercase opacity-70 tracking-widest">Cadastros > Máquinas</div>
          <div class="text-h5 font-weight-black">Gestão de Máquinas e Ativos</div>
        </div>
        <v-btn color="primary" variant="flat" prepend-icon="mdi-plus" @click="openModal(null)">Nova Máquina</v-btn>
      </div>

      <v-row>
        <v-col cols="12" md="4">
          <v-card class="pa-4 border-thin d-flex align-center shadow-sm" elevation="0">
            <v-avatar color="primary" variant="tonal" class="mr-4 rounded-lg"><v-icon>mdi-cog-box</v-icon></v-avatar>
            <div>
              <div class="text-caption font-weight-bold text-uppercase opacity-70">Total de Máquinas</div>
              <div class="text-h5 font-weight-black">{{ machines.length }}</div>
            </div>
          </v-card>
        </v-col>
      </v-row>
    </div>

    <v-card class="flex-grow-1 ma-6 border-thin shadow-sm d-flex flex-column" elevation="0">
      
      <div v-if="loading" class="d-flex flex-column justify-center align-center h-100 py-12">
        <v-progress-circular indeterminate color="primary" size="48"></v-progress-circular>
      </div>

      <v-table v-else class="corporate-table flex-grow-1">
        <thead class="bg-grey-lighten-4">
          <tr>
            <th class="font-weight-black text-uppercase">Nome da Máquina</th>
            <th class="font-weight-black text-uppercase">Tipo (Setor)</th>
            <th class="text-center font-weight-black text-uppercase">Ações</th>
          </tr>
        </thead>
        <tbody>
          <tr v-if="machines.length === 0">
            <td colspan="3" class="text-center py-8 text-grey font-weight-medium">Nenhuma máquina cadastrada.</td>
          </tr>
          <tr v-for="m in machines" :key="m.id" class="hover-bg-row">
            <td class="font-weight-bold text-body-2">{{ m.nome }}</td>
            <td>
              <v-chip size="small" color="blue-grey-darken-3" variant="outlined" class="font-weight-bold text-[10px] text-uppercase">
                {{ m.tipo_info?.nome || 'N/A' }}
              </v-chip>
            </td>
            <td class="text-center">
              <v-btn icon variant="flat" color="primary" size="small" class="mr-2" @click="openModal(m)">
                <v-icon size="16">mdi-pencil</v-icon>
              </v-btn>
              <v-btn icon variant="flat" color="error" size="small" @click="deleteMachine(m.id)">
                <v-icon size="16">mdi-trash-can-outline</v-icon>
              </v-btn>
            </td>
          </tr>
        </tbody>
      </v-table>
    </v-card>

    <MachineDetailsModal v-model:show="modal.show" :machine="modal.data" @refresh="fetchMachines" />
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, reactive } from 'vue';
import { supabase } from '@/api/supabase';
import MachineDetailsModal from '@/components/registrations/MachineDetailsModal.vue';
import { useCompanyStore } from '@/stores/company';

const machines = ref<any[]>([]);
const loading = ref(false);
const modal = reactive({ show: false, data: null });
const companyStore = useCompanyStore();

const fetchMachines = async () => {
  loading.value = true;
  try {
    // O Supabase entende a Foreign Key e traz o nome da tabela 'type_machines'
    const { data, error } = await supabase
      .from('machines')
      .select(`
        id,
        nome,
        tipo,
        created_at,
        tipo_info:type_machines(nome),
      `)
      .order('created_at', { ascending: false })
      .eq('empresa_id', companyStore.currentCompany?.id );

    if (error) throw error;
    machines.value = data || [];
  } catch (error: any) {
    console.error("Erro ao carregar máquinas:", error.message);
  } finally {
    loading.value = false;
  }
};

const openModal = (m: any) => { 
  modal.data = m; 
  modal.show = true; 
};

const deleteMachine = async (id: string) => {
  if(confirm("Confirma a exclusão desta máquina?")) {
    const { error } = await supabase.from('machines').delete().eq('id', id);
    if(error) {
      alert("Erro ao deletar: " + error.message);
    } else {
      fetchMachines();
    }
  }
};

onMounted(fetchMachines);
</script>

<style scoped>
.border-thin { border: 1px solid rgba(0,0,0,0.08) !important; }
.hover-bg-row:hover { background-color: #f5f7fa !important; }
.corporate-table th { opacity: 0.7; font-size: 11px; letter-spacing: 0.05em; border-bottom: 1px solid rgba(0,0,0,0.08); }
.corporate-table td { border-bottom: 1px solid rgba(0,0,0,0.05); }
.tracking-widest { letter-spacing: 0.05em; }
</style>