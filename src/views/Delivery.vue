<template>
  <div
    class="delivery-layout font-sans fill-height d-flex flex-column relative overflow-hidden"
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

    <v-slide-y-transition>
      <div v-if="isBatchMoving" class="batch-move-banner d-flex align-center justify-center gap-4 elevation-10"
           :class="themeStore.currentMode === 'light' ? 'bg-white text-grey-darken-4 border-primary border' : 'bg-primary text-white'">
        <v-icon :class="themeStore.currentMode === 'light' ? 'text-primary' : 'text-white'" class="animate-bounce">mdi-arrow-down-bold</v-icon>
        <div class="d-flex flex-column align-center">
          <span class="font-weight-bold text-h6 lh-1">Selecione o Destino</span>
          <span class="text-caption opacity-80">Clique em uma coluna ou dia abaixo</span>
        </div>
        <v-btn icon="mdi-close" variant="text" @click="cancelBatchMove"></v-btn>
      </div>
    </v-slide-y-transition>

    <div class="content-wrapper d-flex flex-column fill-height z-10 relative">

      <v-fade-transition>
        <div v-if="isBatchMoving"
             class="focus-overlay"
             @click="cancelBatchMove">
        </div>
      </v-fade-transition>

      <div
        class="header-bar px-6 py-4 d-flex align-center justify-space-between flex-shrink-0 relative"
        :class="[
            themeStore.currentMode === 'light' ? 'bg-white border-b border-grey-lighten-2 shadow-sm' : 'bg-glass-header border-bottom-white-05',
            isBatchMoving ? 'z-low' : 'z-high'
        ]"
      >
        <div class="d-flex flex-column">
          <div class="breadcrumb text-caption">
            <span class="opacity-70">MJ Process</span>
            <span class="mx-2 opacity-50">></span>
            <span class="font-weight-bold">Expedição</span>
          </div>
          <div class="text-h6 font-weight-black tracking-tight leading-none mt-1" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">
            Logística de Entrega
          </div>
        </div>

        <div class="d-flex align-center" style="gap: 10px;">
           <div class="d-flex align-center bg-grey-lighten-4 rounded px-1 py-1 mr-4" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-3' : 'bg-white-05'">
              <v-btn size="small" variant="flat" :color="viewMode === 'kanban' ? 'white' : 'transparent'" :class="{'elevation-2 text-primary font-weight-bold': viewMode === 'kanban'}" @click="viewMode = 'kanban'">
                 <v-icon start size="16">mdi-view-column</v-icon> Kanban
              </v-btn>
              <v-btn size="small" variant="flat" :color="viewMode === 'calendar' ? 'white' : 'transparent'" :class="{'elevation-2 text-primary font-weight-bold': viewMode === 'calendar'}" @click="viewMode = 'calendar'">
                 <v-icon start size="16">mdi-calendar-month</v-icon> Calendário
              </v-btn>
           </div>

          <v-btn
            variant="outlined"
            class="btn-rect"
            height="40"
            prepend-icon="mdi-history"
            :color="themeStore.currentMode === 'light' ? 'grey-darken-2' : 'white'"
            @click="openHistoryModal"
          >
            Histórico
          </v-btn>
        </div>
      </div>

      <div class="px-6 pt-4 pb-2 flex-shrink-0 relative" :class="isBatchMoving ? 'z-low' : 'z-high'">
        <div
          class="controls-bar d-flex align-center justify-space-between"
          :class="themeStore.currentMode === 'light' ? 'controls-light' : 'controls-dark'"
        >
          <div class="d-flex align-center flex-wrap" style="gap: 10px;">

            <div class="period-nav d-flex align-center" :class="themeStore.currentMode === 'light' ? 'period-nav-light' : 'period-nav-dark'">
              <v-btn icon variant="text" class="icon-rect" height="40" width="40" @click="viewMode === 'kanban' ? previousWeek() : previousMonth()">
                <v-icon>mdi-chevron-left</v-icon>
              </v-btn>
              <div class="period-label text-caption font-weight-black text-center px-3">
                <v-icon size="small" class="mr-2" color="primary">mdi-calendar-range</v-icon>
                {{ viewMode === 'kanban' ? weekRangeText : calendarMonthText }}
              </div>
              <v-btn icon variant="text" class="icon-rect" height="40" width="40" @click="viewMode === 'kanban' ? nextWeek() : nextMonth()">
                <v-icon>mdi-chevron-right</v-icon>
              </v-btn>
            </div>

            <div style="width: 200px;">
               <v-autocomplete
                  v-model="globalFilterFabric"
                  :items="fabricTypesForFilter"
                  placeholder="Filtrar Tecido"
                  variant="outlined"
                  density="compact"
                  hide-details
                  class="filter-select rounded-0"
                  :bg-color="themeStore.currentMode === 'light' ? 'white' : 'transparent'"
                  clearable
              >
                <template v-slot:prepend-inner><v-icon size="small" class="opacity-50">mdi-filter-variant</v-icon></template>
              </v-autocomplete>
            </div>

            <v-btn v-if="viewMode === 'calendar'" variant="text" size="small" @click="goToToday" class="text-caption font-weight-bold">
               Ir para Hoje
            </v-btn>
          </div>
        </div>
      </div>

      <div class="flex-grow-1 px-6 pb-2 overflow-hidden d-flex flex-column relative z-high">
        <v-card
          class="flex-grow-1 d-flex flex-column rounded-0 border-thin overflow-hidden"
          :class="themeStore.currentMode === 'light' ? 'bg-white shadow-sm' : 'glass-card border-white-05'"
          :elevation="0"
        >
          <div v-if="loading" class="d-flex flex-column justify-center align-center h-100">
             <v-progress-circular indeterminate color="primary" size="64" width="6"></v-progress-circular>
             <div class="mt-4 font-weight-medium opacity-70">Carregando logística...</div>
          </div>

          <div v-else-if="viewMode === 'kanban'" class="kanban-container d-flex flex-grow-1 overflow-hidden h-100 overflow-x-auto custom-scroll-x">

             <div class="kanban-column d-flex flex-column h-100 border-r relative"
                 :class="[
                    themeStore.currentMode === 'light' ? 'bg-green-lighten-5 border-grey-lighten-2' : 'bg-green-darken-4-alpha border-white-05',
                    (isColumnActive('ready') || isBatchMoving) ? 'column-elevated' : ''
                 ]">

              <div v-if="isBatchMoving && selectionMode.column !== 'ready'"
                   class="target-overlay d-flex align-center justify-center cursor-pointer"
                   @click.stop="handleColumnClick('ready')">
                <v-chip color="primary" variant="elevated" class="font-weight-bold elevation-4 pointer-events-none">
                  <v-icon start>mdi-target</v-icon> Mover para cá
                </v-chip>
              </div>

              <v-slide-x-reverse-transition>
                <div v-if="isColumnActive('ready') && !isBatchMoving" class="floating-action-menu" :class="themeStore.currentMode === 'light' ? 'bg-white border shadow-xl' : 'bg-grey-darken-4'">
                  <div class="text-caption font-weight-black mb-3 text-center" :class="textPrimaryClass">{{ selectionMode.selected.length }} SELECIONADOS</div>
                  <v-btn variant="flat" size="small" class="mb-2 font-weight-bold text-caption justify-start px-2" block
                         :color="themeStore.currentMode === 'light' ? 'grey-lighten-4' : 'grey-darken-3'"
                         :class="textPrimaryClass"
                         @click="activateBatchMove"
                         :disabled="!canManageDelivery">
                    <v-icon start color="primary" size="small">mdi-arrow-right-bold-box-outline</v-icon> Mover
                  </v-btn>
                  <v-divider class="mb-2"></v-divider>
                  <v-btn color="error" variant="tonal" size="small" class="font-weight-bold text-caption justify-start px-2" block @click="openBatchDeleteModal" :disabled="!canManageDelivery">
                    <v-icon start size="small">mdi-delete</v-icon> Excluir
                  </v-btn>
                </div>
              </v-slide-x-reverse-transition>

              <div class="column-header pa-3 flex-shrink-0 border-b" :class="themeStore.currentMode === 'light' ? 'border-grey-lighten-2' : 'border-white-05'">
                <div class="d-flex justify-space-between align-center mb-1">
                   <div class="d-flex align-center gap-2">
                      <div class="status-dot bg-success pulsing-dot"></div>
                      <span class="text-subtitle-2 font-weight-black text-uppercase opacity-90">Pronta Entrega</span>
                   </div>
                   <div class="d-flex align-center">
                      <v-btn v-if="isColumnActive('ready')" icon="mdi-check" size="x-small" color="success" variant="flat" class="mr-2 elevation-2" @click.stop="exitSelectionMode"></v-btn>
                      <v-menu location="bottom end">
                        <template v-slot:activator="{ props }">
                          <v-btn v-bind="props" icon size="x-small" variant="text" class="opacity-50"><v-icon>mdi-dots-vertical</v-icon></v-btn>
                        </template>
                        <v-list density="compact" nav class="rounded-lg border shadow-lg" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-surface-card'">
                          <v-list-item prepend-icon="mdi-checkbox-multiple-marked-outline" title="Seleção Múltipla" @click="startSelectionMode('ready')"></v-list-item>
                          <v-list-item prepend-icon="mdi-printer" title="Imprimir Lista" @click="generateColumnReport(readyForDeliveryOrders, 'Pronta Entrega')"></v-list-item>
                        </v-list>
                      </v-menu>
                   </div>
                </div>
                <div class="d-flex align-center justify-space-between mt-1">
                    <span class="text-[10px] opacity-60 font-weight-bold text-uppercase">Aguardando Retirada</span>
                    <v-chip size="x-small" color="success" variant="flat" class="font-weight-black">{{ readyForDeliveryOrders.length }}</v-chip>
                </div>
              </div>

              <div class="kanban-content pa-2 custom-scroll flex-grow-1 overflow-y-auto">
                 <div v-for="order in filteredReadyOrders" :key="order.id" class="mb-2">
                    <v-card
                      class="production-card rounded-0 border-s-4"
                      :class="themeStore.currentMode === 'light' ? 'bg-white border-thin' : 'bg-surface-card border-white-05'"
                      style="border-left-color: #4CAF50 !important; border-left-width: 4px !important;"
                      variant="flat"
                      @click="handleCardClick(order, 'ready')"
                      v-ripple
                    >
                      <div class="d-flex align-center pa-2" v-if="isColumnActive('ready')">
                         <v-checkbox-btn v-model="selectionMode.selected" :value="order.id" density="compact" color="primary" @click.stop></v-checkbox-btn>
                      </div>

                      <v-card-text class="pa-3">
                        <div class="d-flex align-center justify-space-between mb-1">
                             <span class="pill-ref">#{{ String(order.order_number).padStart(4, '0') }}</span>
                             <v-chip size="x-small" color="success" label variant="tonal" class="font-weight-black text-[9px] h-auto py-0.5 rounded-0">PRONTO</v-chip>
                        </div>
                        <div class="text-body-2 font-weight-black lh-1 text-truncate mb-2" :title="order.customer_name">
                          {{ order.customer_name }}
                        </div>
                        <div class="d-flex align-center gap-1 mb-3">
                           <v-icon size="12" class="opacity-50">mdi-layers</v-icon>
                           <span class="text-[10px] font-weight-bold opacity-70 text-uppercase text-truncate">
                             {{ order.details?.fabric_type || 'Múltiplos' }}
                           </span>
                        </div>
                        <v-btn v-if="canManageDelivery" block size="small" color="success" variant="flat" class="font-weight-bold rounded-0" style="height: 28px;" @click.stop="confirmDelivery(order)">
                             <v-icon start size="14">mdi-check-all</v-icon> Saída
                        </v-btn>
                      </v-card-text>
                    </v-card>
                 </div>
              </div>
            </div>

            <div class="kanban-column d-flex flex-column h-100 border-r relative"
                 :class="[
                    themeStore.currentMode === 'light' ? 'bg-orange-lighten-5 border-grey-lighten-2' : 'bg-orange-darken-4-alpha border-white-05',
                    (isColumnActive('tobe') || isBatchMoving) ? 'column-elevated' : ''
                 ]">

                <div v-if="isBatchMoving && selectionMode.column !== 'tobe'"
                     class="target-overlay d-flex align-center justify-center cursor-pointer"
                     @click.stop="executeBatchMove('tobe')">
                    <v-chip color="warning" variant="elevated" class="font-weight-bold elevation-4 pointer-events-none">
                        <v-icon start>mdi-target</v-icon> Voltar p/ Agendar
                    </v-chip>
                </div>

                <v-slide-x-reverse-transition>
                  <div v-if="isColumnActive('tobe') && !isBatchMoving" class="floating-action-menu" :class="themeStore.currentMode === 'light' ? 'bg-white border shadow-xl' : 'bg-grey-darken-4'">
                    <div class="text-caption font-weight-black mb-3 text-center" :class="textPrimaryClass">{{ selectionMode.selected.length }} SELECIONADOS</div>
                    <v-btn variant="flat" size="small" class="mb-2 font-weight-bold text-caption justify-start px-2" block
                          :color="themeStore.currentMode === 'light' ? 'grey-lighten-4' : 'grey-darken-3'"
                          :class="textPrimaryClass"
                          @click="activateBatchMove"
                          :disabled="!canManageDelivery">
                      <v-icon start color="primary" size="small">mdi-arrow-right-bold-box-outline</v-icon> Mover
                    </v-btn>
                  </div>
                </v-slide-x-reverse-transition>

                <div class="column-header pa-3 flex-shrink-0 border-b" :class="themeStore.currentMode === 'light' ? 'border-grey-lighten-2' : 'border-white-05'">
                   <div class="d-flex justify-space-between align-center mb-1">
                       <div class="d-flex align-center gap-2">
                          <div class="status-dot bg-warning pulsing-dot"></div>
                          <span class="text-subtitle-2 font-weight-black text-uppercase opacity-90">Agendar</span>
                       </div>
                       <div class="d-flex align-center">
                          <v-btn v-if="isColumnActive('tobe')" icon="mdi-check" size="x-small" color="success" variant="flat" class="mr-2 elevation-2" @click.stop="exitSelectionMode"></v-btn>
                          <v-menu location="bottom end">
                            <template v-slot:activator="{ props }">
                              <div class="d-flex align-center gap-2">
                                <v-chip size="x-small" color="warning" variant="flat" class="font-weight-black text-white">{{ toBeScheduledOrders.length }}</v-chip>
                                <v-btn v-bind="props" icon size="x-small" variant="text" class="opacity-50"><v-icon>mdi-dots-vertical</v-icon></v-btn>
                              </div>
                            </template>
                            <v-list density="compact" nav class="rounded-lg border shadow-lg" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-surface-card'">
                              <v-list-item prepend-icon="mdi-checkbox-multiple-marked-outline" title="Seleção Múltipla" @click="startSelectionMode('tobe')"></v-list-item>
                            </v-list>
                          </v-menu>
                       </div>
                   </div>
                </div>
                <draggable
                    :list="filteredToBeScheduledOrders"
                    :group="{ name: 'orders', pull: true, put: true }"
                    item-key="id"
                    class="kanban-content pa-2 custom-scroll flex-grow-1 overflow-y-auto"
                    ghost-class="ghost-card"
                    :disabled="!canManageDelivery"
                    @end="onDragEnd"
                  >
                    <template #item="{ element: order }">
                      <div class="mb-2" :class="canManageDelivery ? 'cursor-grab' : 'cursor-pointer'" :data-id="order.id">
                        <v-card class="production-card rounded-0 border-s-4" :class="themeStore.currentMode === 'light' ? 'bg-white border-thin' : 'bg-surface-card border-white-05'" style="border-left-color: #FFC107 !important; border-left-width: 4px !important;" variant="flat" @click="handleCardClick(order, 'tobe')">
                            <div class="d-flex align-center pa-2" v-if="isColumnActive('tobe')">
                               <v-checkbox-btn v-model="selectionMode.selected" :value="order.id" density="compact" color="warning" @click.stop></v-checkbox-btn>
                            </div>
                           <v-card-text class="pa-3">
                              <div class="d-flex align-center justify-space-between mb-1"><span class="pill-ref">#{{ String(order.order_number).padStart(4, '0') }}</span><v-icon v-if="canManageDelivery" size="14" class="opacity-50">mdi-drag</v-icon></div>
                              <div class="text-body-2 font-weight-black lh-1 text-truncate mb-2">{{ order.customer_name }}</div>
                              <div class="font-weight-black text-caption opacity-70">{{ getOrderDisplayMeters(order) }}m</div>
                           </v-card-text>
                        </v-card>
                      </div>
                    </template>
                </draggable>
            </div>

            <div v-for="(day, index) in weekDeliveryDays" :key="day.id" class="kanban-column d-flex flex-column h-100 border-r relative"
              :class="[
                  getZebraColumnClass(index, day.date),
                  themeStore.currentMode === 'light' ? 'border-grey-lighten-2' : 'border-white-05',
                  (isColumnActive(day.id) || isBatchMoving) ? 'column-elevated' : ''
              ]">

               <div v-if="isBatchMoving"
                    class="target-overlay d-flex align-center justify-center cursor-pointer"
                    @click.stop="executeBatchMove(day.date.toISOString())">
                    <v-chip color="primary" variant="elevated" class="font-weight-bold elevation-4 pointer-events-none">
                        <v-icon start>mdi-target</v-icon> Mover p/ Dia
                    </v-chip>
               </div>

               <v-slide-x-reverse-transition>
                  <div v-if="isColumnActive(day.id) && !isBatchMoving" class="floating-action-menu" :class="themeStore.currentMode === 'light' ? 'bg-white border shadow-xl' : 'bg-grey-darken-4'">
                    <div class="text-caption font-weight-black mb-3 text-center" :class="textPrimaryClass">{{ selectionMode.selected.length }} SELECIONADOS</div>
                    <v-btn variant="flat" size="small" class="mb-2 font-weight-bold text-caption justify-start px-2" block
                          :color="themeStore.currentMode === 'light' ? 'grey-lighten-4' : 'grey-darken-3'"
                          :class="textPrimaryClass"
                          @click="activateBatchMove"
                          :disabled="!canManageDelivery">
                      <v-icon start color="primary" size="small">mdi-arrow-right-bold-box-outline</v-icon> Mover
                    </v-btn>
                  </div>
                </v-slide-x-reverse-transition>

               <div class="column-header pa-3 flex-shrink-0 border-b" :class="themeStore.currentMode === 'light' ? 'border-grey-lighten-2' : 'border-white-05'">
                   <div class="d-flex justify-space-between align-start w-100">
                      <div>
                        <div class="text-h6 font-weight-black lh-1" :class="isToday(day.date) ? 'text-primary' : ''">{{ formatDate(day.date, 'dd/MM') }}</div>
                        <div class="text-[10px] font-weight-bold opacity-60 text-uppercase">{{ day.name }}</div>
                      </div>
                      <div class="d-flex align-center">
                          <v-btn v-if="isColumnActive(day.id)" icon="mdi-check" size="x-small" color="success" variant="flat" class="mr-2 elevation-2" @click.stop="exitSelectionMode"></v-btn>
                          <v-menu location="bottom end">
                            <template v-slot:activator="{ props }">
                               <v-btn v-bind="props" icon size="x-small" variant="text" class="opacity-50"><v-icon>mdi-dots-vertical</v-icon></v-btn>
                            </template>
                            <v-list density="compact" nav class="rounded-lg border shadow-lg" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-surface-card'">
                              <v-list-item prepend-icon="mdi-checkbox-multiple-marked-outline" title="Seleção Múltipla" @click="startSelectionMode(day.id)"></v-list-item>
                            </v-list>
                          </v-menu>
                       </div>
                   </div>
                   <div class="mt-1 text-caption font-weight-black font-mono">{{ getDayTotalMeters(day.orders) }}m</div>
               </div>
               <draggable :list="day.orders" :group="{ name: 'orders', pull: true, put: true }" item-key="id" class="kanban-content pa-2 custom-scroll flex-grow-1 overflow-y-auto" :data-date="format(day.date, 'yyyy-MM-dd')" ghost-class="ghost-card" :disabled="!canManageDelivery" @end="onDragEnd">
                 <template #item="{ element: order }">
                    <div class="mb-2" :class="canManageDelivery ? 'cursor-grab' : 'cursor-pointer'" :data-id="order.id">
                        <v-card class="production-card rounded-0 border-s-4" :class="[themeStore.currentMode === 'light' ? 'bg-white border-thin' : 'bg-surface-card border-white-05', order.delivery_confirmed_at ? 'opacity-60 grayscale' : '']" :style="`border-left-color: ${order.delivery_confirmed_at ? '#4CAF50' : '#2196F3'} !important; border-left-width: 4px !important;`" variant="flat" @click="handleCardClick(order, day.id)">

                            <div class="d-flex align-center pa-2" v-if="isColumnActive(day.id)">
                               <v-checkbox-btn v-model="selectionMode.selected" :value="order.id" density="compact" color="info" @click.stop></v-checkbox-btn>
                            </div>

                            <v-card-text class="pa-3">
                                <div class="d-flex align-center justify-space-between mb-1"><span class="pill-ref">#{{ String(order.order_number).padStart(4, '0') }}</span><v-icon v-if="order.delivery_confirmed_at" size="14" color="success">mdi-check-circle</v-icon></div>
                                <div class="text-body-2 font-weight-black lh-1 text-truncate mb-2">{{ order.customer_name }}</div>
                                <div class="d-flex align-center justify-space-between border-t pt-2 mt-2" :class="dividerClass">
                                    <span class="text-caption font-mono font-weight-black">{{ getOrderDisplayMeters(order) }}m</span>

                                    <v-btn v-if="canManageDelivery && !order.delivery_confirmed_at"
                                           icon size="x-small" density="comfortable" variant="flat" color="success"
                                           class="rounded-0" style="width: 24px; height: 24px;"
                                           @click.stop="confirmDelivery(order)">
                                        <v-icon size="14">mdi-check</v-icon>
                                    </v-btn>

                                    <v-btn v-if="canManageDelivery && order.delivery_confirmed_at"
                                           icon size="x-small" density="comfortable" variant="flat" color="warning"
                                           class="rounded-0" style="width: 24px; height: 24px;"
                                           @click.stop="rejectDelivery(order)">
                                        <v-icon size="14">mdi-undo</v-icon>
                                    </v-btn>
                                </div>
                            </v-card-text>
                        </v-card>
                    </div>
                 </template>
                 <template #footer>
                     <div v-for="ghost in getGhostEntriesForDay(day.date)" :key="ghost.id" class="ghost-item mb-2 mx-2 pa-2 rounded border border-dashed opacity-60 d-flex flex-column gap-1 cursor-pointer" @click.stop="openDetailModal(ghost.id)">
                        <div class="d-flex justify-space-between align-center"><span class="pill-ref">#{{ String(ghost.order_number || 0).padStart(4, '0') }}</span><v-icon size="x-small" color="info">mdi-wrench-clock</v-icon></div>
                        <div class="text-caption font-weight-bold text-truncate">{{ ghost.customer_name }}</div>

                        <div class="mt-1" v-if="canManageDelivery">
                            <v-btn block size="x-small" color="warning" variant="flat" class="font-weight-bold text-[9px]" style="height: 20px;" @click.stop="openForceCompleteModal(ghost)">
                                <v-icon start size="10">mdi-alert-octagon</v-icon> Forçar
                            </v-btn>
                        </div>
                     </div>
                 </template>
               </draggable>
            </div>
          </div>

          <div v-else class="calendar-container d-flex flex-grow-1 overflow-hidden h-100">
             <div class="calendar-sidebar d-flex flex-column border-r" style="width: 280px; min-width: 280px;" :class="themeStore.currentMode === 'light' ? 'bg-orange-lighten-5 border-grey-lighten-2' : 'bg-surface-card border-white-05'">
                <div class="pa-4 border-b d-flex justify-space-between align-center" :class="dividerClass">
                    <span class="font-weight-black text-caption text-uppercase">Pendentes de Agendamento</span>
                    <v-chip size="x-small" color="warning" class="font-weight-bold">{{ filteredToBeScheduledOrders.length }}</v-chip>
                </div>
                <draggable
                  :list="filteredToBeScheduledOrders"
                  :group="{ name: 'orders', pull: true, put: true }"
                  item-key="id"
                  class="flex-grow-1 overflow-y-auto custom-scroll pa-3"
                  ghost-class="ghost-card"
                  :disabled="!canManageDelivery"
                  @end="onDragEnd"
                >
                  <template #item="{ element: order }">
                    <div class="mb-2" :class="canManageDelivery ? 'cursor-grab' : 'cursor-pointer'" :data-id="order.id">
                        <v-card class="production-card rounded-0 border-s-4" :class="themeStore.currentMode === 'light' ? 'bg-white border-thin' : 'bg-surface-card-alt border-white-05'" style="border-left-color: #FFC107 !important; border-left-width: 4px !important;" variant="flat" @click="handleCardClick(order, 'tobe')">
                            <div class="pa-2">
                                <div class="d-flex justify-space-between"><span class="pill-ref">#{{ order.order_number }}</span><v-icon v-if="canManageDelivery" size="14" class="opacity-50">mdi-drag</v-icon></div>
                                <div class="text-caption font-weight-bold text-truncate my-1">{{ order.customer_name }}</div>
                                <div class="text-[10px] font-mono opacity-80">{{ getOrderDisplayMeters(order) }}m</div>
                            </div>
                        </v-card>
                    </div>
                  </template>
                </draggable>
             </div>

             <div class="flex-grow-1 d-flex flex-column bg-pattern-grid">
                <div class="d-grid grid-cols-7 border-b text-center" :class="dividerClass">
                    <div v-for="dayName in ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb']" :key="dayName" class="py-2 text-[10px] font-weight-black text-uppercase opacity-60">
                        {{ dayName }}
                    </div>
                </div>
                <div class="d-grid grid-cols-7 flex-grow-1 overflow-y-auto custom-scroll" style="grid-auto-rows: minmax(120px, 1fr);">
                    <div v-for="day in calendarDays" :key="day.dateStr"
                         class="calendar-cell border-r border-b d-flex flex-column relative"
                         :class="[
                            dividerClass,
                            !day.isCurrentMonth ? 'opacity-40 bg-stripes' : '',
                            isToday(day.date) ? (themeStore.currentMode === 'light' ? 'bg-blue-lighten-5' : 'bg-blue-grey-darken-4') : ''
                         ]"
                         style="overflow: hidden;"
                    >
                        <div class="d-flex justify-space-between pa-2 align-center flex-shrink-0">
                            <span class="text-caption font-weight-black" :class="{'text-primary text-h6': isToday(day.date)}">{{ format(day.date, 'd') }}</span>
                            <span v-if="day.orders.length > 0" class="text-[9px] font-mono font-weight-bold opacity-60">{{ getDayTotalMeters(day.orders) }}m</span>
                        </div>

                        <div class="flex-grow-1 overflow-y-auto custom-scroll px-1 pb-1">
                            <draggable
                              :list="day.orders"
                              :group="{ name: 'orders', pull: true, put: true }"
                              item-key="id"
                              class="d-flex flex-column gap-1 h-100"
                              :data-date="day.dateStr"
                              ghost-class="ghost-card"
                              :disabled="!canManageDelivery"
                              @end="onDragEnd"
                            >
                               <template #item="{ element: order }">
                                  <div class="relative group w-100" :class="canManageDelivery ? 'cursor-grab' : 'cursor-pointer'" :data-id="order.id" @click.stop="openDetailModal(order.id)">
                                      <div class="rounded px-2 py-1 mb-1 border-l-2 text-[10px] font-weight-bold shadow-sm transition-all hover:scale-[1.02] w-100"
                                           :class="[
                                             themeStore.currentMode === 'light' ? 'bg-white' : 'bg-surface-card',
                                             order.delivery_confirmed_at ? 'border-green-500 opacity-60' : 'border-blue-500'
                                           ]">
                                          <div class="text-truncate w-100 d-block">{{ order.customer_name }}</div>
                                      </div>
                                  </div>
                               </template>
                            </draggable>
                        </div>
                    </div>
                </div>
             </div>
          </div>

        </v-card>
      </div>

      <v-snackbar v-model="feedbackSnackbar.show" :timeout="3000" location="bottom right" :color="feedbackSnackbar.color" class="mb-4 mr-4" variant="elevated">
        <div class="d-flex align-center gap-3">
          <v-icon :icon="feedbackSnackbar.icon" color="white"></v-icon>
          <span class="font-weight-bold text-white">{{ feedbackSnackbar.message }}</span>
        </div>
      </v-snackbar>

      <v-snackbar v-model="showUndoSnackbar" :timeout="5000" location="bottom center" color="grey-darken-3" class="mb-4">
        <div class="d-flex align-center gap-2">
          <v-icon color="success">mdi-check-circle</v-icon>
          <span class="font-weight-bold">Itens movidos com sucesso!</span>
        </div>
        <template v-slot:actions>
          <v-btn color="warning" variant="text" class="font-weight-black" @click="undoLastBatchMove"><v-icon start>mdi-undo</v-icon> Desfazer</v-btn>
          <v-btn color="white" variant="icon" icon="mdi-close" @click="showUndoSnackbar = false"></v-btn>
        </template>
      </v-snackbar>

      <v-dialog v-model="showHistoryModal" max-width="1200" transition="dialog-bottom-transition" :scrim="true" persistent class="history-modal">
        <v-card class="d-flex flex-column overflow-hidden history-card rounded-0 fill-height" :class="isLightMode ? 'bg-grey-lighten-5' : 'bg-surface-modal'">

            <div class="header-bar px-6 py-4 d-flex align-center justify-space-between flex-shrink-0" :class="isLightMode ? 'bg-white border-b border-grey-lighten-2' : 'bg-glass-header border-bottom-white-05'">
                <div class="d-flex flex-column">
                  <div class="breadcrumb text-caption"><span class="opacity-70">Logística</span><span class="mx-2 opacity-50">&gt;</span><span class="font-weight-bold">Registros</span></div>
                  <div class="text-h6 font-weight-black tracking-tight leading-none mt-1" :class="textPrimaryClass">Histórico de Entregas</div>
                </div>
                <v-btn icon="mdi-close" variant="text" size="large" @click="showHistoryModal = false" :color="textSecondaryColor"></v-btn>
            </div>

            <div class="px-6 pt-4 pb-2 flex-shrink-0">
               <div class="controls-bar d-flex align-center justify-space-between" :class="isLightMode ? 'controls-light' : 'controls-dark'">
                  <div class="d-flex align-center flex-wrap" style="gap: 10px;">
                      <div class="search-wrap d-flex align-center" :class="isLightMode ? 'search-light' : 'search-dark'">
                        <v-icon :color="isLightMode ? 'grey-darken-1' : 'white-70'">mdi-magnify</v-icon>
                        <input v-model="historySearch" type="text" placeholder="Buscar por cliente, pedido..." class="clean-input flex-grow-1"/>
                      </div>
                      <v-autocomplete v-model="selectedFabrics" :items="fabricTypesForFilter" placeholder="Filtrar por Tecido" variant="outlined" density="compact" hide-details multiple chips closable-chips class="filter-select" style="min-width: 220px;" :bg-color="isLightMode ? 'white' : 'transparent'"></v-autocomplete>
                      <v-switch v-model="historyFilterMyOrders" label="Meus Pedidos" density="compact" hide-details color="success" inset class="ml-2 font-weight-bold text-caption" :class="textPrimaryClass"></v-switch>
                  </div>
                  <v-btn color="success" variant="flat" class="btn-rect font-weight-bold" prepend-icon="mdi-file-export" @click="generateHistoryReport">Exportar</v-btn>
               </div>
            </div>

            <div class="px-6 py-3 flex-shrink-0">
                <v-row dense>
                    <v-col cols="12" md="4">
                        <v-card class="kpi-card kpi-rect bg-gradient-info py-3 px-4" elevation="2">
                            <div class="kpi-bg-icon"><v-icon>mdi-truck-check</v-icon></div>
                            <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                                <div class="d-flex align-center gap-2"><v-icon size="18" class="opacity-80">mdi-truck-check</v-icon><span class="kpi-label">Entregues</span></div>
                                <div class="kpi-number-group my-1"><span class="kpi-value">{{ filteredDeliveredOrders.length }}</span><span class="text-caption ml-2 opacity-80">pedidos</span></div>
                                <div class="kpi-footer">Total Geral</div>
                            </div>
                        </v-card>
                    </v-col>
                    <v-col cols="12" md="4">
                        <v-card class="kpi-card kpi-rect bg-gradient-purple py-3 px-4" elevation="2">
                            <div class="kpi-bg-icon"><v-icon>mdi-ruler</v-icon></div>
                            <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                                <div class="d-flex align-center gap-2"><v-icon size="18" class="opacity-80">mdi-ruler</v-icon><span class="kpi-label">Volume Total</span></div>
                                <div class="kpi-number-group my-1"><span class="kpi-value">{{ historyTotalMeters }}</span><span class="text-caption ml-2 opacity-80">metros</span></div>
                                <div class="kpi-footer">Processado</div>
                            </div>
                        </v-card>
                    </v-col>
                    <v-col cols="12" md="4">
                        <v-card class="kpi-card kpi-rect bg-gradient-green py-3 px-4" elevation="2">
                            <div class="kpi-bg-icon"><v-icon>mdi-calendar-check</v-icon></div>
                            <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                                <div class="d-flex align-center gap-2"><v-icon size="18" class="opacity-80">mdi-calendar-check</v-icon><span class="kpi-label">No Prazo</span></div>
                                <div class="kpi-number-group my-1"><span class="kpi-value">{{ historyOnTimePercentage }}%</span></div>
                                <div class="kpi-footer">Taxa de Eficiência</div>
                            </div>
                        </v-card>
                    </v-col>
                </v-row>
            </div>

            <div class="flex-grow-1 px-6 pb-2 overflow-hidden d-flex flex-column">
                <v-card class="flex-grow-1 d-flex flex-column rounded-0 border-thin overflow-hidden" :class="isLightMode ? 'bg-white shadow-sm' : 'glass-card border-white-05'" :elevation="0">
                    <div class="grid-scroll flex-grow-1 overflow-y-auto custom-scroll">
                        <div class="grid-header sticky-head" :class="isLightMode ? 'grid-surface-light' : 'grid-surface-dark'">
                             <div class="cell center header-text" style="width: 80px;">Ref.</div>
                             <div class="cell header-text flex-grow-1">Cliente / Detalhes</div>
                             <div class="cell center header-text" style="width: 140px;">Data Entrega</div>
                             <div class="cell center header-text" style="width: 120px;">Metragem</div>
                             <div class="cell header-text" style="width: 180px;">Vendedor</div>
                             <div class="cell center header-text" style="width: 120px;">Ações</div>
                        </div>

                        <div v-if="filteredDeliveredOrders.length === 0" class="d-flex flex-column justify-center align-center h-100 opacity-60 gap-2 py-10">
                            <v-icon size="48" color="grey-lighten-1">mdi-file-hidden</v-icon>
                            <span class="text-body-2 font-weight-medium text-grey">Nenhum registro encontrado</span>
                        </div>

                        <div v-else v-for="(item, index) in paginatedHistoryItems" :key="item.id" class="grid-row" :class="[isLightMode ? 'grid-row-light' : 'grid-row-dark']">
                             <div class="cell center" style="width: 80px;">
                                 <span class="pill-ref">{{ String(item.order_number).padStart(4,'0') }}</span>
                             </div>
                             <div class="cell flex-grow-1">
                                 <div class="d-flex flex-column">
                                     <span class="text-body-2 font-weight-bold text-truncate">{{ item.customer_name }}</span>
                                     <span class="text-[10px] opacity-70">{{ item.details?.fabric_type || 'Diversos' }}</span>
                                 </div>
                             </div>
                             <div class="cell center" style="width: 140px;">
                                 <div class="d-flex align-center gap-2">
                                    <div class="icon-circle-small bg-green-lighten-5 text-success"><v-icon size="14">mdi-calendar-check</v-icon></div>
                                    <span class="font-weight-bold font-mono text-[11px]">{{ formatDate(item.actual_delivery_date, 'dd/MM/yyyy') }}</span>
                                 </div>
                             </div>
                             <div class="cell center" style="width: 120px;">
                                 <span class="font-mono font-weight-black text-[11px]">{{ getOrderDisplayMeters(item) }}m</span>
                             </div>
                             <div class="cell" style="width: 180px;">
                                 <div class="d-flex align-center gap-2">
                                     <v-avatar size="22" :color="isLightMode ? 'grey-lighten-3' : 'grey-darken-3'" class="text-caption font-weight-bold">{{ item.creator?.full_name?.charAt(0) }}</v-avatar>
                                     <span class="text-[11px] font-weight-bold opacity-80">{{ item.creator?.full_name?.split(' ')[0] }}</span>
                                 </div>
                             </div>
                             <div class="cell center" style="width: 120px;">
                                 <div class="actions-inline">
                                     <v-btn icon size="small" class="action-btn action-edit" @click.stop="openDetailModal(item.id)" title="Ver" variant="flat"><v-icon size="18">mdi-eye</v-icon></v-btn>
                                     <v-btn v-if="canManageDelivery" icon size="small" class="action-btn action-revert" @click.stop="rejectDelivery(item)" title="Estornar" variant="flat"><v-icon size="18">mdi-undo-variant</v-icon></v-btn>
                                 </div>
                             </div>
                        </div>
                    </div>

                    <div class="flex-shrink-0 border-t px-4 py-2 d-flex align-center justify-space-between" :class="isLightMode ? 'bg-grey-lighten-5' : 'bg-white-05'">
                        <div class="text-caption opacity-80">Total: <strong>{{ filteredDeliveredOrders.length }}</strong> registros</div>
                        <v-pagination v-model="page" :length="pageCount" :total-visible="5" density="compact" active-color="success" variant="tonal" size="small"></v-pagination>
                    </div>
                </v-card>
            </div>
        </v-card>
      </v-dialog>

      <v-dialog v-model="showDeleteConfirmModal" max-width="400px" content-class="glass-modal-content">
        <v-card class="rounded-xl pa-6 text-center position-relative overflow-hidden" :class="isLightMode ? 'bg-white' : 'bg-surface-card'">
          <div class="trash-animation-wrapper mb-4"><v-icon size="64" color="error" class="trash-icon-anim">mdi-delete-empty</v-icon></div>
          <h3 class="text-h6 font-weight-black mb-2" :class="textPrimaryClass">Excluir Pedido?</h3>
          <p class="text-body-2 opacity-70 mb-6" :class="textSecondaryClass">O pedido de <b>{{ selectedOrderForDelete?.customer_name }}</b> será movido para a lixeira.</p>
          <div class="d-flex justify-center gap-3"><v-btn variant="text" :color="textSecondaryColor" @click="closeDeleteConfirmModal">Cancelar</v-btn><v-btn color="error" variant="flat" class="font-weight-bold" @click="executeDeleteOrder" :loading="isDeleting">Confirmar Exclusão</v-btn></div>
        </v-card>
      </v-dialog>

      <v-dialog v-model="showForceCompleteModal" max-width="400px" content-class="glass-modal-content">
        <v-card class="rounded-xl pa-6 text-center" :class="isLightMode ? 'bg-white' : 'bg-surface-card'">
          <div class="icon-circle-lg bg-orange-lighten-5 mb-4 mx-auto"><v-icon size="32" color="warning">mdi-alert-octagon</v-icon></div>
          <h3 class="text-h6 font-weight-black mb-2" :class="textPrimaryClass">Forçar Conclusão?</h3>
          <p class="text-body-2 opacity-70 mb-6" :class="textSecondaryClass">Isso moverá o pedido de <b>{{ selectedOrderForForceComplete?.customer_name }}</b> direto para a expedição.</p>
          <div class="d-flex justify-center gap-3"><v-btn variant="text" :color="textSecondaryColor" @click="closeForceCompleteModal">Cancelar</v-btn><v-btn color="warning" variant="flat" class="font-weight-bold" @click="confirmForceComplete" :loading="isForcingComplete">Confirmar</v-btn></div>
        </v-card>
      </v-dialog>

      <v-dialog v-model="showCompleteAllItemsModal" max-width="400px" content-class="glass-modal-content">
        <v-card class="rounded-xl pa-6 text-center" :class="isLightMode ? 'bg-white' : 'bg-surface-card'">
          <div class="icon-circle-lg bg-blue-lighten-5 mb-4 mx-auto"><v-icon size="32" color="primary">mdi-check-all</v-icon></div>
          <h3 class="text-h6 font-weight-black mb-2" :class="textPrimaryClass">Concluir Produção?</h3>
          <p class="text-body-2 opacity-70 mb-6" :class="textSecondaryClass">Todos os itens de <b>{{ selectedOrderForCompletion?.customer_name }}</b> serão marcados como prontos.</p>
          <div class="d-flex justify-center gap-3"><v-btn variant="text" :color="textSecondaryColor" @click="closeCompleteAllItemsModal">Cancelar</v-btn><v-btn color="primary" variant="flat" class="font-weight-bold" @click="confirmCompleteAllItems" :loading="isCompletingAllItems">Confirmar</v-btn></div>
        </v-card>
      </v-dialog>

      <v-dialog v-model="showBatchMoveModal" max-width="400px" content-class="glass-modal-content">
        <v-card class="rounded-xl pa-5" :class="isLightMode ? 'bg-white' : 'bg-surface-card'">
          <h3 class="text-h6 font-weight-black mb-4" :class="textPrimaryClass">Mover {{ selectionMode.selected.length }} itens para:</h3>
          <v-list density="compact" class="bg-transparent">
            <v-list-item @click="executeBatchMove('ready')" class="mb-2 rounded-lg border" :class="isLightMode ? 'border-grey-lighten-2' : 'border-white-05'"><template v-slot:prepend><v-icon color="success">mdi-flash</v-icon></template><v-list-item-title class="font-weight-bold" :class="textPrimaryClass">Pronta Entrega</v-list-item-title></v-list-item>
            <v-list-item @click="executeBatchMove('tobe')" class="mb-2 rounded-lg border" :class="isLightMode ? 'border-grey-lighten-2' : 'border-white-05'"><template v-slot:prepend><v-icon color="warning">mdi-clipboard-clock</v-icon></template><v-list-item-title class="font-weight-bold" :class="textPrimaryClass">Aguardando Envio</v-list-item-title></v-list-item>
            <v-divider class="my-2"></v-divider>
            <div class="text-caption opacity-60 mb-2">Dias da Semana</div>
            <v-list-item v-for="day in weekDeliveryDays" :key="day.id" @click="executeBatchMove(day.date.toISOString())" class="mb-1 rounded-lg hover:bg-primary-opacity-10"><template v-slot:prepend><v-icon size="small" color="primary">mdi-calendar</v-icon></template><v-list-item-title :class="textSecondaryClass">{{ day.name }} ({{ formatDate(day.date, 'dd/MM') }})</v-list-item-title></v-list-item>
          </v-list>
        </v-card>
      </v-dialog>

      <OrderDetailModal :show="showDetailModal" :order-id="selectedOrderId" @close="showDetailModal = false"/>

    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, computed, onActivated, watch, reactive } from 'vue';
