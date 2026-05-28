// src/stores/crm.ts
import { defineStore } from 'pinia';
import { supabase } from '@/api/supabase';
import { formatISO, subDays, eachDayOfInterval, format, parseISO, differenceInDays } from 'date-fns';

// REGRA DE NEGÓCIO: Vendedoras da região Nordeste, conforme solicitado.
const NORDESTE_SELLERS = ['Elda', 'Sueli'];

// ===================================================================
// INÍCIO DA REATORAÇÃO NÍVEL BI
// ===================================================================

async function _fetchOrdersForPeriod(startDate: string, endDate: string) {
  const { data: orders, error } = await supabase
    .from('orders')
    .select(`
      id, customer_name, created_at, created_by, total_value,
      order_items(fabric_type, quantity_meters, total_value_items),
      profiles:created_by(full_name, avatar_url, id)
    `)
    .gte('created_at', startDate)
    .lte('created_at', endDate);

  if (error) throw error;
  return orders;
}

/**
 * Processa um array de pedidos brutos e retorna dados de BI.
 * AGORA RETORNA MAPAS COMPLETOS E SETS DE CLIENTES.
 */
function _processOrders(
  orders: any[],
  startDate: string,
  endDate: string
) {
  let total_revenue = 0;
  let total_meters_processed = 0;

  const salesByDay = new Map<string, number>();
  const salesByFabric = new Map<string, { meters: number, value: number }>();
  const salesBySeller = new Map<string, { meters: number, value: number, avatar_url: string, orders: number }>();
  const salesByCustomer = new Map<string, { meters: number, value: number, orders: number }>();
  const customerSet = new Set<string>();
  const salesByRegionCalc = { Sudoeste: 0, Nordeste: 0 };
  const customerFirstOrder = new Map<string, Date>();

  const dateInterval = eachDayOfInterval({ start: parseISO(startDate), end: parseISO(endDate) });
  dateInterval.forEach(day => salesByDay.set(format(day, 'yyyy-MM-dd'), 0));

  for (const order of orders) {
    const orderValue = order.total_value || 0;
    const customerName = order.customer_name || 'Sem Cliente';
    customerSet.add(customerName);

    let orderMeters = 0;
    if (order.order_items) {
      for (const item of order.order_items) {
        const itemMeters = item.quantity_meters || 0;
        const itemValue = item.total_value_items || 0; // <-- Usando o valor correto
        const fabricName = item.fabric_type || 'Sem Base';

        orderMeters += itemMeters;

        const fab = salesByFabric.get(fabricName) || { meters: 0, value: 0 };
        fab.meters += itemMeters;
        fab.value += itemValue;
        salesByFabric.set(fabricName, fab);
      }
    }

    total_revenue += orderValue;
    total_meters_processed += orderMeters;

    const orderDay = format(parseISO(order.created_at), 'yyyy-MM-dd');
    if (salesByDay.has(orderDay)) salesByDay.set(orderDay, salesByDay.get(orderDay)! + orderValue);

    let sellerName = order.profiles?.full_name || 'N/A';
    let sellerAvatarFromOrder = order.profiles?.avatar_url || '';

    if (sellerName === 'Danilo Martins') {
      sellerName = 'Fernanda Garcia';
      sellerAvatarFromOrder = 'https://cdn.shopify.com/s/files/1/0661/4574/6991/files/Fernanda_Garcia_Logo.png?v=1750964425';
    }

    const existingSellerData = salesBySeller.get(sellerName) || { meters: 0, value: 0, avatar_url: '', orders: 0 };
    existingSellerData.meters += orderMeters;
    existingSellerData.value += orderValue;
    existingSellerData.orders += 1;
    if (!existingSellerData.avatar_url && sellerAvatarFromOrder) {
      existingSellerData.avatar_url = sellerAvatarFromOrder;
    }
    salesBySeller.set(sellerName, existingSellerData);

    const existingCustomerData = salesByCustomer.get(customerName) || { meters: 0, value: 0, orders: 0 };
    existingCustomerData.meters += orderMeters;
    existingCustomerData.value += orderValue;
    existingCustomerData.orders += 1;
    salesByCustomer.set(customerName, existingCustomerData);

    const region = NORDESTE_SELLERS.includes(sellerName) ? 'Nordeste' : 'Sudoeste';
    salesByRegionCalc[region] += orderMeters;

    const orderDate = parseISO(order.created_at);
    if (!customerFirstOrder.has(customerName) || orderDate < customerFirstOrder.get(customerName)!) {
      customerFirstOrder.set(customerName, orderDate);
    }
  }

  const new_customers = Array.from(customerFirstOrder.values()).filter(date =>
    date >= parseISO(startDate) && date <= parseISO(endDate)
  ).length;

  const kpis = {
    total_revenue: total_revenue,
    total_orders: orders.length,
    new_customers: new_customers,
    avg_ticket: orders.length > 0 ? total_revenue / orders.length : 0,
    total_meters: total_meters_processed,
    avg_meters_per_order: orders.length > 0 ? total_meters_processed / orders.length : 0,
  };

  const sales_trend_data = Array.from(salesByDay.entries()).map(([day, total_revenue]) => ({ day, total_revenue })).sort((a, b) => new Date(a.day).getTime() - new Date(b.day).getTime());

  return {
    kpis,
    sales_trend_data, // <-- Renomeado para clareza
    fabricMap: salesByFabric,
    sellerMap: salesBySeller,
    customerMap: salesByCustomer,
    customerSet: customerSet,
    salesByRegion: salesByRegionCalc,
    rawOrders: orders,
  };
}
// ===================================================================
// FIM DA REFATORAÇÃO
// ===================================================================

