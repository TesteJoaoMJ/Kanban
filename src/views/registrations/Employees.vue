<template>
  <div
    class="employees-layout font-sans fill-height d-flex flex-column relative overflow-hidden"
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
        <div class="d-flex flex-column">
          <div class="breadcrumb text-caption">
            <span class="opacity-70">RH & Departamento Pessoal</span>
            <span class="mx-2 opacity-50">></span>
            <span class="font-weight-bold">Colaboradores</span>
          </div>
          <div class="text-h6 font-weight-black tracking-tight leading-none mt-1" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">
            Gestão de Equipe e Dossiês
          </div>
        </div>

        <div class="d-flex align-center" style="gap: 10px;">
          <v-btn
            color="grey-darken-4"
            variant="flat"
            class="btn-rect px-4 font-weight-bold text-caption text-uppercase letter-spacing-1"
            prepend-icon="mdi-account-plus"
            height="40"
            @click="openNewEmployeeModal"
          >
            Novo Colaborador
          </v-btn>

          <v-btn
            variant="outlined"
            class="btn-rect"
            height="40"
            prepend-icon="mdi-dots-grid"
            :color="themeStore.currentMode === 'light' ? 'grey-darken-2' : 'white'"
            @click="actionsModal.show = true"
          >
            Ações
          </v-btn>
        </div>
      </div>

      <div class="px-6 pt-4 pb-2 flex-shrink-0">
        <v-row dense>
          <v-col cols="12" sm="6" md="4">
            <v-card class="kpi-card kpi-rect bg-gradient-blue-grey hover-elevate py-3 px-4" v-ripple elevation="2">
              <div class="kpi-bg-icon"><v-icon>mdi-account-group</v-icon></div>
              <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height text-white">
                <div class="d-flex align-center" style="gap: 8px;">
                  <v-icon size="18" class="opacity-80">mdi-account-group</v-icon>
                  <span class="kpi-label">Quadro Total</span>
                </div>
                <div class="kpi-number-group my-1"><span class="kpi-value">{{ totalEmployees }}</span></div>
                <div class="kpi-footer mt-1">Registros na Base</div>
              </div>
            </v-card>
          </v-col>
          <v-col cols="12" sm="6" md="4">
            <v-card class="kpi-card kpi-rect bg-gradient-success hover-elevate py-3 px-4" v-ripple elevation="2">
              <div class="kpi-bg-icon"><v-icon>mdi-account-check</v-icon></div>
              <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height text-white">
                <div class="d-flex align-center" style="gap: 8px;">
                  <v-icon size="18" class="opacity-80">mdi-account-check</v-icon>
                  <span class="kpi-label">Força Ativa</span>
                </div>
                <div class="kpi-number-group my-1"><span class="kpi-value">{{ activeEmployees }}</span></div>
                <div class="kpi-footer mt-1">Colaboradores Operantes</div>
              </div>
            </v-card>
          </v-col>
          <v-col cols="12" sm="6" md="4">
            <v-card class="kpi-card kpi-rect bg-gradient-orange hover-elevate py-3 px-4" v-ripple elevation="2">
              <div class="kpi-bg-icon"><v-icon>mdi-account-off</v-icon></div>
              <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height text-white">
                <div class="d-flex align-center" style="gap: 8px;">
                  <v-icon size="18" class="opacity-80">mdi-account-clock</v-icon>
                  <span class="kpi-label">Afastados / Desligados</span>
                </div>
                <div class="kpi-number-group my-1"><span class="kpi-value">{{ inactiveEmployees }}</span></div>
                <div class="kpi-footer mt-1">Histórico Retido</div>
              </div>
            </v-card>
          </v-col>
        </v-row>
      </div>

      <div class="px-6 pt-2 pb-2 flex-shrink-0">
        <div class="controls-bar d-flex align-center justify-space-between" :class="themeStore.currentMode === 'light' ? 'controls-light' : 'controls-dark'">
          <div class="d-flex align-center flex-wrap" style="gap: 10px; width: 100%;">

            <div class="search-wrap d-flex align-center" :class="themeStore.currentMode === 'light' ? 'search-light' : 'search-dark'" style="flex: 2;">
              <v-icon :color="themeStore.currentMode === 'light' ? 'grey-darken-1' : 'white-70'">mdi-magnify</v-icon>
              <input
                v-model="search"
                type="text"
                placeholder="Buscar por nome, cargo ou CPF..."
                class="clean-input flex-grow-1"
                :class="themeStore.currentMode === 'light' ? 'text-grey-darken-3' : 'text-white'"
                @input="page = 1"
              />
            </div>

            <div class="search-wrap d-flex align-center px-0" style="flex: 1;" :class="themeStore.currentMode === 'light' ? 'search-light' : 'search-dark'">
                <v-select
                    v-model="statusFilter"
                    :items="['Ativos', 'Afastados/Inativos', 'Todos']"
                    variant="plain"
                    density="compact"
                    hide-details
                    class="font-weight-bold text-caption w-100 px-2"
                ></v-select>
            </div>

            <div class="search-wrap d-flex align-center px-0" style="flex: 1;" :class="themeStore.currentMode === 'light' ? 'search-light' : 'search-dark'">
                <v-select
                    v-model="roleFilter"
                    :items="roleOptions"
                    variant="plain"
                    density="compact"
                    hide-details
                    class="font-weight-bold text-caption w-100 px-2"
                ></v-select>
            </div>

            <v-btn variant="text" class="btn-rect ml-auto" height="40" :color="themeStore.currentMode === 'light' ? 'grey-darken-2' : 'grey-lighten-1'" prepend-icon="mdi-refresh" @click="fetchEmployees" :loading="loading">
                Atualizar
            </v-btn>

          </div>
        </div>
      </div>

      <v-expand-transition>
        <div v-if="selectedEmployees.length > 0" class="px-6 pb-2 flex-shrink-0">
          <div class="d-flex align-center justify-space-between pa-2 px-4 rounded-0" :class="themeStore.currentMode === 'light' ? 'bg-amber-lighten-5 border border-amber-lighten-4' : 'bg-amber-darken-4 border border-amber-darken-3'">
             <div class="d-flex align-center gap-2">
                 <v-icon color="amber-darken-3">mdi-checkbox-multiple-marked</v-icon>
                 <span class="font-weight-bold text-body-2 text-amber-darken-4">{{ selectedEmployees.length }} colaborador(es) selecionado(s)</span>
             </div>
             <div class="d-flex align-center gap-2">
                 <v-btn v-if="selectedEmployees.length >= 2" color="amber-darken-3" variant="flat" size="small" class="font-weight-bold rounded-0" prepend-icon="mdi-call-merge" @click="openMergeModal">
                     Mesclar Cadastros Duplicados
                 </v-btn>
                 <v-btn variant="text" size="small" color="grey-darken-2" class="rounded-0" @click="selectedEmployees = []">Limpar Seleção</v-btn>
             </div>
          </div>
        </div>
      </v-expand-transition>

      <div class="flex-grow-1 px-6 pb-6 overflow-hidden d-flex flex-column">
        <v-card class="flex-grow-1 d-flex flex-column rounded-0 border-thin overflow-hidden" :class="themeStore.currentMode === 'light' ? 'bg-white shadow-sm' : 'glass-card border-white-05'" :elevation="0">
          <div class="grid-scroll flex-grow-1 overflow-y-auto custom-scroll">

            <div class="grid-header sticky-head" :class="[themeStore.currentMode === 'light' ? 'grid-surface-light' : 'grid-surface-dark', 'grid-layout']">
              <div class="cell center header-text"><v-checkbox-btn v-model="selectAll" density="compact" color="primary" class="chk-fixed"></v-checkbox-btn></div>
              <div class="cell header-text">Colaborador</div>
              <div class="cell header-text">Cargo / Função</div>
              <div class="cell header-text">Contato</div>
              <div class="cell center header-text">Status Base</div>
              <div class="cell center header-text">Ações</div>
            </div>

            <div v-if="loading" class="d-flex flex-column justify-center align-center h-100 py-12">
              <v-progress-circular indeterminate color="grey-darken-4" size="32" width="3"></v-progress-circular>
            </div>

            <div v-else-if="filteredEmployees.length === 0" class="d-flex flex-column justify-center align-center h-100 opacity-60 gap-2 py-12">
              <v-icon size="48" color="grey-lighten-1">mdi-account-off-outline</v-icon>
              <span class="text-body-2 font-weight-medium text-grey">Nenhum colaborador encontrado neste filtro.</span>
            </div>

            <div v-else v-for="emp in paginatedEmployees" :key="emp.id" class="grid-row grid-layout" :class="themeStore.currentMode === 'light' ? 'grid-row-light' : 'grid-row-dark'" @click="openEditModal(emp)">
               <div class="cell center" @click.stop>
                  <v-checkbox-btn v-model="selectedEmployees" :value="emp.id" density="compact" color="grey-darken-4" class="chk-fixed"></v-checkbox-btn>
               </div>

               <div class="cell">
                  <div class="d-flex align-center w-100" style="min-width: 0;">
                        <v-avatar :color="getColor(emp.nome)" size="32" variant="tonal" class="rounded-0 mr-3 flex-shrink-0 font-weight-bold text-caption">
                          {{ emp.nome?.charAt(0)?.toUpperCase() }}
                        </v-avatar>
                        <div class="d-flex flex-column overflow-hidden" style="min-width: 0;">
                          <span class="text-truncate list-text-11 font-weight-black text-uppercase" :class="emp.status === 'inativo' ? 'text-grey text-decoration-line-through' : 'text-grey-darken-4'" :title="emp.nome">{{ emp.nome }}</span>
                          <span class="list-text-10 opacity-70 text-truncate font-mono" v-if="emp.cpf">CPF: {{ emp.cpf }}</span>
                        </div>
                   </div>
               </div>

               <div class="cell">
                   <v-chip v-if="emp.cargo" size="x-small" variant="outlined" color="blue-grey-darken-2" class="font-weight-bold text-uppercase rounded-2px">{{ emp.cargo }}</v-chip>
                   <span v-else class="list-text-10 opacity-50 font-italic">Não Definido</span>
               </div>

               <div class="cell">
                   <div class="d-flex flex-column">
                       <div v-if="emp.email" class="d-flex align-center gap-1 mb-1"><v-icon size="10" class="opacity-70">mdi-email</v-icon><span class="list-text-10 font-weight-medium">{{ emp.email }}</span></div>
                       <div v-if="emp.celular || emp.telefone" class="d-flex align-center gap-1"><v-icon size="10" class="opacity-70">mdi-phone</v-icon><span class="list-text-10 font-weight-medium">{{ emp.celular || emp.telefone }}</span></div>
                       <span v-if="!emp.email && !emp.celular && !emp.telefone" class="list-text-10 opacity-50 italic">Sem contato</span>
                   </div>
               </div>

               <div class="cell center">
                   <v-chip size="x-small" :color="emp.status === 'inativo' ? 'error' : (emp.status === 'afastado' ? 'warning' : 'success')" variant="flat" class="font-weight-black rounded-2px text-uppercase">
                       {{ emp.status === 'inativo' ? 'DESLIGADO' : (emp.status === 'afastado' ? 'AFASTADO' : 'ATIVO') }}
                   </v-chip>
               </div>

               <div class="cell center">
                   <div class="actions-inline">
                        <v-tooltip text="Ver Dossiê / Editar" location="top" content-class="bg-black text-white font-weight-bold">
                           <template v-slot:activator="{ props }">
                               <v-btn v-bind="props" icon size="x-small" class="action-btn action-edit" @click.stop="openEditModal(emp)"><v-icon size="16">mdi-folder-account</v-icon></v-btn>
                           </template>
                       </v-tooltip>

                       <v-tooltip :text="emp.status !== 'inativo' && emp.status !== 'afastado' ? 'Afastar / Desligar' : 'Reativar / Recontratar'" location="top" content-class="bg-black text-white font-weight-bold">
                           <template v-slot:activator="{ props }">
                               <v-btn v-bind="props" icon size="x-small" class="action-btn" :class="emp.status !== 'inativo' && emp.status !== 'afastado' ? 'bg-orange-darken-3' : 'bg-green-darken-3'" @click.stop="emp.status !== 'inativo' && emp.status !== 'afastado' ? openDismissModal(emp) : openRehireModal(emp)">
                                   <v-icon size="16">{{ emp.status !== 'inativo' && emp.status !== 'afastado' ? 'mdi-account-minus' : 'mdi-account-convert' }}</v-icon>
                               </v-btn>
                           </template>
                       </v-tooltip>

                       <v-tooltip text="Exclusão Definitiva" location="top" content-class="bg-black text-white font-weight-bold">
                           <template v-slot:activator="{ props }">
                               <v-btn v-bind="props" icon size="x-small" class="action-btn action-del" @click.stop="openDeleteModal(emp)"><v-icon size="16">mdi-trash-can-outline</v-icon></v-btn>
                           </template>
                       </v-tooltip>
                   </div>
               </div>
            </div>
          </div>

          <div class="flex-shrink-0 border-t px-4 py-2 d-flex align-center justify-space-between" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-4 text-grey-darken-3' : 'bg-white-05 text-white'">
            <div class="text-caption opacity-80 font-weight-bold">
              Total nesta visão: <strong class="font-mono">{{ filteredEmployees.length }}</strong> | Página {{ page }} de {{ totalPages }}
            </div>
            <v-pagination v-model="page" :length="totalPages" :total-visible="5" density="compact" active-color="grey-darken-4" variant="tonal" size="small"></v-pagination>
          </div>
        </v-card>
      </div>
    </div>

    <v-dialog v-model="dismissModal.show" max-width="500" persistent scrim="black opacity-80">
        <v-card class="rounded-0 border border-grey-darken-1 bg-white shadow-md">
            <div class="px-6 py-4 border-b bg-orange-darken-3 text-white d-flex justify-space-between align-center">
                <div class="text-h6 font-weight-black d-flex align-center gap-2"><v-icon>mdi-account-minus</v-icon> Alterar Status Funcional</div>
                <v-btn icon="mdi-close" variant="text" size="small" @click="dismissModal.show = false"></v-btn>
            </div>
            <div class="pa-6">
                <div class="text-body-2 font-weight-bold mb-4 text-grey-darken-3">
                    Você está prestes a suspender as atividades de <strong class="text-uppercase">{{ dismissModal.employee?.nome }}</strong>.
                </div>

                <label class="input-label">Tipo de Movimentação</label>
                <v-select v-model="dismissModal.type" :items="['Desligamento (Demissão)', 'Afastamento INSS', 'Licença Maternidade/Paternidade', 'Licença Não Remunerada']" variant="outlined" density="compact" class="ui-field font-weight-bold mb-2"></v-select>

                <label class="input-label">Data Efetiva</label>
                <v-text-field v-model="dismissModal.date" type="date" variant="outlined" density="compact" class="ui-field font-weight-bold font-mono mb-2"></v-text-field>

                <label class="input-label">Motivo / Descrição</label>
                <v-text-field v-model="dismissModal.reason" placeholder="Ex: Quebra de Contrato, Auxílio Doença..." variant="outlined" density="compact" class="ui-field font-weight-bold mb-2"></v-text-field>

                <label class="input-label">Anexar Comprovante / TRCT (Opcional)</label>
                <v-file-input v-model="dismissModal.file" variant="outlined" density="compact" prepend-inner-icon="mdi-paperclip" prepend-icon="" class="ui-field font-weight-bold mb-2"></v-file-input>
            </div>
            <div class="pa-4 bg-grey-lighten-4 border-t d-flex justify-end gap-3">
                <v-btn variant="outlined" color="grey-darken-2" class="btn-rect font-weight-bold bg-white" @click="dismissModal.show = false">Cancelar</v-btn>
                <v-btn color="orange-darken-3" variant="flat" class="btn-rect font-weight-black px-6" :loading="dismissModal.loading" @click="executeDismiss">Confirmar Movimentação</v-btn>
            </div>
        </v-card>
    </v-dialog>

    <v-dialog v-model="rehireModal.show" max-width="450" persistent scrim="black opacity-80">
        <v-card class="rounded-0 border border-grey-darken-1 bg-white shadow-md">
            <div class="px-6 py-4 border-b bg-green-darken-3 text-white d-flex justify-space-between align-center">
                <div class="text-h6 font-weight-black d-flex align-center gap-2"><v-icon>mdi-account-convert</v-icon> Reativar Cadastro</div>
                <v-btn icon="mdi-close" variant="text" size="small" @click="rehireModal.show = false"></v-btn>
            </div>
            <div class="pa-6">
                <div class="text-body-2 font-weight-bold mb-4 text-grey-darken-3">
                    Retornar <strong class="text-uppercase">{{ rehireModal.employee?.nome }}</strong> ao quadro ativo.
                </div>
                <label class="input-label">Data de Retorno / Recontratação</label>
                <v-text-field v-model="rehireModal.date" type="date" variant="outlined" density="compact" class="ui-field font-weight-bold font-mono mb-2"></v-text-field>
                <label class="input-label">Observação (Opcional)</label>
                <v-text-field v-model="rehireModal.notes" placeholder="Ex: Fim do auxílio, recontratado..." variant="outlined" density="compact" class="ui-field font-weight-bold mb-2"></v-text-field>
            </div>
            <div class="pa-4 bg-grey-lighten-4 border-t d-flex justify-end gap-3">
                <v-btn variant="outlined" color="grey-darken-2" class="btn-rect font-weight-bold bg-white" @click="rehireModal.show = false">Cancelar</v-btn>
                <v-btn color="green-darken-3" variant="flat" class="btn-rect font-weight-black px-6" :loading="rehireModal.loading" @click="executeRehire">Reativar Colaborador</v-btn>
            </div>
        </v-card>
    </v-dialog>

    <v-dialog v-model="mergeModal.show" max-width="700" persistent scrim="black opacity-80">
        <v-card class="rounded-0 overflow-hidden d-flex flex-column" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-grey-darken-4'">
            <div class="px-6 py-4 border-b d-flex justify-space-between align-center bg-amber-darken-3 text-white flex-shrink-0">
                <div class="d-flex align-center gap-3">
                    <v-icon size="24">mdi-call-merge</v-icon>
                    <span class="text-h6 font-weight-bold">Mesclar Colaboradores</span>
                </div>
                <v-btn icon variant="text" @click="mergeModal.show = false"><v-icon color="white">mdi-close</v-icon></v-btn>
            </div>
            <div class="pa-6 custom-scroll overflow-y-auto" style="max-height: 60vh;">
                <v-alert type="warning" variant="tonal" class="mb-4 text-caption font-weight-medium border-amber-darken-3 rounded-0">
                    Selecione o <strong>Cadastro Principal</strong>. Os dados em branco dele serão preenchidos pelos outros selecionados. <strong>Os demais serão excluídos permanentemente.</strong>
                </v-alert>

                <v-radio-group v-model="mergeModal.masterId" hide-details>
                    <v-card v-for="emp in mergeModal.candidates" :key="emp.id" variant="outlined" class="mb-3 border-thin rounded-0" :class="mergeModal.masterId === emp.id ? 'border-primary bg-primary-lighten-5' : ''" @click="mergeModal.masterId = emp.id">
                        <div class="pa-4 d-flex align-center gap-3">
                            <v-radio :value="emp.id" color="primary"></v-radio>
                            <div class="flex-grow-1">
                                <div class="font-weight-black text-body-2 text-uppercase">{{ emp.nome }} <span class="text-[10px] font-mono opacity-60 ml-2" v-if="emp.gestao_click_id">ERP: {{ emp.gestao_click_id }}</span></div>
                                <div class="text-[10px] opacity-80 mt-1 d-flex flex-wrap gap-3 font-mono">
                                    <span><strong>CPF:</strong> {{ emp.cpf || '-' }}</span>
                                    <span><strong>EMAIL:</strong> {{ emp.email || '-' }}</span>
                                    <span><strong>TEL:</strong> {{ emp.celular || emp.telefone || '-' }}</span>
                                </div>
                            </div>
                        </div>
                    </v-card>
                </v-radio-group>
            </div>
            <div class="px-6 py-4 border-t d-flex justify-end gap-3 bg-grey-lighten-4">
                <v-btn variant="outlined" color="grey-darken-2" class="btn-rect font-weight-bold bg-white" @click="mergeModal.show = false">Cancelar</v-btn>
                <v-btn color="amber-darken-3" variant="flat" class="btn-rect font-weight-black px-6" :loading="mergeModal.loading" :disabled="!mergeModal.masterId" @click="executeMerge">Mesclar e Excluir</v-btn>
            </div>
        </v-card>
    </v-dialog>

    <EmployeeDetailsModal
        v-model:show="detailsModal.show"
        :employee="detailsModal.employee"
        @close="detailsModal.show = false"
        @refresh="fetchEmployees"
    />

    <v-dialog v-model="actionsModal.show" width="500" persistent scrim="black opacity-75">
      <v-card class="rounded-0 overflow-hidden" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-grey-darken-4'">
        <div class="px-6 py-4 border-b d-flex justify-space-between align-center" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-4' : 'bg-grey-darken-3'">
          <div>
            <div class="text-overline font-weight-black opacity-70 leading-none">Ferramentas</div>
            <div class="text-h6 font-weight-black mt-1">Ações Globais</div>
          </div>
          <v-btn icon variant="text" @click="actionsModal.show = false"><v-icon>mdi-close</v-icon></v-btn>
        </div>

        <div class="pa-6">
          <v-row dense>
             <v-col cols="12" v-if="userStore.isAdmin">
                 <v-card class="d-flex align-center pa-4 cursor-pointer hover-elevate mb-3 border-thin rounded-0" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5' : 'bg-white-05'" @click="syncFromERP" v-ripple>
                     <v-avatar color="grey-darken-4" variant="flat" rounded="0" class="mr-4"><v-icon color="white">mdi-cloud-sync</v-icon></v-avatar>
                     <div><div class="font-weight-bold text-body-2 text-uppercase">Sincronizar com ERP</div><div class="text-[10px] opacity-70">Busca colaboradores atualizados no GestãoClick.</div></div>
                 </v-card>
             </v-col>
             <v-col cols="6">
                 <v-card class="d-flex flex-column align-center justify-center pa-4 cursor-pointer hover-elevate border-thin h-100 rounded-0" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5' : 'bg-white-05'" @click="exportExcel" v-ripple>
                     <v-icon color="success" size="32" class="mb-2">mdi-microsoft-excel</v-icon>
                     <div class="font-weight-bold text-[11px] text-uppercase">Exportar CSV</div>
                 </v-card>
             </v-col>
             <v-col cols="6">
                 <v-card class="d-flex flex-column align-center justify-center pa-4 cursor-pointer hover-elevate border-thin h-100 rounded-0" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5' : 'bg-white-05'" @click="exportPDF" v-ripple>
                     <v-icon color="red-darken-1" size="32" class="mb-2">mdi-file-pdf-box</v-icon>
                     <div class="font-weight-bold text-[11px] text-uppercase">Relatório PDF</div>
                 </v-card>
             </v-col>
          </v-row>
        </div>
      </v-card>
    </v-dialog>

    <v-dialog v-model="deleteModal.show" width="450" persistent scrim="black opacity-80">
        <v-card class="rounded-0 text-center pa-6 d-flex flex-column align-center" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-grey-darken-4'">
            <v-avatar color="red-lighten-5" size="80" class="mb-4 text-red-darken-2 rounded-0"><v-icon size="40">mdi-alert-octagon-outline</v-icon></v-avatar>
            <div class="text-h6 font-weight-black text-uppercase mb-2">Exclusão Definitiva</div>
            <div class="text-body-2 text-grey-darken-1 mb-6">Apagar o registro de <strong class="text-uppercase">{{ deleteModal.emp?.nome }}</strong> do banco de dados?<br><span class="text-[10px] text-error mt-2 d-block">Recomendamos usar o "Afastar/Desligar" para manter histórico.</span></div>
            <div class="d-flex w-100" style="gap: 12px;">
                <v-btn class="flex-grow-1 btn-rect font-weight-bold" variant="outlined" height="40" @click="deleteModal.show = false">Cancelar</v-btn>
                <v-btn class="flex-grow-1 btn-rect font-weight-black" color="red-darken-3" variant="flat" height="40" :loading="deleteModal.loading" @click="confirmDelete">Apagar</v-btn>
            </div>
        </v-card>
    </v-dialog>

  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, reactive } from 'vue';
