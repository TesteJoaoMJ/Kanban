<template>
  <div
    id="pcp-layout-wrapper"
    class="pcp-layout font-sans fill-height d-flex flex-column relative overflow-hidden"
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
        class="header-bar px-6 py-4 d-flex align-center justify-space-between flex-shrink-0 flex-wrap gap-2"
        :class="themeStore.currentMode === 'light' ? 'bg-white border-b border-grey-lighten-2 shadow-sm' : 'bg-glass-header border-bottom-white-05'"
      >
        <div class="d-flex flex-column mb-2 mb-sm-0">
          <div class="breadcrumb text-caption">
            <span class="opacity-70">Industrial</span>
            <span class="mx-2 opacity-50">></span>
            <span class="font-weight-bold">PCP (Planejamento)</span>
          </div>
          <div class="text-h5 font-weight-black tracking-tight leading-none mt-1 text-uppercase d-flex align-center gap-2" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">
            Gestão de Produção
            <v-chip v-if="companyStore.isDemoMode" size="small" color="purple-accent-4" class="font-weight-bold chip-3d">MODO DEMO ATIVO</v-chip>
          </div>
        </div>

        <div class="d-flex align-center flex-wrap" style="gap: 10px;">
          <v-menu location="bottom end" :close-on-content-click="false">
            <template v-slot:activator="{ props }">
              <v-btn
                v-bind="props"
                prepend-icon="mdi-file-pdf-box"
                :color="themeStore.currentMode === 'light' ? 'grey-darken-3' : 'white'"
                variant="outlined"
                class="btn-3d px-4 font-weight-bold text-caption text-uppercase"
                height="40"
              >
                Relatórios
              </v-btn>
            </template>
            <v-card min-width="340" class="rounded-lg">
              <v-list density="compact">
                <v-list-subheader class="text-uppercase font-weight-bold">Filtro de Período</v-list-subheader>
                <v-list-item class="px-2">
                  <v-chip-group v-model="reportPeriod" selected-class="text-primary" mandatory>
                    <v-chip value="today" size="small" filter>Hoje</v-chip>
                    <v-chip value="week" size="small" filter>Semana</v-chip>
                    <v-chip value="month" size="small" filter>Mês</v-chip>
                    <v-chip value="year" size="small" filter>Ano</v-chip>
                  </v-chip-group>
                </v-list-item>

                <v-divider class="my-2"></v-divider>

                <v-list-subheader class="text-uppercase font-weight-bold">Formato</v-list-subheader>
                <v-list-item class="px-2">
                   <v-radio-group v-model="reportGrouping" inline density="compact" hide-details>
                      <v-radio label="Lista de Itens" value="items" color="primary"></v-radio>
                      <v-radio label="Agrupar por Pedido" value="orders" color="primary"></v-radio>
                   </v-radio-group>
                </v-list-item>

                <v-divider class="my-2"></v-divider>

                <v-list-subheader class="text-uppercase font-weight-bold">Gerar Relatório</v-list-subheader>

                <v-list-item
                  title="Resumo Gerencial (KPIs)"
                  subtitle="Ranking de Tecidos, Operadores e Faturamento"
                  @click="generateReport('kpi')"
                  :disabled="loadingPdf"
                >
                  <template v-slot:prepend><v-icon color="purple">mdi-chart-box</v-icon></template>
                </v-list-item>

                <v-list-item
                  title="Aba Atual"
                  subtitle="Relatório da etapa visualizada"
                  @click="generateReport('current')"
                  :disabled="loadingPdf"
                >
                  <template v-slot:prepend><v-icon color="indigo">mdi-table</v-icon></template>
                </v-list-item>

                 <v-list-item
                  title="Geral (Todas as Etapas)"
                  subtitle="Um relatório por página/aba"
                  @click="generateReport('all')"
                  :disabled="loadingPdf"
                >
                  <template v-slot:prepend><v-icon color="teal">mdi-file-document-multiple</v-icon></template>
                </v-list-item>
              </v-list>
              <div v-if="loadingPdf" class="pa-2 text-center text-caption text-grey">
                <v-progress-circular indeterminate size="20" width="2" color="primary" class="mr-2"></v-progress-circular>
                Gerando PDF...
              </div>
            </v-card>
          </v-menu>

          <v-btn-toggle
            v-model="viewMode"
            mandatory
            density="compact"
            variant="outlined"
            class="btn-group-rect rounded-lg btn-3d"
            divided
            :color="themeStore.currentMode === 'light' ? 'indigo-darken-2' : 'white'"
          >
            <v-btn value="list" class="px-4 font-weight-bold text-caption text-uppercase">
              <v-icon start size="small">mdi-format-list-bulleted</v-icon> Lista
            </v-btn>
            <v-btn value="grouped" class="px-4 font-weight-bold text-caption text-uppercase">
              <v-icon start size="small">mdi-package-variant-closed</v-icon> Por Pedido
            </v-btn>
            <v-btn value="kanban" class="px-4 font-weight-bold text-caption text-uppercase">
              <v-icon start size="small">mdi-view-week</v-icon> Semanal
            </v-btn>
          </v-btn-toggle>

          <v-btn
            color="indigo-darken-3"
            variant="flat"
            class="btn-3d px-4 font-weight-bold text-caption text-uppercase letter-spacing-1"
            prepend-icon="mdi-printer-3d-nozzle"
            height="40"
            :to="{ name: 'PrintingStation' }"
          >
            Estação Impressão
          </v-btn>

          <v-btn
            :color="activeTab === 'legado' ? 'red-darken-2' : (themeStore.currentMode === 'light' ? 'grey-darken-3' : 'white')"
            :variant="activeTab === 'legado' ? 'flat' : 'outlined'"
            class="btn-3d px-4 font-weight-bold text-caption text-uppercase ml-2"
            height="40"
            @click="switchTab(activeTab === 'legado' ? kpiTabs[0]?.id || 'pcp' : 'legado')"
          >
            <v-icon start size="small">mdi-archive</v-icon> Legado
          </v-btn>
        </div>
      </div>

