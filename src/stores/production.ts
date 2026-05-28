import { defineStore } from 'pinia';
import { supabase } from '@/api/supabase';
import { useUserStore } from './user';

// -----------------------------------------------------------------------------
// Regras de Negócio (Fluxo novo vs legado)
// -----------------------------------------------------------------------------
// PERFORMANCE: Pré-calculamos o timestamp para evitar 'new Date()' dentro de loops exaustivos.
const FLOW_CUTOFF_ISO = '2026-01-05T00:00:00-03:00';
const FLOW_CUTOFF_TIME = new Date(FLOW_CUTOFF_ISO).getTime();

const toTime = (d?: string | null) => {
  if (!d) return 0;
  const t = Date.parse(d); // Date.parse é mais performático que new Date().getTime()
  return Number.isFinite(t) ? t : 0;
};

const isBeforeFlowCutoff = (iso?: string | null) => {
  if (!iso) return false;
  return toTime(iso) < FLOW_CUTOFF_TIME;
};

// -----------------------------------------------------------------------------
// Tipagens
// -----------------------------------------------------------------------------

export type SortDirection = 'asc' | 'desc';

export type OrderDeliveryBadge =
  | 'ENTREGUE'
  | 'AGUARDANDO_AGENDAMENTO'
  | 'AGENDADO'
  | 'EM_PRODUCAO'
  | 'PRONTO_PARA_ENTREGA'
  | 'INDEFINIDO';

export interface OrderLite {
  id: string;
  order_number: number;
  customer_name: string;
  details?: any;
  status: string;
  created_at?: string;
  billing_alert?: boolean;
  financial_status?: string;
  billed_at?: string | null;
  actual_delivery_date?: string | null;
  forecast_delivery_date?: string | null;
  delivery_confirmed_at?: string | null;
}

export interface ProductionItem {
  id: string;
  status: string;
  design_tag?: string;
  order_id: string;
  stamp_ref: string;
  quantity_meters: number;
  print_file_url: string;
  stamp_image_url: string;
  created_at: string;
  print_started_at?: string;
  print_ended_at?: string;
  fabric_type?: string;
  notes?: string | null;
  op_number?: number | null;
  order?: OrderLite;
  // NOVO: Controle de Reimpressão / Perdas
  reprint_info?: {
    count: number;
    total_lost_meters: number;
    history: Array<{ reason: string; lost_meters: number; date: string; operator_name: string; photo_url?: string }>;
  };
}

export interface BillingOrder {
  id: string;
  order_number: number;
  customer_name: string;
  status: string;
  financial_status: string;
  total_value: number;
  created_at: string;
  billing_queue_visible: boolean;
  billing_alert: boolean;
  details: any;
  items_count?: number;
}

export interface KanbanColumn<T = any> {
  id: string;
  title: string;
  statuses: string[];
  items: T[];
  count: number;
  legacyCount: number;
}

// -----------------------------------------------------------------------------
// Helpers de UI / Status
// -----------------------------------------------------------------------------

const normalizeFinancialStatus = (s: any) => String(s ?? '').trim().toLowerCase();

const getOrderDeliveryBadge = (order?: OrderLite | null): OrderDeliveryBadge => {
  if (!order) return 'INDEFINIDO';

  // 1) Confirmado entregue (fonte de verdade)
  if (order.delivery_confirmed_at) return 'ENTREGUE';

  // 2) Status entregue (fallback)
  if (String(order.status || '').toLowerCase() === 'delivered') return 'ENTREGUE';

  // 3) Tem data real de entrega: agendado
  if (order.actual_delivery_date) return 'AGENDADO';

  // 4) Está em expedição/pronto: aguardando agendamento
  if (['ready_for_delivery', 'waiting_release', 'completed'].includes(order.status)) return 'AGUARDANDO_AGENDAMENTO';

  // 5) Produção em andamento
  if (['in_production', 'design_pending'].includes(order.status)) return 'EM_PRODUCAO';

  return 'INDEFINIDO';
};

const compareByDate = (a?: string | null, b?: string | null, dir: SortDirection = 'desc') => {
  const ta = toTime(a);
  const tb = toTime(b);
  return dir === 'asc' ? ta - tb : tb - ta;
};

// -----------------------------------------------------------------------------
// Store
// -----------------------------------------------------------------------------

