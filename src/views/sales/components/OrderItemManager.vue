<template>
  <v-card
    class="order-item-manager d-flex flex-column bg-transparent h-auto"
    elevation="0"
  >

    <div class="px-6 py-4 border-b flex-shrink-0" :class="[isLight ? 'bg-white' : 'glass-card', borderClass]">
       <div class="d-flex align-center justify-space-between">
          <div class="d-flex align-center gap-3">
             <div class=" rounded-lg d-flex align-center justify-center elevation-1" :class="themeStore.currentMode === 'light' ? 'bg-indigo-lighten-5 text-indigo' : 'bg-primary text-white'">
                <v-icon size="20">mdi-tshirt-crew</v-icon>
             </div>
             <div class="lh-1">
                <h2 class="text-subtitle-1 font-weight-black" :class="textPrimaryClass">Gerenciador de Itens</h2>
             </div>
          </div>

          <div class="d-flex align-center gap-2">
             <div class="px-4 py-2 rounded border d-flex flex-column align-end lh-1 transition-all" :class="[isLight ? 'bg-grey-lighten-5' : 'bg-surface', borderClass]">
                <span class="text-[9px] font-weight-bold uppercase opacity-60 mb-1" :class="textSecondaryClass">Metragem</span>
                <span class="text-subtitle-2 font-weight-black font-mono" :class="textPrimaryClass">{{ formatCurrency(totalMeters, '', 2) }}m</span>
             </div>
             <div class="px-4 py-2 rounded border d-flex flex-column align-end lh-1 transition-all" :class="[isLight ? 'bg-grey-lighten-5' : 'bg-surface', borderClass]">
                <span class="text-[9px] font-weight-bold uppercase opacity-60 mb-1" :class="textSecondaryClass">Itens</span>
                <span class="text-subtitle-2 font-weight-black font-mono" :class="textPrimaryClass">{{ items.length }}</span>
             </div>
          </div>
       </div>
    </div>

    <div
        class="relative d-flex align-start"
        :class="mobile ? 'flex-column h-auto' : 'flex-grow-1 overflow-hidden h-100'"
        style="min-height: 0;"
    >
       <v-row class="ma-0 fill-height w-100" no-gutters>

          <v-col cols="12" md="6"
                 id="left-form-panel"
                 class="pa-6 border-e border-b d-flex flex-column custom-scroll smooth-scroll"
                 :class="[
                    isLight ? 'bg-white' : 'glass-card',
                    borderClass,
                    mobile ? 'h-auto overflow-visible pb-16' : 'h-100 overflow-y-auto'
                 ]"
          >

             <div class="d-flex justify-space-between align-center mb-4 flex-shrink-0">
                <div class="d-flex align-center gap-2">
                    <span class="text-subtitle-2 font-weight-bold" :class="textPrimaryClass">
                        {{ isEditing ? 'Editando Item' : 'Novo Item' }}
                    </span>
                    <v-scale-transition>
                        <v-chip v-if="isEditing" size="x-small" color="warning" variant="flat" class="font-weight-bold uppercase">Modo Edição</v-chip>
                    </v-scale-transition>
                </div>
                <v-btn v-if="isEditing" variant="text" size="small" color="medium-emphasis" @click="prepareNewItem" class="px-2">
                    <v-icon start size="16">mdi-close</v-icon> Cancelar
                </v-btn>
             </div>

             <div class="d-flex align-center justify-space-between pa-4 rounded-lg border mb-5 shadow-sm flex-shrink-0"
                  :class="[
                      themeStore.currentMode === 'light' ? 'bg-indigo-lighten-5 border-indigo-lighten-4' : 'bg-surface border-white-10'
                  ]">
                <v-switch
                    v-model="overridePrice"
                    color="primary"
                    hide-details
                    density="compact"
                    inset
                    :disabled="editedItem.is_exclusive"
                    class="ml-1"
                >
                    <template v-slot:label>
                        <span class="text-caption font-weight-bold ml-2" :class="textPrimaryClass">Editar Preço</span>
                    </template>
                </v-switch>

                <div class="h-24 border-s mx-2 opacity-20" :class="isLight ? 'border-black' : 'border-white'"></div>

                <v-switch
                    v-model="editedItem.is_ready_for_billing"
                    color="success"
                    hide-details
                    density="compact"
                    inset
                    class="mr-1"
                >
                    <template v-slot:label>
                        <span class="text-caption font-weight-bold ml-2" :class="editedItem.is_ready_for_billing ? 'text-success' : textPrimaryClass">Pronta Entrega</span>
                    </template>
                </v-switch>
             </div>

             <div class="stamp-hero-container mb-6 rounded-lg relative overflow-hidden transition-all group elevation-2 flex-shrink-0"
                  :class="[
                      borderClass,
                      editedItem.stamp_image_url ? 'has-image' : 'border-dashed',
                      themeStore.currentMode === 'light' ? 'bg-grey-lighten-4' : 'bg-glass-darker'
                  ]"
                  style="min-height: 220px;"
             >
                <v-img
                   v-if="editedItem.stamp_image_url"
                   :src="editedItem.stamp_image_url"
                   height="220"
                   cover
                   class="transition-transform duration-500 group-hover:scale-105"
                >
                   <div class="absolute inset-0 bg-gradient-to-t from-black/80 via-transparent to-transparent opacity-90"></div>
                   <div class="absolute bottom-0 left-0 p-4 w-100 z-10">
                      <div class="text-white text-subtitle-1 font-weight-bold text-truncate shadow-text">{{ editedItem.stamp_ref }}</div>
                      <div class="text-white-70 text-caption font-weight-medium">Arte Selecionada</div>
                   </div>

                   <div class="absolute top-3 right-3 d-flex gap-2 z-10">
                      <v-btn icon size="x-small" color="white" variant="flat" @click="showStampCatalog = true" :disabled="editedItem.is_ready_for_billing" class="shadow-sm">
                          <v-icon color="grey-darken-3" size="18">mdi-refresh</v-icon>
                          <v-tooltip activator="parent" location="bottom">Trocar Arte</v-tooltip>
                      </v-btn>
                      <v-btn icon size="x-small" color="white" variant="flat" @click="clearStamp" class="shadow-sm">
                          <v-icon color="error" size="18">mdi-delete-outline</v-icon>
                      </v-btn>
                   </div>
                </v-img>

                <div v-else class="d-flex flex-column align-center justify-center h-100 py-8 cursor-pointer hover-bg-subtle transition-all" @click="showStampCatalog = true">
                   <div class="icon-circle-lg mb-3 transition-transform group-hover:scale-110 shadow-soft" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-surface'">
                      <v-icon size="32" :color="themeStore.currentMode === 'light' ? 'primary' : 'white'">mdi-image-search-outline</v-icon>
                   </div>
                   <div class="text-body-2 font-weight-bold" :class="textPrimaryClass">Selecionar Estampa</div>
                   <div class="text-caption text-medium-emphasis mb-4">Clique para buscar no catálogo</div>

                   <v-btn color="primary" variant="flat" size="small" class="font-weight-bold px-6 rounded text-none">
                       Abrir Catálogo
                   </v-btn>

                   <div class="mt-3" @click.stop>
                       <v-btn variant="text" size="x-small" :color="textSecondaryColor" @click="toggleStampUpload" class="text-none opacity-70 hover:opacity-100">
                          Ou upload manual
                       </v-btn>
                   </div>

                   <v-expand-transition>
                      <div v-if="isUploadingNewStamp" class="mt-3 w-75 pa-3 rounded border bg-surface elevation-3 absolute bottom-0 z-20" @click.stop>
                          <div class="text-[10px] font-weight-bold text-uppercase mb-2 text-medium-emphasis">Upload Rápido</div>
                          <v-file-input
                             @change="handleNewStampFileChange"
                             label="Selecionar Arquivo"
                             variant="outlined"
                             density="compact"
                             prepend-icon=""
                             prepend-inner-icon="mdi-camera"
                             hide-details
                             :bg-color="inputBgColor"
                             class="mb-2 text-caption"
                             rounded="sm"
                          ></v-file-input>
                          <v-text-field
                             v-model="editedItem.stamp_ref"
                             label="Nome da Referência"
                             variant="outlined"
                             density="compact"
                             hide-details
                             :bg-color="inputBgColor"
                             class="mb-2 text-caption"
                             rounded="sm"
                          ></v-text-field>
                          <v-btn
                             block size="small" color="success"
                             :loading="isUploadingStampInProgress"
                             :disabled="!editedItem.new_stamp_file || !editedItem.stamp_ref"
                             @click="uploadAndRegisterNewStamp"
                             class="text-none font-weight-bold"
                             rounded="sm"
                          >Salvar e Usar</v-btn>
                      </div>
                   </v-expand-transition>
                </div>
             </div>

             <v-form ref="itemFormRef" class="flex-shrink-0">
                <v-row dense class="row-gap-2">
                   <v-col cols="12">
                      <label class="input-label" :class="textSecondaryClass">Base / Tecido</label>
                      <v-autocomplete
                         v-model="editedItem.fabric_type"
                         :items="products"
                         item-title="nome"
                         item-value="nome"
                         placeholder="Selecione o tecido..."
                         variant="outlined"
                         density="comfortable"
                         :loading="loadingProducts"
                         :rules="[rules.required]"
                         :bg-color="inputBgColor"
                         hide-details="auto"
                         class="font-weight-medium"
                         menu-icon="mdi-chevron-down"
                         rounded="md"
                      >
                         <template v-slot:item="{ props, item }">
                            <v-list-item v-bind="props" density="compact">
                               <template v-slot:append>
                                  <span class="text-[10px] font-weight-bold px-2 py-1 rounded" :class="item.raw.estoque > 0 ? 'bg-green-lighten-5 text-green' : 'bg-red-lighten-5 text-red'">
                                     {{ item.raw.estoque }} {{ (item.raw.unidade || 'm').toLowerCase() }}
                                  </span>
                               </template>
                            </v-list-item>
                         </template>
                      </v-autocomplete>
                   </v-col>

                   <v-col cols="12" sm="6">
                      <label class="input-label" :class="textSecondaryClass">Quantidade</label>
                      <div class="d-flex align-center gap-2">
                         <v-text-field
                            v-model.number="editedItem.quantity"
                            type="number"
                            variant="outlined"
                            density="comfortable"
                            :rules="[rules.required, rules.positive]"
                            :disabled="!editedItem.fabric_type"
                            :bg-color="inputBgColor"
                            placeholder="0.00"
                            :suffix="selectedProductUnit"
                            hide-details="auto"
                            class="font-weight-bold"
                            rounded="md"
                         ></v-text-field>

                         <v-menu v-if="selectedProductUnit === 'kg'" location="bottom end" :close-on-content-click="false">
                            <template v-slot:activator="{ props }">
                               <v-btn v-bind="props" icon="mdi-calculator" variant="tonal" color="primary" size="small" rounded="lg"></v-btn>
                            </template>
                            <v-card min-width="200" class="pa-3">
                               <div class="text-caption mb-1">Converter Metros -> KG</div>
                               <v-text-field
                                  v-model.number="tempMeters"
                                  label="Metros"
                                  density="compact"
                                  type="number"
                                  hide-details
                               ></v-text-field>
                            </v-card>
                         </v-menu>
                      </div>

                      <div v-if="editedItem.fabric_type" class="mt-2 px-1">
                         <div class="d-flex justify-space-between text-[9px] font-weight-bold mb-1">
                            <span :class="realTimeAvailableStock < 0 ? 'text-error' : textSecondaryClass">
                               {{ realTimeAvailableStock < 0 ? 'Estoque Insuficiente' : 'Disponível' }}
                            </span>
                            <span class="font-mono" :class="textPrimaryClass">{{ formatCurrency(realTimeAvailableStock, '', 1) }}{{ selectedProductUnit }}</span>
                         </div>
                         <v-progress-linear
                            :model-value="stockPercentage"
                            :color="getStockUsageColor(editedItem.quantity || 0, realTimeAvailableStock)"
                            height="4"
                            rounded
                            class="opacity-80"
                         ></v-progress-linear>
                      </div>
                   </v-col>

                   <v-col cols="12" sm="6">
                      <label class="input-label" :class="textSecondaryClass">Valor Unitário</label>
                      <v-text-field
                         v-model.number="editedItem.valor_unitario"
                         type="number"
                         variant="outlined"
                         density="comfortable"
                         :readonly="!overridePrice || editedItem.is_exclusive"
                         prefix="R$"
                         :bg-color="inputBgColor"
                         hide-details="auto"
                         class="font-weight-bold"
                         rounded="md"
                      ></v-text-field>
                   </v-col>

                   <v-col cols="12" v-if="!editedItem.is_ready_for_billing">
                      <label class="input-label" :class="textSecondaryClass">Coluna de Destino (Design)</label>
                      <v-select
                         v-model="editedItem.design_tag"
                         :items="designTagsList"
                         variant="outlined"
                         density="comfortable"
                         :bg-color="inputBgColor"
                         hide-details="auto"
                         menu-icon="mdi-chevron-down"
                         rounded="md"
                      >
                         <template v-slot:selection="{ item }">
                            <v-chip size="x-small" :color="getTagColor(item.raw)" variant="flat" label class="font-weight-bold text-uppercase letter-spacing-1">{{ item.raw }}</v-chip>
                         </template>
                         <template v-slot:item="{ props, item }">
                            <v-list-item v-bind="props">
                                <template v-slot:prepend>
                                    <v-icon :color="getTagColor(item.raw)" size="small">mdi-circle</v-icon>
                                </template>
                            </v-list-item>
                         </template>
                      </v-select>
                   </v-col>

                   <v-col cols="12">
                      <label class="input-label" :class="textSecondaryClass">Observações para o Design</label>
                      <v-textarea
                         v-model="editedItem.notes"
                         placeholder="Ex: Refilar lateral, cuidado com a mancha..."
                         variant="outlined"
                         rows="2"
                         density="comfortable"
                         auto-grow
                         hide-details
                         :bg-color="inputBgColor"
                         class="text-body-2"
                         rounded="md"
                      ></v-textarea>
                   </v-col>
                </v-row>
             </v-form>

             <div class="mt-6 flex-shrink-0">
                 <v-btn
                    block
                    size="large"
                    color="primary"
                    class="font-weight-bold rounded text-none shadow-soft"
                    @click="saveOrUpdateItem"
                    height="48"
                    elevation="3"
                 >
                    <div class="d-flex align-center gap-2">
                        <v-icon>{{ isEditing ? 'mdi-content-save-edit' : 'mdi-plus' }}</v-icon>
                        {{ isEditing ? 'Atualizar Item' : 'Adicionar ao Pedido' }}
                    </div>
                 </v-btn>
             </div>
          </v-col>

          <v-col v-if="!mobile" cols="12" md="6"
                 class="h-100 d-flex flex-column pa-0 relative border-s"
                 :class="[isLight ? 'bg-white' : 'glass-card', borderClass]"
          >

             <div class="pa-4 border-b z-20 flex-shrink-0"
                  :class="[isLight ? 'bg-white' : 'bg-transparent', borderClass]">
                <v-text-field
                   ref="searchFieldRef"
                   v-model="itemListSearch"
                   placeholder="Filtrar por estampa ou tecido..."
                   variant="outlined"
                   density="compact"
                   prepend-inner-icon="mdi-magnify"
                   hide-details
                   :bg-color="isLight ? 'grey-lighten-5' : undefined"
                   class="font-weight-medium"
                   rounded="md"
                ></v-text-field>
             </div>

             <div class="flex-grow-1 overflow-hidden d-flex flex-column relative" style="min-height: 0;">
                 <div class="grid-scroll flex-grow-1 overflow-y-auto overflow-x-hidden custom-scroll w-100">

                    <div class="grid-header sticky-head" :class="[isLight ? 'grid-surface-light' : 'grid-surface-dark', 'grid-items-layout']">
                        <div class="cell center header-text" :class="isLight ? 'text-medium-emphasis' : 'text-grey'">#</div>
                        <div class="cell center header-text" :class="isLight ? 'text-medium-emphasis' : 'text-grey'">Img</div>
                        <div class="cell header-text" :class="isLight ? 'text-medium-emphasis' : 'text-grey'">Referência</div>
                        <div class="cell header-text" :class="isLight ? 'text-medium-emphasis' : 'text-grey'">Tecido</div>
                        <div class="cell center header-text" :class="isLight ? 'text-medium-emphasis' : 'text-grey'">Qtd</div>
                        <div class="cell right header-text" :class="isLight ? 'text-medium-emphasis' : 'text-grey'">V. Unit.</div>
                        <div class="cell right header-text" :class="isLight ? 'text-medium-emphasis' : 'text-grey'">Total</div>
                        <div class="cell center header-text" :class="isLight ? 'text-medium-emphasis' : 'text-grey'">Status</div>
                        <div class="cell center header-text" :class="isLight ? 'text-medium-emphasis' : 'text-grey'">Ações</div>
                    </div>

                    <div v-if="filteredItems.length === 0" class="d-flex flex-column align-center justify-center h-100 opacity-50 py-10">
                       <v-icon size="48" color="grey-lighten-1" class="mb-2">mdi-basket-outline</v-icon>
                       <div class="text-caption font-weight-bold text-uppercase letter-spacing-1">Nenhum item lançado</div>
                    </div>

                    <div
                       v-for="(item, index) in filteredItems"
                       :key="item.id"
                       class="grid-row transition-colors group relative"
                       :class="[
                          themeStore.currentMode === 'light' ? 'grid-row-light' : 'grid-row-dark',
                          editedItemIndex === getOriginalIndex(item.id) ? 'grid-selected' : 'hover-bg-row',
                          checkInsufficientStock(item) ? 'row-out-of-stock' : '',
                          'grid-items-layout'
                       ]"
                    >
                       <div class="cell center py-2">
                           <span class="text-[10px] font-weight-bold opacity-70">
                               {{ getOriginalIndex(item.id) + 1 }}
                           </span>
                       </div>

                       <div class="cell center py-2 relative">
                          <div class="relative d-flex align-center justify-center">
                              <v-avatar rounded="md" size="28" class="border-thin elevation-1" :class="isLight ? 'bg-white' : 'bg-grey-darken-3'">
                                 <v-img v-if="item.stamp_image_url" :src="item.stamp_image_url" cover></v-img>
                                 <v-icon v-else size="16" class="text-medium-emphasis">mdi-image-off-outline</v-icon>
                              </v-avatar>
                              <v-icon
                                  v-if="checkInsufficientStock(item)"
                                  class="pulse-alert-icon"
                                  color="error"
                              >mdi-alert-circle</v-icon>
                          </div>
                       </div>

                       <div class="cell py-2">
                           <span class="text-[10px] font-weight-black text-uppercase text-truncate w-100 d-block" :class="textPrimaryClass">
                               {{ item.stamp_ref || 'SEM REF' }}
                           </span>
                       </div>

                       <div class="cell py-2">
                           <span class="text-[10px] font-weight-medium text-uppercase text-truncate opacity-80 w-100 d-block" :class="textSecondaryClass">
                               {{ item.fabric_type || 'N/A' }}
                           </span>
                       </div>

                       <div class="cell center py-2">
                           <span class="text-[9px] font-weight-bold opacity-80 font-mono px-1 rounded text-truncate w-100 text-center" :class="isLight ? 'bg-grey-lighten-4' : 'bg-grey-darken-3'">
                               {{ item.quantity }}{{ item.unit_of_measure }}
                           </span>
                       </div>

                       <div class="cell right py-2">
                           <span class="text-[10px] font-weight-medium font-mono text-truncate d-block w-100 text-right" :class="textPrimaryClass">
                               {{ formatCurrency(Number(item.valor_unitario)) }}
                           </span>
                       </div>

                       <div class="cell right py-2">
                           <span class="text-[10px] font-weight-black font-mono lh-1 text-truncate d-block w-100 text-right" :class="textPrimaryClass">
                               {{ formatCurrency(Number(item.quantity) * Number(item.valor_unitario)) }}
                           </span>
                       </div>

                       <div class="cell center py-2">
                           <v-chip v-if="item.is_ready_for_billing" size="x-small" color="success" variant="flat" class="px-1 h-20 font-weight-bold text-[8px] letter-spacing-1 text-truncate max-w-100">PRONTA</v-chip>
                           <v-chip v-else size="x-small" :color="getTagColor(item.design_tag)" variant="tonal" class="px-1 h-20 font-weight-bold text-[8px] letter-spacing-1 text-truncate max-w-100">{{ item.design_tag }}</v-chip>
                       </div>

                       <div class="cell center py-2">
                           <div class="d-flex align-center justify-center w-100" style="gap: 2px;">
                               <v-btn
                                   icon size="x-small"
                                   variant="flat"
                                   class="action-btn action-edit"
                                   @click.stop="editItem(getOriginalIndex(item.id))"
                               >
                                   <v-icon size="12">mdi-pencil</v-icon>
                               </v-btn>

                               <v-btn
                                   icon size="x-small"
                                   variant="flat"
                                   class="action-btn action-clone"
                                   @click.stop="cloneItem(getOriginalIndex(item.id))"
                               >
                                   <v-icon size="12">mdi-content-copy</v-icon>
                               </v-btn>

                               <v-btn
                                   icon size="x-small"
                                   variant="flat"
                                   class="action-btn action-del"
                                   @click.stop="removeItem(getOriginalIndex(item.id))"
                               >
                                   <v-icon size="12">mdi-trash-can-outline</v-icon>
                               </v-btn>
                           </div>
                       </div>
                    </div>
                 </div>
             </div>
          </v-col>
       </v-row>
    </div>

    <v-btn
        v-if="mobile"
        position="fixed"
        location="bottom right"
        class="mb-20 mr-4 z-50 shadow-lg"
        color="primary"
        icon="mdi-format-list-bulleted"
        size="large"
        elevation="8"
        @click="showMobileList = true"
    >
        <v-badge v-if="items.length > 0" :content="items.length" color="error" floating>
            <v-icon>mdi-format-list-bulleted</v-icon>
        </v-badge>
        <v-icon v-else>mdi-format-list-bulleted</v-icon>
    </v-btn>

    <v-dialog
        v-model="showMobileList"
        fullscreen
        transition="dialog-bottom-transition"
        :scrim="false"
    >
        <v-card :class="isLight ? 'bg-grey-lighten-5' : 'bg-background-dark'">
            <v-toolbar color="primary" density="compact">
                <v-btn icon="mdi-close" @click="showMobileList = false"></v-btn>
                <v-toolbar-title class="text-subtitle-1 font-weight-bold">
                    Itens do Pedido ({{ items.length }})
                </v-toolbar-title>
                <v-spacer></v-spacer>
                <span class="text-caption font-weight-bold mr-4">{{ formatCurrency(totalMeters, '', 2) }}m</span>
            </v-toolbar>

            <div class="pa-3 bg-surface border-b">
                <v-text-field
                   v-model="itemListSearch"
                   placeholder="Buscar item..."
                   variant="outlined"
                   density="compact"
                   prepend-inner-icon="mdi-magnify"
                   hide-details
                   bg-color="white"
                   rounded="lg"
                ></v-text-field>
            </div>

            <v-card-text class="pa-3 pb-20 overflow-y-auto">
                <div v-if="filteredItems.length === 0" class="d-flex flex-column align-center justify-center mt-10 opacity-50">
                    <v-icon size="64" color="grey">mdi-basket-off-outline</v-icon>
                    <div class="mt-4 text-body-2">Nenhum item encontrado.</div>
                    <v-btn class="mt-4" variant="text" color="primary" @click="showMobileList = false">
                        Adicionar Item
                    </v-btn>
                </div>

                <div v-else class="d-flex flex-column gap-3">
                    <v-card
                        v-for="(item, index) in filteredItems"
                        :key="item.id"
                        class="rounded-lg border border-opacity-10"
                        :class="[
                            editedItemIndex === getOriginalIndex(item.id) ? 'border-primary border-2' : '',
                            checkInsufficientStock(item) ? 'row-out-of-stock' : ''
                        ]"
                        elevation="1"
                    >
                        <div class="d-flex pa-3 relative">
                            <div class="relative mr-3">
                                <v-avatar rounded="lg" size="60" class="bg-grey-lighten-4 border">
                                    <v-img v-if="item.stamp_image_url" :src="item.stamp_image_url" cover></v-img>
                                    <v-icon v-else color="grey">mdi-image-off</v-icon>
                                </v-avatar>
                                <v-icon
                                    v-if="checkInsufficientStock(item)"
                                    class="pulse-alert-icon"
                                    color="error"
                                >mdi-alert-circle</v-icon>
                            </div>

                            <div class="flex-grow-1 overflow-hidden">
                                <div class="d-flex justify-space-between align-start">
                                    <div class="text-subtitle-2 font-weight-black text-truncate">
                                        <span class="text-primary mr-1">#{{ getOriginalIndex(item.id) + 1 }}</span>
                                        {{ item.stamp_ref || 'Sem Ref' }}
                                    </div>
                                    <span class="text-subtitle-2 font-weight-black text-primary font-mono">
                                        {{ formatCurrency(Number(item.quantity) * Number(item.valor_unitario)) }}
                                    </span>
                                </div>

                                <div class="d-flex justify-space-between mt-1">
                                    <div class="text-caption text-medium-emphasis text-truncate">{{ item.fabric_type }}</div>
                                    <div class="text-[10px] font-weight-medium text-medium-emphasis">Un: {{ formatCurrency(item.valor_unitario) }}</div>
                                </div>

                                <div class="d-flex align-center mt-1 gap-2">
                                    <v-chip size="x-small" label class="font-weight-bold px-2">
                                        {{ item.quantity }}{{ item.unit_of_measure }}
                                    </v-chip>
                                    <v-chip
                                        size="x-small"
                                        :color="item.is_ready_for_billing ? 'success' : getTagColor(item.design_tag)"
                                        variant="tonal"
                                        class="font-weight-bold"
                                    >
                                        {{ item.is_ready_for_billing ? 'PRONTA' : item.design_tag }}
                                    </v-chip>
                                </div>
                            </div>
                        </div>

                        <div class="d-flex border-t border-opacity-10">
                            <v-btn
                                variant="text"
                                class="flex-grow-1 rounded-0 text-caption font-weight-bold text-none"
                                color="blue-darken-1"
                                prepend-icon="mdi-pencil"
                                @click="editItem(getOriginalIndex(item.id))"
                            >
                                Editar
                            </v-btn>
                            <v-divider vertical></v-divider>
                            <v-btn
                                variant="text"
                                class="flex-grow-1 rounded-0 text-caption font-weight-bold text-none"
                                color="green-darken-1"
                                prepend-icon="mdi-content-copy"
                                @click="cloneItem(getOriginalIndex(item.id))"
                            >
                                Clonar
                            </v-btn>
                            <v-divider vertical></v-divider>
                            <v-btn
                                variant="text"
                                class="flex-grow-1 rounded-0 text-caption font-weight-bold text-none"
                                color="error"
                                prepend-icon="mdi-trash-can-outline"
                                @click="removeItem(getOriginalIndex(item.id))"
                            >
                                Excluir
                            </v-btn>
                        </div>
                    </v-card>
                </div>
            </v-card-text>
        </v-card>
    </v-dialog>

    <v-dialog v-model="showZeroPriceModal" max-width="360">
       <v-card class="text-center pa-6 rounded-xl" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'glass-card'">
          <div class="d-flex justify-center mb-4">
              <div class="icon-circle-lg bg-amber-lighten-5 text-amber">
                  <v-icon size="32">mdi-alert-outline</v-icon>
              </div>
          </div>
          <h3 class="text-subtitle-1 font-weight-bold mb-2" :class="textPrimaryClass">Valor Inválido</h3>
          <p class="text-caption opacity-70 mb-5" :class="textSecondaryClass">O item não pode ter valor R$ 0,00. Por favor, ajuste o preço unitário.</p>
          <v-btn color="primary" variant="flat" block rounded="lg" @click="showZeroPriceModal = false">Entendi</v-btn>
       </v-card>
    </v-dialog>

    <StampCatalogModal
       :show="showStampCatalog"
       @close="showStampCatalog = false"
       @stamp-selected="handleStampSelection"
    />
  </v-card>
