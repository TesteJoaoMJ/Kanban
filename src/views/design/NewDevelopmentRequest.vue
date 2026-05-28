<template>
  <div class="dev-request-layout fill-height d-flex flex-column position-relative overflow-hidden transition-all" :class="themeClasses.pageBg">

    <div class="ambient-glow" :class="isLightMode ? 'glow-light' : 'glow-dark'"></div>

    <div v-if="!isLightMode" class="background-carousel-wrapper">
        <v-carousel cycle height="100%" hide-delimiters :show-arrows="false" interval="20000" class="fill-height opacity-20">
            <v-carousel-item src="@/assets/1.jpg" cover></v-carousel-item>
            <v-carousel-item src="@/assets/3.jpg" cover></v-carousel-item>
        </v-carousel>
        <div class="background-overlay"></div>
    </div>

    <div class="px-6 py-6 px-md-10 py-md-8 position-relative z-10 flex-shrink-0 transition-all">
      <div class="breadcrumb text-[11px] font-weight-bold opacity-70 mb-3 d-flex align-center tracking-wide" :class="themeClasses.textPrimary">
        <v-icon size="14" class="mr-1">mdi-home</v-icon>
        <span class="cursor-pointer hover-text" @click="$router.push({ name: 'Hub' })">Dashboard</span>
        <span class="mx-2 opacity-50">/</span>
        <span class="cursor-pointer hover-text" @click="goToKanban">Estúdio</span>
        <span class="mx-2 opacity-50">/</span>
        <span class="opacity-100" :class="isLightMode ? 'text-indigo-darken-3' : 'text-indigo-lighten-2'">Nova Solicitação</span>
      </div>

      <div class="d-flex align-center justify-space-between flex-wrap gap-4 mb-2">
          <h1 class="text-h3 font-weight-black tracking-tight transition-all" style="letter-spacing: -1px !important;" :class="themeClasses.textPrimary">
            Central de Desenvolvimento
          </h1>

          <div class="d-flex align-center gap-3">
              <v-btn
                  variant="outlined"
                  size="small"
                  :color="isLightMode ? 'indigo-darken-3' : 'indigo-lighten-2'"
                  class="btn-sq font-weight-bold"
                  style="border-width: 1.5px; height: 32px;"
                  @click="openMyRequests"
              >
                  <v-icon start size="16">mdi-history</v-icon>
                  Meu Histórico
              </v-btn>

              <v-slide-x-reverse-transition mode="out-in">
                  <v-chip :key="requestType" size="default" :color="typeColor" variant="flat" class="font-weight-bold text-uppercase chip-sq tracking-widest px-4 transition-all shadow-sm" style="height: 32px;">
                    {{ typeLabel }}
                  </v-chip>
              </v-slide-x-reverse-transition>
          </div>
      </div>

      <p class="text-body-1 font-weight-medium opacity-80 transition-all" style="max-width: 600px;" :class="themeClasses.textSecondary">
        Envie novas solicitações de design, alterações de estampa ou peças piloto diretamente para a fila de produção do estúdio.
      </p>
    </div>

    <div class="flex-grow-1 d-flex flex-column flex-lg-row overflow-hidden relative z-10 mx-4 mx-md-8 mb-4 mb-md-8 border-thin shadow-soft transition-all layout-wrapper" :class="themeClasses.mainWrapper">

        <div class="flex-grow-1 overflow-y-auto custom-scrollbar pa-6 pa-md-8 pb-24 pb-lg-8" :class="themeClasses.formArea">
            <v-container max-width="900" class="pa-0 mx-auto">
                <v-form ref="form" v-model="valid">

                    <transition-group name="list" tag="div" class="d-flex flex-column gap-6">
                        <div v-for="(item, index) in requestItems" :key="item.id" class="request-item-card border-thin transition-all shadow-sm" :class="themeClasses.itemCard">

                            <div class="px-6 py-4 border-b d-flex align-center justify-space-between transition-all" :class="themeClasses.cardHeader">
                                <div class="d-flex align-center gap-4">
                                    <div class="step-indicator transition-all" :class="isLightMode ? 'bg-grey-darken-4 text-white' : 'bg-white text-grey-darken-4'">
                                        {{ index + 1 }}
                                    </div>
                                    <div class="d-flex flex-column">
                                        <div class="text-body-1 font-weight-black tracking-tight transition-all" :class="themeClasses.textPrimary">
                                            {{ item.customer ? item.customer.nome : 'Configuração do Item' }}
                                        </div>
                                        <div class="text-[10px] font-weight-bold text-uppercase opacity-70 mt-1 d-flex align-center gap-2 transition-all" :class="themeClasses.textSecondary">
                                            <span><v-icon size="12" class="mr-1">mdi-paperclip</v-icon>{{ item.files.length }} Anexos</span>
                                            <span v-if="item.notes"><v-icon size="12" class="mr-1">mdi-text</v-icon>Com Observação</span>
                                        </div>
                                    </div>
                                </div>
                                <v-btn
                                    v-if="requestItems.length > 1"
                                    icon size="small"
                                    variant="text"
                                    color="error"
                                    class="btn-sq opacity-80"
                                    @click="removeItem(index)"
                                    title="Remover Item"
                                >
                                    <v-icon size="18">mdi-trash-can-outline</v-icon>
                                </v-btn>
                            </div>

                            <div class="pa-6">
                                <v-row class="row-gap">
                                    <v-col cols="12">
                                        <label class="premium-label">Cliente / Marca Requisitante</label>
                                        <v-autocomplete
                                            v-model="item.customer"
                                            v-model:search="item.clientSearch"
                                            :items="clientList"
                                            :item-title="(c) => c.nome || c.name || c.razao_social || c.nome_fantasia"
                                            item-value="id"
                                            return-object
                                            placeholder="Pesquise por nome, fantasia, CPF ou CNPJ..."
                                            variant="outlined"
                                            prepend-inner-icon="mdi-domain"
                                            :rules="[rules.requiredObject]"
                                            :loading="isSearchingClients"
                                            :custom-filter="customFilter"
                                            density="comfortable"
                                            hide-details="auto"
                                            class="premium-input"
                                            :class="themeClasses.inputClass"
                                        >
                                            <template v-slot:item="{ props, list_item }">
                                                <v-list-item v-bind="props" density="compact" class="py-2">
                                                    <template v-slot:prepend>
                                                        <v-avatar :color="isLightMode ? 'indigo-lighten-5' : 'grey-darken-3'" size="32" class="border-sq mr-3 transition-colors">
                                                            <span class="text-caption font-weight-black" :class="isLightMode ? 'text-indigo-darken-3' : 'text-white'">
                                                                {{ (list_item.raw.nome || list_item.raw.razao_social || 'C').charAt(0).toUpperCase() }}
                                                            </span>
                                                        </v-avatar>
                                                    </template>
                                                    <v-list-item-title class="text-body-2 font-weight-bold">
                                                        {{ list_item.raw.nome || list_item.raw.razao_social || list_item.raw.nome_fantasia }}
                                                    </v-list-item-title>
                                                    <v-list-item-subtitle class="text-[11px] font-mono opacity-70 mt-1">
                                                        {{ list_item.raw.cpf_cnpj || 'Sem documento cadastrado' }}
                                                    </v-list-item-subtitle>
                                                </v-list-item>
                                            </template>
                                            <template v-slot:append-inner>
                                                <v-btn size="small" variant="text" color="indigo" class="btn-sq text-none font-weight-black" @click.stop="openNewCustomerModal">
                                                    + NOVO
                                                </v-btn>
                                            </template>
                                        </v-autocomplete>
                                    </v-col>

                                    <v-col cols="12">
                                        <div class="d-flex align-center justify-space-between mb-2">
                                            <label class="premium-label mb-0">Referências Visuais & Mockups</label>
                                            <span class="text-[10px] font-weight-bold opacity-50 text-uppercase" :class="themeClasses.textPrimary">JPG, PNG, PDF</span>
                                        </div>

                                        <div class="upload-zone transition-all"
                                             :class="themeClasses.uploadZone"
                                             @click="$refs[`fileInput_${index}`][0].click()">
                                            <v-icon size="32" class="mb-3 opacity-80" :color="isLightMode ? 'indigo' : 'white'">mdi-cloud-upload-outline</v-icon>
                                            <div class="text-body-2 font-weight-bold">Clique para buscar os arquivos</div>
                                            <div class="text-caption font-weight-medium opacity-70 mt-1">Arraste os arquivos para cá ou clique no botão</div>

                                            <input
                                                type="file"
                                                :ref="`fileInput_${index}`"
                                                multiple
                                                accept="image/*,.pdf"
                                                class="d-none"
                                                @change="(e) => handleFileSelect(e, item)"
                                            >
                                        </div>

                                        <div v-if="item.attachments_meta && item.attachments_meta.length > 0" class="attachment-grid mt-4">
                                            <div v-for="(fileMeta, fIndex) in item.attachments_meta" :key="fIndex" class="attachment-card border-sq overflow-hidden group border-thin transition-colors" :class="themeClasses.attachmentCard">

                                                <div class="preview-box bg-checkerboard relative" style="height: 120px;">
                                                    <v-img
                                                        :src="fileMeta.preview"
                                                        cover
                                                        height="100%"
                                                        class="transition-transform duration-300 group-hover:scale-105"
                                                    >
                                                        <template v-slot:placeholder>
                                                            <div class="d-flex align-center justify-center fill-height" :class="isLightMode ? 'bg-grey-lighten-4' : 'bg-grey-darken-4'">
                                                                <v-progress-circular indeterminate color="indigo" size="20" width="2"></v-progress-circular>
                                                            </div>
                                                        </template>
                                                    </v-img>
                                                    <div class="absolute top-2 right-2">
                                                        <v-btn icon size="x-small" color="error" variant="flat" class="btn-sq opacity-0 group-hover:opacity-100 transition-opacity shadow-sm" @click.stop="removeFile(item, fIndex)">
                                                            <v-icon size="14">mdi-close</v-icon>
                                                        </v-btn>
                                                    </div>
                                                    <div class="absolute bottom-2 left-2">
                                                        <div class="badge-sq bg-black text-white px-2 py-1 text-[9px] font-weight-black opacity-90 backdrop-blur">
                                                            {{ fileMeta.extension }}
                                                        </div>
                                                    </div>
                                                </div>

                                                <div class="pa-3 text-caption lh-1">
                                                    <div class="font-weight-black text-truncate mb-1 transition-colors" :class="themeClasses.textPrimary" :title="fileMeta.name">
                                                        {{ fileMeta.name }}
                                                    </div>
                                                    <div class="d-flex justify-space-between align-center text-[10px] font-mono opacity-70 transition-colors" :class="themeClasses.textPrimary">
                                                        <span>{{ fileMeta.sizeStr }}</span>
                                                        <span v-if="fileMeta.resolution">{{ fileMeta.resolution }}</span>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                    </v-col>

                                    <v-col cols="12">
                                        <label class="premium-label">Briefing / Especificações Técnicas</label>
                                        <v-textarea
                                            v-model="item.notes"
                                            placeholder="Descreva cores, posição da estampa, técnica desejada, dimensões..."
                                            variant="outlined"
                                            rows="3"
                                            auto-grow
                                            density="comfortable"
                                            hide-details
                                            class="premium-input font-weight-medium"
                                            :class="themeClasses.inputClass"
                                        ></v-textarea>
                                    </v-col>
                                </v-row>
                            </div>
                        </div>
                    </transition-group>

                    <div class="d-flex justify-center mt-8 mb-4">
                        <v-btn
                            variant="outlined"
                            size="large"
                            :color="isLightMode ? 'indigo-darken-1' : 'indigo-lighten-2'"
                            prepend-icon="mdi-plus"
                            class="btn-sq font-weight-black text-uppercase tracking-widest px-8 opacity-90 border-dashed"
                            style="border-width: 2px;"
                            @click="addItem"
                        >
                            Adicionar Item ao Lote
                        </v-btn>
                    </div>

                </v-form>
            </v-container>
        </div>

        <div class="sidebar-config d-flex flex-column border-l flex-shrink-0 transition-all" :class="themeClasses.sidebar">

            <div class="pa-6 border-b transition-all" :class="themeClasses.borderClass">
                <h3 class="text-[10px] font-weight-bold text-uppercase tracking-widest opacity-70 mb-2 transition-colors" :class="themeClasses.textSecondary">Resumo do Lote</h3>
                <div class="text-h4 font-weight-black tracking-tight transition-colors" :class="themeClasses.textPrimary">
                    {{ requestItems.length }} <span class="text-body-1 font-weight-bold opacity-60">Itens</span>
                </div>
            </div>

            <div class="flex-grow-1 overflow-y-auto custom-scrollbar pa-6 d-flex flex-column gap-8">

                <div>
                    <label class="premium-label">Tipo de Solicitação</label>
                    <div class="segmented-control transition-all" :class="isLightMode ? 'seg-light' : 'seg-dark'">
                        <div class="seg-item transition-all" :class="{ 'seg-active': requestType === 'development' }" @click="requestType = 'development'">
                            Novo Design
                        </div>
                        <div class="seg-item transition-all" :class="{ 'seg-active': requestType === 'alteration' }" @click="requestType = 'alteration'">
                            Alteração
                        </div>
                        <div class="seg-item transition-all" :class="{ 'seg-active': requestType === 'pilot' }" @click="requestType = 'pilot'">
                            Piloto
                        </div>
                    </div>

                    <v-expand-transition>
                        <div v-if="requestType === 'pilot'" class="mt-4">
                            <div class="premium-alert border-sq transition-all" :class="isLightMode ? 'bg-indigo-lighten-5 border-indigo-lighten-4' : 'theme-alert-dark border-white-10'">
                                <div class="d-flex align-center gap-2 mb-3">
                                    <v-icon size="16" :color="isLightMode ? 'indigo-darken-2' : 'indigo-lighten-2'">mdi-camera-front-variant</v-icon>
                                    <span class="text-[10px] font-weight-black text-uppercase tracking-widest transition-colors" :class="isLightMode ? 'text-indigo-darken-4' : 'text-white'">Aprovação</span>
                                </div>
                                <v-radio-group v-model="pilotApprovalType" hide-details density="compact" class="custom-radio">
                                    <v-radio value="digital" color="indigo" class="mb-2">
                                        <template v-slot:label>
                                            <div class="d-flex flex-column ml-2 transition-colors" :class="themeClasses.textPrimary">
                                                <span class="text-caption font-weight-bold">Digital (Ágil)</span>
                                                <span class="text-[10px] font-weight-medium opacity-70">Foto/Vídeo via WhatsApp.</span>
                                            </div>
                                        </template>
                                    </v-radio>
                                    <v-radio value="fisico" color="indigo">
                                        <template v-slot:label>
                                            <div class="d-flex flex-column ml-2 transition-colors" :class="themeClasses.textPrimary">
                                                <span class="text-caption font-weight-bold">Física (Correios)</span>
                                                <span class="text-[10px] font-weight-medium opacity-70">Amostra real impressa enviada.</span>
                                            </div>
                                        </template>
                                    </v-radio>
                                </v-radio-group>
                            </div>
                        </div>
                    </v-expand-transition>
                </div>

                <div>
                    <label class="premium-label">Clientes no Lote</label>
                    <div class="d-flex flex-column gap-2">
                        <div v-for="(item, i) in requestItems" :key="i" class="d-flex align-center gap-3">
                            <div class="status-dot transition-colors" :class="item.customer ? 'bg-success' : 'bg-warning'"></div>
                            <span class="text-caption font-weight-bold text-truncate transition-colors" :class="item.customer ? themeClasses.textPrimary : 'text-grey opacity-70 font-italic'">
                                {{ item.customer ? item.customer.nome : 'Pendente (Item ' + (i+1) + ')' }}
                            </span>
                        </div>
                    </div>
                </div>

                <div>
                    <label class="premium-label">Instruções Globais</label>
                    <v-textarea
                        v-model="generalNotes"
                        placeholder="Informação válida para todos os itens..."
                        variant="outlined"
                        rows="3"
                        auto-grow
                        density="comfortable"
                        hide-details
                        class="premium-input font-weight-medium"
                        :class="themeClasses.inputClass"
                    ></v-textarea>
                </div>
            </div>

            <div class="pa-6 border-t mt-auto d-none d-lg-block transition-all" :class="themeClasses.borderClass">
                <transition name="fade-slide" mode="out-in">
                    <v-btn
                        :key="submitBtnText"
                        block
                        :color="submitBtnColor"
                        size="large"
                        variant="flat"
                        class="btn-sq font-weight-black tracking-tight mb-3 shadow-soft transition-all"
                        :loading="loading"
                        :disabled="!valid || requestItems.length === 0"
                        @click="submitRequest"
                        height="50"
                    >
                        {{ submitBtnText }}
                        <v-icon end size="18" class="ml-2 opacity-80">mdi-send</v-icon>
                    </v-btn>
                </transition>

                <v-btn
                    block
                    variant="text"
                    size="small"
                    color="grey"
                    class="btn-sq font-weight-bold transition-colors"
                    @click="resetForm"
                    :disabled="loading"
                >
                    Limpar Formulário
                </v-btn>
            </div>
        </div>

        <div class="mobile-action-bar d-lg-none border-t transition-all" :class="isLightMode ? 'bg-white border-grey-lighten-2' : 'theme-bg-dark border-white-10'">
            <transition name="fade-slide" mode="out-in">
                <v-btn
                    :key="submitBtnText"
                    block
                    :color="submitBtnColor"
                    size="large"
                    variant="flat"
                    class="btn-sq font-weight-black transition-all"
                    :loading="loading"
                    :disabled="!valid || requestItems.length === 0"
                    @click="submitRequest"
                    height="48"
                >
                    {{ submitBtnText }}
                </v-btn>
            </transition>
        </div>

    </div>

    <v-dialog v-model="showSuccessModal" max-width="400" persistent>
        <v-card class="text-center pa-8 border-sq transition-all" :class="isLightMode ? 'bg-white' : 'bg-grey-darken-4 border border-white-10'" elevation="10">
            <div class="icon-circle-lg mx-auto mb-6 bg-success text-white elevation-2" style="border-radius: 6px;">
                <v-icon size="36">mdi-check</v-icon>
            </div>
            <h2 class="text-h6 font-weight-black mb-2 tracking-tight transition-colors" :class="themeClasses.textPrimary">Lote Enviado</h2>
            <p class="text-caption mb-8 font-weight-bold lh-1-4 transition-colors" :class="themeClasses.textSecondary">
                Sua solicitação foi registrada sob o protocolo <br>
                <strong class="text-body-2 font-mono mt-1 d-block transition-colors" :class="isLightMode ? 'text-indigo-darken-3' : 'text-indigo-lighten-2'">{{ successfulDevCode }}</strong>
            </p>
            <div class="d-flex flex-column gap-3">
                <v-btn color="indigo" block size="large" variant="flat" class="btn-sq font-weight-black" @click="startNewRequest">
                    Nova Solicitação
                </v-btn>
                <v-btn variant="outlined" block size="large" :color="isLightMode ? 'grey-darken-3' : 'white'" class="btn-sq font-weight-bold transition-colors" @click="goToKanban">
                    Ver no Kanban
                </v-btn>
            </div>
        </v-card>
    </v-dialog>

    <v-dialog v-model="myRequestsModal.show" max-width="1300" persistent transition="dialog-bottom-transition" content-class="responsive-modal-container">
        <v-card class="overflow-hidden d-flex flex-column history-grid-card transition-all" :class="isLightMode ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-grey-darken-4 border-white-10'">
            <div class="px-6 py-5 border-b d-flex align-center justify-space-between flex-shrink-0 transition-all" :class="isLightMode ? 'bg-white border-grey-lighten-2' : 'bg-grey-darken-3 border-white-10'">
                <div class="d-flex align-center gap-4">
                    <div class="icon-box-sq d-flex align-center justify-center" :class="isLightMode ? 'bg-indigo-lighten-5 text-indigo-darken-3' : 'bg-indigo-accent-2 text-grey-darken-4'">
                       <v-icon size="20">mdi-history</v-icon>
                    </div>
                    <div>
                        <h3 class="text-h6 font-weight-black tracking-tight text-uppercase lh-1 mb-1" :class="themeClasses.textPrimary">Meu Histórico de Solicitações</h3>
                        <div class="text-caption font-weight-bold opacity-70" :class="themeClasses.textSecondary">Acompanhe todos os seus envios para o estúdio de design.</div>
                    </div>
                </div>
                <v-btn icon="mdi-close" variant="tonal" size="small" class="btn-sq" @click="myRequestsModal.show = false"></v-btn>
            </div>

            <div class="flex-grow-1 overflow-hidden d-flex flex-column relative">
                <div class="grid-scroll flex-grow-1 overflow-x-auto overflow-y-auto custom-scrollbar relative">
                    <div class="grid-header sticky-head grid-layout-requests" :class="isLightMode ? 'grid-surface-light' : 'grid-surface-dark'">
                        <div class="cell center header-text">Data / Cód.</div>
                        <div class="cell center header-text">Tipo</div>
                        <div class="cell header-text">Cliente / Resumo do Pedido</div>
                        <div class="cell header-text">Designer Responsável</div>
                        <div class="cell center header-text">Status Atual</div>
                        <div class="cell center header-text">Ações</div>
                    </div>

                    <div v-if="myRequestsModal.loading" class="d-flex flex-column align-center justify-center py-12">
                        <v-progress-circular indeterminate color="indigo" size="48" width="4"></v-progress-circular>
                    </div>

                    <div v-else-if="myRequestsModal.items.length === 0" class="d-flex flex-column align-center justify-center py-16 opacity-60">
                        <v-icon size="64" color="grey" class="mb-4">mdi-clipboard-text-off-outline</v-icon>
                        <span class="text-body-1 font-weight-black">Você ainda não fez nenhuma solicitação.</span>
                    </div>

                    <div
                        v-else
                        v-for="(req, index) in myRequestsModal.items"
                        :key="req.id"
                        class="grid-row grid-layout-requests transition-colors"
                        :class="[isLightMode ? 'grid-row-light' : 'grid-row-dark', zebraClass(index)]"
                    >
                        <div class="cell center flex-column justify-center gap-1 pa-2">
                            <span class="text-[11px] font-mono opacity-70 font-weight-bold">{{ formatDateSimple(req.created_at) }}</span>
                            <span class="pill-ref" :class="isLightMode ? 'bg-indigo-lighten-5 text-indigo-darken-3' : 'bg-indigo-darken-4 text-white'">{{ req.dev_code }}</span>
                        </div>
                        <div class="cell center pa-2">
                            <v-chip size="x-small" :color="getRequestTypeColor(req.request_type)" variant="flat" class="font-weight-black text-[10px] px-3 chip-sq w-100 justify-center shadow-sm" style="height: 22px;">
                                {{ getRequestTypeLabel(req.request_type) }}
                            </v-chip>
                        </div>
                        <div class="cell flex-column align-start justify-center pa-3">
                            <span class="text-body-2 font-weight-black text-truncate w-100 mb-1" :class="themeClasses.textPrimary">{{ getClientNames(req) }}</span>
                            <span class="text-caption opacity-70 text-truncate w-100" :class="themeClasses.textSecondary" :title="getBriefingSnippet(req)">{{ getBriefingSnippet(req) }}</span>
                        </div>
                        <div class="cell pa-3">
                            <div class="d-flex align-center gap-2">
                                <v-avatar size="28" :color="req.designer ? 'indigo' : 'grey-lighten-1'" class="shadow-sm border-sq">
                                    <span class="text-[10px] font-weight-bold text-white">{{ getInitials(req.designer?.full_name || 'Livre') }}</span>
                                </v-avatar>
                                <div class="d-flex flex-column lh-1">
                                    <span class="text-[9px] font-weight-black uppercase opacity-60" :class="themeClasses.textSecondary">Designer</span>
                                    <span class="text-caption font-weight-bold text-truncate" style="max-width: 120px;" :class="req.designer ? themeClasses.textPrimary : 'text-error'">
                                        {{ req.designer?.full_name || 'Livre / Sem Dono' }}
                                    </span>
                                </div>
                            </div>
                        </div>
                        <div class="cell center pa-2">
                            <v-chip size="small" :color="getSmartStatus(req).color" variant="flat" class="font-weight-black text-uppercase chip-sq px-3 shadow-sm" style="height: 26px; font-size: 11px;">
                                {{ getSmartStatus(req).label }}
                            </v-chip>
                        </div>
                        <div class="cell center pa-2">
                            <v-btn size="small" variant="flat" :color="isLightMode ? 'blue-grey-darken-3' : 'white'" class="btn-sq font-weight-bold text-caption shadow-sm px-4" @click="openTimeline(req)">
                                <v-icon start size="16">mdi-timeline-text-outline</v-icon> Ver Tracking
                            </v-btn>
                        </div>
                    </div>
                </div>
            </div>

            <div class="pa-5 border-t d-flex justify-space-between align-center transition-all" :class="themeClasses.cardHeader">
                <span class="text-body-2 font-weight-bold opacity-70" :class="themeClasses.textSecondary">Total: <strong>{{ myRequestsModal.items.length }}</strong> solicitações realizadas.</span>
                <v-btn variant="outlined" size="large" class="btn-sq font-weight-bold" :color="isLightMode ? 'grey-darken-3' : 'white'" @click="myRequestsModal.show = false">Fechar Painel</v-btn>
            </div>
        </v-card>
    </v-dialog>

    <v-dialog v-model="timelineModal.show" max-width="900" persistent scrim="black opacity-80" content-class="responsive-modal-container">
        <v-card class="overflow-hidden border-thin transition-all" :class="isLightMode ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-grey-darken-4 border-white-10'">
            <div class="pa-5 d-flex align-center justify-space-between transition-colors" :class="isLightMode ? 'bg-blue-grey-darken-4 text-white' : 'bg-blue-grey-darken-4 text-white border-b border-white-10'">
                <div class="d-flex align-center gap-3">
                    <div class="icon-box-sq d-flex align-center justify-center bg-white-20 text-white">
                        <v-icon size="20">mdi-timeline-clock-outline</v-icon>
                    </div>
                    <div class="d-flex flex-column">
                        <h3 class="text-h6 font-weight-black text-uppercase lh-1 mb-1 tracking-tight">Rastreamento da Solicitação</h3>
                        <span class="text-caption font-weight-bold opacity-70">Acompanhe as interações e devolutivas deste item.</span>
                    </div>
                </div>
                <v-btn icon="mdi-close" variant="tonal" size="small" color="white" class="btn-sq" @click="timelineModal.show = false"></v-btn>
            </div>

            <v-card-text class="pa-6 custom-scrollbar" style="max-height: 70vh; overflow-y: auto;">
                <div class="mb-8 d-flex flex-column flex-sm-row align-sm-center justify-space-between pa-5 rounded-lg border-thin transition-all" :class="isLightMode ? 'bg-white border-grey-lighten-2 shadow-sm' : 'bg-black-20 border-white-05'">
                    <div class="mb-3 mb-sm-0">
                        <div class="text-[11px] font-weight-black text-uppercase opacity-60 mb-1 tracking-widest" :class="themeClasses.textSecondary">Código do Lote</div>
                        <div class="text-h5 font-weight-black font-mono tracking-tight" :class="themeClasses.textPrimary">{{ timelineModal.item?.dev_code }}</div>
                    </div>
                    <div class="text-left text-sm-right">
                        <div class="text-[11px] font-weight-black text-uppercase opacity-60 mb-1 tracking-widest" :class="themeClasses.textSecondary">Status Final da Solicitação</div>
                        <v-chip size="default" :color="getSmartStatus(timelineModal.item).color" variant="flat" class="font-weight-black chip-sq px-4 shadow-sm">
                            {{ getSmartStatus(timelineModal.item).label }}
                        </v-chip>
                    </div>
                </div>

                <v-timeline density="compact" align="start" side="end" class="ml-n4">
                    <v-timeline-item
                        v-for="log in timelineModal.logs"
                        :key="log.id"
                        :dot-color="log.color"
                        size="small"
                        fill-dot
                    >
                        <v-card class="pa-5 rounded-lg border-thin shadow-sm transition-all" :class="isLightMode ? 'bg-white' : 'bg-grey-darken-3 border-white-05'" elevation="0">
                            <div class="d-flex flex-column flex-sm-row justify-sm-space-between align-sm-center gap-3 mb-4">
                                <v-chip size="small" :color="log.color" variant="flat" class="font-weight-black text-[10px] text-uppercase chip-sq px-3">
                                    {{ log.type }}
                                </v-chip>
                                <span class="text-caption font-mono opacity-70 font-weight-bold d-flex align-center gap-1" :class="themeClasses.textPrimary">
                                    <v-icon size="14">mdi-clock-outline</v-icon> {{ log.date }}
                                </span>
                            </div>

                            <div class="text-body-2 font-weight-medium mb-4" style="white-space: pre-wrap; line-height: 1.6;" :class="themeClasses.textPrimary">{{ log.message }}</div>

                            <div class="text-caption font-weight-black mb-4 opacity-80" :class="log.color === 'error' ? 'text-error' : (log.color === 'success' ? 'text-success' : 'text-info')" v-if="log.author">
                                <v-icon size="16" start>mdi-account</v-icon> Modificado por: {{ log.author }}
                            </div>

                            <div v-if="log.images && log.images.length > 0" class="d-flex gap-3 mt-2 overflow-x-auto pb-3 custom-scrollbar">
                                <v-avatar
                                    v-for="(img, idx) in log.images" :key="idx"
                                    rounded="sm" size="80"
                                    class="cursor-pointer border-thin flex-shrink-0 transition-transform"
                                    :class="isLightMode ? 'bg-grey-lighten-4' : 'bg-black-20'"
                                    style="border-radius: 6px !important;"
                                    @click="openImage(img)"
                                    @mouseover="$event.target.style.transform='scale(1.05)'"
                                    @mouseout="$event.target.style.transform='scale(1)'"
                                >
                                    <v-img :src="img" cover></v-img>
                                </v-avatar>
                            </div>
                        </v-card>
                    </v-timeline-item>
                </v-timeline>
            </v-card-text>
        </v-card>
    </v-dialog>

    <ImageModal
        :show="imageModal.show"
        :image-url="imageModal.url"
        file-name="Anexo da Solicitação"
        @close="imageModal.show = false"
    />

    <ClientFormModal
      :show="isNewCustomerModalOpen"
      @close="isNewCustomerModalOpen = false"
      @client-created="handleNewCustomer"
    />

  </div>
