<template>
  <div
    class="approvals-layout font-sans fill-height d-flex flex-column relative overflow-hidden"
    :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 text-grey-darken-4' : 'bg-glass-dark text-white'"
  >
    <div v-if="themeStore.currentMode !== 'light'" class="background-carousel-wrapper">
      <v-carousel cycle height="100%" hide-delimiters :show-arrows="false" interval="15000" class="fill-height">
        <v-carousel-item src="@/assets/1.jpg" cover></v-carousel-item>
        <v-carousel-item src="@/assets/2.jpg" cover></v-carousel-item>
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
            <span class="opacity-70">Gestão Comercial</span>
            <span class="mx-2 opacity-50">></span>
            <span class="font-weight-bold">Central de Aprovações</span>
          </div>
          <div class="text-h6 font-weight-black tracking-tight leading-none mt-1" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">
            Aprovações Pendentes
          </div>
        </div>

        <div class="d-flex align-center gap-2">
           <v-btn title="Atualizar Lista" icon size="small" variant="text" @click="fetchAllData" :disabled="loadingData">
              <v-icon>mdi-refresh</v-icon>
           </v-btn>
        </div>
      </div>

      <div class="px-6 py-3 flex-shrink-0">
        <v-row dense>
          <v-col cols="12" sm="6">
            <v-card
              class="kpi-card kpi-rect hover-elevate py-3 px-4 cursor-pointer transition-all"
              :class="getKpiClass(currentTab === 'orders', 'info')"
              v-ripple
              elevation="2"
              @click="currentTab = 'orders'"
            >
              <div class="kpi-bg-icon"><v-icon>mdi-receipt-text-check</v-icon></div>
              <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                <div class="d-flex align-center" style="gap: 8px;">
                  <v-icon size="18" class="opacity-80">mdi-receipt-text-check</v-icon>
                  <span class="kpi-label">Pedidos para Aprovação</span>
                </div>
                <div class="kpi-number-group my-1">
                  <span class="kpi-value">{{ orderApprovals.length }}</span>
                  <span class="text-caption ml-2 opacity-70 font-weight-bold">pendentes</span>
                </div>
              </div>
            </v-card>
          </v-col>

          <v-col cols="12" sm="6">
            <v-card
              class="kpi-card kpi-rect hover-elevate py-3 px-4 cursor-pointer transition-all"
              :class="getKpiClass(currentTab === 'developments', 'purple')"
              v-ripple
              elevation="2"
              @click="currentTab = 'developments'"
            >
              <div class="kpi-bg-icon"><v-icon>mdi-palette-swatch</v-icon></div>
              <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                <div class="d-flex align-center" style="gap: 8px;">
                  <v-icon size="18" class="opacity-80">mdi-palette-swatch</v-icon>
                  <span class="kpi-label">Artes & Pilotos (Design)</span>
                </div>
                <div class="kpi-number-group my-1">
                  <span class="kpi-value">{{ developmentApprovals.filter(d => d.status !== 'completed').length }}</span>
                  <span class="text-caption ml-2 opacity-70 font-weight-bold">aguardando</span>
                </div>
              </div>
            </v-card>
          </v-col>
        </v-row>
      </div>

      <div class="px-6 pt-0 pb-2 flex-shrink-0">
         <div class="controls-bar d-flex align-center" :class="themeStore.currentMode === 'light' ? 'controls-light' : 'controls-dark'">
            <v-btn-toggle v-model="currentTab" mandatory density="compact" color="primary" variant="text" class="font-weight-bold">
                <v-btn value="orders" class="text-caption">
                    <v-icon start size="small">mdi-receipt</v-icon> Pedidos ({{ orderApprovals.length }})
                </v-btn>
                <v-btn value="developments" class="text-caption">
                    <v-icon start size="small">mdi-palette</v-icon> Artes & Pilotos ({{ developmentApprovals.length }})
                </v-btn>
            </v-btn-toggle>
         </div>
      </div>

      <div class="flex-grow-1 px-6 pb-0 overflow-hidden d-flex flex-column relative position-relative">

        <div
          v-if="loadingData || isRendering"
          class="loading-overlay-container d-flex flex-column justify-center align-center"
          :class="themeStore.currentMode === 'light' ? 'overlay-light' : 'overlay-dark'"
        >
          <div class="auto-scroll-track w-100 position-absolute opacity-20" style="z-index: 0;">
             <div v-for="i in 10" :key="i" class="d-flex align-center gap-4 mb-4 pa-4 mx-6 border rounded-lg border-opacity-10" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-3' : 'bg-black-20'">
                <div class="skeleton-box rounded" style="width: 40px; height: 40px;"></div>
                <div class="skeleton-box rounded flex-grow-1" style="height: 20px;"></div>
                <div class="skeleton-box rounded d-none d-sm-block" style="width: 150px; height: 20px;"></div>
                <div class="skeleton-box rounded" style="width: 80px; height: 30px;"></div>
             </div>
          </div>

          <div class="particles-area">
            <v-icon
              v-for="p in particles"
              :key="p.id"
              class="particle-icon"
              :color="p.color"
              :style="{ left: p.left, animationDelay: p.delay, animationDuration: p.duration, fontSize: p.size, '--x-dir': p.xDir }"
            >
              {{ p.icon }}
            </v-icon>
          </div>

          <div class="loading-text text-caption mb-4 font-weight-black text-uppercase tracking-widest text-indigo-darken-2 position-relative z-10">
            CARREGANDO APROVAÇÕES
          </div>

          <div class="progress-bar-bg position-relative z-10">
            <div class="progress-bar-fill" :style="{ width: `${renderProgress}%` }">
              <div class="progress-glow"></div>
            </div>
          </div>

          <div class="text-caption font-mono mt-3 opacity-60 font-weight-black position-relative z-10">
            {{ Math.round(renderProgress) }}%
          </div>
        </div>

        <v-card
          v-show="!loadingData && !isRendering"
          class="flex-grow-1 d-flex flex-column rounded-0 border-thin overflow-hidden"
          :class="themeStore.currentMode === 'light' ? 'bg-white shadow-sm' : 'glass-card border-white-05'"
          :elevation="0"
        >
            <div v-if="currentTab === 'orders'" class="fill-height d-flex flex-column relative">
                <div class="grid-scroll flex-grow-1 overflow-y-auto custom-scroll relative">
                    <div class="grid-header sticky-head grid-layout-orders" :class="themeStore.currentMode === 'light' ? 'grid-surface-light' : 'grid-surface-dark'">
                        <div class="cell center header-text">ID</div>
                        <div class="cell header-text">Cliente</div>
                        <div class="cell header-text">Detalhes / Itens</div>
                        <div class="cell center header-text">Designer</div>
                        <div class="cell center header-text">Entrada</div>
                        <div class="cell center header-text">Ação</div>
                    </div>

                    <div v-if="orderApprovals.length === 0" class="d-flex flex-column align-center justify-center py-10 opacity-60">
                        <v-icon size="48" color="grey">mdi-check-all</v-icon>
                        <span class="text-caption font-weight-bold mt-2">Nenhum pedido pendente.</span>
                    </div>
                    <div
                        v-else
                        v-for="(order, index) in paginatedOrders"
                        :key="order.id"
                        class="grid-row grid-layout-orders"
                        :class="[themeStore.currentMode === 'light' ? 'grid-row-light' : 'grid-row-dark', zebraClass(index)]"
                    >
                        <div class="cell center"><span class="pill-ref">#{{ String(order.order_number || order.id).substring(0,4) }}</span></div>
                        <div class="cell font-weight-bold text-caption">{{ order.customer_name }}</div>
                        <div class="cell text-caption opacity-80">{{ getPendingItemsCount(order) }} itens aguardando aprovação</div>
                        <div class="cell center text-caption font-weight-bold">{{ getDesignerName(order) }}</div>
                        <div class="cell center text-caption font-mono">{{ formatDateSimple(order.created_at) }}</div>
                        <div class="cell center">
                            <v-btn :to="{ name: 'ApproveOrder', params: { id: order.id } }" size="small" color="primary" variant="flat" class="font-weight-bold btn-3d">
                                Analisar
                            </v-btn>
                        </div>
                    </div>
                </div>

                <div class="flex-shrink-0 border-t px-4 py-2 d-flex flex-column flex-md-row align-center justify-space-between z-20" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-surface-variant border-top-white-05'">
                    <div class="text-caption opacity-80 mb-2 mb-md-0">
                        <strong>{{ orderApprovals.length }}</strong> registros
                    </div>
                    <v-pagination
                        v-model="pageOrders"
                        :length="pageCountOrders"
                        :total-visible="5"
                        density="compact"
                        active-color="primary"
                        variant="tonal"
                        size="small"
                    ></v-pagination>
                </div>
            </div>

            <div v-if="currentTab === 'developments'" class="fill-height d-flex flex-column relative">
                <div class="grid-scroll flex-grow-1 overflow-y-auto custom-scroll relative">
                    <div class="grid-header sticky-head grid-layout-devs" :class="themeStore.currentMode === 'light' ? 'grid-surface-light' : 'grid-surface-dark'">
                        <div class="cell center header-text">Img</div>
                        <div class="cell center header-text">Tipo / Cód.</div>
                        <div class="cell header-text">Estampa / Ref</div>
                        <div class="cell header-text">Cliente(s)</div>
                        <div class="cell header-text">Solicitante</div>
                        <div class="cell header-text">Designer</div>
                        <div class="cell center header-text">Data Envio</div>
                        <div class="cell center header-text">Ciclos</div>
                        <div class="cell center header-text">Status</div>
                        <div class="cell center header-text">Ações</div>
                    </div>

                    <div v-if="developmentApprovals.length === 0" class="d-flex flex-column align-center justify-center py-10 opacity-60">
                        <v-icon size="48" color="grey">mdi-check-all</v-icon>
                        <span class="text-caption font-weight-bold mt-2">Nenhuma arte ou piloto pendente.</span>
                    </div>
                    <div
                        v-else
                        v-for="(item, index) in paginatedDevs"
                        :key="item.id"
                        class="grid-row grid-layout-devs"
                        :class="[themeStore.currentMode === 'light' ? 'grid-row-light' : 'grid-row-dark', zebraClass(index)]"
                    >
                        <div class="cell center pa-1">
                            <v-avatar rounded="sm" size="40" class="cursor-pointer border-thin bg-grey-lighten-4 position-relative" @click="openImageViewer(getAllImages(item))">
                                <v-img :src="item.final_art_url" cover></v-img>

                                <div v-if="getAllImages(item).length > 1"
                                    class="position-absolute bottom-0 right-0 bg-black text-white px-1 rounded-sm"
                                    style="font-size: 9px; opacity: 0.85; line-height: 1.2; margin: 2px;">
                                    +{{ getAllImages(item).length - 1 }}
                                </div>
                            </v-avatar>
                        </div>

                        <div class="cell center flex-column justify-center gap-1 pa-1">
                            <span class="pill-ref bg-purple-lighten-5 text-purple-darken-3 text-truncate w-100" style="max-width: 100px;">{{ item.dev_code }}</span>
                            <v-chip
                                size="x-small"
                                :color="item.request_type === 'pilot' ? 'purple-darken-2' : (item.request_type === 'alteration' ? 'orange-darken-3' : 'info')"
                                variant="flat"
                                class="font-weight-black text-[9px] px-1 w-100 justify-center"
                                style="height: 16px; max-width: 100px;"
                            >
                                {{ item.request_type === 'pilot' ? 'PILOTO' : (item.request_type === 'alteration' ? 'ALTERAÇÃO' : 'NOVO') }}
                            </v-chip>
                            <v-chip
                                v-if="item.request_type === 'pilot' && item.design_items?.[0]?.pilot_approval_type"
                                size="x-small"
                                :color="item.design_items[0].pilot_approval_type === 'digital' ? 'blue' : 'warning'"
                                variant="outlined"
                                class="font-weight-bold text-[9px] px-1 w-100 justify-center"
                                style="height: 14px; border-width: 1px; max-width: 100px;"
                            >
                                {{ item.design_items[0].pilot_approval_type === 'digital' ? 'DIGITAL' : 'FÍSICO' }}
                            </v-chip>
                        </div>

                        <div class="cell font-weight-bold text-caption text-truncate" :title="item.new_stamp?.name">
                            {{ item.new_stamp?.name || 'Sem nome' }}
                            <div class="text-[9px] opacity-60 font-weight-normal">{{ getClientNames(item) }}</div>
                        </div>

                        <div class="cell text-caption opacity-80 text-truncate" :title="getClientNames(item)">{{ getClientNames(item) }}</div>

                        <div class="cell text-caption font-weight-medium text-truncate">
                            <v-icon size="12" class="mr-1 opacity-50">mdi-account-tie</v-icon>
                            {{ item.creator?.full_name || 'Vendedor' }}
                        </div>

                        <div class="cell text-caption font-weight-bold text-truncate text-primary">
                            {{ item.designer?.full_name || 'Sem Dono' }}
                        </div>

                        <div class="cell center">
                            <span class="text-[10px] font-mono opacity-80">{{ formatDateSimple(item.created_at) }}</span>
                        </div>

                        <div class="cell center">
                            <v-badge v-if="getCycleCount(item) > 1" color="error" :content="getCycleCount(item)" inline></v-badge>
                            <span v-else class="text-[10px] opacity-50 font-weight-bold">1º Ciclo</span>
                        </div>

                        <div class="cell center">
                            <v-chip
                                size="small"
                                :color="item.status === 'completed' ? 'success' : (getCycleCount(item) > 1 ? 'error' : 'warning')"
                                variant="flat"
                                class="solid-chip chip-3d font-weight-black text-uppercase px-2"
                                style="height: 22px; font-size: 10px;"
                            >
                                <v-icon start size="small" v-if="item.status === 'completed'" class="mr-1">mdi-check</v-icon>
                                {{ item.status === 'completed' ? 'Aprovado' : (getCycleCount(item) > 1 ? 'Retorno' : 'Pendente') }}
                            </v-chip>
                        </div>

                        <div class="cell center actions-inline">
                            <v-btn title="Ver Histórico Completo de Ajustes" icon size="small" class="action-btn action-history btn-3d" variant="flat" @click="openHistoryModal(item)">
                                <v-icon size="16">mdi-history</v-icon>
                            </v-btn>

                            <template v-if="item.status === 'completed'">
                                <v-btn title="Compartilhar Arte via WhatsApp" icon size="small" class="action-btn action-share btn-3d" variant="flat" @click="openShareModal(item, 'whatsapp')">
                                    <v-icon size="16">mdi-share-variant</v-icon>
                                </v-btn>
                                <span class="text-[10px] text-success font-weight-bold ml-2">Concluído</span>
                            </template>

                            <template v-else>
                                <v-menu location="bottom end" open-on-hover :close-on-content-click="true">
                                    <template v-slot:activator="{ props }">
                                        <v-btn v-bind="props" title="Opções de Compartilhamento" icon size="small" class="action-btn action-share btn-3d" variant="flat">
                                            <v-icon size="16">mdi-share-variant</v-icon>
                                        </v-btn>
                                    </template>
                                    <v-list density="compact" class="share-menu pa-0" nav>
                                        <v-list-item @click="openShareModal(item, 'whatsapp')" density="compact" style="min-height: 32px;" class="ma-0">
                                            <template v-slot:prepend><v-icon size="14" color="success">mdi-whatsapp</v-icon></template>
                                            <v-list-item-title class="text-[10px] font-weight-bold">WhatsApp</v-list-item-title>
                                        </v-list-item>
                                        <v-list-item @click="openShareModal(item, 'email')" density="compact" style="min-height: 32px;" class="ma-0">
                                            <template v-slot:prepend><v-icon size="14" color="info">mdi-email-outline</v-icon></template>
                                            <v-list-item-title class="text-[10px] font-weight-bold">E-mail</v-list-item-title>
                                        </v-list-item>
                                    </v-list>
                                </v-menu>

                                <v-btn title="Solicitar Ajuste e Retornar" icon size="small" class="action-btn action-revert btn-3d" variant="flat" @click="openRejectModal(item)">
                                    <v-icon size="16">mdi-undo-variant</v-icon>
                                </v-btn>

                                <v-btn :title="item.request_type === 'pilot' ? 'Aprovar Piloto' : 'Aprovar Arte e Liberar'" icon size="small" class="action-btn action-pay btn-3d" variant="flat" @click="approveRequest(item)" :loading="loadingAction === item.id">
                                    <v-icon size="16">mdi-check</v-icon>
                                </v-btn>

                                <v-btn title="Excluir Chamado" icon size="small" class="action-btn action-del btn-3d" variant="flat" @click="deleteItem(item)">
                                    <v-icon size="16">mdi-delete-outline</v-icon>
                                </v-btn>
                            </template>
                        </div>
                    </div>
                </div>

                <div class="flex-shrink-0 border-t px-4 py-2 d-flex flex-column flex-md-row align-center justify-space-between z-20" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-surface-variant border-top-white-05'">
                    <div class="text-caption opacity-80 mb-2 mb-md-0">
                        <strong>{{ developmentApprovals.length }}</strong> registros
                    </div>
                    <v-pagination
                        v-model="pageDevs"
                        :length="pageCountDevs"
                        :total-visible="5"
                        density="compact"
                        active-color="primary"
                        variant="tonal"
                        size="small"
                    ></v-pagination>
                </div>
            </div>
        </v-card>
      </div>
    </div>

    <v-dialog v-model="historyModal.show" max-width="650" persistent scrim="black opacity-80">
        <v-card class="rounded-lg overflow-hidden" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-surface-card'">
            <div class="pa-4 bg-blue-grey-darken-3 text-white d-flex align-center justify-space-between">
                <div class="d-flex align-center gap-3">
                    <v-icon>mdi-timeline-text</v-icon>
                    <h3 class="text-subtitle-1 font-weight-black text-uppercase">Linha do Tempo de Aprovação</h3>
                </div>
                <v-btn icon="mdi-close" variant="text" size="small" color="white" @click="historyModal.show = false"></v-btn>
            </div>

            <v-card-text class="pa-6 custom-scroll" style="max-height: 65vh; overflow-y: auto;">
                <div class="mb-5 d-flex align-center justify-space-between bg-grey-lighten-4 pa-3 rounded border-thin">
                    <div>
                        <div class="text-caption font-weight-black text-uppercase text-primary mb-1">Código da Solicitação</div>
                        <div class="text-subtitle-1 font-weight-black">{{ historyModal.item?.dev_code }}</div>
                    </div>
                    <div class="text-right">
                        <div class="text-caption font-weight-bold text-medium-emphasis mb-1">Estampa / Referência</div>
                        <div class="text-body-2 font-weight-bold">{{ historyModal.item?.new_stamp?.name || 'Sem nome' }}</div>
                    </div>
                </div>

                <v-timeline density="compact" align="start" side="end" class="ml-n4">
                    <v-timeline-item
                        v-for="log in historyModal.logs"
                        :key="log.id"
                        :dot-color="log.color"
                        size="small"
                        fill-dot
                    >
                        <v-card class="pa-3 rounded-lg border-thin shadow-sm" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-background'" elevation="0">
                            <div class="d-flex justify-space-between align-center mb-2">
                                <v-chip size="x-small" :color="log.color" variant="flat" class="font-weight-bold text-[10px] text-uppercase">
                                    {{ log.type }}
                                </v-chip>
                                <span class="text-[10px] font-mono opacity-70 font-weight-bold d-flex align-center gap-1">
                                    <v-icon size="10">mdi-clock-outline</v-icon> {{ log.date }}
                                </span>
                            </div>

                            <div class="text-caption font-weight-medium mt-1 mb-2" style="white-space: pre-wrap; line-height: 1.4;">{{ log.message }}</div>

                            <div class="text-[10px] text-primary font-weight-black mb-2" v-if="log.author">
                                <v-icon size="12" start>mdi-account-edit</v-icon> Por: {{ log.author }}
                            </div>

                            <div v-if="log.images && log.images.length > 0" class="d-flex gap-2 mt-2 overflow-x-auto pb-2 custom-scroll">
                                <v-avatar
                                    v-for="(img, idx) in log.images" :key="idx"
                                    rounded="sm" size="60"
                                    class="cursor-pointer border-thin bg-grey-lighten-3 hover-elevate flex-shrink-0"
                                    @click="openImageViewer(log.images)"
                                >
                                    <v-img :src="img" cover></v-img>
                                </v-avatar>
                            </div>
                        </v-card>
                    </v-timeline-item>
                </v-timeline>
            </v-card-text>
            <div class="pa-4 border-t d-flex justify-end bg-grey-lighten-5">
                <v-btn variant="flat" class="btn-3d font-weight-bold px-6 text-none" color="blue-grey-darken-3" @click="historyModal.show = false">Fechar Histórico</v-btn>
            </div>
        </v-card>
    </v-dialog>

    <v-dialog v-model="showRejectModalState" max-width="500" persistent scrim="black opacity-80">
        <v-card class="rounded-lg overflow-hidden" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-surface-card'">
            <div class="pa-4 bg-error text-white d-flex align-center gap-3">
                <v-icon>mdi-alert-circle-outline</v-icon>
                <h3 class="text-subtitle-1 font-weight-black text-uppercase">Solicitar Ajuste ao Designer</h3>
            </div>
            <v-card-text class="pa-6">
                <div class="d-flex align-center gap-2 mb-4 bg-error-lighten-5 pa-2 rounded border-error-lighten-4">
                    <v-icon color="error" size="small">mdi-information</v-icon>
                    <span class="text-caption text-error-darken-3 font-weight-bold">
                        Esta ação retornará o item para a coluna "Desenvolvimento" do Kanban.
                    </span>
                </div>
                <p class="text-body-2 mb-2 font-weight-bold">Qual o motivo da devolução?</p>
                <v-textarea
                    v-model="rejectReason"
                    placeholder="Descreva o que precisa ser alterado na arte..."
                    variant="outlined"
                    auto-grow
                    rows="3"
                    class="ui-field"
                    hide-details
                    autofocus
                ></v-textarea>
            </v-card-text>
            <div class="pa-4 border-t d-flex justify-end gap-2 bg-grey-lighten-5">
                <v-btn variant="outlined" class="btn-3d font-weight-bold" color="grey-darken-2" @click="closeRejectModal" :disabled="isRejecting">Cancelar</v-btn>
                <v-btn
                    color="error"
                    variant="flat"
                    class="btn-3d font-weight-black"
                    @click="confirmRejection"
                    :loading="isRejecting"
                    :disabled="!rejectReason.trim()"
                >
                    <v-icon start>mdi-send</v-icon> Confirmar Devolução
                </v-btn>
            </div>
        </v-card>
    </v-dialog>

    <v-dialog v-model="shareModal.show" max-width="500" persistent scrim="black opacity-80">
        <v-card class="rounded-lg overflow-hidden" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-surface-card'">
            <div class="pa-4 text-white d-flex align-center gap-3" :class="shareModal.type === 'whatsapp' ? 'bg-green-darken-2' : 'bg-blue-darken-2'">
                <v-icon>{{ shareModal.type === 'whatsapp' ? 'mdi-whatsapp' : 'mdi-email' }}</v-icon>
                <h3 class="text-subtitle-1 font-weight-black text-uppercase">Compartilhar via {{ shareModal.type === 'whatsapp' ? 'WhatsApp' : 'E-mail' }}</h3>
            </div>
            <v-card-text class="pa-6">
                <div v-if="shareModal.item" class="mb-4 d-flex justify-center bg-grey-lighten-4 pa-2 rounded border-thin">
                    <img :src="shareModal.item.final_art_url" style="max-height: 150px; border-radius: 4px;" />
                </div>

                <v-textarea
                    v-model="shareModal.message"
                    label="Mensagem para o Cliente"
                    variant="outlined"
                    auto-grow
                    rows="4"
                    class="ui-field"
                    hide-details
                ></v-textarea>

                <div v-if="shareModal.type === 'whatsapp'" class="mt-2 text-caption opacity-70">
                    <v-icon size="small" start>mdi-information-outline</v-icon>
                    No computador, a imagem será baixada e o WhatsApp Web abrirá para você colar.
                </div>
            </v-card-text>
            <div class="pa-4 border-t d-flex justify-end gap-2 bg-grey-lighten-5">
                <v-btn variant="outlined" class="btn-3d font-weight-bold" color="grey-darken-2" @click="shareModal.show = false" :disabled="shareModal.loading">Cancelar</v-btn>
                <v-btn
                    :color="shareModal.type === 'whatsapp' ? 'success' : 'info'"
                    variant="flat"
                    class="btn-3d font-weight-black"
                    @click="confirmShare"
                    :loading="shareModal.loading"
                >
                    <v-icon start>mdi-share-variant</v-icon> Enviar Agora
                </v-btn>
            </div>
        </v-card>
    </v-dialog>

    <ImageModal :show="showImageModal" :images="selectedImages" @close="showImageModal = false" />
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, reactive, nextTick, watch } from 'vue';
import { supabase } from '@/api/supabase';
import { useUserStore } from '@/stores/user';
import { useThemeStore } from '@/stores/theme';
import { useAppStore } from '@/stores/app';
import { format } from 'date-fns';
import ImageModal from '@/components/ImageModal.vue';

