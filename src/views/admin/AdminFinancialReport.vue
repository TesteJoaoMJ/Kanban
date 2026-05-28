<template>
  <div
    class="financial-report-layout font-sans fill-height d-flex flex-column relative overflow-hidden"
    :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 text-grey-darken-4' : 'bg-glass-dark text-white'"
  >
    <div v-if="themeStore.currentMode !== 'light'" class="background-carousel-wrapper">
      <v-carousel cycle height="100%" hide-delimiters :show-arrows="false" interval="15000" class="fill-height">
        <v-carousel-item src="@/assets/1.jpg" cover></v-carousel-item>
        <v-carousel-item src="@/assets/2.jpg" cover></v-carousel-item>
        <v-carousel-item src="@/assets/3.jpg" cover></v-carousel-item>
      </v-carousel>
      <div class="background-overlay"></div>
    </div>

    <div class="content-wrapper d-flex flex-column fill-height z-10 relative">

      <div
          class="header-bar px-6 py-4 d-flex align-center justify-space-between flex-shrink-0"
          :class="themeStore.currentMode === 'light' ? 'bg-white border-b border-grey-lighten-2 shadow-sm' : 'bg-glass-header border-bottom-white-05'"
      >
          <div class="d-flex flex-column">
              <div class="breadcrumb text-caption">
                  <span class="opacity-70">Financeiro</span>
                  <span class="mx-2 opacity-50">></span>
                  <span class="font-weight-bold">Relatórios</span>
              </div>
              <div class="text-h6 font-weight-black tracking-tight leading-none mt-1">
                  Extrato e Relatório Financeiro
              </div>
          </div>

          <v-btn
              color="primary"
              variant="flat"
              class="btn-rect px-6 font-weight-bold text-uppercase letter-spacing-1 shadow-indigo-soft"
              height="40"
              prepend-icon="mdi-printer"
              @click="printReport"
              :disabled="loading || filteredData.length === 0"
          >
              Imprimir Relatório
          </v-btn>
      </div>

      <div class="px-6 pt-4 pb-0 flex-shrink-0">
          <v-row>
              <v-col cols="12" sm="4">
                  <v-card class="kpi-card kpi-rect bg-gradient-green hover-elevate py-3 px-4" elevation="2">
                      <div class="kpi-bg-icon"><v-icon>mdi-arrow-up-circle</v-icon></div>
                      <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                          <div class="d-flex align-center gap-2">
                              <v-icon size="18" class="opacity-80">mdi-cash-plus</v-icon>
                              <span class="kpi-label">Total Receitas</span>
                          </div>
                          <div class="kpi-number-group my-1">
                              <span class="text-body-2 font-weight-medium mr-1 opacity-70">R$</span>
                              <span class="kpi-value text-h5">{{ formatCurrencyValue(kpis.receitas) }}</span>
                          </div>
                      </div>
                  </v-card>
              </v-col>

              <v-col cols="12" sm="4">
                  <v-card class="kpi-card kpi-rect bg-gradient-danger hover-elevate py-3 px-4" elevation="2">
                      <div class="kpi-bg-icon"><v-icon>mdi-arrow-down-circle</v-icon></div>
                      <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                          <div class="d-flex align-center gap-2">
                              <v-icon size="18" class="opacity-80">mdi-cash-minus</v-icon>
                              <span class="kpi-label">Total Despesas</span>
                          </div>
                          <div class="kpi-number-group my-1">
                              <span class="text-body-2 font-weight-medium mr-1 opacity-70">R$</span>
                              <span class="kpi-value text-h5">{{ formatCurrencyValue(kpis.despesas) }}</span>
                          </div>
                      </div>
                  </v-card>
              </v-col>

              <v-col cols="12" sm="4">
                  <v-card class="kpi-card kpi-rect hover-elevate py-3 px-4" :class="kpis.saldo >= 0 ? 'bg-gradient-info' : 'bg-gradient-warning'" elevation="2">
                      <div class="kpi-bg-icon"><v-icon>mdi-scale-balance</v-icon></div>
                      <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                          <div class="d-flex align-center gap-2">
                              <v-icon size="18" class="opacity-80">mdi-bank</v-icon>
                              <span class="kpi-label">Saldo do Período</span>
                          </div>
                          <div class="kpi-number-group my-1">
                              <span class="text-body-2 font-weight-medium mr-1 opacity-70">R$</span>
                              <span class="kpi-value text-h5">{{ formatCurrencyValue(kpis.saldo) }}</span>
                          </div>
                      </div>
                  </v-card>
              </v-col>
          </v-row>
      </div>

      <div class="px-6 pt-4 pb-2 flex-shrink-0">
          <div
            class="controls-bar d-flex align-center justify-space-between flex-wrap gap-3"
            :class="themeStore.currentMode === 'light' ? 'controls-light' : 'controls-dark'"
          >
              <div class="d-flex align-center flex-wrap gap-3 flex-grow-1">

                  <div class="d-flex align-center gap-2">
                      <v-text-field type="date" v-model="filters.startDate" label="De" variant="outlined" density="compact" hide-details class="date-input btn-rect bg-transparent"></v-text-field>
                      <v-text-field type="date" v-model="filters.endDate" label="Até" variant="outlined" density="compact" hide-details class="date-input btn-rect bg-transparent"></v-text-field>
                  </div>

                  <div style="width: 160px;">
                      <v-select
                          v-model="filters.type"
                          :items="[{title: 'Todos os Tipos', value: 'ALL'}, {title: 'Só Receitas', value: 'RECEIVABLE'}, {title: 'Só Despesas', value: 'PAYABLE'}]"
                          variant="outlined" density="compact" hide-details class="clean-input btn-rect" bg-color="transparent"
                      ></v-select>
                  </div>

                  <div style="width: 150px;">
                      <v-select
                          v-model="filters.status"
                          :items="[{title: 'Qualquer Status', value: 'ALL'}, {title: 'Pagos/Recebidos', value: 'PAID'}, {title: 'Pendentes', value: 'PENDING'}]"
                          variant="outlined" density="compact" hide-details class="clean-input btn-rect" bg-color="transparent"
                      ></v-select>
                  </div>

                  <div class="search-wrap d-flex align-center flex-grow-1" :class="themeStore.currentMode === 'light' ? 'search-light' : 'search-dark'">
                      <v-icon color="grey-darken-1">mdi-magnify</v-icon>
                      <input v-model="filters.search" type="text" placeholder="Buscar por cliente, fornecedor, descrição..." class="clean-input flex-grow-1 ml-2" />
                  </div>

                  <v-btn icon variant="tonal" color="primary" height="40" width="40" class="btn-rect" @click="fetchData" :loading="loading">
                      <v-icon>mdi-refresh</v-icon>
                  </v-btn>
              </div>
          </div>
      </div>

      <div class="flex-grow-1 px-6 pb-4 overflow-hidden d-flex flex-column mt-2">
          <v-card
            class="flex-grow-1 d-flex flex-column rounded-0 border-thin overflow-hidden"
            :class="themeStore.currentMode === 'light' ? 'bg-white shadow-sm' : 'glass-card border-white-05'"
            :elevation="0"
          >
              <div class="grid-scroll flex-grow-1 overflow-y-auto custom-scroll">
                  <div class="grid-header sticky-head" :class="[themeStore.currentMode === 'light' ? 'grid-surface-light' : 'grid-surface-dark', 'grid-finance-layout']">
                      <div class="cell center header-text">Tipo</div>
                      <div class="cell center header-text">Vencimento</div>
                      <div class="cell header-text pl-4">Descrição</div>
                      <div class="cell header-text pl-4">Cliente / Fornecedor</div>
                      <div class="cell center header-text">Status</div>
                      <div class="cell right header-text pr-4">Valor</div>
                  </div>

                  <div v-if="loading" class="d-flex flex-column justify-center align-center h-100 py-10">
                      <v-progress-circular indeterminate color="primary" size="32" width="3"></v-progress-circular>
                  </div>

                  <div v-else-if="filteredData.length === 0" class="d-flex flex-column justify-center align-center h-100 py-10 opacity-60">
                      <v-icon size="48" class="mb-2">mdi-text-box-search-outline</v-icon>
                      <span>Nenhum lançamento encontrado para os filtros atuais.</span>
                  </div>

                  <template v-else>
                      <div v-for="item in filteredData" :key="item.id + item.type" class="grid-row zebra-row" :class="[themeStore.currentMode === 'light' ? 'grid-row-light' : 'grid-row-dark', 'grid-finance-layout']">
                          <div class="cell center">
                               <v-chip size="x-small" variant="flat" :color="item.type === 'RECEITA' ? 'success' : 'error'" class="font-weight-bold">
                                  <v-icon start size="12">{{ item.type === 'RECEITA' ? 'mdi-arrow-up' : 'mdi-arrow-down' }}</v-icon>
                                  {{ item.type }}
                               </v-chip>
                          </div>
                          <div class="cell center"><span class="list-text-10 font-mono" :class="isOverdue(item) ? 'text-error font-weight-bold' : ''">{{ formatDate(item.due_date) }}</span></div>
                          <div class="cell pl-4"><span class="list-text-10 font-weight-medium text-truncate">{{ item.description }}</span></div>
                          <div class="cell pl-4"><span class="list-text-10 text-truncate opacity-80">{{ item.entity_name || 'Não Informado' }}</span></div>
                          <div class="cell center">
                              <v-chip size="x-small" class="font-weight-black text-uppercase letter-spacing-1 solid-chip" :class="item.status === 'pago' ? 'chip-success' : 'chip-warning'">
                                  {{ item.status === 'pago' ? 'Liquidado' : 'Pendente' }}
                              </v-chip>
                          </div>
                          <div class="cell right pr-4">
                              <span class="list-text-10 font-mono font-weight-black" :class="item.type === 'RECEITA' ? 'text-success' : 'text-error'">
                                  {{ item.type === 'RECEITA' ? '+' : '-' }} {{ formatCurrency(item.value) }}
                              </span>
                          </div>
                      </div>
                  </template>
              </div>
          </v-card>
      </div>

    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted, watch } from 'vue';
