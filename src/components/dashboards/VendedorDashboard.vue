<template>
  <v-container fluid class="pa-6 bg-background-app">

    <v-dialog v-model="showRemindersDialog" max-width="1000" persistent transition="dialog-bottom-transition">
      <v-card class="squared-ui border-thin overflow-hidden shadow-2xl d-flex flex-column" :class="isLight ? 'bg-white text-grey-darken-4' : 'bg-grey-darken-4 text-white'" max-height="90vh">

        <div class="pa-5 pa-md-6 border-b d-flex align-center justify-space-between flex-shrink-0" :class="isLight ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-grey-darken-3 border-white-05'">
          <div class="d-flex align-center">
            <div class="icon-box-lg bg-red-opacity-10 text-red-darken-1 mr-4 squared-ui d-flex align-center justify-center shadow-sm">
              <v-icon size="24" class="blink">mdi-bell-ring-outline</v-icon>
            </div>
            <div>
              <h2 class="text-h5 font-weight-black uppercase tracking-widest text-foxie">Central de Alertas Financeiros</h2>
              <p class="text-caption mb-0 font-weight-bold opacity-70">Ações de cobrança e monitoramento de recebíveis pendentes (2026+)</p>
            </div>
          </div>
          <v-btn icon="mdi-close" variant="text" size="small" @click="showRemindersDialog = false" :color="isLight ? 'grey-darken-4' : 'white'" class="squared-ui opacity-60 hover-opacity-100"></v-btn>
        </div>

        <div class="px-6 py-3 border-b d-flex align-center justify-space-between flex-wrap ga-3 flex-shrink-0" :class="isLight ? 'bg-white border-grey-lighten-2' : 'bg-grey-darken-4 border-white-05'">
          <div class="text-[11px] font-weight-black text-foxie uppercase tracking-widest">Filtrar Alertas por Período:</div>
          <div class="segmented-control" :class="isLight ? 'seg-light' : 'seg-dark'">
              <div class="seg-item text-[10px]" :class="{ 'seg-active': modalPeriodFilter === 'all' }" @click="modalPeriodFilter = 'all'">Todos</div>
              <div class="seg-item text-[10px]" :class="{ 'seg-active': modalPeriodFilter === 'day' }" @click="modalPeriodFilter = 'day'">Dia</div>
              <div class="seg-item text-[10px]" :class="{ 'seg-active': modalPeriodFilter === 'week' }" @click="modalPeriodFilter = 'week'">Semana</div>
              <div class="seg-item text-[10px]" :class="{ 'seg-active': modalPeriodFilter === 'month' }" @click="modalPeriodFilter = 'month'">Mês</div>
          </div>
        </div>

        <v-card-text class="pa-0">
          <v-row dense class="ma-0">

            <v-col cols="12" md="6" class="pa-6 border-e-md d-flex flex-column" :class="isLight ? 'bg-white border-grey-lighten-2' : 'bg-grey-darken-4 border-white-05'">
              <div class="text-subtitle-2 font-weight-black text-red-darken-2 mb-3 text-uppercase tracking-widest d-flex align-center justify-space-between flex-shrink-0">
                <div><v-icon size="16" class="mr-2">mdi-clock-alert-outline</v-icon> Em Atraso ({{ filteredModalOverdue.length }})</div>
              </div>

              <div v-if="filteredModalOverdue.length === 0" class="flex-grow-1 d-flex flex-column justify-center align-center border border-dashed rounded opacity-50 my-4" :class="isLight ? 'border-grey-darken-1' : 'border-white-30'">
                <v-icon size="32" color="grey">mdi-check-circle-outline</v-icon>
                <div class="text-[11px] font-weight-bold uppercase tracking-wide mt-2">Nenhum título atrasado no período</div>
              </div>

              <div v-else class="overflow-y-auto custom-scroll pr-2 flex-grow-1" style="max-height: 45vh;">
                <v-list class="bg-transparent pa-0 d-flex flex-column ga-2">
                  <v-card v-for="inst in paginatedModalOverdue" :key="inst.id" variant="outlined" class="squared-ui border-thin pa-3 d-flex align-center justify-space-between transition-all hover-overlay relative overflow-hidden" :class="isLight ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-grey-darken-3 border-white-05'">
                    <div class="position-absolute left-0 top-0 bottom-0 bg-red-darken-1" style="width: 4px; height: 100%;"></div>
                    <div class="pl-2">
                      <div class="text-caption font-weight-black text-truncate uppercase" style="max-width: 220px;" :class="textPrimaryClass">{{ inst.customer_name }}</div>
                      <div class="text-[10px] opacity-70 mt-1 font-weight-bold" :class="textPrimaryClass">
                        Ped. #{{ String(inst.order_number).padStart(4, '0') }} • Parc. {{ inst.installment_number }}/{{ inst.total_installments }}
                      </div>
                      <div class="text-[10px] text-red-darken-2 font-weight-black font-mono mt-1">
                        Venceu em: {{ formatDate(inst.due_date) }} • <b>{{ formatCurrency(inst.value) }}</b>
                      </div>
                    </div>
                    <v-btn size="small" variant="flat" class="btn-3d squared-ui bg-red-darken-1 text-white" icon="mdi-whatsapp" @click="cobrarWhatsapp(inst)">
                      <v-icon size="16">mdi-whatsapp</v-icon>
                    </v-btn>
                  </v-card>
                </v-list>
              </div>

              <div class="flex-shrink-0 pt-3 border-t mt-3" :class="isLight ? 'border-grey-lighten-2' : 'border-white-05'">
                <v-pagination v-model="modalPageOverdue" :length="modalOverdueCount" density="compact" size="small" active-color="red-darken-1" variant="tonal"></v-pagination>
              </div>
            </v-col>

            <v-col cols="12" md="6" class="pa-6 d-flex flex-column" :class="isLight ? 'bg-white' : 'bg-grey-darken-4'">
              <div class="text-subtitle-2 font-weight-black text-orange-darken-4 mb-3 text-uppercase tracking-widest d-flex align-center justify-space-between flex-shrink-0">
                <div><v-icon size="16" class="mr-2">mdi-calendar-clock</v-icon> Vencendo Hoje / Agenda ({{ filteredModalDueToday.length }})</div>
              </div>

              <div v-if="filteredModalDueToday.length === 0" class="flex-grow-1 d-flex flex-column justify-center align-center border border-dashed rounded opacity-50 my-4" :class="isLight ? 'border-grey-darken-1' : 'border-white-30'">
                <v-icon size="32" color="grey">mdi-calendar-blank</v-icon>
                <div class="text-[11px] font-weight-bold uppercase tracking-wide mt-2">Nenhum vencimento programado</div>
              </div>

              <div v-else class="overflow-y-auto custom-scroll pr-2 flex-grow-1" style="max-height: 45vh;">
                <v-list class="bg-transparent pa-0 d-flex flex-column ga-2">
                  <v-card v-for="inst in paginatedModalToday" :key="inst.id" variant="outlined" class="squared-ui border-thin pa-3 d-flex align-center justify-space-between transition-all hover-overlay relative overflow-hidden" :class="isLight ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-grey-darken-3 border-white-05'">
                    <div class="position-absolute left-0 top-0 bottom-0 bg-orange-darken-3" style="width: 4px; height: 100%;"></div>
                    <div class="pl-2">
                      <div class="text-caption font-weight-black text-truncate uppercase" style="max-width: 220px;" :class="textPrimaryClass">{{ inst.customer_name }}</div>
                      <div class="text-[10px] opacity-70 mt-1 font-weight-bold" :class="textPrimaryClass">
                        Ped. #{{ String(inst.order_number).padStart(4, '0') }} • Parc. {{ inst.installment_number }}/{{ inst.total_installments }}
                      </div>
                      <div class="text-[10px] text-orange-darken-4 font-weight-black font-mono mt-1">
                        Data Alerta: {{ formatDate(inst.due_date) }} • <b>{{ formatCurrency(inst.value) }}</b>
                      </div>
                    </div>
                    <v-btn size="small" variant="flat" class="btn-3d squared-ui bg-orange-darken-3 text-white" icon="mdi-whatsapp" @click="cobrarWhatsapp(inst)">
                      <v-icon size="16">mdi-whatsapp</v-icon>
                    </v-btn>
                  </v-card>
                </v-list>
              </div>

              <div class="flex-shrink-0 pt-3 border-t mt-3" :class="isLight ? 'border-grey-lighten-2' : 'border-white-05'">
                <v-pagination v-model="modalPageToday" :length="modalTodayCount" density="compact" size="small" active-color="orange-darken-4" variant="tonal"></v-pagination>
              </div>
            </v-col>

          </v-row>
        </v-card-text>

        <div class="pa-4 border-t d-flex justify-end shadow-up gap-3 flex-shrink-0" :class="isLight ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-grey-darken-3 border-white-05'">
          <v-btn color="deep-orange-darken-3" variant="flat" class="bg-foxie text-white btn-3d px-8 font-weight-black text-caption tracking-widest shadow-foxie squared-ui" height="42" @click="showRemindersDialog = false">
            ESTOU CIENTE DOS TITULOS
          </v-btn>
        </div>
      </v-card>
    </v-dialog>

    <div class="header-section mb-6 animate-fade-in-down">
      <div class="d-flex flex-column flex-md-row justify-space-between align-md-center ga-4">

        <div class="d-flex align-center">
          <div
            class="icon-box-lg mr-4 elevation-6 squared-ui d-flex align-center justify-center transition-swing shadow-foxie bg-foxie text-white"
          >
            <v-icon size="24">mdi-account-tie</v-icon>
          </div>
          <div>
            <div class="d-flex align-center text-[10px] font-weight-black mb-1 opacity-60 tracking-widest" :class="textSecondaryClass">
              <span class="mr-2">FOXIE ERP SYSTEM</span>
              <v-icon size="x-small" class="mr-2">mdi-chevron-right</v-icon>
              <span>COMERCIAL</span>
            </div>
            <h1 class="text-h4 font-weight-black tracking-tight" :class="textPrimaryClass">
              Painel do Vendedor
            </h1>
          </div>
        </div>

        <div class="d-flex align-center px-4 py-2 border-thin backdrop-blur squared-ui shadow-sm" :class="cardBgClass">
           <div class="text-right mr-4 border-r pr-4 d-none d-sm-block" :class="borderClass">
              <div class="text-h6 font-weight-bold font-mono leading-none" :class="textPrimaryClass">
                {{ currentTime }}
              </div>
              <div class="text-[10px] font-weight-black text-foxie text-uppercase tracking-widest mt-1">
                {{ currentDate }}
              </div>
           </div>

           <div class="d-flex flex-column align-start">
              <div class="text-[9px] font-weight-black text-uppercase opacity-60 mb-1 tracking-widest" :class="textSecondaryClass">Período de Análise</div>

              <div class="segmented-control border-thin squared-ui" :class="isDark ? 'seg-dark' : 'seg-light'">
                  <div class="seg-item" :class="{ 'seg-active': periodFilter === 'day' }" @click="periodFilter = 'day'">Dia</div>
                  <div class="seg-item" :class="{ 'seg-active': periodFilter === 'week' }" @click="periodFilter = 'week'">Sem</div>
                  <div class="seg-item" :class="{ 'seg-active': periodFilter === 'month' }" @click="periodFilter = 'month'">Mês</div>
                  <div class="seg-item" :class="{ 'seg-active': periodFilter === 'year' }" @click="periodFilter = 'year'">Ano</div>
              </div>
           </div>
        </div>

        <div class="d-flex align-center flex-wrap ga-3">
          <v-btn
            variant="tonal"
            color="secondary"
            :class="isDark ? 'glass-btn text-white' : 'bg-grey-lighten-3 text-grey-darken-4 border-thin'"
            prepend-icon="mdi-image-edit-outline"
            @click="openEditor"
            :loading="loadingEditorToken"
            size="small"
            class="btn-rect btn-3d font-weight-black text-caption tracking-widest squared-ui"
            height="40"
          >
            Editor
          </v-btn>

          <v-menu location="bottom end">
            <template v-slot:activator="{ props }">
              <v-btn
                color="deep-orange-darken-3"
                variant="flat"
                prepend-icon="mdi-plus-box-outline"
                v-bind="props"
                size="small"
                class="bg-foxie text-white btn-rect btn-3d font-weight-black text-caption tracking-widest shadow-foxie squared-ui"
                height="40"
              >
                Lançar Pedido
                <v-icon end>mdi-chevron-down</v-icon>
              </v-btn>
            </template>
            <v-list density="compact" class="squared-ui border-thin shadow-xl mt-2" :bg-color="isLight ? 'white' : 'grey-darken-4'">
              <v-list-item :to="{ name: 'NewOrderComNota' }" prepend-icon="mdi-file-document-check-outline" link>
                <v-list-item-title class="font-weight-bold text-caption text-uppercase tracking-wider" :class="textPrimaryClass">Com Nota (Sicredi)</v-list-item-title>
              </v-list-item>
              <v-divider class="my-1" :class="borderClass"></v-divider>
              <v-list-item :to="{ name: 'NewOrderSemNota' }" prepend-icon="mdi-file-document-remove-outline" link>
                <v-list-item-title class="font-weight-bold text-caption text-uppercase tracking-wider" :class="textPrimaryClass">Sem Nota (Cora)</v-list-item-title>
              </v-list-item>
            </v-list>
          </v-menu>
        </div>
      </div>
    </div>

    <div v-if="loadingData" class="d-flex flex-column align-center justify-center py-10">
        <v-progress-circular indeterminate color="deep-orange-darken-3" size="48" width="4"></v-progress-circular>
        <div class="text-caption font-weight-black mt-4 opacity-70 text-uppercase tracking-widest" :class="textPrimaryClass">Processando métricas...</div>
    </div>

    <template v-else>
      <v-row class="mb-4 animate-fade-in-up" dense>
          <v-col cols="12" sm="6" md="4" lg="2">
              <v-card class="kpi-card squared-ui bg-gradient-orange hover-elevate shadow-sm" @click="goToApprovals" v-ripple>
                  <div class="kpi-bg-icon"><v-icon>mdi-check-decagram</v-icon></div>
                  <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                      <span class="kpi-label text-white tracking-widest">Aprovações</span>
                      <div class="kpi-number-group">
                          <span class="kpi-value text-white drop-shadow-text">{{ pendingApprovalsCount }}</span>
                      </div>
                      <div class="kpi-footer text-white tracking-widest">Pendentes</div>
                  </div>
              </v-card>
          </v-col>

          <v-col cols="12" sm="6" md="4" lg="3">
              <v-card class="kpi-card squared-ui bg-gradient-info hover-elevate shadow-sm">
                  <div class="kpi-bg-icon"><v-icon>mdi-ruler-square</v-icon></div>
                  <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                      <span class="kpi-label text-white tracking-widest">Volume Vendido</span>
                      <div class="kpi-number-group">
                          <span class="kpi-value text-white drop-shadow-text">{{ formatMeters(dashboardMetrics.totalMeters) }}</span>
                          <span class="kpi-unit text-white">m</span>
                      </div>
                      <div class="kpi-footer text-white tracking-widest">No Período</div>
                  </div>
              </v-card>
          </v-col>

          <v-col cols="12" sm="6" md="4" lg="2">
              <v-card class="kpi-card squared-ui bg-gradient-teal hover-elevate shadow-sm">
                  <div class="kpi-bg-icon"><v-icon>mdi-chart-line</v-icon></div>
                  <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                      <span class="kpi-label text-white tracking-widest">Ticket Médio</span>
                      <div class="kpi-number-group">
                          <span class="kpi-value text-white drop-shadow-text">{{ formatMeters(dashboardMetrics.averageMeters) }}</span>
                          <span class="kpi-unit text-white">m</span>
                      </div>
                      <div class="kpi-footer text-white tracking-widest">Por Pedido</div>
                  </div>
              </v-card>
          </v-col>

          <v-col cols="12" sm="6" md="4" lg="2">
              <v-card class="kpi-card squared-ui bg-gradient-purple hover-elevate shadow-sm">
                  <div class="kpi-bg-icon"><v-icon>mdi-account-plus</v-icon></div>
                  <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                      <span class="kpi-label text-white tracking-widest">Novos Clientes</span>
                      <div class="kpi-number-group">
                          <span class="kpi-value text-white drop-shadow-text">{{ dashboardMetrics.newClients }}</span>
                      </div>
                      <div class="kpi-footer text-white tracking-widest">No Período</div>
                  </div>
              </v-card>
          </v-col>

          <v-col cols="12" sm="6" md="4" lg="3">
              <v-card class="kpi-card squared-ui bg-gradient-blue hover-elevate overflow-visible shadow-sm">
                  <div class="kpi-bg-icon"><v-icon>mdi-target</v-icon></div>
                  <div class="d-flex align-center justify-space-between position-relative z-10 h-100">
                      <div class="d-flex flex-column justify-space-between fill-height">
                          <span class="kpi-label text-white tracking-widest">Meta Anual</span>
                          <div class="kpi-number-group">
                              <span class="kpi-value text-white drop-shadow-text">{{ Math.round(dashboardMetrics.goalPercentage) }}</span>
                              <span class="kpi-unit text-white">%</span>
                          </div>
                          <div class="kpi-footer text-white tracking-widest">Base: 42.000m</div>
                      </div>
                      <div style="width: 60px; height: 60px;">
                          <v-progress-circular
                              :model-value="dashboardMetrics.goalPercentage"
                              :size="55"
                              :width="6"
                              color="white"
                              bg-color="rgba(255,255,255,0.2)"
                          >
                              <v-icon size="small" color="white">mdi-flag</v-icon>
                          </v-progress-circular>
                      </div>
                  </div>
              </v-card>
          </v-col>
      </v-row>

      <v-row class="mb-4 animate-fade-in-up" style="animation-delay: 0.1s">
          <v-col cols="12" md="5">
              <v-card class="squared-ui border-thin h-100 d-flex flex-column shadow-sm" :class="cardBgClass">
                  <div class="px-4 py-3 border-b d-flex align-center justify-space-between flex-shrink-0" :class="borderClass">
                      <div class="d-flex align-center">
                          <div class="icon-box-sm mr-3 rounded-lg" :class="isLight ? 'bg-red-lighten-5 text-red-darken-2' : 'bg-red-opacity-10 text-red'">
                              <v-icon size="18">mdi-alert-octagon-outline</v-icon>
                          </div>
                          <div>
                              <h3 class="text-subtitle-2 font-weight-black text-uppercase tracking-widest" :class="textPrimaryClass">Central de Cobranças</h3>
                              <div class="text-[10px] opacity-50 uppercase tracking-widest">Títulos Filtrados (2026+)</div>
                          </div>
                      </div>
                      <div class="segmented-control border-thin p-1" :class="isDark ? 'seg-dark' : 'seg-light'">
                          <div class="seg-item text-[9px] px-2 py-1" :class="{ 'seg-active': dashboardCobrançaFilter === 'all' }" @click="dashboardCobrançaFilter = 'all'">Todos</div>
                          <div class="seg-item text-[9px] px-2 py-1" :class="{ 'seg-active': dashboardCobrançaFilter === 'overdue' }" @click="dashboardCobrançaFilter = 'overdue'">Atrasadas</div>
                          <div class="seg-item text-[9px] px-2 py-1" :class="{ 'seg-active': dashboardCobrançaFilter === 'today' }" @click="dashboardCobrançaFilter = 'today'">Hoje</div>
                      </div>
                  </div>

                  <div class="flex-grow-1 d-flex flex-column overflow-hidden" style="min-height: 420px;">

                      <div v-if="visibleDashboardOverdue.length === 0 && visibleDashboardDueToday.length === 0" class="flex-grow-1 d-flex flex-column align-center justify-center opacity-40 py-12">
                          <v-icon size="40" class="mb-2">mdi-check-all</v-icon>
                          <span class="text-caption font-weight-black text-uppercase tracking-widest" :class="textPrimaryClass">Nenhuma pendência</span>
                      </div>

                      <template v-else>
                          <div v-if="visibleDashboardOverdue.length > 0" class="d-flex flex-column flex-grow-1 overflow-hidden pb-2">
                              <div class="px-4 pt-3 pb-1 text-[10px] font-weight-black text-red-darken-1 text-uppercase tracking-widest d-flex align-center flex-shrink-0">
                                  <v-icon size="14" class="mr-1">mdi-alert</v-icon> Parcelas Atrasadas ({{ visibleDashboardOverdue.length }})
                              </div>
                              <div class="px-4 flex-grow-1 overflow-y-auto custom-scroll pr-2">
                                  <v-list class="bg-transparent pa-0 d-flex flex-column ga-2">
                                    <v-card v-for="inst in paginatedDashOverdue" :key="inst.id" class="border-thin squared-ui pa-3 d-flex align-center justify-space-between transition-all hover-overlay relative overflow-hidden" :class="isLight ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-transparent border-white-05'">
                                        <div class="position-absolute left-0 top-0 bottom-0 bg-red-darken-1" style="width: 4px;"></div>
                                        <div class="pl-2">
                                            <div class="text-caption font-weight-black text-truncate uppercase" style="max-width: 200px;" :class="textPrimaryClass">{{ inst.customer_name }}</div>
                                            <div class="text-[10px] d-flex align-center mt-1 font-weight-bold opacity-70" :class="textPrimaryClass">
                                                Ped. #{{ String(inst.order_number).padStart(4, '0') }} • Parc. {{ inst.installment_number }}/{{ inst.total_installments }} ({{ formatCurrency(inst.value) }})
                                            </div>
                                            <div class="text-[10px] text-red-darken-2 font-weight-black font-mono d-flex align-center mt-1">
                                                <v-icon size="12" class="mr-1">mdi-calendar-remove</v-icon> Vencimento: {{ formatDate(inst.due_date) }}
                                            </div>
                                        </div>
                                        <v-btn size="small" variant="flat" class="btn-3d squared-ui bg-red-darken-1 text-white" icon="mdi-whatsapp" @click="cobrarWhatsapp(inst)">
                                          <v-icon size="16">mdi-whatsapp</v-icon>
                                        </v-btn>
                                    </v-card>
                                  </v-list>
                              </div>
                              <div class="px-4 flex-shrink-0">
                                <v-pagination v-model="dashPageOverdue" :length="dashOverdueCount" density="compact" size="small" active-color="red-darken-1" variant="tonal" class="mt-2"></v-pagination>
                              </div>
                          </div>

                          <v-divider v-if="visibleDashboardOverdue.length > 0 && visibleDashboardDueToday.length > 0" class="my-2" :class="borderClass"></v-divider>

                          <div v-if="visibleDashboardDueToday.length > 0" class="d-flex flex-column flex-grow-1 overflow-hidden pb-2">
                              <div class="px-4 pt-3 pb-1 text-[10px] font-weight-black text-orange-darken-4 text-uppercase tracking-widest d-flex align-center flex-shrink-0">
                                  <v-icon size="14" class="mr-1">mdi-calendar-today</v-icon> Vencem Hoje ({{ visibleDashboardDueToday.length }})
                              </div>
                              <div class="px-4 flex-grow-1 overflow-y-auto custom-scroll pr-2">
                                  <v-list class="bg-transparent pa-0 d-flex flex-column ga-2">
                                    <v-card v-for="inst in paginatedDashToday" :key="inst.id" class="border-thin squared-ui pa-3 d-flex align-center justify-space-between transition-all hover-overlay relative overflow-hidden" :class="isLight ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-transparent border-white-05'">
                                        <div class="position-absolute left-0 top-0 bottom-0 bg-orange-darken-3" style="width: 4px;"></div>
                                        <div class="pl-2">
                                            <div class="text-caption font-weight-black text-truncate uppercase" style="max-width: 200px;" :class="textPrimaryClass">{{ inst.customer_name }}</div>
                                            <div class="text-[10px] d-flex align-center mt-1 font-weight-bold opacity-70" :class="textPrimaryClass">
                                                Ped. #{{ String(inst.order_number).padStart(4, '0') }} • Parc. {{ inst.installment_number }}/{{ inst.total_installments }} ({{ formatCurrency(inst.value) }})
                                            </div>
                                            <div class="text-[10px] text-orange-darken-4 font-weight-black font-mono d-flex align-center mt-1">
                                                <v-icon size="12" class="mr-1">mdi-alert-circle-outline</v-icon> Cobrança Obrigatória
                                            </div>
                                        </div>
                                        <v-btn size="small" variant="flat" class="btn-3d squared-ui bg-orange-darken-3 text-white" icon="mdi-whatsapp" @click="cobrarWhatsapp(inst)">
                                          <v-icon size="16">mdi-whatsapp</v-icon>
                                        </v-btn>
                                    </v-card>
                                  </v-list>
                              </div>
                              <div class="px-4 flex-shrink-0">
                                <v-pagination v-model="dashPageToday" :length="dashTodayCount" density="compact" size="small" active-color="orange-darken-4" variant="tonal" class="mt-2"></v-pagination>
                              </div>
                          </div>
                      </template>
                  </div>
              </v-card>
          </v-col>

          <v-col cols="12" md="7">
              <v-card class="squared-ui border-thin h-100 d-flex flex-column shadow-sm" :class="cardBgClass">
                  <div class="px-4 py-3 border-b d-flex align-center justify-space-between" :class="borderClass">
                      <div class="d-flex align-center">
                          <div class="icon-box-sm mr-3 rounded-lg" :class="isLight ? 'bg-primary-lighten-5 text-primary' : 'bg-primary-opacity-10 text-primary'">
                              <v-icon size="18">mdi-chart-areaspline</v-icon>
                          </div>
                          <div>
                              <h3 class="text-subtitle-2 font-weight-bold" :class="textPrimaryClass">Evolução de Volume</h3>
                              <div class="text-[10px] opacity-60">Metragem produzida no período</div>
                          </div>
                      </div>
                  </div>
                  <div class="pa-4 flex-grow-1" style="min-height: 420px;">
                      <Bar v-if="salesChartData.labels.length > 0" :data="salesChartData" :options="chartOptions" />
                      <div v-else class="h-100 d-flex flex-column align-center justify-center opacity-40 py-12">
                          <v-icon size="40" class="mb-2">mdi-chart-bar-off</v-icon>
                          <span class="text-caption font-weight-bold text-uppercase tracking-widest" :class="textPrimaryClass">Sem registros gráficos no período</span>
                      </div>
                  </div>
              </v-card>
          </v-col>
      </v-row>

      <v-row class="mb-4 animate-fade-in-up" style="animation-delay: 0.2s" dense>
          <v-col cols="12" lg="4">
              <v-card class="squared-ui border-thin h-100 d-flex flex-column shadow-sm" :class="cardBgClass">
                  <div class="px-4 py-3 border-b" :class="borderClass">
                      <div class="d-flex align-center">
                          <div class="icon-box-sm mr-3 rounded-lg" :class="isLight ? 'bg-purple-lighten-5 text-purple' : 'bg-purple-opacity-10 text-purple-lighten-2'">
                              <v-icon size="18">mdi-texture</v-icon>
                          </div>
                          <div>
                              <h3 class="text-subtitle-2 font-weight-bold" :class="textPrimaryClass">Top Tecidos (Ranking)</h3>
                              <div class="text-[10px] opacity-60">Baseado nos itens vendidos no período</div>
                          </div>
                      </div>
                  </div>
                  <div class="pa-4 flex-grow-1 d-flex flex-column justify-center" :class="isLight ? 'bg-white' : 'bg-grey-darken-4'">
                      <div v-if="topFabrics.length === 0" class="text-center opacity-40 py-4">
                          <v-icon size="32" class="mb-2">mdi-texture-box</v-icon>
                          <div class="text-caption font-weight-bold uppercase text-nano-badge" :class="textPrimaryClass">Sem dados de movimentação</div>
                      </div>
                      <div v-else class="fabric-ranking-list">
                          <div v-for="(fabric, index) in topFabrics" :key="index" class="mb-4">
                              <div class="d-flex justify-space-between align-center mb-1">
                                  <span class="text-caption font-weight-bold text-truncate pr-2 uppercase" :class="textPrimaryClass">{{ index + 1 }}. {{ fabric.name }}</span>
                                  <span class="text-caption font-mono font-weight-black text-foxie">{{ formatMeters(fabric.volume) }}m</span>
                              </div>
                              <v-progress-linear
                                  :model-value="(fabric.volume / topFabrics[0].volume) * 100"
                                  color="orange-darken-3"
                                  height="6"
                                  class="squared-ui"
                                  bg-color="rgba(128,128,128,0.15)"
                              ></v-progress-linear>
                          </div>
                      </div>
                  </div>
              </v-card>
          </v-col>

          <v-col cols="12" lg="4">
              <v-card class="squared-ui border-thin h-100 d-flex flex-column shadow-sm" :class="cardBgClass">
                  <div class="px-4 py-3 border-b" :class="borderClass">
                      <div class="d-flex align-center justify-space-between">
                          <div class="d-flex align-center">
                              <div class="icon-box-sm mr-3 rounded-lg" :class="isLight ? 'bg-green-lighten-5 text-green-darken-2' : 'bg-green-opacity-10 text-green-lighten-2'">
                                  <v-icon size="18">mdi-tag-multiple-outline</v-icon>
                              </div>
                              <div>
                                  <h3 class="text-subtitle-2 font-weight-bold" :class="textPrimaryClass">Últimas Vendas</h3>
                                  <div class="text-[10px] opacity-60">Lançamentos recentes no período</div>
                              </div>
                          </div>
                          <v-btn size="x-small" variant="text" color="foxie" :to="{ name: 'SalesOrderManagement' }" class="font-weight-black text-uppercase">Ver Todas</v-btn>
                      </div>
                  </div>
                  <div class="pa-0 flex-grow-1 overflow-y-auto custom-scroll" style="max-height: 300px;">
                      <div v-if="recentSales.length === 0" class="pa-4 text-center opacity-40 h-100 d-flex align-center justify-center flex-column py-12">
                          <v-icon size="32" class="mb-2">mdi-receipt-outline</v-icon>
                          <span class="text-caption font-weight-black uppercase" :class="textPrimaryClass">Nenhuma venda faturada</span>
                      </div>
                      <v-list v-else class="bg-transparent pa-0">
                          <v-list-item v-for="order in recentSales" :key="order.id" class="border-b py-3 px-4 hover-overlay" :class="borderClass">
                              <template v-slot:prepend>
                                  <div class="icon-box-sm rounded-circle mr-3" :class="isLight ? 'bg-grey-lighten-3' : 'bg-white-05'">
                                      <v-icon size="14" :class="textSecondaryClass">mdi-shopping</v-icon>
                                  </div>
                              </template>
                              <v-list-item-title class="text-caption font-weight-black text-truncate uppercase" :class="textPrimaryClass">
                                  {{ order.customer_name || 'Cliente Balcão' }}
                              </v-list-item-title>
                              <v-list-item-subtitle class="text-[10px] d-flex align-center mt-1" :class="textSecondaryClass">
                                  <span class="font-mono font-weight-black mr-2 text-foxie">#{{ String(order.order_number).padStart(4, '0') }}</span>
                                  <v-icon size="10" class="mr-1">mdi-ruler</v-icon> {{ formatMeters(order.quantity_meters || 0) }}m
                              </v-list-item-subtitle>
                              <template v-slot:append>
                                  <div class="text-caption text-right">
                                      <div class="font-weight-bold text-success">{{ formatTimeAgo(order.created_at) }}</div>
                                  </div>
                              </template>
                          </v-list-item>
                      </v-list>
                  </div>
              </v-card>
          </v-col>

          <v-col cols="12" lg="4">
              <v-card class="squared-ui border-thin h-100 d-flex flex-column shadow-sm" :class="cardBgClass">
                  <div class="px-4 py-3 border-b bg-white-05" :class="borderClass">
                      <div class="d-flex align-center justify-space-between w-100">
                          <div class="d-flex align-center">
                              <div class="icon-box-sm mr-3 rounded-lg" :class="isLight ? 'bg-amber-lighten-5 text-amber-darken-2' : 'bg-orange-opacity-10 text-orange'">
                                  <v-icon size="18">mdi-trophy-variant</v-icon>
                              </div>
                              <div>
                                  <h3 class="text-subtitle-2 font-weight-bold" :class="textPrimaryClass">Ranking Global</h3>
                                  <div class="text-[10px] opacity-60">Top Vendedores Mensal</div>
                              </div>
                          </div>
                      </div>
                  </div>

                  <div class="d-flex align-end justify-center pa-4 h-100 pb-8 podium-wrapper" :class="isLight ? 'bg-white' : 'bg-grey-darken-4'">
                      <div class="podium-container w-100" v-if="filteredSellerRanking.length >= 3">
                          <div class="podium-item rank-2">
                              <div class="podium-avatar-wrapper elevation-3 squared-ui" :class="isLight ? 'bg-white' : 'bg-surface-light'">
                                  <v-avatar size="44" class="podium-avatar bg-grey-darken-2 text-white font-weight-bold text-h6 squared-ui">
                                      <v-img v-if="filteredSellerRanking[1]?.avatar" :src="filteredSellerRanking[1].avatar"></v-img>
                                      <span v-else>{{ getInitials(filteredSellerRanking[1]?.name) }}</span>
                                  </v-avatar>
                                  <div class="rank-badge badge-silver">2</div>
                              </div>
                              <div class="podium-name text-truncate uppercase text-[11px] font-weight-bold" :class="textPrimaryClass">{{ firstName(filteredSellerRanking[1]?.name) }}</div>
                              <div class="podium-value font-mono font-weight-black mt-1 text-[12px]" :class="textSecondaryClass">
                                  {{ filteredSellerRanking[1]?.area.toFixed(0) }}m
                              </div>
                              <div class="podium-bar bar-silver"></div>
                          </div>

                          <div class="podium-item rank-1">
                              <div class="podium-avatar-wrapper elevation-6 squared-ui" :class="isLight ? 'bg-white' : 'bg-surface-light'">
                                  <v-icon color="amber" class="crown-icon">mdi-crown</v-icon>
                                  <v-avatar size="56" class="podium-avatar bg-warning text-white font-weight-bold text-h5 squared-ui">
                                      <v-img v-if="filteredSellerRanking[0]?.avatar" :src="filteredSellerRanking[0].avatar"></v-img>
                                      <span v-else>{{ getInitials(filteredSellerRanking[0]?.name) }}</span>
                                  </v-avatar>
                                  <div class="rank-badge badge-gold">1</div>
                              </div>
                              <div class="podium-name text-truncate font-weight-black uppercase text-[12px]" :class="textPrimaryClass">{{ firstName(filteredSellerRanking[0]?.name) }}</div>
                              <div class="podium-value font-mono font-weight-black text-orange-darken-4 mt-1 text-[14px]">
                                  {{ filteredSellerRanking[0]?.area.toFixed(0) }}m
                              </div>
                              <div class="podium-bar bar-gold"></div>
                          </div>

                          <div class="podium-item rank-3">
                              <div class="podium-avatar-wrapper elevation-3 squared-ui" :class="isLight ? 'bg-white' : 'bg-surface-light'">
                                  <v-avatar size="44" class="podium-avatar bg-grey-darken-3 text-white font-weight-bold text-h6 squared-ui">
                                      <v-img v-if="filteredSellerRanking[2]?.avatar" :src="filteredSellerRanking[2].avatar"></v-img>
                                      <span v-else>{{ getInitials(filteredSellerRanking[2]?.name) }}</span>
                                  </v-avatar>
                                  <div class="rank-badge badge-bronze">3</div>
                              </div>
                              <div class="podium-name text-truncate uppercase text-[11px] font-weight-bold" :class="textPrimaryClass">{{ firstName(filteredSellerRanking[2]?.name) }}</div>
                              <div class="podium-value font-mono font-weight-black mt-1 text-[12px]" :class="textSecondaryClass">
                                  {{ filteredSellerRanking[2]?.area.toFixed(0) }}m
                              </div>
                              <div class="podium-bar bar-bronze"></div>
                          </div>
                      </div>
                      <div v-else class="text-center py-10 opacity-40 w-100 d-flex flex-column align-center py-12">
                          <v-icon size="40">mdi-trophy-broken</v-icon>
                          <div class="text-caption font-weight-black uppercase mt-2" :class="textPrimaryClass">Métricas de Ranking Congeladas</div>
                      </div>
                  </div>
              </v-card>
          </v-col>
      </v-row>

      <v-row class="animate-fade-in-up" style="animation-delay: 0.3s" dense>
        <v-col cols="12" xl="8">
          <v-card class="squared-ui border-thin h-100 overflow-hidden position-relative shadow-sm" :class="cardBgClass">
              <div class="position-absolute top-0 right-0 h-100 w-50" style="background: linear-gradient(to left, rgba(230, 81, 0, 0.06), transparent); pointer-events: none;"></div>

              <div class="d-flex flex-column flex-md-row align-center justify-space-between pa-6 position-relative z-10 h-100">
                  <div class="d-flex align-center mb-4 mb-md-0">
                      <div class="icon-box-lg squared-ui mr-4 elevation-6 d-flex align-center justify-center bg-foxie shadow-foxie">
                          <v-icon size="28" color="white">mdi-format-list-bulleted-type</v-icon>
                      </div>
                      <div>
                          <h2 class="text-h6 font-weight-black uppercase tracking-widest" :class="textPrimaryClass">Central de Faturamento Avançada</h2>
                          <p class="text-body-2 opacity-70 mb-0 mt-1" style="max-width: 450px;" :class="textPrimaryClass">
                              Monitore o andamento logístico completo de suas vendas, consulte romaneios emitidos e valide agendas e parcelamentos de faturamento em tempo real.
                          </p>
                      </div>
                  </div>

                  <div class="d-flex align-center gap-3">
                      <v-btn
                          size="large"
                          color="deep-orange-darken-3"
                          variant="flat"
                          class="bg-foxie text-white btn-rect px-6 btn-3d tracking-widest shadow-foxie squared-ui font-weight-black text-caption"
                          :to="{ name: 'SalesOrderManagement' }"
                          prepend-icon="mdi-open-in-new"
                          height="46"
                      >
                          ACESSAR GESTÃO DE VENDAS
                      </v-btn>
                  </div>
              </div>
          </v-card>
        </v-col>

        <v-col cols="12" xl="4">
          <v-card class="squared-ui border-thin h-100 pa-4 shadow-sm" :class="isLight ? 'bg-white' : 'glass-panel'">
              <SalesMapBrazil
                  :sales-data="salesByRegion"
                  :sellers="sellersByRegion"
                  v-model:period="mapPeriod"
              />
          </v-card>
        </v-col>
      </v-row>
    </template>

    <v-alert v-if="editorError" type="error" closable variant="tonal" class="position-fixed bottom-0 right-0 ma-4 squared-ui font-weight-bold" style="z-index: 9999;" @click:close="editorError = null">
        {{ editorError }}
    </v-alert>

  </v-container>
