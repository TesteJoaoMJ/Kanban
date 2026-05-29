<template>
  <div
    class="font-sans fill-height d-flex flex-column relative overflow-hidden"
    :class="
      themeStore?.currentMode === 'light'
        ? 'bg-grey-lighten-5 text-grey-darken-4'
        : 'bg-glass-dark text-white'
    "
  >
    <div
      v-if="themeStore?.currentMode !== 'light'"
      class="background-carousel-wrapper"
    >
      <div class="background-overlay"></div>
    </div>

    <div
      class="content-wrapper d-flex flex-column fill-height z-10 relative px-4 px-md-6 py-4"
    >
      <div class="d-flex justify-space-between align-center mb-6">
        <div class="d-flex flex-column">
          <div class="breadcrumb text-caption">
            <span class="opacity-70">MJ Process</span>
            <span class="mx-2 opacity-50">></span>
            <span class="font-weight-bold">Produção</span>
          </div>
          <div
            class="text-h6 font-weight-black tracking-tight leading-none mt-1"
            style="width: 200px"
            :class="
              themeStore.currentMode === 'light'
                ? 'text-grey-darken-4'
                : 'text-white'
            "
          >
            Kanban de Produção
          </div>
        </div>

        <div
          class="d-flex align-center flex-wrap"
          style="gap: 10px; justify-content: end"
        >
          <v-btn
            :color="
              themeStore.currentMode === 'light' ? 'grey-darken-3' : 'white'
            "
            variant="outlined"
            v-if="checkPermission('mfg_producao_cadastrar')"
            class="btn-3d px-4 font-weight-bold text-caption text-uppercase"
            height="40"
            append-icon="mdi-plus"
            @click="abrirModalCadastro"
          >
            Produção
            <v-tooltip activator="parent" location="top"
              >Começar nova coleção</v-tooltip
            >
          </v-btn>

          <v-menu
            :close-on-content-click="false"
            location="bottom end"
            max-width="320"
          >
            <template v-slot:activator="{ props }">
              <v-btn
                variant="outlined"
                class="btn-3d font-weight-bold px-0"
                height="40"
                min-width="40"
                width="40"
                v-bind="props"
              >
                <v-icon>mdi-cog</v-icon>
                <v-tooltip activator="parent" location="top"
                  >Personalizar aspecto e métricas</v-tooltip
                >
              </v-btn>
            </template>

            <v-card class="pa-4" :theme="themeStore?.currentMode">
              <div class="text-overline mb-2">Cores das Etapas</div>
              <v-list density="compact" class="pa-0 mb-4 bg-transparent">
                <v-list-item
                  v-for="coluna in colunas"
                  :key="coluna.id"
                  class="px-0"
                >
                  <template v-slot:title>
                    <span class="text-body-2">{{
                      formatarPecaEquivalente(coluna.titulo)
                    }}</span>
                  </template>
                  <template v-slot:append>
                    <v-menu :close-on-content-click="false" location="left">
                      <template v-slot:activator="{ props }">
                        <v-btn
                          v-bind="props"
                          icon
                          size="x-small"
                          elevation="2"
                          :style="{ backgroundColor: coluna.cor || '#3b82f6' }"
                        ></v-btn>
                      </template>
                      <v-card>
                        <v-color-picker
                          v-model="coluna.cor"
                          mode="hex"
                          hide-inputs
                          show-swatches
                          elevation="0"
                          @update:model-value="salvarConfiguracoes"
                        ></v-color-picker>
                      </v-card>
                    </v-menu>
                  </template>
                </v-list-item>
              </v-list>

              <v-divider class="mb-4"></v-divider>

              <div class="d-flex justify-space-between align-center mb-2">
                <div class="text-overline">Secção de KPIs</div>
                <v-switch
                  v-model="kpisVisiveis.secaoGeral"
                  color="primary"
                  hide-details
                  density="compact"
                  @change="salvarConfiguracoes"
                ></v-switch>
              </div>

              <v-expand-transition>
                <div v-if="kpisVisiveis.secaoGeral">
                  <v-switch
                    v-model="kpisVisiveis.totalModelos"
                    label="Total de modelos"
                    color="primary"
                    hide-details
                    density="compact"
                    @change="salvarConfiguracoes"
                  ></v-switch>
                  <v-switch
                    v-model="kpisVisiveis.entregasMes"
                    label="Entregas (Mês)"
                    color="primary"
                    hide-details
                    density="compact"
                    @change="salvarConfiguracoes"
                  ></v-switch>
                  <v-switch
                    v-model="kpisVisiveis.emCorte"
                    label="Em Corte"
                    color="primary"
                    hide-details
                    density="compact"
                    @change="salvarConfiguracoes"
                  ></v-switch>
                  <v-switch
                    v-model="kpisVisiveis.emCostura"
                    label="Em Costura"
                    color="primary"
                    hide-details
                    density="compact"
                    @change="salvarConfiguracoes"
                  ></v-switch>
                  <v-switch
                    v-model="kpisVisiveis.emAcabamento"
                    label="Em Acabamento"
                    color="primary"
                    hide-details
                    density="compact"
                    @change="salvarConfiguracoes"
                  ></v-switch>
                  <v-switch
                    v-model="kpisVisiveis.concluidos"
                    label="No Estoque"
                    color="primary"
                    hide-details
                    density="compact"
                    @change="salvarConfiguracoes"
                  ></v-switch>
                  <v-switch
                    v-model="kpisVisiveis.perigo"
                    label="Perigo"
                    color="primary"
                    hide-details
                    density="compact"
                    @change="salvarConfiguracoes"
                  ></v-switch>
                </div>
              </v-expand-transition>
            </v-card>
          </v-menu>
        </div>
      </div>

      <v-row
        v-if="!carregando && kpisVisiveis.secaoGeral"
        class="mb-3 w-auto justify-center flex-grow-0"
        dense
      >
        <v-col
          v-for="kpi in kpiList"
          :key="kpi.id"
          cols="12"
          sm="6"
          md="4"
          lg
          class="px-1"
        >
          <v-card
            :class="['kpi-card', kpi.color, 'hover-elevate', 'py-2', 'px-3']"
            v-ripple
            elevation="2"
          >
            <div class="kpi-bg-icon">
              <v-icon>{{ kpi.icon }}</v-icon>
            </div>
            <div
              class="d-flex flex-column position-relative z-10 justify-space-between fill-height"
            >
              <div class="d-flex align-center gap-1 overflow-hidden">
                <v-icon size="16" class="opacity-80 flex-shrink-0">{{
                  kpi.icon
                }}</v-icon>
                <span class="kpi-label text-truncate">{{ kpi.label }}</span>
              </div>
              <div class="kpi-number-group my-0">
                <span class="kpi-value">{{ kpi.value }}</span>
                <span
                  v-if="kpi.unit"
                  class="text-caption ml-1 font-weight-bold opacity-80"
                  >{{ kpi.unit }}</span
                >
              </div>
              <div class="kpi-footer mt-0 text-truncate">{{ kpi.footer }}</div>
            </div>
          </v-card>
        </v-col>
      </v-row>

      <div v-if="!carregando" class="d-flex flex-column gap-4 pb-4 border-b">
        <div
          class="d-flex flex-column flex-md-row gap-3 mb-3 justify-space-between w-100"
        >
          <v-text-field
            v-model="termoBusca"
            prepend-inner-icon="mdi-magnify"
            placeholder="Buscar por nome, cód. tecido ou estampa..."
            variant="outlined"
            density="compact"
            hide-details
            clearable
            class="flex-grow-1 w-100"
            style="max-width: 100%"
          >
            <v-tooltip activator="parent" location="top"
              >Pressione ESC para limpar</v-tooltip
            >
          </v-text-field>

          <v-btn
            :color="
              themeStore.currentMode === 'light' ? 'grey-darken-3' : 'white'
            "
            variant="outlined"
            class="btn-3d px-4 font-weight-bold text-caption text-uppercase"
            height="40"
            @click="mostrarModalFeed = true"
            append-icon="mdi mdi-calendar-blank-multiple"
          >
            Histórico
            <v-tooltip activator="parent" location="top"
              >Ver histórico de etapas</v-tooltip
            >
          </v-btn>

          <v-menu location="bottom end">
            <template v-slot:activator="{ props }">
              <v-btn
                variant="outlined"
                class="btn-3d font-weight-bold px-0 justify-content-end"
                height="40"
                min-width="40"
                rounded="md"
                v-bind="props"
              >
                <v-icon>mdi-filter-cog-outline</v-icon>
                <v-tooltip activator="parent" location="top"
                  >Filtrar Etapas</v-tooltip
                >
              </v-btn>
            </template>

            <v-card
              :theme="themeStore?.currentMode"
              min-width="220"
              class="pa-2"
            >
              <div
                class="text-caption text-medium-emphasis mb-2 px-2 font-weight-bold text-uppercase"
              >
                Filtrar por Coluna
              </div>

              <v-list density="compact" nav class="pa-0">
                <v-list-item
                  value="todos"
                  :active="filtro === 'todos'"
                  @click="filtro = 'todos'"
                  color="primary"
                  rounded="lg"
                  class="mb-1"
                >
                  <v-list-item-title>Todos os lotes</v-list-item-title>
                </v-list-item>

                <v-list-item
                  v-for="col in colunas"
                  :key="col.id"
                  :value="col.id"
                  :active="filtro === col.id"
                  @click="filtro = col.id"
                  :color="col.cor || 'primary'"
                  rounded="lg"
                  class="mb-1"
                >
                  <v-list-item-title>{{ col.titulo }}</v-list-item-title>
                </v-list-item>
              </v-list>
            </v-card>
          </v-menu>
        </div>
      </div>

      <div
        v-if="carregando"
        class="d-flex fill-height align-center justify-center mt-10"
      >
        <v-progress-circular
          indeterminate
          color="primary"
          size="64"
          width="6"
        ></v-progress-circular>
      </div>

      <div
        v-else
        class="kanban-container d-flex align-start gap-4 overflow-x-auto pb-4 w-100"
      >
        <div
          v-for="coluna in colunasFiltradas"
          :key="coluna.id"
          class="kanban-column rounded-lg pa-4 d-flex flex-column gap-3"
          :class="
            themeStore?.currentMode === 'light'
              ? 'bg-white border-grey-lighten-2 shadow-sm'
              : 'bg-glass-header border-bottom-white-05'
          "
          :style="{ borderTop: `4px solid ${coluna.cor}` }"
          @dragover.prevent
          @drop="onDrop($event, coluna.id)"
        >
          <div
            class="column-header d-flex justify-space-between align-center px-1 pb-2"
          >
            <span class="font-weight-bold text-subtitle-1">{{
              coluna.titulo
            }}</span>
            <v-chip
              :color="coluna.cor"
              variant="tonal"
              size="small"
              class="font-weight-bold"
            >
              {{ coluna.pecas.length }}
            </v-chip>
          </div>

          <div class="column-content">
            <v-card
              v-for="peca in coluna.pecas"
              :key="peca.id"
              class="mb-3 transition-swing"
              :class="{
                'is-draggable': checkPermission('mfg_producao_arrastar'),
                'hover-elevate': checkPermission('mfg_producao_arrastar'),
              }"
              :style="{
                borderLeft: getStatusPrazo(peca)?.pulsa
                  ? '4px solid rgb(var(--v-theme-error))'
                  : `4px solid ${coluna.cor}`,
              }"
              :draggable="checkPermission('mfg_producao_arrastar')"
              @dragstart="onDragStart($event, peca, coluna.id)"
              @click="peca.expanded = !peca.expanded"
              hover
            >
              <v-card-item class="pb-2 pt-3 px-3">
                <div class="d-flex justify-space-between align-start mb-2">
                  <div
                    class="text-caption text-medium-emphasis d-flex flex-column"
                  >
                    <span>Criado por: {{ peca.autor || "Desconhecido" }}</span>
                    <span>{{ getTempoDecorrido(peca) }}</span>
                  </div>

                  <div
                    v-if="checkPermission('mfg_colecao_arrastar')"
                    class="d-flex gap-1 align-center"
                  >
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
                        <v-list-subheader class="text-caption font-weight-bold"
                          >Mover para:</v-list-subheader
                        >
                        <v-list-item
                          v-for="colDestino in colunas.filter(
                            (c) => c.id !== coluna.id,
                          )"
                          :key="colDestino.id"
                          @click.stop="
                            prepararMovimentacao(peca, coluna.id, colDestino.id)
                          "
                        >
                          <v-list-item-title class="text-caption">{{
                            colDestino.titulo
                          }}</v-list-item-title>
                        </v-list-item>
                      </v-list>
                    </v-menu>

                    <v-btn
                      icon
                      size="x-small"
                      variant="text"
                      color="green"
                      v-if="!peca.faturado && peca.tipo_externo === 1"
                      @click.stop="abrirModalPagamento(peca)"
                    >
                      <v-icon>mdi mdi-cash-clock</v-icon>
                      <v-tooltip activator="parent" location="top"
                        >Faturar</v-tooltip
                      >
                    </v-btn>

                    <v-btn
                      icon
                      size="x-small"
                      variant="text"
                      color="medium-emphasis"
                      v-if="checkPermission('mfg_colecao_editar')"
                      @click.stop="abrirModalEdicao(peca)"
                    >
                      <v-icon>mdi-pencil-outline</v-icon>
                      <v-tooltip activator="parent" location="top"
                        >Editar modelo</v-tooltip
                      >
                    </v-btn>

                    <v-btn
                      icon
                      size="x-small"
                      variant="text"
                      color="error"
                      @click.stop="removeritem(peca)"
                      v-if="checkPermission('mfg_colecao_excluir')"
                    >
                      <v-icon>mdi-trash-can-outline</v-icon>
                      <v-tooltip activator="parent" location="top"
                        >Excluir modelo</v-tooltip
                      >
                    </v-btn>
                  </div>
                </div>

                <v-card-title
                  class="text-subtitle-1 font-weight-bold pa-0 mb-1"
                  style="white-space: normal; line-height: 1.2"
                >
                  {{ peca.nome }}
                </v-card-title>

                <div
                  class="d-flex align-center gap-2 mb-2 flex-wrap"
                  v-if="getStatusPrazo(peca)"
                >
                  <v-chip
                    :color="getStatusPrazo(peca)?.color"
                    size="x-small"
                    class="font-weight-bold text-uppercase"
                    :class="{ 'pulse-animation': getStatusPrazo(peca)?.pulsa }"
                  >
                    {{ getStatusPrazo(peca)?.texto }}
                  </v-chip>
                </div>

                <div class="text-caption d-flex flex-column gap-1 mb-2">
                  <div>
                    <span class="text-medium-emphasis font-weight-medium"
                      >Tecido:</span
                    >
                    {{ peca.tecido_nome || peca.tecido_id || "-" }}
                  </div>
                  <div>
                    <span class="text-medium-emphasis font-weight-medium"
                      >Estampa:</span
                    >
                    {{ peca.estampa_nome || peca.estampa_id || "Sem estampa" }}
                  </div>
                  <div>
                    <span class="text-medium-emphasis font-weight-medium"
                      >Produto:</span
                    >
                    {{
                      formatarPecaEquivalente(
                        peca.produto_nome ||
                          String(peca.produto_id || "Não vinculado"),
                      )
                    }}
                  </div>
                </div>
              </v-card-item>

              <div class="text-center pb-1">
                <v-icon
                  color="medium-emphasis"
                  size="small"
                  :style="{
                    transform: peca.expanded ? 'rotate(180deg)' : 'none',
                    transition: 'transform 0.3s ease',
                  }"
                >
                  mdi-chevron-down
                </v-icon>
              </div>

              <v-expand-transition>
                <div v-if="peca.expanded" @click.stop>
                  <v-divider></v-divider>
                  <v-card-text
                    class="text-caption px-3 py-2 bg-grey-lighten-4 dark:bg-grey-darken-4"
                  >
                    <v-row dense>
                      <v-col cols="6"
                        ><strong>Quantidade:</strong> <br />{{
                          peca.quantidade || 0
                        }}
                        un.</v-col
                      >
                      <v-col cols="6"
                        ><strong>Entrega:</strong> <br />{{
                          formatarData(peca.data_entrega)
                        }}</v-col
                      >
                      <v-col cols="12" v-if="peca.descricao">
                        <span class="text-medium-emphasis">{{
                          peca.descricao
                        }}</span>
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

    <v-dialog
      v-model="mostrarModalFeed"
      max-width="900"
      scrollable
      @after-leave="fecharModalTimeline"
    >
      <v-card :theme="themeStore?.currentMode" rounded="lg">
        <v-fade-transition mode="out-in">
          <div v-if="!pecaSelecionada" key="lista" class="d-flex flex-column fill-height">
            <v-card-title
              class="d-flex justify-space-between align-center px-5 pt-5 pb-3 bg-grey-lighten-4 dark:bg-grey-darken-4"
            >
              <div>
                <div class="text-h6 font-weight-bold">Selecione um Lote</div>
                <div class="text-caption text-medium-emphasis">
                  Acompanhe o histórico de movimentação das peças.
                </div>
              </div>
              <v-btn
                icon="mdi-close"
                variant="text"
                density="comfortable"
                @click="mostrarModalFeed = false"
              ></v-btn>
            </v-card-title>

            <v-divider></v-divider>

            <div
              class="px-4 py-3 bg-grey-lighten-5 dark:bg-grey-darken-3 border-b"
            >
              <v-btn-toggle
                v-model="filtroTimeline"
                mandatory
                color="primary"
                variant="outlined"
                density="compact"
                class="w-100 d-flex rounded-lg overflow-hidden"
              >
                <v-btn value="atuais" class="flex-grow-1 text-caption"
                  >Atuais</v-btn
                >
                <v-btn value="sistema" class="flex-grow-1 text-caption"
                  >Sistema (Fábrica)</v-btn
                >
                <v-btn value="loja" class="flex-grow-1 text-caption"
                  >Loja (PDV)</v-btn
                >
              </v-btn-toggle>
            </div>

            <v-card-text class="pa-0" style="max-height: 65vh">
              <v-list
                v-if="pecasFiltradasTimeline.length > 0"
                lines="two"
                class="bg-transparent pa-2"
              >
                <v-list-item
                  v-for="peca in pecasFiltradasTimeline"
                  :key="peca.id"
                  @click="abrirHistoricoDetalhado(peca)"
                  class="rounded-lg mb-1"
                  link
                >
                  <template v-slot:title>
                    <span class="font-weight-bold">{{ peca.nome }}</span>
                  </template>

                  <template v-slot:subtitle>
                    <div class="d-flex align-center gap-2 mt-1">
                      <span class="d-flex align-center"
                        ><v-icon size="x-small" class="mr-1"
                          >mdi-package-variant</v-icon
                        >
                        {{ peca.quantidade }} un.</span
                      >
                      <span class="d-flex align-center"
                        ><v-icon size="x-small" class="mr-1"
                          >mdi-calendar-clock</v-icon
                        >
                        {{ formatarData(peca.data_entrega) }}</span
                      >
                    </div>
                  </template>

                  <template v-slot:append>
                    <div class="d-flex align-center">
                      <v-chip
                        size="small"
                        :color="getColunaCor(peca.status)"
                        variant="flat"
                        class="font-weight-medium"
                      >
                        {{
                          peca.status === "estoque"
                            ? "Finalizado"
                            : getColunaTitulo(peca.status)
                        }}
                      </v-chip>
                    </div>
                  </template>
                </v-list-item>
              </v-list>

              <div
                v-else
                class="d-flex flex-column align-center justify-center pa-10 text-center text-medium-emphasis"
              >
                <v-icon size="large" color="grey-lighten-1" class="mb-3"
                  >mdi-inbox-remove</v-icon
                >
                <div class="text-subtitle-1 font-weight-medium">
                  Nenhum lote encontrado
                </div>
                <div class="text-caption">
                  Não há produções para este filtro.
                </div>
              </div>
            </v-card-text>
          </div>

          <div v-else key="detalhes" class="d-flex flex-column fill-height">
            <v-card-title
              class="d-flex justify-space-between align-center px-5 pt-4 pb-3"
              :class="
                themeStore?.currentMode === 'light'
                  ? 'bg-grey-lighten-4'
                  : 'bg-grey-darken-4'
              "
            >
              <div class="d-flex align-center gap-3">
                <v-avatar color="primary" variant="tonal" rounded="lg">
                  <v-icon>mdi-factory</v-icon>
                </v-avatar>
                <div>
                  <div class="text-h6 font-weight-bold lh-normal">
                    {{ detalhesPecaDB?.nome || pecaSelecionada?.nome }}
                  </div>
                  <div class="text-caption text-medium-emphasis">
                    Dossiê de produção e mapeamento de operadores
                  </div>
                </div>
              </div>
              <v-btn
                icon="mdi-close"
                variant="text"
                density="comfortable"
                @click="pecaSelecionada = null"
              ></v-btn>
            </v-card-title>
            <v-divider></v-divider>

            <v-card-text class="pa-5 overflow-hidden">
              <div
                v-if="carregandoHistorico"
                class="d-flex flex-column align-center justify-center py-10"
              >
                <v-progress-circular
                  indeterminate
                  color="primary"
                  size="40"
                ></v-progress-circular>
                <span class="text-caption mt-3 text-medium-emphasis"
                  >Mapeando linha de produção...</span
                >
              </div>
              <v-row v-else dense class="align-stretch">
                <v-col cols="12" md="6" class="pr-md-2 h-100">
                  <div
                    class="text-caption font-weight-black text-uppercase mb-2 opacity-70 tracking-widest"
                  >
                    <v-icon size="small" class="mr-1"
                      >mdi-information-outline</v-icon
                    >
                    Dados do Lote
                  </div>
                  <v-card
                    variant="outlined"
                    class="pa-4 rounded-lg overflow-y-auto custom-scroll"
                    style="height: 55vh"
                    :class="
                      themeStore?.currentMode === 'light'
                        ? 'bg-grey-lighten-5 border-grey-lighten-2'
                        : 'bg-grey-darken-4 border-white-05'
                    "
                  >
                    <div class="d-flex flex-column gap-3 text-body-2">
                      <div
                        class="d-flex justify-space-between align-center border-b pb-2"
                        :class="
                          themeStore?.currentMode === 'light'
                            ? 'border-grey-lighten-3'
                            : 'border-white-05'
                        "
                      >
                        <strong class="opacity-70">Status Atual:</strong>
                        <v-chip
                          size="small"
                          :color="
                            detalhesPecaDB?.status === 'estoque'
                              ? 'success'
                              : getColunaCor(detalhesPecaDB?.status)
                          "
                          variant="flat"
                          class="font-weight-bold"
                        >
                          {{
                            detalhesPecaDB?.status === "estoque"
                              ? "No Estoque"
                              : getColunaTitulo(detalhesPecaDB?.status)
                          }}
                        </v-chip>
                      </div>
                      <div class="d-flex justify-space-between">
                        <strong class="opacity-70">Responsável Inicial:</strong>
                        <span class="font-weight-medium text-right">{{
                          detalhesPecaDB?.autor || "N/A"
                        }}</span>
                      </div>
                      <div class="d-flex justify-space-between">
                        <strong class="opacity-70">Previsão de Entrega:</strong>
                        <span class="font-weight-medium"
                          ><v-icon size="x-small" class="mr-1"
                            >mdi-calendar</v-icon
                          >{{
                            formatarData(detalhesPecaDB?.data_entrega)
                          }}</span
                        >
                      </div>
                      <div class="d-flex justify-space-between">
                        <strong class="opacity-70">Total de Peças:</strong>
                        <span class="font-weight-medium"
                          >{{ detalhesPecaDB?.quantidade || 0 }} un.</span
                        >
                      </div>
                      <div class="d-flex justify-space-between">
                        <strong class="opacity-70">Produto Fabricado:</strong>
                        <span class="font-weight-medium text-right">{{
                          detalhesPecaDB?.produto_nome || "Não vinculado"
                        }}</span>
                      </div>
                      <div class="d-flex justify-space-between">
                        <strong class="opacity-70">Tecido:</strong>
                        <span class="font-weight-medium text-right">{{
                          detalhesPecaDB?.tecido_nome ||
                          detalhesPecaDB?.tecido_id ||
                          "N/A"
                        }}</span>
                      </div>
                      <div class="d-flex justify-space-between">
                        <strong class="opacity-70">Estampa:</strong>
                        <span class="font-weight-medium text-right">{{
                          detalhesPecaDB?.estampa_nome ||
                          detalhesPecaDB?.estampa_id ||
                          "N/A"
                        }}</span>
                      </div>

                      <v-divider
                        class="my-2"
                        :class="
                          themeStore?.currentMode === 'light'
                            ? 'border-grey-lighten-3'
                            : 'border-white-05'
                        "
                      ></v-divider>
                      <div
                        class="text-caption font-weight-black text-uppercase text-primary tracking-widest mb-1"
                      >
                        Informações de Manufatura
                      </div>

                      <div class="d-flex justify-space-between">
                        <strong class="opacity-70">Operador Corte:</strong>
                        <span class="font-weight-medium text-right">{{
                          detalhesPecaDB?.tipo_corte === "interna"
                            ? getNomeOperador(detalhesPecaDB?.operador_corte_id)
                            : detalhesPecaDB?.tipo_corte
                              ? "Serviço Externo"
                              : "N/A"
                        }}</span>
                      </div>
                      <div class="d-flex justify-space-between">
                        <strong class="opacity-70">Máquina Corte:</strong>
                        <span class="font-weight-medium text-right">{{
                          detalhesPecaDB?.tipo_corte === "interna"
                            ? getNomeMaquina(detalhesPecaDB?.maquina_corte_id)
                            : detalhesPecaDB?.tipo_corte
                              ? "Serviço Externo"
                              : "N/A"
                        }}</span>
                      </div>

                      <v-divider
                        class="my-1 border-dashed opacity-20"
                      ></v-divider>

                      <div class="d-flex justify-space-between">
                        <strong class="opacity-70">Operador Costura:</strong>
                        <span class="font-weight-medium text-right">{{
                          detalhesPecaDB?.tipo_costura === "interna"
                            ? getNomeOperador(
                                detalhesPecaDB?.operador_costura_id,
                              )
                            : detalhesPecaDB?.tipo_costura
                              ? "Serviço Externo"
                              : "N/A"
                        }}</span>
                      </div>
                      <div class="d-flex justify-space-between">
                        <strong class="opacity-70">Máquina Costura:</strong>
                        <span class="font-weight-medium text-right">{{
                          detalhesPecaDB?.tipo_costura === "interna"
                            ? getNomeMaquina(detalhesPecaDB?.maquina_costura_id)
                            : detalhesPecaDB?.tipo_costura
                              ? "Serviço Externo"
                              : "N/A"
                        }}</span>
                      </div>

                      <v-divider
                        class="my-1 border-dashed opacity-20"
                      ></v-divider>

                      <div class="d-flex justify-space-between">
                        <strong class="opacity-70">Operador Acabamento:</strong>
                        <span class="font-weight-medium text-right">{{
                          detalhesPecaDB?.tipo_acabamento === "interna"
                            ? getNomeOperador(
                                detalhesPecaDB?.operador_acabamento_id,
                              )
                            : detalhesPecaDB?.tipo_acabamento
                              ? "Serviço Externo"
                              : "N/A"
                        }}</span>
                      </div>
                      <div class="d-flex justify-space-between">
                        <strong class="opacity-70">Máquina Acabamento:</strong>
                        <span class="font-weight-medium text-right">{{
                          detalhesPecaDB?.tipo_acabamento === "interna"
                            ? getNomeMaquina(
                                detalhesPecaDB?.maquina_acabamento_id,
                              )
                            : detalhesPecaDB?.tipo_acabamento
                              ? "Serviço Externo"
                              : "N/A"
                        }}</span>
                      </div>

                      <v-row dense class="mt-2">
                        <v-col cols="12" v-if="detalhesPecaDB?.tipo_corte">
                          <div
                            class="pa-2 rounded border"
                            :class="
                              themeStore?.currentMode === 'light'
                                ? 'bg-white border-grey-lighten-3'
                                : 'bg-grey-darken-3 border-white-05'
                            "
                          >
                            <div class="d-flex align-center gap-2 mb-1">
                              <v-icon size="small" color="pink"
                                >mdi-scissors-cutting</v-icon
                              >
                              <strong class="text-caption text-uppercase"
                                >Corte ({{ detalhesPecaDB.tipo_corte }})</strong
                              >
                            </div>
                            <div
                              v-if="detalhesPecaDB.tipo_corte === 'interna'"
                              class="text-caption d-flex flex-column gap-1 ml-6"
                            >
                              <div>
                                <span class="opacity-70">Operador:</span>
                                <strong>{{
                                  getNomeOperador(
                                    detalhesPecaDB.operador_corte_id,
                                  )
                                }}</strong>
                              </div>
                              <div>
                                <span class="opacity-70">Máquina:</span>
                                <strong>{{
                                  getNomeMaquina(
                                    detalhesPecaDB.maquina_corte_id,
                                  )
                                }}</strong>
                              </div>
                            </div>
                          </div>
                        </v-col>

                        <v-col cols="12" v-if="detalhesPecaDB?.tipo_costura">
                          <div
                            class="pa-2 rounded border"
                            :class="
                              themeStore?.currentMode === 'light'
                                ? 'bg-white border-grey-lighten-3'
                                : 'bg-grey-darken-3 border-white-05'
                            "
                          >
                            <div class="d-flex align-center gap-2 mb-1">
                              <v-icon size="small" color="orange"
                                >mdi-needle</v-icon
                              >
                              <strong class="text-caption text-uppercase"
                                >Costura ({{
                                  detalhesPecaDB.tipo_costura
                                }})</strong
                              >
                            </div>
                            <div
                              v-if="detalhesPecaDB.tipo_costura === 'interna'"
                              class="text-caption d-flex flex-column gap-1 ml-6"
                            >
                              <div>
                                <span class="opacity-70">Operador:</span>
                                <strong>{{
                                  getNomeOperador(
                                    detalhesPecaDB.operador_costura_id,
                                  )
                                }}</strong>
                              </div>
                              <div>
                                <span class="opacity-70">Máquina:</span>
                                <strong>{{
                                  getNomeMaquina(
                                    detalhesPecaDB.maquina_costura_id,
                                  )
                                }}</strong>
                              </div>
                            </div>
                          </div>
                        </v-col>

                        <v-col cols="12" v-if="detalhesPecaDB?.tipo_acabamento">
                          <div
                            class="pa-2 rounded border"
                            :class="
                              themeStore?.currentMode === 'light'
                                ? 'bg-white border-grey-lighten-3'
                                : 'bg-grey-darken-3 border-white-05'
                            "
                          >
                            <div class="d-flex align-center gap-2 mb-1">
                              <v-icon size="small" color="green"
                                >mdi-tshirt-crew</v-icon
                              >
                              <strong class="text-caption text-uppercase"
                                >Acabamento ({{
                                  detalhesPecaDB.tipo_acabamento
                                }})</strong
                              >
                            </div>
                            <div
                              v-if="
                                detalhesPecaDB.tipo_acabamento === 'interna'
                              "
                              class="text-caption d-flex flex-column gap-1 ml-6"
                            >
                              <div>
                                <span class="opacity-70">Operador:</span>
                                <strong>{{
                                  getNomeOperador(
                                    detalhesPecaDB.operador_acabamento_id,
                                  )
                                }}</strong>
                              </div>
                              <div>
                                <span class="opacity-70">Máquina:</span>
                                <strong>{{
                                  getNomeMaquina(
                                    detalhesPecaDB.maquina_acabamento_id,
                                  )
                                }}</strong>
                              </div>
                            </div>
                          </div>
                        </v-col>
                      </v-row>

                      <div v-if="detalhesPecaDB?.descricao" class="mt-2">
                        <strong class="opacity-70 d-block mb-1 text-caption"
                          >Instruções Técnicas da Manufatura:</strong
                        >
                        <div
                          class="pa-3 rounded border text-caption"
                          :class="
                            themeStore?.currentMode === 'light'
                              ? 'bg-white border-grey-lighten-3'
                              : 'bg-grey-darken-3 border-white-05'
                          "
                        >
                          {{ detalhesPecaDB?.descricao }}
                        </div>
                      </div>
                    </div>
                  </v-card>
                </v-col>

                <v-col cols="12" md="6" class="pl-md-2 mt-4 mt-md-0 h-100">
                  <div
                    class="text-caption font-weight-black text-uppercase mb-2 opacity-70 tracking-widest"
                  >
                    <v-icon size="small" class="mr-1"
                      >mdi-timeline-clock-outline</v-icon
                    >
                    Histórico e Tempos
                  </div>
                  <v-card
                    variant="outlined"
                    class="pa-4 rounded-lg overflow-y-auto custom-scroll"
                    style="height: 55vh"
                    :class="
                      themeStore?.currentMode === 'light'
                        ? 'bg-grey-lighten-5 border-grey-lighten-2'
                        : 'bg-grey-darken-4 border-white-05'
                    "
                  >
                    <v-timeline
                      density="compact"
                      side="end"
                      align="start"
                      truncate-line="both"
                    >
                      <v-timeline-item
                        v-for="etapa in etapasVisiveis"
                        :key="etapa.id"
                        :dot-color="etapa.dataSaida ? 'success' : 'primary'"
                        :icon="
                          etapa.dataSaida ? 'mdi-check' : 'mdi-circle-medium'
                        "
                        size="small"
                      >
                        <div class="mb-3">
                          <div
                            class="font-weight-bold text-body-2 d-flex align-center justify-space-between"
                          >
                            {{ etapa.titulo }}
                          </div>
                          <div
                            class="text-caption text-medium-emphasis mt-1 d-flex flex-column gap-1"
                          >
                            <div class="d-flex align-center">
                              <v-icon size="x-small" class="mr-1"
                                >mdi-login</v-icon
                              >
                              Entrada: {{ etapa.dataEntrada }}
                            </div>
                            <div
                              class="d-flex align-center"
                              v-if="etapa.dataSaida"
                            >
                              <v-icon size="x-small" class="mr-1 text-success"
                                >mdi-logout</v-icon
                              >
                              Saída: {{ etapa.dataSaida }}
                            </div>
                          </div>
                        </div>
                      </v-timeline-item>
                    </v-timeline>
                    <div
                      v-if="etapasVisiveis.length === 0"
                      class="text-caption text-center opacity-60 py-8 d-flex flex-column align-center"
                    >
                      <v-icon size="large" class="mb-2">mdi-history</v-icon>
                      Nenhum histórico registrado ainda.
                    </div>
                  </v-card>
                </v-col>
              </v-row>
            </v-card-text>

            <v-card-actions
              class="pa-4 border-t d-flex justify-space-between align-center"
              :class="
                themeStore?.currentMode === 'light'
                  ? 'bg-grey-lighten-4'
                  : 'bg-grey-darken-4'
              "
            >
              <div></div>

              <div class="d-flex gap-3 align-center">
                <v-btn
                  variant="tonal"
                  class="px-5 font-weight-bold text-none"
                  @click="pecaSelecionada = null"
                >
                  Voltar
                </v-btn>

                <v-btn
                  color="info"
                  variant="flat"
                  class="px-5 font-weight-bold text-none"
                  prepend-icon="mdi-download"
                  v-if="linkComprovanteExterno"
                  @click="baixarPDFExternoURL(linkComprovanteExterno)"
                >
                  Baixar OS
                </v-btn>

                <v-btn
                  color="error"
                  variant="flat"
                  class="px-5 font-weight-bold text-none"
                  prepend-icon="mdi-file-pdf-box"
                  v-if="etapaPDV"
                  @click="baixarPDF(etapaPDV.id)"
                >
                  Envio pra loja
                </v-btn>
              </div>
            </v-card-actions>
          </div>
        </v-fade-transition>
      </v-card>
    </v-dialog>

    <v-dialog v-model="exibirModalPerigo" max-width="500" persistent>
      <v-card :theme="themeStore?.currentMode">
        <v-card-title
          class="text-error font-weight-bold d-flex align-center gap-2"
        >
          <v-icon color="error">mdi-alert-circle</v-icon> Atenção na Validade!
        </v-card-title>
        <v-card-text>
          <p class="mb-4">
            Os seguintes lotes estão com entrega para hoje ou já estão
            atrasados:
          </p>
          <v-list
            v-if="pecasEmPerigo.length > 0"
            lines="two"
            bg-color="transparent"
            class="pa-0"
          >
            <v-list-item
              v-for="peca in pecasEmPerigo"
              :key="peca.id"
              class="border rounded mb-2 pa-2 border-error-lighten-1"
            >
              <template v-slot:title>
                <div class="d-flex justify-space-between align-center">
                  <span class="font-weight-bold">{{ peca.nome }}</span>
                  <v-chip color="error" size="x-small" variant="flat">{{
                    formatarData(peca.data_entrega)
                  }}</v-chip>
                </div>
              </template>
              <template v-slot:subtitle>
                <div class="d-flex align-center gap-2 mt-1">
                  <v-chip size="x-small" variant="tonal">{{
                    getTituloColuna(peca.status || "")
                  }}</v-chip>
                  <span>Qtd: {{ peca.quantidade }} un.</span>
                </div>
              </template>
            </v-list-item>
          </v-list>
          <div v-else class="text-center text-muted py-4">
            Nenhuma peça em atraso no momento.
          </div>
        </v-card-text>
        <v-card-actions class="pa-4 pt-0">
          <v-spacer></v-spacer>
          <v-btn color="error" variant="flat" @click="exibirModalPerigo = false"
            >Estou Ciente</v-btn
          >
        </v-card-actions>
      </v-card>
    </v-dialog>

    <v-dialog v-model="exibirModalPagamento" max-width="500" persistent>
      <v-card :theme="themeStore?.currentMode">
        <v-card-title class="font-weight-bold"
          >Lançar Contas a Pagar (Serviço Externo)</v-card-title
        >
        <v-card-text class="py-2">
          <p class="mb-4">
            Lote:
            <strong class="text-primary">{{ pecaPagamento?.nome }}</strong>
          </p>
          <v-row dense>
            <v-col cols="12">
              <v-text-field
                v-model="dadosPagamento.descricao"
                label="Descrição da Despesa"
                placeholder="Ex: Pagamento Serviço Terceirizado"
                variant="outlined"
                density="comfortable"
              />
            </v-col>
            <v-col cols="12" sm="6">
              <v-text-field
                v-model="dadosPagamento.valor"
                type="number"
                label="Valor Cobrado (R$)"
                placeholder="0.00"
                prefix="R$"
                variant="outlined"
                density="comfortable"
              />
            </v-col>
            <v-col cols="12" sm="6">
              <v-text-field
                v-model="dadosPagamento.data_vencimento"
                type="date"
                label="Data de Vencimento"
                variant="outlined"
                density="comfortable"
              />
            </v-col>
            <v-col cols="12" sm="6">
              <v-select
                v-model="dadosPagamento.conta"
                :items="listaContasBancarias"
                item-title="bank_name"
                item-value="id"
                label="Contas Bancarias *"
                variant="outlined"
                density="comfortable"
                required
              />
            </v-col>
            <v-col cols="12" sm="6">
              <v-select
                v-model="dadosPagamento.categoria"
                :items="listaPlanoContas"
                item-title="name"
                item-value="id"
                label="Plano de contas *"
                variant="outlined"
                density="comfortable"
                required
              />
            </v-col>
            <v-col cols="12">
              <v-select
                v-model="dadosPagamento.beneficiario"
                :items="listaBeneficiarios"
                item-title="nome"
                item-value="id"
                label="Beneficiário *"
                variant="outlined"
                density="comfortable"
                required
              />
            </v-col>
          </v-row>
        </v-card-text>
        <v-card-actions class="pa-4">
          <v-spacer></v-spacer>
          <v-btn
            variant="text"
            @click="exibirModalPagamento = false"
            :disabled="salvando"
            >Cancelar</v-btn
          >
          <v-btn
            color="success"
            variant="flat"
            @click="confirmarPagamentoFaccao"
            :loading="salvando"
            >Lançar no Financeiro</v-btn
          >
        </v-card-actions>
      </v-card>
    </v-dialog>

    <v-dialog v-model="exibirModalExclusao" max-width="450" persistent>
      <v-card :theme="themeStore?.currentMode">
        <v-card-title class="text-error font-weight-bold"
          ><v-icon left color="error">mdi-alert</v-icon> Deseja excluir a
          coleção?</v-card-title
        >
        <v-card-text
          >Você está prestes a excluir: <strong>{{ pecaEmExclusaoNome }}</strong
          >.<br />Essa ação não terá volta.</v-card-text
        >
        <v-card-actions class="pa-4">
          <v-spacer></v-spacer>
          <v-btn
            variant="text"
            @click="exibirModalExclusao = false"
            :disabled="salvando"
            >Cancelar</v-btn
          >
          <v-btn
            color="error"
            variant="flat"
            @click="ExcluirItem"
            :loading="salvando"
            >Excluir</v-btn
          >
        </v-card-actions>
      </v-card>
    </v-dialog>

    <v-dialog v-model="exibirModalCadastro" max-width="600" persistent>
      <v-card :theme="themeStore?.currentMode">
        <v-card-title class="font-weight-bold pa-4 pb-2">
          {{ modoEdicao ? "Editar Lote" : "Novo Lote" }}
        </v-card-title>
        <v-card-text class="px-4 py-2">
          <v-row dense>
            <v-col cols="12">
              <v-text-field
                v-model="novaPeca.nome"
                label="Nome do modelo"
                placeholder="Ex: Blusa Manga Longa"
                required
                :rules="[(v) => !!v || 'Campo obrigatório']"
                variant="outlined"
                density="comfortable"
              />
            </v-col>
            <v-col cols="12" sm="6">
              <v-text-field
                v-model="novaPeca.quantidade"
                type="number"
                label="Quantidade"
                placeholder="100"
                required
                :rules="[(v) => !!v || 'Campo obrigatório']"
                variant="outlined"
                density="comfortable"
              />
            </v-col>
            <v-col cols="12" sm="6">
              <v-text-field
                v-model="novaPeca.data_entrega"
                type="date"
                label="Data de entrega"
                required
                :rules="[(v) => !!v || 'Campo obrigatório']"
                variant="outlined"
                density="comfortable"
              />
            </v-col>
            <v-col cols="12">
              <v-autocomplete
                v-model="novaPeca.produto"
                v-model:search="produtoSearchTerm"
                :items="produtosFiltrados"
                item-title="fabric_type"
                item-value="id"
                label="Produto Vinculado (Obrigatório)"
                placeholder="Digite o nome do produto..."
                variant="outlined"
                density="comfortable"
                @update:search="buscarProdutosAutocomplete()"
                @click="buscarProdutosAutocomplete()"
                return-object
                :hint="
                  novaPeca.produto
                    ? 'Produto vinculado!'
                    : 'Selecione um produto da lista.'
                "
                persistent-hint
                :error="!novaPeca.produto && produtoSearchTerm.length > 0"
              />
            </v-col>
            <v-col cols="12" sm="6">
              <v-select
                v-model="novaPeca.tecido_id"
                :items="listaTecidos"
                item-title="fabric_type"
                item-value="id"
                label="Tecido (Obrigatório)"
                variant="outlined"
                density="comfortable"
                required
              />
            </v-col>
            <v-col cols="12" sm="6">
              <v-select
                v-model="novaPeca.estampa_id"
                :items="listaEstampas"
                item-title="title"
                item-value="id"
                label="Estampa"
                placeholder="Sem estampa / Selecione..."
                variant="outlined"
                density="comfortable"
                clearable
              />
            </v-col>
            <v-col cols="12">
              <v-textarea
                v-model="novaPeca.descricao"
                label="Descrição"
                placeholder="Breve descrição/comentário da produção"
                rows="3"
                auto-grow
                variant="outlined"
                density="comfortable"
              />
            </v-col>
          </v-row>
        </v-card-text>
        <v-card-actions class="pa-4 pt-0">
          <v-spacer></v-spacer>
          <v-btn
            variant="text"
            @click="exibirModalCadastro = false"
            :disabled="salvando"
            >Cancelar</v-btn
          >
          <v-btn
            color="primary"
            variant="flat"
            @click="salvarproducao"
            :loading="salvando"
          >
            {{ modoEdicao ? "Salvar Alterações" : "Cadastrar" }}
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <v-dialog v-model="dialogMover" max-width="600" persistent>
      <v-card
        :theme="themeStore?.currentMode"
        v-if="ConfirmacaoPecaSelecionada"
      >
        <template v-if="colunaDestino === 'estoque'">
          <v-card-title class="font-weight-bold text-success"
            >Produção Finalizada! 🎉</v-card-title
          >
          <v-card-text>
            <p class="mb-4">
              O lote
              <strong class="text-primary">{{
                ConfirmacaoPecaSelecionada.nome
              }}</strong>
              ({{ ConfirmacaoPecaSelecionada.quantidade }} un.) está pronto.
              Para onde deseja enviar as peças?
            </p>

            <div
              class="pa-4 border rounded"
              :class="
                themeStore?.currentMode === 'light'
                  ? 'bg-grey-lighten-4'
                  : 'bg-grey-darken-3'
              "
            >
              <v-radio-group v-model="destinoEstoque" column color="primary">
                <v-radio
                  label="Enviar tudo para o Estoque da Fábrica"
                  value="sistema"
                ></v-radio>
                <v-radio
                  label="Enviar tudo para o Ponto de Loja"
                  value="pdv"
                ></v-radio>
                <v-radio
                  v-if="(ConfirmacaoPecaSelecionada.quantidade || 0) >= 2"
                  label="Dividir entre Fábrica e Loja"
                  value="ambos"
                ></v-radio>
              </v-radio-group>

              <v-expand-transition>
                <div
                  v-if="destinoEstoque === 'pdv' || destinoEstoque === 'ambos'"
                  class="mt-4 pt-4 border-t"
                >
                  <span class="font-weight-bold text-subtitle-2 mb-2 d-block"
                    >Qual Loja receberá a mercadoria?</span
                  >
                  <v-autocomplete
                    v-model="lojaDestinoSelecionada"
                    :items="listaLojas"
                    item-title="name"
                    item-value="id"
                    label="Selecione a Loja de Destino *"
                    variant="outlined"
                    density="compact"
                    hide-details
                  ></v-autocomplete>
                </div>
              </v-expand-transition>

              <v-expand-transition>
                <div
                  v-if="destinoEstoque === 'ambos'"
                  class="mt-4 pt-4 border-t"
                >
                  <v-row dense>
                    <v-col cols="6"
                      ><v-text-field
                        label="Qtd. Fábrica"
                        type="number"
                        v-model="qtdEstoqueSistema"
                        min="1"
                        variant="outlined"
                        density="compact"
                        @input="validarEstoqueDuplo($event, 'sistema')"
                    /></v-col>
                    <v-col cols="6"
                      ><v-text-field
                        label="Qtd. Loja"
                        type="number"
                        v-model="qtdEstoquePDV"
                        min="1"
                        variant="outlined"
                        density="compact"
                        @input="validarEstoqueDuplo($event, 'pdv')"
                    /></v-col>
                  </v-row>
                  <div
                    class="text-center text-caption mt-2"
                    :class="
                      totalDistribuido >
                      (ConfirmacaoPecaSelecionada.quantidade || 0)
                        ? 'text-error font-weight-bold'
                        : 'text-muted'
                    "
                  >
                    Distribuído: <strong>{{ totalDistribuido }}</strong> de
                    <strong>{{ ConfirmacaoPecaSelecionada.quantidade }}</strong>
                    un.
                  </div>
                </div>
              </v-expand-transition>
            </div>
          </v-card-text>
          <v-card-actions class="pa-4 pt-0">
            <v-spacer></v-spacer>
            <v-btn
              variant="text"
              @click="fecharModalMoverConfirmar"
              :disabled="salvando"
              >Cancelar</v-btn
            >
            <v-btn
              color="primary"
              variant="flat"
              @click="confirmarEnvioEstoqueFinal"
              :loading="salvando"
              >Confirmar Envio</v-btn
            >
          </v-card-actions>
        </template>

        <template v-else>
          <v-card-title class="font-weight-bold"
            >Avançar etapa de produção?</v-card-title
          >
          <v-card-text>
            <p class="mb-4">
              Movimentando
              <strong class="text-primary">{{
                ConfirmacaoPecaSelecionada.nome
              }}</strong>
              para a etapa de
              <strong class="text-primary">{{
                getTituloColuna(colunaDestino)
              }}</strong
              >.
            </p>

            <v-alert
              v-if="pecaEquivalenteNoDestino"
              type="info"
              variant="tonal"
              icon="mdi-auto-fix"
              density="compact"
              class="mb-4"
            >
              ✨ <strong>Lote irmão detectado no destino!</strong> As
              quantidades serão unificadas automaticamente.
            </v-alert>

            <div
              class="pa-4 border rounded mb-4"
              :class="
                themeStore?.currentMode === 'light'
                  ? 'bg-grey-lighten-4'
                  : 'bg-grey-darken-3'
              "
            >
              <span class="font-weight-bold text-subtitle-2 mb-2 d-block"
                >Como deseja avançar este lote?</span
              >
              <v-radio-group v-model="tipoAvanco" column color="primary">
                <v-radio
                  v-if="!pecaEquivalenteNoDestino"
                  :label="`Avançar lote completo (${ConfirmacaoPecaSelecionada.quantidade || 1} un.)`"
                  value="completo"
                ></v-radio>
                <v-radio
                  v-if="pecaEquivalenteNoDestino"
                  :label="`Avançar e juntar com o lote existente (${ConfirmacaoPecaSelecionada.quantidade || 1} un.)`"
                  value="completo"
                ></v-radio>
                <v-radio
                  v-if="pecaEquivalenteNoDestino"
                  label="Avançar lote separadamente (Não unificar)"
                  value="completo_separado"
                  color="info"
                ></v-radio>
                <v-radio
                  v-if="(ConfirmacaoPecaSelecionada.quantidade || 0) >= 2"
                  label="Desmembrar lote (Avançar apenas uma parte)"
                  value="parcial"
                ></v-radio>
              </v-radio-group>

              <v-expand-transition>
                <div v-if="tipoAvanco === 'parcial'" class="mt-2">
                  <v-text-field
                    v-model="qtdDesmembrada"
                    type="number"
                    label="Quantidade a ser avançada (Filho):"
                    variant="outlined"
                    density="compact"
                    :max="(ConfirmacaoPecaSelecionada.quantidade || 0) - 1"
                    min="1"
                    @input="validarTaxaInput"
                  />
                  <div class="text-caption text-muted mt-n3 mb-2">
                    Restarão
                    <strong
                      >{{
                        Math.max(
                          0,
                          (ConfirmacaoPecaSelecionada.quantidade || 0) -
                            (Number(qtdDesmembrada) || 0),
                        )
                      }}
                      un.</strong
                    >
                    na fase atual.
                  </div>
                </div>
              </v-expand-transition>
            </div>

            <div
              v-if="
                ['Corte', 'Costura', 'Acabamento'].includes(
                  getTituloColuna(colunaDestino),
                )
              "
              class="pa-4 border rounded"
              :class="
                themeStore?.currentMode === 'light'
                  ? 'bg-grey-lighten-4'
                  : 'bg-grey-darken-3'
              "
            >
              <span class="font-weight-bold text-subtitle-2 mb-3 d-block"
                >Informações da etapa de
                {{ getTituloColuna(colunaDestino) }}</span
              >

              <template v-if="getTituloColuna(colunaDestino) === 'Corte'">
                <v-radio-group
                  v-model="novaPeca.tipo_corte"
                  inline
                  label="Tipo de Produção *"
                  color="primary"
                  class="mb-2"
                >
                  <v-radio label="Interna" value="interna"></v-radio>
                  <v-radio label="Externa (Parceiro)" value="externa"></v-radio>
                </v-radio-group>

                <div v-if="novaPeca.tipo_corte === 'interna'">
                  <v-autocomplete
                    v-model="novaPeca.operador_corte_id"
                    v-model:search="buscaOperadorCorte"
                    :items="operadoresCorte"
                    item-title="nome"
                    item-value="id"
                    label="Operador de Corte *"
                    placeholder="Busque o colaborador..."
                    variant="outlined"
                    density="comfortable"
                    clearable
                  />
                  <v-autocomplete
                    v-model="novaPeca.maquina_corte_id"
                    v-model:search="buscaMaquinaCorte"
                    :items="maquinasCorte"
                    item-title="nome"
                    item-value="id"
                    label="Máquina de Corte designada *"
                    placeholder="Busque ou selecione a máquina..."
                    variant="outlined"
                    density="comfortable"
                    clearable
                  />
                </div>
              </template>

              <template v-if="getTituloColuna(colunaDestino) === 'Costura'">
                <v-radio-group
                  v-model="novaPeca.tipo_costura"
                  inline
                  label="Tipo de Produção *"
                  color="primary"
                  class="mb-2"
                >
                  <v-radio label="Interna" value="interna"></v-radio>
                  <v-radio label="Externa (Parceiro)" value="externa"></v-radio>
                </v-radio-group>

                <div v-if="novaPeca.tipo_costura === 'interna'">
                  <v-autocomplete
                    v-model="novaPeca.operador_costura_id"
                    v-model:search="buscaOperadorCostura"
                    :items="operadoresCostura"
                    item-title="nome"
                    item-value="id"
                    label="Operador de Costura *"
                    placeholder="Busque o colaborador..."
                    variant="outlined"
                    density="comfortable"
                    clearable
                  />
                  <v-autocomplete
                    v-model="novaPeca.maquina_costura_id"
                    v-model:search="buscaMaquinaCostura"
                    :items="maquinasCostura"
                    item-title="nome"
                    item-value="id"
                    label="Máquina de Costura designada *"
                    placeholder="Busque ou selecione a máquina..."
                    variant="outlined"
                    density="comfortable"
                    clearable
                  />
                </div>
              </template>

              <template v-if="getTituloColuna(colunaDestino) === 'Acabamento'">
                <v-radio-group
                  v-model="novaPeca.tipo_acabamento"
                  inline
                  label="Tipo de Produção *"
                  color="primary"
                  class="mb-2"
                >
                  <v-radio label="Interna" value="interna"></v-radio>
                  <v-radio label="Externa (Parceiro)" value="externa"></v-radio>
                </v-radio-group>

                <div v-if="novaPeca.tipo_acabamento === 'interna'">
                  <v-autocomplete
                    v-model="novaPeca.operador_acabamento_id"
                    v-model:search="buscaOperadorAcabamento"
                    :items="operadoresAcabamento"
                    item-title="nome"
                    item-value="id"
                    label="Operador de Acabamento *"
                    placeholder="Busque o colaborador..."
                    variant="outlined"
                    density="comfortable"
                    clearable
                  />
                  <v-autocomplete
                    v-model="novaPeca.maquina_acabamento_id"
                    v-model:search="buscaMaquinaAcabamento"
                    :items="maquinasAcabamento"
                    item-title="nome"
                    item-value="id"
                    label="Máquina de Acabamento designada *"
                    placeholder="Busque ou selecione a máquina..."
                    variant="outlined"
                    density="comfortable"
                    clearable
                  />
                </div>
              </template>

              <v-expand-transition>
                <div v-if="mostrarCamposExternos" class="mt-4">
                  <v-textarea
                    v-model="novaPeca.descricao_etapa"
                    label="Descrição / Instruções Técnicas *"
                    placeholder="Digite os detalhes técnicos para o Parceiro Externo..."
                    variant="outlined"
                    density="comfortable"
                    rows="3"
                    auto-grow
                    required
                  />
                  <v-text-field
                    v-model="novaPeca.valor_servico"
                    type="number"
                    label="Valor do serviço (Total R$) *"
                    prefix="R$"
                    variant="outlined"
                    density="comfortable"
                    required
                    :hint="
                      valorUnitarioProduto > 0
                        ? `Calculado automático: Qtd x R$ ${valorUnitarioProduto.toFixed(2)} (Valor un. do Produto)`
                        : ''
                    "
                    persistent-hint
                  />
                </div>
              </v-expand-transition>
            </div>
          </v-card-text>
          <v-card-actions class="pa-4 pt-0">
            <v-spacer></v-spacer>
            <v-btn
              variant="text"
              @click="fecharModalMoverConfirmar"
              :disabled="salvando"
              >Cancelar</v-btn
            >
            <v-btn
              color="primary"
              variant="flat"
              @click="confirmarMovimentacao"
              :loading="salvando"
              >Confirmar Avanço</v-btn
            >
          </v-card-actions>
        </template>
      </v-card>
    </v-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted, watch, onUnmounted } from "vue";
