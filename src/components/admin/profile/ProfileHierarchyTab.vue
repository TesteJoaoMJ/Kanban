<template>
  <div
    class="pcp-builder-container builder-shell d-flex flex-column overflow-hidden transition-all relative"
    :class="[
      isLight ? 'theme-enterprise-light text-grey-darken-4' : 'theme-enterprise-dark text-white',
      drawingEdge.active ? 'is-drawing-mode' : '',
      isFullscreen ? 'fullscreen-mode' : 'inline-mode'
    ]"
    ref="containerRef"
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
          <div class="header-brand-mark shrink-0">
            <div class="glow-icon-box d-flex align-center justify-center">
              <v-icon color="white" size="20">mdi-sitemap</v-icon>
            </div>
          </div>
          <div class="header-brand-copy d-flex flex-column min-w-0">
            <div class="d-flex align-center gap-2 flex-wrap">
              <span class="header-eyebrow">Governança ERP</span>
              <v-chip size="x-small" color="primary" variant="flat" class="font-weight-black text-uppercase chip-3d px-2">OrgChart Pro</v-chip>
            </div>
            <div class="d-flex align-center gap-3 flex-wrap min-w-0">
              <h1 class="header-title mb-0">Arquitetura de Setores</h1>
              <span class="header-subtitle text-truncate">Modele a hierarquia, defina líderes e controle o fluxo de aprovações.</span>
            </div>
          </div>
        </div>

        <div class="header-middle d-flex align-center gap-2 flex-wrap justify-center">
          <v-select
            v-model="activeDepartmentId"
            :items="departments"
            item-title="name"
            item-value="id"
            density="comfortable"
            variant="solo-filled"
            hide-details
            prepend-inner-icon="mdi-domain"
            placeholder="Selecione o Setor..."
            class="role-filter role-filter--xl"
            :class="isLight ? 'search-field-light' : 'search-field-dark'"
            @update:model-value="loadDepartmentData"
            :loading="loadingDeps"
          />

          <v-text-field
            v-model="searchQuery"
            density="comfortable"
            variant="solo-filled"
            hide-details
            prepend-inner-icon="mdi-magnify"
            placeholder="Buscar colaborador na malha..."
            class="search-field search-field--xl"
            :class="isLight ? 'search-field-light' : 'search-field-dark'"
          />
        </div>

        <div class="header-actions d-flex align-center gap-2 flex-wrap justify-end">
          <v-btn-group variant="outlined" density="comfortable" class="btn-group-glass zoom-cluster">
            <v-btn icon="mdi-magnify-minus-outline" size="small" @click="zoomOut" class="hover-text-primary" />
            <v-btn class="zoom-indicator font-weight-black font-mono px-1" size="small" style="pointer-events: none;">{{ Math.round(transform.scale * 100) }}%</v-btn>
            <v-btn icon="mdi-magnify-plus-outline" size="small" @click="zoomIn" class="hover-text-primary" />
            <v-btn icon="mdi-target" size="small" @click="resetView" class="hover-text-primary" title="Centralizar" />
            <v-btn :icon="isFullscreen ? 'mdi-fullscreen-exit' : 'mdi-fullscreen'" size="small" @click="toggleFullscreen" class="hover-text-primary" title="Tela Cheia" />
          </v-btn-group>

          <v-btn color="indigo-accent-2" variant="tonal" prepend-icon="mdi-auto-fix" size="small" class="btn-3d btn-secondary-premium" @click="autoLayoutNodes" title="Auto-Organizar">
            Auto-organizar
          </v-btn>
          <v-btn v-if="editMode" color="success" variant="flat" prepend-icon="mdi-content-save-all" size="small" class="font-weight-black text-caption btn-3d btn-primary-premium" @click="saveLayout" :loading="loadingSave">
            Salvar Malha
          </v-btn>
        </div>
      </div>
    </header>

    <div class="builder-status-rail px-4 py-1 d-flex align-center flex-wrap gap-2" :class="isLight ? 'status-rail-light border-grey-lighten-2' : 'status-rail-dark border-grey-darken-3'">
      <div class="status-pill"><v-icon size="10" class="mr-1">mdi-account-group</v-icon> Na Malha <strong class="ml-1">{{ nodes.length }}</strong></div>
      <div class="status-pill"><v-icon size="10" class="mr-1">mdi-graph-outline</v-icon> Vínculos <strong class="ml-1">{{ edges.length }}</strong></div>
      <div class="status-pill"><v-icon size="10" class="mr-1">mdi-shield-crown</v-icon> Lideranças <strong class="ml-1">{{ leaderCount }}</strong></div>
      <div class="status-pill border-warning text-warning" :class="isLight ? 'bg-orange-lighten-5' : 'bg-orange-darken-4-alpha'">
        <v-icon size="10" color="warning" class="mr-1">mdi-account-question</v-icon> Banco de Talentos <strong class="ml-1">{{ poolUsers.length }}</strong>
      </div>
      <v-spacer />
      <v-switch v-if="canEdit" v-model="editMode" color="warning" density="compact" hide-details inset class="mr-2 switch-small">
        <template #label><span class="text-[9px] font-weight-black opacity-70 text-uppercase tracking-widest" :class="editMode ? 'text-warning' : ''">Modo Arquiteto (Edição)</span></template>
      </v-switch>
    </div>

    <div class="d-flex flex-grow-1 overflow-hidden relative">
      <main
        ref="workspaceRef"
        class="workspace-area enterprise-workspace flex-grow-1 relative overflow-hidden no-select"
        :class="{ 'is-editing': editMode }"
        @mousedown="onWorkspaceMouseDown"
        @wheel.prevent="onWorkspaceWheel"
        @dragover.prevent="onCanvasDragOver"
        @drop.prevent="onCanvasDrop"
      >
        <div class="grid-overlay" :class="isLight ? 'grid-light' : 'grid-dark'" :style="gridStyle"></div>
        <div class="grid-glow-overlay" />
        <div class="cinematic-overlay transition-all" :class="drawingEdge.active ? 'overlay-active' : ''"></div>

        <div class="workspace-hud d-flex flex-column gap-2">
          <v-card class="hud-card pa-3 rounded-xl border" :class="isLight ? 'bg-white' : 'bg-grey-darken-4'">
            <div class="d-flex align-center justify-space-between mb-2">
              <div>
                <div class="text-[9px] font-weight-black text-uppercase opacity-60 mb-1">Saúde do Setor</div>
                <div class="text-subtitle-2 font-weight-black lh-1">{{ networkHealthLabel }}</div>
              </div>
              <v-avatar size="32" :color="networkHealthColor" class="text-white elevation-2">
                <v-icon size="16">{{ networkHealthIcon }}</v-icon>
              </v-avatar>
            </div>
            <v-progress-linear :model-value="networkHealthScore" :color="networkHealthColor" rounded height="6" class="mb-1" />
            <div class="text-[8px] opacity-70 lh-1-2">Baseado na proporção estrutural.</div>
          </v-card>
        </div>

        <div v-if="loading" class="absolute d-flex flex-column align-center justify-center w-100 h-100 z-10">
          <v-progress-circular indeterminate color="indigo" size="64" width="6" />
          <span class="mt-4 font-weight-black opacity-70 text-uppercase tracking-widest text-[11px]">Sincronizando Banco de Dados...</span>
        </div>

        <div v-else-if="!activeDepartmentId" class="absolute d-flex flex-column align-center justify-center w-100 h-100 z-10 opacity-60">
          <v-icon size="64" class="mb-4">mdi-domain-off</v-icon>
          <span class="font-weight-black uppercase tracking-widest text-[12px]">Selecione um departamento no menu superior</span>
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
              <path :d="generateSVGPath(edge)" class="edge-path flow-animated energy-flow transition-colors" :stroke="hoveredEdgeId === edge.id && editMode ? '#ff5252' : '#00d4ff'" :stroke-width="hoveredEdgeId === edge.id && editMode ? 4 : 3" fill="none" :marker-end="hoveredEdgeId === edge.id && editMode ? 'url(#arrowhead-hover)' : 'url(#arrowhead)'" />
              <path v-if="editMode" :d="generateSVGPath(edge)" stroke="transparent" stroke-width="24" fill="none" class="edge-hit-area cursor-cut" @mousedown.stop="deleteEdge(edge.id)" />
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
              hoverConnectNodeId === node.id ? 'node-connect-hover' : '',
              node.perms.isLeader ? 'node-attention' : 'node-healthy'
            ]"
            :style="{ left: `${node.ui_x}px`, top: `${node.ui_y}px`, width: '260px', backgroundColor: node.color, borderRadius: '18px', zIndex: selectedNodeId === node.id ? 100 : 16 }"
            @mousedown.stop="onNodeMouseDown($event, node)"
            @mouseup="finishEdge(node)"
            @mouseenter="onNodeMouseEnter(node)"
            @mouseleave="onNodeMouseLeave(node)"
            @click.stop="openDrawer(node)"
          >
            <div class="node-gloss" />

            <div class="px-3 py-2 d-flex align-center justify-space-between border-b border-white-02 position-relative overflow-hidden node-topbar">
              <div class="d-flex align-center gap-2 z-10 w-100 min-w-0">
                <v-avatar size="42" class="elevation-4 border-2 border-white shrink-0 node-avatar" color="white">
                  <v-img v-if="node.user.avatar" :src="node.user.avatar" cover />
                  <span v-else class="text-indigo-darken-4 font-weight-black text-caption">{{ node.user.name.charAt(0) }}</span>
                </v-avatar>
                <div class="d-flex flex-column flex-grow-1 overflow-hidden min-w-0">
                  <div class="text-caption font-weight-black text-white leading-tight text-truncate" style="text-shadow: 0 1px 3px rgba(0,0,0,0.6);">
                    {{ node.user.name }}
                  </div>
                  <span class="text-[8px] font-weight-black text-uppercase text-white opacity-85 tracking-widest text-truncate mt-1">
                    {{ node.user.role || 'Colaborador' }}
                  </span>
                </div>
              </div>
            </div>

            <div class="flex-grow-1 d-flex flex-column pa-3 position-relative node-body" :class="isLight ? 'bg-white' : 'bg-grey-darken-3'">
              <div class="node-quick-grid mb-3">
                <div class="mini-stat glass-panel">
                  <div class="mini-stat__label">Equipe</div>
                  <div class="mini-stat__value">{{ getNodeRelations(node.id).led.length }}</div>
                </div>
                <div class="mini-stat glass-panel">
                  <div class="mini-stat__label">Reporta</div>
                  <div class="mini-stat__value">{{ getNodeRelations(node.id).leaders.length }}</div>
                </div>
              </div>

              <div class="d-flex align-center justify-space-between flex-wrap gap-1 mb-2">
                <div class="d-flex gap-1 flex-wrap">
                  <v-chip v-if="node.perms.isLeader" style="height: 14px; font-size: 8px;" color="warning" variant="flat" class="font-weight-black text-white px-1">Gestor do Setor</v-chip>
                  <v-chip v-else style="height: 14px; font-size: 8px;" color="primary" variant="tonal" class="font-weight-black px-1 text-uppercase tracking-widest">Operacional</v-chip>
                </div>
                <div class="text-[8px] font-weight-black opacity-60 text-uppercase">{{ getHierarchyHint(node) }}</div>
              </div>
            </div>

            <template v-if="editMode">
              <div :ref="el => setPortInRef(node.id, el)" class="port port-in absolute elevation-4" style="top: -6px; left: 50%; transform: translateX(-50%); pointer-events: none;" />
              <div :ref="el => setPortOutRef(node.id, el)" class="port port-out absolute cursor-crosshair elevation-4" style="bottom: -6px; left: 50%; transform: translateX(-50%);" @mousedown.stop.prevent="startEdge($event, node)" />
            </template>
          </div>
        </div>
      </main>

      <v-slide-x-reverse-transition>
        <aside
          v-if="drawerNode"
          class="sidebar-properties enterprise-inspector border-l d-flex flex-column z-30 shadow-xl"
          style="width: 400px;"
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
                  <div class="drawer-header__eyebrow">Dossiê Corporativo</div>
                  <div class="d-flex align-center gap-2 flex-wrap">
                    <h3 class="drawer-header__name mb-0 text-truncate">{{ drawerNode.user.name }}</h3>
                  </div>
                  <div class="drawer-header__role text-truncate mt-1">{{ drawerNode.user.role || 'Colaborador' }}</div>
                </div>
              </div>

              <v-btn icon="mdi-close" size="small" variant="tonal" :color="drawerNode.color" class="shrink-0" @click="closeDrawer" />
            </div>

            <div class="drawer-summary-grid" style="grid-template-columns: repeat(2, 1fr);">
              <div class="drawer-summary-card">
                <span>Lidera (Subordinados)</span>
                <strong>{{ getNodeRelations(drawerNode.id).led.length }}</strong>
              </div>
              <div class="drawer-summary-card">
                <span>Reporta (Gestores)</span>
                <strong>{{ getNodeRelations(drawerNode.id).leaders.length }}</strong>
              </div>
            </div>
          </div>

          <div class="drawer-content-wrapper flex-grow-1 min-h-0 overflow-hidden">
            <div class="h-100 drawer-scroll custom-scrollbar">
              <div class="drawer-shell">

                <div class="drawer-toolbar">
                  <v-btn color="primary" size="small" variant="tonal" class="font-weight-black btn-3d drawer-toolbar__btn flex-grow-1" @click="focusNode(drawerNode)">
                    <v-icon start size="14">mdi-crosshairs-gps</v-icon>Focar no Canvas
                  </v-btn>
                </div>

                <div class="drawer-panel-grid drawer-panel-grid--two">
                  <section class="drawer-panel">
                    <div class="drawer-panel__head">
                      <div class="section-title"><v-icon size="14" class="mr-1">mdi-source-branch</v-icon> Hierarquia Direta</div>
                      <div class="drawer-panel__sub">Fluxo de reporte mapeado</div>
                    </div>

                    <div class="drawer-panel__body" :class="isLight ? 'drawer-surface-light' : 'drawer-surface-dark'">
                      <div class="drawer-chip-block">
                        <div class="drawer-chip-block__label">Reporta para (Líderes)</div>
                        <div v-if="getNodeRelations(drawerNode.id).leaders.length" class="d-flex flex-wrap gap-2">
                          <v-chip
                            v-for="leader in getNodeRelations(drawerNode.id).leaders"
                            :key="leader.id"
                            size="small"
                            :color="leader.color"
                            variant="flat"
                            class="drawer-inline-chip text-white font-weight-black"
                          >
                            {{ leader.user.name }}
                          </v-chip>
                        </div>
                        <div v-else class="drawer-empty-note border border-dashed rounded-lg pa-2 text-center opacity-50">Sem liderança direta acima.</div>
                      </div>

                      <div class="drawer-chip-block">
                        <div class="drawer-chip-block__label">Lidera (Subordinados)</div>
                        <div v-if="getNodeRelations(drawerNode.id).led.length" class="d-flex flex-wrap gap-2">
                          <v-chip
                            v-for="member in getNodeRelations(drawerNode.id).led"
                            :key="member.id"
                            size="small"
                            :color="member.color"
                            variant="tonal"
                            class="drawer-inline-chip font-weight-bold"
                          >
                            {{ member.user.name }}
                          </v-chip>
                        </div>
                        <div v-else class="drawer-empty-note border border-dashed rounded-lg pa-2 text-center opacity-50">Não possui equipe direta.</div>
                      </div>
                    </div>
                  </section>
                </div>

                <section v-if="editMode" class="drawer-panel">
                  <div class="drawer-panel__head">
                    <div class="section-title text-error"><v-icon size="14" class="mr-1">mdi-shield-edit</v-icon> Governança</div>
                    <div class="drawer-panel__sub">Controle de acessos na malha</div>
                  </div>

                  <div class="drawer-panel__body" :class="isLight ? 'drawer-surface-light' : 'drawer-surface-dark'">
                    <v-list density="compact" class="bg-transparent pa-0">
                      <v-list-item class="px-0 py-2">
                        <template #prepend>
                          <v-switch v-model="drawerNode.perms.isLeader" color="warning" hide-details density="compact" class="mr-3 switch-small" @change="handleRoleChange(drawerNode)" />
                        </template>
                        <v-list-item-title class="text-[11px] font-weight-black text-uppercase tracking-widest">Gestor do Departamento</v-list-item-title>
                        <v-list-item-subtitle class="text-[9px] opacity-60 line-height-1-4 mt-1">Concede privilégios de edição da malha neste setor.</v-list-item-subtitle>
                      </v-list-item>
                    </v-list>

                    <v-btn block color="error" variant="tonal" class="mt-4 font-weight-black btn-3d" size="small" @click="removeNodeFromOrg(drawerNode)">
                      <v-icon start size="14">mdi-account-minus</v-icon> Remover do Setor
                    </v-btn>
                  </div>
                </section>

              </div>
            </div>
          </div>
        </aside>
      </v-slide-x-reverse-transition>

      <div
        v-if="editMode && activeDepartmentId"
        class="floating-tray transition-all d-flex flex-column"
        :class="[isTrayExpanded ? 'tray-expanded' : 'tray-collapsed', isLight ? 'tray-light' : 'tray-dark']"
      >
        <div class="tray-shell d-flex flex-column h-100">
          <div class="tray-handle cursor-pointer flex-shrink-0" @click="isTrayExpanded = !isTrayExpanded">
            <div class="tray-handle__inner">
              <div class="handle-bar rounded-pill"></div>
              <div class="tray-handle__label">
                <v-icon size="14" class="mr-1">{{ isTrayExpanded ? 'mdi-chevron-down' : 'mdi-chevron-up' }}</v-icon>
                {{ isTrayExpanded ? 'Recolher Pool' : 'Banco de Talentos (' + poolUsers.length + ' disponíveis para arrastar)' }}
              </div>
            </div>
          </div>

          <template v-if="isTrayExpanded">
            <div class="tray-header border-b" :class="isLight ? 'border-grey-lighten-2' : 'border-grey-darken-2'">
              <div class="tray-header__main">
                <div class="d-flex align-center gap-2">
                  <v-avatar size="28" color="primary" class="text-white"><v-icon size="16">mdi-account-multiple-plus</v-icon></v-avatar>
                  <div>
                    <div class="tray-header__title">Colaboradores do Sistema</div>
                    <div class="tray-header__subtitle">Arraste para cima (no canvas) para incluir este usuário no setor.</div>
                  </div>
                </div>
                <div class="d-flex align-center gap-3">
                  <v-text-field v-model="poolSearch" density="compact" variant="solo-filled" hide-details placeholder="Buscar..." prepend-inner-icon="mdi-magnify" class="search-field" style="width: 200px;"></v-text-field>
                  <v-chip size="small" color="primary" variant="tonal" class="font-weight-black">
                    {{ filteredPool.length }} perfis
                  </v-chip>
                </div>
              </div>
            </div>

            <div class="tray-content custom-scrollbar pa-4">
              <div v-if="filteredPool.length === 0" class="tray-empty">
                <v-icon size="26" class="mb-2">mdi-account-check</v-icon>
                <div class="tray-empty__title">Nenhum colaborador livre</div>
                <div class="tray-empty__caption">Todos já estão na malha ou não correspondem à sua busca.</div>
              </div>

              <div v-else class="d-flex flex-wrap gap-3">
                <v-card
                  v-for="user in filteredPool"
                  :key="user.id"
                  draggable="true"
                  @dragstart="onDragStartPoolUser($event, user)"
                  class="tray-art-card cursor-grab hover-elevate d-flex align-center gap-3"
                  :class="isLight ? 'tray-art-card--light' : 'tray-art-card--dark'"
                  style="width: 260px;"
                >
                  <v-avatar size="36" class="rounded-lg shadow-sm" color="surface-variant">
                     <v-img v-if="user.avatar" :src="user.avatar" cover />
                     <span v-else class="font-weight-black text-caption">{{ user.name.charAt(0) }}</span>
                  </v-avatar>
                  <div class="min-w-0 flex-grow-1">
                    <div class="tray-art-card__title mt-0 text-truncate lh-1">{{ user.name }}</div>
                    <div class="tray-art-card__meta mt-1 text-truncate">
                      <v-icon size="11">mdi-briefcase-outline</v-icon>
                      <span class="text-[10px]">{{ user.role || 'Sem Cargo' }}</span>
                    </div>
                  </div>
                  <v-icon color="grey" size="14">mdi-drag-vertical</v-icon>
                </v-card>
              </div>
            </div>
          </template>
        </div>
      </div>

    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted, onUnmounted } from 'vue'
