<template>
  <v-dialog v-model="dialog" fullscreen transition="dialog-bottom-transition" class="studio-dialog">
    <div class="studio-layout d-flex flex-column h-100 bg-background text-high-emphasis">

      <header class="studio-header d-flex align-center px-4 border-b bg-surface elevation-1 z-50 flex-shrink-0 justify-space-between">
        <div class="header-left d-flex align-center flex-1">
             <v-btn icon size="small" variant="text" @click="close" class="mr-3">
                <v-icon color="high-emphasis">mdi-arrow-left</v-icon>
             </v-btn>
             <div class="d-flex align-center">
                <v-avatar color="primary" size="36" class="mr-3" variant="tonal">
                    <v-icon size="20">mdi-printer-3d-nozzle</v-icon>
                </v-avatar>
                <div class="d-flex flex-column justify-center" style="height: 36px;">
                    <div class="text-subtitle-1 font-weight-bold lh-1 text-high-emphasis">
                       Gerador de Etiquetas <span class="text-primary font-weight-black">MJProcess</span>
                    </div>
                    <div class="text-caption text-medium-emphasis font-mono mt-1" style="font-size: 11px !important;">
                        {{ config.labelWidth }}x{{ config.labelHeight }}mm • {{ zoom.toFixed(1) }}x
                    </div>
                </div>
             </div>
        </div>

        <div class="header-center d-flex align-center justify-center flex-1">
            <div class="toolbar-center bg-surface-variant rounded-pill px-4 py-1.5 d-flex align-center gap-2 elevation-2 border">
                <v-tooltip text="Selecionar (V)" location="bottom" content-class="bg-inverse-surface text-inverse-on-surface">
                    <template v-slot:activator="{ props }">
                        <button v-bind="props" class="tool-btn" :class="{active: !activeElementId}" @click="activeElementId = null">
                            <v-icon size="20" color="high-emphasis">mdi-cursor-default</v-icon>
                        </button>
                    </template>
                </v-tooltip>

                <div class="divider-v"></div>

                <v-tooltip text="Adicionar Texto (T)" location="bottom" content-class="bg-inverse-surface text-inverse-on-surface">
                    <template v-slot:activator="{ props }">
                        <button v-bind="props" class="tool-btn" @click="addText">
                            <v-icon size="20" color="high-emphasis">mdi-format-text</v-icon>
                        </button>
                    </template>
                </v-tooltip>

                <v-tooltip text="Adicionar Código de Barras (B)" location="bottom" content-class="bg-inverse-surface text-inverse-on-surface">
                    <template v-slot:activator="{ props }">
                        <button v-bind="props" class="tool-btn" @click="addBarcode">
                            <v-icon size="20" color="high-emphasis">mdi-barcode</v-icon>
                        </button>
                    </template>
                </v-tooltip>

                <v-menu location="bottom">
                    <template v-slot:activator="{ props: menuProps }">
                        <v-tooltip text="Adicionar Imagem (I)" location="bottom" content-class="bg-inverse-surface text-inverse-on-surface">
                             <template v-slot:activator="{ props: tooltipProps }">
                                <button v-bind="mergeProps(menuProps, tooltipProps)" class="tool-btn">
                                    <v-icon size="20" color="high-emphasis">mdi-image-plus</v-icon>
                                </button>
                             </template>
                        </v-tooltip>
                    </template>
                    <v-list density="compact" class="elevation-4 bg-surface text-high-emphasis">
                        <v-list-item @click="triggerImageUpload(false)" prepend-icon="mdi-image" title="Imagem Normal"></v-list-item>
                        <v-list-item @click="triggerImageUpload(true)" prepend-icon="mdi-magic-staff" title="Imagem (Sem Fundo)" subtitle="Remove fundo branco"></v-list-item>
                    </v-list>
                </v-menu>

                <div class="divider-v"></div>

                <v-tooltip text="Grade (Grid)" location="bottom" content-class="bg-inverse-surface text-inverse-on-surface">
                    <template v-slot:activator="{ props }">
                        <button v-bind="props" class="tool-btn" :class="{active: showGrid}" @click="showGrid = !showGrid">
                            <v-icon size="20" :color="showGrid ? 'primary' : 'high-emphasis'">mdi-grid</v-icon>
                        </button>
                    </template>
                </v-tooltip>

                <v-tooltip text="Imã (Snapping)" location="bottom" content-class="bg-inverse-surface text-inverse-on-surface">
                    <template v-slot:activator="{ props }">
                        <button v-bind="props" class="tool-btn" :class="{active: snappingEnabled}" @click="snappingEnabled = !snappingEnabled">
                            <v-icon size="20" :color="snappingEnabled ? 'primary' : 'high-emphasis'">mdi-magnet</v-icon>
                        </button>
                    </template>
                </v-tooltip>
            </div>
        </div>

        <input type="file" ref="fileInput" accept="image/*" class="d-none" @change="handleImageUpload" />

        <div class="header-right d-flex align-center justify-end gap-3 flex-1">
            <v-menu v-model="showPresetMenu" :close-on-content-click="false" location="bottom end" transition="slide-y-transition">
                <template v-slot:activator="{ props }">
                    <v-btn v-bind="props" variant="tonal" color="primary" class="text-none font-weight-bold" prepend-icon="mdi-bookmark-multiple-outline">
                        Presets
                    </v-btn>
                </template>
                <v-card width="420" class="elevation-10 border bg-surface">
                    <v-tabs v-model="presetTab" color="primary" density="compact" grow>
                        <v-tab value="user">Meus Presets</v-tab>
                        <v-tab value="system">Modelos Padrão</v-tab>
                    </v-tabs>
                    <v-card-text class="pa-0">
                        <v-window v-model="presetTab">
                            <v-window-item value="user">
                                <div class="pa-3 border-b bg-surface-variant d-flex justify-space-between align-center">
                                    <span class="text-caption font-weight-bold">Gerenciar Presets</span>
                                    <v-btn size="small" color="primary" variant="flat" prepend-icon="mdi-plus" @click="saveNewPreset">Salvar Atual</v-btn>
                                </div>
                                <v-list lines="two" density="compact" class="custom-scrollbar" style="max-height: 300px; overflow-y: auto;">
                                    <v-list-item v-for="(preset, idx) in userPresets" :key="'up'+idx" class="border-b" hover @click="applyPreset(preset)">
                                        <template v-slot:prepend>
                                            <v-avatar color="primary-lighten-4" rounded variant="tonal" size="48" class="mr-3">
                                                <v-icon color="primary">mdi-label-outline</v-icon>
                                            </v-avatar>
                                        </template>
                                        <v-list-item-title class="font-weight-bold text-high-emphasis">{{ preset.name }}</v-list-item-title>
                                        <v-list-item-subtitle class="text-caption mt-1">
                                            {{ preset.config.labelWidth }}x{{ preset.config.labelHeight }}mm • {{ preset.config.cols }}x{{ preset.config.rows }} Grade
                                        </v-list-item-subtitle>
                                        <template v-slot:append>
                                            <v-btn icon="mdi-delete" variant="text" color="error" size="small" @click.stop="deletePreset(idx)"></v-btn>
                                        </template>
                                    </v-list-item>
                                    <div v-if="userPresets.length === 0" class="pa-6 text-center text-medium-emphasis text-caption">Nenhum preset salvo.</div>
                                </v-list>
                            </v-window-item>
                            <v-window-item value="system">
                                <v-list lines="two" density="compact" class="custom-scrollbar" style="max-height: 340px; overflow-y: auto;">
                                    <v-list-item v-for="(tpl, idx) in labelTemplates" :key="'sys'+idx" class="border-b" hover @click="applyTemplate(tpl)">
                                        <template v-slot:prepend>
                                            <v-avatar color="grey-lighten-2" rounded variant="tonal" size="48" class="mr-3">
                                                <v-icon color="medium-emphasis">mdi-printer-pos</v-icon>
                                            </v-avatar>
                                        </template>
                                        <v-list-item-title class="font-weight-bold text-high-emphasis">{{ tpl.name }}</v-list-item-title>
                                        <v-list-item-subtitle class="text-caption mt-1">
                                            {{ tpl.config.labelWidth }}x{{ tpl.config.labelHeight }}mm • Cols: {{ tpl.config.cols }} • Linhas: {{ tpl.config.rows }}
                                        </v-list-item-subtitle>
                                    </v-list-item>
                                </v-list>
                            </v-window-item>
                        </v-window>
                    </v-card-text>
                </v-card>
            </v-menu>

            <v-btn color="primary" variant="flat" class="text-none font-weight-bold px-5" @click="downloadPDF" :loading="isGenerating">
                 <v-icon start>mdi-printer</v-icon> Imprimir
            </v-btn>
        </div>
      </header>

      <div class="studio-body d-flex flex-grow-1 overflow-hidden position-relative">

        <v-fade-transition>
            <div v-if="isLoadingData" class="loading-overlay d-flex flex-column align-center justify-center bg-background z-100" style="backdrop-filter: blur(5px);">
                <v-progress-circular indeterminate color="primary" size="64" width="4" class="mb-6"></v-progress-circular>
                <div class="text-h6 font-weight-bold text-high-emphasis mb-2">Preparando Ambiente...</div>
                <div class="text-body-2 text-medium-emphasis px-4 py-2 bg-surface-variant rounded-pill d-flex align-center">
                    <v-icon size="16" class="mr-2" color="primary">mdi-package-variant-closed</v-icon>
                    {{ sampleProduct.name || 'Carregando dados do produto' }}
                </div>
            </div>
        </v-fade-transition>

        <aside class="sidebar-left d-flex flex-column border-e bg-surface w-280 flex-shrink-0 z-20">
            <div class="sidebar-section config-section d-flex flex-column" style="height: 50%;">
                <div class="panel-header bg-surface-variant px-3 py-2 text-caption font-weight-bold text-high-emphasis border-b">
                    <v-icon size="14" class="mr-2">mdi-cog</v-icon> CONFIGURAÇÃO
                </div>
                <div class="pa-4 overflow-y-auto custom-scrollbar">
                    <div class="control-group mb-4 pa-3 rounded border" style="background-color: rgba(var(--v-theme-surface-variant), 0.3);">
                        <div class="group-title text-primary text-caption font-weight-bold mb-2">IMPRESSÃO</div>
                        <div class="d-grid-2 gap-2">
                             <v-text-field label="Cópias" type="number" v-model.number="printOptions.copies" density="compact" hide-details variant="outlined" min="1" bg-color="surface"></v-text-field>
                             <v-text-field label="Pular Início" type="number" v-model.number="printOptions.start" density="compact" hide-details variant="outlined" min="0" bg-color="surface"></v-text-field>
                        </div>
                    </div>
                    <div class="control-group mb-3">
                        <label class="text-caption text-medium-emphasis mb-1 d-block font-weight-medium">Dimensões (mm)</label>
                        <div class="d-grid-2 gap-2">
                             <v-text-field label="Largura" type="number" v-model.number="config.labelWidth" density="compact" hide-details variant="outlined" suffix="mm"></v-text-field>
                             <v-text-field label="Altura" type="number" v-model.number="config.labelHeight" density="compact" hide-details variant="outlined" suffix="mm"></v-text-field>
                        </div>
                    </div>
                    <div class="control-group mb-3">
                        <label class="text-caption text-medium-emphasis mb-1 d-block font-weight-medium">Margens Folha (mm)</label>
                        <div class="d-grid-2 gap-2">
                             <v-text-field label="Topo" type="number" v-model.number="config.marginTop" density="compact" hide-details variant="outlined"></v-text-field>
                             <v-text-field label="Esq" type="number" v-model.number="config.marginLeft" density="compact" hide-details variant="outlined"></v-text-field>
                        </div>
                    </div>
                    <div class="control-group">
                        <label class="text-caption text-medium-emphasis mb-1 d-block font-weight-medium">Grade (Cols x Rows)</label>
                        <div class="d-grid-2 gap-2">
                             <v-text-field label="Colunas" type="number" v-model.number="config.cols" density="compact" hide-details variant="outlined"></v-text-field>
                             <v-text-field label="Linhas" type="number" v-model.number="config.rows" density="compact" hide-details variant="outlined"></v-text-field>
                        </div>
                    </div>
                </div>
            </div>

            <div class="sidebar-divider d-flex align-center justify-center bg-border"><div class="handle bg-medium-emphasis"></div></div>

            <div class="sidebar-section layers-section d-flex flex-column flex-grow-1 overflow-hidden">
                <div class="panel-header bg-surface-variant px-3 py-2 text-caption font-weight-bold text-high-emphasis border-b d-flex justify-space-between align-center">
                    <div class="d-flex align-center"><v-icon size="14" class="mr-2">mdi-layers</v-icon> CAMADAS</div>
                    <v-tooltip text="Novo Grupo" location="top" content-class="bg-inverse-surface text-inverse-on-surface">
                        <template v-slot:activator="{ props }">
                            <v-btn v-bind="props" icon density="compact" size="x-small" variant="text" @click="createFolderPrompt">
                                <v-icon color="medium-emphasis">mdi-folder-plus</v-icon>
                            </v-btn>
                        </template>
                    </v-tooltip>
                </div>
                <div class="flex-grow-1 overflow-y-auto custom-scrollbar bg-surface">
                     <draggable v-model="elements" item-key="id" class="layers-list d-flex flex-column" handle=".drag-handle" @end="forceUpdatePreview">
                        <template #item="{ element: el }">
                             <div class="layer-row d-flex align-center px-3 py-2 border-b cursor-pointer transition-all"
                               :class="activeElementId === el.id ? 'bg-primary-lighten-4 dark:bg-primary-darken-4 border-l-4 border-primary' : 'hover:bg-surface-variant'"
                               @click="activeElementId = el.id" @contextmenu.prevent="openContextMenu($event, el.id)">

                               <div class="d-flex align-center justify-center mr-2 drag-handle cursor-grab">
                                   <v-icon size="16" color="medium-emphasis">mdi-drag-vertical</v-icon>
                               </div>
                               <div class="d-flex align-center justify-center mr-3">
                                   <v-icon size="16" v-if="el.type === 'text'" color="on-surface">mdi-format-text</v-icon>
                                   <v-icon size="16" v-else-if="el.type === 'barcode'" color="on-surface">mdi-barcode</v-icon>
                                   <v-icon size="16" v-else color="on-surface">mdi-image</v-icon>
                               </div>
                               <div class="d-flex flex-column flex-grow-1 overflow-hidden" style="line-height: 1.2;">
                                   <span class="text-caption font-weight-medium text-high-emphasis text-truncate">{{ el.label }}</span>
                                   <span v-if="el.folderId" class="text-[9px] text-primary font-weight-bold"><v-icon size="10" color="primary" class="mr-1">mdi-folder-open</v-icon>Grupo</span>
                               </div>
                               <v-btn icon density="compact" variant="text" size="x-small" @click.stop="el.visible = !el.visible">
                                   <v-icon size="16" :color="el.visible ? 'medium-emphasis' : 'disabled'">{{ el.visible ? 'mdi-eye' : 'mdi-eye-off' }}</v-icon>
                               </v-btn>
                            </div>
                        </template>
                     </draggable>
                     <div v-if="elements.length === 0" class="pa-4 text-center text-caption text-medium-emphasis">Nenhuma camada adicionada</div>
                </div>
            </div>
        </aside>

        <main class="editor-area flex-grow-1 d-grid-editor position-relative overflow-hidden z-10" style="background-color: rgb(var(--v-theme-background));">

            <div class="ruler-corner bg-surface border-e border-b z-50"></div>
            <div class="ruler-top-container bg-surface border-b overflow-hidden relative z-40">
                <div class="ruler-track-h" :style="{ transform: `translateX(${rulerStart.x}px)` }">
                    <div class="ruler-content" :style="{ width: (config.labelWidth * zoom) + 200 + 'px' }">
                        <div v-for="i in Math.ceil(config.labelWidth / 10) + 1" :key="'rt'+i" class="tick-major" :style="{ left: ((i-1) * 10 * zoom) + 'px' }">
                             <span class="tick-label text-medium-emphasis">{{ (i-1)*10 }}</span>
                        </div>
                        <div v-for="j in Math.ceil(config.labelWidth / 2)" :key="'rts'+j" class="tick-minor" :style="{ left: ((j-1) * 2 * zoom) + 'px' }"></div>
                    </div>
                </div>
            </div>

            <div class="ruler-left-container bg-surface border-e overflow-hidden relative z-40">
                <div class="ruler-track-v" :style="{ transform: `translateY(${rulerStart.y}px)` }">
                    <div class="ruler-content-v" :style="{ height: (config.labelHeight * zoom) + 200 + 'px' }">
                        <div v-for="i in Math.ceil(config.labelHeight / 10) + 1" :key="'rl'+i" class="tick-major-v" :style="{ top: ((i-1) * 10 * zoom) + 'px' }">
                             <span class="tick-label-v text-medium-emphasis">{{ (i-1)*10 }}</span>
                        </div>
                        <div v-for="j in Math.ceil(config.labelHeight / 2)" :key="'rls'+j" class="tick-minor-v" :style="{ top: ((j-1) * 2 * zoom) + 'px' }"></div>
                    </div>
                </div>
            </div>

            <div class="canvas-viewport overflow-auto custom-scrollbar relative"
                 ref="scrollContainer"
                 @scroll="updateRulerPosition"
                 @wheel.ctrl.prevent="handleWheelZoom"
            >
                <div class="canvas-center-wrapper d-flex align-center justify-center position-relative" style="min-width: 100%; min-height: 100%; padding: 60px;">

                     <div class="workspace-grid" :style="computedWorkspaceGridStyle"></div>

                     <div class="canvas-stage bg-white elevation-10 position-relative transition-all"
                         ref="stageRef"
                         :style="{
                            width: (config.labelWidth * zoom) + 'px',
                            height: (config.labelHeight * zoom) + 'px',
                         }"
                         @mousemove="onMouseMoveWrapper"
                         @mouseup="stopInteraction"
                         @mouseleave="stopInteraction"
                         @contextmenu.prevent="activeElementId = null"
                    >
                        <div v-for="gx in activeGuides.x" :key="'gx'+gx" class="smart-guide-v" :style="{ left: (gx * zoom) + 'px' }">
                            <span class="guide-tag">{{ Math.round(gx) }}</span>
                        </div>
                        <div v-for="gy in activeGuides.y" :key="'gy'+gy" class="smart-guide-h" :style="{ top: (gy * zoom) + 'px' }">
                            <span class="guide-tag">{{ Math.round(gy) }}</span>
                        </div>

                        <template v-for="(el, index) in elements" :key="el.id">
                            <div v-if="el.visible" class="canvas-element position-absolute"
                                :class="{'element-selected': activeElementId === el.id}"
                                :style="{
                                    left: (el.x * zoom) + 'px', top: (el.y * zoom) + 'px',
                                    width: (el.type !== 'text' ? (el.width! * zoom) : 'auto') + 'px',
                                    height: (el.type !== 'text' ? (el.height! * zoom) : 'auto') + 'px',
                                    zIndex: index, opacity: el.opacity, cursor: 'move',
                                    transform: `rotate(${el.rotation || 0}deg)`,
                                    transformOrigin: 'center center'
                                }"
                                @mousedown.stop="startDrag($event, el)" @contextmenu.prevent.stop="openContextMenu($event, el.id)"
                            >
                                <span v-if="el.type === 'text'" class="no-select whitespace-nowrap d-block"
                                    :style="{ fontSize: (el.fontSize ? (el.fontSize * (zoom/2.83)) : 12) + 'px', fontFamily: el.fontFamily, fontWeight: el.bold ? 'bold' : 'normal', fontStyle: el.italic ? 'italic' : 'normal', color: el.color, lineHeight: 1 }">
                                    {{ getResolvedValue(el) }}
                                </span>
                                <div v-else-if="el.type === 'barcode'" class="w-100 h-100 no-select pointer-events-none">
                                    <img :src="getBarcodeSrc(el)" class="w-100 h-100 object-fill" draggable="false" />
                                </div>
                                <div v-else-if="el.type === 'image'" class="w-100 h-100 no-select">
                                    <img :src="el.src" class="w-100 h-100 object-fill pointer-events-none" draggable="false"/>
                                </div>

                                <div v-if="activeElementId === el.id" class="selection-box">
                                    <div class="resize-handle top-left" @mousedown.stop="localStartResize($event, el, 'tl')"></div>
                                    <div class="resize-handle top-right" @mousedown.stop="localStartResize($event, el, 'tr')"></div>
                                    <div class="resize-handle bottom-left" @mousedown.stop="localStartResize($event, el, 'bl')"></div>
                                    <div class="resize-handle bottom-right" @mousedown.stop="localStartResize($event, el, 'br')"></div>
                                </div>
                            </div>
                        </template>
                     </div>
                </div>
            </div>

            <div class="canvas-overlay-info">
                 <button class="zoom-btn" @click="zoom -= 1"><v-icon size="16">mdi-minus</v-icon></button>
                 <span class="zoom-text">{{ Math.round(zoom * 100) / 100 }}x</span>
                 <button class="zoom-btn" @click="zoom += 1"><v-icon size="16">mdi-plus</v-icon></button>
            </div>
        </main>

        <aside class="sidebar-right border-s bg-surface w-300 flex-shrink-0 z-20 d-flex flex-column">
            <div class="overflow-y-auto custom-scrollbar border-b flex-shrink-0" style="height: 45%; min-height: 250px;">
                <div class="panel-header bg-surface-variant px-3 py-2 text-caption font-weight-bold text-high-emphasis border-b d-flex justify-space-between align-center">
                    <div class="d-flex align-center"><v-icon size="14" class="mr-2">mdi-tune-vertical</v-icon> PROPRIEDADES</div>
                    <v-chip v-if="activeElement" size="x-small" color="primary" label class="font-weight-bold uppercase">{{ activeElement.type }}</v-chip>
                </div>
                <div v-if="activeElement" class="pa-4 d-flex flex-column gap-4">
                    <div class="d-flex gap-2 align-center">
                        <v-text-field v-model="activeElement.label" density="compact" hide-details variant="outlined" label="Nome da Camada" class="font-weight-bold" bg-color="surface"></v-text-field>
                        <v-btn icon color="error" variant="text" density="compact" @click="deleteElement(activeElement.id)"><v-icon>mdi-trash-can-outline</v-icon></v-btn>
                    </div>

                    <div class="control-group">
                        <label class="text-caption text-medium-emphasis mb-1 d-block font-weight-medium">Posição (mm)</label>
                        <div class="d-grid-2 gap-2 mb-2">
                            <v-text-field label="X" type="number" step="0.5" v-model.number="activeElement.x" density="compact" hide-details variant="outlined"></v-text-field>
                            <v-text-field label="Y" type="number" step="0.5" v-model.number="activeElement.y" density="compact" hide-details variant="outlined"></v-text-field>
                        </div>
                        <div class="d-grid-2 gap-2" v-if="activeElement.type !== 'text'">
                            <v-text-field label="Largura" type="number" step="1" v-model.number="activeElement.width" density="compact" hide-details variant="outlined"></v-text-field>
                            <v-text-field label="Altura" type="number" step="1" v-model.number="activeElement.height" density="compact" hide-details variant="outlined"></v-text-field>
                        </div>
                    </div>

                    <v-divider></v-divider>

                    <template v-if="activeElement.type === 'text'">
                         <div class="control-group"><label class="text-caption text-medium-emphasis mb-1 d-block font-weight-medium">Estilo de Texto</label>
                             <div class="d-flex gap-2 mb-2">
                                 <v-select v-model="activeElement.fontFamily" :items="['helvetica', 'courier', 'times']" density="compact" hide-details variant="outlined" class="flex-grow-1"></v-select>
                                 <v-text-field type="number" v-model.number="activeElement.fontSize" density="compact" hide-details variant="outlined" style="width: 70px" suffix="pt"></v-text-field>
                             </div>
                             <div class="d-flex gap-2 align-center">
                                 <v-btn-toggle v-model="activeElement.bold" density="compact" color="primary" variant="outlined" class="flex-grow-1" multiple>
                                     <v-btn :value="true" @click="activeElement.bold = !activeElement.bold" :active="activeElement.bold"><v-icon>mdi-format-bold</v-icon></v-btn>
                                     <v-btn :value="true" @click="activeElement.italic = !activeElement.italic" :active="activeElement.italic"><v-icon>mdi-format-italic</v-icon></v-btn>
                                 </v-btn-toggle>
                                 <input type="color" v-model="activeElement.color" class="color-picker-input border rounded">
                             </div>
                         </div>
                    </template>

                    <template v-if="activeElement.type === 'barcode'">
                         <div class="control-group">
                             <v-checkbox v-model="activeElement.showNum" label="Exibir Números" density="compact" hide-details color="primary"></v-checkbox>
                         </div>
                    </template>

                    <div class="control-group">
                        <label class="text-caption text-medium-emphasis font-weight-medium">Rotação (Graus)</label>
                        <v-slider v-model.number="activeElement.rotation" min="0" max="360" step="1" hide-details density="compact" color="primary">
                            <template v-slot:append>
                                <v-text-field v-model.number="activeElement.rotation" type="number" density="compact" hide-details variant="outlined" style="width: 70px"></v-text-field>
                            </template>
                        </v-slider>
                    </div>

                    <div class="control-group">
                        <label class="text-caption text-medium-emphasis font-weight-medium">Opacidade</label>
                        <v-slider v-model.number="activeElement.opacity" min="0" max="1" step="0.1" hide-details density="compact" color="primary"></v-slider>
                    </div>
                </div>
                <div v-else class="h-100 d-flex flex-column align-center justify-center text-center pa-4 text-disabled">
                    <v-icon size="48" class="mb-3">mdi-cursor-default-click-outline</v-icon>
                    <div class="text-caption">Selecione um elemento para editar</div>
                </div>
            </div>

            <div class="preview-panel bg-surface-variant d-flex flex-column flex-grow-1">
                <div class="panel-header d-flex justify-space-between align-center border-t border-b bg-surface-variant px-3 py-2">
                    <div class="d-flex align-center text-caption font-weight-bold text-high-emphasis"><v-icon size="16" class="mr-2">mdi-file-pdf-box</v-icon> PREVIEW PDF</div>
                    <div class="d-flex align-center gap-1">
                        <v-tooltip text="Tela Cheia" location="top" content-class="bg-inverse-surface">
                            <template v-slot:activator="{ props }">
                                <v-btn v-bind="props" icon density="compact" variant="text" size="small" @click="showFullscreenPreview = true" class="text-high-emphasis"><v-icon>mdi-fullscreen</v-icon></v-btn>
                            </template>
                        </v-tooltip>
                        <v-tooltip text="Atualizar Preview" location="top" content-class="bg-inverse-surface">
                            <template v-slot:activator="{ props }">
                                <v-btn v-bind="props" icon density="compact" variant="tonal" size="small" @click="forceUpdatePreview" :loading="isGenerating" color="primary"><v-icon>mdi-refresh</v-icon></v-btn>
                            </template>
                        </v-tooltip>
                    </div>
                </div>
                <div class="px-3 py-2 border-b bg-surface d-flex align-center justify-space-between">
                    <span class="text-caption font-weight-medium text-medium-emphasis">
                        Simular Limites (Testar Sangria)
                    </span>
                    <v-switch
                        v-model="showPdfGrid"
                        color="error"
                        density="compact"
                        hide-details
                        @change="forceUpdatePreview">
                    </v-switch>
                </div>
                <div class="flex-grow-1 bg-background relative overflow-hidden d-flex align-center justify-center pa-2">
                    <iframe v-if="pdfUrl" :src="pdfUrl + '#view=Fit&toolbar=0&navpanes=0&scrollbar=0'" class="w-100 h-100 border rounded elevation-2 bg-white"></iframe>
                    <div v-else class="text-center">
                        <v-progress-circular indeterminate color="primary" v-if="isGenerating" size="32"></v-progress-circular>
                        <div v-else>
                            <v-icon size="48" color="disabled" class="mb-2">mdi-file-pdf-box</v-icon>
                            <div class="text-caption text-medium-emphasis">Preview Pendente</div>
                        </div>
                    </div>
                </div>
            </div>
        </aside>

      </div>
    </div>

    <v-menu v-model="showContextMenu" :style="{top: contextPos.y + 'px', left: contextPos.x + 'px'}" absolute location="bottom start" :close-on-content-click="true">
        <v-list density="compact" class="elevation-10 bg-surface text-high-emphasis" width="200">
            <v-list-item @click="actionDuplicate" prepend-icon="mdi-content-duplicate" title="Duplicar"></v-list-item>
            <v-divider></v-divider>
            <v-list-item @click="actionBringForward" prepend-icon="mdi-arrange-bring-forward" title="Trazer p/ Frente"></v-list-item>
            <v-list-item @click="actionSendBackward" prepend-icon="mdi-arrange-send-backward" title="Enviar p/ Trás"></v-list-item>
            <v-divider></v-divider>
            <v-list-item @click="createFolderPrompt" prepend-icon="mdi-folder-plus" title="Agrupar"></v-list-item>
            <v-list-item @click="actionDelete" prepend-icon="mdi-delete" title="Excluir" color="error"></v-list-item>
        </v-list>
    </v-menu>

    <v-dialog v-model="showFullscreenPreview" fullscreen transition="dialog-bottom-transition">
        <v-card class="h-100 d-flex flex-column bg-surface">
            <v-toolbar density="compact" color="surface" class="border-b">
                <v-icon class="ml-4 mr-2" color="primary">mdi-file-pdf-box</v-icon>
                <v-toolbar-title class="text-subtitle-1 font-weight-bold text-high-emphasis">Visualização de Impressão Completa</v-toolbar-title>
                <v-spacer></v-spacer>
                <v-btn color="primary" variant="flat" class="mr-3 font-weight-bold text-none" @click="downloadPDF"><v-icon start>mdi-download</v-icon> Baixar PDF</v-btn>
                <v-btn icon="mdi-close" variant="text" @click="showFullscreenPreview = false"></v-btn>
            </v-toolbar>
            <iframe v-if="pdfUrl" :src="pdfUrl" class="flex-grow-1 w-100 border-none bg-grey-lighten-2"></iframe>
        </v-card>
    </v-dialog>

  </v-dialog>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, reactive, nextTick, watch, mergeProps } from 'vue'
