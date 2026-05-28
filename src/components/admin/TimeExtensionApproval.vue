<template>
  <v-container fluid>
    <v-row>
      <v-col cols="12">
        <v-card>
          <v-card-title class="d-flex align-center">
            Solicitações de Tempo Extra Pendentes
            <v-spacer></v-spacer>
             <v-btn icon @click="fetchRequests" :loading="loadingRequests" title="Atualizar Lista">
                <v-icon>mdi-refresh</v-icon>
            </v-btn>
          </v-card-title>
          <v-card-text>
            <v-data-table
              :headers="headers"
              :items="pendingRequests"
              :loading="loadingRequests"
              items-per-page="10"
              hover
            >
              <template v-slot:item.user_id="{ item }">
                {{ getUserName(item.user_id) || item.user_id.substring(0, 8) }}
              </template>
              <template v-slot:item.requested_at="{ item }">
                {{ formatDateTime(item.requested_at) }}
              </template>
              <template v-slot:item.duration_minutes="{ item }">
                {{ item.duration_minutes }} min
              </template>
              <template v-slot:item.actions="{ item }">
                 <v-tooltip location="top" text="Aprovar">
                    <template v-slot:activator="{ props }">
                      <v-btn
                        v-bind="props"
                        icon="mdi-check-circle"
                        color="success"
                        variant="text"
                        size="small"
                        class="me-1"
                        @click="reviewRequest(item, 'approved')"
                        :loading="isReviewing(item.id)"
                      ></v-btn>
                    </template>
                  </v-tooltip>
                 <v-tooltip location="top" text="Rejeitar">
                    <template v-slot:activator="{ props }">
                      <v-btn
                        v-bind="props"
                        icon="mdi-close-circle"
                        color="error"
                        variant="text"
                        size="small"
                        @click="reviewRequest(item, 'rejected')"
                         :loading="isReviewing(item.id)"
                      ></v-btn>
                    </template>
                  </v-tooltip>
              </template>
               <template v-slot:loading>
                <v-skeleton-loader type="table-row@5"></v-skeleton-loader>
              </template>
              <template v-slot:no-data>
                <v-alert type="success" class="mt-4" icon="mdi-check-all">Nenhuma solicitação pendente no momento.</v-alert>
              </template>
            </v-data-table>
          </v-card-text>
        </v-card>
      </v-col>
    </v-row>
    <v-snackbar v-model="snackbar.show" :color="snackbar.color" timeout="3000">
      {{ snackbar.text }}
    </v-snackbar>
  </v-container>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue';
import { supabase } from '@/api/supabase'; // Ajuste o caminho
import { useUserStore } from '@/stores/user'; // Ajuste o caminho
import type { RealtimeChannel } from '@supabase/supabase-js';

interface TimeExtensionRequest {
  id: number;
  user_id: string;
  requested_at: string;
  duration_minutes: number;
  status: 'pending' | 'approved' | 'rejected';
  approved_until?: string | null;
  reviewed_by?: string | null;
  reviewed_at?: string | null;
}

interface UserProfile {
  id: string;
  full_name: string;
}

const userStore = useUserStore();
const pendingRequests = ref<TimeExtensionRequest[]>([]);
const userList = ref<UserProfile[]>([]); // Para mapear ID para nome
const loadingRequests = ref(false);
const reviewingRequestId = ref<number | null>(null); // ID da requisição sendo processada
let realtimeChannel: RealtimeChannel | null = null;

const snackbar = ref({ show: false, text: '', color: 'info' });

const headers = [
  { title: 'Usuário', key: 'user_id', sortable: true },
  { title: 'Solicitado em', key: 'requested_at', sortable: true },
  { title: 'Duração', key: 'duration_minutes', sortable: false },
  { title: 'Ações', key: 'actions', sortable: false, align: 'end' },
] as const;

const isReviewing = (id: number) => reviewingRequestId.value === id;

const fetchUsers = async () => {
  try {
    // Tenta usar a lista da store SE ela existisse e tivesse dados
    // if (userStore.users && userStore.users.length > 0) {
    //    userList.value = userStore.users;
    // } else {
      // Como não existe, busca diretamente
      const { data, error } = await supabase
        .from('profiles')
        .select('id, full_name');
      if (error) throw error;
      userList.value = data || []; // Armazena localmente (CORRETO)

      // REMOVA A LINHA ABAIXO, pois a store não tem essa função
      // userStore.nomeCorretoDaAction(data || []);
    // }
  } catch (error: any) {
    console.error('Erro ao buscar usuários:', error.message);
    showSnackbar('Erro ao carregar lista de usuários.', 'error');
  }
};

const fetchRequests = async () => {
  loadingRequests.value = true;
  try {
    const { data, error } = await supabase
      .from('time_extension_requests')
      .select('*')
      .eq('status', 'pending')
      .order('requested_at', { ascending: true });

    if (error) throw error;
    pendingRequests.value = data || [];
  } catch (error: any) {
    console.error('Erro ao buscar solicitações pendentes:', error.message);
    showSnackbar('Erro ao buscar solicitações.', 'error');
  } finally {
    loadingRequests.value = false;
  }
};

const getUserName = (userId: string | null) => {
  if (!userId) return 'Desconhecido';
  const user = userList.value.find(u => u.id === userId);
  return user?.full_name || userId.substring(0, 8);
};

const formatDateTime = (dateTimeString: string | null | undefined) => {
  if (!dateTimeString) return '';
  try {
    return new Date(dateTimeString).toLocaleString('pt-BR');
  } catch {
    return dateTimeString; // Retorna original se falhar
  }
};

