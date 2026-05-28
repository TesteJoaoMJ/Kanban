<template>
  <div
    class="leads-layout font-sans fill-height d-flex flex-column relative overflow-hidden w-100"
    :class="isDark ? 'bg-glass-dark text-white' : 'bg-grey-lighten-5 text-grey-darken-4'"
  >
    <div v-if="isDark" class="background-carousel-wrapper">
      <v-carousel cycle height="100%" hide-delimiters :show-arrows="false" interval="15000" class="fill-height">
        <v-carousel-item src="@/assets/1.jpg" cover></v-carousel-item>
        <v-carousel-item src="@/assets/2.jpg" cover></v-carousel-item>
        <v-carousel-item src="@/assets/3.jpg" cover></v-carousel-item>
      </v-carousel>
      <div class="background-overlay"></div>
    </div>

    <div class="content-wrapper d-flex flex-column fill-height z-10 w-100">

      <div
        class="header-bar px-4 py-3 px-md-6 py-md-4 d-flex flex-column flex-md-row align-md-start justify-space-between flex-shrink-0 w-100"
        :class="isDark ? 'bg-glass-header border-bottom-white-05' : 'bg-white border-b border-grey-lighten-2 shadow-sm'"
      >
        <div class="d-flex flex-column">
          <div class="breadcrumb text-caption d-none d-md-block">
            <span class="opacity-70">Marketplace</span>
            <span class="mx-2 opacity-50">></span>
            <span class="font-weight-bold">Aprovação de Contas</span>
          </div>
          <div class="text-h5 font-weight-black tracking-tight leading-none mt-1 d-flex align-center gap-2" :class="isDark ? 'text-white' : 'text-grey-darken-4'">
             Triagem de Acessos
             <v-chip size="small" color="error" variant="flat" class="font-weight-bold text-uppercase ml-2">Validação Obrigatória</v-chip>
          </div>
        </div>

        <div class="d-flex align-center gap-3 mt-3 mt-md-0 flex-wrap">
          <v-btn color="grey-darken-3" variant="flat" class="btn-3d px-4 font-weight-bold text-caption flex-shrink-0" height="40" @click="emit('refresh')">
             <v-icon start>mdi-refresh</v-icon> Atualizar Manual
          </v-btn>
        </div>
      </div>

      <div class="px-4 px-md-6 py-4 flex-shrink-0 w-100">
        <v-row class="ma-0 w-100">
          <v-col cols="12" sm="6" md="3" class="pa-2">
            <v-card class="kpi-card kpi-rect bg-gradient-purple hover-elevate py-3 px-4 cursor-pointer" elevation="2" v-ripple @click="filterByStatus('all')">
              <div class="kpi-bg-icon"><v-icon>mdi-account-group</v-icon></div>
              <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                <div class="d-flex align-center gap-2">
                  <v-icon size="18" class="opacity-80">mdi-account-group</v-icon>
                  <span class="kpi-label">TOTAL DE SOLICITAÇÕES</span>
                </div>
                <div class="kpi-number-group my-1"><span class="kpi-value">{{ props.leads.length }}</span></div>
                <div class="kpi-footer mt-1">Registros na base</div>
              </div>
            </v-card>
          </v-col>

          <v-col cols="12" sm="6" md="3" class="pa-2">
            <v-card class="kpi-card kpi-rect bg-gradient-orange hover-elevate py-3 px-4 cursor-pointer" elevation="2" v-ripple @click="filterByStatus('pending')">
              <div class="kpi-bg-icon"><v-icon>mdi-clock-outline</v-icon></div>
              <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                <div class="d-flex align-center gap-2">
                  <v-icon size="18" class="opacity-80">mdi-clock-outline</v-icon>
                  <span class="kpi-label">AGUARDANDO APROVAÇÃO</span>
                </div>
                <div class="kpi-number-group my-1"><span class="kpi-value">{{ stats.pending }}</span></div>
                <div class="kpi-footer mt-1 text-yellow-accent-2 font-weight-bold">Requer análise comercial</div>
              </div>
            </v-card>
          </v-col>

          <v-col cols="12" sm="6" md="3" class="pa-2">
            <v-card class="kpi-card kpi-rect bg-gradient-green hover-elevate py-3 px-4 cursor-pointer" elevation="2" v-ripple @click="filterByStatus('approved')">
              <div class="kpi-bg-icon"><v-icon>mdi-shield-check</v-icon></div>
              <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                <div class="d-flex align-center gap-2">
                  <v-icon size="18" class="opacity-80">mdi-shield-check</v-icon>
                  <span class="kpi-label">CONTAS APROVADAS</span>
                </div>
                <div class="kpi-number-group my-1"><span class="kpi-value">{{ stats.approved }}</span></div>
                <div class="kpi-footer mt-1">Acesso liberado à loja</div>
              </div>
            </v-card>
          </v-col>

          <v-col cols="12" sm="6" md="3" class="pa-2">
            <v-card class="kpi-card kpi-rect bg-gradient-red hover-elevate py-3 px-4 cursor-pointer" elevation="2" v-ripple @click="filterByStatus('rejected')">
              <div class="kpi-bg-icon"><v-icon>mdi-shield-off</v-icon></div>
              <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                <div class="d-flex align-center gap-2">
                  <v-icon size="18" class="opacity-80">mdi-shield-off</v-icon>
                  <span class="kpi-label">CONTAS RECUSADAS</span>
                </div>
                <div class="kpi-number-group my-1"><span class="kpi-value">{{ stats.rejected }}</span></div>
                <div class="kpi-footer mt-1">Acesso bloqueado</div>
              </div>
            </v-card>
          </v-col>
        </v-row>
      </div>

      <div class="px-4 px-md-6 pt-0 pb-2 flex-shrink-0 w-100">
        <div class="controls-bar d-flex flex-column flex-md-row align-center justify-space-between w-100 gap-3" :class="isDark ? 'controls-dark' : 'controls-light'">

          <div class="d-flex flex-column flex-sm-row align-center gap-3 w-100 w-md-auto">
            <v-menu location="bottom start">
              <template v-slot:activator="{ props }">
                <v-btn v-bind="props" variant="outlined" class="btn-3d w-100 w-sm-auto" height="40" prepend-icon="mdi-filter-variant" :color="isDark ? 'white' : 'grey-darken-3'">
                  Filtro: {{ statusFilterLabel }}
                  <v-icon end size="small">mdi-chevron-down</v-icon>
                </v-btn>
              </template>
              <v-list density="compact" :class="isDark ? 'bg-grey-darken-4 text-white' : 'bg-white'">
                <v-list-item @click="filterByStatus('all')"><v-list-item-title class="font-weight-bold">Todas as Solicitações</v-list-item-title></v-list-item>
                <v-list-item @click="filterByStatus('pending')"><v-list-item-title class="font-weight-bold text-warning">Aguardando Aprovação</v-list-item-title></v-list-item>
                <v-list-item @click="filterByStatus('approved')"><v-list-item-title class="font-weight-bold text-success">Contas Aprovadas</v-list-item-title></v-list-item>
                <v-list-item @click="filterByStatus('rejected')"><v-list-item-title class="font-weight-bold text-error">Contas Recusadas</v-list-item-title></v-list-item>
              </v-list>
            </v-menu>

            <div class="search-wrap d-flex align-center w-100 w-sm-auto flex-grow-1" :class="isDark ? 'search-dark' : 'search-light'">
              <v-icon :color="isDark ? 'white-70' : 'grey-darken-1'">mdi-magnify</v-icon>
              <input
                v-model="searchQuery"
                type="text"
                placeholder="Buscar cliente, email, documento ou instagram..."
                class="clean-input flex-grow-1"
                :class="isDark ? 'text-white' : 'text-grey-darken-4'"
              />
            </div>
          </div>

          <div class="d-flex align-center gap-3 w-100 w-md-auto justify-end flex-wrap">
            <transition name="fade">
              <div v-if="selectedLeads.length > 0" class="d-flex align-center gap-2">
                <span class="text-caption font-weight-bold text-primary mr-2">{{ selectedLeads.length }} selecionados</span>
                <v-btn color="error" variant="tonal" size="small" class="btn-3d font-weight-bold" @click="massReject"><v-icon start>mdi-close-circle</v-icon> Recusar Lote</v-btn>
                <v-btn color="success" variant="flat" size="small" class="btn-3d font-weight-bold" @click="massApprove"><v-icon start>mdi-check-circle</v-icon> Aprovar Lote</v-btn>
              </div>
            </transition>
          </div>
        </div>
      </div>

      <div class="flex-grow-1 overflow-hidden d-flex flex-column transition-all px-4 px-md-6 pb-0 w-100">
        <v-card class="flex-grow-1 d-flex flex-column rounded-0 border-thin overflow-hidden w-100" :class="isDark ? 'glass-card border-white-05' : 'bg-white shadow-sm'" :elevation="0">

          <div class="grid-scroll flex-grow-1 overflow-auto custom-scroll relative w-100">
            <div class="grid-table-container">

              <div class="grid-header sticky-head" :class="isDark ? 'grid-surface-dark border-bottom-white-05' : 'grid-surface-light border-b border-grey-lighten-2'">
                <div class="cell center"><v-checkbox-btn :model-value="isAllSelected" :indeterminate="isIndeterminate" @update:model-value="toggleSelectAll" color="success" class="chk-fixed"></v-checkbox-btn></div>
                <div class="cell header-text">Nome do Cliente</div>
                <div class="cell header-text">Documento (CNPJ/CPF)</div>
                <div class="cell header-text">Instagram</div>
                <div class="cell header-text">Contato</div>
                <div class="cell center header-text">Status Atual</div>
                <div class="cell center header-text">Data Solicitação</div>
                <div class="cell center header-text">Ações</div>
              </div>

              <div v-if="paginatedLeads.length === 0" class="d-flex flex-column justify-center align-center h-100 opacity-60 gap-2 py-10 w-100" style="min-width: 1200px;">
                <v-icon size="48" color="grey-lighten-1">mdi-shield-search</v-icon>
                <span class="text-body-2 font-weight-medium text-grey">Nenhum registro encontrado.</span>
              </div>

              <div
                v-else
                v-for="(lead, index) in paginatedLeads"
                :key="lead.id"
                class="grid-row"
                :class="[
                  isDark ? 'grid-row-dark' : 'grid-row-light',
                  zebraClass(index),
                  selectedLeads.includes(lead.id) ? (isDark ? 'grid-selected-dark' : 'grid-selected-light') : '',
                  lead.account_status === 'pending' ? (isDark ? 'border-l-warning' : 'border-l-warning-light') : ''
                ]"
              >
                <div class="cell center"><v-checkbox-btn v-model="selectedLeads" :value="lead.id" color="success" class="chk-fixed"></v-checkbox-btn></div>

                <div class="cell">
                  <div class="d-flex align-center gap-3 w-100">
                    <v-avatar :color="getAvatarColor(lead.account_status)" size="32" class="text-white font-weight-black shadow-sm text-caption flex-shrink-0">
                      {{ lead.name ? lead.name.substring(0, 2).toUpperCase() : '?' }}
                    </v-avatar>
                    <div class="d-flex flex-column overflow-hidden">
                      <strong class="text-body-2 font-weight-black text-truncate flex-grow-1" :class="isDark ? 'text-white' : 'text-grey-darken-4'" :title="lead.name">{{ lead.name || 'Sem nome' }}</strong>
                      <span class="text-[10px] opacity-70 text-truncate font-mono lh-1 mt-1" :title="lead.email"><v-icon size="10">mdi-email-outline</v-icon> {{ lead.email }}</span>
                    </div>
                  </div>
                </div>

                <div class="cell">
                   <v-chip size="small" variant="outlined" class="font-mono font-weight-bold opacity-80 border-opacity-50 w-100 justify-center">
                     {{ lead.document || 'N/A' }}
                   </v-chip>
                </div>

                <div class="cell flex-column align-start justify-center">
                   <a v-if="lead.instagram" :href="`https://instagram.com/${lead.instagram.replace('@', '')}`" target="_blank" class="text-caption font-weight-bold d-flex align-center gap-1 text-truncate w-100 text-decoration-none" :class="isDark ? 'text-purple-lighten-2' : 'text-purple-darken-2'" :title="lead.instagram">
                      <v-icon size="14">mdi-instagram</v-icon> {{ lead.instagram }}
                   </a>
                   <span v-else class="text-caption opacity-40 d-flex align-center gap-1"><v-icon size="14">mdi-instagram</v-icon> N/A</span>
                </div>

                <div class="cell">
                   <span v-if="lead.phone" class="text-caption font-mono font-weight-bold opacity-90 d-flex align-center gap-1 text-truncate w-100" :class="isDark ? 'text-green-lighten-2' : 'text-green-darken-2'">
                      <v-icon size="14">mdi-whatsapp</v-icon> {{ lead.phone }}
                   </span>
                   <span v-else class="text-caption opacity-40 d-flex align-center gap-1"><v-icon size="14">mdi-whatsapp</v-icon> N/A</span>
                </div>

                <div class="cell center flex-column gap-1">
                   <v-chip :color="getStatusObj(lead.account_status).color" variant="flat" size="small" class="font-weight-bold px-3 chip-3d text-uppercase w-100 justify-center tracking-widest" style="font-size: 10px;">
                     {{ getStatusObj(lead.account_status).label }}
                   </v-chip>
                </div>

                <div class="cell center">
                   <span class="text-caption font-weight-bold opacity-70 d-flex align-center gap-1">
                      <v-icon size="12">mdi-calendar</v-icon> {{ formatDate(lead.created_at) }}
                   </span>
                </div>

                <div class="cell center">
                  <div class="actions-inline opacity-actions">
                    <template v-if="lead.account_status === 'pending'">
                      <v-btn icon size="small" class="action-btn bg-success btn-3d" title="Aprovar Acesso" @click="approveAccount(lead)"><v-icon size="16">mdi-check</v-icon></v-btn>
                      <v-btn icon size="small" class="action-btn bg-error btn-3d" title="Recusar Acesso" @click="rejectAccount(lead)"><v-icon size="16">mdi-close</v-icon></v-btn>
                    </template>

                    <template v-else-if="lead.account_status === 'approved'">
                      <v-btn icon size="small" class="action-btn bg-error btn-3d" title="Bloquear Conta" @click="rejectAccount(lead)"><v-icon size="16">mdi-cancel</v-icon></v-btn>
                    </template>

                    <template v-else-if="lead.account_status === 'rejected'">
                      <v-btn icon size="small" class="action-btn bg-success btn-3d" title="Reativar Conta" @click="approveAccount(lead)"><v-icon size="16">mdi-refresh</v-icon></v-btn>
                    </template>

                    <v-btn v-if="lead.phone" icon size="small" class="action-btn bg-grey-darken-2 btn-3d ml-2" title="WhatsApp" @click="openWhatsApp(lead.phone, lead.name)"><v-icon size="16" color="green-lighten-2">mdi-whatsapp</v-icon></v-btn>
                  </div>
                </div>

              </div>

            </div>
          </div>

          <div class="flex-shrink-0 border-t px-4 py-2 d-flex flex-column flex-md-row align-center justify-space-between z-20 w-100" :class="isDark ? 'bg-surface-variant border-top-white-05' : 'bg-white'">
            <div class="text-caption font-weight-bold opacity-70 mb-2 mb-md-0">
              Mostrando {{ paginatedLeads.length }} de {{ filteredLeads.length }} registros
            </div>
            <v-pagination
              v-model="page"
              :length="pageCount"
              :total-visible="5"
              density="compact"
              active-color="primary"
              variant="tonal"
              size="small"
            ></v-pagination>
          </div>

        </v-card>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { supabase } from '@/api/supabase'
