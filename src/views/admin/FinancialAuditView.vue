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
            <span class="opacity-70">Painel Administrativo</span>
            <span class="mx-2 opacity-50">></span>
            <span class="font-weight-bold">Auditoria Financeira</span>
          </div>
          <div class="d-flex align-center gap-2 mt-1">
             <div class="text-h6 font-weight-black tracking-tight leading-none" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">
                Logs Detalhados
             </div>
             <v-chip size="x-small" color="purple-darken-3" class="font-weight-bold ml-2">
                FULL AUDIT
             </v-chip>
          </div>
        </div>

        <div class="d-flex align-center overflow-x-auto pb-1 pb-md-0" style="gap: 10px;">
            <v-btn
                color="indigo-darken-3"
                variant="flat"
                class="btn-rect px-3 px-md-4 font-weight-bold text-caption text-uppercase letter-spacing-1 flex-shrink-0 shadow-sm"
                prepend-icon="mdi-file-pdf-box"
                height="40"
                :loading="generatingPdf"
                @click="generatePDF(filteredItems, `Auditoria_Financeira_${filters.start}_${filters.end}`)"
            >
                <span class="d-none d-sm-inline">Exportar PDF</span>
            </v-btn>

            <v-btn
              color="success"
              variant="flat"
              class="btn-rect px-3 px-md-4 font-weight-bold text-caption text-uppercase letter-spacing-1 flex-shrink-0 shadow-sm"
              prepend-icon="mdi-refresh"
              height="40"
              @click="fetchLogs"
              :loading="loading"
            >
               <span class="d-none d-sm-inline">Atualizar</span>
               <v-icon class="d-inline d-sm-none">mdi-refresh</v-icon>
            </v-btn>
        </div>
      </div>

      <div class="px-4 px-md-6 py-4 flex-shrink-0">
        <div
          class="controls-bar d-flex flex-column rounded-lg bg-white elevation-1 pa-3"
          :class="themeStore.currentMode === 'light' ? '' : 'bg-glass-card'"
          style="gap: 10px;"
        >
          <div class="d-flex flex-column flex-md-row align-start align-md-center justify-space-between" style="gap: 10px;">

            <div class="d-flex align-center flex-wrap w-100 w-md-auto" style="gap: 10px;">
              <div class="d-flex align-center bg-grey-lighten-4 rounded px-1" style="height: 40px; border: 1px solid #e0e0e0;">
                  <button
                    v-for="opt in groupingOptions"
                    :key="opt.value"
                    class="px-3 py-1 text-caption font-weight-bold text-uppercase transition-all rounded-sm"
                    :class="groupingMode === opt.value ? 'bg-white elevation-1 text-primary' : 'text-grey-darken-1 opacity-70 hover:opacity-100'"
                    @click="groupingMode = opt.value"
                  >
                    {{ opt.label }}
                  </button>
              </div>

              <v-menu location="bottom start" :close-on-content-click="true">
                <template v-slot:activator="{ props }">
                  <v-btn v-bind="props" variant="outlined" class="btn-rect" height="40" prepend-icon="mdi-calendar-cursor" color="grey-darken-3">
                    Período
                    <v-icon end size="small">mdi-chevron-down</v-icon>
                  </v-btn>
                </template>
                <v-card class="rounded-lg elevation-4" min-width="200">
                  <v-list density="compact" nav>
                    <v-list-item v-for="p in quickPeriodOptions" :key="p.value" @click="applyPreset(p.value)" class="mb-1">
                      <v-list-item-title class="text-caption font-weight-bold">{{ p.label }}</v-list-item-title>
                    </v-list-item>
                  </v-list>
                </v-card>
              </v-menu>

              <div class="period-nav d-flex align-center justify-center px-4 rounded bg-purple-lighten-5 text-purple-darken-3 border border-purple-lighten-4" style="height: 40px;">
                 <div class="text-caption font-weight-black">
                    {{ formatDateSafe(filters.start) }} <v-icon size="12" class="mx-1">mdi-arrow-right</v-icon> {{ formatDateSafe(filters.end) }}
                 </div>
              </div>
            </div>

            <div class="d-flex align-center flex-wrap justify-end w-100 w-md-auto" style="gap: 10px;">
              <div class="search-wrap d-flex align-center flex-grow-1 flex-md-grow-0 rounded bg-grey-lighten-5 border-thin px-3" style="height: 40px; width: 180px;">
                <v-icon color="grey-darken-1" size="18" class="mr-2">mdi-pound</v-icon>
                <input
                  v-model="filters.orderNumber"
                  type="text"
                  placeholder="Nº Pedido (Ex: 1234)"
                  class="clean-input flex-grow-1 text-body-2"
                  @keyup.enter="fetchLogs"
                />
              </div>

              <div class="search-wrap d-flex align-center flex-grow-1 flex-md-grow-0 rounded bg-grey-lighten-5 border-thin px-3" style="height: 40px; min-width: 250px;">
                <v-icon color="grey-darken-1" size="20" class="mr-2">mdi-magnify</v-icon>
                <input
                  v-model="filters.search"
                  type="text"
                  placeholder="Buscar descrição, motivo ou valor..."
                  class="clean-input flex-grow-1 text-body-2"
                />
              </div>

              <v-menu v-model="filtersDropdownOpen" location="bottom end" :close-on-content-click="false" :z-index="2500">
                <template v-slot:activator="{ props }">
                  <v-btn
                    v-bind="props"
                    variant="flat"
                    class="btn-rect"
                    height="40"
                    color="grey-darken-3"
                    prepend-icon="mdi-filter-cog"
                  >
                    <span class="d-none d-sm-inline">Filtro</span>
                  </v-btn>
                </template>

                <v-card class="rounded-lg pa-4 elevation-4 border-thin" width="320">
                  <div class="text-subtitle-2 font-weight-black mb-3 text-uppercase text-grey-darken-2">Filtros Avançados</div>
                  <v-row dense class="row-gap-2">
                    <v-col cols="12"><label class="text-caption font-weight-bold ml-1">Início</label><v-text-field v-model="filters.start" type="date" variant="outlined" density="compact" hide-details color="primary" class="ui-input" /></v-col>
                    <v-col cols="12"><label class="text-caption font-weight-bold ml-1">Fim</label><v-text-field v-model="filters.end" type="date" variant="outlined" density="compact" hide-details color="primary" class="ui-input" /></v-col>
                    <v-col cols="12">
                        <label class="text-caption font-weight-bold ml-1">Tipo de Ação</label>
                        <v-select v-model="filters.actionType" :items="actionTypes" label="Todos" variant="outlined" density="compact" hide-details class="ui-input" clearable></v-select>
                    </v-col>
                    <v-col cols="12">
                        <label class="text-caption font-weight-bold ml-1">Usuário</label>
                        <v-select v-model="filters.userId" :items="usersList" item-title="full_name" item-value="id" label="Todos" variant="outlined" density="compact" hide-details class="ui-input" clearable></v-select>
                    </v-col>
                  </v-row>
                  <v-btn block color="primary" class="mt-4 btn-rect font-weight-bold shadow-sm" height="36" @click="fetchLogs(); filtersDropdownOpen = false">
                      Aplicar Filtros
                  </v-btn>
                </v-card>
              </v-menu>
            </div>
          </div>
        </div>
      </div>

      <div class="flex-grow-1 overflow-y-auto custom-scroll px-4 px-md-6 pb-6">

        <div v-if="loading" class="d-flex flex-column justify-center align-center py-16">
            <v-progress-circular indeterminate color="primary" size="48" width="4" class="mb-4"></v-progress-circular>
            <span class="text-subtitle-2 font-weight-bold text-grey-darken-1">Carregando auditoria...</span>
        </div>

        <div v-else-if="groupedData.length === 0" class="d-flex flex-column justify-center align-center py-16 opacity-60">
            <v-icon size="64" color="grey-lighten-1" class="mb-3">mdi-file-search-outline</v-icon>
            <div class="text-h6 font-weight-bold text-grey-darken-1">Nenhum log encontrado</div>
            <div class="text-body-2 text-grey">Tente alterar o período ou os filtros.</div>
        </div>

        <template v-else>
            <div v-for="(group, gIdx) in groupedData" :key="gIdx" class="group-container mb-8">

                <div class="group-header d-flex flex-column flex-sm-row align-start align-sm-center justify-space-between mb-2 px-1">
                    <div class="d-flex align-center gap-3 mb-2 mb-sm-0">
                        <div class="date-badge bg-grey-darken-4 text-white font-weight-black px-3 py-1 rounded elevation-2 text-uppercase text-caption ls-1">
                            {{ group.label }}
                        </div>
                        <span class="text-caption font-weight-bold text-grey-darken-1">
                            {{ group.items.length }} {{ groupingMode === 'order' ? 'pedidos' : 'eventos' }}
                        </span>
                    </div>
                    <div class="d-flex align-center gap-3">
                        <div class="d-flex align-center px-3 py-1 bg-blue-lighten-5 text-blue-darken-3 rounded border border-blue-lighten-4" v-if="group.summary.value > 0">
                            <v-icon start size="small" color="blue-darken-2">mdi-cash</v-icon>
                            <span class="text-caption font-mono font-weight-black">{{ formatCurrency(group.summary.value) }}</span>
                        </div>
                        <div class="d-flex align-center px-3 py-1 bg-red-lighten-5 text-red-darken-3 rounded border border-red-lighten-4" v-if="group.summary.critical > 0">
                            <v-icon start size="small" color="red-darken-2">mdi-alert</v-icon>
                            <span class="text-caption font-mono font-weight-black">{{ group.summary.critical }} Críticos</span>
                        </div>
                    </div>
                </div>

                <v-card class="rounded-lg border-thin overflow-hidden shadow-sm" elevation="0">
                    <div class="table-responsive">

                        <div v-if="groupingMode === 'order'" class="grid-statement-layout">
                            <div class="grid-header-row bg-grey-lighten-4 border-b text-grey-darken-2">
                                <div class="cell header-text center" style="flex: 0 0 100px;">Pedido</div>
                                <div class="cell header-text center" style="flex: 0 0 140px;">Última Ação</div>
                                <div class="cell header-text" style="flex: 1;">Usuários Envolvidos</div>
                                <div class="cell header-text center" style="flex: 0 0 120px;">Eventos</div>
                                <div class="cell header-text center" style="flex: 0 0 120px;">Críticos</div>
                                <div class="cell header-text right pr-6" style="flex: 0 0 150px;">Total Movimentado</div>
                                <div class="cell header-text center" style="flex: 0 0 100px;">Histórico</div>
                            </div>

                            <div v-for="order in group.items" :key="order.id" class="grid-body-row hover-bg-grey-lighten-5 transition-colors bg-white">
                                <div class="cell center" style="flex: 0 0 100px;">
                                     <span class="text-body-2 font-weight-black text-indigo-darken-3 bg-indigo-lighten-5 px-2 py-1 rounded border-thin">
                                        #{{ order.orderNumber }}
                                     </span>
                                </div>
                                <div class="cell center" style="flex: 0 0 140px;">
                                    <span class="text-caption font-weight-bold">{{ formatDate(order.lastActionDate) }}</span>
                                    <span class="text-[9px] opacity-70 d-block">{{ formatTime(order.lastActionDate) }}</span>
                                </div>
                                <div class="cell" style="flex: 1;">
                                    <div class="d-flex align-center gap-1 flex-wrap">
                                        <v-chip v-for="u in order.users" :key="u" size="x-small" variant="outlined" color="grey-darken-3">{{ u }}</v-chip>
                                    </div>
                                </div>
                                <div class="cell center" style="flex: 0 0 120px;">
                                    <span class="text-caption font-weight-bold">{{ order.logs.length }} logs</span>
                                </div>
                                <div class="cell center" style="flex: 0 0 120px;">
                                     <v-chip v-if="order.criticalCount > 0" size="x-small" color="red" variant="flat" class="font-weight-bold">{{ order.criticalCount }}</v-chip>
                                     <span v-else class="text-grey-lighten-1 text-caption">-</span>
                                </div>
                                <div class="cell right pr-6" style="flex: 0 0 150px;">
                                    <span class="font-mono font-weight-black text-body-2 text-grey-darken-3">
                                        {{ formatCurrency(order.totalValue) }}
                                    </span>
                                </div>
                                <div class="cell center" style="flex: 0 0 100px;">
                                    <v-btn icon variant="tonal" color="primary" size="small" @click="openHistoryModal(order)">
                                        <v-icon>mdi-magnify</v-icon>
                                        <v-tooltip activator="parent" location="top" content-class="custom-tooltip">Ver Histórico Completo</v-tooltip>
                                    </v-btn>
                                </div>
                            </div>
                        </div>

                        <div v-else class="grid-statement-layout">
                            <div class="grid-header-row bg-grey-lighten-4 border-b text-grey-darken-2">
                                <div class="cell header-text center" style="flex: 0 0 100px;">Hora</div>
                                <div class="cell header-text center" style="flex: 0 0 140px;">Ação</div>
                                <div class="cell header-text" style="flex: 0 0 180px;">Usuário</div>
                                <div class="cell header-text center" style="flex: 0 0 80px;">Ref</div>
                                <div class="cell header-text" style="flex: 0 0 250px;">Descrição</div>
                                <div class="cell header-text" style="flex: 1;">O que mudou? (Alterações)</div>
                                <div class="cell header-text" style="flex: 0 0 200px;">Motivo / Obs</div>
                                <div class="cell header-text right pr-6" style="flex: 0 0 120px;">Valor</div>
                                <div class="cell header-text center" style="flex: 0 0 80px;">Anexo</div>
                            </div>

                            <div
                                v-for="(item, i) in group.items"
                                :key="item.id"
                                class="grid-body-row transition-colors"
                                :class="getRowColorClass(item.action_type)"
                            >
                                <div class="cell center" style="flex: 0 0 100px;">
                                    <span class="font-mono text-caption font-weight-bold opacity-80">{{ formatTime(item.created_at) }}</span>
                                </div>

                                <div class="cell center" style="flex: 0 0 140px;">
                                    <v-chip
                                        :color="getActionColor(item.action_type)"
                                        size="x-small"
                                        variant="flat"
                                        class="font-weight-black px-2 uppercase"
                                    >
                                        {{ formatAction(item.action_type) }}
                                    </v-chip>
                                </div>

                                <div class="cell" style="flex: 0 0 180px;">
                                    <div class="d-flex align-center gap-2 overflow-hidden">
                                        <v-avatar size="24" color="grey-lighten-2" class="text-[10px] font-weight-black">
                                            {{ getInitials(item.profiles?.full_name) }}
                                        </v-avatar>
                                        <div class="d-flex flex-column text-truncate">
                                            <span class="text-caption font-weight-bold text-truncate" :title="item.profiles?.full_name">
                                                {{ item.profiles?.full_name || 'Sistema' }}
                                            </span>
                                        </div>
                                    </div>
                                </div>

                                <div class="cell center" style="flex: 0 0 80px;">
                                    <span
                                        v-if="orderMap[item.entity_id]"
                                        class="text-[10px] bg-white-50 px-2 py-1 rounded font-mono font-weight-bold text-indigo-darken-3 cursor-pointer border-thin hover:bg-white"
                                        @click="openOrder(item.entity_id)"
                                    >
                                        #{{ orderMap[item.entity_id] }}
                                    </span>
                                    <span v-else class="text-caption text-grey opacity-50">-</span>
                                </div>

                                <div class="cell" style="flex: 0 0 250px;">
                                    <span class="text-caption font-weight-bold text-grey-darken-3 text-truncate" :title="item.payload?.description">
                                        {{ item.payload?.description || '-' }}
                                    </span>
                                </div>

                                <div class="cell" style="flex: 1;">
                                    <div v-if="item.action_type === 'RECEIVABLE_EDITED'" class="d-flex flex-wrap gap-2">
                                        <div v-for="diff in resolveDiffs(item.payload, item.old_value)" :key="diff.key" class="text-[10px] bg-white px-2 py-1 rounded border-thin d-flex align-center gap-1 shadow-xs">
                                            <span class="font-weight-bold text-grey-darken-2">{{ diff.label }}:</span>
                                            <span class="text-decoration-line-through text-red-darken-2 opacity-70">{{ diff.from }}</span>
                                            <v-icon size="12" color="grey">mdi-arrow-right</v-icon>
                                            <span class="text-green-darken-3 font-weight-black">{{ diff.to }}</span>
                                        </div>
                                    </div>
                                    <span v-else class="text-caption text-grey opacity-30 italic">Sem alterações</span>
                                </div>

                                <div class="cell" style="flex: 0 0 200px;">
                                    <span v-if="item.payload?.reason" class="text-[11px] text-red-darken-3 font-italic font-weight-medium">
                                        "{{ item.payload.reason }}"
                                    </span>
                                    <span v-else class="text-caption text-grey opacity-40">-</span>
                                </div>

                                <div class="cell right pr-6" style="flex: 0 0 120px;">
                                    <span v-if="item.payload?.value" class="font-mono font-weight-black text-body-2" :class="item.action_type.includes('REVERT') ? 'text-red-darken-3' : 'text-grey-darken-3'">
                                        {{ formatCurrencyValue(item.payload.value) }}
                                    </span>
                                    <span v-else class="text-grey-lighten-1 text-[10px]">-</span>
                                </div>

                                <div class="cell center" style="flex: 0 0 80px;">
                                    <v-tooltip :text="`IP: ${item.ip_address || '?'}`" location="top" content-class="custom-tooltip">
                                        <template v-slot:activator="{ props }">
                                            <div class="d-flex justify-center gap-1" v-bind="props">
                                                <v-btn
                                                    v-if="item.payload?.attachment_url"
                                                    icon
                                                    size="x-small"
                                                    variant="text"
                                                    color="blue-darken-2"
                                                    class="opacity-80 hover:opacity-100"
                                                    title="Ver Anexo"
                                                    :href="item.payload.attachment_url"
                                                    target="_blank"
                                                >
                                                    <v-icon>mdi-paperclip</v-icon>
                                                </v-btn>
                                                <v-icon v-else size="14" color="grey-lighten-1">mdi-earth</v-icon>
                                            </div>
                                        </template>
                                    </v-tooltip>
                                </div>
                            </div>
                        </div>
                    </div>
                </v-card>

            </div>
        </template>

      </div>
    </div>

    <v-dialog v-model="historyModal.show" width="900" scrollable>
        <v-card class="rounded-xl overflow-hidden bg-grey-lighten-4">
            <div class="px-6 py-5 bg-white border-b d-flex align-center justify-space-between sticky-top z-10 shadow-sm">
                <div class="d-flex align-center gap-4">
                    <div class="bg-indigo-lighten-5 pa-3 rounded-circle text-indigo-darken-3">
                         <v-icon size="28">mdi-file-document-multiple-outline</v-icon>
                    </div>
                    <div>
                        <div class="text-overline font-weight-bold text-grey-darken-1 lh-1 mb-1">Dossiê Completo</div>
                        <div class="text-h5 font-weight-black text-grey-darken-4 lh-1">Pedido #{{ historyModal.data?.orderNumber }}</div>
                    </div>
                </div>
                <div class="d-flex align-center gap-3">
                    <v-btn variant="outlined" color="grey-darken-3" class="btn-rect font-weight-bold" prepend-icon="mdi-printer" @click="generateHistoryPDF(historyModal.data)">
                        Baixar Dossiê (PDF)
                    </v-btn>
                    <v-btn icon variant="text" color="grey-darken-2" @click="historyModal.show = false"><v-icon>mdi-close</v-icon></v-btn>
                </div>
            </div>

            <v-card-text class="pa-0 custom-scroll" style="height: 650px;">
                <div class="pa-8">
                    <v-timeline density="comfortable" side="end" align="start" line-color="grey-lighten-2" line-thickness="2">

                        <v-timeline-item
                            v-for="log in historyModal.data?.logs"
                            :key="log.id"
                            :dot-color="getActionColor(log.action_type)"
                            size="default"
                            fill-dot
                            class="mb-4"
                        >
                            <template v-slot:icon>
                                <v-icon size="18" color="white">{{ getActionIcon(log.action_type) }}</v-icon>
                            </template>

                            <v-card class="rounded-lg elevation-2 border-thin overflow-hidden">
                                <div class="px-4 py-3 border-b bg-grey-lighten-5 d-flex align-center justify-space-between">
                                    <div class="d-flex align-center gap-2">
                                        <v-chip size="x-small" :color="getActionColor(log.action_type)" class="font-weight-black text-uppercase">{{ formatActionDidactic(log.action_type) }}</v-chip>
                                        <span class="text-caption text-grey-darken-1 font-weight-bold">{{ formatDate(log.created_at) }} às {{ formatTime(log.created_at) }}</span>
                                    </div>
                                    <div class="d-flex align-center gap-2">
                                        <v-avatar size="20" color="grey-lighten-2" class="text-[10px] font-weight-bold">{{ getInitials(log.profiles?.full_name) }}</v-avatar>
                                        <span class="text-caption font-weight-bold text-grey-darken-3">{{ log.profiles?.full_name || 'Sistema' }}</span>
                                    </div>
                                </div>

                                <div class="pa-4">
                                    <div class="text-body-2 text-grey-darken-3 mb-2" style="line-height: 1.5;">
                                        <span class="font-weight-bold">{{ log.profiles?.full_name || 'O Sistema' }}</span>
                                        {{ getNarrative(log.action_type) }}
                                        <span v-if="log.payload?.value" class="font-weight-black text-green-darken-4 bg-green-lighten-5 px-1 rounded mx-1">{{ formatCurrency(log.payload.value) }}</span>
                                        referente a <span class="font-weight-bold font-italic">"{{ log.payload?.description || 'Parcela' }}"</span>.
                                    </div>

                                    <div v-if="log.action_type === 'RECEIVABLE_EDITED'" class="bg-orange-lighten-5 pa-3 rounded-lg border border-orange-lighten-4 mt-3">
                                        <div class="text-[11px] font-weight-black text-orange-darken-4 text-uppercase mb-2">O que mudou?</div>
                                        <div v-for="diff in resolveDiffs(log.payload, log.old_value)" :key="diff.key" class="d-flex align-center gap-2 mb-1 text-caption">
                                            <span class="font-weight-bold text-grey-darken-3 min-w-80">{{ diff.label }}:</span>
                                            <span class="text-decoration-line-through text-red opacity-70">{{ diff.from }}</span>
                                            <v-icon size="14" color="grey">mdi-arrow-right</v-icon>
                                            <span class="bg-white px-1 rounded font-weight-bold text-green-darken-4 border-thin">{{ diff.to }}</span>
                                        </div>
                                    </div>

                                    <div v-if="log.payload?.reason" class="mt-3 d-flex align-start gap-2 bg-red-lighten-5 pa-2 rounded text-red-darken-4">
                                        <v-icon size="16" class="mt-0.5">mdi-comment-alert-outline</v-icon>
                                        <div class="text-caption font-italic">"{{ log.payload.reason }}"</div>
                                    </div>

                                    <div v-if="log.payload?.attachment_url" class="mt-3 pt-3 border-t border-dashed">
                                        <v-btn
                                            variant="tonal"
                                            color="blue-darken-2"
                                            prepend-icon="mdi-paperclip"
                                            size="small"
                                            class="font-weight-bold text-caption"
                                            :href="log.payload.attachment_url"
                                            target="_blank"
                                        >
                                            Visualizar Comprovante Anexado
                                        </v-btn>
                                    </div>
                                </div>
                            </v-card>
                        </v-timeline-item>

                    </v-timeline>
                </div>
            </v-card-text>
        </v-card>
    </v-dialog>

    <v-scale-transition>
        <div v-if="feedback.show" class="feedback-toast" :class="feedback.error ? 'is-error' : 'is-success'">
            <div class="d-flex align-center">
                <v-icon color="white" class="mr-3">{{ feedback.error ? 'mdi-alert-circle' : 'mdi-check-circle' }}</v-icon>
                <div>
                    <div class="text-subtitle-2 font-weight-black text-white">{{ feedback.title }}</div>
                    <div class="text-caption text-white opacity-80">{{ feedback.message }}</div>
                </div>
                <v-btn icon size="small" variant="text" color="white" class="ml-auto" @click="feedback.show = false"><v-icon>mdi-close</v-icon></v-btn>
            </div>
        </div>
    </v-scale-transition>

  </div>
