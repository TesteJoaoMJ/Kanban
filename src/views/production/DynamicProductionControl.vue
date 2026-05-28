<template>
  <div v-if="!isSuperAdmin" class="construction-wrapper w-100 h-100 d-flex flex-column align-center justify-center position-relative overflow-hidden transition-all" :class="isLight ? 'bg-grey-lighten-4' : 'bg-grey-darken-4'">
    <div class="absolute top-0 left-0 w-100 h-100 opacity-20" style="background-image: radial-gradient(circle at center, #536DFE 0%, transparent 60%); pointer-events: none;"></div>
    <div class="bg-grid-construction absolute top-0 left-0 w-100 h-100 opacity-10" style="pointer-events: none;"></div>

    <div class="z-10 d-flex flex-column align-center text-center px-4">
      <v-avatar size="140" color="indigo-accent-2" class="elevation-10 mb-8 pulse-avatar">
        <v-icon size="72" color="white">mdi-crane</v-icon>
      </v-avatar>

      <h1 class="text-h3 font-weight-black mb-4 lh-1" :class="isLight ? 'text-grey-darken-4' : 'text-white'" style="letter-spacing: -1px;">
        Motor em Calibragem
      </h1>

      <p class="text-h6 font-weight-medium opacity-70 max-w-md mb-10" :class="isLight ? 'text-grey-darken-3' : 'text-grey-lighten-1'" style="line-height: 1.5;">
        O novo <strong>PCP Dinâmico (V2)</strong> está em fase de construção e testes restritos.<br><br>O acesso temporário é exclusivo para membros da engenharia de software (Super Administradores).
      </p>

      <v-btn size="x-large" color="indigo-accent-2" variant="flat" class="btn-3d font-weight-black px-10" prepend-icon="mdi-arrow-left" @click="router.push({ name: 'ProductionControl' })">
        Voltar ao PCP Oficial
      </v-btn>
    </div>
  </div>

  <div
    v-else
    id="dynamic-pcp-layout-wrapper"
    class="pcp-layout font-sans fill-height d-flex flex-column relative overflow-hidden transition-all"
    :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 text-grey-darken-4' : 'bg-glass-dark text-white'"
  >
    <div v-if="themeStore.currentMode !== 'light'" class="background-carousel-wrapper">
      <v-carousel cycle height="100%" hide-delimiters :show-arrows="false" interval="15000" class="fill-height">
        <v-carousel-item src="/placeholder.png" cover></v-carousel-item>
      </v-carousel>
      <div class="background-overlay"></div>
    </div>

    <div class="content-wrapper d-flex flex-column fill-height z-10 relative">

      <div
        class="header-bar px-6 py-4 d-flex align-center justify-space-between flex-shrink-0 flex-wrap gap-4"
        :class="themeStore.currentMode === 'light' ? 'bg-white border-b border-grey-lighten-2 shadow-sm' : 'bg-glass-header border-bottom-white-05'"
      >
        <div class="d-flex flex-column mb-2 mb-sm-0">
          <div class="breadcrumb text-caption">
            <span class="opacity-70">Industrial</span>
            <span class="mx-2 opacity-50">></span>
            <span class="font-weight-bold">PCP Dinâmico (V2)</span>
          </div>
          <div class="text-h5 font-weight-black tracking-tight leading-none mt-1 text-uppercase d-flex align-center gap-2" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">
            Motor de Produção
            <v-chip size="small" color="success" variant="flat" class="font-weight-bold chip-3d text-white ml-2">
               <v-icon start size="16">mdi-engine</v-icon> Blueprint: {{ activeWorkflow?.name || 'Carregando...' }}
            </v-chip>
          </div>
        </div>

        <div class="d-flex align-center flex-wrap gap-4">
          <v-btn-toggle
            v-model="viewMode"
            mandatory
            density="compact"
            variant="outlined"
            class="btn-group-rect rounded-lg btn-3d"
            divided
            :color="themeStore.currentMode === 'light' ? 'indigo-darken-2' : 'white'"
          >
            <v-btn value="list" class="px-4 font-weight-bold text-caption text-uppercase"><v-icon start size="small">mdi-format-list-bulleted</v-icon> Lista</v-btn>
            <v-btn value="kanban" class="px-4 font-weight-bold text-caption text-uppercase"><v-icon start size="small">mdi-view-week</v-icon> Kanban</v-btn>
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
        </div>
      </div>

      <v-slide-y-transition>
         <div v-if="viewMode !== 'kanban'" class="px-6 pt-4 pb-2 flex-shrink-0">
           <div class="d-flex align-center flex-nowrap w-100 overflow-x-auto pb-3 custom-scroll-x kpi-scroll-container" style="gap: 12px;">
             <template v-for="(stage, idx) in orderedStages" :key="stage.id">
               <v-card
                 class="kpi-card kpi-rect hover-elevate py-3 px-4 cursor-pointer position-relative transition-all"
                 :class="[activeStageId === stage.id ? 'kpi-active-border elevation-6' : 'elevation-3 opacity-90']"
                 :style="{
                    background: getKpiGradient(stage.color),
                    color: 'white',
                    borderBottomColor: activeStageId === stage.id ? '#fff' : 'transparent',
                    borderWidth: activeStageId === stage.id ? '0 0 4px 0' : '0'
                 }"
                 v-ripple
                 @click="activeStageId = stage.id"
                 style="min-width: 160px; flex: 1 1 0; overflow: hidden;"
               >
                 <div class="kpi-bg-icon text-white"><v-icon>{{ (stage.data as any).icon || 'mdi-view-column' }}</v-icon></div>
                 <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                   <div class="d-flex align-center text-truncate" style="gap: 6px;">
                     <v-icon size="18" color="white" class="opacity-80">{{ (stage.data as any).icon || 'mdi-view-column' }}</v-icon>
                     <span class="kpi-label text-truncate font-weight-black text-uppercase text-white">{{ (stage.data as any).title || stage.data.name }}</span>
                   </div>
                   <div class="kpi-number-group my-1">
                     <span class="text-body-2 font-weight-medium mr-1 text-white opacity-80">Qtd:</span>
                     <span class="kpi-value text-white">{{ getItemsForStage(stage).length }}</span>
                   </div>
                   <div class="kpi-footer mt-1 text-truncate text-[10px] text-white opacity-80">{{ getMetersForStage(stage) }}m Total</div>
                 </div>
               </v-card>
               <v-icon v-if="idx < orderedStages.length - 1" size="20" class="opacity-40 flex-shrink-0" :color="themeStore.currentMode === 'light' ? 'grey-darken-2' : 'white'">mdi-chevron-right</v-icon>
             </template>
           </div>
         </div>
      </v-slide-y-transition>

      <div class="px-6 pt-2 pb-2 flex-shrink-0">
        <div class="controls-bar d-flex flex-column" :class="themeStore.currentMode === 'light' ? 'controls-light' : 'controls-dark'">
          <div class="d-flex align-center justify-space-between flex-wrap" style="gap: 10px;">
            <div class="search-wrap d-flex align-center flex-grow-1" :class="themeStore.currentMode === 'light' ? 'search-light' : 'search-dark'">
              <v-icon :color="themeStore.currentMode === 'light' ? 'grey-darken-1' : 'white-70'">mdi-magnify</v-icon>
              <input v-model="searchQuery" type="text" placeholder="BUSCAR OP, REF OU CLIENTE NO MOTOR..." class="clean-input flex-grow-1 text-uppercase font-weight-bold" />
              <v-btn v-if="searchQuery" icon="mdi-close-circle" size="x-small" variant="text" @click="searchQuery = ''" class="opacity-50"></v-btn>
            </div>

            <div class="hint-tooltip" data-title="Atualizar Conexão SQL">
              <v-btn variant="flat" class="btn-3d" height="40" color="indigo" @click="fetchProductionItems" icon rounded="0" :loading="isLoading">
                <v-icon>mdi-refresh</v-icon>
              </v-btn>
            </div>
          </div>
        </div>
      </div>

      <div class="flex-grow-1 px-6 pb-0 overflow-hidden d-flex flex-column position-relative">

        <div v-if="isLoading" class="d-flex flex-column justify-center align-center h-100">
           <v-progress-circular indeterminate color="indigo" size="64" width="4"></v-progress-circular>
           <span class="mt-4 font-weight-bold text-uppercase opacity-70">Sincronizando Grafo Lógico...</span>
        </div>

        <v-fade-transition mode="out-in" v-else>

          <div v-if="viewMode === 'kanban'" class="flex-grow-1 overflow-x-auto custom-scroll-x d-flex gap-4 h-100 pb-4">
            <div
              v-for="stage in orderedStages"
              :key="'kb-'+stage.id"
              class="kanban-column d-flex flex-column h-100 rounded-lg overflow-hidden border shadow-sm flex-shrink-0"
              :class="themeStore.currentMode === 'light' ? 'border-grey-lighten-2 bg-grey-lighten-4' : 'border-white-05 bg-grey-darken-4'"
              style="min-width: 350px; width: 350px; max-height: 100%;"
            >
              <div class="pa-4 shadow-sm z-10 text-white position-relative overflow-hidden flex-shrink-0" :style="{ background: getKpiGradient(stage.color) }">
                <div class="d-flex justify-space-between align-start z-10 position-relative w-100">
                   <div class="d-flex flex-column">
                      <div class="d-flex align-center gap-2 mb-1">
                        <v-icon size="18" color="white">{{ (stage.data as any).icon || 'mdi-view-column' }}</v-icon>
                        <span class="font-weight-black text-uppercase text-subtitle-1 lh-1">{{ (stage.data as any).title || stage.data.name }}</span>
                      </div>
                      <div class="text-[11px] opacity-80 font-weight-medium">{{ getItemsForStage(stage).length }} itens na fila</div>
                   </div>
                   <v-chip size="x-small" label class="font-weight-black chip-3d bg-white text-black" rounded="0">{{ getMetersForStage(stage) }}m</v-chip>
                </div>
                <v-icon size="80" class="absolute opacity-20" style="right: -10px; bottom: -10px; transform: rotate(-15deg); pointer-events: none;">{{ (stage.data as any).icon || 'mdi-view-column' }}</v-icon>
              </div>

              <div class="flex-grow-1 overflow-y-auto custom-scroll pa-3 d-flex flex-column gap-3" :data-stage-id="stage.id">
                <draggable
                  v-model="itemsByStage[stage.id]"
                  group="motor-kanban"
                  item-key="id"
                  :disabled="!canOperateStage(stage)"
                  :move="checkMove"
                  ghost-class="ghost-card"
                  drag-class="drag-card"
                  class="min-h-100 d-flex flex-column gap-3 pb-6"
                  @end="onKanbanDragEnd"
                >
                  <template #item="{ element: card }">
                    <v-card
                      class="kanban-card border-thin rounded-lg hover-elevate transition-all"
                      :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-grey-darken-3'"
                      elevation="2"
                      :style="{ borderLeft: `6px solid ${stage.color} !important` }"
                    >
                      <div class="px-3 py-2 d-flex align-center justify-space-between gap-2">
                        <div class="d-flex flex-column overflow-hidden">
                          <div class="d-flex gap-2 align-center mb-1">
                             <v-chip size="x-small" label class="font-weight-black chip-3d text-white" :color="stage.color" rounded="sm">OP #{{ card.order_number }}</v-chip>
                          </div>
                          <div class="text-caption font-weight-black text-uppercase text-truncate" style="max-width: 190px;">{{ card.customer_name }}</div>
                          <div class="text-[11px] opacity-75 text-truncate font-weight-bold" style="max-width: 190px;">{{ card.stamp_ref || 'S/ REF' }} • {{ card.fabric_type || '-' }}</div>
                        </div>
                        <div class="d-flex flex-column align-end flex-shrink-0">
                          <div class="text-subtitle-2 font-weight-black">{{ card.quantity_meters }}m</div>
                          <div class="text-[10px] opacity-70 font-mono">{{ formatDateShort(card.created_at) }}</div>
                        </div>
                      </div>

                      <div class="px-3 pb-2 d-flex align-center justify-space-between gap-2 border-t pt-2 mt-1" :class="themeStore.currentMode === 'light' ? 'border-grey-lighten-4' : 'border-grey-darken-2'">
                        <div class="d-flex align-center gap-2">
                          <div class="hint-tooltip" data-title="Ver Arte">
                              <div class="icon-3d-wrapper cursor-pointer" @click="openImage(card)">
                                  <v-icon size="16" class="icon-3d" :color="stage.color">mdi-tshirt-crew</v-icon>
                                  <div class="icon-3d-shine"></div>
                              </div>
                          </div>
                          <v-chip size="x-small" label rounded="sm" variant="flat" class="font-weight-bold chip-3d text-white text-uppercase" :color="getDynamicStatusConfig(card.status, stage).color">
                            {{ getDynamicStatusConfig(card.status, stage).label }}
                          </v-chip>
                        </div>

                        <div class="d-flex align-center gap-1">
                           <div class="hint-tooltip" data-title="Histórico / Logs">
                              <v-btn class="square-btn btn-3d" variant="tonal" color="blue-grey" @click.stop="openLogs(card)">
                                 <v-icon size="16">mdi-history</v-icon>
                              </v-btn>
                           </div>

                           <div v-for="action in getAvailableActionsForItem(card, stage)" :key="action.id" class="hint-tooltip" :data-title="action.label">
                               <v-btn class="square-btn btn-3d text-white" variant="flat" :color="action.color" @click.stop="executeAction(action, card, stage)" :loading="processingItemId === card.id">
                                  <v-icon size="18">{{ action.icon }}</v-icon>
                               </v-btn>
                           </div>
                        </div>
                      </div>
                    </v-card>
                  </template>
                </draggable>

                <div v-if="getItemsForStage(stage).length === 0" class="h-100 d-flex flex-column align-center justify-center opacity-40 border-2 border-dashed rounded-lg" :class="themeStore.currentMode === 'light' ? 'border-grey-lighten-2' : 'border-grey-darken-2'">
                  <v-icon size="36" class="mb-2">mdi-inbox-arrow-down-outline</v-icon>
                  <div class="text-caption font-weight-bold text-uppercase">Aba Vazia</div>
                </div>
              </div>
            </div>
          </div>

          <v-card
            v-else-if="viewMode === 'list'"
            class="flex-grow-1 d-flex flex-column rounded-0 border-thin overflow-hidden position-relative"
            :class="themeStore.currentMode === 'light' ? 'bg-white shadow-sm' : 'glass-card border-white-05'"
            :elevation="0"
          >
            <div class="grid-scroll flex-grow-1 overflow-auto custom-scroll position-relative">
              <div class="grid-header sticky-head border-b" :class="[themeStore.currentMode === 'light' ? 'grid-surface-light border-grey-lighten-2' : 'grid-surface-dark border-grey-darken-2', 'grid-dynamic']">
                  <div class="cell center header-text border-r">
                      <v-checkbox-btn :model-value="isAllPageSelected" @update:modelValue="toggleSelectAllPage" density="compact" class="chk-fixed"></v-checkbox-btn>
                  </div>
                  <div class="cell center header-text border-r">Arte</div>
                  <div class="cell header-text border-r">Referência / Tecido</div>
                  <div class="cell header-text border-r">Cliente / OP</div>
                  <div class="cell center header-text border-r">Entrada</div>
                  <div class="cell center header-text border-r">Qtd (m)</div>
                  <div class="cell center header-text border-r">Status Analítico</div>
                  <div class="cell center header-text">Ações Definidas</div>
              </div>

              <div v-if="getItemsForStage(activeStageObj).length === 0" class="d-flex flex-column justify-center align-center h-100 opacity-60 gap-2 py-10" style="min-width: 1200px;">
                <v-icon size="48" color="grey-lighten-1">mdi-clipboard-text-off-outline</v-icon>
                <span class="text-body-1 font-weight-medium text-grey">Nenhum registro nesta aba</span>
              </div>

              <template v-else>
                <div
                    v-for="(item, index) in paginatedListItems"
                    :key="item.id"
                    class="grid-row border-b"
                    :class="[zebraClass(index), 'grid-dynamic', themeStore.currentMode === 'light' ? 'grid-row-light' : 'grid-row-dark', selectedIds.has(item.id) ? (themeStore.currentMode === 'light' ? 'grid-selected-light' : 'grid-selected-dark') : '']"
                >
                    <div class="cell center border-r border-inherit">
                        <v-checkbox-btn :model-value="selectedIds.has(item.id)" @update:modelValue="val => toggleSelect(item.id, val)" density="compact" class="chk-fixed" @click.stop></v-checkbox-btn>
                    </div>

                    <div class="cell center border-r border-inherit pa-1">
                        <div class="hint-tooltip" data-title="Ver Arte">
                            <div class="icon-3d-wrapper cursor-pointer" @click="openImage(item)">
                                <v-icon size="20" class="icon-3d" :color="activeStageObj?.color || 'indigo'">mdi-tshirt-crew</v-icon>
                                <div class="icon-3d-shine"></div>
                            </div>
                        </div>
                    </div>

                    <div class="cell border-r border-inherit">
                        <div class="d-flex flex-column">
                            <span class="list-text font-weight-black text-uppercase text-truncate">{{ item.stamp_ref || 'SEM REF' }}</span>
                            <span class="text-caption opacity-70">{{ item.fabric_type || '-' }}</span>
                        </div>
                    </div>

                    <div class="cell border-r border-inherit">
                        <div class="d-flex flex-column">
                            <span class="list-text font-weight-bold text-truncate" :title="item.customer_name">{{ item.customer_name }}</span>
                            <span class="text-caption opacity-70 font-weight-bold" :style="{ color: activeStageObj?.color }">OP #{{ item.order_number }}</span>
                        </div>
                    </div>

                    <div class="cell center border-r border-inherit"><span class="list-text font-mono opacity-80">{{ formatDateShort(item.created_at) }}</span></div>
                    <div class="cell center border-r border-inherit"><span class="list-text font-mono font-weight-black">{{ item.quantity_meters }}m</span></div>

                    <div class="cell center border-r border-inherit">
                        <v-chip size="x-small" variant="flat" class="font-weight-bold text-uppercase w-100 justify-center chip-3d text-white" :color="getDynamicStatusConfig(item.status, activeStageObj).color">
                            {{ getDynamicStatusConfig(item.status, activeStageObj).label }}
                        </v-chip>
                    </div>

                    <div class="cell center">
                         <div class="actions-inline d-flex gap-2 justify-center w-100">
                             <div class="hint-tooltip" data-title="Auditoria (Histórico de Logs)">
                                 <v-btn class="square-btn btn-3d" variant="tonal" color="blue-grey" @click.stop="openLogs(item)">
                                     <v-icon size="16">mdi-history</v-icon>
                                 </v-btn>
                             </div>

                             <div v-for="action in getAvailableActionsForItem(item, activeStageObj!)" :key="action.id" class="hint-tooltip" :data-title="action.label">
                                 <v-btn class="square-btn btn-3d text-white" variant="flat" :color="action.color" @click.stop="executeAction(action, item, activeStageObj!)" :loading="processingItemId === item.id">
                                    <v-icon size="18">{{ action.icon }}</v-icon>
                                 </v-btn>
                             </div>
                         </div>
                    </div>
                </div>
              </template>
            </div>

            <div class="flex-shrink-0 border-t px-4 py-2 d-flex align-center justify-space-between gap-2" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5' : 'bg-white-05'">
              <div class="text-caption opacity-80 font-weight-bold text-uppercase">
                Total na Aba: <strong>{{ getItemsForStage(activeStageObj).length }}</strong> registros
              </div>
              <v-pagination
                v-if="viewMode === 'list' && getItemsForStage(activeStageObj).length > 0"
                v-model="listPage"
                :length="Math.max(1, Math.ceil(getItemsForStage(activeStageObj).length / itemsPerPage))"
                density="compact"
                active-color="indigo-darken-3"
                total-visible="7"
                variant="tonal"
                size="small"
              ></v-pagination>
            </div>
          </v-card>
        </v-fade-transition>

        <v-slide-y-transition>
          <div v-if="selectedIds.size > 0 && viewMode !== 'kanban'" class="floating-actions-wrap">
            <v-card class="floating-actions-card shadow-lg" :class="themeStore.currentMode === 'light' ? 'floating-light' : 'floating-dark'" elevation="12">
              <div class="d-flex align-center justify-space-between px-5 py-3 gap-4">
                <div class="d-flex align-center gap-3">
                  <v-icon :color="activeStageObj?.color || 'indigo'" size="28">mdi-checkbox-multiple-marked-circle</v-icon>
                  <div class="d-flex flex-column">
                    <span class="text-subtitle-2 font-weight-black text-uppercase lh-1">{{ selectedIds.size }} itens selecionados</span>
                    <span class="text-[11px] opacity-75">Interseção Lógica de Lote Avaliada</span>
                  </div>
                </div>

                <div class="d-flex align-center gap-2">
                  <template v-if="batchAvailableActions.length > 0">
                     <v-btn
                        v-for="btn in batchAvailableActions" :key="btn.id"
                        size="small" variant="flat" class="btn-3d floating-btn text-white font-weight-bold px-4"
                        :color="btn.color"
                        @click="executeBatchAction(btn)"
                        :loading="isProcessingEngine"
                     >
                        <v-icon start size="16">{{ btn.icon }}</v-icon> {{ btn.label }} (Lote)
                     </v-btn>
                  </template>
                  <template v-else>
                     <span class="text-caption text-error font-weight-bold mr-4">Conflito de status ou lote desabilitado.</span>
                  </template>

                  <v-divider vertical class="mx-2 opacity-30"></v-divider>
                  <v-btn size="small" variant="text" class="font-weight-bold" @click="selectedIds.clear()">Limpar</v-btn>
                </div>
              </div>
            </v-card>
          </div>
        </v-slide-y-transition>

      </div>
    </div>

    <v-dialog v-model="formModal.show" max-width="500" persistent>
      <v-card class="rounded-xl overflow-hidden shadow-lg border" :class="themeStore.currentMode === 'light' ? 'bg-white border-grey-lighten-2' : 'bg-grey-darken-4 border-grey-darken-2'">
        <div v-if="formModal.node" class="px-5 py-4 text-white d-flex align-center justify-space-between" :style="{ backgroundColor: formModal.node.color || '#9C27B0' }">
          <div class="d-flex align-center gap-2">
             <v-icon size="24">{{ getNodeIcon('FORM') }}</v-icon>
             <span class="font-weight-black text-uppercase text-subtitle-1">{{ formModal.node.data.name || 'Ação Exigida' }}</span>
          </div>
          <v-btn icon="mdi-close" variant="text" density="compact" color="white" @click="closeFormModal"></v-btn>
        </div>

        <div class="pa-5">
           <p v-if="formModal.node?.data.description" class="text-caption mb-4 opacity-80">{{ formModal.node.data.description }}</p>
           <v-alert v-if="formModal.isBatch" color="warning" variant="tonal" class="mb-4 text-caption" density="compact">O preenchimento se aplicará a todos os {{ formModal.batchItems.length }} itens do lote.</v-alert>

           <v-form ref="dynamicFormRef" @submit.prevent="submitDynamicForm">
              <div v-for="field in (formModal.node?.data as any)?.fields || []" :key="field.name" class="mb-4">
                 <template v-if="['select', 'multiselect'].includes(field.type)">
                    <v-autocomplete v-model="formModal.payload[field.name]" :items="formModal.dropdownOptions[field.name] || []" item-title="label" item-value="value" :label="field.label" :multiple="field.type === 'multiselect'" :rules="field.isRequired ? [v => !!v || 'Obrigatório'] : []" variant="outlined" density="comfortable" :base-color="themeStore.currentMode === 'light' ? 'grey' : 'grey-darken-1'" :color="formModal.node?.color"></v-autocomplete>
                 </template>
                 <template v-else-if="field.type === 'textarea'">
                    <v-textarea v-model="formModal.payload[field.name]" :label="field.label" :rules="field.isRequired ? [v => !!v || 'Obrigatório'] : []" variant="outlined" density="comfortable" rows="3" :base-color="themeStore.currentMode === 'light' ? 'grey' : 'grey-darken-1'" :color="formModal.node?.color"></v-textarea>
                 </template>
                 <template v-else-if="field.type === 'file'">
                    <v-file-input v-model="formModal.payload[field.name]" :label="field.label" prepend-icon="mdi-camera" variant="outlined" density="comfortable" :base-color="themeStore.currentMode === 'light' ? 'grey' : 'grey-darken-1'" :color="formModal.node?.color" :rules="field.isRequired ? [v => !!v || 'Anexo obrigatório'] : []"></v-file-input>
                 </template>
                 <template v-else>
                    <v-text-field v-model="formModal.payload[field.name]" :label="field.label" :type="field.type" :rules="field.isRequired ? [v => !!v || 'Obrigatório'] : []" variant="outlined" density="comfortable" :base-color="themeStore.currentMode === 'light' ? 'grey' : 'grey-darken-1'" :color="formModal.node?.color"></v-text-field>
                 </template>
              </div>
           </v-form>
        </div>

        <div class="pa-4 border-t d-flex justify-end gap-2" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-grey-darken-3 border-grey-darken-2'">
          <v-btn variant="outlined" class="font-weight-bold" @click="closeFormModal" :color="themeStore.currentMode === 'light' ? 'grey-darken-3' : 'white'">Cancelar</v-btn>
          <v-btn variant="flat" class="font-weight-bold text-white btn-3d" :color="formModal.node?.color || 'purple'" @click="submitDynamicForm" :loading="isProcessingEngine">
            Confirmar Operação
          </v-btn>
        </div>
      </v-card>
    </v-dialog>

    <v-dialog v-model="reworkModal.show" max-width="500" persistent>
      <v-card class="rounded-xl overflow-hidden shadow-lg border border-red-darken-2" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-grey-darken-4'">
        <div v-if="reworkModal.node" class="px-5 py-4 text-white d-flex align-center justify-space-between bg-red-darken-3">
          <div class="d-flex align-center gap-2">
             <v-icon size="24">mdi-alert-octagon</v-icon>
             <span class="font-weight-black text-uppercase text-subtitle-1">{{ reworkModal.node.data.name || 'Reportar Falha' }}</span>
          </div>
          <v-btn icon="mdi-close" variant="text" density="compact" color="white" @click="closeReworkModal"></v-btn>
        </div>

        <div class="pa-5">
           <v-alert color="red-lighten-4" class="text-caption mb-4 text-red-darken-4 border-red" border="start" density="compact">ATENÇÃO: O item retornará para a etapa anterior configurada no motor.</v-alert>
           <v-alert v-if="reworkModal.isBatch" color="warning" variant="tonal" class="mb-4 text-caption" density="compact">Ação em lote ativada. Devolvendo {{ reworkModal.batchItems.length }} itens.</v-alert>

           <v-form ref="reworkFormRef" @submit.prevent="submitRework">
              <v-textarea v-if="(reworkModal.node?.data as any)?.requireJustification" v-model="reworkModal.payload.justification" label="Motivo da Devolução/Defeito" :rules="[v => !!v || 'Justificativa é obrigatória']" variant="outlined" density="comfortable" rows="3" color="red" class="mb-3"></v-textarea>
              <v-file-input v-if="(reworkModal.node?.data as any)?.requireAttachment && !reworkModal.isBatch" v-model="reworkModal.payload.attachment" label="Anexar Foto da Falha" :rules="[v => !!v || 'Foto é obrigatória']" variant="outlined" density="comfortable" prepend-icon="mdi-camera-outline" color="red" accept="image/*"></v-file-input>
           </v-form>
        </div>

        <div class="pa-4 border-t border-red-darken-4 d-flex justify-end gap-2 bg-red-lighten-5" :class="themeStore.currentMode === 'light' ? '' : 'bg-red-darken-4'">
          <v-btn variant="outlined" class="font-weight-bold" @click="closeReworkModal" color="red-darken-3">Cancelar</v-btn>
          <v-btn variant="flat" class="font-weight-bold text-white btn-3d bg-red-darken-3" @click="submitRework" :loading="isProcessingEngine">Confirmar Retorno</v-btn>
        </div>
      </v-card>
    </v-dialog>

    <v-dialog v-model="logModal.show" max-width="800" scrollable>
      <v-card class="rounded-xl shadow-lg border" :class="themeStore.currentMode === 'light' ? 'bg-white border-grey-lighten-2' : 'bg-grey-darken-4 border-grey-darken-2'">
        <div class="px-5 py-4 font-weight-black d-flex align-center justify-space-between border-b" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-4 border-grey-lighten-2' : 'bg-grey-darken-3 border-grey-darken-2'">
          <div class="d-flex align-center gap-3">
            <v-avatar color="blue-grey" class="elevation-2 text-white"><v-icon>mdi-timeline-text-outline</v-icon></v-avatar>
            <div class="d-flex flex-column">
              <span class="text-uppercase text-subtitle-1 font-weight-black lh-1">Auditoria (Timeline do Motor)</span>
              <span class="text-caption opacity-70">Ref: {{ logModal.item?.stamp_ref || 'S/N' }} • OP #{{ logModal.item?.order_number }}</span>
            </div>
          </div>
          <v-btn icon="mdi-close" variant="text" density="compact" @click="logModal.show = false"></v-btn>
        </div>

        <v-card-text class="pa-0 custom-scroll" style="max-height: 60vh;">
          <div class="pa-6">
            <div v-if="logModal.loading" class="text-center py-10"><v-progress-circular indeterminate color="blue-grey"></v-progress-circular></div>
            <div v-else-if="logModal.logs.length === 0" class="text-center opacity-50 py-10"><v-icon size="48" class="mb-3">mdi-database-eye-off-outline</v-icon><div class="font-weight-bold">O Motor ainda não processou eventos para este item.</div></div>
            <div v-else class="log-timeline">
              <div v-for="(log, idx) in logModal.logs" :key="log.id" class="log-row rounded-lg border" :class="themeStore.currentMode === 'light' ? 'bg-white border-grey-lighten-2 shadow-sm' : 'bg-grey-darken-3 border-grey-darken-2'">
                <div class="log-mark pt-2"><div class="log-dot bg-blue-grey border-white"></div><div v-if="idx < logModal.logs.length - 1" class="log-line"></div></div>

                <div class="log-content py-2 px-3">
                  <div class="d-flex align-start justify-space-between flex-wrap gap-2">
                    <div class="d-flex align-center gap-2 flex-wrap">
                        <v-chip size="small" label class="font-weight-black chip-3d text-white text-uppercase" :color="log.metadata?.is_rework ? 'red-darken-2' : (log.action === 'BATCH_STATUS_CHANGE' ? 'deep-purple-darken-2' : (log.action === 'STATUS_CHANGE' ? 'blue-grey-darken-2' : 'purple'))">
                        {{ log.metadata?.is_rework ? 'REJEIÇÃO/FALHA' : (log.action === 'BATCH_STATUS_CHANGE' ? 'AVANÇO LOTE' : (log.action === 'STATUS_CHANGE' ? 'AVANÇO ITEM' : 'EVENTO')) }}
                        </v-chip>
                        <v-chip v-if="log.metadata?.batch_size" size="small" label class="font-weight-bold border" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-4' : 'bg-grey-darken-4'">
                        Lote: {{ log.metadata.batch_size }} itens
                        </v-chip>
                    </div>
                    <div class="text-caption font-mono font-weight-bold opacity-75"><v-icon size="14" class="mr-1">mdi-clock-outline</v-icon>{{ format(new Date(log.created_at), 'dd/MM/yy HH:mm:ss') }}</div>
                  </div>

                  <div class="mt-3 text-body-2 font-weight-bold">{{ log.metadata?.description || 'Ação registrada pelo motor.' }}</div>

                  <div v-if="log.metadata?.justification" class="mt-2 text-caption text-error font-weight-bold p-2 border rounded" style="background: rgba(244,67,54,0.1);">
                     Motivo / Defeito: {{ log.metadata.justification }}
                  </div>

                  <div v-if="log.metadata?.attachment_url" class="mt-2">
                     <a :href="log.metadata.attachment_url" target="_blank" class="text-blue-darken-2 font-weight-bold text-caption d-flex align-center" style="text-decoration: none;">
                        <v-icon size="16" class="mr-1">mdi-paperclip</v-icon> Ver Anexo de Falha (Imagem)
                     </a>
                  </div>

                  <div class="mt-3 d-flex align-center gap-2 flex-wrap">
                      <div v-if="log.metadata?.old_status && log.metadata?.new_status" class="text-[10px] opacity-80 font-mono bg-black-05 px-2 py-1 rounded d-inline-block border">
                        {{ log.metadata.old_status }} <v-icon size="10">mdi-arrow-right</v-icon> {{ log.metadata.new_status }}
                      </div>
                      <div class="text-[10px] opacity-70 font-mono text-uppercase bg-black-05 px-2 py-1 rounded border">
                        <v-icon size="10" class="mr-1">mdi-account</v-icon> {{ log.user?.full_name || 'SISTEMA' }}
                      </div>
                  </div>

                  <div v-if="Object.keys(log.metadata?.form_data || {}).length > 0" class="mt-3 pt-2 border-t text-[11px] font-mono opacity-80">
                     <strong>Dados Informados no Formulário:</strong><br>
                     <span v-for="(val, key) in log.metadata.form_data" :key="key" class="d-block mt-1">- {{ key }}: {{ val }}</span>
                  </div>

                </div>
              </div>
            </div>
          </div>
        </v-card-text>
      </v-card>
    </v-dialog>

    <ImageModal :show="imageModal.show" :image-url="imageModal.url" :file-name="imageModal.name" @close="imageModal.show = false" />

  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted, watch } from 'vue';
