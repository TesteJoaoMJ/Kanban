<template>
  <div
    class="admin-user-management-wrapper font-sans fill-height d-flex flex-column relative overflow-hidden"
    :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 text-grey-darken-4' : 'bg-glass-dark text-white'"
  >
    <div v-if="themeStore.currentMode !== 'light'" class="background-carousel-wrapper">
      <div class="background-overlay"></div>
    </div>

    <div class="content-wrapper d-flex flex-column fill-height z-10 relative">
      <div
        class="header-bar px-6 py-4 d-flex align-center justify-space-between flex-shrink-0"
        :class="themeStore.currentMode === 'light' ? 'bg-white border-b border-grey-lighten-2 shadow-sm' : 'bg-glass-header border-bottom-white-05'"
      >
        <div class="d-flex align-center">
          <v-btn icon="mdi-arrow-left" variant="flat" color="blue-grey-darken-3" class="btn-rect mr-4" height="40" width="40" @click="router.push({ name: 'AdminHub' })"></v-btn>
          <div class="d-flex flex-column">
            <div class="breadcrumb text-caption">
              <span class="opacity-70">Administração</span>
              <span class="mx-2 opacity-50">></span>
              <span class="font-weight-bold">Equipe</span>
            </div>
            <div class="text-h6 font-weight-black tracking-tight leading-none mt-1">
              Gestão de Acessos e Cargos
            </div>
          </div>
        </div>

        <div class="d-flex align-center gap-3">
          <v-menu location="bottom end" :close-on-content-click="true">
            <template v-slot:activator="{ props }">
              <v-btn
                v-bind="props"
                variant="outlined"
                color="blue-grey-darken-3"
                class="btn-rect font-weight-bold text-caption text-uppercase bg-white"
                height="40"
              >
                Mais Ações
                <v-icon end size="small">mdi-chevron-down</v-icon>
              </v-btn>
            </template>
            <v-card class="rounded-0 border-thin shadow-xl" min-width="240">
              <v-list density="compact" nav>
                <v-list-item v-if="userStore.isSuperAdmin" @click="openRoleManagement" prepend-icon="mdi-briefcase-account" class="font-weight-black text-blue-darken-4 mb-1 bg-blue-lighten-5 rounded">
                  <v-list-item-title>Gerenciar Cargos</v-list-item-title>
                </v-list-item>

                <v-list-item v-if="userStore.isSuperAdmin" @click="openUpdateModal" prepend-icon="mdi-rocket-launch" class="font-weight-bold text-deep-purple-darken-3 mb-1">
                  <v-list-item-title>Disparar Atualização</v-list-item-title>
                </v-list-item>

                <v-list-item @click="openCommissionReport" prepend-icon="mdi-cash-register" class="font-weight-bold text-orange-darken-4">
                  <v-list-item-title>Relatório de Comissão</v-list-item-title>
                </v-list-item>
                <v-divider class="my-1"></v-divider>
                <v-list-item @click="showCompanyModal = true" prepend-icon="mdi-domain" class="font-weight-bold text-blue-grey-darken-4">
                  <v-list-item-title>Gestão de Empresas</v-list-item-title>
                </v-list-item>
              </v-list>
            </v-card>
          </v-menu>

          <v-btn
            v-if="userStore.isSuperAdmin"
            color="success"
            variant="flat"
            class="btn-rect px-6 font-weight-bold text-caption text-uppercase"
            prepend-icon="mdi-account-plus"
            height="40"
            @click="openUserModal(null)"
          >
            Novo Colaborador
          </v-btn>
        </div>
      </div>

      <div class="px-6 py-3 flex-shrink-0">
        <v-row dense>
          <v-col cols="12" sm="6" md="3" v-for="(kpi, idx) in kpiList" :key="idx">
            <v-card
              class="kpi-card kpi-rect bg-gradient-custom py-3 px-4"
              :class="kpi.gradient"
              elevation="2"
            >
              <div class="kpi-bg-icon"><v-icon>{{ kpi.icon }}</v-icon></div>
              <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                <div class="d-flex align-center gap-2">
                  <v-icon size="18" class="opacity-80">{{ kpi.icon }}</v-icon>
                  <span class="kpi-label">{{ kpi.label }}</span>
                </div>
                <div class="kpi-number-group my-1">
                  <span class="kpi-value">{{ kpi.value }}</span>
                </div>
                <div class="kpi-footer mt-1">{{ kpi.footer }}</div>
              </div>
            </v-card>
          </v-col>
        </v-row>
      </div>

      <div class="px-6 pt-0 pb-2 flex-shrink-0">
        <div
          class="controls-bar d-flex align-center justify-space-between"
          :class="themeStore.currentMode === 'light' ? 'controls-light' : 'controls-dark'"
        >
          <div class="d-flex align-center gap-3">
            <div class="search-wrap d-flex align-center" :class="themeStore.currentMode === 'light' ? 'search-light' : 'search-dark'" style="min-width: 350px;">
              <v-icon :color="themeStore.currentMode === 'light' ? 'grey-darken-1' : 'white-70'">mdi-magnify</v-icon>
              <input
                v-model="search"
                type="text"
                placeholder="Pesquisar por Nome ou E-mail..."
                class="clean-input flex-grow-1"
              />
            </div>

            <v-select
              v-model="statusFilter"
              :items="['Todos', 'Ativos', 'Inativos']"
              label="Status da Conta"
              variant="outlined"
              density="compact"
              hide-details
              class="ui-field"
              style="width: 160px;"
              bg-color="transparent"
            ></v-select>
          </div>

          <v-btn
            variant="text"
            class="btn-rect font-weight-bold"
            height="40"
            color="grey-darken-2"
            prepend-icon="mdi-refresh"
            @click="fetchUsers"
          >
            Atualizar Grid
          </v-btn>
        </div>
      </div>

      <div class="flex-grow-1 px-6 pb-0 overflow-hidden d-flex flex-column">
        <v-card
          class="flex-grow-1 d-flex flex-column rounded-0 border-thin overflow-hidden"
          :class="themeStore.currentMode === 'light' ? 'bg-white shadow-sm' : 'glass-card border-white-05'"
          :elevation="0"
        >
          <div class="grid-scroll flex-grow-1 overflow-y-auto custom-scroll relative">
            <div
              class="grid-header sticky-head grid-users-layout"
              :class="themeStore.currentMode === 'light' ? 'grid-surface-light' : 'grid-surface-dark'"
            >
              <div class="cell center header-text pl-2">Foto</div>
              <div class="cell header-text">Nome / E-mail</div>
              <div class="cell header-text">Cargo Principal</div>
              <div class="cell header-text">Vínculo RH</div>
              <div class="cell header-text">Unidade (Loja)</div>
              <div class="cell center header-text">Status</div>
              <div class="cell center header-text">Ações</div>
            </div>

            <div v-if="loading" class="d-flex flex-column justify-center align-center h-100 py-10 min-w-full">
              <v-progress-circular indeterminate color="blue-grey-darken-2" size="32" width="3"></v-progress-circular>
            </div>

            <div v-else-if="filteredUsers.length === 0" class="d-flex flex-column justify-center align-center h-100 py-10 opacity-60 min-w-full">
               <v-icon size="48" color="grey-lighten-1">mdi-account-search-outline</v-icon>
               <span class="text-body-2 font-weight-medium mt-2 text-grey">Nenhum colaborador encontrado.</span>
            </div>

            <div
              v-else
              v-for="(user, index) in paginatedUsers"
              :key="user.id"
              class="grid-row grid-users-layout transition-colors"
              :class="[
                themeStore.currentMode === 'light' ? 'grid-row-light' : 'grid-row-dark',
                zebraClass(index),
                !user.is_active ? 'opacity-50 grayscale-low' : ''
              ]"
            >
              <div class="cell center pl-2">
                  <v-avatar size="36" rounded="lg" class="border" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-4' : 'bg-grey-darken-3'">
                    <v-img v-if="user.avatar_url" :src="user.avatar_url" cover></v-img>
                    <v-icon v-else color="grey" size="18">mdi-account</v-icon>
                  </v-avatar>
              </div>

              <div class="cell">
                  <div class="d-flex flex-column overflow-hidden py-1">
                      <span class="list-text-11 font-weight-black text-truncate text-uppercase">{{ user.full_name }}</span>
                      <span class="text-[10px] opacity-70 text-truncate font-mono">{{ user.email || 'S/ E-mail' }}</span>
                  </div>
              </div>

              <div class="cell">
                 <div class="d-flex align-center gap-2">
                     <v-icon :color="user._isSupervisor ? 'warning' : 'blue-grey'" size="16">
                         {{ user._isSupervisor ? 'mdi-star-circle' : 'mdi-briefcase' }}
                     </v-icon>
                     <span class="font-weight-bold text-caption text-truncate" :class="user._customRoleName === 'Sem Cargo Definido' ? 'opacity-50 font-italic' : 'text-blue-grey-darken-3'">
                         {{ user._customRoleName }}
                     </span>
                 </div>
              </div>

              <div class="cell">
                 <div class="d-flex align-center gap-2 overflow-hidden w-100">
                    <v-icon size="14" :color="user.employee_id ? 'indigo-darken-2' : 'grey-lighten-1'">mdi-badge-account-horizontal-outline</v-icon>
                    <span class="list-text-10 font-weight-bold text-truncate" :class="user.employee_id ? '' : 'opacity-40 font-italic'">
                        {{ user._employeeName }}
                    </span>
                 </div>
              </div>

              <div class="cell">
                <span class="list-text-10 font-weight-bold uppercase opacity-80 text-truncate">
                    <v-icon size="12" class="mr-1 opacity-50">mdi-store-marker-outline</v-icon>
                    {{ user._storeName }}
                </span>
              </div>

              <div class="cell center">
                <v-chip size="x-small" :color="user.is_active ? 'success' : 'error'" class="font-weight-bold text-uppercase px-2" variant="tonal">
                  {{ user.is_active ? 'Ativo' : 'Inativo' }}
                </v-chip>
              </div>

              <div class="cell center">
                <div class="actions-inline">
                  <v-btn v-if="userStore.isSuperAdmin" icon size="small" class="action-btn action-edit" @click.stop="openUserModal(user)" title="Gerenciar Acessos" variant="flat">
                    <v-icon size="16">mdi-pencil</v-icon>
                  </v-btn>
                  <v-btn v-if="userStore.isSuperAdmin" icon size="small" class="action-btn action-pwd" @click.stop="openPasswordReset(user)" title="Resetar Senha" variant="flat">
                    <v-icon size="16">mdi-lock-reset</v-icon>
                  </v-btn>
                </div>
              </div>
            </div>
          </div>

          <div class="flex-shrink-0 border-t px-4 py-2 d-flex align-center justify-space-between bg-grey-lighten-5">
            <div class="text-caption opacity-80 font-weight-bold">
              Mostrando <strong class="text-blue-grey-darken-3">{{ paginatedUsers.length }}</strong> de <strong>{{ filteredUsers.length }}</strong> registros
            </div>
            <v-pagination
              v-model="page"
              :length="pageCount"
              :total-visible="5"
              density="compact"
              active-color="blue-grey-darken-3"
              variant="tonal"
              size="small"
            ></v-pagination>
          </div>
        </v-card>
      </div>
    </div>

    <v-dialog v-model="updateModal.show" max-width="700">
      <v-card class="rounded-lg overflow-hidden border-thin shadow-2xl">
        <div class="bg-deep-purple-darken-4 pa-6 text-white d-flex align-center gap-4 border-b border-deep-purple-darken-3">
          <v-icon size="40" class="opacity-80">mdi-rocket-launch</v-icon>
          <div>
            <div class="text-h6 font-weight-black uppercase">Disparar Atualização Geral</div>
            <div class="text-caption opacity-80">Notificar usuários em tempo real para recarregarem o sistema.</div>
          </div>
        </div>
        <div class="pa-6 bg-white">
           <v-row class="row-gap-sm">
               <v-col cols="12" sm="5">
                   <label class="input-label">Versão da Release *</label>
                   <v-text-field v-model="updateModal.form.version" variant="outlined" density="comfortable" class="ui-field font-weight-bold" placeholder="Ex: 2.1.5"></v-text-field>
               </v-col>
               <v-col cols="12" sm="7">
                    <label class="input-label">Reabrir modal (se ignorado) em:</label>
                    <v-select v-model="updateModal.form.reopen_interval_seconds" :items="[{title: 'Forçar Imediato (Sem botão fechar)', value: 0}, {title: '1 Minuto', value: 60}, {title: '5 Minutos', value: 300}, {title: '15 Minutos', value: 900}, {title: '1 Hora', value: 3600}]" variant="outlined" density="comfortable" class="ui-field"></v-select>
               </v-col>
               <v-col cols="12">
                   <label class="input-label">O que mudou? (Notas de Atualização) *</label>
                   <v-textarea v-model="updateModal.form.description" variant="outlined" density="comfortable" class="ui-field" rows="4" placeholder="Liste as correções e novidades dessa versão..."></v-textarea>
               </v-col>

               <v-col cols="12">
                   <div class="text-caption font-weight-bold text-grey-darken-1 mb-2 mt-2"><v-icon size="14" class="mr-1">mdi-filter-variant</v-icon> Filtros de Direcionamento (Deixe vazio para mandar pra TODOS)</div>
               </v-col>

               <v-col cols="12" sm="6">
                    <v-autocomplete v-model="updateModal.form.target_roles" :items="customRoles" item-title="name" item-value="id" label="Apenas para estes Cargos" multiple chips closable-chips variant="outlined" density="comfortable" class="ui-field" hide-details></v-autocomplete>
               </v-col>
               <v-col cols="12" sm="6">
                    <v-autocomplete v-model="updateModal.form.target_users" :items="users" item-title="full_name" item-value="id" label="Apenas para estes Usuários" multiple chips closable-chips variant="outlined" density="comfortable" class="ui-field" hide-details></v-autocomplete>
               </v-col>
           </v-row>
        </div>
        <div class="pa-5 bg-grey-lighten-5 border-t d-flex justify-end gap-3 shadow-up">
          <v-btn variant="text" class="btn-rect font-weight-bold text-grey-darken-2" height="44" @click="updateModal.show = false">Cancelar</v-btn>
          <v-btn color="deep-purple-darken-3" variant="flat" class="btn-rect px-8 font-weight-black shadow-soft" height="44" :loading="updateModal.loading" @click="dispatchUpdate">
              <v-icon start>mdi-send</v-icon> Disparar Alerta
          </v-btn>
        </div>
      </v-card>
    </v-dialog>

    <AdminUserDetailModal
      v-if="userModal.show"
      :user="userModal.selectedUser"
      :auxData="auxDataPayload"
      @close="userModal.show = false"
      @saved="handleUserSaved"
    />

    <v-dialog v-model="roleManagementModal.show" fullscreen transition="dialog-bottom-transition">
        <v-card class="d-flex flex-row overflow-hidden bg-white h-100">
            <div class="bg-grey-lighten-4 border-r d-flex flex-column h-100 flex-shrink-0" style="width: 320px;">
                <div class="pa-4 bg-white border-b d-flex flex-column gap-3 shadow-sm z-10">
                    <div class="d-flex align-center gap-2">
                        <v-icon color="blue-darken-3" size="28">mdi-briefcase-account</v-icon>
                        <div>
                            <div class="text-subtitle-2 font-weight-black uppercase tracking-tight">Cargos e Funções</div>
                            <div class="text-[10px] opacity-70">Templates de Permissão Corporativa</div>
                        </div>
                    </div>
                    <v-btn block color="blue-darken-3" variant="flat" prepend-icon="mdi-plus" class="font-weight-bold shadow-sm" @click="resetRoleForm">Novo Cargo</v-btn>
                </div>

                <v-list class="flex-grow-1 overflow-y-auto bg-transparent pa-3 custom-scroll" density="compact" nav>
                    <v-list-item
                        v-for="r in customRoles"
                        :key="r.id"
                        :active="roleManagementModal.form.id === r.id"
                        @click="selectRoleToEdit(r)"
                        active-color="blue-darken-3"
                        class="mb-2 rounded-lg border-thin bg-white hover-border-blue transition-colors shadow-sm"
                        elevation="0"
                    >
                         <template v-slot:prepend>
                            <v-icon :color="r.is_supervisor ? 'warning' : 'blue-grey'">mdi-briefcase</v-icon>
                         </template>
                         <v-list-item-title class="font-weight-bold text-caption text-uppercase">{{ r.name }}</v-list-item-title>
                         <v-list-item-subtitle class="text-[10px]">{{ r.is_supervisor ? 'Acesso Especial de Supervisor' : 'Acesso Padrão (Colaborador)' }}</v-list-item-subtitle>
                    </v-list-item>
                </v-list>
            </div>

            <div class="flex-grow-1 d-flex flex-column h-100 bg-grey-lighten-4">
                <div class="pa-4 border-b d-flex justify-space-between align-center bg-white shadow-sm z-10 flex-shrink-0">
                     <div class="text-h6 font-weight-black text-blue-grey-darken-4 uppercase tracking-tight d-flex align-center gap-2">
                         <v-icon color="blue-grey-darken-2">mdi-tune-vertical</v-icon>
                         {{ roleManagementModal.form.id ? 'Editando Cargo: ' + roleManagementModal.form.name : 'Construtor de Novo Cargo' }}
                     </div>
                     <v-btn icon="mdi-close" variant="text" @click="roleManagementModal.show = false"></v-btn>
                </div>

                <div class="pa-6 overflow-y-auto flex-grow-1 custom-scroll relative">
                     <v-form ref="roleFormRef" @submit.prevent="saveRole" id="roleForm">

                         <div class="section-block bg-white border-thin rounded-xl pa-6 shadow-sm mb-6">
                             <div class="d-flex align-center gap-3 border-b pb-3 mb-5">
                                 <v-avatar color="blue-grey-lighten-5" size="32" class="rounded text-blue-grey-darken-3"><v-icon size="18">mdi-card-text</v-icon></v-avatar>
                                 <div>
                                    <h4 class="text-subtitle-2 font-weight-black text-uppercase text-grey-darken-4 mb-0">Informações Básicas</h4>
                                    <span class="text-[10px] text-grey-darken-1">Dados de identificação e hierarquia.</span>
                                 </div>
                             </div>

                             <v-row class="row-gap-sm">
                                 <v-col cols="12" md="6">
                                     <label class="input-label">Nomenclatura Oficial *</label>
                                     <v-text-field v-model="roleManagementModal.form.name" variant="outlined" density="comfortable" class="ui-field" placeholder="Ex: Analista de Produção Pleno" :rules="[rules.required]"></v-text-field>
                                 </v-col>
                                 <v-col cols="12" md="6">
                                     <label class="input-label">Descrição da Função (Opcional)</label>
                                     <v-text-field v-model="roleManagementModal.form.description" variant="outlined" density="comfortable" class="ui-field" placeholder="Breve resumo das responsabilidades"></v-text-field>
                                 </v-col>
                                 <v-col cols="12">
                                     <div class="border-thin rounded-lg pa-4 bg-amber-lighten-5 border-amber-lighten-3 d-flex align-center justify-space-between shadow-inner">
                                         <div>
                                            <div class="font-weight-black text-amber-darken-4 text-body-2 uppercase">Privilégios Elevados de Supervisão</div>
                                            <div class="text-caption text-amber-darken-3">Dá poderes irrestritos para aprovar exceções financeiras e ver relatórios gerenciais na Dashboard.</div>
                                         </div>
                                         <v-switch v-model="roleManagementModal.form.is_supervisor" color="warning" hide-details density="compact" inset></v-switch>
                                     </div>
                                 </v-col>
                             </v-row>
                         </div>

                         <div class="mb-6">
                            <div class="d-flex align-center gap-3 mb-6 px-2">
                                <v-avatar color="success-lighten-5" size="36" class="rounded-lg text-success-darken-3 shadow-inner"><v-icon size="20">mdi-shield-check-outline</v-icon></v-avatar>
                                <div>
                                   <h3 class="text-h6 font-weight-black text-uppercase text-grey-darken-4 lh-1">Matriz de Acessos do Cargo</h3>
                                   <span class="text-caption text-grey-darken-1">Todos vinculados a este cargo herdarão estas configurações.</span>
                                </div>
                            </div>

                            <div v-for="mod in permissionTree" :key="mod.module" class="mb-8">
                                <div class="d-flex align-center gap-2 mb-4 pl-2">
                                    <div style="width: 4px; height: 16px;" class="bg-primary rounded-pill"></div>
                                    <h4 class="text-subtitle-1 font-weight-black text-blue-grey-darken-4 text-uppercase tracking-tight">{{ mod.module }}</h4>
                                </div>

                                <v-row dense>
                                    <v-col cols="12" md="6" lg="4" v-for="cat in mod.categories" :key="cat.name">
                                        <v-card class="h-100 border-thin rounded-xl shadow-sm bg-white overflow-hidden d-flex flex-column hover-border-blue transition-all">
                                            <div class="bg-grey-lighten-5 px-4 py-3 border-b d-flex align-center justify-space-between">
                                                <span class="text-caption font-weight-black text-grey-darken-3 text-uppercase letter-spacing-1 d-flex align-center">
                                                    <v-icon size="14" class="mr-2 opacity-50">mdi-folder</v-icon> {{ cat.name }}
                                                </span>
                                            </div>
                                            <div class="pa-2 d-flex flex-column gap-1 flex-grow-1">
                                                <template v-for="perm in cat.items" :key="perm.value">
                                                    <div class="d-flex align-center justify-space-between px-3 py-2 rounded-lg hover-bg-grey transition-colors" :class="roleManagementModal.form.permissions.includes(perm.value) ? 'bg-blue-grey-lighten-5' : ''">
                                                        <v-switch v-model="roleManagementModal.form.permissions" :value="perm.value" :label="perm.label" density="compact" hide-details color="success" class="modern-switch flex-grow-1"></v-switch>

                                                        <div class="d-flex gap-2" v-if="roleManagementModal.form.permissions.includes(perm.value)">
                                                            <v-tooltip text="Somente Leitura" location="top" v-if="!perm.subItems || perm.subItems.length === 0">
                                                                <template v-slot:activator="{ props }">
                                                                    <v-btn icon size="x-small" v-bind="props" variant="flat" :color="isRoleReadOnlyActive(perm.value) ? 'warning-lighten-4 text-warning-darken-4 border border-warning' : 'grey-lighten-4 text-grey-darken-1 border'" @click="toggleRoleReadOnly(perm.value)">
                                                                        <v-icon size="14">{{ isRoleReadOnlyActive(perm.value) ? 'mdi-eye-off' : 'mdi-eye-check' }}</v-icon>
                                                                    </v-btn>
                                                                </template>
                                                            </v-tooltip>
                                                            <v-tooltip text="Poder de Exclusão (Lixeira)" location="top" v-if="perm.tables && perm.tables.length > 0">
                                                                <template v-slot:activator="{ props }">
                                                                    <v-btn icon size="x-small" v-bind="props" variant="flat" :color="isRoleDeleteActive(perm) ? 'error-lighten-4 text-error-darken-4 border border-error' : 'grey-lighten-4 text-grey-darken-1 border'" @click="toggleRoleDelete(perm)">
                                                                        <v-icon size="14">mdi-delete-empty</v-icon>
                                                                    </v-btn>
                                                                </template>
                                                            </v-tooltip>
                                                        </div>
                                                    </div>

                                                    <div v-if="perm.subItems && perm.subItems.length > 0 && roleManagementModal.form.permissions.includes(perm.value)" class="ml-4 pl-3 py-1 border-s-sm border-primary-lighten-3 mb-2 d-flex flex-column gap-1">
                                                        <div v-for="sub in perm.subItems" :key="sub.value" class="d-flex align-center justify-space-between px-2 py-1 rounded hover-bg-grey transition-colors" :class="roleManagementModal.form.permissions.includes(sub.value) ? 'bg-blue-lighten-5' : ''">
                                                            <v-switch v-model="roleManagementModal.form.permissions" :value="sub.value" :label="sub.label" density="compact" hide-details color="primary" class="modern-switch sub-switch flex-grow-1"></v-switch>
                                                            <div class="d-flex gap-1" v-if="roleManagementModal.form.permissions.includes(sub.value)">
                                                                <v-tooltip text="Aba Somente Leitura" location="top">
                                                                    <template v-slot:activator="{ props }">
                                                                        <v-btn icon size="x-small" v-bind="props" variant="flat" :color="isRoleReadOnlyActive(sub.value) ? 'warning-lighten-4 text-warning-darken-4 border border-warning' : 'grey-lighten-4 text-grey-darken-1 border'" @click="toggleRoleReadOnly(sub.value)" style="width: 24px; height: 24px;">
                                                                            <v-icon size="12">{{ isRoleReadOnlyActive(sub.value) ? 'mdi-eye-off' : 'mdi-eye-check' }}</v-icon>
                                                                        </v-btn>
                                                                    </template>
                                                                </v-tooltip>
                                                                <v-tooltip text="Exclusão na Aba" location="top" v-if="sub.tables && sub.tables.length > 0">
                                                                    <template v-slot:activator="{ props }">
                                                                        <v-btn icon size="x-small" v-bind="props" variant="flat" :color="isRoleDeleteActive(sub) ? 'error-lighten-4 text-error-darken-4 border border-error' : 'grey-lighten-4 text-grey-darken-1 border'" @click="toggleRoleDelete(sub)" style="width: 24px; height: 24px;">
                                                                            <v-icon size="12">mdi-delete-empty</v-icon>
                                                                        </v-btn>
                                                                    </template>
                                                                </v-tooltip>
                                                            </div>
                                                        </div>
                                                    </div>
                                                </template>
                                            </div>
                                        </v-card>
                                    </v-col>
                                </v-row>
                            </div>
                        </div>

                     </v-form>
                </div>

                <div class="pa-4 border-t d-flex justify-space-between align-center bg-white shadow-up z-10 flex-shrink-0">
                     <v-btn color="red-darken-2" variant="text" class="font-weight-bold" prepend-icon="mdi-trash-can" v-if="roleManagementModal.form.id" @click="deleteRole(roleManagementModal.form.id)">
                         Excluir Cargo
                     </v-btn>
                     <div v-else></div>
                     <div class="d-flex gap-3">
                         <v-btn variant="text" class="btn-rect font-weight-bold" height="44" @click="roleManagementModal.show = false">Cancelar</v-btn>
                         <v-btn color="blue-darken-3" variant="flat" class="btn-rect font-weight-black px-10 shadow-soft" height="44" @click="saveRole" :loading="roleManagementModal.loading">
                             <v-icon start>mdi-check</v-icon> Salvar Cargo
                         </v-btn>
                     </div>
                </div>
            </div>
        </v-card>
    </v-dialog>

    <v-dialog v-model="commissionModal.show" fullscreen transition="dialog-bottom-transition" scrim="black">
      <v-card class="d-flex flex-row overflow-hidden rounded-0 bg-white">
        <div class="bg-grey-darken-4 text-white d-flex flex-column shadow-xl relative z-10" style="width: 350px; flex-shrink: 0;">
           <div class="pa-8 bg-black-10 flex-grow-1 d-flex flex-column">
              <v-icon size="48" class="mb-4 opacity-80" color="orange">mdi-finance</v-icon>
              <h2 class="text-h5 font-weight-black leading-tight uppercase mb-1">Auditoria de Vendas</h2>
              <div class="text-caption opacity-70 font-weight-bold mb-8">Conferência de comissões e legitimidade de carteira.</div>

              <div class="bg-black-20 rounded pa-4 mb-4 border-white-10">
                 <div class="text-[10px] font-weight-black uppercase opacity-60 mb-1">Vendedor Analisado</div>
                 <div class="text-h6 font-weight-black leading-tight text-orange-lighten-2">{{ getSelectedUserName }}</div>
                 <div class="text-caption opacity-70 font-mono mt-1">{{ formatDate(commissionModal.startDate) }} - {{ formatDate(commissionModal.endDate) }}</div>
              </div>

              <div class="d-flex flex-column gap-4 mt-auto">
                 <div class="bg-white-10 rounded pa-4 border-white-10">
                    <div class="text-[10px] font-weight-black uppercase opacity-60 mb-1">Total Recebido (Base)</div>
                    <div class="font-mono font-weight-black text-h6">{{ formatCurrency(commissionModal.totalPaid) }}</div>
                 </div>
                 <div class="bg-success rounded pa-4 elevation-4 border-white-10">
                    <div class="text-[10px] font-weight-black uppercase opacity-80 mb-1 text-black">Comissão Final ({{ commissionModal.userPercentage }}%)</div>
                    <div class="text-h4 font-weight-black text-black">{{ formatCurrency(commissionModal.totalCommission) }}</div>
                 </div>
                 <div v-if="divergenceCount > 0" class="bg-red-darken-4 rounded pa-3 border-white-10 d-flex align-center gap-3">
                    <v-icon>mdi-alert</v-icon>
                    <div class="text-caption font-weight-bold leading-tight">
                       {{ divergenceCount }} vendas com divergência detectadas.
                    </div>
                 </div>
              </div>
           </div>

           <div class="pa-4 bg-black-20">
              <v-btn block variant="text" prepend-icon="mdi-close" @click="commissionModal.show = false">FECHAR RELATÓRIO</v-btn>
           </div>
        </div>

        <div class="flex-grow-1 d-flex flex-column bg-white overflow-hidden">
           <div class="px-8 py-5 border-b d-flex align-center justify-space-between bg-white elevation-1 relative z-20">
              <div class="d-flex align-center gap-4 flex-grow-1 mr-8">
                 <v-select
                    v-model="commissionModal.userId"
                    :items="users"
                    item-title="full_name"
                    item-value="id"
                    label="Selecionar Vendedor"
                    variant="outlined"
                    density="compact"
                    hide-details
                    class="ui-field font-weight-bold"
                    style="max-width: 250px;"
                 ></v-select>

                 <div class="d-flex align-center gap-2">
                    <v-text-field v-model="commissionModal.startDate" type="date" variant="outlined" density="compact" hide-details class="ui-field" style="width: 140px;"></v-text-field>
                    <span class="text-caption font-weight-bold opacity-50">ATÉ</span>
                    <v-text-field v-model="commissionModal.endDate" type="date" variant="outlined" density="compact" hide-details class="ui-field" style="width: 140px;"></v-text-field>
                 </div>

                 <v-btn color="grey-darken-4" variant="flat" class="btn-rect px-6 font-weight-bold" height="40" :loading="commissionModal.loading" @click="calculateCommission">
                    <v-icon class="mr-2">mdi-refresh</v-icon> PROCESSAR
                 </v-btn>
              </div>

              <div class="d-flex align-center gap-2">
                 <v-text-field
                    v-model="commissionModal.externalSellerName"
                    placeholder="Nome p/ PDF (Opcional)"
                    variant="outlined"
                    density="compact"
                    hide-details
                    class="ui-field"
                    style="width: 180px;"
                 ></v-text-field>
                 <v-divider vertical class="mx-2"></v-divider>
                 <v-btn icon="mdi-microsoft-excel" color="success" variant="tonal" class="rounded" @click="exportToExcel" :disabled="!commissionModal.results.length"></v-btn>
                 <v-btn icon="mdi-file-pdf-box" color="error" variant="flat" class="rounded" @click="generateDetailedPDF" :disabled="!commissionModal.results.length"></v-btn>
              </div>
           </div>

           <div class="flex-grow-1 overflow-y-auto bg-grey-lighten-5 pa-8 custom-scroll">
              <v-card class="border-thin shadow-sm rounded-0 overflow-hidden" v-if="commissionModal.results.length > 0">
                 <v-table density="comfortable" hover>
                    <thead class="bg-grey-lighten-4">
                       <tr>
                          <th class="font-weight-black uppercase text-[10px] py-3 text-grey-darken-2">Pedido</th>
                          <th class="font-weight-black uppercase text-[10px] py-3 text-grey-darken-2">Data</th>
                          <th class="font-weight-black uppercase text-[10px] py-3 text-grey-darken-2">Cliente / Status Carteira</th>
                          <th class="font-weight-black uppercase text-[10px] py-3 text-center text-grey-darken-2">Valor Total</th>
                          <th class="font-weight-black uppercase text-[10px] py-3 text-center text-orange-darken-4">Base Paga</th>
                          <th class="font-weight-black uppercase text-[10px] py-3 text-right text-success">Comissão</th>
                          <th class="font-weight-black uppercase text-[10px] py-3 text-center" style="width: 80px;">Ação</th>
                       </tr>
                    </thead>
                    <tbody>
                       <tr v-for="(res, idx) in commissionModal.results" :key="res.orderId" :class="res.isDivergent ? 'bg-red-lighten-5' : ''">
                          <td class="font-weight-black font-mono text-[11px]">#{{ res.orderNumber }}</td>
                          <td class="font-mono text-[11px] opacity-70">{{ formatDate(res.date) }}</td>
                          <td class="py-3">
                             <div class="font-weight-bold text-[11px]">{{ res.customer }}</div>
                             <div v-if="res.isDivergent" class="d-flex align-center gap-1 mt-1 text-red-darken-4">
                                <v-icon size="12" color="red-darken-4">mdi-alert-circle</v-icon>
                                <span class="text-[9px] font-weight-black uppercase">Carteira de: {{ res.trueOwnerName }}</span>
                             </div>
                          </td>
                          <td class="text-center font-mono text-[11px] opacity-60">{{ formatCurrency(res.totalOrderValue) }}</td>
                          <td class="text-center font-mono text-[12px] font-weight-black text-orange-darken-4">{{ formatCurrency(res.paidValue) }}</td>
                          <td class="text-right font-mono text-[12px] font-weight-black text-success">{{ formatCurrency(res.commission) }}</td>
                          <td class="text-center">
                             <v-menu location="left" :close-on-content-click="false">
                                <template v-slot:activator="{ props }">
                                   <v-btn v-bind="props" icon="mdi-account-arrow-right" variant="text" density="compact" :color="res.isDivergent ? 'red' : 'grey'"></v-btn>
                                </template>
                                <v-card width="300" class="pa-4 border-thin shadow-xl">
                                   <div class="text-caption font-weight-black uppercase mb-3 text-grey-darken-1">Transferir Responsabilidade</div>
                                   <v-autocomplete
                                      label="Novo Dono (Vendedor)"
                                      :items="users"
                                      item-title="full_name"
                                      item-value="id"
                                      variant="outlined"
                                      density="compact"
                                      hide-details
                                      class="ui-field mb-3"
                                      @update:model-value="(val) => reassignOrderOwner(res.orderId, val, idx, res.isStoreSale)"
                                   ></v-autocomplete>
                                   <v-btn block color="error" variant="tonal" size="small" class="font-weight-bold btn-rect" @click="commissionModal.results.splice(idx, 1); recalculateTotals()">
                                      Remover do Relatório
                                   </v-btn>
                                </v-card>
                             </v-menu>
                          </td>
                       </tr>
                    </tbody>
                 </v-table>
              </v-card>

              <div v-else-if="!commissionModal.loading" class="d-flex flex-column align-center justify-center h-100 opacity-40">
                 <v-icon size="80" class="mb-4 text-grey-lighten-1">mdi-clipboard-text-search</v-icon>
                 <div class="text-h6 font-weight-bold text-grey-darken-1">Aguardando Parâmetros</div>
                 <div class="text-caption text-grey">Selecione vendedor e datas acima para gerar.</div>
              </div>
           </div>
        </div>
      </v-card>
    </v-dialog>

    <v-dialog v-model="pwdModal.show" max-width="500">
      <v-card class="rounded-0 overflow-hidden border-thin shadow-2xl">
        <div class="bg-blue-grey-darken-4 pa-8 text-white text-center">
          <v-icon size="64" class="mb-4 text-grey-lighten-1">mdi-security-network</v-icon>
          <div class="text-h6 font-weight-black uppercase">Redefinir Credencial</div>
          <div class="text-caption opacity-80">{{ pwdModal.user?.full_name }}</div>
        </div>
        <div class="pa-10 bg-white">
          <label class="input-label mb-2">Nova Senha Administrativa</label>
          <v-text-field v-model="pwdModal.newPassword" type="password" variant="outlined" density="comfortable" class="ui-field" placeholder="Mínimo 6 dígitos"></v-text-field>
        </div>
        <div class="pa-6 bg-grey-lighten-5 border-t d-flex justify-end gap-4">
          <v-btn variant="text" class="btn-rect font-weight-bold text-grey-darken-2" @click="pwdModal.show = false">Cancelar</v-btn>
          <v-btn color="blue-grey-darken-3" variant="flat" class="btn-rect px-8 font-weight-black" :loading="pwdModal.loading" @click="executePasswordReset">Confirmar Troca</v-btn>
        </div>
      </v-card>
    </v-dialog>

    <CompanyManagementModal :show="showCompanyModal" @close="showCompanyModal = false" />
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, reactive, computed } from 'vue';
import { supabase } from '@/api/supabase';
import { useRouter } from 'vue-router';
import type { VForm } from 'vuetify/components';
import { useAppStore } from '@/stores/app';
import { useUserStore } from '@/stores/user';
import { useThemeStore } from '@/stores/theme';
import CompanyManagementModal from './CompanyManagementModal.vue';
import AdminUserDetailModal from './AdminUserDetailModal.vue';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import * as XLSX from 'xlsx';
import { format } from 'date-fns';

