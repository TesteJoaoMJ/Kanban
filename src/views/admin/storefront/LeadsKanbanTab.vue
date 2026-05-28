<template>
  <div
    class="design-layout font-sans relative overflow-hidden"
    :class="isDark ? 'bg-glass-dark text-white' : 'bg-grey-lighten-5 text-grey-darken-4'"
  >
    <audio ref="alertSoundRef" src="https://cdn.shopify.com/s/files/1/0661/4574/6991/files/new-notification-022-370046.mp3?v=1757327480" preload="auto"></audio>

    <div v-if="isDark" class="background-carousel-wrapper">
      <v-carousel cycle height="100%" hide-delimiters :show-arrows="false" interval="15000" class="fill-height">
        <v-carousel-item src="@/assets/1.jpg" cover></v-carousel-item>
        <v-carousel-item src="@/assets/2.jpg" cover></v-carousel-item>
        <v-carousel-item src="@/assets/3.jpg" cover></v-carousel-item>
      </v-carousel>
      <div class="background-overlay"></div>
    </div>

    <div class="content-wrapper z-10 relative d-flex flex-column h-100">

      <div class="header-bar px-6 py-4 d-flex align-center justify-space-between flex-shrink-0 relative"
           :class="isDark ? 'bg-glass-header border-bottom-white-05' : 'bg-white border-b border-grey-lighten-2 shadow-sm'">

        <div class="d-flex flex-column">
          <div class="breadcrumb text-caption">
            <span class="opacity-70">Marketplace B2B</span>
            <span class="mx-2 opacity-50">></span>
            <span class="font-weight-bold">Gestão Comercial</span>
          </div>
          <div class="text-h6 font-weight-black tracking-tight leading-none mt-1 d-flex align-center gap-2" :class="isDark ? 'text-white' : 'text-grey-darken-4'">
            Pipeline de Leads
            <v-chip size="x-small" color="primary" variant="flat" class="font-weight-black px-2 chip-3d">CRM ENTERPRISE</v-chip>
          </div>
        </div>

        <div class="d-flex align-center gap-3">
          <v-tooltip location="bottom">
             <template v-slot:activator="{ props }">
                <v-btn v-bind="props" variant="outlined" class="btn-rect btn-3d font-weight-bold bg-white" height="40" prepend-icon="mdi-robot-outline" :color="isDark ? 'grey-darken-3 text-white' : 'indigo'" @click="showAutomationsModal = true">
                  Automações
                </v-btn>
             </template>
             <span>Configurar Gatilhos e Ações Automáticas</span>
          </v-tooltip>

          <v-tooltip location="bottom">
             <template v-slot:activator="{ props }">
                <v-btn v-bind="props" variant="flat" class="btn-rect btn-3d font-weight-bold" height="40" prepend-icon="mdi-view-column-plus" color="primary" @click="showColumnManagerModal = true">
                  Gerenciar Funil
                </v-btn>
             </template>
             <span>Criar e organizar colunas manualmente</span>
          </v-tooltip>

          <v-btn variant="flat" class="btn-rect btn-3d font-weight-bold shadow-gold text-black" height="40" prepend-icon="mdi-account-plus" color="warning" @click="openLeadFormModal(null)">
            Novo Lead
          </v-btn>
        </div>
      </div>

      <div class="px-6 pt-4 pb-2 flex-shrink-0 relative">
        <v-row dense class="mb-4">
           <v-col cols="12" sm="6" md="3">
              <v-card class="kpi-card kpi-rect bg-gradient-info py-3 px-4 hover-elevate cursor-pointer" elevation="2" @click="advancedFilters.accessStatus = 'all'; advancedFilters.riskLevel = 'all'">
                  <div class="kpi-bg-icon"><v-icon>mdi-account-group</v-icon></div>
                  <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                      <div class="d-flex align-center gap-2">
                          <v-icon size="18" class="opacity-80">mdi-account-group</v-icon>
                          <span class="kpi-label">Base de Leads</span>
                      </div>
                      <div class="kpi-number-group my-1"><span class="kpi-value">{{ allLeads.length }}</span></div>
                      <div class="kpi-footer">Total no pipeline</div>
                  </div>
              </v-card>
           </v-col>
           <v-col cols="12" sm="6" md="3">
              <v-card class="kpi-card kpi-rect bg-gradient-warning py-3 px-4 hover-elevate cursor-pointer" elevation="2" @click="advancedFilters.riskLevel = 'medium'">
                  <div class="kpi-bg-icon"><v-icon>mdi-fire</v-icon></div>
                  <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                      <div class="d-flex align-center gap-2">
                          <v-icon size="18" class="opacity-80">mdi-alert-decagram</v-icon>
                          <span class="kpi-label">Atenção Necessária</span>
                      </div>
                      <div class="kpi-number-group my-1"><span class="kpi-value">{{ leadsEstagnados }}</span></div>
                      <div class="kpi-footer">Violando SLAs de tempo</div>
                  </div>
              </v-card>
           </v-col>
           <v-col cols="12" sm="6" md="3">
              <v-card class="kpi-card kpi-rect bg-gradient-red py-3 px-4 hover-elevate cursor-pointer" elevation="2" @click="advancedFilters.riskLevel = 'high'">
                  <div class="kpi-bg-icon"><v-icon>mdi-shield-off</v-icon></div>
                  <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                      <div class="d-flex align-center gap-2">
                          <v-icon size="18" class="opacity-80">mdi-shield-alert</v-icon>
                          <span class="kpi-label">Risco Motor</span>
                      </div>
                      <div class="kpi-number-group my-1"><span class="kpi-value">{{ leadsBloqueados }}</span></div>
                      <div class="kpi-footer">Alto risco ou bloqueio</div>
                  </div>
              </v-card>
           </v-col>
           <v-col cols="12" sm="6" md="3">
              <v-card class="kpi-card kpi-rect bg-gradient-success py-3 px-4 hover-elevate cursor-pointer" elevation="2" @click="advancedFilters.accessStatus = 'active'">
                  <div class="kpi-bg-icon"><v-icon>mdi-check-decagram</v-icon></div>
                  <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                      <div class="d-flex align-center gap-2">
                          <v-icon size="18" class="opacity-80">mdi-key-star</v-icon>
                          <span class="kpi-label">Convertidos</span>
                      </div>
                      <div class="kpi-number-group my-1"><span class="kpi-value">{{ leadsConvertidos }}</span></div>
                      <div class="kpi-footer">Chaves VIP ativas</div>
                  </div>
              </v-card>
           </v-col>
        </v-row>

        <div class="controls-bar d-flex flex-wrap align-center justify-space-between mb-2 gap-3" :class="isDark ? 'controls-dark' : 'controls-light'">
          <div class="d-flex align-center gap-3 flex-wrap">
             <div class="search-wrap d-flex align-center" :class="isDark ? 'search-dark' : 'search-light'" style="width: 280px;">
                 <v-icon :color="isDark ? 'white-70' : 'grey-darken-1'">mdi-magnify</v-icon>
                 <input v-model="searchQuery" type="text" placeholder="Buscar cliente, email, telefone..." class="clean-input flex-grow-1 ml-2" :class="isDark ? 'text-white' : 'text-grey-darken-4'"/>
             </div>

             <v-select
                v-model="advancedFilters.accessStatus"
                :items="[{label:'Todos os Status', value:'all'}, {label:'Acesso Liberado (ON)', value:'active'}, {label:'Expirado/Sem Acesso', value:'expired'}]"
                item-title="label"
                item-value="value"
                variant="outlined"
                density="compact"
                hide-details
                class="filter-select"
                style="max-width: 200px;"
                :bg-color="isDark ? 'rgba(255,255,255,0.05)' : 'white'"
             ></v-select>

             <v-select
                v-model="advancedFilters.riskLevel"
                :items="[{label:'Qualquer Risco', value:'all'}, {label:'Seguros', value:'low'}, {label:'Atenção (Score > 40)', value:'medium'}, {label:'Crítico/Bloqueado (Score > 70)', value:'high'}]"
                item-title="label"
                item-value="value"
                variant="outlined"
                density="compact"
                hide-details
                class="filter-select"
                style="max-width: 240px;"
                :bg-color="isDark ? 'rgba(255,255,255,0.05)' : 'white'"
             ></v-select>
          </div>

          <v-btn v-if="hasActiveFilters" variant="text" color="error" size="small" class="font-weight-bold" @click="clearFilters">
             Limpar Filtros
          </v-btn>
        </div>
      </div>

      <div class="kanban-master-container px-6 pb-4 z-high flex-grow-1">
        <v-card class="kanban-board-card rounded-0 border-thin h-100" :class="isDark ? 'glass-card border-white-05' : 'bg-transparent shadow-none'" :elevation="0">

          <div v-if="loading" class="d-flex flex-column justify-center align-center h-100">
             <v-progress-circular indeterminate color="primary" size="64" width="6"></v-progress-circular>
             <div class="mt-4 font-weight-medium opacity-70">Sincronizando pipeline...</div>
          </div>

          <div v-else-if="columns.length === 0" class="d-flex flex-column justify-center align-center h-100 opacity-60 bg-white rounded-xl border">
             <v-icon size="64" class="mb-4">mdi-view-column-outline</v-icon>
             <h2 class="text-h5 font-weight-black mb-2">Funil Vazio</h2>
             <p>Clique em "Gerenciar Funil" no topo para adicionar sua primeira coluna.</p>
          </div>

          <div v-else class="kanban-container custom-scroll-x pa-2 h-100">
             <draggable v-model="columns" item-key="id" class="d-flex h-100" handle=".column-drag-handle" @change="saveColumnOrder">
                <template #item="{ element: col }">
                    <div class="kanban-column border-r rounded-lg overflow-hidden shadow-sm mr-4 d-flex flex-column transition-all"
                         :style="getColumnBodyStyle(col.accent_color)">

                        <div class="column-header pa-3 position-relative overflow-hidden column-drag-handle cursor-grab"
                             :style="getColumnHeaderStyle(col.accent_color)">

                            <div class="d-flex justify-space-between align-start z-10 position-relative">
                              <div class="d-flex flex-column">
                                 <div class="d-flex align-center gap-2 mb-1">
                                    <div class="status-dot pulsing-dot" :style="`background-color: ${col.accent_color}`"></div>
                                    <span class="text-subtitle-2 font-weight-black text-uppercase lh-1" :class="isDark ? 'text-white' : 'text-grey-darken-4'">{{ col.title }}</span>
                                 </div>
                                 <div class="d-flex align-center gap-2 text-[10px] font-weight-bold opacity-80" :class="isDark ? 'text-white' : 'text-grey-darken-3'">
                                    <span>Prob: {{ col.win_probability || 0 }}%</span> | <span>SLA: {{ col.rotting_days || 0 }}d</span>
                                 </div>
                              </div>
                              <v-chip size="small" :color="getColLeads(col.id).length > (col.wip_limit || 999) ? 'error' : col.accent_color" variant="flat" class="font-weight-black chip-3d px-2 text-white">
                                  {{ getColLeads(col.id).length }} <span v-if="col.wip_limit > 0">/ {{ col.wip_limit }}</span>
                              </v-chip>
                           </div>
                           <div class="absolute top-0 right-0 w-50 h-100 opacity-30" style="background: linear-gradient(90deg, transparent, #ffffff); pointer-events: none;"></div>
                        </div>

                        <draggable :list="getColLeads(col.id)" group="leads" item-key="id" class="kanban-content pa-3 custom-scroll flex-grow-1" @change="onLeadMoved($event, col)">
                            <template #item="{ element: lead }">
                                <div class="mb-3 cursor-grab" :data-id="lead.id">
                                    <v-card
                                        class="storefront-card rounded-lg border-s-4 shadow-md position-relative overflow-hidden"
                                        :class="[isDark ? 'bg-grey-darken-4 border-white-05' : 'bg-white border-thin', getRottingClass(lead, col)]"
                                        :style="`border-left-color: ${getRottingClass(lead, col) ? '#FF5252' : col.accent_color} !important; border-left-width: 4px !important;`"
                                        @click="openDossierModal(lead)"
                                        v-ripple
                                    >
                                        <div v-if="getRottingClass(lead, col)" class="rotting-bg-glow"></div>

                                        <v-card-text class="pa-3 position-relative z-10">
                                            <div class="d-flex align-center justify-space-between mb-2">
                                                <div class="d-flex align-center gap-2">
                                                    <v-avatar size="24" :color="getAvatarColor(lead.name)" class="text-white text-[10px] font-weight-bold shadow-sm">
                                                        {{ getInitials(lead.name) }}
                                                    </v-avatar>
                                                    <span class="text-caption font-weight-black text-truncate" :class="isDark ? 'text-white' : 'text-grey-darken-4'" style="max-width: 140px;" :title="lead.name">
                                                        {{ lead.name || 'Lead Anônimo' }}
                                                    </span>
                                                </div>
                                                <v-icon v-if="lead.behavior_score > 60" size="14" color="error" class="animate-bounce" title="Risco Alto de Plágio">mdi-shield-alert</v-icon>
                                            </div>

                                            <div class="text-[10px] opacity-70 text-truncate mb-2 d-flex align-center gap-1" :title="lead.email">
                                                <v-icon size="10">mdi-email-outline</v-icon> {{ lead.email }}
                                            </div>

                                            <div class="mt-2 d-flex align-center justify-space-between">
                                                <v-chip size="x-small" :color="isSlaBreached(lead, col) ? 'error' : 'grey'" variant="tonal" class="font-weight-bold px-1" style="font-size: 9px;">
                                                    <v-icon start size="10">mdi-clock-fast</v-icon> {{ getFormattedTimeInCol(lead) }}
                                                </v-chip>

                                                <v-chip size="x-small" :color="lead.login_status === 'active' ? 'success' : 'error'" variant="flat" class="font-weight-bold px-1 text-[9px] chip-3d text-white">
                                                    {{ lead.login_status === 'active' ? 'Chave ON' : 'Sem Acesso' }}
                                                </v-chip>
                                            </div>

                                            <div class="mt-3 pt-2 border-t d-flex align-center justify-space-between" :class="isDark ? 'border-white-10' : 'border-grey-lighten-3'">
                                                <v-btn size="x-small" variant="tonal" color="success" class="font-weight-bold btn-3d text-[10px]" @click.stop="openWhatsApp(lead.phone, lead.name)" :disabled="!lead.phone">
                                                    <v-icon start size="12">mdi-whatsapp</v-icon> Contato
                                                </v-btn>

                                                <v-menu location="bottom end">
                                                    <template v-slot:activator="{ props }">
                                                        <v-btn v-bind="props" size="x-small" icon variant="text" class="opacity-50 hover-opacity-100" @click.stop>
                                                            <v-icon size="16">mdi-dots-vertical</v-icon>
                                                        </v-btn>
                                                    </template>
                                                    <v-list density="compact" nav :class="isDark ? 'bg-grey-darken-4 text-white' : 'bg-white'" class="shadow-xl border-thin rounded-lg">
                                                        <v-list-item @click="openVIPConfigModal(lead)" class="text-primary font-weight-bold">
                                                            <template v-slot:prepend><v-icon size="14" class="mr-2">mdi-key-star</v-icon></template>
                                                            <v-list-item-title class="text-caption">Emitir Chave VIP</v-list-item-title>
                                                        </v-list-item>
                                                        <v-list-item @click="openLeadFormModal(lead)" class="text-info font-weight-bold">
                                                            <template v-slot:prepend><v-icon size="14" class="mr-2">mdi-pencil</v-icon></template>
                                                            <v-list-item-title class="text-caption">Editar Lead</v-list-item-title>
                                                        </v-list-item>
                                                        <v-divider class="my-1 border-opacity-20"></v-divider>
                                                        <v-list-item @click="deleteLead(lead.id)" class="text-error font-weight-bold">
                                                            <template v-slot:prepend><v-icon size="14" class="mr-2">mdi-trash-can-outline</v-icon></template>
                                                            <v-list-item-title class="text-caption">Excluir Lead</v-list-item-title>
                                                        </v-list-item>
                                                    </v-list>
                                                </v-menu>
                                            </div>
                                        </v-card-text>
                                    </v-card>
                                </div>
                            </template>
                        </draggable>

                    </div>
                </template>
             </draggable>
          </div>
        </v-card>
      </div>

    </div>

    <v-dialog v-model="showColumnManagerModal" max-width="750" persistent>
        <v-card class="rounded-xl border shadow-lg" :class="isDark ? 'bg-grey-darken-4 text-white' : 'bg-white'">
            <v-card-title class="d-flex align-center justify-space-between bg-primary text-white pa-4">
                <div class="d-flex align-center gap-2"><v-icon>mdi-view-column-plus</v-icon> Configuração do Funil (Pipeline)</div>
                <v-btn icon="mdi-close" variant="text" color="white" @click="showColumnManagerModal = false"></v-btn>
            </v-card-title>
            <v-card-text class="pa-4">
                <v-alert color="info" variant="tonal" class="text-caption mb-4 border" density="compact">Crie as etapas da sua jornada de vendas. Você pode definir limites para evitar gargalos (WIP) e definir prazos (SLA) para cobrar os vendedores.</v-alert>

                <v-row class="mb-4 align-center" dense>
                    <v-col cols="12" md="4"><v-text-field v-model="newCol.title" label="Nome da Etapa" density="compact" hide-details variant="outlined"></v-text-field></v-col>
                    <v-col cols="6" md="2"><v-text-field v-model.number="newCol.win_probability" type="number" label="Prob. (%)" density="compact" hide-details variant="outlined"></v-text-field></v-col>
                    <v-col cols="6" md="2"><v-text-field v-model.number="newCol.rotting_days" type="number" label="SLA (Dias)" density="compact" hide-details variant="outlined" hint="Tempo para estagnar"></v-text-field></v-col>
                    <v-col cols="6" md="2">
                        <v-tooltip location="top">
                          <template #activator="{props}"><input v-bind="props" type="color" v-model="newCol.accent_color" class="color-picker w-100 rounded" title="Cor"></template>
                          Cor da Etapa
                        </v-tooltip>
                    </v-col>
                    <v-col cols="6" md="2"><v-btn color="success" block class="btn-3d font-weight-bold" @click="addColumn" :loading="isSavingCol">Adicionar</v-btn></v-col>
                </v-row>

                <v-table density="compact" class="border rounded" :class="isDark ? 'bg-grey-darken-3 text-white' : 'bg-grey-lighten-5'">
                    <thead><tr><th>Etapa</th><th>Prob.</th><th>SLA (Alerta)</th><th>Ações</th></tr></thead>
                    <tbody>
                        <tr v-for="col in columns" :key="col.id">
                            <td class="font-weight-bold"><div class="status-dot mr-2 d-inline-block" :style="`background-color: ${col.accent_color}`"></div>{{ col.title }}</td>
                            <td>{{ col.win_probability || 0 }}%</td>
                            <td>{{ col.rotting_days > 0 ? col.rotting_days + ' dias' : 'Sem SLA' }}</td>
                            <td class="text-right"><v-btn icon="mdi-delete" size="small" variant="text" color="error" @click="deleteColumn(col.id)"></v-btn></td>
                        </tr>
                    </tbody>
                </v-table>
            </v-card-text>
        </v-card>
    </v-dialog>

    <v-dialog v-model="showAutomationsModal" max-width="850" persistent>
        <v-card class="rounded-xl border shadow-lg" :class="isDark ? 'bg-grey-darken-4 text-white' : 'bg-white'">
            <v-card-title class="d-flex align-center justify-space-between bg-indigo-darken-3 text-white pa-4">
                <div class="d-flex align-center gap-2"><v-icon>mdi-robot</v-icon> Motor de Automações & Gatilhos</div>
                <v-btn icon="mdi-close" variant="text" color="white" @click="showAutomationsModal = false"></v-btn>
            </v-card-title>
            <v-card-text class="pa-6" :class="isDark ? 'bg-grey-darken-4' : 'bg-grey-lighten-5'">
                <div class="d-flex justify-space-between align-center mb-4">
                   <p class="text-body-2 opacity-70 mb-0">Crie regras manuais de "SE / ENTÃO" para o sistema trabalhar sozinho. O motor varre a base a cada 5 segundos.</p>
                   <v-btn color="indigo" class="btn-3d font-weight-bold" prepend-icon="mdi-plus" @click="openRuleBuilder">Nova Regra</v-btn>
                </div>

                <v-list density="comfortable" class="border rounded-lg bg-transparent">
                    <div v-if="automations.length === 0" class="pa-6 text-center opacity-60">Nenhuma automação configurada.</div>
                    <v-list-item v-for="rule in automations" :key="rule.id" class="border-b mb-2 mx-2 rounded shadow-sm" :class="isDark ? 'bg-surface-card border-white-05' : 'bg-white'">
                        <template v-slot:prepend><v-switch v-model="rule.is_active" color="success" hide-details density="compact" @change="toggleAutomation(rule)"></v-switch></template>
                        <v-list-item-title class="font-weight-bold text-indigo">{{ rule.name }}</v-list-item-title>
                        <v-list-item-subtitle class="text-caption mt-1 opacity-80 d-flex flex-wrap align-center gap-1">
                            <v-chip size="x-small" variant="flat" color="grey" class="text-white font-weight-bold">
                                <v-icon start size="10">mdi-filter</v-icon>
                                {{ rule.condition_value.source_column_id && rule.condition_value.source_column_id !== 'all' ? 'Origem: ' + (columns.find(c => c.id === rule.condition_value.source_column_id)?.title || 'Desconhecida') : 'Qualquer Coluna' }}
                            </v-chip>
                            <span class="mx-1">|</span>
                            <strong>SE:</strong> {{ getTriggerLabel(rule.trigger_event) }}
                            <span v-if="rule.trigger_event === 'time_in_column'" class="bg-indigo-lighten-5 text-indigo-darken-4 px-1 rounded mx-1">
                                {{ rule.condition_value.timeValue }} {{ getUnitLabel(rule.condition_value.timeUnit) }}
                            </span>
                            <span v-if="rule.trigger_event === 'risk_score_high'" class="bg-red-lighten-5 text-red-darken-4 px-1 rounded mx-1">> {{ rule.condition_value.score }}</span>
                            <v-icon size="12" class="mx-1">mdi-arrow-right</v-icon>
                            <strong>ENTÃO:</strong> {{ getActionLabel(rule.action_type) }}
                        </v-list-item-subtitle>
                        <template v-slot:append><v-btn icon="mdi-delete" size="small" variant="text" color="error" @click="deleteAutomation(rule.id)"></v-btn></template>
                    </v-list-item>
                </v-list>
            </v-card-text>
        </v-card>
    </v-dialog>

    <v-dialog v-model="showRuleBuilder" max-width="650">
        <v-card class="rounded-xl pa-5 border shadow-lg" :class="isDark ? 'bg-grey-darken-3 text-white' : 'bg-white'">
            <h3 class="text-h6 font-weight-black mb-4 text-indigo">Construir Lógica de Automação</h3>

            <v-text-field v-model="newRule.name" label="Nome desta Automação (Ex: Alerta de Plágio)" variant="outlined" density="comfortable" class="mb-4 font-weight-bold"></v-text-field>

            <div class="pa-4 rounded border mb-4" :class="isDark ? 'bg-grey-darken-4 border-white-10' : 'bg-grey-lighten-5'">
                <h4 class="text-caption font-weight-bold text-uppercase mb-3 text-warning"><v-icon size="14">mdi-lightning-bolt</v-icon> 1. Condição do Gatilho (SE)</h4>

                <v-select v-model="newRule.condition_value.source_column_id" :items="[{title:'Qualquer Coluna do Funil (Global)', id:'all'}, ...columns]" item-title="title" item-value="id" label="Onde o lead precisa estar?" variant="outlined" density="comfortable" class="mb-3" color="warning"></v-select>

                <v-select v-model="newRule.trigger_event" :items="triggerOptions" item-title="label" item-value="value" label="O que deve acontecer com ele?" variant="outlined" density="comfortable" hide-details class="mb-3" color="warning"></v-select>

                <v-row v-if="newRule.trigger_event === 'time_in_column'" dense class="mb-3 mt-1">
                   <v-col cols="6"><v-text-field v-model.number="newRule.condition_value.timeValue" type="number" label="Quantidade" variant="outlined" density="comfortable" hide-details></v-text-field></v-col>
                   <v-col cols="6"><v-select v-model="newRule.condition_value.timeUnit" :items="timeUnits" item-title="label" item-value="value" label="Unidade de Tempo" variant="outlined" density="comfortable" hide-details></v-select></v-col>
                </v-row>

                <v-text-field v-if="newRule.trigger_event === 'risk_score_high'" v-model.number="newRule.condition_value.score" type="number" label="Score atingir ou ultrapassar:" variant="outlined" density="comfortable" hide-details class="mt-2"></v-text-field>
                <v-text-field v-if="newRule.trigger_event === 'missing_contact'" v-model.number="newRule.condition_value.timeValue" type="number" label="Dias sem preencher telefone:" variant="outlined" density="comfortable" hide-details class="mt-2"></v-text-field>
            </div>

            <div class="pa-4 rounded border mb-4" :class="isDark ? 'bg-grey-darken-4 border-white-10' : 'bg-grey-lighten-5'">
                <h4 class="text-caption font-weight-bold text-uppercase mb-3 text-success"><v-icon size="14">mdi-robot</v-icon> 2. Execução (ENTÃO)</h4>
                <v-select v-model="newRule.action_type" :items="actionOptions" item-title="label" item-value="value" label="O que o sistema deve fazer?" variant="outlined" density="comfortable" hide-details class="mb-3" color="success"></v-select>

                <v-select v-if="newRule.action_type === 'move_to_column'" v-model="newRule.action_payload.target_column_id" :items="columns" item-title="title" item-value="id" label="Para qual Coluna mover?" variant="outlined" density="comfortable" hide-details></v-select>
                <v-text-field v-if="newRule.action_type === 'set_alert'" v-model="newRule.action_payload.message" label="Mensagem do Alerta Visível" variant="outlined" density="comfortable" hide-details></v-text-field>

                <v-row v-if="newRule.action_type === 'change_risk'" dense class="mt-1">
                    <v-col cols="6"><v-select v-model="newRule.action_payload.risk_action" :items="[{title:'Aumentar Score (+ Risco)', value:'increase'}, {title:'Diminuir Score (- Risco)', value:'decrease'}, {title:'Zerar Risco', value:'reset'}]" item-title="title" item-value="value" label="Ação no Risco" variant="outlined" density="comfortable" hide-details></v-select></v-col>
                    <v-col cols="6"><v-text-field v-if="newRule.action_payload.risk_action !== 'reset'" v-model.number="newRule.action_payload.risk_amount" type="number" label="Quantos pontos?" variant="outlined" density="comfortable" hide-details></v-text-field></v-col>
                </v-row>
            </div>

            <div class="d-flex justify-end gap-2 mt-2">
                <v-btn variant="text" @click="showRuleBuilder = false">Cancelar</v-btn>
                <v-btn color="indigo" variant="flat" class="btn-3d font-weight-bold px-6 text-white" @click="saveAutomation" :loading="isSavingRule">Salvar Ativação</v-btn>
            </div>
        </v-card>
    </v-dialog>

    <v-dialog v-model="showDossierModal" max-width="850" persistent>
        <v-card class="rounded-xl border shadow-lg d-flex flex-column" :class="isDark ? 'bg-grey-darken-4 text-white border-white-10' : 'bg-white'" height="700px">
          <v-card-title class="pa-0 d-flex flex-column flex-shrink-0">
            <div class="pa-5 d-flex justify-space-between align-center bg-primary text-white">
              <div class="d-flex align-center gap-4">
                <v-avatar size="56" color="white" class="text-primary font-weight-black text-h5 shadow-sm">{{ getInitials(selectedDossierLead?.name) }}</v-avatar>
                <div>
                  <span class="font-weight-black text-h5 d-block lh-1">{{ selectedDossierLead?.name || 'Lead Anônimo' }}</span>
                  <span class="text-caption opacity-80 d-flex align-center gap-1 mt-1"><v-icon size="12">mdi-email</v-icon> {{ selectedDossierLead?.email }}</span>
                </div>
              </div>
              <v-btn icon="mdi-close" variant="text" color="white" @click="showDossierModal = false"></v-btn>
            </div>
            <v-tabs v-model="dossierTab" bg-color="transparent" color="primary" class="border-b font-weight-bold">
              <v-tab value="info"><v-icon start>mdi-card-account-details</v-icon> Dados & Acesso</v-tab>
              <v-tab value="timeline"><v-icon start>mdi-history</v-icon> Histórico & Automações</v-tab>
            </v-tabs>
          </v-card-title>

          <v-card-text class="pa-6 overflow-y-auto custom-scroll" :class="isDark ? 'bg-grey-darken-4' : 'bg-grey-lighten-5'">
             <v-window v-model="dossierTab">
                <v-window-item value="info">
                   <v-row>
                     <v-col cols="12" md="6">
                        <v-card class="pa-4 border shadow-sm" :class="isDark ? 'bg-surface-card border-white-05' : 'bg-white'">
                           <h4 class="text-caption font-weight-black text-uppercase opacity-60 mb-4">Informações do Lead</h4>
                           <div class="mb-2"><span class="text-caption d-block opacity-70">Telefone</span><strong>{{ selectedDossierLead?.phone || 'N/A' }}</strong></div>
                           <div class="mb-2"><span class="text-caption d-block opacity-70">Documento</span><strong>{{ selectedDossierLead?.document || 'N/A' }}</strong></div>
                           <div><span class="text-caption d-block opacity-70">Cadastrado em</span><strong>{{ formatDateFull(selectedDossierLead?.created_at) }}</strong></div>
                        </v-card>
                     </v-col>
                     <v-col cols="12" md="6">
                        <v-card class="pa-4 border shadow-sm h-100 d-flex flex-column justify-center align-center text-center" :class="isDark ? 'bg-surface-card border-white-05' : 'bg-white'">
                           <template v-if="selectedDossierLead?.login_status === 'active'">
                               <v-icon color="success" size="48">mdi-key-check</v-icon>
                               <div class="font-weight-black text-success mt-2">CHAVE VIP ATIVA</div>
                               <div class="text-caption mt-1">Válida até: {{ formatDate(selectedDossierLead?.temp_auth_expires_at) }}</div>
                           </template>
                           <template v-else>
                               <v-icon color="error" size="48">mdi-lock</v-icon>
                               <div class="font-weight-black text-error mt-2">SEM ACESSO AO CATÁLOGO</div>
                           </template>
                           <v-btn block color="primary" variant="flat" class="mt-4 btn-3d font-weight-bold" @click="openVIPConfigModal(selectedDossierLead)">Emitir/Renovar Chave</v-btn>
                        </v-card>
                     </v-col>
                     <v-col cols="12">
                        <v-card class="pa-4 border shadow-sm" :class="isDark ? 'bg-surface-card border-white-05' : 'bg-white'">
                            <div class="d-flex justify-space-between align-center mb-2">
                                <h4 class="text-caption font-weight-black text-uppercase opacity-60">Risk Score (Anti-Plágio)</h4>
                                <v-chip size="x-small" :color="selectedDossierLead?.behavior_score > 50 ? 'error' : 'success'" variant="flat" class="font-weight-bold">{{ selectedDossierLead?.behavior_score || 0 }} / 100</v-chip>
                            </div>
                            <v-progress-linear :model-value="selectedDossierLead?.behavior_score || 0" :color="selectedDossierLead?.behavior_score > 50 ? 'error' : 'success'" height="8" rounded striped></v-progress-linear>
                            <p class="text-[10px] opacity-70 mt-2 mb-0">Risco baseado na análise de tráfego. Scores altos indicam compartilhamento de conta ou extração em massa (Crawlers).</p>
                        </v-card>
                     </v-col>
                   </v-row>
                </v-window-item>

                <v-window-item value="timeline">
                    <div class="d-flex align-center justify-space-between mb-4">
                        <span class="text-caption font-weight-bold opacity-70">Ações e gatilhos automáticos disparados para este lead.</span>
                        <v-btn size="small" variant="tonal" color="primary" class="font-weight-bold" @click="addNote">Adicionar Anotação</v-btn>
                    </div>
                    <v-timeline density="compact" align="start">
                        <v-timeline-item v-for="log in leadHistory" :key="log.id" :dot-color="getHistoryColor(log.action_type)" size="small">
                            <div class="pa-3 border rounded shadow-sm" :class="isDark ? 'bg-grey-darken-3 border-white-10' : 'bg-white border-grey-lighten-2'">
                                <div class="d-flex justify-space-between">
                                    <strong class="text-body-2">{{ log.description }}</strong>
                                    <span class="text-[10px] opacity-60 font-weight-bold">{{ formatDate(log.created_at) }}</span>
                                </div>
                                <div v-if="log.action_type === 'automation'" class="text-[10px] text-purple font-weight-bold mt-1"><v-icon size="12">mdi-robot</v-icon> Movido por Automação</div>
                            </div>
                        </v-timeline-item>
                    </v-timeline>
                    <div v-if="leadHistory.length===0" class="text-center opacity-50 py-4 font-italic">Sem histórico registrado na linha do tempo.</div>
                </v-window-item>
             </v-window>
          </v-card-text>
        </v-card>
    </v-dialog>

    <v-dialog v-model="showNotificationsModal" max-width="500">
        <v-card class="rounded-xl border shadow-lg" :class="isDark ? 'bg-grey-darken-4' : 'bg-white'">
            <v-card-title class="bg-error text-white pa-4 font-weight-black d-flex justify-space-between align-center">
                <span><v-icon start>mdi-bell-alert</v-icon> Central de Alertas do CRM</span>
                <v-btn icon="mdi-close" variant="text" size="small" @click="showNotificationsModal = false"></v-btn>
            </v-card-title>
            <v-list density="compact" class="bg-transparent pa-4 custom-scroll" style="max-height: 400px; overflow-y: auto;">
                <v-list-item v-for="alert in activeAlerts" :key="alert.id" class="border rounded mb-3 elevation-1" :class="isDark ? 'bg-surface-card border-white-10' : 'bg-red-lighten-5 border-red-lighten-4'">
                    <v-list-item-title class="font-weight-black text-error text-wrap lh-1-2 mb-1"><v-icon size="14" class="mr-1">mdi-alert-circle</v-icon> {{ alert.message }}</v-list-item-title>
                    <v-list-item-subtitle class="text-caption opacity-70">{{ formatDate(alert.created_at) }}</v-list-item-subtitle>
                    <template #append><v-btn size="small" variant="flat" color="error" class="font-weight-bold btn-3d" @click="clearAlert(alert.id)">Resolver</v-btn></template>
                </v-list-item>
                <div v-if="activeAlerts.length === 0" class="text-center pa-4 opacity-50 font-weight-bold"><v-icon size="32" class="mb-2 d-block mx-auto">mdi-check-decagram</v-icon>Tudo limpo! Nenhum alerta pendente.</div>
            </v-list>
        </v-card>
    </v-dialog>

    <v-dialog v-model="editLeadModal.show" max-width="500" persistent>
        <v-card class="rounded-xl border shadow-lg" :class="isDark ? 'bg-grey-darken-4 text-white' : 'bg-white'">
            <v-card-title class="d-flex align-center justify-space-between bg-primary text-white pa-4">
                <span>{{ editLeadModal.isNew ? 'Cadastrar Novo Lead' : 'Editar Lead' }}</span>
                <v-btn icon="mdi-close" variant="text" color="white" @click="editLeadModal.show = false"></v-btn>
            </v-card-title>
            <v-card-text class="pa-6">
                <v-text-field v-model="editLeadModal.form.name" label="Nome Completo *" variant="outlined" density="comfortable" class="mb-3 font-weight-bold" color="primary"></v-text-field>
                <v-text-field v-model="editLeadModal.form.email" label="E-mail *" variant="outlined" density="comfortable" class="mb-3" color="primary"></v-text-field>
                <v-row dense>
                    <v-col cols="6"><v-text-field v-model="editLeadModal.form.phone" label="WhatsApp" variant="outlined" density="comfortable" color="primary"></v-text-field></v-col>
                    <v-col cols="6"><v-text-field v-model="editLeadModal.form.document" label="CPF/CNPJ" variant="outlined" density="comfortable" color="primary"></v-text-field></v-col>
                </v-row>
            </v-card-text>
            <v-card-actions class="pa-4 border-t d-flex justify-end gap-3" :class="isDark ? 'bg-grey-darken-3' : 'bg-grey-lighten-5'">
                <v-btn variant="tonal" class="btn-3d font-weight-bold" @click="editLeadModal.show = false" :disabled="editLeadModal.loading">Cancelar</v-btn>
                <v-btn color="primary" variant="flat" class="btn-3d font-weight-black px-6 text-white" @click="saveLeadForm" :loading="editLeadModal.loading">Salvar Lead</v-btn>
            </v-card-actions>
        </v-card>
    </v-dialog>

    <v-dialog v-model="showVIPConfigModal" max-width="480" persistent>
      <v-card class="rounded-xl border shadow-lg" :class="isDark ? 'bg-grey-darken-4 text-white' : 'bg-white'">
        <v-card-title class="pa-5 d-flex justify-space-between align-center border-b" :class="isDark ? 'bg-grey-darken-3' : 'bg-grey-lighten-5'">
          <div class="d-flex align-center gap-3">
            <div class="bg-primary-lighten-4 text-primary rounded-circle d-flex align-center justify-center" style="width: 40px; height: 40px;">
              <v-icon>mdi-shield-key-outline</v-icon>
            </div>
            <div>
              <span class="font-weight-black text-h6 d-block lh-1">Emissão de Chave</span>
              <span class="text-caption opacity-70">Geração de chave VIP de login</span>
            </div>
          </div>
          <v-btn icon="mdi-close" variant="text" size="small" @click="showVIPConfigModal = false"></v-btn>
        </v-card-title>

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
          ></v-select>
          <v-alert type="info" variant="tonal" class="rounded-lg mb-0 text-caption font-weight-medium bg-primary-lighten-5 text-primary border-primary">
            O comportamento continuará sendo monitorado pelo motor anti-plágio.
          </v-alert>
        </v-card-text>

        <v-card-actions class="pa-4 border-t d-flex justify-end gap-2" :class="isDark ? 'bg-grey-darken-3' : 'bg-grey-lighten-5'">
          <v-btn variant="tonal" class="font-weight-bold text-none rounded-lg px-4" @click="showVIPConfigModal = false">Cancelar</v-btn>
          <v-btn color="primary" variant="flat" class="font-weight-bold text-none rounded-lg px-6 btn-3d" @click="confirmVIPAccess" :loading="isProcessingCode">Emitir e Enviar</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <v-dialog v-model="showVIPCodeModal" max-width="450" persistent>
      <v-card class="rounded-xl border shadow-lg text-center overflow-hidden" :class="isDark ? 'bg-grey-darken-4 text-white' : 'bg-white'">
        <div class="bg-primary pt-8 pb-6 px-6 position-relative text-white">
           <v-icon size="64" class="mb-3 opacity-90">mdi-shield-check</v-icon>
           <h3 class="text-h5 font-weight-black mb-1">Chave Emitida</h3>
           <p class="text-body-2 opacity-80">A chave foi gerada e enviada ao e-mail.</p>
        </div>

        <v-card-text class="pa-6">
          <p class="text-caption font-weight-bold text-uppercase tracking-widest opacity-70 mb-2">Chave VIP do Lead</p>
          <div class="code-display-box border rounded-xl py-4 px-2 d-flex align-center justify-center gap-4 mb-6 cursor-pointer" :class="isDark ? 'bg-grey-darken-3 border-white-20' : 'bg-grey-lighten-4 border-grey-lighten-2'" @click="copyToClipboard(generatedCode, 'Código copiado!')" v-ripple>
            <span class="text-h3 font-weight-black tracking-widest text-primary">{{ generatedCode }}</span>
            <v-icon color="primary" size="24">mdi-content-copy</v-icon>
          </div>
          <div class="d-flex flex-column gap-3">
            <v-btn color="#25D366" variant="flat" size="large" block class="text-white font-weight-bold text-none rounded-lg btn-3d" @click="sendCodeViaWhatsApp" :disabled="!generatedLeadPhone"><v-icon start>mdi-whatsapp</v-icon> Enviar WhatsApp</v-btn>
            <v-btn variant="tonal" size="large" block class="font-weight-bold text-none rounded-lg" @click="showVIPCodeModal = false; generatedCode = ''">Fechar Janela</v-btn>
          </div>
        </v-card-text>
      </v-card>
    </v-dialog>

  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted, reactive } from 'vue'
