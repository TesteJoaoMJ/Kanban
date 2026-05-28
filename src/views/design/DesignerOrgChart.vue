<template>
  <div
    class="pcp-builder-container builder-shell d-flex flex-column overflow-hidden transition-all relative fullscreen-mode"
    :class="[isLight ? 'theme-enterprise-light text-grey-darken-4' : 'theme-enterprise-dark text-white', drawingEdge.active ? 'is-drawing-mode' : '']"
  >
    <div
      v-for="anim in activeAnimations"
      :key="anim.id"
      class="water-drop-effect"
      :style="{ '--start-x': anim.startX+'px', '--start-y': anim.startY+'px', '--end-x': anim.targetX+'px', '--end-y': anim.targetY+'px', color: anim.color }"
    />

    <header
      class="enterprise-header border-b flex-shrink-0 z-30 transition-none"
      :class="isLight ? 'bg-white border-grey-lighten-2' : 'bg-grey-darken-4 border-grey-darken-3'"
    >
      <div class="header-shell px-5 py-3 d-flex justify-space-between align-center gap-4">
        <div class="header-brand d-flex align-center gap-3 min-w-0">
          <v-btn icon="mdi-arrow-left" variant="tonal" color="primary" size="small" class="header-nav-btn shrink-0" @click="$router.push('/design')" title="Voltar ao Kanban" />
          <div class="header-brand-mark shrink-0">
            <div class="glow-icon-box d-flex align-center justify-center">
              <v-icon color="white" size="20">mdi-family-tree</v-icon>
            </div>
          </div>
          <div class="header-brand-copy d-flex flex-column min-w-0">
            <div class="d-flex align-center gap-2 flex-wrap">
              <span class="header-eyebrow">Design Operations</span>
              <v-chip size="x-small" color="primary" variant="flat" class="font-weight-black text-uppercase chip-3d px-2">OrgChart Pro</v-chip>
            </div>
            <div class="d-flex align-center gap-3 flex-wrap min-w-0">
              <h1 class="header-title mb-0">
                Command Center
              </h1>
              <span class="header-subtitle text-truncate">
                Arraste cards, conecte vínculos e governe a operação visual da equipe
              </span>
            </div>
          </div>
        </div>

        <div class="header-middle d-flex align-center gap-2 flex-wrap justify-center">
          <v-text-field
            v-model="searchQuery"
            density="comfortable"
            variant="solo-filled"
            hide-details
            prepend-inner-icon="mdi-magnify"
            placeholder="Buscar designer, função ou card..."
            class="search-field search-field--xl"
            :class="isLight ? 'search-field-light' : 'search-field-dark'"
          />

          <v-select
            v-model="roleFilter"
            :items="roleFilterOptions"
            density="comfortable"
            variant="solo-filled"
            hide-details
            class="role-filter role-filter--xl"
            :class="isLight ? 'search-field-light' : 'search-field-dark'"
          />

          <v-btn-toggle v-model="compactCards" mandatory density="comfortable" class="view-toggle view-toggle-premium" divided>
            <v-btn :value="false" prepend-icon="mdi-cards-outline" size="small" class="font-weight-black">Detalhado</v-btn>
            <v-btn :value="true" prepend-icon="mdi-view-grid-outline" size="small" class="font-weight-black">Compacto</v-btn>
          </v-btn-toggle>
        </div>

        <div class="header-actions d-flex align-center gap-2 flex-wrap justify-end">
          <v-btn-group variant="outlined" density="comfortable" class="btn-group-glass zoom-cluster">
            <v-btn icon="mdi-magnify-minus-outline" size="small" @click="zoomOut" class="hover-text-primary" />
            <v-btn class="zoom-indicator font-weight-black font-mono px-1" size="small" style="pointer-events: none;">{{ Math.round(transform.scale * 100) }}%</v-btn>
            <v-btn icon="mdi-magnify-plus-outline" size="small" @click="zoomIn" class="hover-text-primary" />
            <v-btn icon="mdi-target" size="small" @click="resetView" class="hover-text-primary" />
          </v-btn-group>

          <v-btn color="indigo-accent-2" variant="tonal" prepend-icon="mdi-auto-fix" size="small" class="btn-3d btn-secondary-premium" @click="autoLayoutNodes" title="Auto-Organizar">
            Auto-organizar
          </v-btn>
          <v-btn color="success" variant="flat" prepend-icon="mdi-content-save-all" size="small" class="font-weight-black text-caption btn-3d btn-primary-premium" @click="saveLayout" :loading="loadingSave">
            Salvar layout
          </v-btn>
        </div>
      </div>
    </header>

    <div class="builder-status-rail px-4 py-1 d-flex align-center flex-wrap gap-2" :class="isLight ? 'status-rail-light border-grey-lighten-2' : 'status-rail-dark border-grey-darken-3'">
      <div class="status-pill"><v-icon size="10" class="mr-1">mdi-account-group</v-icon> Equipe <strong class="ml-1">{{ nodes.length }}</strong></div>
      <div class="status-pill"><v-icon size="10" class="mr-1">mdi-graph-outline</v-icon> Vínculos <strong class="ml-1">{{ edges.length }}</strong></div>
      <div class="status-pill"><v-icon size="10" class="mr-1">mdi-palette-swatch</v-icon> Carga ativa <strong class="ml-1">{{ totalActiveArts }}</strong></div>
      <div class="status-pill border-warning text-warning" :class="isLight ? 'bg-orange-lighten-5' : 'bg-orange-darken-4-alpha'">
        <v-icon size="10" color="warning" class="mr-1">mdi-inbox-arrow-down</v-icon> Sem dono <strong class="ml-1">{{ totalUnassignedArts }}</strong>
      </div>
      <div class="status-pill" :class="overloadedCount ? 'status-pill-danger' : ''">
        <v-icon size="10" class="mr-1">mdi-fire-alert</v-icon> Sobrecarga <strong class="ml-1">{{ overloadedCount }}</strong>
      </div>
      <v-spacer />
      <v-switch v-model="showOnlyOverloaded" color="warning" density="compact" hide-details inset class="mr-2 switch-small">
        <template #label><span class="text-[9px] font-weight-bold opacity-70">Mostrar só críticos</span></template>
      </v-switch>
    </div>

    <div class="d-flex flex-grow-1 overflow-hidden relative">
      <main
        ref="workspaceRef"
        class="workspace-area enterprise-workspace flex-grow-1 relative overflow-hidden no-select"
        @mousedown="onWorkspaceMouseDown"
        @wheel.prevent="onWorkspaceWheel"
      >
        <div class="grid-overlay" :class="isLight ? 'grid-light' : 'grid-dark'" :style="gridStyle"></div>
        <div class="grid-glow-overlay" />
        <div class="cinematic-overlay transition-all" :class="drawingEdge.active ? 'overlay-active' : ''"></div>

        <div class="workspace-hud d-flex flex-column gap-2">
          <v-card class="hud-card pa-3 rounded-xl border" :class="isLight ? 'bg-white' : 'bg-grey-darken-4'">
            <div class="d-flex align-center justify-space-between mb-2">
              <div>
                <div class="text-[9px] font-weight-black text-uppercase opacity-60 mb-1">Saúde da malha</div>
                <div class="text-subtitle-2 font-weight-black lh-1">{{ networkHealthLabel }}</div>
              </div>
              <v-avatar size="32" :color="networkHealthColor" class="text-white elevation-2">
                <v-icon size="16">{{ networkHealthIcon }}</v-icon>
              </v-avatar>
            </div>
            <v-progress-linear :model-value="networkHealthScore" :color="networkHealthColor" rounded height="6" class="mb-1" />
            <div class="text-[8px] opacity-70 lh-1-2">Baseado em bloqueios, órfãos e sobrecarga.</div>
          </v-card>

          <v-card class="hud-card pa-3 rounded-xl border" :class="isLight ? 'bg-white' : 'bg-grey-darken-4'">
            <div class="d-flex align-center justify-space-between mb-2">
              <div class="text-[9px] font-weight-black text-uppercase opacity-60">Radar rápido</div>
              <v-icon size="14" color="primary">mdi-radar</v-icon>
            </div>
            <div class="d-flex flex-column gap-1 text-[10px]">
              <div class="hud-line"><span>Líderes</span><strong>{{ leaderCount }}</strong></div>
              <div class="hud-line"><span>Bloqueados</span><strong>{{ blockedCount }}</strong></div>
              <div class="hud-line"><span>Sem chefia</span><strong>{{ rootCount }}</strong></div>
              <div class="hud-line"><span>Maior fila</span><strong>{{ maxLoadDisplay }}</strong></div>
            </div>
          </v-card>
        </div>

        <div v-if="loading" class="absolute d-flex flex-column align-center justify-center w-100 h-100 z-10">
          <v-progress-circular indeterminate color="indigo" size="64" width="6" />
          <span class="mt-4 font-weight-bold opacity-70">Sincronizando hierarquia e operação...</span>
        </div>

        <div v-else class="canvas-layer absolute" :style="{ transform: `translate(${transform.x}px, ${transform.y}px) scale(${transform.scale})` }">
          <svg class="edges-layer absolute top-0 left-0 w-100 h-100" style="overflow: visible; z-index: 1;">
            <defs>
              <marker id="arrowhead" markerWidth="10" markerHeight="7" refX="9" refY="3.5" orient="auto"><polygon points="0 0, 10 3.5, 0 7" fill="#00d4ff" /></marker>
              <marker id="arrowhead-hover" markerWidth="10" markerHeight="7" refX="9" refY="3.5" orient="auto"><polygon points="0 0, 10 3.5, 0 7" fill="#ff5252" /></marker>
              <marker id="arrowhead-active" markerWidth="10" markerHeight="7" refX="9" refY="3.5" orient="auto"><polygon points="0 0, 10 3.5, 0 7" fill="#4CAF50" /></marker>
            </defs>
            <g v-for="edge in visibleEdges" :key="edge.id" @mouseenter="hoveredEdgeId = edge.id" @mouseleave="hoveredEdgeId = null">
              <path :d="generateSVGPath(edge)" stroke="#00d4ff" stroke-width="2" stroke-dasharray="4,4" fill="none" opacity="0.18" />
              <path :d="generateSVGPath(edge)" class="edge-path flow-animated energy-flow transition-colors" :stroke="hoveredEdgeId === edge.id ? '#ff5252' : '#00d4ff'" :stroke-width="hoveredEdgeId === edge.id ? 4 : 3" stroke-dasharray="15, 30" fill="none" :marker-end="hoveredEdgeId === edge.id ? 'url(#arrowhead-hover)' : 'url(#arrowhead)'" />
              <path :d="generateSVGPath(edge)" stroke="transparent" stroke-width="24" fill="none" class="edge-hit-area cursor-cut" @mousedown.stop="deleteEdge(edge.id)" />
            </g>
            <path v-if="drawingEdge.active" :d="generateDrawingPath()" class="flow-animated energy-flow" stroke="#4CAF50" stroke-width="3" stroke-dasharray="15, 30" fill="none" marker-end="url(#arrowhead-active)" />
          </svg>

          <div
            v-for="node in filteredNodes"
            :key="node.id"
            :ref="el => setNodeElementRef(node.id, el)"
            class="flow-node-wrapper absolute d-flex flex-column"
            :class="[
              selectedNodeId === node.id ? 'node-selected' : '',
              dragOverNodeId === node.id ? 'node-drag-over' : '',
              hoverConnectNodeId === node.id ? 'node-connect-hover' : '',
              node.isBlocked ? 'node-blocked grayscale' : '',
              isNodeExpanded(node) ? 'node-detailed' : 'node-compact',
              getNodeLoadLevel(node) === 'critical' ? 'node-critical' : getNodeLoadLevel(node) === 'attention' ? 'node-attention' : 'node-healthy'
            ]"
            :style="{ left: `${node.ui_x}px`, top: `${node.ui_y}px`, width: isNodeExpanded(node) ? '280px' : '230px', backgroundColor: node.color, borderRadius: '18px', zIndex: selectedNodeId === node.id ? 100 : 16 }"
            @mousedown.stop="onNodeMouseDown($event, node)"
            @mouseup="finishEdge(node)"
            @mouseenter="onNodeMouseEnter(node)"
            @mouseleave="onNodeMouseLeave(node)"
            @click.stop="selectNode(node)"
            @dragover.prevent="onNodeDragOver($event, node)"
            @dragleave.prevent="dragOverNodeId = null"
            @drop="onNodeDrop($event, node)"
          >
            <div class="node-gloss" />

            <div class="px-3 py-2 d-flex align-center justify-space-between border-b border-white-02 position-relative overflow-hidden node-topbar">
              <div class="d-flex align-center gap-2 z-10 w-100 min-w-0">
                <v-avatar size="36" class="elevation-4 border-2 border-white shrink-0 node-avatar" color="white">
                  <v-img v-if="node.user.avatar" :src="node.user.avatar" cover />
                  <span v-else class="text-indigo-darken-4 font-weight-black text-caption">{{ node.user.name.charAt(0) }}</span>
                </v-avatar>
                <div class="d-flex flex-column flex-grow-1 overflow-hidden min-w-0">
                  <div class="d-flex align-center gap-1 flex-wrap mb-0">
                    <span class="text-caption font-weight-black text-white leading-tight text-truncate" style="text-shadow: 0 1px 3px rgba(0,0,0,0.6);">
                      {{ node.user.name }}
                    </span>
                    <v-chip size="x-small" :color="getNodeLoadColor(node)" variant="flat" class="font-weight-black text-uppercase chip-3d" style="height: 14px; font-size: 8px;">
                      {{ getNodeLoadLabel(node) }}
                    </v-chip>
                  </div>
                  <span class="text-[8px] font-weight-black text-uppercase text-white opacity-85 tracking-widest text-truncate mt-0">
                    {{ node.user.role }}
                  </span>
                </div>
              </div>

              <div class="d-flex align-center">
                <v-btn :icon="isNodeExpanded(node) ? 'mdi-chevron-up' : 'mdi-chevron-down'" variant="text" color="white" size="x-small" class="z-20 shrink-0" @mousedown.stop @click.stop="toggleNodeExpanded(node)" />
                <v-menu location="bottom end">
                  <template #activator="{ props }">
                    <v-btn icon="mdi-dots-horizontal" variant="text" color="white" size="x-small" class="z-20 ml-1 shrink-0" v-bind="props" @mousedown.stop @click.stop />
                  </template>
                  <v-list density="compact" nav class="border shadow-lg" :class="isLight ? 'bg-white' : 'bg-grey-darken-3'">
                    <v-list-item @click="openDrawer(node)" prepend-icon="mdi-eye-outline" class="font-weight-bold text-[11px]">Abrir painel</v-list-item>
                    <v-list-item @click="focusNode(node)" prepend-icon="mdi-crosshairs-gps" class="font-weight-bold text-[11px]">Focar quadro</v-list-item>
                    <v-list-item @click="openEditPermsModal(node)" prepend-icon="mdi-shield-edit-outline" class="font-weight-bold text-[11px] text-primary">Editar permissões</v-list-item>
                    <v-list-item @click="toggleNodeBlock(node)" :prepend-icon="node.isBlocked ? 'mdi-lock-open-variant' : 'mdi-lock'" class="font-weight-bold text-[11px] text-warning">{{ node.isBlocked ? 'Desbloquear' : 'Bloquear' }}</v-list-item>
                    <v-divider class="my-1" />
                    <v-list-item @click="removeNodeFromOrg(node)" prepend-icon="mdi-account-remove" class="font-weight-bold text-[11px] text-error">Remover da equipe</v-list-item>
                  </v-list>
                </v-menu>
              </div>
            </div>

            <div class="flex-grow-1 d-flex flex-column pa-3 position-relative node-body" :class="isLight ? 'bg-white' : 'bg-grey-darken-3'">
              <div v-if="node.isBlocked" class="absolute inset-0 d-flex align-center justify-center bg-grey-lighten-2 opacity-85 z-20">
                <v-chip color="error" variant="flat" size="small" class="font-weight-black text-uppercase shadow-sm"><v-icon start size="12">mdi-lock</v-icon> Bloqueado</v-chip>
              </div>

              <div class="node-quick-grid mb-2">
                <div class="mini-stat glass-panel">
                  <div class="mini-stat__label">Fila</div>
                  <div class="mini-stat__value">{{ node.tasks.total }}</div>
                </div>
                <div class="mini-stat glass-panel">
                  <div class="mini-stat__label">Conduz</div>
                  <div class="mini-stat__value">{{ getNodeRelations(node.id).led.length }}</div>
                </div>
                <div class="mini-stat glass-panel">
                  <div class="mini-stat__label">Recebe</div>
                  <div class="mini-stat__value">{{ getNodeRelations(node.id).leaders.length }}</div>
                </div>
              </div>

              <div class="mb-2">
                <div class="d-flex align-center justify-space-between mb-1">
                  <span class="text-[8px] font-weight-black text-uppercase opacity-70">Pressão Operacional</span>
                  <span class="text-[9px] font-weight-black" :class="getPressureTextClass(node)">{{ getNodePressurePercent(node) }}%</span>
                </div>
                <v-progress-linear :model-value="getNodePressurePercent(node)" :color="getNodeLoadColor(node)" rounded height="6" />
                <div class="d-flex justify-space-between mt-1 text-[8px] font-weight-bold opacity-70">
                  <span>Alvo: {{ getNodeCapacity(node) }}</span>
                  <span>{{ node.tasks.total }} artes</span>
                </div>
              </div>

              <div class="d-flex align-center justify-space-between flex-wrap gap-1 mb-3">
                <div class="d-flex gap-1 flex-wrap">
                  <v-chip v-if="node.perms.isLeader" style="height: 14px; font-size: 8px;" color="amber-darken-2" variant="flat" class="font-weight-black text-white px-1">Líder</v-chip>
                  <v-chip v-if="node.perms.canApprove" style="height: 14px; font-size: 8px;" color="success" variant="flat" class="font-weight-black px-1">Aprova</v-chip>
                  <v-chip v-if="node.perms.requiresApproval" style="height: 14px; font-size: 8px;" color="error" variant="tonal" class="font-weight-black px-1">Revisão</v-chip>
                </div>
                <div class="text-[8px] font-weight-black opacity-60 text-uppercase">{{ getHierarchyHint(node) }}</div>
              </div>

              <div v-show="isNodeExpanded(node)" class="node-preview-list mb-3 transition-all">
                <div class="preview-header d-flex align-center justify-space-between mb-1">
                  <span class="text-[8px] font-weight-black text-uppercase opacity-65">Preview Fila</span>
                  <span class="text-[8px] font-weight-black opacity-55">{{ Math.min(node.tasks.items.length, 3) }}/{{ node.tasks.items.length }}</span>
                </div>
                <div v-if="node.tasks.items.length" class="d-flex flex-column gap-1">
                  <div v-for="task in node.tasks.items.slice(0, 3)" :key="task.id" class="queue-mini-item">
                    <div class="queue-mini-item__title text-truncate">{{ task.name }}</div>
                    <v-chip size="x-small" :color="getStatusColor(task.statusLabel)" variant="flat" class="font-weight-black text-[7px] px-1 h-auto py-0">{{ task.statusLabel }}</v-chip>
                  </div>
                </div>
                <div v-else class="queue-mini-empty text-[9px]">Fila vazia</div>
              </div>

              <div class="mt-auto d-flex gap-2 flex-wrap">
                <v-btn block size="x-small" variant="flat" color="primary" class="font-weight-black action-btn flex-grow-1" @click.stop="openDrawer(node)">
                  {{ isNodeExpanded(node) ? 'Cockpit' : 'Abrir' }} <v-icon end size="12">mdi-arrow-top-right</v-icon>
                </v-btn>
              </div>
            </div>

            <div :ref="el => setPortInRef(node.id, el)" class="port port-in absolute elevation-4" style="top: -6px; left: 50%; transform: translateX(-50%); pointer-events: none;" />
            <div :ref="el => setPortOutRef(node.id, el)" class="port port-out absolute cursor-crosshair elevation-4" style="bottom: -6px; left: 50%; transform: translateX(-50%);" @mousedown.stop.prevent="startEdge($event, node)" />
          </div>
        </div>
      </main>

      <v-slide-x-reverse-transition>
        <aside
          v-if="drawerNode"
          class="sidebar-properties enterprise-inspector border-l d-flex flex-column z-30 shadow-xl"
          style="width: 460px;"
          :class="isLight ? 'bg-white border-grey-lighten-2 text-grey-darken-4' : 'bg-grey-darken-4 border-grey-darken-2 text-white'"
        >
          <div class="drawer-header border-b flex-shrink-0" :class="isLight ? 'border-grey-lighten-2' : 'border-grey-darken-2'" :style="{ '--drawer-accent': drawerNode.color }">
            <div class="drawer-header__top d-flex justify-space-between align-start gap-3">
              <div class="d-flex align-center gap-3 flex-grow-1 min-w-0">
                <v-avatar :color="drawerNode.color" size="54" class="drawer-header__avatar shrink-0">
                  <v-img v-if="drawerNode.user.avatar" :src="drawerNode.user.avatar" cover />
                  <span v-else class="text-white text-subtitle-1 font-weight-black">{{ drawerNode.user.name.charAt(0) }}</span>
                </v-avatar>

                <div class="drawer-header__identity min-w-0">
                  <div class="drawer-header__eyebrow">Designer cockpit</div>
                  <div class="d-flex align-center gap-2 flex-wrap">
                    <h3 class="drawer-header__name mb-0 text-truncate">{{ drawerNode.user.name }}</h3>
                    <v-chip
                      size="small"
                      :color="getNodeLoadColor(drawerNode)"
                      variant="flat"
                      class="drawer-status-chip"
                    >
                      {{ getNodeLoadLabel(drawerNode) }}
                    </v-chip>
                  </div>
                  <div class="drawer-header__role text-truncate">{{ drawerNode.user.role }}</div>
                </div>
              </div>

              <v-btn icon="mdi-close" size="small" variant="tonal" :color="drawerNode.color" class="shrink-0" @click="closeDrawer" />
            </div>

            <div class="drawer-summary-grid">
              <div class="drawer-summary-card">
                <span>Fila ativa</span>
                <strong>{{ drawerNode.tasks.total }}</strong>
              </div>
              <div class="drawer-summary-card">
                <span>Capacidade</span>
                <strong>{{ getNodeCapacity(drawerNode) }}</strong>
              </div>
              <div class="drawer-summary-card">
                <span>Lidera</span>
                <strong>{{ getNodeRelations(drawerNode.id).led.length }}</strong>
              </div>
              <div class="drawer-summary-card">
                <span>Reporta</span>
                <strong>{{ getNodeRelations(drawerNode.id).leaders.length }}</strong>
              </div>
            </div>

            <div class="drawer-pressure-strip">
              <div class="d-flex align-center justify-space-between mb-2">
                <div>
                  <div class="drawer-strip-label">Pressão operacional</div>
                  <div class="drawer-strip-caption">{{ getSuggestedAction(drawerNode) }}</div>
                </div>
                <div class="drawer-strip-value" :class="getPressureTextClass(drawerNode)">{{ getNodePressurePercent(drawerNode) }}%</div>
              </div>
              <v-progress-linear :model-value="getNodePressurePercent(drawerNode)" :color="getNodeLoadColor(drawerNode)" rounded height="8" />
            </div>
          </div>

          <div class="drawer-tabs-wrap border-b flex-shrink-0" :class="isLight ? 'border-grey-lighten-2' : 'border-grey-darken-2'">
            <v-tabs
              v-model="drawerTab"
              :color="drawerNode.color"
              align-tabs="start"
              class="drawer-tabs"
              density="comfortable"
              grow
            >
              <v-tab value="active" class="drawer-tab-item">
                <v-icon start size="14">mdi-view-dashboard-outline</v-icon>
                Painel operacional
              </v-tab>
              <v-tab value="history" class="drawer-tab-item">
                <v-icon start size="14">mdi-timeline-text-outline</v-icon>
                Histórico & Timeline
              </v-tab>
            </v-tabs>
          </div>

          <div class="drawer-content-wrapper flex-grow-1 min-h-0 overflow-hidden">
            <v-window v-model="drawerTab" class="h-100 drawer-window">

              <v-window-item value="active" class="h-100">
                <div class="drawer-scroll custom-scrollbar">
                  <div class="drawer-shell">
                    <div class="drawer-toolbar">
                      <v-btn color="indigo" size="small" variant="flat" class="font-weight-black btn-3d drawer-toolbar__btn" @click="openEditPermsModal(drawerNode)">
                        <v-icon start size="14">mdi-shield-edit-outline</v-icon>Permissões
                      </v-btn>
                      <v-btn :color="drawerNode.isBlocked ? 'success' : 'warning'" size="small" variant="tonal" class="font-weight-black btn-3d drawer-toolbar__btn" @click="toggleNodeBlock(drawerNode)">
                        <v-icon start size="14">{{ drawerNode.isBlocked ? 'mdi-lock-open-variant' : 'mdi-lock' }}</v-icon>{{ drawerNode.isBlocked ? 'Desbloquear' : 'Bloquear' }}
                      </v-btn>
                      <v-btn color="primary" size="small" variant="tonal" class="font-weight-black btn-3d drawer-toolbar__btn" @click="focusNode(drawerNode)">
                        <v-icon start size="14">mdi-crosshairs-gps</v-icon>Focar
                      </v-btn>
                    </div>

                    <div class="drawer-panel-grid drawer-panel-grid--metrics">
                      <v-card class="drawer-stat-card" :class="isLight ? 'drawer-surface-light' : 'drawer-surface-dark'">
                        <div class="drawer-stat-card__label">Estado atual</div>
                        <div class="drawer-stat-card__value">{{ getNodeLoadLabel(drawerNode) }}</div>
                        <div class="drawer-stat-card__meta">saúde da célula</div>
                      </v-card>

                      <v-card class="drawer-stat-card" :class="isLight ? 'drawer-surface-light' : 'drawer-surface-dark'">
                        <div class="drawer-stat-card__label">Backend role</div>
                        <div class="drawer-stat-card__value drawer-stat-card__value--sm text-truncate">{{ drawerNode.user.custom_role_id || 'N/A' }}</div>
                        <div class="drawer-stat-card__meta">escopo de api</div>
                      </v-card>

                      <v-card class="drawer-stat-card" :class="isLight ? 'drawer-surface-light' : 'drawer-surface-dark'">
                        <div class="drawer-stat-card__label">Hierarquia</div>
                        <div class="drawer-stat-card__value drawer-stat-card__value--sm">{{ getHierarchyHint(drawerNode) }}</div>
                        <div class="drawer-stat-card__meta">posição na malha</div>
                      </v-card>
                    </div>

                    <div class="drawer-panel-grid drawer-panel-grid--two">
                      <section class="drawer-panel">
                        <div class="drawer-panel__head">
                          <div class="section-title"><v-icon size="14" class="mr-1">mdi-shield-account</v-icon> Governança</div>
                          <div class="drawer-panel__sub">Permissões e nível de autonomia</div>
                        </div>

                        <div class="drawer-panel__body" :class="isLight ? 'drawer-surface-light' : 'drawer-surface-dark'">
                          <div class="perm-row"><span>Líder do setor</span><v-icon size="14" :color="drawerNode.perms.isLeader ? 'success' : 'grey'">{{ drawerNode.perms.isLeader ? 'mdi-check-circle' : 'mdi-minus-circle' }}</v-icon></div>
                          <div class="perm-row"><span>Pode aprovar</span><v-icon size="14" :color="drawerNode.perms.canApprove ? 'success' : 'grey'">{{ drawerNode.perms.canApprove ? 'mdi-check-circle' : 'mdi-minus-circle' }}</v-icon></div>
                          <div class="perm-row"><span>Requer aprovação</span><v-icon size="14" :color="drawerNode.perms.requiresApproval ? 'error' : 'grey'">{{ drawerNode.perms.requiresApproval ? 'mdi-check-circle' : 'mdi-minus-circle' }}</v-icon></div>
                        </div>
                      </section>

                      <section class="drawer-panel">
                        <div class="drawer-panel__head">
                          <div class="section-title"><v-icon size="14" class="mr-1">mdi-source-branch</v-icon> Hierarquia</div>
                          <div class="drawer-panel__sub">Relações diretas de liderança</div>
                        </div>

                        <div class="drawer-panel__body" :class="isLight ? 'drawer-surface-light' : 'drawer-surface-dark'">
                          <div class="drawer-chip-block">
                            <div class="drawer-chip-block__label">Reporta para</div>
                            <div v-if="getNodeRelations(drawerNode.id).leaders.length" class="d-flex flex-wrap gap-2">
                              <v-chip
                                v-for="leader in getNodeRelations(drawerNode.id).leaders"
                                :key="leader.id"
                                size="small"
                                :color="leader.color"
                                variant="flat"
                                class="drawer-inline-chip text-white"
                              >
                                {{ leader.user.name }}
                              </v-chip>
                            </div>
                            <div v-else class="drawer-empty-note">Sem liderança acima.</div>
                          </div>

                          <div class="drawer-chip-block">
                            <div class="drawer-chip-block__label">Conduz</div>
                            <div v-if="getNodeRelations(drawerNode.id).led.length" class="d-flex flex-wrap gap-2">
                              <v-chip
                                v-for="member in getNodeRelations(drawerNode.id).led"
                                :key="member.id"
                                size="small"
                                :color="member.color"
                                variant="tonal"
                                class="drawer-inline-chip"
                              >
                                {{ member.user.name }}
                              </v-chip>
                            </div>
                            <div v-else class="drawer-empty-note">Sem equipe direta.</div>
                          </div>
                        </div>
                      </section>
                    </div>

                    <div class="drawer-panel-grid drawer-panel-grid--two">
                      <section class="drawer-panel">
                        <div class="drawer-panel__head">
                          <div class="section-title"><v-icon size="14" class="mr-1">mdi-radar</v-icon> Operacional</div>
                          <div class="drawer-panel__sub">Leitura rápida do quadro</div>
                        </div>

                        <div class="drawer-panel__body" :class="isLight ? 'drawer-surface-light' : 'drawer-surface-dark'">
                          <div class="drawer-kv"><span>Carga atual</span><strong>{{ drawerNode.tasks.total }} / {{ getNodeCapacity(drawerNode) }}</strong></div>
                          <div class="drawer-kv"><span>Status</span><strong>{{ getNodeLoadLabel(drawerNode) }}</strong></div>
                          <div class="drawer-kv"><span>Hierarquia</span><strong>{{ getHierarchyHint(drawerNode) }}</strong></div>
                          <div class="drawer-kv"><span>Ação sugerida</span><strong>{{ getSuggestedAction(drawerNode) }}</strong></div>
                        </div>
                      </section>

                      <section class="drawer-panel">
                        <div class="drawer-panel__head">
                          <div class="section-title"><v-icon size="14" class="mr-1">mdi-tray-arrow-down</v-icon> Recebimento rápido</div>
                          <div class="drawer-panel__sub">Arraste uma arte para atribuição direta</div>
                        </div>

                        <v-card
                          class="drawer-dropzone"
                          :class="[isLight ? 'drawer-surface-light' : 'drawer-surface-dark', dragOverNodeId === drawerNode.id ? 'dropzone-card--active' : '']"
                          @dragover.prevent="onNodeDragOver($event, drawerNode)"
                          @dragleave.prevent="dragOverNodeId = null"
                          @drop="onNodeDrop($event, drawerNode)"
                        >
                          <v-icon size="28" :color="drawerNode.color" class="mb-2">mdi-arrow-down-circle-outline</v-icon>
                          <div class="drawer-dropzone__title">Solte cards aqui</div>
                          <div class="drawer-dropzone__caption">Atribuição direta para {{ drawerNode.user.name.split(' ')[0] }}</div>
                        </v-card>
                      </section>
                    </div>

                    <section class="drawer-panel">
                      <div class="drawer-panel__head drawer-panel__head--spaced">
                        <div>
                          <div class="section-title mb-1"><v-icon size="14" class="mr-1">mdi-palette-swatch</v-icon> Fila atual</div>
                          <div class="drawer-panel__sub">Artes em andamento deste usuário</div>
                        </div>
                        <v-chip size="small" color="primary" variant="tonal" class="font-weight-black">{{ drawerNode.tasks.total }} itens</v-chip>
                      </div>

                      <div v-if="drawerNode.tasks.items.length === 0" class="drawer-empty-state" :class="isLight ? 'drawer-surface-light' : 'drawer-surface-dark'">
                        <v-icon size="26" class="mb-2">mdi-tray-remove</v-icon>
                        <div class="drawer-empty-state__title">Nenhuma arte pendente</div>
                        <div class="drawer-empty-state__caption">Esse designer está sem itens ativos no momento.</div>
                      </div>

                      <div v-else class="drawer-task-list">
                        <v-card
                          v-for="(task, i) in drawerNode.tasks.items"
                          :key="i"
                          draggable="true"
                          @dragstart="onDragStartTask($event, task, drawerNode.id)"
                          class="designer-task-card cursor-grab"
                          :class="isLight ? 'designer-task-card--light' : 'designer-task-card--dark'"
                        >
                          <div class="designer-task-card__top">
                            <div class="designer-task-card__code">
                              {{ task.type === 'order' ? `OP #${String(task.order_number).padStart(4,'0')}` : `DEV #${String(task.id).substring(0,6)}` }}
                            </div>
                            <v-chip size="small" :color="getStatusColor(task.statusLabel)" variant="flat" class="designer-task-card__chip">
                              {{ task.statusLabel }}
                            </v-chip>
                          </div>

                          <div class="designer-task-card__title" :title="task.name">{{ task.name }}</div>

                          <div class="designer-task-card__meta">
                            <v-icon size="13">mdi-domain</v-icon>
                            <span class="text-truncate">{{ task.customer_name || 'Uso Interno' }}</span>
                          </div>

                          <div class="designer-task-card__footer">
                            <div class="designer-task-card__time">
                              <v-icon size="13" class="mr-1">mdi-clock-outline</v-icon>{{ formatDate(task.created_at) }}
                            </div>
                            <v-icon color="grey" size="14">mdi-drag-horizontal-variant</v-icon>
                          </div>
                        </v-card>
                      </div>

                      <v-alert color="info" variant="tonal" class="drawer-tip" density="comfortable" icon="mdi-cursor-pointer">
                        Arraste qualquer card para redistribuir entre designers.
                      </v-alert>
                    </section>
                  </div>
                </div>
              </v-window-item>

              <v-window-item value="history" class="h-100">
                <div class="drawer-scroll custom-scrollbar">
                  <div v-if="!drawerNode.historyTasks || drawerNode.historyTasks.length === 0" class="drawer-empty-state drawer-empty-state--history" :class="isLight ? 'drawer-surface-light' : 'drawer-surface-dark'">
                    <v-icon size="36" class="mb-3">mdi-clipboard-text-clock-outline</v-icon>
                    <div class="drawer-empty-state__title">Sem histórico finalizado</div>
                    <div class="drawer-empty-state__caption">Nenhum registro de artes concluídas foi localizado para este usuário.</div>
                  </div>

                  <div v-else class="drawer-history-shell">
                    <div class="drawer-history-head">
                      <div>
                        <div class="section-title mb-1"><v-icon size="14" class="mr-1">mdi-history</v-icon> Auditoria de entregas</div>
                        <div class="drawer-panel__sub">Últimas {{ drawerNode.historyTasks.length }} artes concluídas por este designer</div>
                      </div>
                    </div>

                    <v-expansion-panels variant="accordion" class="history-panels">
                      <v-expansion-panel
                        v-for="(hTask, i) in drawerNode.historyTasks"
                        :key="i"
                        class="history-panel-item"
                        :class="isLight ? 'history-panel-item--light' : 'history-panel-item--dark'"
                      >
                        <v-expansion-panel-title class="history-panel-title">
                          <div class="history-summary w-100">
                            <div class="history-summary__main">
                              <div class="history-summary__title" :title="hTask.name">{{ hTask.name }}</div>
                              <div class="history-summary__meta">
                                <v-icon size="12">mdi-domain</v-icon>
                                <span class="text-truncate">{{ hTask.customer_name }}</span>
                              </div>
                            </div>

                            <div class="history-summary__aside">
                              <v-chip size="small" color="success" variant="flat" class="font-weight-black">Finalizado</v-chip>
                              <div class="history-summary__time">{{ formatDate(hTask.finished_at) }}</div>
                            </div>
                          </div>
                        </v-expansion-panel-title>

                        <v-expansion-panel-text class="history-panel-body">
                          <div class="history-panel-body__inner">
                            <v-timeline density="comfortable" align="start" side="end" truncate-line="both" class="workflow-timeline" line-thickness="2">
                              <v-timeline-item
                                v-for="(event, idx) in hTask.events"
                                :key="idx"
                                :dot-color="getEventColor(event.type)"
                                size="small"
                                fill-dot
                              >
                                <div class="timeline-event-card">
                                  <div class="d-flex align-center justify-space-between gap-3">
                                    <strong class="timeline-title">{{ event.title }}</strong>
                                    <span class="timeline-meta timeline-meta--time">{{ formatDate(event.timestamp) }}</span>
                                  </div>

                                  <div v-if="event.user" class="timeline-meta timeline-meta--user mt-2">
                                    <v-icon size="12" class="mr-1">mdi-account</v-icon>{{ event.user }}
                                  </div>

                                  <div v-if="event.notes" class="timeline-note" :class="getEventNoteBg(event.type)">
                                    {{ event.notes }}
                                  </div>

                                  <div v-if="event.art_url" class="timeline-thumb mt-3">
                                    <v-img :src="event.art_url" height="64" width="64" cover class="rounded-lg border shadow-sm" />
                                  </div>
                                </div>
                              </v-timeline-item>
                            </v-timeline>
                          </div>
                        </v-expansion-panel-text>
                      </v-expansion-panel>
                    </v-expansion-panels>
                  </div>
                </div>
              </v-window-item>

            </v-window>
          </div>
        </aside>
      </v-slide-x-reverse-transition>

      <div
        class="floating-tray transition-all d-flex flex-column"
        :class="[isTrayExpanded ? 'tray-expanded' : 'tray-collapsed', isLight ? 'tray-light' : 'tray-dark']"
      >
        <div class="tray-shell d-flex flex-column h-100">
          <div class="tray-handle cursor-pointer flex-shrink-0" @click="isTrayExpanded = !isTrayExpanded">
            <div class="tray-handle__inner">
              <div class="handle-bar rounded-pill"></div>
              <div class="tray-handle__label">
                <v-icon size="14" class="mr-1">{{ isTrayExpanded ? 'mdi-chevron-down' : 'mdi-chevron-up' }}</v-icon>
                {{ isTrayExpanded ? 'Recolher fila global' : 'Fila global limbo (' + totalUnassignedArts + ' artes)' }}
              </div>
            </div>
          </div>

          <template v-if="isTrayExpanded">
            <div class="tray-header border-b" :class="isLight ? 'border-grey-lighten-2' : 'border-grey-darken-2'">
              <div class="tray-header__main">
                <div class="d-flex align-center gap-2">
                  <v-avatar size="28" color="warning" class="text-white"><v-icon size="16">mdi-inbox-multiple</v-icon></v-avatar>
                  <div>
                    <div class="tray-header__title">Fila sem responsável</div>
                    <div class="tray-header__subtitle">Itens aguardando distribuição manual</div>
                  </div>
                </div>
                <v-chip size="small" color="warning" variant="tonal" class="font-weight-black">
                  {{ totalUnassignedArts }} itens
                </v-chip>
              </div>
            </div>

            <div class="tray-content custom-scrollbar">
              <div v-if="Object.keys(groupedUnassignedTasks).length === 0" class="tray-empty">
                <v-icon size="26" class="mb-2">mdi-check-all</v-icon>
                <div class="tray-empty__title">Limbo vazio</div>
                <div class="tray-empty__caption">Não existem artes sem responsável neste momento.</div>
              </div>

              <div v-else class="tray-lanes">
                <div
                  v-for="(tasks, groupName) in groupedUnassignedTasks"
                  :key="groupName"
                  class="tray-column"
                  :class="isLight ? 'tray-column--light' : 'tray-column--dark'"
                >
                  <div class="tray-column-head">
                    <div class="tray-column-head__title">{{ groupName }}</div>
                    <v-chip size="small" color="primary" variant="flat" class="font-weight-black">{{ tasks.length }}</v-chip>
                  </div>

                  <div class="tray-cards-container custom-scrollbar">
                    <v-card
                      v-for="(task, i) in tasks"
                      :key="i"
                      draggable="true"
                      @dragstart="onDragStartTask($event, task, null)"
                      class="tray-art-card cursor-grab"
                      :class="isLight ? 'tray-art-card--light' : 'tray-art-card--dark'"
                    >
                      <div class="tray-art-card__code">
                        {{ task.type === 'order' ? `OP #${String(task.order_number).padStart(4,'0')}` : `DEV #${String(task.id).substring(0,6)}` }}
                      </div>
                      <div class="tray-art-card__title">{{ task.name }}</div>
                      <div class="tray-art-card__meta">
                        <v-icon size="12">mdi-domain</v-icon>
                        <span class="text-truncate">{{ task.customer_name || 'Uso Interno' }}</span>
                      </div>
                      <div class="tray-art-card__footer">
                        <v-chip size="x-small" :color="getStatusColor(task.statusLabel)" variant="tonal" class="font-weight-black">
                          {{ task.statusLabel }}
                        </v-chip>
                        <v-icon color="grey" size="13">mdi-drag-horizontal-variant</v-icon>
                      </div>
                    </v-card>
                  </div>
                </div>
              </div>
            </div>
          </template>
        </div>
      </div>
      </div>
    <v-dialog v-model="permsModal.show" max-width="400" persistent>
      <v-card class="rounded-xl overflow-hidden shadow-xl" :class="isLight ? 'bg-white' : 'bg-grey-darken-4'">
        <div class="pa-3 border-b d-flex justify-space-between align-center bg-indigo-darken-3 text-white">
          <div class="font-weight-black text-uppercase text-[11px]"><v-icon start size="14">mdi-shield-account</v-icon> Permissões Design</div>
          <v-btn icon="mdi-close" variant="text" size="x-small" color="white" @click="permsModal.show = false" />
        </div>
        <div class="pa-4" v-if="permsModal.node">
          <div class="d-flex align-center gap-3 mb-4">
            <v-avatar size="36" color="indigo-lighten-4" class="text-indigo-darken-4 font-weight-black"><v-img v-if="permsModal.node.user.avatar" :src="permsModal.node.user.avatar" cover /><span v-else>{{ permsModal.node.user.name.charAt(0) }}</span></v-avatar>
            <div>
              <div class="text-subtitle-2 font-weight-black lh-1">{{ permsModal.node.user.name }}</div>
              <div class="text-[10px] opacity-70">{{ permsModal.node.user.role }}</div>
            </div>
          </div>

          <v-card class="border-thin shadow-sm rounded-lg overflow-hidden" elevation="0" :class="isLight ? 'bg-grey-lighten-5' : 'bg-grey-darken-3'">
            <v-list density="compact" class="bg-transparent pa-0">
              <v-list-item class="py-1">
                <template #prepend><v-switch v-model="permsModal.isLeader" color="indigo" hide-details density="compact" class="mr-2 switch-small" /></template>
                <v-list-item-title class="font-weight-bold text-[11px]">Líder do Setor</v-list-item-title>
              </v-list-item>
              <v-divider />
              <v-list-item class="py-1" :disabled="permsModal.isLeader">
                <template #prepend><v-switch v-model="permsModal.canApprove" color="success" hide-details density="compact" class="mr-2 switch-small" :disabled="permsModal.isLeader" /></template>
                <v-list-item-title class="font-weight-bold text-[11px]">Pode Aprovar Artes</v-list-item-title>
              </v-list-item>
              <v-divider />
              <v-list-item class="py-1" :disabled="permsModal.isLeader || permsModal.canApprove">
                <template #prepend><v-switch v-model="permsModal.requiresApproval" color="error" hide-details density="compact" class="mr-2 switch-small" :disabled="permsModal.isLeader || permsModal.canApprove" /></template>
                <v-list-item-title class="font-weight-bold text-[11px]">Requer Aprovação</v-list-item-title>
              </v-list-item>
            </v-list>
          </v-card>
          <v-btn block color="indigo" class="mt-4 font-weight-black btn-3d" size="small" @click="savePermissions" :loading="permsModal.loading">Salvar permissões</v-btn>
        </div>
      </v-card>
    </v-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted, onUnmounted } from 'vue';