const router = useRouter();
const appStore = useAppStore();
const themeStore = useThemeStore();
const userStore = useUserStore();

const search = ref('');
const roleFilter = ref('Todos');
const statusFilter = ref('Todos');
const loading = ref(true);
const users = ref<any[]>([]);
const stores = ref<any[]>([]);
const employeesList = ref<any[]>([]);
const companiesList = ref<any[]>([]);
const customRoles = ref<any[]>([]);
const page = ref(1);
const itemsPerPage = 30;

const showCompanyModal = ref(false);

// --- ESTADO DO MODAL DE USUÁRIO (EXTRAÍDO) ---
const userModal = reactive({
    show: false,
    selectedUser: null as any
});

const openUserModal = (user: any | null) => {
    userModal.selectedUser = user;
    userModal.show = true;
};

const handleUserSaved = async () => {
    userModal.show = false;
    await fetchUsers();
};

const auxDataPayload = computed(() => ({
    employeesList: employeesList.value,
    stores: stores.value,
    companiesList: companiesList.value,
    customRoles: customRoles.value
}));

// --- ESTADO DO MODAL DE ATUALIZAÇÃO GLOBAL ---
const updateModal = reactive({
    show: false,
    loading: false,
    form: {
        version: '',
        description: '',
        target_roles: [] as string[],
        target_users: [] as string[],
        reopen_interval_seconds: 300
    }
});

