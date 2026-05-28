<template>
  <div
    class="leads-layout font-sans fill-height d-flex flex-column relative overflow-hidden w-100"
    :class="isDark ? 'bg-glass-dark text-white' : 'bg-grey-lighten-5 text-grey-darken-4'"
  >
    <div v-if="isDark" class="background-carousel-wrapper">
      <v-carousel cycle height="100%" hide-delimiters :show-arrows="false" interval="15000" class="fill-height">
        <v-carousel-item src="@/assets/1.jpg" cover></v-carousel-item>
        <v-carousel-item src="@/assets/2.jpg" cover></v-carousel-item>
        <v-carousel-item src="@/assets/3.jpg" cover></v-carousel-item>
      </v-carousel>
      <div class="background-overlay"></div>
    </div>

    <div class="content-wrapper d-flex flex-column fill-height z-10 w-100">

      <div
        class="header-bar px-4 py-3 px-md-6 py-md-4 d-flex flex-column flex-md-row align-md-start justify-space-between flex-shrink-0 w-100"
        :class="isDark ? 'bg-glass-header border-bottom-white-05' : 'bg-white border-b border-grey-lighten-2 shadow-sm'"
      >
        <div class="d-flex flex-column">
          <div class="breadcrumb text-caption d-none d-md-block">
            <span class="opacity-70">Marketplace</span>
            <span class="mx-2 opacity-50">></span>
            <span class="font-weight-bold">Gestão de Acessos (Leads)</span>
          </div>
          <div class="text-h5 font-weight-black tracking-tight leading-none mt-1 d-flex align-center gap-2" :class="isDark ? 'text-white' : 'text-grey-darken-4'">
             Acessos e Monitoramento Anti-Plágio
             <v-chip size="small" color="primary" variant="flat" class="font-weight-bold text-uppercase ml-2">Motor Ativo</v-chip>
          </div>
        </div>

        <div class="d-flex align-center gap-3 mt-3 mt-md-0 flex-wrap">
          <v-btn
            color="success"
            variant="flat"
            class="btn-3d px-4 font-weight-bold text-caption text-uppercase letter-spacing-1 flex-shrink-0"
            prepend-icon="mdi-account-plus"
            height="40"
            @click="openCreateAccountModal"
          >
            Criar Conta
          </v-btn>

          <v-menu location="bottom end">
            <template v-slot:activator="{ props }">
              <v-btn
                v-bind="props"
                color="blue-darken-3"
                variant="flat"
                class="btn-3d px-4 font-weight-bold text-caption text-uppercase letter-spacing-1 flex-shrink-0"
                prepend-icon="mdi-file-chart"
                height="40"
                :loading="reportLoading"
              >
                Auditoria & Relatórios
                <v-icon end size="small">mdi-chevron-down</v-icon>
              </v-btn>
            </template>
            <v-list density="compact" nav :class="isDark ? 'bg-grey-darken-4 text-white' : 'bg-white'">
              <v-list-item @click="generateReport('pdf')" prepend-icon="mdi-file-pdf-box" title="Exportar para PDF" :class="isDark ? 'text-red-lighten-1' : 'text-red-darken-3'" class="font-weight-bold"></v-list-item>
              <v-list-item @click="generateReport('excel')" prepend-icon="mdi-microsoft-excel" title="Exportar para Excel" :class="isDark ? 'text-green-lighten-1' : 'text-green-darken-3'" class="font-weight-bold"></v-list-item>
            </v-list>
          </v-menu>

          <v-btn color="grey-darken-3" variant="flat" class="btn-3d px-4 font-weight-bold text-caption flex-shrink-0" height="40" @click="fetchSecurityData">
             <v-icon start>mdi-refresh</v-icon> Atualizar Manual
          </v-btn>
        </div>
      </div>

      <div class="px-4 px-md-6 py-4 flex-shrink-0 w-100">
        <v-row class="ma-0 w-100">
          <v-col cols="12" sm="6" md="3" class="pa-2">
            <v-card class="kpi-card bg-gradient-purple hover-elevate py-3 px-4 cursor-pointer" elevation="2" v-ripple @click="filterByStatus('all')">
              <div class="kpi-bg-icon"><v-icon>mdi-account-group</v-icon></div>
              <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                <div class="d-flex align-center gap-2">
                  <v-icon size="18" class="opacity-80">mdi-account-group</v-icon>
                  <span class="kpi-label">TOTAL DE LEADS</span>
                </div>
                <div class="kpi-number-group my-1"><span class="kpi-value">{{ enrichedLeads.length }}</span></div>
                <div class="kpi-footer mt-1 opacity-70">Registros na base</div>
              </div>
            </v-card>
          </v-col>

          <v-col cols="12" sm="6" md="3" class="pa-2">
            <v-card class="kpi-card bg-gradient-success hover-elevate py-3 px-4 cursor-pointer" elevation="2" v-ripple @click="filterByStatus('active')">
              <div class="kpi-bg-icon"><v-icon>mdi-shield-check</v-icon></div>
              <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                <div class="d-flex align-center gap-2">
                  <v-icon size="18" class="opacity-80">mdi-shield-check</v-icon>
                  <span class="kpi-label">ACESSO LIBERADO</span>
                </div>
                <div class="kpi-number-group my-1"><span class="kpi-value">{{ activeLoginCount }}</span></div>
                <div class="kpi-footer mt-1 opacity-70">Sessões com chave válida</div>
              </div>
            </v-card>
          </v-col>

          <v-col cols="12" sm="6" md="3" class="pa-2">
            <v-card class="kpi-card bg-gradient-warning hover-elevate py-3 px-4 cursor-pointer" elevation="2" v-ripple @click="filterByStatus('behavior_warning')">
              <div class="kpi-bg-icon"><v-icon>mdi-eye-alert</v-icon></div>
              <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                <div class="d-flex align-center gap-2">
                  <v-icon size="18" class="opacity-80">mdi-eye-alert</v-icon>
                  <span class="kpi-label">COMPORTAMENTO SUSPEITO</span>
                </div>
                <div class="kpi-number-group my-1"><span class="kpi-value">{{ suspiciousBehaviorCount }}</span></div>
                <div class="kpi-footer mt-1 opacity-70">Scores médios ou revalidação</div>
              </div>
            </v-card>
          </v-col>

          <v-col cols="12" sm="6" md="3" class="pa-2">
            <v-card class="kpi-card bg-gradient-danger hover-elevate py-3 px-4 cursor-pointer" elevation="2" v-ripple @click="filterByStatus('blocked')">
              <div class="kpi-bg-icon"><v-icon>mdi-shield-off</v-icon></div>
              <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                <div class="d-flex align-center gap-2">
                  <v-icon size="18" class="opacity-80">mdi-shield-off</v-icon>
                  <span class="kpi-label">BLOQUEADOS (MOTOR)</span>
                </div>
                <div class="kpi-number-group my-1"><span class="kpi-value">{{ blockedBehaviorCount }}</span></div>
                <div class="kpi-footer mt-1 text-yellow-accent-2 font-weight-bold">Acesso cortado pelo sistema</div>
              </div>
            </v-card>
          </v-col>
        </v-row>
      </div>

      <div class="px-4 px-md-6 pt-0 pb-2 flex-shrink-0 w-100">
        <div class="controls-bar d-flex flex-column flex-md-row align-center justify-space-between w-100 gap-3" :class="isDark ? 'controls-dark' : 'controls-light'">

          <div class="d-flex flex-column flex-sm-row align-center gap-3 w-100 w-md-auto">
            <v-menu location="bottom start">
              <template v-slot:activator="{ props }">
                <v-btn v-bind="props" variant="outlined" class="btn-3d w-100 w-sm-auto" height="40" prepend-icon="mdi-filter-variant" :color="isDark ? 'white' : 'grey-darken-3'">
                  Filtro: {{ statusFilterLabel }}
                  <v-icon end size="small">mdi-chevron-down</v-icon>
                </v-btn>
              </template>
              <v-list density="compact" :class="isDark ? 'bg-grey-darken-4 text-white' : 'bg-white'">
                <v-list-item @click="filterByStatus('all')"><v-list-item-title class="font-weight-bold">Todos os Registros</v-list-item-title></v-list-item>
                <v-list-item @click="filterByStatus('active')"><v-list-item-title class="font-weight-bold text-success">Login Liberado</v-list-item-title></v-list-item>
                <v-list-item @click="filterByStatus('behavior_warning')"><v-list-item-title class="font-weight-bold text-warning">Risco Comportamental (Médio/Alto)</v-list-item-title></v-list-item>
                <v-list-item @click="filterByStatus('blocked')"><v-list-item-title class="font-weight-bold text-error">Bloqueados pelo Motor</v-list-item-title></v-list-item>
              </v-list>
            </v-menu>

            <div class="search-wrap d-flex align-center w-100 w-sm-auto flex-grow-1" :class="isDark ? 'search-dark' : 'search-light'">
              <v-icon :color="isDark ? 'white-70' : 'grey-darken-1'">mdi-magnify</v-icon>
              <input
                v-model="searchQuery"
                type="text"
                placeholder="Buscar cliente, email, documento, IP ou Fingerprint..."
                class="clean-input flex-grow-1"
                :class="isDark ? 'text-white' : 'text-grey-darken-4'"
              />
            </div>
          </div>

          <div class="d-flex align-center gap-3 w-100 w-md-auto justify-end flex-wrap">
            <transition name="fade">
              <div v-if="selectedLeads.length > 0" class="d-flex align-center gap-2">
                <span class="text-caption font-weight-bold text-primary mr-2">{{ selectedLeads.length }} selecionados</span>
                <v-btn color="error" variant="tonal" size="small" class="btn-3d font-weight-bold" @click="revokeMassAccess" :loading="isProcessingMass"><v-icon start>mdi-shield-off</v-icon> Revogar Chaves</v-btn>
                <v-btn color="primary" variant="flat" size="small" class="btn-3d font-weight-bold" @click="openConfigModal(null)"><v-icon start>mdi-key-star</v-icon> Emitir Chave</v-btn>
                <v-btn color="success" variant="flat" size="small" class="btn-3d font-weight-bold" @click="openCreateAccountModal"><v-icon start>mdi-account-plus</v-icon> Criar Conta</v-btn>
              </div>
            </transition>
          </div>
        </div>
      </div>

      <div class="flex-grow-1 overflow-hidden d-flex flex-column transition-all px-4 px-md-6 pb-4 w-100">
        <v-card class="flex-grow-1 d-flex flex-column rounded-0 border-thin overflow-hidden w-100" :class="isDark ? 'glass-card border-white-05' : 'bg-white shadow-sm'" :elevation="0">

          <div class="grid-scroll flex-grow-1 overflow-auto custom-scroll relative w-100">
            <div class="grid-table-container">

              <div class="grid-header sticky-head" :class="isDark ? 'grid-surface-dark border-bottom-white-05' : 'grid-surface-light border-b border-grey-lighten-2'">
                <div class="cell center"><v-checkbox-btn :model-value="isAllSelected" :indeterminate="isIndeterminate" @update:model-value="toggleSelectAll" color="success" class="chk-fixed"></v-checkbox-btn></div>
                <div class="cell header-text pl-4">Nome</div>
                <div class="cell header-text">E-mail</div>
                <div class="cell header-text">Documento</div>
                <div class="cell center header-text">Info Comercial</div>
                <div class="cell center header-text">Status Chave</div>
                <div class="cell center header-text">Expiração</div>
                <div class="cell center header-text">Device</div>
                <div class="cell center header-text">Risco</div>
                <div class="cell header-text">Motivo / Alerta</div>
                <div class="cell center header-text">Ações</div>
              </div>

              <div v-if="paginatedLeads.length === 0" class="d-flex flex-column justify-center align-center h-100 opacity-60 gap-2 py-10 w-100" style="min-width: 1400px;">
                <v-icon size="48" color="grey-lighten-1">mdi-shield-search</v-icon>
                <span class="text-body-2 font-weight-medium text-grey">Nenhum registro encontrado.</span>
              </div>

              <div
                v-else
                v-for="(lead, index) in paginatedLeads"
                :key="lead.id"
                class="grid-row"
                :class="[isDark ? 'grid-row-dark' : 'grid-row-light', zebraClass(index), selectedLeads.includes(lead.id) ? (isDark ? 'grid-selected-dark' : 'grid-selected-light') : '']"
              >
                <div class="cell center"><v-checkbox-btn v-model="selectedLeads" :value="lead.id" color="success" class="chk-fixed"></v-checkbox-btn></div>

                <div class="cell pl-4">
                  <div class="d-flex align-center gap-3 w-100 overflow-hidden">
                    <v-avatar :color="getAvatarColor(lead.name)" size="32" class="text-white font-weight-black shadow-sm text-caption flex-shrink-0">
                      {{ lead.name ? lead.name.substring(0, 2).toUpperCase() : '?' }}
                    </v-avatar>
                    <div class="d-flex flex-column overflow-hidden min-w-0 w-100">
                      <strong class="text-caption font-weight-black text-truncate" :class="isDark ? 'text-white' : 'text-grey-darken-4'" :title="lead.name">{{ lead.name || 'Sem nome' }}</strong>
                      <span v-if="lead.auth_code_requested" class="text-[9px] font-weight-black text-warning text-uppercase animate-pulse bg-warning-lighten-5 px-1 rounded mt-1 align-self-start">Chave Solicitada</span>
                    </div>
                  </div>
                </div>

                <div class="cell flex-column align-start justify-center min-w-0">
                   <span class="text-caption font-weight-medium text-truncate opacity-90 w-100" :title="lead.email">{{ lead.email }}</span>
                </div>

                <div class="cell flex-column align-start justify-center min-w-0">
                   <span class="text-[11px] font-mono font-weight-bold opacity-70 text-truncate w-100" :title="lead.document">{{ lead.document || '-' }}</span>
                </div>

                <div class="cell center">
                   <v-btn
                     v-if="lead.vip_interest || lead.vip_pilot_meterage || lead.vip_operation_size"
                     size="small"
                     variant="tonal"
                     color="primary"
                     class="font-weight-bold btn-3d w-100 text-none px-2"
                     height="32"
                     @click="openVipModal(lead)"
                   >
                     <v-icon start size="14">mdi-clipboard-text</v-icon> Ver Info
                   </v-btn>
                   <span v-else class="text-[10px] opacity-40 font-weight-bold text-uppercase">-</span>
                </div>

                <div class="cell center flex-column gap-1">
                   <v-chip :color="getLoginStatus(lead).color" :variant="getLoginStatus(lead).variant" size="small" class="font-weight-bold px-2 chip-3d text-uppercase w-100 justify-center" style="font-size: 9px;">
                     <v-icon start size="12" v-if="getLoginStatus(lead).icon">{{ getLoginStatus(lead).icon }}</v-icon>
                     {{ getLoginStatus(lead).label }}
                   </v-chip>
                </div>

                <div class="cell center">
                   <span v-if="lead.temp_auth_expires_at && new Date(lead.temp_auth_expires_at) > new Date()" class="text-[11px] font-weight-bold text-success d-flex align-center gap-1 text-center opacity-90">
                      {{ formatExpiration(lead.temp_auth_expires_at) }}
                   </span>
                   <span v-else-if="lead.temp_auth_expires_at && new Date(lead.temp_auth_expires_at) <= new Date()" class="text-[11px] font-weight-bold text-error d-flex align-center gap-1 text-center text-decoration-line-through opacity-80" title="A chave já venceu">
                      {{ formatExpiration(lead.temp_auth_expires_at) }}
                   </span>
                   <span v-else class="text-[11px] opacity-40">-</span>
                </div>

                <div class="cell center">
                   <v-btn
                     size="small"
                     :color="(lead.behavior_status === 'blocked' || lead.behavior_flag === 'high') ? 'error' : 'success'"
                     variant="tonal"
                     class="btn-3d text-none px-2 w-100 font-weight-bold"
                     height="32"
                     @click="openFingerprintModal(lead)"
                   >
                      <v-icon start size="14">{{ (lead.behavior_status === 'blocked' || lead.behavior_flag === 'high') ? 'mdi-alert-octagon' : 'mdi-check-decagram' }}</v-icon>
                      {{ (lead.behavior_status === 'blocked' || lead.behavior_flag === 'high') ? 'Violado' : 'Seguro' }}
                   </v-btn>
                </div>

                <div class="cell center flex-column px-3 w-100">
                   <span class="text-[12px] font-weight-black text-uppercase mb-1" :class="getRiskColorText(lead.behavior_score)">{{ lead.behavior_score || 0 }} / 100</span>
                   <v-progress-linear
                      :model-value="lead.behavior_score || 0"
                      :color="getRiskColorText(lead.behavior_score).replace('text-', '')"
                      height="6"
                      rounded
                      class="w-100"
                   ></v-progress-linear>
                </div>

                <div class="cell flex-column align-start justify-center min-w-0" @click="lead.behavior_reason ? openReasonModal(lead) : null">
                   <span v-if="lead.behavior_reason" class="text-[11px] font-weight-bold text-truncate w-100 cursor-pointer hover-underline" :class="getBehaviorStatus(lead).color === 'error' ? 'text-error' : 'text-warning'" :title="translateReasonShort(lead.behavior_reason)">
                      {{ translateReasonShort(lead.behavior_reason) }}
                   </span>
                   <span v-else class="text-[11px] opacity-40 font-weight-bold">-</span>
                </div>

                <div class="cell center">
                  <div class="actions-inline opacity-actions">
                    <v-btn icon size="small" class="action-btn bg-success btn-3d" title="WhatsApp" :disabled="!lead.phone" @click="openWhatsApp(lead.phone, lead.name)"><v-icon size="16">mdi-whatsapp</v-icon></v-btn>
                    <v-btn icon size="small" class="action-btn bg-primary btn-3d" title="Emitir Nova Chave" @click="openConfigModal(lead)" :loading="processingCode === lead.id"><v-icon size="16">mdi-key-star</v-icon></v-btn>
                    <v-btn icon size="small" class="action-btn bg-info btn-3d" title="Dossiê Anti-Plágio" @click="openDossier(lead)"><v-icon size="16">mdi-shield-search</v-icon></v-btn>

                    <v-menu location="bottom end">
                      <template v-slot:activator="{ props }">
                        <v-btn v-bind="props" icon size="small" class="action-btn bg-grey-darken-2 btn-3d" title="Opções de Segurança"><v-icon size="16">mdi-cog</v-icon></v-btn>
                      </template>
                      <v-list density="compact" class="shadow-xl border-thin rounded-lg" :class="isDark ? 'bg-grey-darken-4 text-white' : 'bg-white'">
                        <v-list-item @click="copyToClipboard(lead.email, 'E-mail copiado!')"><template v-slot:prepend><v-icon size="16" class="mr-2">mdi-email-copy</v-icon></template><v-list-item-title class="text-caption font-weight-bold">Copiar E-mail</v-list-item-title></v-list-item>
                        <v-divider class="my-1 border-opacity-20"></v-divider>
                        <v-list-item @click="resetBehaviorRisk(lead)" base-color="success">
                          <template v-slot:prepend><v-icon size="16" class="mr-2">mdi-shield-check-outline</v-icon></template>
                          <v-list-item-title class="text-caption font-weight-bold">Zerar Risco (Perdoar/Limpar Dev)</v-list-item-title>
                        </v-list-item>
                        <v-list-item @click="forceBehaviorBlock(lead)" base-color="error">
                          <template v-slot:prepend><v-icon size="16" class="mr-2">mdi-shield-lock</v-icon></template>
                          <v-list-item-title class="text-caption font-weight-bold">Forçar Bloqueio e Queimar Chave</v-list-item-title>
                        </v-list-item>
                      </v-list>
                    </v-menu>
                  </div>
                </div>

              </div>

            </div>
          </div>

          <div class="flex-shrink-0 border-t px-4 py-2 d-flex flex-column flex-md-row align-center justify-space-between z-20 w-100" :class="isDark ? 'bg-surface-variant border-top-white-05' : 'bg-white'">
            <div class="text-caption font-weight-bold opacity-70 mb-2 mb-md-0">
              Mostrando {{ paginatedLeads.length }} de {{ filteredLeads.length }} registros
            </div>
            <v-pagination
              v-model="page"
              :length="pageCount"
              :total-visible="5"
              density="compact"
              active-color="primary"
              variant="tonal"
              size="small"
            ></v-pagination>
          </div>

        </v-card>
      </div>
    </div>

    <v-dialog v-model="showFingerprintModal" max-width="450">
      <v-card class="rounded-xl border shadow-indigo-soft overflow-hidden" :class="isDark ? 'bg-grey-darken-4 text-white' : 'bg-white'">
        <div class="px-5 py-4 border-b d-flex justify-space-between align-center flex-shrink-0 position-relative overflow-hidden" :class="selectedFingerprintLead?.behavior_status === 'blocked' || selectedFingerprintLead?.behavior_flag === 'high' ? 'bg-error' : 'bg-success'">
            <div class="card-bg-icon"><v-icon size="80">mdi-cellphone-link</v-icon></div>
            <div class="d-flex align-center gap-3 position-relative z-10">
                <div class="icon-box bg-white rounded-lg d-flex align-center justify-center elevation-1" :class="selectedFingerprintLead?.behavior_status === 'blocked' || selectedFingerprintLead?.behavior_flag === 'high' ? 'text-error' : 'text-success'" style="width: 38px; height: 38px;">
                    <v-icon size="22">{{ selectedFingerprintLead?.behavior_status === 'blocked' || selectedFingerprintLead?.behavior_flag === 'high' ? 'mdi-alert-octagon' : 'mdi-shield-check' }}</v-icon>
                </div>
                <div class="text-white">
                    <div class="font-weight-bold text-uppercase opacity-80" style="font-size: 10px; letter-spacing: 1px;">Autenticidade do Dispositivo</div>
                    <div class="text-h6 font-weight-black lh-1 mt-1">{{ selectedFingerprintLead?.behavior_status === 'blocked' || selectedFingerprintLead?.behavior_flag === 'high' ? 'Dispositivo Violado' : 'Dispositivo Seguro' }}</div>
                </div>
            </div>
        </div>
        <v-card-text class="pa-6">
          <div class="d-flex flex-column gap-4">
            <div class="d-flex flex-column">
              <span class="text-[10px] font-weight-black text-uppercase opacity-60 mb-1 letter-spacing-1">Endereço IP (Último Acesso)</span>
              <span class="text-body-1 font-mono font-weight-black d-flex align-center gap-2 text-primary">
                <v-icon size="18" color="primary">mdi-web</v-icon>
                {{ selectedFingerprintLead?.last_ip || 'Desconhecido' }}
              </span>
            </div>
            <v-divider :class="isDark ? 'border-white-05' : ''"></v-divider>
            <div class="d-flex flex-column">
              <span class="text-[10px] font-weight-black text-uppercase opacity-60 mb-1 letter-spacing-1">Fingerprint (Assinatura do Aparelho)</span>
              <span class="text-caption font-mono font-weight-bold d-flex align-center gap-2 opacity-80 text-truncate">
                <v-icon size="16">mdi-fingerprint</v-icon>
                {{ selectedFingerprintLead?.computed_fingerprint || 'Aguardando primeiro acesso...' }}
              </span>
            </div>
            <v-alert v-if="selectedFingerprintLead?.behavior_status === 'blocked' || selectedFingerprintLead?.behavior_flag === 'high'" type="error" variant="tonal" class="mt-2 text-caption font-weight-bold border-error rounded-lg">
               Foi detectada uma inconsistência de hardware ou rede associada a esta chave.
            </v-alert>
          </div>
        </v-card-text>
        <v-card-actions class="pa-4 border-t d-flex justify-end" :class="isDark ? 'border-white-05' : ''">
          <v-btn variant="tonal" color="grey" class="text-none font-weight-bold rounded-lg btn-3d" @click="showFingerprintModal = false">Fechar</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <v-dialog v-model="showVipModal" max-width="450">
      <v-card class="rounded-xl border shadow-indigo-soft overflow-hidden" :class="isDark ? 'bg-grey-darken-4 text-white' : 'bg-white'">
        <div class="px-5 py-4 border-b d-flex justify-space-between align-center flex-shrink-0 bg-primary position-relative overflow-hidden">
            <div class="card-bg-icon"><v-icon size="80">mdi-clipboard-text-search-outline</v-icon></div>
            <div class="d-flex align-center gap-3 position-relative z-10">
                <div class="icon-box bg-white text-primary rounded-lg d-flex align-center justify-center elevation-1" style="width: 38px; height: 38px;">
                    <v-icon size="22">mdi-bullseye-arrow</v-icon>
                </div>
                <div class="text-white">
                    <div class="font-weight-bold text-uppercase opacity-80" style="font-size: 10px; letter-spacing: 1px;">Solicitação Comercial</div>
                    <div class="text-h6 font-weight-black lh-1 mt-1">Questionário de Avaliação</div>
                </div>
            </div>
        </div>
        <v-card-text class="pa-6">
          <div class="d-flex flex-column gap-5">
            <div class="d-flex flex-column">
              <span class="text-[10px] font-weight-black text-uppercase opacity-60 mb-1 letter-spacing-1">Foco Principal</span>
              <span class="text-body-1 font-weight-black d-flex align-center gap-2">
                <v-icon size="20" color="primary">mdi-check-circle-outline</v-icon>
                {{ selectedVipLead?.vip_interest || 'Não informado' }}
              </span>
            </div>
            <v-divider :class="isDark ? 'border-white-05' : ''"></v-divider>
            <div class="d-flex flex-column">
              <span class="text-[10px] font-weight-black text-uppercase opacity-60 mb-1 letter-spacing-1">Metragem Inicial do Piloto</span>
              <span class="text-body-1 font-weight-black d-flex align-center gap-2">
                <v-icon size="20" color="primary">mdi-tape-measure</v-icon>
                {{ selectedVipLead?.vip_pilot_meterage || 'Não informado' }}
              </span>
            </div>
            <v-divider :class="isDark ? 'border-white-05' : ''"></v-divider>
            <div class="d-flex flex-column">
              <span class="text-[10px] font-weight-black text-uppercase opacity-60 mb-1 letter-spacing-1">Volume da Operação</span>
              <span class="text-body-1 font-weight-black d-flex align-center gap-2">
                <v-icon size="20" color="primary">mdi-domain</v-icon>
                {{ selectedVipLead?.vip_operation_size || 'Não informado' }}
              </span>
            </div>
          </div>
        </v-card-text>
        <v-card-actions class="pa-4 border-t d-flex justify-end" :class="isDark ? 'border-white-05' : ''">
          <v-btn variant="tonal" color="primary" class="text-none font-weight-bold rounded-lg btn-3d" @click="showVipModal = false">Fechar Respostas</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <v-dialog v-model="showReasonModal" max-width="400">
      <v-card class="rounded-xl border shadow-lg" :class="isDark ? 'bg-grey-darken-4 text-white' : 'bg-white'">
        <v-card-title class="pa-4 border-b text-error font-weight-black d-flex align-center gap-2" :class="isDark ? 'border-white-05' : 'bg-error-lighten-5'">
          <v-icon>mdi-alert-circle-outline</v-icon> Motivo do Bloqueio / Alerta
        </v-card-title>
        <v-card-text class="pa-6">
          <p class="text-body-1 font-weight-medium mb-0 text-center">
            {{ translateReasonShort(selectedReasonLead?.behavior_reason) }}
          </p>
        </v-card-text>
        <v-card-actions class="pa-4 border-t d-flex justify-end" :class="isDark ? 'border-white-05' : ''">
          <v-btn variant="tonal" color="grey" class="text-none font-weight-bold rounded-lg btn-3d" @click="showReasonModal = false">Fechar</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <v-dialog v-model="showDossierModal" max-width="700" persistent>
      <v-card class="rounded-xl border shadow-indigo-soft d-flex flex-column overflow-hidden" :class="isDark ? 'bg-grey-darken-4 text-white' : 'bg-white'" height="650px">
        <div class="px-5 py-4 border-b d-flex justify-space-between align-center flex-shrink-0 bg-primary position-relative overflow-hidden">
            <div class="card-bg-icon"><v-icon size="80">mdi-shield-search</v-icon></div>
            <div class="d-flex align-center gap-3 position-relative z-10">
                <div class="icon-box bg-white text-primary rounded-lg d-flex align-center justify-center elevation-1" style="width: 38px; height: 38px;">
                    <v-icon size="22">mdi-magnify-scan</v-icon>
                </div>
                <div class="text-white">
                    <div class="font-weight-bold text-uppercase opacity-80" style="font-size: 10px; letter-spacing: 1px;">Dossiê Comportamental</div>
                    <div class="text-h6 font-weight-black lh-1 mt-1">{{ selectedDossierLead?.name || 'Sessão Anônima' }}</div>
                </div>
            </div>
            <v-btn icon="mdi-close" variant="text" size="small" color="white" class="z-10" @click="showDossierModal = false"></v-btn>
        </div>

        <v-card-text class="pa-0 overflow-y-auto flex-grow-1 custom-scroll" :class="isDark ? 'bg-grey-darken-4' : 'bg-white'">
           <div class="pa-6 border-b" :class="isDark ? 'bg-grey-darken-4 border-white-05' : 'bg-white'">
              <div class="d-flex justify-space-between align-center mb-4">
                 <h4 class="text-subtitle-2 font-weight-black text-uppercase tracking-widest opacity-60">Score de Risco Atual</h4>
                 <v-chip :color="getBehaviorStatus(selectedDossierLead).color" size="small" variant="flat" class="font-weight-bold chip-3d">
                    {{ getBehaviorStatus(selectedDossierLead).label }}
                 </v-chip>
              </div>
              <v-progress-linear
                 :model-value="selectedDossierLead?.behavior_score || 0"
                 :color="getRiskColorText(selectedDossierLead?.behavior_score).replace('text-', '')"
                 height="12"
                 rounded
                 striped
              ></v-progress-linear>
              <div class="d-flex justify-space-between mt-2 text-caption font-weight-bold opacity-50">
                 <span>0 (Normal)</span>
                 <span>40 (Alerta)</span>
                 <span>70 (Revalidar)</span>
                 <span>100 (Bloqueio)</span>
              </div>
           </div>

           <div class="pa-6">
              <h4 class="text-subtitle-2 font-weight-black text-uppercase tracking-widest opacity-60 mb-6 d-flex align-center gap-2">
                 <v-icon size="16">mdi-history</v-icon> Auditoria de Tráfego e Infrações
              </h4>

              <div v-if="isFetchingEvents" class="d-flex justify-center py-8">
                 <v-progress-circular indeterminate color="primary"></v-progress-circular>
              </div>

              <div v-else-if="sessionEvents.length === 0" class="d-flex flex-column align-center text-center opacity-60 py-6">
                 <v-icon size="40" class="mb-2">mdi-shield-check-outline</v-icon>
                 <span class="text-caption font-weight-bold">Nenhuma atividade suspeita gravada recentemente.</span>
              </div>

              <v-timeline v-else density="compact" align="start" class="w-100" truncate-line="both">
                 <v-timeline-item
                    v-for="event in sessionEvents"
                    :key="event.id"
                    :dot-color="getEventColor(event.event_type)"
                    size="small"
                 >
                    <div class="d-flex flex-column mb-4 border rounded-lg pa-3" :class="isDark ? 'border-white-10 bg-grey-darken-3' : 'bg-grey-lighten-5 border-grey-lighten-2'">
                       <div class="d-flex justify-space-between align-center mb-1">
                          <strong class="text-body-2 font-weight-bold" :class="`text-${getEventColor(event.event_type)}`">{{ getEventTitle(event.event_type) }}</strong>
                          <span class="text-caption font-weight-bold opacity-60">{{ format(new Date(event.created_at), 'dd/MM HH:mm:ss') }}</span>
                       </div>

                       <div class="mt-2 d-flex flex-column gap-1 text-caption opacity-80">
                         <div v-if="event.context" class="d-flex align-center gap-1">
                           <v-icon size="12">mdi-map-marker-outline</v-icon> <span>Local: <strong>{{ event.context }}</strong></span>
                         </div>
                         <div v-if="event.visible_duration" class="d-flex align-center gap-1">
                           <v-icon size="12">mdi-timer-outline</v-icon> <span>Tempo Exposto: {{ event.visible_duration }}s</span>
                         </div>
                         <div v-if="event.metadata_json && event.metadata_json.action" class="d-flex align-center gap-1">
                           <v-icon size="12">mdi-gesture-tap</v-icon> <span>Ação Realizada: {{ event.metadata_json.action }}</span>
                         </div>
                         <div v-if="event.metadata_json && event.metadata_json.strike" class="d-flex align-center gap-1 mt-1 text-error font-weight-bold">
                           <v-icon size="12" color="error">mdi-alert</v-icon> <span>Strike Computado: Nível {{ event.metadata_json.strike }}</span>
                         </div>
                       </div>
                    </div>
                 </v-timeline-item>
              </v-timeline>
           </div>
        </v-card-text>

        <v-card-actions class="pa-4 border-t d-flex justify-end gap-2 flex-shrink-0" :class="isDark ? 'bg-grey-darken-3 border-white-05' : 'bg-grey-lighten-5'">
          <v-btn variant="tonal" color="success" class="font-weight-bold text-none rounded-lg px-4 btn-3d" @click="resetBehaviorRisk(selectedDossierLead)">
            <v-icon start>mdi-refresh</v-icon> Zerar & Perdoar Device
          </v-btn>
          <v-btn variant="flat" color="error" class="font-weight-bold text-none rounded-lg px-4 btn-3d" @click="forceBehaviorBlock(selectedDossierLead)">
            <v-icon start>mdi-shield-lock</v-icon> Forçar Bloqueio
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <v-dialog v-model="createAccountModal.show" max-width="620" persistent>
      <v-card class="rounded-xl border shadow-indigo-soft overflow-hidden" :class="isDark ? 'bg-grey-darken-4 text-white' : 'bg-white'">
        <div class="px-5 py-4 border-b d-flex justify-space-between align-center flex-shrink-0 bg-success position-relative overflow-hidden">
            <div class="card-bg-icon"><v-icon size="84">mdi-account-plus</v-icon></div>
            <div class="d-flex align-center gap-3 position-relative z-10">
                <div class="icon-box bg-white text-success rounded-lg d-flex align-center justify-center elevation-1" style="width: 40px; height: 40px;">
                    <v-icon size="23">mdi-account-key</v-icon>
                </div>
                <div class="text-white">
                    <div class="font-weight-bold text-uppercase opacity-80" style="font-size: 10px; letter-spacing: 1px;">Cadastro assistido</div>
                    <div class="text-h6 font-weight-black lh-1 mt-1">Criar conta para cliente</div>
                </div>
            </div>
            <v-btn icon="mdi-close" variant="text" size="small" color="white" class="z-10" @click="closeCreateAccountModal"></v-btn>
        </div>

        <v-card-text class="pa-6">
          <v-alert type="info" variant="tonal" class="rounded-lg mb-5 text-caption font-weight-medium border-primary" icon="mdi-information-outline">
            Use quando o cliente passou os dados ao vendedor. A conta será criada no Auth, já aprovada, com senha definida e prazo de ativação.
          </v-alert>

          <div class="create-account-grid">
            <div class="field-span-2">
              <label class="form-mini-label">Nome do cliente</label>
              <v-text-field
                v-model="createAccountForm.name"
                placeholder="Nome completo ou razão social"
                variant="outlined"
                density="compact"
                color="success"
                class="ui-field"
                hide-details
              />
            </div>

            <div>
              <label class="form-mini-label">E-mail de acesso</label>
              <v-text-field
                v-model="createAccountForm.email"
                placeholder="cliente@email.com"
                variant="outlined"
                density="compact"
                color="success"
                class="ui-field"
                hide-details
              />
            </div>

            <div>
              <label class="form-mini-label">Senha inicial</label>
              <v-text-field
                v-model="createAccountForm.password"
                :type="createAccountForm.showPassword ? 'text' : 'password'"
                placeholder="Defina a senha do cliente"
                variant="outlined"
                density="compact"
                color="success"
                class="ui-field"
                hide-details
                :append-inner-icon="createAccountForm.showPassword ? 'mdi-eye-off' : 'mdi-eye'"
                @click:append-inner="createAccountForm.showPassword = !createAccountForm.showPassword"
              />
            </div>

            <div>
              <label class="form-mini-label">Confirmar senha</label>
              <v-text-field
                v-model="createAccountForm.confirmPassword"
                :type="createAccountForm.showPassword ? 'text' : 'password'"
                placeholder="Repita a senha"
                variant="outlined"
                density="compact"
                color="success"
                class="ui-field"
                hide-details
              />
            </div>

            <div>
              <label class="form-mini-label">WhatsApp</label>
              <v-text-field
                v-model="createAccountForm.phone"
                placeholder="(00) 00000-0000"
                variant="outlined"
                density="compact"
                color="success"
                class="ui-field"
                hide-details
              />
            </div>

            <div>
              <label class="form-mini-label">CPF / CNPJ</label>
              <v-text-field
                v-model="createAccountForm.document"
                placeholder="Documento do cliente"
                variant="outlined"
                density="compact"
                color="success"
                class="ui-field"
                hide-details
              />
            </div>

            <div>
              <label class="form-mini-label">Tempo de ativação</label>
              <v-select
                v-model="createAccountForm.duration"
                :items="durationOptions"
                item-title="label"
                item-value="value"
                variant="outlined"
                density="compact"
                color="success"
                class="ui-field"
                hide-details
              />
            </div>

            <div class="field-span-2">
              <v-alert
                type="success"
                variant="tonal"
                class="rounded-lg text-caption font-weight-bold border-success"
                icon="mdi-lock-check-outline"
              >
                O cliente acessará com <strong>e-mail e senha</strong>. A conta já nasce aprovada e ativa pelo tempo escolhido.
              </v-alert>
            </div>
          </div>

          <v-alert
            v-if="!isAdmin && createAccountForm.duration > 12"
            type="warning"
            variant="tonal"
            class="rounded-lg mt-5 text-caption font-weight-bold border-warning"
            icon="mdi-shield-alert-outline"
          >
            Atenção: este tempo é maior que o padrão de vendedor. O cadastro será criado, mas fica registrado para auditoria.
          </v-alert>

          <v-alert
            v-else
            type="success"
            variant="tonal"
            class="rounded-lg mt-5 text-caption font-weight-medium border-success"
            icon="mdi-check-decagram"
          >
            Após criar, o cliente poderá entrar com o e-mail e a senha definidos aqui. O acesso vence automaticamente no prazo escolhido.
          </v-alert>
        </v-card-text>

        <v-card-actions class="pa-4 border-t d-flex justify-end gap-2" :class="isDark ? 'bg-grey-darken-3 border-white-05' : 'bg-grey-lighten-5'">
          <v-btn variant="tonal" class="font-weight-bold text-none rounded-lg px-4 btn-3d" @click="closeCreateAccountModal" :disabled="createAccountModal.loading">Cancelar</v-btn>
          <v-btn color="success" variant="flat" class="font-weight-bold text-none rounded-lg px-6 btn-3d" @click="createLeadAccountBySeller" :loading="createAccountModal.loading">
            <v-icon start>mdi-account-check</v-icon>
            Criar conta ativa
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <v-dialog v-model="showConfigModal" max-width="480">
      <v-card class="rounded-xl border shadow-indigo-soft overflow-hidden" :class="isDark ? 'bg-grey-darken-4 text-white' : 'bg-white'">
        <div class="px-5 py-4 border-b d-flex justify-space-between align-center flex-shrink-0 bg-primary position-relative overflow-hidden">
            <div class="card-bg-icon"><v-icon size="80">mdi-shield-key-outline</v-icon></div>
            <div class="d-flex align-center gap-3 position-relative z-10">
                <div class="icon-box bg-white text-primary rounded-lg d-flex align-center justify-center elevation-1" style="width: 38px; height: 38px;">
                    <v-icon size="22">mdi-key-star</v-icon>
                </div>
                <div class="text-white">
                    <div class="font-weight-bold text-uppercase opacity-80" style="font-size: 10px; letter-spacing: 1px;">Emissão de Chave</div>
                    <div class="text-h6 font-weight-black lh-1 mt-1">Liberar Acesso</div>
                </div>
            </div>
            <v-btn icon="mdi-close" variant="text" size="small" color="white" class="z-10" @click="showConfigModal = false"></v-btn>
        </div>

        <v-card-text class="pa-6">
          <label class="font-weight-bold text-caption text-uppercase tracking-wider opacity-70 mb-2 d-block">Tempo de Validade</label>
          <v-select
            v-model="accessDuration"
            :items="durationOptions"
            item-title="label"
            item-value="value"
            variant="outlined"
            density="comfortable"
            color="primary"
            class="ui-field mb-4 font-weight-bold"
            hide-details
          >
            <template v-slot:item="{ props, item }">
              <v-list-item v-bind="props">
                <template v-slot:append v-if="!isAdmin && item.raw.value > 12">
                  <v-icon size="16" color="warning">mdi-lock-outline</v-icon>
                </template>
              </v-list-item>
            </template>
          </v-select>

          <v-alert v-if="!isAdmin && accessDuration > 12" type="warning" variant="tonal" class="rounded-lg mb-0 text-caption font-weight-bold border border-warning" icon="mdi-shield-alert-outline">
            Apenas administradores podem liberar mais de 12 horas.
          </v-alert>
          <v-alert v-else type="info" variant="tonal" class="rounded-lg mb-0 text-caption font-weight-medium bg-primary-lighten-5 text-primary border-primary">
            O comportamento continuará sendo monitorado pelo motor anti-plágio.
          </v-alert>
        </v-card-text>

      <v-card-actions class="pa-4 border-t d-flex justify-end gap-2" :class="isDark ? 'bg-grey-darken-3' : 'bg-grey-lighten-5'">
        <v-btn variant="tonal" class="font-weight-bold text-none rounded-lg px-4 btn-3d" @click="showConfigModal = false">Cancelar</v-btn>

        <v-btn v-if="!isAdmin && accessDuration > 12" color="warning" variant="flat" class="font-weight-bold text-none rounded-lg px-6 btn-3d" @click="requestTimeApproval" :loading="isProcessingCode">Solicitar Aprovação</v-btn>

        <template v-else>
          <v-btn color="success" variant="flat" class="font-weight-bold text-none rounded-lg px-6 btn-3d" @click="approveAccessDirectly" :loading="isProcessingCode">
            Aprovar Direto
          </v-btn>
          <v-btn color="primary" variant="flat" class="font-weight-bold text-none rounded-lg px-6 btn-3d" @click="confirmAccessConfig" :loading="isProcessingCode">
            Emitir Código
          </v-btn>
        </template>
      </v-card-actions>
      </v-card>
    </v-dialog>

    <v-dialog v-model="accessKeyModal.show" max-width="450" persistent scrim="black opacity-80">
      <v-card class="rounded-lg shadow-2xl border-thin overflow-hidden" :class="isDark ? 'bg-grey-darken-4 text-white' : 'bg-white'">
        <div class="px-6 py-4 border-b d-flex align-center justify-space-between" :class="isDark ? 'bg-grey-darken-3 border-white-10' : 'bg-surface-light'">
          <div class="d-flex align-center gap-3">
            <v-avatar color="success-lighten-5" size="40" class="text-success-darken-2 rounded-lg">
              <v-icon>mdi-key-chain</v-icon>
            </v-avatar>
            <div>
              <h3 class="text-subtitle-1 font-weight-black leading-none mb-1 text-uppercase tracking-widest">Acesso Liberado</h3>
              <div class="text-caption opacity-70 font-mono">{{ accessKeyModal.leadName }}</div>
            </div>
          </div>
          <v-btn icon="mdi-close" variant="text" size="small" @click="accessKeyModal.show = false"></v-btn>
        </div>

        <div class="pa-6 text-center">
          <div class="text-caption font-weight-bold opacity-70 text-uppercase mb-2">Chave de Acesso Exclusiva</div>

          <div class="text-h3 font-weight-black font-mono text-primary mb-6 py-4 rounded-lg border-thin cursor-pointer d-flex align-center justify-center gap-4" :class="isDark ? 'bg-black-20 border-white-10' : 'bg-grey-lighten-5'" @click="copyToClipboard(accessKeyModal.key, 'Chave copiada!')" v-ripple>
            {{ accessKeyModal.key }}
            <v-icon color="primary" size="24">mdi-content-copy</v-icon>
          </div>

          <v-btn
            color="#25D366"
            variant="flat"
            class="btn-3d font-weight-black text-white w-100"
            size="large"
            prepend-icon="mdi-whatsapp"
            @click="sendAccessKeyWhatsapp"
          >
            ENVIAR VIA WHATSAPP
          </v-btn>
        </div>
      </v-card>
    </v-dialog>

  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch, onMounted, onUnmounted, reactive } from 'vue'