import { supabase } from '@/api/supabase';
import { useAppStore } from '@/stores/app';
import { useThemeStore } from '@/stores/themeStore';
import { format, parseISO, isBefore, startOfDay } from 'date-fns';

// Imports de Logo para o relatório
import logoMjlm from '@/assets/logomjlm.png';

const appStore = useAppStore();
const themeStore = useThemeStore();

const now = new Date();
const firstDay = new Date(now.getFullYear(), now.getMonth(), 1).toISOString().substring(0, 10);
const lastDay = new Date(now.getFullYear(), now.getMonth() + 1, 0).toISOString().substring(0, 10);

const loading = ref(false);
const transactions = ref<any[]>([]);

// Estado dos Filtros
const filters = reactive({
    startDate: firstDay,
    endDate: lastDay,
    type: 'ALL', // ALL, RECEIVABLE, PAYABLE
    status: 'ALL', // ALL, PAID, PENDING
    search: ''
});

// Busca os dados das DUAS tabelas
const fetchData = async () => {
    loading.value = true;
    transactions.value = [];

    try {
        // Busca Receitas (Adapte o nome da tabela conforme seu banco, ex: mj_receivables)
        const { data: receitas } = await supabase
            .from('mj_receivables')
            .select('*')
            .gte('due_date', filters.startDate)
            .lte('due_date', filters.endDate);

        // Busca Despesas (Adapte o nome da tabela conforme seu banco, ex: mj_accounts_payable)
        const { data: despesas } = await supabase
            .from('mj_accounts_payable')
            .select('*')
            .gte('due_date', filters.startDate)
            .lte('due_date', filters.endDate);

        const formatedReceitas = (receitas || []).map(r => ({
            ...r, type: 'RECEITA', entity_name: r.customer_name || r.cliente
        }));

        const formatedDespesas = (despesas || []).map(d => ({
            ...d, type: 'DESPESA', entity_name: d.supplier_name || d.fornecedor
        }));

        transactions.value = [...formatedReceitas, ...formatedDespesas].sort((a, b) => {
            return new Date(a.due_date).getTime() - new Date(b.due_date).getTime();
        });

    } catch (error) {
        console.error("Erro ao buscar dados financeiros", error);
        appStore.showSnackbar("Erro ao carregar dados.", "error");
    } finally {
        loading.value = false;
    }
};