const userStore = useUserStore();
const themeStore = useThemeStore();
const appStore = useAppStore();

const currentTab = ref('developments');
const loadingData = ref(true);
const loadingAction = ref<string | null>(null);

const orderApprovals = ref<any[]>([]);
const developmentApprovals = ref<any[]>([]);

// LOADING SKELETON
const isRendering = ref(false);
const renderProgress = ref(0);

const particleIcons = ['mdi-palette', 'mdi-check-all', 'mdi-image-multiple', 'mdi-account-tie'];
const particleColors = ['indigo-lighten-2', 'purple-lighten-2', 'cyan-lighten-2', 'teal-lighten-2'];
const particles = Array.from({ length: 15 }).map((_, i) => ({
  id: i,
  icon: particleIcons[Math.floor(Math.random() * particleIcons.length)],
  color: particleColors[Math.floor(Math.random() * particleColors.length)],
  left: `${30 + Math.random() * 40}%`,
  delay: `${Math.random() * 2}s`,
  duration: `${1.5 + Math.random() * 1.5}s`,
  size: `${14 + Math.random() * 16}px`,
  xDir: `${(Math.random() - 0.5) * 120}px`
}));

// Paginação
const pageOrders = ref(1);
const pageDevs = ref(1);
const itemsPerPage = 30;