import { supabase } from '@/api/supabase'
import { useThemeStore } from '@/stores/theme'
import { useAppStore } from '@/stores/app'

// --- INTERFACES ---
interface OrgNode {
  id: string;
  user: { id: string; name: string; role: string; avatar: string; email: string; };
  perms: { isLeader: boolean; };
  ui_x: number; ui_y: number; color: string;
}
interface OrgEdge { id: string; fromId: string; toId: string; }
interface Department { id: string; name: string; }
interface PoolUser { id: string; name: string; email: string; role: string; avatar: string; }

// --- PROPS & STORE ---
const props = defineProps<{ profile: any; user: any; isSuperAdmin: boolean; }>()
const themeStore = useThemeStore()
const appStore = useAppStore()
const isLight = computed(() => themeStore.currentMode === 'light')

// --- STATE ---
const containerRef = ref<HTMLElement | null>(null)
const isFullscreen = ref(false)
const loading = ref(true)
const loadingDeps = ref(false)
const loadingSave = ref(false)
const editMode = ref(false)

const departments = ref<Department[]>([])
const activeDepartmentId = ref<string | null>(null)

const nodes = ref<OrgNode[]>([])
const edges = ref<OrgEdge[]>([])
const allUsers = ref<PoolUser[]>([])

const selectedNodeId = ref<string | null>(null)
const hoveredEdgeId = ref<string | null>(null)
const drawerNode = ref<OrgNode | null>(null)

