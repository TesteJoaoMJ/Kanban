<template>
  <div
    class="clients-layout font-sans fill-height d-flex flex-column relative overflow-hidden"
    :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 text-grey-darken-4' : 'bg-glass-dark text-white'"
  >
    <div v-if="themeStore.currentMode !== 'light'" class="background-carousel-wrapper">
      <div class="background-overlay"></div>
    </div>

    <Transition name="context-island-float">
      <div v-show="isContextIslandFloating" class="floating-context-island">
        <div class="floating-island-inner">
          <v-btn
            v-for="btn in tenantContextButtons"
            :key="btn.id"
            size="x-small"
            height="26"
            :variant="companyStore.context === btn.id ? 'flat' : 'text'"
            :color="companyStore.context === btn.id ? (btn.isHolding ? 'blue-grey-darken-4' : btn.color) : undefined"
            class="font-weight-black btn-context-3d floating-context-btn rounded-lg"
            :class="companyStore.context === btn.id ? 'btn-context-active' : 'btn-context-idle'"
            @click="setTenantContext(btn.id)"
          >
            {{ btn.name }}
          </v-btn>
        </div>
      </div>
    </Transition>

    <div class="content-wrapper d-flex flex-column fill-height z-10 relative">
      <div
        class="header-bar px-6 py-4 d-flex align-center justify-space-between flex-shrink-0"
        :class="themeStore.currentMode === 'light' ? 'bg-white border-b border-grey-lighten-2 shadow-sm' : 'bg-glass-header border-bottom-white-05'"
      >
        <div class="d-flex flex-column">
          <div class="breadcrumb text-caption font-weight-bold text-uppercase tracking-widest opacity-70 mb-1">
            Cadastros &gt; Clientes
          </div>
          <div
            class="text-h5 font-weight-black tracking-tight leading-none"
            :class="themeStore.currentMode === 'light' ? 'text-primary-darken-2' : 'text-white'"
          >
            Base de Clientes e CRM
          </div>
          <div class="text-caption font-weight-bold opacity-60 mt-1">
            Carteira filtrada por empresa, crédito e histórico comercial.
          </div>

          <Transition name="context-dock">
            <div v-show="!isContextIslandFloating" class="context-switcher-docked d-flex align-center flex-wrap mt-3">
              <v-btn
                v-for="btn in tenantContextButtons"
                :key="btn.id"
                size="x-small"
                height="24"
                :variant="companyStore.context === btn.id ? 'flat' : 'elevated'"
                :color="companyStore.context === btn.id ? (btn.isHolding ? 'blue-grey-darken-4' : btn.color) : undefined"
                class="font-weight-black btn-context-3d btn-context-pill px-3 rounded-lg flex-shrink-0"
                :class="companyStore.context === btn.id ? 'btn-context-active' : 'btn-context-idle'"
                @click="setTenantContext(btn.id)"
              >
                {{ btn.name }}
              </v-btn>
            </div>
          </Transition>
        </div>

        <div class="d-flex align-center flex-wrap" style="gap: 12px;">
          <v-btn
            color="primary"
            variant="flat"
            class="btn-3d px-6 font-weight-black text-caption text-uppercase tracking-widest"
            prepend-icon="mdi-account-plus"
            height="42"
            @click="openNewClientModal"
          >
            Novo Cliente
          </v-btn>

          <v-btn
            class="btn-3d font-weight-bold"
            height="42"
            prepend-icon="mdi-export-variant"
            color="blue-grey-darken-3"
            @click="actionsModal.show = true"
          >
            Relatórios
          </v-btn>
        </div>
      </div>

      <div class="px-6 pt-5 pb-2 flex-shrink-0">
        <v-row dense>
          <v-col cols="12" sm="6" md="3" v-for="(kpi, idx) in kpiList" :key="idx">
            <v-card class="kpi-card kpi-3d kpi-subtle py-3 px-4 cursor-pointer" :class="kpi.gradient" v-ripple>
              <div class="kpi-bg-icon"><v-icon>{{ kpi.icon }}</v-icon></div>
              <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                <div class="d-flex align-center gap-2 mb-1">
                  <v-icon size="18" class="opacity-90 text-white">{{ kpi.icon }}</v-icon>
                  <span class="kpi-label text-white">{{ kpi.label }}</span>
                </div>
                <div class="kpi-number-group my-1">
                  <span class="text-h4 font-weight-black text-white font-mono lh-1">{{ kpi.value }}</span>
                </div>
                <div class="kpi-footer mt-1 text-white">{{ kpi.footer }}</div>
              </div>
            </v-card>
          </v-col>
        </v-row>
      </div>

      <div class="px-4 px-md-6 pt-2 pt-md-4 pb-2 flex-shrink-0">
        <div
          class="clients-taskbar d-flex flex-column gap-3"
          :class="themeStore.currentMode === 'light' ? 'clients-taskbar-light' : 'clients-taskbar-dark'"
        >
          <div class="taskbar-main">
            <div
              class="search-wrap taskbar-search d-flex align-center"
              :class="themeStore.currentMode === 'light' ? 'search-light' : 'search-dark'"
            >
              <v-icon :color="themeStore.currentMode === 'light' ? 'grey-darken-1' : 'white-70'">mdi-magnify</v-icon>
              <input
                v-model="search"
                type="text"
                placeholder="Buscar cliente, documento, responsável ou cidade..."
                class="clean-input flex-grow-1 px-2"
                style="font-size: 13px;"
                @input="page = 1"
              />
            </div>

            <div class="taskbar-right">
              <v-menu location="bottom end" :close-on-content-click="false">
                <template v-slot:activator="{ props }">
                  <v-btn
                    v-bind="props"
                    variant="flat"
                    color="primary"
                    class="btn-3d font-weight-black taskbar-action-btn"
                    height="42"
                    prepend-icon="mdi-filter-variant"
                    append-icon="mdi-chevron-down"
                  >
                    Filtros
                  </v-btn>
                </template>

                <v-card
                  class="clients-filter-tray rounded-xl border-thin shadow-xl"
                  :class="themeStore.currentMode === 'light' ? 'clients-filter-tray-light' : 'clients-filter-tray-dark text-white'"
                  width="380"
                >
                  <div class="tray-header pa-3 d-flex align-center justify-space-between">
                    <div class="d-flex align-center">
                      <div class="tray-icon mr-3"><v-icon size="18">mdi-filter-variant</v-icon></div>
                      <div>
                        <div class="text-subtitle-2 font-weight-black">Filtros da carteira</div>
                        <div class="text-caption opacity-70">Vendedor, situação e crédito.</div>
                      </div>
                    </div>
                  </div>

                  <div class="tray-section px-3 pb-3">
                    <div class="tray-section-title mb-2">Vendedor responsável</div>
                    <v-select
                      v-model="currentSellerFilter"
                      :items="sellerFilterOptions"
                      item-title="label"
                      item-value="value"
                      variant="outlined"
                      density="compact"
                      hide-details
                      class="tray-field font-weight-bold"
                      prepend-inner-icon="mdi-account-tie"
                      @update:model-value="page = 1"
                    />
                  </div>

                  <div class="tray-section px-3 pb-3">
                    <div class="tray-section-title mb-2">Situação da carteira</div>
                    <div class="tray-chip-grid">
                      <button
                        v-for="status in statusFilters"
                        :key="status.value"
                        type="button"
                        class="tray-chip-btn"
                        :class="currentStatusFilter === status.value ? 'tray-chip-btn--active' : ''"
                        @click="currentStatusFilter = status.value; page = 1"
                      >
                        {{ status.label }}
                      </button>
                    </div>
                  </div>

                  <div class="tray-footer px-3 pb-3">
                    <v-btn
                      block
                      variant="tonal"
                      color="error"
                      class="btn-3d-subtle font-weight-black"
                      height="38"
                      @click="currentSellerFilter = 'all'; currentStatusFilter = 'active'; page = 1"
                    >
                      Limpar filtros
                    </v-btn>
                  </div>
                </v-card>
              </v-menu>

              <v-menu location="bottom end">
                <template v-slot:activator="{ props }">
                  <v-btn
                    v-bind="props"
                    variant="outlined"
                    class="btn-3d font-weight-bold taskbar-action-btn"
                    height="42"
                    prepend-icon="mdi-dots-grid"
                    append-icon="mdi-chevron-down"
                    :color="themeStore.currentMode === 'light' ? 'grey-darken-2' : 'white'"
                  >
                    Mais ações
                  </v-btn>
                </template>

                <v-card
                  class="clients-filter-tray rounded-xl border-thin shadow-xl"
                  :class="themeStore.currentMode === 'light' ? 'clients-filter-tray-light' : 'clients-filter-tray-dark text-white'"
                  width="340"
                >
                  <div class="tray-header pa-3 d-flex align-center">
                    <div class="tray-icon mr-3"><v-icon size="18">mdi-dots-grid</v-icon></div>
                    <div>
                      <div class="text-subtitle-2 font-weight-black">Mais ações</div>
                      <div class="text-caption opacity-70">Relatórios e atualização.</div>
                    </div>
                  </div>

                  <div class="tray-section px-3 pb-3">
                    <button class="tray-action" type="button" @click="fetchClients">
                      <span class="tray-action-icon text-blue-grey"><v-icon size="18">mdi-refresh</v-icon></span>
                      <span>
                        <strong>Atualizar clientes</strong>
                        <small>Recarrega carteira, vendas e bloqueios.</small>
                      </span>
                    </button>

                    <button class="tray-action" type="button" @click="exportExcel">
                      <span class="tray-action-icon text-success"><v-icon size="18">mdi-file-excel</v-icon></span>
                      <span>
                        <strong>Exportar CSV</strong>
                        <small>Baixa a carteira filtrada.</small>
                      </span>
                    </button>

                    <button class="tray-action" type="button" @click="exportPDF">
                      <span class="tray-action-icon text-error"><v-icon size="18">mdi-file-pdf-box</v-icon></span>
                      <span>
                        <strong>Exportar PDF</strong>
                        <small>Relatório visual da carteira.</small>
                      </span>
                    </button>
                  </div>
                </v-card>
              </v-menu>

              <v-chip
                label
                size="small"
                color="primary"
                variant="tonal"
                class="tenant-status-chip font-weight-black text-uppercase tracking-widest"
              >
                {{ currentTenantLabel }}
              </v-chip>
            </div>
          </div>
        </div>
      </div>

      <v-expand-transition>
        <div v-if="selectedClients.length > 0" class="px-6 pb-3 flex-shrink-0">
          <div
            class="d-flex align-center justify-space-between pa-3 rounded-lg shadow-sm border-thin"
            :class="themeStore.currentMode === 'light' ? 'bg-blue-lighten-5 border-blue-lighten-3' : 'bg-blue-darken-4 bg-opacity-20 border-blue-darken-3'"
          >
            <div class="d-flex align-center gap-3">
              <v-avatar color="primary" size="36" variant="flat" class="rounded btn-3d">
                <v-icon size="18" color="white">mdi-checkbox-multiple-marked</v-icon>
              </v-avatar>
              <span class="font-weight-black text-body-1 text-primary">
                {{ selectedClients.length }} cliente(s) selecionado(s)
              </span>
            </div>
            <div class="d-flex align-center gap-3">
              <v-btn
                color="primary"
                variant="flat"
                class="btn-3d font-weight-bold px-6"
                prepend-icon="mdi-account-arrow-right"
                @click="bulkAssignModal.show = true"
              >
                Atribuir Vendedor
              </v-btn>
              <v-btn
                color="warning"
                variant="flat"
                class="btn-3d font-weight-bold px-6"
                prepend-icon="mdi-account-cancel-outline"
                @click="bulkBlockModal.show = true"
              >
                Bloquear em Lote
              </v-btn>
              <v-btn variant="text" class="font-weight-bold" color="grey-darken-1" @click="selectedClients = []">
                Cancelar
              </v-btn>
            </div>
          </div>
        </div>
      </v-expand-transition>

      <div class="flex-grow-1 px-6 pb-6 overflow-hidden d-flex flex-column">
        <v-card
          class="clients-grid-card flex-grow-1 d-flex flex-column rounded-0 border-thin overflow-hidden"
          :class="themeStore.currentMode === 'light' ? 'bg-white' : 'glass-card border-white-05'"
          :elevation="0"
        >
          <div class="grid-scroll flex-grow-1 overflow-y-auto custom-scroll">
            <div
              class="grid-header sticky-head grid-layout"
              :class="[themeStore.currentMode === 'light' ? 'grid-surface-light border-b border-grey-lighten-2' : 'grid-surface-dark border-b border-white-10']"
            >
              <div class="cell center header-text">
                <v-checkbox-btn v-model="selectAll" density="compact" color="primary" class="chk-fixed" />
              </div>
              <div class="cell header-text">Cliente / Fantasia</div>
              <div class="cell center header-text">Tipo</div>
              <div class="cell header-text">Documento</div>
              <div class="cell header-text">Contato</div>
              <div class="cell header-text">Responsável</div>
              <div class="cell header-text">Cidade / UF</div>
              <div class="cell center header-text">Última Compra</div>
              <div class="cell center header-text">LTV</div>
              <div class="cell center header-text">Status</div>
              <div class="cell center header-text">Crédito</div>
              <div class="cell center header-text">Ações</div>
            </div>

            <div v-if="loading" class="d-flex flex-column justify-center align-center h-100 py-12" style="min-width: 1500px;">
              <v-progress-circular indeterminate color="primary" size="48" width="4" />
            </div>

            <div
              v-else-if="filteredClients.length === 0"
              class="d-flex flex-column justify-center align-center h-100 opacity-50 gap-3 py-12"
              style="min-width: 1500px;"
            >
              <v-icon size="64" color="grey-lighten-1">mdi-account-search-outline</v-icon>
              <span class="text-h6 font-weight-bold text-grey">Nenhum cliente encontrado nesta visão.</span>
            </div>

            <div
              v-else
              v-for="(client, idx) in paginatedClients"
              :key="client.id"
              class="grid-row grid-layout transition-all"
              :class="[themeStore.currentMode === 'light' ? 'grid-row-light' : 'grid-row-dark', client.is_delinquent ? 'client-row-blocked' : '']"
            >
              <div class="cell center">
                <v-checkbox-btn v-model="selectedClients" :value="client.id" density="compact" color="primary" class="chk-fixed" />
              </div>

              <div class="cell">
                <v-avatar
                  v-if="client.avatar_url"
                  :image="client.avatar_url"
                  size="32"
                  class="rounded mr-3 flex-shrink-0 border-thin"
                />
                <v-avatar
                  v-else
                  :color="getColor(client.nome_fantasia || client.nome)"
                  size="32"
                  variant="tonal"
                  class="rounded mr-3 flex-shrink-0 font-weight-black text-caption border-thin"
                >
                  {{ (client.nome_fantasia || client.nome)?.charAt(0)?.toUpperCase() }}
                </v-avatar>

                <div class="d-flex flex-column min-w-0">
                  <div class="d-flex align-center min-w-0">
                    <span class="text-truncate list-text-11 font-weight-bold mr-2" :title="client.nome_fantasia || client.nome">
                      {{ client.nome_fantasia || client.nome }}
                    </span>
                    <v-icon v-if="client.is_delinquent" size="15" color="error" title="Cliente inadimplente">
                      mdi-alert-octagon
                    </v-icon>
                  </div>
                  <span v-if="client.razao_social && client.razao_social !== client.nome" class="text-[10px] opacity-60 text-truncate">
                    {{ client.razao_social }}
                  </span>
                </div>
              </div>

              <div class="cell center">
                <v-chip size="x-small" :color="getPersonType(client) === 'PJ' ? 'indigo' : 'blue-grey'" variant="tonal" class="font-weight-black px-3">
                  {{ getPersonType(client) }}
                </v-chip>
              </div>

              <div class="cell">
                <span class="list-text-10 font-mono font-weight-bold opacity-90">
                  {{ formatDocument(client.cpf || client.cnpj) }}
                </span>
              </div>

              <div class="cell">
                <span class="list-text-10 font-weight-medium text-truncate opacity-90">
                  {{ client.celular || client.telefone || 'S/ Tel' }}
                  <span class="mx-1 opacity-50">|</span>
                  {{ client.email || 'S/ Email' }}
                </span>
              </div>

              <div class="cell">
                <span
                  class="list-text-10 font-weight-bold text-truncate"
                  :class="isClientActive(client) ? (themeStore.currentMode === 'light' ? 'text-black' : 'text-white') : 'text-decoration-line-through opacity-50'"
                  v-if="client.responsible_salesperson"
                >
                  <v-icon size="14" color="amber-darken-3" class="mr-1">mdi-crown</v-icon>
                  {{ client.responsible_salesperson?.full_name }}
                </span>
                <span class="text-body-2 font-weight-bold text-info text-truncate" v-else-if="client.suggested_seller_id">
                  {{ getSellerName(client.suggested_seller_id) }} (Sug)
                </span>
                <span class="text-body-2 font-weight-bold text-error" v-else>
                  Sem Dono
                </span>
              </div>

              <div class="cell">
                <span class="list-text-10 text-truncate font-weight-bold" v-if="client.cidade || client.estado">
                  {{ client.cidade }}<span v-if="client.cidade && client.estado"> - </span>{{ client.estado }}
                </span>
                <span v-else class="text-caption opacity-40 font-italic">Não informado</span>
              </div>

              <div class="cell center">
                <span
                  class="list-text-10 font-mono font-weight-bold"
                  :class="!client.last_purchase_date ? 'text-grey' : (isClientActive(client) ? 'text-success' : 'text-error')"
                >
                  {{ client.last_purchase_date ? formatDate(client.last_purchase_date) : 'Nunca' }}
                </span>
              </div>

              <div class="cell center">
                <span class="list-text-11 font-mono font-weight-black text-primary">
                  {{ formatCurrency(client.total_spent) }}
                </span>
              </div>

              <div class="cell center">
                <v-chip
                  size="small"
                  :color="isClientActive(client) ? 'success' : 'error'"
                  variant="flat"
                  class="font-weight-black text-uppercase chip-3d px-3 tracking-widest"
                >
                  {{ isClientActive(client) ? 'ATIVO' : 'INATIVO' }}
                </v-chip>
              </div>

              <div class="cell center">
                <v-chip
                  v-if="client.is_delinquent"
                  size="small"
                  color="error"
                  variant="flat"
                  class="font-weight-black text-uppercase chip-3d px-3 tracking-widest"
                  title="Cliente bloqueado para novos pedidos"
                >
                  <v-icon start size="14">mdi-account-cancel</v-icon>
                  INADIMPLENTE
                </v-chip>
                <v-chip
                  v-else
                  size="small"
                  color="success"
                  variant="tonal"
                  class="font-weight-black text-uppercase px-3 tracking-widest"
                >
                  <v-icon start size="14">mdi-check-circle</v-icon>
                  LIBERADO
                </v-chip>
              </div>

              <div class="cell center">
                <div class="actions-inline">
                  <v-btn icon size="small" variant="flat" color="primary" class="action-btn btn-3d" @click.stop="openEditModal(client)" title="Editar">
                    <v-icon size="16">mdi-pencil</v-icon>
                  </v-btn>

                  <v-btn icon size="small" variant="flat" color="info" class="action-btn btn-3d" @click.stop="openHistoryModal(client)" title="Histórico">
                    <v-icon size="16">mdi-history</v-icon>
                  </v-btn>

                  <v-btn
                    icon
                    size="small"
                    variant="flat"
                    :color="client.is_delinquent ? 'success' : 'warning'"
                    class="action-btn btn-3d"
                    :title="client.is_delinquent ? 'Liberar cliente para novos pedidos' : 'Marcar cliente como inadimplente'"
                    @click.stop="toggleClientDelinquency(client)"
                  >
                    <v-icon size="16">
                      {{ client.is_delinquent ? 'mdi-account-check-outline' : 'mdi-account-cancel-outline' }}
                    </v-icon>
                  </v-btn>

                  <v-btn icon size="small" variant="flat" color="error" class="action-btn btn-3d" @click.stop="openDeleteModal(client)" title="Excluir">
                    <v-icon size="16">mdi-trash-can-outline</v-icon>
                  </v-btn>
                </div>
              </div>
            </div>
          </div>

          <div
            class="flex-shrink-0 border-t px-6 py-3 d-flex align-center justify-space-between"
            :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-black-40 border-white-10'"
          >
            <div class="text-caption font-weight-bold opacity-80 text-uppercase tracking-widest">
              Total: <strong class="text-primary">{{ filteredClients.length }}</strong> clientes |
              Página {{ page }} de {{ totalPages || 1 }}
            </div>
            <v-pagination
              v-model="page"
              :length="totalPages || 1"
              :total-visible="5"
              density="compact"
              active-color="primary"
              variant="tonal"
              size="small"
              class="font-weight-bold"
            />
          </div>
        </v-card>
      </div>
    </div>

    <!-- MODAL FIXO E MAIS LIMPO -->
    <v-dialog
      v-model="editModal.show"
      width="1040"
      max-width="96vw"
      persistent
      scrim="black opacity-80"
      transition="dialog-bottom-transition"
    >
      <v-card
        class="client-editor-card rounded-xl border-thin shadow-2xl"
        :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-grey-darken-4 text-white'"
      >
        <div class="editor-header-clean">
          <div class="d-flex align-center gap-3 min-w-0">
            <v-avatar
              size="44"
              :color="editModal.form.is_delinquent ? 'error' : 'primary'"
              variant="tonal"
              class="rounded-lg"
            >
              <v-icon>{{ editModal.isNew ? 'mdi-account-plus' : 'mdi-account-edit' }}</v-icon>
            </v-avatar>
            <div class="min-w-0">
              <div class="text-caption font-weight-black text-uppercase tracking-widest opacity-60">
                {{ editModal.isNew ? 'Novo cadastro' : 'Edição cadastral' }}
              </div>
              <div class="text-h6 font-weight-black text-truncate">
                {{ editModal.form.nome || editModal.form.nome_fantasia || 'Cliente sem nome' }}
              </div>
            </div>
          </div>

          <div class="d-flex align-center gap-2">
            <v-chip
              :color="editModal.form.is_delinquent ? 'error' : 'success'"
              variant="flat"
              class="font-weight-black text-uppercase chip-3d px-4"
            >
              <v-icon start size="16">
                {{ editModal.form.is_delinquent ? 'mdi-lock-alert' : 'mdi-lock-open-check' }}
              </v-icon>
              {{ editModal.form.is_delinquent ? 'Bloqueado no NewOrder' : 'Liberado no NewOrder' }}
            </v-chip>

            <v-btn icon="mdi-close" variant="text" class="btn-3d-subtle" @click="editModal.show = false" />
          </div>
        </div>

        <div class="editor-body-fixed">
          <aside class="editor-side-clean">
            <div class="avatar-clean-box">
              <v-avatar
                size="88"
                :color="editModal.form.avatar_url ? 'transparent' : 'primary'"
                variant="tonal"
                class="rounded-lg cursor-pointer btn-3d-subtle"
                @click="avatarInputRef?.click()"
              >
                <v-img v-if="editModal.form.avatar_url" :src="editModal.form.avatar_url" cover />
                <v-icon v-else size="42">mdi-camera-plus</v-icon>
                <v-overlay :model-value="editModal.uploadingAvatar" contained class="align-center justify-center">
                  <v-progress-circular indeterminate color="primary" size="24" />
                </v-overlay>
              </v-avatar>

              <div class="mt-3 text-caption font-weight-black text-uppercase tracking-widest opacity-70 cursor-pointer" @click="avatarInputRef?.click()">
                Alterar foto
              </div>
              <input type="file" ref="avatarInputRef" accept="image/*" class="d-none" @change="(e) => handleFileUpload(e, 'avatar')" />
            </div>

            <div class="side-stat-card mt-4">
              <div class="side-stat-label">Empresa da visão</div>
              <div class="side-stat-value">{{ currentTenantLabel }}</div>
            </div>

            <div class="side-stat-card mt-3">
              <div class="side-stat-label">Limite de crédito</div>
              <div class="side-stat-value">{{ formatCurrency(editModal.form.credit_limit || 0) }}</div>
            </div>

            <div class="side-stat-card mt-3" :class="editModal.form.is_delinquent ? 'side-danger' : 'side-success'">
              <div class="side-stat-label">Situação comercial</div>
              <div class="side-stat-value">
                {{ editModal.form.is_delinquent ? 'Inadimplente' : 'Liberado' }}
              </div>
              <div class="side-stat-hint">
                {{ editModal.form.is_delinquent ? 'Bloqueia novos pedidos.' : 'Pode gerar pedidos.' }}
              </div>
            </div>
          </aside>

          <main class="editor-main-clean">
            <div class="editor-tabs-clean">
              <v-tabs v-model="editModal.tab" color="primary" density="comfortable" class="modern-tabs">
                <v-tab value="basic" class="font-weight-black text-caption tracking-widest">
                  <v-icon start size="small">mdi-card-account-details</v-icon>
                  Identificação
                </v-tab>
                <v-tab value="address" class="font-weight-black text-caption tracking-widest">
                  <v-icon start size="small">mdi-map-marker-radius</v-icon>
                  Endereço
                </v-tab>
                <v-tab value="finance" class="font-weight-black text-caption tracking-widest">
                  <v-icon start size="small">mdi-shield-account</v-icon>
                  Crédito
                </v-tab>
                <v-tab value="acquisition" class="font-weight-black text-caption tracking-widest">
                  <v-icon start size="small">mdi-source-branch</v-icon>
                  Origem
                </v-tab>
              </v-tabs>
            </div>

            <div class="editor-scroll-fixed custom-scroll">
              <v-form @submit.prevent="saveClient" id="clientFormRef" ref="formRef">
                <v-window v-model="editModal.tab" class="overflow-visible">
                  <v-window-item value="basic">
                    <section class="modal-section-clean">
                      <div class="section-title-row-clean">
                        <div>
                          <div class="section-title-clean">Dados principais</div>
                          <div class="section-subtitle-clean">Informações básicas usadas em pedidos e financeiro.</div>
                        </div>
                      </div>

                      <v-row dense class="row-gap">
                        <v-col cols="12" md="3">
                          <label class="input-label">Tipo</label>
                          <v-select v-model="editModal.form.person_type" :items="['PF', 'PJ']" variant="outlined" density="compact" color="primary" class="ui-field font-weight-bold" />
                        </v-col>

                        <v-col cols="12" md="5">
                          <label class="input-label">{{ editModal.form.person_type === 'PJ' ? 'CNPJ' : 'CPF' }}</label>
                          <v-text-field
                            v-model="editModal.form.cpf_cnpj"
                            variant="outlined"
                            density="compact"
                            color="primary"
                            class="ui-field font-weight-bold font-mono"
                            :loading="editModal.searchingCnpj"
                            :append-inner-icon="editModal.form.person_type === 'PJ' ? 'mdi-magnify' : ''"
                            @click:append-inner="searchCnpj"
                          />
                        </v-col>

                        <v-col cols="12" md="4">
                          <label class="input-label">Vendedor Responsável</label>
                          <v-autocomplete
                            v-model="editModal.form.vendedor_responsavel_id"
                            :items="salespeopleList"
                            item-title="full_name"
                            item-value="id"
                            variant="outlined"
                            density="compact"
                            color="amber-darken-3"
                            class="ui-field font-weight-bold"
                            prepend-inner-icon="mdi-crown"
                            :disabled="!userStore.isAdmin"
                          />
                        </v-col>

                        <v-col cols="12" md="6">
                          <label class="input-label">Nome Fantasia / Apelido *</label>
                          <v-text-field v-model="editModal.form.nome" variant="outlined" density="compact" color="primary" class="ui-field font-weight-bold" :rules="[v => !!v || 'Obrigatório']" />
                        </v-col>

                        <v-col cols="12" md="6">
                          <label class="input-label">Razão Social / Nome Completo</label>
                          <v-text-field v-model="editModal.form.razao_social" variant="outlined" density="compact" color="primary" class="ui-field" />
                        </v-col>

                        <v-col cols="12" md="4">
                          <label class="input-label">Telefone / WhatsApp</label>
                          <v-text-field v-model="editModal.form.telefone" variant="outlined" density="compact" color="primary" class="ui-field font-weight-bold font-mono" prepend-inner-icon="mdi-whatsapp" />
                        </v-col>

                        <v-col cols="12" md="5">
                          <label class="input-label">E-mail Principal</label>
                          <v-text-field v-model="editModal.form.email" variant="outlined" density="compact" color="primary" class="ui-field font-weight-medium" prepend-inner-icon="mdi-email-outline" />
                        </v-col>

                        <v-col cols="12" md="3">
                          <label class="input-label">Situação</label>
                          <v-select v-model="editModal.form.situacao" :items="['Ativo', 'Inativo']" variant="outlined" density="compact" color="primary" class="ui-field font-weight-bold" />
                        </v-col>

                        <v-col cols="12" v-if="editModal.form.person_type === 'PJ'">
                          <label class="input-label">Porte da Empresa</label>
                          <v-select
                            v-model="editModal.form.company_size"
                            :items="['MEI', 'ME', 'EPP', 'Médio Porte', 'Grande Porte']"
                            variant="outlined"
                            density="compact"
                            color="primary"
                            class="ui-field font-weight-bold"
                          />
                        </v-col>
                      </v-row>
                    </section>
                  </v-window-item>

                  <v-window-item value="address">
                    <section class="modal-section-clean">
                      <div class="section-title-row-clean">
                        <div>
                          <div class="section-title-clean">Endereço</div>
                          <div class="section-subtitle-clean">Dados de entrega, cobrança e faturamento.</div>
                        </div>
                      </div>

                      <v-row dense class="row-gap">
                        <v-col cols="12" md="3">
                          <label class="input-label">CEP</label>
                          <v-text-field v-model="editModal.form.cep" variant="outlined" density="compact" color="primary" class="ui-field font-weight-bold font-mono" />
                        </v-col>

                        <v-col cols="12" md="7">
                          <label class="input-label">Logradouro / Rua</label>
                          <v-text-field v-model="editModal.form.endereco" variant="outlined" density="compact" color="primary" class="ui-field font-weight-medium" />
                        </v-col>

                        <v-col cols="12" md="2">
                          <label class="input-label">Número</label>
                          <v-text-field v-model="editModal.form.numero" variant="outlined" density="compact" color="primary" class="ui-field font-weight-bold" />
                        </v-col>

                        <v-col cols="12" md="5">
                          <label class="input-label">Bairro</label>
                          <v-text-field v-model="editModal.form.bairro" variant="outlined" density="compact" color="primary" class="ui-field font-weight-medium" />
                        </v-col>

                        <v-col cols="12" md="5">
                          <label class="input-label">Cidade</label>
                          <v-text-field v-model="editModal.form.cidade" variant="outlined" density="compact" color="primary" class="ui-field font-weight-medium" />
                        </v-col>

                        <v-col cols="12" md="2">
                          <label class="input-label">UF</label>
                          <v-text-field v-model="editModal.form.estado" variant="outlined" density="compact" color="primary" class="ui-field font-weight-bold font-mono text-center" />
                        </v-col>

                        <v-col cols="12" class="mt-4">
                          <label class="input-label">Observações</label>
                          <v-textarea
                            v-model="editModal.form.observacoes"
                            variant="outlined"
                            density="comfortable"
                            color="primary"
                            rows="4"
                            class="ui-field font-weight-medium"
                            placeholder="Ex: horário de entrega, contato interno, referência..."
                          />
                        </v-col>
                      </v-row>
                    </section>
                  </v-window-item>

                  <v-window-item value="finance">
                    <section class="modal-section-clean">
                      <div class="section-title-row-clean">
                        <div>
                          <div class="section-title-clean">Crédito & bloqueio</div>
                          <div class="section-subtitle-clean">Controle comercial para liberar ou bloquear pedidos no NewOrder.</div>
                        </div>
                      </div>

                      <v-row dense class="row-gap">
                        <v-col cols="12" md="5">
                          <label class="input-label">Limite de crédito</label>
                          <v-text-field
                            v-model="editModal.form.credit_limit"
                            prefix="R$"
                            type="number"
                            variant="outlined"
                            density="compact"
                            color="primary"
                            class="ui-field font-weight-black font-mono"
                          />
                        </v-col>

                        <v-col cols="12" md="7">
                          <div class="block-control-clean" :class="editModal.form.is_delinquent ? 'danger' : 'safe'">
                            <div class="d-flex align-center justify-space-between gap-4">
                              <div>
                                <div class="block-control-title">
                                  {{ editModal.form.is_delinquent ? 'Cliente inadimplente' : 'Cliente liberado' }}
                                </div>
                                <div class="block-control-copy">
                                  {{ editModal.form.is_delinquent ? 'O NewOrder vai impedir novos pedidos.' : 'O vendedor pode lançar pedidos normalmente.' }}
                                </div>
                              </div>
                              <v-switch v-model="editModal.form.is_delinquent" color="error" inset hide-details />
                            </div>
                          </div>
                        </v-col>

                        <v-col cols="12">
                          <v-expand-transition>
                            <div v-if="editModal.form.is_delinquent">
                              <label class="input-label text-error">Motivo do bloqueio *</label>
                              <v-textarea
                                v-model="editModal.form.delinquency_reason"
                                variant="outlined"
                                density="comfortable"
                                color="error"
                                rows="4"
                                class="ui-field font-weight-medium"
                                placeholder="Ex: Cliente com débito em aberto com a empresa."
                                :rules="[v => !editModal.form.is_delinquent || !!String(v || '').trim() || 'Informe o motivo do bloqueio']"
                              />

                              <v-alert type="error" variant="tonal" density="compact" class="mt-3 text-caption font-weight-bold border-error rounded-lg">
                                Ao salvar, este cliente ficará bloqueado para novos pedidos até ser liberado.
                              </v-alert>
                            </div>
                          </v-expand-transition>

                          <v-expand-transition>
                            <v-alert
                              v-if="!editModal.form.is_delinquent"
                              type="success"
                              variant="tonal"
                              density="compact"
                              class="text-caption font-weight-bold border-success rounded-lg"
                            >
                              Cliente liberado para novos pedidos.
                            </v-alert>
                          </v-expand-transition>
                        </v-col>
                      </v-row>
                    </section>
                  </v-window-item>

                  <v-window-item value="acquisition">
                    <section class="modal-section-clean">
                      <div class="section-title-row-clean">
                        <div>
                          <div class="section-title-clean">Origem do lead</div>
                          <div class="section-subtitle-clean">Como este cliente entrou na carteira.</div>
                        </div>
                      </div>

                      <v-row dense class="row-gap">
                        <v-col cols="12" md="6">
                          <label class="input-label">Canal de aquisição</label>
                          <v-select
                            v-model="editModal.form.acquisition_channel"
                            :items="acquisitionChannels"
                            variant="outlined"
                            density="compact"
                            color="primary"
                            class="ui-field font-weight-bold"
                          />
                        </v-col>

                        <v-col cols="12" md="6">
                          <label class="input-label">Detalhe / Subcanal</label>
                          <v-text-field
                            v-model="editModal.form.acquisition_subchannel"
                            variant="outlined"
                            density="compact"
                            color="primary"
                            class="ui-field font-weight-medium"
                            placeholder="Ex: Instagram, indicação, feira..."
                          />
                        </v-col>

                        <v-col cols="12">
                          <label class="input-label">Comprovante de visita</label>
                          <div class="proof-upload-box-clean">
                            <div class="d-flex align-center gap-3 min-w-0">
                              <v-avatar color="primary" variant="tonal" class="rounded-lg">
                                <v-icon>mdi-paperclip</v-icon>
                              </v-avatar>
                              <div class="min-w-0">
                                <div class="text-body-2 font-weight-black">
                                  {{ editModal.form.visit_proof_url ? 'Comprovante anexado' : 'Nenhum comprovante anexado' }}
                                </div>
                                <div class="text-caption opacity-70 text-truncate">
                                  {{ editModal.form.visit_proof_url || 'Anexe foto, print ou documento quando necessário.' }}
                                </div>
                              </div>
                            </div>

                            <div class="d-flex align-center gap-2">
                              <v-btn
                                variant="outlined"
                                color="primary"
                                class="btn-3d-subtle font-weight-bold"
                                :loading="editModal.uploadingProof"
                                @click="proofInputRef?.click()"
                              >
                                <v-icon start>mdi-upload</v-icon>
                                Anexar
                              </v-btn>
                              <v-btn
                                v-if="editModal.form.visit_proof_url"
                                variant="text"
                                color="error"
                                class="font-weight-bold"
                                @click="editModal.form.visit_proof_url = null"
                              >
                                Remover
                              </v-btn>
                            </div>
                          </div>
                          <input type="file" ref="proofInputRef" class="d-none" @change="(e) => handleFileUpload(e, 'proof')" />
                        </v-col>
                      </v-row>
                    </section>
                  </v-window-item>
                </v-window>
              </v-form>
            </div>
          </main>
        </div>

        <div class="editor-footer-clean">
          <div class="text-caption opacity-60 font-weight-bold">
            {{ editModal.isNew ? 'Novo cadastro' : 'Alterações serão aplicadas ao salvar' }}
          </div>
          <div class="d-flex align-center gap-3">
            <v-btn variant="outlined" class="btn-3d-subtle font-weight-bold px-6" @click="editModal.show = false">
              Cancelar
            </v-btn>
            <v-btn
              color="primary"
              variant="flat"
              class="btn-3d font-weight-black px-8 tracking-widest"
              :loading="editModal.saving"
              @click="saveClient"
            >
              <v-icon start>mdi-content-save</v-icon>
              Salvar Cliente
            </v-btn>
          </div>
        </div>
      </v-card>
    </v-dialog>

    <v-dialog v-model="bulkAssignModal.show" width="450" persistent scrim="black opacity-80">
      <v-card class="rounded-xl pa-6 border-thin shadow-2xl" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-grey-darken-4'">
        <div class="d-flex align-center gap-3 mb-4">
          <v-avatar color="primary" variant="tonal" class="rounded-lg"><v-icon>mdi-account-multiple-check</v-icon></v-avatar>
          <div class="text-h6 font-weight-black lh-1">Atribuir Carteira</div>
        </div>
        <div class="text-body-2 mb-6 font-weight-medium opacity-80">
          Selecione o vendedor responsável pelos <strong>{{ selectedClients.length }}</strong> clientes.
        </div>
        <v-autocomplete
          label="Selecione o vendedor"
          v-model="bulkAssignModal.sellerId"
          :items="salespeopleList"
          item-title="full_name"
          item-value="id"
          variant="outlined"
          density="compact"
          color="primary"
          prepend-inner-icon="mdi-crown"
          class="ui-field font-weight-bold"
        />
        <div class="d-flex justify-end gap-3 mt-2">
          <v-btn variant="outlined" class="btn-3d-subtle font-weight-bold px-6" @click="bulkAssignModal.show = false">Cancelar</v-btn>
          <v-btn color="primary" variant="flat" class="btn-3d font-weight-black px-8 tracking-widest" :loading="bulkAssignModal.loading" :disabled="!bulkAssignModal.sellerId" @click="confirmBulkAssign">Atribuir</v-btn>
        </div>
      </v-card>
    </v-dialog>

    <v-dialog v-model="bulkBlockModal.show" width="520" persistent scrim="black opacity-80">
      <v-card class="rounded-xl pa-6 border-thin shadow-2xl" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-grey-darken-4'">
        <div class="d-flex align-center gap-3 mb-4">
          <v-avatar color="warning" variant="tonal" class="rounded-lg"><v-icon>mdi-account-cancel-outline</v-icon></v-avatar>
          <div>
            <div class="text-h6 font-weight-black lh-1">Bloquear clientes em lote</div>
            <div class="text-caption opacity-70 font-weight-bold mt-1">{{ selectedClients.length }} cliente(s) selecionado(s)</div>
          </div>
        </div>

        <v-alert type="warning" variant="tonal" class="mb-4 text-caption font-weight-bold">
          Clientes bloqueados não poderão gerar novos pedidos no NewOrder.
        </v-alert>

        <v-textarea
          v-model="bulkBlockModal.reason"
          label="Motivo do bloqueio"
          variant="outlined"
          density="comfortable"
          rows="4"
          color="warning"
          class="ui-field font-weight-medium"
        />

        <div class="d-flex justify-space-between gap-3 mt-2">
          <v-btn color="success" variant="tonal" class="btn-3d-subtle font-weight-bold px-6" :loading="bulkBlockModal.loading" @click="confirmBulkUnblock">
            Liberar Selecionados
          </v-btn>
          <div class="d-flex gap-3">
            <v-btn variant="outlined" class="btn-3d-subtle font-weight-bold px-6" @click="bulkBlockModal.show = false">Cancelar</v-btn>
            <v-btn color="warning" variant="flat" class="btn-3d font-weight-black px-8 tracking-widest" :loading="bulkBlockModal.loading" @click="confirmBulkBlock">Bloquear</v-btn>
          </div>
        </div>
      </v-card>
    </v-dialog>

    <v-dialog v-model="historyModal.show" width="960" persistent scrim="black opacity-80">
      <v-card class="rounded-xl overflow-hidden border-thin shadow-2xl" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-grey-darken-4'">
        <div class="pa-5 d-flex align-center justify-space-between border-b" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-grey-darken-3 border-white-10'">
          <div>
            <div class="text-caption font-weight-black text-uppercase opacity-60">Histórico comercial</div>
            <div class="text-h6 font-weight-black">{{ historyModal.clientName }}</div>
          </div>
          <v-btn icon="mdi-close" variant="text" @click="historyModal.show = false" />
        </div>

        <div class="pa-5">
          <div v-if="historyModal.loading" class="d-flex justify-center py-10">
            <v-progress-circular indeterminate color="primary" />
          </div>

          <div v-else>
            <v-row dense class="mb-4">
              <v-col cols="12" md="6">
                <v-card variant="tonal" color="primary" class="pa-4 rounded-lg">
                  <div class="text-caption font-weight-black text-uppercase">Total comprado</div>
                  <div class="text-h5 font-weight-black">{{ formatCurrency(historyModal.kpis.totalAmount) }}</div>
                </v-card>
              </v-col>
              <v-col cols="12" md="6">
                <v-card variant="tonal" color="warning" class="pa-4 rounded-lg">
                  <div class="text-caption font-weight-black text-uppercase">Pedidos encontrados</div>
                  <div class="text-h5 font-weight-black">{{ historyModal.orders.length }}</div>
                </v-card>
              </v-col>
            </v-row>

            <v-expansion-panels variant="accordion">
              <v-expansion-panel v-for="order in historyModal.orders" :key="order.id">
                <v-expansion-panel-title>
                  <div class="d-flex align-center justify-space-between w-100 pr-4">
                    <div>
                      <div class="font-weight-black">Pedido #{{ order.order_number || order.order_code || order.id }}</div>
                      <div class="text-caption opacity-70">{{ formatDate(order.created_at || order.date_sale) }} • {{ order.status || 'sem status' }}</div>
                    </div>
                    <div class="text-subtitle-1 font-weight-black text-success font-mono">
                      {{ formatCurrency(order.total_value || 0) }}
                    </div>
                  </div>
                </v-expansion-panel-title>
                <v-expansion-panel-text>
                  <pre class="text-caption opacity-80">{{ order.details || 'Sem detalhes adicionais.' }}</pre>
                </v-expansion-panel-text>
              </v-expansion-panel>
            </v-expansion-panels>
          </div>
        </div>
      </v-card>
    </v-dialog>

    <v-dialog v-model="deleteModal.show" width="450" persistent scrim="black opacity-80">
      <v-card class="rounded-xl text-center pa-8 d-flex flex-column align-center border-thin shadow-2xl" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-grey-darken-4'">
        <v-avatar color="error" variant="tonal" size="80" class="mb-5 rounded-lg shadow-sm btn-3d">
          <v-icon size="40">mdi-alert-octagon</v-icon>
        </v-avatar>
        <div class="text-h5 font-weight-black text-error mb-2">Atenção crítica</div>
        <div class="text-body-2 text-medium-emphasis mb-6 px-4 font-weight-medium">
          Você está prestes a excluir o cadastro de <strong>{{ deleteModal.client?.nome }}</strong>.
          <div class="bg-red-lighten-5 text-red-darken-4 pa-3 rounded-lg border-thin mt-4 text-[11px] font-weight-bold text-uppercase tracking-widest d-flex align-start gap-2 text-left" style="line-height: 1.3;">
            <v-icon size="16" color="error" class="mt-n1">mdi-alert</v-icon>
            <div>Se existirem pedidos ou boletos atrelados, o banco pode bloquear a exclusão para proteger a auditoria financeira.</div>
          </div>
        </div>
        <div class="d-flex w-100 gap-3">
          <v-btn class="flex-grow-1 btn-3d-subtle font-weight-bold" variant="outlined" height="44" @click="deleteModal.show = false">Cancelar</v-btn>
          <v-btn class="flex-grow-1 btn-3d font-weight-black tracking-widest" color="error" variant="flat" height="44" :loading="deleteModal.loading" @click="confirmDelete" prepend-icon="mdi-delete-forever">Excluir</v-btn>
        </div>
      </v-card>
    </v-dialog>

    <v-dialog v-model="actionsModal.show" width="420" scrim="black opacity-70">
      <v-card class="rounded-xl pa-5 border-thin shadow-2xl" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-grey-darken-4'">
        <div class="d-flex align-center gap-3 mb-4">
          <v-avatar color="blue-grey-darken-3" variant="tonal" class="rounded-lg"><v-icon>mdi-export-variant</v-icon></v-avatar>
          <div>
            <div class="text-h6 font-weight-black">Relatórios</div>
            <div class="text-caption opacity-70">Exportação da base filtrada</div>
          </div>
        </div>

        <div class="d-flex flex-column gap-3">
          <v-btn color="success" variant="flat" class="btn-3d font-weight-bold" prepend-icon="mdi-file-excel" @click="exportExcel">
            Exportar CSV
          </v-btn>
          <v-btn color="error" variant="flat" class="btn-3d font-weight-bold" prepend-icon="mdi-file-pdf-box" @click="exportPDF">
            Exportar PDF
          </v-btn>
          <v-btn variant="text" class="font-weight-bold" @click="actionsModal.show = false">
            Fechar
          </v-btn>
        </div>
      </v-card>
    </v-dialog>

    <v-snackbar v-model="snackbar.show" :color="snackbar.color" location="bottom right" timeout="4000" rounded="pill" elevation="24">
      <div class="d-flex align-center font-weight-bold font-mono px-2">
        <v-icon size="18" class="mr-3">{{ snackbar.icon }}</v-icon>
        <span>{{ snackbar.text }}</span>
      </div>
    </v-snackbar>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onBeforeUnmount, reactive, watch } from 'vue';