import { supabase } from '@/api/supabase';
import OrderDetailModal from '@/components/OrderDetailModal.vue';
import draggable from 'vuedraggable';
import { useUserStore } from '@/stores/user';
import { useDashboardStore } from '@/stores/dashboard';
import { useThemeStore } from '@/stores/theme';
import { storeToRefs } from 'pinia';
import { format, addDays, startOfWeek, endOfWeek, subDays, isToday, isValid, startOfMonth, endOfMonth, eachDayOfInterval, addMonths, subMonths, isSameDay, parseISO, isBefore } from 'date-fns';
import { ptBR } from 'date-fns/locale';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';

// Types
type OrderItem = { id: string; status: string; fabric_type: string; quantity_meters: number; billed_quantity: number | null; };
type Order = {
  id: string; customer_name: string; quantity_meters: number; status: string;
  is_launch: boolean; details: { fabric_type: string; } | null;
  actual_delivery_date: Date | null; delivery_confirmed_at: string | null;
  production_date: string | null;
  billed_at: string | null;
  order_number: number;
  order_items: OrderItem[];
  creator: { full_name: string; } | null;
  forecast_delivery_date?: string | null;
};

// State
const userStore = useUserStore();
const dashboardStore = useDashboardStore();
const themeStore = useThemeStore();
const { productionGhosts, loading } = storeToRefs(dashboardStore);