import { useUserStore } from "@/stores/user";
import { useCompanyStore } from "@/stores/company";
import { useThemeStore } from "@/stores/theme";
import { supabase } from "@/api/supabase";
import { useAppStore } from "@/stores/app";

import html2pdf from "html2pdf.js";

const appStore = useAppStore();
const themeStore = useThemeStore();
const userStore = useUserStore();
const companyStore = useCompanyStore();

const checkPermission = (permissionCode: string) => {
  if (userStore.profile?.permissions?.custom_role_id?.length === 0)
    return false;
  const perms = userStore.profile?.permissions || [];
  return perms.includes(permissionCode);
};

interface Peca {
  id: string;
  created_at?: string;
  nome: string | null;
  quantidade: number | null;
  data_entrega: string | null;
  tecido_id: string | null;
  estampa_id: string | null;
  produto_id: string | null;
  tecido_nome: string | null;
  estampa_nome: string | null;
  produto_nome: string | null;
  descricao: string | null;
  status: string | null;
  autor: string | null;
  empresa_id?: string;
  expanded?: boolean;
  maquina_corte_id?: string | null;
  maquina_costura_id?: string | null;
  maquina_acabamento_id?: string | null;
  operador_corte_id?: string | null;
  operador_costura_id?: string | null;
  operador_acabamento_id?: string | null;
  tipo_externo?: number | null;
  tipo_corte?: string | null;
  tipo_costura?: string | null;
  tipo_acabamento?: string | null;
  descricao_etapa?: string | null;
  valor_servico?: number | null;
  precoUni?: string | null;
  preco_unitario?: string | null;
  faturado?: number | null;
}