import { supabase } from '@/api/supabase';
import { useThemeStore } from '@/stores/themeStore';
import { useAppStore } from '@/stores/app';
import { useUserStore } from '@/stores/user';
import { useCompanyStore } from '@/stores/company';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import { format, differenceInDays, parseISO, subMonths } from 'date-fns';
import logoImage from '@/assets/logomjlm.png';

const themeStore = useThemeStore();
const appStore = useAppStore();
const userStore = useUserStore();
const companyStore = useCompanyStore();

const zebraClass = (index: number) => {
  if (themeStore.currentMode === 'light') {
    return index % 2 === 0 ? 'zebra-light-a' : 'zebra-light-b';
  }
  return index % 2 === 0 ? 'zebra-dark-a' : 'zebra-dark-b';
};

const loading = ref(false);
const clients = ref<any[]>([]);
const search = ref('');
const currentStatusFilter = ref('active');
const currentSellerFilter = ref('all');
const salespeopleList = ref<any[]>([]);
const formSubmitted = ref(false);
const isContextIslandFloating = ref(false);

const selectedClients = ref<string[]>([]);
const bulkAssignModal = reactive({ show: false, sellerId: null as string | null, loading: false });
const bulkBlockModal = reactive({
  show: false,
  reason: 'Cliente com débito em aberto com a empresa.',
  loading: false
});

