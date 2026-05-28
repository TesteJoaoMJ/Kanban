<template>
  <div
    class="design-clients-layout font-sans fill-height d-flex flex-column relative overflow-hidden"
    :class="isDark ? 'text-white' : 'text-grey-darken-4'"
  >
    <div class="flex-shrink-0 mb-4 d-flex align-center justify-space-between">
      <v-btn-toggle v-model="mainView" mandatory density="comfortable" class="border-thin bg-transparent" :color="isDark ? 'white' : 'primary'">
        <v-btn value="vip" class="text-caption font-weight-black px-6">
          <v-icon start size="16">mdi-crown-outline</v-icon> Estúdio VIP & Cofre
        </v-btn>
        <v-btn value="pilots" class="text-caption font-weight-black px-6">
          <v-icon start size="16">mdi-flask-outline</v-icon> Produção de Pilotos
        </v-btn>
        <v-btn value="transactions" class="text-caption font-weight-black px-6">
          <v-icon start size="16">mdi-cash-register</v-icon> Caixa & Transações
        </v-btn>
      </v-btn-toggle>

      <v-btn
        variant="flat"
        class="btn-3d text-white"
        height="36"
        color="grey-darken-3"
        @click="handleRefresh"
        title="Sincronizar Dados"
      >
        <v-icon start size="16">mdi-refresh</v-icon> Atualizar
      </v-btn>
    </div>

    <template v-if="mainView === 'vip'">
      <div class="flex-shrink-0 mb-4">
        <v-row dense>
          <v-col cols="12" sm="4" v-for="(kpi, idx) in kpiList" :key="idx">
            <v-card
              class="kpi-card kpi-rect hover-elevate py-3 px-4 cursor-default"
              :class="kpi.gradient"
              elevation="2"
            >
              <div class="kpi-bg-icon"><v-icon>{{ kpi.icon }}</v-icon></div>
              <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                <div class="d-flex align-center" style="gap: 8px;">
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

      <div class="flex-shrink-0 mb-4">
        <div
          class="controls-bar d-flex flex-column flex-md-row align-start align-md-center justify-space-between rounded"
          :class="isDark ? 'controls-dark' : 'controls-light'"
          style="gap: 10px;"
        >
          <div class="d-flex align-center flex-wrap gap-2">
            <v-btn-toggle v-model="statusFilter" density="compact" mandatory class="border-thin bg-transparent" :color="isDark ? 'white' : 'primary'">
              <v-btn value="all" class="text-caption font-weight-bold px-4">Todos</v-btn>
              <v-btn value="pending" class="text-caption font-weight-bold px-4 text-warning">Pendentes</v-btn>
              <v-btn value="granted" class="text-caption font-weight-bold px-4 text-success">Ativos</v-btn>
            </v-btn-toggle>
          </div>

          <div class="d-flex align-center border-thin rounded px-3" style="height: 32px;" :class="isDark ? 'bg-black-20 border-white-10' : 'bg-grey-lighten-5 border-grey-lighten-2'">
              <span class="text-[10px] font-weight-black text-uppercase letter-spacing-1 mr-3" :class="requireVipPermission ? (isDark ? 'text-teal-accent-4' : 'text-teal-darken-3') : 'text-warning'">
                {{ requireVipPermission ? 'VIP EXIGIDO' : 'ACESSO PÚBLICO' }}
              </span>
              <v-switch
                v-model="requireVipPermission"
                color="teal-darken-3"
                density="compact"
                hide-details
                inset
                class="compact-switch"
                @change="toggleVipRequirement"
              ></v-switch>
            </div>

          <div class="d-flex align-center flex-wrap justify-end flex-grow-1 flex-md-grow-0" style="gap: 10px;">
            <div class="search-wrap d-flex align-center rounded border" :class="isDark ? 'search-dark border-white-10' : 'search-light bg-white'" style="height: 36px; min-width: 300px;">
              <v-icon size="small" class="ml-3 mr-2" :color="isDark ? 'white-70' : 'grey-darken-1'">mdi-magnify</v-icon>
              <input
                v-model="searchQuery"
                type="text"
                placeholder="Buscar cliente por nome ou e-mail..."
                class="clean-input flex-grow-1 pr-3 font-weight-bold"
                :class="isDark ? 'text-white' : 'text-grey-darken-4'"
              />
            </div>
          </div>
        </div>
      </div>

      <div class="flex-grow-1 overflow-hidden d-flex flex-column pb-2">
        <v-card
          class="flex-grow-1 d-flex flex-column rounded-0 border-thin overflow-hidden"
          :class="isDark ? 'glass-card border-white-05' : 'bg-white shadow-sm'"
          :elevation="0"
        >
          <div class="grid-scroll flex-grow-1 overflow-auto custom-scroll relative">
            <div
              class="grid-header sticky-head"
              :class="[isDark ? 'grid-surface-dark border-bottom-white-05' : 'grid-surface-light border-b border-grey-lighten-2']"
              style="grid-template-columns: 2fr 1.5fr 100px 140px 140px;"
            >
              <div class="cell header-text pl-4">Cliente / Identificação</div>
              <div class="cell header-text">Credencial (E-mail)</div>
              <div class="cell center header-text">Entregas</div>
              <div class="cell center header-text">Status Acesso</div>
              <div class="cell center header-text">Ações</div>
            </div>

            <div v-if="filteredLeads.length === 0" class="d-flex flex-column justify-center align-center h-100 opacity-60 gap-2 py-10 min-w-full">
              <v-icon size="48" color="grey-lighten-1">mdi-account-filter-outline</v-icon>
              <span class="text-body-2 font-weight-medium text-grey">Nenhum registro encontrado para este filtro.</span>
            </div>

            <div
              v-else
              v-for="(lead, index) in filteredLeads"
              :key="lead.id"
              class="grid-row group transition-all"
              :class="[
                isDark ? 'grid-row-dark' : 'grid-row-light',
                zebraClass(index),
                lead.design_access_status === 'pending' ? (isDark ? 'bg-warning-darken-4-alpha' : 'bg-warning-lighten-5') : ''
              ]"
              style="grid-template-columns: 2fr 1.5fr 100px 140px 140px;"
            >
              <div class="cell pl-4">
                <div class="d-flex align-center gap-3 w-100 overflow-hidden">
                  <v-avatar :color="lead.design_access_status === 'pending' ? 'warning' : (isDark ? 'teal-accent-4' : 'teal-darken-3')" variant="tonal" size="32" class="rounded-md font-weight-black text-caption flex-shrink-0">
                    {{ lead.name ? lead.name[0].toUpperCase() : 'C' }}
                  </v-avatar>
                  <div class="d-flex flex-column min-w-0">
                    <span class="text-truncate list-text-11 font-weight-bold" :title="lead.name">{{ lead.name || 'Cliente Sem Nome' }}</span>
                    <span v-if="lead.design_access_status === 'pending'" class="text-[9px] font-weight-black text-warning text-uppercase letter-spacing-1 mt-0.5">Solicita Acesso</span>
                  </div>
                </div>
              </div>

              <div class="cell">
                <div class="d-flex align-center gap-2 overflow-hidden w-100">
                  <v-icon size="14" class="opacity-50 flex-shrink-0">mdi-email-outline</v-icon>
                  <span class="text-truncate list-text-11 font-mono opacity-80" :title="lead.email">{{ lead.email }}</span>
                </div>
              </div>

              <div class="cell center">
                <v-chip size="small" variant="tonal" :color="getDeliveryCount(lead.email) > 0 ? (isDark ? 'blue-lighten-2' : 'blue-darken-2') : 'grey'" class="font-weight-black font-mono px-3">
                  {{ getDeliveryCount(lead.email) }}
                </v-chip>
              </div>

              <div class="cell center">
                <span class="solid-chip chip-status chip-3d cursor-default" :class="lead.design_access_status === 'pending' ? 'chip-warn' : (lead.design_access_status === 'granted' ? 'chip-success' : 'chip-danger')">
                  <v-icon start size="12">{{ lead.design_access_status === 'pending' ? 'mdi-clock-outline' : (lead.design_access_status === 'granted' ? 'mdi-shield-check' : 'mdi-cancel') }}</v-icon>
                  {{ lead.design_access_status === 'pending' ? 'Pendente' : (lead.design_access_status === 'granted' ? 'Autorizado' : 'Revogado') }}
                </span>
              </div>

              <div class="cell center">
                <div class="actions-inline">
                  <template v-if="lead.design_access_status === 'pending'">
                    <v-btn icon size="small" class="action-btn action-pay btn-3d" title="Aprovar VIP" variant="flat" @click="grantAccess(lead.id)">
                      <v-icon size="16">mdi-check</v-icon>
                    </v-btn>
                    <v-btn icon size="small" class="action-btn action-del btn-3d" title="Recusar" variant="flat" @click="denyAccess(lead.id)">
                      <v-icon size="16">mdi-close</v-icon>
                    </v-btn>
                  </template>

                  <template v-else>
                    <v-btn
                      v-if="lead.design_access_status === 'granted'"
                      icon size="small" class="action-btn action-del btn-3d" title="Revogar VIP" variant="flat"
                      @click="revokeAccess(lead.id)"
                    >
                      <v-icon size="16">mdi-shield-remove-outline</v-icon>
                    </v-btn>

                    <v-btn
                      icon size="small" class="action-btn bg-indigo-darken-2 btn-3d" title="Abrir Acervo do Cliente" variant="flat"
                      @click="openLibraryDrawer(lead)"
                    >
                      <v-icon size="16">mdi-folder-image</v-icon>
                    </v-btn>
                  </template>
                </div>
              </div>
            </div>
          </div>

          <div class="flex-shrink-0 border-t px-4 py-2 d-flex align-center justify-space-between z-20" :class="isDark ? 'bg-surface-variant border-top-white-05' : 'bg-grey-lighten-4'">
            <div class="text-caption font-weight-bold opacity-80">
              Mostrando <strong>{{ filteredLeads.length }}</strong> registros de clientes
            </div>
          </div>
        </v-card>
      </div>
    </template>


    <template v-else-if="mainView === 'pilots'">
      <div class="flex-grow-1 overflow-hidden d-flex flex-column pb-2">

        <div class="d-flex align-center justify-space-between px-2 mb-4">
           <h2 class="text-h6 font-weight-black">Quadro de Solicitações</h2>
           <div class="d-flex gap-3 align-center">

             <v-btn
               v-if="selectedPilotsToGroup.length > 1"
               color="success"
               variant="flat"
               class="btn-3d font-weight-black text-none animate-bounce"
               @click="generateGroupedPix"
             >
               <v-icon start>mdi-qrcode-plus</v-icon> Gerar PIX Agrupado ({{ selectedPilotsToGroup.length }})
             </v-btn>

             <v-btn-toggle v-model="pilotViewMode" density="compact" mandatory class="border-thin bg-transparent" :color="isDark ? 'white' : 'primary'">
               <v-btn value="kanban" title="Visão Kanban"><v-icon size="18">mdi-view-column</v-icon></v-btn>
               <v-btn value="grid" title="Visão Tabela"><v-icon size="18">mdi-view-list</v-icon></v-btn>
             </v-btn-toggle>

             <v-btn color="primary" class="btn-3d font-weight-black text-none" @click="openNewPilotModal">
               <v-icon start>mdi-plus</v-icon> Novo Piloto Manual
             </v-btn>
           </div>
        </div>

        <div v-if="isLoadingPilots" class="d-flex flex-column align-center justify-center w-100 h-100 opacity-60 gap-3">
           <v-progress-circular indeterminate color="primary" size="48"></v-progress-circular>
           <span class="text-caption font-weight-bold font-mono">Buscando pilotos do sistema...</span>
        </div>

        <div v-else-if="pilotViewMode === 'kanban'" class="kanban-board w-100 h-100 d-flex gap-4 overflow-x-auto custom-scroll px-1 pb-2">

          <div class="kanban-col d-flex flex-column">
            <div class="kanban-col-header" :class="isDark ? 'bg-warning-darken-4 text-warning-lighten-2 border-b border-warning-darken-2' : 'bg-warning-lighten-4 text-warning-darken-4 border-b border-warning-lighten-2'">
               <v-icon size="16" class="mr-2">mdi-cash-clock</v-icon> Aguardando Pag.
               <span class="count-badge ml-auto bg-warning text-white">{{ pilotsPending.length }}</span>
            </div>
            <div class="kanban-col-body custom-scroll">
               <div v-for="pilot in pilotsPending" :key="pilot.id" class="kanban-card shadow-sm border-thin" :class="isDark ? 'bg-grey-darken-4 border-white-10' : 'bg-white border-grey-lighten-2'">
                  <div class="d-flex align-center justify-space-between mb-2">
                    <div class="d-flex align-center gap-2">
                      <v-avatar size="24" :color="pilot.customer_mj_id ? 'indigo' : 'primary'" variant="tonal" class="text-[10px] font-weight-black">{{ getPilotClientName(pilot)[0] }}</v-avatar>
                      <span class="text-caption font-weight-bold text-truncate" style="max-width: 140px;">{{ getPilotClientName(pilot) }}</span>
                    </div>
                    <v-chip v-if="pilot.representative_request" size="x-small" color="success" variant="flat" class="px-1" title="Criado por Representante">
                      <v-icon size="12">mdi-account-tie</v-icon>
                    </v-chip>
                  </div>

                  <div class="kanban-card-mid rounded pa-2 d-flex gap-2" :class="isDark ? 'bg-grey-darken-3' : 'bg-grey-lighten-4'">
                    <img :src="getPilotStampImage(pilot)" class="mid-img cursor-pointer hover-elevate" @click="openImage(getPilotStampImage(pilot))" />
                    <div class="mid-info">
                      <span class="mid-title">{{ getPilotStampTitle(pilot) }}</span>
                      <span class="mid-ref">Ref: {{ pilot.stamp?.ref_code || 'CUSTOM' }}</span>
                    </div>
                  </div>

                  <div class="d-flex justify-space-between align-center mt-2">
                    <span class="text-[10px] font-weight-bold opacity-70"><v-icon size="12" class="mr-1">mdi-texture</v-icon>{{ pilot.fabric?.name || 'Tecido' }} ({{ pilot.quantity_meters }}m)</span>
                    <span class="text-caption font-weight-black text-primary">R$ {{ formatPrice(pilot.amount) }}</span>
                  </div>

                  <div class="kanban-card-actions mt-3 pt-2 border-t d-flex flex-wrap gap-2" :class="isDark ? 'border-white-10' : 'border-grey-lighten-2'">
                    <v-btn size="x-small" color="success" variant="tonal" class="font-weight-bold flex-grow-1" @click="changePilotStatus(pilot.id, 'paid')">Aprovar Pagamento</v-btn>
                    <v-btn size="x-small" color="teal" variant="flat" class="font-weight-bold btn-3d px-2" @click="openPixModal(pilot)" title="Copiar PIX"><v-icon size="14">mdi-qrcode</v-icon></v-btn>
                    <v-btn size="x-small" color="error" variant="text" icon="mdi-cancel" @click="changePilotStatus(pilot.id, 'canceled')" title="Cancelar"></v-btn>
                  </div>
               </div>
               <div v-if="pilotsPending.length === 0" class="empty-col">Nenhum piloto aqui</div>
            </div>
          </div>

          <div class="kanban-col d-flex flex-column">
            <div class="kanban-col-header" :class="isDark ? 'bg-info-darken-4 text-info-lighten-2 border-b border-info-darken-2' : 'bg-info-lighten-4 text-info-darken-4 border-b border-info-lighten-2'">
               <v-icon size="16" class="mr-2">mdi-list-status</v-icon> Fila de Produção
               <span class="count-badge ml-auto bg-info text-white">{{ pilotsPaid.length }}</span>
            </div>
            <div class="kanban-col-body custom-scroll">
               <div v-for="pilot in pilotsPaid" :key="pilot.id" class="kanban-card shadow-sm border-thin" :class="isDark ? 'bg-grey-darken-4 border-white-10' : 'bg-white border-grey-lighten-2'">
                  <div class="d-flex align-center justify-space-between mb-2">
                    <div class="d-flex align-center gap-2">
                      <v-avatar size="24" :color="pilot.customer_mj_id ? 'indigo' : 'info'" variant="tonal" class="text-[10px] font-weight-black">{{ getPilotClientName(pilot)[0] }}</v-avatar>
                      <span class="text-caption font-weight-bold text-truncate" style="max-width: 140px;">{{ getPilotClientName(pilot) }}</span>
                    </div>
                  </div>

                  <div class="kanban-card-mid rounded pa-2 d-flex gap-2" :class="isDark ? 'bg-grey-darken-3' : 'bg-grey-lighten-4'">
                    <img :src="getPilotStampImage(pilot)" class="mid-img cursor-pointer hover-elevate" @click="openImage(getPilotStampImage(pilot))" />
                    <div class="mid-info">
                      <span class="mid-title">{{ getPilotStampTitle(pilot) }}</span>
                      <span class="mid-ref">Ref: {{ pilot.stamp?.ref_code || 'CUSTOM' }}</span>
                    </div>
                  </div>

                  <div class="d-flex justify-space-between align-center mt-2">
                    <span class="text-[10px] font-weight-bold opacity-70"><v-icon size="12" class="mr-1">mdi-texture</v-icon>{{ pilot.fabric?.name || 'Tecido' }} ({{ pilot.quantity_meters }}m)</span>
                    <span class="text-caption font-weight-black text-primary">R$ {{ formatPrice(pilot.amount) }}</span>
                  </div>

                  <div class="kanban-card-actions mt-3 pt-2 border-t" :class="isDark ? 'border-white-10' : 'border-grey-lighten-2'">
                    <v-btn size="x-small" color="primary" variant="tonal" class="font-weight-bold flex-grow-1" @click="changePilotStatus(pilot.id, 'in_production')">Iniciar Produção</v-btn>
                  </div>
               </div>
               <div v-if="pilotsPaid.length === 0" class="empty-col">Nenhum piloto aqui</div>
            </div>
          </div>

          <div class="kanban-col d-flex flex-column">
            <div class="kanban-col-header" :class="isDark ? 'bg-primary-darken-4 text-primary-lighten-2 border-b border-primary-darken-2' : 'bg-primary-lighten-4 text-primary-darken-4 border-b border-primary-lighten-2'">
               <v-icon size="16" class="mr-2">mdi-printer-3d</v-icon> Em Produção
               <span class="count-badge ml-auto bg-primary text-white">{{ pilotsProducing.length }}</span>
            </div>
            <div class="kanban-col-body custom-scroll">
               <div v-for="pilot in pilotsProducing" :key="pilot.id" class="kanban-card shadow-sm border-thin" :class="isDark ? 'bg-grey-darken-4 border-white-10' : 'bg-white border-grey-lighten-2'" style="border-left: 4px solid rgb(var(--v-theme-primary)) !important;">
                  <div class="d-flex align-center justify-space-between mb-2">
                    <div class="d-flex align-center gap-2">
                      <v-avatar size="24" :color="pilot.customer_mj_id ? 'indigo' : 'primary'" variant="tonal" class="text-[10px] font-weight-black">{{ getPilotClientName(pilot)[0] }}</v-avatar>
                      <span class="text-caption font-weight-bold text-truncate" style="max-width: 140px;">{{ getPilotClientName(pilot) }}</span>
                    </div>
                  </div>

                  <div class="kanban-card-mid rounded pa-2 d-flex gap-2" :class="isDark ? 'bg-grey-darken-3' : 'bg-grey-lighten-4'">
                    <img :src="getPilotStampImage(pilot)" class="mid-img cursor-pointer hover-elevate" @click="openImage(getPilotStampImage(pilot))" />
                    <div class="mid-info">
                      <span class="mid-title">{{ getPilotStampTitle(pilot) }}</span>
                      <span class="mid-ref">Ref: {{ pilot.stamp?.ref_code || 'CUSTOM' }}</span>
                    </div>
                  </div>

                  <div class="d-flex justify-space-between align-center mt-2">
                    <span class="text-[10px] font-weight-bold opacity-70"><v-icon size="12" class="mr-1">mdi-texture</v-icon>{{ pilot.fabric?.name || 'Tecido' }} ({{ pilot.quantity_meters }}m)</span>
                  </div>

                  <div class="kanban-card-actions mt-3 pt-2 border-t" :class="isDark ? 'border-white-10' : 'border-grey-lighten-2'">
                    <v-btn size="x-small" color="purple" variant="tonal" class="font-weight-bold flex-grow-1" @click="changePilotStatus(pilot.id, 'shipped')">Despachar (Enviado)</v-btn>
                  </div>
               </div>
               <div v-if="pilotsProducing.length === 0" class="empty-col">Nenhum piloto aqui</div>
            </div>
          </div>

          <div class="kanban-col d-flex flex-column">
            <div class="kanban-col-header" :class="isDark ? 'bg-success-darken-4 text-success-lighten-2 border-b border-success-darken-2' : 'bg-success-lighten-4 text-success-darken-4 border-b border-success-lighten-2'">
               <v-icon size="16" class="mr-2">mdi-check-all</v-icon> Finalizados
               <span class="count-badge ml-auto bg-success text-white">{{ pilotsDone.length }}</span>
            </div>
            <div class="kanban-col-body custom-scroll">
               <div v-for="pilot in pilotsDone" :key="pilot.id" class="kanban-card shadow-sm border-thin opacity-80" :class="isDark ? 'bg-grey-darken-4 border-white-10' : 'bg-white border-grey-lighten-2'" style="border-left: 4px solid #10b981 !important;">
                  <div class="d-flex align-center justify-space-between mb-2">
                    <div class="d-flex align-center gap-2">
                      <v-avatar size="24" :color="pilot.customer_mj_id ? 'indigo' : 'success'" variant="tonal" class="text-[10px] font-weight-black">{{ getPilotClientName(pilot)[0] }}</v-avatar>
                      <span class="text-caption font-weight-bold text-truncate" style="max-width: 140px;">{{ getPilotClientName(pilot) }}</span>
                    </div>
                    <v-chip size="x-small" :color="pilot.status === 'delivered' ? 'success' : 'purple'" variant="flat" class="px-1 text-[9px] font-weight-bold">
                       {{ pilot.status === 'delivered' ? 'Entregue' : 'Enviado' }}
                    </v-chip>
                  </div>

                  <div class="kanban-card-mid rounded pa-2 d-flex gap-2" :class="isDark ? 'bg-grey-darken-3' : 'bg-grey-lighten-4'">
                    <img :src="getPilotStampImage(pilot)" class="mid-img cursor-pointer hover-elevate" @click="openImage(getPilotStampImage(pilot))" />
                    <div class="mid-info">
                      <span class="mid-title">{{ getPilotStampTitle(pilot) }}</span>
                    </div>
                  </div>

                  <div v-if="pilot.status === 'shipped'" class="kanban-card-actions mt-3 pt-2 border-t" :class="isDark ? 'border-white-10' : 'border-grey-lighten-2'">
                    <v-btn size="x-small" color="success" variant="text" class="font-weight-bold flex-grow-1" @click="changePilotStatus(pilot.id, 'delivered')">Marcar Entregue</v-btn>
                  </div>
               </div>
               <div v-if="pilotsDone.length === 0" class="empty-col">Nenhum piloto aqui</div>
            </div>
          </div>

        </div>

        <v-card v-else class="flex-grow-1 d-flex flex-column rounded-0 border-thin overflow-hidden mx-1" :class="isDark ? 'glass-card border-white-05' : 'bg-white shadow-sm'" elevation="0">
            <div class="controls-bar pa-3 border-b d-flex gap-3 align-center" :class="isDark ? 'bg-grey-darken-4 border-white-05' : 'bg-grey-lighten-5 border-grey-lighten-2'">
               <div class="search-wrap d-flex align-center rounded border bg-white" style="height: 36px; max-width: 300px;">
                  <v-icon size="small" class="ml-3 mr-2 text-grey-darken-1">mdi-magnify</v-icon>
                  <input v-model="pilotGridSearch" type="text" placeholder="Filtrar piloto..." class="clean-input flex-grow-1 font-weight-bold text-grey-darken-4" />
               </div>
               <v-btn-toggle v-model="pilotGridStatusFilter" density="compact" mandatory class="border bg-white" color="primary">
                  <v-btn value="all" class="text-caption font-weight-bold px-3">Todos</v-btn>
                  <v-btn value="pending_payment" class="text-caption font-weight-bold px-3 text-warning">Pendente (PIX)</v-btn>
                  <v-btn value="in_production" class="text-caption font-weight-bold px-3 text-info">Produzindo</v-btn>
               </v-btn-toggle>
            </div>

            <div class="grid-scroll flex-grow-1 overflow-auto custom-scroll">
                <div class="grid-header sticky-head" :class="isDark ? 'grid-surface-dark border-bottom-white-05' : 'grid-surface-light border-b border-grey-lighten-2'" style="grid-template-columns: 50px 80px 2fr 2fr 150px 100px 140px 180px;">
                    <div class="cell center pl-2" style="width: 50px;">
                        <v-icon size="16" class="opacity-50">mdi-check-all</v-icon>
                    </div>
                    <div class="cell center header-text pl-2">ID</div>
                    <div class="cell header-text">Cliente</div>
                    <div class="cell header-text">Estampa / Arte</div>
                    <div class="cell center header-text">Tecido</div>
                    <div class="cell center header-text">Valor</div>
                    <div class="cell center header-text">Status</div>
                    <div class="cell center header-text">Ações</div>
                </div>

                <div v-if="filteredGridPilots.length === 0" class="pa-10 text-center opacity-60">Nenhum piloto atende aos filtros.</div>

                <div v-else v-for="(pilot, index) in filteredGridPilots" :key="pilot.id" class="grid-row group transition-all" :class="[isDark ? 'grid-row-dark' : 'grid-row-light', zebraClass(index)]" style="grid-template-columns: 50px 80px 2fr 2fr 150px 100px 140px 180px;">

                    <div class="cell center" style="width: 50px;">
                        <v-checkbox
                          v-if="pilot.status === 'pending_payment'"
                          v-model="selectedPilotsToGroup"
                          :value="pilot"
                          hide-details
                          density="compact"
                          color="success"
                        ></v-checkbox>
                    </div>

                    <div class="cell center font-mono text-[10px] font-weight-bold opacity-70">{{ pilot.id.substring(0,6).toUpperCase() }}</div>

                    <div class="cell">
                        <div class="d-flex align-center gap-2">
                           <v-avatar size="24" :color="pilot.customer_mj_id ? 'indigo' : 'primary'" variant="tonal" class="text-[10px] font-weight-black">{{ getPilotClientName(pilot)[0] }}</v-avatar>
                           <span class="text-truncate text-body-2 font-weight-bold">{{ getPilotClientName(pilot) }}</span>
                        </div>
                    </div>

                    <div class="cell">
                        <div class="d-flex align-center gap-2">
                           <v-img :src="getPilotStampImage(pilot)" width="28" height="28" cover class="rounded cursor-pointer border" @click.stop="openImageModal(getPilotStampImage(pilot), 'Arte do Piloto')"></v-img>
                           <div class="d-flex flex-column lh-1">
                              <span class="text-[11px] font-weight-bold text-truncate" style="max-width:180px;">{{ getPilotStampTitle(pilot) }}</span>
                              <span class="text-[9px] opacity-70 font-mono mt-0.5">Ref: {{ pilot.stamp?.ref_code || 'CUSTOM' }}</span>
                           </div>
                        </div>
                    </div>

                    <div class="cell center text-[11px] font-weight-bold opacity-80">{{ pilot.fabric?.name || '-' }} ({{ pilot.quantity_meters }}m)</div>
                    <div class="cell center text-body-2 font-weight-black text-primary">R$ {{ formatPrice(pilot.amount) }}</div>

                    <div class="cell center">
                        <v-chip size="small" variant="tonal" :color="getPilotStatusColor(pilot.status)" class="font-weight-black text-[10px] px-2 chip-3d">
                            {{ getPilotStatusLabel(pilot.status) }}
                        </v-chip>
                    </div>

                    <div class="cell center">
                        <div class="actions-inline">
                            <template v-if="pilot.status === 'pending_payment'">
                                <v-btn icon size="small" class="action-btn bg-teal-darken-1 btn-3d" title="Ver PIX Copia e Cola" @click="openPixModal(pilot)">
                                    <v-icon size="16">mdi-qrcode</v-icon>
                                </v-btn>
                                <v-btn icon size="small" class="action-btn action-pay btn-3d" title="Aprovar Pagamento Manual" @click="changePilotStatus(pilot.id, 'paid')">
                                    <v-icon size="16">mdi-check</v-icon>
                                </v-btn>
                            </template>
                            <template v-else-if="pilot.status === 'paid'">
                                <v-btn size="x-small" color="primary" variant="flat" class="font-weight-bold btn-3d px-2" @click="changePilotStatus(pilot.id, 'in_production')">
                                    <v-icon start size="14">mdi-printer-3d</v-icon> Produzir
                                </v-btn>
                            </template>
                            <template v-else-if="pilot.status === 'in_production'">
                                <v-btn size="x-small" color="purple" variant="flat" class="font-weight-bold btn-3d px-2" @click="changePilotStatus(pilot.id, 'shipped')">
                                    <v-icon start size="14">mdi-truck-delivery</v-icon> Enviar
                                </v-btn>
                            </template>
                        </div>
                    </div>
                </div>
            </div>
        </v-card>
      </div>
    </template>

    <template v-else-if="mainView === 'transactions'">
      <div class="flex-grow-1 overflow-hidden d-flex flex-column pb-2">
        <div class="d-flex align-center justify-space-between px-2 mb-4">
           <h2 class="text-h6 font-weight-black d-flex align-center gap-2">
             <v-icon color="success">mdi-safe</v-icon> Histórico de Transações dos Pilotos
           </h2>
        </div>

        <v-card class="flex-grow-1 d-flex flex-column rounded-0 border-thin overflow-hidden mx-1" :class="isDark ? 'glass-card border-white-05' : 'bg-white shadow-sm'" elevation="0">
            <div v-if="isLoadingTransactions" class="d-flex flex-column justify-center align-center h-100 opacity-60">
                <v-progress-circular indeterminate color="success"></v-progress-circular>
                <span class="mt-2 text-caption font-weight-bold">Lendo o livro caixa...</span>
            </div>
            <div class="grid-scroll flex-grow-1 overflow-auto custom-scroll" v-else>
                <div class="grid-header sticky-head" :class="isDark ? 'grid-surface-dark border-bottom-white-05' : 'grid-surface-light border-b border-grey-lighten-2'" style="grid-template-columns: 150px 180px 2fr 150px 2fr;">
                    <div class="cell center header-text pl-2">Data / Hora</div>
                    <div class="cell center header-text">Ação Executada</div>
                    <div class="cell header-text">Cliente (Origem do Piloto)</div>
                    <div class="cell center header-text">Valor Movimentado</div>
                    <div class="cell header-text">Responsável / Log</div>
                </div>

                <div v-if="transactions.length === 0" class="pa-10 text-center opacity-60">Nenhuma transação registrada no caixa dos pilotos.</div>

                <div v-else v-for="(txn, index) in transactions" :key="txn.id" class="grid-row group transition-all" :class="[isDark ? 'grid-row-dark' : 'grid-row-light', zebraClass(index)]" style="grid-template-columns: 150px 180px 2fr 150px 2fr;">
                    <div class="cell center flex-column align-center justify-center lh-1">
                        <span class="text-[11px] font-weight-bold">{{ formatDateSimple(txn.created_at) }}</span>
                        <span class="text-[9px] font-mono opacity-60 mt-1">{{ formatTimeOnly(txn.created_at) }}</span>
                    </div>

                    <div class="cell center">
                        <v-chip size="small" variant="tonal" :color="getTxnColor(txn.action)" class="font-weight-black text-[10px] px-2 chip-3d">
                            <v-icon start size="12">{{ getTxnIcon(txn.action) }}</v-icon>
                            {{ getTxnLabel(txn.action) }}
                        </v-chip>
                    </div>

                    <div class="cell">
                        <div class="d-flex align-center gap-2">
                           <v-avatar size="24" :color="txn.pilot?.customer_mj_id ? 'indigo' : 'primary'" variant="tonal" class="text-[10px] font-weight-black">{{ getTransactionClientName(txn)[0] }}</v-avatar>
                           <div class="d-flex flex-column lh-1">
                               <span class="text-truncate text-body-2 font-weight-bold" style="max-width: 200px;">{{ getTransactionClientName(txn) }}</span>
                               <span class="text-[9px] font-mono opacity-60 mt-0.5 text-uppercase">PILOTO: {{ txn.pilot_id?.substring(0,8) }}</span>
                           </div>
                        </div>
                    </div>

                    <div class="cell center text-body-2 font-weight-black" :class="txn.action === 'canceled' ? 'text-error text-decoration-line-through' : 'text-success'">
                        R$ {{ formatPrice(txn.amount) }}
                    </div>

                    <div class="cell">
                        <div class="d-flex flex-column lh-1 w-100">
                            <span class="text-[11px] font-weight-bold text-truncate"><v-icon size="12" class="mr-1 opacity-50">mdi-account</v-icon>{{ txn.user?.full_name || 'Sistema / Auto' }}</span>
                            <span v-if="txn.details?.pix_code" class="text-[9px] font-mono opacity-60 mt-1 text-truncate" title="Código PIX rastreado">PIX ID: {{ txn.details.payment_id || 'Gerado' }}</span>
                            <span v-if="txn.details?.manual_update" class="text-[9px] font-mono opacity-60 mt-1 text-warning">BAIXA MANUAL DE CAIXA</span>
                            <span v-if="txn.details?.grouped_generation" class="text-[9px] font-mono opacity-60 mt-1 text-info">PIX AGRUPADO MÚLTIPLO</span>
                        </div>
                    </div>
                </div>
            </div>
            <div class="flex-shrink-0 border-t px-4 py-2 d-flex align-center justify-space-between z-20" :class="isDark ? 'bg-surface-variant border-top-white-05' : 'bg-grey-lighten-4'">
                <div class="text-caption font-weight-bold opacity-80">Mostrando <strong>{{ transactions.length }}</strong> registros de caixa.</div>
            </div>
        </v-card>
      </div>
    </template>

    <v-navigation-drawer
      v-model="drawerOpen"
      location="right"
      temporary
      width="650"
      :class="isDark ? 'bg-grey-darken-4 border-l border-white-10' : 'bg-grey-lighten-5'"
      elevation="24"
    >
      <div class="d-flex flex-column h-100 relative">

        <div class="px-6 py-5 border-b flex-shrink-0 d-flex align-center justify-space-between" :class="isDark ? 'bg-grey-darken-3 border-white-10' : 'bg-white shadow-sm'">
          <div class="d-flex align-center gap-4">
             <v-avatar :color="isDark ? 'indigo-accent-2' : 'indigo-darken-3'" size="48" class="rounded-xl shadow-sm">
               <v-icon color="white" size="24">mdi-safe</v-icon>
             </v-avatar>
             <div class="lh-1">
               <div class="text-[10px] font-weight-black text-uppercase opacity-60 letter-spacing-1 mb-1">Acervo do Cofre VIP</div>
               <h3 class="text-h6 font-weight-black leading-none text-truncate" style="max-width: 400px;">
                 {{ selectedLead?.name || 'Cliente' }}
               </h3>
             </div>
          </div>
          <v-btn icon="mdi-close" variant="tonal" size="small" class="btn-3d" :color="isDark ? 'white' : 'grey-darken-3'" @click="drawerOpen = false"></v-btn>
        </div>

        <div class="flex-grow-1 overflow-y-auto custom-scroll pa-8 bg-texture position-relative">

          <div v-if="Object.keys(groupedDeliveries).length === 0" class="d-flex flex-column align-center justify-center h-100 opacity-60 text-center">
            <v-icon size="72" class="mb-4 opacity-50">mdi-image-search-outline</v-icon>
            <h4 class="text-subtitle-1 font-weight-black">O Cofre está vazio</h4>
            <p class="text-caption mt-1 mx-auto" style="max-width: 300px;">
              Este cliente ainda não possui artes finalizadas e entregues através do Kanban de Design.
            </p>
          </div>

          <div v-else class="timeline-container">
            <div v-for="(arts, dateGroup) in groupedDeliveries" :key="dateGroup" class="timeline-group mb-12">

              <div class="d-flex align-center mb-6 sticky-date">
                <div class="text-[11px] font-weight-black text-uppercase letter-spacing-1 px-4 py-1.5 rounded-pill shadow-sm border" :class="isDark ? 'bg-indigo-darken-4 text-indigo-lighten-4 border-indigo-darken-3' : 'bg-indigo-lighten-5 text-indigo-darken-4 border-indigo-lighten-4'">
                  <v-icon start size="12">mdi-calendar-blank</v-icon> {{ dateGroup }}
                </div>
                <div class="flex-grow-1 ml-4 line-separator" :class="isDark ? 'bg-white-10' : 'bg-grey-lighten-3'"></div>
              </div>

              <v-row dense class="mx-n2">
                <v-col cols="12" sm="6" v-for="arte in arts" :key="arte.id" class="pa-2">
                  <div class="library-card-3d relative rounded-xl overflow-hidden cursor-pointer" :class="isDark ? 'bg-black border-white-10' : 'bg-white border-grey-lighten-2'" @click="openImage(arte.file_url)">

                    <div class="position-relative w-100 bg-surface-variant" style="aspect-ratio: 1/1;">
                      <v-img :src="arte.file_url" cover class="w-100 h-100 transition-transform img-zoom"></v-img>

                      <div class="position-absolute top-0 left-0 w-100 h-100 bg-gradient-to-t from-black-80 to-transparent pointer-events-none"></div>

                      <div class="position-absolute top-0 left-0 w-100 pa-3 d-flex justify-space-between align-start z-10 pointer-events-none">
                        <span class="text-[10px] font-mono font-weight-bold text-white bg-black-50 px-2 py-1 rounded backdrop-blur border border-white-10 shadow-sm">
                          ID: {{ arte.design_request_id }}
                        </span>
                        <v-chip size="x-small" :color="isArteExpired(arte) ? 'error' : 'success'" variant="flat" class="font-weight-black text-[9px] px-2 h-auto py-1 shadow-sm text-uppercase letter-spacing-1">
                          {{ isArteExpired(arte) ? 'Expirada' : 'Ativa' }}
                        </v-chip>
                      </div>

                      <div class="hover-action-overlay position-absolute top-0 left-0 w-100 h-100 d-flex flex-column align-center justify-center gap-3 backdrop-blur-sm z-20">
                        <v-btn size="small" color="white" variant="flat" class="btn-3d font-weight-black text-indigo-darken-4 w-75 shadow-lg" @click.stop="openImage(arte.file_url)">
                          <v-icon start size="16">mdi-magnify-plus-outline</v-icon> Visualizar
                        </v-btn>

                        <div class="d-flex gap-2 w-75">
                          <v-btn v-if="isArteExpired(arte)" size="small" color="success" class="btn-3d flex-grow-1 font-weight-bold" @click.stop="restoreVisibility(arte.id)" title="Renovar acesso por +24h">
                            <v-icon start size="14">mdi-refresh</v-icon> Renovar
                          </v-btn>
                          <v-btn size="small" color="error" class="btn-3d flex-grow-1 font-weight-bold" @click.stop="revokeArte(arte.id)" title="Apagar do Cofre">
                            <v-icon start size="14">mdi-trash-can-outline</v-icon> Excluir
                          </v-btn>
                        </div>
                      </div>
                    </div>

                    <div class="pa-3 d-flex align-center justify-space-between border-t" :class="isDark ? 'bg-surface-variant border-white-10' : 'bg-grey-lighten-5 border-grey-lighten-2'">
                      <div class="d-flex flex-column lh-1">
                        <span class="text-[9px] font-weight-black text-uppercase opacity-50 letter-spacing-1 mb-0.5">Válido até</span>
                        <span class="text-[11px] font-mono font-weight-black" :class="isArteExpired(arte) ? 'text-error' : (isDark ? 'text-white' : 'text-grey-darken-4')">
                          {{ formatTimeOnly(arte.expires_at) }}
                        </span>
                      </div>
                      <v-btn icon size="x-small" variant="tonal" class="btn-3d" color="primary" @click.stop="window.open(arte.file_url, '_blank')" title="Baixar Original">
                        <v-icon size="14">mdi-download</v-icon>
                    </v-btn>
                    </div>

                  </div>
                </v-col>
              </v-row>
            </div>
          </div>
        </div>

      </div>
    </v-navigation-drawer>

    <v-dialog v-model="showPilotModal" max-width="700" persistent>
      <v-card class="rounded-xl border shadow-lg" :class="isDark ? 'bg-grey-darken-4 border-white-10 text-white' : 'bg-white border-grey-lighten-2 text-grey-darken-4'">
        <div class="px-6 py-4 border-b d-flex align-center justify-space-between" :class="isDark ? 'border-white-10' : 'border-grey-lighten-2'">
           <h3 class="text-h6 font-weight-black d-flex align-center">
             <v-icon color="primary" class="mr-2">mdi-flask-plus</v-icon>
             Nova Solicitação de Piloto
           </h3>
           <v-btn icon="mdi-close" variant="text" size="small" @click="showPilotModal = false" :disabled="isGeneratingAdminPix"></v-btn>
        </div>

        <div class="pa-6">
           <div v-if="isLoadingPilotResources" class="d-flex flex-column align-center justify-center py-6">
             <v-progress-circular indeterminate color="primary" size="40"></v-progress-circular>
             <span class="text-caption font-weight-bold mt-2">Carregando catálogo e bases...</span>
           </div>

           <template v-else>