interface Coluna {
  id: string;
  titulo: string;
  cor?: string;
  pecas: Peca[];
  sequencia: string;
}
interface Maquina {
  id: string;
  nome: string;
  tipo_info?: { nome: string };
}
interface Colaborador {
  id: string;
  nome: string;
}

const carregando = ref(false);
const salvando = ref(false);
const todasPecas = ref<Peca[]>([]);

const exibirModalPerigo = ref(false);
let intervaloPerigo: ReturnType<typeof setInterval> | null = null;

// --- FUNÇÕES EXTRAÍDAS E UNIFICADAS DO CORE ---
const somNotificacao = new URL(
  "../../../assets/message_notification.mp3",
  import.meta.url,
).href;

const getTempoDecorrido = (peca: Peca) => {
  if (!peca.created_at) return "Sem data";
  const diffMs = new Date().getTime() - new Date(peca.created_at).getTime();
  if (diffMs < 0) return "Agora mesmo";
  const mins = Math.floor(diffMs / 60000);
  const horas = Math.floor(diffMs / 3600000);
  const dias = Math.floor(diffMs / 86400000);
  if (dias > 0) return dias === 1 ? "Há 1 dia" : `Há ${dias} dias`;
  if (horas > 0) return horas === 1 ? "Há 1 hora" : `Há ${horas} horas`;
  if (mins > 0) return mins === 1 ? "Há 1 min" : `Há ${mins} min`;
  return "Agora mesmo";
};

