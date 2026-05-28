<template>
  <v-dialog v-model="dialog" fullscreen transition="dialog-bottom-transition" class="fixed-dialog">
    <v-card
      class="d-flex flex-column rounded-0 font-sans h-100 overflow-hidden receivables-layout"
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

      <div
        class="px-4 py-3 px-md-6 py-md-4 d-flex justify-space-between align-center flex-shrink-0 z-20"
        :class="themeStore.currentMode === 'light' ? 'bg-white border-b border-grey-lighten-2 shadow-sm' : 'bg-glass-header border-bottom-white-05'"
      >
        <div class="d-flex align-center gap-4">
          <v-btn icon variant="text" :color="themeStore.currentMode === 'light' ? 'grey-darken-4' : 'white'" @click="dialog = false" class="btn-3d"><v-icon>mdi-arrow-left</v-icon></v-btn>
          <div>
            <div class="text-caption font-weight-bold text-uppercase tracking-wide" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-1' : 'opacity-70'">Emissor Fiscal Sefaz</div>
            <div class="text-h6 font-weight-black lh-1" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">{{ isEditingDraft ? 'Editando Rascunho NF-e' : 'Nova NF-e (Modelo 55)' }}</div>
          </div>
        </div>
        <div class="d-flex align-center gap-3">
          <v-btn variant="outlined" :color="themeStore.currentMode === 'light' ? 'grey-darken-2' : 'white'" class="btn-3d font-weight-bold text-none" @click="saveDraft" :loading="savingDraft">
            <v-icon start>mdi-content-save-edit</v-icon> Salvar Rascunho
          </v-btn>
          <v-btn variant="outlined" color="warning" class="btn-3d font-weight-bold text-none" @click="downloadDebugXml">
            <v-icon start>mdi-xml</v-icon> Debug XML
          </v-btn>
          <v-btn variant="flat" color="blue-grey-darken-3" class="btn-3d font-weight-bold text-none text-white" @click="generatePreview" :loading="previewLoading">
            <v-icon start>mdi-file-eye-outline</v-icon> Prévia DANFE
          </v-btn>

          <v-btn color="success" variant="flat" class="btn-3d px-6 font-weight-black text-none" @click="submitNfe('nuvem')" :loading="issuingProvider === 'nuvem'" :disabled="issuingProvider === 'sefaz'">
            <v-icon start>mdi-cloud-upload</v-icon> Transmitir Nuvem
          </v-btn>

          <v-btn v-if="isFullStack" color="deep-orange-darken-2" variant="flat" class="btn-3d px-6 font-weight-black text-none" @click="submitNfe('sefaz')" :loading="issuingProvider === 'sefaz'" :disabled="issuingProvider === 'nuvem'">
            <v-icon start>mdi-server-network</v-icon> Transmitir Sefaz
          </v-btn>
        </div>
      </div>

      <div class="flex-grow-1 overflow-hidden d-flex position-relative w-100 z-10">
        <div v-if="loadingOrderData" class="position-absolute w-100 h-100 d-flex flex-column align-center justify-center z-30 backdrop-blur-sm" :class="themeStore.currentMode === 'light' ? 'bg-white-90' : 'bg-black-80'">
            <v-progress-circular indeterminate :color="themeStore.currentMode === 'light' ? 'primary' : 'success'" size="64" width="4"></v-progress-circular>
            <div class="mt-4 text-h6 font-weight-black" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">Importando dados...</div>
        </div>

        <div class="flex-grow-1 overflow-y-auto custom-scroll pa-4 pa-md-6 w-100">
          <div class="d-flex flex-column w-100" style="gap: 20px;">

            <v-card class="rounded-lg border-thin overflow-hidden shadow-sm w-100" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'glass-card border-white-05'" elevation="0">
              <div class="px-6 py-3 border-b d-flex justify-space-between align-center" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-white-05 border-bottom-white-05'">
                <div class="font-weight-black text-subtitle-2 text-uppercase d-flex align-center gap-2" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-3' : 'text-white'">
                    <v-icon size="18" :color="themeStore.currentMode === 'light' ? 'grey-darken-2' : 'white'">mdi-domain</v-icon> 0. Empresa Emissora
                </div>
                <div style="width: 350px;">
                    <v-select
                        v-model="activeCompany"
                        :items="companies"
                        item-title="name"
                        return-object
                        variant="outlined"
                        density="compact"
                        hide-details
                        :color="themeStore.currentMode === 'light' ? 'primary' : 'success'"
                        class="ui-field font-weight-bold"
                        @update:model-value="populateEmitente"
                    ></v-select>
                </div>
              </div>
              <div class="pa-6 w-100">
                <v-row dense class="row-gap w-100 ma-0">
                  <v-col cols="12" md="3"><label class="input-label">CNPJ Emitente *</label><v-text-field v-model="form.emitente.cnpj" variant="outlined" density="compact" class="ui-field" readonly></v-text-field></v-col>
                  <v-col cols="12" md="5"><label class="input-label">Razão Social *</label><v-text-field v-model="form.emitente.nome" variant="outlined" density="compact" class="ui-field"></v-text-field></v-col>
                  <v-col cols="12" md="4"><label class="input-label">Nome Fantasia</label><v-text-field v-model="form.emitente.fantasia" variant="outlined" density="compact" class="ui-field"></v-text-field></v-col>
                  <v-col cols="12" md="3"><label class="input-label">Inscrição Estadual (IE)</label><v-text-field v-model="form.emitente.ie" variant="outlined" density="compact" class="ui-field"></v-text-field></v-col>
                  <v-col cols="12" md="3"><label class="input-label">Inscrição Municipal (IM)</label><v-text-field v-model="form.emitente.im" variant="outlined" density="compact" class="ui-field"></v-text-field></v-col>
                  <v-col cols="12" md="3"><label class="input-label">Regime (CRT) *</label><v-select v-model="form.emitente.crt" :items="[{value: '1', title: '1 - Simples Nacional'}, {value: '2', title: '2 - Simples Excesso'}, {value: '3', title: '3 - Regime Normal'}]" variant="outlined" density="compact" class="ui-field font-weight-bold"></v-select></v-col>
                  <v-col cols="12" md="3"><label class="input-label">CNAE</label><v-text-field v-model="form.emitente.cnae" variant="outlined" density="compact" class="ui-field"></v-text-field></v-col>

                  <v-col cols="12"><v-divider class="my-2 border-dashed"></v-divider></v-col>

                  <v-col cols="12" md="2"><label class="input-label">CEP *</label><v-text-field v-model="form.emitente.endereco.cep" variant="outlined" density="compact" class="ui-field"></v-text-field></v-col>
                  <v-col cols="12" md="6"><label class="input-label">Logradouro *</label><v-text-field v-model="form.emitente.endereco.logradouro" variant="outlined" density="compact" class="ui-field"></v-text-field></v-col>
                  <v-col cols="12" md="2"><label class="input-label">Número *</label><v-text-field v-model="form.emitente.endereco.numero" variant="outlined" density="compact" class="ui-field"></v-text-field></v-col>
                  <v-col cols="12" md="2"><label class="input-label">UF *</label><v-select v-model="form.emitente.endereco.uf" :items="estados" variant="outlined" density="compact" class="ui-field"></v-select></v-col>

                  <v-col cols="12" md="4"><label class="input-label">Bairro *</label><v-text-field v-model="form.emitente.endereco.bairro" variant="outlined" density="compact" class="ui-field"></v-text-field></v-col>
                  <v-col cols="12" md="4"><label class="input-label">Município *</label><v-text-field v-model="form.emitente.endereco.municipio" variant="outlined" density="compact" class="ui-field"></v-text-field></v-col>
                  <v-col cols="12" md="2"><label class="input-label">Cód IBGE *</label><v-text-field v-model="form.emitente.endereco.codigo_municipio" variant="outlined" density="compact" class="ui-field" placeholder="Ex: 3554508"></v-text-field></v-col>
                  <v-col cols="12" md="4"><label class="input-label">Complemento</label><v-text-field v-model="form.emitente.endereco.complemento" variant="outlined" density="compact" class="ui-field"></v-text-field></v-col>
                </v-row>
              </div>
            </v-card>

            <v-card class="rounded-lg border-thin overflow-hidden shadow-sm w-100" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'glass-card border-white-05'" elevation="0">
              <div class="px-6 py-3 border-b d-flex justify-space-between align-center" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-white-05 border-bottom-white-05'">
                <div class="font-weight-black text-subtitle-2 text-uppercase d-flex align-center gap-2" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-3' : 'text-white'">
                  <v-icon size="18" :color="themeStore.currentMode === 'light' ? 'grey-darken-2' : 'white'">mdi-cog-sync-outline</v-icon> 1. Dados da Operação
                </div>
              </div>
              <div class="pa-6 w-100">
                <v-row dense class="row-gap w-100 ma-0">
                  <v-col cols="12" md="6">
                    <label class="input-label">Natureza da Operação *</label>
                    <v-text-field v-model="form.natureza_operacao" variant="outlined" density="compact" class="ui-field font-weight-bold" placeholder="Ex: Venda de Mercadorias"></v-text-field>
                  </v-col>
                  <v-col cols="12" md="3">
                    <label class="input-label">Tipo (Entrada/Saída) *</label>
                    <v-select v-model="form.tpNF" :items="[{value: 0, title: '0 - Entrada'}, {value: 1, title: '1 - Saída'}]" item-title="title" item-value="value" variant="outlined" density="compact" class="ui-field font-weight-bold" :color="themeStore.currentMode === 'light' ? 'primary' : 'success'"></v-select>
                  </v-col>
                  <v-col cols="12" md="3">
                    <label class="input-label">Finalidade *</label>
                    <v-select v-model="form.finNFe" :items="[{value: 1, title: '1 - Normal'}, {value: 2, title: '2 - Complementar'}, {value: 3, title: '3 - Ajuste'}, {value: 4, title: '4 - Devolução/Retorno'}]" item-title="title" item-value="value" variant="outlined" density="compact" class="ui-field font-weight-bold" :color="themeStore.currentMode === 'light' ? 'primary' : 'success'"></v-select>
                  </v-col>

                  <v-col cols="12" v-if="form.finNFe === 4 || form.finNFe === 3">
                    <v-divider class="my-2 border-dashed"></v-divider>
                    <v-alert type="info" variant="tonal" density="compact" class="text-caption font-weight-bold mb-2">
                        Notas de Ajuste ou Devolução não aceitam detalhamento financeiro (Fatura). O sistema definirá o pagamento automaticamente como "Sem Pagamento (90)".
                    </v-alert>
                    <label class="input-label" :class="themeStore.currentMode === 'light' ? 'text-error' : 'text-red-lighten-2'">Chave de Acesso da Nota Referenciada *</label>
                    <v-combobox v-model="form.chavesReferenciadas" chips clearable multiple placeholder="Digite a chave de 44 dígitos e aperte Enter" variant="outlined" density="compact" class="ui-field"></v-combobox>
                  </v-col>

                  <v-col cols="12"><v-divider class="my-2 border-dashed"></v-divider></v-col>

                  <v-col cols="12" md="4">
                    <label class="input-label">Presença do Comprador</label>
                    <v-select v-model="form.indPres" :items="[{value: 0, title: '0 - Não se aplica'}, {value: 1, title: '1 - Presencial'}, {value: 2, title: '2 - Internet'}, {value: 3, title: '3 - Teleatendimento'}, {value: 9, title: '9 - Outros'}]" item-title="title" item-value="value" variant="outlined" density="compact" class="ui-field" :color="themeStore.currentMode === 'light' ? 'primary' : 'success'"></v-select>
                  </v-col>
                  <v-col cols="12" md="4">
                    <label class="input-label">Intermediador (Marketplace)</label>
                    <v-select v-model="form.indIntermed" :items="[{value: 0, title: '0 - Loja Própria / Sem Intermediador'}, {value: 1, title: '1 - Marketplace (Terceiros)'}]" item-title="title" item-value="value" variant="outlined" density="compact" class="ui-field" :color="themeStore.currentMode === 'light' ? 'primary' : 'success'"></v-select>
                  </v-col>
                  <v-col cols="12" md="4" v-if="form.indIntermed === 1">
                    <label class="input-label" :class="themeStore.currentMode === 'light' ? 'text-primary' : 'text-success'">CNPJ do Marketplace</label>
                    <v-text-field v-model="form.cnpjIntermediador" variant="outlined" density="compact" class="ui-field" placeholder="Apenas números"></v-text-field>
                  </v-col>
                </v-row>
              </div>
            </v-card>

            <v-card class="rounded-lg border-thin overflow-hidden shadow-sm w-100" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'glass-card border-white-05'" elevation="0">
              <div class="px-6 py-3 border-b d-flex justify-space-between align-center" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-white-05 border-bottom-white-05'">
                <div class="font-weight-black text-subtitle-2 text-uppercase d-flex align-center gap-2" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-3' : 'text-white'">
                  <v-icon size="18" :color="themeStore.currentMode === 'light' ? 'grey-darken-2' : 'white'">mdi-account-details-outline</v-icon> 2. Cliente / Destinatário
                </div>
                <div class="d-flex align-center gap-2">
                  <v-btn size="small" :color="themeStore.currentMode === 'light' ? 'primary' : 'success'" variant="tonal" class="font-weight-bold btn-3d" prepend-icon="mdi-account-plus" @click="openQuickCustomerAdd">Novo Rápido</v-btn>
                </div>
              </div>
              <div class="pa-6 w-100">
                <div class="mb-4">
                    <label class="input-label mb-1" :class="themeStore.currentMode === 'light' ? 'text-primary' : 'text-success'">Preenchimento Automático (Buscar Cliente na Base)</label>
                    <v-autocomplete
                        v-model="selectedClient"
                        :items="auxData.clients"
                        item-title="searchLabel"
                        item-value="id"
                        placeholder="Digite o nome, CNPJ ou CPF do cliente..."
                        variant="outlined" density="compact" prepend-inner-icon="mdi-magnify" return-object @update:model-value="handleClientSelection" hide-details class="ui-field font-weight-bold"
                        :color="themeStore.currentMode === 'light' ? 'primary' : 'success'"
                    >
                    </v-autocomplete>
                </div>

                <v-row dense class="row-gap w-100 ma-0">
                  <v-col cols="12" md="4">
                    <label class="input-label d-flex justify-space-between w-100">
                        <span>CPF / CNPJ *</span>
                        <v-btn icon size="x-small" variant="flat" :color="themeStore.currentMode === 'light' ? 'grey-darken-3' : 'white-20'" style="height: 18px; width: 18px;" :loading="loadingCnpj" @click="buscarDadosCnpj" title="Consultar CNPJ" class="btn-3d"><v-icon size="10">mdi-magnify</v-icon></v-btn>
                    </label>
                    <v-text-field v-model="form.destinatario.cnpj_cpf" variant="outlined" density="compact" class="ui-field font-weight-bold" @keyup.enter="buscarDadosCnpj" :color="themeStore.currentMode === 'light' ? 'primary' : 'success'"></v-text-field>
                  </v-col>
                  <v-col cols="12" md="8"><label class="input-label">Razão Social / Nome Completo *</label><v-text-field v-model="form.destinatario.nome" variant="outlined" density="compact" class="ui-field font-weight-bold" :color="themeStore.currentMode === 'light' ? 'primary' : 'success'"></v-text-field></v-col>

                  <v-col cols="12" md="5">
                    <label class="input-label">Indicador de Inscrição Estadual (IE) *</label>
                    <v-select v-model="form.destinatario.indIEDest" :items="[{value: '1', title: '1 - Contribuinte (Tem IE)'}, {value: '2', title: '2 - Contribuinte Isento'}, {value: '9', title: '9 - Não Contribuinte'}]" item-title="title" item-value="value" variant="outlined" density="compact" class="ui-field font-weight-bold" :color="themeStore.currentMode === 'light' ? 'primary' : 'success'"></v-select>
                  </v-col>
                  <v-col cols="12" md="4">
                    <label class="input-label d-flex justify-space-between w-100">
                        <span>Inscrição Estadual</span>
                        <v-btn icon size="x-small" variant="flat" :color="themeStore.currentMode === 'light' ? 'grey-darken-3' : 'white-20'" style="height: 18px; width: 18px;" :loading="loadingCCC" @click="consultarSefazIE" title="Buscar Sefaz" class="btn-3d"><v-icon size="10">mdi-magnify</v-icon></v-btn>
                    </label>
                    <v-text-field v-model="form.destinatario.ie" variant="outlined" density="compact" class="ui-field" placeholder="Números ou ISENTO" :color="themeStore.currentMode === 'light' ? 'primary' : 'success'"></v-text-field>
                  </v-col>
                  <v-col cols="12" md="3"><label class="input-label">Insc. Municipal</label><v-text-field v-model="form.destinatario.im" variant="outlined" density="compact" class="ui-field" :color="themeStore.currentMode === 'light' ? 'primary' : 'success'"></v-text-field></v-col>

                  <v-col cols="12"><v-divider class="my-2 border-dashed"></v-divider></v-col>

                  <v-col cols="12" md="3"><label class="input-label">CEP *</label><v-text-field v-model="form.destinatario.endereco.cep" variant="outlined" density="compact" class="ui-field" :color="themeStore.currentMode === 'light' ? 'primary' : 'success'"></v-text-field></v-col>
                  <v-col cols="12" md="7"><label class="input-label">Logradouro *</label><v-text-field v-model="form.destinatario.endereco.logradouro" variant="outlined" density="compact" class="ui-field" :color="themeStore.currentMode === 'light' ? 'primary' : 'success'"></v-text-field></v-col>
                  <v-col cols="12" md="2"><label class="input-label">Nº *</label><v-text-field v-model="form.destinatario.endereco.numero" variant="outlined" density="compact" class="ui-field" :color="themeStore.currentMode === 'light' ? 'primary' : 'success'"></v-text-field></v-col>

                  <v-col cols="12" md="5"><label class="input-label">Bairro *</label><v-text-field v-model="form.destinatario.endereco.bairro" variant="outlined" density="compact" class="ui-field" :color="themeStore.currentMode === 'light' ? 'primary' : 'success'"></v-text-field></v-col>
                  <v-col cols="12" md="4"><label class="input-label">Município *</label><v-text-field v-model="form.destinatario.endereco.municipio" variant="outlined" density="compact" class="ui-field" :color="themeStore.currentMode === 'light' ? 'primary' : 'success'"></v-text-field></v-col>
                  <v-col cols="12" md="2"><label class="input-label">Cód IBGE</label><v-text-field v-model="form.destinatario.endereco.codigo_municipio" variant="outlined" density="compact" class="ui-field" placeholder="Auto" :color="themeStore.currentMode === 'light' ? 'primary' : 'success'"></v-text-field></v-col>
                  <v-col cols="12" md="1"><label class="input-label">UF *</label><v-select v-model="form.destinatario.endereco.uf" :items="estados" variant="outlined" density="compact" class="ui-field font-weight-bold" :color="themeStore.currentMode === 'light' ? 'primary' : 'success'" @update:model-value="applyTaxRulesFromUF"></v-select></v-col>
                </v-row>
              </div>
            </v-card>

            <v-card class="rounded-lg border-thin overflow-hidden shadow-sm w-100" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'glass-card border-white-05'" elevation="0">
              <div class="px-6 py-3 border-b d-flex justify-space-between align-center" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-white-05 border-bottom-white-05'">
                <div class="font-weight-black text-subtitle-2 text-uppercase d-flex align-center gap-2" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-3' : 'text-white'">
                  <v-icon size="18" :color="themeStore.currentMode === 'light' ? 'grey-darken-2' : 'white'">mdi-package-variant-closed</v-icon> 3. Produtos e Serviços *
                </div>
                <div class="d-flex align-center gap-2">
                  <v-btn size="small" :color="themeStore.currentMode === 'light' ? 'grey-darken-4' : 'success'" variant="flat" class="btn-3d font-weight-bold" prepend-icon="mdi-plus" @click="addItem">Novo Item</v-btn>
                </div>
              </div>

              <div class="px-4 py-2 border-b d-flex align-center gap-2 overflow-x-auto custom-scroll w-100" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-white-05 border-bottom-white-05'">
                  <span class="text-caption font-weight-bold text-uppercase mr-2 flex-shrink-0" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-2' : 'text-white-70'">Faturamento Parcial:</span>
                  <v-btn v-for="pct in [10, 20, 30, 40, 50, 60, 70, 80, 90, 100]" :key="pct" size="small" variant="outlined" :color="themeStore.currentMode === 'light' ? 'grey-darken-2' : 'white'" class="btn-3d rounded-2px font-weight-bold flex-shrink-0" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-glass-dark'" @click="applyPercentage(pct)">
                      {{ pct }}%
                  </v-btn>
              </div>

              <div class="w-100 overflow-x-auto custom-scroll" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-transparent'">
                <div style="min-width: 1200px; width: 100%;">
                    <div class="grid-header" :class="[themeStore.currentMode === 'light' ? 'grid-surface-light border-b border-grey-lighten-2' : 'grid-surface-dark border-bottom-white-05']" style="grid-template-columns: 40px minmax(200px, 2fr) 90px 70px 70px 60px 80px 100px 90px 110px 100px;">
                        <div class="cell center header-text">#</div>
                        <div class="cell header-text">Descrição do Produto</div>
                        <div class="cell header-text">NCM</div>
                        <div class="cell center header-text">CFOP</div>
                        <div class="cell center header-text">CST/CSOSN</div>
                        <div class="cell center header-text">UN</div>
                        <div class="cell center header-text">QTD</div>
                        <div class="cell center header-text">V. Unit</div>
                        <div class="cell center header-text">Desc R$</div>
                        <div class="cell center header-text">Total</div>
                        <div class="cell center header-text">Tributação</div>
                    </div>

                    <div
                        class="grid-row border-b"
                        :class="[themeStore.currentMode === 'light' ? 'grid-row-light border-grey-lighten-2' : 'grid-row-dark border-bottom-white-05', zebraClass(idx)]"
                        style="grid-template-columns: 40px minmax(200px, 2fr) 90px 70px 70px 60px 80px 100px 90px 110px 100px;"
                        v-for="(item, idx) in form.itens" :key="idx"
                    >
                        <div class="cell center text-caption font-weight-bold" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-1' : 'text-white-70'">{{ idx + 1 }}</div>
                        <div class="cell pa-1">
                            <v-combobox v-model="item.descricao" :items="auxData.products" item-title="label" item-value="label" variant="plain" density="compact" hide-details return-object @update:model-value="() => onItemSelect(item)" class="clean-input-combo font-weight-bold text-caption w-100 h-100" placeholder="Nome do produto..." :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'"></v-combobox>
                        </div>
                        <div class="cell pa-1"><input type="text" v-model="item.ncm" class="clean-input border rounded-2px px-2 py-1 text-caption w-100" :class="inputClass" placeholder="NCM"></div>
                        <div class="cell pa-1 center"><input type="text" v-model="item.cfop" class="clean-input border rounded-2px px-2 py-1 text-caption w-100 text-center" :class="inputClass" placeholder="5102"></div>
                        <div class="cell pa-1 center"><input type="text" v-model="item.impostos.cst_csosn" class="clean-input border rounded-2px px-2 py-1 text-caption w-100 text-center font-weight-bold" :class="inputClassDisabled" maxlength="4" readonly title="Ajuste na tela de Tributação"></div>
                        <div class="cell pa-1 center"><input type="text" v-model="item.unidade" class="clean-input border rounded-2px px-2 py-1 text-caption w-100 text-center font-weight-bold text-uppercase" :class="inputClass" maxlength="4" placeholder="UN"></div>
                        <div class="cell pa-1 center"><input type="number" v-model="item.quantidade" class="clean-input border rounded-2px px-2 py-1 text-center w-100 font-weight-bold" :class="inputClass"></div>
                        <div class="cell pa-1 center"><input type="number" v-model="item.valor_unitario" class="clean-input border rounded-2px px-2 py-1 text-right w-100 font-weight-medium" :class="inputClass" step="0.01"></div>
                        <div class="cell pa-1 center"><input type="number" v-model="item.desconto" class="clean-input border rounded-2px px-2 py-1 text-right w-100 font-weight-bold" :class="themeStore.currentMode === 'light' ? 'bg-white text-error border-grey-lighten-2' : 'bg-black-20 text-red-lighten-2 border-white-10'" step="0.01" placeholder="0.00"></div>
                        <div class="cell center font-weight-black text-body-2" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">
                            {{ formatRawCurrency((item.quantidade * item.valor_unitario) - (Number(item.desconto) || 0)) }}
                        </div>
                        <div class="cell center gap-1">
                            <v-btn icon size="x-small" :color="themeStore.currentMode === 'light' ? 'primary' : 'primary'" variant="flat" class="btn-3d" @click="openTaxModal(idx)" title="Tributação Avançada"><v-icon size="14">mdi-scale-balance</v-icon></v-btn>
                            <v-btn icon size="x-small" color="error" variant="flat" class="btn-3d" @click="removeItem(idx)" title="Remover"><v-icon size="14">mdi-delete</v-icon></v-btn>
                        </div>
                    </div>
                </div>
              </div>
            </v-card>

            <v-card class="rounded-lg border-thin overflow-hidden shadow-sm w-100" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'glass-card border-white-05'" elevation="0">
              <div class="px-6 py-3 border-b d-flex justify-space-between align-center" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-white-05 border-bottom-white-05'">
                <div class="font-weight-black text-subtitle-2 text-uppercase d-flex align-center gap-2" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-3' : 'text-white'">
                  <v-icon size="18" :color="themeStore.currentMode === 'light' ? 'grey-darken-2' : 'white'">mdi-truck-outline</v-icon> 4. Transporte e Frete
                </div>
              </div>
              <div class="pa-6 w-100">
                <v-row dense class="row-gap w-100 ma-0">
                  <v-col cols="12">
                    <label class="input-label">Modalidade do Frete *</label>
                    <v-radio-group v-model="form.transporte.modFrete" inline hide-details class="mt-0 font-weight-bold text-body-2">
                      <v-radio label="0 - CIF (Emitente)" :value="0" :color="themeStore.currentMode === 'light' ? 'grey-darken-4' : 'success'"></v-radio>
                      <v-radio label="1 - FOB (Destinatário)" :value="1" :color="themeStore.currentMode === 'light' ? 'grey-darken-4' : 'success'"></v-radio>
                      <v-radio label="9 - Sem Frete" :value="9" :color="themeStore.currentMode === 'light' ? 'grey-darken-4' : 'success'"></v-radio>
                    </v-radio-group>
                  </v-col>

                  <template v-if="form.transporte.modFrete !== 9">
                    <v-col cols="12"><v-divider class="my-3 border-dashed"></v-divider></v-col>
                    <v-col cols="12" md="3"><label class="input-label">CNPJ Transportadora</label><v-text-field v-model="form.transporte.cnpj" variant="outlined" density="compact" class="ui-field"></v-text-field></v-col>
                    <v-col cols="12" md="6"><label class="input-label">Razão Social Transportadora</label><v-text-field v-model="form.transporte.xNome" variant="outlined" density="compact" class="ui-field"></v-text-field></v-col>
                    <v-col cols="12" md="3"><label class="input-label">Inscrição Estadual</label><v-text-field v-model="form.transporte.IE" variant="outlined" density="compact" class="ui-field"></v-text-field></v-col>

                    <v-col cols="12" md="5"><label class="input-label">Endereço Transportadora</label><v-text-field v-model="form.transporte.xEnder" variant="outlined" density="compact" class="ui-field"></v-text-field></v-col>
                    <v-col cols="12" md="4"><label class="input-label">Município</label><v-text-field v-model="form.transporte.xMun" variant="outlined" density="compact" class="ui-field"></v-text-field></v-col>
                    <v-col cols="12" md="3"><label class="input-label">UF Transporte</label><v-select v-model="form.transporte.UF" :items="estados" variant="outlined" density="compact" class="ui-field"></v-select></v-col>

                    <v-col cols="12"><div class="text-caption font-weight-bold text-uppercase mt-4 mb-2" :class="themeStore.currentMode === 'light' ? 'text-grey' : 'text-white-70'">Volumes e Carga</div></v-col>

                    <v-col cols="12" md="2"><label class="input-label">Placa Veículo</label><v-text-field v-model="form.transporte.placa" variant="outlined" density="compact" class="ui-field"></v-text-field></v-col>
                    <v-col cols="12" md="2"><label class="input-label">UF Placa</label><v-select v-model="form.transporte.placaUF" :items="estados" variant="outlined" density="compact" class="ui-field"></v-select></v-col>
                    <v-col cols="12" md="2"><label class="input-label">Qtd Volumes</label><v-text-field v-model="form.transporte.qVol" type="number" variant="outlined" density="compact" class="ui-field"></v-text-field></v-col>
                    <v-col cols="12" md="2"><label class="input-label">Espécie (Ex: CX)</label><v-text-field v-model="form.transporte.esp" variant="outlined" density="compact" class="ui-field"></v-text-field></v-col>
                    <v-col cols="12" md="2"><label class="input-label">Peso Líq. (KG)</label><v-text-field v-model="form.transporte.pesoL" type="number" variant="outlined" density="compact" class="ui-field"></v-text-field></v-col>
                    <v-col cols="12" md="2"><label class="input-label">Peso Bruto (KG)</label><v-text-field v-model="form.transporte.pesoB" type="number" variant="outlined" density="compact" class="ui-field"></v-text-field></v-col>
                  </template>
                </v-row>
              </div>
            </v-card>

            <v-card v-if="form.finNFe !== 3 && form.finNFe !== 4" class="rounded-lg border-thin overflow-hidden shadow-sm w-100" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'glass-card border-white-05'" elevation="0">
              <div class="px-6 py-3 border-b d-flex justify-space-between align-center" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-white-05 border-bottom-white-05'">
                <div class="font-weight-black text-subtitle-2 text-uppercase d-flex align-center gap-2" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-3' : 'text-white'">
                  <v-icon size="18" :color="themeStore.currentMode === 'light' ? 'grey-darken-2' : 'white'">mdi-credit-card-outline</v-icon> 5. Fatura e Pagamento
                </div>
                <v-switch v-model="informarPagamento" :color="themeStore.currentMode === 'light' ? 'grey-darken-4' : 'success'" label="Informar Pagamento" hide-details density="compact" class="m-0 font-weight-bold"></v-switch>
              </div>
              <div class="pa-6 w-100" v-if="informarPagamento">
                <div v-for="(pag, i) in form.pagamentos" :key="i" class="d-flex align-end gap-3 mb-3 pb-3 border-b border-dashed w-100 flex-wrap">
                  <div style="flex: 2; min-width: 200px;"><label class="input-label">Forma de Pagamento *</label><v-select v-model="pag.tPag" :items="auxData.paymentMethods" item-title="name" item-value="value" density="compact" variant="outlined" class="ui-field"></v-select></div>
                  <div style="flex: 0.5; min-width: 90px;"><label class="input-label">Nº Parcela *</label><v-text-field v-model="pag.nDup" density="compact" variant="outlined" class="ui-field font-weight-bold" placeholder="001"></v-text-field></div>
                  <div style="flex: 1; min-width: 150px;"><label class="input-label">Vencimento</label><v-text-field type="date" v-model="pag.dVenc" density="compact" variant="outlined" class="ui-field"></v-text-field></div>
                  <div style="flex: 1; min-width: 150px;"><label class="input-label" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">Valor Parcela (R$) *</label><v-text-field type="number" v-model.number="pag.vPag" density="compact" variant="outlined" class="ui-field font-weight-bold"></v-text-field></div>

                  <template v-if="['03', '04', '17'].includes(pag.tPag)">
                      <div style="flex: 1; min-width: 150px;"><label class="input-label">Cód Autenticação (cAut)</label><v-text-field v-model="pag.cAut" density="compact" variant="outlined" class="ui-field"></v-text-field></div>
                      <div style="flex: 1; min-width: 150px;"><label class="input-label">CNPJ Maquininha</label><v-text-field v-model="pag.cnpjCredenciadora" density="compact" variant="outlined" class="ui-field"></v-text-field></div>
                  </template>

                  <v-btn icon size="small" color="error" variant="tonal" class="btn-3d" @click="form.pagamentos.splice(i, 1)" v-if="form.pagamentos.length > 1" style="margin-bottom: 2px;"><v-icon size="16">mdi-close</v-icon></v-btn>
                </div>
                <v-btn size="small" variant="text" :color="themeStore.currentMode === 'light' ? 'grey-darken-4' : 'success'" class="font-weight-bold" prepend-icon="mdi-plus" @click="addPaymentRow">Adicionar Parcela</v-btn>
              </div>
            </v-card>

            <v-card class="rounded-lg border-thin overflow-hidden shadow-sm w-100 mb-8" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'glass-card border-white-05'" elevation="0">
              <div class="px-6 py-3 border-b d-flex justify-space-between align-center" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-white-05 border-bottom-white-05'">
                <div class="font-weight-black text-subtitle-2 text-uppercase d-flex align-center gap-2" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-3' : 'text-white'">
                  <v-icon size="18" :color="themeStore.currentMode === 'light' ? 'grey-darken-2' : 'white'">mdi-text-box-outline</v-icon> 6. Informações Complementares
                </div>
              </div>
              <div class="pa-6 w-100">
                <v-row dense class="row-gap w-100 ma-0">
                  <v-col cols="12" md="6">
                      <label class="input-label">Informações p/ DANFE (Contribuinte)</label>
                      <v-textarea v-model="form.obs" variant="outlined" density="compact" rows="3" class="ui-field" placeholder="Ex: Imposto recolhido antecipadamente..."></v-textarea>
                  </v-col>
                  <v-col cols="12" md="6">
                      <label class="input-label">Informações Adicionais (Uso Exclusivo Fisco)</label>
                      <v-textarea v-model="form.obsFisco" variant="outlined" density="compact" rows="3" class="ui-field"></v-textarea>
                  </v-col>
                </v-row>
              </div>
            </v-card>

          </div>
        </div>

        <div class="d-flex flex-column flex-shrink-0 relative border-l shadow-xl z-20" :class="themeStore.currentMode === 'light' ? 'bg-grey-darken-4 text-white border-grey-darken-3' : 'bg-black-90 text-white border-white-10'" style="width: 360px;">
          <div class="pa-6 border-b" :class="themeStore.currentMode === 'light' ? 'border-white-10' : 'border-white-10'">
            <div class="text-h6 font-weight-black text-uppercase d-flex align-center gap-2 mb-1">
              <v-icon color="white">mdi-calculator</v-icon> Resumo Fiscal
            </div>
            <div class="text-caption opacity-70">Soma exata conforme regras Sefaz</div>
          </div>

          <div class="flex-grow-1 overflow-y-auto pa-6">
            <div class="d-flex flex-column gap-6">
              <div>
                <div class="d-flex justify-space-between mb-1">
                  <span class="text-caption font-weight-bold text-uppercase opacity-80">Total Produtos</span>
                  <span class="text-body-1 font-weight-black">{{ formatRawCurrency(totalFormValue) }}</span>
                </div>
                <v-progress-linear :model-value="100" color="grey" height="2" class="opacity-30" rounded="0"></v-progress-linear>
              </div>

              <div v-if="totalDesconto > 0" class="mt-2">
                <div class="d-flex justify-space-between mb-1">
                  <span class="text-caption font-weight-bold text-uppercase text-red-lighten-2">Total Descontos</span>
                  <span class="text-body-1 font-weight-black text-red-lighten-2">-{{ formatRawCurrency(totalDesconto) }}</span>
                </div>
                <v-progress-linear :model-value="100" color="red-lighten-2" height="2" rounded="0"></v-progress-linear>
              </div>

              <v-divider class="border-white-20 my-2"></v-divider>

              <div>
                <div class="d-flex justify-space-between mb-1">
                  <span class="text-caption font-weight-bold text-grey-lighten-2">ICMS</span>
                  <span class="text-body-2 font-weight-bold text-grey-lighten-2">{{ formatRawCurrency(taxTotals.vICMS) }}</span>
                </div>
                <v-progress-linear :model-value="(taxTotals.vICMS / (totalFormValue || 1)) * 100" color="grey-lighten-2" height="2" rounded="0"></v-progress-linear>
                <div class="text-[10px] opacity-60 mt-1 d-flex justify-space-between">
                    <span>BC: {{ formatRawCurrency(taxTotals.vBC) }}</span>
                    <span>ST: {{ formatRawCurrency(taxTotals.vST) }}</span>
                </div>
              </div>

              <div>
                <div class="d-flex justify-space-between mb-1">
                  <span class="text-caption font-weight-bold text-grey-lighten-2">IPI</span>
                  <span class="text-body-2 font-weight-bold text-grey-lighten-2">{{ formatRawCurrency(taxTotals.vIPI) }}</span>
                </div>
                <v-progress-linear :model-value="(taxTotals.vIPI / (totalFormValue || 1)) * 100" color="grey-lighten-2" height="2" rounded="0"></v-progress-linear>
              </div>

              <div>
                <div class="d-flex justify-space-between mb-1">
                  <span class="text-caption font-weight-bold text-grey-lighten-2">PIS / COFINS</span>
                  <span class="text-body-2 font-weight-bold text-grey-lighten-2">{{ formatRawCurrency(taxTotals.vPIS + taxTotals.vCOFINS) }}</span>
                </div>
                <v-progress-linear :model-value="((taxTotals.vPIS + taxTotals.vCOFINS) / (totalFormValue || 1)) * 100" color="grey-lighten-2" height="2" rounded="0"></v-progress-linear>
              </div>
            </div>
          </div>

          <div class="pa-6 border-t border-white-10 mt-auto bg-black-20">
            <div class="text-caption font-weight-bold text-uppercase opacity-70 mb-1">Valor Total da Nota</div>
            <div class="text-h4 font-weight-black text-white lh-1 text-shadow-sm">{{ formatRawCurrency((totalFormValue - totalDesconto) + taxTotals.vST + taxTotals.vIPI + taxTotals.vFCPST) }}</div>
          </div>
        </div>
      </div>
    </v-card>

    <v-dialog v-model="showTaxModal" max-width="1100" persistent transition="dialog-fade-transition">
        <v-card class="rounded-xl shadow-2xl d-flex flex-column overflow-hidden" :class="themeStore.currentMode === 'light' ? 'bg-white border text-grey-darken-4' : 'bg-grey-darken-4 border-white-10 text-white'" style="height: 750px; min-height: 750px; max-height: 750px;">
            <v-toolbar density="compact" :color="themeStore.currentMode === 'light' ? 'grey-lighten-4' : 'black'" class="border-b" :class="themeStore.currentMode === 'light' ? 'border-grey-lighten-2' : 'border-white-10'">
                <v-icon start class="ml-2" :color="themeStore.currentMode === 'light' ? 'primary' : 'white'">mdi-scale-balance</v-icon>
                <v-toolbar-title class="font-weight-black text-subtitle-1 text-uppercase tracking-wide" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">
                    Painel de Tributação Avançada (Sefaz)
                </v-toolbar-title>
                <v-spacer></v-spacer>
                <v-btn icon="mdi-close" variant="text" density="comfortable" @click="showTaxModal = false"></v-btn>
            </v-toolbar>

            <div class="d-flex flex-grow-1 overflow-hidden">
                <div class="border-r d-flex flex-column flex-shrink-0" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-black-20 border-white-10'" style="width: 240px; overflow-y: auto;">
                    <v-list density="compact" bg-color="transparent" nav mandatory v-model:selected="taxTabList" class="pa-3">
                        <v-list-item value="icms" :color="themeStore.currentMode === 'light' ? 'primary' : 'white'" class="rounded-lg mb-1 font-weight-bold text-body-2" active-class="bg-primary text-white">
                            <template v-slot:prepend><v-icon size="small" class="mr-2">mdi-percent</v-icon></template>
                            ICMS / SN / ST
                        </v-list-item>
                        <v-list-item value="ipi" :color="themeStore.currentMode === 'light' ? 'primary' : 'white'" class="rounded-lg mb-1 font-weight-bold text-body-2" active-class="bg-primary text-white">
                            <template v-slot:prepend><v-icon size="small" class="mr-2">mdi-factory</v-icon></template>
                            IPI
                        </v-list-item>
                        <v-list-item value="pis" :color="themeStore.currentMode === 'light' ? 'primary' : 'white'" class="rounded-lg mb-1 font-weight-bold text-body-2" active-class="bg-primary text-white">
                            <template v-slot:prepend><v-icon size="small" class="mr-2">mdi-hand-coin-outline</v-icon></template>
                            PIS / COFINS
                        </v-list-item>
                        <v-list-item value="difal" :color="themeStore.currentMode === 'light' ? 'primary' : 'white'" class="rounded-lg mb-1 font-weight-bold text-body-2" active-class="bg-primary text-white">
                            <template v-slot:prepend><v-icon size="small" class="mr-2">mdi-map-marker-path</v-icon></template>
                            DIFAL / Partilha
                        </v-list-item>
                        <v-list-item value="retencoes" :color="themeStore.currentMode === 'light' ? 'primary' : 'white'" class="rounded-lg mb-1 font-weight-bold text-body-2" active-class="bg-primary text-white">
                            <template v-slot:prepend><v-icon size="small" class="mr-2">mdi-bank-transfer</v-icon></template>
                            Retenções Federais
                        </v-list-item>
                        <v-list-item value="reforma" :color="themeStore.currentMode === 'light' ? 'primary' : 'white'" class="rounded-lg mb-1 font-weight-bold text-body-2" active-class="bg-primary text-white">
                            <template v-slot:prepend><v-icon size="small" class="mr-2">mdi-calendar-clock</v-icon></template>
                            Reforma 2026 (IBS)
                        </v-list-item>
                    </v-list>
                </div>

                <div class="flex-grow-1 custom-scroll pa-6 bg-transparent" style="overflow-y: auto;" v-if="currentItemTax">

                    <div v-show="taxTab === 'icms'">
                        <div class="text-subtitle-1 font-weight-black mb-4 d-flex align-center gap-2 border-b pb-2 text-primary"><v-icon>mdi-percent</v-icon> ICMS e Substituição Tributária (ST)</div>
                        <v-row dense class="row-gap w-100 ma-0">
                            <v-col cols="12"><label class="input-label">Origem da Mercadoria</label><v-select v-model="currentItemTax.origem" :items="taxOptions.origem" item-title="title" item-value="value" density="compact" variant="outlined" class="ui-field font-weight-bold"></v-select></v-col>
                            <v-col cols="12"><label class="input-label">CST / CSOSN do Item (Crucial)</label><v-select v-model="currentItemTax.cst_csosn" :items="taxOptions.cst_csosn" item-title="title" item-value="value" density="compact" variant="outlined" class="ui-field font-weight-black text-primary"></v-select></v-col>

                            <v-col cols="12"><v-divider class="my-3 border-dashed"></v-divider></v-col>

                            <v-col cols="12" md="4"><label class="input-label">Mod. Base Cálculo</label><v-select v-model="currentItemTax.modBC" :items="[{title: '0 - Margem Valor', value: 0}, {title: '1 - Pauta', value: 1}, {title: '2 - Preço Tabelado', value: 2}, {title: '3 - Valor Operação', value: 3}]" item-title="title" item-value="value" density="compact" variant="outlined" class="ui-field"></v-select></v-col>
                            <v-col cols="12" md="4"><label class="input-label">Base Cálculo ICMS (R$)</label><v-text-field v-model="currentItemTax.vBC" density="compact" variant="outlined" type="number" class="ui-field" placeholder="Auto"></v-text-field></v-col>
                            <v-col cols="12" md="4"><label class="input-label">Alíquota ICMS (%)</label><v-text-field v-model="currentItemTax.p_icms" density="compact" variant="outlined" type="number" class="ui-field font-weight-bold"></v-text-field></v-col>

                            <v-col cols="12" md="3"><label class="input-label">Redução Base (%)</label><v-text-field v-model="currentItemTax.p_red_bc" density="compact" variant="outlined" type="number" class="ui-field"></v-text-field></v-col>
                            <v-col cols="12" md="3"><label class="input-label">Valor ICMS (R$)</label><v-text-field v-model="currentItemTax.vICMS" density="compact" variant="outlined" type="number" class="ui-field" placeholder="Auto"></v-text-field></v-col>
                            <v-col cols="12" md="3"><label class="input-label">% FCP (Pobreza)</label><v-text-field v-model="currentItemTax.pFCP" density="compact" variant="outlined" type="number" class="ui-field"></v-text-field></v-col>
                            <v-col cols="12" md="3"><label class="input-label">ICMS Deson. (R$)</label><v-text-field v-model="currentItemTax.vICMSDeson" density="compact" variant="outlined" type="number" class="ui-field"></v-text-field></v-col>

                            <v-col cols="12"><div class="text-subtitle-2 font-weight-black text-uppercase mt-4 border-b pb-1 text-primary">Substituição Tributária (ST) e Retenções</div></v-col>

                            <v-col cols="12" md="4"><label class="input-label">Mod. BC ST</label><v-select v-model="currentItemTax.modBCST" :items="[{title: '0 - Preço Tabelado', value: 0}, {title: '1 - Lista Negativa', value: 1}, {title: '2 - Lista Positiva', value: 2}, {title: '3 - Lista Neutra', value: 3}, {title: '4 - Margem Agregado (%)', value: 4}, {title: '5 - Pauta', value: 5}, {title: '6 - Valor Operação', value: 6}]" item-title="title" item-value="value" density="compact" variant="outlined" class="ui-field"></v-select></v-col>
                            <v-col cols="12" md="4"><label class="input-label">MVA ST (%)</label><v-text-field v-model="currentItemTax.pMVAST" density="compact" variant="outlined" type="number" class="ui-field"></v-text-field></v-col>
                            <v-col cols="12" md="4"><label class="input-label">Red. BC ST (%)</label><v-text-field v-model="currentItemTax.pRedBCST" density="compact" variant="outlined" type="number" class="ui-field"></v-text-field></v-col>
                            <v-col cols="12" md="3"><label class="input-label">Base Calc ST (R$)</label><v-text-field v-model="currentItemTax.vBCST" density="compact" variant="outlined" type="number" class="ui-field font-weight-bold text-error"></v-text-field></v-col>
                            <v-col cols="12" md="3"><label class="input-label">Alíq. ICMS ST (%)</label><v-text-field v-model="currentItemTax.p_icmsst" density="compact" variant="outlined" type="number" class="ui-field"></v-text-field></v-col>
                            <v-col cols="12" md="3"><label class="input-label">Valor ICMS ST (R$)</label><v-text-field v-model="currentItemTax.vICMSST" density="compact" variant="outlined" type="number" class="ui-field font-weight-bold text-error"></v-text-field></v-col>
                            <v-col cols="12" md="3"><label class="input-label">% FCP ST</label><v-text-field v-model="currentItemTax.pFCPST" density="compact" variant="outlined" type="number" class="ui-field"></v-text-field></v-col>
                        </v-row>
                    </div>

                    <div v-show="taxTab === 'ipi'">
                        <div class="text-subtitle-1 font-weight-black mb-4 d-flex align-center gap-2 border-b pb-2 text-primary"><v-icon>mdi-factory</v-icon> IPI (Imposto sobre Produto Industrializado)</div>
                        <v-row dense class="row-gap w-100 ma-0">
                            <v-col cols="12">
                              <label class="input-label">Situação Tributária do IPI (CST)</label>
                              <v-select
                                  v-model="currentItemTax.cst_ipi"
                                  :items="taxOptions.cst_ipi"
                                  item-title="title"
                                  item-value="value"
                                  density="compact"
                                  variant="outlined"
                                  class="ui-field font-weight-bold"
                                  @update:model-value="handleCstIpiChange"
                              ></v-select>
                          </v-col>
                            <v-col cols="12" md="6"><label class="input-label">Cód. Enquadramento</label><v-text-field v-model="currentItemTax.c_enq" density="compact" variant="outlined" placeholder="999" class="ui-field"></v-text-field></v-col>
                            <v-col cols="12" md="6"><label class="input-label">CNPJ Produtor (Equiparado)</label><v-text-field v-model="currentItemTax.cnpjProd" density="compact" variant="outlined" placeholder="Somente se diferente do emitente" class="ui-field"></v-text-field></v-col>

                            <v-col cols="12"><v-divider class="my-2 border-dashed"></v-divider></v-col>

                            <v-col cols="12" md="6"><label class="input-label">Base Cálculo IPI (R$)</label><v-text-field v-model="currentItemTax.vBCIPI" density="compact" variant="outlined" type="number" class="ui-field" placeholder="Auto (Valor Produto)"></v-text-field></v-col>
                            <v-col cols="12" md="6"><label class="input-label">Alíquota IPI (%)</label><v-text-field v-model="currentItemTax.p_ipi" density="compact" variant="outlined" type="number" class="ui-field font-weight-bold text-primary"></v-text-field></v-col>
                        </v-row>
                    </div>

                    <div v-show="taxTab === 'pis'">
                        <div class="text-subtitle-1 font-weight-black mb-4 d-flex align-center gap-2 border-b pb-2 text-primary"><v-icon>mdi-hand-coin-outline</v-icon> PIS / COFINS</div>
                        <v-row dense class="row-gap w-100 ma-0">
                            <v-col cols="12"><label class="input-label">Situação Tributária (CST) PIS/COFINS</label><v-select v-model="currentItemTax.cst_pis_cofins" :items="taxOptions.cst_pis_cofins" item-title="title" item-value="value" density="compact" variant="outlined" class="ui-field font-weight-bold"></v-select></v-col>

                            <v-col cols="12"><v-divider class="my-2 border-dashed"></v-divider></v-col>
                            <v-col cols="12" md="6"><label class="input-label">Base Calc PIS (R$)</label><v-text-field v-model="currentItemTax.vBCPIS" density="compact" variant="outlined" type="number" class="ui-field" placeholder="Auto"></v-text-field></v-col>
                            <v-col cols="12" md="6"><label class="input-label">Alíq. PIS (%)</label><v-text-field v-model="currentItemTax.p_pis" density="compact" variant="outlined" type="number" class="ui-field font-weight-bold"></v-text-field></v-col>

                            <v-col cols="12"><v-divider class="my-2 border-dashed"></v-divider></v-col>
                            <v-col cols="12" md="6"><label class="input-label">Base Calc COFINS (R$)</label><v-text-field v-model="currentItemTax.vBCCOFINS" density="compact" variant="outlined" type="number" class="ui-field" placeholder="Auto"></v-text-field></v-col>
                            <v-col cols="12" md="6"><label class="input-label">Alíq. COFINS (%)</label><v-text-field v-model="currentItemTax.p_cofins" density="compact" variant="outlined" type="number" class="ui-field font-weight-bold"></v-text-field></v-col>
                        </v-row>
                    </div>

                    <div v-show="taxTab === 'difal'">
                        <div class="text-subtitle-1 font-weight-black mb-4 d-flex align-center gap-2 border-b pb-2 text-primary"><v-icon>mdi-map-marker-path</v-icon> DIFAL / ICMS Partilha Interestadual</div>
                        <div class="text-caption mb-4 opacity-80">Grupo obrigatório em vendas interestaduais para Consumidor Final (Não Contribuinte). Exemplo: E-commerce.</div>
                        <v-row dense class="row-gap w-100 ma-0">
                            <v-col cols="12" md="6"><label class="input-label">Base de Cálculo DIFAL (R$)</label><v-text-field v-model="currentItemTax.vBCUFDest" density="compact" variant="outlined" type="number" class="ui-field" placeholder="Auto"></v-text-field></v-col>
                            <v-col cols="12" md="6"><label class="input-label">% FCP Destino (Pobreza)</label><v-text-field v-model="currentItemTax.pFCPUFDest" density="compact" variant="outlined" type="number" class="ui-field" placeholder="Ex: 2"></v-text-field></v-col>
                            <v-col cols="12" md="4"><label class="input-label">Alíq. Interna UF Destino (%)</label><v-text-field v-model="currentItemTax.pICMSUFDest" density="compact" variant="outlined" type="number" class="ui-field font-weight-bold" placeholder="Ex: 18"></v-text-field></v-col>
                            <v-col cols="12" md="4"><label class="input-label">Alíq. Interestadual (%)</label><v-text-field v-model="currentItemTax.pICMSInter" density="compact" variant="outlined" type="number" class="ui-field" placeholder="4, 7 ou 12"></v-text-field></v-col>
                            <v-col cols="12" md="4"><label class="input-label">% Partilha Destino</label><v-text-field v-model="currentItemTax.pICMSInterPart" density="compact" variant="outlined" type="number" class="ui-field" placeholder="100"></v-text-field></v-col>
                        </v-row>
                    </div>

                    <div v-show="taxTab === 'retencoes'">
                        <div class="text-subtitle-1 font-weight-black mb-4 d-flex align-center gap-2 border-b pb-2 text-primary"><v-icon>mdi-bank-transfer</v-icon> Retenções Federais na Fonte</div>
                        <div class="text-caption mb-4 opacity-80">Apenas para notas que contenham prestação de serviços sujeitas a retenção na fonte.</div>
                        <v-row dense class="row-gap w-100 ma-0">
                            <v-col cols="12" md="4"><label class="input-label">Valor Retido PIS (R$)</label><v-text-field v-model="currentItemTax.vRetPIS" density="compact" variant="outlined" type="number" class="ui-field text-error"></v-text-field></v-col>
                            <v-col cols="12" md="4"><label class="input-label">Valor Retido COFINS (R$)</label><v-text-field v-model="currentItemTax.vRetCOFINS" density="compact" variant="outlined" type="number" class="ui-field text-error"></v-text-field></v-col>
                            <v-col cols="12" md="4"><label class="input-label">Valor Retido CSLL (R$)</label><v-text-field v-model="currentItemTax.vRetCSLL" density="compact" variant="outlined" type="number" class="ui-field text-error"></v-text-field></v-col>

                            <v-col cols="12"><v-divider class="my-2 border-dashed"></v-divider></v-col>

                            <v-col cols="12" md="4"><label class="input-label">Base Calc IRRF (R$)</label><v-text-field v-model="currentItemTax.vBCIRRF" density="compact" variant="outlined" type="number" class="ui-field"></v-text-field></v-col>
                            <v-col cols="12" md="4"><label class="input-label">Valor Retido IRRF (R$)</label><v-text-field v-model="currentItemTax.vIRRF" density="compact" variant="outlined" type="number" class="ui-field text-error font-weight-bold"></v-text-field></v-col>
                            <v-col cols="12" md="4"><label class="input-label">Valor Ret. Previdência (R$)</label><v-text-field v-model="currentItemTax.vRetPrev" density="compact" variant="outlined" type="number" class="ui-field text-error"></v-text-field></v-col>
                        </v-row>
                    </div>

                    <div v-show="taxTab === 'reforma'">
                        <div class="text-subtitle-1 font-weight-black mb-4 d-flex align-center gap-2 border-b pb-2 text-primary"><v-icon>mdi-calendar-clock</v-icon> Reforma Tributária 2026 (IBS/CBS/IS)</div>
                        <div class="text-caption mb-4 opacity-80 text-warning font-weight-bold"><v-icon size="small" color="warning">mdi-alert</v-icon> Campos preparados para o novo layout Sefaz da Transição Tributária (IBS, CBS e Imposto Seletivo).</div>
                        <v-row dense class="row-gap w-100 ma-0">
                            <v-col cols="12" md="8"><label class="input-label">CST IBS/CBS</label><v-text-field v-model="currentItemTax.CST_IBSCBS" density="compact" variant="outlined" placeholder="Ex: 00" class="ui-field"></v-text-field></v-col>
                            <v-col cols="12" md="4"><label class="input-label">Cód Classific. Tributária</label><v-text-field v-model="currentItemTax.cClassTrib" density="compact" variant="outlined" placeholder="Ex: 00000" class="ui-field"></v-text-field></v-col>

                            <v-col cols="12" md="4"><label class="input-label">Alíq. IBS Estado (%)</label><v-text-field v-model="currentItemTax.pIBSUF" density="compact" variant="outlined" type="number" class="ui-field"></v-text-field></v-col>
                            <v-col cols="12" md="4"><label class="input-label">Alíq. IBS Município (%)</label><v-text-field v-model="currentItemTax.pIBSMun" density="compact" variant="outlined" type="number" class="ui-field"></v-text-field></v-col>
                            <v-col cols="12" md="4"><label class="input-label">Alíq. CBS Federal (%)</label><v-text-field v-model="currentItemTax.pCBS" density="compact" variant="outlined" type="number" class="ui-field font-weight-bold"></v-text-field></v-col>

                            <v-col cols="12"><v-divider class="my-2 border-dashed"></v-divider></v-col>

                            <v-col cols="12" md="6"><label class="input-label">CST Imposto Seletivo (IS)</label><v-text-field v-model="currentItemTax.CST_IS" density="compact" variant="outlined" class="ui-field" placeholder="Ex: 00"></v-text-field></v-col>
                            <v-col cols="12" md="6"><label class="input-label">Alíquota IS (%)</label><v-text-field v-model="currentItemTax.pIS" density="compact" variant="outlined" type="number" class="ui-field"></v-text-field></v-col>
                        </v-row>
                    </div>

                </div>
            </div>

            <div class="pa-4 flex-shrink-0 d-flex align-center justify-space-between shadow-md" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-4 border-t border-grey-lighten-2' : 'bg-black-40 border-t border-white-10'">
                <v-checkbox v-model="applyTaxToAll" label="Aplicar esta tributação a TODOS os itens da nota" :color="themeStore.currentMode === 'light' ? 'primary' : 'primary'" hide-details class="font-weight-black text-caption m-0 p-0"></v-checkbox>
                <div class="d-flex gap-3">
                    <v-btn variant="outlined" class="btn-3d font-weight-bold" @click="showTaxModal = false" height="46">Cancelar</v-btn>
                    <v-btn color="primary" variant="flat" class="btn-3d font-weight-black px-8" @click="saveTaxDetails" height="46"><v-icon start>mdi-check</v-icon> Salvar Regras Fiscais</v-btn>
                </div>
            </div>
        </v-card>
    </v-dialog>

    <v-dialog v-model="danfeModal.show" max-width="1000" scrollable>
        <v-card class="rounded-lg h-100 border shadow-xl" :class="themeStore.currentMode === 'light' ? 'border-grey-lighten-2 bg-white' : 'border-white-10 bg-glass-dark'">
            <v-toolbar density="compact" class="elevation-0 border-b" :class="themeStore.currentMode === 'light' ? 'bg-grey-darken-4 border-grey-darken-3' : 'bg-primary border-white-10'">
                <v-toolbar-title class="text-caption font-weight-bold text-white tracking-wide">Prévia DANFE Sefaz</v-toolbar-title>
                <v-spacer></v-spacer>
                <v-btn icon color="white" class="btn-3d" @click="danfeModal.show = false"><v-icon>mdi-close</v-icon></v-btn>
            </v-toolbar>
            <v-card-text class="pa-0 h-[600px]" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-2' : 'bg-black'" style="height: 80vh;">
                <div v-if="previewLoading" class="d-flex align-center justify-center h-100 flex-column">
                    <v-progress-circular indeterminate :color="themeStore.currentMode === 'light' ? 'grey-darken-4' : 'success'" size="48" width="3"></v-progress-circular>
                    <div class="mt-4 font-weight-bold" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">Renderizando PDF localmente...</div>
                </div>
                <iframe v-else-if="danfeModal.url" :src="danfeModal.url" class="pdf-iframe w-100 h-100 border-0"></iframe>
            </v-card-text>
        </v-card>
    </v-dialog>

    <v-dialog v-model="errorDialog.show" max-width="450" persistent>
        <v-card class="rounded-lg border shadow-xl" :class="themeStore.currentMode === 'light' ? 'border-grey-lighten-2 bg-white' : 'border-white-10 bg-glass-dark'">
            <div class="pa-6 text-center">
                <div class="mb-4 d-flex justify-center">
                    <v-avatar color="red-lighten-5" size="80" class="rounded-lg shadow-sm">
                        <v-icon size="40" color="red-darken-2">mdi-alert-octagon</v-icon>
                    </v-avatar>
                </div>
                <h3 class="text-h6 font-weight-black text-red-darken-3 mb-2">Rejeição Sefaz / Comunicação</h3>
                <p class="text-body-2 mb-2 px-2 font-weight-medium" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-3' : 'text-white-70'">
                    {{ errorDialog.friendlyMessage }}
                </p>

                <div v-if="emissionLogs.length > 0" class="mb-6 text-left bg-black-20 pa-3 rounded font-mono text-[10px] custom-scroll" style="max-height: 150px; overflow-y: auto;">
                    <div class="font-weight-bold mb-1 opacity-70" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">Logs do Processo:</div>
                    <div v-for="(log, idx) in emissionLogs" :key="idx" :class="log.type === 'error' ? 'text-red-darken-2' : (log.type === 'success' ? 'text-green-darken-2' : (themeStore.currentMode === 'light' ? 'text-grey-darken-2' : 'text-grey-lighten-1'))">
                        [{{ log.time }}] {{ log.step }}: {{ log.message }}
                    </div>
                </div>

                <div class="d-flex flex-column gap-3">
                    <v-btn :color="themeStore.currentMode === 'light' ? 'grey-darken-4' : 'primary'" variant="flat" block size="large" class="font-weight-bold shadow-sm btn-3d" @click="errorDialog.show = false">
                        <v-icon start>mdi-pencil-outline</v-icon> Corrigir Nota
                    </v-btn>
                    <v-btn color="grey-darken-2" variant="outlined" block size="large" class="font-weight-bold btn-3d" @click="saveDraftFromError">
                        <v-icon start>mdi-content-save-edit</v-icon> Salvar Rascunho
                    </v-btn>
                    <v-btn color="grey" variant="text" block class="text-caption font-weight-bold mt-2 btn-3d" prepend-icon="mdi-content-copy" @click="copyErrorLogs">
                        Copiar Logs Técnicos
                    </v-btn>
                </div>
            </div>
        </v-card>
    </v-dialog>

  </v-dialog>
