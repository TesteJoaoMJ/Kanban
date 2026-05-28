<template>
  <div class="enterprise-cockpit" :class="isLight ? 'theme-light' : 'theme-dark'">

    <v-progress-linear
      v-if="isTransitioning || isLoading"
      indeterminate
      :color="isLight ? 'primary' : 'cyan-accent-4'"
      height="2"
      class="position-absolute w-100 z-50 system-loader"
    ></v-progress-linear>

    <v-dialog v-model="needsAuth" persistent max-width="400" transition="fade-transition">
      <v-card class="auth-card elevation-24">
        <div class="auth-header">
          <div class="auth-icon-wrapper shadow-sm">
            <v-icon :color="isLight ? 'primary' : 'cyan-accent-3'" size="36">mdi-shield-lock-outline</v-icon>
          </div>
          <h2 class="auth-title">SRE COCKPIT</h2>
          <p class="auth-subtitle">Acesso restrito à auditoria e telemetria.</p>
        </div>
        <div class="auth-body">
          <label class="auth-label">PIN DE SEGURANÇA (NÍVEL 5)</label>
          <v-otp-input v-model="pinCode" length="4" type="password" :color="isLight ? 'primary' : 'cyan-accent-3'" :error="pinError" @finish="verifyPin" class="auth-otp"></v-otp-input>
          <div class="error-msg text-error">
            <v-icon size="14" class="mr-1" v-if="pinErrorMsg">mdi-alert-circle</v-icon>
            {{ pinErrorMsg }}
          </div>
          <v-btn :color="isLight ? '#0f172a' : 'cyan-darken-3'" variant="flat" block size="large" :loading="isVerifying" @click="verifyPin" class="auth-btn mt-4">
            AUTENTICAR SESSÃO
          </v-btn>
        </div>
      </v-card>
    </v-dialog>

    <template v-if="!needsAuth">
      <header class="cockpit-topbar">
        <div class="topbar-left">
          <div class="logo-area">
            <v-icon size="20" :color="isLight ? '#0f172a' : 'cyan-accent-3'">mdi-radar</v-icon>
            <span class="system-title">SRE COCKPIT</span>
            <span class="badge-live"><span class="pulse-dot"></span> LIVE</span>
          </div>
          <div class="vertical-divider"></div>
          <nav class="module-nav">
            <button
              class="nav-tab"
              :class="{ 'active': filters.module === 'Todos' }"
              @click="setModule('Todos')"
            >
              Visão Global
            </button>
            <button
              v-for="mod in systemModules"
              :key="mod.id"
              class="nav-tab"
              :class="{ 'active': filters.module === mod.id }"
              @click="setModule(mod.id)"
            >
              {{ mod.name }}
            </button>
          </nav>
        </div>

        <div class="topbar-right">
          <div class="health-indicator">
            <v-icon size="14" color="success" class="mr-1">mdi-check-circle</v-icon>
            <span class="font-weight-medium">Health: {{ systemHealthScore }}%</span>
          </div>
          <div class="sync-info">
            <span class="sync-label">Último sync</span>
            <span class="sync-time">{{ formatTimeOnly(lastSync) }}</span>
          </div>
          <v-btn size="small" variant="outlined" class="btn-action" prepend-icon="mdi-sync" @click="fetchData" :loading="isLoading">
            Sync
          </v-btn>
          <div class="vertical-divider mx-1"></div>
          <v-btn icon="mdi-lock-outline" variant="text" class="text-muted" @click="lockSystem" title="Bloquear Terminal" size="small"></v-btn>
        </div>
      </header>

      <div class="cockpit-body">

        <main class="cockpit-main">

          <div class="filters-strip">
            <div class="search-box">
              <v-icon size="16" class="search-icon text-muted">mdi-magnify</v-icon>
              <input type="text" v-model="filters.search" placeholder="Pesquisar logs por ID, ator, entidade ou JSON..." class="search-input" />
            </div>

            <div class="filter-actions">
              <select v-model="filters.action" class="styled-select">
                <option value="Todas">Ações: Todas</option>
                <option value="Criação">Apenas Criações (INSERT)</option>
                <option value="Atualização">Apenas Edições (UPDATE)</option>
                <option value="Exclusão">Apenas Exclusões (DELETE)</option>
                <option value="Mudança de Fase">Status Change</option>
              </select>
            </div>

            <div class="stats-mini">
              <span class="stat-text"><strong class="text-main">{{ paginatedLogs.length }}</strong>/{{ filteredLogs.length }} logs</span>
              <span class="stat-text"><strong class="text-main">{{ uniqueUsers.length }}</strong> atores</span>
            </div>
          </div>

          <div class="log-table-wrapper">
            <table class="data-table">
              <thead>
                <tr>
                  <th style="width: 130px">Timestamp</th>
                  <th style="width: 100px">Ação</th>
                  <th style="width: 150px">Módulo / Origem</th>
                  <th style="width: 180px">Ator (Usuário)</th>
                  <th>Mensagem do Evento</th>
                  <th style="width: 50px" class="text-center">Detalhe</th>
                </tr>
              </thead>
              <tbody>
                <tr v-if="paginatedLogs.length === 0">
                  <td colspan="6" class="empty-state">
                    <v-icon size="40" class="empty-icon">mdi-database-search-outline</v-icon>
                    <div class="empty-title">Nenhum evento localizado</div>
                    <div class="empty-subtitle">Tente ajustar os filtros ou os termos de pesquisa acima.</div>
                  </td>
                </tr>
                <tr
                  v-for="log in paginatedLogs"
                  :key="log.event_id"
                  class="data-row"
                  :class="{ 'row-active': selectedLog?.event_id === log.event_id }"
                  @click="selectLog(log)"
                >
                  <td class="cell-timestamp">{{ formatTimeFull(log.created_at) }}</td>
                  <td>
                    <span class="badge-action" :class="log.action_type">{{ translateActionShort(log.action_type) }}</span>
                  </td>
                  <td class="cell-origin" :title="formatKeyName(log.source_table || log.entity_type)">
                    {{ formatKeyName(log.source_table || log.entity_type) }}
                  </td>
                  <td>
                    <div class="actor-wrap" :title="displayActorName(log.actor_name)">
                      <div class="actor-dot" :style="{ backgroundColor: getActorColor(displayActorName(log.actor_name)) }"></div>
                      <span class="actor-name">{{ displayActorName(log.actor_name) }}</span>
                    </div>
                  </td>
                  <td class="cell-message" :title="log.didactic_message">
                    {{ log.didactic_message }}
                  </td>
                  <td class="text-center">
                    <v-icon size="18" class="row-chevron">mdi-chevron-right</v-icon>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>

          <div class="pagination-footer">
            <v-pagination v-if="totalPages > 1" v-model="currentPage" :length="totalPages" :total-visible="7" density="compact" active-color="primary"></v-pagination>
          </div>
        </main>

        <aside class="inspector-panel" :class="{ 'panel-open': selectedLog }">
          <div v-if="selectedLog" class="inspector-container">

            <header class="inspector-header">
              <div class="header-titles">
                <span class="sup-title">INSPEÇÃO FORENSE</span>
                <h3 class="main-title">{{ translateValue(selectedLog.action_type) }}</h3>
              </div>
              <v-btn icon="mdi-close" variant="text" size="small" class="close-btn" @click="selectedLog = null"></v-btn>
            </header>

            <div class="inspector-body custom-scrollbar">

              <section class="info-section">
                <div class="grid-2-col">
                  <div class="info-group">
                    <label>ID do Evento</label>
                    <div class="val-mono badge-grey">{{ selectedLog.event_id.split('-')[0] }}...</div>
                  </div>
                  <div class="info-group">
                    <label>Data / Hora</label>
                    <div class="val-mono">{{ formatTimeFull(selectedLog.created_at) }}</div>
                  </div>
                  <div class="info-group">
                    <label>Responsável</label>
                    <div class="val-text d-flex align-center gap-2">
                       <v-avatar size="16" :color="getActorColor(displayActorName(selectedLog.actor_name))"><span class="text-[8px] text-white">{{ displayActorName(selectedLog.actor_name).charAt(0) || 'S' }}</span></v-avatar>
                      <span class="text-truncate">{{ displayActorName(selectedLog.actor_name) }}</span>
                    </div>
                  </div>
                  <div class="info-group">
                    <label>Entidade Alvo</label>
                    <div class="val-text font-weight-bold text-main">{{ formatKeyName(selectedLog.source_table || selectedLog.entity_type) }}</div>
                  </div>
                </div>
              </section>

              <section class="info-section">
                <div class="message-card">
                  <v-icon size="16" class="msg-icon">mdi-information-outline</v-icon>
                  <span class="msg-text">{{ selectedLog.didactic_message }}</span>
                </div>
              </section>

              <section class="info-section" v-if="getContextualData(selectedLog).length > 0">
                <h4 class="section-heading">Contexto Extraído</h4>
                <div class="context-list">
                  <div class="context-item" v-for="info in getContextualData(selectedLog)" :key="info.label">
                    <span class="ctx-label">{{ info.label }}</span>
                    <span class="ctx-val">{{ info.value }}</span>
                  </div>
                </div>
              </section>

              <section class="info-section" v-if="hasDiff(selectedLog)">
                <div class="d-flex justify-space-between align-center mb-3">
                  <h4 class="section-heading mb-0">Mutações de Registro (Diff)</h4>
                  <button class="btn-toggle-diff" @click="showRawJson = !showRawJson">
                    {{ showRawJson ? 'Ver Diff Visual' : 'Ver JSON Bruto' }}
                  </button>
                </div>

                <div v-if="showRawJson" class="raw-json-container">
                  <div class="json-pane old-pane">
                    <div class="pane-header">Antes (Before)</div>
                    <pre class="custom-scrollbar">{{ JSON.stringify(selectedLog.before_data, null, 2) || 'null' }}</pre>
                  </div>
                  <div class="json-pane new-pane">
                    <div class="pane-header">Depois (After)</div>
                    <pre class="custom-scrollbar">{{ JSON.stringify(selectedLog.after_data, null, 2) || 'null' }}</pre>
                  </div>
                </div>

                <div v-else class="diff-list">
                  <div class="diff-item" v-for="change in getDeepDiff(selectedLog.before_data, selectedLog.after_data)" :key="change.key">
                    <div class="diff-prop-header">
                      <strong>{{ formatKeyName(change.key) }}</strong>
                      <span class="diff-prop-key">{{ change.key }}</span>
                    </div>
                    <div class="diff-compare-box">
                      <div class="diff-val old-val">
                        <div class="diff-indicator">-</div>
                        <div class="diff-content" :class="{'italic opacity-50': translateValue(change.old) === 'Vazio / Não Existia'}">
                          {{ translateValue(change.old) }}
                        </div>
                      </div>
                      <div class="diff-val new-val">
                        <div class="diff-indicator">+</div>
                        <div class="diff-content font-weight-bold">
                          {{ translateValue(change.new) }}
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </section>

              <section class="info-section" v-if="extractUUIDs(selectedLog).length > 0">
                <h4 class="section-heading">Rastreabilidade (UUIDs Detectados)</h4>
                <div class="trace-actions">
                  <button class="btn-trace" v-for="uuid in extractUUIDs(selectedLog)" :key="uuid" @click="openEntityTimeline(uuid)">
                    <v-icon size="14" class="mr-2">mdi-crosshairs-gps</v-icon>
                    <span>Rastrear: {{ translateUuidToName(uuid) }}</span>
                  </button>
                </div>
              </section>

            </div>
          </div>

          <div v-else class="empty-inspector">
            <div class="empty-icon-wrap">
              <v-icon size="32">mdi-microscope</v-icon>
            </div>
            <h4>Inspetor Inativo</h4>
            <p>Selecione um log na tabela para detalhar metadados e diff de payload.</p>
          </div>
        </aside>

      </div>

      <v-navigation-drawer v-model="entityTimelineOpen" location="right" width="600" temporary class="drawer-timeline" elevation="24">
        <div class="drawer-header">
          <div class="drawer-title-area">
            <h3 class="drawer-title">Linha do Tempo</h3>
            <span class="drawer-uuid">{{ selectedEntityId }}</span>
          </div>
          <v-btn icon="mdi-close" variant="text" size="small" class="close-btn" @click="entityTimelineOpen = false"></v-btn>
        </div>
        <div class="drawer-body custom-scrollbar">
          <v-timeline density="compact" align="start" truncate-line="start" side="end" class="mt-4">
            <v-timeline-item v-for="event in entityTimelineEvents" :key="event.event_id" :dot-color="getActionColorVuetify(event.action_type)" size="small" fill-dot>
              <div class="timeline-card">
                <div class="tl-header">
                  <span class="tl-module">{{ getModuleCategory(event) }}</span>
                  <span class="tl-time">{{ formatTimeFull(event.created_at) }}</span>
                </div>
                <div class="tl-body">
                  <div class="tl-actor"><v-icon size="12" class="mr-1">mdi-account</v-icon>{{ displayActorName(event.actor_name) }}</div>
                  <div class="tl-msg">{{ event.didactic_message }}</div>
                </div>
              </div>
            </v-timeline-item>
          </v-timeline>
        </div>
      </v-navigation-drawer>

    </template>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch, onUnmounted, onMounted } from 'vue';