<div v-if="pilotGeneratedResult" class="text-center py-4 animation-slide-up">
                <v-icon size="64" color="success" class="mb-2">mdi-check-circle</v-icon>
                <h4 class="text-h5 font-weight-black text-success mb-2">Pedido de Pilotos Criado!</h4>
                <p class="text-body-2 mb-4" :class="isDark ? 'text-grey-lighten-1' : 'text-grey-darken-1'">O agrupamento foi finalizado e o PIX oficial foi gerado no caixa.</p>

                <div class="bg-white pa-4 rounded-lg d-inline-block mx-auto mb-4 shadow-sm border border-grey-lighten-2">
                    <QrcodeVue :value="pilotGeneratedResult.copyPaste" :size="200" level="M" />
                </div>

                <v-btn block color="teal-darken-1" size="large" class="btn-3d font-weight-black text-white mb-6" @click="copyPixCode(pilotGeneratedResult.copyPaste)">
                   <v-icon start>mdi-content-copy</v-icon> Copiar PIX Copia e Cola
                </v-btn>

                <div class="border rounded-xl pa-4 text-left mb-6" :class="isDark ? 'bg-grey-darken-3 border-white-10' : 'bg-grey-lighten-5 border-grey-lighten-2'">
                  <div class="text-[10px] font-weight-bold text-uppercase mb-1" :class="isDark ? 'text-grey-lighten-1' : 'text-grey-darken-1'">Cliente</div>
                  <div class="font-weight-black text-body-1 mb-3">{{ pilotGeneratedResult.leadName }}</div>

                  <div class="text-[10px] font-weight-bold text-uppercase mb-1" :class="isDark ? 'text-grey-lighten-1' : 'text-grey-darken-1'">Itens do Pedido</div>
                  <ul class="mb-3 pl-4">
                    <li v-for="(item, i) in pilotGeneratedResult.items" :key="i" class="text-body-2 mb-1">
                      <strong>{{ item.stampName }}</strong> — {{ item.fabricName }} ({{ item.qty }}m)
                    </li>
                  </ul>

                  <div class="text-[10px] font-weight-bold text-uppercase mb-1" :class="isDark ? 'text-grey-lighten-1' : 'text-grey-darken-1'">Valor Total</div>
                  <div class="font-weight-black text-primary text-h6">R$ {{ formatPrice(pilotGeneratedResult.totalAmount) }}</div>
                </div>

                <v-btn block color="primary" size="x-large" class="btn-3d font-weight-black mb-3" @click="copyWhatsAppMessage">
                   <v-icon start>mdi-whatsapp</v-icon> Copiar para WhatsApp
                </v-btn>
                <v-btn block variant="tonal" class="font-weight-bold" @click="showPilotModal = false">Concluir</v-btn>
             </div>

             <v-form v-else @submit.prevent="createAdminPilot">
                <div class="d-flex flex-column gap-4">

                  <div class="border-b pb-4 mb-2" :class="isDark ? 'border-white-10' : 'border-grey-lighten-2'">
                    <label class="text-[11px] font-weight-bold text-uppercase letter-spacing-1 d-block mb-3 text-primary">1. Seleção do Cliente</label>
                    <v-radio-group v-model="pilotForm.clientType" inline density="compact" hide-details class="mb-3">
                      <v-radio label="Cliente do ERP (MJ)" value="erp" color="primary"></v-radio>
                      <v-radio label="Lead do E-commerce" value="lead" color="primary"></v-radio>
                    </v-radio-group>

                    <v-autocomplete
                      v-if="pilotForm.clientType === 'lead'"
                      v-model="pilotForm.leadId"
                      :items="props.leads"
                      item-title="name"
                      item-value="id"
                      placeholder="Busque pelo nome ou email (Leads)..."
                      variant="outlined"
                      density="comfortable"
                      :bg-color="isDark ? 'grey-darken-3' : 'white'"
                      hide-details
                      required
                    >
                       <template v-slot:item="{ props, item }">
                         <v-list-item v-bind="props" :title="item.raw.name" :subtitle="item.raw.email"></v-list-item>
                       </template>
                    </v-autocomplete>

                    <v-autocomplete
                      v-else
                      v-model="pilotForm.erpClientId"
                      :items="erpClients"
                      item-title="nome"
                      item-value="id"
                      placeholder="Busque pelo nome ou CNPJ/CPF (ERP)..."
                      variant="outlined"
                      density="comfortable"
                      :bg-color="isDark ? 'grey-darken-3' : 'white'"
                      hide-details
                      required
                    >
                       <template v-slot:item="{ props, item }">
                         <v-list-item v-bind="props" :title="item.raw.nome || item.raw.razao_social" :subtitle="item.raw.cnpj || item.raw.cpf || 'Sem doc'"></v-list-item>
                       </template>
                    </v-autocomplete>
                  </div>

                  <div>
                    <label class="text-[11px] font-weight-bold text-uppercase letter-spacing-1 d-block mb-3 text-primary">2. Estampas do Pedido</label>

                    <div v-for="(item, idx) in pilotForm.items" :key="item.id" class="border rounded-lg pa-4 mb-4 position-relative" :class="isDark ? 'border-white-10 bg-black-20' : 'border-grey-lighten-2 bg-grey-lighten-5'">

                      <div class="d-flex justify-space-between align-center mb-3">
                          <span class="font-weight-black text-caption text-uppercase letter-spacing-1 opacity-70">Item {{ idx + 1 }}</span>
                          <v-btn v-if="pilotForm.items.length > 1" icon="mdi-trash-can-outline" size="x-small" color="error" variant="text" @click="removePilotItem(idx)"></v-btn>
                      </div>

                      <v-radio-group v-model="item.stampSource" inline density="compact" hide-details class="mb-3">
                        <v-radio label="Catálogo" value="catalog" color="primary"></v-radio>
                        <v-radio label="Upload (Cliente)" value="custom" color="primary"></v-radio>
                      </v-radio-group>

                      <v-autocomplete
                        v-if="item.stampSource === 'catalog'"
                        v-model="item.stampId"
                        :items="catalogStamps"
                        item-title="title"
                        item-value="id"
                        placeholder="Selecione a arte..."
                        variant="outlined"
                        density="comfortable"
                        :bg-color="isDark ? 'grey-darken-3' : 'white'"
                        hide-details
                        class="mb-3"
                        required
                      >
                         <template v-slot:item="{ props, item }">
                           <v-list-item v-bind="props">
                              <template v-slot:prepend>
                                <v-avatar size="32" class="mr-3 rounded"><img :src="item.raw.main_image_url" style="object-fit:cover" /></v-avatar>
                              </template>
                              <v-list-item-title class="font-weight-bold">{{ item.raw.title }}</v-list-item-title>
                              <v-list-item-subtitle>Ref: {{ item.raw.ref_code }}</v-list-item-subtitle>
                           </v-list-item>
                         </template>
                      </v-autocomplete>

                      <div v-else class="pa-3 border rounded border-dashed mb-3" :class="isDark ? 'border-white-20 bg-grey-darken-4' : 'border-grey-lighten-1 bg-white'">
                        <v-file-input
                          v-model="item.customStampFile"
                          label="Anexar Arte do Cliente"
                          variant="outlined"
                          density="compact"
                          accept="image/png, image/jpeg, image/jpg, application/pdf"
                          prepend-icon="mdi-cloud-upload"
                          hide-details
                          class="mb-1"
                          required
                        ></v-file-input>
                      </div>

                      <div class="d-flex gap-3 mb-3">
                        <v-autocomplete
                          class="flex-grow-1"
                          v-model="item.fabricId"
                          :items="catalogFabrics"
                          item-title="name"
                          item-value="id"
                          placeholder="Tecido..."
                          variant="outlined"
                          density="comfortable"
                          :bg-color="isDark ? 'grey-darken-3' : 'white'"
                          hide-details
                          required
                        >
                           <template v-slot:item="{ props, item }">
                             <v-list-item v-bind="props" :title="item.raw.name" :subtitle="`R$ ${formatPrice(item.raw.base_price || item.raw.price)}/m`"></v-list-item>
                           </template>
                        </v-autocomplete>

                        <v-text-field
                          style="max-width: 120px;"
                          v-model.number="item.quantity"
                          type="number"
                          min="1"
                          label="Metros"
                          variant="outlined"
                          density="comfortable"
                          :bg-color="isDark ? 'grey-darken-3' : 'white'"
                          hide-details
                          required
                        ></v-text-field>
                      </div>

                      <v-textarea
                          v-model="item.description"
                          label="Observações para a Produção / Design"
                          placeholder="Ex: Escala 15cm, Cores vibrantes..."
                          variant="outlined"
                          density="comfortable"
                          rows="2"
                          auto-grow
                          hide-details
                          :bg-color="isDark ? 'grey-darken-3' : 'white'"
                      ></v-textarea>
                    </div>

                    <v-btn variant="outlined" block class="border-dashed btn-3d font-weight-bold" color="primary" @click="addPilotItem">
                        <v-icon start>mdi-plus</v-icon> Adicionar outra estampa
                    </v-btn>
                  </div>

                </div>

                <div class="mt-6 pt-4 border-t d-flex justify-space-between align-center" :class="isDark ? 'border-white-10' : 'border-grey-lighten-2'">
                   <div class="d-flex flex-column">
                     <span class="text-[10px] font-weight-bold text-uppercase" :class="isDark ? 'text-grey-lighten-1' : 'text-grey-darken-1'">Total a cobrar</span>
                     <span class="text-h6 font-weight-black text-primary">R$ {{ formatPrice(calculateAdminPilotTotal) }}</span>
                   </div>
                   <v-btn type="submit" color="primary" size="large" class="btn-3d font-weight-black" :loading="isGeneratingAdminPix" :disabled="!isFormValid">
                     <v-icon start>mdi-qrcode-scan</v-icon> Gerar Pedido e PIX
                   </v-btn>
                </div>
             </v-form>
           </template>
        </div>
      </v-card>
    </v-dialog>

    <v-dialog v-model="pixModal.show" max-width="400">
        <v-card class="rounded-xl pa-6 text-center shadow-lg border" :class="isDark ? 'bg-grey-darken-4 border-white-10 text-white' : 'bg-white border-grey-lighten-2 text-grey-darken-4'">
            <div class="d-flex align-center justify-space-between mb-4 border-b pb-2" :class="isDark ? 'border-white-10' : 'border-grey-lighten-2'">
               <h3 class="text-h6 font-weight-black text-primary"><v-icon start>mdi-qrcode</v-icon> Pagar Piloto</h3>
               <v-btn icon="mdi-close" variant="text" size="small" @click="pixModal.show = false"></v-btn>
            </div>

            <p class="text-caption font-weight-bold opacity-80 mb-4">Escaneie o código abaixo no app do seu banco ou copie o código Copia e Cola para efetuar o pagamento do piloto.</p>

            <div class="bg-white pa-4 rounded-lg d-inline-block mx-auto mb-6 shadow-sm border border-grey-lighten-2">
                <QrcodeVue :value="pixModal.code" :size="220" level="M" />
            </div>

            <v-btn block color="teal-darken-1" size="large" class="btn-3d font-weight-black text-white" @click="copyPixCode(pixModal.code)">
               <v-icon start>mdi-content-copy</v-icon> Copiar PIX Copia e Cola
            </v-btn>
        </v-card>
    </v-dialog>

    <ImageModal v-model="showImageModal" :imageUrl="selectedImageUrl" />

  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { supabase } from '@/api/supabase'