import { supabase } from '@/api/supabase';
import { gestaoApi } from '@/api/gestaoClick';
import { useThemeStore } from '@/stores/themeStore';
import { useAppStore } from '@/stores/app';
import { useUserStore } from '@/stores/user';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import { format } from 'date-fns';

// Componente do Dossiê Premium
import EmployeeDetailsModal from '@/components/registrations/EmployeeDetailsModal.vue';

const themeStore = useThemeStore();
const appStore = useAppStore();
const userStore = useUserStore();

// STATE
const loading = ref(false);
const employees = ref<any[]>([]);
const search = ref('');
const roleFilter = ref('Todos os Cargos');
const statusFilter = ref('Ativos'); // Novo filtro

const selectedEmployees = ref<string[]>([]);
const page = ref(1);
const itemsPerPage = 30;

// MODAIS
const actionsModal = reactive({ show: false });
const deleteModal = reactive({ show: false, loading: false, emp: null as any });
const detailsModal = reactive({ show: false, employee: null as any });

const mergeModal = reactive({
    show: false, loading: false, candidates: [] as any[], masterId: null as string | null
});

const dismissModal = reactive({
    show: false, loading: false, employee: null as any,
    type: 'Desligamento (Demissão)', date: new Date().toISOString().split('T')[0], reason: '', file: null as File | null
});