import { supabase } from '@/api/supabase'
import { useThemeStore } from '@/stores/theme'
import { useAppStore } from '@/stores/app'
import { useUserStore } from '@/stores/user'
import draggable from 'vuedraggable'
import { parseISO, differenceInSeconds, differenceInDays, format } from 'date-fns'

const themeStore = useThemeStore()
const appStore = useAppStore()
const userStore = useUserStore()
const isDark = computed(() => themeStore.currentMode !== 'light')

// --- ÁUDIOS ---
const alertSoundRef = ref<HTMLAudioElement | null>(null)
const isAudioUnlocked = ref(false)

// --- ESTADOS DO KANBAN E DADOS ---
const loading = ref(true)
const allLeads = ref<any[]>([])
const columns = ref<any[]>([])
const securityData = ref<any[]>([])
const automations = ref<any[]>([])
const activeAlerts = ref<any[]>([])
const leadHistory = ref<any[]>([])

const searchQuery = ref('')
const filterStatus = ref<'all' | 'alerts' | 'blocked' | 'converted'>('all')

const advancedFilters = reactive({ accessStatus: 'all', riskLevel: 'all' })
const hasActiveFilters = computed(() => advancedFilters.accessStatus !== 'all' || advancedFilters.riskLevel !== 'all' || searchQuery.value !== '' || filterStatus.value !== 'all')