import draggable from 'vuedraggable'
import JsBarcode from 'jsbarcode'
import { useAppStore } from '@/stores/app'
import { useLabelStudio, type LabelElement } from '@/composables/useLabelStudio'

const props = defineProps<{ modelValue: boolean, products: any[] }>()
const emit = defineEmits(['update:modelValue'])
const appStore = useAppStore()

const isLoadingData = ref(false)
const removeBgMode = ref(false)

// Presets State
const showPresetMenu = ref(false)
const presetTab = ref('user')
const userPresets = ref<any[]>([])

// Modelos Padrão conhecidos
const labelTemplates = [
    { name: 'Pimaco 6180 (A4, 30 Etiquetas)', config: { labelWidth: 66.7, labelHeight: 25.4, marginTop: 15.1, marginLeft: 4.2, cols: 3, rows: 10 } },
    { name: 'Pimaco 6182 (A4, 14 Etiquetas)', config: { labelWidth: 101.6, labelHeight: 33.9, marginTop: 15.1, marginLeft: 4.2, cols: 2, rows: 7 } },
    { name: 'Pimaco 6189 (A4, 1 Etiqueta)', config: { labelWidth: 210, labelHeight: 297, marginTop: 0, marginLeft: 0, cols: 1, rows: 1 } },
    { name: 'Térmica 40x40 (Rolo)', config: { labelWidth: 40, labelHeight: 40, marginTop: 0, marginLeft: 0, cols: 1, rows: 1 } },
    { name: 'Térmica 100x150 (Envios/Sedex)', config: { labelWidth: 100, labelHeight: 150, marginTop: 0, marginLeft: 0, cols: 1, rows: 1 } }
]