</template>

<script setup lang="ts">
import { ref, computed, reactive, onMounted } from 'vue';
import { useThemeStore } from '@/stores/theme';
import { useUserStore } from '@/stores/user';
import { supabase } from '@/api/supabase';
import { format, parseISO, isValid, startOfMonth, endOfMonth, startOfWeek, endOfWeek, subDays, getWeek } from 'date-fns';
import { ptBR } from 'date-fns/locale';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import logoMj from '@/assets/logo.png';
import { useRouter } from 'vue-router';

const themeStore = useThemeStore();
const userStore = useUserStore();
const router = useRouter();

// Estados
const loading = ref(false);
const generatingPdf = ref(false);
const logs = ref<any[]>([]);
const usersList = ref<any[]>([]);
const filtersDropdownOpen = ref(false);
const groupingMode = ref<'day' | 'week' | 'month' | 'order'>('day');

const historyModal = reactive({ show: false, data: null as any });

// CACHES AUXILIARES
const orderMap = ref<Record<string, string>>({});
const paymentMethodsMap = ref<Record<string, string>>({});
const accountsMap = ref<Record<string, string>>({});

// Filtros
const filters = reactive({
  start: format(startOfMonth(new Date()), 'yyyy-MM-dd'),
  end: format(endOfMonth(new Date()), 'yyyy-MM-dd'),
  search: '',
  userId: null,
  actionType: null,
  orderNumber: ''
});