</template>

<script setup lang="ts">
import { ref, computed, watch, nextTick, toRaw, onMounted } from 'vue';
import { supabase } from '@/api/supabase';
import { useAppStore } from '@/stores/app';
import { useThemeStore } from '@/stores/theme';
import { useDisplay } from 'vuetify';

import StampCatalogModal from '@/components/StampCatalogModal.vue';

const props = defineProps<{
  items: any[];
  products: any[];
  stockItems: any[];
  stampLibrary: any[];
  loadingProducts: boolean;
  designTags?: string[];
}>();

const emit = defineEmits(['update:items']);
const appStore = useAppStore();
const themeStore = useThemeStore();
const { mobile } = useDisplay();

// REFS & STATE
const itemFormRef = ref<any>(null);
const searchFieldRef = ref<any>(null);
const showStampCatalog = ref(false);
const showZeroPriceModal = ref(false);
const isUploadingNewStamp = ref(false);
const isUploadingStampInProgress = ref(false);
const overridePrice = ref(false);
const tempMeters = ref<number | null>(null);
const itemListSearch = ref('');
const showMobileList = ref(false);

const PRONTA_ENTREGA_STAMP_ID = '83915888';
const rules = { required: (v: any) => !!v || 'Obrigatório.', positive: (v: number | null) => (v != null && v > 0) || '> 0' };