const paginatedOrders = computed(() => {
    const start = (pageOrders.value - 1) * itemsPerPage;
    return orderApprovals.value.slice(start, start + itemsPerPage);
});
const pageCountOrders = computed(() => Math.ceil(orderApprovals.value.length / itemsPerPage));

const paginatedDevs = computed(() => {
    const start = (pageDevs.value - 1) * itemsPerPage;
    return developmentApprovals.value.slice(start, start + itemsPerPage);
});
const pageCountDevs = computed(() => Math.ceil(developmentApprovals.value.length / itemsPerPage));

const showImageModal = ref(false);
const selectedImages = ref<string[]>([]);

const showRejectModalState = ref(false);
const rejectReason = ref('');
const itemToReject = ref<any>(null);
const isRejecting = ref(false);

// State para o Modal de Histórico Inteligente
interface HistoryLog {
    id: number;
    type: string;
    date: string;
    message: string;
    images: string[];
    color: string;
    author: string;
}

const historyModal = reactive({
    show: false,
    item: null as any,
    logs: [] as HistoryLog[]
});

// Share Modal State
const shareModal = reactive({
  show: false,
  message: '',
  item: null as any,
  type: 'whatsapp' as 'whatsapp' | 'email',
  loading: false
});

const getKpiClass = (active: boolean, colorType: string) => {
    if (active) {
        return `kpi-active-border bg-gradient-${colorType} text-white`;
    }
    return `bg-gradient-${colorType} text-white opacity-80`;
};