const actionsModal = reactive({ show: false });
const editModal = reactive({
  show: false,
  tab: 'basic',
  isNew: false,
  saving: false,
  searchingCnpj: false,
  uploadingAvatar: false,
  uploadingProof: false,
  form: {
    person_type: 'PF',
    acquisition_channel: '',
    acquisition_subchannel: '',
    visit_proof_url: null,
    avatar_url: null,
    company_size: '',
    cpf_cnpj: '',
    is_delinquent: false,
    delinquency_reason: null
  } as any
});

const historyModal = reactive({
  show: false,
  loading: false,
  clientName: '',
  orders: [] as any[],
  kpis: { totalAmount: 0, openReceivables: 0 }
});

const deleteModal = reactive({ show: false, loading: false, client: null as any });
const snackbar = reactive({ show: false, text: '', color: 'success', icon: 'mdi-check' });

const page = ref(1);
const itemsPerPage = 30;
const formRef = ref<any>(null);
const avatarInputRef = ref<HTMLInputElement | null>(null);
const proofInputRef = ref<HTMLInputElement | null>(null);

const statusFilters = [
  { label: 'Todos', value: 'all' },
  { label: 'Ativos', value: 'active' },
  { label: 'Inativos', value: 'inactive' },
  { label: 'Bloqueados', value: 'blocked' }
];

