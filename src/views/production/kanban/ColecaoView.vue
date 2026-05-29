<template>
  <div class="font-sans fill-height d-flex flex-column relative overflow-hidden"
    :class="themeStore?.currentMode === 'light' ? 'bg-grey-lighten-5 text-grey-darken-4' : 'bg-glass-dark text-white'">
    <div v-if="themeStore?.currentMode !== 'light'" class="background-carousel-wrapper">
      <div class="background-overlay"></div>
    </div>

    <div class="content-wrapper d-flex flex-column fill-height z-10 relative px-4 px-md-6 py-4">

      <div class="d-flex justify-space-between align-center mb-6">
        <div class="d-flex flex-column">
          <div class="breadcrumb text-caption">
            <span class="opacity-70">MJ Process</span>
            <span class="mx-2 opacity-50">></span>
            <span class="font-weight-bold">Produção</span>
          </div>
          <div class="text-h6 font-weight-black tracking-tight leading-none mt-1"
            :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">
            Kanban de Coleção
          </div>
        </div>

        <div class="d-flex align-center flex-wrap" style="gap: 10px;">

          <v-btn :color="themeStore.currentMode === 'light' ? 'grey-darken-3' : 'white'" variant="outlined" v-if="checkPermission('mfg_colecao_cadastrar')"
            class="btn-3d px-4 font-weight-bold text-caption text-uppercase" height="40" append-icon="mdi-plus"
            @click="abrirModalCadastro">
            Coleção
            <v-tooltip activator="parent" location="top">Começar nova coleção</v-tooltip>
          </v-btn>

          <v-menu :close-on-content-click="false" location="bottom end" max-width="320">
            <template v-slot:activator="{ props }">

              <v-btn variant="outlined" class="btn-3d font-weight-bold px-0" height="40" min-width="40" width="40"
                v-bind="props">
                <v-icon>mdi-cog</v-icon>
                <v-tooltip activator="parent" location="top">Personalizar aspecto e métricas</v-tooltip>
              </v-btn>
            </template>

            <v-card class="pa-4" :theme="themeStore?.currentMode">
              <div class="text-overline mb-2">Cores das Etapas</div>
              <v-list density="compact" class="pa-0 mb-4 bg-transparent">
                <v-list-item v-for="coluna in colunas" :key="coluna.id" class="px-0">
                  <template v-slot:title>
                    <span class="text-body-2">{{ formatarPecaEquivalente(coluna.titulo) }}</span>
                  </template>
                  <template v-slot:append>
                    <v-menu :close-on-content-click="false" location="left">
                      <template v-slot:activator="{ props }">
                        <v-btn v-bind="props" icon size="x-small" elevation="2"
                          :style="{ backgroundColor: coluna.cor || '#3b82f6' }"></v-btn>
                      </template>
                      <v-card>
                        <v-color-picker v-model="coluna.cor" mode="hex" hide-inputs show-swatches elevation="0"
                          @update:model-value="salvarConfiguracoes"></v-color-picker>
                      </v-card>
                    </v-menu>
                  </template>
                </v-list-item>
              </v-list>

              <v-divider class="mb-4"></v-divider>

              <div class="d-flex justify-space-between align-center mb-2">
                <div class="text-overline">Secção de KPIs</div>
                <v-switch v-model="kpisVisiveis.secaoGeral" color="primary" hide-details density="compact"
                  @change="salvarConfiguracoes"></v-switch>
              </div>

              <v-expand-transition>
                <div v-if="kpisVisiveis.secaoGeral">
                  <v-switch v-model="kpisVisiveis.totalModelos" label="Total de Modelos" color="primary" hide-details
                    density="compact" @change="salvarConfiguracoes"></v-switch>
                  <v-switch v-model="kpisVisiveis.volumeProjetado" label="Entregas (Mês)" color="primary" hide-details
                    density="compact" @change="salvarConfiguracoes"></v-switch>
                  <v-switch v-model="kpisVisiveis.devModelo" label="Desenv. Modelo" color="primary" hide-details
                    density="compact" @change="salvarConfiguracoes"></v-switch>
                  <v-switch v-model="kpisVisiveis.devEstampa" label="Desenv. Estampa" color="primary" hide-details
                    density="compact" @change="salvarConfiguracoes"></v-switch>
                  <v-switch v-model="kpisVisiveis.emPilotagem" label="Pilotagem" color="primary" hide-details
                    density="compact" @change="salvarConfiguracoes"></v-switch>
                  <v-switch v-model="kpisVisiveis.totalPiloto" label="Volume Piloto" color="primary" hide-details
                    density="compact" @change="salvarConfiguracoes"></v-switch>
                </div>
              </v-expand-transition>
            </v-card>
          </v-menu>
        </div>
      </div>

      <v-row v-if="!carregando && kpisVisiveis.secaoGeral" class="mb-3 w-auto justify-center flex-grow-0" dense>
        <v-col v-for="kpi in kpiList" :key="kpi.id" cols="12" sm="6" md="4" lg="2">
          <v-card :class="['kpi-card', kpi.color, 'hover-elevate', 'py-3', 'px-4']" v-ripple elevation="2">
            <div class="kpi-bg-icon"><v-icon>{{ kpi.icon }}</v-icon></div>
            <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
              <div class="d-flex align-center gap-2">
                <v-icon size="18" class="opacity-80">{{ kpi.icon }}</v-icon>
                <span class="kpi-label">{{ kpi.label }}</span>
              </div>
              <div class="kpi-number-group my-1">
                <span class="kpi-value">{{ kpi.value }}</span>
                <span v-if="kpi.unit" class="text-caption ml-1 font-weight-bold opacity-80">{{ kpi.unit }}</span>
              </div>
              <div class="kpi-footer mt-1">{{ kpi.footer }}</div>
            </div>
          </v-card>
        </v-col>
      </v-row>

      <div v-if="!carregando" class="d-flex flex-column gap-4 pb-4 border-b">
        <div class="d-flex flex-column flex-md-row gap-3 mb-3 justify-space-between w-100">
          <v-text-field 
            v-model="termoBusca" 
            prepend-inner-icon="mdi-magnify"
            placeholder="Buscar por nome, cód. tecido ou estampa..." 
            variant="outlined" 
            density="compact" 
            hide-details
            clearable 
            class="flex-grow-1 w-100" 
            style="max-width: 100%;"
          >
            <v-tooltip activator="parent" location="top">Pressione ESC para limpar</v-tooltip>
          </v-text-field>

          <v-btn :color="themeStore.currentMode === 'light' ? 'grey-darken-3' : 'white'" variant="outlined"
            class="btn-3d px-4 font-weight-bold text-caption text-uppercase" height="40"
            @click="mostrarModalFeed = true" append-icon="mdi mdi-calendar-blank-multiple">
            Histórico
            <v-tooltip activator="parent" location="top">Ver histórico de etapas</v-tooltip>
          </v-btn>

          <v-menu location="bottom center">
            <template v-slot:activator="{ props }">
              <v-btn variant="outlined" class="btn-3d font-weight-bold px-0 justify-content-end" height="40" min-width="40"
                rounded="md" v-bind="props">
                <v-icon>mdi-filter-cog-outline</v-icon>
                <v-tooltip activator="parent" location="top">Filtrar Etapas</v-tooltip>
              </v-btn>
            </template>

            <v-card :theme="themeStore?.currentMode" min-width="220" class="pa-2">
              <div class="text-caption text-medium-emphasis mb-2 px-2 font-weight-bold text-uppercase">Filtrar por
                Coluna
              </div>

              <v-list density="compact" nav class="pa-0">
                <v-list-item value="todos" :active="filtro === 'todos'" @click="filtro = 'todos'" color="primary"
                  rounded="lg" class="mb-1">
                  <v-list-item-title>Todos os lotes</v-list-item-title>
                </v-list-item>

                <v-list-item v-for="col in colunas" :key="col.id" :value="col.id" :active="filtro === col.id"
                  @click="filtro = col.id" :color="col.cor || 'primary'" rounded="lg" class="mb-1">
                  <v-list-item-title>{{ col.titulo }}</v-list-item-title>
                </v-list-item>
              </v-list>
            </v-card>
          </v-menu>
        </div>
      </div>

      <div v-if="carregando" class="d-flex fill-height align-center justify-center mt-10">
        <v-progress-circular indeterminate color="primary" size="64" width="6"></v-progress-circular>
      </div>

      <div v-else class="kanban-container">
        <div v-for="coluna in colunasFiltradas" :key="coluna.id"
          class="kanban-column rounded-lg pa-4 d-flex flex-column gap-3"
          :class="themeStore?.currentMode === 'light' ? 'bg-white border-grey-lighten-2 shadow-sm' : 'bg-glass-header border-bottom-white-05'"
          :style="{ borderTop: `4px solid ${coluna.cor}` }" @dragover.prevent @drop="onDrop($event, coluna.id)">
          <div class="column-header d-flex justify-space-between align-center px-1 pb-2">
            <span class="font-weight-bold text-subtitle-1">{{ coluna.titulo }}</span>
            <v-chip :color="coluna.cor" variant="tonal" size="small" class="font-weight-bold">
              {{ coluna.pecas.length }}
            </v-chip>
          </div>

          <div class="column-content">
            <v-card v-for="peca in coluna.pecas" :key="peca.id" class="mb-3 transition-swing"
              :class="{ 'is-draggable': checkPermission('mfg_colecao_arrastar'), 'hover-elevate': checkPermission('mfg_colecao_arrastar') }"
              :style="{ borderLeft: getStatusPrazo(peca)?.pulsa ? '4px solid rgb(var(--v-theme-error))' : `4px solid ${coluna.cor}` }"
              :draggable="checkPermission('mfg_colecao_arrastar')" @dragstart="onDragStart($event, peca, coluna.id)"
              @click="peca.expanded = !peca.expanded" hover>
              <v-card-item class="pb-2 pt-3 px-3">
                <div class="d-flex justify-space-between align-start mb-2">
                  <div class="text-caption text-medium-emphasis d-flex flex-column">
                    <span>Criado por: {{ peca.autor || 'Desconhecido' }}</span>
                    <span>{{ getTempoDecorrido(peca.created_at) }}</span>
                  </div>

                  <div v-if="checkPermission('mfg_colecao_arrastar')" class="d-flex gap-1 align-center">
                    <v-menu location="bottom end">
                      <template v-slot:activator="{ props }">
                        <v-btn 
                          icon="mdi-swap-horizontal" 
                          size="x-small" 
                          variant="tonal" 
                          color="primary" 
                          class="d-md-none" 
                          v-bind="props" 
                          @click.stop
                        >
                          <v-icon>mdi-swap-horizontal</v-icon>
                        </v-btn>
                      </template>
                      <v-list density="compact" class="pa-0" min-width="150">
                        <v-list-subheader class="text-caption font-weight-bold">Mover para:</v-list-subheader>
                        <v-list-item 
                          v-for="colDestino in colunas.filter(c => c.id !== coluna.id)" 
                          :key="colDestino.id"
                          @click.stop="prepararMovimentacao(peca, coluna.id, colDestino.id)"
                        >
                          <v-list-item-title class="text-caption">{{ colDestino.titulo }}</v-list-item-title>
                        </v-list-item>
                      </v-list>
                    </v-menu>

                    <v-btn icon size="x-small" variant="text" color="medium-emphasis" v-if="checkPermission('mfg_colecao_editar')"
                      @click.stop="abrirModalEdicao(peca)">
                      <v-icon>mdi-pencil-outline</v-icon>
                      <v-tooltip activator="parent" location="top">Editar modelo</v-tooltip>
                    </v-btn>
                    <v-btn icon size="x-small" variant="text" color="error" @click.stop="removeritem(peca)" v-if="checkPermission('mfg_colecao_excluir')">
                      <v-icon>mdi-trash-can-outline</v-icon>
                      <v-tooltip activator="parent" location="top">Excluir modelo</v-tooltip>
                    </v-btn>
                  </div>
                </div>

                <v-card-title class="text-subtitle-1 font-weight-bold pa-0 mb-1"
                  style="white-space: normal; line-height: 1.2;">
                  {{ peca.nome }}
                </v-card-title>

                <div class="d-flex align-center gap-2 mb-2 flex-wrap" v-if="getStatusPrazo(peca)">
                  <v-chip :color="getStatusPrazo(peca)?.color" size="x-small" class="font-weight-bold text-uppercase"
                    :class="{ 'pulse-animation': getStatusPrazo(peca)?.pulsa }">
                    {{ getStatusPrazo(peca)?.texto }}
                  </v-chip>
                </div>

                <div class="text-caption d-flex flex-column gap-1 mb-2">
                  <div><span class="text-medium-emphasis font-weight-medium">Tecido:</span> {{ peca.tecido_nome }}</div>
                  <div><span class="text-medium-emphasis font-weight-medium">Estampa:</span> {{ peca.estampa_nome }}
                  </div>
                  <div><span class="text-medium-emphasis font-weight-medium">Produto:</span> {{
                    formatarPecaEquivalente(peca.produto_nome ) }}</div>
                </div>

                <div v-if="checkPermission('mfg_colecao_cadastrar') && coluna.id === 'pilotagem'" class="mt-2">
                  <v-btn block size="small" variant="tonal" color="primary" @click.stop="abrirModalProducao(peca)">
                    Enviar para produção
                  </v-btn>
                </div>
              </v-card-item>

              <div class="text-center pb-1">
                <v-icon color="medium-emphasis" size="small"
                  :style="{ transform: peca.expanded ? 'rotate(180deg)' : 'none', transition: 'transform 0.3s ease' }">
                  mdi-chevron-down
                </v-icon>
              </div>

              <v-expand-transition>
                <div v-if="peca.expanded" @click.stop>
                  <v-divider></v-divider>
                  <v-card-text
                    :class="themeStore?.currentMode === 'light' ? 'bg-white border-grey-lighten-2 shadow-sm' : 'bg-glass-header border-bottom-white-05'">
                    <v-row dense>
                      <v-col cols="6"><strong>Quantidade:</strong> <br>{{ peca.quantidade || 0 }} un.</v-col>
                      <v-col cols="6"><strong>Entrega:</strong> <br>{{ formatarData(peca.data_entrega) }}</v-col>
                      <v-col cols="12" v-if="peca.descricao">
                        <span class="text-medium-emphasis">{{ peca.descricao }}</span>
                      </v-col>
                    </v-row>
                  </v-card-text>
                </div>
              </v-expand-transition>
            </v-card>
          </div>
        </div>
      </div>
    </div>

    <v-dialog v-model="mostrarModalFeed" max-width="600" scrollable @after-leave="fecharModalTimeline">
      <v-card :theme="themeStore?.currentMode" rounded="lg">
        <v-fade-transition mode="out-in">

          <div v-if="!pecaSelecionada" key="lista">
            <v-card-title
              class="d-flex justify-space-between align-center px-5 pt-5 pb-3 bg-grey-lighten-4 dark:bg-grey-darken-4">
              <div>
                <div class="text-h6 font-weight-bold">Selecione um Modelo</div>
                <div class="text-caption text-medium-emphasis">Acompanhe o histórico de desenvolvimento.</div>
              </div>
              <v-btn icon="mdi-close" variant="text" density="comfortable" @click="mostrarModalFeed = false"></v-btn>
            </v-card-title>

            <v-divider></v-divider>

            <div class="px-4 py-3 bg-grey-lighten-5 dark:bg-grey-darken-3 border-b">
              <v-btn-toggle v-model="filtroTimeline" mandatory color="primary" variant="outlined" density="compact"
                class="w-100 d-flex rounded-lg overflow-hidden">
                <v-btn value="atuais" class="flex-grow-1 text-caption">Em Desenvolvimento</v-btn>
                <v-btn value="finalizado" class="flex-grow-1 text-caption">Enviados p/ Produção</v-btn>
              </v-btn-toggle>
            </div>

            <v-card-text class="pa-0" style="max-height: 55vh;">
              <v-list v-if="pecasFiltradasTimeline.length > 0" lines="two" class="bg-transparent pa-2">
                <v-list-item v-for="peca in pecasFiltradasTimeline" :key="peca.id"
                  @click="abrirHistoricoDetalhado(peca)" class="rounded-lg mb-1" link>
                  <template v-slot:title>
                    <span class="font-weight-bold" v-if="peca.status === 'finalizado'">{{ peca.nome }} - {{ peca.autor }}</span>
                    <span class="font-weight-bold" v-else>{{ peca.nome }}</span>
                  </template>

                  <template v-slot:subtitle>
                    <div class="d-flex align-center gap-2 mt-1">
                      <span class="d-flex align-center"><v-icon size="x-small" class="mr-1">mdi-package-variant</v-icon>
                        {{ peca.quantidade || 0 }} un.</span>
                      <span class="d-flex align-center"><v-icon size="x-small"
                          class="mr-1">mdi-calendar-clock</v-icon> {{ formatarData(peca.data_entrega) }} </span>
                    </div>
                  </template>

                  <template v-slot:append class="d-flex flex-column gap-1">
                    <v-chip size="small" :color="peca.status === 'finalizado' ? 'success' : getColunaCor(peca.status)"
                      variant="flat" class="font-weight-medium">
                      {{ peca.status === 'finalizado' ? 'Em Produção' : getColunaTitulo(peca.status) }}
                    </v-chip>
                    <v-btn icon="mdi-cog-outline" variant="text" size="small" color="primary" @click.stop="abrirHistoricoDetalhado(peca)" class="ml-2" v-if="peca.status === 'finalizado'"></v-btn>
                  </template>
                </v-list-item>
              </v-list>

              <div v-else class="d-flex flex-column align-center justify-center pa-10 text-center text-medium-emphasis">
                <v-icon size="large" color="grey-lighten-1" class="mb-3">mdi-inbox-remove</v-icon>
                <div class="text-subtitle-1 font-weight-medium">Nenhum modelo encontrado</div>
                <div class="text-caption">Não há modelos para este filtro.</div>
              </div>
            </v-card-text>
          </div>

          <v-card :theme="themeStore?.currentMode" rounded="lg">
            <v-card-title class="d-flex justify-space-between align-center px-5 pt-4 pb-3" :class="themeStore?.currentMode === 'light' ? 'bg-grey-lighten-4' : 'bg-grey-darken-4'">
              <div class="d-flex align-center gap-3">
                <v-avatar color="primary" variant="tonal" rounded="lg">
                    <v-icon>mdi-tshirt-crew</v-icon>
                </v-avatar>
                <div>
                  <div class="text-h6 font-weight-bold lh-normal">{{ detalhesPecaDB?.nome || pecaSelecionada?.nome }}</div>
                  <div class="text-caption text-medium-emphasis">Dossiê completo da peça e auditoria de fases</div>
                </div>
              </div>
              <v-btn icon="mdi-close" variant="text" density="comfortable" @click="mostrarModalFeed = false"></v-btn>
            </v-card-title>
            <v-divider></v-divider>

            <v-card-text class="pa-5 overflow-hidden">
              <div v-if="carregandoHistorico" class="d-flex flex-column align-center justify-center py-10">
                  <v-progress-circular indeterminate color="primary" size="40"></v-progress-circular>
                  <span class="text-caption mt-3 text-medium-emphasis">Coletando informações...</span>
              </div>
              <v-row v-else dense class="align-stretch">
                  <v-col cols="12" md="6" class="pr-md-2 h-100">
                    <div class="text-caption font-weight-black text-uppercase mb-2 opacity-70 tracking-widest"><v-icon size="small" class="mr-1">mdi-information-outline</v-icon> Dados da Peça</div>
                    <v-card variant="outlined" class="pa-4 rounded-lg overflow-y-auto custom-scroll" style="height: 55vh;" :class="themeStore?.currentMode === 'light' ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-grey-darken-4 border-white-05'">
                        <div class="d-flex flex-column gap-3 text-body-2">
                          <div class="d-flex justify-space-between align-center border-b pb-2" :class="themeStore?.currentMode === 'light' ? 'border-grey-lighten-3' : 'border-white-05'">
                              <strong class="opacity-70">Status Atual:</strong>
                              <v-chip size="small" :color="detalhesPecaDB?.status === 'finalizado' ? 'success' : getColunaCor(detalhesPecaDB?.status)" variant="flat" class="font-weight-bold">
                                {{ detalhesPecaDB?.status === 'finalizado' ? 'Em Produção' : getColunaTitulo(detalhesPecaDB?.status) }}
                              </v-chip>
                          </div>
                          <div class="d-flex justify-space-between">
                              <strong class="opacity-70">Criado por:</strong> <span class="font-weight-medium text-right">{{ detalhesPecaDB?.autor || 'N/A' }}</span>
                          </div>
                          <div class="d-flex justify-space-between">
                              <strong class="opacity-70">Data de Entrega:</strong> <span class="font-weight-medium"><v-icon size="x-small" class="mr-1">mdi-calendar</v-icon>{{ formatarData(detalhesPecaDB?.data_entrega) }}</span>
                          </div>
                          <div class="d-flex justify-space-between">
                              <strong class="opacity-70">Quantidade:</strong> <span class="font-weight-medium">{{ detalhesPecaDB?.quantidade || 0 }} un.</span>
                          </div>
                          <div class="d-flex justify-space-between">
                              <strong class="opacity-70">Produto Base:</strong> <span class="font-weight-medium text-right">{{ detalhesPecaDB?.produto_nome || 'Não vinculado' }}</span>
                          </div>
                          <div class="d-flex justify-space-between">
                              <strong class="opacity-70">Tecido:</strong> <span class="font-weight-medium text-right">{{ detalhesPecaDB?.tecido_nome || 'N/A' }}</span>
                          </div>
                          <div class="d-flex justify-space-between">
                              <strong class="opacity-70">Estampa:</strong> <span class="font-weight-medium text-right">{{ detalhesPecaDB?.estampa_nome || 'N/A' }}</span>
                          </div>

                          <div v-if="detalhesPecaDB?.descricao" class="mt-2">
                            <strong class="opacity-70 d-block mb-1">Observações:</strong>
                            <div class="pa-3 rounded border text-caption" :class="themeStore?.currentMode === 'light' ? 'bg-white border-grey-lighten-3' : 'bg-grey-darken-3 border-white-05'">{{ detalhesPecaDB?.descricao }}</div>
                          </div>
                        </div>
                    </v-card>
                  </v-col>

                  <v-col cols="12" md="6" class="pl-md-2 mt-4 mt-md-0 h-100">
                    <div class="text-caption font-weight-black text-uppercase mb-2 opacity-70 tracking-widest"><v-icon size="small" class="mr-1">mdi-timeline-clock-outline</v-icon> Histórico de Etapas</div>
                    <v-card variant="outlined" class="pa-4 rounded-lg overflow-y-auto custom-scroll" style="height: 55vh;" :class="themeStore?.currentMode === 'light' ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-grey-darken-4 border-white-05'">
                        <v-timeline density="compact" side="end" align="start" truncate-line="both">
                          <v-timeline-item v-for="etapa in etapasVisiveis" :key="etapa.id"
                            :dot-color="etapa.dataSaida ? 'success' : 'primary'"
                            :icon="etapa.dataSaida ? 'mdi-check' : 'mdi-circle-medium'" size="small">
                            <div class="mb-3">
                              <div class="font-weight-bold text-body-2 d-flex align-center justify-space-between">
                                  {{ etapa.titulo }}
                              </div>
                              <div class="text-caption text-medium-emphasis mt-1 d-flex flex-column gap-1">
                                <div class="d-flex align-center"><v-icon size="x-small" class="mr-1">mdi-login</v-icon> Entrada: {{ etapa.dataEntrada }}</div>
                                <div class="d-flex align-center" v-if="etapa.dataSaida"><v-icon size="x-small" class="mr-1 text-success">mdi-logout</v-icon> Saída: {{ etapa.dataSaida }}</div>
                              </div>
                            </div>
                          </v-timeline-item>
                        </v-timeline>
                        <div v-if="etapasVisiveis.length === 0" class="text-caption text-center opacity-60 py-8 d-flex flex-column align-center">
                            <v-icon size="large" class="mb-2">mdi-history</v-icon>
                            Nenhum histórico registrado.
                        </div>
                    </v-card>
                  </v-col>
              </v-row>
            </v-card-text>
            <v-card-actions class="pa-4 border-t d-flex justify-space-between align-center" :class="themeStore?.currentMode === 'light' ? 'bg-grey-lighten-4' : 'bg-grey-darken-4'">
              <div></div>
              <div class="d-flex gap-3 align-center">
                <v-btn variant="tonal" class="px-5 font-weight-bold text-none" @click="mostrarModalFeed = false">Fechar</v-btn>
                <v-btn color="primary" variant="flat" class="px-5 font-weight-bold text-none" prepend-icon="mdi-download" @click="baixarPDFDoCard(detalhesPecaDB || pecaSelecionada)">
                  Baixar Dossiê (PDF)
                </v-btn>
              </div>
            </v-card-actions>
          </v-card>

        </v-fade-transition>
      </v-card>
    </v-dialog>

    <v-dialog v-model="exibirModalExclusao" max-width="450" persistent>
      <v-card :theme="themeStore?.currentMode">
        <v-card-title class="text-error font-weight-bold"><v-icon left color="error">mdi-alert</v-icon> Deseja excluir a
          coleção?</v-card-title>
        <v-card-text>Você está prestes a excluir: <strong>{{ pecaEmExclusaoNome }}</strong>.<br>Essa ação não terá
          volta.</v-card-text>
        <v-card-actions class="pa-4">
          <v-spacer></v-spacer>
          <v-btn variant="text" @click="exibirModalExclusao = false" :disabled="salvando">Cancelar</v-btn>
          <v-btn color="error" variant="flat" @click="ExcluirItem" :loading="salvando">Excluir</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <v-dialog v-model="exibirModalCadastro" max-width="600" persistent>
      <v-card :theme="themeStore?.currentMode">
        <v-card-title class="pa-4 pb-2 text-h6 font-weight-bold">{{ modoEdicao ? 'Editar Coleção' : 'Nova Coleção'
          }}</v-card-title>
        <v-card-text class="px-4 py-2">
          <v-row dense>
            <v-col cols="12">
              <v-text-field v-model="novaPeca.nome" label="Nome do modelo *" placeholder="Ex: Blusa Manga Longa"
                variant="outlined" density="comfortable" clearable required />
            </v-col>

            <v-col cols="12" sm="6">
              <v-text-field v-model="novaPeca.quantidade" type="number" min="1" label="Quantidade *"
                placeholder="Ex: 100" variant="outlined" density="comfortable" clearable required />
            </v-col>

            <v-col cols="12" sm="6">
              <v-text-field v-model="novaPeca.data_entrega" type="date" label="Data de entrega *" variant="outlined"
                density="comfortable" :min="dataDeHoje" clearable required />
            </v-col>

            <v-col cols="12">
              <v-autocomplete v-model="novaPeca.produto" v-model:search="produtoSearchTerm" :items="produtosFiltrados"
                item-title="fabric_type" item-value="id" label="Produto Vinculado *"
                placeholder="Digite para buscar o produto..." variant="outlined" density="comfortable" clearable
                @update:search="buscarProdutosAutocomplete()" @click="buscarProdutosAutocomplete()" return-object>
                <template v-slot:no-data>
                  <div class="px-4 py-2 text-caption opacity-70">Nenhum produto encontrado.</div>
                </template>
              </v-autocomplete>
            </v-col>

            <v-col cols="12" sm="6">
              <v-select v-model="novaPeca.tecido_id" :items="listaTecidos" item-title="fabric_type" item-value="id"
                label="Tecido" placeholder="Selecione um tecido..." variant="outlined" density="comfortable"
                clearable />
            </v-col>

            <v-col cols="12" sm="6">
              <v-select v-model="novaPeca.estampa_id" :items="listaEstampas" item-title="title" item-value="id"
                label="Estampa" placeholder="Selecione uma estampa..." variant="outlined" density="comfortable"
                clearable />
            </v-col>

            <v-col cols="12">
              <v-textarea v-model="novaPeca.descricao" label="Descrição / Observações"
                placeholder="Adicione instruções específicas para a produção..." variant="outlined"
                density="comfortable" rows="3" auto-grow clearable persistent-placeholder />
            </v-col>
          </v-row>
        </v-card-text>
        <v-card-actions class="pa-4 pt-0">
          <v-spacer></v-spacer>
          <v-btn variant="text" @click="exibirModalCadastro = false" :disabled="salvando">Cancelar</v-btn>
          <v-btn color="primary" variant="flat" @click="salvarColecao" :loading="salvando">{{ modoEdicao ? 'Salvar Alterações' : 'Cadastrar' }}</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <v-dialog v-model="dialogProducao" max-width="450" persistent>
      <v-card :theme="themeStore?.currentMode">
        <v-card-title class="font-weight-bold">Enviar para Produção Final?</v-card-title>
        <v-card-text>Confirmar a saída do modelo <strong class="text-primary">{{ pecaParaProducao?.nome }}</strong> da
          fase
          de <strong>Pilotagem (Teste)</strong> para iniciar a <strong>Produção</strong>?</v-card-text>
        <v-card-actions class="pa-4">
          <v-spacer></v-spacer>
          <v-btn variant="text" @click="fecharModalProducao" :disabled="salvando">Cancelar</v-btn>
          <v-btn color="primary" variant="flat" @click="confirmarEnvioProducao" :loading="salvando">Sim, enviar</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <v-dialog v-model="dialogMover" max-width="450" persistent>
      <v-card :theme="themeStore?.currentMode">
        <v-card-title class="font-weight-bold">Mudar etapa da coleção?</v-card-title>
        <v-card-text>Confirmar a movimentação de <strong class="text-primary">{{ ConfirmacaoPecaSelecionada?.nome
            }}</strong> para a fase de <strong class="text-primary">{{ getTituloColuna(colunaDestino)
            }}</strong>?</v-card-text>
        <v-card-actions class="pa-4">
          <v-spacer></v-spacer>
          <v-btn variant="text" @click="fecharModalMoverConfirmar" :disabled="salvando">Cancelar</v-btn>
          <v-btn color="error" variant="flat" @click="confirmarMovimentacao" :loading="salvando">Sim, mover</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted, watch, onUnmounted } from 'vue'
