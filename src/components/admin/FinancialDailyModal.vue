<template>
  <v-dialog
    v-model="show"
    max-width="850"
    scrollable
    transition="dialog-bottom-transition"
    persistent
  >
    <v-card class="rounded-xl shadow-lg border-thin overflow-hidden d-flex flex-column" :class="isDark ? 'bg-grey-darken-4' : 'bg-white'" max-height="85vh">

      <div class="px-6 py-4 flex-shrink-0 d-flex align-center justify-space-between border-b" :class="isDark ? 'border-grey-darken-3 bg-grey-darken-4' : 'border-grey-lighten-2 bg-white'">
        <div class="d-flex align-center gap-3">
          <v-avatar :color="isDark ? 'grey-darken-3' : 'grey-lighten-3'" rounded="lg" size="42" class="border-thin">
            <v-icon size="24" :color="isDark ? 'primary-lighten-1' : 'primary'">mdi-calendar-check-outline</v-icon>
          </v-avatar>
          <div>
            <h2 class="text-subtitle-1 font-weight-black lh-1" :class="isDark ? 'text-white' : 'text-grey-darken-4'">Resumo Financeiro Diário</h2>
            <div class="text-caption font-weight-medium mt-1 d-flex align-center gap-2" :class="isDark ? 'text-grey-lighten-1' : 'text-grey-darken-1'">
              <v-icon size="14">mdi-calendar-today</v-icon> Hoje, {{ todayFormatted }}
            </div>
          </div>
        </div>
        <v-btn icon variant="text" :color="isDark ? 'grey-lighten-1' : 'grey-darken-2'" density="comfortable" @click="closeModal">
          <v-icon>mdi-close</v-icon>
        </v-btn>
      </div>

      <div class="px-6 py-4 border-b flex-shrink-0" :class="isDark ? 'bg-grey-darken-4 border-grey-darken-3' : 'bg-grey-lighten-5 border-grey-lighten-2'">
          <v-row dense>
              <v-col cols="12" sm="4">
                  <div class="pa-4 rounded-lg border-thin" :class="isDark ? 'bg-grey-darken-3 border-grey-darken-2' : 'bg-white border-grey-lighten-2'">
                      <div class="text-[11px] font-weight-bold text-uppercase opacity-70 mb-1 d-flex align-center gap-2">
                          <v-icon size="14">mdi-cash-register</v-icon> Previsão Total
                      </div>
                      <div class="text-h5 font-weight-black">{{ formatCurrency(kpis.total) }}</div>
                      <div class="text-[11px] font-weight-medium opacity-60 mt-1">{{ kpis.count }} título(s) para hoje</div>
                  </div>
              </v-col>
              <v-col cols="12" sm="4">
                  <div class="pa-4 rounded-lg border-thin" :class="isDark ? 'bg-success-darken-4/10 border-success/30' : 'bg-success-lighten-5 border-success-lighten-4'">
                      <div class="text-[11px] font-weight-bold text-uppercase text-success mb-1 d-flex align-center gap-2">
                          <v-icon size="14">mdi-check-all</v-icon> Já Recebido
                      </div>
                      <div class="text-h5 font-weight-black text-success">{{ formatCurrency(kpis.paid) }}</div>
                      <div class="text-[11px] font-weight-medium mt-1 text-success opacity-80">{{ kpis.paidCount }} título(s) liquidado(s)</div>
                  </div>
              </v-col>
              <v-col cols="12" sm="4">
                  <div class="pa-4 rounded-lg border-thin" :class="isDark ? 'bg-warning-darken-4/10 border-warning/30' : 'bg-orange-lighten-5 border-warning-lighten-4'">
                      <div class="text-[11px] font-weight-bold text-uppercase text-warning mb-1 d-flex align-center gap-2">
                          <v-icon size="14">mdi-clock-outline</v-icon> Pendente
                      </div>
                      <div class="text-h5 font-weight-black text-warning">{{ formatCurrency(kpis.pending) }}</div>
                      <div class="text-[11px] font-weight-medium mt-1 text-warning opacity-80">{{ kpis.pendingCount }} título(s) em aberto</div>
                  </div>
              </v-col>
          </v-row>
      </div>

      <div class="flex-grow-1 overflow-y-auto pa-0 custom-scrollbar" :class="isDark ? 'bg-grey-darken-4' : 'bg-white'">
          <div v-if="loading" class="pa-12 d-flex flex-column align-center justify-center opacity-60">
              <v-progress-circular indeterminate size="40" width="3" color="primary"></v-progress-circular>
              <span class="text-caption mt-4 font-weight-bold text-uppercase letter-spacing-1">Consultando Receitas...</span>
          </div>

          <div v-else-if="todayReceivables.length === 0" class="pa-16 text-center opacity-50">
              <v-icon size="64" class="mb-4">mdi-check-circle-outline</v-icon>
              <div class="text-subtitle-1 font-weight-bold">Tudo em dia!</div>
              <div class="text-caption">Não há nenhuma previsão de recebimento para hoje.</div>
          </div>

          <v-table v-else density="comfortable" class="clean-table" :class="isDark ? 'bg-grey-darken-4' : 'bg-white'">
              <thead :class="isDark ? 'bg-grey-darken-3' : 'bg-grey-lighten-4'">
                  <tr>
                      <th class="text-left font-weight-bold text-uppercase text-[10px] pl-6">Ref / Pedido</th>
                      <th class="text-left font-weight-bold text-uppercase text-[10px]">Cliente</th>
                      <th class="text-left font-weight-bold text-uppercase text-[10px]">Vendedor</th>
                      <th class="text-left font-weight-bold text-uppercase text-[10px]">Método Prev.</th>
                      <th class="text-center font-weight-bold text-uppercase text-[10px]">Status</th>
                      <th class="text-right font-weight-bold text-uppercase text-[10px] pr-6">Valor (R$)</th>
                  </tr>
              </thead>
              <tbody>
                  <tr v-for="rec in todayReceivables" :key="rec.id" class="transition-all hover-row">
                      <td class="pl-6 py-3">
                          <div class="d-flex flex-column">
                              <span class="font-mono text-[12px] font-weight-bold" :class="isDark ? 'text-white' : 'text-grey-darken-4'">#{{ rec.orders?.order_number || 'S/N' }}</span>
                              <span class="text-[10px] opacity-50 mt-1">{{ String(rec.id).slice(0,6) }}</span>
                          </div>
                      </td>
                      <td class="py-3">
                          <span class="text-[12px] font-weight-medium text-truncate d-inline-block" style="max-width: 180px;" :title="rec.orders?.customer_name">
                              {{ rec.orders?.customer_name || 'Diversos / Balcão' }}
                          </span>
                      </td>
                      <td class="py-3">
                          <div class="d-flex align-center gap-2">
                              <v-avatar size="22" :color="isDark ? 'grey-darken-3' : 'grey-lighten-2'" class="border-thin">
                                  <span class="text-[9px] font-weight-bold">{{ getInitials(rec.vendedor_nome) }}</span>
                              </v-avatar>
                              <span class="text-[11px] font-weight-medium opacity-80">{{ rec.vendedor_nome || 'N/A' }}</span>
                          </div>
                      </td>
                      <td class="py-3">
                          <v-chip size="small" variant="outlined" :color="isDark ? 'grey-lighten-1' : 'grey-darken-1'" class="font-weight-bold text-[10px] rounded-md px-2">
                              {{ rec.payment_method?.name || 'Não Def.' }}
                          </v-chip>
                      </td>
                      <td class="py-3 text-center">
                          <v-chip size="small" :color="rec.status === 'pago' ? 'success' : 'warning'" variant="flat" class="font-weight-bold text-[10px] rounded-md text-white">
                              {{ rec.status === 'pago' ? 'PAGO' : 'ABERTO' }}
                          </v-chip>
                      </td>
                      <td class="pr-6 py-3 text-right">
                          <span class="font-mono text-[13px] font-weight-black" :class="rec.status === 'pago' ? 'text-success' : (isDark ? 'text-white' : 'text-grey-darken-4')">
                              {{ formatCurrency(rec.value) }}
                          </span>
                      </td>
                  </tr>
              </tbody>
          </v-table>
      </div>

      <div class="px-6 py-4 border-t flex-shrink-0 d-flex justify-space-between align-center" :class="isDark ? 'border-grey-darken-3 bg-grey-darken-4' : 'border-grey-lighten-2 bg-grey-lighten-5'">
          <v-checkbox-btn v-model="dontShowAgain" color="primary" density="compact" hide-details>
              <template v-slot:label>
                  <span class="text-[12px] font-weight-medium opacity-80 ml-2">Não exibir novamente hoje</span>
              </template>
          </v-checkbox-btn>

          <div class="d-flex gap-3">
              <v-btn variant="outlined" :color="isDark ? 'grey-lighten-1' : 'grey-darken-2'" class="rounded-lg font-weight-bold text-none px-4" @click="closeModal">
                Fechar
              </v-btn>
              <v-btn color="primary" variant="flat" class="rounded-lg font-weight-bold text-none px-6 shadow-sm" @click="goToFinanceiro">
                  Ir para Recebimentos <v-icon end size="16">mdi-arrow-right</v-icon>
              </v-btn>
          </div>
      </div>
    </v-card>
  </v-dialog>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { supabase } from '@/api/supabase';
