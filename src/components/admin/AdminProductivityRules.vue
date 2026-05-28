<template>
  <div
    class="productivity-layout font-sans d-flex flex-column h-100"
    :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 text-grey-darken-4' : 'bg-glass-dark text-white'"
  >
    <div
      class="header-bar px-6 py-4 d-flex align-center justify-space-between flex-shrink-0"
      :class="themeStore.currentMode === 'light' ? 'bg-white border-b border-grey-lighten-2 shadow-sm' : 'bg-glass-header border-bottom-white-05'"
    >
      <div class="d-flex flex-column">
        <div class="breadcrumb text-caption d-flex align-center">
          <v-icon size="14" class="mr-1 opacity-70">mdi-cogs</v-icon>
          <span class="opacity-70">Administração</span>
          <span class="mx-2 opacity-50">></span>
          <span class="font-weight-bold text-primary">Regras do Sistema</span>
        </div>
        <div class="text-h5 font-weight-black tracking-tight leading-none mt-1 text-uppercase" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">
          Centro de Produtividade & Logística
        </div>
      </div>

      <div class="d-flex align-center gap-3">
        <v-btn
          color="success"
          variant="flat"
          class="btn-rect px-8 font-weight-black text-body-2 text-uppercase shadow-sm"
          prepend-icon="mdi-content-save-check"
          height="44"
          @click="saveGlobalSettings"
          :loading="saving"
        >
          Salvar Alterações
        </v-btn>
      </div>
    </div>

    <div class="flex-grow-1 d-flex overflow-hidden relative border-t" :class="themeStore.currentMode === 'light' ? 'border-grey-lighten-2' : 'border-white-05'">

      <div class="settings-sidebar d-flex flex-column flex-shrink-0 border-r" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-4 border-grey-lighten-2' : 'bg-surface-alt border-white-05'">
         <div class="pa-5">
            <div class="text-caption font-weight-black text-uppercase opacity-60 mb-4 letter-spacing-1">Módulos de Regra</div>

            <div
              class="settings-nav-item"
              :class="{'active-nav': activeTab === 'logistics', 'dark-mode': themeStore.currentMode !== 'light'}"
              @click="activeTab = 'logistics'"
            >
              <div class="nav-icon"><v-icon>mdi-truck-fast</v-icon></div>
              <div class="nav-text">
                 <div class="nav-title">Logística & Prazos</div>
                 <div class="nav-subtitle">Motor de datas de entrega</div>
              </div>
            </div>

            <div
              class="settings-nav-item mt-2"
              :class="{'active-nav': activeTab === 'workload', 'dark-mode': themeStore.currentMode !== 'light'}"
              @click="activeTab = 'workload'"
            >
              <div class="nav-icon"><v-icon>mdi-clock-outline</v-icon></div>
              <div class="nav-text">
                 <div class="nav-title">Jornada & Ponto</div>
                 <div class="nav-subtitle">Horários, almoço e extras</div>
              </div>
            </div>
         </div>
      </div>

      <div class="flex-grow-1 overflow-y-auto custom-scroll" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-transparent'">

         <div v-if="loadingData" class="d-flex flex-column justify-center align-center h-100 opacity-60">
            <v-progress-circular indeterminate color="primary" size="64" width="4"></v-progress-circular>
            <div class="mt-4 font-weight-bold text-uppercase">Carregando Módulos...</div>
         </div>

         <div v-else-if="activeTab === 'logistics'" class="pa-6 pa-md-8 d-flex flex-column gap-6 min-h-100 animate-fade-in">

            <div class="info-banner d-flex gap-4 pa-5 border-thin" :class="themeStore.currentMode === 'light' ? 'bg-blue-lighten-5 border-blue-lighten-4' : 'bg-blue-darken-4-alpha border-blue-darken-3'">
                <v-icon color="primary" size="32">mdi-information</v-icon>
                <div>
                    <h3 class="text-subtitle-1 font-weight-black text-primary mb-1 text-uppercase">Como funciona o Motor de Prazos?</h3>
                    <p class="text-body-2 opacity-80 mb-0 leading-tight">
                        Sempre que uma nova venda for lançada, o sistema somará o <strong>Lead Time de Produção</strong> à data de hoje.
                        Após isso, procurará o próximo dia da semana marcado como <strong>Dia Autorizado de Entrega</strong> para definir a previsão oficial.
                    </p>
                </div>
            </div>

            <div class="d-flex flex-wrap gap-4">
                <v-card class="kpi-card kpi-rect py-4 px-5 position-relative elevation-2 bg-gradient-blue flex-grow-1" style="min-width: 250px;">
                    <div class="kpi-bg-icon"><v-icon>mdi-timer-sand</v-icon></div>
                    <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height text-white">
                        <div class="d-flex align-center text-truncate gap-2 mb-2">
                        <v-icon size="18" class="opacity-80">mdi-timer-sand</v-icon>
                        <span class="text-caption font-weight-black text-uppercase">Lead Time de Produção</span>
                        </div>
                        <div class="d-flex align-end gap-1 my-1">
                        <span class="text-h3 font-weight-black leading-none">{{ settings.productionLeadTime }}</span>
                        <span class="text-caption font-weight-bold opacity-70 mb-1">Dias</span>
                        </div>
                        <div class="text-[11px] font-weight-bold opacity-80 mt-1 text-uppercase">Tempo padrão até expedição</div>
                    </div>
                </v-card>

                <v-card class="kpi-card kpi-rect py-4 px-5 position-relative elevation-2 bg-gradient-green flex-grow-1" style="min-width: 250px;">
                    <div class="kpi-bg-icon"><v-icon>mdi-calendar-check</v-icon></div>
                    <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height text-white">
                        <div class="d-flex align-center text-truncate gap-2 mb-2">
                        <v-icon size="18" class="opacity-80">mdi-truck-delivery</v-icon>
                        <span class="text-caption font-weight-black text-uppercase">Dias de Rota Ativos</span>
                        </div>
                        <div class="d-flex align-end gap-1 my-1">
                        <span class="text-h3 font-weight-black leading-none">{{ safeArrayLength(settings.allowedDeliveryDays) }}</span>
                        <span class="text-caption font-weight-bold opacity-70 mb-1">Dias/Semana</span>
                        </div>
                        <div class="text-[11px] font-weight-bold opacity-80 mt-1 text-uppercase">Janelas oficias de entrega</div>
                    </div>
                </v-card>

                <v-card class="kpi-card kpi-rect py-4 px-5 position-relative elevation-2 bg-gradient-purple flex-grow-1" style="min-width: 250px;">
                    <div class="kpi-bg-icon"><v-icon>mdi-beach</v-icon></div>
                    <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height text-white">
                        <div class="d-flex align-center text-truncate gap-2 mb-2">
                        <v-icon size="18" class="opacity-80">mdi-calendar-remove</v-icon>
                        <span class="text-caption font-weight-black text-uppercase">Feriados / Exceções</span>
                        </div>
                        <div class="d-flex align-end gap-1 my-1">
                        <span class="text-h3 font-weight-black leading-none">{{ safeArrayLength(holidays) }}</span>
                        <span class="text-caption font-weight-bold opacity-70 mb-1">Registros</span>
                        </div>
                        <div class="text-[11px] font-weight-bold opacity-80 mt-1 text-uppercase">Dias com pausa logística</div>
                    </div>
                </v-card>
            </div>

            <v-card class="border-thin shadow-sm card-rect" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'glass-card'">
                <div class="px-6 py-4 border-b d-flex align-center gap-3" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5' : 'bg-white-05'">
                    <v-avatar color="indigo-lighten-5" class="text-indigo-darken-2 avatar-rect" size="36"><v-icon>mdi-tune-vertical</v-icon></v-avatar>
                    <div>
                        <h3 class="text-subtitle-1 font-weight-black text-uppercase mb-0 tracking-tight">Parâmetros Globais</h3>
                    </div>
                </div>
                <div class="pa-6 pa-md-8">
                    <v-row>
                        <v-col cols="12" md="4">
                            <label class="input-label">Lead Time de Produção (Dias)</label>
                            <v-text-field
                                v-model.number="settings.productionLeadTime"
                                type="number"
                                variant="outlined"
                                density="comfortable"
                                hide-details
                                min="0"
                                suffix="Dias"
                                class="ui-field font-weight-black text-h6"
                                :bg-color="themeStore.currentMode === 'light' ? 'white' : 'transparent'"
                            ></v-text-field>
                            <div class="field-hint mt-2">
                                Quantos dias a fábrica precisa, no mínimo, para produzir e embalar o pedido.
                            </div>
                        </v-col>

                        <v-col cols="12" md="8">
                            <label class="input-label">Dias da Semana com Rota de Entrega</label>
                            <div class="d-flex align-center gap-2 flex-wrap">
                                <v-btn
                                    v-for="day in weekDays"
                                    :key="day.value"
                                    :variant="isDeliveryDayAllowed(day.value) ? 'flat' : 'outlined'"
                                    :color="isDeliveryDayAllowed(day.value) ? 'primary' : (themeStore.currentMode === 'light' ? 'grey-darken-1' : 'white-70')"
                                    class="btn-rect font-weight-bold px-4"
                                    height="48"
                                    @click="toggleDeliveryDay(day.value)"
                                >
                                    <v-icon start size="16" v-if="isDeliveryDayAllowed(day.value)">mdi-check-circle</v-icon>
                                    {{ day.label }}
                                </v-btn>
                            </div>
                            <div class="field-hint mt-2">
                                O sistema fará o agendamento de expedição apenas nos dias selecionados (marcados em azul).
                            </div>
                        </v-col>
                    </v-row>
                </div>
            </v-card>

            <v-card class="border-thin shadow-sm card-rect d-flex flex-column flex-grow-1 overflow-hidden" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'glass-card'">
                <div class="px-6 py-4 border-b d-flex justify-space-between align-center flex-wrap gap-4" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5' : 'bg-white-05'">
                    <div class="d-flex align-center gap-3">
                        <v-avatar color="red-lighten-5" class="text-error avatar-rect" size="36"><v-icon>mdi-calendar-remove</v-icon></v-avatar>
                        <div>
                            <h3 class="text-subtitle-1 font-weight-black text-uppercase mb-0 tracking-tight">Feriados e Exceções</h3>
                            <span class="text-caption opacity-70">Dias em que a fábrica para.</span>
                        </div>
                    </div>

                    <div class="d-flex align-center gap-3">
                        <div class="search-wrap d-flex align-center" :class="themeStore.currentMode === 'light' ? 'search-light' : 'search-dark'">
                            <v-icon :color="themeStore.currentMode === 'light' ? 'grey-darken-1' : 'white-70'">mdi-magnify</v-icon>
                            <input v-model="searchHoliday" type="text" placeholder="Buscar feriado..." class="clean-input flex-grow-1" />
                        </div>
                        <v-btn variant="flat" color="indigo" class="btn-rect font-weight-bold" height="40" prepend-icon="mdi-plus" @click="openHolidayModal(null)">
                            Nova Exceção
                        </v-btn>
                    </div>
                </div>

                <div class="grid-scroll flex-grow-1 overflow-y-auto custom-scroll position-relative" style="min-height: 300px;">
                    <div class="grid-header sticky-head border-b" :class="themeStore.currentMode === 'light' ? 'grid-surface-light' : 'grid-surface-dark'">
                        <div class="cell center header-text border-r" style="width: 140px;">Data</div>
                        <div class="cell header-text flex-grow-1 border-r">Motivo / Descrição</div>
                        <div class="cell center header-text border-r" style="width: 160px;">Pausa Produção?</div>
                        <div class="cell center header-text border-r" style="width: 160px;">Pausa Entrega?</div>
                        <div class="cell center header-text" style="width: 140px;">Ações</div>
                    </div>

                    <div v-if="filteredHolidays.length === 0" class="d-flex flex-column justify-center align-center py-12 opacity-50 w-100">
                         <v-icon size="64" class="mb-2">mdi-calendar-check-outline</v-icon>
                         <span class="text-body-1 font-weight-bold text-uppercase">Nenhuma exceção cadastrada.</span>
                    </div>

                    <div
                        v-else
                        v-for="(item, index) in filteredHolidays"
                        :key="item.id || index"
                        class="grid-row transition-colors border-b"
                        :class="[themeStore.currentMode === 'light' ? 'grid-row-light' : 'grid-row-dark', zebraClass(index)]"
                    >
                        <div class="cell center border-r" style="width: 140px;">
                            <v-chip size="small" color="indigo" variant="tonal" class="font-weight-black font-mono rounded-0">{{ formatDateSafe(item.date) }}</v-chip>
                        </div>
                        <div class="cell flex-grow-1 border-r">
                           <span class="font-weight-bold text-uppercase text-[13px] tracking-tight">{{ item.reason || '-' }}</span>
                        </div>
                        <div class="cell center border-r" style="width: 160px;">
                            <v-icon :color="item.pauses_production ? 'error' : 'success'">{{ item.pauses_production ? 'mdi-pause-octagon' : 'mdi-check-circle' }}</v-icon>
                        </div>
                        <div class="cell center border-r" style="width: 160px;">
                             <v-icon :color="item.pauses_delivery ? 'error' : 'success'">{{ item.pauses_delivery ? 'mdi-pause-octagon' : 'mdi-check-circle' }}</v-icon>
                        </div>
                        <div class="cell center" style="width: 140px;">
                          <div class="actions-inline">
                            <v-btn icon size="small" class="action-btn action-edit btn-rect" @click="openHolidayModal(item, false)" title="Editar" variant="flat"><v-icon size="16">mdi-pencil</v-icon></v-btn>
                            <v-btn icon size="small" class="action-btn bg-indigo-darken-2 btn-rect" @click="openHolidayModal(item, true)" title="Clonar" variant="flat"><v-icon size="16">mdi-content-copy</v-icon></v-btn>
                            <v-btn icon size="small" class="action-btn action-delete btn-rect" @click="deleteHoliday(item.id)" title="Remover" variant="flat"><v-icon size="16">mdi-trash-can</v-icon></v-btn>
                          </div>
                        </div>
                    </div>
                </div>
            </v-card>
         </div>

         <div v-else-if="activeTab === 'workload'" class="pa-6 pa-md-8 d-flex flex-column gap-6 min-h-100 animate-fade-in">

            <div class="info-banner d-flex gap-4 pa-5 border-thin" :class="themeStore.currentMode === 'light' ? 'bg-teal-lighten-5 border-teal-lighten-4' : 'bg-teal-darken-4-alpha border-teal-darken-3'">
                <v-icon color="teal-darken-3" size="32">mdi-clock-alert</v-icon>
                <div>
                    <h3 class="text-subtitle-1 font-weight-black text-teal-darken-3 mb-1 text-uppercase">Como funciona o Ponto Eletrônico?</h3>
                    <p class="text-body-2 opacity-80 mb-0 leading-tight" :class="themeStore.currentMode === 'light' ? 'text-teal-darken-4' : 'text-teal-lighten-4'">
                        Defina a jornada padrão da empresa. Se a <strong>Trava de Hora Extra</strong> estiver ativa, qualquer funcionário que tentar trabalhar fora do horário definido precisará de um PIN de autorização de um gestor.
                    </p>
                </div>
            </div>

            <v-card class="border-thin shadow-sm card-rect" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'glass-card'">
                <div class="px-6 py-4 border-b d-flex align-center gap-3" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5' : 'bg-white-05'">
                    <v-avatar color="teal-lighten-5" class="text-teal-darken-2 avatar-rect" size="36"><v-icon>mdi-office-building-clock</v-icon></v-avatar>
                    <div>
                        <h3 class="text-subtitle-1 font-weight-black text-uppercase mb-0 tracking-tight">Jornada Global Padrão</h3>
                    </div>
                </div>
                <div class="pa-6 pa-md-8">
                    <v-row dense class="mb-6">
                        <v-col cols="12" sm="6" md="3">
                            <label class="input-label">Entrada</label>
                            <v-text-field v-model="workSettings.globalStartTime" type="time" variant="outlined" density="comfortable" hide-details :bg-color="themeStore.currentMode === 'light' ? 'white' : 'transparent'" class="ui-field font-weight-black font-mono"></v-text-field>
                        </v-col>
                        <v-col cols="12" sm="6" md="3">
                            <label class="input-label text-warning">Início Almoço</label>
                            <v-text-field v-model="workSettings.lunchStartTime" type="time" variant="outlined" density="comfortable" hide-details :bg-color="themeStore.currentMode === 'light' ? 'white' : 'transparent'" class="ui-field font-weight-black font-mono"></v-text-field>
                        </v-col>
                        <v-col cols="12" sm="6" md="3">
                            <label class="input-label text-warning">Fim Almoço</label>
                            <v-text-field v-model="workSettings.lunchEndTime" type="time" variant="outlined" density="comfortable" hide-details :bg-color="themeStore.currentMode === 'light' ? 'white' : 'transparent'" class="ui-field font-weight-black font-mono"></v-text-field>
                        </v-col>
                        <v-col cols="12" sm="6" md="3">
                            <label class="input-label">Saída</label>
                            <v-text-field v-model="workSettings.globalEndTime" type="time" variant="outlined" density="comfortable" hide-details :bg-color="themeStore.currentMode === 'light' ? 'white' : 'transparent'" class="ui-field font-weight-black font-mono"></v-text-field>
                        </v-col>
                    </v-row>

                    <div class="d-flex align-center justify-space-between p-4 border-thin" :class="themeStore.currentMode === 'light' ? 'bg-amber-lighten-5 border-warning' : 'bg-warning-opacity-10 border-warning'">
                        <div>
                            <div class="text-subtitle-1 font-weight-black text-uppercase text-warning mb-1">Trava Operacional (Hora Extra)</div>
                            <div class="text-caption font-weight-medium opacity-80" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-3' : 'text-white'">Exigir autorização digital (PIN) de um administrador para permitir operações fora do horário de expediente.</div>
                        </div>
                        <v-switch v-model="workSettings.requireOvertimeApproval" color="warning" hide-details density="comfortable" inset></v-switch>
                    </div>
                </div>
            </v-card>

            <v-card class="border-thin shadow-sm d-flex flex-column flex-grow-1 overflow-hidden card-rect" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'glass-card'">
                <div class="px-6 py-4 border-b d-flex justify-space-between align-center flex-wrap gap-4" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5' : 'bg-white-05'">
                    <div class="d-flex align-center gap-3">
                        <v-avatar color="indigo-lighten-5" class="text-indigo avatar-rect" size="36"><v-icon>mdi-account-clock</v-icon></v-avatar>
                        <div>
                            <h3 class="text-subtitle-1 font-weight-black text-uppercase mb-0 tracking-tight">Exceções Individuais</h3>
                            <span class="text-caption opacity-70">Funcionários com horários diferentes da fábrica.</span>
                        </div>
                    </div>

                    <v-btn variant="flat" color="teal-darken-2" class="btn-rect font-weight-bold" height="40" prepend-icon="mdi-account-plus" @click="openCustomScheduleModal(null)">
                        Adicionar Horário Fixo
                    </v-btn>
                </div>

                <div class="grid-scroll flex-grow-1 overflow-y-auto custom-scroll position-relative" style="min-height: 300px;">
                    <div class="grid-header sticky-head border-b" :class="themeStore.currentMode === 'light' ? 'grid-surface-light' : 'grid-surface-dark'">
                        <div class="cell header-text flex-grow-1 border-r">Colaborador / Usuário</div>
                        <div class="cell center header-text border-r" style="width: 140px;">Entrada / Saída</div>
                        <div class="cell center header-text border-r" style="width: 160px;">Pausa p/ Almoço</div>
                        <div class="cell center header-text" style="width: 100px;">Ações</div>
                    </div>

                    <div v-if="!safeCustomSchedules || safeCustomSchedules.length === 0" class="d-flex flex-column justify-center align-center py-10 opacity-50 w-100">
                        <v-icon size="48" class="mb-2">mdi-account-group</v-icon>
                        <span class="text-body-2 font-weight-bold text-uppercase">Nenhuma exceção de funcionário.</span>
                        <span class="text-caption">Todos seguem a jornada global.</span>
                    </div>

                    <div v-else v-for="(item, index) in safeCustomSchedules" :key="item.userId || index" class="grid-row transition-colors border-b" :class="[themeStore.currentMode === 'light' ? 'grid-row-light' : 'grid-row-dark', zebraClass(index)]">
                        <div class="cell flex-grow-1 border-r">
                           <v-avatar size="24" color="grey-lighten-2" class="mr-3 text-[10px] font-weight-bold text-grey-darken-3 avatar-rect">{{ getUserInitial(item.userId) }}</v-avatar>
                           <span class="text-[13px] font-weight-bold text-uppercase tracking-tight">{{ getUserNameSafe(item.userId) }}</span>
                        </div>
                        <div class="cell center border-r" style="width: 140px;">
                            <div class="d-flex flex-column align-center">
                                <span class="font-mono font-weight-black text-success lh-1">{{ item.startTime || '-' }}</span>
                                <span class="font-mono font-weight-black text-error lh-1 mt-1">{{ item.endTime || '-' }}</span>
                            </div>
                        </div>
                        <div class="cell center border-r" style="width: 160px;">
                             <v-chip size="small" variant="tonal" color="warning" class="font-mono font-weight-bold px-2 rounded-0 text-[11px]">
                                 {{ item.lunchStartTime || '-' }} as {{ item.lunchEndTime || '-' }}
                             </v-chip>
                        </div>
                        <div class="cell center" style="width: 100px;">
                          <div class="actions-inline">
                            <v-btn icon size="small" class="action-btn action-edit btn-rect" @click="openCustomScheduleModal(item)" title="Editar" variant="flat"><v-icon size="16">mdi-pencil</v-icon></v-btn>
                            <v-btn icon size="small" class="action-btn action-delete btn-rect" @click="deleteCustomSchedule(item.userId)" title="Remover" variant="flat"><v-icon size="16">mdi-trash-can</v-icon></v-btn>
                          </div>
                        </div>
                    </div>
                </div>
            </v-card>
         </div>

      </div>
    </div>

    <v-dialog v-model="holidayModal.show" max-width="450" persistent>
        <v-card class="card-rect border-thin shadow-xl" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-grey-darken-4'">
            <div class="px-6 py-4 text-white font-weight-bold d-flex justify-space-between align-center" :class="holidayModal.isEdit ? 'bg-orange-darken-3' : 'bg-indigo-darken-3'">
                <span class="text-uppercase tracking-tight"><v-icon start>mdi-calendar-alert</v-icon> {{ holidayModal.isEdit ? 'Editar Exceção' : 'Nova Exceção Logística' }}</span>
                <v-btn icon="mdi-close" variant="text" density="compact" @click="holidayModal.show = false"></v-btn>
            </div>
            <v-card-text class="pa-6">
                <label class="input-label">Data da Exceção *</label>
                <v-text-field v-model="holidayModal.form.date" type="date" variant="outlined" density="comfortable" class="ui-field mb-4" :bg-color="themeStore.currentMode === 'light' ? 'grey-lighten-5' : 'rgba(0,0,0,0.2)'"></v-text-field>

                <label class="input-label">Motivo / Feriado *</label>
                <v-text-field v-model="holidayModal.form.reason" variant="outlined" density="comfortable" class="ui-field mb-5" placeholder="Ex: Feriado Nacional, Manutenção..." :bg-color="themeStore.currentMode === 'light' ? 'grey-lighten-5' : 'rgba(0,0,0,0.2)'"></v-text-field>

                <div class="border-thin pa-4 mb-3 d-flex align-center justify-space-between transition-colors" :class="holidayModal.form.pauses_production ? 'bg-error-opacity-10 border-error' : ''">
                    <div>
                        <div class="font-weight-bold text-body-2 text-uppercase" :class="holidayModal.form.pauses_production ? 'text-error' : ''">Pausa Produção?</div>
                        <div class="text-[10px] opacity-70">A fábrica não vai trabalhar (afeta lead time).</div>
                    </div>
                    <v-switch v-model="holidayModal.form.pauses_production" color="error" hide-details density="compact" inset></v-switch>
                </div>

                <div class="border-thin pa-4 d-flex align-center justify-space-between transition-colors" :class="holidayModal.form.pauses_delivery ? 'bg-error-opacity-10 border-error' : ''">
                    <div>
                        <div class="font-weight-bold text-body-2 text-uppercase" :class="holidayModal.form.pauses_delivery ? 'text-error' : ''">Pausa Expedição?</div>
                        <div class="text-[10px] opacity-70">Caminhão não sairá neste dia.</div>
                    </div>
                    <v-switch v-model="holidayModal.form.pauses_delivery" color="error" hide-details density="compact" inset></v-switch>
                </div>
            </v-card-text>
            <div class="pa-4 border-t d-flex justify-end gap-3" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5' : 'bg-white-05'">
                <v-btn variant="text" @click="holidayModal.show = false" class="font-weight-bold px-4 btn-rect" height="44">Cancelar</v-btn>
                <v-btn :color="holidayModal.isEdit ? 'orange-darken-3' : 'indigo-darken-3'" variant="flat" @click="saveHoliday" class="font-weight-bold px-8 btn-rect" height="44">Confirmar</v-btn>
            </div>
        </v-card>
    </v-dialog>

    <v-dialog v-model="customScheduleModal.show" max-width="500" persistent>
        <v-card class="card-rect border-thin shadow-xl" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-grey-darken-4'">
            <div class="bg-teal-darken-3 px-6 py-4 text-white font-weight-bold d-flex justify-space-between align-center">
                <span class="text-uppercase tracking-tight"><v-icon start>mdi-account-clock</v-icon> {{ customScheduleModal.isEdit ? 'Editar Horário' : 'Novo Horário Individual' }}</span>
                <v-btn icon="mdi-close" variant="text" density="compact" @click="customScheduleModal.show = false"></v-btn>
            </div>
            <v-card-text class="pa-6">
                <label class="input-label">Selecione o Colaborador *</label>
                <v-autocomplete v-model="customScheduleModal.form.userId" :items="safeUserList" item-title="full_name" item-value="id" variant="outlined" density="comfortable" class="ui-field mb-5" :disabled="customScheduleModal.isEdit" placeholder="Buscar usuário..." :bg-color="themeStore.currentMode === 'light' ? 'grey-lighten-5' : 'rgba(0,0,0,0.2)'"></v-autocomplete>

                <v-row dense class="mb-2">
                    <v-col cols="6">
                        <label class="input-label text-success">Entrada</label>
                        <v-text-field v-model="customScheduleModal.form.startTime" type="time" variant="outlined" density="comfortable" class="ui-field font-weight-black font-mono" :bg-color="themeStore.currentMode === 'light' ? 'white' : 'transparent'"></v-text-field>
                    </v-col>
                    <v-col cols="6">
                        <label class="input-label text-error">Saída</label>
                        <v-text-field v-model="customScheduleModal.form.endTime" type="time" variant="outlined" density="comfortable" class="ui-field font-weight-black font-mono" :bg-color="themeStore.currentMode === 'light' ? 'white' : 'transparent'"></v-text-field>
                    </v-col>
                </v-row>
                <v-row dense>
                    <v-col cols="6">
                        <label class="input-label text-warning">Início Almoço</label>
                        <v-text-field v-model="customScheduleModal.form.lunchStartTime" type="time" variant="outlined" density="comfortable" class="ui-field font-weight-bold font-mono" :bg-color="themeStore.currentMode === 'light' ? 'white' : 'transparent'"></v-text-field>
                    </v-col>
                    <v-col cols="6">
                        <label class="input-label text-warning">Fim Almoço</label>
                        <v-text-field v-model="customScheduleModal.form.lunchEndTime" type="time" variant="outlined" density="comfortable" class="ui-field font-weight-bold font-mono" :bg-color="themeStore.currentMode === 'light' ? 'white' : 'transparent'"></v-text-field>
                    </v-col>
                </v-row>
            </v-card-text>
            <div class="pa-4 border-t d-flex justify-end gap-3" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5' : 'bg-white-05'">
                <v-btn variant="text" @click="customScheduleModal.show = false" class="font-weight-bold px-4 btn-rect" height="44">Cancelar</v-btn>
                <v-btn color="teal-darken-3" variant="flat" @click="saveCustomSchedule" class="font-weight-bold px-8 btn-rect" height="44">Salvar Horário</v-btn>
            </div>
        </v-card>
    </v-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, computed, reactive } from 'vue';
