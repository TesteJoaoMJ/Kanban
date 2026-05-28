<template>
  <div
    class="price-admin-layout font-sans fill-height d-flex flex-column relative overflow-hidden"
    :class="isLightMode ? 'bg-grey-lighten-5 text-grey-darken-4' : 'bg-glass-dark text-white'"
  >
    <div v-if="!isLightMode" class="background-carousel-wrapper">
      <div class="background-overlay"></div>
    </div>

    <div class="content-wrapper d-flex flex-column fill-height z-10 relative">

      <div
        class="header-bar px-4 py-3 px-md-6 py-md-4 d-flex flex-column flex-md-row align-md-center justify-space-between flex-shrink-0"
        :class="isLightMode ? 'bg-white border-b border-grey-lighten-2 shadow-sm' : 'bg-glass-header border-bottom-white-05'"
        style="gap: 12px;"
      >
        <div class="d-flex flex-column">
          <div class="breadcrumb text-caption d-none d-md-block">
            <span class="opacity-70">Administração</span>
            <span class="mx-2 opacity-50">></span>
            <span class="font-weight-bold">Tabela de Preços</span>
          </div>
          <div class="d-flex align-center gap-2 mt-1">
             <v-icon size="24" :color="isLightMode ? 'primary' : 'white'">mdi-tag-multiple</v-icon>
             <div class="text-h5 font-weight-black tracking-tight leading-none text-uppercase" :class="isLightMode ? 'text-grey-darken-4' : 'text-white'">
                Gerenciar Preços
             </div>
          </div>
        </div>

        <div class="d-flex align-center flex-wrap gap-2" style="max-width: 600px; width: 100%; justify-content: flex-end;">

          <v-btn-toggle
            v-model="viewMode"
            mandatory
            density="compact"
            variant="outlined"
            class="btn-group-rect rounded-lg border-thin mr-2 btn-3d"
            :color="isLightMode ? 'indigo-darken-2' : 'white'"
            divided
          >
            <v-btn value="grid" class="px-3" title="Visualização em Grade">
              <v-icon size="small">mdi-view-list</v-icon>
            </v-btn>
            <v-btn value="card" class="px-3" title="Visualização em Cards">
              <v-icon size="small">mdi-view-grid</v-icon>
            </v-btn>
          </v-btn-toggle>

          <v-btn color="orange-darken-3" variant="flat" class="btn-3d px-4 font-weight-bold text-caption text-uppercase" height="40" @click="openStockImportModal">
            <v-icon start size="18">mdi-package-down</v-icon> Importar do Estoque
          </v-btn>

          <v-btn color="indigo" variant="flat" class="btn-3d px-4 font-weight-bold text-caption text-uppercase" height="40" @click="openDialog()">
            <v-icon start size="18">mdi-plus</v-icon> Novo Produto
          </v-btn>
        </div>
      </div>

      <div class="px-4 px-md-6 pt-4 pb-2 flex-shrink-0">
        <div class="controls-bar d-flex flex-column" :class="isLightMode ? 'controls-light' : 'controls-dark'">
          <div class="d-flex align-center justify-space-between w-100 flex-wrap gap-2">

            <div class="search-wrap d-flex align-center flex-grow-1" style="max-width: 500px;" :class="isLightMode ? 'search-light' : 'search-dark'">
              <v-icon :color="isLightMode ? 'grey-darken-1' : 'white-70'">mdi-magnify</v-icon>
              <input
                v-model="search"
                type="text"
                placeholder="BUSCAR PRODUTO CADASTRADO..."
                class="clean-input flex-grow-1 font-weight-bold pl-2 text-uppercase"
              />
              <v-icon v-if="search" size="small" class="cursor-pointer opacity-50 ml-2" @click="search = ''">mdi-close</v-icon>
            </div>

            <div class="d-flex align-center gap-2" v-if="viewMode === 'grid'">
               <span class="text-caption font-weight-bold opacity-70 d-none d-sm-block">DENSIDADE DA GRID:</span>
               <v-btn-toggle
                  v-model="gridDensity"
                  mandatory
                  density="compact"
                  variant="outlined"
                  class="btn-group-rect rounded-lg border-thin btn-3d"
                  :color="isLightMode ? 'indigo-darken-2' : 'white'"
                  divided
                >
                  <v-btn value="compact" class="px-3 text-caption font-weight-bold" title="Layout Compacto (Menos Espaço)">
                    <v-icon start size="small">mdi-format-line-spacing</v-icon> COMPACTO
                  </v-btn>
                  <v-btn value="comfortable" class="px-3 text-caption font-weight-bold" title="Layout Normal (Mais Espaço)">
                    <v-icon start size="small">mdi-format-list-bulleted</v-icon> NORMAL
                  </v-btn>
                </v-btn-toggle>
            </div>

          </div>
        </div>
      </div>

      <div class="flex-grow-1 overflow-hidden d-flex flex-column px-4 px-md-6 pb-4 transition-all relative">

        <div v-if="loading" class="d-flex flex-column justify-center align-center h-100 py-10 w-100">
          <v-progress-circular indeterminate color="indigo" size="48" width="4"></v-progress-circular>
          <span class="text-caption mt-4 font-weight-bold text-uppercase tracking-widest text-indigo-darken-2">Carregando base de preços...</span>
        </div>

        <div v-else-if="filteredProducts.length === 0" class="d-flex flex-column justify-center align-center h-100 opacity-60 gap-2 py-10 w-100">
          <v-icon size="48" color="grey-lighten-1">mdi-database-off-outline</v-icon>
          <span class="text-body-2 font-weight-bold text-grey text-uppercase">Nenhum produto encontrado.</span>
        </div>

        <v-card
          v-else-if="viewMode === 'grid'"
          class="flex-grow-1 d-flex flex-column rounded-0 border-thin overflow-hidden relative"
          :class="isLightMode ? 'bg-white shadow-sm' : 'glass-card border-white-05'"
          :elevation="0"
        >
          <div class="grid-scroll flex-grow-1 overflow-auto custom-scroll relative">
            <div
              class="grid-header sticky-head border-b"
              :class="[isLightMode ? 'grid-surface-light' : 'grid-surface-dark', `density-${gridDensity}`]"
              style="grid-template-columns: minmax(250px, 1.5fr) minmax(150px, 1fr) 100px 100px 100px 80px 120px 120px 120px 120px 170px;"
            >
              <div class="cell header-text pl-4">Produto</div>
              <div class="cell header-text">Composição</div>
              <div class="cell center header-text">Gramatura</div>
              <div class="cell center header-text">Largura</div>
              <div class="cell center header-text">Rolo</div>
              <div class="cell center header-text">Unid.</div>
              <div class="cell right header-text">SE (À Vista)</div>
              <div class="cell right header-text">SE (A Prazo)</div>
              <div class="cell right header-text">NE (À Vista)</div>
              <div class="cell right header-text">NE (A Prazo)</div>
              <div class="cell center header-text">Ações</div>
            </div>

            <div
              v-for="(item, index) in filteredProducts"
              :key="item.id"
              class="grid-row border-b transition-all"
              :class="[
                isLightMode ? 'grid-row-light' : 'grid-row-dark',
                zebraClass(index),
                `density-${gridDensity}`
              ]"
              style="grid-template-columns: minmax(250px, 1.5fr) minmax(150px, 1fr) 100px 100px 100px 80px 120px 120px 120px 120px 170px;"
            >
                <div class="cell pl-4">
                    <div class="d-flex align-center gap-3 w-100">
                        <div class="color-stripe rounded-pill" :class="item.unit === 'kg' ? 'bg-purple-darken-1' : 'bg-teal-darken-1'" style="width: 4px; height: 24px;"></div>
                        <div class="text-truncate list-text font-weight-black text-uppercase cursor-pointer hover-link" :title="item.name" @click="openDialog(item)">{{ item.name }}</div>
                    </div>
                </div>

                <div class="cell">
                    <span class="text-truncate list-text opacity-90 w-100 font-weight-bold" :title="item.composition">{{ item.composition || '-' }}</span>
                </div>

                <div class="cell center">
                    <span class="list-text font-mono opacity-80 text-truncate">{{ item.grammage || '-' }}</span>
                </div>

                <div class="cell center">
                    <span class="list-text font-mono opacity-80 text-truncate">{{ item.width_length || '-' }}</span>
                </div>

                <div class="cell center">
                    <span class="list-text font-mono opacity-80 text-truncate">{{ item.rolo || '-' }}</span>
                </div>

                <div class="cell center">
                    <v-chip :color="item.unit === 'kg' ? 'purple-darken-1' : 'teal-darken-1'" size="x-small" variant="tonal" class="font-weight-black text-uppercase chip-3d">{{ item.unit }}</v-chip>
                </div>

                <div class="cell right">
                    <span class="list-text font-mono font-weight-black text-green-darken-3">{{ formatCurrency(item.price_se_cash) }}</span>
                </div>

                <div class="cell right">
                    <span class="list-text font-mono font-weight-bold text-green-darken-2 opacity-80">{{ formatCurrency(item.price_se_term) }}</span>
                </div>

                <div class="cell right">
                    <span class="list-text font-mono font-weight-black text-indigo-darken-2">{{ formatCurrency(item.price_ne_cash) }}</span>
                </div>

                <div class="cell right">
                    <span class="list-text font-mono font-weight-bold text-indigo-darken-1 opacity-80">{{ formatCurrency(item.price_ne_term) }}</span>
                </div>

                <div class="cell center" style="overflow: visible;">
                     <div class="actions-inline">
                         <v-tooltip text="Editar" location="top" content-class="tooltip-contrast">
                           <template v-slot:activator="{ props }">
                             <v-btn v-bind="props" class="square-btn btn-3d" variant="flat" color="indigo" @click.stop="openDialog(item)">
                               <v-icon size="16">mdi-pencil</v-icon>
                             </v-btn>
                           </template>
                         </v-tooltip>

                         <v-tooltip text="Clonar Produto" location="top" content-class="tooltip-contrast">
                           <template v-slot:activator="{ props }">
                             <v-btn v-bind="props" class="square-btn btn-3d" variant="flat" color="blue-grey" @click.stop="cloneItem(item)">
                               <v-icon size="16">mdi-content-copy</v-icon>
                             </v-btn>
                           </template>
                         </v-tooltip>

                         <v-tooltip text="Compartilhar Preço" location="top" content-class="tooltip-contrast">
                           <template v-slot:activator="{ props }">
                             <v-btn v-bind="props" class="square-btn btn-3d" variant="flat" color="teal-darken-2" @click.stop="openShareModal(item)">
                               <v-icon size="16">mdi-share-variant</v-icon>
                             </v-btn>
                           </template>
                         </v-tooltip>

                         <v-tooltip text="Excluir" location="top" content-class="tooltip-contrast">
                           <template v-slot:activator="{ props }">
                             <v-btn v-bind="props" class="square-btn btn-3d" variant="flat" color="red-darken-3" @click.stop="deleteItem(item)">
                               <v-icon size="16">mdi-trash-can-outline</v-icon>
                             </v-btn>
                           </template>
                         </v-tooltip>
                     </div>
                </div>
            </div>
          </div>
          <div class="flex-shrink-0 border-t px-4 py-2 d-flex align-center justify-space-between z-20" :class="isLightMode ? 'bg-grey-lighten-5' : 'bg-white-05'">
             <span class="text-caption font-weight-bold text-uppercase opacity-80">Total Listado: <strong>{{ filteredProducts.length }}</strong> registros</span>
          </div>
        </v-card>

        <div v-else class="flex-grow-1 overflow-y-auto custom-scroll pr-2 h-100 w-100">
            <v-row>
              <v-col v-for="item in filteredProducts" :key="item.id" cols="12" sm="6" md="4" lg="3">
                <v-card class="price-card btn-3d rounded-lg" :class="[`unit--${item.unit}`, isLightMode ? 'price-card-light' : 'glass-card border-white-05']" variant="flat">
                  <div class="card-actions-menu">
                    <v-menu location="start">
                      <template v-slot:activator="{ props }">
                        <v-btn icon="mdi-dots-vertical" v-bind="props" variant="text" size="small" :color="isLightMode ? 'grey-darken-3' : 'white'"></v-btn>
                      </template>
                      <v-list density="compact" nav :class="isLightMode ? 'bg-white border-thin' : 'menu-list-styling'">
                        <v-list-item @click="openDialog(item)" prepend-icon="mdi-pencil" title="Editar"></v-list-item>
                        <v-list-item @click="cloneItem(item)" prepend-icon="mdi-content-copy" title="Clonar"></v-list-item>
                        <v-list-item @click="openShareModal(item)" prepend-icon="mdi-share-variant" title="Compartilhar"></v-list-item>
                        <v-divider class="my-1"></v-divider>
                        <v-list-item @click="deleteItem(item)" prepend-icon="mdi-trash-can-outline" base-color="error" title="Excluir"></v-list-item>
                      </v-list>
                    </v-menu>
                  </div>
                  <v-card-text class="d-flex flex-column h-100 pt-5">
                    <div class="mb-3 pr-6">
                      <h3 class="text-subtitle-1 font-weight-black lh-1 mb-1 text-uppercase" :class="isLightMode ? 'text-grey-darken-4' : 'text-white'">{{ item.name }}</h3>
                      <p class="text-caption font-weight-bold opacity-80" :class="isLightMode ? 'text-grey-darken-2' : 'text-grey-lighten-1'">{{ item.composition || 'S/ Composição' }}</p>
                    </div>
                    <div class="info-grid mb-4 border-thin pa-2 rounded bg-white-05">
                      <div class="info-item"><span class="info-label opacity-70">Gramatura</span><span class="info-value font-mono">{{ item.grammage || '-' }}</span></div>
                      <div class="info-item"><span class="info-label opacity-70">Largura</span><span class="info-value font-mono">{{ item.width_length || '-' }}</span></div>
                      <div class="info-item"><span class="info-label opacity-70">Rolo</span><span class="info-value font-mono">{{ item.rolo || '-' }}</span></div>
                      <div v-if="item.unit === 'kg'" class="info-item"><span class="info-label opacity-70">Rend.</span><span class="info-value font-mono">{{ item.rendimento || '-' }}</span></div>
                      <div class="info-item"><span class="info-label opacity-70">Unidade</span><v-chip :color="item.unit === 'kg' ? 'purple-darken-1' : 'teal-darken-1'" size="x-small" variant="flat" class="mt-1 font-weight-black uppercase rounded chip-3d">{{ item.unit }}</v-chip></div>
                    </div>
                    <v-spacer></v-spacer>

                    <div class="price-region mt-2 rounded-lg pa-3" :class="isLightMode ? 'bg-grey-lighten-5 border-thin' : 'bg-white-05 border-white-05 border'">
                      <h4 class="region-title text-success font-weight-black d-flex align-center gap-1"><v-icon size="14">mdi-map-marker-outline</v-icon> SUDESTE</h4>
                      <div class="d-flex justify-space-between mt-2">
                        <div class="d-flex flex-column">
                            <span class="text-[10px] font-weight-black text-uppercase opacity-60">À Vista</span>
                            <span class="font-mono font-weight-black text-subtitle-2">{{ formatCurrency(item.price_se_cash) }}</span>
                        </div>
                        <div class="d-flex flex-column align-end">
                            <span class="text-[10px] font-weight-black text-uppercase opacity-60">A Prazo</span>
                            <span class="font-mono font-weight-bold text-caption">{{ formatCurrency(item.price_se_term) }}</span>
                        </div>
                      </div>
                    </div>

                    <div class="price-region mt-2 rounded-lg pa-3" :class="isLightMode ? 'bg-grey-lighten-5 border-thin' : 'bg-white-05 border-white-05 border'">
                      <h4 class="region-title text-info font-weight-black d-flex align-center gap-1"><v-icon size="14">mdi-map-marker-outline</v-icon> NORDESTE</h4>
                      <div class="d-flex justify-space-between mt-2">
                        <div class="d-flex flex-column">
                            <span class="text-[10px] font-weight-black text-uppercase opacity-60">À Vista</span>
                            <span class="font-mono font-weight-black text-subtitle-2">{{ formatCurrency(item.price_ne_cash) }}</span>
                        </div>
                        <div class="d-flex flex-column align-end">
                            <span class="text-[10px] font-weight-black text-uppercase opacity-60">A Prazo</span>
                            <span class="font-mono font-weight-bold text-caption">{{ formatCurrency(item.price_ne_term) }}</span>
                        </div>
                      </div>
                    </div>

                  </v-card-text>
                </v-card>
              </v-col>
            </v-row>
        </div>

      </div>
    </div>

    <v-dialog v-model="stockImportModal" max-width="500px" persistent>
        <v-card class="rounded-lg shadow-lg border-thin" :class="isLightMode ? 'bg-white' : 'glass-card'">
            <v-card-title class="pa-4 border-b bg-orange-darken-3 text-white">
                <span class="text-subtitle-1 font-weight-black text-uppercase d-flex align-center gap-2">
                    <v-icon>mdi-package-down</v-icon> Importar do Estoque
                </span>
            </v-card-title>
            <v-card-text class="pa-6">
                <v-alert color="orange" variant="tonal" class="mb-4 text-caption font-weight-bold border-thin" icon="mdi-information-outline" density="compact">
                    Selecione um produto existente no estoque (Matéria-Prima/Produto Final) para iniciar a precificação de venda.
                </v-alert>

                <v-autocomplete
                    v-model="selectedStockItem"
                    :items="stockItems"
                    item-title="fabric_type"
                    item-value="id"
                    label="Pesquisar Produto do Estoque"
                    variant="outlined"
                    density="comfortable"
                    class="ui-field"
                    return-object
                    :bg-color="isLightMode ? 'white' : 'transparent'"
                >
                    <template v-slot:item="{ props, item }">
                        <v-list-item v-bind="props" :subtitle="`Unid: ${item.raw.unit_of_measure || 'N/A'}`">
                            <template v-slot:prepend>
                                <v-icon color="grey">mdi-package-variant-closed</v-icon>
                            </template>
                        </v-list-item>
                    </template>
                </v-autocomplete>
            </v-card-text>
            <v-card-actions class="pa-4 border-t d-flex justify-end gap-3" :class="isLightMode ? 'bg-grey-lighten-5' : 'bg-white-05'">
                <v-btn variant="outlined" class="btn-3d font-weight-bold" @click="stockImportModal = false">Cancelar</v-btn>
                <v-btn color="orange-darken-3" variant="flat" class="btn-3d font-weight-bold" @click="confirmStockImport" :disabled="!selectedStockItem">Iniciar Precificação</v-btn>
            </v-card-actions>
        </v-card>
    </v-dialog>

    <v-dialog v-model="shareModal" max-width="400px">
      <v-card class="rounded-lg shadow-lg border-thin" :class="isLightMode ? 'bg-white' : 'glass-card'">
        <v-card-title class="pa-4 border-b bg-teal-darken-3 text-white">
            <span class="text-subtitle-1 font-weight-black text-uppercase d-flex align-center gap-2">
                <v-icon>mdi-share-variant</v-icon> Compartilhar Preço
            </span>
        </v-card-title>
        <v-card-text class="pa-6 text-center">
            <p class="text-body-2 font-weight-bold mb-6">Como deseja enviar a cotação do item <strong class="text-teal">{{ itemToShare?.name }}</strong>?</p>

            <div class="d-flex flex-column gap-3">
              <v-btn color="green-darken-1" variant="flat" class="btn-3d" height="48" @click="shareViaWhatsApp" prepend-icon="mdi-whatsapp">
                Enviar por WhatsApp
              </v-btn>

              <v-btn color="indigo" variant="flat" class="btn-3d" height="48" @click="shareViaEmail" prepend-icon="mdi-email-outline">
                Enviar por E-mail
              </v-btn>
            </div>
        </v-card-text>
        <v-card-actions class="pa-4 border-t d-flex justify-end" :class="isLightMode ? 'bg-grey-lighten-5' : 'bg-white-05'">
            <v-btn variant="text" class="font-weight-bold" @click="shareModal = false">Fechar</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <v-dialog v-model="dialog" max-width="750px" persistent scrollable>
      <v-card class="rounded-lg shadow-lg border-thin d-flex flex-column h-100" :class="isLightMode ? 'bg-white' : 'glass-card'" style="max-height: 90vh;">
        <v-card-title class="pa-4 border-b flex-shrink-0 bg-indigo-darken-3 text-white">
            <span class="text-subtitle-1 font-weight-black text-uppercase d-flex align-center gap-2">
                <v-icon>{{ editedIndex === -1 ? 'mdi-tag-plus' : 'mdi-pencil' }}</v-icon>
                {{ formTitle }}
            </span>
        </v-card-title>

        <v-card-text class="pa-6 flex-grow-1 overflow-y-auto custom-scroll">
          <div class="text-subtitle-2 font-weight-black text-uppercase mb-3 d-flex align-center justify-space-between" :class="isLightMode ? 'text-indigo-darken-2' : 'text-indigo-lighten-2'">
              Dados do Produto
              <v-chip v-if="editedItem.stock_id" size="x-small" color="orange" variant="flat" class="font-weight-black chip-3d">Vínculo ERP Ativo</v-chip>
          </div>

          <v-text-field v-model="editedItem.name" label="Nome do Produto *" variant="outlined" density="comfortable" class="ui-field mb-2 font-weight-bold text-uppercase" :bg-color="isLightMode ? 'white' : 'transparent'" :readonly="!!editedItem.stock_id" :hint="editedItem.stock_id ? 'Nome travado por causa do vínculo com o estoque' : ''" persistent-hint></v-text-field>

          <v-row dense class="mb-2">
            <v-col cols="12" sm="8">
              <v-text-field v-model="editedItem.composition" label="Composição / Detalhes" variant="outlined" density="comfortable" class="ui-field" :bg-color="isLightMode ? 'white' : 'transparent'"></v-text-field>
            </v-col>
            <v-col cols="12" sm="4">
              <v-text-field v-model="editedItem.grammage" label="Gramatura" variant="outlined" density="comfortable" hint="Ex: 180g/m²" class="ui-field" :bg-color="isLightMode ? 'white' : 'transparent'"></v-text-field>
            </v-col>
          </v-row>

          <v-row dense>
             <v-col cols="12" sm="4">
                <v-text-field v-model="editedItem.width_length" label="Largura" variant="outlined" density="comfortable" hint="Ex: 1,60m" class="ui-field" :bg-color="isLightMode ? 'white' : 'transparent'"></v-text-field>
            </v-col>
             <v-col cols="12" sm="4">
                <v-text-field v-model="editedItem.rolo" label="Tamanho Rolo" variant="outlined" density="comfortable" hint="Ex: Aprox. 50m" class="ui-field" :bg-color="isLightMode ? 'white' : 'transparent'"></v-text-field>
            </v-col>
            <v-col cols="12" sm="4">
                <v-select v-model="editedItem.unit" :items="['metro', 'kg', 'unidade']" label="Unidade Base" variant="outlined" density="comfortable" class="ui-field font-weight-bold text-uppercase" :bg-color="isLightMode ? 'white' : 'transparent'"></v-select>
            </v-col>
            <v-col cols="12" sm="4" v-if="editedItem.unit === 'kg'">
                <v-text-field v-model="editedItem.rendimento" label="Rendimento (m/kg)" variant="outlined" density="comfortable" hint="Ex: 3.5" class="ui-field" :bg-color="isLightMode ? 'white' : 'transparent'"></v-text-field>
            </v-col>
          </v-row>

          <v-divider class="my-6 border-opacity-25"></v-divider>

          <div class="text-subtitle-2 font-weight-black text-uppercase mb-4" :class="isLightMode ? 'text-green-darken-3' : 'text-success'">Precificação de Venda</div>

          <v-row dense>
            <v-col cols="12" sm="6">
              <v-text-field v-model.number="editedItem.price_se_cash" label="Preço Sudeste (À Vista)" type="number" variant="outlined" density="comfortable" prefix="R$" class="ui-field font-weight-bold text-success" :bg-color="isLightMode ? 'white' : 'transparent'"></v-text-field>
            </v-col>
            <v-col cols="12" sm="6">
              <v-text-field v-model.number="editedItem.price_se_term" label="Preço Sudeste (A Prazo)" type="number" variant="outlined" density="comfortable" prefix="R$" class="ui-field font-weight-bold text-success" :bg-color="isLightMode ? 'white' : 'transparent'"></v-text-field>
            </v-col>
            <v-col cols="12" sm="6">
              <v-text-field v-model.number="editedItem.price_ne_cash" label="Preço Nordeste (À Vista)" type="number" variant="outlined" density="comfortable" prefix="R$" class="ui-field font-weight-bold text-info" :bg-color="isLightMode ? 'white' : 'transparent'"></v-text-field>
            </v-col>
            <v-col cols="12" sm="6">
              <v-text-field v-model.number="editedItem.price_ne_term" label="Preço Nordeste (A Prazo)" type="number" variant="outlined" density="comfortable" prefix="R$" class="ui-field font-weight-bold text-info" :bg-color="isLightMode ? 'white' : 'transparent'"></v-text-field>
            </v-col>
          </v-row>
        </v-card-text>

        <v-card-actions class="pa-4 border-t flex-shrink-0 d-flex justify-end gap-3" :class="isLightMode ? 'bg-grey-lighten-5' : 'bg-white-05'">
          <v-btn variant="outlined" class="btn-3d font-weight-bold" height="40" @click="closeDialog" :color="isLightMode ? 'grey-darken-3' : 'white'">Cancelar</v-btn>
          <v-btn color="indigo" variant="flat" class="btn-3d font-weight-bold px-6" height="40" @click="saveItem" :loading="isSaving">
              <v-icon start>mdi-content-save-check</v-icon> Salvar Produto
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from 'vue';
import { supabase } from '@/api/supabase';
import { useThemeStore } from '@/stores/theme';
import { useAppStore } from '@/stores/app';