import { format } from 'date-fns';
import draggable from 'vuedraggable';
import { supabase } from '@/api/supabase';
import { useDynamicPcpStore } from '@/stores/dynamicPcpStore';
import { useThemeStore } from '@/stores/theme';
import { useUserStore } from '@/stores/user';
import { useAppStore } from '@/stores/app';
import { useRouter } from 'vue-router';
import type { WorkflowNode, StageNodeData } from '@/types/dynamicPcp';
import { v4 as uuidv4 } from 'uuid';
import ImageModal from '@/components/ImageModal.vue';
import { useProductionStore } from '@/stores/production';

const router = useRouter();
const store = useDynamicPcpStore();
const legacyStore = useProductionStore();
const themeStore = useThemeStore();
const userStore = useUserStore();
const appStore = useAppStore();

const dynamicFormRef = ref<any>(null);
const reworkFormRef = ref<any>(null);

const isSuperAdmin = computed(() => userStore.profile?.role === 'super_admin' || userStore.role === 'super_admin');
const isLight = computed(() => themeStore.currentMode === 'light');
const isLoading = ref(true);
const isProcessingEngine = ref(false);
const processingItemId = ref<string | null>(null);
const searchQuery = ref('');
const viewMode = ref('list');

const listPage = ref(1);
const itemsPerPage = 30;

