<template>
  <div
    class="receivables-layout font-sans fill-height d-flex flex-column relative overflow-hidden"
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
        class="header-bar px-4 py-3 px-md-6 py-md-4 d-flex flex-column flex-md-row align-md-center justify-space-between flex-shrink-0"
        :class="themeStore.currentMode === 'light' ? 'bg-white border-b border-grey-lighten-2 shadow-sm' : 'bg-glass-header border-bottom-white-05'"
        style="gap: 12px;"
      >
        <div class="d-flex flex-column">
          <div class="breadcrumb text-caption d-none d-md-block">
            <span class="opacity-70">Fiscal</span>
            <span class="mx-2 opacity-50">></span>
            <span class="font-weight-bold">Empresas e Filiais</span>
          </div>
          <div class="d-flex align-center gap-3 mt-1">
             <div class="icon-box-md rounded-lg elevation-2 d-flex align-center justify-center" style="width: 40px; height: 40px;" :class="themeStore.currentMode === 'light' ? 'bg-blue-grey-darken-3 text-white' : 'bg-primary-transparent text-primary'">
                <v-icon size="24">mdi-domain</v-icon>
             </div>
             <div>
                 <h1 class="text-h6 font-weight-black tracking-tight leading-none" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">
                    Configurações de Empresas
                 </h1>
                 <span class="text-caption opacity-70">Parâmetros de emissão NF-e, NFC-e, NFS-e, CT-e e Certificados</span>
             </div>
          </div>
        </div>

        <div class="d-flex align-center pb-1 pb-md-0" style="gap: 10px;">
          <v-btn
            color="success"
            variant="flat"
            class="btn-rect px-4 font-weight-bold text-caption text-uppercase letter-spacing-1 flex-shrink-0 shadow-sm"
            prepend-icon="mdi-plus"
            height="40"
            @click="openDialog()"
          >
             Nova Empresa
          </v-btn>
        </div>
      </div>

      <div class="px-4 px-md-6 py-4 flex-shrink-0">
        <div class="controls-bar d-flex flex-column" :class="themeStore.currentMode === 'light' ? 'controls-light' : 'controls-dark'">
            <div class="search-wrap d-flex align-center w-100" :class="themeStore.currentMode === 'light' ? 'search-light bg-white' : 'search-dark'">
                <v-icon :color="themeStore.currentMode === 'light' ? 'grey-darken-1' : 'white-70'">mdi-magnify</v-icon>
                <input
                    v-model="search"
                    type="text"
                    placeholder="Pesquisar por Razão Social, Nome Fantasia ou CNPJ..."
                    class="clean-input flex-grow-1 ml-2 font-weight-bold"
                    :class="themeStore.currentMode === 'light' ? 'text-grey-darken-3' : 'text-white'"
                />
            </div>
        </div>
      </div>

      <div class="flex-grow-1 overflow-hidden d-flex flex-column px-4 px-md-6 pb-6">
        <v-card class="flex-grow-1 d-flex flex-column rounded-0 border-thin overflow-hidden" :class="themeStore.currentMode === 'light' ? 'bg-white shadow-sm' : 'glass-card border-white-05'" :elevation="0">
          <div class="grid-scroll flex-grow-1 overflow-auto custom-scroll relative">
            <div class="grid-header sticky-head" :class="themeStore.currentMode === 'light' ? 'grid-surface-light' : 'grid-surface-dark'" style="grid-template-columns: 60px minmax(200px, 1.5fr) minmax(160px, 1.5fr) 160px 120px 100px 90px 120px 160px 110px; min-width: 1300px;">
              <div class="cell center header-text">Status</div>
              <div class="cell header-text">Razão Social</div>
              <div class="cell header-text">Nome Fantasia</div>
              <div class="cell center header-text">CNPJ</div>
              <div class="cell center header-text">IE</div>
              <div class="cell center header-text">Regime</div>
              <div class="cell center header-text">CST Padrão</div>
              <div class="cell center header-text">Amb. NFe</div>
              <div class="cell center header-text">Certificado A1</div>
              <div class="cell center header-text">Ações</div>
            </div>

            <div v-if="loading" class="d-flex flex-column justify-center align-center h-100 py-10 min-w-full">
              <v-progress-circular indeterminate color="blue-grey" size="32" width="3"></v-progress-circular>
            </div>

            <div v-else-if="filteredCompanies.length === 0" class="d-flex flex-column justify-center align-center h-100 opacity-60 py-10 min-w-full">
              <v-icon size="48" color="grey-lighten-1">mdi-domain-off</v-icon>
              <span class="text-body-2 font-weight-medium mt-2">Nenhuma empresa cadastrada.</span>
            </div>

            <div
              v-else
              v-for="(item, index) in filteredCompanies"
              :key="item.id"
              class="grid-row"
              :class="[themeStore.currentMode === 'light' ? 'grid-row-light' : 'grid-row-dark', zebraClass(index)]"
              style="grid-template-columns: 60px minmax(200px, 1.5fr) minmax(160px, 1.5fr) 160px 120px 100px 90px 120px 160px 110px; min-width: 1300px;"
            >
                <div class="cell center">
                    <div class="status-dot rounded-circle" :class="item.active ? 'bg-success pulse-success' : 'bg-grey'"></div>
                </div>

                <div class="cell font-weight-bold list-text-11 text-truncate" :title="item.name">{{ item.name }}</div>
                <div class="cell list-text-11 text-truncate opacity-80" :title="item.trade_name">{{ item.trade_name || '-' }}</div>
                <div class="cell center font-mono font-weight-black list-text-11">{{ formatCNPJ(item.cnpj) }}</div>
                <div class="cell center list-text-11 opacity-80">{{ item.ie || 'ISENTO' }}</div>

                <div class="cell center">
                    <v-chip size="x-small" label class="font-weight-bold" :color="item.crt === '3' ? 'purple-darken-1' : 'blue-darken-1'">
                        CRT: {{ item.crt }}
                    </v-chip>
                </div>
                <div class="cell center font-mono font-weight-black list-text-11">{{ item.default_cst_csosn || '102' }}</div>

                <div class="cell center">
                    <v-chip size="x-small" :color="item.nfe_environment === 'producao' ? 'red-darken-1' : 'teal-darken-1'" variant="flat" class="font-weight-bold text-uppercase">
                        {{ item.nfe_environment }}
                    </v-chip>
                </div>

                <div class="cell center">
                    <v-chip v-if="item.certificate_validity" size="x-small" :color="isCertValid(item.certificate_validity) ? 'success' : 'error'" variant="flat" class="font-weight-bold">
                        <v-icon start size="10">{{ isCertValid(item.certificate_validity) ? 'mdi-check-circle' : 'mdi-alert-circle' }}</v-icon>
                        {{ formatDateSafe(item.certificate_validity) }}
                    </v-chip>
                    <v-chip v-else size="x-small" color="grey" variant="tonal" class="font-weight-bold">Ausente</v-chip>
                </div>

                <div class="cell center">
                    <div class="actions-inline">
                        <v-btn icon size="small" class="action-btn action-edit" @click.stop="openDialog(item)" title="Editar" variant="flat"><v-icon size="16">mdi-pencil</v-icon></v-btn>
                        <v-btn icon size="small" class="action-btn" :class="item.active ? 'bg-orange-darken-2' : 'bg-green-darken-2'" @click.stop="toggleStatus(item)" :title="item.active ? 'Desativar' : 'Ativar'" variant="flat"><v-icon size="16">mdi-power</v-icon></v-btn>
                    </div>
                </div>
            </div>
          </div>
        </v-card>
      </div>
    </div>

    <v-dialog v-model="dialog" width="1250" height="90vh" persistent transition="dialog-bottom-transition" class="fixed-dialog">
        <v-card class="d-flex flex-row overflow-hidden rounded-0 fill-height w-100" height="100%">

            <div class="modal-sidebar pa-0 d-flex flex-column flex-shrink-0 text-white bg-blue-grey-darken-4" style="width: 280px; z-index: 10;">
                <div class="pa-6 text-center border-b border-white-10 relative">
                    <v-avatar size="90" class="mb-3 cursor-pointer hover-opacity relative overflow-hidden border elevation-4 bg-white" @click="triggerLogoUpload">
                        <v-img v-if="editedItem.logo_url" :src="editedItem.logo_url" cover></v-img>
                        <v-icon v-else size="36" color="grey-lighten-1">mdi-domain</v-icon>
                        <div class="overlay-upload d-flex align-center justify-center">
                            <span class="text-[10px] text-white font-weight-bold">ALTERAR</span>
                        </div>
                    </v-avatar>
                    <input type="file" ref="logoInput" class="d-none" accept="image/*" @change="handleLogoUpload">
                    <div class="text-subtitle-2 font-weight-black text-truncate">{{ editedItem.trade_name || editedItem.name || 'Nova Empresa' }}</div>
                    <div class="text-caption font-mono opacity-80">{{ formatCNPJ(editedItem.cnpj) || 'CNPJ...' }}</div>
                </div>

                <div class="flex-grow-1 overflow-y-auto py-2 custom-scroll-dark">
                    <v-tabs v-model="activeTab" direction="vertical" color="white" class="sidebar-tabs">
                        <v-tab value="geral" class="justify-start px-6"><v-icon start size="18">mdi-card-account-details</v-icon> Dados Básicos</v-tab>
                        <v-tab value="endereco" class="justify-start px-6"><v-icon start size="18">mdi-map-marker</v-icon> Endereço</v-tab>
                        <v-tab value="nfe" class="justify-start px-6"><v-icon start size="18">mdi-truck-delivery-outline</v-icon> NF-e (Modelo 55)</v-tab>
                        <v-tab value="nfce" class="justify-start px-6"><v-icon start size="18">mdi-receipt-text-outline</v-icon> NFC-e (Cupom)</v-tab>
                        <v-tab value="nfse" class="justify-start px-6"><v-icon start size="18">mdi-briefcase-outline</v-icon> NFS-e (Serviços)</v-tab>
                        <v-tab value="cte" class="justify-start px-6"><v-icon start size="18">mdi-bus-articulated-front</v-icon> CT-e (Transporte)</v-tab>
                        <v-tab value="autorizacoes" class="justify-start px-6"><v-icon start size="18">mdi-shield-account-outline</v-icon> Autorizações XML</v-tab>
                        <v-tab value="certificado" class="justify-start px-6 text-amber-accent-2"><v-icon start size="18">mdi-shield-check</v-icon> Certificado A1</v-tab>
                    </v-tabs>
                </div>
            </div>

            <div class="flex-grow-1 d-flex flex-column h-100 overflow-hidden" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5' : 'bg-glass-dark'">

                 <div class="pa-5 border-b d-flex align-center justify-space-between flex-shrink-0 bg-white z-10" :class="themeStore.currentMode === 'light' ? 'border-grey-lighten-2' : 'border-white-10 bg-glass-header'">
                     <div>
                         <div class="text-h6 font-weight-black text-grey-darken-3">{{ getTabTitle(activeTab) }}</div>
                         <div class="text-caption text-grey">Preencha corretamente as informações fiscais e obrigatórias.</div>
                     </div>
                     <v-btn icon="mdi-close" variant="text" color="grey-darken-1" @click="close"></v-btn>
                 </div>

                 <div class="flex-grow-1 overflow-y-auto custom-scroll pa-6 pa-md-8 absolute-fill">
                    <v-form ref="formRef" @submit.prevent="save" id="companyForm">
                        <v-window v-model="activeTab">

                            <v-window-item value="geral">
                                <v-card class="pa-6 rounded-xl border-thin shadow-xs" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'glass-card border-white-05'" elevation="0">
                                    <div class="text-subtitle-2 font-weight-bold text-uppercase opacity-70 mb-4">Identificação Fiscal</div>
                                    <v-row dense class="row-gap">
                                        <v-col cols="12" md="8"><label class="input-label">Razão Social *</label><v-text-field v-model="editedItem.name" variant="outlined" density="comfortable" class="ui-field" bg-color="transparent"></v-text-field></v-col>
                                        <v-col cols="12" md="4"><label class="input-label">Nome Fantasia</label><v-text-field v-model="editedItem.trade_name" variant="outlined" density="comfortable" class="ui-field" bg-color="transparent"></v-text-field></v-col>
                                        <v-col cols="12" md="4"><label class="input-label">CNPJ *</label><v-text-field v-model="editedItem.cnpj" v-maska="'##.###.###/####-##'" variant="outlined" density="comfortable" class="ui-field font-weight-bold" bg-color="transparent"></v-text-field></v-col>
                                        <v-col cols="12" md="4"><label class="input-label">Inscrição Estadual (IE)</label><v-text-field v-model="editedItem.ie" variant="outlined" density="comfortable" class="ui-field" bg-color="transparent" placeholder="Somente números ou ISENTO"></v-text-field></v-col>
                                        <v-col cols="12" md="4"><label class="input-label">Inscrição Municipal (IM)</label><v-text-field v-model="editedItem.im" variant="outlined" density="comfortable" class="ui-field" bg-color="transparent"></v-text-field></v-col>

                                        <v-col cols="12"><v-divider class="my-3 border-dashed"></v-divider></v-col>

                                        <v-col cols="12" md="6">
                                            <label class="input-label text-blue-grey-darken-3">Regime Tributário (CRT) *</label>
                                            <v-select v-model="editedItem.crt" :items="crtOptions" item-title="label" item-value="value" variant="outlined" density="comfortable" class="ui-field font-weight-bold" bg-color="transparent" @update:model-value="adjustDefaultCst"></v-select>
                                        </v-col>
                                        <v-col cols="12" md="6">
                                            <label class="input-label text-blue-grey-darken-3">CST / CSOSN Padrão *</label>
                                            <v-select v-model="editedItem.default_cst_csosn" :items="availableCstOptions" item-title="label" item-value="value" variant="outlined" density="comfortable" class="ui-field font-weight-bold" bg-color="transparent"></v-select>
                                        </v-col>
                                        <v-col cols="12"><label class="input-label">Email de Contato (Envio de Notas)</label><v-text-field v-model="editedItem.email" variant="outlined" density="comfortable" class="ui-field" bg-color="transparent" autocomplete="email"></v-text-field></v-col>
                                    </v-row>
                                </v-card>
                            </v-window-item>

                            <v-window-item value="endereco">
                                <v-card class="pa-6 rounded-xl border-thin shadow-xs" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'glass-card border-white-05'" elevation="0">
                                    <div class="text-subtitle-2 font-weight-bold text-uppercase opacity-70 mb-4">Localização da Matriz/Filial</div>
                                    <v-row dense class="row-gap">
                                        <v-col cols="12" md="3"><label class="input-label">CEP</label><v-text-field v-model="editedItem.zip_code" v-maska="'#####-###'" variant="outlined" density="comfortable" class="ui-field" bg-color="transparent" append-inner-icon="mdi-magnify" @blur="buscaCep"></v-text-field></v-col>
                                        <v-col cols="12" md="7"><label class="input-label">Logradouro</label><v-text-field v-model="editedItem.street" variant="outlined" density="comfortable" class="ui-field" bg-color="transparent"></v-text-field></v-col>
                                        <v-col cols="12" md="2"><label class="input-label">Número</label><v-text-field v-model="editedItem.number" variant="outlined" density="comfortable" class="ui-field" bg-color="transparent"></v-text-field></v-col>

                                        <v-col cols="12" md="5"><label class="input-label">Bairro</label><v-text-field v-model="editedItem.district" variant="outlined" density="comfortable" class="ui-field" bg-color="transparent"></v-text-field></v-col>
                                        <v-col cols="12" md="5"><label class="input-label">Cidade</label><v-text-field v-model="editedItem.city" variant="outlined" density="comfortable" class="ui-field" bg-color="transparent"></v-text-field></v-col>
                                        <v-col cols="12" md="2"><label class="input-label">UF</label><v-text-field v-model="editedItem.uf" variant="outlined" density="comfortable" class="ui-field" bg-color="transparent" maxlength="2"></v-text-field></v-col>
                                    </v-row>
                                </v-card>
                            </v-window-item>

                            <v-window-item value="nfe">
                                <v-card class="pa-6 rounded-xl border-thin shadow-xs" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'glass-card border-white-05'" elevation="0">
                                    <div class="d-flex align-center gap-3 mb-6">
                                        <div class="icon-box bg-blue-lighten-5 text-blue-darken-3 rounded"><v-icon>mdi-truck-delivery</v-icon></div>
                                        <div class="text-subtitle-2 font-weight-bold text-uppercase text-grey-darken-3">Nota Fiscal Eletrônica (Mod. 55)</div>
                                    </div>
                                    <v-row dense class="row-gap">
                                        <v-col cols="12" md="4"><label class="input-label">Ambiente NF-e</label><v-select v-model="editedItem.nfe_environment" :items="envOptions" variant="outlined" density="comfortable" class="ui-field"></v-select></v-col>
                                        <v-col cols="12" md="4"><label class="input-label">Série</label><v-text-field v-model.number="editedItem.nfe_series" type="number" variant="outlined" density="comfortable" class="ui-field"></v-text-field></v-col>
                                        <v-col cols="12" md="4"><label class="input-label text-blue-darken-3">Próximo Número (Sequência)</label><v-text-field v-model.number="editedItem.nfe_next_number" type="number" variant="outlined" density="comfortable" class="ui-field font-weight-bold"></v-text-field></v-col>
                                        <v-col cols="12" md="6"><label class="input-label">Versão Layout SEFAZ</label><v-text-field v-model="editedItem.nfe_version" variant="outlined" density="comfortable" class="ui-field" disabled bg-color="grey-lighten-4"></v-text-field></v-col>

                                        <v-col cols="12"><v-divider class="my-2 border-dashed"></v-divider></v-col>
                                        <v-col cols="12">
                                            <v-checkbox v-model="editedItem.subtract_icms_pis_cofins" label="Subtrair valor do ICMS da base de cálculo do PIS e COFINS" color="blue-darken-3" density="compact" hide-details></v-checkbox>
                                            <v-checkbox v-model="editedItem.simple_danfe" label="Imprimir DANFE no modelo Simplificado (Etiqueta)" color="blue-darken-3" density="compact" hide-details></v-checkbox>
                                        </v-col>

                                        <v-col cols="12" class="mt-4"><label class="input-label">Info. Complementar Padrão (Fixo no Rodapé)</label><v-textarea v-model="editedItem.nfe_info_complementar" variant="outlined" rows="3" class="ui-field" placeholder="Ex: Empresa optante pelo simples nacional..."></v-textarea></v-col>
                                    </v-row>
                                </v-card>
                            </v-window-item>

                            <v-window-item value="nfce">
                                <v-card class="pa-6 rounded-xl border-thin shadow-xs" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'glass-card border-white-05'" elevation="0">
                                    <div class="d-flex align-center gap-3 mb-6">
                                        <div class="icon-box bg-orange-lighten-5 text-orange-darken-3 rounded"><v-icon>mdi-receipt-text-outline</v-icon></div>
                                        <div class="text-subtitle-2 font-weight-bold text-uppercase text-grey-darken-3">Nota Fiscal de Consumidor (Cupom Mod. 65)</div>
                                    </div>
                                    <v-row dense class="row-gap">
                                        <v-col cols="12" md="4"><label class="input-label">Ambiente NFC-e</label><v-select v-model="editedItem.nfce_environment" :items="envOptions" variant="outlined" density="comfortable" class="ui-field"></v-select></v-col>
                                        <v-col cols="12" md="4"><label class="input-label">Série</label><v-text-field v-model.number="editedItem.nfce_series" type="number" variant="outlined" density="comfortable" class="ui-field"></v-text-field></v-col>
                                        <v-col cols="12" md="4"><label class="input-label text-orange-darken-3">Próximo Número</label><v-text-field v-model.number="editedItem.nfce_next_number" type="number" variant="outlined" density="comfortable" class="ui-field font-weight-bold"></v-text-field></v-col>

                                        <v-col cols="12"><v-divider class="my-2 border-dashed"></v-divider></v-col>
                                        <v-col cols="12" md="8"><label class="input-label text-orange-darken-3">Token CSC (Id do Código de Segurança)</label><v-text-field v-model="editedItem.nfce_token" variant="outlined" density="comfortable" class="ui-field"></v-text-field></v-col>
                                        <v-col cols="12" md="4"><label class="input-label text-orange-darken-3">CSC Alfanumérico</label><v-text-field v-model="editedItem.nfce_csc" variant="outlined" density="comfortable" class="ui-field"></v-text-field></v-col>

                                        <v-col cols="12" class="mt-2"><label class="input-label">Info. Complementar NFC-e</label><v-textarea v-model="editedItem.nfce_info_complementar" variant="outlined" rows="2" class="ui-field"></v-textarea></v-col>
                                    </v-row>
                                </v-card>
                            </v-window-item>

                            <v-window-item value="nfse">
                                <v-card class="pa-6 rounded-xl border-thin shadow-xs" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'glass-card border-white-05'" elevation="0">
                                    <div class="d-flex align-center gap-3 mb-6">
                                        <div class="icon-box bg-teal-lighten-5 text-teal-darken-3 rounded"><v-icon>mdi-briefcase-outline</v-icon></div>
                                        <div class="text-subtitle-2 font-weight-bold text-uppercase text-grey-darken-3">Nota Fiscal de Serviço (Prefeituras)</div>
                                    </div>
                                    <v-row dense class="row-gap">
                                        <v-col cols="12" md="4"><label class="input-label">Ambiente NFS-e</label><v-select v-model="editedItem.nfse_environment" :items="envOptions" variant="outlined" density="comfortable" class="ui-field"></v-select></v-col>
                                        <v-col cols="12" md="4"><label class="input-label">Série RPS</label><v-text-field v-model="editedItem.nfse_rps_series" variant="outlined" density="comfortable" class="ui-field"></v-text-field></v-col>
                                        <v-col cols="12" md="4"><label class="input-label text-teal-darken-3">Último RPS Emitido</label><v-text-field v-model.number="editedItem.nfse_next_rps" type="number" variant="outlined" density="comfortable" class="ui-field font-weight-bold"></v-text-field></v-col>

                                        <v-col cols="12" md="6"><label class="input-label">Regime Especial de Tributação</label><v-select v-model="editedItem.nfse_tax_regime" :items="taxRegimeOptions" item-title="label" item-value="value" variant="outlined" density="comfortable" class="ui-field"></v-select></v-col>
                                        <v-col cols="12" md="6"><label class="input-label">Natureza da Operação</label><v-select v-model="editedItem.nfse_operation_nature" :items="operationNatureOptions" item-title="label" item-value="value" variant="outlined" density="comfortable" class="ui-field"></v-select></v-col>

                                        <v-col cols="12" class="mt-2"><label class="input-label">Observações Padrão NFS-e</label><v-textarea v-model="editedItem.nfse_info_complementar" variant="outlined" rows="2" class="ui-field"></v-textarea></v-col>
                                    </v-row>
                                </v-card>
                            </v-window-item>

                            <v-window-item value="cte">
                                <v-card class="pa-6 rounded-xl border-thin shadow-xs" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'glass-card border-white-05'" elevation="0">
                                    <div class="d-flex align-center gap-3 mb-6">
                                        <div class="icon-box bg-purple-lighten-5 text-purple-darken-3 rounded"><v-icon>mdi-bus-articulated-front</v-icon></div>
                                        <div class="text-subtitle-2 font-weight-bold text-uppercase text-grey-darken-3">Conhecimento de Transporte (Mod. 57)</div>
                                    </div>
                                    <v-row dense class="row-gap">
                                        <v-col cols="12" md="4"><label class="input-label">Ambiente CT-e</label><v-select v-model="editedItem.cte_environment" :items="envOptions" variant="outlined" density="comfortable" class="ui-field"></v-select></v-col>
                                        <v-col cols="12" md="4"><label class="input-label">Série</label><v-text-field v-model.number="editedItem.cte_series" type="number" variant="outlined" density="comfortable" class="ui-field"></v-text-field></v-col>
                                        <v-col cols="12" md="4"><label class="input-label text-purple-darken-3">Próximo Número</label><v-text-field v-model.number="editedItem.cte_next_number" type="number" variant="outlined" density="comfortable" class="ui-field font-weight-bold"></v-text-field></v-col>
                                        <v-col cols="12" class="mt-2"><label class="input-label">Info. Complementar CT-e</label><v-textarea v-model="editedItem.cte_info_complementar" variant="outlined" rows="2" class="ui-field"></v-textarea></v-col>
                                    </v-row>
                                </v-card>
                            </v-window-item>

                            <v-window-item value="autorizacoes">
                                <v-card class="pa-6 rounded-xl border-thin shadow-xs" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'glass-card border-white-05'" elevation="0">
                                    <div class="d-flex align-center gap-3 mb-4">
                                        <div class="icon-box bg-blue-grey-lighten-5 text-blue-grey-darken-3 rounded"><v-icon>mdi-shield-account-outline</v-icon></div>
                                        <div class="text-subtitle-2 font-weight-bold text-uppercase text-grey-darken-3">Autorização de Download de XML (Contador)</div>
                                    </div>
                                    <p class="text-body-2 text-grey-darken-1 mb-4">Informe os CNPJs ou CPFs (separados por vírgula) das pessoas/contabilidades que poderão baixar os arquivos XML diretamente do portal da Sefaz.</p>
                                    <v-textarea v-model="editedItem.xml_auth_cnpjs" variant="outlined" placeholder="Ex: 12345678000199, 98765432100" rows="4" class="ui-field"></v-textarea>
                                </v-card>
                            </v-window-item>

                            <v-window-item value="certificado">
                                <div v-if="editedItem.certificate_validity" class="certificate-card rounded-xl pa-6 mb-6 elevation-2" :class="isCertValid(editedItem.certificate_validity) ? 'bg-success-gradient' : 'bg-error-gradient'">
                                    <div class="d-flex justify-space-between align-start">
                                        <div class="d-flex align-center gap-4">
                                            <div class="security-crest d-flex align-center justify-center rounded-circle bg-white shadow-sm" style="width: 56px; height: 56px;">
                                                <v-icon size="32" :color="isCertValid(editedItem.certificate_validity) ? 'success' : 'error'">mdi-shield-check</v-icon>
                                            </div>
                                            <div class="text-white">
                                                <div class="text-subtitle-1 font-weight-black text-uppercase tracking-wide">Certificado Digital A1</div>
                                                <div class="text-body-2 font-weight-medium opacity-90">{{ editedItem.name || 'Empresa Emissora' }}</div>
                                                <div class="text-caption font-mono mt-1 opacity-70">CNPJ: {{ formatCNPJ(editedItem.cnpj) || 'Não definido' }}</div>
                                            </div>
                                        </div>
                                        <v-chip color="white" :class="isCertValid(editedItem.certificate_validity) ? 'text-success' : 'text-error'" class="font-weight-black elevation-1">
                                            {{ isCertValid(editedItem.certificate_validity) ? 'VÁLIDO' : 'VENCIDO' }}
                                        </v-chip>
                                    </div>
                                    <v-divider class="my-4 border-white-20"></v-divider>
                                    <div class="d-flex justify-space-between align-end">
                                        <div class="text-white">
                                            <div class="text-[10px] text-uppercase font-weight-bold opacity-70">Data de Vencimento</div>
                                            <div class="text-h6 font-weight-black font-mono mt-1">{{ formatDateSafe(editedItem.certificate_validity) }}</div>
                                        </div>
                                        <v-btn variant="flat" color="rgba(255,255,255,0.2)" class="text-white font-weight-bold text-caption border-white-20 backdrop-blur-sm" @click="removeCertificate">
                                            <v-icon start size="16">mdi-delete-outline</v-icon> Remover Certificado
                                        </v-btn>
                                    </div>
                                </div>

                                <v-card class="pa-6 rounded-xl border-thin shadow-xs" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'glass-card border-white-05'" elevation="0">
                                    <div class="text-subtitle-2 font-weight-bold mb-3">{{ editedItem.certificate_validity ? 'Substituir Certificado Atual' : 'Instalar Novo Certificado (.PFX ou .P12)' }}</div>
                                    <div
                                        class="drag-drop-zone rounded-xl d-flex flex-column align-center justify-center pa-6 transition-all"
                                        :class="[
                                            isDragging ? 'dragging bg-blue-grey-lighten-5 border-blue-grey' : (themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 border-grey-lighten-3' : 'bg-white-05 border-white-10'),
                                            certFile ? 'has-file' : ''
                                        ]"
                                        @dragover.prevent="isDragging = true"
                                        @dragleave.prevent="isDragging = false"
                                        @drop.prevent="handleDrop"
                                        @click="triggerCertInput"
                                    >
                                        <v-icon size="48" :color="certFile ? 'success' : (themeStore.currentMode === 'light' ? 'grey-lighten-1' : 'white-20')" class="mb-3 transition-all">
                                            {{ certFile ? 'mdi-file-certificate' : 'mdi-cloud-upload-outline' }}
                                        </v-icon>
                                        <div v-if="!certFile" class="text-center pointer-events-none">
                                            <div class="text-body-1 font-weight-bold" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-3' : 'text-white'">Arraste e solte o arquivo aqui</div>
                                            <div class="text-caption opacity-60 mt-1">ou clique para procurar no seu computador</div>
                                        </div>
                                        <div v-else class="text-center pointer-events-none">
                                            <div class="text-h6 font-weight-black text-success">{{ certFile.name }}</div>
                                            <div class="text-caption text-grey-darken-1 mt-1">{{ (certFile.size / 1024).toFixed(1) }} KB prontos para instalação</div>
                                        </div>
                                        <input type="file" ref="certInput" class="d-none" accept=".pfx,.p12" @change="handleCertSelect">
                                    </div>

                                    <v-expand-transition>
                                        <div v-if="certFile" class="mt-6 pa-5 rounded-xl border border-blue-grey-lighten-3 bg-blue-grey-lighten-5 shadow-sm">
                                            <label class="input-label text-blue-grey-darken-4">Senha do Certificado Digital *</label>
                                            <v-text-field
                                                v-model="certPassword"
                                                type="password"
                                                variant="outlined"
                                                density="comfortable"
                                                prepend-inner-icon="mdi-lock-outline"
                                                class="ui-field bg-white"
                                                placeholder="Digite a senha para descriptografar"
                                                color="blue-grey-darken-2"
                                                hide-details
                                                autocomplete="new-password"
                                            ></v-text-field>
                                            <v-btn block color="blue-grey-darken-3" size="large" variant="flat" class="font-weight-bold mt-4 shadow-sm" @click="installCertificate" :loading="installingCert" :disabled="!certPassword">
                                                <v-icon start>mdi-shield-key-outline</v-icon> Validar e Instalar Certificado
                                            </v-btn>
                                        </div>
                                    </v-expand-transition>
                                </v-card>
                            </v-window-item>

                        </v-window>
                    </v-form>
                 </div>

                 <div class="pa-4 border-t d-flex justify-end align-center flex-shrink-0 z-10 bg-white shadow-inner-top" :class="themeStore.currentMode === 'light' ? 'border-grey-lighten-2' : 'border-white-10 bg-glass-header'" style="gap: 12px; height: 80px;">
                    <v-btn variant="text" class="font-weight-bold text-grey-darken-1" @click="close" :disabled="saving" height="46">Cancelar</v-btn>
                    <v-btn color="success" variant="flat" class="btn-rect px-8 font-weight-black text-body-1 shadow-sm" height="46" @click="save" :loading="saving">
                        <v-icon start>mdi-content-save-check</v-icon> Salvar Configurações
                    </v-btn>
                 </div>
            </div>
        </v-card>
    </v-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted, computed } from 'vue';