import { useUserStore } from '@/stores/user';
import { useCompanyStore } from '@/stores/company';
import { useThemeStore } from '@/stores/theme';
import { supabase } from '@/api/supabase';
import { useAppStore } from '@/stores/app';

const appStore = useAppStore();
const themeStore = useThemeStore()
const userStore = useUserStore();
const companyStore = useCompanyStore();

const tenantStore = computed(() => userStore.adminSelectedStore);

const checkPermission = (permissionCode: string) => {
  if (userStore.profile?.permissions?.custom_role_id?.length === 0) return false;
  const perms = userStore.profile?.permissions || [];
  return perms.includes(permissionCode);
};

interface Peca {
  id: string
  created_at?: string
  nome: string | null
  quantidade: number | null
  data_entrega: string | null
  tecido_id: string | null
  tecido_nome: string | null
  estampa_id: string | null
  estampa_nome: string | null
  descricao: string | null
  status: string | null
  autor: string | null
  empresa_id?: string
  expanded?: boolean
  produto_id: string
  produto_nome: string
  produto_preco: string
}

interface Coluna {
  id: string
  titulo: string
  cor: string
  pecas: Peca[]
  sequencia: string
}

const carregando = ref(false)
const salvando = ref(false)
const todasPecas = ref<Peca[]>([])

