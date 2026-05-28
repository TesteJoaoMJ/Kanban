<template>
  <v-dialog
    :model-value="show"
    @update:model-value="handleUpdateShow"
    max-width="1400px"
    height="95vh"
    persistent
    scrim="black opacity-90"
    transition="dialog-bottom-transition"
    class="fixed-dialog"
  >
    <v-card class="d-flex flex-row rounded-0 overflow-hidden h-100 font-sans border border-grey-darken-2 bg-grey-lighten-4" elevation="24">

      <div class="sidebar-menu d-flex flex-column flex-shrink-0 bg-grey-darken-4 text-white border-r border-grey-darken-3 shadow-md" style="width: 290px; z-index: 20;">

          <div class="pa-6 d-flex flex-column align-center text-center border-b border-white-10 relative">
              <v-btn icon size="x-small" variant="text" color="white" class="absolute top-2 right-2 d-md-none rounded-0" @click="$emit('close')"><v-icon>mdi-close</v-icon></v-btn>

              <div class="relative mb-4 group cursor-pointer" @click="$refs.avatarInput.click()">
                  <v-avatar size="100" class="rounded-0 border-white-20 bg-grey-darken-3 transition-all">
                      <v-img v-if="form.avatar_url" :src="form.avatar_url" cover></v-img>
                      <v-icon v-else size="40" color="grey-lighten-1">mdi-account-tie</v-icon>
                  </v-avatar>
                  <div class="avatar-overlay absolute inset-0 d-flex align-center justify-center rounded-0 opacity-0 group-hover:opacity-100 transition-all bg-black-70">
                      <v-icon color="white" size="24">mdi-camera-plus</v-icon>
                  </div>
                  <input type="file" ref="avatarInput" accept="image/*" class="d-none" @change="uploadAvatar">
                  <v-progress-circular v-if="uploadingAvatar" indeterminate color="white" size="24" class="absolute inset-0 ma-auto"></v-progress-circular>
              </div>

              <h3 class="text-subtitle-1 font-weight-black leading-tight mb-1 text-white uppercase">{{ form.nome || 'NOVO COLABORADOR' }}</h3>
              <div class="text-[11px] font-weight-bold text-grey-lighten-1 text-uppercase tracking-widest mb-3">
                  {{ form.cargo || 'CARGO NÃO DEFINIDO' }}
              </div>
              <div class="d-flex align-center gap-2 justify-center w-100">
                  <span class="text-[10px] font-weight-bold px-2 py-1 bg-blue-grey-darken-3 rounded-0 text-uppercase border border-white-10">{{ form.contract_type || 'N/A' }}</span>
                  <span class="text-[10px] font-weight-bold px-2 py-1 bg-green-darken-3 rounded-0 text-uppercase border border-white-10" v-if="!isNew">ATIVO</span>
              </div>
          </div>

          <v-tabs v-model="activeTab" direction="vertical" color="white" class="flex-grow-1 custom-scroll" slider-color="white">
              <v-tab :value="0" class="text-none font-weight-bold justify-start px-5 tab-item"><v-icon start size="18" class="opacity-70">mdi-card-account-details</v-icon> Dados Pessoais e Contato</v-tab>
              <v-tab :value="1" class="text-none font-weight-bold justify-start px-5 tab-item"><v-icon start size="18" class="opacity-70">mdi-briefcase-account</v-icon> Vínculo Profissional</v-tab>
              <v-tab :value="2" class="text-none font-weight-bold justify-start px-5 tab-item"><v-icon start size="18" class="opacity-70">mdi-clock-check-outline</v-icon> Jornada de Trabalho</v-tab>
              <v-tab :value="3" class="text-none font-weight-bold justify-start px-5 tab-item"><v-icon start size="18" class="opacity-70">mdi-cash-multiple</v-icon> Remuneração e Custos</v-tab>
              <v-tab :value="4" class="text-none font-weight-bold justify-start px-5 tab-item"><v-icon start size="18" class="opacity-70">mdi-hand-heart</v-icon> Benefícios e Patrimônio</v-tab>
              <v-tab :value="5" class="text-none font-weight-bold justify-start px-5 tab-item"><v-icon start size="18" class="opacity-70">mdi-folder-account</v-icon> Cofre de Documentos <span class="ml-auto font-mono text-[10px] bg-white text-black px-1 rounded-0" v-if="form.documents?.length">{{ form.documents.length }}</span></v-tab>
              <v-tab :value="6" class="text-none font-weight-bold justify-start px-5 tab-item text-red-lighten-2"><v-icon start size="18">mdi-calculator-variant-outline</v-icon> TRCT (Rescisão)</v-tab>
          </v-tabs>

          <div class="pa-4 border-t border-white-10">
              <v-btn block color="blue-grey-darken-3" variant="flat" class="btn-rect font-weight-black text-[11px] tracking-widest mb-2" @click="exportDossierPdf" :loading="isExportingPdf">
                  <v-icon start size="16">mdi-file-pdf-box</v-icon> EXPORTAR DOSSIÊ
              </v-btn>
              <div class="text-center text-[9px] text-grey-lighten-1 font-weight-bold text-uppercase tracking-widest">Dossiê RH Premium</div>
          </div>
      </div>

      <div class="flex-grow-1 d-flex flex-column overflow-hidden relative bg-grey-lighten-4">

          <div class="px-6 py-4 d-flex justify-space-between align-center border-b border-grey-lighten-2 bg-white flex-shrink-0 z-10 shadow-sm">
              <div class="text-subtitle-1 font-weight-black text-uppercase text-grey-darken-4 d-flex align-center gap-2 tracking-widest">
                  <v-icon color="grey-darken-3" size="20">{{ tabIcons[activeTab] }}</v-icon>
                  {{ tabTitles[activeTab] }}
              </div>
              <div class="d-flex align-center gap-3">
                  <v-btn variant="outlined" color="grey-darken-2" class="btn-rect font-weight-bold bg-white" height="42" @click="$emit('close')">DESCARTAR</v-btn>
                  <v-btn color="success" variant="flat" class="btn-rect font-weight-black px-8 shadow-sm text-body-2 tracking-widest" height="42" :loading="isSaving" @click="saveEmployee">
                      <v-icon start>mdi-content-save-check</v-icon> SALVAR FICHA
                  </v-btn>
              </div>
          </div>

          <div class="flex-grow-1 overflow-y-auto pa-6 custom-scroll">
              <v-form ref="formRef" @submit.prevent>
                  <v-window v-model="activeTab" :touch="false" class="overflow-visible">

                      <v-window-item :value="0">
                          <v-card class="rounded-0 border border-grey-lighten-2 shadow-sm mb-6 bg-white" elevation="0">
                              <div class="px-5 py-3 border-b bg-grey-lighten-4 text-[11px] font-weight-black text-uppercase text-grey-darken-3 d-flex align-center gap-2">Identidade e Classificação</div>
                              <div class="pa-5">
                                  <v-row dense class="row-gap">
                                      <v-col cols="12" md="7"><label class="input-label">Nome Completo *</label><v-text-field v-model="form.nome" variant="outlined" density="compact" color="primary" class="ui-field font-weight-bold" :rules="[v => !!v || 'Obrigatório']"></v-text-field></v-col>
                                      <v-col cols="12" md="5"><label class="input-label">Estado Civil</label><v-select v-model="form.marital_status" :items="['Solteiro(a)', 'Casado(a)', 'Divorciado(a)', 'Viúvo(a)', 'União Estável']" variant="outlined" density="compact" color="primary" class="ui-field font-weight-bold"></v-select></v-col>
                                      <v-col cols="12" md="4"><label class="input-label">CPF *</label><v-text-field v-model="form.cpf" variant="outlined" density="compact" color="primary" class="ui-field font-mono font-weight-bold" v-maska="'###.###.###-##'"></v-text-field></v-col>
                                      <v-col cols="12" md="4"><label class="input-label">RG</label><v-text-field v-model="form.rg" variant="outlined" density="compact" color="primary" class="ui-field font-mono"></v-text-field></v-col>
                                      <v-col cols="12" md="4"><label class="input-label">Nascimento</label><v-text-field v-model="form.birth_date" type="date" variant="outlined" density="compact" color="primary" class="ui-field font-mono font-weight-bold"></v-text-field></v-col>
                                  </v-row>
                              </div>
                          </v-card>

                          <v-card class="rounded-0 border border-grey-lighten-2 shadow-sm mb-6 bg-white" elevation="0">
                              <div class="px-5 py-3 border-b bg-grey-lighten-4 text-[11px] font-weight-black text-uppercase text-grey-darken-3 d-flex align-center gap-2">Contato e Endereço</div>
                              <div class="pa-5">
                                  <v-row dense class="row-gap">
                                      <v-col cols="12" md="6"><label class="input-label">E-mail</label><v-text-field v-model="form.email" prepend-inner-icon="mdi-email" variant="outlined" density="compact" color="primary" class="ui-field"></v-text-field></v-col>
                                      <v-col cols="12" md="3"><label class="input-label">Celular</label><v-text-field v-model="form.celular" prepend-inner-icon="mdi-whatsapp" variant="outlined" density="compact" color="success" class="ui-field font-mono font-weight-bold" v-maska="['(##) ####-####', '(##) #####-####']"></v-text-field></v-col>
                                      <v-col cols="12" md="3"><label class="input-label">Fixo/Recado</label><v-text-field v-model="form.telefone" prepend-inner-icon="mdi-phone" variant="outlined" density="compact" color="primary" class="ui-field font-mono" v-maska="['(##) ####-####', '(##) #####-####']"></v-text-field></v-col>
                                      <v-col cols="12"><label class="input-label">Endereço Completo</label><v-text-field v-model="form.endereco_completo" variant="outlined" density="compact" color="primary" class="ui-field"></v-text-field></v-col>
                                  </v-row>
                                  <v-divider class="my-4 border-dashed"></v-divider>
                                  <div class="text-[11px] font-weight-black text-error text-uppercase mb-3 d-flex align-center gap-2"><v-icon size="16">mdi-ambulance</v-icon> Contato de Emergência</div>
                                  <v-row dense>
                                      <v-col cols="12" md="5"><label class="input-label">Nome do Contato</label><v-text-field v-model="form.emergency_contact.name" variant="outlined" density="compact" class="ui-field font-weight-bold"></v-text-field></v-col>
                                      <v-col cols="12" md="4"><label class="input-label">Parentesco</label><v-text-field v-model="form.emergency_contact.relation" placeholder="Ex: Esposa, Mãe" variant="outlined" density="compact" class="ui-field"></v-text-field></v-col>
                                      <v-col cols="12" md="3"><label class="input-label">Telefone Urgência</label><v-text-field v-model="form.emergency_contact.phone" variant="outlined" density="compact" class="ui-field font-mono font-weight-bold text-error" v-maska="['(##) ####-####', '(##) #####-####']"></v-text-field></v-col>
                                  </v-row>
                              </div>
                          </v-card>

                          <v-card class="rounded-0 border border-grey-lighten-2 shadow-sm bg-white" elevation="0">
                              <div class="px-5 py-3 border-b bg-grey-lighten-4 d-flex justify-space-between align-center">
                                  <div class="text-[11px] font-weight-black text-uppercase text-grey-darken-3 d-flex align-center gap-2">Familiares e Dependentes (IRRF)</div>
                                  <v-btn size="small" variant="flat" color="grey-darken-4" class="font-weight-bold btn-rect rounded-0" prepend-icon="mdi-plus" @click="showDependentModal = true">Adicionar</v-btn>
                              </div>
                              <div class="w-100 overflow-x-auto">
                                  <div v-if="!form.dependents || form.dependents.length === 0" class="pa-6 text-center text-[11px] font-weight-bold text-grey opacity-70 bg-white text-uppercase">Nenhum dependente cadastrado.</div>
                                  <table class="w-100 custom-grid-table" v-else>
                                      <thead class="bg-grey-lighten-5 border-b">
                                          <tr><th class="text-left text-uppercase font-weight-black text-[10px] text-grey-darken-2 pa-3">Nome do Dependente</th><th class="text-center text-uppercase font-weight-black text-[10px] text-grey-darken-2 pa-3">Parentesco</th><th class="text-center text-uppercase font-weight-black text-[10px] text-grey-darken-2 pa-3">Nascimento</th><th class="text-center text-uppercase font-weight-black text-[10px] text-grey-darken-2 pa-3">Ação</th></tr>
                                      </thead>
                                      <tbody>
                                          <tr v-for="(dep, idx) in form.dependents" :key="idx" class="border-b hover-row bg-white">
                                              <td class="pa-3 font-weight-bold text-[12px] text-grey-darken-4">{{ dep.name }}</td>
                                              <td class="pa-3 text-center"><v-chip size="x-small" variant="outlined" color="blue-grey-darken-2" class="font-weight-bold rounded-0">{{ dep.relation }}</v-chip></td>
                                              <td class="pa-3 text-center font-mono text-[12px]">{{ formatDate(dep.birth_date) }}</td>
                                              <td class="pa-3 text-center"><v-btn icon size="x-small" variant="text" color="error" class="rounded-0" @click="removeDependent(idx)"><v-icon size="16">mdi-delete</v-icon></v-btn></td>
                                          </tr>
                                      </tbody>
                                  </table>
                              </div>
                          </v-card>
                      </v-window-item>

                      <v-window-item :value="1">

                          <v-card class="pa-5 rounded-0 border border-grey-lighten-2 shadow-sm mb-6 bg-white d-flex align-center justify-space-between" elevation="0" v-if="vacationInfo">
                              <div class="d-flex align-center gap-4">
                                  <v-avatar :color="vacationInfo.color" variant="tonal" rounded="0" size="48"><v-icon>mdi-beach</v-icon></v-avatar>
                                  <div>
                                      <div class="text-[10px] font-weight-black text-uppercase tracking-widest text-grey-darken-2">Período Aquisitivo de Férias</div>
                                      <div class="font-mono text-body-2 font-weight-black mt-1">{{ vacationInfo.start }} a {{ vacationInfo.end }}</div>
                                      <div class="text-[10px] text-grey mt-1">Prazo Limite para Gozo: <strong class="font-mono">{{ vacationInfo.limit }}</strong></div>
                                  </div>
                              </div>
                              <v-chip :color="vacationInfo.color" variant="flat" class="font-weight-black rounded-0 text-uppercase">{{ vacationInfo.status }}</v-chip>
                          </v-card>

                          <v-card class="rounded-0 border border-grey-lighten-2 shadow-sm mb-6 bg-white" elevation="0">
                              <div class="px-5 py-3 border-b bg-grey-lighten-4 text-[11px] font-weight-black text-uppercase text-grey-darken-3 d-flex align-center gap-2">Vínculo Organizacional</div>
                              <div class="pa-5">
                                  <v-row dense class="row-gap">
                                      <v-col cols="12" md="4">
                                          <label class="input-label">Empresa de Registro (CNPJ)</label>
                                          <v-autocomplete v-model="form.company_id" :items="fiscalCompanies" item-title="label" item-value="id" variant="outlined" density="compact" class="ui-field font-weight-bold" clearable hint="Se vazio, usará a Matriz/Padrão" persistent-hint></v-autocomplete>
                                      </v-col>
                                      <v-col cols="12" md="4"><label class="input-label">Tipo de Contrato</label><v-select v-model="form.contract_type" :items="['CLT', 'PJ', 'Estágio', 'Temporário', 'Jovem Aprendiz']" variant="outlined" density="compact" class="ui-field font-weight-bold"></v-select></v-col>
                                      <v-col cols="12" md="4"><label class="input-label">Vincular Login (Acesso Sistema)</label><v-autocomplete v-model="form.user_id" :items="systemUsers" item-title="label" item-value="id" variant="outlined" density="compact" class="ui-field font-weight-bold" clearable hint="Bloqueia o acesso ao ser desligado" persistent-hint></v-autocomplete></v-col>
                                      <v-col cols="12" md="4"><label class="input-label">Data de Admissão</label><v-text-field v-model="form.admission_date" type="date" variant="outlined" density="compact" class="ui-field font-mono font-weight-bold"></v-text-field></v-col>
                                      <v-col cols="12" md="4"><label class="input-label">Gestor / Supervisor Direto</label><v-autocomplete v-model="form.supervisor_id" :items="colaboradores" item-title="nome" item-value="id" variant="outlined" density="compact" class="ui-field" clearable></v-autocomplete></v-col>
                                      <v-col cols="12" md="4"><label class="input-label">Cargo Atual</label><v-text-field v-model="form.cargo" variant="outlined" density="compact" class="ui-field font-weight-black text-grey-darken-4"></v-text-field></v-col>
                                      <v-col cols="12" md="12"><label class="input-label">Departamentos (Tags)</label><v-combobox v-model="form.departments" :items="['Comercial', 'Produção', 'Logística', 'Financeiro', 'Marketing', 'RH', 'Diretoria', 'TI', 'Design']" multiple chips closable-chips variant="outlined" density="compact" class="ui-field font-weight-bold"></v-combobox></v-col>
                                  </v-row>
                              </div>
                          </v-card>

                          <v-card class="rounded-0 border border-grey-lighten-2 shadow-sm bg-white" elevation="0">
                              <div class="px-5 py-3 border-b bg-grey-lighten-4 d-flex justify-space-between align-center">
                                  <div class="text-[11px] font-weight-black text-uppercase text-grey-darken-3 d-flex align-center gap-2">Histórico Profissional (Timeline)</div>
                                  <v-btn color="grey-darken-4" variant="flat" size="small" class="btn-rect font-weight-bold rounded-0" prepend-icon="mdi-plus" @click="showCareerEventModal = true">Registrar Evento</v-btn>
                              </div>

                              <div v-if="!form.career_history || form.career_history.length === 0" class="text-center py-6 opacity-50 bg-grey-lighten-5">
                                  <span class="text-[11px] font-weight-bold text-uppercase">Nenhum evento registrado.</span>
                              </div>

                              <div class="pa-5" v-else>
                                  <div class="custom-timeline">
                                      <div class="timeline-item" v-for="(event, idx) in sortedCareerHistory" :key="idx">
                                          <div class="timeline-marker" :class="`bg-${getEventColor(event.type)}`"><v-icon color="white" size="14">{{ getEventIcon(event.type) }}</v-icon></div>
                                          <div class="timeline-content border border-grey-lighten-2 rounded-0 shadow-sm bg-white pa-3">
                                              <div class="d-flex justify-space-between align-start mb-1">
                                                  <div>
                                                      <span class="text-[10px] font-weight-black text-uppercase px-2 py-1 rounded-0 text-white" :class="`bg-${getEventColor(event.type)}`">{{ event.type }}</span>
                                                      <div class="text-[13px] font-weight-bold text-grey-darken-4 mt-2">{{ event.description }}</div>
                                                  </div>
                                                  <div class="d-flex flex-column align-end">
                                                      <span class="text-[11px] font-weight-bold font-mono opacity-80 text-grey-darken-2">{{ formatDate(event.date) }}</span>
                                                      <v-btn icon size="x-small" variant="text" color="error" class="mt-1 rounded-0" @click="removeCareerEvent(idx)"><v-icon size="14">mdi-delete</v-icon></v-btn>
                                                  </div>
                                              </div>
                                              <div class="d-flex align-center gap-3 mt-2 px-3 py-2 rounded-0 bg-grey-lighten-5 border border-dashed" v-if="event.old_value || event.new_value">
                                                  <span class="text-[11px] font-weight-bold opacity-60 text-decoration-line-through" v-if="event.old_value">{{ event.old_value }}</span>
                                                  <v-icon size="14" color="grey-darken-1" v-if="event.old_value && event.new_value">mdi-arrow-right-bold</v-icon>
                                                  <span class="text-[12px] font-weight-black text-success">{{ event.new_value }}</span>
                                              </div>
                                          </div>
                                      </div>
                                  </div>
                              </div>
                          </v-card>
                      </v-window-item>

                      <v-window-item :value="2">
                          <v-card class="rounded-0 border border-grey-lighten-2 shadow-sm bg-white" elevation="0">
                              <div class="px-5 py-3 border-b bg-grey-darken-4 d-flex justify-space-between align-center">
                                  <div class="text-[11px] font-weight-black text-uppercase text-white d-flex align-center gap-2">Quadro de Horários Semanal</div>
                                  <v-chip color="blue-lighten-1" variant="flat" size="small" class="font-weight-black rounded-0 font-mono">Carga Calculada: {{ calculatedWeeklyHours }}h</v-chip>
                              </div>
                              <div class="pa-5 bg-grey-lighten-5 text-caption font-italic text-grey-darken-2 border-b border-dashed">
                                  * Marque os dias em que o colaborador trabalha e defina os horários de entrada e saída. Este quadro integrará com o login de sistema no futuro.
                              </div>
                              <div class="w-100 overflow-x-auto bg-white">
                                  <table class="w-100 custom-grid-table text-center">
                                      <thead class="bg-grey-lighten-4 border-b">
                                          <tr>
                                              <th class="pa-3 text-uppercase text-[10px] font-weight-black text-left">Dia da Semana</th>
                                              <th class="pa-3 text-uppercase text-[10px] font-weight-black">Entrada 1</th>
                                              <th class="pa-3 text-uppercase text-[10px] font-weight-black">Saída (Almoço)</th>
                                              <th class="pa-3 text-uppercase text-[10px] font-weight-black">Entrada 2</th>
                                              <th class="pa-3 text-uppercase text-[10px] font-weight-black">Saída (Fim)</th>
                                          </tr>
                                      </thead>
                                      <tbody>
                                          <tr v-for="day in weekDays" :key="day.key" class="border-b" :class="!form.work_schedule[day.key].active ? 'opacity-50 bg-grey-lighten-5' : ''">
                                              <td class="pa-3 text-left">
                                                  <v-checkbox v-model="form.work_schedule[day.key].active" :label="day.label" density="compact" hide-details color="primary" class="font-weight-bold text-[12px]"></v-checkbox>
                                              </td>
                                              <td class="pa-3"><input type="time" v-model="form.work_schedule[day.key].in1" class="schedule-input" :disabled="!form.work_schedule[day.key].active"></td>
                                              <td class="pa-3"><input type="time" v-model="form.work_schedule[day.key].out1" class="schedule-input" :disabled="!form.work_schedule[day.key].active"></td>
                                              <td class="pa-3"><input type="time" v-model="form.work_schedule[day.key].in2" class="schedule-input" :disabled="!form.work_schedule[day.key].active"></td>
                                              <td class="pa-3"><input type="time" v-model="form.work_schedule[day.key].out2" class="schedule-input" :disabled="!form.work_schedule[day.key].active"></td>
                                          </tr>
                                      </tbody>
                                  </table>
                              </div>
                          </v-card>
                      </v-window-item>

                      <v-window-item :value="3">
                          <v-row dense class="row-gap">
                              <v-col cols="12">
                                  <v-card class="pa-5 rounded-0 border border-grey-lighten-2 bg-white shadow-sm" elevation="0">
                                      <div class="text-[11px] font-weight-black text-uppercase text-blue-darken-3 mb-4 tracking-widest border-b pb-2 d-flex align-center gap-2"><v-icon size="18">mdi-bank</v-icon> Conta Bancária para Pagamento (Folha)</div>
                                      <v-row dense>
                                          <v-col cols="12" md="3"><label class="input-label">Banco / Instituição</label><v-text-field v-model="form.bank_info.bank" placeholder="Ex: Itaú, Nubank" variant="outlined" density="compact" class="ui-field font-weight-bold"></v-text-field></v-col>
                                          <v-col cols="12" md="2"><label class="input-label">Agência</label><v-text-field v-model="form.bank_info.agency" variant="outlined" density="compact" class="ui-field font-mono"></v-text-field></v-col>
                                          <v-col cols="12" md="2"><label class="input-label">Conta c/ Dígito</label><v-text-field v-model="form.bank_info.account" variant="outlined" density="compact" class="ui-field font-mono font-weight-bold"></v-text-field></v-col>
                                          <v-col cols="12" md="2"><label class="input-label">Tipo de Conta</label><v-select v-model="form.bank_info.type" :items="['Corrente', 'Poupança', 'Salário']" variant="outlined" density="compact" class="ui-field"></v-select></v-col>
                                          <v-col cols="12" md="3"><label class="input-label">Chave PIX</label><v-text-field v-model="form.bank_info.pix" variant="outlined" density="compact" class="ui-field font-mono text-teal-darken-3 font-weight-bold"></v-text-field></v-col>
                                      </v-row>
                                  </v-card>
                              </v-col>

                              <v-col cols="12" md="4">
                                  <v-card class="pa-5 rounded-0 border border-grey-lighten-2 bg-white h-100 shadow-sm" elevation="0">
                                      <div class="text-[11px] font-weight-black text-uppercase text-grey-darken-3 mb-4 tracking-widest border-b pb-2">Base de Remuneração Mensal</div>
                                      <label class="input-label">Salário Base Bruto</label>
                                      <v-text-field v-model.number="form.salary_base" type="number" variant="outlined" density="compact" class="ui-field font-mono font-weight-black text-grey-darken-4 mb-3"></v-text-field>

                                      <label class="input-label">Adicionais Fixos (Insalubridade, Prêmios)</label>
                                      <v-text-field v-model.number="form.salary_additional" type="number" variant="outlined" density="compact" class="ui-field font-mono font-weight-bold mb-3"></v-text-field>

                                      <label class="input-label">Carga Tributária da Folha (%)</label>
                                      <v-text-field v-model.number="form.tax_percentage" type="number" variant="outlined" density="compact" class="ui-field font-mono font-weight-bold" :hint="form.contract_type === 'CLT' ? 'Geralmente 40% a 70%' : 'PJ: 0%'" persistent-hint></v-text-field>
                                  </v-card>
                              </v-col>

                              <v-col cols="12" md="8">
                                  <div class="d-flex flex-column gap-3 h-100">
                                      <div class="d-flex gap-3">
                                          <v-card class="pa-4 rounded-0 border border-grey-darken-3 bg-grey-darken-4 text-white flex-grow-1 shadow-sm" elevation="0">
                                              <div class="text-[10px] font-weight-bold text-uppercase opacity-70 mb-1 d-flex align-center justify-space-between">Custo Mensal (Empresa) <v-icon size="14">mdi-calendar-month</v-icon></div>
                                              <div class="text-h5 font-weight-black font-mono mt-1 text-green-lighten-2">{{ formatCurrency(monthlyCost) }}</div>
                                          </v-card>
                                          <v-card class="pa-4 rounded-0 border border-orange-darken-3 bg-orange-darken-4 text-white flex-grow-1 shadow-sm" elevation="0">
                                              <div class="text-[10px] font-weight-bold text-uppercase opacity-70 mb-1 d-flex align-center justify-space-between">Provisão Anual Real <v-icon size="14">mdi-calendar-sync</v-icon></div>
                                              <div class="text-h5 font-weight-black font-mono mt-1">{{ formatCurrency(yearlyCost) }}</div>
                                              <div class="text-[9px] mt-1 opacity-60 font-weight-bold" v-if="form.contract_type === 'CLT'">Inclui 13º e Férias (+1/3)</div>
                                          </v-card>
                                      </div>

                                      <v-card class="pa-5 rounded-0 border border-grey-lighten-2 bg-white flex-grow-1 shadow-sm" elevation="0">
                                          <div class="d-flex align-center justify-space-between mb-4 border-b pb-2">
                                              <div class="text-[11px] font-weight-black text-uppercase text-grey-darken-3 tracking-widest">Composição do Custo Mensal</div>
                                              <div class="text-[10px] font-weight-bold bg-grey-lighten-4 px-2 py-1 border rounded-0 text-uppercase">Proj. 5 Anos: <span class="font-mono text-error">{{ formatCurrency(yearlyCost * 5) }}</span></div>
                                          </div>

                                          <div class="d-flex align-center gap-4 w-100 justify-space-around">
                                              <div class="d-flex flex-column align-center text-center">
                                                  <div class="font-mono text-subtitle-1 font-weight-black text-blue-darken-3 mb-1">{{ formatCurrency(basePlusAdic) }}</div>
                                                  <span class="text-[10px] font-weight-bold text-uppercase text-grey-darken-2 border-t pt-1 w-100">Salário+Adic</span>
                                              </div>
                                              <v-icon color="grey-lighten-1" size="20">mdi-plus</v-icon>

                                              <div class="d-flex flex-column align-center text-center">
                                                  <div class="font-mono text-subtitle-1 font-weight-black text-red-darken-3 mb-1">{{ formatCurrency(taxCost) }}</div>
                                                  <span class="text-[10px] font-weight-bold text-uppercase text-grey-darken-2 border-t pt-1 w-100">Impostos (RH)</span>
                                              </div>
                                              <v-icon color="grey-lighten-1" size="20">mdi-plus</v-icon>

                                              <div class="d-flex flex-column align-center text-center">
                                                  <div class="font-mono text-subtitle-1 font-weight-black text-teal-darken-3 mb-1">{{ formatCurrency(totalBenefitsValue) }}</div>
                                                  <span class="text-[10px] font-weight-bold text-uppercase text-grey-darken-2 border-t pt-1 w-100">Benefícios Extras</span>
                                              </div>
                                          </div>
                                      </v-card>
                                  </div>
                              </v-col>
                          </v-row>
                      </v-window-item>

                      <v-window-item :value="4">
                          <v-card class="rounded-0 border border-grey-lighten-2 shadow-sm bg-white mb-6" elevation="0">
                              <div class="px-5 py-3 border-b bg-grey-lighten-4 d-flex justify-space-between align-center">
                                  <div class="text-[11px] font-weight-black text-uppercase text-grey-darken-3 d-flex align-center gap-2">Pacote de Benefícios Ativos</div>
                                  <v-btn color="grey-darken-4" variant="flat" size="small" class="btn-rect font-weight-bold rounded-0" prepend-icon="mdi-plus" @click="showBenefitModal = true">Conceder</v-btn>
                              </div>
                              <div class="w-100 overflow-x-auto">
                                  <table class="w-100 custom-grid-table" v-if="form.benefits?.length > 0">
                                      <thead class="bg-grey-lighten-5 border-b">
                                          <tr>
                                              <th class="text-left text-uppercase font-weight-black text-[10px] text-grey-darken-2 pa-3">Benefício</th>
                                              <th class="text-left text-uppercase font-weight-black text-[10px] text-grey-darken-2 pa-3">Fornecedor/Fonte</th>
                                              <th class="text-right text-uppercase font-weight-black text-[10px] text-grey-darken-2 pa-3">Custo Mensal (Empresa)</th>
                                              <th class="text-center text-uppercase font-weight-black text-[10px] text-grey-darken-2 pa-3">Ação</th>
                                          </tr>
                                      </thead>
                                      <tbody>
                                          <tr v-for="(ben, idx) in form.benefits" :key="idx" class="border-b hover-row bg-white">
                                              <td class="pa-3 font-weight-bold text-[12px] text-grey-darken-4 d-flex align-center gap-2"><v-icon size="16" color="teal-darken-3">mdi-star-four-points</v-icon> {{ ben.name }}</td>
                                              <td class="pa-3 text-[12px] opacity-80">{{ ben.provider || 'Interno' }}</td>
                                              <td class="pa-3 text-right font-mono font-weight-black text-teal-darken-3">{{ formatCurrency(ben.value) }}</td>
                                              <td class="pa-3 text-center"><v-btn icon size="x-small" variant="text" color="error" class="rounded-0" @click="removeBenefit(idx)"><v-icon size="16">mdi-delete</v-icon></v-btn></td>
                                          </tr>
                                      </tbody>
                                  </table>
                                  <div v-else class="pa-6 text-center text-[11px] font-weight-bold text-grey opacity-70 text-uppercase">Nenhum benefício ativo.</div>
                              </div>
                          </v-card>

                          <v-card class="rounded-0 border border-grey-lighten-2 shadow-sm bg-white" elevation="0">
                              <div class="px-5 py-3 border-b bg-grey-lighten-4 d-flex justify-space-between align-center">
                                  <div class="text-[11px] font-weight-black text-uppercase text-grey-darken-3 d-flex align-center gap-2">Controle de Patrimônio / EPIs em Posse</div>
                                  <v-btn color="blue-darken-3" variant="flat" size="small" class="btn-rect font-weight-bold rounded-0" prepend-icon="mdi-plus" @click="showEquipmentModal = true">Entregar Item</v-btn>
                              </div>
                              <div class="w-100 overflow-x-auto">
                                  <table class="w-100 custom-grid-table" v-if="form.equipments?.length > 0">
                                      <thead class="bg-blue-lighten-5 border-b">
                                          <tr>
                                              <th class="text-left text-uppercase font-weight-black text-[10px] text-blue-darken-3 pa-3">Item Entregue</th>
                                              <th class="text-left text-uppercase font-weight-black text-[10px] text-blue-darken-3 pa-3">Série/Detalhe</th>
                                              <th class="text-center text-uppercase font-weight-black text-[10px] text-blue-darken-3 pa-3">Data Entrega</th>
                                              <th class="text-center text-uppercase font-weight-black text-[10px] text-blue-darken-3 pa-3">Status</th>
                                              <th class="text-center text-uppercase font-weight-black text-[10px] text-blue-darken-3 pa-3">Ação</th>
                                          </tr>
                                      </thead>
                                      <tbody>
                                          <tr v-for="(eq, idx) in form.equipments" :key="idx" class="border-b hover-row bg-white">
                                              <td class="pa-3 font-weight-bold text-[12px] text-grey-darken-4 d-flex align-center gap-2"><v-icon size="16" color="blue-darken-2">mdi-laptop</v-icon> {{ eq.name }}</td>
                                              <td class="pa-3 text-[11px] font-mono text-grey-darken-2">{{ eq.serial_number || 'N/A' }}</td>
                                              <td class="pa-3 text-center font-mono text-[12px]">{{ formatDate(eq.delivery_date) }}</td>
                                              <td class="pa-3 text-center">
                                                  <v-chip size="x-small" :color="eq.status === 'Devolvido' ? 'success' : 'warning'" variant="flat" class="font-weight-bold rounded-2px">{{ eq.status }}</v-chip>
                                              </td>
                                              <td class="pa-3 text-center">
                                                  <v-btn v-if="eq.status !== 'Devolvido'" size="x-small" variant="tonal" color="success" class="rounded-2px text-[10px] font-weight-bold px-2 mr-1" @click="returnEquipment(idx)">Devolver</v-btn>
                                                  <v-btn icon size="x-small" variant="text" color="error" class="rounded-0" @click="removeEquipment(idx)"><v-icon size="16">mdi-delete</v-icon></v-btn>
                                              </td>
                                          </tr>
                                      </tbody>
                                  </table>
                                  <div v-else class="pa-6 text-center text-[11px] font-weight-bold text-grey opacity-70 text-uppercase">Nenhum equipamento/EPI em posse.</div>
                              </div>
                          </v-card>
                      </v-window-item>

                      <v-window-item :value="5">
                          <v-card class="rounded-0 border border-grey-lighten-2 shadow-sm bg-white" elevation="0">
                              <div class="px-5 py-3 border-b bg-grey-lighten-4 d-flex justify-space-between align-center">
                                  <div class="text-[11px] font-weight-black text-uppercase text-grey-darken-3 d-flex align-center gap-2">Organização de Arquivos do RH</div>
                                  <v-btn color="grey-darken-4" variant="flat" class="btn-rect font-weight-bold rounded-0" size="small" prepend-icon="mdi-upload" @click="showDocModal = true">Arquivar Documento</v-btn>
                              </div>

                              <v-expansion-panels variant="accordion" class="custom-expansion rounded-0">
                                  <v-expansion-panel v-for="cat in docCategories" :key="cat" class="border-b bg-white rounded-0">
                                      <v-expansion-panel-title class="py-3 px-5">
                                          <div class="d-flex align-center gap-3 w-100">
                                              <v-icon color="grey-darken-3" size="20">mdi-folder</v-icon>
                                              <span class="font-weight-bold text-[12px] text-uppercase text-grey-darken-3">{{ cat }}</span>
                                              <span class="ml-auto mr-4 font-mono text-[10px] font-weight-black bg-grey-lighten-3 px-2 py-1 rounded-0 border">{{ getDocsByCategory(cat).length }}</span>
                                          </div>
                                      </v-expansion-panel-title>
                                      <v-expansion-panel-text class="bg-grey-lighten-5 pt-3 pb-3 px-5 border-t border-dashed">
                                          <div v-if="getDocsByCategory(cat).length === 0" class="text-center py-2 opacity-50 text-[10px] font-weight-bold font-italic text-uppercase">Pasta vazia.</div>
                                          <v-row dense v-else>
                                              <v-col cols="12" md="6" lg="4" v-for="doc in getDocsByCategory(cat)" :key="doc.url">
                                                  <v-card variant="outlined" class="pa-2 border-grey-lighten-2 bg-white d-flex align-center justify-space-between rounded-0 shadow-sm hover-row cursor-pointer" @click="openDoc(doc.url)">
                                                      <div class="d-flex align-center gap-3 overflow-hidden">
                                                          <v-icon :color="doc.url.includes('.pdf') ? 'red-darken-3' : 'blue-grey-darken-2'" size="28">{{ doc.url.includes('.pdf') ? 'mdi-file-pdf-box' : 'mdi-image-outline' }}</v-icon>
                                                          <div class="overflow-hidden">
                                                              <div class="text-[11px] font-weight-black text-truncate text-grey-darken-4" :title="doc.name">{{ doc.name }}</div>
                                                              <div class="text-[9px] opacity-70 mt-0 font-mono">{{ formatDate(doc.uploaded_at) }}</div>
                                                          </div>
                                                      </div>
                                                      <v-btn icon size="x-small" variant="text" color="error" class="rounded-0" @click.stop="removeDocument(doc)"><v-icon size="14">mdi-delete</v-icon></v-btn>
                                                  </v-card>
                                              </v-col>
                                          </v-row>
                                      </v-expansion-panel-text>
                                  </v-expansion-panel>
                              </v-expansion-panels>
                          </v-card>
                      </v-window-item>

                      <v-window-item :value="6">
                          <v-row dense class="row-gap h-100">
                              <v-col cols="12" md="4">
                                  <v-card class="pa-5 rounded-0 border border-grey-lighten-2 bg-white h-100 shadow-sm" elevation="0">
                                      <div class="text-[11px] font-weight-black text-uppercase text-grey-darken-3 mb-4 tracking-widest border-b pb-2 d-flex align-center gap-2">
                                          <v-icon size="18">mdi-text-box-edit-outline</v-icon> Parâmetros do Desligamento
                                      </div>

                                      <div class="bg-grey-lighten-5 border border-dashed border-grey-lighten-2 rounded-0 pa-3 mb-4">
                                          <div class="text-[9px] font-weight-black text-uppercase text-grey-darken-2 mb-2">Bases do Dossiê p/ Cálculo</div>
                                          <div class="d-flex justify-space-between align-center mb-1 text-[11px]">
                                              <span class="font-weight-bold opacity-70">Salário c/ Adicionais:</span>
                                              <span class="font-weight-black font-mono text-blue-darken-4">{{ formatCurrency(basePlusAdic) }}</span>
                                          </div>
                                          <div class="d-flex justify-space-between align-center mb-1 text-[11px]">
                                              <span class="font-weight-bold opacity-70">Data de Admissão:</span>
                                              <span class="font-weight-black font-mono">{{ formatDate(form.admission_date) || 'NÃO DEFINIDA' }}</span>
                                          </div>
                                          <div class="d-flex justify-space-between align-center text-[11px]">
                                              <span class="font-weight-bold opacity-70">Dependentes (IRRF):</span>
                                              <span class="font-weight-black font-mono">{{ form.dependents?.length || 0 }}</span>
                                          </div>
                                      </div>

                                      <label class="input-label">Salário Base (Sobrescrever) - Opcional</label>
                                      <v-text-field v-model.number="rescissionSim.manualBaseSalary" type="number" variant="outlined" density="compact" class="ui-field font-mono font-weight-bold mb-3" hint="Se vazio, usará a base de remuneração do dossiê" persistent-hint></v-text-field>

                                      <label class="input-label mt-2">Data do Desligamento</label>
                                      <v-text-field v-model="rescissionSim.endDate" type="date" variant="outlined" density="compact" class="ui-field font-mono font-weight-bold mb-3"></v-text-field>

                                      <label class="input-label">Motivo da Rescisão</label>
                                      <v-select v-model="rescissionSim.reason" :items="['Sem Justa Causa', 'Pedido de Demissão', 'Acordo (Reforma Trab.)', 'Justa Causa']" variant="outlined" density="compact" class="ui-field font-weight-bold mb-3"></v-select>

                                      <label class="input-label">Aviso Prévio (Lei 12.506)</label>
                                      <v-select v-model="rescissionSim.noticeType" :items="['Indenizado', 'Trabalhado', 'Não Cumprido (Descontado)']" variant="outlined" density="compact" class="ui-field font-weight-bold mb-3" :disabled="rescissionSim.reason === 'Justa Causa'"></v-select>

                                      <v-row dense>
                                          <v-col cols="6">
                                              <label class="input-label">Férias Vencidas (Períodos)</label>
                                              <v-text-field v-model.number="rescissionSim.vacationOverduePeriods" type="number" variant="outlined" density="compact" class="ui-field font-mono font-weight-bold mb-3" hint="Ex: 1 ou 2"></v-text-field>
                                          </v-col>
                                          <v-col cols="6">
                                              <label class="input-label">Saldo FGTS Caixa (R$)</label>
                                              <v-text-field v-model.number="rescissionSim.fgtsBalance" type="number" variant="outlined" density="compact" class="ui-field font-mono font-weight-bold text-success mb-3"></v-text-field>
                                          </v-col>
                                      </v-row>

                                      <v-btn block color="grey-darken-4" variant="flat" class="btn-rect font-weight-black mt-2" height="42" @click="calculateRescission">
                                          <v-icon start>mdi-calculator</v-icon> GERAR TRCT EXATO
                                      </v-btn>
                                  </v-card>
                              </v-col>

                              <v-col cols="12" md="8">
                                  <v-card class="rounded-0 border border-grey-lighten-2 shadow-sm bg-white h-100 d-flex flex-column" elevation="0">
                                      <div class="px-5 py-3 border-b bg-grey-darken-4 d-flex justify-space-between align-center flex-shrink-0">
                                          <div class="text-[11px] font-weight-black text-uppercase text-white d-flex align-center gap-2">Extrato Rescisório Consolidado (2026)</div>
                                      </div>

                                      <div class="flex-grow-1 overflow-y-auto bg-grey-lighten-5 relative">
                                          <div v-if="!rescissionSim.simulated" class="absolute inset-0 d-flex flex-column align-center justify-center opacity-40">
                                              <v-icon size="48" class="mb-2">mdi-receipt-text-outline</v-icon>
                                              <span class="text-[11px] font-weight-bold text-uppercase tracking-widest">Preencha e Gere o Cálculo</span>
                                          </div>
                                          <div v-else>
                                              <table class="w-100 custom-grid-table border-b">
                                                  <thead class="bg-grey-lighten-4 border-b">
                                                      <tr>
                                                          <th class="text-left text-uppercase font-weight-black text-[10px] text-grey-darken-2 pa-3 border-r">Verba Rescisória (Proventos e Descontos)</th>
                                                          <th class="text-right text-uppercase font-weight-black text-[10px] text-grey-darken-2 pa-3">Valor (R$)</th>
                                                      </tr>
                                                  </thead>
                                                  <tbody class="bg-white">
                                                      <tr class="border-b">
                                                          <td class="pa-3 text-[12px] font-weight-bold border-r">Saldo de Salário ({{ rescissionSim.meta.workedDays }} dias)</td>
                                                          <td class="pa-3 text-right font-mono text-[13px] font-weight-bold">{{ formatCurrency(rescissionSim.results.salaryBalance) }}</td>
                                                      </tr>
                                                      <tr class="border-b" v-if="rescissionSim.results.noticePeriodVal !== 0">
                                                          <td class="pa-3 text-[12px] font-weight-bold border-r" :class="rescissionSim.results.noticePeriodVal < 0 ? 'text-error' : ''">Aviso Prévio ({{ rescissionSim.meta.noticeDays }} dias)</td>
                                                          <td class="pa-3 text-right font-mono text-[13px] font-weight-bold" :class="rescissionSim.results.noticePeriodVal < 0 ? 'text-error' : ''">{{ formatCurrency(rescissionSim.results.noticePeriodVal) }}</td>
                                                      </tr>
                                                      <tr class="border-b">
                                                          <td class="pa-3 text-[12px] font-weight-bold border-r">13º Salário Proporcional ({{ rescissionSim.meta.months13 }}/12)</td>
                                                          <td class="pa-3 text-right font-mono text-[13px] font-weight-bold">{{ formatCurrency(rescissionSim.results.thirteenth) }}</td>
                                                      </tr>
                                                      <tr class="border-b" v-if="rescissionSim.results.vacationOverdue > 0">
                                                          <td class="pa-3 text-[12px] font-weight-bold border-r">Férias Vencidas + 1/3 ({{ rescissionSim.vacationOverduePeriods }} período(s))</td>
                                                          <td class="pa-3 text-right font-mono text-[13px] font-weight-bold">{{ formatCurrency(rescissionSim.results.vacationOverdue) }}</td>
                                                      </tr>
                                                      <tr class="border-b">
                                                          <td class="pa-3 text-[12px] font-weight-bold border-r">Férias Proporcionais + 1/3 ({{ rescissionSim.meta.monthsVacation }}/12)</td>
                                                          <td class="pa-3 text-right font-mono text-[13px] font-weight-bold">{{ formatCurrency(rescissionSim.results.vacationProportional) }}</td>
                                                      </tr>
                                                      <tr class="bg-grey-lighten-4 border-b border-t-thick">
                                                          <td class="pa-3 text-[12px] font-weight-black border-r text-uppercase text-grey-darken-4">Total Bruto TRCT</td>
                                                          <td class="pa-3 text-right font-mono text-[14px] font-weight-black text-grey-darken-4">{{ formatCurrency(rescissionSim.results.totalTrct) }}</td>
                                                      </tr>
                                                      <tr class="border-b bg-red-lighten-5">
                                                          <td class="pa-3 text-[12px] font-weight-bold border-r text-red-darken-3">
                                                              Deduções Estimadas (INSS/IRRF Tabela Prog.)
                                                              <span class="text-[9px] d-block opacity-70 mt-1">Cálculo com {{ form.dependents?.length || 0 }} dependente(s) na dedução.</span>
                                                          </td>
                                                          <td class="pa-3 text-right font-mono text-[13px] font-weight-bold text-red-darken-3">-{{ formatCurrency(rescissionSim.results.discounts) }}</td>
                                                      </tr>
                                                  </tbody>
                                              </table>

                                              <div class="pa-4 border-b bg-white d-flex justify-space-between align-center">
                                                  <div class="text-[12px] font-weight-black text-uppercase text-grey-darken-2">Líquido a Pagar do Colaborador</div>
                                                  <div class="text-h5 font-weight-black font-mono text-blue-darken-4">{{ formatCurrency(rescissionSim.results.totalTrct - rescissionSim.results.discounts) }}</div>
                                              </div>

                                              <div class="pa-4 bg-orange-lighten-5 d-flex justify-space-between align-center border-t border-orange-lighten-3 mt-2" v-if="rescissionSim.results.fgtsPenalty > 0">
                                                  <div>
                                                      <div class="text-[12px] font-weight-black text-uppercase text-orange-darken-4">Multa Rescisória FGTS (GRRF)</div>
                                                      <div class="text-[9px] opacity-80 text-orange-darken-4 mt-1 font-weight-bold">Pagamento em guia separada DAE. Base: R$ {{ formatCurrency(rescissionSim.fgtsBalance) }}</div>
                                                  </div>
                                                  <div class="text-h6 font-weight-black font-mono text-orange-darken-4">{{ formatCurrency(rescissionSim.results.fgtsPenalty) }}</div>
                                              </div>
                                          </div>
                                      </div>
                                  </v-card>
                              </v-col>
                          </v-row>
                      </v-window-item>

                  </v-window>
              </v-form>
          </div>
      </div>

    </v-card>

    <v-dialog v-model="showDependentModal" max-width="400">
        <v-card class="pa-5 rounded-0 border border-grey-darken-1 bg-white shadow-md">
            <h3 class="text-[13px] font-weight-black mb-4 text-uppercase tracking-widest text-grey-darken-3 border-b pb-2">Adicionar Dependente</h3>
            <label class="input-label">Nome Completo</label>
            <v-text-field v-model="newDependent.name" variant="outlined" density="compact" class="ui-field font-weight-bold mb-2"></v-text-field>
            <label class="input-label">Grau de Parentesco</label>
            <v-select v-model="newDependent.relation" :items="['Filho(a)', 'Cônjuge', 'Pai/Mãe', 'Enteado(a)', 'Outros']" variant="outlined" density="compact" class="ui-field font-weight-bold mb-2"></v-select>
            <label class="input-label">Data de Nascimento</label>
            <v-text-field v-model="newDependent.birth_date" type="date" variant="outlined" density="compact" class="ui-field font-weight-bold font-mono mb-4"></v-text-field>
            <div class="d-flex justify-end gap-2">
                <v-btn variant="outlined" color="grey-darken-2" class="btn-rect font-weight-bold bg-white" @click="showDependentModal = false">Cancelar</v-btn>
                <v-btn color="grey-darken-4" variant="flat" class="btn-rect font-weight-black px-6" @click="addDependent">Adicionar</v-btn>
            </div>
        </v-card>
    </v-dialog>

    <v-dialog v-model="showEquipmentModal" max-width="400">
        <v-card class="pa-5 rounded-0 border border-grey-darken-1 bg-white shadow-md">
            <h3 class="text-[13px] font-weight-black mb-4 text-uppercase tracking-widest text-blue-darken-3 border-b pb-2">Entregar Patrimônio</h3>
            <label class="input-label">Item / Equipamento</label>
            <v-select v-model="newEquipment.name" :items="['Notebook', 'Smartphone Corporativo', 'Monitor', 'Uniforme (Kit)', 'EPI (Bota/Capacete)', 'Veículo', 'Chaves', 'Outros']" variant="outlined" density="compact" class="ui-field font-weight-bold mb-2"></v-select>
            <label class="input-label">Nº de Série / Placa / Detalhe</label>
            <v-text-field v-model="newEquipment.serial_number" placeholder="Ex: NTB-001, GOL-4822" variant="outlined" density="compact" class="ui-field font-mono mb-2"></v-text-field>
            <label class="input-label">Data da Entrega (Termo)</label>
            <v-text-field v-model="newEquipment.delivery_date" type="date" variant="outlined" density="compact" class="ui-field font-weight-bold font-mono mb-4"></v-text-field>
            <div class="d-flex justify-end gap-2">
                <v-btn variant="outlined" color="grey-darken-2" class="btn-rect font-weight-bold bg-white" @click="showEquipmentModal = false">Cancelar</v-btn>
                <v-btn color="blue-darken-3" variant="flat" class="btn-rect font-weight-black px-6" @click="addEquipment">Registrar</v-btn>
            </div>
        </v-card>
    </v-dialog>

    <v-dialog v-model="showCareerEventModal" max-width="450">
        <v-card class="pa-5 rounded-0 border border-grey-darken-1 bg-white shadow-md">
            <h3 class="text-[13px] font-weight-black mb-4 text-uppercase tracking-widest text-grey-darken-3 border-b pb-2">Registrar Evento RH</h3>
            <label class="input-label">Tipo de Evento</label>
            <v-select v-model="newEvent.type" :items="['Admissão', 'Promoção', 'Mudança de Departamento', 'Ajuste Salarial', 'Férias', 'Advertência', 'Licença', 'Outros']" variant="outlined" density="compact" class="ui-field font-weight-bold mb-2"></v-select>
            <label class="input-label">Data da Ocorrência</label>
            <v-text-field v-model="newEvent.date" type="date" variant="outlined" density="compact" class="ui-field font-weight-bold font-mono mb-2"></v-text-field>
            <label class="input-label">Descrição Breve</label>
            <v-text-field v-model="newEvent.description" placeholder="Ex: Promovido a Gerente" variant="outlined" density="compact" class="ui-field font-weight-bold mb-2"></v-text-field>
            <v-row dense class="mb-4">
                <v-col cols="6"><label class="input-label">Valor/Cargo Antigo</label><v-text-field v-model="newEvent.old_value" variant="outlined" density="compact" class="ui-field text-[12px] font-weight-bold"></v-text-field></v-col>
                <v-col cols="6"><label class="input-label">Valor/Cargo Novo</label><v-text-field v-model="newEvent.new_value" variant="outlined" density="compact" class="ui-field text-[12px] font-weight-bold"></v-text-field></v-col>
            </v-row>
            <div class="d-flex justify-end gap-2">
                <v-btn variant="outlined" color="grey-darken-2" class="btn-rect font-weight-bold bg-white" @click="showCareerEventModal = false">Cancelar</v-btn>
                <v-btn color="grey-darken-4" variant="flat" class="btn-rect font-weight-black px-6" @click="addCareerEvent">Gravar</v-btn>
            </div>
        </v-card>
    </v-dialog>

    <v-dialog v-model="showBenefitModal" max-width="400">
        <v-card class="pa-5 rounded-0 border border-grey-darken-1 bg-white shadow-md">
            <h3 class="text-[13px] font-weight-black mb-4 text-uppercase tracking-widest text-grey-darken-3 border-b pb-2">Concessão de Benefício</h3>
            <v-radio-group v-model="benefitMode" inline color="grey-darken-4" class="mb-2 font-weight-bold text-[12px]" hide-details>
                <v-radio label="Padrão" value="global"></v-radio>
                <v-radio label="Customizado" value="custom"></v-radio>
            </v-radio-group>
            <label class="input-label mt-2">Nome do Benefício</label>
            <v-autocomplete v-if="benefitMode === 'global'" v-model="newBenefit.name" :items="globalBenefits" variant="outlined" density="compact" class="ui-field font-weight-bold mb-2"></v-autocomplete>
            <v-text-field v-else v-model="newBenefit.name" variant="outlined" density="compact" class="ui-field font-weight-bold mb-2"></v-text-field>
            <label class="input-label">Fornecedor / Fonte</label>
            <v-text-field v-model="newBenefit.provider" placeholder="Ex: Unimed" variant="outlined" density="compact" class="ui-field mb-2"></v-text-field>
            <label class="input-label">Custo Mensal (Empresa)</label>
            <v-text-field v-model.number="newBenefit.value" type="number" prefix="R$" variant="outlined" density="compact" class="ui-field font-mono font-weight-bold mb-4"></v-text-field>
            <div class="d-flex justify-end gap-2">
                <v-btn variant="outlined" color="grey-darken-2" class="btn-rect font-weight-bold bg-white" @click="showBenefitModal = false">Cancelar</v-btn>
                <v-btn color="grey-darken-4" variant="flat" class="btn-rect font-weight-black px-6" @click="addBenefit">Conceder</v-btn>
            </div>
        </v-card>
    </v-dialog>

    <v-dialog v-model="showDocModal" max-width="400">
        <v-card class="pa-5 rounded-0 border border-grey-darken-1 bg-white shadow-md">
            <h3 class="text-[13px] font-weight-black mb-4 text-uppercase tracking-widest text-grey-darken-3 border-b pb-2">Upar Documento</h3>
            <label class="input-label">Categoria (Pasta de Destino)</label>
            <v-select v-model="newDocCategory" :items="docCategories" variant="outlined" density="compact" class="ui-field font-weight-bold mb-2"></v-select>
            <label class="input-label">Arquivo (PDF/Imagem)</label>
            <v-file-input v-model="newDocFile" variant="outlined" density="compact" prepend-inner-icon="mdi-paperclip" prepend-icon="" class="ui-field font-weight-bold mb-2"></v-file-input>
            <label class="input-label">Nome Personalizado (Opcional)</label>
            <v-text-field v-model="newDocCustomName" placeholder="Se vazio, usa original" variant="outlined" density="compact" class="ui-field mb-4"></v-text-field>
            <div class="d-flex justify-end gap-2">
                <v-btn variant="outlined" color="grey-darken-2" class="btn-rect font-weight-bold bg-white" @click="showDocModal = false">Cancelar</v-btn>
                <v-btn color="grey-darken-4" variant="flat" class="btn-rect font-weight-black px-6" :loading="uploadingDoc" @click="executeDocUpload">Arquivar</v-btn>
            </div>
        </v-card>
    </v-dialog>

  </v-dialog>