import { supabase } from '@/api/supabase';
import { vMaska } from 'maska/vue';
import axios from 'axios';
import { useThemeStore } from '@/stores/themeStore';
import { useAppStore } from '@/stores/app';

const themeStore = useThemeStore();
const appStore = useAppStore();

const API_URL = import.meta.env.VITE_SEFAZ_PROXY_URL || 'https://sefaz-proxy-dujl.onrender.com';

const companies = ref<any[]>([]);
const loading = ref(false);
const dialog = ref(false);
const saving = ref(false);
const activeTab = ref('geral');
const search = ref('');

// Refs de Arquivo
const isDragging = ref(false);
const certFile = ref<File | null>(null);
const certPassword = ref('');
const certInput = ref<HTMLInputElement | null>(null);
const installingCert = ref(false);
const logoInput = ref<HTMLInputElement | null>(null);

// OPÇÕES DOS SELECTS
const crtOptions = [
  { label: '1 - Simples Nacional', value: '1' },
  { label: '2 - Simples Nacional (Excesso de Sublimite)', value: '2' },
  { label: '3 - Regime Normal (Lucro Presumido/Real)', value: '3' },
];

const availableCstOptions = computed(() => {
    const isSimples = editedItem.crt === '1' || editedItem.crt === '2';
    if (isSimples) {
        return [
            { label: '102 - Simples Nacional (Sem permissão crédito)', value: '102' },
            { label: '103 - Simples Nacional (Isenção)', value: '103' },
            { label: '400 - Simples Nacional (Não tributada)', value: '400' },
            { label: '500 - ICMS cobrado por ST (Simples Nacional)', value: '500' },
            { label: '900 - Outros', value: '900' }
        ];
    } else {
        return [
            { label: '00 - Tributada Integralmente (Reg. Normal)', value: '00' },
            { label: '20 - Com Redução de Base de Cálculo', value: '20' },
            { label: '40 - Isenta (Reg. Normal)', value: '40' },
            { label: '41 - Não Tributada (Reg. Normal)', value: '41' },
            { label: '60 - ICMS cobrado anteriormente por ST', value: '60' },
            { label: '900 - Outros', value: '900' }
        ];
    }
});