const actionTypes = [
    { title: 'Pagamento Recebido', value: 'PAYMENT_RECEIVED' },
    { title: 'Estorno', value: 'PAYMENT_REVERTED' },
    { title: 'Parcela Criada', value: 'RECEIVABLE_CREATED' },
    { title: 'Parcela Editada', value: 'RECEIVABLE_EDITED' },
    { title: 'Parcela Excluída', value: 'RECEIVABLE_DELETED' },
    { title: 'Anexo', value: 'RECEIVABLE_ATTACHMENT' },
];

const feedback = reactive({ show: false, error: false, title: '', message: '' });
const showFeedback = (title: string, msg: string, isError = false) => {
    feedback.title = title; feedback.message = msg; feedback.error = isError; feedback.show = true;
    setTimeout(() => feedback.show = false, 4000);
};

// Computed Filtered Items
const filteredItems = computed(() => {
    let items = logs.value;
    if (filters.search) {
        const term = filters.search.toLowerCase();
        items = items.filter(l =>
            (l.payload?.description || '').toLowerCase().includes(term) ||
            (l.profiles?.full_name || '').toLowerCase().includes(term) ||
            (l.payload?.value && String(l.payload.value).includes(term)) ||
            (l.payload?.reason || '').toLowerCase().includes(term)
        );
    }
    return items;
});