// Elementos Default extendidos com rotation
const defaultElements: any[] = [
    { id: 'name', label: 'Nome Produto', type: 'text', x: 2, y: 3, fontSize: 8, bold: true, visible: true, fontFamily: 'helvetica', color: '#000000', opacity: 1, rotation: 0 },
    { id: 'price', label: 'Preço', type: 'text', x: 2, y: 7, fontSize: 12, bold: true, visible: true, fontFamily: 'helvetica', color: '#000000', opacity: 1, rotation: 0 },
    { id: 'barcode', label: 'Código Barras', type: 'barcode', x: 2, y: 11, width: 35, height: 10, visible: true, showNum: true, color: '#000000', opacity: 1, rotation: 0 }
]

const {
    zoom, activeElementId, elements, pdfUrl, isGenerating, activeGuides,
    snappingEnabled, showGrid, showPdfGrid,
    handleWheelZoom, startDrag, startResize, handleMouseMove, stopInteraction, generatePdfPreview, createPdfDoc,
    addImage, addText, addBarcode, duplicateElement, deleteElement, bringForward, sendBackward, createFolder
} = useLabelStudio(defaultElements)

const dialog = computed({ get: () => props.modelValue, set: (val) => emit('update:modelValue', val) })
const activeElement = computed(() => elements.value.find(e => e.id === activeElementId.value) as any)
const fileInput = ref<HTMLInputElement | null>(null)
const showFullscreenPreview = ref(false)
const scrollContainer = ref<HTMLElement | null>(null)
const stageRef = ref<HTMLElement | null>(null)
const rulerStart = reactive({ x: 0, y: 0 })