</template>

<script setup lang="ts">
import { ref, watch, computed, reactive } from 'vue';
import { supabase } from '@/api/supabase';
import { useAppStore } from '@/stores/app';
import { vMaska } from "maska/vue";
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import { format } from 'date-fns';

const props = defineProps<{ show: boolean; employee: any }>();
const emit = defineEmits(['update:show', 'close', 'refresh']);
const appStore = useAppStore();

const activeTab = ref(0);
const isSaving = ref(false);
const formRef = ref<any>(null);

const tabTitles = ['Ficha Cadastral Central', 'Perfil Profissional', 'Jornada de Trabalho Automática', 'Visão de Custos e Contas', 'Benefícios e Equipamentos', 'Cofre de Arquivos', 'Simulador Rescisório (CLT)'];
const tabIcons = ['mdi-card-account-details', 'mdi-briefcase-account', 'mdi-clock-check-outline', 'mdi-cash-multiple', 'mdi-hand-heart', 'mdi-folder-account', 'mdi-calculator-variant'];
const docCategories = ['Identificação (RG/CPF/CNH)', 'Contrato de Trabalho', 'Atestados Médicos', 'Comprovantes de Residência', 'Certificações / Cursos', 'Documentos Dependentes', 'Outros'];
const globalBenefits = ['Vale Transporte (VT)', 'Vale Refeição (VR)', 'Vale Alimentação (VA)', 'Plano de Saúde', 'Plano Odontológico', 'Gympass', 'Auxílio Creche'];