const safeJsonParse = (str: string) => {
    try { return JSON.parse(str); } catch { return []; }
};

const getItemsArray = (item: any) => {
    if (!item.design_items) return [];
    if (Array.isArray(item.design_items)) return item.design_items;
    if (typeof item.design_items === 'string') return safeJsonParse(item.design_items);
    return [];
};

const getAllImages = (item: any) => {
    let images: string[] = [];
    if (item.final_art_url) images.push(item.final_art_url);

    if (item.additional_arts) {
        const extraArts = typeof item.additional_arts === 'string'
            ? safeJsonParse(item.additional_arts)
            : item.additional_arts;

        if (Array.isArray(extraArts)) {
            images.push(...extraArts.filter(url => typeof url === 'string'));
        }
    }
    return images;
};

const openImageViewer = (images: string[]) => {
    selectedImages.value = images;
    showImageModal.value = true;
};

// --- LOGICA INTELIGENTE DO HISTÓRICO (Com Imagens, Briefing e Nomes Corrigidos) ---
const openHistoryModal = (item: any) => {
    historyModal.item = item;
    const logEntries: HistoryLog[] = [];
    let idCounter = 0;

    const items = getItemsArray(item);
    const firstItem = items.length > 0 ? items[0] : null;

    // 1. Resgata o Briefing e Imagens Iniciais
    let initialText = item.general_notes || item.description || item.observations || '';
    let initialAttachments: string[] = [];

    if (firstItem) {
        if (!initialText) initialText = firstItem.description || firstItem.observations || firstItem.briefing || firstItem.details?.observation || firstItem.details?.briefing || '';
        if (firstItem.attachments && Array.isArray(firstItem.attachments)) initialAttachments = firstItem.attachments;
    }

    if (!initialText) initialText = 'Nenhuma descrição detalhada foi fornecida na abertura do chamado.';

    logEntries.push({
        id: idCounter++,
        type: 'SOLICITAÇÃO INICIAL',
        date: formatDateSimple(item.created_at),
        message: initialText,
        images: initialAttachments,
        color: 'grey-darken-1',
        author: item.creator?.full_name || 'Solicitante'
    });

    // 2. Analisa o Log de Retornos e Envios (Regex)
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
            author = item.creator?.full_name || 'Solicitante';
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

    if (logEntries.length === 1 && logStr.trim() !== '') {
        logEntries.push({
            id: idCounter++,
            type: 'REGISTRO GERAL',
            date: '-',
            message: logStr.trim(),
            images: [],
            color: 'info',
            author: 'Sistema'
        });
    }

    // 3. Associa as Artes Atuais ao evento mais recente do Designer
    const currentArts = getAllImages(item);
    if (currentArts.length > 0) {
        const lastEnvio = [...logEntries].reverse().find(l => l.type.includes('ENVIO') || l.type.includes('ATUALIZAÇÃO'));

        if (lastEnvio) {
            lastEnvio.images = currentArts;
        } else {
            logEntries.push({
                id: idCounter++,
                type: 'ARTE FINAL / ENVIO',
                date: formatDateSimple(item.updated_at),
                message: 'Artes anexadas e enviadas para avaliação.',
                images: currentArts,
                color: 'success',
                author: item.designer?.full_name || 'Designer'
            });
        }
    }

    historyModal.logs = logEntries.reverse();
    historyModal.show = true;
};