import { supabase } from '@/api/supabase';
import { useThemeStore } from '@/stores/theme';
import { useAppStore } from '@/stores/app';
import { format, parseISO } from 'date-fns';
import { ptBR } from 'date-fns/locale';

const themeStore = useThemeStore();
const appStore = useAppStore();
const isLight = computed(() => themeStore.currentMode === 'light');

const drawerTab = ref('active');

interface WorkflowEvent {
  type: 'created' | 'approval_request' | 'rejected' | 'approved' | 'finished';
  title: string;
  timestamp: string;
  user: string;
  notes?: string;
  art_url?: string;
}

interface HistoryTaskItem {
  id: string;
  name: string;
  customer_name: string;
  finished_at: string;
  events: WorkflowEvent[];
}

interface TaskRequest { id: string; profile: { full_name: string; avatar_url: string; }; designer_id: string; created_at: string; }
interface TaskItem { id: string; name: string; statusLabel: string; type: 'order' | 'development'; order_number?: number; customer_name?: string; created_at: string; requests?: TaskRequest[]; original: any; }
interface OrgNode {
  id: string; user: { id: string; name: string; role: string; avatar: string; custom_role_id: string; };
  perms: { isLeader: boolean; canApprove: boolean; requiresApproval: boolean; };
  tasks: { total: number; items: TaskItem[] };
  historyTasks: HistoryTaskItem[];
  ui_x: number; ui_y: number; color: string; isBlocked: boolean;
}
interface OrgEdge { id: string; fromId: string; toId: string; }