import { supabase } from '@/api/supabase';
import { useAppStore } from '@/stores/app';
import { useThemeStore } from '@/stores/theme';
import { format, parseISO, isValid } from 'date-fns';

const appStore = useAppStore();
const themeStore = useThemeStore();

const activeTab = ref('logistics'); // 'logistics' ou 'workload'
const saving = ref(false);
const loadingData = ref(true);

const searchHoliday = ref('');
const userList = ref<any[]>([]);

// Propriedade Segura para a lista de usuários
const safeUserList = computed(() => {
    return Array.isArray(userList.value) ? userList.value : [];
});

// Gerador Seguro de IDs Únicos nativo do JS
const generateSafeId = () => {
    try {
        return Date.now().toString(36) + Math.random().toString(36).substring(2, 8);
    } catch(e) {
        return Math.floor(Math.random() * 10000000).toString();
    }
};

// --- ESTADO LOGÍSTICA ---
const settings = reactive({
    productionLeadTime: 4,
    allowedDeliveryDays: [2, 4, 6] // Terça, Quinta, Sábado
});

const weekDays = [
    { label: 'Dom', value: 0 },
    { label: 'Seg', value: 1 },
    { label: 'Ter', value: 2 },
    { label: 'Qua', value: 3 },
    { label: 'Qui', value: 4 },
    { label: 'Sex', value: 5 },
    { label: 'Sáb', value: 6 }
];