type Product = {
  id: string; name: string; composition: string; grammage: string;
  unit: 'metro' | 'kg' | 'unidade' | string; rendimento?: string | null; width_length?: string | null; rolo?: string | null;
  price_se_cash: number; price_se_term: number; price_ne_cash: number; price_ne_term: number;
  stock_id?: string | null;
};

const themeStore = useThemeStore();
const appStore = useAppStore();
const isLightMode = computed(() => themeStore.currentMode === 'light');

const loading = ref(true);
const search = ref('');
const products = ref<Product[]>([]);
const viewMode = ref('grid');
const gridDensity = ref<'compact'|'comfortable'>('comfortable'); // Controle de Densidade da Grid
const dialog = ref(false);
const isSaving = ref(false);
const editedIndex = ref(-1);

// Modais Secundários
const stockImportModal = ref(false);
const shareModal = ref(false);
const stockItems = ref<any[]>([]);
const selectedStockItem = ref<any>(null);
const itemToShare = ref<Product | null>(null);

const defaultItem: Partial<Product> = {
    name: '', composition: '', grammage: '', width_length: '', rolo: '', unit: 'metro', rendimento: null,
    price_se_cash: 0, price_se_term: 0, price_ne_cash: 0, price_ne_term: 0, stock_id: null
};

