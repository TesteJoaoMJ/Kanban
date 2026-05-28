<template>
  <div
    class="d-flex flex-column h-100 w-100 overflow-hidden"
    :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 text-grey-darken-4' : 'bg-transparent text-white'"
  >

    <div
      class="px-6 py-3 flex-shrink-0 d-flex align-center justify-space-between border-b transition-all"
      :class="themeStore.currentMode === 'light' ? 'bg-white border-grey-lighten-2' : 'bg-glass-header border-white-05'"
    >
      <div class="d-flex align-center">
        <div
            class="icon-box-sm rounded-lg mr-3 d-flex align-center justify-center elevation-2"
            :class="themeStore.currentMode === 'light' ? 'bg-orange-darken-1 text-white' : 'bg-white-10 text-orange-accent-2'"
            style="width: 36px; height: 36px;"
        >
            <v-icon size="20">mdi-store</v-icon>
        </div>
        <div>
            <div class="text-caption font-weight-bold text-uppercase opacity-70">Módulo Vendas</div>
            <div class="text-h6 font-weight-bold leading-none">Pedidos Cajuia</div>
        </div>
      </div>

      <div class="d-flex align-center gap-4">
         <div class="d-none d-md-flex flex-column align-end mr-4">
             <div class="text-h6 font-weight-bold font-mono leading-none">
                 {{ realTimeClock }}
             </div>
             <div class="d-flex align-center text-caption font-weight-medium opacity-70 gap-2">
                 <span :class="themeStore.currentMode === 'light' ? 'text-grey-darken-1' : 'text-white'">{{ currentDate }}</span>
                 <v-icon size="xx-small" color="grey">mdi-circle-small</v-icon>
                 <span class="d-flex align-center text-success"><v-icon size="10" class="mr-1">mdi-check-circle</v-icon> Online</span>
             </div>
         </div>

         <v-divider vertical class="h-24 mx-1" :class="themeStore.currentMode === 'light' ? 'border-grey-lighten-1' : 'border-white-10'"></v-divider>

         <div class="d-flex align-center gap-2">
            <v-btn
                icon
                density="comfortable"
                variant="text"
                :color="themeStore.currentMode === 'light' ? 'grey-darken-2' : 'white'"
                @click="fetchOrders"
                :loading="loading"
            >
                <v-icon>mdi-refresh</v-icon>
                <v-tooltip activator="parent" location="bottom">Atualizar</v-tooltip>
            </v-btn>

            <v-btn
                variant="flat"
                color="error"
                class="text-none font-weight-bold px-4 ml-2 shadow-soft"
                height="40"
                rounded="lg"
                @click="openCloseRegisterModal"
            >
                <v-icon start>mdi-cash-lock</v-icon> Fechar Caixa
            </v-btn>
         </div>
      </div>
    </div>

    <div class="d-flex flex-column flex-grow-1 overflow-y-auto custom-scrollbar pa-6">

      <v-row dense class="mb-6 flex-shrink-0">
        <v-col cols="12" md="4">
          <v-card class="kpi-card-sharp bg-gradient-green hover-elevate" v-ripple>
            <div class="kpi-bg-icon"><v-icon>mdi-cash-multiple</v-icon></div>
            <div class="d-flex flex-column position-relative z-10 h-100 justify-space-between">
              <div>
                <div class="d-flex align-center mb-1">
                   <v-icon color="white" size="small" class="mr-2 opacity-80">mdi-store</v-icon>
                   <span class="kpi-label text-white-80">FATURAMENTO</span>
                </div>
                <div class="kpi-number-group">
                  <span class="kpi-unit mr-1 text-white-70">R$</span>
                  <span class="kpi-value text-h4 font-mono text-white">{{ formatCurrencyNoSymbol(kpis.totalRevenue) }}</span>
                </div>
              </div>
              <div class="kpi-footer text-caption bg-black-20 w-100 px-3 py-1 mt-2 text-white">
                Total faturado no período
              </div>
            </div>
          </v-card>
        </v-col>

        <v-col cols="12" md="4">
          <v-card class="kpi-card-sharp bg-gradient-info hover-elevate" v-ripple>
            <div class="kpi-bg-icon"><v-icon>mdi-ticket-percent</v-icon></div>
            <div class="d-flex flex-column position-relative z-10 h-100 justify-space-between">
              <div>
                <div class="d-flex align-center mb-1">
                   <v-icon color="white" size="small" class="mr-2 opacity-80">mdi-chart-line</v-icon>
                   <span class="kpi-label text-white-80">TICKET MÉDIO</span>
                </div>
                <div class="kpi-number-group">
                  <span class="kpi-unit mr-1 text-white-70">R$</span>
                  <span class="kpi-value text-h4 font-mono text-white">{{ formatCurrencyNoSymbol(kpis.averageTicket) }}</span>
                </div>
              </div>
              <div class="kpi-footer text-caption bg-black-20 w-100 px-3 py-1 mt-2 text-white">
                Média por venda realizada
              </div>
            </div>
          </v-card>
        </v-col>

        <v-col cols="12" md="4">
          <v-card class="kpi-card-sharp bg-gradient-warning hover-elevate" v-ripple>
            <div class="kpi-bg-icon"><v-icon>mdi-cart-check</v-icon></div>
            <div class="d-flex flex-column position-relative z-10 h-100 justify-space-between">
              <div>
                <div class="d-flex align-center mb-1">
                   <v-icon color="white" size="small" class="mr-2 opacity-80">mdi-receipt</v-icon>
                   <span class="kpi-label text-white-80">TOTAL VENDAS</span>
                </div>
                <div class="kpi-number-group">
                  <span class="kpi-value text-h4 font-mono text-white">{{ kpis.totalOrders }}</span>
                  <span class="kpi-unit ml-2 text-white-70 font-weight-bold">PEDIDOS</span>
                </div>
              </div>
              <div class="kpi-footer text-caption bg-black-20 w-100 px-3 py-1 mt-2 text-white">
                Volume total de transações
              </div>
            </div>
          </v-card>
        </v-col>
      </v-row>

      <div
        class="flex-grow-1 d-flex flex-column overflow-hidden rounded-xl border transition-all"
        :class="themeStore.currentMode === 'light' ? 'bg-white border-grey-lighten-2 shadow-sm' : 'glass-panel border-white-05'"
      >

        <div
            class="px-4 py-3 border-b d-flex flex-wrap align-center gap-4 transition-all"
            :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-glass-header border-white-05'"
        >
          <div class="d-flex align-center gap-2 flex-grow-1" style="max-width: 400px;">
            <v-text-field
              v-model="search"
              density="compact"
              variant="outlined"
              placeholder="Buscar por cliente, ID ou vendedor..."
              prepend-inner-icon="mdi-magnify"
              hide-details
              :bg-color="themeStore.currentMode === 'light' ? 'white' : 'rgba(255,255,255,0.05)'"
              class="rounded-lg"
            ></v-text-field>
          </div>

          <div style="width: 180px;">
            <v-select
              v-model="dateFilter"
              :items="dateOptions"
              item-title="label"
              item-value="value"
              density="compact"
              variant="outlined"
              prepend-inner-icon="mdi-calendar-range"
              hide-details
              :bg-color="themeStore.currentMode === 'light' ? 'white' : 'rgba(255,255,255,0.05)'"
              class="rounded-lg"
            ></v-select>
          </div>

          <v-spacer></v-spacer>
          <span class="text-caption font-weight-bold opacity-70 ml-2">{{ filteredOrders.length }} registros</span>
        </div>

        <div
            class="orders-grid-header px-4 py-3 border-b text-caption font-weight-bold text-uppercase"
            :class="themeStore.currentMode === 'light' ? 'bg-white text-grey-darken-1 border-grey-lighten-2' : 'bg-transparent text-white-50 border-white-05'"
        >
          <div>ID</div>
          <div>Data / Hora</div>
          <div>Cliente</div>
          <div>Vendedor</div>
          <div class="text-center">Pagamento</div>
          <div class="text-right">Total</div>
          <div class="text-center">Ações</div>
        </div>

        <div class="flex-grow-1 overflow-y-auto custom-scrollbar px-0 py-0">
          <div v-if="loading" class="d-flex flex-column align-center justify-center h-100 opacity-60">
             <v-progress-circular indeterminate color="primary" size="40"></v-progress-circular>
             <span class="text-caption mt-3 font-weight-bold">Carregando pedidos...</span>
          </div>

          <div v-else-if="filteredOrders.length === 0" class="d-flex flex-column align-center justify-center py-12 h-100 opacity-50">
            <v-icon size="64" class="mb-4">mdi-cart-off</v-icon>
            <span class="text-h6 font-weight-bold">Nenhuma venda encontrada</span>
          </div>

          <v-list v-else class="pa-0 bg-transparent">
            <div
                v-for="(item, index) in filteredOrders"
                :key="item.id"
                class="orders-grid-row px-4 border-b transition-all"
                :class="[
                    themeStore.currentMode === 'light'
                        ? (index % 2 === 0 ? 'bg-white' : 'bg-grey-lighten-5') + ' border-grey-lighten-1 hover:bg-grey-lighten-4'
                        : 'border-white-05 hover-bg-glass text-white'
                ]"
            >
              <div class="font-weight-bold text-primary text-body-2 font-mono">#{{ item.order_number }}</div>

              <div class="d-flex flex-column">
                <span class="text-body-2 font-weight-bold">{{ formatDate(item.created_at) }}</span>
                <span class="text-caption opacity-60">{{ formatTime(item.created_at) }}</span>
              </div>

              <div class="d-flex align-center text-truncate">
                <v-avatar size="28" :color="themeStore.currentMode === 'light' ? 'grey-lighten-3' : 'white-10'" class="mr-3">
                  <span class="text-caption font-weight-bold" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-3' : 'text-white'">
                      {{ item.customer_name?.charAt(0).toUpperCase() || '?' }}
                  </span>
                </v-avatar>
                <div class="d-flex flex-column text-truncate">
                  <span class="text-body-2 font-weight-bold text-truncate" :title="item.customer_name">{{ item.customer_name || 'Consumidor' }}</span>
                </div>
              </div>

              <div class="text-caption opacity-80 text-truncate d-flex align-center">
                 <v-icon size="14" class="mr-1 opacity-70">mdi-account-tie</v-icon>
                 {{ item.vendedor_nome || '-' }}
              </div>

              <div class="text-center">
                <v-chip
                    size="x-small"
                    :color="getPaymentColor(item.payment_method)"
                    variant="flat"
                    class="font-weight-bold text-uppercase justify-center"
                    style="min-width: 90px;"
                >
                  {{ item.payment_method }}
                </v-chip>
              </div>

              <div class="text-right">
                <span class="font-weight-black text-body-1 font-mono">{{ formatCurrency(item.total_value) }}</span>
              </div>

              <div class="d-flex justify-center align-center gap-1">

                <v-tooltip :text="item.nfe_key ? 'Visualizar NFe' : 'Emitir NFe'" location="top">
                    <template v-slot:activator="{ props }">
                        <v-btn
                            icon
                            size="x-small"
                            variant="text"
                            v-bind="props"
                            :color="item.nfe_key ? 'blue' : (themeStore.currentMode === 'light' ? 'grey-darken-1' : 'grey-lighten-1')"
                            @click="handleNfeAction(item)"
                        >
                            <v-icon>{{ item.nfe_key ? 'mdi-file-check' : 'mdi-file-upload-outline' }}</v-icon>
                        </v-btn>
                    </template>
                </v-tooltip>

                <v-btn icon size="x-small" variant="text" :color="themeStore.currentMode === 'light' ? 'grey-darken-1' : 'white'" @click="openOrderDetails(item)">
                  <v-icon>mdi-eye-outline</v-icon>
                  <v-tooltip activator="parent" location="top">Ver Detalhes</v-tooltip>
                </v-btn>

                <v-menu location="bottom end">
                  <template v-slot:activator="{ props }">
                    <v-btn icon size="x-small" variant="text" :color="themeStore.currentMode === 'light' ? 'grey-darken-1' : 'white'" v-bind="props">
                      <v-icon>mdi-dots-vertical</v-icon>
                    </v-btn>
                  </template>
                  <v-list density="compact" class="rounded-lg elevation-4">
                    <v-list-item link @click="resendReceipt(item)">
                        <template v-slot:prepend><v-icon size="small" class="mr-2">mdi-email-outline</v-icon></template>
                        <v-list-item-title>Reenviar Recibo</v-list-item-title>
                    </v-list-item>
                    <v-divider class="my-1"></v-divider>
                    <v-list-item link class="text-error" @click="cancelOrder(item)">
                        <template v-slot:prepend><v-icon size="small" color="error" class="mr-2">mdi-cancel</v-icon></template>
                        <v-list-item-title>Estornar Venda</v-list-item-title>
                    </v-list-item>
                  </v-list>
                </v-menu>
              </div>
            </div>
          </v-list>
        </div>
      </div>
    </div>

    <v-dialog v-model="showCloseRegister" max-width="450px" transition="dialog-bottom-transition">
      <v-card class="rounded-xl">
        <v-toolbar density="compact" color="surface" class="border-b px-4">
           <v-toolbar-title class="text-subtitle-1 font-weight-bold">Fechamento de Caixa</v-toolbar-title>
           <v-spacer></v-spacer>
           <v-btn icon="mdi-close" variant="text" size="small" @click="showCloseRegister = false"></v-btn>
        </v-toolbar>

        <v-card-text class="pa-6">
          <div class="text-center mb-6 bg-grey-lighten-4 rounded-xl py-4 border-dashed">
            <div class="text-caption text-medium-emphasis text-uppercase font-weight-bold">Vendas de Hoje</div>
            <div class="text-h4 font-weight-black text-success mt-1">{{ formatCurrency(dailyTotals.total) }}</div>
            <div class="text-caption text-medium-emphasis mt-1">{{ dailyTotals.count }} pedidos</div>
          </div>

          <div class="d-flex flex-column gap-2">
            <div v-for="(amount, method) in dailyTotals.byMethod" :key="method" class="d-flex justify-space-between align-center pa-3 rounded-lg border">
              <div class="d-flex align-center">
                <v-icon :color="getPaymentColor(method)" size="small" class="mr-3">mdi-circle</v-icon>
                <span class="text-body-2 text-capitalize font-weight-medium">{{ method }}</span>
              </div>
              <span class="font-weight-bold">{{ formatCurrency(amount) }}</span>
            </div>
          </div>
        </v-card-text>
        <div class="pa-5 pt-0">
          <v-btn block color="error" size="large" variant="flat" class="rounded-lg font-weight-bold" @click="confirmCloseRegister">
             <v-icon start>mdi-check</v-icon> Confirmar e Imprimir
          </v-btn>
        </div>
      </v-card>
    </v-dialog>

    <v-dialog v-model="emission.show" width="1000px" height="90vh" persistent transition="dialog-bottom-transition" class="no-resize-dialog">
        <v-card class="rounded-xl overflow-hidden d-flex flex-column h-100">
            <v-toolbar color="surface" density="comfortable" class="border-b px-2 flex-shrink-0">
                <v-btn icon="mdi-close" variant="text" @click="emission.show = false" :disabled="emission.processing"></v-btn>
                <v-toolbar-title class="text-subtitle-1 font-weight-black ml-2">Emitir NFe (Pedido #{{ emission.order?.order_number }})</v-toolbar-title>
                <v-spacer></v-spacer>
                <div v-if="emission.activeCompany" class="text-caption font-weight-bold text-medium-emphasis mr-4">
                    Emitente: {{ emission.activeCompany.name?.substring(0,25) }}...
                </div>
            </v-toolbar>

            <div class="flex-grow-1 overflow-y-auto pa-6">

                <div v-if="emission.step === 1" class="h-100 d-flex flex-column justify-center">
                    <div class="text-center mb-8">
                        <v-icon size="80" color="primary" class="mb-4">mdi-file-document-edit-outline</v-icon>
                        <h3 class="text-h5 font-weight-bold">Modo de Emissão</h3>
                        <p class="text-body-1 text-medium-emphasis">Selecione o percentual do valor total para a nota fiscal.</p>
                    </div>

                    <v-row justify="center" class="gap-4">
                        <v-col cols="12" md="5">
                            <v-card
                                variant="outlined"
                                class="pa-6 text-center cursor-pointer transition-all hover-border-primary h-100 d-flex flex-column justify-center"
                                :class="emission.mode === '50' ? 'bg-blue-lighten-5 border-primary ring-2' : ''"
                                @click="emission.mode = '50'"
                                height="200"
                            >
                                <div class="text-h3 font-weight-black text-primary mb-2">50%</div>
                                <div class="text-h6 font-weight-bold text-uppercase">Valor Parcial</div>
                                <div class="text-body-2 text-medium-emphasis mt-2">Reduz o valor unitário dos itens pela metade.</div>
                            </v-card>
                        </v-col>
                        <v-col cols="12" md="5">
                            <v-card
                                variant="outlined"
                                class="pa-6 text-center cursor-pointer transition-all hover-border-primary h-100 d-flex flex-column justify-center"
                                :class="emission.mode === '100' ? 'bg-blue-lighten-5 border-primary ring-2' : ''"
                                @click="emission.mode = '100'"
                                height="200"
                            >
                                <div class="text-h3 font-weight-black text-success mb-2">100%</div>
                                <div class="text-h6 font-weight-bold text-uppercase">Valor Cheio</div>
                                <div class="text-body-2 text-medium-emphasis mt-2">Emite o valor integral original do pedido.</div>
                            </v-card>
                        </v-col>
                    </v-row>
                </div>

                <div v-else-if="emission.step === 2">
                    <v-alert v-if="emission.validationErrors.length > 0" type="warning" variant="tonal" class="mb-6" density="comfortable" border="start">
                        <div class="font-weight-bold mb-2">Dados incompletos para emissão:</div>
                        <ul class="pl-4 text-body-2">
                            <li v-for="err in emission.validationErrors" :key="err">{{ err }}</li>
                        </ul>
                    </v-alert>

                    <h3 class="text-subtitle-1 font-weight-bold mb-3 d-flex align-center">
                        <v-icon start size="small" color="primary">mdi-account</v-icon> Destinatário
                    </h3>
                    <v-card variant="outlined" class="pa-4 mb-6 bg-grey-lighten-5 border-dashed rounded-lg">
                        <v-row dense>
                            <v-col cols="12" md="6"><v-text-field v-model="emission.form.destinatario.nome" label="Nome / Razão Social" density="compact" variant="outlined" bg-color="surface"></v-text-field></v-col>
                            <v-col cols="12" md="6"><v-text-field v-model="emission.form.destinatario.cnpj_cpf" label="CPF / CNPJ" density="compact" variant="outlined" bg-color="surface"></v-text-field></v-col>
                            <v-col cols="12" md="3"><v-text-field v-model="emission.form.destinatario.endereco.cep" label="CEP" density="compact" variant="outlined" bg-color="surface"></v-text-field></v-col>
                            <v-col cols="12" md="7"><v-text-field v-model="emission.form.destinatario.endereco.logradouro" label="Endereço" density="compact" variant="outlined" bg-color="surface"></v-text-field></v-col>
                            <v-col cols="12" md="2"><v-text-field v-model="emission.form.destinatario.endereco.numero" label="Número" density="compact" variant="outlined" bg-color="surface"></v-text-field></v-col>
                            <v-col cols="12" md="5"><v-text-field v-model="emission.form.destinatario.endereco.bairro" label="Bairro" density="compact" variant="outlined" bg-color="surface"></v-text-field></v-col>
                            <v-col cols="12" md="5"><v-text-field v-model="emission.form.destinatario.endereco.municipio" label="Município" density="compact" variant="outlined" bg-color="surface"></v-text-field></v-col>
                            <v-col cols="12" md="2"><v-text-field v-model="emission.form.destinatario.endereco.uf" label="UF" density="compact" variant="outlined" bg-color="surface"></v-text-field></v-col>
                        </v-row>
                    </v-card>

                    <h3 class="text-subtitle-1 font-weight-bold mb-3 d-flex align-center">
                        <v-icon start size="small" color="primary">mdi-cart</v-icon> Itens da Nota ({{ emission.mode }}%)
                    </h3>
                    <div class="border rounded-lg overflow-hidden mb-6">
                        <v-table density="compact" hover>
                            <thead class="bg-grey-lighten-4">
                                <tr>
                                    <th class="text-uppercase text-caption font-weight-bold">Produto</th>
                                    <th width="120" class="text-uppercase text-caption font-weight-bold">NCM</th>
                                    <th width="120" class="text-uppercase text-caption font-weight-bold">CFOP</th>
                                    <th width="100" class="text-right text-uppercase text-caption font-weight-bold">Qtd</th>
                                    <th width="120" class="text-right text-uppercase text-caption font-weight-bold">Unit.</th>
                                    <th width="120" class="text-right text-uppercase text-caption font-weight-bold">Total</th>
                                </tr>
                            </thead>
                            <tbody>
                                <tr v-for="(item, i) in emission.form.itens" :key="i">
                                    <td class="text-body-2 font-weight-medium py-2">{{ item.descricao }}</td>
                                    <td>
                                        <v-text-field v-model="item.ncm" density="compact" variant="outlined" hide-details class="my-1" bg-color="surface" placeholder="0000.00.00"></v-text-field>
                                    </td>
                                    <td>
                                        <v-text-field v-model="item.cfop" density="compact" variant="outlined" hide-details class="my-1" bg-color="surface"></v-text-field>
                                    </td>
                                    <td class="text-right">{{ item.quantidade }}</td>
                                    <td class="text-right">{{ formatCurrencyNoSymbol(item.valor_unitario) }}</td>
                                    <td class="text-right font-weight-bold">{{ formatCurrencyNoSymbol(item.quantidade * item.valor_unitario) }}</td>
                                </tr>
                            </tbody>
                        </v-table>
                    </div>

                    <h3 class="text-subtitle-1 font-weight-bold mb-3 d-flex align-center">
                        <v-icon start size="small" color="primary">mdi-cash-multiple</v-icon> Pagamento
                    </h3>
                    <v-card variant="outlined" class="pa-4 mb-6 bg-grey-lighten-5 border-dashed rounded-lg">
                        <v-row dense>
                            <v-col cols="12" md="6">
                                <v-radio-group v-model="emission.form.pagamento.forma" inline hide-details>
                                    <v-radio label="À Vista" value="0" color="indigo"></v-radio>
                                    <v-radio label="À Prazo" value="1" color="indigo"></v-radio>
                                </v-radio-group>
                            </v-col>
                            <v-col cols="12" md="6">
                                <v-select
                                    v-model="emission.form.pagamento.meio"
                                    :items="auxData.paymentMethods"
                                    item-title="name"
                                    item-value="value"
                                    label="Meio de Pagamento"
                                    variant="outlined"
                                    density="compact"
                                    hide-details
                                    bg-color="surface"
                                ></v-select>
                            </v-col>
                        </v-row>
                    </v-card>
                </div>

                <div v-else-if="emission.step === 3" class="h-100 d-flex flex-column">
                    <div class="d-flex align-center justify-center mb-4">
                        <v-icon color="indigo" class="mr-2">mdi-eye-check</v-icon>
                        <h3 class="text-h6 font-weight-bold">Pré-visualização da DANFE</h3>
                    </div>

                    <div class="flex-grow-1 bg-grey-darken-3 rounded-lg overflow-hidden relative shadow-inner">
                        <div v-if="emission.previewLoading" class="absolute-center d-flex flex-column align-center">
                            <v-progress-circular indeterminate color="white" size="64"></v-progress-circular>
                            <span class="text-white mt-4 font-weight-bold">Gerando PDF...</span>
                        </div>
                        <iframe v-else :src="emission.previewUrl" class="w-100 h-100 border-none"></iframe>
                    </div>
                </div>

                <div v-else-if="emission.step === 4" class="h-100 d-flex flex-column">
                    <div class="text-center mb-6 pt-4">
                        <v-progress-circular v-if="emission.processing" indeterminate color="indigo" size="80" width="8" class="mb-4"></v-progress-circular>
                        <v-icon v-else-if="emission.success" color="success" size="80" class="mb-4">mdi-check-circle</v-icon>
                        <v-icon v-else color="error" size="80" class="mb-4">mdi-alert-circle</v-icon>

                        <h3 class="text-h5 font-weight-bold">
                            {{ emission.processing ? 'Processando Emissão...' : (emission.success ? 'Nota Autorizada com Sucesso!' : 'Falha na Emissão') }}
                        </h3>
                    </div>

                    <div class="flex-grow-1 border rounded-lg bg-black overflow-hidden d-flex flex-column">
                        <div class="bg-grey-darken-4 px-4 py-2 text-caption font-weight-bold text-uppercase border-b border-white-10">Log de Transmissão</div>
                        <div class="pa-4 font-mono text-caption overflow-y-auto custom-scrollbar flex-grow-1 text-green-accent-3" style="font-family: monospace;">
                            <div v-for="(log, i) in emission.logs" :key="i" class="mb-1 border-b border-white-05 pb-1">
                                <span class="opacity-60 mr-2">{{ log.time }}</span>
                                <span v-html="log.msg"></span>
                            </div>
                        </div>
                    </div>
                </div>

            </div>

            <div class="pa-4 border-t bg-surface d-flex align-center justify-end gap-3 flex-shrink-0" v-if="emission.step !== 4">
                <v-btn
                    v-if="emission.step > 1"
                    variant="outlined"
                    color="medium-emphasis"
                    height="48"
                    class="px-6 font-weight-bold"
                    @click="emission.step--"
                >
                    Voltar
                </v-btn>

                <v-spacer></v-spacer>

                <v-btn
                    v-if="emission.step === 1"
                    color="primary"
                    variant="flat"
                    height="48"
                    class="px-8 font-weight-bold"
                    @click="prepareEmission"
                >
                    Continuar <v-icon end>mdi-arrow-right</v-icon>
                </v-btn>

                <v-btn
                    v-if="emission.step === 2"
                    color="success"
                    variant="flat"
                    height="48"
                    class="px-8 font-weight-bold"
                    @click="goToPreview"
                >
                    Gerar Preview <v-icon end>mdi-file-eye</v-icon>
                </v-btn>

                <v-btn
                    v-if="emission.step === 3"
                    color="indigo"
                    variant="flat"
                    height="48"
                    class="px-10 font-weight-black text-body-1"
                    @click="processEmission"
                    :loading="emission.processing"
                >
                    TRANSMITIR NFE <v-icon end>mdi-send</v-icon>
                </v-btn>
            </div>

            <div class="pa-4 border-t bg-surface d-flex justify-end gap-3 flex-shrink-0" v-if="emission.step === 4 && !emission.processing">
                <v-btn v-if="emission.success" color="success" height="48" class="px-8 font-weight-bold" @click="finishEmission">Concluir Processo</v-btn>
                <v-btn v-else color="warning" variant="outlined" height="48" class="px-6 font-weight-bold" @click="emission.step = 2">Voltar e Corrigir</v-btn>
            </div>
        </v-card>
    </v-dialog>

    <CajuiaOrderDetailModal :show="showDetailModal" :order="selectedOrder" @close="showDetailModal = false" />

  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted, computed, reactive, watch } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '@/api/supabase'