</template>

<script setup>
import { ref, onMounted, watch, computed } from 'vue';
import { supabase } from '@/api/supabase';
import { useUserStore } from '@/stores/user';
import { useThemeStore } from '@/stores/themeStore';
import { useRouter } from 'vue-router';
import ClientFormModal from '@/components/ClientFormModal.vue';
import ImageModal from '@/components/ImageModal.vue';
import { format, parseISO } from 'date-fns';

const themeStore = useThemeStore();
const userStore = useUserStore();
const router = useRouter();

const isLightMode = computed(() => themeStore.currentMode === 'light');

// Classes computadas rígidas para garantir o Dark Mode Perfeito
const themeClasses = computed(() => {
    if (isLightMode.value) {
        return {
            pageBg: 'theme-bg-light',
            mainWrapper: 'bg-white border-grey-lighten-2',
            formArea: 'bg-grey-lighten-5',
            sidebar: 'bg-grey-lighten-4 border-grey-lighten-2',
            itemCard: 'bg-white border-grey-lighten-2',
            cardHeader: 'bg-grey-lighten-4 border-grey-lighten-2',
            textPrimary: 'text-grey-darken-4',
            textSecondary: 'text-grey-darken-2',
            inputClass: 'theme-light text-grey-darken-4',
            uploadZone: 'upload-light text-grey-darken-4',
            attachmentCard: 'bg-white border-grey-lighten-2',
            borderClass: 'border-grey-lighten-2'
        };
    } else {
        return {
            pageBg: 'theme-bg-dark',
            mainWrapper: 'bg-surface-dark border-white-10',
            formArea: 'bg-transparent',
            sidebar: 'bg-sidebar-dark border-white-10',
            itemCard: 'bg-elevated-dark border-white-05',
            cardHeader: 'bg-black-20 border-white-05',
            textPrimary: 'text-white',
            textSecondary: 'text-white-70',
            inputClass: 'theme-dark text-white',
            uploadZone: 'upload-dark text-white',
            attachmentCard: 'bg-black-40 border-white-10',
            borderClass: 'border-white-10'
        };
    }
});