const editedItem = ref<Partial<Product>>({ ...defaultItem });

const formTitle = computed(() => editedIndex.value === -1 ? 'Nova Precificação' : 'Editar Regras de Preço');
const filteredProducts = computed(() => {
    if (!search.value) return products.value;
    const query = search.value.toLowerCase();
    return products.value.filter(p =>
        p.name.toLowerCase().includes(query) ||
        p.composition?.toLowerCase().includes(query)
    );
});

const fetchProducts = async () => {
  loading.value = true;
  try {
    const { data, error } = await supabase.from('price_list').select('*').order('name');
    if (error) throw error;
    products.value = data || [];
  } catch (err: any) {
      appStore.showSnackbar('Erro ao carregar preços.', 'error');
  } finally { loading.value = false; }
};

// --- STOCK INTEGRATION ---
const fetchStockItems = async () => {
    try {
        const { data, error } = await supabase.from('stock').select('id, fabric_type, unit_of_measure').order('fabric_type');
        if (error) throw error;
        stockItems.value = data || [];
    } catch (e) {
        console.error("Erro ao buscar estoque", e);
    }
};

const openStockImportModal = async () => {
    selectedStockItem.value = null;
    await fetchStockItems();
    stockImportModal.value = true;
};

const confirmStockImport = () => {
    if (!selectedStockItem.value) return;

    let u = String(selectedStockItem.value.unit_of_measure).toLowerCase();
    if (u === 'kg' || u.includes('quilo')) u = 'kg';
    else if (u === 'm' || u.includes('mt') || u.includes('metro')) u = 'metro';
    else u = 'unidade';

    editedItem.value = {
        ...defaultItem,
        name: selectedStockItem.value.fabric_type,
        unit: u,
        stock_id: selectedStockItem.value.id
    };

    stockImportModal.value = false;
    editedIndex.value = -1;
    dialog.value = true;
};