</template>

<script setup lang="ts">
import { ref, reactive, computed, watch, onMounted } from 'vue';
import { supabase } from '@/api/supabase';
import { sefazService } from '@/api/sefazApi';
import { useAppStore } from '@/stores/app';
import { useThemeStore } from '@/stores/theme';
import { useCompanyStore } from '@/stores/company';
import { DANFe } from 'node-sped-pdf';
import { format } from 'date-fns';
import { PDFDocument, rgb, StandardFonts } from 'pdf-lib';
import axios from 'axios';

const props = defineProps<{
    modelValue: boolean;
    orderId?: string | null;
    draftId?: string | null;
    draftPayload?: any;
}>();

const emit = defineEmits(['update:modelValue', 'success', 'draft-saved']);

const dialog = computed({
    get: () => props.modelValue,
    set: (val) => emit('update:modelValue', val)
});

const appStore = useAppStore();
const themeStore = useThemeStore();
const companyStore = useCompanyStore();
const SEFAZ_PROXY_URL = import.meta.env.VITE_SEFAZ_PROXY_URL || 'https://sefaz-proxy-dujl.onrender.com';

// ROLE E PERMISSÕES
const userRole = ref<string | null>(null);
const isFullStack = computed(() => userRole.value === 'Full-Stack');

const fetchUserRole = async () => {
    const { data: { user } } = await supabase.auth.getUser();
    if (user) {
        const { data, error } = await supabase
            .from('profiles')
            .select(`
                custom_role_id,
                custom_roles ( name )
            `)
            .eq('id', user.id)
            .single();

        if (!error) {
            userRole.value = (data?.custom_roles as any)?.name || null;
        }
    }
};

