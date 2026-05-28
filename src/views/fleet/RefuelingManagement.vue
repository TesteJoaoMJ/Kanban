<template>
  <div
    class="fleet-layout font-sans fill-height d-flex flex-column relative overflow-hidden"
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
          v-if="!isMobileFullscreen"
          class="header-bar px-4 py-3 px-md-6 py-md-4 d-flex flex-column flex-md-row align-md-center justify-space-between flex-shrink-0"
          :class="themeStore.currentMode === 'light' ? 'bg-white border-b border-grey-lighten-2 shadow-sm' : 'bg-glass-header border-bottom-white-05'"
          style="gap: 12px;"
        >
          <div class="d-flex flex-column">
            <div class="breadcrumb text-caption d-none d-md-block">
              <span class="opacity-70">Logística</span>
              <span class="mx-2 opacity-50">></span>
              <span class="font-weight-bold">Frota</span>
            </div>
            <div class="d-flex align-center gap-2 mt-1">
               <div class="text-h6 font-weight-black tracking-tight leading-none" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">
                  Controle de Abastecimento
               </div>
            </div>
          </div>

          <div class="d-flex align-center overflow-x-auto pb-1 pb-md-0" style="gap: 10px;">
            <div class="d-flex align-center gap-1 mr-4 bg-grey-lighten-4 rounded-lg px-2 border-thin shadow-sm">
                <v-btn icon size="small" density="compact" variant="text" @click="changeMonth(-1)"><v-icon>mdi-chevron-left</v-icon></v-btn>
                <span class="text-caption font-weight-black uppercase text-center text-grey-darken-3" style="min-width: 90px;">{{ currentMonthLabel }}</span>
                <v-btn icon size="small" density="compact" variant="text" @click="changeMonth(1)"><v-icon>mdi-chevron-right</v-icon></v-btn>
            </div>

            <v-btn
              color="amber-darken-3"
              variant="flat"
              class="btn-3d px-3 px-md-4 font-weight-bold text-caption text-uppercase letter-spacing-1 flex-shrink-0 shadow-button"
              prepend-icon="mdi-plus"
              height="40"
              @click="openRequestDialog"
            >
               Novo Voucher
            </v-btn>
          </div>
        </div>

        <div v-if="!isMobileFullscreen" class="px-4 px-md-6 py-2 flex-shrink-0">
          <v-row class="d-none d-md-flex">
            <v-col cols="12" sm="6" md="" v-for="(kpi, idx) in kpiList" :key="idx">
              <v-card
                class="kpi-card kpi-rect bg-gradient-custom hover-elevate py-3 px-4 cursor-pointer"
                :class="[kpi.gradient]"
                v-ripple
                elevation="2"
              >
                <div class="kpi-bg-icon"><v-icon>{{ kpi.icon }}</v-icon></div>
                <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                  <div class="d-flex align-center" style="gap: 8px;">
                    <v-icon size="18" class="opacity-80">{{ kpi.icon }}</v-icon>
                    <span class="kpi-label">{{ kpi.label }}</span>
                  </div>
                  <div class="kpi-number-group my-1">
                    <span class="text-body-2 font-weight-medium mr-1 opacity-70" v-if="kpi.isMoney">R$</span>
                    <span class="kpi-value">{{ kpi.value }}</span>
                  </div>
                  <div class="kpi-footer mt-1">{{ kpi.footer }}</div>
                </div>
              </v-card>
            </v-col>
          </v-row>

          <div class="d-block d-md-none kpi-mobile-wrapper my-2">
            <v-window v-model="kpiModel" show-arrows class="elevation-4 rounded-xl overflow-hidden shadow-lg">
               <template v-slot:prev="{ props }"><v-btn variant="flat" icon="mdi-chevron-left" @click="props.onClick" color="rgba(0,0,0,0.3)" size="small" class="text-white backdrop-blur-sm"></v-btn></template>
               <template v-slot:next="{ props }"><v-btn variant="flat" icon="mdi-chevron-right" @click="props.onClick" color="rgba(0,0,0,0.3)" size="small" class="text-white backdrop-blur-sm"></v-btn></template>
               <v-window-item v-for="(kpi, idx) in kpiList" :key="idx">
                  <v-card class="kpi-card-mobile d-flex flex-column align-center justify-center py-6 px-4 text-center relative" :class="[kpi.gradient]" height="140" elevation="0" v-ripple>
                      <div class="kpi-bg-icon-mobile"><v-icon>{{ kpi.icon }}</v-icon></div>
                      <div class="d-flex flex-column align-center relative z-10 w-100">
                          <div class="d-flex align-center justify-center mb-1 bg-white-20 px-3 py-1 rounded-pill backdrop-blur-sm" style="max-width: 80%;">
                              <v-icon size="16" class="mr-2 text-white">{{ kpi.icon }}</v-icon>
                              <span class="text-caption font-weight-black text-uppercase text-white tracking-wide text-truncate">{{ kpi.label }}</span>
                          </div>
                          <div class="text-h3 font-weight-black text-white my-2 text-shadow-sm">
                             <span class="text-body-2 opacity-80 align-top mr-1" v-if="kpi.isMoney">R$</span>{{ kpi.value }}
                          </div>
                          <div class="text-caption text-white font-weight-medium opacity-90">{{ kpi.footer }}</div>
                      </div>
                  </v-card>
               </v-window-item>
            </v-window>
            <div class="d-flex justify-center mt-3 gap-2">
                <div v-for="(k, i) in kpiList" :key="i" class="kpi-dot transition-all rounded-circle cursor-pointer" :class="kpiModel === i ? 'bg-success w-3 h-3 elevation-2' : 'bg-grey-lighten-2 w-2 h-2 opacity-50'" @click="kpiModel = i"></div>
            </div>
          </div>
        </div>

        <div v-if="!isMobileFullscreen" class="px-4 px-md-6 pt-0 pb-2 flex-shrink-0">
          <div v-if="mobile" class="d-flex align-center gap-2">
               <v-btn color="amber-darken-3" variant="flat" class="btn-3d flex-shrink-0" height="44" icon="mdi-plus" @click="openRequestDialog"></v-btn>
               <div class="flex-grow-1 relative search-wrap rounded bg-white border d-flex align-center" style="height: 44px;">
                  <input v-model="search" type="text" placeholder="Buscar veículo..." class="clean-input w-100 h-100 px-3 font-weight-bold" style="outline: none;"/>
                  <v-icon size="small" class="mr-3 text-grey-darken-1">mdi-magnify</v-icon>
              </div>
          </div>
          <div v-else class="controls-bar d-flex flex-column" :class="themeStore.currentMode === 'light' ? 'controls-light' : 'controls-dark'" style="gap: 10px;">
            <div class="d-flex flex-column flex-md-row align-start align-md-center justify-space-between" style="gap: 10px;">
              <div class="d-flex align-center flex-wrap w-100 w-md-auto" style="gap: 10px;">
                 <span class="text-caption font-weight-bold opacity-70 ml-2">Visualize as requisições do mês selecionado acima.</span>
              </div>
              <div class="d-flex align-center flex-wrap justify-end w-100 w-md-auto" style="gap: 10px;">
                <div class="search-wrap d-flex align-center flex-grow-1 flex-md-grow-0" :class="themeStore.currentMode === 'light' ? 'search-light' : 'search-dark'">
                  <v-icon :color="themeStore.currentMode === 'light' ? 'grey-darken-1' : 'white-70'">mdi-magnify</v-icon>
                  <input v-model="search" type="text" placeholder="Filtrar veículo ou motorista..." class="clean-input flex-grow-1" />
                </div>
              </div>
            </div>
          </div>
        </div>

        <div
          class="flex-grow-1 overflow-hidden d-flex flex-column transition-all"
          :class="isMobileFullscreen ? 'absolute top-0 left-0 w-100 h-100 z-20 bg-white' : 'px-4 px-md-6 pb-4'"
        >
          <v-card
            class="flex-grow-1 d-flex flex-column rounded-0 border-thin overflow-hidden"
            :class="themeStore.currentMode === 'light' ? 'bg-white shadow-sm' : 'glass-card border-white-05'"
            :elevation="0"
          >
            <div v-if="!mobile" class="grid-scroll flex-grow-1 overflow-auto custom-scroll relative">
              <div
                class="grid-header sticky-head"
                :class="[themeStore.currentMode === 'light' ? 'grid-surface-light' : 'grid-surface-dark', 'grid-refueling']"
              >
                <div class="cell center header-text">Req. Nº</div>
                <div class="cell center header-text">Data</div>
                <div class="cell header-text">Veículo / Motorista</div>
                <div class="cell center header-text">Valor</div>
                <div class="cell center header-text">Status</div>
                <div class="cell center header-text">Ações</div>
              </div>

              <div v-if="loading" class="d-flex flex-column justify-center align-center h-100 py-10 min-w-full">
                <v-progress-circular indeterminate color="amber-darken-3" size="32" width="3"></v-progress-circular>
                <span class="text-caption mt-2 font-weight-bold opacity-60">Carregando...</span>
              </div>

              <div v-else-if="filteredMonthlyRefuelings.length === 0" class="d-flex flex-column justify-center align-center h-100 opacity-60 gap-2 py-10 min-w-full">
                <v-icon size="48" color="grey-lighten-1">mdi-gas-station-off</v-icon>
                <span class="text-body-2 font-weight-medium text-grey">Nenhum abastecimento no período.</span>
              </div>

              <div
                v-else
                v-for="(item, index) in filteredMonthlyRefuelings"
                :key="item.id"
                class="grid-row"
                :class="[
                  themeStore.currentMode === 'light' ? 'grid-row-light' : 'grid-row-dark',
                  zebraClass(index),
                  'grid-refueling'
                ]"
              >
                  <div class="cell center">
                      <span class="pill-ref text-blue-grey-darken-3 bg-blue-grey-lighten-5">#{{ item.request_number }}</span>
                  </div>
                  <div class="cell center">
                      <span class="list-text-11 font-mono font-weight-medium">{{ formatDateSafe(item.created_at) }}</span>
                  </div>
                  <div class="cell d-flex flex-column align-start justify-center" style="line-height: 1.2;">
                      <div class="text-truncate list-text-11 font-weight-bold text-grey-darken-4">
                          <v-icon size="12" class="mr-1" color="grey-darken-1">mdi-car</v-icon>
                          {{ item.vehicle?.plate }} - {{ item.vehicle?.model }}
                      </div>
                      <div class="text-caption opacity-70 mt-1">
                          <v-icon size="12" class="mr-1" color="grey-darken-1">mdi-account</v-icon>
                          {{ item.driver_name }}
                      </div>
                  </div>
                  <div class="cell center">
                      <span class="list-text-11 font-mono font-weight-black" :class="item.status === 'concluido' ? 'text-success' : 'text-amber-darken-3'">
                          {{ item.status === 'concluido' ? formatCurrency(item.approved_amount) : formatCurrency(item.requested_amount) + '*' }}
                      </span>
                  </div>
                  <div class="cell center">
                      <span class="solid-chip chip-3d" :class="getStatusChipClass(item.status)">{{ item.status }}</span>
                  </div>
                  <div class="cell center">
                      <div class="actions-inline">
                         <template v-if="item.status === 'pendente'">
                            <v-btn icon size="small" class="action-btn bg-blue-grey-darken-2 btn-3d" @click="generateVoucherPDF(item)" title="Imprimir Voucher" variant="flat">
                                <v-icon size="16">mdi-printer</v-icon>
                            </v-btn>
                            <v-btn icon size="small" class="action-btn action-pay btn-3d" @click="openFinishDialog(item)" title="Baixar Pedido (Concluir)" variant="flat">
                                <v-icon size="16">mdi-check</v-icon>
                            </v-btn>
                         </template>

                         <template v-else>
                            <v-btn v-if="item.receipt_url" icon size="small" class="action-btn action-edit btn-3d bg-info" @click="viewReceipt(item.receipt_url)" title="Ver Nota Fiscal" variant="flat">
                                <v-icon size="16">mdi-receipt-text</v-icon>
                            </v-btn>

                            <v-btn
                                icon size="small" variant="flat"
                                class="action-btn btn-3d"
                                :class="item.financial_integrated ? 'bg-success' : 'bg-warning'"
                                :disabled="item.financial_integrated"
                                @click="integrateWithFinance(item)"
                                :title="item.financial_integrated ? 'Lançado no Financeiro' : 'Lançar no Contas a Pagar'"
                            >
                                <v-icon size="16">{{ item.financial_integrated ? 'mdi-cash-check' : 'mdi-cash-minus' }}</v-icon>
                            </v-btn>
                         </template>
                      </div>
                  </div>
              </div>
            </div>

            <div v-else class="flex-grow-1 overflow-y-auto bg-grey-lighten-4 pb-12 custom-scroll">
                <div v-if="loading" class="d-flex flex-column align-center justify-center py-8"><v-progress-circular indeterminate color="amber-darken-3"></v-progress-circular></div>
                <div v-else-if="filteredMonthlyRefuelings.length === 0" class="d-flex flex-column align-center justify-center py-10 opacity-60"><v-icon size="40">mdi-gas-station-off</v-icon></div>
                <div v-else class="d-flex flex-column gap-3 pa-3">
                   <div
                      v-for="(item, index) in filteredMonthlyRefuelings"
                      :key="item.id"
                      class="bg-white rounded-lg border-thin pa-4 elevation-1 relative overflow-hidden"
                   >
                      <div class="d-flex justify-space-between align-center mb-3">
                          <div class="d-flex align-center gap-2">
                              <v-chip size="x-small" color="grey-lighten-3" class="font-weight-black text-grey-darken-3 chip-3d">#{{ item.request_number }}</v-chip>
                          </div>
                          <v-chip size="small" :color="item.status === 'concluido' ? 'success' : 'warning'" variant="flat" class="font-weight-black text-white text-uppercase px-2 chip-3d" style="height: 20px; font-size: 10px;">
                               {{ item.status }}
                          </v-chip>
                      </div>

                      <div class="mb-3">
                          <div class="text-subtitle-2 font-weight-black text-grey-darken-4 leading-tight mb-1">{{ item.vehicle?.plate }} - {{ item.vehicle?.model }}</div>
                          <div class="text-caption text-grey"><v-icon size="12" class="mr-1">mdi-account</v-icon>{{ item.driver_name }}</div>
                      </div>

                      <div class="d-flex align-end justify-space-between mt-2 mb-3">
                           <div class="d-flex flex-column">
                               <span class="text-[10px] font-weight-bold text-grey uppercase tracking-wide">Data</span>
                               <div class="text-body-2 font-mono font-weight-bold d-flex align-center text-grey-darken-2">
                                   <v-icon size="14" class="mr-1">mdi-calendar</v-icon>
                                   {{ formatDateSafe(item.created_at) }}
                               </div>
                           </div>

                           <div class="text-right">
                               <span class="text-[10px] font-weight-bold text-grey uppercase tracking-wide">Valor</span>
                               <div class="text-h6 font-weight-black leading-none" :class="item.status === 'concluido' ? 'text-success-darken-2' : 'text-amber-darken-3'">
                                  {{ item.status === 'concluido' ? formatCurrency(item.approved_amount) : formatCurrency(item.requested_amount) }}
                               </div>
                           </div>
                      </div>

                      <v-divider class="mb-3 border-opacity-50"></v-divider>

                      <div class="d-flex gap-2">
                           <template v-if="item.status === 'pendente'">
                              <v-btn class="flex-grow-1 font-weight-bold btn-3d text-white" variant="flat" color="blue-grey-darken-2" height="36" @click="generateVoucherPDF(item)">
                                  <v-icon size="18" class="mr-1">mdi-printer</v-icon> Imprimir
                              </v-btn>
                              <v-btn class="flex-grow-1 font-weight-bold btn-3d text-white" variant="flat" color="success" height="36" @click="openFinishDialog(item)">
                                  <v-icon size="18" class="mr-1">mdi-check</v-icon> Baixar
                              </v-btn>
                           </template>
                           <template v-else>
                              <v-btn v-if="item.receipt_url" class="flex-grow-1 font-weight-bold btn-3d text-white" variant="flat" color="info" height="36" @click="viewReceipt(item.receipt_url)">
                                  <v-icon size="18" class="mr-1">mdi-receipt-text</v-icon> Ver Nota
                              </v-btn>
                              <v-btn class="flex-grow-1 font-weight-bold btn-3d text-white" variant="flat" :color="item.financial_integrated ? 'success' : 'warning'" height="36" :disabled="item.financial_integrated" @click="integrateWithFinance(item)">
                                  <v-icon size="18" class="mr-1">{{ item.financial_integrated ? 'mdi-cash-check' : 'mdi-cash-minus' }}</v-icon>
                                  {{ item.financial_integrated ? 'Integrado' : 'Lançar' }}
                              </v-btn>
                           </template>
                      </div>
                   </div>
                </div>
            </div>
          </v-card>
        </div>
    </div>

    <v-dialog
        v-model="requestDialog"
        max-width="900px"
        persistent
        scrim="black opacity-80"
        transition="dialog-bottom-transition"
        class="fixed-dialog"
    >
        <v-card class="d-flex overflow-hidden rounded-0 h-100 font-sans border border-grey-darken-2 bg-grey-lighten-4 flex-column flex-md-row" elevation="24">
            <div class="sidebar-menu d-flex flex-column flex-shrink-0 bg-grey-darken-4 text-white border-r border-grey-darken-3 shadow-md" style="width: 280px; z-index: 20;">
                <div class="pa-6 d-flex flex-column align-center text-center border-b border-white-10 relative h-100">
                    <v-btn icon size="x-small" variant="text" color="white" class="absolute top-2 right-2 d-md-none rounded-0" @click="requestDialog = false"><v-icon>mdi-close</v-icon></v-btn>

                    <v-avatar size="90" class="rounded-0 border-white-20 bg-amber-darken-3 transition-all mb-4 mt-4 shadow-lg">
                        <v-icon size="45" color="white">mdi-gas-station</v-icon>
                    </v-avatar>

                    <h3 class="text-subtitle-1 font-weight-black leading-tight mb-1 text-white uppercase">REQUISIÇÃO DE ABASTECIMENTO</h3>
                    <div class="text-[11px] font-weight-bold text-grey-lighten-1 text-uppercase tracking-widest mb-3">
                        Emissão de Voucher Autorizado
                    </div>

                    <div class="mt-auto pt-6 text-left w-100 opacity-60 text-caption font-italic">
                        * O voucher deve ser entregue impresso ao posto conveniado para validação.
                    </div>
                </div>
            </div>

            <div class="flex-grow-1 d-flex flex-column overflow-hidden relative bg-white">
                <div class="px-6 py-4 d-flex justify-space-between align-center border-b border-grey-lighten-2 bg-grey-lighten-5 flex-shrink-0 z-10 shadow-sm">
                    <div class="text-subtitle-1 font-weight-black text-uppercase text-grey-darken-4 d-flex align-center gap-2 tracking-widest">
                        <v-icon color="amber-darken-3" size="20">mdi-file-document-edit</v-icon>
                        DADOS DA SOLICITAÇÃO
                    </div>
                </div>

                <div class="flex-grow-1 overflow-y-auto pa-6 custom-scroll">
                    <v-form @submit.prevent id="requestForm">
                        <v-row dense class="row-gap">
                            <v-col cols="12" md="6">
                                <label class="input-label">Veículo (Placa - Modelo) *</label>
                                <v-autocomplete v-model="newRequest.vehicle_id" :items="vehicles" item-title="plate" item-value="id" variant="outlined" density="compact" color="amber-darken-3" class="ui-field font-weight-bold" @update:model-value="onVehicleSelect">
                                    <template v-slot:item="{ props, item }">
                                        <v-list-item v-bind="props" :title="`${item.raw.plate} - ${item.raw.model}`"></v-list-item>
                                    </template>
                                </v-autocomplete>
                            </v-col>
                            <v-col cols="12" md="6">
                                <label class="input-label">Motorista (Auto-preenchido)</label>
                                <v-text-field v-model="newRequest.driver_name" variant="outlined" density="compact" color="amber-darken-3" class="ui-field bg-grey-lighten-4" readonly></v-text-field>
                            </v-col>
                            <v-col cols="12" md="6">
                                <label class="input-label">Valor Autorizado (R$) *</label>
                                <v-text-field v-model="newRequest.requested_amount" type="number" prefix="R$" variant="outlined" density="compact" color="amber-darken-3" class="ui-field font-mono font-weight-black"></v-text-field>
                            </v-col>
                            <v-col cols="12" md="6">
                                <label class="input-label">Tipo de Combustível *</label>
                                <v-select v-model="newRequest.fuel_type" :items="['Gasolina', 'Etanol', 'Diesel S10', 'Diesel S500']" variant="outlined" density="compact" color="amber-darken-3" class="ui-field font-weight-bold"></v-select>
                            </v-col>
                            <v-col cols="12">
                                <label class="input-label">Observações</label>
                                <v-textarea v-model="newRequest.notes" variant="outlined" density="compact" color="amber-darken-3" rows="2" class="ui-field"></v-textarea>
                            </v-col>
                        </v-row>
                    </v-form>
                </div>

                <div class="pa-4 border-t bg-grey-lighten-5 d-flex justify-end align-center flex-shrink-0" style="gap: 12px;">
                    <v-btn variant="outlined" class="btn-3d px-6 font-weight-bold text-body-2" height="42" @click="requestDialog = false">Cancelar</v-btn>
                    <v-btn color="amber-darken-3" variant="flat" class="btn-3d px-6 font-weight-black text-body-2" height="42" @click="createRequest"><v-icon start>mdi-check</v-icon> Gerar Voucher</v-btn>
                </div>
            </div>
        </v-card>
    </v-dialog>

    <v-dialog
        v-model="finishDialog"
        max-width="1000px"
        persistent
        scrim="black opacity-80"
        transition="dialog-bottom-transition"
        class="fixed-dialog"
    >
        <v-card class="d-flex overflow-hidden rounded-0 h-100 font-sans border border-grey-darken-2 bg-grey-lighten-4 flex-column flex-md-row" elevation="24">
            <div class="sidebar-menu d-flex flex-column flex-shrink-0 bg-grey-darken-4 text-white border-r border-grey-darken-3 shadow-md" style="width: 290px; z-index: 20;">
                <div class="pa-6 d-flex flex-column align-center text-center border-b border-white-10 relative">
                    <v-btn icon size="x-small" variant="text" color="white" class="absolute top-2 right-2 d-md-none rounded-0" @click="finishDialog = false"><v-icon>mdi-close</v-icon></v-btn>

                    <v-avatar size="90" class="rounded-0 border-white-20 bg-green-darken-3 transition-all mb-4 mt-2 shadow-lg">
                        <v-icon size="45" color="white">mdi-check-decagram</v-icon>
                    </v-avatar>

                    <h3 class="text-subtitle-1 font-weight-black leading-tight mb-1 text-white uppercase">BAIXA E CONFERÊNCIA</h3>
                    <div class="text-[11px] font-weight-bold text-grey-lighten-1 text-uppercase tracking-widest mb-3">
                        Voucher Autorizado
                    </div>

                    <div class="w-100 bg-white-10 pa-3 mt-2 border border-white-20 text-left">
                        <div class="text-[10px] font-weight-black text-grey-lighten-1 uppercase">Valor Liberado Inicial</div>
                        <div class="text-h5 font-weight-black font-mono text-green-accent-3">{{ formatCurrency(finishData.approved_amount) }}</div>
                    </div>
                </div>
            </div>

            <div class="flex-grow-1 d-flex flex-column overflow-hidden relative bg-white">
                <div class="px-6 py-4 d-flex justify-space-between align-center border-b border-grey-lighten-2 bg-grey-lighten-5 flex-shrink-0 z-10 shadow-sm">
                    <div class="text-subtitle-1 font-weight-black text-uppercase text-grey-darken-4 d-flex align-center gap-2 tracking-widest">
                        <v-icon color="green-darken-3" size="20">mdi-receipt-text-check</v-icon>
                        DADOS FISCAIS E QUILOMETRAGEM
                    </div>
                </div>

                <div class="flex-grow-1 overflow-y-auto pa-6 custom-scroll">
                    <v-form @submit.prevent id="finishForm">
                        <v-row dense class="row-gap">
                            <v-col cols="12">
                                <v-alert type="info" variant="tonal" density="compact" class="text-caption font-weight-bold mb-4 bg-blue-lighten-5">
                                    Preencha o valor EXATO cobrado na bomba (que consta na Nota Fiscal).
                                </v-alert>
                            </v-col>
                            <v-col cols="12" md="12">
                                <label class="input-label">Valor Efetivamente Pago (R$) *</label>
                                <v-text-field v-model="finishData.approved_amount" type="number" prefix="R$" variant="outlined" density="compact" color="green-darken-3" class="ui-field font-mono font-weight-black text-h6"></v-text-field>
                            </v-col>
                            <v-col cols="12" md="6">
                                <label class="input-label">Litros Abastecidos *</label>
                                <v-text-field v-model="finishData.liters" type="number" suffix="L" variant="outlined" density="compact" color="green-darken-3" class="ui-field font-mono font-weight-bold"></v-text-field>
                            </v-col>
                            <v-col cols="12" md="6">
                                <label class="input-label">Quilometragem (KM Atual) *</label>
                                <v-text-field v-model="finishData.km_at_refuel" type="number" suffix="KM" variant="outlined" density="compact" color="green-darken-3" class="ui-field font-mono font-weight-bold"></v-text-field>
                            </v-col>
                            <v-col cols="12">
                                <label class="input-label">Anexar Nota Fiscal / Cupom *</label>
                                <v-file-input v-model="receiptFile" variant="outlined" density="compact" prepend-inner-icon="mdi-camera" prepend-icon="" color="green-darken-3" class="ui-field font-weight-bold" accept="image/*,application/pdf"></v-file-input>
                            </v-col>
                        </v-row>
                    </v-form>
                </div>

                <div class="pa-4 border-t bg-grey-lighten-5 d-flex justify-end align-center flex-shrink-0" style="gap: 12px;">
                    <v-btn variant="outlined" class="btn-3d px-6 font-weight-bold text-body-2" height="42" @click="finishDialog = false">Cancelar</v-btn>
                    <v-btn color="green-darken-3" variant="flat" class="btn-3d px-6 font-weight-black text-body-2" height="42" :loading="finishing" @click="confirmFinish"><v-icon start>mdi-check-all</v-icon> Confirmar Baixa</v-btn>
                </div>
            </div>
        </v-card>
    </v-dialog>

    <v-dialog v-model="imageDialog" max-width="600">
       <v-img :src="selectedReceiptUrl" cover class="rounded-lg bg-grey-darken-4"></v-img>
    </v-dialog>

  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { supabase } from '@/api/supabase';
