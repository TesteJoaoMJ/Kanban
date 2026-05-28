<template>
  <div
    class="chart-accounts-layout font-sans fill-height d-flex flex-column relative overflow-hidden"
    :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 text-grey-darken-4' : 'bg-glass-dark text-white'"
  >
    <div v-if="themeStore.currentMode !== 'light'" class="background-carousel-wrapper">
      <v-carousel cycle height="100%" hide-delimiters :show-arrows="false" interval="15000" class="fill-height">
        <v-carousel-item src="@/assets/1.jpg" cover></v-carousel-item>
        <v-carousel-item src="@/assets/2.jpg" cover></v-carousel-item>
        <v-carousel-item src="@/assets/3.jpg" cover></v-carousel-item>
      </v-carousel>
      <div class="background-overlay"></div>
    </div>

    <div class="content-wrapper d-flex flex-column fill-height z-10 relative">

      <div
        class="header-bar px-4 py-3 px-md-6 py-md-4 d-flex flex-column flex-md-row align-md-center justify-space-between flex-shrink-0"
        :class="themeStore.currentMode === 'light' ? 'bg-white border-b border-grey-lighten-2 shadow-sm' : 'bg-glass-header border-bottom-white-05'"
        style="gap: 12px;"
      >
        <div class="d-flex flex-column">
           <div class="d-flex align-center gap-2">
             <div class="text-h6 font-weight-black tracking-tight leading-none" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">
                Plano de Contas
             </div>
             <v-chip size="x-small" color="info" class="font-weight-bold ml-2 rounded-0">GERENCIAL</v-chip>
          </div>
          <div class="text-caption opacity-70 mt-1">Gestão, Unificação e Auditoria de Estrutura Financeira.</div>
        </div>

        <div class="d-flex justify-center flex-grow-1 px-4">
             <v-tabs
                v-model="activeTab"
                density="compact"
                :color="themeStore.currentMode === 'light' ? 'primary' : 'white'"
                class="rounded-0 overflow-hidden"
                :bg-color="themeStore.currentMode === 'light' ? 'grey-lighten-4' : 'rgba(255,255,255,0.05)'"
             >
                <v-tab value="all" class="text-caption font-weight-bold px-6 rounded-0">
                    <v-icon start size="small">mdi-apps</v-icon> Todas ({{ rawAccounts.length }})
                </v-tab>
                <v-tab value="system" class="text-caption font-weight-bold px-6 rounded-0">
                    <v-icon start size="small" color="blue">mdi-monitor-dashboard</v-icon> Sistema
                </v-tab>
                <v-tab value="erp" class="text-caption font-weight-bold px-6 rounded-0">
                    <v-icon start size="small" color="orange">mdi-cloud-download</v-icon> ERP Importado
                </v-tab>
             </v-tabs>
        </div>

        <div class="d-flex align-center overflow-x-auto pb-1 pb-md-0" style="gap: 10px;">
          <v-btn
            variant="flat"
            color="blue-grey-darken-3"
            class="text-caption font-weight-bold btn-rect"
            prepend-icon="mdi-history"
            @click="historyModal.show = true"
          >
             Log de Auditoria
          </v-btn>
          <v-btn
            color="primary"
            variant="flat"
            class="btn-rect px-3 px-md-4 font-weight-bold text-caption text-uppercase letter-spacing-1 flex-shrink-0"
            prepend-icon="mdi-plus"
            height="40"
            @click="openAccountModal()"
          >
             Nova Conta
          </v-btn>
        </div>
      </div>

      <div class="px-4 px-md-6 py-2 py-md-3 flex-shrink-0">
        <div
          class="controls-bar d-flex flex-column"
          :class="themeStore.currentMode === 'light' ? 'controls-light' : 'controls-dark'"
          style="gap: 10px;"
        >
            <div class="d-flex align-center flex-wrap justify-space-between w-100" style="gap: 10px;">
              <div class="flex-grow-1" style="min-width: 250px;">
                  <v-text-field
                    v-model="filters.search"
                    prepend-inner-icon="mdi-magnify"
                    placeholder="Pesquisar por nome ou código..."
                    variant="outlined"
                    density="compact"
                    hide-details
                    bg-color="white"
                    color="primary"
                    class="rounded-0-input"
                    clearable
                  ></v-text-field>
              </div>

              <div style="width: 160px;">
                   <v-select
                        v-model="filters.usageStatus"
                        :items="[
                            {title: 'Todos', value: 'all'},
                            {title: 'Em Uso (Com Lançamentos)', value: 'used'},
                            {title: 'Sem Uso (Vazio)', value: 'unused'}
                        ]"
                        label="Status de Uso"
                        variant="outlined"
                        density="compact"
                        hide-details
                        bg-color="white"
                        color="primary"
                        class="rounded-0-input"
                   ></v-select>
              </div>

               <div style="width: 160px;">
                   <v-select
                        v-model="filters.sortBy"
                        :items="[
                            {title: 'Código (Padrão)', value: 'code'},
                            {title: 'Nome (A-Z)', value: 'name'},
                            {title: 'Mais Usados', value: 'most_used'},
                            {title: 'Menos Usados', value: 'least_used'}
                        ]"
                        label="Ordenar Por"
                        variant="outlined"
                        density="compact"
                        hide-details
                        bg-color="white"
                        color="primary"
                        prepend-inner-icon="mdi-sort"
                        class="rounded-0-input"
                   ></v-select>
              </div>

              <v-btn-toggle
                v-model="filters.type"
                density="compact"
                color="primary"
                variant="outlined"
                class="flex-shrink-0 bg-white rounded-0"
                divided
              >
                  <v-btn value="all" class="text-caption font-weight-bold rounded-0">Todos</v-btn>
                  <v-btn value="Receita" class="text-caption font-weight-bold text-success rounded-0">Receitas</v-btn>
                  <v-btn value="Despesa" class="text-caption font-weight-bold text-error rounded-0">Despesas</v-btn>
              </v-btn-toggle>

              <v-btn variant="text" icon="mdi-refresh" rounded="0" @click="fetchAccounts" :loading="loading" title="Atualizar Dados"></v-btn>
            </div>
        </div>
      </div>

      <div class="d-flex flex-grow-1 overflow-hidden relative">
          <div class="flex-grow-1 overflow-hidden d-flex flex-column px-4 px-md-6 pb-0 transition-all">
            <v-card
              class="flex-grow-1 d-flex flex-column rounded-0 border-thin overflow-hidden"
              :class="themeStore.currentMode === 'light' ? 'bg-white shadow-sm' : 'glass-card border-white-05'"
              :elevation="0"
            >
              <div class="grid-scroll flex-grow-1 overflow-auto custom-scroll relative">
                <div
                  class="grid-header sticky-head"
                  :class="themeStore.currentMode === 'light' ? 'grid-surface-light' : 'grid-surface-dark'"
                >
                  <div class="cell cell-check center">
                    <v-checkbox-btn disabled density="compact" class="rounded-0-input"></v-checkbox-btn>
                  </div>

                  <div class="cell header-text" style="width: 100px;">Código</div>
                  <div class="cell header-text flex-grow-1">Nome da Conta / Estrutura</div>
                  <div class="cell header-text center" style="width: 100px;">Origem</div>
                  <div class="cell header-text center" style="width: 100px;">Natureza</div>
                  <div class="cell header-text center" style="width: 140px;">Uso Real</div>
                  <div class="cell header-text center" style="width: 80px;">Status</div>
                  <div class="cell header-text center" style="width: 100px;">Ações</div>
                </div>

                <div v-if="loading" class="d-flex flex-column justify-center align-center h-100 py-10 min-w-full">
                  <v-progress-circular indeterminate color="primary" size="32" width="3"></v-progress-circular>
                  <span class="text-caption mt-2 font-weight-bold opacity-60">Carregando e calculando usos reais...</span>
                </div>

                <div v-else-if="paginatedItems.length === 0" class="d-flex flex-column justify-center align-center h-100 opacity-60 gap-2 py-10 min-w-full">
                  <v-icon size="48" color="grey-lighten-1">mdi-filter-off</v-icon>
                  <span class="text-body-2 font-weight-medium text-grey">Nenhuma conta encontrada com os filtros atuais.</span>
                  <v-btn variant="text" color="primary" class="btn-rect" @click="clearFilters">Limpar Filtros</v-btn>
                </div>

                <div
                  v-else
                  v-for="(item, index) in paginatedItems"
                  :key="item.id"
                  class="grid-row"
                  :class="[
                    themeStore.currentMode === 'light' ? 'grid-row-light' : 'grid-row-dark',
                    index % 2 === 0 ? (themeStore.currentMode === 'light' ? 'zebra-light-a' : 'zebra-dark-a') : (themeStore.currentMode === 'light' ? 'zebra-light-b' : 'zebra-dark-b'),
                    selectedMap.has(item.id) ? (themeStore.currentMode === 'light' ? 'grid-selected-light' : 'grid-selected-dark') : ''
                  ]"
                >
                    <div class="cell cell-check center">
                        <v-checkbox-btn
                            :model-value="selectedMap.has(item.id)"
                            @update:model-value="toggleSelection(item)"
                            density="compact"
                            color="success"
                            class="chk-fixed rounded-0-input"
                        ></v-checkbox-btn>
                    </div>

                    <div class="cell font-mono font-weight-bold text-caption" style="width: 100px;">
                        {{ item.code }}
                    </div>

                    <div class="cell flex-grow-1" :style="{ paddingLeft: (item.level * 20 + 10) + 'px' }">
                        <div class="d-flex align-center">
                            <v-icon v-if="item.is_group" size="16" color="info" class="mr-2 opacity-80">mdi-folder-outline</v-icon>
                            <v-icon v-else size="16" :color="item.type === 'Receita' ? 'success' : 'error'" class="mr-2 opacity-80">mdi-file-document-outline</v-icon>

                            <span class="text-body-2 text-truncate" :class="item.is_group ? 'font-weight-black text-uppercase' : 'font-weight-medium'">
                                {{ item.name }}
                            </span>
                        </div>
                    </div>

                     <div class="cell center" style="width: 100px;">
                        <v-chip size="x-small" :color="item.is_erp ? 'orange' : 'blue'" variant="tonal" class="font-weight-bold rounded-0">
                            {{ item.is_erp ? 'ERP' : 'SISTEMA' }}
                        </v-chip>
                    </div>

                    <div class="cell center" style="width: 100px;">
                        <span class="text-caption font-weight-bold" :class="item.type === 'Receita' ? 'text-success' : (item.type === 'Despesa' ? 'text-error' : 'text-grey')">
                            {{ item.type }}
                        </span>
                    </div>

                    <div class="cell center" style="width: 140px;">
                        <v-btn
                            v-if="!item.is_group"
                            size="small"
                            variant="tonal"
                            height="24"
                            class="text-caption font-weight-bold px-3 btn-rect"
                            :color="getUsageCount(item.id) > 0 ? 'primary' : 'grey-lighten-1'"
                            @click.stop="openUsageDetail(item)"
                        >
                            <v-icon start size="12">mdi-link-variant</v-icon>
                            {{ getUsageCount(item.id) }} lançamentos
                        </v-btn>
                        <span v-else class="text-caption opacity-40">-</span>
                    </div>

                     <div class="cell center" style="width: 80px;">
                        <v-icon size="16" :color="item.active ? 'success' : 'grey'">
                            {{ item.active ? 'mdi-check-circle-outline' : 'mdi-close-circle-outline' }}
                        </v-icon>
                    </div>

                    <div class="cell center" style="width: 100px;">
                        <div class="actions-inline">
                            <v-btn icon size="small" class="action-btn action-edit" @click.stop="openAccountModal(item)" title="Editar" variant="flat">
                                <v-icon size="16">mdi-pencil</v-icon>
                            </v-btn>
                            <v-btn icon size="small" class="action-btn action-del" @click.stop="deleteAccount(item)" title="Excluir / Migrar" variant="flat">
                                <v-icon size="16">mdi-trash-can-outline</v-icon>
                            </v-btn>
                        </div>
                    </div>
                </div>
              </div>

              <div class="flex-shrink-0 border-t px-4 py-2 d-flex align-center justify-space-between bg-white z-20">
                 <div class="d-flex align-center gap-4">
                     <div class="text-caption opacity-80">
                         Mostrando <strong>{{ paginatedItems.length }}</strong> de <strong>{{ filteredItems.length }}</strong> contas
                     </div>
                 </div>
                 <v-pagination
                    v-model="page"
                    :length="pageCount"
                    density="compact"
                    active-color="primary"
                    variant="tonal"
                    size="small"
                    total-visible="5"
                 ></v-pagination>
              </div>
            </v-card>
          </div>

          <v-slide-x-reverse-transition>
            <div v-if="selectedMap.size > 0" class="selection-drawer flex-shrink-0 d-flex flex-column border-l shadow-xl" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-surface-variant'" style="width: 320px;">
                <div class="px-4 py-3 bg-orange-darken-3 text-white d-flex align-center justify-space-between">
                    <span class="text-subtitle-2 font-weight-black">Selecionados ({{ selectedMap.size }})</span>
                    <v-btn icon="mdi-close" variant="text" rounded="0" density="compact" @click="selectedMap.clear()"></v-btn>
                </div>
                <div class="flex-grow-1 overflow-y-auto pa-2 bg-grey-lighten-5">
                    <div v-for="[id, item] in selectedMap" :key="id" class="bg-white rounded-0 border pa-2 mb-2 relative">
                         <div class="d-flex justify-space-between align-start">
                             <div>
                                 <div class="text-caption font-mono font-weight-bold">{{ item.code }}</div>
                                 <div class="text-body-2 font-weight-bold leading-tight">{{ item.name }}</div>
                                 <div class="text-[10px] mt-1 text-grey">{{ item.is_erp ? 'Origem: ERP' : 'Origem: Sistema' }}</div>
                             </div>
                             <v-btn icon="mdi-close" variant="text" size="x-small" color="grey" rounded="0" @click="selectedMap.delete(id)"></v-btn>
                         </div>
                         <v-divider class="my-2"></v-divider>
                         <div class="d-flex align-center justify-space-between">
                             <span class="text-caption text-grey">Uso: {{ getUsageCount(id) }}</span>
                             <v-chip size="x-small" class="rounded-0" :color="item.type==='Receita'?'success':'error'">{{ item.type }}</v-chip>
                         </div>
                    </div>
                </div>
                <div class="pa-3 border-t bg-white d-flex flex-column gap-2">
                    <v-btn
                        block
                        color="orange-darken-3"
                        variant="flat"
                        class="font-weight-bold btn-rect"
                        :prepend-icon="selectedMap.size === 1 ? 'mdi-swap-horizontal' : 'mdi-merge'"
                        :disabled="selectedMap.size === 0"
                        @click="openMergeModal"
                    >
                        {{ selectedMap.size === 1 ? 'Migrar Conta' : 'Unificar (Merge)' }}
                    </v-btn>
                    <v-btn
                        block
                        color="red-darken-1"
                        variant="tonal"
                        class="font-weight-bold btn-rect"
                        prepend-icon="mdi-trash-can"
                        @click="bulkDelete"
                    >
                        Excluir Seleção
                    </v-btn>
                </div>
            </div>
          </v-slide-x-reverse-transition>
      </div>

    </div>

    <v-dialog v-model="migrationModal.show" max-width="1100" persistent scrollable>
        <v-card class="rounded-0 d-flex flex-column border-thin h-100" style="max-height: 85vh;">
            <div class="px-6 py-4 bg-error text-white d-flex align-center justify-space-between flex-shrink-0">
                <div class="d-flex align-center gap-3">
                    <v-icon size="28">mdi-alert-circle-outline</v-icon>
                    <div>
                        <div class="text-subtitle-1 font-weight-black text-uppercase letter-spacing-1">Ação Necessária para Exclusão</div>
                        <div class="text-caption opacity-90">
                            A conta <strong>{{ migrationModal.account?.name }}</strong> possui <strong>{{ migrationModal.items.length }}</strong> lançamentos ativos. Você deve migrá-los para prosseguir.
                        </div>
                    </div>
                </div>
                <v-btn icon="mdi-close" variant="text" rounded="0" @click="migrationModal.show = false"></v-btn>
            </div>

            <div class="pa-4 border-b bg-grey-lighten-4 flex-shrink-0">
                <div class="text-caption font-weight-bold mb-2 text-uppercase text-grey-darken-1">Alteração em Lote</div>
                <div class="d-flex align-center gap-3">
                     <v-autocomplete
                        v-model="migrationModal.bulkTargetId"
                        :items="allAccounts"
                        item-title="name"
                        item-value="id"
                        label="Novo Plano de Contas para Todos"
                        variant="outlined"
                        density="compact"
                        hide-details
                        class="flex-grow-1 bg-white rounded-0-input"
                     >
                        <template v-slot:item="{ props, item: slotItem }">
                            <v-list-item v-bind="props" :subtitle="slotItem?.raw?.code" :disabled="slotItem?.value === migrationModal.account?.id" class="rounded-0"></v-list-item>
                        </template>
                     </v-autocomplete>
                     <v-btn color="primary" variant="flat" class="btn-rect" height="40" @click="applyBulkTarget" :disabled="!migrationModal.bulkTargetId">Aplicar a Todos</v-btn>
                </div>
            </div>

            <div class="flex-grow-1 overflow-y-auto custom-scroll pa-0 bg-white">
                <v-table density="compact" class="text-caption align-middle">
                    <thead class="bg-grey-lighten-5">
                        <tr>
                            <th class="font-weight-bold text-uppercase" width="100">Data</th>
                            <th class="font-weight-bold text-uppercase">Descrição Original</th>
                            <th class="font-weight-bold text-uppercase text-right" width="120">Valor</th>
                            <th class="font-weight-bold text-uppercase" width="400">Novo Plano (Individual)</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr v-for="row in migrationModal.items" :key="row.id + row.sourceTable" class="border-b hover-bg-grey">
                            <td class="font-mono text-grey-darken-2">{{ formatDate(row.due_date) }}</td>
                            <td class="text-truncate font-weight-medium" style="max-width: 250px;" :title="row.description">{{ row.description || 'Sem descrição' }}</td>
                            <td class="font-weight-black text-right">{{ formatCurrency(row.value) }}</td>
                            <td class="pa-2">
                                <div class="d-flex align-center gap-2 w-100">
                                    <v-select
                                        v-model="row.targetId"
                                        :items="allAccounts"
                                        item-title="name"
                                        item-value="id"
                                        placeholder="Manter original..."
                                        variant="outlined"
                                        density="compact"
                                        hide-details
                                        class="flex-grow-1 rounded-0-input"
                                    >
                                        <template v-slot:item="{ props, item: slotItem }">
                                            <v-list-item v-bind="props" :subtitle="slotItem?.raw?.code" :disabled="slotItem?.value === migrationModal.account?.id" class="rounded-0 text-caption"></v-list-item>
                                        </template>
                                    </v-select>
                                    <v-tooltip text="Criar Nova Conta e Vincular" location="top">
                                        <template v-slot:activator="{ props }">
                                            <v-btn
                                                v-bind="props"
                                                icon="mdi-plus"
                                                size="small"
                                                color="primary"
                                                variant="tonal"
                                                class="btn-rect flex-shrink-0"
                                                @click="openAccountModalForLink(row)"
                                            ></v-btn>
                                        </template>
                                    </v-tooltip>
                                </div>
                            </td>
                        </tr>
                    </tbody>
                </v-table>
            </div>

            <div class="px-6 py-4 border-t d-flex justify-space-between align-center bg-grey-lighten-5 flex-shrink-0">
                <div class="text-caption text-grey">
                    Apenas os registros com <strong>Novo Plano</strong> selecionado serão migrados e salvos.
                </div>
                <div class="d-flex gap-3">
                    <v-btn variant="outlined" color="grey-darken-3" class="btn-rect" @click="migrationModal.show = false">Cancelar</v-btn>
                    <v-btn color="success" variant="flat" class="font-weight-bold btn-rect" @click="executeMigration" :loading="migrationModal.loading" :disabled="!hasPendingMigrations">
                        <v-icon start>mdi-content-save-check</v-icon> Salvar e Migrar
                    </v-btn>
                </div>
            </div>
        </v-card>
    </v-dialog>

    <v-dialog v-model="editModal.show" max-width="600" persistent>
        <v-card class="rounded-0 border-thin">
            <div class="px-6 py-4 border-b d-flex align-center justify-space-between bg-grey-lighten-5">
                <span class="text-subtitle-1 font-weight-black text-uppercase text-grey-darken-3">
                    {{ editModal.form.id ? 'Editar Conta' : 'Nova Conta' }}
                </span>
                <v-btn icon="mdi-close" variant="text" rounded="0" @click="closeEditModal"></v-btn>
            </div>
            <div class="pa-6">
                <v-form @submit.prevent="saveAccount">
                    <v-row dense>
                        <v-col cols="12" md="4">
                             <v-text-field
                                v-model="editModal.form.code"
                                label="Código*"
                                placeholder="ex: 1.01.02"
                                variant="outlined"
                                density="comfortable"
                                class="font-mono rounded-0-input"
                             ></v-text-field>
                        </v-col>
                        <v-col cols="12" md="8">
                             <v-text-field
                                v-model="editModal.form.name"
                                label="Nome da Conta*"
                                variant="outlined"
                                density="comfortable"
                                class="rounded-0-input"
                             ></v-text-field>
                        </v-col>
                        <v-col cols="12" md="6">
                             <v-select
                                v-model="editModal.form.type"
                                label="Natureza"
                                :items="['Receita', 'Despesa', 'Ativo', 'Passivo']"
                                variant="outlined"
                                density="comfortable"
                                class="rounded-0-input"
                             ></v-select>
                        </v-col>
                        <v-col cols="12" md="6">
                             <v-select
                                v-model="editModal.form.is_group"
                                label="Tipo"
                                :items="[{title:'Sintética (Grupo)', value:true}, {title:'Analítica (Lançamentos)', value:false}]"
                                variant="outlined"
                                density="comfortable"
                                class="rounded-0-input"
                             ></v-select>
                        </v-col>
                        <v-col cols="12">
                             <v-textarea
                                v-model="editModal.form.description"
                                label="Descrição / Obs"
                                variant="outlined"
                                density="comfortable"
                                rows="2"
                                class="rounded-0-input"
                             ></v-textarea>
                        </v-col>
                    </v-row>
                </v-form>
            </div>
            <div class="px-6 py-4 border-t d-flex justify-end gap-3 bg-grey-lighten-5">
                <v-btn variant="outlined" color="grey-darken-3" class="btn-rect" @click="closeEditModal">Cancelar</v-btn>
                <v-btn color="primary" variant="flat" class="btn-rect font-weight-bold" :loading="editModal.loading" @click="saveAccount">Salvar Estrutura</v-btn>
            </div>
        </v-card>
    </v-dialog>

    <v-dialog v-model="mergeModal.show" max-width="800" persistent>
        <v-card class="rounded-0 border-thin overflow-hidden">
            <div class="px-6 py-4 bg-orange-darken-3 text-white d-flex align-center justify-space-between">
                <div>
                    <div class="text-caption font-weight-bold opacity-80 text-uppercase">Assistente de Manutenção</div>
                    <div class="text-h6 font-weight-black">
                        {{ mergeModal.sourceIds.length === 1 ? 'Migrar Conta' : 'Unificar Planos de Contas' }}
                    </div>
                </div>
                <v-icon size="32" class="opacity-50">
                    {{ mergeModal.sourceIds.length === 1 ? 'mdi-swap-horizontal' : 'mdi-merge' }}
                </v-icon>
            </div>

            <div class="pa-6">
                <v-alert type="warning" variant="tonal" class="mb-6 border-orange rounded-0" icon="mdi-alert">
                    <div class="text-subtitle-2 font-weight-bold">Esta ação transfere lançamentos e exclui as contas de origem.</div>
                    <div class="text-caption" v-if="mergeModal.sourceIds.length === 1">
                        A <strong>conta selecionada</strong> será migrada para a conta de destino.
                        Os {{ countTotalUsage(mergeModal.sourceIds) }} lançamentos vinculados serão transferidos automaticamente.
                    </div>
                    <div class="text-caption" v-else>
                        As <strong>{{ mergeModal.sourceIds.length }} contas selecionadas</strong> serão fundidas na conta de destino.
                        Todos os {{ countTotalUsage(mergeModal.sourceIds) }} lançamentos vinculados serão migrados automaticamente.
                    </div>
                </v-alert>

                <div class="mb-6">
                    <div class="text-subtitle-2 font-weight-bold mb-2">
                        {{ mergeModal.sourceIds.length === 1 ? 'Conta Origem (Será Excluída):' : 'Contas Origem (Serão Excluídas):' }}
                    </div>
                    <div class="bg-grey-lighten-4 rounded-0 pa-3 border-thin" style="max-height: 150px; overflow-y: auto;">
                        <div v-for="account in mergeModal.sourceAccounts" :key="account.id" class="d-flex align-center gap-2 mb-1">
                            <v-icon color="error" size="small">mdi-minus-circle</v-icon>
                            <span class="font-mono text-caption font-weight-bold">{{ account.code }}</span>
                            <span class="text-body-2">{{ account.name }}</span>
                            <v-chip size="x-small" label class="ml-auto rounded-0">{{ getUsageCount(account.id) }} lançamentos</v-chip>
                        </div>
                    </div>
                </div>

                <div class="mb-4">
                    <div class="text-subtitle-2 font-weight-bold mb-2">Conta Destino (Onde os dados ficarão):</div>
                    <v-autocomplete
                        v-model="mergeModal.targetId"
                        :items="allAccounts"
                        item-title="name"
                        item-value="id"
                        label="Selecione a conta correta"
                        variant="outlined"
                        placeholder="Pesquise a conta destino..."
                        color="success"
                        class="rounded-0-input"
                    >
                         <template v-slot:item="{ props, item: slotItem }">
                            <v-list-item v-bind="props" :subtitle="slotItem?.raw?.code" class="rounded-0">
                                <template v-slot:append>
                                    <v-chip v-if="mergeModal.sourceIds.includes(slotItem?.value)" size="x-small" color="error" class="rounded-0">Origem</v-chip>
                                </template>
                            </v-list-item>
                        </template>
                    </v-autocomplete>
                </div>
            </div>

            <div class="px-6 py-4 border-t d-flex justify-end gap-3 bg-grey-lighten-5">
                <v-btn variant="outlined" color="grey-darken-3" class="btn-rect" @click="mergeModal.show = false" :disabled="mergeModal.loading">Cancelar</v-btn>
                <v-btn
                    color="orange-darken-3"
                    variant="flat"
                    :loading="mergeModal.loading"
                    :disabled="!mergeModal.targetId || mergeModal.sourceIds.includes(mergeModal.targetId)"
                    @click="executeMerge"
                    class="font-weight-bold btn-rect"
                >
                    <v-icon start>mdi-check-all</v-icon>
                    {{ mergeModal.sourceIds.length === 1 ? 'Migrar Conta' : 'Unificar e Migrar' }}
                </v-btn>
            </div>
        </v-card>
    </v-dialog>

    <v-dialog v-model="detailModal.show" fullscreen transition="dialog-bottom-transition">
        <v-card class="bg-grey-lighten-5 d-flex flex-column rounded-0 h-100">
            <div class="px-6 py-4 bg-white border-b d-flex align-center justify-space-between flex-shrink-0 z-10">
                <div class="d-flex align-center gap-4">
                    <v-btn icon="mdi-arrow-left" variant="text" rounded="0" @click="detailModal.show = false"></v-btn>
                    <div>
                        <div class="text-caption font-weight-bold opacity-70 text-uppercase">Detalhes da Conta / Lançamentos</div>
                        <div class="text-h6 font-weight-black">{{ detailModal.account?.name }}</div>
                        <div class="d-flex align-center gap-2">
                             <v-chip size="x-small" label class="font-mono font-weight-bold rounded-0">{{ detailModal.account?.code }}</v-chip>
                             <v-chip size="x-small" class="rounded-0" :color="detailModal.account?.type === 'Receita' ? 'success' : 'error'">{{ detailModal.account?.type }}</v-chip>
                             <v-chip v-if="detailModal.account?.is_erp" size="x-small" color="orange" class="rounded-0">ERP</v-chip>
                        </div>
                    </div>
                </div>
            </div>

            <v-tabs v-model="detailModal.tab" bg-color="white" color="primary" class="rounded-0 flex-shrink-0 z-10 border-b">
                 <v-tab value="extract" class="rounded-0">Extrato / Lançamentos</v-tab>
                 <v-tab value="maintenance" class="text-orange-darken-3 rounded-0">Manutenção / Conversão Total</v-tab>
            </v-tabs>

            <div class="flex-grow-1 position-relative overflow-hidden bg-grey-lighten-4">
                 <v-window v-model="detailModal.tab" class="h-100 position-absolute w-100" style="inset: 0;">

                     <v-window-item value="extract" class="h-100 d-flex flex-column position-absolute w-100" style="inset: 0;">

                        <div class="pa-4 d-flex align-center gap-4 bg-white border-b flex-shrink-0">
                            <v-card class="bg-blue-lighten-5 px-4 py-2 rounded-0 border-blue-lighten-4 border-thin" elevation="0">
                                <div class="text-caption text-blue-darken-3 font-weight-bold">Volume Financeiro</div>
                                <div class="text-subtitle-1 font-weight-black text-blue-darken-4">{{ formatCurrency(detailModalTotalValue) }}</div>
                            </v-card>
                            <v-card class="bg-white px-4 py-2 rounded-0 border-thin" elevation="0">
                                <div class="text-caption text-grey-darken-1 font-weight-bold">Total de Lançamentos</div>
                                <div class="text-subtitle-1 font-weight-black">{{ detailModal.totalCount }}</div>
                            </v-card>
                            <v-spacer></v-spacer>
                            <span class="text-caption text-grey mr-2"><v-icon start size="small">mdi-information-outline</v-icon> Mostrando os últimos 500 registros</span>
                        </div>

                        <div class="flex-grow-1 overflow-hidden d-flex flex-column bg-white">
                            <div class="grid-header bg-grey-lighten-4 border-b flex-shrink-0">
                                <div class="cell center" style="width: 60px;">
                                    <v-checkbox-btn
                                        :model-value="detailModal.selectedItems.length === detailModal.items.length && detailModal.items.length > 0"
                                        :indeterminate="detailModal.selectedItems.length > 0 && detailModal.selectedItems.length < detailModal.items.length"
                                        @update:model-value="toggleAllDetailItems"
                                        density="compact"
                                        class="rounded-0-input"
                                        color="primary"
                                    ></v-checkbox-btn>
                                </div>
                                <div class="cell header-text center" style="width: 100px;">Data</div>
                                <div class="cell header-text flex-grow-1">Descrição / Sacado</div>
                                <div class="cell header-text center" style="width: 120px;">Valor</div>
                                <div class="cell header-text center" style="width: 100px;">Status</div>
                            </div>

                            <div class="flex-grow-1 overflow-y-auto custom-scroll">
                                <div v-if="detailModal.loading" class="d-flex justify-center pa-8"><v-progress-circular indeterminate color="primary"></v-progress-circular></div>
                                <div v-else-if="detailModal.items.length === 0" class="d-flex justify-center pa-8 text-grey">Nenhum lançamento recente encontrado.</div>
                                <div
                                    v-else
                                    v-for="(row, idx) in detailModal.items"
                                    :key="idx"
                                    class="grid-row border-b hover-bg-grey"
                                    :class="[idx % 2 === 0 ? 'bg-white' : 'bg-grey-lighten-5', detailModal.selectedItems.includes(row.id) ? 'bg-blue-lighten-5' : '']"
                                    @click="toggleDetailItemSelection(row.id)"
                                    style="cursor: pointer;"
                                >
                                    <div class="cell center" style="width: 60px;">
                                        <v-checkbox-btn
                                            v-model="detailModal.selectedItems"
                                            :value="row.id"
                                            density="compact"
                                            color="primary"
                                            class="rounded-0-input"
                                            @click.stop
                                        ></v-checkbox-btn>
                                    </div>
                                    <div class="cell center text-caption font-mono" style="width: 100px;">{{ formatDate(row.due_date) }}</div>
                                    <div class="cell flex-grow-1 text-caption font-weight-bold">{{ row.description || 'Sem descrição' }}</div>
                                    <div class="cell center text-caption font-weight-black" style="width: 120px;">{{ formatCurrency(row.value) }}</div>
                                    <div class="cell center" style="width: 100px;">
                                        <v-chip size="x-small" :color="row.status === 'pago' ? 'success' : 'warning'" variant="flat" class="rounded-0">{{ row.status }}</v-chip>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <v-slide-y-reverse-transition>
                            <div v-if="detailModal.selectedItems.length > 0" class="border-t pa-3 bg-blue-grey-darken-4 d-flex align-center justify-space-between flex-shrink-0 z-20">
                                <div class="text-white d-flex align-center gap-2 px-3">
                                    <v-icon>mdi-content-copy</v-icon>
                                    <span class="text-subtitle-2 font-weight-bold">{{ detailModal.selectedItems.length }} lançamentos selecionados</span>
                                </div>
                                <div class="d-flex align-center gap-3" style="width: 500px;">
                                    <v-autocomplete
                                        v-model="detailModal.bulkTargetId"
                                        :items="allAccounts"
                                        item-title="name"
                                        item-value="id"
                                        label="Mover selecionados para..."
                                        variant="solo-filled"
                                        density="compact"
                                        hide-details
                                        class="flex-grow-1 rounded-0"
                                        bg-color="white"
                                    >
                                        <template v-slot:item="{ props, item: slotItem }">
                                            <v-list-item v-bind="props" :subtitle="slotItem?.raw?.code" :disabled="slotItem?.value === detailModal.account?.id" class="rounded-0"></v-list-item>
                                        </template>
                                    </v-autocomplete>
                                    <v-btn
                                        color="orange-darken-3"
                                        variant="flat"
                                        class="font-weight-bold btn-rect"
                                        :disabled="!detailModal.bulkTargetId"
                                        :loading="detailModal.bulkMigrating"
                                        @click="migrateSelectedDetailItems"
                                    >
                                        Migrar Seleção
                                    </v-btn>
                                </div>
                            </div>
                        </v-slide-y-reverse-transition>

                     </v-window-item>

                     <v-window-item value="maintenance" class="h-100 overflow-y-auto pa-6 position-absolute w-100" style="inset: 0;">
                         <v-card class="mx-auto rounded-0 border-thin pa-6" max-width="600" elevation="0">
                             <div class="d-flex align-center gap-3 mb-4">
                                 <v-avatar color="orange-lighten-5" rounded="0"><v-icon color="orange-darken-3">mdi-wrench</v-icon></v-avatar>
                                 <div>
                                     <div class="text-h6 font-weight-bold">Converter / Migrar Conta Inteira</div>
                                     <div class="text-caption text-grey">Mova TODOS os lançamentos desta conta para outra.</div>
                                 </div>
                             </div>

                             <v-alert type="info" variant="tonal" class="mb-4 text-caption rounded-0 border-info">
                                 A conta atual <strong>{{ detailModal.account?.name }}</strong> será eliminada após a migração de todos os {{ detailModal.totalCount }} registros.
                             </v-alert>

                             <v-autocomplete
                                v-model="detailModal.targetId"
                                :items="allAccounts"
                                item-title="name"
                                item-value="id"
                                label="Selecionar Conta de Destino"
                                variant="outlined"
                                color="primary"
                                class="rounded-0-input"
                             >
                                <template v-slot:item="{ props, item: slotItem }">
                                    <v-list-item v-bind="props" :subtitle="slotItem?.raw?.code" :disabled="slotItem?.value === detailModal.account?.id" class="rounded-0"></v-list-item>
                                </template>
                             </v-autocomplete>

                             <v-btn
                                block
                                size="large"
                                color="orange-darken-3"
                                class="mt-4 font-weight-bold btn-rect"
                                :disabled="!detailModal.targetId || detailModal.targetId === detailModal.account?.id"
                                :loading="mergeModal.loading"
                                @click="convertSingleAccountFromDetail"
                             >
                                Confirmar Migração Total
                             </v-btn>
                         </v-card>
                     </v-window-item>
                 </v-window>
            </div>
        </v-card>
    </v-dialog>

    <v-dialog v-model="historyModal.show" :width="900" scrollable>
        <v-card class="rounded-0 d-flex flex-column h-100 border-thin" height="700">
            <div class="px-6 py-4 bg-blue-grey-darken-4 text-white d-flex align-center justify-space-between flex-shrink-0">
                <div class="d-flex align-center gap-3">
                    <v-avatar color="white" variant="tonal" class="rounded-0"><v-icon>mdi-history</v-icon></v-avatar>
                    <div>
                        <div class="text-h6 font-weight-black text-uppercase">Log de Auditoria</div>
                        <div class="text-caption opacity-80">Rastreamento completo de alterações no plano de contas</div>
                    </div>
                </div>
                <v-btn icon="mdi-close" variant="text" rounded="0" @click="historyModal.show = false"></v-btn>
            </div>

            <div class="px-6 py-3 border-b bg-grey-lighten-4 d-flex gap-4 align-center flex-shrink-0">
                <v-text-field
                    v-model="historyModal.search"
                    prepend-inner-icon="mdi-magnify"
                    placeholder="Filtrar logs por usuário ou ação..."
                    variant="outlined"
                    density="compact"
                    hide-details
                    bg-color="white"
                    class="flex-grow-1 rounded-0-input"
                ></v-text-field>
                <div class="text-caption font-weight-bold text-grey">
                    {{ historyModal.filteredLogs.length }} registros
                </div>
            </div>

            <div class="flex-grow-1 overflow-y-auto bg-grey-lighten-5 pa-4 custom-scroll">
                 <div v-if="historyModal.loading" class="d-flex justify-center pa-8"><v-progress-circular indeterminate color="primary"></v-progress-circular></div>
                 <div v-else-if="historyModal.logs.length === 0" class="d-flex flex-column align-center justify-center h-100 text-grey opacity-60">
                     <v-icon size="64" class="mb-4">mdi-text-box-search-outline</v-icon>
                     <div class="text-h6">Nenhum registro encontrado</div>
                 </div>

                 <template v-else>
                     <div v-for="(group, date) in historyModal.groupedLogs" :key="date">
                         <div class="d-flex align-center mb-4 mt-2">
                             <v-divider></v-divider>
                             <div class="mx-4 text-caption font-weight-black text-uppercase text-grey-darken-1 bg-white px-3 py-1 rounded-0 border-thin">
                                 {{ date }}
                             </div>
                             <v-divider></v-divider>
                         </div>

                         <v-card v-for="log in group" :key="log.id" class="mb-3 border-l-4 rounded-0 border-thin" :class="getLogBorderClass(log.action_type)" elevation="0">
                             <div class="pa-4 d-flex align-start gap-4">
                                 <v-avatar :image="log.user_avatar" color="grey-lighten-2" class="rounded-0">
                                     <span v-if="!log.user_avatar" class="text-caption font-weight-bold">{{ getInitials(log.user_name) }}</span>
                                 </v-avatar>
                                 <div class="flex-grow-1">
                                     <div class="d-flex justify-space-between align-start">
                                         <div>
                                             <div class="text-subtitle-2 font-weight-black">
                                                 {{ log.user_name || log.user_email || 'Sistema' }}
                                                 <span class="text-caption font-weight-regular text-grey ml-2">{{ log.user_role }}</span>
                                             </div>
                                             <div class="text-caption text-grey">{{ formatTime(log.created_at) }}</div>
                                         </div>
                                         <v-chip size="x-small" :color="getLogColor(log.action_type)" label class="font-weight-bold rounded-0">
                                             {{ translateAction(log.action_type) }}
                                         </v-chip>
                                     </div>

                                     <div class="mt-3 bg-grey-lighten-5 rounded-0 pa-3 text-caption font-mono border-thin">
                                         <div v-if="log.parsedDetails && log.parsedDetails.diff">
                                             <div class="d-flex align-center gap-2 mb-1">
                                                 <strong class="text-grey-darken-3">Alteração:</strong>
                                                 <span>{{ log.parsedDetails.message }}</span>
                                             </div>
                                             <div class="d-flex gap-4 mt-2">
                                                 <div class="w-50 pa-2 bg-red-lighten-5 rounded-0 text-red-darken-4 border border-red-lighten-4">
                                                     <div class="font-weight-bold mb-1 border-b border-red-lighten-3 pb-1">ANTES</div>
                                                     <pre class="text-[10px] whitespace-pre-wrap">{{ JSON.stringify(log.parsedDetails.diff.old, null, 2) }}</pre>
                                                 </div>
                                                 <div class="w-50 pa-2 bg-green-lighten-5 rounded-0 text-green-darken-4 border border-green-lighten-4">
                                                      <div class="font-weight-bold mb-1 border-b border-green-lighten-3 pb-1">DEPOIS</div>
                                                      <pre class="text-[10px] whitespace-pre-wrap">{{ JSON.stringify(log.parsedDetails.diff.new, null, 2) }}</pre>
                                                 </div>
                                             </div>
                                         </div>
                                         <div v-else>
                                             {{ log.details }}
                                         </div>
                                     </div>
                                 </div>
                             </div>
                         </v-card>
                     </div>
                 </template>
            </div>
        </v-card>
    </v-dialog>

  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted, watch } from 'vue';