onMounted(() => {
    fetchUserRole();
});

// ENGINE DE LOGS
const emissionLogs = ref<any[]>([]);
const addLog = (step: string, message: string, type: 'info' | 'error' | 'success' = 'info', raw: any = null) => {
    const time = new Date().toLocaleTimeString();
    emissionLogs.value.push({ time, step, message, type });
    console.log(`[NFe Log - ${step}]`, message, raw || '');
};

const forceNum = (val: any) => {
    if (val === null || val === undefined || val === '') return 0;
    if (typeof val === 'number') return val;
    let s = String(val).trim().replace(/R\$\s?/gi, '').replace(/\s/g, '');
    if (s.includes('.') && s.includes(',')) s = s.replace(/\./g, '').replace(',', '.');
    else if (s.includes(',')) s = s.replace(',', '.');
    const n = Number(s);
    return isNaN(n) ? 0 : n;
};

const inputClass = computed(() => themeStore.currentMode === 'light' ? 'bg-white border-grey-lighten-2 text-grey-darken-4' : 'bg-black-20 border-white-10 text-white');
const inputClassDisabled = computed(() => themeStore.currentMode === 'light' ? 'bg-grey-lighten-4 border-grey-lighten-2 text-grey-darken-2' : 'bg-black-40 border-white-10 text-white-70');