<div v-if="activeTab !== 'legado'" class="px-6 pt-4 pb-2 flex-shrink-0">
        <div class="d-flex align-center flex-nowrap w-100 overflow-x-auto pb-3 custom-scroll-x kpi-scroll-container" style="gap: 12px;">

          <template v-for="(kpi, idx) in kpiTabs" :key="kpi.id">
            <v-card
              class="kpi-card kpi-rect hover-elevate py-3 px-4 cursor-pointer position-relative transition-all"
              :class="[
                kpi.gradient,
                activeTab === kpi.id ? 'kpi-active-border elevation-6' : 'elevation-2 opacity-90'
              ]"
              :data-tab-id="kpi.id"
              v-ripple
              @click="switchTab(kpi.id)"
              style="min-width: 140px; flex: 1 1 0;"
            >
              <div class="kpi-bg-icon"><v-icon>{{ kpi.icon }}</v-icon></div>
              <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                <div class="d-flex align-center text-truncate" style="gap: 6px;">
                  <v-icon size="16" class="opacity-80">{{ kpi.icon }}</v-icon>
                  <span class="kpi-label text-truncate">{{ kpi.label }}</span>
                </div>
                <div class="kpi-number-group my-1">
                  <span class="text-body-2 font-weight-medium mr-1 opacity-70">Qtd:</span>
                  <span class="kpi-value">{{ kpi.count }}</span>
                </div>
                <div class="kpi-footer mt-1 text-truncate">{{ kpi.footer }}</div>
              </div>
            </v-card>

            <v-icon
              v-if="idx < kpiTabs.length - 1"
              size="20"
              class="opacity-40 flex-shrink-0"
              :color="themeStore.currentMode === 'light' ? 'grey-darken-2' : 'white'"
            >
              mdi-chevron-right
            </v-icon>
          </template>

          <div class="d-flex align-center pl-1 ml-1 h-100">
            <v-card
              class="kpi-card kpi-rect hover-elevate py-2 px-3 cursor-pointer d-flex flex-column align-center justify-center transition-all opacity-70"
              :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-4 text-grey-darken-2' : 'bg-transparent text-white'"
              style="min-width: 110px; width: 110px; min-height: 110px; border: 2px dashed currentColor !important; box-shadow: none !important;"
              v-ripple
              @click="appStore.showSnackbar('Funcionalidade de criação de etapa em desenvolvimento.', 'info')"
            >
              <v-icon size="24" class="mb-1 opacity-70">mdi-plus</v-icon>
              <span class="text-[10px] font-weight-black text-uppercase opacity-80 text-center" style="line-height: 1.2;">Nova<br>Etapa</span>
            </v-card>
          </div>

        </div>
      </div>

      <div v-else class="px-6 pt-4 pb-2 flex-shrink-0">
         <v-alert
           color="red-darken-3"
           variant="tonal"
           icon="mdi-archive-alert"
           class="font-weight-bold py-3 text-uppercase"
         >
           Você está visualizando o banco de dados Legado (Pedidos Antigos)
         </v-alert>
      </div>

      <div class="px-6 pt-2 pb-2 flex-shrink-0">
        <div class="controls-bar d-flex flex-column" :class="themeStore.currentMode === 'light' ? 'controls-light' : 'controls-dark'">
          <div class="d-flex align-center justify-space-between flex-wrap" style="gap: 10px;">
            <div class="search-wrap d-flex align-center flex-grow-1" :class="themeStore.currentMode === 'light' ? 'search-light' : 'search-dark'">
              <v-icon :color="themeStore.currentMode === 'light' ? 'grey-darken-1' : 'white-70'">mdi-magnify</v-icon>
              <input
                v-model="filters.search"
                type="text"
                :placeholder="isBillingTab ? 'BUSCAR (CLIENTE, OP)...' : 'BUSCAR (CLIENTE, OP, REFERÊNCIA)...'"
                class="clean-input flex-grow-1 text-uppercase font-weight-bold"
              />
            </div>

            <v-btn-toggle
              v-if="activeTab === 'faturamento'"
              v-model="faturamentoSubTab"
              mandatory
              density="compact"
              variant="outlined"
              class="btn-group-rect rounded-lg mx-2 btn-3d"
              divided
              :color="themeStore.currentMode === 'light' ? 'indigo-darken-2' : 'white'"
            >
              <v-btn value="a_faturar" class="px-3 font-weight-bold text-caption text-uppercase">A Faturar</v-btn>
              <v-btn value="faturado" class="px-3 font-weight-bold text-caption text-uppercase">Faturado</v-btn>
            </v-btn-toggle>

            <v-chip-group v-if="(currentTabStatuses || []).length > 0" v-model="filters.status" multiple column class="mx-2">
              <v-chip
                v-for="s in currentTabStatuses"
                :key="s.value"
                :value="s.value"
                filter
                size="small"
                variant="tonal"
                class="font-weight-bold chip-3d"
              >
                {{ s.label }}
              </v-chip>
            </v-chip-group>

            <v-chip-group
              v-if="activeTab === 'faturamento' && faturamentoSubTab === 'a_faturar'"
              v-model="billingFilters.onlyVisible"
              mandatory
              class="mx-2"
            >
              <v-chip :value="true" filter size="small" variant="tonal" color="indigo" class="font-weight-bold chip-3d">
                VISÍVEIS (SOLTOS)
              </v-chip>
              <v-chip :value="false" filter size="small" variant="tonal" color="grey" class="font-weight-bold chip-3d">
                TODOS OS PEDIDOS
              </v-chip>
            </v-chip-group>

            <div v-if="activeTab === 'liberacao' || activeTab === 'legado'" class="d-flex align-center">
              <v-btn-toggle
                v-model="flowMode"
                mandatory
                density="compact"
                variant="outlined"
                class="btn-group-rect rounded-lg btn-3d"
                divided
                :color="themeStore.currentMode === 'light' ? 'grey-darken-3' : 'white'"
              >
                <v-btn value="current" class="px-3 font-weight-bold text-caption text-uppercase">Atual</v-btn>
                <v-btn value="legacy" class="px-3 font-weight-bold text-caption text-uppercase">Legado</v-btn>
              </v-btn-toggle>
            </div>

            <v-select
              v-model="sortOrder"
              :items="sortOptions"
              item-title="label"
              item-value="value"
              variant="outlined"
              density="compact"
              hide-details
              class="ui-field"
              style="max-width: 210px;"
              :label="'Ordenar'"
            ></v-select>

            <div class="hint-tooltip" data-title="Recarregar Tela">
              <v-btn variant="flat" class="btn-3d" height="40" color="indigo" @click="refreshCurrentData" icon rounded="0">
                <v-icon>mdi-refresh</v-icon>
              </v-btn>
            </div>

            <v-menu v-model="filtersDropdownOpen" location="bottom end" :close-on-content-click="false" width="420">
              <template v-slot:activator="{ props }">
                <v-btn
                  v-bind="props"
                  variant="outlined"
                  class="btn-3d"
                  height="40"
                  prepend-icon="mdi-filter-variant"
                  :color="themeStore.currentMode === 'light' ? 'grey-darken-3' : 'white'"
                >
                  Filtros
                </v-btn>
              </template>

              <v-card class="rounded-0 border-thin shadow-lg">
                <div class="px-4 py-3 bg-grey-darken-3 text-white font-weight-black text-uppercase text-caption d-flex justify-space-between align-center">
                  <span>Data</span>
                  <v-btn size="x-small" variant="text" icon="mdi-close" @click="filtersDropdownOpen = false"></v-btn>
                </div>

                <div class="pa-4" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5' : 'bg-white-05'">
                  <v-row dense>
                    <v-col cols="6">
                      <v-text-field v-model="filters.dateStart" label="De" type="date" variant="outlined" density="compact" class="ui-field bg-white" hide-details />
                    </v-col>
                    <v-col cols="6">
                      <v-text-field v-model="filters.dateEnd" label="Até" type="date" variant="outlined" density="compact" class="ui-field bg-white" hide-details />
                    </v-col>
                  </v-row>
                  <div class="mt-3 text-caption font-weight-bold opacity-70">
                    Aplica em <span class="font-weight-black">Entrada</span> (itens/pedidos) e, em Liberação, prioriza <span class="font-weight-black">Entrega Prev.</span>
                  </div>
                </div>

                <div class="px-4 py-3 bg-white border-t d-flex justify-end gap-2">
                  <v-btn variant="outlined" class="btn-3d" height="32" color="grey-darken-1" @click="clearFilters">Limpar</v-btn>
                  <v-btn variant="flat" class="btn-3d" height="32" color="indigo" @click="filtersDropdownOpen = false">Aplicar</v-btn>
                </div>
              </v-card>
            </v-menu>
          </div>
        </div>
      </div>

      <div class="flex-grow-1 px-6 pb-0 overflow-hidden d-flex flex-column position-relative">

        <div v-if="viewMode === 'kanban'" class="flex-grow-1 overflow-x-auto custom-scroll-x d-flex gap-0 h-100 pb-2" ref="scrollContainerKanban">
          <div
            v-for="col in displayedKanban"
            :key="col.id"
            class="kanban-column d-flex flex-column h-100 border-r"
            :class="[col.bgClass, themeStore.currentMode === 'light' ? 'border-grey-lighten-2' : 'border-white-05']"
            style="min-width: 320px; width: 320px;"
            @dragover.prevent
            @drop.prevent="onKanbanDrop(col.id, $event)"
          >
            <div class="px-3 py-3 d-flex align-center justify-space-between border-b"
                 :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-white-05'">
              <div class="d-flex flex-column">
                <div class="text-caption font-weight-black text-uppercase">{{ col.title }}</div>
                <div class="text-[11px] opacity-70 font-weight-medium">
                  {{ col.items.length }} item(ns)
                  <span v-if="col.legacyCount > 0" class="ml-2 opacity-80">• {{ col.legacyCount }} legado</span>
                </div>
              </div>
              <v-chip size="x-small" label class="font-weight-black chip-3d" rounded="0"
                      :color="themeStore.currentMode === 'light' ? 'grey-darken-3' : 'white'">
                {{ col.totalMeters }}m
              </v-chip>
            </div>

            <div class="flex-grow-1 overflow-auto custom-scroll pa-2 d-flex flex-column gap-2">
              <v-card
                v-for="card in col.items"
                :key="card.__kkey"
                v-memo="[card.__kkey, card.status, themeStore.currentMode]"
                class="kanban-card border-thin rounded-0"
                :class="themeStore.currentMode === 'light' ? 'bg-white' : 'glass-card'"
                elevation="0"
                draggable="true"
                @dragstart="onKanbanDragStart(card, col.id, $event)"
              >
                <div class="px-3 py-2 d-flex align-center justify-space-between gap-2">
                  <div class="d-flex flex-column">
                    <div class="d-flex align-center gap-2 flex-wrap">
                      <v-chip size="x-small" label class="font-weight-black chip-3d" color="primary" rounded="0">
                        OP #{{ card.orderNumber }}
                      </v-chip>

                      <v-chip
                        v-if="card.deliveryBadge"
                        size="x-small"
                        label
                        class="font-weight-black chip-3d"
                        rounded="0"
                        :color="deliveryBadgeColor(card.deliveryBadge)"
                      >
                        {{ deliveryBadgeLabel(card.deliveryBadge) }}
                      </v-chip>

                      <v-chip
                        v-if="card.isLegacy"
                        size="x-small"
                        label
                        class="font-weight-black chip-3d"
                        rounded="0"
                        color="red-darken-2"
                      >
                        LEGADO
                      </v-chip>
                    </div>

                    <div class="text-caption font-weight-black text-uppercase text-truncate" style="max-width: 280px;">
                      {{ card.customerName }}
                    </div>

                    <div class="text-[11px] opacity-75 text-truncate" style="max-width: 280px;">
                      {{ card.title }}
                    </div>
                  </div>

                  <div class="d-flex flex-column align-end">
                    <div class="text-caption font-weight-black">
                      {{ card.quantityMeters }}m
                    </div>
                    <div class="text-[11px] opacity-70 font-mono">
                      {{ formatDateShort(card.bestDate) }}
                    </div>
                  </div>
                </div>

                <div class="px-3 pb-2 d-flex align-center justify-space-between gap-2">
                  <div class="d-flex align-center gap-2">
                    <div class="hint-tooltip" data-title="Clique para ver a estampa em Alta Qualidade">
                        <div class="icon-3d-wrapper cursor-pointer" @click="openImage(card.raw)">
                            <v-icon size="20" class="icon-3d" :color="themeStore.currentMode === 'light' ? 'indigo-darken-3' : 'indigo-lighten-3'">mdi-tshirt-crew</v-icon>
                            <div class="icon-3d-shine"></div>
                        </div>
                    </div>

                    <v-chip size="x-small" label rounded="0" class="font-weight-bold chip-3d" :color="statusChipColor(card.status)">
                      {{ statusLabel(card.status) }}
                    </v-chip>
                  </div>

                  <div class="d-flex align-center gap-1">
                    <div class="hint-tooltip" data-title="Detalhes">
                      <v-btn class="square-btn btn-3d" variant="flat" color="indigo" @click.stop="openLaunchDetail(card.raw)">
                        <v-icon size="16">mdi-file-document-outline</v-icon>
                      </v-btn>
                    </div>

                    <div class="hint-tooltip" data-title="Avançar Etapa">
                       <v-btn class="square-btn btn-3d" variant="flat" :color="getNextActionColor(card.status)" @click.stop="advanceStatus(card.raw)" @mouseenter="setItemHighlight(card.raw)" @mouseleave="clearHighlight">
                          <v-icon size="16">{{ getNextActionIcon(card.status) }}</v-icon>
                        </v-btn>
                    </div>

                    <div class="hint-tooltip" data-title="Reportar Erro (Devolver p/ Impressão)" v-if="activeTab === 'calandra' || col.id === 'calandra'">
                        <v-btn class="square-btn btn-3d" variant="flat" color="red-darken-3" @click.stop="openReprintError(card.raw)">
                          <v-icon size="16">mdi-printer-off</v-icon>
                        </v-btn>
                    </div>
                  </div>
                </div>
              </v-card>

              <div v-if="col.items.length === 0" class="pa-6 text-center opacity-70">
                <v-icon size="34" class="mb-1">mdi-inbox-arrow-down-outline</v-icon>
                <div class="text-caption font-weight-bold">Vazio</div>
              </div>
            </div>
          </div>
        </div>

        <v-card
          v-else
          class="flex-grow-1 d-flex flex-column rounded-0 border-thin overflow-hidden position-relative"
          :class="themeStore.currentMode === 'light' ? 'bg-white shadow-sm' : 'glass-card border-white-05'"
          :elevation="0"
        >
          <div class="grid-scroll flex-grow-1 overflow-auto custom-scroll position-relative" ref="scrollContainerList">

            <div class="grid-header sticky-head border-b" :class="[themeStore.currentMode === 'light' ? 'grid-surface-light' : 'grid-surface-dark', gridClass]">
                <div class="cell center header-text border-r">
                    <v-checkbox-btn :model-value="isAllPageSelected" @update:modelValue="toggleSelectAllPage" density="compact" class="chk-fixed"></v-checkbox-btn>
                </div>

                <template v-if="isBillingTab">
                    <div class="cell center header-text border-r">#OP</div>
                    <div class="cell header-text border-r">Data</div>
                    <div class="cell header-text border-r">Cliente / Pedido</div>
                    <div class="cell center header-text border-r">Status Produção</div>
                    <div class="cell center header-text border-r">Financeiro</div>
                    <div class="cell right header-text border-r">Total (R$)</div>
                    <div class="cell center header-text border-r">Aviso</div>
                    <div class="cell center header-text">Ações</div>
                </template>

                <template v-else-if="activeTab === 'liberacao'">
                    <div class="cell center header-text border-r">Tipo</div>
                    <div class="cell center header-text border-r">Arte</div>
                    <div class="cell header-text border-r">Cliente / Item</div>
                    <div class="cell center header-text border-r">Previsão</div>
                    <div class="cell center header-text border-r">Status</div>
                    <div class="cell center header-text">Ações</div>
                </template>

                <template v-else>
                    <div class="cell center header-text border-r">#</div>
                    <div class="cell center header-text border-r">Arte</div>
                    <div class="cell header-text border-r">Referência</div>
                    <div class="cell header-text border-r">{{ activeTab === 'design' ? 'Cliente / Tag' : 'Cliente / OP' }}</div>
                    <div class="cell center header-text border-r">Entrada</div>
                    <div class="cell center header-text border-r">Qtd (m)</div>
                    <div class="cell center header-text border-r">Status</div>
                    <div class="cell center header-text">Ações</div>
                </template>
            </div>

            <div v-if="store.loading" class="d-flex flex-column justify-center align-center h-100 py-10" style="min-width: 1000px;">
              <v-progress-circular indeterminate color="indigo" size="48" width="4"></v-progress-circular>
            </div>
            <div v-else-if="filteredList.length === 0" class="d-flex flex-column justify-center align-center h-100 opacity-60 gap-2 py-10" style="min-width: 1000px;">
              <v-icon size="48" color="grey-lighten-1">mdi-clipboard-text-off-outline</v-icon>
              <span class="text-body-1 font-weight-medium text-grey">Nenhum registro encontrado</span>
            </div>

            <template v-else>
                <template v-if="viewMode === 'grouped'">
                    <div class="pa-2">
                        <v-expansion-panels variant="accordion">
                            <v-expansion-panel
                                v-for="group in displayedGrouped"
                                :key="group.orderId"
                                class="mb-2 border-thin rounded-0"
                                :class="themeStore.currentMode === 'light' ? 'bg-white' : 'glass-card'"
                                elevation="0"
                            >
                                <v-expansion-panel-title class="py-2" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5' : 'bg-white-05'">
                                    <div class="d-flex align-center gap-3 mr-4" @click.stop>
                                         <v-checkbox-btn
                                            :model-value="isGroupSelected(group)"
                                            :indeterminate="isGroupIndeterminate(group)"
                                            @update:modelValue="(val) => toggleSelectGroup(group, val)"
                                            density="compact"
                                            class="chk-fixed"
                                         ></v-checkbox-btn>

                                        <v-chip color="primary" label size="small" class="font-weight-black chip-3d" rounded="0">OP #{{ group.orderNumber }}</v-chip>
                                        <v-chip v-if="group.deliveryBadge" :color="deliveryBadgeColor(group.deliveryBadge)" label size="small" class="font-weight-black chip-3d" rounded="0">{{ deliveryBadgeLabel(group.deliveryBadge) }}</v-chip>
                                        <v-chip v-if="group.isLegacy" color="red-darken-2" label size="small" class="font-weight-black chip-3d" rounded="0">LEGADO</v-chip>
                                        <div class="d-flex flex-column">
                                            <span class="font-weight-black text-subtitle-2 text-uppercase">{{ group.customerName }}</span>
                                            <span class="text-caption opacity-70">{{ group.items.length }} Itens • {{ group.totalMeters }}m Total</span>
                                        </div>
                                    </div>
                                    <v-spacer></v-spacer>
                                    <div class="d-flex align-center gap-2" @click.stop>
                                        <v-menu location="bottom end">
                                            <template v-slot:activator="{ props }">
                                                <v-btn v-bind="props" size="small" variant="tonal" class="text-caption font-weight-bold btn-3d">
                                                    Ações Lote <v-icon end>mdi-chevron-down</v-icon>
                                                </v-btn>
                                            </template>
                                            <v-list density="compact" nav>
                                                <v-list-item title="Avançar Todos" prepend-icon="mdi-fast-forward" @click="batchAdvanceGroup(group)" @mouseenter="setGroupHighlight(group)" @mouseleave="clearHighlight"></v-list-item>
                                                <v-list-item v-if="userStore.isSuperAdmin" title="Forçar Status Pedido" prepend-icon="mdi-package-variant" @click="openManualStatus({ id: group.orderId }, 'order')"></v-list-item>
                                            </v-list>
                                        </v-menu>
                                    </div>
                                </v-expansion-panel-title>
                          <v-expansion-panel-text class="pa-0">
                              <div
                                  v-for="(item, itIdx) in group.items"
                                  :key="rowKey(item)"
                                  v-memo="[rowKey(item), item.status, isSelected(item.id), themeStore.currentMode]"
                                  class="grid-row border-b"
                                  :class="[gridClass, itIdx % 2 !== 0 ? (themeStore.currentMode === 'light' ? 'bg-grey-lighten-5' : 'bg-white-05') : '']"
                              >
                                  <div class="cell center border-r">
                                      <v-checkbox-btn :model-value="isSelected(item.id)" @update:modelValue="(val) => toggleSelect(item.id, val)" density="compact" class="chk-fixed"></v-checkbox-btn>
                                  </div>

                                  <template v-if="isBillingTab">
                                      <div class="cell center border-r"><span class="pill-ref">ITEM</span></div>
                                      <div class="cell border-r"><span class="list-text font-mono">{{ formatDate(item.created_at) }}</span></div>
                                      <div class="cell border-r">
                                          <div class="d-flex flex-column">
                                              <span class="list-text font-weight-black text-uppercase">{{ item.stamp_ref }}</span>
                                              <span class="text-caption opacity-70">{{ item.fabric_type }}</span>
                                          </div>
                                      </div>
                                      <div class="cell center border-r">
                                          <v-chip size="x-small" :color="getStatusConfig(item.status).color" label class="font-weight-bold chip-3d">
                                              {{ getStatusConfig(item.status).label }}
                                          </v-chip>
                                      </div>
                                      <div class="cell center border-r">-</div>
                                      <div class="cell right border-r px-4">-</div>
                                      <div class="cell center border-r">-</div>
                                      <div class="cell center">
                                          <div class="actions-inline">
                                              <div class="hint-tooltip" data-title="Histórico">
                                                <v-btn class="square-btn btn-3d" variant="flat" color="blue-grey" icon @click.stop="openLogs(item)">
                                                    <v-icon size="16">mdi-history</v-icon>
                                                </v-btn>
                                              </div>
                                          </div>
                                      </div>
                                  </template>

                                  <template v-else>
                                      <div class="cell center border-r text-caption opacity-50">{{ itIdx + 1 }}</div>
                                      <div class="cell center border-r pa-1">
                                          <div class="hint-tooltip" data-title="Clique para ver a estampa em Alta Qualidade">
                                              <div class="icon-3d-wrapper cursor-pointer" @click="openImage(item)">
                                                  <v-icon size="20" class="icon-3d" :color="themeStore.currentMode === 'light' ? 'indigo-darken-3' : 'indigo-lighten-3'">mdi-tshirt-crew</v-icon>
                                                  <div class="icon-3d-shine"></div>
                                              </div>
                                          </div>
                                      </div>
                                      <div class="cell border-r"><span class="font-weight-bold text-caption">{{ item.stamp_ref }}</span></div>
                                      <div class="cell border-r"><span class="text-caption">{{ item.fabric_type || '-' }}</span></div>
                                      <div class="cell center border-r"><span class="font-mono text-caption">{{ formatDate(item.created_at) }}</span></div>
                                      <div class="cell center border-r"><span class="font-weight-black font-mono text-caption">{{ item.quantity_meters }}m</span></div>
                                      <div class="cell center border-r">
                                          <v-chip size="x-small" :color="getStatusConfig(item.status).color" label class="font-weight-bold text-uppercase chip-3d">
                                              {{ getStatusConfig(item.status).label }}
                                          </v-chip>
                                      </div>
                                      <div class="cell center">
                                          <div class="actions-inline">
                                              <div class="hint-tooltip" data-title="Histórico">
                                                <v-btn class="square-btn btn-3d" variant="flat" color="blue-grey" icon @click.stop="openLogs(item)">
                                                    <v-icon size="16">mdi-history</v-icon>
                                                </v-btn>
                                              </div>
                                              <div class="hint-tooltip" data-title="Avançar Etapa">
                                                <v-btn class="square-btn btn-3d" variant="flat" :color="getNextActionColor(item.status)" icon @click.stop="advanceStatus(item)">
                                                    <v-icon size="16">{{ getNextActionIcon(item.status) }}</v-icon>
                                                </v-btn>
                                              </div>
                                              <div class="hint-tooltip" data-title="Reportar Erro" v-if="activeTab === 'calandra'">
                                                <v-btn class="square-btn btn-3d" variant="flat" color="red-darken-3" @click.stop="openReprintError(item)">
                                                    <v-icon size="16">mdi-printer-off</v-icon>
                                                </v-btn>
                                              </div>
                                          </div>
                                      </div>
                                  </template>
                              </div>
                          </v-expansion-panel-text>
                            </v-expansion-panel>
                        </v-expansion-panels>
                    </div>
                </template>

                <template v-else>
                  <div
                      v-for="(item, index) in displayedList"
                      :key="rowKey(item)"
                      v-memo="[rowKey(item), item.status, item.financial_status, item.billing_queue_visible, item.billing_alert, isSelected(item.id), themeStore.currentMode]"
                      class="grid-row border-b"
                      :class="[zebraClass(index), gridClass, selectedIds.has(String(item.id)) ? (themeStore.currentMode === 'light' ? 'grid-selected-light' : 'grid-selected-dark') : '']"
                  >
                    <div class="cell center border-r">
                          <v-checkbox-btn :model-value="isSelected(item.id)" @update:modelValue="(val) => toggleSelect(item.id, val)" density="compact" class="chk-fixed" @click.stop></v-checkbox-btn>
                      </div>

                      <template v-if="isBillingTab">
                          <div class="cell center border-r"><span class="pill-ref">{{ String(item.order_number || '0').padStart(4, '0') }}</span></div>
                          <div class="cell border-r"><span class="list-text font-mono">{{ formatDate(item.created_at) }}</span></div>
                          <div class="cell border-r">
                              <div class="d-flex flex-column">
                                  <span class="list-text font-weight-black text-uppercase">{{ item.customer_name }}</span>
                                  <span class="text-caption opacity-70">Ped: #{{ item.order_number }}</span>
                              </div>
                          </div>
                          <div class="cell center border-r">
                              <v-chip size="x-small" :color="getStatusConfig(item.status).color" label class="font-weight-bold chip-3d">{{ getStatusConfig(item.status).label }}</v-chip>
                          </div>
                          <div class="cell center border-r">
                              <v-chip size="x-small" :color="getBillingStatusColor(item.financial_status)" variant="flat" class="font-weight-bold chip-3d">{{ item.financial_status || 'Pendente' }}</v-chip>
                          </div>
                          <div class="cell right border-r px-4"><span class="font-mono font-weight-black">{{ formatCurrency(item.total_value) }}</span></div>
                          <div class="cell center border-r">
                              <div class="hint-tooltip" :data-title="item.billing_alert ? 'Ver Aviso' : 'Adicionar Aviso'">
                                  <v-btn icon size="x-small" variant="text" :color="item.billing_alert ? 'red' : 'grey'" @click.stop="openBillingAlertModal(item)">
                                      <v-icon size="20">{{ item.billing_alert ? 'mdi-bell-ring' : 'mdi-bell-outline' }}</v-icon>
                                  </v-btn>
                              </div>
                          </div>
                          <div class="cell center">
                              <div class="actions-inline">
                                  <div class="hint-tooltip" data-title="Visibilidade">
                                      <v-btn class="square-btn btn-3d" variant="flat" color="indigo" @click="toggleBillingVisibility(item)">
                                          <v-icon size="16">{{ item.billing_queue_visible ? 'mdi-eye' : 'mdi-eye-off' }}</v-icon>
                                      </v-btn>
                                  </div>
                                  <div class="hint-tooltip" data-title="Agendar Expedição">
                                      <v-btn class="square-btn btn-3d" variant="flat" color="green" @click="openScheduleModal(item)"><v-icon size="16">mdi-calendar-check</v-icon></v-btn>
                                  </div>
                                  <v-menu location="bottom end">
                                      <template v-slot:activator="{ props }"><v-btn v-bind="props" class="square-btn btn-3d" variant="flat" color="grey-darken-3"><v-icon size="16">mdi-chevron-down</v-icon></v-btn></template>
                                      <v-list density="compact" nav>
                                          <v-list-item v-if="userStore.isSuperAdmin" title="Forçar Status" prepend-icon="mdi-alert" @click="openManualStatus(item, 'order')"></v-list-item>
                                      </v-list>
                                  </v-menu>
                              </div>
                          </div>
                      </template>

                      <template v-else-if="activeTab === 'liberacao'">
                          <div class="cell center border-r">
                              <v-icon v-if="isGhostRow(item)" color="error" title="Fantasma">mdi-ghost</v-icon>
                              <v-icon v-else color="success" title="Item Pronto">mdi-package-variant-closed</v-icon>
                          </div>
                          <div class="cell center border-r pa-1">
                              <div v-if="!isGhostRow(item)" class="hint-tooltip" data-title="Clique para ver a estampa em Alta Qualidade">
                                  <div class="icon-3d-wrapper cursor-pointer" @click="openImage(item)">
                                      <v-icon size="20" class="icon-3d" :color="themeStore.currentMode === 'light' ? 'indigo-darken-3' : 'indigo-lighten-3'">mdi-tshirt-crew</v-icon>
                                      <div class="icon-3d-shine"></div>
                                  </div>
                              </div>
                              <span v-else class="text-[10px] font-weight-bold">N/A</span>
                          </div>
                          <div class="cell border-r">
                              <div class="d-flex flex-column">
                                  <span class="list-text font-weight-bold">{{ isGhostRow(item) ? item.customer_name : item.order?.customer_name }}</span>
                                  <span class="text-caption opacity-70">{{ isGhostRow(item) ? `PEDIDO #${item.order_number}` : `Item: ${item.stamp_ref}` }}</span>
                              </div>
                          </div>
                          <div class="cell center border-r">
                              <span class="list-text font-mono font-weight-bold" :class="isGhostRow(item) ? 'text-error' : ''">{{ formatDate(getReleaseDate(item)) }}</span>
                          </div>
                          <div class="cell center border-r">
                              <v-chip size="x-small" :color="getStatusConfig(getReleaseStatus(item)).color" label class="font-weight-bold chip-3d">{{ getStatusConfig(getReleaseStatus(item)).label }}</v-chip>
                          </div>
                          <div class="cell center">
                              <div class="actions-inline">
                                  <div class="hint-tooltip" data-title="Entregar" v-if="!isGhostRow(item)">
                                      <v-btn class="square-btn btn-3d" variant="flat" color="green" @click="markOrderDeliveredFromItem(item)"><v-icon size="16">mdi-truck-check</v-icon></v-btn>
                                  </div>
                                  <v-menu location="bottom end">
                                      <template v-slot:activator="{ props }"><v-btn v-bind="props" class="square-btn btn-3d" variant="flat" color="grey-darken-3"><v-icon size="16">mdi-chevron-down</v-icon></v-btn></template>
                                      <v-list density="compact" nav>
                                          <v-list-item v-if="userStore.isSuperAdmin" title="Forçar Status" prepend-icon="mdi-alert" @click="openManualStatus(item, isGhostRow(item) ? 'order' : 'item')"></v-list-item>
                                      </v-list>
                                  </v-menu>
                              </div>
                          </div>
                      </template>

                      <template v-else>
                          <div class="cell center border-r text-caption opacity-50">{{ index + 1 + (pagination.page - 1) * pagination.perPage }}</div>
                          <div class="cell center border-r pa-1">
                              <div class="hint-tooltip" data-title="Clique para ver a estampa em Alta Qualidade">
                                  <div class="icon-3d-wrapper cursor-pointer" @click="openImage(item)">
                                      <v-icon size="20" class="icon-3d" :color="themeStore.currentMode === 'light' ? 'indigo-darken-3' : 'indigo-lighten-3'">mdi-tshirt-crew</v-icon>
                                      <div class="icon-3d-shine"></div>
                                  </div>
                              </div>
                          </div>
                          <div class="cell border-r">
                              <span class="list-text font-weight-black text-uppercase">{{ item.stamp_ref }}</span>
                          </div>
                          <div class="cell border-r">
                              <div class="d-flex flex-column">
                                  <span class="list-text font-weight-bold text-truncate" :title="item.order?.customer_name">{{ item.order?.customer_name }}</span>
                                  <div v-if="activeTab === 'design'" class="d-flex align-center mt-1">
                                      <v-chip size="x-small" :color="getDesignTagColor(item.design_tag)" variant="flat" class="font-weight-bold mr-2 chip-3d">{{ item.design_tag || 'N/A' }}</v-chip>
                                      <span class="text-caption opacity-70">OP #{{ item.order?.order_number }}</span>
                                  </div>
                                  <span v-else class="text-caption opacity-70">OP #{{ item.order?.order_number }}</span>
                              </div>
                          </div>
                          <div class="cell center border-r"><span class="list-text font-mono">{{ formatDate(item.created_at) }}</span></div>
                          <div class="cell center border-r"><span class="list-text font-mono font-weight-black">{{ item.quantity_meters }}m</span></div>
                          <div class="cell center border-r">
                              <v-chip size="x-small" :color="getStatusConfig(item.status).color" label class="font-weight-bold text-uppercase w-100 justify-center chip-3d" style="min-width: 90px;">
                                  {{ getStatusConfig(item.status).label }}
                              </v-chip>
                          </div>
                          <div class="cell center">
                               <div class="actions-inline">
                                   <div class="hint-tooltip" data-title="Histórico">
                                       <v-btn class="square-btn btn-3d" variant="flat" color="blue-grey" icon @click.stop="openLogs(item)">
                                           <v-icon size="16">mdi-history</v-icon>
                                       </v-btn>
                                   </div>

                                   <div class="hint-tooltip" :data-title="getNextActionTitle(item.status)">
                                       <v-btn class="square-btn btn-3d" variant="flat" :color="getNextActionColor(item.status)" icon @click.stop="advanceStatus(item)">
                                           <v-icon size="16">{{ getNextActionIcon(item.status) }}</v-icon>
                                       </v-btn>
                                   </div>

                                   <div class="hint-tooltip" data-title="Reportar Erro" v-if="activeTab === 'calandra'">
                                        <v-btn class="square-btn btn-3d" variant="flat" color="red-darken-3" @click.stop="openReprintError(item)">
                                            <v-icon size="16">mdi-printer-off</v-icon>
                                        </v-btn>
                                    </div>

                                   <v-menu location="bottom end">
                                       <template v-slot:activator="{ props }">
                                           <v-btn v-bind="props" class="square-btn btn-3d" variant="flat" color="grey-darken-3" @click.stop>
                                               <v-icon size="16">mdi-chevron-down</v-icon>
                                           </v-btn>
                                       </template>
                                       <v-list density="compact" nav class="border-thin">
                                           <v-list-item title="Editar Item" prepend-icon="mdi-pencil" @click="openEditModal(item)"></v-list-item>
                                           <v-list-item title="Ficha Técnica" prepend-icon="mdi-file-document-outline" @click="openLaunchDetail(item)"></v-list-item>
                                           <v-list-item v-if="['design_released', 'waiting_separation', 'in_separation'].includes(item.status)" title="Devolver ao Design" prepend-icon="mdi-keyboard-return" class="text-orange-darken-3" @click="openReturnToDesign(item)"></v-list-item>
                                           <v-divider class="my-1"></v-divider>
                                           <v-list-item v-if="userStore.isSuperAdmin" title="Forçar Status" prepend-icon="mdi-alert-circle-outline" class="text-red">
                                               <v-menu activator="parent" location="start" open-on-hover>
                                                   <v-list density="compact" nav>
                                                       <v-list-item v-for="opt in statusOptions" :key="opt.value" :title="opt.label" @click="quickSetItemStatus(item, opt.value, 'item')"></v-list-item>
                                                   </v-list>
                                               </v-menu>
                                           </v-list-item>
                                       </v-list>
                                   </v-menu>
                               </div>
                          </div>
                      </template>
                  </div>
                </template>
            </template>
          </div>

          <div class="flex-shrink-0 border-t px-4 py-2 d-flex align-center justify-space-between gap-2" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5' : 'bg-white-05'">
            <div class="text-caption opacity-80 font-weight-bold text-uppercase">
              Total: <strong>{{ filteredList.length }}</strong> registros
            </div>
            <v-pagination
              v-if="viewMode === 'list'"
              v-model="pagination.page"
              :length="Math.max(1, Math.ceil(filteredList.length / pagination.perPage))"
              density="compact"
              active-color="indigo-darken-3"
              total-visible="6"
              variant="tonal"
              size="small"
            ></v-pagination>
          </div>
        </v-card>

        <div
          v-if="store.loading"
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

          <div class="loading-text text-caption font-weight-black text-uppercase tracking-widest text-indigo-darken-2 position-relative z-10">
            CARREGANDO DADOS...
          </div>
        </div>

        <v-slide-y-transition>
          <div v-if="hasSelection" class="floating-actions-wrap">
            <v-card class="floating-actions-card" :class="themeStore.currentMode === 'light' ? 'floating-light' : 'floating-dark'" elevation="8">
              <div class="d-flex align-center justify-space-between px-4 py-3 gap-3">
                <div class="d-flex align-center gap-2">
                  <v-icon :color="themeStore.currentMode === 'light' ? 'indigo' : 'white'">mdi-checkbox-marked-circle</v-icon>
                  <div class="d-flex flex-column">
                    <div class="text-caption font-weight-black text-uppercase">
                      {{ selectedCount }} selecionado(s)
                    </div>
                    <div class="text-[11px] opacity-75">
                      {{ floatingContextLabel }}
                    </div>
                  </div>
                </div>

                <div class="d-flex align-center gap-2">
                  <template v-if="isOperationalTab">
                    <div class="hint-tooltip" data-title="Avançar (próxima etapa lógica)">
                      <v-btn size="small" variant="flat" class="btn-3d floating-btn" color="green-darken-2" @click="batchAdvanceSelected" @mouseenter="setItemHighlight(selectedRows[0])" @mouseleave="clearHighlight">
                        <v-icon start size="16">mdi-fast-forward</v-icon> Avançar
                      </v-btn>
                    </div>
                      <v-menu v-if="userStore.isSuperAdmin" location="top">
                        <template v-slot:activator="{ props }">
                          <v-btn v-bind="props" size="small" variant="flat" class="btn-3d floating-btn" color="deep-purple-darken-1">
                            <v-icon start size="16">mdi-swap-horizontal-bold</v-icon> Mover Etapa <v-icon end size="16">mdi-chevron-up</v-icon>
                          </v-btn>
                        </template>
                        <v-list density="compact" nav style="max-height: 360px; overflow:auto;">
                          <v-list-item v-for="opt in statusOptions" :key="opt.value" :title="opt.label" prepend-icon="mdi-flag-variant" @click="batchSetStatusSelected(opt.value)"></v-list-item>
                        </v-list>
                      </v-menu>
                  </template>

                  <template v-else-if="isBillingTab">
                    <div class="hint-tooltip" data-title="Marcar selecionados como visíveis no financeiro">
                      <v-btn size="small" variant="flat" class="btn-3d floating-btn" color="indigo" @click="batchBillingSetVisibility(true)">
                        <v-icon start size="16">mdi-eye</v-icon> Visíveis
                      </v-btn>
                    </div>
                    <div class="hint-tooltip" data-title="Marcar selecionados como NÃO visíveis no financeiro">
                      <v-btn
                        size="small"
                        variant="outlined"
                        class="btn-3d floating-btn"
                        :color="themeStore.currentMode === 'light' ? 'grey-darken-2' : 'white'"
                        @click="batchBillingSetVisibility(false)"
                      >
                        <v-icon start size="16">mdi-eye-off</v-icon> Ocultar
                      </v-btn>
                    </div>

                    <div class="hint-tooltip" data-title="Alternar alerta nos selecionados">
                      <v-btn
                        size="small"
                        variant="flat"
                        class="btn-3d floating-btn"
                        color="red-darken-1"
                        @click="batchBillingToggleAlert"
                      >
                        <v-icon start size="16">mdi-bell</v-icon> Alertas
                      </v-btn>
                    </div>

                    <div class="hint-tooltip" data-title="Agendar pedidos selecionados para Expedição (Calendário)">
                      <v-btn
                        size="small"
                        variant="flat"
                        class="btn-3d floating-btn"
                        color="green-darken-2"
                        @click="openScheduleModalBatch(selectedRows)"
                      >
                        <v-icon start size="16">mdi-calendar-check</v-icon> Agendar Expedição
                      </v-btn>
                    </div>
                  </template>

                  <template v-else-if="activeTab === 'liberacao'">
                    <div class="hint-tooltip" data-title="Marcar pedidos selecionados como ENTREGUE">
                      <v-btn
                        size="small"
                        variant="flat"
                        class="btn-3d floating-btn"
                        color="success"
                        @click="batchMarkDelivered"
                      >
                        <v-icon start size="16">mdi-truck-check</v-icon> Entregue
                      </v-btn>
                    </div>
                  </template>

                  <v-divider vertical class="mx-1 opacity-30"></v-divider>

                  <div class="hint-tooltip" data-title="Limpar seleção">
                    <v-btn size="small" variant="text" class="btn-3d" @click="clearSelection">
                      <v-icon>mdi-close</v-icon>
                    </v-btn>
                  </div>
                </div>
              </div>
            </v-card>
          </div>
        </v-slide-y-transition>
      </div>
    </div>

    <ImageModal :show="imageModal.show" :image-url="imageModal.url" :file-name="imageModal.name" @close="imageModal.show = false" />