const clearFilters = () => {
    advancedFilters.accessStatus = 'all'
    advancedFilters.riskLevel = 'all'
    searchQuery.value = ''
    filterStatus.value = 'all'
}

// --- MODAIS MANUAIS ---
const showColumnManagerModal = ref(false)
const showAutomationsModal = ref(false)
const showRuleBuilder = ref(false)
const editLeadModal = reactive({ show: false, loading: false, isNew: false, form: { id: '', name: '', email: '', phone: '', document: '', kanban_column_id: null as string|null } })

const dossierTab = ref('info')
const showDossierModal = ref(false)
const selectedDossierLead = ref<any>(null)
const showNotificationsModal = ref(false)

// --- MODAIS VIP KEY (PORTADOS) ---
const showVIPConfigModal = ref(false)
const showVIPCodeModal = ref(false)
const accessDuration = ref(12)
const isProcessingCode = ref(false)
const generatedCode = ref('')
const generatedLeadPhone = ref('')
const generatedLeadName = ref('')
const durationOptions = [ { label: '1 Hora (Teste)', value: 1 }, { label: '12 Horas (Padrão)', value: 12 }, { label: '24 Horas (1 Dia)', value: 24 }, { label: '48 Horas (2 Dias)', value: 48 }, { label: '168 Horas (7 Dias)', value: 168 } ]