import { sefazService } from '@/api/sefazApi'
import { useAppStore } from '@/stores/app'
import { useUserStore } from '@/stores/user'
import { useThemeStore } from '@/stores/theme'
import { format, isSameMonth, isToday, parseISO, startOfMonth, endOfMonth, subMonths } from 'date-fns'
import jsPDF from 'jspdf'
import autoTable from 'jspdf-autotable'
import { DANFe } from 'node-sped-pdf'
import CajuiaOrderDetailModal from '@/components/CajuiaOrderDetailModal.vue'

const router = useRouter()
const appStore = useAppStore()
const userStore = useUserStore()
const themeStore = useThemeStore()
const loading = ref(true)
const rawOrders = ref<any[]>([])
const search = ref('')
const dateFilter = ref('month')
const showCloseRegister = ref(false)
const selectedPaymentMethods = ref<string[]>([])

const showDetailModal = ref(false)
const selectedOrder = ref(null)

const realTimeClock = ref(format(new Date(), 'HH:mm:ss'))
let clockInterval: NodeJS.Timeout
const currentDate = ref(format(new Date(), 'dd/MM/yyyy'))

const dateOptions = [
  { label: 'Hoje', value: 'today' },
  { label: 'Este Mês', value: 'month' },
  { label: 'Todos', value: 'all' }
]