// Item State
const createNewItem = () => ({
  id: Date.now(),
  fabric_type: null,
  stamp_ref_id: null,
  stamp_ref: '',
  quantity: null,
  quantity_meters: null,
  unit_of_measure: 'm',
  rendimento: null,
  valor_unitario: null,
  stamp_image_url: null,
  notes: '',
  design_tag: props.designTags && props.designTags.length > 0 ? props.designTags[0] : 'Desenvolvimento',
  new_stamp_file: null,
  has_insufficient_stock: false,
  status: 'design_pending',
  is_ready_for_billing: false,
  is_exclusive: false
});

const editedItem = ref<any>(createNewItem());
const editedItemIndex = ref<number | null>(null);
const isEditing = computed(() => editedItemIndex.value !== null);
const isLight = computed(() => themeStore.currentMode === 'light');

// THEME COMPUTED PROPERTIES
const textPrimaryClass = computed(() => isLight.value ? 'text-grey-darken-4' : 'text-white');
const textSecondaryClass = computed(() => isLight.value ? 'text-grey-darken-1' : 'text-white-70');
const textSecondaryColor = computed(() => isLight.value ? 'grey' : 'white');
const borderClass = computed(() => isLight.value ? 'border-grey-lighten-2' : 'border-white-10');
const inputBgColor = computed(() => isLight.value ? undefined : 'rgba(255,255,255,0.03)');

