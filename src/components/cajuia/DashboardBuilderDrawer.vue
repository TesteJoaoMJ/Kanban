<template>
  <v-navigation-drawer
    v-model="isOpen"
    location="right"
    temporary
    width="1100"
    class="glass-drawer elevation-24"
    scrim="rgba(0,0,0,0.6)"
    floating
  >
    <div class="d-flex flex-column h-100 relative overflow-hidden bg-transparent">

      <div class="drawer-glow" :class="newWidget.gradient"></div>

      <div class="drawer-header px-8 py-6 border-b border-white-10 d-flex align-center justify-space-between relative z-10">
         <div class="d-flex align-center gap-4">
            <div class="header-icon-box rounded-xl elevation-5 d-flex align-center justify-center" :class="editingWidgetId ? 'bg-warning-gradient' : 'bg-primary-gradient'">
               <v-icon color="white" size="28">
                  {{ editingWidgetId ? 'mdi-pencil-box' : 'mdi-view-dashboard-edit' }}
               </v-icon>
            </div>
            <div>
               <div class="d-flex align-center gap-2 mb-1">
                  <span class="text-overline font-weight-bold text-white-70 letter-spacing-2">
                      {{ editingWidgetId ? 'MODO DE EDIÇÃO' : 'CONSTRUTOR DE DASHBOARD' }}
                  </span>
               </div>
               <h2 class="text-h4 font-weight-black text-white lh-1 text-shadow">
                  {{ editingWidgetId ? 'Editar Indicador' : 'Novo Widget' }}
               </h2>
            </div>
         </div>

         <v-btn icon variant="text" color="white" class="hover-glow" @click="close">
            <v-icon size="28">mdi-close</v-icon>
         </v-btn>
      </div>

      <div class="px-8 pt-6 pb-2 flex-shrink-0 relative z-10">
         <div class="glass-pill-tabs p-1 rounded-xl d-flex border border-white-10 bg-white-05">
            <div
                class="tab-item flex-1-1 text-center py-2 rounded-lg cursor-pointer transition-all"
                :class="{ 'active-tab elevation-5': activeTab === 'create' }"
                @click="activeTab = 'create'"
            >
                <span class="text-caption font-weight-bold text-uppercase letter-spacing-1" :class="activeTab === 'create' ? 'text-white' : 'text-white-50'">
                    <v-icon start size="small" class="mr-1">mdi-tune</v-icon> Configurar
                </span>
            </div>
            <div
                class="tab-item flex-1-1 text-center py-2 rounded-lg cursor-pointer transition-all"
                :class="{ 'active-tab elevation-5': activeTab === 'layout', 'opacity-50 pointer-events-none': !!editingWidgetId }"
                @click="!editingWidgetId && (activeTab = 'layout')"
            >
                <span class="text-caption font-weight-bold text-uppercase letter-spacing-1" :class="activeTab === 'layout' ? 'text-white' : 'text-white-50'">
                    <v-icon start size="small" class="mr-1">mdi-view-grid</v-icon> Organizar
                </span>
            </div>
         </div>
      </div>

      <v-window v-model="activeTab" class="flex-grow-1 overflow-hidden bg-transparent relative z-10 h-100">

        <v-window-item value="create" class="h-100">
            <div class="d-flex flex-column h-100">

                <div v-if="!editingWidgetId" class="px-8 py-5 border-b border-white-05 flex-shrink-0">
                    <div class="d-flex align-center justify-space-between mb-3">
                        <span class="text-caption font-weight-bold text-white-50 text-uppercase pl-1">Modelos Rápidos</span>
                    </div>
                    <div class="d-flex gap-4 overflow-x-auto pb-2 custom-scrollbar hide-scrollbar-track">
                        <div
                            v-for="(tpl, i) in templates" :key="i"
                            class="template-card cursor-pointer pa-4 rounded-xl border border-white-10 d-flex flex-column align-start justify-space-between transition-all hover-scale relative overflow-hidden"
                            @click="applyTemplate(tpl)"
                        >
                            <div class="absolute-glow-bg" :class="tpl.gradient_bg"></div>
                            <div class="d-flex align-center justify-space-between w-100 mb-2 relative z-10">
                                <div class="template-icon rounded-lg d-flex align-center justify-center shadow-lg" :class="tpl.gradient_bg">
                                    <v-icon size="20" color="white">{{ tpl.icon }}</v-icon>
                                </div>
                                <v-icon size="18" color="white-50">mdi-arrow-right</v-icon>
                            </div>
                            <div class="relative z-10">
                                <div class="text-subtitle-2 font-weight-bold text-white lh-1 mb-1">{{ tpl.label }}</div>
                                <div class="text-[10px] text-white-70 lh-1">{{ tpl.desc }}</div>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="d-flex flex-grow-1 h-100 overflow-hidden">

                    <div class="w-60 pa-8 overflow-y-auto custom-scrollbar pr-6 h-100">
                        <v-form ref="createForm" @submit.prevent="saveWidget">

                            <div class="form-section mb-8">
                                <div class="d-flex align-center justify-space-between mb-4">
                                    <div class="d-flex align-center gap-3">
                                        <div class="step-number">1</div>
                                        <span class="text-subtitle-2 font-weight-bold text-white">Fonte de Dados</span>
                                    </div>
                                </div>

                                <div class="glass-input-group pa-1 rounded-xl border border-white-10 bg-white-02">
                                    <v-select
                                        v-model="newWidget.source"
                                        :items="friendlySources"
                                        item-title="label"
                                        item-value="value"
                                        variant="solo" density="comfortable"
                                        class="glass-select mb-1"
                                        placeholder="Selecione a origem..."
                                        hide-details
                                        menu-icon="mdi-chevron-down"
                                        @update:model-value="onSourceChange"
                                    >
                                        <template #prepend-inner>
                                            <v-icon color="primary" class="ml-2 opacity-80">mdi-database</v-icon>
                                        </template>
                                    </v-select>

                                    <div class="d-flex border-t border-white-05">
                                        <v-select
                                            v-model="newWidget.operation"
                                            :items="operationOptions"
                                            item-title="label"
                                            item-value="value"
                                            variant="solo" density="compact"
                                            class="glass-select w-50 border-r border-white-05"
                                            hide-details
                                            prefix="Cálculo:"
                                        ></v-select>
                                        <v-select
                                            v-if="newWidget.operation !== 'count'"
                                            v-model="newWidget.column"
                                            :items="currentColumnOptions"
                                            item-title="label"
                                            item-value="value"
                                            variant="solo" density="compact"
                                            class="glass-select w-50"
                                            hide-details
                                            prefix="Campo:"
                                            no-data-text="Selecione a fonte"
                                        ></v-select>
                                    </div>
                                </div>
                            </div>

                            <div class="form-section mb-8">
                                <div class="d-flex align-center justify-space-between mb-4">
                                    <div class="d-flex align-center gap-3">
                                        <div class="step-number">2</div>
                                        <span class="text-subtitle-2 font-weight-bold text-white">Visualização</span>
                                    </div>
                                </div>

                                <div class="mb-4">
                                    <v-text-field
                                        v-model="newWidget.title"
                                        placeholder="Título do Widget (Ex: Faturamento)"
                                        variant="outlined"
                                        color="primary"
                                        bg-color="rgba(255,255,255,0.03)"
                                        class="rounded-lg"
                                        hide-details
                                    ></v-text-field>
                                </div>

                                <div class="visual-grid d-flex gap-4 mb-4">
                                    <div
                                        v-for="type in ['kpi', 'list', 'chart']" :key="type"
                                        class="visual-card flex-1-1 pa-4 rounded-xl border border-white-10 text-center cursor-pointer transition-all position-relative overflow-hidden"
                                        :class="{ 'active-visual border-primary': newWidget.type === type }"
                                        @click="newWidget.type = type"
                                    >
                                        <div class="active-check" v-if="newWidget.type === type"><v-icon size="10" color="white">mdi-check</v-icon></div>
                                        <v-icon size="24" class="mb-2" :color="newWidget.type === type ? 'primary' : 'white-50'">
                                            {{ type === 'kpi' ? 'mdi-numeric-9-plus-box' : (type === 'list' ? 'mdi-format-list-bulleted' : 'mdi-chart-bar') }}
                                        </v-icon>
                                        <div class="text-caption font-weight-bold text-white text-uppercase">{{ type === 'kpi' ? 'Número' : (type === 'list' ? 'Lista' : 'Gráfico') }}</div>
                                    </div>
                                </div>

                                <div class="glass-well pa-4 rounded-xl border border-white-05 bg-white-02">
                                    <v-row dense>
                                        <v-col cols="6">
                                            <span class="text-caption text-white-50 font-weight-bold ml-1">Formato</span>
                                            <v-select v-model="newWidget.format" :items="formatOptions" item-title="label" item-value="value" variant="outlined" density="compact" bg-color="rgba(0,0,0,0.2)" hide-details class="mt-1"></v-select>
                                        </v-col>
                                        <v-col cols="6">
                                            <span class="text-caption text-white-50 font-weight-bold ml-1">Tamanho</span>
                                            <v-select v-model="newWidget.cols" :items="colsOptions" item-title="label" item-value="value" variant="outlined" density="compact" bg-color="rgba(0,0,0,0.2)" hide-details class="mt-1"></v-select>
                                        </v-col>
                                        <v-col cols="12" class="mt-2">
                                            <div class="d-flex justify-space-between mb-1">
                                                <span class="text-caption text-white-50 font-weight-bold ml-1">Altura Personalizada</span>
                                                <span class="text-caption text-primary font-weight-bold">{{ newWidget.height || 'Auto' }} px</span>
                                            </div>
                                            <v-slider v-model="newWidget.height" min="140" max="600" step="20" hide-details color="primary" track-color="rgba(255,255,255,0.1)" thumb-size="12"></v-slider>
                                        </v-col>
                                    </v-row>
                                </div>

                                <div class="mt-4">
                                    <span class="text-caption text-white-50 font-weight-bold ml-1 d-block mb-2">Personalização</span>
                                    <div class="d-flex align-center gap-4">

                                        <v-menu location="top start" :close-on-content-click="false">
                                            <template v-slot:activator="{ props }">
                                                <div v-bind="props" class="style-trigger rounded-xl border border-white-10 px-3 py-2 d-flex align-center gap-3 cursor-pointer hover-bg-white-05">
                                                    <div class="preview-circle" :class="newWidget.gradient"></div>
                                                    <span class="text-caption text-white font-weight-bold">Cor</span>
                                                    <v-icon size="14" color="white-50">mdi-chevron-up</v-icon>
                                                </div>
                                            </template>
                                            <div class="glass-menu-content pa-3 d-flex gap-2 flex-wrap mw-200 rounded-xl border border-white-10 elevation-10">
                                                <div v-for="grad in gradientOptions" :key="grad.value" class="color-circle cursor-pointer border-white-10 transition-transform hover-scale" :class="[grad.value, { 'ring-active': newWidget.gradient === grad.value }]" @click="newWidget.gradient = grad.value"></div>
                                            </div>
                                        </v-menu>

                                        <v-menu location="top start" :close-on-content-click="false">
                                            <template v-slot:activator="{ props }">
                                                <div v-bind="props" class="style-trigger rounded-xl border border-white-10 px-3 py-2 d-flex align-center gap-3 cursor-pointer hover-bg-white-05">
                                                    <v-icon size="18" color="white">{{ newWidget.icon }}</v-icon>
                                                    <span class="text-caption text-white font-weight-bold">Ícone</span>
                                                    <v-icon size="14" color="white-50">mdi-chevron-up</v-icon>
                                                </div>
                                            </template>
                                            <div class="glass-menu-content pa-3 d-grid-icons mw-300 rounded-xl border border-white-10 elevation-10">
                                                <div v-for="icon in iconOptions" :key="icon" class="icon-selector rounded-lg border border-white-10 cursor-pointer d-flex align-center justify-center transition-all bg-white-05" :class="{ 'selected bg-primary border-primary': newWidget.icon === icon }" @click="newWidget.icon = icon">
                                                    <v-icon size="16" color="white">{{ icon }}</v-icon>
                                                </div>
                                            </div>
                                        </v-menu>

                                    </div>
                                </div>

                            </div>

                            <div class="form-section mb-6">
                                <div class="d-flex align-center justify-space-between mb-4">
                                    <div class="d-flex align-center gap-3">
                                        <div class="step-number">3</div>
                                        <span class="text-subtitle-2 font-weight-bold text-white">Filtros</span>
                                    </div>
                                    <v-btn size="small" color="white" variant="tonal" prepend-icon="mdi-plus" @click="addFilter" class="text-none">Adicionar</v-btn>
                                </div>

                                <div v-if="newWidget.filters.length > 0" class="glass-well pa-3 rounded-xl border border-white-05 bg-white-02">
                                    <transition-group name="list" tag="div">
                                        <div v-for="(filter, i) in newWidget.filters" :key="i" class="d-flex gap-2 align-center mb-2 last-mb-0">
                                            <v-select
                                                v-model="filter.column"
                                                :items="currentColumnOptions"
                                                item-title="label"
                                                item-value="value"
                                                density="compact"
                                                variant="solo"
                                                bg-color="rgba(0,0,0,0.3)"
                                                hide-details
                                                class="glass-solo-input w-40 text-[11px]"
                                                placeholder="Campo"
                                            >
                                                <template #selection="{ item }">
                                                    <span class="text-truncate">{{ item.title }}</span>
                                                </template>
                                            </v-select>
                                            <v-select v-model="filter.operator" :items="operatorOptions" item-title="label" item-value="value" density="compact" variant="solo" bg-color="rgba(0,0,0,0.3)" hide-details class="glass-solo-input w-25 text-[11px]"></v-select>
                                            <v-text-field v-model="filter.value" placeholder="Valor" density="compact" variant="solo" bg-color="rgba(0,0,0,0.3)" hide-details class="glass-solo-input flex-grow-1 text-[11px]"></v-text-field>
                                            <v-btn icon size="x-small" variant="text" color="error" @click="removeFilter(i)"><v-icon>mdi-close</v-icon></v-btn>
                                        </div>
                                    </transition-group>
                                </div>
                                <div v-else class="text-center py-6 border dashed border-white-10 rounded-xl">
                                    <div class="text-caption text-white-30">Nenhum filtro aplicado.</div>
                                </div>
                            </div>

                        </v-form>
                    </div>

                    <div class="w-40 bg-glass-darker border-l border-white-10 d-flex flex-column align-center justify-center relative pa-6 overflow-hidden h-100">
                         <div class="grid-pattern absolute-full opacity-10"></div>

                         <div class="d-flex align-center justify-space-between w-100 px-4 mb-6 relative z-10" style="max-width: 320px">
                             <span class="text-overline font-weight-bold text-white-50">VISÃO PREVIA</span>
                             <div class="d-flex align-center gap-2">
                                <v-progress-circular v-if="loadingPreview" indeterminate size="12" width="2" color="warning"></v-progress-circular>
                                <span class="text-[10px] font-weight-bold" :class="loadingPreview ? 'text-warning' : 'text-success'">
                                    {{ loadingPreview ? 'Sincronizando...' : 'Dados Reais' }}
                                </span>
                             </div>
                         </div>

                         <div class="preview-stage relative z-10 perspective-3d w-100 d-flex justify-center">
                            <div class="glass-card pa-5 position-relative overflow-hidden kpi-card w-100 elevation-20 transition-all border border-white-10"
                                 :style="{ maxWidth: '320px', height: newWidget.height ? newWidget.height + 'px' : 'auto', minHeight: '160px' }">

                                <div class="absolute-bg-icon" :class="newWidget.gradient">
                                    <v-icon>{{ newWidget.icon }}</v-icon>
                                </div>

                                <div class="d-flex justify-space-between mb-4 relative z-10">
                                    <div class="d-flex align-center gap-3 overflow-hidden">
                                       <div class="icon-avatar rounded-lg d-flex align-center justify-center elevation-5 flex-shrink-0" :class="newWidget.gradient">
                                           <v-icon size="18" color="white">{{ newWidget.icon }}</v-icon>
                                       </div>
                                       <span class="text-caption text-white font-weight-bold text-uppercase letter-spacing-1 text-truncate">
                                           {{ newWidget.title || 'Sem Título' }}
                                       </span>
                                    </div>
                                    <v-chip v-if="newWidget.type === 'kpi'" size="x-small" color="success" variant="flat" class="font-weight-bold h-20 px-2 flex-shrink-0">
                                        <v-icon start size="10">mdi-arrow-up</v-icon> +4%
                                    </v-chip>
                                </div>

                                <div v-if="newWidget.type === 'kpi'" class="d-flex align-end relative z-10 h-100 pb-4">
                                    <h2 class="text-h4 font-weight-black text-white kpi-value text-shadow-lg lh-1 text-truncate w-100">
                                        {{ formatValue(previewData.value, newWidget.format) }}
                                    </h2>
                                </div>

                                <div v-else-if="newWidget.type === 'list'" class="relative z-10 h-100 overflow-hidden d-flex flex-column">
                                    <div class="d-flex justify-space-between py-2 border-b border-white-10 text-[10px] text-white-50 text-uppercase font-weight-bold">
                                        <span>Nome</span><span>Valor</span>
                                    </div>
                                    <div class="flex-grow-1 overflow-hidden mt-2">
                                         <div v-for="(item, idx) in previewData.list" :key="idx" class="d-flex justify-space-between py-2 text-caption text-white border-b border-white-05 align-center">
                                            <div class="d-flex align-center gap-2 text-truncate pr-2">
                                                <div class="text-[10px] text-white-30 font-mono">#{{idx+1}}</div>
                                                <span class="text-truncate font-weight-medium">{{ item.label || 'Item ' + idx }}</span>
                                            </div>
                                            <span class="font-weight-bold bg-white-10 px-2 rounded text-[10px] flex-shrink-0">{{ formatValue(item.value, newWidget.format) }}</span>
                                         </div>
                                         <div v-if="!previewData.list?.length" class="text-[10px] text-white-30 text-center mt-4">Sem dados</div>
                                    </div>
                                </div>

                                 <div v-else-if="newWidget.type === 'chart'" class="relative z-10 w-100 d-flex align-end justify-space-between h-100 pb-2 gap-1 px-2">
                                    <div v-for="(bar, idx) in previewData.chart || [30, 50, 40, 70, 45]" :key="idx"
                                         class="rounded-t-sm transition-all"
                                         :class="idx === 2 ? newWidget.gradient : 'bg-white-10'"
                                         :style="{ width: '15%', height: (typeof bar === 'number' ? bar : 40) + '%', opacity: idx === 2 ? 1 : 0.5 }">
                                    </div>
                                </div>

                            </div>
                         </div>
                    </div>
                </div>
            </div>
        </v-window-item>

        <v-window-item value="layout" class="h-100">
            <div class="pa-8 h-100 d-flex flex-column overflow-y-auto custom-scrollbar">
               <div class="glass-alert pa-4 rounded-xl border border-white-10 mb-6 d-flex align-center gap-4 bg-info-gradient-soft flex-shrink-0">
                   <v-icon color="white">mdi-drag-variant</v-icon>
                   <div>
                       <div class="font-weight-bold text-white text-subtitle-2">Organização Visual</div>
                       <div class="text-caption text-white-70">Arraste para mudar a posição. Use o switch para ocultar.</div>
                   </div>
               </div>

               <draggable
                v-model="store.widgets"
                item-key="id"
                handle=".drag-handle-zone"
                @end="store.saveLayout"
                class="d-flex flex-column gap-3 position-relative pb-10 flex-grow-1"
                animation="300"
              >
                <template #item="{ element }">
                  <div class="layout-item glass-surface pa-3 rounded-xl d-flex align-center justify-space-between transition-all border border-white-05 hover-border-primary relative overflow-hidden group">
                    <div class="absolute-left-marker" :class="element.config.gradient || 'bg-white-10'"></div>

                    <div class="d-flex align-center flex-grow-1 overflow-hidden gap-4 pl-4">
                      <div class="drag-handle-zone cursor-move d-flex align-center justify-center p-2 rounded hover-bg-white-10 text-white-30 hover:text-white transition-colors">
                          <v-icon>mdi-drag-vertical</v-icon>
                      </div>

                      <div class="layout-icon-box rounded-lg d-flex align-center justify-center" :class="element.config.gradient">
                        <v-icon size="18" color="white">
                            {{ element.config.icon || (element.type === 'chart' ? 'mdi-chart-box' : 'mdi-numeric') }}
                        </v-icon>
                      </div>

                      <div class="text-truncate">
                        <div class="text-subtitle-2 font-weight-bold text-white">{{ element.title }}</div>
                        <div class="d-flex align-center gap-2 mt-0">
                            <v-chip size="x-small" class="font-mono font-weight-bold bg-white-05 text-white-70 border-none">{{ getColLabel(element.cols) }}</v-chip>
                            <span class="text-[10px] text-white-30 text-uppercase font-weight-bold">{{ element.type }}</span>
                        </div>
                      </div>
                    </div>

                    <div class="d-flex align-center gap-2 pr-2">
                      <v-btn icon size="small" variant="text" color="white-70" class="hover:text-white hover-bg-white-10" @click="startEditing(element)"><v-icon>mdi-pencil</v-icon></v-btn>
                      <v-switch v-model="element.visible" color="success" density="compact" hide-details inset class="scale-08 ml-2" @change="store.saveLayout"></v-switch>
                      <v-divider vertical class="border-white-10 mx-2 h-20"></v-divider>
                      <v-btn icon size="small" variant="text" color="error" class="opacity-50 hover-opacity-100" :disabled="element.config.is_system" @click="store.deleteWidget(element.id)"><v-icon>mdi-trash-can-outline</v-icon></v-btn>
                    </div>
                  </div>
                </template>
              </draggable>
           </div>
        </v-window-item>

      </v-window>

      <div class="drawer-footer px-8 py-5 border-t border-white-10 bg-glass-footer flex-shrink-0 d-flex align-center justify-end gap-4 relative z-20" v-if="activeTab === 'create'">
           <v-btn v-if="editingWidgetId" variant="text" color="white-70" height="48" class="rounded-xl px-6 text-none font-weight-bold" @click="cancelEditing">Cancelar</v-btn>
            <v-btn color="primary" height="48" class="font-weight-bold shadow-glow-primary rounded-xl text-body-2 px-10 text-none letter-spacing-1 bg-primary-gradient border-none" @click="saveWidget" :loading="processing">
                <v-icon start class="mr-2">{{ editingWidgetId ? 'mdi-check' : 'mdi-plus' }}</v-icon>
                {{ editingWidgetId ? 'Salvar Alterações' : 'Criar Widget' }}
            </v-btn>
      </div>

    </div>
  </v-navigation-drawer>
