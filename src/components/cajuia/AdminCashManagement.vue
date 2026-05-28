<template>
  <div class="d-flex flex-column h-100 w-100 pa-6">

      <div class="d-flex align-end justify-space-between mb-6 flex-shrink-0">
          <div>
             <h2 class="text-h5 font-weight-black text-white text-shadow">Auditoria de Caixa (MJ)</h2>
             <div class="text-caption text-white-50 mt-1">Controle de sessões, aberturas e fechamentos por loja.</div>
          </div>

          <div class="d-flex align-center gap-3">
             <div style="width: 200px;">
                <v-select
                    v-model="selectedStore"
                    :items="stores"
                    item-title="name"
                    item-value="id"
                    label="Filtrar Loja"
                    variant="solo"
                    density="compact"
                    hide-details
                    bg-color="rgba(255,255,255,0.05)"
                    class="glass-select"
                    @update:model-value="fetchData"
                ></v-select>
             </div>

             <div class="glass-panel px-1 py-1 rounded-lg border-white-10 d-flex align-center">
                 <v-btn icon size="small" variant="text" @click="changeDate(-1)" color="white-70"><v-icon>mdi-chevron-left</v-icon></v-btn>
                 <div class="px-3 text-center" style="min-width: 140px;">
                     <div class="text-[10px] text-white-50 font-weight-bold text-uppercase">Data Base</div>
                     <div class="text-body-2 font-weight-bold text-white d-flex align-center justify-center gap-2">
                         <v-icon size="14" color="primary">mdi-calendar</v-icon> {{ formattedDate }}
                     </div>
                 </div>
                 <v-btn icon size="small" variant="text" @click="changeDate(1)" color="white-70"><v-icon>mdi-chevron-right</v-icon></v-btn>
             </div>

             <v-btn icon size="small" variant="text" class="glass-btn-icon" @click="fetchData" :loading="loading">
                <v-icon color="white">mdi-refresh</v-icon>
             </v-btn>
          </div>
      </div>

      <div class="d-flex gap-4 mb-6 flex-shrink-0">
           <div class="glass-stat-card flex-grow-1 pa-4 rounded-xl d-flex align-center hover-glow border-l-info">
              <div class="icon-box bg-info-10 mr-4 rounded-lg"><v-icon color="info" size="24">mdi-cash-plus</v-icon></div>
              <div>
                  <div class="text-[10px] text-white-50 font-weight-bold text-uppercase letter-spacing-1">Vendas (Dinheiro)</div>
                  <div class="text-h5 font-weight-black text-white">{{ formatCurrency(dailyStats.salesCash) }}</div>
              </div>
           </div>

           <div class="glass-stat-card flex-grow-1 pa-4 rounded-xl d-flex align-center hover-glow border-l-success">
              <div class="icon-box bg-success-10 mr-4 rounded-lg"><v-icon color="success" size="24">mdi-bank-transfer-in</v-icon></div>
              <div>
                  <div class="text-[10px] text-white-50 font-weight-bold text-uppercase letter-spacing-1">Suprimentos</div>
                  <div class="text-h5 font-weight-black text-white">{{ formatCurrency(dailyStats.supply) }}</div>
              </div>
           </div>

           <div class="glass-stat-card flex-grow-1 pa-4 rounded-xl d-flex align-center hover-glow border-l-error">
              <div class="icon-box bg-error-10 mr-4 rounded-lg"><v-icon color="error" size="24">mdi-bank-transfer-out</v-icon></div>
              <div>
                  <div class="text-[10px] text-white-50 font-weight-bold text-uppercase letter-spacing-1">Sangrias</div>
                  <div class="text-h5 font-weight-black text-white">{{ formatCurrency(dailyStats.bleed) }}</div>
              </div>
           </div>

           <div class="glass-stat-card flex-grow-1 pa-4 rounded-xl d-flex align-center hover-glow" :class="dailyStats.difference < 0 ? 'border-l-error' : 'border-l-primary'">
              <div class="icon-box mr-4 rounded-lg" :class="dailyStats.difference < 0 ? 'bg-error-10' : 'bg-primary-10'">
                  <v-icon :color="dailyStats.difference < 0 ? 'error' : 'primary'" size="24">mdi-scale-balance</v-icon>
              </div>
              <div>
                  <div class="text-[10px] text-white-50 font-weight-bold text-uppercase letter-spacing-1">Quebra/Sobra</div>
                  <div class="text-h5 font-weight-black" :class="dailyStats.difference < 0 ? 'text-error' : 'text-white'">
                      {{ formatCurrency(dailyStats.difference) }}
                  </div>
              </div>
           </div>
      </div>

      <div class="d-flex flex-grow-1 overflow-hidden gap-4">
          <div class="glass-panel width-300 d-flex flex-column rounded-xl overflow-hidden flex-shrink-0">
              <div class="px-4 py-3 border-b border-white-10 bg-glass-header">
                  <h3 class="text-subtitle-2 font-weight-bold text-white">Sessões (Turnos)</h3>
                  <div class="text-caption text-white-50">{{ sessions.length }} registros encontrados</div>
              </div>
              <div class="flex-grow-1 overflow-y-auto custom-scrollbar pa-2">
                  <div v-if="sessions.length === 0" class="text-center py-8 text-white-30 text-caption">
                      Nenhuma sessão nesta loja/data.
                  </div>
                  <div
                    v-for="session in sessions"
                    :key="session.id"
                    class="session-card pa-3 mb-2 rounded-lg border border-white-05 cursor-pointer transition-all"
                    :class="selectedSession?.id === session.id ? 'bg-white-10 border-primary' : 'hover-bg-white-05'"
                    @click="selectSession(session)"
                  >
                      <div class="d-flex align-center justify-space-between mb-2">
                          <div class="d-flex align-center gap-2">
                              <v-avatar size="24" color="primary" class="text-caption font-weight-bold text-white">
                                  {{ getInitials(session.user_name) }}
                              </v-avatar>
                              <div class="text-caption font-weight-bold text-white text-truncate width-120">
                                  {{ session.user_name }}
                              </div>
                          </div>
                          <v-chip size="x-small" :color="session.status === 'open' ? 'success' : 'grey'" variant="flat" class="font-weight-bold px-2 h-16">
                              {{ session.status === 'open' ? 'ABERTO' : 'FECHADO' }}
                          </v-chip>
                      </div>
                      <div class="d-flex justify-space-between text-[10px] text-white-50">
                          <span>Abertura: {{ formatTime(session.opened_at) }}</span>
                          <span v-if="session.closed_at">Fechamento: {{ formatTime(session.closed_at) }}</span>
                      </div>
                  </div>
              </div>
          </div>

          <div class="glass-panel flex-grow-1 d-flex flex-column rounded-xl overflow-hidden">
              <div class="px-6 py-4 border-b border-white-10 bg-glass-header d-flex justify-space-between align-center">
                  <div v-if="selectedSession">
                      <h3 class="text-subtitle-1 font-weight-bold text-white">Extrato do Caixa</h3>
                      <div class="text-caption text-white-50 d-flex align-center gap-2">
                          ID: <span class="font-mono text-white-70">{{ selectedSession.id.split('-')[0] }}...</span>
                          <v-icon size="4" color="white-30">mdi-circle</v-icon>
                          Fundo Inicial: <span class="text-white font-weight-bold">{{ formatCurrency(selectedSession.initial_balance) }}</span>
                      </div>
                  </div>
                  <div v-else class="text-white-50 font-italic">Selecione uma sessão ao lado</div>
              </div>

              <div class="flex-grow-1 overflow-y-auto custom-scrollbar pa-0 bg-glass-body-gradient relative">

                  <div v-if="!selectedSession" class="absolute-center d-flex flex-column align-center text-white-30">
                      <v-icon size="48" class="mb-2 opacity-20">mdi-cash-multiple</v-icon>
                      <span>Selecione um operador para auditar</span>
                  </div>

                  <v-table v-else density="comfortable" class="bg-transparent text-white w-100 hover-rows">
                      <thead class="bg-glass-darker sticky-top backdrop-blur z-10">
                          <tr>
                              <th class="text-left text-white-30 text-[10px] text-uppercase font-weight-bold pl-6 w-15">Hora</th>
                              <th class="text-left text-white-30 text-[10px] text-uppercase font-weight-bold w-15">Tipo</th>
                              <th class="text-left text-white-30 text-[10px] text-uppercase font-weight-bold w-40">Histórico</th>
                              <th class="text-right text-white-30 text-[10px] text-uppercase font-weight-bold pr-6 w-30">Valor</th>
                          </tr>
                      </thead>
                      <tbody>
                          <tr class="bg-white-02">
                              <td class="pl-6 py-3 text-caption font-mono text-white-50">{{ formatTime(selectedSession.opened_at) }}</td>
                              <td><v-chip size="x-small" color="info" variant="tonal" class="font-weight-bold">ABERTURA</v-chip></td>
                              <td class="text-caption text-white font-weight-bold">Fundo de Troco (Saldo Inicial)</td>
                              <td class="text-right pr-6 font-mono font-weight-bold text-info">+ {{ formatCurrency(selectedSession.initial_balance) }}</td>
                          </tr>

                          <tr v-for="move in movements" :key="move.id" class="border-b border-white-05 transition-colors group">
                              <td class="pl-6 py-3 text-caption font-mono text-white-70">{{ formatTime(move.created_at) }}</td>
                              <td>
                                  <v-chip size="x-small" :color="getTypeColor(move.type)" variant="tonal" class="font-weight-bold text-uppercase border-none">
                                      {{ getTypeLabel(move.type) }}
                                  </v-chip>
                              </td>
                              <td>
                                  <div class="d-flex flex-column">
                                      <span class="text-caption text-white font-weight-medium">{{ move.description || '-' }}</span>
                                      <span v-if="move.order_id" class="text-[10px] text-primary cursor-pointer hover-underline">
                                          Ref: Pedido ID ...{{ move.order_id.substring(0, 6) }}
                                      </span>
                                  </div>
                              </td>
                              <td class="text-right pr-6">
                                  <span class="font-mono font-weight-bold" :class="Number(move.amount) >= 0 ? 'text-success' : 'text-error'">
                                      {{ Number(move.amount) >= 0 ? '+' : '' }} {{ formatCurrency(move.amount) }}
                                  </span>
                              </td>
                          </tr>

                          <tr v-if="selectedSession.status === 'closed'" class="bg-white-05 border-t border-white-10">
                              <td class="pl-6 py-4 text-caption font-mono text-white-50">{{ formatTime(selectedSession.closed_at) }}</td>
                              <td><v-chip size="x-small" color="warning" variant="flat" class="font-weight-black text-black">FECHAMENTO</v-chip></td>
                              <td>
                                  <div class="d-flex flex-column">
                                      <span class="text-caption text-white font-weight-bold">Conferência (Contagem Cega)</span>
                                      <span v-if="selectedSession.notes" class="text-[10px] text-white-50 font-italic">Obs: "{{ selectedSession.notes }}"</span>
                                  </div>
                              </td>
                              <td class="text-right pr-6">
                                  <div class="d-flex flex-column align-end">
                                      <span class="text-caption text-white-50">Informado: {{ formatCurrency(selectedSession.final_balance_user) }}</span>
                                      <span class="text-caption" :class="Number(selectedSession.difference) === 0 ? 'text-success' : 'text-error'">
                                          Dif: {{ formatCurrency(selectedSession.difference) }}
                                      </span>
                                  </div>
                              </td>
                          </tr>
                      </tbody>
                  </v-table>
              </div>
          </div>
      </div>

  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { supabase } from '@/api/supabase'