import { useThemeStore } from '@/stores/theme'
import { useUserStore } from '@/stores/user'
import ImageModal from '@/components/ImageModal.vue'
import QrcodeVue from 'qrcode.vue'
import { coraApi } from '@/api/coraProxy'

const MR_JACKY_CORA_ID = 'int-3VpXneDbEmHHHYFNN8hoIh'

const props = defineProps<{
  leads: any[],
  vaultedDeliveries: any[]
}>()

const emit = defineEmits(['refresh'])
const themeStore = useThemeStore()
const userStore = useUserStore()

const isDark = computed(() => themeStore.currentMode !== 'light')

// ESTADOS E CONTROLES GERAIS
const mainView = ref<'vip' | 'pilots' | 'transactions'>('vip')
const searchQuery = ref('')
const statusFilter = ref<'all' | 'pending' | 'granted'>('all')
const showImageModal = ref(false)
const selectedImageUrl = ref('')
const requireVipPermission = ref(true)

// ESTADOS: PILOTOS
const pilots = ref<any[]>([])
const isLoadingPilots = ref(false)
const pilotViewMode = ref<'kanban' | 'grid'>('kanban')
const pilotGridSearch = ref('')
const pilotGridStatusFilter = ref<'all' | 'pending_payment' | 'in_production'>('all')
const selectedPilotsToGroup = ref<any[]>([]) // MALANDRAGEM: Vetor pra guardar os caras q vão pro mesmo PIX