const searchQuery = ref('')

// Workspace State
const workspaceRef = ref<HTMLElement | null>(null)
const nodeElementRefs = new Map<string, HTMLElement>()
const portInRefs = new Map<string, HTMLElement>()
const portOutRefs = new Map<string, HTMLElement>()
const edgeRenderTick = ref(0)
const hoverConnectNodeId = ref<string | null>(null)

const transform = reactive({ x: 0, y: 0, scale: 1 })
let isPanning = false; let startPan = { x: 0, y: 0 }
let isDraggingNode = false; let draggedNodeId: string | null = null; let nodeOffset = { x: 0, y: 0 }

const drawingEdge = reactive({ active: false, sourceNodeId: null as string | null, startX: 0, startY: 0, currentX: 0, currentY: 0 })
const activeAnimations = ref<any[]>([])

// Tray State
const isTrayExpanded = ref(false)
const poolSearch = ref('')

// --- COMPUTED ---
const canEdit = computed(() => props.isSuperAdmin || nodes.value.some(n => n.user.id === props.user?.id && n.perms.isLeader))

const filteredNodes = computed(() => {
  const q = searchQuery.value.trim().toLowerCase()
  return nodes.value.filter(n => !q || n.user.name.toLowerCase().includes(q) || n.user.role.toLowerCase().includes(q))
})