<v-dialog v-model="calandraModal.show" max-width="450" persistent>
      <v-card class="rounded-lg shadow-lg" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'glass-card border-white-05'">
        <div class="px-4 py-3 border-b d-flex align-center justify-space-between bg-orange-darken-3 text-white">
          <div class="d-flex align-center gap-2">
            <v-icon color="white">mdi-fire</v-icon>
            <span class="font-weight-black text-uppercase text-subtitle-1">Enviar para Calandra</span>
          </div>
          <v-btn icon="mdi-close" variant="text" size="small" class="btn-3d" color="white" @click="calandraModal.show = false"></v-btn>
        </div>

        <div class="pa-5">
          <v-select
            v-model="calandraModal.machine"
            :items="store.availableCalandras"
            label="Selecione a Calandra"
            variant="outlined"
            density="compact"
            class="mb-3 ui-field"
            hide-details
          ></v-select>
          <v-select
            v-model="calandraModal.operator"
            :items="store.availableOperators"
            label="Selecione o Operador"
            variant="outlined"
            density="compact"
            class="ui-field"
            hide-details
          ></v-select>
        </div>

        <div class="px-4 py-3 border-t d-flex justify-end gap-2" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5' : 'bg-white-05'">
          <v-btn variant="outlined" class="btn-3d font-weight-bold" @click="calandraModal.show = false" :color="themeStore.currentMode === 'light' ? 'grey-darken-3' : 'white'">Cancelar</v-btn>
          <v-btn color="orange-darken-3" variant="flat" class="btn-3d font-weight-bold" @click="confirmCalandra">Confirmar</v-btn>
        </div>
      </v-card>
    </v-dialog>

    <v-dialog v-model="reprintErrorModal.show" max-width="500" persistent>
      <v-card class="rounded-xl overflow-hidden shadow-lg" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'glass-card border-white-05'" style="border: 1px solid rgba(198, 40, 40, 0.4);">
        <div class="bg-red-darken-3 px-5 py-4 text-white d-flex align-center justify-space-between">
          <span class="font-weight-black text-uppercase">
            <v-icon start>mdi-alert-octagon</v-icon>
            Reportar Erro de Impressão
          </span>
          <v-btn icon="mdi-close" variant="text" density="compact" class="btn-3d" color="white" @click="reprintErrorModal.show = false"></v-btn>
        </div>

        <div class="pa-5">
          <div v-if="reprintErrorModal.loading && !reprintErrorModal.printData && !reprintErrorModal.notes" class="text-center py-4">
             <v-progress-circular indeterminate color="red"></v-progress-circular>
          </div>

          <template v-else>
            <v-alert
              v-if="reprintErrorModal.printData"
              color="grey-darken-3"
              icon="mdi-history"
              variant="tonal"
              class="mb-4 py-2 border text-caption"
            >
              <div class="font-weight-black mb-1">Última Impressão Registrada:</div>
              <div><strong>Operador:</strong> {{ reprintErrorModal.printData.user?.full_name || 'Desconhecido' }}</div>
              <div><strong>Máquina:</strong> {{ reprintErrorModal.printData.metadata?.machine || 'Não Informada' }}</div>
              <div><strong>Data:</strong> {{ formatDateFull(reprintErrorModal.printData.created_at) }}</div>
            </v-alert>
            <v-alert v-else color="amber" variant="tonal" class="mb-4 text-caption py-2" icon="mdi-help-circle-outline">
              Não foi possível localizar o operador que imprimiu esta peça.
            </v-alert>

            <v-textarea
              v-model="reprintErrorModal.notes"
              label="Motivo / Defeito (Obrigatório)"
              variant="outlined"
              density="comfortable"
              rows="3"
              placeholder="Ex: Falha na cabeça de impressão, mancha no canto esquerdo..."
              class="mb-3 ui-field"
              hide-details
            ></v-textarea>

            <div class="d-flex flex-column gap-2 mb-2 mt-3">
              <span class="text-caption font-weight-bold opacity-80">Foto da Falha (Opcional, mas recomendado)</span>

              <div class="d-flex align-start gap-3">
                <div
                  class="flex-grow-1 border rounded-lg d-flex align-center justify-center position-relative cursor-pointer overflow-hidden"
                  style="height: 100px; border-style: dashed !important;"
                  :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-4' : 'bg-white-05'"
                  @click="$refs.errorFileInput.click()"
                >
                  <img v-if="reprintErrorModal.previewUrl" :src="reprintErrorModal.previewUrl" style="width: 100%; height: 100%; object-fit: cover;" />
                  <div v-else class="text-center opacity-60">
                    <v-icon size="24">mdi-camera-plus</v-icon>
                    <div class="text-[11px] mt-1">Anexar Imagem</div>
                  </div>
                </div>

                <v-btn
                  v-if="reprintErrorModal.previewUrl"
                  icon="mdi-trash-can"
                  color="red"
                  variant="tonal"
                  size="small"
                  class="btn-3d"
                  @click="reprintErrorModal.file = null; reprintErrorModal.previewUrl = null; $refs.errorFileInput.value = ''"
                ></v-btn>
              </div>
              <input
                type="file"
                ref="errorFileInput"
                accept="image/*"
                style="display: none"
                @change="handleFileChange"
              />
            </div>

            <p class="text-[11px] text-red mt-3 text-center font-weight-bold">
              Ao confirmar, este item voltará automaticamente para a "Fila de Impressão".
            </p>
          </template>
        </div>

        <div class="pa-4 border-t d-flex justify-end gap-2" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5' : 'bg-white-05'">
          <v-btn variant="outlined" class="btn-3d" @click="reprintErrorModal.show = false" :disabled="reprintErrorModal.loading" :color="themeStore.currentMode === 'light' ? 'grey-darken-3' : 'white'">Cancelar</v-btn>
          <v-btn color="red-darken-3" variant="flat" class="btn-3d" @click="confirmReprintError" :loading="reprintErrorModal.loading">
            Confirmar Rejeição
          </v-btn>
        </div>
      </v-card>
    </v-dialog>


    <v-dialog v-model="returnDesignModal.show" max-width="500" persistent>
      <v-card class="rounded-xl overflow-hidden shadow-lg" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'glass-card border-white-05'" style="border: 1px solid rgba(230, 81, 0, 0.4);">
        <div class="bg-orange-darken-3 px-5 py-4 text-white d-flex align-center justify-space-between">
          <span class="font-weight-black text-uppercase">
            <v-icon start>mdi-keyboard-return</v-icon>
            Devolver ao Design
          </span>
          <v-btn icon="mdi-close" variant="text" density="compact" class="btn-3d" color="white" @click="returnDesignModal.show = false"></v-btn>
        </div>

        <div class="pa-5">
          <v-alert color="amber" variant="tonal" class="mb-4 text-caption py-2" icon="mdi-alert">
            O item será retirado do fluxo de produção e devolvido para a fila de Design.
          </v-alert>

          <v-textarea
            v-model="returnDesignModal.reason"
            label="Motivo da Devolução (Obrigatório)"
            variant="outlined"
            density="comfortable"
            rows="3"
            placeholder="Ex: Cor da estampa incorreta, falta da logomarca..."
            class="mb-3 ui-field"
            hide-details
          ></v-textarea>
        </div>

        <div class="pa-4 border-t d-flex justify-end gap-2" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5' : 'bg-white-05'">
          <v-btn variant="outlined" class="btn-3d" @click="returnDesignModal.show = false" :disabled="returnDesignModal.loading" :color="themeStore.currentMode === 'light' ? 'grey-darken-3' : 'white'">Cancelar</v-btn>
          <v-btn color="orange-darken-3" variant="flat" class="btn-3d" @click="confirmReturnToDesign" :loading="returnDesignModal.loading">
            Confirmar Devolução
          </v-btn>
        </div>
      </v-card>
    </v-dialog>

    <v-dialog v-model="logModal.show" max-width="860" scrollable>
      <v-card class="rounded-lg shadow-lg" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'glass-card border-white-05'">

        <div
          class="px-5 py-3 font-weight-black d-flex align-center justify-space-between border-b"
          :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-3' : 'bg-white-05'"
        >
          <div class="d-flex flex-column">
            <div class="d-flex align-center gap-2">
              <v-icon color="blue-grey">mdi-history</v-icon>
              <span class="text-uppercase text-subtitle-1 font-weight-black">Histórico de Eventos</span>
            </div>
            <div class="text-caption opacity-70">
              Linha do tempo detalhada (do mais recente para o mais antigo)
            </div>
          </div>

          <div class="d-flex align-center gap-3">
            <v-chip size="small" variant="tonal" class="font-weight-bold chip-3d" color="indigo">
              {{ (store.currentLogs || []).length }} evento(s)
            </v-chip>
            <v-btn icon="mdi-close" variant="text" density="compact" class="btn-3d" @click="logModal.show = false"></v-btn>
          </div>
        </div>

        <v-card-text class="pa-0 custom-scroll" style="max-height: 60vh;">
          <div class="pa-4" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5' : ''">

            <div v-if="!(store.currentLogs || []).length" class="text-center opacity-60 py-10 d-flex flex-column align-center">
              <v-icon size="48" class="mb-3">mdi-timeline-clock-outline</v-icon>
              <div class="font-weight-bold text-h6">Sem histórico</div>
              <div class="text-caption">Ainda não há eventos registrados para este item.</div>
            </div>

            <div v-else class="log-timeline">
              <div
                v-for="(log, idx) in (store.currentLogs || [])"
                :key="log.id || idx"
                class="log-row rounded-lg"
                :class="themeStore.currentMode === 'light' ? 'log-row-light shadow-sm' : 'log-row-dark'"
              >
                <div class="log-mark pt-1">
                  <div class="log-dot" :class="logDotClass(log)"></div>
                  <div v-if="idx < (store.currentLogs || []).length - 1" class="log-line"></div>
                </div>

                <div class="log-content py-1">
                  <div class="d-flex align-start justify-space-between flex-wrap gap-2">
                    <div class="d-flex align-center gap-2 flex-wrap">

                      <v-chip size="small" label class="font-weight-black chip-3d" :color="logChipColor(log)">
                        <v-icon start size="14">{{ logIcon(log) }}</v-icon>
                        {{ logMainLabel(log) }}
                      </v-chip>

                      <v-chip v-if="logStageChip(log)" size="small" label variant="outlined" class="font-weight-bold bg-white-05" :color="logStageChip(log)!.color">
                        {{ logStageChip(log)!.text }}
                      </v-chip>

                      <v-chip size="small" label variant="tonal" class="font-weight-bold chip-3d bg-white-05" :color="themeStore.currentMode === 'light' ? 'grey-darken-3' : 'white'">
                        <v-icon start size="14">mdi-account</v-icon>
                        {{ log.user?.full_name || 'Sistema Automático' }}
                      </v-chip>
                    </div>

                    <div class="text-caption font-mono font-weight-bold opacity-75 d-flex align-center mt-1 mt-sm-0">
                      <v-icon size="14" class="mr-1">mdi-clock-outline</v-icon>
                      {{ formatDateFull(log.created_at) }}
                    </div>
                  </div>

                  <div class="log-desc mt-3 pa-3 rounded text-caption border-thin" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-black opacity-80'">
                    <span class="font-weight-bold opacity-90">{{ logDescription(log) }}</span>
                  </div>

                  <div v-if="log.metadata?.photo_url" class="mt-3">
                    <v-btn size="small" color="red-darken-2" variant="tonal" prepend-icon="mdi-image" class="btn-3d" @click="openImage({ stamp_image_url: log.metadata.photo_url, stamp_ref: 'Foto da Falha (Calandra)' })">
                      Ver Foto do Defeito
                    </v-btn>
                  </div>

                  <div class="mt-2 text-[10px] opacity-40 font-mono text-uppercase">
                    TIPO: {{ String(log.action || 'DESCONHECIDO').replace(/_/g, ' ') }}
                  </div>
                </div>
              </div>
            </div>
          </div>
        </v-card-text>
      </v-card>
    </v-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, reactive, watch, shallowRef, nextTick } from 'vue';