// --- STATE FORM ---
const form = ref(null);
const valid = ref(false);
const loading = ref(false);
const isNewCustomerModalOpen = ref(false);
const showSuccessModal = ref(false);
const successfulDevCode = ref('');

const requestType = ref('development'); // 'development' | 'alteration' | 'pilot'
const pilotApprovalType = ref('digital'); // 'digital' | 'fisico'

// Clientes
const clientList = ref([]);
const isSearchingClients = ref(false);
let searchTimeout = null;

const generalNotes = ref('');
const requestItems = ref([{ id: Date.now(), customer: null, notes: '', files: [], attachments_meta: [], clientSearch: '' }]);

const rules = {
  required: value => !!value || 'Campo obrigatório.',
  requiredObject: value => (!!value && typeof value === 'object' && Object.keys(value).length > 0) || 'Cliente é obrigatório.',
};

const typeLabel = computed(() => {
    if (requestType.value === 'alteration') return 'Alteração';
    if (requestType.value === 'pilot') return 'Piloto';
    return 'Novo Design';
});

const typeColor = computed(() => {
    if (requestType.value === 'alteration') return 'orange-darken-3';
    if (requestType.value === 'pilot') return 'purple-darken-2';
    return 'indigo';
});

const submitBtnText = computed(() => {
    if (requestType.value === 'alteration') return 'ENVIAR ALTERAÇÃO';
    if (requestType.value === 'pilot') return 'SOLICITAR PILOTO';
    return 'ENVIAR DESIGN';
});