const visibleNodeIds = computed(() => new Set(filteredNodes.value.map(n => n.id)))
const visibleEdges = computed(() => edges.value.filter(e => visibleNodeIds.value.has(e.fromId) && visibleNodeIds.value.has(e.toId)))

// O Banco de talentos filtra qualquer um que NÃO esteja presente nos nós do setor atual
const poolUsers = computed(() => {
  const usedIds = new Set(nodes.value.map(n => n.user.id))
  return allUsers.value.filter(u => !usedIds.has(u.id))
})

const filteredPool = computed(() => {
  const q = poolSearch.value.trim().toLowerCase()
  return poolUsers.value.filter(u => !q || u.name.toLowerCase().includes(q) || u.role.toLowerCase().includes(q))
})

const leaderCount = computed(() => nodes.value.filter(n => n.perms.isLeader).length)
const networkHealthScore = computed(() => {
  if (nodes.value.length === 0) return 100
  const ratio = leaderCount.value / nodes.value.length
  if (ratio > 0.4) return 60
  if (ratio < 0.1 && nodes.value.length > 5) return 50
  return 100
})
const networkHealthLabel = computed(() => networkHealthScore.value >= 90 ? 'Ideal' : 'Desbalanceada')
const networkHealthColor = computed(() => networkHealthScore.value >= 90 ? 'success' : 'warning')
const networkHealthIcon = computed(() => networkHealthScore.value >= 90 ? 'mdi-shield-check' : 'mdi-alert')

const gridStyle = computed(() => {
  const size = 48 * transform.scale
  return { '--grid-position-x': `${transform.x}px`, '--grid-position-y': `${transform.y}px`, '--grid-size': `${size}px` }
})

// --- METODOS ---
onMounted(async () => {
  await fetchInitialData()
  window.addEventListener('mousemove', handleGlobalMouseMove)
  window.addEventListener('mouseup', handleGlobalMouseUp)
  window.addEventListener('resize', queueEdgeRefresh)
  document.addEventListener('fullscreenchange', () => {
    isFullscreen.value = !!document.fullscreenElement
    queueEdgeRefresh()
  })
})

onUnmounted(() => {
  window.removeEventListener('mousemove', handleGlobalMouseMove)
  window.removeEventListener('mouseup', handleGlobalMouseUp)
  window.removeEventListener('resize', queueEdgeRefresh)
})

const fetchInitialData = async () => {
  loadingDeps.value = true
  try {
    // Busca Departamentos
    const { data: deps } = await supabase.from('org_departments').select('id, name')
    if (deps && deps.length) {
      departments.value = deps
      activeDepartmentId.value = deps[0].id
    } else {
      // Mock se a tabela org_departments não existir ainda ou estiver vazia
      departments.value = [{ id: 'mock_dep_1', name: 'Departamento de TI' }]
      activeDepartmentId.value = 'mock_dep_1'
    }

    // Busca Todos os Usuários
    const { data: profiles } = await supabase.from('profiles').select('id, full_name, email, avatar_url, role')
    if (profiles) {
      allUsers.value = profiles.map(p => ({
        id: p.id, name: p.full_name || 'Desconhecido', email: p.email || '', role: p.role || '', avatar: p.avatar_url || ''
      }))
    }

    if (activeDepartmentId.value) await loadDepartmentData()

  } catch (err) {
    console.error(err)
  } finally {
    loadingDeps.value = false
  }
}

const loadDepartmentData = async () => {
  if (!activeDepartmentId.value) return
  loading.value = true
  editMode.value = false
  closeDrawer()

  try {
    const { data: dbNodes } = await supabase.from('org_nodes').select('id, is_leader, ui_x, ui_y, profile_id').eq('department_id', activeDepartmentId.value)

    if (dbNodes && dbNodes.length) {
       nodes.value = dbNodes.map((n: any) => {
        const u = allUsers.value.find(user => user.id === n.profile_id)
        return {
          id: n.id,
          user: u || { id: n.profile_id, name: 'Desconhecido', email: '', role: '', avatar: '' },
          perms: { isLeader: n.is_leader },
          ui_x: Number(n.ui_x), ui_y: Number(n.ui_y),
          color: n.is_leader ? '#8B5CF6' : '#2196F3'
        }
      })
    } else {
      nodes.value = []
    }

    const { data: dbEdges } = await supabase.from('org_edges').select('*').eq('department_id', activeDepartmentId.value)
    if (dbEdges && dbEdges.length) {
      edges.value = dbEdges.map((e: any) => ({
        id: e.id, fromId: e.from_node_id, toId: e.to_node_id
      }))
    } else {
      edges.value = []
    }

    resetView()
  } catch (e) {
    console.error(e)
  } finally {
    loading.value = false
    queueEdgeRefresh()
  }
}

const saveLayout = async () => {
  if (!activeDepartmentId.value) return
  loadingSave.value = true
  try {
    for (const node of nodes.value) {
      if (node.id.startsWith('temp_')) {
        const { data, error } = await supabase.from('org_nodes').insert({
          department_id: activeDepartmentId.value,
          profile_id: node.user.id,
          is_leader: node.perms.isLeader,
          ui_x: Math.round(node.ui_x),
          ui_y: Math.round(node.ui_y)
        }).select('id').single()

        if (!error && data) {
          const oldId = node.id; node.id = data.id
          edges.value.forEach(e => { if (e.fromId === oldId) e.fromId = data.id; if (e.toId === oldId) e.toId = data.id })
        }
      } else {
        await supabase.from('org_nodes').update({
          is_leader: node.perms.isLeader,
          ui_x: Math.round(node.ui_x), ui_y: Math.round(node.ui_y)
        }).eq('id', node.id)
      }
    }

    await supabase.from('org_edges').delete().eq('department_id', activeDepartmentId.value)
    if (edges.value.length) {
      await supabase.from('org_edges').insert(edges.value.map(e => ({
        department_id: activeDepartmentId.value, from_node_id: e.fromId, to_node_id: e.toId
      })))
    }

    appStore.showSnackbar('Malha salva com sucesso.', 'success')
    await loadDepartmentData()
  } catch (err) {
    appStore.showSnackbar('Erro ao salvar.', 'error')
  } finally {
    loadingSave.value = false
  }
}

// --- LOGICA DE VIEW ---
const toggleFullscreen = () => {
  if (!document.fullscreenElement) {
    if (containerRef.value?.requestFullscreen) {
      containerRef.value.requestFullscreen()
    }
  } else {
    document.exitFullscreen()
  }
}

const autoLayoutNodes = () => {
  const leaders = nodes.value.filter(n => n.perms.isLeader)
  const others = nodes.value.filter(n => !n.perms.isLeader)
  const hSpace = 300; const vSpace = 250; const startX = 400

  leaders.forEach((n, i) => { n.ui_x = startX + (i * hSpace); n.ui_y = 100 })
  const cx = leaders.length ? (leaders[0].ui_x + leaders[leaders.length-1].ui_x)/2 : startX
  others.forEach((n, i) => { n.ui_x = cx + (i * hSpace) - ((others.length-1)*hSpace/2); n.ui_y = 100 + vSpace })
  resetView()
}