const viewMode = ref<'kanban' | 'calendar'>('kanban');

// Pagination State
const page = ref(1);
const itemsPerPage = 50;

// Feedback State
const feedbackSnackbar = reactive({
  show: false,
  message: '',
  color: 'success',
  icon: 'mdi-check-circle'
});

const showFeedback = (message: string, type: 'success' | 'warning' | 'error' = 'success') => {
  feedbackSnackbar.message = message;
  feedbackSnackbar.color = type === 'warning' ? 'warning' : (type === 'error' ? 'error' : 'success');
  feedbackSnackbar.icon = type === 'warning' ? 'mdi-alert' : (type === 'error' ? 'mdi-alert-circle' : 'mdi-check-circle');
  feedbackSnackbar.show = true;
};

// Theme Computed
const isLightMode = computed(() => themeStore.currentMode === 'light');
const textPrimaryClass = computed(() => isLightMode.value ? 'text-grey-darken-4' : 'text-white');
const textSecondaryClass = computed(() => isLightMode.value ? 'text-grey-darken-1' : 'text-white-70');
const textSecondaryColor = computed(() => isLightMode.value ? 'grey-darken-2' : 'white');
const dividerClass = computed(() => isLightMode.value ? 'border-grey-lighten-2' : 'border-white-05');