// TAGS DINÂMICAS
const designTagsList = computed(() => {
    if (props.designTags && props.designTags.length > 0) return props.designTags;
    return ['Desenvolvimento', 'Alteração', 'Finalização'];
});

const getTagColor = (tag: string) => {
    const tagLower = (tag || '').toLowerCase();
    if (tagLower.includes('alteração')) return 'orange';
    if (tagLower.includes('finalização')) return 'teal';
    if (tagLower.includes('desenvolvimento')) return 'info';
    if (tagLower.includes('aprovação') || tagLower.includes('lider')) return 'purple';
    if (tagLower.includes('vetor')) return 'indigo';
    return 'blue-grey';
};


// LOGIC
const totalMeters = computed(() => props.items.reduce((total, item) => total + (item.quantity_meters || 0), 0));

const filteredItems = computed(() => {
  let result = props.items;
  if (itemListSearch.value) {
    const query = itemListSearch.value.toLowerCase();
    result = props.items.filter(item => item.stamp_ref?.toLowerCase().includes(query) || item.fabric_type?.toLowerCase().includes(query));
  }
  return [...result].reverse();
});

const getOriginalIndex = (itemId: number) => props.items.findIndex(item => item.id === itemId);

const selectedProduct = computed(() => props.stockItems.find(p => p.fabric_type === editedItem.value.fabric_type) || props.products.find(p => p.nome === editedItem.value.fabric_type));
const selectedProductUnit = computed(() => ((selectedProduct.value as any)?.unit_of_measure || (selectedProduct.value as any)?.unidade || 'm').toLowerCase());
const selectedProductRendimento = computed(() => (selectedProduct.value as any)?.rendimento || parseFloat((selectedProduct.value as any)?.rendimento || '0'));
const selectedProductStock = computed(() => {
    const product = props.products.find(p => p.nome === editedItem.value.fabric_type);
    return product ? parseFloat(product.estoque as string) || 0 : 0;
});