import { useTheme } from 'vuetify'
import { format } from 'date-fns'

const theme = useTheme()
const isDark = computed(() => theme.global.current.value.dark)

const props = defineProps<{ leads: any[] }>()
const emit = defineEmits(['refresh'])

// ESTADOS E CONTROLES
const statusFilter = ref<'all' | 'pending' | 'approved' | 'rejected'>('pending')
const searchQuery = ref('')
const selectedLeads = ref<string[]>([])
const page = ref(1)
const itemsPerPage = 30

// COMPUTEDS E ESTATÍSTICAS
const stats = computed(() => {
  return {
    pending: props.leads.filter(l => l.account_status === 'pending').length,
    approved: props.leads.filter(l => l.account_status === 'approved').length,
    rejected: props.leads.filter(l => l.account_status === 'rejected').length,
  }
})

const filteredLeads = computed(() => {
  let list = props.leads

  if (statusFilter.value !== 'all') {
    list = list.filter(l => l.account_status === statusFilter.value)
  }

  if (searchQuery.value) {
    const q = searchQuery.value.toLowerCase()
    list = list.filter(l =>
      l.name?.toLowerCase().includes(q) ||
      l.email?.toLowerCase().includes(q) ||
      l.document?.includes(q) ||
      l.instagram?.toLowerCase().includes(q)
    )
  }

  return list.sort((a, b) => {
    if (a.account_status === 'pending' && b.account_status !== 'pending') return -1;
    if (b.account_status === 'pending' && a.account_status !== 'pending') return 1;
    return new Date(b.created_at).getTime() - new Date(a.created_at).getTime();
  })
})