import { format, parseISO, addDays, startOfDay, endOfDay } from 'date-fns'
import { ptBR } from 'date-fns/locale'
import { useUserStore } from '@/stores/user'

const userStore = useUserStore()
const currentDate = ref(new Date())
const loading = ref(false)
const sessions = ref<any[]>([])
const selectedSession = ref<any>(null)
const movements = ref<any[]>([])
const stores = ref<any[]>([])
const selectedStore = ref<string | null>(null)

const dailyStats = ref({ salesCash: 0, supply: 0, bleed: 0, difference: 0 })

const formattedDate = computed(() => format(currentDate.value, "dd 'de' MMMM, yyyy", { locale: ptBR }))

const changeDate = (days: number) => { currentDate.value = addDays(currentDate.value, days); fetchData(); }

const init = async () => {
    const { data } = await supabase.from('stores').select('id, name').eq('active', true)
    stores.value = data || []
    if (userStore.activeStoreId) selectedStore.value = userStore.activeStoreId
    else if (stores.value.length > 0) selectedStore.value = stores.value[0].id

    fetchData()
}

const fetchData = async () => {
    if (!selectedStore.value) return
    loading.value = true
    selectedSession.value = null
    movements.value = []

    try {
        const start = startOfDay(currentDate.value).toISOString()
        const end = endOfDay(currentDate.value).toISOString()

        // 1. BUSCA SESSÕES SEM JOIN DE USUÁRIO (Para evitar erro)
        const { data: sess, error: sessError } = await supabase
            .from('mj_cash_sessions')
            .select('*')
            .eq('store_id', selectedStore.value)
            .gte('opened_at', start)
            .lte('opened_at', end)
            .order('opened_at', { ascending: false })

        if(sessError) throw sessError

        // 2. BUSCA PERFIS MANUALMENTE
        let profiles: any[] = []
        if (sess && sess.length > 0) {
            const userIds = sess.map(s => s.user_id)
            const { data: profs } = await supabase.from('profiles').select('id, full_name, email').in('id', userIds)
            profiles = profs || []
        }

        sessions.value = (sess || []).map(s => {
            const p = profiles.find(profile => profile.id === s.user_id)
            return {
                ...s,
                user_name: p?.full_name || p?.email || 'Usuário'
            }
        })

        // 3. CALCULA KPIs
        const sessionIds = sessions.value.map(s => s.id)
        let allMoves: any[] = []
        if(sessionIds.length > 0) {
             const { data } = await supabase.from('mj_cash_movements').select('*').in('session_id', sessionIds)
             allMoves = data || []
        }

        let sales = 0, supp = 0, bld = 0
        allMoves.forEach(m => {
            const val = Number(m.amount)
            if(m.type === 'sale_cash') sales += val
            if(m.type === 'supply') supp += val
            if(m.type === 'bleed') bld += Math.abs(val)
        })
        const diff = sessions.value.reduce((acc, s) => acc + (Number(s.difference) || 0), 0)

        dailyStats.value = { salesCash: sales, supply: supp, bleed: bld, difference: diff }

        if(sessions.value.length > 0) selectSession(sessions.value[0])

    } catch(e) { console.error(e) } finally { loading.value = false }
}