// Configuração
const config = ref({ pageSize: 'Letter', labelWidth: 44.45, labelHeight: 12.7, marginTop: 12.7, marginLeft: 4.8, colGap: 2.5, rowGap: 0, cols: 4, rows: 20 })
const printOptions = ref({ copies: 1, start: 0 })

// Melhorando a detecção do produto para o preview
const sampleProduct = computed(() => {
    if (props.products && props.products.length > 0) {
        return props.products[0]
    }
    return {
        name: 'PRODUTO EXEMPLO',
        sku: 'SKU-000',
        base_price: 99.90,
        barcode: '1234567890123'
    }
})

// Simula carregamento elegante ao abrir
watch(dialog, (val) => {
    if (val) {
        isLoadingData.value = true
        setTimeout(() => {
            isLoadingData.value = false
            nextTick(forceUpdatePreview)
        }, 1200)
    }
})

// Grid Style Dinâmico aplicado no workspace inteiro
const computedWorkspaceGridStyle = computed(() => {
    if (!showGrid.value) return { display: 'none' }
    const majorSize = 10 * zoom.value
    const minorSize = 2 * zoom.value
    // Cores que respeitam light e dark mode via variáveis CSS do Vuetify
    const majorColor = 'rgba(var(--v-theme-on-surface), 0.15)'
    const minorColor = 'rgba(var(--v-theme-on-surface), 0.05)'
    return {
        backgroundSize: `${majorSize}px ${majorSize}px, ${majorSize}px ${majorSize}px, ${minorSize}px ${minorSize}px, ${minorSize}px ${minorSize}px`,
        backgroundImage:
            `linear-gradient(${majorColor} 1px, transparent 1px),
             linear-gradient(90deg, ${majorColor} 1px, transparent 1px),
             linear-gradient(${minorColor} 1px, transparent 1px),
             linear-gradient(90deg, ${minorColor} 1px, transparent 1px)`,
        backgroundPosition: `${rulerStart.x}px ${rulerStart.y}px` // Alinha perfeitamente com a régua e o canvas!
    }
})