// --- COMPARTILHAMENTO (WHATSAPP/E-MAIL) ---
const openShareModal = (item: Product) => {
    itemToShare.value = item;
    shareModal.value = true;
};

const generateShareText = (item: Product) => {
    const r = `*TABELA DE PREÇOS - CONFECÇÕES MJ*\n\n*Produto:* ${item.name.toUpperCase()}\n*Composição:* ${item.composition || '-'}\n*Gramatura:* ${item.grammage || '-'}\n*Largura:* ${item.width_length || '-'}\n*Unidade Base:* ${item.unit.toUpperCase()}\n\n📊 *PREÇOS SUDESTE*\nÀ Vista: ${formatCurrency(item.price_se_cash)}\nA Prazo: ${formatCurrency(item.price_se_term)}\n\n📊 *PREÇOS NORDESTE*\nÀ Vista: ${formatCurrency(item.price_ne_cash)}\nA Prazo: ${formatCurrency(item.price_ne_term)}`;
    return encodeURIComponent(r);
};

const shareViaWhatsApp = () => {
    if(!itemToShare.value) return;
    window.open(`https://wa.me/?text=${generateShareText(itemToShare.value)}`, '_blank');
    shareModal.value = false;
};

const shareViaEmail = () => {
    if(!itemToShare.value) return;
    const subject = encodeURIComponent(`Cotação de Preço: ${itemToShare.value.name.toUpperCase()}`);
    window.open(`mailto:?subject=${subject}&body=${generateShareText(itemToShare.value)}`, '_blank');
    shareModal.value = false;
};