// Permissão Granular Dinâmica (Lê da Store)
const canManageDelivery = computed(() => {
  // Verifica se a role principal é ADMIN
  if (userStore.profile?.role === 'ADMIN') return true;

  // Verifica se o cargo customizado é PCP
  if (userStore.profile?.custom_role_id === 'PCP') return true;

  // Fallback para a permissão granular específica
  return userStore.hasPermission('log_delivery_manage');
});

const showDetailModal = ref(false);
const selectedOrderId = ref<string | null>(null);
const allOrders = ref<Order[]>([]);
const currentDeliveryWeekStart = ref(startOfWeek(new Date(), { weekStartsOn: 1 }));

// CALENDAR STATE
const currentCalendarMonth = ref(new Date());

const showHistoryModal = ref(false);
const historySearch = ref('');
const selectedFabrics = ref<string[]>([]);
const globalFilterFabric = ref<string | null>(null);
const historyFilterMyOrders = ref(false);

const showForceCompleteModal = ref(false);
const isForcingComplete = ref(false);
const selectedOrderForForceComplete = ref<Order | null>(null);

const showCompleteAllItemsModal = ref(false);
const isCompletingAllItems = ref(false);
const selectedOrderForCompletion = ref<Order | null>(null);

const showDeleteConfirmModal = ref(false);
const isDeleting = ref(false);
const selectedOrderForDelete = ref<Order | null>(null);