export const useCrmStore = defineStore('crm', {
  state: () => ({
    filters: {
      startDate: formatISO(subDays(new Date(), 30), { representation: 'date' }),
      endDate: formatISO(new Date(), { representation: 'date' }),
    },
    rawOrders: [] as any[],
    overview: {
      kpis: null as Record<string, any> | null,
      sales_trend: [] as { day: string, total_revenue: number }[],
      top_fabrics: [] as { fabric: string, total_meters: number }[], // Mantido para o dashboard antigo
      top_sellers_by_meters: [] as any[], // Mantido para o dashboard antigo
      top_customers_by_meters: [] as any[], // Mantido para o dashboard antigo
    },
    salesByRegion: {
      Sudoeste: 0,
      Nordeste: 0,
    },
    loading: true,
  }),

  actions: {
    /**
     * Ação principal: Alimenta o dashboard.
     */
    async fetchCrmData() {
      this.loading = true;
      try {
        const orders = await _fetchOrdersForPeriod(this.filters.startDate, this.filters.endDate);
        this.rawOrders = orders;

        const processedData = _processOrders(orders, this.filters.startDate, this.filters.endDate);

        // Converte os mapas em Top 5 para o dashboard antigo
        const top_fabrics = Array.from(processedData.fabricMap.entries())
          .map(([fabric, data]) => ({ fabric, total_meters: data.meters }))
          .sort((a, b) => b.total_meters - a.total_meters).slice(0, 5);

        const top_sellers_by_meters = Array.from(processedData.sellerMap.entries())
          .map(([name, data]) => ({ name, value: data.meters, avatar_url: data.avatar_url }))
          .sort((a, b) => b.value - a.value);

        const top_customers_by_meters = Array.from(processedData.customerMap.entries())
          .map(([name, data]) => ({ name, value: data.meters, avatar_url: null }))
          .sort((a, b) => b.value - a.value);

        this.overview = {
          kpis: processedData.kpis,
          sales_trend: processedData.sales_trend_data,
          top_fabrics: top_fabrics,
          top_sellers_by_meters: top_sellers_by_meters,
          top_customers_by_meters: top_customers_by_meters,
        };
        this.salesByRegion = processedData.salesByRegion;

      } catch (error) {
        console.error('CRM_DEBUG: ERRO CRÍTICO NO fetchCrmData:', error);
        this.overview.kpis = null;
      } finally {
        this.loading = false;
      }
    },

    /**
     * NOVA AÇÃO: Busca e processa dados para dois períodos
     * e retorna o resultado COMPLETO.
     */
    async fetchComparativeReport(
      periodA: { startDate: string, endDate: string },
      periodB: { startDate: string, endDate: string }
    ) {
      try {
        const [ordersA, ordersB] = await Promise.all([
          _fetchOrdersForPeriod(periodA.startDate, periodA.endDate),
          _fetchOrdersForPeriod(periodB.startDate, periodB.endDate)
        ]);

        const dataA = _processOrders(ordersA, periodA.startDate, periodA.endDate);
        const dataB = _processOrders(ordersB, periodB.startDate, periodB.endDate);

        return { dataA, dataB };

      } catch (error) {
        console.error('Erro ao buscar relatório comparativo:', error);
        throw error;
      }
    }
  },
});
