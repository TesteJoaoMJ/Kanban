<template>
  <div class="pcp-builder-container builder-shell h-100 w-100 d-flex flex-column overflow-hidden transition-all"
       :class="isLight ? 'theme-enterprise-light text-grey-darken-4' : 'theme-enterprise-dark text-white'">

    <header class="builder-header enterprise-topbar px-5 py-3 flex-shrink-0 z-30 transition-all"
            :class="isLight ? 'bg-white border-grey-lighten-2' : 'bg-grey-darken-3 border-grey-darken-2'">
      <div class="builder-header-shell d-flex align-center justify-space-between gap-4 flex-wrap">
        <div class="builder-header-brand d-flex align-center gap-4 min-w-0">
          <div class="builder-logo-shell bg-indigo-darken-2 rounded pa-2 d-flex align-center justify-center shrink-0">
            <v-icon color="white" size="24">mdi-engine-outline</v-icon>
          </div>

          <div class="d-flex flex-column min-w-0 gap-2">
            <div class="d-flex align-center gap-2 flex-wrap">
              <div class="builder-eyebrow">Production Workflow Engine</div>
              <v-chip size="x-small" color="primary" variant="flat" class="font-weight-black px-2 chip-3d">Blueprint Studio</v-chip>
              <v-chip v-if="isCurrentMotorActive" color="success" variant="flat" size="small" class="font-weight-black chip-3d px-3">
                <v-icon start size="14">mdi-check-decagram</v-icon> EM OPERAÇÃO
              </v-chip>
            </div>

            <div class="d-flex align-center gap-3 flex-wrap min-w-0">
              <h1 class="builder-title mb-0">Flowchart Builder</h1>
              <div class="builder-subtitle text-truncate">Modelagem visual do motor, regras, formulários e transições operacionais</div>
            </div>
          </div>
        </div>

        <div class="builder-header-middle d-flex align-center gap-3 flex-wrap justify-center">
          <v-select
            v-model="currentMotorId"
            :items="store.workflows"
            item-title="name"
            item-value="id"
            density="comfortable"
            variant="solo-filled"
            hide-details
            placeholder="Selecione um Motor..."
            class="builder-motor-select font-weight-bold"
            :base-color="isLight ? 'grey' : 'grey-lighten-1'"
            :color="isLight ? 'indigo' : 'indigo-lighten-1'"
            @update:modelValue="onMotorSelect"
          >
            <template v-slot:append-item>
              <v-divider class="mb-1"></v-divider>
              <v-list-item @click="createNewMotor" class="bg-indigo-lighten-5 text-indigo-darken-3 font-weight-bold py-2">
                <template v-slot:prepend><v-icon start>mdi-plus-circle</v-icon></template>
                Criar Novo Motor Vazio
              </v-list-item>
            </template>
          </v-select>

          <div class="hint-tooltip" data-title="Excluir Motor Atual">
            <v-btn v-if="currentMotorId" icon="mdi-delete" color="error" variant="tonal" size="small" class="builder-danger-btn" @click="deleteCurrentMotor"></v-btn>
          </div>

          <v-btn-toggle v-model="viewMode" mandatory density="comfortable" variant="outlined" divided class="enterprise-segmented builder-mode-toggle"
                        :class="isLight ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-grey-darken-4 border-grey-darken-1'">
            <v-btn value="flowchart" class="px-4 text-caption font-weight-bold text-uppercase" :color="isLight ? 'indigo' : 'indigo-lighten-2'">
              <v-icon start size="small">mdi-sitemap</v-icon> Builder Visual
            </v-btn>
            <v-btn value="structure" class="px-4 text-caption font-weight-bold text-uppercase" :color="isLight ? 'indigo' : 'indigo-lighten-2'">
              <v-icon start size="small">mdi-view-week</v-icon> Preview Colunas
            </v-btn>
          </v-btn-toggle>
        </div>

        <div class="builder-header-actions d-flex align-center gap-3 flex-wrap justify-end">
          <v-btn-group v-if="viewMode === 'flowchart'" variant="outlined" density="comfortable" class="builder-zoom-cluster"
                       :class="isLight ? 'bg-white border-grey-lighten-2' : 'bg-grey-darken-4 border-grey-darken-1'">
            <v-btn icon="mdi-magnify-minus-outline" @click="zoomOut"></v-btn>
            <v-btn class="font-weight-black font-mono text-caption px-2 builder-zoom-indicator" style="min-width: 64px; pointer-events: none;">{{ Math.round(transform.scale * 100) }}%</v-btn>
            <v-btn icon="mdi-magnify-plus-outline" @click="zoomIn"></v-btn>
            <div class="hint-tooltip" data-title="Centralizar Câmera"><v-btn icon="mdi-target" @click="resetView"></v-btn></div>
          </v-btn-group>

          <v-menu location="bottom end">
            <template v-slot:activator="{ props }">
              <v-btn v-bind="props" color="warning" variant="tonal" class="font-weight-bold text-caption builder-secondary-btn" prepend-icon="mdi-auto-fix">Ações Rápidas <v-icon end>mdi-chevron-down</v-icon></v-btn>
            </template>
            <v-card class="mt-1 shadow-lg border-thin builder-actions-menu" min-width="360">
              <v-list density="compact" nav>
                <v-list-item @click="autoGenerateRealFlow" prepend-icon="mdi-factory" class="mb-1 text-primary font-weight-bold">
                  <v-list-item-title>Replicar Fluxo da Fábrica Completo</v-list-item-title>
                  <v-list-item-subtitle class="text-caption opacity-80" style="white-space: normal;">Gera abas, botões, formulários e microfluxos internos com a mesma lógica estrutural do legado.</v-list-item-subtitle>
                </v-list-item>
                <v-divider class="my-1"></v-divider>
                <v-list-item @click="clearWorkspace" prepend-icon="mdi-delete-sweep" class="text-error font-weight-bold">
                  <v-list-item-title>Limpar Quadro Atual</v-list-item-title>
                </v-list-item>
              </v-list>
            </v-card>
          </v-menu>

          <v-btn color="indigo-accent-2" variant="flat" prepend-icon="mdi-content-save-check" class="font-weight-black text-caption text-white btn-3d builder-primary-btn" @click="saveCurrentWorkflow" :loading="store.isSaving">
            Salvar
          </v-btn>

          <v-btn v-if="currentMotorId && !isCurrentMotorActive" color="success" variant="flat" prepend-icon="mdi-power-plug" class="font-weight-black text-caption text-white btn-3d builder-primary-btn ml-1" @click="activateMotor">
            Ativar Motor
          </v-btn>
        </div>
      </div>
    </header>

    <div class="builder-status-rail px-4 py-2 d-flex align-center flex-wrap gap-2" :class="isLight ? 'status-rail-light' : 'status-rail-dark'">
      <div class="status-pill">
        <v-icon size="14" class="mr-1">mdi-vector-polyline</v-icon>
        Nós visíveis: <strong class="ml-1">{{ visibleNodes.length }}</strong>
      </div>
      <div class="status-pill">
        <v-icon size="14" class="mr-1">mdi-transit-connection-variant</v-icon>
        Conexões: <strong class="ml-1">{{ visibleEdges.length }}</strong>
      </div>
      <div class="status-pill">
        <v-icon size="14" class="mr-1">mdi-layers-triple-outline</v-icon>
        Contexto: <strong class="ml-1">{{ currentContextId ? 'Microfluxo' : 'Macrofluxo' }}</strong>
      </div>
      <div class="status-pill">
        <v-icon size="14" class="mr-1">mdi-magnify</v-icon>
        Zoom: <strong class="ml-1">{{ Math.round(transform.scale * 100) }}%</strong>
      </div>
    </div>

    <v-expand-transition>
      <div v-if="currentContextId !== null && viewMode === 'flowchart'" class="w-100 flex-shrink-0 d-flex align-center justify-center py-2 z-20 shadow-sm" :class="isLight ? 'bg-indigo-lighten-5 border-b border-indigo-lighten-4' : 'bg-indigo-darken-4 border-b border-indigo-darken-3'">
         <v-chip color="indigo-darken-2" variant="flat" class="font-weight-black text-uppercase chip-3d text-white px-4">
            <v-icon start size="18">mdi-diving-scuba</v-icon>
            Mergulho Interno: {{ currentContextStageName }}
         </v-chip>
         <v-btn size="small" variant="text" class="font-weight-bold ml-4 text-indigo" prepend-icon="mdi-arrow-up-circle" @click="goUpToMacro">
            Voltar ao Fluxo Principal (Abas)
         </v-btn>
      </div>
    </v-expand-transition>

    <div class="d-flex flex-grow-1 overflow-hidden relative">

      <aside v-if="viewMode === 'flowchart'" class="sidebar-tools enterprise-panel border-r d-flex flex-column z-20 overflow-y-auto custom-scrollbar transition-all"
             style="width: 290px; min-width: 290px;"
             :class="isLight ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-grey-darken-4 border-grey-darken-2'">

        <div class="pa-4 border-b font-weight-black text-uppercase text-caption d-flex align-center gap-2 opacity-80" :class="isLight ? 'border-grey-lighten-2 text-grey-darken-3' : 'border-grey-darken-3 text-grey-lighten-1'">
           <v-icon size="18">{{ currentContextId === null ? 'mdi-view-dashboard-outline' : 'mdi-vector-link' }}</v-icon>
           Elementos {{ currentContextId === null ? 'Macro' : 'Micro' }}
        </div>

        <div class="pa-3 d-flex flex-column gap-3">
          <div v-for="item in currentPalette" :key="item.type"
               class="palette-card border rounded-lg p-2 d-flex align-center gap-3 cursor-grab hover-elevate transition-all"
               :class="isLight ? 'bg-white border-grey-lighten-2' : 'bg-grey-darken-3 border-grey-darken-1'"
               draggable="true" @dragstart="onDragStart($event, item)">
            <div class="d-flex align-center justify-center rounded elevation-1 flex-shrink-0" :style="{ backgroundColor: item.color, minWidth: '42px', height: '42px', borderRadius: item.borderRadius }">
              <v-icon size="22" color="white">{{ item.icon }}</v-icon>
            </div>
            <div class="d-flex flex-column overflow-hidden">
              <span class="font-weight-black text-[12px] lh-1 text-uppercase mb-1 text-truncate" :class="isLight ? 'text-grey-darken-4' : 'text-white'">{{ item.label }}</span>
              <span class="text-[10px] opacity-70 leading-tight text-wrap" :class="isLight ? 'text-grey-darken-2' : 'text-grey-lighten-1'">{{ item.desc }}</span>
            </div>
          </div>
        </div>

        <div class="pa-4 mt-auto border-t opacity-60 text-caption text-center" :class="isLight ? 'border-grey-lighten-2' : 'border-grey-darken-2'">
           Arraste os elementos para o quadro ao lado para construir seu fluxo.
        </div>
      </aside>

      <main
        v-if="viewMode === 'flowchart'"
        ref="workspaceRef"
        class="workspace-area enterprise-workspace flex-grow-1 relative overflow-hidden transition-all"
        :class="[currentContextId !== null ? 'context-micro' : 'context-macro']"
        @mousedown="onWorkspaceMouseDown"
        @wheel.prevent="onWorkspaceWheel"
        @dragover.prevent
        @drop="onDropNode"
      >
        <div class="grid-overlay" :class="isLight ? 'grid-light' : 'grid-dark'" :style="gridStyle"></div>

        <div v-if="visibleNodes.length === 0" class="tutorial-overlay absolute d-flex flex-column align-center justify-center w-100 h-100" style="pointer-events: none;">
          <div class="pa-10 rounded-xl border d-flex flex-column align-center text-center shadow-lg relative z-10"
               :class="isLight ? 'bg-white border-grey-lighten-2' : 'bg-grey-darken-3 border-grey-darken-2'" style="max-width: 500px;">
            <v-icon size="72" :color="currentContextId === null ? 'indigo' : 'teal'" class="mb-4 opacity-50">{{ currentContextId === null ? 'mdi-sitemap' : 'mdi-gesture-tap-button' }}</v-icon>
            <h2 class="text-h4 font-weight-black mb-3" :class="isLight ? 'text-grey-darken-3' : 'text-white'">
              {{ currentContextId === null ? 'Fluxo Principal Vazio' : 'Aba Vazia' }}
            </h2>
            <p class="text-body-1 mb-6" :class="isLight ? 'text-grey-darken-1' : 'text-grey'">
              {{ currentContextId === null ? 'Arraste Origens e Abas da paleta para construir o quadro de colunas do sistema.' : 'Comece arrastando um nó de Entrada (O status que o item tem ao chegar) e conecte aos botões para criar o fluxo de vida.' }}
            </p>
          </div>
        </div>

        <div class="canvas-layer absolute" :class="{'zoom-dive-active': isDiving}" :style="{ transform: `translate(${transform.x}px, ${transform.y}px) scale(${transform.scale})` }">

          <svg class="edges-layer absolute top-0 left-0 w-100 h-100" style="overflow: visible; pointer-events: none;">
            <defs>
              <marker id="arrowhead" markerWidth="10" markerHeight="7" refX="9" refY="3.5" orient="auto"><polygon points="0 0, 10 3.5, 0 7" fill="#9E9E9E" /></marker>
              <marker id="arrowhead-active" markerWidth="10" markerHeight="7" refX="9" refY="3.5" orient="auto"><polygon points="0 0, 10 3.5, 0 7" fill="#00d4ff" /></marker>
              <marker id="arrowhead-success" markerWidth="10" markerHeight="7" refX="9" refY="3.5" orient="auto"><polygon points="0 0, 10 3.5, 0 7" fill="#4CAF50" /></marker>
              <marker id="arrowhead-warning" markerWidth="10" markerHeight="7" refX="9" refY="3.5" orient="auto"><polygon points="0 0, 10 3.5, 0 7" fill="#FF9800" /></marker>
              <marker id="arrowhead-fail" markerWidth="10" markerHeight="7" refX="9" refY="3.5" orient="auto"><polygon points="0 0, 10 3.5, 0 7" fill="#F44336" /></marker>
              <marker id="arrowhead-jump" markerWidth="10" markerHeight="7" refX="9" refY="3.5" orient="auto"><polygon points="0 0, 10 3.5, 0 7" fill="#FFC107" /></marker>
            </defs>

            <g v-for="edge in visibleEdges" :key="edge.id">
              <path
                :d="generateSVGPath(edge.startX, edge.startY, edge.endX, edge.endY, edge.condition, edge.isJump, edge.fromId)"
                :stroke="getEdgeColor(edge.condition, edge.isJump)"
                stroke-width="2"
                stroke-dasharray="4,4"
                fill="none"
                opacity="0.3"
              />

              <path
                :d="generateSVGPath(edge.startX, edge.startY, edge.endX, edge.endY, edge.condition, edge.isJump, edge.fromId)"
                class="edge-path cursor-pointer flow-animated energy-flow"
                :stroke="selectedEdgeId === edge.id ? '#ffffff' : '#00d4ff'"
                :stroke-width="edge.isJump ? 4 : 3"
                stroke-dasharray="15, 30"
                fill="none"
                :marker-end="`url(#arrowhead${edge.isJump ? '-jump' : (edge.condition === 'rule1' ? '-success' : (edge.condition === 'rule2' ? '-warning' : (edge.condition === 'fail' ? '-fail' : '-active')))})`"
                style="pointer-events: stroke;"
                @click.stop="selectEdge(edge.id)"
                :class="{ 'edge-selected': selectedEdgeId === edge.id }"
              />
            </g>

            <path
              v-if="drawingEdge.active"
              :d="generateSVGPath(drawingEdge.startX, drawingEdge.startY, drawingEdge.currentX, drawingEdge.currentY, drawingEdge.condition, false, drawingEdge.sourceNodeId)"
              class="flow-animated energy-flow"
              stroke="#00d4ff"
              stroke-width="3"
              stroke-dasharray="15, 30"
              fill="none"
              marker-end="url(#arrowhead-active)"
            />
          </svg>

          <div
            v-for="node in visibleNodes"
            :key="node.id"
            class="flow-node-wrapper flow-node-card absolute d-flex flex-column transition-transform"
            :class="{ 'node-selected': selectedNodeId === node.id, 'node-inspected': inspectedNodeId === node.id }"
            :style="{ left: `${node.ui_x}px`, top: `${node.ui_y}px`, width: `${node.width}px`, height: `${node.height}px`, backgroundColor: node.color, borderRadius: getNodeBorderRadius(node.type) }"
            @mousedown.stop="onNodeMouseDown($event, node)"
            @dblclick.stop="onNodeDoubleClick(node)"
          >
            <div class="flow-node-topbar px-3 py-2 d-flex align-center justify-space-between gap-2 border-b border-white-02">
              <div class="d-flex align-center gap-2 min-w-0">
                <div class="flow-node-icon-shell shrink-0">
                  <v-icon size="16" color="white">{{ getNodeIcon(node.type) }}</v-icon>
                </div>
                <div class="d-flex flex-column min-w-0">
                  <span class="flow-node-kind text-truncate">{{ getNodeFriendlyTypeName(node.type) }}</span>
                  <span class="flow-node-mini-meta text-truncate">{{ node.type }}</span>
                </div>
              </div>

              <div class="d-flex align-center gap-1 shrink-0">
                <v-icon v-if="node.type === 'STAGE' && (node.data as any).slaHours > 0" size="14" color="warning" class="hint-tooltip" data-title="SLA Ativo (Tempo Limite)">mdi-clock-alert</v-icon>
                <v-btn icon="mdi-dock-right" size="x-small" variant="tonal" color="white" class="node-inspector-btn" @click.stop="openNodeInspector(node.id)">
                  <v-tooltip activator="parent" location="top">Abrir painel do elemento</v-tooltip>
                </v-btn>
              </div>
            </div>

            <div class="flow-node-body flex-grow-1 d-flex flex-column justify-space-between pa-3 px-4 position-relative">
              <div class="d-flex flex-column align-center text-center">
                <span class="flow-node-title z-10">
                  {{ node.data.name || node.data.title || 'Sem Nome' }}
                </span>

                <div class="flow-node-meta-stack mt-3 z-10">
                  <template v-if="node.type === 'STAGE'">
                    <span class="flow-node-meta-chip">
                      Ordem {{ (node.data as any).order }}
                    </span>
                    <v-btn size="x-small" variant="tonal" class="flow-node-action-btn mt-1" @click.stop="diveIntoStage(node.id)">
                      Mergulhar <v-icon end size="12">mdi-arrow-down-right</v-icon>
                    </v-btn>
                  </template>

                  <template v-if="node.type === 'ENTRY'">
                    <span class="flow-node-meta-chip">Entrada: {{ (node.data as any).dbStatus || 'Indefinido' }}</span>
                    <span v-if="(node.data as any).chipLabel" class="flow-node-tag-chip">Chip: {{ (node.data as any).chipLabel }}</span>
                  </template>

                  <template v-if="node.type === 'STEP' || node.type === 'TRANSFER'">
                    <span class="flow-node-meta-chip">{{ node.type === 'STEP' ? 'DB' : 'Alvo' }}: {{ node.type === 'STEP' ? (node.data as any).dbStatus : (node.data as any).targetStatus }}</span>
                    <span v-if="(node.data as any).chipLabel" class="flow-node-tag-chip">Chip: {{ (node.data as any).chipLabel }}</span>
                  </template>

                  <template v-if="node.type === 'FORM' || node.type === 'REWORK' || node.type === 'OUTPUT'">
                    <span class="flow-node-meta-chip">Alvo: {{ (node.data as any).targetStatus || (node.data as any).finalStatus || 'Avanço Padrão' }}</span>
                    <span v-if="(node.data as any).chipLabel" class="flow-node-tag-chip">Chip: {{ (node.data as any).chipLabel }}</span>
                  </template>
                </div>
              </div>

              <div class="flow-node-footer d-flex align-center justify-space-between gap-2 mt-3 z-10">
                <div class="flow-node-footer-badge">{{ getNodeFriendlyTypeName(node.type) }}</div>
                <v-btn size="x-small" variant="flat" color="white" class="flow-node-panel-btn" @click.stop="openNodeInspector(node.id)">
                  Editar <v-icon end size="12">mdi-arrow-top-right</v-icon>
                </v-btn>
              </div>

              <div class="absolute top-0 left-0 w-100 h-100 opacity-20 pointer-events-none" style="background: linear-gradient(135deg, rgba(255,255,255,0.4) 0%, transparent 100%);"></div>
            </div>

            <div v-if="node.type !== 'SOURCE' && node.type !== 'ENTRY'" class="port port-in absolute cursor-crosshair elevation-4" @mousedown.stop="startEdge($event, node, 'in')" @mouseup.stop="finishEdge(node, 'in')">
               <v-tooltip activator="parent" location="left">Entrada de Fluxo</v-tooltip>
            </div>

            <template v-if="node.type === 'DECISION'">
               <div class="port port-out-right absolute cursor-crosshair elevation-4 bg-success" style="border-color: #fff;" @mousedown.stop="startEdge($event, node, 'out', 'rule1')" @mouseup.stop="finishEdge(node, 'out')">
                  <v-tooltip activator="parent" location="right">Rota 1 (Verde)</v-tooltip>
               </div>
               <div class="port port-out-bottom absolute cursor-crosshair elevation-4 bg-warning" style="border-color: #fff;" @mousedown.stop="startEdge($event, node, 'out', 'rule2')" @mouseup.stop="finishEdge(node, 'out')">
                  <v-tooltip activator="parent" location="bottom">Rota 2 (Amarela)</v-tooltip>
               </div>
               <div class="port port-out-top absolute cursor-crosshair elevation-4 bg-error" style="border-color: #fff;" @mousedown.stop="startEdge($event, node, 'out', 'fail')" @mouseup.stop="finishEdge(node, 'out')">
                  <v-tooltip activator="parent" location="top">Rota 3 (Vermelha)</v-tooltip>
               </div>
            </template>

            <template v-else-if="node.type === 'REWORK'">
               <div class="port port-out-right absolute cursor-crosshair elevation-4 bg-success" style="border-color: #fff;" @mousedown.stop="startEdge($event, node, 'out', 'success')" @mouseup.stop="finishEdge(node, 'out')">
                  <v-tooltip activator="parent" location="right">Erro Aprovado/Resolvido</v-tooltip>
               </div>
               <div class="port port-out-bottom absolute cursor-crosshair elevation-4 bg-error" style="border-color: #fff;" @mousedown.stop="startEdge($event, node, 'out', 'fail')" @mouseup.stop="finishEdge(node, 'out')">
                  <v-tooltip activator="parent" location="bottom">Fio de Devolução (Retorno)</v-tooltip>
               </div>
            </template>

            <template v-else-if="node.type !== 'OUTPUT'">
               <div class="port port-out-right absolute cursor-crosshair elevation-4" @mousedown.stop="startEdge($event, node, 'out', 'default')" @mouseup.stop="finishEdge(node, 'out')">
                  <v-tooltip activator="parent" location="right">Saída de Fluxo</v-tooltip>
               </div>
            </template>
          </div>
        </div>
      </main>

      <main v-if="viewMode === 'structure'" class="enterprise-structure-view flex-grow-1 p-6 overflow-x-auto overflow-y-hidden custom-scrollbar transition-all d-flex"
            :class="isLight ? 'bg-grey-lighten-4 text-grey-darken-4' : 'bg-grey-darken-4 text-white'" style="gap: 24px;">

        <div v-if="nodes.filter(n=>n.type==='STAGE').length === 0" class="d-flex flex-column align-center justify-center w-100 h-100 opacity-50">
            <v-icon size="64" class="mb-4">mdi-view-column-outline</v-icon>
            <h3 class="text-h5 font-weight-black">Nenhuma coluna macro configurada</h3>
            <p>Arraste colunas (Aba Kanban) no Builder Visual para gerar a estrutura.</p>
        </div>

        <template v-else>
            <div v-for="stage in orderedStagesForPreview" :key="stage.id"
                 class="preview-column rounded-xl d-flex flex-column shadow-md border flex-shrink-0 enterprise-preview-column"
                 :class="isLight ? 'bg-white border-grey-lighten-2' : 'bg-grey-darken-3 border-grey-darken-2'"
                 style="width: 340px; height: 100%;">

                <div class="pa-4 text-white border-b position-relative overflow-hidden flex-shrink-0" :style="{ backgroundColor: stage.color }">
                    <div class="d-flex align-center justify-space-between position-relative z-10">
                        <div class="d-flex flex-column">
                            <h3 class="text-subtitle-1 font-weight-black text-uppercase lh-1">{{ stage.data.name || (stage.data as any).title }}</h3>
                            <span class="text-[11px] opacity-80 mt-1 font-weight-medium" v-if="(stage.data as any).chipLabel">
                                Padrão: {{ (stage.data as any).chipLabel }}
                            </span>
                        </div>
                        <v-btn size="small" variant="tonal" class="bg-white text-black font-weight-bold chip-3d px-3" @click="editNodeFromStructure(stage.id)">Editar</v-btn>
                    </div>
                    <v-icon size="60" class="absolute opacity-20" style="right: -10px; bottom: -10px; transform: rotate(-15deg); pointer-events: none;">{{ getNodeIcon('STAGE') }}</v-icon>
                </div>

                <div class="flex-grow-1 p-3 overflow-y-auto custom-scrollbar d-flex flex-column gap-3 pa-3" :class="isLight ? 'bg-grey-lighten-5' : 'bg-grey-darken-4'">
                    <div v-if="getNodesForStagePreview(stage.id).length === 0" class="h-100 d-flex flex-column align-center justify-center opacity-40 border-2 border-dashed rounded-lg pa-4 text-center">
                        <v-icon size="32" class="mb-2">mdi-gesture-tap-button</v-icon>
                        <span class="text-caption font-weight-bold">Aba Vazia no Micro-Fluxo</span>
                        <span class="text-[10px]">Não há botões ou formulários internos configurados.</span>
                    </div>

                    <v-card v-for="child in getNodesForStagePreview(stage.id)" :key="child.id"
                            class="border-thin shadow-sm rounded-lg hover-elevate overflow-hidden"
                            :class="isLight ? 'bg-white' : 'bg-grey-darken-3'"
                            @click="editNodeFromStructure(child.id)"
                            style="cursor: pointer; border-left: 6px solid !important;" :style="{ borderLeftColor: child.color + ' !important' }">
                        <div class="pa-3 d-flex flex-column gap-2">
                            <div class="d-flex justify-space-between align-start">
                                <div class="d-flex align-center gap-2">
                                    <v-icon size="18" :color="child.color">{{ getNodeIcon(child.type) }}</v-icon>
                                    <span class="font-weight-black text-subtitle-2 lh-1 text-truncate" style="max-width: 200px;">{{ child.data.name }}</span>
                                </div>
                                <v-chip size="x-small" :color="child.color" variant="flat" class="font-weight-black text-white text-[9px] px-1">{{ child.type }}</v-chip>
                            </div>

                            <div class="d-flex flex-wrap gap-2 mt-1">
                                <span v-if="child.type === 'ENTRY'" class="text-[10px] font-mono bg-grey-lighten-2 text-grey-darken-4 px-2 py-0.5 rounded border">
                                    Escuta: {{ (child.data as any).dbStatus }}
                                </span>
                                <span v-if="child.type === 'STEP' || child.type === 'TRANSFER'" class="text-[10px] font-mono bg-grey-lighten-2 text-grey-darken-4 px-2 py-0.5 rounded border">
                                    {{ child.type === 'STEP' ? 'Gera: ' + (child.data as any).dbStatus : 'Gera: ' + (child.data as any).targetStatus }}
                                </span>
                                <span v-if="child.type === 'FORM' || child.type === 'REWORK' || child.type === 'OUTPUT'" class="text-[10px] font-mono bg-grey-lighten-2 text-grey-darken-4 px-2 py-0.5 rounded border">
                                    Alvo: {{ (child.data as any).targetStatus || (child.data as any).finalStatus }}
                                </span>
                                <span v-if="(child.data as any).chipLabel" class="text-[10px] font-weight-bold bg-indigo-lighten-5 text-indigo-darken-4 px-2 py-0.5 rounded border border-indigo-lighten-4">
                                    Tag: {{ (child.data as any).chipLabel }}
                                </span>
                            </div>
                        </div>
                    </v-card>
                </div>

                <div class="pa-2 border-t text-center text-[10px] font-weight-bold opacity-60 text-uppercase tracking-widest" :class="isLight ? 'bg-white' : 'bg-grey-darken-3'">
                    SLA Limite: {{ (stage.data as any).slaHours > 0 ? (stage.data as any).slaHours + 'h' : 'Desativado' }}
                </div>
            </div>
        </template>
      </main>

      <v-slide-x-reverse-transition>
      <aside v-if="selectedNode && viewMode === 'flowchart'" class="sidebar-properties enterprise-inspector element-inspector border-l d-flex flex-column z-30 shadow-xl" style="width: 560px;"
             :class="isLight ? 'bg-white border-grey-lighten-2 text-grey-darken-4' : 'bg-grey-darken-4 border-grey-darken-2 text-white'">

        <div class="element-inspector-hero pa-5 border-b d-flex flex-column position-relative overflow-hidden" :class="isLight ? 'border-grey-lighten-2' : 'border-grey-darken-2'" :style="{ backgroundColor: selectedNode.color + (isLight ? '1A' : '33') }">
          <div class="d-flex justify-space-between align-start z-10 w-100">
             <div class="d-flex align-center gap-4">
               <v-avatar :color="selectedNode.color" size="48" class="elevation-4 text-white border-2 border-white">
                  <v-icon size="24">{{ getNodeIcon(selectedNode.type) }}</v-icon>
               </v-avatar>
               <div class="d-flex flex-column">
                 <div class="element-inspector-kicker">Elemento selecionado</div>
                 <h3 class="text-h6 font-weight-black lh-1 mb-1" :style="{ color: selectedNode.color }">{{ selectedNode.data.name || selectedNode.data.title || 'Elemento sem nome' }}</h3>
                 <v-chip size="x-small" :color="selectedNode.color" variant="flat" class="font-weight-bold px-2 align-self-start text-white text-uppercase tracking-widest">{{ getNodeFriendlyTypeName(selectedNode.type) }}</v-chip>
                 <div class="element-inspector-subtitle mt-2">Configuração, mapeamento e comportamento deste bloco no motor.</div>
               </div>
             </div>
             <v-btn icon="mdi-close" size="small" variant="tonal" :color="selectedNode.color" class="z-10" @click="closeNodeInspector()"></v-btn>
          </div>
          <div class="absolute top-0 right-0 w-50 h-100 opacity-20" style="background: linear-gradient(90deg, transparent, #fff); pointer-events: none;"></div>

          <div class="element-inspector-summary-grid mt-4 z-10">
            <div class="summary-tile"><span>Tipo</span><strong>{{ selectedNode.type }}</strong></div>
            <div class="summary-tile"><span>Contexto</span><strong>{{ selectedNode.parentId ? 'Micro' : 'Macro' }}</strong></div>
            <div class="summary-tile"><span>Tamanho</span><strong>{{ selectedNode.width }}×{{ selectedNode.height }}</strong></div>
          </div>

          <v-tabs v-model="propertiesTab" :color="selectedNode.color" density="comfortable" class="mt-4 font-weight-bold text-caption z-10 element-inspector-tabs" bg-color="transparent">
             <v-tab value="basic"><v-icon start size="16">mdi-tune</v-icon> Geral</v-tab>
             <v-tab v-if="selectedNode.type === 'STAGE'" value="rules"><v-icon start size="16">mdi-shield-lock</v-icon> Acessos e DB</v-tab>
             <v-tab v-if="selectedNode.type === 'FORM'" value="form"><v-icon start size="16">mdi-form-textbox</v-icon> Form Builder</v-tab>
             <v-tab v-if="selectedNode.type === 'DECISION'" value="logic"><v-icon start size="16">mdi-call-split</v-icon> Opções da Decisão</v-tab>
             <v-tab v-if="selectedNode.type === 'REWORK'" value="rework"><v-icon start size="16">mdi-alert-octagon</v-icon> Parâmetros do Erro</v-tab>
          </v-tabs>
        </div>

        <div class="element-inspector-content flex-grow-1 overflow-y-auto pa-6 custom-scrollbar pb-16">
          <v-window v-model="propertiesTab">

             <v-window-item value="basic">
                <v-alert :color="selectedNode.color" variant="tonal" class="text-caption mb-6 lh-1-2 border font-weight-medium pa-4 shadow-sm" border="start">
                   {{ getNodeExplanation(selectedNode.type) }}
                </v-alert>

                <v-text-field v-model="selectedNode.data.name" label="Nome do Elemento" variant="outlined" density="comfortable" class="mb-4 font-weight-black text-h6" :color="selectedNode.color"></v-text-field>

                <template v-if="selectedNode.type !== 'SOURCE' && selectedNode.type !== 'DECISION'">
                   <v-text-field v-model="(selectedNode.data as any).chipLabel" label="Rótulo do Chip (Tradução para o Dynamic)" placeholder="Ex: Impressão Concluída" variant="outlined" density="comfortable" class="mb-6 font-weight-bold" :color="selectedNode.color" persistent-hint hint="O que será escrito na etiqueta colorida do Kanban quando o item ganhar este status."></v-text-field>
                </template>

                <v-card class="pa-4 rounded-lg d-flex align-center justify-space-between shadow-sm border-thin mb-6" :class="isLight ? 'bg-grey-lighten-5' : 'bg-grey-darken-3'">
                  <span class="text-body-2 font-weight-bold">Cor Visual:</span>
                  <div class="d-flex align-center gap-3 enterprise-toolbar-actions">
                    <span class="font-mono text-caption text-uppercase opacity-70">{{ selectedNode.color }}</span>
                    <input type="color" v-model="selectedNode.color" class="elevation-2 rounded cursor-pointer" style="width: 48px; height: 40px; border: 3px solid #fff; padding: 0;">
                  </div>
                </v-card>

                <template v-if="selectedNode.type === 'SOURCE'">
                  <h4 class="text-subtitle-2 font-weight-black text-uppercase mb-4 mt-6 border-b pb-2"><v-icon size="18" class="mr-2">mdi-database-search</v-icon> Tabela Inicial</h4>
                  <v-select v-model="(selectedNode.data as any).tableName" label="Tabela do Banco (Supabase)" :items="dbTablesOptions" item-title="label" item-value="value" variant="outlined" density="comfortable" class="mb-4 font-weight-bold" :color="selectedNode.color"></v-select>
                  <v-combobox v-model="(selectedNode.data as any).entryConditions" label="Condições SQL Iniciais (Aperte Enter)" placeholder="Ex: status != 'delivered'" multiple chips variant="outlined" density="comfortable" class="font-mono text-caption" :color="selectedNode.color"></v-combobox>
                </template>

                <template v-if="selectedNode.type === 'ENTRY'">
                   <h4 class="text-subtitle-2 font-weight-black text-uppercase mb-4 mt-6 border-b pb-2"><v-icon size="18" class="mr-2">mdi-login-variant</v-icon> Identificador de Chegada</h4>
                   <v-text-field v-model="(selectedNode.data as any).dbStatus" label="Status Exato no Banco (DB_STATUS)" placeholder="ex: printed" variant="outlined" density="comfortable" class="font-mono text-caption mb-4 text-primary font-weight-black" :color="selectedNode.color" persistent-hint hint="Se o item cair nesta aba com esse status, o motor conectará ele aos fios que saem deste nó automaticamente."></v-text-field>
                </template>

                <template v-if="selectedNode.type === 'STAGE'">
                  <h4 class="text-subtitle-2 font-weight-black text-uppercase mb-4 mt-6 border-b pb-2"><v-icon size="18" class="mr-2">mdi-view-column</v-icon> Parâmetros da Coluna</h4>

                  <v-row dense class="mb-2 mt-4">
                     <v-col cols="6"><v-text-field v-model.number="(selectedNode.data as any).order" label="Ordem Física (Esq -> Dir)" type="number" variant="outlined" density="comfortable" :color="selectedNode.color"></v-text-field></v-col>
                     <v-col cols="6"><v-text-field v-model.number="(selectedNode.data as any).slaHours" label="SLA (Aviso de Atraso em Horas)" type="number" variant="outlined" density="comfortable" color="warning"></v-text-field></v-col>
                  </v-row>
                  <v-switch v-model="(selectedNode.data as any).isFinalStage" label="Aba Final? (Encerra o Pedido na Fábrica)" color="success" density="compact" class="font-weight-bold mt-2" inset></v-switch>
                </template>

                <template v-if="selectedNode.type === 'STEP'">
                   <h4 class="text-subtitle-2 font-weight-black text-uppercase mb-4 mt-6 border-b pb-2"><v-icon size="18" class="mr-2">mdi-database-edit-outline</v-icon> Propriedades do Botão</h4>
                   <v-text-field v-model="(selectedNode.data as any).dbStatus" label="Status Exato no Banco (DB_STATUS)" placeholder="ex: in_production" variant="outlined" density="comfortable" class="font-mono text-caption mb-4 text-primary" :color="selectedNode.color"></v-text-field>
                   <v-text-field v-model="(selectedNode.data as any).buttonText" label="Texto do Botão" variant="outlined" density="comfortable" class="mb-4" :color="selectedNode.color"></v-text-field>
                   <v-select v-model="(selectedNode.data as any).icon" :items="iconOptions" label="Ícone do Botão" variant="outlined" density="comfortable" class="mb-4" :color="selectedNode.color">
                      <template v-slot:selection="{ item }"><div class="d-flex align-center gap-2"><v-icon :color="selectedNode.color">{{ item.raw.value }}</v-icon> <span>{{ item.raw.title }}</span></div></template>
                      <template v-slot:item="{ props, item }"><v-list-item v-bind="props"><template v-slot:prepend><v-icon :color="selectedNode.color" class="mr-3">{{ item.raw.value }}</v-icon></template></v-list-item></template>
                   </v-select>
                   <v-switch v-model="(selectedNode.data as any).allowBatch" label="Permitir Ação em Lote (Marcar Múltiplos)?" color="success" density="compact" class="font-weight-bold mt-2" inset></v-switch>
                </template>

                <template v-if="selectedNode.type === 'TRANSFER'">
                   <h4 class="text-subtitle-2 font-weight-black text-uppercase mb-4 mt-6 border-b pb-2"><v-icon size="18" class="mr-2">mdi-page-next-outline</v-icon> Propriedades do Botão de Saída</h4>
                   <v-text-field v-model="(selectedNode.data as any).targetStatus" label="Status Alvo (O que o item ganha ao sair)" placeholder="ex: waiting_calandra" variant="outlined" density="comfortable" class="font-mono text-caption mb-4 text-primary" :color="selectedNode.color"></v-text-field>
                   <v-text-field v-model="(selectedNode.data as any).buttonText" label="Texto do Botão (Ex: Avançar p/ Calandra)" variant="outlined" density="comfortable" class="mb-4" :color="selectedNode.color"></v-text-field>
                   <v-select v-model="(selectedNode.data as any).icon" :items="iconOptions" label="Ícone do Botão" variant="outlined" density="comfortable" class="mb-4" :color="selectedNode.color">
                      <template v-slot:selection="{ item }"><div class="d-flex align-center gap-2"><v-icon :color="selectedNode.color">{{ item.raw.value }}</v-icon> <span>{{ item.raw.title }}</span></div></template>
                      <template v-slot:item="{ props, item }"><v-list-item v-bind="props"><template v-slot:prepend><v-icon :color="selectedNode.color" class="mr-3">{{ item.raw.value }}</v-icon></template></v-list-item></template>
                   </v-select>
                   <v-switch v-model="(selectedNode.data as any).allowBatch" label="Permitir Ação em Lote (Marcar Múltiplos)?" color="success" density="compact" class="font-weight-bold mt-2" inset></v-switch>
                </template>

                <v-divider class="my-6 border-transparent"></v-divider>
                <v-btn block size="large" color="error" variant="tonal" class="font-weight-black border-dashed" prepend-icon="mdi-delete-empty" @click="deleteNode(selectedNode.id)">Apagar Elemento do Quadro</v-btn>
             </v-window-item>

             <v-window-item value="rules" v-if="selectedNode.type === 'STAGE'">
                <h4 class="text-subtitle-2 font-weight-black text-uppercase mb-4 mt-2 border-b pb-2"><v-icon size="18" class="mr-2">mdi-database-search</v-icon> Mapeamento de Status Padrão</h4>
                <v-combobox v-model="(selectedNode.data as any).mappedStatuses" label="Status que nascem nesta aba" placeholder="Ex: design_pending (Aperte Enter)" multiple chips variant="outlined" density="comfortable" class="font-mono text-caption mb-6" :color="selectedNode.color" persistent-hint hint="Itens que entrarem nestes status vão aterrissar direto nos Nós de 'Entrada da Aba' (ENTRY) configurados aqui dentro."></v-combobox>

                <h4 class="text-subtitle-2 font-weight-black text-uppercase mb-4 mt-6 border-b pb-2"><v-icon size="18" class="mr-2">mdi-shield-lock</v-icon> Controle de Permissões Rigoroso</h4>
                <v-alert color="warning" variant="tonal" class="text-caption mb-5 lh-1-2 border" density="compact">Restrinja o acesso consultando a tabela de Perfis <strong>(custom_role_id)</strong>.</v-alert>

                <v-autocomplete v-model="(selectedNode.data as any).permissions.viewCustomRoles"
                                :items="customRolesOptions" item-title="name" item-value="id"
                                label="Permissão de LEITURA (Somente Observa)"
                                multiple chips closable-chips variant="outlined" density="comfortable" class="mb-4"
                                placeholder="Vazio = Todos podem ver" persistent-hint hint="Quem não estiver aqui sequer verá a coluna no kanban."></v-autocomplete>

                <v-autocomplete v-model="(selectedNode.data as any).permissions.operateCustomRoles"
                                :items="customRolesOptions" item-title="name" item-value="id"
                                label="Permissão de INTERAÇÃO (Pode Mover/Apertar)"
                                multiple chips closable-chips variant="outlined" density="comfortable"
                                placeholder="Vazio = Todos podem operar" persistent-hint hint="Apenas estes cargos poderão clicar em botões ou arrastar cards."></v-autocomplete>
             </v-window-item>

             <v-window-item value="form" v-if="selectedNode.type === 'FORM'">
                <v-row>
                   <v-col cols="12" class="mb-2">
                      <v-alert color="purple" variant="tonal" class="text-caption mb-4 lh-1-2 border font-weight-medium" density="compact">Após o usuário preencher este modal e salvar, para qual status o item deve ser enviado?</v-alert>
                      <v-text-field v-model="(selectedNode.data as any).targetStatus" label="Status após Salvar (DB_STATUS)" placeholder="ex: in_production" variant="outlined" density="comfortable" color="purple" class="font-mono text-caption font-weight-bold mb-4"></v-text-field>

                      <v-btn block size="large" color="purple" variant="flat" class="font-weight-bold btn-3d mb-4" prepend-icon="mdi-plus-box-multiple" @click="addFormField">Adicionar Campo no Modal</v-btn>

                      <draggable v-model="(selectedNode.data as any).fields" item-key="id" handle=".cursor-move">
                        <template #item="{ element: field, index: idx }">
                           <v-expansion-panels variant="accordion" class="mb-2">
                             <v-expansion-panel class="border shadow-sm" :class="isLight ? 'bg-white' : 'bg-grey-darken-3'">
                                <v-expansion-panel-title class="font-weight-bold px-4 py-2">
                                   <div class="d-flex align-center w-100">
                                      <v-icon size="18" color="grey" class="mr-3 cursor-move">mdi-drag-horizontal-variant</v-icon>
                                      <v-icon size="18" color="purple" class="mr-2">mdi-form-textbox</v-icon>
                                      <span class="text-truncate">{{ field.label || `Campo ${idx+1}` }}</span>
                                   </div>
                                </v-expansion-panel-title>
                                <v-expansion-panel-text class="pt-3">
                                   <v-text-field v-model="field.label" label="Rótulo (O que o usuário vê na tela)" variant="outlined" density="compact" color="purple" class="mb-2"></v-text-field>
                                   <v-text-field v-model="field.name" label="Chave no Banco de Dados (Ex: machine_id)" variant="outlined" density="compact" color="purple" class="font-mono text-caption mb-2"></v-text-field>
                                   <v-select v-model="field.type" :items="formFieldTypes" label="Tipo de Dado (Input)" variant="outlined" density="compact" color="purple" class="mb-2"></v-select>
                                   <v-switch v-model="field.isRequired" label="Prenchimento Obrigatório?" color="purple" density="compact" hide-details class="mb-2"></v-switch>

                                   <v-select v-if="['select', 'multiselect'].includes(field.type)" v-model="field.dataSource" :items="dbTablesOptions" label="Puxar opções da Tabela:" variant="outlined" density="compact" color="purple" class="mt-2"></v-select>
                                   <v-select v-if="['select', 'multiselect'].includes(field.type) && field.dataSource === 'production_machines'" v-model="field.machineTypeFilter" :items="[{title: 'Todas', value: 'all'}, {title: 'Apenas Impressoras', value: 'printer'}, {title: 'Apenas Calandras', value: 'calandra'}]" label="Filtro de Máquina" variant="outlined" density="compact" color="purple" class="mt-2"></v-select>

                                   <v-btn size="small" color="error" variant="text" prepend-icon="mdi-trash-can" class="mt-2" @click="removeFormField(idx)">Excluir Campo</v-btn>
                                </v-expansion-panel-text>
                             </v-expansion-panel>
                           </v-expansion-panels>
                        </template>
                      </draggable>
                   </v-col>

                   <v-col cols="12" class="mt-4">
                      <div class="text-caption font-weight-black text-uppercase mb-2 text-purple d-flex align-center"><v-icon class="mr-2">mdi-eye-outline</v-icon> Como ficará a tela do operador:</div>
                      <v-card class="pa-5 border-2 border-dashed shadow-lg rounded-xl" :class="isLight ? 'bg-grey-lighten-5 border-purple-lighten-3' : 'bg-grey-darken-4 border-purple-darken-3'">
                         <div class="text-h6 font-weight-black text-uppercase mb-4 pb-2 border-b d-flex align-center gap-2" :class="isLight ? 'text-grey-darken-4' : 'text-white'"><v-icon color="purple">mdi-form-select</v-icon> {{ selectedNode.data.name }}</div>
                         <div v-if="(selectedNode.data as any).fields.length === 0" class="text-center opacity-50 py-4 font-italic">O modal está vazio. Adicione campos acima.</div>

                         <div v-for="field in (selectedNode.data as any).fields" :key="'prev-'+field.id" class="mb-4">
                            <v-file-input v-if="field.type === 'file'" :label="field.label + (field.isRequired ? ' *' : '')" variant="outlined" density="comfortable" prepend-icon="mdi-camera" color="purple" hide-details></v-file-input>
                            <v-textarea v-else-if="field.type === 'textarea'" :label="field.label + (field.isRequired ? ' *' : '')" variant="outlined" density="comfortable" rows="2" color="purple" hide-details></v-textarea>
                            <v-select v-else-if="['select', 'multiselect'].includes(field.type)" :label="field.label + (field.isRequired ? ' *' : '')" :items="['Fulano (Exemplo DB)', 'Ciclano (Exemplo DB)']" variant="outlined" density="comfortable" color="purple" hide-details></v-select>
                            <v-checkbox v-else-if="field.type === 'boolean'" :label="field.label + (field.isRequired ? ' *' : '')" color="purple" density="compact" hide-details></v-checkbox>
                            <v-text-field v-else :label="field.label + (field.isRequired ? ' *' : '')" :type="field.type === 'number' ? 'number' : (field.type === 'date' ? 'date' : 'text')" variant="outlined" density="comfortable" color="purple" hide-details></v-text-field>
                         </div>

                         <div class="d-flex justify-end mt-6 gap-2 pt-4 border-t">
                            <v-btn variant="outlined" color="grey" class="font-weight-bold">Cancelar</v-btn>
                            <v-btn variant="flat" color="purple" class="font-weight-bold btn-3d text-white">Confirmar Operação</v-btn>
                         </div>
                      </v-card>
                   </v-col>
                </v-row>
             </v-window-item>

             <v-window-item value="logic" v-if="selectedNode.type === 'DECISION'">
                <v-btn-toggle v-model="(selectedNode.data as any).mode" mandatory color="pink" class="mb-4 w-100 btn-3d" variant="outlined" density="compact">
                   <v-btn value="auto" class="flex-grow-1 font-weight-bold text-caption">Auto (If/Else)</v-btn>
                   <v-btn value="manual" class="flex-grow-1 font-weight-bold text-caption">Manual (Botões)</v-btn>
                </v-btn-toggle>

                <v-text-field v-model="(selectedNode.data as any).triggerStatus" label="Status Acionador (DB_STATUS)" placeholder="ex: in_production" variant="outlined" density="comfortable" color="pink" class="font-mono text-caption font-weight-bold mb-4" persistent-hint hint="Quando o item chegar neste status, a decisão será ativada na tela."></v-text-field>

                <template v-if="(selectedNode.data as any).mode !== 'manual'">
                   <v-alert color="pink" variant="tonal" class="mb-5 text-caption lh-1-2 border font-weight-medium" density="compact">O item testará a primeira regra. Se for verdadeira, sairá pelo fio verde. Se não, testa a segunda (amarela). Se tudo falhar, sai pela vermelha.</v-alert>

                   <v-card class="pa-4 border-2 shadow-sm mb-4" style="border-color: #4CAF50 !important;" :class="isLight ? 'bg-white' : 'bg-grey-darken-3'">
                      <h4 class="text-success mb-3 font-weight-black d-flex align-center gap-2"><v-icon>mdi-arrow-right-bold-circle</v-icon> Rota 1 (Fio Verde)</h4>
                      <v-select v-model="(selectedNode.data as any).rule1.field" :items="availableFields" label="Qual campo da OP analisar?" variant="outlined" density="compact" color="success" class="mb-2"></v-select>
                      <v-row dense>
                         <v-col cols="6"><v-select v-model="(selectedNode.data as any).rule1.operator" :items="availableOperators" label="Critério" variant="outlined" density="compact" color="success"></v-select></v-col>
                         <v-col cols="6"><v-text-field v-model="(selectedNode.data as any).rule1.value" label="Valor Esperado" variant="outlined" density="compact" color="success"></v-text-field></v-col>
                      </v-row>
                   </v-card>

                   <v-card class="pa-4 border-2 shadow-sm mb-4" style="border-color: #FF9800 !important;" :class="isLight ? 'bg-white' : 'bg-grey-darken-3'">
                      <h4 class="text-warning mb-3 font-weight-black d-flex align-center gap-2"><v-icon>mdi-arrow-down-bold-circle</v-icon> Rota 2 (Fio Amarelo)</h4>
                      <v-select v-model="(selectedNode.data as any).rule2.field" :items="availableFields" label="Qual campo da OP analisar?" variant="outlined" density="compact" color="warning" class="mb-2"></v-select>
                      <v-row dense>
                         <v-col cols="6"><v-select v-model="(selectedNode.data as any).rule2.operator" :items="availableOperators" label="Critério" variant="outlined" density="compact" color="warning"></v-select></v-col>
                         <v-col cols="6"><v-text-field v-model="(selectedNode.data as any).rule2.value" label="Valor Esperado" variant="outlined" density="compact" color="warning"></v-text-field></v-col>
                      </v-row>
                   </v-card>

                   <v-card class="pa-4 border-2 shadow-sm" style="border-color: #F44336 !important;" :class="isLight ? 'bg-red-lighten-5' : 'bg-red-darken-4'">
                      <h4 class="text-error mb-2 font-weight-black d-flex align-center gap-2"><v-icon>mdi-arrow-up-bold-circle</v-icon> Rota 3 (Fio Vermelho)</h4>
                      <p class="text-caption mb-0 font-weight-bold">Se as regras de cima falharem, o item é jogado nesta direção automaticamente.</p>
                   </v-card>
                </template>
                <template v-else>
                   <v-alert color="pink" variant="tonal" class="text-caption font-weight-medium border" density="compact">
                       No modo Manual, o Motor pausará o item e exibirá todas as conexões que saem deste nó como múltiplos botões na tela para o operador escolher o caminho. Conecte os botões ou formulários nas saídas deste nó!
                   </v-alert>
                </template>
             </v-window-item>

             <v-window-item value="rework" v-if="selectedNode.type === 'REWORK'">
                <v-alert color="error" variant="tonal" class="text-caption mb-5 lh-1-2 border font-weight-medium" density="compact">O nó de Retrabalho (Erro) força o operador a explicar o defeito. O motor marcará a OP com uma tag vermelha e a devolverá.</v-alert>

                <v-card class="pa-4 border-thin shadow-sm mb-6 rounded-lg" :class="isLight ? 'bg-red-lighten-5 border-red-lighten-4' : 'bg-red-darken-4 border-red-darken-2'">
                   <v-switch v-model="(selectedNode.data as any).requireJustification" label="Obrigar Justificativa em Texto?" color="error" density="compact" hide-details class="mb-2 font-weight-bold"></v-switch>
                   <v-switch v-model="(selectedNode.data as any).requireAttachment" label="Obrigar Anexo (Foto da Falha)?" color="error" density="compact" hide-details class="font-weight-bold"></v-switch>
                </v-card>

                <h4 class="text-subtitle-2 font-weight-black text-uppercase mb-2 text-error">Devolução no Banco de Dados</h4>
                <v-text-field v-model="(selectedNode.data as any).targetStatus" label="Gravar qual DB_STATUS na OP após o erro?" placeholder="ex: waiting_print_rework" variant="outlined" density="comfortable" class="font-mono mt-2" color="error"></v-text-field>
                <p class="text-[10px] mt-1 opacity-70">Nota: Ligue o fio vermelho inferior do Retrabalho diretamente à etapa do passado para a qual o item deve voltar fisicamente no Kanban.</p>
             </v-window-item>

          </v-window>
        </div>
      </aside>
      </v-slide-x-reverse-transition>

      <v-slide-x-reverse-transition>
      <aside v-if="selectedEdge && viewMode === 'flowchart'" class="sidebar-properties enterprise-inspector border-l d-flex flex-column z-30 shadow-xl transition-all" style="width: 360px;"
             :class="isLight ? 'bg-white border-grey-lighten-2' : 'bg-grey-darken-4 border-grey-darken-2'">

        <div class="pa-5 border-b d-flex justify-space-between align-start position-relative overflow-hidden"
             :class="selectedEdge.isJump ? 'bg-amber-darken-4 text-white' : (selectedEdge.condition === 'fail' ? 'bg-red-darken-4 text-white' : (['rule1', 'success'].includes(selectedEdge.condition as string) ? 'bg-green-darken-4 text-white' : (selectedEdge.condition === 'rule2' ? 'bg-orange-darken-4 text-white' : 'bg-indigo-darken-4 text-white')))">
          <div class="d-flex align-center gap-4 z-10">
             <v-avatar size="48" class="elevation-4 text-white border border-white" :color="selectedEdge.isJump ? 'amber-darken-2' : (selectedEdge.condition === 'fail' ? 'red-darken-2' : (['rule1', 'success'].includes(selectedEdge.condition as string) ? 'green-darken-2' : 'indigo-darken-2'))">
                <v-icon size="24">{{ selectedEdge.isJump ? 'mdi-debug-step-over' : 'mdi-vector-polyline' }}</v-icon>
             </v-avatar>
             <div class="d-flex flex-column">
                <h3 class="text-h6 font-weight-black text-uppercase lh-1 mb-1">{{ selectedEdge.isJump ? 'Fio de Atalho' : 'Fio Condutor' }}</h3>
                <v-chip size="x-small" color="white" variant="outlined" class="font-weight-bold px-2 align-self-start text-white text-uppercase tracking-widest">Sentido do Motor</v-chip>
             </div>
          </div>
          <v-btn icon="mdi-close" size="small" variant="text" color="white" class="z-10" @click="selectedEdgeId = null"></v-btn>
          <div class="absolute top-0 right-0 w-50 h-100 opacity-10" style="background: linear-gradient(90deg, transparent, #fff);"></div>
        </div>

        <div class="flex-grow-1 overflow-y-auto pa-6 custom-scrollbar">
           <v-card v-if="currentContextId === null" class="pa-4 border-thin shadow-sm mb-6 rounded-lg" :class="isLight ? 'bg-amber-lighten-5 border-amber-lighten-3' : 'bg-amber-darken-4 border-amber-darken-2'">
              <v-switch v-model="selectedEdge.isJump" label="Este é um Atalho Mágico (Pulo)?" color="warning" class="font-weight-black text-amber-darken-4" hide-details></v-switch>
              <p class="text-[10px] mt-2 mb-0 opacity-80 leading-tight">Ao ligar colunas distantes, o Motor autorizará que usuários com permissão arrastem o card diretamente para o destino pulando abas do meio.</p>
           </v-card>

           <template v-if="selectedEdge.isJump">
              <h4 class="text-subtitle-2 font-weight-black text-uppercase mb-4 d-flex align-center gap-2 text-warning"><v-icon size="18">mdi-shield-key-outline</v-icon> Quem ou O Que pode pular?</h4>
              <v-select v-model="(selectedEdge as any).jumpRule.field" :items="availableFields" label="Campo Analisado na OP" variant="outlined" density="compact" color="warning" class="mb-2"></v-select>
              <v-select v-model="(selectedEdge as any).jumpRule.operator" :items="availableOperators" label="Critério" variant="outlined" density="compact" color="warning" class="mb-2"></v-select>
              <v-text-field v-model="(selectedEdge as any).jumpRule.value" label="Valor Exigido" variant="outlined" density="compact" color="warning" class="mb-4"></v-text-field>

              <v-autocomplete v-model="selectedEdge.jumpRoles" :items="customRolesOptions" item-title="name" item-value="id" label="Cargos Autorizados a Arrastar (Vazio=Todos)" multiple chips closable-chips variant="outlined" density="comfortable" color="warning"></v-autocomplete>
           </template>

           <template v-else>
              <h4 class="text-subtitle-2 font-weight-black text-uppercase mb-4 d-flex align-center gap-2"><v-icon size="18">mdi-information-outline</v-icon> Rota Lógica</h4>
              <v-alert :color="selectedEdge.condition === 'fail' ? 'error' : (['rule1', 'success'].includes(selectedEdge.condition as string) ? 'success' : (selectedEdge.condition === 'rule2' ? 'warning' : 'indigo'))" variant="tonal" class="text-caption mb-5 lh-1-2 font-weight-bold" density="compact" border="start">
                {{ selectedEdge.condition === 'fail' ? 'Linha Vermelha de Erro ou Senão.' : (['rule1', 'success'].includes(selectedEdge.condition as string) ? 'Linha Verde de Sucesso.' : (selectedEdge.condition === 'rule2' ? 'Linha Amarela (Condição B).' : 'Linha Linear Padrão e Obrigatória.')) }}
              </v-alert>
           </template>

           <v-divider class="my-6 border-transparent"></v-divider>
           <v-btn color="error" block size="large" variant="flat" prepend-icon="mdi-scissors-cutting" class="font-weight-black btn-3d shadow-lg mt-4" @click="deleteEdge(selectedEdge.id)">Desconectar Fio com Tesoura</v-btn>
        </div>
      </aside>
      </v-slide-x-reverse-transition>

    </div>

    <PcpWorkflowWizard v-model="isWizardOpen" />

  </div>