import { useUserStore } from '@/stores/user';
import { useAppStore } from '@/stores/app';
import { useThemeStore } from '@/stores/theme';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import QRCode from 'qrcode';
import { format, startOfMonth, endOfMonth, addMonths, parseISO } from 'date-fns';
import { ptBR } from 'date-fns/locale';
import { useDisplay } from 'vuetify';

const userStore = useUserStore();
const appStore = useAppStore();
const themeStore = useThemeStore();
const { mobile } = useDisplay();

// State
const loading = ref(false);
const refuelings = ref<any[]>([]);
const vehicles = ref<any[]>([]);
const search = ref('');
const isMobileFullscreen = ref(false);

const requestDialog = ref(false);
const finishDialog = ref(false);
const imageDialog = ref(false);
const finishing = ref(false);
const generatingPdfId = ref<string | null>(null);
const selectedReceiptUrl = ref('');
const receiptFile = ref<File[]>([]);
const currentMonthDate = ref(new Date());

const newRequest = ref({ vehicle_id: null, driver_name: '', requested_amount: '', fuel_type: 'Gasolina', notes: '' });
const finishData = ref({ id: '', approved_amount: '', liters: '', km_at_refuel: '' });

// Computed
const currentMonthLabel = computed(() => format(currentMonthDate.value, "MMM yyyy", { locale: ptBR }));