import { supabase } from '@/api/supabase';
import { useThemeStore } from '@/stores/themeStore';

const themeStore = useThemeStore();
const isLight = computed(() => themeStore.currentMode === 'light');

// ESTADO AUTH E UI
const needsAuth = ref(true);
const pinCode = ref('');
const isVerifying = ref(false);
const pinError = ref(false);
const pinErrorMsg = ref('');
const currentUser = ref<any>(null);

// MÓDULOS E FILTROS
const isTransitioning = ref(false);
const selectedLog = ref<any>(null);
const showRawJson = ref(false);

const isLoading = ref(false);
const lastSync = ref('');
const showToast = ref(false);
const toastMsg = ref('');

const unifiedLogs = ref<any[]>([]);
let realtimeSubscriptionPrimary: any = null;
let realtimeSubscriptionFallback: any = null;
let realtimeSubscriptionProd: any = null;

const entityCache = ref<Record<string, any>>({});

const fetchMissingContext = async (logs: any[]) => {
  const uuidRegex = /[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}/gi;
  const rawIds = new Set<string>();

  logs.forEach(l => {
     if(l.entity_label && l.entity_label.length === 36) rawIds.add(l.entity_label);
     // Captura UUIDs ocultos nos payloads e até no nome do ator (quando vem de production_logs)
     const str = JSON.stringify(l.after_data || {}) + JSON.stringify(l.before_data || {}) + String(l.actor_name || '');
     const matches = str.match(uuidRegex);
     if (matches) matches.forEach(m => rawIds.add(m));
  });

  const uniqueIds = Array.from(rawIds).filter(id => !entityCache.value[id]);
  if (uniqueIds.length === 0) return;

  try {
      const { data: profs } = await supabase.from('profiles').select('id, full_name').in('id', uniqueIds);
      if(profs) profs.forEach((p:any) => { entityCache.value[p.id] = { type: 'User', name: p.full_name }; });

      let missing = uniqueIds.filter(id => !entityCache.value[id]);
      if (missing.length > 0) {
         const { data: ords } = await supabase.from('orders').select('id, customer_name, order_number').in('id', missing);
         if(ords) ords.forEach((o:any) => { entityCache.value[o.id] = { type: 'Order', name: `${o.customer_name} (OP#${o.order_number})`, customer_name: o.customer_name, order_number: o.order_number }; });
      }

      missing = uniqueIds.filter(id => !entityCache.value[id]);
      if (missing.length > 0) {
         const { data: items } = await supabase.from('order_items').select('id, stamp_ref, orders(customer_name, order_number)').in('id', missing);
         if(items) items.forEach((p:any) => { entityCache.value[p.id] = { type: 'Item', name: p.stamp_ref, stamp_ref: p.stamp_ref, customer_name: p.orders?.customer_name, order_number: p.orders?.order_number }; });
      }

      missing = uniqueIds.filter(id => !entityCache.value[id]);
      if(missing.length > 0) {
          const { data: rec } = await supabase.from('finance_receivables').select('id, description, value, entity_name').in('id', missing);
          if(rec) rec.forEach((r:any) => { entityCache.value[r.id] = { type: 'Receivable', name: `Receita: ${r.entity_name || r.description} (R$ ${r.value})` }; });
      }

      missing = uniqueIds.filter(id => !entityCache.value[id]);
      if(missing.length > 0) {
          const { data: pay } = await supabase.from('finance_payables').select('id, description, value, entity_name').in('id', missing);
          if(pay) pay.forEach((p:any) => { entityCache.value[p.id] = { type: 'Payable', name: `Despesa: ${p.entity_name || p.description} (R$ ${p.value})` }; });
      }

      missing = uniqueIds.filter(id => !entityCache.value[id]);
      if(missing.length > 0) {
          const { data: comps } = await supabase.from('companies').select('id, trade_name').in('id', missing);
          if(comps) comps.forEach((c:any) => { entityCache.value[c.id] = { type: 'Company', name: c.trade_name }; });

          const { data: banks } = await supabase.from('finance_accounts').select('id, name').in('id', missing);
          if(banks) banks.forEach((b:any) => { entityCache.value[b.id] = { type: 'Bank', name: b.name }; });

          const { data: custs } = await supabase.from('customers_mj').select('id, nome').in('id', missing);
          if(custs) custs.forEach((c:any) => { entityCache.value[c.id] = { type: 'Customer', name: c.nome }; });
      }
  } catch (e) { console.warn('SRE Cache Miss:', e); }
};