</template>

<script setup lang="ts">
// (MANTIDO O SCRIPT IGUAL - A LÓGICA ESTÁ CORRETA, APENAS AS IMPORTAÇÕES FORAM MANTIDAS POR REFERÊNCIA)
import { ref, reactive, computed, watch, defineComponent, h } from 'vue'
import draggable from 'vuedraggable'
import { useCajuiaDashboardStore } from '@/stores/cajuiaDashboard'
import { debounce } from 'lodash-es'

// TOOLTIP COMPONENT (MANTIDO)
const HelpTooltip = defineComponent({
    props: ['title', 'text'],
    setup(props, { slots }) {
        const show = ref(false)
        return () => h('v-menu', {
            openOnHover: true, location: 'bottom start',
            contentClass: 'glass-tooltip',
            activator: 'parent',
            modelValue: show.value,
            'onUpdate:modelValue': (v:boolean) => show.value = v
        }, {
            activator: ({ props: menuProps }: any) => h('div', {
                ...menuProps,
                class: 'd-flex align-center justify-center rounded-circle border border-white-20 w-6 h-6 cursor-help hover-bg-white-10 transition-all'
            }, [h('v-icon', { size: 14, color: 'primary' }, 'mdi-help')]),
            default: () => h('div', { class: 'pa-4 mw-250' }, [
                h('div', { class: 'font-weight-bold text-white mb-1 text-uppercase text-[11px] letter-spacing-1' }, props.title),
                h('div', { class: 'text-[11px] text-white-70 line-height-14' }, props.text)
            ])
        })
    }
})