const activeWorkflow = computed(() => store.activeWorkflow);
const items = ref<any[]>([]);
const itemsByStage = ref<Record<string, any[]>>({});

const activeStageId = ref<string | null>(null);
const activeStageObj = computed(() => orderedStages.value.find(s => s.id === activeStageId.value) || null);

watch(activeStageId, () => { listPage.value = 1; });

const selectedIds = ref(new Set<string>());
const toggleSelect = (id: string, val: boolean) => { if(val) selectedIds.value.add(id); else selectedIds.value.delete(id); };

const paginatedListItems = computed(() => {
   const list = getItemsForStage(activeStageObj.value);
   const start = (listPage.value - 1) * itemsPerPage;
   return list.slice(start, start + itemsPerPage);
});

const isAllPageSelected = computed(() => {
   return paginatedListItems.value.length > 0 && paginatedListItems.value.every((i:any) => selectedIds.value.has(i.id));
});
const toggleSelectAllPage = (val: boolean) => {
   paginatedListItems.value.forEach((i:any) => toggleSelect(i.id, val));
};

const selectedRows = computed(() => items.value.filter(i => selectedIds.value.has(i.id)));
const batchAvailableActions = computed(() => {
    if (selectedRows.value.length === 0) return [];
    const firstItem = selectedRows.value[0];
    const allSameStatus = selectedRows.value.every(i => i.status === firstItem.status);
    if (!allSameStatus) return [];

    const stage = orderedStages.value.find(s => s.id === activeStageId.value);
    if (!stage) return [];

    const actions = getAvailableActionsForItem(firstItem, stage);
    return actions.filter(a => {
        if (a.type === 'STEP' || a.type === 'TRANSFER') return (a.node.data as any).allowBatch === true;
        return true;
    });
});