// --- FORMULÁRIOS E OPÇÕES ---
const newCol = reactive({ title: '', accent_color: '#3B82F6', win_probability: 50, rotting_days: 3, wip_limit: 0 })
const isSavingCol = ref(false)

const timeUnits = [{ label: 'Segundos', value: 'seconds' }, { label: 'Minutos', value: 'minutes' }, { label: 'Horas', value: 'hours' }, { label: 'Dias', value: 'days' }]
const triggerOptions = [
    { label: 'Tempo Estagnado na Coluna', value: 'time_in_column' },
    { label: 'Lead Criado (Novo)', value: 'lead_created' },
    { label: 'Risco de Plágio Alto (> X)', value: 'risk_score_high' },
    { label: 'Chave VIP Expirou', value: 'auth_expired' },
    { label: 'Sem Contato (Sem WhatsApp)', value: 'missing_contact' }
]
const actionOptions = [
    { label: 'Mover Automaticamente de Coluna', value: 'move_to_column' },
    { label: 'Disparar Alerta (Sino e Pop-up)', value: 'set_alert' },
    { label: 'Alterar Score de Risco', value: 'change_risk' }
]

const newRule = reactive({
    name: '',
    trigger_event: 'time_in_column',
    condition_value: { source_column_id: 'all', timeValue: 1, timeUnit: 'days', score: 70 } as any,
    action_type: 'set_alert',
    action_payload: { target_column_id: '', message: 'Verifique este Lead!', risk_action: 'increase', risk_amount: 10 } as any
})
const isSavingRule = ref(false)