const paginatedLeads = computed(() => {
  const start = (page.value - 1) * itemsPerPage
  return filteredLeads.value.slice(start, start + itemsPerPage)
})

const pageCount = computed(() => Math.ceil(filteredLeads.value.length / itemsPerPage))
watch([searchQuery, statusFilter], () => { page.value = 1; selectedLeads.value = [] })

const isAllSelected = computed(() => paginatedLeads.value.length > 0 && selectedLeads.value.length === paginatedLeads.value.length)
const isIndeterminate = computed(() => selectedLeads.value.length > 0 && selectedLeads.value.length < paginatedLeads.value.length)
const toggleSelectAll = (val: boolean) => { selectedLeads.value = val ? paginatedLeads.value.map(l => l.id) : [] }

const statusFilterLabel = computed(() => {
  const map: Record<string, string> = { all: 'Todos os Registros', pending: 'Aguardando', approved: 'Aprovados', rejected: 'Bloqueados' }
  return map[statusFilter.value] || 'Filtro'
})

function filterByStatus(status: 'all' | 'pending' | 'approved' | 'rejected') {
  statusFilter.value = status
}

// AUXILIARES UI
function getStatusObj(status: string) {
  switch (status) {
    case 'pending': return { label: 'Pendente', color: 'warning' }
    case 'approved': return { label: 'Aprovado', color: 'success' }
    case 'rejected': return { label: 'Recusado', color: 'error' }
    default: return { label: 'N/A', color: 'grey' }
  }
}

