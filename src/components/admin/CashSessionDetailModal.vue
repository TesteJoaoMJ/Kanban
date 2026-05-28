<template>
  <v-dialog
    :model-value="modelValue"
    @update:model-value="$emit('update:modelValue', $event)"
    max-width="1450"
    scrollable
    transition="dialog-bottom-transition"
  >
    <v-card class="rounded-xl border shadow-2xl overflow-hidden d-flex flex-column apple-hub-layout" :class="isDark ? 'bg-apple-dark text-white border-white-10' : 'bg-apple-light text-grey-darken-4 border-grey-lighten-2'" height="92vh">

      <div class="ambient-glow" :class="isDark ? 'glow-dark' : 'glow-light'"></div>

      <div class="px-6 py-6 px-md-8 py-md-6 border-b flex-shrink-0 d-flex justify-space-between align-start position-relative z-10" :class="isDark ? 'bg-surface-dark/80 border-white-05' : 'bg-white/80 border-grey-lighten-2'" style="backdrop-filter: blur(20px);">
          <div class="d-flex align-center gap-5">
              <div class="icon-box-lg rounded-xl elevation-2 d-flex align-center justify-center" :class="isDark ? 'bg-primary-darken-4 text-primary-lighten-1' : 'bg-primary-lighten-5 text-primary-darken-1'" style="width: 56px; height: 56px;">
                  <v-icon size="32">mdi-shield-search</v-icon>
              </div>
              <div>
                  <div class="breadcrumb text-[11px] font-weight-bold opacity-60 mb-1 d-flex align-center tracking-widest text-uppercase">
                      <v-icon size="14" class="mr-2">mdi-home</v-icon>
                      <span>Financeiro</span>
                      <span class="mx-2 opacity-40">/</span>
                      <span>Caixas do Dia</span>
                      <span class="mx-2 opacity-40">/</span>
                      <span class="text-primary">Auditoria e Reparo</span>
                  </div>
                  <h1 class="text-h4 font-weight-black tracking-tight lh-1" style="letter-spacing: -1px !important;">
                      Auditoria de Turno
                  </h1>
              </div>
          </div>

          <v-btn icon variant="tonal" class="rounded-xl shadow-sm border" size="small" :class="isDark ? 'border-white-10' : 'border-grey-lighten-2'" @click="$emit('update:modelValue', false)">
              <v-icon size="20">mdi-close</v-icon>
          </v-btn>
      </div>

      <v-card-text class="pa-0 d-flex flex-row overflow-hidden position-relative z-10 h-100">

          <div class="sessions-sidebar flex-shrink-0 d-flex flex-column border-r z-20 transition-all h-100" :class="isDark ? 'bg-surface-dark/40 border-white-05' : 'bg-white/40 border-grey-lighten-2'" style="width: 300px; backdrop-filter: blur(10px);">
            <div class="px-6 py-4 border-b d-flex flex-column gap-1" :class="isDark ? 'bg-white-02 border-white-05' : 'bg-grey-50 border-grey-lighten-2'">
                <div class="text-[10px] font-weight-bold text-uppercase opacity-50 tracking-widest d-flex align-center gap-2"><v-icon size="14">mdi-store-outline</v-icon> Unidade Base</div>
                <div class="text-body-2 font-weight-black d-flex align-center gap-2" :class="isDark ? 'text-white' : 'text-grey-darken-4'">
                    {{ session?.store?.name || 'Carregando...' }}
                </div>
                <div class="text-[11px] font-mono opacity-70 mt-1">{{ formatDateOnly(session?.opened_at) }}</div>
            </div>

            <div class="pa-4 custom-scroll flex-grow-1 overflow-y-auto">
              <div v-if="sessionMaths.length === 0" class="pa-4 text-center text-[11px] font-weight-bold opacity-50 text-uppercase tracking-widest">Nenhum caixa encontrado.</div>

              <div
                 v-for="s in sessionMaths" :key="s.id"
                 @click="focusSession(s.id)"
                 class="session-card mb-3 pa-4 rounded-xl border cursor-pointer transition-all position-relative overflow-hidden"
                 :class="[
                     focusedSessionId === s.id
                        ? (isDark ? 'bg-primary-darken-4/30 border-primary/50 shadow-glow' : 'bg-primary-50 border-primary-200 shadow-sm')
                        : (isDark ? 'bg-white-02 border-white-05 hover-bg-dark' : 'bg-white border-grey-lighten-2 hover-bg-light')
                 ]"
              >
                 <div v-if="focusedSessionId === s.id" class="active-indicator bg-primary position-absolute left-0 top-0 bottom-0" style="width: 4px;"></div>
                 <div class="d-flex flex-column gap-2">
                     <div class="d-flex justify-space-between align-start">
                         <span class="text-body-2 font-weight-black text-truncate pr-2 lh-1" :class="isDark ? 'text-white' : 'text-grey-darken-4'" style="max-width: 150px;">
                            {{ s.operatorName }}
                         </span>
                         <v-chip size="x-small" :color="s.status === 'open' ? 'success' : 'grey'" variant="flat" class="font-weight-bold text-[9px] px-2 rounded-md tracking-widest uppercase">
                             {{ s.status === 'open' ? 'ABERTO' : 'FECHADO' }}
                         </v-chip>
                     </div>
                     <div class="d-flex justify-space-between align-center mt-1 border-t pt-2" :class="isDark ? 'border-white-10' : 'border-grey-lighten-3'">
                         <span class="text-[10px] font-weight-bold text-uppercase opacity-60">Gaveta:</span>
                         <span class="text-[12px] font-mono font-weight-black" :class="focusedSessionId === s.id ? 'text-primary' : ''">
                            {{ formatCurrency(s.expectedGaveta) }}
                         </span>
                     </div>
                 </div>
              </div>
            </div>
          </div>

          <div class="main-content flex-grow-1 d-flex flex-column overflow-hidden h-100 position-relative">
            <v-progress-linear v-if="loadingData" indeterminate color="primary" class="position-absolute top-0 w-100 z-30" height="2"></v-progress-linear>

            <div class="flex-grow-1 overflow-y-auto custom-scroll pa-6 pa-md-8">

                <div class="mb-8">
                    <h2 class="text-subtitle-1 font-weight-black letter-spacing-1 opacity-90 mb-4 d-flex align-center gap-2 text-uppercase">
                        Consolidado Físico da Unidade
                    </h2>

                    <div class="d-grid kpi-macro-grid gap-4">
                        <v-card class="apple-report-card pa-5 rounded-xl border shadow-micro transition-all position-relative overflow-hidden" :class="isDark ? 'bg-surface-dark border-white-05' : 'bg-white border-grey-lighten-2'">
                            <div class="color-glow bg-primary"></div>
                            <div class="text-[10px] font-weight-bold text-uppercase opacity-50 mb-2 tracking-widest position-relative z-10">Fundos Iniciais</div>
                            <div class="text-h6 font-mono font-weight-black position-relative z-10">{{ formatCurrency(storeTotals.initial) }}</div>
                        </v-card>

                        <v-card class="apple-report-card pa-5 rounded-xl border shadow-micro transition-all position-relative overflow-hidden" :class="isDark ? 'bg-surface-dark border-white-05' : 'bg-white border-grey-lighten-2'">
                            <div class="color-glow bg-success"></div>
                            <div class="text-[10px] font-weight-bold text-uppercase text-success mb-2 tracking-widest position-relative z-10">Vendas Físicas (+)</div>
                            <div class="text-h6 font-mono font-weight-black text-success position-relative z-10">{{ formatCurrency(storeTotals.cashSales) }}</div>
                        </v-card>

                        <v-card class="apple-report-card pa-5 rounded-xl border shadow-micro transition-all position-relative overflow-hidden" :class="isDark ? 'bg-surface-dark border-white-05' : 'bg-white border-grey-lighten-2'">
                            <div class="color-glow bg-info"></div>
                            <div class="text-[10px] font-weight-bold text-uppercase text-info mb-2 tracking-widest position-relative z-10">Suprimentos (+)</div>
                            <div class="text-h6 font-mono font-weight-black text-info position-relative z-10">{{ formatCurrency(storeTotals.supply) }}</div>
                        </v-card>

                        <v-card class="apple-report-card pa-5 rounded-xl border shadow-micro transition-all position-relative overflow-hidden" :class="isDark ? 'bg-surface-dark border-white-05' : 'bg-white border-grey-lighten-2'">
                            <div class="color-glow bg-error"></div>
                            <div class="text-[10px] font-weight-bold text-uppercase text-error mb-2 tracking-widest position-relative z-10">Sangrias (-)</div>
                            <div class="text-h6 font-mono font-weight-black text-error position-relative z-10">({{ formatCurrency(storeTotals.bleed) }})</div>
                        </v-card>

                        <v-card class="apple-report-card pa-5 rounded-xl border shadow-micro d-flex justify-space-between align-center transition-all position-relative overflow-hidden"
                             :class="isDark ? 'bg-surface-dark border-white-05' : 'bg-white border-grey-lighten-2'">
                            <div class="color-glow" :class="storeTotals.diff === 0 ? 'bg-success' : 'bg-error'"></div>
                            <div class="position-relative z-10">
                                <div class="text-[10px] font-weight-bold text-uppercase opacity-70 mb-2 tracking-widest">Espera vs Declarado</div>
                                <div class="d-flex align-center gap-2 font-mono text-[11px] opacity-80 font-weight-bold">
                                    <span>E: <span :class="isDark ? 'text-white' : 'text-black'">{{ formatCurrency(storeTotals.expected) }}</span></span>
                                    <v-icon size="10" class="opacity-50">mdi-minus</v-icon>
                                    <span>D: <span :class="isDark ? 'text-white' : 'text-black'">{{ formatCurrency(storeTotals.declared) }}</span></span>
                                </div>
                            </div>
                            <div class="text-right position-relative z-10">
                                <div class="text-[10px] font-weight-bold text-uppercase opacity-70 mb-1 tracking-widest">Diferença</div>
                                <div class="text-h6 font-weight-black font-mono lh-1" :class="storeTotals.diff === 0 ? 'text-success' : 'text-error'">
                                    {{ formatCurrency(storeTotals.diff) }}
                                </div>
                            </div>
                        </v-card>
                    </div>
                </div>

                <v-card v-if="focusedMath" class="apple-report-card rounded-xl border shadow-micro d-flex flex-column overflow-hidden position-relative" :class="isDark ? 'bg-surface-dark border-white-05' : 'bg-white border-grey-lighten-2'">

                    <div class="px-6 py-5 border-b d-flex flex-column flex-md-row justify-space-between align-md-end gap-4" :class="isDark ? 'border-white-05 bg-white-02' : 'border-grey-lighten-2 bg-grey-50'">
                        <div class="d-flex align-center gap-4">
                            <v-avatar size="48" :color="isDark ? 'grey-darken-3' : 'grey-lighten-3'" class="border rounded-xl">
                                <span class="text-h6 font-weight-black">{{ focusedMath.operatorName.charAt(0) }}</span>
                            </v-avatar>
                            <div>
                                <div class="text-[10px] font-weight-bold text-uppercase tracking-widest opacity-50 mb-1">Auditoria de Operador</div>
                                <div class="text-h5 font-weight-black lh-1 tracking-tight">{{ focusedMath.operatorName }}</div>
                            </div>
                        </div>

                        <v-tabs v-model="activeTab" color="primary" density="compact" bg-color="transparent" class="elegant-tabs">
                            <v-tab value="dashboard" class="text-none font-weight-bold text-[12px] tracking-widest text-uppercase"><v-icon start size="14">mdi-view-dashboard-outline</v-icon> Dashboard</v-tab>
                            <v-tab value="ledger" class="text-none font-weight-bold text-[12px] tracking-widest text-uppercase"><v-icon start size="14">mdi-format-list-bulleted</v-icon> Livro Caixa</v-tab>
                            <v-tab value="repair" class="text-none font-weight-bold text-[12px] tracking-widest text-uppercase"><v-icon start size="14">mdi-tools</v-icon> Reparo</v-tab>
                            <v-tab value="blackbox" class="text-none font-weight-bold text-[12px] text-amber-darken-2 tracking-widest text-uppercase"><v-icon start size="14">mdi-record-rec</v-icon> Caixa Preta</v-tab>
                        </v-tabs>
                    </div>

                    <div class="pa-6">
                        <v-window v-model="activeTab" class="overflow-visible">

                            <v-window-item value="dashboard" class="fade-in">
                                <div class="d-flex justify-end mb-6 gap-3">
                                    <v-btn variant="outlined" size="small" class="rounded-lg font-weight-bold text-[11px] tracking-widest text-uppercase border-opacity-50" :color="isDark ? 'white' : 'grey-darken-3'" @click="generateQuickPdf" :loading="loadingPdf">
                                        <v-icon start size="14">mdi-flash</v-icon> Relatório Rápido
                                    </v-btn>
                                    <v-btn variant="flat" color="primary" size="small" class="rounded-lg font-weight-bold text-[11px] tracking-widest text-uppercase shadow-sm" @click="openPdfEditor">
                                        <v-icon start size="14">mdi-pencil-ruler</v-icon> Editor PDF
                                    </v-btn>
                                </div>

                                <v-row dense class="mx-n2">
                                    <v-col cols="12" md="4" class="px-2">
                                        <div class="fill-height rounded-xl border shadow-micro overflow-hidden d-flex flex-column transition-all" :class="isDark ? 'bg-white-02 border-white-05' : 'bg-grey-50 border-grey-lighten-2'">
                                            <div class="px-5 py-4 border-b d-flex align-center" :class="isDark ? 'border-white-05' : 'border-grey-lighten-2'">
                                                <v-icon size="16" class="mr-2 opacity-60">mdi-cash-multiple</v-icon>
                                                <span class="font-weight-bold text-uppercase text-[11px] tracking-widest opacity-80">Extrato Físico</span>
                                            </div>
                                            <div class="pa-5 flex-grow-1 d-flex flex-column gap-3">
                                                <div class="extrato-row d-flex justify-space-between align-center"><span class="opacity-70 text-[11px] font-weight-bold text-uppercase tracking-wide">Fundo Inicial</span><span class="font-mono text-[13px] font-weight-black">{{ formatCurrency(focusedMath.initial) }}</span></div>
                                                <div class="extrato-row d-flex justify-space-between align-center"><span class="text-success text-[11px] font-weight-bold text-uppercase tracking-wide">Vendas PDV</span><span class="font-mono text-[13px] text-success font-weight-black">+ {{ formatCurrency(focusedMath.cashSales) }}</span></div>
                                                <div class="extrato-row d-flex justify-space-between align-center"><span class="text-info text-[11px] font-weight-bold text-uppercase tracking-wide">Suprimentos</span><span class="font-mono text-[13px] text-info font-weight-black">+ {{ formatCurrency(focusedMath.supply) }}</span></div>
                                                <div class="extrato-row d-flex justify-space-between align-center"><span class="text-error text-[11px] font-weight-bold text-uppercase tracking-wide">Sangrias</span><span class="font-mono text-[13px] text-error font-weight-black">- {{ formatCurrency(focusedMath.bleed) }}</span></div>
                                                <div v-if="focusedMath.auditInGaveta > 0" class="extrato-row d-flex justify-space-between align-center"><span class="text-warning text-[11px] font-weight-bold text-uppercase tracking-wide">Auditoria (+)</span><span class="font-mono text-[13px] text-warning font-weight-black">+ {{ formatCurrency(focusedMath.auditInGaveta) }}</span></div>
                                                <div v-if="focusedMath.auditOutGaveta > 0" class="extrato-row d-flex justify-space-between align-center"><span class="text-warning text-[11px] font-weight-bold text-uppercase tracking-wide">Auditoria (-)</span><span class="font-mono text-[13px] text-warning font-weight-black">- {{ formatCurrency(focusedMath.auditOutGaveta) }}</span></div>
                                            </div>
                                            <div class="px-5 py-4 border-t d-flex justify-space-between align-center mt-auto" :class="isDark ? 'border-white-05 bg-surface-dark' : 'border-grey-lighten-2 bg-white'">
                                                <div>
                                                    <div class="text-[9px] font-weight-bold text-uppercase opacity-50 mb-1 tracking-widest">Esperado Gaveta</div>
                                                    <div class="font-mono text-h6 font-weight-black lh-1">{{ formatCurrency(focusedMath.expectedGaveta) }}</div>
                                                </div>
                                                <div class="text-right">
                                                    <div class="text-[9px] font-weight-bold text-uppercase opacity-50 mb-1 tracking-widest">Furo</div>
                                                    <div class="font-mono text-h6 font-weight-black lh-1" :class="focusedMath.difference === 0 ? 'text-success' : 'text-error'">
                                                        {{ focusedMath.status === 'open' ? '---' : formatCurrency(focusedMath.difference) }}
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                    </v-col>

                                    <v-col cols="12" md="4" class="px-2">
                                        <div class="fill-height rounded-xl border shadow-micro overflow-hidden d-flex flex-column transition-all" :class="isDark ? 'bg-white-02 border-white-05' : 'bg-grey-50 border-grey-lighten-2'">
                                            <div class="px-5 py-4 border-b d-flex align-center" :class="isDark ? 'border-white-05' : 'border-grey-lighten-2'">
                                                <v-icon size="16" class="mr-2 opacity-60 text-primary">mdi-cloud-check</v-icon>
                                                <span class="font-weight-bold text-uppercase text-[11px] tracking-widest opacity-80 text-primary">Extrato Virtual</span>
                                            </div>
                                            <div class="pa-5 flex-grow-1 d-flex flex-column gap-3">
                                                <div class="extrato-row d-flex justify-space-between align-center"><span class="opacity-70 text-[11px] font-weight-bold text-uppercase tracking-wide">Total PIX/Transf.</span><span class="font-mono text-[13px] text-primary font-weight-black">{{ formatCurrency(focusedMath.virtualPix) }}</span></div>
                                                <div class="extrato-row d-flex justify-space-between align-center"><span class="opacity-70 text-[11px] font-weight-bold text-uppercase tracking-wide">Total Cartões</span><span class="font-mono text-[13px] text-primary font-weight-black">{{ formatCurrency(focusedMath.virtualCard) }}</span></div>
                                                <div class="extrato-row d-flex justify-space-between align-center"><span class="opacity-70 text-[11px] font-weight-bold text-uppercase tracking-wide">Boletos e Outros</span><span class="font-mono text-[13px] text-primary font-weight-black">{{ formatCurrency(focusedMath.virtualOther) }}</span></div>
                                                <div v-if="focusedMath.auditInVirtual > 0" class="extrato-row d-flex justify-space-between align-center"><span class="text-warning text-[11px] font-weight-bold text-uppercase tracking-wide">Auditoria (+)</span><span class="font-mono text-[13px] text-warning font-weight-black">+ {{ formatCurrency(focusedMath.auditInVirtual) }}</span></div>
                                                <div v-if="focusedMath.auditOutVirtual > 0" class="extrato-row d-flex justify-space-between align-center"><span class="text-warning text-[11px] font-weight-bold text-uppercase tracking-wide">Auditoria (-)</span><span class="font-mono text-[13px] text-warning font-weight-black">- {{ formatCurrency(focusedMath.auditOutVirtual) }}</span></div>
                                            </div>
                                            <div class="px-5 py-4 border-t mt-auto" :class="isDark ? 'border-white-05 bg-surface-dark' : 'border-grey-lighten-2 bg-white'">
                                                <div class="text-[9px] font-weight-bold text-uppercase opacity-70 mb-1 text-primary tracking-widest">Faturado Digital</div>
                                                <div class="font-mono text-h6 font-weight-black lh-1 text-primary">{{ formatCurrency(focusedMath.virtualTotal) }}</div>
                                            </div>
                                        </div>
                                    </v-col>

                                    <v-col cols="12" md="4" class="px-2">
                                        <div class="fill-height rounded-xl border shadow-micro overflow-hidden d-flex flex-column transition-all" :class="isDark ? 'bg-white-02 border-white-05' : 'bg-grey-50 border-grey-lighten-2'">
                                            <div class="px-5 py-4 border-b d-flex justify-space-between align-center" :class="isDark ? 'border-white-05' : 'border-grey-lighten-2'">
                                                <span class="font-weight-bold text-uppercase text-[11px] tracking-widest opacity-80 d-flex align-center"><v-icon start size="16" class="opacity-60">mdi-receipt-text</v-icon> Pedidos Vínculados</span>
                                                <v-chip size="small" color="primary" variant="flat" class="font-weight-black px-3 rounded-lg">{{ focusedOrders.length }}</v-chip>
                                            </div>
                                            <div class="flex-grow-1 overflow-y-auto custom-scroll" style="max-height: 250px;">
                                                <div v-if="focusedOrders.length === 0" class="text-center pa-8 text-[11px] opacity-50 font-weight-bold text-uppercase tracking-widest">Nenhum pedido atrelado.</div>
                                                <div v-for="o in focusedOrders" :key="o.id" class="px-5 py-4 border-b d-flex justify-space-between align-center transition-all hover-elevate" :class="isDark ? 'border-white-05 hover-bg-dark' : 'border-grey-lighten-2 hover-bg-light'">
                                                    <div class="d-flex flex-column gap-1">
                                                        <span class="font-mono text-[12px] font-weight-black text-primary">#{{ o.order_number }}</span>
                                                        <span class="text-[10px] font-weight-bold opacity-70 text-truncate text-uppercase tracking-wide" style="max-width: 140px;">{{ o.customer_name }}</span>
                                                    </div>
                                                    <div class="d-flex flex-column align-end gap-1">
                                                        <span class="font-mono font-weight-black text-[12px]">{{ formatCurrency(o.total_value) }}</span>
                                                        <span class="text-[9px] font-weight-bold text-uppercase px-2 py-0-5 rounded-md" :class="o.status === 'cancelled' ? 'bg-error-lighten-5 text-error border border-error-lighten-3' : 'bg-grey-lighten-4 text-grey-darken-2 border border-grey-lighten-2'">{{ o.status }}</span>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                    </v-col>
                                </v-row>
                            </v-window-item>

                            <v-window-item value="ledger" class="fade-in">
                                <div class="d-flex justify-space-between align-center mb-6">
                                    <div>
                                        <h3 class="text-subtitle-1 font-weight-black opacity-90 tracking-tight">Movimentações Detalhadas</h3>
                                        <p class="text-caption font-weight-medium opacity-60">Histórico completo de entradas e saídas físicas/manuais.</p>
                                    </div>
                                    <v-btn variant="tonal" color="primary" size="small" class="rounded-lg font-weight-bold text-[11px] tracking-widest text-uppercase" prepend-icon="mdi-plus" @click="openAddEntryModal">
                                        Novo Lançamento
                                    </v-btn>
                                </div>

                                <div class="rounded-xl border overflow-hidden shadow-micro" :class="isDark ? 'border-white-05 bg-surface-dark' : 'border-grey-lighten-2 bg-white'">
                                    <div class="grid-ledger-header border-b px-5 py-4" :class="isDark ? 'bg-white-02 border-white-05 text-white-70' : 'bg-grey-50 border-grey-lighten-2 text-grey-darken-2'">
                                        <div class="text-[10px] font-weight-black text-uppercase tracking-widest">Hora</div>
                                        <div class="text-[10px] font-weight-black text-uppercase tracking-widest">Descrição</div>
                                        <div class="text-[10px] font-weight-black text-uppercase tracking-widest text-center">Tipo</div>
                                        <div class="text-[10px] font-weight-black text-uppercase tracking-widest text-center">Método</div>
                                        <div class="text-[10px] font-weight-black text-uppercase tracking-widest text-right">Valor</div>
                                        <div class="text-[10px] font-weight-black text-uppercase tracking-widest text-center">Ações</div>
                                    </div>
                                    <div class="custom-scroll" style="max-height: 500px; overflow-y: auto;">
                                        <div v-if="detailedLedger.length === 0" class="pa-8 text-center text-[11px] opacity-50 font-weight-bold text-uppercase tracking-widest">Nenhum lançamento no caixa.</div>
                                        <div v-for="row in detailedLedger" :key="row.id" class="grid-ledger-row px-5 py-4 border-b transition-all hover-elevate" :class="isDark ? 'border-white-05 hover-bg-dark' : 'border-grey-lighten-2 hover-bg-light'">
                                            <div class="font-mono text-[11px] font-weight-bold opacity-70 d-flex align-center">{{ formatTimeOnly(row.date) }}</div>
                                            <div class="d-flex flex-column justify-center gap-1">
                                                <span class="text-[11px] font-weight-bold opacity-90">{{ row.description }}</span>
                                                <span v-if="row.orderNumber" class="text-[9px] font-mono font-weight-bold opacity-50">Ref: #{{ row.orderNumber }}</span>
                                            </div>
                                            <div class="d-flex align-center justify-center">
                                                <span class="status-pill" :class="row.direction === 'in' ? 'pill-success' : 'pill-error'">{{ row.label }}</span>
                                            </div>
                                            <div class="d-flex align-center justify-center">
                                                <span class="method-chip" :class="'method-' + getMethodColorClass(row.method)">{{ row.method }}</span>
                                            </div>
                                            <div class="font-mono text-[13px] font-weight-black text-right d-flex align-center justify-end" :class="row.direction === 'in' ? 'text-success' : 'text-error'">
                                                {{ row.direction === 'in' ? '+' : '-' }} {{ formatCurrency(row.amount) }}
                                            </div>

                                            <div class="d-flex justify-center align-center gap-2">
                                                <v-tooltip text="Editar" location="top" v-if="row.id.startsWith('mov_') && row.label !== 'Abertura'">
                                                    <template v-slot:activator="{ props }">
                                                        <v-btn v-bind="props" icon size="x-small" variant="tonal" color="primary" class="rounded-lg shadow-sm" @click="editMovement(row)">
                                                            <v-icon size="14">mdi-pencil</v-icon>
                                                        </v-btn>
                                                    </template>
                                                </v-tooltip>

                                                <v-tooltip text="Excluir/Ocultar do Turno" location="top" v-if="row.label !== 'Abertura' && userStore.isAdmin">
                                                    <template v-slot:activator="{ props }">
                                                        <v-btn v-bind="props" icon size="x-small" variant="tonal" color="error" class="rounded-lg shadow-sm" @click="requestExclusion(row)">
                                                            <v-icon size="14">mdi-trash-can-outline</v-icon>
                                                        </v-btn>
                                                    </template>
                                                </v-tooltip>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </v-window-item>

                            <v-window-item value="repair" class="fade-in">
                                <div class="d-flex justify-space-between align-center mb-6">
                                    <div>
                                        <h3 class="text-subtitle-1 font-weight-black opacity-90 text-amber-darken-3 tracking-tight">Inclusão de Receitas Órfãs</h3>
                                        <p class="text-caption font-weight-medium opacity-60">Identifique pagamentos sistêmicos que não entraram neste caixa físico.</p>
                                    </div>
                                    <v-btn color="amber-darken-3" variant="flat" size="small" class="rounded-lg font-weight-bold text-[11px] tracking-widest text-uppercase shadow-sm" @click="applyAuditToCashMovements" :loading="isApplying" :disabled="!hasAnyCashIncluded">
                                        Incluir no Caixa <v-icon end size="14">mdi-check</v-icon>
                                    </v-btn>
                                </div>

                                <div class="rounded-xl border overflow-hidden shadow-micro" :class="isDark ? 'border-amber-900/30 bg-surface-dark' : 'border-amber-200 bg-white'">
                                    <div class="grid-audit-header border-b px-5 py-4" :class="isDark ? 'bg-amber-900/20 border-amber-900/30 text-amber-lighten-2' : 'bg-amber-50 border-amber-200 text-amber-darken-4'">
                                        <div class="text-[10px] font-weight-black text-uppercase tracking-widest text-center">Incluir</div>
                                        <div class="text-[10px] font-weight-black text-uppercase tracking-widest">Origem / Ref</div>
                                        <div class="text-[10px] font-weight-black text-uppercase tracking-widest">Descrição</div>
                                        <div class="text-[10px] font-weight-black text-uppercase tracking-widest">Meio Físico</div>
                                        <div class="text-[10px] font-weight-black text-uppercase tracking-widest text-center">Tipo</div>
                                        <div class="text-[10px] font-weight-black text-uppercase tracking-widest text-right">Valor</div>
                                    </div>
                                    <div class="custom-scroll" style="max-height: 500px; overflow-y: auto;">
                                        <div v-if="auditRows.length === 0" class="pa-8 text-center text-[11px] opacity-50 font-weight-bold text-uppercase tracking-widest">Nenhuma receita órfã detectada neste turno.</div>
                                        <div v-for="row in auditRows" :key="row.key" class="grid-audit-row px-5 py-4 border-b transition-all" :class="[row.includeInCash ? (isDark ? 'bg-amber-900/30' : 'bg-amber-50') : '', isDark ? 'border-white-05 hover-bg-dark' : 'border-grey-lighten-2 hover-bg-light']">
                                            <div class="d-flex align-center justify-center">
                                                <v-checkbox-btn v-model="row.includeInCash" color="amber-darken-3" density="compact"></v-checkbox-btn>
                                            </div>
                                            <div class="d-flex flex-column justify-center gap-1">
                                                <span class="text-[11px] font-weight-black opacity-90">{{ row.sourceLabel }}</span>
                                                <span class="text-[9px] font-mono font-weight-bold opacity-50">ID: {{ row.sourceIdShort }}</span>
                                            </div>
                                            <div class="d-flex align-center">
                                                <span class="text-[11px] font-weight-bold opacity-80">{{ row.description || '-' }}</span>
                                            </div>
                                            <div class="d-flex align-center">
                                                <v-select v-if="row.includeInCash" v-model="row.auditMethod" :items="auditMethods" density="compact" variant="outlined" hide-details class="text-[11px] rounded-lg font-weight-bold" :bg-color="isDark ? '#2A2A35' : 'white'" style="max-width: 140px;"></v-select>
                                                <span v-else class="text-[11px] font-weight-bold opacity-30">-</span>
                                            </div>
                                            <div class="d-flex align-center justify-center">
                                                <v-btn-toggle v-if="row.includeInCash" v-model="row.direction" density="compact" mandatory class="border rounded-lg" style="height: 28px;">
                                                    <v-btn value="in" class="text-[10px] font-weight-black px-2 tracking-widest" :color="row.direction === 'in' ? 'success' : ''" variant="flat">ENTRA</v-btn>
                                                    <v-btn value="out" class="text-[10px] font-weight-black px-2 tracking-widest" :color="row.direction === 'out' ? 'error' : ''" variant="flat">SAI</v-btn>
                                                </v-btn-toggle>
                                                <span v-else class="text-[11px] font-weight-bold opacity-30">-</span>
                                            </div>
                                            <div class="font-mono text-[13px] font-weight-black text-right d-flex align-center justify-end" :class="row.includeInCash ? 'text-primary' : 'opacity-60'">
                                                {{ formatCurrency(row.amount) }}
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </v-window-item>

                            <v-window-item value="blackbox" class="fade-in">
                                 <div class="d-flex justify-space-between align-center mb-6">
                                    <div>
                                        <h3 class="text-subtitle-1 font-weight-black opacity-90 text-amber-darken-3 d-flex align-center gap-2 tracking-tight">
                                            <v-icon size="18">mdi-alert-decagram-outline</v-icon> Caixa Preta (Logs Imutáveis)
                                        </h3>
                                        <p class="text-caption font-weight-medium opacity-60">Rastreamento de cada clique disparado pelas interfaces de venda e pagamento durante este turno.</p>
                                    </div>
                                </div>

                                <div class="rounded-xl border overflow-hidden shadow-micro" :class="isDark ? 'border-amber-900/30 bg-surface-dark' : 'border-amber-200 bg-white'">
                                    <div class="grid-blackbox-header border-b px-5 py-4" :class="isDark ? 'bg-amber-900/20 border-amber-900/30 text-amber-lighten-2' : 'bg-amber-50 border-amber-200 text-amber-darken-4'">
                                        <div class="text-[10px] font-weight-black text-uppercase tracking-widest">Timestamp</div>
                                        <div class="text-[10px] font-weight-black text-uppercase tracking-widest">Origem Lógica</div>
                                        <div class="text-[10px] font-weight-black text-uppercase tracking-widest">Classificação</div>
                                        <div class="text-[10px] font-weight-black text-uppercase tracking-widest">Referência</div>
                                        <div class="text-[10px] font-weight-black text-uppercase tracking-widest text-right">Valor</div>
                                    </div>
                                    <div class="custom-scroll" style="max-height: 500px; overflow-y: auto;">
                                        <div v-if="blackboxLogs.length === 0" class="pa-8 text-center text-[11px] opacity-50 font-weight-bold text-uppercase tracking-widest">Nenhum evento registrado.</div>
                                        <div v-for="log in blackboxLogs" :key="log.id" class="grid-blackbox-row px-5 py-4 border-b transition-all hover-elevate" :class="isDark ? 'border-white-05 hover-bg-dark' : 'border-grey-lighten-2 hover-bg-light'">
                                            <div class="font-mono text-[11px] font-weight-bold opacity-60 d-flex align-center">{{ formatDateTimeSeconds(log.created_at) }}</div>
                                            <div class="d-flex align-center">
                                                <span class="text-[10px] font-weight-bold text-uppercase tracking-widest border px-2 py-0-5 rounded-md" :class="isDark ? 'bg-white-05 border-white-10' : 'bg-grey-50 border-grey-200'">{{ log.origin }}</span>
                                            </div>
                                            <div class="d-flex align-center gap-2">
                                                <div class="dot-indicator" :class="log.is_cash ? 'bg-success' : 'bg-info'"></div>
                                                <span class="text-[11px] font-weight-bold opacity-80 text-uppercase tracking-wide">{{ log.method_name || 'N/A' }}</span>
                                                <span class="text-[10px] font-weight-bold opacity-40 font-mono">({{ log.is_cash ? 'FÍS' : 'DIG' }})</span>
                                            </div>
                                            <div class="d-flex align-center">
                                                <span class="text-[11px] font-weight-bold opacity-80 text-uppercase">{{ log.order_ref || '-' }}</span>
                                            </div>
                                            <div class="font-mono text-[13px] font-weight-black text-right d-flex align-center justify-end" :class="log.amount < 0 ? 'text-error' : 'text-primary'">
                                                {{ formatCurrency(log.amount) }}
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </v-window-item>

                        </v-window>
                    </div>
                </v-card>
            </div>
          </div>
      </v-card-text>
    </v-card>

    <v-dialog v-model="showAddEntryModal" max-width="450">
        <v-card class="rounded-xl border shadow-2xl" :class="isDark ? 'bg-surface-dark border-white-10' : 'bg-white border-grey-lighten-2'">
            <div class="px-6 py-5 border-b d-flex justify-space-between align-center" :class="isDark ? 'border-white-05 bg-white-02' : 'border-grey-lighten-2 bg-grey-50'">
                <span class="font-weight-black text-[13px] text-uppercase tracking-widest d-flex align-center gap-2">
                    <v-icon size="18" color="primary">{{ isEditing ? 'mdi-pencil' : 'mdi-plus-circle' }}</v-icon>
                    {{ isEditing ? 'Editar Lançamento' : 'Novo Lançamento Manual' }}
                </span>
                <v-btn icon size="small" variant="text" @click="showAddEntryModal = false"><v-icon size="18">mdi-close</v-icon></v-btn>
            </div>
            <div class="pa-6">
                <div class="d-grid gap-4 mb-4" style="grid-template-columns: 1fr 1fr;">
                    <v-select v-model="newEntry.type" :items="[{title:'Suprimento', value:'supply'}, {title:'Sangria', value:'bleed'}]" label="Tipo" variant="outlined" density="compact" hide-details class="rounded-lg font-weight-bold"></v-select>
                    <v-text-field v-model="newEntry.amount" label="Valor (R$)" type="number" prefix="R$" variant="outlined" density="compact" hide-details class="rounded-lg font-mono font-weight-black text-primary"></v-text-field>
                </div>

                <v-select v-model="newEntry.method" :items="cashStore.availablePaymentMethods" item-title="name" item-value="id" label="Método de Pagamento" variant="outlined" density="compact" class="mb-4 rounded-lg font-weight-bold" hide-details placeholder="Selecione..."></v-select>

                <v-autocomplete
                    v-model="newEntry.orderId" :items="allOrders" item-title="order_number" item-value="id"
                    label="Vincular a Pedido (Opcional)" variant="outlined" density="compact" class="mb-4 rounded-lg font-weight-bold" hide-details clearable
                >
                    <template v-slot:item="{ props, item }">
                        <v-list-item v-bind="props" :title="'#' + item.raw.order_number" :subtitle="item.raw.customer_name" class="text-[12px] font-weight-bold"></v-list-item>
                    </template>
                </v-autocomplete>

                <v-text-field v-model="newEntry.description" label="Descrição / Observação" variant="outlined" density="compact" class="mb-4 rounded-lg font-weight-bold" hide-details></v-text-field>

                <div class="d-grid gap-4" style="grid-template-columns: 1fr 1fr;">
                    <v-text-field v-model="newEntry.date" type="date" label="Data" variant="outlined" density="compact" hide-details class="rounded-lg font-mono font-weight-bold"></v-text-field>
                    <v-text-field v-model="newEntry.time" type="time" label="Hora" variant="outlined" density="compact" hide-details class="rounded-lg font-mono font-weight-bold"></v-text-field>
                </div>
            </div>
            <div class="pa-5 border-t d-flex justify-end gap-3" :class="isDark ? 'border-white-05 bg-white-02' : 'border-grey-lighten-2 bg-grey-50'">
                <v-btn variant="outlined" size="small" class="rounded-lg font-weight-bold text-uppercase tracking-widest px-4" @click="showAddEntryModal = false">Cancelar</v-btn>
                <v-btn color="primary" variant="flat" size="small" class="rounded-lg font-weight-black text-uppercase tracking-widest px-6 shadow-sm" @click="saveManualEntry" :loading="savingEntry">
                    {{ isEditing ? 'Salvar' : 'Registrar' }}
                </v-btn>
            </div>
        </v-card>
    </v-dialog>

    <v-dialog v-model="confirmDialog" max-width="420" persistent>
        <v-card class="rounded-xl border-thin shadow-2xl" :class="isDark ? 'bg-surface-dark text-white border-white-10' : 'bg-white'">
            <div class="pa-8 text-center">
                <div class="icon-circle-lg mx-auto mb-5 rounded-2xl" :class="isDark ? 'bg-red-darken-4' : 'bg-red-lighten-5'">
                    <v-icon size="40" color="error">mdi-alert-octagon</v-icon>
                </div>
                <h3 class="text-h6 font-weight-black mb-2 lh-1 tracking-tight">Excluir / Ocultar do Caixa</h3>
                <p class="text-body-2 opacity-70 mb-8 font-weight-medium">
                    Deseja remover <strong>{{ itemToExclude?.description }}</strong> no valor de <strong class="text-error font-mono">R$ {{ Number(itemToExclude?.amount || 0).toFixed(2).replace('.', ',') }}</strong>?
                    <br><br>O registro deixará de contabilizar na matemática deste turno para o fechamento de caixa.
                </p>
                <div class="d-flex gap-3">
                    <v-btn variant="outlined" class="flex-grow-1 rounded-lg font-weight-bold text-uppercase tracking-widest" height="44" @click="confirmDialog = false" :disabled="isExcluding" :color="isDark ? 'white' : 'grey-darken-2'">Cancelar</v-btn>
                    <v-btn color="error" variant="flat" class="flex-grow-1 rounded-lg font-weight-black text-uppercase tracking-widest shadow-soft" height="44" @click="confirmExclusion" :loading="isExcluding">Confirmar</v-btn>
                </div>
            </div>
        </v-card>
    </v-dialog>

    <v-dialog v-model="showPdfEditorModal" max-width="1400" scrollable transition="dialog-bottom-transition">
      <v-card class="apple-hub-layout d-flex flex-column h-100 rounded-3xl position-relative overflow-hidden w-100 shadow-2xl border" :class="isDark ? 'bg-apple-dark text-white border-white-10' : 'bg-apple-light text-grey-darken-4 border-grey-lighten-2'" height="90vh">
         <div class="ambient-glow" :class="isDark ? 'glow-dark' : 'glow-light'"></div>

         <div class="px-8 py-6 d-flex justify-space-between align-center border-b flex-shrink-0 position-relative z-10" :class="isDark ? 'bg-surface-dark/80 border-white-05' : 'bg-white/80 border-grey-lighten-2'" style="backdrop-filter: blur(20px);">
            <div class="d-flex align-center gap-4">
                <v-btn icon variant="tonal" size="small" class="rounded-xl border-opacity-50 shadow-sm" @click="showPdfEditorModal = false"><v-icon size="18">mdi-arrow-left</v-icon></v-btn>
                <div>
                    <h2 class="text-h5 font-weight-black tracking-tight lh-1">Editor de Relatório PDF</h2>
                    <div class="text-[11px] opacity-60 font-mono mt-1 font-weight-bold text-uppercase tracking-widest">Sessão Alvo: {{ focusedSessionId?.slice(0,8).toUpperCase() }}</div>
                </div>
            </div>
            <v-btn variant="flat" color="primary" class="rounded-xl font-weight-black text-uppercase tracking-widest px-6 shadow-sm" height="44" @click="confirmDownloadCustomPdf" :loading="loadingPdf">
              <v-icon start size="18">mdi-printer</v-icon> Gerar Relatório
            </v-btn>
         </div>

         <div class="flex-grow-1 overflow-y-auto pa-8 custom-scroll d-flex flex-column flex-xl-row gap-6 align-start w-100 position-relative z-10">

            <div style="width: 100%; max-width: 450px; gap: 24px;" class="flex-shrink-0 d-flex flex-column">
                <div class="apple-report-card pa-6 rounded-xl border shadow-soft" :class="isDark ? 'bg-surface-dark border-white-05' : 'bg-white border-grey-lighten-2'">
                   <h3 class="text-[11px] text-uppercase font-weight-black mb-5 opacity-70 d-flex align-center tracking-widest"><v-icon start size="16">mdi-card-account-details-outline</v-icon> Metadados do Relatório</h3>
                   <v-text-field v-model="pdfOptions.userName" label="Operador Auditado" density="comfortable" variant="outlined" class="mb-4 rounded-lg font-weight-bold" hide-details />
                   <v-text-field v-model="pdfOptions.openedAt" type="datetime-local" label="Data de Abertura" density="comfortable" variant="outlined" class="mb-4 rounded-lg font-mono font-weight-bold" hide-details />
                   <v-text-field v-model="pdfOptions.closedAt" type="datetime-local" label="Data de Fechamento" density="comfortable" variant="outlined" hide-details class="rounded-lg font-mono font-weight-bold" />
                </div>

                <div class="apple-report-card pa-6 rounded-xl border shadow-soft" :class="isDark ? 'bg-surface-dark border-white-05' : 'bg-white border-grey-lighten-2'">
                   <h3 class="text-[11px] text-uppercase font-weight-black mb-5 opacity-70 d-flex align-center tracking-widest"><v-icon start size="16">mdi-calculator</v-icon> Consolidação Financeira</h3>
                   <div class="d-flex justify-space-between text-[12px] mb-3 opacity-80 font-weight-bold text-uppercase tracking-widest"><span>Fundo Inicial:</span> <span class="font-mono">{{ formatCurrency(pdfTotals.initial) }}</span></div>
                   <div class="d-flex justify-space-between text-[12px] mb-3 text-success font-weight-bold text-uppercase tracking-widest"><span>Entradas na Gaveta (+):</span> <span class="font-mono">{{ formatCurrency(pdfTotals.gavetaIn) }}</span></div>
                   <div class="d-flex justify-space-between text-[12px] mb-5 text-error font-weight-bold text-uppercase tracking-widest"><span>Saídas da Gaveta (-):</span> <span class="font-mono">({{ formatCurrency(pdfTotals.gavetaOut) }})</span></div>
                   <v-divider class="mb-5 opacity-20 border-dashed"></v-divider>
                   <div class="d-flex justify-space-between align-center mb-5">
                       <span class="text-[11px] font-weight-black text-uppercase opacity-70 tracking-widest">Esperado Gaveta:</span>
                       <span class="font-mono font-weight-black text-h6 lh-1">{{ formatCurrency(pdfTotals.expected) }}</span>
                   </div>
                   <div class="d-flex justify-space-between align-center mb-5">
                       <span class="text-[11px] font-weight-black text-uppercase opacity-70 tracking-widest">Declarado Físico:</span>
                       <v-text-field v-model="userReportedOverride" type="number" prefix="R$" density="compact" variant="outlined" hide-details style="max-width: 150px" class="rounded-lg font-mono text-primary font-weight-black" />
                   </div>
                   <div class="mt-2 pa-4 text-center rounded-xl border font-weight-black text-[12px] text-uppercase tracking-widest transition-all" :class="pdfTotals.diff === 0 ? 'bg-success-darken-4/10 text-success border-success/30' : 'bg-error-darken-4/10 text-error border-error/30'">
                       DIFERENÇA: {{ formatCurrency(pdfTotals.diff) }}
                   </div>
                </div>
            </div>

            <div class="flex-grow-1 d-flex flex-column gap-6 w-100" style="min-width: 0;">
                <div class="apple-report-card rounded-xl border shadow-soft overflow-hidden d-flex flex-column" :class="isDark ? 'bg-surface-dark border-amber-900/40' : 'bg-white border-amber-200'">
                    <div class="px-6 py-4 border-b d-flex justify-space-between align-center" :class="isDark ? 'bg-amber-900/20 border-white-05' : 'bg-amber-50 border-amber-100'">
                        <span class="font-weight-black text-[11px] text-uppercase tracking-widest text-amber-darken-3 d-flex align-center gap-2"><v-icon size="16">mdi-cash-register</v-icon> Tabela 1: Gaveta Física</span>
                        <v-chip size="small" color="amber-darken-3" variant="flat" class="font-weight-black px-3 rounded-lg">{{ pdfGavetaRows.length }} itens</v-chip>
                    </div>
                    <div class="pa-0 overflow-x-auto">
                        <table class="w-100 pdf-edit-table" :class="isDark ? 'dark-mode' : ''">
                            <thead><tr><th style="width: 180px">Data/Hora</th><th>Descrição</th><th style="width: 150px">Tipo</th><th style="width: 160px">Valor (R$)</th><th style="width: 60px"></th></tr></thead>
                            <tbody>
                                <tr v-for="(row, idx) in pdfGavetaRows" :key="row.id">
                                    <td><v-text-field v-model="row.date" type="datetime-local" density="compact" variant="plain" hide-details class="text-[11px] font-mono font-weight-bold" /></td>
                                    <td><v-text-field v-model="row.description" density="compact" variant="plain" hide-details class="text-[12px] font-weight-bold" /></td>
                                    <td><v-select v-model="row.direction" :items="[{title:'Entrada (+)',value:'in'},{title:'Saída (-)',value:'out'}]" density="compact" variant="plain" hide-details class="text-[11px] font-weight-bold text-uppercase" /></td>
                                    <td><v-text-field v-model="row.amount" type="number" density="compact" variant="plain" hide-details class="text-[13px] font-mono font-weight-black text-primary" /></td>
                                    <td class="text-center"><v-btn icon="mdi-close" size="small" color="grey" variant="text" @click="pdfGavetaRows.splice(idx, 1)"></v-btn></td>
                                </tr>
                                <tr v-if="pdfGavetaRows.length === 0"><td colspan="5" class="text-center text-[11px] py-8 opacity-50 font-weight-bold text-uppercase tracking-widest">Tabela Vazia.</td></tr>
                            </tbody>
                        </table>
                    </div>
                </div>

                <div class="apple-report-card rounded-xl border shadow-soft overflow-hidden d-flex flex-column" :class="isDark ? 'bg-surface-dark border-indigo-900/40' : 'bg-white border-indigo-200'">
                    <div class="px-6 py-4 border-b d-flex justify-space-between align-center" :class="isDark ? 'bg-indigo-900/20 border-white-05' : 'bg-indigo-50 border-indigo-100'">
                        <span class="font-weight-black text-[11px] text-uppercase tracking-widest text-indigo-darken-2 d-flex align-center gap-2"><v-icon size="16">mdi-cloud-check</v-icon> Tabela 2: Virtual (PIX/Cartão)</span>
                        <v-chip size="small" color="indigo-darken-2" variant="flat" class="font-weight-black px-3 rounded-lg">{{ pdfVirtualRows.length }} itens</v-chip>
                    </div>
                    <div class="pa-0 overflow-x-auto">
                        <table class="w-100 pdf-edit-table" :class="isDark ? 'dark-mode' : ''">
                            <thead><tr><th style="width: 180px">Data/Hora</th><th>Descrição</th><th style="width: 150px">Método</th><th style="width: 160px">Valor (R$)</th><th style="width: 60px"></th></tr></thead>
                            <tbody>
                                <tr v-for="(row, idx) in pdfVirtualRows" :key="row.id">
                                    <td><v-text-field v-model="row.date" type="datetime-local" density="compact" variant="plain" hide-details class="text-[11px] font-mono font-weight-bold" /></td>
                                    <td><v-text-field v-model="row.description" density="compact" variant="plain" hide-details class="text-[12px] font-weight-bold" /></td>
                                    <td><v-text-field v-model="row.method" density="compact" variant="plain" hide-details class="text-[11px] font-weight-bold text-uppercase" /></td>
                                    <td><v-text-field v-model="row.amount" type="number" density="compact" variant="plain" hide-details class="text-[13px] font-mono font-weight-black text-primary" /></td>
                                    <td class="text-center"><v-btn icon="mdi-close" size="small" color="grey" variant="text" @click="pdfVirtualRows.splice(idx, 1)"></v-btn></td>
                                </tr>
                                <tr v-if="pdfVirtualRows.length === 0"><td colspan="5" class="text-center text-[11px] py-8 opacity-50 font-weight-bold text-uppercase tracking-widest">Tabela Vazia.</td></tr>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
         </div>
      </v-card>
    </v-dialog>

  </v-dialog>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue';