</template>

<script setup lang="ts">
import PcpWorkflowWizard from '@/components/production/PcpWorkflowWizard.vue';
import { ref, reactive, computed, onMounted, onUnmounted } from 'vue';
import { format } from 'date-fns';
import draggable from 'vuedraggable';
import { v4 as uuidv4 } from 'uuid';
import { useDynamicPcpStore } from '@/stores/dynamicPcpStore';
import { useThemeStore } from '@/stores/theme';
import type { WorkflowNode, WorkflowEdge, NodeType, NodeData, SourceNodeData, StageNodeData, FormNodeData, OutputNodeData, PcpWorkflow } from '@/types/dynamicPcp';
import { useAppStore } from '@/stores/app';
import { supabase } from '@/api/supabase';

type LocalNode = WorkflowNode & { parentId?: string | null };
interface LocalEdge extends WorkflowEdge { condition?: 'default' | 'rule1' | 'rule2' | 'fail' | 'success'; isJump?: boolean; jumpRoles?: string[]; jumpRule?: {field: string, operator: string, value: string}; }

const isWizardOpen = ref(false);
const store = useDynamicPcpStore();
const appStore = useAppStore();
const themeStore = useThemeStore();

const isLight = computed(() => themeStore.currentMode === 'light');

const viewMode = ref<'flowchart' | 'structure'>('flowchart');
const propertiesTab = ref('basic');
const workspaceRef = ref<HTMLElement | null>(null);
const currentMotorId = ref<string | null>(null);
const customRolesOptions = ref<{ id: string, name: string }[]>([]);

