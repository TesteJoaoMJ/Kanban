<template>
  <v-container fluid class="admin-dashboard-container pa-6" :class="{ 'light-mode-container': isLight }">

    <div class="header-section mb-6 animate-fade-in-down">
      <div class="d-flex flex-column flex-md-row justify-space-between align-md-center ga-4">
        <div class="d-flex align-center">
          <div class="icon-box-lg mr-4 rounded-xl d-flex align-center justify-center transition-all card-3d"
            :class="isLight ? 'bg-grey-darken-4 text-white' : 'bg-gradient-primary'">
            <v-icon color="white" size="28">mdi-monitor-dashboard</v-icon>
          </div>
          <div>
            <div class="d-flex align-center text-caption font-weight-bold mb-1 opacity-70" :class="isLight ? 'text-grey-darken-2' : 'text-white'">
              <span class="mr-2">MJ PROCESS</span>
              <v-icon size="x-small" class="mr-2">mdi-chevron-right</v-icon>
              <span>DASHBOARD</span>
            </div>
            <h1 class="text-h4 font-weight-black" :class="isLight ? 'text-grey-darken-4' : 'text-white'">
              Visão Geral
            </h1>
          </div>
        </div>

        <div class="d-flex align-center px-4 py-2 border-thin card-3d" :class="isLight ? 'bg-white' : 'glass-card'">
           <div class="text-right mr-4 border-r pr-4" :class="isLight ? 'border-grey-lighten-2' : 'border-white-10'">
              <div class="text-h6 font-weight-bold font-mono leading-none" :class="isLight ? 'text-grey-darken-4' : 'text-white'">
                {{ currentTime }}
              </div>
              <div class="text-caption font-weight-bold text-uppercase" :class="isLight ? 'text-grey-darken-1' : 'text-medium-emphasis'">
                {{ currentDate }}
              </div>
           </div>
           <div class="d-flex flex-column align-start">
              <div class="d-flex align-center text-caption font-weight-bold text-success mb-1">
                 <div class="status-dot bg-success mr-2 blink"></div>
                 SISTEMA ONLINE
              </div>
              <div class="text-caption font-mono font-weight-bold" :class="isLight ? 'text-grey-darken-1' : 'text-grey-lighten-1'" style="font-size: 0.7rem;">
                 SYNC: {{ lastSyncTime }}
              </div>
           </div>
        </div>

        <div class="d-flex align-center flex-wrap ga-3">
          <v-btn to="/estoque" variant="flat" color="success" class="btn-3d font-weight-bold text-uppercase" prepend-icon="mdi-package-variant-closed" size="small" height="40">
            Check Estoque
          </v-btn>
          <v-tooltip text="Relatórios Avançados" location="bottom" content-class="tooltip-contrast">
            <template v-slot:activator="{ props }">
              <v-btn v-bind="props" class="square-btn btn-3d" variant="flat" :color="isLight ? 'indigo' : 'white'" @click="showReportModal = true">
                <v-icon size="18" :color="isLight ? 'white' : 'black'">mdi-file-chart-outline</v-icon>
              </v-btn>
            </template>
          </v-tooltip>
        </div>
      </div>
    </div>

    <v-row class="mb-4 animate-fade-in-up" style="animation-delay: 0.1s" dense>
      <v-col cols="12" sm="6" md="4" lg="2">
        <v-card class="kpi-card-3d bg-gradient-orange" @click="openModal('Pedidos Pendentes de Aprovação', ordersPendingApproval, 'orange')" v-ripple>
          <div class="kpi-bg-icon"><v-icon>mdi-alert-decagram</v-icon></div>
          <div class="d-flex flex-column position-relative z-10 h-100 justify-space-between">
            <div>
                <span class="kpi-label">Aprovação</span>
                <div class="kpi-number-group"><span class="kpi-value font-mono">{{ ordersPendingApproval.length }}</span><span class="kpi-unit">pedidos</span></div>
            </div>
            <div class="kpi-footer">{{ formatNumber(totalMetersPendingApproval) }}m pendentes</div>
          </div>
        </v-card>
      </v-col>

      <v-col cols="12" sm="6" md="4" lg="2">
        <v-card class="kpi-card-3d bg-gradient-green" @click="openModal('Pedidos Entregues', filteredDeliveredOrders, 'green-darken-2')" v-ripple>
          <div class="kpi-bg-icon"><v-icon>mdi-truck-check</v-icon></div>
          <div class="d-flex flex-column position-relative z-10 h-100 justify-space-between">
            <div>
                <span class="kpi-label">Entregues</span>
                <div class="kpi-number-group"><span class="kpi-value font-mono">{{ filteredDeliveredOrders.length }}</span><span class="kpi-unit">pedidos</span></div>
            </div>
            <div class="kpi-footer">{{ formatNumber(totalMetersDelivered) }}m (Filtro)</div>
          </div>
        </v-card>
      </v-col>

      <v-col cols="12" sm="6" md="4" lg="2">
        <v-card class="kpi-card-3d bg-gradient-red" @click="openKpiDetailModal('delayed')" v-ripple>
          <div class="kpi-bg-icon"><v-icon>mdi-clock-alert</v-icon></div>
          <div class="d-flex flex-column position-relative z-10 h-100 justify-space-between">
            <div>
                <span class="kpi-label">Atraso Design</span>
                <div class="kpi-number-group"><span class="kpi-value font-mono">{{ itemsDelayedInDesign.count }}</span><span class="kpi-unit">itens</span></div>
            </div>
            <div class="kpi-footer">{{ formatNumber(itemsDelayedInDesign.totalMeters) }}m atrasados</div>
          </div>
        </v-card>
      </v-col>

      <v-col cols="12" sm="6" md="4" lg="2">
        <v-card class="kpi-card-3d bg-gradient-purple" @click="openModal('Total de Pedidos em Aberto', allOpenOrders, 'purple-lighten-2')" v-ripple>
          <div class="kpi-bg-icon"><v-icon>mdi-chart-pie</v-icon></div>
          <div class="d-flex flex-column position-relative z-10 h-100 justify-space-between">
            <div>
                <span class="kpi-label">Total Aberto</span>
                <div class="kpi-number-group"><span class="kpi-value font-mono">{{ allOpenOrders.length }}</span><span class="kpi-unit">pedidos</span></div>
            </div>
            <div class="kpi-footer">{{ formatNumber(totalMetersOpen) }}m na fila</div>
          </div>
        </v-card>
      </v-col>

      <v-col cols="12" sm="6" md="4" lg="2">
        <v-card class="kpi-card-3d bg-gradient-cyan" @click="openModal('Pedidos em Produção', productionOrders, 'cyan-darken-2')" v-ripple>
          <div class="kpi-bg-icon"><v-icon>mdi-factory</v-icon></div>
          <div class="d-flex flex-column position-relative z-10 h-100 justify-space-between">
            <div>
                <span class="kpi-label">Produção</span>
                <div class="kpi-number-group"><span class="kpi-value font-mono">{{ productionOrders.length }}</span><span class="kpi-unit">pedidos</span></div>
            </div>
            <div class="kpi-footer">{{ formatNumber(productionOrdersMeters) }}m ativos</div>
          </div>
        </v-card>
      </v-col>

      <v-col cols="12" sm="6" md="4" lg="2">
        <v-card class="kpi-card-3d bg-gradient-blue" @click="openKpiDetailModal('design')" v-ripple>
          <div class="kpi-bg-icon"><v-icon>mdi-palette</v-icon></div>
          <div class="d-flex flex-column position-relative z-10 h-100 justify-space-between">
            <div>
                <span class="kpi-label">Fila Design</span>
                <div class="kpi-number-group"><span class="kpi-value font-mono">{{ formatNumber(totalMetersInDesign) }}</span><span class="kpi-unit">m</span></div>
            </div>
            <div class="kpi-footer">Aguardando arte</div>
          </div>
        </v-card>
      </v-col>
    </v-row>

    <v-row class="mb-6 animate-fade-in-up" style="animation-delay: 0.15s" dense>
        <v-col cols="12" md="8">
            <v-card class="pa-4 border-thin h-100 d-flex flex-column card-3d" :class="isLight ? 'bg-white' : 'glass-card'">
               <div class="d-flex align-center justify-space-between mb-4">
                  <div class="d-flex align-center">
                     <v-avatar color="indigo-lighten-5" class="mr-3 rounded-lg" size="36">
                        <v-icon color="indigo" size="20">mdi-chart-bar</v-icon>
                     </v-avatar>
                     <div>
                        <div class="text-caption font-weight-bold text-uppercase opacity-70" :class="isLight ? 'text-grey-darken-2' : ''">Volume de Pedidos</div>
                        <div class="text-body-2 font-weight-bold" :class="isLight ? 'text-grey-darken-4' : ''">Evolução no Período</div>
                     </div>
                  </div>
                  <v-btn-toggle v-model="orderChartPeriod" mandatory density="compact" variant="outlined" class="rounded-lg btn-3d" :color="isLight ? 'indigo' : 'white'" divided>
                    <v-btn value="month" class="px-3 text-caption font-weight-bold">Mensal</v-btn>
                    <v-btn value="year" class="px-3 text-caption font-weight-bold">Anual</v-btn>
                  </v-btn-toggle>
               </div>
               <div class="flex-grow-1" style="height: 250px; min-height: 250px;">
                  <Bar :data="ordersVolumeChartData" :options="orderChartOptions" />
               </div>
            </v-card>
        </v-col>

        <v-col cols="12" md="4">
            <v-card class="pa-4 border-thin h-100 d-flex flex-column card-3d" :class="isLight ? 'bg-white' : 'glass-card'">
               <div class="d-flex align-center justify-space-between mb-2">
                  <div class="d-flex align-center">
                     <v-avatar color="red-lighten-5" class="mr-3 rounded-lg" size="36">
                        <v-icon color="red-darken-1" size="20">mdi-alert-circle</v-icon>
                     </v-avatar>
                     <div>
                        <div class="text-caption font-weight-bold text-uppercase opacity-70" :class="isLight ? 'text-grey-darken-2' : ''">Monitor de Prazos</div>
                        <div class="text-body-2 font-weight-bold" :class="isLight ? 'text-grey-darken-4' : ''">Pedidos em Atraso</div>
                     </div>
                  </div>
                  <v-chip color="error" size="small" variant="tonal" class="font-weight-black chip-3d">Crítico</v-chip>
               </div>

               <div class="d-flex flex-column justify-center align-center flex-grow-1 py-4">
                  <div class="text-h2 font-weight-black text-red-accent-2 mb-2" :class="isLight ? 'text-red-darken-2' : ''">
                     {{ delayedOrdersList.length }}
                  </div>
                  <div class="text-caption text-center mb-4 font-weight-bold" :class="isLight ? 'text-grey-darken-1' : 'text-medium-emphasis'">
                     Pedidos em aberto com data <br>de entrega expirada
                  </div>

                  <v-btn color="indigo" variant="flat" prepend-icon="mdi-file-pdf-box" class="font-weight-bold mb-3 w-100 btn-3d" @click="openReportDialog">
                    Gerar Relatório PDF
                  </v-btn>

                  <v-btn variant="tonal" :color="isLight ? 'grey-darken-3' : 'white'" class="w-100 btn-3d font-weight-bold" @click="showDelayedOrdersModal = true">
                    Ver Lista Completa e Gerenciar
                  </v-btn>
               </div>
            </v-card>
        </v-col>
    </v-row>

    <div class="mb-8 animate-fade-in-up" style="animation-delay: 0.2s">
        <DeliveryCalendar
            :orders="allOrders"
            @edit="openEditOrder"
            @cancel="cancelOrder"
            @print="printReceipt"
        />
    </div>

    <v-card class="border-thin animate-fade-in-up card-3d overflow-hidden" :class="isLight ? 'bg-white' : 'glass-card'" style="animation-delay: 0.3s">
      <div class="d-flex flex-column flex-sm-row align-center justify-space-between px-6 py-4" :class="isLight ? 'border-b border-grey-lighten-2' : 'border-b border-white-05'">
        <div class="tabs-pill-container rounded-pill pa-1 d-flex" :class="isLight ? 'bg-grey-lighten-4' : 'bg-white-05'">
          <div class="tab-pill font-weight-bold" :class="{ active: mainTab === 'list', 'light-active': isLight && mainTab === 'list' }" @click="mainTab = 'list'">
            <v-icon size="small" class="mr-2">mdi-format-list-bulleted-square</v-icon> Lista de Pedidos
          </div>
          <div class="tab-pill font-weight-bold" :class="{ active: mainTab === 'charts', 'light-active': isLight && mainTab === 'charts' }" @click="mainTab = 'charts'">
            <v-icon size="small" class="mr-2">mdi-chart-box</v-icon> Analytics & Gráficos
          </div>
        </div>
        <div class="d-flex align-center mt-4 mt-sm-0 w-100 w-sm-auto" v-if="mainTab === 'list'">
           <div class="search-wrap d-flex align-center flex-grow-1" :class="isLight ? 'search-light' : 'search-dark'" style="width: 300px;">
              <v-icon :color="isLight ? 'grey-darken-1' : 'white-70'">mdi-magnify</v-icon>
              <input
                v-model="search"
                type="text"
                placeholder="BUSCAR PEDIDO..."
                class="clean-input flex-grow-1 font-weight-bold pl-2 text-uppercase"
              />
              <v-icon v-if="search" size="small" class="cursor-pointer opacity-50 ml-2" @click="search = ''">mdi-close</v-icon>
            </div>
        </div>
      </div>

      <v-window v-model="mainTab" class="pa-0 bg-transparent">
        <v-window-item value="list">
          <div class="filter-toolbar px-6 py-3 d-flex flex-wrap align-center ga-3" :class="isLight ? 'bg-grey-lighten-5 border-b border-grey-lighten-2' : 'bg-surface-darker border-b border-white-05'">
            <v-icon size="small" color="indigo">mdi-filter-variant</v-icon>
            <span class="text-caption font-weight-bold text-uppercase mr-1" :class="isLight ? 'text-grey-darken-2' : 'text-medium-emphasis'">Período:</span>
            <v-chip-group v-model="filterType" mandatory selected-class="text-white bg-indigo glow-chip" class="custom-chip-group">
              <v-chip value="today" size="small" :variant="isLight ? 'flat' : 'outlined'" class="font-weight-bold chip-3d" :class="isLight ? 'bg-white' : ''">Hoje</v-chip>
              <v-chip value="current_week" size="small" :variant="isLight ? 'flat' : 'outlined'" class="font-weight-bold chip-3d" :class="isLight ? 'bg-white' : ''">Esta Semana</v-chip>
              <v-chip value="current_month" size="small" :variant="isLight ? 'flat' : 'outlined'" class="font-weight-bold chip-3d" :class="isLight ? 'bg-white' : ''">Este Mês</v-chip>
              <v-chip value="all" size="small" :variant="isLight ? 'flat' : 'outlined'" class="font-weight-bold chip-3d" :class="isLight ? 'bg-white' : ''">Todos</v-chip>
            </v-chip-group>

            <div class="vertical-divider mx-2" :class="isLight ? 'bg-grey-lighten-2' : ''"></div>

            <span class="text-caption font-weight-bold text-uppercase mr-1" :class="isLight ? 'text-grey-darken-2' : 'text-medium-emphasis'">Status:</span>
            <v-chip-group v-model="filterType" selected-class="ring-2 ring-white" class="custom-chip-group">
               <v-chip value="billing" size="small" color="success" variant="flat" class="font-weight-black text-white chip-3d">Aguard. Faturamento</v-chip>
               <v-chip value="delivered" size="small" color="info" variant="flat" class="font-weight-black text-white chip-3d">Entregues</v-chip>
               <v-chip value="delayed" size="small" color="error" variant="flat" class="font-weight-black text-white chip-3d">Atrasados</v-chip>
            </v-chip-group>

            <v-spacer></v-spacer>
            <div class="stats-badge d-flex align-center text-caption font-weight-bold px-3 py-1 rounded-lg border-thin card-3d" :class="isLight ? 'bg-white text-grey-darken-3' : 'glass-card text-white'">
              <v-icon size="x-small" color="indigo" class="mr-2">mdi-database</v-icon>
              {{ filteredOrders.length }} registros
            </div>
          </div>

          <div class="grid-scroll flex-grow-1 overflow-auto custom-scroll relative" style="max-height: 600px;">
            <div
              class="grid-header sticky-head border-b"
              :class="isLight ? 'grid-surface-light' : 'grid-surface-dark'"
              style="grid-template-columns: minmax(280px, 1.5fr) minmax(180px, 1fr) 120px 140px 160px 140px 100px;"
            >
              <div class="cell header-text pl-4 border-r">Cliente / Pedido</div>
              <div class="cell header-text border-r">Vendedor</div>
              <div class="cell center header-text border-r">Tipo</div>
              <div class="cell right header-text border-r">Metragem</div>
              <div class="cell center header-text border-r">{{ filterType === 'delivered' ? 'Entrega' : 'Lançamento' }}</div>
              <div class="cell center header-text border-r">Status</div>
              <div class="cell center header-text">Ações</div>
            </div>

            <div
              v-for="(item, index) in filteredOrders"
              :key="item.id"
              class="grid-row border-b transition-all cursor-pointer hover-lift-row"
              :class="[isLight ? 'grid-row-light' : 'grid-row-dark', zebraClass(index)]"
              style="grid-template-columns: minmax(280px, 1.5fr) minmax(180px, 1fr) 120px 140px 160px 140px 100px;"
              @click="openEditOrder(item)"
            >
              <div class="cell pl-4 border-r">
                <div class="d-flex align-center gap-3 w-100">
                  <v-avatar :color="isLight ? 'grey-lighten-3' : 'surface-light'" size="36" class="font-weight-black text-caption card-3d flex-shrink-0" :class="isLight ? 'text-grey-darken-3' : 'text-white'">
                    {{ item.customer_name.charAt(0) }}
                  </v-avatar>
                  <div class="d-flex flex-column w-100 overflow-hidden">
                    <span class="text-truncate list-text font-weight-black text-uppercase" :title="item.customer_name" :class="isLight ? 'text-grey-darken-4' : 'text-white'">
                      {{ item.customer_name }}
                    </span>
                    <span class="text-caption font-weight-bold font-mono text-indigo" v-if="item.order_number">
                      #{{ String(item.order_number).padStart(4, '0') }}
                    </span>
                  </div>
                </div>
              </div>

              <div class="cell border-r">
                <div class="d-flex align-center gap-2">
                  <v-icon size="small" color="grey">mdi-account-tie-outline</v-icon>
                  <span class="text-truncate list-text font-weight-bold text-uppercase" :class="isLight ? 'text-grey-darken-3' : 'text-white-70'">
                    {{ item.creator?.full_name?.split(' ')[0] || 'Vendedor' }}
                  </span>
                </div>
              </div>

              <div class="cell center border-r">
                <v-chip size="x-small" :color="item.is_launch ? 'purple-darken-2' : 'blue-grey'" variant="flat" class="font-weight-black text-uppercase chip-3d">
                  {{ item.is_launch ? 'Lançamento' : 'Padrão' }}
                </v-chip>
              </div>

              <div class="cell right border-r pr-4">
                <div class="d-flex align-center justify-end w-100">
                  <span class="font-weight-black font-mono list-text" :class="isLight ? 'text-grey-darken-4' : 'text-white'">{{ formatNumber(item.quantity_meters) }}</span>
                  <span class="text-caption font-weight-bold opacity-70 ml-1">m</span>
                </div>
              </div>

              <div class="cell center border-r">
                <span v-if="filterType === 'delivered'" class="list-text font-mono font-weight-bold text-success d-flex align-center">
                  <v-icon size="14" class="mr-1">mdi-check-circle</v-icon>
                  {{ formatDate(item.delivery_confirmed_at) }}
                </span>
                <span v-else class="list-text font-mono font-weight-bold d-flex align-center" :class="isLight ? 'text-grey-darken-2' : 'text-white-70'">
                  <v-icon size="14" class="mr-1">mdi-calendar</v-icon>
                  {{ formatDate(item.created_at) }}
                </span>
              </div>

              <div class="cell center border-r">
                <v-chip :color="getStatusColor(item.status)" size="small" variant="flat" class="font-weight-black text-uppercase text-white chip-3d" style="width: 100px; justify-content: center;">
                  {{ getStatusText(item.status) }}
                </v-chip>
              </div>

              <div class="cell center" style="overflow: visible;">
                 <div class="actions-inline w-100 d-flex justify-center">
                    <v-tooltip text="Ver Detalhes" location="top" content-class="tooltip-contrast">
                      <template v-slot:activator="{ props }">
                        <v-btn v-bind="props" class="square-btn btn-3d" variant="flat" color="indigo" @click.stop="openEditOrder(item)">
                          <v-icon size="16">mdi-eye-outline</v-icon>
                        </v-btn>
                      </template>
                    </v-tooltip>
                 </div>
              </div>

            </div>

            <div v-if="filteredOrders.length === 0" class="pa-10 text-center d-flex flex-column align-center justify-center opacity-60">
                <v-icon size="40" class="mb-2">mdi-alert-circle-outline</v-icon>
                <span class="text-body-2 font-weight-bold text-uppercase">Nenhum pedido encontrado.</span>
            </div>
          </div>

        </v-window-item>

        <v-window-item value="charts">
          <div class="pa-6">
            <v-row class="mb-2">
              <v-col cols="12">
                <v-card class="pa-4 border-thin card-3d" :class="isLight ? 'bg-white' : 'glass-card'">
                  <div class="d-flex align-center justify-space-between mb-4">
                    <div class="d-flex align-center">
                      <div class="icon-box-sm bg-indigo-lighten-5 mr-3 rounded-lg card-3d"><v-icon color="indigo">mdi-chart-line-variant</v-icon></div>
                      <div><h3 class="text-subtitle-1 font-weight-black text-uppercase" :class="isLight ? 'text-grey-darken-4' : 'text-white'">Evolução de Vendas (Semestral)</h3></div>
                    </div>
                  </div>
                  <div style="height: 300px;"><Bar :data="monthlySalesChartData" :options="barOptions" /></div>
                </v-card>
              </v-col>
            </v-row>
          </div>
        </v-window-item>
      </v-window>
    </v-card>

    <v-dialog v-model="reportDialog.show" max-width="500px">
        <v-card class="rounded-xl border-thin card-3d" :class="isLight ? 'bg-white' : 'glass-card'">
            <v-card-title class="d-flex align-center justify-space-between pl-4 pr-2 py-3 border-b bg-indigo-darken-3 text-white">
                <span class="text-h6 font-weight-black text-uppercase">Gerar Relatório de Pedidos</span>
                <v-btn icon="mdi-close" variant="text" size="small" class="btn-3d" @click="reportDialog.show = false" color="white"></v-btn>
            </v-card-title>
            <v-card-text class="pa-5">
                <v-row dense>
                    <v-col cols="12">
                        <label class="text-caption font-weight-bold mb-1 d-block text-uppercase" :class="isLight ? 'text-grey-darken-3' : 'text-white'">Tipo de Relatório</label>
                        <v-select v-model="reportDialog.type" :items="[{title: 'Todos os Pedidos', value: 'all'}, {title: 'Apenas Atrasados', value: 'delayed'}, {title: 'Entregues', value: 'delivered'}]" variant="outlined" density="comfortable" class="ui-field font-weight-bold" :bg-color="isLight ? 'white' : 'transparent'"></v-select>
                    </v-col>
                    <v-col cols="6">
                        <label class="text-caption font-weight-bold mb-1 d-block text-uppercase" :class="isLight ? 'text-grey-darken-3' : 'text-white'">Data Início</label>
                        <v-text-field v-model="reportDialog.startDate" type="date" density="comfortable" variant="outlined" class="ui-field font-weight-bold"></v-text-field>
                    </v-col>
                    <v-col cols="6">
                        <label class="text-caption font-weight-bold mb-1 d-block text-uppercase" :class="isLight ? 'text-grey-darken-3' : 'text-white'">Data Fim</label>
                        <v-text-field v-model="reportDialog.endDate" type="date" density="comfortable" variant="outlined" class="ui-field font-weight-bold"></v-text-field>
                    </v-col>
                </v-row>
            </v-card-text>
            <v-card-actions class="pa-4 pt-0 border-t d-flex justify-end gap-2" :class="isLight ? 'bg-grey-lighten-5' : 'bg-white-05'">
                <v-btn variant="outlined" class="btn-3d font-weight-bold" @click="reportDialog.show = false" :color="isLight ? 'grey-darken-3' : 'white'">Cancelar</v-btn>
                <v-btn color="indigo" variant="flat" class="btn-3d font-weight-bold px-6" :loading="isGeneratingPdf" @click="generateCustomReport"><v-icon start>mdi-download</v-icon> Gerar PDF</v-btn>
            </v-card-actions>
        </v-card>
    </v-dialog>

    <OrderDetailModal :show="showDetailModal" :order-id="selectedOrder?.id" @close="showDetailModal = false" />
    <ApprovalWarningModal :show="showApprovalModal" :pending-orders="ordersPendingApproval" @close="showApprovalModal = false" />
    <ReportSettingsModal :show="showReportModal" @close="showReportModal = false" :orders="allOrders" :sellers="sellerList" :clients="clientList" :fabrics="fabricList" />
    <OpenOrdersModal :show="showOpenOrdersModal" :title="modalTitle" :title-color="modalColor" :orders="modalOrderList" @close="showOpenOrdersModal = false" @status-updated="dashboardStore.fetchData" />

    <DelayedOrdersModal
      :show="showDelayedOrdersModal"
      :orders="delayedOrdersList"
      @close="showDelayedOrdersModal = false"
      @refresh="dashboardStore.fetchData"
      @view-details="(item) => openEditOrder(item)"
    />

    <v-dialog v-model="showKpiDetailModal" max-width="900px">
      <v-card class="rounded-xl border-thin card-3d overflow-hidden" :class="isLight ? 'bg-white' : 'glass-card'">
        <v-toolbar color="indigo-darken-3" class="border-b px-2 text-white">
          <v-toolbar-title class="font-weight-black text-h6 text-uppercase pl-2">{{ modalTitle }}</v-toolbar-title>
          <v-btn icon="mdi-close" class="btn-3d" @click="showKpiDetailModal = false" variant="text" color="white"></v-btn>
        </v-toolbar>

        <v-card-text class="pa-0">
           <div class="grid-scroll flex-grow-1 overflow-auto custom-scroll relative" style="max-height: 60vh;">
               <div class="grid-header sticky-head border-b" :class="isLight ? 'grid-surface-light' : 'grid-surface-dark'" style="grid-template-columns: minmax(200px, 1.5fr) minmax(150px, 1fr) 120px 100px 120px;">
                   <div class="cell header-text border-r pl-4">Cliente</div>
                   <div class="cell header-text border-r">Vendedor</div>
                   <div class="cell center header-text border-r">Item</div>
                   <div class="cell right header-text border-r">Metragem</div>
                   <div class="cell center header-text">Status</div>
               </div>
               <div v-for="(item, idx) in modalItems" :key="idx" class="grid-row border-b transition-all" :class="[isLight ? 'grid-row-light' : 'grid-row-dark', zebraClass(idx)]" style="grid-template-columns: minmax(200px, 1.5fr) minmax(150px, 1fr) 120px 100px 120px;">
                   <div class="cell pl-4 border-r">
                       <span class="text-truncate list-text font-weight-black text-uppercase">{{ item.customer_name }}</span>
                   </div>
                   <div class="cell border-r">
                       <span class="text-truncate list-text font-weight-bold text-uppercase opacity-80">{{ item.creator_name || 'Vendedor' }}</span>
                   </div>
                   <div class="cell center border-r">
                       <span class="list-text font-weight-bold">{{ item.stamp_ref || '-' }}</span>
                   </div>
                   <div class="cell right border-r pr-4">
                       <span class="font-weight-black font-mono list-text">{{ formatNumber(item.quantity_meters) }}m</span>
                   </div>
                   <div class="cell center">
                       <v-chip :color="getStatusColor(item.status)" size="small" variant="flat" class="font-weight-black text-uppercase text-white chip-3d" style="width: 90px; justify-content: center;">
                           {{ getStatusText(item.status) }}
                       </v-chip>
                   </div>
               </div>
           </div>
        </v-card-text>
      </v-card>
    </v-dialog>

    <v-snackbar v-model="snackbar.show" :color="snackbar.color" :timeout="4000" location="top center" content-class="font-weight-bold elevation-10 rounded-lg"><v-icon start>mdi-information</v-icon>{{ snackbar.text }}</v-snackbar>
  </v-container>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onActivated, defineAsyncComponent, reactive, onUnmounted } from 'vue';
