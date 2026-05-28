<template>
  <div class="receivables-layout font-sans fill-height d-flex flex-column relative overflow-hidden" :class="isDark ? 'bg-grey-darken-4 text-white' : 'bg-grey-lighten-5 text-grey-darken-4'">

    <div v-if="isDark" class="background-carousel-wrapper">
      <v-carousel cycle height="100%" hide-delimiters :show-arrows="false" interval="15000" class="fill-height">
        <v-carousel-item src="@/assets/1.jpg" cover></v-carousel-item>
        <v-carousel-item src="@/assets/2.jpg" cover></v-carousel-item>
        <v-carousel-item src="@/assets/3.jpg" cover></v-carousel-item>
      </v-carousel>
      <div class="background-overlay"></div>
    </div>

    <div class="content-wrapper d-flex flex-column fill-height z-10 relative">

      <div class="header-bar px-4 py-3 px-md-6 py-md-4 d-flex flex-column flex-md-row align-md-center justify-space-between flex-shrink-0" :class="isDark ? 'bg-glass-header border-bottom-white-05' : 'bg-white border-b border-grey-lighten-2 shadow-sm'" style="gap: 12px;">
        <div class="d-flex flex-column">
          <div class="breadcrumb text-caption d-none d-md-block">
            <span class="opacity-70">Logística</span><span class="mx-2 opacity-50">></span><span class="font-weight-bold">Gestão de Estoque</span>
          </div>
          <div class="d-flex align-center gap-2 mt-1">
             <div class="text-h6 font-weight-black tracking-tight leading-none" :class="isDark ? 'text-white' : 'text-grey-darken-4'">
                Inventário de Materiais
             </div>
          </div>
        </div>

        <div class="d-none d-md-flex align-center overflow-x-auto pb-1 pb-md-0" style="gap: 10px;">
          <v-menu location="bottom end">
            <template v-slot:activator="{ props }">
              <v-btn v-bind="props" variant="tonal" :color="isDark ? 'grey-lighten-2' : 'grey-darken-3'" class="px-4 font-weight-bold text-caption text-uppercase letter-spacing-1 mr-2" style="border-radius: 6px;" height="40">
                Mais Ações <v-icon end>mdi-chevron-down</v-icon>
              </v-btn>
            </template>
            <v-list density="compact" class="rounded-lg border-thin shadow-lg" :bg-color="isDark ? 'grey-darken-4' : 'white'">
              <v-list-item @click="openImportNfeModal" class="hover-bg-light">
                <template v-slot:prepend><v-icon size="small" color="indigo-darken-2">mdi-file-xml-box</v-icon></template>
                <v-list-item-title class="font-weight-bold">Entrada (NF-e XML)</v-list-item-title>
              </v-list-item>
              <v-list-item v-if="canConfigAlerts" @click="openSettingsModal" class="hover-bg-light">
                <template v-slot:prepend><v-icon size="small" color="blue-grey-darken-3">mdi-bell-cog</v-icon></template>
                <v-list-item-title class="font-weight-bold">Alertas (SRE)</v-list-item-title>
              </v-list-item>
              <v-list-item @click="syncCajuiaItems" class="hover-bg-light">
                <template v-slot:prepend><v-icon size="small" color="orange-darken-4">mdi-sync</v-icon></template>
                <v-list-item-title class="font-weight-bold">Sincronizar (ERP)</v-list-item-title>
              </v-list-item>
            </v-list>
          </v-menu>

          <v-btn color="teal-darken-3" variant="flat" class="btn-3d px-3 px-md-4 font-weight-bold text-caption text-uppercase letter-spacing-1 flex-shrink-0 shadow-button" prepend-icon="mdi-plus" height="40" @click="openDialog()">
            Novo Material
          </v-btn>
        </div>
      </div>

      <div class="px-4 px-md-6 py-2 flex-shrink-0">
        <v-row dense class="d-none d-md-flex">
          <v-col cols="12" sm="6" md="3" v-for="(kpi, idx) in kpiList" :key="idx">
            <v-card class="kpi-card kpi-rect hover-elevate py-3 px-4 cursor-pointer" :class="kpi.gradient" v-ripple elevation="2">
              <div class="kpi-bg-icon"><v-icon>{{ kpi.icon }}</v-icon></div>
              <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                <div class="d-flex align-center" style="gap: 8px;">
                  <v-icon size="18" class="opacity-80">{{ kpi.icon }}</v-icon>
                  <span class="kpi-label">{{ kpi.label }}</span>
                </div>
                <div class="kpi-number-group my-1">
                  <span class="kpi-value">{{ kpi.value }}</span>
                </div>
                <div class="kpi-footer mt-1">{{ kpi.footer }}</div>
              </div>
            </v-card>
          </v-col>
        </v-row>
      </div>

      <div class="px-4 px-md-6 pt-2 pb-0 flex-shrink-0">
        <div class="fichario-wrapper d-flex align-end gap-1 overflow-x-auto hide-scrollbar">
            <div
                v-for="tab in customTabs"
                :key="tab.id"
                class="fichario-tab d-flex align-center gap-2"
                :class="{ 'active': currentTab === tab.id, 'dark-mode': isDark, 'tab-archive': tab.id === 'archive' }"
                @click="currentTab = tab.id"
            >
                <v-icon size="16" class="tab-icon">{{ tab.id === 'archive' ? 'mdi-archive-outline' : 'mdi-folder-outline' }}</v-icon>
                <span class="text-truncate font-weight-black text-caption text-uppercase tracking-wide">{{ tab.name }}</span>
                <v-icon v-if="tab.isDeletable" size="14" class="tab-close-btn ml-1" @click.stop="deleteTab(tab.id)">mdi-close-circle</v-icon>
            </div>
            <v-btn icon="mdi-plus" size="small" variant="tonal" color="teal-darken-3" class="mb-1 ml-2 shadow-sm" @click="newTabModal.show = true"></v-btn>
        </div>

        <div class="controls-bar d-flex align-center justify-space-between flex-wrap shadow-sm rounded-b-lg border-x border-b px-4 py-3" :class="isDark ? 'bg-glass-dark border-white-10' : 'bg-white border-grey-lighten-2'" style="gap: 10px;">
          <v-chip-group v-model="unitFilter" mandatory selected-class="bg-teal-darken-3 text-white">
            <v-chip value="all" size="small" variant="outlined" class="font-weight-bold chip-3d">TODOS</v-chip>
            <v-chip value="m" size="small" variant="outlined" class="font-weight-bold chip-3d">METROS (M)</v-chip>
            <v-chip value="kg" size="small" variant="outlined" class="font-weight-bold chip-3d">QUILOS (KG)</v-chip>
          </v-chip-group>

          <div class="d-flex align-center flex-grow-1 justify-end" style="gap: 10px;">
            <div class="search-wrap d-flex align-center flex-grow-1" :class="isDark ? 'search-dark bg-black-20 border-white-10 rounded' : 'search-light bg-white border rounded'" style="max-width: 400px;">
              <v-icon :color="isDark ? 'white-70' : 'grey-darken-1'" class="ml-2">mdi-magnify</v-icon>
              <input v-model="search" type="text" placeholder="Pesquisar material, EAN ou ID..." class="clean-input flex-grow-1 font-weight-bold pa-2" :class="isDark ? 'text-white' : 'text-grey-darken-4'" />
            </div>
            <v-btn variant="flat" class="btn-3d font-weight-bold" height="40" color="teal-darken-3" @click="fetchStock" prepend-icon="mdi-refresh">
              Atualizar
            </v-btn>
          </div>
        </div>
      </div>

      <div class="flex-grow-1 overflow-hidden d-flex flex-column transition-all px-4 px-md-6 py-4">
        <v-card class="flex-grow-1 d-flex flex-column rounded-lg border-thin overflow-hidden relative" :class="isDark ? 'glass-card border-white-05' : 'bg-white shadow-sm'" :elevation="0">
          <div class="grid-scroll flex-grow-1 overflow-auto custom-scroll relative">

            <div class="grid-header sticky-head border-b" :class="[isDark ? 'grid-surface-dark' : 'grid-surface-light']" style="grid-template-columns: 50px 80px 2.5fr 120px 80px 120px 120px 120px 220px; min-width: 1300px;">
              <div class="cell center header-text px-0">
                 <v-checkbox v-model="isAllSelected" hide-details density="compact" color="teal-darken-3" @click.stop="toggleSelectAll"></v-checkbox>
              </div>
              <div class="cell center header-text">ID ERP</div>
              <div class="cell header-text">Material / Descrição Técnica</div>
              <div class="cell center header-text">Cód. Barras</div>
              <div class="cell center header-text">UN</div>
              <div class="cell center header-text">Saldo</div>
              <div class="cell center header-text">Custo</div>
              <div class="cell center header-text">Status</div>
              <div class="cell center header-text">Ações</div>
            </div>

            <div v-if="loading" class="d-flex flex-column justify-center align-center h-100 py-10 min-w-full">
              <v-progress-circular indeterminate color="teal-darken-3" size="48" width="4"></v-progress-circular>
            </div>

            <div v-else-if="paginatedItems.length === 0" class="d-flex flex-column justify-center align-center h-100 py-10 min-w-full opacity-60">
              <v-icon size="64">mdi-folder-open-outline</v-icon>
              <span class="text-body-1 mt-4 font-weight-bold">Esta pasta está vazia.</span>
            </div>

            <div
              v-else
              v-for="(item, index) in paginatedItems"
              :key="item.id"
              class="grid-row transition-all"
              :class="[isDark ? 'grid-row-dark' : 'grid-row-light', zebraClass(index), { 'row-selected': isItemSelected(item) }]"
              style="grid-template-columns: 50px 80px 2.5fr 120px 80px 120px 120px 120px 220px; min-width: 1300px;"
              @click="toggleSelection(item)"
            >
              <div class="cell center px-0" @click.stop>
                 <v-checkbox v-model="selectedItems" :value="item" hide-details density="compact" color="teal-darken-3"></v-checkbox>
              </div>

              <div class="cell center">
                <span class="pill-ref font-weight-black" :class="item.gestao_click_id ? 'bg-blue-lighten-5 text-blue-darken-3' : 'bg-grey-lighten-4 text-grey-darken-4'">
                  {{ item.gestao_click_id || 'LOCAL' }}
                </span>
              </div>

              <div class="cell">
                <div class="d-flex align-center w-100 overflow-hidden">
                  <v-icon size="18" :color="item.fabric_type?.startsWith('CJ') ? 'orange-darken-4' : 'grey-darken-1'" class="mr-3 opacity-80">
                    {{ item.fabric_type?.startsWith('CJ') ? 'mdi-fruit-cherries' : 'mdi-texture-box' }}
                  </v-icon>
                  <div class="d-flex flex-column text-truncate">
                      <span class="font-weight-medium text-truncate w-100 list-text-11" :class="isDark ? 'text-white' : 'text-grey-darken-4'">{{ item.fabric_type }}</span>
                      <span class="text-[10px] opacity-60 font-weight-bold" v-if="item.ncm">NCM: {{ item.ncm }}</span>
                  </div>
                </div>
              </div>

              <div class="cell center">
                  <span class="font-mono font-weight-medium list-text-11" :class="isDark ? 'text-grey-lighten-1' : 'text-grey-darken-2'">{{ item.barcode || '---' }}</span>
              </div>

              <div class="cell center">
                <span class="font-weight-bold opacity-70 text-uppercase list-text-11">{{ item.unit_of_measure }}</span>
              </div>

              <div class="cell center">
                <span class="font-mono font-weight-black" :class="isDark ? 'text-white' : 'text-grey-darken-4'" style="font-size: 15px;">{{ Number(item.available_meters || 0).toLocaleString('pt-BR', { maximumFractionDigits: 2 }) }}</span>
              </div>

              <div class="cell center">
                <span v-if="canViewFinancials" class="font-mono font-weight-bold text-teal-darken-3 list-text-11">{{ formatCurrency(item.base_price) }}</span>
                <v-icon v-else size="16" class="opacity-40" title="Acesso restrito">mdi-eye-off-outline</v-icon>
              </div>

              <div class="cell center">
                <v-chip size="default" variant="flat" :color="getStockStatus(item).color" class="font-weight-bold text-uppercase px-3 chip-3d text-white" style="font-size: 11px; height: 28px;">
                    {{ getStockStatus(item).label }}
                </v-chip>
              </div>

              <div class="cell center" @click.stop>
                <div class="actions-inline d-flex flex-nowrap gap-2">
                  <v-tooltip text="Rastreabilidade & Lotes" location="top" content-class="tooltip-dark">
                      <template v-slot:activator="{ props }"><v-btn v-bind="props" icon size="small" class="action-btn btn-3d bg-amber-lighten-4 text-amber-darken-4" @click.stop="openHistoryModal(item)" variant="flat"><v-icon size="16">mdi-history</v-icon></v-btn></template>
                  </v-tooltip>
                  <v-tooltip text="Configurações do Item" location="top" content-class="tooltip-dark">
                      <template v-slot:activator="{ props }"><v-btn v-bind="props" icon size="small" class="action-btn btn-3d bg-indigo-lighten-4 text-indigo-darken-4" @click.stop="openConfigModal(item)" variant="flat"><v-icon size="16">mdi-cog</v-icon></v-btn></template>
                  </v-tooltip>
                  <v-tooltip text="Imprimir Etiqueta" location="top" content-class="tooltip-dark">
                      <template v-slot:activator="{ props }"><v-btn v-bind="props" icon size="small" class="action-btn btn-3d bg-grey-lighten-2 text-grey-darken-3" @click.stop="openLabelModal(item)" variant="flat"><v-icon size="16">mdi-printer</v-icon></v-btn></template>
                  </v-tooltip>
                  <v-tooltip text="Clonar Item" location="top" content-class="tooltip-dark">
                      <template v-slot:activator="{ props }"><v-btn v-bind="props" icon size="small" class="action-btn btn-3d bg-blue-grey-lighten-4 text-blue-grey-darken-4" @click.stop="cloneItem(item)" variant="flat"><v-icon size="16">mdi-content-copy</v-icon></v-btn></template>
                  </v-tooltip>
                  <v-tooltip text="Editar Item" location="top" content-class="tooltip-dark">
                      <template v-slot:activator="{ props }"><v-btn v-bind="props" icon size="small" class="action-btn btn-3d action-edit" @click.stop="openDialog(item)" variant="flat"><v-icon size="16">mdi-pencil</v-icon></v-btn></template>
                  </v-tooltip>
                  <v-tooltip text="Excluir Item" location="top" content-class="tooltip-dark">
                      <template v-slot:activator="{ props }"><v-btn v-bind="props" icon size="small" class="action-btn btn-3d action-del" @click.stop="deleteItem(item)" variant="flat"><v-icon size="16">mdi-trash-can-outline</v-icon></v-btn></template>
                  </v-tooltip>
                </div>
              </div>
            </div>
          </div>

          <div class="flex-shrink-0 border-t px-4 py-2 d-flex align-center justify-space-between z-20" :class="isDark ? 'bg-surface-variant border-top-white-05' : 'bg-white'">
            <div class="text-caption font-weight-bold opacity-70">
              Página <strong class="text-teal-darken-3">{{ page }}</strong> de {{ pageCount }} ({{ filteredItems.length }} registros)
            </div>
            <v-pagination
               v-model="page"
               :length="pageCount"
               :total-visible="5"
               density="compact"
               active-color="teal-darken-3"
               variant="tonal"
               size="small"
            ></v-pagination>
          </div>
        </v-card>
      </div>

      <v-scale-transition origin="bottom center">
         <div v-if="selectedItems.length > 0" class="selection-island-wrapper">
             <div class="selection-island elevation-10">
                 <div class="d-flex align-center pr-4 border-r border-white-20 mr-4">
                     <v-btn icon size="small" variant="text" color="white" @click="selectedItems = []">
                        <v-icon>mdi-close</v-icon>
                     </v-btn>
                     <span class="text-body-2 font-weight-bold text-white ml-2 text-no-wrap">
                        {{ selectedItems.length }} Selecionados
                     </span>
                 </div>

                 <div class="d-flex align-center overflow-x-auto" style="gap: 8px;">
                     <v-menu location="top center" offset="15">
                         <template v-slot:activator="{ props }">
                             <v-btn v-bind="props" variant="text" color="white" class="font-weight-bold text-capitalize" prepend-icon="mdi-folder-move">Mover Pasta</v-btn>
                         </template>
                         <v-card class="bg-grey-darken-4 text-white rounded-xl border-white-05 shadow-2xl" min-width="200">
                             <v-list density="compact" class="bg-transparent">
                                 <div class="px-4 py-2 text-[10px] text-uppercase font-weight-black opacity-60">Escolha o destino</div>
                                 <v-list-item v-for="tab in customTabs" :key="tab.id" @click="bulkMoveToTab(tab.id)" class="hover-bg-dark">
                                     <template v-slot:prepend><v-icon size="18" color="grey-lighten-1">{{ tab.id === 'archive' ? 'mdi-archive' : 'mdi-folder' }}</v-icon></template>
                                     <v-list-item-title class="font-weight-bold ml-2">{{ tab.name }}</v-list-item-title>
                                 </v-list-item>
                             </v-list>
                         </v-card>
                     </v-menu>

                     <v-divider vertical class="border-white-20 mx-1"></v-divider>

                     <v-menu location="top center" offset="15">
                         <template v-slot:activator="{ props }">
                             <v-btn v-bind="props" variant="text" color="blue-lighten-2" class="font-weight-bold text-capitalize" prepend-icon="mdi-toggle-switch">Visibilidade / Alertas</v-btn>
                         </template>
                         <v-card class="bg-grey-darken-4 text-white rounded-xl border-white-05 shadow-2xl" min-width="240">
                             <v-list density="compact" class="bg-transparent">
                                 <v-list-item @click="bulkToggle('visible_in_sales', true)" class="hover-bg-dark"><v-list-item-title class="text-teal-lighten-2 font-weight-bold"><v-icon start size="18">mdi-storefront</v-icon> Mostrar no NewOrder</v-list-item-title></v-list-item>
                                 <v-list-item @click="bulkToggle('visible_in_sales', false)" class="hover-bg-dark"><v-list-item-title class="text-grey-lighten-1 font-weight-bold"><v-icon start size="18">mdi-storefront-off</v-icon> Ocultar do NewOrder</v-list-item-title></v-list-item>
                                 <v-divider class="my-1 border-white-05"></v-divider>
                                 <v-list-item @click="bulkToggle('alert_enabled', true)" class="hover-bg-dark"><v-list-item-title class="text-error-lighten-1 font-weight-bold"><v-icon start size="18">mdi-bell-ring</v-icon> Ligar Alertas Críticos</v-list-item-title></v-list-item>
                                 <v-list-item @click="bulkToggle('alert_enabled', false)" class="hover-bg-dark"><v-list-item-title class="text-grey-lighten-1 font-weight-bold"><v-icon start size="18">mdi-bell-off</v-icon> Desligar Alertas Críticos</v-list-item-title></v-list-item>
                             </v-list>
                         </v-card>
                     </v-menu>

                     <v-divider vertical class="border-white-20 mx-1"></v-divider>

                     <v-btn variant="flat" color="red-darken-1" class="font-weight-bold px-4 btn-3d text-capitalize" prepend-icon="mdi-trash-can-outline" @click="bulkDelete">Excluir</v-btn>
                 </div>
             </div>
         </div>
      </v-scale-transition>

      <v-dialog
          v-model="dialog"
          :width="mobile ? '100%' : '1100'"
          :fullscreen="mobile"
          persistent
          scrim="black opacity-80"
          transition="dialog-bottom-transition"
          class="fixed-dialog"
      >
          <v-card class="d-flex overflow-hidden rounded-lg fill-height shadow-xl" :class="mobile ? 'flex-column' : 'flex-row'" height="100%" style="max-height: 90vh;">
              <div class="modal-sidebar pa-6 d-flex flex-column text-white" :class="[isDark ? 'bg-grey-darken-4' : 'bg-teal-darken-4', mobile ? 'd-none' : '']" style="width: 280px; flex-shrink: 0; border-right: 1px solid rgba(255,255,255,0.1);">
                   <div class="d-flex align-center" style="gap: 12px;">
                      <div class="bg-white-20 p-3 rounded d-flex align-center justify-center" style="width: 48px; height: 48px;">
                          <v-icon size="32" color="white">mdi-warehouse</v-icon>
                      </div>
                      <div>
                          <h3 class="text-h6 font-weight-black leading-tight">{{ isEditing ? 'Atualizar' : 'Novo' }} Material</h3>
                          <div class="text-caption opacity-80">Controle e Tributação</div>
                      </div>
                  </div>
                  <div class="mt-6 bg-white-10 pa-4 rounded border-white-10">
                      <div class="text-caption font-weight-black opacity-70 mb-1 text-uppercase">Saldo Atual em Loja</div>
                      <div class="text-h4 font-weight-black">{{ Number(editedItem.current_stock || 0).toLocaleString('pt-BR', { maximumFractionDigits: 2 }) }} <span class="text-caption">{{ editedItem.unit_of_measure?.toUpperCase() }}</span></div>
                  </div>
                  <v-spacer></v-spacer>
                  <div class="text-[10px] font-weight-bold opacity-50 uppercase tracking-widest d-flex align-center gap-2">
                     <v-icon size="14">mdi-shield-account-outline</v-icon> Acesso Administrativo
                  </div>
              </div>

              <div class="flex-grow-1 d-flex flex-column h-100 overflow-hidden relative" :class="isDark ? 'bg-grey-darken-4 text-white' : 'bg-grey-lighten-4'">
                  <div class="pa-4 border-b flex-shrink-0 d-flex justify-space-between align-center" :class="isDark ? 'bg-grey-darken-3' : 'bg-white'">
                      <div class="text-subtitle-1 font-weight-black d-flex align-center gap-2">
                          <v-icon color="teal-darken-3">mdi-file-document-edit-outline</v-icon> Ficha do Material
                      </div>
                      <v-btn icon="mdi-close" variant="text" :color="isDark ? 'white' : 'grey-darken-1'" @click="close"></v-btn>
                  </div>

                  <div class="flex-grow-1 overflow-y-auto custom-scroll pa-4 pa-md-6 absolute-fill" :class="isDark ? 'bg-grey-darken-4' : 'bg-grey-lighten-4'">
                      <v-form @submit.prevent="save" id="stockForm">

                          <div class="pa-5 rounded-lg border shadow-sm mb-6" :class="isDark ? 'bg-grey-darken-3 border-white-10' : 'bg-white border-grey-lighten-2'">
                              <div class="text-subtitle-2 font-weight-black text-uppercase mb-4 d-flex align-center gap-2" :class="isDark ? 'text-teal-lighten-3' : 'text-teal-darken-3'">
                                  <v-icon size="18">mdi-tag-text-outline</v-icon> Identificação Básica
                              </div>
                              <v-row class="row-gap">
                                  <v-col cols="12" md="8">
                                      <v-text-field v-model="editedItem.fabric_type" label="Nome / Descrição do Material*" variant="outlined" density="comfortable" color="teal-darken-3" class="ui-field font-weight-bold" :class="isDark ? '' : 'bg-grey-lighten-5'"></v-text-field>
                                  </v-col>
                                  <v-col cols="12" md="4">
                                      <v-select v-model="editedItem.target_tab" :items="customTabs" item-title="name" item-value="id" label="Pasta de Destino" variant="outlined" density="comfortable" color="teal-darken-3" class="ui-field font-weight-bold" :class="isDark ? '' : 'bg-teal-lighten-5'"></v-select>
                                  </v-col>
                              </v-row>
                          </div>

                          <div class="pa-5 rounded-lg border shadow-sm mb-6" :class="isDark ? 'bg-grey-darken-3 border-white-10' : 'bg-white border-grey-lighten-2'">
                              <div class="text-subtitle-2 font-weight-black text-uppercase mb-4 d-flex align-center gap-2" :class="isDark ? 'text-grey-lighten-1' : 'text-grey-darken-3'">
                                  <v-icon size="18">mdi-bank-outline</v-icon> Fiscal e Códigos
                              </div>
                              <v-row class="row-gap">
                                  <v-col cols="12" md="4">
                                      <div class="d-flex align-center justify-space-between mb-1">
                                          <span class="text-[10px] text-uppercase font-weight-bold opacity-70">Cód. Barras</span>
                                          <v-btn size="x-small" variant="text" color="teal-darken-3" prepend-icon="mdi-barcode-scan" class="text-none font-weight-bold px-1" @click="generateBarcode">Gerar Auto</v-btn>
                                      </div>
                                      <v-text-field v-model="editedItem.barcode" label="EAN/GTIN" variant="outlined" density="comfortable" color="teal-darken-3" class="ui-field" append-inner-icon="mdi-barcode" hide-details :class="isDark ? '' : 'bg-grey-lighten-5'"></v-text-field>
                                  </v-col>

                                  <v-col cols="12" md="5">
                                      <div class="d-flex align-center justify-space-between mb-1">
                                          <span class="text-[10px] text-uppercase font-weight-bold opacity-70">NCM (API Brasil)</span>
                                          <v-btn size="x-small" variant="text" color="teal-darken-3" class="text-none font-weight-bold px-1" @click="forceSearchNCM"><v-icon start size="14">mdi-magic-staff</v-icon> Buscar Pelo Nome</v-btn>
                                      </div>
                                      <v-combobox
                                          v-model="editedItem.ncm"
                                          :items="ncmSuggestions"
                                          item-title="title"
                                          item-value="value"
                                          :return-object="false"
                                          :loading="loadingNcm"
                                          label="Digite ou busque o NCM"
                                          variant="outlined"
                                          density="comfortable"
                                          color="teal-darken-3"
                                          class="ui-field font-weight-bold"
                                          hide-details
                                          :class="isDark ? '' : 'bg-grey-lighten-5'"
                                          @update:search="val => searchNCMDebounced(val)"
                                      ></v-combobox>
                                  </v-col>

                                  <v-col cols="12" md="3">
                                      <div class="d-flex align-center justify-space-between mb-1">
                                          <span class="text-[10px] text-uppercase font-weight-bold opacity-70">Integração</span>
                                      </div>
                                      <v-text-field v-model="editedItem.gestao_click_id" label="ID ERP (Opcional)" variant="outlined" density="comfortable" color="teal-darken-3" class="ui-field" placeholder="Sincronização" hide-details :class="isDark ? '' : 'bg-grey-lighten-5'"></v-text-field>
                                  </v-col>
                              </v-row>
                          </div>

                          <v-row class="row-gap mb-6">
                              <v-col cols="12" md="6">
                                 <div class="pa-5 rounded-lg border shadow-sm h-100" :class="isDark ? 'bg-grey-darken-3 border-white-10' : 'bg-white border-grey-lighten-2'">
                                    <div class="text-subtitle-2 font-weight-black text-uppercase mb-4 d-flex align-center gap-2" :class="isDark ? 'text-orange-lighten-2' : 'text-orange-darken-4'">
                                        <v-icon size="18">mdi-swap-vertical</v-icon> Movimentação de Estoque
                                    </div>

                                    <div class="d-flex flex-column gap-3 mb-4">
                                        <v-btn-toggle v-model="editedItem.qty_operation" mandatory divided class="w-100 rounded border ui-field" :class="isDark ? 'bg-grey-darken-4' : 'bg-grey-lighten-4'" color="teal-darken-3" style="height: 48px;">
                                          <v-btn value="in" class="flex-grow-1 font-weight-black text-success"><v-icon start>mdi-arrow-down-thick</v-icon> Entrada (+)</v-btn>
                                          <v-btn value="out" class="flex-grow-1 font-weight-black text-error"><v-icon start>mdi-arrow-up-thick</v-icon> Saída (-)</v-btn>
                                        </v-btn-toggle>

                                        <div class="d-flex align-center gap-2 mt-2">
                                           <v-text-field v-model.number="editedItem.qty_value" type="number" label="Quantidade a movimentar" variant="outlined" density="comfortable" color="teal-darken-3" class="font-weight-black ui-field flex-grow-1" min="0" placeholder="Ex: 10" hide-details :class="isDark ? '' : 'bg-grey-lighten-5'"></v-text-field>
                                           <v-select v-model="editedItem.unit_of_measure" :items="['m', 'kg', 'un', 'cx']" label="UN" variant="outlined" density="comfortable" color="teal-darken-3" class="ui-field font-weight-bold" style="max-width: 100px;" hide-details :class="isDark ? '' : 'bg-grey-lighten-5'"></v-select>
                                        </div>

                                        <v-expand-transition>
                                          <div v-if="editedItem.qty_operation === 'in'" class="mt-3">
                                            <v-text-field
                                              v-model="editedItem.batch_code"
                                              label="Código do Lote (Ex: CHIFFON-LOTE-01)"
                                              variant="outlined"
                                              density="comfortable"
                                              color="teal-darken-3"
                                              class="font-weight-bold ui-field"
                                              placeholder="Deixe vazio para gerar automático"
                                              hide-details
                                              :class="isDark ? '' : 'bg-grey-lighten-5'">
                                            </v-text-field>
                                          </div>
                                        </v-expand-transition>
                                    </div>
                                    <div class="text-[11px] font-weight-medium lh-1-2" :class="isDark ? 'text-grey-lighten-1' : 'text-grey-darken-1'">
                                       O valor será processado na hora de salvar. Deixe <strong>Zero</strong> se não quiser alterar o saldo atual.
                                    </div>
                                 </div>
                              </v-col>

                              <v-col cols="12" md="6">
                                 <div class="pa-5 rounded-lg border shadow-sm h-100" :class="isDark ? 'bg-grey-darken-3 border-white-10' : 'bg-white border-grey-lighten-2'">
                                    <div class="text-subtitle-2 font-weight-black text-uppercase mb-4 d-flex align-center gap-2" :class="isDark ? 'text-blue-lighten-3' : 'text-blue-darken-3'">
                                        <v-icon size="18">mdi-cash-multiple</v-icon> Precificação e Alertas
                                    </div>
                                    <v-row class="row-gap mt-1">
                                       <v-col cols="12">
                                         <v-text-field v-model.number="editedItem.base_price" label="Custo Base por Unidade (R$)" type="number" variant="outlined" density="comfortable" color="teal-darken-3" class="ui-field font-weight-black text-teal-darken-3" prefix="R$" hide-details :class="isDark ? '' : 'bg-grey-lighten-5'"></v-text-field>
                                       </v-col>
                                       <v-col cols="12" class="mt-2">
                                         <v-text-field v-model.number="editedItem.low_stock_threshold" label="Alerta de Ruptura (Estoque Mínimo)" type="number" variant="outlined" density="comfortable" class="ui-field font-weight-bold" hint="O sistema avisará quando o saldo for menor que este valor" persistent-hint :class="isDark ? '' : 'bg-grey-lighten-5'"></v-text-field>
                                       </v-col>
                                    </v-row>
                                 </div>
                              </v-col>
                          </v-row>
                      </v-form>
                  </div>

                  <div class="pa-4 border-t d-flex justify-end align-center flex-shrink-0" :class="isDark ? 'bg-grey-darken-3' : 'bg-white'" style="gap: 12px; height: 80px; box-shadow: 0 -4px 10px rgba(0,0,0,0.03);">
                      <v-btn variant="outlined" class="btn-3d px-8 font-weight-bold text-body-2" height="48" @click="close" :disabled="isSaving">Cancelar</v-btn>
                      <v-btn color="teal-darken-3" variant="flat" class="btn-3d px-8 font-weight-black text-body-1" height="48" type="submit" form="stockForm" :loading="isSaving">
                          <v-icon start>mdi-content-save-check</v-icon> Salvar Material
                      </v-btn>
                  </div>
              </div>
          </v-card>
      </v-dialog>

      <!-- NOVO MODAL: Rastreabilidade (Ledger e Lotes) -->
      <v-dialog v-model="historyModal.show" max-width="1100" scrollable>
        <v-card class="rounded-xl shadow-2xl border-thin" :class="isDark ? 'bg-grey-darken-4 text-white' : 'bg-white'">
          <div class="pa-4 border-b d-flex align-center justify-space-between" :class="isDark ? 'bg-grey-darken-3 border-white-10' : 'bg-surface-light border-grey-lighten-2'">
            <div class="d-flex align-center gap-3">
              <v-avatar color="amber-lighten-5" size="40" class="text-amber-darken-4 rounded-lg"><v-icon>mdi-history</v-icon></v-avatar>
              <div>
                <h3 class="text-subtitle-1 font-weight-black leading-none mb-1 text-uppercase tracking-widest">Rastreabilidade & Lotes</h3>
                <div class="text-caption opacity-70 font-mono">{{ historyModal.materialName }}</div>
              </div>
            </div>
            <v-btn icon="mdi-close" variant="text" size="small" @click="historyModal.show = false"></v-btn>
          </div>

          <v-card-text class="pa-0">
            <v-tabs v-model="historyModal.tab" color="teal-darken-3" bg-color="transparent" class="border-b border-white-10">
              <v-tab value="ledger" class="font-weight-bold text-none"><v-icon start>mdi-list-box-outline</v-icon> Livro-Razão (Histórico)</v-tab>
              <v-tab value="batches" class="font-weight-bold text-none"><v-icon start>mdi-barcode-scan</v-icon> Lotes Disponíveis</v-tab>
            </v-tabs>

            <v-window v-model="historyModal.tab" class="pa-4">
              <!-- Aba de Histórico (Ledger) -->
              <v-window-item value="ledger">
                <v-data-table
                  :items="historyModal.ledger"
                  :loading="historyModal.loading"
                  density="compact"
                  class="bg-transparent text-body-2"
                >
                  <template v-slot:item="{ item }">
                    <tr>
                      <td class="font-mono text-caption">{{ formatDateFull(item.created_at) }}</td>
                      <td>
                        <v-chip size="x-small" :color="item.operation_type === 'IN' ? 'success' : (item.operation_type === 'OUT' || item.operation_type === 'PRODUCTION_CONSUMPTION' ? 'error' : 'warning')">
                          {{ item.operation_type }}
                        </v-chip>
                      </td>
                      <td class="font-weight-bold">{{ item.qty_before }} -> {{ item.qty_after }}</td>
                      <td class="text-caption">
                        <div v-if="item.order_number" class="text-teal-darken-3 font-weight-bold">#{{ item.order_number }} - {{ item.client_name }}</div>
                        <div class="opacity-70">{{ item.notes || '-' }}</div>
                      </td>
                      <td class="font-mono text-caption opacity-60">{{ item.stock_batches?.batch_code || 'Geral' }}</td>
                    </tr>
                  </template>
                  <template v-slot:headers>
                    <tr>
                      <th class="font-weight-bold text-uppercase text-caption">Data/Hora</th>
                      <th class="font-weight-bold text-uppercase text-caption">Operação</th>
                      <th class="font-weight-bold text-uppercase text-caption">Movimento</th>
                      <th class="font-weight-bold text-uppercase text-caption">Referência / Pedido</th>
                      <th class="font-weight-bold text-uppercase text-caption">Lote</th>
                    </tr>
                  </template>
                </v-data-table>
              </v-window-item>

              <!-- Aba de Lotes -->
              <v-window-item value="batches">
                <v-data-table
                  :items="historyModal.batches"
                  :loading="historyModal.loading"
                  density="compact"
                  class="bg-transparent text-body-2"
                >
                  <template v-slot:item="{ item }">
                    <tr>
                      <td class="font-mono font-weight-bold">{{ item.batch_code }}</td>
                      <td>{{ item.initial_qty }}</td>
                      <td class="font-weight-bold" :class="item.current_qty > 0 ? 'text-success' : 'text-error'">{{ item.current_qty }}</td>
                      <td>{{ formatCurrency(item.cost_per_unit) }}</td>
                      <td class="text-caption opacity-70">{{ formatDateFull(item.created_at) }}</td>
                    </tr>
                  </template>
                  <template v-slot:headers>
                    <tr>
                      <th class="font-weight-bold text-uppercase text-caption">Código do Lote</th>
                      <th class="font-weight-bold text-uppercase text-caption">Qtd Inicial</th>
                      <th class="font-weight-bold text-uppercase text-caption">Qtd Atual</th>
                      <th class="font-weight-bold text-uppercase text-caption">Custo UN</th>
                      <th class="font-weight-bold text-uppercase text-caption">Data de Entrada</th>
                    </tr>
                  </template>
                </v-data-table>
              </v-window-item>
            </v-window>
          </v-card-text>
        </v-card>
      </v-dialog>


      <v-dialog v-model="newTabModal.show" max-width="450">
          <v-card class="pa-6 rounded-xl border-t-lg border-t-primary shadow-2xl" :class="isDark ? 'bg-grey-darken-4 text-white' : 'bg-white'">
              <div class="d-flex align-center gap-3 mb-6">
                  <v-avatar color="teal-lighten-5" size="48" class="text-teal-darken-3 rounded-lg"><v-icon size="28">mdi-folder-plus-outline</v-icon></v-avatar>
                  <div>
                     <h3 class="text-h6 font-weight-black leading-none mb-1">Criar Nova Pasta</h3>
                     <span class="text-caption opacity-70">Organize seu estoque em abas personalizadas.</span>
                  </div>
              </div>

              <v-text-field v-model="newTabModal.name" label="Nome da Pasta" variant="outlined" density="comfortable" color="teal-darken-3" class="ui-field font-weight-bold" autofocus @keyup.enter="saveNewTab"></v-text-field>

              <div class="d-flex justify-end gap-3 mt-2">
                  <v-btn variant="outlined" class="btn-3d font-weight-bold" height="40" @click="newTabModal.show = false">Cancelar</v-btn>
                  <v-btn color="teal-darken-3" variant="flat" class="btn-3d px-6 font-weight-black" height="40" @click="saveNewTab" :loading="newTabModal.loading">Criar</v-btn>
              </div>
          </v-card>
      </v-dialog>

      <v-dialog v-model="sreModal.show" max-width="500">
          <v-card class="rounded-lg overflow-hidden" :class="isDark ? 'bg-grey-darken-4 text-white' : 'bg-white'">
              <div class="px-6 py-4 border-b d-flex align-center justify-space-between" :class="isDark ? 'bg-grey-darken-3' : 'bg-grey-lighten-5'">
                  <div>
                      <div class="text-caption font-weight-black opacity-70 text-uppercase">Configurações SRE</div>
                      <div class="text-h6 font-weight-black">Alertas do Sistema</div>
                  </div>
                  <v-btn icon variant="text" @click="sreModal.show = false"><v-icon>mdi-close</v-icon></v-btn>
              </div>
              <div class="pa-6 text-center">
                  <v-icon size="64" color="blue-grey-darken-2" class="mb-4">mdi-bell-cog-outline</v-icon>
                  <p class="text-body-1 font-weight-medium">A interface de configuração de gatilhos do SRE está sendo movida para o Cockpit Administrativo Global.</p>
                  <p class="text-caption opacity-70 mt-2">Em breve, você poderá configurar os disparos por WhatsApp e e-mail diretamente por aqui.</p>
              </div>
              <div class="pa-4 border-t d-flex justify-end" :class="isDark ? 'bg-grey-darken-3' : 'bg-grey-lighten-5'">
                  <v-btn color="blue-grey-darken-3" variant="flat" class="btn-3d" @click="sreModal.show = false">Entendi</v-btn>
              </div>
          </v-card>
      </v-dialog>

      <v-dialog v-model="importNfeModal.show" max-width="900" persistent scrollable>
        <v-card class="rounded-xl border-thin shadow-xl" :class="isDark ? 'bg-grey-darken-4' : 'bg-white'">
          <div class="pa-4 border-b d-flex align-center justify-space-between" :class="isDark ? 'bg-grey-darken-3 border-white-10' : 'bg-surface-light'">
              <h3 class="text-subtitle-1 font-weight-black d-flex align-center gap-2 text-uppercase tracking-widest ls-1">
                  <v-icon color="indigo">mdi-file-xml-box</v-icon> Absorção de Estoque (NF-e)
              </h3>
              <v-btn icon="mdi-close" variant="text" size="small" @click="importNfeModal.show = false"></v-btn>
          </div>
          <v-card-text class="pa-6 custom-scroll" style="max-height: 70vh;">
            <div class="mb-6 d-flex align-center gap-4">
               <v-btn color="indigo-darken-2" variant="flat" class="btn-3d font-weight-bold text-none" @click="$refs.xmlInput.click()">
                 <v-icon start>mdi-upload</v-icon> Selecionar XML da Sefaz
               </v-btn>
               <input type="file" ref="xmlInput" accept=".xml" style="display: none" @change="handleNfeFileUpload" />
               <span v-if="importNfeModal.file" class="text-caption font-weight-bold opacity-80">{{ importNfeModal.file.name }}</span>
            </div>

            <div v-if="importNfeModal.nfeInfo.chave" class="pa-4 rounded-lg border-thin mb-6 d-flex flex-wrap gap-4" :class="isDark ? 'bg-grey-darken-3 border-white-10' : 'bg-grey-lighten-5'">
               <div class="flex-grow-1">
                  <div class="text-[10px] text-uppercase font-weight-bold opacity-70">Fornecedor / Emitente</div>
                  <div class="text-body-2 font-weight-black">{{ importNfeModal.nfeInfo.emitente }}</div>
               </div>
               <div>
                  <div class="text-[10px] text-uppercase font-weight-bold opacity-70">Emissão</div>
                  <div class="text-body-2 font-weight-black font-mono">{{ formatDateFull(importNfeModal.nfeInfo.data) }}</div>
               </div>
               <div>
                  <div class="text-[10px] text-uppercase font-weight-bold opacity-70">Valor NF</div>
                  <div class="text-body-2 font-weight-black font-mono text-success">{{ formatCurrency(importNfeModal.nfeInfo.valor) }}</div>
               </div>
               <div class="w-100">
                  <div class="text-[10px] text-uppercase font-weight-bold opacity-70">Chave de Acesso</div>
                  <div class="text-caption font-weight-bold font-mono">{{ importNfeModal.nfeInfo.chave }}</div>
               </div>
            </div>

            <div v-if="importNfeModal.items.length > 0">
               <div class="text-subtitle-2 font-weight-black text-uppercase mb-3 text-indigo">Mapeamento de Produtos</div>
               <v-table density="compact" class="border-thin rounded-lg" :class="isDark ? 'bg-grey-darken-4 text-white' : 'bg-white'">
                  <thead :class="isDark ? 'bg-grey-darken-3' : 'bg-grey-lighten-4'">
                     <tr>
                        <th class="font-weight-black text-caption text-uppercase">Produto na NF-e</th>
                        <th class="font-weight-black text-caption text-center text-uppercase">Qtd</th>
                        <th class="font-weight-black text-caption text-center text-uppercase">Unid</th>
                        <th class="font-weight-black text-caption text-uppercase" style="width: 300px;">Vincular ao Estoque Interno</th>
                     </tr>
                  </thead>
                  <tbody>
                     <tr v-for="(item, idx) in importNfeModal.items" :key="idx" :class="isDark ? 'hover-bg-grey-darken-3' : 'hover-bg-grey-lighten-5'">
                        <td class="text-caption py-2">
                           <div class="font-weight-bold">{{ item.xProd }}</div>
                           <div class="text-[10px] opacity-70 font-mono mt-1">EAN: {{ item.cEAN }}</div>
                        </td>
                        <td class="text-center font-mono font-weight-black">{{ item.qCom }}</td>
                        <td class="text-center font-weight-bold opacity-70">{{ item.uCom }}</td>
                        <td class="pa-2">
                           <v-autocomplete
                              v-model="item.matchedStockId"
                              :items="stockItems"
                              item-title="fabric_type"
                              item-value="id"
                              density="compact"
                              variant="outlined"
                              hide-details
                              placeholder="Selecione para vincular..."
                              clearable
                              class="ui-field"
                           >
                              <template v-slot:item="{ props, item: slotItem }">
                                 <v-list-item v-bind="props" :title="slotItem.raw.fabric_type" :subtitle="`Saldo Atual: ${slotItem.raw.available_meters} ${slotItem.raw.unit_of_measure}`"></v-list-item>
                              </template>
                           </v-autocomplete>
                        </td>
                     </tr>
                  </tbody>
               </v-table>
            </div>
          </v-card-text>
          <div class="pa-4 border-t d-flex justify-end gap-3" :class="isDark ? 'bg-grey-darken-3 border-white-10' : 'bg-surface-light'">
             <v-btn variant="outlined" class="btn-3d font-weight-bold" @click="importNfeModal.show = false" :disabled="importNfeModal.loading">Cancelar</v-btn>
             <v-btn color="indigo-darken-2" variant="flat" class="btn-3d font-weight-black px-6" @click="confirmNfeImport" :loading="importNfeModal.loading" :disabled="!importNfeModal.nfeInfo.chave || importNfeModal.items.length === 0">
                 <v-icon start>mdi-check-all</v-icon> Efetivar Entrada
             </v-btn>
          </div>
        </v-card>
      </v-dialog>

      <v-dialog v-model="configModal.show" max-width="500" persistent>
        <v-card class="rounded-xl shadow-2xl border-thin overflow-hidden" :class="isDark ? 'bg-grey-darken-4 text-white' : 'bg-white'">
          <div class="px-6 py-4 border-b d-flex align-center justify-space-between" :class="isDark ? 'bg-grey-darken-3 border-white-10' : 'bg-surface-light border-grey-lighten-2'">
              <div class="d-flex align-center gap-3">
                  <v-avatar color="indigo-lighten-5" size="40" class="text-indigo-darken-3 rounded-lg"><v-icon>mdi-cog</v-icon></v-avatar>
                  <div>
                      <h3 class="text-subtitle-1 font-weight-black leading-none mb-1 text-uppercase tracking-widest">Configurações</h3>
                      <div class="text-caption opacity-70 font-mono">{{ configModal.item?.fabric_type }}</div>
                  </div>
              </div>
              <v-btn icon="mdi-close" variant="text" size="small" @click="configModal.show = false"></v-btn>
          </div>

          <div class="pa-6 d-flex flex-column gap-4">
              <div class="pa-4 rounded-lg border-thin d-flex gap-3 align-start transition-all" :class="[isDark ? 'bg-grey-darken-3 border-white-10' : 'bg-grey-lighten-5', configModal.visible_in_sales ? 'border-s-4 border-s-teal-darken-2' : '']">
                  <v-switch v-model="configModal.visible_in_sales" color="teal-darken-2" hide-details density="compact" class="mt-0 pt-0"></v-switch>
                  <div>
                      <div class="font-weight-black text-body-2 mb-1 d-flex align-center gap-2"><v-icon size="16" color="teal-darken-2">mdi-storefront</v-icon> Visível no Ponto de Venda</div>
                      <div class="text-caption opacity-70">Se ativado, este item aparecerá na tela de vendas (NewOrder / PDV) para que os vendedores possam comercializá-lo. Desative se for um insumo interno.</div>
                  </div>
              </div>

              <div class="pa-4 rounded-lg border-thin d-flex gap-3 align-start transition-all" :class="[isDark ? 'bg-grey-darken-3 border-white-10' : 'bg-grey-lighten-5', configModal.alert_enabled ? 'border-s-4 border-s-error' : '']">
                  <v-switch v-model="configModal.alert_enabled" color="error" hide-details density="compact" class="mt-0 pt-0"></v-switch>
                  <div>
                      <div class="font-weight-black text-body-2 mb-1 d-flex align-center gap-2"><v-icon size="16" color="error">mdi-bell-ring</v-icon> Alertas do SRE Ativos</div>
                      <div class="text-caption opacity-70">Permite que o monitor de engenharia de confiabilidade (SRE) dispare alertas críticos (WhatsApp/Dashboard) caso o estoque atinja o limite mínimo.</div>
                  </div>
              </div>

              <div class="pa-4 rounded-lg border-thin d-flex gap-3 align-start transition-all" :class="[isDark ? 'bg-grey-darken-3 border-white-10' : 'bg-grey-lighten-5', configModal.include_in_kpi ? 'border-s-4 border-s-purple-darken-2' : '']">
                  <v-switch v-model="configModal.include_in_kpi" color="purple-darken-2" hide-details density="compact" class="mt-0 pt-0"></v-switch>
                  <div>
                      <div class="font-weight-black text-body-2 mb-1 d-flex align-center gap-2"><v-icon size="16" color="purple-darken-2">mdi-chart-line</v-icon> Impactar KPIs Financeiros</div>
                      <div class="text-caption opacity-70">Faz com que o valor deste material seja contabilizado no "Patrimônio Ativo" e nos gráficos de evolução financeira da empresa.</div>
                  </div>
              </div>
          </div>

          <div class="pa-4 border-t d-flex justify-end gap-3" :class="isDark ? 'bg-grey-darken-3 border-white-10' : 'bg-surface-light'">
             <v-btn variant="outlined" class="btn-3d font-weight-bold" @click="configModal.show = false" :disabled="configModal.loading">Cancelar</v-btn>
             <v-btn color="indigo-darken-2" variant="flat" class="btn-3d font-weight-black px-6" @click="saveConfigModal" :loading="configModal.loading">
                 <v-icon start>mdi-check</v-icon> Aplicar
             </v-btn>
          </div>
        </v-card>
      </v-dialog>

      <LabelGeneratorModal v-model="showLabelModal" :products="selectedProductsForLabel" />
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, computed, reactive, watch } from 'vue';
import { supabase } from '@/api/supabase';
import { useAppStore } from '@/stores/app';
import { useUserStore } from '@/stores/user';
import { useThemeStore } from '@/stores/theme';
import { useCompanyStore } from '@/stores/company';
import { gestaoApi } from '@/api/gestaoClick';
import { useDisplay } from 'vuetify';
import LabelGeneratorModal from '@/components/admin/LabelGeneratorModal.vue';
import axios from 'axios';
import { format } from 'date-fns';