import { supabase } from '@/api/supabase'
import { useThemeStore } from '@/stores/theme'
import { useUserStore } from '@/stores/user'
import { useAppStore } from '@/stores/app';
import jsPDF from 'jspdf'
import autoTable from 'jspdf-autotable'
import * as XLSX from 'xlsx'
import { format } from 'date-fns'

const props = defineProps<{ leads: any[] }>()
const emit = defineEmits(['refresh'])

const themeStore = useThemeStore()
const userStore = useUserStore()
const isDark = computed(() => themeStore.currentMode !== 'light')
const isAdmin = computed(() => ['admin', 'super_admin'].includes(userStore.profile?.role || ''))
const appStore = useAppStore();

// ==========================================
// MODAIS E TRADUTORES DE MOTIVO
// ==========================================
const showFingerprintModal = ref(false)
const selectedFingerprintLead = ref<any>(null)
function openFingerprintModal(lead: any) {
  selectedFingerprintLead.value = lead
  showFingerprintModal.value = true
}

const showVipModal = ref(false)
const selectedVipLead = ref<any>(null)
function openVipModal(lead: any) {
  selectedVipLead.value = lead
  showVipModal.value = true
}

const showReasonModal = ref(false)
const selectedReasonLead = ref<any>(null)
function openReasonModal(lead: any) {
  selectedReasonLead.value = lead
  showReasonModal.value = true
}