import { supabase } from '@/api/supabase';
import { useAppStore } from '@/stores/app';
import { useThemeStore } from '@/stores/theme';
import { useUserStore } from '@/stores/user';
import { format, isToday, isYesterday, parseISO } from 'date-fns';
import { ptBR } from 'date-fns/locale';

const appStore = useAppStore();
const themeStore = useThemeStore();
const userStore = useUserStore();

const loading = ref(false);
const rawAccounts = ref<any[]>([]);
const selectedMap = ref<Map<string, any>>(new Map());
const usageMap = ref<Map<string, number>>(new Map());
const activeTab = ref('all');
const page = ref(1);
const itemsPerPage = 30;

const filters = reactive({
    search: '',
    type: 'all',
    usageStatus: 'all',
    sortBy: 'code'
});

// Acompanha se o usuário clicou em [+] ao lado de uma linha de migração
const itemAwaitingNewAccount = ref<any>(null);

// Modal de Migração Inteligente na Exclusão
const migrationModal = reactive({
    show: false,
    loading: false,
    account: null as any | null,
    items: [] as any[],
    bulkTargetId: null as string | null
});

const editModal = reactive({
    show: false,
    loading: false,
    form: { id: '', code: '', name: '', type: 'Despesa', is_group: false, description: '', active: true }
});