const currentContextId = ref<string | null>(null);
const isDiving = ref(false);

const gridStyle = computed(() => {
  const size = 48 * transform.scale;
  return {
    '--grid-position-x': `${transform.x}px`,
    '--grid-position-y': `${transform.y}px`,
    '--grid-size': `${size}px`,
  };
});

const currentContextStageName = computed(() => {
    if (!currentContextId.value) return '';
    const stage = nodes.value.find(n => n.id === currentContextId.value);
    return stage ? (stage.data.name || (stage.data as any).title) : '';
});

const diveIntoStage = (stageId: string) => {
    isDiving.value = true;
    setTimeout(() => {
        currentContextId.value = stageId;
        selectedNodeId.value = null;
        inspectedNodeId.value = null;
        selectedEdgeId.value = null;
        resetView();
        isDiving.value = false;
    }, 250);
};

const goUpToMacro = () => {
    isDiving.value = true;
    setTimeout(() => {
        currentContextId.value = null;
        selectedNodeId.value = null;
        inspectedNodeId.value = null;
        selectedEdgeId.value = null;
        resetView();
        isDiving.value = false;
    }, 250);
};

const visibleNodes = computed(() => {
    if (currentContextId.value === null) {
        return nodes.value.filter(n => !n.parentId);
    } else {
        return nodes.value.filter(n => n.parentId === currentContextId.value);
    }
});