</template>

<script setup lang="ts">
import { computed, ref, onMounted, defineAsyncComponent, onUnmounted, watch } from 'vue';
import { useRouter } from 'vue-router';
import { useSalesAreaStore } from '@/stores/salesArea';
import { useUserStore } from '@/stores/user';
import { useTheme } from 'vuetify'; // Correção do Light/Dark Mode
import { supabase } from '@/api/supabase';
import {
    startOfMonth, endOfMonth, startOfDay, endOfDay,
    startOfWeek, endOfWeek, startOfYear, endOfYear,
    parseISO, format, differenceInDays, formatDistanceToNow,
    isBefore, isEqual, isToday, isWithinInterval
} from 'date-fns';
import { Chart as ChartJS, Title, Tooltip, Legend, BarElement, CategoryScale, LinearScale } from 'chart.js';
import SalesMapBrazil from './SalesMapBrazil.vue';
import { ptBR } from 'date-fns/locale';

const Bar = defineAsyncComponent(() => import('vue-chartjs').then(c => c.Bar));
ChartJS.register(Title, Tooltip, Legend, BarElement, CategoryScale, LinearScale);

const router = useRouter();
const salesStore = useSalesAreaStore();
const userStore = useUserStore();
const theme = useTheme();

// --- TEMA SINCRONIZADO ---
const isDark = computed(() => theme.global.current.value.dark);
const isLight = computed(() => !theme.global.current.value.dark);