function translateReasonShort(reason: string | null) {
  if (!reason) return '-';

  const map: Record<string, string> = {
    'rapid_route_cycling': 'F5 Excessivo',
    'multiple_devices': 'Uso Compartilhado',
    'devtools_opened': 'Inspecionou Código',
    'printscreen_detected': 'Tentou Print',
    'right_click': 'Tentou Salvar Arte',
    'excessive_downloads': 'Downloads em Massa',
    'bloqueio manual global': 'Bloqueio Manual',
    'violação de device/ip (login compartilhado)': 'IP Inconsistente'
  };

  return map[reason.toLowerCase()] || 'Atividade Suspeita';
}

// ==========================================
// ESTADOS DA INTEGRAÇÃO DO MOTOR DE RISCO
// ==========================================
const securityProfiles = ref<any[]>([])
const enrichedLeads = ref<any[]>([])
let pollInterval: any = null

async function fetchSecurityData() {
  try {
    const { data: profiles } = await supabase.from('security_profiles').select('*')
    securityProfiles.value = profiles || []

    enrichedLeads.value = props.leads.map(lead => {
      const profile = securityProfiles.value.find(p => String(p.user_id) === String(lead.id))

      const now = new Date()
      const expiresAt = lead.temp_auth_expires_at ? new Date(lead.temp_auth_expires_at) : null

      const isRevokedPrematurely = !lead.temp_auth_code && lead.access_status !== 'active' && expiresAt && expiresAt > now

      let bScore = profile?.risk_score || 0
      let bFlag = profile?.risk_flag || 'none'
      let bStatus = profile?.access_status || 'active'
      let bReason = profile?.risk_reason || null

      if (isRevokedPrematurely) {
         bScore = 100
         bFlag = 'high'
         bStatus = 'blocked'
         bReason = 'Violação de Device/IP (Login Compartilhado)'
      }

      let loginStatus = 'expired'
      if (expiresAt && expiresAt > now && lead.access_status === 'active') loginStatus = 'active'
      else if (lead.temp_auth_code && expiresAt && expiresAt > now) loginStatus = 'active'
      else if (isRevokedPrematurely) loginStatus = 'revoked'

      let parsedContext: any = {}
      if (lead.authorized_context) {
        if (typeof lead.authorized_context === 'string') {
          try { parsedContext = JSON.parse(lead.authorized_context) } catch (e) {}
        } else {
          parsedContext = lead.authorized_context
        }
      }

      return {
        ...lead,
        login_status: loginStatus,
        behavior_score: bScore,
        behavior_flag: bFlag,
        behavior_status: bStatus,
        behavior_reason: bReason,
        behavior_context: profile?.current_context || 'N/A',
        behavior_blocked_until: profile?.blocked_until || null,
        session_id: profile?.session_id || null,
        computed_fingerprint: profile?.device_fingerprint || parsedContext.fingerprint || null
      }
    })
  } catch (e) {
    console.error('Erro ao buscar dados do motor de risco', e)
  }
}