const { mobile } = useDisplay();
const appStore = useAppStore();
const userStore = useUserStore();
const themeStore = useThemeStore();
const companyStore = useCompanyStore();
const isDark = computed(() => themeStore.currentMode !== 'light');

const stockItems = ref<any[]>([]);
const loading = ref(true);
const isSaving = ref(false);
const search = ref('');
const dialog = ref(false);
const isEditing = ref(false);
const unitFilter = ref('all');

// --- PAGINAÇÃO ---
const page = ref(1);
const itemsPerPage = 30;

const formatDate = (d:string) => d ? format(new Date(d), 'dd/MM/yy') : '-';
const formatDateFull = (d:string) => d ? format(new Date(d), 'dd/MM/yyyy HH:mm') : '-';
const formatCurrency = (v:number) => new Intl.NumberFormat('pt-BR',{style:'currency',currency:'BRL'}).format(Number(v)||0);
const formatNumber = (v:number) => new Intl.NumberFormat('pt-BR', { minimumFractionDigits: 0, maximumFractionDigits: 2 }).format(Number(v)||0);
const zebraClass = (i: number) => themeStore.currentMode === 'light' ? (i % 2 === 0 ? 'zebra-light-a' : 'zebra-light-b') : (i % 2 === 0 ? 'zebra-dark-a' : 'zebra-dark-b');

