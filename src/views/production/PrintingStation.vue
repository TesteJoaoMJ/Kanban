<template>
  <div
    class="printing-layout font-sans fill-height d-flex flex-column relative overflow-hidden"
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
        class="header-bar px-6 py-4 d-flex align-center justify-space-between flex-shrink-0 flex-wrap gap-3"
        :class="themeStore.currentMode === 'light' ? 'bg-white border-b border-grey-lighten-2 shadow-sm' : 'bg-glass-header border-bottom-white-05'"
      >
        <div class="d-flex align-center">
          <div class="bg-cyan-darken-4 pa-3 mr-4 d-flex align-center justify-center rounded-0 shadow-lg" style="width: 56px; height: 56px;">
            <v-icon color="white" size="36">mdi-printer-3d-nozzle</v-icon>
          </div>
          <div class="d-flex flex-column">
            <div class="breadcrumb text-caption d-flex align-center text-uppercase font-weight-bold letter-spacing-1">
              <span class="opacity-70">Industrial</span>
              <v-icon size="x-small" class="mx-2 opacity-50">mdi-chevron-right</v-icon>
              <span class="text-cyan-darken-1">Estação de Impressão</span>
            </div>
            <div class="text-h5 font-weight-black tracking-tight leading-none mt-1 d-flex align-center gap-2">
              Painel de Operador
              <v-chip v-if="companyStore.isDemoMode" size="small" color="purple-accent-4" class="font-weight-bold chip-3d text-white ml-2">MODO DEMO ATIVO</v-chip>
            </div>
          </div>
        </div>

        <div class="d-flex align-center flex-wrap" style="gap: 16px;">
          <v-btn-toggle
            v-model="activeView"
            mandatory
            density="compact"
            variant="outlined"
            class="btn-group-rect rounded-lg border-thin bg-transparent btn-3d"
            divided
            :color="themeStore.currentMode === 'light' ? 'cyan-darken-3' : 'cyan-lighten-1'"
            @update:model-value="handleViewChange"
          >
            <v-btn value="queue" class="px-4 font-weight-black text-caption text-uppercase">
              <v-icon start size="small">mdi-printer-3d-nozzle-outline</v-icon> Fila Atual
            </v-btn>
            <v-btn value="history" class="px-4 font-weight-black text-caption text-uppercase">
              <v-icon start size="small">mdi-history</v-icon> Histórico de Liberação
            </v-btn>
          </v-btn-toggle>

          <v-btn
            variant="flat"
            class="btn-3d font-weight-black"
            height="40"
            color="cyan-darken-3"
            prepend-icon="mdi-refresh"
            @click="refreshData"
          >
            ATUALIZAR
          </v-btn>
        </div>
      </div>

      <div class="px-6 py-4 flex-shrink-0" v-if="activeView === 'queue'">
        <v-row dense>
          <v-col cols="12" md="4">
            <v-card class="kpi-card kpi-rect bg-gradient-info hover-elevate py-4 px-5" elevation="4">
              <div class="kpi-bg-icon"><v-icon>mdi-tray-full</v-icon></div>
              <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                <span class="kpi-label">FILA DE ESPERA</span>
                <div class="kpi-number-group my-2">
                  <span class="kpi-value">{{ queueItems.length }}</span>
                  <span class="text-body-2 font-weight-bold opacity-70 ml-2 text-uppercase">Rolos Pendentes</span>
                </div>
                <div class="kpi-footer">Aguardando Início (Inclui Retrabalhos)</div>
              </div>
            </v-card>
          </v-col>

          <v-col cols="12" md="4">
            <v-card class="kpi-card kpi-rect bg-gradient-warning hover-elevate py-4 px-5" elevation="4">
              <div class="kpi-bg-icon"><v-icon>mdi-printer-3d-nozzle-outline</v-icon></div>
              <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                <span class="kpi-label">IMPRIMINDO AGORA</span>
                <div class="kpi-number-group my-2">
                  <span class="kpi-value">{{ activeItems.length }}</span>
                  <span class="text-body-2 font-weight-bold opacity-70 ml-2 text-uppercase">Máquinas Ativas</span>
                </div>
                <div class="kpi-footer">Em execução</div>
              </div>
            </v-card>
          </v-col>

          <v-col cols="12" md="4">
            <v-card class="kpi-card kpi-rect bg-gradient-success hover-elevate py-4 px-5" elevation="4">
              <div class="kpi-bg-icon"><v-icon>mdi-chart-timeline-variant</v-icon></div>
              <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                <span class="kpi-label">METRAGEM TOTAL</span>
                <div class="kpi-number-group my-2">
                  <span class="kpi-value">{{ totalMetersDisplay }}</span>
                  <span class="text-body-2 font-weight-bold opacity-70 ml-2 text-uppercase">Metros</span>
                </div>
                <div class="kpi-footer">Carga de Trabalho Atual</div>
              </div>
            </v-card>
          </v-col>
        </v-row>
      </div>

      <div class="px-6 pt-0 pb-2 flex-shrink-0">
        <div
          class="controls-bar d-flex flex-column rounded-0 border-thin shadow-sm"
          :class="themeStore.currentMode === 'light' ? 'controls-light' : 'controls-dark'"
        >
          <div class="d-flex align-center justify-space-between flex-wrap px-2" style="gap: 12px;">
            <div class="d-flex gap-2" v-if="activeView === 'queue'">
              <v-btn
                v-for="opt in statusFilters"
                :key="opt.value"
                :color="currentStatusFilter === opt.value ? 'cyan-darken-3' : (themeStore.currentMode === 'light' ? 'grey-lighten-3' : 'grey-darken-3')"
                :variant="'flat'"
                class="btn-3d font-weight-bold"
                height="40"
                @click="currentStatusFilter = opt.value"
              >
                <v-icon start size="small" class="mr-1">{{ opt.icon }}</v-icon>
                {{ opt.label }}
              </v-btn>
            </div>
            <div class="text-caption font-weight-black opacity-70 text-uppercase d-flex align-center gap-2" v-else>
               <v-icon>mdi-history</v-icon> Últimos itens já impressos
            </div>

            <div class="spacer"></div>

            <div class="search-wrap d-flex align-center" :class="themeStore.currentMode === 'light' ? 'search-light' : 'search-dark'">
              <v-icon :color="themeStore.currentMode === 'light' ? 'grey-darken-1' : 'white-70'">mdi-magnify</v-icon>
              <input
                v-model="searchText"
                type="text"
                placeholder="BUSCAR OP, REFERÊNCIA..."
                class="clean-input flex-grow-1 text-uppercase font-weight-bold ml-2"
              />
            </div>
          </div>
        </div>
      </div>

      <div class="flex-grow-1 px-6 pb-0 overflow-hidden d-flex flex-column">
        <v-card
          class="flex-grow-1 d-flex flex-column rounded-0 border-thin overflow-hidden grid-host position-relative"
          :class="themeStore.currentMode === 'light' ? 'bg-white shadow-sm' : 'glass-card border-white-05'"
          elevation="0"
          :style="{ '--grid-cols': gridCols }"
        >
          <div class="grid-scroll flex-grow-1 overflow-auto custom-scroll" ref="scrollContainer">
            <div
              class="grid-header sticky-head"
              :class="themeStore.currentMode === 'light' ? 'grid-surface-light' : 'grid-surface-dark'"
            >
              <div class="cell center header-text border-r">Seq</div>
              <div class="cell center header-text border-r">Arte</div>
              <div class="cell header-text border-r">Referência</div>
              <div class="cell header-text border-r">Cliente / Pedido</div>

              <div class="cell center header-text border-r" v-if="activeView === 'queue'">Máquina</div>
              <div class="cell center header-text border-r" v-if="activeView === 'queue'">Avisos / Falhas</div>
              <template v-else>
                <div class="cell center header-text border-r">Máquina</div>
                <div class="cell center header-text border-r">Operador</div>
                <div class="cell center header-text border-r">Data</div>
                <div class="cell center header-text border-r">Hora</div>
              </template>

              <div class="cell center header-text border-r">Volume</div>
              <div class="cell center header-text border-r">Status</div>
              <div class="cell center header-text">Ações</div>
            </div>

            <div v-if="!store.loading && !isRendering && displayedData.length === 0" class="d-flex flex-column justify-center align-center h-100 opacity-60 gap-3 py-10">
              <div class="bg-grey-lighten-4 pa-6 rounded-0 d-flex align-center justify-center border-thin">
                <v-icon size="64" color="grey">mdi-printer-off</v-icon>
              </div>
              <div class="text-center">
                <div class="text-h6 font-weight-black text-grey-darken-1 text-uppercase">Nenhum item encontrado</div>
                <div class="text-caption text-grey font-weight-bold">Ajuste os filtros ou aguarde novas liberações.</div>
              </div>
            </div>

            <template v-else>
              <div
                v-for="(item, index) in displayedData"
                :key="item.id"
                class="grid-row"
                :class="[
                  zebraClass(index),
                  item.status === 'printing' ? (themeStore.currentMode === 'light' ? 'row-active-light' : 'row-active-dark') : '',
                  isItemInError(item) ? 'row-error-pulse' : ''
                ]"
              >
                <div class="cell center font-weight-black opacity-50 font-mono border-r">
                  {{ getRowIndex(index) }}
                </div>

                <div class="cell center pa-2 border-r">
                   <div class="hint-tooltip" data-title="Clique para ver a estampa em Alta Qualidade">
                       <div class="icon-3d-wrapper cursor-pointer" @click="openImage(item)">
                           <v-icon size="20" class="icon-3d" :color="themeStore.currentMode === 'light' ? 'cyan-darken-3' : 'cyan-lighten-3'">mdi-tshirt-crew</v-icon>
                           <div class="icon-3d-shine"></div>
                       </div>
                   </div>
                </div>

                <div class="cell border-r">
                  <div class="d-flex flex-column min-w-0">
                    <span class="list-text font-weight-black text-uppercase text-truncate">{{ item.stamp_ref }}</span>
                  </div>
                </div>

                <div class="cell border-r">
                  <div class="d-flex flex-column min-w-0">
                    <span class="list-text font-weight-bold text-truncate text-body-2">{{ item.order?.customer_name }}</span>
                    <div class="d-flex align-center mt-1">
                      <v-icon size="12" class="mr-1 opacity-50">mdi-file-document-outline</v-icon>
                      <span class="list-text opacity-70 font-mono font-weight-bold">OP #{{ item.order?.order_number }}</span>
                    </div>
                  </div>
                </div>

                <div class="cell center border-r" v-if="activeView === 'queue'">
                  <v-chip
                    v-if="item.status === 'printing'"
                    class="font-weight-bold chip-3d"
                    size="small"
                    color="deep-purple-darken-2"
                    variant="flat"
                    label
                  >
                    <v-icon start size="small">mdi-printer</v-icon>
                    <span class="text-truncate">{{ getCurrentLogMachine(item) }}</span>
                  </v-chip>
                  <span v-else class="text-caption opacity-40 font-weight-bold">-</span>
                </div>

                <div class="cell center border-r" v-if="activeView === 'queue'">
                   <div v-if="isItemInError(item)" class="d-flex flex-column align-center w-100 py-1">
                     <span class="text-[10px] text-red-darken-3 font-weight-black text-uppercase mb-1 text-center leading-tight">Falha na<br/>Calandra</span>
                     <v-btn size="x-small" color="red-darken-3" class="font-weight-black animate-bounce btn-3d" variant="flat" @click.stop="openErrorDetails(item)">
                       <v-icon start size="12">mdi-camera</v-icon> FOTO / DEFEITO
                     </v-btn>
                   </div>
                   <span v-else class="text-caption opacity-40 font-weight-bold">-</span>
                </div>

                <template v-else>
                   <div class="cell center border-r">
                     <span class="text-caption font-weight-bold opacity-70 text-truncate" :title="item.machine || store.activeMachines[item.id] || '-'">
                       {{ item.machine || store.activeMachines[item.id] || '-' }}
                     </span>
                   </div>
                   <div class="cell center border-r">
                     <v-chip size="small" variant="tonal" color="cyan-darken-2" class="font-weight-bold text-truncate w-100 d-flex justify-center chip-3d">
                       {{ item.operator_name || store.activeOperators[item.id] || 'NÃO IDENT.' }}
                     </v-chip>
                   </div>
                   <div class="cell center border-r">
                     <span class="text-caption font-mono font-weight-black opacity-80">{{ formatDateOnly(item.print_ended_at || item.created_at) }}</span>
                   </div>
                   <div class="cell center border-r">
                     <span class="text-caption font-mono font-weight-black opacity-80">{{ formatTimeOnly(item.print_ended_at || item.created_at) }}</span>
                   </div>
                </template>

                <div class="cell center border-r">
                  <span class="text-body-2 font-weight-black font-mono">{{ item.quantity_meters }}m</span>
                </div>

                <div class="cell center border-r">
                  <v-chip
                    class="font-weight-black text-uppercase text-white letter-spacing-1 chip-3d"
                    size="small"
                    :color="item.status === 'waiting_print_rework' ? 'red-darken-3' : (item.status === 'printing' ? 'cyan-darken-2' : (activeView === 'history' ? 'blue-grey' : 'blue-grey-lighten-1'))"
                    :variant="'flat'"
                    label
                  >
                    <v-icon start size="small" class="mr-1 animate-spin" v-if="item.status === 'printing'">mdi-loading</v-icon>
                    <v-icon start size="small" class="mr-1" v-else-if="item.status === 'waiting_print_rework'">mdi-alert-octagon</v-icon>
                    <v-icon start size="small" class="mr-1" v-else-if="activeView === 'history'">mdi-check-all</v-icon>
                    <v-icon start size="small" class="mr-1" v-else>mdi-clock-outline</v-icon>
                    {{ activeView === 'history' ? 'IMPRESSO' : (item.status === 'printing' ? 'RODANDO' : (item.status === 'waiting_print_rework' ? 'RETRABALHO' : 'NA FILA')) }}
                  </v-chip>
                </div>

                <div class="cell center">
                  <div class="actions-inline">
                    <div v-if="canEditItem" class="hint-tooltip" data-title="Editar Registro (Admin)">
                      <v-btn icon size="small" class="action-btn btn-3d" color="indigo-darken-2" variant="flat" @click="handleAdminEdit(item)">
                        <v-icon size="16">mdi-pencil</v-icon>
                      </v-btn>
                    </div>

                    <div class="hint-tooltip" data-title="Visualizar Arte">
                      <v-btn icon size="small" class="action-btn btn-3d" color="blue-grey" variant="flat" @click="openImage(item)">
                        <v-icon size="16">mdi-eye</v-icon>
                      </v-btn>
                    </div>

                    <div class="hint-tooltip" data-title="Baixar Arquivo" v-if="activeView === 'queue'">
                      <v-btn icon size="small" class="action-btn btn-3d" color="orange-darken-3" variant="flat" :href="item.print_file_url" target="_blank" download @click.stop>
                        <v-icon size="16">mdi-download</v-icon>
                      </v-btn>
                    </div>

                    <template v-if="activeView === 'queue'">
                      <div class="hint-tooltip" :data-title="['waiting_print', 'waiting_print_rework'].includes(item.status) ? 'INICIAR Impressão' : 'FINALIZAR Impressão'">
                        <v-btn icon size="small" class="action-btn btn-3d" :color="['waiting_print', 'waiting_print_rework'].includes(item.status) ? 'green-darken-3' : 'cyan-darken-4'" variant="flat" @click="openPinModal(item, ['waiting_print', 'waiting_print_rework'].includes(item.status) ? 'start' : 'finish')">
                          <v-icon size="18">{{ ['waiting_print', 'waiting_print_rework'].includes(item.status) ? 'mdi-play' : 'mdi-check-all' }}</v-icon>
                        </v-btn>
                      </div>
                      <div class="hint-tooltip" data-title="Remover / Cancelar">
                        <v-btn icon size="small" class="action-btn btn-3d" color="red-darken-4" variant="flat" @click="openPinModal(item, 'delete')">
                          <v-icon size="16">mdi-delete</v-icon>
                        </v-btn>
                      </div>
                    </template>

                    <template v-if="activeView === 'history'">
                      <div class="hint-tooltip" data-title="Solicitar Reimpressão (Erro)">
                        <v-btn icon size="small" class="action-btn btn-3d" color="amber-darken-3" variant="flat" @click="openReprintModal(item)">
                          <v-icon size="16">mdi-printer-alert</v-icon>
                        </v-btn>
                      </div>
                    </template>
                  </div>
                </div>
              </div>
            </template>
          </div>

          <div class="flex-shrink-0 border-t px-4 py-2 d-flex align-center justify-space-between gap-2" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5' : 'bg-white-05'">
            <div class="text-caption opacity-80 font-weight-bold text-uppercase">
              Mostrando <strong>{{ displayedData.length }}</strong> de <strong>{{ filteredDataLength }}</strong> registros
            </div>

            <v-pagination
              v-model="pagination.page"
              :length="Math.ceil(filteredDataLength / pagination.perPage)"
              density="compact"
              active-color="cyan-darken-4"
              total-visible="5"
              variant="flat"
              class="enterprise-pagination"
              rounded="0"
            ></v-pagination>
          </div>

          <div
            v-if="store.loading || isRendering"
            class="loading-overlay-container d-flex flex-column justify-center align-center"
            :class="themeStore.currentMode === 'light' ? 'overlay-light' : 'overlay-dark'"
          >
            <div class="particles-area">
              <v-icon
                v-for="p in particles"
                :key="p.id"
                class="particle-icon"
                :color="p.color"
                :style="{
                  left: p.left,
                  animationDelay: p.delay,
                  animationDuration: p.duration,
                  fontSize: p.size,
                  '--x-dir': p.xDir
                }"
              >
                {{ p.icon }}
              </v-icon>
            </div>

            <div class="loading-text text-caption mb-4 font-weight-black text-uppercase tracking-widest text-cyan-darken-2 position-relative z-10">
              CARREGANDO ITENS
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
        </v-card>
      </div>
    </div>

    <v-dialog v-model="pinModal.show" width="520" persistent transition="dialog-bottom-transition">
      <v-card class="pin-card overflow-hidden border-thin elevation-24" :class="themeStore.currentMode === 'light' ? 'pin-light' : 'pin-dark'">
        <div class="pin-head" :class="pinHeadClass">
          <div class="pin-head-left">
            <div class="pin-head-badge"><v-icon color="white" size="22">mdi-shield-lock-outline</v-icon></div>
            <div class="min-w-0">
              <div class="pin-title">Autorização Requerida</div>
              <div class="pin-subtitle">Identificação do operador responsável</div>
            </div>
          </div>
          <v-btn icon variant="text" size="small" color="white" class="pin-close" @click="pinModal.show = false"><v-icon>mdi-close</v-icon></v-btn>
        </div>

        <div class="pin-body">
          <div class="pin-surface">
            <div class="pin-surface-glow"></div>
            <v-window v-model="pinModal.step">
              <v-window-item :value="1">
                <div class="text-center mb-5">
                  <div class="pin-action-title">{{ getActionTitle(pinModal.actionType) }}</div>
                  <div class="pin-action-desc">
                    Digite seu <strong>PIN de Segurança</strong> para confirmar a identidade do operador que irá
                    <span class="text-uppercase font-weight-bold"> {{ getActionVerb(pinModal.actionType) }} </span>
                    este item.
                  </div>
                </div>

                <div class="d-flex justify-center mb-4">
                  <v-otp-input
                    v-model="pinModal.code"
                    length="4"
                    variant="outlined"
                    class="font-weight-black secure-otp"
                    height="76"
                    max-width="340"
                    :base-color="themeStore.currentMode === 'light' ? 'grey-darken-3' : 'grey-lighten-3'"
                    color="cyan-darken-2"
                    @finish="identifyUser"
                  ></v-otp-input>
                </div>

                <div v-if="pinModal.error" class="pin-alert pin-alert-error">
                  <v-icon start size="small">mdi-alert-circle</v-icon> PIN NÃO ENCONTRADO
                </div>

                <v-btn block size="large" variant="flat" height="56" class="pin-primary-btn btn-3d" :color="themeStore.currentMode === 'light' ? 'blue-grey-darken-4' : 'grey-darken-4'" :disabled="pinModal.code.length < 4" :loading="pinModal.loading" @click="identifyUser">
                  <v-icon start>mdi-shield-check</v-icon> VERIFICAR IDENTIDADE
                </v-btn>
              </v-window-item>

              <v-window-item :value="2">
                <div class="pin-profile">
                  <v-avatar size="84" class="pin-avatar" color="grey-lighten-2">
                    <v-img v-if="pinModal.identifiedUser?.avatar_url" :src="pinModal.identifiedUser.avatar_url" cover></v-img>
                    <span v-else class="text-h4 font-weight-black text-grey-darken-2">{{ pinModal.identifiedUser?.full_name?.charAt(0) }}</span>
                  </v-avatar>
                  <div class="min-w-0">
                    <div class="pin-name text-truncate">{{ pinModal.identifiedUser?.full_name }}</div>
                    <div class="pin-role"><v-icon size="14" class="mr-1">mdi-badge-account-horizontal-outline</v-icon> Operador Identificado</div>
                  </div>
                </div>

                <div v-if="pinModal.isDivergent" class="pin-alert pin-alert-error mt-4">
                  <v-icon start>mdi-lock-remove</v-icon>
                  <div class="text-left">
                    <div class="font-weight-black text-uppercase text-caption mb-1">Acesso Negado: PIN Divergente</div>
                    <div class="text-caption leading-tight" style="font-size: 0.78rem; line-height: 1.5;">
                      Este PIN pertence a <strong>{{ pinModal.identifiedUser?.full_name }}</strong>.<br />
                      Você está logado como <strong>{{ userStore.profile?.full_name }}</strong>.<br /><br />
                      Para prosseguir, insira <strong>seu próprio PIN</strong> ou troque de usuário na estação.
                    </div>
                  </div>
                </div>

                <div v-else class="mt-4">
                  <div v-if="pinModal.actionType === 'start'" class="mb-4">
                    <label class="pin-label">Selecionar Impressora *</label>
                    <v-select
                      v-model="pinModal.machine"
                      :items="store.availablePrinters"
                      variant="outlined"
                      density="comfortable"
                      class="pin-select"
                      :bg-color="themeStore.currentMode === 'light' ? 'grey-lighten-5' : 'rgba(255,255,255,0.05)'"
                      placeholder="Selecione a máquina..."
                      hide-details
                      prepend-inner-icon="mdi-printer"
                    ></v-select>
                  </div>
                  <div class="pin-summary">
                    <div class="pin-summary-ico"><v-icon size="24" color="white">{{ getActionIcon(pinModal.actionType) }}</v-icon></div>
                    <div class="text-left min-w-0">
                      <div class="pin-summary-label">Ação solicitada</div>
                      <div class="pin-summary-text text-truncate">{{ getActionDescription(pinModal.actionType) }}</div>
                    </div>
                  </div>
                </div>

                <div class="d-flex gap-3 mt-5">
                  <v-btn variant="outlined" height="56" class="flex-grow-1 pin-secondary-btn btn-3d" @click="pinModal.step = 1">{{ pinModal.isDivergent ? 'Voltar e Corrigir' : 'Voltar' }}</v-btn>
                  <v-btn v-if="!pinModal.isDivergent" variant="flat" height="56" class="flex-grow-1 pin-confirm-btn font-weight-black text-white btn-3d" :color="getActionColor(pinModal.actionType)" :loading="pinModal.loading" :disabled="pinModal.actionType === 'start' && !pinModal.machine" @click="executeAction">
                    <v-icon start>mdi-check-all</v-icon> CONFIRMAR
                  </v-btn>
                </div>
              </v-window-item>
            </v-window>
          </div>
        </div>
      </v-card>
    </v-dialog>

    <v-dialog v-model="reprintModal.show" width="520" persistent transition="dialog-bottom-transition">
      <v-card class="pin-card overflow-hidden border-thin elevation-24" :class="themeStore.currentMode === 'light' ? 'pin-light' : 'pin-dark'">
        <div class="pin-head pin-head-warning">
          <div class="pin-head-left">
            <div class="pin-head-badge"><v-icon color="white" size="22">mdi-printer-alert</v-icon></div>
            <div class="min-w-0">
              <div class="pin-title">Solicitar Reimpressão</div>
              <div class="pin-subtitle">Retornar item para fila e calcular perdas</div>
            </div>
          </div>
          <v-btn icon variant="text" size="small" color="white" class="pin-close" @click="reprintModal.show = false"><v-icon>mdi-close</v-icon></v-btn>
        </div>

        <div class="pin-body">
          <div class="pin-surface">
            <div class="pin-surface-glow"></div>
            <v-window v-model="reprintModal.step">
              <v-window-item :value="1">
                <div class="mb-4">
                  <v-textarea
                    v-model="reprintModal.reason"
                    label="Motivo da Reimpressão *"
                    placeholder="Ex: Falha na cabeça de impressão, tecido sujo, etc."
                    variant="outlined"
                    density="comfortable"
                    rows="3"
                    hide-details
                    class="mb-3"
                  ></v-textarea>

                  <v-text-field
                    v-model.number="reprintModal.lostMeters"
                    label="Metragem Perdida (m) *"
                    type="number"
                    variant="outlined"
                    density="comfortable"
                    hide-details
                    prepend-inner-icon="mdi-ruler"
                    class="mb-2"
                  ></v-text-field>
                </div>

                <v-btn block size="large" variant="flat" height="56" class="pin-primary-btn btn-3d" color="amber-darken-3" :disabled="!reprintModal.reason.trim() || reprintModal.lostMeters <= 0" @click="reprintModal.step = 2">
                  AVANÇAR PARA ASSINATURA <v-icon end>mdi-arrow-right</v-icon>
                </v-btn>
              </v-window-item>

              <v-window-item :value="2">
                <div class="text-center mb-5">
                  <div class="pin-action-title">Identificação do Operador</div>
                  <div class="pin-action-desc">
                    Insira seu <strong>PIN</strong> para confirmar a perda de <strong>{{ reprintModal.lostMeters }}m</strong> e devolver à fila.
                  </div>
                </div>

                <div class="d-flex justify-center mb-4">
                  <v-otp-input
                    v-model="reprintModal.pin"
                    length="4"
                    variant="outlined"
                    class="font-weight-black secure-otp"
                    height="76"
                    max-width="340"
                    :base-color="themeStore.currentMode === 'light' ? 'grey-darken-3' : 'grey-lighten-3'"
                    color="amber-darken-3"
                    @finish="confirmReprintAuth"
                  ></v-otp-input>
                </div>

                <div v-if="reprintModal.error" class="pin-alert pin-alert-error">
                  <v-icon start size="small">mdi-alert-circle</v-icon> PIN NÃO ENCONTRADO
                </div>

                <div class="d-flex gap-3 mt-5">
                   <v-btn variant="outlined" height="56" class="flex-grow-1 pin-secondary-btn btn-3d" @click="reprintModal.step = 1; reprintModal.pin = ''; reprintModal.error = false">Voltar</v-btn>
                   <v-btn variant="flat" height="56" class="flex-grow-1 pin-confirm-btn font-weight-black text-white btn-3d" color="amber-darken-3" :loading="reprintModal.loading" :disabled="reprintModal.pin.length < 4" @click="confirmReprintAuth">
                    <v-icon start>mdi-check-all</v-icon> CONFIRMAR
                  </v-btn>
                </div>
              </v-window-item>
            </v-window>
          </div>
        </div>
      </v-card>
    </v-dialog>

    <v-dialog v-model="adminEditModal.show" width="650" persistent transition="scale-transition">
      <v-card class="rounded-lg border-thin overflow-hidden elevation-24">
        <div class="bg-indigo-darken-4 text-white px-6 py-4 d-flex align-center">
          <v-avatar size="32" color="white" class="mr-3">
            <v-icon color="indigo-darken-4" size="20">mdi-shield-edit</v-icon>
          </v-avatar>
          <div>
            <div class="text-h6 font-weight-black leading-none">MODO ADMINISTRATIVO</div>
            <div class="text-caption opacity-80 mt-1">Correção direta de registro de produção</div>
          </div>
          <v-spacer></v-spacer>
          <v-btn icon variant="text" size="small" @click="adminEditModal.show = false"><v-icon>mdi-close</v-icon></v-btn>
        </div>

        <v-card-text class="pa-6">
          <div class="bg-grey-lighten-4 pa-4 rounded border-thin mb-6 d-flex align-center">
             <v-icon color="indigo" class="mr-3">mdi-information-outline</v-icon>
             <div class="text-caption font-weight-bold opacity-70">
                Item ID: <span class="font-mono">{{ adminEditModal.item?.id }}</span>
             </div>
          </div>

          <v-row dense>
            <v-col cols="12" md="6">
              <v-text-field v-model="adminEditModal.form.stamp_ref" label="Referência da Estampa" variant="outlined" density="comfortable" prepend-inner-icon="mdi-tag"></v-text-field>
            </v-col>
            <v-col cols="12" md="6">
              <v-text-field v-model.number="adminEditModal.form.quantity_meters" label="Metragem (Metros)" type="number" variant="outlined" density="comfortable" prepend-inner-icon="mdi-ruler"></v-text-field>
            </v-col>
            <v-col cols="12">
              <v-select v-model="adminEditModal.form.status" :items="[{ title: 'Fila de Impressão', value: 'waiting_print' }, { title: 'Imprimindo', value: 'printing' }, { title: 'Impresso (Fila Calandra)', value: 'printed' }]" label="Status de Produção" variant="outlined" density="comfortable" prepend-inner-icon="mdi-state-machine"></v-select>
            </v-col>
            <v-divider class="my-4 w-100"></v-divider>
            <div class="text-caption font-weight-black text-uppercase mb-2 opacity-60 w-100 pl-3">Alocação de Recurso</div>
            <v-col cols="12" md="6">
              <v-select v-model="adminEditModal.form.machine" :items="store.availablePrinters" label="Impressora Alocada" variant="outlined" density="comfortable" prepend-inner-icon="mdi-printer" placeholder="Nenhuma máquina" clearable></v-select>
            </v-col>
            <v-col cols="12" md="6">
              <v-autocomplete v-model="adminEditModal.form.operator_name" :items="store.availableOperators" label="Operador Responsável" variant="outlined" density="comfortable" prepend-inner-icon="mdi-account-hard-hat" placeholder="Nenhum operador" clearable></v-autocomplete>
            </v-col>
          </v-row>
        </v-card-text>
        <v-card-actions class="pa-6 bg-grey-lighten-5 border-t">
          <v-btn variant="outlined" class="btn-3d px-6" height="48" @click="adminEditModal.show = false">Cancelar</v-btn>
          <v-spacer></v-spacer>
          <v-btn color="indigo-darken-4" variant="flat" class="btn-3d px-8 font-weight-black" height="48" :loading="adminEditModal.loading" @click="saveAdminEdit">APLICAR CORREÇÕES</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <v-dialog v-model="errorDetailsModal.show" max-width="500">
      <v-card class="rounded-xl overflow-hidden" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-grey-darken-4'">
        <div class="bg-red-darken-3 px-5 py-4 text-white d-flex align-center justify-space-between">
          <span class="font-weight-black text-uppercase">
            <v-icon start>mdi-alert-octagon</v-icon>
            Motivo da Rejeição / Falha
          </span>
          <v-btn icon="mdi-close" variant="text" density="compact" @click="errorDetailsModal.show = false"></v-btn>
        </div>
        <div class="pa-5">
          <div v-if="errorDetailsModal.loading" class="text-center py-5">
             <v-progress-circular indeterminate color="red-darken-3"></v-progress-circular>
             <div class="mt-2 text-caption font-weight-bold opacity-70 text-uppercase">Buscando dados da falha...</div>
          </div>
          <template v-else>
              <v-alert color="red-lighten-5" class="border border-red-lighten-3 mb-4 text-red-darken-4">
                 <p class="text-body-2 font-weight-bold mb-0">
                   {{ errorDetailsModal.reason }}
                 </p>
              </v-alert>

              <div v-if="errorDetailsModal.photo_url" class="mt-2 text-center">
                <span class="text-caption font-weight-bold opacity-70 mb-2 d-block text-uppercase">Foto anexada pela Calandra:</span>
                <v-img
                  :src="errorDetailsModal.photo_url"
                  class="rounded-lg border-thin cursor-pointer elevation-4 mx-auto hover-elevate transition-all"
                  max-height="300"
                  cover
                  @click="openImage({ stamp_image_url: errorDetailsModal.photo_url, stamp_ref: 'Foto do Defeito' })"
                ></v-img>
              </div>
          </template>
        </div>
        <div class="pa-4 border-t d-flex justify-end" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5' : 'bg-white-05'">
           <v-btn variant="flat" color="red-darken-3" class="font-weight-bold btn-3d" @click="errorDetailsModal.show = false">Fechar</v-btn>
        </div>
      </v-card>
    </v-dialog>

    <ImageModal :show="imageModal.show" :image-url="imageModal.url" :file-name="imageModal.name" @close="imageModal.show = false" />
  </div>