const openUpdateModal = () => {
    updateModal.form = { version: '', description: '', target_roles: [], target_users: [], reopen_interval_seconds: 300 };
    updateModal.show = true;
};

const dispatchUpdate = async () => {
    if (!updateModal.form.version || !updateModal.form.description) {
        appStore.showSnackbar('Versão e descrição são campos obrigatórios.', 'warning');
        return;
    }
    updateModal.loading = true;
    try {
        const { error } = await supabase.from('system_updates').insert({
            version: updateModal.form.version,
            description: updateModal.form.description,
            target_roles: updateModal.form.target_roles.length > 0 ? updateModal.form.target_roles : [],
            target_users: updateModal.form.target_users.length > 0 ? updateModal.form.target_users : [],
            reopen_interval_seconds: updateModal.form.reopen_interval_seconds
        });
        if (error) throw error;
        appStore.showSnackbar('Alerta de atualização disparado com sucesso!', 'success');
        updateModal.show = false;
    } catch (err: any) {
        appStore.showSnackbar('Erro ao disparar atualização: ' + err.message, 'error');
    } finally {
        updateModal.loading = false;
    }
};

// --- ÁRVORE DE PERMISSÕES PARA O MODAL DE CARGOS ---
const permissionTree = computed(() => {
    return [
        {
            module: 'Visão Geral & Tarefas',
            categories: [
                { name: 'Dashboard', items: [
                    { value: 'view_dashboard', label: 'Acessar Dashboard ERP', tables: [] },
                    { value: 'view_tasks', label: 'Gerenciar Tarefas/Projetos', tables: ['tasks'] },
                    { value: 'operacional_corte', label: 'Acessar Painel Cortadora a Laser', tables: [] }
                ]}
            ]
        },
        {
            module: 'Cadastros Base',
            categories: [
                { name: 'Entidades Comerciais', items: [
                    { value: 'cad_clients', label: 'Gestão de Clientes', tables: ['customers_mj'] },
                    { value: 'cad_suppliers', label: 'Gestão de Fornecedores', tables: ['suppliers_mj'] }
                ]}
            ]
        },
        {
            module: 'Vendas & Negociações',
            categories: [
                { name: 'Operacional', items: [
                    { value: 'sales_my_orders', label: 'Minhas Vendas (Criar/Editar prõprios)', tables: ['orders'] },
                    { value: 'sales_store', label: 'Vendas Balcão (Loja / PDV)', tables: ['store_sales'] },
                    { value: 'sales_management', label: 'Gestão Global de Pedidos', tables: ['orders'] }
                ]},
                { name: 'Consultas Gerais', items: [
                    { value: 'sales_global_consult', label: 'Consulta Global (Referências Vendidas)', tables: [] },
                    { value: 'sales_price_list', label: 'Visualizar Tabela de Preços', tables: [] },
                    { value: 'sales_didatic', label: 'Material Didático de Vendas', tables: [] }
                ]},
                { name: 'Gerencial', items: [
                    { value: 'admin_sales_area', label: 'Gráficos e Estatísticas de Vendas', tables: [] }
                ]}
            ]
        },
        {
            module: 'Produtos & Compras',
            categories: [
                { name: 'Controle de Estoque', items: [
                    { value: 'prod_stock', label: 'Consultar Estoque (Leitura)', tables: ['stock'] },
                    { value: 'prod_stock_mgmt', label: 'Gestão de Estoque (Lançar/Editar/Ajustar)', tables: ['stock'] }
                ]},
                { name: 'Processos de Compra', items: [
                    { value: 'pur_quotations', label: 'Cotações de Compra', tables: [] },
                    { value: 'pur_products', label: 'Gestão de Produtos', tables: [] },
                    { value: 'pur_services', label: 'Ordem de Serviços (Terceiros)', tables: [] }
                ]}
            ]
        },
        {
            module: 'Design Gráfico',
            categories: [
                { name: 'Workflow', items: [
                    { value: 'des_kanban', label: 'Visualizar Kanban Design', tables: [] },
                    { value: 'des_request', label: 'Solicitar Desenvolvimento', tables: [] },
                    { value: 'mfg_approvals', label: 'Aprovações de Arte', tables: [] },
                    { value: 'des_catalog', label: 'Catálogo de Estampas (Interno)', tables: [] }
                ]}
            ]
        },
        {
            module: 'Produção Industrial',
            categories: [
                { name: 'Chão de Fábrica', items: [
                    { value: 'mfg_launches', label: 'Painel de Lançamentos', tables: [] },
                    { value: 'mfg_control', label: 'Acesso Geral ao PCP', tables: [] },
                    { value: 'mfg_printing', label: 'Estação de Impressão (Módulo Solo)', tables: [] },
                    { value: 'mfg_release', label: 'Liberação e Qualidade', tables: [] },
                    { value: 'mfg_in_production', label: 'Rastreio Em Produção', tables: [] }
                ]},
                // ADICIONE ESTA NOVA CATEGORIA AQUI:
                { name: 'Controle de Abas do PCP', items: [
                    { value: 'pcp_tab_design', label: 'Aba: Design (Finalização)', tables: [] },
                    { value: 'pcp_tab_pcp', label: 'Aba: PCP Geral', tables: [] },
                    { value: 'pcp_tab_separacao', label: 'Aba: Separação', tables: [] },
                    { value: 'pcp_tab_impressao', label: 'Aba: Impressão', tables: [] },
                    { value: 'pcp_tab_calandra', label: 'Aba: Calandra', tables: [] },
                    { value: 'pcp_tab_faturamento', label: 'Aba: Faturamento', tables: [] },
                    { value: 'pcp_tab_liberacao', label: 'Aba: Expedição', tables: [] }
                ]}
            ]
        },
        {
            module: 'Logística & Frota',
            categories: [
                { name: 'Expedição', items: [
                    { value: 'log_delivery', label: 'Controle de Entregas', tables: [] }
                ]},
                { name: 'Frota', items: [
                    { value: 'fleet_vehicles', label: 'Gestão de Veículos', tables: [] },
                    { value: 'fleet_refueling', label: 'Registro de Abastecimento', tables: [] }
                ]}
            ]
        },
        {
            module: 'Financeiro',
            categories: [
                { name: 'Caixa e Bancos', items: [
                    { value: 'fin_receivables', label: 'Contas a Receber', tables: ['finance_receivables'] },
                    { value: 'fin_payables', label: 'Contas a Pagar', tables: ['finance_payables'] },
                    { value: 'fin_accounts', label: 'Contas Bancárias e Conciliação', tables: ['finance_accounts'] },
                    { value: 'fin_statement', label: 'Extrato Bancário', tables: ['finance_transactions'] }
                ]}
            ]
        },
        {
            module: 'Fiscal & Tributário',
            categories: [
                { name: 'Documentos Fiscais', items: [
                    { value: 'fisc_nfe_sell', label: 'Emissor NFe (Venda)', tables: [] },
                    { value: 'fisc_nfe_buy', label: 'Monitor NFe (Compras)', tables: [] },
                    { value: 'fisc_nfce_sell', label: 'Emissor NFCe', tables: [] },
                    { value: 'fisc_cte_issuer', label: 'Emissor CTe', tables: [] }
                ]},
                { name: 'Cadastros Contábeis', items: [
                    { value: 'fisc_companies', label: 'Empresas / Holding', tables: [] },
                    { value: 'fisc_stores', label: 'Lojas / Filiais', tables: [] },
                    { value: 'fisc_chart', label: 'Plano de Contas', tables: [] },
                    { value: 'fisc_pay_methods', label: 'Formas de Pagamento', tables: [] },
                    { value: 'fisc_tax_rules', label: 'Regras Tributárias (ICMS)', tables: [] }
                ]}
            ]
        },
        {
            module: 'Relatórios Gerenciais',
            categories: [
                { name: 'Exportação de Dados', items: [
                    { value: 'view_reports', label: 'Acessar Hub de Relatórios', tables: [] },
                    { value: 'rep_fin_payables', label: 'Relatório Contas a Pagar', tables: [] },
                    { value: 'rep_fin_receivables', label: 'Relatório Contas a Receber', tables: [] },
                    { value: 'rep_fin_dre', label: 'Relatório DRE', tables: [] },
                    { value: 'rep_sales', label: 'Relatórios e Auditoria de Vendas', tables: [] }
                ]}
            ]
        },
        {
            module: 'Recursos Humanos',
            categories: [
                { name: 'Time e Controle', items: [
                    { value: 'cad_employees', label: 'Dossiê Colaboradores', tables: ['employees_mj'] },
                    { value: 'rh_ponto', label: 'Gestão de Ponto Eletrônico e Totem', tables: [] },
                    { value: 'rh_beneficios', label: 'Gestão de Benefícios', tables: [] }
                ]}
            ]
        },
        {
            module: 'Marketplace B2B',
            categories: [
                { name: 'Administração do Hub', items: [
                    { value: 'admin_integrations', label: 'Acesso Global ao Hub B2B (Layout, Estampas, VIP)', tables: [] }
                ]}
            ]
        },
        {
            module: 'Loja Varejo (Cajuia)',
            categories: [
                { name: 'Sistema Loja Cajuia', items: [
                    { value: 'cajuia_dashboard', label: 'Painel Vendedor / Dashboard', tables: [] },
                    { value: 'cajuia_orders', label: 'Gestão de Pedidos Cajuia', tables: [] },
                    { value: 'cajuia_nfe', label: 'Emissor NFe Cajuia', tables: [] },
                    { value: 'cajuia_clients', label: 'Base de Clientes Cajuia', tables: [] },
                    { value: 'cajuia_financial', label: 'Financeiro Cajuia', tables: [] },
                    { value: 'cajuia_admin', label: 'Administração (Ruptura/Estoque Cajuia)', tables: [] }
                ]}
            ]
        },
        {
            module: 'Administração Sistema',
            categories: [
                { name: 'Segurança Global', items: [
                    { value: 'admin_general', label: 'Painel Geral de Configurações (Admin Master)', tables: [] },
                    { value: 'config_low_stock_alerts', label: 'Configurar Alertas Automáticos (SRE)', tables: [] }
                ]}
            ]
        }
    ];
});