const holidays = ref<any[]>([]);
const holidayModal = reactive({
    show: false,
    isEdit: false,
    form: { id: '', date: '', reason: '', pauses_production: true, pauses_delivery: true }
});

const filteredHolidays = computed(() => {
    try {
        const list = Array.isArray(holidays.value) ? holidays.value : [];
        if (!searchHoliday.value) return list;
        const term = searchHoliday.value.toLowerCase();
        return list.filter(h => h && h.reason && h.reason.toLowerCase().includes(term));
    } catch(e) {
        return [];
    }
});

// --- ESTADO JORNADA ---
const workSettings = reactive({
    globalStartTime: '08:00',
    globalEndTime: '18:00',
    lunchStartTime: '12:00',
    lunchEndTime: '13:00',
    requireOvertimeApproval: true,
    customSchedules: [] as any[]
});

const customScheduleModal = reactive({
    show: false,
    isEdit: false,
    form: { userId: '', startTime: '08:00', endTime: '18:00', lunchStartTime: '12:00', lunchEndTime: '13:00' }
});

const safeCustomSchedules = computed(() => {
    return Array.isArray(workSettings.customSchedules) ? workSettings.customSchedules : [];
});

// --- INIT & CARREGAMENTO DE DADOS (BANCO REAL) ---
const loadAllSettings = async () => {
    loadingData.value = true;
    try {
        const { data: users, error: uErr } = await supabase.from('profiles').select('id, full_name').order('full_name');
        if (users && !uErr) userList.value = users;

        const { data, error: cErr } = await supabase.from('app_config').select('key, value').in('key', ['delivery_settings', 'delivery_exceptions', 'work_schedule_settings']);

        if (data && !cErr) {
            const delSet = data.find(d => d.key === 'delivery_settings');
            if (delSet && delSet.value) {
                settings.productionLeadTime = Number(delSet.value.productionLeadTime) || 4;
                settings.allowedDeliveryDays = Array.isArray(delSet.value.allowedDeliveryDays) ? delSet.value.allowedDeliveryDays : [2, 4, 6];
            }

            const delExc = data.find(d => d.key === 'delivery_exceptions');
            if (delExc && delExc.value) {
                holidays.value = Array.isArray(delExc.value) ? delExc.value : [];
            }

            const workSet = data.find(d => d.key === 'work_schedule_settings');
            if (workSet && workSet.value) {
                Object.assign(workSettings, workSet.value);
                if (!Array.isArray(workSettings.customSchedules)) {
                    workSettings.customSchedules = [];
                }
            }
        }
    } catch (e) {
        console.error("Erro ao carregar configurações:", e);
    } finally {
        loadingData.value = false;
    }
};