</template>

<script setup lang="ts">
import { ref, shallowRef, reactive, onMounted, computed, onUnmounted, watch, nextTick } from 'vue';
import { useProductionStore, type ProductionItem } from '@/stores/production';
import { useUserStore } from '@/stores/user';
import { useThemeStore } from '@/stores/theme';
import { useCompanyStore } from '@/stores/company';
import { useAppStore } from '@/stores/app';
import { supabase } from '@/api/supabase';
import ImageModal from '@/components/ImageModal.vue';
import { format } from 'date-fns';

const store = useProductionStore();
const themeStore = useThemeStore();
const companyStore = useCompanyStore();
const userStore = useUserStore();
const appStore = useAppStore();

// -------------------------------------------------------------
// ESTADO DA LOADING BAR E REF DE SCROLL DA LISTA
// -------------------------------------------------------------
const scrollContainer = ref<HTMLElement | null>(null);
const isRendering = ref(false);
const renderProgress = ref(0);
const displayedData = shallowRef<ProductionItem[]>([]);

// Gerador de partículas dinâmicas (estampas)
const particleIcons = ['mdi-flower-tulip', 'mdi-palette', 'mdi-brush', 'mdi-texture', 'mdi-shape', 'mdi-tshirt-crew', 'mdi-draw'];
const particleColors = ['cyan-lighten-2', 'teal-lighten-2', 'blue-lighten-2', 'indigo-lighten-2', 'purple-lighten-2'];
const particles = Array.from({ length: 20 }).map((_, i) => ({
  id: i,
  icon: particleIcons[Math.floor(Math.random() * particleIcons.length)],
  color: particleColors[Math.floor(Math.random() * particleColors.length)],
  left: `${30 + Math.random() * 40}%`,
  delay: `${Math.random() * 2}s`,
  duration: `${1.5 + Math.random() * 1.5}s`,
  size: `${14 + Math.random() * 16}px`,
  xDir: `${(Math.random() - 0.5) * 120}px`
}));