onMounted(async () => {
  if (!isSuperAdmin.value) return;

  isLoading.value = true;
  await store.fetchWorkflows();
  if (activeWorkflow.value) {
    if (orderedStages.value.length > 0) activeStageId.value = orderedStages.value[0].id;
    initializeColumns();
    await fetchProductionItems();
  }
  isLoading.value = false;
});

const initializeColumns = () => { itemsByStage.value = {}; orderedStages.value.forEach(stage => { itemsByStage.value[stage.id] = []; }); };

const fetchProductionItems = async () => {
  if (!activeWorkflow.value) return;
  isLoading.value = true;
  try {
    const sourceNode = activeWorkflow.value.nodes.find(n => n.type === 'SOURCE');
    const tableName = sourceNode ? (sourceNode.data as any).tableName : 'order_items';

    if (tableName === 'order_items') {
        await legacyStore.fetchManagementItems();
        items.value = (legacyStore.managementList || []).map((d: any) => ({
            ...d,
            order_number: d.order_number || d.order?.order_number,
            customer_name: d.customer_name || d.order?.customer_name
        }));
    } else {
        const { data, error } = await supabase
            .from(tableName)
            .select(`*, orders!inner(order_number, customer_name, status)`)
            .not('status', 'in', '("delivered","completed","canceled")')
            .not('orders.status', 'in', '("delivered","completed","canceled")')
            .order('created_at', { ascending: false });
        if (error) throw error;
        items.value = data || [];
    }

    distributeItemsToColumns();
  } catch (e: any) { appStore.showSnackbar('Erro ao buscar itens: ' + e.message, 'error'); } finally { isLoading.value = false; }
};