const currentPage = ref(1);
const itemsPerPage = 50;

const filters = ref({ search: '', module: 'Todos', action: 'Todas' });
const actionMapToDB: Record<string, string> = { 'Todas': 'Todas', 'Criação': 'INSERT', 'Atualização': 'UPDATE', 'Exclusão': 'DELETE', 'Mudança de Fase': 'STATUS_CHANGE' };

const entityTimelineOpen = ref(false);
const selectedEntityId = ref('');

const verifyPin = async () => {
  if (pinCode.value.length !== 4) return;
  isVerifying.value = true;
  pinError.value = false;

  try {
    const { data: { session } } = await supabase.auth.getSession();
    if (!session?.user) throw new Error("Usuário não autenticado.");

    const { data: profile, error } = await supabase.from('profiles').select('*').eq('id', session.user.id).single();
    if (error || !profile) throw new Error("Erro de credenciais.");

    if (profile.security_pin === pinCode.value || profile.role === 'super_admin' || profile.role === 'admin') {
      currentUser.value = profile;
      needsAuth.value = false;
      await fetchData();
      subscribeToRealtime();
    } else {
      throw new Error("Acesso restrito a Administradores.");
    }
  } catch (err: any) {
    pinError.value = true; pinErrorMsg.value = err.message; pinCode.value = '';
  } finally { isVerifying.value = false; }
};

const lockSystem = () => { needsAuth.value = true; pinCode.value = ''; selectedLog.value = null; };