const filteredMonthlyRefuelings = computed(() => {
    const start = startOfMonth(currentMonthDate.value);
    const end = endOfMonth(currentMonthDate.value);
    let list = refuelings.value.filter(item => {
        const d = parseISO(item.created_at);
        return d >= start && d <= end;
    });

    if (search.value) {
        const term = search.value.toLowerCase();
        list = list.filter(v =>
            v.vehicle?.plate?.toLowerCase().includes(term) ||
            v.driver_name?.toLowerCase().includes(term)
        );
    }
    return list;
});

const monthlySpent = computed(() => filteredMonthlyRefuelings.value.filter(r => r.status === 'concluido').reduce((acc, curr) => acc + Number(curr.approved_amount || 0), 0));
const pendingRequests = computed(() => filteredMonthlyRefuelings.value.filter(r => r.status === 'pendente').length);
const totalLiters = computed(() => filteredMonthlyRefuelings.value.filter(r => r.status === 'concluido').reduce((acc, curr) => acc + Number(curr.liters || 0), 0).toFixed(1));
const averageCost = computed(() => {
    const concluded = filteredMonthlyRefuelings.value.filter(r => r.status === 'concluido');
    return concluded.length ? (monthlySpent.value / concluded.length) : 0;
});

// KPIs List
const kpiModel = ref(0);
const kpiList = computed(() => ([
  { label: 'Gasto Mensal', value: formatCurrency(monthlySpent.value), footer: 'Total confirmado', icon: 'mdi-cash-multiple', gradient: 'bg-gradient-info', isMoney: false },
  { label: 'Pedidos Pendentes', value: pendingRequests.value, footer: 'Aguardando baixa', icon: 'mdi-timer-sand', gradient: 'bg-gradient-purple', isMoney: false },
  { label: 'Volume Abastecido', value: `${totalLiters.value} L`, footer: 'Litros totais', icon: 'mdi-barrel', gradient: 'bg-gradient-green', isMoney: false },
  { label: 'Custo Médio', value: formatCurrency(averageCost.value), footer: 'Por abastecimento', icon: 'mdi-chart-line', gradient: 'bg-gradient-red', isMoney: false },
]));