import { useDashboardStore } from '@/stores/dashboard';
import { useThemeStore } from '@/stores/theme';
import { useAppStore } from '@/stores/app';
import { storeToRefs } from 'pinia';
import { format, startOfMonth, endOfMonth, startOfWeek, endOfWeek, startOfDay, endOfDay, isWithinInterval, parseISO, addMonths, isSameDay, setDate, differenceInCalendarDays, startOfYear, endOfYear, getMonth, isBefore, startOfToday, addDays } from 'date-fns';
import { ptBR } from 'date-fns/locale';
import { Chart as ChartJS, Title, Tooltip, Legend, ArcElement, CategoryScale, LineElement, LinearScale, PointElement, BarElement, Filler } from 'chart.js';
import { supabase } from '@/api/supabase';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import { useOrderPDF } from '@/composables/useOrderPDF';
import DeliveryCalendar from '@/components/dashboards/DeliveryCalendar.vue';

ChartJS.register(Title, Tooltip, Legend, ArcElement, CategoryScale, LineElement, LinearScale, PointElement, BarElement, Filler);

// Components
const OrderDetailModal = defineAsyncComponent(() => import('@/components/OrderDetailModal.vue'));
const ApprovalWarningModal = defineAsyncComponent(() => import('@/components/admin/ApprovalWarningModal.vue'));
const ReportSettingsModal = defineAsyncComponent(() => import('@/components/admin/ReportSettingsModal.vue'));
const OpenOrdersModal = defineAsyncComponent(() => import('@/components/admin/OpenOrdersModal.vue'));
const DelayedOrdersModal = defineAsyncComponent(() => import('@/components/dashboards/DelayedOrdersModal.vue'));