const showBatchMoveModal = ref(false);

// UNDO STATE
const lastBatchAction = ref<{ ids: string[], previousState: Map<string, any> } | null>(null);
const showUndoSnackbar = ref(false);

// SELECTION & BATCH
const selectionMode = reactive({
  active: false,
  column: null as string | null,
  selected: [] as string[]
});
const isBatchMoving = ref(false);

const startSelectionMode = (colId: string) => {
  selectionMode.active = true;
  selectionMode.column = colId;
  selectionMode.selected = [];
  isBatchMoving.value = false;
};

const exitSelectionMode = () => {
  selectionMode.active = false;
  selectionMode.column = null;
  selectionMode.selected = [];
  isBatchMoving.value = false;
};

const isColumnActive = (colId: string) => selectionMode.active && selectionMode.column === colId;

const handleCardClick = (order: Order, colId: string) => {
  if (isBatchMoving.value) return;

  if (!selectionMode.active) {
    openDetailModal(order.id);
  } else if (selectionMode.column === colId) {
    const idx = selectionMode.selected.indexOf(order.id);
    if (idx === -1) selectionMode.selected.push(order.id);
    else selectionMode.selected.splice(idx, 1);
  }
};

const handleColumnClick = (colId: string) => {
  if (isBatchMoving.value) {
    if (colId === 'ready') executeBatchMove('ready');
    else if (colId === 'tobe') executeBatchMove('tobe');
    else executeBatchMove(colId);
  }
};