const checkInsufficientStock = (item: any) => {
    if (!item.fabric_type || !item.quantity) return false;
    const product = props.products.find(p => p.nome === item.fabric_type);
    const stock = product ? parseFloat(product.estoque as string) || 0 : 0;
    return item.quantity > stock;
};

const realTimeAvailableStock = computed(() => {
    if (!selectedProductStock.value || !editedItem.value.fabric_type) return 0;
    const inCart = props.items.reduce((acc, item, idx) => item.fabric_type === editedItem.value.fabric_type && idx !== editedItemIndex.value ? acc + (item.quantity || 0) : acc, 0);
    return selectedProductStock.value - inCart;
});
const stockPercentage = computed(() => {
    const total = selectedProductStock.value || 1;
    const current = editedItem.value.quantity || 0;
    return Math.min((current / total) * 100, 100);
});

const formatCurrency = (value: number | null | undefined, currency = 'BRL', digits = 2) => {
  if (value == null) return currency === 'BRL' ? 'R$ 0,00' : '0';
  const options: any = { minimumFractionDigits: digits, maximumFractionDigits: digits };
  if(currency) { options.style = 'currency'; options.currency = currency; }
  return new Intl.NumberFormat('pt-BR', options).format(value);
};
const getStockUsageColor = (qty: number, avail: number) => (avail < 0 || qty > avail) ? 'error' : (qty > avail * 0.8 ? 'warning' : 'success');