// --- AÇÕES GLOBAIS (SALVAR TUDO) ---
const saveGlobalSettings = async () => {
    saving.value = true;
    try {
        const payload = [
            { key: 'delivery_settings', value: { productionLeadTime: settings.productionLeadTime, allowedDeliveryDays: settings.allowedDeliveryDays } },
            { key: 'delivery_exceptions', value: holidays.value },
            { key: 'work_schedule_settings', value: {
                globalStartTime: workSettings.globalStartTime,
                globalEndTime: workSettings.globalEndTime,
                lunchStartTime: workSettings.lunchStartTime,
                lunchEndTime: workSettings.lunchEndTime,
                requireOvertimeApproval: workSettings.requireOvertimeApproval,
                customSchedules: workSettings.customSchedules
            }}
        ];

        const { error } = await supabase.from('app_config').upsert(payload, { onConflict: 'key' });
        if (error) throw error;

        try { await appStore.fetchDeliveryConfig(); } catch(e){}

        appStore.showSnackbar('Todas as regras foram salvas com sucesso!', 'success');
    } catch (e) {
        console.error(e);
        appStore.showSnackbar('Erro ao salvar as regras no banco.', 'error');
    } finally {
        saving.value = false;
    }
};

// --- LÓGICA LOGÍSTICA ---
const isDeliveryDayAllowed = (dayValue: number) => {
    try {
        if (!Array.isArray(settings.allowedDeliveryDays)) return false;
        return settings.allowedDeliveryDays.includes(dayValue);
    } catch(e) {
        return false;
    }
};