// ESTADOS: TRANSAÇÕES (NOVO COFRE)
const transactions = ref<any[]>([])
const isLoadingTransactions = ref(false)

// ESTADOS: NOVO PILOTO MANUAL MULTI-ESTAMPA (ADMIN)
const showPilotModal = ref(false)
const isLoadingPilotResources = ref(false)
const catalogStamps = ref<any[]>([])
const catalogFabrics = ref<any[]>([])
const erpClients = ref<any[]>([])
const erpClientsMap = ref<Map<string, string>>(new Map())

const pilotForm = ref({
    clientType: 'erp',
    leadId: null,
    erpClientId: null,
    items: [
      { id: Date.now().toString(), stampSource: 'catalog', stampId: null, customStampFile: null as File | null, fabricId: null, quantity: 1, description: '' }
    ]
})

const isGeneratingAdminPix = ref(false)
const pilotGeneratedResult = ref<any>(null)

// ESTADOS: MODAL DE PIX
const pixModal = ref({ show: false, code: '' })

// ESTADOS: DRAWER VIP
const drawerOpen = ref(false)
const selectedLead = ref<any>(null)

// ==========================================
// CICLO DE VIDA (INIT)
// ==========================================
onMounted(async () => {
  try {
    const { data, error } = await supabase.from('system_settings').select('require_vip_design').single()
    if (data && !error) requireVipPermission.value = data.require_vip_design
  } catch (err) {}

  await fetchErpClients()
  await loadPilots()
})