// Filtro no Frontend (para a busca de texto e seletores rápidos)
const filteredData = computed(() => {
    let list = transactions.value;

    if (filters.type !== 'ALL') {
        const typeFilter = filters.type === 'RECEIVABLE' ? 'RECEITA' : 'DESPESA';
        list = list.filter(t => t.type === typeFilter);
    }

    if (filters.status !== 'ALL') {
        const statusFilter = filters.status === 'PAID' ? 'pago' : 'pendente';
        list = list.filter(t => (t.status || '').toLowerCase() === statusFilter);
    }

    if (filters.search) {
        const q = filters.search.toLowerCase();
        list = list.filter(t =>
            (t.description || '').toLowerCase().includes(q) ||
            (t.entity_name || '').toLowerCase().includes(q)
        );
    }

    return list;
});

// Calcula os KPIs
const kpis = computed(() => {
    let rec = 0;
    let des = 0;
    filteredData.value.forEach(t => {
        const val = Number(t.value) || 0;
        if (t.type === 'RECEITA') rec += val;
        else if (t.type === 'DESPESA') des += val;
    });
    return {
        receitas: rec,
        despesas: des,
        saldo: rec - des
    };
});

// Helpers Visuais
const formatCurrency = (v: any) => new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(Number(v)||0);
const formatCurrencyValue = (v: any) => new Intl.NumberFormat('pt-BR', { minimumFractionDigits: 2 }).format(Number(v)||0);
const formatDate = (d: string) => d ? format(parseISO(d), 'dd/MM/yyyy') : '-';
const isOverdue = (item: any) => {
    if (item.status === 'pago') return false;
    return isBefore(parseISO(item.due_date), startOfDay(new Date()));
};