const activeView = ref<'queue' | 'history'>('queue');

const handleViewChange = () => {
    pagination.page = 1;
    searchText.value = '';
    if (activeView.value === 'history' && store.printedHistory.length === 0) {
        refreshData();
    }
};

const formatDateOnly = (iso: string) => {
    if (!iso) return '-';
    return format(new Date(iso), 'dd/MM/yyyy');
};

const formatTimeOnly = (iso: string) => {
    if (!iso) return '-';
    return format(new Date(iso), 'HH:mm');
};

const searchText = ref('');
const debouncedSearch = ref('');
let searchDebounceTimer: any = null;

const uiQueue = shallowRef<ProductionItem[]>([]);
const uiHistory = shallowRef<ProductionItem[]>([]);
let queueSyncTimer: any = null;

const canEditItem = computed(() => {
  const role = userStore.profile?.role;
  return role === 'admin' || role === 'super_admin';
});

const adminEditModal = reactive({
  show: false,
  loading: false,
  item: null as ProductionItem | null,
  form: { stamp_ref: '', quantity_meters: 0, status: '', machine: '' as string | undefined, operator_name: '' as string | undefined }
});

const handleAdminEdit = (item: ProductionItem) => {
  adminEditModal.item = item;
  adminEditModal.form.stamp_ref = item.stamp_ref;
  adminEditModal.form.quantity_meters = item.quantity_meters;
  adminEditModal.form.status = item.status;
  adminEditModal.form.machine = store.activeMachines[item.id] || '';
  adminEditModal.form.operator_name = store.activeOperators[item.id] || '';
  adminEditModal.show = true;
};