// ==========================================
// 2. BUSCA AVANÇADA (Mesclando v_sre_unified_logs e production_logs)
// ==========================================
const fetchData = async () => {
  isLoading.value = true;
  selectedLog.value = null;
  try {
    // Dispara chamadas paralelas para cobrir todas as tabelas geradoras de telemetria
    const [ { data: logs }, { data: prodLogs } ] = await Promise.all([
      supabase.from('v_sre_unified_logs').select('*').order('created_at', { ascending: false }).limit(2000),
      supabase.from('production_logs').select('*').order('created_at', { ascending: false }).limit(1000)
    ]);

    let merged = logs ? [...logs] : [];

    // Mapeamento on-the-fly dos logs nativos do chão de fábrica para o formato Unified SRE
    if (prodLogs) {
        const mappedProdLogs = prodLogs.map(row => {
            let actionFmt = 'STATUS_CHANGE';
            if(row.action === 'returned_to_design' || row.action === 'start_print' || row.action === 'finish_print') actionFmt = 'UPDATE';
            if(row.action === 'reprint_error_reported') actionFmt = 'DELETE';

            return {
               event_id: `prod-${row.id}`,
               created_at: row.created_at,
               actor_name: row.user_id ? `UUID:${row.user_id}` : 'Módulo de Produção', // O identificador UUID será resolvido pela entityCache
               action_type: actionFmt,
               module: row.action?.includes('print') || row.action?.includes('calandra') ? 'Impressão' : 'PCP',
               didactic_message: `Apontamento de Fábrica: ${String(row.action).toUpperCase()} ` + (row.metadata?.reason ? `| Motivo: ${row.metadata.reason}` : ''),
               before_data: null,
               after_data: row.metadata,
               source_table: 'production_logs',
               entity_label: row.order_item_id || row.order_id,
               entity_type: 'production_item'
            }
        });
        merged = [...merged, ...mappedProdLogs];
    }

    // Ordena tudo pelo Timestamp real para não quebrar a timeline
    merged.sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime());

    unifiedLogs.value = merged.slice(0, 2000);
    currentPage.value = 1;
    await fetchMissingContext(unifiedLogs.value);

    systemHealthScore.value = 99;
    lastSync.value = new Date().toISOString();
  } catch (error) { console.error("Erro na telemetria:", error); }
  finally { isLoading.value = false; }
};

const subscribeToRealtime = () => {
  realtimeSubscriptionPrimary = supabase.channel('sre_cdc_channel_primary')
    .on('postgres_changes', { event: '*', schema: 'public', table: 'operation_events' }, async (payload) => {
      handleRealtimePayload(payload.new, 'operation_events');
    }).subscribe();

  realtimeSubscriptionFallback = supabase.channel('sre_cdc_channel_fallback')
    .on('postgres_changes', { event: '*', schema: 'public', table: 'finance_audit_logs' }, async (payload) => {
      handleRealtimePayload(payload.new, 'finance_audit_logs');
    }).subscribe();

  // Escuta os eventos gerados pelos terminais de chão de fábrica
  realtimeSubscriptionProd = supabase.channel('sre_cdc_channel_prod')
    .on('postgres_changes', { event: '*', schema: 'public', table: 'production_logs' }, async (payload) => {
      handleRealtimePayload(payload.new, 'production_logs');
    }).subscribe();
};

const handleRealtimePayload = async (row: any, source: string) => {
    let newEvent: any = {};

    if (source === 'operation_events') {
        newEvent = {
           event_id: row.id, created_at: row.created_at, actor_name: row.actor_name,
           action_type: row.action_type, module: row.module_key || 'Sistema', didactic_message: row.didactic_message,
           before_data: row.before_data, after_data: row.after_data, source_table: row.entity_type || 'Tabela Genérica',
           entity_label: row.entity_id, entity_type: row.entity_type
        };
    } else if (source === 'finance_audit_logs') {
        newEvent = {
           event_id: row.id, created_at: row.created_at, actor_name: 'Usuário ' + String(row.user_id).substring(0,5),
           action_type: row.action_type, module: 'Financeiro Fallback', didactic_message: 'Alteração Direta em Tabela Financeira',
           before_data: row.old_value, after_data: row.payload, source_table: 'finance_tables',
           entity_label: row.entity_id, entity_type: 'finance'
        };
    } else if (source === 'production_logs') {
        let actionFmt = 'STATUS_CHANGE';
        if(row.action === 'returned_to_design' || row.action === 'start_print' || row.action === 'finish_print') actionFmt = 'UPDATE';
        if(row.action === 'reprint_error_reported') actionFmt = 'DELETE';

        newEvent = {
           event_id: `prod-${row.id}`,
           created_at: row.created_at,
           actor_name: row.user_id ? `UUID:${row.user_id}` : 'Módulo de Produção',
           action_type: actionFmt,
           module: row.action?.includes('print') || row.action?.includes('calandra') ? 'Impressão' : 'PCP',
           didactic_message: `Apontamento de Fábrica: ${String(row.action).toUpperCase()} ` + (row.metadata?.reason ? `| Motivo: ${row.metadata.reason}` : ''),
           before_data: null,
           after_data: row.metadata,
           source_table: 'production_logs',
           entity_label: row.order_item_id || row.order_id,
           entity_type: 'production_item'
        };
    }

    unifiedLogs.value.unshift(newEvent);
    await fetchMissingContext([newEvent]);
};

// ==========================================
// FUNÇÃO PARA RENDERIZAR O NOME CORRETO (Resolve UUID on-the-fly)
// ==========================================
const displayActorName = (name: string) => {
    if (!name) return 'Sistema';
    if (name.startsWith('UUID:')) {
        const uuid = name.replace('UUID:', '');
        if (entityCache.value[uuid]) return entityCache.value[uuid].name;
        return 'Operador de Fábrica';
    }
    return name;
};

const formatTimeOnly = (iso: string) => iso ? new Date(iso).toLocaleTimeString('pt-BR', {hour12:false, hour:'2-digit', minute:'2-digit', second:'2-digit'}) : '';

// HEURÍSTICA DE MÓDULOS AVANÇADA (Agora captura nuances de payloads da produção)
const getModuleCategory = (e: any) => {
    const eMod = (e.module || e.module_key || '').toLowerCase();
    const entityType = (e.source_table || e.entity_type || '').toLowerCase();
    const msg = (e.didactic_message || '').toLowerCase();
    const payloadStr = JSON.stringify(e.after_data || {}).toLowerCase();

    if (eMod.includes('financ') || eMod.includes('caixa') || eMod.includes('receber') || eMod.includes('pagar') || entityType.includes('finance') || entityType.includes('payable') || entityType.includes('receivable')) return 'Financeiro';
    if (eMod.includes('venda') || eMod.includes('faturamento') || eMod.includes('pdv') || (entityType.includes('order') && !entityType.includes('item'))) return 'Faturamento';
    if (eMod.includes('design') || eMod.includes('arte') || msg.includes('design')) return 'Design';

    // Captura logs da Estação de Impressão e Calandra
    if (eMod.includes('impress') || eMod.includes('print') || msg.includes('print') || msg.includes('impressão') || msg.includes('calandra') || payloadStr.includes('print')) return 'Impressão';

    // Captura logs do Workflow Geral do PCP (Separação, Painel Master)
    if (eMod.includes('pcp') || eMod.includes('produ') || entityType.includes('production') || msg.includes('pcp') || msg.includes('produção') || msg.includes('separação') || payloadStr.includes('separation')) return 'PCP';

    if (eMod.includes('fiscal') || eMod.includes('sefaz')) return 'Fiscal';
    if (eMod.includes('expedi') || eMod.includes('estoque')) return 'Expedição';

    return 'Sistema';
};