// --- KPIS CALCULADOS ---
const leadsEstagnados = computed(() => allLeads.value.filter(l => l.column_id && isSlaBreached(l, columns.value.find(c=>c.id===l.column_id))).length)
const leadsBloqueados = computed(() => securityData.value.filter(s => s.access_status === 'blocked' || s.risk_score >= 80).length)
const leadsConvertidos = computed(() => allLeads.value.filter(l => l.login_status === 'active').length)

// ==========================================
// UTILS DE CORES E ESTILOS (HEX -> RGBA)
// ==========================================
const hexToRgba = (hex: string, alpha: number) => {
    if (!hex) return `rgba(0,0,0,${alpha})`
    let c = hex.substring(1)
    if (c.length === 3) c = c.split('').map(x => x + x).join('')
    const r = parseInt(c.slice(0, 2), 16) || 0
    const g = parseInt(c.slice(2, 4), 16) || 0
    const b = parseInt(c.slice(4, 6), 16) || 0
    return `rgba(${r}, ${g}, ${b}, ${alpha})`
}

const getColumnHeaderStyle = (hex: string) => {
    return {
        backgroundColor: hexToRgba(hex, isDark.value ? 0.3 : 0.15),
        borderTop: `4px solid ${hex}`,
        borderBottom: `1px solid ${hexToRgba(hex, 0.4)}`
    }
}