const colaboradores = ref<any[]>([]);
const fiscalCompanies = ref<any[]>([]);
const systemUsers = ref<any[]>([]);

const isNew = computed(() => !props.employee?.id);
const isExportingPdf = ref(false);

const weekDays = [
    { key: 'mon', label: 'Segunda-feira' }, { key: 'tue', label: 'Terça-feira' }, { key: 'wed', label: 'Quarta-feira' },
    { key: 'thu', label: 'Quinta-feira' }, { key: 'fri', label: 'Sexta-feira' }, { key: 'sat', label: 'Sábado' }, { key: 'sun', label: 'Domingo' }
];

const defaultSchedule = {
    mon: { active: true, in1: '08:00', out1: '12:00', in2: '13:00', out2: '17:48' },
    tue: { active: true, in1: '08:00', out1: '12:00', in2: '13:00', out2: '17:48' },
    wed: { active: true, in1: '08:00', out1: '12:00', in2: '13:00', out2: '17:48' },
    thu: { active: true, in1: '08:00', out1: '12:00', in2: '13:00', out2: '17:48' },
    fri: { active: true, in1: '08:00', out1: '12:00', in2: '13:00', out2: '17:48' },
    sat: { active: false, in1: '08:00', out1: '12:00', in2: '', out2: '' },
    sun: { active: false, in1: '', out1: '', in2: '', out2: '' },
};