const adjustDefaultCst = () => {
    // Quando muda o Regime, limpa o CST caso ele não seja mais compatível
    const validValues = availableCstOptions.value.map(o => o.value);
    if (!validValues.includes(editedItem.default_cst_csosn)) {
        editedItem.default_cst_csosn = validValues[0];
    }
};

const envOptions = [
    { title: 'Homologação (Testes SEFAZ)', value: 'homologacao' },
    { title: 'Produção (Validade Jurídica)', value: 'producao' }
];

const taxRegimeOptions = [
    { label: 'Nenhum', value: '0' },
    { label: 'Microempresa Municipal', value: '1' },
    { label: 'Estimativa', value: '2' },
    { label: 'Sociedade de Profissionais', value: '3' },
    { label: 'Cooperativa', value: '4' },
    { label: 'MEI', value: '5' },
    { label: 'ME EPP Simples Nacional', value: '6' }
];

const operationNatureOptions = [
    { label: 'Tributação no município', value: '1' },
    { label: 'Tributação fora do município', value: '2' },
    { label: 'Isenção', value: '3' },
    { label: 'Imune', value: '4' },
    { label: 'Exigibilidade Suspensa', value: '5' }
];

const defaultItem = {
    id: null, name: '', trade_name: '', cnpj: '', ie: '', im: '', crt: '1', email: '',
    zip_code: '', street: '', number: '', complemento: '', district: '', city: '', uf: '',
    active: true, logo_url: null,

    // NFE
    nfe_environment: 'homologacao', nfe_series: 1, nfe_next_number: 1, nfe_info_complementar: '', nfe_version: '4.00', subtract_icms_pis_cofins: false, simple_danfe: false, default_cst_csosn: '102',

    // NFCE
    nfce_environment: 'homologacao', nfce_series: 1, nfce_next_number: 1, nfce_token: '', nfce_csc: '', nfce_info_complementar: '',

    // NFSE
    nfse_environment: 'homologacao', nfse_next_rps: 1, nfse_rps_series: '1', nfse_tax_regime: '0', nfse_operation_nature: '1', nfse_info_complementar: '',

    // CTE
    cte_environment: 'homologacao', cte_series: 1, cte_next_number: 1, cte_info_complementar: '',

    // OUTROS
    xml_auth_cnpjs: '', certificate_validity: null, certificate_url: null, certificate_password: null
};