// Helpers
const formatCurrency = (val: any) => new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(Number(val) || 0);
const formatDateSafe = (dateString: string) => { if (!dateString) return '-'; return dateString.split('T')[0].split('-').reverse().join('/'); };
const changeMonth = (amount: number) => { currentMonthDate.value = addMonths(currentMonthDate.value, amount); };

const getStatusChipClass = (status: string) => {
  if (status === 'concluido') return 'chip-success';
  if (status === 'pendente') return 'chip-warn';
  return 'chip-danger';
};
const getStatusDotClass = (status: string) => {
  if (status === 'concluido') return 'bg-success';
  if (status === 'pendente') return 'bg-warning pulse';
  return 'bg-grey';
};
const zebraClass = (i:number) => themeStore.currentMode!=='light' ? (i%2===0?'zebra-dark-a':'zebra-dark-b') : (i%2===0?'zebra-light-a':'zebra-light-b');

// API
const fetchData = async () => {
  loading.value = true;
  const { data: refData } = await supabase.from('fleet_refuelings').select('*, vehicle:vehicle_id(plate, model)').order('created_at', { ascending: false });
  if (refData) refuelings.value = refData;
  const { data: vehData } = await supabase.from('fleet_vehicles').select('id, plate, model, driver_name').eq('status', 'ativo');
  if (vehData) vehicles.value = vehData;
  loading.value = false;
};