const textPrimaryClass = computed(() => isDark.value ? 'text-white' : 'text-grey-darken-4');
const textSecondaryClass = computed(() => isDark.value ? 'text-grey-lighten-1' : 'text-grey-darken-1');
const cardBgClass = computed(() => isDark.value ? 'bg-grey-darken-4' : 'bg-white shadow-soft');
const borderClass = computed(() => isDark.value ? 'border-white-05' : 'border-grey-lighten-2');

const loadingEditorToken = ref(false);
const editorError = ref<string | null>(null);
const currentTime = ref('');
const currentDate = ref('');
const mapPeriod = ref('month');
let clockInterval: NodeJS.Timeout;

// --- STATE: FILTROS E DADOS ---
const periodFilter = ref<'day' | 'week' | 'month' | 'year'>('month');
const modalPeriodFilter = ref<'all' | 'day' | 'week' | 'month'>('all');
const dashboardCobrançaFilter = ref<'all' | 'overdue' | 'today'>('all');
const loadingData = ref(false);

const dashboardMetrics = ref({ totalMeters: 0, totalOrders: 0, averageMeters: 0, goalPercentage: 0, newClients: 0 });
const topFabrics = ref<any[]>([]);
const recentSales = ref<any[]>([]);
const pendingApprovalsCount = ref(0);