const resetView = () => {
  setTimeout(() => {
    const root = nodes.value.find(n => n.perms.isLeader) || nodes.value[0]
    if (root && workspaceRef.value) {
      const rect = workspaceRef.value.getBoundingClientRect()
      transform.x = (rect.width / 2) - (root.ui_x * 0.8) - 100
      transform.y = 80; transform.scale = 0.8
    } else { transform.x = 200; transform.y = 80; transform.scale = 0.8 }
    queueEdgeRefresh()
  }, 50)
}

const zoomIn = () => { transform.scale = Math.min(2.5, transform.scale + 0.1); queueEdgeRefresh() }
const zoomOut = () => { transform.scale = Math.max(0.3, transform.scale - 0.1); queueEdgeRefresh() }

// --- EDGES & REFS ---
let edgeRefreshQueued = false
const queueEdgeRefresh = () => { if (edgeRefreshQueued) return; edgeRefreshQueued = true; requestAnimationFrame(() => { edgeRenderTick.value++; edgeRefreshQueued = false }) }

const setNodeElementRef = (id: string, el: any) => {
  if (el) nodeElementRefs.set(id, el.$el || el)
  else nodeElementRefs.delete(id)
}
const setPortInRef = (id: string, el: any) => {
  if (el) portInRefs.set(id, el.$el || el)
  else portInRefs.delete(id)
}
const setPortOutRef = (id: string, el: any) => {
  if (el) portOutRefs.set(id, el.$el || el)
  else portOutRefs.delete(id)
}

const getCanvasPointFromElement = (el: HTMLElement | undefined) => {
  if (!el || !workspaceRef.value) return null
  const wr = workspaceRef.value.getBoundingClientRect()
  const r = el.getBoundingClientRect()
  return { x: (r.left + r.width/2 - wr.left - transform.x)/transform.scale, y: (r.top + r.height/2 - wr.top - transform.y)/transform.scale }
}
const getNodePortPoint = (nodeId: string, type: 'in'|'out') => {
  edgeRenderTick.value // Reativo ao tick
  const p = type === 'in' ? getCanvasPointFromElement(portInRefs.get(nodeId)) : getCanvasPointFromElement(portOutRefs.get(nodeId))
  if (p) return p
  const n = nodes.value.find(x => x.id === nodeId)
  if (!n) return null
  return { x: n.ui_x + 130, y: type === 'out' ? n.ui_y + 120 : n.ui_y }
}

const startEdge = (e: MouseEvent, node: OrgNode) => {
  if (!editMode.value) return
  e.stopPropagation(); e.preventDefault()
  const pt = getNodePortPoint(node.id, 'out') || { x: node.ui_x+130, y: node.ui_y+120 }
  drawingEdge.active = true; drawingEdge.sourceNodeId = node.id
  drawingEdge.startX = pt.x; drawingEdge.startY = pt.y
  drawingEdge.currentX = pt.x; drawingEdge.currentY = pt.y
}
const finishEdge = (targetNode: OrgNode) => {
  if (!drawingEdge.active || !editMode.value) return
  if (drawingEdge.sourceNodeId === targetNode.id) { drawingEdge.active = false; return }
  const exists = edges.value.some(e => e.fromId === drawingEdge.sourceNodeId && e.toId === targetNode.id)
  if (!exists) { edges.value.push({ id: `edge_${Date.now()}`, fromId: drawingEdge.sourceNodeId!, toId: targetNode.id }); queueEdgeRefresh() }
  drawingEdge.active = false; hoverConnectNodeId.value = null
}
const deleteEdge = (id: string) => { edges.value = edges.value.filter(e => e.id !== id); hoveredEdgeId.value = null }

const buildSmoothPath = (sx: number, sy: number, ex: number, ey: number) => {
  const vGap = Math.max(50, Math.abs(ey - sy) * 0.45)
  return `M ${sx} ${sy} C ${sx} ${sy + vGap}, ${ex} ${ey - vGap}, ${ex} ${ey}`
}
const generateDrawingPath = () => buildSmoothPath(drawingEdge.startX, drawingEdge.startY, drawingEdge.currentX, drawingEdge.currentY)
const generateSVGPath = (edge: OrgEdge) => {
  const s = getNodePortPoint(edge.fromId, 'out'); const e = getNodePortPoint(edge.toId, 'in')
  if (!s || !e) return ''
  return buildSmoothPath(s.x, s.y, e.x, e.y)
}

const handleGlobalMouseMove = (e: MouseEvent) => {
  if (isPanning && !drawingEdge.active) { transform.x = e.clientX - startPan.x; transform.y = e.clientY - startPan.y }
  if (isDraggingNode && draggedNodeId && workspaceRef.value && editMode.value) {
    const wr = workspaceRef.value.getBoundingClientRect()
    const n = nodes.value.find(x => x.id === draggedNodeId)
    if (n) { n.ui_x = (e.clientX - wr.left - transform.x - nodeOffset.x)/transform.scale; n.ui_y = (e.clientY - wr.top - transform.y - nodeOffset.y)/transform.scale; queueEdgeRefresh() }
  }
  if (drawingEdge.active && workspaceRef.value) {
    const wr = workspaceRef.value.getBoundingClientRect()
    drawingEdge.currentX = (e.clientX - wr.left - transform.x)/transform.scale
    drawingEdge.currentY = (e.clientY - wr.top - transform.y)/transform.scale
  }
}
const handleGlobalMouseUp = () => {
  isPanning = false; isDraggingNode = false; draggedNodeId = null
  if (drawingEdge.active) { drawingEdge.active = false; drawingEdge.sourceNodeId = null; hoverConnectNodeId.value = null }
}

const onWorkspaceMouseDown = (e: MouseEvent) => {
  if (drawingEdge.active) return
  isPanning = true; startPan = { x: e.clientX - transform.x, y: e.clientY - transform.y }; selectedNodeId.value = null; closeDrawer()
}
const onWorkspaceWheel = (e: WheelEvent) => {
  const delta = -e.deltaY * 0.001
  let ns = transform.scale * Math.exp(delta)
  ns = Math.min(Math.max(0.3, ns), 2.5)
  const wr = workspaceRef.value!.getBoundingClientRect()
  const xs = (e.clientX - wr.left - transform.x)/transform.scale
  const ys = (e.clientY - wr.top - transform.y)/transform.scale
  transform.x = (e.clientX - wr.left) - xs * ns
  transform.y = (e.clientY - wr.top) - ys * ns
  transform.scale = ns; queueEdgeRefresh()
}

// --- NODE INTERACTION ---
const onNodeMouseDown = (e: MouseEvent, node: OrgNode) => {
  if (!editMode.value) return
  e.stopPropagation(); selectedNodeId.value = node.id; isDraggingNode = true; draggedNodeId = node.id
  if (workspaceRef.value) {
    const wr = workspaceRef.value.getBoundingClientRect()
    nodeOffset.x = e.clientX - wr.left - (node.ui_x * transform.scale + transform.x)
    nodeOffset.y = e.clientY - wr.top - (node.ui_y * transform.scale + transform.y)
  }
}
const onNodeMouseEnter = (node: OrgNode) => { if (drawingEdge.active && drawingEdge.sourceNodeId !== node.id) hoverConnectNodeId.value = node.id }
const onNodeMouseLeave = (node: OrgNode) => { if (hoverConnectNodeId.value === node.id) hoverConnectNodeId.value = null }

const openDrawer = (node: OrgNode) => { selectedNodeId.value = node.id; drawerNode.value = node }
const closeDrawer = () => { drawerNode.value = null }
const focusNode = (node: OrgNode) => {
  if (!workspaceRef.value) return
  const wr = workspaceRef.value.getBoundingClientRect()
  transform.x = (wr.width / 2) - ((node.ui_x + 130) * transform.scale)
  transform.y = (wr.height / 3) - ((node.ui_y + 100) * transform.scale)
  queueEdgeRefresh()
}