const mergeModal = reactive({
    show: false,
    loading: false,
    sourceIds: [] as string[],
    sourceAccounts: [] as any[],
    targetId: null as string | null
});

const detailModal = reactive({
    show: false,
    loading: false,
    tab: 'extract',
    account: null as any,
    targetId: null as string | null,
    items: [] as any[],
    totalCount: 0,
    // NOVOS ESTADOS PARA A SELEÇÃO
    selectedItems: [] as string[],
    bulkTargetId: null as string | null,
    bulkMigrating: false
});

// AQUI ESTAVA FALTANDO NA ÚLTIMA RESPOSTA:
const historyModal = reactive({
    show: false,
    loading: false,
    search: '',
    logs: [] as any[],
    filteredLogs: [] as any[],
    groupedLogs: {} as Record<string, any[]>
});

// --- UTILS ---
const formatCurrency = (val: any) => new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(Number(val) || 0);
const formatDate = (date: string) => date ? new Date(date).toLocaleDateString('pt-BR') : '-';
const formatTime = (date: string) => date ? new Date(date).toLocaleTimeString('pt-BR', {hour: '2-digit', minute:'2-digit'}) : '';
const getInitials = (name: string) => name ? name.substring(0, 2).toUpperCase() : 'US';

// --- COMPUTED PROPERTIES ---