// --- ESTADOS DO MODAL DE CARGOS ---
const roleFormRef = ref<VForm | null>(null);
const roleManagementModal = reactive({
    show: false,
    loading: false,
    form: {
        id: null as string | null,
        name: '',
        description: '',
        is_supervisor: false,
        permissions: [] as string[],
        read_only_permissions: [] as string[],
        delete_permissions: [] as string[]
    }
});

const pwdModal = reactive({ show: false, user: null as any, newPassword: '', loading: false });

const getLocalYYYYMMDD = (d: Date) => {
    const y = d.getFullYear();
    const m = String(d.getMonth() + 1).padStart(2, '0');
    const day = String(d.getDate()).padStart(2, '0');
    return `${y}-${m}-${day}`;
};

const commissionModal = reactive({
  show: false, loading: false, userId: null as string | null, externalSellerName: '',
  startDate: getLocalYYYYMMDD(new Date(new Date().getFullYear(), new Date().getMonth(), 1)),
  endDate: getLocalYYYYMMDD(new Date()),
  results: [] as any[], totalPaid: 0, totalCommission: 0, userPercentage: 0
});

const rules = {
  required: (v: any) => !!v || 'Campo obrigatório',
  email: (v: string) => /.+@.+\..+/.test(v) || 'E-mail inválido',
  minLength: (len: number) => (v: string) => (v && v.length >= len) || `Mínimo ${len} caracteres`
};