const isEditingDraft = ref(false);
const loadingOrderData = ref(false);
const savingDraft = ref(false);

const issuing = ref(false);
const issuingProvider = ref<'nuvem' | 'sefaz' | null>(null);

const previewLoading = ref(false);
const loadingCCC = ref(false);
const loadingCnpj = ref(false);
const informarPagamento = ref(false);
const applyTaxToAll = ref(false);

const companies = ref<any[]>([]);
const activeCompany = ref<any>(null);
const nextNfeNumber = ref(0);
const currentDefaultCst = ref('102');

const auxData = reactive({ clients: [] as any[], products: [] as any[], paymentMethods: [] as any[] });
const selectedClient = ref<any>(null);
const estados = ['SP', 'RJ', 'MG', 'RS', 'PR', 'SC', 'BA', 'PE', 'DF', 'GO', 'ES', 'CE', 'PA', 'MA', 'PB', 'AM', 'RN', 'AL', 'PI', 'MT', 'MS', 'SE', 'RO', 'TO', 'AC', 'AP', 'RR'];

const showTaxModal = ref(false);
const taxTabList = ref(['icms']);
const taxTab = computed(() => taxTabList.value[0]);
const currentItemTax = ref<any>(null);
const currentEditingItemIndex = ref(-1);

const handleCstIpiChange = (newCst: string) => {
    if (!currentItemTax.value) return;

    if (['02', '52'].includes(newCst)) {
        currentItemTax.value.c_enq = '399';
        appStore.showSnackbar('CST de Isenção selecionado. O Código de Enquadramento foi ajustado para o padrão Sefaz (399).', 'info');
    }
    else if (['04', '54'].includes(newCst)) {
        currentItemTax.value.c_enq = '099';
        appStore.showSnackbar('CST de Imunidade selecionado. O Código de Enquadramento foi ajustado para o padrão Sefaz (099).', 'info');
    }
    else if (['05', '55'].includes(newCst)) {
        currentItemTax.value.c_enq = '199';
        appStore.showSnackbar('CST de Suspensão selecionado. O Código de Enquadramento foi ajustado para o padrão Sefaz (199).', 'info');
    }
    else {
        currentItemTax.value.c_enq = '999';
    }
};