// Mudar de aba carrega as transações na hora
watch(mainView, async (newVal) => {
    if (newVal === 'transactions' && transactions.value.length === 0) {
        await loadTransactions()
    }
})

async function handleRefresh() {
  emit('refresh')
  await fetchErpClients()
  await loadPilots()
  if (mainView.value === 'transactions') await loadTransactions()
}

async function fetchErpClients() {
    const { data } = await supabase.from('customers_mj').select('id, nome, razao_social, cpf, cnpj').order('nome', { ascending: true })
    if (data) {
        erpClients.value = data;
        erpClientsMap.value = new Map(data.map(c => [c.id, c.nome || c.razao_social || 'Cliente ERP']))
    }
}

// ==========================================
// LÓGICA: PILOTOS (BUSCA E AÇÕES)
// ==========================================
async function loadPilots() {
  isLoadingPilots.value = true
  try {
    const { data, error } = await supabase
      .from('pilot_requests')
      .select('*, stamp:catalog_stamps(title, ref_code, main_image_url), fabric:catalog_fabrics(name), customer_mj:customers_mj(nome, razao_social, cpf, cnpj)')
      .order('created_at', { ascending: false })

    if (data && !error) pilots.value = data
  } catch (err) {
    console.error('Erro ao carregar pilotos', err)
  } finally {
    isLoadingPilots.value = false
  }
}