const financialReminders = ref({ overdue: [] as any[], dueToday: [] as any[] });
const showRemindersDialog = ref(false);

// --- PAGINAÇÃO FIXADA (20 Itens MÁX) ---
const modalPageOverdue = ref(1);
const modalPageToday = ref(1);
const dashPageOverdue = ref(1);
const dashPageToday = ref(1);
const itemsPerPage = 20;

const dateRange = computed(() => {
    const now = new Date();
    if (periodFilter.value === 'day') return { start: startOfDay(now), end: endOfDay(now) };
    if (periodFilter.value === 'week') return { start: startOfWeek(now, { weekStartsOn: 1 }), end: endOfWeek(now, { weekStartsOn: 1 }) };
    if (periodFilter.value === 'month') return { start: startOfMonth(now), end: endOfMonth(now) };
    if (periodFilter.value === 'year') return { start: startOfYear(now), end: endOfYear(now) };
    return { start: startOfMonth(now), end: endOfMonth(now) };
});

watch(periodFilter, () => { fetchDashboardData(); });

// Reset Paginação
watch(modalPeriodFilter, () => { modalPageOverdue.value = 1; modalPageToday.value = 1; });
watch(dashboardCobrançaFilter, () => { dashPageOverdue.value = 1; dashPageToday.value = 1; });