const systemModules = [
    { id: 'Faturamento', name: 'Vendas & CRM' },
    { id: 'Design', name: 'Design' },
    { id: 'Impressão', name: 'Impressão & Calandra' },
    { id: 'PCP', name: 'Fábrica/PCP' },
    { id: 'Financeiro', name: 'Financeiro' },
    { id: 'Fiscal', name: 'Fiscal' },
    { id: 'Expedição', name: 'Logística' }
];

const setModule = (modId: string) => { filters.value.module = modId; currentPage.value = 1; selectedLog.value = null; };
const selectLog = (log: any) => { showRawJson.value = false; selectedLog.value = log; };

const uniqueUsers = computed(() => Array.from(new Set(filteredLogs.value.map(e => displayActorName(e.actor_name)).filter(n => n))));

const filteredLogs = computed(() => {
  return unifiedLogs.value.filter(e => {
    const searchLow = filters.value.search.toLowerCase();
    let matchSearch = true;

    if (searchLow) {
        const c = entityCache.value[e.entity_label] || {};
        const textToSearch = [
            displayActorName(e.actor_name) || '', e.didactic_message || '', JSON.stringify(e.after_data || {}), JSON.stringify(e.before_data || {}),
            c.name || '', c.customer_name || '', c.stamp_ref || '', c.order_number || ''
        ].join(' ').toLowerCase();
        matchSearch = textToSearch.includes(searchLow);
    }

    let matchModule = true;
    if (filters.value.module !== 'Todos') matchModule = getModuleCategory(e) === filters.value.module;

    const dbAction = actionMapToDB[filters.value.action];
    const matchAction = dbAction === 'Todas' || e.action_type === dbAction;

    return matchSearch && matchModule && matchAction;
  });
});

const totalPages = computed(() => Math.ceil(filteredLogs.value.length / itemsPerPage) || 1);
const paginatedLogs = computed(() => { const start = (currentPage.value - 1) * itemsPerPage; return filteredLogs.value.slice(start, start + itemsPerPage); });

const resetPage = () => { currentPage.value = 1; };
watch(() => filters.value, resetPage, { deep: true });

const entityTimelineEvents = computed(() => {
  if (!selectedEntityId.value) return [];
  const idLower = selectedEntityId.value.toLowerCase();
  return unifiedLogs.value.filter(log => {
      const stringified = JSON.stringify(log.after_data || {}) + JSON.stringify(log.before_data || {}) + (log.didactic_message || '');
      return stringified.toLowerCase().includes(idLower) || log.entity_label?.toLowerCase() === idLower;
  }).sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime());
});

const systemHealthScore = ref(100);

const translateUuidToName = (uuid: string) => {
   if(!uuid || uuid.length !== 36) return uuid;
   const c = entityCache.value[uuid];
   if(c && c.name) return c.name;
   return uuid;
};

const extractUUIDs = (log: any) => {
  const uuids: string[] = [];
  if(log.entity_label && log.entity_label.length === 36) uuids.push(log.entity_label);
  const dataStr = JSON.stringify(log.after_data || {}) + JSON.stringify(log.before_data || {});
  const regex = /[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}/gi;
  const matches = dataStr.match(regex);
  if (matches) matches.forEach(m => { if (!uuids.includes(m)) uuids.push(m); });
  return uuids;
};

const getContextualData = (log: any) => {
  const data = log.after_data || log.before_data || {};
  const cache = entityCache.value[log.entity_label] || {};
  const context = [];

  const orderNum = data.order_number || cache.order_number;
  const custName = data.customer_name || data.client_name || cache.customer_name || data.entity_name;
  const stampRef = data.stamp_ref || cache.stamp_ref || data.fabric_name;

  if (orderNum) context.push({ label: 'Nº Pedido/OP', value: orderNum });
  if (custName) context.push({ label: 'Referência Nominal', value: custName });
  if (stampRef) context.push({ label: 'Variável Secundária', value: stampRef });

  if (data.amount || data.value) context.push({ label: 'Cifra Envolvida', value: `R$ ${data.amount || data.value}` });
  if (data.status) context.push({ label: 'Fase/Status', value: translateValue(data.status) });
  if (data.machine) context.push({ label: 'Máquina Alocada', value: data.machine });

  return context;
};

const hasDiff = (log: any) => !!log.before_data || !!log.after_data;

const getDeepDiff = (before: any, after: any) => {
  const changes = [];
  const b = before || {};
  const a = after || {};
  const allKeys = new Set([...Object.keys(b), ...Object.keys(a)]);

  for (const key of allKeys) {
    if (['updated_at', 'created_at', 'id'].includes(key)) continue;
    const valBefore = b[key];
    const valAfter = a[key];
    if (JSON.stringify(valBefore) !== JSON.stringify(valAfter)) {
      changes.push({
        key,
        old: valBefore !== undefined ? valBefore : 'Vazio / Não Existia',
        new: valAfter !== undefined ? valAfter : 'Apagado / Removido'
      });
    }
  }
  return changes;
};

const formatKeyName = (key: string) => {
  if (!key) return 'Desconhecido';
  const dict: Record<string,string> = {
    status: 'Fase/Situação', total_value: 'Valor Total', customer_name: 'Cliente', due_date: 'Vencimento', payment_method: 'Método Pgto.',
    amount: 'Valor', value: 'Quantia', description: 'Descrição', user_id: 'Usuário', order_id: 'Pedido', product_id: 'Arte',
    company_id: 'Empresa Atrelada', bank_account_id: 'Conta Bancária', entity_name: 'Beneficiário/Pagador', machine: 'Máquina'
  };
  if (dict[key]) return dict[key];
  if (dict[key.toLowerCase()]) return dict[key.toLowerCase()];
  return key.split('_').map(w => w.charAt(0).toUpperCase() + w.slice(1)).join(' ');
};

const friendlyValues: Record<string, string> = {
  'INSERT': 'CREATE', 'UPDATE': 'UPDATE', 'DELETE': 'DELETE', 'STATUS_CHANGE': 'STATUS',
  'pendente': 'Pendente (Aberto)', 'em_aberto': 'Em Aberto', 'pago': 'Liquidado/Baixado', 'atrasado': 'Vencido'
};