// ESTADO DO FORMULÁRIO (PRÉ-POPULADO PARA EVITAR UNDEFINED)
const getDefaultForm = () => ({
    nome: '', cargo: '', cpf: '', rg: '', birth_date: '', email: '', celular: '', telefone: '', supervisor_id: null,
    marital_status: 'Solteiro(a)', contract_type: 'CLT', admission_date: new Date().toISOString().split('T')[0],
    departments: [], salary_base: 0, salary_additional: 0, tax_percentage: 40, company_id: null,
    emergency_contact: { name: '', relation: '', phone: '' },
    bank_info: { bank: '', agency: '', account: '', type: 'Corrente', pix: '' },
    work_schedule: JSON.parse(JSON.stringify(defaultSchedule)),
    avatar_url: null, dependents: [], career_history: [], benefits: [], documents: [], equipments: []
});

const form = reactive<any>(getDefaultForm());

// Modais Inlines
const showDependentModal = ref(false);
const newDependent = reactive({ name: '', relation: 'Filho(a)', birth_date: '' });

const showEquipmentModal = ref(false);
const newEquipment = reactive({ name: 'Notebook', serial_number: '', delivery_date: new Date().toISOString().split('T')[0] });

const showCareerEventModal = ref(false);
const newEvent = reactive({ type: 'Promoção', date: new Date().toISOString().split('T')[0], description: '', old_value: '', new_value: '' });