const kpisVisiveis = reactive({
  secaoGeral: true, totalModelos: true, volumeProjetado: true,
  emPilotagem: true, devModelo: true, devEstampa: true, totalPiloto: true
})

const termoBusca = ref('')
const dataBusca = ref('')
const filtro = ref<string>('todos')

const exibirModalCadastro = ref(false)
const exibirModalExclusao = ref(false)
const dialogProducao = ref(false)
const dialogMover = ref(false)

const modoEdicao = ref(false)
const pecaEmEdicaoId = ref<string | null>(null)
const pecaEmExclusaoId = ref<string | null>(null)
const pecaEmExclusaoNome = ref<string | null>(null)

const produtoSearchTerm = ref('')
const produtosFiltrados = ref<{ id: string; fabric_type: string, base_price: string }[]>([]);
let timeoutBusca: any = null

const listaTecidos = ref<{ id: string, fabric_type: string }[]>([])
const listaEstampas = ref<{ id: string, title: string }[]>([])

const colunas = reactive<Coluna[]>([
  { id: 'dev_modelo', titulo: 'Desenvolvimento de modelo', cor: '#3b82f6', pecas: [], sequencia: '1' },
  { id: 'dev_estampa', titulo: 'Desenvolvimento de estampa', cor: '#ec4899', pecas: [], sequencia: '2' },
  { id: 'pilotagem', titulo: 'Pilotagem (Teste)', cor: '#10b981', pecas: [], sequencia: '3' }
])