// ===============================================
// PROGRESS BAR LOADING (Animação Suave)
// ===============================================
let renderInterval: any = null;

const runLoadingAnimation = () => {
  isRendering.value = true;
  renderProgress.value = 0;
  if (renderInterval) clearInterval(renderInterval);

  const targetDuration = 1200;
  const intervalTime = 20;
  const step = (100 / (targetDuration / intervalTime));

  renderInterval = setInterval(() => {
    renderProgress.value += step;
    if (renderProgress.value >= 100) {
      clearInterval(renderInterval);
      renderProgress.value = 100;
      setTimeout(() => {
          isRendering.value = false;
      }, 200);
    }
  }, intervalTime);
};

const fetchAllData = async () => {
    if (!userStore.isLoggedIn) return;
    loadingData.value = true;
    console.group("🔄 Fetching Approval Data");

    try {
        // Pedidos - Fix no Join do Designer
        const { data: orders, error: orderErr } = await supabase
            .from('orders')
            .select('id, customer_name, created_at, order_number, designer:profiles!designer_id(full_name), creator:profiles!created_by(full_name), order_items(*)')
            .eq('order_items.status', 'customer_approval')
            .order('created_at', { ascending: true });

        if (orderErr) throw orderErr;
        orderApprovals.value = (orders || []).filter(o => o.order_items && o.order_items.some((i: any) => i.status === 'customer_approval'));
        pageOrders.value = 1;

        // Desenvolvimentos & Pilotos (Internos)
        const { data: devs, error: devErr } = await supabase
            .from('design_requests')
            .select(`
                *,
                new_stamp:new_stamp_id(*),
                designer:profiles!designer_id(full_name),
                creator:profiles!created_by(full_name)
            `)
            .in('status', ['pending_approval', 'completed'])
            .eq('created_by', userStore.profile?.id)
            .order('created_at', { ascending: false });

        if (devErr) throw devErr;

        developmentApprovals.value = (devs || []).map(item => ({
            ...item,
            design_items: typeof item.design_items === 'string' ? safeJsonParse(item.design_items) : item.design_items
        }));
        pageDevs.value = 1;

    } catch (e: any) {
        console.error("Erro no Fetch:", e);
        appStore.showSnackbar("Erro ao carregar dados: " + e.message, "error");
    } finally {
        loadingData.value = false;
        runLoadingAnimation(); // Inicia a animação após puxar os dados
        console.groupEnd();
    }
};