onMounted(() => {
  fetchSecurityData()
  pollInterval = setInterval(fetchSecurityData, 5000)
})

onUnmounted(() => {
  if (pollInterval) clearInterval(pollInterval)
})

watch(() => props.leads, fetchSecurityData, { deep: true })

// ==========================================
// ESTADOS DA TABELA E GRID
// ==========================================
const searchQuery = ref('')
const currentStatusFilter = ref('all')
const selectedLeads = ref<string[]>([])
const page = ref(1)
const itemsPerPage = 30
const reportLoading = ref(false)

const filteredLeads = computed(() => {
  let result = enrichedLeads.value
  if (searchQuery.value) {
    const q = searchQuery.value.toLowerCase()
    result = result.filter(l =>
      (l.name && l.name.toLowerCase().includes(q)) ||
      (l.email && l.email.toLowerCase().includes(q)) ||
      (l.document && l.document.includes(q)) ||
      (l.last_ip && l.last_ip.includes(q)) ||
      (l.computed_fingerprint && l.computed_fingerprint.includes(q))
    )
  }
  if (currentStatusFilter.value !== 'all') {
    result = result.filter(l => {
      if (currentStatusFilter.value === 'active') return l.login_status === 'active' && l.behavior_status !== 'blocked';
      if (currentStatusFilter.value === 'behavior_warning') return l.behavior_flag === 'medium' || l.behavior_flag === 'high' || l.behavior_status === 'revalidation_required';
      if (currentStatusFilter.value === 'blocked') return l.behavior_status === 'blocked' || l.login_status === 'revoked';
      return true;
    })
  }
  return result.sort((a, b) => {
    if (a.behavior_status === 'blocked' && b.behavior_status !== 'blocked') return -1
    if (a.behavior_status !== 'blocked' && b.behavior_status === 'blocked') return 1
    if (a.behavior_score > b.behavior_score) return -1
    if (a.behavior_score < b.behavior_score) return 1
    return new Date(b.created_at).getTime() - new Date(a.created_at).getTime()
  })
})