// ACTIONS
const prepareNewItem = async () => {
  editedItem.value = createNewItem(); editedItemIndex.value = null; isUploadingNewStamp.value = false; overridePrice.value = false; tempMeters.value = null;
  await nextTick(); itemFormRef.value?.resetValidation();
};

const editItem = (index: number) => {
  editedItemIndex.value = index;
  const itemData = toRaw(props.items[index]);

  const product = props.products.find(p => p.nome === itemData.fabric_type);
  if (product) {
      const defaultPrice = parseFloat(product.valor_venda) || 0;
      overridePrice.value = Number(itemData.valor_unitario) !== defaultPrice;
  } else {
      overridePrice.value = !!itemData.valor_unitario;
  }

  editedItem.value = JSON.parse(JSON.stringify(itemData));
  isUploadingNewStamp.value = false;

  if (mobile.value) {
      showMobileList.value = false;
      appStore.showSnackbar('Item carregado para edição', 'info');
  }
};

const cloneItem = (index: number) => {
    const originalItem = props.items[index];
    if (!originalItem) return;

    const cloned = JSON.parse(JSON.stringify(originalItem));
    cloned.id = Date.now();
    cloned.status = 'design_pending';

    const newItems = [...props.items];
    newItems.splice(index + 1, 0, cloned);

    emit('update:items', newItems);
    appStore.showSnackbar('Item clonado com sucesso!', 'success');
};

const removeItem = (index: number) => {
  const newItems = [...props.items]; newItems.splice(index, 1); emit('update:items', newItems);
  if (editedItemIndex.value === index) prepareNewItem();
};