const approveRequest = async (item: any) => {
    loadingAction.value = item.id;
    try {
        if (item.new_stamp_id) {
            const { error: stampError } = await supabase.from('stamp_library').update({ is_approved_for_sale: true }).eq('id', item.new_stamp_id);
            if (stampError) throw new Error("Erro ao atualizar biblioteca: " + stampError.message);
        }

        const { error: requestError } = await supabase.from('design_requests').update({ status: 'completed' }).eq('id', item.id);
        if (requestError) throw new Error("Erro ao finalizar solicitação: " + requestError.message);

        const index = developmentApprovals.value.findIndex(d => d.id === item.id);
        if (index !== -1) {
            developmentApprovals.value[index].status = 'completed';
        }

        const msg = item.request_type === 'pilot' ? "Piloto aprovado e finalizado com sucesso!" : "Estampa aprovada e liberada para venda!";
        appStore.showSnackbar(msg, "success");

    } catch (error: any) {
        console.error(error);
        appStore.showSnackbar(error.message, "error");
    } finally {
        loadingAction.value = null;
    }
};

const deleteItem = async (item: any) => {
    if (!confirm(`Tem certeza que deseja excluir a solicitação ${item.dev_code}? Esta ação não pode ser desfeita.`)) return;

    loadingAction.value = item.id;
    try {
        const { error } = await supabase.from('design_requests').delete().eq('id', item.id);
        if (error) throw error;

        developmentApprovals.value = developmentApprovals.value.filter(d => d.id !== item.id);
        appStore.showSnackbar("Solicitação excluída com sucesso.", "success");
    } catch (e: any) {
        appStore.showSnackbar("Erro ao excluir: " + e.message, "error");
    } finally {
        loadingAction.value = null;
    }
};

const openShareModal = (item: any, type: 'whatsapp' | 'email') => {
  shareModal.item = item;
  shareModal.type = type;
  const clientName = getClientNames(item) || 'Cliente';

  if (type === 'whatsapp') {
      shareModal.message = `Olá ${clientName}! Segue a arte para aprovação do código *${item.dev_code}* (${item.new_stamp?.name || 'Piloto'}).\n\nPodemos prosseguir com a produção?`;
  } else {
      shareModal.message = `Prezado(a) ${clientName},\n\nSegue em anexo a arte para aprovação referente ao código ${item.dev_code}.\n\nAguardo seu retorno para prosseguirmos.`;
  }

  shareModal.show = true;
};

const confirmShare = async () => {
  if (!shareModal.item) return;
  shareModal.loading = true;

  try {
    const imageUrl = shareModal.item.final_art_url;

    if (shareModal.type === 'whatsapp') {
        if (!imageUrl) throw new Error("URL da imagem não encontrada.");

        const response = await fetch(imageUrl);
        const blob = await response.blob();
        const file = new File([blob], `arte_${shareModal.item.dev_code}.jpg`, { type: blob.type });

        const shareData = {
          files: [file],
          title: `Aprovação de Arte/Piloto - ${shareModal.item.dev_code}`,
          text: shareModal.message
        };

        if (navigator.canShare && navigator.canShare(shareData)) {
          await navigator.share(shareData);
        } else {
          const link = document.createElement('a');
          link.href = URL.createObjectURL(blob);
          link.download = `arte_${shareModal.item.dev_code}.jpg`;
          document.body.appendChild(link);
          link.click();
          document.body.removeChild(link);

          const whatsappUrl = `https://wa.me/?text=${encodeURIComponent(shareModal.message)}`;
          window.open(whatsappUrl, '_blank');

          appStore.showSnackbar("Imagem baixada! Cole-a no WhatsApp que foi aberto.", "info");
        }
    } else {
        const subject = `Aprovação - ${shareModal.item.dev_code}`;
        const mailtoUrl = `mailto:?subject=${encodeURIComponent(subject)}&body=${encodeURIComponent(shareModal.message)}`;
        window.open(mailtoUrl, '_blank');
        appStore.showSnackbar("Cliente de e-mail aberto. Anexe a imagem se necessário.", "info");
    }

    shareModal.show = false;

  } catch (error: any) {
    console.error("Erro ao compartilhar:", error);
    appStore.showSnackbar("Erro ao compartilhar: " + error.message, "error");
  } finally {
    shareModal.loading = false;
  }
};