const props = defineProps({ modelValue: Boolean })
const emit = defineEmits(['update:modelValue', 'update:layout'])

const store = useCajuiaDashboardStore()
const activeTab = ref('create')
const processing = ref(false)
const editingWidgetId = ref<string | null>(null)
const loadingPreview = ref(false)
const previewData = reactive({ value: 0, list: [] as any[], chart: [] as any[] })

const isOpen = computed({ get: () => props.modelValue, set: (val) => emit('update:modelValue', val) })
const close = () => { isOpen.value = false; cancelEditing(); }

const friendlySources = [
    { label: '🛍️ Vendas & Pedidos', value: 'cajuia_orders' },
    { label: '📦 Estoque de Produtos', value: 'cajuia_products' },
    { label: '👥 Base de Clientes', value: 'cajuia_clients' }
]
const operationOptions = [{ label: 'Somar (Total)', value: 'sum' }, { label: 'Contar (Qtd)', value: 'count' }]
const columnMappings: any = {
    'cajuia_orders': [{ label: 'Valor Total (R$)', value: 'total_value' }, { label: 'Qtd Itens', value: 'quantity' }],
    'cajuia_products': [{ label: 'Valor Estoque (R$)', value: 'total_value' }, { label: 'Qtd Física', value: 'quantity_in_stock' }, { label: 'Preço Venda', value: 'price' }],
    'cajuia_clients': [{ label: 'ID (Contagem)', value: 'id' }]
}
const currentColumnOptions = computed(() => columnMappings[newWidget.source] || [])
const formatOptions = [{ label: 'Dinheiro (R$)', value: 'currency' }, { label: 'Número', value: 'number' }, { label: 'Porcentagem (%)', value: 'percent' }]
const colsOptions = [{ label: 'Pequeno (1/4)', value: 3 }, { label: 'Médio (1/3)', value: 4 }, { label: 'Metade (1/2)', value: 6 }, { label: 'Tela Toda', value: 12 }]
const operatorOptions = [{ label: 'Igual a', value: 'eq' }, { label: 'Diferente', value: 'neq' }, { label: 'Maior que', value: 'gt' }, { label: 'Menor que', value: 'lt' }, { label: 'Contém', value: 'ilike' }]
const iconOptions = ['mdi-cash-multiple', 'mdi-shopping', 'mdi-account-group', 'mdi-chart-line', 'mdi-cube-outline', 'mdi-star-circle', 'mdi-chart-arc', 'mdi-finance', 'mdi-truck-delivery', 'mdi-tag-outline', 'mdi-store', 'mdi-hanger']
const gradientOptions = [
    { value: 'bg-gradient-primary', glow: 'glow-primary' }, { value: 'bg-gradient-success', glow: 'glow-success' },
    { value: 'bg-gradient-warning', glow: 'glow-warning' }, { value: 'bg-gradient-error', glow: 'glow-error' },
    { value: 'bg-gradient-info', glow: 'glow-info' }, { value: 'bg-gradient-purple', glow: 'glow-purple' },
    { value: 'bg-gradient-pink', glow: 'glow-pink' }, { value: 'bg-gradient-teal', glow: 'glow-teal' },
    { value: 'bg-gradient-orange', glow: 'glow-orange' },
]
const templates = [
    { label: 'Vendas Mês', desc: 'Total vendido no mês atual', icon: 'mdi-cash-multiple', gradient_bg: 'bg-gradient-success', data: { title: 'Vendas Mensais', source: 'cajuia_orders', operation: 'sum', column: 'total_value', format: 'currency', type: 'kpi', icon: 'mdi-cash-multiple', gradient: 'bg-gradient-success' } },
    { label: 'Estoque Baixo', desc: 'Itens com menos de 5 un', icon: 'mdi-alert-circle', gradient_bg: 'bg-gradient-warning', data: { title: 'Alerta Estoque', source: 'cajuia_products', operation: 'count', column: 'id', format: 'number', type: 'list', icon: 'mdi-alert-circle', gradient: 'bg-gradient-warning', filters: [{ column: 'quantity_in_stock', operator: 'lt', value: '5' }] } },
    { label: 'Clientes', desc: 'Total da base de contatos', icon: 'mdi-account-group', gradient_bg: 'bg-gradient-info', data: { title: 'Total Clientes', source: 'cajuia_clients', operation: 'count', column: 'id', format: 'number', type: 'kpi', icon: 'mdi-account-group', gradient: 'bg-gradient-info' } }
]
const newWidget = reactive({ title: '', type: 'kpi', cols: 3, height: null as number|null, source: null as string|null, operation: 'sum', column: null as string|null, format: 'number', icon: 'mdi-star', gradient: 'bg-gradient-primary', filters: [] as any[] })