const updateRulerPosition = () => {
    if (!scrollContainer.value || !stageRef.value) return
    const vRect = scrollContainer.value.getBoundingClientRect()
    const sRect = stageRef.value.getBoundingClientRect()
    rulerStart.x = sRect.left - vRect.left
    rulerStart.y = sRect.top - vRect.top
}

// Redimensionamento Local (Permite redimensionar Textos proporcionalmente)
let isLocalResizing = false;
const localStartResize = (e: MouseEvent, el: any, corner: string) => {
    e.stopPropagation();
    e.preventDefault();

    if (el.type === 'text') {
        isLocalResizing = true;
        const startX = e.clientX;
        const startY = e.clientY;
        const startFontSize = el.fontSize || 12;

        const onMove = (moveEvent: MouseEvent) => {
            if (!isLocalResizing) return;
            const dx = moveEvent.clientX - startX;
            const dy = moveEvent.clientY - startY;

            // Determina fator de escala baseado no canto puxado
            let factor = 0;
            if (corner === 'br' || corner === 'tr') factor += dx; else factor -= dx;
            if (corner === 'br' || corner === 'bl') factor += dy; else factor -= dy;

            const scaleFactor = 1 + (factor / 200); // Sensibilidade
            let newSize = startFontSize * scaleFactor;
            if (newSize < 4) newSize = 4;
            if (newSize > 300) newSize = 300;

            el.fontSize = Math.round(newSize);
        };

        const onUp = () => {
            isLocalResizing = false;
            document.removeEventListener('mousemove', onMove);
            document.removeEventListener('mouseup', onUp);
            forceUpdatePreview();
        };

        document.addEventListener('mousemove', onMove);
        document.addEventListener('mouseup', onUp);
    } else {
        // Fallback para o resize original do Composible para imagens e barcodes
        startResize(e, el, corner);
    }
}