const paginatedLeads = computed(() => {
  const start = (page.value - 1) * itemsPerPage
  return filteredLeads.value.slice(start, start + itemsPerPage)
})

const pageCount = computed(() => Math.ceil(filteredLeads.value.length / itemsPerPage))
watch([searchQuery, currentStatusFilter], () => { page.value = 1 })

const isAllSelected = computed(() => paginatedLeads.value.length > 0 && selectedLeads.value.length === paginatedLeads.value.length)
const isIndeterminate = computed(() => selectedLeads.value.length > 0 && selectedLeads.value.length < paginatedLeads.value.length)
const toggleSelectAll = (val: boolean) => { selectedLeads.value = val ? paginatedLeads.value.map(l => l.id) : [] }

const activeLoginCount = computed(() => enrichedLeads.value.filter(l => l.login_status === 'active' && l.behavior_status !== 'blocked').length)
const suspiciousBehaviorCount = computed(() => enrichedLeads.value.filter(l => l.behavior_flag === 'medium' || l.behavior_flag === 'high' || l.behavior_status === 'revalidation_required').length)
const blockedBehaviorCount = computed(() => enrichedLeads.value.filter(l => l.behavior_status === 'blocked' || l.login_status === 'revoked').length)

const statusFilterLabel = computed(() => {
  const map: Record<string, string> = { all: 'Todos', active: 'Logins Ativos', behavior_warning: 'Risco Comportamental', blocked: 'Motor Bloqueou' }
  return map[currentStatusFilter.value] || 'Filtro'
})
function filterByStatus(status: string) { currentStatusFilter.value = status }