const activateBatchMove = () => {
  if (selectionMode.selected.length) {
    isBatchMoving.value = true;
  }
};

const cancelBatchMove = () => {
  isBatchMoving.value = false;
};

const openBatchDeleteModal = () => { alert("Exclusão em massa em breve."); };

// EXECUTE BATCH MOVE
const executeBatchMove = async (target: string) => {
  const ids = selectionMode.selected;
  if (ids.length === 0) return;

  const currentSnapshot = new Map<string, any>();
  allOrders.value.filter(o => ids.includes(o.id)).forEach(o => {
    currentSnapshot.set(o.id, {
      status: o.status,
      actual_delivery_date: o.actual_delivery_date ? o.actual_delivery_date.toISOString() : null
    });
  });
  lastBatchAction.value = { ids: [...ids], previousState: currentSnapshot };

  const updateData: any = {};
  if (target === 'ready') {
    updateData.status = 'ready_for_delivery';
    updateData.actual_delivery_date = null;
  } else if (target === 'tobe') {
    updateData.status = 'completed';
    updateData.actual_delivery_date = null;
  } else {
    updateData.actual_delivery_date = target.includes('T') ? target : `${target}T12:00:00`;
  }

  try {
    const { error } = await supabase.from('orders').update(updateData).in('id', ids);
    if (error) throw error;

    await fetchDeliveryOrders();
    exitSelectionMode();
    showUndoSnackbar.value = true;
  } catch (e) { console.error(e); }
};

const undoLastBatchMove = async () => {
  if (!lastBatchAction.value) return;

  const { ids, previousState } = lastBatchAction.value;
  showUndoSnackbar.value = false;

  try {
    const updates = ids.map(id => {
      const prevState = previousState.get(id);
      if (!prevState) return null;
      return {
        id: id,
        status: prevState.status,
        actual_delivery_date: prevState.actual_delivery_date
      };
    }).filter(u => u !== null);

    if (updates.length > 0) {
      const { error } = await supabase.from('orders').upsert(updates as any);
      if (error) throw error;
      await fetchDeliveryOrders();
    }
  } catch (e) { console.error('Erro ao desfazer:', e); }
};

const getZebraColumnClass = (index: number, date: Date) => {
    if (isToday(date)) return isLightMode.value ? 'bg-blue-lighten-5' : 'bg-blue-grey-darken-4';
    if (isLightMode.value) {
        return index % 2 === 0 ? 'bg-grey-lighten-5' : 'bg-white';
    } else {
        return index % 2 === 0 ? 'bg-surface-card-alt' : 'bg-transparent';
    }
}

// DATA PROCESSING
const readyForDeliveryOrders = computed(() => {
  let orders = allOrders.value.filter(o => o.status === 'ready_for_delivery' && !o.actual_delivery_date);
  if (globalFilterFabric.value) {
    orders = orders.filter(o => filterOrderByFabric(o, globalFilterFabric.value!));
  }
  return orders;
});

const filteredReadyOrders = computed(() => readyForDeliveryOrders.value);

const toBeScheduledOrders = computed(() => {
  let orders = allOrders.value.filter(o => o.status === 'completed' && !o.actual_delivery_date);
  if (globalFilterFabric.value) {
    orders = orders.filter(o => filterOrderByFabric(o, globalFilterFabric.value!));
  }
  return orders;
});

const filteredToBeScheduledOrders = computed(() => toBeScheduledOrders.value);

const scheduledOrders = computed(() => allOrders.value.filter(o => !!o.actual_delivery_date));

const deliveredOrders = computed(() => {
  return scheduledOrders.value.filter(o => o.delivery_confirmed_at)
    .sort((a,b) => (b.actual_delivery_date?.getTime() || 0) - (a.actual_delivery_date?.getTime() || 0));
});

const filteredDeliveredOrders = computed(() => {
    let list = deliveredOrders.value;
    if (historySearch.value) {
        const term = historySearch.value.toLowerCase();
        list = list.filter(o =>
            o.customer_name.toLowerCase().includes(term) ||
            String(o.order_number).includes(term)
        );
    }
    if (historyFilterMyOrders.value && userStore.profile?.full_name) {
        list = list.filter(o => o.creator?.full_name === userStore.profile?.full_name);
    }
    if (selectedFabrics.value.length > 0) {
        list = list.filter(o => selectedFabrics.value.some(f => filterOrderByFabric(o, f)));
    }
    return list;
});

// Pagination Logic
const pageCount = computed(() => Math.ceil(filteredDeliveredOrders.value.length / itemsPerPage));
const paginatedHistoryItems = computed(() => {
    const start = (page.value - 1) * itemsPerPage;
    const end = start + itemsPerPage;
    return filteredDeliveredOrders.value.slice(start, end);
});

watch([historySearch, selectedFabrics, historyFilterMyOrders], () => { page.value = 1; });

// History KPIs
const historyTotalMeters = computed(() => {
    return filteredDeliveredOrders.value.reduce((acc, order) => acc + (order.quantity_meters || 0), 0).toLocaleString('pt-BR');
});

const historyOnTimePercentage = computed(() => {
    const total = filteredDeliveredOrders.value.length;
    if (total === 0) return 100;
    const onTime = filteredDeliveredOrders.value.filter(o => {
        if (!o.actual_delivery_date || !o.delivery_confirmed_at) return false;
        return isSameDay(o.actual_delivery_date, parseISO(o.delivery_confirmed_at));
    }).length;
    return Math.round((onTime / total) * 100);
});

const filterOrderByFabric = (order: Order, fabric: string) => {
  if (order.is_launch) return order.order_items.some(i => i.fabric_type === fabric);
  return order.details?.fabric_type === fabric;
};

const getOrderDisplayMeters = (order: any) => {
  if (order.is_launch && order.order_items?.length > 0) {
    return order.order_items.reduce((sum: number, item: any) => sum + (item.billed_quantity || item.quantity_meters || 0), 0);
  }
  return order.quantity_meters;
};

const getGhostEntriesForDay = (date: Date) => {
  let ghosts = productionGhosts.value.filter(ghost =>
    ghost.forecast_delivery_date &&
    isValid(ghost.forecast_delivery_date) &&
    isSameDay(ghost.forecast_delivery_date, date)
  );
  if (globalFilterFabric.value) {
    ghosts = ghosts.filter(g => g.details?.fabric_type === globalFilterFabric.value);
  }
  return ghosts;
};

const getDayTotalMeters = (orders: Order[]) => {
  const total = orders.reduce((sum, order) => sum + getOrderDisplayMeters(order), 0);
  return total.toLocaleString('pt-BR');
};

const weekDeliveryDays = computed(() => {
  const weekStart = currentDeliveryWeekStart.value;
  const days = [
    { name: 'Segunda-feira', dayOfWeek: 1 },
    { name: 'Terça-feira', dayOfWeek: 2 },
    { name: 'Quarta-feira', dayOfWeek: 3 },
    { name: 'Quinta-feira', dayOfWeek: 4 },
    { name: 'Sexta-feira', dayOfWeek: 5 },
    { name: 'Sábado', dayOfWeek: 6 },
  ];
  return days.map(dayInfo => {
    let currentDate = addDays(weekStart, dayInfo.dayOfWeek - 1);
    let dayOrders = scheduledOrders.value.filter(o => o.actual_delivery_date && isSameDay(o.actual_delivery_date, currentDate));

    if (globalFilterFabric.value) {
      dayOrders = dayOrders.filter(o => filterOrderByFabric(o, globalFilterFabric.value!));
    }

    return {
      id: currentDate.toISOString().split('T')[0],
      name: dayInfo.name, date: currentDate,
      orders: dayOrders
    };
  });
});

const calendarDays = computed(() => {
    const monthStart = startOfMonth(currentCalendarMonth.value);
    const monthEnd = endOfMonth(currentCalendarMonth.value);
    const startDate = startOfWeek(monthStart, { weekStartsOn: 0 });
    const endDate = endOfWeek(monthEnd, { weekStartsOn: 0 });

    const interval = eachDayOfInterval({ start: startDate, end: endDate });

    return interval.map(date => {
        const isCurrentMonth = isSameDay(date, monthStart) || (isBefore(date, monthEnd) && !isBefore(date, monthStart)) || isSameDay(date, monthEnd);
        let dayOrders = scheduledOrders.value.filter(o => o.actual_delivery_date && isSameDay(o.actual_delivery_date, date));

        if (globalFilterFabric.value) {
          dayOrders = dayOrders.filter(o => filterOrderByFabric(o, globalFilterFabric.value!));
        }

        return {
            date,
            dateStr: format(date, 'yyyy-MM-dd'),
            isCurrentMonth,
            orders: dayOrders
        };
    });
});