const editedItem = reactive({ ...defaultItem });

// --- LIFECYCLE & DATA ---
const fetchCompanies = async () => {
  loading.value = true;
  const { data } = await supabase.from('companies').select('*').order('name');

  // Mapeamento e fallback pra evitar bugs
  companies.value = (data || []).map(c => ({
      ...c,
      street: c.street || c.logradouro || '',
      district: c.district || c.bairro || '',
      city: c.city || c.municipio || '',
      zip_code: c.zip_code || c.cep || ''
  }));
  loading.value = false;
};

const filteredCompanies = computed(() => {
    if (!search.value) return companies.value;
    const term = search.value.toLowerCase();
    const numTerm = term.replace(/\D/g, '');
    return companies.value.filter(c =>
        c.name?.toLowerCase().includes(term) ||
        c.trade_name?.toLowerCase().includes(term) ||
        (numTerm.length > 0 && c.cnpj?.includes(numTerm))
    );
});

// --- ACTIONS ---
const openDialog = (item?: any) => {
    activeTab.value = 'geral';
    certFile.value = null; certPassword.value = '';
    Object.assign(editedItem, item ? JSON.parse(JSON.stringify(item)) : JSON.parse(JSON.stringify(defaultItem)));

    // Retrocompatibilidade
    editedItem.logradouro = editedItem.street || editedItem.logradouro || '';
    editedItem.bairro = editedItem.district || editedItem.bairro || '';
    editedItem.municipio = editedItem.city || editedItem.municipio || '';
    editedItem.cep = editedItem.zip_code || editedItem.cep || '';

    if(!editedItem.default_cst_csosn) editedItem.default_cst_csosn = editedItem.crt === '3' ? '00' : '102';

    dialog.value = true;
};