// --- SISTEMA DE PASTAS (FICHÁRIO) COM ORDENAÇÃO CORRETA ---
const currentTab = ref('production');
const defaultTabs = [
    { id: 'production', name: 'Linha de Produção', isDeletable: false },
    { id: 'ready_delivery', name: 'Pronta Entrega', isDeletable: false },
    { id: 'cajuia', name: 'Cajuia (CJ)', isDeletable: false }
];
const archiveTab = { id: 'archive', name: 'Arquivados', isDeletable: false };

const customTabs = ref([...defaultTabs, archiveTab]);
const newTabModal = reactive({ show: false, name: '', loading: false });

const sreModal = reactive({ show: false });
const openSettingsModal = () => { sreModal.show = true; };

// --- HISTÓRICO E LOTES (LEDGER) ---
const historyModal = reactive({
  show: false,
  loading: false,
  stockId: '',
  materialName: '',
  tab: 'ledger',
  ledger: [] as any[],
  batches: [] as any[]
});

const openHistoryModal = async (item: any) => {
  historyModal.stockId = item.id;
  historyModal.materialName = item.fabric_type;
  historyModal.show = true;
  historyModal.loading = true;
  historyModal.tab = 'ledger';
  historyModal.ledger = [];
  historyModal.batches = [];

  try {
    // Busca Lotes Ativos
    const { data: bData } = await supabase
      .from('stock_batches')
      .select('*')
      .eq('stock_id', item.id)
      .order('created_at', { ascending: false });

    historyModal.batches = bData || [];

    // Busca Histórico (Livro Razão)
    const { data: lData } = await supabase
      .from('stock_ledger')
      .select(`
        *,
        stock_batches ( batch_code )
      `)
      .eq('stock_id', item.id)
      .order('created_at', { ascending: false });

    historyModal.ledger = lData || [];
  } catch (error) {
    console.error("Erro ao carregar histórico", error);
  } finally {
    historyModal.loading = false;
  }
};