const getColumnBodyStyle = (hex: string) => {
    return {
        backgroundColor: hexToRgba(hex, isDark.value ? 0.08 : 0.04),
        borderColor: hexToRgba(hex, 0.2)
    }
}

// ==========================================
// 1. CARGA DE DADOS (INIT)
// ==========================================
const fetchData = async () => {
    loading.value = true
    try {
        const { data: cols } = await supabase.from('crm_kanban_columns').select('*').order('order_index')
        columns.value = cols || []

        const { data: leads } = await supabase.from('public_leads').select('*')

        const { data: sec } = await supabase.from('security_profiles').select('*')
        securityData.value = sec || []

        const { data: rules } = await supabase.from('crm_automations').select('*')
        automations.value = rules || []

        const { data: alerts } = await supabase.from('crm_active_alerts').select('*').eq('is_read', false)
        activeAlerts.value = alerts || []

        allLeads.value = (leads || []).map(l => {
            const risk = securityData.value.find(s => s.user_id === l.id)
            return {
                ...l,
                behavior_score: risk?.risk_score || 0,
                login_status: l.temp_auth_expires_at && new Date(l.temp_auth_expires_at) > new Date() ? 'active' : 'expired',
                column_id: l.kanban_column_id || (columns.value.length > 0 ? columns.value[0].id : null)
            }
        })

        runAutomationEngine()
    } catch (e) { console.error(e) }
    finally { loading.value = false }
}