const saveAdminEdit = async () => {
  if (companyStore.isDemoMode) return appStore.showSnackbar('Ação não permitida em modo demonstração', 'warning');
  if (!adminEditModal.item) return;
  adminEditModal.loading = true;
  try {
    await store.adminUpdateItem(adminEditModal.item.id, { stamp_ref: adminEditModal.form.stamp_ref, quantity_meters: adminEditModal.form.quantity_meters, status: adminEditModal.form.status, machine: adminEditModal.form.machine, operator_name: adminEditModal.form.operator_name });
    adminEditModal.show = false;
  } catch (e) {
    alert('Erro ao salvar alterações.');
  } finally {
    adminEditModal.loading = false;
  }
};

watch(searchText, (val) => {
  if (searchDebounceTimer) clearTimeout(searchDebounceTimer);
  searchDebounceTimer = setTimeout(() => {
    debouncedSearch.value = (val || '').trim();
    pagination.page = 1;
  }, 180);
});

watch(() => store.printingQueue, (val) => {
    if (queueSyncTimer) clearTimeout(queueSyncTimer);
    queueSyncTimer = setTimeout(() => { uiQueue.value = Array.isArray(val) ? val.slice() : []; }, 160);
  }, { deep: false, immediate: true }
);

watch(() => store.printedHistory, (val) => {
    uiHistory.value = Array.isArray(val) ? val.slice() : [];
});