import { useUserStore } from '@/stores/user';
import { useThemeStore } from '@/stores/theme';
import { format } from 'date-fns';
import { ptBR } from 'date-fns/locale';
import { useRouter } from 'vue-router';

const show = ref(false);
const loading = ref(false);
const dontShowAgain = ref(false);
const todayReceivables = ref<any[]>([]);

const userStore = useUserStore();
const themeStore = useThemeStore();
const router = useRouter();

const isDark = computed(() => themeStore.currentMode === 'dark');
const todayFormatted = computed(() => format(new Date(), "dd 'de' MMMM", { locale: ptBR }));

const kpis = computed(() => {
    let total = 0, paid = 0, pending = 0;
    let paidCount = 0, pendingCount = 0;

    todayReceivables.value.forEach(rec => {
        const val = Number(rec.value || 0);
        total += val;
        if (rec.status === 'pago') {
            paid += val;
            paidCount++;
        } else {
            pending += val;
            pendingCount++;
        }
    });

    return { total, paid, pending, count: todayReceivables.value.length, paidCount, pendingCount };
});

const formatCurrency = (val: number) => new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(val);
const getInitials = (name: string) => {
    if (!name) return '-';
    const parts = name.split(' ');
    return parts.length > 1 ? (parts[0][0] + parts[1][0]).toUpperCase() : parts[0].substring(0, 2).toUpperCase();
};