// Context Menu
const showContextMenu = ref(false)
const contextPos = reactive({ x: 0, y: 0 })
const contextElementId = ref<string | null>(null)

const openContextMenu = (event: MouseEvent, id: string) => {
    showContextMenu.value = false
    nextTick(() => {
        contextElementId.value = id
        contextPos.x = event.clientX
        contextPos.y = event.clientY
        showContextMenu.value = true
    })
}
const actionDuplicate = () => { if(contextElementId.value) duplicateElement(contextElementId.value) }
const actionDelete = () => { if(contextElementId.value) deleteElement(contextElementId.value) }
const actionBringForward = () => { if(contextElementId.value) bringForward(contextElementId.value) }
const actionSendBackward = () => { if(contextElementId.value) sendBackward(contextElementId.value) }

// Resolved Values (Stock Data Fetching Logic)
const getResolvedValue = (el: any) => {
    const p = sampleProduct.value
    if (el.id === 'name') return (p.name || p.description || 'Sem Nome').substring(0, 30)

    if (el.id === 'price') {
        const priceVal = p.sale_price || p.price || p.active_price || p.base_price || 0
        return new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(Number(priceVal))
    }

    if (el.id === 'sku') return `Ref: ${p.sku || p.code || '---'}`
    if (el.id === 'barcode') return p.barcode || p.ean || p.sku || '000000'
    return el.label
}