const openRejectModal = (item: any) => {
    itemToReject.value = item;
    rejectReason.value = '';
    showRejectModalState.value = true;
};

const closeRejectModal = () => {
    showRejectModalState.value = false;
    itemToReject.value = null;
    isRejecting.value = false;
};

const confirmRejection = async () => {
    if (!itemToReject.value || !rejectReason.value.trim()) return;

    isRejecting.value = true;
    const item = itemToReject.value;

    try {
        const timestamp = new Date().toLocaleString('pt-BR');
        const newNoteEntry = `[DEVOLUÇÃO SOLICITANTE - ${timestamp}]: ${rejectReason.value}`;

        let currentItems = getItemsArray(item);
        if (!Array.isArray(currentItems)) currentItems = [currentItems];

        const updatedItems = currentItems.map((di: any) => {
            const prevLog = di.adjustment_log || '';
            return {
                ...di,
                adjustment_log: prevLog ? `${prevLog}\n${newNoteEntry}` : newNoteEntry
            };
        });

        // Retorna para alteração/correção no kanban do designer
        const { error } = await supabase
            .from('design_requests')
            .update({
                status: 'design_pending',
                final_art_url: null,
                additional_arts: null,
                design_items: updatedItems,
                request_type: item.request_type === 'pilot' ? 'pilot' : 'alteration'
            })
            .eq('id', item.id);

        if (error) throw error;

        if (item.designer_id) {
            await supabase.from('notifications').insert({
                recipient_id: item.designer_id,
                sender_id: userStore.profile?.id,
                content: `Ajuste solicitado em ${item.dev_code}. Verifique o Kanban.`,
                redirect_url: '/design-kanban'
            });
        }

        appStore.showSnackbar("Devolvido para o designer com sucesso!", "success");
        developmentApprovals.value = developmentApprovals.value.filter(d => d.id !== item.id);
        closeRejectModal();

    } catch (error: any) {
        console.error("Erro CRÍTICO na rejeição:", error);
        appStore.showSnackbar("Erro ao processar devolução: " + error.message, "error");
    } finally {
        isRejecting.value = false;
    }
};