const processedAccounts = computed(() => {
    return rawAccounts.value.map(acc => {
        const isErpCode = (acc.code && acc.code.length > 12) || /[a-zA-Z]/.test(acc.code.replace(/[ixvIXV]/g, ''));
        return {
            ...acc,
            is_erp: isErpCode,
            level: acc.code ? acc.code.split('.').length - 1 : 0
        };
    });
});

const allAccounts = computed(() => [...processedAccounts.value].sort((a,b) => a.code.localeCompare(b.code, undefined, { numeric: true })));

const filteredItems = computed(() => {
    let list = [...processedAccounts.value];

    if (activeTab.value === 'system') list = list.filter(i => !i.is_erp);
    else if (activeTab.value === 'erp') list = list.filter(i => i.is_erp);

    if (filters.search) {
        const term = filters.search.trim().toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g, "");
        list = list.filter(i => {
            const nameNorm = i.name ? i.name.toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g, "") : "";
            const codeNorm = i.code ? i.code.toLowerCase() : "";
            return nameNorm.includes(term) || codeNorm.includes(term);
        });
    }

    if (filters.type !== 'all') list = list.filter(i => i.type === filters.type);

    if (filters.usageStatus === 'used') list = list.filter(i => getUsageCount(i.id) > 0);
    else if (filters.usageStatus === 'unused') list = list.filter(i => getUsageCount(i.id) === 0);

    if (filters.sortBy === 'name') list.sort((a, b) => a.name.localeCompare(b.name));
    else if (filters.sortBy === 'most_used') list.sort((a, b) => getUsageCount(b.id) - getUsageCount(a.id));
    else if (filters.sortBy === 'least_used') list.sort((a, b) => getUsageCount(a.id) - getUsageCount(b.id));
    else list.sort((a,b) => a.code.localeCompare(b.code, undefined, { numeric: true }));

    return list;
});