const pagination = reactive({ page: 1, perPage: 20 });
const currentStatusFilter = ref('all');

watch(currentStatusFilter, () => { pagination.page = 1; });

const statusFilters = [
  { label: 'Todos', value: 'all', icon: 'mdi-view-list' },
  { label: 'Fila de Espera', value: 'waiting', icon: 'mdi-tray-full' },
  { label: 'Imprimindo', value: 'printing', icon: 'mdi-printer-3d-nozzle' }
];

const pinModal = reactive({ show: false, step: 1, code: '', machine: null as string | null, item: null as ProductionItem | null, actionType: '' as 'start' | 'finish' | 'delete', loading: false, error: false, identifiedUser: null as any, isDivergent: false });
const imageModal = reactive({ show: false, url: '', name: '' });

const reprintModal = reactive({
    show: false,
    step: 1,
    item: null as ProductionItem | null,
    reason: '',
    lostMeters: 0,
    pin: '',
    loading: false,
    error: false
});

const errorDetailsModal = reactive({
    show: false,
    loading: false,
    reason: '',
    photo_url: null as string | null
});

// ADICIONADO: RECONHECE O NOVO STATUS DE RETRABALHO
const isItemInError = (item: ProductionItem) => {
    return item.status === 'waiting_print_rework' || item.status.includes('rework') || (item.reprint_info && item.reprint_info.count > 0 && ['waiting_print', 'printing'].includes(item.status));
};

// ADICIONADO: BUSCA LOG DA FALHA E FOTO NO SUPABASE DE VERDADE
const openErrorDetails = async (item: ProductionItem) => {
    errorDetailsModal.loading = true;
    errorDetailsModal.reason = '';
    errorDetailsModal.photo_url = null;
    errorDetailsModal.show = true;

    try {
        const { data, error } = await supabase
          .from('production_logs')
          .select('*')
          .eq('order_item_id', item.id)
          .order('created_at', { ascending: false })
          .limit(10);

        if (data && data.length > 0) {
            // 1. Procura primeiro o erro gerado pelo painel PCP (Calandra)
            const pcpErrorLog = data.find(l => l.action === 'reprint_error_reported');
            if (pcpErrorLog) {
                errorDetailsModal.reason = pcpErrorLog.metadata?.reason || 'Motivo não especificado pela equipe da Calandra.';
                errorDetailsModal.photo_url = pcpErrorLog.metadata?.photo_url || null;
                return;
            }

            // 2. Mantém o código antigo (is_rework) caso haja algum log antigo com esse formato
            const reworkLog = data.find(l => l.metadata?.is_rework);
            if (reworkLog) {
                errorDetailsModal.reason = reworkLog.metadata.justification || 'Motivo não especificado na etapa de revisão.';
                errorDetailsModal.photo_url = reworkLog.metadata.attachment_url || null;
                return;
            }
        }

        // Fallback antigo
        const history = item.reprint_info?.history || [];
        const lastError = history[history.length - 1];
        if (lastError) {
            errorDetailsModal.reason = lastError.reason || 'Motivo não especificado pela equipe da Calandra.';
            errorDetailsModal.photo_url = lastError.photo_url || null;
        } else {
            errorDetailsModal.reason = 'Nenhum log de erro detalhado encontrado para este item no banco de dados.';
        }
    } catch (e) {
        errorDetailsModal.reason = 'Falha de comunicação ao buscar o log de erro no servidor.';
    } finally {
        errorDetailsModal.loading = false;
    }
};