// IMPRIMIR RELATÓRIO HTML
const printReport = () => {
    const printWindow = window.open('', '_blank');
    if (!printWindow) {
        appStore.showSnackbar('Permita a abertura de pop-ups para visualizar o relatório.', 'warning');
        return;
    }

    let rowsHtml = '';
    filteredData.value.forEach(item => {
        const typeStyle = item.type === 'RECEITA' ? 'color: #2e7d32;' : 'color: #c62828;';
        const typeSign = item.type === 'RECEITA' ? '+' : '-';

        rowsHtml += `
            <tr>
                <td class="text-center" style="font-weight: bold; ${typeStyle}">${item.type}</td>
                <td class="text-center">${formatDate(item.due_date)}</td>
                <td>${item.description || '-'}</td>
                <td>${item.entity_name || '-'}</td>
                <td class="text-center">${item.status === 'pago' ? 'Liquidado' : 'Pendente'}</td>
                <td class="text-right" style="font-weight: bold; ${typeStyle}">${typeSign} ${formatCurrency(item.value)}</td>
            </tr>
        `;
    });

    const html = `
        <!DOCTYPE html>
        <html lang="pt-BR">
        <head>
            <meta charset="UTF-8">
            <title>Relatório Financeiro</title>
            <style>
                body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; padding: 20px; color: #333; margin: 0; }
                .header { display: flex; justify-content: space-between; align-items: flex-start; border-bottom: 2px solid #1976d2; padding-bottom: 15px; margin-bottom: 20px; }
                .header-info h1 { margin: 0 0 5px 0; font-size: 22px; color: #1976d2; text-transform: uppercase; letter-spacing: 1px; }
                .header-info p { margin: 3px 0; font-size: 12px; color: #555; }

                .logo-placeholder { display: flex; align-items: center; justify-content: flex-end; }
                .logo-placeholder img { max-width: 160px; max-height: 65px; object-fit: contain; }

                .kpis { display: flex; gap: 15px; margin-bottom: 20px; }
                .kpi { border: 1px solid #e0e0e0; background: #f9f9f9; padding: 15px; border-radius: 6px; flex: 1; text-align: center; }
                .kpi-title { font-size: 11px; text-transform: uppercase; font-weight: bold; color: #757575; margin-bottom: 5px; }
                .kpi-value { font-size: 20px; font-weight: 900; color: #212121; }
                .kpi-value.success { color: #2e7d32; }
                .kpi-value.danger { color: #c62828; }
                .kpi-value.info { color: #0288d1; }

                table { width: 100%; border-collapse: collapse; font-size: 11px; margin-bottom: 20px;}
                th, td { border: 1px solid #ddd; padding: 8px; }
                th { background-color: #f5f5f5; text-transform: uppercase; color: #555; text-align: left; }
                .text-right { text-align: right; }
                .text-center { text-align: center; }
                tr:nth-child(even) { background-color: #fafafa; }

                .footer { margin-top: 30px; font-size: 10px; color: #888; text-align: center; border-top: 1px solid #eee; padding-top: 10px; }

                @media print {
                    body { padding: 0; }
                    .header { border-bottom: 1px solid #ccc; }
                    .kpi { border: 1px solid #ccc; background: transparent; }
                    @page { margin: 1.5cm; size: A4 portrait; }
                }
            </style>
        </head>
        <body>
            <div class="header">
                <div class="header-info">
                    <h1>Relatório Financeiro</h1>
                    <p><strong>Tipo de Lançamentos:</strong> ${filters.type === 'ALL' ? 'Receitas e Despesas' : filters.type === 'RECEIVABLE' ? 'Apenas Receitas' : 'Apenas Despesas'}</p>
                    <p><strong>Status:</strong> ${filters.status === 'ALL' ? 'Pagos e Pendentes' : filters.status === 'PAID' ? 'Liquidados' : 'Pendentes'}</p>
                    <p><strong>Período (Vencimento):</strong> ${formatDate(filters.startDate)} a ${formatDate(filters.endDate)}</p>
                </div>
                <div class="logo-placeholder">
                    <img src="${logoMjlm}" alt="Logo da Empresa">
                </div>
            </div>

            <div class="kpis">
                <div class="kpi">
                    <div class="kpi-title">Total Receitas</div>
                    <div class="kpi-value success">${formatCurrency(kpis.value.receitas)}</div>
                </div>
                <div class="kpi">
                    <div class="kpi-title">Total Despesas</div>
                    <div class="kpi-value danger">${formatCurrency(kpis.value.despesas)}</div>
                </div>
                <div class="kpi">
                    <div class="kpi-title">Saldo Projetado</div>
                    <div class="kpi-value info">${formatCurrency(kpis.value.saldo)}</div>
                </div>
            </div>

            <table>
                <thead>
                    <tr>
                        <th class="text-center" style="width: 80px;">Tipo</th>
                        <th class="text-center" style="width: 80px;">Vencimento</th>
                        <th>Descrição</th>
                        <th>Cliente / Fornecedor</th>
                        <th class="text-center" style="width: 90px;">Status</th>
                        <th class="text-right" style="width: 110px;">Valor</th>
                    </tr>
                </thead>
                <tbody>
                    ${rowsHtml}
                </tbody>
            </table>

            <div class="footer">
                Relatório gerado pelo Sistema em ${new Date().toLocaleString('pt-BR')}
            </div>

            <script>
                window.onload = () => {
                    setTimeout(() => {
                        window.print();
                        window.close();
                    }, 500);
                };
            <\/script>
        </body>
        </html>
    `;

    printWindow.document.open();
    printWindow.document.write(html);
    printWindow.document.close();
};