const paginatedItems = computed(() => {
    const start = (page.value - 1) * itemsPerPage;
    return filteredItems.value.slice(start, start + itemsPerPage);
});

const pageCount = computed(() => Math.ceil(filteredItems.value.length / itemsPerPage));

const clearFilters = () => {
    filters.search = '';
    filters.usageStatus = 'all';
    filters.type = 'all';
    activeTab.value = 'all';
};

// Computado para a soma total da listagem mostrada no DetailModal
const detailModalTotalValue = computed(() => {
    return detailModal.items.reduce((sum, item) => sum + (Number(item.value) || 0), 0);
});

// --- FETCHING DATA & CALCULA USO REAL (PAGINADO) ---

const fetchAccounts = async () => {
    loading.value = true;
    const { data, error } = await supabase.from('finance_chart_of_accounts').select('*').order('code');
    if (!error && data) {
        rawAccounts.value = data;
        await fetchAccurateUsageStats();
    }
    loading.value = false;
};

// Faz looping garantindo que se existir 10.000 lançamentos ele pegue todos
const fetchAccurateUsageStats = async () => {
    const map = new Map<string, number>();

    const fetchAllFromTable = async (table: string) => {
        let start = 0;
        let hasMore = true;
        while(hasMore) {
            const { data, error } = await supabase.from(table).select('chart_of_accounts_id').not('chart_of_accounts_id', 'is', null).range(start, start + 999);
            if (error || !data || data.length === 0) {
                hasMore = false;
                break;
            }
            data.forEach(item => {
                const id = item.chart_of_accounts_id;
                if (id) map.set(id, (map.get(id) || 0) + 1);
            });
            start += 1000;
            if (data.length < 1000) hasMore = false;
        }
    };

    await Promise.all([
        fetchAllFromTable('finance_receivables'),
        fetchAllFromTable('finance_payables')
    ]);

    usageMap.value = map;
};