const toggleDeliveryDay = (dayValue: number) => {
    try {
        if (!Array.isArray(settings.allowedDeliveryDays)) {
            settings.allowedDeliveryDays = [];
        }
        const index = settings.allowedDeliveryDays.indexOf(dayValue);
        if (index === -1) {
            settings.allowedDeliveryDays.push(dayValue);
            settings.allowedDeliveryDays.sort();
        } else {
            settings.allowedDeliveryDays.splice(index, 1);
        }
    } catch(e) {
        console.error(e);
    }
};

const openHolidayModal = (item: any = null, isClone = false) => {
    try {
        if (item) {
            holidayModal.isEdit = !isClone;
            holidayModal.form = {
                id: isClone ? generateSafeId() : item.id,
                date: item.date || '',
                reason: isClone ? `${item.reason || ''} (Cópia)` : (item.reason || ''),
                pauses_production: !!item.pauses_production,
                pauses_delivery: !!item.pauses_delivery
            };
        } else {
            holidayModal.isEdit = false;
            holidayModal.form = { id: generateSafeId(), date: '', reason: '', pauses_production: true, pauses_delivery: true };
        }
        holidayModal.show = true;
    } catch(e) {
        appStore.showSnackbar('Erro ao abrir modal.', 'error');
    }
};