const visibleEdges = computed(() => {
    return edges.value.filter(e => {
        const fromNode = nodes.value.find(n => n.id === e.fromId);
        const toNode = nodes.value.find(n => n.id === e.toId);
        const expectedParent = currentContextId.value;
        return (fromNode?.parentId || null) === expectedParent && (toNode?.parentId || null) === expectedParent;
    });
});

const orderedStagesForPreview = computed(() => {
    const stages = nodes.value.filter(n => n.type === 'STAGE' && !n.parentId);
    return stages.sort((a, b) => ((a.data as StageNodeData).order || 0) - ((b.data as StageNodeData).order || 0));
});

const getNodesForStagePreview = (stageId: string) => {
    return nodes.value.filter(n => n.parentId === stageId);
};

const nodePalette = [
  { type: 'SOURCE' as NodeType, label: 'Origem', desc: 'Tabela do Banco', icon: 'mdi-database-export', color: '#607D8B', borderRadius: '12px', w: 200, h: 90 },
  { type: 'STAGE' as NodeType, label: 'Aba Kanban', desc: 'Coluna do Painel', icon: 'mdi-view-column', color: '#3F51B5', borderRadius: '12px', w: 220, h: 100 },
  { type: 'OUTPUT' as NodeType, label: 'Fim de Fluxo', desc: 'Encerra o item', icon: 'mdi-flag-checkered', color: '#4CAF50', borderRadius: '12px', w: 160, h: 90 },
  { type: 'ENTRY' as NodeType, label: 'Entrada da Aba', desc: 'Início do Micro-Fluxo', icon: 'mdi-login-variant', color: '#4CAF50', borderRadius: '40px', w: 180, h: 90 },
  { type: 'DECISION' as NodeType, label: 'Decisão', desc: 'Bifurcação/Múltiplos', icon: 'mdi-call-split', color: '#E91E63', borderRadius: '40px', w: 160, h: 100 },
  { type: 'STEP' as NodeType, label: 'Passo Interno', desc: 'Retém o item na Aba', icon: 'mdi-gesture-tap-button', color: '#00ACC1', borderRadius: '40px', w: 180, h: 90 },
  { type: 'TRANSFER' as NodeType, label: 'Botão de Saída', desc: 'Avança para Próxima Aba', icon: 'mdi-page-next-outline', color: '#607D8B', borderRadius: '40px', w: 180, h: 90 },
  { type: 'FORM' as NodeType, label: 'Formulário', desc: 'Pede dados extras', icon: 'mdi-form-textbox', color: '#9C27B0', borderRadius: '12px', w: 180, h: 90 },
  { type: 'REWORK' as NodeType, label: 'Retrabalho', desc: 'Devolve com erro', icon: 'mdi-alert-octagon', color: '#F44336', borderRadius: '12px', w: 180, h: 90 },
];

const currentPalette = computed(() => {
    if (currentContextId.value === null) {
        return nodePalette.filter(p => ['SOURCE', 'STAGE', 'DECISION', 'OUTPUT'].includes(p.type));
    } else {
        return nodePalette.filter(p => ['ENTRY', 'STEP', 'TRANSFER', 'FORM', 'REWORK', 'DECISION', 'OUTPUT'].includes(p.type));
    }
});

// AQUI: employees_mj configurado.
const dbTablesOptions = [{ label: 'Pedidos (order_items)', value: 'order_items' }, { label: 'Colaboradores (employees_mj)', value: 'employees_mj' }, { label: 'Clientes', value: 'customers_mj' }, { label: 'Máquinas', value: 'production_machines' }];
const formFieldTypes = [{ label: 'Texto Curto', value: 'text' }, { label: 'Texto Longo', value: 'textarea' }, { label: 'Dropdown', value: 'select' }, { label: 'Checkbox', value: 'boolean' }, { label: 'Upload Arquivo', value: 'file' }, { label: 'Data', value: 'date' }, { label: 'Número', value: 'number' }];
const availableFields = ['status', 'priority', 'quantity_meters', 'fabric_type', 'machine_id', 'is_urgent'];
const availableOperators = ['Igual a (==)', 'Diferente de (!=)', 'Contém', 'Maior que (>)', 'Menor que (<)'];
const iconOptions = [{ title: 'Seta Avanço', value: 'mdi-arrow-right-bold-circle' }, { title: 'Play (Iniciar)', value: 'mdi-play-circle' }, { title: 'Sair / Avançar', value: 'mdi-page-next-outline' }, { title: 'Cesta', value: 'mdi-basket-outline' }, { title: 'Bico (Imprimir)', value: 'mdi-printer-3d-nozzle' }, { title: 'Fogo (Calandra)', value: 'mdi-fire' }, { title: 'Check', value: 'mdi-check-circle' }, { title: 'Caminhão', value: 'mdi-truck-check' }, { title: 'Config (Ajuste)', value: 'mdi-cog' }];