import { supabase } from '@/api/supabase';
import { useUserStore } from '@/stores/user';
import { useThemeStore } from '@/stores/theme';
import { format, startOfDay, endOfDay } from 'date-fns';
import { useCashReport } from '@/composables/useCashReport';
import { useMjCashSessionStore } from '@/stores/mjCashSession';
import { useAppStore } from '@/stores/app';

const appStore = useAppStore();
const cashStore = useMjCashSessionStore();
const userStore = useUserStore();
const themeStore = useThemeStore();
const { generateEditableClosingReport, generateClosingReport } = useCashReport();

const isDark = computed(() => themeStore.currentMode === 'dark');

type Direction = 'in' | 'out';
const props = defineProps<{ modelValue: boolean; session: any; }>();
const emit = defineEmits(['update:modelValue', 'refresh']);

const loadingData = ref(false);
const loadingPdf = ref(false);
const isApplying = ref(false);

const storeSessions = ref<any[]>([]);
const allMovements = ref<any[]>([]);
const allOrders = ref<any[]>([]);
const auditRows = ref<AuditRow[]>([]);
const blackboxLogs = ref<any[]>([]);
const focusedSessionId = ref<string | null>(null);
const activeTab = ref('dashboard');

const auditMethods = [
  { value: 'dinheiro', title: 'Dinheiro (Espécie)' },
  { value: 'pix', title: 'PIX' },
  { value: 'cartao_credito', title: 'Cartão de Crédito' },
  { value: 'cartao_debito', title: 'Cartão de Débito' },
  { value: 'transferencia', title: 'Transferência Bancária' },
  { value: 'boleto', title: 'Boleto' },
  { value: 'cheque', title: 'Cheque' },
  { value: 'deposito', title: 'Depósito' },
  { value: 'outro', title: 'Outro' }
];