import { format, addDays, startOfWeek, endOfWeek, isBefore, isSameDay, parseISO, formatDistanceToNow, startOfDay, startOfMonth, endOfMonth, startOfYear, isAfter, eachDayOfInterval, addMonths, subMonths } from 'date-fns';
import { ptBR } from 'date-fns/locale';
import { useProductionStore } from '@/stores/production';
import { useThemeStore } from '@/stores/theme';
import { useCompanyStore } from '@/stores/company';
import { supabase } from '@/api/supabase';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import { useAppStore } from '@/stores/app';
import { useUserStore } from '@/stores/user';
import ImageModal from '@/components/ImageModal.vue';
import LaunchDetailModal from '@/components/LaunchDetailModal.vue';

const store = useProductionStore();
const themeStore = useThemeStore();
const companyStore = useCompanyStore();
const appStore = useAppStore();
const userStore = useUserStore();

// -------------------------------------------------------------
// ESTADO DA LOADING BAR E REF DE SCROLL DA LISTA
// -------------------------------------------------------------
const scrollContainerList = ref<HTMLElement | null>(null);
const scrollContainerKanban = ref<HTMLElement | null>(null);
const displayedList = shallowRef<any[]>([]);
const displayedGrouped = shallowRef<any[]>([]);
const displayedKanban = shallowRef<any[]>([]);

const particleIcons = ['mdi-tshirt-crew', 'mdi-palette', 'mdi-scissors-cutting', 'mdi-texture', 'mdi-hanger'];
const particleColors = ['indigo-lighten-2', 'purple-lighten-2', 'cyan-lighten-2', 'teal-lighten-2', 'blue-lighten-2'];
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


// STATE
const activeTab = ref('pcp');
const viewMode = ref('list');
const filtersDropdownOpen = ref(false);
const filters = reactive({ search: '', status: [] as string[], dateStart: '', dateEnd: '' });
const pagination = reactive({ page: 1, perPage: 50 });
const flowMode = ref<'current' | 'legacy'>('current');
const sortOrder = ref<'newest' | 'oldest'>('newest');
const sortOptions = [
  { label: 'Mais novo → Mais velho', value: 'newest' },
  { label: 'Mais velho → Mais novo', value: 'oldest' },
];

// RELATÓRIOS (PDF)
const loadingPdf = ref(false);
const reportPeriod = ref('month');
const reportGrouping = ref('items');

// FILTERS CONFIG
const billingFilters = reactive({ onlyVisible: true, includeAlerts: true });
const releaseFilters = reactive({ showReady: true, showGhosts: true });
const faturamentoSubTab = ref<'a_faturar' | 'faturado'>('a_faturar');

// MODALS STATE
const editModal = reactive({ show: false, loading: false, item: null as any, form: { stamp_ref: '', fabric_type: '', quantity_meters: 0, notes: '' } });
const launchDetailModal = reactive({ show: false, orderId: '', itemId: '' });
const calandraModal = reactive({ show: false, item: null as any, machine: null, operator: '', isBatch: false, batchIds: [] as string[] });
const logModal = reactive({ show: false });
const imageModal = reactive({ show: false, url: '', name: '' });
const manualStatusModal = reactive({ show: false, item: null as any, newStatus: '', type: 'item' });
const alertModal = reactive({ show: false, order: null as any, message: '' });
const reprintErrorModal = reactive({
  show: false,
  loading: false,
  item: null as any,
  notes: '',
  file: null as File | null,
  previewUrl: null as string | null,
  printData: null as any
});

// NOVO MODAL DE AGENDAMENTO DE EXPEDIÇÃO (CALENDÁRIO)
const scheduleModal = reactive({
    show: false,
    loading: false,
    isBatch: false,
    order: null as any,
    batchOrders: [] as any[],
    selectedDate: new Date(),
    currentMonth: startOfMonth(new Date()),
    forecastDate: null as Date | null
});

const nextScheduleMonth = () => scheduleModal.currentMonth = addMonths(scheduleModal.currentMonth, 1);
const prevScheduleMonth = () => scheduleModal.currentMonth = subMonths(scheduleModal.currentMonth, 1);

const scheduleDays = computed(() => {
    if (!scheduleModal.show) return [];
    const monthStart = startOfMonth(scheduleModal.currentMonth);
    const monthEnd = endOfMonth(scheduleModal.currentMonth);
    const startDate = startOfWeek(monthStart, { weekStartsOn: 0 });
    const endDate = endOfWeek(monthEnd, { weekStartsOn: 0 });

    return eachDayOfInterval({ start: startDate, end: endDate }).map(date => ({
        date,
        dateStr: format(date, 'yyyy-MM-dd'),
        isCurrentMonth: isSameDay(date, monthStart) || (date > monthStart && date < monthEnd) || isSameDay(date, monthEnd)
    }));
});

const returnDesignModal = reactive({
  show: false,
  loading: false,
  item: null as any,
  reason: ''
});

const openReturnToDesign = (item: any) => {
  returnDesignModal.item = item;
  returnDesignModal.reason = '';
  returnDesignModal.show = true;
};

const confirmReturnToDesign = async () => {
  if (companyStore.isDemoMode) return appStore.showSnackbar('Ação não permitida em modo demonstração', 'warning');
  if (!returnDesignModal.item) return;
  returnDesignModal.loading = true;

  try {
    const item = returnDesignModal.item;

    const { error } = await supabase.from('order_items').update({
      status: 'design_pending',
      design_tag: 'Alteração'
    }).eq('id', item.id);

    if (error) throw error;

    await supabase.from('production_logs').insert({
      order_item_id: item.id,
      user_id: userStore.user?.id,
      action: 'returned_to_design',
      metadata: { reason: returnDesignModal.reason || 'Devolvido do PCP sem motivo especificado' }
    });

    appStore.showSnackbar('Item devolvido ao Design com sucesso.', 'success');
    item.status = 'design_pending';
    item.design_tag = 'Alteração';
    returnDesignModal.show = false;
  } catch (e: any) {
    appStore.showSnackbar('Erro ao devolver item: ' + e.message, 'error');
  } finally {
    returnDesignModal.loading = false;
  }
};

const openScheduleModal = (order: any) => {
    const isFaturado = String(order.financial_status || '').toLowerCase() === 'faturado';
    if (!isFaturado) {
        if(!confirm('Atenção: Este pedido AINDA NÃO ESTÁ FATURADO. Tem certeza que deseja agendar para expedição mesmo assim?')) return;
    }

    scheduleModal.isBatch = false;
    scheduleModal.order = order;

    let forecastObj = null;
    const savedDate = order.actual_delivery_date
                   || order.order?.actual_delivery_date
                   || order.forecast_delivery_date
                   || order.order?.forecast_delivery_date
                   || order.details?.forecast_delivery_date;

    if (savedDate) {
        forecastObj = parseISO(savedDate);
    } else {
        const baseDateStr = order.created_at || order.order?.created_at;
        if (baseDateStr) {
            const baseDate = new Date(parseISO(baseDateStr));
            baseDate.setDate(baseDate.getDate() + 4);
            forecastObj = baseDate;
        }
    }

    scheduleModal.forecastDate = forecastObj;
    scheduleModal.selectedDate = scheduleModal.forecastDate || new Date();
    scheduleModal.currentMonth = startOfMonth(scheduleModal.selectedDate);
    scheduleModal.show = true;
};

const openScheduleModalBatch = (orders: any[]) => {
    const unbilled = orders.filter(o => String(o.financial_status || '').toLowerCase() !== 'faturado');
    if (unbilled.length > 0) {
        if(!confirm(`Atenção: ${unbilled.length} pedido(s) selecionado(s) NÃO ESTÃO FATURADOS. Deseja agendar todos para a mesma data mesmo assim?`)) return;
    }

    scheduleModal.isBatch = true;
    scheduleModal.batchOrders = orders;
    scheduleModal.forecastDate = null;
    scheduleModal.selectedDate = new Date();
    scheduleModal.currentMonth = startOfMonth(scheduleModal.selectedDate);
    scheduleModal.show = true;
};

const confirmSchedule = async () => {
    if (companyStore.isDemoMode) return appStore.showSnackbar('Ação não permitida em modo demonstração', 'warning');
    scheduleModal.loading = true;
    try {
        const targetDate = format(scheduleModal.selectedDate, 'yyyy-MM-dd') + 'T12:00:00';

        if (scheduleModal.isBatch) {
             const orderIds = scheduleModal.batchOrders.map((o:any) => String(o.id));
             await supabase.from('orders').update({
                 status: 'completed',
                 actual_delivery_date: targetDate
             }).in('id', orderIds);

             await store.advanceToRelease(orderIds, null);
             scheduleModal.batchOrders.forEach(o => o.status = 'completed');
        } else {
             const orderId = String(scheduleModal.order.id);
             await supabase.from('orders').update({
                 status: 'completed',
                 actual_delivery_date: targetDate
             }).eq('id', orderId);

             await store.advanceToRelease([], orderId);
             scheduleModal.order.status = 'completed';
        }

        appStore.showSnackbar('Agendamento realizado com sucesso!', 'success');
        scheduleModal.show = false;
        clearSelection();
    } catch (e) {
        appStore.showSnackbar('Erro ao agendar pedido para expedição.', 'error');
    } finally {
        scheduleModal.loading = false;
    }
};

const handleFileChange = (e: any) => {
  const file = e.target.files[0];
  if (file) {
    reprintErrorModal.file = file;
    reprintErrorModal.previewUrl = URL.createObjectURL(file);
  }
};

const openReprintError = async (item: any) => {
  reprintErrorModal.item = item;
  reprintErrorModal.notes = '';
  reprintErrorModal.file = null;
  reprintErrorModal.previewUrl = null;
  reprintErrorModal.printData = null;

  reprintErrorModal.loading = true;
  reprintErrorModal.show = true;

  if (companyStore.isDemoMode) {
      reprintErrorModal.printData = { user: { full_name: 'Operador Fictício' }, metadata: { machine: 'Máquina Demo 1' }, created_at: new Date().toISOString() };
      reprintErrorModal.loading = false;
      return;
  }

  const printData = await store.fetchLastPrintData(item.id);
  reprintErrorModal.printData = printData;
  reprintErrorModal.loading = false;
};

const confirmReprintError = async () => {
  if (companyStore.isDemoMode) return appStore.showSnackbar('Ação não permitida em modo demonstração', 'warning');
  if (!reprintErrorModal.notes.trim()) {
    appStore.showSnackbar('Informe o motivo do erro.', 'warning');
    return;
  }

  reprintErrorModal.loading = true;
  try {
    await store.reportReprintError(
      reprintErrorModal.item.id,
      reprintErrorModal.notes,
      reprintErrorModal.file,
      reprintErrorModal.printData
    );
    reprintErrorModal.item.status = 'waiting_print';
    appStore.showSnackbar('Item devolvido para a Impressão.', 'success');
    reprintErrorModal.show = false;
  } catch (e: any) {
    appStore.showSnackbar('Erro: ' + (e.message || 'Falha ao registrar problema.'), 'error');
  } finally {
    reprintErrorModal.loading = false;
  }
};

const selectedIds = ref(new Set<string>());
const isSelected = (id: any) => selectedIds.value.has(String(id));
const toggleSelect = (id: any, val: boolean) => { if(val) selectedIds.value.add(String(id)); else selectedIds.value.delete(String(id)); };
const toggleSelectAllPage = (val: boolean) => { paginatedList.value.forEach(i => toggleSelect(i.id || rowKey(i), val)); };
const isAllPageSelected = computed(() => paginatedList.value.length > 0 && paginatedList.value.every(i => selectedIds.value.has(String(i.id || rowKey(i)))));
const hasSelection = computed(() => selectedIds.value.size > 0);

const toggleSelectGroup = (group: any, val: boolean) => { group.items.forEach((i: any) => toggleSelect(i.id || rowKey(i), val)); };
const isGroupSelected = (group: any) => group.items.every((i: any) => isSelected(i.id || rowKey(i)));
const isGroupIndeterminate = (group: any) => { const count = group.items.filter((i: any) => isSelected(i.id || rowKey(i))).length; return count > 0 && count < group.items.length; };

const canAccessTab = (tabId: string) => {
  if (companyStore.isDemoMode) return true;
  if (userStore.isSuperAdmin) return true;

  const tabPermissions: Record<string, string> = {
    'design': 'pcp_tab_design',
    'pcp': 'pcp_tab_pcp',
    'separacao': 'pcp_tab_separacao',
    'impressao': 'pcp_tab_impressao',
    'calandra': 'pcp_tab_calandra',
    'faturamento': 'pcp_tab_faturamento',
    'liberacao': 'pcp_tab_liberacao',
  };

  const requiredPermission = tabPermissions[tabId];
  return requiredPermission ? userStore.hasPermission(requiredPermission) : true;
};

const PCP_STATUSES = ['design_released', 'waiting_separation', 'in_separation', 'waiting_print', 'printing', 'printed', 'waiting_calandra', 'in_calandra', 'in_production', 'billing_pending', 'waiting_release'];