const rehireModal = reactive({
    show: false, loading: false, employee: null as any,
    date: new Date().toISOString().split('T')[0], notes: ''
});

// UTILS
const getColor = (name: string) => {
    const colors = ['primary', 'info', 'success', 'warning', 'blue-grey', 'teal'];
    let hash = 0;
    if(!name) return 'grey';
    for(let i=0; i<name.length; i++) hash = name.charCodeAt(i) + ((hash << 5) - hash);
    return colors[Math.abs(hash) % colors.length];
};

// FETCH DATA
const fetchEmployees = async () => {
    loading.value = true;
    try {
        const { data, error } = await supabase.from('employees_mj').select('*').order('nome', { ascending: true });
        if (error) throw error;

        // Garante que quem não tem status setado receba 'ativo'
        employees.value = (data || []).map(e => ({ ...e, status: e.status || 'ativo' }));
    } catch (e) {
        appStore.showSnackbar("Erro ao buscar equipe", "error");
    } finally {
        loading.value = false;
    }
};

// COMPUTEDS E FILTROS
const roleOptions = computed(() => {
    const roles = new Set(employees.value.map(e => e.cargo).filter(c => c && c.trim() !== ''));
    return ['Todos os Cargos', 'Sem Cargo Definido', ...Array.from(roles)];
});