const Doughnut = defineAsyncComponent(() => import('vue-chartjs').then(c => c.Doughnut));
const Bar = defineAsyncComponent(() => import('vue-chartjs').then(c => c.Bar));

const themeStore = useThemeStore();
const dashboardStore = useDashboardStore();
const appStore = useAppStore();
const { generateReadyDeliveryReceiptPdf } = useOrderPDF();

const { orders: allOrders, ordersPendingApproval, totalMetersPendingApproval, itemsDelayedInDesign, completedOrders, deliveredOrders, salesBySeller, salesByFabric, designItemsStatus, monthlyProduction, delayedDesignItemsDetails, totalMetersInDesign, allDesignItemsDetails, monthlySalesPerformance } = storeToRefs(dashboardStore);

// Themes
const isLight = computed(() => themeStore.currentMode === 'light');
const isGlass = computed(() => themeStore.currentMode === 'glass');
const panelClasses = computed(() => isLight.value ? 'light-panel bg-white' : (isGlass.value ? 'glass-card' : 'dark-panel bg-grey-darken-4'));
const chartTextColor = computed(() => isLight.value ? '#424242' : '#e0e0e0');
const chartGridColor = computed(() => isLight.value ? 'rgba(0,0,0,0.05)' : 'rgba(255,255,255,0.05)');