function getLoginStatus(lead: any) {
  if (lead.login_status === 'revoked' || lead.behavior_status === 'blocked') {
    return { color: 'error', variant: 'flat', label: 'Revogada', icon: 'mdi-shield-off' }
  }
  if (lead.login_status === 'active') {
    return { color: 'success', variant: 'tonal', label: 'Chave Ativa', icon: 'mdi-key-check' }
  }
  return { color: 'grey', variant: 'outlined', label: 'Expirada', icon: 'mdi-key-remove' }
}

function getBehaviorStatus(lead: any) {
  if (!lead) return { label: 'Desconhecido', color: 'grey' }
  if (lead.behavior_status === 'blocked' || lead.login_status === 'revoked') return { label: 'BLOQUEADO', color: 'error' }
  if (lead.behavior_status === 'revalidation_required') return { label: 'REVALIDAR', color: 'orange' }
  if (lead.behavior_score > 40) return { label: 'ALERTA', color: 'warning' }
  return { label: 'SEGURO', color: 'success' }
}

function getRiskColorText(score: number) {
  if (score >= 80) return 'text-error'
  if (score >= 40) return 'text-warning'
  return 'text-success'
}

function getEventColor(type: string) {
  if (type === 'exposure') return 'warning'
  if (type === 'scroll_speed') return 'orange'
  if (type === 'interaction') return 'success'
  if (type === 'violation') return 'error'
  return 'primary'
}

function getEventTitle(type: string) {
  if (type === 'exposure') return 'Visualizações em massa'
  if (type === 'scroll_speed') return 'Scroll rápido detectado'
  if (type === 'interaction') return 'Interação Humana'
  if (type === 'violation') return 'TENTATIVA DE PLÁGIO / COMPARTILHADO'
  return 'Evento Registrado'
}

function formatExpiration(dateString: string) {
  return format(new Date(dateString), 'dd/MM/yy HH:mm')
}

function zebraClass(index: number) {
  if (isDark.value) return index % 2 === 0 ? 'zebra-dark-a' : 'zebra-dark-b'
  return index % 2 === 0 ? 'zebra-light-a' : 'zebra-light-b'
}
function getAvatarColor(name: string) {
  const colors = ['#8B5CF6', '#10B981', '#F59E0B', '#EF4444', '#3B82F6']
  return name ? colors[name.charCodeAt(0) % colors.length] : colors[0]
}

// ==========================================
// BYPASS DIRETO (PERDÃO E BLOQUEIO ABSOLUTO)
// ==========================================
const showDossierModal = ref(false)
const selectedDossierLead = ref<any>(null)
const sessionEvents = ref<any[]>([])
const isFetchingEvents = ref(false)

async function openDossier(lead: any) {
  selectedDossierLead.value = lead
  showDossierModal.value = true
  isFetchingEvents.value = true
  sessionEvents.value = []

  try {
    let query = supabase.from('security_events_log').select('*')
    if (lead.session_id) query = query.eq('session_id', lead.session_id)
    else query = query.eq('user_id', lead.id)

    const { data } = await query.order('created_at', { ascending: false }).limit(40)
    sessionEvents.value = data || []
  } catch (err) { console.error('Erro ao buscar eventos', err) }
  finally { isFetchingEvents.value = false }
}

async function resetBehaviorRisk(lead: any) {
  if (!confirm(`Zerar o Risk Score de ${lead.name}? O Device será perdoado e limpo.`)) return
  try {
    await supabase.rpc('admin_manage_security', { p_user_id: lead.id, p_action: 'reset' })

    await supabase.from('security_profiles').update({
      risk_score: 0,
      risk_flag: 'none',
      access_status: 'active',
      blocked_until: null,
      risk_reason: null
    }).eq('user_id', lead.id)

    const { error: updateError } = await supabase.from('public_leads').update({
      temp_auth_code: null,
      temp_auth_expires_at: null,
      last_ip: null,
      authorized_context: null,
      access_status: 'inactive'
    }).eq('id', lead.id)

    if (updateError) throw updateError

    lead.behavior_score = 0
    lead.behavior_flag = 'none'
    lead.behavior_status = 'active'
    lead.login_status = 'expired'
    lead.behavior_reason = null
    lead.temp_auth_code = null
    lead.temp_auth_expires_at = null
    lead.last_ip = null
    lead.computed_fingerprint = null

    showDossierModal.value = false
  } catch (e: any) {
    alert('Erro ao perdoar: ' + e.message)
  }
}

async function forceBehaviorBlock(lead: any) {
  if (!confirm(`Bloquear o dispositivo/IP de ${lead.name}? A chave será QUEIMADA imediatamente.`)) return
  try {
    await supabase.rpc('admin_manage_security', { p_user_id: lead.id, p_action: 'block' })

    await supabase.from('security_profiles').update({
      risk_score: 100,
      risk_flag: 'high',
      access_status: 'blocked',
      risk_reason: 'Bloqueio Manual Global',
      blocked_until: new Date(Date.now() + 86400000).toISOString()
    }).eq('user_id', lead.id)

    const { error: updateError } = await supabase.from('public_leads').update({
      temp_auth_code: null,
      temp_auth_expires_at: null,
      last_ip: null,
      authorized_context: null,
      access_status: 'blocked'
    }).eq('id', lead.id)

    if (updateError) throw updateError

    lead.behavior_score = 100
    lead.behavior_flag = 'high'
    lead.behavior_status = 'blocked'
    lead.login_status = 'revoked'
    lead.behavior_reason = 'Bloqueio Manual Global'
    lead.temp_auth_code = null
    lead.temp_auth_expires_at = null
    lead.last_ip = null
    lead.computed_fingerprint = null

    showDossierModal.value = false
  } catch (e: any) {
    alert('Falha crítica ao aplicar bloqueio: ' + e.message)
  }
}

// ==========================================
// EMISSÃO DE CHAVES E COMUNICAÇÃO
// ==========================================
const isProcessingMass = ref(false)
const processingCode = ref<string | null>(null)
const showConfigModal = ref(false)
const isMassConfig = ref(false)
const leadToConfig = ref<any>(null)
const accessDuration = ref(12)
const isProcessingCode = ref(false)

const createAccountModal = reactive({
  show: false,
  loading: false
})

const createAccountForm = reactive({
  name: '',
  email: '',
  password: '',
  confirmPassword: '',
  showPassword: false,
  phone: '',
  document: '',
  duration: 12
})

const accessKeyModal = reactive({
  show: false,
  leadName: '',
  phone: '',
  key: ''
})

const durationOptions = [
  { label: '1 Hora (Teste Rápido)', value: 1 },
  { label: '12 Horas (Padrão)', value: 12 },
  { label: '24 Horas (1 Dia)', value: 24 },
  { label: '48 Horas (2 Dias)', value: 48 },
  { label: '168 Horas (7 Dias)', value: 168 },
  { label: 'Acesso Permanente', value: 87600 }
]

async function copyToClipboard(text: string, msg: string) {
  try { await navigator.clipboard.writeText(text); alert(msg) } catch (e) {}
}

function openWhatsApp(phone: string, name: string) {
  if (phone) window.open(`https://wa.me/55${phone.replace(/\D/g, '')}?text=${encodeURIComponent(`Olá ${name}, referente ao seu acesso ao nosso Acervo Digital.`)}`, '_blank')
}

function sendAccessKeyWhatsapp() {
  const phoneDigits = accessKeyModal.phone?.replace(/\D/g, '') || '';
  if (!phoneDigits) {
    appStore.showSnackbar('Atenção: Este lead não possui telefone cadastrado.', 'warning');
    return;
  }
  const prefix = phoneDigits.length <= 11 ? '55' : '';
  const finalPhone = `${prefix}${phoneDigits}`;
  const message = `Olá ${accessKeyModal.leadName}!\n\nSeu acesso exclusivo ao acervo foi aprovado.\n\nSua chave de acesso é: *${accessKeyModal.key}*\n\nBasta inserir essa chave na tela inicial para conferir as estampas.`;
  const url = `https://wa.me/${finalPhone}?text=${encodeURIComponent(message)}`;
  window.open(url, '_blank');
}

function resetCreateAccountForm() {
  createAccountForm.name = ''
  createAccountForm.email = ''
  createAccountForm.password = ''
  createAccountForm.confirmPassword = ''
  createAccountForm.showPassword = false
  createAccountForm.phone = ''
  createAccountForm.document = ''
  createAccountForm.duration = 12
}

function openCreateAccountModal() {
  resetCreateAccountForm()
  createAccountModal.show = true
}