// ==========================================
// 2. KANBAN (DRAG, DROP, TEMPO)
// ==========================================
const getColLeads = (colId: string) => {
    let list = allLeads.value.filter(l => l.column_id === colId)

    if (searchQuery.value) {
        const q = searchQuery.value.toLowerCase();
        list = list.filter(l => l.name?.toLowerCase().includes(q) || l.email?.toLowerCase().includes(q))
    }
    if (filterStatus.value === 'alerts') list = list.filter(l => isSlaBreached(l, columns.value.find(c=>c.id===colId)))
    if (filterStatus.value === 'blocked') list = list.filter(l => l.behavior_score > 50)
    if (filterStatus.value === 'converted') list = list.filter(l => l.login_status === 'active')

    // Filtros avançados
    if (advancedFilters.accessStatus === 'active') list = list.filter(l => l.login_status === 'active')
    if (advancedFilters.accessStatus === 'expired') list = list.filter(l => l.login_status === 'expired')
    if (advancedFilters.riskLevel === 'low') list = list.filter(l => l.behavior_score <= 40)
    if (advancedFilters.riskLevel === 'medium') list = list.filter(l => l.behavior_score > 40 && l.behavior_score <= 70)
    if (advancedFilters.riskLevel === 'high') list = list.filter(l => l.behavior_score > 70)

    return list.sort((a,b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime())
}

const getElapsedSeconds = (lead: any) => {
    const d = lead.updated_at || lead.created_at
    if (!d) return 0
    return differenceInSeconds(new Date(), parseISO(d))
}

const getFormattedTimeInCol = (lead: any) => {
    const secs = getElapsedSeconds(lead)
    if (secs < 60) return `${secs} segs`
    if (secs < 3600) return `${Math.floor(secs/60)} mins`
    if (secs < 86400) return `${Math.floor(secs/3600)} horas`
    return `${Math.floor(secs/86400)} dias`
}

const isSlaBreached = (lead: any, col: any) => {
    if (!col || !col.rotting_days) return false
    const daysLimit = col.rotting_days
    const daysElapsed = differenceInDays(new Date(), parseISO(lead.updated_at || lead.created_at))
    return daysElapsed > daysLimit
}

const getRottingClass = (lead: any, col: any) => {
    if (isSlaBreached(lead, col)) return 'rotting-card border-error'
    return ''
}

const onLeadMoved = async (evt: any, col: any) => {
    if (evt.added) {
        const lead = evt.added.element
        lead.column_id = col.id
        lead.updated_at = new Date().toISOString()
        try {
            await supabase.from('public_leads').update({ kanban_column_id: col.id, updated_at: lead.updated_at }).eq('id', lead.id)
            await supabase.from('crm_lead_history').insert({ lead_id: lead.id, action_type: 'moved', description: `Movido manualmente para a etapa: ${col.title}` })
            runAutomationEngine()
        } catch(e) {}
    }
}

// ==========================================
// 3. GERENCIADOR MANUAL DE COLUNAS
// ==========================================
const addColumn = async () => {
    if (!newCol.title) return appStore.showSnackbar('Dê um nome para a etapa.', 'warning')
    isSavingCol.value = true
    try {
        const payload = { title: newCol.title, accent_color: newCol.accent_color, win_probability: newCol.win_probability, rotting_days: newCol.rotting_days, wip_limit: newCol.wip_limit, order_index: columns.value.length }
        const { data, error } = await supabase.from('crm_kanban_columns').insert([payload]).select().single()
        if (error) throw error
        if (data) columns.value.push(data)
        newCol.title = ''; newCol.wip_limit = 0; newCol.rotting_days = 3;
    } catch(e) { appStore.showSnackbar('Erro ao criar coluna', 'error') }
    finally { isSavingCol.value = false }
}

const deleteColumn = async (id: string) => {
    if (!confirm('Apagar esta etapa? Os leads nela voltarão para o início.')) return
    await supabase.from('crm_kanban_columns').delete().eq('id', id)
    columns.value = columns.value.filter(c => c.id !== id)
}

const saveColumnOrder = async () => {
    columns.value.forEach((c, i) => c.order_index = i)
    try {
        const payload = columns.value.map(c => ({ id: c.id, order_index: c.order_index }))
        await supabase.from('crm_kanban_columns').upsert(payload)
    } catch(e) {}
}

// ==========================================
// 4. MOTOR DE AUTOMAÇÕES E GATILHOS
// ==========================================
const openRuleBuilder = () => {
    newRule.name = ''
    newRule.trigger_event = 'time_in_column'
    showRuleBuilder.value = true
}

const saveAutomation = async () => {
    isSavingRule.value = true
    try {
        const payload = {
            name: newRule.name,
            trigger_event: newRule.trigger_event,
            condition_value: newRule.condition_value,
            action_type: newRule.action_type,
            action_payload: newRule.action_payload,
            is_active: true
        }
        const { data } = await supabase.from('crm_automations').insert([payload]).select().single()
        if (data) automations.value.push(data)
        showRuleBuilder.value = false
        appStore.showSnackbar('Automação Ativada! O motor está rodando.', 'success')
        runAutomationEngine()
    } catch(e) {} finally { isSavingRule.value = false }
}

const deleteAutomation = async (id: string) => {
    await supabase.from('crm_automations').delete().eq('id', id)
    automations.value = automations.value.filter(a => a.id !== id)
}
const toggleAutomation = async (rule: any) => {
    await supabase.from('crm_automations').update({ is_active: rule.is_active }).eq('id', rule.id)
}

const runAutomationEngine = () => {
    const activeRules = automations.value.filter(r => r.is_active)
    if (activeRules.length === 0) return

    let madeChanges = false

    allLeads.value.forEach(async lead => {
        activeRules.forEach(async rule => {
            let fired = false

            // Filtro da Condição de Origem
            const matchesCol = !rule.condition_value.source_column_id || rule.condition_value.source_column_id === 'all' || lead.column_id === rule.condition_value.source_column_id
            if (!matchesCol) return

            // Avaliação do Gatilho
            if (rule.trigger_event === 'time_in_column') {
                const tv = rule.condition_value.timeValue || 1
                const tu = rule.condition_value.timeUnit || 'days'
                const elapsedSecs = getElapsedSeconds(lead)
                let elapsedToCompare = elapsedSecs

                if (tu === 'minutes') elapsedToCompare = elapsedSecs / 60
                else if (tu === 'hours') elapsedToCompare = elapsedSecs / 3600
                else if (tu === 'days') elapsedToCompare = elapsedSecs / 86400

                if (elapsedToCompare >= tv) fired = true
            }
            else if (rule.trigger_event === 'risk_score_high') {
                if (lead.behavior_score >= rule.condition_value.score) fired = true
            }
            else if (rule.trigger_event === 'auth_expired') {
                if (lead.login_status === 'expired') fired = true
            }
            else if (rule.trigger_event === 'missing_contact') {
                if (!lead.phone) fired = true
            }

            if (fired) {
                // Lógica das Ações
                if (rule.action_type === 'move_to_column' && lead.column_id !== rule.action_payload.target_column_id) {
                    lead.column_id = rule.action_payload.target_column_id
                    lead.updated_at = new Date().toISOString()
                    madeChanges = true
                    try {
                        await supabase.from('public_leads').update({ kanban_column_id: rule.action_payload.target_column_id, updated_at: lead.updated_at }).eq('id', lead.id)
                        await supabase.from('crm_lead_history').insert({ lead_id: lead.id, action_type: 'automation', description: `O motor moveu o card pela regra: ${rule.name}` })
                    } catch(e) {}
                }
                else if (rule.action_type === 'set_alert') {
                    const hasRecent = activeAlerts.value.find(a => a.lead_id === lead.id && a.message === rule.action_payload.message)
                    if (!hasRecent) {
                        madeChanges = true
                        const newAlert = { lead_id: lead.id, alert_type: 'automation', message: `${lead.name}: ${rule.action_payload.message}` }
                        try {
                            const { data } = await supabase.from('crm_active_alerts').insert([newAlert]).select().single()
                            if (data) activeAlerts.value.push(data)
                            if (alertSoundRef.value && isAudioUnlocked.value) { alertSoundRef.value.currentTime = 0; alertSoundRef.value.play().catch(()=>{}) }
                            appStore.showSnackbar(`ALERTA: ${newAlert.message}`, 'error')
                        } catch(e) {}
                    }
                }
                else if (rule.action_type === 'change_risk') {
                    const hasExecutedBefore = leadHistory.value.find(h => h.lead_id === lead.id && h.description.includes(rule.name))
                    if (!hasExecutedBefore) {
                        let newRisk = lead.behavior_score
                        if (rule.action_payload.risk_action === 'increase') newRisk += rule.action_payload.risk_amount
                        else if (rule.action_payload.risk_action === 'decrease') newRisk -= rule.action_payload.risk_amount
                        else newRisk = 0

                        if (newRisk < 0) newRisk = 0
                        if (newRisk > 100) newRisk = 100

                        lead.behavior_score = newRisk
                        try {
                            await supabase.from('security_profiles').update({ risk_score: newRisk }).eq('user_id', lead.id)
                            await supabase.from('crm_lead_history').insert({ lead_id: lead.id, action_type: 'automation', description: `Score de risco alterado por: ${rule.name}` })
                        } catch(e) {}
                    }
                }
            }
        })
    })

    if (madeChanges) console.log("CRM Engine: Automações processadas.")
}

// ==========================================
// 5. DOSSIÊ DO LEAD
// ==========================================
const openDossierModal = async (lead: any) => {
    selectedDossierLead.value = lead
    dossierTab.value = 'info'
    showDossierModal.value = true
    leadHistory.value = []
    try {
        const { data } = await supabase.from('crm_lead_history').select('*').eq('lead_id', lead.id).order('created_at', { ascending: false })
        leadHistory.value = data || []
    } catch(e) {}
}

const addNote = async () => {
    const text = prompt("Digite a anotação para a Timeline do cliente:")
    if (!text) return
    const { data } = await supabase.from('crm_lead_history').insert({ lead_id: selectedDossierLead.value.id, action_type: 'note', description: text }).select().single()
    if (data) leadHistory.value.unshift(data)
}

const emitirChaveParaLead = () => {
    openVIPConfigModal(selectedDossierLead.value)
}

// ==========================================
// 6. CADASTRO MANUAL DE LEAD
// ==========================================
const openLeadFormModal = (lead: any) => {
    if (lead) {
        editLeadModal.isNew = false
        editLeadModal.form = { id: lead.id, name: lead.name, email: lead.email, phone: lead.phone, document: lead.document, kanban_column_id: lead.column_id }
    } else {
        editLeadModal.isNew = true
        editLeadModal.form = { id: '', name: '', email: '', phone: '', document: '', kanban_column_id: columns.value.length > 0 ? columns.value[0].id : null }
    }
    editLeadModal.show = true
}

const saveLeadForm = async () => {
    if (!editLeadModal.form.name || !editLeadModal.form.email) return appStore.showSnackbar('Nome e Email obrigatórios', 'warning')
    editLeadModal.loading = true
    try {
        const payload = { name: editLeadModal.form.name, email: editLeadModal.form.email, phone: editLeadModal.form.phone, document: editLeadModal.form.document, kanban_column_id: editLeadModal.form.kanban_column_id }
        if (editLeadModal.isNew) await supabase.from('public_leads').insert([payload])
        else await supabase.from('public_leads').update(payload).eq('id', editLeadModal.form.id)

        appStore.showSnackbar('Salvo com sucesso!', 'success')
        editLeadModal.show = false
        fetchData()
    } catch(e) { appStore.showSnackbar('Erro ao salvar.', 'error') }
    finally { editLeadModal.loading = false }
}

// ==========================================
// 7. GERAÇÃO DE CHAVE VIP
// ==========================================
const openVIPConfigModal = (lead: any) => {
  selectedDossierLead.value = lead
  accessDuration.value = 12
  showVIPConfigModal.value = true
}

const confirmVIPAccess = async () => {
  isProcessingCode.value = true
  const lead = selectedDossierLead.value
  try {
    const { data: code, error: rpcError } = await supabase.rpc('generate_premium_access_code', {
      p_email: lead.email,
      p_admin_id: userStore.profile?.id
    })

    if (rpcError) throw rpcError;

    const expiresAt = new Date()
    expiresAt.setHours(expiresAt.getHours() + accessDuration.value)

    await supabase.from('public_leads').update({ temp_auth_expires_at: expiresAt.toISOString(), auth_code_requested: false }).eq('id', lead.id)

    // Envio do Email via Edge Function
    const url = (supabase as any).supabaseUrl
    const storageKey = Object.keys(localStorage).find(k => k.startsWith('sb-') && k.endsWith('-auth-token'))
    const token = JSON.parse(localStorage.getItem(storageKey || '') || '{}').access_token

    fetch(`${url}/functions/v1/send-approval-email-auth`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` },
      body: JSON.stringify({ email: lead.email, name: lead.name, code: code })
    }).catch(e => console.error("Erro no envio de email", e))

    generatedCode.value = code
    generatedLeadName.value = lead.name || 'Cliente'
    generatedLeadPhone.value = lead.phone || ''

    showVIPConfigModal.value = false
    showVIPCodeModal.value = true
    fetchData()
  } catch (err: any) {
      appStore.showSnackbar('Erro na geração (RLS ou Banco): ' + err.message, 'error')
  } finally {
      isProcessingCode.value = false
  }
}

async function copyToClipboard(text: string, msg: string) {
  try { await navigator.clipboard.writeText(text); appStore.showSnackbar(msg, 'success') } catch (e) {}
}

function sendCodeViaWhatsApp() {
  const msg = `Olá ${generatedLeadName.value}! Seu acesso seguro ao nosso Acervo Digital foi autorizado.\n\n🔑 *Código de Desbloqueio: ${generatedCode.value}*\n\nAcesse e confira nossas novidades.`
  window.open(`https://wa.me/55${generatedLeadPhone.value.replace(/\D/g, '')}?text=${encodeURIComponent(msg)}`, '_blank')
}


// UTILS
const clearAlert = async (id: string) => { await supabase.from('crm_active_alerts').update({is_read: true}).eq('id', id); activeAlerts.value = activeAlerts.value.filter(a => a.id !== id) }
const getTriggerLabel = (v: string) => triggerOptions.find(o => o.value === v)?.label || v
const getActionLabel = (v: string) => actionOptions.find(o => o.value === v)?.label || v
const getUnitLabel = (v: string) => timeUnits.find(o => o.value === v)?.label || v
const getAvatarColor = (n: string) => { const c = ['#3F51B5', '#009688', '#FF9800', '#E91E63', '#4CAF50']; return n ? c[n.charCodeAt(0)%c.length] : c[0] }
const getInitials = (n: string) => n ? (n.split(' ').length > 1 ? n.split(' ')[0][0] + n.split(' ')[1][0] : n.substring(0,2)).toUpperCase() : '?'
const formatDate = (d: string) => d ? format(parseISO(d), 'dd/MM/yy HH:mm') : '-'
const formatDateFull = (d: string) => d ? format(parseISO(d), 'dd/MM/yyyy HH:mm') : '-'
const getHistoryColor = (type: string) => { if(type==='moved') return 'primary'; if(type==='automation') return 'purple'; if(type==='note') return 'success'; return 'grey' }
const openWhatsApp = (phone: string, name: string) => { if (phone) window.open(`https://wa.me/55${phone.replace(/\D/g, '')}?text=${encodeURIComponent(`Olá ${name}, referente ao seu acesso.`)}`, '_blank') }

// --- CORREÇÃO DO ÁUDIO AQUI ---
const unlockAudio = () => {
  if (!isAudioUnlocked.value) {
    if (alertSoundRef.value) {
        alertSoundRef.value.muted = true;
        alertSoundRef.value.play().then(() => {
            alertSoundRef.value!.pause();
            alertSoundRef.value!.currentTime = 0;
            alertSoundRef.value!.muted = false;
        }).catch(()=>{})
    }
    isAudioUnlocked.value = true
  }
}
// ------------------------------

// Roda a cada 5 Segundos
let engineLoop: any = null
onMounted(() => {
    fetchData()
    window.addEventListener('click', unlockAudio, { once: true })
    engineLoop = setInterval(runAutomationEngine, 5000)
})
onUnmounted(() => {
    if(engineLoop) clearInterval(engineLoop)
    window.removeEventListener('click', unlockAudio)
})
onMounted(() => {
    fetchData()
    window.addEventListener('click', unlockAudio, { once: true })
    engineLoop = setInterval(runAutomationEngine, 5000)
})
onUnmounted(() => {
    if(engineLoop) clearInterval(engineLoop)
    window.removeEventListener('click', unlockAudio)
})

</script>

<style scoped lang="scss">
/* MANTENDO A IDENTIDADE VISUAL EXATA DO DESIGNKANBAN */
.design-layout { width: 100%; height: calc(100vh - 64px); display: flex; flex-direction: column; }
.content-wrapper { flex: 1 1 0; display: flex; flex-direction: column; overflow: hidden; }

.background-carousel-wrapper { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 0; opacity: 0.6; pointer-events: none; }
.background-overlay { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 1; background: radial-gradient(circle at center, rgba(15, 15, 19, 0.4), rgba(15, 15, 19, 0.98)); backdrop-filter: blur(8px); }
.z-10 { position: relative; z-index: 10; }
.bg-glass-dark { background: rgba(10,10,12,0.85); }
.bg-glass-header { background: rgba(20,20,24,0.55); backdrop-filter: blur(14px); }
.border-bottom-white-05 { border-bottom: 1px solid rgba(255,255,255,0.08); }
.border-thin { border: 1px solid rgba(0,0,0,0.08); }

.btn-rect { border-radius: 0 !important; text-transform: none !important; }
.btn-3d { border-radius: 6px !important; box-shadow: 0 3px 5px rgba(0,0,0,0.15), inset 0 2px 0 rgba(255,255,255,0.25) !important; transition: transform 0.1s ease, box-shadow 0.1s ease; text-transform: none !important; }
.btn-3d:active { transform: translateY(2px); box-shadow: 0 1px 2px rgba(0,0,0,0.15), inset 0 1px 0 rgba(255,255,255,0.2) !important; }
.chip-3d { box-shadow: 0 3px 5px rgba(0,0,0,0.12), inset 0 1px 0 rgba(255,255,255,0.25) !important; text-shadow: 0 1px 2px rgba(0,0,0,0.25); }
.shadow-gold { box-shadow: 0 4px 12px rgba(245, 158, 11, 0.3) !important; }

.search-wrap { height: 40px; border-radius: 6px; padding: 0 12px; border: 1px solid rgba(0,0,0,0.08); }
.search-dark { background: rgba(255,255,255,0.08); border-color: rgba(255,255,255,0.10); }
.clean-input { border: none; outline: none; background: transparent; font-size: 13px; font-weight: 600; }
.controls-bar { border: 1px solid rgba(0,0,0,0.08); border-radius: 6px; padding: 10px; }
.controls-dark { background: rgba(30,30,35,0.55); backdrop-filter: blur(16px); border-color: rgba(255,255,255,0.08); }

.filter-select :deep(.v-field) { border-radius: 6px !important; min-height: 40px !important; }

/* KPIs idênticos ao Design Kanban */
.kpi-card { color: white; position: relative; min-height: 110px; overflow: hidden; }
.kpi-rect { border-radius: 8px !important; }
.bg-gradient-info { background: linear-gradient(135deg, #0288d1, #005b9f); }
.bg-gradient-success { background: linear-gradient(135deg, #2e7d32, #1b5e20); }
.bg-gradient-warning { background: linear-gradient(135deg, #FFB300, #F57F17); }
.bg-gradient-red { background: linear-gradient(135deg, #c62828, #8e0000); }
.kpi-bg-icon { position: absolute; right: -20px; bottom: -20px; opacity: 0.15; transform: rotate(-15deg); }
.kpi-bg-icon .v-icon { font-size: 100px; color: white; }
.kpi-label { font-size: 12px; font-weight: 900; letter-spacing: .2px; text-transform: uppercase; }
.kpi-value { font-size: 26px; font-weight: 900; }
.kpi-footer { font-size: 11px; opacity: .9; font-weight: 700; }
.hover-elevate:hover { transform: translateY(-2px); box-shadow: 0 8px 16px rgba(0,0,0,0.3) !important; }

/* KANBAN STRICT CONTAINERS */
.kanban-master-container { flex: 1 1 0; display: flex; flex-direction: column; overflow: hidden; }
.kanban-board-card { flex: 1 1 0; display: flex; flex-direction: column; overflow: hidden; background: transparent !important; }
.kanban-container { flex: 1 1 0; display: flex; align-items: stretch; overflow-x: auto; overflow-y: hidden; }
.kanban-column { min-width: 340px; width: 340px; flex-shrink: 0; display: flex; flex-direction: column; height: 100%; backdrop-filter: blur(10px); }
.column-header { flex-shrink: 0; }
.kanban-content { flex: 1 1 0; overflow-y: auto; overflow-x: hidden; padding-bottom: 20px; }

/* Cards (Storefront Type) */
.storefront-card { transition: transform 0.2s, box-shadow 0.2s; cursor: pointer; }
.storefront-card:hover { transform: translateY(-2px); box-shadow: 0 6px 15px rgba(0,0,0,0.2) !important; }
.cursor-grab { cursor: grab; }
.status-dot { width: 8px; height: 8px; border-radius: 50%; display: inline-block; }
.pulsing-dot { animation: pulse-opacity 2s infinite; }

/* Efeito de Estagnação de SLA (Rotting Effect do Enterprise) */
.rotting-card { border-color: rgba(244, 67, 54, 0.5) !important; }
.rotting-bg-glow { position: absolute; top: -50%; right: -50%; width: 200%; height: 200%; background: radial-gradient(circle at center, rgba(244, 67, 54, 0.08) 0%, transparent 60%); pointer-events: none; animation: pulse-glow 2s infinite; z-index: 0; }

@keyframes pulse-opacity { 0%, 100% { opacity: 1; } 50% { opacity: 0.5; } }
@keyframes pulse-glow { 0% { opacity: 0.3; } 50% { opacity: 0.8; } 100% { opacity: 0.3; } }
.animate-bounce { animation: bounce 1s infinite; }
@keyframes bounce { 0%, 100% { transform: translateY(0); } 50% { transform: translateY(-3px); } }

.custom-scroll::-webkit-scrollbar { width: 6px; height: 6px; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.35); border-radius: 6px; }
.custom-scroll-x::-webkit-scrollbar { height: 8px; }
.custom-scroll-x::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.35); border-radius: 6px; }

.color-picker { width: 100%; height: 32px; border: none; border-radius: 4px; cursor: pointer; padding: 0; }
.lh-1 { line-height: 1 !important; }
.lh-1-2 { line-height: 1.2 !important; }
</style>