// State
const showDetailModal = ref(false);
const selectedOrder = ref<any | null>(null);
const showApprovalModal = ref(false);
const showReportModal = ref(false);
const showDelayedOrdersModal = ref(false);
const search = ref('');
const filterType = ref('current_month');
const mainTab = ref('list');
const snackbar = reactive({ show: false, text: '', color: '' });
const isGeneratingPdf = ref(false);
const showOpenOrdersModal = ref(false);
const modalOrderList = ref<any[]>([]);
const modalTitle = ref('');
const modalColor = ref('primary');
const showKpiDetailModal = ref(false);
const modalItems = ref<any[]>([]);
const orderChartPeriod = ref<'month' | 'year'>('month');
const reportDialog = reactive({ show: false, type: 'delayed', startDate: format(startOfMonth(new Date()), 'yyyy-MM-dd'), endDate: format(endOfMonth(new Date()), 'yyyy-MM-dd') });

// Clock
const currentTime = ref('');
const currentDate = ref('');
const lastSyncTime = ref('');
let clockInterval: NodeJS.Timeout;
const updateClock = () => { const now = new Date(); currentTime.value = format(now, 'HH:mm:ss'); currentDate.value = format(now, "EEE, d MMM yyyy", { locale: ptBR }); };

// --- LÓGICA DE DATAS E STATUS ---
const closedStatuses = ['delivered', 'completed', 'cancelled', 'ready_for_delivery'];