// --- FILTRAGEM E ORDENAÇÃO DO MODAL DE REMINDERS (2026+) ---
const filteredModalOverdue = computed(() => {
    let list = financialReminders.value.overdue || [];
    return filterRemindersByPeriod(list, modalPeriodFilter.value);
});
const modalOverdueCount = computed(() => Math.ceil(filteredModalOverdue.value.length / itemsPerPage) || 1);
const paginatedModalOverdue = computed(() => {
    const start = (modalPageOverdue.value - 1) * itemsPerPage;
    return filteredModalOverdue.value.slice(start, start + itemsPerPage);
});

const filteredModalDueToday = computed(() => {
    let list = financialReminders.value.dueToday || [];
    return filterRemindersByPeriod(list, modalPeriodFilter.value);
});
const modalTodayCount = computed(() => Math.ceil(filteredModalDueToday.value.length / itemsPerPage) || 1);
const paginatedModalToday = computed(() => {
    const start = (modalPageToday.value - 1) * itemsPerPage;
    return filteredModalDueToday.value.slice(start, start + itemsPerPage);
});

// --- FILTRAGEM DA CENTRAL DE COBRANÇAS DO DASHBOARD ---
const visibleDashboardOverdue = computed(() => {
    if (dashboardCobrançaFilter.value === 'today') return [];
    return financialReminders.value.overdue || [];
});
const dashOverdueCount = computed(() => Math.ceil(visibleDashboardOverdue.value.length / itemsPerPage) || 1);
const paginatedDashOverdue = computed(() => {
    const start = (dashPageOverdue.value - 1) * itemsPerPage;
    return visibleDashboardOverdue.value.slice(start, start + itemsPerPage);
});