const somNotificacao = new URL('../../assets/message_notification.mp3', import.meta.url).href

const getTempoDecorrido = (created_at: string | undefined) => {
  if (!created_at) return 'Sem data'
  const diffMs = new Date().getTime() - new Date(created_at).getTime()
  if (diffMs < 0) return 'Agora mesmo'
  const mins = Math.floor(diffMs / 60000); const horas = Math.floor(diffMs / 3600000); const dias = Math.floor(diffMs / 86400000);
  if (dias > 0) return dias === 1 ? 'Há 1 dia' : `Há ${dias} dias`
  if (horas > 0) return horas === 1 ? 'Há 1 hora' : `Há ${horas} horas`
  if (mins > 0) return mins === 1 ? 'Há 1 min' : `Há ${mins} min`
  return 'Agora mesmo'
}

const formatarPecaEquivalente = (texto: string) => texto.length > 25 ? texto.substring(0, 25) + '...' : texto

const getStatusPrazo = (peca: Peca) => {
  if (!peca.data_entrega) return null
  const hoje = new Date(); hoje.setHours(0, 0, 0, 0)
  const partes = peca.data_entrega.split('T')[0].split('-')
  if (partes.length !== 3) return null
  const dataEntrega = new Date(Number(partes[0]), Number(partes[1]) - 1, Number(partes[2]))
  dataEntrega.setHours(0, 0, 0, 0)
  const diffDias = Math.ceil((dataEntrega.getTime() - hoje.getTime()) / 86400000)

  if (diffDias < 0) return { color: 'error', texto: 'Atrasado', pulsa: true }
  if (diffDias === 0) return { color: 'warning', texto: 'Entrega Hoje', pulsa: true }
  if (diffDias <= 3) return { color: 'warning', texto: `Faltam ${diffDias} dias`, pulsa: false }
  return null
}