const isGaveta = (method: string) => {
    if(!method) return true;
    const m = method.toLowerCase();
    return m.includes('dinheiro') || m.includes('espécie');
};

type AuditRow = {
  key: string; sourceTable: string; sourceLabel: string; sourceId: string; sourceIdShort: string;
  description: string; paidAt: string; amount: number; direction: Direction; includeInCash: boolean;
  paymentMethodId: string | null; paymentMethodLabel: string | null; notes: string; auditMethod: string;
};

// CRUD MANUAL & OCULTAÇÃO
const showAddEntryModal = ref(false);
const savingEntry = ref(false);
const isEditing = ref(false);
const editingId = ref<string | null>(null);

const confirmDialog = ref(false);
const itemToExclude = ref<any>(null);
const isExcluding = ref(false);

const newEntry = ref({
    type: 'supply', amount: null as number | null, description: '', method: null as string | null,
    orderId: null as string | null, date: format(new Date(), 'yyyy-MM-dd'), time: format(new Date(), 'HH:mm')
});

const getMethodName = (id: any) => {
    if (!id) return 'Dinheiro';
    const m = cashStore.availablePaymentMethods.find((pm:any) => String(pm.id) === String(id) || String(pm.gestao_click_id) === String(id));
    return m ? m.name : String(id);
};