// Grouping Logic
const groupedData = computed(() => {
    if (groupingMode.value === 'order') {
        // Agrupamento por PEDIDO
        const orderGroups: Record<string, any> = {};

        filteredItems.value.forEach(item => {
            const orderId = item.entity_id || 'unknown';
            if (!orderGroups[orderId]) {
                orderGroups[orderId] = {
                    id: orderId,
                    orderNumber: orderMap.value[orderId] || 'S/N',
                    logs: [],
                    totalValue: 0,
                    criticalCount: 0,
                    users: new Set(),
                    lastActionDate: item.created_at
                };
            }
            const group = orderGroups[orderId];
            group.logs.push(item);
            group.users.add(item.profiles?.full_name?.split(' ')[0] || 'Sistema');

            // Atualiza data mais recente
            if (new Date(item.created_at) > new Date(group.lastActionDate)) {
                group.lastActionDate = item.created_at;
            }

            if (item.payload?.value) group.totalValue += Number(item.payload.value);
            if (['PAYMENT_REVERTED', 'RECEIVABLE_DELETED'].includes(item.action_type)) group.criticalCount++;
        });

        return [{
            label: 'Resumo por Pedido',
            items: Object.values(orderGroups).sort((a: any, b: any) => new Date(b.lastActionDate).getTime() - new Date(a.lastActionDate).getTime()),
            summary: { value: 0, critical: 0 }
        }];
    }

    // Agrupamento por DATA (Padrão)
    const groups: Record<string, { label: string, dateObj: Date, items: any[], summary: { value: number, critical: number } }> = {};

    filteredItems.value.forEach(item => {
        const date = parseISO(item.created_at);
        if (!isValid(date)) return;

        let key = '';
        let label = '';

        if (groupingMode.value === 'day') {
            key = format(date, 'yyyy-MM-dd');
            label = format(date, 'dd/MM/yyyy (EEEE)', { locale: ptBR });
        } else if (groupingMode.value === 'week') {
            const week = getWeek(date, { locale: ptBR });
            const year = date.getFullYear();
            key = `${year}-W${week}`;
            label = `Semana ${week} de ${year}`;
        } else {
            key = format(date, 'yyyy-MM');
            label = format(date, 'MMMM yyyy', { locale: ptBR }).toUpperCase();
        }

        if (!groups[key]) {
            groups[key] = { label, dateObj: date, items: [], summary: { value: 0, critical: 0 } };
        }

        groups[key].items.push(item);

        if (item.payload?.value) {
            groups[key].summary.value += Number(item.payload.value);
        }
        if (['PAYMENT_REVERTED', 'RECEIVABLE_DELETED'].includes(item.action_type)) {
            groups[key].summary.critical++;
        }
    });

    return Object.values(groups).sort((a, b) => b.dateObj.getTime() - a.dateObj.getTime());
});