const getStatusPrazo = (peca: Peca) => {
  if (!peca.data_entrega) return null;
  const hoje = new Date();
  hoje.setHours(0, 0, 0, 0);
  const partes = peca.data_entrega.split("T")[0].split("-");
  if (partes.length !== 3) return null;
  const dataEntrega = new Date(
    Number(partes[0]),
    Number(partes[1]) - 1,
    Number(partes[2]),
  );
  dataEntrega.setHours(0, 0, 0, 0);
  const diffDias = Math.ceil(
    (dataEntrega.getTime() - hoje.getTime()) / 86400000,
  );

  if (diffDias < 0) return { color: "error", texto: "Atrasado", pulsa: true };
  if (diffDias === 0)
    return { color: "warning", texto: "Entrega Hoje", pulsa: true };
  if (diffDias <= 3)
    return { color: "warning", texto: `Faltam ${diffDias} dias`, pulsa: false };
  return null;
};

const tocarSomAlerta = () => {
  new Audio(somNotificacao).play().catch(() => {});
};

let intervaloSom: ReturnType<typeof setInterval> | null = null;

const formatarPecaEquivalente = (texto: string) =>
  texto.length > 30 ? texto.substring(0, 30) + "..." : texto;

const pecasEmPerigo = computed(() => {
  return todasPecas.value.filter((peca) => {
    if (!peca.data_entrega || peca.status === "estoque") return false;
    const hoje = new Date();
    hoje.setHours(0, 0, 0, 0);
    const partesData = peca.data_entrega.split("T")[0].split("-");
    if (partesData.length !== 3) return false;
    const dataEntrega = new Date(
      Number(partesData[0]),
      Number(partesData[1]) - 1,
      Number(partesData[2]),
    );
    dataEntrega.setHours(0, 0, 0, 0);
    return dataEntrega.getTime() - hoje.getTime() <= 0;
  });
});

const formatarData = (dataISO: string | null) => {
  if (!dataISO) return "-";
  const partes = dataISO.split("T")[0].split("-");
  if (partes.length !== 3) return dataISO;
  return `${partes[2]}/${partes[1]}/${partes[0]}`;
};

// --- LINHA DO TEMPO (FEED) E DOSSIÊ DETALHADO ---
const mostrarModalFeed = ref(false);
const pecaSelecionada = ref<any | null>(null);
const historicoDB = ref<any[]>([]);
const carregandoHistorico = ref(false);
const filtroTimeline = ref("atuais");

// Variáveis para o novo Modal de Detalhes
const exibirModalDetalhesPeca = ref(false);
const detalhesPecaDB = ref<any>(null);

const fecharModalTimeline = () => {
  pecaSelecionada.value = null;
  historicoDB.value = [];
};

const getColunaCor = (statusId: string | null) =>
  colunas.find((c) => c.id === statusId)?.cor || "primary";
const getColunaTitulo = (statusId: string | null) =>
  colunas.find((c) => c.id === statusId)?.titulo || "Sem Etapa";

const getNomeOperador = (id: string | null | undefined) => {
  if (!id) return "Não atribuído";
  return (
    listaColaboradores.value.find((c) => c.id === id)?.nome || "Desconhecido"
  );
};

const getNomeMaquina = (id: string | null | undefined) => {
  if (!id) return "Não atribuída";
  return listaMaquinas.value.find((m) => m.id === id)?.nome || "Desconhecida";
};

const formatarDataHoraTimezone = (dataISO: string) => {
  const d = new Date(dataISO);
  const dia = String(d.getDate()).padStart(2, "0");
  const mes = String(d.getMonth() + 1).padStart(2, "0");
  const hora = String(d.getHours()).padStart(2, "0");
  const min = String(d.getMinutes()).padStart(2, "0");
  return `Dia ${dia}/${mes} às ${hora}:${min}`;
};

watch(mostrarModalFeed, (aberto) => {
  if (aberto) {
    const temAtivas = todasPecas.value.some((p) => p.status !== "estoque");
    filtroTimeline.value = temAtivas ? "atuais" : "sistema";
  }
});

const pecasFiltradasTimeline = computed(() => {
  return todasPecas.value
    .filter((peca) => {
      if (filtroTimeline.value === "atuais") {
        return peca.status !== "estoque";
      }

      if (filtroTimeline.value === "sistema") {
        if (peca.status !== "estoque") return false;
        try {
          const meta = JSON.parse(peca.descricao_etapa || "{}");
          return meta.sistema === true || !meta.pdv;
        } catch (e) {
          return true;
        }
      }

      if (filtroTimeline.value === "loja") {
        if (peca.status !== "estoque") return false;
        try {
          const meta = JSON.parse(peca.descricao_etapa || "{}");
          return meta.pdv === true;
        } catch (e) {
          return false;
        }
      }

      return true;
    })
    .sort((a, b) => {
      const dA = a.data_entrega ? new Date(a.data_entrega).getTime() : 0;
      const dB = b.data_entrega ? new Date(b.data_entrega).getTime() : 0;
      return dB - dA;
    });
});