// --- ESTADO DE EMISSÃO NFE ---
const emission = reactive({
    show: false,
    step: 1,
    mode: '100', // '50' ou '100'
    order: null as any,
    items: [] as any[],
    form: {
        destinatario: { nome: '', cnpj_cpf: '', email: '', endereco: { logradouro: '', numero: '', bairro: '', municipio: '', uf: 'SP', cep: '' } },
        itens: [] as any[],
        pagamento: { forma: '0', meio: '99' },
        obs: ''
    },
    validationErrors: [] as string[],
    processing: false,
    previewLoading: false,
    previewUrl: '',
    success: false,
    logs: [] as { time: string, msg: string }[],
    activeCompany: null as any
})

const auxData = reactive({ products: [] as any[], paymentMethods: [] as any[] });

const filteredOrders = computed(() => {
  let items = rawOrders.value

  if (dateFilter.value === 'today') {
    items = items.filter(o => isToday(parseISO(o.created_at)))
  } else if (dateFilter.value === 'month') {
    items = items.filter(o => isSameMonth(parseISO(o.created_at), new Date()))
  }

  if (selectedPaymentMethods.value.length > 0) {
      items = items.filter(o => selectedPaymentMethods.value.includes(o.payment_method))
  }

  if (search.value) {
    const lowerSearch = search.value.toLowerCase()
    items = items.filter(o =>
      o.order_number?.toString().includes(lowerSearch) ||
      o.customer_name?.toLowerCase().includes(lowerSearch) ||
      o.vendedor_nome?.toLowerCase().includes(lowerSearch)
    )
  }
  return items
})