const getNodeRelations = (nodeId: string) => ({
  leaders: edges.value.filter(e => e.toId === nodeId).map(e => nodes.value.find(n => n.id === e.fromId)).filter(Boolean) as OrgNode[],
  led: edges.value.filter(e => e.fromId === nodeId).map(e => nodes.value.find(n => n.id === e.toId)).filter(Boolean) as OrgNode[],
})
const getHierarchyHint = (node: OrgNode) => {
  const rel = getNodeRelations(node.id)
  if (!rel.leaders.length && rel.led.length) return 'Diretoria'
  if (!rel.leaders.length && !rel.led.length) return 'Isolado'
  if (rel.leaders.length && rel.led.length) return 'Liderança Tática'
  return 'Base Operacional'
}

const handleRoleChange = (node: OrgNode) => { node.color = node.perms.isLeader ? '#8B5CF6' : '#2196F3' }

const removeNodeFromOrg = async (node: OrgNode) => {
  if (!confirm(`Remover ${node.user.name} deste setor? O vínculo com a malha será perdido.`)) return
  if (!node.id.startsWith('temp_')) {
    try {
      await supabase.from('org_nodes').delete().eq('id', node.id)
    } catch(e) {}
  }
  nodes.value = nodes.value.filter(n => n.id !== node.id)
  edges.value = edges.value.filter(e => e.fromId !== node.id && e.toId !== node.id)
  closeDrawer()
}

// --- DRAG & DROP NATIVO DO TRAY PARA O CANVAS ---
const onDragStartPoolUser = (e: DragEvent, user: PoolUser) => {
  e.dataTransfer?.setData('text/plain', JSON.stringify(user))
}
const onCanvasDragOver = (e: DragEvent) => { if (editMode.value) e.preventDefault() }

const onCanvasDrop = (e: DragEvent) => {
  if (!editMode.value) return
  e.preventDefault()

  const data = e.dataTransfer?.getData('text/plain')
  if (!data) return
  try {
    const user: PoolUser = JSON.parse(data)
    const wr = workspaceRef.value!.getBoundingClientRect()
    const x = (e.clientX - wr.left - transform.x)/transform.scale
    const y = (e.clientY - wr.top - transform.y)/transform.scale

    nodes.value.push({
      id: `temp_${Date.now()}`,
      user,
      perms: { isLeader: false },
      ui_x: x - 130, ui_y: y - 60,
      color: '#2196F3'
    })

    triggerDropAnimation(e.clientX, e.clientY, x, y)
    queueEdgeRefresh()
  } catch(err){}
}

const triggerDropAnimation = (cx: number, cy: number, tx: number, ty: number) => {
  const wr = workspaceRef.value?.getBoundingClientRect()
  if (!wr) return
  const fX = wr.left + (tx * transform.scale) + transform.x + (130 * transform.scale)
  const fY = wr.top + (ty * transform.scale) + transform.y + (60 * transform.scale)
  const id = Date.now()
  activeAnimations.value.push({ id, startX: cx, startY: cy, targetX: fX, targetY: fY, color: '#00d4ff' })
  setTimeout(() => { activeAnimations.value = activeAnimations.value.filter(a => a.id !== id) }, 600)
}
</script>

<style scoped lang="scss">
/* =========================================================
   ORG CHART PREMIUM STYLES (INLINE BY DEFAULT)
========================================================= */

/* Esta é a classe dinâmica acionada pelo botão Tela Cheia */
.fullscreen-mode {
  position: fixed !important;
  top: 0; left: 0; right: 0; bottom: 0;
  width: 100vw !important; height: 100vh !important;
  z-index: 9999;
  border-radius: 0 !important;
}