const abrirHistoricoDetalhado = async (peca: Peca) => {
  pecaSelecionada.value = peca;
  carregandoHistorico.value = true;
  exibirModalDetalhesPeca.value = true;

  try {
    const { data: historicoData } = await supabase
      .from("kanban_producao_historico")
      .select("*")
      .eq("producao_id", peca.id)
      .order("data_entrada", { ascending: true });

    if (historicoData) historicoDB.value = historicoData;

    const { data: pecaData } = await supabase
      .from("kanban_producao")
      .select("*")
      .eq("id", peca.id)
      .single();

    if (pecaData) {
      detalhesPecaDB.value = pecaData;
    } else {
      detalhesPecaDB.value = peca;
    }
  } catch (error) {
    console.error(error);
  } finally {
    carregandoHistorico.value = false;
  }
};

const etapasVisiveis = computed(() => {
  if (!pecaSelecionada.value || historicoDB.value.length === 0) return [];

  const historicoOrdenado = [...historicoDB.value].sort((a, b) => {
    return (
      new Date(a.data_entrada).getTime() - new Date(b.data_entrada).getTime()
    );
  });

  const etapas = historicoOrdenado.map((item, index) => {
    const proximoItem = historicoOrdenado[index + 1];
    const config = colunas.find((c) => c.id === item.status) || {
      titulo: item.status,
    };

    let tituloEtapa = config.titulo;
    if (item.status === "sistema") tituloEtapa = "Enviado para Fábrica ✔";
    if (item.status === "PDV") tituloEtapa = "Enviado para Loja";

    const dataSaidaCalculada =
      item.data_saida || (proximoItem ? proximoItem.data_entrada : null);

    return {
      id: item.id,
      status: item.status,
      titulo: tituloEtapa,
      dataEntrada: item.data_entrada
        ? formatarDataHoraTimezone(item.data_entrada)
        : null,
      dataSaida: dataSaidaCalculada
        ? formatarDataHoraTimezone(dataSaidaCalculada)
        : null,
      comprovante_producao_loja: item.comprovante_producao_loja,
      comprovante_producao_externa: item.comprovante_producao_externa,
    };
  });

  return etapas.reverse();
});

const linkComprovanteExterno = computed(() => {
  if (!etapasVisiveis.value) return null;
  const etapaComPdf = etapasVisiveis.value.find(
    (e) => e.comprovante_producao_externa,
  );
  return etapaComPdf ? etapaComPdf.comprovante_producao_externa : null;
});

const etapaPDV = computed(() => {
  if (!etapasVisiveis.value) return null;
  return etapasVisiveis.value.find((e) => e.comprovante_producao_loja);
});

// --- LISTAS AUXILIARES ---
const listaContasBancarias = ref<{ id: string; bank_name: string }[]>([]);
const listaBeneficiarios = ref<{ id: string; nome: string }[]>([]);
const listaPlanoContas = ref<{ id: string; name: string }[]>([]);

const listaTecidos = ref<{ id: string; fabric_type: string }[]>([]);
const listaEstampas = ref<{ id: string; title: string }[]>([]);
const produtoSearchTerm = ref("");
const produtosFiltrados = ref<
  { id: string; fabric_type: string; base_price: string }[]
>([]);
let timeoutBusca: any = null;

const buscarListasAuxiliares = async () => {
  try {
    const { data: tecidos } = await supabase
      .from("stock")
      .select("id, fabric_type")
      .order("fabric_type")
      .eq("target_tab", "tab_2kc7pi")
      .eq("visible_in_sales", true);
    if (tecidos) listaTecidos.value = tecidos;
    const { data: ContaBanco } = await supabase
      .from("finance_accounts")
      .select("id, bank_name")
      .order("bank_name")
      .eq("is_active", true);
    if (ContaBanco) listaContasBancarias.value = ContaBanco;
    const { data: Beneficiarios } = await supabase
      .from("suppliers_mj")
      .select("id, nome")
      .order("nome")
      .eq("situacao", "Ativo");
    if (Beneficiarios) listaBeneficiarios.value = Beneficiarios;
    const { data: PlanoContas } = await supabase
      .from("finance_chart_of_accounts")
      .select("id, name")
      .order("name")
      .eq("type", "Despesa")
      .eq("active", true);
    if (PlanoContas) listaPlanoContas.value = PlanoContas;
    const { data: estampas } = await supabase
      .from("catalog_stamps")
      .select("id, title")
      .order("title");
    if (estampas) listaEstampas.value = estampas;
  } catch (error) {
    console.error(error);
  }
};

const buscarProdutosAutocomplete = async (val?: any) => {
  const searchTerm = typeof val === "string" ? val.trim() : "";

  if (timeoutBusca) clearTimeout(timeoutBusca);

  timeoutBusca = setTimeout(async () => {
    try {
      let query = supabase
        .from("stock")
        .select("id, fabric_type, base_price")
        .eq("target_tab", "cajuia")
        .order("fabric_type")
        .limit(50);

      if (searchTerm) {
        query = query.ilike("fabric_type", `%${searchTerm}%`);
      }

      const { data, error } = await query;
      if (error) throw error;
      if (data) produtosFiltrados.value = data;
    } catch (error) {
      console.error("Erro na busca de produtos:", error);
    }
  }, 300);
};

// --- CONTROLE DE LOJAS (PDV) ---
const listaLojas = ref<any[]>([]);
const lojaDestinoSelecionada = ref<string | null>(null);

const buscarLojas = async () => {
  try {
    const { data, error } = await supabase
      .from("stores")
      .select("id, name")
      .eq("active", true)
      .order("name");
    if (data) listaLojas.value = data;
  } catch (err) {
    console.error("Erro ao buscar lojas:", err);
  }
};

// --- COLABORADORES E MÁQUINAS ---
const listaColaboradores = ref<Colaborador[]>([]);
const totalestoque = ref(0);

const buscaOperadorCorte = ref("");
const buscaOperadorCostura = ref("");
const buscaOperadorAcabamento = ref("");

const carregarColaboradores = async () => {
  try {
    const { data } = await supabase.from("employees_mj").select("id, nome");
    if (data) listaColaboradores.value = data;
  } catch (error) {
    console.error(error);
  }
};

const colaboradoresFiltrados = (busca: string) =>
  listaColaboradores.value.filter((op) =>
    op.nome.toLowerCase().includes(busca.toLowerCase()),
  );
const operadoresCorte = computed(() =>
  colaboradoresFiltrados(buscaOperadorCorte.value),
);
const operadoresCostura = computed(() =>
  colaboradoresFiltrados(buscaOperadorCostura.value),
);
const operadoresAcabamento = computed(() =>
  colaboradoresFiltrados(buscaOperadorAcabamento.value),
);

const listaMaquinas = ref<Maquina[]>([]);
const buscaMaquinaCorte = ref("");
const buscaMaquinaCostura = ref("");
const buscaMaquinaAcabamento = ref("");

const carregarMaquinas = async () => {
  try {
    const { data } = await supabase
      .from("machines")
      .select("id, nome, tipo_info:type_machines(nome)");

    if (data) listaMaquinas.value = data;
  } catch (error) {
    console.error("Erro ao carregar máquinas: ", error);
  }
};

const maquinasFiltradas = (tipoDesejado: string, busca: string) => {
  return listaMaquinas.value.filter((m) => {
    const tipoDaMaquinaDB = m.tipo_info?.nome?.toLowerCase() || "";
    const tipoParaFiltrar = tipoDesejado.toLowerCase();

    const buscaDigitada = busca ? busca.toLowerCase() : "";

    return (
      tipoDaMaquinaDB === tipoParaFiltrar &&
      m.nome.toLowerCase().includes(buscaDigitada)
    );
  });
};

const maquinasCorte = computed(() =>
  maquinasFiltradas("Corte", buscaMaquinaCorte.value),
);
const maquinasCostura = computed(() =>
  maquinasFiltradas("Costura", buscaMaquinaCostura.value),
);
const maquinasAcabamento = computed(() =>
  maquinasFiltradas("Acabamento", buscaMaquinaAcabamento.value),
);

const kpisVisiveis = reactive<Record<string, boolean>>({
  secaoGeral: true,
  totalModelos: true,
  entregasMes: true,
  emCorte: true,
  emCostura: true,
  emAcabamento: true,
  concluidos: true,
  perigo: true,
});

const termoBusca = ref("");
const dataBusca = ref("");
const filtro = ref<string>("todos");
const exibirModalExclusao = ref(false);
const exibirModalCadastro = ref(false);
const dialogMover = ref(false);
const modoEdicao = ref(false);

const pecaEmEdicaoId = ref<string | null>(null);
const pecaEmExclusaoId = ref<string | null>(null);
const pecaEmExclusaoNome = ref<string | null>(null);

const colunas = reactive<Coluna[]>([
  {
    id: "producao",
    titulo: "Pedido de estampa",
    cor: "#3b82f6",
    pecas: [],
    sequencia: "1",
  },
  {
    id: "pedido_tecido",
    titulo: "Pedido do Tecido",
    cor: "#8b5cf6",
    pecas: [],
    sequencia: "2",
  },
  { id: "corte", titulo: "Corte", cor: "#ec4899", pecas: [], sequencia: "3" },
  {
    id: "costura",
    titulo: "Costura",
    cor: "#f59e0b",
    pecas: [],
    sequencia: "4",
  },
  {
    id: "acabamento",
    titulo: "Acabamento",
    cor: "#10b981",
    pecas: [],
    sequencia: "5",
  },
  {
    id: "embalagem",
    titulo: "Embalamento",
    cor: "#06b6d4",
    pecas: [],
    sequencia: "6",
  },
  {
    id: "estoque",
    titulo: "Estoque",
    cor: "#64748b",
    pecas: [],
    sequencia: "7",
  },
]);

const totalLotes = computed(() => {
  return todasPecas.value.filter(
    (item) => item.status?.toLowerCase() !== "estoque",
  ).length;
});
const totalEntregasMesAtual = computed(() => {
  let mesAlvo = dataBusca.value
    ? dataBusca.value.substring(0, 7)
    : `${new Date().getFullYear()}-${String(new Date().getMonth() + 1).padStart(2, "0")}`;
  return colunas.reduce(
    (acc, col) =>
      acc +
      col.pecas.filter(
        (p) => p.data_entrega && p.data_entrega.startsWith(mesAlvo),
      ).length,
    0,
  );
});

const carregarEstoque = async () => {
  const { data } = await supabase
    .from("stock")
    .select("available_meters")
    .eq("visible_in_sales", true);
  if (data) {
    totalestoque.value = data.reduce(
      (acc, item) => acc + Number(item.available_meters || 0),
      0,
    );
  }
};

const carregarConfiguracoes = async () => {
  const userId = userStore.profile?.id;
  if (!userId) return;
  try {
    const { data } = await supabase
      .from("kanban_producao_configuracoes")
      .select("*")
      .eq("perfil_id", userId)
      .maybeSingle();
    if (data) {
      kpisVisiveis.secaoGeral = data.kpi_secao_geral !== 0;
      kpisVisiveis.totalModelos = data.kpi_total_de_modelos !== 0;
      kpisVisiveis.entregasMes = data.kpi_entrega_mes !== 0;
      kpisVisiveis.emCorte = data.kpi_em_corte !== 0;
      kpisVisiveis.emCostura = data.kpi_em_costura !== 0;
      kpisVisiveis.emAcabamento = data.kpi_em_acabamento !== 0;
      kpisVisiveis.concluidos = data.kpi_concluidos !== 0;
      if (data.kpi_perigo !== undefined)
        kpisVisiveis.perigo = data.kpi_perigo !== 0;

      if (data.cor_tabela_producao) colunas[0].cor = data.cor_tabela_producao;
      if (data.cor_tabela_pedido_tecido)
        colunas[1].cor = data.cor_tabela_pedido_tecido;
      if (data.cor_tabela_corte) colunas[2].cor = data.cor_tabela_corte;
      if (data.cor_tabela_costura) colunas[3].cor = data.cor_tabela_costura;
      if (data.cor_tabela_acabamento)
        colunas[4].cor = data.cor_tabela_acabamento;
      if (data.cor_tabela_embalagem) colunas[5].cor = data.cor_tabela_embalagem;
      if (data.cor_tabela_estoque) colunas[6].cor = data.cor_tabela_estoque;
    }
  } catch (err) {
    console.error("Erro ao carregar confs:", err);
  }
};

const salvarConfiguracoes = async () => {
  const userId = userStore.profile?.id;
  if (!userId) return;

  const payload = {
    perfil_id: userId,
    kpi_secao_geral: kpisVisiveis.secaoGeral ? 1 : 0,
    kpi_total_de_modelos: kpisVisiveis.totalModelos ? 1 : 0,
    kpi_entrega_mes: kpisVisiveis.entregasMes ? 1 : 0,
    kpi_em_corte: kpisVisiveis.emCorte ? 1 : 0,
    kpi_em_costura: kpisVisiveis.emCostura ? 1 : 0,
    kpi_em_acabamento: kpisVisiveis.emAcabamento ? 1 : 0,
    kpi_concluidos: kpisVisiveis.concluidos ? 1 : 0,
    kpi_perigo: kpisVisiveis.perigo ? 1 : 0,
    cor_tabela_producao: colunas[0].cor,
    cor_tabela_pedido_tecido: colunas[1].cor,
    cor_tabela_corte: colunas[2].cor,
    cor_tabela_costura: colunas[3].cor,
    cor_tabela_acabamento: colunas[4].cor,
    cor_tabela_embalagem: colunas[5].cor,
    cor_tabela_estoque: colunas[6].cor,
  };

  try {
    const { error } = await supabase
      .from("kanban_producao_configuracoes")
      .upsert(payload, { onConflict: "perfil_id" });
    if (error) throw error;
  } catch (err: any) {
    console.error("Falha ao salvar configurações:", err.message);
  }
};

const organizarColunas = () => {
  colunas.forEach((c) => (c.pecas = []));
  todasPecas.value.forEach((peca) => {
    if (peca.status === "estoque") return;
    if (termoBusca.value) {
      const termo = termoBusca.value.toLowerCase();
      if (
        !(peca.nome || "").toLowerCase().includes(termo) &&
        !String(peca.tecido_id || "").includes(termo) &&
        !String(peca.estampa_id || "").includes(termo)
      )
        return;
    }
    if (
      dataBusca.value &&
      peca.data_entrega?.substring(0, 7) !== dataBusca.value.substring(0, 7)
    )
      return;
    const colunaEncontrada = colunas.find(
      (c) => c.id === (peca.status || "producao"),
    );
    if (colunaEncontrada) colunaEncontrada.pecas.push(peca);
    else colunas[0]?.pecas.push(peca);
  });
};

const colunasFiltradas = computed(() =>
  filtro.value === "todos"
    ? colunas
    : colunas.filter((c) => c.id === filtro.value),
);
watch([termoBusca, dataBusca], () => organizarColunas());

const buscarProducao = async () => {
  carregando.value = true;
  try {
    let query = supabase
      .from("kanban_producao")
      .select("*")
      .in("status", [
        "producao",
        "pedido_tecido",
        "corte",
        "costura",
        "acabamento",
        "embalagem",
        "estoque",
      ]);
    if (dataBusca.value)
      query = query.ilike(
        "data_entrega",
        `${dataBusca.value.substring(0, 7)}%`,
      );
    const { data, error } = await query.order("data_entrega", {
      ascending: true,
    });
    if (error) throw error;
    todasPecas.value = (data || []).map((item) => ({
      ...item,
      expanded: false,
    }));
    organizarColunas();
  } catch (error) {
    console.error(error);
  } finally {
    carregando.value = false;
  }
};

onMounted(() => {
  buscarProducao();
  carregarConfiguracoes();
  carregarMaquinas();
  carregarColaboradores();
  carregarEstoque();
  buscarListasAuxiliares();
  buscarLojas();

  intervaloPerigo = setInterval(() => {
    if (pecasEmPerigo.value.length > 0) exibirModalPerigo.value = true;
  }, 3600000);

  intervaloSom = setInterval(() => {
    if (todasPecas.value.some((p) => getStatusPrazo(p)?.pulsa))
      tocarSomAlerta();
  }, 10000);
});

onUnmounted(() => {
  if (intervaloPerigo) clearInterval(intervaloPerigo);
  if (intervaloSom) clearInterval(intervaloSom);
});

const getBaseName = (nome: string | null) =>
  nome ? nome.replace(/\s*\(Desmembrado\)/g, "").trim() : "";