const gridCols = computed(() => {
  return activeView.value === 'queue'
    // Na Fila Atual: Status passou de 120px para 150px, e Ações de 160px para 200px
    ? '50px 60px 140px minmax(200px, 1fr) 160px 160px 100px 150px 200px'
    // No Histórico: Adicionado 140px para a coluna Máquina
    : '50px 60px 140px minmax(200px, 1fr) 140px 150px 90px 80px 100px 150px 220px';
});

const openReprintModal = (item: ProductionItem) => {
    reprintModal.item = item;
    reprintModal.reason = '';
    reprintModal.lostMeters = item.quantity_meters || 0;
    reprintModal.pin = '';
    reprintModal.step = 1;
    reprintModal.error = false;
    reprintModal.show = true;
};

const confirmReprintAuth = async () => {
    if (companyStore.isDemoMode) return appStore.showSnackbar('Ação não permitida em modo demonstração', 'warning');
    if (reprintModal.pin.length < 4 || !reprintModal.item) return;
    reprintModal.loading = true;
    reprintModal.error = false;

    try {
        const { data: profile, error } = await supabase.from('profiles').select('*').eq('security_pin', reprintModal.pin).single();
        if (error || !profile) throw new Error('PIN Invalido');

        await store.requestReprint(
            reprintModal.item.id,
            reprintModal.reason,
            Number(reprintModal.lostMeters),
            reprintModal.pin,
            profile.id,
            profile.full_name
        );

        reprintModal.show = false;
        activeView.value = 'queue';
    } catch (e) {
        reprintModal.error = true;
        reprintModal.pin = '';
    } finally {
        reprintModal.loading = false;
    }
};

const filteredData = computed(() => {
  let items = activeView.value === 'queue' ? uiQueue.value : uiHistory.value;

  if (activeView.value === 'queue') {
      // ADICIONADO: O filtro 'waiting' também pega os status de retrabalho
      if (currentStatusFilter.value === 'waiting') items = items.filter(i => ['waiting_print', 'waiting_print_rework'].includes(i.status));
      if (currentStatusFilter.value === 'printing') items = items.filter(i => i.status === 'printing');
  }

  if (debouncedSearch.value) {
    const s = debouncedSearch.value.toLowerCase();
    items = items.filter(i => i.order?.customer_name?.toLowerCase().includes(s) || i.stamp_ref?.toLowerCase().includes(s) || String(i.order?.order_number).includes(s) );
  }

  const maxPage = Math.max(1, Math.ceil(items.length / pagination.perPage));
  if (pagination.page > maxPage) pagination.page = maxPage;
  return items;
});

const filteredDataLength = computed(() => filteredData.value.length);

const paginatedData = computed(() => {
  const start = (pagination.page - 1) * pagination.perPage;
  return filteredData.value.slice(start, start + pagination.perPage);
});

// -------------------------------------------------------------------------
// OTIMIZAÇÃO MAX: PRE-SCROLL HACK COM OVERLAY
// -------------------------------------------------------------------------
watch(paginatedData, async (newVal) => {
  isRendering.value = true;
  renderProgress.value = 0;

  displayedData.value = newVal;

  await nextTick();

  if (scrollContainer.value && newVal.length > 0) {
    const el = scrollContainer.value;

    setTimeout(() => {
      const maxScroll = el.scrollHeight - el.clientHeight;
      if (maxScroll > 0) {
        el.scrollTo({ top: maxScroll, behavior: 'smooth' });

        setTimeout(() => {
          el.scrollTo({ top: 0, behavior: 'smooth' });
        }, 1300);
      }
    }, 150);
  }

  const targetDuration = 3000;
  const intervalTime = 30;
  const step = (100 / (targetDuration / intervalTime));

  const progressInterval = setInterval(() => {
    renderProgress.value += step;

    if (renderProgress.value >= 100) {
      clearInterval(progressInterval);
      renderProgress.value = 100;
      isRendering.value = false;
    }
  }, intervalTime);

}, { immediate: true });
// -------------------------------------------------------------------------

// ADICIONADO: waiting_print_rework faz parte da fila total de peças
const queueItems = computed(() => uiQueue.value.filter(i => ['waiting_print', 'waiting_print_rework'].includes(i.status)));
const activeItems = computed(() => uiQueue.value.filter(i => i.status === 'printing'));

const totalMetersRaw = computed(() => {
  const total = uiQueue.value.reduce((acc, i) => acc + (Number(i.quantity_meters) || 0), 0);
  return Math.round(total * 100) / 100;
});
const totalMetersDisplay = computed(() => totalMetersRaw.value.toLocaleString('pt-BR', { minimumFractionDigits: 2, maximumFractionDigits: 2 }));

const openPinModal = (item: ProductionItem, type: 'start' | 'finish' | 'delete') => {
  pinModal.item = item; pinModal.actionType = type; pinModal.code = ''; pinModal.machine = null; pinModal.error = false; pinModal.step = 1; pinModal.loading = false; pinModal.identifiedUser = null; pinModal.isDivergent = false; pinModal.show = true;
};

const identifyUser = async () => {
  if (companyStore.isDemoMode) return appStore.showSnackbar('Ação não permitida em modo demonstração', 'warning');
  if (pinModal.code.length < 4) return;
  pinModal.loading = true; pinModal.error = false;
  try {
    const { data: profile, error } = await supabase.from('profiles').select('*').eq('security_pin', pinModal.code).single();
    if (error || !profile) throw new Error('PIN não encontrado');
    pinModal.identifiedUser = profile;
    if (userStore.profile?.id && profile.id !== userStore.profile.id) pinModal.isDivergent = true; else pinModal.isDivergent = false;
    setTimeout(() => { pinModal.step = 2; pinModal.loading = false; }, 450);
  } catch (e) { pinModal.error = true; pinModal.code = ''; pinModal.loading = false; }
};

const executeAction = async () => {
  if (companyStore.isDemoMode) return appStore.showSnackbar('Ação não permitida em modo demonstração', 'warning');
  if (!pinModal.item) return;
  pinModal.loading = true;
  try {
    if (pinModal.actionType === 'delete') {
      await store.updatePrintStatus(pinModal.item.id, 'design_released', 'print_cancelled', pinModal.code, undefined, pinModal.identifiedUser?.id);
    } else {
      const newStatus = pinModal.actionType === 'start' ? 'printing' : 'printed';
      const logAction = pinModal.actionType === 'start' ? 'start_print' : 'finish_print';
      await store.updatePrintStatus(pinModal.item.id, newStatus, logAction, pinModal.code, pinModal.machine || undefined, pinModal.identifiedUser?.id);
    }
    pinModal.show = false;
  } catch (e) { alert('Erro ao executar ação.'); } finally { pinModal.loading = false; }
};

const pinHeadClass = computed(() => {
  if (pinModal.actionType === 'delete') return 'pin-head-danger';
  if (pinModal.actionType === 'finish') return 'pin-head-success';
  return 'pin-head-neutral';
});

const getActionTitle = (type: string) => (type === 'delete' ? 'Remover da Fila?' : type === 'finish' ? 'Concluir Impressão?' : 'Iniciar Impressão?');
const getActionVerb = (type: string) => (type === 'delete' ? 'CANCELAR' : type === 'finish' ? 'FINALIZAR' : 'INICIAR');
const getActionDescription = (type: string) => { if (type === 'delete') return 'O item será removido da fila e estornado para o Design.'; if (type === 'finish') return 'Enviar para Calandra / Acabamento.'; return `Liberar para máquina ${pinModal.machine || '...'} .`; };
const getActionIcon = (type: string) => (type === 'delete' ? 'mdi-alert-octagon' : type === 'finish' ? 'mdi-send-check' : 'mdi-printer-play');
const getActionColor = (type: string) => (type === 'delete' ? 'red-darken-3' : type === 'finish' ? 'green-darken-3' : 'cyan-darken-3');
const getCurrentLogMachine = (item: ProductionItem) => store.activeMachines[item.id] || '-';