const getMethodColorClass = (method: string) => {
    if(!method) return 'dinheiro';
    const m = method.toLowerCase();
    if (m.includes('dinheiro') || m.includes('espécie')) return 'dinheiro';
    if (m.includes('pix') || m.includes('transf')) return 'pix';
    if (m.includes('cart')) return 'cartao';
    return 'outro';
};

// MOTOR MATEMÁTICO (INCLUINDO PDV sale_cash)
const calculateSessionMath = (sessionId: string) => {
    const session = storeSessions.value.find(s => s.id === sessionId);
    if (!session) return null;

    const movs = allMovements.value.filter(m => m.session_id === sessionId);
    const ords = allOrders.value.filter(o => o.cash_session_id === sessionId && o.status !== 'cancelled');

    let initial = Number(session.initial_balance || 0);
    let declared = session.status === 'closed' ? Number(session.final_balance_user || 0) : 0;

    let cashSales = 0; let supply = 0; let bleed = 0; let auditInGaveta = 0; let auditOutGaveta = 0;
    let virtualPix = 0; let virtualCard = 0; let virtualOther = 0; let auditInVirtual = 0; let auditOutVirtual = 0;

    movs.forEach(m => {
        const amt = Number(m.amount);
        if (m.type === 'supply') supply += amt;
        if (m.type === 'bleed') bleed += Math.abs(amt);
        if (m.type === 'sale_cash') cashSales += Math.abs(amt); // CONTA VENDAS PDV (DINHEIRO) NA MATEMÁTICA FÍSICA

        if (m.type === 'in_audit' || m.type === 'out_audit') {
            const match = (m.description || '').match(/^\[(.*?)\]/);
            const methodClean = match ? match[1].toLowerCase() : 'dinheiro';
            const isGav = isGaveta(methodClean);

            if (m.type === 'in_audit') { isGav ? auditInGaveta += Math.abs(amt) : auditInVirtual += Math.abs(amt); }
            if (m.type === 'out_audit') { isGav ? auditOutGaveta += Math.abs(amt) : auditOutVirtual += Math.abs(amt); }
        }
    });

    const processPayment = (val: number, methodId: string, explicitName: string = '', generalMethodName: string = '') => {
        let mName = String(explicitName || '').toLowerCase();
        if (!mName || mName === String(methodId).toLowerCase() || mName === 'undefined') mName = String(getMethodName(methodId)).toLowerCase();
        let combinedName = (mName + " " + String(generalMethodName).toLowerCase()).trim();
        const isPix = combinedName.includes('pix') || combinedName.includes('transfer');
        const isCard = combinedName.includes('cart') || combinedName.includes('crédito');
        const isDinheiro = combinedName.includes('dinheiro') || combinedName.includes('espécie');

        if (isPix) virtualPix += val;
        else if (isCard) virtualCard += val;
        else if (isDinheiro) cashSales += val;
        else { if (cashStore.isCashMethod(methodId)) cashSales += val; else virtualOther += val; }
    };

    ords.forEach(o => {
        const d = o.details || {};
        const generalMethodName = d.payment_method || '';
        if (d.downPayments && Array.isArray(d.downPayments)) { d.downPayments.forEach((dp: any) => { if (Number(dp.value) > 0) processPayment(Number(dp.value), dp.method_id, dp.method_name, generalMethodName); }); }
        else if (Number(d.entry_value) > 0) { processPayment(Number(d.entry_value), d.entry_method || d.entry_method_id, d.entry_method_name || d.entry_method, generalMethodName); }
        if (d.installments && d.installments.length === 1 && (!d.downPayments?.length) && (!d.entry_value || Number(d.entry_value) === 0)) { const inst = d.installments[0]; if (Number(inst.value) > 0) processPayment(Number(inst.value), inst.payment_method_id, '', generalMethodName); }
    });

    const expectedGaveta = initial + cashSales + supply - bleed + auditInGaveta - auditOutGaveta;
    const difference = session.status === 'closed' ? (declared - expectedGaveta) : 0;
    const virtualTotal = virtualPix + virtualCard + virtualOther + auditInVirtual - auditOutVirtual;

    return {
        id: session.id, operatorName: session.user?.full_name || 'Operador', status: session.status,
        openedAt: session.opened_at, closedAt: session.closed_at,
        initial, declared, expectedGaveta, difference,
        cashSales, supply, bleed, auditInGaveta, auditOutGaveta,
        virtualPix, virtualCard, virtualOther, auditInVirtual, auditOutVirtual, virtualTotal,
        rawSession: session
    };
};