const onVehicleSelect = (vehicleId: string) => {
  const veh = vehicles.value.find(v => v.id === vehicleId);
  if (veh) newRequest.value.driver_name = veh.driver_name;
};

// Actions
const openRequestDialog = () => {
    newRequest.value = { vehicle_id: null, driver_name: '', requested_amount: '', fuel_type: 'Gasolina', notes: '' };
    requestDialog.value = true;
}

const createRequest = async () => {
  if (!newRequest.value.vehicle_id || !newRequest.value.requested_amount) {
      appStore.showSnackbar('Preencha veículo e valor.', 'warning');
      return;
  }
  const { error } = await supabase.from('fleet_refuelings').insert([{
    vehicle_id: newRequest.value.vehicle_id,
    driver_name: newRequest.value.driver_name,
    requested_amount: parseFloat(newRequest.value.requested_amount),
    fuel_type: newRequest.value.fuel_type,
    notes: newRequest.value.notes,
    status: 'pendente'
  }]);
  if (!error) {
      requestDialog.value = false;
      appStore.showSnackbar('Requisição gerada.', 'success');
      fetchData();
  }
};

const openFinishDialog = (item: any) => {
  finishData.value = { id: item.id, approved_amount: item.requested_amount, liters: '', km_at_refuel: '' };
  receiptFile.value = [];
  finishDialog.value = true;
};