const getNodeFriendlyTypeName = (type: string) => { const map: Record<string, string> = { SOURCE: 'Database', STAGE: 'Aba Macro', ENTRY: 'Ponto de Entrada', STEP: 'Passo Interno', TRANSFER: 'Avanço / Saída', FORM: 'Modal de Entrada', DECISION: 'Bifurcação', REWORK: 'Fluxo de Retorno', OUTPUT: 'Terminal' }; return map[type] || type; };
const getNodeExplanation = (type: string) => { const map: Record<string, string> = { SOURCE: 'Ponto de partida SQL.', STAGE: 'Cria uma coluna gigante no Kanban.', ENTRY: 'Onde o item "pousa" ao chegar nesta aba vindo do fluxo macro.', STEP: 'Representa um clique do usuário e muda o DB_STATUS do item, segurando-o nesta aba.', TRANSFER: 'Muda o DB_STATUS, mas NÃO conta o item nesta aba. Ele será sugado pela próxima coluna.', FORM: 'Interrompe a rota pedindo dados no modal.', DECISION: 'Ramifica as rotas logicamente ou cria múltiplos botões (Modo Manual).', REWORK: 'Força justificativa e joga no fio vermelho.', OUTPUT: 'Finaliza o processo produtivo desta linha.' }; return map[type] || ''; };
const getNodeIcon = (type: string) => nodePalette.find(p => p.type === type)?.icon || 'mdi-help';
const getNodeBorderRadius = (type: string) => nodePalette.find(p => p.type === type)?.borderRadius || '8px';

const nodes = ref<LocalNode[]>([]);
const edges = ref<LocalEdge[]>([]);
const selectedNodeId = ref<string | null>(null);
const inspectedNodeId = ref<string | null>(null);
const selectedEdgeId = ref<string | null>(null);

const selectedNode = computed(() => nodes.value.find(n => n.id === inspectedNodeId.value));
const selectedEdge = computed(() => edges.value.find(e => e.id === selectedEdgeId.value));
const isCurrentMotorActive = computed(() => store.activeWorkflow?.id === currentMotorId.value && store.activeWorkflow?.is_active);

const drawingEdge = reactive({ active: false, sourceNodeId: null as string | null, condition: 'default' as 'default'|'rule1'|'rule2'|'fail'|'success', startX: 0, startY: 0, currentX: 0, currentY: 0 });
const transform = reactive({ x: 0, y: 0, scale: 1 });
let isPanning = false; let startPan = { x: 0, y: 0 };
let isDraggingNode = false; let draggedNodeId: string | null = null; let nodeOffset = { x: 0, y: 0 };

onMounted(async () => {
  await store.fetchWorkflows();
  if (store.activeWorkflow) { currentMotorId.value = store.activeWorkflow.id; loadIntoWorkspace(store.activeWorkflow); }
  else if (store.workflows.length > 0) { currentMotorId.value = store.workflows[0].id; loadIntoWorkspace(store.workflows[0]); }

  fetchCustomRoles();

  window.addEventListener('mousemove', handleGlobalMouseMove);
  window.addEventListener('mouseup', handleGlobalMouseUp);
});
onUnmounted(() => { window.removeEventListener('mousemove', handleGlobalMouseMove); window.removeEventListener('mouseup', handleGlobalMouseUp); });

const fetchCustomRoles = async () => {
    try {
        const { data, error } = await supabase.from('custom_roles').select('id, name');
        if (!error && data) {
            customRolesOptions.value = data;
        } else {
            customRolesOptions.value = [
                { id: 'admin', name: 'Administrador' }, { id: 'manager', name: 'Gerente' },
                { id: 'pcp_operator', name: 'PCP' }, { id: 'designer', name: 'Design' },
                { id: 'printer', name: 'Impressor' }, { id: 'seller', name: 'Vendedor' }
            ];
        }
    } catch (e) {
        console.warn('Tabela custom_roles não encontrada.', e);
    }
};

const onMotorSelect = async (id: string) => { const motor = store.workflows.find(w => w.id === id); if (motor) loadIntoWorkspace(motor); };
const createNewMotor = () => { nodes.value = []; edges.value = []; selectedNodeId.value = null; inspectedNodeId.value = null; currentContextId.value = null; const newId = uuidv4(); const newWf: PcpWorkflow = { id: newId, name: `Blueprint ${format(new Date(), 'dd/MM HH:mm')}`, version: '2.0.0', is_active: false, nodes: [], edges: [] }; store.workflows.push(newWf); currentMotorId.value = newId; resetView(); };
const deleteCurrentMotor = async () => { if (!currentMotorId.value) return; if(confirm("Excluir definitivamente?")) { await supabase.from('pcp_workflows').delete().eq('id', currentMotorId.value); await store.fetchWorkflows(); if (store.workflows.length > 0) { currentMotorId.value = store.workflows[0].id; loadIntoWorkspace(store.workflows[0]); } else { createNewMotor(); } } };
const activateMotor = async () => { if (!currentMotorId.value) return; await saveCurrentWorkflow(); await store.setActiveWorkflow(currentMotorId.value); };
const loadIntoWorkspace = (workflow: PcpWorkflow) => { nodes.value = JSON.parse(JSON.stringify(workflow.nodes)); edges.value = JSON.parse(JSON.stringify(workflow.edges)); currentContextId.value = null; selectedNodeId.value = null; inspectedNodeId.value = null; selectedEdgeId.value = null; setTimeout(() => { nodes.value.forEach(n => updateEdgesForNode(n.id)); }, 100); };
const saveCurrentWorkflow = async () => { if (!currentMotorId.value) return; const wf = store.workflows.find(w => w.id === currentMotorId.value); if (wf) { wf.nodes = nodes.value as WorkflowNode[]; wf.edges = edges.value; await store.saveWorkflow(wf); } };

const autoGenerateRealFlow = () => {
   if(nodes.value.length > 0 && !confirm("O quadro atual será apagado. Aplicar Seed Total?")) return;
   nodes.value = []; edges.value = []; currentContextId.value = null;

   const sourceId = uuidv4();
   nodes.value.push({ id: sourceId, parentId: null, type: 'SOURCE', ui_x: 50, ui_y: 300, width: 200, height: 90, color: '#607D8B', data: { name: 'OPs do Sistema', tableName: 'order_items', entryConditions: ["status != 'delivered'"] } as any });

   const stages = [
      { id: uuidv4(), title: 'Design', color: '#2196F3', x: 350, mappedStatuses: ['design_pending', 'customer_approval', 'approved_by_seller', 'approved_by_designer'], chipLabel: 'Arte' },
      { id: uuidv4(), title: 'PCP Geral', color: '#9C27B0', x: 650, mappedStatuses: ['design_released'], chipLabel: 'PCP' },
      { id: uuidv4(), title: 'Separação', color: '#00BCD4', x: 950, mappedStatuses: ['waiting_separation', 'in_separation'], chipLabel: 'Estoque' },
      { id: uuidv4(), title: 'Impressão', color: '#FFC107', x: 1250, mappedStatuses: ['waiting_print', 'waiting_print_rework', 'printing'], chipLabel: 'Plotter' },
      { id: uuidv4(), title: 'Calandra', color: '#FF9800', x: 1550, mappedStatuses: ['printed', 'waiting_calandra', 'in_calandra', 'in_production'], chipLabel: 'Prensa' },
      { id: uuidv4(), title: 'Expedição', color: '#4CAF50', x: 1850, mappedStatuses: ['waiting_release', 'ready_for_delivery', 'completed'], chipLabel: 'Logística', isFinal: true }
   ];

   let prevMacroId = sourceId;
   stages.forEach((st, idx) => {
      nodes.value.push({ id: st.id, parentId: null, type: 'STAGE', ui_x: st.x, ui_y: 300, width: 220, height: 100, color: st.color, data: { name: st.title, title: st.title, order: idx+1, slaHours: 24, mappedStatuses: st.mappedStatuses, permissions: { viewCustomRoles: [], operateCustomRoles: [] }, isFinalStage: st.isFinal || false, chipLabel: st.chipLabel } as any });
      edges.value.push({ id: uuidv4(), fromId: prevMacroId, toId: st.id, condition: 'default', startX: 0, startY: 0, endX: 0, endY: 0 });
      prevMacroId = st.id;
   });

   const getStageId = (title: string) => stages.find(s => s.title === title)!.id;

   // ================= MICRO: DESIGN =================
   const stDesign = getStageId('Design');
   const d_en1 = uuidv4();
   nodes.value.push({ id: d_en1, parentId: stDesign, type: 'ENTRY', ui_x: 50, ui_y: 200, width: 180, height: 90, color: '#4CAF50', data: { name: 'Entrada Design', dbStatus: 'design_pending', chipLabel: 'Aguardando Arte' } as any });
   const d_st1 = uuidv4();
   nodes.value.push({ id: d_st1, parentId: stDesign, type: 'STEP', ui_x: 300, ui_y: 200, width: 180, height: 90, color: '#2196F3', data: { name: 'Iniciar Criação', dbStatus: 'in_design', buttonText: 'Desenhar', icon: 'mdi-palette', chipLabel: 'Criando Arte' } as any });
   edges.value.push({ id: uuidv4(), fromId: d_en1, toId: d_st1, condition: 'default', startX:0, startY:0, endX:0, endY:0 });
   const d_tr1 = uuidv4();
   nodes.value.push({ id: d_tr1, parentId: stDesign, type: 'TRANSFER', ui_x: 600, ui_y: 200, width: 180, height: 90, color: '#9C27B0', data: { name: 'Liberar PCP', targetStatus: 'design_released', buttonText: 'Aprovar e Liberar', icon: 'mdi-check-all', chipLabel: 'Aprovado' } as any });
   edges.value.push({ id: uuidv4(), fromId: d_st1, toId: d_tr1, condition: 'default', startX:0, startY:0, endX:0, endY:0 });

   // ================= MICRO: PCP =================
   const stPcp = getStageId('PCP Geral');
   const p_en1 = uuidv4();
   nodes.value.push({ id: p_en1, parentId: stPcp, type: 'ENTRY', ui_x: 50, ui_y: 300, width: 180, height: 90, color: '#4CAF50', data: { name: 'Entrada PCP', dbStatus: 'design_released', chipLabel: 'Aguardando PCP' } as any });
   const p_tr1 = uuidv4();
   nodes.value.push({ id: p_tr1, parentId: stPcp, type: 'TRANSFER', ui_x: 350, ui_y: 300, width: 180, height: 90, color: '#00BCD4', data: { name: 'Liberar Confecção', targetStatus: 'waiting_separation', buttonText: 'Gerar Ficha', icon: 'mdi-file-document', chipLabel: 'Ficha Pronta' } as any });
   edges.value.push({ id: uuidv4(), fromId: p_en1, toId: p_tr1, condition: 'default', startX:0, startY:0, endX:0, endY:0 });

   // ================= MICRO: SEPARAÇÃO =================
   const stSep = getStageId('Separação');
   const s_en1 = uuidv4();
   nodes.value.push({ id: s_en1, parentId: stSep, type: 'ENTRY', ui_x: 50, ui_y: 300, width: 180, height: 90, color: '#4CAF50', data: { name: 'Fila Separação', dbStatus: 'waiting_separation', chipLabel: 'Aguardando Tecido' } as any });
   const s_st1 = uuidv4();
   nodes.value.push({ id: s_st1, parentId: stSep, type: 'STEP', ui_x: 300, ui_y: 300, width: 180, height: 90, color: '#00ACC1', data: { name: 'Separar Rolos', dbStatus: 'in_separation', buttonText: 'Iniciar Corte', icon: 'mdi-content-cut', chipLabel: 'Cortando' } as any });
   edges.value.push({ id: uuidv4(), fromId: s_en1, toId: s_st1, condition: 'default', startX:0, startY:0, endX:0, endY:0 });
   const s_tr1 = uuidv4();
   nodes.value.push({ id: s_tr1, parentId: stSep, type: 'TRANSFER', ui_x: 600, ui_y: 300, width: 180, height: 90, color: '#FFC107', data: { name: 'Mandar p/ Plotter', targetStatus: 'waiting_print', buttonText: 'Finalizar', icon: 'mdi-printer', chipLabel: 'Separado' } as any });
   edges.value.push({ id: uuidv4(), fromId: s_st1, toId: s_tr1, condition: 'default', startX:0, startY:0, endX:0, endY:0 });

   // ================= MICRO: IMPRESSÃO =================
   const stImp = getStageId('Impressão');
   const i_en1 = uuidv4();
   nodes.value.push({ id: i_en1, parentId: stImp, type: 'ENTRY', ui_x: 50, ui_y: 200, width: 180, height: 90, color: '#4CAF50', data: { name: 'Fila Plotter', dbStatus: 'waiting_print', chipLabel: 'Fila Impressão' } as any });
   const i_en2 = uuidv4();
   nodes.value.push({ id: i_en2, parentId: stImp, type: 'ENTRY', ui_x: 50, ui_y: 400, width: 180, height: 90, color: '#F44336', data: { name: 'Fila Retrabalho', dbStatus: 'waiting_print_rework', chipLabel: 'Refazer Impressão' } as any });

   const i_st1 = uuidv4();
   nodes.value.push({ id: i_st1, parentId: stImp, type: 'STEP', ui_x: 350, ui_y: 300, width: 180, height: 90, color: '#FFB300', data: { name: 'Imprimir Papel', dbStatus: 'printing', buttonText: 'Bipar Plotter', icon: 'mdi-printer-3d-nozzle', chipLabel: 'Imprimindo' } as any });
   edges.value.push({ id: uuidv4(), fromId: i_en1, toId: i_st1, condition: 'default', startX:0, startY:0, endX:0, endY:0 });
   edges.value.push({ id: uuidv4(), fromId: i_en2, toId: i_st1, condition: 'default', startX:0, startY:0, endX:0, endY:0 });

   const i_tr1 = uuidv4();
   nodes.value.push({ id: i_tr1, parentId: stImp, type: 'TRANSFER', ui_x: 650, ui_y: 300, width: 180, height: 90, color: '#FF9800', data: { name: 'Mandar p/ Prensa', targetStatus: 'printed', buttonText: 'Concluir Impressão', icon: 'mdi-check-circle', chipLabel: 'Papel Pronto' } as any });
   edges.value.push({ id: uuidv4(), fromId: i_st1, toId: i_tr1, condition: 'default', startX:0, startY:0, endX:0, endY:0 });

   // ================= MICRO: CALANDRA =================
   const stCal = getStageId('Calandra');
   const c_en1 = uuidv4();
   nodes.value.push({ id: c_en1, parentId: stCal, type: 'ENTRY', ui_x: 50, ui_y: 300, width: 180, height: 90, color: '#4CAF50', data: { name: 'Fila Prensa', dbStatus: 'printed', chipLabel: 'Aguardando Calandra' } as any });

   const c_st1 = uuidv4();
   nodes.value.push({ id: c_st1, parentId: stCal, type: 'STEP', ui_x: 300, ui_y: 300, width: 180, height: 90, color: '#FB8C00', data: { name: 'Preparar Máquina', dbStatus: 'waiting_calandra', buttonText: 'Pegar Rolo', icon: 'mdi-cog', allowBatch: false, chipLabel: 'Preparação' } as any });
   edges.value.push({ id: uuidv4(), fromId: c_en1, toId: c_st1, condition: 'default', startX:0, startY:0, endX:0, endY:0 });

   const c_form1 = uuidv4();
   nodes.value.push({ id: c_form1, parentId: stCal, type: 'FORM', ui_x: 550, ui_y: 300, width: 180, height: 90, color: '#9C27B0', data: { name: 'Ligar Máquina', targetStatus: 'in_production', chipLabel: 'Calandrando', fields: [ { id: uuidv4(), name: 'machine_id', label: 'Qual Máquina?', type: 'select', isRequired: true, dataSource: 'production_machines', machineTypeFilter: 'calandra' }, { id: uuidv4(), name: 'operator_id', label: 'Quem vai operar?', type: 'select', isRequired: true, dataSource: 'employees_mj' } ] } as any });
   edges.value.push({ id: uuidv4(), fromId: c_st1, toId: c_form1, condition: 'default', startX:0, startY:0, endX:0, endY:0 });

   const c_dec1 = uuidv4();
   nodes.value.push({ id: c_dec1, parentId: stCal, type: 'DECISION', ui_x: 850, ui_y: 300, width: 160, height: 100, color: '#E91E63', data: { name: 'Ações de Produção', mode: 'manual', triggerStatus: 'in_production', chipLabel: 'Avaliando' } as any });
   edges.value.push({ id: uuidv4(), fromId: c_form1, toId: c_dec1, condition: 'default', startX:0, startY:0, endX:0, endY:0 });

   const c_trOut = uuidv4();
   nodes.value.push({ id: c_trOut, parentId: stCal, type: 'TRANSFER', ui_x: 1150, ui_y: 200, width: 180, height: 90, color: '#4CAF50', data: { name: 'Enviar Expedição', targetStatus: 'waiting_release', buttonText: 'Liberar p/ Expedição', icon: 'mdi-truck-check', chipLabel: 'Liberado' } as any });
   edges.value.push({ id: uuidv4(), fromId: c_dec1, toId: c_trOut, condition: 'rule1', startX:0, startY:0, endX:0, endY:0 });

   const c_rework1 = uuidv4();
   nodes.value.push({ id: c_rework1, parentId: stCal, type: 'REWORK', ui_x: 1150, ui_y: 400, width: 180, height: 90, color: '#F44336', data: { name: 'Erro de Impressão', requireJustification: true, requireAttachment: true, targetStatus: 'waiting_print_rework', targetStageName: 'Impressão', chipLabel: 'Falhou' } as any });
   edges.value.push({ id: uuidv4(), fromId: c_dec1, toId: c_rework1, condition: 'fail', startX:0, startY:0, endX:0, endY:0 });

   // ================= MICRO: EXPEDIÇÃO =================
   const stExp = getStageId('Expedição');
   const e_en1 = uuidv4();
   nodes.value.push({ id: e_en1, parentId: stExp, type: 'ENTRY', ui_x: 50, ui_y: 300, width: 180, height: 90, color: '#4CAF50', data: { name: 'Recebidos', dbStatus: 'waiting_release', chipLabel: 'Aguardando Liberação' } as any });
   const e_st1 = uuidv4();
   nodes.value.push({ id: e_st1, parentId: stExp, type: 'STEP', ui_x: 300, ui_y: 300, width: 180, height: 90, color: '#8BC34A', data: { name: 'Embalagem', dbStatus: 'ready_for_delivery', buttonText: 'Embalar', icon: 'mdi-package-variant', chipLabel: 'Pronto Entrega' } as any });
   edges.value.push({ id: uuidv4(), fromId: e_en1, toId: e_st1, condition: 'default', startX:0, startY:0, endX:0, endY:0 });
   const e_out = uuidv4();
   nodes.value.push({ id: e_out, parentId: stExp, type: 'OUTPUT', ui_x: 600, ui_y: 300, width: 180, height: 90, color: '#388E3C', data: { name: 'Despachar OP', finalStatus: 'completed', chipLabel: 'Finalizado' } as any });
   edges.value.push({ id: uuidv4(), fromId: e_st1, toId: e_out, condition: 'default', startX:0, startY:0, endX:0, endY:0 });

   setTimeout(() => { nodes.value.forEach(n => updateEdgesForNode(n.id)); resetView(); transform.scale = 0.5; }, 100);
};