const filteredEmployees = computed(() => {
    let list = [...employees.value];

    // Filtro de Status
    if (statusFilter.value === 'Ativos') {
        list = list.filter(e => e.status !== 'inativo' && e.status !== 'afastado');
    } else if (statusFilter.value === 'Afastados/Inativos') {
        list = list.filter(e => e.status === 'inativo' || e.status === 'afastado');
    }

    // Filtro de Cargo
    if (roleFilter.value === 'Sem Cargo Definido') {
        list = list.filter(e => !e.cargo || e.cargo.trim() === '');
    } else if (roleFilter.value !== 'Todos os Cargos') {
        list = list.filter(e => e.cargo === roleFilter.value);
    }

    // Busca Textual
    if (search.value) {
        const s = search.value.toLowerCase();
        list = list.filter(e =>
            e.nome?.toLowerCase().includes(s) ||
            e.cargo?.toLowerCase().includes(s) ||
            e.cpf?.includes(s)
        );
    }
    return list;
});

const paginatedEmployees = computed(() => {
    const start = (page.value - 1) * itemsPerPage;
    return filteredEmployees.value.slice(start, start + itemsPerPage);
});

const totalPages = computed(() => Math.ceil(filteredEmployees.value.length / itemsPerPage) || 1);

const selectAll = computed({
    get: () => paginatedEmployees.value.length > 0 && selectedEmployees.value.length === paginatedEmployees.value.length,
    set: (val) => {
        if (val) selectedEmployees.value = paginatedEmployees.value.map(c => c.id);
        else selectedEmployees.value = [];
    }
});