function closeCreateAccountModal() {
  if (createAccountModal.loading) return
  createAccountModal.show = false
  resetCreateAccountForm()
}

function normalizeLeadEmail(email: string) {
  return String(email || '').trim().toLowerCase()
}

function normalizeLeadPhone(phone: string) {
  return String(phone || '').replace(/\D/g, '')
}

function validateCreateAccountForm() {
  const email = normalizeLeadEmail(createAccountForm.email)
  if (!createAccountForm.name || createAccountForm.name.trim().length < 3) return 'Informe o nome do cliente.'
  if (!email || !/^\S+@\S+\.\S+$/.test(email)) return 'Informe um e-mail válido.'
  if (!createAccountForm.password || createAccountForm.password.length < 6) return 'Informe uma senha com pelo menos 6 caracteres.'
  if (createAccountForm.password !== createAccountForm.confirmPassword) return 'A confirmação de senha não confere.'
  if (!createAccountForm.phone || normalizeLeadPhone(createAccountForm.phone).length < 10) return 'Informe um WhatsApp válido.'
  if (!createAccountForm.duration || Number(createAccountForm.duration) <= 0) return 'Selecione o tempo de ativação.'
  return null
}

async function createLeadAccountBySeller() {
  const validationError = validateCreateAccountForm()
  if (validationError) {
    appStore.showSnackbar(validationError, 'warning')
    return
  }

  createAccountModal.loading = true
  try {
    const email = normalizeLeadEmail(createAccountForm.email)
    const phone = normalizeLeadPhone(createAccountForm.phone)

    const { data, error } = await supabase.functions.invoke('create-marketplace-lead-account', {
      body: {
        name: createAccountForm.name.trim(),
        email,
        password: createAccountForm.password,
        phone,
        document: createAccountForm.document ? createAccountForm.document.trim() : null,
        durationHours: Number(createAccountForm.duration)
      }
    })

    if (error) throw error
    if (data?.error) throw new Error(data.error)

    const insertedLead = data?.lead
    const accessCode = data?.access_code || insertedLead?.temp_auth_code || 'CONTA-ATIVA'

    accessKeyModal.leadName = insertedLead?.name || createAccountForm.name.trim()
    accessKeyModal.phone = insertedLead?.phone || phone
    accessKeyModal.key = `Login: ${email} | Senha: ${createAccountForm.password}`

    appStore.showSnackbar('Conta criada ativa com e-mail e senha!', 'success')
    createAccountModal.show = false

    enrichedLeads.value = [{
      ...insertedLead,
      temp_auth_code: accessCode,
      login_status: 'active',
      behavior_score: 0,
      behavior_flag: 'none',
      behavior_status: 'active',
      behavior_reason: null,
      computed_fingerprint: null
    }, ...enrichedLeads.value]

    resetCreateAccountForm()
    emit('refresh')
  } catch (err: any) {
    console.error('Erro ao criar conta assistida:', err)

    let message = err?.message || 'falha desconhecida'

    // Quando a Edge Function retorna 409/400, o supabase-js joga FunctionsHttpError.
    // O texto útil vem no corpo da resposta, então tentamos ler aqui.
    try {
      if (err?.context?.json) {
        const body = await err.context.json()
        message = body?.error || body?.message || message
      } else if (err?.context?.text) {
        const text = await err.context.text()
        if (text) {
          try {
            const parsed = JSON.parse(text)
            message = parsed?.error || parsed?.message || text
          } catch {
            message = text
          }
        }
      }
    } catch (_) {}

    appStore.showSnackbar('Erro ao criar conta: ' + message, 'error')
  } finally {
    createAccountModal.loading = false
  }
}

function openConfigModal(lead: any = null) {
  if (lead) { leadToConfig.value = lead; isMassConfig.value = false }
  else { leadToConfig.value = null; isMassConfig.value = true }
  accessDuration.value = 12
  showConfigModal.value = true
}

async function confirmAccessConfig() {
  if (isMassConfig.value) await generateMassCodes(accessDuration.value)
  else await generateAndSendCode(leadToConfig.value, accessDuration.value)
  showConfigModal.value = false
}

async function approveAccessDirectly() {
  isProcessingCode.value = true
  try {
    const hours = accessDuration.value;
    const expiresAt = new Date();
    expiresAt.setHours(expiresAt.getHours() + hours);

    if (isMassConfig.value) {
      // Aprovação direta em massa
      const promises = selectedLeads.value.map(id => supabase.from('public_leads').update({
        temp_auth_code: null,                // Nulo significa bypass do código
        temp_auth_expires_at: expiresAt.toISOString(),
        access_status: 'active',
        auth_code_requested: false,
        last_ip: null,
        authorized_context: null
      }).eq('id', id));
      await Promise.all(promises);
      selectedLeads.value = [];
    } else {
      // Aprovação direta individual
      const { error } = await supabase.from('public_leads').update({
        temp_auth_code: null,                // Nulo significa bypass do código
        temp_auth_expires_at: expiresAt.toISOString(),
        access_status: 'active',
        auth_code_requested: false,
        last_ip: null,
        authorized_context: null
      }).eq('id', leadToConfig.value.id);

      if (error) throw error;
    }

    appStore.showSnackbar('Acesso liberado diretamente com sucesso! A tela do cliente atualizará agora.', 'success');
    showConfigModal.value = false;
    emit('refresh');
  } catch (err: any) {
    appStore.showSnackbar('Erro ao aprovar direto: ' + err.message, 'error');
  } finally {
    isProcessingCode.value = false;
  }
}

async function requestTimeApproval() {
  isProcessingCode.value = true
  try {
    if (isMassConfig.value) {
      const promises = selectedLeads.value.map(id => supabase.from('public_leads').update({ auth_code_requested: true }).eq('id', id))
      await Promise.all(promises)
      selectedLeads.value = []
    } else {
      const { error } = await supabase.from('public_leads').update({ auth_code_requested: true }).eq('id', leadToConfig.value.id)
      if (error) throw error;
    }
    showConfigModal.value = false
    emit('refresh')
  } catch (err: any) { alert('Erro ao solicitar aprovação: ' + err.message) }
  finally { isProcessingCode.value = false }
}

const generateAndSendCode = async (lead: any, hours: number) => {
    const code = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = new Date();
    expiresAt.setHours(expiresAt.getHours() + hours);

    try {
        const { error: dbError } = await supabase
            .from('public_leads')
            .update({
                temp_auth_code: code,
                temp_auth_expires_at: expiresAt.toISOString(),
                access_status: 'active',
                last_ip: null,
                authorized_context: null
            })
            .eq('id', lead.id);

        if (dbError) throw dbError;

        accessKeyModal.leadName = lead.name || 'Cliente';
        accessKeyModal.phone = lead.phone || '';
        accessKeyModal.key = code;

        const { error: edgeError } = await supabase.functions.invoke('send-approval-email-auth', {
            body: { email: lead.email, code: code, name: lead.name || 'Cliente' }
        });

        if (edgeError) {
            console.warn("🚨 ERRO DA EDGE FUNCTION:", edgeError);
            throw new Error('falha_email');
        }

        appStore.showSnackbar('Código gerado e e-mail enviado!', 'success');
        accessKeyModal.show = true;
        emit('refresh');

    } catch (error: any) {
        if (error.message === 'falha_email' || (error.message && error.message.includes('FetchError'))) {
            accessKeyModal.leadName = lead.name || 'Cliente';
            accessKeyModal.phone = lead.phone || '';
            accessKeyModal.key = code;

            accessKeyModal.show = true;
            appStore.showSnackbar('E-mail falhou, mas a chave foi gerada e liberada localmente.', 'warning');
            emit('refresh');
        } else {
            console.error("Erro SQL/Sistema:", error);
            appStore.showSnackbar(`Erro crítico: ${error.message}`, 'error');
        }
    }
};