const getUsageCount = (id: string) => usageMap.value.get(id) || 0;
const countTotalUsage = (ids: string[]) => ids.reduce((acc, id) => acc + getUsageCount(id), 0);

// --- SELECTION ---
const toggleSelection = (item: any) => {
    if (selectedMap.value.has(item.id)) selectedMap.value.delete(item.id);
    else selectedMap.value.set(item.id, item);
};

// Selecionar todos os itens do extrato no Modal
const toggleAllDetailItems = (val: boolean) => {
    if (val) detailModal.selectedItems = detailModal.items.map(i => i.id);
    else detailModal.selectedItems = [];
};

// Toggle de um item individual ao clicar na linha no Modal
const toggleDetailItemSelection = (id: string) => {
    const idx = detailModal.selectedItems.indexOf(id);
    if (idx > -1) detailModal.selectedItems.splice(idx, 1);
    else detailModal.selectedItems.push(id);
};

// --- AUDIT LOGS ---
const logAudit = async (actionType: string, message: string, oldData: any = null, newData: any = null) => {
    try {
        const detailsObj = { message: message, diff: (oldData || newData) ? { old: oldData, new: newData } : null };
        await supabase.from('system_audit_logs').insert({
            action_type: actionType, details: JSON.stringify(detailsObj), user_id: userStore.user?.id,
            user_email: userStore.user?.email, created_at: new Date()
        });
    } catch (e) { console.warn('Audit error', e); }
};

const fetchHistory = async () => {
    historyModal.loading = true;
    const { data: logs } = await supabase.from('system_audit_logs').select('*').order('created_at', { ascending: false }).limit(100);
    if (logs) {
        const userIds = [...new Set(logs.map(l => l.user_id).filter(Boolean))];
        const { data: profiles } = await supabase.from('profiles').select('id, full_name, avatar_url, role').in('id', userIds);
        const profileMap = new Map(); profiles?.forEach(p => profileMap.set(p.id, p));

        historyModal.logs = logs.map(log => {
            const profile = profileMap.get(log.user_id);
            let parsedDetails = null;
            try { parsedDetails = JSON.parse(log.details); } catch { parsedDetails = { message: log.details }; }
            return {
                ...log, user_name: profile?.full_name || log.user_email, user_avatar: profile?.avatar_url,
                user_role: profile?.role || 'Usuário', parsedDetails: parsedDetails
            };
        });
        filterAndGroupLogs();
    }
    historyModal.loading = false;
};

const filterAndGroupLogs = () => {
    let filtered = historyModal.logs;
    if (historyModal.search) {
        const term = historyModal.search.toLowerCase();
        filtered = filtered.filter(l => (l.user_name && l.user_name.toLowerCase().includes(term)) || (l.action_type && l.action_type.toLowerCase().includes(term)));
    }
    historyModal.filteredLogs = filtered;

    const groups: Record<string, any[]> = {};
    filtered.forEach(log => {
        const date = parseISO(log.created_at);
        let key = format(date, "dd 'de' MMMM, yyyy", { locale: ptBR });
        if (isToday(date)) key = "Hoje"; else if (isYesterday(date)) key = "Ontem";
        if (!groups[key]) groups[key] = [];
        groups[key].push(log);
    });
    historyModal.groupedLogs = groups;
};