const selectSession = async (session: any) => {
    selectedSession.value = session
    const { data } = await supabase
        .from('mj_cash_movements')
        .select('*')
        .eq('session_id', session.id)
        .order('created_at', { ascending: true })
    movements.value = data || []
}

const formatCurrency = (val: any) => new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(Number(val) || 0)
const formatTime = (d: string) => d ? format(parseISO(d), 'HH:mm') : '-'
const getInitials = (name: string) => name ? name.substring(0, 2).toUpperCase() : '??'
const getTypeColor = (type: string) => ({ 'sale_cash': 'success', 'supply': 'info', 'bleed': 'error' }[type] || 'grey')
const getTypeLabel = (type: string) => ({ 'sale_cash': 'VENDA', 'supply': 'SUPRIMENTO', 'bleed': 'SANGRIA', 'opening': 'ABERTURA' }[type] || type.toUpperCase())

onMounted(init)
</script>

<style scoped lang="scss">
/* Glass Layout */
.glass-panel, .glass-stat-card {
    background: rgba(30, 30, 35, 0.4);
    backdrop-filter: blur(12px);
    border: 1px solid rgba(255, 255, 255, 0.08);
    box-shadow: 0 8px 32px rgba(0,0,0,0.2);
}
.bg-glass-header { background: rgba(255, 255, 255, 0.03); }
.bg-glass-darker { background: rgba(14, 14, 16, 0.6); }
.bg-glass-body-gradient { background: linear-gradient(to bottom, rgba(255,255,255,0.01), transparent); }