const translateValue = (val: any) => {
  if (val === null || val === undefined || val === '') return 'Vazio';
  if (typeof val === 'boolean') return val ? 'Sim' : 'Não';
  if (typeof val === 'string' && val.match(/^\d{4}-\d{2}-\d{2}T/)) return new Date(val).toLocaleString('pt-BR');
  if (typeof val === 'string') {
     if(val.length === 36 && entityCache.value[val]) return entityCache.value[val].name;
     const lowerVal = val.toLowerCase();
     if (friendlyValues[lowerVal]) return friendlyValues[lowerVal];
     if (friendlyValues[val]) return friendlyValues[val];
  }
  if (Array.isArray(val)) return `[ Array c/ ${val.length} itens ]`;
  if (typeof val === 'object') return '{ Objeto JSON }';
  return val;
};

const translateActionShort = (a: string) => {
    const map: any = { 'INSERT': 'ADD', 'UPDATE': 'UPD', 'DELETE': 'DEL', 'STATUS_CHANGE': 'STS' };
    return map[a] || a.substring(0,3).toUpperCase();
};

const openEntityTimeline = (uuid: string) => { selectedEntityId.value = uuid; entityTimelineOpen.value = true; };

const getActorColor = (name: string) => {
    if(!name || name === 'Sistema' || name.includes('Módulo')) return '#64748b';
    const colors = ['#3b82f6', '#ec4899', '#8b5cf6', '#10b981', '#f59e0b', '#06b6d4'];
    const charCode = name.charCodeAt(0) || 0;
    return colors[charCode % colors.length];
};

const getActionColorVuetify = (a: string) => { const c:any = { 'INSERT': 'success', 'UPDATE': 'warning', 'DELETE': 'error', 'STATUS_CHANGE': 'info' }; return c[a] || 'grey'; };
const formatTimeFull = (iso: string) => iso ? new Date(iso).toLocaleString('pt-BR', {day:'2-digit', month:'2-digit', year:'numeric', hour:'2-digit', minute:'2-digit', second:'2-digit'}) : '';

onMounted(() => {});
onUnmounted(() => {
    if (realtimeSubscriptionPrimary) supabase.removeChannel(realtimeSubscriptionPrimary);
    if (realtimeSubscriptionFallback) supabase.removeChannel(realtimeSubscriptionFallback);
    if (realtimeSubscriptionProd) supabase.removeChannel(realtimeSubscriptionProd);
});
</script>

<style scoped lang="scss">
/* ==========================================================================
   ENTERPRISE DESIGN SYSTEM (HIGH DENSITY / PROFESSIONAL SRE)
   ========================================================================== */

/* Variables (Light / Dark) */
.theme-light {
  --bg-root: #f8fafc;
  --bg-panel: #ffffff;
  --bg-hover: #f1f5f9;
  --border-subtle: #e2e8f0;
  --border-strong: #cbd5e1;
  --text-main: #0f172a;
  --text-muted: #64748b;
  --brand-primary: #0ea5e9;

  --diff-bg-old: #fef2f2;
  --diff-text-old: #b91c1c;
  --diff-bg-new: #f0fdf4;
  --diff-text-new: #15803d;
}

.theme-dark {
  --bg-root: #020617;
  --bg-panel: #0f172a;
  --bg-hover: #1e293b;
  --border-subtle: #1e293b;
  --border-strong: #334155;
  --text-main: #f8fafc;
  --text-muted: #94a3b8;
  --brand-primary: #38bdf8;

  --diff-bg-old: rgba(239, 68, 68, 0.1);
  --diff-text-old: #ef4444;
  --diff-bg-new: rgba(16, 185, 129, 0.1);
  --diff-text-new: #10b981;
}

/* Global Reset & Typography */
* { box-sizing: border-box; }
.enterprise-cockpit {
  display: flex;
  flex-direction: column;
  height: 100vh;
  width: 100%; /* Important: Prevents horizontal scroll overflow */
  overflow: hidden;
  font-family: 'Inter', system-ui, sans-serif;
  font-size: 13px;
  background-color: var(--bg-root);
  color: var(--text-main);
}

.text-muted { color: var(--text-muted); }
.text-main { color: var(--text-main); }
.val-mono { font-family: 'JetBrains Mono', monospace; font-size: 12px; }

.custom-scrollbar::-webkit-scrollbar { width: 6px; height: 6px; }
.custom-scrollbar::-webkit-scrollbar-thumb { background: var(--border-strong); border-radius: 4px; }
.custom-scrollbar::-webkit-scrollbar-track { background: transparent; }

/* ==========================================================================
   AUTH SCREEN (Crisp & Corporate)
   ========================================================================== */
.auth-card {
  background: var(--bg-panel);
  border: 1px solid var(--border-subtle);
  border-radius: 12px;
  padding: 32px;
  text-align: center;
}
.auth-header { margin-bottom: 24px; }
.auth-icon-wrapper { display: inline-flex; padding: 16px; border-radius: 16px; background: var(--bg-hover); margin-bottom: 16px; border: 1px solid var(--border-subtle); }
.auth-title { font-size: 18px; font-weight: 800; letter-spacing: -0.02em; margin: 0; }
.auth-subtitle { font-size: 13px; color: var(--text-muted); margin: 4px 0 0; }
.auth-label { display: block; text-align: left; font-size: 11px; font-weight: 700; color: var(--text-muted); margin-bottom: 8px; letter-spacing: 0.05em; }
.auth-otp :deep(input) { font-family: 'JetBrains Mono', monospace; font-size: 24px; font-weight: bold; }
.auth-btn { letter-spacing: 0.05em; font-weight: 700; border-radius: 8px; }

/* ==========================================================================
   TOP NAVIGATION
   ========================================================================== */
.cockpit-topbar {
  display: flex; align-items: center; justify-content: space-between;
  height: 52px; padding: 0 16px;
  background-color: var(--bg-panel);
  border-bottom: 1px solid var(--border-strong);
  flex-shrink: 0; z-index: 10;
}
.topbar-left, .topbar-right { display: flex; align-items: center; gap: 16px; }