const loadCustomTabs = async () => {
    try {
        const { data } = await supabase.from('app_config').select('value').eq('key', 'stock_custom_tabs').maybeSingle();
        if (data && data.value) {
            const extraTabs = data.value as any[];
            customTabs.value = [...defaultTabs, ...extraTabs, archiveTab];
        }
    } catch (e) { console.error("Erro ao carregar pastas", e); }
};

const saveNewTab = async () => {
    if (!newTabModal.name.trim()) return appStore.showSnackbar('Digite um nome para a pasta', 'warning');
    newTabModal.loading = true;
    try {
        const slug = 'tab_' + Math.random().toString(36).substr(2, 6);
        const extraTabs = customTabs.value.filter(t => t.isDeletable);
        extraTabs.push({ id: slug, name: newTabModal.name.trim(), isDeletable: true });

        await supabase.from('app_config').upsert({ key: 'stock_custom_tabs', value: extraTabs });

        customTabs.value = [...defaultTabs, ...extraTabs, archiveTab];
        currentTab.value = slug;
        newTabModal.show = false;
        newTabModal.name = '';
        appStore.showSnackbar('Pasta criada com sucesso!', 'success');
    } catch (e) {
        appStore.showSnackbar('Erro ao criar pasta', 'error');
    } finally { newTabModal.loading = false; }
};