const acquisitionChannels = [
  'Indicação',
  'Instagram',
  'WhatsApp',
  'Google',
  'Vendedor foi até o cliente',
  'Cliente veio até a loja',
  'Feira / Evento',
  'Carteira antiga',
  'Outro'
];

const tenantContextButtons = computed(() => {
  const companies = (companyStore.availableCompanies || []).map((company: any, index: number) => ({
    id: company.id,
    name: company.trade_name || company.name,
    color: index % 2 === 0 ? 'primary' : 'success',
    isHolding: false
  }));

  return [
    ...companies,
    {
      id: 'global',
      name: 'Holding',
      color: 'blue-grey-darken-4',
      isHolding: true
    }
  ];
});

const currentTenantLabel = computed(() => {
  if (companyStore.isGlobalView) return 'Holding';
  return companyStore.currentCompanyName || 'Empresa';
});

const setTenantContext = (contextId: string) => {
  companyStore.setContext(contextId as any);
  selectedClients.value = [];
  page.value = 1;
};

const handleContextIslandScroll = () => {
  isContextIslandFloating.value = window.scrollY > 120;
};

const cleanDoc = (doc: any) => doc ? String(doc).replace(/\D/g, '') : '';
const formatDocument = (val: string) => val || '-';
const formatCurrency = (val: any) => new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(Number(val) || 0);
const formatDate = (dateString: string) => dateString ? format(new Date(dateString), 'dd/MM/yyyy') : '-';
const normalize = (str: string) => str ? str.normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase().trim() : '';

const getPersonType = (client: any) => {
  return client.person_type || client.tipo_pessoa || (client.cnpj ? 'PJ' : 'PF');
};

const getColor = (name: string) => {
  const colors = ['primary', 'secondary', 'info', 'success', 'warning', 'error'];
  let hash = 0;
  if (!name) return 'grey';
  for (let i = 0; i < name.length; i++) hash = name.charCodeAt(i) + ((hash << 5) - hash);
  return colors[Math.abs(hash) % colors.length];
};

const getSellerName = (id: string) => {
  const seller = salespeopleList.value.find(v => v.id === id);
  return seller ? seller.full_name : 'Desconhecido';
};

const isClientActive = (client: any) => {
  if (client.situacao === 'Inativo') return false;

  if (client.created_at) {
    const createdDate = parseISO(client.created_at);
    if (differenceInDays(new Date(), createdDate) <= 60) return true;
  }

  if (!client.last_purchase_date) return false;
  const lastOrder = parseISO(client.last_purchase_date);
  return differenceInDays(new Date(), lastOrder) <= 60;
};

const sellerFilterOptions = computed(() => {
  const options = [
    { label: 'Todos os Vendedores', value: 'all' },
    { label: 'Sem Dono', value: 'unassigned' }
  ];

  salespeopleList.value.forEach(seller => {
    options.push({ label: seller.full_name, value: seller.id });
  });

  return options;
});

const visibleClientsByTenant = computed(() => {
  if (companyStore.isGlobalView) return clients.value;

  const ctx = String(companyStore.context);
  return clients.value.filter(client => {
    const tenantIds = Array.isArray(client.tenant_ids) ? client.tenant_ids.map(String) : [];
    return String(client.company_id || '') === ctx || tenantIds.includes(ctx);
  });
});

const kpiList = computed(() => {
  let baseList = visibleClientsByTenant.value;

  if (currentSellerFilter.value === 'unassigned') {
    baseList = baseList.filter(c => !c.vendedor_responsavel_id);
  } else if (currentSellerFilter.value !== 'all') {
    baseList = baseList.filter(c =>
      c.vendedor_responsavel_id === currentSellerFilter.value ||
      (!c.vendedor_responsavel_id && c.suggested_seller_id === currentSellerFilter.value)
    );
  }

  const total = baseList.length;
  const active = baseList.filter(c => isClientActive(c)).length;
  const blocked = baseList.filter(c => c.is_delinquent).length;
  const currentMonth = new Date().toISOString().slice(0, 7);
  const newClients = baseList.filter(c => c.created_at?.startsWith(currentMonth)).length;

  return [
    { label: 'Total Base', value: total, footer: 'Clientes na visão', icon: 'mdi-database', gradient: 'bg-gradient-info' },
    { label: 'Carteira Ativa', value: active, footer: 'Giro nos últimos 60d', icon: 'mdi-briefcase-check', gradient: 'bg-gradient-success' },
    { label: 'Novos Leads', value: newClients, footer: 'Captação mensal', icon: 'mdi-account-multiple-plus', gradient: 'bg-gradient-blue' },
    { label: 'Inadimplentes', value: blocked, footer: 'Bloqueados no NewOrder', icon: 'mdi-account-cancel', gradient: 'bg-gradient-red' }
  ];
});