const visibleDashboardDueToday = computed(() => {
    if (dashboardCobrançaFilter.value === 'overdue') return [];
    return financialReminders.value.dueToday || [];
});
const dashTodayCount = computed(() => Math.ceil(visibleDashboardDueToday.value.length / itemsPerPage) || 1);
const paginatedDashToday = computed(() => {
    const start = (dashPageToday.value - 1) * itemsPerPage;
    return visibleDashboardDueToday.value.slice(start, start + itemsPerPage);
});

// HELPER: Filtro de períodos dinâmico + Barreira 2026+
const filterRemindersByPeriod = (list: any[], period: string) => {
    const today = new Date();
    const boundary2026 = new Date('2026-01-01T00:00:00Z');

    return list.filter(item => {
        const itemDate = parseISO(item.due_date);
        if (isBefore(itemDate, boundary2026)) return false; // BARREIRA ABSOLUTA

        if (period === 'day') return isToday(itemDate);
        if (period === 'week') {
            return isWithinInterval(itemDate, { start: startOfWeek(today, { weekStartsOn: 1 }), end: endOfWeek(today, { weekStartsOn: 1 }) });
        }
        if (period === 'month') {
            return isWithinInterval(itemDate, { start: startOfMonth(today), end: endOfMonth(today) });
        }
        return true;
    });
};

// --- HELPER FUNCTIONS ---
const getInitials = (name: string) => { if (!name) return 'V'; const parts = name.split(' '); if (parts.length >= 2) return `${parts[0][0]}${parts[1][0]}`.toUpperCase(); return name.substring(0, 2).toUpperCase(); };
const formatDate = (dateStr: string) => dateStr ? format(parseISO(dateStr), 'dd/MM/yyyy') : '';
const formatCurrency = (val: number) => new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(val || 0);
const formatTimeAgo = (dateStr: string) => dateStr ? formatDistanceToNow(parseISO(dateStr), { addSuffix: true, locale: ptBR }).replace('aproximadamente ', '') : '';
const firstName = (name: string) => name ? name.split(' ')[0] : 'Vendedor';
const formatMeters = (value: number) => Number(value || 0).toLocaleString('pt-BR', { maximumFractionDigits: 0 });
const goToApprovals = () => { router.push({ name: 'Approvals' }); };

const cobrarWhatsapp = (inst: any) => {
    const msg = `Olá! Notamos que a parcela ${inst.installment_number}/${inst.total_installments} referente ao Pedido #${String(inst.order_number).padStart(4, '0')} encontra-se em aberto no valor de ${formatCurrency(inst.value)}. Podemos ajudar com o envio do link de Pix para regularização?`;
    window.open(`https://wa.me/?text=${encodeURIComponent(msg)}`, '_blank');
};