// KPIs
const totalEmployees = computed(() => employees.value.length);
const activeEmployees = computed(() => employees.value.filter(e => e.status !== 'inativo' && e.status !== 'afastado').length);
const inactiveEmployees = computed(() => employees.value.filter(e => e.status === 'inativo' || e.status === 'afastado').length);

const kpiList = computed(() => []); // Substituto no template diretamente

// AÇÕES DE MOVIMENTAÇÃO (Afastar/Reativar)
const openDismissModal = (emp: any) => {
    dismissModal.employee = emp;
    dismissModal.type = 'Desligamento (Demissão)';
    dismissModal.date = new Date().toISOString().split('T')[0];
    dismissModal.reason = '';
    dismissModal.file = null;
    dismissModal.show = true;
};

const executeDismiss = async () => {
    if (!dismissModal.reason || !dismissModal.date) return appStore.showSnackbar('Preencha data e motivo.', 'warning');
    dismissModal.loading = true;
    try {
        const emp = dismissModal.employee;
        let docUrl = null;
        let docName = null;

        if (dismissModal.file) {
            const file = Array.isArray(dismissModal.file) ? dismissModal.file[0] : dismissModal.file;
            const fileExt = file.name.split('.').pop();
            const fileName = `doc_${Date.now()}_${Math.random().toString(36).substring(7)}.${fileExt}`;
            const { error: uploadError } = await supabase.storage.from('customer_assets').upload(`employees/docs/${fileName}`, file);
            if (uploadError) throw uploadError;
            const { data } = supabase.storage.from('customer_assets').getPublicUrl(`employees/docs/${fileName}`);
            docUrl = data.publicUrl;
            docName = file.name;
        }

        const isAfastamento = dismissModal.type.includes('Afastamento') || dismissModal.type.includes('Licença');
        const newStatus = isAfastamento ? 'afastado' : 'inativo';

        const newHistoryEvent = {
            type: isAfastamento ? 'Licença' : 'Desligamento',
            date: dismissModal.date,
            description: `${dismissModal.type}: ${dismissModal.reason}`,
            old_value: 'Ativo',
            new_value: isAfastamento ? 'Afastado' : 'Desligado',
            ui_id: Date.now()
        };

        const updatedHistory = [...(emp.career_history || []), newHistoryEvent];
        const updatedDocs = [...(emp.documents || [])];
        if (docUrl) {
            updatedDocs.push({
                name: `[${isAfastamento ? 'Afastamento' : 'Desligamento'}] ${docName || 'Comprovante'}`,
                url: docUrl,
                category: 'Atestados Médicos / Afastamentos', // Pode customizar
                uploaded_at: new Date().toISOString()
            });
        }

        const { error } = await supabase.from('employees_mj').update({
            status: newStatus,
            career_history: updatedHistory,
            documents: updatedDocs,
            updated_at: new Date().toISOString()
        }).eq('id', emp.id);

        if (error) throw error;

        appStore.showSnackbar(`Colaborador ${newStatus.toUpperCase()} com sucesso!`, 'success');
        dismissModal.show = false;
        fetchEmployees();
    } catch (e: any) {
        appStore.showSnackbar(`Erro: ${e.message}`, 'error');
    } finally {
        dismissModal.loading = false;
    }
};