const confirmFinish = async () => {
  if(!finishData.value.approved_amount || !finishData.value.liters || !finishData.value.km_at_refuel || receiptFile.value.length === 0) {
      appStore.showSnackbar('Preencha todos os campos e anexe a nota.', 'warning');
      return;
  }

  finishing.value = true;
  let receiptUrl = null;
  if (receiptFile.value.length > 0) {
     const file = receiptFile.value[0];
     const fileName = `receipts/${Date.now()}-${file.name.replace(/\s/g, '_')}`;
     await supabase.storage.from('fleet-media').upload(fileName, file);
     const { data } = supabase.storage.from('fleet-media').getPublicUrl(fileName);
     receiptUrl = data.publicUrl;
  }
  await supabase.from('fleet_refuelings').update({
    status: 'concluido',
    approved_amount: parseFloat(finishData.value.approved_amount),
    liters: parseFloat(finishData.value.liters),
    km_at_refuel: parseInt(finishData.value.km_at_refuel),
    receipt_url: receiptUrl
  }).eq('id', finishData.value.id);

  finishing.value = false; finishDialog.value = false;
  appStore.showSnackbar('Baixa confirmada!', 'success');
  fetchData();
};

const viewReceipt = (url: string) => { selectedReceiptUrl.value = url; imageDialog.value = true; }

const integrateWithFinance = async (item: any) => {
    if(!confirm(`Lançar R$ ${formatCurrency(item.approved_amount)} no financeiro?`)) return;

    try {
        loading.value = true;
        const { error: errFin } = await supabase.from('finance_payables').insert({
            description: `Abastecimento - ${item.vehicle?.plate}`,
            value: item.approved_amount,
            due_date: format(new Date(), 'yyyy-MM-dd'),
            status: 'pending',
            origin_fleet_id: item.id,
            category: 'Combustível',
            notes: `Motorista: ${item.driver_name}. Litros: ${item.liters}`,
            installment_number: 1,
            total_installments: 1
        });

        if (errFin) throw errFin;

        await supabase.from('fleet_refuelings').update({ financial_integrated: true }).eq('id', item.id);
        item.financial_integrated = true;
        appStore.showSnackbar('Lançado com sucesso!', 'success');

    } catch (e: any) {
        appStore.showSnackbar('Erro: ' + e.message, 'error');
    } finally {
        loading.value = false;
    }
};