const addFormField = () => { if (selectedNode.value?.type === 'FORM') { if(!(selectedNode.value.data as any).fields) (selectedNode.value.data as any).fields = []; (selectedNode.value.data as any).fields.push({ id: uuidv4(), name: 'novo_campo', label: 'Novo Campo', type: 'text', isRequired: true, dataSource: 'custom' }); } };
const removeFormField = (idx: number) => { if (selectedNode.value?.type === 'FORM') (selectedNode.value.data as any).fields.splice(idx, 1); };

const handleGlobalMouseMove = (e: MouseEvent) => {
  if (isPanning) { transform.x = e.clientX - startPan.x; transform.y = e.clientY - startPan.y; }
  if (isDraggingNode && draggedNodeId && workspaceRef.value) {
      const rect = workspaceRef.value.getBoundingClientRect();
      const node = nodes.value.find(n => n.id === draggedNodeId);
      if (node) {
          node.ui_x = (e.clientX - rect.left - transform.x - nodeOffset.x) / transform.scale;
          node.ui_y = (e.clientY - rect.top - transform.y - nodeOffset.y) / transform.scale;
          updateEdgesForNode(node.id);
      }
  }
  if (drawingEdge.active && workspaceRef.value) {
      const rect = workspaceRef.value.getBoundingClientRect();
      drawingEdge.currentX = (e.clientX - rect.left - transform.x) / transform.scale;
      drawingEdge.currentY = (e.clientY - rect.top - transform.y) / transform.scale;
  }
};
const handleGlobalMouseUp = () => { isPanning = false; isDraggingNode = false; draggedNodeId = null; if (drawingEdge.active) { drawingEdge.active = false; drawingEdge.sourceNodeId = null; } };
const onWorkspaceMouseDown = (e: MouseEvent) => { if (e.button === 1 || e.button === 0) { isPanning = true; startPan = { x: e.clientX - transform.x, y: e.clientY - transform.y }; selectedNodeId.value = null; inspectedNodeId.value = null; selectedEdgeId.value = null; } };
const onWorkspaceWheel = (e: WheelEvent) => { const delta = -e.deltaY * 0.001; let newScale = transform.scale * Math.exp(delta); newScale = Math.min(Math.max(0.3, newScale), 2.5); const rect = workspaceRef.value!.getBoundingClientRect(); const xs = (e.clientX - rect.left - transform.x) / transform.scale; const ys = (e.clientY - rect.top - transform.y) / transform.scale; transform.x = (e.clientX - rect.left) - xs * newScale; transform.y = (e.clientY - rect.top) - ys * newScale; transform.scale = newScale; };
const zoomIn = () => { transform.scale = Math.min(2.5, transform.scale + 0.1); };
const zoomOut = () => { transform.scale = Math.max(0.3, transform.scale - 0.1); };
const resetView = () => { transform.x = 0; transform.y = 0; transform.scale = 1; };

const onDragStart = (e: DragEvent, item: any) => { e.dataTransfer?.setData('application/json', JSON.stringify(item)); };
const onDropNode = (e: DragEvent) => {
  const dataStr = e.dataTransfer?.getData('application/json'); if (!dataStr) return;
  const item = JSON.parse(dataStr); const rect = (e.currentTarget as HTMLElement).getBoundingClientRect();
  const x = (e.clientX - rect.left - transform.x) / transform.scale;
  const y = (e.clientY - rect.top - transform.y) / transform.scale;

  const newNode: LocalNode = { id: uuidv4(), parentId: currentContextId.value, type: item.type, ui_x: x - (item.w / 2), ui_y: y - (item.h / 2), width: item.w, height: item.h, color: item.color, data: getDefaultDataForType(item.type) };
  nodes.value.push(newNode); openNodeInspector(newNode.id); selectedEdgeId.value = null; propertiesTab.value = 'basic';
};

const getDefaultDataForType = (type: string): NodeData => {
  const base = { name: `Novo Elemento`, chipLabel: '' };
  switch(type) {
    case 'SOURCE': return { ...base, name: 'Origem SQL', tableName: 'order_items', entryConditions: [], autoRefreshInterval: 0 } as SourceNodeData;
    case 'STAGE': return { ...base, name: 'Nova Aba', title: 'Aba Vazia', order: 1, slaHours: 0, permissions: { viewCustomRoles: [], operateCustomRoles: [] }, mappedStatuses: [], isFinalStage: false, chipLabel: 'Na Fila' } as any;
    case 'ENTRY': return { ...base, name: 'Ponto de Entrada', dbStatus: '', chipLabel: 'Aguardando' } as any;
    case 'STEP': return { ...base, name: 'Botão de Passo', dbStatus: 'status_interno', buttonText: 'Avançar', icon: 'mdi-play-circle', allowBatch: false, chipLabel: 'Processando' } as any;
    case 'TRANSFER': return { ...base, name: 'Botão de Saída', targetStatus: '', buttonText: 'Avançar Aba', icon: 'mdi-page-next-outline', allowBatch: true } as any;
    case 'FORM': return { ...base, name: 'Formulário', targetStatus: '', fields: [] } as FormNodeData;
    case 'DECISION': return { ...base, name: 'Bifurcação', mode: 'manual', triggerStatus: '', rule1: { field: 'status', operator: 'Igual a (==)', value: '' }, rule2: { field: 'status', operator: 'Igual a (==)', value: '' } } as any;
    case 'REWORK': return { ...base, name: 'Reportar Falha', requireJustification: true, requireAttachment: true, targetStatus: 'erro', targetStageName: '', chipLabel: 'Falha/Erro' } as any;
    case 'OUTPUT': return { ...base, name: 'Fim de Rota', destinationType: 'update_record', finalStatus: '', payloadMappings: {}, chipLabel: 'Concluído' } as OutputNodeData;
    default: return base as any;
  }
};

const onNodeMouseDown = (e: MouseEvent, node: LocalNode) => {
    e.stopPropagation(); selectedNodeId.value = node.id; selectedEdgeId.value = null;
    isDraggingNode = true; draggedNodeId = node.id;
    if (workspaceRef.value) {
        const rect = workspaceRef.value.getBoundingClientRect();
        nodeOffset.x = e.clientX - rect.left - (node.ui_x * transform.scale + transform.x);
        nodeOffset.y = e.clientY - rect.top - (node.ui_y * transform.scale + transform.y);
    }
};

const onNodeDoubleClick = (node: LocalNode) => {
   if (node.type === 'STAGE') { diveIntoStage(node.id); }
};

const openNodeInspector = (id: string, tab: string = 'basic') => {
    selectedNodeId.value = id;
    inspectedNodeId.value = id;
    selectedEdgeId.value = null;
    propertiesTab.value = tab;
};

const closeNodeInspector = () => {
    inspectedNodeId.value = null;
};

const editNodeFromStructure = (id: string) => {
    openNodeInspector(id);
    viewMode.value = 'flowchart';
    propertiesTab.value = 'basic';
    const node = nodes.value.find(n => n.id === id);
    if(node?.parentId) {
        currentContextId.value = node.parentId;
    } else if (node?.type === 'STAGE') {
        currentContextId.value = null;
    }
};

const deleteNode = (id: string) => {
    nodes.value = nodes.value.filter(n => n.id !== id && n.parentId !== id);
    edges.value = edges.value.filter(e => e.fromId !== id && e.toId !== id);
    if (selectedNodeId.value === id) selectedNodeId.value = null;
    if (inspectedNodeId.value === id) inspectedNodeId.value = null;
};

const getNodeCenter = (nodeId: string, portType: 'in' | 'out', condition: 'default'|'rule1'|'rule2'|'success'|'fail' = 'default') => {
  const node = nodes.value.find(n => n.id === nodeId); if (!node) return { x: 0, y: 0 };
  if (portType === 'in') return { x: node.ui_x, y: node.ui_y + (node.height / 2) };
  if (node.type === 'DECISION') {
     if (condition === 'rule1') return { x: node.ui_x + node.width, y: node.ui_y + (node.height / 2) };
     if (condition === 'rule2') return { x: node.ui_x + (node.width / 2), y: node.ui_y + node.height };
     if (condition === 'fail') return { x: node.ui_x + (node.width / 2), y: node.ui_y };
  }
  if (node.type === 'REWORK') {
     if (condition === 'success') return { x: node.ui_x + node.width, y: node.ui_y + (node.height / 2) };
     if (condition === 'fail') return { x: node.ui_x + (node.width / 2), y: node.ui_y + node.height };
  }
  return { x: node.ui_x + node.width, y: node.ui_y + (node.height / 2) };
};

const startEdge = (e: MouseEvent, node: LocalNode, portType: 'in' | 'out', condition: 'default'|'rule1'|'rule2'|'success'|'fail' = 'default') => {
  if (portType === 'in') return;
  const startPos = getNodeCenter(node.id, 'out', condition);
  drawingEdge.active = true; drawingEdge.sourceNodeId = node.id; drawingEdge.condition = condition;
  drawingEdge.startX = startPos.x; drawingEdge.startY = startPos.y; drawingEdge.currentX = startPos.x; drawingEdge.currentY = startPos.y;
};

const finishEdge = (targetNode: LocalNode, portType: 'in' | 'out') => {
  if (portType === 'out' || !drawingEdge.active || drawingEdge.sourceNodeId === targetNode.id) { drawingEdge.active = false; return; }
  const startPos = getNodeCenter(drawingEdge.sourceNodeId!, 'out', drawingEdge.condition);
  const endPos = getNodeCenter(targetNode.id, 'in');
  const newEdge: LocalEdge = { id: uuidv4(), fromId: drawingEdge.sourceNodeId!, toId: targetNode.id, condition: drawingEdge.condition, isJump: false, jumpRoles: [], jumpRule: {field:'', operator:'Igual a (==)', value:''}, startX: startPos.x, startY: startPos.y, endX: endPos.x, endY: endPos.y };
  edges.value.push(newEdge); drawingEdge.active = false;
};

const updateEdgesForNode = (nodeId: string) => {
  edges.value.forEach(edge => {
    if (edge.fromId === nodeId) { const pos = getNodeCenter(nodeId, 'out', edge.condition); edge.startX = pos.x; edge.startY = pos.y; }
    if (edge.toId === nodeId) { const pos = getNodeCenter(nodeId, 'in'); edge.endX = pos.x; edge.endY = pos.y; }
  });
};

const generateSVGPath = (sx: number, sy: number, ex: number, ey: number, condition?: string, isJump?: boolean, sourceNodeId?: string | null) => {
  const sourceNode = nodes.value.find(n => n.id === sourceNodeId);
  if (sourceNode && sourceNode.type === 'DECISION' && condition === 'fail') { const cY = sy - 60; return `M ${sx} ${sy} C ${sx} ${cY}, ${ex} ${cY}, ${ex} ${ey}`; }
  if (sx > ex && condition === 'fail') { const dropY = Math.max(sy, ey) + 120; return `M ${sx} ${sy} C ${sx+50} ${dropY}, ${ex-50} ${dropY}, ${ex} ${ey}`; }
  const cX = (sx + ex) / 2; return `M ${sx} ${sy} C ${cX} ${sy}, ${cX} ${ey}, ${ex} ${ey}`;
};

const getEdgeColor = (condition?: string, isJump?: boolean) => {
  if (isJump) return '#FFC107';
  if (['rule1', 'success'].includes(condition || '')) return '#4CAF50';
  if (condition === 'rule2') return '#FF9800';
  if (condition === 'fail') return '#F44336';
  return isLight.value ? '#9E9E9E' : '#78909C';
};

const selectEdge = (id: string) => { selectedEdgeId.value = id; selectedNodeId.value = null; inspectedNodeId.value = null; propertiesTab.value = 'basic'; };
const deleteEdge = (id: string) => { edges.value = edges.value.filter(e => e.id !== id); if (selectedEdgeId.value === id) selectedEdgeId.value = null; };
const clearWorkspace = () => { if(confirm("Limpar o quadro inteiro? Todo o rascunho visual atual será apagado.")) { nodes.value = []; edges.value = []; selectedNodeId.value = null; inspectedNodeId.value = null; selectedEdgeId.value = null; currentContextId.value = null; resetView(); } };
</script>

<style scoped lang="scss">
/* ==========================================================================
   WORKSPACE GRID (Abordagem Nativa Baseada no CanvasArea.vue)
============================================================================= */

.workspace-area {
  cursor: grab;
  border-radius: 24px;
  margin: 16px;
  isolation: isolate;
  border: 1px solid rgba(148, 163, 184, 0.18);
  box-shadow:
    0 30px 80px rgba(15, 23, 42, 0.18),
    inset 0 1px 0 rgba(255,255,255,0.05),
    inset 0 0 0 1px rgba(255,255,255,0.02);
}
.workspace-area:active { cursor: grabbing; }

.grid-overlay {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
  pointer-events: none;
  z-index: 1;
  /* Opacidade reduzida para não gritar na tela, mas garantindo que as linhas fiquem visíveis */
  opacity: 0.8;

  /* Usando linear-gradient nativo com background-repeat blindado contra SCSS */
  background-image:
    linear-gradient(to right, var(--grid-color) 1px, transparent 1px),
    linear-gradient(to bottom, var(--grid-color) 1px, transparent 1px);
  background-size: var(--grid-size, 48px) var(--grid-size, 48px);
  background-position: var(--grid-position-x, 0px) var(--grid-position-y, 0px);
  background-repeat: repeat;
}

/* Cores da Grade - Tema Claro */
.grid-light {
  --grid-color: rgba(0, 0, 0, 0.15) !important;
}

/* Cores da Grade - Tema Escuro */
.grid-dark {
  --grid-color: rgba(255, 255, 255, 0.15) !important;
}

/* Variação quando está mergulhado no micro-fluxo */
.context-micro .grid-light {
  --grid-color: rgba(79, 70, 229, 0.25) !important;
}
.context-micro .grid-dark {
  --grid-color: rgba(99, 102, 241, 0.25) !important;
}

/* ==========================================================================
   RESTANTE DO CSS
============================================================================= */

.canvas-layer {
  transform-origin: 0 0;
  width: 10000px;
  height: 10000px;
  z-index: 2;
  transition: transform 0.25s cubic-bezier(0.25, 0.8, 0.25, 1);
}
.zoom-dive-active { transform: scale(3) !important; opacity: 0; }

.flow-node-wrapper {
  cursor: pointer;
  border: 1px solid rgba(255,255,255,0.16);
  backdrop-filter: blur(10px);
  transition: all 0.28s cubic-bezier(0.22, 1, 0.36, 1);
  box-shadow:
    0 16px 30px rgba(2, 6, 23, 0.28),
    0 8px 16px rgba(15, 23, 42, 0.14),
    inset 0 1px 0 rgba(255,255,255,0.10) !important;
}
.flow-node-wrapper:hover {
  filter: brightness(1.06);
  transform: translateY(-6px) scale(1.018);
  box-shadow:
    0 28px 48px rgba(2, 6, 23, 0.34),
    0 14px 26px rgba(15, 23, 42, 0.18),
    inset 0 1px 0 rgba(255,255,255,0.14) !important;
}
.node-selected {
  border-color: rgba(255,255,255,0.55) !important;
  box-shadow: 0 0 0 4px rgba(0, 212, 255, 0.24), 0 24px 64px rgba(2, 6, 23, 0.42) !important;
  z-index: 100 !important;
}