function getPilotClientName(pilot: any) {
  if (pilot.customer_mj_id) return erpClientsMap.value.get(pilot.customer_mj_id) || 'Cliente ERP'
  const lead = props.leads.find(l => l.id === pilot.user_id)
  return lead?.name || 'Cliente E-commerce'
}

function getPilotStampImage(pilot: any) {
  return pilot.custom_stamp_url || pilot.stamp?.main_image_url || '/placeholder.png'
}

function getPilotStampTitle(pilot: any) {
  if (pilot.custom_stamp_url) return 'Arte Exclusiva do Cliente'
  return pilot.stamp?.title || 'Estampa Padrão'
}

function formatPrice(val: number) {
  return Number(val || 0).toLocaleString('pt-BR', { minimumFractionDigits: 2, maximumFractionDigits: 2 })
}

function getPilotStatusColor(status: string) {
    if (status === 'pending_payment') return 'warning'
    if (status === 'paid') return 'info'
    if (status === 'in_production') return 'primary'
    if (status === 'shipped') return 'purple'
    if (status === 'delivered') return 'success'
    return 'grey'
}

function getPilotStatusLabel(status: string) {
    if (status === 'pending_payment') return 'Aguardando PIX'
    if (status === 'paid') return 'Fila de Produção'
    if (status === 'in_production') return 'Estampando'
    if (status === 'shipped') return 'Enviado'
    if (status === 'delivered') return 'Entregue'
    if (status === 'canceled') return 'Cancelado'
    return status
}

async function changePilotStatus(pilotId: string, newStatus: string) {
  try {
    const { error } = await supabase.from('pilot_requests').update({ status: newStatus }).eq('id', pilotId)
    if (error) throw error

    const pIndex = pilots.value.findIndex(p => p.id === pilotId)
    if (pIndex !== -1) {
      const pilot = pilots.value[pIndex]
      pilot.status = newStatus

      // INSERÇÃO SILENCIOSA NO HISTÓRICO DE TRANSAÇÕES
      let action = ''
      if (newStatus === 'paid') action = 'payment_confirmed'
      else if (newStatus === 'canceled') action = 'canceled'

      if (action) {
          await supabase.from('pilot_transactions').insert({
              pilot_id: pilot.id,
              action: action,
              amount: pilot.amount,
              created_by: userStore.profile?.id,
              details: { manual_update: true }
          })
      }
    }
    if (mainView.value === 'transactions') await loadTransactions()
  } catch (e) {
    alert("Erro ao alterar status do piloto.")
  }
}

// Computed do Kanban
const pilotsPending = computed(() => pilots.value.filter(p => p.status === 'pending_payment'))
const pilotsPaid = computed(() => pilots.value.filter(p => p.status === 'paid'))
const pilotsProducing = computed(() => pilots.value.filter(p => p.status === 'in_production'))
const pilotsDone = computed(() => pilots.value.filter(p => ['shipped', 'delivered'].includes(p.status)))

// Computed da Grid
const filteredGridPilots = computed(() => {
    let result = pilots.value.filter(p => p.status !== 'canceled')

    if (pilotGridStatusFilter.value !== 'all') {
        result = result.filter(p => p.status === pilotGridStatusFilter.value)
    }

    if (pilotGridSearch.value) {
        const q = pilotGridSearch.value.toLowerCase()
        result = result.filter(p =>
            p.id.toLowerCase().includes(q) ||
            getPilotClientName(p).toLowerCase().includes(q) ||
            (p.stamp?.ref_code || '').toLowerCase().includes(q)
        )
    }

    return result.sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime())
})

// ==========================================
// LÓGICA: GERAÇÃO DE PIX AGRUPADO (MALANDRAGEM MÁXIMA)
// ==========================================
async function generateGroupedPix() {
    if (selectedPilotsToGroup.value.length < 2) {
        return alert("Selecione pelo menos 2 pilotos para gerar um PIX agrupado.");
    }

    // Verifica se os clientes são os mesmos
    const firstClient = getPilotClientName(selectedPilotsToGroup.value[0]);
    const allSameClient = selectedPilotsToGroup.value.every(p => getPilotClientName(p) === firstClient);

    if (!allSameClient) {
        return alert("Rapaz, tu não pode agrupar PIX de clientes diferentes! Seleciona pilotos da mesma pessoa.");
    }

    isGeneratingAdminPix.value = true;
    try {
        const totalAmount = selectedPilotsToGroup.value.reduce((acc, p) => acc + (p.amount || 0), 0);
        const amountInCents = Math.round(totalAmount * 100);
        const groupId = crypto.randomUUID();

        const firstPilot = selectedPilotsToGroup.value[0];
        let cleanDocument = '00000000000';

        if (firstPilot.customer_mj_id) {
            const erpClient = erpClients.value.find(c => c.id === firstPilot.customer_mj_id);
            if (erpClient) cleanDocument = (erpClient.cnpj || erpClient.cpf || '00000000000').replace(/\D/g, '');
        } else {
            const lead = props.leads.find(l => l.id === firstPilot.user_id);
            if (lead) cleanDocument = (lead.document || '00000000000').replace(/\D/g, '');
        }

        // Bate na Cora
        const coraResponse = await coraApi.generatePix({
            amount: amountInCents,
            code: `PLT-GRP-${groupId.substring(0,6)}`,
            customer: { name: firstClient, identity: cleanDocument }
        }, MR_JACKY_CORA_ID);

        const qrCodeCopyPaste = coraResponse.emv || coraResponse.payment_options?.pix?.emv || '';
        const coraInvoiceIdStr = coraResponse.id || '';

        if (!qrCodeCopyPaste) throw new Error("Código PIX não retornado pelo gateway.");

        const pilotIds = selectedPilotsToGroup.value.map(p => p.id);

        // Atualiza a galera na tabela
        await supabase.from('pilot_requests').update({
            pix_qr_code: qrCodeCopyPaste,
            payment_id: coraInvoiceIdStr,
            group_id: groupId
        }).in('id', pilotIds);

        // Caixa forte
        const txns = selectedPilotsToGroup.value.map(p => ({
            pilot_id: p.id,
            action: 'pix_generated',
            amount: p.amount,
            created_by: userStore.profile?.id,
            details: { pix_code: qrCodeCopyPaste, payment_id: coraInvoiceIdStr, group_id: groupId, grouped_generation: true }
        }));
        await supabase.from('pilot_transactions').insert(txns);

        // Mostra o modal na cara com o resultado formatado no mesmo jeito da criação
        pilotGeneratedResult.value = {
            copyPaste: qrCodeCopyPaste,
            totalAmount: totalAmount,
            items: selectedPilotsToGroup.value.map(p => ({
                stampName: getPilotStampTitle(p),
                fabricName: p.fabric?.name || '-',
                qty: p.quantity_meters,
                amount: p.amount
            })),
            leadName: firstClient
        };

        showPilotModal.value = true;
        selectedPilotsToGroup.value = []; // Limpa a seleção

        await loadPilots();
        if (mainView.value === 'transactions') await loadTransactions();

    } catch (e: any) {
        alert(`Falha ao gerar o PIX agrupado: ${e.message}`);
    } finally {
        isGeneratingAdminPix.value = false;
    }
}


// ==========================================
// LÓGICA: MODAL DO PIX INDIVIDUAL
// ==========================================
function openPixModal(pilot: any) {
    if (!pilot.pix_qr_code) {
        alert("Nenhum código PIX atrelado a este piloto. Gere um novo pedido manual para forçar.")
        return;
    }
    pixModal.value = { show: true, code: pilot.pix_qr_code }
}

function copyPixCode(code: string) {
    navigator.clipboard.writeText(code).then(() => {
        alert('✅ PIX Copia e Cola enviado para a área de transferência!');
        pixModal.value.show = false;
    });
}

// ==========================================
// LÓGICA: TRANSAÇÕES (CAIXA FORTE)
// ==========================================
async function loadTransactions() {
    isLoadingTransactions.value = true
    try {
        const { data, error } = await supabase
            .from('pilot_transactions')
            .select('*, pilot:pilot_requests(user_id, customer_mj_id, id), user:profiles(full_name)')
            .order('created_at', { ascending: false })
            .limit(500)

        if (data && !error) transactions.value = data
    } catch(e) {
        console.error("Erro ao buscar livro caixa.", e)
    } finally {
        isLoadingTransactions.value = false
    }
}

function getTransactionClientName(txn: any) {
    if (!txn.pilot) return 'Piloto Deletado'
    if (txn.pilot.customer_mj_id) return erpClientsMap.value.get(txn.pilot.customer_mj_id) || 'Cliente ERP'
    const lead = props.leads.find(l => l.id === txn.pilot.user_id)
    return lead?.name || 'Cliente E-commerce'
}

function getTxnColor(action: string) {
    if (action === 'pix_generated') return 'info'
    if (action === 'payment_confirmed') return 'success'
    if (action === 'canceled') return 'error'
    return 'grey'
}

function getTxnIcon(action: string) {
    if (action === 'pix_generated') return 'mdi-qrcode'
    if (action === 'payment_confirmed') return 'mdi-cash-check'
    if (action === 'canceled') return 'mdi-cash-remove'
    return 'mdi-circle-small'
}

function getTxnLabel(action: string) {
    if (action === 'pix_generated') return 'PIX Gerado'
    if (action === 'payment_confirmed') return 'Pagamento Aprovado'
    if (action === 'canceled') return 'Cancelado/Estornado'
    return action
}


// ==========================================
// LÓGICA: GERAÇÃO MANUAL DE PILOTO (MULTI-ESTAMPA)
// ==========================================

function addPilotItem() {
    pilotForm.value.items.push({
        id: Date.now().toString() + Math.random(),
        stampSource: 'catalog',
        stampId: null,
        customStampFile: null,
        fabricId: null,
        quantity: 1,
        description: ''
    });
}

function removePilotItem(idx: number) {
    pilotForm.value.items.splice(idx, 1);
}

const isFormValid = computed(() => {
    const p = pilotForm.value;
    const hasClient = (p.clientType === 'erp' && p.erpClientId) || (p.clientType === 'lead' && p.leadId);
    if (!hasClient || p.items.length === 0) return false;

    for (const item of p.items) {
        const hasStamp = (item.stampSource === 'catalog' && item.stampId) || (item.stampSource === 'custom' && item.customStampFile);
        if (!hasStamp || !item.fabricId || item.quantity <= 0) return false;
    }
    return true;
});

async function openNewPilotModal() {
    showPilotModal.value = true;
    pilotGeneratedResult.value = null;
    pilotForm.value = {
        clientType: 'erp', leadId: null, erpClientId: null,
        items: [{ id: Date.now().toString(), stampSource: 'catalog', stampId: null, customStampFile: null, fabricId: null, quantity: 1, description: '' }]
    };

    if (catalogStamps.value.length === 0 || catalogFabrics.value.length === 0 || erpClients.value.length === 0) {
        isLoadingPilotResources.value = true;
        try {
            const [stampsRes, fabricsRes, clientsRes] = await Promise.all([
                supabase.from('catalog_stamps').select('*').eq('is_active', true).order('created_at', { ascending: false }),
                supabase.from('catalog_fabrics').select('*').eq('is_active', true),
                supabase.from('customers_mj').select('id, nome, razao_social, cpf, cnpj').order('nome', { ascending: true })
            ]);
            catalogStamps.value = stampsRes.data || [];
            catalogFabrics.value = fabricsRes.data || [];
            erpClients.value = clientsRes.data || [];
            erpClientsMap.value = new Map(erpClients.value.map(c => [c.id, c.nome || c.razao_social || 'Cliente ERP']));
        } catch(e) {
            console.error("Erro ao carregar recursos para piloto", e);
        } finally {
            isLoadingPilotResources.value = false;
        }
    }
}