/* Cards & Lists */
.session-card { background: rgba(255,255,255,0.02); }
.hover-bg-white-05:hover { background: rgba(255,255,255,0.05); }
.border-primary { border-color: rgb(var(--v-theme-primary)) !important; }

/* Text & Icons */
.text-shadow { text-shadow: 0 2px 10px rgba(0,0,0,0.5); }
.icon-box { width: 48px; height: 48px; display: flex; align-items: center; justify-content: center; }
.bg-info-10 { background: rgba(var(--v-theme-info), 0.15); }
.bg-success-10 { background: rgba(0, 230, 118, 0.15); }
.bg-error-10 { background: rgba(255, 82, 82, 0.15); }
.bg-primary-10 { background: rgba(var(--v-theme-primary), 0.15); }

.border-l-info { border-left: 4px solid rgb(var(--v-theme-info)); }
.border-l-success { border-left: 4px solid #00e676; }
.border-l-error { border-left: 4px solid #ff5252; }
.border-l-primary { border-left: 4px solid rgb(var(--v-theme-primary)); }

/* Utils */
.width-300 { width: 300px; }
.width-120 { width: 120px; }
.h-16 { height: 16px; }
.text-white-30 { color: rgba(255,255,255,0.3) !important; }
.text-white-50 { color: rgba(255,255,255,0.5) !important; }
.border-white-05 { border-color: rgba(255, 255, 255, 0.05) !important; }
.border-white-10 { border-color: rgba(255, 255, 255, 0.1) !important; }
.glass-btn-icon { background: rgba(255,255,255,0.05); border-radius: 8px; &:hover { background: rgba(255,255,255,0.1); } }
.glass-select :deep(.v-field) { border-radius: 8px !important; border: 1px solid rgba(255,255,255,0.1); color: white !important; }
.hover-underline:hover { text-decoration: underline; }
.absolute-center { position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%); }
.sticky-top { position: sticky; top: 0; z-index: 5; }

/* Scrollbar */
.custom-scrollbar::-webkit-scrollbar { width: 6px; }
.custom-scrollbar::-webkit-scrollbar-track { background: rgba(0,0,0,0.1); }
.custom-scrollbar::-webkit-scrollbar-thumb { background: rgba(255, 255, 255, 0.15); border-radius: 3px; }
</style>