watch(() => historyModal.show, (val) => { if(val) fetchHistory(); });
watch(() => historyModal.search, () => filterAndGroupLogs());

const translateAction = (type: string) => {
    const map: Record<string, string> = { 'MERGE_ACCOUNTS': 'Unificação de Contas', 'DELETE_ACCOUNT': 'Exclusão de Conta', 'UPDATE_ACCOUNT': 'Edição de Conta', 'CREATE_ACCOUNT': 'Criação de Conta', 'CONVERT_ACCOUNT': 'Conversão Individual'};
    return map[type] || type;
};

const getLogColor = (type: string) => {
    if (type.includes('DELETE')) return 'error'; if (type.includes('MERGE')) return 'warning'; if (type.includes('CREATE')) return 'success'; return 'info';
};

const getLogBorderClass = (type: string) => {
    if (type.includes('DELETE')) return 'border-red-500'; if (type.includes('MERGE')) return 'border-orange-500'; if (type.includes('CREATE')) return 'border-green-500'; return 'border-blue-500';
};

// --- CRUD & ACTIONS ---

const openAccountModal = (item?: any) => {
    if (item) {
        editModal.form = {
            id: item.id,
            code: item.code || '',
            name: item.name || '',
            type: item.type || 'Despesa',
            is_group: !!item.is_group,
            description: item.description || '',
            active: item.active !== false
        };
    } else {
        editModal.form = { id: '', code: '', name: '', type: 'Despesa', is_group: false, description: '', active: true };
    }
    editModal.show = true;
};

const openAccountModalForLink = (row: any) => {
    itemAwaitingNewAccount.value = row;
    openAccountModal();
};

const closeEditModal = () => {
    editModal.show = false;
    itemAwaitingNewAccount.value = null;
};

const saveAccount = async () => {
    if (!editModal.form.code || !editModal.form.name) return;
    editModal.loading = true;

    const payload: any = {
        code: editModal.form.code,
        name: editModal.form.name,
        type: editModal.form.type,
        is_group: editModal.form.is_group,
        description: editModal.form.description,
        active: editModal.form.active
    };

    const isUpdate = !!editModal.form.id;
    if (isUpdate) {
        payload.id = editModal.form.id;
    }

    let oldData = null;
    if (isUpdate) {
        oldData = rawAccounts.value.find(a => a.id === payload.id);
    }

    const { data, error } = await supabase.from('finance_chart_of_accounts').upsert(payload).select().single();

    if (!error && data) {
        if (itemAwaitingNewAccount.value) {
            itemAwaitingNewAccount.value.targetId = data.id;
            itemAwaitingNewAccount.value = null;
            appStore.showSnackbar('Conta criada e vinculada na linha!', 'success');
        } else {
            appStore.showSnackbar('Salvo com sucesso!', 'success');
        }

        await logAudit(isUpdate ? 'UPDATE_ACCOUNT' : 'CREATE_ACCOUNT', `Conta ${payload.code} - ${payload.name} ${isUpdate ? 'atualizada' : 'criada'}.`, oldData, data);
        editModal.show = false;
        fetchAccounts();
    } else {
        console.error("Erro ao salvar:", error);
        appStore.showSnackbar('Erro ao salvar plano de contas.', 'error');
    }

    editModal.loading = false;
};

const deleteAccount = async (item: any) => {
    let realTimeCount = 0;
    const [{ count: cRec }, { count: cPay }] = await Promise.all([
        supabase.from('finance_receivables').select('*', { count: 'exact', head: true }).eq('chart_of_accounts_id', item.id),
        supabase.from('finance_payables').select('*', { count: 'exact', head: true }).eq('chart_of_accounts_id', item.id)
    ]);
    realTimeCount = (cRec || 0) + (cPay || 0);

    if (realTimeCount > 0) {
        await openMigrationModal(item);
        return;
    }

    if(!confirm(`Excluir a conta ${item.name}?`)) return;

    try {
        const { error } = await supabase.from('finance_chart_of_accounts').delete().eq('id', item.id);
        if (error) throw error;

        await logAudit('DELETE_ACCOUNT', `Excluiu a conta ${item.code} - ${item.name}`, item, null);
        fetchAccounts();
        appStore.showSnackbar('Conta excluída com sucesso.', 'success');
    } catch (error: any) {
        console.error("Erro na exclusão:", error);
        appStore.showSnackbar('O banco de dados bloqueou a exclusão. Possível vínculo estrutural (Conta Pai/Filha).', 'error');
    }
};

// --- MIGRATION / EXCLUSÃO AVANÇADA (INDIVIDUAL ROW) ---
const openMigrationModal = async (account: any) => {
    migrationModal.loading = true;
    migrationModal.account = account;
    migrationModal.items = [];
    migrationModal.bulkTargetId = null;
    migrationModal.show = true;

    const { data: recData } = await supabase.from('finance_receivables').select('id, due_date, description, value, status').eq('chart_of_accounts_id', account.id);
    if (recData) migrationModal.items.push(...recData.map(r => ({ ...r, sourceTable: 'finance_receivables', targetId: null })));

    const { data: payData } = await supabase.from('finance_payables').select('id, due_date, description, value, status').eq('chart_of_accounts_id', account.id);
    if (payData) migrationModal.items.push(...payData.map(r => ({ ...r, sourceTable: 'finance_payables', targetId: null })));

    migrationModal.loading = false;
};

const applyBulkTarget = () => {
    if (migrationModal.bulkTargetId) {
        migrationModal.items.forEach(i => i.targetId = migrationModal.bulkTargetId);
    }
};

const hasPendingMigrations = computed(() => {
    return migrationModal.items.some(i => !!i.targetId);
});

const executeMigration = async () => {
    migrationModal.loading = true;
    try {
        const toUpdateRec = migrationModal.items.filter(i => i.targetId && i.sourceTable === 'finance_receivables');
        const toUpdatePay = migrationModal.items.filter(i => i.targetId && i.sourceTable === 'finance_payables');

        for (const item of toUpdateRec) {
            await supabase.from('finance_receivables').update({ chart_of_accounts_id: item.targetId }).eq('id', item.id);
        }
        for (const item of toUpdatePay) {
            await supabase.from('finance_payables').update({ chart_of_accounts_id: item.targetId }).eq('id', item.id);
        }

        appStore.showSnackbar(`${toUpdateRec.length + toUpdatePay.length} lançamentos alterados.`, 'success');

        const remaining = migrationModal.items.length - (toUpdateRec.length + toUpdatePay.length);
        if (remaining <= 0) {
            migrationModal.show = false;
            if (confirm(`A conta '${migrationModal.account.name}' não possui mais vínculos. Deseja excluí-la agora?`)) {
                await supabase.from('finance_chart_of_accounts').delete().eq('id', migrationModal.account.id);
                appStore.showSnackbar('Conta original deletada.', 'success');
                fetchAccounts();
            } else {
                fetchAccounts();
            }
        } else {
            await openMigrationModal(migrationModal.account);
        }

    } catch (e: any) {
        appStore.showSnackbar('Erro ao migrar dados: ' + e.message, 'error');
    } finally {
        migrationModal.loading = false;
    }
};

// --- MIGRATION / MERGE / DETAILS ---
const openUsageDetail = async (account: any) => {
    detailModal.account = account;
    detailModal.items = [];
    detailModal.targetId = null;

    // Zera a seleção ao abrir
    detailModal.selectedItems = [];
    detailModal.bulkTargetId = null;

    detailModal.show = true;
    detailModal.loading = true;
    detailModal.tab = 'extract';
    detailModal.totalCount = getUsageCount(account.id);

    const { data } = await supabase
        .from(account.type === 'Receita' ? 'finance_receivables' : 'finance_payables')
        .select('id, due_date, description, value, status')
        .eq('chart_of_accounts_id', account.id)
        .order('due_date', { ascending: false })
        .limit(500);

    if (data) detailModal.items = data;
    detailModal.loading = false;
};