const getNextDeliveryDay = (date: Date): Date => {
  const newDate = new Date(date);
  while (true) {
    const dayOfWeek = newDate.getDay();
    if ([2, 4, 6].includes(dayOfWeek)) return newDate;
    newDate.setDate(newDate.getDate() + 1);
  }
};

const calculateDeliveryDate = (orderDateStr: string) => {
    if (!orderDateStr) return null;
    try {
        const start = parseISO(orderDateStr);
        const baseDate = addDays(start, 8);
        return getNextDeliveryDay(baseDate);
    } catch (e) { return null; }
};

const getDeliveryInfo = (orderDateStr: string) => {
    const deliveryDate = calculateDeliveryDate(orderDateStr);
    if (!deliveryDate) return { dateStr: '--/--', daysDiff: null, fullDate: null };
    const now = new Date(); now.setHours(0,0,0,0);
    const deliveryMidnight = new Date(deliveryDate); deliveryMidnight.setHours(0,0,0,0);
    const diff = differenceInCalendarDays(deliveryMidnight, now);
    return { dateStr: format(deliveryDate, 'dd/MM/yyyy'), daysDiff: diff, fullDate: deliveryDate };
};

const processedOrders = computed(() => {
    return allOrders.value.map(o => {
        const dInfo = getDeliveryInfo(o.created_at);
        return { ...o, delivery_date_obj: dInfo.fullDate };
    });
});

const delayedOrdersList = computed(() => {
    const now = new Date(); now.setHours(0,0,0,0);
    return processedOrders.value.filter(o => {
        if (closedStatuses.includes(o.status)) return false;
        if (o.delivery_date_obj && o.delivery_date_obj < now) return true;
        return false;
    });
});

// --- ACTIONS ---
const openEditOrder = (order: any) => { selectedOrder.value = order; showDetailModal.value = true; };
const cancelOrder = async (item: any) => { if(confirm(`Cancelar pedido #${item.order_number}?`)) { await supabase.from('orders').update({ status: 'cancelled' }).eq('id', item.id); dashboardStore.fetchData(); } };
const printReceipt = async (order: any) => {
    try {
        const { data: items } = await supabase.from('order_items').select('*').eq('order_id', order.id);
        const client = { nome: order.customer_name, cpf_cnpj: '' };
        await generateReadyDeliveryReceiptPdf(order.order_number, client, order.total_value, 'Reimpressão', items || []);
    } catch(e) { console.error(e); }
};

// --- CHARTS & KPIS ---
const ordersVolumeChartData = computed(() => {
    const period = orderChartPeriod.value;
    const now = new Date();
    let labels: string[] = [];
    let dataValues: number[] = [];
    if (period === 'year') {
        const start = startOfYear(now); const end = endOfYear(now);
        labels = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez']; dataValues = Array(12).fill(0);
        allOrders.value.forEach(o => { const date = parseISO(o.created_at); if (date >= start && date <= end) { dataValues[getMonth(date)]++; } });
    } else {
        const start = startOfMonth(now); const end = endOfMonth(now); const daysInMonth = end.getDate();
        labels = Array.from({length: daysInMonth}, (_, i) => String(i + 1)); dataValues = Array(daysInMonth).fill(0);
        allOrders.value.forEach(o => { const date = parseISO(o.created_at); if (date >= start && date <= end) { dataValues[date.getDate() - 1]++; } });
    }
    return { labels, datasets: [{ label: 'Total Pedidos', backgroundColor: isLight.value ? '#3949AB' : '#29b6f6', borderRadius: 6, data: dataValues, barPercentage: 0.5 }] };
});

const orderChartOptions = computed(() => ({ responsive: true, maintainAspectRatio: false, plugins: { legend: { display: false }, tooltip: { backgroundColor: isLight.value ? 'rgba(255,255,255,0.95)' : 'rgba(20, 20, 25, 0.95)', titleColor: isLight.value ? '#000' : '#fff', bodyColor: isLight.value ? '#333' : '#e0e0e0', borderColor: isLight.value ? 'rgba(0,0,0,0.1)' : 'rgba(255,255,255,0.1)', borderWidth: 1, padding: 12, titleFont: { size: 14, family: 'Montserrat, sans-serif' }, bodyFont: { size: 13, family: 'Montserrat, sans-serif' } } }, scales: { y: { grid: { color: chartGridColor.value, borderDash: [4, 4] }, ticks: { color: isLight.value ? '#757575' : '#9e9e9e', font: { family: 'Montserrat, sans-serif' } } }, x: { grid: { display: false }, ticks: { color: chartTextColor.value, font: { weight: 'bold', family: 'Montserrat, sans-serif' } } } } }));