// --- CRUD ---
const openDialog = (item: Product | null = null) => {
    editedIndex.value = item ? products.value.findIndex(p => p.id === item.id) : -1;
    editedItem.value = item ? { ...item } : { ...defaultItem };
    dialog.value = true;
};

const cloneItem = (item: Product) => {
    const cloned = { ...item };
    delete (cloned as any).id; // Remove ID para virar um item novo
    cloned.name = `${cloned.name} (CÓPIA)`;
    editedIndex.value = -1; // Força Insert
    editedItem.value = cloned;
    dialog.value = true;
    appStore.showSnackbar('Item clonado. Ajuste os dados e salve.', 'info');
};

const closeDialog = () => { dialog.value = false; };

const saveItem = async () => {
    isSaving.value = true;
    try {
        const payload = { ...editedItem.value };
        if (payload.unit !== 'kg') payload.rendimento = null;

        // FIX: Remove o stock_id do envio para não estourar erro de schema cache no BD
        const { id, stock_id, ...dataToSave } = payload as any;

        if (editedIndex.value > -1) {
            const { error } = await supabase.from('price_list').update(dataToSave).eq('id', id);
            if (error) throw error;
            appStore.showSnackbar('Atualizado com sucesso!', 'success');
        } else {
            const { error } = await supabase.from('price_list').insert(dataToSave);
            if (error) throw error;
            appStore.showSnackbar('Produto cadastrado na tabela!', 'success');
        }
        await fetchProducts();
        closeDialog();
    } catch (err: any) {
        appStore.showSnackbar(`Erro: ${err.message}`, 'error');
    } finally { isSaving.value = false; }
};

