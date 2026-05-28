<template>
  <v-container fluid class="admin-dashboard-container pa-6" :class="{ 'light-mode-container': themeStore.currentMode === 'light' }">

    <div class="header-section mb-6 animate-fade-in-down">
      <div class="d-flex flex-column flex-md-row justify-space-between align-md-center ga-4">

        <div class="d-flex align-center">
          <div
            class="icon-box-lg mr-4 elevation-10 rounded-xl d-flex align-center justify-center glow-effect"
            :class="themeStore.currentMode === 'light' ? 'bg-grey-darken-4 text-white' : 'bg-gradient-primary'"
          >
            <v-icon color="white" size="28">mdi-monitor-dashboard</v-icon>
          </div>
          <div>
            <div class="d-flex align-center text-caption font-weight-bold mb-1 opacity-70" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-2' : 'text-white'">
              <span class="mr-2">MJ PROCESS</span>
              <v-icon size="x-small" class="mr-2">mdi-chevron-right</v-icon>
              <span>DASHBOARD</span>
            </div>
            <h1 class="text-h4 font-weight-black" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white text-gradient'">
              Visão Geral
            </h1>
          </div>
        </div>

        <div
          class="d-flex align-center px-4 py-2 rounded-lg border-thin"
          :class="themeStore.currentMode === 'light' ? 'bg-white shadow-soft' : 'glass-panel'"
        >
           <div class="text-right mr-4 border-r pr-4" :class="themeStore.currentMode === 'light' ? 'border-grey-lighten-2' : 'border-white-10'">
              <div class="text-h6 font-weight-bold font-mono leading-none" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">
                {{ currentTime }}
              </div>
              <div class="text-caption font-weight-medium text-uppercase" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-1' : 'text-medium-emphasis'">
                {{ currentDate }}
              </div>
           </div>
           <div class="d-flex flex-column align-start">
              <div class="d-flex align-center text-caption font-weight-bold text-success mb-1">
                 <div class="status-dot bg-success mr-2 blink"></div>
                 SISTEMA ONLINE
              </div>
              <div class="text-caption text-medium-emphasis font-mono" style="font-size: 0.7rem;">
                 SYNC: {{ lastSyncTime }}
              </div>
           </div>
        </div>

        <div class="d-flex align-center flex-wrap ga-3">
          <v-btn
            variant="tonal"
            color="success"
            :class="themeStore.currentMode === 'light' ? 'shadow-soft' : 'glass-btn'"
            prepend-icon="mdi-package-variant-closed"
            :loading="isRecheckingStock"
            @click="handleStockRecheck"
            size="small"
            class="font-weight-bold"
          >
            Check Estoque
          </v-btn>

          <v-btn
            to="/admin/crm"
            variant="flat"
            :class="themeStore.currentMode === 'light' ? 'bg-grey-darken-3 text-white' : 'bg-gradient-info text-white font-weight-bold shadow-glow'"
            prepend-icon="mdi-chart-timeline-variant"
            size="small"
          >
            CRM
          </v-btn>

          <v-btn icon density="comfortable" :variant="themeStore.currentMode === 'light' ? 'elevated' : 'tonal'" :color="themeStore.currentMode === 'light' ? 'white' : 'white'" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-2' : 'glass-btn-icon'" @click="showReportModal = true">
            <v-icon>mdi-file-chart-outline</v-icon>
            <v-tooltip activator="parent" location="bottom">Relatórios Avançados</v-tooltip>
          </v-btn>
        </div>
      </div>
    </div>

    <v-row class="mb-4 animate-fade-in-up" style="animation-delay: 0.1s" dense>
      <v-col cols="12" sm="6" md="4" lg="2">
        <v-card class="kpi-card bg-gradient-orange hover-elevate" @click="openModal('Pedidos Pendentes de Aprovação', ordersPendingApproval, 'orange')" v-ripple>
          <div class="kpi-bg-icon"><v-icon>mdi-alert-decagram</v-icon></div>
          <div class="d-flex flex-column position-relative z-10">
            <span class="kpi-label">Aprovação</span>
            <div class="kpi-number-group">
              <span class="kpi-value">{{ ordersPendingApproval.length }}</span>
              <span class="kpi-unit">pedidos</span>
            </div>
            <div class="kpi-footer">{{ formatNumber(totalMetersPendingApproval) }}m pendentes</div>
          </div>
        </v-card>
      </v-col>

      <v-col cols="12" sm="6" md="4" lg="2">
        <v-card class="kpi-card bg-gradient-green hover-elevate" @click="openModal('Pedidos Entregues', filteredDeliveredOrders, 'green-darken-2')" v-ripple>
          <div class="kpi-bg-icon"><v-icon>mdi-truck-check</v-icon></div>
          <div class="d-flex flex-column position-relative z-10">
            <span class="kpi-label">Entregues</span>
            <div class="kpi-number-group">
              <span class="kpi-value">{{ filteredDeliveredOrders.length }}</span>
              <span class="kpi-unit">pedidos</span>
            </div>
            <div class="kpi-footer">{{ formatNumber(totalMetersDelivered) }}m (Filtro)</div>
          </div>
        </v-card>
      </v-col>

      <v-col cols="12" sm="6" md="4" lg="2">
        <v-card class="kpi-card bg-gradient-red hover-elevate" @click="openKpiDetailModal('delayed')" v-ripple>
          <div class="kpi-bg-icon"><v-icon>mdi-clock-alert</v-icon></div>
          <div class="d-flex flex-column position-relative z-10">
            <span class="kpi-label">Atraso Design</span>
            <div class="kpi-number-group">
              <span class="kpi-value">{{ itemsDelayedInDesign.count }}</span>
              <span class="kpi-unit">itens</span>
            </div>
            <div class="kpi-footer">{{ formatNumber(itemsDelayedInDesign.totalMeters) }}m atrasados</div>
          </div>
        </v-card>
      </v-col>

      <v-col cols="12" sm="6" md="4" lg="2">
        <v-card class="kpi-card bg-gradient-purple hover-elevate" @click="openModal('Total de Pedidos em Aberto', allOpenOrders, 'purple-lighten-2')" v-ripple>
          <div class="kpi-bg-icon"><v-icon>mdi-chart-pie</v-icon></div>
          <div class="d-flex flex-column position-relative z-10">
            <span class="kpi-label">Total Aberto</span>
            <div class="kpi-number-group">
              <span class="kpi-value">{{ allOpenOrders.length }}</span>
              <span class="kpi-unit">pedidos</span>
            </div>
            <div class="kpi-footer">{{ formatNumber(totalMetersOpen) }}m na fila</div>
          </div>
        </v-card>
      </v-col>

      <v-col cols="12" sm="6" md="4" lg="2">
        <v-card class="kpi-card bg-gradient-cyan hover-elevate" @click="openModal('Pedidos em Produção', productionOrders, 'cyan-darken-2')" v-ripple>
          <div class="kpi-bg-icon"><v-icon>mdi-factory</v-icon></div>
          <div class="d-flex flex-column position-relative z-10">
            <span class="kpi-label">Produção</span>
            <div class="kpi-number-group">
              <span class="kpi-value">{{ productionOrders.length }}</span>
              <span class="kpi-unit">pedidos</span>
            </div>
            <div class="kpi-footer">{{ formatNumber(productionOrdersMeters) }}m ativos</div>
          </div>
        </v-card>
      </v-col>

      <v-col cols="12" sm="6" md="4" lg="2">
        <v-card class="kpi-card bg-gradient-blue hover-elevate" @click="openKpiDetailModal('design')" v-ripple>
          <div class="kpi-bg-icon"><v-icon>mdi-palette</v-icon></div>
          <div class="d-flex flex-column position-relative z-10">
            <span class="kpi-label">Fila Design</span>
            <div class="kpi-number-group">
              <span class="kpi-value">{{ formatNumber(totalMetersInDesign) }}</span>
              <span class="kpi-unit">metros</span>
            </div>
            <div class="kpi-footer">Aguardando arte</div>
          </div>
        </v-card>
      </v-col>
    </v-row>

    <v-row class="mb-6 animate-fade-in-up" style="animation-delay: 0.15s" dense>
        <v-col cols="12" md="6">
            <v-card
                class="pa-4 rounded-xl border-thin h-100 d-flex flex-column hover-scale-sm transition-all"
                :class="themeStore.currentMode === 'light' ? 'light-panel' : 'glass-panel'"
            >
               <div class="d-flex align-center justify-space-between mb-2">
                  <div class="d-flex align-center cursor-pointer" @click="$router.push({ name: 'FinancialReceivables' })">
                     <v-avatar color="green-lighten-5" class="mr-3 rounded-lg" size="36">
                        <v-icon color="green-darken-1" size="20">mdi-arrow-up-bold</v-icon>
                     </v-avatar>
                     <div>
                        <div class="text-caption font-weight-bold text-uppercase opacity-70">Contas a Receber</div>
                        <div class="d-flex align-center gap-2">
                           <v-btn icon="mdi-chevron-left" size="x-small" variant="text" density="compact" @click.stop="changeFinancialMonth(-1)"></v-btn>
                           <span class="text-body-2 font-weight-bold text-capitalize">{{ formatFinancialMonth }}</span>
                           <v-btn icon="mdi-chevron-right" size="x-small" variant="text" density="compact" @click.stop="changeFinancialMonth(1)"></v-btn>
                        </div>
                     </div>
                  </div>
                  <v-chip color="green" size="small" variant="tonal" class="font-weight-bold">
                     <v-icon start size="x-small">mdi-chart-bar</v-icon> Entrada
                  </v-chip>
               </div>

               <div class="d-flex align-center justify-space-between mt-2 mb-4 px-2">
                  <div>
                     <div class="text-h4 font-weight-black font-mono text-green-accent-3" :class="themeStore.currentMode === 'light' ? 'text-green-darken-2' : ''">
                        {{ formatCurrency(receivablesData.total) }}
                     </div>
                     <div class="text-caption text-medium-emphasis">Previsto para este mês</div>
                  </div>
                  <div class="text-right">
                     <div class="text-caption font-weight-bold text-green">Recebido</div>
                     <div class="text-body-1 font-weight-bold">{{ formatCurrency(receivablesData.received) }}</div>
                  </div>
               </div>

               <div class="financial-chart-wrapper flex-grow-1" style="height: 120px; min-height: 120px;">
                  <Bar :data="receivablesChartData" :options="financialChartOptions('receivable')" />
               </div>

               <div class="d-flex justify-space-between align-center mt-3 pt-3 border-t" :class="themeStore.currentMode === 'light' ? 'border-grey-lighten-3' : 'border-white-05'">
                  <div class="d-flex align-center text-caption text-medium-emphasis">
                     <v-icon size="x-small" color="warning" class="mr-1">mdi-calendar-alert</v-icon>
                     Vence Hoje: <strong class="text-white ml-1" :class="themeStore.currentMode === 'light' ? 'text-black' : ''">{{ formatCurrency(receivablesData.dueToday) }}</strong>
                  </div>
                  <v-btn size="x-small" variant="text" append-icon="mdi-arrow-right" to="/admin/financeiro/recebiveis" class="text-none">Acessar Painel</v-btn>
               </div>
            </v-card>
        </v-col>

        <v-col cols="12" md="6">
            <v-card class="pa-4 rounded-xl border-thin h-100 d-flex flex-column hover-scale-sm transition-all" :class="themeStore.currentMode === 'light' ? 'light-panel' : 'glass-panel'">
               <div class="d-flex align-center justify-space-between mb-2">
                  <div class="d-flex align-center">
                     <v-avatar color="red-lighten-5" class="mr-3 rounded-lg" size="36">
                        <v-icon color="red-darken-1" size="20">mdi-arrow-down-bold</v-icon>
                     </v-avatar>
                     <div>
                        <div class="text-caption font-weight-bold text-uppercase opacity-70">Contas a Pagar</div>
                        <div class="d-flex align-center gap-2">
                           <v-btn icon="mdi-chevron-left" size="x-small" variant="text" density="compact" @click.stop="changeFinancialMonth(-1)"></v-btn>
                           <span class="text-body-2 font-weight-bold text-capitalize">{{ formatFinancialMonth }}</span>
                           <v-btn icon="mdi-chevron-right" size="x-small" variant="text" density="compact" @click.stop="changeFinancialMonth(1)"></v-btn>
                        </div>
                     </div>
                  </div>
                  <v-chip color="red" size="small" variant="tonal" class="font-weight-bold">
                     <v-icon start size="x-small">mdi-chart-bar</v-icon> Saída
                  </v-chip>
               </div>

               <div class="d-flex align-center justify-space-between mt-2 mb-4 px-2">
                  <div>
                     <div class="text-h4 font-weight-black font-mono text-red-accent-2" :class="themeStore.currentMode === 'light' ? 'text-red-darken-2' : ''">
                        {{ formatCurrency(payablesData.total) }}
                     </div>
                     <div class="text-caption text-medium-emphasis">A pagar neste mês</div>
                  </div>
                  <div class="text-right">
                     <div class="text-caption font-weight-bold text-red">Pago</div>
                     <div class="text-body-1 font-weight-bold">{{ formatCurrency(payablesData.paid) }}</div>
                  </div>
               </div>

               <div class="financial-chart-wrapper flex-grow-1" style="height: 120px; min-height: 120px;">
                  <Bar :data="payablesChartData" :options="financialChartOptions('payable')" />
               </div>

               <div class="d-flex justify-space-between align-center mt-3 pt-3 border-t" :class="themeStore.currentMode === 'light' ? 'border-grey-lighten-3' : 'border-white-05'">
                  <div class="d-flex align-center text-caption text-medium-emphasis">
                     <v-icon size="x-small" color="error" class="mr-1">mdi-alert-circle</v-icon>
                     Vence Hoje: <strong class="text-white ml-1" :class="themeStore.currentMode === 'light' ? 'text-black' : ''">{{ formatCurrency(payablesData.dueToday) }}</strong>
                  </div>
                  <v-btn size="x-small" variant="text" append-icon="mdi-arrow-right" disabled>Em Breve</v-btn>
               </div>
            </v-card>
        </v-col>
    </v-row>

    <v-card
      class="rounded-xl mb-8 pa-0 overflow-hidden animate-fade-in-up"
      :class="themeStore.currentMode === 'light' ? 'light-panel' : 'glass-panel'"
      style="animation-delay: 0.2s"
    >
      <div
        class="monthly-hero d-flex flex-column flex-md-row align-center pa-6"
        :class="themeStore.currentMode === 'light' ? 'bg-gradient-dark-blue' : 'bg-gradient-dark-diag'"
      >
        <div class="d-flex align-center flex-grow-1 w-100 justify-space-between justify-md-start">
          <v-btn icon="mdi-chevron-left" variant="tonal" size="small" color="white" class="glass-btn-icon" @click="dashboardStore.previousMonthKpi"></v-btn>
          <div class="text-center mx-8">
            <div class="text-overline font-weight-black letter-spacing-2 mb-n1" :class="themeStore.currentMode === 'light' ? 'text-blue-lighten-3' : 'text-primary'">PRODUÇÃO MENSAL</div>
            <h2 class="text-h4 font-weight-black text-white text-capitalize text-shadow">{{ monthlyProduction.displayMonth }}</h2>
          </div>
          <v-btn icon="mdi-chevron-right" variant="tonal" size="small" color="white" class="glass-btn-icon" @click="dashboardStore.nextMonthKpi"></v-btn>
        </div>

        <v-divider vertical class="mx-8 hidden-sm-and-down border-opacity-10" color="white"></v-divider>
        <v-divider class="my-4 w-100 hidden-md-and-up border-opacity-10" color="white"></v-divider>

        <div class="d-flex align-center justify-center ga-12 pr-md-8">
          <div class="text-center">
            <div class="text-h3 font-weight-black text-white mb-0 text-shadow">{{ monthlyProduction.totalOrders }}</div>
            <div class="text-caption text-uppercase font-weight-bold text-white-50 tracking-wide">Pedidos Finalizados</div>
          </div>
          <div class="text-center">
            <div class="text-h3 font-weight-black text-success mb-0 text-shadow">{{ formatNumber(monthlyProduction.totalMeters) }}<span class="text-h5 text-success">m</span></div>
            <div class="text-caption text-uppercase font-weight-bold text-white-50 tracking-wide">Volume Produzido</div>
          </div>
        </div>
      </div>
    </v-card>

    <v-card
      class="rounded-xl border-thin animate-fade-in-up"
      :class="themeStore.currentMode === 'light' ? 'light-panel' : 'glass-panel'"
      style="animation-delay: 0.3s"
    >

      <div class="d-flex flex-column flex-sm-row align-center justify-space-between px-6 py-4" :class="themeStore.currentMode === 'light' ? 'border-b' : 'border-b border-white-05'">
        <div class="tabs-pill-container rounded-pill pa-1 d-flex" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-4' : 'bg-surface-darker'">
          <div
            class="tab-pill"
            :class="{ active: mainTab === 'list', 'light-active': themeStore.currentMode === 'light' && mainTab === 'list' }"
            @click="mainTab = 'list'"
          >
            <v-icon size="small" class="mr-2">mdi-format-list-bulleted-square</v-icon>
            Lista de Pedidos
          </div>
          <div
            class="tab-pill"
            :class="{ active: mainTab === 'charts', 'light-active': themeStore.currentMode === 'light' && mainTab === 'charts' }"
            @click="mainTab = 'charts'"
          >
            <v-icon size="small" class="mr-2">mdi-chart-box</v-icon>
            Analytics & Gráficos
          </div>
        </div>

        <div class="d-flex align-center mt-4 mt-sm-0 w-100 w-sm-auto" v-if="mainTab === 'list'">
           <v-text-field
            v-model="search"
            prepend-inner-icon="mdi-magnify"
            placeholder="Buscar pedido, cliente, ID..."
            variant="solo"
            density="compact"
            hide-details
            class="search-field-glass"
            style="min-width: 300px"
            :bg-color="themeStore.currentMode === 'light' ? 'grey-lighten-4' : 'rgba(0,0,0,0.2)'"
            :class="themeStore.currentMode === 'light' ? 'text-grey-darken-3' : 'text-white'"
           ></v-text-field>
        </div>
      </div>

      <v-window v-model="mainTab" class="pa-0">

        <v-window-item value="list">
          <div class="filter-toolbar px-6 py-3 d-flex flex-wrap align-center ga-3" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 border-b' : 'bg-surface-darker border-b border-white-05'">
            <v-icon size="small" color="primary">mdi-filter-variant</v-icon>
            <span class="text-caption font-weight-bold text-uppercase mr-1" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-2' : 'text-medium-emphasis'">Período:</span>

            <v-chip-group v-model="filterType" mandatory selected-class="text-white bg-primary glow-chip" class="custom-chip-group">
              <v-chip value="today" size="small" :variant="themeStore.currentMode === 'light' ? 'flat' : 'outlined'" class="font-weight-bold" :class="themeStore.currentMode === 'light' ? 'bg-white' : ''">Hoje</v-chip>
              <v-chip value="current_week" size="small" :variant="themeStore.currentMode === 'light' ? 'flat' : 'outlined'" class="font-weight-bold" :class="themeStore.currentMode === 'light' ? 'bg-white' : ''">Esta Semana</v-chip>
              <v-chip value="current_month" size="small" :variant="themeStore.currentMode === 'light' ? 'flat' : 'outlined'" class="font-weight-bold" :class="themeStore.currentMode === 'light' ? 'bg-white' : ''">Este Mês</v-chip>
            </v-chip-group>

            <div class="vertical-divider mx-2" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-2' : ''"></div>

            <span class="text-caption font-weight-bold text-uppercase mr-1" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-2' : 'text-medium-emphasis'">Status:</span>
            <v-chip-group v-model="filterType" selected-class="ring-2 ring-white" class="custom-chip-group">
               <v-chip value="billing" size="small" color="success" variant="flat" class="font-weight-bold text-white">Aguard. Faturamento</v-chip>
               <v-chip value="delivered" size="small" color="info" variant="flat" class="font-weight-bold text-white">Entregues</v-chip>
            </v-chip-group>

            <v-spacer></v-spacer>

            <div class="stats-badge d-flex align-center text-caption font-weight-bold px-3 py-1 rounded-lg border" :class="themeStore.currentMode === 'light' ? 'bg-white text-grey-darken-3 border-grey-lighten-2' : 'bg-surface-lighten-1 text-white border-white-10'">
              <v-icon size="x-small" color="primary" class="mr-2">mdi-database</v-icon>
              {{ filteredOrders.length }} registros
              <span class="mx-2 text-medium-emphasis">|</span>
              {{ formatNumber(filteredMeters) }}m
            </div>
          </div>

          <v-data-table
            :headers="activeHeaders"
            :items="filteredOrders"
            :search="search"
            class="bg-transparent premium-table"
            :class="themeStore.currentMode === 'light' ? 'light-table' : 'glass-table'"
            hover
            density="comfortable"
            @click:row="(_, { item }) => { selectedOrder = item; showDetailModal = true; }"
          >
            <template v-slot:item.customer_name="{ item }">
              <div class="d-flex align-center py-2">
                <v-avatar :color="themeStore.currentMode === 'light' ? 'grey-lighten-3' : 'surface-light'" size="32" class="mr-3 font-weight-bold text-caption" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-3' : 'text-white-70'">
                  {{ item.customer_name.charAt(0) }}
                </v-avatar>
                <div>
                  <div class="font-weight-bold text-body-2" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">{{ item.customer_name }}</div>
                  <div class="text-caption text-primary font-mono" v-if="item.order_number">
                    #{{ String(item.order_number).padStart(4, '0') }}
                  </div>
                </div>
              </div>
            </template>

            <template v-slot:item.creator.full_name="{ item }">
              <div class="d-flex align-center">
                <v-icon size="small" color="grey" class="mr-2">mdi-account-tie-outline</v-icon>
                <span class="text-caption font-weight-medium" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-2' : 'text-white-70'">{{ item.creator?.full_name?.split(' ')[0] }}</span>
              </div>
            </template>

            <template v-slot:item.quantity_meters="{ item }">
              <div class="d-flex align-center justify-end">
                <span class="font-weight-black font-mono text-body-2" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">{{ formatNumber(item.quantity_meters) }}</span>
                <span class="text-caption text-medium-emphasis ml-1">m</span>
              </div>
            </template>

            <template v-slot:item.created_at="{ item }">
              <div class="d-flex align-center text-caption text-medium-emphasis">
                <v-icon size="x-small" class="mr-1">mdi-calendar</v-icon>
                {{ formatDate(item.created_at) }}
              </div>
            </template>

            <template v-slot:item.delivery_confirmed_at="{ item }">
              <div class="d-flex align-center text-caption text-success font-weight-bold">
                <v-icon size="x-small" class="mr-1">mdi-check-circle</v-icon>
                {{ formatDate(item.delivery_confirmed_at) }}
              </div>
            </template>

            <template v-slot:item.is_launch="{ item }">
              <v-chip
                size="x-small"
                :color="item.is_launch ? 'purple-accent-2' : 'blue-grey'"
                variant="tonal"
                class="font-weight-bold text-uppercase letter-spacing-1"
              >
                {{ item.is_launch ? 'Lançamento' : 'Padrão' }}
              </v-chip>
            </template>

            <template v-slot:item.status="{ item }">
              <v-chip
                :color="getStatusColor(item.status)"
                size="small"
                variant="flat"
                class="font-weight-bold status-chip-glow text-caption text-white"
              >
                {{ getStatusText(item.status) }}
              </v-chip>
            </template>

            <template v-slot:item.actions="{ item }">
              <div class="d-flex justify-end ga-1">
                <v-btn icon size="x-small" variant="text" color="primary">
                  <v-icon>mdi-eye-outline</v-icon>
                  <v-tooltip activator="parent" location="top">Ver Detalhes</v-tooltip>
                </v-btn>
              </div>
            </template>

            <template v-slot:no-data>
              <div class="text-center pa-12 text-medium-emphasis opacity-50">
                <v-icon size="64" class="mb-4">mdi-clipboard-text-search-outline</v-icon>
                <div class="text-h6">Nenhum pedido encontrado</div>
                <div class="text-caption">Ajuste os filtros ou busque por outro termo.</div>
              </div>
            </template>
          </v-data-table>
        </v-window-item>

        <v-window-item value="charts">
          <div class="pa-6">

            <v-row class="mb-2">
              <v-col cols="12">
                <v-card
                  class="chart-panel-premium pa-4 rounded-xl border-thin"
                  :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-surface-darker'"
                >
                  <div class="d-flex align-center justify-space-between mb-4">
                    <div class="d-flex align-center">
                        <div class="icon-box-sm bg-primary-opacity-10 mr-3 rounded-lg"><v-icon color="primary">mdi-chart-line-variant</v-icon></div>
                        <div>
                            <h3 class="text-subtitle-1 font-weight-bold" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">Evolução de Vendas (Semestral)</h3>
                            <div class="text-caption text-medium-emphasis">Volume total em metros por mês</div>
                        </div>
                    </div>
                    <v-btn icon size="small" variant="text"><v-icon>mdi-download</v-icon></v-btn>
                  </div>
                  <div style="height: 300px;">
                    <Bar :data="monthlySalesChartData" :options="barOptions" />
                  </div>
                </v-card>
              </v-col>
            </v-row>

            <v-row>
              <v-col cols="12" md="4">
                <v-card class="chart-panel-premium pa-4 rounded-xl border-thin h-100" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-surface-darker'">
                  <div class="d-flex align-center mb-4">
                    <div class="icon-box-sm bg-orange-opacity-10 mr-3 rounded-lg"><v-icon color="orange">mdi-account-star</v-icon></div>
                    <h3 class="text-subtitle-2 font-weight-bold" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">Top Vendedores</h3>
                  </div>
                  <div class="chart-wrapper-square">
                    <Doughnut :data="salesBySellerChartData" :options="doughnutOptions" />
                  </div>
                </v-card>
              </v-col>

              <v-col cols="12" md="4">
                <v-card class="chart-panel-premium pa-4 rounded-xl border-thin h-100" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-surface-darker'">
                  <div class="d-flex align-center mb-4">
                    <div class="icon-box-sm bg-teal-opacity-10 mr-3 rounded-lg"><v-icon color="teal">mdi-shape</v-icon></div>
                    <h3 class="text-subtitle-2 font-weight-bold" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">Mix de Tecidos</h3>
                  </div>
                  <div class="chart-wrapper-square">
                    <Doughnut :data="salesByFabricChartData" :options="doughnutOptions" />
                  </div>
                </v-card>
              </v-col>

              <v-col cols="12" md="4">
                <v-card class="chart-panel-premium pa-4 rounded-xl border-thin h-100" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-surface-darker'">
                  <div class="d-flex align-center mb-4">
                    <div class="icon-box-sm bg-red-opacity-10 mr-3 rounded-lg"><v-icon color="red-accent-2">mdi-clock-check-outline</v-icon></div>
                    <h3 class="text-subtitle-2 font-weight-bold" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">Saúde do Design</h3>
                  </div>
                  <div class="chart-wrapper-square">
                    <Doughnut :data="designStatusChartData" :options="doughnutOptions" />
                  </div>
                </v-card>
              </v-col>
            </v-row>
          </div>
        </v-window-item>

      </v-window>
    </v-card>

    <OrderDetailModal :show="showDetailModal" :order-id="selectedOrder?.id" @close="showDetailModal = false" />
    <ApprovalWarningModal :show="showApprovalModal" :pending-orders="ordersPendingApproval" @close="showApprovalModal = false" />
    <ReportSettingsModal :show="showReportModal" @close="showReportModal = false" :orders="allOrders" :sellers="sellerList" :clients="clientList" :fabrics="fabricList" />
    <OpenOrdersModal :show="showOpenOrdersModal" :title="modalTitle" :title-color="modalColor" :orders="modalOrderList" @close="showOpenOrdersModal = false" @status-updated="dashboardStore.fetchData" />

    <FinancialDailyModal
        :show="showFinancialModal"
        :date="selectedFinancialDate"
        :type="selectedFinancialType"
        :items="selectedFinancialItems"
        @close="showFinancialModal = false"
    />

    <v-dialog v-model="showKpiDetailModal" max-width="900px" content-class="glass-modal">
      <v-card class="rounded-xl border-thin" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-surface-darker'">
        <v-toolbar color="transparent" class="border-b px-2" :class="themeStore.currentMode === 'light' ? '' : 'border-white-05'">
          <v-toolbar-title class="font-weight-bold text-h6 pl-4" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">
            {{ modalTitle }}
          </v-toolbar-title>
          <v-btn icon="mdi-close" @click="showKpiDetailModal = false" variant="text" :color="themeStore.currentMode === 'light' ? 'grey-darken-1' : 'white'"></v-btn>
        </v-toolbar>
        <v-card-text class="pa-0">
          <v-data-table
            :headers="modalHeaders"
            :items="modalItems"
            class="bg-transparent premium-table"
            :class="themeStore.currentMode === 'light' ? 'light-table' : ''"
            density="compact"
          >
            <template v-slot:item.quantity_meters="{ value }">
              <span class="font-weight-bold" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-3' : 'text-white'">{{ formatNumber(value) }}m</span>
            </template>
            <template v-slot:item.status="{ item }">
              <v-chip :color="getStatusColor(item.status)" size="x-small" variant="flat" class="font-weight-bold text-white">
                {{ getStatusText(item.status) }}
              </v-chip>
            </template>
          </v-data-table>
        </v-card-text>
      </v-card>
    </v-dialog>

    <v-snackbar v-model="snackbar.show" :color="snackbar.color" :timeout="4000" location="top center" content-class="font-weight-bold elevation-10">
      <v-icon start>mdi-information</v-icon>
      {{ snackbar.text }}
    </v-snackbar>

  </v-container>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onActivated, defineAsyncComponent, reactive, onUnmounted, watch } from 'vue';