// Lógica de migração PARCIAL (Desmembramento a partir do detalhe)
const migrateSelectedDetailItems = async () => {
    if (!detailModal.bulkTargetId || detailModal.selectedItems.length === 0) return;
    detailModal.bulkMigrating = true;

    try {
        const table = detailModal.account?.type === 'Receita' ? 'finance_receivables' : 'finance_payables';
        const targetAccount = allAccounts.value.find(a => a.id === detailModal.bulkTargetId);

        // Faz o update no banco
        const { error } = await supabase
            .from(table)
            .update({ chart_of_accounts_id: detailModal.bulkTargetId })
            .in('id', detailModal.selectedItems);

        if (error) throw error;

        // Auditoria da ação de desmembramento
        await logAudit(
            'UPDATE_ACCOUNT',
            `Desmembrou ${detailModal.selectedItems.length} lançamentos da conta '${detailModal.account.code}' para a conta '${targetAccount?.code}'.`,
            null,
            { ids_migrados: detailModal.selectedItems, destino: targetAccount }
        );

        appStore.showSnackbar(`${detailModal.selectedItems.length} itens migrados com sucesso para ${targetAccount?.name}!`, 'success');

        // Atualiza a listagem e fecha o modal (ou reabre limpo)
        await fetchAccounts();
        await openUsageDetail(detailModal.account);

    } catch (error: any) {
        appStore.showSnackbar('Erro ao migrar itens: ' + error.message, 'error');
    } finally {
        detailModal.bulkMigrating = false;
    }
};

const openMergeModal = () => {
    if (selectedMap.value.size === 0) return;
    mergeModal.sourceIds = Array.from(selectedMap.value.keys());
    mergeModal.sourceAccounts = Array.from(selectedMap.value.values());
    mergeModal.targetId = null;
    mergeModal.show = true;
};

const executeMerge = async () => {
    if (!mergeModal.targetId) return;
    mergeModal.loading = true;
    try {
        const sourceIds = mergeModal.sourceIds;
        const targetId = mergeModal.targetId;
        const targetAccount = allAccounts.value.find(a => a.id === targetId);
        const oldSnapshot = mergeModal.sourceAccounts.map(a => `${a.code} (${a.name})`).join(', ');

        try { await supabase.from('finance_payables').update({ chart_of_accounts_id: targetId }).in('chart_of_accounts_id', sourceIds); } catch(e) {}
        await supabase.from('finance_receivables').update({ chart_of_accounts_id: targetId }).in('chart_of_accounts_id', sourceIds);
        await supabase.from('finance_chart_of_accounts').delete().in('id', sourceIds);

        const isSingle = sourceIds.length === 1;
        const actionName = isSingle ? 'CONVERT_ACCOUNT' : 'MERGE_ACCOUNTS';
        const logMsg = isSingle
            ? `Migrou a conta [${oldSnapshot}] para a conta [${targetAccount?.code} - ${targetAccount?.name}].`
            : `Unificou [${oldSnapshot}] para a conta [${targetAccount?.code} - ${targetAccount?.name}].`;

        await logAudit(actionName, logMsg, { deleted_accounts: mergeModal.sourceAccounts }, { target_account: targetAccount });

        appStore.showSnackbar(isSingle ? 'Migração concluída com sucesso!' : 'Unificação concluída com sucesso!', 'success');

        selectedMap.value.clear();
        mergeModal.show = false;
        fetchAccounts();
    } catch (e: any) {
        appStore.showSnackbar('Erro: ' + e.message, 'error');
    } finally {
        mergeModal.loading = false;
    }
};

const convertSingleAccountFromDetail = async () => {
    if (!detailModal.targetId || !detailModal.account) return;
    mergeModal.loading = true;
    try {
        const sourceId = detailModal.account.id;
        const targetId = detailModal.targetId;
        const targetAccount = allAccounts.value.find(a => a.id === targetId);

        try { await supabase.from('finance_payables').update({ chart_of_accounts_id: targetId }).eq('chart_of_accounts_id', sourceId); } catch(e){}
        await supabase.from('finance_receivables').update({ chart_of_accounts_id: targetId }).eq('chart_of_accounts_id', sourceId);
        await supabase.from('finance_chart_of_accounts').delete().eq('id', sourceId);

        await logAudit('CONVERT_ACCOUNT', `Converteu ${detailModal.account.code} para ${targetAccount?.code}.`, detailModal.account, targetAccount);

        appStore.showSnackbar('Conta convertida!', 'success');
        detailModal.show = false;
        fetchAccounts();
    } catch (e: any) {
        appStore.showSnackbar('Erro: ' + e.message, 'error');
    } finally {
        mergeModal.loading = false;
    }
};

const bulkDelete = async () => {
    const idsToTry = Array.from(selectedMap.value.keys());
    const accounts = Array.from(selectedMap.value.values());
    const idsToDelete = idsToTry.filter(id => getUsageCount(id) === 0);

    if (idsToDelete.length < idsToTry.length) {
         appStore.showSnackbar(`Atenção: Das ${idsToTry.length} contas selecionadas, apenas ${idsToDelete.length} não possuem uso. Você deve migrar os dados clicando no ícone da lixeira na conta individualmente.`, 'warning');
         if (idsToDelete.length === 0) return;
    }

    if(!confirm(`Tem certeza que deseja excluir ${idsToDelete.length} conta(s) que não possuem vínculos?`)) return;

    try {
        const { error } = await supabase.from('finance_chart_of_accounts').delete().in('id', idsToDelete);
        if (error) throw error;

        await logAudit('DELETE_ACCOUNT', `Exclusão em massa de ${idsToDelete.length} contas.`, { accounts: accounts.filter(a => idsToDelete.includes(a.id)) }, null);

        selectedMap.value.clear();
        fetchAccounts();
        appStore.showSnackbar('Contas sem uso excluídas com sucesso.', 'success');
    } catch (error: any) {
        console.error(error);
        appStore.showSnackbar(`Erro: Alguma conta selecionada possui sub-contas (Conta Pai) e não pôde ser excluída.`, 'error');
    }
};

onMounted(() => {
    fetchAccounts();
});
</script>

<style scoped lang="scss">
.chart-accounts-layout { position: relative; }
.bg-glass-dark { background: rgba(10,10,12,0.85); }
.bg-glass-header { background: rgba(20,20,24,0.55); backdrop-filter: blur(14px); }
.border-bottom-white-05 { border-bottom: 1px solid rgba(255,255,255,0.08); }

.btn-rect { border-radius: 0 !important; text-transform: none !important; }
.rounded-0-input :deep(.v-field) { border-radius: 0 !important; }
.rounded-0 { border-radius: 0 !important; }

.controls-bar { border: 1px solid rgba(0,0,0,0.08); padding: 10px; }
.search-wrap { height: 40px; padding: 0 12px; border: 1px solid rgba(0,0,0,0.08); border-radius: 0px; }
.clean-input { border: none; outline: none; flex: 1; font-size: 13px; }

.grid-scroll { scrollbar-gutter: stable both-edges; }
.custom-scroll::-webkit-scrollbar { width: 8px; height: 8px; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.35); border-radius: 0px; }

.grid-header, .grid-row { display: flex; align-items: stretch; width: 100%; min-width: 800px; }
.cell { padding: 8px 12px; display: flex; align-items: center; border-right: 1px solid rgba(0,0,0,0.05); border-bottom: 1px solid rgba(0,0,0,0.05); min-height: 48px; }
.header-text { font-size: 11px; font-weight: 900; text-transform: uppercase; letter-spacing: 0.5px; }
.center { justify-content: center; text-align: center; }

.table-borders th, .table-borders td {
    border-right: 1px solid rgba(0,0,0,0.05);
}
.hover-bg-grey:hover { background: #f9f9f9 !important; }

.grid-surface-light .cell { background: #f5f7fa; color: #555; }
.grid-surface-dark .cell { background: rgba(255,255,255,0.08); color: #ccc; }
.grid-row-light .cell { background: #fff; }
.grid-row-dark .cell { background: rgba(255,255,255,0.04); }
.grid-selected-light .cell { background: #e8f5e9 !important; }
.grid-selected-dark .cell { background: rgba(76, 175, 80, 0.2) !important; }

.zebra-light-a .cell { background: #fff; }
.zebra-light-b .cell { background: #fafafa; }
.zebra-dark-a .cell { background: rgba(255,255,255,0.04); }
.zebra-dark-b .cell { background: rgba(255,255,255,0.02); }

.actions-inline { display: flex; gap: 6px; justify-content: center; }
.action-btn { width: 28px !important; height: 28px !important; border-radius: 0px !important; color: #fff !important; }
.action-edit { background: #1976d2 !important; }
.action-del { background: #c62828 !important; }

.selection-drawer {
    transition: all 0.3s ease;
    border-left: 1px solid rgba(0,0,0,0.1);
    z-index: 50;
}
.border-white-05 { border-color: rgba(255,255,255,0.05) !important; }

.border-l-4 { border-left-width: 4px !important; }
.border-red-500 { border-color: #ef5350 !important; }
.border-orange-500 { border-color: #ffa726 !important; }
.border-green-500 { border-color: #66bb6a !important; }
.border-blue-500 { border-color: #42a5f5 !important; }
</style>