const showBenefitModal = ref(false);
const benefitMode = ref('global');
const newBenefit = reactive({ name: '', provider: '', value: 0 });

const showDocModal = ref(false);
const newDocCategory = ref(docCategories[0]);
const newDocFile = ref<File | null>(null);
const newDocCustomName = ref('');

const uploadingAvatar = ref(false);
const uploadingDoc = ref(false);

// SIMULADOR DE RESCISÃO (2026 CLT) - EXATO
const rescissionSim = reactive({
    manualBaseSalary: null as number | null,
    endDate: new Date().toISOString().split('T')[0],
    reason: 'Sem Justa Causa',
    noticeType: 'Indenizado',
    vacationOverdueDays: 0,
    vacationOverduePeriods: 0,
    fgtsBalance: 0,
    simulated: false,
    meta: { workedDays: 0, noticeDays: 0, months13: 0, monthsVacation: 0 },
    results: { salaryBalance: 0, thirteenth: 0, vacationOverdue: 0, vacationProportional: 0, noticePeriodVal: 0, fgtsPenalty: 0, totalTrct: 0, discounts: 0 }
});

const calculatedWeeklyHours = computed(() => {
    let totalMinutes = 0;
    if(!form.work_schedule) return "0:00";
    for (const d of weekDays) {
        const day = form.work_schedule[d.key];
        if (day && day.active) {
            const m1 = timeToMinutes(day.out1) - timeToMinutes(day.in1);
            const m2 = timeToMinutes(day.out2) - timeToMinutes(day.in2);
            if(m1 > 0) totalMinutes += m1;
            if(m2 > 0) totalMinutes += m2;
        }
    }
    const h = Math.floor(totalMinutes / 60);
    const m = totalMinutes % 60;
    return `${h}:${m.toString().padStart(2, '0')}`;
});

const timeToMinutes = (t: string) => {
    if(!t) return 0;
    const [h, m] = t.split(':').map(Number);
    if(isNaN(h) || isNaN(m)) return 0;
    return (h * 60) + m;
};

// Férias Visuais
const vacationInfo = computed(() => {
    if(!form.admission_date) return null;
    const adm = new Date(form.admission_date);
    const now = new Date();
    let years = now.getFullYear() - adm.getFullYear();

    let startPeriod = new Date(adm);
    startPeriod.setFullYear(adm.getFullYear() + years);
    if (now < startPeriod) {
        startPeriod.setFullYear(startPeriod.getFullYear() - 1);
    }
    let endPeriod = new Date(startPeriod);
    endPeriod.setFullYear(endPeriod.getFullYear() + 1);

    const limitDate = new Date(endPeriod);
    limitDate.setFullYear(limitDate.getFullYear() + 1);

    let status = 'Adquirindo (Proporcional)';
    let color = 'info';
    if (now >= endPeriod && now < limitDate) {
        status = 'Disponível p/ Gozo (Vencida)'; color = 'warning';
    } else if (now >= limitDate) {
        status = 'Vencida + Multa CLT'; color = 'error';
    }

    return {
        start: formatDate(startPeriod.toISOString()),
        end: formatDate(endPeriod.toISOString()),
        limit: formatDate(limitDate.toISOString()),
        status, color
    }
});