const deleteItem = async (item: Product) => {
    if (confirm(`Tem certeza que deseja remover "${item.name}" da tabela de preços?`)) {
        try {
            const { error } = await supabase.from('price_list').delete().eq('id', item.id);
            if (error) throw error;
            appStore.showSnackbar('Removido.', 'success');
            await fetchProducts();
        } catch (err: any) { appStore.showSnackbar(`Erro: ${err.message}`, 'error'); }
    }
};

const formatCurrency = (value: number) => new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(value || 0);
const zebraClass = (i: number) => themeStore.currentMode !== 'light' ? (i % 2 === 0 ? 'zebra-dark-a' : 'zebra-dark-b') : (i % 2 === 0 ? 'zebra-light-a' : 'zebra-light-b');

onMounted(fetchProducts);
</script>

<style scoped lang="scss">
/* Layout Geral */
.price-admin-layout { position: relative; height: 100vh; }
.bg-glass-dark { background: rgba(10,10,12,0.95); }
.bg-glass-header { background: rgba(20,20,24,0.85); backdrop-filter: blur(14px); }
.background-carousel-wrapper { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 0; opacity: 0.6; pointer-events: none; }
.background-overlay { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 1; background: radial-gradient(circle at center, rgba(15, 15, 19, 0.4), rgba(15, 15, 19, 0.98)); backdrop-filter: blur(8px); }