/* Modo Inline (Normal) */
.inline-mode {
  min-height: 700px;
  height: 75vh;
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
.transition-colors { transition: stroke .2s ease, stroke-width .2s ease; }

.pcp-builder-container { width: 100%; display: flex; flex-direction: column; overflow: hidden; }
.builder-shell { background: radial-gradient(circle at top left, rgba(59,130,246,0.10), transparent 26%), radial-gradient(circle at bottom right, rgba(14,165,233,0.10), transparent 24%); }
.theme-enterprise-dark.builder-shell { background: radial-gradient(circle at top left, rgba(56,189,248,0.10), transparent 26%), radial-gradient(circle at bottom right, rgba(99,102,241,0.12), transparent 24%), linear-gradient(180deg, #050b14 0%, #09111f 100%); }
.theme-enterprise-light.builder-shell { background: radial-gradient(circle at top left, rgba(59,130,246,0.08), transparent 24%), radial-gradient(circle at bottom right, rgba(99,102,241,0.08), transparent 22%), linear-gradient(180deg, #f6f9fd 0%, #edf3fa 100%); }

.enterprise-header { backdrop-filter: blur(24px); box-shadow: 0 4px 15px rgba(0,0,0,0.08); }
.theme-enterprise-dark .enterprise-header { box-shadow: 0 4px 20px rgba(0,0,0,0.3), inset 0 -1px 0 rgba(255,255,255,0.04); background: linear-gradient(180deg, rgba(8,15,28,.92), rgba(8,15,28,.82)) !important; }
.theme-enterprise-light .enterprise-header { background: linear-gradient(180deg, rgba(255,255,255,.94), rgba(248,250,252,.88)) !important; }

.header-shell { min-height: 82px; }
.header-brand { flex: 1 1 340px; }
.header-middle { flex: 1 1 560px; }
.header-actions { flex: 1 1 340px; }
.header-brand-mark .glow-icon-box {
  width: 50px; height: 50px; border-radius: 16px;
  background: linear-gradient(135deg, #312e81 0%, #2563eb 50%, #06b6d4 100%);
  box-shadow: 0 16px 30px rgba(59,130,246,.28), inset 0 1px 0 rgba(255,255,255,.22);
}
.header-eyebrow { font-size: 10px; font-weight: 900; letter-spacing: .18em; text-transform: uppercase; opacity: .62; }
.header-title {
  font-size: 1.22rem; font-weight: 900; line-height: 1; letter-spacing: -.03em;
  background: linear-gradient(135deg, #4f46e5 0%, #0ea5e9 100%); -webkit-background-clip: text; -webkit-text-fill-color: transparent;
}
.theme-enterprise-dark .header-title { background: linear-gradient(135deg, #c7d2fe 0%, #67e8f9 100%); -webkit-background-clip: text; -webkit-text-fill-color: transparent; }
.header-subtitle { font-size: 11px; font-weight: 700; opacity: .66; max-width: 380px; }

.search-field--xl { width: 290px; }
.role-filter--xl { width: 240px; }
.search-field :deep(.v-field), .role-filter :deep(.v-field) {
  border-radius: 14px !important; min-height: 44px !important; border: 1px solid rgba(148,163,184,.14); box-shadow: inset 0 1px 0 rgba(255,255,255,.08), 0 8px 18px rgba(15,23,42,.06);
}
.search-field-light :deep(.v-field), .role-filter.search-field-light :deep(.v-field) { background: linear-gradient(180deg, rgba(255,255,255,.96), rgba(241,245,249,.90)) !important; }
.search-field-dark :deep(.v-field), .role-filter.search-field-dark :deep(.v-field) { background: linear-gradient(180deg, rgba(15,23,42,.90), rgba(2,6,23,.82)) !important; }
.view-toggle-premium, .zoom-cluster { border-radius: 14px !important; padding: 3px; border: 1px solid rgba(148,163,184,.14); box-shadow: inset 0 1px 0 rgba(255,255,255,.08), 0 8px 18px rgba(15,23,42,.06); }
.zoom-indicator { min-width: 54px; font-size: 11px !important; }
.btn-primary-premium { min-height: 42px; padding-inline: 18px !important; border-radius: 14px !important; box-shadow: 0 14px 30px rgba(34,197,94,.24) !important; }
.btn-secondary-premium { min-height: 42px; padding-inline: 16px !important; border-radius: 14px !important; }

/* Status Rail */
.builder-status-rail { border-bottom: 1px solid rgba(148,163,184,0.12); box-shadow: 0 2px 10px rgba(15,23,42,0.05); position: relative; z-index: 15; backdrop-filter: blur(10px); }
.status-rail-light { background: linear-gradient(180deg, rgba(255,255,255,0.8), rgba(255,255,255,0.58)); }
.status-rail-dark { background: linear-gradient(180deg, rgba(10,15,27,0.82), rgba(10,15,27,0.64)); }
.status-pill { display: inline-flex; align-items: center; padding: 4px 8px; border-radius: 999px; font-size: 9px; font-weight: 800; letter-spacing: .02em; text-transform: uppercase; border: 1px solid rgba(148,163,184,0.16); box-shadow: inset 0 1px 0 rgba(255,255,255,0.12), 0 2px 4px rgba(15,23,42,0.04); }
.theme-enterprise-light .status-pill { background: rgba(255,255,255,0.9); color: #334155; }
.theme-enterprise-dark .status-pill { background: rgba(15,23,42,0.8); color: #dbeafe; }
.switch-small :deep(.v-switch__track) { height: 14px !important; } .switch-small :deep(.v-switch__thumb) { width: 10px !important; height: 10px !important; }

/* Workspace */
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

/* Nodes */
.flow-node-wrapper {
  border-radius: 22px !important; overflow: hidden; border: 1px solid rgba(255,255,255,.08);
  box-shadow: 0 18px 38px rgba(15,23,42,.14), 0 4px 12px rgba(15,23,42,.08);
  transition: transform .18s ease, box-shadow .22s ease, border-color .22s ease; z-index: 16; backdrop-filter: blur(10px); cursor: pointer;
}
.flow-node-wrapper:hover { filter: brightness(1.05); transform: translateY(-2px); box-shadow: 0 24px 48px rgba(2,6,23,0.25), 0 8px 16px rgba(15,23,42,0.15), inset 0 1px 0 rgba(255,255,255,0.14) !important; }
.node-selected { border-color: rgba(255,255,255,0.55) !important; box-shadow: 0 0 0 3px rgba(0,212,255,0.24), 0 18px 48px rgba(2,6,23,0.4) !important; z-index: 100 !important; }
.node-connect-hover { box-shadow: 0 0 0 3px rgba(76,175,80,0.45), 0 12px 30px rgba(76,175,80,0.24) !important; transform: scale(1.02); }
.node-healthy { box-shadow: 0 12px 24px rgba(15,23,42,0.15), 0 2px 6px rgba(15,23,42,0.10), inset 0 1px 0 rgba(255,255,255,.14); }
.node-attention { box-shadow: 0 12px 24px rgba(146,64,14,.22), 0 2px 6px rgba(245,158,11,.14), inset 0 1px 0 rgba(255,255,255,.14); }

.node-gloss { position: absolute; inset: 0; pointer-events: none; background: linear-gradient(180deg, rgba(255,255,255,.14), transparent 28%); z-index: 1; }
.node-topbar { min-height: 74px; padding: 12px 14px !important; background: linear-gradient(135deg, rgba(255,255,255,.08), rgba(255,255,255,.02)); border-bottom: 1px solid rgba(255,255,255,.10); position: relative; z-index: 2; }
.node-body { background: linear-gradient(180deg, rgba(255,255,255,.98), rgba(248,250,252,.96)) !important; position: relative; z-index: 2; }
.theme-enterprise-dark .node-body { background: linear-gradient(180deg, rgba(17,24,39,.96), rgba(12,18,30,.94)) !important; }
.node-avatar { box-shadow: 0 8px 16px rgba(0,0,0,.15), inset 0 1px 0 rgba(255,255,255,.3); }

.node-quick-grid { display: grid; grid-template-columns: repeat(2, minmax(0,1fr)); gap: 10px; }
.mini-stat { border-radius: 16px; padding: 10px 10px 9px; border: 1px solid rgba(148,163,184,.12); background: linear-gradient(180deg, rgba(255,255,255,.92), rgba(248,250,252,.85)); box-shadow: inset 0 1px 0 rgba(255,255,255,.65); display: flex; flex-direction: column; gap: 2px; }
.theme-enterprise-dark .mini-stat { background: linear-gradient(180deg, rgba(30,41,59,.85), rgba(15,23,42,.82)); border-color: rgba(148,163,184,.10); }
.mini-stat__label { font-size: 9px; font-weight: 900; letter-spacing: .08em; text-transform: uppercase; opacity: .54; }
.mini-stat__value { margin-top: 4px; font-size: 18px; line-height: 1; font-weight: 900; }

.action-btn { min-height: 34px !important; border-radius: 12px !important; font-size: 10px !important; letter-spacing: .02em; }

/* Ports & Edges */
.port { width: 12px; height: 12px; background: #fff; border: 3px solid #333; border-radius: 50%; z-index: 20; transition: transform .2s, background .2s; }
.port:hover { transform: scale(1.8); background: #536DFE; border-color: #fff; }
.port-out { border-color: #00d4ff; }
.port-in { border-color: #9E9E9E; }
.energy-flow { filter: drop-shadow(0 0 2px #00d4ff) drop-shadow(0 0 5px rgba(0,119,204,.8)); stroke-linecap: round; }
.cursor-cut { cursor: url('data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="%23ff5252" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="6" cy="6" r="3"></circle><circle cx="6" cy="18" r="3"></circle><line x1="20" y1="4" x2="8.12" y2="15.88"></line><line x1="14.47" y1="14.48" x2="20" y2="20"></line><line x1="8.12" y1="8.12" x2="12" y2="12"></line></svg>') 12 12, pointer; }

/* DRAWER */
.sidebar-properties { margin: 12px 12px 12px 0; border-radius: 20px; border: 1px solid rgba(148,163,184,0.14) !important; box-shadow: -15px 0 50px rgba(15,23,42,0.15), inset 0 1px 0 rgba(255,255,255,0.3) !important; background: linear-gradient(180deg, rgba(255,255,255,0.96), rgba(255,255,255,0.9)); backdrop-filter: blur(18px); }
.theme-enterprise-dark .sidebar-properties { background: linear-gradient(180deg, rgba(10,16,29,0.98), rgba(8,14,27,0.94)); box-shadow: -15px 0 50px rgba(0,0,0,0.5), inset 0 1px 0 rgba(255,255,255,0.05) !important; }
.drawer-header { padding: 18px 18px 16px; background: radial-gradient(circle at top right, color-mix(in srgb, var(--drawer-accent) 24%, white) 0%, transparent 26%), linear-gradient(180deg, rgba(255,255,255,.08), rgba(255,255,255,.02)); position: relative; overflow: hidden; }
.theme-enterprise-dark .drawer-header { background: radial-gradient(circle at top right, color-mix(in srgb, var(--drawer-accent) 20%, white) 0%, transparent 28%), linear-gradient(180deg, rgba(255,255,255,.04), rgba(255,255,255,.015)); }
.drawer-header::after { content: ""; position: absolute; inset: 0; pointer-events: none; background: linear-gradient(135deg, rgba(255,255,255,.10), transparent 42%); }
.drawer-header__avatar { box-shadow: 0 16px 32px rgba(15,23,42,.18), inset 0 1px 0 rgba(255,255,255,.25); }
.drawer-header__eyebrow { font-size: 10px; font-weight: 900; text-transform: uppercase; letter-spacing: .14em; opacity: .56; margin-bottom: 5px; }
.drawer-header__name { font-size: 1.2rem; line-height: 1; font-weight: 900; letter-spacing: -.03em; }
.drawer-header__role { margin-top: 6px; font-size: 12px; font-weight: 700; opacity: .68; }

.drawer-summary-grid { display: grid; gap: 10px; margin-top: 14px; }
.drawer-summary-card { padding: 12px; border-radius: 18px; background: rgba(255,255,255,.72); border: 1px solid rgba(148,163,184,.14); box-shadow: inset 0 1px 0 rgba(255,255,255,.6), 0 8px 20px rgba(15,23,42,.06); backdrop-filter: blur(12px); }
.theme-enterprise-dark .drawer-summary-card { background: rgba(15,23,42,.56); box-shadow: inset 0 1px 0 rgba(255,255,255,.06), 0 8px 20px rgba(0,0,0,.2); border-color: rgba(255,255,255,.05); }
.drawer-summary-card span { display: block; font-size: 9px; font-weight: 900; text-transform: uppercase; letter-spacing: .08em; opacity: .58; }
.drawer-summary-card strong { display: block; margin-top: 7px; font-size: 20px; line-height: 1; font-weight: 900; }

.drawer-scroll { height: 100%; overflow-y: auto; padding: 18px; }
.drawer-shell { display: flex; flex-direction: column; gap: 20px; padding-bottom: 28px; }
.drawer-toolbar { display: flex; gap: 8px; flex-wrap: wrap; }
.drawer-toolbar__btn { min-height: 36px !important; border-radius: 12px !important; padding-inline: 14px !important; }

.drawer-panel-grid { display: grid; gap: 14px; }
.drawer-panel-grid--two { grid-template-columns: repeat(2, minmax(0,1fr)); }
.drawer-surface-light { background: linear-gradient(180deg, rgba(255,255,255,.98), rgba(248,250,252,.95)) !important; border: 1px solid rgba(148,163,184,.14) !important; }
.drawer-surface-dark { background: linear-gradient(180deg, rgba(30,41,59,.94), rgba(15,23,42,.9)) !important; border: 1px solid rgba(148,163,184,.10) !important; }
.drawer-panel__body { border-radius: 20px !important; box-shadow: 0 10px 26px rgba(15,23,42,.06), inset 0 1px 0 rgba(255,255,255,.05); padding: 14px; }
.drawer-panel__head { margin-bottom: 10px; }
.section-title { font-size: 10px !important; font-weight: 900 !important; text-transform: uppercase; letter-spacing: .12em !important; opacity: .68; display: flex; align-items: center; margin-bottom: 6px; }
.drawer-panel__sub { font-size: 12px; font-weight: 700; opacity: .62; }
.drawer-chip-block + .drawer-chip-block { margin-top: 16px; }
.drawer-chip-block__label { margin-bottom: 8px; font-size: 10px; font-weight: 900; text-transform: uppercase; letter-spacing: .08em; opacity: .56; }
.drawer-inline-chip { min-height: 28px !important; border-radius: 999px !important; font-weight: 800 !important; }
.drawer-empty-note { font-size: 12px; font-weight: 700; opacity: .58; }

/* TRAY INFERIOR - FLOATING ISLAND EXCLUSIVA (AJUSTADA PARA POSITION ABSOLUTE) */
.floating-tray { position: absolute; bottom: 12px; left: 50%; transform: translateX(-50%); width: 85%; max-width: 900px; z-index: 40; pointer-events: none; }
.floating-tray > * { pointer-events: auto; }
.tray-shell { border-radius: 16px; overflow: hidden; backdrop-filter: blur(24px); box-shadow: 0 15px 40px rgba(0,0,0,0.35), inset 0 1px 0 rgba(255,255,255,0.15); border: 1px solid rgba(148,163,184,0.2); }
.tray-light .tray-shell { background: linear-gradient(180deg, rgba(255,255,255,.94), rgba(248,250,252,.92)); }
.tray-dark .tray-shell { background: linear-gradient(180deg, rgba(12,18,31,.96), rgba(9,14,25,.94)); }
.tray-expanded { height: 35vh; max-height: 380px; }
.tray-collapsed { height: 32px; overflow: hidden; width: 240px; }
.tray-handle { border-bottom: 1px solid rgba(148,163,184,0.1); background: rgba(0,0,0,0.02); }
.handle-bar { width: 32px; height: 3px; background: rgba(148,163,184,.6); box-shadow: inset 0 1px 0 rgba(255,255,255,.3); }
.tray-handle__inner { min-height: 32px; display: flex; align-items: center; justify-content: center; gap: 14px; }
.tray-handle__label { display: flex; align-items: center; font-size: 11px; font-weight: 900; letter-spacing: .08em; text-transform: uppercase; opacity: .72; }

.tray-header { padding: 14px 16px; min-height: 58px; background: linear-gradient(180deg, rgba(255,255,255,.04), transparent); }
.tray-header__main { display: flex; align-items: center; justify-content: space-between; gap: 16px; }
.tray-header__title { font-size: 15px; font-weight: 900; line-height: 1.1; }
.tray-header__subtitle { margin-top: 4px; font-size: 12px; font-weight: 700; opacity: .62; }
.tray-content { flex: 1 1 auto; min-height: 0; overflow-y: auto; padding: 16px; }
.tray-empty { min-height: 140px; display: flex; flex-direction: column; align-items: center; justify-content: center; text-align: center; opacity: .7; }
.tray-empty__title { font-size: 15px; font-weight: 900; }
.tray-empty__caption { margin-top: 6px; font-size: 12px; font-weight: 700; }

.tray-art-card { padding: 12px; border-radius: 16px !important; border: 1px solid rgba(148,163,184,.14) !important; box-shadow: 0 10px 20px rgba(15,23,42,.06), inset 0 1px 0 rgba(255,255,255,.05) !important; transition: transform .16s ease; }
.tray-art-card:hover { transform: translateY(-2px); box-shadow: 0 14px 28px rgba(15,23,42,.09) !important; border-color: rgba(99,102,241,.4) !important; }
.tray-art-card--light { background: linear-gradient(180deg, rgba(255,255,255,.99), rgba(248,250,252,.95)) !important; }
.tray-art-card--dark { background: linear-gradient(180deg, rgba(51,65,85,.86), rgba(15,23,42,.80)) !important; }
.tray-art-card__title { font-size: 14px; font-weight: 900; }
.tray-art-card__meta { opacity: .66; }

@keyframes suckIn {
  0% { top: var(--start-y); left: var(--start-x); transform: translate(-50%, -50%) scale(1); opacity: 1; }
  100% { top: var(--end-y); left: var(--end-x); transform: translate(-50%, -50%) scale(0); opacity: 0; filter: blur(4px); }
}
.water-drop-effect { position: absolute; animation: suckIn .6s cubic-bezier(.55,.085,.68,.53) forwards; width: 16px; height: 16px; border-radius: 50%; background-color: currentColor; box-shadow: 0 0 15px currentColor, 0 0 30px currentColor; z-index: 99999; pointer-events: none; }

.is-drawing-mode .flow-node-wrapper { z-index: 10; box-shadow: 0 0 0 2px rgba(0,212,255,0.4) !important; }
.is-drawing-mode .flow-node-wrapper:hover { box-shadow: 0 0 0 3px #00d4ff, 0 8px 24px rgba(0,212,255,0.2) !important; transform: scale(1.02); }

@media (max-width: 1200px) {
  .drawer-panel-grid--two { grid-template-columns: 1fr; }
  .workspace-hud { display: none; }
}
</style>