const orderedStages = computed(() => {
  if (!activeWorkflow.value) return [];
  const stages = activeWorkflow.value.nodes.filter(n => n.type === 'STAGE' && !n.parentId);
  return stages.sort((a, b) => ((a.data as StageNodeData).order || 0) - ((b.data as StageNodeData).order || 0));
});

const distributeItemsToColumns = () => {
  initializeColumns();
  const filtered = items.value.filter(item => {
    if (!searchQuery.value) return true;
    const q = searchQuery.value.toLowerCase();
    return String(item.order_number).includes(q) || String(item.stamp_ref).toLowerCase().includes(q) || String(item.customer_name).toLowerCase().includes(q);
  });

  orderedStages.value.forEach(stage => {
    const mapped = (stage.data as any).mappedStatuses || [];

    const childEntries = activeWorkflow.value!.nodes.filter(n => n.parentId === stage.id && n.type === 'ENTRY');
    const entryStatuses = childEntries.map(n => (n.data as any).dbStatus).filter(Boolean);

    const childSteps = activeWorkflow.value!.nodes.filter(n => n.parentId === stage.id && n.type === 'STEP');
    const stepStatuses = childSteps.map(n => (n.data as any).dbStatus).filter(Boolean);

    const childDecisions = activeWorkflow.value!.nodes.filter(n => n.parentId === stage.id && n.type === 'DECISION' && (n.data as any).mode === 'manual');
    const decisionStatuses = childDecisions.map(n => (n.data as any).triggerStatus).filter(Boolean);

    const validStatuses = [...mapped, ...entryStatuses, ...stepStatuses, ...decisionStatuses].filter(Boolean);

    itemsByStage.value[stage.id] = filtered.filter(item => validStatuses.includes(item.status));
  });
};

watch(searchQuery, () => { distributeItemsToColumns(); listPage.value = 1; });

const getItemsForStage = (stage: WorkflowNode | null) => stage ? (itemsByStage.value[stage.id] || []) : [];

const getMetersForStage = (stage: WorkflowNode | null) => {
    const total = getItemsForStage(stage).reduce((acc, curr) => acc + Number(curr.quantity_meters || 0), 0);
    return total.toLocaleString('pt-BR', { minimumFractionDigits: 0, maximumFractionDigits: 2 });
};

const formatDateShort = (d: string) => d ? format(new Date(d), 'dd/MM/yy') : '';
const zebraClass = (i:number) => (themeStore.currentMode==='light' ? (i%2===0 ? 'zebra-light-a':'zebra-light-b') : (i%2===0 ? 'zebra-dark-a':'zebra-dark-b'));

const darkenColor = (color: string, amount: number) => {
    let colorValue = color;
    if (colorValue.startsWith('#')) colorValue = colorValue.slice(1);
    let num = parseInt(colorValue, 16);
    let r = (num >> 16) - amount; let g = ((num >> 8) & 0x00FF) - amount; let b = (num & 0x0000FF) - amount;
    if (r < 0) r = 0; if (g < 0) g = 0; if (b < 0) b = 0;
    return `#${(g | (b << 8) | (r << 16)).toString(16).padStart(6, '0')}`;
};
const getKpiGradient = (color: string) => {
    const dark = darkenColor(color, 40);
    return `linear-gradient(135deg, ${color}, ${dark})`;
};

const imageModal = reactive({ show: false, url: '', name: '' });
const openImage = (item:any) => { imageModal.url = item.stamp_image_url||item.print_file_url; imageModal.name = item.stamp_ref; imageModal.show = true; };

const logModal = reactive({ show: false, loading: false, logs: [] as any[], item: null as any });
const openLogs = async (item: any) => {
    logModal.item = item; logModal.loading = true; logModal.show = true;
    try {
       const { data, error } = await supabase
          .from('production_logs')
          .select('*, user:profiles(full_name)')
          .eq('order_item_id', item.id)
          .order('created_at', { ascending: false });

       if (error) throw error;
       logModal.logs = data || [];
    } catch(e) { logModal.logs = []; } finally { logModal.loading = false; }
};

const getDynamicStatusConfig = (dbStatus: string, stage: WorkflowNode | null) => {
    if (!stage || !activeWorkflow.value) return { label: dbStatus, color: 'blue-grey' };

    const entryNode = activeWorkflow.value.nodes.find(n => n.parentId === stage.id && n.type === 'ENTRY' && (n.data as any).dbStatus === dbStatus);
    if (entryNode) return { label: (entryNode.data as any).chipLabel || entryNode.data.name, color: entryNode.color };

    const stepNode = activeWorkflow.value.nodes.find(n => n.parentId === stage.id && n.type === 'STEP' && (n.data as any).dbStatus === dbStatus);
    if (stepNode) return { label: (stepNode.data as any).chipLabel || stepNode.data.name, color: (stepNode.data as any).buttonColor || stage.color };

    const decNode = activeWorkflow.value.nodes.find(n => n.parentId === stage.id && n.type === 'DECISION' && (n.data as any).mode === 'manual' && (n.data as any).triggerStatus === dbStatus);
    if (decNode) return { label: (decNode.data as any).chipLabel || decNode.data.name, color: decNode.color };

    if (dbStatus.includes('rework') || dbStatus.includes('erro') || dbStatus.includes('fail')) {
        return { label: 'Falha / Retorno', color: '#E53935' };
    }

    const mapped = (stage.data as any).mappedStatuses || [];
    if (mapped.includes(dbStatus)) return { label: (stage.data as any).chipLabel || 'Fila ' + ((stage.data as any).title || ''), color: stage.color };

    return { label: dbStatus, color: 'blue-grey' };
};