// Funções exclusivas para o Modal de Cargos (Role Builder)
const isRoleReadOnlyActive = (permValue: string) => roleManagementModal.form.read_only_permissions.includes(permValue);
const isRoleDeleteActive = (permItem: any) => {
    if (!permItem.tables || permItem.tables.length === 0) return false;
    return permItem.tables.every((table: string) => roleManagementModal.form.delete_permissions.includes(table));
};
const toggleRoleReadOnly = (permValue: string) => {
    const list = roleManagementModal.form.read_only_permissions;
    const index = list.indexOf(permValue);
    if (index > -1) list.splice(index, 1);
    else list.push(permValue);
};
const toggleRoleDelete = (permItem: any) => {
    const list = roleManagementModal.form.delete_permissions;
    if (!permItem.tables || permItem.tables.length === 0) {
        appStore.showSnackbar('Nenhuma tabela associada para exclusão neste módulo.', 'info');
        return;
    }
    const active = isRoleDeleteActive(permItem);
    if (active) {
        permItem.tables.forEach((table: string) => {
            const idx = list.indexOf(table);
            if (idx > -1) list.splice(idx, 1);
        });
    } else {
        permItem.tables.forEach((table: string) => {
            if (!list.includes(table)) list.push(table);
        });
    }
};

// KPIs
const kpiList = computed(() => {
    const total = users.value.length;
    const active = users.value.filter(u => u.is_active !== false).length;
    const sellers = users.value.filter(u => u.role === 'vendedor' || u.cajuia_role?.includes('vendedor')).length;
    const admins = users.value.filter(u => u.role === 'admin' || u.cajuia_role?.includes('admin') || u._isSupervisor).length;

    return [
        { label: 'Total Cadastros', value: total, footer: 'Base Completa', icon: 'mdi-account-group', gradient: 'bg-gradient-info' },
        { label: 'Acessos Ativos', value: active, footer: 'Permitidos no Sistema', icon: 'mdi-account-key', gradient: 'bg-gradient-success' },
        { label: 'Vendedores', value: sellers, footer: 'Equipe Comercial', icon: 'mdi-account-cash', gradient: 'bg-gradient-warning' },
        { label: 'Administradores', value: admins, footer: 'Gestão e Supervisão', icon: 'mdi-security', gradient: 'bg-gradient-purple' },
    ];
});