const weekRangeText = computed(() => `${format(currentDeliveryWeekStart.value, 'dd MMM', { locale: ptBR })} - ${format(endOfWeek(currentDeliveryWeekStart.value, { weekStartsOn: 1 }), 'dd MMM', { locale: ptBR })}`);
const calendarMonthText = computed(() => format(currentCalendarMonth.value, 'MMMM yyyy', { locale: ptBR }));

const nextWeek = () => currentDeliveryWeekStart.value = addDays(currentDeliveryWeekStart.value, 7);
const previousWeek = () => currentDeliveryWeekStart.value = subDays(currentDeliveryWeekStart.value, 7);

const nextMonth = () => currentCalendarMonth.value = addMonths(currentCalendarMonth.value, 1);
const previousMonth = () => currentCalendarMonth.value = subMonths(currentCalendarMonth.value, 1);
const goToToday = () => {
    currentCalendarMonth.value = new Date();
    currentDeliveryWeekStart.value = startOfWeek(new Date(), { weekStartsOn: 1 });
}

const onDragEnd = async (event: any) => {
  if (!canManageDelivery.value) return;

  const { item, to } = event;
  const orderId = item.dataset.id;
  const newDateStr = to.dataset.date;
  if (!orderId) return;

  const targetIsSchedule = !!newDateStr;
  let newDateObj: Date | null = null;
  if (targetIsSchedule && newDateStr) {
      const [y, m, d] = newDateStr.split('-').map(Number);
      newDateObj = new Date(y, m - 1, d);
  }

  const orderIndex = allOrders.value.findIndex(o => o.id === orderId);
  if (orderIndex !== -1) {
    allOrders.value[orderIndex].actual_delivery_date = newDateObj;
  }

  try {
    const datePayload = targetIsSchedule ? `${newDateStr}T12:00:00` : null;
    const { error } = await supabase.from('orders').update({ actual_delivery_date: datePayload }).eq('id', orderId);

    if (error) {
        throw error;
    }
    await fetchDeliveryOrders();
  } catch (err: any) {
    console.error('Erro ao mover pedido:', err);
    await fetchDeliveryOrders();
    showFeedback("Erro ao mover pedido", 'error');
  }
};

const confirmDelivery = async (order: Order) => {
  if (!canManageDelivery.value) return;
  try {
    const { error } = await supabase.from('orders').update({ delivery_confirmed_at: new Date().toISOString(), status: 'delivered' }).eq('id', order.id);
    if (error) throw error;
    await fetchDeliveryOrders();
    showFeedback("Entrega confirmada!", 'success');
  } catch (err: any) {
      console.error('Erro ao confirmar entrega:', err.message);
      showFeedback("Erro ao confirmar entrega", 'error');
  }
};

const rejectDelivery = async (order: any) => {
  if (!canManageDelivery.value) return;
  try {
    const newStatus = 'completed';
    const { error } = await supabase.from('orders').update({ delivery_confirmed_at: null, actual_delivery_date: null, status: newStatus }).eq('id', order.id);
    if (error) throw error;
    await fetchDeliveryOrders();
    showFeedback("Entrega revertida! Pedido voltou para 'Agendar'.", 'warning');
  } catch (err: any) {
      console.error('Erro ao cancelar entrega:', err.message);
      showFeedback("Erro ao reverter", 'error');
  }
};

const confirmDeleteOrder = (order: Order) => {
  selectedOrderForDelete.value = order;
  showDeleteConfirmModal.value = true;
};

const closeDeleteConfirmModal = () => {
  showDeleteConfirmModal.value = false;
  selectedOrderForDelete.value = null;
};

const executeDeleteOrder = async () => {
  if (!selectedOrderForDelete.value) return;
  isDeleting.value = true;
  try {
    const { error } = await supabase.from('orders').update({ status: 'archived' }).eq('id', selectedOrderForDelete.value.id);
    if (error) throw error;
    await fetchDeliveryOrders();
    closeDeleteConfirmModal();
    showFeedback("Pedido excluído", 'success');
  } catch (err: any) {
    console.error('Erro ao excluir pedido:', err.message);
    showFeedback("Erro ao excluir", 'error');
  } finally {
    isDeleting.value = false;
  }
};

const generateColumnReport = (orders: Order[], title: string) => {
  if (!orders.length) return;
  const doc = new jsPDF();
  doc.setFontSize(16).setFont('helvetica', 'bold');
  doc.text(`Relatório: ${title}`, 15, 15);
  doc.setFontSize(10).setFont('helvetica', 'normal');
  doc.text(`Gerado em: ${format(new Date(), 'dd/MM/yyyy HH:mm')}`, 15, 22);

  const body = orders.map(o => [
    `#${String(o.order_number).padStart(4,'0')}`,
    o.customer_name,
    o.details?.fabric_type || (o.is_launch ? 'Lançamento' : '-'),
    `${getOrderDisplayMeters(o)}m`,
    o.creator?.full_name || '-'
  ]);

  autoTable(doc, {
    head: [['ID', 'Cliente', 'Tecido', 'Qtd', 'Vendedor']],
    body,
    startY: 30,
    theme: 'striped',
    headStyles: { fillColor: [40, 40, 40] }
  });

  doc.save(`relatorio_${title.replace(/[^a-z0-9]/gi, '_').toLowerCase()}.pdf`);
};

const generateHistoryReport = () => {
  const doc = new jsPDF();
  doc.text("Histórico de Entregas", 15, 15);
  const body = filteredDeliveredOrders.value.map(o => [
    formatDate(o.actual_delivery_date, 'dd/MM/yyyy'),
    o.customer_name,
    `${getOrderDisplayMeters(o)}m`,
    o.creator?.full_name
  ]);
  autoTable(doc, {
    head: [['Data', 'Cliente', 'Qtd', 'Vendedor']],
    body, startY: 25,
  });
  doc.save('historico_entregas.pdf');
};

const openDetailModal = (orderId: string) => { selectedOrderId.value = orderId; showDetailModal.value = true; };
const openHistoryModal = () => { showHistoryModal.value = true; };

const formatDate = (date: Date | string | null | undefined, formatString: string) => {
  if (!date) return '';
  const dateObj = typeof date === 'string' ? parseISO(date) : new Date(date);
  if (!isValid(dateObj)) return '-';
  return format(dateObj, formatString, { locale: ptBR });
};

const fetchDeliveryOrders = async () => {
  const { data, error } = await supabase
    .from('orders')
    .select(`
      id, customer_name, quantity_meters, status, is_launch, details, production_date, billed_at, order_number,
      creator:created_by(full_name),
      actual_delivery_date, delivery_confirmed_at,
      order_items(id, status, fabric_type, quantity_meters, billed_quantity)
    `)
    .in('status', ['completed', 'delivered', 'ready_for_delivery']);

  if (error) throw error;
  allOrders.value = (data || []).map((o: any) => ({ ...o, actual_delivery_date: o.actual_delivery_date ? parseISO(o.actual_delivery_date) : null }));
};

const openForceCompleteModal = (order: any) => { selectedOrderForForceComplete.value = order; showForceCompleteModal.value = true; };
const closeForceCompleteModal = () => { showForceCompleteModal.value = false; selectedOrderForForceComplete.value = null; };

const confirmForceComplete = async () => {
  if (!selectedOrderForForceComplete.value || !userStore.profile?.id) return;
  isForcingComplete.value = true;
  try {
    const { error } = await supabase.rpc('forcar_conclusao_pedido', {
      p_order_id: selectedOrderForForceComplete.value.id,
      p_admin_id: userStore.profile.id
    });
    if (error) throw error;
    await fetchDeliveryOrders(); await dashboardStore.fetchData(); closeForceCompleteModal();
    showFeedback("Conclusão forçada com sucesso", 'success');
  } catch (err: any) { console.error(err); showFeedback("Erro ao forçar conclusão", 'error'); } finally { isForcingComplete.value = false; }
};

const openCompleteAllItemsModal = (order: Order) => {
  selectedOrderForCompletion.value = order;
  showCompleteAllItemsModal.value = true;
};
const closeCompleteAllItemsModal = () => { showCompleteAllItemsModal.value = false; selectedOrderForCompletion.value = null; };

const confirmCompleteAllItems = async () => {
  if (!selectedOrderForCompletion.value || !userStore.profile?.id) return;
  isCompletingAllItems.value = true;
  try {
    const { error } = await supabase.rpc('concluir_todos_itens_pedido', { p_order_id: selectedOrderForCompletion.value.id, p_user_id: userStore.profile.id });
    if (error) throw error;
    await fetchDeliveryOrders(); await dashboardStore.fetchData(); closeCompleteAllItemsModal();
    showFeedback("Itens concluídos", 'success');
  } catch (err: any) { console.error(err); showFeedback("Erro ao concluir itens", 'error'); } finally { isCompletingAllItems.value = false; }
};

const fabricTypesForFilter = computed(() => {
  const fabrics = new Set<string>();
  allOrders.value.forEach(order => {
    if (order.is_launch) order.order_items.forEach(item => { if (item.fabric_type) fabrics.add(item.fabric_type); });
    else if (order.details?.fabric_type) fabrics.add(order.details.fabric_type);
  });
  return Array.from(fabrics).sort();
});

onActivated(() => { fetchDeliveryOrders(); dashboardStore.fetchData(); });
onMounted(() => { fetchDeliveryOrders(); dashboardStore.fetchData(); });
</script>

<style scoped lang="scss">
.delivery-layout { position: relative; }
.background-carousel-wrapper { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 0; opacity: 0.6; pointer-events: none; }
.background-overlay { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 1; background: radial-gradient(circle at center, rgba(15, 15, 19, 0.4), rgba(15, 15, 19, 0.98)); backdrop-filter: blur(8px); }
.z-10 { position: relative; z-index: 10; }