const saveOrUpdateItem = async () => {
  const errors = [];
  if (!editedItem.value.fabric_type) errors.push("Tecido");
  if (!editedItem.value.quantity) errors.push("Quantidade");
  if (!editedItem.value.stamp_ref_id) errors.push("Estampa/Arte");

  if (errors.length > 0) {
      appStore.showSnackbar(`Preencha os campos obrigatórios: ${errors.join(", ")}`, 'warning');
      return;
  }

  if (itemFormRef.value) {
      const { valid } = await itemFormRef.value.validate();
      if (!valid) return;
  }

  if (!editedItem.value.valor_unitario || editedItem.value.valor_unitario <= 0) {
      showZeroPriceModal.value = true; return;
  }

  const freshProduct = props.products.find(p => p.nome === editedItem.value.fabric_type);
  if (freshProduct) {
      editedItem.value.unit_of_measure = (freshProduct.unidade || freshProduct.unit_of_measure || 'm').toLowerCase();
      const r = parseFloat(freshProduct.rendimento || '0');
      editedItem.value.rendimento = isNaN(r) ? 0 : r;
  }

  if (editedItem.value.unit_of_measure === 'kg' && editedItem.value.rendimento && editedItem.value.quantity) {
      const calc = editedItem.value.quantity * editedItem.value.rendimento;
      editedItem.value.quantity_meters = parseFloat(calc.toFixed(2));
  } else if (editedItem.value.quantity) {
      editedItem.value.quantity_meters = editedItem.value.quantity;
  }

  editedItem.value.has_insufficient_stock = false;
  editedItem.value.status = editedItem.value.is_ready_for_billing ? 'completed' : 'design_pending';

  const rawItem = JSON.parse(JSON.stringify(toRaw(editedItem.value)));
  const newItems = [...props.items];
  if (isEditing.value && editedItemIndex.value !== null) newItems[editedItemIndex.value] = rawItem;
  else newItems.push(rawItem);

  emit('update:items', newItems);
  await prepareNewItem();

  nextTick(() => {
      const leftPanel = document.getElementById('left-form-panel');
      if (leftPanel) {
          leftPanel.scrollTo({ top: 0, behavior: 'smooth' });
      }
  });
};

const handleStampSelection = (stamp: any) => {
  if (!stamp) return;
  editedItem.value.stamp_ref_id = stamp.id;
  editedItem.value.stamp_ref = stamp.nome;
  editedItem.value.stamp_image_url = stamp.image_url || stamp.imagem_url;
  showStampCatalog.value = false;
};

const clearStamp = () => {
    editedItem.value.stamp_ref_id = null;
    editedItem.value.stamp_ref = '';
    editedItem.value.stamp_image_url = null;
};

const handleNewStampFileChange = (event: Event) => {
  const file = (event.target as HTMLInputElement).files?.[0];
  if (file) { editedItem.value.new_stamp_file = file; editedItem.value.stamp_image_url = URL.createObjectURL(file); }
};

const uploadAndRegisterNewStamp = async () => {
  isUploadingStampInProgress.value = true;
  try {
     const file = editedItem.value.new_stamp_file;
     const path = `public/${Date.now()}-${file.name.replace(/\s/g, '_')}`;
     await supabase.storage.from('stamp-library').upload(path, file);
     const { data } = supabase.storage.from('stamp-library').getPublicUrl(path);

     const { data: newStampData, error } = await supabase.from('stamp_library').insert({
         name: editedItem.value.stamp_ref,
         image_url: data.publicUrl,
         is_approved_for_sale: true,
         gestao_click_service_id: String(Date.now()) // CORREÇÃO: ID Fake para bypass da tabela
     }).select().single();

     if (error) throw error;

     handleStampSelection({ id: newStampData.id, nome: newStampData.name, imagem_url: data.publicUrl });
     isUploadingNewStamp.value = false;
     appStore.showSnackbar('Estampa cadastrada!', 'success');
  } catch (e: any) { appStore.showSnackbar(e.message, 'error'); }
  finally { isUploadingStampInProgress.value = false; }
};

const toggleStampUpload = () => {
    isUploadingNewStamp.value = !isUploadingNewStamp.value;
    if(isUploadingNewStamp.value) clearStamp();
};

const focusSearch = () => {
    if (searchFieldRef.value) searchFieldRef.value.focus();
};
defineExpose({ focusSearch });

// Watchers
watch(() => editedItem.value.fabric_type, (productName) => {
  const product = props.products.find(p => p.nome === productName);
  if (product) {
      if (!overridePrice.value) {
          editedItem.value.valor_unitario = parseFloat(product.valor_venda) || 0;
      }
      editedItem.value.unit_of_measure = (product.unidade || product.unit_of_measure || 'm').toLowerCase();
      const r = parseFloat(product.rendimento || '0');
      editedItem.value.rendimento = isNaN(r) ? 0 : r;
  }
});

watch(tempMeters, (v) => {
    if (selectedProductUnit.value === 'kg' && selectedProductRendimento.value && v) {
        const calcKg = parseFloat((v / selectedProductRendimento.value).toFixed(2));
        editedItem.value.quantity = calcKg;
    }
});

watch(() => editedItem.value.quantity, (v) => {
    if (selectedProductUnit.value === 'kg' && selectedProductRendimento.value && v) {
        const calcM = parseFloat((v * selectedProductRendimento.value).toFixed(2));
        editedItem.value.quantity_meters = calcM;
    } else if (selectedProductUnit.value !== 'kg') {
        editedItem.value.quantity_meters = v;
    }
});

watch(() => editedItem.value.is_ready_for_billing, (v) => { if (v) editedItem.value.stamp_ref_id = PRONTA_ENTREGA_STAMP_ID; });

watch(overridePrice, (isOverridden) => {
    if (!isOverridden && editedItem.value.fabric_type) {
        const product = props.products.find(p => p.nome === editedItem.value.fabric_type);
        if (product) {
            editedItem.value.valor_unitario = parseFloat(product.valor_venda) || 0;
        }
    }
});