const groupingOptions = [
    { label: 'Dia', value: 'day' },
    { label: 'Semana', value: 'week' },
    { label: 'Mês', value: 'month' },
    { label: 'Por Pedido', value: 'order' }
];

const quickPeriodOptions = [
    { label: 'Hoje', value: 'today' },
    { label: 'Esta Semana', value: 'week' },
    { label: 'Este Mês', value: 'month' },
];

const applyPreset = (preset: string) => {
    const today = new Date();
    if (preset === 'today') {
        filters.start = format(today, 'yyyy-MM-dd');
        filters.end = format(today, 'yyyy-MM-dd');
    } else if (preset === 'week') {
        filters.start = format(startOfWeek(today, { weekStartsOn: 1 }), 'yyyy-MM-dd');
        filters.end = format(endOfWeek(today, { weekStartsOn: 1 }), 'yyyy-MM-dd');
    } else if (preset === 'month') {
        filters.start = format(startOfMonth(today), 'yyyy-MM-dd');
        filters.end = format(endOfMonth(today), 'yyyy-MM-dd');
    }
    fetchLogs();
};

const fetchAuxiliaryData = async () => {
    const { data: users } = await supabase.from('profiles').select('id, full_name, email');
    if (users) usersList.value = users;

    const { data: methods } = await supabase.from('finance_payment_methods').select('id, name');
    if (methods) {
        methods.forEach((m: any) => paymentMethodsMap.value[m.id] = m.name);
    }

    const { data: accounts } = await supabase.from('finance_accounts').select('id, name');
    if (accounts) {
        accounts.forEach((a: any) => accountsMap.value[a.id] = a.name);
    }
};