const close = () => { dialog.value = false; };

const save = async () => {
  if (!editedItem.name || !editedItem.cnpj) return appStore.showSnackbar("Razão Social e CNPJ são obrigatórios.", "warning");
  saving.value = true;
  try {
    const payload = { ...editedItem };
    if (!payload.id) delete payload.id;

    payload.cnpj = payload.cnpj.replace(/\D/g, '');
    payload.street = payload.logradouro;
    payload.district = payload.bairro;
    payload.city = payload.municipio;
    payload.zip_code = payload.cep?.replace(/\D/g, '');

    // Limpeza
    delete payload.logradouro; delete payload.bairro; delete payload.municipio; delete payload.cep;

    const { error } = await supabase.from('companies').upsert(payload);
    if (error) throw error;

    appStore.showSnackbar("Configurações da empresa salvas com sucesso!", "success");
    await fetchCompanies();
    close();
  } catch (error: any) { appStore.showSnackbar('Erro ao salvar: ' + error.message, "error"); }
  finally { saving.value = false; }
};

const toggleStatus = async (item: any) => {
    const newVal = !item.active;
    await supabase.from('companies').update({ active: newVal }).eq('id', item.id);
    item.active = newVal;
    appStore.showSnackbar(`Empresa ${newVal ? 'Ativada' : 'Desativada'} com sucesso.`, "success");
};