const calculateAdminPilotTotal = computed(() => {
    let total = 0;
    for (const item of pilotForm.value.items) {
        if (item.fabricId) {
            const fabric = catalogFabrics.value.find(f => f.id === item.fabricId);
            if (fabric) {
                total += (fabric.base_price || fabric.price || 0) * (item.quantity || 1);
            }
        }
    }
    return total;
});

async function createAdminPilot() {
    if (!isFormValid.value) {
        alert("Preencha todos os campos obrigatórios em todos os itens.");
        return;
    }

    isGeneratingAdminPix.value = true;
    const createdPilotIds: string[] = [];

    try {
        // 1. Identificar o Cliente
        let leadName = 'Cliente B2B';
        let cleanDocument = '00000000000';
        let finalUserId = null;
        let finalCustomerMjId = null;

        if (pilotForm.value.clientType === 'erp') {
            const erpClient = erpClients.value.find(c => c.id === pilotForm.value.erpClientId);
            if (!erpClient) throw new Error("Cliente ERP não encontrado.");
            leadName = erpClient.nome || erpClient.razao_social || 'Cliente ERP';
            cleanDocument = (erpClient.cnpj || erpClient.cpf || '00000000000').replace(/\D/g, '');
            finalCustomerMjId = erpClient.id;
        } else {
            const lead = props.leads.find(l => l.id === pilotForm.value.leadId);
            if (!lead) throw new Error("Lead não encontrado.");
            leadName = lead.name || 'Cliente Ecommerce';
            cleanDocument = (lead.document || '00000000000').replace(/\D/g, '');
            finalUserId = lead.id;
        }

        // 2. Processar Itens e Criar no Banco (Agrupados por group_id)
        const groupId = crypto.randomUUID();
        let totalAmount = 0;
        const resultItems = [];

        for (const item of pilotForm.value.items) {
            let finalStampId = null;
            let finalCustomStampUrl = null;
            let stampName = 'Arte Exclusiva do Cliente';

            if (item.stampSource === 'catalog') {
                const stamp = catalogStamps.value.find(s => s.id === item.stampId);
                if (!stamp) throw new Error("Estampa do catálogo não encontrada.");
                finalStampId = stamp.id;
                stampName = stamp.title;
            } else {
                const file = item.customStampFile as any;
                if (!file) throw new Error("Arquivo da estampa não selecionado.");

                const actualFile = Array.isArray(file) ? file[0] : file;
                const fileExt = actualFile.name.split('.').pop();
                const fileName = `${Date.now()}-${Math.random().toString(36).substring(2)}.${fileExt}`;

                const { data: uploadData, error: uploadError } = await supabase.storage
                    .from('custom-client-stamps')
                    .upload(fileName, actualFile);

                if (uploadError) throw new Error("Falha ao subir a arte para o servidor.");

                const { data: publicUrlData } = supabase.storage
                    .from('custom-client-stamps')
                    .getPublicUrl(uploadData.path);

                finalCustomStampUrl = publicUrlData.publicUrl;
            }

            const fabric = catalogFabrics.value.find(f => f.id === item.fabricId);
            if (!fabric) throw new Error("Tecido base não encontrado.");

            const itemAmount = (fabric.base_price || fabric.price || 0) * (item.quantity || 1);
            totalAmount += itemAmount;

            // Insere cada piloto
            const { data: pilotRequest, error: dbError } = await supabase
                .from('pilot_requests')
                .insert({
                    user_id: finalUserId,
                    customer_mj_id: finalCustomerMjId,
                    group_id: groupId,
                    stamp_id: finalStampId,
                    custom_stamp_url: finalCustomStampUrl,
                    fabric_id: fabric.id,
                    amount: itemAmount,
                    quantity_meters: item.quantity,
                    notes: item.description, // MALANDRAGEM: Observações salvas
                    status: 'pending_payment',
                    payment_status: 'pending',
                    representative_request: true
                })
                .select()
                .single();

            if (dbError) throw dbError;
            createdPilotIds.push(pilotRequest.id);

            resultItems.push({
                stampName: stampName,
                fabricName: fabric.name,
                qty: item.quantity,
                amount: itemAmount
            });
        }

        // 3. Gerar PIX na Cora (SOMA TOTAL DO GRUPO)
        const amountInCents = Math.round(totalAmount * 100);
        const coraResponse = await coraApi.generatePix({
            amount: amountInCents,
            code: `PLT-${groupId.substring(0,8)}`,
            customer: { name: leadName, identity: cleanDocument }
        }, MR_JACKY_CORA_ID);

        if (!coraResponse) throw new Error('Falha ao gerar PIX na API Cora.');

        const qrCodeCopyPaste = coraResponse.emv || coraResponse.payment_options?.pix?.emv || '';
        const coraInvoiceIdStr = coraResponse.id || '';

        if (!qrCodeCopyPaste) throw new Error("Código PIX não retornado pelo gateway.");

        // 4. Atualizar todos os Pilotos do grupo com o mesmo PIX
        await supabase.from('pilot_requests').update({
            pix_qr_code: qrCodeCopyPaste,
            payment_id: coraInvoiceIdStr
        }).in('id', createdPilotIds);

        // 5. INSERÇÃO NO CAIXA (Uma transação pra cada piloto, pra bater a contabilidade certa)
        const txns = createdPilotIds.map((pid, idx) => ({
            pilot_id: pid,
            action: 'pix_generated',
            amount: resultItems[idx].amount,
            created_by: userStore.profile?.id,
            details: { pix_code: qrCodeCopyPaste, payment_id: coraInvoiceIdStr, group_id: groupId }
        }));
        await supabase.from('pilot_transactions').insert(txns);

        // 6. Mostrar Resultado Final
        pilotGeneratedResult.value = {
            copyPaste: qrCodeCopyPaste,
            totalAmount: totalAmount,
            items: resultItems,
            leadName: leadName
        };

        await loadPilots();
        if (mainView.value === 'transactions') await loadTransactions();

    } catch (e: any) {
        console.error("Erro no Admin Pilot:", e);
        if (createdPilotIds.length > 0) {
             await supabase.from('pilot_requests').delete().in('id', createdPilotIds);
        }
        alert(`Falha ao gerar pilotos e PIX: ${e.message}`);
    } finally {
        isGeneratingAdminPix.value = false;
    }
}

function copyWhatsAppMessage() {
    if (!pilotGeneratedResult.value) return;
    const res = pilotGeneratedResult.value;

    let msg = `*OLÁ, ${res.leadName}! SEU PEDIDO DE PILOTO FOI GERADO.*\n\n`;

    res.items.forEach((it: any, idx: number) => {
        msg += `▪️ *Item ${idx + 1}: ${it.stampName}*\n`;
        msg += `   Tecido: ${it.fabricName}\n`;
        msg += `   Quantidade: ${it.qty} metros\n`;
        msg += `   Valor: R$ ${formatPrice(it.amount)}\n\n`;
    });

    msg += `*TOTAL A PAGAR: R$ ${formatPrice(res.totalAmount)}*\n\n`;
    msg += `*Copie o código PIX abaixo para pagar e liberar seu pedido na fila de produção:*\n\n`;
    msg += `${res.copyPaste}\n\n`;
    msg += `_O recibo será gerado automaticamente no seu painel assim que o banco aprovar._`;

    navigator.clipboard.writeText(msg).then(() => {
        alert('✅ Mensagem com código PIX copiada para a área de transferência! Cole no WhatsApp do cliente.');
    });
}


// ==========================================
// LÓGICA VIP (EXISTENTE)
// ==========================================
async function toggleVipRequirement() {
  try {
    await supabase.from('system_settings').update({ require_vip_design: requireVipPermission.value }).eq('id', 1)
    emit('refresh')
  } catch (err) {
    console.error('Erro ao salvar configuração VIP:', err)
  }
}

const filteredLeads = computed(() => {
  let result = props.leads.filter(l => l.design_access_status !== 'none' || l.design_access_status === null)

  if (statusFilter.value !== 'all') {
    result = result.filter(l => l.design_access_status === statusFilter.value)
  }

  if (searchQuery.value) {
    const s = searchQuery.value.toLowerCase()
    result = result.filter(l =>
      l.name?.toLowerCase().includes(s) ||
      l.email?.toLowerCase().includes(s)
    )
  }

  return result.sort((a, b) => {
    if (a.design_access_status === 'pending' && b.design_access_status !== 'pending') return -1
    if (a.design_access_status !== 'pending' && b.design_access_status === 'pending') return 1
    return (a.name || '').localeCompare(b.name || '')
  })
})

const kpiList = computed(() => {
  const pending = props.leads.filter(l => l.design_access_status === 'pending').length
  const active = props.leads.filter(l => l.design_access_status === 'granted').length
  const deliveries = props.vaultedDeliveries.length

  return [
    { label: 'Solicitações VIP', value: pending, footer: 'Aguardando Aprovação', icon: 'mdi-account-clock', gradient: 'bg-gradient-warning' },
    { label: 'Clientes VIP Ativos', value: active, footer: 'Acesso Liberado', icon: 'mdi-shield-crown', gradient: 'bg-gradient-green' },
    { label: 'Artes no Cofre', value: deliveries, footer: 'Auditoria Total', icon: 'mdi-safe', gradient: 'bg-gradient-purple' }
  ]
})

const groupedDeliveries = computed(() => {
  if (!selectedLead.value) return {}
  const deliveries = props.vaultedDeliveries.filter(d => d.client_email === selectedLead.value.email)

  deliveries.sort((a, b) => new Date(b.delivered_at).getTime() - new Date(a.delivered_at).getTime())

  const groups: Record<string, any[]> = {}
  deliveries.forEach(d => {
    const dateObj = new Date(d.delivered_at)
    const dateStr = dateObj.toLocaleDateString('pt-BR', { day: '2-digit', month: 'long', year: 'numeric' })
    if (!groups[dateStr]) groups[dateStr] = []
    groups[dateStr].push(d)
  })

  return groups
})

function zebraClass(i: number) {
  return isDark.value ? (i % 2 === 0 ? 'zebra-dark-a' : 'zebra-dark-b') : (i % 2 === 0 ? 'zebra-light-a' : 'zebra-light-b')
}

function getDeliveryCount(email: string) {
  return props.vaultedDeliveries.filter(d => d.client_email === email).length
}

function formatTimeOnly(d: string) {
  if (!d) return '--/--'
  const date = new Date(d)
  return `${date.toLocaleDateString('pt-BR')} às ${date.toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' })}`
}

function formatDateSimple(d: string) {
  if (!d) return '--/--'
  return new Date(d).toLocaleDateString('pt-BR')
}

function isArteExpired(a: any) {
  return new Date() > new Date(a.expires_at) && !a.force_visible
}

function openImage(url: string) {
  selectedImageUrl.value = url
  showImageModal.value = true
}

function openImageModal(url: string, name: string = '') {
  selectedImageUrl.value = url
  showImageModal.value = true
}

function openLibraryDrawer(lead: any) {
  selectedLead.value = lead
  drawerOpen.value = true
}

async function grantAccess(id: string) {
  const { error } = await supabase.from('public_leads').update({ design_access_status: 'granted' }).eq('id', id)
  if (error) alert('Erro: ' + error.message)
  else emit('refresh')
}

async function denyAccess(id: string) {
  if(!confirm('Deseja recusar o acesso?')) return
  const { error } = await supabase.from('public_leads').update({ design_access_status: 'none' }).eq('id', id)
  if (error) alert('Erro: ' + error.message)
  else emit('refresh')
}