// --- PDF GENERATION ---
const openReportDialog = () => { reportDialog.show = true; };
const imageToBase64 = (url: string): Promise<string> => new Promise((resolve, reject) => { const img = new Image(); img.crossOrigin = 'Anonymous'; img.onload = () => { const canvas = document.createElement('canvas'); canvas.width = img.width; canvas.height = img.height; const ctx = canvas.getContext('2d'); if (ctx) { ctx.drawImage(img, 0, 0); resolve(canvas.toDataURL('image/png')); } else reject(new Error('Canvas error')); }; img.onerror = reject; img.src = url; });

const generateCustomReport = async () => {
    isGeneratingPdf.value = true;
    try {
        const doc = new jsPDF({ orientation: 'p', unit: 'mm', format: 'a4' });
        const pageWidth = doc.internal.pageSize.width; const pageHeight = doc.internal.pageSize.height;
        const startDate = parseISO(reportDialog.startDate); const endDate = parseISO(reportDialog.endDate); endDate.setHours(23, 59, 59, 999);
        let targetOrders = processedOrders.value.filter(o => { const date = parseISO(o.created_at); return date >= startDate && date <= endDate; });

        if (reportDialog.type === 'delayed') {
            const now = new Date(); now.setHours(0,0,0,0);
            targetOrders = targetOrders.filter(o => !closedStatuses.includes(o.status) && o.delivery_date_obj && o.delivery_date_obj < now);
        } else if (reportDialog.type === 'delivered') {
            targetOrders = targetOrders.filter(o => ['completed', 'delivered'].includes(o.status));
        }

        try { const logoUrl = 'https://cdn.shopify.com/s/files/1/0661/4574/6991/files/Sem_nome_1080_x_800_px_1080_x_500_px_1080_x_400_px_1000_x_380_px_da020cf2-2bb9-4dac-8dd3-4548cfd2e5ae.png?v=1756811713'; const logoBase64 = await imageToBase64(logoUrl); doc.addImage(logoBase64, 'PNG', 15, 10, 45, (doc.getImageProperties(logoBase64).height * 45) / doc.getImageProperties(logoBase64).width); } catch (e) {}
        doc.setFontSize(8).setTextColor(50); const headerText = ["MR JACKY CONFECCOES LTDA", "CNPJ: 20.631.721/0001-07", "Rua Luiz Montanhan, 1302 - Tiete/SP", "Contato: (15) 99847-8789 | financeiro@mrjacky.com"]; doc.text(headerText, pageWidth - 15, 15, { align: 'right' });
        doc.setDrawColor(200, 200, 200); doc.line(15, 30, pageWidth - 15, 30);
        doc.setFontSize(14).setFont('helvetica', 'bold').setTextColor(0); doc.text('Relatório de Pedidos', 15, 40);
        doc.setFontSize(9).setFont('helvetica', 'normal').setTextColor(100); doc.text(`Período: ${format(startDate, 'dd/MM/yyyy')} a ${format(endDate, 'dd/MM/yyyy')} | Tipo: ${reportDialog.type.toUpperCase()}`, 15, 45);

        const totalMet = targetOrders.reduce((acc, o) => acc + (Number(o.quantity_meters) || 0), 0);
        let kpiX = 15; const drawKPI = (label: string, value: string, valueColor: [number, number, number] = [0,0,0]) => { doc.setFillColor(255, 255, 255); doc.setDrawColor(200, 200, 200); doc.roundedRect(kpiX, 50, 45, 12, 2, 2, 'FD'); doc.setFontSize(7).setTextColor(100); doc.text(label, kpiX + 3, 54); doc.setFontSize(10).setFont('helvetica', 'bold').setTextColor(valueColor[0], valueColor[1], valueColor[2]); doc.text(value, kpiX + 3, 59); kpiX += 48; };
        drawKPI("Total Registros", `${targetOrders.length}`, [0, 0, 0]); drawKPI("Volume (Metros)", `${formatNumber(totalMet)}m`, [0, 100, 0]);

        const columns = [{ header: 'Pedido', dataKey: 'id' }, { header: 'Emissão', dataKey: 'date' }, { header: 'Cliente', dataKey: 'client' }, { header: 'Metros', dataKey: 'meters' }, { header: 'Entrega Est.', dataKey: 'delivery' }, { header: 'Status', dataKey: 'status' }];
        const now = new Date(); now.setHours(0,0,0,0);
        const tableBody = targetOrders.map(order => {
             const dInfo = getDeliveryInfo(order.created_at);
             const isClosed = closedStatuses.includes(order.status);
             const statusRaw = getStatusText(order.status);
             const statusText = isClosed ? statusRaw : "EM ABERTO";
             let rowColor = [255, 255, 255];
             if (order.delivery_date_obj && !isClosed) {
                 if (order.delivery_date_obj < now) rowColor = [255, 205, 210];
                 else if (isSameDay(order.delivery_date_obj, now)) rowColor = [255, 224, 178];
             }
             return { id: `#${String(order.order_number).padStart(4, '0')}`, date: formatDate(order.created_at), client: order.customer_name?.substring(0, 25) || 'Consumidor', meters: `${formatNumber(order.quantity_meters || 0)}m`, delivery: dInfo.dateStr || '--', status: statusText, _rowColor: rowColor };
        });

        autoTable(doc, { startY: 70, columns: columns, body: tableBody, theme: 'grid', headStyles: { fillColor: [50, 50, 50], textColor: 255, fontStyle: 'bold', fontSize: 8 }, bodyStyles: { fontSize: 8, textColor: 50, cellPadding: 2 }, columnStyles: { id: { fontStyle: 'bold', cellWidth: 18 }, client: { cellWidth: 'auto' }, meters: { halign: 'center', cellWidth: 15 }, delivery: { halign: 'center', cellWidth: 20 }, status: { halign: 'center', cellWidth: 30, fontStyle: 'bold' } }, didParseCell: (data) => { if (data.section === 'body') { const row = data.row.raw as any; if (row._rowColor) { data.cell.styles.fillColor = row._rowColor as [number, number, number]; } } }, didDrawPage: (data) => { const str = `Gerado via MJProcess`; doc.setFontSize(8).setTextColor(150); doc.text(str, pageWidth / 2, pageHeight - 10, { align: 'center' }); } });
        doc.save(`Relatorio_${reportDialog.type}_${format(new Date(), 'yyyyMMdd')}.pdf`);
        appStore.showSnackbar("Relatório gerado!", "success"); reportDialog.show = false;
    } catch (e) { appStore.showSnackbar("Erro ao gerar PDF", "error"); } finally { isGeneratingPdf.value = false; }
};

// Helpers
const openKpiDetailModal = (type: string) => { if (type === 'delayed') { modalTitle.value = 'Itens Atrasados no Design'; modalItems.value = delayedDesignItemsDetails.value; } else if (type === 'design') { modalTitle.value = 'Fila Geral de Design'; modalItems.value = allDesignItemsDetails.value; } showKpiDetailModal.value = true; };
const openModal = (title: string, orders: any[], color: string = 'primary') => { modalTitle.value = title; modalColor.value = color; modalOrderList.value = (title === 'Pedidos Entregues') ? filteredDeliveredOrders.value : orders; showOpenOrdersModal.value = true; };
const filteredDeliveredOrders = computed(() => { const now = new Date(); const baseList = deliveredOrders.value; let range; switch (filterType.value) { case 'today': range = { start: startOfDay(now), end: endOfDay(now) }; break; case 'current_week': range = { start: startOfWeek(now, { weekStartsOn: 1 }), end: endOfWeek(now, { weekStartsOn: 1 }) }; break; case 'current_month': default: range = { start: startOfMonth(now), end: endOfMonth(now) }; break; } return baseList.filter(o => o.delivery_confirmed_at && isWithinInterval(parseISO(o.delivery_confirmed_at), range)); });
const totalMetersDelivered = computed(() => filteredDeliveredOrders.value.reduce((sum, order) => sum + (Number(order.quantity_meters) || 0), 0));