import { useDashboardStore } from '@/stores/dashboard';
import { useThemeStore } from '@/stores/theme';
import { storeToRefs } from 'pinia';
import { format, startOfMonth, endOfMonth, startOfWeek, endOfWeek, startOfDay, endOfDay, isWithinInterval, parseISO, addMonths, isSameDay, setDate } from 'date-fns';
import { ptBR } from 'date-fns/locale';
import { Chart as ChartJS, Title, Tooltip, Legend, ArcElement, CategoryScale, LineElement, LinearScale, PointElement, BarElement, Filler } from 'chart.js';
import { supabase } from '@/api/supabase';

ChartJS.register(Title, Tooltip, Legend, ArcElement, CategoryScale, LineElement, LinearScale, PointElement, BarElement, Filler);

// Components Async
const OrderDetailModal = defineAsyncComponent(() => import('@/components/OrderDetailModal.vue'));
const ApprovalWarningModal = defineAsyncComponent(() => import('@/components/admin/ApprovalWarningModal.vue'));
const ReportSettingsModal = defineAsyncComponent(() => import('@/components/admin/ReportSettingsModal.vue'));
const OpenOrdersModal = defineAsyncComponent(() => import('@/components/admin/OpenOrdersModal.vue'));
const FinancialDailyModal = defineAsyncComponent(() => import('@/components/admin/FinancialDailyModal.vue'));
const Doughnut = defineAsyncComponent(() => import('vue-chartjs').then(c => c.Doughnut));
const Bar = defineAsyncComponent(() => import('vue-chartjs').then(c => c.Bar));