const encontrarPecaEquivalente = (pecaOrigem: Peca, destinoStatus: string) =>
  todasPecas.value.find(
    (p) =>
      p.id !== pecaOrigem.id &&
      p.status === destinoStatus &&
      getBaseName(p.nome) === getBaseName(pecaOrigem.nome) &&
      p.tecido_id === pecaOrigem.tecido_id &&
      p.estampa_id === pecaOrigem.estampa_id,
  );
const pecaEquivalenteNoDestino = computed(() =>
  !ConfirmacaoPecaSelecionada.value || !colunaDestino.value
    ? null
    : encontrarPecaEquivalente(
        ConfirmacaoPecaSelecionada.value,
        colunaDestino.value,
      ),
);

const novaPeca = reactive<Record<string, any>>({
  nome: "",
  quantidade: "",
  data_entrega: "",
  tecido_id: "",
  estampa_id: "",
  descricao: "",
  produto: null,
  produto_id: null,
  produto_unitario: null,
  tecido_nome: "",
  estampa_nome: "",
  produto_nome: "",
  maquina_corte_id: null,
  maquina_costura_id: null,
  maquina_acabamento_id: null,
  operador_corte_id: null,
  operador_costura_id: null,
  operador_acabamento_id: null,
  tipo_corte: "interna",
  tipo_costura: "interna",
  tipo_acabamento: "interna",
  tipo_externo: 0,
  descricao_etapa: "",
  valor_servico: "",
});

// === CRUD PRODUÇÃO ===
const abrirModalCadastro = () => {
  modoEdicao.value = false;
  pecaEmEdicaoId.value = null;
  Object.assign(novaPeca, {
    nome: "",
    quantidade: "",
    data_entrega: "",
    tecido_id: "",
    estampa_id: "",
    produto: null,
    produto_id: null,
    tecido_nome: "",
    estampa_nome: "",
    produto_nome: "",
    descricao: "",
    maquina_corte_id: null,
    maquina_costura_id: null,
    maquina_acabamento_id: null,
    operador_corte_id: null,
    operador_costura_id: null,
    operador_acabamento_id: null,
    tipo_corte: "interna",
    tipo_costura: "interna",
    tipo_acabamento: "interna",
    tipo_externo: 0,
    descricao_etapa: "",
    valor_servico: "",
  });
  produtoSearchTerm.value = "";
  produtosFiltrados.value = [];
  buscarProdutosAutocomplete("");
  exibirModalCadastro.value = true;
};

const abrirModalEdicao = async (peca: Peca) => {
  modoEdicao.value = true;
  pecaEmEdicaoId.value = peca.id;
  Object.assign(novaPeca, {
    nome: peca.nome || "",
    quantidade: peca.quantidade ?? "",
    data_entrega: peca.data_entrega || "",
    tecido_id: peca.tecido_id ?? "",
    estampa_id: peca.estampa_id ?? "",
    descricao: peca.descricao || "",
    produto: "",
    produto_nome: peca.produto_nome || "",
    produto_preco: peca.precoUni || "",
    tecido_nome: peca.tecido_nome || "",
    estampa_nome: peca.estampa_nome || "",
  });
  produtoSearchTerm.value = "";
  buscarProdutosAutocomplete("");

  if (peca.produto_id) {
    const { data: produtos } = await supabase
      .from("stock")
      .select("id, fabric_type, base_price")
      .order("fabric_type")
      .eq("target_tab", "ready_delivery");
    if (produtos) {
      produtosFiltrados.value = produtos;
      novaPeca.produto = produtos.find((p) => p.id === peca.produto_id) || null;
    }
  }
  exibirModalCadastro.value = true;
};

const removeritem = (peca: Peca) => {
  pecaEmExclusaoId.value = peca.id;
  pecaEmExclusaoNome.value = peca.nome;
  exibirModalExclusao.value = true;
};

const ExcluirItem = async () => {
  if (!pecaEmExclusaoId.value) return;
  salvando.value = true;
  try {
    const { error } = await supabase
      .from("kanban_producao")
      .delete()
      .eq("id", pecaEmExclusaoId.value);
    if (error) throw error;
    todasPecas.value = todasPecas.value.filter(
      (p) => p.id !== pecaEmExclusaoId.value,
    );
    organizarColunas();
    exibirModalExclusao.value = false;
    appStore.showSnackbar("Produção excluída com sucesso.", "success");
  } catch (error: any) {
    appStore.showSnackbar(
      `Não foi possível excluir a produção. Detalhe: ${error?.message || error?.details}`,
      "error",
    );
  } finally {
    salvando.value = false;
  }
};

const salvarproducao = async () => {
  if (
    !novaPeca.nome ||
    !novaPeca.quantidade ||
    !novaPeca.data_entrega ||
    !novaPeca.tecido_id
  ) {
    appStore.showSnackbar("Preencha todos os campos obrigatórios.", "warning");
    return;
  }

  if (Number(novaPeca.quantidade) <= 0) {
    appStore.showSnackbar("A quantidade deve ser maior que zero.", "warning");
    return;
  }

  if (!novaPeca.produto) {
    appStore.showSnackbar(
      "Erro: É obrigatório selecionar um Produto válido da lista de busca antes de salvar.",
      "error",
    );
    return;
  }

  salvando.value = true;
  try {
    const tecidoSelecionado = listaTecidos.value.find(
      (t) => t.id === novaPeca.tecido_id,
    );
    const estampaSelecionada = listaEstampas.value.find(
      (e) => e.id === novaPeca.estampa_id,
    );

    const produtoId =
      typeof novaPeca.produto === "object"
        ? novaPeca.produto.id
        : novaPeca.produto;
    const produtoNome =
      typeof novaPeca.produto === "object"
        ? novaPeca.produto.fabric_type
        : produtosFiltrados.value.find((p) => p.id === produtoId)
            ?.fabric_type || null;

    const produtobase =
      typeof novaPeca.produto === "object"
        ? novaPeca.produto.base_price
        : produtosFiltrados.value.find((p) => p.id === produtoId)?.base_price ||
          null;

    const payload = {
      nome: novaPeca.nome,
      quantidade: novaPeca.quantidade,
      data_entrega: novaPeca.data_entrega,
      tecido_id: novaPeca.tecido_id || null,
      estampa_id: novaPeca.estampa_id || null,
      produto_id: produtoId || null,
      tecido_nome: tecidoSelecionado ? tecidoSelecionado.fabric_type : null,
      estampa_nome: estampaSelecionada ? estampaSelecionada.title : null,
      produto_nome: produtoNome,
      preco_unitario: produtobase,
      descricao: novaPeca.descricao,
      empresa_id: companyStore.currentCompany?.id || null,
      autor:
        userStore.profile?.username || userStore.profile?.id || "Usuário Web",
    };

    if (modoEdicao.value && pecaEmEdicaoId.value) {
      const { error } = await supabase
        .from("kanban_producao")
        .update(payload)
        .eq("id", pecaEmEdicaoId.value);
      if (error) throw error;
      appStore.showSnackbar("Lote atualizado com sucesso!", "success");
    } else {
      const { error } = await supabase
        .from("kanban_producao")
        .insert([{ ...payload, status: "producao" }]);
      if (error) throw error;
      appStore.showSnackbar("Lote cadastrado com sucesso!", "success");
    }
    exibirModalCadastro.value = false;
    buscarProducao();
  } catch (error: any) {
    console.error(error);
    appStore.showSnackbar(
      `Falha ao salvar. Detalhe: ${error.message || JSON.stringify(error)}`,
      "error",
    );
  } finally {
    salvando.value = false;
  }
};

// --- CONTROLE DE DRAG AND DROP ---
const ConfirmacaoPecaSelecionada = ref<Peca | null>(null);
const colunaOrigemId = ref<string>("");
const colunaDestino = ref<string>("");
const tipoAvanco = ref<"completo" | "parcial" | "completo_separado">(
  "completo",
);
const qtdDesmembrada = ref<number | string>("");
const valorUnitarioProduto = ref<number>(0);

const destinoEstoque = ref<"sistema" | "pdv" | "ambos">("sistema");
const qtdEstoqueSistema = ref<number | string>("");
const qtdEstoquePDV = ref<number | string>("");
const totalDistribuido = computed(
  () =>
    (Number(qtdEstoqueSistema.value) || 0) + (Number(qtdEstoquePDV.value) || 0),
);

const pecaArrastada = ref<Peca | null>(null);
const originIdArrasto = ref<string>("");

const onDragStart = (event: DragEvent, peca: Peca, origemId: string) => {
  if (!userStore.profile.permissions.includes("mfg_producao_arrastar")) return;
  pecaArrastada.value = peca;
  originIdArrasto.value = origemId;
};

const qtdAvancarReal = computed(() =>
  tipoAvanco.value === "parcial"
    ? Number(qtdDesmembrada.value) || 0
    : ConfirmacaoPecaSelecionada.value?.quantidade || 0,
);

const mostrarCamposExternos = computed(() => {
  if (!colunaDestino.value) return false;
  const titulo = getTituloColuna(colunaDestino.value);
  if (titulo === "Corte" && novaPeca.tipo_corte === "externa") return true;
  if (titulo === "Costura" && novaPeca.tipo_costura === "externa") return true;
  if (titulo === "Acabamento" && novaPeca.tipo_acabamento === "externa")
    return true;
  return false;
});

watch([valorUnitarioProduto, qtdAvancarReal], ([unitario, qtd]) => {
  if (unitario > 0) novaPeca.valor_servico = (unitario * qtd).toFixed(2);
});

const prepararMovimentacao = (
  peca: Peca,
  origemId: string,
  destinoId: string,
) => {
  ConfirmacaoPecaSelecionada.value = peca;
  colunaOrigemId.value = origemId;
  colunaDestino.value = destinoId;
  dialogMover.value = true;
};

const onDrop = async (event: DragEvent, destinoId: string) => {
  if (!pecaArrastada.value || originIdArrasto.value === destinoId) return;
  ConfirmacaoPecaSelecionada.value = pecaArrastada.value;
  colunaOrigemId.value = originIdArrasto.value;
  colunaDestino.value = destinoId;
  tipoAvanco.value = "completo";
  pecaArrastada.value = null;
  valorUnitarioProduto.value = 0;

  if (ConfirmacaoPecaSelecionada.value?.produto_id) {
    try {
      const { data } = await supabase
        .from("stock")
        .select("base_price")
        .eq("id", ConfirmacaoPecaSelecionada.value.produto_id)
        .single();
      if (data) valorUnitarioProduto.value = Number(data.base_price) || 0;
    } catch (err) {
      console.error("Erro ao buscar base_price do produto:", err);
    }
  }
  dialogMover.value = true;
  prepararMovimentacao(
    ConfirmacaoPecaSelecionada.value,
    colunaOrigemId.value,
    colunaDestino.value,
  );
};

const fecharModalMoverConfirmar = () => {
  ConfirmacaoPecaSelecionada.value = null;
  colunaOrigemId.value = "";
  colunaDestino.value = "";
  valorUnitarioProduto.value = 0;
  dialogMover.value = false;
  lojaDestinoSelecionada.value = null;
  buscaMaquinaCorte.value = "";
  buscaMaquinaCostura.value = "";
  buscaMaquinaAcabamento.value = "";
  buscaOperadorCorte.value = "";
  buscaOperadorCostura.value = "";
  buscaOperadorAcabamento.value = "";
  Object.assign(novaPeca, {
    maquina_corte_id: null,
    maquina_costura_id: null,
    maquina_acabamento_id: null,
    operador_corte_id: null,
    operador_costura_id: null,
    operador_acabamento_id: null,
    tipo_corte: "interna",
    tipo_costura: "interna",
    tipo_acabamento: "interna",
    tipo_externo: 0,
    descricao_etapa: "",
    valor_servico: "",
  });
};

const validarTaxaInput = (e: Event) => {
  const el = e.target as HTMLInputElement;
  let num = parseInt(el.value.replace(/\D/g, ""), 10);
  const max = (ConfirmacaoPecaSelecionada.value?.quantidade || 0) - 1;
  if (num > max) num = max;
  qtdDesmembrada.value = num || "";
  el.value = num ? num.toString() : "";
};

const validarEstoqueDuplo = (e: Event, tipo: "sistema" | "pdv") => {
  const el = e.target as HTMLInputElement;
  let digitado = parseInt(el.value.replace(/\D/g, ""), 10) || 0;
  const totalLote = ConfirmacaoPecaSelecionada.value?.quantidade || 0;
  const outro =
    tipo === "sistema"
      ? Number(qtdEstoquePDV.value) || 0
      : Number(qtdEstoqueSistema.value) || 0;
  if (digitado > totalLote - outro) digitado = Math.max(0, totalLote - outro);
  if (tipo === "sistema") qtdEstoqueSistema.value = digitado || "";
  else qtdEstoquePDV.value = digitado || "";
  el.value = digitado ? digitado.toString() : "";
};

const kpiList = computed(() =>
  [
    {
      id: "total",
      label: "Total de Lotes",
      value: totalLotes,
      footer: "Ativos na produção",
      icon: "mdi-format-list-bulleted",
      color: "bg-gradient-info",
    },
    {
      id: "entregas",
      label: "Entregas (Mês)",
      value: totalEntregasMesAtual.value,
      footer: "Neste mês",
      unit: "un.",
      icon: "mdi-calendar-check",
      color: "bg-gradient-purple",
    },
    {
      id: "corte",
      label: "Em Corte",
      value: colunas.find((c) => c.id === "corte")?.pecas.length || 0,
      footer: "Em etapa",
      icon: "mdi-scissors-cutting",
      color: "bg-gradient-warning",
    },
    {
      id: "costura",
      label: "Em Costura",
      value: colunas.find((c) => c.id === "costura")?.pecas.length || 0,
      footer: "Em etapa",
      icon: "mdi-needle",
      color: "bg-gradient-red",
    },
    {
      id: "acabamento",
      label: "Em Acabamento",
      value: colunas.find((c) => c.id === "acabamento")?.pecas.length || 0,
      footer: "Em etapa",
      icon: "mdi-tshirt-crew",
      color: "bg-gradient-green",
    },
    {
      id: "perigo",
      label: "Perigo",
      value: pecasEmPerigo.value.length,
      footer: "Lotes vencendo",
      icon: "mdi-alert-circle",
      color: "bg-gradient-red",
    },
    {
      id: "estoque",
      label: "No Estoque",
      value: totalestoque.value,
      footer: "Peças totais",
      icon: "mdi-package-variant-closed",
      color: "bg-gradient-info",
    },
  ].filter((item) => {
    if (item.id === "total") return kpisVisiveis.totalModelos;
    if (item.id === "entregas") return kpisVisiveis.entregasMes;
    if (item.id === "corte") return kpisVisiveis.emCorte;
    if (item.id === "costura") return kpisVisiveis.emCostura;
    if (item.id === "acabamento") return kpisVisiveis.emAcabamento;
    if (item.id === "perigo") return kpisVisiveis.perigo;
    if (item.id === "estoque") return kpisVisiveis.concluidos;
    return true;
  }),
);

// --- ESTADO DO MODAL FINANCEIRO ---
const exibirModalPagamento = ref(false);
const pecaPagamento = ref<Peca | null>(null);
const dadosPagamento = reactive({
  id: "",
  valor: "",
  data_vencimento: "",
  descricao: "",
  conta: "",
  beneficiario: "",
  categoria: "",
});

const abrirModalPagamento = (peca: Peca) => {
  dadosPagamento.id = peca.id;
  pecaPagamento.value = peca;
  dadosPagamento.valor = peca.valor_servico
    ? peca.valor_servico.toString()
    : "";
  dadosPagamento.data_vencimento = new Date().toISOString().split("T")[0];
  dadosPagamento.descricao = `Pagamento Serviço Externo (${getTituloColuna(peca.status || "")}) - Lote: ${peca.nome}`;
  dadosPagamento.beneficiario = listaBeneficiarios.value[0]?.id || "";
  dadosPagamento.conta = listaContasBancarias.value[0]?.id || "";
  dadosPagamento.categoria = listaPlanoContas.value[0]?.id || "";
  exibirModalPagamento.value = true;
};