const calculateRescission = () => {
    if (!form.admission_date) {
        return appStore.showSnackbar('Data de admissão não definida na aba "Perfil Profissional".', 'warning');
    }

    const base = Number(rescissionSim.manualBaseSalary) > 0
        ? Number(rescissionSim.manualBaseSalary)
        : (Number(form.salary_base || 0) + Number(form.salary_additional || 0));

    if (base <= 0) {
        return appStore.showSnackbar('Salário base não definido na aba "Custos".', 'warning');
    }

    const parseLocalDate = (value: string | Date) => {
        if (value instanceof Date) {
            return new Date(value.getFullYear(), value.getMonth(), value.getDate());
        }

        const [year, month, day] = String(value).split('-').map(Number);
        return new Date(year, month - 1, day);
    };

    const addMonthsSafe = (date: Date, months: number) => {
        const result = new Date(date.getFullYear(), date.getMonth(), date.getDate());
        const originalDay = result.getDate();

        result.setMonth(result.getMonth() + months);

        if (result.getDate() !== originalDay) {
            result.setDate(0);
        }

        return new Date(result.getFullYear(), result.getMonth(), result.getDate());
    };

    const diffDaysInclusive = (start: Date, end: Date) => {
        const startOnly = new Date(start.getFullYear(), start.getMonth(), start.getDate());
        const endOnly = new Date(end.getFullYear(), end.getMonth(), end.getDate());

        return Math.floor((endOnly.getTime() - startOnly.getTime()) / 86400000) + 1;
    };

    const count13Avos = (admissionDate: Date, finalDate: Date) => {
        const year = finalDate.getFullYear();
        let avos = 0;

        for (let month = 0; month <= finalDate.getMonth(); month++) {
            const monthStart = new Date(year, month, 1);
            const monthEnd = new Date(year, month + 1, 0);

            const periodStart = admissionDate > monthStart ? admissionDate : monthStart;
            const periodEnd = finalDate < monthEnd ? finalDate : monthEnd;

            if (periodEnd >= periodStart && diffDaysInclusive(periodStart, periodEnd) >= 15) {
                avos++;
            }
        }

        return Math.max(0, Math.min(12, avos));
    };

    const countVacationAvos = (admissionDate: Date, finalDate: Date, overduePeriods: number) => {
        const proportionalPeriodStart = addMonthsSafe(admissionDate, overduePeriods * 12);

        if (finalDate < proportionalPeriodStart) {
            return 0;
        }

        let avos = 0;

        for (let i = 0; i < 12; i++) {
            const periodStart = addMonthsSafe(proportionalPeriodStart, i);
            const nextPeriodStart = addMonthsSafe(proportionalPeriodStart, i + 1);
            const periodEnd = new Date(nextPeriodStart);
            periodEnd.setDate(periodEnd.getDate() - 1);

            const workedEnd = finalDate < periodEnd ? finalDate : periodEnd;

            if (workedEnd >= periodStart && diffDaysInclusive(periodStart, workedEnd) >= 15) {
                avos++;
            }
        }

        return Math.max(0, Math.min(12, avos));
    };

    const adm = parseLocalDate(form.admission_date);
    const dem = parseLocalDate(rescissionSim.endDate);

    if (dem <= adm) {
        return appStore.showSnackbar('A data de demissão deve ser maior que a de admissão.', 'error');
    }

    // 1. Saldo de salário
    // Se a data de demissão for 01/05, conta 1 dia.
    // Se na sua regra interna o último dia pago foi 30/04, então a data de demissão usada no simulador deve ser 30/04.
    const workedDays = dem.getDate();
    const salaryBalance = (base / 30) * workedDays;

    // 2. Tempo de serviço
    const msDiff = dem.getTime() - adm.getTime();
    const totalDaysWorked = Math.floor(msDiff / 86400000);
    const yearsWorked = Math.floor(totalDaysWorked / 365);

    // 3. Aviso prévio
    let noticePeriodVal = 0;
    let noticeDays = 0;

    if (rescissionSim.reason === 'Sem Justa Causa') {
        noticeDays = Math.min(90, 30 + (yearsWorked * 3));

        if (rescissionSim.noticeType === 'Indenizado') {
            noticePeriodVal = (base / 30) * noticeDays;
        }
    } else if (
        rescissionSim.reason === 'Pedido de Demissão' &&
        rescissionSim.noticeType === 'Não Cumprido (Descontado)'
    ) {
        noticeDays = 30;
        noticePeriodVal = -base;
    } else if (rescissionSim.reason === 'Acordo (Reforma Trab.)') {
        noticeDays = Math.min(90, 30 + (yearsWorked * 3));

        if (rescissionSim.noticeType === 'Indenizado') {
            noticePeriodVal = ((base / 30) * noticeDays) / 2;
        }
    }

    // Aviso trabalhado NÃO projeta nem soma valor indenizado.
    let finalProjectedDate = new Date(dem);

    if (rescissionSim.noticeType === 'Indenizado' && noticeDays > 0) {
        finalProjectedDate = new Date(dem);
        finalProjectedDate.setDate(finalProjectedDate.getDate() + noticeDays);
    }

    // 4. 13º proporcional
    let months13 = count13Avos(adm, finalProjectedDate);
    let thirteenth = (base / 12) * months13;

    // 5. Férias
    const vacationOverduePeriods = Number(rescissionSim.vacationOverduePeriods || 0);

    let monthsVacation = countVacationAvos(
        adm,
        finalProjectedDate,
        vacationOverduePeriods
    );

    let vacationProportionalBase = (base / 12) * monthsVacation;
    let vacationProportional = vacationProportionalBase + (vacationProportionalBase / 3);

    let vacationOverdueBase = base * vacationOverduePeriods;
    let vacationOverdue = vacationOverdueBase + (vacationOverdueBase / 3);

    // 6. Multa FGTS
    // Como você pediu cálculo SEM multa, deixo controlado.
    const includeFgtsPenalty = Boolean(rescissionSim.includeFgtsPenalty);

    let fgtsPenalty = 0;

    if (includeFgtsPenalty && rescissionSim.reason === 'Sem Justa Causa') {
        fgtsPenalty = Number(rescissionSim.fgtsBalance || 0) * 0.40;
    }

    if (includeFgtsPenalty && rescissionSim.reason === 'Acordo (Reforma Trab.)') {
        fgtsPenalty = Number(rescissionSim.fgtsBalance || 0) * 0.20;
    }

    // 7. Ajuste justa causa
    if (rescissionSim.reason === 'Justa Causa') {
        thirteenth = 0;
        vacationProportional = 0;
        noticePeriodVal = 0;
        months13 = 0;
        monthsVacation = 0;
    }

    const sumTrct = salaryBalance
        + thirteenth
        + vacationOverdue
        + vacationProportional
        + noticePeriodVal;

    // 8. Impostos
    const numDependents = form.dependents ? form.dependents.length : 0;
    const deducaoDependentes = numDependents * 189.59;

    const calcularINSSProgressivo = (valor: number) => {
        let inss = 0;

        if (valor <= 0) return 0;

        if (valor <= 1412.00) return valor * 0.075;
        inss += 1412.00 * 0.075;

        if (valor <= 2666.68) return inss + ((valor - 1412.00) * 0.09);
        inss += (2666.68 - 1412.00) * 0.09;

        if (valor <= 4000.03) return inss + ((valor - 2666.68) * 0.12);
        inss += (4000.03 - 2666.68) * 0.12;

        if (valor <= 7786.02) return inss + ((valor - 4000.03) * 0.14);
        inss += (7786.02 - 4000.03) * 0.14;

        return inss;
    };

    const calcularIRRFProgressivo = (baseCalc: number) => {
        if (baseCalc <= 2259.20) return 0;
        if (baseCalc <= 2826.65) return (baseCalc * 0.075) - 169.44;
        if (baseCalc <= 3751.05) return (baseCalc * 0.15) - 381.44;
        if (baseCalc <= 4664.68) return (baseCalc * 0.225) - 662.77;
        return (baseCalc * 0.275) - 896.00;
    };

    const inssSalario = calcularINSSProgressivo(salaryBalance);
    const inss13 = calcularINSSProgressivo(thirteenth);

    const descontoLegalSalario = inssSalario + deducaoDependentes;
    const baseIrrfSalario = salaryBalance - Math.max(descontoLegalSalario, 564.80);
    const irrfSalario = calcularIRRFProgressivo(baseIrrfSalario);

    const descontoLegal13 = inss13 + deducaoDependentes;
    const baseIrrf13 = thirteenth - Math.max(descontoLegal13, 564.80);
    const irrf13 = calcularIRRFProgressivo(baseIrrf13);

    const totalDiscounts = inssSalario + inss13 + irrfSalario + irrf13;

    rescissionSim.meta = {
        workedDays,
        noticeDays,
        months13: rescissionSim.reason === 'Justa Causa' ? 0 : months13,
        monthsVacation: rescissionSim.reason === 'Justa Causa' ? 0 : monthsVacation,
    };

    rescissionSim.results = {
        salaryBalance,
        thirteenth,
        vacationOverdue,
        vacationProportional,
        noticePeriodVal,
        fgtsPenalty,
        totalTrct: sumTrct,
        discounts: totalDiscounts,
        netTotal: sumTrct - totalDiscounts,
        grossTotalWithoutFgtsPenalty: sumTrct,
        netTotalWithoutFgtsPenalty: sumTrct - totalDiscounts,
        totalWithFgtsPenalty: sumTrct + fgtsPenalty,
        netTotalWithFgtsPenalty: sumTrct + fgtsPenalty - totalDiscounts,
    };

    rescissionSim.simulated = true;
};

const fetchSupervisors = async () => {
    const { data } = await supabase.from('employees_mj').select('id, nome, cargo').order('nome');
    if (data) colaboradores.value = data.map(d => ({ id: d.id, nome: `${d.nome} (${d.cargo || 'S/ Cargo'})` }));
};

const fetchSystemUsers = async () => {
    const { data } = await supabase.from('profiles').select('id, full_name, email');
    if (data) {
        systemUsers.value = data.map(u => ({
            id: u.id,
            label: `${u.full_name || 'Sem nome'} (${u.email})`
        }));
    }
};

const fetchCompanies = async () => {
    const { data } = await supabase.from('companies').select('id, trade_name, name, cnpj').eq('active', true);
    if (data) {
        fiscalCompanies.value = data.map(c => ({
            id: c.id,
            label: `${c.trade_name || c.name} (${c.cnpj})`
        }));
    }
};

watch(() => props.show, async (newVal) => {
    if (newVal) {
        activeTab.value = 0;
        rescissionSim.simulated = false;
        await fetchSupervisors();
        await fetchSystemUsers();
        await fetchCompanies();

        Object.assign(form, getDefaultForm()); // Zera tudo 100%

        if (props.employee && Object.keys(props.employee).length > 0) {
            // Mescla os dados que existem no banco, respeitando os objetos nested se estiverem nulos
            Object.keys(props.employee).forEach(key => {
                if(props.employee[key] !== null && props.employee[key] !== undefined) {
                    form[key] = props.employee[key];
                }
            });

            // Garantia extra de arrays/objetos se o banco retornar string vazia
            if (!form.emergency_contact || typeof form.emergency_contact === 'string') form.emergency_contact = { name: '', relation: '', phone: '' };
            if (!form.bank_info || typeof form.bank_info === 'string') form.bank_info = { bank: '', agency: '', account: '', type: 'Corrente', pix: '' };
            if (!form.work_schedule || Object.keys(form.work_schedule).length === 0) form.work_schedule = JSON.parse(JSON.stringify(defaultSchedule));
        }
        if(formRef.value) formRef.value.resetValidation();
    }
});

const handleUpdateShow = (val: boolean) => { if (!val) emit('close'); };

const basePlusAdic = computed(() => Number(form.salary_base || 0) + Number(form.salary_additional || 0));
const totalBenefitsValue = computed(() => (form.benefits || []).reduce((sum: number, b: any) => sum + Number(b.value || 0), 0));
const taxCost = computed(() => basePlusAdic.value * (Number(form.tax_percentage || 0) / 100));
const monthlyCost = computed(() => basePlusAdic.value + taxCost.value + totalBenefitsValue.value);
const yearlyCost = computed(() => {
    if (form.contract_type === 'CLT') return (basePlusAdic.value + taxCost.value) * 13.33 + (totalBenefitsValue.value * 12);
    return monthlyCost.value * 12;
});

const addDependent = () => {
    if (!newDependent.name) return appStore.showSnackbar('Nome obrigatório', 'warning');
    if (!form.dependents) form.dependents = [];
    form.dependents.push({ ...newDependent, ui_id: Date.now() });
    showDependentModal.value = false;
    Object.assign(newDependent, { name: '', relation: 'Filho(a)', birth_date: '' });
};
const removeDependent = (idx: number) => { form.dependents.splice(idx, 1); };

const addEquipment = () => {
    if (!newEquipment.name) return appStore.showSnackbar('Nome do item obrigatório', 'warning');
    if (!form.equipments) form.equipments = [];
    form.equipments.push({ ...newEquipment, status: 'Em Posse', ui_id: Date.now() });
    showEquipmentModal.value = false;
    Object.assign(newEquipment, { name: 'Notebook', serial_number: '', delivery_date: new Date().toISOString().split('T')[0] });
};
const removeEquipment = (idx: number) => { form.equipments.splice(idx, 1); };
const returnEquipment = (idx: number) => { form.equipments[idx].status = 'Devolvido'; appStore.showSnackbar('Item devolvido com sucesso.', 'success'); };

const sortedCareerHistory = computed(() => {
    if (!form.career_history) return [];
    return [...form.career_history].sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime());
});

const getEventColor = (type: string) => {
    switch(type) { case 'Promoção': return 'success'; case 'Mudança de Departamento': return 'purple'; case 'Ajuste Salarial': return 'amber-darken-3'; case 'Admissão': return 'blue-darken-3'; case 'Advertência': return 'error'; case 'Férias': return 'teal'; case 'Licença': return 'orange'; default: return 'blue-grey-darken-3'; }
};
const getEventIcon = (type: string) => {
    switch(type) { case 'Promoção': return 'mdi-star'; case 'Ajuste Salarial': return 'mdi-cash-plus'; case 'Admissão': return 'mdi-door-open'; case 'Advertência': return 'mdi-alert'; case 'Férias': return 'mdi-beach'; default: return 'mdi-chevron-right'; }
};