const formatDateSimple = (d: string) => d ? format(new Date(d), 'dd/MM/yyyy') : '-';
const getPendingItemsCount = (order: any) => order.order_items?.filter((i:any) => i.status === 'customer_approval').length || 0;
const getDesignerName = (obj: any) => obj.designer?.full_name || 'Não atribuído';
const getClientNames = (item: any) => {
    const items = getItemsArray(item);
    const names = items.map((i: any) => i.customer_name).filter(Boolean);
    return names.join(', ') || 'N/A';
};
const getCycleCount = (item: any) => {
    const items = getItemsArray(item);
    if (items.length === 0) return 1;
    const log = items[0].adjustment_log || '';
    const matches = log.match(/\[DEVOLUÇÃO/g);
    return matches ? matches.length + 1 : 1;
};

const zebraClass = (i: number) => themeStore.currentMode !== 'light' ? (i % 2 === 0 ? 'zebra-dark-a' : 'zebra-dark-b') : (i % 2 === 0 ? 'zebra-light-a' : 'zebra-light-b');

onMounted(() => {
    fetchAllData();
});
</script>

<style scoped lang="scss">
.approvals-layout { position: relative; }
.bg-glass-dark { background: rgba(10,10,12,0.85); }
.bg-glass-header { background: rgba(20,20,24,0.55); backdrop-filter: blur(14px); }
.border-bottom-white-05 { border-bottom: 1px solid rgba(255,255,255,0.08); }
.controls-bar { border: 1px solid rgba(0,0,0,0.08); padding: 10px; }

/* LOADING SKELETON AUTOSCROLL */
.loading-overlay-container { position: absolute; inset: 0; z-index: 50; overflow: hidden; background: inherit; }
.auto-scroll-track { animation: autoScroll 4s ease-in-out infinite alternate; filter: blur(1px); }
@keyframes autoScroll { 0% { transform: translateY(0); } 100% { transform: translateY(-20%); } }
.skeleton-box { background: linear-gradient(90deg, rgba(150,150,150,0.1) 25%, rgba(150,150,150,0.2) 50%, rgba(150,150,150,0.1) 75%); background-size: 200% 100%; animation: shimmer 1.5s infinite linear; }
@keyframes shimmer { 0% { background-position: 200% 0; } 100% { background-position: -200% 0; } }

.overlay-light { background: rgba(255, 255, 255, 0.85); backdrop-filter: blur(6px); }
.overlay-dark { background: rgba(20, 20, 24, 0.85); backdrop-filter: blur(6px); }

.loading-text { font-size: 13px; animation: pulse-text 1.5s infinite; }
@keyframes pulse-text { 0%, 100% { opacity: 0.6; text-shadow: 0 0 4px rgba(63, 81, 181, 0); } 50% { opacity: 1; text-shadow: 0 0 10px rgba(63, 81, 181, 0.8); } }

.progress-bar-bg { width: 280px; height: 6px; background: rgba(128, 128, 128, 0.15); border-radius: 6px; overflow: hidden; box-shadow: inset 0 1px 3px rgba(0,0,0,0.2); }
.progress-bar-fill { height: 100%; background: linear-gradient(90deg, #3F51B5, #5C6BC0); border-radius: 6px; box-shadow: 0 0 12px rgba(92, 107, 192, 0.6); position: relative; transition: width 0.1s linear; }
.progress-glow { position: absolute; top: 0; right: 0; bottom: 0; width: 20px; background: rgba(255, 255, 255, 0.8); filter: blur(4px); animation: glow-move 1s linear infinite; }
@keyframes glow-move { 0% { transform: translateX(-20px); opacity: 0; } 50% { opacity: 1; } 100% { transform: translateX(10px); opacity: 0; } }

.particles-area { position: absolute; bottom: calc(50% - 20px); width: 100%; height: 200px; pointer-events: none; z-index: 0; }
.particle-icon { position: absolute; bottom: 0; opacity: 0; animation: floatUp infinite ease-out; }
@keyframes floatUp { 0% { transform: translate(0, 0) scale(0.3) rotate(0deg); opacity: 0; } 20% { opacity: 0.9; } 80% { opacity: 0.5; } 100% { transform: translate(var(--x-dir), -140px) scale(1.6) rotate(180deg); opacity: 0; } }


/* EFEITOS 3D */
.btn-3d { border-radius: 6px !important; box-shadow: 0 3px 5px rgba(0,0,0,0.15), inset 0 2px 0 rgba(255,255,255,0.25) !important; transition: transform 0.1s ease, box-shadow 0.1s ease; text-transform: none !important; }
.btn-3d:active { transform: translateY(2px); box-shadow: 0 1px 2px rgba(0,0,0,0.15), inset 0 1px 0 rgba(255,255,255,0.2) !important; }
.chip-3d { border-radius: 6px !important; box-shadow: 0 3px 5px rgba(0,0,0,0.12), inset 0 1px 0 rgba(255,255,255,0.25) !important; text-shadow: 0 1px 2px rgba(0,0,0,0.25); }
.solid-chip { display: inline-flex; align-items: center; justify-content: center; height: 28px; padding: 0 12px; font-weight: 900; color: #fff; text-transform: uppercase; white-space: nowrap; }

/* CABEÇALHO FIXO DA GRID */
.sticky-head { position: sticky; top: 0; z-index: 20; box-shadow: 0 8px 16px -4px rgba(0, 0, 0, 0.12); }
.bg-glass-dark .sticky-head { box-shadow: 0 8px 20px -4px rgba(0, 0, 0, 0.4); }

/* VARIÁVEIS DE GRID */
.approvals-layout {
    --grid-cols-orders: 80px 200px 1fr 200px 150px 120px;
    --grid-cols-devs: 60px 110px 220px 1fr 140px 150px 100px 80px 110px 180px;
}

.grid-scroll { scrollbar-gutter: stable both-edges; }
.custom-scroll::-webkit-scrollbar { width: 8px; height: 8px; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.35); border-radius: 6px; }
.custom-scroll::-webkit-scrollbar-track { background: transparent; }

.grid-header, .grid-row { display: grid; align-items: stretch; width: 100%; gap: 0; }
.grid-layout-orders { grid-template-columns: var(--grid-cols-orders); }
.grid-layout-devs { grid-template-columns: var(--grid-cols-devs); }

.grid-row {
    content-visibility: auto;
    contain-intrinsic-size: 60px;
    will-change: transform;
}

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

.header-text { font-size: 11px; font-weight: 800; text-transform: uppercase; letter-spacing: 0.5px; line-height: 1.2; }
.grid-header .cell { min-height: 44px; font-weight: 800; text-transform: uppercase; letter-spacing: 0.5px; line-height: 1.2; }
.center { justify-content: center; text-align: center; }

/* THEMES GRID */
.grid-surface-light .cell { background: #f5f7fa; color: rgba(0,0,0,0.9); border-color: rgba(0,0,0,0.12) !important; }
.grid-row-light .cell { border-color: rgba(0,0,0,0.08) !important; }
.zebra-light-a .cell { background: #ffffff; }
.zebra-light-b .cell { background: #f0f4f8; }
.grid-row-light:hover .cell { background: #e3f2fd !important; cursor: pointer; }

.grid-surface-dark .cell {
  background: rgba(255,255,255,0.08) !important;
  color: rgba(255,255,255,0.80) !important;
  border-color: rgba(255,255,255,0.10) !important;
  backdrop-filter: none !important;
}
.grid-row-dark .cell { background: rgba(255,255,255,0.04); border-color: rgba(255,255,255,0.08) !important; color: rgba(255,255,255,0.85); }
.zebra-dark-a .cell { background: rgba(255,255,255,0.04) !important; }
.zebra-dark-b .cell { background: rgba(255,255,255,0.015) !important; }
.grid-row-dark:hover .cell { background: rgba(255,255,255,0.07) !important; cursor: pointer; }

/* KPI Cards */
.kpi-card { color: white; position: relative; min-height: 100px; overflow: hidden; border: 1px solid rgba(0,0,0,0.08); }
.kpi-rect { border-radius: 0 !important; }
.kpi-bg-icon { position: absolute; right: -20px; bottom: -20px; opacity: 0.15; transform: rotate(-15deg); }
.kpi-bg-icon .v-icon { font-size: 100px; color: inherit; }
.bg-gradient-info { background: linear-gradient(135deg, #0288d1, #005b9f); }
.bg-gradient-purple { background: linear-gradient(135deg, #7b1fa2, #4a148c); }
.kpi-label { font-size: 12px; font-weight: 900; letter-spacing: .2px; text-transform: uppercase; }
.kpi-value { font-size: 24px; font-weight: 900; }
.kpi-active-border { border: 2px solid white !important; transform: scale(1.01); box-shadow: 0 4px 20px rgba(0,0,0,0.2); }

/* Elements */
.pill-ref { font-size: 11px !important; font-weight: 900; font-family: monospace; padding: 4px 6px; border-radius: 6px; white-space: nowrap; }
.actions-inline { display: flex; gap: 4px; justify-content: center; flex-wrap: nowrap !important; }
.action-btn { width: 28px !important; height: 28px !important; color: #fff !important; border-radius: 6px !important; }
.action-history { background: #00838f !important; }
.action-pay { background: #2e7d32 !important; }
.action-revert { background: #f57f17 !important; }
.action-share { background: #25D366 !important; }
.action-del { background: #FF5252 !important; }

/* Modal Backgrounds */
.background-carousel-wrapper { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 0; pointer-events: none; opacity: 0.4; }
.background-overlay { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 1; background: radial-gradient(circle at center, rgba(15, 15, 19, 0.6), rgba(15, 15, 19, 0.98)); backdrop-filter: blur(8px); }
</style>