const formatCurrency = (val: number) => new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(val || 0);
const formatDate = (date: string) => {
    if (!date) return '--';
    const safeDate = date.length === 10 ? `${date}T12:00:00` : date;
    return format(new Date(safeDate), 'dd/MM/yyyy');
};

const getSelectedUserName = computed(() => {
    if (commissionModal.externalSellerName) return commissionModal.externalSellerName;
    return users.value.find(u => u.id === commissionModal.userId)?.full_name || 'Vendedor Não Selecionado';
});

const divergenceCount = computed(() => commissionModal.results.filter(r => r.isDivergent).length);

const fetchAuxiliaryData = async () => {
    try {
        const [empRes, storeRes, compRes, rolesRes] = await Promise.all([
            supabase.from('employees_mj').select('id, nome, cargo, situacao').order('nome'),
            supabase.from('stores').select('*').eq('active', true),
            supabase.from('companies').select('id, trade_name').order('trade_name'),
            supabase.from('custom_roles').select('*').order('name')
        ]);
        if (empRes.data) employeesList.value = empRes.data;
        if (storeRes.data) stores.value = storeRes.data;
        if (compRes.data) companiesList.value = compRes.data;
        if (rolesRes.data) customRoles.value = rolesRes.data;
    } catch (e) { console.warn('Aviso: Tabela custom_roles pode não existir ainda.', e); }
};

const fetchUsers = async () => {
  loading.value = true;
  try {
    const { data: profiles } = await supabase.from('profiles').select('*, permissions').order('full_name');
    const { data: permissions } = await supabase.from('cajuia_permissions').select('user_id, role');
    const { data: designPerms } = await supabase.from('design_user_permissions').select('*');

    const permMap = new Map(permissions?.map(p => [p.user_id, p.role]));
    const designPermMap = new Map(designPerms?.map(p => [p.user_id, p]));

    users.value = (profiles || []).map(p => {
        const cajRole = permMap.get(p.id) || null;
        const customRole = customRoles.value.find(cr => cr.id === p.custom_role_id);
        const dPerm: any = designPermMap.get(p.id) || {};

        return {
            ...p,
            cajuia_role: cajRole,
            _cajuiaRoleFormatted: cajRole ? cajRole.replace('_cajuia', '').toUpperCase() : '',
            _storeName: stores.value.find(s => s.id === p.store_id)?.name || 'Matriz / Indefinido',
            _employeeName: employeesList.value.find(e => e.id === p.employee_id)?.nome || 'Sem Vínculo (RH)',
            _customRoleName: customRole ? customRole.name : 'Sem Cargo Definido',
            _isSupervisor: customRole ? customRole.is_supervisor : false,
            // Variáveis de Design
            is_design_leader: dPerm.is_leader || false,
            requires_design_approval: dPerm.requires_leader_approval || false,
            can_approve_design: dPerm.can_approve_for_leader || false
        };
    });
  } catch (err: any) { appStore.showSnackbar(err.message, 'error'); } finally { loading.value = false; }
};

// --- GESTÃO DE CARGOS ---
const openRoleManagement = () => {
    resetRoleForm();
    roleManagementModal.show = true;
};

const resetRoleForm = () => {
    roleManagementModal.form = { id: null, name: '', description: '', is_supervisor: false, permissions: [], read_only_permissions: [], delete_permissions: [] };
};

const selectRoleToEdit = (role: any) => {
    roleManagementModal.form = {
        id: role.id,
        name: role.name,
        description: role.description || '',
        is_supervisor: role.is_supervisor,
        permissions: Array.isArray(role.permissions) ? [...role.permissions] : [],
        read_only_permissions: Array.isArray(role.read_only_permissions) ? [...role.read_only_permissions] : [],
        delete_permissions: Array.isArray(role.delete_permissions) ? [...role.delete_permissions] : []
    };
};

const saveRole = async () => {
    if (!roleManagementModal.form.name) return appStore.showSnackbar('Nome do cargo é obrigatório', 'warning');
    roleManagementModal.loading = true;
    try {
        const payload = {
            name: roleManagementModal.form.name,
            description: roleManagementModal.form.description,
            is_supervisor: roleManagementModal.form.is_supervisor,
            permissions: roleManagementModal.form.permissions,
            read_only_permissions: roleManagementModal.form.read_only_permissions,
            delete_permissions: roleManagementModal.form.delete_permissions
        };

        if (roleManagementModal.form.id) {
            await supabase.from('custom_roles').update(payload).eq('id', roleManagementModal.form.id);
        } else {
            await supabase.from('custom_roles').insert(payload);
        }
        appStore.showSnackbar('Cargo salvo com sucesso!', 'success');

        await fetchAuxiliaryData();
        await fetchUsers();

        if (!roleManagementModal.form.id) {
             const newRole = customRoles.value.find(r => r.name === payload.name);
             if (newRole) selectRoleToEdit(newRole);
        }
    } catch (e: any) {
        appStore.showSnackbar('Erro ao salvar cargo: ' + e.message, 'error');
    } finally {
        roleManagementModal.loading = false;
    }
};

const deleteRole = async (id: string) => {
    if (!confirm('Deseja excluir este cargo? Os usuários não perderão o acesso, apenas o vínculo com o template será removido.')) return;
    try {
        await supabase.from('custom_roles').delete().eq('id', id);
        appStore.showSnackbar('Cargo excluído', 'success');
        resetRoleForm();
        await fetchAuxiliaryData();
        await fetchUsers();
    } catch (e:any) {
         appStore.showSnackbar('Erro ao excluir: ' + e.message, 'error');
    }
};

const openCommissionReport = () => {
  commissionModal.userId = null; commissionModal.results = []; commissionModal.totalPaid = 0; commissionModal.totalCommission = 0; commissionModal.show = true;
};