const openRehireModal = (emp: any) => {
    rehireModal.employee = emp;
    rehireModal.date = new Date().toISOString().split('T')[0];
    rehireModal.notes = '';
    rehireModal.show = true;
};

const executeRehire = async () => {
    if (!rehireModal.date) return appStore.showSnackbar('Preencha a data.', 'warning');
    rehireModal.loading = true;
    try {
        const emp = rehireModal.employee;

        const newHistoryEvent = {
            type: 'Admissão',
            date: rehireModal.date,
            description: `Retorno / Reativação. ${rehireModal.notes ? 'Obs: ' + rehireModal.notes : ''}`,
            old_value: emp.status === 'afastado' ? 'Afastado' : 'Desligado',
            new_value: 'Ativo',
            ui_id: Date.now()
        };

        const updatedHistory = [...(emp.career_history || []), newHistoryEvent];

        const { error } = await supabase.from('employees_mj').update({
            status: 'ativo',
            career_history: updatedHistory,
            updated_at: new Date().toISOString()
        }).eq('id', emp.id);

        if (error) throw error;

        appStore.showSnackbar('Colaborador reativado no quadro!', 'success');
        rehireModal.show = false;
        fetchEmployees();
    } catch (e: any) {
        appStore.showSnackbar(`Erro: ${e.message}`, 'error');
    } finally {
        rehireModal.loading = false;
    }
};