const deleteTab = async (tabId: string) => {
    if (!confirm('Deseja excluir esta pasta? Itens dentro dela ficarão "órfãos" (vão para Produção).')) return;
    try {
        const extraTabs = customTabs.value.filter(t => t.isDeletable && t.id !== tabId);
        await supabase.from('app_config').upsert({ key: 'stock_custom_tabs', value: extraTabs });
        customTabs.value = [...defaultTabs, ...extraTabs, archiveTab];
        if (currentTab.value === tabId) currentTab.value = 'production';
        appStore.showSnackbar('Pasta excluída', 'success');
    } catch (e) { appStore.showSnackbar('Erro ao excluir', 'error'); }
};

// --- BUSCA INTELIGENTE DE NCM (BRASIL API) ---
const ncmSuggestions = ref<any[]>([]);
const loadingNcm = ref(false);
let ncmTimeout: any = null;

const searchNCM = async (query: string) => {
    if (!query || query.length < 3) return;
    loadingNcm.value = true;
    try {
        const { data } = await axios.get(`https://brasilapi.com.br/api/ncm/v1?search=${encodeURIComponent(query)}`);
        ncmSuggestions.value = data.map((n: any) => ({
            title: `${n.codigo} - ${n.descricao.substring(0, 65)}...`,
            value: n.codigo
        })).slice(0, 15);
    } catch (e) {
        ncmSuggestions.value = [];
    } finally {
        loadingNcm.value = false;
    }
};