const saveHoliday = () => {
    try {
        if (!holidayModal.form.date || !holidayModal.form.reason) return appStore.showSnackbar('Preencha os dados obrigatórios.', 'warning');

        if (!Array.isArray(holidays.value)) holidays.value = [];

        if (holidayModal.isEdit) {
            const idx = holidays.value.findIndex(h => h.id === holidayModal.form.id);
            if (idx > -1) holidays.value[idx] = { ...holidayModal.form };
        } else {
            holidays.value.push({ ...holidayModal.form });
        }

        holidays.value.sort((a, b) => {
            const da = a.date ? new Date(a.date).getTime() : 0;
            const db = b.date ? new Date(b.date).getTime() : 0;
            return da - db;
        });

        holidayModal.show = false;
        appStore.showSnackbar('Exceção adicionada. Salve as alterações para fixar no banco.', 'info');
    } catch(e) {
        appStore.showSnackbar('Erro ao salvar exceção.', 'error');
    }
};

const deleteHoliday = (id: string) => {
    try {
        if(!confirm("Remover esta exceção logística?")) return;
        if (Array.isArray(holidays.value)) {
            holidays.value = holidays.value.filter(h => h.id !== id);
            appStore.showSnackbar('Removido localmente. Salve as alterações.', 'info');
        }
    } catch(e) {
        console.error(e);
    }
};

