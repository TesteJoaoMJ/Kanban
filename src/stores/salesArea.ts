import { defineStore } from 'pinia';
import { supabase } from '@/api/supabase';
import { startOfMonth, endOfMonth, subDays, isAfter, isBefore, format, parseISO, differenceInDays } from 'date-fns';
import { ptBR } from 'date-fns/locale';

export const useSalesAreaStore = defineStore('salesArea', {
  state: () => ({
    loading: false,
    currentDate: new Date(),
    // Dados Brutos
    orders: [] as any[], // Pedidos do período atual (detalhado)
    receivables: [] as any[], // Financeiro do período
    customers: [] as any[], // Base de clientes completa
    allOrdersHistory: [] as any[], // Histórico COMPLETO para cálculo preciso de churn/novos

    // Filtros de Visualização
    rankingFilter: 'money' as 'money' | 'area', // Alterna entre Ranking por Valor ou Metragem
  }),

  getters: {
    // --- Datas do Período ---
    periodStart(): Date { return startOfMonth(this.currentDate); },
    periodEnd(): Date { return endOfMonth(this.currentDate); },
    periodLabel(): string { return format(this.currentDate, 'MMMM yyyy', { locale: ptBR }); },

    // --- Listas Processadas ---
    ordersInPeriod(state): any[] {
      return state.orders.filter(o => {
        const d = new Date(o.created_at);
        return isAfter(d, subDays(this.periodStart, 1)) && isBefore(d, this.periodEnd);
      });
    },

    // --- KPIs Principais ---
    kpis(state): any[] {
      // Cálculo baseado nos pedidos filtrados por período
      const currentRevenue = this.ordersInPeriod.reduce((acc, o) => acc + (Number(o.total_value) || 0), 0);
      const currentMeters = this.ordersInPeriod.reduce((acc, o) => acc + (Number(o.quantity_meters) || 0), 0);
      const orderCount = this.ordersInPeriod.length;
      const ticket = orderCount > 0 ? currentRevenue / orderCount : 0;

      // Financeiro Real (O que caiu na conta vs O que foi faturado)
      const totalReceivable = state.receivables.reduce((acc, r) => acc + (Number(r.value) || 0), 0);
      const totalPaid = state.receivables.reduce((acc, r) => acc + (Number(r.paid_value) || 0), 0);
      const financialHealth = totalReceivable > 0 ? (totalPaid / totalReceivable) * 100 : 0;

      return [
        {
          label: 'Faturamento (Vendas)',
          value: this.formatCurrency(currentRevenue),
          prefix: '', suffix: '',
          footer: `${this.ordersInPeriod.length} pedidos no período`,
          icon: 'mdi-currency-usd',
          gradient: 'bg-gradient-green'
        },
        {
          label: 'Produção (Metragem)',
          value: Math.round(currentMeters).toLocaleString('pt-BR'),
          prefix: '', suffix: 'm²',
          footer: 'Área total processada',
          icon: 'mdi-layers-outline',
          gradient: 'bg-gradient-info'
        },
        {
          label: 'Financeiro (Recebido)',
          value: this.formatCurrency(totalPaid),
          prefix: '', suffix: '',
          footer: `De ${this.formatCurrency(totalReceivable)} faturado (${financialHealth.toFixed(1)}%)`,
          icon: 'mdi-cash-check',
          gradient: 'bg-gradient-purple'
        },
        {
          label: 'Ticket Médio',
          value: this.formatCurrency(ticket),
          prefix: '', suffix: '',
          footer: 'Por pedido realizado',
          icon: 'mdi-trending-up',
          gradient: 'bg-gradient-warning'
        }
      ];
    },

    // --- RANKING DE VENDEDORES (LÓGICA CORRIGIDA) ---
    sellerRanking(state): any[] {
      const rankingMap = new Map();

      this.ordersInPeriod.forEach(order => {
        let sellerId = 'sys';
        let sellerName = 'Sistema/Admin';
        let avatar = null;

        // 1. Verifica se o cliente tem um DONO (Vendedor Responsável)
        // Essa é a regra de ouro: O dono da carteira ganha a comissão/metragem.
        if (order.customer && order.customer.vendedor_responsavel_id) {
             sellerId = order.customer.vendedor_responsavel_id;
             // Tenta pegar o nome do objeto join 'responsible_salesperson'
             sellerName = order.customer.responsible_salesperson?.full_name || 'Vendedor Responsável';
        }
        // 2. Se não tiver dono (cliente órfão), usa quem criou o pedido (created_by)
        else if (order.created_by) {
             sellerId = order.created_by.id;
             sellerName = order.created_by.full_name;
             avatar = order.created_by.avatar_url;
        }

        // Ignorar usuários técnicos/bots se necessário
        if (sellerName.toLowerCase().includes('bot')) return;

        if (!rankingMap.has(sellerId)) {
          rankingMap.set(sellerId, {
            id: sellerId,
            name: sellerName,
            avatar: avatar,
            value: 0,     // Soma monetária
            area: 0,      // Soma de metragem
            count: 0,     // Qtd de pedidos
            orders: [] as any[] // Lista detalhada para auditoria
          });
        }

        const current = rankingMap.get(sellerId);

        // Acumula valores
        const val = Number(order.total_value) || 0;
        const met = Number(order.quantity_meters) || 0;

        current.value += val;
        current.area += met;
        current.count += 1;

        current.orders.push({
            id: order.id,
            date: order.created_at,
            client: order.customer?.nome || 'Consumidor Final',
            value: val,
            meters: met
        });
      });

      const list = Array.from(rankingMap.values());

      // Total base para cálculo de porcentagem (depende do filtro ativo)
      const totalBase = list.reduce((acc, i) => acc + (state.rankingFilter === 'money' ? i.value : i.area), 0);

      // Ordenação dinâmica baseada no filtro (money vs area)
      return list
        .sort((a, b) => state.rankingFilter === 'money' ? b.value - a.value : b.area - a.area)
        .map(seller => ({
          ...seller,
          // Porcentagem relativa ao total do período
          pct: totalBase > 0 ? ((state.rankingFilter === 'money' ? seller.value : seller.area) / totalBase) * 100 : 0
        }));
    },

    // Clientes Inativos (> 30 dias sem compra)
    // Ordenado por: Mais Recentes (que acabaram de ficar inativos) primeiro
    inactiveCustomersList(state): any[] {
        // Mapa da última compra de cada cliente baseado no HISTÓRICO COMPLETO
        const lastBuyMap = new Map();

        state.allOrdersHistory.forEach(order => {
            if (!order.customer_id) return;
            const currentDate = new Date(order.created_at);

            if (!lastBuyMap.has(order.customer_id)) {
                lastBuyMap.set(order.customer_id, {
                    date: currentDate,
                    seller: order.created_by?.full_name || 'Sistema',
                    order_id: order.id,
                    order_val: order.total_value
                });
            } else {
                const existing = lastBuyMap.get(order.customer_id);
                if (isAfter(currentDate, existing.date)) {
                   lastBuyMap.set(order.customer_id, {
                       date: currentDate,
                       seller: order.created_by?.full_name || 'Sistema',
                       order_id: order.id,
                       order_val: order.total_value
                   });
                }
            }
        });

        const inactiveLimit = subDays(new Date(), 30); // Regra de 30 dias para inatividade comercial
        const result = [] as any[];

        // Cruza com a lista de clientes cadastrados
        state.customers.forEach(cust => {
            const lastBuyData = lastBuyMap.get(cust.id);

            // Cenário 1: Já comprou, mas faz tempo
            if (lastBuyData) {
                if (isBefore(lastBuyData.date, inactiveLimit)) {
                    result.push({
                        ...cust,
                        status: 'inativo',
                        last_buy: lastBuyData.date,
                        last_order_id: lastBuyData.order_id,
                        last_order_value: lastBuyData.order_val,
                        days_inactive: differenceInDays(new Date(), lastBuyData.date),
                        last_seller: lastBuyData.seller
                    });
                }
            } else {
                // Cenário 2: Nunca comprou (baseado na data de cadastro)
                const created = new Date(cust.created_at);
                if (isBefore(created, inactiveLimit)) {
                      result.push({
                        ...cust,
                        status: 'sem_compra',
                        last_buy: created,
                        last_order_id: null,
                        last_order_value: 0,
                        days_inactive: differenceInDays(new Date(), created),
                        last_seller: 'Nunca comprou'
                    });
                }
            }
        });

        // Ordenar por DATA DA ÚLTIMA COMPRA (Decrescente)
        return result.sort((a, b) => new Date(b.last_buy).getTime() - new Date(a.last_buy).getTime());
    },

    // Novos e Reativados no Período Atual
    activeNewsList(state): any[] {
        const result = [] as any[];
        const processedClients = new Set();

        // Itera sobre os pedidos DO MÊS ATUAL
        this.ordersInPeriod.forEach(order => {
             if (!order.customer_id) return;
             if (processedClients.has(order.customer_id)) return; // Evita duplicar cliente na lista

             processedClients.add(order.customer_id);

             const customer = state.customers.find(c => c.id === order.customer_id);
             if (!customer) return;

             // Verifica no histórico TOTAL se houve compra ANTES do início deste mês
             const hasPreviousPurchase = state.allOrdersHistory.some(h =>
                 h.customer_id === order.customer_id &&
                 isBefore(new Date(h.created_at), this.periodStart)
             );

             result.push({
                 id: customer.id,
                 nome: customer.nome || customer.razao_social || 'Cliente sem nome',
                 type: hasPreviousPurchase ? 'Reativado' : 'Novo',
                 seller: order.created_by?.full_name || 'Sistema',
                 val: Number(order.total_value),
                 current_order_id: order.id,
                 current_order_date: order.created_at,
                 whatsapp: customer.celular || customer.telefone,
                 email: customer.email
             });
        });

        return result.sort((a, b) => new Date(b.current_order_date).getTime() - new Date(a.current_order_date).getTime());
    },

    // Gráfico: Vendas diárias
    chartData(state): any {
        const daysInMonth = differenceInDays(this.periodEnd, this.periodStart) + 1;
        const labels = [] as string[];
        const dataMoney = new Array(daysInMonth).fill(0);
        const dataArea = new Array(daysInMonth).fill(0);

        for (let i = 0; i < daysInMonth; i++) {
            const d = new Date(this.periodStart);
            d.setDate(d.getDate() + i);
            labels.push(format(d, 'dd/MM'));
        }

        this.ordersInPeriod.forEach(o => {
            const date = new Date(o.created_at);
            const dayDiff = differenceInDays(date, this.periodStart);

            if (dayDiff >= 0 && dayDiff < daysInMonth) {
                dataMoney[dayDiff] += Number(o.total_value) || 0;
                dataArea[dayDiff] += Number(o.quantity_meters) || 0;
            }
        });

        return {
            labels,
            series: [
                { name: 'Vendas (R$)', type: 'column', data: dataMoney.map(v => Number(v.toFixed(2))) },
                { name: 'Metragem (m²)', type: 'line', data: dataArea.map(v => Number(v.toFixed(2))) }
            ]
        };
    },

    // Performance por Loja
    storePerformance(state): any[] {
        const stores = new Map();

        this.ordersInPeriod.forEach(o => {
            const storeName = o.store?.name || 'Matriz/Padrão';
            const storeId = o.store_id || 'default';

            if(!stores.has(storeId)) {
                stores.set(storeId, { id: storeId, name: storeName, total: 0, area: 0, count: 0 });
            }

            const st = stores.get(storeId);
            st.total += Number(o.total_value) || 0;
            st.area += Number(o.quantity_meters) || 0;
            st.count++;
        });

        return Array.from(stores.values()).map(s => ({
            ...s,
            avg: s.total / s.count,
            performance: Math.min((s.total / 50000) * 100, 100).toFixed(0)
        }));
    }
  },

  actions: {
    formatCurrency(val: number) {
      return new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(val);
    },

    setPeriod(direction: number) {
        const d = new Date(this.currentDate);
        d.setMonth(d.getMonth() + direction);
        this.currentDate = d;
        this.fetchData();
    },

    async fetchData() {
        this.loading = true;
        try {
            const startISO = this.periodStart.toISOString();
            const endISO = this.periodEnd.toISOString();

            // 1. Buscar Pedidos do Mês (Detalhado com Joins para Vendedor Responsável)
            const { data: currentOrders, error: errOrders } = await supabase
                .from('orders')
                .select(`
                    id, created_at, total_value, quantity_meters, status, customer_id, store_id,
                    created_by:created_by(id, full_name, avatar_url),
                    customer:customers_mj(
                        nome,
                        razao_social,
                        vendedor_responsavel_id,
                        responsible_salesperson:vendedor_responsavel_id(full_name)
                    ),
                    store:store_id(name)
                `)
                .gte('created_at', startISO)
                .lte('created_at', endISO)
                .neq('status', 'cancelled');

            if (errOrders) throw errOrders;
            this.orders = currentOrders || [];

            // 2. Buscar Recebíveis do Mês (Financeiro)
            const { data: financeData, error: errFin } = await supabase
                .from('finance_receivables')
                .select('id, value, paid_value, status, due_date')
                .gte('due_date', startISO)
                .lte('due_date', endISO);

            if (errFin) throw errFin;
            this.receivables = financeData || [];

            // 3. Buscar Clientes
            const { data: clientsData, error: errClients } = await supabase
                .from('customers_mj')
                .select('id, nome, razao_social, celular, telefone, email, created_at');

            if (errClients) throw errClients;
            this.customers = clientsData || [];

            // 4. Buscar Histórico COMPLETO de Pedidos (Para análise de Inativos/Novos)
            const { data: historyData, error: errHist } = await supabase
                .from('orders')
                .select(`
                    id, customer_id, created_at, total_value,
                    created_by:created_by(id, full_name)
                `)
                .neq('status', 'cancelled')
                .limit(10000);

            if (errHist) throw errHist;
            this.allOrdersHistory = historyData || [];

        } catch (error) {
            console.error('Erro ao carregar SalesArea:', error);
        } finally {
            this.loading = false;
        }
    }
  }
});