const addCareerEvent = () => {
    if (!newEvent.date || !newEvent.description) return appStore.showSnackbar('Preencha Data e Descrição', 'warning');
    if (!form.career_history) form.career_history = [];
    form.career_history.push({ ...newEvent, ui_id: Date.now() });
    showCareerEventModal.value = false;
    Object.assign(newEvent, { type: 'Promoção', date: new Date().toISOString().split('T')[0], description: '', old_value: '', new_value: '' });
};
const removeCareerEvent = (idx: number) => { form.career_history.splice(idx, 1); };

const addBenefit = () => {
    if (!newBenefit.name) return appStore.showSnackbar('Nome do benefício obrigatório', 'warning');
    if (!form.benefits) form.benefits = [];
    form.benefits.push({ ...newBenefit, ui_id: Date.now() });
    showBenefitModal.value = false;
    Object.assign(newBenefit, { name: '', provider: '', value: 0 });
};
const removeBenefit = (idx: number) => { form.benefits.splice(idx, 1); };

const getDocsByCategory = (cat: string) => { return (form.documents || []).filter((d: any) => d.category === cat); };

const executeDocUpload = async () => {
    if (!newDocFile.value) return appStore.showSnackbar('Selecione um arquivo.', 'warning');
    uploadingDoc.value = true;
    try {
        const file = Array.isArray(newDocFile.value) ? newDocFile.value[0] : newDocFile.value;
        const fileExt = file.name.split('.').pop();
        const fileName = `doc_${Date.now()}_${Math.random().toString(36).substring(7)}.${fileExt}`;
        const { error } = await supabase.storage.from('customer_assets').upload(`employees/docs/${fileName}`, file);
        if (error) throw error;
        const { data } = supabase.storage.from('customer_assets').getPublicUrl(`employees/docs/${fileName}`);

        if (!form.documents) form.documents = [];
        form.documents.push({ name: newDocCustomName.value || file.name, url: data.publicUrl, category: newDocCategory.value, uploaded_at: new Date().toISOString() });
        appStore.showSnackbar('Documento arquivado!', 'success');
        showDocModal.value = false; newDocFile.value = null; newDocCustomName.value = '';
    } catch (e: any) { appStore.showSnackbar('Erro ao salvar documento', 'error'); } finally { uploadingDoc.value = false; }
};

const openDoc = (url: string) => { window.open(url, '_blank'); };
const removeDocument = (doc: any) => { if(!confirm('Excluir documento?')) return; const idx = form.documents.findIndex((d: any) => d.url === doc.url); if(idx > -1) form.documents.splice(idx, 1); };

const uploadAvatar = async (event: any) => {
    const file = event.target.files[0];
    if (!file) return;
    uploadingAvatar.value = true;
    try {
        const fileExt = file.name.split('.').pop();
        const fileName = `avatar_${Date.now()}_${Math.random().toString(36).substring(7)}.${fileExt}`;
        const { error } = await supabase.storage.from('customer_assets').upload(`employees/${fileName}`, file);
        if (error) throw error;
        const { data } = supabase.storage.from('customer_assets').getPublicUrl(`employees/${fileName}`);
        form.avatar_url = data.publicUrl;
        appStore.showSnackbar('Foto atualizada!', 'success');
    } catch (e: any) { appStore.showSnackbar('Erro ao salvar foto', 'error'); } finally { uploadingAvatar.value = false; }
};

const exportDossierPdf = async () => {
    isExportingPdf.value = true;
    try {
        const imageToBase64 = async (url: string): Promise<string> => {
            try {
                if (!url) return '';
                const res = await fetch(url);
                const blob = await res.blob();
                return new Promise((resolve) => {
                    const reader = new FileReader();
                    reader.onload = () => resolve(String(reader.result));
                    reader.readAsDataURL(blob);
                });
            } catch(e) { return ''; }
        };

        const doc = new jsPDF({ orientation: "p", unit: "mm", format: "a4" });
        const pageW = doc.internal.pageSize.getWidth();
        const pageH = doc.internal.pageSize.getHeight();
        const M = 10;
        const boxW = pageW - M * 2;
        let lastY = 10;

        // --- Função Auxiliar de Quebra de Página Inteligente ---
        const checkPageBreak = (neededHeight: number) => {
            if (lastY + neededHeight > pageH - 20) {
                doc.addPage();
                lastY = 15;
            }
        };

        const COMPANY = {
            name: "CONFECCOES MJ",
            cnpj: "53.756.096/0001-89",
            address: "RUA LUIZ MONTANHAN, 1302 (BARRACÃO TERRA NOVA)",
            city: "Tietê/SP - CEP: 18530-000",
            phones: "(15) 9789-0653 - (15) 99763-7941",
            email: "mrjackyfinanceiro@gmail.com",
            logoUrl: "https://cdn.shopify.com/s/files/1/0661/4574/6991/files/Sem_nome_1080_x_800_px_1080_x_500_px_1080_x_400_px_1000_x_380_px_da020cf2-2bb9-4dac-8dd3-4548cfd2e5ae.png?v=1756811713"
        };

        // --- 1. CABEÇALHO PADRÃO ---
        const headerH = 26;
        doc.setDrawColor(180); doc.setLineWidth(0.3); doc.rect(M, lastY, boxW, headerH);
        try {
            const logoBase64 = await imageToBase64(COMPANY.logoUrl);
            if(logoBase64) doc.addImage(logoBase64, "PNG", M + 3, lastY + 4, 30, 16);
        } catch (e) { /* ignore */ }

        doc.setFont("helvetica", "bold"); doc.setFontSize(11); doc.text(COMPANY.name, M + 38, lastY + 9);
        doc.setFont("helvetica", "normal"); doc.setFontSize(8.5);
        doc.text(`CNPJ: ${COMPANY.cnpj}`, M + 38, lastY + 14);
        doc.text(COMPANY.address, M + 38, lastY + 18);
        doc.text(COMPANY.city, M + 38, lastY + 22);

        const rightX = pageW - M;
        doc.text(COMPANY.phones, rightX, lastY + 9, { align: "right" });
        doc.text(COMPANY.email, rightX, lastY + 14, { align: "right" });
        doc.text("Departamento de Recursos Humanos", rightX, lastY + 19, { align: "right" });
        lastY += headerH + 6;

        // --- 2. BARRA DE TÍTULO ---
        const barH = 8;
        doc.setFillColor(230); doc.rect(M, lastY, boxW, barH, "F"); doc.setDrawColor(180); doc.rect(M, lastY, boxW, barH);
        doc.setFont("helvetica", "bold"); doc.setFontSize(11);
        doc.text("DOSSIÊ COMPLETO DE COLABORADOR", pageW / 2, lastY + 5.5, { align: "center" });
        doc.setFontSize(10); doc.text(formatDate(new Date().toISOString()), pageW - M - 2, lastY + 5.5, { align: "right" });
        lastY += barH + 6;

        // --- 3. DADOS CADASTRAIS (COM FOTO) ---
        doc.setFont("helvetica", "bold"); doc.setFontSize(9.5);
        doc.setFillColor(230); doc.rect(M, lastY, boxW, 7, "F"); doc.setDrawColor(180); doc.rect(M, lastY, boxW, 7);
        doc.text("1. IDENTIFICAÇÃO E CLASSIFICAÇÃO", M + 2, lastY + 5);
        lastY += 9;

        const photoSize = 35;
        doc.setDrawColor(180);
        doc.rect(M, lastY, photoSize, photoSize + 5);

        if (form.avatar_url) {
            try {
                const avatarBase64 = await imageToBase64(form.avatar_url);
                if (avatarBase64) doc.addImage(avatarBase64, "JPEG", M + 1, lastY + 1, photoSize - 2, photoSize + 3);
            } catch(e) { doc.setFont("helvetica", "italic"); doc.setFontSize(8); doc.text("S/ Foto", M + (photoSize/2), lastY + (photoSize/2), {align: "center"}); }
        } else {
            doc.setFont("helvetica", "italic"); doc.setFontSize(8); doc.text("S/ Foto", M + (photoSize/2), lastY + (photoSize/2), {align: "center"});
        }

        const safeName = form.nome || 'COLABORADOR';
        const tableX = M + photoSize + 4;
        const tableW = boxW - photoSize - 4;

        autoTable(doc, {
            startY: lastY, theme: "grid", tableWidth: tableW, margin: { left: tableX },
            styles: { fontSize: 8.5, cellPadding: 1.5, textColor: 0, lineColor: [200, 200, 200], lineWidth: 0.2, minCellHeight: 8, valign: "middle" },
            columnStyles: { 0: { cellWidth: 20, fontStyle: "bold" }, 1: { cellWidth: 60 }, 2: { cellWidth: 25, fontStyle: "bold" }, 3: { cellWidth: "auto" } },
            body: [
                ["Nome:", safeName.toUpperCase(), "CPF:", form.cpf || "—"],
                ["Cargo:", form.cargo || "—", "RG:", form.rg || "—"],
                ["Admissão:", formatDate(form.admission_date) || "—", "Nascimento:", formatDate(form.birth_date) || "—"],
                ["Vínculo:", form.contract_type || "—", "Estado Civil:", form.marital_status || "—"],
                ["Endereço:", form.endereco_completo || "—", "", ""]
            ]
        });
        lastY = Math.max((doc as any).lastAutoTable.finalY + 5, lastY + photoSize + 10);

        // --- 4. CONTATO E EMERGÊNCIA ---
        checkPageBreak(30);
        doc.setFont("helvetica", "bold"); doc.setFontSize(9.5);
        doc.setFillColor(230); doc.rect(M, lastY, boxW, 7, "F"); doc.setDrawColor(180); doc.rect(M, lastY, boxW, 7);
        doc.text("2. CONTATOS E EMERGÊNCIA", M + 2, lastY + 5);

        autoTable(doc, {
            startY: lastY + 7, theme: "grid", tableWidth: boxW, margin: { left: M, right: M },
            styles: { fontSize: 8.5, cellPadding: 1.5, textColor: 0, lineColor: [200, 200, 200], lineWidth: 0.2, minCellHeight: 7, valign: "middle" },
            columnStyles: { 0: { cellWidth: 35, fontStyle: "bold" }, 1: { cellWidth: 60 }, 2: { cellWidth: 30, fontStyle: "bold" }, 3: { cellWidth: "auto" } },
            body: [
                ["Celular / Fixo:", `${form.celular || "—"} / ${form.telefone || "—"}`, "E-mail:", form.email || "—"],
                ["Avisar Emergência:", form.emergency_contact?.name || "—", "Tel. Emergência:", `${form.emergency_contact?.phone || "—"} (${form.emergency_contact?.relation || "—"})`]
            ]
        });
        lastY = (doc as any).lastAutoTable.finalY + 5;

        // --- 5. SITUAÇÃO FUNCIONAL E FÉRIAS ---
        checkPageBreak(30);
        doc.setFont("helvetica", "bold"); doc.setFontSize(9.5);
        doc.setFillColor(230); doc.rect(M, lastY, boxW, 7, "F"); doc.setDrawColor(180); doc.rect(M, lastY, boxW, 7);
        doc.text("3. JORNADA E FÉRIAS", M + 2, lastY + 5);

        const vac = vacationInfo.value;
        const vacText = vac ? `${vac.start} a ${vac.end} (Limite: ${vac.limit}) | Status: ${vac.status.toUpperCase()}` : "N/A";

        autoTable(doc, {
            startY: lastY + 7, theme: "grid", tableWidth: boxW, margin: { left: M, right: M },
            styles: { fontSize: 8.5, cellPadding: 1.5, textColor: 0, lineColor: [200, 200, 200], lineWidth: 0.2, minCellHeight: 7, valign: "middle" },
            columnStyles: { 0: { cellWidth: 25, fontStyle: "bold" }, 1: { cellWidth: 45 }, 2: { cellWidth: 15, fontStyle: "bold" }, 3: { cellWidth: "auto" } },
            body: [ ["Jornada:", form.work_hours || "—", "Férias:", vacText] ]
        });
        lastY = (doc as any).lastAutoTable.finalY + 5;

        // --- 6. DADOS BANCÁRIOS E CUSTOS ---
        checkPageBreak(40);
        doc.setFont("helvetica", "bold"); doc.setFontSize(9.5);
        doc.setFillColor(230); doc.rect(M, lastY, boxW, 7, "F"); doc.setDrawColor(180); doc.rect(M, lastY, boxW, 7);
        doc.text("4. REMUNERAÇÃO, BANCO E CUSTOS (VISÃO EMPRESA)", M + 2, lastY + 5);

        const bankName = form.bank_info?.bank || 'N/A';
        const bankAgency = form.bank_info?.agency || 'N/A';
        const bankAcc = form.bank_info?.account || 'N/A';
        const bankPix = form.bank_info?.pix || 'N/A';

        autoTable(doc, {
            startY: lastY + 7, theme: "grid", tableWidth: boxW, margin: { left: M, right: M },
            styles: { fontSize: 8.5, cellPadding: 1.5, textColor: 0, lineColor: [200, 200, 200], lineWidth: 0.2, minCellHeight: 7, valign: "middle" },
            columnStyles: { 0: { cellWidth: 35, fontStyle: "bold" }, 1: { cellWidth: 50 }, 2: { cellWidth: 40, fontStyle: "bold" }, 3: { cellWidth: "auto" } },
            body: [
                ["Banco / Instituição:", bankName, "Chave PIX:", bankPix],
                ["Agência:", bankAgency, "Conta (Tipo):", `${bankAcc} (${form.bank_info?.type || "—"})`],
                ["Salário Base / Adic.:", `${formatCurrency(form.salary_base)} / ${formatCurrency(form.salary_additional)}`, "Encargos (INSS/FGTS):", formatCurrency(taxCost.value)],
                ["CUSTO MENSAL:", formatCurrency(monthlyCost.value), "PROVISÃO ANUAL:", formatCurrency(yearlyCost.value)]
            ]
        });
        lastY = (doc as any).lastAutoTable.finalY + 5;

        // --- 7. BENEFÍCIOS ATIVOS ---
        if (form.benefits && form.benefits.length > 0) {
            checkPageBreak(30);
            doc.setFont("helvetica", "bold"); doc.setFontSize(9.5);
            doc.setFillColor(230); doc.rect(M, lastY, boxW, 7, "F"); doc.setDrawColor(180); doc.rect(M, lastY, boxW, 7);
            doc.text("5. PACOTE DE BENEFÍCIOS CONCEDIDOS", M + 2, lastY + 5);

            autoTable(doc, {
                startY: lastY + 7, theme: "grid", tableWidth: boxW, margin: { left: M, right: M },
                headStyles: { fillColor: [245, 245, 245], textColor: 0, fontStyle: "bold", fontSize: 8.5, valign: "middle" },
                styles: { fontSize: 8.3, cellPadding: 1.5, lineColor: [200, 200, 200], lineWidth: 0.2, textColor: 0, minCellHeight: 7, valign: "middle" },
                head: [["BENEFÍCIO", "FORNECEDOR / FONTE", "CUSTO MENSAL EMPRESA"]],
                body: form.benefits.map((b: any) => [b.name || "—", b.provider || "Interno", formatCurrency(b.value)])
            });
            lastY = (doc as any).lastAutoTable.finalY + 5;
        }

        // --- 8. HISTÓRICO PROFISSIONAL ---
        if (sortedCareerHistory.value && sortedCareerHistory.value.length > 0) {
            checkPageBreak(30);
            doc.setFont("helvetica", "bold"); doc.setFontSize(9.5);
            doc.setFillColor(230); doc.rect(M, lastY, boxW, 7, "F"); doc.setDrawColor(180); doc.rect(M, lastY, boxW, 7);
            doc.text("6. HISTÓRICO E OCORRÊNCIAS DE CARREIRA", M + 2, lastY + 5);

            autoTable(doc, {
                startY: lastY + 7, theme: "grid", tableWidth: boxW, margin: { left: M, right: M },
                headStyles: { fillColor: [245, 245, 245], textColor: 0, fontStyle: "bold", fontSize: 8.5, valign: "middle" },
                styles: { fontSize: 8.3, cellPadding: 1.5, lineColor: [200, 200, 200], lineWidth: 0.2, textColor: 0, minCellHeight: 7, valign: "middle" },
                head: [["DATA", "TIPO DE EVENTO", "DESCRIÇÃO DO EVENTO", "TRANSIÇÃO (DE -> PARA)"]],
                body: sortedCareerHistory.value.map((h: any) => [
                    formatDate(h.date), h.type || "—", h.description || "—",
                    (h.old_value || h.new_value) ? `${h.old_value || ''} -> ${h.new_value || ''}` : "—"
                ])
            });
            lastY = (doc as any).lastAutoTable.finalY + 5;
        }

        // --- 9. EQUIPAMENTOS / EPIs ---
        if (form.equipments && form.equipments.length > 0) {
            checkPageBreak(30);
            doc.setFont("helvetica", "bold"); doc.setFontSize(9.5);
            doc.setFillColor(230); doc.rect(M, lastY, boxW, 7, "F"); doc.setDrawColor(180); doc.rect(M, lastY, boxW, 7);
            doc.text("7. PATRIMÔNIO EM POSSE E EPIs", M + 2, lastY + 5);

            autoTable(doc, {
                startY: lastY + 7, theme: "grid", tableWidth: boxW, margin: { left: M, right: M },
                headStyles: { fillColor: [245, 245, 245], textColor: 0, fontStyle: "bold", fontSize: 8.5, valign: "middle" },
                styles: { fontSize: 8.3, cellPadding: 1.5, lineColor: [200, 200, 200], lineWidth: 0.2, textColor: 0, minCellHeight: 7, valign: "middle" },
                head: [["EQUIPAMENTO / ITEM", "Nº SÉRIE / DETALHES", "ENTREGUE EM", "STATUS"]],
                body: form.equipments.map((e: any) => [e.name || "—", e.serial_number || "—", formatDate(e.delivery_date) || "—", e.status || "—"])
            });
            lastY = (doc as any).lastAutoTable.finalY + 5;
        }

        // --- 10. DEPENDENTES ---
        if (form.dependents && form.dependents.length > 0) {
            checkPageBreak(30);
            doc.setFont("helvetica", "bold"); doc.setFontSize(9.5);
            doc.setFillColor(230); doc.rect(M, lastY, boxW, 7, "F"); doc.setDrawColor(180); doc.rect(M, lastY, boxW, 7);
            doc.text("8. DEPENDENTES LEGAIS (IRRF/PLANO)", M + 2, lastY + 5);

            autoTable(doc, {
                startY: lastY + 7, theme: "grid", tableWidth: boxW, margin: { left: M, right: M },
                headStyles: { fillColor: [245, 245, 245], textColor: 0, fontStyle: "bold", fontSize: 8.5, valign: "middle" },
                styles: { fontSize: 8.3, cellPadding: 1.5, lineColor: [200, 200, 200], lineWidth: 0.2, textColor: 0, minCellHeight: 7, valign: "middle" },
                head: [["NOME DO DEPENDENTE", "GRAU DE PARENTESCO", "NASCIMENTO"]],
                body: form.dependents.map((d: any) => [d.name || "—", d.relation || "—", formatDate(d.birth_date) || "—"])
            });
            lastY = (doc as any).lastAutoTable.finalY + 5;
        }

        // --- ASSINATURAS ---
        checkPageBreak(35);
        const signH = 20;
        let signY = lastY + 10;

        doc.setDrawColor(0); doc.setLineWidth(0.3); doc.rect(M, signY, boxW, signH);

        doc.setDrawColor(120); doc.line(M + 15, signY + 12, M + (boxW/2) - 15, signY + 12);
        doc.setFont("helvetica", "normal"); doc.setFontSize(8);
        doc.text("Assinatura do Colaborador", M + (boxW/4), signY + 16, { align: "center" });

        doc.line(M + (boxW/2) + 15, signY + 12, M + boxW - 15, signY + 12);
        doc.text("Departamento de Recursos Humanos", M + (boxW*0.75), signY + 16, { align: "center" });

        // --- PAGINAÇÃO ---
        const totalPages = (doc as any).internal.getNumberOfPages();
        for (let i = 1; i <= totalPages; i++) {
            doc.setPage(i);
            doc.setFontSize(7); doc.setTextColor(150);
            doc.text(`Gerado com MJProcess (Dossiê RH) - Página ${i}/${totalPages}`, pageW - M, pageH - 5, { align: "right" });
        }

        const safeFileName = safeName.replace(/[^a-zA-Z0-9]/g, '_').toUpperCase();
        doc.save(`FICHA_RH_${safeFileName}_${format(new Date(), 'ddMMyyyy')}.pdf`);
        appStore.showSnackbar('Dossiê exportado perfeitamente!', 'success');

    } catch(e: any) {
        console.error("Erro interno do jsPDF:", e);
        appStore.showSnackbar(`Erro ao exportar PDF: ${e.message}`, 'error');
    } finally {
        isExportingPdf.value = false;
    }
};