const getColLabel = (cols: number) => { if(cols===3) return '25%'; if(cols===4) return '33%'; if(cols===6) return '50%'; if(cols===12) return '100%'; return `${cols}/12` }
const formatValue = (val: any, type?: string) => { if (val === undefined || val === null) return '-'; if (type === 'currency') return new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL', maximumFractionDigits: 0 }).format(Number(val)); if (type === 'percent') return `${Number(val).toFixed(1)}%`; if (type === 'number') return new Intl.NumberFormat('pt-BR').format(Number(val)); return val }
const onSourceChange = () => { newWidget.column = null; if(currentColumnOptions.value.length > 0) newWidget.column = currentColumnOptions.value[0].value }
const applyTemplate = (tpl: any) => Object.assign(newWidget, tpl.data)
const addFilter = () => newWidget.filters.push({ column: '', operator: 'eq', value: '' })
const removeFilter = (i: number) => newWidget.filters.splice(i, 1)

const startEditing = (widget: any) => { editingWidgetId.value = widget.id; Object.assign(newWidget, { title: widget.title, type: widget.type, cols: widget.cols, source: widget.config?.source, operation: widget.config?.operation || 'sum', column: widget.config?.column, format: widget.config?.format || 'number', icon: widget.config?.icon || 'mdi-star', gradient: widget.config?.gradient || 'bg-gradient-primary', filters: widget.config?.filters ? [...widget.config.filters] : [], height: widget.config?.height || null }); activeTab.value = 'create' }
const cancelEditing = () => { editingWidgetId.value = null; Object.assign(newWidget, { title: '', type: 'kpi', cols: 3, height: null, source: null, operation: 'sum', column: null, format: 'number', icon: 'mdi-star', gradient: 'bg-gradient-primary', filters: [] }); previewData.value = 0; previewData.list = []; previewData.chart = []; activeTab.value = 'layout' }
const saveWidget = async () => { if (!newWidget.title || !newWidget.source) return; processing.value = true; try { const widgetData = { title: newWidget.title, type: newWidget.type, cols: newWidget.cols, config: { source: newWidget.source, operation: newWidget.operation, column: newWidget.column, format: newWidget.format, icon: newWidget.icon, gradient: newWidget.gradient, filters: newWidget.filters, height: newWidget.height } }; if (editingWidgetId.value) { const index = store.widgets.findIndex(w => w.id === editingWidgetId.value); if(index !== -1) { store.widgets[index] = { ...store.widgets[index], ...widgetData }; await store.saveLayout() } } else { await store.createCustomWidget(widgetData) }; emit('update:layout'); cancelEditing() } catch (error) { console.error(error) } finally { processing.value = false } }

const fetchPreview = async () => { if (!newWidget.source) return; loadingPreview.value = true; try { const tempWidget = { id: 'temp', title: 'Preview', type: newWidget.type, cols: 3, visible: true, config: { source: newWidget.source, operation: newWidget.operation, column: newWidget.column, filters: newWidget.filters, list_type: newWidget.type === 'list' ? 'ranking' : undefined, group_col: newWidget.type === 'list' ? 'name' : undefined, agg_col: newWidget.column, limit: 5 }, value: 0, listData: [], series: [] }; await store.processWidgetData(tempWidget as any, store.getDateRange('month')); previewData.value = tempWidget.value || 0; if (newWidget.type === 'list' && tempWidget.listData) { previewData.list = tempWidget.listData.map(item => ({ label: item.name || item.product_name || item.customer_name || `ID: ${item.id}`, value: item._val !== undefined ? item._val : (item[newWidget.column!] || 0) })) } if (newWidget.type === 'chart') { const base = Number(tempWidget.value) || 100; previewData.chart = [base * 0.4, base * 0.8, base * 0.5, base * 1.0, base * 0.6] } } catch (e) { console.error("Preview err:", e) } finally { loadingPreview.value = false } }
const debouncedPreview = debounce(fetchPreview, 800)
watch(() => [newWidget.source, newWidget.operation, newWidget.column, newWidget.filters, newWidget.type], () => { debouncedPreview() }, { deep: true })
</script>

<style scoped lang="scss">
/* GLASS DRAWER & LAYOUT CORE */
:deep(.v-window), :deep(.v-window__container) { height: 100% !important; flex: 1 1 auto; display: flex; flex-direction: column; }
.glass-drawer { background: rgba(20, 20, 25, 0.92) !important; backdrop-filter: blur(30px); border-left: 1px solid rgba(255, 255, 255, 0.1); }

/* MENU CONTENT (A SOLUÇÃO PARA O "INVISÍVEL") */
/* Aplicamos o estilo na div interna do menu para garantir fundo */
.glass-menu-content {
    background: rgba(25, 25, 30, 0.98); /* Fundo quase sólido para legibilidade */
    backdrop-filter: blur(20px);
    border: 1px solid rgba(255,255,255,0.1);
}

/* SCROLLBAR */
.custom-scrollbar { scrollbar-width: thin; scrollbar-color: rgba(255, 255, 255, 0.4) transparent; }
.custom-scrollbar::-webkit-scrollbar { width: 8px; height: 8px; }
.custom-scrollbar::-webkit-scrollbar-thumb { background: rgba(255, 255, 255, 0.3); border-radius: 4px; border: 2px solid transparent; background-clip: content-box; }
.custom-scrollbar::-webkit-scrollbar-thumb:hover { background-color: rgba(255, 255, 255, 0.6); }

/* HEADER & TABS */
.header-icon-box { width: 48px; height: 48px; background: rgba(255,255,255,0.05); }
.bg-primary-gradient { background: linear-gradient(135deg, rgb(var(--v-theme-primary)), #1565c0); }
.bg-warning-gradient { background: linear-gradient(135deg, #ffa726, #f57c00); }
.glass-pill-tabs { background: rgba(0,0,0,0.2); }
.tab-item:hover { background: rgba(255,255,255,0.05); }
.active-tab { background: rgba(255,255,255,0.15); border: 1px solid rgba(255,255,255,0.2); box-shadow: 0 4px 15px rgba(0,0,0,0.2); }

/* INPUTS */
.glass-input-group { background: rgba(255,255,255,0.03); border: 1px solid rgba(255,255,255,0.08); }
.glass-select :deep(.v-field) { box-shadow: none; background: transparent; font-size: 13px; }
.glass-select :deep(.v-field__input) { padding-top: 10px; min-height: 44px; }
.glass-solo-input :deep(.v-field) { border-radius: 8px; box-shadow: none; border: 1px solid rgba(255,255,255,0.1); }

/* STYLE SELECTORS */
.style-trigger { height: 40px; transition: all 0.2s; background: rgba(255,255,255,0.02); }
.style-trigger:hover { background: rgba(255,255,255,0.08); border-color: rgba(255,255,255,0.3); }
.color-circle { width: 36px; height: 36px; border-radius: 50%; border: 2px solid rgba(255,255,255,0.1); }
.preview-circle { width: 14px; height: 14px; border-radius: 50%; box-shadow: 0 0 8px rgba(0,0,0,0.5); }
.ring-active { border-color: white; transform: scale(1.1); box-shadow: 0 0 15px rgba(255,255,255,0.3); }
.icon-selector { width: 44px; height: 44px; transition: all 0.2s; }
.icon-selector:hover { background: rgba(255,255,255,0.1); transform: scale(1.05); }
.icon-selector.selected { background: rgb(var(--v-theme-primary)); border-color: transparent !important; }

/* PREVIEW CARD & GLOWS */
.bg-glass-darker { background: rgba(0,0,0,0.4); }
.kpi-card { background: rgba(30, 30, 35, 0.6); backdrop-filter: blur(24px); border: 1px solid rgba(255,255,255,0.15); box-shadow: 0 25px 60px rgba(0,0,0,0.5); }
.absolute-bg-icon { position: absolute; bottom: -20px; right: -20px; opacity: 0.08; transform: rotate(-10deg); .v-icon { font-size: 180px; } }
.drawer-glow { position: absolute; top: 0; left: 0; width: 100%; height: 300px; opacity: 0.1; pointer-events: none; filter: blur(80px); transition: background 0.5s ease; background: linear-gradient(to bottom, rgb(var(--v-theme-primary)), transparent); &.bg-gradient-success { background: linear-gradient(to bottom, #00c853, transparent); } &.bg-gradient-warning { background: linear-gradient(to bottom, #ffca28, transparent); } &.bg-gradient-error { background: linear-gradient(to bottom, #ef5350, transparent); } &.bg-gradient-info { background: linear-gradient(to bottom, #29b6f6, transparent); } }

/* GRADIENTES */
.bg-gradient-primary { background: linear-gradient(135deg, rgb(var(--v-theme-primary)), #1565c0); }
.bg-gradient-success { background: linear-gradient(135deg, #00c853, #006025); }
.bg-gradient-warning { background: linear-gradient(135deg, #ffca28, #ff6f00); }
.bg-gradient-error { background: linear-gradient(135deg, #ef5350, #c62828); }
.bg-gradient-info { background: linear-gradient(135deg, #29b6f6, #01579b); }
.bg-gradient-purple { background: linear-gradient(135deg, #9c27b0, #4a148c); }
.bg-gradient-pink { background: linear-gradient(135deg, #e91e63, #880e4f); }
.bg-gradient-teal { background: linear-gradient(135deg, #009688, #004d40); }
.bg-gradient-orange { background: linear-gradient(135deg, #ff5722, #bf360c); }

.w-60 { width: 60%; } .w-40 { width: 40%; } .w-50 { width: 50%; } .mw-200 { max-width: 200px; } .mw-250 { max-width: 250px; } .h-20 { height: 20px; } .text-shadow { text-shadow: 0 2px 10px rgba(0,0,0,0.5); } .lh-1 { line-height: 1; } .hover-scale:hover { transform: scale(1.02); }
</style>