const sessionMaths = computed(() => storeSessions.value.map(s => calculateSessionMath(s.id)).filter(Boolean) as ReturnType<typeof calculateSessionMath>[]);

const storeTotals = computed(() => {
    let initial = 0; let cashSales = 0; let supply = 0; let bleed = 0; let expected = 0; let declared = 0; let diff = 0;
    sessionMaths.value.forEach(m => {
        initial += m!.initial; cashSales += m!.cashSales + m!.auditInGaveta; supply += m!.supply; bleed += m!.bleed + m!.auditOutGaveta; expected += m!.expectedGaveta;
        if (m!.status === 'closed') { declared += m!.declared; diff += m!.difference; }
    });
    return { initial, cashSales, supply, bleed, expected, declared, diff };
});

const focusedMath = computed(() => focusedSessionId.value ? calculateSessionMath(focusedSessionId.value) : null);
const focusedOrders = computed(() => focusedSessionId.value ? allOrders.value.filter(o => o.cash_session_id === focusedSessionId.value) : []);
const focusedMovements = computed(() => focusedSessionId.value ? allMovements.value.filter(m => m.session_id === focusedSessionId.value) : []);
const hasAnyCashIncluded = computed(() => auditRows.value.some(r => r.includeInCash));

const focusSession = (id: string) => { focusedSessionId.value = id; activeTab.value = 'dashboard'; };