const kpis = computed(() => {
  const items = filteredOrders.value
  const totalRevenue = items.reduce((acc, curr) => acc + (Number(curr.total_value) || 0), 0)
  const totalOrders = items.length
  const averageTicket = totalOrders > 0 ? totalRevenue / totalOrders : 0
  return { totalRevenue, totalOrders, averageTicket }
})

const dailyTotals = computed(() => {
  const todaySales = rawOrders.value.filter(o => isToday(parseISO(o.created_at)))
  const byMethod: Record<string, number> = {}
  let total = 0
  todaySales.forEach(sale => {
    const method = sale.payment_method || 'Outros'
    const value = Number(sale.total_value) || 0
    if (!byMethod[method]) byMethod[method] = 0
    byMethod[method] += value
    total += value
  })
  return { total, count: todaySales.length, byMethod }
})

const emissionTotal = computed(() => {
    return emission.form.itens.reduce((acc, item) => acc + (item.quantidade * item.valor_unitario), 0)
})

const fetchAuxiliaryData = async () => {
    try {
        const [productsRes] = await Promise.all([
            supabase.from('cajuia_products').select('name, sku, price, ncm')
        ]);

        auxData.products = (productsRes.data || []).map((p:any) => ({
            label: p.name,
            price: p.price,
            ncm: p.ncm || ''
        }));

        // LISTA FIXA DE MEIOS DE PAGAMENTO SEFAZ
        // Garante que o código '01' seja encontrado pelo v-select
        auxData.paymentMethods = [
            { name: 'Dinheiro', value: '01' },
            { name: 'Cheque', value: '02' },
            { name: 'Cartão de Crédito', value: '03' },
            { name: 'Cartão de Débito', value: '04' },
            { name: 'Crédito Loja', value: '05' },
            { name: 'Vale Alimentação', value: '10' },
            { name: 'Vale Refeição', value: '11' },
            { name: 'Vale Presente', value: '12' },
            { name: 'Vale Combustível', value: '13' },
            { name: 'Boleto Bancário', value: '15' },
            { name: 'Depósito Bancário', value: '16' },
            { name: 'PIX', value: '17' },
            { name: 'Transferência Bancária', value: '18' },
            { name: 'Fidelidade', value: '19' },
            { name: 'Sem Pagamento', value: '90' },
            { name: 'Outros', value: '99' }
        ];

    } catch (e: any) { console.error('Erro aux data', e); }
};