const loading = ref(true);
const loadingSave = ref(false);
const nodes = ref<OrgNode[]>([]);
const edges = ref<OrgEdge[]>([]);
const selectedNodeId = ref<string | null>(null);
const hoveredEdgeId = ref<string | null>(null);
const drawerNode = ref<OrgNode | null>(null);

const searchQuery = ref('');
const roleFilter = ref('all');
const showOnlyOverloaded = ref(false);
const compactCards = ref(true);
const expandedNodeIds = ref<string[]>([]);
const roleFilterOptions = [
  { title: 'Todos', value: 'all' },
  { title: 'Líderes', value: 'leader' },
  { title: 'Aprovadores', value: 'approver' },
  { title: 'Júnior/Revisão', value: 'junior' },
  { title: 'Plenos', value: 'mid' },
  { title: 'Bloqueados', value: 'blocked' },
];

const permsModal = reactive({ show: false, loading: false, node: null as OrgNode | null, isLeader: false, canApprove: false, requiresApproval: false });

const workspaceRef = ref<HTMLElement | null>(null);
const nodeElementRefs = new Map<string, HTMLElement>();
const portInRefs = new Map<string, HTMLElement>();
const portOutRefs = new Map<string, HTMLElement>();
const edgeRenderTick = ref(0);
const hoverConnectNodeId = ref<string | null>(null);
const transform = reactive({ x: 0, y: 0, scale: 1 });
let isPanning = false;
let startPan = { x: 0, y: 0 };
let isDraggingNode = false;
let draggedNodeId: string | null = null;
let nodeOffset = { x: 0, y: 0 };

const drawingEdge = reactive({ active: false, sourceNodeId: null as string | null, startX: 0, startY: 0, currentX: 0, currentY: 0 });

const getEventColor = (type: string) => {
  const map: Record<string, string> = { 'created': 'grey', 'approval_request': 'info', 'rejected': 'error', 'approved': 'success', 'finished': 'deep-purple' };
  return map[type] || 'primary';
};
const getEventNoteBg = (type: string) => {
  return type === 'rejected' ? 'bg-error text-error bg-opacity-20' : (type === 'approved' ? 'bg-success text-success bg-opacity-20' : 'bg-black-10');
};

const gridStyle = computed(() => {
  const size = 48 * transform.scale;
  return { '--grid-position-x': `${transform.x}px`, '--grid-position-y': `${transform.y}px`, '--grid-size': `${size}px` };
});

const totalActiveArts = computed(() => nodes.value.reduce((acc, node) => acc + node.tasks.total, 0));
const leaderCount = computed(() => nodes.value.filter(n => n.perms.isLeader).length);
const blockedCount = computed(() => nodes.value.filter(n => n.isBlocked).length);
const rootCount = computed(() => nodes.value.filter(n => !edges.value.some(e => e.toId === n.id)).length);
const overloadedCount = computed(() => nodes.value.filter(n => getNodeLoadLevel(n) === 'critical').length);
const maxLoadDisplay = computed(() => {
  const biggest = [...nodes.value].sort((a, b) => b.tasks.total - a.tasks.total)[0];
  if (!biggest) return '0';
  return `${biggest.user.name.split(' ')[0]} (${biggest.tasks.total})`;
});

const networkHealthScore = computed(() => {
  const penalty = (totalUnassignedArts.value * 8) + (blockedCount.value * 10) + (overloadedCount.value * 14);
  return Math.max(15, Math.min(100, 100 - penalty));
});
const networkHealthLabel = computed(() => {
  if (networkHealthScore.value >= 85) return 'Alta estabilidade';
  if (networkHealthScore.value >= 65) return 'Boa, mas exigindo atenção';
  if (networkHealthScore.value >= 45) return 'Pressionada';
  return 'Crítica';
});
const networkHealthColor = computed(() => {
  if (networkHealthScore.value >= 85) return 'success';
  if (networkHealthScore.value >= 65) return 'info';
  if (networkHealthScore.value >= 45) return 'warning';
  return 'error';
});
const networkHealthIcon = computed(() => {
  if (networkHealthScore.value >= 85) return 'mdi-shield-check';
  if (networkHealthScore.value >= 65) return 'mdi-pulse';
  if (networkHealthScore.value >= 45) return 'mdi-alert';
  return 'mdi-alert-octagon';
});

const isTrayExpanded = ref(false);
const unassignedTasks = ref<TaskItem[]>([]);
const draggedTaskInfo = ref<{ task: TaskItem, sourceNodeId: string | null } | null>(null);
const dragOverNodeId = ref<string | null>(null);
const activeAnimations = ref<any[]>([]);