const kpiTabs = computed(() => {
  const m = store.managementList || [];
  const countDesign = m.filter(i => ['design_pending', 'customer_approval', 'approved_by_seller', 'approved_by_designer'].includes(i.status)).length;

  const countPCP = m.filter(i => PCP_STATUSES.includes(i.status)).length;

  const countSep = m.filter(i => ['waiting_separation', 'in_separation'].includes(i.status)).length;
  const countImp = m.filter(i => ['waiting_print', 'printing'].includes(i.status)).length;
  const countCal = m.filter(i => ['printed', 'waiting_calandra', 'in_calandra', 'in_production'].includes(i.status)).length;

  const bills = store.billingList || [];
  const isFaturado = (s: any) => String(s || '').trim().toLowerCase() === 'faturado';
  const countAbertoParcial = bills.filter(o => !isFaturado(o.financial_status)).length;

  const expeditionLen = (store.expeditionList || []).length;
  const ghostLen = (store.ghostOrders || []).length;

  return [
    { id: 'design', label: 'DESIGN (FINALIZAÇÃO)', icon: 'mdi-pencil-ruler', gradient: 'bg-gradient-blue', count: countDesign },
    { id: 'pcp', label: 'PCP GERAL', icon: 'mdi-chart-timeline-variant', gradient: 'bg-gradient-purple', count: countPCP },
    { id: 'separacao', label: 'SEPARAÇÃO', icon: 'mdi-basket-outline', gradient: 'bg-gradient-cyan', count: countSep },
    { id: 'impressao', label: 'IMPRESSÃO', icon: 'mdi-printer-3d-nozzle', gradient: 'bg-gradient-warning', count: countImp },
    { id: 'calandra', label: 'CALANDRA', icon: 'mdi-fire', gradient: 'bg-gradient-orange', count: countCal },
    { id: 'faturamento', label: 'FATURAMENTO', icon: 'mdi-cash-clock', gradient: 'bg-gradient-dark', count: countAbertoParcial },
    { id: 'liberacao', label: 'EXPEDIÇÃO', icon: 'mdi-check-decagram', gradient: 'bg-gradient-green', count: expeditionLen + ghostLen }
  ].filter(kpi => canAccessTab(kpi.id));
});

const isBillingTab = computed(() => activeTab.value === 'faturamento');
const isSpecialTab = computed(() => isBillingTab.value);
const isOperationalTab = computed(() => !isSpecialTab.value && activeTab.value !== 'liberacao');

const currentTabStatuses = computed(() => {
  switch (activeTab.value) {
    case 'separacao': return [{value:'waiting_separation',label:'Fila'}, {value:'in_separation',label:'Separando'}];
    case 'impressao': return [{value:'waiting_print',label:'Fila'}, {value:'printing',label:'Imprimindo'}];
    case 'calandra': return [{value:'printed',label:'Fila'}, {value:'waiting_calandra',label:'Aguardando'}, {value:'in_production',label:'Em Processo'}];
    case 'faturamento':
      if (faturamentoSubTab.value === 'a_faturar') {
        return [{value:'Em Aberto',label:'Em Aberto'}, {value:'Parcialmente Faturado',label:'Parcial'}];
      } else {
        return [{value:'Faturado',label:'Faturado'}];
      }
    case 'liberacao': return [{value:'waiting_release',label:'Aguardando'}, {value:'ready_for_delivery',label:'Pronto'}, {value:'completed',label:'Concluído'}];
    case 'legado': return [{value:'production_queue',label:'Fila'}, {value:'in_printing',label:'Impressão'}, {value:'in_cutting',label:'Corte'}];
    default: return [];
  }
});

const prettifyCode = (code: string) => String(code || '').trim().replaceAll('_', ' ').replace(/\s+/g, ' ').toUpperCase();

const actionMap: Record<string, { label: string; color: string; icon: string }> = {
  sent_to_pcp: { label: 'Enviado ao PCP', color: 'deep-purple-darken-2', icon: 'mdi-chart-timeline-variant' },
  sent_to_calandra: { label: 'Enviado à Calandra', color: 'orange-darken-2', icon: 'mdi-fire' },
  sent_to_printing: { label: 'Enviado à Impressão', color: 'indigo-darken-2', icon: 'mdi-printer-3d-nozzle' },
  sent_to_separation: { label: 'Enviado à Separação', color: 'cyan-darken-2', icon: 'mdi-basket-outline' },
  sent_to_billing: { label: 'Enviado ao Faturamento', color: 'blue-grey-darken-2', icon: 'mdi-cash-clock' },
  sent_to_release: { label: 'Enviado à Expedição', color: 'teal-darken-2', icon: 'mdi-truck-fast-outline' },
  batch_advance: { label: 'Avanço em lote', color: 'deep-purple-darken-1', icon: 'mdi-fast-forward' },
  batch_force: { label: 'Movido em lote', color: 'indigo-darken-2', icon: 'mdi-swap-horizontal-bold' },
  order_delivered: { label: 'Pedido entregue', color: 'green-darken-2', icon: 'mdi-truck-check' },
  billing_visible_on: { label: 'Marcado como visível (Financeiro)', color: 'indigo-darken-2', icon: 'mdi-eye' },
  billing_visible_off: { label: 'Ocultado do financeiro', color: 'grey-darken-2', icon: 'mdi-eye-off' },
  billing_alert_on: { label: 'Alerta ativado (Financeiro)', color: 'red-darken-2', icon: 'mdi-bell-ring' },
  billing_alert_off: { label: 'Alerta removido (Financeiro)', color: 'grey-darken-1', icon: 'mdi-bell-off' },
  reprint_error_reported: { label: 'Erro Reportado (Voltou p/ Impressão)', color: 'red-darken-3', icon: 'mdi-alert-octagon' },
  returned_to_design: { label: 'Devolvido ao Design', color: 'orange-darken-3', icon: 'mdi-keyboard-return' },
};

const parseLogAction = (raw: any) => {
  const action = String(raw?.action || '').trim();
  const adv = action.match(/^advanced_to_(.+)$/);
  if (adv) return { kind: 'ADVANCED_TO', type: 'ADVANCE', raw: action, to: adv[1], key: action };
  const forced = action.match(/^(forced_to_|force_to_|manual_to_)(.+)$/);
  if (forced) return { kind: 'FORCED_TO', type: 'FORCE', raw: action, to: forced[2], key: action };

  if (action === 'reprint_error_reported') return { kind: 'REPRINT_ERROR', type: 'REPRINT_ERROR', raw: action, key: action };

  let type = 'UNKNOWN';
  if (action === 'sent_to_calandra') type = 'CALANDRA';
  if (action === 'batch_advance') type = 'BATCH_ADVANCE';
  if (action === 'batch_force') type = 'BATCH_FORCE';
  if (action === 'order_delivered') type = 'DELIVERED';

  return { kind: 'RAW', type, raw: action, key: action };
};

const logActionChip = (log: any): { label: string; color: string; icon: string } => {
  const p = parseLogAction(log);
  if (p.kind === 'ADVANCED_TO') {
    const cfg = getStatusConfig(String(p.to));
    return { label: `Avançou → ${cfg.label || statusLabel(String(p.to))}`, color: 'green-darken-2', icon: 'mdi-arrow-right-bold' };
  }
  if (p.kind === 'FORCED_TO') {
    const cfg = getStatusConfig(String(p.to));
    return { label: `Forçado → ${cfg.label || statusLabel(String(p.to))}`, color: 'red-darken-2', icon: 'mdi-alert-octagon' };
  }
  const rawKey = String(p.raw || '').trim();
  if (actionMap[rawKey]) return actionMap[rawKey];
  return { label: `Ação: ${prettifyCode(rawKey || 'unknown')}`, color: 'grey-darken-2', icon: 'mdi-information-outline' };
};

const logStageChip = (log: any): null | { text: string; color: string } => {
  const p = parseLogAction(log);
  if (!('to' in p) || !p.to) return null;
  const cfg = getStatusConfig(String(p.to));
  return { text: `Etapa: ${cfg.label || statusLabel(String(p.to))}`, color: cfg.color || 'grey' };
};

const logMainLabel = (log: any) => {
  const p = parseLogAction(log);
  switch (p.type) {
    case 'ADVANCE': return 'Avançou etapa';
    case 'FORCE': return 'Status forçado';
    case 'CALANDRA': return 'Enviado para Calandra';
    case 'BATCH_ADVANCE': return 'Avanço em lote';
    case 'BATCH_FORCE': return 'Movido em lote';
    case 'DELIVERED': return 'Entrega confirmada';
    case 'CREATED': return 'Registro criado';
    case 'UPDATED': return 'Registro atualizado';
    case 'REMOVED': return 'Registro removido';
    case 'REPRINT_ERROR': return 'Erro na Calandra';
    default: return 'Evento registrado';
  }
};

const logDescription = (log: any) => {
  const p = parseLogAction(log);
  const action = String(log?.action || '').trim();
  switch (p.type) {
    case 'ADVANCE': return `O item foi avançado automaticamente para a próxima etapa do fluxo.`;
    case 'FORCE': return `Alguém forçou a etapa manualmente (isso ignora a sequência padrão).`;
    case 'CALANDRA': return `O item foi enviado para a Calandra (normalmente com máquina/operador definidos).`;
    case 'BATCH_ADVANCE': return `Vários itens foram avançados em lote de uma vez (ação de seleção múltipla).`;
    case 'BATCH_FORCE': return `Vários itens foram movidos em lote para uma etapa escolhida manualmente.`;
    case 'DELIVERED': return `O pedido foi marcado como ENTREGUE (confirmação final da expedição).`;
    case 'CREATED': return `O registro entrou no sistema (criação).`;
    case 'UPDATED': return `Algum dado do registro foi alterado (ex.: campos/observações/status).`;
    case 'REMOVED': return `O registro foi removido/invalidado.`;

  case 'RETURN_DESIGN': return `O item foi retirado do fluxo de produção e devolvido ao Design. Motivo: ${log.metadata?.reason || 'Não informado'}.`;
    case 'REPRINT_ERROR':
      const reason = log.metadata?.reason || 'Sem motivo detalhado';
      const op = log.metadata?.previous_print?.user?.full_name || 'Desconhecido';
      const mach = log.metadata?.previous_print?.metadata?.machine || 'Desconhecida';
      return `Item rejeitado na calandra e devolvido para impressão. Motivo: ${reason}. \n(Ref. Impressão: Operador ${op} na máquina ${mach})`;
    default:
        if (action === 'returned_to_design') return `O item foi retirado do fluxo de produção e devolvido ao Design. Motivo: ${log.metadata?.reason || 'Não informado'}.`;
        return `Ação interna registrada no sistema.`;
  }
};

const logChipColor = (log: any) => {
  const p = parseLogAction(log);
  switch (p.type) {
    case 'ADVANCE': return 'green-darken-2';
    case 'FORCE': return 'red-darken-2';
    case 'CALANDRA': return 'orange-darken-2';
    case 'BATCH_ADVANCE': return 'deep-purple-darken-1';
    case 'BATCH_FORCE': return 'indigo-darken-2';
    case 'DELIVERED': return 'teal-darken-2';
    case 'CREATED': return 'cyan-darken-2';
    case 'UPDATED': return 'blue-darken-2';
    case 'REMOVED': return 'grey-darken-2';
    case 'REPRINT_ERROR': return 'red-darken-3';
    default: return 'grey-darken-1';
  }
};

const logIcon = (log: any) => {
  const p = parseLogAction(log);
  switch (p.type) {
    case 'ADVANCE': return 'mdi-arrow-right-bold';
    case 'FORCE': return 'mdi-alert-octagon';
    case 'CALANDRA': return 'mdi-fire';
    case 'BATCH_ADVANCE': return 'mdi-fast-forward';
    case 'BATCH_FORCE': return 'mdi-swap-horizontal-bold';
    case 'DELIVERED': return 'mdi-truck-check';
    case 'CREATED': return 'mdi-plus-box';
    case 'UPDATED': return 'mdi-pencil';
    case 'REMOVED': return 'mdi-trash-can';
    case 'REPRINT_ERROR': return 'mdi-printer-off';
    default: return 'mdi-information-outline';
  }
};

const logDotClass = (log: any) => {
  const p = parseLogAction(log);
  if (p.type === 'FORCE') return 'log-dot-danger';
  if (p.type === 'ADVANCE') return 'log-dot-success';
  if (p.type === 'CALANDRA') return 'log-dot-warn';
  if (p.type === 'DELIVERED') return 'log-dot-teal';
  if (p.type === 'REPRINT_ERROR') return 'log-dot-danger';
  return 'log-dot-neutral';
};


const rawList = computed(() => {
  if (isBillingTab.value) return store.billingList || [];

  if (activeTab.value === 'liberacao') {
    const ghosts = flowMode.value === 'legacy' ? (store.ghostOrdersLegacy || []) : (store.ghostOrdersCurrent || []);
    const exp = flowMode.value === 'legacy' ? (store.expeditionLegacy || []) : (store.expeditionCurrent || []);
    return [...ghosts, ...exp];
  }

  if (activeTab.value === 'legado') {
    return flowMode.value === 'legacy' ? (store.managementLegacy || []) : (store.managementCurrent || []);
  }

  return store.managementList || [];
});

const filteredList = computed(() => {
    let list = rawList.value || [];

    list = list.filter((i: any) => i.status !== 'cancelled' && i?.order?.status !== 'cancelled');

    if(activeTab.value === 'pcp') {
        list = list.filter((i:any) => PCP_STATUSES.includes(i.status));
    }
    else if(activeTab.value === 'design') list = list.filter((i:any) => ['design_pending','customer_approval','approved_by_seller','approved_by_designer'].includes(i.status));
    else if(activeTab.value === 'legado') list = list.filter((i:any) => ['production_queue','in_printing','in_cutting'].includes(i.status));
    else if(activeTab.value === 'separacao') list = list.filter((i:any) => ['waiting_separation','in_separation'].includes(i.status));
    else if(activeTab.value === 'impressao') list = list.filter((i:any) => ['waiting_print','printing'].includes(i.status));
    else if(activeTab.value === 'calandra') list = list.filter((i:any) => ['printed','waiting_calandra','in_calandra','in_production'].includes(i.status));

    if(isBillingTab.value) {
        const isFaturado = (s:any) => String(s||'').toLowerCase() === 'faturado';

        if (faturamentoSubTab.value === 'faturado') {
            list = list.filter((o:any) => isFaturado(o.financial_status));
        } else {
            list = list.filter((o:any) => !isFaturado(o.financial_status));
            if(billingFilters.onlyVisible) {
                list = list.filter((o:any) => o.billing_queue_visible || (billingFilters.includeAlerts && o.billing_alert));
            }
        }
    }

    if(filters.search) {
        const s = filters.search.toLowerCase();
        list = list.filter((i:any) => String(i.order_number||i.order?.order_number||'').includes(s) || String(i.customer_name||i.order?.customer_name||'').toLowerCase().includes(s) || String(i.stamp_ref||'').toLowerCase().includes(s));
    }

    if (filters.status.length > 0) list = list.filter((i: any) => filters.status.includes(i.status || i.financial_status));

    if (filters.dateStart || filters.dateEnd) {
        const start = filters.dateStart ? new Date(filters.dateStart) : null;
        const end = filters.dateEnd ? new Date(filters.dateEnd) : null;
        if (end) end.setHours(23, 59, 59);

        list = list.filter((i: any) => {
            const dateStr = getBestRowDate(i);
            if (!dateStr) return false;
            const d = new Date(dateStr);
            if (start && d < start) return false;
            if (end && d > end) return false;
            return true;
        });
    }

    const dir = sortOrder.value === 'oldest' ? 1 : -1;
    list = [...list].sort((a: any, b: any) => {
      const da = getBestRowDate(a) || a.created_at || a.order?.created_at || '';
      const db = getBestRowDate(b) || b.created_at || b.order?.created_at || '';
      const ta = da ? new Date(da).getTime() : 0;
      const tb = db ? new Date(db).getTime() : 0;
      if (ta === tb) return 0;
      return ta < tb ? -1 * dir : 1 * dir;
    });

    return list;
});

const paginatedList = computed(() => {
    const start = (pagination.page - 1) * pagination.perPage;
    return filteredList.value.slice(start, start + pagination.perPage);
});

const gridClass = computed(() => {
    if (isBillingTab.value) return 'grid-billing';
    if (activeTab.value === 'liberacao') return 'grid-release';
    return 'grid-default';
});

const statusOptions = [
  { label: 'Retornar ao Design', value: 'design_pending' },
  { label: 'Aprovação Cliente', value: 'customer_approval' },
  { label: 'Liberado PCP', value: 'design_released' },
  { label: 'Fila Separação', value: 'waiting_separation' },
  { label: 'Em Separação', value: 'in_separation' },
  { label: 'Fila Impressão', value: 'waiting_print' },
  { label: 'Imprimindo', value: 'printing' },
  { label: 'Impresso', value: 'printed' },
  { label: 'Fila Calandra', value: 'waiting_calandra' },
  { label: 'Em Produção', value: 'in_production' },
  { label: 'Faturamento', value: 'billing_pending' },
  { label: 'Expedição', value: 'waiting_release' },
  { label: 'Concluído', value: 'completed' }
];

const getStatusConfig = (s: string) => {
    const map:any = {
        design_pending:{color:'grey',label:'Design'},
        customer_approval:{color:'amber',label:'Aprovação'},
        design_released:{color:'cyan',label:'Liberado'},
        waiting_separation:{color:'light-blue',label:'Separação'},
        in_separation:{color:'blue',label:'Separando'},
        waiting_print:{color:'indigo',label:'Fila Imp'},
        printing:{color:'blue',label:'Imprimindo'},
        printed:{color:'deep-purple',label:'Impresso'},
        waiting_calandra:{color:'orange',label:'Fila Cal'},
        in_production:{color:'deep-orange',label:'Em Prod'},
        billing_pending:{color:'blue-grey',label:'Fat'},
        waiting_release:{color:'teal',label:'Expedição'},
        completed:{color:'green',label:'Concluído'}
    };
    return map[s] || {color:'grey', label:s};
};

const getBillingStatusColor = (s:string) => {
    if(String(s).toLowerCase() === 'faturado') return 'success';
    if(String(s).toLowerCase().includes('parcial')) return 'warning';
    return 'grey';
};

const getDesignTagColor = (t:string) => {
    if(t==='Aprovado') return 'green';
    if(t==='Alteração') return 'orange';
    return 'info';
};

const getNextActionIcon = (s: string) => {
  if (s === 'design_released') return 'mdi-basket-outline';
  if (s === 'waiting_separation') return 'mdi-play';
  if (s === 'in_separation') return 'mdi-printer-3d-nozzle';
  if (s === 'printing') return 'mdi-stop';
  if (s === 'printed') return 'mdi-fire';
  if (s === 'in_production') return 'mdi-cash-clock';
  if (s === 'billing_pending') return 'mdi-clipboard-check';
  if (s === 'waiting_release') return 'mdi-truck-check';
  return 'mdi-arrow-right-thick';
};