const safeArrayLength = (arr: any) => {
    return Array.isArray(arr) ? arr.length : 0;
};

// --- LÓGICA JORNADA INDIVIDUAL ---
const openCustomScheduleModal = (item: any = null) => {
    try {
        if (item) {
            customScheduleModal.isEdit = true;
            customScheduleModal.form = { ...item };
        } else {
            customScheduleModal.isEdit = false;
            customScheduleModal.form = { userId: '', startTime: '08:00', endTime: '18:00', lunchStartTime: '12:00', lunchEndTime: '13:00' };
        }
        customScheduleModal.show = true;
    } catch(e) {
        console.error(e);
    }
};

const saveCustomSchedule = () => {
    try {
        if (!customScheduleModal.form.userId) return appStore.showSnackbar('Selecione um colaborador.', 'warning');
        if (!Array.isArray(workSettings.customSchedules)) workSettings.customSchedules = [];

        const idx = workSettings.customSchedules.findIndex(c => c.userId === customScheduleModal.form.userId);

        if (customScheduleModal.isEdit && idx > -1) {
            workSettings.customSchedules[idx] = { ...customScheduleModal.form };
        } else {
            if (idx > -1) return appStore.showSnackbar('Este usuário já possui uma exceção. Edite a existente.', 'error');
            workSettings.customSchedules.push({ ...customScheduleModal.form });
        }
        customScheduleModal.show = false;
        appStore.showSnackbar('Horário configurado localmente. Salve as alterações.', 'info');
    } catch(e) {
        console.error(e);
    }
};

const deleteCustomSchedule = (userId: string) => {
    try {
        if(!confirm("Remover o horário personalizado deste usuário?")) return;
        if (Array.isArray(workSettings.customSchedules)) {
            workSettings.customSchedules = workSettings.customSchedules.filter(c => c.userId !== userId);
            appStore.showSnackbar('Removido. Salve as alterações.', 'info');
        }
    } catch(e) {
        console.error(e);
    }
};

const getUserNameSafe = (id: string) => {
    try {
        if (!Array.isArray(userList.value)) return 'Desconhecido';
        const user = userList.value.find(u => u.id === id);
        return user && user.full_name ? user.full_name : 'Desconhecido';
    } catch (e) {
        return 'Erro';
    }
};

const getUserInitial = (id: string) => {
    const name = getUserNameSafe(id);
    return name && name.length > 0 ? name.charAt(0).toUpperCase() : 'U';
};

// Utils
const formatDateSafe = (isoStr: string) => {
    if(!isoStr) return '-';
    try {
        const d = parseISO(isoStr);
        if(isValid(d)) return format(d, 'dd/MM/yyyy');
        return '-';
    } catch(e) {
        return '-';
    }
};

const zebraClass = (i: number) => {
    if (themeStore.currentMode === 'light') return i % 2 === 0 ? 'zebra-light-a' : 'zebra-light-b';
    return i % 2 === 0 ? 'zebra-dark-a' : 'zebra-dark-b';
};

onMounted(() => {
    loadAllSettings();
});
</script>

<style scoped lang="scss">
/* Layout Geral da Tela - Agora com comportamento Flex normal, escapando dos bugs de absolute e margin negativa */
.productivity-layout {
    height: 100%;
    width: 100%;
    display: flex;
    flex-direction: column;
}

.min-h-100 { min-height: 100%; }

.background-carousel-wrapper { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 0; opacity: 0.6; pointer-events: none; }
.background-overlay { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 1; background: radial-gradient(circle at center, rgba(15, 15, 19, 0.4), rgba(15, 15, 19, 0.98)); backdrop-filter: blur(8px); }
.z-10 { position: relative; z-index: 10; }
.z-20 { position: relative; z-index: 20; }

.bg-glass-dark { background: rgba(10,10,12,0.85); }
.bg-glass-header { background: rgba(20,20,24,0.55); backdrop-filter: blur(14px); }
.border-bottom-white-05 { border-bottom: 1px solid rgba(255,255,255,0.08); }
.border-thin { border: 1px solid rgba(0,0,0,0.08); }
.bg-white-05 { background: rgba(255,255,255,0.05); }

.glass-card { background: rgba(30, 30, 35, 0.45); backdrop-filter: blur(25px); border: 1px solid rgba(255,255,255,0.08); }

/* FORÇANDO BORDAS QUADRADAS (SHARP EDGES) EM TUDO NESTA TELA */
:deep(.v-card) { border-radius: 0 !important; }
:deep(.v-btn) { border-radius: 0 !important; text-transform: none !important; }
:deep(.v-text-field .v-field__outline) { border-radius: 0 !important; }
:deep(.v-select .v-field__outline) { border-radius: 0 !important; }
:deep(.v-autocomplete .v-field__outline) { border-radius: 0 !important; }
:deep(.v-chip) { border-radius: 0 !important; }
:deep(.v-avatar) { border-radius: 0 !important; }
:deep(.v-dialog > .v-overlay__content > .v-card) { border-radius: 0 !important; }