// CARGA DE DADOS DO BANCO
const fetchStoreDayData = async () => {
    if (!props.session?.store_id || !props.session?.opened_at) return;
    loadingData.value = true;
    await cashStore.fetchPaymentMethods();
    await cashStore.fetchStoreConfig(props.session.store_id);

    const dayStart = startOfDay(new Date(props.session.opened_at)).toISOString();
    const dayEnd = endOfDay(new Date(props.session.opened_at)).toISOString();

    try {
        const { data: sessions } = await supabase.from('mj_cash_sessions').select('*, user:profiles(full_name)').eq('store_id', props.session.store_id).gte('opened_at', dayStart).lte('opened_at', dayEnd).order('opened_at', { ascending: true });
        storeSessions.value = sessions || [];

        const sessionIds = storeSessions.value.map(s => s.id);
        if (sessionIds.length > 0) {
            const { data: movs } = await supabase.from('mj_cash_movements').select('*').in('session_id', sessionIds).order('created_at', { ascending: true });
            allMovements.value = movs || [];
            const { data: ords } = await supabase.from('orders').select('*, order_items(*)').in('cash_session_id', sessionIds);
            allOrders.value = ords || [];
        }

        if (!focusedSessionId.value && props.session.id) focusedSessionId.value = props.session.id;
        await fetchAuditRows(dayStart, dayEnd);
    } catch(e) { console.error(e); } finally { loadingData.value = false; }
};

const fetchAuditRows = async (queryMin: string, queryMax: string) => {
  const rows: AuditRow[] = [];
  const pushRow = (r: Partial<AuditRow>) => {
      rows.push({
          key: `${r.sourceTable}:${r.sourceId}`, sourceTable: r.sourceTable || '', sourceLabel: r.sourceLabel || '', sourceId: String(r.sourceId),
          sourceIdShort: String(r.sourceId).slice(0,8), description: r.description || '', paidAt: r.paidAt || '', amount: Number(r.amount),
          direction: (r.direction || 'in') as Direction, includeInCash: false, paymentMethodId: null, paymentMethodLabel: null, notes: '', auditMethod: 'dinheiro'
      });
  };

  try {
      const currentUserId = focusedMath.value?.rawSession?.user_id || props.session?.user_id;
      let query = supabase.from('finance_receivables').select('*').gte('payment_date', queryMin).lte('payment_date', queryMax);
      if (currentUserId) query = query.eq('user_id', currentUserId);

      const { data: rec } = await query;
      rec?.forEach((r: any) => pushRow({ sourceTable: 'finance_receivables', sourceLabel: 'Receita Sistêmica', sourceId: r.id, description: r.description, paidAt: r.payment_date, amount: r.paid_value || r.value, direction: 'in' }));
  } catch (err) { console.error(err); }
  auditRows.value = rows.sort((a, b) => new Date(a.paidAt).getTime() - new Date(b.paidAt).getTime());
};

watch(focusedSessionId, async (newId) => {
    if(!newId) { blackboxLogs.value = []; return; }
    try {
        const { data } = await supabase.from('mj_cash_extraction_audit').select('*').eq('session_id', newId).order('created_at', { ascending: true });
        blackboxLogs.value = data || [];
    } catch(e) { console.error("Erro fetch caixa preta", e); }
});

const applyAuditToCashMovements = async () => {
  if (!focusedSessionId.value || !confirm(`Confirmar inclusão destes lançamentos no caixa de ${focusedMath.value?.operatorName}?`)) return;
  isApplying.value = true;
  try {
    const s = storeSessions.value.find(s => s.id === focusedSessionId.value);
    const payload = auditRows.value.filter(r => r.includeInCash).map(r => ({
        session_id: focusedSessionId.value, user_id: userStore.user?.id || s.user_id,
        type: r.direction === 'in' ? 'in_audit' : 'out_audit', amount: r.direction === 'in' ? Math.abs(r.amount) : -Math.abs(r.amount),
        description: `[${r.auditMethod.toUpperCase()}] ${r.description}`, source_table: r.sourceTable, source_id: r.sourceId, note: r.notes
    }));
    if(payload.length > 0) {
        const { error } = await supabase.from('mj_cash_movements').insert(payload);
        if (error) throw error; appStore.showSnackbar('Lançamentos incluídos.', 'success'); emit('refresh'); await fetchStoreDayData();
    }
  } catch (e: any) { alert('Erro: ' + e.message); } finally { isApplying.value = false; }
};