// --- LÓGICA DE COMISSÕES ---
const calculateCommission = async () => {
    if (!commissionModal.userId) return appStore.showSnackbar('Selecione um vendedor.', 'warning');
    if (!commissionModal.startDate || !commissionModal.endDate) return appStore.showSnackbar('Defina o período.', 'warning');

    commissionModal.loading = true;
    try {
        const userObj = users.value.find(u => u.id === commissionModal.userId);
        const perc = userObj?.commission_percentage || 0;
        commissionModal.userPercentage = perc;

        // VERIFICA SE O USUÁRIO PERTENCE À SANTOS & LOPES
        const userCompany = companiesList.value.find(c => c.id === userObj?.company_id);
        const isSantosELopes = userCompany && userCompany.trade_name.toLowerCase().includes('santos');

        const rawResults = [];
        let totalPaid = 0;
        let totalComm = 0;

        if (isSantosELopes) {
            const { data: directSales, error: directError } = await supabase
                .from('store_sales')
                .select('id, order_number, date_sale, customer_name, total_value')
                .eq('seller_id', commissionModal.userId)
                .gte('date_sale', `${commissionModal.startDate}T00:00:00-03:00`)
                .lte('date_sale', `${commissionModal.endDate}T23:59:59-03:00`)
                .order('date_sale', { ascending: false });

            if (directError) throw directError;

            if (directSales) {
                for (const sale of directSales) {
                    const valTotal = Number(sale.total_value || 0);
                    const com = valTotal * (perc / 100);

                    totalPaid += valTotal;
                    totalComm += com;

                    rawResults.push({
                        orderId: sale.id, orderNumber: sale.order_number, date: sale.date_sale, customer: sale.customer_name || 'Consumidor Balcão',
                        totalOrderValue: valTotal, totalValue: valTotal, total_value: valTotal, paidValue: valTotal,
                        commission: com, isDivergent: false, trueOwnerName: '', isStoreSale: true
                    });
                }
            }
        } else {
            const { data: receivables, error: recError } = await supabase
                .from('finance_receivables')
                .select('id, value, payment_date, order_id, description, status')
                .eq('status', 'pago')
                .gte('payment_date', `${commissionModal.startDate}T00:00:00-03:00`)
                .lte('payment_date', `${commissionModal.endDate}T23:59:59-03:00`);

            if (recError) throw recError;

            if (receivables && receivables.length > 0) {
                const { data: orders } = await supabase
                    .from('orders')
                    .select('id, order_number, created_at, customer_name, total_value')
                    .eq('created_by', commissionModal.userId)
                    .order('created_at', { ascending: false })
                    .limit(10000);

                const { data: storeSales } = await supabase
                    .from('store_sales')
                    .select('id, order_number, date_sale, customer_name, total_value')
                    .eq('seller_id', commissionModal.userId)
                    .order('date_sale', { ascending: false })
                    .limit(10000);

                const sellerOrdersMap = new Map();
                if (orders) orders.forEach(o => sellerOrdersMap.set(o.id, { ...o, is_store_sale: false }));
                if (storeSales) storeSales.forEach(o => sellerOrdersMap.set(o.id, { ...o, created_at: o.date_sale, is_store_sale: true }));

                for (const rec of receivables) {
                    let matchedOrder = null;
                    const recDesc = (rec.description || '').toLowerCase();

                    const cleanDesc = recDesc
                        .replace(/\b\d{2}\/\d{2}\/\d{2,4}\b/g, ' ')
                        .replace(/r\$\s*[\d.,]+/gi, ' ')
                        .replace(/\b\d+,\d{2}\b/g, ' ');

                    const foundNumbers = (cleanDesc.match(/\d+/g) || []).map(n => Number(n));

                    if (rec.order_id && sellerOrdersMap.has(rec.order_id)) {
                        matchedOrder = sellerOrdersMap.get(rec.order_id);
                    } else if (foundNumbers.length > 0) {
                        if (storeSales) {
                            for (const sale of storeSales) {
                                if (foundNumbers.includes(Number(sale.order_number))) {
                                    matchedOrder = sellerOrdersMap.get(sale.id);
                                    break;
                                }
                            }
                        }
                        if (!matchedOrder && orders) {
                            for (const ord of orders) {
                                if (foundNumbers.includes(Number(ord.order_number))) {
                                    matchedOrder = sellerOrdersMap.get(ord.id);
                                    break;
                                }
                            }
                        }
                    }

                    if (matchedOrder) {
                        const valRecebido = Number(rec.value || 0);
                        const com = valRecebido * (perc / 100);
                        const valPedidoTotal = Number(matchedOrder.total_value || 0);

                        totalPaid += valRecebido;
                        totalComm += com;

                        rawResults.push({
                            orderId: matchedOrder.id, orderNumber: matchedOrder.order_number, date: rec.payment_date, customer: matchedOrder.customer_name || 'Desconhecido',
                            totalOrderValue: valPedidoTotal, totalValue: valPedidoTotal, total_value: valPedidoTotal, paidValue: valRecebido,
                            commission: com, isDivergent: false, trueOwnerName: '', isStoreSale: matchedOrder.is_store_sale
                        });
                    }
                }
            }
        }

        // AGRUPAMENTO E SOMA FINAL
        const groupedResults = new Map();
        let totalSumOfOrders = 0;

        for (const r of rawResults) {
            if (groupedResults.has(r.orderId)) {
                const ex = groupedResults.get(r.orderId);
                ex.paidValue += r.paidValue;
                ex.commission += r.commission;
            } else {
                groupedResults.set(r.orderId, { ...r });
                totalSumOfOrders += r.totalOrderValue;
            }
        }

        const finalResults = Array.from(groupedResults.values()).sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime());

        commissionModal.results = finalResults;
        commissionModal.totalPaid = totalPaid;
        commissionModal.totalCommission = totalComm;
        commissionModal.totalOrderValue = totalSumOfOrders;
        commissionModal.totalValue = totalSumOfOrders;

        if (finalResults.length === 0) appStore.showSnackbar('Nenhum dado encontrado para este vendedor.', 'info');
        else appStore.showSnackbar('Comissões calculadas com sucesso!', 'success');

    } catch (e: any) {
        console.error(e);
        appStore.showSnackbar('Erro ao calcular comissões.', 'error');
    } finally {
        commissionModal.loading = false;
    }
};

const reassignOrderOwner = async (orderId: string, newSellerId: string, index: number, isStoreSale: boolean) => {
    try {
        const tableName = isStoreSale ? 'store_sales' : 'orders';
        const columnName = isStoreSale ? 'seller_id' : 'created_by';

        await supabase.from(tableName).update({ [columnName]: newSellerId }).eq('id', orderId);

        appStore.showSnackbar('Venda transferida para outro vendedor com sucesso!', 'success');
        commissionModal.results.splice(index, 1);
        recalculateTotals();
    } catch (e) {
        appStore.showSnackbar('Erro ao transferir.', 'error');
    }
};

const recalculateTotals = () => {
    let grandTotalPaid = 0;
    commissionModal.results.forEach(res => grandTotalPaid += res.paidValue);
    commissionModal.totalPaid = grandTotalPaid;
    commissionModal.totalCommission = grandTotalPaid * (commissionModal.userPercentage / 100);
};

const generateDetailedPDF = () => {
  const doc = new jsPDF();
  const sellerName = getSelectedUserName.value;

  doc.setFillColor(230, 81, 0);
  doc.rect(0, 0, 210, 50, 'F');

  doc.setTextColor(255, 255, 255);
  doc.setFontSize(22);
  doc.setFont('helvetica', 'bold');
  doc.text('MJ PROCESS SOLUTIONS', 14, 20);

  doc.setFontSize(14);
  doc.setFont('helvetica', 'normal');
  doc.text('RELATÓRIO DE COMISSÕES E VENDAS', 14, 28);

  doc.setFontSize(10);
  doc.text(`Gerado em: ${format(new Date(), 'dd/MM/yyyy HH:mm')}`, 14, 38);

  doc.setFontSize(12);
  doc.setFont('helvetica', 'bold');
  doc.text(`COLABORADOR: ${sellerName.toUpperCase()}`, 196, 20, { align: 'right' });
  doc.setFontSize(10);
  doc.setFont('helvetica', 'normal');
  doc.text(`Período: ${formatDate(commissionModal.startDate)} a ${formatDate(commissionModal.endDate)}`, 196, 28, { align: 'right' });

  doc.text(`Base de Cálculo (Recebido): ${formatCurrency(commissionModal.totalPaid)}`, 196, 36, { align: 'right' });

  doc.setFont('helvetica', 'bold');
  doc.text(`Comissão Total: ${formatCurrency(commissionModal.totalCommission)}`, 196, 44, { align: 'right' });

  const tableBody = commissionModal.results.map(res => [
      res.orderNumber,
      formatDate(res.date),
      res.customer,
      res.isDivergent ? `DIVERGENTE: ${res.trueOwnerName}` : 'OK',
      formatCurrency(res.totalOrderValue),
      formatCurrency(res.paidValue),
      formatCurrency(res.commission)
  ]);

  autoTable(doc, {
    head: [['PEDIDO', 'DATA', 'CLIENTE', 'STATUS CARTEIRA', 'V. TOTAL', 'BASE PAGA', 'COMISSÃO']],
    body: tableBody,
    startY: 55,
    theme: 'grid',
    headStyles: { fillColor: [66, 66, 66], textColor: 255, fontStyle: 'bold', fontSize: 9 },
    styles: { fontSize: 8, cellPadding: 3, valign: 'middle' },
    columnStyles: {
        3: { fontStyle: 'bold', textColor: [183, 28, 28] },
        5: { halign: 'right', fontStyle: 'bold' },
        6: { halign: 'right', fontStyle: 'bold', textColor: [27, 94, 32] }
    },
    didParseCell: (data) => {
        if (data.column.index === 3 && data.cell.text[0] === 'OK') {
            data.cell.styles.textColor = [100, 100, 100];
            data.cell.styles.fontStyle = 'normal';
        }
    }
  });

  const pageCount = doc.getNumberOfPages();
  for(let i = 1; i <= pageCount; i++) {
     doc.setPage(i);
     doc.setFontSize(8);
     doc.setTextColor(150);
     doc.text(`Página ${i} de ${pageCount} - Documento interno confidencial`, 105, 290, { align: 'center' });
  }

  doc.save(`Comissao_${sellerName.replace(/\s/g, '_')}_${commissionModal.startDate}.pdf`);
};