async function generateMassCodes(hours: number) {
  isProcessingMass.value = true
  try {
    const url = (supabase as any).supabaseUrl
    const storageKey = Object.keys(localStorage).find(k => k.startsWith('sb-') && k.endsWith('-auth-token'))
    const token = JSON.parse(localStorage.getItem(storageKey || '') || '{}').access_token

    const promises = selectedLeads.value.map(async id => {
      const lead = props.leads.find(l => l.id === id)
      if (!lead) return;

      const { data: code } = await supabase.rpc('generate_premium_access_code', { p_email: lead.email, p_admin_id: userStore.profile?.id })
      if (code) {
        const expiresAt = new Date()
        expiresAt.setHours(expiresAt.getHours() + hours)

        const { error } = await supabase.from('public_leads').update({
          temp_auth_expires_at: expiresAt.toISOString(),
          last_ip: null,
          authorized_context: null,
          access_status: 'active'
        }).eq('id', id)
        if (error) throw error;

        const response = await fetch(`${url}/functions/v1/send-approval-email-auth`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` },
          body: JSON.stringify({
            email: lead.email,
            name: lead.name || 'Cliente',
            code: code
          })
        })

        if (!response.ok) {
           const errorText = await response.text()
           console.error(`🚨 ERRO DA EDGE FUNCTION (Lead ${lead.email}):`, errorText)
        }
      }
    })

    await Promise.all(promises)
    selectedLeads.value = []
    emit('refresh')
  } catch (e: any) { alert('Erro na geração em massa: ' + e.message) }
  finally { isProcessingMass.value = false }
}

async function revokeMassAccess() {
  if(!confirm(`Queimar as chaves de ${selectedLeads.value.length} leads? Eles perderão o acesso instantaneamente.`)) return
  isProcessingMass.value = true
  try {
    const promises = selectedLeads.value.map(async id => {
      const { error } = await supabase.from('public_leads').update({
        temp_auth_code: null,
        temp_auth_expires_at: null,
        last_ip: null,
        authorized_context: null,
        access_status: 'inactive'
      }).eq('id', id)
      if (error) throw error;
    })

    await Promise.all(promises)
    selectedLeads.value = []
    emit('refresh')
  } catch(e:any) { alert('Erro ao revogar: ' + e.message) }
  finally { isProcessingMass.value = false }
}

// ==========================================
// EXPORTAÇÃO (PDF E EXCEL)
// ==========================================
async function generateReport(type: 'pdf' | 'excel') {
  reportLoading.value = true

  if (filteredLeads.value.length === 0) {
    alert('Nenhum dado para exportar.')
    reportLoading.value = false
    return
  }

  const exportData = filteredLeads.value.map(l => ({
    Nome: l.name || 'S/N',
    Email: l.email || '-',
    IP: l.last_ip || '-',
    LoginAtivo: l.login_status === 'active' ? 'Sim' : 'Não',
    ScorePlagio: l.behavior_score || 0,
    StatusMotor: getBehaviorStatus(l).label
  }))

  try {
    if (type === 'excel') {
      const ws = XLSX.utils.json_to_sheet(exportData)
      const wb = XLSX.utils.book_new()
      XLSX.utils.book_append_sheet(wb, ws, "Auditoria_Seguranca")
      XLSX.writeFile(wb, `Relatorio_Seguranca_${format(new Date(), 'dd-MM-yyyy')}.xlsx`)
    } else {
      const doc = new jsPDF({ orientation: 'l', unit: 'mm', format: 'a4' })
      doc.setFontSize(16)
      doc.text('Auditoria de Acessos e Anti-Plágio', 14, 20)
      doc.setFontSize(10)
      doc.text(`Gerado em: ${format(new Date(), 'dd/MM/yyyy HH:mm')}`, 14, 28)

      autoTable(doc, {
        startY: 35,
        head: [['Nome', 'E-mail', 'IP', 'Login Liberado', 'Score Anti-Plágio', 'Status Motor']],
        body: exportData.map(row => [row.Nome, row.Email, row.IP, row.LoginAtivo, row.ScorePlagio, row.StatusMotor]),
        theme: 'grid',
        styles: { fontSize: 8, cellPadding: 2 },
        headStyles: { fillColor: [25, 118, 210] }
      })
      doc.save(`Auditoria_Seguranca_${format(new Date(), 'yyyyMMdd')}.pdf`)
    }
  } catch (error: any) {
    alert('Erro ao gerar relatório: ' + error.message)
  } finally {
    reportLoading.value = false
  }
}
</script>

<style scoped lang="scss">
.leads-layout { position: relative; width: 100%; max-width: 100%; }
.bg-glass-dark { background: rgba(10,10,12,0.85); }
.bg-glass-header { background: rgba(20,20,24,0.55); backdrop-filter: blur(14px); }
.border-bottom-white-05 { border-bottom: 1px solid rgba(255,255,255,0.08); }
.border-top-white-05 { border-top: 1px solid rgba(255,255,255,0.08); }

.background-carousel-wrapper {
  position: absolute; top: 0; left: 0; width: 100%; height: 100%;
  z-index: 0; opacity: 0.6; pointer-events: none;
}
.background-overlay {
  position: absolute; top: 0; left: 0; width: 100%; height: 100%;
  z-index: 1; background: radial-gradient(circle at center, rgba(15, 15, 19, 0.4), rgba(15, 15, 19, 0.98));
  backdrop-filter: blur(8px);
}

.controls-bar { border: 1px solid rgba(0,0,0,0.08); padding: 10px; border-radius: 8px; flex-wrap: wrap; }
.controls-dark { border-color: rgba(255,255,255,0.1); background: rgba(255,255,255,0.02); }
.search-wrap { height: 40px; padding: 0 12px; display: flex; align-items: center; border: 1px solid rgba(0,0,0,0.15); border-radius: 6px; min-width: 200px; }
.search-dark { border-color: rgba(255,255,255,0.2); background: rgba(0,0,0,0.2); }
.clean-input { border: none; outline: none; font-size: 13px; font-weight: 600; width: 100%; }

/* KPIs Estilo Anexo */
.kpi-card { color: white; position: relative; min-height: 110px; overflow: hidden; border-radius: 0 !important; border: 1px solid rgba(255,255,255,0.15); }
.kpi-bg-icon { position: absolute; right: -20px; bottom: -20px; opacity: 0.15; transform: rotate(-15deg); pointer-events: none; }
.kpi-bg-icon .v-icon { font-size: 100px; color: white; }
.kpi-label { font-size: 12px; font-weight: 900; letter-spacing: .2px; text-transform: uppercase; }
.kpi-value { font-size: 26px; font-weight: 900; letter-spacing: .2px; }

/* FIX DAS CORES DOS KPIS */
.bg-gradient-info { background: linear-gradient(135deg, #0288d1, #005b9f); }
.bg-gradient-success { background: linear-gradient(135deg, #2e7d32, #1b5e20); }
.bg-gradient-warning { background: linear-gradient(135deg, #f57c00, #e65100); }
.bg-gradient-danger { background: linear-gradient(135deg, #c62828, #b71c1c); }
.bg-gradient-purple { background: linear-gradient(135deg, #7b1fa2, #4a148c); }

.hover-elevate { transition: transform 0.2s ease, box-shadow 0.2s ease; }
.hover-elevate:hover { transform: translateY(-4px); box-shadow: 0 12px 24px rgba(0,0,0,0.2) !important; }

/* =========================================================================
   GRID TOTALMENTE DESMEMBRADA (11 COLUNAS, CADA DADO EM SEU LUGAR)
============================================================================ */
.grid-scroll {
  scrollbar-gutter: stable; -webkit-overflow-scrolling: touch;
  width: 100%; overflow-x: auto; will-change: transform;
}
.custom-scroll::-webkit-scrollbar { width: 8px; height: 8px; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.35); border-radius: 6px; }

.grid-table-container {
  display: flex; flex-direction: column;
  min-width: 1400px; /* BEM LARGO PRA NÃO ESPREMER NADA */
  width: 100%;
}

.grid-header, .grid-row {
  display: grid; align-items: stretch; width: 100%;
  /* 11 Colunas 100% Exclusivas e Isoladas */
  grid-template-columns:
    46px
    minmax(200px, 2fr)
    minmax(180px, 1.5fr)
    130px
    110px
    120px
    120px
    110px
    120px
    minmax(150px, 2fr)
    140px;
}

.cell {
  padding: 8px 12px;
  display: flex; align-items: center;
  border-right: 1px solid rgba(0,0,0,0.08);
  border-bottom: 1px solid rgba(0,0,0,0.08);
  min-height: 56px; overflow: hidden;
  transition: background-color 0.2s ease;
}

.center { justify-content: center; text-align: center; }
.grid-header .cell { min-height: 44px; font-weight: 800; text-transform: uppercase; letter-spacing: 0.5px; font-size: 9.5px; opacity: 0.8; }

.sticky-head { position: sticky; top: 0; z-index: 20; box-shadow: 0 8px 16px -4px rgba(0, 0, 0, 0.12); }

.grid-surface-light .cell { background: #f5f7fa; color: rgba(0,0,0,0.9); border-color: rgba(0,0,0,0.12) !important; }
.grid-row-light .cell { border-color: rgba(0,0,0,0.08) !important; }
.zebra-light-a .cell { background: #ffffff; }
.zebra-light-b .cell { background: #fafafa; }
.grid-row-light:hover .cell { background: #e3f2fd !important; }
.grid-selected-light .cell { background: #e8f5e9 !important; }

.grid-surface-dark .cell { background: rgba(255,255,255,0.08) !important; color: rgba(255,255,255,0.80) !important; border-color: rgba(255,255,255,0.10) !important; }
.grid-row-dark .cell { background: rgba(255,255,255,0.02); border-color: rgba(255,255,255,0.08) !important; color: rgba(255,255,255,0.9); }
.zebra-dark-a .cell { background: rgba(255,255,255,0.03) !important; }
.zebra-dark-b .cell { background: rgba(255,255,255,0.01) !important; }
.grid-row-dark:hover .cell { background: rgba(255,255,255,0.07) !important; }
.grid-selected-dark .cell { background: rgba(76, 175, 80, 0.2) !important; }

.btn-3d { border-radius: 6px !important; box-shadow: 0 3px 5px rgba(0,0,0,0.15), inset 0 2px 0 rgba(255,255,255,0.25) !important; transition: transform 0.1s ease, box-shadow 0.1s ease; text-transform: none !important; }
.btn-3d:active { transform: translateY(2px); box-shadow: 0 1px 2px rgba(0,0,0,0.15), inset 0 1px 0 rgba(255,255,255,0.2) !important; }

.chip-3d { border-radius: 6px !important; box-shadow: 0 2px 4px rgba(0,0,0,0.12), inset 0 1px 0 rgba(255,255,255,0.2) !important; text-shadow: 0 1px 2px rgba(0,0,0,0.2); }

.actions-inline { display: flex; gap: 4px; justify-content: center; }
.action-btn { width: 28px !important; height: 28px !important; color: #fff !important; }

.opacity-actions .action-btn { opacity: 0.6; transition: opacity 0.2s, transform 0.2s; }
.grid-row:hover .opacity-actions .action-btn { opacity: 1; }
.action-btn:hover { transform: scale(1.1); }

/* Identidade Visual Premium Modais */
.card-bg-icon { position: absolute; right: -10px; bottom: -20px; opacity: 0.15; transform: rotate(-15deg); pointer-events: none; }
.card-bg-icon .v-icon { color: white; }
.shadow-indigo-soft { box-shadow: 0 4px 15px rgba(63, 81, 181, 0.4); }
.lh-1 { line-height: 1.1; }

.animate-pulse { animation: pulse 1.5s infinite; }
@keyframes pulse { 0%, 100% { opacity: 1; } 50% { opacity: 0.3; } }


/* Cadastro assistido pelo vendedor */
.create-account-grid {
  display: grid;
  grid-template-columns: minmax(0, 1fr) minmax(0, 1fr);
  gap: 14px;
}

.field-span-2 {
  grid-column: span 2;
}

.form-mini-label {
  display: block;
  font-size: 10px;
  font-weight: 900;
  text-transform: uppercase;
  letter-spacing: 0.065em;
  opacity: 0.68;
  margin-bottom: 6px;
}

.create-mode-toggle {
  width: fit-content;
  max-width: 100%;
  overflow: hidden;
  border-radius: 10px !important;
}

.create-mode-toggle :deep(.v-btn) {
  min-width: 142px;
}

@media (max-width: 700px) {
  .create-account-grid {
    grid-template-columns: 1fr;
  }

  .field-span-2 {
    grid-column: span 1;
  }

  .create-mode-toggle,
  .create-mode-toggle :deep(.v-btn) {
    width: 100%;
  }
}

</style>