// EXTRATO DETALHADO (LIVRO CAIXA) E FUNÇÕES DE EXCLUSÃO
const detailedLedger = computed(() => {
    if (!focusedMath.value) return [];
    const rows: any[] = [];

    for (const m of focusedMovements.value) {
        let desc = m.description || m.type;
        const match = desc.match(/^\[(.*?)\]/);
        let methodRaw = match ? match[1].toUpperCase() : 'DINHEIRO';
        if (m.type === 'sale_cash') methodRaw = 'DINHEIRO';
        desc = desc.replace(/^\[.*?\]\s*/, '').replace('AUDITORIA: ', '').trim();

        let direction = 'in';
        if (m.type === 'bleed' || m.type.includes('out_audit') || m.amount < 0) direction = 'out';

        let label = direction === 'in' ? 'Entrada (Man)' : 'Saída (Man)';
        if (m.type === 'supply') label = 'Suprimento';
        if (m.type === 'bleed') label = 'Sangria';
        if (m.type === 'opening') label = 'Abertura';
        if (m.type === 'sale_cash') label = 'Venda PDV';

        let orderNumberDisplay = null;
        if (m.order_id) {
            const found = allOrders.value.find(o => o.id === m.order_id);
            if (found) orderNumberDisplay = found.order_number;
        }

        rows.push({ id: `mov_${m.id}`, date: m.created_at, description: desc, label: label, method: methodRaw, direction: direction, amount: Math.abs(Number(m.amount)), orderNumber: orderNumberDisplay });
    }

    for (const o of focusedOrders.value) {
        const d = o.details || {}; const genMethod = d.payment_method || '';
        const addRow = (val: number, methodId: string, explicitName: string, sourceRef: string) => {
            let mName = String(explicitName || '').toLowerCase();
            if (!mName || mName === String(methodId).toLowerCase() || mName === 'undefined') mName = String(getMethodName(methodId)).toLowerCase();
            const combinedName = (mName + " " + String(genMethod).toLowerCase()).trim();
            const isPix = combinedName.includes('pix') || combinedName.includes('transfer');
            const isCard = combinedName.includes('cart');

            rows.push({
                id: `ord_${o.id}_${Math.random()}`, date: o.created_at, description: `Pedido #${o.order_number} (${sourceRef} - ${o.customer_name})`,
                label: 'Recebimento', method: isPix ? 'PIX' : (isCard ? 'CARTÃO' : mName.toUpperCase().slice(0, 15)), direction: 'in', amount: val, orderNumber: o.order_number
            });
        };

        if (d.downPayments && Array.isArray(d.downPayments)) { d.downPayments.forEach((dp: any) => { if (Number(dp.value) > 0) addRow(Number(dp.value), dp.method_id, dp.method_name, 'Sinal'); }); }
        else if (Number(d.entry_value) > 0) { addRow(Number(d.entry_value), d.entry_method || d.entry_method_id, d.entry_method_name || d.entry_method, 'Sinal'); }
        if (d.installments && d.installments.length === 1 && (!d.downPayments?.length) && (!d.entry_value || Number(d.entry_value) === 0)) { const inst = d.installments[0]; if (Number(inst.value) > 0) addRow(Number(inst.value), inst.payment_method_id, '', 'Pgt. Único'); }
    }

    return rows.sort((a,b) => new Date(b.date).getTime() - new Date(a.date).getTime());
});

const requestExclusion = (row: any) => {
    itemToExclude.value = row;
    confirmDialog.value = true;
};

const confirmExclusion = async () => {
    if (!itemToExclude.value) return;
    isExcluding.value = true;

    try {
        const row = itemToExclude.value;

        // Se for um registro manual ou do PDV (Venda Balcão) salvo diretamente nos cash_movements
        if (row.id.startsWith('mov_')) {
            const movId = row.id.replace('mov_', '');

            // 1. Apaga do Cash Movements
            const { error: errMov } = await supabase.from('mj_cash_movements').delete().eq('id', movId);
            if (errMov) throw errMov;

            // 2. Se tiver vinculado a uma venda no PDV/Recebíveis, apaga lá também para desatar a sujeira
            try {
                await supabase.from('finance_receivables').delete().ilike('description', `%${row.orderNumber || ''}%`).eq('session_id', focusedSessionId.value);
            } catch (ignore) {}

        // Se for um Pedido ERP (NewOrder) amarrado à sessão
        } else if (row.id.startsWith('ord_')) {
            const ordId = row.id.split('_')[1];
            // Ao invés de deletar, desvinculamos o cash_session para que o pedido pare de computar no caixa.
            const { error: errOrd } = await supabase.from('orders').update({ cash_session_id: null }).eq('id', ordId);
            if (errOrd) throw errOrd;
        }

        appStore.showSnackbar('Registro ocultado/excluído com sucesso!', 'success');
        confirmDialog.value = false;
        itemToExclude.value = null;

        emit('refresh');
        await fetchStoreDayData();
    } catch (e: any) {
        appStore.showSnackbar(`Erro ao excluir: ${e.message}`, 'error');
    } finally {
        isExcluding.value = false;
    }
};

const openAddEntryModal = () => {
    isEditing.value = false; editingId.value = null;
    newEntry.value = { type: 'supply', amount: null, description: '', method: null, orderId: null, date: format(new Date(), 'yyyy-MM-dd'), time: format(new Date(), 'HH:mm') };
    showAddEntryModal.value = true;
};

const editMovement = (row: any) => {
    const mov = focusedMovements.value.find(m => m.id === row.id.replace('mov_', ''));
    if(!mov) return;
    isEditing.value = true; editingId.value = mov.id;

    let matchedMethodId = null;
    const methodMatch = cashStore.availablePaymentMethods.find((m:any) => m.name.toUpperCase() === row.method.toUpperCase());
    if (methodMatch) matchedMethodId = methodMatch.id;

    let cleanDesc = mov.description || ''; cleanDesc = cleanDesc.replace(/^\[.*?\]\s*/, '');

    newEntry.value = { type: mov.type === 'supply' || mov.type === 'bleed' ? mov.type : 'supply', amount: Math.abs(mov.amount), description: cleanDesc, method: matchedMethodId, orderId: mov.order_id || null, date: format(new Date(mov.created_at), 'yyyy-MM-dd'), time: format(new Date(mov.created_at), 'HH:mm') };
    showAddEntryModal.value = true;
};

const saveManualEntry = async () => {
    if (!newEntry.value.amount) return appStore.showSnackbar('Digite um valor válido.', 'warning');
    savingEntry.value = true;
    try {
        const dateTimeString = `${newEntry.value.date}T${newEntry.value.time}:00`;
        const methodName = newEntry.value.method ? getMethodName(newEntry.value.method).toUpperCase() : 'DINHEIRO';

        const payload = {
            session_id: focusedSessionId.value || props.session.id, user_id: userStore.user?.id, type: newEntry.value.type,
            amount: newEntry.value.type === 'bleed' ? -Math.abs(newEntry.value.amount) : Math.abs(newEntry.value.amount),
            description: `[${methodName}] ${newEntry.value.description || newEntry.value.type}`, order_id: newEntry.value.orderId || null, created_at: new Date(dateTimeString).toISOString()
        };

        if (isEditing.value && editingId.value) { const { error } = await supabase.from('mj_cash_movements').update(payload).eq('id', editingId.value); if (error) throw error; appStore.showSnackbar('Lançamento atualizado', 'success'); }
        else { const { error } = await supabase.from('mj_cash_movements').insert(payload); if (error) throw error; appStore.showSnackbar('Lançamento registrado', 'success'); }

        showAddEntryModal.value = false; emit('refresh'); await fetchStoreDayData();
    } catch (e: any) { appStore.showSnackbar(e.message, 'error'); } finally { savingEntry.value = false; }
};

// === EDITOR DE PDF ===
const showPdfEditorModal = ref(false);
const pdfOptions = ref({ userName: '', openedAt: '', closedAt: '' });
const pdfGavetaRows = ref<any[]>([]);
const pdfVirtualRows = ref<any[]>([]);
const userReportedOverride = ref<number>(0);

const formatInputDate = (iso: string) => {
    if(!iso) return '';
    const dt = new Date(iso); dt.setMinutes(dt.getMinutes() - dt.getTimezoneOffset());
    return dt.toISOString().slice(0, 16);
};