// --- LÓGICA DE EMISSÃO ---

const handleNfeAction = async (item: any) => {
    if (item.nfe_key) {
        if (item.sales_order_pdf_url) {
             window.open(item.sales_order_pdf_url, '_blank');
        } else {
             appStore.showSnackbar('PDF da NFe não disponível.', 'warning');
        }
    } else {
        // INICIA FLUXO DE EMISSÃO
        startEmissionFlow(item);
    }
}

const startEmissionFlow = async (order: any) => {
    if(auxData.paymentMethods.length === 0) await fetchAuxiliaryData();

    // Carrega empresa emissora (Santos & Lopes)
    try {
        const nuvemResponse = await sefazService.listarEmpresas();
        const nuvemCompanies = nuvemResponse.data || (Array.isArray(nuvemResponse) ? nuvemResponse : []);
        const { data: dbCompanies } = await supabase.from('companies').select('*');
        const allCompanies = nuvemCompanies.map((nc: any) => {
            const dbConfig = (dbCompanies || []).find((dbc: any) => dbc.cnpj.replace(/\D/g, '') === nc.cnpj.replace(/\D/g, ''));
            return { ...nc, id: dbConfig?.id || nc.id, nfe_next_number: parseInt(dbConfig?.nfe_next_number) || 0, ie: dbConfig?.ie || nc.inscricao_estadual, crt: dbConfig?.crt || '3', nfe_series: dbConfig?.nfe_series || 1, nfe_environment: dbConfig?.nfe_environment || 'homologacao' };
        });
        emission.activeCompany = allCompanies.find((c: any) => c.cnpj.replace(/\D/g, '') === '53756096000189');
        if (!emission.activeCompany) {
            appStore.showSnackbar('Erro: Empresa emissora não configurada.', 'error');
            return;
        }
    } catch(e) { console.error(e); return; }

    emission.order = order;
    emission.step = 1;
    emission.mode = '100';
    emission.logs = [];
    emission.success = false;
    emission.processing = false;
    emission.validationErrors = [];

    // Busca Itens do Pedido
    const { data: items } = await supabase.from('cajuia_order_items').select('*').eq('order_id', order.id);
    emission.items = items || [];

    // Preenche Form Inicial
    let clientAddress = { logradouro: '', numero: '', bairro: '', municipio: '', uf: 'SP', cep: '' };
    let clientCpfCnpj = '';

    try {
        const { data: client } = await supabase.from('cajuia_clients').select('*').eq('name', order.customer_name).maybeSingle();
        if(client) {
            clientCpfCnpj = client.cpf_cnpj || '';
            clientAddress = {
                logradouro: client.address_street || '',
                numero: client.address_number || '',
                bairro: client.address_district || '',
                municipio: client.city || '',
                uf: client.state || 'SP',
                cep: client.zip_code || ''
            }
        }
    } catch {}

    // DETECÇÃO AUTOMÁTICA DE PAGAMENTO
    const { forma, meio } = detectPaymentData(order.payment_method);
    console.log("[DEBUG PAY] Payment Method from Order:", order.payment_method);
    console.log("[DEBUG PAY] Detected:", { forma, meio });

    emission.form = {
        destinatario: {
            nome: order.customer_name || 'Consumidor',
            cnpj_cpf: clientCpfCnpj,
            email: '',
            ie: '',
            endereco: clientAddress
        },
        itens: [],
        pagamento: { forma, meio },
        obs: `Pedido #${order.order_number}`
    };

    emission.show = true;
}