const filteredOrders = computed(() => {
    const now = new Date();
    let baseList = allOrders.value;
    switch (filterType.value) {
        case 'today': baseList = baseList.filter(o => isWithinInterval(parseISO(o.created_at), { start: startOfDay(now), end: endOfDay(now) })); break;
        case 'current_week': baseList = baseList.filter(o => isWithinInterval(parseISO(o.created_at), { start: startOfWeek(now, { weekStartsOn: 1 }), end: endOfWeek(now, { weekStartsOn: 1 }) })); break;
        case 'billing': baseList = completedOrders.value; break;
        case 'delivered': baseList = deliveredOrders.value; break;
        case 'delayed': baseList = delayedOrdersList.value; break;
        case 'all': break;
        default: baseList = baseList.filter(o => isWithinInterval(parseISO(o.created_at), { start: startOfMonth(now), end: endOfMonth(now) })); break;
    }
    if (search.value) {
        const s = search.value.toLowerCase();
        baseList = baseList.filter(o => String(o.order_number).includes(s) || o.customer_name?.toLowerCase().includes(s));
    }

    // Sort: newest first
    return baseList.sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime());
});

const productionOrders = computed(() => allOrders.value.filter(o => ['production_queue', 'in_printing', 'in_cutting'].includes(o.status)));
const productionOrdersMeters = computed(() => productionOrders.value.reduce((sum, order) => sum + (Number(order.quantity_meters) || 0), 0));
const allOpenOrders = computed(() => [ ...allOrders.value.filter(o => ['design_pending', 'customer_approval', 'changes_requested', 'approved_by_seller'].includes(o.status)), ...productionOrders.value, ...completedOrders.value ]);
const totalMetersOpen = computed(() => allOpenOrders.value.reduce((sum, order) => sum + (Number(order.quantity_meters) || 0), 0));

const formatNumber = (value: number) => Number(value || 0).toLocaleString('pt-BR', { maximumFractionDigits: 0 });
const formatDate = (dateString: string | null) => dateString ? format(new Date(dateString), 'dd/MM/yyyy', { locale: ptBR }) : '-';

const getStatusColor = (status: string) => { switch(status) { case 'design_pending': return 'blue-grey'; case 'customer_approval': return 'orange-darken-2'; case 'production_queue': return 'grey-darken-2'; case 'completed': return 'success'; case 'delivered': return 'info'; default: return 'grey'; }};
const getStatusText = (status: string) => { switch(status) { case 'design_pending': return 'No Design'; case 'customer_approval': return 'Aprovação'; case 'production_queue': return 'Fila Produção'; case 'completed': return 'Aguard. Fat.'; case 'delivered': return 'Entregue'; default: return status; }};

const sellerList = computed(() => [...new Set(allOrders.value.map(o => o.creator?.full_name).filter(Boolean))]);
const clientList = computed(() => [...new Set(allOrders.value.map(o => o.customer_name).filter(Boolean))]);
const fabricList = computed(() => { const fabrics = new Set<string>(); allOrders.value.forEach(order => { if (order.is_launch) order.order_items.forEach(item => fabrics.add(item.fabric_type)); else if (order.details?.fabric_type) fabrics.add(order.details.fabric_type); }); return Array.from(fabrics); });

// Component Headers for Modals
const modalHeaders = [{ title: 'Cliente', key: 'customer_name' }, { title: 'Vendedor', key: 'creator_name' }, { title: 'Item', key: 'stamp_ref' }, { title: 'Metragem', key: 'quantity_meters' }, { title: 'Status', key: 'status' }];

// Grid Helper
const zebraClass = (i:number) => themeStore.currentMode!=='light' ? (i%2===0?'zebra-dark-a':'zebra-dark-b') : (i%2===0?'zebra-light-a':'zebra-light-b');

// Lifecycle
onActivated(async () => { await dashboardStore.fetchData(); lastSyncTime.value = format(new Date(), 'HH:mm'); });
onMounted(async () => { updateClock(); clockInterval = setInterval(updateClock, 1000); await dashboardStore.fetchData(); lastSyncTime.value = format(new Date(), 'HH:mm'); });
onUnmounted(() => { clearInterval(clockInterval); });
</script>

<style scoped lang="scss">
/* Animations */
.animate-fade-in-down { animation: fadeInDown 0.7s cubic-bezier(0.2, 0.8, 0.2, 1); }
.animate-fade-in-up { animation: fadeInUp 0.7s cubic-bezier(0.2, 0.8, 0.2, 1) backwards; }
@keyframes fadeInDown { from { opacity: 0; transform: translateY(-30px); } to { opacity: 1; transform: translateY(0); } }
@keyframes fadeInUp { from { opacity: 0; transform: translateY(30px); } to { opacity: 1; transform: translateY(0); } }
.blink { animation: blink 2s infinite; }
@keyframes blink { 0% { opacity: 1; } 50% { opacity: 0.4; } 100% { opacity: 1; } }

/* ========================================================
   EFEITOS 3D E BORDAS / BUTTONS E CARDS
   ======================================================== */

.btn-3d {
    border-radius: 6px !important;
    box-shadow: 0 3px 5px rgba(0,0,0,0.15), inset 0 2px 0 rgba(255,255,255,0.25) !important;
    transition: transform 0.1s ease, box-shadow 0.1s ease;
    text-transform: none !important;
    font-weight: 700;
    letter-spacing: 0.5px;
}
.btn-3d:active {
    transform: translateY(2px);
    box-shadow: 0 1px 2px rgba(0,0,0,0.15), inset 0 1px 0 rgba(255,255,255,0.2) !important;
}

.chip-3d {
    border-radius: 6px !important;
    box-shadow: 0 3px 5px rgba(0,0,0,0.12), inset 0 1px 0 rgba(255,255,255,0.25) !important;
    text-shadow: 0 1px 2px rgba(0,0,0,0.25);
}

.card-3d {
    border-radius: 12px !important;
    box-shadow: 0 6px 12px rgba(0,0,0,0.15), inset 0 2px 0 rgba(255,255,255,0.2) !important;
    transition: transform 0.2s ease, box-shadow 0.2s ease;
}

.square-btn { width: 32px !important; height: 32px !important; min-width: 32px !important; padding: 0 !important; }
.ui-field :deep(.v-field) { border-radius: 8px !important; }