const fetchClients = async () => {
  loading.value = true;

  try {
    const { data: clientsData, error } = await supabase
      .from('customers_mj')
      .select(`
        *,
        responsible_salesperson:vendedor_responsavel_id (id, full_name),
        orders (created_at, status, id, total_value, created_by, company_id)
      `)
      .order('nome', { ascending: true });

    if (error) throw error;

    const sixMonthsAgo = subMonths(new Date(), 6).toISOString();

    const { data: looseOrders } = await supabase
      .from('orders')
      .select('customer_name, created_at, total_value, created_by, company_id')
      .gte('created_at', sixMonthsAgo)
      .not('customer_name', 'is', null)
      .order('created_at', { ascending: false });

    const { data: storeSales } = await supabase
      .from('store_sales')
      .select('id, customer_id, customer_name, seller_id, seller_name, total_value, date_sale, created_at, company_id')
      .gte('created_at', sixMonthsAgo)
      .order('created_at', { ascending: false });

    clients.value = (clientsData || []).map((client: any) => {
      let lastDate = null;
      let totalSpent = 0;
      let suggestedSeller = null;
      const sellerCounts: Record<string, number> = {};
      const tenantSet = new Set<string>();

      if (client.company_id) tenantSet.add(String(client.company_id));

      if (client.orders && client.orders.length > 0) {
        const sorted = [...client.orders].sort((a: any, b: any) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime());
        lastDate = sorted[0].created_at;
        totalSpent += client.orders.reduce((acc: number, curr: any) => acc + (Number(curr.total_value) || 0), 0);

        client.orders.forEach((order: any) => {
          if (order.created_by) sellerCounts[order.created_by] = (sellerCounts[order.created_by] || 0) + 1;
          if (order.company_id) tenantSet.add(String(order.company_id));
        });
      }

      const normName = normalize(client.nome);
      const normFantasia = normalize(client.nome_fantasia);

      if (looseOrders) {
        const matches = looseOrders.filter((order: any) => {
          const normOrderName = normalize(order.customer_name);
          return normOrderName === normName || (normFantasia && normOrderName === normFantasia);
        });

        if (matches.length > 0) {
          if (!lastDate) lastDate = matches[0].created_at;
          totalSpent += matches.reduce((acc: number, curr: any) => acc + (Number(curr.total_value) || 0), 0);

          matches.forEach((order: any) => {
            if (order.created_by) sellerCounts[order.created_by] = (sellerCounts[order.created_by] || 0) + 1;
            if (order.company_id) tenantSet.add(String(order.company_id));
          });
        }
      }

      if (storeSales) {
        const matches = storeSales.filter((sale: any) => {
          if (sale.customer_id && String(sale.customer_id) === String(client.id)) return true;
          const normSaleName = normalize(sale.customer_name);
          return normSaleName === normName || (normFantasia && normSaleName === normFantasia);
        });

        if (matches.length > 0) {
          const sorted = [...matches].sort((a: any, b: any) => new Date(b.date_sale || b.created_at).getTime() - new Date(a.date_sale || a.created_at).getTime());
          const candidateLastDate = sorted[0].date_sale || sorted[0].created_at;

          if (!lastDate || new Date(candidateLastDate).getTime() > new Date(lastDate).getTime()) {
            lastDate = candidateLastDate;
          }

          totalSpent += matches.reduce((acc: number, curr: any) => acc + (Number(curr.total_value) || 0), 0);

          matches.forEach((sale: any) => {
            if (sale.seller_id) sellerCounts[sale.seller_id] = (sellerCounts[sale.seller_id] || 0) + 1;
            if (sale.company_id) tenantSet.add(String(sale.company_id));
          });
        }
      }

      if (!lastDate && client.last_purchase) lastDate = client.last_purchase;

      if (!client.vendedor_responsavel_id) {
        const topSeller = Object.keys(sellerCounts).sort((a, b) => sellerCounts[b] - sellerCounts[a])[0];
        if (topSeller) suggestedSeller = topSeller;
      }

      return {
        ...client,
        is_delinquent: !!client.is_delinquent,
        delinquency_reason: client.delinquency_reason || null,
        last_purchase_date: lastDate,
        total_spent: totalSpent,
        suggested_seller_id: suggestedSeller,
        tenant_ids: Array.from(tenantSet)
      };
    });
  } catch (error: any) {
    console.error('Erro fetchClients:', error);
    appStore.showSnackbar('Erro ao carregar clientes: ' + error.message, 'error');
  } finally {
    loading.value = false;
  }
};

const fetchSalespeople = async () => {
  try {
    const { data, error } = await supabase
      .from('profiles')
      .select('id, full_name')
      .or('role.eq.vendedor,role.eq.admin,role.eq.super_admin')
      .order('full_name');

    if (!error) salespeopleList.value = data || [];
  } catch (error) {
    console.error(error);
  }
};

const filteredClients = computed(() => {
  let list = [...visibleClientsByTenant.value];

  if (currentSellerFilter.value === 'unassigned') {
    list = list.filter(c => !c.vendedor_responsavel_id);
  } else if (currentSellerFilter.value !== 'all') {
    list = list.filter(c =>
      c.vendedor_responsavel_id === currentSellerFilter.value ||
      (!c.vendedor_responsavel_id && c.suggested_seller_id === currentSellerFilter.value)
    );
  }

  if (currentStatusFilter.value === 'active') list = list.filter(c => isClientActive(c));
  if (currentStatusFilter.value === 'inactive') list = list.filter(c => !isClientActive(c));
  if (currentStatusFilter.value === 'blocked') list = list.filter(c => c.is_delinquent);

  if (search.value) {
    const s = normalize(search.value);
    list = list.filter(c =>
      normalize(c.nome).includes(s) ||
      normalize(c.nome_fantasia).includes(s) ||
      normalize(c.razao_social).includes(s) ||
      String(c.cpf || '').includes(s) ||
      String(c.cnpj || '').includes(s) ||
      normalize(c.cidade).includes(s)
    );
  }

  list.sort((a, b) => {
    if (a.is_delinquent && !b.is_delinquent) return -1;
    if (!a.is_delinquent && b.is_delinquent) return 1;

    const aActive = isClientActive(a);
    const bActive = isClientActive(b);

    if (aActive && !bActive) return -1;
    if (!aActive && bActive) return 1;

    if (a.last_purchase_date && b.last_purchase_date) {
      return new Date(b.last_purchase_date).getTime() - new Date(a.last_purchase_date).getTime();
    }

    return String(a.nome || '').localeCompare(String(b.nome || ''));
  });

  return list;
});

const paginatedClients = computed(() => {
  const start = (page.value - 1) * itemsPerPage;
  return filteredClients.value.slice(start, start + itemsPerPage);
});

const totalPages = computed(() => Math.ceil(filteredClients.value.length / itemsPerPage));

const selectAll = computed({
  get: () => paginatedClients.value.length > 0 && selectedClients.value.length === paginatedClients.value.length,
  set: (val) => {
    selectedClients.value = val ? paginatedClients.value.map(c => c.id) : [];
  }
});

const confirmBulkAssign = async () => {
  if (!bulkAssignModal.sellerId || selectedClients.value.length === 0) return;

  bulkAssignModal.loading = true;
  try {
    const { error } = await supabase
      .from('customers_mj')
      .update({
        vendedor_responsavel_id: bulkAssignModal.sellerId,
        updated_at: new Date().toISOString()
      })
      .in('id', selectedClients.value);

    if (error) throw error;

    appStore.showSnackbar(`${selectedClients.value.length} clientes atribuídos com sucesso!`, 'success');
    selectedClients.value = [];
    bulkAssignModal.show = false;
    await fetchClients();
  } catch (error: any) {
    appStore.showSnackbar('Erro ao atribuir vendedores: ' + error.message, 'error');
  } finally {
    bulkAssignModal.loading = false;
  }
};

const confirmBulkBlock = async () => {
  if (selectedClients.value.length === 0) return;

  bulkBlockModal.loading = true;
  try {
    const reason = bulkBlockModal.reason?.trim() || 'Cliente com débito em aberto com a empresa.';

    const { error } = await supabase
      .from('customers_mj')
      .update({
        is_delinquent: true,
        delinquency_reason: reason,
        delinquency_marked_at: new Date().toISOString(),
        delinquency_marked_by: userStore.user?.id || userStore.profile?.id || null,
        updated_at: new Date().toISOString()
      })
      .in('id', selectedClients.value);

    if (error) throw error;

    appStore.showSnackbar(`${selectedClients.value.length} cliente(s) bloqueado(s).`, 'warning');
    selectedClients.value = [];
    bulkBlockModal.show = false;
    await fetchClients();
  } catch (error: any) {
    appStore.showSnackbar('Erro ao bloquear clientes: ' + error.message, 'error');
  } finally {
    bulkBlockModal.loading = false;
  }
};

const confirmBulkUnblock = async () => {
  if (selectedClients.value.length === 0) return;

  bulkBlockModal.loading = true;
  try {
    const { error } = await supabase
      .from('customers_mj')
      .update({
        is_delinquent: false,
        delinquency_reason: null,
        delinquency_marked_at: null,
        delinquency_marked_by: null,
        updated_at: new Date().toISOString()
      })
      .in('id', selectedClients.value);

    if (error) throw error;

    appStore.showSnackbar(`${selectedClients.value.length} cliente(s) liberado(s).`, 'success');
    selectedClients.value = [];
    bulkBlockModal.show = false;
    await fetchClients();
  } catch (error: any) {
    appStore.showSnackbar('Erro ao liberar clientes: ' + error.message, 'error');
  } finally {
    bulkBlockModal.loading = false;
  }
};

const toggleClientDelinquency = async (client: any) => {
  const currentlyBlocked = !!client.is_delinquent;
  let reason: string | null = client.delinquency_reason || null;

  if (!currentlyBlocked) {
    reason = window.prompt(
      `Motivo do bloqueio de ${client.nome_fantasia || client.nome}:`,
      client.delinquency_reason || 'Cliente com débito em aberto com a empresa.'
    );

    if (reason === null) return;
    reason = reason.trim() || 'Cliente com débito em aberto com a empresa.';
  } else {
    const ok = window.confirm(`Liberar ${client.nome_fantasia || client.nome} para novos pedidos?`);
    if (!ok) return;
    reason = null;
  }

  try {
    const payload = currentlyBlocked
      ? {
          is_delinquent: false,
          delinquency_reason: null,
          delinquency_marked_at: null,
          delinquency_marked_by: null,
          updated_at: new Date().toISOString()
        }
      : {
          is_delinquent: true,
          delinquency_reason: reason,
          delinquency_marked_at: new Date().toISOString(),
          delinquency_marked_by: userStore.user?.id || userStore.profile?.id || null,
          updated_at: new Date().toISOString()
        };

    const { error } = await supabase
      .from('customers_mj')
      .update(payload)
      .eq('id', client.id);

    if (error) throw error;

    Object.assign(client, payload);

    appStore.showSnackbar(
      currentlyBlocked ? 'Cliente liberado para novos pedidos.' : 'Cliente marcado como inadimplente. NewOrder ficará bloqueado.',
      currentlyBlocked ? 'success' : 'warning'
    );
  } catch (error: any) {
    console.error(error);
    appStore.showSnackbar('Erro ao atualizar bloqueio do cliente: ' + error.message, 'error');
  }
};

const handleFileUpload = async (event: any, type: 'avatar' | 'proof') => {
  const file = event.target.files?.[0];
  if (!file) return;

  const fileExt = file.name.split('.').pop();
  const fileName = `${Date.now()}_${Math.random().toString(36).substring(7)}.${fileExt}`;
  const filePath = `${type}s/${fileName}`;

  try {
    if (type === 'avatar') editModal.uploadingAvatar = true;
    else editModal.uploadingProof = true;

    const { error: uploadError } = await supabase.storage.from('customer_assets').upload(filePath, file);
    if (uploadError) throw uploadError;

    const { data } = supabase.storage.from('customer_assets').getPublicUrl(filePath);

    if (type === 'avatar') editModal.form.avatar_url = data.publicUrl;
    else editModal.form.visit_proof_url = data.publicUrl;

    appStore.showSnackbar('Arquivo anexado com sucesso!', 'success');
  } catch (error: any) {
    console.error('Erro upload:', error);
    appStore.showSnackbar('Erro ao salvar arquivo no Storage: ' + error.message, 'error');
  } finally {
    if (type === 'avatar') editModal.uploadingAvatar = false;
    else editModal.uploadingProof = false;

    event.target.value = '';
  }
};

const searchCnpj = async () => {
  const doc = cleanDoc(editModal.form.cpf_cnpj);

  if (!doc || doc.length !== 14) {
    appStore.showSnackbar('Digite um CNPJ válido com 14 dígitos', 'warning');
    return;
  }

  editModal.searchingCnpj = true;
  try {
    const response = await fetch(`https://brasilapi.com.br/api/cnpj/v1/${doc}`);
    if (!response.ok) throw new Error('CNPJ não encontrado');

    const data = await response.json();

    if (data) {
      editModal.form.nome = data.nome_fantasia || data.razao_social;
      editModal.form.razao_social = data.razao_social;
      editModal.form.cep = data.cep;
      editModal.form.endereco = data.logradouro;
      editModal.form.numero = data.numero;
      editModal.form.bairro = data.bairro;
      editModal.form.cidade = data.municipio;
      editModal.form.estado = data.uf;
      editModal.form.email = data.email || editModal.form.email;
      editModal.form.telefone = data.ddd_telefone_1 || editModal.form.telefone;

      if (data.porte) {
        if (data.porte.includes('MICRO EMPRESA')) editModal.form.company_size = 'ME';
        else if (data.porte.includes('PEQUENO PORTE')) editModal.form.company_size = 'EPP';
        else editModal.form.company_size = data.porte;
      }

      appStore.showSnackbar('Dados importados da Receita Federal!', 'success');
    }
  } catch (error) {
    appStore.showSnackbar('Erro ao buscar CNPJ. Verifique se está correto.', 'error');
  } finally {
    editModal.searchingCnpj = false;
  }
};

const openNewClientModal = () => {
  formSubmitted.value = false;
  editModal.tab = 'basic';
  editModal.isNew = true;
  editModal.show = true;
  editModal.form = {
    vendedor_responsavel_id: userStore.user?.id || userStore.profile?.id || null,
    company_id: companyStore.isGlobalView ? null : companyStore.context,
    person_type: 'PF',
    acquisition_channel: '',
    acquisition_subchannel: '',
    company_size: '',
    cpf_cnpj: '',
    situacao: 'Ativo',
    credit_limit: 0,
    is_delinquent: false,
    delinquency_reason: null
  };
};