const reviewRequest = async (request: TimeExtensionRequest, decision: 'approved' | 'rejected') => {
  if (reviewingRequestId.value !== null) return; // Evita cliques duplos

  reviewingRequestId.value = request.id;
  const currentAdminUserId = userStore.user?.id; // Pega o ID do admin logado

  if (!currentAdminUserId) {
    showSnackbar('Erro: ID do administrador não encontrado.', 'error');
    reviewingRequestId.value = null;
    return;
  }

  try {
    const updateData: Partial<TimeExtensionRequest> = {
      status: decision,
      reviewed_by: currentAdminUserId,
      reviewed_at: new Date().toISOString(),
    };

    if (decision === 'approved') {
       // Calcula approved_until no lado do servidor OU cliente
       // Lado cliente (mais simples aqui, mas pode ter leve diferença de tempo):
       const now = new Date();
       const approvedUntil = new Date(now.getTime() + request.duration_minutes * 60000);
       updateData.approved_until = approvedUntil.toISOString();
    }

    const { error } = await supabase
      .from('time_extension_requests')
      .update(updateData)
      .eq('id', request.id)
       .eq('status', 'pending'); // Garante que só atualize se ainda estiver pendente

    if (error) {
       // Verifica se o erro é porque o registro não foi encontrado (talvez já revisado)
       if (error.code === 'PGRST116') { // Código de erro do PostgREST para 0 linhas afetadas
            showSnackbar('Esta solicitação já foi revisada por outro administrador.', 'warning');
            // Remove da lista local otimisticamente
            pendingRequests.value = pendingRequests.value.filter(r => r.id !== request.id);
       } else {
            throw error; // Lança outros erros
       }
    } else {
      showSnackbar(`Solicitação ${decision === 'approved' ? 'aprovada' : 'rejeitada'}.`, decision === 'approved' ? 'success' : 'info');
      // Remove da lista local otimisticamente
      pendingRequests.value = pendingRequests.value.filter(r => r.id !== request.id);
    }
  } catch (error: any) {
    console.error(`Erro ao ${decision} solicitação:`, error.message);
    showSnackbar(`Erro ao ${decision === 'approved' ? 'aprovar' : 'rejeitar'} solicitação.`, 'error');
  } finally {
    reviewingRequestId.value = null;
  }
};

const setupRealtime = () => {
    if (realtimeChannel) return; // Já está escutando

    console.log('[REALTIME][ADMIN] Configurando listener para novas solicitações pendentes.');
    realtimeChannel = supabase
        .channel('new-pending-requests')
        .on(
            'postgres_changes',
            {
                event: 'INSERT',
                schema: 'public',
                table: 'time_extension_requests',
                filter: 'status=eq.pending' // Escuta apenas novas inserções pendentes
            },
            (payload) => {
                console.log('[REALTIME][ADMIN] Nova solicitação pendente recebida:', payload);
                const newRequest = payload.new as TimeExtensionRequest;
                // Adiciona na lista se não existir (evita duplicação caso fetch ocorra ao mesmo tempo)
                if (!pendingRequests.value.some(r => r.id === newRequest.id)) {
                    pendingRequests.value.unshift(newRequest); // Adiciona no início
                    showSnackbar(`Nova solicitação de ${getUserName(newRequest.user_id)} recebida.`, 'info');
                }
            }
        )
        // Adiciona listener para UPDATES também, para remover caso outro admin aprove/rejeite
         .on(
            'postgres_changes',
            {
                event: 'UPDATE',
                schema: 'public',
                table: 'time_extension_requests',
                filter: 'status=neq.pending' // Escuta quando status DEIXA de ser pending
            },
            (payload) => {
                 console.log('[REALTIME][ADMIN] Solicitação deixou de ser pendente:', payload);
                 const reviewedRequest = payload.old as Partial<TimeExtensionRequest>; // Pega o ID do old
                 if (reviewedRequest.id) {
                     const index = pendingRequests.value.findIndex(r => r.id === reviewedRequest.id);
                     if (index > -1) {
                         console.log(`[REALTIME][ADMIN] Removendo solicitação ${reviewedRequest.id} da lista.`);
                         pendingRequests.value.splice(index, 1);
                     }
                 }
            }
         )
        .subscribe((status, err) => {
            if (status === 'SUBSCRIBED') {
                console.log('[REALTIME][ADMIN] Conectado ao canal de solicitações.');
            } else if (status === 'CHANNEL_ERROR' || status === 'TIMED_OUT') {
                console.error('[REALTIME][ADMIN] Erro no canal de solicitações:', err || status);
                showSnackbar('Erro de conexão com atualizações em tempo real.', 'error');
            } else if (status === 'CLOSED') {
                 console.log('[REALTIME][ADMIN] Canal de solicitações fechado.');
             }
        });
}

const removeRealtime = async () => {
    if (realtimeChannel) {
        console.log('[REALTIME][ADMIN] Removendo listener de solicitações.');
        try {
            await supabase.removeChannel(realtimeChannel);
            console.log('[REALTIME][ADMIN] Canal removido.');
        } catch (error) {
            console.error('[REALTIME][ADMIN] Erro ao remover canal:', error);
        } finally {
             realtimeChannel = null;
        }
    }
}

const showSnackbar = (text: string, color: string = 'info') => {
  snackbar.value = { show: true, text, color };
};

onMounted(async () => {
  await fetchUsers(); // Precisa dos nomes
  await fetchRequests();
  setupRealtime(); // Começa a ouvir por novas solicitações
});

onUnmounted(() => {
  removeRealtime(); // Limpa o listener ao sair do componente
});
</script>

<style scoped>
/* Estilos se necessário */
.v-data-table {
  min-height: 200px;
}
</style>