const getNodeIcon = (type: string) => {
   const map: any = { FORM: 'mdi-form-textbox', REWORK: 'mdi-alert-octagon', OUTPUT: 'mdi-flag-checkered', DECISION: 'mdi-call-split', STAGE: 'mdi-arrow-right-bold-circle', TRANSFER: 'mdi-page-next-outline', ENTRY: 'mdi-login-variant' };
   return map[type] || 'mdi-cog';
};

const canOperateStage = (stage: WorkflowNode) => {
  const profileRole = userStore.profile?.role || userStore.role;
  if (profileRole === 'admin' || profileRole === 'super_admin') return true;

  const opCustomRoles = (stage.data as any).permissions?.operateCustomRoles || [];
  if (opCustomRoles.length === 0) return true;

  const userCustomRole = userStore.profile?.custom_role_id;
  return opCustomRoles.includes(userCustomRole);
};

const getAvailableActionsForItem = (item: any, stage: WorkflowNode) => {
    if (!activeWorkflow.value) return [];
    let currentNodes: WorkflowNode[] = [];

    const entryNodes = activeWorkflow.value.nodes.filter(n => n.parentId === stage.id && n.type === 'ENTRY');
    const exactEntry = entryNodes.find(n => (n.data as any).dbStatus === item.status);
    if (exactEntry) currentNodes.push(exactEntry);

    const stepNode = activeWorkflow.value.nodes.find(n => n.parentId === stage.id && n.type === 'STEP' && (n.data as any).dbStatus === item.status);
    if (stepNode) currentNodes.push(stepNode);

    const decNode = activeWorkflow.value.nodes.find(n => n.parentId === stage.id && n.type === 'DECISION' && (n.data as any).mode === 'manual' && (n.data as any).triggerStatus === item.status);
    if (decNode) currentNodes.push(decNode);

    if (currentNodes.length === 0) {
        const mapped = (stage.data as any).mappedStatuses || [];
        if (mapped.includes(item.status)) {
            const genericEntry = entryNodes.find(n => !(n.data as any).dbStatus);
            if (genericEntry) {
                currentNodes.push(genericEntry);
            } else {
                currentNodes.push(stage);
            }
        }
    }

    let actions: any[] = [];

    currentNodes.forEach(cNode => {
        const outEdges = activeWorkflow.value!.edges.filter(e => e.fromId === cNode.id && !e.isJump);

        outEdges.forEach(edge => {
            const targetNode = activeWorkflow.value!.nodes.find(n => n.id === edge.toId);
            if (!targetNode) return;

            if (targetNode.type === 'STAGE') {
                actions.push({
                    id: targetNode.id, type: 'STAGE', node: targetNode, edge,
                    label: `Enviar p/ ${(targetNode.data as any).title || targetNode.data.name}`,
                    color: targetNode.color, icon: 'mdi-arrow-right-bold-circle'
                });
            } else {
                let color = (targetNode.data as any).buttonColor || targetNode.color;
                if (cNode.type === 'DECISION') {
                     if (edge.condition === 'rule1') color = '#4CAF50';
                     else if (edge.condition === 'rule2') color = '#FF9800';
                     else if (edge.condition === 'fail') color = '#F44336';
                }

                actions.push({
                    id: targetNode.id, type: targetNode.type, node: targetNode, edge,
                    label: (targetNode.data as any).buttonText || targetNode.data.name || 'Avançar',
                    color: color,
                    icon: (targetNode.data as any).icon || getNodeIcon(targetNode.type)
                });
            }
        });
    });

    return actions;
};

const getStageEntryStatus = (stage: WorkflowNode) => {
    const childEntries = activeWorkflow.value!.nodes.filter(n => n.parentId === stage.id && n.type === 'ENTRY');
    if (childEntries.length > 0 && (childEntries[0].data as any).dbStatus) return (childEntries[0].data as any).dbStatus;

    const childSteps = activeWorkflow.value!.nodes.filter(n => n.parentId === stage.id && n.type === 'STEP');
    if (childSteps.length > 0) return (childSteps[0].data as any).dbStatus;

    const mapped = (stage.data as any).mappedStatuses || [];
    if (mapped.length > 0) return mapped[0];

    return stage.data.name.toLowerCase().replace(/\s+/g, '_');
};

const checkMove = (evt: any) => {
   const draggedItem = evt.draggedContext.element;
   const fromStageId = evt.from.getAttribute('data-stage-id');
   const toStageId = evt.to.getAttribute('data-stage-id');
   if (fromStageId === toStageId) return true;

   const fromStage = orderedStages.value.find(s => s.id === fromStageId);
   const actions = getAvailableActionsForItem(draggedItem, fromStage!);
   const hasExternalStageMove = actions.some(a => a.type === 'STAGE' && a.id === toStageId);

   if (hasExternalStageMove) return true;

   const jumpEdge = activeWorkflow.value?.edges.find(e => e.fromId === fromStageId && e.toId === toStageId && e.isJump);
   if (jumpEdge) return true;

   appStore.showSnackbar(`Ação Bloqueada: Conclua os passos internos nos botões antes de arrastar.`, 'error');
   return false;
};

const onKanbanDragEnd = (evt: any) => { };

const executeBatchAction = async (action: any) => {
   if (selectedRows.value.length === 0) return;
   const firstItem = selectedRows.value[0];
   const stage = orderedStages.value.find(s => s.id === activeStageId.value);
   if (!stage) return;

   const targetNode = action.node as WorkflowNode;

   if (targetNode.type === 'FORM') { await openFormModal(targetNode, firstItem, stage, true, selectedRows.value); }
   else if (targetNode.type === 'REWORK') { openReworkModal(targetNode, firstItem, stage, true, selectedRows.value); }
   else {
      isProcessingEngine.value = true;
      const allItemIds = selectedRows.value.map(i => i.id);
      for (const item of selectedRows.value) {
         await applyNodeState(targetNode, item, { is_batch: true, batch_size: selectedRows.value.length, batch_items: allItemIds }, action.edge.condition);
      }
      isProcessingEngine.value = false;
      appStore.showSnackbar(`Ação de lote aplicada.`, 'success');
      await fetchProductionItems();
   }
};

const executeAction = async (action: any, item: any, sourceStage: WorkflowNode) => {
    processingItemId.value = item.id;
    const targetNode = action.node as WorkflowNode;

    if (targetNode.type === 'FORM') { await openFormModal(targetNode, item, sourceStage, false, []); }
    else if (targetNode.type === 'REWORK') { openReworkModal(targetNode, item, sourceStage, false, []); }
    else {
        await applyNodeState(targetNode, item, {}, action.edge.condition);
        await fetchProductionItems();
    }
    processingItemId.value = null;
};

const applyNodeState = async (targetNode: WorkflowNode, item: any, payload: any, edgeCondition: string = 'default') => {
    let newStatus = null;
    let logMsg = `Executado: ${targetNode.data.name}`;

    if (targetNode.type === 'STAGE') {
        newStatus = getStageEntryStatus(targetNode);
        logMsg = `Transferido para a Aba: ${targetNode.data.name}`;
    }
    else if (targetNode.type === 'STEP') {
        newStatus = (targetNode.data as any).dbStatus;
        logMsg = `Ação Interna: ${targetNode.data.name}`;
    }
    else if (targetNode.type === 'TRANSFER') {
        newStatus = (targetNode.data as any).targetStatus;
        logMsg = `Enviado Adiante/Transferido: ${targetNode.data.name}`;
    }
    else if (targetNode.type === 'FORM') {
        newStatus = (targetNode.data as any).targetStatus;
        logMsg = `Formulário Preenchido: ${targetNode.data.name}`;
    }
    else if (targetNode.type === 'REWORK') {
        newStatus = (targetNode.data as any).targetStatus;
        logMsg = `Falha Reportada: ${targetNode.data.name}`;
    }
    else if (targetNode.type === 'OUTPUT') {
        newStatus = (targetNode.data as any).finalStatus || 'completed';
        logMsg = `Finalizado pelo Sistema: ${targetNode.data.name}`;
    }
    else if (targetNode.type === 'DECISION') {
        if ((targetNode.data as any).mode === 'manual') {
            return;
        } else {
            const matchedCondition = evaluateDecision(targetNode, item);
            const nextEdge = activeWorkflow.value!.edges.find(e => e.fromId === targetNode.id && e.condition === matchedCondition);
            if (nextEdge) {
                const nextNode = activeWorkflow.value!.nodes.find(n => n.id === nextEdge.toId);
                if (nextNode) return await applyNodeState(nextNode, item, payload, matchedCondition);
            }
            return;
        }
    }

    if (newStatus) {
        await executeStatusUpdateSilent(item.id, newStatus, logMsg, payload);
        item.status = newStatus;
    }

    const outEdges = activeWorkflow.value!.edges.filter(e => e.fromId === targetNode.id && !e.isJump);
    for (const edge of outEdges) {
        const nextNode = activeWorkflow.value!.nodes.find(n => n.id === edge.toId);
        if (!nextNode) continue;

        if (nextNode.type === 'DECISION' && (nextNode.data as any).mode !== 'manual') {
            await applyNodeState(nextNode, item, payload, edge.condition);
        } else if (nextNode.type === 'OUTPUT') {
            await applyNodeState(nextNode, item, payload, edge.condition);
        }
    }
};