// =======================================================
// MODO DEMO: POPULAR DADOS
// =======================================================
const populateDemoData = () => {
    store.activeMachines = { 'fake-item-2': 'Máquina Epson S3200' };
    store.availablePrinters = ['Máquina Epson S3200', 'Máquina Mimaki F200'];

    if (activeView.value === 'queue') {
        store.printingQueue = [
            { id: 'fake-item-1', status: 'waiting_print', stamp_ref: 'EST-FLORAL-01', quantity_meters: 150.5, order: { customer_name: 'Cliente Fictício A', order_number: '1001' } },
            { id: 'fake-item-2', status: 'printing', stamp_ref: 'EST-GEOM-02', quantity_meters: 300, order: { customer_name: 'Cliente Fictício B', order_number: '1002' } },
            { id: 'fake-item-3', status: 'waiting_print', stamp_ref: 'EST-LISTRA-03', quantity_meters: 85, order: { customer_name: 'Cliente Fictício C', order_number: '1003' } },
            { id: 'fake-item-4', status: 'waiting_print_rework', stamp_ref: 'EST-PRAIA-04', quantity_meters: 50, order: { customer_name: 'Cliente Fictício D', order_number: '1004' } },
            { id: 'fake-item-5', status: 'waiting_print', stamp_ref: 'EST-FOLHA-05', quantity_meters: 100, order: { customer_name: 'Cliente Fictício E', order_number: '1005' }, reprint_info: { count: 1, history: [{ reason: 'Borrou no meio do rolo' }] } }
        ] as any[];
    } else {
        store.printedHistory = [
            { id: 'fake-hist-1', status: 'printed', stamp_ref: 'EST-ANTIGA-01', quantity_meters: 500, operator_name: 'Operador Demo 1', print_ended_at: new Date().toISOString(), order: { customer_name: 'Cliente Fictício Z', order_number: '9001' } },
            { id: 'fake-hist-2', status: 'printed', stamp_ref: 'EST-ANTIGA-02', quantity_meters: 120, operator_name: 'Operador Demo 2', print_ended_at: new Date(Date.now() - 3600000).toISOString(), order: { customer_name: 'Cliente Fictício X', order_number: '9002' } }
        ] as any[];
    }
};


const refreshData = async () => {
  if (companyStore.isDemoMode) {
      populateDemoData();
      return;
  }

  if(activeView.value === 'queue') {
      await Promise.allSettled([ store.fetchPrintingQueue(), store.fetchMachines('printer'), store.fetchOperators() ]);
  } else {
      await store.fetchPrintedHistory();
  }
};

const openImage = (item: any) => { imageModal.url = item.stamp_image_url || item.print_file_url; imageModal.name = item.stamp_ref; imageModal.show = true; };
const getRowIndex = (index: number) => ((pagination.page - 1) * pagination.perPage) + index + 1;
const zebraClass = (index: number) => { if (themeStore.currentMode !== 'light') return index % 2 === 0 ? 'zebra-dark-a' : 'zebra-dark-b'; return index % 2 === 0 ? 'zebra-light-a' : 'zebra-light-b'; };

onMounted(() => { refreshData(); });
onUnmounted(() => { if (searchDebounceTimer) clearTimeout(searchDebounceTimer); if (queueSyncTimer) clearTimeout(queueSyncTimer); });
</script>

<style scoped lang="scss">
/* ========================================================
   OVERLAY E EFEITOS DA LOADING BAR
   ======================================================== */
.loading-overlay-container {
  position: absolute;
  inset: 0;
  z-index: 100;
  transition: opacity 0.3s ease;
}

.overlay-light {
  background: rgba(255, 255, 255, 0.95);
  backdrop-filter: blur(6px);
}

.overlay-dark {
  background: rgba(20, 20, 24, 0.95);
  backdrop-filter: blur(6px);
}

.loading-text {
  font-size: 13px;
  animation: pulse-text 1.5s infinite;
}

@keyframes pulse-text {
  0%, 100% { opacity: 0.6; text-shadow: 0 0 4px rgba(0, 172, 193, 0); }
  50% { opacity: 1; text-shadow: 0 0 10px rgba(0, 172, 193, 0.8); }
}

.progress-bar-bg {
  width: 280px;
  height: 6px;
  background: rgba(128, 128, 128, 0.15);
  border-radius: 6px;
  overflow: hidden;
  box-shadow: inset 0 1px 3px rgba(0,0,0,0.2);
}

.progress-bar-fill {
  height: 100%;
  background: linear-gradient(90deg, #00838f, #00e5ff);
  border-radius: 6px;
  box-shadow: 0 0 12px rgba(0, 229, 255, 0.6);
  position: relative;
}

.progress-glow {
  position: absolute;
  top: 0;
  right: 0;
  bottom: 0;
  width: 20px;
  background: rgba(255, 255, 255, 0.8);
  filter: blur(4px);
  animation: glow-move 1s linear infinite;
}

@keyframes glow-move {
  0% { transform: translateX(-20px); opacity: 0; }
  50% { opacity: 1; }
  100% { transform: translateX(10px); opacity: 0; }
}

/* ========================================================
   ANIMAÇÃO DE PARTÍCULAS (ESTAMPAS VOANDO)
   ======================================================== */
.particles-area {
  position: absolute;
  bottom: calc(50% - 20px);
  width: 100%;
  height: 200px;
  pointer-events: none;
  z-index: 0;
}

.particle-icon {
  position: absolute;
  bottom: 0;
  opacity: 0;
  animation: floatUp infinite ease-out;
}

@keyframes floatUp {
  0% {
    transform: translate(0, 0) scale(0.3) rotate(0deg);
    opacity: 0;
  }
  20% {
    opacity: 0.9;
  }
  80% {
    opacity: 0.5;
  }
  100% {
    transform: translate(var(--x-dir), -140px) scale(1.6) rotate(180deg);
    opacity: 0;
  }
}

/* ========================================================
   OTIMIZAÇÃO DE PERFORMANCE: TOOLTIPS NATIVOS (SEM JS)
   ======================================================== */
.hint-tooltip {
  position: relative;
  display: inline-flex;
}
.hint-tooltip:hover::after {
  content: attr(data-title);
  position: absolute;
  bottom: calc(100% + 6px);
  left: 50%;
  transform: translateX(-50%);
  background: rgba(0, 0, 0, 0.95);
  color: #ffffff;
  padding: 6px 10px;
  font-size: 11px;
  font-weight: 800;
  border-radius: 4px;
  white-space: nowrap;
  pointer-events: none;
  z-index: 100;
  border: 1px solid rgba(255, 255, 255, 0.2);
  box-shadow: 0 4px 15px rgba(0, 0, 0, 0.5);
  text-transform: uppercase;
  letter-spacing: 0.5px;
}
.hint-tooltip:hover::before {
  content: '';
  position: absolute;
  bottom: 100%;
  left: 50%;
  transform: translateX(-50%);
  border-width: 5px;
  border-style: solid;
  border-color: rgba(0,0,0,0.95) transparent transparent transparent;
  pointer-events: none;
  z-index: 100;
}

/* EFEITOS 3D E BOTÕES */
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
    font-weight: 900;
}