let edgeRefreshQueued = false;
const queueEdgeRefresh = () => {
  if (edgeRefreshQueued) return;
  edgeRefreshQueued = true;
  requestAnimationFrame(() => {
    edgeRenderTick.value++;
    edgeRefreshQueued = false;
  });
};

const setNodeElementRef = (nodeId: string, el: Element | null) => {
  if (el instanceof HTMLElement) nodeElementRefs.set(nodeId, el);
  else nodeElementRefs.delete(nodeId);
};
const setPortInRef = (nodeId: string, el: Element | null) => {
  if (el instanceof HTMLElement) portInRefs.set(nodeId, el);
  else portInRefs.delete(nodeId);
};
const setPortOutRef = (nodeId: string, el: Element | null) => {
  if (el instanceof HTMLElement) portOutRefs.set(nodeId, el);
  else portOutRefs.delete(nodeId);
};

const getCanvasPointFromElement = (el: HTMLElement | undefined | null) => {
  if (!el || !workspaceRef.value) return null;
  const workspaceRect = workspaceRef.value.getBoundingClientRect();
  const rect = el.getBoundingClientRect();
  return {
    x: (rect.left + rect.width / 2 - workspaceRect.left - transform.x) / transform.scale,
    y: (rect.top + rect.height / 2 - workspaceRect.top - transform.y) / transform.scale,
  };
};

const getNodePortPoint = (nodeId: string, type: 'in' | 'out') => {
  edgeRenderTick.value;
  const byPort = type === 'in' ? getCanvasPointFromElement(portInRefs.get(nodeId)) : getCanvasPointFromElement(portOutRefs.get(nodeId));
  if (byPort) return byPort;

  const node = nodes.value.find(n => n.id === nodeId);
  const nodeEl = nodeElementRefs.get(nodeId);
  if (node && nodeEl) {
    const workspaceRect = workspaceRef.value?.getBoundingClientRect();
    const rect = nodeEl.getBoundingClientRect();
    if (workspaceRect) {
      return {
        x: (rect.left + rect.width / 2 - workspaceRect.left - transform.x) / transform.scale,
        y: type === 'out'
          ? (rect.bottom - workspaceRect.top - transform.y) / transform.scale
          : (rect.top - workspaceRect.top - transform.y) / transform.scale,
      };
    }
  }

  if (!node) return null;
  // Ajuste do centro com base no width default do expanded vs compact
  const w = isNodeExpanded(node) ? 280 : 230;
  return { x: node.ui_x + (w/2), y: type === 'out' ? node.ui_y + 140 : node.ui_y };
};

const getNodeRelations = (nodeId: string) => ({
  leaders: edges.value.filter(e => e.toId === nodeId).map(e => nodes.value.find(n => n.id === e.fromId)).filter(Boolean) as OrgNode[],
  led: edges.value.filter(e => e.fromId === nodeId).map(e => nodes.value.find(n => n.id === e.toId)).filter(Boolean) as OrgNode[],
});

const getNodeCapacity = (node: OrgNode) => {
  if (node.perms.isLeader) return 14;
  if (node.perms.canApprove) return 10;
  if (node.perms.requiresApproval) return 6;
  return 8;
};
const getNodePressurePercent = (node: OrgNode) => Math.min(100, Math.round((node.tasks.total / Math.max(1, getNodeCapacity(node))) * 100));
const getNodeLoadLevel = (node: OrgNode) => {
  const p = getNodePressurePercent(node);
  if (node.isBlocked) return 'blocked';
  if (p >= 90) return 'critical';
  if (p >= 65) return 'attention';
  return 'healthy';
};
const getNodeLoadLabel = (node: OrgNode) => {
  const level = getNodeLoadLevel(node);
  if (level === 'blocked') return 'Bloqueado';
  if (level === 'critical') return 'Crítico';
  if (level === 'attention') return 'Atenção';
  return 'Saudável';
};
const getNodeLoadColor = (node: OrgNode) => {
  const level = getNodeLoadLevel(node);
  if (level === 'blocked') return 'grey';
  if (level === 'critical') return 'error';
  if (level === 'attention') return 'warning';
  return 'success';
};
const getPressureTextClass = (node: OrgNode) => {
  const level = getNodeLoadLevel(node);
  if (level === 'critical') return 'text-error';
  if (level === 'attention') return 'text-warning';
  return 'text-success';
};
const getHierarchyHint = (node: OrgNode) => {
  const rel = getNodeRelations(node.id);
  if (!rel.leaders.length && rel.led.length) return 'Topo de célula';
  if (!rel.leaders.length && !rel.led.length) return 'Isolado';
  if (rel.leaders.length && rel.led.length) return 'Intermediário';
  return 'Operação final';
};
const getSuggestedAction = (node: OrgNode) => {
  const level = getNodeLoadLevel(node);
  if (node.isBlocked) return 'Desbloquear ou isolar';
  if (level === 'critical') return 'Redistribuir artes';
  if (level === 'attention') return 'Monitorar perto';
  if (!getNodeRelations(node.id).leaders.length && !node.perms.isLeader) return 'Definir liderança';
  return 'Fluxo estável';
};

const totalUnassignedArts = computed(() => unassignedTasks.value.length);
const groupedUnassignedTasks = computed(() => {
  const groups: Record<string, TaskItem[]> = {};
  unassignedTasks.value.forEach(t => {
    const group = t.statusLabel || 'Geral';
    if (!groups[group]) groups[group] = [];
    groups[group].push(t);
  });
  return groups;
});

const filteredNodes = computed(() => {
  const q = searchQuery.value.trim().toLowerCase();
  return nodes.value.filter(node => {
    const roleMatch = roleFilter.value === 'all'
      || (roleFilter.value === 'leader' && node.perms.isLeader)
      || (roleFilter.value === 'approver' && node.perms.canApprove)
      || (roleFilter.value === 'junior' && node.perms.requiresApproval)
      || (roleFilter.value === 'mid' && !node.perms.isLeader && !node.perms.canApprove && !node.perms.requiresApproval)
      || (roleFilter.value === 'blocked' && node.isBlocked);

    const overloadMatch = !showOnlyOverloaded.value || getNodeLoadLevel(node) === 'critical';
    const textMatch = !q || [
      node.user.name,
      node.user.role,
      node.user.custom_role_id,
      ...node.tasks.items.slice(0, 6).map(t => `${t.name} ${t.statusLabel} ${t.customer_name || ''}`)
    ].join(' ').toLowerCase().includes(q);

    return roleMatch && overloadMatch && textMatch;
  });
});

const visibleNodeIds = computed(() => new Set(filteredNodes.value.map(n => n.id)));
const visibleEdges = computed(() => edges.value.filter(e => visibleNodeIds.value.has(e.fromId) && visibleNodeIds.value.has(e.toId)));

const isNodeExpanded = (node: OrgNode) => !compactCards.value || expandedNodeIds.value.includes(node.id);
const toggleNodeExpanded = (node: OrgNode) => {
  if (!expandedNodeIds.value.includes(node.id)) expandedNodeIds.value = [...expandedNodeIds.value, node.id];
  else expandedNodeIds.value = expandedNodeIds.value.filter(id => id !== node.id);
  queueEdgeRefresh();
};

const formatDate = (d: string) => d ? format(parseISO(d), 'dd/MM/yy HH:mm', { locale: ptBR }) : '';
const getStatusColor = (status: string) => {
  if (status.includes('Líder')) return 'deep-purple';
  if (status.includes('Alteração')) return 'warning';
  if (status.includes('Aprovado')) return 'success';
  return 'primary';
};

onMounted(async () => {
  await fetchRealData();
  queueEdgeRefresh();
  window.addEventListener('mousemove', handleGlobalMouseMove);
  window.addEventListener('mouseup', handleGlobalMouseUp);
  window.addEventListener('resize', queueEdgeRefresh);
});

onUnmounted(() => {
  window.removeEventListener('mousemove', handleGlobalMouseMove);
  window.removeEventListener('mouseup', handleGlobalMouseUp);
  window.removeEventListener('resize', queueEdgeRefresh);
});

const fetchRealData = async () => {
  loading.value = true;
  try {
    const { data: teamData } = await supabase.from('design_user_permissions').select(`*, profile:profiles!design_user_permissions_user_id_fkey(id, full_name, role, custom_role_id, avatar_url)`);
    const { data: requestsData } = await supabase.from('design_assignment_requests').select('*, profile:profiles!design_assignment_requests_designer_id_fkey(full_name, avatar_url)').eq('status', 'pending');

    const designStatuses = ['design_pending', 'customer_approval', 'changes_requested', 'approved_by_designer', 'approved_by_seller'];
    const { data: ordersWithItems } = await supabase.from('orders').select(`id, order_number, customer_name, designer_id, created_at, order_items!inner(id, stamp_ref, status, design_tag, created_at)`).in('order_items.status', designStatuses);
    const { data: devTasks } = await supabase.from('design_requests').select('id, dev_code, status, design_tag, designer_id, created_at, design_items').in('status', ['design_pending', 'in_design', 'finalizing']);

    // Auditoria Verídica
    const historyStatuses = ['approved_by_seller', 'production_queue', 'in_printing', 'in_cutting', 'completed', 'delivered'];
    const { data: historyOrders } = await supabase.from('orders')
      .select(`
        id, customer_name, designer_id, created_at,
        creator:profiles!orders_created_by_fkey(full_name),
        order_items!inner(id, stamp_ref, created_at, updated_at, notes, status, stamp_image_url),
        order_logs(id, log_type, description, created_at, profile:profiles!order_logs_profile_id_fkey(full_name))
      `)
      .in('order_items.status', historyStatuses)
      .not('designer_id', 'is', null);

    const { data: devHistory } = await supabase.from('design_requests')
      .select(`
        id, dev_code, status, designer_id, created_at, general_notes, final_art_url, design_items, request_type,
        creator:profiles!design_requests_created_by_fkey(full_name)
      `)
      .in('status', ['pending_approval', 'approved', 'completed'])
      .not('designer_id', 'is', null);

    const { data: rejectionLogs } = await supabase.from('design_rejection_logs')
      .select('item_id, reason, created_at, leader:profiles!design_rejection_logs_leader_id_fkey(full_name)');

    const builtNodes: OrgNode[] = [];
    const orphans: TaskItem[] = [];
    const localPrefs = JSON.parse(localStorage.getItem('orgchart_layout') || '[]');
    const localEdges = JSON.parse(localStorage.getItem('orgchart_edges') || 'null');
    if (localEdges) edges.value = localEdges;

    const orderTasksFlat: any[] = [];
    (ordersWithItems || []).forEach((order: any) => {
      order.order_items.forEach((item: any) => {
        orderTasksFlat.push({
          id: item.id, stamp_ref: item.stamp_ref, status: item.status, design_tag: item.design_tag,
          designer_id: order.designer_id, order_id: order.id, customer_name: order.customer_name,
          order_number: order.order_number, created_at: item.created_at || order.created_at
        });
      });
    });

    const mapTask = (t: any, type: 'order' | 'development'): TaskItem => {
      let custName = t.customer_name;
      if (type === 'development' && t.design_items) {
        try {
          const items = typeof t.design_items === 'string' ? JSON.parse(t.design_items) : t.design_items;
          if (items[0]?.customer_name) custName = items[0].customer_name;
        } catch (e) {}
      }
      const taskReqs = (requestsData || []).filter(req => (type === 'order' ? req.order_id === t.order_id : req.item_id === t.id));
      return {
        id: t.id,
        name: type === 'order' ? `${t.stamp_ref || 'S/ Ref'}` : `${t.dev_code || 'S/ Cod'}`,
        statusLabel: t.design_tag || (type === 'order' ? 'Design' : 'Desenvolvimento'),
        type,
        order_number: t.order_number,
        customer_name: custName,
        created_at: t.created_at,
        requests: taskReqs.length > 0 ? taskReqs : undefined,
        original: t,
      };
    };

    orderTasksFlat.forEach(t => { if (!t.designer_id) orphans.push(mapTask(t, 'order')); });
    (devTasks || []).forEach(t => { if (!t.designer_id) orphans.push(mapTask(t, 'development')); });
    unassignedTasks.value = orphans;

    let hasSavedPositions = false;
    if (teamData) {
      teamData.forEach(item => {
        if (!item.profile) return;
        const userOrderTasks = orderTasksFlat.filter(t => t.designer_id === item.user_id).map(t => mapTask(t, 'order'));
        const userDevTasks = (devTasks || []).filter(t => t.designer_id === item.user_id).map(t => mapTask(t, 'development'));
        const allUserTasks = [...userOrderTasks, ...userDevTasks];

        const compiledHistoryTasks: HistoryTaskItem[] = [];

        const userHistoryOrders = (historyOrders || []).filter((o: any) => o.designer_id === item.user_id);
        userHistoryOrders.forEach((o: any) => {
            o.order_items.forEach((oi: any) => {
                const events: WorkflowEvent[] = [];
                events.push({
                    type: 'created',
                    title: 'Arte Solicitada',
                    timestamp: oi.created_at || o.created_at,
                    user: o.creator?.full_name || 'Vendedor',
                    notes: oi.notes
                });

                const rejections = (rejectionLogs || []).filter((r: any) => r.item_id === oi.id);
                rejections.forEach((r: any) => {
                    events.push({
                        type: 'rejected',
                        title: 'Ajuste Solicitado',
                        timestamp: r.created_at,
                        user: r.leader?.full_name || 'Revisor/Líder',
                        notes: r.reason
                    });
                });

                const logs = (o.order_logs || []).filter((l: any) => l.description?.includes(oi.stamp_ref));
                logs.forEach((l: any) => {
                    if(l.description?.toLowerCase().includes('aprovad')) {
                        events.push({
                            type: 'approved',
                            title: 'Arte Aprovada',
                            timestamp: l.created_at,
                            user: l.profile?.full_name || 'Avaliador',
                            notes: l.description
                        });
                    }
                });

                events.push({
                    type: 'finished',
                    title: 'Design Finalizado',
                    timestamp: oi.updated_at,
                    user: item.profile.full_name,
                    art_url: oi.stamp_image_url
                });

                events.sort((a,b) => new Date(a.timestamp).getTime() - new Date(b.timestamp).getTime());

                compiledHistoryTasks.push({
                    id: oi.id,
                    name: oi.stamp_ref || 'S/ Ref',
                    customer_name: o.customer_name || 'Desconhecido',
                    finished_at: oi.updated_at,
                    events
                });
            });
        });

        const userDevHistory = (devHistory || []).filter((d: any) => d.designer_id === item.user_id);
        userDevHistory.forEach((d: any) => {
            const events: WorkflowEvent[] = [];
            events.push({
                type: 'created',
                title: 'Desenv. Solicitado',
                timestamp: d.created_at,
                user: d.creator?.full_name || 'Solicitante',
                notes: d.general_notes
            });

            const rejections = (rejectionLogs || []).filter((r: any) => r.item_id === d.id);
            rejections.forEach((r: any) => {
                events.push({ type: 'rejected', title: 'Ajuste Solicitado', timestamp: r.created_at, user: r.leader?.full_name || 'Revisor', notes: r.reason });
            });

            events.push({
                type: 'finished',
                title: 'Desenv. Finalizado',
                timestamp: d.created_at,
                user: item.profile.full_name,
                art_url: d.final_art_url
            });

            events.sort((a,b) => new Date(a.timestamp).getTime() - new Date(b.timestamp).getTime());

            let custName = 'Uso Interno';
            try {
                const parsed = typeof d.design_items === 'string' ? JSON.parse(d.design_items) : d.design_items;
                if(parsed && parsed[0]?.customer_name) custName = parsed[0].customer_name;
            } catch(e){}

            compiledHistoryTasks.push({
                id: d.id,
                name: d.dev_code || 'S/ Cod',
                customer_name: custName,
                finished_at: d.created_at,
                events
            });
        });

        compiledHistoryTasks.sort((a, b) => new Date(b.finished_at).getTime() - new Date(a.finished_at).getTime());
        const recentHistory = compiledHistoryTasks.slice(0, 30);

        let color = '#2196F3';
        if (item.is_leader) color = '#8B5CF6';
        else if (item.can_approve_for_leader) color = '#06B6D4';
        else if (item.requires_leader_approval) color = '#F59E0B';

        let x = item.ui_x || 0; let y = item.ui_y || 0;
        if (x === 0 && y === 0) {
          const lPos = localPrefs.find((l: any) => l.id === item.user_id);
          if (lPos) { x = lPos.x; y = lPos.y; }
        }
        if (x !== 0 || y !== 0) hasSavedPositions = true;

        builtNodes.push({
          id: item.user_id,
          ui_x: x,
          ui_y: y,
          color,
          isBlocked: item.is_blocked || false,
          user: {
            id: item.profile.id,
            name: item.profile.full_name || 'Desconhecido',
            role: item.is_leader ? 'Líder de Design' : (item.can_approve_for_leader ? 'Sênior' : (item.requires_leader_approval ? 'Júnior' : 'Pleno')),
            avatar: item.profile.avatar_url || '',
            custom_role_id: item.profile.custom_role_id || 'N/A',
          },
          perms: {
            isLeader: item.is_leader,
            canApprove: item.can_approve_for_leader,
            requiresApproval: item.requires_leader_approval,
          },
          tasks: { total: allUserTasks.length, items: allUserTasks },
          historyTasks: recentHistory
        });
      });
    }
    nodes.value = builtNodes;
    queueEdgeRefresh();

    if (!hasSavedPositions) {
      autoLayoutNodes();
    } else {
      edges.value = edges.value.filter(e => nodes.value.some(n => n.id === e.fromId) && nodes.value.some(n => n.id === e.toId));
      resetView();
    }
  } catch (e) {
    console.error('Erro ao carregar dados:', e);
  } finally {
    loading.value = false;
  }
};