export const useProductionStore = defineStore('production', {
  state: () => ({
    // 1) Filas operacionais (Design/PCP/Separação/Impressão/Calandra/Liberação etc.)
    managementList: [] as ProductionItem[],

    // 2) Fila da estação de impressão
    printingQueue: [] as ProductionItem[],

    // NOVO: Histórico de peças já impressas
    printedHistory: [] as ProductionItem[],

    // 3) Fila de faturamento (Pedidos Pai)
    billingList: [] as BillingOrder[],

    // 4) Expedição/Liberação
    expeditionList: [] as ProductionItem[], // Itens prontos/concluídos
    ghostOrders: [] as any[], // Pedidos com data, mas sem itens prontos

    // Dados auxiliares
    activeMachines: {} as Record<string, string>,
    activeOperators: {} as Record<string, string>, // Mapeamento de operadores ativos
    availablePrinters: [] as string[],
    availableCalandras: [] as string[],
    availableOperators: [] as string[],
    currentLogs: [] as any[],
    loading: false,
  }),

  getters: {
    // Separação por fluxo (novo vs legado por data de criação do PEDIDO PAI)
    managementLegacy: (s) => s.managementList.filter(i => isBeforeFlowCutoff(i.order?.created_at || i.created_at)),
    managementCurrent: (s) => s.managementList.filter(i => !isBeforeFlowCutoff(i.order?.created_at || i.created_at)),

    expeditionLegacy: (s) => s.expeditionList.filter(i => isBeforeFlowCutoff(i.order?.created_at || i.created_at)),
    expeditionCurrent: (s) => s.expeditionList.filter(i => !isBeforeFlowCutoff(i.order?.created_at || i.created_at)),

    ghostOrdersLegacy: (s) => s.ghostOrders.filter((o: any) => isBeforeFlowCutoff(o?.created_at)),
    ghostOrdersCurrent: (s) => s.ghostOrders.filter((o: any) => !isBeforeFlowCutoff(o?.created_at)),

    // Badge de entrega (para UI: agrupado por pedido e dropdown dos itens)
    resolveOrderDeliveryBadge: () => (order?: OrderLite | null) => getOrderDeliveryBadge(order),

    // Kanban base (retorna colunas prontas para a UI montar cards)
    getKanbanColumns:
      (s) =>
      (tabId: string, opts?: { sort?: SortDirection; includeLegacy?: boolean }) => {
        const sort = opts?.sort ?? 'desc';
        const includeLegacy = opts?.includeLegacy ?? true;

        const build = (columns: Array<{ id: string; title: string; statuses: string[] }>, list: any[]) => {
          const cols: KanbanColumn[] = columns.map(c => ({ id: c.id, title: c.title, statuses: c.statuses, items: [], count: 0, legacyCount: 0 }));

          for (const item of list) {
            const status = String(item?.status || '');
            const col = cols.find(c => c.statuses.includes(status));
            if (!col) continue;

            const orderCreated = item?.order?.created_at || item?.created_at || item?.created_at;
            const isLegacy = isBeforeFlowCutoff(orderCreated);
            if (!includeLegacy && isLegacy) continue;

            col.items.push(item);
            col.count += 1;
            if (isLegacy) col.legacyCount += 1;
          }

          // Ordenação dentro da coluna
          cols.forEach(c => {
            c.items.sort((a: any, b: any) => {
              const da = a?.created_at || a?.order?.created_at;
              const db = b?.created_at || b?.order?.created_at;
              return compareByDate(da, db, sort);
            });
          });

          return cols;
        };

        // Fonte da lista por aba
        if (tabId === 'faturamento' || tabId === 'faturado') {
          const isFaturado = (o: any) => normalizeFinancialStatus(o?.financial_status) === 'faturado';
          const list = (s.billingList || []).filter(o => (tabId === 'faturado' ? isFaturado(o) : !isFaturado(o)));
          return build(
            [
              { id: 'aberto', title: 'Em Aberto', statuses: ['__billing_open__'] },
              { id: 'parcial', title: 'Parcial', statuses: ['__billing_partial__'] },
              { id: 'faturado', title: 'Faturado', statuses: ['__billing_done__'] },
            ],
            list.map((o: any) => ({
              ...o,
              // normaliza "status" só pra encaixar na coluna
              status: isFaturado(o) ? '__billing_done__' : normalizeFinancialStatus(o?.financial_status).includes('parcial') ? '__billing_partial__' : '__billing_open__',
            }))
          );
        }

        if (tabId === 'liberacao') {
          const list = [...(s.ghostOrders || []), ...(s.expeditionList || [])].map((x: any) => ({
            ...x,
            // ghosts não têm stamp_ref; mantém status consistente
            status: x?.status || 'waiting_release',
          }));
          return build(
            [
              { id: 'waiting_release', title: 'Aguardando', statuses: ['waiting_release'] },
              { id: 'ready_for_delivery', title: 'Pronto', statuses: ['ready_for_delivery'] },
              { id: 'completed', title: 'Concluído', statuses: ['completed'] },
            ],
            list
          );
        }

        // Operacional (Design/PCP/Separação/Impressão/Calandra/Legado)
        const base = s.managementList || [];

        switch (tabId) {
          case 'design':
            return build(
              [
                { id: 'design_pending', title: 'Design Pendente', statuses: ['design_pending'] },
                { id: 'customer_approval', title: 'Aprovação do Cliente', statuses: ['customer_approval'] },
                { id: 'changes_requested', title: 'Ajustes Solicitados', statuses: ['changes_requested'] },
                { id: 'approved', title: 'Aprovado', statuses: ['approved_by_seller', 'approved_by_designer'] },
              ],
              base
            );

          case 'separacao':
            return build(
              [
                { id: 'design_released', title: 'Liberado', statuses: ['design_released'] },
                { id: 'waiting_separation', title: 'Fila', statuses: ['waiting_separation'] },
                { id: 'in_separation', title: 'Separando', statuses: ['in_separation'] },
              ],
              base
            );

          case 'impressao':
            return build(
              [
                { id: 'waiting_print', title: 'Fila', statuses: ['waiting_print', 'waiting_print_rework'] },
                { id: 'printing', title: 'Imprimindo', statuses: ['printing'] },
              ],
              base
            );

          case 'calandra':
            return build(
              [
                { id: 'printed', title: 'Fila', statuses: ['printed'] },
                { id: 'waiting_calandra', title: 'Aguardando', statuses: ['waiting_calandra'] },
                { id: 'in_calandra', title: 'Em Calandra', statuses: ['in_calandra'] },
                { id: 'in_production', title: 'Em Processo', statuses: ['in_production'] },
              ],
              base
            );

          case 'legado':
            return build(
              [
                { id: 'production_queue', title: 'Fila', statuses: ['production_queue'] },
                { id: 'in_printing', title: 'Impressão', statuses: ['in_printing'] },
                { id: 'in_cutting', title: 'Corte', statuses: ['in_cutting'] },
              ],
              base
            );

          case 'pcp':
          default:
            // PCP geral: visão firme, com todas as etapas importantes em colunas
            return build(
              [
                { id: 'waiting_separation', title: 'Fila Separação', statuses: ['waiting_separation'] },
                { id: 'in_separation', title: 'Separando', statuses: ['in_separation'] },
                { id: 'waiting_print', title: 'Fila Impressão', statuses: ['waiting_print', 'waiting_print_rework'] },
                { id: 'printing', title: 'Imprimindo', statuses: ['printing'] },
                { id: 'printed', title: 'Fila Calandra', statuses: ['printed', 'waiting_calandra'] },
                { id: 'in_calandra', title: 'Em Calandra', statuses: ['in_calandra'] },
                { id: 'in_production', title: 'Em Processo', statuses: ['in_production'] },
                { id: 'billing_pending', title: 'Aguardando Faturamento', statuses: ['billing_pending'] },
                { id: 'waiting_release', title: 'Aguardando Expedição', statuses: ['waiting_release'] },
                { id: 'ready_for_delivery', title: 'Pronto p/ Entrega', statuses: ['ready_for_delivery'] },
              ],
              base
            );
        }
      },
  },

  actions: {
    // ----------------------------------------------------------------
    // Sincronização Automática (Status do Pai baseado nos itens)
    // ----------------------------------------------------------------
    async syncOrderStatus(orderId: string) {
      if (!orderId) return;
      try {
        const { data: items, error } = await supabase
          .from('order_items')
          .select('status')
          .eq('order_id', orderId);

        if (error || !items || items.length === 0) return;

        const totalItems = items.length;
        const completedCount = items.filter(i => i.status === 'completed').length;

        const inDesign = items.filter(i => ['design_pending', 'customer_approval', 'changes_requested'].includes(i.status)).length;
        // ADICIONADO waiting_print_rework PARA MANTER O PAI EM PRODUÇÃO
        const inProduction = items.filter(i => ['design_released', 'waiting_separation', 'in_separation', 'waiting_print', 'waiting_print_rework', 'printing', 'printed', 'waiting_calandra', 'in_calandra', 'in_production'].includes(i.status)).length;
        const inRelease = items.filter(i => ['waiting_release', 'ready_for_delivery'].includes(i.status)).length;

        let newOrderStatus = '';
        if (inDesign > 0) newOrderStatus = 'design_pending';
        else if (inProduction > 0) newOrderStatus = 'in_production';
        else if (inRelease > 0) newOrderStatus = 'ready_for_delivery';
        else if (completedCount === totalItems) newOrderStatus = 'completed';

        if (newOrderStatus) {
          await supabase.from('orders').update({ status: newOrderStatus }).eq('id', orderId);
        }
      } catch (err) {
        console.error('Erro syncOrderStatus:', err);
      }
    },

    // Ação acionada pelo Painel de Produção (Devolver da Calandra para Impressão)
    async reportReprintError(itemId: string, notes: string, file: File | null, printData: any) {
      const userStore = useUserStore();
      this.loading = true;

      try {
        let photoUrl = null;

        // Se o usuário anexou uma foto do defeito, faz o upload para o Storage do Supabase
        if (file) {
          const fileExt = file.name.split('.').pop();
          const fileName = `${itemId}-${Date.now()}.${fileExt}`;

          // ATENÇÃO: Verifique se o nome do seu bucket é 'production-files' ou altere conforme o seu projeto
          const { data: uploadData, error: uploadError } = await supabase.storage
            .from('production-files')
            .upload(`reprint-errors/${fileName}`, file);

          if (!uploadError && uploadData) {
             const { data: publicUrlData } = supabase.storage
              .from('production-files')
              .getPublicUrl(uploadData.path);
             photoUrl = publicUrlData.publicUrl;
          }
        }

        // 1. Volta o status do item para a fila de impressão (rework)
        const { error } = await supabase
          .from('order_items')
          .update({ status: 'waiting_print_rework' })
          .eq('id', itemId);

        if (error) throw error;

        // 2. Insere o log de evento que a sua interface (ProductionControl.vue) já espera ler
        await supabase.from('production_logs').insert({
          order_item_id: itemId,
          user_id: userStore.user?.id,
          action: 'reprint_error_reported',
          metadata: {
            reason: notes,
            photo_url: photoUrl,
            previous_print: printData,
            timestamp: new Date().toISOString()
          }
        });

        // 3. Atualiza a interface local e sincroniza o pedido pai
        this.applyLocalItemStatusUpdate([itemId], 'waiting_print_rework');

        const { data: itemData } = await supabase
          .from('order_items')
          .select('order_id')
          .eq('id', itemId)
          .single();

        if (itemData?.order_id) {
          await this.syncOrderStatus(itemData.order_id);
        }

        // Atualiza as listas da tela
        await this.fetchManagementItems();
      } catch (err) {
        console.error('Erro ao reportar reimpressão:', err);
        throw err;
      } finally {
        this.loading = false;
      }
    },

    // ----------------------------------------------------------------
    // Helpers internos (atualização local sem resetar tela)
    // ----------------------------------------------------------------
    applyLocalItemStatusUpdate(itemIds: string[], newStatus: string) {
      if (!itemIds.length) return;
      const set = new Set(itemIds.map(String));

      const patch = (arr: any[]) => {
        for (const it of arr) {
          if (it && set.has(String(it.id))) {
            it.status = newStatus;
          }
        }
      };

      patch(this.managementList as any[]);
      patch(this.printingQueue as any[]);
      patch(this.printedHistory as any[]);
      patch(this.expeditionList as any[]);
    },

    // ----------------------------------------------------------------
    // 1) Dados Mestres
    // ----------------------------------------------------------------
    async fetchMachines(type: 'printer' | 'calandra') {
      try {
        const { data } = await supabase
          .from('production_machines')
          .select('name')
          .eq('is_active', true)
          .eq('type', type)
          .order('name', { ascending: true });

        if (data) {
          const names = data.map(m => m.name);
          if (type === 'printer') this.availablePrinters = names;
          else this.availableCalandras = names;
        }
      } catch (err) {
        console.error(`Erro fetchMachines (${type}):`, err);
      }
    },

    async fetchOperators() {
      try {
        const { data } = await supabase
          .from('employees_mj')
          .select('id, nome')
          .eq('situacao', 'Ativo')
          .order('nome', { ascending: true });
        if (data) {
          this.availableOperators = data.map(e => e.nome).filter(Boolean) as string[];
        }
      } catch (err) {
        console.error('Erro fetchOperators:', err);
      }
    },

    async fetchItemLogs(itemId: string) {
      this.currentLogs = [];
      const { data } = await supabase
        .from('production_logs')
        .select(`*, user:profiles(full_name)`)
        .eq('order_item_id', itemId)
        .order('created_at', { ascending: false });
      if (data) this.currentLogs = data;
    },

    // ----------------------------------------------------------------
    // 2) Fetches por contexto
    // ----------------------------------------------------------------

    async fetchManagementItems() {
      this.loading = true;
      try {
        // AQUI ESTAVA O ERRO PARA O DYNAMIC KANBAN: Faltava o waiting_print_rework
        const targetStatuses = [
          'design_pending',
          'customer_approval',
          'approved_by_seller',
          'changes_requested',
          'approved_by_designer',
          'design_released',
          'waiting_separation',
          'in_separation',
          'waiting_print',
          'waiting_print_rework', // ADICIONADO AQUI
          'printing',
          'printed',
          'waiting_calandra',
          'in_calandra',
          'in_production',
          'billing_pending',
          'waiting_release',
          'ready_for_delivery',
          // legado
          'production_queue',
          'in_printing',
          'in_cutting',
        ];

        const selectOrder = 'id, order_number, customer_name, details, status, created_at, billing_alert, financial_status, billed_at, actual_delivery_date, forecast_delivery_date, delivery_confirmed_at';

        // Itens ativos
        const { data: activeItems, error: activeError } = await supabase
          .from('order_items')
          .select(`*, order:orders(${selectOrder})`)
          .in('status', targetStatuses)
          .order('created_at', { ascending: false })
          .limit(1000000);

        if (activeError) throw activeError;

        let finalItems: any[] = activeItems || [];

        // Histórico recente (concluídos)
        const { data: recentCompleted, error: completedError } = await supabase
          .from('order_items')
          .select(`*, order:orders(${selectOrder})`)
          .eq('status', 'completed')
          .order('created_at', { ascending: false })
          .limit(1000000);

        if (!completedError && recentCompleted) {
          finalItems = [...finalItems, ...recentCompleted];
        }

        finalItems.sort((a, b) => compareByDate(a?.created_at, b?.created_at, 'desc'));
        this.managementList = finalItems as ProductionItem[];
      } catch (err) {
        console.error('Erro na Store (fetchManagementItems):', err);
      } finally {
        this.loading = false;
      }
    },

    async fetchBillingOrders() {
      this.loading = true;
      try {
        const { data, error } = await supabase
          .from('orders')
          .select('id, order_number, customer_name, status, financial_status, total_value, created_at, billing_queue_visible, billing_alert, details, billed_at, actual_delivery_date, forecast_delivery_date, delivery_confirmed_at')
          .order('created_at', { ascending: false })
          .limit(100000);

        if (error) throw error;
        this.billingList = data as BillingOrder[];
      } catch (err) {
        console.error('Erro fetchBillingOrders:', err);
      } finally {
        this.loading = false;
      }
    },

    async fetchExpeditionData() {
      this.loading = true;
      try {
        // Itens prontos
        const { data: readyItems, error: readyError } = await supabase
          .from('order_items')
          .select('*, order:orders!inner(id, order_number, customer_name, created_at, status, actual_delivery_date, forecast_delivery_date, delivery_confirmed_at)')
          .in('order.status', ['completed', 'ready_for_delivery', 'delivered', 'waiting_release'])
          .order('created_at', { ascending: false })
          .limit(100000);

        if (readyError) throw readyError;
        this.expeditionList = (readyItems || []) as ProductionItem[];

        // Pedidos agendados sem itens prontos
        const { data: scheduledOrders, error: ghostError } = await supabase
          .from('orders')
          .select('id, order_number, customer_name, created_at, actual_delivery_date, forecast_delivery_date, delivery_confirmed_at, status')
          .not('actual_delivery_date', 'is', null)
          .neq('status', 'delivered')
          .neq('status', 'archived')
          .order('created_at', { ascending: false })
          .limit(100000);

        if (ghostError) throw ghostError;

        const readyOrderIds = new Set(this.expeditionList.map(i => i.order_id));
        this.ghostOrders = (scheduledOrders || []).filter(o => !readyOrderIds.has(o.id));
      } catch (err) {
        console.error('Erro fetchExpeditionData:', err);
      } finally {
        this.loading = false;
      }
    },

    async fetchPrintingQueue() {
      this.loading = true;
      try {
        if (this.availablePrinters.length === 0) await this.fetchMachines('printer');
        const selectOrder = 'id, order_number, customer_name, details, status, created_at, actual_delivery_date, forecast_delivery_date, delivery_confirmed_at';

        // AQUI ESTAVA O ERRO DO PRINTING STATION: Faltava o waiting_print_rework
        const { data } = await supabase
          .from('order_items')
          .select(`*, order:orders(${selectOrder})`)
          .in('status', ['waiting_print', 'printing', 'waiting_print_rework'])
          .order('created_at', { ascending: true })
          .limit(100000);

        if (data) this.printingQueue = data as any;
        await this.fetchActiveMachines();
      } catch (err) {
        console.error(err);
      } finally {
        this.loading = false;
      }
    },

    // Busca histórico para a estação de impressão (Histórico de Liberação)
async fetchPrintedHistory() {
      this.loading = true;
      try {
        const selectOrder = 'id, order_number, customer_name, status';
        const { data } = await supabase
          .from('order_items')
          .select(`*, order:orders(${selectOrder})`)
          .in('status', ['printed', 'waiting_calandra', 'in_calandra', 'in_production', 'billing_pending', 'waiting_release', 'ready_for_delivery', 'completed'])
          .order('print_ended_at', { ascending: false, nullsFirst: false })
          .limit(200); // Traz os últimos 200 impressos

        if (data) {
          this.printedHistory = data as any;

          const historyIds = data.map((i: any) => i.id);
          if (historyIds.length > 0) {
            const { data: logs } = await supabase
              .from('production_logs')
              .select('order_item_id, action, metadata, user:profiles(full_name)')
              .in('action', ['finish_print', 'start_print'])
              .in('order_item_id', historyIds)
              .limit(1000000) // O SEGREDO AQUI: Quebra a trava de 1000 linhas do Supabase
              .order('created_at', { ascending: false });

            if (logs && logs.length > 0) {
              const opMap: Record<string, string> = { ...this.activeOperators };
              const machineMap: Record<string, string> = { ...this.activeMachines };

              logs.forEach(log => {
                // 1. Popula o Operador
                if (!opMap[log.order_item_id] && log.user?.full_name) {
                  opMap[log.order_item_id] = log.user.full_name;
                }

                // 2. Popula a Máquina lendo ESTRITAMENTE do log de start_print
                if (log.action === 'start_print' && log.metadata?.machine && log.metadata.machine !== 'N/A') {
                  if (!machineMap[log.order_item_id]) {
                    machineMap[log.order_item_id] = log.metadata.machine;
                  }
                }
              });

              this.activeOperators = opMap;
              this.activeMachines = machineMap;
            }
          }
        }
      } catch (err) {
        console.error(err);
      } finally {
        this.loading = false;
      }
    },

    async fetchActiveMachines() {
      const printingIds = this.printingQueue.filter(i => i.status === 'printing').map(i => i.id);
      if (printingIds.length === 0) {
        // ATENÇÃO: Nunca zere a variável this.activeMachines aqui,
        // senão os dados da aba Histórico somem da tela quando a Fila Atual estiver vazia.
        return;
      }
      try {
        const { data } = await supabase
          .from('production_logs')
          .select('order_item_id, metadata, user:profiles(full_name)')
          .eq('action', 'start_print')
          .in('order_item_id', printingIds)
          .order('created_at', { ascending: false });

        const map: Record<string, string> = { ...this.activeMachines };
        const opMap: Record<string, string> = { ...this.activeOperators };

        data?.forEach(log => {
          if (!map[log.order_item_id] && log.metadata?.machine && log.metadata.machine !== 'N/A') {
            map[log.order_item_id] = log.metadata.machine;
          }
          if (!opMap[log.order_item_id] && log.user?.full_name) {
            opMap[log.order_item_id] = log.user.full_name;
          }
        });

        this.activeMachines = map;
        this.activeOperators = opMap;
      } catch (e) {
        console.error(e);
      }
    },

    async verifyPin(pin: string, userIdOverride?: string): Promise<boolean> {
      const userStore = useUserStore();
      const targetUserId = userIdOverride || userStore.user?.id;
      if (!targetUserId) return false;
      const { data } = await supabase.from('profiles').select('security_pin').eq('id', targetUserId).single();
      return !!(data && String(data.security_pin).trim() === String(pin).trim());
    },

    async fetchLastPrintData(itemId: string) {
      try {
        const { data } = await supabase
          .from('production_logs')
          .select('created_at, metadata, user:profiles(full_name)')
          .eq('order_item_id', itemId)
          .eq('action', 'start_print')
          .order('created_at', { ascending: false })
          .limit(1)
          .single();
        return data;
      } catch (e) {
        return null;
      }
    },

    // Ação de Solicitar Reimpressão da Estação de Impressão e Contabilizar Perdas
    async requestReprint(itemId: string, reason: string, lostMeters: number, pin: string, operatorId?: string, operatorName?: string) {
      const userStore = useUserStore();
      const opId = operatorId || userStore.user?.id;
      const isPinValid = await this.verifyPin(pin, opId);
      if (!isPinValid) throw new Error('PIN de segurança incorreto.');

      this.loading = true;
      try {
        const { data: currentItem } = await supabase.from('order_items').select('reprint_info, order_id').eq('id', itemId).single();

        const currentInfo = currentItem?.reprint_info || { count: 0, total_lost_meters: 0, history: [] };
        const newInfo = {
          count: (currentInfo.count || 0) + 1,
          total_lost_meters: (currentInfo.total_lost_meters || 0) + lostMeters,
          history: [
            ...(currentInfo.history || []),
            { reason, lost_meters: lostMeters, date: new Date().toISOString(), operator_name: operatorName || 'Operador' }
          ]
        };

        const { error } = await supabase
          .from('order_items')
          .update({
            status: 'waiting_print_rework', // ADICIONADO: Envia pro status real de retrabalho
            reprint_info: newInfo
          })
          .eq('id', itemId);

        if (error) throw error;

        await supabase.from('production_logs').insert({
          order_item_id: itemId,
          user_id: opId,
          action: 'reprint_requested',
          metadata: { reason, lost_meters: lostMeters, timestamp: new Date().toISOString() }
        });

        if (currentItem?.order_id) await this.syncOrderStatus(currentItem.order_id);

        await this.fetchPrintingQueue();
        await this.fetchPrintedHistory();

      } catch (err) {
        console.error('Erro na reimpressão:', err);
        throw err;
      } finally {
        this.loading = false;
      }
    },

    // ----------------------------------------------------------------
    // 3) Ações (workflow)
    // ----------------------------------------------------------------

    async moveStage(itemId: string, newStatus: string, actionLog: string, extraData: any = {}, opts?: { refresh?: boolean }) {
      const userStore = useUserStore();
      const refresh = opts?.refresh ?? true;
      const { data: itemData, error } = await supabase
        .from('order_items')
        .update({ status: newStatus })
        .eq('id', itemId)
        .select('order_id')
        .single();
      if (error) throw error;

      this.applyLocalItemStatusUpdate([itemId], newStatus);

      await supabase.from('production_logs').insert({
        order_item_id: itemId,
        user_id: userStore.user?.id,
        action: actionLog,
        metadata: { timestamp: new Date().toISOString(), triggered_by: 'pcp_manager', ...extraData },
      });

      if (itemData?.order_id) await this.syncOrderStatus(itemData.order_id);
      if (refresh) await this.fetchManagementItems();
    },

    async setBillingVisibility(orderIds: string[], visible: boolean) {
      if (!orderIds.length) return;
      try {
        await supabase.from('orders').update({ billing_queue_visible: visible }).in('id', orderIds);
        const set = new Set(orderIds);
        this.billingList = this.billingList.map(o => (set.has(o.id) ? { ...o, billing_queue_visible: visible } : o));
      } catch (err) {
        console.error('Erro setBillingVisibility:', err);
        throw err;
      }
    },

    async toggleBillingAlert(orderId: string, currentStatus: boolean) {
      try {
        await supabase.from('orders').update({ billing_alert: !currentStatus }).eq('id', orderId);
        this.billingList = this.billingList.map(o => (o.id === orderId ? { ...o, billing_alert: !currentStatus } : o));
      } catch (err) {
        console.error('Erro toggleBillingAlert:', err);
      }
    },

    async advanceToRelease(itemIds: string[], orderId?: string, opts?: { refresh?: boolean }) {
      const userStore = useUserStore();
      const refresh = opts?.refresh ?? true;
      try {
        let ids = itemIds;
        if ((!ids || ids.length === 0) && orderId) {
          const { data: items } = await supabase.from('order_items').select('id').eq('order_id', orderId);
          ids = (items || []).map((i: any) => i.id);
        }
        if (!ids.length) return;

        await supabase.from('order_items').update({ status: 'completed' }).in('id', ids);
        this.applyLocalItemStatusUpdate(ids, 'completed');

        const logs = ids.map(id => ({
          order_item_id: id,
          user_id: userStore.user?.id,
          action: 'advanced_to_release',
          metadata: { timestamp: new Date().toISOString(), triggered_by: 'billing_tab' },
        }));
        await supabase.from('production_logs').insert(logs);

        if (orderId) await this.syncOrderStatus(orderId);
        else {
          const { data: distinctOrders } = await supabase.from('order_items').select('order_id').in('id', ids);
          const uniqueOids = [...new Set((distinctOrders || []).map((i: any) => i.order_id))];
          for (const oid of uniqueOids) await this.syncOrderStatus(oid);
        }

        if (refresh) await this.fetchBillingOrders();
      } catch (err) {
        console.error('Erro advanceToRelease:', err);
        throw err;
      }
    },

    async forceUpdateItemStatus(itemId: string, newStatus: string, opts?: { refresh?: boolean }) {
      const userStore = useUserStore();
      const refresh = opts?.refresh ?? true;
      const { data: item } = await supabase
        .from('order_items')
        .update({ status: newStatus })
        .eq('id', itemId)
        .select('order_id')
        .single();

      this.applyLocalItemStatusUpdate([itemId], newStatus);

      await supabase.from('production_logs').insert({
        order_item_id: itemId,
        user_id: userStore.user?.id,
        action: 'force_status_update',
        metadata: { new_status: newStatus, timestamp: new Date().toISOString() },
      });

      if (item?.order_id) await this.syncOrderStatus(item.order_id);
      if (refresh) {
        await this.fetchManagementItems();
        await this.fetchExpeditionData();
      }
    },

    async forceBatchUpdateByOrder(orderId: string, newStatus: string, opts?: { refresh?: boolean }) {
      const userStore = useUserStore();
      const refresh = opts?.refresh ?? true;
      const { data: items } = await supabase.from('order_items').select('id').eq('order_id', orderId);
      if (!items || !items.length) return;
      const ids = items.map((i: any) => i.id);

      await supabase.from('order_items').update({ status: newStatus }).in('id', ids);
      this.applyLocalItemStatusUpdate(ids, newStatus);

      const logs = ids.map(id => ({
        order_item_id: id,
        user_id: userStore.user?.id,
        action: 'force_batch_order_update',
        metadata: { new_status: newStatus, timestamp: new Date().toISOString() },
      }));
      await supabase.from('production_logs').insert(logs);

      await this.syncOrderStatus(orderId);
      if (refresh) {
        await this.fetchManagementItems();
        await this.fetchExpeditionData();
      }
    },

    async batchUpdateStatus(itemIds: string[], newStatus: string, actionLog: string, extraData: any = {}, opts?: { refresh?: boolean }) {
      if (!itemIds.length) return;
      const userStore = useUserStore();
      const refresh = opts?.refresh ?? true;
      try {
        await supabase.from('order_items').update({ status: newStatus }).in('id', itemIds);
        this.applyLocalItemStatusUpdate(itemIds, newStatus);

        const logs = itemIds.map(id => ({
          order_item_id: id,
          user_id: userStore.user?.id,
          action: actionLog,
          metadata: { timestamp: new Date().toISOString(), triggered_by: 'pcp_batch', ...extraData },
        }));
        await supabase.from('production_logs').insert(logs);

        const { data: items } = await supabase.from('order_items').select('order_id').in('id', itemIds);
        if (items) {
          const uniqueOids = [...new Set(items.map((i: any) => i.order_id))];
          for (const oid of uniqueOids) await this.syncOrderStatus(oid);
        }

        if (refresh) await this.fetchManagementItems();
      } catch (err) {
        console.error(err);
        throw err;
      }
    },

    async updatePrintStatus(itemId: string, newStatus: string, actionLog: string, pin: string, machineName?: string, authorizedUserId?: string, opts?: { refresh?: boolean }) {
      const userStore = useUserStore();
      const refresh = opts?.refresh ?? true;
      const operatorId = authorizedUserId || userStore.user?.id;
      const isPinValid = await this.verifyPin(pin, operatorId);
      if (!isPinValid) throw new Error('PIN de segurança incorreto.');

      const updatePayload: any = { status: newStatus };
      if (newStatus === 'printing') updatePayload.print_started_at = new Date().toISOString();
      if (newStatus === 'printed') updatePayload.print_ended_at = new Date().toISOString();

      const { data: itemData, error } = await supabase
        .from('order_items')
        .update(updatePayload)
        .eq('id', itemId)
        .select('order_id')
        .single();
      if (error) throw error;

      this.applyLocalItemStatusUpdate([itemId], newStatus);

      await supabase.from('production_logs').insert({
        order_item_id: itemId,
        user_id: operatorId,
        action: actionLog,
        metadata: {
          machine: machineName || 'N/A',
          device: navigator.userAgent,
          timestamp: new Date().toISOString(),
          logged_session_user: userStore.user?.id,
          divergent_auth: operatorId !== userStore.user?.id,
        },
      });

      if (itemData?.order_id) await this.syncOrderStatus(itemData.order_id);
      if (refresh) await this.fetchPrintingQueue();
    },

    async adminUpdateItem(itemId: string, updates: {
      stamp_ref?: string;
      quantity_meters?: number;
      status?: string;
      machine?: string;
      operator_name?: string;
    }) {
      const userStore = useUserStore();
      try {
        const itemUpdate: any = {};
        if (updates.stamp_ref !== undefined) itemUpdate.stamp_ref = updates.stamp_ref;
        if (updates.quantity_meters !== undefined) itemUpdate.quantity_meters = updates.quantity_meters;
        if (updates.status !== undefined) itemUpdate.status = updates.status;

        const { data: itemData, error: itemError } = await supabase
          .from('order_items')
          .update(itemUpdate)
          .eq('id', itemId)
          .select('order_id')
          .single();

        if (itemError) throw itemError;

        await supabase.from('production_logs').insert({
          order_item_id: itemId,
          user_id: userStore.user?.id,
          action: 'admin_manual_edit',
          metadata: {
            timestamp: new Date().toISOString(),
            triggered_by: 'admin_edit_modal',
            machine: updates.machine,
            operator_name: updates.operator_name,
            updates: updates
          },
        });

        if (itemData?.order_id) await this.syncOrderStatus(itemData.order_id);

        this.applyLocalItemStatusUpdate([itemId], updates.status || '');
        await this.fetchPrintingQueue();
      } catch (err) {
        console.error('Erro no adminUpdateItem:', err);
        throw err;
      }
    },

    // ----------------------------------------------------------------
    // 4) Entrega (pedido pai)
    // ----------------------------------------------------------------

    async confirmOrderDelivered(orderId: string, opts?: { actualDeliveryDate?: string; refresh?: boolean }) {
      if (!orderId) return;
      const refresh = opts?.refresh ?? true;
      const nowIso = new Date().toISOString();
      const today = new Date();
      const yyyy = today.getFullYear();
      const mm = String(today.getMonth() + 1).padStart(2, '0');
      const dd = String(today.getDate()).padStart(2, '0');
      const todayDate = `${yyyy}-${mm}-${dd}`;

      const payload: any = {
        status: 'delivered',
        delivery_confirmed_at: nowIso,
      };
      if (opts?.actualDeliveryDate) payload.actual_delivery_date = opts.actualDeliveryDate;
      else payload.actual_delivery_date = todayDate;

      await supabase.from('orders').update(payload).eq('id', orderId);

      this.managementList = this.managementList.map(i => {
        if (i?.order?.id === orderId) {
          return { ...i, order: { ...(i.order as any), status: 'delivered', delivery_confirmed_at: nowIso, actual_delivery_date: payload.actual_delivery_date } };
        }
        return i;
      });
      this.expeditionList = this.expeditionList.map(i => {
        if (i?.order?.id === orderId) {
          return { ...i, order: { ...(i.order as any), status: 'delivered', delivery_confirmed_at: nowIso, actual_delivery_date: payload.actual_delivery_date } };
        }
        return i;
      });
      this.ghostOrders = (this.ghostOrders || []).map((o: any) => (o?.id === orderId ? { ...o, status: 'delivered', delivery_confirmed_at: nowIso, actual_delivery_date: payload.actual_delivery_date } : o));

      if (refresh) await this.fetchExpeditionData();
    },

    async confirmOrdersDelivered(orderIds: string[], opts?: { refresh?: boolean }) {
      const ids = (orderIds || []).filter(Boolean);
      if (!ids.length) return;
      const refresh = opts?.refresh ?? true;
      const nowIso = new Date().toISOString();
      const today = new Date();
      const yyyy = today.getFullYear();
      const mm = String(today.getMonth() + 1).padStart(2, '0');
      const dd = String(today.getDate()).padStart(2, '0');
      const todayDate = `${yyyy}-${mm}-${dd}`;

      await supabase
        .from('orders')
        .update({ status: 'delivered', delivery_confirmed_at: nowIso, actual_delivery_date: todayDate })
        .in('id', ids);

      const set = new Set(ids);
      this.managementList = this.managementList.map(i => (i?.order?.id && set.has(i.order.id) ? { ...i, order: { ...(i.order as any), status: 'delivered', delivery_confirmed_at: nowIso, actual_delivery_date: todayDate } } : i));
      this.expeditionList = this.expeditionList.map(i => (i?.order?.id && set.has(i.order.id) ? { ...i, order: { ...(i.order as any), status: 'delivered', delivery_confirmed_at: nowIso, actual_delivery_date: todayDate } } : i));
      this.ghostOrders = (this.ghostOrders || []).map((o: any) => (o?.id && set.has(o.id) ? { ...o, status: 'delivered', delivery_confirmed_at: nowIso, actual_delivery_date: todayDate } : o));

      if (refresh) await this.fetchExpeditionData();
    },
  },
});