const confirmarPagamentoFaccao = async () => {
  if (!dadosPagamento.data_vencimento || !dadosPagamento.descricao) {
    appStore.showSnackbar(
      "Preencha a descrição, valor e a data de vencimento.",
      "warning",
    );
    return;
  }
  if (Number(dadosPagamento.valor) <= 0) {
    appStore.showSnackbar(
      "O Valor não pode ser vazio ou igual a 0.",
      "warning",
    );
    return;
  }

  salvando.value = true;
  try {
    const fornecedorSelecionado = listaBeneficiarios.value.find(
      (b) => b.id === dadosPagamento.beneficiario,
    );
    const nomeBeneficiario = fornecedorSelecionado
      ? fornecedorSelecionado.nome
      : "Serviço Externo";

    const payload = {
      description: dadosPagamento.descricao,
      value: parseFloat(dadosPagamento.valor),
      due_date: dadosPagamento.data_vencimento,
      status: "pendente",
      category: "Serviço Externo (Facção)",

      entity_name: nomeBeneficiario,

      company_id: companyStore.currentCompany?.id || null,
      bank_account_id: dadosPagamento.conta || null,
      chart_of_accounts_id: dadosPagamento.categoria || null,

      installment_number: 1,
      total_installments: 1,
      competence_date: new Date().toISOString().split("T")[0],
      reconciliation_status: "PENDING",
    };

    const { error } = await supabase.from("finance_payables").insert([payload]);
    if (error) throw error;

    appStore.showSnackbar(
      "Lançamento registrado no Contas a Pagar com sucesso!",
      "success",
    );

    // Atualiza a ficha de produção indicando que já foi faturado
    const payloadAtt = { faturado: 1 };
    const { error: erroAtt } = await supabase
      .from("kanban_producao")
      .update(payloadAtt)
      .eq("id", dadosPagamento.id);
    if (erroAtt) throw erroAtt;

    buscarProducao();
    exibirModalPagamento.value = false;
  } catch (error: any) {
    console.error("Erro ao lançar contas a pagar:", error);
    appStore.showSnackbar(
      `Não foi possível registrar o pagamento. Detalhe: ${error.message || JSON.stringify(error)}`,
      "error",
    );
  } finally {
    salvando.value = false;
  }
};

const baixarPDFExternoURL = (url: string) => {
  window.open(url, "_blank");
};

const baixarPDFDoCard = (peca: Peca) => gerarPDFOrdemServico(peca);
const baixarPDF = async (historicoId: string) => {
  const { data, error } = await supabase
    .from("kanban_producao_historico")
    .select("comprovante_producao_loja")
    .eq("id", historicoId)
    .single();

  if (error || !data?.comprovante_producao_loja) {
    console.error("PDF não encontrado");
    return;
  }

  const response = await fetch(data.comprovante_producao_loja);

  const blob = await response.blob();

  const blobUrl = URL.createObjectURL(blob);

  const link = document.createElement("a");

  link.href = blobUrl;
  link.download = `comprovante-${historicoId}.pdf`;

  document.body.appendChild(link);

  link.click();

  link.remove();

  URL.revokeObjectURL(blobUrl);
};

const gerarPDFOrdemServico = async (
  peca: Peca,
  etapaAvulsa?: string,
  extrasAvulsos?: any,
  colunaIdDestino?: string,
) => {
  const dataHoje = new Date().toLocaleDateString("pt-BR");
  const horaHoje = new Date().toLocaleTimeString("pt-BR", {
    hour: "2-digit",
    minute: "2-digit",
  });
  const etapa =
    typeof etapaAvulsa === "string"
      ? etapaAvulsa
      : getTituloColuna(peca.status || "");
  const qtd = extrasAvulsos?.quantidadeMove || peca.quantidade || 0;
  const valorTotal = extrasAvulsos?.valor_servico || peca.valor_servico || 0;
  const vlrUnitario = valorTotal > 0 ? (valorTotal / qtd).toFixed(2) : "0.00";
  const numeroOS = peca.id
    ? peca.id.substring(0, 8).toUpperCase()
    : Math.floor(Math.random() * 1000000);

  const html = `
    <!DOCTYPE html>
    <html lang="pt-BR">
    <head>
      <meta charset="UTF-8">
      <title>OS EXTERNA - ${numeroOS}</title>
      <style>
        @page { size: A4 portrait; margin: 15mm; }
        * { box-sizing: border-box; }
        body { font-family: 'Segoe UI', Arial, sans-serif; font-size: 13px; color: #111827; margin: 0; padding: 0; line-height: 1.5; }
        .container { width: 100%; max-width: 190mm; margin: 0 auto; }
        .header { display: flex; width: 100%; border: 2px solid #111827; border-radius: 6px; margin-bottom: 20px; overflow: hidden; }
        .header-title { width: 80%; display: flex; flex-direction: column; justify-content: center; align-items: center; padding: 10px; }
        .header-title h1 { margin: 0; font-size: 20px; text-transform: uppercase; letter-spacing: 1px; color: #111827; }
        .header-title p { margin: 5px 0 0 0; font-size: 14px; font-weight: 600; color: #4b5563; }
        .header-info { width: 25%; border-left: 1px solid #111827; background-color: #f9fafb; padding: 10px; font-size: 12px; }
        .header-info strong { display: inline-block; width: 60px; }
        table { width: 100%; border-collapse: collapse; margin-bottom: 20px; border-radius: 6px; }
        th, td { border: 1px solid #d1d5db; padding: 8px 12px; text-align: left; }
        th { background-color: #f3f4f6; font-size: 12px; text-transform: uppercase; color: #374151; font-weight: 700; width: 25%; }
        td { font-size: 13px; color: #111827; }
        .items-table th { background-color: #e5e7eb; border-color: #9ca3af; text-align: center; }
        .items-table td { border-color: #9ca3af; }
        .items-table .text-center { text-align: center; }
        .items-table .col-valor { width: 110px; }
        .items-table tr.total-row th { text-align: right; font-size: 14px; background-color: #f3f4f6; padding-right: 15px;}
        .items-table tr.total-row td { background-color: #f9fafb; font-weight: bold; font-size: 14px; color: #10b981; }
        .obs-box { border: 1px solid #d1d5db; border-radius: 6px; padding: 15px; margin-bottom: 20px; min-height: 100px; background-color: #fcfcfc; }
        .obs-title { font-weight: 700; font-size: 12px; text-transform: uppercase; margin-bottom: 8px; color: #374151; border-bottom: 1px solid #e5e7eb; padding-bottom: 5px; }
        .signatures { display: flex; justify-content: space-between; margin-top: 50px; padding: 0 20px; }
        .sig-box { width: 40%; text-align: center; }
        .sig-line { border-bottom: 1px solid #111827; margin-bottom: 8px; height: 30px; }
        .sig-name { font-weight: 700; font-size: 12px; text-transform: uppercase; }
        .sig-role { font-size: 11px; color: #6b7280; }
        .footer { margin-top: 40px; text-align: center; font-size: 10px; color: #9ca3af; border-top: 1px solid #e5e7eb; padding-top: 10px; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <div class="header-title">
            <h1>Ordem de Serviço</h1>
            <p>SERVIÇO EXTERNO</p>
          </div>
          <div class="header-info">
            <div style="margin-bottom: 5px;"><strong>OS Nº:</strong> <span style="color: #ef4444; font-weight: 700; font-size: 14px;">${numeroOS}</span></div>
            <div style="margin-bottom: 5px;"><strong>Emissão:</strong> ${dataHoje}</div>
            <div><strong>Hora:</strong> ${horaHoje}</div>
          </div>
        </div>

        <table>
          <tr><th>Lote / Modelo</th><td colspan="3" style="font-weight: 700; font-size: 14px; text-transform: uppercase;">${peca.nome || "N/A"}</td></tr>
          <tr><th>Etapa Produtiva</th><td>${etapa}</td><th>Prazo de Entrega</th><td style="color: #dc2626; font-weight: 700;">${formatarData(peca.data_entrega)}</td></tr>
          <tr><th>Cód. Tecido</th><td>${peca.tecido_nome || peca.tecido_id || "-"}</td><th>Cód. Estampa</th><td>${peca.estampa_nome || peca.estampa_id || "-"}</td></tr>
        </table>

        <table class="items-table">
          <tr><th style="width: 50%; text-align: left;">Descrição do Serviço</th><th style="width: 10%;">UN</th><th style="width: 10%;">QTD</th><th class="col-valor">Vlr. Unitário</th><th class="col-valor">Vlr. Total</th></tr>
          <tr>
            <td>Serviço de ${etapa} referente ao Lote: <strong>${peca.nome || "-"}</strong></td>
            <td class="text-center">PC</td>
            <td class="text-center" style="font-weight: bold; font-size: 14px;">${qtd}</td>
            <td class="text-center">R$ ${vlrUnitario}</td>
            <td class="text-center">R$ ${parseFloat(valorTotal.toString()).toFixed(2)}</td>
          </tr>
          <tr><td>&nbsp;</td><td></td><td></td><td></td><td></td></tr>
          <tr><td>&nbsp;</td><td></td><td></td><td></td><td></td></tr>
          <tr class="total-row">
            <th colspan="4">TOTAL GERAL DA O.S. (R$)</th>
            <td class="text-center">R$ ${parseFloat(valorTotal.toString()).toFixed(2)}</td>
          </tr>
        </table>

        <div class="obs-box">
          <div class="obs-title">Instruções Técnicas e Observações</div>
          <div style="font-size: 13px; line-height: 1.6; white-space: pre-line;">${extrasAvulsos?.descricao_etapa || peca.descricao_etapa || peca.descricao || "Nenhuma instrução especial registrada no sistema para este lote."}</div>
        </div>

        <div style="font-size: 11px; color: #4b5563; text-align: justify; margin-bottom: 20px;">
          <strong>Termo de Responsabilidade:</strong> O prestador de serviço compromete-se a entregar a quantidade descrita acima no prazo estipulado, garantindo os padrões de qualidade exigidos pela empresa contratante. Quaisquer defeitos de produção, danos ou perdas de material deverão ser comunicados imediatamente e poderão sofrer desconto proporcional no valor total deste serviço.
        </div>

        <div class="signatures">
          <div class="sig-box"><div class="sig-line"></div><div class="sig-name">Gestão de Produção</div><div class="sig-role">Contratante / Emissor</div></div>
          <div class="sig-box"><div class="sig-line"></div><div class="sig-name">Parceiro / Fornecedor</div><div class="sig-role">Recebedor / Prestador</div></div>
        </div>

        <div class="footer">Documento gerado automaticamente pelo Sistema Foxie ${dataHoje} às ${horaHoje}.</div>
      </div>
    </body>
    </html>
  `;

  const element = document.createElement("div");

  element.innerHTML = html;

  document.body.appendChild(element);

  const opt = {
    margin: 0,
    filename: `guia.pdf`,
    image: { type: "jpeg", quality: 1 },
    html2canvas: {
      scale: 2,
    },
    jsPDF: {
      unit: "mm",
      format: "a4",
      orientation: "portrait",
    },
  };

  // GERA BLOB PDF
  const pdfBlob = await html2pdf().set(opt).from(element).outputPdf("blob");

  document.body.removeChild(element);

  // Dispara o download local nativamente para não passar em branco para o usuário
  const blobUrlLocal = URL.createObjectURL(pdfBlob);
  const linkLocal = document.createElement("a");
  linkLocal.href = blobUrlLocal;
  linkLocal.download = `OS_Externa_${numeroOS}.pdf`;
  document.body.appendChild(linkLocal);
  linkLocal.click();
  linkLocal.remove();
  URL.revokeObjectURL(blobUrlLocal);

  // Faz o upload pro bucket
  const nomeArquivo = `Comprovante_servico_externo/${peca.id}_${Date.now()}.pdf`;

  const { error } = await supabase.storage
    .from("comprovanteProducao")
    .upload(nomeArquivo, pdfBlob, {
      contentType: "application/pdf",
      upsert: true,
    });

  if (error) {
    console.error(error);
    return;
  }

  // URL pública
  const { data } = supabase.storage
    .from("comprovanteProducao")
    .getPublicUrl(nomeArquivo);

  const urlPDF = data.publicUrl;

  // salva no banco da etapa correspondente (não mais "PDV" travado)
  let queryHistorico = supabase
    .from("kanban_producao_historico")
    .update({
      comprovante_producao_externa: urlPDF,
      comprovante_path_externa: nomeArquivo,
    })
    .eq("producao_id", peca.id);

  if (colunaIdDestino) {
    queryHistorico = queryHistorico.eq("status", colunaIdDestino);
  }

  await queryHistorico;
};

const gerarPDFEnvioLoja = async (
  peca: Peca,
  quantidade: number,
  lojaNome: string,
) => {
  const dataHoje = new Date().toLocaleDateString("pt-BR");

  const horaHoje = new Date().toLocaleTimeString("pt-BR", {
    hour: "2-digit",
    minute: "2-digit",
  });

  const nomeResponsavel =
    userStore.profile?.username || userStore.profile?.nome || "Usuário Web";

  const numeroGuia = Math.floor(Math.random() * 1000000)
    .toString()
    .padStart(6, "0");

  const html = `
    <!DOCTYPE html>
    <html lang="pt-BR">
    <head>
      <meta charset="UTF-8">
      <title>Guia de Remessa - ${numeroGuia}</title>
      <style>
        @page { size: A4 portrait; margin: 15mm; }
        * { box-sizing: border-box; }
        body { font-family: 'Segoe UI', Arial, sans-serif; font-size: 13px; color: #111827; margin: 0; padding: 0; line-height: 1.5; }
        .container { width: 100%; max-width: 190mm; margin: 0 auto; }
        .header { display: flex; width: 100%; border: 2px solid #111827; border-radius: 6px; margin-bottom: 20px; overflow: hidden; }
        .header-title { width: 70%; display: flex; flex-direction: column; justify-content: center; align-items: center; padding: 10px; }
        .header-title h1 { margin: 0; font-size: 18px; text-transform: uppercase; letter-spacing: 1px; color: #111827; text-align: center; }
        .header-title p { margin: 5px 0 0 0; font-size: 14px; font-weight: 600; color: #4b5563; }
        .header-info { width: 30%; border-left: 1px solid #111827; background-color: #f9fafb; padding: 10px; font-size: 12px; }
        .header-info strong { display: inline-block; width: 65px; }
        table { width: 100%; border-collapse: collapse; margin-bottom: 20px; border-radius: 6px; }
        th, td { border: 1px solid #d1d5db; padding: 8px 12px; text-align: left; }
        th { background-color: #f3f4f6; font-size: 12px; text-transform: uppercase; color: #374151; font-weight: 700; width: 25%; }
        td { font-size: 13px; color: #111827; }
        .items-table th { background-color: #e5e7eb; border-color: #9ca3af; text-align: center; }
        .items-table td { border-color: #9ca3af; }
        .items-table .text-center { text-align: center; }
        .signatures { display: flex; justify-content: space-between; margin-top: 60px; padding: 0 20px; }
        .sig-box { width: 40%; text-align: center; }
        .sig-line { border-bottom: 1px solid #111827; margin-bottom: 8px; height: 30px; }
        .sig-name { font-weight: 700; font-size: 12px; text-transform: uppercase; }
        .sig-role { font-size: 11px; color: #6b7280; }
        .footer { margin-top: 40px; text-align: center; font-size: 10px; color: #9ca3af; border-top: 1px solid #e5e7eb; padding-top: 10px; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <div class="header-title">
            <h1>Guia de Remessa / Transferência</h1>
            <p>MERCADORIA PRONTA PARA VENDA</p>
          </div>
          <div class="header-info">
            <div style="margin-bottom: 5px;"><strong>Guia Nº:</strong> <span style="color: #ef4444; font-weight: 700; font-size: 14px;">${numeroGuia}</span></div>
            <div style="margin-bottom: 5px;"><strong>Data:</strong> ${dataHoje}</div>
            <div><strong>Hora:</strong> ${horaHoje}</div>
          </div>
        </div>

        <table>
          <tr><th>Loja Destino</th><td colspan="3" style="font-weight: 800; font-size: 15px; color: #0288d1; text-transform: uppercase;">${lojaNome}</td></tr>
          <tr><th>Emitente (Fábrica)</th><td colspan="3">${nomeResponsavel}</td></tr>
        </table>

        <table class="items-table">
          <tr><th style="width: 50%; text-align: left;">Descrição do Lote / Produto</th><th style="width: 15%;">UN</th><th style="width: 35%;">Quantidade Enviada</th></tr>
          <tr>
            <td><strong>${peca.nome || "N/A"}</strong><br><span style="font-size: 11px; color: #6b7280;">Tecido: ${peca.tecido_nome || "-"} | Estampa: ${peca.estampa_nome || "-"}</span></td>
            <td class="text-center">PC</td>
            <td class="text-center" style="font-weight: bold; font-size: 16px;">${quantidade} un.</td>
          </tr>
        </table>

        <div style="font-size: 12px; color: #4b5563; text-align: justify; margin-bottom: 20px;">
          <strong>Termo de Recebimento:</strong> Confirmo o recebimento das mercadorias listadas acima em perfeitas condições para comercialização. A partir da assinatura, a responsabilidade pelo estoque físico passa a ser do Ponto de Venda.
        </div>

        <div class="signatures">
          <div class="sig-box"><div class="sig-line"></div><div class="sig-name"></div><div class="sig-role">Expedição / Fábrica</div></div>
          <div class="sig-box"><div class="sig-line"></div><div class="sig-name"></div><div class="sig-role">Recebedor / ${lojaNome}</div></div>
        </div>

        <div class="footer">Documento gerado pelo Sistema Foxie às ${horaHoje} do dia ${dataHoje}.</div>
      </div>
    </body>
    </html>
  `;

  const element = document.createElement("div");
  element.innerHTML = html;

  document.body.appendChild(element);

  const opt = {
    margin: 0,
    filename: `guia-${numeroGuia}.pdf`,
    image: { type: "jpeg", quality: 1 },
    html2canvas: {
      scale: 2,
    },
    jsPDF: {
      unit: "mm",
      format: "a4",
      orientation: "portrait",
    },
  };

  // GERA BLOB PDF
  const pdfBlob = await html2pdf().set(opt).from(element).outputPdf("blob");

  document.body.removeChild(element);

  const nomeArquivo = `Comprovante_Envio_Loja/${peca.id}_${Date.now()}.pdf`;

  const { error } = await supabase.storage
    .from("comprovanteProducao")
    .upload(nomeArquivo, pdfBlob, {
      contentType: "application/pdf",
      upsert: true,
    });

  if (error) {
    console.error(error);
    return;
  }

  // URL pública
  const { data } = supabase.storage
    .from("comprovanteProducao")
    .getPublicUrl(nomeArquivo);

  const urlPDF = data.publicUrl;

  // salva no banco
  const {} = await supabase
    .from("kanban_producao_historico")
    .update({
      comprovante_producao_loja: urlPDF,
      comprovante_path: nomeArquivo,
    })
    .eq("producao_id", peca.id)
    .eq("status", "PDV")
    .select();
};