.logo-area { display: flex; align-items: center; gap: 8px; }
.system-title { font-weight: 800; font-size: 14px; letter-spacing: -0.01em; }
.badge-live { display: flex; align-items: center; gap: 4px; font-size: 10px; font-weight: 700; color: #ef4444; background: rgba(239, 68, 68, 0.1); padding: 2px 6px; border-radius: 4px; border: 1px solid rgba(239, 68, 68, 0.2); }
.pulse-dot { width: 6px; height: 6px; background-color: #ef4444; border-radius: 50%; animation: pulse 2s infinite; }
@keyframes pulse { 0% { opacity: 1; box-shadow: 0 0 0 0 rgba(239, 68, 68, 0.7); } 70% { opacity: 0.5; box-shadow: 0 0 0 4px rgba(239, 68, 68, 0); } 100% { opacity: 1; box-shadow: 0 0 0 0 rgba(239, 68, 68, 0); } }

.vertical-divider { width: 1px; height: 24px; background-color: var(--border-subtle); }

.module-nav { display: flex; gap: 4px; }
.nav-tab { background: transparent; border: 1px solid transparent; color: var(--text-muted); font-size: 12px; font-weight: 600; padding: 4px 10px; border-radius: 6px; cursor: pointer; transition: all 0.2s; }
.nav-tab:hover { color: var(--text-main); background: var(--bg-hover); }
.nav-tab.active { background: var(--bg-hover); color: var(--text-main); border-color: var(--border-subtle); box-shadow: 0 1px 2px rgba(0,0,0,0.05); }

.health-indicator { display: flex; align-items: center; font-size: 12px; }
.sync-info { display: flex; flex-direction: column; text-align: right; line-height: 1.2; }
.sync-label { font-size: 9px; text-transform: uppercase; color: var(--text-muted); font-weight: 700; }
.sync-time { font-size: 11px; font-family: 'JetBrains Mono', monospace; font-weight: 600; }
.btn-action { text-transform: none; font-weight: 600; letter-spacing: 0; border-color: var(--border-strong) !important; color: var(--text-main) !important; }

/* ==========================================================================
   MAIN LAYOUT (Split Pane)
   ========================================================================== */
.cockpit-body {
  display: flex;
  flex: 1;
  height: calc(100vh - 52px);
  overflow: hidden; /* No overflow on root level */
}

.cockpit-main {
  flex: 1;
  min-width: 0; /* Crucial: allows main area to shrink when inspector opens */
  display: flex;
  flex-direction: column;
  background-color: var(--bg-root);
}

/* FILTERS */
.filters-strip {
  display: flex; align-items: center; padding: 12px 16px; gap: 12px;
  border-bottom: 1px solid var(--border-subtle);
  background-color: var(--bg-panel);
  flex-shrink: 0;
}
.search-box {
  display: flex; align-items: center; flex: 1; max-width: 400px;
  background: var(--bg-root); border: 1px solid var(--border-strong);
  border-radius: 6px; padding: 0 10px; height: 32px;
  transition: border-color 0.2s;
}
.search-box:focus-within { border-color: var(--brand-primary); box-shadow: 0 0 0 2px rgba(14, 165, 233, 0.15); }
.search-input { width: 100%; border: none; outline: none; background: transparent; color: var(--text-main); font-size: 13px; margin-left: 8px; }
.styled-select { height: 32px; background: var(--bg-root); border: 1px solid var(--border-strong); border-radius: 6px; padding: 0 10px; color: var(--text-main); font-size: 12px; font-weight: 500; outline: none; cursor: pointer; }

.stats-mini { display: flex; gap: 16px; margin-left: auto; font-size: 12px; color: var(--text-muted); }

/* ==========================================================================
   DATA TABLE (High Density)
   ========================================================================== */
.log-table-wrapper {
  flex: 1;
  overflow: auto; /* Scrollbars specifically inside the table area */
  background-color: var(--bg-panel);
}
.data-table {
  width: 100%;
  border-collapse: separate;
  border-spacing: 0;
  text-align: left;
  table-layout: fixed; /* Ensures columns respect defined widths and don't push layouts */
}
.data-table th {
  position: sticky; top: 0; z-index: 5;
  background-color: var(--bg-hover);
  color: var(--text-muted); font-size: 11px; font-weight: 600; text-transform: uppercase; letter-spacing: 0.05em;
  padding: 8px 12px; border-bottom: 1px solid var(--border-strong);
}
.data-row { cursor: pointer; transition: background-color 0.1s; }
.data-row:hover { background-color: var(--bg-hover); }
.data-row.row-active { background-color: rgba(14, 165, 233, 0.05); }

.data-table td {
  padding: 8px 12px;
  border-bottom: 1px solid var(--border-subtle);
  vertical-align: middle;
  white-space: nowrap; overflow: hidden; text-overflow: ellipsis; /* Prevents cell expansion */
}
.cell-timestamp { font-family: 'JetBrains Mono', monospace; font-size: 11px; color: var(--text-muted); }

.badge-action { display: inline-block; padding: 2px 6px; border-radius: 4px; font-size: 10px; font-weight: 800; font-family: 'JetBrains Mono', monospace; text-align: center; width: 44px; }
.INSERT { background: var(--diff-bg-new); color: var(--diff-text-new); }
.UPDATE { background: rgba(245, 158, 11, 0.1); color: #d97706; }
.theme-dark .UPDATE { color: #fbbf24; }
.DELETE { background: var(--diff-bg-old); color: var(--diff-text-old); }
.STATUS_CHANGE { background: rgba(14, 165, 233, 0.1); color: var(--brand-primary); }

.cell-origin { font-size: 12px; font-weight: 500; }
.actor-wrap { display: flex; align-items: center; gap: 6px; }
.actor-dot { width: 8px; height: 8px; border-radius: 50%; flex-shrink: 0; }
.actor-name { font-size: 12px; font-weight: 600; overflow: hidden; text-overflow: ellipsis; }

.cell-message { font-size: 12px; color: var(--text-muted); }
.row-chevron { color: var(--border-strong); transition: color 0.2s; }
.data-row:hover .row-chevron { color: var(--brand-primary); }

.empty-state { text-align: center; padding: 64px 20px !important; }
.empty-icon { color: var(--border-strong); margin-bottom: 16px; }
.empty-title { font-size: 14px; font-weight: 600; color: var(--text-main); margin-bottom: 4px; }
.empty-subtitle { font-size: 13px; color: var(--text-muted); }

.pagination-footer { padding: 8px 16px; background-color: var(--bg-panel); border-top: 1px solid var(--border-subtle); display: flex; justify-content: flex-end; flex-shrink: 0; }

/* ==========================================================================
   INSPECTOR FORENSE (Right Sidebar - GitHub Style)
   ========================================================================== */
.inspector-panel {
  width: 0; /* Hidden by default */
  background-color: var(--bg-root);
  border-left: 0px solid var(--border-strong);
  transition: width 0.2s cubic-bezier(0.4, 0, 0.2, 1);
  overflow: hidden;
  display: flex;
  flex-direction: column;
  flex-shrink: 0; /* Prevents flex from squishing the panel */
}
.inspector-panel.panel-open { width: 450px; border-left-width: 1px; box-shadow: -4px 0 12px rgba(0,0,0,0.05); }

.inspector-container { display: flex; flex-direction: column; height: 100%; min-width: 450px; /* Forces content to maintain width during animation */ }

.inspector-header { padding: 16px 20px; background-color: var(--bg-panel); border-bottom: 1px solid var(--border-strong); display: flex; justify-content: space-between; align-items: flex-start; flex-shrink: 0; }
.sup-title { font-size: 10px; font-weight: 700; color: var(--text-muted); letter-spacing: 0.05em; display: block; margin-bottom: 4px; }
.main-title { font-size: 16px; font-weight: 800; margin: 0; }
.close-btn { color: var(--text-muted); }

.inspector-body { padding: 20px; flex: 1; overflow-y: auto; display: flex; flex-direction: column; gap: 24px; }

.section-heading { font-size: 12px; font-weight: 700; text-transform: uppercase; color: var(--text-muted); margin: 0 0 12px 0; letter-spacing: 0.02em; border-bottom: 1px solid var(--border-subtle); padding-bottom: 8px; }

.info-section { display: flex; flex-direction: column; }
.grid-2-col { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; }
.info-group label { display: block; font-size: 10px; font-weight: 600; text-transform: uppercase; color: var(--text-muted); margin-bottom: 4px; }
.badge-grey { background: var(--bg-hover); padding: 2px 6px; border-radius: 4px; border: 1px solid var(--border-subtle); display: inline-block; }
.val-text { font-size: 13px; }

.message-card { background: var(--bg-panel); border: 1px solid var(--border-strong); border-radius: 8px; padding: 12px; display: flex; gap: 10px; align-items: flex-start; box-shadow: 0 1px 2px rgba(0,0,0,0.02); }
.msg-icon { color: var(--brand-primary); margin-top: 2px; }
.msg-text { font-size: 13px; line-height: 1.5; color: var(--text-main); }

.context-list { display: flex; flex-direction: column; gap: 8px; }
.context-item { display: flex; justify-content: space-between; padding: 8px 12px; background: var(--bg-panel); border: 1px dashed var(--border-strong); border-radius: 6px; font-size: 12px; }
.ctx-label { font-weight: 600; color: var(--text-muted); }
.ctx-val { font-weight: 700; color: var(--text-main); }

/* DIFF VIEWER (Pro UI) */
.btn-toggle-diff { background: transparent; border: 1px solid var(--border-strong); color: var(--text-main); font-size: 10px; font-weight: 600; padding: 4px 8px; border-radius: 4px; cursor: pointer; transition: all 0.2s; }
.btn-toggle-diff:hover { background: var(--bg-hover); }

.diff-list { display: flex; flex-direction: column; gap: 12px; }
.diff-item { border: 1px solid var(--border-strong); border-radius: 6px; overflow: hidden; background: var(--bg-panel); }
.diff-prop-header { padding: 8px 12px; background: var(--bg-hover); border-bottom: 1px solid var(--border-subtle); display: flex; justify-content: space-between; align-items: center; font-size: 12px; }
.diff-prop-key { font-family: 'JetBrains Mono', monospace; font-size: 10px; color: var(--text-muted); }

.diff-compare-box { display: flex; flex-direction: column; }
.diff-val { display: flex; padding: 8px 12px; font-family: 'JetBrains Mono', monospace; font-size: 12px; line-height: 1.4; border-bottom: 1px solid var(--border-subtle); }
.diff-val:last-child { border-bottom: none; }
.diff-indicator { width: 16px; font-weight: bold; flex-shrink: 0; user-select: none; }
.old-val { background-color: var(--diff-bg-old); color: var(--diff-text-old); }
.new-val { background-color: var(--diff-bg-new); color: var(--diff-text-new); }

.raw-json-container { border: 1px solid var(--border-strong); border-radius: 6px; overflow: hidden; }
.json-pane { border-bottom: 1px solid var(--border-strong); }
.json-pane:last-child { border-bottom: none; }
.pane-header { padding: 6px 12px; font-size: 11px; font-weight: 700; }
.old-pane .pane-header { background-color: var(--diff-bg-old); color: var(--diff-text-old); }
.new-pane .pane-header { background-color: var(--diff-bg-new); color: var(--diff-text-new); }
.json-pane pre { margin: 0; padding: 12px; font-family: 'JetBrains Mono', monospace; font-size: 11px; background: var(--bg-panel); overflow-x: auto; }

.trace-actions { display: flex; flex-direction: column; gap: 8px; }
.btn-trace { display: flex; align-items: center; width: 100%; text-align: left; padding: 10px 12px; background: var(--bg-panel); border: 1px solid var(--border-strong); border-radius: 6px; font-size: 12px; font-weight: 600; cursor: pointer; transition: all 0.2s; color: var(--text-main); }
.btn-trace:hover { border-color: var(--brand-primary); background: rgba(14, 165, 233, 0.05); }

.empty-inspector { display: flex; flex-direction: column; align-items: center; justify-content: center; height: 100%; text-align: center; padding: 32px; color: var(--text-muted); }
.empty-icon-wrap { width: 64px; height: 64px; border-radius: 50%; background: var(--bg-panel); border: 1px dashed var(--border-strong); display: flex; align-items: center; justify-content: center; margin-bottom: 16px; }

/* ==========================================================================
   DRAWER TIMELINE (Right sliding drawer)
   ========================================================================== */
.drawer-header { padding: 16px 20px; border-bottom: 1px solid var(--border-strong); background: var(--bg-panel); display: flex; justify-content: space-between; align-items: flex-start; }
.drawer-title { font-size: 16px; font-weight: 800; margin: 0 0 4px 0; }
.drawer-uuid { font-family: 'JetBrains Mono', monospace; font-size: 11px; color: var(--text-muted); background: var(--bg-hover); padding: 2px 6px; border-radius: 4px; }
.drawer-body { padding: 20px; height: calc(100% - 70px); overflow-y: auto; background: var(--bg-root); }

.timeline-card { background: var(--bg-panel); border: 1px solid var(--border-strong); border-radius: 8px; overflow: hidden; box-shadow: 0 1px 2px rgba(0,0,0,0.02); }
.tl-header { padding: 8px 12px; background: var(--bg-hover); border-bottom: 1px solid var(--border-subtle); display: flex; justify-content: space-between; align-items: center; }
.tl-module { font-size: 10px; font-weight: 800; text-transform: uppercase; letter-spacing: 0.05em; }
.tl-time { font-family: 'JetBrains Mono', monospace; font-size: 10px; color: var(--text-muted); }
.tl-body { padding: 12px; }
.tl-actor { font-size: 11px; font-weight: 600; margin-bottom: 6px; display: flex; align-items: center; }
.tl-msg { font-size: 13px; line-height: 1.4; color: var(--text-muted); }
</style>