// Ao alterar a data base, busca de novo no banco
watch(() => filters.startDate, fetchData);
watch(() => filters.endDate, fetchData);

onMounted(() => {
    fetchData();
});
</script>

<style scoped lang="scss">
.financial-report-layout { position: relative; }
.background-carousel-wrapper { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 0; opacity: 0.6; pointer-events: none; }
.background-overlay { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 1; background: radial-gradient(circle at center, rgba(15, 15, 19, 0.4), rgba(15, 15, 19, 0.98)); backdrop-filter: blur(8px); }
.z-10 { position: relative; z-index: 10; }
.bg-glass-dark { background: rgba(10,10,12,0.85); }
.bg-glass-header { background: rgba(20,20,24,0.55); backdrop-filter: blur(14px); }
.border-bottom-white-05 { border-bottom: 1px solid rgba(255,255,255,0.08); }

.btn-rect { border-radius: 0 !important; text-transform: none !important; font-weight: 800; }
.controls-bar { border: 1px solid rgba(0,0,0,0.08); border-radius: 0; padding: 10px; }
.controls-light { background: #ffffff; }
.controls-dark { background: rgba(30,30,35,0.55); backdrop-filter: blur(16px); border: 1px solid rgba(255,255,255,0.08); }

.search-wrap { height: 40px; border-radius: 0; padding: 0 12px; min-width: 250px; }
.search-light { background: #f4f6f8; border: 1px solid rgba(0,0,0,0.08); }
.search-dark { background: rgba(255,255,255,0.08); border: 1px solid rgba(255,255,255,0.10); }

.clean-input { border: none; outline: none; background: transparent; font-size: 12px; color: inherit; width: 100%; }
.date-input { width: 130px; }

.kpi-bg-icon { position: absolute; right: -20px; bottom: -20px; opacity: 0.15; transform: rotate(-15deg); pointer-events: none; }
.kpi-bg-icon .v-icon { font-size: 100px; color: white; }
.kpi-card { border: 1px solid rgba(255,255,255,0.15); color: white; min-height: 110px; position: relative; overflow: hidden; border-radius: 0 !important; }
.bg-gradient-info { background: linear-gradient(135deg, #0288d1, #005b9f); }
.bg-gradient-green { background: linear-gradient(135deg, #2e7d32, #1b5e20); }
.bg-gradient-warning { background: linear-gradient(135deg, #FFB300, #F57F17); }
.bg-gradient-danger { background: linear-gradient(135deg, #c62828, #b71c1c); }

.kpi-label { font-size: 12px; font-weight: 900; letter-spacing: .2px; }
.kpi-value { font-size: 24px; font-weight: 900; letter-spacing: .2px; }

/* Grid Atualizado para o Financeiro */
.grid-finance-layout {
  display: grid;
  width: 100%;
  grid-template-columns: 100px 120px 2fr 1.5fr 120px 140px;
}

.cell { padding: 8px 10px; display: flex; align-items: center; border-right: 1px solid rgba(0,0,0,0.08); border-bottom: 1px solid rgba(0,0,0,0.08); min-height: 56px; overflow: hidden; }
.center { justify-content: center; text-align: center; }
.right { justify-content: flex-end; text-align: right; }

.header-text { font-size: 11px; font-weight: 900; text-transform: uppercase; letter-spacing: 0.5px; opacity: 0.8; padding: 12px 8px; }
.zebra-row:nth-child(even) .cell { background-color: rgba(0,0,0,0.02); }
.grid-row-dark.zebra-row:nth-child(even) .cell { background-color: rgba(255,255,255,0.02); }
.grid-header .cell { min-height: 44px; font-size: 12px; font-weight: 900; text-transform: uppercase; letter-spacing: .6px; }

.grid-surface-light .cell { background: #f5f7fa; color: rgba(0,0,0,0.7); }
.grid-surface-dark .cell { background: rgba(255,255,255,0.08); color: rgba(255,255,255,0.80); }
.sticky-head { position: sticky; top: 0; z-index: 10; }

.shadow-indigo-soft { box-shadow: 0 4px 15px rgba(63, 81, 181, 0.4); }
.custom-scroll::-webkit-scrollbar { width: 6px; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.3); border-radius: 4px; }
.list-text-10 { font-size: 13px !important; line-height: 1.25 !important; }

.solid-chip { display: inline-flex; align-items: center; justify-content: center; height: 22px; padding: 0 10px; border-radius: 8px; font-size: 10px; font-weight: 900; color: #fff; white-space: nowrap; }
.chip-success { background: #2e7d32; }
.chip-warning { background: #f57f17; }
</style>