const saveLayout = async () => {
  loadingSave.value = true;
  try {
    const pos = nodes.value.map(n => ({ id: n.id, x: Math.round(n.ui_x), y: Math.round(n.ui_y) }));
    localStorage.setItem('orgchart_layout', JSON.stringify(pos));
    localStorage.setItem('orgchart_edges', JSON.stringify(edges.value));

    let dbFailed = false;
    for (const node of nodes.value) {
      const { error } = await supabase.from('design_user_permissions').update({ ui_x: Math.round(node.ui_x), ui_y: Math.round(node.ui_y) }).eq('user_id', node.id);
      if (error) dbFailed = true;
    }

    appStore.showSnackbar(dbFailed ? 'Layout salvo localmente, mas houve falha ao persistir no banco.' : 'Layout salvo com sucesso.', dbFailed ? 'warning' : 'success');
  } catch (e) {
    appStore.showSnackbar('Erro ao salvar layout.', 'error');
  } finally {
    loadingSave.value = false;
  }
};

const autoLayoutNodes = () => {
  const leaders = nodes.value.filter(n => n.perms.isLeader);
  const seniors = nodes.value.filter(n => !n.perms.isLeader && n.perms.canApprove);
  const juniors = nodes.value.filter(n => n.perms.requiresApproval);
  const midLevel = nodes.value.filter(n => !n.perms.isLeader && !n.perms.canApprove && !n.perms.requiresApproval);

  const horizontalSpacing = 320;
  const verticalSpacing = 280;
  const startX = 350;

  if (leaders.length) leaders.forEach((n, i) => { n.ui_x = startX + (i * horizontalSpacing); n.ui_y = 60; });
  const level2 = [...seniors, ...midLevel];
  const centerL1 = leaders.length ? (leaders[0].ui_x + leaders[leaders.length - 1].ui_x) / 2 : startX;
  level2.forEach((n, i) => {
    n.ui_x = centerL1 + (i * horizontalSpacing) - ((level2.length - 1) * horizontalSpacing / 2);
    n.ui_y = 60 + verticalSpacing;
  });

  const centerL2 = level2.length ? (level2[0].ui_x + level2[level2.length - 1].ui_x) / 2 : centerL1;
  juniors.forEach((n, i) => {
    n.ui_x = centerL2 + (i * horizontalSpacing) - ((juniors.length - 1) * horizontalSpacing / 2);
    n.ui_y = 60 + (verticalSpacing * 2);
  });

  resetView();
  queueEdgeRefresh();
};

const resetView = () => {
  setTimeout(() => {
    const topNode = nodes.value.find(n => n.perms.isLeader) || nodes.value[0];
    if (topNode && workspaceRef.value) {
      const rect = workspaceRef.value.getBoundingClientRect();
      transform.x = (rect.width / 2) - (topNode.ui_x * 0.82) - (140 * 0.82);
      transform.y = 60;
      transform.scale = 0.82;
    } else {
      transform.x = 200; transform.y = 60; transform.scale = 0.82;
    }
    queueEdgeRefresh();
  }, 50);
};

const startEdge = (e: MouseEvent, node: OrgNode) => {
  e.stopPropagation();
  e.preventDefault();
  const startPoint = getNodePortPoint(node.id, 'out') || { x: node.ui_x + 125, y: node.ui_y + 140 };
  drawingEdge.active = true;
  drawingEdge.sourceNodeId = node.id;
  drawingEdge.startX = startPoint.x;
  drawingEdge.startY = startPoint.y;
  drawingEdge.currentX = startPoint.x;
  drawingEdge.currentY = startPoint.y;
};

const finishEdge = (targetNode: OrgNode) => {
  if (!drawingEdge.active) return;
  if (drawingEdge.sourceNodeId === targetNode.id) {
    drawingEdge.active = false;
    drawingEdge.sourceNodeId = null;
    hoverConnectNodeId.value = null;
    return;
  }
  const exists = edges.value.some(edge => edge.fromId === drawingEdge.sourceNodeId && edge.toId === targetNode.id);
  if (!exists) {
    edges.value.push({ id: `edge_${drawingEdge.sourceNodeId}_${targetNode.id}`, fromId: drawingEdge.sourceNodeId!, toId: targetNode.id });
    queueEdgeRefresh();
  }
  drawingEdge.active = false;
  drawingEdge.sourceNodeId = null;
  hoverConnectNodeId.value = null;
};

const deleteEdge = (id: string) => {
  edges.value = edges.value.filter(e => e.id !== id);
  hoveredEdgeId.value = null;
};

const buildSmoothPath = (sx: number, sy: number, ex: number, ey: number) => {
  const verticalGap = Math.max(50, Math.abs(ey - sy) * 0.45);
  const c1y = sy + verticalGap;
  const c2y = ey - verticalGap;
  return `M ${sx} ${sy} C ${sx} ${c1y}, ${ex} ${c2y}, ${ex} ${ey}`;
};
const generateDrawingPath = () => buildSmoothPath(drawingEdge.startX, drawingEdge.startY, drawingEdge.currentX, drawingEdge.currentY);
const generateSVGPath = (edge: OrgEdge) => {
  const start = getNodePortPoint(edge.fromId, 'out');
  const end = getNodePortPoint(edge.toId, 'in');
  if (!start || !end) return '';
  return buildSmoothPath(start.x, start.y, end.x, end.y);
};

const toggleNodeBlock = async (node: OrgNode) => {
  node.isBlocked = !node.isBlocked;
  try { await supabase.from('design_user_permissions').update({ is_blocked: node.isBlocked }).eq('user_id', node.id); } catch (e) {}
  appStore.showSnackbar(node.isBlocked ? 'Bloqueado para receber artes.' : 'Desbloqueado.', 'warning');
};

const removeNodeFromOrg = async (node: OrgNode) => {
  if (!confirm(`Remover ${node.user.name} da equipe? As artes dele ficarão órfãs.`)) return;
  try {
    await supabase.from('design_user_permissions').delete().eq('user_id', node.id);
    node.tasks.items.forEach(t => {
      unassignedTasks.value.push(t);
      if (t.type === 'order') supabase.from('orders').update({ designer_id: null }).eq('id', t.original.order_id).then();
      else supabase.from('design_requests').update({ designer_id: null }).eq('id', t.id).then();
    });
    nodes.value = nodes.value.filter(n => n.id !== node.id);
    edges.value = edges.value.filter(e => e.fromId !== node.id && e.toId !== node.id);
    if (drawerNode.value?.id === node.id) closeDrawer();
    appStore.showSnackbar('Membro removido com sucesso.', 'success');
  } catch (e) {
    appStore.showSnackbar('Erro ao remover.', 'error');
  }
};

const openEditPermsModal = (node: OrgNode) => {
  permsModal.node = node;
  permsModal.isLeader = node.perms.isLeader;
  permsModal.canApprove = node.perms.canApprove;
  permsModal.requiresApproval = node.perms.requiresApproval;
  permsModal.show = true;
};

const savePermissions = async () => {
  if (!permsModal.node) return;
  permsModal.loading = true;
  try {
    await supabase.from('design_user_permissions').update({
      is_leader: permsModal.isLeader,
      can_approve_for_leader: permsModal.canApprove,
      requires_leader_approval: permsModal.requiresApproval,
    }).eq('user_id', permsModal.node.id);

    permsModal.node.perms = { isLeader: permsModal.isLeader, canApprove: permsModal.canApprove, requiresApproval: permsModal.requiresApproval };
    permsModal.node.user.role = permsModal.isLeader ? 'Líder de Design' : (permsModal.canApprove ? 'Sênior' : (permsModal.requiresApproval ? 'Júnior' : 'Pleno'));
    permsModal.node.color = permsModal.isLeader ? '#8B5CF6' : (permsModal.canApprove ? '#06B6D4' : (permsModal.requiresApproval ? '#F59E0B' : '#2196F3'));

    permsModal.show = false;
    appStore.showSnackbar('Permissões atualizadas.', 'success');
  } catch (e) {
    appStore.showSnackbar('Erro ao atualizar permissões.', 'error');
  } finally {
    permsModal.loading = false;
  }
};

const approveRequest = async (task: TaskItem, req: TaskRequest) => {
  try {
    if (task.type === 'order') await supabase.from('orders').update({ designer_id: req.designer_id }).eq('id', task.original.order_id);
    else await supabase.from('design_requests').update({ designer_id: req.designer_id }).eq('id', task.id);

    await supabase.from('design_assignment_requests').update({ status: 'approved' }).eq('id', req.id);

    unassignedTasks.value = unassignedTasks.value.filter(t => t.id !== task.id);
    task.requests = [];
    const targetNode = nodes.value.find(n => n.id === req.designer_id);
    if (targetNode) { targetNode.tasks.items.push(task); targetNode.tasks.total++; }
    appStore.showSnackbar('Solicitação aprovada!', 'success');
  } catch (e) {
    appStore.showSnackbar('Erro ao aprovar.', 'error');
  }
};

const denyRequest = async (req: TaskRequest) => {
  try {
    await supabase.from('design_assignment_requests').update({ status: 'rejected' }).eq('id', req.id);
    await fetchRealData();
    appStore.showSnackbar('Solicitação negada.', 'success');
  } catch (e) {}
};

const onDragStartTask = (e: DragEvent, task: TaskItem, sourceNodeId: string | null) => {
  draggedTaskInfo.value = { task, sourceNodeId };
  e.dataTransfer?.setData('text/plain', task.id);
  if (e.dataTransfer) e.dataTransfer.effectAllowed = 'move';
};
const onNodeDragOver = (e: DragEvent, node: OrgNode) => {
  if (node.isBlocked) return;
  if (draggedTaskInfo.value && draggedTaskInfo.value.sourceNodeId !== node.id) dragOverNodeId.value = node.id;
};
const onNodeDrop = async (e: DragEvent, targetNode: OrgNode) => {
  dragOverNodeId.value = null;
  if (targetNode.isBlocked) { appStore.showSnackbar('Este designer está bloqueado.', 'error'); return; }

  const taskId = e.dataTransfer?.getData('text/plain');
  const dragInfo = draggedTaskInfo.value;
  if (dragInfo && dragInfo.task.id === taskId && dragInfo.sourceNodeId !== targetNode.id) {
    const { task, sourceNodeId } = dragInfo;
    triggerDropAnimation(e.clientX, e.clientY, targetNode);
    if (sourceNodeId === null) {
      unassignedTasks.value = unassignedTasks.value.filter(t => t.id !== task.id);
    } else {
      const sourceNode = nodes.value.find(n => n.id === sourceNodeId);
      if (sourceNode) { sourceNode.tasks.items = sourceNode.tasks.items.filter(t => t.id !== task.id); sourceNode.tasks.total--; }
    }
    targetNode.tasks.items.push(task); targetNode.tasks.total++;
    try {
      if (task.type === 'order') await supabase.from('orders').update({ designer_id: targetNode.id }).eq('id', task.original.order_id);
      else await supabase.from('design_requests').update({ designer_id: targetNode.id }).eq('id', task.id);
      appStore.showSnackbar('Atribuição realizada com sucesso!', 'success');
    } catch (err) {
      appStore.showSnackbar('Erro ao atribuir no banco.', 'error');
    }
  }
  draggedTaskInfo.value = null;
};

const triggerDropAnimation = (clientX: number, clientY: number, targetNode: OrgNode) => {
  const rect = workspaceRef.value?.getBoundingClientRect();
  if (!rect) return;
  const targetX = rect.left + (targetNode.ui_x * transform.scale) + transform.x + (125 * transform.scale);
  const targetY = rect.top + (targetNode.ui_y * transform.scale) + transform.y + (50 * transform.scale);
  const animId = Date.now();
  activeAnimations.value.push({ id: animId, startX: clientX, startY: clientY, targetX, targetY, color: '#00d4ff' });
  setTimeout(() => { activeAnimations.value = activeAnimations.value.filter(a => a.id !== animId); }, 600);
};

const handleGlobalMouseMove = (e: MouseEvent) => {
  if (isPanning && !drawingEdge.active) {
    transform.x = e.clientX - startPan.x;
    transform.y = e.clientY - startPan.y;
  }
  if (isDraggingNode && draggedNodeId && workspaceRef.value && !drawingEdge.active) {
    const rect = workspaceRef.value.getBoundingClientRect();
    const node = nodes.value.find(n => n.id === draggedNodeId);
    if (node) {
      node.ui_x = (e.clientX - rect.left - transform.x - nodeOffset.x) / transform.scale;
      node.ui_y = (e.clientY - rect.top - transform.y - nodeOffset.y) / transform.scale;
      queueEdgeRefresh();
    }
  }
  if (drawingEdge.active && workspaceRef.value) {
    const rect = workspaceRef.value.getBoundingClientRect();
    drawingEdge.currentX = (e.clientX - rect.left - transform.x) / transform.scale;
    drawingEdge.currentY = (e.clientY - rect.top - transform.y) / transform.scale;
  }
};

const handleGlobalMouseUp = () => {
  isPanning = false;
  isDraggingNode = false;
  draggedNodeId = null;

  if (drawingEdge.active) {
    const hoveredNode = hoverConnectNodeId.value ? nodes.value.find(n => n.id === hoverConnectNodeId.value) : null;
    if (hoveredNode) finishEdge(hoveredNode);
    else {
      drawingEdge.active = false;
      drawingEdge.sourceNodeId = null;
      hoverConnectNodeId.value = null;
    }
  }
};

const onWorkspaceMouseDown = (e: MouseEvent) => {
  if (drawingEdge.active) return;
  if (e.button === 1 || e.button === 0) {
    isPanning = true;
    startPan = { x: e.clientX - transform.x, y: e.clientY - transform.y };
    selectedNodeId.value = null;
  }
};

const onWorkspaceWheel = (e: WheelEvent) => {
  const delta = -e.deltaY * 0.001;
  let newScale = transform.scale * Math.exp(delta);
  newScale = Math.min(Math.max(0.3, newScale), 2.5);
  const rect = workspaceRef.value!.getBoundingClientRect();
  const xs = (e.clientX - rect.left - transform.x) / transform.scale;
  const ys = (e.clientY - rect.top - transform.y) / transform.scale;
  transform.x = (e.clientX - rect.left) - xs * newScale;
  transform.y = (e.clientY - rect.top) - ys * newScale;
  transform.scale = newScale;
  queueEdgeRefresh();
};

const zoomIn = () => { transform.scale = Math.min(2.5, transform.scale + 0.1); queueEdgeRefresh(); };
const zoomOut = () => { transform.scale = Math.max(0.3, transform.scale - 0.1); queueEdgeRefresh(); };
const onNodeMouseEnter = (node: OrgNode) => {
  if (drawingEdge.active && drawingEdge.sourceNodeId !== node.id) hoverConnectNodeId.value = node.id;
};
const onNodeMouseLeave = (node: OrgNode) => {
  if (hoverConnectNodeId.value === node.id) hoverConnectNodeId.value = null;
};
const focusNode = (node: OrgNode) => {
  if (!workspaceRef.value) return;
  const rect = workspaceRef.value.getBoundingClientRect();
  transform.x = (rect.width / 2) - ((node.ui_x + 140) * transform.scale);
  transform.y = (rect.height / 3) - ((node.ui_y + 100) * transform.scale);
  selectedNodeId.value = node.id;
  queueEdgeRefresh();
};
const onNodeMouseDown = (e: MouseEvent, node: OrgNode) => {
  e.stopPropagation();
  selectedNodeId.value = node.id;
  isDraggingNode = true;
  draggedNodeId = node.id;
  if (workspaceRef.value) {
    const rect = workspaceRef.value.getBoundingClientRect();
    nodeOffset.x = e.clientX - rect.left - (node.ui_x * transform.scale + transform.x);
    nodeOffset.y = e.clientY - rect.top - (node.ui_y * transform.scale + transform.y);
  }
};
const selectNode = (node: OrgNode) => { selectedNodeId.value = node.id; };
const openDrawer = (node: OrgNode) => { drawerNode.value = node; drawerTab.value = 'active'; };
const closeDrawer = () => { drawerNode.value = null; };
</script>