const tocarSomAlerta = () => { new Audio(somNotificacao).play().catch(() => { }) }

let intervaloSom: ReturnType<typeof setInterval> | null = null
onMounted(() => {
  intervaloSom = setInterval(() => {
    if (todasPecas.value.some(p => getStatusPrazo(p)?.pulsa)) tocarSomAlerta()
  }, 10000)
})
onUnmounted(() => { if (intervaloSom) clearInterval(intervaloSom) })

const mostrarModalFeed = ref(false)
const pecaSelecionada = ref<any | null>(null)
const historicoDB = ref<any[]>([])
const carregandoHistorico = ref(false)
const filtroTimeline = ref('atuais')

// VARIÁVEIS PARA O NOVO MODAL DE DETALHES
const exibirModalDetalhesPeca = ref(false)
const detalhesPecaDB = ref<any>(null)

const fecharModalTimeline = () => { pecaSelecionada.value = null; historicoDB.value = [] }

const getColunaCor = (statusId: string | null) => colunas.find(c => c.id === statusId)?.cor || 'primary'
const getColunaTitulo = (statusId: string | null) => colunas.find(c => c.id === statusId)?.titulo || 'Sem Etapa'

const formatarData = (dataISO: string | null) => {
  if (!dataISO) return '-'
  const partes = dataISO.split('T')[0].split('-')
  return partes.length !== 3 ? dataISO : `${partes[2]}/${partes[1]}/${partes[0]}`
}

const formatarDataHoraTimezone = (dataISO: string) => {
  const d = new Date(dataISO)
  const dia = String(d.getDate()).padStart(2, '0'); const mes = String(d.getMonth() + 1).padStart(2, '0');
  const hora = String(d.getHours()).padStart(2, '0'); const min = String(d.getMinutes()).padStart(2, '0');
  return `Dia ${dia}/${mes} às ${hora}:${min}`
}

const selecionarPecaParaHistorico = async (peca: Peca) => {
  pecaSelecionada.value = peca
  carregandoHistorico.value = true
  try {
    const { data } = await supabase.from('kanban_colecao_historico').select('*').eq('colecao_id', peca.id).order('data_entrada', { ascending: true })
    if (data) historicoDB.value = data
  } finally { carregandoHistorico.value = false }
}

const abrirHistoricoDetalhado = async (peca: Peca) => {
  pecaSelecionada.value = peca
  carregandoHistorico.value = true
  exibirModalDetalhesPeca.value = true // Abre o novo modal construído
  
  try {
    // Busca o histórico da peça
    const { data: historicoData } = await supabase.from('kanban_colecao_historico')
      .select('*').eq('colecao_id', peca.id).order('data_entrada', { ascending: true })
    
    if (historicoData) historicoDB.value = historicoData

    // Busca os dados completos e mais recentes da peça
    const { data: pecaData } = await supabase.from('kanban_colecao')
      .select('*').eq('id', peca.id).single()
      
    if (pecaData) {
      detalhesPecaDB.value = pecaData
    } else {
      detalhesPecaDB.value = peca // Fallback para a peça já carregada na interface
    }

  } catch (error) { 
    console.error(error) 
  } finally { 
    carregandoHistorico.value = false 
  }
}

// LOGICA DE GERAR PDF DE DOSSIÊ DE COLEÇÃO
const baixarPDFDoCard = (peca: Peca) => gerarPDFDossieColecao(peca)

const gerarPDFDossieColecao = (peca: Peca) => {
  const dataHoje = new Date().toLocaleDateString('pt-BR');
  const horaHoje = new Date().toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' });
  const numeroDoc = peca.id ? peca.id.substring(0, 8).toUpperCase() : Math.floor(Math.random() * 1000000);

  const html = `
    <!DOCTYPE html>
    <html lang="pt-BR">
    <head>
      <meta charset="UTF-8">
      <title>DOSSIÊ COLEÇÃO - ${numeroDoc}</title>
      <style>
        @page { size: A4 portrait; margin: 15mm; }
        * { box-sizing: border-box; }
        body { font-family: 'Segoe UI', Arial, sans-serif; font-size: 13px; color: #111827; margin: 0; padding: 0; line-height: 1.5; }
        .container { width: 100%; max-width: 190mm; margin: 0 auto; }
        .header { display: flex; width: 100%; border: 2px solid #111827; border-radius: 6px; margin-bottom: 20px; overflow: hidden; }
        .header-title { width: 75%; display: flex; flex-direction: column; justify-content: center; align-items: center; padding: 10px; }
        .header-title h1 { margin: 0; font-size: 20px; text-transform: uppercase; letter-spacing: 1px; color: #111827; }
        .header-title p { margin: 5px 0 0 0; font-size: 14px; font-weight: 600; color: #4b5563; }
        .header-info { width: 25%; border-left: 1px solid #111827; background-color: #f9fafb; padding: 10px; font-size: 12px; }
        .header-info strong { display: inline-block; width: 60px; }
        table { width: 100%; border-collapse: collapse; margin-bottom: 20px; border-radius: 6px; }
        th, td { border: 1px solid #d1d5db; padding: 8px 12px; text-align: left; }
        th { background-color: #f3f4f6; font-size: 12px; text-transform: uppercase; color: #374151; font-weight: 700; width: 25%; }
        td { font-size: 13px; color: #111827; }
        .obs-box { border: 1px solid #d1d5db; border-radius: 6px; padding: 15px; margin-bottom: 20px; min-height: 100px; background-color: #fcfcfc; }
        .obs-title { font-weight: 700; font-size: 12px; text-transform: uppercase; margin-bottom: 8px; color: #374151; border-bottom: 1px solid #e5e7eb; padding-bottom: 5px; }
        .footer { margin-top: 40px; text-align: center; font-size: 10px; color: #9ca3af; border-top: 1px solid #e5e7eb; padding-top: 10px; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <div class="header-title">
            <h1>Dossiê de Coleção</h1>
            <p>FICHA TÉCNICA E ACOMPANHAMENTO</p>
          </div>
          <div class="header-info">
            <div style="margin-bottom: 5px;"><strong>DOC Nº:</strong> <span style="color: #ef4444; font-weight: 700; font-size: 14px;">${numeroDoc}</span></div>
            <div style="margin-bottom: 5px;"><strong>Emissão:</strong> ${dataHoje}</div>
            <div><strong>Hora:</strong> ${horaHoje}</div>
          </div>
        </div>

        <table>
          <tr><th>Modelo da Peça</th><td colspan="3" style="font-weight: 700; font-size: 14px; text-transform: uppercase;">${peca.nome || 'N/A'}</td></tr>
          <tr><th>Criado Por</th><td>${peca.autor || 'N/A'}</td><th>Previsão Entrega</th><td style="color: #dc2626; font-weight: 700;">${formatarData(peca.data_entrega)}</td></tr>
          <tr><th>Produto Base</th><td colspan="3">${peca.produto_nome || 'Não vinculado'}</td></tr>
          <tr><th>Tecido</th><td>${peca.tecido_nome || 'N/A'}</td><th>Estampa</th><td>${peca.estampa_nome || 'N/A'}</td></tr>
          <tr><th>Quantidade</th><td colspan="3" style="font-weight: 700; font-size: 14px;">${peca.quantidade || 0} un.</td></tr>
        </table>

        <div class="obs-box">
          <div class="obs-title">Observações e Detalhes Técnicos</div>
          <div style="font-size: 13px; line-height: 1.6; white-space: pre-line;">${peca.descricao || 'Nenhuma observação registrada.'}</div>
        </div>

        <div class="footer">Documento gerado automaticamente pelo Sistema Foxie ${dataHoje} às ${horaHoje}.</div>
      </div>
    </body>
    </html>
  `;

  let iframe = document.getElementById('impressao-pdf-oculto') as HTMLIFrameElement;
  if (!iframe) {
    iframe = document.createElement('iframe');
    iframe.id = 'impressao-pdf-oculto';
    iframe.style.display = 'none';
    document.body.appendChild(iframe);
  }

  const doc = iframe.contentDocument || iframe.contentWindow?.document;
  if (doc) {
    doc.open();
    doc.write(html);
    doc.close();
  }

  setTimeout(() => {
    iframe.contentWindow?.focus();
    iframe.contentWindow?.print();
  }, 500);
};