const danfeModal = reactive({ show: false, url: '' });
const errorDialog = reactive({ show: false, friendlyMessage: '', rawDetails: null as any });

const taxOptions = {
    origem: [
        { value: 0, title: '0 - Nacional' },
        { value: 1, title: '1 - Estrangeira (Importação Direta)' },
        { value: 2, title: '2 - Estrangeira (Mercado Interno)' },
        { value: 3, title: '3 - Nacional (Imp. > 40% e <= 70%)' },
        { value: 4, title: '4 - Nacional (Produção conforme PPB)' },
        { value: 5, title: '5 - Nacional (Imp. <= 40%)' },
        { value: 6, title: '6 - Estrangeira (Direta, sem similar nacional)' },
        { value: 7, title: '7 - Estrangeira (Merc. Interno, sem similar)' },
        { value: 8, title: '8 - Nacional (Imp. > 70%)' }
    ],
    cst_csosn: [
        { value: '00', title: '00 - Tributada Integralmente (Reg. Normal)' },
        { value: '10', title: '10 - Tributada + Cobrança ICMS por ST' },
        { value: '20', title: '20 - Com Redução de Base de Cálculo' },
        { value: '30', title: '30 - Isenta/NT + Cobrança ICMS por ST' },
        { value: '40', title: '40 - Isenta (Reg. Normal)' },
        { value: '41', title: '41 - Não Tributada (Reg. Normal)' },
        { value: '50', title: '50 - Suspensão' },
        { value: '51', title: '51 - Diferimento' },
        { value: '60', title: '60 - ICMS cobrado anteriormente por ST' },
        { value: '70', title: '70 - Redução Base + Cobrança ST' },
        { value: '90', title: '90 - Outras (Reg. Normal)' },
        { value: '101', title: '101 - Simples c/ Permissão de Crédito' },
        { value: '102', title: '102 - Simples s/ Permissão de Crédito' },
        { value: '103', title: '103 - Simples Isenção para faixa de receita' },
        { value: '201', title: '201 - Simples c/ Crédito + Cobrança ST' },
        { value: '202', title: '202 - Simples s/ Crédito + Cobrança ST' },
        { value: '203', title: '203 - Simples Isenção + Cobrança ST' },
        { value: '300', title: '300 - Simples Imune' },
        { value: '400', title: '400 - Simples Não Tributada' },
        { value: '500', title: '500 - Simples ICMS Cobrado Ant. por ST' },
        { value: '900', title: '900 - Outros (Simples Nacional)' }
    ],
    cst_ipi: [
        { value: '50', title: '50 - Saída Tributada' },
        { value: '51', title: '51 - Saída Tributável com Alíquota Zero' },
        { value: '52', title: '52 - Saída Isenta' },
        { value: '53', title: '53 - Saída Não Tributada' },
        { value: '54', title: '54 - Saída Imune' },
        { value: '55', title: '55 - Saída com Suspensão' },
        { value: '99', title: '99 - Outras Saídas' },
        { value: '00', title: '00 - Entrada com Recuperação de Crédito' },
        { value: '01', title: '01 - Entrada Tributável com Alíquota Zero' },
        { value: '02', title: '02 - Entrada Isenta' },
        { value: '03', title: '03 - Entrada Não Tributada' },
        { value: '04', title: '04 - Entrada Imune' },
        { value: '05', title: '05 - Entrada com Suspensão' },
        { value: '49', title: '49 - Outras Entradas' }
    ],
    cst_pis_cofins: [
        { value: '01', title: '01 - Operação Tributável Alíquota Básica' },
        { value: '02', title: '02 - Operação Tributável Alíquota Diferenciada' },
        { value: '03', title: '03 - Operação Tributável (Unidade de Medida)' },
        { value: '04', title: '04 - Tributável Monofásica (Alíquota Zero)' },
        { value: '05', title: '05 - Operação Tributável por ST' },
        { value: '06', title: '06 - Operação Tributável a Alíquota Zero' },
        { value: '07', title: '07 - Operação Isenta da Contribuição' },
        { value: '08', title: '08 - Operação sem Incidência' },
        { value: '09', title: '09 - Operação com Suspensão' },
        { value: '49', title: '49 - Outras Operações de Saída' },
        { value: '50', title: '50 - Entrada c/ Direito a Crédito' },
        { value: '70', title: '70 - Entrada s/ Direito a Crédito' },
        { value: '73', title: '73 - Aquisição a Alíquota Zero' },
        { value: '98', title: '98 - Outras Entradas' },
        { value: '99', title: '99 - Outras Operações' }
    ]
};

const getInitialItemState = () => ({
    descricao: '', ncm: '', cest: '', cfop: '5102', unidade: 'UN', quantidade: 1, valor_unitario: 0, desconto: 0,
    vFrete: 0, vSeg: 0, vOutro: 0, xPed: '', nItemPed: '',
    lotes: [], di: [],
    impostos: {
        origem: 0,
        cst_csosn: currentDefaultCst.value,
        modBC: 3,
        p_icms: 0, p_red_bc: 0, vBC: 0, vICMS: 0, pFCP: 0,
        modBCST: 4, pMVAST: 0, pRedBCST: 0, vBCST: 0, p_icmsst: 0, vICMSST: 0, pFCPST: 0,
        pST: 0, vICMSSubstituto: 0, vFCPSTRet: 0,
        pICMSUFDest: 0, vBCUFDest: 0, pFCPUFDest: 0, pICMSInter: 0, pICMSInterPart: 100,
        c_enq: '999', cst_ipi: '99', p_ipi: 0,
        cst_pis_cofins: '99', p_pis: 0, p_cofins: 0,
        vII: 0, vDespAdu: 0, vIOF: 0,
        vRetPIS: 0, vRetCOFINS: 0, vRetCSLL: 0, vIRRF: 0, vBCIRRF: 0, vRetPrev: 0,
        CST_IBSCBS: '', cClassTrib: '', pIBSUF: 0, pIBSMun: 0, pCBS: 0,
        CST_IS: '', pIS: 0
    }
});

const initialFormState = {
    natureza_operacao: 'VENDA', data_emissao: '', data_saida: '',
    tpNF: 1, finNFe: 1, indFinal: 1, indPres: 1, indIntermed: 0, cnpjIntermediador: '', idCadIntTran: '', chavesReferenciadas: [],
    emitente: { cnpj: '', nome: '', fantasia: '', ie: '', im: '', crt: '1', cnae: '', telefone: '', endereco: { logradouro: '', numero: '', complemento: '', bairro: '', municipio: '', uf: 'SP', cep: '', codigo_municipio: '' } },
    destinatario: { cnpj_cpf: '', nome: '', ie: '', im: '', indIEDest: '9', email: '', endereco: { logradouro: '', numero: '', bairro: '', municipio: '', uf: 'SP', cep: '', codigo_municipio: '' } },
    transporte: { modFrete: 9, cnpj: '', IE: '', xNome: '', xEnder: '', xMun: '', UF: '', placa: '', placaUF: '', qVol: 0, esp: '', pesoB: 0, pesoL: 0 },
    itens: [],
    pagamentos: [{ nDup: '001', tPag: '01', indPag: '0', vPag: 0, dVenc: '', vTroco: 0, cAut: '', cnpjCredenciadora: '', tBand: '99', tpIntegra: '2' }],
    obs: '', obsFisco: ''
};

const form = reactive(JSON.parse(JSON.stringify(initialFormState)));