const detectPaymentData = (methodName: string) => {
    const name = (methodName || '').toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g, "");
    let forma = '0'; // 0=Vista, 1=Prazo
    let meio = '99'; // Outros

    if (name.includes('dinheiro')) { meio = '01'; forma = '0'; }
    else if (name.includes('pix')) { meio = '17'; forma = '0'; }
    else if (name.includes('credito')) { meio = '03'; forma = '1'; }
    else if (name.includes('debito')) { meio = '04'; forma = '0'; }
    else if (name.includes('boleto')) { meio = '15'; forma = '1'; }

    return { forma, meio };
}

const prepareEmission = () => {
    // Aplica a lógica 50% / 100%
    const multiplier = emission.mode === '50' ? 0.5 : 1;

    emission.form.itens = emission.items.map(item => ({
        descricao: item.product_name,
        ncm: '',
        cfop: '5102',
        quantidade: item.quantidade || item.quantity,
        valor_unitario: (item.unit_price * multiplier)
    }));

    emission.items.forEach(async (orderItem, idx) => {
        const { data: prod } = await supabase.from('cajuia_products').select('ncm').eq('name', orderItem.product_name).maybeSingle();
        if (prod && prod.ncm) emission.form.itens[idx].ncm = prod.ncm;
    });

    emission.step = 2;
}

const validateForm = () => {
    emission.validationErrors = [];
    if (!emission.form.destinatario.cnpj_cpf) emission.validationErrors.push('CPF/CNPJ do destinatário obrigatório.');
    if (!emission.form.destinatario.endereco.logradouro) emission.validationErrors.push('Logradouro obrigatório.');
    if (!emission.form.destinatario.endereco.cep) emission.validationErrors.push('CEP obrigatório.');
    emission.form.itens.forEach((item: any, i: number) => {
        if (!item.ncm) emission.validationErrors.push(`Item ${i+1} (${item.descricao}) sem NCM.`);
        if (!item.cfop) emission.validationErrors.push(`Item ${i+1} (${item.descricao}) sem CFOP.`);
    });
}

const goToPreview = async () => {
    validateForm();
    if (emission.validationErrors.length > 0) {
        appStore.showSnackbar('Por favor, corrija os erros antes de prosseguir.', 'warning');
        return;
    }
    await generateVisualPreview();
    emission.step = 3;
}