.btn-rect { font-weight: 800; letter-spacing: 0.5px; }
.card-rect { border-radius: 0 !important; }
.avatar-rect { border-radius: 0 !important; }

/* SIDEBAR SETTINGS STYLE */
.settings-sidebar { width: 280px; min-width: 280px; max-width: 280px; }
.settings-nav-item {
    display: flex; align-items: center; gap: 14px; padding: 12px 14px;
    cursor: pointer; transition: all 0.2s ease;
    border: 1px solid transparent; margin-bottom: 8px;
    border-radius: 0;
}
.settings-nav-item:hover { background: rgba(128,128,128,0.1); }
.settings-nav-item.active-nav { background: #E3F2FD; border-color: #90CAF9; }
.settings-nav-item.active-nav.dark-mode { background: rgba(25, 118, 210, 0.2); border-color: rgba(25, 118, 210, 0.4); }

.nav-icon { display: flex; align-items: center; justify-content: center; width: 36px; height: 36px; background: rgba(128,128,128,0.1); border-radius: 0; }
.active-nav .nav-icon { background: #1976D2; color: white; }
.nav-text { display: flex; flex-direction: column; }
.nav-title { font-size: 13px; font-weight: 900; line-height: 1.2; text-transform: uppercase; }
.nav-subtitle { font-size: 10px; opacity: 0.6; line-height: 1.2; margin-top: 2px; }

/* Banners / Alerts */
.info-banner { border-left: 4px solid currentColor; border-radius: 0; }

/* Formulários */
.input-label { font-size: 10px; font-weight: 900; text-transform: uppercase; opacity: 0.7; margin-bottom: 6px; display: block; letter-spacing: 0.5px;}
.field-hint { font-size: 11px; opacity: 0.7; line-height: 1.3; }

/* Controles e Busca */
.controls-bar { border: 1px solid rgba(0,0,0,0.08); padding: 10px; }
.controls-light { background: #ffffff; }
.controls-dark { background: rgba(30,30,35,0.55); backdrop-filter: blur(16px); border: 1px solid rgba(255,255,255,0.08); }
.search-wrap { height: 40px; padding: 0 12px; min-width: 250px; max-width: 350px; }
.search-light { background: #f4f6f8; border: 1px solid rgba(0,0,0,0.08); }
.search-dark { background: rgba(255,255,255,0.08); border: 1px solid rgba(255,255,255,0.10); }
.clean-input { border: none; outline: none; background: transparent; font-size: 13px; color: inherit; padding: 0; }

/* Grid System Nativo */
.grid-scroll { scrollbar-gutter: stable both-edges; }
.custom-scroll::-webkit-scrollbar { width: 8px; height: 8px; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.35); border-radius: 0; }
.custom-scroll::-webkit-scrollbar-track { background: transparent; }

.grid-header, .grid-row { display: flex; align-items: stretch; width: 100%; min-width: 800px; border-bottom: 1px solid rgba(0,0,0,0.08); }
.cell { padding: 8px 12px; display: flex; align-items: center; border-right: 1px solid rgba(0,0,0,0.08); min-height: 48px; overflow: hidden; }
.center { justify-content: center; text-align: center; }

.grid-header .cell { min-height: 40px; font-size: 11px; font-weight: 900; text-transform: uppercase; letter-spacing: .6px; opacity: 0.8; }
.header-text { font-size: 11px; opacity: 0.9; }

.grid-surface-light .cell { background: #f5f7fa; color: rgba(0,0,0,0.7); border-color: rgba(0,0,0,0.10); }
.grid-surface-dark .cell { background: rgba(255,255,255,0.08); color: rgba(255,255,255,0.80); border-color: rgba(255,255,255,0.10); }

.zebra-light-a .cell { background: #ffffff; border-color: rgba(0,0,0,0.08); }
.zebra-light-b .cell { background: #fafafa; border-color: rgba(0,0,0,0.08); }
.grid-row-light:hover .cell { background: #f7fafc !important; }

.zebra-dark-a .cell { background: rgba(255,255,255,0.04); border-color: rgba(255,255,255,0.08); }
.zebra-dark-b .cell { background: rgba(255,255,255,0.015); border-color: rgba(255,255,255,0.08); }
.grid-row-dark:hover .cell { background: rgba(255,255,255,0.07) !important; }

.sticky-head { position: sticky; top: 0; z-index: 10; }

/* Utils & Buttons */
.pill-ref { font-size: 12px; font-weight: 900; font-family: monospace; background: rgba(0,0,0,0.06); padding: 4px 8px; }
.actions-inline { display: flex; align-items: center; justify-content: center; gap: 6px; }
.action-btn { width: 32px !important; height: 32px !important; color: #fff !important; }
.action-btn :deep(.v-icon) { color: #fff !important; }
.action-delete { background: #e53935 !important; }
.action-edit { background: #fb8c00 !important; }

.bg-error-opacity-10 { background-color: rgba(var(--v-theme-error), 0.1) !important; }
.bg-warning-opacity-10 { background-color: rgba(var(--v-theme-warning), 0.1) !important; }
.animate-fade-in { animation: fadeIn 0.3s ease-in-out forwards; }
@keyframes fadeIn { from { opacity: 0; transform: translateY(10px); } to { opacity: 1; transform: translateY(0); } }
.tracking-tight { letter-spacing: -0.5px !important; }

/* KPI Cards Customizados para aba Logsítica */
.kpi-card { border: 1px solid rgba(255,255,255,0.15); overflow: hidden; }
.bg-gradient-blue { background: linear-gradient(135deg, #1976D2, #0D47A1); color:white; }
.bg-gradient-green { background: linear-gradient(135deg, #2e7d32, #1b5e20); color:white;}
.bg-gradient-purple { background: linear-gradient(135deg, #7b1fa2, #4a148c); color:white;}
.kpi-bg-icon { position: absolute; right: -10px; bottom: -20px; opacity: 0.15; transform: rotate(-15deg); pointer-events: none; z-index: 0; }
.kpi-bg-icon .v-icon { font-size: 100px; color: white; }
</style>