const searchNCMDebounced = (newVal: string) => {
    if(!newVal || newVal.length < 3) return;
    clearTimeout(ncmTimeout);
    ncmTimeout = setTimeout(() => {
        searchNCM(newVal);
    }, 800);
};

const forceSearchNCM = () => {
    const term = editedItem.value.ncm || editedItem.value.fabric_type;
    if(term) searchNCM(typeof term === 'object' ? term.value : term);
    else appStore.showSnackbar('Digite o nome do material para buscar', 'info');
};

const editedItem = ref<any>({
  id: null, fabric_type: '', unit_of_measure: 'm', base_price: 0,
  include_in_kpi: true,
  qty_operation: 'in',
  qty_value: 0,
  current_stock: 0, low_stock_threshold: 10, gestao_click_id: null, barcode: '', ncm: '',
  visible_in_sales: true, alert_enabled: true, target_tab: 'production'
});

// --- SELEÇÃO E BULK ACTIONS ---
const selectedItems = ref<any[]>([]);

const isAllSelected = computed({
    get: () => paginatedItems.value.length > 0 && selectedItems.value.length === paginatedItems.value.length,
    set: (val) => { toggleSelectAll(); }
});

const isItemSelected = (item: any) => selectedItems.value.some(i => i.id === item.id);

const toggleSelection = (item: any) => {
    const idx = selectedItems.value.findIndex(i => i.id === item.id);
    if (idx > -1) selectedItems.value.splice(idx, 1);
    else selectedItems.value.push(item);
};

const toggleSelectAll = () => {
    if (selectedItems.value.length === paginatedItems.value.length) selectedItems.value = [];
    else selectedItems.value = [...paginatedItems.value];
};

const bulkMoveToTab = async (targetTabId: string) => {
    const ids = selectedItems.value.map(i => i.id);
    try {
        const { error } = await supabase.from('stock').update({ target_tab: targetTabId }).in('id', ids);
        if (error) throw error;
        appStore.showSnackbar(`${ids.length} itens movidos com sucesso!`, 'success');
        selectedItems.value = [];
        fetchStock();
    } catch (e:any) { appStore.showSnackbar(`Erro ao mover: ${e.message}`, 'error'); }
};

const bulkToggle = async (field: 'visible_in_sales' | 'alert_enabled', value: boolean) => {
    const ids = selectedItems.value.map(i => i.id);
    try {
        const { error } = await supabase.from('stock').update({ [field]: value }).in('id', ids);
        if (error) throw error;
        appStore.showSnackbar(`Configuração aplicada a ${ids.length} itens!`, 'success');
        selectedItems.value = [];
        fetchStock();
    } catch (e:any) { appStore.showSnackbar(`Erro ao aplicar: ${e.message}`, 'error'); }
};

const bulkDelete = async () => {
    if (!confirm(`Excluir ${selectedItems.value.length} itens? Itens em uso serão arquivados automaticamente.`)) return;

    loading.value = true;
    try {
        const ids = selectedItems.value.map(i => i.id);

        // Tenta apagar todos de uma vez
        const { error } = await supabase.from('stock').delete().in('id', ids);

        if (error) {
            // Se der erro de foreign key (23503), fazemos o fallback para arquivamento
            if (error.code === '23503' || error.message.includes('Conflict')) {
                appStore.showSnackbar(`Alguns itens estão em uso em pedidos e foram movidos para "Arquivados".`, 'warning');
                await supabase.from('stock').update({ target_tab: 'archive', visible_in_sales: false }).in('id', ids);
            } else {
                throw error;
            }
        } else {
            appStore.showSnackbar(`Itens excluídos com sucesso!`, 'success');
        }

        selectedItems.value = [];
        fetchStock();
    } catch (e:any) {
        appStore.showSnackbar(`Erro ao excluir: ${e.message}`, 'error');
    } finally {
        loading.value = false;
    }
};

const showLabelModal = ref(false);
const selectedProductsForLabel = ref<any[]>([]);

const canViewFinancials = computed(() => {
  if (!userStore.profile) return false;
  const role = userStore.profile.role;
  return role === 'super_admin' || role === 'admin' || role === 'financeiro' || userStore.profile.custom_role_id === 'financeiro';
});

const canConfigAlerts = computed(() => {
  if (!userStore.profile) return false;
  if (userStore.profile.role === 'super_admin' || userStore.profile.role === 'admin') return true;
  return userStore.profile.permissions?.includes('config_low_stock_alerts') || false;
});

const kpisData = computed(() => {
  const list = stockItems.value.filter(i => i.include_in_kpi);
  return {
    patrimonio: list.reduce((acc, i) => acc + ((i.available_meters || 0) * (i.base_price || 0)), 0),
    metros: list.filter(i => i.unit_of_measure === 'm').reduce((acc, i) => acc + (i.available_meters || 0), 0),
    quilos: list.filter(i => i.unit_of_measure === 'kg').reduce((acc, i) => acc + (i.available_meters || 0), 0),
    alertas: list.filter(i => (i.available_meters || 0) <= (i.low_stock_threshold || 10) && i.alert_enabled).length
  };
});

const kpiList = computed(() => [
  { label: 'Patrimônio Ativo', value: canViewFinancials.value ? formatCurrency(kpisData.value.patrimonio) : '---', icon: 'mdi-currency-usd', gradient: 'bg-gradient-purple', footer: canViewFinancials.value ? 'Valorização total' : 'Acesso restrito' },
  { label: 'Total em Metros', value: `${kpisData.value.metros.toLocaleString('pt-BR')}m`, icon: 'mdi-ruler', gradient: 'bg-gradient-info', footer: 'Materiais (M)' },
  { label: 'Total em Quilos', value: `${kpisData.value.quilos.toLocaleString('pt-BR')}kg`, icon: 'mdi-weight', gradient: 'bg-gradient-green', footer: 'Materiais (KG)' },
  { label: 'Alerta de Ruptura', value: kpisData.value.alertas, icon: 'mdi-alert-octagon', gradient: 'bg-gradient-red', footer: 'Abaixo do mínimo' }
]);

const filteredItems = computed(() => {
  let list = stockItems.value.filter(i => i.target_tab === currentTab.value);
  if (unitFilter.value !== 'all') list = list.filter(i => i.unit_of_measure === unitFilter.value);
  if (search.value) {
    const s = search.value.toLowerCase();
    list = list.filter(i => i.fabric_type.toLowerCase().includes(s) || i.gestao_click_id?.includes(s) || i.barcode?.includes(s));
  }
  return list;
});

watch([currentTab, search, unitFilter], () => { page.value = 1; selectedItems.value = []; });

const paginatedItems = computed(() => {
   const start = (page.value - 1) * itemsPerPage;
   return filteredItems.value.slice(start, start + itemsPerPage);
});

const pageCount = computed(() => Math.ceil(filteredItems.value.length / itemsPerPage) || 1);

const getStockStatus = (item: any) => {
  const qty = item.available_meters || 0;
  const min = item.low_stock_threshold || 10;
  if (qty <= 0) return { label: 'ESGOTADO', color: 'error' };
  if (qty <= min) return { label: 'CRÍTICO', color: 'error' };
  if (qty <= min * 1.5) return { label: 'BAIXO', color: 'warning' };
  return { label: 'NORMAL', color: 'success' };
};

const generateBarcode = () => {
    const timestamp = new Date().getTime().toString().slice(-10);
    const randomPrefix = Math.floor(100 + Math.random() * 900).toString();
    editedItem.value.barcode = `${randomPrefix}${timestamp}`;
};

const fetchStock = async () => {
  loading.value = true;
  try { const { data } = await supabase.from('stock').select('*').order('fabric_type'); stockItems.value = data || []; }
  catch (e: any) { appStore.showSnackbar("Erro: " + e.message, "error"); }
  finally { loading.value = false; }
};

// --- RITUAL DA ENGRENAGEM (CONFIGURAÇÕES DO ITEM) ---
const configModal = reactive({
    show: false,
    loading: false,
    item: null as any,
    visible_in_sales: true,
    alert_enabled: true,
    include_in_kpi: true
});

const openConfigModal = (item: any) => {
    configModal.item = item;
    configModal.visible_in_sales = item.visible_in_sales !== false;
    configModal.alert_enabled = item.alert_enabled !== false;
    configModal.include_in_kpi = item.include_in_kpi !== false;
    configModal.show = true;
};

const saveConfigModal = async () => {
    if (!configModal.item) return;
    configModal.loading = true;
    try {
        const payload = {
            visible_in_sales: configModal.visible_in_sales,
            alert_enabled: configModal.alert_enabled,
            include_in_kpi: configModal.include_in_kpi
        };
        const { error } = await supabase.from('stock').update(payload).eq('id', configModal.item.id);
        if (error) throw error;

        configModal.item.visible_in_sales = configModal.visible_in_sales;
        configModal.item.alert_enabled = configModal.alert_enabled;
        configModal.item.include_in_kpi = configModal.include_in_kpi;

        appStore.showSnackbar('Configurações atualizadas com sucesso!', 'success');
        configModal.show = false;
    } catch (error: any) {
        appStore.showSnackbar(`Erro: ${error.message}`, 'error');
    } finally {
        configModal.loading = false;
    }
};