onMounted(() => { console.warn('🚀 [OrderItemManager] PRONTO'); });

</script>

<style scoped lang="scss">
/* MANTÉM OS ESTILOS ORIGINAIS DO ORDER ITEM MANAGER AQUI */
.glass-card { backdrop-filter: blur(12px) saturate(150%); background-color: rgba(17, 17, 17, 0.3); border: 1px solid rgba(255, 255, 255, 0.1); border-radius: 16px; }
.bg-glass-light { background-color: rgba(255, 255, 255, 0.05); }
.bg-glass-darker { background-color: rgba(0, 0, 0, 0.2); }
.border-white-10 { border-color: rgba(255, 255, 255, 0.1) !important; }
.border-grey-lighten-2 { border-color: #E0E0E0 !important; }
.shadow-soft { box-shadow: 0 4px 14px rgba(0,0,0,0.1); }
.shadow-sm { box-shadow: 0 1px 3px rgba(0,0,0,0.08); }

.lh-1 { line-height: 1; }
.h-16 { height: 16px; } .h-24 { height: 24px; } .h-20 { height: 20px; }
.absolute { position: absolute; } .relative { position: relative; } .inset-0 { inset: 0; }
.top-3 { top: 12px; } .right-3 { right: 12px; } .bottom-0 { bottom: 0; } .left-0 { left: 0; }
.hover-bg-subtle:hover { background-color: rgba(128,128,128,0.05); }
.shadow-text { text-shadow: 0 2px 4px rgba(0,0,0,0.8); }
.row-gap-2 { row-gap: 8px; }
.mb-20 { margin-bottom: 80px; }
.max-w-100 { max-width: 100%; }

.icon-box-sm { width: 36px; height: 36px; }
.icon-circle-lg { width: 64px; height: 64px; border-radius: 50%; display: flex; align-items: center; justify-content: center; }
.stamp-hero-container { border-width: 2px; transition: all 0.3s ease; &.has-image { border-style: solid; border-width: 0; } }
.bg-gradient-to-t { background: linear-gradient(to top, rgba(0,0,0,0.85) 0%, rgba(0,0,0,0.4) 50%, transparent 100%); }
.input-label { font-size: 10px; font-weight: 800; text-transform: uppercase; letter-spacing: 0.5px; opacity: 0.7; margin-bottom: 4px; display: block; }

.grid-items-layout {
    display: grid;
    grid-template-columns: 28px 44px 2.5fr 1.5fr 1fr 1.2fr 1.2fr 60px 75px;
    align-items: stretch;
    width: 100%;
}

.grid-header { z-index: 10; border-bottom: 1px solid rgba(0,0,0,0.08); }
.grid-row { border-bottom: 1px solid rgba(0,0,0,0.06); }
.grid-row:nth-child(even) { background-color: rgba(0, 0, 0, 0.015); }
.cell { padding: 4px 6px; display: flex; align-items: center; border-right: 1px solid rgba(0,0,0,0.05); font-size: 11px; min-width: 0; }
.cell:last-child { border-right: none; }
.header-text { padding: 8px 6px; font-size: 9px; font-weight: 900; text-transform: uppercase; letter-spacing: 0.5px; display: flex; align-items: center; }
.cell.center, .cell.center { justify-content: center; text-align: center; }
.cell.right, .cell.right { justify-content: flex-end; text-align: right; }

.grid-surface-light { background: #f5f7fa; color: #555; }
.grid-surface-dark { background: rgba(255,255,255,0.08); color: #ccc; }
.grid-row-light { background: #fff; }
.grid-row-dark { background: rgba(255,255,255,0.04); }
.grid-selected { background: #e8f5e9 !important; border-left: 4px solid #2e7d32; }
.hover-bg-row:hover { background-color: rgba(128,128,128,0.05); cursor: pointer; }

.action-btn { width: 22px !important; height: 22px !important; border-radius: 4px !important; color: #fff !important; margin: 0 1px; }
.action-edit { background: #ff9900 !important; }
.action-clone { background: #199201 !important; }
.action-del { background: #c62828 !important; }

.pulse-alert-icon { position: absolute; top: -8px; right: -8px; font-size: 18px !important; animation: bounce-pulse-icon 1.5s infinite; filter: drop-shadow(0px 2px 4px rgba(0,0,0,0.5)); z-index: 5; }
@keyframes bounce-pulse-icon { 0% { transform: translateY(0) scale(1); opacity: 0.6; } 50% { transform: translateY(-4px) scale(1.15); opacity: 1; } 100% { transform: translateY(0) scale(1); opacity: 0.6; } }

.row-out-of-stock { animation: pulse-red-bg 2.5s infinite !important; border-left: 3px solid rgba(244, 67, 54, 0.6) !important; }
@keyframes pulse-red-bg { 0% { background-color: rgba(244, 67, 54, 0.05); } 50% { background-color: rgba(244, 67, 54, 0.18); } 100% { background-color: rgba(244, 67, 54, 0.05); } }

.grid-scroll { overflow-x: hidden; overflow-y: auto; }
.smooth-scroll { scroll-behavior: smooth; }

.custom-scrollbar::-webkit-scrollbar, .custom-scroll::-webkit-scrollbar { width: 6px; height: 6px; }
.custom-scrollbar::-webkit-scrollbar-track, .custom-scroll::-webkit-scrollbar-track { background: transparent; }
.custom-scrollbar::-webkit-scrollbar-thumb, .custom-scroll::-webkit-scrollbar-thumb { background: rgba(0,0,0,0.15); border-radius: 3px; }
.custom-scrollbar:hover::-webkit-scrollbar-thumb, .custom-scroll:hover::-webkit-scrollbar-thumb { background: rgba(0,0,0,0.25); }

:deep(.v-field__outline) { --v-field-border-opacity: 0.15; }
:deep(.v-field--focused .v-field__outline) { --v-field-border-opacity: 0.8; }
:deep(.v-field__input) { min-height: 40px !important; padding-top: 8px !important; padding-bottom: 8px !important; font-size: 13px; }
</style>