const submitBtnColor = computed(() => {
    if (requestType.value === 'alteration') return 'orange-darken-3';
    if (requestType.value === 'pilot') return 'purple-darken-2';
    return 'indigo';
});


// --- STATE MY REQUESTS (HISTÓRICO) ---
const myRequestsModal = reactive({
    show: false,
    loading: false,
    items: []
});

const timelineModal = reactive({
    show: false,
    item: null,
    logs: []
});

const imageModal = reactive({ show: false, url: '' });


// --- LOGIC ---

const formatDateSimple = (d) => d ? format(new Date(d), 'dd/MM/yyyy') : '-';

// ADICIONE ESTA FUNÇÃO AQUI:
const getInitials = (name) => {
    if (!name || name === 'Sem Dono' || name === 'Livre' || name === 'Livre / Sem Dono') return '--';
    const parts = name.trim().split(' ');
    if (parts.length > 1) return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
    return name.substring(0, 2).toUpperCase();
};

const getItemsArray = (item) => {
    if (!item.design_items) return [];
    if (Array.isArray(item.design_items)) return item.design_items;
    try { return JSON.parse(item.design_items); } catch { return []; }
};

const getClientNames = (item) => {
    const items = getItemsArray(item);
    const names = items.map(i => i.customer_name).filter(Boolean);
    return names.join(', ') || 'N/A';
};