// === EFETIVAR MOVIMENTAÇÕES ===
const confirmarEnvioEstoqueFinal = async () => {
  const pecaOrigem = ConfirmacaoPecaSelecionada.value;
  if (!pecaOrigem) return;
  const totalLote = pecaOrigem.quantidade || 0;

  let qtdFisicaSistema = 0;
  let qtdFisicaPDV = 0;

  if (destinoEstoque.value === "sistema") {
    qtdFisicaSistema = totalLote;
  } else if (destinoEstoque.value === "pdv") {
    qtdFisicaPDV = totalLote;
  } else if (destinoEstoque.value === "ambos") {
    qtdFisicaSistema = Number(qtdEstoqueSistema.value) || 0;
    qtdFisicaPDV = Number(qtdEstoquePDV.value) || 0;
    if (qtdFisicaSistema + qtdFisicaPDV !== totalLote) {
      appStore.showSnackbar(
        "A soma das quantidades deve ser igual ao total do lote.",
        "warning",
      );
      return;
    }
  }

  let lojaSelecionada = null;
  if (qtdFisicaPDV > 0) {
    if (!lojaDestinoSelecionada.value) {
      appStore.showSnackbar(
        "Por favor, selecione a Loja (PDV) que receberá as peças.",
        "warning",
      );
      return;
    }
    lojaSelecionada = listaLojas.value.find(
      (l) => l.id === lojaDestinoSelecionada.value,
    );
  }

  salvando.value = true;
  try {
    if (
      (destinoEstoque.value === "sistema" ||
        destinoEstoque.value === "ambos") &&
      qtdFisicaSistema > 0
    ) {
      if (!pecaOrigem.produto_id) {
        throw new Error(
          "Produto vinculado não encontrado para dar entrada no estoque.",
        );
      }

      const { data: currentStock, error: errFetch } = await supabase
        .from("stock")
        .select("available_meters")
        .eq("id", pecaOrigem.produto_id)
        .single();

      if (errFetch && errFetch.code !== "PGRST116") throw errFetch;

      const qtyBefore = Number(currentStock?.available_meters || 0);
      const qtyAfter = qtyBefore + qtdFisicaSistema;

      const { error: errUpdateStock } = await supabase
        .from("stock")
        .update({ available_meters: qtyAfter })
        .eq("id", pecaOrigem.produto_id);
      if (errUpdateStock) throw errUpdateStock;

      const batchCode = `LOTE-${pecaOrigem.id.substring(0, 8).toUpperCase()}`;

      const quantidadeLote = Number(pecaOrigem.quantidade) || 0;
      const valorTotalLote =
        Number(pecaOrigem.precoUni || pecaOrigem.preco_unitario) || 0;

      const custoPorUnidade =
        quantidadeLote > 0 ? valorTotalLote / quantidadeLote : 0;

      const { data: batchData, error: errBatch } = await supabase
        .from("stock_batches")
        .insert({
          stock_id: pecaOrigem.produto_id,
          batch_code: batchCode,
          initial_qty: qtdFisicaSistema,
          current_qty: qtdFisicaSistema,
          cost_per_unit: custoPorUnidade,
        })
        .select()
        .single();
      if (errBatch) throw errBatch;

      const { error: errLedger } = await supabase.from("stock_ledger").insert({
        stock_id: pecaOrigem.produto_id,
        batch_id: batchData?.id,
        operation_type: "IN",
        qty_changed: qtdFisicaSistema,
        qty_before: qtyBefore,
        qty_after: qtyAfter,
        notes: `Entrada via Produção Kanban - Lote: ${pecaOrigem.nome}`,
        created_by: userStore.profile?.id,
      });
      if (errLedger) throw errLedger;

      const { error: e } = await supabase
        .from("kanban_producao_historico")
        .insert({
          producao_id: pecaOrigem.id,
          status: "sistema",
          perfil_id: userStore.profile?.id,
        });
      if (e) throw e;
    }

    if (
      (destinoEstoque.value === "pdv" || destinoEstoque.value === "ambos") &&
      qtdFisicaPDV > 0 &&
      lojaSelecionada
    ) {
      const { error: epdv } = await supabase
        .from("kanban_producao_historico")
        .insert({
          producao_id: pecaOrigem.id,
          status: "PDV",
          perfil_id: userStore.profile?.id,
        });
      if (epdv) throw epdv;

      gerarPDFEnvioLoja(pecaOrigem, qtdFisicaPDV, lojaSelecionada.name);
    }

    const payloadEstoque: any = {
      status: "estoque",
      descricao_etapa: JSON.stringify({
        sistema: qtdFisicaSistema > 0,
        pdv: qtdFisicaPDV > 0,
        loja: lojaSelecionada?.name || null,
        qtd: qtdFisicaPDV,
      }),
    };

    const { error: e3 } = await supabase
      .from("kanban_producao")
      .update(payloadEstoque)
      .eq("id", pecaOrigem.id);
    if (e3) throw e3;

    appStore.showSnackbar(
      "Envio para estoque concluído com sucesso!",
      "success",
    );
    await buscarProducao();
    fecharModalMoverConfirmar();
  } catch (error: any) {
    console.error(error);
    appStore.showSnackbar(
      `Falha ao concluir envio. Detalhe: ${error.message || JSON.stringify(error)}`,
      "error",
    );
  } finally {
    salvando.value = false;
  }
};

const confirmarMovimentacao = async () => {
  if (!ConfirmacaoPecaSelecionada.value || !colunaDestino.value) return;
  if (
    ConfirmacaoPecaSelecionada.value.tipo_externo === 1 &&
    !ConfirmacaoPecaSelecionada.value.faturado
  ) {
    appStore.showSnackbar(
      "Não é possível avançar. Fature o serviço externo atual (Lançar Contas a Pagar) antes de mover o lote.",
      "error",
    );
    return;
  }
  const nomeDestino = getTituloColuna(colunaDestino.value);
  let isExterno = false;

  if (mostrarCamposExternos.value) {
    if (!novaPeca.descricao_etapa) {
      appStore.showSnackbar(
        "Preencha o campo de Descrição / Instruções Técnicas.",
        "warning",
      );
      return;
    }
    if (!novaPeca.valor_servico) {
      appStore.showSnackbar("Preencha o campo de Valor do serviço.", "warning");
      return;
    }
  }

  if (nomeDestino === "Corte") {
    if (novaPeca.tipo_corte === "interna") {
      if (!novaPeca.operador_corte_id || !novaPeca.maquina_corte_id) {
        appStore.showSnackbar("Selecione operador e máquina.", "warning");
        return;
      }
    } else isExterno = true;
  } else if (nomeDestino === "Costura") {
    if (novaPeca.tipo_costura === "interna") {
      if (!novaPeca.operador_costura_id || !novaPeca.maquina_costura_id) {
        appStore.showSnackbar("Selecione operador e máquina.", "warning");
        return;
      }
    } else isExterno = true;
  } else if (nomeDestino === "Acabamento") {
    if (novaPeca.tipo_acabamento === "interna") {
      if (!novaPeca.operador_acabamento_id || !novaPeca.maquina_acabamento_id) {
        appStore.showSnackbar("Selecione operador e máquina.", "warning");
        return;
      }
    } else isExterno = true;
  }

  salvando.value = true;
  try {
    const pecaAtual = ConfirmacaoPecaSelecionada.value;

    const irmao = pecaEquivalenteNoDestino.value;
    const qtdAvancar =
      tipoAvanco.value === "parcial"
        ? Number(qtdDesmembrada.value)
        : pecaAtual.quantidade || 0;

    if (qtdAvancar <= 0) {
      appStore.showSnackbar(
        "A quantidade a avançar deve ser maior que zero.",
        "error",
      );
      return;
    }

    if (
      tipoAvanco.value === "parcial" &&
      qtdAvancar >= (pecaAtual.quantidade || 0)
    ) {
      appStore.showSnackbar(
        "Para avançar todo o lote, selecione a opção de avanço completo.",
        "warning",
      );
      return;
    }

    const dadosExtrasEtapa: Record<string, any> = {
      tipo_externo: isExterno ? 1 : 0,
    };

    if (isExterno) {
      dadosExtrasEtapa.descricao_etapa = novaPeca.descricao_etapa;
      dadosExtrasEtapa.valor_servico =
        parseFloat(novaPeca.valor_servico) || null;
    }

    if (nomeDestino === "Corte") {
      dadosExtrasEtapa.tipo_corte = novaPeca.tipo_corte || "interna"; // SALVANDO NO BANCO
      if (!isExterno) {
        dadosExtrasEtapa.maquina_corte_id = novaPeca.maquina_corte_id || null;
        dadosExtrasEtapa.operador_corte_id = novaPeca.operador_corte_id || null;
      }
    }
    if (nomeDestino === "Costura") {
      dadosExtrasEtapa.tipo_costura = novaPeca.tipo_costura || "interna"; // SALVANDO NO BANCO
      if (!isExterno) {
        dadosExtrasEtapa.maquina_costura_id =
          novaPeca.maquina_costura_id || null;
        dadosExtrasEtapa.operador_costura_id =
          novaPeca.operador_costura_id || null;
      }
    }
    if (nomeDestino === "Acabamento") {
      dadosExtrasEtapa.tipo_acabamento = novaPeca.tipo_acabamento || "interna"; // SALVANDO NO BANCO
      if (!isExterno) {
        dadosExtrasEtapa.maquina_acabamento_id =
          novaPeca.maquina_acabamento_id || null;
        dadosExtrasEtapa.operador_acabamento_id =
          novaPeca.operador_acabamento_id || null;
      }
    }

    const { expanded, id, created_at, ...pecaLimpaParaDB } = pecaAtual;

    let idPecaNoDestino = pecaAtual.id;

    if (tipoAvanco.value === "parcial") {
      const { error: err1 } = await supabase
        .from("kanban_producao")
        .update({ quantidade: (pecaAtual.quantidade || 0) - qtdAvancar })
        .eq("id", pecaAtual.id);
      if (err1) throw err1;

      if (irmao && tipoAvanco.value !== "completo_separado") {
        const { error: err2 } = await supabase
          .from("kanban_producao")
          .update({
            quantidade: (irmao.quantidade || 0) + qtdAvancar,
            nome: getBaseName(pecaAtual.nome),
            ...dadosExtrasEtapa,
          })
          .eq("id", irmao.id);
        if (err2) throw err2;
        idPecaNoDestino = irmao.id;
      } else {
        const { data: novaPecaCriada, error: err3 } = await supabase
          .from("kanban_producao")
          .insert([
            {
              ...pecaLimpaParaDB,
              nome: `${getBaseName(pecaAtual.nome)} (Desmembrado)`,
              quantidade: qtdAvancar,
              status: colunaDestino.value,
              ...dadosExtrasEtapa,
            },
          ])
          .select()
          .single();
        if (err3) throw err3;
        idPecaNoDestino = novaPecaCriada.id;
      }
    } else {
      if (irmao && tipoAvanco.value !== "completo_separado") {
        const { error: err4 } = await supabase
          .from("kanban_producao")
          .update({
            quantidade: (irmao.quantidade || 0) + (pecaAtual.quantidade || 0),
            nome: getBaseName(pecaAtual.nome),
            ...dadosExtrasEtapa,
          })
          .eq("id", irmao.id);
        if (err4) throw err4;

        idPecaNoDestino = irmao.id;
        const { error: err5 } = await supabase
          .from("kanban_producao")
          .delete()
          .eq("id", pecaAtual.id);
        if (err5) throw err5;
      } else {
        const { error: err6 } = await supabase
          .from("kanban_producao")
          .update({
            status: colunaDestino.value,
            ...dadosExtrasEtapa,
            nome: getBaseName(pecaAtual.nome),
          })
          .eq("id", pecaAtual.id);
        if (err6) throw err6;
        idPecaNoDestino = pecaAtual.id;
      }
    }

    if (isExterno) {
      // Buscar os dados frescos pra ter certeza que a ficha será gerada pra peça certa
      const { data: freshPeca } = await supabase
        .from("kanban_producao")
        .select("*")
        .eq("id", idPecaNoDestino)
        .single();
      if (freshPeca) {
        gerarPDFOrdemServico(
          freshPeca,
          nomeDestino,
          {
            quantidadeMove: qtdAvancar,
            valor_servico: novaPeca.valor_servico,
            descricao_etapa: novaPeca.descricao_etapa,
          },
          colunaDestino.value,
        );
      }
    }

    appStore.showSnackbar("Movimentação concluída com sucesso!", "success");
    await buscarProducao();
    fecharModalMoverConfirmar();
  } catch (error: any) {
    console.error(error);
    appStore.showSnackbar(
      `Falha na movimentação de Produção. Detalhe: ${error.message || JSON.stringify(error)}`,
      "error",
    );
  } finally {
    salvando.value = false;
  }
};

const getTituloColuna = (id: string) =>
  colunas.find((c) => c.id === id)?.titulo || "";
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
  max-width: 300px;
  height: 100%;
  display: flex;
  flex-direction: column;
  transition: all 0.3s ease;
  user-select: none;
  margin-top: 10px;
  background-color: rgba(255, 255, 255, 0.035);
}

.column-content {
  overflow: auto;
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

/* KPIs Estilo */
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
  letter-spacing: 0.2px;
  text-transform: uppercase;
}

.kpi-value {
  font-size: 22px;
  font-weight: 900;
}

.kpi-footer {
  font-size: 11px;
  opacity: 0.9;
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
  background: linear-gradient(135deg, #ffb300, #f57f17) !important;
}

.hover-elevate {
  transition:
    transform 0.2s ease,
    box-shadow 0.2s ease;
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

@media (min-width: 1600px) {
  .kanban-column {
    flex: 1;
    max-width: 400px;
  }
}
@media (max-width: 960px) {
  .column-content {
    overflow: auto;
    padding-bottom: 20px;
  }
}
</style>