// AÇÕES CRUD BÁSICAS
const openNewEmployeeModal = () => { detailsModal.employee = null; detailsModal.show = true; };
const openEditModal = (emp: any) => { detailsModal.employee = emp; detailsModal.show = true; };
const openDeleteModal = (emp: any) => { deleteModal.emp = emp; deleteModal.show = true; };

const confirmDelete = async () => {
    deleteModal.loading = true;
    try {
        await supabase.from('employees_mj').delete().eq('id', deleteModal.emp.id);
        appStore.showSnackbar("Excluído definitivamente", "success");
        fetchEmployees();
    } catch(e) { appStore.showSnackbar("Erro ao excluir", "error"); } finally { deleteModal.loading = false; deleteModal.show = false; }
};

// FERRAMENTA DE MESCLAGEM (MERGE)
const openMergeModal = () => {
    mergeModal.candidates = employees.value.filter(e => selectedEmployees.value.includes(e.id));
    mergeModal.masterId = mergeModal.candidates[0]?.id || null;
    mergeModal.show = true;
};

const executeMerge = async () => {
    if (!mergeModal.masterId) return;
    mergeModal.loading = true;

    try {
        const master = mergeModal.candidates.find(c => c.id === mergeModal.masterId);
        const slaves = mergeModal.candidates.filter(c => c.id !== mergeModal.masterId);

        let mergedData: any = {};
        const fieldsToCheck = ['cpf', 'rg', 'birth_date', 'email', 'telefone', 'celular', 'cargo', 'contract_type'];

        fieldsToCheck.forEach(field => {
            if (!master[field] || master[field].trim() === '') {
                const provider = slaves.find(s => s[field] && String(s[field]).trim() !== '');
                if (provider) mergedData[field] = provider[field];
            }
        });

        if (Object.keys(mergedData).length > 0) {
            await supabase.from('employees_mj').update(mergedData).eq('id', master.id);
        }

        const slaveIds = slaves.map(s => s.id);
        await supabase.from('employees_mj').delete().in('id', slaveIds);

        appStore.showSnackbar(`Mesclagem concluída. ${slaves.length} registro(s) redundantes removidos.`, "success");
        selectedEmployees.value = [];
        mergeModal.show = false;
        fetchEmployees();
    } catch (e) {
        appStore.showSnackbar("Erro durante a mesclagem.", "error");
    } finally {
        mergeModal.loading = false;
    }
};

// EXPORT E SYNC (ERP)
const syncFromERP = async () => {
    actionsModal.show = false;
    appStore.showSnackbar("Iniciando busca no ERP. Aguarde...", "info");
    try {
        const remote = await gestaoApi.buscarFuncionarios('');
        if (remote && remote.length > 0) {
            for (const item of remote) {
                const payload = { gestao_click_id: item.id, nome: item.nome, email: item.email, telefone: item.fone, celular: item.celular, cpf: item.cpf, cargo: item.cargo, updated_at: new Date() };
                await supabase.from('employees_mj').upsert(payload, { onConflict: 'gestao_click_id' });
            }
            appStore.showSnackbar("Sincronização concluída!", "success");
            fetchEmployees();
        }
    } catch(e) { appStore.showSnackbar("Erro ao conectar com ERP", "error"); }
};

const exportExcel = () => {
    const csvRows = [];
    const headers = ['ID ERP', 'Nome', 'Cargo', 'Status', 'CPF', 'Email', 'Celular'];
    csvRows.push(headers.join(';'));

    filteredEmployees.value.forEach(e => {
        const row = [e.gestao_click_id || '', e.nome || '', e.cargo || '', e.status || 'ativo', e.cpf || '', e.email || '', e.celular || ''];
        csvRows.push(row.map(r => `"${String(r).replace(/"/g, '""')}"`).join(';'));
    });

    const blob = new Blob([new Uint8Array([0xEF, 0xBB, 0xBF]), csvRows.join('\n')], { type: 'text/csv;charset=utf-8;' });
    const link = document.createElement("a");
    link.href = URL.createObjectURL(blob);
    link.download = `Equipe_MJ_${format(new Date(), 'ddMMyyyy')}.csv`;
    link.click();
    actionsModal.show = false;
};

const exportPDF = () => {
    const doc = new jsPDF();
    doc.text(`Relatório de Colaboradores`, 14, 15);
    autoTable(doc, {
        startY: 25,
        head: [['Nome', 'Cargo', 'Status', 'Contato']],
        body: filteredEmployees.value.map(c => [c.nome, c.cargo || '-', c.status ? c.status.toUpperCase() : 'ATIVO', c.celular || c.email || '-'])
    });
    doc.save(`Equipe_MJ_${format(new Date(), 'ddMMyyyy')}.pdf`);
    actionsModal.show = false;
};

onMounted(fetchEmployees);
</script>