// --- PDF VOUCHER FIX ---
const generateVoucherPDF = async (item: any) => {
  generatingPdfId.value = item.id;
  try {
    const doc = new jsPDF('p', 'mm', 'a4');
    const pageWidth = doc.internal.pageSize.width;
    const pageHeight = doc.internal.pageSize.height;
    const midPointY = pageHeight / 2;
    const margin = 15;

    const qrText = `VOUCHER:${item.id}|${item.request_number}|${item.requested_amount}`;
    const qrCodeDataUrl = await QRCode.toDataURL(qrText, { width: 100, margin: 1 });
    const processedBy = userStore.profile?.full_name || 'Sistema';
    const dateStr = format(new Date(), "dd/MM/yyyy HH:mm");

    const addWatermark = (yOffset: number) => {
       doc.saveGraphicsState();
       doc.setGState(new (doc as any).GState({ opacity: 0.15 }));
       doc.setFont('helvetica', 'bold');
       doc.setFontSize(22);
       doc.setTextColor(255, 0, 0);
       const text = 'VOUCHER / REQUISIÇÃO';
       doc.text(text, 12, yOffset + 100, { angle: 90 });
       doc.text(text, pageWidth - 12, yOffset + 100, { angle: -90 });
       doc.setFontSize(60);
       doc.setTextColor(230, 230, 230);
       doc.text("MJ FROTA", pageWidth/2, yOffset + 100, { align: 'center', angle: 45 });
       doc.restoreGraphicsState();
    };

    const generateHalf = (yOffset: number, viaName: string) => {
       addWatermark(yOffset);

       doc.setFontSize(14).setFont('helvetica', 'bold').setTextColor(0);
       doc.text("REQUISIÇÃO DE ABASTECIMENTO", pageWidth / 2, yOffset + 20, { align: 'center' });

       doc.setFontSize(10).setFont('helvetica', 'normal');
       doc.text(`Voucher Nº ${String(item.request_number).padStart(5, '0')}`, pageWidth / 2, yOffset + 26, { align: 'center' });

       doc.setFontSize(8).setTextColor(100);
       doc.text(viaName, pageWidth - margin, yOffset + 15, { align: 'right' });
       doc.text(`Emissão: ${dateStr}`, pageWidth - margin, yOffset + 19, { align: 'right' });
       doc.text(`Por: ${processedBy}`, pageWidth - margin, yOffset + 23, { align: 'right' });

       doc.setDrawColor(200); doc.setLineWidth(0.5);
       doc.line(margin, yOffset + 35, pageWidth - margin, yOffset + 35);

       autoTable(doc, {
          startY: yOffset + 40,
          head: [['Veículo / Placa', 'Motorista', 'Combustível', 'Valor Autorizado']],
          body: [[
             `${item.vehicle?.model?.toUpperCase()} - ${item.vehicle?.plate}`,
             item.driver_name?.toUpperCase(),
             item.fuel_type?.toUpperCase(),
             formatCurrency(item.requested_amount)
          ]],
          theme: 'grid',
          headStyles: { fillColor: [50, 50, 60], textColor: 255, fontStyle: 'bold', halign: 'center' },
          bodyStyles: { textColor: 0, fontSize: 10, halign: 'center' },
          styles: { cellPadding: 4, lineColor: 200, lineWidth: 0.1 },
          margin: { left: margin, right: 40 }
       });

       const qrSize = 30;
       doc.addImage(qrCodeDataUrl, 'PNG', pageWidth - margin - qrSize, yOffset + 40, qrSize, qrSize);

       const finalY = (doc as any).lastAutoTable.finalY + 10;
       if (item.notes) {
          doc.setFontSize(9).setFont('helvetica', 'bold').setTextColor(0);
          doc.text("Observações:", margin, finalY);
          doc.setFontSize(9).setFont('helvetica', 'normal');
          doc.text(item.notes, margin, finalY + 5);
       }

       const sigY = yOffset + (pageHeight/2) - 35;
       doc.setDrawColor(0); doc.setLineWidth(0.3);
       const sigW = 60;
       doc.line(margin + 10, sigY, margin + 10 + sigW, sigY);
       doc.setFontSize(8).setTextColor(0).setFont('helvetica', 'normal');
       doc.text("Autorizado Por (Empresa)", margin + 10 + (sigW/2), sigY + 4, { align: 'center' });
       doc.line(pageWidth - margin - 10 - sigW, sigY, pageWidth - margin - 10, sigY);
       doc.text("Assinatura Motorista", pageWidth - margin - 10 - (sigW/2), sigY + 4, { align: 'center' });
    };

    generateHalf(0, 'VIA DA EMPRESA');
    doc.setDrawColor(150); doc.setLineDashPattern([3, 3], 0);
    doc.line(5, midPointY, pageWidth - 5, midPointY);
    doc.setLineDashPattern([], 0);
    generateHalf(midPointY, 'VIA DO MOTORISTA');

    doc.save(`Voucher_${item.request_number}.pdf`);
  } catch (e) { console.error(e); } finally { generatingPdfId.value = null; }
};

onMounted(fetchData);
</script>

<style scoped lang="scss">
/* IDENTIDADE VISUAL CORPORATIVA (IDÊNTICA À GESTÃO DE VEÍCULOS/FINANCEIRO) */
.fleet-layout { position: relative; }
.background-carousel-wrapper { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 0; pointer-events: none; opacity: 1; }
.background-overlay { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 1; background: radial-gradient(circle at center, rgba(15, 15, 19, 0.4), rgba(15, 15, 19, 0.95)); backdrop-filter: blur(8px); }

.bg-glass-dark { background: rgba(10,10,12,0.85); }
.bg-glass-header { background: rgba(20,20,24,0.55); backdrop-filter: blur(14px); }
.border-bottom-white-05 { border-bottom: 1px solid rgba(255,255,255,0.08); }
.controls-bar { border: 1px solid rgba(0,0,0,0.08); padding: 10px; }
.search-wrap { height: 40px; padding: 0 12px; border: 1px solid rgba(0,0,0,0.08); display: flex; align-items: center; min-width: 300px; flex: 1; }
.clean-input { border: none; outline: none; flex: 1; font-size: 12px; }

/* Grid e Scroll */
.grid-scroll { scrollbar-gutter: stable; -webkit-overflow-scrolling: touch; }
.custom-scroll::-webkit-scrollbar { width: 8px; height: 8px; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.35); border-radius: 6px; }
.custom-scroll::-webkit-scrollbar-track { background: transparent; }