const generateVisualPreview = async () => {
    emission.previewLoading = true;
    try {
        const emit = emission.activeCompany;
        const dest = emission.form.destinatario;
        const valorTotal = emissionTotal.value.toFixed(2);
        const dhEmi = new Date().toISOString();

        let detHtml = '';
        emission.form.itens.forEach((item: any, index: number) => {
            detHtml += `<det nItem="${index + 1}">
                <prod>
                    <cProd>00${index + 1}</cProd>
                    <xProd>${item.descricao}</xProd>
                    <NCM>${item.ncm || '00000000'}</NCM>
                    <CFOP>${item.cfop || '5102'}</CFOP>
                    <uCom>UN</uCom>
                    <qCom>${item.quantidade}</qCom>
                    <vUnCom>${item.valor_unitario.toFixed(2)}</vUnCom>
                    <vProd>${(item.quantidade * item.valor_unitario).toFixed(2)}</vProd>
                    <uTrib>UN</uTrib>
                    <qTrib>${item.quantidade}</qTrib>
                    <vUnTrib>${item.valor_unitario.toFixed(2)}</vUnTrib>
                    <indTot>1</indTot>
                </prod>
                <imposto>
                    <ICMS>
                        <ICMS00>
                            <orig>0</orig>
                            <CST>00</CST>
                            <modBC>3</modBC>
                            <vBC>0.00</vBC>
                            <pICMS>0.00</pICMS>
                            <vICMS>0.00</vICMS>
                        </ICMS00>
                    </ICMS>
                    <PIS><PISNT><CST>07</CST></PISNT></PIS>
                    <COFINS><COFINSNT><CST>07</CST></COFINSNT></COFINS>
                </imposto>
            </det>`;
        });

        // XML CORRIGIDO PARA O NODE-SPED-PDF
        const xmlMock = `<nfeProc version="4.00" xmlns="http://www.portalfiscal.inf.br/nfe">
            <NFe xmlns="http://www.portalfiscal.inf.br/nfe">
                <infNFe Id="NFe${'0'.repeat(44)}" versao="4.00">
                    <ide>
                        <cUF>35</cUF>
                        <cNF>00000000</cNF>
                        <natOp>VENDA MERCADORIA</natOp>
                        <mod>55</mod>
                        <serie>1</serie>
                        <nNF>1</nNF>
                        <dhEmi>${dhEmi}</dhEmi>
                        <tpNF>1</tpNF>
                        <idDest>1</idDest>
                        <cMunFG>3550308</cMunFG>
                        <tpImp>1</tpImp>
                        <tpEmis>1</tpEmis>
                        <cDV>0</cDV>
                        <tpAmb>2</tpAmb>
                        <finNFe>1</finNFe>
                        <indFinal>1</indFinal>
                        <indPres>1</indPres>
                        <procEmi>0</procEmi>
                        <verProc>MJProcess Preview</verProc>
                    </ide>
                    <emit>
                        <CNPJ>${emit.cnpj.replace(/\D/g, '')}</CNPJ>
                        <xNome>${emit.name}</xNome>
                        <enderEmit>
                            <xLgr>${emit.street || 'Rua'}</xLgr>
                            <nro>${emit.number || 'S/N'}</nro>
                            <xBairro>${emit.district || 'Bairro'}</xBairro>
                            <cMun>3550308</cMun>
                            <xMun>${emit.city || 'Cidade'}</xMun>
                            <UF>${emit.uf || 'SP'}</UF>
                            <CEP>${emit.zip_code?.replace(/\D/g, '') || '00000000'}</CEP>
                            <cPais>1058</cPais>
                            <xPais>BRASIL</xPais>
                        </enderEmit>
                        <IE>${emit.ie?.replace(/\D/g, '') || ''}</IE>
                        <CRT>1</CRT>
                    </emit>
                    <dest>
                        <CNPJ>${dest.cnpj_cpf.replace(/\D/g, '')}</CNPJ>
                        <xNome>${dest.nome}</xNome>
                        <enderDest>
                            <xLgr>${dest.endereco.logradouro || 'Rua'}</xLgr>
                            <nro>${dest.endereco.numero || 'S/N'}</nro>
                            <xBairro>${dest.endereco.bairro || 'Bairro'}</xBairro>
                            <cMun>3550308</cMun>
                            <xMun>${dest.endereco.municipio || 'Cidade'}</xMun>
                            <UF>${dest.endereco.uf || 'SP'}</UF>
                            <CEP>${dest.endereco.cep.replace(/\D/g, '') || '00000000'}</CEP>
                            <cPais>1058</cPais>
                            <xPais>BRASIL</xPais>
                        </enderDest>
                        <indIEDest>9</indIEDest>
                    </dest>
                    ${detHtml}
                    <total>
                        <ICMSTot>
                            <vBC>0.00</vBC>
                            <vICMS>0.00</vICMS>
                            <vICMSDeson>0.00</vICMSDeson>
                            <vFCP>0.00</vFCP>
                            <vBCST>0.00</vBCST>
                            <vST>0.00</vST>
                            <vFCPST>0.00</vFCPST>
                            <vFCPSTRet>0.00</vFCPSTRet>
                            <vProd>${valorTotal}</vProd>
                            <vFrete>0.00</vFrete>
                            <vSeg>0.00</vSeg>
                            <vDesc>0.00</vDesc>
                            <vII>0.00</vII>
                            <vIPI>0.00</vIPI>
                            <vIPIDevol>0.00</vIPIDevol>
                            <vPIS>0.00</vPIS>
                            <vCOFINS>0.00</vCOFINS>
                            <vOutro>0.00</vOutro>
                            <vNF>${valorTotal}</vNF>
                        </ICMSTot>
                    </total>
                    <transp>
                        <modFrete>9</modFrete>
                    </transp>
                    <pag>
                        <detPag>
                            <tPag>${emission.form.pagamento.meio || '90'}</tPag>
                            <vPag>${valorTotal}</vPag>
                        </detPag>
                    </pag>
                    <infAdic>
                        <infCpl>${emission.form.obs || ''} - PRÉVIA DE DOCUMENTO.</infCpl>
                    </infAdic>
                </infNFe>
            </NFe>
        </nfeProc>`;

        const pdf = await DANFe({ xml: xmlMock });
        emission.previewUrl = URL.createObjectURL(new Blob([pdf], { type: 'application/pdf' }));
    } catch (e) {
        console.error("Erro preview:", e);
        emission.previewUrl = '';
    } finally {
        emission.previewLoading = false;
    }
}

const addLog = (msg: string) => {
    emission.logs.push({ time: format(new Date(), 'HH:mm:ss'), msg });
}

// BUSCA SEQUENCIAL INTELIGENTE (RESOLVE PROBLEMA DO NEXT NUMBER)
const getNextNumber = async () => {
    if (!emission.activeCompany) return 1;

    // 1. Configuração na tabela 'companies' (Base)
    let configNum = Number(emission.activeCompany.nfe_next_number);
    if (isNaN(configNum)) configNum = 0;

    // 2. Última nota 'AUTORIZADA' na tabela 'nfe_outbound'
    const cnpjClean = emission.activeCompany.cnpj.replace(/\D/g, '');
    const { data } = await supabase
        .from('nfe_outbound')
        .select('numero')
        .or(`emitente_cnpj.eq.${emission.activeCompany.cnpj},emitente_cnpj.eq.${cnpjClean}`)
        .eq('status', 'AUTORIZADA')
        .order('numero', { ascending: false })
        .limit(1)
        .maybeSingle();

    const lastUsed = data?.numero ? Number(data.numero) : 0;
    const finalNumber = Math.max(configNum, lastUsed + 1);

    return finalNumber;
};

const processEmission = async () => {
    emission.step = 4;
    emission.processing = true;
    emission.logs = [];
    addLog('Iniciando processo de emissão...');

    try {
        const nextNum = await getNextNumber();
        addLog(`Número da NFe definido: <b>${nextNum}</b>`);

        // 2. Sanitização de Dados
        const cleanCNPJ = (val: string) => val.replace(/\D/g, '');
        const emitenteCNPJ = cleanCNPJ(emission.activeCompany.cnpj);
        const destCNPJ_CPF = cleanCNPJ(emission.form.destinatario.cnpj_cpf);

        const payload = {
            natureza_operacao: 'VENDA DE MERCADORIA',
            destinatario: {
                ...emission.form.destinatario,
                cnpj_cpf: destCNPJ_CPF
            },
            itens: emission.form.itens,
            pagamentos: [{
                meio_pagamento: emission.form.pagamento.meio,
                valor: emissionTotal.value,
                forma_pagamento: emission.form.pagamento.forma
            }],
            ambiente: emission.activeCompany.nfe_environment,
            serie: emission.activeCompany.nfe_series,
            crt: emission.activeCompany.crt,
            numero: nextNum,
            informacoes_adicionais: emission.form.obs
        };

        addLog('Enviando dados para a SEFAZ...');

        // ENVIO API
        const result = await sefazService.emitirNFe(payload, emitenteCNPJ, emission.activeCompany.ie);

        if (result.status === 'autorizado' || result.status === 'success') {
            addLog('<span class="text-success font-weight-bold">✅ NFe AUTORIZADA com sucesso!</span>');
            addLog(`Chave: ${result.chave}`);
            emission.success = true;

            // Atualiza numeração da empresa
            await supabase.from('companies').update({ nfe_next_number: nextNum + 1 }).eq('id', emission.activeCompany.id);

            // Salva na tabela nfe_outbound (SEM O CAMPO created_by)
            const dbPayload = {
                emitente_cnpj: emission.activeCompany.cnpj, // Mantém formato original para visualização
                destinatario_nome: emission.form.destinatario.nome,
                valor_total: emissionTotal.value,
                status: 'AUTORIZADA',
                chave: result.chave,
                numero: result.numero,
                xml_link: result.xml_url,
                pdf_link: result.pdf_url,
                // created_by removido pois a coluna não existe no DB
                retorno_sefaz: { ...result, payload: payload }
            };

            const { error: insertError } = await supabase.from('nfe_outbound').insert(dbPayload);
            if(insertError) throw insertError;

            // Atualiza Pedido (Tenta salvar NFe Key, ignora erro se coluna não existir)
            try {
                await supabase.from('cajuia_orders').update({
                    nfe_key: result.chave,
                }).eq('id', emission.order.id);
            } catch(updateErr) {
                console.warn('Não foi possível atualizar chave NFe no pedido (Coluna inexistente ou erro):', updateErr);
            }

            addLog('Dados salvos no sistema.');
            fetchOrders();
        } else {
            addLog('<span class="text-error font-weight-bold">❌ Erro na autorização.</span>');
            addLog(`Motivo: ${result.motivo || JSON.stringify(result)}`);
            emission.success = false;
        }

    } catch (e: any) {
        addLog(`<span class="text-error">❌ Erro Crítico: ${e.message}</span>`);
        console.error(e);
        emission.success = false;
    } finally {
        emission.processing = false;
    }
}