const openEditModal = (client: any) => {
  formSubmitted.value = false;
  editModal.tab = 'basic';
  editModal.isNew = false;
  editModal.show = true;
  editModal.form = {
    ...client,
    cpf_cnpj: client.cpf || client.cnpj || '',
    person_type: getPersonType(client),
    is_delinquent: !!client.is_delinquent,
    delinquency_reason: client.delinquency_reason || ''
  };
};

const saveClient = async () => {
  formSubmitted.value = true;

  const validation = await formRef.value?.validate?.();
  if (validation && validation.valid === false) {
    appStore.showSnackbar('Preencha os campos obrigatórios em todas as abas.', 'warning');
    return;
  }

  if (editModal.form.is_delinquent && !String(editModal.form.delinquency_reason || '').trim()) {
    editModal.tab = 'finance';
    appStore.showSnackbar('Informe o motivo do bloqueio antes de salvar.', 'warning');
    return;
  }

  if (editModal.isNew && editModal.form.acquisition_channel === 'Vendedor foi até o cliente' && !editModal.form.visit_proof_url) {
    editModal.tab = 'acquisition';
    appStore.showSnackbar('Anexe o comprovante da visita para prosseguir com o novo cadastro.', 'error');
    return;
  }

  editModal.saving = true;

  try {
    const payload = JSON.parse(JSON.stringify(editModal.form));
    const doc = cleanDoc(payload.cpf_cnpj);
    let cpf = null;
    let cnpj = null;

    if (doc) {
      if (doc.length > 11) cnpj = doc;
      else cpf = doc;
    }

    const isBlocked = !!payload.is_delinquent;
    const cleanPayload: any = {
      nome: payload.nome,
      razao_social: payload.razao_social,
      nome_fantasia: payload.nome_fantasia || payload.nome,
      tipo_pessoa: payload.person_type || 'PF',
      person_type: payload.person_type || 'PF',
      cpf,
      cnpj,
      email: payload.email,
      telefone: payload.telefone,
      celular: payload.celular,
      cep: payload.cep,
      endereco: payload.endereco,
      numero: payload.numero,
      bairro: payload.bairro,
      cidade: payload.cidade,
      estado: payload.estado,
      observacoes: payload.observacoes,
      situacao: payload.situacao || 'Ativo',
      credit_limit: Number(payload.credit_limit) || 0,
      vendedor_responsavel_id: payload.vendedor_responsavel_id || null,
      company_id: payload.company_id || (companyStore.isGlobalView ? null : companyStore.context),
      acquisition_channel: payload.acquisition_channel,
      acquisition_subchannel: payload.acquisition_subchannel,
      visit_proof_url: payload.visit_proof_url,
      avatar_url: payload.avatar_url,
      company_size: payload.company_size,
      is_delinquent: isBlocked,
      delinquency_reason: isBlocked ? (String(payload.delinquency_reason || '').trim() || 'Cliente com débito em aberto com a empresa.') : null,
      delinquency_marked_at: isBlocked
        ? (payload.delinquency_marked_at || new Date().toISOString())
        : null,
      delinquency_marked_by: isBlocked
        ? (payload.delinquency_marked_by || userStore.user?.id || userStore.profile?.id || null)
        : null,
      updated_at: new Date().toISOString()
    };

    if (editModal.isNew) {
      const { error } = await supabase.from('customers_mj').insert(cleanPayload);
      if (error) throw error;
    } else {
      const { error } = await supabase.from('customers_mj').update(cleanPayload).eq('id', payload.id);
      if (error) throw error;
    }

    appStore.showSnackbar(
      isBlocked
        ? 'Cliente salvo e bloqueado no NewOrder.'
        : 'Cadastro salvo com sucesso.',
      isBlocked ? 'warning' : 'success'
    );

    editModal.show = false;
    await fetchClients();
  } catch (error: any) {
    console.error(error);
    appStore.showSnackbar('Falha ao salvar cliente: ' + error.message, 'error');
  } finally {
    editModal.saving = false;
  }
};

const openHistoryModal = async (client: any) => {
  historyModal.show = true;
  historyModal.loading = true;
  historyModal.clientName = client.nome_fantasia || client.nome;
  historyModal.orders = [];
  historyModal.kpis = { totalAmount: 0, openReceivables: 0 };

  try {
    const [ordersResult, storeSalesResult] = await Promise.all([
      supabase
        .from('orders')
        .select('id, order_number, created_at, status, total_value, details, company_id')
        .or(`customer_id.eq.${client.id},customer_name.ilike.%${client.nome || client.nome_fantasia}%`)
        .order('created_at', { ascending: false })
        .limit(50),
      supabase
        .from('store_sales')
        .select('id, order_number, created_at, date_sale, status, total_value, customer_name, company_id')
        .or(`customer_id.eq.${client.id},customer_name.ilike.%${client.nome || client.nome_fantasia}%`)
        .order('created_at', { ascending: false })
        .limit(50)
    ]);

    if (ordersResult.error) throw ordersResult.error;
    if (storeSalesResult.error) throw storeSalesResult.error;

    const rows = [
      ...(ordersResult.data || []),
      ...(storeSalesResult.data || []).map((sale: any) => ({
        ...sale,
        created_at: sale.date_sale || sale.created_at,
        details: 'Venda PDV / Santos & Lopes'
      }))
    ];

    historyModal.orders = rows
      .filter((row: any) => companyStore.isGlobalView || String(row.company_id || '') === String(companyStore.context))
      .sort((a: any, b: any) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime());

    historyModal.kpis.totalAmount = historyModal.orders.reduce((acc: number, order: any) => acc + (Number(order.total_value) || 0), 0);
  } catch (error: any) {
    console.error(error);
    appStore.showSnackbar('Erro ao buscar histórico: ' + error.message, 'error');
  } finally {
    historyModal.loading = false;
  }
};

const openDeleteModal = (client: any) => {
  deleteModal.client = client;
  deleteModal.show = true;
};

const confirmDelete = async () => {
  if (!deleteModal.client?.id) return;

  deleteModal.loading = true;
  try {
    const { error } = await supabase.from('customers_mj').delete().eq('id', deleteModal.client.id);
    if (error) throw error;

    appStore.showSnackbar('Cliente excluído com sucesso.', 'success');
    deleteModal.show = false;
    await fetchClients();
  } catch (error: any) {
    appStore.showSnackbar('Erro ao excluir cliente: ' + error.message, 'error');
  } finally {
    deleteModal.loading = false;
  }
};