watch(mostrarModalFeed, (aberto) => {
  if (aberto) {
    const temAtivas = todasPecas.value.some(p => p.status !== 'finalizado')
    filtroTimeline.value = temAtivas ? 'atuais' : 'finalizado'
  }
})

const pecasFiltradasTimeline = computed(() => {
  return todasPecas.value.filter(peca => {
    if (filtroTimeline.value === 'atuais') return peca.status !== 'finalizado'
    if (filtroTimeline.value === 'finalizado') return peca.status === 'finalizado'
    return true
  }).sort((a, b) => {
    const dA = a.data_entrega ? new Date(a.data_entrega).getTime() : 0
    const dB = b.data_entrega ? new Date(b.data_entrega).getTime() : 0
    return dB - dA
  })
})

const etapasVisiveis = computed(() => {
  if (!pecaSelecionada.value || historicoDB.value.length === 0) return [];

  const historicoOrdenado = [...historicoDB.value].sort((a, b) => {
    return new Date(a.data_entrada).getTime() - new Date(b.data_entrada).getTime();
  });

  const etapas = historicoOrdenado.map((item, index) => {
    const proximoItem = historicoOrdenado[index + 1];
    const config = colunas.find(c => c.id === item.status) || { titulo: item.status };

    let tituloEtapa = config.titulo;
    if (item.status === 'finalizado') tituloEtapa = 'Enviado para Produção';

    const dataSaidaCalculada = item.data_saida || (proximoItem ? proximoItem.data_entrada : null);

    return {
      id: item.id,
      status: item.status,
      titulo: tituloEtapa,
      dataEntrada: item.data_entrada ? formatarDataHoraTimezone(item.data_entrada) : null,
      dataSaida: dataSaidaCalculada ? formatarDataHoraTimezone(dataSaidaCalculada) : null
    };
  });

  return etapas.reverse();
});

const buscarListasAuxiliares = async () => {
  try {
    const { data: tecidos } = await supabase.from('stock').select('id, fabric_type').order('fabric_type').eq('target_tab', 'tab_2kc7pi').eq('visible_in_sales', true)
    if (tecidos) listaTecidos.value = tecidos
    const { data: estampas } = await supabase.from('catalog_stamps').select('id, title').order('title')
    if (estampas) listaEstampas.value = estampas
  } catch (error) { console.error(error) }
}

const carregarConfiguracoes = async () => {
  const userId = userStore.profile?.id
  if (!userId) return
  try {
    const { data, error } = await supabase.from('kanban_colecao_configuracoes').select('*').eq('perfil_id', userId).maybeSingle()
    if (error) { return }

    if (data) {
      kpisVisiveis.secaoGeral = data.kpi_secao_geral !== 0
      kpisVisiveis.totalModelos = data.kpi_total_de_modelos !== 0
      kpisVisiveis.volumeProjetado = data.kpi_volume_total !== 0
      kpisVisiveis.devModelo = data.kpi_total_desenvolvimento_modelo !== 0
      kpisVisiveis.devEstampa = data.kpi_total_desenvolvimento_estampa !== 0
      kpisVisiveis.emPilotagem = data.kpi_total_piloto !== 0
      kpisVisiveis.totalPiloto = data.kpi_total_volume_piloto !== 0

      if (data.cor_tabela_desenvolvimento_modelo) colunas[0].cor = data.cor_tabela_desenvolvimento_modelo
      if (data.cor_tabela_desenvolvimento_estampa) colunas[1].cor = data.cor_tabela_desenvolvimento_estampa
      if (data.cor_tabela_pilotagem) colunas[2].cor = data.cor_tabela_pilotagem
    } else {
      await salvarConfiguracoes()
    }
  } catch (err) { console.error(err) }
}

const dataDeHoje = computed(() => {
  const d = new Date(); return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
})

const buscarProdutosAutocomplete = async (val?: any) => {
  const searchTerm = typeof val === 'string' ? val.trim() : '';

  if (timeoutBusca) clearTimeout(timeoutBusca)

  timeoutBusca = setTimeout(async () => {
    try {
      let query = supabase
        .from('stock')
        .select('id, fabric_type, base_price')
        .eq('target_tab', 'ready_delivery')
        .order('fabric_type')
        .limit(50);

      if (searchTerm) {
        query = query.ilike('fabric_type', `%${searchTerm}%`);
      }

      const { data, error } = await query;
      if (error) throw error;
      if (data) produtosFiltrados.value = data;
    } catch (error) {
      console.error(error);
    }
  }, 300)
}

const salvarConfiguracoes = async () => {
  const userId = userStore.profile?.id
  if (!userId) return

  const payload = {
    perfil_id: userId, kpi_secao_geral: kpisVisiveis.secaoGeral ? 1 : 0, kpi_total_de_modelos: kpisVisiveis.totalModelos ? 1 : 0,
    kpi_volume_total: kpisVisiveis.volumeProjetado ? 1 : 0, kpi_total_desenvolvimento_modelo: kpisVisiveis.devModelo ? 1 : 0,
    kpi_total_desenvolvimento_estampa: kpisVisiveis.devEstampa ? 1 : 0, kpi_total_piloto: kpisVisiveis.emPilotagem ? 1 : 0,
    kpi_total_volume_piloto: kpisVisiveis.totalPiloto ? 1 : 0,
    cor_tabela_desenvolvimento_modelo: colunas[0].cor, cor_tabela_desenvolvimento_estampa: colunas[1].cor, cor_tabela_pilotagem: colunas[2].cor
  }
  try { await supabase.from('kanban_colecao_configuracoes').upsert(payload, { onConflict: 'perfil_id' }) }
  catch (err) { console.error(err) }
}

const totalModelos = computed(() => { return colunas.reduce((acc, coluna) => acc + coluna.pecas.length, 0) })
const totalEntregasMesAtual = computed(() => {
  let mesAlvo = dataBusca.value ? dataBusca.value.substring(0, 7) : `${new Date().getFullYear()}-${String(new Date().getMonth() + 1).padStart(2, '0')}`
  let count = 0
  colunas.forEach(coluna => { count += coluna.pecas.filter(p => p.data_entrega && p.data_entrega.startsWith(mesAlvo)).length })
  return count
})
const totalDevModelo = computed(() => { const c = colunas.find(c => c.id === 'dev_modelo'); return c ? c.pecas.length : 0 })
const totalDevEstampa = computed(() => { const c = colunas.find(c => c.id === 'dev_estampa'); return c ? c.pecas.length : 0 })
const totalPilotagem = computed(() => { const c = colunas.find(c => c.id === 'pilotagem'); return c ? c.pecas.length : 0 })
const totalPiloto = computed(() => { const c = colunas.find(c => c.id === 'pilotagem'); if (!c) return 0; return c.pecas.reduce((acc, curr) => acc + (curr.quantidade || 0), 0) })

const kpiList = computed(() => [
  { id: 'total', label: 'Total Modelos', value: totalModelos.value, footer: 'Modelos ativos', icon: 'mdi-tshirt-crew', color: 'bg-gradient-info', unit: '' },
  { id: 'entregas', label: 'Entregas (Mês)', value: totalEntregasMesAtual.value, footer: 'Neste mês', icon: 'mdi-calendar-check', color: 'bg-gradient-purple', unit: 'un.' },
  { id: 'devModelo', label: 'Desenv. Modelo', value: totalDevModelo.value, footer: 'Em etapa', icon: 'mdi-pencil-ruler', color: 'bg-gradient-warning', unit: '' },
  { id: 'devEstampa', label: 'Desenv. Estampa', value: totalDevEstampa.value, footer: 'Em etapa', icon: 'mdi-palette', color: 'bg-gradient-red', unit: '' },
  { id: 'pilotagem', label: 'Pilotagem', value: totalPilotagem.value, footer: 'Modelos em teste', icon: 'mdi-sewing-machine', color: 'bg-gradient-green', unit: '' },
  { id: 'volumePiloto', label: 'Volume Piloto', value: totalPiloto.value, footer: 'Peças totais', icon: 'mdi-package-variant-closed', color: 'bg-gradient-info', unit: 'un.' }
].filter(item => {
  if (item.id === 'total') return kpisVisiveis.totalModelos;
  if (item.id === 'entregas') return kpisVisiveis.volumeProjetado;
  if (item.id === 'devModelo') return kpisVisiveis.devModelo;
  if (item.id === 'devEstampa') return kpisVisiveis.devEstampa;
  if (item.id === 'pilotagem') return kpisVisiveis.emPilotagem;
  if (item.id === 'volumePiloto') return kpisVisiveis.totalPiloto;
  return true;
}));

