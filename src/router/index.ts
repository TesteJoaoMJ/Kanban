import { createRouter, createWebHistory, type RouteRecordRaw } from 'vue-router';
import { useUserStore } from '@/stores/user';
import { useCompanyStore } from '@/stores/company';
import { useProtectionStore } from '@/stores/protectionStore';
import { supabase } from '@/api/supabase';

const routes: Array<RouteRecordRaw> = [
  // ================= ROTAS PÚBLICAS =================
  {
    path: '/',
    name: 'Login',
    component: () => import('@/views/Login.vue'),
    meta: { requiresAuth: false }
  },
  {
    path: '/acesso-negado',
    name: 'Unauthorized',
    component: () => import('@/views/Unauthorized.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/rh/totem-ponto',
    name: 'TimeKiosk',
    component: () => import('@/views/rh/TimeKiosk.vue'),
    meta: { requiresAuth: true, permission: 'rh_ponto' }
  },
  {
    path: '/apresentacao',
    name: 'Landing',
    component: () => import('@/views/Landing.vue'),
    meta: { requiresAuth: false }
  },
  {
    path: '/marketplace-login',
    name: 'MarketplaceLogin',
    component: () => import('@/views/public/MarketplaceLogin.vue'),
    meta: { requiresAuth: false }
  },
  {
    path: '/marketplace',
    name: 'MarketplacePortal',
    component: () => import('@/views/public/MarketplacePortal.vue'),
    meta: { requiresAuth: false },
    children: [
      // --- ROTAS ABERTAS (PÚBLICAS) ---
      {
        path: '',
        name: 'MarketplaceHome',
        component: () => import('@/views/public/MarketplaceHome.vue'),
        meta: { protectionContext: 'unknown' }
      },
      {
        path: 'estamparia-digital',
        name: 'MarketplaceEstamparia',
        component: () => import('@/views/public/MarketplaceEstamparia.vue'),
        meta: { protectionContext: 'unknown' }
      },
      {
        path: 'corte-a-laser',
        name: 'MarketplaceLaser',
        component: () => import('@/views/public/MarketplaceLaser.vue'),
        meta: { protectionContext: 'unknown' }
      },
      {
        path: 'canga-promocional',
        name: 'MarketplaceCanga',
        component: () => import('@/views/public/MarketplaceCanga.vue'),
        meta: { protectionContext: 'unknown' }
      },

      // --- ROTAS DE CLIENTE COMUM (SÓ EXIGE LOGIN) ---
      {
        path: 'perfil',
        name: 'MarketplaceProfile',
        component: () => import('@/views/public/MarketplaceProfile.vue'),
        meta: { requiresMarketplaceAuth: true, protectionContext: 'unknown' }
      },
      {
        path: 'checkout',
        name: 'MarketplaceCheckout',
        component: () => import('@/views/public/MarketplaceCheckout.vue'),
        meta: { requiresMarketplaceAuth: true, protectionContext: 'checkout' }
      },
      {
        path: 'ficha-tecnica',
        name: 'MarketplaceFichaTecnica',
        component: () => import('@/views/public/MarketplaceFichaTecnica.vue'),
        meta: { requiresMarketplaceAuth: true, protectionContext: 'catalog' }
      },

      // --- ROTAS RESTRITAS (PREMIUM / VIP) ---
      {
        path: 'catalogo',
        name: 'MarketplaceCatalog',
        component: () => import('@/views/public/MarketplaceCatalog.vue'),
        meta: { premiumRestricted: true, protectionContext: 'catalog' }
      },
      {
        path: 'descobrir',
        name: 'MarketplaceDiscover',
        component: () => import('@/views/public/MarketplaceDiscover.vue'),
        meta: { premiumRestricted: true, protectionContext: 'discover' }
      },
      {
        path: 'favoritos',
        name: 'MarketplaceFavorites',
        component: () => import('@/views/public/MarketplaceFavorites.vue'),
        meta: { premiumRestricted: true, protectionContext: 'catalog' }
      },
      {
        path: 'produto/:id',
        name: 'MarketplaceProduct',
        component: () => import('@/views/public/MarketplaceProduct.vue'),
        meta: { premiumRestricted: true, protectionContext: 'art_detail' }
      }
    ]
  },
  {
    path: '/login',
    redirect: '/'
  },
  {
    path: '/acesso-revogado',
    name: 'Dismissed',
    component: () => import('@/views/Dismissed.vue'),
    meta: { requiresAuth: false }
  },
  {
    path: '/privacy',
    name: 'Privacy',
    component: () => import('@/views/public/Privacy.vue'),
    meta: { title: 'Política de Privacidade' }
  },
  {
    path: '/terms',
    name: 'Terms',
    component: () => import('@/views/public/Terms.vue'),
    meta: { title: 'Termos de Serviço' }
  },

  // ================= ROTAS PROTEGIDAS (ISOLADAS DO LAYOUT) =================
  {
    path: '/hub',
    name: 'Hub',
    component: () => import('@/views/Hub.vue'),
    meta: { requiresAuth: true },
  },
  {
    path: '/rh/totem-ponto',
    name: 'TimeKiosk',
    component: () => import('@/views/rh/TimeKiosk.vue'),
    meta: { requiresAuth: true, permission: 'rh_ponto' }
  },

  // ================= ROTAS PROTEGIDAS (DENTRO DO SISTEMA) =================
  {
    path: '/',
    component: () => import('@/layouts/default.vue'),
    children: [
      {
        path: 'perfil',
        name: 'UserProfile',
        component: () => import('@/views/admin/UserProfileView.vue'),
        meta: { requiresAuth: true, title: 'Meu Perfil' }
      },
      {
        path: 'dashboard',
        name: 'Home',
        component: () => import('@/components/dashboards/DashboardManager.vue'),
        meta: { requiresAuth: true, permission: 'view_dashboard' }
      },
      {
        path: 'pedidos',
        name: 'Orders',
        component: () => import('@/views/Orders.vue'),
        meta: { requiresAuth: true, requiresModule: 'mj', permission: 'sales_my_orders' }
      },
      {
        path: '/development/new',
        name: 'NewDevelopmentRequest',
        component: () => import('@/views/design/NewDevelopmentRequest.vue'),
        meta: { requiresAuth: true, requiresModule: 'mj', permission: 'des_request' },
      },
      {
        path: 'aprovar-pedidos',
        name: 'Approvals',
        component: () => import('@/views/Approvals.vue'),
        meta: { requiresModule: 'mj', permission: 'mfg_approvals' }
      },
      {
        path: 'admin/gestao-pedidos',
        name: 'OrderManagement',
        component: () => import('@/views/admin/OrderManagement.vue'),
        meta: { requiresAuth: true, requiresModule: 'mj', permission: 'sales_management' }
      },
      {
        path: 'admin/store-sales',
        name: 'StoreSalesManagement',
        component: () => import('@/views/admin/StoreSalesManagement.vue'),
        meta: { requiresAuth: true, permission: 'sales_store' }
      },
      {
        path: 'pdv',
        name: 'PDV',
        component: () => import('@/views/sales/PDV.vue'),
        meta: { requiresAuth: true, requiresModule: 'mj', permission: 'sales_store' }
      },
      {
        path: 'em-producao',
        name: 'InProduction',
        component: () => import('@/views/production/InProduction.vue'),
        meta: { requiresModule: 'mj', permission: 'mfg_in_production' }
      },
      {
        path: 'production/control',
        name: 'ProductionControl',
        component: () => import('@/views/production/ProductionControl.vue'),
        meta: { requiresAuth: true, requiresModule: 'mj', permission: 'mfg_control' }
      },
      {
        path: 'production/kanban_colecao',
        name: 'KanbanColecao',
        component: () => import('@/views/production/kanban/ColecaoView.vue'),
        meta: { requiresAuth: true, requiresModule: 'mj', permission: 'mfg_colecao' }
      },
      {
        path: 'production/kanban_producao',
        name: 'KanbanProducao',
        component: () => import('@/views/production/kanban/ProducaoView.vue'),
        meta: { requiresAuth: true, requiresModule: 'mj', permission: 'mfg_producao' }
      },
      {
        path: 'production/dynamic-control',
        name: 'DynamicProductionControl',
        component: () => import('@/views/production/DynamicProductionControl.vue'),
        meta: { requiresAuth: true, requiresModule: 'mj', permission: 'mfg_control' }
      },
      {
        path: 'production/printing',
        name: 'PrintingStation',
        component: () => import('@/views/production/PrintingStation.vue'),
        meta: { requiresAuth: true, requiresModule: 'mj', permission: 'mfg_printing' }
      },
      {
        path: 'liberacao',
        name: 'Liberacao',
        component: () => import('@/views/production/Liberacao.vue'),
        meta: { requiresModule: 'mj', permission: 'mfg_release' }
      },
      {
        path: 'launches',
        name: 'Launches',
        component: () => import('@/views/Launches.vue'),
        meta: { requiresAuth: true, requiresModule: 'mj', permission: 'mfg_launches' }
      },
      {
        path: 'tabela-precos',
        name: 'PriceList',
        component: () => import('@/views/sales/PriceList.vue'),
        meta: { requiresModule: 'mj', permission: 'sales_price_list' }
      },
      {
        path: 'estoque',
        name: 'Stock',
        component: () => import('@/views/Stock.vue'),
        meta: { requiresAuth: true, requiresModule: 'mj', permission: 'prod_stock' }
      },
      {
        path: 'estoque/gestao',
        name: 'StockManagement',
        component: () => import('@/views/admin/StockManagement.vue'),
        meta: { requiresAuth: true, requiresModule: 'mj', permission: 'prod_stock_mgmt' }
      },
      {
        path: 'didatico',
        name: 'Didatico',
        component: () => import('@/views/Didatico.vue'),
        meta: { requiresModule: 'mj', permission: 'sales_didatic' }
      },
      {
        path: 'email',
        name: 'EmailManager',
        component: () => import('@/views/admin/EmailManager.vue'),
        meta: { requiresAuth: true, title: 'Gerenciador de E-mails' }
      },
      {
        path: 'entrega',
        name: 'Delivery',
        component: () => import('@/views/Delivery.vue'),
        meta: { requiresAuth: true, requiresModule: 'mj', permission: 'log_delivery' }
      },
      {
        path: 'novo-pedido-com-nota',
        name: 'NewOrderComNota',
        component: () => import('@/views/sales/NewOrder.vue'),
        meta: { requiresAuth: true, requiresModule: 'mj', orderContext: 'com_nota' }
      },
      {
        path: 'novo-pedido-sem-nota',
        name: 'NewOrderSemNota',
        component: () => import('@/views/sales/NewOrder.vue'),
        meta: { requiresAuth: true, requiresModule: 'mj', orderContext: 'sem_nota' }
      },
      {
        path: 'vendas/gestao',
        name: 'SalesOrderManagement',
        component: () => import('@/views/sales/SalesOrderManagement.vue'),
        meta: { requiresAuth: true, requiresModule: 'mj', permission: 'sales_my_orders' }
      },
      {
        path: 'vendas/pagamentos',
        name: 'SalesPayments',
        component: () => import('@/views/financial/CoraStatementView.vue'),
        meta: { requiresAuth: true, title: 'Consultar Pagamento', permission: 'fin_statement' }
      },
      {
        path: 'design',
        name: 'DesignKanban',
        component: () => import('@/views/design/DesignKanban.vue'),
        meta: { requiresModule: 'mj', permission: 'des_kanban' }
      },
      {
        path: 'design/organograma',
        name: 'DesignerOrgChart',
        component: () => import('@/views/design/DesignerOrgChart.vue'),
        meta: { requiresAuth: true, requiresModule: 'mj', permission: 'des_kanban' }
      },
      {
        path: 'catalogo-estampas',
        name: 'StampCatalog',
        component: () => import('@/views/design/StampCatalog.vue'),
        meta: { requiresModule: 'mj', permission: 'des_catalog' }
      },
      {
        path: 'producao',
        name: 'ProductionKanban',
        component: () => import('@/views/production/ProductionKanban.vue'),
        meta: { requiresModule: 'mj', permission: 'mfg_in_production' }
      },
      {
        path: 'pedidos/:id/aprovar',
        name: 'ApproveOrder',
        component: () => import('@/views/orders/ApproveOrder.vue'),
        meta: { requiresModule: 'mj', permission: 'mfg_approvals' }
      },
      {
        path: 'cadastros/clientes',
        name: 'ClientManagement',
        component: () => import('@/views/registrations/Clients.vue'),
        meta: { requiresAuth: true, requiresModule: 'mj', permission: 'cad_clients' }
      },
      {
        path: 'cadastros/maquinas',
        name: 'MachinesManagement',
        component: () => import('@/views/registrations/machines.vue'),
        meta: { requiresAuth: true, requiresModule: 'mj', permission: 'cad_machines' }
      },
      {
        path: 'cadastros/fornecedores',
        name: 'SupplierManagement',
        component: () => import('@/views/registrations/Suppliers.vue'),
        meta: { requiresAuth: true, requiresModule: 'mj', permission: 'cad_suppliers' }
      },
      {
        path: 'cadastros/funcionarios',
        name: 'EmployeeManagement',
        component: () => import('@/views/registrations/Employees.vue'),
        meta: { requiresAuth: true, requiresModule: 'mj', permission: 'cad_employees' }
      },
      {
        path: 'admin/financeiro/recebiveis',
        name: 'FinancialReceivables',
        component: () => import('@/components/admin/AdminMjReceivables.vue'),
        meta: { requiresAuth: true, requiresModule: 'mj', permission: 'fin_receivables' }
      },
      {
        path: 'admin/financeiro/pagar',
        name: 'FinancialPayables',
        component: () => import('@/components/admin/AdminMjAccountsPayable.vue'),
        meta: { requiresAuth: true, requiresModule: 'mj', permission: 'fin_payables' }
      },
      {
        path: 'admin/financeiro/contas',
        name: 'FinancialAccounts',
        component: () => import('@/components/admin/AdminMjBankAccounts.vue'),
        meta: { requiresAuth: true, requiresModule: 'mj', permission: 'fin_accounts' }
      },
      {
        path: 'admin/financeiro/dfe',
        name: 'DfeManagement',
        component: () => import('@/components/admin/AdminMjPayables.vue'),
        meta: { requiresAuth: true, requiresModule: 'mj', permission: 'fin_payables' }
      },
      {
        path: 'admin/fiscal/emissor-nfe',
        name: 'AdminNfeIssuer',
        component: () => import('@/views/admin/fiscal/AdminNfeIssuer.vue'),
        meta: { requiresAuth: true, requiresModule: 'mj', permission: 'fisc_nfe_sell' }
      },
      {
        path: 'admin/fiscal/emissor-nfce',
        name: 'AdminNfceIssuer',
        component: () => import('@/views/admin/fiscal/AdminNfceIssuer.vue'),
        meta: { requiresAuth: true, requiresModule: 'mj', permission: 'fisc_nfce_sell' }
      },
      {
        path: 'admin/fiscal/empresas',
        name: 'FiscalCompanies',
        component: () => import('@/views/admin/fiscal/FiscalCompanies.vue'),
        meta: { requiresAuth: true, requiresModule: 'mj', permission: 'fisc_companies' }
      },
      {
        path: 'admin/fiscal/lojas',
        name: 'FiscalStores',
        component: () => import('@/views/admin/fiscal/FiscalStores.vue'),
        meta: { requiresAuth: true, requiresModule: 'mj', permission: 'fisc_stores' }
      },
      {
        path: 'financeiro/plano-contas',
        name: 'ChartOfAccounts',
        component: () => import('@/views/financial/ChartOfAccounts.vue'),
        meta: { requiresAuth: true, requiresModule: 'mj', permission: 'fisc_chart' }
      },
      {
        path: 'admin/fiscal/monitor',
        name: 'FiscalMonitor',
        component: () => import('@/views/admin/fiscal/FiscalMonitor.vue'),
        meta: { requiresAuth: true, requiresModule: 'mj', permission: 'fisc_nfe_buy' }
      },
      {
        path: 'chat',
        name: 'Chat',
        component: () => import('@/views/Chat.vue'),
        meta: { requiresModule: 'mj' }
      },
      {
        path: 'tasks',
        name: 'Tasks',
        component: () => import('@/views/Tasks.vue'),
        meta: { requiresModule: 'mj', permission: 'view_tasks' }
      },
      {
        path: 'projects',
        name: 'Projects',
        component: () => import('@/views/Projects.vue'),
        meta: { requiresModule: 'mj', permission: 'view_tasks' }
      },
      {
        path: 'admin',
        name: 'Admin',
        component: () => import('@/views/Admin.vue'),
        meta: { requiresAuth: true, requiresModule: 'mj', permission: 'admin_general' }
      },
      {
        path: 'admin/storefront',
        name: 'StorefrontManager',
        component: () => import('@/views/admin/StorefrontManager.vue'),
        meta: { requiresAuth: true, permission: 'admin_integrations' }
      },
      {
        path: 'admin/crm',
        name: 'CRM',
        component: () => import('@/views/admin/CRM.vue'),
        meta: { requiresAuth: true, requiresModule: 'mj' }
      },
      {
        path: 'admin/sales-tenant-control',
        name: 'SalesTenantControl',
        component: () => import('@/views/admin/SalesTenantControl.vue'),
        meta: { requiresAuth: true, permission: 'admin_sales_tenant' } // Ou use 'admin_general' se não tiver criado essa permissão
      },
      {
        path: 'frota/veiculos',
        name: 'FleetVehicles',
        component: () => import('@/views/fleet/VehicleManagement.vue'),
        meta: { requiresAuth: true, requiresModule: 'mj', permission: 'fleet_vehicles' }
      },
      {
        path: 'frota/abastecimento',
        name: 'FleetRefueling',
        component: () => import('@/views/fleet/RefuelingManagement.vue'),
        meta: { requiresAuth: true, requiresModule: 'mj', permission: 'fleet_refueling' }
      },
      {
        path: '/admin/reports/:reportType',
        name: 'AdminReports',
        component: () => import('@/views/admin/AdminReports.vue'),
        props: true,
        meta: { requiresAuth: true, permission: 'view_reports' } // <-- ADICIONAR ESTA LINHA
      },
      {
        path: '/admin/sales-area',
        name: 'SalesArea',
        component: () => import('@/views/admin/SalesArea.vue'),
        meta: { requiresAuth: true, permission: 'admin_sales_area' }
      },
      {
        path: '/admin/reports/financial-payables',
        name: 'FinancialPayablesReport',
        component: () => import('@/views/financial/FinancialPayablesReport.vue'),
        meta: { requiresAuth: true, permission: 'rep_fin_payables' }
      },
      {
        path: '/admin/reports/financial-receivables',
        name: 'FinancialReceivablesReport',
        component: () => import('@/views/financial/FinancialReceivablesReport.vue'),
        meta: { requiresAuth: true, permission: 'rep_fin_receivables' }
      },
      {
        path: '/admin/reports/financial-dre',
        name: 'FinancialDreReport',
        component: () => import('@/views/financial/FinancialDreReport.vue'),
        meta: { requiresAuth: true, permission: 'rep_fin_dre' }
      },
      {
        path: '/admin/reports/sales-report',
        name: 'SalesReport',
        component: () => import('@/views/financial/SalesReport.vue'),
        meta: { requiresAuth: true, permission: 'rep_sales' }
      },
      {
        path: '/admin/reports/sales-audit',
        name: 'SalesAuditReport',
        component: () => import('@/views/admin/SalesAuditReport.vue'),
        meta: { requiresAuth: true, permission: 'rep_sales' }
      },
      {
        path: '/admin/reports/stock-movements',
        name: 'StockMovementsReport',
        component: () => import('@/views/admin/StockMovementsReport.vue'),
        meta: { requiresAuth: true }
      },
      {
        path: 'fiscal/payment-methods',
        name: 'AdminPaymentMethods',
        component: () => import('@/views/admin/fiscal/AdminPaymentMethods.vue'),
        meta: { requiresAuth: true, permission: 'fisc_pay_methods' }
      },
      {
        path: '/admin/produtos/compras',
        name: 'ProductPurchases',
        component: () => import('@/views/purchases/ProductPurchases.vue'),
        meta: { requiresAuth: true, permission: 'pur_products' }
      },
      {
        path: '/admin/produtos/servicos',
        name: 'ServicePurchases',
        component: () => import('@/views/purchases/ServicePurchases.vue'),
        meta: { requiresAuth: true, permission: 'pur_services' }
      },
      {
        path: '/quotations',
        name: 'Quotations',
        component: () => import('@/views/purchases/QuotationManagement.vue'),
        meta: { requiresAuth: true, permission: 'pur_quotations' }
      },
      {
        path: 'consulta-global',
        name: 'GlobalOrders',
        component: () => import('@/views/sales/GlobalOrdersView.vue'),
        meta: { requiresAuth: true, title: 'Consulta Global' }
      },
      {
        path: 'fiscal/cte',
        name: 'AdminCteIssuer',
        component: () => import('@/views/admin/fiscal/AdminCteIssuer.vue'),
        meta: {
          requiresAuth: true,
          title: 'Emissão de CT-e'
        }
      },
      {
        path: '/cockpit',
        name: 'SystemCockpit',
        component: () => import('@/views/admin/SystemCockpit.vue'),
        meta: {
          requiresAuth: true,
        }
      },
      {
        path: '/admin/backup',
        name: 'AdminBackup',
        component: () => import('@/views/admin/AdminBackup.vue'),
        meta: { requiresAuth: true, roles: ['admin', 'super_admin'] }
      },
      {
        path: 'fiscal/tax-rules',
        name: 'FiscalTaxRules',
        component: () => import('@/views/admin/fiscal/FiscalTaxRules.vue'),
        meta: { requiresAuth: true }
      },

      // --- ROTAS DO RH (PONTO ELETRÔNICO) ---
      {
        path: 'rh/ponto',
        name: 'AdminTimeTracking',
        component: () => import('@/views/rh/AdminTimeTracking.vue'),
        meta: { requiresAuth: true, requiresModule: 'mj', permission: 'rh_ponto' }
      },

      // --- ROTAS CAJUIA ---
      {
        path: 'cajuia/dashboard',
        name: 'CajuiaDashboard',
        component: () => import('@/views/cajuia/Dashboard.vue'),
        meta: { requiresAuth: true, requiresModule: 'cajuia', permission: 'cajuia_dashboard' }
      },
      {
        path: 'cajuia/vendedor',
        name: 'CajuiaSellerDashboard',
        component: () => import('@/views/cajuia/SellerDashboard.vue'),
        meta: { requiresAuth: true, requiresModule: 'cajuia', permission: 'cajuia_dashboard' }
      },
      {
        path: 'cajuia/admin',
        name: 'CajuiaAdmin',
        component: () => import('@/views/cajuia/Admin.vue'),
        meta: { requiresAuth: true, requiresModule: 'cajuia', permission: 'cajuia_admin' }
      },
      {
        path: 'cajuia/pedidos',
        name: 'CajuiaOrders',
        component: () => import('@/views/cajuia/Orders.vue'),
        meta: { requiresAuth: true, requiresModule: 'cajuia', permission: 'cajuia_orders' }
      },
      {
        path: 'cajuia/financeiro',
        name: 'CajuiaFinancial',
        component: () => import('@/views/cajuia/Financial.vue'),
        meta: { requiresAuth: true, requiresModule: 'cajuia', permission: 'cajuia_financial' }
      },
      {
        path: 'cajuia/clientes',
        name: 'CajuiaClients',
        component: () => import('@/views/cajuia/Clients.vue'),
        meta: { requiresAuth: true, requiresModule: 'cajuia', permission: 'cajuia_clients' }
      },
      {
        path: 'cajuia/nfe-emissor',
        name: 'SellerNfeIssuer',
        component: () => import('@/views/cajuia/SellerNfeIssuer.vue'),
        meta: { requiresAuth: true, requiresModule: 'cajuia', permission: 'cajuia_nfe' }
      },
      {
        path: 'cortadora/dashboard',
        name: 'CajuiaCortadoraDashboard',
        component: () => import('@/views/cajuia/CortadoraDashboard.vue'),
        meta: { requiresAuth: true, requiresModule: 'mj', permission: 'operacional_corte' }
      },
      {
        path: 'cortadora/lancamentos',
        name: 'CajuiaCortadoraManagement',
        component: () => import('@/views/cajuia/CortadoraManagement.vue'),
        meta: { requiresAuth: true, requiresModule: 'mj', permission: 'operacional_corte' }
      },
    ],
  }
];

const router = createRouter({
  history: createWebHistory(process.env.BASE_URL),
  routes,
});

// A BLINDAGEM MÁXIMA PARA A TELA BRANCA DE F5 🛡️
router.beforeEach(async (to, from, next) => {
  try {
      const userStore = useUserStore();
      const companyStore = useCompanyStore();
      const protectionStore = useProtectionStore();

      const toName = to.name ? String(to.name) : '';

      const publicRoutes = [
        'Dismissed', 'Login', 'Landing', 'MarketplaceLogin',
        'MarketplacePortal', 'MarketplaceHome', 'MarketplaceDiscover',
        'MarketplaceProduct', 'MarketplaceProfile', 'MarketplaceCheckout',
        'MarketplaceFichaTecnica', 'MarketplaceEstamparia', 'MarketplaceLaser',
        'MarketplaceCanga', 'MarketplaceCatalog', 'MarketplaceFavorites'
      ];

      // Tenta buscar a sessão. Se der erro, engole a exceção e não trava o router.
      if (!userStore.isLoggedIn) {
          try {
              await userStore.fetchSession();
          } catch (e) {
              console.warn('[Router] Falha leve ao buscar sessão no F5', e);
          }
      }

      const isMarketplaceRoute = to.matched.some(record => record.name === 'MarketplacePortal');

      if (isMarketplaceRoute) {
          if (!protectionStore.isInitialized) {
             try {
                await protectionStore.initializeGuard();
             } catch(e) {}
          }

          if (protectionStore.isBlocked && toName !== 'MarketplaceHome' && toName !== 'MarketplaceLogin') {
              console.warn('Segurança: Navegação bloqueada. Destruindo sessão VIP...');
              localStorage.removeItem('mj_active_code');
              return next({ name: 'MarketplaceLogin', query: { blocked: 'true' } });
          }

          const newContext = to.meta.protectionContext as any;
          if (newContext) {
              protectionStore.setContext(newContext);
          } else {
              protectionStore.setContext('unknown');
          }

          if (toName === 'MarketplaceProduct' && from.name === 'MarketplaceProduct') {
              protectionStore.applyPenalty(10, 'rapid_route_cycling');
          }
      }

      if (userStore.isLoggedIn && !userStore.profile && !publicRoutes.includes(toName)) {
         try {
            await Promise.all([
              userStore.fetchProfile(),
              userStore.fetchCajuiaRole()
            ]);
         } catch (error) {
            console.error('[Router] Erro ao carregar perfil do ERP:', error);
            await userStore.signOut();
            return next({ name: 'Login' });
         }
      }

      if (userStore.isLoggedIn && !companyStore.activeCompany) {
          try { companyStore.initialize(); } catch(e) {}
      }

      if (userStore.isLoggedIn && userStore.user && !publicRoutes.includes(toName)) {
          if (userStore.employeeStatus === undefined) {
              try {
                  const { data: emp, error } = await supabase
                      .from('employees_mj')
                      .select('status')
                      .eq('user_id', userStore.user.id)
                      .maybeSingle();

                  if (error) throw error;
                  userStore.employeeStatus = emp ? emp.status : 'ativo';
              } catch (err) {
                  userStore.employeeStatus = 'ativo';
              }
          }

          if (userStore.employeeStatus === 'inativo' || userStore.employeeStatus === 'afastado') {
              return next({ name: 'Dismissed' });
          }
      }

      const requiresAuth = to.matched.some(record => record.meta.requiresAuth);
      if (requiresAuth && !userStore.isLoggedIn) {
        return next({ name: 'Login' });
      }

      // Validação de rotas que exigem apenas ter conta logada no portal (Perfil, Checkout, etc)
      const requiresMarketplaceAuth = to.matched.some(record => record.meta.requiresMarketplaceAuth);
      if (requiresMarketplaceAuth) {
          if (!userStore.isLoggedIn || !userStore.user) {
              return next({ name: 'MarketplaceLogin' });
          }
      }

      // Validação VIP: O roteador SÓ exige login. A checagem do código é feita pelo componente MarketplacePortal.vue
      const isPremiumRestricted = to.matched.some(record => record.meta.premiumRestricted);
      if (isPremiumRestricted) {
          if (!userStore.isLoggedIn || !userStore.user) {
              return next({ name: 'MarketplaceLogin' });
          }
          // Deixa a rota passar. O Portal vai exibir o cadeado (showVipLock) se o usuário não tiver chave validada.
      }

      if (toName === 'Login' && userStore.isLoggedIn) {
        const customRoleId = userStore.profile?.custom_role_id;
        if (customRoleId) {
            if (userStore.hasPermission('operacional_corte') && !userStore.hasPermission('admin_general')) {
                if (userStore.currentModule !== 'mj') userStore.setModule('mj');
                return next({ name: 'CajuiaCortadoraDashboard' });
            }
            if (userStore.hasPermission('view_dashboard')) {
                if (userStore.currentModule !== 'mj') userStore.setModule('mj');
                return next({ name: 'Home' });
            }
            if (userStore.hasPermission('cajuia_dashboard')) {
                if (userStore.currentModule !== 'cajuia') userStore.setModule('cajuia');
                return next({ name: 'CajuiaDashboard' });
            }
            return next({ name: 'Hub' });
        }
        const role = userStore.profile?.role;
        if (role === 'impressor') {
            if (userStore.currentModule !== 'mj') userStore.setModule('mj');
            return next({ name: 'PrintingStation' });
        }
        if (role === 'faturador') {
            if (userStore.currentModule !== 'mj') userStore.setModule('mj');
            return next({ name: 'OrderManagement' });
        }
        return next({ name: 'Hub' });
      }

      const requiredPermission = to.meta.permission as string | undefined;
      const requiredModule = to.meta.requiresModule as 'mj' | 'cajuia' | undefined;
      const isSuperAdmin = userStore.profile?.role === 'super_admin';

      if (requiredPermission) {
         if (!isSuperAdmin && !userStore.hasPermission(requiredPermission)) {
             // ALTERADO DE 'Hub' PARA 'Unauthorized'
             return next({ name: 'Unauthorized', query: { permissao: requiredPermission } });
         }
         if (requiredModule && userStore.currentModule !== requiredModule) {
             userStore.setModule(requiredModule);
         }
         return next();
      }

      if (userStore.isLoggedIn && toName !== 'Hub' && requiredModule) {
        if (userStore.currentModule !== requiredModule) {
            return next({ name: 'Hub', query: { erro: 'modulo_incorreto' } });
        }
        if (isSuperAdmin) return next();
        if (requiredModule === 'mj' && !userStore.hasMJAccess) return next({ name: 'Hub', query: { acesso_negado: 'true', modulo: 'mj' } });
        if (requiredModule === 'cajuia' && !userStore.hasCajuiaAccess) return next({ name: 'Hub', query: { acesso_negado: 'true', modulo: 'cajuia' } });
      }

      if (toName === 'CRM' && !userStore.canAccessCrm && !isSuperAdmin) {
         return next({ name: 'Hub', query: { acesso_negado: 'true', recurso: 'CRM' } });
      }

      next();

  } catch (criticalError) {
      // O SALVA-VIDAS 🛟: Se estourar um erro gigantesco e assíncrono no F5 que não foi pego...
      console.error('[CRITICAL ROUTER ERROR] Erro não tratado na navegação:', criticalError);

      // ...nós garantimos que a promessa resolve (next) e a tela monta!
      // Se a rota exigia login, chutamos com segurança pro login. Se não, deixa tentar renderizar.
      if (to.matched.some(record => record.meta.requiresAuth)) {
          return next({ name: 'Login' });
      }
      return next();
  }
});

export default router;