const themeStore = useThemeStore();
const dashboardStore = useDashboardStore();
const {
  orders: allOrders,
  ordersPendingApproval,
  totalMetersPendingApproval,
  itemsDelayedInDesign,
  completedOrders,
  deliveredOrders,
  salesBySeller,
  salesByFabric,
  designItemsStatus,
  monthlyProduction,
  delayedDesignItemsDetails,
  totalMetersInDesign,
  allDesignItemsDetails,
  monthlySalesPerformance,
} = storeToRefs(dashboardStore);

// State
const showDetailModal = ref(false);
const selectedOrder = ref<any | null>(null);
const showApprovalModal = ref(false);
const showReportModal = ref(false);
const search = ref('');
const filterType = ref('current_month');
const mainTab = ref('list');
const isRecheckingStock = ref(false);
const snackbar = reactive({ show: false, text: '', color: '' });

// KPI Modals State
const showOpenOrdersModal = ref(false);
const modalOrderList = ref<any[]>([]);
const modalTitle = ref('');
const modalColor = ref('primary');
const showKpiDetailModal = ref(false);
const modalItems = ref<any[]>([]);

// Financial Modals State
const showFinancialModal = ref(false);
const selectedFinancialDate = ref(new Date());
const selectedFinancialType = ref<'receivable' | 'payable'>('receivable');
const selectedFinancialItems = ref<any[]>([]);