<style scoped lang="scss">
/* ==== FULLSCREEN MODE ==== */
.fullscreen-mode {
  position: fixed !important;
  top: 0; left: 0; right: 0; bottom: 0;
  width: 100vw; height: 100vh;
  z-index: 9999;
}

.no-select { user-select: none; }
.absolute { position: absolute; }
.relative { position: relative; }
.z-10 { z-index: 10; } .z-20 { z-index: 20; } .z-30 { z-index: 30; }
.lh-1 { line-height: 1; } .lh-1-2 { line-height: 1.2; }
.tracking-widest { letter-spacing: .1em; }
.shrink-0 { flex-shrink: 0 !important; }
.min-w-0 { min-width: 0; }
.cursor-grab { cursor: grab; } .cursor-grab:active { cursor: grabbing; }
.grayscale { filter: grayscale(100%); }
.transition-colors { transition: stroke .2s ease, stroke-width .2s ease; }

.pcp-builder-container { width: 100%; display: flex; flex-direction: column; overflow: hidden; }
.builder-shell { background: radial-gradient(circle at top left, rgba(59,130,246,0.10), transparent 26%), radial-gradient(circle at bottom right, rgba(14,165,233,0.10), transparent 24%); }
.theme-enterprise-dark.builder-shell { background: radial-gradient(circle at top left, rgba(56,189,248,0.10), transparent 26%), radial-gradient(circle at bottom right, rgba(99,102,241,0.12), transparent 24%), linear-gradient(180deg, #050b14 0%, #09111f 100%); }
.theme-enterprise-light.builder-shell { background: radial-gradient(circle at top left, rgba(59,130,246,0.08), transparent 24%), radial-gradient(circle at bottom right, rgba(99,102,241,0.08), transparent 22%), linear-gradient(180deg, #f6f9fd 0%, #edf3fa 100%); }

.enterprise-header { backdrop-filter: blur(24px); box-shadow: 0 4px 15px rgba(0,0,0,0.08); }
.theme-enterprise-dark .enterprise-header { box-shadow: 0 4px 20px rgba(0,0,0,0.3), inset 0 -1px 0 rgba(255,255,255,0.04); }
.glow-icon-box { background: linear-gradient(135deg, #4338ca 0%, #0284c7 100%); box-shadow: 0 8px 16px rgba(79,70,229,0.3), inset 0 1px 0 rgba(255,255,255,0.2); }
.text-gradient-primary { background: linear-gradient(135deg, #4f46e5 0%, #0ea5e9 100%); -webkit-background-clip: text; -webkit-text-fill-color: transparent; }
.theme-enterprise-dark .text-gradient-primary { background: linear-gradient(135deg, #818cf8 0%, #38bdf8 100%); -webkit-background-clip: text; -webkit-text-fill-color: transparent; }

.search-field { width: 180px; }
.role-filter { width: 130px; }
.search-field :deep(.v-field), .role-filter :deep(.v-field) { border-radius: 8px !important; box-shadow: inset 0 1px 0 rgba(255,255,255,0.1); }
.search-field-light :deep(.v-field), .role-filter.search-field-light :deep(.v-field) { background: rgba(241,245,249,.92) !important; }
.search-field-dark :deep(.v-field), .role-filter.search-field-dark :deep(.v-field) { background: rgba(2,6,23,.45) !important; }
.view-toggle { border-radius: 8px; overflow: hidden; }
.view-toggle :deep(.v-btn) { text-transform: uppercase; letter-spacing: .02em; }
.btn-group-glass { border-radius: 8px !important; padding: 2px; box-shadow: inset 0 1px 0 rgba(255,255,255,0.08); }
.hover-text-primary:hover { color: #4f46e5 !important; }
.theme-enterprise-dark .hover-text-primary:hover { color: #818cf8 !important; }

.builder-status-rail { border-bottom: 1px solid rgba(148,163,184,0.12); box-shadow: 0 2px 10px rgba(15,23,42,0.05); position: relative; z-index: 15; backdrop-filter: blur(10px); }
.status-rail-light { background: linear-gradient(180deg, rgba(255,255,255,0.8), rgba(255,255,255,0.58)); }
.status-rail-dark { background: linear-gradient(180deg, rgba(10,15,27,0.82), rgba(10,15,27,0.64)); }
.status-pill { display: inline-flex; align-items: center; padding: 4px 8px; border-radius: 999px; font-size: 9px; font-weight: 800; letter-spacing: .02em; text-transform: uppercase; border: 1px solid rgba(148,163,184,0.16); box-shadow: inset 0 1px 0 rgba(255,255,255,0.12), 0 2px 4px rgba(15,23,42,0.04); }
.theme-enterprise-light .status-pill { background: rgba(255,255,255,0.9); color: #334155; }
.theme-enterprise-dark .status-pill { background: rgba(15,23,42,0.8); color: #dbeafe; }
.status-pill-danger { border-color: rgba(239,68,68,0.4) !important; color: #ef4444 !important; }
.switch-small :deep(.v-switch__track) { height: 14px !important; } .switch-small :deep(.v-switch__thumb) { width: 10px !important; height: 10px !important; }

.workspace-area { margin: 0; padding-bottom: 0; cursor: grab; isolation: isolate; }
.workspace-area:active { cursor: grabbing; }
.theme-enterprise-light .workspace-area { background: linear-gradient(180deg, #f8fbff 0%, #eef4fb 100%); }
.theme-enterprise-dark .workspace-area { background: linear-gradient(180deg, #08101b 0%, #0a1322 100%); }
.grid-overlay { position: absolute; inset: 0; width: 100%; height: 100%; pointer-events: none; z-index: 0; opacity: 0.82; background-image: linear-gradient(to right, var(--grid-color) 1px, transparent 1px), linear-gradient(to bottom, var(--grid-color) 1px, transparent 1px); background-size: var(--grid-size, 48px) var(--grid-size, 48px); background-position: var(--grid-position-x, 0px) var(--grid-position-y, 0px); background-repeat: repeat; }
.grid-light { --grid-color: rgba(0,0,0,.12) !important; }
.grid-dark { --grid-color: rgba(255,255,255,.11) !important; }
.grid-glow-overlay { position: absolute; inset: 0; pointer-events: none; z-index: 0; background: radial-gradient(circle at 20% 10%, rgba(59,130,246,.08), transparent 28%), radial-gradient(circle at 80% 15%, rgba(56,189,248,.06), transparent 25%), radial-gradient(circle at 50% 80%, rgba(99,102,241,.05), transparent 30%); }
.canvas-layer { transform-origin: 0 0; width: 10000px; height: 10000px; z-index: 10; will-change: transform; }
.cinematic-overlay { position: absolute; inset: 0; background: rgba(0,0,0,0); backdrop-filter: blur(0px) brightness(1); pointer-events: none; z-index: 5; transition: all 0.3s; }
.overlay-active { background: rgba(0,0,0,0.34); backdrop-filter: blur(6px) brightness(.72); }

.workspace-hud { position: absolute; top: 12px; left: 12px; z-index: 22; width: 220px; pointer-events: none; }
.hud-card { pointer-events: auto; border-color: rgba(148,163,184,.14) !important; box-shadow: 0 10px 30px rgba(15,23,42,.09), inset 0 1px 0 rgba(255,255,255,.28); backdrop-filter: blur(12px); }
.hud-line { display: flex; align-items: center; justify-content: space-between; gap: 8px; padding: 4px 0; font-weight: 700; font-size: 10px; }
.hud-line strong { font-weight: 900; }

.flow-node-wrapper { overflow: hidden; z-index: 16; box-shadow: 0 10px 24px rgba(15,23,42,0.15), 0 2px 6px rgba(15,23,42,0.08), inset 0 1px 0 rgba(255,255,255,0.14); border: 1px solid rgba(255,255,255,0.16); backdrop-filter: blur(10px); cursor: pointer; }
.flow-node-wrapper:hover { filter: brightness(1.05); box-shadow: 0 18px 36px rgba(2,6,23,0.25), 0 8px 16px rgba(15,23,42,0.15), inset 0 1px 0 rgba(255,255,255,0.14) !important; }
.node-selected { border-color: rgba(255,255,255,0.55) !important; box-shadow: 0 0 0 3px rgba(0,212,255,0.24), 0 18px 48px rgba(2,6,23,0.4) !important; z-index: 100 !important; }
.node-drag-over { border-color: #00d4ff !important; box-shadow: 0 0 0 5px rgba(0,212,255,0.3) !important; transform: scale(1.02); filter: brightness(1.15); }
.node-connect-hover { box-shadow: 0 0 0 3px rgba(76,175,80,0.45), 0 12px 30px rgba(76,175,80,0.24) !important; transform: scale(1.02); }
.node-blocked { opacity: .88; }
.node-critical { box-shadow: 0 12px 24px rgba(127,29,29,.24), 0 2px 6px rgba(239,68,68,.14), inset 0 1px 0 rgba(255,255,255,.14); }
.node-attention { box-shadow: 0 12px 24px rgba(146,64,14,.22), 0 2px 6px rgba(245,158,11,.14), inset 0 1px 0 rgba(255,255,255,.14); }
.node-healthy { box-shadow: 0 12px 24px rgba(15,23,42,0.15), 0 2px 6px rgba(15,23,42,0.10), inset 0 1px 0 rgba(255,255,255,.14); }
.node-gloss { position: absolute; inset: 0; pointer-events: none; background: linear-gradient(180deg, rgba(255,255,255,.14), transparent 28%); z-index: 1; }
.node-topbar, .node-body { position: relative; z-index: 2; }
.node-avatar { box-shadow: 0 8px 16px rgba(0,0,0,.15), inset 0 1px 0 rgba(255,255,255,.3); }
.node-quick-grid { display: grid; grid-template-columns: repeat(3, minmax(0,1fr)); gap: 6px; }
.mini-stat { border-radius: 10px; padding: 6px; display: flex; flex-direction: column; gap: 2px; }
.glass-panel { background: linear-gradient(180deg, rgba(255,255,255,.14), rgba(255,255,255,.07)); border: 1px solid rgba(148,163,184,.12); box-shadow: inset 0 1px 0 rgba(255,255,255,.12); }
.theme-enterprise-light .glass-panel { background: linear-gradient(180deg, rgba(241,245,249,.82), rgba(248,250,252,.68)); }
.mini-stat__label { font-size: 8px; font-weight: 800; letter-spacing: .05em; text-transform: uppercase; opacity: .64; }
.mini-stat__value { font-size: 1rem; font-weight: 900; line-height: 1; }
.preview-header { min-height: 14px; }
.node-preview-list { border-radius: 10px; padding: 8px; border: 1px solid rgba(148,163,184,.12); background: linear-gradient(180deg, rgba(255,255,255,.06), transparent); }
.queue-mini-item { display: flex; align-items: center; justify-content: space-between; gap: 4px; padding: 4px 0; border-bottom: 1px dashed rgba(148,163,184,.16); }
.queue-mini-item:last-child { border-bottom: none; padding-bottom: 0; }
.queue-mini-item__title { font-size: 9px; font-weight: 800; opacity: .9; }
.queue-mini-empty { font-weight: 700; opacity: .56; }
.action-btn { border-radius: 8px !important; min-height: 28px; font-size: 9px !important; }
.node-compact .node-preview-list { display: none; }
.node-compact .node-body { padding: 10px !important; }
.node-compact .mini-stat { padding: 6px; border-radius: 8px; }
.node-compact .mini-stat__value { font-size: .9rem; }
.node-compact .node-quick-grid { gap: 4px; margin-bottom: 8px !important; }
.node-compact .node-topbar { padding: 8px 10px !important; }
.node-compact .node-avatar { width: 30px !important; height: 30px !important; }
.node-compact .action-btn { min-width: 30px; }

.port { width: 12px; height: 12px; background: #fff; border: 3px solid #333; border-radius: 50%; z-index: 20; transition: transform .2s, background .2s; }
.port:hover { transform: scale(1.8); background: #536DFE; border-color: #fff; }
.port-out { border-color: #00d4ff; }
.port-in { border-color: #9E9E9E; }
.energy-flow { filter: drop-shadow(0 0 2px #00d4ff) drop-shadow(0 0 5px rgba(0,119,204,.8)); stroke-linecap: round; }
.flow-animated { animation: flowDash 1.2s linear infinite; }
@keyframes flowDash { from { stroke-dashoffset: 45; } to { stroke-dashoffset: 0; } }
.cursor-cut { cursor: url('data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="%23ff5252" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="6" cy="6" r="3"></circle><circle cx="6" cy="18" r="3"></circle><line x1="20" y1="4" x2="8.12" y2="15.88"></line><line x1="14.47" y1="14.48" x2="20" y2="20"></line><line x1="8.12" y1="8.12" x2="12" y2="12"></line></svg>') 12 12, pointer; }

/* SIDEBAR INFORMATIVA (Riqueza de detalhes, mas escala visual reduzida) */
.sidebar-properties { margin: 12px 12px 12px 0; border-radius: 20px; border: 1px solid rgba(148,163,184,0.14) !important; box-shadow: -15px 0 50px rgba(15,23,42,0.15), inset 0 1px 0 rgba(255,255,255,0.3) !important; background: linear-gradient(180deg, rgba(255,255,255,0.96), rgba(255,255,255,0.9)); backdrop-filter: blur(18px); }
.theme-enterprise-dark .sidebar-properties { background: linear-gradient(180deg, rgba(10,16,29,0.98), rgba(8,14,27,0.94)); box-shadow: -15px 0 50px rgba(0,0,0,0.5), inset 0 1px 0 rgba(255,255,255,0.05) !important; }
.drawer-hero-grid { display: grid; grid-template-columns: repeat(4, minmax(0,1fr)); gap: 6px; }
.hero-kpi { border-radius: 10px; padding: 8px; background: linear-gradient(180deg, rgba(255,255,255,.2), rgba(255,255,255,.05)); border: 1px solid rgba(255,255,255,.15); box-shadow: inset 0 1px 0 rgba(255,255,255,.1); display: flex; flex-direction: column; gap: 2px; }
.hero-kpi span { font-size: 8px; text-transform: uppercase; letter-spacing: .05em; font-weight: 900; opacity: .72; }
.hero-kpi strong { font-size: 1rem; line-height: 1; font-weight: 900; }
.drawer-shell { display: flex; flex-direction: column; gap: 14px; }
.drawer-actionbar { display: flex; flex-wrap: wrap; gap: 6px; }
.drawer-overview-grid { display: grid; grid-template-columns: repeat(3, minmax(0,1fr)); gap: 8px; }
.metric-card { min-height: 80px; }
.drawer-two-col { display: grid; grid-template-columns: repeat(2, minmax(0,1fr)); gap: 8px; align-items: stretch; }
.inspector-section { display: block; }
.section-title { font-weight: 900; letter-spacing: .04em; text-transform: uppercase; margin-bottom: 6px; display: flex; align-items: center; }
.section-card { border-radius: 12px; padding: 10px; border: 1px solid rgba(148,163,184,.14); box-shadow: inset 0 1px 0 rgba(255,255,255,.12); }
.section-card-light { background: linear-gradient(180deg, rgba(248,250,252,.94), rgba(241,245,249,.88)); }
.section-card-dark { background: linear-gradient(180deg, rgba(15,23,42,.75), rgba(17,24,39,.72)); }
.perm-row { display: flex; align-items: center; justify-content: space-between; gap: 6px; padding: 4px 0; font-weight: 700; font-size: 9px; }
.dropzone-card { border-style: dashed !important; transition: all .22s ease; cursor: crosshair; }
.dropzone-card--active { transform: translateY(-2px); box-shadow: 0 0 0 2px rgba(0,212,255,.32), 0 10px 30px rgba(0,212,255,.18) !important; border-style: solid !important; }

/* TRAY INFERIOR - FLOATING ISLAND EXCLUSIVA */
.floating-tray { position: fixed; bottom: 12px; left: 50%; transform: translateX(-50%); width: 85%; max-width: 900px; z-index: 40; pointer-events: none; }
.floating-tray > * { pointer-events: auto; }
.tray-shell { border-radius: 16px; overflow: hidden; backdrop-filter: blur(24px); box-shadow: 0 15px 40px rgba(0,0,0,0.35), inset 0 1px 0 rgba(255,255,255,0.15); border: 1px solid rgba(148,163,184,0.2); }
.tray-light .tray-shell { background: linear-gradient(180deg, rgba(255,255,255,.94), rgba(248,250,252,.92)); }
.tray-dark .tray-shell { background: linear-gradient(180deg, rgba(12,18,31,.96), rgba(9,14,25,.94)); }
.tray-expanded { height: 35vh; max-height: 380px; }
.tray-collapsed { height: 32px; overflow: hidden; width: 240px; }
.tray-handle { border-bottom: 1px solid rgba(148,163,184,0.1); background: rgba(0,0,0,0.02); }
.handle-bar { width: 32px; height: 3px; background: rgba(148,163,184,.6); box-shadow: inset 0 1px 0 rgba(255,255,255,.3); }

/* Timeline UI no Drawer (Auditoria) */
.history-panels :deep(.v-expansion-panel-title) { min-height: 32px !important; padding: 6px 10px !important; }
.workflow-timeline { font-family: inherit; }
.bg-black-10 { background-color: rgba(0,0,0,0.03); }
.theme-enterprise-dark .bg-black-10 { background-color: rgba(0,0,0,0.2); }

.task-card { box-shadow: 0 2px 6px rgba(0,0,0,0.05), inset 0 1px 0 rgba(255,255,255,0.2) !important; }
.hover-elevate:hover { transform: translateY(-2px); box-shadow: 0 6px 12px rgba(0,0,0,0.1), inset 0 1px 0 rgba(255,255,255,0.3) !important; border-color: rgba(99,102,241,0.4) !important; }
.btn-3d { border-radius: 8px !important; box-shadow: 0 2px 5px rgba(0,0,0,0.1), inset 0 1px 1px rgba(255,255,255,0.15) !important; text-transform: uppercase !important; letter-spacing: 0.5px; transition: transform 0.1s ease, box-shadow 0.1s ease; }
.btn-3d:active { transform: translateY(2px); box-shadow: 0 1px 2px rgba(0,0,0,0.1), inset 0 1px 0 rgba(255,255,255,0.1) !important; }
.chip-3d { box-shadow: 0 2px 3px rgba(0,0,0,0.1), inset 0 1px 0 rgba(255,255,255,0.2) !important; font-weight: 900; text-shadow: 0 1px 1px rgba(0,0,0,0.2); }

.custom-scrollbar::-webkit-scrollbar { width: 4px; height: 4px; }
.custom-scrollbar::-webkit-scrollbar-thumb { background: rgba(150,150,150,0.3); border-radius: 4px; }
.custom-scrollbar::-webkit-scrollbar-track { background: transparent; }

@keyframes suckIn {
  0% { top: var(--start-y); left: var(--start-x); transform: translate(-50%, -50%) scale(1); opacity: 1; }
  100% { top: var(--end-y); left: var(--end-x); transform: translate(-50%, -50%) scale(0); opacity: 0; filter: blur(4px); }
}
.water-drop-effect { position: fixed; animation: suckIn .6s cubic-bezier(.55,.085,.68,.53) forwards; width: 16px; height: 16px; border-radius: 50%; background-color: currentColor; box-shadow: 0 0 15px currentColor, 0 0 30px currentColor; z-index: 99999; pointer-events: none; }

.is-drawing-mode .flow-node-wrapper { z-index: 10; box-shadow: 0 0 0 2px rgba(0,212,255,0.4) !important; }
.is-drawing-mode .flow-node-wrapper:hover { box-shadow: 0 0 0 3px #00d4ff, 0 8px 24px rgba(0,212,255,0.2) !important; transform: scale(1.02); }



/* PREMIUM OVERRIDES */
.enterprise-header {
  position: relative;
  border-bottom: 1px solid rgba(148,163,184,.14);
  backdrop-filter: blur(22px) saturate(160%);
  box-shadow: 0 12px 30px rgba(15,23,42,.08), inset 0 -1px 0 rgba(255,255,255,.06);
}
.theme-enterprise-dark .enterprise-header {
  background: linear-gradient(180deg, rgba(8,15,28,.92), rgba(8,15,28,.82)) !important;
  box-shadow: 0 14px 34px rgba(0,0,0,.34), inset 0 -1px 0 rgba(255,255,255,.04);
}
.theme-enterprise-light .enterprise-header {
  background: linear-gradient(180deg, rgba(255,255,255,.94), rgba(248,250,252,.88)) !important;
}
.header-shell { min-height: 82px; }
.header-brand { flex: 1 1 340px; }
.header-middle { flex: 1 1 560px; }
.header-actions { flex: 1 1 340px; }
.header-nav-btn { border-radius: 14px !important; }
.header-brand-mark .glow-icon-box {
  width: 50px;
  height: 50px;
  border-radius: 16px;
  background: linear-gradient(135deg, #312e81 0%, #2563eb 50%, #06b6d4 100%);
  box-shadow: 0 16px 30px rgba(59,130,246,.28), inset 0 1px 0 rgba(255,255,255,.22);
}
.header-eyebrow {
  font-size: 10px;
  font-weight: 900;
  letter-spacing: .18em;
  text-transform: uppercase;
  opacity: .62;
}
.header-title {
  font-size: 1.22rem;
  font-weight: 900;
  line-height: 1;
  letter-spacing: -.03em;
  background: linear-gradient(135deg, #4f46e5 0%, #0ea5e9 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
}
.theme-enterprise-dark .header-title {
  background: linear-gradient(135deg, #c7d2fe 0%, #67e8f9 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
}
.header-subtitle {
  font-size: 11px;
  font-weight: 700;
  opacity: .66;
  max-width: 380px;
}
.search-field--xl { width: 290px; }
.role-filter--xl { width: 180px; }
.search-field :deep(.v-field),
.role-filter :deep(.v-field) {
  border-radius: 14px !important;
  min-height: 44px !important;
  border: 1px solid rgba(148,163,184,.14);
  box-shadow: inset 0 1px 0 rgba(255,255,255,.08), 0 8px 18px rgba(15,23,42,.06);
}
.search-field-light :deep(.v-field),
.role-filter.search-field-light :deep(.v-field) {
  background: linear-gradient(180deg, rgba(255,255,255,.96), rgba(241,245,249,.90)) !important;
}
.search-field-dark :deep(.v-field),
.role-filter.search-field-dark :deep(.v-field) {
  background: linear-gradient(180deg, rgba(15,23,42,.90), rgba(2,6,23,.82)) !important;
}
.view-toggle-premium,
.zoom-cluster {
  border-radius: 14px !important;
  padding: 3px;
  border: 1px solid rgba(148,163,184,.14);
  box-shadow: inset 0 1px 0 rgba(255,255,255,.08), 0 8px 18px rgba(15,23,42,.06);
}
.zoom-indicator {
  min-width: 54px;
  font-size: 11px !important;
}
.btn-primary-premium {
  min-height: 42px;
  padding-inline: 18px !important;
  border-radius: 14px !important;
  box-shadow: 0 14px 30px rgba(34,197,94,.24) !important;
}
.btn-secondary-premium {
  min-height: 42px;
  padding-inline: 16px !important;
  border-radius: 14px !important;
}

.flow-node-wrapper {
  border-radius: 22px !important;
  overflow: hidden;
  border: 1px solid rgba(255,255,255,.08);
  box-shadow: 0 18px 38px rgba(15,23,42,.14), 0 4px 12px rgba(15,23,42,.08);
  transition: transform .18s ease, box-shadow .22s ease, border-color .22s ease;
}
.flow-node-wrapper:hover { transform: translateY(-2px); box-shadow: 0 24px 48px rgba(15,23,42,.18), 0 8px 18px rgba(15,23,42,.10); }
.node-selected { box-shadow: 0 0 0 2px rgba(99,102,241,.32), 0 30px 64px rgba(79,70,229,.22), 0 10px 24px rgba(15,23,42,.14) !important; }
.node-topbar {
  min-height: 74px;
  padding: 12px 14px !important;
  background: linear-gradient(135deg, rgba(255,255,255,.08), rgba(255,255,255,.02));
  border-bottom: 1px solid rgba(255,255,255,.10);
}
.node-body { background: linear-gradient(180deg, rgba(255,255,255,.98), rgba(248,250,252,.96)) !important; }
.theme-enterprise-dark .node-body { background: linear-gradient(180deg, rgba(17,24,39,.96), rgba(12,18,30,.94)) !important; }
.node-quick-grid { gap: 10px; }
.mini-stat {
  border-radius: 16px;
  padding: 10px 10px 9px;
  border: 1px solid rgba(148,163,184,.12);
  background: linear-gradient(180deg, rgba(255,255,255,.92), rgba(248,250,252,.85));
  box-shadow: inset 0 1px 0 rgba(255,255,255,.65);
}
.theme-enterprise-dark .mini-stat {
  background: linear-gradient(180deg, rgba(30,41,59,.85), rgba(15,23,42,.82));
  border-color: rgba(148,163,184,.10);
}
.mini-stat__label { font-size: 9px; font-weight: 900; letter-spacing: .08em; text-transform: uppercase; opacity: .54; }
.mini-stat__value { margin-top: 4px; font-size: 18px; line-height: 1; font-weight: 900; }
.node-preview-list {
  border-radius: 16px;
  padding: 10px;
  border: 1px solid rgba(148,163,184,.12);
  background: linear-gradient(180deg, rgba(255,255,255,.65), rgba(248,250,252,.28));
}
.theme-enterprise-dark .node-preview-list {
  background: linear-gradient(180deg, rgba(255,255,255,.04), rgba(255,255,255,.02));
}
.queue-mini-item { padding: 8px 0; }
.queue-mini-item__title { font-size: 10px; font-weight: 800; }
.action-btn {
  min-height: 34px !important;
  border-radius: 12px !important;
  font-size: 10px !important;
  letter-spacing: .02em;
}

.sidebar-properties {
  margin: 14px 14px 14px 0;
  border-radius: 24px;
  box-shadow: -18px 0 40px rgba(15,23,42,.16), -6px 0 14px rgba(15,23,42,.08), inset 0 1px 0 rgba(255,255,255,.18) !important;
}
.drawer-header {
  position: relative;
  overflow: hidden;
  background: radial-gradient(circle at top right, rgba(255,255,255,.22), transparent 28%), linear-gradient(180deg, rgba(255,255,255,.06), rgba(255,255,255,.02));
}
.drawer-header::after {
  content: "";
  position: absolute;
  inset: 0;
  pointer-events: none;
  background: linear-gradient(135deg, rgba(255,255,255,.10), transparent 42%);
}
.drawer-hero-grid { gap: 10px; }
.hero-kpi {
  padding: 12px 10px;
  border-radius: 16px;
  border: 1px solid rgba(148,163,184,.14);
  background: rgba(255,255,255,.66);
  backdrop-filter: blur(10px);
  box-shadow: inset 0 1px 0 rgba(255,255,255,.55);
}
.theme-enterprise-dark .hero-kpi { background: rgba(15,23,42,.52); }
.hero-kpi span { font-size: 9px; letter-spacing: .08em; opacity: .58; }
.hero-kpi strong { margin-top: 6px; font-size: 18px; }

.drawer-tabs {
  padding: 8px 10px;
  background: linear-gradient(180deg, rgba(255,255,255,.03), transparent);
}
.drawer-tabs :deep(.v-slide-group__content) { gap: 8px; }
.drawer-tabs :deep(.v-tab) {
  min-height: 38px;
  border-radius: 12px;
  text-transform: none;
  font-size: 11px;
  font-weight: 900;
  opacity: .7;
}
.drawer-tabs :deep(.v-tab--selected) {
  opacity: 1;
  background: rgba(79,70,229,.12);
  box-shadow: inset 0 0 0 1px rgba(79,70,229,.16);
}

.drawer-shell { gap: 18px; }
.drawer-actionbar { gap: 8px; }
.drawer-overview-grid { gap: 10px; }
.metric-card {
  min-height: 94px;
  border-radius: 18px !important;
  box-shadow: 0 10px 24px rgba(15,23,42,.05), inset 0 1px 0 rgba(255,255,255,.06) !important;
}
.section-title {
  margin-bottom: 10px;
  font-size: 10px;
  letter-spacing: .12em;
  opacity: .62;
}
.section-card {
  border-radius: 18px;
  padding: 14px;
  box-shadow: 0 8px 18px rgba(15,23,42,.05), inset 0 1px 0 rgba(255,255,255,.05);
}
.perm-row { padding: 7px 0; font-size: 10px; }

.history-panels {
  display: flex;
  flex-direction: column;
  gap: 12px;
}
.history-panel-item {
  border-radius: 18px !important;
  border: 1px solid rgba(148,163,184,.14) !important;
  box-shadow: 0 12px 28px rgba(15,23,42,.06), inset 0 1px 0 rgba(255,255,255,.04);
}
.history-panel-title {
  min-height: 68px !important;
  padding: 14px 16px !important;
  background: linear-gradient(180deg, rgba(255,255,255,.03), transparent);
}
.history-panel-body {
  background: linear-gradient(180deg, rgba(255,255,255,.04), transparent);
}
.workflow-timeline :deep(.v-timeline-item__body) { padding-bottom: 14px !important; }
.timeline-event-card {
  border-radius: 14px;
  padding: 12px;
  border: 1px solid rgba(148,163,184,.12);
  background: linear-gradient(180deg, rgba(255,255,255,.86), rgba(248,250,252,.72));
  box-shadow: 0 8px 18px rgba(15,23,42,.05);
}
.theme-enterprise-dark .timeline-event-card {
  background: linear-gradient(180deg, rgba(30,41,59,.84), rgba(15,23,42,.78));
}
.timeline-title {
  font-size: 11px;
  font-weight: 900;
  line-height: 1.2;
}
.timeline-meta {
  font-size: 10px;
  font-weight: 800;
  opacity: .6;
}
.timeline-note {
  margin-top: 8px;
  padding: 10px 12px;
  border-radius: 12px;
  font-size: 11px;
  line-height: 1.35;
  border-left: 3px solid currentColor;
}

.task-card {
  border-radius: 16px !important;
  box-shadow: 0 10px 22px rgba(15,23,42,.06), inset 0 1px 0 rgba(255,255,255,.2) !important;
}
.hover-elevate:hover {
  transform: translateY(-2px);
  box-shadow: 0 14px 28px rgba(15,23,42,.09), inset 0 1px 0 rgba(255,255,255,.25) !important;
  border-color: rgba(99,102,241,.4) !important;
}

.floating-tray {
  bottom: 14px;
  width: 86%;
  max-width: 980px;
}
.tray-shell {
  border-radius: 22px;
  border: 1px solid rgba(148,163,184,.14);
  box-shadow: 0 -18px 40px rgba(15,23,42,.16), 0 -6px 16px rgba(15,23,42,.08), inset 0 1px 0 rgba(255,255,255,.15);
}
.tray-expanded { height: 36vh; max-height: 400px; }
.tray-collapsed { height: 38px; width: 280px; }
.tray-handle {
  min-height: 38px;
  border-bottom: 1px solid rgba(148,163,184,.08);
  background: linear-gradient(180deg, rgba(255,255,255,.04), transparent);
}
.handle-bar {
  width: 42px;
  height: 5px;
  background: rgba(148,163,184,.42);
}
.tray-header {
  min-height: 58px;
  background: linear-gradient(180deg, rgba(255,255,255,.04), transparent);
}
.tray-column {
  border-radius: 18px !important;
  box-shadow: inset 0 1px 0 rgba(255,255,255,.05), 0 8px 18px rgba(15,23,42,.05);
}
.tray-column-head {
  min-height: 38px;
  background: linear-gradient(180deg, rgba(255,255,255,.06), transparent);
}
.tray-task-card {
  border-radius: 14px !important;
  box-shadow: 0 8px 18px rgba(15,23,42,.06), inset 0 1px 0 rgba(255,255,255,.04);
}


/* TRUE REWORK OVERRIDES */
.drawer-content-wrapper { min-height: 0; }
.drawer-window { height: 100%; }
.drawer-scroll {
  height: 100%;
  overflow-y: auto;
  padding: 18px;
}
.drawer-shell {
  display: flex;
  flex-direction: column;
  gap: 20px;
  padding-bottom: 28px;
}
.drawer-header {
  padding: 18px 18px 16px;
  background:
    radial-gradient(circle at top right, color-mix(in srgb, var(--drawer-accent) 24%, white) 0%, transparent 26%),
    linear-gradient(180deg, rgba(255,255,255,.08), rgba(255,255,255,.02));
}
.theme-enterprise-dark .drawer-header {
  background:
    radial-gradient(circle at top right, color-mix(in srgb, var(--drawer-accent) 20%, white) 0%, transparent 28%),
    linear-gradient(180deg, rgba(255,255,255,.04), rgba(255,255,255,.015));
}
.drawer-header__top { margin-bottom: 16px; }
.drawer-header__avatar {
  box-shadow: 0 16px 32px rgba(15,23,42,.18), inset 0 1px 0 rgba(255,255,255,.25);
}
.drawer-header__eyebrow {
  font-size: 10px;
  font-weight: 900;
  text-transform: uppercase;
  letter-spacing: .14em;
  opacity: .56;
  margin-bottom: 5px;
}
.drawer-header__name {
  font-size: 1.2rem;
  line-height: 1;
  font-weight: 900;
  letter-spacing: -.03em;
}
.drawer-header__role {
  margin-top: 6px;
  font-size: 12px;
  font-weight: 700;
  opacity: .68;
}
.drawer-status-chip {
  height: 24px !important;
  border-radius: 999px !important;
  font-size: 10px !important;
  font-weight: 900 !important;
}
.drawer-summary-grid {
  display: grid;
  grid-template-columns: repeat(4, minmax(0,1fr));
  gap: 10px;
  margin-bottom: 14px;
}
.drawer-summary-card {
  padding: 12px 12px 11px;
  border-radius: 18px;
  background: rgba(255,255,255,.72);
  border: 1px solid rgba(148,163,184,.14);
  box-shadow: inset 0 1px 0 rgba(255,255,255,.6), 0 8px 20px rgba(15,23,42,.06);
  backdrop-filter: blur(12px);
}
.theme-enterprise-dark .drawer-summary-card {
  background: rgba(15,23,42,.56);
}
.drawer-summary-card span {
  display: block;
  font-size: 9px;
  font-weight: 900;
  text-transform: uppercase;
  letter-spacing: .08em;
  opacity: .58;
}
.drawer-summary-card strong {
  display: block;
  margin-top: 7px;
  font-size: 20px;
  line-height: 1;
  font-weight: 900;
}
.drawer-pressure-strip {
  border-radius: 18px;
  padding: 14px;
  border: 1px solid rgba(148,163,184,.14);
  background: linear-gradient(180deg, rgba(255,255,255,.68), rgba(248,250,252,.42));
  box-shadow: inset 0 1px 0 rgba(255,255,255,.55);
}
.theme-enterprise-dark .drawer-pressure-strip {
  background: linear-gradient(180deg, rgba(15,23,42,.62), rgba(15,23,42,.4));
}
.drawer-strip-label {
  font-size: 10px;
  font-weight: 900;
  text-transform: uppercase;
  letter-spacing: .08em;
  opacity: .58;
}
.drawer-strip-caption {
  margin-top: 4px;
  font-size: 12px;
  font-weight: 700;
  opacity: .72;
}
.drawer-strip-value {
  font-size: 24px;
  font-weight: 900;
  line-height: 1;
}

.drawer-tabs-wrap {
  padding: 10px 14px 12px;
  background: linear-gradient(180deg, rgba(255,255,255,.03), transparent);
}
.drawer-tabs {
  border-radius: 16px;
  padding: 4px;
  background: rgba(148,163,184,.08);
}
.drawer-tabs :deep(.v-slide-group__content) { gap: 6px; }
.drawer-tab-item {
  min-height: 42px !important;
  border-radius: 12px !important;
  font-size: 11px !important;
  font-weight: 900 !important;
  text-transform: none !important;
  letter-spacing: .01em;
}
.drawer-tabs :deep(.v-tab--selected) {
  background: rgba(255,255,255,.92);
  box-shadow: 0 8px 20px rgba(15,23,42,.08), inset 0 1px 0 rgba(255,255,255,.55);
}
.theme-enterprise-dark .drawer-tabs :deep(.v-tab--selected) {
  background: rgba(15,23,42,.92);
}

.drawer-toolbar {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}
.drawer-toolbar__btn {
  min-height: 36px !important;
  border-radius: 12px !important;
  padding-inline: 14px !important;
}
.drawer-panel-grid {
  display: grid;
  gap: 14px;
}
.drawer-panel-grid--metrics {
  grid-template-columns: repeat(3, minmax(0,1fr));
}
.drawer-panel-grid--two {
  grid-template-columns: repeat(2, minmax(0,1fr));
}
.drawer-surface-light {
  background: linear-gradient(180deg, rgba(255,255,255,.98), rgba(248,250,252,.95)) !important;
  border: 1px solid rgba(148,163,184,.14) !important;
}
.drawer-surface-dark {
  background: linear-gradient(180deg, rgba(30,41,59,.94), rgba(15,23,42,.9)) !important;
  border: 1px solid rgba(148,163,184,.10) !important;
}
.drawer-stat-card,
.drawer-panel__body,
.drawer-dropzone,
.drawer-empty-state {
  border-radius: 20px !important;
  box-shadow: 0 10px 26px rgba(15,23,42,.06), inset 0 1px 0 rgba(255,255,255,.05);
}
.drawer-stat-card {
  padding: 16px;
}
.drawer-stat-card__label {
  font-size: 10px;
  font-weight: 900;
  text-transform: uppercase;
  letter-spacing: .1em;
  opacity: .56;
}
.drawer-stat-card__value {
  margin-top: 10px;
  font-size: 22px;
  line-height: 1;
  font-weight: 900;
}
.drawer-stat-card__value--sm { font-size: 15px; }
.drawer-stat-card__meta {
  margin-top: 8px;
  font-size: 11px;
  font-weight: 700;
  opacity: .62;
}
.drawer-panel__head { margin-bottom: 10px; }
.drawer-panel__head--spaced {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 12px;
}
.drawer-panel__sub {
  font-size: 12px;
  font-weight: 700;
  opacity: .62;
}
.section-title {
  font-size: 10px !important;
  font-weight: 900 !important;
  text-transform: uppercase;
  letter-spacing: .12em !important;
  opacity: .68;
}
.drawer-panel__body {
  padding: 14px;
}
.drawer-chip-block + .drawer-chip-block { margin-top: 16px; }
.drawer-chip-block__label {
  margin-bottom: 8px;
  font-size: 10px;
  font-weight: 900;
  text-transform: uppercase;
  letter-spacing: .08em;
  opacity: .56;
}
.drawer-inline-chip {
  min-height: 28px !important;
  border-radius: 999px !important;
  font-weight: 800 !important;
}
.drawer-empty-note {
  font-size: 12px;
  font-weight: 700;
  opacity: .58;
}
.perm-row,
.drawer-kv {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  min-height: 40px;
  padding: 0 2px;
  font-size: 12px;
  font-weight: 800;
}
.perm-row + .perm-row,
.drawer-kv + .drawer-kv {
  border-top: 1px solid rgba(148,163,184,.12);
}
.drawer-kv strong { text-align: right; }
.drawer-dropzone {
  min-height: 170px;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  border-style: dashed !important;
  text-align: center;
  transition: all .22s ease;
}
.drawer-dropzone__title {
  font-size: 14px;
  font-weight: 900;
  line-height: 1.1;
}
.drawer-dropzone__caption {
  margin-top: 6px;
  font-size: 12px;
  font-weight: 700;
  opacity: .62;
}
.drawer-empty-state {
  padding: 30px 22px;
  text-align: center;
}
.drawer-empty-state__title {
  font-size: 15px;
  font-weight: 900;
  line-height: 1.1;
}
.drawer-empty-state__caption {
  margin-top: 8px;
  font-size: 12px;
  font-weight: 700;
  opacity: .62;
}
.drawer-empty-state--history {
  min-height: 220px;
  display: flex;
  flex-direction: column;
  justify-content: center;
}

.drawer-task-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}
.designer-task-card {
  padding: 14px;
  border-radius: 20px !important;
  border: 1px solid rgba(148,163,184,.14) !important;
  box-shadow: 0 12px 28px rgba(15,23,42,.07), inset 0 1px 0 rgba(255,255,255,.06) !important;
  transition: transform .16s ease, box-shadow .18s ease, border-color .18s ease;
}
.designer-task-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 16px 32px rgba(15,23,42,.10), inset 0 1px 0 rgba(255,255,255,.08) !important;
  border-color: rgba(99,102,241,.28) !important;
}
.designer-task-card--light {
  background: linear-gradient(180deg, rgba(255,255,255,.99), rgba(248,250,252,.94)) !important;
}
.designer-task-card--dark {
  background: linear-gradient(180deg, rgba(30,41,59,.96), rgba(15,23,42,.92)) !important;
}
.designer-task-card__top,
.designer-task-card__footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
}
.designer-task-card__code {
  font-size: 10px;
  font-weight: 900;
  letter-spacing: .08em;
  text-transform: uppercase;
  opacity: .62;
}
.designer-task-card__chip {
  min-height: 24px !important;
  border-radius: 999px !important;
  font-weight: 900 !important;
  font-size: 10px !important;
}
.designer-task-card__title {
  margin-top: 10px;
  font-size: 16px;
  line-height: 1.2;
  font-weight: 900;
}
.designer-task-card__meta {
  display: flex;
  align-items: center;
  gap: 7px;
  margin-top: 10px;
  font-size: 12px;
  font-weight: 700;
  opacity: .68;
}
.designer-task-card__footer {
  margin-top: 14px;
  padding-top: 12px;
  border-top: 1px solid rgba(148,163,184,.12);
}
.designer-task-card__time {
  display: flex;
  align-items: center;
  font-size: 11px;
  font-weight: 800;
  opacity: .56;
}
.drawer-tip {
  margin-top: 12px;
  border-radius: 16px !important;
}

.drawer-history-shell {
  display: flex;
  flex-direction: column;
  gap: 14px;
  padding-bottom: 28px;
}
.drawer-history-head {
  padding: 2px 2px 0;
}
.history-panels {
  display: flex;
  flex-direction: column;
  gap: 14px;
}
.history-panel-item {
  border-radius: 22px !important;
  overflow: hidden !important;
  border: 1px solid rgba(148,163,184,.14) !important;
  box-shadow: 0 12px 28px rgba(15,23,42,.06), inset 0 1px 0 rgba(255,255,255,.04) !important;
}
.history-panel-item--light {
  background: linear-gradient(180deg, rgba(255,255,255,.98), rgba(248,250,252,.95)) !important;
}
.history-panel-item--dark {
  background: linear-gradient(180deg, rgba(30,41,59,.95), rgba(15,23,42,.9)) !important;
}
.history-panel-title {
  min-height: 88px !important;
  padding: 18px !important;
}
.history-summary {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 18px;
}
.history-summary__main {
  min-width: 0;
  flex: 1 1 auto;
}
.history-summary__title {
  font-size: 15px;
  line-height: 1.15;
  font-weight: 900;
}
.history-summary__meta {
  display: flex;
  align-items: center;
  gap: 6px;
  margin-top: 8px;
  font-size: 12px;
  font-weight: 700;
  opacity: .62;
}
.history-summary__aside {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 8px;
}
.history-summary__time {
  font-size: 11px;
  font-weight: 800;
  opacity: .56;
}
.history-panel-body {
  padding: 0 !important;
}
.history-panel-body__inner {
  padding: 0 18px 16px 18px;
}
.workflow-timeline {
  padding-top: 4px;
}
.workflow-timeline :deep(.v-timeline-item) {
  padding-bottom: 8px !important;
}
.workflow-timeline :deep(.v-timeline-item__body) {
  padding-bottom: 14px !important;
}
.timeline-event-card {
  border-radius: 18px;
  padding: 14px;
  border: 1px solid rgba(148,163,184,.12);
  background: linear-gradient(180deg, rgba(255,255,255,.88), rgba(248,250,252,.76));
  box-shadow: 0 10px 22px rgba(15,23,42,.05);
}
.theme-enterprise-dark .timeline-event-card {
  background: linear-gradient(180deg, rgba(30,41,59,.88), rgba(15,23,42,.80));
}
.timeline-title {
  font-size: 13px;
  font-weight: 900;
  line-height: 1.2;
}
.timeline-meta {
  font-size: 11px;
  font-weight: 800;
  opacity: .62;
}
.timeline-meta--time {
  white-space: nowrap;
}
.timeline-note {
  margin-top: 10px;
  padding: 12px 14px;
  border-radius: 14px;
  font-size: 12px;
  font-weight: 700;
  line-height: 1.45;
}
.timeline-thumb {
  display: inline-flex;
}
.bg-black-10 {
  background-color: rgba(15,23,42,.04);
}
.theme-enterprise-dark .bg-black-10 {
  background-color: rgba(2,6,23,.44);
}

.floating-tray {
  position: fixed;
  left: 50%;
  bottom: 16px;
  transform: translateX(-50%);
  z-index: 40;
  width: min(1120px, calc(100vw - 28px));
  pointer-events: none;
}
.floating-tray > * {
  pointer-events: auto;
}
.tray-shell {
  overflow: hidden;
  border-radius: 24px;
  border: 1px solid rgba(148,163,184,.14);
  backdrop-filter: blur(20px);
  box-shadow: 0 24px 56px rgba(15,23,42,.18), inset 0 1px 0 rgba(255,255,255,.10);
}
.tray-light .tray-shell {
  background: linear-gradient(180deg, rgba(255,255,255,.96), rgba(248,250,252,.92));
}
.tray-dark .tray-shell {
  background: linear-gradient(180deg, rgba(9,14,25,.96), rgba(15,23,42,.94));
}
.tray-collapsed {
  height: 54px;
}
.tray-expanded {
  height: min(420px, 44vh);
}
.tray-handle {
  padding: 0 14px;
  border-bottom: 1px solid rgba(148,163,184,.10);
  background: linear-gradient(180deg, rgba(255,255,255,.05), transparent);
}
.tray-handle__inner {
  min-height: 54px;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 14px;
}
.handle-bar {
  width: 44px;
  height: 5px;
  background: rgba(148,163,184,.44);
}
.tray-handle__label {
  display: flex;
  align-items: center;
  font-size: 11px;
  font-weight: 900;
  letter-spacing: .08em;
  text-transform: uppercase;
  opacity: .72;
}
.tray-header {
  padding: 14px 16px;
}
.tray-header__main {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
}
.tray-header__title {
  font-size: 15px;
  font-weight: 900;
  line-height: 1.1;
}
.tray-header__subtitle {
  margin-top: 4px;
  font-size: 12px;
  font-weight: 700;
  opacity: .62;
}
.tray-content {
  flex: 1 1 auto;
  min-height: 0;
  overflow-x: auto;
  padding: 0 16px 16px;
}
.tray-empty {
  min-height: 240px;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  text-align: center;
  opacity: .7;
}
.tray-empty__title {
  font-size: 15px;
  font-weight: 900;
}
.tray-empty__caption {
  margin-top: 6px;
  font-size: 12px;
  font-weight: 700;
}
.tray-lanes {
  display: flex;
  align-items: stretch;
  gap: 14px;
  min-height: 100%;
  padding-top: 4px;
}
.tray-column {
  width: 270px;
  min-width: 270px;
  display: flex;
  flex-direction: column;
  border-radius: 20px;
  overflow: hidden;
  border: 1px solid rgba(148,163,184,.14);
  box-shadow: inset 0 1px 0 rgba(255,255,255,.04), 0 10px 22px rgba(15,23,42,.06);
}
.tray-column--light {
  background: linear-gradient(180deg, rgba(255,255,255,.96), rgba(248,250,252,.92));
}
.tray-column--dark {
  background: linear-gradient(180deg, rgba(30,41,59,.88), rgba(15,23,42,.84));
}
.tray-column-head {
  min-height: 52px;
  padding: 10px 12px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  border-bottom: 1px solid rgba(148,163,184,.10);
  background: linear-gradient(180deg, rgba(255,255,255,.06), transparent);
}
.tray-column-head__title {
  font-size: 11px;
  font-weight: 900;
  text-transform: uppercase;
  letter-spacing: .12em;
  opacity: .7;
}
.tray-cards-container {
  min-height: 0;
  overflow-y: auto;
  padding: 12px;
  display: flex;
  flex-direction: column;
  gap: 10px;
}
.tray-art-card {
  padding: 12px;
  border-radius: 16px !important;
  border: 1px solid rgba(148,163,184,.14) !important;
  box-shadow: 0 10px 20px rgba(15,23,42,.06), inset 0 1px 0 rgba(255,255,255,.05) !important;
}
.tray-art-card--light {
  background: linear-gradient(180deg, rgba(255,255,255,.99), rgba(248,250,252,.95)) !important;
}
.tray-art-card--dark {
  background: linear-gradient(180deg, rgba(51,65,85,.86), rgba(15,23,42,.80)) !important;
}
.tray-art-card__code {
  font-size: 10px;
  font-weight: 900;
  letter-spacing: .08em;
  text-transform: uppercase;
  opacity: .56;
}
.tray-art-card__title {
  margin-top: 8px;
  font-size: 14px;
  line-height: 1.2;
  font-weight: 900;
}
.tray-art-card__meta {
  display: flex;
  align-items: center;
  gap: 6px;
  margin-top: 8px;
  font-size: 11px;
  font-weight: 700;
  opacity: .66;
}
.tray-art-card__footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  margin-top: 12px;
}

@media (max-width: 1420px) {
  .drawer-summary-grid {
    grid-template-columns: repeat(2, minmax(0,1fr));
  }
}
@media (max-width: 1200px) {
  .drawer-panel-grid--metrics,
  .drawer-panel-grid--two {
    grid-template-columns: 1fr;
  }
  .sidebar-properties {
    width: min(460px, calc(100vw - 12px)) !important;
  }
}

@media (max-width: 1420px) {
  .search-field { width: 160px; }
  .workspace-hud { width: 180px; }
  .drawer-hero-grid { grid-template-columns: repeat(2, minmax(0,1fr)); }
}
@media (max-width: 1200px) {
  .drawer-overview-grid { grid-template-columns: 1fr; }
  .drawer-two-col { grid-template-columns: 1fr; }
  .workspace-hud { display: none; }
}
</style>