const fetchLogs = async () => {
    loading.value = true;
    try {
        let query = supabase
            .from('finance_audit_logs')
            .select('*, profiles(full_name, email)')
            .order('created_at', { ascending: false });

        if (filters.start) query = query.gte('created_at', filters.start + 'T00:00:00');
        if (filters.end) query = query.lte('created_at', filters.end + 'T23:59:59');
        if (filters.userId) query = query.eq('user_id', filters.userId);
        if (filters.actionType) query = query.eq('action_type', filters.actionType);

        if (filters.orderNumber && filters.orderNumber.trim() !== '') {
            const { data: ord } = await supabase.from('orders').select('id').eq('order_number', filters.orderNumber.trim()).maybeSingle();
            if (ord) query = query.eq('entity_id', ord.id);
            else { logs.value = []; showFeedback('Aviso', 'Pedido não encontrado.', true); return; }
        }

        const { data, error } = await query;
        if (error) throw error;
        logs.value = data || [];

        if (logs.value.length > 0) {
            const entityIds = [...new Set(logs.value.map(l => l.entity_id).filter(Boolean))];
            if (entityIds.length > 0) {
                const { data: orderInfos } = await supabase.from('orders').select('id, order_number').in('id', entityIds);
                if (orderInfos) orderInfos.forEach((o: any) => orderMap.value[o.id] = String(o.order_number));
            }
        }
        showFeedback('Sucesso', 'Logs atualizados.', false);
    } catch (e: any) {
        console.error(e);
        showFeedback('Erro', e.message, true);
    } finally {
        loading.value = false;
    }
};

const openOrder = (id: string) => {
    if (!id) return;
    router.push({ name: 'OrderManagement', query: { open_order_id: id, open_finance: 'true' } });
};

// Histórico Modal
const openHistoryModal = (orderGroup: any) => {
    historyModal.data = orderGroup;
    historyModal.show = true;
};

const resolveDiffs = (current: any, old: any) => {
    if (!old) return [];
    const diffs: any[] = [];
    const labels: Record<string, string> = { 'value': 'Valor', 'due_date': 'Vencimento', 'competence_date': 'Competência', 'payment_method_id': 'Forma Pgto', 'bank_account_id': 'Conta Bancária', 'description': 'Descrição', 'notes': 'Obs' };

    for (const key in current) {
        if (current[key] !== old[key] && !['updated_at', 'billing_items_snapshot', 'order_id', 'customer_id', 'created_by'].includes(key)) {
            let fromVal = old[key];
            let toVal = current[key];
            const label = labels[key] || key;

            if (key === 'value') { fromVal = formatCurrency(fromVal); toVal = formatCurrency(toVal); }
            else if (key.includes('date')) { fromVal = fromVal ? formatDateSafe(fromVal) : '-'; toVal = toVal ? formatDateSafe(toVal) : '-'; }
            else if (key === 'payment_method_id') { fromVal = paymentMethodsMap.value[fromVal] || 'Desconhecido'; toVal = paymentMethodsMap.value[toVal] || 'Desconhecido'; }
            else if (key === 'bank_account_id') { fromVal = accountsMap.value[fromVal] || 'Desconhecido'; toVal = accountsMap.value[toVal] || 'Desconhecido'; }

            diffs.push({ key, label, from: fromVal, to: toVal });
        }
    }
    return diffs;
};

// Utils & Formatters
const formatCurrency = (val: number) => new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(Number(val));
const formatCurrencyValue = (val: number) => new Intl.NumberFormat('pt-BR', { minimumFractionDigits: 2 }).format(Number(val));
const formatDateSafe = (dateString?: string) => dateString ? format(parseISO(dateString), 'dd/MM/yyyy') : '-';
const formatDateTime = (iso: string) => iso ? format(parseISO(iso), 'dd/MM/yyyy HH:mm', { locale: ptBR }) : '-';
const formatTime = (iso: string) => iso ? format(parseISO(iso), 'HH:mm') : '-';
const getInitials = (name: string) => name ? name.substring(0, 2).toUpperCase() : '??';
const formatDate = (iso: string) => iso ? format(parseISO(iso), 'dd/MM/yyyy') : '-';

const formatAction = (type: string) => {
    const map: any = { 'PAYMENT_RECEIVED': 'Recebido', 'PAYMENT_REVERTED': 'Estornado', 'RECEIVABLE_CREATED': 'Criado', 'RECEIVABLE_EDITED': 'Editado', 'RECEIVABLE_DELETED': 'Excluído', 'RECEIVABLE_ATTACHMENT': 'Anexo' };
    return map[type] || type;
};

const formatActionDidactic = (type: string) => {
    const map: any = {
        'PAYMENT_RECEIVED': 'Pagamento Confirmado',
        'PAYMENT_REVERTED': 'Pagamento Cancelado',
        'RECEIVABLE_CREATED': 'Nova Parcela Criada',
        'RECEIVABLE_EDITED': 'Dados Alterados',
        'RECEIVABLE_DELETED': 'Parcela Excluída',
        'RECEIVABLE_ATTACHMENT': 'Documento Anexado'
    };
    return map[type] || type;
};

const getNarrative = (type: string) => {
     const map: any = {
        'PAYMENT_RECEIVED': 'confirmou o recebimento do valor de',
        'PAYMENT_REVERTED': 'estornou (cancelou) o recebimento de',
        'RECEIVABLE_CREATED': 'criou uma nova parcela no valor de',
        'RECEIVABLE_EDITED': 'editou informações da parcela',
        'RECEIVABLE_DELETED': 'excluiu a parcela no valor de',
        'RECEIVABLE_ATTACHMENT': 'anexou um comprovante na parcela'
    };
    return map[type] || 'realizou uma ação na parcela';
};

const getActionColor = (type: string) => {
    if (type.includes('RECEIVED')) return 'green-darken-2';
    if (type.includes('REVERT') || type.includes('DELETED')) return 'red-darken-2';
    if (type.includes('EDIT')) return 'orange-darken-2';
    return 'blue-darken-2';
};

const getActionIcon = (type: string) => {
    if (type.includes('RECEIVED')) return 'mdi-cash-check';
    if (type.includes('REVERT')) return 'mdi-undo-variant';
    if (type.includes('EDIT')) return 'mdi-pencil-outline';
    if (type.includes('DELETE')) return 'mdi-trash-can-outline';
    if (type.includes('ATTACHMENT')) return 'mdi-file-document-outline';
    return 'mdi-circle-small';
};