.edge-path { transition: stroke-width 0.2s, filter 0.2s; }
.edge-path:hover { stroke-width: 6 !important; filter: drop-shadow(0 0 6px rgba(0, 212, 255, 0.8)); }

.energy-flow {
  filter: drop-shadow(0 0 3px #00d4ff) drop-shadow(0 0 6px rgba(0, 119, 204, 0.8));
  stroke-linecap: round;
}
.edge-selected {
  filter: drop-shadow(0 0 6px #fff) drop-shadow(0 0 12px #fff);
  stroke: #ffffff !important;
  stroke-width: 5px !important;
}
.flow-animated { animation: flowDash 1.2s linear infinite; }
@keyframes flowDash {
  from { stroke-dashoffset: 45; }
  to { stroke-dashoffset: 0; }
}

.port { width: 16px; height: 16px; background: #fff; border: 4px solid #333; border-radius: 50%; z-index: 20; transition: transform 0.2s, background 0.2s; }
.port:hover { transform: scale(1.8); background: #536DFE; border-color: #fff; }
.port-in { left: -8px; top: 50%; transform: translateY(-50%); border-color: #9E9E9E; }
.port-out-right { right: -8px; top: 50%; transform: translateY(-50%); }
.port-out-bottom { bottom: -8px; left: 50%; transform: translateX(-50%); }
.port-out-top { top: -8px; left: 50%; transform: translateX(-50%); }

.sidebar-properties { box-shadow: -10px 0 30px rgba(0,0,0,0.4) !important; }
.palette-card { cursor: grab; }
.palette-card:active { cursor: grabbing; }
.custom-scrollbar::-webkit-scrollbar { width: 6px; height: 6px; }
.custom-scrollbar::-webkit-scrollbar-thumb { background: rgba(150,150,150,0.5); border-radius: 4px; }
.transition-all { transition: all 0.3s cubic-bezier(0.25, 0.8, 0.25, 1); }
.absolute { position: absolute; }
.relative { position: relative; }
.z-10 { z-index: 10; } .z-20 { z-index: 20; } .z-30 { z-index: 30; }
.lh-1 { line-height: 1; } .lh-1-2 { line-height: 1.2; }
.tracking-widest { letter-spacing: 0.1em; }

.btn-3d { border-radius: 8px !important; box-shadow: 0 4px 6px rgba(0,0,0,0.2), inset 0 2px 0 rgba(255,255,255,0.2) !important; text-transform: uppercase !important; letter-spacing: 0.5px; transition: transform 0.1s ease, box-shadow 0.1s ease; }
.btn-3d:active { transform: translateY(2px); box-shadow: 0 1px 2px rgba(0,0,0,0.2), inset 0 1px 0 rgba(255,255,255,0.1) !important; }
.chip-3d { box-shadow: 0 2px 4px rgba(0,0,0,0.12), inset 0 1px 0 rgba(255,255,255,0.25) !important; font-weight: 900; text-shadow: 0 1px 2px rgba(0,0,0,0.3); }
.hover-elevate:hover { transform: translateY(-3px); box-shadow: 0 10px 20px rgba(0,0,0,0.15) !important; border-color: rgba(83, 109, 254, 0.5) !important; }
.hint-tooltip { position: relative; display: inline-flex; }
.hint-tooltip:hover::after { content: attr(data-title); position: absolute; bottom: calc(100% + 8px); left: 50%; transform: translateX(-50%); background: #222; color: #fff; padding: 6px 10px; font-size: 11px; font-weight: 800; border-radius: 4px; white-space: nowrap; pointer-events: none; z-index: 100; text-transform: uppercase; letter-spacing: 0.5px; box-shadow: 0 4px 12px rgba(0,0,0,0.3); }

.wizard-fab-container {
  position: fixed;
  bottom: 40px;
  right: 40px;
  z-index: 9999;
  display: flex;
  flex-direction: column;
  align-items: flex-end;
}

.wizard-speech-bubble {
  position: absolute;
  bottom: 85px;
  right: 10px;
  background: linear-gradient(135deg, #ffffff 0%, #f8fafc 100%);
  border: 1px solid #e2e8f0;
  border-radius: 16px;
  padding: 14px 20px;
  box-shadow: 0 15px 35px -5px rgba(0, 0, 0, 0.15), 0 5px 15px rgba(0, 0, 0, 0.05);
  width: max-content;
  max-width: 280px;
  transform-origin: bottom right;
  animation: float-bubble 4s ease-in-out infinite, pop-in 0.6s cubic-bezier(0.175, 0.885, 0.32, 1.275) forwards;
}

.bubble-content { display: flex; flex-direction: column; gap: 4px; }
.bubble-title { font-size: 13px; font-weight: 800; color: #0f172a; letter-spacing: -0.02em; }
.bubble-text { font-size: 12px; font-weight: 500; color: #64748b; line-height: 1.3; }

.bubble-tail {
  position: absolute;
  bottom: -8px;
  right: 24px;
  width: 16px;
  height: 16px;
  background: #f8fafc;
  border-right: 1px solid #e2e8f0;
  border-bottom: 1px solid #e2e8f0;
  transform: rotate(45deg);
}

.wizard-fab {
  width: 68px;
  height: 68px;
  border-radius: 50%;
  background: linear-gradient(135deg, #4f46e5 0%, #2563eb 100%);
  border: 3px solid #ffffff;
  box-shadow: 0 10px 25px -5px rgba(37, 99, 235, 0.6), 0 0 0 0 rgba(37, 99, 235, 0.4);
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  position: relative;
  overflow: hidden;
  animation: pulse-ring 3s infinite;
  transition: transform 0.3s cubic-bezier(0.175, 0.885, 0.32, 1.275);
}

.wizard-fab:hover {
  transform: scale(1.1) translateY(-4px);
  box-shadow: 0 20px 35px -5px rgba(37, 99, 235, 0.7), 0 0 0 0 rgba(37, 99, 235, 0);
}

.avatar-wrapper { position: relative; z-index: 2; transition: transform 0.3s ease; }
.wizard-fab:hover .avatar-wrapper { transform: rotate(-10deg) scale(1.1); }

.fab-shine {
  position: absolute;
  top: 0;
  left: -150%;
  width: 50%;
  height: 100%;
  background: linear-gradient(to right, rgba(255,255,255,0) 0%, rgba(255,255,255,0.4) 50%, rgba(255,255,255,0) 100%);
  transform: skewX(-25deg);
  z-index: 1;
  animation: shine-effect 4s cubic-bezier(0.4, 0, 0.2, 1) infinite;
}

@keyframes shine-effect { 0% { left: -150%; } 20% { left: 200%; } 100% { left: 200%; } }
@keyframes pulse-ring { 0% { box-shadow: 0 0 0 0 rgba(37, 99, 235, 0.5); } 70% { box-shadow: 0 0 0 20px rgba(37, 99, 235, 0); } 100% { box-shadow: 0 0 0 0 rgba(37, 99, 235, 0); } }
@keyframes float-bubble { 0%, 100% { transform: translateY(0); } 50% { transform: translateY(-6px); } }
@keyframes pop-in { 0% { opacity: 0; transform: scale(0.8) translateY(10px); } 100% { opacity: 1; transform: scale(1) translateY(0); } }

.builder-shell {
  position: relative;
  background:
    radial-gradient(circle at top left, rgba(79, 70, 229, 0.14), transparent 28%),
    radial-gradient(circle at top right, rgba(14, 165, 233, 0.10), transparent 22%),
    linear-gradient(180deg, rgba(255,255,255,0.05), rgba(255,255,255,0));
}
.builder-shell::after {
  content: '';
  position: absolute;
  inset: 0;
  pointer-events: none;
  background: linear-gradient(180deg, rgba(255,255,255,0.04), transparent 20%, transparent 80%, rgba(255,255,255,0.02));
}


.theme-enterprise-light { background-color: #eef2f7; }
.theme-enterprise-dark { background-color: #0b1220; }

.enterprise-topbar {
  min-height: 78px;
  padding-top: 14px !important;
  padding-bottom: 14px !important;
  backdrop-filter: blur(12px);
  box-shadow: 0 10px 30px rgba(15, 23, 42, 0.12);
  position: relative;
}
.enterprise-topbar::after {
  content: '';
  position: absolute;
  inset: auto 0 0 0;
  height: 1px;
  background: linear-gradient(90deg, transparent, rgba(99, 102, 241, 0.28), transparent);
}
.builder-logo-shell {
  min-width: 46px;
  min-height: 46px;
  border-radius: 16px !important;
  box-shadow: 0 12px 24px rgba(79, 70, 229, 0.28), inset 0 1px 0 rgba(255,255,255,0.25);
}
.enterprise-segmented {
  border-radius: 16px !important;
  padding: 4px;
  box-shadow: inset 0 1px 0 rgba(255,255,255,0.08);
}
.enterprise-toolbar-actions {
  padding: 6px 10px;
  border-radius: 18px;
}
.enterprise-panel {
  backdrop-filter: blur(14px);
  box-shadow: inset -1px 0 0 rgba(255,255,255,0.04), 10px 0 30px rgba(2, 6, 23, 0.08);
}
.enterprise-workspace { isolation: isolate; }
.enterprise-workspace::before {
  content: '';
  position: absolute;
  inset: 0;
  pointer-events: none;
  z-index: 0;
  background:
    radial-gradient(circle at 50% 0%, rgba(99, 102, 241, 0.08), transparent 30%),
    linear-gradient(180deg, rgba(255,255,255,0.02), rgba(255,255,255,0));
}
.enterprise-workspace::after {
  content: '';
  position: absolute;
  inset: 14px;
  border-radius: 24px;
  pointer-events: none;
  box-shadow: inset 0 0 0 1px rgba(148, 163, 184, 0.14), inset 0 24px 60px rgba(15, 23, 42, 0.08);
  z-index: 0;
}
.enterprise-structure-view {
  background-image:
    radial-gradient(circle at top left, rgba(79, 70, 229, 0.08), transparent 24%),
    linear-gradient(180deg, rgba(255,255,255,0.02), rgba(255,255,255,0));
}
.enterprise-preview-column {
  border-radius: 24px !important;
  overflow: hidden;
  box-shadow: 0 18px 40px rgba(15, 23, 42, 0.12), inset 0 1px 0 rgba(255,255,255,0.06) !important;
}
.enterprise-inspector {
  backdrop-filter: blur(18px);
  box-shadow: -18px 0 38px rgba(2, 6, 23, 0.28) !important;
}
.palette-card {
  border-radius: 18px !important;
  padding: 14px !important;
  box-shadow: 0 10px 20px rgba(2, 6, 23, 0.06);
}
.palette-card:hover {
  transform: translateY(-3px);
  box-shadow: 0 20px 35px rgba(15, 23, 42, 0.14);
}
.flow-node-wrapper { backdrop-filter: blur(6px); }
.flow-node-wrapper::after {
  content: '';
  position: absolute;
  inset: 0;
  border-radius: inherit;
  pointer-events: none;
  box-shadow: inset 0 1px 0 rgba(255,255,255,0.18);
}
.builder-header .v-btn,
.builder-header .v-select,
.builder-header .v-btn-group,
.builder-header .v-btn-toggle { border-radius: 14px !important; }
.sidebar-properties .v-card,
.preview-column .v-card { border-radius: 18px !important; }
.enterprise-fab {
  box-shadow:
    0 22px 50px -10px rgba(37, 99, 235, 0.55),
    0 0 0 1px rgba(255,255,255,0.22),
    inset 0 1px 0 rgba(255,255,255,0.3);
}
@media (max-width: 1280px) {
  .enterprise-topbar {
    gap: 12px;
    flex-wrap: wrap;
    justify-content: space-between !important;
  }
  .enterprise-toolbar-actions {
    width: 100%;
    justify-content: flex-end;
    padding: 0;
  }
  .sidebar-tools {
    width: 260px !important;
    min-width: 260px !important;
  }
  .sidebar-properties { width: 460px !important; }
}

.enterprise-topbar {
  min-height: 78px;
  backdrop-filter: blur(16px);
  box-shadow: 0 14px 30px rgba(15, 23, 42, 0.10);
}
.builder-logo-shell {
  width: 48px;
  height: 48px;
  border-radius: 16px !important;
  box-shadow: 0 12px 28px rgba(79, 70, 229, 0.28), inset 0 1px 0 rgba(255,255,255,0.18);
}
.enterprise-segmented, .enterprise-toolbar-actions .v-btn-group, .sidebar-tools, .sidebar-properties, .preview-column {
  backdrop-filter: blur(14px);
}
.sidebar-tools {
  margin: 16px 0 16px 16px;
  border-radius: 24px;
  box-shadow: 0 18px 48px rgba(15, 23, 42, 0.12);
}
.sidebar-properties {
  margin: 16px 16px 16px 0;
  border-radius: 24px;
  overflow: hidden;
  box-shadow: -18px 0 48px rgba(2,6,23,0.22) !important;
}
.preview-column {
  border-radius: 24px !important;
  overflow: hidden;
  box-shadow: 0 18px 48px rgba(15, 23, 42, 0.14);
}
.palette-card {
  border-radius: 18px !important;
  min-height: 74px;
}

@media (max-width: 960px) {
  .wizard-fab-container {
    bottom: 20px;
    right: 20px;
  }
  .wizard-speech-bubble {
    max-width: 220px;
    right: 0;
  }
  .sidebar-properties {
    width: 100% !important;
    max-width: 100%;
  }
}



.builder-status-rail {
  position: relative;
  z-index: 15;
  border-bottom: 1px solid rgba(148, 163, 184, 0.12);
  backdrop-filter: blur(10px);
}
.status-rail-light {
  background: linear-gradient(180deg, rgba(255,255,255,0.72), rgba(255,255,255,0.58));
}
.status-rail-dark {
  background: linear-gradient(180deg, rgba(10,15,27,0.82), rgba(10,15,27,0.70));
}
.status-pill {
  display: inline-flex;
  align-items: center;
  padding: 8px 12px;
  border-radius: 999px;
  font-size: 11px;
  font-weight: 800;
  letter-spacing: .04em;
  text-transform: uppercase;
  border: 1px solid rgba(148,163,184,0.16);
  box-shadow: inset 0 1px 0 rgba(255,255,255,0.12), 0 8px 18px rgba(15,23,42,0.06);
}
.theme-enterprise-light .status-pill {
  background: rgba(255,255,255,0.82);
  color: #334155;
}
.theme-enterprise-dark .status-pill {
  background: rgba(15,23,42,0.72);
  color: #dbeafe;
}

.workspace-area {
  margin: 16px;
  border-radius: 30px;
  border: 1px solid rgba(148,163,184,0.16);
  box-shadow:
    0 28px 70px rgba(2, 6, 23, 0.18),
    inset 0 1px 0 rgba(255,255,255,0.06),
    inset 0 -30px 80px rgba(15,23,42,0.06);
}
.theme-enterprise-light .workspace-area {
  background: linear-gradient(180deg, #f8fbff 0%, #eef4fb 100%);
}
.theme-enterprise-dark .workspace-area {
  background: linear-gradient(180deg, #0b1424 0%, #09111f 100%);
}
.workspace-area::after {
  content: '';
  position: absolute;
  inset: 12px;
  border-radius: 24px;
  pointer-events: none;
  z-index: 0;
  box-shadow: inset 0 0 0 1px rgba(255,255,255,0.05);
}

.tutorial-overlay > div {
  backdrop-filter: blur(16px);
  border-radius: 28px !important;
  box-shadow: 0 30px 70px rgba(15,23,42,0.16) !important;
}

.enterprise-panel {
  background-image: linear-gradient(180deg, rgba(255,255,255,0.05), transparent);
}
.theme-enterprise-dark .enterprise-panel {
  background-image: linear-gradient(180deg, rgba(255,255,255,0.04), rgba(255,255,255,0.01));
}

.sidebar-tools .pa-4.border-b,
.sidebar-properties .pa-4.border-b,
.sidebar-properties .pa-5.border-b {
  position: relative;
}
.sidebar-tools .pa-4.border-b::after,
.sidebar-properties .pa-4.border-b::after,
.sidebar-properties .pa-5.border-b::after {
  content: '';
  position: absolute;
  inset: auto 16px 0 16px;
  height: 1px;
  background: linear-gradient(90deg, transparent, rgba(99,102,241,0.26), transparent);
}

.preview-column > .pa-4.text-white {
  min-height: 96px;
  box-shadow: inset 0 1px 0 rgba(255,255,255,0.16);
}
.preview-column .flex-grow-1 {
  background-image: linear-gradient(180deg, rgba(255,255,255,0.02), transparent 20%);
}

.flow-node-wrapper {
  overflow: hidden;
}
.flow-node-wrapper::before {
  content: '';
  position: absolute;
  inset: 0;
  border-radius: inherit;
  pointer-events: none;
  background: linear-gradient(135deg, rgba(255,255,255,0.18), transparent 38%, transparent 62%, rgba(255,255,255,0.06));
  opacity: .7;
}
.flow-node-wrapper > * {
  position: relative;
  z-index: 1;
}

.enterprise-inspector {
  background-image:
    radial-gradient(circle at top right, rgba(99, 102, 241, 0.10), transparent 22%),
    linear-gradient(180deg, rgba(255,255,255,0.04), transparent);
}

.wizard-speech-bubble {
  border-radius: 20px;
}
.enterprise-fab {
  width: 72px;
  height: 72px;
}

@media (max-width: 1280px) {
  .workspace-area {
    margin: 12px;
    border-radius: 22px;
  }
}

/* enterprise remaster v5 */
.builder-shell {
  background:
    radial-gradient(circle at top left, rgba(59,130,246,0.12), transparent 26%),
    radial-gradient(circle at bottom right, rgba(14,165,233,0.10), transparent 24%);
}
.theme-enterprise-dark.builder-shell {
  background:
    radial-gradient(circle at top left, rgba(56,189,248,0.10), transparent 26%),
    radial-gradient(circle at bottom right, rgba(99,102,241,0.10), transparent 24%),
    linear-gradient(180deg, #050b14 0%, #09111f 100%);
}
.theme-enterprise-light.builder-shell {
  background:
    radial-gradient(circle at top left, rgba(59,130,246,0.08), transparent 24%),
    radial-gradient(circle at bottom right, rgba(99,102,241,0.08), transparent 22%),
    linear-gradient(180deg, #f6f9fd 0%, #edf3fa 100%);
}

.enterprise-topbar {
  min-height: 84px;
  padding-top: 14px !important;
  padding-bottom: 14px !important;
  border-bottom-color: rgba(148, 163, 184, 0.14) !important;
  background:
    linear-gradient(180deg, rgba(255,255,255,0.92), rgba(255,255,255,0.78));
  backdrop-filter: blur(18px);
  box-shadow:
    0 10px 34px rgba(15, 23, 42, 0.08),
    inset 0 -1px 0 rgba(255,255,255,0.24);
}
.theme-enterprise-dark .enterprise-topbar {
  background:
    linear-gradient(180deg, rgba(8, 15, 28, 0.92), rgba(8, 15, 28, 0.82));
  box-shadow:
    0 16px 38px rgba(0,0,0,0.32),
    inset 0 -1px 0 rgba(255,255,255,0.04);
}
.builder-logo-shell {
  width: 54px;
  height: 54px;
  border-radius: 18px !important;
  box-shadow:
    0 16px 34px rgba(79, 70, 229, 0.34),
    inset 0 1px 0 rgba(255,255,255,0.24);
}

.builder-status-rail {
  margin: 0 16px;
  border-radius: 0 0 20px 20px;
  border: 1px solid rgba(148,163,184,0.12);
  border-top: none;
  box-shadow: 0 12px 28px rgba(15,23,42,0.08);
}
.theme-enterprise-dark .builder-status-rail {
  box-shadow: 0 18px 30px rgba(0,0,0,0.22);
}

.sidebar-tools,
.sidebar-properties {
  border: 1px solid rgba(148,163,184,0.14) !important;
}
.sidebar-tools {
  margin: 18px 0 18px 18px;
  border-radius: 28px;
  background:
    linear-gradient(180deg, rgba(255,255,255,0.88), rgba(255,255,255,0.76));
  box-shadow:
    0 26px 70px rgba(15,23,42,0.10),
    inset 0 1px 0 rgba(255,255,255,0.46);
}
.theme-enterprise-dark .sidebar-tools {
  background:
    linear-gradient(180deg, rgba(10,16,29,0.92), rgba(9,15,28,0.84));
  box-shadow:
    0 28px 72px rgba(0,0,0,0.34),
    inset 0 1px 0 rgba(255,255,255,0.05);
}
.sidebar-properties {
  margin: 18px 18px 18px 0;
  border-radius: 28px;
  background:
    linear-gradient(180deg, rgba(255,255,255,0.94), rgba(255,255,255,0.82));
  box-shadow:
    -24px 0 70px rgba(15,23,42,0.12),
    inset 0 1px 0 rgba(255,255,255,0.42) !important;
}
.theme-enterprise-dark .sidebar-properties {
  background:
    linear-gradient(180deg, rgba(10,16,29,0.96), rgba(8,14,27,0.88));
  box-shadow:
    -24px 0 74px rgba(0,0,0,0.42),
    inset 0 1px 0 rgba(255,255,255,0.05) !important;
}

.palette-card {
  min-height: 82px;
  padding: 14px 15px !important;
  border-radius: 20px !important;
  border-color: rgba(148,163,184,0.14) !important;
  background:
    linear-gradient(180deg, rgba(255,255,255,0.98), rgba(248,250,252,0.92));
  box-shadow:
    0 10px 24px rgba(15,23,42,0.06),
    inset 0 1px 0 rgba(255,255,255,0.5);
}
.theme-enterprise-dark .palette-card {
  background:
    linear-gradient(180deg, rgba(16,23,37,0.96), rgba(11,18,31,0.90));
  box-shadow:
    0 14px 28px rgba(0,0,0,0.28),
    inset 0 1px 0 rgba(255,255,255,0.04);
}
.palette-card:hover {
  transform: translateY(-4px) scale(1.01);
}

.workspace-area {
  margin: 18px;
  border-radius: 34px;
  border: 1px solid rgba(148,163,184,0.15);
  box-shadow:
    0 36px 90px rgba(2, 6, 23, 0.18),
    inset 0 1px 0 rgba(255,255,255,0.10),
    inset 0 -50px 120px rgba(15,23,42,0.05);
}
.theme-enterprise-light .workspace-area {
  background:
    linear-gradient(180deg, #f8fbff 0%, #eef4fb 100%);
}
.theme-enterprise-dark .workspace-area {
  background:
    linear-gradient(180deg, #08101b 0%, #0a1322 100%);
}
.workspace-area::before {
  z-index: 0;
  background:
    radial-gradient(circle at top left, rgba(99,102,241,0.14), transparent 22%),
    radial-gradient(circle at bottom right, rgba(14,165,233,0.12), transparent 24%);
}
.workspace-area::after {
  inset: 14px;
  border-radius: 26px;
  box-shadow:
    inset 0 0 0 1px rgba(255,255,255,0.06),
    inset 0 14px 40px rgba(255,255,255,0.03);
}

.canvas-layer {
  z-index: 2;
  will-change: transform;
}
.edges-layer {
  filter: drop-shadow(0 0 12px rgba(56,189,248,0.10));
}

.flow-node-wrapper {
  overflow: hidden;
  box-shadow:
    0 18px 34px rgba(15,23,42,0.18),
    0 2px 8px rgba(15,23,42,0.10),
    inset 0 1px 0 rgba(255,255,255,0.14);
}
.flow-node-wrapper:hover {
  transform: translateY(-2px);
}
.flow-node-wrapper::before {
  background:
    linear-gradient(135deg, rgba(255,255,255,0.24), transparent 34%, transparent 64%, rgba(255,255,255,0.08));
}
.flow-node-wrapper .port {
  box-shadow:
    0 8px 18px rgba(2,6,23,0.22),
    inset 0 1px 0 rgba(255,255,255,0.30);
}

.preview-column {
  border-radius: 28px !important;
  border: 1px solid rgba(148,163,184,0.14) !important;
  box-shadow:
    0 24px 60px rgba(15,23,42,0.12),
    inset 0 1px 0 rgba(255,255,255,0.26);
}
.theme-enterprise-dark .preview-column {
  box-shadow:
    0 26px 64px rgba(0,0,0,0.34),
    inset 0 1px 0 rgba(255,255,255,0.05);
}
.preview-column .v-card {
  border-radius: 18px !important;
  border: 1px solid rgba(148,163,184,0.12) !important;
}

.builder-header .v-btn,
.builder-header .v-select .v-field,
.builder-header .v-btn-group,
.builder-header .v-btn-toggle,
.sidebar-properties .v-field,
.sidebar-tools .v-field,
.sidebar-properties .v-card,
.preview-column .v-card {
  border-radius: 16px !important;
}

.builder-header .v-btn {
  min-height: 42px;
  box-shadow: inset 0 1px 0 rgba(255,255,255,0.12);
}

.sidebar-tools .pa-4.border-b::after,
.sidebar-properties .pa-4.border-b::after,
.sidebar-properties .pa-5.border-b::after {
  height: 2px;
  border-radius: 999px;
  background: linear-gradient(90deg, transparent, rgba(59,130,246,0.32), rgba(99,102,241,0.22), transparent);
}

.tutorial-overlay > div {
  border-radius: 30px !important;
  backdrop-filter: blur(18px);
  box-shadow:
    0 40px 90px rgba(15,23,42,0.16),
    inset 0 1px 0 rgba(255,255,255,0.32) !important;
}

@media (max-width: 1280px) {
  .workspace-area {
    margin: 12px;
    border-radius: 24px;
  }
  .sidebar-tools {
    width: 270px !important;
    min-width: 270px !important;
  }
}



/* ===== premium builder remaster v2 ===== */
.builder-header-shell { min-height: 88px; }
.builder-header-brand { flex: 1 1 360px; }
.builder-header-middle { flex: 1 1 520px; }
.builder-header-actions { flex: 1 1 360px; }
.builder-eyebrow {
  font-size: 10px;
  font-weight: 900;
  letter-spacing: .18em;
  text-transform: uppercase;
  opacity: .62;
}
.builder-title {
  font-size: 1.24rem;
  font-weight: 950;
  line-height: 1;
  letter-spacing: -.03em;
  background: linear-gradient(135deg, #4f46e5 0%, #0ea5e9 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
}
.theme-enterprise-dark .builder-title {
  background: linear-gradient(135deg, #c7d2fe 0%, #67e8f9 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
}
.builder-subtitle {
  font-size: 11px;
  font-weight: 700;
  opacity: .68;
  max-width: 420px;
}
.builder-motor-select { width: 300px; }
.builder-motor-select :deep(.v-field) {
  min-height: 46px !important;
  border-radius: 16px !important;
  box-shadow: inset 0 1px 0 rgba(255,255,255,.10), 0 12px 24px rgba(15,23,42,.06);
}
.builder-mode-toggle,
.builder-zoom-cluster {
  padding: 4px;
  border-radius: 16px !important;
  box-shadow: inset 0 1px 0 rgba(255,255,255,.08), 0 10px 24px rgba(15,23,42,.06);
}
.builder-primary-btn,
.builder-secondary-btn {
  min-height: 44px !important;
  border-radius: 16px !important;
  padding-inline: 16px !important;
  font-weight: 900 !important;
  letter-spacing: .02em;
}
.builder-danger-btn {
  border-radius: 14px !important;
}
.builder-actions-menu {
  border-radius: 20px !important;
  overflow: hidden;
}
.flow-node-card {
  border: 1px solid rgba(255,255,255,0.14);
  box-shadow:
    0 22px 42px rgba(15,23,42,0.20),
    0 6px 14px rgba(15,23,42,0.10),
    inset 0 1px 0 rgba(255,255,255,0.16) !important;
}
.flow-node-card:hover { transform: translateY(-4px) scale(1.012); }
.flow-node-card.node-selected {
  box-shadow:
    0 0 0 2px rgba(255,255,255,0.28),
    0 28px 56px rgba(15,23,42,0.22),
    0 0 0 6px rgba(99,102,241,0.18) !important;
}
.flow-node-card.node-inspected {
  box-shadow:
    0 0 0 2px rgba(255,255,255,0.34),
    0 0 0 6px rgba(14,165,233,0.16),
    0 34px 64px rgba(15,23,42,0.26) !important;
}
.flow-node-topbar {
  min-height: 50px;
  background: linear-gradient(180deg, rgba(0,0,0,0.34), rgba(0,0,0,0.18));
  backdrop-filter: blur(8px);
}
.flow-node-icon-shell {
  width: 28px;
  height: 28px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border-radius: 10px;
  background: rgba(255,255,255,0.16);
  box-shadow: inset 0 1px 0 rgba(255,255,255,0.18);
}
.flow-node-kind {
  font-size: 9px;
  font-weight: 900;
  letter-spacing: .14em;
  text-transform: uppercase;
  color: rgba(255,255,255,0.92);
}
.flow-node-mini-meta {
  font-size: 9px;
  font-weight: 700;
  color: rgba(255,255,255,0.64);
}
.node-inspector-btn {
  min-width: 26px !important;
  width: 26px !important;
  height: 26px !important;
  border-radius: 9px !important;
  background: rgba(255,255,255,0.14) !important;
}
.flow-node-body {
  background: linear-gradient(180deg, rgba(255,255,255,0.02), rgba(255,255,255,0.00));
}
.flow-node-title {
  font-size: 16px;
  line-height: 1.15;
  font-weight: 950;
  color: #fff;
  text-shadow: 0 1px 3px rgba(0,0,0,.45);
}
.flow-node-meta-stack {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 6px;
}
.flow-node-meta-chip,
.flow-node-tag-chip,
.flow-node-footer-badge {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-height: 24px;
  padding: 5px 10px;
  border-radius: 999px;
  font-size: 10px;
  font-weight: 800;
  line-height: 1;
  color: rgba(255,255,255,0.94);
  border: 1px solid rgba(255,255,255,0.14);
  box-shadow: inset 0 1px 0 rgba(255,255,255,0.14);
}
.flow-node-meta-chip {
  background: rgba(0,0,0,0.28);
  font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
}
.flow-node-tag-chip { background: rgba(79,70,229,0.38); }
.flow-node-footer-badge { background: rgba(255,255,255,0.12); }
.flow-node-action-btn,
.flow-node-panel-btn {
  min-height: 26px !important;
  border-radius: 10px !important;
  padding-inline: 10px !important;
  font-weight: 900 !important;
  letter-spacing: .01em;
}
.flow-node-action-btn {
  background: rgba(255,255,255,0.92) !important;
  color: #312e81 !important;
}
.flow-node-panel-btn {
  color: #0f172a !important;
}
.element-inspector {
  border-radius: 30px;
}
.element-inspector-hero {
  background:
    radial-gradient(circle at top right, rgba(255,255,255,0.30), transparent 28%),
    linear-gradient(180deg, rgba(255,255,255,0.08), rgba(255,255,255,0.02));
}
.element-inspector-kicker {
  font-size: 10px;
  font-weight: 900;
  letter-spacing: .16em;
  text-transform: uppercase;
  opacity: .58;
  margin-bottom: 8px;
}
.element-inspector-subtitle {
  font-size: 11px;
  line-height: 1.35;
  font-weight: 700;
  opacity: .70;
  max-width: 360px;
}
.element-inspector-summary-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 10px;
}
.summary-tile {
  padding: 12px;
  border-radius: 16px;
  border: 1px solid rgba(255,255,255,0.14);
  background: rgba(255,255,255,0.26);
  backdrop-filter: blur(12px);
  box-shadow: inset 0 1px 0 rgba(255,255,255,0.24);
}
.theme-enterprise-dark .summary-tile {
  background: rgba(15,23,42,0.44);
}
.summary-tile span {
  display: block;
  font-size: 9px;
  font-weight: 900;
  text-transform: uppercase;
  letter-spacing: .12em;
  opacity: .62;
}
.summary-tile strong {
  display: block;
  margin-top: 6px;
  font-size: 13px;
  font-weight: 900;
}
.element-inspector-tabs {
  padding: 4px;
  border-radius: 18px;
  background: rgba(255,255,255,0.18);
  backdrop-filter: blur(10px);
}
.theme-enterprise-dark .element-inspector-tabs {
  background: rgba(15,23,42,0.36);
}
.element-inspector-tabs :deep(.v-slide-group__content) {
  gap: 8px;
}
.element-inspector-tabs :deep(.v-tab) {
  min-height: 38px;
  border-radius: 14px;
  font-size: 11px;
  font-weight: 900;
  text-transform: none;
  letter-spacing: .01em;
}
.element-inspector-tabs :deep(.v-tab--selected) {
  background: rgba(255,255,255,0.30);
  box-shadow: inset 0 0 0 1px rgba(255,255,255,0.18);
}
.element-inspector-content {
  background-image: linear-gradient(180deg, rgba(255,255,255,0.03), transparent 18%);
}
.element-inspector-content > .v-window {
  overflow: visible;
}
.element-inspector-content .v-alert,
.element-inspector-content .v-card,
.element-inspector-content .v-expansion-panel {
  border-radius: 18px !important;
}
.element-inspector-content .v-field :deep(.v-field) {
  border-radius: 16px !important;
}
@media (max-width: 1280px) {
  .builder-header-middle,
  .builder-header-actions {
    width: 100%;
    justify-content: flex-start;
  }
  .builder-motor-select { width: min(100%, 320px); }
}

</style>