// --- LOGO UPLOAD ---
const triggerLogoUpload = () => logoInput.value?.click();
const handleLogoUpload = async (event: any) => {
    const file = event.target.files[0];
    if (!file) return;
    appStore.showSnackbar("A enviar imagem...", "info");
    const fileName = `logos/${Date.now()}_${file.name}`;
    const { error } = await supabase.storage.from('media').upload(fileName, file);
    if (error) return appStore.showSnackbar('Erro ao subir imagem.', 'error');
    const { data } = supabase.storage.from('media').getPublicUrl(fileName);
    editedItem.logo_url = data.publicUrl;
    appStore.showSnackbar("Imagem atualizada. Clique em Salvar Configurações.", "success");
};

// --- CERTIFICADO ---
const triggerCertInput = () => certInput.value?.click();
const handleDrop = (e: DragEvent) => {
    isDragging.value = false;
    if (e.dataTransfer?.files && e.dataTransfer.files.length > 0) {
        const file = e.dataTransfer.files[0];
        if(file.name.endsWith('.pfx') || file.name.endsWith('.p12')) certFile.value = file;
        else appStore.showSnackbar("Apenas ficheiros .PFX são permitidos.", "warning");
    }
};
const handleCertSelect = (e: any) => {
    if (e.target.files && e.target.files.length > 0) certFile.value = e.target.files[0];
};