/* NOVO ÍCONE 3D DE ESTAMPA EM RELEVO */
.icon-3d-wrapper {
    position: relative;
    width: 32px;
    height: 32px;
    display: flex;
    align-items: center;
    justify-content: center;
    background: linear-gradient(135deg, rgba(255,255,255,0.1), rgba(0,0,0,0.1));
    border-radius: 8px;
    box-shadow: 0 4px 6px rgba(0,0,0,0.15), inset 0 2px 4px rgba(255,255,255,0.4), inset 0 -2px 4px rgba(0,0,0,0.2);
    overflow: hidden;
    transition: transform 0.2s cubic-bezier(0.175, 0.885, 0.32, 1.275);
}
.bg-glass-dark .icon-3d-wrapper {
    background: linear-gradient(135deg, rgba(255,255,255,0.05), rgba(0,0,0,0.3));
    box-shadow: 0 4px 6px rgba(0,0,0,0.3), inset 0 2px 4px rgba(255,255,255,0.1), inset 0 -2px 4px rgba(0,0,0,0.4);
}
.icon-3d-wrapper:hover {
    transform: translateY(-2px) scale(1.05);
}
.icon-3d {
    filter: drop-shadow(0 2px 2px rgba(0,0,0,0.3));
}
.icon-3d-shine {
    position: absolute;
    top: 0; left: -100%;
    width: 50%; height: 100%;
    background: linear-gradient(90deg, transparent, rgba(255,255,255,0.5), transparent);
    transform: skewX(-20deg);
}
.icon-3d-wrapper:hover .icon-3d-shine {
    animation: shine-sweep 0.6s ease-out;
}
@keyframes shine-sweep {
    0% { left: -100%; }
    100% { left: 200%; }
}

.printing-layout { position: relative; height: 100vh; }
.bg-glass-dark { background: #0a0a0c; }
.bg-glass-header { background: rgba(20,20,24,0.9); border-bottom: 1px solid rgba(255,255,255,0.05) !important; }

.background-carousel-wrapper { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 0; opacity: 0.6; pointer-events: none; }
.background-overlay { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 1; background: radial-gradient(circle at center, rgba(15, 15, 19, 0.4), rgba(15, 15, 19, 0.98)); backdrop-filter: blur(8px); }

.border-white-05 { border-color: rgba(255,255,255,0.05) !important; }
.border-thin { border: 1px solid rgba(0,0,0,0.12); }
.bg-white-05 { background: rgba(255,255,255,0.05); }

.clean-input { border: none; outline: none; background: transparent; font-size: 13px; color: inherit; width: 100%; }

.controls-bar { border: 1px solid rgba(0,0,0,0.08); padding: 8px; }
.controls-light { background: #ffffff; }
.controls-dark { background: #1e1e23; border: 1px solid rgba(255,255,255,0.08); }
.search-wrap { height: 40px; width: 320px; border-radius: 0; padding: 0 12px; border: 1px solid rgba(0,0,0,0.08); }
.search-light { background: #f4f6f8; }
.search-dark { background: rgba(255,255,255,0.08); border-color: rgba(255,255,255,0.1); }

/* RESOLUÇÃO DA GRID VERTICAL */
.grid-header, .grid-row {
  display: grid;
  grid-template-columns: var(--grid-cols);
  align-items: center;
  width: 100%;
  min-width: 1200px;
}
.grid-header { min-height: 48px; border-bottom: 2px solid rgba(0,0,0,0.10); }

/* GPU Acceleration */
.grid-row{
  min-height: 74px;
  border-bottom: 1px solid rgba(0,0,0,0.08);
  transition: background 0.2s;
  will-change: transform;
  contain: content;
  transform: translateZ(0);
}

.cell{ padding: 0 12px; display: flex; align-items: center; overflow: hidden; white-space: nowrap; height: 100%; min-width: 0; }
.border-r { border-right: 1px solid rgba(0,0,0,0.08); }
.header-text { font-size: 11px; font-weight: 900; text-transform: uppercase; letter-spacing: 0.6px; opacity: 0.8; }
.list-text { font-size: 13px !important; line-height: 1.35 !important; }
.center { justify-content: center; text-align: center; }

.sticky-head{ position: sticky; top: 0; z-index: 5; }

.kpi-card { color: white; min-height: 110px; position: relative; overflow: hidden; transition: all 0.3s ease; }
.kpi-bg-icon { position: absolute; right: -20px; bottom: -20px; opacity: 0.15; transform: rotate(-15deg); pointer-events: none; }
.kpi-bg-icon .v-icon { font-size: 100px; color: white; }
.kpi-label { font-size: 11px; font-weight: 900; letter-spacing: 1px; opacity: 0.9; }
.kpi-value { font-size: 32px; font-weight: 900; letter-spacing: -1px; }
.kpi-footer { font-size: 10px; opacity: .8; font-weight: 700; text-transform: uppercase; margin-top: 4px; }

.actions-inline { display: flex; align-items: center; justify-content: center; gap: 6px; }
.action-btn { width: 32px !important; height: 32px !important; border-radius: 8px !important; overflow: hidden; }

/* ANIMAÇÃO DE PULSO PARA ERRO */
.row-error-pulse {
  animation: pulseError 2s infinite;
  border-left: 4px solid #c62828 !important;
}

@keyframes pulseError {
  0% { background-color: rgba(198, 40, 40, 0.05); }
  50% { background-color: rgba(198, 40, 40, 0.2); }
  100% { background-color: rgba(198, 40, 40, 0.05); }
}

.animate-bounce {
  animation: bounce 1.5s infinite;
}

@keyframes bounce {
  0%, 100% { transform: translateY(-15%); animation-timing-function: cubic-bezier(0.8,0,1,1); }
  50% { transform: none; animation-timing-function: cubic-bezier(0,0,0.2,1); }
}

.animate-spin { animation: spin 2s linear infinite; }
@keyframes spin { 100% { transform: rotate(360deg); } }

.secure-otp :deep(input) { font-size: 28px; font-weight: 900; letter-spacing: 10px; border-radius: 12px !important; }

.bg-gradient-info { background: linear-gradient(135deg, #0288d1, #01579b); }
.bg-gradient-warning { background: linear-gradient(135deg, #f57c00, #e65100); }
.bg-gradient-success { background: linear-gradient(135deg, #2e7d32, #1b5e20); }

.grid-surface-light { background: #f1f5f9; color: rgba(0,0,0,0.8); }
.grid-surface-dark { background: #1e1e24; color: rgba(255,255,255,0.85); }

.zebra-light-a { background: #ffffff; }
.zebra-light-b { background: #f8fafc; }
.zebra-dark-a { background: rgba(255,255,255,0.03); }
.zebra-dark-b { background: rgba(255,255,255,0.06); }

.row-active-light { background: #e0f7fa !important; border-left: 4px solid #00acc1; }
.row-active-dark { background: rgba(0, 172, 193, 0.15) !important; border-left: 4px solid #00acc1; }

.pin-card{ border-radius: 14px !important; }
.pin-dark{ background: #121216; border-color: rgba(255,255,255,0.10) !important; }
.pin-head{ padding: 18px; display: flex; align-items: center; justify-content: space-between; color: #fff; position: relative; overflow: hidden; }
.pin-head-left{ display: flex; align-items: center; gap: 14px; min-width: 0; }
.pin-head-badge{ width: 40px; height: 40px; border-radius: 12px; display: flex; align-items: center; justify-content: center; background: rgba(255,255,255,0.18); border: 1px solid rgba(255,255,255,0.22); }
.pin-title{ font-weight: 900; text-transform: uppercase; letter-spacing: 0.6px; line-height: 1.1; }
.pin-subtitle{ opacity: 0.85; font-weight: 700; font-size: 12px; margin-top: 2px; }

.pin-head-neutral{ background: linear-gradient(135deg, #111827, #0b1220); }
.pin-head-success{ background: linear-gradient(135deg, #0f3d2e, #09261d); }
.pin-head-danger{ background: linear-gradient(135deg, #4a0f18, #2a070d); }
.pin-head-warning{ background: linear-gradient(135deg, #f57c00, #e65100); }

.pin-body{ padding: 16px; }
.pin-surface{ position: relative; border-radius: 14px; padding: 18px; background: rgba(0,0,0,0.02); overflow: hidden; }
.pin-dark .pin-surface{ background: rgba(255,255,255,0.05); }

.pin-primary-btn, .pin-secondary-btn, .pin-confirm-btn{ border-radius: 12px !important; font-weight: 900 !important; }
.pin-alert{ display: flex; align-items: flex-start; gap: 10px; padding: 12px; border-radius: 12px; font-weight: 900; text-transform: uppercase; justify-content: center; margin-bottom: 14px; }
.pin-alert-error{ background: rgba(183, 28, 28, 0.10); color: #b71c1c; border: 1px solid rgba(183, 28, 28, 0.20); }

.v-theme--dark {
  .text-grey-darken-4, .text-grey-darken-3, .text-grey-darken-2, .text-grey-darken-1, .text-grey {
    color: rgba(255,255,255,0.9) !important;
  }
}
</style>