const getNextActionColor = (s: string) => {
  if (s === 'design_released') return 'light-blue-darken-3';
  if (s === 'waiting_separation') return 'blue-darken-2';
  if (s === 'in_separation') return 'indigo';
  if (s === 'printing') return 'red';
  if (s === 'in_production') return 'orange-darken-3';
  if (s === 'billing_pending') return 'indigo';
  if (s === 'waiting_release') return 'green';
  return 'green-darken-3';
};

const getNextActionTitle = (s: string) => {
  if (s === 'design_released') return 'Enviar para Fila de Separação';
  if (s === 'waiting_separation') return 'Iniciar Separação';
  if (s === 'in_separation') return 'Concluir Separação (Enviar p/ Impressão)';
  if (s === 'printing') return 'Concluir Impressão';
  if (s === 'printed') return 'Enviar para Calandra';
  if (s === 'in_production') return 'Enviar para Faturamento';
  return 'Avançar Etapa';
};

const getNextLogicalStatus = (status: string) => {
    if(['design_pending','customer_approval','approved_by_seller','approved_by_designer'].includes(status)) return 'design_released';
    if(status === 'design_released') return 'waiting_separation';
    if(status === 'waiting_separation') return 'in_separation';
    if(status === 'in_separation') return 'waiting_print';

    if(status === 'waiting_print') return 'BLOCKED_PRINTING';

    if(status === 'printing') return 'printed';
    if(status === 'printed') return 'waiting_calandra';
    if(status === 'waiting_calandra') return 'in_production';
    if(status === 'in_production') return 'billing_pending';

    if(status === 'billing_pending') return 'completed';
    if(status === 'waiting_release') return 'completed';
    if(['production_queue','in_printing','in_cutting'].includes(status)) return 'waiting_print';
    return '';
};

const getTabForStatus = (status: string) => {
  if(['design_pending','customer_approval','approved_by_seller','approved_by_designer'].includes(status)) return 'design';
  if(['design_released','waiting_separation','in_separation'].includes(status)) return 'separacao';
  if(['waiting_print','printing'].includes(status)) return 'impressao';
  if(['printed','waiting_calandra','in_calandra','in_production'].includes(status)) return 'calandra';
  if(['billing_pending', 'Em Aberto', 'Parcialmente Faturado', 'Faturado'].includes(status)) return 'faturamento';
  if(['waiting_release','ready_for_delivery','completed'].includes(status)) return 'liberacao';
  return null;
};

// ----------------------------------------------------------------------------------
// HOVER NATIVO
// ----------------------------------------------------------------------------------
const setItemHighlight = (item: any) => {
    const next = getNextLogicalStatus(item.status);
    if(next && next !== 'BLOCKED_PRINTING') {
        const tabId = getTabForStatus(next);
        if (tabId) document.getElementById('pcp-layout-wrapper')?.setAttribute('data-highlight-tab', tabId);
    }
};

const setGroupHighlight = (group: any) => {
  const validItems = group.items.filter((i: any) => !isGhostRow(i));
  if (validItems.length === 0) return;
  const firstStatus = validItems[0].status;
  const allSame = validItems.every((i:any) => i.status === firstStatus);
  if(allSame) {
      const next = getNextLogicalStatus(firstStatus);
      if(next && next !== 'BLOCKED_PRINTING') {
          const tabId = getTabForStatus(next);
          if (tabId) document.getElementById('pcp-layout-wrapper')?.setAttribute('data-highlight-tab', tabId);
      }
  }
};

const clearHighlight = () => {
    document.getElementById('pcp-layout-wrapper')?.removeAttribute('data-highlight-tab');
};
// ----------------------------------------------------------------------------------

const advanceStatus = async (item: any) => {
    if (companyStore.isDemoMode) return appStore.showSnackbar('Ação não permitida em modo demonstração', 'warning');
    const next = getNextLogicalStatus(item.status);

    if(!next) return alert(`Status final ou desconhecido: ${item.status}`);

    if (next === 'BLOCKED_PRINTING') {
        appStore.showSnackbar('Use a "Estação de Impressão" (no menu superior) para selecionar a máquina, o operador e iniciar a impressão deste item.', 'warning');
        return;
    }

    if(next === 'in_production') {
        await store.fetchMachines('calandra');
        calandraModal.item = item;
        calandraModal.show = true;
        return;
    }

    if(confirm(`Avançar para ${getStatusConfig(next).label}?`)) {
      const prev = item.status;
      item.status = next;
      try {
        await store.moveStage(item.id, next, `advanced_to_${next}`);
        appStore.showSnackbar('Atualizado.', 'success');
      } catch (e) {
        item.status = prev;
        appStore.showSnackbar('Erro ao avançar.', 'error');
      }
    }
};

const quickSetItemStatus = async (item:any, status:string, type:string) => {
  if (companyStore.isDemoMode) return appStore.showSnackbar('Ação não permitida em modo demonstração', 'warning');
  const prev = item.status;
  item.status = status;
  try {
    if(type === 'order') {
        await store.forceBatchUpdateByOrder(item.id, status);
        rawList.value.forEach(i => {
            if (i.order_id === item.id || i.order?.id === item.id || i.id === item.id) {
                i.status = status;
            }
        });
    }
    else {
        await store.forceUpdateItemStatus(item.id, status);
    }
    appStore.showSnackbar('Status atualizado.', 'success');
  } catch (e) {
    item.status = prev;
    appStore.showSnackbar('Erro ao atualizar status.', 'error');
  }
};

const confirmCalandra = async () => {
    if (companyStore.isDemoMode) return appStore.showSnackbar('Ação não permitida em modo demonstração', 'warning');
    if(calandraModal.item) {
        await store.moveStage(calandraModal.item.id, 'in_production', 'sent_to_calandra', { machine:calandraModal.machine, operator:calandraModal.operator });
        calandraModal.item.status = 'in_production';
    }
    calandraModal.show = false;
};

const openEditModal = (item: any) => { editModal.item = item; editModal.form = { stamp_ref: item.stamp_ref, fabric_type: item.fabric_type, quantity_meters: Number(item.quantity_meters), notes: item.notes || '' }; editModal.show = true; };

const saveEditItem = async () => {
    if (companyStore.isDemoMode) return appStore.showSnackbar('Ação não permitida em modo demonstração', 'warning');
    if(!editModal.item?.id) return;
    editModal.loading = true;
    try {
        const { error } = await supabase.from('order_items').update({ stamp_ref: editModal.form.stamp_ref, fabric_type: editModal.form.fabric_type, quantity_meters: editModal.form.quantity_meters, notes: editModal.form.notes }).eq('id', editModal.item.id);
        if(error) throw error;

        editModal.item.stamp_ref = editModal.form.stamp_ref;
        editModal.item.fabric_type = editModal.form.fabric_type;
        editModal.item.quantity_meters = editModal.form.quantity_meters;
        editModal.item.notes = editModal.form.notes;

        editModal.show = false;
    } catch(e:any) { alert('Erro: ' + e.message); } finally { editModal.loading = false; }
};

const openLaunchDetail = (item: any) => {
    const orderId = item.order_id || item.order?.id;
    if(!orderId) return alert('Pedido não vinculado.');
    launchDetailModal.orderId = String(orderId); launchDetailModal.itemId = String(item.id); launchDetailModal.show = true;
};

// =======================================================
// MODO DEMO: POPULAR DADOS
// =======================================================
const populateDemoData = () => {
    const today = new Date().toISOString();
    const yesterday = new Date(Date.now() - 86400000).toISOString();

    store.managementList = [
        { id: 'fake-1', order_id: 'ord-1', order: { id: 'ord-1', order_number: 1001, customer_name: 'Cliente Fictício A' }, customer_name: 'Cliente Fictício A', stamp_ref: 'EST-001', fabric_type: 'Malha', quantity_meters: 50, status: 'design_released', created_at: today },
        { id: 'fake-2', order_id: 'ord-2', order: { id: 'ord-2', order_number: 1002, customer_name: 'Cliente Fictício B' }, customer_name: 'Cliente Fictício B', stamp_ref: 'EST-002', fabric_type: 'Moletom', quantity_meters: 100, status: 'waiting_print', created_at: yesterday },
        { id: 'fake-3', order_id: 'ord-3', order: { id: 'ord-3', order_number: 1003, customer_name: 'Cliente Fictício C' }, customer_name: 'Cliente Fictício C', stamp_ref: 'EST-003', fabric_type: 'Dry Fit', quantity_meters: 200, status: 'printed', created_at: yesterday },
        { id: 'fake-4', order_id: 'ord-4', order: { id: 'ord-4', order_number: 1004, customer_name: 'Cliente Fictício D' }, customer_name: 'Cliente Fictício D', stamp_ref: 'EST-004', fabric_type: 'Helanca', quantity_meters: 30, status: 'waiting_separation', created_at: today },
        { id: 'fake-5', order_id: 'ord-5', order: { id: 'ord-5', order_number: 1005, customer_name: 'Cliente Fictício E' }, customer_name: 'Cliente Fictício E', stamp_ref: 'EST-005', fabric_type: 'Tactel', quantity_meters: 150, status: 'in_production', created_at: yesterday },
        { id: 'fake-6', order_id: 'ord-6', order: { id: 'ord-6', order_number: 1006, customer_name: 'Cliente Fictício F' }, customer_name: 'Cliente Fictício F', stamp_ref: 'EST-006', fabric_type: 'Lycra', quantity_meters: 80, status: 'design_pending', design_tag: 'Desenvolvimento', created_at: today },
    ] as any;

    store.billingList = [
        { id: 'fake-b1', order_number: 1007, customer_name: 'Cliente Fictício G', total_value: 1500.00, status: 'billing_pending', financial_status: 'Em Aberto', billing_queue_visible: true, billing_alert: false, created_at: yesterday },
        { id: 'fake-b2', order_number: 1008, customer_name: 'Cliente Fictício H', total_value: 3200.50, status: 'completed', financial_status: 'Faturado', billing_queue_visible: true, billing_alert: true, created_at: yesterday },
    ] as any;

    store.expeditionList = [
        { id: 'fake-e1', order_id: 'ord-9', order: { id: 'ord-9', order_number: 1009, customer_name: 'Cliente Fictício I' }, customer_name: 'Cliente Fictício I', stamp_ref: 'EST-009', fabric_type: 'Malha PV', quantity_meters: 120, status: 'waiting_release', created_at: yesterday },
    ] as any;

    store.ghostOrders = [
        { id: 'fake-g1', order_id: 'ord-10', order_number: 1010, customer_name: 'Fantasma Fictício J', actual_delivery_date: today, status: 'waiting_release', is_ghost: true }
    ] as any;
};

const switchTab = (id:string) => { activeTab.value = id; pagination.page = 1; filters.status = []; refreshCurrentData(); };

const refreshCurrentData = () => {
    if (companyStore.isDemoMode) {
        populateDemoData();
        return;
    }
    if(isBillingTab.value) store.fetchBillingOrders();
    else if(activeTab.value === 'liberacao') store.fetchExpeditionData();
    else store.fetchManagementItems();
};

const formatDate = (d:string) => d ? format(new Date(d), 'dd/MM/yy') : '-';
const formatDateFull = (d:string) => d ? format(new Date(d), 'dd/MM/yy HH:mm') : '-';
const formatCurrency = (v:number) => new Intl.NumberFormat('pt-BR',{style:'currency',currency:'BRL'}).format(Number(v)||0);
const formatNumber = (v:number) => new Intl.NumberFormat('pt-BR', { minimumFractionDigits: 0, maximumFractionDigits: 2 }).format(Number(v)||0);
const zebraClass = (i: number) => themeStore.currentMode === 'light' ? (i % 2 === 0 ? 'zebra-light-a' : 'zebra-light-b') : (i % 2 === 0 ? 'zebra-dark-a' : 'zebra-dark-b');

const openImage = (item:any) => { imageModal.url = item.stamp_image_url||item.print_file_url; imageModal.name = item.stamp_ref; imageModal.show = true; };
const openLogs = (item:any) => {
    if (companyStore.isDemoMode) {
        store.currentLogs = [{ id: '1', action: 'CREATED', created_at: new Date().toISOString(), user: { full_name: 'Sistema' } }] as any;
        logModal.show = true;
        return;
    }
    store.fetchItemLogs(item.id);
    logModal.show = true;
};

const isGhostRow = (r:any) => r.is_ghost || !r.stamp_ref;
const rowKey = (r:any) => {
    if (!r) return 'empty';
    const baseId = r.id || r.order_id || r.order?.id || r.order_number || Math.random().toString(36).slice(2, 9);
    return isGhostRow(r) ? `ghost-${baseId}` : `item-${baseId}`;
};

const getReleaseDate = (r:any) => isGhostRow(r) ? r.actual_delivery_date : r.order?.actual_delivery_date;
const getReleaseStatus = (r:any) => r.status || 'waiting_release';
const getBestRowDate = (row: any) => { if (activeTab.value === 'liberacao') return getReleaseDate(row) || row.created_at || row.order?.created_at; return row.created_at || row.order?.created_at; };

const toggleBillingVisibility = async (order:any) => {
    if (companyStore.isDemoMode) return appStore.showSnackbar('Ação não permitida em modo demonstração', 'warning');
    await store.setBillingVisibility([order.id], !order.billing_queue_visible);
    order.billing_queue_visible = !order.billing_queue_visible;
};

const toggleAlert = async (order:any) => {
    if (companyStore.isDemoMode) return appStore.showSnackbar('Ação não permitida em modo demonstração', 'warning');
    await store.toggleBillingAlert(order.id, !order.billing_alert);
    order.billing_alert = !order.billing_alert;
}

const openBillingAlertModal = (order: any) => { alertModal.order = order; alertModal.message = order.details?.alert_message || ''; alertModal.show = true; };

const saveBillingAlert = async () => {
    if (companyStore.isDemoMode) return appStore.showSnackbar('Ação não permitida em modo demonstração', 'warning');
    if(!alertModal.order) return;
    try {
        await supabase.from('orders').update({ billing_alert: true, details: { ...alertModal.order.details, alert_message: alertModal.message } }).eq('id', alertModal.order.id);

        alertModal.order.billing_alert = true;
        if (!alertModal.order.details) alertModal.order.details = {};
        alertModal.order.details.alert_message = alertModal.message;

        alertModal.show = false;
    } catch(e) { alert('Erro ao salvar aviso'); }
};

const openManualStatus = (item: any, type: string) => { manualStatusModal.item = item; manualStatusModal.type = type; manualStatusModal.newStatus = item.status; manualStatusModal.show = true; };
const confirmManualStatus = async () => {
    if (companyStore.isDemoMode) return appStore.showSnackbar('Ação não permitida em modo demonstração', 'warning');
    if(manualStatusModal.type === 'order') {
        const id = manualStatusModal.item.orderId || manualStatusModal.item.id;
        await store.forceBatchUpdateByOrder(id, manualStatusModal.newStatus);
        rawList.value.forEach(i => {
            if (i.order_id === id || i.order?.id === id || i.id === id) {
                i.status = manualStatusModal.newStatus;
            }
        });
    } else {
        await store.forceUpdateItemStatus(manualStatusModal.item.id, manualStatusModal.newStatus);
        manualStatusModal.item.status = manualStatusModal.newStatus;
    }
    manualStatusModal.show = false;
};

const selectedRows = computed(() => { const keys = selectedIds.value; if (keys.size === 0) return []; if (activeTab.value === 'liberacao') return filteredList.value.filter((r: any) => keys.has(rowKey(r))); return filteredList.value.filter((r: any) => keys.has(String(r.id))); });
const selectedCount = computed(() => selectedIds.value.size);
const floatingContextLabel = computed(() => `Itens Selecionados (${selectedCount.value})`);
const clearSelection = () => { selectedIds.value.clear(); };

const batchAdvanceSelected = async () => {
  if (companyStore.isDemoMode) return appStore.showSnackbar('Ação não permitida em modo demonstração', 'warning');
  const rows = selectedRows.value;
  if (rows.length === 0) return;

  const validItems = rows.filter((i: any) => !isGhostRow(i));
  if(validItems.length === 0) return;

  const firstStatus = validItems[0].status;
  const allSame = validItems.every((i:any) => i.status === firstStatus);

  if (!allSame) {
      appStore.showSnackbar('Acesso Negado: Todos os itens selecionados devem estar na mesma etapa para avançar.', 'warning');
      return;
  }

  const nextStatus = getNextLogicalStatus(firstStatus);
  if (!nextStatus) return;

  if (nextStatus === 'BLOCKED_PRINTING') {
      appStore.showSnackbar('Para iniciar a impressão, utilize a Estação de Impressão.', 'warning');
      return;
  }

  if (!confirm(`Avançar ${validItems.length} item(ns) para ${getStatusConfig(nextStatus).label}?`)) return;

  try {
    const promises = validItems.map((item: any) =>
        store.moveStage(item.id, nextStatus, `advanced_to_${nextStatus}`)
    );
    await Promise.all(promises);

    for (const row of filteredList.value) {
      if (row?.id && selectedIds.value.has(String(row.id))) row.status = nextStatus;
    }
    appStore.showSnackbar('Itens avançados com sucesso.', 'success');
  } catch (e) {
    appStore.showSnackbar('Erro ao avançar itens.', 'error');
  } finally {
    clearSelection();
  }
};

const batchSetStatusSelected = async (status: string) => {
  if (companyStore.isDemoMode) return appStore.showSnackbar('Ação não permitida em modo demonstração', 'warning');
  const ids = Array.from(selectedIds.value);
  if (ids.length === 0) return;

  if (!confirm(`Mover ${ids.length} item(ns) para: ${statusLabel(status)}?`)) return;

  try {
    const promises = ids.map((id: string) => store.forceUpdateItemStatus(id, status));
    await Promise.all(promises);

    for (const row of filteredList.value) {
      if (row?.id && selectedIds.value.has(String(row.id))) row.status = status;
    }

    appStore.showSnackbar('Itens movidos.', 'success');
  } catch (e) {
    appStore.showSnackbar('Erro ao mover itens.', 'error');
  } finally {
    clearSelection();
  }
};