const exportToExcel = () => {
    const data = commissionModal.results.map(r => ({
        "Pedido": r.orderNumber,
        "Data": formatDate(r.date),
        "Cliente": r.customer,
        "Status Carteira": r.isDivergent ? `Pertence a ${r.trueOwnerName}` : "Regular",
        "Valor Pedido": r.totalOrderValue,
        "Base Comissão (Pago)": r.paidValue,
        "Comissão Gerada": r.commission
    }));

    data.push({
        "Pedido": "TOTAL GERAL",
        "Data": "-",
        "Cliente": "-",
        "Status Carteira": "-",
        "Valor Pedido": commissionModal.totalOrderValue,
        "Base Comissão (Pago)": commissionModal.totalPaid,
        "Comissão Gerada": commissionModal.totalCommission
    });

    const ws = XLSX.utils.json_to_sheet(data);
    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, "Relatorio");
    XLSX.writeFile(wb, `Comissao_${getSelectedUserName.value}.xlsx`);
};

const executePasswordReset = async () => {
  if (pwdModal.newPassword.length < 6) return appStore.showSnackbar('Senha curta demais', 'warning');
  pwdModal.loading = true;
  try {
    const { error } = await supabase.functions.invoke('update-user-password', {
        body: { userId: pwdModal.user.id, password: pwdModal.newPassword },
        headers: { "Content-Type": "application/json" }
    });
    if (error) throw error;
    appStore.showSnackbar('Senha alterada!', 'success');
    pwdModal.show = false;
  } catch (e: any) { appStore.showSnackbar('Erro ao trocar senha', 'error'); } finally { pwdModal.loading = false; }
};

const openPasswordReset = (user: any) => { pwdModal.user = user; pwdModal.newPassword = ''; pwdModal.show = true; }

const filteredUsers = computed(() => {
  let list = users.value || [];
  if (roleFilter.value !== 'Todos') list = list.filter(u => u.role === roleFilter.value);
  if (statusFilter.value === 'Ativos') list = list.filter(u => u.is_active !== false);
  if (statusFilter.value === 'Inativos') list = list.filter(u => u.is_active === false);

  if (search.value) {
    const s = search.value.toLowerCase();
    list = list.filter(u => u.full_name?.toLowerCase().includes(s) || u.email?.toLowerCase().includes(s));
  }
  return list;
});

const paginatedUsers = computed(() => {
  const list = filteredUsers.value || [];
  const start = (page.value - 1) * itemsPerPage;
  return list.slice(start, start + itemsPerPage);
});

const pageCount = computed(() => {
  const list = filteredUsers.value || [];
  return Math.ceil(list.length / itemsPerPage);
});

const zebraClass = (i: number) => themeStore.currentMode !== 'light' ? (i % 2 === 0 ? 'zebra-dark-a' : 'zebra-dark-b') : (i % 2 === 0 ? 'zebra-light-a' : 'zebra-light-b');

onMounted(() => {
    fetchAuxiliaryData();
    fetchUsers();
});
</script>

<style scoped lang="scss">
/* Layout Geral da Tela */
.admin-user-management-wrapper { position: absolute; top: 0; left: 0; right: 0; bottom: 0; width: 100%; height: 100%; z-index: 5; }
.background-carousel-wrapper { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 0; opacity: 0.6; pointer-events: none; }
.background-overlay { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 1; background: radial-gradient(circle at center, rgba(15, 15, 19, 0.4), rgba(15, 15, 19, 0.98)); backdrop-filter: blur(8px); }
.z-10 { position: relative; z-index: 10; }

.bg-glass-dark { background: rgba(10,10,12,0.85); }
.bg-glass-header { background: rgba(20,20,24,0.55); backdrop-filter: blur(14px); }
.border-bottom-white-05 { border-bottom: 1px solid rgba(255,255,255,0.08); }
.btn-rect { border-radius: 0 !important; text-transform: none !important; font-weight: 800; }
.controls-bar { border: 1px solid rgba(0,0,0,0.08); padding: 10px; }
.search-wrap { height: 40px; padding: 0 12px; border: 1px solid rgba(0,0,0,0.08); display: flex; align-items: center; min-width: 300px; flex: 1; }
.clean-input { border: none; outline: none; flex: 1; font-size: 12px; }

/* Grid System Responsivo Fluído (Padrão Receivables) */
.grid-scroll { scrollbar-gutter: stable; -webkit-overflow-scrolling: touch; }
.custom-scroll::-webkit-scrollbar { width: 8px; height: 8px; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.35); border-radius: 6px; }
.custom-scroll::-webkit-scrollbar-track { background: transparent; }

.grid-header, .grid-row {
    display: grid;
    align-items: stretch;
    width: 100%;
}

.grid-users-layout {
    grid-template-columns: 60px minmax(200px, 2fr) minmax(180px, 1.5fr) minmax(160px, 1.5fr) minmax(140px, 1fr) 90px 100px;
    min-width: 950px;
}

.cell {
    padding: 6px 10px;
    display: flex;
    align-items: center;
    border-right: 1px solid rgba(0,0,0,0.08);
    border-bottom: 1px solid rgba(0,0,0,0.08);
    min-height: 54px;
    overflow: hidden;
}

.header-text { font-size: 13px !important; font-weight: 900; text-transform: uppercase; letter-spacing: 0.5px; color: rgba(0,0,0,0.7); }
.center { justify-content: center; text-align: center; }

/* Themes & Zebrado */
.grid-surface-light .cell { background: #f5f7fa; border-color: rgba(0,0,0,0.10) !important; color: rgba(0,0,0,0.9); }
.grid-surface-dark .cell { background: rgba(255,255,255,0.08); color: rgba(255,255,255,0.95); border-color: rgba(255,255,255,0.1) !important; }

.grid-row-light .cell { border-color: rgba(0,0,0,0.06) !important; }
.grid-row-dark .cell { border-color: rgba(255,255,255,0.06) !important; }

.zebra-light-a .cell { background: #ffffff; }
.zebra-light-b .cell { background: #f0f4f8; }
.zebra-dark-a .cell { background: rgba(0,0,0,0.15); }
.zebra-dark-b .cell { background: rgba(255,255,255,0.03); }

.grid-row-light:hover .cell { background: #e3f2fd !important; cursor: pointer; }
.grid-row-dark:hover .cell { background: rgba(255,255,255,0.12) !important; cursor: pointer; }

/* Cabeçalho Fixo */
.sticky-head { position: sticky; top: 0; z-index: 20; box-shadow: 0 8px 16px -4px rgba(0, 0, 0, 0.12); }
.bg-glass-dark .sticky-head { box-shadow: 0 8px 20px -4px rgba(0, 0, 0, 0.4); }

/* KPI Cards */
.kpi-card { color: white; position: relative; min-height: 110px; overflow: hidden; border-radius: 8px;}
.kpi-bg-icon { position: absolute; right: -20px; bottom: -20px; opacity: 0.15; transform: rotate(-15deg); }
.kpi-bg-icon .v-icon { font-size: 100px; color: white; }
.bg-gradient-info { background: linear-gradient(135deg, #0288d1, #005b9f); }
.bg-gradient-success { background: linear-gradient(135deg, #2e7d32, #1b5e20); }
.bg-gradient-purple { background: linear-gradient(135deg, #7b1fa2, #4a148c); }
.bg-gradient-warning { background: linear-gradient(135deg, #FFB300, #F57F17); }
.kpi-label { font-size: 12px; font-weight: 900; letter-spacing: .2px; text-transform: uppercase; }
.kpi-value { font-size: 24px; font-weight: 900; }
.kpi-footer { font-size: 11px; opacity: .9; font-weight: 700; text-transform: uppercase; }

/* Tipografia e Chips da Grid */
.list-text-11 { font-size: 13px !important; line-height: 1.2 !important; }
.list-text-10 { font-size: 12px !important; line-height: 1.2 !important; }
.grayscale-low { filter: grayscale(100%); }

.actions-inline { display: flex; gap: 4px; justify-content: center; }
.action-btn { width: 28px !important; height: 28px !important; border-radius: 6px !important; color: #fff !important; }
.action-edit { background: #1976d2 !important; }
.action-pwd { background: #455a64 !important; }
.ui-field :deep(.v-field) { border-radius: 6px !important; }
.row-gap-sm { row-gap: 12px; }

/* Switches Elegantes */
.modern-switch :deep(.v-switch__track) { background-color: rgba(0,0,0,0.1) !important; opacity: 1; }
.modern-switch :deep(.v-switch__thumb) { box-shadow: 0 2px 4px rgba(0,0,0,0.15); }
.modern-switch :deep(.v-label) { font-size: 12px !important; font-weight: 800; color: #424242; opacity: 0.9; }

.sub-switch :deep(.v-label) { font-size: 11px !important; font-weight: 700; color: #616161; }

.hover-bg-grey:hover { background-color: rgba(0,0,0,0.03); }
.hover-border-blue:hover { border-color: rgba(21, 101, 192, 0.4) !important; box-shadow: 0 4px 12px rgba(21, 101, 192, 0.1) !important; transform: translateY(-2px); z-index: 5; }

/* Formulários do Modal */
.input-label {
    font-size: 11px;
    font-weight: 900;
    text-transform: uppercase;
    color: #616161;
    display: block;
    margin-bottom: 4px;
    letter-spacing: 0.5px;
}

.section-block { transition: all 0.3s ease; }
.section-block:hover { box-shadow: 0 6px 16px rgba(0,0,0,0.06) !important; border-color: rgba(0,0,0,0.12) !important; }
.tracking-tight { letter-spacing: -0.5px !important; }
.line-height-1-2 { line-height: 1.2; }
.opacity-100 { opacity: 1 !important; }
.opacity-0 { opacity: 0 !important; }
.transition-all { transition: all 0.3s ease; }
.transition-colors { transition: background-color 0.2s ease, border-color 0.2s ease; }
</style>