const organizarColunas = () => {
  colunas.forEach(c => c.pecas = [])
  todasPecas.value.forEach(peca => {
    if (peca.status === 'finalizado') return;

    if (termoBusca.value) {
      const termo = termoBusca.value.toLowerCase()
      const matchNome = (peca.nome || '').toLowerCase().includes(termo)
      const matchTecido = String(peca.tecido_id || '').includes(termo)
      const matchEstampa = String(peca.estampa_id || '').includes(termo)
      if (!matchNome && !matchTecido && !matchEstampa) return
    }
    if (dataBusca.value) {
      const dataPeca = peca.data_entrega ? peca.data_entrega.split('T')[0] : ''
      if (dataPeca?.substring(0, 7) !== dataBusca.value.substring(0, 7)) return
    }
    const statusDestino = peca.status || 'dev_modelo'
    const colunaEncontrada = colunas.find(c => c.id === statusDestino)
    if (colunaEncontrada) colunaEncontrada.pecas.push(peca)
    else colunas[0]?.pecas.push(peca)
  })
}

const colunasFiltradas = computed(() => filtro.value === 'todos' ? colunas : colunas.filter(c => c.id === filtro.value))
watch([termoBusca, dataBusca], () => organizarColunas())

const buscarColecoes = async () => {
  carregando.value = true
  try {
    let query = supabase.from('kanban_colecao').select('*').in('status', ['dev_modelo', 'dev_estampa', 'pilotagem', 'finalizado']).eq('empresa_id', companyStore.currentCompany?.id).order('data_entrega', { ascending: false })
    if (dataBusca.value) query = query.ilike('data_entrega', `${dataBusca.value.substring(0, 7)}%`)
    const { data, error } = await query.order('data_entrega', { ascending: true })
    if (error) throw error
    todasPecas.value = (data || []).map(item => ({ ...item, expanded: false }))
    organizarColunas()
  } catch (error) { console.error(error) }
  finally { carregando.value = false }
}

onMounted(() => { buscarColecoes(); carregarConfiguracoes(); buscarListasAuxiliares() })

const novaPeca = reactive<Record<string, any>>({ nome: null, quantidade: null, data_entrega: null, tecido_id: null, estampa_id: null, descricao: null, produto: null, produto_nome: null, produto_preco: null, tecido_nome: null, estampa_nome: null })

const abrirModalCadastro = () => {
  modoEdicao.value = false; pecaEmEdicaoId.value = null
  Object.assign(novaPeca, { nome: null, quantidade: null, data_entrega: null, tecido_id: null, estampa_id: null, descricao: null, produto: null, produto_nome: null, produto_preco: null, tecido_nome: null, estampa_nome: null })
  produtoSearchTerm.value = ''; produtosFiltrados.value = []
  buscarProdutosAutocomplete('');
  exibirModalCadastro.value = true
}

const abrirModalEdicao = async (peca: Peca) => {
  modoEdicao.value = true; pecaEmEdicaoId.value = peca.id
  Object.assign(novaPeca, {
    nome: peca.nome || '', quantidade: peca.quantidade ?? '', data_entrega: peca.data_entrega || '',
    tecido_id: peca.tecido_id ?? '', estampa_id: peca.estampa_id ?? '', descricao: peca.descricao || '', produto: '',
    produto_nome: peca.produto_nome || '', produto_preco: peca.produto_preco || '', tecido_nome: peca.tecido_nome || '', estampa_nome: peca.estampa_nome || ''
  })
  produtoSearchTerm.value = ''
  buscarProdutosAutocomplete('');

  if (peca.produto_id) {
    const { data: produtos } = await supabase.from('stock').select('id, fabric_type, base_price').order('fabric_type').eq('target_tab', 'ready_delivery')
    if (produtos) {
      produtosFiltrados.value = produtos
      novaPeca.produto = produtos.find(p => p.id === peca.produto_id) || null
    }
  }
  exibirModalCadastro.value = true
}

const removeritem = (peca: Peca) => { pecaEmExclusaoId.value = peca.id; pecaEmExclusaoNome.value = peca.nome; exibirModalExclusao.value = true }

const ExcluirItem = async () => {
  if (!pecaEmExclusaoId.value) return
  salvando.value = true
  try {
    const { error } = await supabase.from('kanban_colecao').delete().eq('id', pecaEmExclusaoId.value)
    if (error) throw error
    todasPecas.value = todasPecas.value.filter(p => p.id !== pecaEmExclusaoId.value)
    organizarColunas(); exibirModalExclusao.value = false
    appStore.showSnackbar('Coleção excluída com sucesso.', 'success');
  } catch (error: any) { 
    appStore.showSnackbar(`Não foi possível excluir a coleção. Detalhe: ${error?.message || error?.details}`, 'error') 
  }
  finally { salvando.value = false }
}

const salvarColecao = async () => {
  if (!novaPeca.nome || !novaPeca.quantidade || !novaPeca.data_entrega || !novaPeca.tecido_id) { 
    appStore.showSnackbar('Preencha todos os campos obrigatórios.', 'warning'); 
    return 
  }

  if (Number(novaPeca.quantidade) <= 0) {
    appStore.showSnackbar('A quantidade deve ser maior que zero.', 'warning');
    return
  }

  if (!novaPeca.produto) { 
    appStore.showSnackbar('Erro: É obrigatório selecionar um Produto válido da lista de busca antes de salvar.', 'error'); 
    return 
  }

  salvando.value = true
  try {
    const tecidoSelecionado = listaTecidos.value.find(t => t.id === novaPeca.tecido_id)
    const estampaSelecionada = listaEstampas.value.find(e => e.id === novaPeca.estampa_id)

    let produtoId = null;
    let produtoNome = null;
    let precoUnitario = null;

    if (typeof novaPeca.produto === 'object') {
      produtoId = novaPeca.produto.id;
      produtoNome = novaPeca.produto.fabric_type;
      precoUnitario = novaPeca.produto.base_price;
    } else {
      produtoId = novaPeca.produto;
      const prodEncontrado = produtosFiltrados.value.find(p => p.id === produtoId);
      produtoNome = prodEncontrado?.fabric_type || null;
      precoUnitario = prodEncontrado?.base_price || null;
    }

    const payload = {
      nome: novaPeca.nome,
      quantidade: Number(novaPeca.quantidade) || null,
      data_entrega: novaPeca.data_entrega || null,
      tecido_id: novaPeca.tecido_id || null,
      estampa_id: novaPeca.estampa_id || null,
      descricao: novaPeca.descricao || null,
      produto_id: produtoId,
      tecido_nome: tecidoSelecionado ? tecidoSelecionado.fabric_type : null,
      estampa_nome: estampaSelecionada ? estampaSelecionada.title : null,
      produto_nome: produtoNome,
      preco_unitario: precoUnitario
    }

    if (modoEdicao.value && pecaEmEdicaoId.value) {
      await supabase.from('kanban_colecao').update(payload).eq('id', pecaEmEdicaoId.value)
      const index = todasPecas.value.findIndex(p => p.id === pecaEmEdicaoId.value)
      if (index !== -1) todasPecas.value[index] = { ...todasPecas.value[index], ...payload }
      appStore.showSnackbar('Coleção atualizada com sucesso.', 'success')
    } else {
      const payloadInsert = { ...payload, status: 'dev_modelo', autor: userStore.profile?.username || userStore.profile?.id, empresa_id: companyStore.currentCompany?.id || tenantStore.value }
      const { data } = await supabase.from('kanban_colecao').insert([payloadInsert]).select()
      if (data && data.length > 0) todasPecas.value.unshift({ ...data[0], expanded: false })
      else await buscarColecoes()
      appStore.showSnackbar('Coleção cadastrada com sucesso.', 'success')
    }
    organizarColunas(); exibirModalCadastro.value = false
  } catch (error: any) { 
    appStore.showSnackbar(`Não foi possível salvar a coleção. Detalhe: ${error?.message || error?.details}`, 'error') 
  }
  finally { salvando.value = false }
}