const batchBillingSetVisibility = async (val: boolean) => {
  if (companyStore.isDemoMode) return appStore.showSnackbar('Ação não permitida em modo demonstração', 'warning');
  const ids = Array.from(selectedIds.value);
  if (ids.length === 0) return;

  if (!confirm(`Definir visibilidade de ${ids.length} pedido(s) para ${val ? 'VISÍVEL' : 'OCULTO'}?`)) return;

  try {
    await store.setBillingVisibility(ids, val);
    appStore.showSnackbar('Atualizado com sucesso (sem recarregar a tela).', 'success');
  } catch (e) {
    appStore.showSnackbar('Erro ao atualizar visibilidade.', 'error');
  } finally {
    clearSelection();
  }
};

const batchBillingToggleAlert = async () => {
  if (companyStore.isDemoMode) return appStore.showSnackbar('Ação não permitida em modo demonstração', 'warning');
  const rows = selectedRows.value;
  if (rows.length === 0) return;

  if (!confirm(`Alternar ALERTA em ${rows.length} pedido(s)?`)) return;

  try {
    for (const o of rows) {
      await store.toggleBillingAlert(o.id, !o.billing_alert);
    }
    appStore.showSnackbar('Alertas atualizados.', 'success');
  } catch (e) {
    appStore.showSnackbar('Erro ao atualizar alertas.', 'error');
  } finally {
    clearSelection();
  }
};

const batchMarkDelivered = async () => {
  if (companyStore.isDemoMode) return appStore.showSnackbar('Ação não permitida em modo demonstração', 'warning');
  const rows = selectedRows.value;
  if (rows.length === 0) return;

  const orderIds = Array.from(new Set(rows.map((r: any) => resolveOrderId(r)).filter(Boolean)));

  if (orderIds.length === 0) {
    appStore.showSnackbar('Nenhum pedido válido selecionado.', 'warning');
    return;
  }

  if (!confirm(`Confirmar ENTREGA de ${orderIds.length} pedido(s)?`)) return;

  try {
    await store.confirmOrdersDelivered(orderIds);

    for (const r of rows) {
      const o = r.order || r;
      if (o) {
        o.delivery_confirmed_at = new Date().toISOString();
        if (!o.actual_delivery_date) o.actual_delivery_date = new Date().toISOString().slice(0, 10);
        if (String(o.status || '').toLowerCase() !== 'delivered') o.status = 'delivered';
      }
    }

    appStore.showSnackbar('Entrega confirmada.', 'success');
  } catch (e) {
    appStore.showSnackbar('Erro ao confirmar entrega.', 'error');
  } finally {
    clearSelection();
  }
};

const batchAdvanceGroup = async (group: any) => {
  if (companyStore.isDemoMode) return appStore.showSnackbar('Ação não permitida em modo demonstração', 'warning');
  const validItems = group.items.filter((i: any) => !isGhostRow(i));
  if (validItems.length === 0) return;

  const firstStatus = validItems[0].status;
  const allSame = validItems.every((i:any) => i.status === firstStatus);

  if (!allSame) {
      appStore.showSnackbar('Acesso Negado: Todos os itens do pedido devem estar na exata mesma etapa para avançar juntos.', 'warning');
      return;
  }

  const nextStatus = getNextLogicalStatus(firstStatus);
  if (!nextStatus) return;

  if (nextStatus === 'BLOCKED_PRINTING') {
      appStore.showSnackbar('Use a "Estação de Impressão" para iniciar a impressão de todos itens.', 'warning');
      return;
  }

  if (!confirm(`Avançar ${validItems.length} item(ns) para ${getStatusConfig(nextStatus).label}?`)) return;

  try {
    const promises = validItems.map((item: any) =>
        store.moveStage(item.id, nextStatus, `advanced_to_${nextStatus}`)
    );
    await Promise.all(promises);

    for (const it of group.items) {
      if (it?.id && validItems.find((v:any)=>v.id === it.id)) it.status = nextStatus;
    }
    appStore.showSnackbar('Pedido atualizado.', 'success');
  } catch (e) {
    appStore.showSnackbar('Erro ao avançar pedido.', 'error');
  }
};

const resolveOrderId = (obj: any): string | null => { if (!obj) return null; if (obj.order_id) return String(obj.order_id); if (obj.order?.id) return String(obj.order.id); if (obj.id) return String(obj.id); return null; };

const groupedOrders = computed(() => {
  const base = filteredList.value;
  const groups: Record<string, any> = {};
  base.forEach((item: any) => {
    let oid = item.order_id || item.order?.id;
    if (!oid && item.id && item.order_number && !item.stamp_ref) oid = item.id;
    if (!oid) return;
    if (!groups[oid]) {
      const orderObj = item.order || item;
      const created = item.order?.created_at || item.created_at || orderObj?.created_at || null;
      const isLegacy = created ? (new Date(created).getTime() < new Date('2026-01-05T00:00:00-03:00').getTime()) : false;
      groups[oid] = {
        orderId: oid,
        orderNumber: item.order_number || item.order?.order_number,
        customerName: item.customer_name || item.order?.customer_name,
        order: orderObj,
        deliveryBadge: store.resolveOrderDeliveryBadge(orderObj),
        isLegacy,
        items: [],
        totalMeters: 0,
      };
    }
    if (item.stamp_ref) {
        groups[oid].items.push(item);
        groups[oid].totalMeters += Number(item.quantity_meters || 0);
    } else {
        groups[oid].items.push({
            ...item,
            id: `ghost-${item.id}`,
            is_ghost: true,
            stamp_ref: 'PEDIDO AGENDADO (FANTASMA)',
            fabric_type: '-',
            quantity_meters: 0,
            status: item.status || 'waiting_release'
        });
    }
  });
  return Object.values(groups);
});


const formatDateShort = (iso?: string | null) => {
  if (!iso) return '-';
  const d = new Date(iso);
  if (!Number.isFinite(d.getTime())) return '-';
  return d.toLocaleDateString('pt-BR');
};

const deliveryBadgeLabel = (b: any) => {
  switch (b) {
    case 'ENTREGUE': return 'ENTREGUE';
    case 'AGUARDANDO_AGENDAMENTO': return 'AGUARD. AGEND.';
    case 'AGENDADO': return 'AGENDADO';
    case 'PRONTO_PARA_ENTREGA': return 'PRONTO';
    case 'EM_PRODUCAO': return 'EM PRODUÇÃO';
    default: return 'STATUS';
  }
};

const deliveryBadgeColor = (b: any) => {
  switch (b) {
    case 'ENTREGUE': return 'green-darken-2';
    case 'AGENDADO': return 'blue-darken-2';
    case 'AGUARDANDO_AGENDAMENTO': return 'amber-darken-2';
    case 'PRONTO_PARA_ENTREGA': return 'teal-darken-2';
    case 'EM_PRODUCAO': return 'deep-purple-darken-1';
    default: return 'grey-darken-2';
  }
};

const statusLabel = (status: string) => {
  const opt = statusOptions.find((o: any) => o.value === status);
  return opt?.label || status;
};

const statusChipColor = (status: string) => {
  if (['completed'].includes(status)) return 'green-darken-2';
  if (['ready_for_delivery'].includes(status)) return 'teal-darken-2';
  if (['waiting_release'].includes(status)) return 'amber-darken-2';
  if (['in_separation', 'printing', 'in_calandra', 'in_production'].includes(status)) return 'blue-darken-2';
  return 'grey-darken-2';
};

const kanbanKpiDefs = [
  { id: 'design', title: 'Design', bgClass: 'kanban-bg-1', statuses: ['design_pending','customer_approval','approved_by_seller','approved_by_designer'] },
  { id: 'pcp', title: 'PCP', bgClass: 'kanban-bg-2', statuses: ['design_released','waiting_separation','in_separation','waiting_print','printing','printed','waiting_calandra','in_calandra','in_production','billing_pending','waiting_release'] },
  { id: 'separacao', title: 'Separação', bgClass: 'kanban-bg-3', statuses: ['waiting_separation','in_separation'] },
  { id: 'impressao', title: 'Impressão', bgClass: 'kanban-bg-4', statuses: ['waiting_print','printing'] },
  { id: 'calandra', title: 'Calandra', bgClass: 'kanban-bg-5', statuses: ['printed','waiting_calandra','in_calandra','in_production'] },
  { id: 'liberacao', title: 'Expedição', bgClass: 'kanban-bg-6', statuses: ['waiting_release','ready_for_delivery','completed'] },
  { id: 'legado', title: 'Legado', bgClass: 'kanban-bg-7', statuses: ['production_queue','in_printing','in_cutting'] },
];

const buildKanbanCard = (row: any) => {
  const order = row.order || row;
  const orderNumber = row.order_number || row.order?.order_number || order?.order_number || '-';
  const customerName = row.customer_name || row.order?.customer_name || order?.customer_name || '-';
  const deliveryBadge = store.resolveOrderDeliveryBadge(order);
  const bestDate = getBestRowDate(row) || row.created_at || row.order?.created_at || order?.created_at || null;
  const isLegacy = (() => {
    const dt = row.order?.created_at || row.created_at || order?.created_at || null;
    if (!dt) return false;
    return new Date(dt).getTime() < new Date('2026-01-05T00:00:00-03:00').getTime();
  })();

  const isGhost = isGhostRow(row);
  const title = isGhost ? 'PEDIDO (AGENDADO / FANTASMA)' : `${row.stamp_ref || 'SEM REF'} • ${row.fabric_type || '-'}`;
  const imageUrl = row.stamp_image_url || row.print_file_url;
  const quantityMeters = Number(row.quantity_meters || 0);

  return {
    __kkey: rowKey(row),
    raw: row,
    id: row.id,
    status: row.status || row.financial_status || 'design_pending',
    orderId: resolveOrderId(row),
    orderNumber,
    customerName,
    deliveryBadge,
    isLegacy,
    title,
    imageUrl,
    quantityMeters,
    bestDate,
  };
};

const kanbanColumns = computed(() => {
  const baseMgmt = store.managementList || [];
  const baseExp = [...(store.ghostOrders || []), ...(store.expeditionList || [])];

  const universe = companyStore.isDemoMode ? rawList.value : [...baseMgmt, ...baseExp];

  let list = universe;

  if (filters.search) {
    const s = filters.search.toLowerCase();
    list = list.filter((i: any) =>
      String(i.order_number || i.order?.order_number || '').includes(s) ||
      String(i.customer_name || i.order?.customer_name || '').toLowerCase().includes(s) ||
      String(i.stamp_ref || '').toLowerCase().includes(s)
    );
  }

  if (filters.status.length > 0) list = list.filter((i: any) => filters.status.includes(i.status || i.financial_status));

  if (filters.dateStart || filters.dateEnd) {
    const start = filters.dateStart ? new Date(filters.dateStart) : null;
    const end = filters.dateEnd ? new Date(filters.dateEnd) : null;
    if (end) end.setHours(23, 59, 59);
    list = list.filter((i: any) => {
      const dateStr = getBestRowDate(i) || i.created_at || i.order?.created_at;
      if (!dateStr) return false;
      const d = new Date(dateStr);
      if (start && d < start) return false;
      if (end && d > end) return false;
      return true;
    });
  }

  const dir = sortOrder.value === 'oldest' ? 1 : -1;
  list = [...list].sort((a: any, b: any) => {
    const da = getBestRowDate(a) || a.created_at || a.order?.created_at || '';
    const db = getBestRowDate(b) || b.created_at || b.order?.created_at || '';
    const ta = da ? new Date(da).getTime() : 0;
    const tb = db ? new Date(db).getTime() : 0;
    if (ta === tb) return 0;
    return ta < tb ? -1 * dir : 1 * dir;
  });

  const cols = kanbanKpiDefs.map(def => ({
    id: def.id,
    title: def.title,
    bgClass: def.bgClass,
    statuses: def.statuses,
    items: [] as any[],
    legacyCount: 0,
    totalMeters: 0,
  }));

  for (const row of list) {
    const status = String(row.status || '');
    const col = cols.find(c => c.statuses.includes(status));
    if (!col) continue;

    const card = buildKanbanCard(row);
    col.items.push(card);
    col.totalMeters += Number(card.quantityMeters || 0);
    if (card.isLegacy) col.legacyCount += 1;
  }

  return cols;
});

const kanbanDragPayload = ref<any>(null);

const getDefaultStatusForColumn = (colId: string): string | null => {
  const def = kanbanKpiDefs.find(d => d.id === colId);
  if (!def) return null;

  switch (colId) {
    case 'design': return 'design_pending';
    case 'separacao': return 'waiting_separation';
    case 'impressao': return 'waiting_print';
    case 'calandra': return 'waiting_calandra';
    case 'liberacao': return 'waiting_release';
    case 'legado': return 'production_queue';
    case 'pcp': return 'design_released';
    default: return def.statuses[0] || null;
  }
};

const onKanbanDragStart = (card: any, fromColId: string, ev: DragEvent) => {
  kanbanDragPayload.value = { card, fromColId };
  try {
    ev.dataTransfer?.setData('application/json', JSON.stringify({ key: card.__kkey, fromColId, id: card.id, orderId: card.orderId }));
  } catch {}
  ev.dataTransfer?.setDragImage?.((ev.target as any), 10, 10);
};

const onKanbanDrop = async (toColId: string, ev: DragEvent) => {
  if (companyStore.isDemoMode) return appStore.showSnackbar('Ação não permitida em modo demonstração', 'warning');
  const payload = kanbanDragPayload.value;
  if (!payload?.card?.raw) return;

  const targetStatus = getDefaultStatusForColumn(toColId);
  if (!targetStatus) return;

  const raw = payload.card.raw;

  if (isGhostRow(raw)) {
    appStore.showSnackbar('Pedido fantasma não pode ser movido por Kanban. Use ações do pedido.', 'warning');
    return;
  }

  if (!userStore.isSuperAdmin) {
      const nextValid = getNextLogicalStatus(raw.status);
      if (targetStatus !== nextValid && targetStatus !== raw.status) {
          appStore.showSnackbar('Acesso Negado: Você deve seguir as etapas corretamente. Use o botão de avançar.', 'error');
          return;
      }
  }

  const prev = raw.status;
  raw.status = targetStatus;

  try {
    await store.forceUpdateItemStatus(raw.id, targetStatus);
    appStore.showSnackbar(`Movido para ${statusLabel(targetStatus)}`, 'success');
  } catch (e) {
    raw.status = prev;
    appStore.showSnackbar('Erro ao mover item no Kanban', 'error');
  }
};

const markOrderDeliveredFromItem = async (item: any) => {
  if (companyStore.isDemoMode) return appStore.showSnackbar('Ação não permitida em modo demonstração', 'warning');
  const oid = item.order?.id || item.order_id || item.orderId;
  if (!oid) return;
  if (!confirm('Confirmar entrega deste pedido?')) return;

  try {
    await store.confirmOrderDelivered(String(oid));
    const o = item.order || item;
    if (o) {
      o.delivery_confirmed_at = new Date().toISOString();
      if (!o.actual_delivery_date) o.actual_delivery_date = new Date().toISOString().slice(0, 10);
      o.status = 'delivered';
    }
    appStore.showSnackbar('Entrega confirmada.', 'success');
  } catch (e) {
    appStore.showSnackbar('Erro ao confirmar entrega.', 'error');
  }
};

const clearFilters = () => {
  filters.search = '';
  filters.status = [];
  filters.dateStart = '';
  filters.dateEnd = '';
};

// -------------------------------------------------------------------------
// ATUALIZAÇÃO OTIMISTA (SEM FALSO LOADING)
// -------------------------------------------------------------------------
const currentViewData = computed(() => {
    if (viewMode.value === 'list') return paginatedList.value;
    if (viewMode.value === 'grouped') return groupedOrders.value;
    if (viewMode.value === 'kanban') return kanbanColumns.value;
    return [];
});

watch(currentViewData, (newVal) => {
  if (viewMode.value === 'list') displayedList.value = newVal;
  else if (viewMode.value === 'grouped') displayedGrouped.value = newVal;
  else if (viewMode.value === 'kanban') displayedKanban.value = newVal;
}, { immediate: true, deep: true });


// PDF GENERATION
const imageToBase64 = async (url: string): Promise<string> => { try { const res = await fetch(url); const blob = await res.blob(); return new Promise((resolve) => { const reader = new FileReader(); reader.onload = () => resolve(reader.result as string); reader.readAsDataURL(blob); }); } catch (e) { return ''; } };
const filterOrdersByPeriod = (list: any[]) => {
  const now = new Date(); let startDate: Date;
  switch (reportPeriod.value) { case 'today': startDate = startOfDay(now); break; case 'week': startDate = startOfWeek(now, { weekStartsOn: 1 }); break; case 'year': startDate = startOfYear(now); break; case 'month': default: startDate = startOfMonth(now); break; }
  return list.filter(o => { const d = o.updated_at || o.created_at; if(!d) return false; return isAfter(parseISO(d), startDate); });
};