async function revokeAccess(id: string) {
  if(!confirm('Deseja revogar o acesso VIP?')) return
  const { error } = await supabase.from('public_leads').update({ design_access_status: 'none' }).eq('id', id)
  if (error) alert('Erro: ' + error.message)
  else emit('refresh')
}

async function restoreVisibility(id: string) {
  const d = new Date()
  d.setHours(d.getHours() + 24)
  const { error } = await supabase.from('client_design_deliveries').update({ expires_at: d.toISOString(), force_visible: true }).eq('id', id)
  if (error) alert('Erro: ' + error.message)
  else emit('refresh')
}

async function revokeArte(id: string) {
  if(!confirm('Apagar registro imediatamente?')) return
  const { error } = await supabase.from('client_design_deliveries').delete().eq('id', id)
  if (error) alert('Erro: ' + error.message)
  else emit('refresh')
}
</script>

<style scoped lang="scss">
/* =========================================================================
   ESTILOS GERAIS
========================================================================= */
.design-clients-layout { position: relative; }
.border-bottom-white-05 { border-bottom: 1px solid rgba(255,255,255,0.08); }
.border-top-white-05 { border-top: 1px solid rgba(255,255,255,0.08); }
.border-white-10 { border: 1px solid rgba(255,255,255,0.1) !important; }
.border-white-20 { border: 1px solid rgba(255,255,255,0.2) !important; }
.bg-black-20 { background-color: rgba(0,0,0,0.2); }
.bg-black-50 { background-color: rgba(0,0,0,0.5); }

.controls-bar { padding: 10px; border: 1px solid rgba(0,0,0,0.08); }
.controls-light { background: #ffffff; }
.controls-dark { background: rgba(30,30,35,0.55); backdrop-filter: blur(16px); border: 1px solid rgba(255,255,255,0.08); }

.search-wrap { padding: 0 12px; display: flex; align-items: center; }
.search-light { background: #f4f6f8; border: 1px solid rgba(0,0,0,0.08); }
.search-dark { background: rgba(255,255,255,0.05); border: 1px solid rgba(255,255,255,0.10); }
.clean-input { border: none; outline: none; flex: 1; font-size: 13px; background: transparent; }

/* Grid e Scroll */
.grid-scroll { scrollbar-gutter: stable; -webkit-overflow-scrolling: touch; }
.custom-scroll::-webkit-scrollbar { width: 6px; height: 6px; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.35); border-radius: 4px; }
.custom-scroll::-webkit-scrollbar-track { background: transparent; }

/* GRID LAYOUT FLUIDO E RESPONSIVO DINÂMICO */
.grid-header, .grid-row { display: grid; align-items: stretch; width: 100%; }
.cell { padding: 6px 12px; display: flex; align-items: center; border-right: 1px solid rgba(0,0,0,0.08); border-bottom: 1px solid rgba(0,0,0,0.08); min-height: 54px; overflow: hidden; transition: background-color 0.2s ease; }
.header-text { font-size: 11px; font-weight: 800; text-transform: uppercase; letter-spacing: 0.5px; line-height: 1.2; }
.center { justify-content: center; text-align: center; }

.grid-header .cell { min-height: 44px; }
.list-text-11 { font-size: 13px !important; line-height: 1.2 !important; }

/* DARK/LIGHT MODE DA GRID */
.grid-surface-light .cell { background: #f5f7fa; color: rgba(0,0,0,0.9); border-color: rgba(0,0,0,0.12) !important; }
.grid-row-light .cell { border-color: rgba(0,0,0,0.08) !important; }
.zebra-light-a .cell { background: #ffffff; }
.zebra-light-b .cell { background: #f0f4f8; }
.grid-row-light:hover .cell { background: #e3f2fd !important; }

.grid-surface-dark .cell { background: rgba(255,255,255,0.08) !important; color: rgba(255,255,255,0.80) !important; border-color: rgba(255,255,255,0.10) !important; backdrop-filter: none !important; }
.grid-row-dark .cell { background: rgba(255,255,255,0.04); border-color: rgba(255,255,255,0.08) !important; color: rgba(255,255,255,0.85); }
.zebra-dark-a .cell { background: rgba(255,255,255,0.04) !important; }
.zebra-dark-b .cell { background: rgba(255,255,255,0.015) !important; }
.grid-row-dark:hover .cell { background: rgba(255,255,255,0.07) !important; }

.bg-warning-darken-4-alpha { background-color: rgba(245, 158, 11, 0.15) !important; }

/* KPI Desktop */
.kpi-card { color: white; position: relative; min-height: 110px; overflow: hidden; border-radius: 8px;}
.kpi-bg-icon { position: absolute; right: -20px; bottom: -20px; opacity: 0.15; transform: rotate(-15deg); }
.kpi-bg-icon .v-icon { font-size: 100px; color: white; }

.bg-gradient-green { background: linear-gradient(135deg, #2e7d32, #1b5e20); }
.bg-gradient-purple { background: linear-gradient(135deg, #7b1fa2, #4a148c); }
.bg-gradient-warning { background: linear-gradient(135deg, #FFB300, #F57F17); }
.kpi-label { font-size: 12px; font-weight: 900; letter-spacing: .2px; text-transform: uppercase; }
.kpi-value { font-size: 26px; font-weight: 900; }
.kpi-footer { font-size: 11px; opacity: .9; font-weight: 700; letter-spacing: 0.05em; text-transform: uppercase; }

.solid-chip { display: inline-flex; align-items: center; justify-content: center; height: 26px; padding: 0 10px; font-weight: 900; color: #fff; text-transform: uppercase; white-space: nowrap; font-size: 10px; }
.chip-status { min-width: 90px; }
.chip-success { background: #2e7d32; }
.chip-warn { background: #f57f17; }
.chip-danger { background: #c62828; }

.actions-inline { display: flex; gap: 6px; justify-content: center; flex-wrap: nowrap !important; }
.action-btn { width: 30px !important; height: 30px !important; color: #fff !important; }
.action-pay { background: #2e7d32 !important; }
.action-del { background: #c62828 !important; }

/* EFEITOS 3D */
.btn-3d { border-radius: 6px !important; box-shadow: 0 3px 5px rgba(0,0,0,0.15), inset 0 2px 0 rgba(255,255,255,0.25) !important; transition: transform 0.1s ease, box-shadow 0.1s ease; text-transform: none !important; }
.btn-3d:active { transform: translateY(2px); box-shadow: 0 1px 2px rgba(0,0,0,0.15), inset 0 1px 0 rgba(255,255,255,0.2) !important; }
.chip-3d { border-radius: 6px !important; box-shadow: 0 2px 4px rgba(0,0,0,0.12), inset 0 1px 0 rgba(255,255,255,0.25) !important; text-shadow: 0 1px 2px rgba(0,0,0,0.25); }

/* UTILIDADES */
.glass-card { background: rgba(30, 30, 36, 0.6); backdrop-filter: blur(12px); }
.sticky-head { position: sticky; top: 0; z-index: 20; box-shadow: 0 8px 16px -4px rgba(0, 0, 0, 0.12); }
.bg-glass-dark .sticky-head { box-shadow: 0 8px 20px -4px rgba(0, 0, 0, 0.4); }
.letter-spacing-1 { letter-spacing: 0.05em; }
.lh-1 { line-height: 1.2 !important; }
.transition-all { transition: all 0.2s ease; }
.animation-slide-up { animation: slideUp 0.4s ease-out forwards; }

@keyframes slideUp {
  0% { opacity: 0; transform: translateY(20px); }
  100% { opacity: 1; transform: translateY(0); }
}

/* =========================================================================
   ESTILOS EXCLUSIVOS: DRAWER TIMELINE 3D
========================================================================= */
.bg-texture {
  background-image: radial-gradient(rgba(128, 128, 128, 0.15) 1px, transparent 1px);
  background-size: 24px 24px;
}

.sticky-date { position: sticky; top: -20px; z-index: 30; }
.line-separator { box-shadow: 0 1px 2px rgba(0,0,0,0.05); }

.library-card-3d {
  transform: perspective(1200px) rotateY(-10deg) rotateX(4deg);
  box-shadow: -8px 12px 24px rgba(0,0,0,0.15);
  transition: all 0.4s cubic-bezier(0.25, 0.8, 0.25, 1);
  transform-style: preserve-3d;
  will-change: transform, box-shadow;
  border: 1px solid rgba(255,255,255,0.05);
}

.library-card-3d:hover {
  transform: perspective(1200px) rotateY(0deg) rotateX(0deg) scale(1.02);
  box-shadow: 0 20px 40px rgba(0,0,0,0.3);
  z-index: 10;
  border-color: rgba(var(--v-theme-primary), 0.5);
}

.library-card-3d .img-zoom { transition: transform 0.6s cubic-bezier(0.25, 1, 0.5, 1); }
.library-card-3d:hover .img-zoom { transform: scale(1.05); }

.bg-gradient-to-t { background: linear-gradient(to top, var(--tw-gradient-stops)); }
.from-black-80 { --tw-gradient-from: rgba(0,0,0,0.85); --tw-gradient-stops: var(--tw-gradient-from), transparent 50%; }
.backdrop-blur { backdrop-filter: blur(6px); -webkit-backdrop-filter: blur(6px); }
.backdrop-blur-sm { backdrop-filter: blur(3px); -webkit-backdrop-filter: blur(3px); }

.hover-action-overlay {
  opacity: 0;
  background: rgba(0,0,0,0.45);
  transition: opacity 0.3s ease;
}
.library-card-3d:hover .hover-action-overlay { opacity: 1; }

/* =========================================================================
   ESTILOS EXCLUSIVOS: KANBAN DE PILOTOS E GRID
========================================================================= */
.kanban-board {
  padding: 8px;
}

.kanban-col {
  flex: 0 0 320px;
  max-width: 320px;
  background: rgba(128,128,128,0.03);
  border-radius: 12px;
  overflow: hidden;
}

.kanban-col-header {
  padding: 12px 16px;
  font-size: 13px;
  font-weight: 800;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  display: flex;
  align-items: center;
  border-bottom-width: 2px !important;
}

.count-badge {
  font-size: 10px;
  font-weight: 900;
  padding: 2px 8px;
  border-radius: 999px;
  line-height: 1;
}

.kanban-col-body {
  flex-grow: 1;
  padding: 12px;
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.empty-col {
  padding: 24px;
  text-align: center;
  font-size: 12px;
  color: rgba(128,128,128,0.5);
  font-weight: 700;
  border: 1px dashed rgba(128,128,128,0.2);
  border-radius: 8px;
}

.kanban-card {
  border-radius: 12px;
  padding: 12px;
  display: flex;
  flex-direction: column;
  transition: transform 0.2s ease, box-shadow 0.2s ease;
}

.kanban-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 24px rgba(0,0,0,0.12);
}

.kanban-card-mid {
  display: flex;
  gap: 10px;
  padding: 8px;
  border-radius: 8px;
}

.mid-img {
  width: 42px;
  height: 42px;
  border-radius: 6px;
  object-fit: cover;
}

.mid-info {
  display: flex;
  flex-direction: column;
  justify-content: center;
  overflow: hidden;
  line-height: 1.2;
}

.mid-title {
  font-size: 12px;
  font-weight: 800;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.mid-ref {
  font-size: 10px;
  font-family: monospace;
  opacity: 0.6;
  margin-top: 2px;
}

.kanban-card-actions {
  display: flex;
  gap: 8px;
}

.text-decoration-line-through { text-decoration: line-through; opacity: 0.7; }
</style>