const getRowColorClass = (type: string) => {
    if (type.includes('RECEIVED')) return 'bg-green-soft border-l-4-green';
    if (type.includes('REVERT') || type.includes('DELETED')) return 'bg-red-soft border-l-4-red';
    if (type.includes('EDIT')) return 'bg-orange-soft border-l-4-orange';
    return 'bg-blue-soft border-l-4-blue';
};

// PDF Generation (HISTÓRICO ESPECÍFICO)
const imageToBase64 = async (url: string): Promise<string> => {
  try { const res = await fetch(url); const blob = await res.blob(); return await new Promise((resolve) => { const reader = new FileReader(); reader.onload = () => resolve(String(reader.result)); reader.readAsDataURL(blob); }); } catch { return ''; }
};

const generateHistoryPDF = async (orderData: any) => {
    if (!orderData || !orderData.logs.length) return showFeedback('Aviso', 'Sem dados.', true);
    generatingPdf.value = true;
    try {
        const doc = new jsPDF({ orientation: 'p', unit: 'mm', format: 'a4' });
        const pageW = doc.internal.pageSize.getWidth();
        const M = 10;

        try { const logoBase64 = await imageToBase64(logoMj); if (logoBase64) doc.addImage(logoBase64, 'PNG', M + 2, 10, 30, 15); } catch (e) { /* ignore */ }

        doc.setFontSize(8);
        doc.setFont("helvetica", "bold");
        doc.text("MJ PROCESS - AUDITORIA", pageW - M, 14, { align: 'right' });
        doc.setFont("helvetica", "normal");
        doc.text(`Emissão: ${format(new Date(), 'dd/MM/yyyy HH:mm', { locale: ptBR })}`, pageW - M, 18, { align: 'right' });

        doc.setDrawColor(200, 200, 200);
        doc.line(M, 30, pageW - M, 30);

        doc.setFontSize(14).setFont("helvetica", "bold").text(`DOSSIÊ FINANCEIRO: PEDIDO #${orderData.orderNumber}`, M, 35);
        doc.setFontSize(10).setFont("helvetica", "normal").text(`Gerado em: ${format(new Date(), 'dd/MM/yyyy HH:mm')}`, M, 42);

        // Aviso Legal
        doc.setFillColor(250, 250, 250); doc.rect(M, 46, pageW - (2*M), 12, 'F');
        doc.setFontSize(8).setTextColor(100);
        doc.text("Este documento é um registro imutável de auditoria gerado pelo sistema MJProcess.", M + 2, 51);
        doc.text("Todas as ações abaixo foram registradas e vinculadas aos usuários responsáveis.", M + 2, 55);

        doc.setTextColor(0);
        const tableBody = orderData.logs.map((item: any) => {
            let details = getNarrative(item.action_type);
            if (item.action_type === 'RECEIVABLE_EDITED') {
                 const diffs = resolveDiffs(item.payload, item.old_value);
                 details = diffs.map(d => `${d.label}: ${d.from} -> ${d.to}`).join('\n');
            } else if (item.payload?.reason) {
                 details += `\nMotivo: ${item.payload.reason}`;
            }

            return [
                formatDateTime(item.created_at),
                formatActionDidactic(item.action_type), // Nome amigável
                item.profiles?.full_name || 'Sistema',
                details,
                item.payload?.value ? formatCurrency(item.payload.value) : '-'
            ];
        });

autoTable(doc, {
            startY: 65,
            head: [['DATA/HORA', 'AÇÃO', 'RESPONSÁVEL', 'DETALHES DA OCORRÊNCIA', 'VALOR']],
            body: tableBody,
            theme: 'grid',
            headStyles: { fillColor: [33, 33, 33], textColor: 255, fontStyle: 'bold', fontSize: 9 },
            bodyStyles: { fontSize: 8, cellPadding: 3 },
            columnStyles: { 0: { cellWidth: 30 }, 1: { cellWidth: 35 }, 2: { cellWidth: 30 }, 3: { cellWidth: 'auto' }, 4: { cellWidth: 25, halign: 'right' } },

            didParseCell: (data) => {
                if (data.section === 'body') {
                    const action = orderData.logs[data.row.index].action_type;
                    if (action.includes('RECEIVED')) { data.cell.styles.fillColor = [232, 245, 233]; data.cell.styles.textColor = [27, 94, 32]; }
                    else if (action.includes('REVERT') || action.includes('DELETED')) { data.cell.styles.fillColor = [255, 235, 238]; data.cell.styles.textColor = [183, 28, 28]; }
                }
            },

            // CORREÇÃO AQUI: Usar 'pageW' em vez de 'pageWidth'
             didDrawPage: (data) => {
                const str = `Gerado por: ${userStore.profile?.full_name} (${userStore.user?.email}) via MJProcess`;
                doc.setFontSize(7).setTextColor(150);
                doc.text(str, pageW / 2, doc.internal.pageSize.height - 10, { align: 'center' });
            }
        });

        doc.save(`Dossie_Pedido_${orderData.orderNumber}.pdf`);
        showFeedback('Sucesso', 'Dossiê baixado.', false);
    } catch(e:any) { showFeedback('Erro', e.message, true); } finally { generatingPdf.value = false; }
};