<style scoped lang="scss">
/* ESTILO CORPORATIVO ADMINMJRECEIVABLES */
.employees-layout { position: relative; }
.background-carousel-wrapper { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 0; pointer-events: none; opacity: 0.6; }
.background-overlay { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 1; background: radial-gradient(circle at center, rgba(15, 15, 19, 0.6), rgba(15, 15, 19, 0.98)); backdrop-filter: blur(10px); }
.z-10 { position: relative; z-index: 10; }

.bg-glass-dark { background: rgba(10,10,12,0.85); }
.bg-glass-header { background: rgba(20,20,24,0.55); backdrop-filter: blur(14px); }
.border-bottom-white-05 { border-bottom: 1px solid rgba(255,255,255,0.08); }
.border-thin { border: 1px solid rgba(0,0,0,0.08); }
.bg-white-05 { background: rgba(255,255,255,0.05); }

/* CONTROLS */
.controls-bar { border: 1px solid rgba(0,0,0,0.08); border-radius: 0; padding: 10px; }
.controls-light { background: #ffffff; }
.controls-dark { background: rgba(30,30,35,0.55); backdrop-filter: blur(16px); border: 1px solid rgba(255,255,255,0.08); }

.search-wrap { height: 40px; border-radius: 0; padding: 0 12px; }
.search-light { background: #f4f6f8; border: 1px solid rgba(0,0,0,0.08); }
.search-dark { background: rgba(255,255,255,0.08); border: 1px solid rgba(255,255,255,0.10); }
.clean-input { border: none; outline: none; background: transparent; font-size: 12px; color: inherit; width: 100%; }

.btn-rect { border-radius: 0 !important; text-transform: none !important; font-weight: 800; }
.ui-field :deep(.v-field) { border-radius: 0px !important; font-size: 13px; background: #fff;}
.input-label { display: block; font-size: 11px; font-weight: 800; text-transform: uppercase; color: #757575; margin-bottom: 6px; letter-spacing: 0.5px; }

/* KPIs */
.kpi-card { border: 1px solid rgba(255,255,255,0.15); color: white; min-height: 100px; position: relative; overflow: hidden; }
.kpi-rect { border-radius: 0 !important; }
.kpi-bg-icon { position: absolute; right: -20px; bottom: -20px; opacity: 0.15; transform: rotate(-15deg); pointer-events: none; z-index: 0; }
.kpi-bg-icon .v-icon { font-size: 80px; color: white; }
.kpi-label { font-size: 11px; font-weight: 900; letter-spacing: .2px; text-transform: uppercase; }
.kpi-value { font-size: 24px; font-weight: 900; letter-spacing: .2px; font-family: monospace; }
.kpi-footer { font-size: 10px; opacity: .9; font-weight: 700; text-transform: uppercase; }

.bg-gradient-info { background: linear-gradient(135deg, #0288d1, #005b9f); }
.bg-gradient-success { background: linear-gradient(135deg, #2e7d32, #1b5e20); }
.bg-gradient-purple { background: linear-gradient(135deg, #7b1fa2, #4a148c); }
.bg-gradient-blue-grey { background: linear-gradient(135deg, #546e7a, #37474f); }
.bg-gradient-orange { background: linear-gradient(135deg, #ef6c00, #bf360c); }

/* GRID LAYOUT */
.glass-card { background: rgba(30, 30, 35, 0.45); backdrop-filter: blur(25px); border: 1px solid rgba(255,255,255,0.08); }
.grid-scroll { scrollbar-gutter: stable both-edges; }
.custom-scroll::-webkit-scrollbar { width: 8px; height: 8px; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.35); border-radius: 0px; }

.grid-header, .grid-row { display: grid; align-items: stretch; width: 100%; border-bottom: 1px solid rgba(0,0,0,0.08); }
.grid-layout { grid-template-columns: 50px 2fr 1.5fr 1.5fr 100px 140px; }

.cell { padding: 8px 10px; display: flex; align-items: center; border-right: 1px solid rgba(0,0,0,0.08); min-height: 52px; overflow: hidden; }
.center { justify-content: center; text-align: center; }

.grid-header .cell { min-height: 44px; font-size: 11px; font-weight: 900; text-transform: uppercase; letter-spacing: .6px; }
.header-text { font-size: 11px; }

.grid-surface-light .cell { background: #f5f7fa; color: rgba(0,0,0,0.7); border-color: rgba(0,0,0,0.10); }
.grid-surface-dark .cell { background: rgba(255,255,255,0.08); color: rgba(255,255,255,0.80); border-color: rgba(255,255,255,0.10); }

.grid-row-light .cell { background: #fff; border-color: rgba(0,0,0,0.08); color: #333; }
.grid-row-light:hover .cell { background: #f7fafc; cursor: pointer;}
.grid-row-dark .cell { background: rgba(255,255,255,0.04); border-color: rgba(255,255,255,0.08); }
.grid-row-dark:hover .cell { background: rgba(255,255,255,0.07); cursor: pointer; }

.sticky-head { position: sticky; top: 0; z-index: 10; }
.list-text-11 { font-size: 11px !important; line-height: 1.25 !important; }
.list-text-10 { font-size: 10px !important; line-height: 1.25 !important; }
.rounded-2px { border-radius: 2px !important; }

.actions-inline { display: flex; align-items: center; justify-content: center; gap: 4px; }
.action-btn { width: 26px !important; height: 26px !important; border-radius: 2px !important; color: #fff !important; }
.action-edit { background: #1976d2 !important; }
.action-del { background: #c62828 !important; }
.chk-fixed { margin: 0 !important; padding: 0 !important; }
</style>