/* Grid Layout Fluido */
.grid-header, .grid-row {
    display: grid;
    align-items: stretch;
    width: 100%;
}
.grid-refueling { grid-template-columns: 80px 100px minmax(200px, 1.5fr) 140px 140px 180px; }

.cell {
    padding: 6px 8px;
    display: flex;
    align-items: center;
    border-right: 1px solid rgba(0,0,0,0.08);
    border-bottom: 1px solid rgba(0,0,0,0.08);
    min-height: 54px;
    overflow: hidden;
    transition: background-color 0.2s ease;
}

.header-text { font-size: 14px !important; font-weight: 800; text-transform: uppercase; letter-spacing: 0.5px; line-height: 1.2; }
.center { justify-content: center; text-align: center; }
.grid-header .cell { min-height: 44px; }
.list-text-11 { font-size: 14px !important; line-height: 1.2 !important; }

.grid-surface-light .cell { background: #f5f7fa; color: rgba(0,0,0,0.9); border-color: rgba(0,0,0,0.12) !important; }
.grid-surface-dark .cell { background: rgba(255,255,255,0.08); color: rgba(255,255,255,0.95); border-color: rgba(255,255,255,0.1) !important; }
.grid-row-light .cell { border-color: rgba(0,0,0,0.08) !important; }
.grid-row-dark .cell { border-color: rgba(255,255,255,0.08) !important; }

.zebra-light-a .cell { background: #ffffff; }
.zebra-light-b .cell { background: #f0f4f8; }
.zebra-dark-a .cell { background: rgba(0,0,0,0.15); }
.zebra-dark-b .cell { background: rgba(255,255,255,0.03); }
.grid-row-light:hover .cell { background: #e3f2fd !important; }
.grid-row-dark:hover .cell { background: rgba(255,255,255,0.12) !important; }

/* KPIs */
.kpi-card { color: white; position: relative; min-height: 110px; overflow: hidden; }
.kpi-bg-icon { position: absolute; right: -20px; bottom: -20px; opacity: 0.15; transform: rotate(-15deg); }
.kpi-bg-icon .v-icon { font-size: 100px; color: white; }
.kpi-bg-icon-mobile { position: absolute; right: -5px; bottom: -5px; opacity: 0.15; transform: rotate(-10deg); }
.kpi-bg-icon-mobile .v-icon { font-size: 60px; color: white; }

.bg-gradient-info { background: linear-gradient(135deg, #0288d1, #005b9f); }
.bg-gradient-green { background: linear-gradient(135deg, #2e7d32, #1b5e20); }
.bg-gradient-red { background: linear-gradient(135deg, #c62828, #8e0000); }
.bg-gradient-purple { background: linear-gradient(135deg, #7b1fa2, #4a148c); }

.kpi-label { font-size: 12px; font-weight: 900; letter-spacing: .2px; }
.kpi-value { font-size: 22px; font-weight: 900; }
.kpi-footer { font-size: 11px; opacity: .9; font-weight: 700; }

/* Chips & Buttons 3D */
.pill-ref { font-size: 12px !important; font-weight: 900; font-family: monospace; padding: 4px 6px; border-radius: 0px; white-space: nowrap; }
.solid-chip { display: inline-flex; align-items: center; justify-content: center; height: 28px; padding: 0 12px; font-size: 11px !important; font-weight: 900; color: #fff; text-transform: uppercase; white-space: nowrap; }
.chip-success { background: #2e7d32; }
.chip-warn { background: #f57f17; }
.chip-danger { background: #c62828; }

.actions-inline { display: flex; gap: 4px; justify-content: center; flex-wrap: nowrap !important; }
.action-btn { width: 28px !important; height: 28px !important; color: #fff !important; }
.action-edit { background: #1976d2 !important; }
.action-pay { background: #2e7d32 !important; }

.btn-3d {
    border-radius: 6px !important;
    box-shadow: 0 3px 5px rgba(0,0,0,0.15), inset 0 2px 0 rgba(255,255,255,0.25) !important;
    transition: transform 0.1s ease, box-shadow 0.1s ease;
    text-transform: none !important;
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

.row-gap { row-gap: 14px; margin-top: 4px; }

/* Pulse Animation */
.pulse { animation: pulse-yellow 2s infinite; }
@keyframes pulse-yellow { 0% { box-shadow: 0 0 0 0 rgba(245, 127, 23, 0.7); } 70% { box-shadow: 0 0 0 8px rgba(245, 127, 23, 0); } 100% { box-shadow: 0 0 0 0 rgba(245, 127, 23, 0); } }

/* CONTORNO EXTERNO DA GRID E FIX STICKY */
.flex-grow-1.overflow-hidden > .v-card.flex-grow-1 { border: 1px solid rgba(0,0,0,0.12) !important; }
.bg-glass-dark .flex-grow-1.overflow-hidden > .v-card.flex-grow-1 { border: 1px solid rgba(255,255,255,0.12) !important; }
.sticky-head { position: sticky; top: 0; z-index: 20; box-shadow: 0 8px 16px -4px rgba(0, 0, 0, 0.12); }
.bg-glass-dark .sticky-head { box-shadow: 0 8px 20px -4px rgba(0, 0, 0, 0.4); }

/* =======================================================
   ESTILO CORPORATIVO MODAIS PREMIUM
   ======================================================= */
.fixed-dialog { overflow: hidden !important; }
.btn-rect { border-radius: 2px !important; text-transform: none !important; letter-spacing: 0.5px; }
.ui-field :deep(.v-field) { border-radius: 2px !important; font-size: 13px; background: #fff;}
.input-label { display: block; font-size: 11px; font-weight: 800; text-transform: uppercase; color: #757575; margin-bottom: 6px; letter-spacing: 0.5px; }
.tracking-widest { letter-spacing: 0.05em; }

.border-white-20 { border: 1px solid rgba(255,255,255,0.2) !important; }
.border-white-10 { border-color: rgba(255,255,255,0.1) !important; }
.bg-black-70 { background-color: rgba(0,0,0,0.7); }
.shadow-md { box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06); }
.bg-white-10 { background: rgba(255,255,255,0.1); }
</style>