function getAvatarColor(status: string) {
  switch (status) {
    case 'pending': return 'warning'
    case 'approved': return 'success'
    case 'rejected': return 'error'
    default: return 'primary'
  }
}

function zebraClass(index: number) {
  if (isDark.value) return index % 2 === 0 ? 'zebra-dark-a' : 'zebra-dark-b'
  return index % 2 === 0 ? 'zebra-light-a' : 'zebra-light-b'
}

function formatDate(dateString: string) {
  if (!dateString) return '-'
  return format(new Date(dateString), 'dd/MM/yy HH:mm')
}

function openWhatsApp(phone: string, name: string) {
  if (phone) window.open(`https://wa.me/55${phone.replace(/\D/g, '')}?text=${encodeURIComponent(`Olá ${name}, referente ao seu cadastro no Acervo Digital MJ.`)}`, '_blank')
}

// ==========================================
// AÇÕES DE BANCO DE DADOS
// ==========================================
async function approveAccount(lead: any) {
  const isReactivation = lead.account_status === 'rejected'
  const msg = isReactivation
    ? `Reativar a conta de ${lead.name}?`
    : `Aprovar o acesso de ${lead.name} e enviar e-mail de liberação?`

  if(!confirm(msg)) return

  const { error } = await supabase.from('public_leads').update({ account_status: 'approved' }).eq('id', lead.id)
  if (error) {
    alert('Erro ao aprovar: ' + error.message)
    return
  }

  if (!isReactivation) {
    try {
      await supabase.functions.invoke('send-approval-email', {
        body: { email: lead.email, name: lead.name }
      })
    } catch (err) {
      console.error('Erro ao enviar e-mail:', err)
    }
  }

  emit('refresh')
}