const ConfirmacaoPecaSelecionada = ref<Peca | null>(null)
const colunaOrigemId = ref<string>(''); const colunaDestino = ref<string>(''); const pecaParaProducao = ref<Peca | null>(null)
const pecaArrastada = ref<Peca | null>(null); const origemArrastoId = ref<string>('')

const onDragStart = (event: DragEvent, peca: Peca, origemId: string) => { 
  if (!checkPermission('mfg_colecao_arrastar')) return; 
  pecaArrastada.value = peca; 
  origemArrastoId.value = origemId 
}

const prepararMovimentacao = (peca: Peca, origemId: string, destinoId: string) => {
  ConfirmacaoPecaSelecionada.value = peca
  colunaOrigemId.value = origemId
  colunaDestino.value = destinoId
  dialogMover.value = true;
}

const onDrop = (event: DragEvent, destinoId: string) => {
  if (!pecaArrastada.value || origemArrastoId.value === destinoId) return
  
  const peca = pecaArrastada.value
  const origemId = origemArrastoId.value
  pecaArrastada.value = null

  prepararMovimentacao(peca, origemId, destinoId)
}

const fecharModalMoverConfirmar = () => { ConfirmacaoPecaSelecionada.value = null; colunaOrigemId.value = ''; colunaDestino.value = ''; dialogMover.value = false }

const confirmarMovimentacao = async () => {
  if (!ConfirmacaoPecaSelecionada.value || !colunaDestino.value) return
  salvando.value = true
  if (ConfirmacaoPecaSelecionada.value.estampa_id === null || ConfirmacaoPecaSelecionada.value.tecido_id === null) { 
    appStore.showSnackbar('Preencha todos os campos para mudar essa coleção de etapa', 'warning');
    salvando.value = false; fecharModalMoverConfirmar();
    return 
  }

  try {
    const colOrigem = colunas.find(c => c.id === colunaOrigemId.value); const colDestino = colunas.find(c => c.id === colunaDestino.value)
    if (Number(colDestino?.sequencia || 1) > Number(colOrigem?.sequencia || 1) + 1) { 
      appStore.showSnackbar("Não é possível mover. Motivo: Você não passou por todas as etapas.", 'error'); 
      salvando.value = false; fecharModalMoverConfirmar(); return 
    }

    await supabase.from('kanban_colecao').update({ status: colunaDestino.value }).eq('id', ConfirmacaoPecaSelecionada.value.id)
    const index = todasPecas.value.findIndex(p => p.id === ConfirmacaoPecaSelecionada.value?.id)
    if (index !== -1) todasPecas.value[index].status = colunaDestino.value

    appStore.showSnackbar('Modelo avançado com sucesso!', 'success')
    organizarColunas(); fecharModalMoverConfirmar()
  } catch (error) { 
    appStore.showSnackbar('Não foi possível mover o card.', 'error') 
  }
  finally { salvando.value = false }
}

const abrirModalProducao = (peca: Peca) => { pecaParaProducao.value = peca; dialogProducao.value = true }
const fecharModalProducao = () => { pecaParaProducao.value = null; dialogProducao.value = false }

const confirmarEnvioProducao = async () => {
  if (!pecaParaProducao.value) return
  salvando.value = true

  try {
    const payloadProducao = {
      nome: pecaParaProducao.value.nome,
      quantidade: pecaParaProducao.value.quantidade,
      data_entrega: pecaParaProducao.value.data_entrega,
      tecido_id: pecaParaProducao.value.tecido_id,
      estampa_id: pecaParaProducao.value.estampa_id,
      estampa_nome: pecaParaProducao.value.estampa_nome,
      tecido_nome: pecaParaProducao.value.tecido_nome,
      produto_nome: pecaParaProducao.value.produto_nome,
      descricao: pecaParaProducao.value.descricao,
      status: 'producao',
      autor: pecaParaProducao.value.autor,
      empresa_id: pecaParaProducao.value.empresa_id || companyStore.currentCompany?.id,
      produto_id: pecaParaProducao.value.produto_id,
      preco_unitario: (pecaParaProducao.value as any).preco_unitario
    }

    const { error: erroInsert } = await supabase.from('kanban_producao').insert([payloadProducao])
    if (erroInsert) throw erroInsert

    const { error: erroUpdate } = await supabase.from('kanban_colecao').update({ status: 'finalizado' }).eq('id', pecaParaProducao.value.id)
    if (erroUpdate) throw erroUpdate

    await supabase.from('kanban_colecao_historico').insert({
      colecao_id: pecaParaProducao.value.id,
      status: 'finalizado',
      perfil_id: userStore.profile?.id
    })

    const index = todasPecas.value.findIndex(p => p.id === pecaParaProducao.value?.id)
    if (index !== -1) todasPecas.value[index].status = 'finalizado'

    appStore.showSnackbar('Enviado para Produção com sucesso!', 'success')
    organizarColunas()
    fecharModalProducao()

  } catch (error: any) {
    appStore.showSnackbar(`Não foi possível enviar o modelo para a produção. Detalhe: ${error?.message || error?.details || 'Erro desconhecido'}`, 'error')
  } finally {
    salvando.value = false
  }
}

const getTituloColuna = (id: string) => colunas.find(c => c.id === id)?.titulo || ''
</script>

<style scoped>
.kanban-container {
  display: flex;
  flex-direction: row;
  align-items: flex-start;
  gap: 10px;
  padding-bottom: 10px;
  width: 100%;
  max-width: 100vw;
  -webkit-overflow-scrolling: touch;
  height: calc(100vh - 390px);
  max-height: calc(100vh - 390px);
  overflow: hidden;
}

.kanban-column {
  flex: 0 0 300px;
  min-width: 33%;
  height: 100%;
  display: flex;
  flex-direction: column;
  transition: all 0.3s ease;
  user-select: none;
  margin-top: 10px;
  background-color: rgba(255, 255, 255, 0.035);
}

.column-content {
  overflow-y: auto;
  flex-grow: 1;
  padding-right: 4px;
}

.column-content::-webkit-scrollbar {
  width: 6px;
}

.column-content::-webkit-scrollbar-thumb {
  background: rgba(150, 150, 150, 0.3);
  border-radius: 10px;
}

.is-draggable {
  cursor: grab;
}

.is-draggable:active {
  cursor: grabbing;
}

.kpi-card {
  color: white !important;
  position: relative;
  min-height: 110px;
  overflow: hidden;
  border-radius: 8px;
}

.kpi-bg-icon {
  position: absolute;
  right: -20px;
  bottom: -20px;
  opacity: 0.15;
  transform: rotate(-15deg);
  pointer-events: none;
}

.kpi-bg-icon .v-icon {
  font-size: 100px;
  color: white;
}

.kpi-label {
  font-size: 12px;
  font-weight: 900;
  letter-spacing: .2px;
  text-transform: uppercase;
}

.kpi-value {
  font-size: 22px;
  font-weight: 900;
}

.kpi-footer {
  font-size: 11px;
  opacity: .9;
  font-weight: 700;
}

.bg-gradient-info {
  background: linear-gradient(135deg, #0288d1, #005b9f) !important;
}

.bg-gradient-green {
  background: linear-gradient(135deg, #2e7d32, #1b5e20) !important;
}

.bg-gradient-red {
  background: linear-gradient(135deg, #c62828, #8e0000) !important;
}

.bg-gradient-purple {
  background: linear-gradient(135deg, #7b1fa2, #4a148c) !important;
}

.bg-gradient-warning {
  background: linear-gradient(135deg, #FFB300, #F57F17) !important;
}

.hover-elevate {
  transition: transform 0.2s ease, box-shadow 0.2s ease;
}

.hover-elevate:hover {
  transform: translateY(-3px);
  box-shadow: 0 8px 16px rgba(0, 0, 0, 0.15) !important;
}

.opacity-80 {
  opacity: 0.8;
}

@keyframes pulse-animation {
  0% {
    box-shadow: 0 0 0 0 rgba(239, 68, 68, 0.6);
  }

  70% {
    box-shadow: 0 0 0 8px rgba(239, 68, 68, 0);
  }

  100% {
    box-shadow: 0 0 0 0 rgba(239, 68, 68, 0);
  }
}

.pulse-animation {
  animation: pulse-animation 2s infinite;
}

@media (max-width: 960px) {
  .kanban-container {
    overflow-x: auto;
    padding-bottom: 20px;
  }
  
  .kanban-column {
    flex: 0 0 85vw;
    min-width: 85vw;
  }
}
</style>