/* Campos de Busca e Filtros */
.search-wrap { height: 40px; padding: 0 12px; display: flex; align-items: center; flex: 1; border-radius: 8px; }
.search-light { background: #f4f6f8; border: 1px solid rgba(0,0,0,0.08); }
.search-light:focus-within { border-color: #3f51b5; box-shadow: 0 0 0 2px rgba(63,81,181,0.1); }
.search-dark { background: rgba(255,255,255,0.08); border: 1px solid rgba(255,255,255,0.10); }
.search-dark:focus-within { border-color: rgba(255,255,255,0.3); background: rgba(255,255,255,0.08); }
.clean-input { border: none; outline: none; flex: 1; font-size: 13px; background: transparent; color: inherit; }

/* Theme Styles */
.glass-card { background: rgba(30, 30, 35, 0.85); backdrop-filter: blur(25px); color: white; }
.light-panel { background: #FFFFFF; border: 1px solid #E0E0E0; box-shadow: 0 4px 12px rgba(0,0,0,0.05); }

.bg-gradient-primary { background: linear-gradient(135deg, #1976d2, #0d47a1); }
.bg-surface-darker { background: rgba(0, 0, 0, 0.25) !important; }

/* KPI Cards 3D */
.kpi-card-3d {
    height: 120px;
    border-radius: 12px !important;
    padding: 20px;
    position: relative;
    overflow: hidden;
    border: 1px solid rgba(255,255,255,0.1);
    cursor: pointer;
    color: white;
    display: flex;
    flex-direction: column;
    box-shadow: 0 6px 12px rgba(0,0,0,0.2), inset 0 2px 0 rgba(255,255,255,0.3) !important;
    transition: transform 0.2s ease, box-shadow 0.2s ease, filter 0.2s ease;
}
.kpi-card-3d:hover {
    transform: translateY(-4px);
    box-shadow: 0 12px 24px rgba(0,0,0,0.3), inset 0 2px 0 rgba(255,255,255,0.4) !important;
    filter: brightness(1.05);
    z-index: 2;
}
.kpi-bg-icon { position: absolute; right: -15px; bottom: -15px; opacity: 0.15; transform: rotate(-20deg); pointer-events: none; }
.kpi-bg-icon .v-icon { font-size: 110px; color: white; }
.kpi-label { font-size: 0.75rem; font-weight: 800; text-transform: uppercase; letter-spacing: 1px; opacity: 0.9; margin-bottom: 4px; }
.kpi-number-group { display: flex; align-items: baseline; line-height: 1; margin-bottom: 8px; }
.kpi-value { font-size: 2.5rem; font-weight: 900; }
.kpi-unit { font-size: 0.85rem; font-weight: 700; opacity: 0.7; margin-left: 6px; text-transform: uppercase;}
.kpi-footer { font-size: 0.70rem; font-family: monospace; background: rgba(0,0,0,0.2); padding: 4px 8px; border-radius: 6px; width: fit-content; font-weight: bold;}

/* Grids e Custom Scroll - ESTILO RECEIVABLES */
.grid-scroll { scrollbar-gutter: stable both-edges; -webkit-overflow-scrolling: touch; }
.custom-scroll::-webkit-scrollbar { width: 8px; height: 8px; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.35); border-radius: 6px; }
.custom-scroll::-webkit-scrollbar-track { background: transparent; }

.grid-header, .grid-row {
    display: grid;
    align-items: stretch;
    width: 100%;
    min-width: 1100px;
}

.cell {
    padding: 8px 12px;
    display: flex;
    align-items: center;
    border-right: 1px solid rgba(0,0,0,0.08);
    border-bottom: 1px solid rgba(0,0,0,0.08);
    min-height: 56px;
    overflow: visible;
}
.cell:last-child { border-right: none !important; }

.header-text { font-size: 11px !important; font-weight: 900; text-transform: uppercase; letter-spacing: 0.5px; line-height: 1.2; opacity: 0.9;}
.center { justify-content: center; text-align: center; }
.right { justify-content: flex-end; text-align: right; }
.list-text { font-size: 13px !important; line-height: 1.3 !important; }

.grid-surface-light .cell { background: #f5f7fa; color: #555; border-color: rgba(0,0,0,0.06); }
.grid-surface-dark .cell { background: rgba(255,255,255,0.04); color: #ccc; border-color: rgba(255,255,255,0.05); }
.grid-row-light .cell { background: #fff; border-color: rgba(0,0,0,0.06); }
.grid-row-dark .cell { background: rgba(255,255,255,0.02); border-color: rgba(255,255,255,0.05); }

.zebra-light-a .cell { background: #fff; }
.zebra-light-b .cell { background: #f9f9f9; }
.zebra-dark-a .cell { background: rgba(255,255,255,0.01); }
.zebra-dark-b .cell { background: rgba(255,255,255,0.03); }

.hover-lift-row:hover .cell {
    background-color: rgba(63, 81, 181, 0.05) !important;
}

/* Tabs */
.tabs-pill-container { border: 1px solid rgba(255,255,255,0.1); display: inline-flex; }
.light-mode-container .tabs-pill-container { border: 1px solid #E0E0E0; }
.tab-pill { padding: 8px 24px; border-radius: 50px; color: #aaa; font-size: 0.9rem; cursor: pointer; transition: 0.3s; display: flex; align-items: center; }
.tab-pill:hover { color: white; background: rgba(255,255,255,0.05); }
.tab-pill.active { background: rgba(63, 81, 181, 0.15); color: #3949AB; border: 1px solid rgba(63, 81, 181, 0.3); box-shadow: 0 0 15px rgba(63, 81, 181, 0.2); }
.tab-pill.light-active { background: #FFFFFF; color: #3949AB; border: 1px solid #E0E0E0; box-shadow: 0 2px 6px rgba(0,0,0,0.05); }
.light-mode-container .tab-pill { color: #616161; }
.light-mode-container .tab-pill:hover { background: rgba(0,0,0,0.05); color: #424242; }

.custom-chip-group .v-chip--selected { box-shadow: 0 0 10px rgba(var(--v-theme-indigo), 0.4); }
.glow-chip { box-shadow: 0 0 8px rgba(63, 81, 181, 0.5); }

/* Auxiliares */
.icon-box-lg { width: 56px; height: 56px; }
.icon-box-sm { width: 36px; height: 36px; display: flex; align-items: center; justify-content: center; }
.status-dot { width: 8px; height: 8px; border-radius: 50%; }
.font-mono { font-family: 'Roboto Mono', monospace; }
.border-white-05 { border-color: rgba(255,255,255,0.05) !important; }
.border-white-10 { border-color: rgba(255,255,255,0.1) !important; }
.bg-gradient-orange { background: linear-gradient(135deg, #ffa726, #f57c00); }
.bg-gradient-green { background: linear-gradient(135deg, #66bb6a, #2e7d32); }
.bg-gradient-red { background: linear-gradient(135deg, #ef5350, #c62828); }
.bg-gradient-purple { background: linear-gradient(135deg, #ab47bc, #7b1fa2); }
.bg-gradient-cyan { background: linear-gradient(135deg, #26c6da, #00838f); }
.bg-gradient-blue { background: linear-gradient(135deg, #42a5f5, #1565c0); }

/* Tabelas Antigas (Mantido para o modal) */
.premium-table :deep(th) { font-size: 0.7rem !important; text-transform: uppercase; letter-spacing: 1px; color: rgba(255,255,255,0.5) !important; font-weight: 700 !important; }
.premium-table :deep(td) { padding-top: 12px !important; padding-bottom: 12px !important; border-bottom: 1px solid rgba(255,255,255,0.05) !important; }
.premium-table :deep(tr:hover) { background-color: rgba(255,255,255,0.03) !important; }
.light-table :deep(th) { color: #757575 !important; border-bottom: 1px solid #EEEEEE !important; }
.light-table :deep(td) { border-bottom: 1px solid #F5F5F5 !important; color: #424242 !important; }
.light-table :deep(tr:hover) { background-color: #FAFAFA !important; }

/* Global Tooltip Override for Light Mode */
:global(.tooltip-contrast > .v-overlay__content) {
    background-color: #212121 !important;
    color: white !important;
    font-weight: 600 !important;
    font-size: 0.75rem !important;
    padding: 6px 12px !important;
    border-radius: 6px !important;
}
</style>