const exportExcel = () => {
  try {
    const headers = [
      'Empresa/Visão',
      'Nome / Fantasia',
      'Tipo',
      'Razão Social',
      'Documento',
      'Email',
      'Telefone',
      'Cidade',
      'Estado',
      'Vendedor Responsável',
      'Última Compra',
      'Gasto Total',
      'Status',
      'Crédito'
    ];

    const rows = filteredClients.value.map(c => [
      currentTenantLabel.value,
      c.nome_fantasia || c.nome,
      getPersonType(c),
      c.razao_social || '-',
      c.cpf || c.cnpj || '-',
      c.email || '-',
      c.telefone || c.celular || '-',
      c.cidade || '-',
      c.estado || '-',
      c.responsible_salesperson?.full_name || 'Sem Dono',
      c.last_purchase_date ? formatDate(c.last_purchase_date) : 'Nunca',
      c.total_spent || 0,
      isClientActive(c) ? 'Ativo' : 'Inativo',
      c.is_delinquent ? 'Inadimplente / Bloqueado' : 'Liberado'
    ]);

    const csvContent = [
      headers.join(';'),
      ...rows.map(row => row.map(field => `"${String(field || '').replace(/"/g, '""')}"`).join(';'))
    ].join('\n');

    const bom = new Uint8Array([0xEF, 0xBB, 0xBF]);
    const blob = new Blob([bom, csvContent], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');

    link.setAttribute('href', url);
    link.setAttribute('download', `Relatorio_Clientes_${currentTenantLabel.value}_${format(new Date(), 'ddMMyyyy_HHmm')}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);

    appStore.showSnackbar('Relatório CSV exportado.', 'success');
    actionsModal.show = false;
  } catch (error) {
    console.error('Erro ao exportar CSV:', error);
    appStore.showSnackbar('Erro ao montar CSV.', 'error');
  }
};

const exportPDF = () => {
  try {
    const doc = new jsPDF({ orientation: 'landscape', unit: 'mm', format: 'a4' });

    try {
      const imgProps = doc.getImageProperties(logoImage);
      const imgWidth = 30;
      const imgHeight = (imgProps.height * imgWidth) / imgProps.width;
      doc.addImage(logoImage, 'PNG', 14, 10, imgWidth, imgHeight);
    } catch (error) {
      console.warn('Logo não carregada no PDF.');
    }

    doc.setFontSize(15);
    doc.setFont('helvetica', 'bold');
    doc.text(`Relatório de Clientes - ${currentTenantLabel.value}`, 50, 18);

    doc.setFontSize(9);
    doc.setFont('helvetica', 'normal');
    doc.text(`Gerado em ${format(new Date(), 'dd/MM/yyyy HH:mm')}`, 50, 24);

    const body = filteredClients.value.map(c => [
      c.nome_fantasia || c.nome || '-',
      getPersonType(c),
      c.cpf || c.cnpj || '-',
      c.telefone || c.celular || '-',
      c.cidade || '-',
      c.responsible_salesperson?.full_name || 'Sem Dono',
      c.last_purchase_date ? formatDate(c.last_purchase_date) : 'Nunca',
      formatCurrency(c.total_spent),
      c.is_delinquent ? 'Bloqueado' : 'Liberado'
    ]);

    autoTable(doc, {
      startY: 34,
      head: [['Cliente', 'Tipo', 'Documento', 'Telefone', 'Cidade', 'Vendedor', 'Última Compra', 'LTV', 'Crédito']],
      body,
      styles: { fontSize: 8, cellPadding: 2 },
      headStyles: { fillColor: [31, 41, 55], textColor: 255, fontStyle: 'bold' },
      alternateRowStyles: { fillColor: [245, 247, 250] }
    });

    doc.save(`Relatorio_Clientes_${currentTenantLabel.value}_${format(new Date(), 'ddMMyyyy_HHmm')}.pdf`);
    actionsModal.show = false;
    appStore.showSnackbar('Relatório PDF exportado.', 'success');
  } catch (error: any) {
    console.error('Erro PDF:', error);
    appStore.showSnackbar('Erro ao gerar PDF: ' + error.message, 'error');
  }
};

watch(() => companyStore.context, () => {
  page.value = 1;
  selectedClients.value = [];
});

onMounted(async () => {
  handleContextIslandScroll();
  window.addEventListener('scroll', handleContextIslandScroll, { passive: true });

  if (!companyStore.availableCompanies.length) {
    await companyStore.initialize();
  }

  await Promise.all([
    fetchSalespeople(),
    fetchClients()
  ]);
});

onBeforeUnmount(() => {
  window.removeEventListener('scroll', handleContextIslandScroll);
});
</script>

<style scoped>
.clients-layout {
  min-height: 100vh;
}

.background-carousel-wrapper {
  position: fixed;
  inset: 0;
  z-index: 0;
  pointer-events: none;
  background:
    radial-gradient(circle at top left, rgba(37, 99, 235, 0.12), transparent 34%),
    radial-gradient(circle at bottom right, rgba(239, 68, 68, 0.10), transparent 32%),
    linear-gradient(135deg, #020617, #111827);
}

.background-overlay {
  position: absolute;
  inset: 0;
  background: rgba(2, 6, 23, 0.74);
  backdrop-filter: blur(2px);
}

.content-wrapper {
  min-height: 0;
}

.bg-glass-dark {
  background: #020617;
}

.bg-glass-header {
  background: rgba(15, 23, 42, 0.72);
  backdrop-filter: blur(16px);
}

.border-bottom-white-05 {
  border-bottom: 1px solid rgba(255, 255, 255, 0.05);
}

.border-white-05 {
  border-color: rgba(255, 255, 255, 0.05) !important;
}

.border-white-10 {
  border-color: rgba(255, 255, 255, 0.10) !important;
}

.bg-black-20 {
  background: rgba(0, 0, 0, 0.20);
}

.bg-black-40 {
  background: rgba(0, 0, 0, 0.40);
}

.header-bar {
  position: relative;
  z-index: 2;
}

.tracking-widest {
  letter-spacing: 0.08em;
}

.leading-none {
  line-height: 1;
}

.kpi-card {
  position: relative;
  min-height: 108px;
  border-radius: 18px;
  overflow: hidden;
  color: white;
  transition: transform 0.18s ease, box-shadow 0.18s ease;
}

.kpi-card:hover {
  transform: translateY(-2px);
}

.kpi-3d,
.btn-3d,
.chip-3d,
.action-btn {
  box-shadow:
    0 2px 0 rgba(0,0,0,.13),
    0 9px 16px rgba(15,23,42,.11) !important;
}

.btn-3d-subtle {
  box-shadow:
    0 1px 0 rgba(0,0,0,.12),
    0 6px 12px rgba(15,23,42,.08) !important;
}

.kpi-subtle {
  border: 1px solid rgba(255,255,255,0.16);
}

.kpi-bg-icon {
  position: absolute;
  right: -10px;
  bottom: -18px;
  opacity: 0.16;
}

.kpi-bg-icon :deep(.v-icon) {
  font-size: 84px;
}

.kpi-label {
  font-size: 10px;
  font-weight: 900;
  text-transform: uppercase;
  letter-spacing: 0.08em;
}

.kpi-footer {
  font-size: 10px;
  font-weight: 800;
  text-transform: uppercase;
  opacity: 0.82;
}

.bg-gradient-info {
  background: linear-gradient(135deg, #2563eb, #0ea5e9);
}

.bg-gradient-success {
  background: linear-gradient(135deg, #16a34a, #22c55e);
}

.bg-gradient-blue {
  background: linear-gradient(135deg, #0284c7, #2563eb);
}

.bg-gradient-red {
  background: linear-gradient(135deg, #dc2626, #f97316);
}

.controls-bar {
  gap: 14px;
}

.clean-input {
  outline: none;
  border: none;
  background: transparent;
  min-width: 0;
}

.clean-input::placeholder {
  opacity: 0.55;
}

/* Context buttons iguais ao padrão AdminMjReceivables: soltos, pequenos e 3D sutil */
.context-switcher-docked {
  width: auto !important;
  max-width: 100% !important;
  padding: 0 !important;
  gap: 9px !important;
  border-radius: 0 !important;
  background: transparent !important;
  border: none !important;
  box-shadow: none !important;
  backdrop-filter: none !important;
  overflow: visible !important;
}

.btn-context-pill {
  min-width: 96px !important;
  height: 24px !important;
  padding-inline: 12px !important;
  border-radius: 8px !important;
  font-size: 8.5px !important;
  letter-spacing: .06em !important;
  text-transform: uppercase !important;
}

.btn-context-3d {
  transition:
    transform .16s ease,
    box-shadow .16s ease,
    background .16s ease,
    color .16s ease,
    filter .16s ease;
}

.btn-context-3d:hover {
  transform: translateY(-1px);
}

.btn-context-3d:active {
  transform: translateY(1px);
}

.btn-context-active {
  color: #fff !important;
  box-shadow:
    0 2px 0 rgba(0,0,0,.18),
    0 8px 16px rgba(15,23,42,.18) !important;
}

.btn-context-idle {
  color: #64748b !important;
  background: rgba(255,255,255,.88) !important;
  border: 1px solid rgba(148,163,184,.20) !important;
  box-shadow:
    0 2px 0 rgba(15,23,42,.07),
    0 8px 14px rgba(15,23,42,.08) !important;
}

.bg-glass-header .btn-context-idle {
  color: rgba(255,255,255,.82) !important;
  background: rgba(255,255,255,.08) !important;
  border-color: rgba(255,255,255,.12) !important;
}

.context-dock-enter-active,
.context-dock-leave-active {
  transition: opacity .28s ease, transform .34s cubic-bezier(.2,.9,.25,1), filter .28s ease;
}

.context-dock-enter-from,
.context-dock-leave-to {
  opacity: 0;
  transform: translateY(-8px) scale(.96);
  filter: blur(4px);
}

.context-dock-enter-to,
.context-dock-leave-from {
  opacity: 1;
  transform: translateY(0) scale(1);
  filter: blur(0);
}

.floating-context-island {
  position: fixed;
  top: 18px;
  left: 50%;
  transform: translateX(-50%);
  z-index: 50;
  pointer-events: auto;
  animation: islandSoftHover 5.8s ease-in-out infinite .6s;
}

.floating-context-island::before {
  content: '';
  position: absolute;
  inset: -10px;
  pointer-events: none;
  border-radius: 26px;
  background: radial-gradient(circle at 50% 50%, rgba(59,130,246,0.13), transparent 62%);
  opacity: .75;
  animation: islandGlow 3.6s ease-in-out infinite;
}

.floating-island-inner {
  position: relative;
  z-index: 2;
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 7px;
  border-radius: 18px;
  background: rgba(255,255,255,.88);
  border: 1px solid rgba(148,163,184,.22);
  box-shadow:
    0 18px 38px rgba(15,23,42,.16),
    inset 0 1px 0 rgba(255,255,255,.90);
  backdrop-filter: blur(16px);
}

.floating-context-btn {
  min-width: 94px !important;
  height: 26px !important;
  padding-inline: 11px !important;
  border-radius: 9px !important;
  font-size: 8.5px !important;
  letter-spacing: .055em !important;
}

.context-island-float-enter-active {
  transition:
    opacity .38s ease,
    transform .52s cubic-bezier(.18, 1.15, .28, 1),
    filter .34s ease;
}

.context-island-float-leave-active {
  transition:
    opacity .30s ease,
    transform .42s cubic-bezier(.22, .8, .28, 1),
    filter .28s ease;
}

.context-island-float-enter-from {
  opacity: 0;
  transform: translateX(-50%) translateY(-42px) scale(.82);
  filter: blur(10px);
}

.context-island-float-enter-to {
  opacity: 1;
  transform: translateX(-50%) translateY(0) scale(1);
  filter: blur(0);
}

.context-island-float-leave-from {
  opacity: 1;
  transform: translateX(-50%) translateY(0) scale(1);
  filter: blur(0);
}

.context-island-float-leave-to {
  opacity: 0;
  transform: translateX(-50%) translateY(-34px) scale(.88);
  filter: blur(9px);
}

@keyframes islandSoftHover {
  0%, 100% { margin-top: 0; }
  50% { margin-top: -2px; }
}

@keyframes islandGlow {
  0%, 100% {
    opacity: .45;
    transform: scale(.96);
  }
  50% {
    opacity: .78;
    transform: scale(1.02);
  }
}

/* Grid antiga + coluna PF/PJ */
.grid-scroll {
  min-width: 100%;
}

.grid-layout {
  display: grid;
  grid-template-columns:
    48px
    minmax(230px, 1.3fr)
    76px
    145px
    220px
    170px
    145px
    125px
    125px
    115px
    145px
    150px;
  min-width: 1690px;
}

.grid-header,
.grid-row {
  align-items: center;
}

.grid-header {
  min-height: 44px;
  font-size: 10px;
  text-transform: uppercase;
  letter-spacing: 0.07em;
  font-weight: 900;
}

.sticky-head {
  position: sticky;
  top: 0;
  z-index: 4;
}

.grid-surface-light {
  background: #f8fafc;
}

.grid-surface-dark {
  background: rgba(15, 23, 42, 0.98);
}

.grid-row {
  min-height: 58px;
  border-bottom: 1px solid rgba(148, 163, 184, 0.16);
  transition: background 0.16s ease, transform 0.16s ease;
}

.grid-row:hover {
  background: rgba(59, 130, 246, 0.08);
}

.grid-row-light {
  color: #0f172a;
}

.grid-row-dark {
  color: #f8fafc;
}

.zebra-light-a {
  background: #fff;
}

.zebra-light-b {
  background: #f8fafc;
}

.zebra-dark-a {
  background: rgba(15, 23, 42, 0.82);
}

.zebra-dark-b {
  background: rgba(30, 41, 59, 0.72);
}

.client-row-blocked {
  box-shadow: inset 4px 0 0 #ef4444;
}

.cell {
  display: flex;
  align-items: center;
  min-width: 0;
  padding: 0 10px;
}

.cell.center {
  justify-content: center;
  text-align: center;
}

.header-text {
  opacity: 0.72;
}

.chk-fixed {
  transform: scale(0.88);
}

.action-btn {
  width: 30px !important;
  height: 30px !important;
  border-radius: 9px !important;
}

.min-w-0 {
  min-width: 0;
}

.text-\[10px\] {
  font-size: 10px;
}

.text-\[11px\] {
  font-size: 11px;
}

.custom-scroll {
  scrollbar-width: thin;
  scrollbar-color: rgba(148, 163, 184, 0.5) transparent;
}

.custom-scroll::-webkit-scrollbar {
  width: 8px;
  height: 8px;
}

.custom-scroll::-webkit-scrollbar-thumb {
  background: rgba(148, 163, 184, 0.45);
  border-radius: 999px;
}

/* Modal fixo, limpo, sem degradê exagerado */
.client-editor-card {
  height: 760px;
  max-height: 92vh;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.editor-header-clean {
  min-height: 76px;
  padding: 16px 20px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  border-bottom: 1px solid rgba(148, 163, 184, 0.18);
  background: rgba(248, 250, 252, 0.92);
}

.text-white .editor-header-clean {
  background: rgba(15, 23, 42, 0.82);
}

.editor-body-fixed {
  display: grid;
  grid-template-columns: 245px minmax(0, 1fr);
  flex: 1;
  min-height: 0;
}

.editor-side-clean {
  padding: 18px;
  border-right: 1px solid rgba(148, 163, 184, 0.18);
  background: rgba(248, 250, 252, 0.72);
  overflow: hidden;
}

.text-white .editor-side-clean {
  background: rgba(15, 23, 42, 0.42);
}

.avatar-clean-box {
  padding: 16px;
  text-align: center;
  border-radius: 16px;
  border: 1px solid rgba(148, 163, 184, 0.18);
  background: rgba(255, 255, 255, 0.72);
}

.text-white .avatar-clean-box {
  background: rgba(255, 255, 255, 0.05);
}

.side-stat-card {
  padding: 14px;
  border-radius: 14px;
  border: 1px solid rgba(148, 163, 184, 0.18);
  background: rgba(255, 255, 255, 0.74);
}

.text-white .side-stat-card {
  background: rgba(255, 255, 255, 0.05);
}

.side-stat-card.side-danger {
  border-color: rgba(239, 68, 68, 0.25);
  background: rgba(254, 242, 242, 0.88);
}

.side-stat-card.side-success {
  border-color: rgba(34, 197, 94, 0.22);
  background: rgba(240, 253, 244, 0.88);
}

.text-white .side-stat-card.side-danger {
  background: rgba(127, 29, 29, 0.28);
}

.text-white .side-stat-card.side-success {
  background: rgba(20, 83, 45, 0.22);
}

.side-stat-label {
  font-size: 9px;
  font-weight: 900;
  text-transform: uppercase;
  letter-spacing: .08em;
  opacity: .60;
  margin-bottom: 4px;
}

.side-stat-value {
  font-size: 13px;
  font-weight: 950;
  line-height: 1.2;
}

.side-stat-hint {
  font-size: 11px;
  opacity: .68;
  margin-top: 5px;
}

.editor-main-clean {
  min-width: 0;
  min-height: 0;
  display: flex;
  flex-direction: column;
}

.editor-tabs-clean {
  padding: 0 18px;
  border-bottom: 1px solid rgba(148, 163, 184, 0.14);
}

.editor-scroll-fixed {
  flex: 1;
  overflow-y: auto;
  padding: 18px;
  background: rgba(248, 250, 252, 0.44);
}

.text-white .editor-scroll-fixed {
  background: rgba(2, 6, 23, 0.24);
}

.modal-section-clean {
  padding: 18px;
  border-radius: 16px;
  border: 1px solid rgba(148, 163, 184, 0.18);
  background: rgba(255,255,255,0.86);
  box-shadow: 0 10px 22px rgba(15,23,42,0.04);
}

.text-white .modal-section-clean {
  background: rgba(15, 23, 42, 0.54);
  border-color: rgba(255,255,255,0.10);
}

.section-title-row-clean {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 18px;
}

.section-title-clean {
  font-size: 14px;
  font-weight: 950;
  text-transform: uppercase;
  letter-spacing: .04em;
}

.section-subtitle-clean {
  font-size: 12px;
  opacity: .62;
  font-weight: 700;
  margin-top: 2px;
}

.input-label {
  display: block;
  margin-bottom: 6px;
  font-size: 10px;
  font-weight: 900;
  text-transform: uppercase;
  letter-spacing: 0.08em;
  opacity: 0.72;
}

.row-gap {
  row-gap: 12px;
}

.ui-field :deep(.v-field) {
  border-radius: 12px;
  box-shadow: 0 6px 14px rgba(15,23,42,0.035);
}

.block-control-clean {
  height: 100%;
  min-height: 74px;
  padding: 14px;
  border-radius: 14px;
  border: 1px solid rgba(148, 163, 184, 0.18);
  background: rgba(248, 250, 252, 0.92);
}

.block-control-clean.danger {
  border-color: rgba(239, 68, 68, 0.28);
  background: rgba(254, 242, 242, 0.96);
}

.block-control-clean.safe {
  border-color: rgba(34, 197, 94, 0.22);
  background: rgba(240, 253, 244, 0.96);
}

.text-white .block-control-clean {
  background: rgba(15, 23, 42, 0.58);
}

.block-control-title {
  font-size: 13px;
  font-weight: 950;
  text-transform: uppercase;
  letter-spacing: .04em;
}

.block-control-copy {
  font-size: 12px;
  opacity: .68;
  font-weight: 700;
  margin-top: 3px;
}

.proof-upload-box-clean {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  padding: 14px;
  border-radius: 14px;
  border: 1px dashed rgba(148, 163, 184, 0.45);
  background: rgba(248,250,252,0.70);
}

.text-white .proof-upload-box-clean {
  background: rgba(15,23,42,0.50);
}

.editor-footer-clean {
  min-height: 64px;
  padding: 12px 18px;
  border-top: 1px solid rgba(148, 163, 184, 0.18);
  background: rgba(248, 250, 252, 0.92);
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
}

.text-white .editor-footer-clean {
  background: rgba(15, 23, 42, 0.82);
}

@media (max-width: 960px) {
  .header-bar {
    align-items: flex-start !important;
    flex-direction: column;
    gap: 16px;
  }

  .controls-bar {
    align-items: stretch !important;
    flex-direction: column;
  }

  .search-wrap {
    width: 100% !important;
  }

  .context-switcher-docked {
    gap: 7px !important;
    overflow-x: auto !important;
    flex-wrap: nowrap !important;
    scrollbar-width: none;
  }

  .context-switcher-docked::-webkit-scrollbar {
    display: none;
  }

  .btn-context-pill,
  .floating-context-btn {
    min-width: 86px !important;
    font-size: 7.8px !important;
    padding-inline: 8px !important;
  }

  .floating-context-island {
    top: auto;
    bottom: 18px;
    max-width: calc(100vw - 20px);
  }

  .floating-context-island::before {
    display: none;
  }

  .floating-island-inner {
    max-width: calc(100vw - 20px);
    overflow-x: auto;
    scrollbar-width: none;
  }

  .floating-island-inner::-webkit-scrollbar {
    display: none;
  }

  .client-editor-card {
    height: 92vh;
  }

  .editor-body-fixed {
    grid-template-columns: 1fr;
  }

  .editor-side-clean {
    display: none;
  }

  .editor-header-clean,
  .editor-footer-clean {
    flex-direction: column;
    align-items: stretch;
  }
}


/* ===== Correção visual: padrão OrderManagement ===== */
.clients-taskbar {
  border-radius: 18px;
  padding: 12px;
  border: 1px solid rgba(148, 163, 184, 0.18);
  box-shadow:
    0 10px 28px rgba(15,23,42,0.06),
    inset 0 1px 0 rgba(255,255,255,0.74);
}

.clients-taskbar-light {
  background: rgba(255,255,255,0.92);
}

.clients-taskbar-dark {
  background: rgba(15,23,42,0.76);
  border-color: rgba(255,255,255,0.08);
}

.taskbar-main {
  display: grid;
  grid-template-columns: minmax(280px, 1fr) auto;
  align-items: center;
  gap: 14px;
}

.taskbar-search,
.taskbar-action-btn {
  height: 42px !important;
  border-radius: 14px !important;
}

.taskbar-search {
  padding: 0 14px;
  border: 1px solid rgba(148,163,184,0.18);
}

.search-light {
  background: rgba(248,250,252,0.95);
}

.search-dark {
  background: rgba(2,6,23,0.34);
  border-color: rgba(255,255,255,0.10);
}

.taskbar-right {
  display: flex;
  align-items: center;
  justify-content: flex-end;
  gap: 10px;
}

.tenant-status-chip {
  height: 34px !important;
  border-radius: 12px !important;
}

.clients-filter-tray {
  overflow: hidden;
}

.clients-filter-tray-light {
  background: rgba(255,255,255,0.98);
}

.clients-filter-tray-dark {
  background: rgba(15,23,42,0.98);
}

.tray-header {
  border-bottom: 1px solid rgba(148,163,184,0.14);
}

.tray-icon {
  display: grid;
  place-items: center;
  width: 34px;
  height: 34px;
  border-radius: 10px;
  background: rgba(59,130,246,0.10);
  color: #2563eb;
}

.tray-section-title {
  font-size: 10px;
  font-weight: 950;
  text-transform: uppercase;
  letter-spacing: .08em;
  opacity: .62;
}

.tray-field :deep(.v-field) {
  min-height: 40px !important;
  border-radius: 12px !important;
}

.tray-chip-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 8px;
}

.tray-chip-btn {
  height: 36px;
  border: 1px solid rgba(148,163,184,0.22);
  border-radius: 12px;
  background: rgba(248,250,252,0.86);
  font-size: 11px;
  font-weight: 950;
  text-transform: uppercase;
  letter-spacing: .04em;
  color: #475569;
  box-shadow:
    0 1px 0 rgba(15,23,42,.08),
    0 7px 12px rgba(15,23,42,.05);
  transition: .16s ease;
}

.tray-chip-btn:hover {
  transform: translateY(-1px);
}

.tray-chip-btn--active {
  background: #2563eb;
  color: white;
  border-color: rgba(37,99,235,.80);
  box-shadow:
    0 2px 0 rgba(0,0,0,.16),
    0 10px 18px rgba(37,99,235,.20);
}

.tray-action {
  width: 100%;
  display: flex;
  align-items: center;
  gap: 12px;
  min-height: 54px;
  padding: 10px;
  border: 1px solid rgba(148,163,184,0.16);
  border-radius: 14px;
  background: rgba(248,250,252,0.84);
  text-align: left;
  margin-bottom: 8px;
  transition: .16s ease;
}

.tray-action:hover {
  transform: translateY(-1px);
  box-shadow: 0 10px 20px rgba(15,23,42,.08);
}

.clients-filter-tray-dark .tray-action {
  background: rgba(255,255,255,0.06);
  border-color: rgba(255,255,255,0.10);
}

.tray-action-icon {
  display: grid;
  place-items: center;
  width: 34px;
  height: 34px;
  flex: 0 0 34px;
  border-radius: 11px;
  background: rgba(148,163,184,0.12);
}

.tray-action strong {
  display: block;
  font-size: 12px;
  font-weight: 950;
  line-height: 1.15;
}

.tray-action small {
  display: block;
  margin-top: 3px;
  font-size: 10px;
  opacity: .64;
  font-weight: 700;
  line-height: 1.15;
}

/* Grid igual OrderManagement: card, header separado, linhas com respiro e badges alinhadas */
.clients-grid-card {
  border-radius: 20px !important;
  border: 1px solid rgba(148,163,184,0.18) !important;
  box-shadow:
    0 16px 32px rgba(15,23,42,0.08),
    inset 0 1px 0 rgba(255,255,255,0.74) !important;
}

.clients-grid-card-light {
  background: rgba(255,255,255,0.96) !important;
}

.clients-grid-card-dark {
  background: rgba(15,23,42,0.72) !important;
  border-color: rgba(255,255,255,0.08) !important;
}

.grid-scroll {
  padding: 12px;
}

.grid-layout {
  display: grid;
  grid-template-columns:
    48px
    minmax(250px, 1.35fr)
    76px
    150px
    minmax(230px, 1fr)
    180px
    160px
    130px
    130px
    118px
    160px
    166px;
  min-width: 1840px;
}

.grid-header {
  min-height: 48px;
  border-radius: 14px;
  margin-bottom: 10px;
  font-size: 10px;
  text-transform: uppercase;
  letter-spacing: .075em;
  font-weight: 950;
  box-shadow: inset 0 -1px 0 rgba(148,163,184,0.16);
}

.sticky-head {
  top: 12px;
}

.grid-surface-light {
  background: #f1f5f9;
}

.grid-surface-dark {
  background: rgba(2, 6, 23, 0.72);
}

.orderlike-row {
  min-height: 62px;
  margin-bottom: 8px;
  border-radius: 14px;
  border: 1px solid rgba(148,163,184,0.16);
  box-shadow: 0 8px 16px rgba(15,23,42,0.035);
  overflow: hidden;
}

.orderlike-row:hover {
  transform: translateY(-1px);
  box-shadow: 0 12px 22px rgba(15,23,42,0.07);
}

.grid-row-light {
  background: #ffffff;
  color: #0f172a;
}

.grid-row-dark {
  background: rgba(15,23,42,0.84);
  color: #f8fafc;
}

.client-row-blocked {
  box-shadow:
    inset 4px 0 0 #ef4444,
    0 8px 16px rgba(15,23,42,0.035) !important;
}

.cell {
  padding: 0 12px;
  border-right: 1px solid rgba(148,163,184,0.10);
}

.cell:last-child {
  border-right: none;
}

.action-btn {
  width: 32px !important;
  height: 32px !important;
  border-radius: 10px !important;
}

.chip-3d {
  min-height: 24px !important;
}

@media (max-width: 960px) {
  .taskbar-main {
    grid-template-columns: 1fr;
  }

  .taskbar-right {
    justify-content: flex-start;
    overflow-x: auto;
    padding-bottom: 2px;
  }

  .taskbar-action-btn {
    min-width: 126px;
  }

  .tenant-status-chip {
    min-width: max-content;
  }
}


/* ========================================================
   GRID CORRIGIDA: MESMO LAYOUT DO OrderManagement.vue
   - sem linhas em card
   - sem padding interno falso
   - células contínuas com divisórias
   ======================================================== */
.clients-grid-card {
  border-radius: 0 !important;
  box-shadow: none !important;
  border: 1px solid rgba(148,163,184,0.22) !important;
}

.grid-scroll {
  padding: 0 !important;
  scrollbar-gutter: stable both-edges;
}

.grid-header,
.grid-row {
  display: grid !important;
  align-items: stretch !important;
  width: 100% !important;
  border-bottom: 1px solid rgba(0,0,0,0.08) !important;
  min-width: 1500px !important;
  margin: 0 !important;
  border-radius: 0 !important;
  overflow: visible !important;
  box-shadow: none !important;
}

/* Clientes tem uma coluna PF/PJ a mais, mas segue a mesma lógica do OrderManagement */
.grid-layout {
  grid-template-columns:
    48px
    minmax(240px, 1.35fr)
    76px
    150px
    minmax(220px, 1fr)
    180px
    160px
    130px
    130px
    118px
    160px
    166px !important;
  min-width: 1740px !important;
}

.cell {
  padding: 10px 12px !important;
  display: flex !important;
  align-items: center !important;
  border-right: 1px solid rgba(0,0,0,0.08) !important;
  min-height: 56px !important;
  overflow: hidden !important;
  transition: background-color 0.2s ease !important;
}

.cell:last-child {
  border-right: 0 !important;
}

.center {
  justify-content: center !important;
  text-align: center !important;
}

.right {
  justify-content: flex-end !important;
  text-align: right !important;
}

.grid-header .cell {
  min-height: 48px !important;
  font-size: 13px !important;
  font-weight: 900 !important;
  text-transform: uppercase !important;
  letter-spacing: .6px !important;
}

.header-text {
  font-size: 13px !important;
  font-weight: 800 !important;
  text-transform: uppercase !important;
}

/* Exatamente a lógica visual do OrderManagement */
.grid-surface-light .cell {
  background: #f5f7fa !important;
  color: rgba(0,0,0,0.9) !important;
  border-color: rgba(0,0,0,0.12) !important;
}

.grid-surface-dark .cell {
  background: rgba(255,255,255,0.08) !important;
  color: rgba(255,255,255,0.80) !important;
  border-color: rgba(255,255,255,0.10) !important;
}

.grid-row-light .cell {
  background: #fff !important;
  border-color: rgba(0,0,0,0.08) !important;
}

.grid-row-light:nth-child(even) .cell {
  background: #fafafa !important;
}

.grid-row-light:hover .cell {
  background: #f7fafc !important;
}

.grid-row-dark .cell {
  background: rgba(255,255,255,0.04) !important;
  border-color: rgba(255,255,255,0.08) !important;
}

.grid-row-dark:nth-child(even) .cell {
  background: rgba(255,255,255,0.015) !important;
}

.grid-row-dark:hover .cell {
  background: rgba(255,255,255,0.07) !important;
}

.sticky-head {
  position: sticky !important;
  top: 0 !important;
  z-index: 10 !important;
  box-shadow: 0 8px 16px -4px rgba(0,0,0,0.12) !important;
}

/* Linha bloqueada mantém o alerta sem virar card */
.client-row-blocked .cell:first-child {
  box-shadow: inset 4px 0 0 #ef4444 !important;
}

/* Tipografia e pills iguais ao OrderManagement */
.pill-ref {
  font-size: 13px;
  font-weight: 900;
  font-family: monospace;
  background: rgba(0,0,0,0.06);
  padding: 4px 8px;
  border-radius: 6px;
}

.list-text-11 {
  font-size: 14px !important;
  line-height: 1.25 !important;
}

.list-text-10 {
  font-size: 13px !important;
  line-height: 1.25 !important;
}

.solid-chip {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  height: 26px;
  padding: 0 12px;
  border-radius: 6px;
  font-size: 11px;
  font-weight: 900;
  color: #fff;
  white-space: nowrap;
  text-transform: uppercase;
}

.chip-success { background: #2e7d32; }
.chip-info { background: #1976d2; }
.chip-warning { background: #f57f17; }
.chip-danger { background: #c62828; }
.chip-default { background: #455a64; }

/* Ações iguais ao OrderManagement */
.actions-inline {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
}

.action-btn {
  width: 30px !important;
  height: 30px !important;
  min-width: 30px !important;
  border-radius: 15% !important;
  color: #fff !important;
}

.action-btn :deep(.v-icon) {
  color: #fff !important;
}

.action-edit,
.action-btn.bg-primary,
.action-btn.text-primary {
  background: #1976d2 !important;
}

.action-pay {
  background: #2e7d32 !important;
}

.action-delete {
  background: #e53935 !important;
}

.action-more {
  background: #1b5e20 !important;
}

/* Corrige os botões atuais de cliente para cores sólidas no padrão da grid de pedidos */
.cell .v-btn.action-btn:nth-child(1) {
  background: #1976d2 !important;
}

.cell .v-btn.action-btn:nth-child(2) {
  background: #1976d2 !important;
}

.cell .v-btn.action-btn:nth-child(3) {
  background: #fb8c00 !important;
}

.cell .v-btn.action-btn:nth-child(4) {
  background: #e53935 !important;
}

/* Barra de filtros no mesmo padrão/tamanho do OrderManagement */
.clients-taskbar {
  border-radius: 18px !important;
  padding: 12px !important;
  box-shadow:
    0 14px 30px rgba(15,23,42,0.06),
    inset 0 1px 0 rgba(255,255,255,0.72) !important;
}

.taskbar-main {
  display: flex !important;
  align-items: center !important;
  justify-content: space-between !important;
  gap: 14px !important;
  width: 100% !important;
}

.taskbar-search {
  flex: 1 1 420px !important;
  min-width: 260px !important;
  max-width: 760px !important;
  height: 42px !important;
  border-radius: 0 !important;
  padding: 0 12px !important;
}

.taskbar-right {
  display: flex !important;
  align-items: center !important;
  justify-content: flex-end !important;
  gap: 10px !important;
  flex: 0 0 auto !important;
  margin-left: auto !important;
}

.taskbar-action-btn {
  height: 42px !important;
  min-width: 128px !important;
  border-radius: 6px !important;
}

.tenant-status-chip {
  height: 42px !important;
  border-radius: 6px !important;
  padding-inline: 14px !important;
}

@media (max-width: 960px) {
  .taskbar-main {
    flex-direction: column !important;
    align-items: stretch !important;
  }

  .taskbar-search {
    max-width: 100% !important;
    width: 100% !important;
  }

  .taskbar-right {
    width: 100% !important;
    justify-content: flex-start !important;
    overflow-x: auto !important;
  }
}
</style>