// PDF Geral (Mantido e Melhorado)
const generatePDF = async (items: any[], title: string) => {
    if (items.length === 0) return showFeedback('Aviso', 'Nada para exportar.', true);
    generatingPdf.value = true;
    try {
        const doc = new jsPDF({ orientation: 'l', unit: 'mm', format: 'a4' });
        const pageW = doc.internal.pageSize.getWidth();
        const M = 10;

        try { const logoBase64 = await imageToBase64(logoMj); if (logoBase64) doc.addImage(logoBase64, 'PNG', M + 2, 10, 30, 15); } catch (e) { /* ignore */ }

        doc.setFontSize(8).setFont("helvetica", "bold");
        doc.text("MJ PROCESS - SISTEMA INTEGRADO", pageW - M, 14, { align: 'right' });
        doc.setFont("helvetica", "normal");
        doc.text(`CNPJ: 53.756.096/0001-89`, pageW - M, 18, { align: 'right' });

        doc.setDrawColor(200, 200, 200); doc.line(M, 30, pageW - M, 30);

        doc.setFontSize(14).setFont("helvetica", "bold").setTextColor(40);
        doc.text("RELATÓRIO DE AUDITORIA FINANCEIRA", M, 38);
        doc.setFontSize(10).setTextColor(100);
        doc.text(`Período: ${filters.start} a ${filters.end}`, M, 44);

        // Aviso Imutável
        doc.setFillColor(245); doc.rect(M, 48, pageW - (2*M), 10, 'F');
        doc.setFontSize(8).setTextColor(80);
        doc.text("Declaração de Integridade: Este relatório foi extraído diretamente dos logs de auditoria criptografados do sistema.", M + 2, 54);

        // KPIs Rápidos
        const totalVal = items.reduce((acc, i) => acc + (Number(i.payload?.value) || 0), 0);
        const totalCrit = items.filter(i => i.action_type.includes('REVERT') || i.action_type.includes('DELETE')).length;

        doc.setFontSize(9).setTextColor(0);
        doc.text(`Total Movimentado: ${formatCurrency(totalVal)}  |  Ações Críticas: ${totalCrit}  |  Registros: ${items.length}`, M, 65);

        const tableBody = items.map(item => {
            let diffText = '-';
            if (item.action_type === 'RECEIVABLE_EDITED') {
                 const diffs = resolveDiffs(item.payload, item.old_value);
                 diffText = diffs.map(d => `${d.label}: ${d.from} -> ${d.to}`).join('\n');
            }
            return [
                formatDateTime(item.created_at),
                formatAction(item.action_type),
                item.profiles?.full_name || 'Sistema',
                orderMap.value[item.entity_id] || '-',
                item.payload?.description || '-',
                diffText,
                item.payload?.reason || '-',
                item.payload?.value ? formatCurrency(item.payload.value) : '-'
            ];
        });

        autoTable(doc, {
            startY: 70,
            head: [['DATA', 'AÇÃO', 'USUÁRIO', 'REF', 'DESCRIÇÃO', 'ALTERAÇÕES', 'MOTIVO', 'VALOR']],
            body: tableBody,
            theme: 'grid',
            headStyles: { fillColor: [33, 33, 33], textColor: 255, fontStyle: 'bold', fontSize: 8 },
            bodyStyles: { fontSize: 7, cellPadding: 2 },
            columnStyles: { 0: { cellWidth: 25 }, 1: { cellWidth: 25 }, 2: { cellWidth: 30 }, 3: { cellWidth: 15 }, 4: { cellWidth: 40 }, 5: { cellWidth: 60 }, 6: { cellWidth: 40 }, 7: { cellWidth: 25, halign: 'right' } },
            didDrawPage: (data) => {
                const str = `Gerado por: ${userStore.profile?.full_name} (${userStore.user?.email}) em ${format(new Date(), 'dd/MM/yyyy HH:mm')}`;
                doc.setFontSize(7).setTextColor(150);
                doc.text(str, pageW / 2, doc.internal.pageSize.height - 10, { align: 'center' });
            }
        });

        doc.save(`${title}.pdf`);
        showFeedback('Sucesso', 'PDF gerado.', false);
    } catch (e: any) { showFeedback('Erro', 'Falha ao gerar PDF.', true); } finally { generatingPdf.value = false; }
};

onMounted(() => { fetchAuxiliaryData(); fetchLogs(); });
</script>

<style scoped lang="scss">
/* Estilos mantidos (Tooltip, Glassmorphism, Grid) */
.receivables-layout { position: relative; }
.bg-glass-dark { background: rgba(10,10,12,0.95); }
.bg-glass-header { background: rgba(20,20,24,0.85); backdrop-filter: blur(10px); }
.border-bottom-white-05 { border-bottom: 1px solid rgba(255,255,255,0.08); }
.btn-rect { border-radius: 4px !important; text-transform: none !important; font-weight: 800; letter-spacing: 0.5px; }
.clean-input { border: none; outline: none; flex: 1; font-size: 13px; }
.ls-1 { letter-spacing: 1px; }
.gap-2 { gap: 8px; } .gap-3 { gap: 12px; }

.table-responsive { overflow-x: auto; -webkit-overflow-scrolling: touch; }
.grid-statement-layout { display: table; width: 100%; min-width: 1300px; }
.grid-header-row, .grid-body-row { display: flex; align-items: stretch; width: 100%; }
.cell { padding: 8px 12px; display: flex; align-items: center; border-right: 1px solid rgba(0,0,0,0.05); min-height: 48px; font-size: 12px; }
.cell:last-child { border-right: none; }
.header-text { font-size: 11px; font-weight: 900; text-transform: uppercase; letter-spacing: 0.5px; color: #616161; }
.center { justify-content: center; text-align: center; }
.right { justify-content: flex-end; text-align: right; }

.bg-green-soft { background-color: rgba(76, 175, 80, 0.08); }
.bg-red-soft { background-color: rgba(244, 67, 54, 0.08); }
.bg-orange-soft { background-color: rgba(255, 152, 0, 0.08); }
.bg-blue-soft { background-color: rgba(33, 150, 243, 0.08); }
.hover-bg-grey-lighten-5:hover { background-color: #f5f5f5 !important; }

.border-l-4-green { border-left: 4px solid #2e7d32 !important; }
.border-l-4-red { border-left: 4px solid #c62828 !important; }
.border-l-4-orange { border-left: 4px solid #ef6c00 !important; }
.border-l-4-blue { border-left: 4px solid #1565c0 !important; }

.ui-input :deep(.v-field__input) { min-height: 32px !important; padding-top: 4px; padding-bottom: 4px; font-size: 13px; }

.feedback-toast { position: fixed; bottom: 24px; right: 24px; padding: 16px 20px; border-radius: 8px; box-shadow: 0 10px 30px rgba(0,0,0,0.3); z-index: 9999; min-width: 300px; }
.feedback-toast.is-success { background: #2e7d32; }
.feedback-toast.is-error { background: #c62828; }

.background-carousel-wrapper { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 0; }
.background-overlay { position: absolute; top: 0; left: 0; width: 100%; height: 100%; background: rgba(10,10,12,0.85); z-index: 1; }

/* Tooltip Fix (Global Override) */
:global(.custom-tooltip) {
    background-color: #000000 !important;
    color: #ffffff !important;
    font-size: 11px !important;
    font-weight: 600 !important;
    border-radius: 4px;
    opacity: 1 !important;
}
</style>