const openPdfEditor = () => {
    if (!focusedMath.value) return;
    pdfGavetaRows.value = []; pdfVirtualRows.value = [];
    userReportedOverride.value = Number(focusedMath.value.declared || 0);

    const s = focusedMath.value.rawSession;
    pdfOptions.value.userName = focusedMath.value.operatorName;
    pdfOptions.value.openedAt = s?.opened_at ? formatInputDate(s.opened_at) : '';
    pdfOptions.value.closedAt = s?.closed_at ? formatInputDate(s.closed_at) : formatInputDate(new Date().toISOString());

    for (const m of focusedMovements.value) {
        if (m.type === 'opening') continue;
        let desc = m.description || m.type;
        const match = desc.match(/^\[(.*?)\]/);
        let methodRaw = match ? match[1].toUpperCase() : 'DINHEIRO';
        if (m.type === 'sale_cash') methodRaw = 'DINHEIRO';
        desc = desc.replace(/^\[.*?\]\s*/, '').replace('AUDITORIA: ', '').trim();

        let direction = 'in'; if (m.type === 'bleed' || m.type.includes('out_audit') || m.amount < 0) direction = 'out';
        let label = direction === 'in' ? 'Entrada' : 'Saída';
        if (m.type === 'supply') label = 'Suprimento'; if (m.type === 'bleed') label = 'Sangria'; if (m.type === 'sale_cash') label = 'Venda';

        const row = { id: `m_${m.id}`, date: formatInputDate(m.created_at), description: desc, label: label, method: methodRaw, direction, amount: Math.abs(Number(m.amount)) };
        if (methodRaw.includes('DINHEIRO') || methodRaw.includes('ESPÉCIE') || m.type === 'sale_cash') pdfGavetaRows.value.push(row); else pdfVirtualRows.value.push(row);
    }

    for (const o of focusedOrders.value) {
        const d = o.details || {}; const genMethod = d.payment_method || '';
        const addRow = (val: number, methodId: string, explicitName: string, sourceRef: string) => {
            let mName = String(explicitName || '').toLowerCase();
            if (!mName || mName === String(methodId).toLowerCase() || mName === 'undefined') mName = String(getMethodName(methodId)).toLowerCase();
            const combinedName = (mName + " " + String(genMethod).toLowerCase()).trim();
            const isPix = combinedName.includes('pix') || combinedName.includes('transfer');
            const isCard = combinedName.includes('cart');
            const isDinheiro = combinedName.includes('dinheiro') || combinedName.includes('espécie');

            let isGavetaLocal = isDinheiro; if (!isGavetaLocal && !isPix && !isCard && cashStore.isCashMethod(methodId)) isGavetaLocal = true;

            const row = { id: `o_${o.id}_${Math.random()}`, date: formatInputDate(o.created_at), description: `Pedido #${o.order_number} (${sourceRef})`, label: 'Venda', method: isPix ? 'PIX' : (isCard ? 'CARTÃO' : mName.toUpperCase().slice(0, 15)), direction: 'in', amount: val };
            if (isGavetaLocal) pdfGavetaRows.value.push(row); else pdfVirtualRows.value.push(row);
        };

        if (d.downPayments && Array.isArray(d.downPayments)) { d.downPayments.forEach((dp: any) => { if (Number(dp.value) > 0) addRow(Number(dp.value), dp.method_id, dp.method_name, 'Sinal'); }); }
        else if (Number(d.entry_value) > 0) { addRow(Number(d.entry_value), d.entry_method || d.entry_method_id, d.entry_method_name || d.entry_method, 'Sinal'); }
        if (d.installments && d.installments.length === 1 && (!d.downPayments?.length) && (!d.entry_value || Number(d.entry_value) === 0)) { const inst = d.installments[0]; if (Number(inst.value) > 0) addRow(Number(inst.value), inst.payment_method_id, '', 'Pgt. Único'); }
    }

    const deduplicate = (rows: any[]) => {
      const unique: any[] = [];
      for (const row of rows) {
          const match = row.description.match(/#(\d+)/);
          const orderNum = match ? match[1] : null;
          const isDup = unique.some(ex => {
              if (ex.amount !== row.amount) return false;
              if (orderNum && ex.description.includes(`#${orderNum}`)) return true;
              if (ex.description === row.description && ex.method === row.method) return true;
              return false;
          });
          if (!isDup) unique.push(row);
      }
      return unique;
    };

    pdfGavetaRows.value = deduplicate(pdfGavetaRows.value).sort((a,b) => new Date(a.date).getTime() - new Date(b.date).getTime());
    pdfVirtualRows.value = deduplicate(pdfVirtualRows.value).sort((a,b) => new Date(a.date).getTime() - new Date(b.date).getTime());
    showPdfEditorModal.value = true;
};

const pdfTotals = computed(() => {
    const initial = Number(focusedMath.value?.initial || 0);
    const userReported = Number(userReportedOverride.value || 0);
    let gavetaIn = 0; let gavetaOut = 0;
    pdfGavetaRows.value.forEach(r => { if(r.direction === 'in') gavetaIn += Number(r.amount); else gavetaOut += Number(r.amount); });
    let virtualIn = 0; let virtualOut = 0;
    pdfVirtualRows.value.forEach(r => { if(r.direction === 'in') virtualIn += Number(r.amount); else virtualOut += Number(r.amount); });

    const expected = initial + gavetaIn - gavetaOut;
    const diff = userReported - expected;
    return { initial, gavetaIn, gavetaOut, virtualIn, virtualOut, expected, userReported, diff };
});

const generateQuickPdf = async () => {
    if (!focusedMath.value) return;
    loadingPdf.value = true;
    try { await generateClosingReport(focusedMath.value.rawSession, focusedMovements.value, focusedMath.value.rawSession.store?.name, focusedMath.value.operatorName, focusedOrders.value); }
    catch (e) { console.error(e); } finally { loadingPdf.value = false; }
};

const confirmDownloadCustomPdf = async () => {
    loadingPdf.value = true;
    try {
        await generateEditableClosingReport({
            header: {
                sessionId: focusedSessionId.value as string, storeName: focusedMath.value?.rawSession.store?.name || 'Loja', operatorName: pdfOptions.value.userName,
                openedAt: pdfOptions.value.openedAt ? new Date(pdfOptions.value.openedAt).toISOString() : new Date().toISOString(), closedAt: pdfOptions.value.closedAt ? new Date(pdfOptions.value.closedAt).toISOString() : new Date().toISOString()
            },
            kpis: pdfTotals.value, physicalTable: pdfGavetaRows.value, virtualTable: pdfVirtualRows.value
        });
        showPdfEditorModal.value = false;
    } catch (e) { console.error(e); } finally { loadingPdf.value = false; }
};

// FORMATTERS
const formatTimeOnly = (d: string) => d ? format(new Date(d), 'HH:mm') : '-';
const formatDateOnly = (d: string) => { if (!d) return '-'; return new Date(d).toLocaleString('pt-BR', { day: '2-digit', month: '2-digit', year: 'numeric' }); };
const formatDateTimeSeconds = (d: string) => d ? format(new Date(d), 'dd/MM HH:mm:ss') : '-';
const formatCurrency = (val: any) => new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(Number(val) || 0);

watch(() => props.modelValue, (val) => {
    if (val) { focusedSessionId.value = props.session?.id || null; fetchStoreDayData(); }
    else { storeSessions.value = []; allMovements.value = []; allOrders.value = []; focusedSessionId.value = null; }
});
</script>

<style scoped>
/* APLICAÇÃO DO DESIGN QUADRADO (2px base) */
.rounded-sm { border-radius: 4px !important; }
.rounded-md { border-radius: 6px !important; }
.rounded-lg { border-radius: 8px !important; }
.rounded-xl { border-radius: 12px !important; }
.rounded-2xl { border-radius: 16px !important; }
.rounded-3xl { border-radius: 20px !important; }

.font-sans { font-family: 'Inter', system-ui, sans-serif; }
.bg-background-dark { background-color: #0c0d10; }
.bg-surface-dark { background-color: #14151a; }
.border-r-dark { border-right: 1px solid rgba(255, 255, 255, 0.05); }
.border-r-light { border-right: 1px solid rgba(0, 0, 0, 0.08); }

.border-white-05 { border-color: rgba(255,255,255,0.05) !important; }
.border-white-10 { border-color: rgba(255,255,255,0.1) !important; }
.bg-white-02 { background-color: rgba(255,255,255,0.02) !important; }
.bg-white-05 { background-color: rgba(255,255,255,0.05) !important; }

.shadow-right { box-shadow: 2px 0 10px rgba(0,0,0,0.03); }
.shadow-micro { box-shadow: 0 2px 8px rgba(0,0,0,0.04); }
.shadow-glow { box-shadow: 0 0 20px rgba(var(--v-theme-primary), 0.15); }
.shadow-soft { box-shadow: 0 4px 14px rgba(0,0,0,0.1) !important; }

.tracking-widest { letter-spacing: 0.1em; }
.letter-spacing-1 { letter-spacing: 0.05em; }
.lh-1 { line-height: 1.1; }
.font-mono { font-family: 'JetBrains Mono', monospace !important; }
.font-weight-semibold { font-weight: 600; }

.icon-circle-lg { width: 80px; height: 80px; display: flex; align-items: center; justify-content: center; }
.icon-box-sm { width: 32px; height: 32px; }
.icon-box-md { width: 48px; height: 48px; }
.icon-box-lg { width: 56px; height: 56px; }

/* TABS ELEGANTES */
.elegant-tabs { border-bottom: 1px solid transparent; }
.elegant-tabs :deep(.v-btn) { text-transform: none; letter-spacing: 0; padding: 0 16px; margin-right: 8px; opacity: 0.6; }
.elegant-tabs :deep(.v-btn--selected) { opacity: 1; }
.elegant-tabs :deep(.v-tab__slider) { height: 2px; border-radius: 2px 2px 0 0; }

/* GRID MACRO */
.d-grid { display: grid; }
.kpi-macro-grid { grid-template-columns: repeat(5, 1fr); }
@media (max-width: 1200px) { .kpi-macro-grid { grid-template-columns: repeat(3, 1fr); } }

/* TABELAS MODERNAS */
.grid-ledger-header, .grid-ledger-row, .grid-audit-header, .grid-audit-row, .grid-blackbox-header, .grid-blackbox-row {
    display: grid;
    align-items: center;
}
.grid-ledger-header, .grid-ledger-row { grid-template-columns: 80px minmax(200px, 1fr) 100px 100px 120px 80px; }
.grid-audit-header, .grid-audit-row { grid-template-columns: 60px 100px minmax(150px, 1fr) 150px 120px 100px; }
.grid-blackbox-header, .grid-blackbox-row { grid-template-columns: 120px 120px 150px minmax(150px, 1fr) 100px; }

.hover-bg-light:hover { background-color: #F8FAFC !important; }
.hover-bg-dark:hover { background-color: rgba(255,255,255,0.02) !important; }

/* CHIPS E PILLS */
.method-chip { font-size: 9px; font-weight: 800; color: white; padding: 3px 8px; border-radius: 4px; text-transform: uppercase; letter-spacing: 0.5px; }
.method-dinheiro { background-color: #388E3C; }
.method-pix { background-color: #00897B; }
.method-cartao { background-color: #1976D2; }
.method-outro { background-color: #607D8B; }

.status-pill { font-size: 9px; font-weight: 800; padding: 3px 8px; border-radius: 4px; text-transform: uppercase; letter-spacing: 0.5px; }
.pill-success { background-color: rgba(76, 175, 80, 0.1); color: #4CAF50; border: 1px solid rgba(76, 175, 80, 0.2); }
.pill-error { background-color: rgba(244, 67, 54, 0.1); color: #F44336; border: 1px solid rgba(244, 67, 54, 0.2); }

.dot-indicator { width: 6px; height: 6px; border-radius: 50%; }

/* UTILS */
.transition-all { transition: all 0.2s ease-in-out; }
.cursor-pointer { cursor: pointer; }
.h-20 { height: 20px !important; }
.hover-elevate:hover { transform: translateY(-1px); box-shadow: 0 4px 10px rgba(0,0,0,0.05); }

.custom-scroll::-webkit-scrollbar { width: 6px; height: 6px; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.2); border-radius: 4px; }
.custom-scroll::-webkit-scrollbar-thumb:hover { background: rgba(128,128,128,0.4); }

.fade-in { animation: fadeIn 0.3s ease-out; }
@keyframes fadeIn { from { opacity: 0; transform: translateY(5px); } to { opacity: 1; transform: translateY(0); } }

/* === APPLE HUB DESIGN (BACKGROUNDS AND GLOWS) === */
.apple-hub-layout {
  position: relative;
  overflow: hidden;
  z-index: 0;
}
.bg-apple-light { background-color: #f5f5f7; }
.bg-apple-dark { background-color: #0c0d10; }

.ambient-glow {
  position: absolute;
  top: 0; left: 0; right: 0; bottom: 0;
  pointer-events: none;
  z-index: -1;
  opacity: 0.4;
}
.glow-light {
  background: radial-gradient(circle at 10% 10%, rgba(var(--v-theme-primary), 0.1) 0%, transparent 40%),
              radial-gradient(circle at 90% 90%, rgba(var(--v-theme-info), 0.1) 0%, transparent 40%);
}
.glow-dark {
  background: radial-gradient(circle at 10% 10%, rgba(var(--v-theme-primary), 0.15) 0%, transparent 50%),
              radial-gradient(circle at 90% 90%, rgba(var(--v-theme-info), 0.1) 0%, transparent 50%);
  opacity: 0.7;
}

.apple-report-card {
  position: relative;
  overflow: hidden;
}
.color-glow {
  position: absolute;
  width: 120px;
  height: 120px;
  bottom: -40px;
  right: -40px;
  border-radius: 50%;
  filter: blur(40px);
  opacity: 0.1;
  pointer-events: none;
  z-index: 0;
  transition: opacity 0.4s ease, transform 0.4s ease;
}
.apple-report-card:hover .color-glow {
  opacity: 0.25;
  transform: scale(1.2);
}

/* EDITOR DE PDF NATIVO */
.pdf-edit-table { border-collapse: collapse; }
.pdf-edit-table th { text-transform: uppercase; font-size: 10px; font-weight: 700; color: #78909C; padding: 8px; border-bottom: 1px solid rgba(0,0,0,0.05); text-align: left; }
.pdf-edit-table td { padding: 4px; border-bottom: 1px solid rgba(0,0,0,0.03); }
.dark-mode.pdf-edit-table th { color: rgba(255,255,255,0.5); border-bottom: 1px solid rgba(255,255,255,0.05); }
.dark-mode.pdf-edit-table td { border-bottom: 1px solid rgba(255,255,255,0.03); }
.pdf-edit-table :deep(.v-field__input) { min-height: 28px !important; padding-top: 0 !important; padding-bottom: 0 !important; }
</style>