const generateReport = async (scope: 'current' | 'all' | 'kpi') => {
  if (scope === 'current' && activeTab.value === 'legado') { appStore.showSnackbar("Relatório indisponível para Legacy", "warning"); return; }
  loadingPdf.value = true;
  try {
    const doc = new jsPDF({ orientation: 'p', unit: 'mm', format: 'a4' });
    const logoUrl = 'https://cdn.shopify.com/s/files/1/0661/4574/6991/files/Sem_nome_1080_x_800_px_1080_x_500_px_1080_x_400_px_1000_x_380_px_da020cf2-2bb9-4dac-8dd3-4548cfd2e5ae.png?v=1756811713';
    const logoBase64 = await imageToBase64(logoUrl);
    const pageWidth = doc.internal.pageSize.width;
    const drawHeader = (title: string, subtitle: string) => {
      if (logoBase64) doc.addImage(logoBase64, 'PNG', 14, 10, 35, 12);
      doc.setFontSize(8).setTextColor(100).text("CONFECCOES MJ", pageWidth - 14, 12, { align: 'right' }).text(`Gerado em: ${format(new Date(), 'dd/MM/yyyy HH:mm')}`, pageWidth - 14, 16, { align: 'right' });
      doc.setDrawColor(200).setLineWidth(0.5).line(14, 26, pageWidth - 14, 26);
      doc.setFontSize(16).setTextColor(0).setFont("helvetica", "bold").text(title.toUpperCase(), 14, 36);
      doc.setFontSize(10).setFont("helvetica", "normal").text(subtitle, 14, 42);
    };
    const periodText = `Período: ${reportPeriod.value}`;

    if (scope === 'kpi') {
      const allItems = filterOrdersByPeriod(store.managementList || []);
      const totalMeters = allItems.reduce((acc, i) => acc + (Number(i.quantity_meters) || 0), 0);
      drawHeader("RESUMO GERENCIAL - ESTAMPARIA", periodText);
      doc.setFontSize(14).text(`Total Metros: ${formatNumber(totalMeters)}m`, 14, 60);
    } else {
      const tabsToProcess = scope === 'current' ? [kpiTabs.value.find(k => k.id === activeTab.value)] : kpiTabs.value.filter(k => !['legado', 'faturamento', 'design'].includes(k.id));
      let hasPrintedPage = false;
      for (const kpi of tabsToProcess) {
        if (!kpi) continue;
        let targetList = (kpi.id === 'faturamento') ? store.billingList : (kpi.id === 'liberacao' ? [...(store.ghostOrders||[]), ...(store.expeditionList||[])] : store.managementList);
        if(kpi.id === 'pcp') targetList = store.managementList.filter((i:any) => ['design_released','waiting_separation','in_separation','waiting_print','printing','printed','waiting_calandra','in_calandra','in_production','billing_pending','waiting_release'].includes(i.status));

        const filtered = filterOrdersByPeriod(targetList || []);
        if (hasPrintedPage) doc.addPage(); hasPrintedPage = true;
        drawHeader(`RELATÓRIO: ${kpi.label}`, periodText);

        if(reportGrouping.value === 'orders') {
            const grouped = filtered.reduce((acc: any, item: any) => {
                const oid = item.order_id || item.order?.id || item.id;
                if(!acc[oid]) acc[oid] = { order: item.order || item, items: [] };
                if(item.stamp_ref) acc[oid].items.push(item);
                return acc;
            }, {});

            const tableBody = Object.values(grouped).map((g: any) => [
                `#${String(g.order.order_number).padStart(4,'0')}`,
                g.order.customer_name?.substring(0, 25),
                `${g.items.length} itens`,
                `${formatNumber(g.items.reduce((s:number, i:any)=>s+(Number(i.quantity_meters)||0),0))}m`,
                g.order.status
            ]);
            autoTable(doc, { startY: 55, head: [['Pedido', 'Cliente', 'Qtd Itens', 'Total Metros', 'Status']], body: tableBody });
        } else {
             const tableBody = filtered.map(item => [
                `#${item.order_number || item.order?.order_number || '-'}`,
                item.customer_name?.substring(0, 20) || item.order?.customer_name?.substring(0, 20),
                item.stamp_ref || '-',
                `${formatNumber(item.quantity_meters)}m`,
                item.status
             ]);
             autoTable(doc, { startY: 55, head: [['Pedido', 'Cliente', 'Ref', 'Metros', 'Status']], body: tableBody });
        }
      }
    }
    doc.save(`Relatorio_${scope}.pdf`);
    appStore.showSnackbar("Relatório gerado!", "success");
  } catch (e: any) { appStore.showSnackbar("Erro PDF: " + e.message, "error"); } finally { loadingPdf.value = false; }
};

onMounted(() => {
  if (kpiTabs.value.length > 0 && !kpiTabs.value.find(t => t.id === activeTab.value)) {
    activeTab.value = kpiTabs.value[0].id;
  }
  refreshCurrentData();
  store.fetchOperators();
});
</script>

<style scoped lang="scss">
/* Layout */
.production-layout { position: relative; height: 100vh; }
.bg-glass-dark { background: rgba(10,10,12,0.95); }
.bg-glass-header { background: rgba(20,20,24,0.85); backdrop-filter: blur(14px); }
.background-carousel-wrapper { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 0; opacity: 0.6; pointer-events: none; }
.background-overlay { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 1; background: radial-gradient(circle at center, rgba(15, 15, 19, 0.4), rgba(15, 15, 19, 0.98)); backdrop-filter: blur(8px); }

/* Grid System e Identidade Visual (Baseado em AdminMjReceivables) */
.grid-header, .grid-row { display: grid; align-items: stretch; width: 100%; min-width: 1600px; }
.grid-default { grid-template-columns: 44px 50px 60px 180px minmax(200px, 1fr) 100px 100px 140px 160px; }
.grid-billing { grid-template-columns: 44px 60px 100px minmax(250px, 1fr) 160px 160px 140px 80px 160px; }
.grid-release { grid-template-columns: 44px 60px 140px minmax(250px, 1fr) 120px 140px 160px; }

.cell { padding: 0 12px; display: flex; align-items: center; border-right: 1px solid rgba(0,0,0,0.08); border-bottom: 1px solid rgba(0,0,0,0.08); height: 56px; overflow: visible; transition: background-color 0.2s ease; }
.grid-header .cell { min-height: 44px; font-size: 11px; font-weight: 800; text-transform: uppercase; letter-spacing: 0.5px; opacity: 0.9; line-height: 1.2; }
.center { justify-content: center; text-align: center; }
.right { justify-content: flex-end; text-align: right; }
.list-text { font-size: 13px; line-height: 1.35; }

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

.hint-tooltip { position: relative; display: inline-flex; }
.hint-tooltip:hover::after { content: attr(data-title); position: absolute; bottom: calc(100% + 6px); left: 50%; transform: translateX(-50%); background: rgba(0,0,0,0.95); color: #fff; padding: 6px 10px; font-size: 11px; font-weight: 800; border-radius: 4px; white-space: nowrap; pointer-events: none; z-index: 100; text-transform: uppercase; letter-spacing: 0.5px; }
.hint-tooltip:hover::before { content: ''; position: absolute; bottom: 100%; left: 50%; transform: translateX(-50%); border-width: 5px; border-style: solid; border-color: rgba(0,0,0,0.95) transparent transparent transparent; pointer-events: none; z-index: 100; }

/* Themes & Zebras - Matches AdminMjReceivables */
.grid-surface-light .cell { background: #f5f7fa; color: rgba(0,0,0,0.9); border-color: rgba(0,0,0,0.12) !important; }
.grid-row-light .cell { border-color: rgba(0,0,0,0.08) !important; }
.zebra-light-a .cell { background: #ffffff; }
.zebra-light-b .cell { background: #f0f4f8; }
.grid-row-light:hover .cell { background: #e3f2fd !important; }
.grid-selected-light .cell { background: #e8f5e9 !important; }

.grid-surface-dark .cell {
  background: rgba(255,255,255,0.08) !important;
  color: rgba(255,255,255,0.80) !important;
  border-color: rgba(255,255,255,0.10) !important;
  backdrop-filter: none !important;
}
.grid-row-dark .cell { background: rgba(255,255,255,0.04); border-color: rgba(255,255,255,0.08) !important; color: rgba(255,255,255,0.85); }
.zebra-dark-a .cell { background: rgba(255,255,255,0.04) !important; }
.zebra-dark-b .cell { background: rgba(255,255,255,0.015) !important; }
.grid-row-dark:hover .cell { background: rgba(255,255,255,0.07) !important; }
.grid-selected-dark .cell { background: rgba(76, 175, 80, 0.2) !important; }

.hover-grey:hover { background-color: #f5f5f5 !important; }

/* FIX PARA TEXTOS CINZAS NO MODO ESCURO */
.v-theme--dark {
  .text-grey-darken-4, .text-grey-darken-3, .text-grey-darken-2, .text-grey-darken-1, .text-grey {
    color: rgba(255,255,255,0.9) !important;
  }
}

/* Actions */
.actions-inline { display: flex; align-items: center; justify-content: center; gap: 6px; width: 100%; }
.square-btn { width: 32px !important; height: 32px !important; min-width: 32px !important; padding: 0 !important; }

/* KPIs e Responsividade Abas */
.kpi-scroll-container { -webkit-overflow-scrolling: touch; }
@media (max-width: 600px) {
    .kpi-scroll-container { padding-bottom: 8px !important; }
    .kpi-card { min-width: 120px !important; padding: 8px 12px !important; }
    .kpi-bg-icon .v-icon { font-size: 40px !important; right: -5px !important; bottom: -5px !important; }
    .kpi-label { font-size: 10px !important; }
    .kpi-number-group .kpi-value { font-size: 16px !important; }
}

.kpi-card { border: 1px solid rgba(0,0,0,0.08); transition: all 0.2s ease; border-radius: 0 !important; }
.kpi-active-border { border-bottom: 3px solid currentColor; background: #fff; }
.bg-gradient-blue { background: linear-gradient(135deg, #2196F3, #1565C0); color:white; }
.bg-gradient-purple { background: linear-gradient(135deg, #9C27B0, #6A1B9A); color:white; }
.bg-gradient-cyan { background: linear-gradient(135deg, #00BCD4, #00838F); color:white; }
.bg-gradient-warning { background: linear-gradient(135deg, #FFC107, #FF8F00); color:white; }
.bg-gradient-orange { background: linear-gradient(135deg, #FF9800, #EF6C00); color:white; }
.bg-gradient-dark { background: linear-gradient(135deg, #455A64, #263238); color:white; }
.bg-gradient-green { background: linear-gradient(135deg, #4CAF50, #2E7D32); color:white; }
.bg-gradient-red { background: linear-gradient(135deg, #F44336, #B71C1C); color:white; }
.kpi-bg-icon { position: absolute; right: -10px; bottom: -10px; opacity: 0.2; transform: rotate(-15deg); }
.kpi-bg-icon .v-icon { font-size: 60px; }

/* Scrollbars */
.custom-scroll { scrollbar-width: thin; }
.custom-scroll::-webkit-scrollbar { width: 8px; height: 8px; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.35); border-radius: 6px; }
.custom-scroll-x::-webkit-scrollbar { height: 8px; }
.custom-scroll-x::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.35); border-radius: 4px; }
.custom-scroll::-webkit-scrollbar-track, .custom-scroll-x::-webkit-scrollbar-track { background: transparent; }

.pill-ref { font-size: 11px; font-weight: 900; font-family: monospace; background: rgba(0,0,0,0.06); padding: 2px 6px; border-radius: 4px; }
.chk-fixed { margin: 0 !important; padding: 0 !important; width: 24px; height: 24px; }
:deep(.v-selection-control__input) { width: 24px; height: 24px; }
:deep(.v-checkbox-btn .v-icon) { font-size: 18px !important; }

/* Floating selection bar */
.floating-actions-wrap { position: fixed; left: 0; right: 0; bottom: 18px; display: flex; justify-content: center; z-index: 9999; pointer-events: none; }
.floating-actions-card { width: min(1100px, calc(100% - 32px)); border-radius: 14px !important; overflow: hidden; pointer-events: auto; backdrop-filter: blur(10px); }
.floating-light { background: rgba(255,255,255,0.95); border: 1px solid rgba(0,0,0,0.08); }
.floating-dark { background: rgba(20,20,24,0.85); border: 1px solid rgba(255,255,255,0.12); }
.floating-btn { border-radius: 10px !important; text-transform: none !important; font-weight: 900; }

/* Fix Tooltips Contrast - Dark BG / White Text */
:global(.tooltip-contrast > .v-overlay__content) { background-color: rgba(33, 33, 33, 0.95) !important; color: #ffffff !important; font-size: 11px !important; font-weight: 700 !important; border-radius: 4px; border: 1px solid rgba(255,255,255,0.2); }

/* LOG TIMELINE */
.log-timeline { display: flex; flex-direction: column; gap: 14px; }
.log-row { display: grid; grid-template-columns: 22px 1fr; gap: 12px; padding: 12px; border: 1px solid rgba(0,0,0,0.08); }
.log-row-light { background: #fff; }
.log-row-dark { background: rgba(255,255,255,0.04); border-color: rgba(255,255,255,0.10); }

.log-mark { position: relative; display: flex; flex-direction: column; align-items: center; }
.log-dot { width: 12px; height: 12px; border-radius: 999px; border: 2px solid rgba(255,255,255,0.5); }
.log-line { width: 2px; flex: 1; margin-top: 6px; background: rgba(160,160,160,0.45); border-radius: 2px; }

.log-dot-success { background: rgba(76, 175, 80, 1); border-color: rgba(76, 175, 80, 0.25); }
.log-dot-danger { background: rgba(244, 67, 54, 1); border-color: rgba(244, 67, 54, 0.25); }
.log-dot-warn { background: rgba(255, 152, 0, 1); border-color: rgba(255, 152, 0, 0.25); }
.log-dot-teal { background: rgba(0, 150, 136, 1); border-color: rgba(0, 150, 136, 0.25); }
.log-dot-neutral { background: rgba(120,120,120,1); border-color: rgba(120,120,120,0.25); }

.log-desc { font-size: 13px; line-height: 1.35; opacity: 0.92; }

.transition-all { transition: all 0.3s cubic-bezier(0.25, 0.8, 0.25, 1); }

/* ========================================================
   HOVER NATIVO (SEM VUE) PARA NÃO TRAVAR O NAVEGADOR
   ======================================================== */
#pcp-layout-wrapper[data-highlight-tab] .kpi-card { filter: grayscale(100%) brightness(0.7); opacity: 0.4 !important; transform: scale(0.98); }

#pcp-layout-wrapper[data-highlight-tab="design"] .kpi-card[data-tab-id="design"],
#pcp-layout-wrapper[data-highlight-tab="pcp"] .kpi-card[data-tab-id="pcp"],
#pcp-layout-wrapper[data-highlight-tab="separacao"] .kpi-card[data-tab-id="separacao"],
#pcp-layout-wrapper[data-highlight-tab="impressao"] .kpi-card[data-tab-id="impressao"],
#pcp-layout-wrapper[data-highlight-tab="calandra"] .kpi-card[data-tab-id="calandra"],
#pcp-layout-wrapper[data-highlight-tab="faturamento"] .kpi-card[data-tab-id="faturamento"],
#pcp-layout-wrapper[data-highlight-tab="liberacao"] .kpi-card[data-tab-id="liberacao"] {
    filter: none;
    transform: scale(1.05);
    box-shadow: 0 0 20px currentColor !important;
    z-index: 10;
    opacity: 1 !important;
    animation: pulse-kpi 1.5s infinite;
}

@keyframes pulse-kpi {
    0% { transform: scale(1.05); }
    50% { transform: scale(1.02); filter: brightness(1.2); }
    100% { transform: scale(1.05); }
}

/* Modal de Agendamento */
.d-grid { display: grid; }
.grid-cols-7 { grid-template-columns: repeat(7, 1fr); }
.gap-1 { gap: 4px; }
.calendar-day-btn { height: 40px; display: flex; align-items: center; justify-content: center; border-radius: 8px; cursor: pointer; font-size: 13px; font-weight: bold; position: relative; transition: all 0.2s; border: 1px solid transparent; }
.light-mode-btn:hover { background: rgba(0,0,0,0.05); }
.dark-mode-btn:hover { background: rgba(255,255,255,0.05); }
.calendar-day-btn.is-selected { background: #3F51B5 !important; color: white !important; box-shadow: 0 4px 10px rgba(63, 81, 181, 0.4); }
.calendar-day-btn.is-forecast { border-color: #4CAF50; color: #2E7D32; background: rgba(76, 175, 80, 0.1); }
.calendar-day-btn.is-forecast.is-selected { background: #4CAF50 !important; color: white !important; box-shadow: 0 4px 10px rgba(76, 175, 80, 0.4); border-color: transparent; }
.forecast-icon { position: absolute; top: 4px; right: 4px; }

/* ========================================================
   OVERLAY E EFEITOS DA LOADING BAR (ANTI-TRAVAMENTO)
   ======================================================== */
.loading-overlay-container { position: absolute; inset: 0; z-index: 100; transition: opacity 0.3s ease; }
.overlay-light { background: rgba(255, 255, 255, 0.95); backdrop-filter: blur(6px); }
.overlay-dark { background: rgba(20, 20, 24, 0.95); backdrop-filter: blur(6px); }
.loading-text { font-size: 13px; animation: pulse-text 1.5s infinite; }

@keyframes pulse-text {
  0%, 100% { opacity: 0.6; text-shadow: 0 0 4px rgba(63, 81, 181, 0); }
  50% { opacity: 1; text-shadow: 0 0 10px rgba(63, 81, 181, 0.8); }
}

.progress-bar-bg { width: 280px; height: 6px; background: rgba(128, 128, 128, 0.15); border-radius: 6px; overflow: hidden; box-shadow: inset 0 1px 3px rgba(0,0,0,0.2); }
.progress-bar-fill { height: 100%; background: linear-gradient(90deg, #3F51B5, #5C6BC0); border-radius: 6px; box-shadow: 0 0 12px rgba(92, 107, 192, 0.6); position: relative; }
.progress-glow { position: absolute; top: 0; right: 0; bottom: 0; width: 20px; background: rgba(255, 255, 255, 0.8); filter: blur(4px); animation: glow-move 1s linear infinite; }

@keyframes glow-move {
  0% { transform: translateX(-20px); opacity: 0; }
  50% { opacity: 1; }
  100% { transform: translateX(10px); opacity: 0; }
}

/* ========================================================
   ANIMAÇÃO DE PARTÍCULAS
   ======================================================== */
.particles-area { position: absolute; bottom: calc(50% - 20px); width: 100%; height: 200px; pointer-events: none; z-index: 0; }
.particle-icon { position: absolute; bottom: 0; opacity: 0; animation: floatUp infinite ease-out; }

@keyframes floatUp {
  0% { transform: translate(0, 0) scale(0.3) rotate(0deg); opacity: 0; }
  20% { opacity: 0.9; }
  80% { opacity: 0.5; }
  100% { transform: translate(var(--x-dir), -140px) scale(1.6) rotate(180deg); opacity: 0; }
}

/* CONTORNO EXTERNO DA GRID */
.flex-grow-1.overflow-hidden > .v-card.flex-grow-1 { border: 1px solid rgba(0,0,0,0.12) !important; }
.bg-glass-dark .flex-grow-1.overflow-hidden > .v-card.flex-grow-1 { border: 1px solid rgba(255,255,255,0.12) !important; }

/* CABEÇALHO FIXO COM EFEITO DE ELEVAÇÃO */
.sticky-head { position: sticky; top: 0; z-index: 20; box-shadow: 0 8px 16px -4px rgba(0, 0, 0, 0.12); }
.bg-glass-dark .sticky-head { box-shadow: 0 8px 20px -4px rgba(0, 0, 0, 0.4); }
</style>