const getBarcodeSrc = (el: any) => {
    try {
        const p = sampleProduct.value
        const code = p.barcode || p.ean || p.sku || '123456789'
        const canvas = document.createElement('canvas')
        JsBarcode(canvas, code, {
            format: "CODE128",
            displayValue: el.showNum,
            fontSize: 20,
            margin: 0,
            lineColor: el.color || '#000000',
            width: 2,
            height: 50
        })
        return canvas.toDataURL('image/png')
    } catch { return '' }
}

const onMouseMoveWrapper = (e: MouseEvent) => { handleMouseMove(e, config.value.labelWidth, config.value.labelHeight) }

const triggerImageUpload = (removeBg: boolean) => {
    removeBgMode.value = removeBg
    fileInput.value?.click()
}
const handleImageUpload = (e: Event) => {
    const target = e.target as HTMLInputElement;
    if(target.files?.[0]) {
        addImage(target.files[0], removeBgMode.value)
    }
    target.value = '' // reset
}
const createFolderPrompt = () => {
    const name = prompt('Nome do Grupo:')
    if(name) createFolder(name)
}

// Lógica de Presets (Apenas atualiza layout, não produtos)
const saveNewPreset = () => {
    const name = prompt('Nome do novo preset:')
    if (!name) return
    const newPreset = {
        id: Date.now(),
        name,
        config: JSON.parse(JSON.stringify(config.value)),
        elements: JSON.parse(JSON.stringify(elements.value))
    }
    userPresets.value.push(newPreset)
    localStorage.setItem('mj_label_presets_list', JSON.stringify(userPresets.value))
    appStore.showSnackbar('Preset salvo com sucesso!', 'success')
}

const loadPresetsFromStorage = () => {
    const saved = localStorage.getItem('mj_label_presets_list')
    if (saved) {
        try { userPresets.value = JSON.parse(saved) } catch {}
    }
}

const deletePreset = (index: number) => {
    userPresets.value.splice(index, 1)
    localStorage.setItem('mj_label_presets_list', JSON.stringify(userPresets.value))
}

const applyPreset = (preset: any) => {
    config.value = JSON.parse(JSON.stringify(preset.config))
    if (preset.elements) elements.value = JSON.parse(JSON.stringify(preset.elements))
    showPresetMenu.value = false
    appStore.showSnackbar(`Preset "${preset.name}" aplicado!`, 'success')
    nextTick(forceUpdatePreview)
}

const applyTemplate = (tpl: any) => {
    config.value = { ...config.value, ...JSON.parse(JSON.stringify(tpl.config)) }
    showPresetMenu.value = false
    appStore.showSnackbar(`Modelo "${tpl.name}" aplicado!`, 'success')
    nextTick(forceUpdatePreview)
}

const forceUpdatePreview = () => { generatePdfPreview(config.value, printOptions.value, props.products.length ? props.products : [sampleProduct.value]) }
const downloadPDF = () => { isGenerating.value = true; setTimeout(() => { const doc = createPdfDoc(config.value, printOptions.value, props.products.length ? props.products : [sampleProduct.value]); doc.save('etiquetas.pdf'); isGenerating.value = false; appStore.showSnackbar('PDF gerado!', 'success') }, 500) }
const close = () => { emit('update:modelValue', false) }

watch(zoom, () => nextTick(updateRulerPosition))