const syncCajuiaItems = async () => {
  loading.value = true;
  try {
    const produtosGestao = await gestaoApi.buscarProdutos();
    const itensCajuia = produtosGestao.filter(p => p.nome?.trim().toUpperCase().startsWith('CJ'));
    const upsertPayloads = itensCajuia.map(item => ({
      gestao_click_id: item.id.toString(), fabric_type: item.nome.trim(), unit_of_measure: item.unidade?.toLowerCase() === 'kg' ? 'kg' : 'm', base_price: parseFloat(item.valor_venda) || 0, available_meters: parseFloat(item.estoque as string) || 0, barcode: item.codigo_barra || null, ncm: item.fiscal?.ncm || null, is_ready_delivery: false, include_in_kpi: false, low_stock_threshold: 5, verification: true,
      visible_in_sales: true, alert_enabled: true, target_tab: 'cajuia'
    }));

    if (upsertPayloads.length > 0) {
        const { data, error } = await supabase.from('stock').upsert(upsertPayloads, { onConflict: 'gestao_click_id' }).select();
        if (error) throw error;
        appStore.showSnackbar(`${data?.length} itens sincronizados!`, "success");
    } else { appStore.showSnackbar("Nenhum item CJ encontrado para sincronizar.", "info"); }

    await fetchStock(); currentTab.value = 'cajuia';
  } catch (e: any) { appStore.showSnackbar("Erro na sincronização: " + e.message, "error"); }
  finally { loading.value = false; }
};

const openDialog = (item?: any) => {
  ncmSuggestions.value = [];

  if (item) {
    isEditing.value = true;
    editedItem.value = {
        ...item,
        qty_operation: 'in', qty_value: 0,
        batch_code: '',
        current_stock: Number(Number(item.available_meters).toFixed(2)),
        base_price: Number(Number(item.base_price).toFixed(2)),
        low_stock_threshold: Number(Number(item.low_stock_threshold).toFixed(2)),
        barcode: item.barcode || '', ncm: item.ncm || '',
        visible_in_sales: item.visible_in_sales !== false, alert_enabled: item.alert_enabled !== false,
        target_tab: item.target_tab || 'production'
    };
  } else {
    isEditing.value = false;
    editedItem.value = {
        id: null, fabric_type: '', unit_of_measure: 'm', base_price: 0, include_in_kpi: true,
        qty_operation: 'in', qty_value: 0,
        current_stock: 0, low_stock_threshold: 10, gestao_click_id: null, barcode: '', ncm: '',
        visible_in_sales: true, alert_enabled: true, target_tab: currentTab.value
    };
  }
  dialog.value = true;
};

const openLabelModal = (item: any) => {
    selectedProductsForLabel.value = [{ name: item.fabric_type, barcode: item.barcode || item.gestao_click_id || '000000', price: item.base_price, sku: item.gestao_click_id || 'LOCAL' }];
    showLabelModal.value = true;
};

const cloneItem = (item: any) => {
    const cloned = { ...item };
    cloned.id = null; cloned.fabric_type = `${cloned.fabric_type} (Cópia)`; cloned.gestao_click_id = null; cloned.available_meters = 0; cloned.barcode = '';
    openDialog(cloned);
    isEditing.value = false;
    editedItem.value = { ...cloned, qty_operation: 'in', qty_value: 0, current_stock: 0 };
};

const close = () => { dialog.value = false; };

const save = async () => {
  if (!editedItem.value.fabric_type) return appStore.showSnackbar("O nome do material é obrigatório.", "warning");

  isSaving.value = true;
  try {
    const valToMove = Number(editedItem.value.qty_value) || 0;
    const finalChange = editedItem.value.qty_operation === 'out' ? -Math.abs(valToMove) : Math.abs(valToMove);
    const finalQty = Number(editedItem.value.current_stock) + finalChange;

    const { qty_operation, qty_value, current_stock, id, batch_code, ...payload } = editedItem.value;

    if (typeof payload.ncm === 'object' && payload.ncm !== null) {
        payload.ncm = payload.ncm.value || payload.ncm.codigo;
    }

    payload.available_meters = finalQty;
    payload.verification = true;

    if (payload.target_tab === 'ready_delivery') payload.is_ready_delivery = true;
    else payload.is_ready_delivery = false;

    if (payload.gestao_click_id === '') payload.gestao_click_id = null;
    if (payload.barcode === '') payload.barcode = null;
    if (payload.ncm === '') payload.ncm = null;

    let targetStockId = id;

    if (isEditing.value) {
      const { error } = await supabase.from('stock').update(payload).eq('id', id);
      if (error) throw error;
    } else {
      const { data, error } = await supabase.from('stock').insert(payload).select().single();
      if (error) throw error;
      targetStockId = data.id;
    }

    // Gravar no LEDGER se houve mudança manual
if (finalChange !== 0) {
        const ledgerPayload = {
            stock_id: targetStockId,
            operation_type: finalChange > 0 ? 'IN' : 'ADJUSTMENT',
            qty_changed: finalChange,
            qty_before: Number(editedItem.value.current_stock),
            qty_after: finalQty,
            notes: 'Ajuste manual / Inserção direta via InfiniteSpace',
            created_by: userStore.profile?.id
        };
        if (finalChange < 0) ledgerPayload.operation_type = 'OUT';

        await supabase.from('stock_ledger').insert(ledgerPayload);

        // 👇 LÓGICA CORRIGIDA AQUI 👇
        // Se foi uma entrada (IN), criar o lote respeitando o que você digitou
        if (finalChange > 0) {
            // Pega o lote digitado ou gera um fallback seguro se você esquecer
            const userBatchCode = editedItem.value.batch_code?.trim();
            const finalBatchCode = userBatchCode ? userBatchCode : `LOTE-MNL-${Date.now().toString().slice(-6)}`;

            const batchPayload = {
                stock_id: targetStockId,
                batch_code: finalBatchCode,
                initial_qty: finalChange,
                current_qty: finalChange,
                cost_per_unit: payload.base_price || 0
            };
            await supabase.from('stock_batches').insert(batchPayload);
        }
        // 👆 FIM DA LÓGICA CORRIGIDA 👆
    }

    appStore.showSnackbar("Salvo com sucesso!", "success");
    currentTab.value = payload.target_tab;
    fetchStock(); close();
  } catch (e: any) { appStore.showSnackbar("Erro: " + (e.message || 'Falha'), "error"); }
  finally { isSaving.value = false; }
};

const deleteItem = async (item: any) => {
  if (confirm(`Excluir "${item.fabric_type}"?`)) {
    try {
        const { error } = await supabase.from('stock').delete().eq('id', item.id);

        if (error) {
            if (error.code === '23503' || error.message.includes('Conflict')) {
                appStore.showSnackbar('Este material já está em uso em pedidos/financeiro. Ele foi ocultado das vendas e movido para "Arquivados".', 'warning', 6000);
                await supabase.from('stock').update({ target_tab: 'archive', visible_in_sales: false }).eq('id', item.id);
            } else {
                throw error;
            }
        } else {
            appStore.showSnackbar('Material excluído!', 'success');
        }
        fetchStock();
    } catch(e:any) {
        appStore.showSnackbar('Erro ao excluir: ' + e.message, 'error');
    }
  }
};

// --- RITUAL: ABSORÇÃO DE NFE (IMPORTAÇÃO XML) ---
const importNfeModal = reactive({
    show: false,
    loading: false,
    file: null as File | null,
    items: [] as any[],
    nfeInfo: { chave: '', emitente: '', data: '', valor: 0 }
});

const openImportNfeModal = () => {
    importNfeModal.file = null;
    importNfeModal.items = [];
    importNfeModal.nfeInfo = { chave: '', emitente: '', data: '', valor: 0 };
    importNfeModal.show = true;
};

const handleNfeFileUpload = (event: Event) => {
    const file = (event.target as HTMLInputElement).files?.[0];
    if (!file) return;
    importNfeModal.file = file;

    const reader = new FileReader();
    reader.onload = (e) => {
        try {
            const text = e.target?.result as string;
            const parser = new DOMParser();
            const xmlDoc = parser.parseFromString(text, "text/xml");

            const infNFe = xmlDoc.getElementsByTagName('infNFe')[0];
            if (!infNFe) throw new Error("XML inválido ou não é uma NF-e.");

            const chave = infNFe.getAttribute('Id')?.replace('NFe', '') || '';
            const emitente = xmlDoc.getElementsByTagName('emit')[0]?.getElementsByTagName('xNome')[0]?.textContent || 'Desconhecido';
            const dataEmi = xmlDoc.getElementsByTagName('dhEmi')[0]?.textContent || new Date().toISOString();
            const valorTotal = xmlDoc.getElementsByTagName('vNF')[0]?.textContent || '0';

            importNfeModal.nfeInfo = { chave, emitente, data: dataEmi, valor: Number(valorTotal) };

            const detElements = xmlDoc.getElementsByTagName('det');
            const extractedItems = [];
            for (let i = 0; i < detElements.length; i++) {
                const prod = detElements[i].getElementsByTagName('prod')[0];
                const xProd = prod.getElementsByTagName('xProd')[0]?.textContent || '';
                const cEAN = prod.getElementsByTagName('cEAN')[0]?.textContent || '';
                const qCom = Number(prod.getElementsByTagName('qCom')[0]?.textContent || 0);
                const vUnCom = Number(prod.getElementsByTagName('vUnCom')[0]?.textContent || 0);
                const uCom = prod.getElementsByTagName('uCom')[0]?.textContent || '';

                const match = stockItems.value.find(s => s.barcode === cEAN || s.fabric_type.trim().toUpperCase() === xProd.trim().toUpperCase());

                extractedItems.push({
                    nItem: i + 1,
                    xProd,
                    cEAN,
                    qCom,
                    vUnCom,
                    uCom,
                    matchedStockId: match ? match.id : null
                });
            }
            importNfeModal.items = extractedItems;
        } catch (err: any) {
            appStore.showSnackbar('Erro ao processar o XML: ' + err.message, 'error');
        }
    };
    reader.readAsText(file);
};