const evaluateDecision = (node: WorkflowNode, item: any) => {
    const rules = [ (node.data as any).rule1, (node.data as any).rule2 ];
    for (let i = 0; i < rules.length; i++) {
        const rule = rules[i];
        if (!rule || !rule.field) continue;

        const itemVal = String(item[rule.field] || '');
        const expVal = String(rule.value || '');
        let match = false;

        if (rule.operator === 'Igual a (==)') match = itemVal === expVal;
        else if (rule.operator === 'Diferente de (!=)') match = itemVal !== expVal;
        else if (rule.operator === 'Contém') match = itemVal.includes(expVal);
        else if (rule.operator === 'Maior que (>)') match = Number(itemVal) > Number(expVal);
        else if (rule.operator === 'Menor que (<)') match = Number(itemVal) < Number(expVal);

        if (match) return i === 0 ? 'rule1' : 'rule2';
    }
    return 'fail';
};

const executeStatusUpdateSilent = async (itemId: string, newStatus: string, logDesc: string, extraPayload: any = {}) => {
  const currentItem = items.value.find(i => i.id === itemId);
  const oldStatus = currentItem ? currentItem.status : 'unknown';

  const { error } = await supabase.from('order_items').update({ status: newStatus }).eq('id', itemId);
  if (error) return;

  const metadata = {
     old_status: oldStatus, new_status: newStatus, description: logDesc,
     form_data: extraPayload.form_data || {},
     is_rework: extraPayload.is_rework || false,
     justification: extraPayload.justification || '',
     attachment_url: extraPayload.attachment_url || '',
     is_batch: extraPayload.is_batch || false, batch_size: extraPayload.batch_size || 1, batch_items: extraPayload.batch_items || []
  };

  await supabase.from('production_logs').insert({
    order_item_id: itemId, user_id: userStore.user?.id,
    action: extraPayload.is_batch ? 'BATCH_STATUS_CHANGE' : 'STATUS_CHANGE',
    metadata: metadata
  });
};

const formModal = reactive({ show: false, isBatch: false, batchItems: [] as any[], node: null as WorkflowNode | null, item: null as any, sourceStage: null as WorkflowNode | null, payload: {} as Record<string, any>, dropdownOptions: {} as Record<string, any[]> });
const openFormModal = async (node: WorkflowNode, item: any, sourceStage: WorkflowNode, isBatch = false, batchItems: any[] = []) => {
  formModal.node = node; formModal.item = item; formModal.sourceStage = sourceStage; formModal.payload = {}; formModal.isBatch = isBatch; formModal.batchItems = batchItems;

  for (const field of ((node.data as any).fields || [])) {
     if (['select', 'multiselect'].includes(field.type) && field.dataSource) {
        if (field.dataSource === 'production_machines') {
            let query = supabase.from('production_machines').select('id, name');
            if (field.machineTypeFilter && field.machineTypeFilter !== 'all') {
                query = query.eq('type', field.machineTypeFilter);
            }
            const { data } = await query;
            formModal.dropdownOptions[field.name] = (data || []).map(d => ({ label: d.name, value: d.id }));
        }
        if (field.dataSource === 'employees_mj') {
            const { data } = await supabase.from('employees_mj').select('id, nome, cargo').eq('situacao', 'Ativo');
            formModal.dropdownOptions[field.name] = (data || []).map(d => ({ label: `${d.nome} (${d.cargo || 'S/C'})`, value: d.id }));
        }
     }
  }
  formModal.show = true;
};
const closeFormModal = () => { formModal.show = false; processingItemId.value = null; };
const submitDynamicForm = async () => {
  if (!dynamicFormRef.value) return;
  const { valid } = await dynamicFormRef.value.validate();
  if (!valid) return;

  if (!formModal.node || !formModal.item) return;
  isProcessingEngine.value = true;

  const processedPayload = { ...formModal.payload };
  for (const key in processedPayload) {
     const val = processedPayload[key];
     if (val instanceof File || (Array.isArray(val) && val[0] instanceof File)) {
         const file = Array.isArray(val) ? val[0] : val;
         processedPayload[key] = `Arquivo Anexado: ${file.name}`;
     }
  }

  const p = { form_data: processedPayload }; const nId = formModal.node.id; formModal.show = false;

  if (formModal.isBatch) {
     const allItemIds = formModal.batchItems.map(i => i.id);
     for (const it of formModal.batchItems) { await applyNodeState(formModal.node, it, { ...p, is_batch: true, batch_size: formModal.batchItems.length, batch_items: allItemIds }); }
  } else { await applyNodeState(formModal.node, formModal.item, p); }

  await fetchProductionItems();
  isProcessingEngine.value = false;
};

const reworkModal = reactive({ show: false, isBatch: false, batchItems: [] as any[], node: null as WorkflowNode | null, item: null as any, sourceStage: null as WorkflowNode | null, payload: { justification: '', attachment: null as File | null | File[] } });
const openReworkModal = (node: WorkflowNode, item: any, sourceStage: WorkflowNode, isBatch = false, batchItems: any[] = []) => { reworkModal.node = node; reworkModal.item = item; reworkModal.sourceStage = sourceStage; reworkModal.isBatch = isBatch; reworkModal.batchItems = batchItems; reworkModal.payload = { justification: '', attachment: null }; reworkModal.show = true; };
const closeReworkModal = () => { reworkModal.show = false; processingItemId.value = null; };
const submitRework = async () => {
  if (!reworkFormRef.value) return;
  const { valid } = await reworkFormRef.value.validate();
  if (!valid) return;

  if (!reworkModal.node || !reworkModal.item) return;
  isProcessingEngine.value = true;
  try {
     let attachmentUrl = '';

     if (reworkModal.payload.attachment && !reworkModal.isBatch) {
         const fileToUpload = Array.isArray(reworkModal.payload.attachment) ? reworkModal.payload.attachment[0] : reworkModal.payload.attachment;
         if (fileToUpload instanceof File) {
            const fileExt = fileToUpload.name.split('.').pop();
            const fileName = `${uuidv4()}.${fileExt}`;
            const { error: uploadError } = await supabase.storage.from('production-media').upload(`reworks/${fileName}`, fileToUpload);
            if (!uploadError) {
               const { data } = supabase.storage.from('production-media').getPublicUrl(`reworks/${fileName}`);
               attachmentUrl = data.publicUrl;
            } else {
               console.error("Erro no upload da falha:", uploadError);
               appStore.showSnackbar("O anexo falhou pois a permissão no Supabase bloqueou. O item será devolvido sem foto.", "warning");
            }
         }
     }

     reworkModal.show = false;
     if (reworkModal.isBatch) {
        const allItemIds = reworkModal.batchItems.map(i => i.id);
        for (const it of reworkModal.batchItems) {
           await applyNodeState(reworkModal.node, it, { is_rework: true, justification: reworkModal.payload.justification, attachment_url: attachmentUrl, is_batch: true, batch_size: reworkModal.batchItems.length, batch_items: allItemIds });
        }
     } else {
        await applyNodeState(reworkModal.node, reworkModal.item, { is_rework: true, justification: reworkModal.payload.justification, attachment_url: attachmentUrl });
     }
     await fetchProductionItems();
  } finally { isProcessingEngine.value = false; }
};
</script>

<style scoped lang="scss">
.pcp-layout { position: relative; height: 100vh; }
.bg-glass-dark { background: rgba(10,10,12,0.95); }
.bg-glass-header { background: rgba(20,20,24,0.85); backdrop-filter: blur(14px); }
.background-carousel-wrapper { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 0; opacity: 0.6; pointer-events: none; }
.background-overlay { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 1; background: radial-gradient(circle at center, rgba(15, 15, 19, 0.4), rgba(15, 15, 19, 0.98)); backdrop-filter: blur(8px); }