const finishEmission = () => {
    emission.show = false;
    appStore.showSnackbar('Processo finalizado.', 'success');
}

const fetchOrders = async () => {
  loading.value = true
  try {
    let query = supabase
      .from('cajuia_orders')
      .select(`*, profiles(full_name)`)
      .order('created_at', { ascending: false })

    if (!userStore.isGlobalAdmin && !userStore.isCajuiaAdmin && userStore.user?.id) {
        query = query.eq('vendedor_id', userStore.user.id)
    }

    const { data, error } = await query
    if (error) throw error

    rawOrders.value = (data || []).map((order: any) => ({
      ...order,
      vendedor_nome: order.profiles?.full_name || 'N/A'
    }))

  } catch (err: any) {
    console.error(err)
    appStore.showSnackbar('Erro ao carregar pedidos.', 'error')
  } finally {
    loading.value = false
  }
}

const openOrderDetails = (order: any) => {
    selectedOrder.value = order
    showDetailModal.value = true
}

const resendReceipt = (order: any) => {
    appStore.showSnackbar(`Recibo #${order.order_number} reenviado!`, 'success')
}

const cancelOrder = (order: any) => {
    if (confirm(`Estornar venda #${order.order_number}?`)) {
        appStore.showSnackbar(`Venda estornada.`, 'warning')
    }
}

const openCloseRegisterModal = () => { showCloseRegister.value = true }

const confirmCloseRegister = () => {
  const doc = new jsPDF()
  const today = new Date()
  doc.text('Fechamento de Caixa - Cajuia', 14, 20)
  doc.text(`Data: ${format(today, "dd/MM/yyyy HH:mm")}`, 14, 30)
  doc.text(`Total: ${formatCurrency(dailyTotals.value.total)}`, 14, 40)
  doc.save(`Fechamento_${format(today, 'yyyyMMdd')}.pdf`)
  appStore.showSnackbar('Caixa encerrado!', 'success')
  showCloseRegister.value = false
}

const getPaymentColor = (method: string) => {
  const m = method?.toLowerCase() || ''
  if (m.includes('pix')) return 'teal'
  if (m.includes('dinheiro')) return 'green'
  if (m.includes('crédito')) return 'blue'
  return 'grey'
}

const formatCurrency = (val: number) => new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(Number(val)||0)
const formatCurrencyNoSymbol = (val: number) => new Intl.NumberFormat('pt-BR', { minimumFractionDigits: 2 }).format(val || 0)
const formatDate = (d: string) => d ? format(new Date(d), 'dd/MM/yyyy') : ''
const formatTime = (d: string) => d ? format(new Date(d), 'HH:mm') : ''

onMounted(() => {
    fetchOrders()
    clockInterval = setInterval(() => {
        realTimeClock.value = format(new Date(), 'HH:mm:ss')
        currentDate.value = format(new Date(), 'dd/MM/yyyy')
    }, 1000)
})
onUnmounted(() => clearInterval(clockInterval))
</script>

<style scoped lang="scss">
/* --- ESTILOS DE LAYOUT --- */
.glass-panel { background: rgba(30, 30, 35, 0.45); backdrop-filter: blur(25px); border: 1px solid rgba(255, 255, 255, 0.08); }
.bg-glass-header { background: rgba(255, 255, 255, 0.03); }
.border-white-05 { border-color: rgba(255, 255, 255, 0.05) !important; }
.bg-white-10 { background: rgba(255, 255, 255, 0.1); }

.no-resize-dialog {
    max-height: 90vh !important;
}

/* --- KPI CARDS (PREMIUM) --- */
.kpi-card-sharp {
    height: 120px;
    border-radius: 12px;
    padding: 16px;
    position: relative;
    overflow: hidden;
    border: 1px solid rgba(255,255,255,0.15);
    cursor: pointer;
    transition: all 0.3s ease;
    color: white;
}
.kpi-card-sharp:hover { transform: translateY(-4px); box-shadow: 0 10px 25px rgba(0,0,0,0.2); }

.kpi-bg-icon { position: absolute; right: -25px; bottom: -25px; opacity: 0.2; transform: rotate(-15deg); pointer-events: none; }
.kpi-bg-icon .v-icon { font-size: 110px; color: white; }

.bg-gradient-green { background: linear-gradient(135deg, #2e7d32, #1b5e20); }
.bg-gradient-info { background: linear-gradient(135deg, #0288d1, #005b9f); }
.bg-gradient-warning { background: linear-gradient(135deg, #f57c00, #e65100); }
.bg-black-20 { background: rgba(0,0,0,0.2); }

/* --- GRID / LIST --- */
.orders-grid-header, .orders-grid-row {
  display: grid;
  grid-template-columns: 80px 140px minmax(200px, 1fr) minmax(120px, 1fr) 120px 120px 100px;
  gap: 16px;
  padding-left: 16px;
  padding-right: 16px;
}
.orders-grid-row { min-height: 56px; cursor: default; }
.hover-bg-glass:hover { background-color: rgba(255,255,255,0.08) !important; }

/* Scrollbar Sutil */
.custom-scrollbar::-webkit-scrollbar { width: 6px; }
.custom-scrollbar::-webkit-scrollbar-track { background: transparent; }
.custom-scrollbar::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.4); border-radius: 4px; }

.ring-2 { box-shadow: 0 0 0 3px rgba(33, 150, 243, 0.4); }
.hover-border-primary:hover { border-color: rgb(var(--v-theme-primary)) !important; background-color: rgba(var(--v-theme-primary), 0.05); }
.absolute-center { position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%); }
</style>