/* Campos de Busca e Filtros */
.search-wrap { height: 40px; padding: 0 12px; display: flex; align-items: center; flex: 1; border-radius: 6px; }
.search-light { background: #f4f6f8; border: 1px solid rgba(0,0,0,0.08); }
.search-light:focus-within { border-color: #3f51b5; box-shadow: 0 0 0 2px rgba(63,81,181,0.1); }
.search-dark { background: rgba(255,255,255,0.08); border: 1px solid rgba(255,255,255,0.10); }
.search-dark:focus-within { border-color: rgba(255,255,255,0.3); background: rgba(255,255,255,0.08); }
.clean-input { border: none; outline: none; flex: 1; font-size: 13px; background: transparent; color: inherit; }

/* Grid e Scroll (Padrão AdminMjReceivables) */
.grid-scroll { scrollbar-gutter: stable; -webkit-overflow-scrolling: touch; }
.custom-scroll::-webkit-scrollbar { width: 8px; height: 8px; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.35); border-radius: 6px; }
.custom-scroll::-webkit-scrollbar-track { background: transparent; }

/* Grid Definition - Min-width force horizontal scroll */
.grid-header, .grid-row {
    display: grid;
    align-items: stretch;
    width: 100%;
    min-width: 1700px; /* Force Scroll */
}

/* Cells Config com Border Right explícito */
.cell {
    padding: 0 12px;
    display: flex;
    align-items: center;
    border-right: 1px solid rgba(0,0,0,0.08); /* Linha Vertical Restabelecida */
    border-bottom: 1px solid rgba(0,0,0,0.08);
    overflow: visible; /* Para tooltips não cortarem */
    transition: all 0.2s ease;
}

/* Remove a borda da última coluna para não ficar linha sobrando na beirada */
.cell:last-child {
    border-right: none !important;
}

/* Densidade da Grid (Controle) */
.density-compact .cell { min-height: 40px; height: 40px; }
.density-compact .list-text { font-size: 11px !important; }
.density-compact .grid-header .cell { font-size: 10px !important; min-height: 36px; height: 36px; }

.density-comfortable .cell { min-height: 56px; height: 56px; }
.density-comfortable .list-text { font-size: 13px !important; }
.density-comfortable .grid-header .cell { font-size: 11px !important; min-height: 44px; height: 44px; }

.grid-header .cell {
    font-weight: 900;
    text-transform: uppercase;
    letter-spacing: 0.5px;
    line-height: 1.2;
    opacity: 0.9;
}

/* Alinhamentos */
.center { justify-content: center; text-align: center; }
.right { justify-content: flex-end; text-align: right; }

/* Themes do Grid */
.grid-surface-light .cell { background: #f5f7fa; color: rgba(0,0,0,0.9); border-color: rgba(0,0,0,0.12) !important; }
.grid-surface-dark .cell { background: rgba(255,255,255,0.08); color: rgba(255,255,255,0.8); border-color: rgba(255,255,255,0.1) !important; backdrop-filter: none; }
.grid-row-light .cell { border-color: rgba(0,0,0,0.08) !important; }
.grid-row-dark .cell { border-color: rgba(255,255,255,0.08) !important; }

/* Zebras e Hover */
.zebra-light-a .cell { background: #ffffff; }
.zebra-light-b .cell { background: #f0f4f8; }
.zebra-dark-a .cell { background: rgba(255,255,255,0.04); }
.zebra-dark-b .cell { background: rgba(255,255,255,0.015); }
.grid-row-light:hover .cell { background: #e3f2fd !important; }
.grid-row-dark:hover .cell { background: rgba(255,255,255,0.07) !important; }

.hover-link:hover { text-decoration: underline; color: #1976d2 !important; }

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
}

.square-btn { width: 32px !important; height: 32px !important; min-width: 32px !important; padding: 0 !important; }

/* ESPAÇAMENTO DE AÇÕES (CORRIGIDO) */
.actions-inline {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 10px; /* <--- ESPAÇO ENTRE OS BOTÕES ADICIONADO AQUI */
    width: 100%;
}

/* Fix Tooltips Contrast - Dark BG / White Text */
:global(.tooltip-contrast > .v-overlay__content) { background-color: rgba(33, 33, 33, 0.95) !important; color: #ffffff !important; font-size: 11px !important; font-weight: 700 !important; border-radius: 4px; border: 1px solid rgba(255,255,255,0.2); }

/* Price Cards (Visualização Alternativa) */
.price-card {
  position: relative;
  border-left: 5px solid;
  transition: all 0.2s ease-in-out;
  height: 100%;
  display: flex;
  flex-direction: column;

  &.unit--kg { border-left-color: #7E57C2; }
  &.unit--metro { border-left-color: #00897B; }
  &.unit--unidade { border-left-color: #F57C00; }
}

.price-card-light {
  background-color: #ffffff;
  border: 1px solid rgba(0,0,0,0.08);
  box-shadow: 0 4px 12px rgba(0,0,0,0.05);
}

.card-actions-menu { position: absolute; top: 8px; right: 8px; z-index: 2;}
.menu-list-styling { background-color: rgba(30, 30, 35, 0.95) !important; backdrop-filter: blur(10px); color: white;}

.info-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(80px, 1fr)); gap: 12px; }
.info-item { display: flex; flex-direction: column; }
.info-label { font-size: 0.65rem; text-transform: uppercase; margin-bottom: 2px; font-weight: 900; }
.info-value { font-size: 0.85rem; font-weight: 700; }

/* Utils & Modal */
.border-thin { border: 1px solid rgba(128,128,128,0.2) !important; }
.bg-white-05 { background-color: rgba(255,255,255,0.05) !important; }
.ui-field :deep(.v-field) { border-radius: 6px !important; }

.glass-card {
  backdrop-filter: blur(25px);
  background-color: rgba(30, 30, 35, 0.85);
  color: white;
}

.sticky-head { position: sticky; top: 0; z-index: 20; box-shadow: 0 8px 16px -4px rgba(0, 0, 0, 0.12); }
.bg-glass-dark .sticky-head { box-shadow: 0 8px 20px -4px rgba(0, 0, 0, 0.4); }
</style>