async function rejectAccount(lead: any) {
  if(!confirm(`Bloquear/Recusar o acesso de ${lead.name}? Ele perderá acesso imediato à loja.`)) return

  const { error } = await supabase.from('public_leads').update({ account_status: 'rejected' }).eq('id', lead.id)
  if (error) alert('Erro ao bloquear: ' + error.message)

  emit('refresh')
}

async function massApprove() {
  if(!confirm(`Aprovar ${selectedLeads.value.length} contas selecionadas?`)) return
  try {
    const { error } = await supabase.from('public_leads').update({ account_status: 'approved' }).in('id', selectedLeads.value)
    if (error) throw error;
    selectedLeads.value = []
    emit('refresh')
  } catch(e:any) { alert('Erro: ' + e.message) }
}

async function massReject() {
  if(!confirm(`Recusar/Bloquear ${selectedLeads.value.length} contas selecionadas?`)) return
  try {
    const { error } = await supabase.from('public_leads').update({ account_status: 'rejected' }).in('id', selectedLeads.value)
    if (error) throw error;
    selectedLeads.value = []
    emit('refresh')
  } catch(e:any) { alert('Erro: ' + e.message) }
}
</script>

<style scoped lang="scss">
/* ==========================================================================
   FUNDAÇÃO TYPOGRAPHY & LAYOUT (CLONE EXATO DO LEADS TAB)
========================================================================== */
.leads-layout { position: relative; width: 100%; max-width: 100%; }
.font-sans { font-family: 'Inter', -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; }
.tracking-tight { letter-spacing: -0.03em !important; }
.tracking-widest { letter-spacing: 0.1em !important; }
.lh-1 { line-height: 1 !important; }
.min-w-max-content { min-width: max-content; }
.min-w-200 { min-width: 200px; }
.flex-1 { flex: 1; }