// Financial Data State
const financialDate = ref(new Date());
const receivablesData = ref({ total: 0, received: 0, dueToday: 0 });
const payablesData = ref({ total: 0, paid: 0, dueToday: 0 });
// Data Mapping for Drilldown: Record<day_index, items[]>
const receivablesMap = ref<Record<number, any[]>>({});
const payablesMap = ref<Record<number, any[]>>({});
const receivablesChartValues = ref<number[]>([]);
const payablesChartValues = ref<number[]>([]);

// Clock
const currentTime = ref('');
const currentDate = ref('');
const lastSyncTime = ref('');
let clockInterval: NodeJS.Timeout;

const updateClock = () => {
    const now = new Date();
    currentTime.value = format(now, 'HH:mm:ss');
    currentDate.value = format(now, "EEE, d MMM yyyy", { locale: ptBR });
};

// --- FINANCIAL FETCHING ---
const changeFinancialMonth = (delta: number) => {
    financialDate.value = addMonths(financialDate.value, delta);
    fetchFinancialData();
};
const formatFinancialMonth = computed(() => format(financialDate.value, 'MMMM yyyy', { locale: ptBR }));
const formatCurrency = (value: number) => new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(Number(value) || 0);

const fetchFinancialData = async () => {
   const start = startOfMonth(financialDate.value).toISOString();
   const end = endOfMonth(financialDate.value).toISOString();
   const today = new Date();

   // Reset Maps
   receivablesMap.value = {};
   payablesMap.value = {};
   const daysInMonth = endOfMonth(financialDate.value).getDate();
   const dailyRec = Array(daysInMonth).fill(0);
   const dailyPay = Array(daysInMonth).fill(0);

   try {
       // Receivables
       const { data: recData } = await supabase.from('finance_receivables').select('value, due_date, status, description, customer_id').gte('due_date', start).lte('due_date', end);

       if (recData) {
           // Fetch customer names if needed (simulated here or fetched in bulk)
           const customerIds = [...new Set(recData.map(r => r.customer_id).filter(id => id))];
           // In a real app, you would fetch names here. Assuming they are available or we show 'Cliente'.

           const receivedStatuses = ['pago', 'confirmado', 'paid'];
           receivablesData.value.total = recData.reduce((acc, curr) => acc + (Number(curr.value) || 0), 0);
           receivablesData.value.received = recData.filter(i => receivedStatuses.includes(i.status)).reduce((acc, curr) => acc + (Number(curr.value) || 0), 0);
           receivablesData.value.dueToday = recData.filter(i => isSameDay(parseISO(i.due_date), today) && !receivedStatuses.includes(i.status)).reduce((acc, curr) => acc + (Number(curr.value) || 0), 0);

           // Map items to days
           recData.forEach(item => {
                const day = parseISO(item.due_date).getDate() - 1; // 0-indexed
                if (day >= 0 && day < daysInMonth) {
                    dailyRec[day] += (Number(item.value) || 0);
                    if (!receivablesMap.value[day]) receivablesMap.value[day] = [];
                    receivablesMap.value[day].push(item);
                }
           });
           receivablesChartValues.value = dailyRec;
       }

       // Payables
       const { data: payData } = await supabase.from('finance_payables').select('value, due_date, status, description').gte('due_date', start).lte('due_date', end);

       if (payData) {
           const paidStatuses = ['pago', 'confirmado', 'paid'];
           payablesData.value.total = payData.reduce((acc, curr) => acc + (Number(curr.value) || 0), 0);
           payablesData.value.paid = payData.filter(i => paidStatuses.includes(i.status)).reduce((acc, curr) => acc + (Number(curr.value) || 0), 0);
           payablesData.value.dueToday = payData.filter(i => isSameDay(parseISO(i.due_date), today) && !paidStatuses.includes(i.status)).reduce((acc, curr) => acc + (Number(curr.value) || 0), 0);

           payData.forEach(item => {
                const day = parseISO(item.due_date).getDate() - 1;
                if (day >= 0 && day < daysInMonth) {
                    dailyPay[day] += (Number(item.value) || 0);
                    if (!payablesMap.value[day]) payablesMap.value[day] = [];
                    payablesMap.value[day].push(item);
                }
           });
           payablesChartValues.value = dailyPay;
       }

   } catch (e) { console.warn("Erro financeiro:", e); }
};