onMounted(() => {
    loadPresetsFromStorage();
    nextTick(updateRulerPosition)
})
</script>

<style scoped lang="scss">
/* Estilos Específicos do Editor */
.studio-dialog { font-family: 'Inter', sans-serif; }

.tool-btn {
    width: 36px; height: 36px; border-radius: 8px; display: flex; align-items: center; justify-content: center;
    color: inherit; opacity: 0.75; transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
    &:hover { opacity: 1; background: rgba(var(--v-theme-primary), 0.1); transform: translateY(-1px); }
    &.active { opacity: 1; color: rgb(var(--v-theme-primary)); background: rgba(var(--v-theme-primary), 0.15); box-shadow: inset 0 2px 4px rgba(0,0,0,0.05); }
}
.divider-v { width: 1px; height: 20px; background: rgba(var(--v-theme-on-surface), 0.2); margin: 0 8px; }

.lh-1 { line-height: 1.1; }
.d-grid-2 { display: grid; grid-template-columns: 1fr 1fr; }
.w-280 { width: 280px; } .w-300 { width: 340px; } /* Painel direito levemente mais largo para o preview */
.cursor-grab { cursor: grab; }
.color-picker-input { border: 1px solid rgba(128,128,128,0.3); width: 32px; height: 32px; cursor: pointer; background: white; padding: 2px; }

/* Canvas & Grid Layout */
.d-grid-editor { display: grid; grid-template-columns: 30px 1fr; grid-template-rows: 30px 1fr; }
.ruler-corner { grid-column: 1; grid-row: 1; }
.ruler-top-container { grid-column: 2; grid-row: 1; }
.ruler-left-container { grid-column: 1; grid-row: 2; }
.canvas-viewport { grid-column: 2; grid-row: 2; }

/* Background Grid do Workspace */
.workspace-grid {
    position: absolute;
    top: 0; left: 0; right: 0; bottom: 0;
    z-index: 0;
    pointer-events: none;
    will-change: background-position;
}

/* Réguas */
.ruler-track-h { height: 100%; position: relative; will-change: transform; }
.ruler-track-v { width: 100%; position: relative; will-change: transform; }
.tick-major { position: absolute; top: 0; height: 100%; width: 1px; background: rgba(var(--v-theme-on-surface), 0.3); }
.tick-label { position: absolute; top: 2px; left: 4px; font-size: 10px; opacity: 0.8; font-family: monospace; color: rgb(var(--v-theme-on-surface)); }
.tick-minor { position: absolute; bottom: 0; height: 6px; width: 1px; background: rgba(var(--v-theme-on-surface), 0.15); }
.tick-major-v { position: absolute; left: 0; width: 100%; height: 1px; background: rgba(var(--v-theme-on-surface), 0.3); }
.tick-label-v { position: absolute; left: 4px; top: 4px; font-size: 10px; opacity: 0.8; font-family: monospace; writing-mode: vertical-lr; transform: rotate(180deg); color: rgb(var(--v-theme-on-surface)); }
.tick-minor-v { position: absolute; right: 0; width: 6px; height: 1px; background: rgba(var(--v-theme-on-surface), 0.15); }

/* Overlay de Zoom */
.canvas-overlay-info {
    position: absolute; top: 12px; right: 24px;
    background: rgb(var(--v-theme-surface)); border: 1px solid rgba(var(--v-theme-on-surface), 0.1);
    box-shadow: 0 4px 12px rgba(0,0,0,0.1);
    padding: 6px 12px; border-radius: 20px;
    display: flex; align-items: center; gap: 8px; z-index: 100;
}
.zoom-btn { opacity: 0.7; color: rgb(var(--v-theme-on-surface)); transition: all 0.2s; &:hover { opacity: 1; color: rgb(var(--v-theme-primary)); transform: scale(1.1); } }
.zoom-text { font-size: 12px; font-family: monospace; font-weight: bold; width: 44px; text-align: center; color: rgb(var(--v-theme-on-surface)); }

/* Elementos no Canvas */
/* Guias Inteligentes - AZUL FORTE (#2196F3) */
.smart-guide-v { position: absolute; top: -2000px; bottom: -2000px; width: 1px; background: #2196F3; z-index: 999; pointer-events: none; }
.smart-guide-h { position: absolute; left: -2000px; right: -2000px; height: 1px; background: #2196F3; z-index: 999; pointer-events: none; }
.guide-tag { background: #2196F3; color: white; font-size: 10px; font-weight: bold; padding: 2px 4px; border-radius: 4px; position: absolute; top: 4px; left: 4px; }

.element-selected { outline: 1.5px solid rgb(var(--v-theme-primary)); box-shadow: 0 0 0 4px rgba(var(--v-theme-primary), 0.15); }
.selection-box { position: absolute; inset: 0; pointer-events: none; }
.resize-handle {
    width: 12px; height: 12px; background: white; border: 2px solid rgb(var(--v-theme-primary));
    position: absolute; pointer-events: auto; z-index: 1000; box-shadow: 0 2px 4px rgba(0,0,0,0.2);
    border-radius: 50%; /* Redondo e moderno */
    &.top-left { top: -6px; left: -6px; cursor: nwse-resize; }
    &.top-right { top: -6px; right: -6px; cursor: nesw-resize; }
    &.bottom-left { bottom: -6px; left: -6px; cursor: nesw-resize; }
    &.bottom-right { bottom: -6px; right: -6px; cursor: nwse-resize; }
    &:hover { transform: scale(1.2); }
}

/* Loading Overlay */
.loading-overlay { position: absolute; inset: 0; z-index: 9999; background: rgba(var(--v-theme-background), 0.85); }

/* Custom Scrollbar Suave */
.custom-scrollbar::-webkit-scrollbar { width: 8px; height: 8px; }
.custom-scrollbar::-webkit-scrollbar-track { background: transparent; }
.custom-scrollbar::-webkit-scrollbar-thumb { background: rgba(var(--v-theme-on-surface), 0.2); border-radius: 4px; border: 2px solid transparent; background-clip: padding-box; }
.custom-scrollbar::-webkit-scrollbar-thumb:hover { background-color: rgba(var(--v-theme-on-surface), 0.4); }
</style>