.bg-glass-dark { background: rgba(10,10,12,0.85); }
.bg-glass-header { background: rgba(20,20,24,0.55); backdrop-filter: blur(14px); }
.border-bottom-white-05 { border-bottom: 1px solid rgba(255,255,255,0.08); }
.border-thin { border: 1px solid rgba(0,0,0,0.08); }
.bg-white-05 { background: rgba(255,255,255,0.05); }

.btn-rect { border-radius: 0 !important; text-transform: none !important; font-weight: 800; }
.icon-rect { border-radius: 0 !important; }

/* Controls Bar */
.controls-bar { border: 1px solid rgba(0,0,0,0.08); border-radius: 0; padding: 10px; }
.controls-light { background: #ffffff; }
.controls-dark { background: rgba(30,30,35,0.55); backdrop-filter: blur(16px); border: 1px solid rgba(255,255,255,0.08); }

.period-nav { border-radius: 0; height: 40px; overflow: hidden; }
.period-nav-light { border: 1px solid rgba(0,0,0,0.12); background: #fafafa; }
.period-nav-dark { border: 1px solid rgba(255,255,255,0.10); background: rgba(255,255,255,0.06); }
.period-label { min-width: 190px; display: flex; align-items: center; justify-content: center; height: 40px; }

/* Inputs */
.filter-select :deep(.v-field) { border-radius: 0 !important; }
.filter-select :deep(.v-field__input) { min-height: 40px !important; padding-top: 8px !important; font-size: 13px; font-weight: bold; }
.search-wrap {
  height: 40px;
  border-radius: 0;
  padding: 0 12px;
  min-width: 300px;
  flex: 1;
}
.search-light { background: #f4f6f8; border: 1px solid rgba(0,0,0,0.08); }
.search-dark { background: rgba(255,255,255,0.08); border: 1px solid rgba(255,255,255,0.10); }

.clean-input {
  border: none;
  outline: none;
  background: transparent;
  font-size: 12px;
  color: inherit;
}

/* Kanban Styles */
.kanban-container { gap: 0; }
.kanban-column { min-width: 280px; width: 280px; flex-shrink: 0; transition: all 0.2s ease; }
.column-elevated { z-index: 100 !important; position: relative; }

/* Calendar Styles */
.d-grid { display: grid; }
.grid-cols-7 { grid-template-columns: repeat(7, 1fr); }
.calendar-cell { min-height: 120px; transition: background 0.2s; }
.bg-stripes { background-image: repeating-linear-gradient(45deg, transparent, transparent 10px, rgba(0,0,0,0.03) 10px, rgba(0,0,0,0.03) 20px); }

/* Specific Column Colors */
.bg-green-darken-4-alpha { background: rgba(27, 94, 32, 0.25); }
.bg-orange-darken-4-alpha { background: rgba(230, 81, 0, 0.2); }
.bg-surface-card-alt { background-color: rgba(255, 255, 255, 0.02); }

.glass-card { background: rgba(30, 30, 35, 0.45); backdrop-filter: blur(25px); border: 1px solid rgba(255,255,255,0.08); }
.bg-surface-card { background-color: rgba(255, 255, 255, 0.05); }
.border-white-05 { border-color: rgba(255,255,255,0.05) !important; }

/* Scrollbars */
.custom-scroll::-webkit-scrollbar { width: 6px; height: 6px; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.35); border-radius: 6px; }
.custom-scroll::-webkit-scrollbar-track { background: transparent; }
.custom-scroll-x::-webkit-scrollbar { height: 8px; }
.custom-scroll-x::-webkit-scrollbar-track { background: transparent; }
.custom-scroll-x::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.35); border-radius: 6px; }

/* Production Card Style (Identidade Unificada) */
.production-card { transition: transform 0.2s, box-shadow 0.2s; position: relative; cursor: pointer; }
.production-card:hover { transform: translateY(-2px); box-shadow: 0 4px 12px rgba(0,0,0,0.15) !important; z-index: 2; }

.pill-ref { font-size: 9px; font-weight: 900; font-family: monospace; background: rgba(0,0,0,0.08); padding: 2px 6px; border-radius: 4px; }
.status-dot { width: 8px; height: 8px; border-radius: 50%; display: inline-block; }
.pulsing-dot { animation: pulse-opacity 2s infinite; }
@keyframes pulse-opacity { 0%, 100% { opacity: 1; } 50% { opacity: 0.5; } }

.cursor-grab { cursor: grab; }
.cursor-grab:active { cursor: grabbing; }
.ghost-card { opacity: 0.5; border: 2px dashed rgba(var(--v-theme-primary), 0.5) !important; background: transparent !important; box-shadow: none !important; }
.lh-1 { line-height: 1 !important; }

/* Batch Move */
.batch-move-banner {
    position: fixed; top: 20px; left: 50%; transform: translateX(-50%);
    padding: 12px 32px; border-radius: 50px; z-index: 9999 !important; min-width: 300px;
}
.focus-overlay {
    position: absolute; top: 0; left: 0; right: 0; bottom: 0; background: rgba(0, 0, 0, 0.5); backdrop-filter: blur(4px); z-index: 50; pointer-events: auto;
}
.target-overlay {
    position: absolute; top: 0; left: 0; right: 0; bottom: 0; background-color: rgba(255, 255, 255, 0.2); backdrop-filter: blur(2px); z-index: 2005; cursor: pointer; border: 3px dashed rgb(var(--v-theme-primary)); opacity: 0; transition: opacity 0.3s ease; animation: fadeIn 0.3s forwards;
}
@keyframes fadeIn { to { opacity: 1; } }
.floating-action-menu { position: absolute; top: 60px; right: -140px; width: 130px; padding: 12px; border-radius: 12px; box-shadow: 0 10px 30px rgba(0,0,0,0.3); z-index: 1001; }

.animate-bounce { animation: bounce 1s infinite; }
@keyframes bounce { 0%, 100% { transform: translateY(0); } 50% { transform: translateY(-5px); } }

/* History Modal Styling */
.history-modal .history-card { border-radius: 0; box-shadow: 0 12px 30px rgba(0,0,0,0.12); overflow: hidden; }
.bg-surface-modal { background-color: #1E1E24; }
.icon-circle-lg { width: 64px; height: 64px; border-radius: 50%; display: flex; align-items: center; justify-content: center; }
.icon-circle-small { width: 24px; height: 24px; border-radius: 50%; display: flex; align-items: center; justify-content: center; }
.glass-modal-content { backdrop-filter: blur(20px) !important; background-color: rgba(30, 30, 30, 0.95) !important; box-shadow: 0 25px 50px -12px rgba(0,0,0,0.5); }
.trash-icon-anim { animation: shake 0.8s cubic-bezier(.36,.07,.19,.97) both infinite; }
@keyframes shake { 10%, 90% { transform: translate3d(-1px, 0, 0); } 20%, 80% { transform: translate3d(2px, 0, 0); } 30%, 50%, 70% { transform: translate3d(-4px, 0, 0); } 40%, 60% { transform: translate3d(4px, 0, 0); } }

/* KPI Cards Imported Style */
.kpi-card {
  border: 1px solid rgba(255,255,255,0.15);
  color: white;
  min-height: 110px;
  position: relative;
  overflow: hidden;
}
.kpi-rect { border-radius: 0 !important; }
.bg-gradient-info { background: linear-gradient(135deg, #0288d1, #005b9f); }
.bg-gradient-green { background: linear-gradient(135deg, #2e7d32, #1b5e20); }
.bg-gradient-purple { background: linear-gradient(135deg, #7b1fa2, #4a148c); }
.kpi-bg-icon { position: absolute; right: -20px; bottom: -20px; opacity: 0.15; transform: rotate(-15deg); pointer-events: none; z-index: 0; }
.kpi-bg-icon .v-icon { font-size: 100px; color: white; }
.kpi-label { font-size: 12px; font-weight: 900; letter-spacing: .2px; }
.kpi-value { font-size: 22px; font-weight: 900; letter-spacing: .2px; }
.kpi-footer { font-size: 11px; opacity: .9; font-weight: 700; }

/* Grid/Table Styles (Excel-like) */
.grid-scroll { scrollbar-gutter: stable both-edges; }
.grid-header, .grid-row { display: flex; width: 100%; }
.cell { padding: 8px 10px; display: flex; align-items: center; border-right: 1px solid rgba(0,0,0,0.08); border-bottom: 1px solid rgba(0,0,0,0.08); min-height: 48px; overflow: hidden; }
.center { justify-content: center; text-align: center; }
.grid-header .cell { min-height: 40px; font-size: 11px; font-weight: 900; text-transform: uppercase; letter-spacing: .6px; }
.header-text { font-size: 11px; }

.grid-surface-light .cell { background: #f5f7fa; color: rgba(0,0,0,0.7); border-color: rgba(0,0,0,0.10); }
.grid-surface-dark .cell { background: rgba(255,255,255,0.08); color: rgba(255,255,255,0.80); border-color: rgba(255,255,255,0.10); }
.grid-row-light .cell { background: #fff; border-color: rgba(0,0,0,0.08); }
.grid-row-light:hover .cell { background: #f7fafc; }
.grid-row-dark .cell { background: rgba(255,255,255,0.04); border-color: rgba(255,255,255,0.08); }
.grid-row-dark:hover .cell { background: rgba(255,255,255,0.07); }
.sticky-head { position: sticky; top: 0; z-index: 10; }

.actions-inline { display: flex; align-items: center; gap: 8px; }
.action-btn { width: 28px !important; height: 28px !important; border-radius: 6px !important; color: #fff !important; }
.action-btn :deep(.v-icon) { color: #fff !important; }
.action-edit { background: #1976d2 !important; }
.action-revert { background: #f57f17 !important; }

.z-low { z-index: 1 !important; }
.z-high { z-index: 100 !important; }
</style>