// --- CHART INTERACTION ---
const openDailyFinancialModal = (index: number, type: 'receivable' | 'payable') => {
    const day = index + 1; // Chart is 0-indexed, Date is 1-indexed
    selectedFinancialDate.value = setDate(financialDate.value, day);
    selectedFinancialType.value = type;

    if (type === 'receivable') {
        selectedFinancialItems.value = receivablesMap.value[index] || [];
    } else {
        selectedFinancialItems.value = payablesMap.value[index] || [];
    }
    showFinancialModal.value = true;
};

// --- CHARTS CONFIG ---
const chartTextColor = computed(() => themeStore.currentMode === 'light' ? '#424242' : '#e0e0e0');
const chartGridColor = computed(() => themeStore.currentMode === 'light' ? 'rgba(0,0,0,0.05)' : 'rgba(255,255,255,0.05)');

const financialChartOptions = (type: 'receivable' | 'payable') => ({
    responsive: true,
    maintainAspectRatio: false,
    onClick: (e: any, elements: any) => {
        if (elements && elements.length > 0) {
            const index = elements[0].index;
            openDailyFinancialModal(index, type);
        }
    },
    plugins: {
        legend: { display: false },
        tooltip: {
            backgroundColor: themeStore.currentMode === 'light' ? 'rgba(255,255,255,0.95)' : 'rgba(20, 20, 25, 0.95)',
            titleColor: themeStore.currentMode === 'light' ? '#000' : '#fff',
            bodyColor: themeStore.currentMode === 'light' ? '#333' : '#e0e0e0',
            borderColor: themeStore.currentMode === 'light' ? 'rgba(0,0,0,0.1)' : 'rgba(255,255,255,0.1)',
            borderWidth: 1,
            padding: 10,
            callbacks: {
                title: (ctx: any) => `Dia ${ctx[0].label}`,
                label: (ctx: any) => {
                    const val = formatCurrency(ctx.raw);
                    return type === 'receivable' ? `Entrada: ${val}` : `Saída: ${val}`;
                }
            }
        }
    },
    scales: {
        x: { display: false },
        y: { display: false }
    },
    elements: {
        bar: {
            borderRadius: 4,
            hoverBackgroundColor: type === 'receivable' ? '#00C853' : '#D50000' // Stronger color on hover
        }
    }
});