const confirmNfeImport = async () => {
    const itemsToUpdate = importNfeModal.items.filter(i => i.matchedStockId);
    if (itemsToUpdate.length === 0) {
        return appStore.showSnackbar('Vincule pelo menos um produto ao estoque local.', 'warning');
    }

    importNfeModal.loading = true;
    try {
        let xmlUrl = '';
        if (importNfeModal.file) {
            const fileName = `${Date.now()}_${importNfeModal.nfeInfo.chave}.xml`;
            const { data: uploadData, error: uploadError } = await supabase.storage.from('nfe-docs').upload(`entradas/${fileName}`, importNfeModal.file);
            if (!uploadError) {
                const { data: publicUrlData } = supabase.storage.from('nfe-docs').getPublicUrl(`entradas/${fileName}`);
                xmlUrl = publicUrlData.publicUrl;
            }
        }

        const cnpjDestino = companyStore.companies?.[0]?.cnpj?.replace(/\D/g, '') || '00000000000000';

        const { error: dfeError } = await supabase.from('dfe_entries').upsert({
            chave: importNfeModal.nfeInfo.chave,
            cnpj_destinatario: cnpjDestino,
            emitente_nome: importNfeModal.nfeInfo.emitente,
            valor: importNfeModal.nfeInfo.valor,
            data_emissao: importNfeModal.nfeInfo.data,
            situacao_sefaz: 'Autorizada',
            xml_link: xmlUrl,
            status_processamento: 'concluido'
        }, { onConflict: 'chave' });

        if (dfeError) console.error("Erro salvando DFe:", dfeError);

        const updatePromises = itemsToUpdate.map(async (item) => {
            const stockItem = stockItems.value.find(s => s.id === item.matchedStockId);
            if (stockItem) {
                const newQty = Number(stockItem.available_meters) + item.qCom;
                await supabase.from('stock').update({ available_meters: newQty }).eq('id', stockItem.id);

                // Grava no Ledger
                await supabase.from('stock_ledger').insert({
                    stock_id: stockItem.id,
                    operation_type: 'IN',
                    qty_changed: item.qCom,
                    qty_before: Number(stockItem.available_meters),
                    qty_after: newQty,
                    notes: `Entrada via NFE: ${importNfeModal.nfeInfo.chave}`,
                    created_by: userStore.profile?.id
                });

                // Cria o lote correspondente
                await supabase.from('stock_batches').insert({
                    stock_id: stockItem.id,
                    batch_code: `NFE-${importNfeModal.nfeInfo.chave.slice(-6)}-${Date.now().toString().slice(-4)}`,
                    initial_qty: item.qCom,
                    current_qty: item.qCom,
                    cost_per_unit: item.vUnCom
                });
            }
        });

        await Promise.all(updatePromises);

        appStore.showSnackbar('Entrada de NF-e efetuada com sucesso!', 'success');
        importNfeModal.show = false;
        fetchStock();
    } catch (e: any) {
        appStore.showSnackbar('Erro ao finalizar entrada: ' + e.message, 'error');
    } finally {
        importNfeModal.loading = false;
    }
};

onMounted(async () => {
    await loadCustomTabs();
    fetchStock();
});
</script>

<style scoped lang="scss">
@import "@/styles/settings.scss";

/* Layout Base idêntico ao AdminMjReceivables */
.receivables-layout { position: relative; }
.bg-glass-dark { background: rgba(10,10,12,0.85); }
.bg-glass-header { background: rgba(20,20,24,0.55); backdrop-filter: blur(14px); }
.border-bottom-white-05 { border-bottom: 1px solid rgba(255,255,255,0.08); }
.border-white-10 { border: 1px solid rgba(255,255,255,0.1) !important; }
.bg-black-20 { background: rgba(0,0,0,0.2) !important; }

/* Backgrounds (Dark Mode) */
.background-carousel-wrapper { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 0; opacity: 0.6; pointer-events: none; }
.background-overlay { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 1; background: radial-gradient(circle at center, rgba(15, 15, 19, 0.4), rgba(15, 15, 19, 0.98)); backdrop-filter: blur(8px); }

/* Inputs e Botões 3D padrão */
.ui-field :deep(.v-field) { border-radius: 6px !important; }
.btn-3d { border-radius: 6px !important; box-shadow: 0 3px 5px rgba(0,0,0,0.15), inset 0 2px 0 rgba(255,255,255,0.25) !important; transition: transform 0.1s ease, box-shadow 0.1s ease; text-transform: none !important; }
.btn-3d:active { transform: translateY(2px); box-shadow: 0 1px 2px rgba(0,0,0,0.15), inset 0 1px 0 rgba(255,255,255,0.2) !important; }
.chip-3d { border-radius: 6px !important; box-shadow: 0 3px 5px rgba(0,0,0,0.12), inset 0 1px 0 rgba(255,255,255,0.25) !important; text-shadow: 0 1px 2px rgba(0,0,0,0.25); }

.row-gap { row-gap: 14px; margin-top: 4px; }
.fixed-dialog { overflow: hidden !important; }
.absolute-fill { height: 100%; overflow-y: auto; }

/* Controles de Busca e Grid */
.controls-bar { border: 1px solid rgba(0,0,0,0.08); padding: 10px; }
.search-wrap { height: 40px; display: flex; align-items: center; min-width: 300px; }
.clean-input { border: none; outline: none; flex: 1; font-size: 13px; }

/* Grid Fluid */
.grid-scroll { scrollbar-gutter: stable; -webkit-overflow-scrolling: touch; }
.custom-scroll::-webkit-scrollbar { width: 8px; height: 8px; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.35); border-radius: 6px; }
.custom-scroll::-webkit-scrollbar-track { background: transparent; }

.grid-header, .grid-row { display: grid; align-items: stretch; width: 100%; min-width: 1300px; }
.cell { padding: 6px 12px; display: flex; align-items: center; border-right: 1px solid rgba(0,0,0,0.08); border-bottom: 1px solid rgba(0,0,0,0.08); min-height: 54px; overflow: hidden; transition: background-color 0.2s ease; }
.header-text { font-weight: 800; text-transform: uppercase; letter-spacing: 0.5px; line-height: 1.2; font-size: 12px; }
.center { justify-content: center; text-align: center; }
.grid-header .cell { min-height: 44px; }
.list-text-11 { font-size: 13px !important; line-height: 1.2 !important; }

/* Headers Sticky */
.sticky-head { position: sticky; top: 0; z-index: 20; box-shadow: 0 8px 16px -4px rgba(0, 0, 0, 0.12); }
.bg-glass-dark .sticky-head { box-shadow: 0 8px 20px -4px rgba(0, 0, 0, 0.4); }

/* Temas da Grid */
.grid-surface-light .cell { background: #f5f7fa; color: rgba(0,0,0,0.9); border-color: rgba(0,0,0,0.12) !important; }
.grid-surface-dark .cell { background: rgba(255,255,255,0.08) !important; color: rgba(255,255,255,0.80) !important; border-color: rgba(255,255,255,0.10) !important; }

.grid-row-light .cell { border-color: rgba(0,0,0,0.08) !important; }
.grid-row-dark .cell { background: rgba(255,255,255,0.04); border-color: rgba(255,255,255,0.08) !important; color: rgba(255,255,255,0.85); }

.zebra-light-a .cell { background: #ffffff; }
.zebra-light-b .cell { background: #f0f4f8; }
.zebra-dark-a .cell { background: rgba(255,255,255,0.04) !important; }
.zebra-dark-b .cell { background: rgba(255,255,255,0.015) !important; }

.grid-row-light:hover .cell { background: #e3f2fd !important; cursor: pointer; }
.grid-row-dark:hover .cell { background: rgba(255,255,255,0.07) !important; cursor: pointer; }

.row-selected .cell { background: rgba(0, 105, 92, 0.1) !important; border-top: 1px solid rgba(0, 105, 92, 0.3) !important; border-bottom: 1px solid rgba(0, 105, 92, 0.3) !important; }

.pill-ref { font-size: 12px !important; font-weight: 900; font-family: monospace; padding: 4px 6px; border-radius: 0px; white-space: nowrap; }

/* Botões de Ação na Tabela */
.actions-inline { display: flex; gap: 4px; justify-content: center; }
.action-btn { width: 28px !important; height: 28px !important; color: #fff !important; }
.action-edit { background: #1976d2 !important; }
.action-del { background: #c62828 !important; }

/* KPI Cards */
.kpi-card { border: 1px solid rgba(255,255,255,0.15); color: white; min-height: 100px; position: relative; overflow: hidden; transition: all 0.2s ease; }
.kpi-rect { border-radius: 6px !important; }
.kpi-bg-icon { position: absolute; right: -15px; bottom: -15px; opacity: 0.15; transform: rotate(-15deg); pointer-events: none; }
.kpi-bg-icon .v-icon { font-size: 80px; color: white; }
.bg-gradient-green { background: linear-gradient(135deg, #2e7d32, #1b5e20); }
.bg-gradient-red { background: linear-gradient(135deg, #c62828, #8e0000); }
.bg-gradient-purple { background: linear-gradient(135deg, #7b1fa2, #4a148c); }
.bg-gradient-info { background: linear-gradient(135deg, #0288d1, #005b9f); }
.kpi-label { font-size: 11px; font-weight: 900; text-transform: uppercase; letter-spacing: 0.5px; }
.kpi-value { font-size: 24px; font-weight: 900; }
.kpi-footer { font-size: 10px; font-weight: 700; opacity: 0.8; }

/* FICHÁRIO TABS ESTILO PASTAS */
.fichario-wrapper { border-bottom: 2px solid #00695C; padding-bottom: 0; }
.fichario-tab { padding: 10px 18px; background: #e0e0e0; color: #616161; border-radius: 8px 8px 0 0; cursor: pointer; transition: all 0.2s ease; border: 1px solid #bdbdbd; border-bottom: none; position: relative; max-width: 220px; }
.fichario-tab:hover { background: #eeeeee; }
.fichario-tab.active { background: #00695C; color: #ffffff; border-color: #00695C; padding-bottom: 12px; margin-bottom: -2px; z-index: 2; box-shadow: 0 -3px 8px rgba(0,0,0,0.1); }
.fichario-tab.tab-archive { opacity: 0.8; }
.fichario-tab.tab-archive.active { background: #455A64; border-color: #455A64; opacity: 1; }

.fichario-tab.dark-mode { background: rgba(255,255,255,0.05); color: #9e9e9e; border-color: rgba(255,255,255,0.1); }
.fichario-tab.dark-mode:hover { background: rgba(255,255,255,0.1); }
.fichario-tab.dark-mode.active { background: #00695C; color: #ffffff; border-color: #00695C; }
.fichario-tab.dark-mode.tab-archive.active { background: #455A64; border-color: #455A64; }

.tab-close-btn { opacity: 0; transition: opacity 0.2s; cursor: pointer; }
.fichario-tab:hover .tab-close-btn { opacity: 0.6; }
.fichario-tab:hover .tab-close-btn:hover { opacity: 1; color: #ff5252; }
.hide-scrollbar::-webkit-scrollbar { height: 0px; display: none; }

/* ILHA FLUTUANTE (FLOATING ACTION BAR) */
.selection-island-wrapper { position: absolute; bottom: 30px; left: 0; right: 0; display: flex; justify-content: center; z-index: 100; pointer-events: none; }
.selection-island { pointer-events: auto; background: #1e1e24; border-radius: 12px; padding: 8px 16px; display: flex; align-items: center; gap: 8px; border: 1px solid rgba(255,255,255,0.1); box-shadow: 0 10px 30px rgba(0,0,0,0.3); }

.hover-bg-dark:hover { background: rgba(255,255,255,0.1); cursor: pointer; }
.hover-bg-grey-darken-3:hover { background-color: #424242; }
.hover-bg-grey-lighten-5:hover { background-color: #f5f5f5; }
.shadow-button { box-shadow: 0 4px 15px rgba(0, 105, 92, 0.3); }
</style>