.bg-glass-dark { background-color: #0B0F19; }
.bg-glass-header { background: rgba(20,20,24,0.55); backdrop-filter: blur(14px); -webkit-backdrop-filter: blur(14px); }
.glass-card { background: rgba(255, 255, 255, 0.03); backdrop-filter: blur(12px); -webkit-backdrop-filter: blur(12px); }

.bg-white-05 { background-color: rgba(255, 255, 255, 0.05) !important; }
.border-white-05 { border-color: rgba(255, 255, 255, 0.05) !important; }
.border-white-10 { border-color: rgba(255, 255, 255, 0.1) !important; }
.border-bottom-white-05 { border-bottom: 1px solid rgba(255, 255, 255, 0.05) !important; }
.border-top-white-05 { border-top: 1px solid rgba(255, 255, 255, 0.05) !important; }
.text-white-50 { color: rgba(255, 255, 255, 0.5) !important; }

/* ==========================================================================
   CAROUSEL BACKGROUND ANIMATION
========================================================================== */
.background-carousel-wrapper {
  position: absolute;
  top: 0; left: 0; width: 100%; height: 100%;
  z-index: 0;
  opacity: 0.6;
  pointer-events: none;
}
.background-overlay {
  position: absolute;
  top: 0; left: 0; width: 100%; height: 100%;
  z-index: 1;
  background: radial-gradient(circle at center, rgba(15, 15, 19, 0.4), rgba(15, 15, 19, 0.98));
  backdrop-filter: blur(8px);
}
:deep(.v-carousel__item) { transition: transform 15s linear !important; }
:deep(.v-window-item--active .v-carousel__item) { transform: scale(1.1); }

/* ==========================================================================
   CONTROLS BAR & SEARCH
========================================================================== */
.controls-bar { border: 1px solid rgba(0,0,0,0.08); padding: 10px; border-radius: 8px; flex-wrap: wrap; }
.controls-dark { border-color: rgba(255,255,255,0.1); background: rgba(255,255,255,0.02); }

.search-wrap { height: 40px; padding: 0 12px; display: flex; align-items: center; border: 1px solid rgba(0,0,0,0.15); border-radius: 6px; min-width: 200px; }
.search-dark { border-color: rgba(255,255,255,0.2); background: rgba(0,0,0,0.2); }
.clean-input { border: none; outline: none; font-size: 13px; font-weight: 600; width: 100%; }

/* ==========================================================================
   KPI STRIP (GRADIENT BOXES EXATOS)
========================================================================== */
.kpi-card { color: white; position: relative; min-height: 110px; overflow: hidden; border-radius: 12px; transition: transform 0.2s ease, box-shadow 0.2s ease; }
.kpi-bg-icon { position: absolute; right: -20px; bottom: -20px; opacity: 0.15; transform: rotate(-15deg); pointer-events: none; }
.kpi-bg-icon .v-icon { font-size: 100px; color: white; }
.kpi-label { font-size: 11px; font-weight: 900; letter-spacing: .5px; }
.kpi-value { font-size: 26px; font-weight: 900; line-height: 1; }
.kpi-footer { font-size: 11px; opacity: .9; font-weight: 600; }

.bg-gradient-purple { background: linear-gradient(135deg, #7b1fa2, #4a148c); }
.bg-gradient-green { background: linear-gradient(135deg, #2e7d32, #1b5e20); }
.bg-gradient-orange { background: linear-gradient(135deg, #e65100, #ef6c00); }
.bg-gradient-red { background: linear-gradient(135deg, #c62828, #8e0000); }

.hover-elevate:hover { transform: translateY(-4px); box-shadow: 0 12px 24px rgba(0,0,0,0.2) !important; }

/* ==========================================================================
   DATA GRID (CSS GRID TABLE)
========================================================================== */
.grid-scroll {
  scrollbar-gutter: stable;
  -webkit-overflow-scrolling: touch;
  width: 100%;
  overflow-x: auto;
  will-change: transform;
}
.custom-scroll::-webkit-scrollbar { width: 8px; height: 8px; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.35); border-radius: 6px; }

.grid-table-container {
  display: flex;
  flex-direction: column;
  min-width: 1300px;
  width: 100%;
}

.grid-header, .grid-row {
  display: grid;
  align-items: stretch;
  width: 100%;
  /* 8 Colunas Adaptadas para Aprovação de Contas */
  grid-template-columns: 50px minmax(200px, 2fr) minmax(150px, 1.5fr) minmax(150px, 1.5fr) minmax(150px, 1.5fr) 140px 160px 140px;
}

.cell {
  padding: 10px 16px;
  display: flex;
  align-items: center;
  border-right: 1px solid rgba(0,0,0,0.08);
  border-bottom: 1px solid rgba(0,0,0,0.08);
  min-height: 64px;
  overflow: hidden;
  transition: background-color 0.2s ease;
}

.center { justify-content: center; text-align: center; }
.grid-header .cell { min-height: 48px; font-weight: 800; text-transform: uppercase; letter-spacing: 0.5px; font-size: 11px; }

.sticky-head { position: sticky; top: 0; z-index: 20; box-shadow: 0 8px 16px -4px rgba(0, 0, 0, 0.12); }

.grid-surface-light .cell { background: #f5f7fa; color: rgba(0,0,0,0.9); border-color: rgba(0,0,0,0.12) !important; }
.grid-row-light .cell { border-color: rgba(0,0,0,0.08) !important; }
.zebra-light-a .cell { background: #ffffff; }
.zebra-light-b .cell { background: #fafafa; }
.grid-row-light:hover .cell { background: #e3f2fd !important; }
.grid-selected-light .cell { background: #e8f5e9 !important; }

.grid-surface-dark .cell {
  background: rgba(255,255,255,0.08) !important;
  color: rgba(255,255,255,0.80) !important;
  border-color: rgba(255,255,255,0.10) !important;
}
.grid-row-dark .cell { background: rgba(255,255,255,0.02); border-color: rgba(255,255,255,0.08) !important; color: rgba(255,255,255,0.9); }
.zebra-dark-a .cell { background: rgba(255,255,255,0.03) !important; }
.zebra-dark-b .cell { background: rgba(255,255,255,0.01) !important; }
.grid-row-dark:hover .cell { background: rgba(255,255,255,0.07) !important; }
.grid-selected-dark .cell { background: rgba(76, 175, 80, 0.2) !important; }

/* Status Indicators Line */
.border-l-warning { border-left: 3px solid rgb(var(--v-theme-warning)) !important; }
.border-l-warning-light { border-left: 3px solid rgb(var(--v-theme-warning)) !important; }

/* ==========================================================================
   COMPONENTES UI (BOTÕES 3D, CHIPS)
========================================================================== */
.btn-3d {
  border-radius: 6px !important;
  box-shadow: 0 3px 5px rgba(0,0,0,0.15), inset 0 2px 0 rgba(255,255,255,0.2) !important;
  transition: transform 0.1s ease, box-shadow 0.1s ease;
  text-transform: none !important;
}
.btn-3d:active {
  transform: translateY(2px);
  box-shadow: 0 1px 2px rgba(0,0,0,0.15), inset 0 1px 0 rgba(255,255,255,0.2) !important;
}

.chip-3d {
  border-radius: 6px !important;
  box-shadow: 0 2px 4px rgba(0,0,0,0.12), inset 0 1px 0 rgba(255,255,255,0.2) !important;
  text-shadow: 0 1px 2px rgba(0,0,0,0.2);
}

.actions-inline { display: flex; gap: 6px; justify-content: center; }
.action-btn { width: 32px !important; height: 32px !important; color: #fff !important; }
.opacity-actions .action-btn { opacity: 0.6; transition: opacity 0.2s, transform 0.2s; }
.grid-row:hover .opacity-actions .action-btn { opacity: 1; }
.action-btn:hover { transform: scale(1.1); }
</style>