const openEditor = async () => {
  loadingEditorToken.value = true; editorError.value = null;
  try {
    const { error: sessionError } = await supabase.auth.refreshSession(); if (sessionError) throw sessionError;
    const { data, error } = await supabase.functions.invoke('generate-editor-token'); if (error) throw error;
    if (data.token) window.open(`https://mjmockups.onrender.com?token=${data.token}`, '_blank');
  } catch (error: any) { editorError.value = "Erro ao acessar editor."; } finally { loadingEditorToken.value = false; }
};

const updateClock = () => {
    const now = new Date();
    currentTime.value = format(now, 'HH:mm:ss');
    currentDate.value = format(now, "EEE, d MMM", { locale: ptBR }).toUpperCase();
};

// --- FETCH DATA CENTRALIZADO ---
const fetchDashboardData = async () => {
    loadingData.value = true;
    try {
        const userId = userStore.profile?.id;
        if (!userId) return;

        const { start, end } = dateRange.value;
        const startIso = start.toISOString();
        const endIso = end.toISOString();

        const { data: orders } = await supabase
            .from('orders')
            .select('id, quantity_meters, total_value, created_at, customer_name, order_number, order_items(status)')
            .eq('created_by', userId)
            .gte('created_at', startIso)
            .lte('created_at', endIso)
            .neq('status', 'cancelled');

        if (orders) {
            const totalM = orders.reduce((acc, o) => acc + (Number(o.quantity_meters) || 0), 0);
            const totalO = orders.length;

            pendingApprovalsCount.value = orders.filter(o => o.order_items && o.order_items.some((i: any) => i.status === 'customer_approval')).length;
            recentSales.value = [...orders].sort((a,b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime()).slice(0, 5);

            dashboardMetrics.value = {
                totalMeters: totalM,
                totalOrders: totalO,
                averageMeters: totalO > 0 ? totalM / totalO : 0,
                goalPercentage: periodFilter.value === 'year' ? Math.min((totalM / 42000) * 100, 100) : Math.min((totalM / 3500) * 100, 100),
                newClients: 0
            };
        }

        const { data: itemsData } = await supabase
            .from('order_items')
            .select('quantity_meters, fabric_type, orders!inner(created_by, created_at, status)')
            .eq('orders.created_by', userId)
            .neq('orders.status', 'cancelled')
            .gte('orders.created_at', startIso)
            .lte('orders.created_at', endIso);

        const fMap = new Map();
        itemsData?.forEach(item => {
            const name = item.fabric_type || 'Diversos/Outros';
            const meters = Number(item.quantity_meters) || 0;
            if (meters > 0) { fMap.set(name, (fMap.get(name) || 0) + meters); }
        });
        topFabrics.value = Array.from(fMap.entries()).map(([name, volume]) => ({ name, volume })).sort((a,b) => b.volume - a.volume).slice(0, 5);

        // 3. CENTRAL DE COBRANÇAS
        const { data: openOrders } = await supabase
            .from('orders')
            .select('id, order_number, customer_name, financial_status, details, total_value, created_at')
            .eq('created_by', userId)
            .neq('status', 'cancelled')
            .in('financial_status', ['Em Aberto', 'Parcialmente Faturado', 'pending', 'partial', 'Aguardando Pagamento']);

        const todayMid = startOfDay(new Date());
        const boundary2026 = new Date('2026-01-01T00:00:00Z');
        const overdueList: any[] = [];
        const todayList: any[] = [];

        openOrders?.forEach(order => {
            let pendingInstallments: any[] = [];
            const schedule = order.details?.installments || order.details?.installments_schedule;

            if (schedule && Array.isArray(schedule)) {
                pendingInstallments = schedule.filter((i:any) => {
                    const st = String(i.status).toLowerCase();
                    return st !== 'paid' && st !== 'pago' && st !== 'faturado';
                });
            }

            if (pendingInstallments.length > 0) {
                pendingInstallments.forEach((inst:any, idx:number) => {
                    if (!inst.due_date) return;
                    const dDate = startOfDay(parseISO(inst.due_date));

                    if (isBefore(dDate, boundary2026)) return;

                    const payload = {
                        id: `${order.id}-${idx}`,
                        order_number: order.order_number,
                        customer_name: order.customer_name,
                        due_date: inst.due_date,
                        value: inst.value || 0,
                        installment_number: idx + 1,
                        total_installments: schedule.length
                    };
                    if (isBefore(dDate, todayMid)) overdueList.push(payload);
                    else if (isEqual(dDate, todayMid)) todayList.push(payload);
                });
            } else {
                const fallbackDate = order.details?.forecast_delivery_date || order.created_at;
                const dDate = startOfDay(parseISO(fallbackDate));

                if (isBefore(dDate, boundary2026)) return;

                const payload = {
                    id: order.id,
                    order_number: order.order_number,
                    customer_name: order.customer_name,
                    due_date: fallbackDate,
                    value: order.total_value || 0,
                    installment_number: 1,
                    total_installments: 1
                };
                if (isBefore(dDate, todayMid)) overdueList.push(payload);
                else if (isEqual(dDate, todayMid)) todayList.push(payload);
            }
        });

        // ORDENAÇÃO ASCENDENTE: Mais Velhos (venceram a mais tempo) PRIMEIRO, depois os mais novos.
        overdueList.sort((a,b) => new Date(a.due_date).getTime() - new Date(b.due_date).getTime());
        todayList.sort((a,b) => new Date(a.due_date).getTime() - new Date(b.due_date).getTime());

        financialReminders.value = { overdue: overdueList, dueToday: todayList };

        if (overdueList.length > 0 || todayList.length > 0) {
            showRemindersDialog.value = true;
        }

    } catch (error) {
        console.error("Erro ao buscar dados do dashboard:", error);
    } finally {
        loadingData.value = false;
    }
};

// --- CHART DATA E MAPAS ---
const salesChartData = computed(() => {
    const daysInMonth = 30;
    const labels = [] as string[];
    const dataArea = new Array(daysInMonth).fill(0);
    const pStart = new Date(); pStart.setDate(pStart.getDate() - 30);

    for (let i = 0; i < daysInMonth; i++) {
        const d = new Date(pStart); d.setDate(d.getDate() + i);
        labels.push(format(d, 'dd/MM'));
    }

    (salesStore.orders || []).filter(o => o.created_by?.id === userStore.profile?.id).forEach(o => {
        if (!o.created_at) return;
        const date = new Date(o.created_at);
        if (date >= pStart) {
             const dayDiff = differenceInDays(date, pStart);
             if (dayDiff >= 0 && dayDiff < daysInMonth) { dataArea[dayDiff] += Number(o.quantity_meters) || 0; }
        }
    });

    return {
        labels,
        datasets: [{
            label: 'Volume (m)',
            backgroundColor: 'rgba(230, 81, 0, 0.4)', // Foxie Amber
            borderColor: '#E65100',
            borderWidth: 1.5,
            data: dataArea.map(v => Number(v.toFixed(1)))
        }]
    };
});

const chartOptions = computed(() => ({
  responsive: true, maintainAspectRatio: false,
  plugins: { legend: { display: false } },
  scales: {
    y: { beginAtZero: true, grid: { color: isDark.value ? 'rgba(255, 255, 255, 0.04)' : 'rgba(0,0,0,0.03)' }, ticks: { color: isDark.value ? '#9E9E9E' : '#616161', font: { size: 10 } } },
    x: { grid: { display: false }, ticks: { color: isDark.value ? '#9E9E9E' : '#616161', font: { size: 10 } } },
  },
}));

const filteredSellerRanking = computed(() => [...(salesStore.sellerRanking || [])].sort((a, b) => b.area - a.area));
const sellerToRegionMap: Record<string, 'sudeste' | 'nordeste'> = { 'Beatriz Garcia': 'sudeste', 'Marcos Levi': 'sudeste', 'Juci': 'sudeste', 'Elda': 'nordeste', 'Sueli': 'nordeste', 'Fernanda Garcia': 'sudeste', 'João Vitor': 'sudeste', 'Ana Júlia': 'sudeste', 'Adjane Katia': 'sudeste' };

const salesByRegion = computed(() => {
    const regionMap: { [key: string]: number } = { 'Sudoeste': 0, 'Nordeste': 0 };
    (salesStore.orders || []).filter(o => o.created_by?.id === userStore.profile?.id).forEach(order => {
        let sellerName = userStore.profile?.full_name;
        if (sellerName && sellerToRegionMap[sellerName]) {
             const regionKey = sellerToRegionMap[sellerName] === 'sudeste' ? 'Sudoeste' : 'Nordeste';
             regionMap[regionKey] += (Number(order.quantity_meters) || 0);
        }
    });
    return regionMap as { Sudoeste: number; Nordeste: number; };
});

const sellersByRegion = computed(() => {
    const regions: { nordeste: string[], sudeste: string[] } = { nordeste: [], sudeste: [] };
    const myName = userStore.profile?.full_name;
    if(myName && sellerToRegionMap[myName]) regions[sellerToRegionMap[myName]].push(myName);
    return regions;
});

onMounted(async () => {
  updateClock(); clockInterval = setInterval(updateClock, 1000);
  await salesStore.fetchData();
  await fetchDashboardData();
});
onUnmounted(() => clearInterval(clockInterval));
</script>

<style scoped lang="scss">
/* DESIGN SYSTEM INTEGRADO: SQUARED & REALISTIC 3D SHADOWS */
.squared-ui, .squared-ui :deep(.v-field), .squared-ui :deep(.v-card) { border-radius: 2px !important; }

.btn-3d {
    border-radius: 2px !important;
    box-shadow: 0 4px 6px rgba(0,0,0,0.12), inset 0 1px 0 rgba(255,255,255,0.2) !important;
    transition: all 0.15s ease;
}
.btn-3d:active { transform: translateY(1px); box-shadow: 0 2px 3px rgba(0,0,0,0.1) !important; }

.chip-3d { border-radius: 2px !important; box-shadow: 0 3px 5px rgba(0,0,0,0.1) !important; text-shadow: 0 1px 1px rgba(0,0,0,0.2); }

/* Paleta Foxie */
.bg-foxie { background-color: #E65100 !important; }
.text-foxie { color: #E65100 !important; }
.shadow-foxie { box-shadow: 0 4px 15px rgba(230, 81, 0, 0.25) !important; }

.animate-fade-in-down { animation: fadeInDown 0.5s cubic-bezier(0.25, 0.8, 0.25, 1); }
.animate-fade-in-up { animation: fadeInUp 0.5s cubic-bezier(0.25, 0.8, 0.25, 1) backwards; }
@keyframes fadeInDown { from { opacity: 0; transform: translateY(-10px); } to { opacity: 1; transform: translateY(0); } }
@keyframes fadeInUp { from { opacity: 0; transform: translateY(10px); } to { opacity: 1; transform: translateY(0); } }
.blink { animation: blink 2.5s infinite; }
@keyframes blink { 0%, 100% { opacity: 1; } 50% { opacity: 0.5; } }

/* Controls Segmentados */
.segmented-control { display: flex; padding: 2px; border-radius: 2px; gap: 2px; }
.seg-light { background: #f0f0f0; border: 1px solid #e0e0e0; }
.seg-dark { background: rgba(255,255,255,0.04); border: 1px solid rgba(255,255,255,0.06); }
.seg-item { flex: 1; text-align: center; padding: 5px 12px; font-size: 11px; font-weight: 900; text-transform: uppercase; border-radius: 1px; cursor: pointer; transition: all 0.15s; color: #757575; }
.seg-dark .seg-item { color: #9e9e9e; }
.seg-light .seg-item:hover { color: #212121; }
.seg-light .seg-active { background: #ffffff; color: #E65100; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
.seg-dark .seg-active { background: #E65100; color: #ffffff; box-shadow: 0 2px 6px rgba(0,0,0,0.3); }

.icon-box-lg { width: 44px; height: 44px; }
.icon-box-sm { width: 34px; height: 34px; display: flex; align-items: center; justify-content: center; }

.custom-scroll::-webkit-scrollbar { width: 6px; height: 6px; }
.custom-scroll::-webkit-scrollbar-track { background: transparent; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128, 128, 128, 0.25); border-radius: 3px; }

/* KPIs */
.kpi-card { height: 110px; border-radius: 2px !important; padding: 16px; position: relative; overflow: hidden; cursor: pointer; transition: all 0.2s ease; border: 1px solid rgba(255,255,255,0.05); }
.kpi-card:hover { transform: translateY(-3px); filter: brightness(1.05); }
.kpi-bg-icon { position: absolute; right: -15px; bottom: -15px; opacity: 0.12; transform: rotate(-15deg); pointer-events: none; }
.kpi-bg-icon .v-icon { font-size: 90px; color: white; }
.kpi-label { font-size: 11px; font-weight: 900; text-transform: uppercase; letter-spacing: 0.5px; }
.kpi-number-group { display: flex; align-items: baseline; line-height: 1; margin-top: 4px; }
.kpi-value { font-size: 24px; font-weight: 900; }
.kpi-unit { font-size: 11px; font-weight: 700; margin-left: 2px; }
.kpi-footer { font-size: 9px; background: rgba(0,0,0,0.15); padding: 1px 6px; border-radius: 2px; width: fit-content; font-weight: bold; }

.bg-gradient-info { background: linear-gradient(135deg, #0288d1, #01579b); }
.bg-gradient-purple { background: linear-gradient(135deg, #673ab7, #4527a0); }
.bg-gradient-orange { background: linear-gradient(135deg, #f57c00, #e65100); }
.bg-gradient-teal { background: linear-gradient(135deg, #00897b, #004d40); }
.bg-gradient-blue { background: linear-gradient(135deg, #1565c0, #0d47a1); }

/* Podium Layout */
.podium-container { display: flex; align-items: flex-end; justify-content: center; gap: 8px; height: 100%; width: 100%; }
.podium-item { display: flex; flex-direction: column; align-items: center; width: 32%; position: relative; }
.podium-avatar-wrapper { position: relative; border-radius: 2px; padding: 2px; margin-bottom: 6px; background: #e0e0e0; }
.rank-badge { position: absolute; bottom: -4px; right: -4px; width: 20px; height: 20px; border-radius: 50%; color: white; font-weight: 900; font-size: 11px; display: flex; align-items: center; justify-content: center; border: 1px solid white; }
.crown-icon { position: absolute; top: -14px; left: 50%; transform: translateX(-50%); font-size: 16px; }

.badge-gold { background: #ffb300; } .badge-silver { background: #b0bec5; } .badge-bronze { background: #b08d57; }
.podium-bar { width: 100%; border-radius: 2px 2px 0 0; opacity: 0.95; }
.bar-gold { height: 100px; background: #ffb300; } .bar-silver { height: 65px; background: #cfd8dc; } .bar-bronze { height: 40px; background: #d7ccc8; }
.rank-1 { order: 2; z-index: 2; } .rank-2 { order: 1; z-index: 1; } .rank-3 { order: 3; z-index: 1; }

.btn-rect { border-radius: 2px !important; text-transform: none !important; }
.border-thin { border: 1px solid rgba(128,128,128,0.12) !important; }
.glass-panel { background: rgba(255, 255, 255, 0.9); }
.bg-background-app .bg-grey-darken-4 .glass-panel { background: #1e1e24 !important; }
.shadow-up { box-shadow: 0 -3px 10px rgba(0,0,0,0.04); }
.hover-opacity-100:hover { opacity: 1 !important; }
.hover-overlay:hover { background: rgba(128,128,128,0.05) !important; transition: background 0.3s ease; }
</style>