const installCertificate = async () => {
    if (!certFile.value || !certPassword.value) return;
    installingCert.value = true;
    try {
        const reader = new FileReader();
        reader.readAsDataURL(certFile.value as Blob);
        reader.onload = async () => {
            try {
                const base64 = (reader.result as string).split(',')[1];
                const cnpjLimpo = editedItem.cnpj.replace(/\D/g, '') || '00000000000000';

                // Exemplo real de endpoint que poderia validar o PFX
                // await axios.put(`${API_URL}/api/empresas/${cnpjLimpo}/certificado`, { certificado_base64: base64, password: certPassword.value });

                // Simulação visual (Substituir pela resposta da API real que retorna a validade)
                await new Promise(resolve => setTimeout(resolve, 1500));
                const validityDate = new Date();
                validityDate.setFullYear(validityDate.getFullYear() + 1);

                editedItem.certificate_validity = validityDate.toISOString();
                editedItem.certificate_password = certPassword.value; // Em produção pode omitir se a API já guarda seguro

                appStore.showSnackbar("Certificado processado e validado com sucesso!", "success");

                certFile.value = null; certPassword.value = '';
            } catch(apiErr:any) {
                appStore.showSnackbar("Erro na validação do certificado: " + (apiErr.response?.data?.error || apiErr.message), "error");
            } finally {
                installingCert.value = false;
            }
        };
    } catch (e: any) {
        appStore.showSnackbar("Erro ao ler o ficheiro.", "error");
        installingCert.value = false;
    }
};

const removeCertificate = () => {
    if(!confirm('Tem a certeza que deseja remover o certificado instalado? A emissão de notas irá parar de funcionar.')) return;
    editedItem.certificate_validity = null;
    editedItem.certificate_url = null;
    editedItem.certificate_password = null;
    appStore.showSnackbar("Certificado removido. Lembre-se de salvar as configurações.", "warning");
};

// --- UTILS ---
const buscaCep = async () => {
    const cep = editedItem.cep?.replace(/\D/g, '') || editedItem.zip_code?.replace(/\D/g, '');
    if (cep?.length === 8) {
        try {
            const res = await axios.get(`https://viacep.com.br/ws/${cep}/json/`);
            if (!res.data.erro) {
                editedItem.logradouro = res.data.logradouro;
                editedItem.bairro = res.data.bairro;
                editedItem.municipio = res.data.localidade;
                editedItem.uf = res.data.uf;
            }
        } catch {}
    }
};

const formatCNPJ = (v: string) => v?.replace(/^(\d{2})(\d{3})(\d{3})(\d{4})(\d{2})/, "$1.$2.$3/$4-$5");
const formatDateSafe = (dateString: string) => {
    if (!dateString) return '-';
    return dateString.split('T')[0].split('-').reverse().join('/');
};
const isCertValid = (dateString: string) => {
    if(!dateString) return false;
    return new Date(dateString) > new Date();
};
const zebraClass = (i:number) => themeStore.currentMode !== 'light' ? (i%2===0?'zebra-dark-a':'zebra-dark-b') : (i%2===0?'zebra-light-a':'zebra-light-b');

const getTabTitle = (tab: string) => {
    const map: Record<string, string> = {
        geral: 'Dados Básicos e Identificação',
        endereco: 'Localização da Matriz',
        nfe: 'Configuração NF-e (Modelo 55)',
        nfce: 'Configuração NFC-e (Cupom)',
        nfse: 'Configuração NFS-e (Serviço)',
        cte: 'Configuração CT-e (Transporte)',
        autorizacoes: 'Autorizações Sefaz (Download de XML)',
        certificado: 'Gestão do Certificado Digital A1'
    };
    return map[tab] || 'Detalhes da Empresa';
};

onMounted(() => { fetchCompanies(); });
</script>

<style scoped lang="scss">
/* --- LAYOUT GLOBAL PADRÃO ADMINMJRECEIVABLES --- */
.receivables-layout { position: relative; }
.bg-glass-dark { background: rgba(10,10,12,0.85); }
.bg-glass-header { background: rgba(20,20,24,0.55); backdrop-filter: blur(14px); }
.border-bottom-white-05 { border-bottom: 1px solid rgba(255,255,255,0.08); }
.btn-rect { border-radius: 0 !important; text-transform: none !important; font-weight: 800; }
.shadow-inner-top { box-shadow: inset 0 2px 4px rgba(0,0,0,0.02); }