const receivablesChartData = computed(() => ({
    labels: Array.from({length: receivablesChartValues.value.length}, (_, i) => i + 1),
    datasets: [{
        data: receivablesChartValues.value,
        backgroundColor: '#00E676',
        barPercentage: 0.6
    }]
}));

const payablesChartData = computed(() => ({
    labels: Array.from({length: payablesChartValues.value.length}, (_, i) => i + 1),
    datasets: [{
        data: payablesChartValues.value,
        backgroundColor: '#FF1744',
        barPercentage: 0.6
    }]
}));

// --- KPI / MODAL HELPERS ---
const openKpiDetailModal = (type: string) => {
  if (type === 'delayed') { modalTitle.value = 'Itens Atrasados no Design'; modalItems.value = delayedDesignItemsDetails.value; }
  else if (type === 'design') { modalTitle.value = 'Fila Geral de Design'; modalItems.value = allDesignItemsDetails.value; }
  showKpiDetailModal.value = true;
};

const openModal = (title: string, orders: any[], color: string = 'primary') => {
  modalTitle.value = title;
  modalColor.value = color;
  modalOrderList.value = (title === 'Pedidos Entregues') ? filteredDeliveredOrders.value : orders;
  showOpenOrdersModal.value = true;
};

// ... (Rest of filteredOrders, formatters, etc from previous version remain effectively same)
// Re-declaring key computed props for clarity/context binding in template
const filteredDeliveredOrders = computed(() => {
  const now = new Date();
  const baseList = deliveredOrders.value;
  let range;
  switch (filterType.value) {
    case 'today': range = { start: startOfDay(now), end: endOfDay(now) }; break;
    case 'current_week': range = { start: startOfWeek(now, { weekStartsOn: 1 }), end: endOfWeek(now, { weekStartsOn: 1 }) }; break;
    case 'current_month': default: range = { start: startOfMonth(now), end: endOfMonth(now) }; break;
  }
  return baseList.filter(o => o.delivery_confirmed_at && isWithinInterval(parseISO(o.delivery_confirmed_at), range));
});