const getBriefingSnippet = (item) => {
    const items = getItemsArray(item);
    if (items.length > 0 && items[0].notes) return items[0].notes;
    return item.general_notes || 'Sem briefing.';
};

const getRequestTypeLabel = (type) => {
    if (type === 'pilot') return 'PILOTO';
    if (type === 'alteration') return 'ALTERAÇÃO';
    return 'NOVO DESIGN';
};

const getRequestTypeColor = (type) => {
    if (type === 'pilot') return 'purple-darken-2';
    if (type === 'alteration') return 'orange-darken-3';
    return 'indigo';
};

const zebraClass = (i) => isLightMode.value ? (i % 2 === 0 ? 'zebra-light-a' : 'zebra-light-b') : (i % 2 === 0 ? 'zebra-dark-a' : 'zebra-dark-b');

// --- LÓGICA DE STATUS INTELIGENTE (SMART STATUS) ---
const getCycleCount = (item) => {
    const items = getItemsArray(item);
    if (items.length === 0) return 1;
    const log = items[0].adjustment_log || '';
    const matches = log.match(/\[DEVOLUÇÃO/g);
    return matches ? matches.length + 1 : 1;
};

const getSmartStatus = (item) => {
    if (!item) return { label: '-', color: 'grey' };
    const cycles = getCycleCount(item);
    const s = item.status;

    if (s === 'completed' || s === 'approved_by_designer' || s === 'approved_by_seller') {
        return { label: 'Concluído / Aprovado', color: 'success' };
    }
    if (s === 'pending_approval') {
        return { label: 'Aprovação Pendente', color: 'warning' };
    }
    if (cycles > 1) {
        return { label: `Re-design (${cycles}x)`, color: 'error' };
    }
    return { label: 'Em Desenvolvimento', color: 'info' };
};

// --- ABRIR MODAL DE HISTÓRICO E BUSCAR DADOS ---
const openMyRequests = async () => {
    myRequestsModal.show = true;
    myRequestsModal.loading = true;
    try {
        const { data, error } = await supabase
            .from('design_requests')
            .select('*, designer:profiles!designer_id(full_name)')
            .eq('created_by', userStore.profile?.id)
            .order('created_at', { ascending: false });

        if (error) throw error;
        myRequestsModal.items = data || [];
    } catch (e) {
        console.error("Erro ao buscar histórico:", e);
    } finally {
        myRequestsModal.loading = false;
    }
};

// --- ABRIR TIMELINE DE UM ITEM ---
const openTimeline = (item) => {
    timelineModal.item = item;
    const logEntries = [];
    let idCounter = 0;

    const items = getItemsArray(item);
    const firstItem = items.length > 0 ? items[0] : null;

    // 1. Resgata o Briefing e Imagens Iniciais
    let initialText = item.general_notes || firstItem?.notes || 'Solicitação iniciada no sistema.';
    let initialAttachments = [];
    if (firstItem && firstItem.attachments && Array.isArray(firstItem.attachments)) {
        initialAttachments = firstItem.attachments;
    }

    logEntries.push({
        id: idCounter++,
        type: 'SOLICITAÇÃO ENVIADA',
        date: formatDateSimple(item.created_at),
        message: initialText,
        images: initialAttachments,
        color: 'grey-darken-1',
        author: userStore.profile?.full_name || 'Você'
    });

    // 2. Analisa o Log de Retornos e Envios usando Regex (Mesmo do Approvals.vue)
    const logStr = firstItem ? (firstItem.adjustment_log || '') : '';
    const regex = /\[(.*?) - (.*?)\]:\s*([\s\S]*?)(?=\n\[|$)/g;
    let match;

    while ((match = regex.exec(logStr)) !== null) {
        const type = match[1].trim();
        const date = match[2].trim();
        const message = match[3].trim();

        let color = 'info';
        let author = 'Sistema';

        if (type.includes('DEVOLUÇÃO') || type.includes('REJEITADO')) {
            color = 'error';
            author = userStore.profile?.full_name || 'Você';
        } else if (type.includes('ENVIO') || type.includes('APROVADO')) {
            color = 'success';
            author = item.designer?.full_name || 'Designer';
        }

        logEntries.push({
            id: idCounter++,
            type,
            date,
            message,
            images: [],
            color,
            author
        });
    }

    // 3. Verifica se tem arte final atual (Se o status for aguardando aprovação ou concluído)
    if (item.status === 'pending_approval' || item.status === 'completed' || item.status === 'approved_by_designer') {
        const finalArts = [];
        if (item.final_art_url) finalArts.push(item.final_art_url);

        const lastLog = logEntries[logEntries.length - 1];
        if (lastLog && (lastLog.type.includes('ENVIO') || lastLog.type.includes('ATUALIZAÇÃO'))) {
            lastLog.images = finalArts;
        } else if (finalArts.length > 0) {
            logEntries.push({
                id: idCounter++,
                type: 'ARTE FINAL / ENVIO',
                date: formatDateSimple(item.updated_at || item.created_at),
                message: 'Artes anexadas e enviadas para avaliação.',
                images: finalArts,
                color: 'success',
                author: item.designer?.full_name || 'Designer'
            });
        }
    }

    timelineModal.logs = logEntries.reverse();
    timelineModal.show = true;
};

const openImage = (url) => {
    imageModal.url = url;
    imageModal.show = true;
};


// --- FILE HANDLING (NOVO DESIGN) ---
const formatBytes = (bytes, decimals = 1) => {
    if (!+bytes) return '0 B';
    const k = 1024;
    const dm = decimals < 0 ? 0 : decimals;
    const sizes = ['B', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return `${parseFloat((bytes / Math.pow(k, i)).toFixed(dm))} ${sizes[i]}`;
};

const handleFileSelect = async (event, item) => {
    const newFiles = Array.from(event.target.files);
    if (!newFiles.length) return;

    item.files = [...item.files, ...newFiles];

    for (const file of newFiles) {
        const meta = {
            name: file.name,
            sizeStr: formatBytes(file.size),
            type: file.type,
            extension: file.name.split('.').pop().toUpperCase(),
            preview: null,
            resolution: null
        };

        if (file.type.startsWith('image/')) {
            const url = URL.createObjectURL(file);
            meta.preview = url;
            const img = new Image();
            img.onload = () => { meta.resolution = `${img.width}x${img.height}px`; };
            img.src = url;
        } else if (file.type === 'application/pdf') {
            meta.preview = 'https://upload.wikimedia.org/wikipedia/commons/8/87/PDF_file_icon.svg';
        }

        item.attachments_meta.push(meta);
    }
};

const removeFile = (item, index) => {
    item.files.splice(index, 1);
    const removedMeta = item.attachments_meta.splice(index, 1)[0];
    if (removedMeta.preview && removedMeta.preview.startsWith('blob:')) {
        URL.revokeObjectURL(removedMeta.preview);
    }
};

// --- CLIENT SEARCH & FILTERING (SUPABASE) ---
const normalizeStr = (str) => {
    if (!str) return '';
    return str.normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase().trim();
};

const customFilter = (value, query, item) => {
    if (!query) return true;
    const textoBuscado = normalizeStr(query);
    const nomeDoCliente = normalizeStr(item.raw.nome || item.raw.name || item.raw.razao_social || item.raw.nome_fantasia);
    const cpfCnpjDoCliente = (item.raw.cpf_cnpj || item.raw.cpf || item.raw.cnpj || '').replace(/\D/g, '');
    const numerosDaBusca = query.replace(/\D/g, '');
    return nomeDoCliente.includes(textoBuscado) || (numerosDaBusca.length > 0 && cpfCnpjDoCliente.includes(numerosDaBusca));
};

watch(() => requestItems.value.map(item => item.clientSearch), async (searches) => {
  const activeSearch = searches.find(s => s && typeof s === 'string' && s.trim().length > 2);
  if (!activeSearch) { isSearchingClients.value = false; return; }

  const isJustSelected = requestItems.value.some(item => {
      if (item.customer && item.clientSearch) {
          const nomeCliente = item.customer.nome || item.customer.name || item.customer.razao_social || item.customer.nome_fantasia || '';
          return item.clientSearch === nomeCliente;
      }
      return false;
  });

  if (isJustSelected) return;

  isSearchingClients.value = true;
  clearTimeout(searchTimeout);

  searchTimeout = setTimeout(async () => {
    try {
      const termo = activeSearch.trim();
      const termoSeguro = termo.replace(/,/g, ' ');
      const termoLimpoNumeros = termo.replace(/\D/g, '');

      let queryOr = `nome.ilike.%${termoSeguro}%,razao_social.ilike.%${termoSeguro}%,nome_fantasia.ilike.%${termoSeguro}%`;
      if (termoLimpoNumeros.length > 0) queryOr += `,cpf.ilike.%${termoLimpoNumeros}%,cnpj.ilike.%${termoLimpoNumeros}%`;

      const { data: clientsFromDb, error } = await supabase.from('customers_mj').select('*').or(queryOr).limit(30);
      if (error) throw error;

      const mappedClients = (clientsFromDb || []).map(c => ({
         ...c, id: c.gestao_click_id || c.id, nome: c.nome || c.razao_social || c.nome_fantasia, cpf_cnpj: c.cpf || c.cnpj
      }));

      const mapClientes = new Map();
      clientList.value.forEach(c => mapClientes.set(c.id, c));
      mappedClients.forEach(c => mapClientes.set(c.id, c));
      clientList.value = Array.from(mapClientes.values());
    } catch (e) { console.error("Erro busca Supabase:", e); } finally { isSearchingClients.value = false; }
  }, 400);
}, { deep: true });

const fetchCustomers = async () => {
  const { data, error } = await supabase.from('customers_mj').select('*').limit(50);
  if (!error && data) {
      clientList.value = data.map(c => ({ ...c, id: c.gestao_click_id || c.id, nome: c.nome || c.razao_social || c.nome_fantasia, cpf_cnpj: c.cpf || c.cnpj }));
  }
};

const openNewCustomerModal = () => { isNewCustomerModalOpen.value = true; };

const handleNewCustomer = (newCustomer) => {
  const mapped = { ...newCustomer, id: newCustomer.gestao_click_id || newCustomer.id, nome: newCustomer.nome || newCustomer.razao_social || newCustomer.nome_fantasia, cpf_cnpj: newCustomer.cpf || newCustomer.cnpj };
  clientList.value.unshift(mapped);
  const lastItem = requestItems.value[requestItems.value.length - 1];
  if (!lastItem.customer) lastItem.customer = mapped;
  isNewCustomerModalOpen.value = false;
};

const addItem = () => {
  requestItems.value.push({ id: Date.now(), customer: null, notes: '', files: [], attachments_meta: [], clientSearch: '' });
  setTimeout(() => {
      const container = document.querySelector('.custom-scrollbar');
      if(container) container.scrollTo({ top: container.scrollHeight, behavior: 'smooth' });
  }, 100);
};

const removeItem = (index) => { requestItems.value.splice(index, 1); };

const uploadFiles = async (item, devCode) => {
    if (!item.files || item.files.length === 0) return [];
    const uploadPromises = item.files.map(file => {
        const fileExt = file.name.split('.').pop();
        const safeCustomerName = (item.customer.nome || 'cliente').replace(/[^a-zA-Z0-9]/g, '_');
        const fileName = `${devCode}/${safeCustomerName}_${Date.now()}_${Math.random().toString(36).substr(2, 5)}.${fileExt}`;
        return supabase.storage.from('arts').upload(fileName, file);
    });
    const results = await Promise.all(uploadPromises);
    const urls = [];
    for (const result of results) {
        if (!result.error) {
            const { data } = supabase.storage.from('arts').getPublicUrl(result.data.path);
            urls.push(data.publicUrl);
        }
    }
    return urls;
};

const submitRequest = async () => {
  const { valid: isValid } = await form.value.validate();
  if (!isValid) return;

  loading.value = true;
  try {
    const prefix = requestType.value === 'alteration' ? 'ALT' : requestType.value === 'pilot' ? 'PIL' : 'DEV';
    const tempDevCode = `${prefix}-${Date.now().toString().slice(-6)}`;
    const designItemsPayload = [];
    const approvalText = requestType.value === 'pilot' ? ` | Aprovação: ${pilotApprovalType.value === 'digital' ? 'Digital' : 'Física'}` : '';

    for (const item of requestItems.value) {
      const attachmentUrls = await uploadFiles(item, tempDevCode);
      designItemsPayload.push({
        customer_id: item.customer.id,
        customer_name: item.customer.nome,
        notes: item.notes,
        attachments: attachmentUrls,
        meta_summary: item.attachments_meta.map(m => `${m.extension} (${m.sizeStr})`).join(', ') + approvalText,
        pilot_approval_type: requestType.value === 'pilot' ? pilotApprovalType.value : null
      });
    }

    const { data: devCode, error } = await supabase.rpc('create_design_request', {
      p_general_notes: generalNotes.value,
      p_store_id: userStore.profile?.store_id,
      p_design_items: designItemsPayload,
      p_created_by: userStore.profile?.id,
      p_request_type: requestType.value
    });

    if (error) throw error;

    let finalCode = devCode || tempDevCode;
    if (requestType.value === 'alteration') finalCode = finalCode.replace('DEV', 'ALT');
    if (requestType.value === 'pilot') finalCode = finalCode.replace('DEV', 'PIL');

    successfulDevCode.value = finalCode;
    showSuccessModal.value = true;
  } catch (error) {
    console.error('Error submitting:', error);
    alert('Erro ao enviar: ' + error.message);
  } finally {
    loading.value = false;
  }
};

const resetForm = () => {
    requestItems.value = [{ id: Date.now(), customer: null, notes: '', files: [], attachments_meta: [], clientSearch: '' }];
    generalNotes.value = '';
    requestType.value = 'development';
    pilotApprovalType.value = 'digital';
    if (form.value) form.value.resetValidation();
};

const startNewRequest = () => { showSuccessModal.value = false; resetForm(); };
const goToKanban = () => { router.push('/design'); };

onMounted(() => { fetchCustomers(); });
</script>

<style scoped lang="scss">
/* ====== FUNDOS BLINDADOS (DARK/LIGHT MODE) ====== */
.theme-bg-light { background-color: #f5f5f7 !important; }
.theme-bg-dark { background-color: #000000 !important; }

.bg-surface-dark { background-color: #18181b !important; }
.bg-elevated-dark { background-color: #27272a !important; }
.bg-sidebar-dark { background-color: #121212 !important; }

.bg-black-20 { background-color: rgba(0,0,0,0.2) !important; }
.bg-black-40 { background-color: rgba(0,0,0,0.4) !important; }
.bg-white-20 { background-color: rgba(255,255,255,0.2) !important; }
.text-white-70 { color: rgba(255,255,255,0.7) !important; }

/* Backgrounds Súteis */
.ambient-glow { position: absolute; top: -100px; left: 0; width: 100%; height: 400px; pointer-events: none; z-index: 0; }
.glow-light { background: radial-gradient(ellipse at 50% 0%, rgba(63, 81, 181, 0.08) 0%, rgba(255, 255, 255, 0) 70%); }
.glow-dark { background: radial-gradient(ellipse at 50% 0%, rgba(92, 107, 192, 0.15) 0%, rgba(0, 0, 0, 0) 70%); }

.background-carousel-wrapper { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 0; pointer-events: none; }
.background-overlay { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 1; background: radial-gradient(circle at center, rgba(0, 0, 0, 0.5), rgba(0, 0, 0, 0.98)); backdrop-filter: blur(10px); }

/* ====== BREADCRUMB HOVER ====== */
.hover-text { transition: color 0.2s ease; }
.hover-text-indigo:hover { color: #3949ab !important; }
.hover-text-white:hover { color: #ffffff !important; }

/* ====== ELEMENTOS QUADRADOS / CINZELADOS (OVERRIDE DO VUETIFY) ====== */
.layout-wrapper { border-radius: 6px !important; }
.border-sq { border-radius: 4px !important; }
.btn-sq { border-radius: 4px !important; text-transform: none !important; letter-spacing: 0.2px; }
.chip-sq { border-radius: 4px !important; }
.badge-sq { border-radius: 3px !important; }
.icon-box-sq { width: 44px; height: 44px; border-radius: 6px; }

.shadow-soft { box-shadow: 0 4px 16px rgba(0,0,0,0.06) !important; }
.shadow-sm { box-shadow: 0 2px 8px rgba(0,0,0,0.04) !important; }

/* ====== TIPOGRAFIA ====== */
.tracking-tight { letter-spacing: -1px !important; }
.tracking-widest { letter-spacing: 0.08em !important; }
.lh-1 { line-height: 1; }
.lh-1-4 { line-height: 1.4; }
.premium-label { font-size: 10px; font-weight: 800; text-transform: uppercase; color: #757575; display: block; margin-bottom: 6px; letter-spacing: 0.5px; }
.v-theme--dark .premium-label { color: #9e9e9e; }

/* ====== INPUTS PREMIUM ====== */
.premium-input :deep(.v-field) { border-radius: 4px !important; }
.theme-light :deep(.v-field) { background: #ffffff !important; border: 1px solid rgba(0,0,0,0.12) !important; box-shadow: 0 1px 2px rgba(0,0,0,0.01) !important; }
.theme-dark :deep(.v-field) { background: rgba(0,0,0,0.2) !important; border: 1px solid rgba(255,255,255,0.12) !important; box-shadow: none !important; color: white !important; }
.theme-light :deep(.v-field__outline), .theme-dark :deep(.v-field__outline) { display: none !important; }

/* ====== SIDEBAR ====== */
.sidebar-config { width: 320px; min-width: 320px; }
@media (max-width: 1200px) { .sidebar-config { width: 300px; min-width: 300px; } }
@media (max-width: 960px) { .sidebar-config { width: 100%; min-width: 100%; border-left: none !important; border-top: 1px solid var(--v-border-color); } }

/* Segmented Control (Apple Style) */
.segmented-control { display: flex; padding: 3px; border-radius: 4px; gap: 3px; }
.seg-light { background: rgba(0,0,0,0.04); border: 1px solid rgba(0,0,0,0.08); }
.seg-dark { background: rgba(255,255,255,0.05); border: 1px solid rgba(255,255,255,0.08); }
.seg-item { flex: 1; text-align: center; padding: 6px 4px; font-size: 10px; font-weight: 700; text-transform: uppercase; border-radius: 3px; cursor: pointer; transition: all 0.2s; color: #757575; }
.seg-dark .seg-item { color: #9e9e9e; }
.seg-light .seg-item:hover { color: #212121; }
.seg-dark .seg-item:hover { color: #ffffff; }
.seg-light .seg-active { background: #ffffff; color: #1a237e; box-shadow: 0 1px 2px rgba(0,0,0,0.05); border: 1px solid #e0e0e0; }
.seg-dark .seg-active { background: #3949ab; color: #ffffff; box-shadow: 0 1px 4px rgba(0,0,0,0.3); border: 1px solid rgba(255,255,255,0.05); }

.theme-alert-dark { background: rgba(0,0,0,0.2) !important; }
.custom-radio :deep(.v-label) { opacity: 1 !important; }
.status-dot { width: 6px; height: 6px; border-radius: 50%; flex-shrink: 0; }

/* ====== UPLOAD ZONE & ANEXOS ====== */
.upload-zone { border-radius: 4px; border: 1px dashed; padding: 24px 16px; text-align: center; cursor: pointer; }
.upload-light { border-color: rgba(0,0,0,0.15); background: transparent; }
.upload-light:hover { border-color: #3949ab; background: rgba(57, 73, 171, 0.03); }
.upload-dark { border-color: rgba(255,255,255,0.15); background: transparent; }
.upload-dark:hover { border-color: #5c6bc0; background: rgba(92, 107, 192, 0.05); }

.attachment-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(110px, 1fr)); gap: 10px; }
.bg-checkerboard { background-image: linear-gradient(45deg, rgba(128,128,128,0.1) 25%, transparent 25%), linear-gradient(-45deg, rgba(128,128,128,0.1) 25%, transparent 25%), linear-gradient(45deg, transparent 75%, rgba(128,128,128,0.1) 75%), linear-gradient(-45deg, transparent 75%, rgba(128,128,128,0.1) 75%); background-size: 10px 10px; background-position: 0 0, 0 5px, 5px -5px, -5px 0px; }

.step-indicator { width: 24px; height: 24px; border-radius: 4px; display: flex; align-items: center; justify-content: center; font-size: 11px; font-weight: 800; }
.mobile-action-bar { position: sticky; bottom: 0; padding: 12px; z-index: 50; box-shadow: 0 -4px 16px rgba(0,0,0,0.05); }

.custom-scrollbar::-webkit-scrollbar { width: 6px; height: 6px; }
.custom-scrollbar::-webkit-scrollbar-track { background: transparent; }
.custom-scrollbar::-webkit-scrollbar-thumb { background: rgba(128, 128, 128, 0.3); border-radius: 3px; }

.transition-all { transition: all 0.3s cubic-bezier(0.25, 0.8, 0.25, 1); }
.transition-colors { transition: background-color 0.3s ease, border-color 0.3s ease, color 0.3s ease; }

/* ======== MODAIS E RESPONSIVIDADE ======== */
@media (max-width: 600px) {
    /* Força os modais a ocuparem a tela inteira no mobile (Widescreen Fake) */
    :global(.responsive-modal-container > .v-overlay__content > .v-card) {
        height: 100vh !important;
        max-height: 100vh !important;
        border-radius: 0 !important;
        margin: 0 !important;
    }
}

/* ======== ESTILOS GRID DE HISTÓRICO (EXCEL-LIKE) ======== */
.history-grid-card { box-shadow: 0 12px 30px rgba(0,0,0,0.12); }
.grid-layout-requests { grid-template-columns: 140px 120px minmax(250px, 1fr) 200px 160px 140px; }
.grid-scroll { scrollbar-gutter: stable both-edges; }

.grid-header, .grid-row { display: grid; align-items: stretch; width: 100%; gap: 0; min-width: 1000px; }
.cell { padding: 6px 12px; display: flex; align-items: center; border-right: 1px solid rgba(0,0,0,0.08); border-bottom: 1px solid rgba(0,0,0,0.08); min-height: 48px; overflow: hidden; }
.center { justify-content: center; text-align: center; }
.header-text { font-size: 11px; font-weight: 900; text-transform: uppercase; letter-spacing: 0.5px; line-height: 1.2; }
.grid-header .cell { min-height: 44px; }

.grid-surface-light .cell { background: #f5f7fa; color: rgba(0,0,0,0.8); border-color: rgba(0,0,0,0.10) !important; }
.grid-surface-dark .cell { background: rgba(255,255,255,0.08); color: rgba(255,255,255,0.80); border-color: rgba(255,255,255,0.10) !important; }

.grid-row-light .cell { border-color: rgba(0,0,0,0.06) !important; }
.zebra-light-a .cell { background: #ffffff; }
.zebra-light-b .cell { background: #f9f9f9; }
.grid-row-light:hover .cell { background: #e3f2fd !important; }

.grid-row-dark .cell { border-color: rgba(255,255,255,0.06) !important; }
.zebra-dark-a .cell { background: rgba(255,255,255,0.04); }
.zebra-dark-b .cell { background: rgba(255,255,255,0.02); }
.grid-row-dark:hover .cell { background: rgba(255,255,255,0.08) !important; }

.sticky-head { position: sticky; top: 0; z-index: 20; box-shadow: 0 4px 12px rgba(0,0,0,0.08); }
.pill-ref { font-size: 11px; font-weight: 900; font-family: monospace; padding: 4px 8px; border-radius: 4px; white-space: nowrap; }

.fade-slide-enter-active, .fade-slide-leave-active { transition: all 0.3s ease; }
.fade-slide-enter-from { opacity: 0; transform: translateX(-10px); }
.fade-slide-leave-to { opacity: 0; transform: translateX(10px); }

.icon-circle-lg { width: 64px; height: 64px; display: flex; align-items: center; justify-content: center; }
</style>