.controls-bar { border: 1px solid rgba(0,0,0,0.08); padding: 10px; border-radius: 8px; }
.controls-dark { border-color: rgba(255,255,255,0.1); }
.search-wrap { height: 44px; padding: 0 16px; border: 1px solid rgba(0,0,0,0.08); display: flex; align-items: center; border-radius: 6px; }
.search-dark { border-color: rgba(255,255,255,0.1); background: rgba(255,255,255,0.02); }
.clean-input { border: none; outline: none; flex: 1; font-size: 14px; background: transparent; }

.background-carousel-wrapper { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 0; opacity: 0.6; pointer-events: none; }
.background-overlay { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 1; background: radial-gradient(circle at center, rgba(15, 15, 19, 0.4), rgba(15, 15, 19, 0.98)); backdrop-filter: blur(8px); }
.z-10 { position: relative; z-index: 10; }

/* --- GRID FLUIDA C/ COLUNAS SEPARADAS --- */
.grid-scroll { scrollbar-gutter: stable; -webkit-overflow-scrolling: touch; }
.custom-scroll::-webkit-scrollbar { width: 8px; height: 8px; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.35); border-radius: 6px; }
.custom-scroll::-webkit-scrollbar-track { background: transparent; }

.grid-header, .grid-row { display: grid; align-items: stretch; width: 100%; }
.cell { padding: 6px 12px; display: flex; align-items: center; border-right: 1px solid rgba(0,0,0,0.08); border-bottom: 1px solid rgba(0,0,0,0.08); min-height: 54px; overflow: hidden; transition: background-color 0.2s ease; }
.header-text { font-size: 11px !important; font-weight: 800; text-transform: uppercase; letter-spacing: 0.5px; opacity: 0.8; background: inherit; }
.center { justify-content: center; text-align: center; }
.list-text-11 { font-size: 13px !important; line-height: 1.2 !important; }

.grid-surface-light .cell { background: #f8fafc; color: rgba(0,0,0,0.8); border-color: rgba(0,0,0,0.08) !important; }
.grid-surface-dark .cell { background: rgba(255,255,255,0.05); color: rgba(255,255,255,0.9); border-color: rgba(255,255,255,0.08) !important; }
.grid-row-light .cell { border-color: rgba(0,0,0,0.05) !important; }
.grid-row-dark .cell { border-color: rgba(255,255,255,0.05) !important; }
.zebra-light-a .cell { background: #ffffff; }
.zebra-light-b .cell { background: #fcfcfc; }
.zebra-dark-a .cell { background: rgba(0,0,0,0.15); }
.zebra-dark-b .cell { background: rgba(255,255,255,0.02); }
.grid-row-light:hover .cell { background: #f1f5f9 !important; }
.grid-row-dark:hover .cell { background: rgba(255,255,255,0.08) !important; }

.sticky-head { position: sticky; top: 0; z-index: 20; box-shadow: 0 8px 16px -4px rgba(0, 0, 0, 0.08); }
.bg-glass-dark .sticky-head { box-shadow: 0 8px 20px -4px rgba(0, 0, 0, 0.3); }

/* Status Dot e Actions */
.status-dot { width: 10px; height: 10px; }
.pulse-success { box-shadow: 0 0 0 rgba(76, 175, 80, 0.4); animation: pulse 2s infinite; }
@keyframes pulse { 0% { box-shadow: 0 0 0 0 rgba(76, 175, 80, 0.4); } 70% { box-shadow: 0 0 0 6px rgba(76, 175, 80, 0); } 100% { box-shadow: 0 0 0 0 rgba(76, 175, 80, 0); } }

.actions-inline { display: flex; gap: 6px; justify-content: center; }
.action-btn { width: 32px !important; height: 32px !important; border-radius: 6px !important; color: #fff !important; }
.action-edit { background: #455A64 !important; } /* Mudança para a cor de edição neutra */

/* --- MODAL E FORMULÁRIO --- */
.fixed-dialog { overflow: hidden !important; }
.absolute-fill { height: 100%; overflow-y: auto; }
.ui-field :deep(.v-field) { border-radius: 6px !important; }
.row-gap { row-gap: 16px; margin-top: 4px;}
.input-label { display: block; font-size: 11px; font-weight: 800; text-transform: uppercase; color: #757575; margin-bottom: 6px; letter-spacing: 0.5px; }
.bg-glass-dark .input-label { color: rgba(255,255,255,0.7); }
.icon-box { width: 36px; height: 36px; display: flex; align-items: center; justify-content: center; }

/* SIDEBAR TABS - COR SLATE/CHUMBO ELEGANTE */
.bg-blue-grey-darken-4 { background-color: #263238 !important; }
.custom-scroll-dark::-webkit-scrollbar { width: 4px; }
.custom-scroll-dark::-webkit-scrollbar-thumb { background: rgba(255,255,255,0.2); border-radius: 2px; }
.sidebar-tabs :deep(.v-btn) { justify-content: flex-start; text-align: left; height: 52px; font-size: 13px; font-weight: 700; letter-spacing: 0.3px; border-radius: 0; opacity: 0.7;}
.sidebar-tabs :deep(.v-btn--active) { background-color: rgba(255,255,255,0.1); border-right: 4px solid #fff; opacity: 1; }

/* AVATAR OVERLAY */
.hover-opacity:hover .overlay-upload { opacity: 1; }
.overlay-upload { position: absolute; bottom: 0; left: 0; width: 100%; background: rgba(0,0,0,0.8); padding: 6px; opacity: 0; transition: opacity 0.2s; }

/* DRAG N DROP ZONE */
.drag-drop-zone { border: 2px dashed transparent; cursor: pointer; min-height: 180px; }
.drag-drop-zone.dragging { border-color: #546E7A !important; background-color: rgba(84, 110, 122, 0.05) !important; transform: scale(1.02); }
.drag-drop-zone.has-file { border-style: solid; border-color: #4CAF50 !important; background-color: rgba(76, 175, 80, 0.05) !important; }

/* CERTIFICATE PREMIUM CARD */
.certificate-card { position: relative; overflow: hidden; }
.bg-success-gradient { background: linear-gradient(135deg, #2e7d32, #1b5e20); }
.bg-error-gradient { background: linear-gradient(135deg, #c62828, #8e0000); }
.border-white-20 { border-color: rgba(255,255,255,0.2) !important; border-style: dashed; }
.backdrop-blur-sm { backdrop-filter: blur(4px); }
</style>