const filteredOrders = computed(() => {
  const now = new Date();
  switch (filterType.value) {
    case 'today': return allOrders.value.filter(o => isWithinInterval(parseISO(o.created_at), { start: startOfDay(now), end: endOfDay(now) }));
    case 'current_week': return allOrders.value.filter(o => isWithinInterval(parseISO(o.created_at), { start: startOfWeek(now, { weekStartsOn: 1 }), end: endOfWeek(now, { weekStartsOn: 1 }) }));
    case 'billing': return completedOrders.value;
    case 'delivered': return deliveredOrders.value;
    default: return allOrders.value.filter(o => isWithinInterval(parseISO(o.created_at), { start: startOfMonth(now), end: endOfMonth(now) }));
  }
});

const filteredMeters = computed(() => filteredOrders.value.reduce((sum, order) => sum + (order.quantity_meters || 0), 0));
const productionOrders = computed(() => allOrders.value.filter(o => ['production_queue', 'in_printing', 'in_cutting'].includes(o.status)));
const productionOrdersMeters = computed(() => productionOrders.value.reduce((sum, order) => sum + (order.quantity_meters || 0), 0));
const allOpenOrders = computed(() => [ ...allOrders.value.filter(o => ['design_pending', 'customer_approval', 'changes_requested', 'approved_by_seller'].includes(o.status)), ...productionOrders.value, ...completedOrders.value ]);
const totalMetersOpen = computed(() => allOpenOrders.value.reduce((sum, order) => sum + (order.quantity_meters || 0), 0));

const activeHeaders = computed(() => {
  const headers = [
    { title: 'Cliente / Pedido', key: 'customer_name' },
    { title: 'Vendedor', key: 'creator.full_name' },
    { title: 'Tipo', key: 'is_launch' },
    { title: 'Metragem', key: 'quantity_meters', align: 'end' as const },
    { title: 'Status', key: 'status', align: 'center' as const },
    { title: 'Ações', key: 'actions', sortable: false, align: 'end' as const },
  ];
  if (filterType.value === 'delivered') headers.splice(4, 0, { title: 'Entrega', key: 'delivery_confirmed_at', align: 'start' as const });
  else headers.splice(4, 0, { title: 'Lançamento', key: 'created_at', align: 'start' as const });
  return headers;
});

const modalHeaders = [{ title: 'Cliente', key: 'customer_name' }, { title: 'Vendedor', key: 'creator_name' }, { title: 'Item', key: 'stamp_ref' }, { title: 'Metragem', key: 'quantity_meters' }, { title: 'Status', key: 'status' }];
const formatNumber = (value: number) => Number(value || 0).toLocaleString('pt-BR', { maximumFractionDigits: 0 });
const formatDate = (dateString: string | null) => dateString ? format(new Date(dateString), 'dd/MM/yy', { locale: ptBR }) : '-';
const getStatusColor = (status: string) => { /* Reuse logic */ switch(status) { case 'design_pending': return 'blue-grey'; case 'customer_approval': return 'orange'; case 'production_queue': return 'grey-darken-1'; case 'completed': return 'success'; case 'delivered': return 'info'; default: return 'grey'; }};
const getStatusText = (status: string) => { /* Reuse logic */ switch(status) { case 'design_pending': return 'No Design'; case 'customer_approval': return 'Aprovação'; case 'production_queue': return 'Fila Produção'; case 'completed': return 'Aguard. Fat.'; case 'delivered': return 'Entregue'; default: return status; }};

// --- CHART OPTIONS FOR MAIN DASHBOARD ---
const commonChartOptions = computed(() => ({ responsive: true, maintainAspectRatio: false, plugins: { legend: { position: 'right' as const, labels: { color: chartTextColor.value, font: { size: 11, family: 'Roboto' }, usePointStyle: true } } } }));
const doughnutOptions = computed(() => ({ ...commonChartOptions.value, cutout: '75%' }));
const barOptions = computed(() => ({ responsive: true, maintainAspectRatio: false, plugins: { legend: { display: false } }, scales: { y: { grid: { color: chartGridColor.value }, ticks: { color: '#999' } }, x: { grid: { display: false }, ticks: { color: chartTextColor.value, font: { weight: 'bold' } } } } }));

const monthlySalesChartData = computed(() => ({ labels: monthlySalesPerformance.value.labels, datasets: [{ label: 'Volume (m)', backgroundColor: 'rgba(41, 182, 246, 0.8)', borderRadius: 6, data: monthlySalesPerformance.value.data }] }));
const salesBySellerChartData = computed(() => ({ labels: salesBySeller.value.map(s => s.seller === 'Danilo Martins' ? 'Fernanda Garcia' : s.seller), datasets: [{ backgroundColor: ['#29b6f6', '#66bb6a', '#ffa726', '#ab47bc', '#ef5350', '#8d6e63'], borderColor: 'transparent', data: salesBySeller.value.map(s => s.totalMeters) }] }));
const salesByFabricChartData = computed(() => ({ labels: salesByFabric.value.slice(0, 5).map(f => f.fabric), datasets: [{ backgroundColor: ['#26a69a', '#7e57c2', '#d4e157', '#ff7043', '#5c6bc0'], borderColor: 'transparent', data: salesByFabric.value.slice(0, 5).map(f => f.totalMeters) }] }));
const designStatusChartData = computed(() => ({ labels: ['Em Dia', 'Atrasado'], datasets: [{ backgroundColor: ['#00e676', '#ff1744'], borderColor: 'transparent', data: [designItemsStatus.value.onTime, designItemsStatus.value.delayed] }] }));
const sellerList = computed(() => [...new Set(allOrders.value.map(o => o.creator?.full_name).filter(Boolean))]);
const clientList = computed(() => [...new Set(allOrders.value.map(o => o.customer_name).filter(Boolean))]);
const fabricList = computed(() => { const fabrics = new Set<string>(); allOrders.value.forEach(order => { if (order.is_launch) order.order_items.forEach(item => fabrics.add(item.fabric_type)); else if (order.details?.fabric_type) fabrics.add(order.details.fabric_type); }); return Array.from(fabrics); });

// --- LIFECYCLE ---
onActivated(async () => { await dashboardStore.fetchData(); fetchFinancialData(); lastSyncTime.value = format(new Date(), 'HH:mm'); });
onMounted(async () => { updateClock(); clockInterval = setInterval(updateClock, 1000); await dashboardStore.fetchData(); fetchFinancialData(); lastSyncTime.value = format(new Date(), 'HH:mm'); });
onUnmounted(() => { clearInterval(clockInterval); });
</script>

<style scoped lang="scss">
/* Reuse previous Styles */
.animate-fade-in-down { animation: fadeInDown 0.7s cubic-bezier(0.2, 0.8, 0.2, 1); }
.animate-fade-in-up { animation: fadeInUp 0.7s cubic-bezier(0.2, 0.8, 0.2, 1) backwards; }
@keyframes fadeInDown { from { opacity: 0; transform: translateY(-30px); } to { opacity: 1; transform: translateY(0); } }
@keyframes fadeInUp { from { opacity: 0; transform: translateY(30px); } to { opacity: 1; transform: translateY(0); } }
.blink { animation: blink 2s infinite; }
@keyframes blink { 0% { opacity: 1; } 50% { opacity: 0.4; } 100% { opacity: 1; } }