.kpi-scroll-container { -webkit-overflow-scrolling: touch; }
.kpi-card { transition: all 0.25s cubic-bezier(0.2, 0.8, 0.2, 1); border-radius: 0 !important; border-bottom: 0 solid transparent; border: 1px solid rgba(0,0,0,0.08); }
.kpi-active-border { transform: scale(1.05); filter: brightness(1.1); box-shadow: 0 10px 25px rgba(0,0,0,0.5) !important; }
.kpi-bg-icon { position: absolute; right: -10px; bottom: -10px; opacity: 0.2; transform: rotate(-15deg); pointer-events: none; }
.kpi-bg-icon .v-icon { font-size: 60px; }

.grid-header, .grid-row { display: grid; align-items: stretch; width: 100%; min-width: 1200px; }
.grid-dynamic { grid-template-columns: 50px 60px 180px minmax(200px, 1fr) 140px 120px 180px 200px; }
.cell { padding: 0 12px; display: flex; align-items: center; border-right: 1px solid rgba(0,0,0,0.08); border-bottom: 1px solid rgba(0,0,0,0.08); height: 56px; overflow: visible; transition: background-color 0.2s ease; }
.grid-header .cell { min-height: 44px; font-size: 11px; font-weight: 800; text-transform: uppercase; letter-spacing: 0.5px; opacity: 0.9; line-height: 1.2; }
.center { justify-content: center; text-align: center; }
.list-text { font-size: 13px; line-height: 1.35; }

.grid-surface-light .cell { background: #f5f7fa; color: rgba(0,0,0,0.9); border-color: rgba(0,0,0,0.12) !important; }
.grid-row-light .cell { border-color: rgba(0,0,0,0.08) !important; }
.zebra-light-a .cell { background: #ffffff; }
.zebra-light-b .cell { background: #f0f4f8; }
.grid-row-light:hover .cell { background: #e3f2fd !important; }
.grid-selected-light .cell { background: #e8f5e9 !important; }

.grid-surface-dark .cell { background: rgba(255,255,255,0.08) !important; color: rgba(255,255,255,0.80) !important; border-color: rgba(255,255,255,0.10) !important; backdrop-filter: none !important; }
.grid-row-dark .cell { background: rgba(255,255,255,0.04); border-color: rgba(255,255,255,0.08) !important; color: rgba(255,255,255,0.85); }
.zebra-dark-a .cell { background: rgba(255,255,255,0.04) !important; }
.zebra-dark-b .cell { background: rgba(255,255,255,0.015) !important; }
.grid-row-dark:hover .cell { background: rgba(255,255,255,0.07) !important; }
.grid-selected-dark .cell { background: rgba(76, 175, 80, 0.2) !important; }

.actions-inline { display: flex; align-items: center; justify-content: center; gap: 6px; width: 100%; }
.square-btn { width: 32px !important; height: 32px !important; min-width: 32px !important; padding: 0 !important; border-radius: 6px !important; }
.btn-3d { border-radius: 6px !important; box-shadow: 0 3px 5px rgba(0,0,0,0.15), inset 0 2px 0 rgba(255,255,255,0.25) !important; transition: transform 0.1s ease, box-shadow 0.1s ease; text-transform: uppercase !important; font-weight: 800; letter-spacing: 0.5px; }
.btn-3d:active { transform: translateY(2px); box-shadow: 0 1px 2px rgba(0,0,0,0.15), inset 0 1px 0 rgba(255,255,255,0.2) !important; }
.chip-3d { box-shadow: 0 2px 4px rgba(0,0,0,0.12), inset 0 1px 0 rgba(255,255,255,0.25) !important; font-weight: 900; text-shadow: 0 1px 2px rgba(0,0,0,0.3); }
.hover-elevate:hover { transform: translateY(-2px); box-shadow: 0 8px 16px rgba(0,0,0,0.1) !important; }

.kanban-card { cursor: grab; }
.kanban-card:active { cursor: grabbing; }

.drag-card {
   transform-origin: top center;
   animation: swing 0.4s ease-in-out alternate infinite !important;
   box-shadow: 0 30px 60px rgba(0,0,0,0.5) !important;
   cursor: grabbing !important;
   opacity: 0.95;
   border-color: rgba(83, 109, 254, 0.8) !important;
   z-index: 999;
}
@keyframes swing {
   0% { transform: rotate(3deg) scale(1.05); }
   100% { transform: rotate(-3deg) scale(1.05); }
}

.ghost-card {
   opacity: 0.4;
   background-color: rgba(128, 128, 128, 0.1);
   border: 2px dashed rgba(128, 128, 128, 0.5) !important;
   border-left: 2px dashed rgba(128, 128, 128, 0.5) !important;
   border-radius: 8px;
   transition: height 0.2s ease;
}

.icon-3d-wrapper { position: relative; width: 32px; height: 32px; display: flex; align-items: center; justify-content: center; background: linear-gradient(135deg, rgba(255,255,255,0.1), rgba(0,0,0,0.1)); border-radius: 8px; box-shadow: 0 4px 6px rgba(0,0,0,0.15), inset 0 2px 4px rgba(255,255,255,0.4), inset 0 -2px 4px rgba(0,0,0,0.2); overflow: hidden; transition: transform 0.2s cubic-bezier(0.175, 0.885, 0.32, 1.275); }
.bg-glass-dark .icon-3d-wrapper { background: linear-gradient(135deg, rgba(255,255,255,0.05), rgba(0,0,0,0.3)); box-shadow: 0 4px 6px rgba(0,0,0,0.3), inset 0 2px 4px rgba(255,255,255,0.1), inset 0 -2px 4px rgba(0,0,0,0.4); }
.icon-3d-wrapper:hover { transform: translateY(-2px) scale(1.05); }
.icon-3d { filter: drop-shadow(0 2px 2px rgba(0,0,0,0.3)); }
.icon-3d-shine { position: absolute; top: 0; left: -100%; width: 50%; height: 100%; background: linear-gradient(90deg, transparent, rgba(255,255,255,0.5), transparent); transform: skewX(-20deg); }
.icon-3d-wrapper:hover .icon-3d-shine { animation: shine-sweep 0.6s ease-out; }
@keyframes shine-sweep { 0% { left: -100%; } 100% { left: 200%; } }

.hint-tooltip { position: relative; display: inline-flex; }
.hint-tooltip:hover::after { content: attr(data-title); position: absolute; bottom: calc(100% + 6px); left: 50%; transform: translateX(-50%); background: rgba(0,0,0,0.95); color: #fff; padding: 6px 10px; font-size: 11px; font-weight: 800; border-radius: 4px; white-space: nowrap; pointer-events: none; z-index: 100; text-transform: uppercase; letter-spacing: 0.5px; box-shadow: 0 4px 12px rgba(0,0,0,0.3); }

.custom-scroll::-webkit-scrollbar { width: 8px; height: 8px; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.35); border-radius: 6px; }
.custom-scroll-x::-webkit-scrollbar { height: 8px; }
.custom-scroll-x::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.35); border-radius: 4px; }
.custom-scroll::-webkit-scrollbar-track, .custom-scroll-x::-webkit-scrollbar-track { background: transparent; }

.floating-actions-wrap { position: fixed; left: 0; right: 0; bottom: 18px; display: flex; justify-content: center; z-index: 9999; pointer-events: none; }
.floating-actions-card { width: min(1100px, calc(100% - 32px)); border-radius: 14px !important; overflow: hidden; pointer-events: auto; backdrop-filter: blur(10px); }
.floating-light { background: rgba(255,255,255,0.95); border: 1px solid rgba(0,0,0,0.08); }
.floating-dark { background: rgba(20,20,24,0.85); border: 1px solid rgba(255,255,255,0.12); }
.floating-btn { border-radius: 10px !important; text-transform: none !important; font-weight: 900; }

.sticky-head { position: sticky; top: 0; z-index: 20; box-shadow: 0 8px 16px -4px rgba(0, 0, 0, 0.12); }
.chk-fixed { margin: 0 !important; padding: 0 !important; width: 24px; height: 24px; }
:deep(.v-selection-control__input) { width: 24px; height: 24px; }
:deep(.v-checkbox-btn .v-icon) { font-size: 18px !important; }

.log-timeline { display: flex; flex-direction: column; gap: 14px; }
.log-row { display: grid; grid-template-columns: 22px 1fr; gap: 12px; padding: 12px; border: 1px solid rgba(0,0,0,0.08); }
.log-row-light { background: #fff; }
.log-row-dark { background: rgba(255,255,255,0.04); border-color: rgba(255,255,255,0.10) !important; }
.log-mark { position: relative; display: flex; flex-direction: column; align-items: center; }
.log-dot { width: 12px; height: 12px; border-radius: 999px; border: 2px solid rgba(255,255,255,0.5); }
.log-line { width: 2px; flex: 1; margin-top: 6px; background: rgba(160,160,160,0.45); border-radius: 2px; }
</style>