const saveEmployee = async () => {
    const { valid } = await formRef.value.validate();
    if (!valid) { activeTab.value = 0; return appStore.showSnackbar('Verifique os campos obrigatórios na aba 1.', 'warning'); }

    isSaving.value = true;
    try {
        const payload = { ...form };
        payload.updated_at = new Date().toISOString();

        // Limpa máscaras
        if (payload.cpf) payload.cpf = payload.cpf.replace(/\D/g, '');
        if (payload.celular) payload.celular = payload.celular.replace(/\D/g, '');
        if (payload.telefone) payload.telefone = payload.telefone.replace(/\D/g, '');

        // Tratamento de Nulos (Anti-Erro 400)
        if (payload.birth_date === "") payload.birth_date = null;
        if (payload.admission_date === "") payload.admission_date = null;
        if (payload.user_id === "") payload.user_id = null;
        if (payload.supervisor_id === "") payload.supervisor_id = null;
        if (payload.company_id === "") payload.company_id = null;

        if (isNew.value) {
            // MATA O ID FANTASMA PARA O SUPABASE GERAR UM NOVO AUTOMATICAMENTE
            delete payload.id;

            const { error } = await supabase.from('employees_mj').insert(payload);
            if (error) throw error;
            appStore.showSnackbar('Dossiê do colaborador criado!', 'success');
        } else {
            const { error } = await supabase.from('employees_mj').update(payload).eq('id', props.employee.id);
            if (error) throw error;
            appStore.showSnackbar('Dossiê atualizado com sucesso!', 'success');
        }

        emit('refresh');
        emit('close');
    } catch (error: any) {
        appStore.showSnackbar(`Erro do Sistema: ${error.message}`, 'error');
    } finally {
        isSaving.value = false;
    }
};

const formatDate = (val: string) => { if (!val) return ''; const [y, m, d] = val.split('T')[0].split('-'); return `${d}/${m}/${y}`; };
const formatCurrency = (val: any) => new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(Number(val) || 0);
</script>

<style scoped>
/* ESTILO CORPORATIVO ADMINMJRECEIVABLES */
.fixed-dialog { overflow: hidden !important; }
.btn-rect { border-radius: 2px !important; text-transform: none !important; letter-spacing: 0.5px; }
.rounded-2px { border-radius: 2px !important; }
.ui-field :deep(.v-field) { border-radius: 2px !important; font-size: 13px; background: #fff;}
.input-label { display: block; font-size: 11px; font-weight: 800; text-transform: uppercase; color: #757575; margin-bottom: 6px; letter-spacing: 0.5px; }
.tracking-widest { letter-spacing: 0.05em; }

.border-white-20 { border: 1px solid rgba(255,255,255,0.2) !important; }
.border-white-10 { border-color: rgba(255,255,255,0.1) !important; }
.border-t-thick { border-top: 2px solid rgba(0,0,0,0.15) !important; }
.bg-black-70 { background-color: rgba(0,0,0,0.7); }
.bg-black-20 { background-color: rgba(0,0,0,0.2); }
.inset-0 { top: 0; bottom: 0; left: 0; right: 0; }
.shadow-md { box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06); }
.shadow-sm { box-shadow: 0 1px 2px rgba(0,0,0,0.05) !important; }
.row-gap { row-gap: 16px; margin-top: 4px; }
.hover-row:hover { background-color: #f8f9fa !important; }

/* Scrollbar */
.custom-scroll::-webkit-scrollbar { width: 6px; height: 6px; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.3); border-radius: 4px; }

/* Grid Tables */
.custom-grid-table { border-collapse: collapse; }
.custom-grid-table th, .custom-grid-table td { border-bottom: 1px solid rgba(0,0,0,0.08); }
.schedule-input { border: 1px solid rgba(0,0,0,0.2); padding: 4px 8px; border-radius: 2px; font-size: 13px; font-family: monospace; outline: none; background: white;}
.schedule-input:disabled { background: #f5f5f5; opacity: 0.5; }

/* Tabs laterais */
.tab-item { border-bottom: 1px solid rgba(255,255,255,0.05); min-height: 52px; font-size: 13px; }
.tab-item.v-tab--selected { background: rgba(255,255,255,0.1); border-right: 3px solid #fff; }

/* Expansion Panels (Pastas) */
.custom-expansion :deep(.v-expansion-panel-title) { min-height: 50px; padding: 12px 20px; font-size: 13px; }

/* Timeline Customizada (Flat Corporate) */
.custom-timeline { position: relative; padding-left: 20px; margin-top: 10px; }
.custom-timeline::before { content: ''; position: absolute; left: 6px; top: 0; bottom: 0; width: 2px; background: rgba(0,0,0,0.1); }
.timeline-item { position: relative; margin-bottom: 20px; }
.timeline-marker { position: absolute; left: -20px; top: 0; width: 24px; height: 24px; border-radius: 2px; display: flex; align-items: center; justify-content: center; box-shadow: 0 2px 4px rgba(0,0,0,0.1); z-index: 2; }
</style>