.glass-panel { background: rgba(30, 30, 35, 0.6); backdrop-filter: blur(20px); border: 1px solid rgba(255, 255, 255, 0.08); box-shadow: 0 8px 32px rgba(0,0,0,0.3); }
.light-panel { background: #FFFFFF; border: 1px solid #E0E0E0; box-shadow: 0 4px 12px rgba(0,0,0,0.05); }
.bg-gradient-primary { background: linear-gradient(135deg, #1976d2, #0d47a1); }
.bg-gradient-dark-blue { background: linear-gradient(135deg, #1565C0 0%, #0D47A1 100%); }
.bg-surface-darker { background: rgba(0, 0, 0, 0.25) !important; }
.kpi-card { height: 120px; border-radius: 16px; padding: 20px; position: relative; overflow: hidden; border: 1px solid rgba(255,255,255,0.1); cursor: pointer; transition: all 0.3s ease; color: white; }
.kpi-card:hover { transform: translateY(-6px); box-shadow: 0 12px 30px rgba(0,0,0,0.4); filter: brightness(1.1); }
.kpi-bg-icon { position: absolute; right: -15px; bottom: -15px; opacity: 0.15; transform: rotate(-20deg); pointer-events: none; }
.kpi-bg-icon .v-icon { font-size: 110px; color: white; }
.kpi-label { font-size: 0.75rem; font-weight: 700; text-transform: uppercase; letter-spacing: 1px; opacity: 0.8; margin-bottom: 4px; }
.kpi-number-group { display: flex; align-items: baseline; line-height: 1; margin-bottom: 8px; }
.kpi-value { font-size: 2.5rem; font-weight: 900; }
.kpi-unit { font-size: 0.85rem; font-weight: 500; opacity: 0.7; margin-left: 6px; }
.kpi-footer { font-size: 0.75rem; font-family: monospace; background: rgba(0,0,0,0.2); padding: 2px 8px; border-radius: 4px; width: fit-content; }
.tabs-pill-container { border: 1px solid rgba(255,255,255,0.1); display: inline-flex; }
.light-mode-container .tabs-pill-container { border: 1px solid #E0E0E0; }
.tab-pill { padding: 8px 24px; border-radius: 50px; color: #aaa; font-weight: 600; font-size: 0.9rem; cursor: pointer; transition: 0.3s; display: flex; align-items: center; }
.tab-pill:hover { color: white; background: rgba(255,255,255,0.05); }
.tab-pill.active { background: rgba(41, 182, 246, 0.15); color: #29b6f6; border: 1px solid rgba(41, 182, 246, 0.3); box-shadow: 0 0 15px rgba(41, 182, 246, 0.2); }
.tab-pill.light-active { background: #FFFFFF; color: #1976D2; border: 1px solid #E0E0E0; box-shadow: 0 2px 6px rgba(0,0,0,0.05); }
.light-mode-container .tab-pill { color: #616161; }
.light-mode-container .tab-pill:hover { background: rgba(0,0,0,0.05); color: #424242; }
.custom-chip-group .v-chip--selected { box-shadow: 0 0 10px rgba(var(--v-theme-primary), 0.4); }
.glow-chip { box-shadow: 0 0 8px rgba(41, 182, 246, 0.5); }
.search-field-glass :deep(.v-field) { border-radius: 12px !important; border: 1px solid rgba(255,255,255,0.1); color: white; }
.light-mode-container .search-field-glass :deep(.v-field) { border: 1px solid #E0E0E0; color: #424242; }
.premium-table :deep(th) { font-size: 0.7rem !important; text-transform: uppercase; letter-spacing: 1px; color: rgba(255,255,255,0.5) !important; font-weight: 700 !important; }
.premium-table :deep(td) { padding-top: 12px !important; padding-bottom: 12px !important; border-bottom: 1px solid rgba(255,255,255,0.05) !important; }
.premium-table :deep(tr:hover) { background-color: rgba(255,255,255,0.03) !important; }
.light-table :deep(th) { color: #757575 !important; border-bottom: 1px solid #EEEEEE !important; }
.light-table :deep(td) { border-bottom: 1px solid #F5F5F5 !important; color: #424242 !important; }
.light-table :deep(tr:hover) { background-color: #FAFAFA !important; }
.status-chip-glow { box-shadow: 0 2px 8px rgba(0,0,0,0.2); border: 1px solid rgba(255,255,255,0.1); text-transform: uppercase; letter-spacing: 0.5px; }
.glass-btn { background: rgba(255,255,255,0.05) !important; border: 1px solid rgba(255,255,255,0.1); font-weight: 600; letter-spacing: 0.5px; height: 40px; }
.glass-btn:hover { background: rgba(255,255,255,0.1) !important; transform: translateY(-2px); box-shadow: 0 4px 12px rgba(0,0,0,0.3); }
.glass-btn-icon { background: rgba(255,255,255,0.05) !important; border: 1px solid rgba(255,255,255,0.1); width: 40px; height: 40px; }
.shadow-soft { box-shadow: 0 2px 6px rgba(0,0,0,0.1); }
.icon-box-lg { width: 56px; height: 56px; }
.icon-box-sm { width: 36px; height: 36px; display: flex; align-items: center; justify-content: center; }
.shadow-glow { box-shadow: 0 0 20px rgba(41, 182, 246, 0.4); }
.glow-effect { box-shadow: 0 0 20px rgba(25, 118, 210, 0.5); }
.status-dot { width: 8px; height: 8px; border-radius: 50%; }
.hover-scale-sm { transition: transform 0.2s; &:hover { transform: scale(1.02); } }
.chart-wrapper-square { height: 250px; display: flex; align-items: center; justify-content: center; position: relative; }
.bg-primary-opacity-10 { background: rgba(41, 182, 246, 0.1); }
.bg-orange-opacity-10 { background: rgba(255, 167, 38, 0.1); }
.bg-teal-opacity-10 { background: rgba(38, 166, 154, 0.1); }
.bg-red-opacity-10 { background: rgba(239, 83, 80, 0.1); }
.text-white-70 { color: rgba(255,255,255,0.7); }
.text-white-50 { color: rgba(255,255,255,0.5); }
.text-shadow { text-shadow: 0 4px 10px rgba(0,0,0,0.5); }
.font-mono { font-family: 'Roboto Mono', monospace; }
.border-white-05 { border-color: rgba(255,255,255,0.05) !important; }
.border-white-10 { border-color: rgba(255,255,255,0.1) !important; }
.text-gradient { background: linear-gradient(to right, #ffffff, #b0bec5); -webkit-background-clip: text; -webkit-text-fill-color: transparent; }
.bg-gradient-orange { background: linear-gradient(135deg, #ffa726, #f57c00); }
.bg-gradient-green { background: linear-gradient(135deg, #66bb6a, #2e7d32); }
.bg-gradient-red { background: linear-gradient(135deg, #ef5350, #c62828); }
.bg-gradient-purple { background: linear-gradient(135deg, #ab47bc, #7b1fa2); }
.bg-gradient-cyan { background: linear-gradient(135deg, #26c6da, #00838f); }
.bg-gradient-blue { background: linear-gradient(135deg, #42a5f5, #1565c0); }
</style>