const translateSefazError = (errObj: any) => {
    if (!errObj) return "Erro desconhecido ao comunicar com a Sefaz.";
    const raw = typeof errObj === 'string' ? errObj : JSON.stringify(errObj);

    if (raw.includes('Network Error') || raw.includes('ERR_NETWORK')) {
        return 'O Proxy Node.js derrubou a conexão (Network Error). Isso ocorre se a rota da Sefaz Direta não estiver ativa no servidor ou se o Node.js sofreu um crash fatal devido a certificado SSL inválido/ausente no .env do Render. Verifique os logs no painel do Render.';
    }

    if (raw.includes('conflito com o configurado para a empresa')) return 'O ambiente solicitado (homologação/produção) está em conflito com o configurado na Nuvem Fiscal para este CNPJ.';
    if (raw.includes('Duplicidade')) return 'Já existe uma nota fiscal autorizada com este número para este CNPJ. Atualize o número.';
    if (raw.includes('modBC') || raw.includes('vBC')) return 'Inconsistência na Base de Cálculo. Verifique a tributação dos itens.';
    if (raw.includes('NCM')) return 'O código NCM é inválido, inexistente ou incompatível.';
    if (raw.includes('Inscricao Estadual') || raw.includes('IE') || raw.includes('Não Contribuinte')) return 'A Inscrição Estadual (IE) informada é inválida ou o cliente foi marcado incorretamente.';
    if (raw.includes('CFOP')) return 'O código CFOP informado não é compatível com a operação ou destino.';
    if (raw.includes('Assinatura') || raw.includes('Certificado')) return 'O certificado digital cadastrado está inválido, vencido ou corrompido.';
    if (raw.includes('Rejeicao:')) { const match = raw.match(/Rejeicao:\s(.*?)(?="|,|\\n|$)/); if (match) return match[1]; }
    if (errObj.message) return errObj.message;
    return 'A Sefaz/Gateway rejeitou a emissão devido a uma inconsistência nos dados.';
};

const copyErrorLogs = () => {
    const txt = typeof errorDialog.rawDetails === 'string' ? errorDialog.rawDetails : JSON.stringify(errorDialog.rawDetails, null, 2);
    const fullLogs = JSON.stringify(emissionLogs.value, null, 2);
    navigator.clipboard.writeText(txt + '\n\n=== LOGS DO PROCESSO ===\n' + fullLogs);
    appStore.showSnackbar('Logs técnicos copiados!', 'success');
};

const saveDraftFromError = () => {
    errorDialog.show = false;
    saveDraft();
};

const formatRawCurrency = (v: any) => Number(v || 0).toFixed(2);
const parseValue = (val: any) => { if (!val) return 0; if (typeof val === 'number') return val; return isNaN(parseFloat(String(val))) ? 0 : parseFloat(String(val)); };

const totalDesconto = computed(() => form.itens.reduce((acc: number, item: any) => acc + (Number(item.desconto) || 0), 0));
const totalFormValue = computed(() => form.itens.reduce((acc: number, item: any) => acc + (item.quantidade * item.valor_unitario), 0));

const taxTotals = computed(() => {
    let vBC=0, vICMS=0, vIPI=0, vPIS=0, vCOFINS=0, vST=0, vFCPST=0;
    form.itens.forEach((item: any) => {
        const qtd = parseValue(item.quantidade);
        const unit = parseValue(item.valor_unitario);
        const desc = parseValue(item.desconto);
        const vProd = (qtd * unit) - desc;
        const imp = item.impostos || {};

        const pRed = parseValue(imp.p_red_bc);
        const bc = pRed > 0 ? vProd * (1 - pRed/100) : vProd;
        vBC += parseValue(imp.vBC) || bc;
        vICMS += parseValue(imp.vICMS) || (bc * (parseValue(imp.p_icms)/100));
        vIPI += parseValue(imp.vBCIPI) ? (parseValue(imp.vBCIPI) * (parseValue(imp.p_ipi)/100)) : ((qtd * unit) * (parseValue(imp.p_ipi)/100));
        vPIS += vProd * (parseValue(imp.p_pis)/100);
        vCOFINS += vProd * (parseValue(imp.p_cofins)/100);
        vST += parseValue(imp.vICMSST);
        vFCPST += parseValue(imp.vFCPST) || (parseValue(imp.vBCST) * (parseValue(imp.pFCPST)/100));
    });
    return { vBC, vICMS, vIPI, vPIS, vCOFINS, vST, vFCPST };
});

const loadInitialData = async () => {
    const { data: dbCompanies } = await supabase.from('companies').select('*');
    companies.value = (dbCompanies || []).map(c => ({
        ...c, nfe_environment: c.nfe_environment || 'homologacao', nfe_series: c.nfe_series || 1, nfe_next_number: parseInt(c.nfe_next_number) || 1, crt: c.crt || '1'
    }));

    if (companies.value.length > 0 && !activeCompany.value) {
        activeCompany.value = companyStore.context ? (companies.value.find(c => c.id === companyStore.context) || companies.value[0]) : companies.value[0];
        populateEmitente();
    }

    const { data: clients } = await supabase.from('customers_mj').select('*').order('nome', { ascending: true });
    auxData.clients = (clients || []).map((c: any) => ({ ...c, searchLabel: `${c.razao_social || c.nome} (${c.cnpj || c.cpf || c.cpf_cnpj || 'Sem Doc'})` }));

    const { data: stocks } = await supabase.from('stock').select('*');
    auxData.products = (stocks || []).map((s: any) => ({ ...s, label: `${s.fabric_type || ''} ${s.color || ''}`.trim(), ncm: s.ncm }));

    auxData.paymentMethods = [{name: 'Dinheiro', value: '01'}, {name: 'Cartão Crédito', value: '03'}, {name: 'Cartão Débito', value: '04'}, {name: 'Boleto', value: '15'}, {name: 'PIX', value: '17'}, {name: 'Sem Pagamento', value: '90'}];
};

const populateEmitente = () => {
    const comp = activeCompany.value;
    if (comp) {
        form.emitente = {
            cnpj: comp.cnpj || '', nome: comp.name || '', fantasia: comp.trade_name || comp.fantasia || '', ie: comp.ie || 'ISENTO', im: comp.im || '',
            crt: String(comp.crt || '1'), cnae: comp.cnae || '', telefone: comp.telefone || '',
            endereco: {
                logradouro: comp.street || comp.logradouro || comp.endereco || '',
                numero: comp.number || comp.numero || '',
                complemento: comp.complemento || '',
                bairro: comp.district || comp.bairro || '',
                municipio: comp.city || comp.municipio || '',
                uf: comp.uf || 'SP',
                cep: comp.zip_code || comp.cep || '',
                codigo_municipio: comp.ibge_code || comp.codigo_municipio || '3554508'
            }
        };
        nextNfeNumber.value = Number(comp.nfe_next_number || 1);
        currentDefaultCst.value = comp.default_cst_csosn || (comp.crt === '3' ? '00' : '102');
        if(form.itens && form.itens.length > 0) {
             form.itens.forEach((item: any) => { if (item.impostos && !item.impostos.cst_csosn_modificado) item.impostos.cst_csosn = currentDefaultCst.value; });
        }
        form.obs = comp.nfe_info_complementar || '';
    }
};

const loadOrderData = async (orderId: string) => {
    loadingOrderData.value = true;
    try {
        let { data: order } = await supabase.from('orders').select('*, customer:customers_mj(*)').eq('id', orderId).maybeSingle();
        let items = [];

        if (order) {
            const { data: orderItems } = await supabase.from('order_items').select('*').eq('order_id', orderId);
            items = orderItems || [];
        } else {
            const { data: storeSale } = await supabase.from('store_sales').select('*').eq('id', orderId).maybeSingle();
            if (storeSale) {
                order = storeSale;
                if (order.customer_id) {
                    const { data: c } = await supabase.from('customers_mj').select('*').eq('id', order.customer_id).maybeSingle();
                    if (c) order.customer = c;
                } else if (order.customer_name) {
                    const { data: c } = await supabase.from('customers_mj').select('*').ilike('nome', `%${order.customer_name}%`).limit(1).maybeSingle();
                    if (c) order.customer = c;
                }
                if (order.items && Array.isArray(order.items) && order.items.length > 0) items = order.items;
                else { const { data: storeItems } = await supabase.from('store_sale_items').select('*').eq('store_sale_id', orderId); items = storeItems || []; }
            }
        }

        if (order) {
            if (order.customer) handleClientSelection(order.customer);
            else form.destinatario.nome = order.customer_name || 'CONSUMIDOR FINAL';

            if (!form.obs) form.obs = typeof order.details === 'object' ? (order.details?.observation || '') : '';

            if (items && items.length > 0) {
                form.itens = items.map((i: any) => {
                    const desc = i.produto?.nome_produto || i.nome_produto || i.nome || i.descricao || i.name || i.fabric_type || 'Item Diverso';
                    let qtd = forceNum(i.produto?.quantidade ?? i.quantidade ?? i.quantity ?? i.quantity_meters ?? 1);
                    if (qtd <= 0) qtd = 1;
                    let val = forceNum(i.produto?.valor_unitario ?? i.valor_unitario ?? i.preco_unitario ?? i.unit_price ?? i.produto?.preco ?? i.preco ?? i.produto?.price ?? i.price ?? i.valor);
                    if (val === 0) { const subtotal = forceNum(i.total_value_items ?? i.total ?? i.valor_total ?? i.produto?.valor_total ?? i.subtotal ?? i.total_price); if (subtotal > 0) val = subtotal / qtd; }
                    if (val === 0 && order.total_value > 0) val = forceNum(order.total_value) / items.length / qtd;
                    const stockMatch = auxData.products.find((p: any) => p.fabric_type === desc || p.fabric_type === i.fabric_type);

                    return { ...getInitialItemState(), descricao: desc, ncm: stockMatch?.ncm || i.ncm || '61091000', quantidade: qtd, valor_unitario: Number(val.toFixed(2)), _original_unit_price: Number(val.toFixed(2)), desconto: 0 };
                });
            } else if (order.total_value > 0) {
                const totalCru = forceNum(order.total_value);
                form.itens = [{ ...getInitialItemState(), descricao: 'Produtos Diversos', ncm: '61091000', quantidade: 1, valor_unitario: Number(totalCru.toFixed(2)), _original_unit_price: Number(totalCru.toFixed(2)) }];
            }

            if (form.destinatario.endereco.uf) await applyTaxRulesFromUF(form.destinatario.endereco.uf);

            const schedule = order.details?.installments_schedule;
            if (schedule && schedule.length > 0) {
                informarPagamento.value = true;
                form.pagamentos = schedule.map((p: any, index: number) => ({
                    nDup: String(index + 1).padStart(3, '0'),
                    tPag: p.payment_method_id || '17',
                    vPag: Number(p.value).toFixed(2),
                    dVenc: p.due_date,
                    vTroco: 0, indPag: '1', cAut: '', cnpjCredenciadora: '', tBand: '99', tpIntegra: '2'
                }));
            }
        }
    } catch (e) {
        appStore.showSnackbar("Erro ao importar pedido.", "error");
    } finally { loadingOrderData.value = false; }
};

const applyPercentage = (pct: number) => {
    form.itens.forEach((item: any) => {
        if (!item._original_unit_price) item._original_unit_price = item.valor_unitario;
        item.valor_unitario = Number((item._original_unit_price * (pct / 100)).toFixed(2));
        if (item.desconto) { if (!item._original_discount) item._original_discount = item.desconto; item.desconto = Number((item._original_discount * (pct / 100)).toFixed(2)); }
    });
    if(informarPagamento.value && form.pagamentos.length > 0) form.pagamentos[0].vPag = totalFormValue.value.toFixed(2);
    appStore.showSnackbar(`Valores recalculados para ${pct}%`, 'success');
};

watch(() => props.modelValue, async (newVal) => {
    if (newVal) {
        Object.assign(form, JSON.parse(JSON.stringify(initialFormState)));
        form.data_emissao = new Date().toISOString().slice(0, 16);
        form.data_saida = new Date().toISOString().slice(0, 16);
        informarPagamento.value = false;
        applyTaxToAll.value = false;
        selectedClient.value = null;

        await loadInitialData();

        if (props.draftPayload) {
            isEditingDraft.value = !!props.draftId;
            const payload = JSON.parse(JSON.stringify(props.draftPayload));

            if (payload.emitente?.cnpj) {
                const draftCnpj = payload.emitente.cnpj.replace(/\D/g, '');
                const matchedCompany = companies.value.find(c => c.cnpj?.replace(/\D/g, '') === draftCnpj);
                if (matchedCompany) {
                    activeCompany.value = matchedCompany;
                    populateEmitente();
                }
            }

            if (payload.natureza_operacao) form.natureza_operacao = payload.natureza_operacao;
            if (payload.obs !== undefined) form.obs = payload.obs;
            if (payload.obsFisco !== undefined) form.obsFisco = payload.obsFisco;
            if (payload.destinatario) form.destinatario = { ...form.destinatario, ...payload.destinatario };
            if (payload.emitente) form.emitente = { ...form.emitente, ...payload.emitente };

            // CORREÇÃO CRÍTICA: Restaurar Transporte e outros itens cruciais que o Rascunho não puxava
            if (payload.transporte) form.transporte = { ...form.transporte, ...payload.transporte };
            if (payload.tpNF !== undefined) form.tpNF = payload.tpNF;
            if (payload.finNFe !== undefined) form.finNFe = payload.finNFe;
            if (payload.indFinal !== undefined) form.indFinal = payload.indFinal;
            if (payload.indPres !== undefined) form.indPres = payload.indPres;
            if (payload.indIntermed !== undefined) form.indIntermed = payload.indIntermed;
            if (payload.cnpjIntermediador !== undefined) form.cnpjIntermediador = payload.cnpjIntermediador;
            if (payload.chavesReferenciadas !== undefined) form.chavesReferenciadas = payload.chavesReferenciadas;

            if (payload.itens && payload.itens.length > 0) form.itens = payload.itens.map((item: any) => ({ ...getInitialItemState(), ...item, _original_unit_price: item.valor_unitario }));
            else form.itens = [getInitialItemState()];

            if (payload.pagamentos && payload.pagamentos.length > 0 && payload.pagamentos[0].tPag !== '90') {
                form.pagamentos = payload.pagamentos;
                informarPagamento.value = true;
            } else if (payload.pagamentos && payload.pagamentos.length > 0 && payload.pagamentos[0].tPag === '90') {
                informarPagamento.value = false;
            }
        } else if (props.orderId) {
            isEditingDraft.value = false;
            await loadOrderData(props.orderId);
        } else {
            isEditingDraft.value = false;
            form.itens = [getInitialItemState()];
        }
    }
}, { immediate: true });

const openQuickCustomerAdd = async () => {
    const doc = prompt('CPF/CNPJ do Cliente (Somente números):');
    if (!doc) return;
    const name = prompt('Nome/Razão Social do Cliente:');
    if (!name) return;
    const uf = prompt('Estado (UF) do Cliente (Ex: SP, RJ):')?.toUpperCase() || 'SP';
    try {
        const { data, error } = await supabase.from('customers_mj').insert({ nome: name, cpf_cnpj: doc.replace(/\D/g, ''), estado: uf, uf: uf }).select('*').single();
        if (error) throw error;
        const newClient = { ...data, searchLabel: `${data.nome} (${data.cpf_cnpj || data.cpf || data.cnpj})` };
        auxData.clients.push(newClient);
        selectedClient.value = newClient;
        handleClientSelection(newClient);
        appStore.showSnackbar('Cliente cadastrado e selecionado!', 'success');
    } catch (e: any) { appStore.showSnackbar('Erro ao salvar cliente: ' + e.message, 'error'); }
};

const applyTaxRulesFromUF = async (uf: string) => {
    if (!uf) return;
    try {
        let query = supabase.from('fiscal_tax_rules').select('*').eq('uf', uf);
        if (activeCompany.value?.id) query = query.eq('company_id', activeCompany.value.id);
        const { data: taxRule } = await query.maybeSingle();
        if (taxRule) {
            form.itens.forEach((item: any) => {
                item.cfop = taxRule.cfop;
                if(item.impostos) {
                    item.impostos.cst_csosn = taxRule.cst_csosn;
                    item.impostos.p_icms = Number(taxRule.icms_aliquot) || 0;
                    item.impostos.p_red_bc = Number(taxRule.icms_base_reduction) || 0;
                    item.impostos.p_pis = Number(taxRule.pis_aliquot) || 0;
                    item.impostos.p_cofins = Number(taxRule.cofins_aliquot) || 0;
                    item.impostos.p_ipi = Number(taxRule.ipi_aliquot) || 0;
                    item.impostos.cst_csosn_modificado = true;
                    if (taxRule.cst_csosn !== '102' && taxRule.cst_csosn !== '103' && taxRule.cst_csosn !== '400') {
                        item.impostos.modBC = 3;
                        const val = (item.quantidade * item.valor_unitario) - (Number(item.desconto) || 0);
                        const pRed = Number(taxRule.icms_base_reduction) || 0;
                        const bc = pRed > 0 ? val * (1 - pRed/100) : val;
                        item.impostos.vBC = Number(bc.toFixed(2));
                        item.impostos.vICMS = Number((bc * (Number(taxRule.icms_aliquot)/100)).toFixed(2));
                    }
                }
            });
            appStore.showSnackbar(`Regras tributárias importadas para ${uf}`, 'info');
        }
    } catch (e) { console.error('Erro ao buscar regra tributária', e); }
};

const handleClientSelection = async (client: any) => {
    if (!client) return;
    let indIEDest = '9';
    if (client.ie && client.ie.toUpperCase() === 'ISENTO') indIEDest = '2';
    else if (client.ie && client.ie.replace(/\D/g, '').length > 0) indIEDest = '1';
    const uf = client.estado || client.uf || 'SP';

    form.destinatario = {
        cnpj_cpf: client.cnpj || client.cpf || client.cpf_cnpj || '', nome: client.razao_social || client.nome || '', ie: client.ie || client.inscricao_estadual || '', im: client.im || '',
        indIEDest: indIEDest, email: client.email || '',
        endereco: { logradouro: client.endereco || client.rua || '', numero: client.numero || 'S/N', bairro: client.bairro || '', municipio: client.cidade || client.municipio || '', uf: uf, cep: client.cep || '', codigo_municipio: client.codigo_municipio || '' }
    };
    if (form.itens && form.itens.length > 0) await applyTaxRulesFromUF(uf);
};

const buscarDadosCnpj = async () => {
    const doc = form.destinatario.cnpj_cpf?.replace(/\D/g, '');
    if (!doc || doc.length !== 14) return appStore.showSnackbar('CNPJ inválido.', 'warning');
    loadingCnpj.value = true;
    try {
        const res = await axios.get(`https://brasilapi.com.br/api/cnpj/v1/${doc}`);
        const data = res.data;
        form.destinatario.nome = data.razao_social; form.destinatario.endereco.cep = data.cep; form.destinatario.endereco.logradouro = data.logradouro; form.destinatario.endereco.numero = data.numero; form.destinatario.endereco.complemento = data.complemento; form.destinatario.endereco.bairro = data.bairro; form.destinatario.endereco.municipio = data.municipio; form.destinatario.endereco.uf = data.uf; form.destinatario.endereco.codigo_municipio = data.codigo_municipio;
        appStore.showSnackbar('CNPJ importado com sucesso!', 'success');
        await applyTaxRulesFromUF(data.uf);
    } catch (e) { appStore.showSnackbar('Não foi possível buscar o CNPJ.', 'error'); } finally { loadingCnpj.value = false; }
};

const consultarSefazIE = async () => {
    const emitenteCnpj = activeCompany.value?.cnpj || companies.value[0]?.cnpj;
    const docDestino = form.destinatario.cnpj_cpf;
    const ufDestino = form.destinatario.endereco?.uf;
    if (!emitenteCnpj || !docDestino || !ufDestino) return appStore.showSnackbar('Dados incompletos para consultar Sefaz.', 'warning');
    loadingCCC.value = true;
    try {
        const docLimpo = docDestino.replace(/\D/g, '');
        const argumento = docLimpo.length > 11 ? 'CNPJ' : 'CPF';
        const response = await axios.get(`${SEFAZ_PROXY_URL}/api/consultar-ccc`, { params: { cnpj_emissor: emitenteCnpj, uf: ufDestino, argumento: argumento, documento: docLimpo } });
        const dados = response.data?.data;
        if (dados && dados.informacoes_cadastrais && dados.informacoes_cadastrais.length > 0) {
            const cadastroAtivo = dados.informacoes_cadastrais.find((c: any) => c.cSit === 1) || dados.informacoes_cadastrais[0];
            if (cadastroAtivo && cadastroAtivo.ie) { form.destinatario.ie = cadastroAtivo.ie; form.destinatario.indIEDest = '1'; appStore.showSnackbar(`IE localizada!`, 'success'); }
            else { form.destinatario.ie = ''; form.destinatario.indIEDest = '9'; appStore.showSnackbar('Não Contribuinte.', 'info'); }
        } else { form.destinatario.ie = ''; form.destinatario.indIEDest = '9'; appStore.showSnackbar('Não Contribuinte.', 'warning'); }
    } catch (e: any) { appStore.showSnackbar('Erro ao consultar a Sefaz.', 'error'); } finally { loadingCCC.value = false; }
};

const onItemSelect = (item: any) => {
    const p = item.descricao;
    if (p && typeof p === 'object') {
        item.descricao = `${p.fabric_type || ''} ${p.color || ''} ${p.composition || ''}`.trim();
        if(p.ncm) item.ncm = p.ncm;
        item.valor_unitario = 0; item._original_unit_price = 0;
    }
};

const addItem = () => {
    const newItem = getInitialItemState();
    if (form.itens.length > 0 && form.destinatario.endereco.uf) {
        const first = form.itens[0];
        newItem.cfop = first.cfop;
        if (newItem.impostos && first.impostos) {
            Object.assign(newItem.impostos, JSON.parse(JSON.stringify(first.impostos)));
            newItem.impostos.cst_csosn_modificado = true;
        }
    }
    form.itens.push(newItem);
};

const removeItem = (idx: number) => { if(confirm('Remover item?')) form.itens.splice(idx, 1); };

const addPaymentRow = () => {
    const nextNum = String(form.pagamentos.length + 1).padStart(3, '0');
    form.pagamentos.push({ nDup: nextNum, tPag: '01', indPag: '0', vPag: 0, dVenc: '', vTroco: 0, cAut: '', cnpjCredenciadora: '', tBand: '99', tpIntegra: '2' });
};

const openTaxModal = (idx: number) => {
    currentEditingItemIndex.value = idx;
    currentItemTax.value = JSON.parse(JSON.stringify(form.itens[idx].impostos || getInitialItemState().impostos));
    showTaxModal.value = true;
};

const saveTaxDetails = () => {
    const taxData = { ...currentItemTax.value, cst_csosn_modificado: true };
    if (applyTaxToAll.value) {
        form.itens.forEach((item: any) => { item.impostos = JSON.parse(JSON.stringify(taxData)); });
        appStore.showSnackbar('Tributação aplicada a TODOS os itens!', 'success');
    } else {
        if (currentEditingItemIndex.value > -1) form.itens[currentEditingItemIndex.value].impostos = taxData;
        appStore.showSnackbar('Tributação atualizada.', 'success');
    }
    showTaxModal.value = false;
};

const saveDraft = async () => {
    savingDraft.value = true;
    try {
        const cleanCNPJ = form.emitente.cnpj ? form.emitente.cnpj.replace(/\D/g, '') : '';
        const payload = { emitente_cnpj: cleanCNPJ, destinatario_nome: form.destinatario.nome || 'Rascunho', valor_total: totalFormValue.value, status: 'RASCUNHO', retorno_sefaz: { payload: JSON.parse(JSON.stringify(form)) } };
        if (isEditingDraft.value && props.draftId) await supabase.from('nfe_outbound').update(payload).eq('id', props.draftId);
        else await supabase.from('nfe_outbound').insert(payload);
        appStore.showSnackbar('Rascunho salvo!', 'success'); emit('draft-saved'); dialog.value = false;
    } catch(e) { appStore.showSnackbar('Erro ao salvar rascunho.', 'error'); } finally { savingDraft.value = false; }
};

const downloadDebugXml = () => {
    try {
        const xml = "";
        const blob = new Blob([xml], { type: 'application/xml' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `debug_previa_nfe_${nextNfeNumber.value || '1'}.xml`;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
        appStore.showSnackbar('XML gerado com sucesso! Cole o conteúdo para análise.', 'info');
    } catch (e: any) {
        appStore.showSnackbar('Erro ao gerar XML de debug: ' + e.message, 'error');
    }
};

const generatePreview = async () => {
    previewLoading.value = true;
    danfeModal.show = true;

    try {
        const company = activeCompany.value || companies.value[0];
        if (!company) throw new Error('Empresa não identificada.');

        const cleanCNPJ = form.emitente.cnpj.replace(/\D/g, '');
        const cleanIE = String(form.emitente.ie || 'ISENTO').toUpperCase() === 'ISENTO' ? 'ISENTO' : String(form.emitente.ie).replace(/\D/g, '');

        const payload = JSON.parse(JSON.stringify({
            ...form,
            ambiente: company.nfe_environment || 'homologacao',
            numero: nextNfeNumber.value,
            serie: company.nfe_series || 1
        }));

        if (payload.destinatario && payload.destinatario.email) {
            payload.destinatario.email = payload.destinatario.email.trim();
            if (!payload.destinatario.email.includes('.com') && !payload.destinatario.email.includes('.br')) {
                 delete payload.destinatario.email;
            }
        }

        const isAjusteOrDevolucao = payload.finNFe === 3 || payload.finNFe === 4;

        if (isAjusteOrDevolucao) {
            payload.pagamentos = [{ tPag: '90', indPag: '0', vPag: 0, dVenc: '', vTroco: 0, cAut: '', cnpjCredenciadora: '', tBand: '99', tpIntegra: '2' }];
        } else {
            if (!informarPagamento.value || !payload.pagamentos || payload.pagamentos.length === 0) {
                payload.pagamentos = [{ nDup: '001', tPag: '90', indPag: '0', vPag: 0, dVenc: '', vTroco: 0, cAut: '', cnpjCredenciadora: '', tBand: '99', tpIntegra: '2' }];
            }

            if (informarPagamento.value && payload.pagamentos) {
                let somaPagamentos = 0;
                payload.pagamentos.forEach((p: any) => {
                    p.vPag = Number(p.vPag || 0);
                    somaPagamentos += p.vPag;
                });

                const vNF = (totalFormValue.value - totalDesconto.value) + taxTotals.value.vST + taxTotals.value.vIPI + taxTotals.value.vFCPST;
                const diferencaPag = Number((vNF - somaPagamentos).toFixed(2));

                if (diferencaPag > 0.00) {
                    payload.pagamentos.push({
                        nDup: '',
                        tPag: '99',
                        indPag: '0',
                        vPag: diferencaPag,
                        dVenc: '',
                        vTroco: 0, cAut: '', cnpjCredenciadora: '', tBand: '99', tpIntegra: '2'
                    });
                }
            }
        }

        if (!isAjusteOrDevolucao && informarPagamento.value && payload.pagamentos && payload.pagamentos.length > 0) {
            const parcelasPrazo = payload.pagamentos.filter((p: any) => p.dVenc);
            if (parcelasPrazo.length > 0) {
                const vNF = (totalFormValue.value - totalDesconto.value) + taxTotals.value.vST + taxTotals.value.vIPI + taxTotals.value.vFCPST;
                payload.cobr = {
                    fat: {
                        nFat: String(payload.numero).padStart(3, '0'),
                        vOrig: Number(vNF.toFixed(2)),
                        vDesc: 0,
                        vLiq: Number(vNF.toFixed(2))
                    },
                    dup: parcelasPrazo.map((p: any) => ({
                        nDup: p.nDup || '001',
                        dVenc: p.dVenc,
                        vDup: Number(p.vPag || 0)
                    }))
                };
            }
        }

        // CORREÇÃO CRÍTICA DE NUMERAÇÃO DE CAMPOS E ENUMS ONDE O ZERO É VÁLIDO
        payload.tpNF = parseInt(String(payload.tpNF).charAt(0));
        payload.tpNF = isNaN(payload.tpNF) ? 1 : payload.tpNF;

        payload.finNFe = parseInt(String(payload.finNFe).charAt(0));
        payload.finNFe = isNaN(payload.finNFe) ? 1 : payload.finNFe;

        payload.indFinal = parseInt(String(payload.indFinal).charAt(0));
        payload.indFinal = isNaN(payload.indFinal) ? 1 : payload.indFinal;

        payload.indPres = parseInt(String(payload.indPres).charAt(0));
        payload.indPres = isNaN(payload.indPres) ? 1 : payload.indPres;

        payload.indIntermed = parseInt(String(payload.indIntermed).charAt(0));
        payload.indIntermed = isNaN(payload.indIntermed) ? 0 : payload.indIntermed;

        if (payload.transporte && payload.transporte.modFrete !== undefined) {
            const parsedFrete = parseInt(String(payload.transporte.modFrete).charAt(0));
            payload.transporte.modFrete = isNaN(parsedFrete) ? 9 : parsedFrete;
        }

        if (payload.destinatario && payload.destinatario.indIEDest !== undefined) {
            const parsedIEDest = parseInt(String(payload.destinatario.indIEDest).charAt(0));
            payload.destinatario.indIEDest = isNaN(parsedIEDest) ? 9 : parsedIEDest;
        }

        const response = await axios.post(`${SEFAZ_PROXY_URL}/api/previa-nfe`, {
            order: payload,
            cnpj_emitente: cleanCNPJ,
            ie_emitente: cleanIE,
            usuario: appStore.user?.name || appStore.user?.nome || 'Administrador'
        }, { responseType: 'blob' });

        const blob = new Blob([response.data], { type: 'application/pdf' });
        danfeModal.url = URL.createObjectURL(blob);

      } catch (e: any) {
        console.error(e);
        let errorMsg = e.response?.data?.error || e.message;
        if (e.response?.data?.details) {
            errorMsg += ' | Sefaz/Nuvem: ' + JSON.stringify(e.response.data.details);
        }
        appStore.showSnackbar('Erro na prévia: ' + errorMsg, 'error');
        danfeModal.show = false;
    } finally {
        previewLoading.value = false;
    }
};

const submitNfe = async (provider: 'nuvem' | 'sefaz' = 'nuvem') => {
    const company = activeCompany.value || companies.value[0];
    if (!company) return appStore.showSnackbar('Empresa não identificada.', 'error');

    issuing.value = true;
    issuingProvider.value = provider;
    emissionLogs.value = [];

    addLog('INICIO', `Iniciando processo de emissão via ${provider.toUpperCase()}`);

    const ambienteEmissao = provider === 'sefaz' ? 'homologacao' : (company.nfe_environment || 'homologacao');

    if (provider === 'sefaz') {
        addLog('SAFETY_CHECK', 'Modo Sefaz Direta detectado: Ambiente travado em HOMOLOGAÇÃO por segurança.', 'info');
    } else {
        addLog('SAFETY_CHECK', `Modo Nuvem Fiscal detectado: Usando configuração da empresa (${ambienteEmissao}).`, 'info');
    }

    const payload = JSON.parse(JSON.stringify({
        ...form,
        ambiente: ambienteEmissao,
        numero: nextNfeNumber.value,
        serie: company.nfe_series || 1
    }));

    // CORREÇÃO CRÍTICA DO PAGAMENTO 904 E 99
    const isAjusteOrDevolucao = payload.finNFe === 3 || payload.finNFe === 4;

    if (isAjusteOrDevolucao) {
        // Regra Inquebrável Sefaz
        payload.pagamentos = [{
            nDup: '', tPag: '90', indPag: '0', vPag: 0, dVenc: '', vTroco: 0, cAut: '', cnpjCredenciadora: '', tBand: '99', tpIntegra: '2'
        }];
    } else {
        // Regra de Venda (Integra o formulário e acha a diferença se tiver desativado/falso pagamento parcial)
        if (!informarPagamento.value || !payload.pagamentos || payload.pagamentos.length === 0) {
            payload.pagamentos = [{ nDup: '001', tPag: '90', indPag: '0', vPag: 0, dVenc: '', vTroco: 0, cAut: '', cnpjCredenciadora: '', tBand: '99', tpIntegra: '2' }];
        }

        if (informarPagamento.value && payload.pagamentos) {
            let somaPagamentos = 0;
            payload.pagamentos.forEach((p: any) => {
                p.vPag = Number(p.vPag || 0);
                somaPagamentos += p.vPag;
            });

            const vNF = (totalFormValue.value - totalDesconto.value) + taxTotals.value.vST + taxTotals.value.vIPI + taxTotals.value.vFCPST;
            const diferencaPag = Number((vNF - somaPagamentos).toFixed(2));

            // Empurra a diferença apenas se for Venda e informar pagamento estiver true (evita rejeição)
            if (diferencaPag > 0.00) {
                payload.pagamentos.push({
                    nDup: '',
                    tPag: '99',
                    indPag: '0',
                    vPag: diferencaPag,
                    dVenc: '',
                    vTroco: 0, cAut: '', cnpjCredenciadora: '', tBand: '99', tpIntegra: '2'
                });
            }
        }
    }

    if (!isAjusteOrDevolucao && informarPagamento.value && payload.pagamentos && payload.pagamentos.length > 0) {
        const parcelasPrazo = payload.pagamentos.filter((p: any) => p.dVenc);
        if (parcelasPrazo.length > 0) {
            const vNF = (totalFormValue.value - totalDesconto.value) + taxTotals.value.vST + taxTotals.value.vIPI + taxTotals.value.vFCPST;
            const sumDup = parcelasPrazo.reduce((acc: number, p: any) => acc + Number(p.vPag || 0), 0);
            const descFatura = vNF - sumDup > 0 ? vNF - sumDup : 0;

            payload.cobr = {
                fat: {
                    nFat: String(payload.numero).padStart(3, '0'),
                    vOrig: Number(vNF.toFixed(2)),
                    vDesc: Number(descFatura.toFixed(2)),
                    vLiq: Number(sumDup.toFixed(2))
                },
                dup: parcelasPrazo.map((p: any) => ({
                    nDup: p.nDup || '001',
                    dVenc: p.dVenc,
                    vDup: Number(p.vPag || 0)
                }))
            };
        }
    }

    // CORREÇÃO CRÍTICA DE ZEROS
    payload.tpNF = parseInt(String(payload.tpNF).charAt(0));
    payload.tpNF = isNaN(payload.tpNF) ? 1 : payload.tpNF;

    payload.finNFe = parseInt(String(payload.finNFe).charAt(0));
    payload.finNFe = isNaN(payload.finNFe) ? 1 : payload.finNFe;

    payload.indFinal = parseInt(String(payload.indFinal).charAt(0));
    payload.indFinal = isNaN(payload.indFinal) ? 1 : payload.indFinal;

    payload.indPres = parseInt(String(payload.indPres).charAt(0));
    payload.indPres = isNaN(payload.indPres) ? 1 : payload.indPres;

    payload.indIntermed = parseInt(String(payload.indIntermed).charAt(0));
    payload.indIntermed = isNaN(payload.indIntermed) ? 0 : payload.indIntermed;

    if (payload.transporte && payload.transporte.modFrete !== undefined) {
        const parsedFrete = parseInt(String(payload.transporte.modFrete).charAt(0));
        payload.transporte.modFrete = isNaN(parsedFrete) ? 9 : parsedFrete;
    }

    if (payload.destinatario && payload.destinatario.indIEDest !== undefined) {
        const parsedIEDest = parseInt(String(payload.destinatario.indIEDest).charAt(0));
        payload.destinatario.indIEDest = isNaN(parsedIEDest) ? 9 : parsedIEDest;
    }

    payload.itens.forEach((item: any) => {
        if (item.impostos) {
            if (item.impostos.modBC !== undefined) {
                const parsedBC = parseInt(String(item.impostos.modBC).charAt(0));
                item.impostos.modBC = isNaN(parsedBC) ? 3 : parsedBC;
            }
            if (item.impostos.modBCST !== undefined) {
                const parsedBCST = parseInt(String(item.impostos.modBCST).charAt(0));
                item.impostos.modBCST = isNaN(parsedBCST) ? 4 : parsedBCST;
            }
            if (item.impostos.origem !== undefined) {
                const parsedOrigem = parseInt(String(item.impostos.origem).charAt(0));
                item.impostos.origem = isNaN(parsedOrigem) ? 0 : parsedOrigem;
            }
        }
    });

    try {
        const cleanIE = String(payload.emitente.ie || 'ISENTO').toUpperCase() === 'ISENTO' ? 'ISENTO' : String(payload.emitente.ie).replace(/\D/g, '');
        const cleanCNPJ = payload.emitente.cnpj.replace(/\D/g, '');

        addLog('API_CALL', `Disparando para o proxy... [Provider: ${provider}]`);

        // Chamada à API
        const res = await sefazService.emitirNFe(payload, cleanCNPJ, cleanIE, provider);

        addLog('API_RESPONSE', `Retorno recebido do proxy.`, 'success', res);

        const statusSefaz = res.status ? res.status.toLowerCase() : '';
        const cStat = res.data?.parsed?.cStat || res.cStat;

        const isAuthorized = (provider === 'nuvem')
            ? (statusSefaz === 'autorizado' || statusSefaz === 'autorizada' || statusSefaz === 'success')
            : (statusSefaz === 'success' || cStat === '100' || cStat === 100);

        if (!isAuthorized) {
            throw { message: `Status retornado: ${res.status}. Motivo: ${res.motivo_status || res.data?.parsed?.xMotivo || 'Desconhecido'}`, details: res };
        }

        addLog('SUCESSO', 'Nota autorizada e assinada com sucesso!', 'success');

        const dbData = { status: 'AUTORIZADA', chave: res.chave, numero: res.numero, xml_link: res.xml_url, pdf_link: res.pdf_url, retorno_sefaz: { ...res, payload, provider_used: provider } };
        if (isEditingDraft.value && props.draftId) await supabase.from('nfe_outbound').update(dbData).eq('id', props.draftId);
        else await supabase.from('nfe_outbound').insert({ ...dbData, emitente_cnpj: cleanCNPJ, destinatario_nome: payload.destinatario.nome, valor_total: totalFormValue.value });
        await supabase.from('companies').update({ nfe_next_number: res.numero + 1 }).eq('id', company.id);

        if (props.orderId) {
            await supabase.from('orders').update({ nfe_number: String(res.numero), nfe_key: res.chave, financial_status: 'Faturado' }).eq('id', props.orderId);
            await supabase.from('store_sales').update({ nfe_number: String(res.numero), nfe_key: res.chave, financial_status: 'Faturado' }).eq('id', props.orderId);
        }

        appStore.showSnackbar(`Nota ${res.numero} autorizada via ${provider.toUpperCase()}!`, 'success');
        emit('success');
        dialog.value = false;
    } catch (e: any) {
        const errorDetails = e.response?.data || e.details || e;
        addLog('ERRO_CRITICO', e.message || 'Falha na emissão', 'error', errorDetails);

        errorDialog.friendlyMessage = translateSefazError(errorDetails);
        errorDialog.rawDetails = errorDetails;
        errorDialog.show = true;

        if (isEditingDraft.value && props.draftId) {
            await supabase.from('nfe_outbound').update({ status: 'REJEITADA', retorno_sefaz: { error: errorDetails, payload, provider_used: provider } }).eq('id', props.draftId);
            emit('success');
        }
    } finally {
        issuing.value = false;
        issuingProvider.value = null;
    }
};

const zebraClass = (i: number) => themeStore.currentMode !== 'light' ? (i % 2 === 0 ? 'zebra-dark-a' : 'zebra-dark-b') : (i % 2 === 0 ? 'zebra-light-a' : 'zebra-light-b');
</script>

<style scoped lang="scss">
.receivables-layout { position: relative; }
.bg-glass-dark { background: rgba(10,10,12,0.85); }
.bg-glass-header { background: rgba(20,20,24,0.55); backdrop-filter: blur(14px); }
.border-bottom-white-05 { border-bottom: 1px solid rgba(255,255,255,0.08) !important; }
.border-white-10 { border: 1px solid rgba(255,255,255,0.1) !important; }
.bg-white-05 { background: rgba(255,255,255,0.05); }
.bg-black-90 { background: rgba(0,0,0,0.9); }
.bg-black-80 { background: rgba(0,0,0,0.8); }
.bg-black-40 { background: rgba(0,0,0,0.4); }
.bg-black-20 { background: rgba(0,0,0,0.2) !important; }
.text-white-70 { color: rgba(255,255,255,0.7) !important; }
.backdrop-blur-sm { backdrop-filter: blur(4px); }
.text-shadow-sm { text-shadow: 0 2px 4px rgba(0,0,0,0.2); }

.background-carousel-wrapper { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 0; opacity: 0.6; pointer-events: none; }
.background-overlay { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 1; background: radial-gradient(circle at center, rgba(15, 15, 19, 0.4), rgba(15, 15, 19, 0.98)); backdrop-filter: blur(8px); }

.fixed-dialog { overflow: hidden !important; }
.ui-field :deep(.v-field) { border-radius: 6px !important; }
.row-gap { row-gap: 16px; margin-top: 4px; }
.input-label { display: block; font-size: 11px; font-weight: 800; text-transform: uppercase; color: #757575; margin-bottom: 6px; letter-spacing: 0.5px; }

/* Grid e Scroll */
.custom-scroll::-webkit-scrollbar { width: 8px; height: 8px; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.35); border-radius: 6px; }
.custom-scroll::-webkit-scrollbar-track { background: transparent; }

.grid-header, .grid-row { display: grid; align-items: stretch; width: 100%; }
.cell { padding: 6px 8px; display: flex; align-items: center; border-right: 1px solid rgba(0,0,0,0.08); border-bottom: 1px solid rgba(0,0,0,0.08); min-height: 48px; overflow: hidden; transition: background-color 0.2s ease; }
.header-text { font-weight: 800; text-transform: uppercase; letter-spacing: 0.5px; line-height: 1.2; font-size: 11px !important; opacity: 0.8; }
.center { justify-content: center; text-align: center; }

.grid-surface-light .cell { background: #f0f2f5; color: rgba(0,0,0,0.9); border-color: rgba(0,0,0,0.08) !important; }
.grid-row-light .cell { border-color: rgba(0,0,0,0.05) !important; }
.zebra-light-a .cell { background: #ffffff; }
.zebra-light-b .cell { background: #f8f9fa; }
.grid-row-light:hover .cell { background: #e3f2fd !important; }

.grid-surface-dark .cell { background: rgba(255,255,255,0.08) !important; color: rgba(255,255,255,0.80) !important; border-color: rgba(255,255,255,0.10) !important; }
.grid-row-dark .cell { background: rgba(255,255,255,0.04); border-color: rgba(255,255,255,0.08) !important; color: rgba(255,255,255,0.85); }
.zebra-dark-a .cell { background: rgba(255,255,255,0.04) !important; }
.zebra-dark-b .cell { background: rgba(255,255,255,0.015) !important; }
.grid-row-dark:hover .cell { background: rgba(255,255,255,0.07) !important; }

.clean-input { border: none; outline: none; font-size: 13px; width: 100%; font-family: monospace; background: transparent; color: inherit; }
.clean-input-combo :deep(.v-field__outline) { display: none !important; }
.clean-input-combo :deep(.v-field__input) { padding-left: 0 !important; padding-right: 0 !important; }

.btn-3d { border-radius: 6px !important; box-shadow: 0 3px 5px rgba(0,0,0,0.15), inset 0 2px 0 rgba(255,255,255,0.25) !important; transition: transform 0.1s ease, box-shadow 0.1s ease; text-transform: none !important; }
.btn-3d:active { transform: translateY(2px); box-shadow: 0 1px 2px rgba(0,0,0,0.15), inset 0 1px 0 rgba(255,255,255,0.2) !important; }
.glass-card { background: rgba(255,255,255,0.03); backdrop-filter: blur(10px); }

.rounded-2px { border-radius: 2px !important; }
.pdf-iframe { width: 100%; height: 100%; border: none; background: white; }
.lh-1 { line-height: 1.2; }
.shadow-md { box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06); }
.shadow-xl { box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04); }
.border-dashed { border-style: dashed !important; border-color: rgba(0,0,0,0.12) !important; }

/* Adicionado para garantir o Dark Mode nos Dialogs */
.v-dialog > .v-overlay__content > .v-card {
    transition: background-color 0.3s ease, color 0.3s ease;
}
</style>