const closeModal = () => {
    if (dontShowAgain.value) {
        const todayStr = format(new Date(), 'yyyy-MM-dd');
        localStorage.setItem(`finance_daily_hidden_${userStore.user?.id}`, todayStr);
    }
    show.value = false;
};

const goToFinanceiro = () => {
    closeModal();
    router.push({ name: 'FinancialReceivables' });
};

const checkAndLoad = async () => {
    if (!userStore.profile) await userStore.fetchProfile();

    const isFinanceiro = userStore.profile?.custom_role_id?.toLowerCase() === 'financeiro' ||
                         userStore.profile?.role?.toLowerCase() === 'admin' ||
                         userStore.profile?.role?.toLowerCase() === 'super_admin';

    if (!isFinanceiro) return;

    const todayStr = format(new Date(), 'yyyy-MM-dd');
    const hiddenFlag = localStorage.getItem(`finance_daily_hidden_${userStore.user?.id}`);
    const sessionFlag = sessionStorage.getItem('finance_daily_shown_this_session');

    if (hiddenFlag === todayStr || sessionFlag) return;

    loading.value = true;
    show.value = true;
    sessionStorage.setItem('finance_daily_shown_this_session', 'true');

    try {
        // CORREÇÃO: O campo na tabela orders é 'user_id' e não 'vendedor_id'
        const { data, error } = await supabase
            .from('finance_receivables')
            .select(`
                id, value, status, description, due_date,
                payment_method:finance_payment_methods(name),
                orders ( order_number, customer_name, user_id )
            `)
            .eq('due_date', todayStr)
            .neq('status', 'cancelado')
            .order('status', { ascending: false });

        if (error) throw error;

        const recs = data || [];
        const sellerIds = [...new Set(recs.map(r => r.orders?.user_id).filter(Boolean))];

        let sellersMap: Record<string, string> = {};
        if (sellerIds.length > 0) {
            const { data: profiles } = await supabase.from('profiles').select('id, full_name').in('id', sellerIds);
            if (profiles) {
                profiles.forEach(p => sellersMap[p.id] = p.full_name);
            }
        }

        todayReceivables.value = recs.map(r => ({
            ...r,
            vendedor_nome: r.orders?.user_id ? sellersMap[r.orders.user_id] : null
        }));

    } catch (err) {
        console.error('Erro ao buscar daily financeiro:', err);
    } finally {
        loading.value = false;
    }
};

onMounted(() => {
    setTimeout(checkAndLoad, 800);
});
</script>

<style scoped>
.font-sans { font-family: 'Inter', system-ui, sans-serif; }
.border-thin { border: 1px solid rgba(128,128,128, 0.15) !important; }
.lh-1 { line-height: 1.1; }
.letter-spacing-1 { letter-spacing: 0.05em; }
.font-mono { font-family: 'JetBrains Mono', monospace !important; }

/* Tabela Nativa Clean */
.clean-table { background: transparent !important; }
.clean-table th { border-bottom: 1px solid rgba(128,128,128, 0.1) !important; color: inherit; opacity: 0.7; }
.clean-table td { border-bottom: 1px solid rgba(128,128,128, 0.05) !important; }
.hover-row:hover td { background-color: rgba(128,128,128, 0.04) !important; cursor: default; }

.custom-scrollbar::-webkit-scrollbar { width: 6px; }
.custom-scrollbar::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.2); border-radius: 10px; }
.transition-all { transition: all 0.2s ease-in-out; }
</style>
