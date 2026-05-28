<template>
  <div
    class="design-layout font-sans relative overflow-hidden"
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

    <div class="content-wrapper z-10 relative">

      <div
        class="header-bar px-6 py-4 d-flex align-center justify-space-between flex-shrink-0 relative"
        :class="themeStore.currentMode === 'light' ? 'bg-white border-b border-grey-lighten-2 shadow-sm' : 'bg-glass-header border-bottom-white-05'"
      >
        <div class="d-flex flex-column">
          <div class="breadcrumb text-caption">
            <span class="opacity-70">MJ Process</span>
            <span class="mx-2 opacity-50">></span>
            <span class="font-weight-bold">Design</span>
          </div>
          <div class="text-h6 font-weight-black tracking-tight leading-none mt-1" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">
            Fluxo de Criação
          </div>
        </div>

        <div class="d-flex align-center" style="gap: 10px;">

          <v-badge v-if="isLeaderOrRightHand" :content="assignmentRequests.length" :model-value="assignmentRequests.length > 0" color="error">
             <v-btn
                variant="flat"
                class="btn-rect btn-3d text-none font-weight-bold"
                height="40"
                prepend-icon="mdi-hand-back-right"
                color="orange-darken-3"
                @click="showAssignmentRequestsModal = true"
              >
                Solicitações
              </v-btn>
          </v-badge>

          <template v-if="currentUserPerms.is_leader">
             <v-btn
                variant="flat"
                class="btn-rect btn-3d text-none font-weight-bold"
                height="40"
                prepend-icon="mdi-sitemap"
                color="indigo-darken-1"
                @click="$router.push('/design/organograma')"
                title="Acessar o Canvas Interativo do Organograma"
              >
                Organograma
              </v-btn>

             <v-btn
                variant="flat"
                class="btn-rect btn-3d text-none font-weight-bold"
                height="40"
                prepend-icon="mdi-account-group"
                color="deep-purple-darken-1"
                @click="showTeamManagerModal = true"
              >
                Equipe & Permissões
              </v-btn>
              <v-btn
                variant="flat"
                class="btn-rect btn-3d text-none font-weight-bold"
                height="40"
                prepend-icon="mdi-view-column-plus"
                color="primary"
                @click="showColumnManagerModal = true"
              >
                Gerenciar Fluxo
              </v-btn>
          </template>

          <v-btn
            variant="outlined"
            class="btn-rect btn-3d bg-white"
            height="40"
            prepend-icon="mdi-history"
            :color="themeStore.currentMode === 'light' ? 'grey-darken-2' : 'grey-darken-3'"
            :class="themeStore.currentMode !== 'light' ? 'text-white' : ''"
            @click="openHistoryModal"
          >
            Histórico de Liberações
          </v-btn>

          <v-tooltip location="bottom">
            <template #activator="{ props }">
              <v-btn
                v-bind="props"
                :icon="hintsEnabled ? 'mdi-lightbulb-on-outline' : 'mdi-lightbulb-off-outline'"
                variant="text"
                density="comfortable"
                :color="hintsEnabled ? 'amber' : (themeStore.currentMode === 'light' ? 'grey-darken-2' : 'white')"
                @click="toggleHints"
              ></v-btn>
            </template>
            <span>{{ hintsEnabled ? 'Desativar Dicas' : 'Ativar Dicas' }}</span>
          </v-tooltip>
        </div>
      </div>

      <div class="px-6 pt-4 pb-2 flex-shrink-0 relative">

        <v-row dense class="mb-4">
           <v-col cols="12" sm="6" md="3" v-for="(kpi, index) in activeKpis" :key="index">
              <v-menu location="bottom end">
                <template v-slot:activator="{ props: menuProps }">
                  <v-card class="kpi-card kpi-rect py-3 px-4 cursor-pointer hover-elevate" :class="kpi.gradient" elevation="2" v-bind="menuProps" v-ripple>
                      <div class="kpi-bg-icon"><v-icon>{{ kpi.icon }}</v-icon></div>
                      <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                          <div class="d-flex align-center gap-2">
                              <v-icon size="18" class="opacity-80">{{ kpi.icon }}</v-icon>
                              <span class="kpi-label">{{ kpi.title }}</span>
                          </div>
                          <div class="kpi-number-group my-1">
                              <span class="kpi-value">{{ kpi.count }}</span>
                              <span class="text-caption ml-2 opacity-80 font-weight-bold">itens</span>
                          </div>
                          <div class="kpi-footer">{{ formatNumber(kpi.meters) }}m em processo</div>
                      </div>
                  </v-card>
                </template>
                <v-list density="compact" nav :bg-color="themeStore.currentMode === 'light' ? 'white' : 'grey-darken-4'">
                  <v-list-subheader>Alterar Métrica</v-list-subheader>
                  <v-list-item v-for="option in kpiOptions" :key="option.value" :value="option.value" @click="changeKpi(index, option.value)" :active="kpi.id === option.value" color="primary">
                    <template v-slot:prepend><v-icon :icon="option.icon" size="small" :color="option.iconColor"></v-icon></template>
                    <v-list-item-title>{{ option.title }}</v-list-item-title>
                  </v-list-item>
                </v-list>
              </v-menu>
           </v-col>
        </v-row>

        <div class="controls-bar d-flex align-center justify-space-between mb-2" :class="themeStore.currentMode === 'light' ? 'controls-light' : 'controls-dark'">
          <div class="d-flex align-center flex-wrap" style="gap: 10px;">
            <div class="search-wrap d-flex align-center" :class="themeStore.currentMode === 'light' ? 'search-light' : 'search-dark'">
                <v-icon :color="themeStore.currentMode === 'light' ? 'grey-darken-1' : 'white-70'">mdi-magnify</v-icon>
                <input v-model="searchQuery" type="text" placeholder="Buscar por cliente, ref ou ID..." class="clean-input flex-grow-1" ref="searchFieldRef"/>
            </div>

            <v-chip filter :model-value="filterDelayed" @click="filterDelayed = !filterDelayed" color="error" variant="tonal" label class="font-weight-bold chip-3d" prepend-icon="mdi-clock-alert-outline">
               Apenas Atrasados
            </v-chip>
          </div>
        </div>
      </div>

      <div class="kanban-master-container px-6 pb-2 z-high">
        <v-card
          class="kanban-board-card rounded-0 border-thin"
          :class="themeStore.currentMode === 'light' ? 'bg-white shadow-sm' : 'glass-card border-white-05'"
          :elevation="0"
        >
          <div v-if="loading" class="d-flex flex-column justify-center align-center h-100">
             <v-progress-circular indeterminate color="primary" size="64" width="6"></v-progress-circular>
             <div class="mt-4 font-weight-medium opacity-70">Carregando fluxo...</div>
          </div>

          <div v-else class="kanban-container custom-scroll-x">
            <div v-for="column in columns" :key="column.id"
                 class="kanban-column border-r"
                 :class="[
                    column.bgClass,
                    themeStore.currentMode === 'light' ? 'border-grey-lighten-2' : 'border-white-05'
                 ]">

                 <div class="column-header pa-3 border-b" :class="themeStore.currentMode === 'light' ? 'border-grey-lighten-2' : 'border-white-05'">
                    <div class="d-flex justify-space-between align-center mb-1">
                       <div class="d-flex align-center gap-2">
                          <div class="status-dot pulsing-dot" :class="column.dotColor"></div>
                          <span class="text-subtitle-2 font-weight-black text-uppercase opacity-90" :title="column.tag_name">{{ column.title }}</span>
                       </div>

                       <div class="d-flex align-center gap-2">
                           <v-chip size="small" :color="column.chipColor" variant="flat" class="font-weight-black chip-3d px-2">{{ column.items.length }}</v-chip>

                           <v-menu location="bottom end">
                                <template v-slot:activator="{ props }">
                                    <v-btn v-bind="props" icon size="x-small" variant="text" class="opacity-50 hover-opacity-100">
                                        <v-icon>mdi-sort</v-icon>
                                    </v-btn>
                                </template>
                                <v-list density="compact" nav class="border shadow-lg" :class="isLightMode ? 'bg-white' : 'bg-surface-card'">
                                    <v-list-subheader class="text-[10px] font-weight-bold uppercase">Ordenar Coluna</v-list-subheader>
                                    <v-list-item @click="setColumnSort(column.id, 'created_at_desc')" :active="columnSorts[column.id] === 'created_at_desc'">
                                        <template v-slot:prepend><v-icon size="small">mdi-sort-clock-ascending-outline</v-icon></template>
                                        <v-list-item-title>Mais Recentes</v-list-item-title>
                                    </v-list-item>
                                    <v-list-item @click="setColumnSort(column.id, 'created_at_asc')" :active="columnSorts[column.id] === 'created_at_asc'">
                                        <template v-slot:prepend><v-icon size="small">mdi-sort-clock-descending-outline</v-icon></template>
                                        <v-list-item-title>Mais Antigos</v-list-item-title>
                                    </v-list-item>
                                    <v-divider class="my-1"></v-divider>
                                    <v-list-item @click="setColumnSort(column.id, 'customer_name')" :active="columnSorts[column.id] === 'customer_name'">
                                        <template v-slot:prepend><v-icon size="small">mdi-sort-alphabetical-variant</v-icon></template>
                                        <v-list-item-title>Cliente (A-Z)</v-list-item-title>
                                    </v-list-item>
                                     <v-list-item @click="setColumnSort(column.id, 'quantity')" :active="columnSorts[column.id] === 'quantity'">
                                        <template v-slot:prepend><v-icon size="small">mdi-sort-numeric-descending</v-icon></template>
                                        <v-list-item-title>Maior Volume</v-list-item-title>
                                    </v-list-item>
                                </v-list>
                           </v-menu>
                       </div>
                    </div>
                    <div class="d-flex align-center justify-space-between mt-1">
                        <span class="text-[10px] opacity-60 font-weight-bold text-uppercase">Volume</span>
                        <span class="text-caption font-mono font-weight-black">{{ formatNumber(column.meters) }}m</span>
                    </div>
                 </div>

                 <draggable
                    :list="column.items"
                    group="items"
                    item-key="id"
                    class="kanban-content pa-2 custom-scroll"
                    :disabled="column.id === 'col-app'"
                    @change="onCardMoved($event, column)"
                  >
                    <template #item="{ element: item }">
                       <div :data-id="item.id" class="mb-2 cursor-grab" @mousemove="onCardMouseMove">

                        <v-card
                          v-if="isStorefrontItem(item)"
                          class="storefront-card rounded-xl shadow-sm position-relative overflow-hidden"
                          :class="isLightMode ? 'bg-white border-warning-lighten-2' : 'bg-surface-card border-warning-darken-3'"
                          style="border-width: 2px !important; border-style: solid !important;"
                          @click="openModalForItem(item)"
                          v-ripple
                        >
                          <div class="vip-bg-glow"></div>
                          <v-card-text class="pa-3 position-relative z-10">
                            <div class="d-flex align-center justify-space-between mb-3">
                                <v-chip size="x-small" color="warning" variant="flat" class="font-weight-black text-black px-2 shadow-gold" style="border: 1px solid #F59E0B;">
                                  <v-icon start size="12">mdi-crown</v-icon> CLIENTE VIP (SITE)
                                </v-chip>
                                <span class="text-[10px] font-weight-bold opacity-70 font-mono text-warning" :class="!isLightMode ? 'text-warning-lighten-2' : ''">{{ item.original.dev_code }}</span>
                            </div>

                            <div class="text-body-2 font-weight-black lh-1 text-truncate mb-1" :title="item.customer_name" :class="isLightMode ? 'text-grey-darken-4' : 'text-white'">
                                {{ item.customer_name }}
                            </div>
                            <div class="text-[10px] opacity-70 text-truncate mb-3" :class="isLightMode ? 'text-grey-darken-2' : 'text-grey-lighten-1'">
                                {{ getStorefrontBriefing(item) }}
                            </div>

                            <div class="mt-2 pt-2 border-t d-flex align-center justify-space-between" :class="isLightMode ? 'border-warning-lighten-4' : 'border-warning-darken-4'">
                                <div class="d-flex align-center gap-2">
                                    <v-avatar size="24" :color="item.designer_id ? 'warning' : 'grey-lighten-1'" class="shadow-sm">
                                        <span class="text-[10px] font-weight-bold" :class="item.designer_id ? 'text-black' : 'text-white'">{{ getInitials(getDesignerName(item.designer_id)) }}</span>
                                    </v-avatar>
                                    <div class="d-flex flex-column lh-1">
                                        <span class="text-[9px] font-weight-black uppercase opacity-60">Designer</span>
                                        <span class="text-[10px] font-weight-bold text-truncate" style="max-width: 80px;" :class="item.designer_id ? '' : 'text-error'">
                                            {{ getDesignerName(item.designer_id) || 'Sem Dono' }}
                                        </span>
                                    </div>
                                </div>

                                <v-menu v-if="isLeaderOrRightHand" location="bottom end">
                                    <template v-slot:activator="{ props }">
                                        <v-btn v-bind="props" size="x-small" variant="tonal" color="warning" class="font-weight-bold px-2 text-[10px] btn-3d" @click.stop>
                                            <v-icon start size="12">mdi-account-switch</v-icon> Atribuir
                                        </v-btn>
                                    </template>
                                    <v-list density="compact" nav>
                                        <v-list-item @click="assignCard(item, null)">
                                            <template v-slot:prepend><v-icon size="small" color="grey">mdi-account-off</v-icon></template>
                                            <v-list-item-title class="text-caption font-weight-bold">Nenhum (Livre)</v-list-item-title>
                                        </v-list-item>
                                        <v-divider class="my-1"></v-divider>
                                        <v-list-item v-for="member in designTeamMembers" :key="member.user_id" @click="assignCard(item, member.user_id)">
                                            <template v-slot:prepend>
                                                <v-avatar size="20" color="warning" class="mr-2"><span class="text-[8px] text-black font-weight-bold">{{ getInitials(member.profile?.full_name) }}</span></v-avatar>
                                            </template>
                                            <v-list-item-title class="text-caption font-weight-bold">{{ member.profile?.full_name }}</v-list-item-title>
                                        </v-list-item>
                                    </v-list>
                                </v-menu>

                                <v-btn v-else-if="!item.designer_id" size="x-small" variant="flat" color="warning" class="font-weight-black text-black px-2 text-[10px] btn-3d shadow-gold" @click.stop="assignCard(item, userStore.profile?.id)">
                                      <v-icon start size="12">mdi-hand-back-right</v-icon> Assumir
                                </v-btn>
                            </div>

                            <div class="mt-3 d-flex flex-column gap-2" v-if="isLeaderOrRightHand || item.designer_id === userStore.profile?.id">
                                <v-btn
                                    v-if="!isLeaderOrRightHand && requiresApproval && column.tag_name !== 'Aprovação Líder'"
                                    block variant="tonal" size="x-small" color="warning" class="font-weight-bold btn-3d"
                                    @click.stop="openUploadModal(item.original, 'leader', 'development')"
                                >
                                    <v-icon start size="14">mdi-cloud-upload</v-icon> Enviar p/ Líder
                                </v-btn>

                                <v-btn
                                    v-if="(!requiresApproval || column.tag_name === 'Aprovado' || column.tag_name === 'Aprovação Líder') && (isLeaderOrRightHand || !requiresApproval)"
                                    block variant="flat" size="x-small" color="warning" class="text-black font-weight-black btn-3d shadow-gold"
                                    @click.stop="openModalForItem(item)"
                                >
                                    <v-icon start size="14">mdi-safe-star</v-icon> Entregar no Cofre VIP (24h)
                                </v-btn>

                                <v-btn
                                    v-if="isLeaderOrRightHand && column.tag_name === 'Aprovação Líder'"
                                    block variant="tonal" size="x-small" color="error" class="font-weight-bold btn-3d"
                                    @click.stop="openRejectModal(item)"
                                >
                                    <v-icon start size="14">mdi-close-octagon</v-icon> Rejeitar Arte
                                </v-btn>
                            </div>
                          </v-card-text>
                        </v-card>

                        <v-card
                            v-else-if="item.type === 'pilot_internal'"
                            class="pilot-internal-card rounded-xl shadow-sm position-relative overflow-hidden mb-2"
                            :class="isLightMode ? 'bg-white border-purple-lighten-2' : 'bg-surface-card border-purple-darken-3'"
                            style="border-width: 2px !important; border-style: solid !important;"
                            @click="openModalForItem(item)"
                            v-ripple
                        >
                            <v-card-text class="pa-3 position-relative z-10">
                                <div class="d-flex align-center justify-space-between mb-3">
                                    <div class="d-flex gap-2">
                                        <v-chip size="x-small" color="purple-darken-2" variant="flat" class="font-weight-black px-2 btn-3d">
                                            <v-icon start size="12">mdi-tshirt-crew</v-icon> PILOTO (ERP)
                                        </v-chip>
                                        <v-chip v-if="item.original.design_items?.[0]?.pilot_approval_type" size="x-small" :color="item.original.design_items[0].pilot_approval_type === 'digital' ? 'info' : 'warning'" variant="flat" class="font-weight-black px-2 btn-3d">
                                            <v-icon start size="12">{{ item.original.design_items[0].pilot_approval_type === 'digital' ? 'mdi-cellphone-message' : 'mdi-truck-delivery-outline' }}</v-icon>
                                            {{ item.original.design_items[0].pilot_approval_type === 'digital' ? 'DIGITAL' : 'FÍSICO' }}
                                        </v-chip>
                                    </div>
                                    <span class="text-[10px] font-weight-bold opacity-70 font-mono text-purple">{{ item.original.dev_code }}</span>
                                </div>

                                <div class="text-body-2 font-weight-black lh-1 text-truncate mb-1" :class="isLightMode ? 'text-grey-darken-4' : 'text-white'">
                                    {{ item.customer_name }}
                                </div>

                                <div class="text-[10px] opacity-70 line-clamp-2 mt-2 mb-2 font-italic lh-1">
                                    {{ item.original.general_notes || item.original.design_items?.[0]?.notes || 'Sem observações' }}
                                </div>

                                <div class="d-flex align-center justify-space-between pt-2 border-t" :class="isLightMode ? 'border-purple-lighten-4' : 'border-purple-darken-4'">
                                    <div class="d-flex align-center gap-2">
                                        <v-avatar size="24" :color="item.designer_id ? 'purple' : 'grey-lighten-1'" class="shadow-sm">
                                            <span class="text-[10px] font-weight-bold text-white">{{ getInitials(getDesignerName(item.designer_id)) }}</span>
                                        </v-avatar>
                                        <div class="d-flex flex-column lh-1">
                                            <span class="text-[9px] font-weight-black uppercase opacity-60">Designer</span>
                                            <span class="text-[10px] font-weight-bold text-truncate" style="max-width: 80px;" :class="item.designer_id ? '' : 'text-error'">
                                                {{ getDesignerName(item.designer_id) || 'Livre' }}
                                            </span>
                                        </div>
                                    </div>

                                    <v-menu v-if="isLeaderOrRightHand" location="bottom end">
                                        <template v-slot:activator="{ props }">
                                            <v-btn v-bind="props" size="x-small" variant="tonal" color="purple" class="font-weight-bold px-2 text-[10px] btn-3d" @click.stop>
                                                <v-icon start size="12">mdi-account-switch</v-icon> Atribuir
                                            </v-btn>
                                        </template>
                                        <v-list density="compact" nav>
                                            <v-list-item @click="assignCard(item, null)">
                                                <template v-slot:prepend><v-icon size="small" color="grey">mdi-account-off</v-icon></template>
                                                <v-list-item-title class="text-caption font-weight-bold">Nenhum (Livre)</v-list-item-title>
                                            </v-list-item>
                                            <v-divider class="my-1"></v-divider>
                                            <v-list-item v-for="member in designTeamMembers" :key="member.user_id" @click="assignCard(item, member.user_id)">
                                                <template v-slot:prepend>
                                                    <v-avatar size="20" color="purple" class="mr-2"><span class="text-[8px] text-white">{{ getInitials(member.profile?.full_name) }}</span></v-avatar>
                                                </template>
                                                <v-list-item-title class="text-caption font-weight-bold">{{ member.profile?.full_name }}</v-list-item-title>
                                            </v-list-item>
                                        </v-list>
                                    </v-menu>

                                    <v-btn v-else-if="!item.designer_id" size="x-small" variant="flat" color="purple" class="font-weight-black px-2 text-[10px] btn-3d" @click.stop="assignCard(item, userStore.profile?.id)">
                                          <v-icon start size="12">mdi-hand-back-right</v-icon> Assumir
                                    </v-btn>
                                </div>

                                <div class="mt-3 d-flex flex-column gap-2" v-if="item.designer_id === userStore.profile?.id || isLeaderOrRightHand">
                                    <v-btn
                                        v-if="!isLeaderOrRightHand && requiresApproval && column.tag_name !== 'Aprovação Líder'"
                                        block variant="tonal" size="x-small" color="purple" class="font-weight-bold btn-3d"
                                        @click.stop="openUploadModal(item.original, 'leader', 'development')"
                                    >
                                        <v-icon start size="14">mdi-cloud-upload</v-icon> Enviar p/ Líder
                                    </v-btn>

                                    <v-btn
                                        v-if="(!requiresApproval || column.tag_name === 'Aprovado' || column.tag_name === 'Aprovação Líder') && (isLeaderOrRightHand || !requiresApproval)"
                                        block variant="flat" size="x-small" color="purple" class="text-white font-weight-black btn-3d"
                                        @click.stop="openUploadModal(item.original, 'customer', 'development')"
                                    >
                                        <v-icon start size="14">mdi-check-decagram</v-icon> Enviar para Aprovação
                                    </v-btn>

                                    <v-btn
                                        v-if="isLeaderOrRightHand && column.tag_name === 'Aprovação Líder'"
                                        block variant="tonal" size="x-small" color="error" class="font-weight-bold btn-3d"
                                        @click.stop="openRejectModal(item)"
                                    >
                                        <v-icon start size="14">mdi-close-octagon</v-icon> Rejeitar Arte
                                    </v-btn>
                                </div>
                            </v-card-text>
                        </v-card>

                        <DevelopmentRequestCard
                          v-else-if="item.type === 'development'"
                          :item="item.original"
                          :design-team-members="designTeamMembers"
                          :current-user-perms="currentUserPerms"
                          @open="openModalForItem(item)"
                          @uploadLeader="openUploadModal(item.original, 'leader', 'development')"
                          @uploadCustomer="openUploadModal(item.original, 'customer', 'development')"
                          @itemUpdated="fetchAllData"
                          class="mb-2"
                        />

                        <v-card
                            v-else-if="item.type === 'pilot'"
                            class="production-card rounded-xl shadow-sm position-relative overflow-hidden mb-2"
                            :class="isLightMode ? 'bg-white border-indigo-lighten-2' : 'bg-surface-card border-indigo-darken-3'"
                            style="border-width: 2px !important; border-style: solid !important;"
                            @click="openModalForItem(item)"
                            v-ripple
                        >
                            <v-card-text class="pa-3 position-relative z-10">
                                <div class="d-flex align-center justify-space-between mb-3">
                                    <v-chip size="x-small" color="indigo" variant="flat" class="font-weight-black px-2 btn-3d">
                                        <v-icon start size="12">mdi-flask</v-icon> PILOTO (SITE)
                                    </v-chip>
                                    <div class="d-flex gap-2 align-center">
                                      <v-chip v-if="item.original.group_id" size="x-small" color="indigo-lighten-4" class="text-indigo-darken-4 font-weight-black px-2" variant="flat">
                                        GRP: {{ item.original.group_id.substring(0,4).toUpperCase() }}
                                      </v-chip>
                                      <span class="text-[10px] font-weight-bold opacity-70 font-mono text-indigo">
                                          {{ item.original.id.substring(0,8).toUpperCase() }}
                                      </span>
                                    </div>
                                </div>

                                <div class="text-body-2 font-weight-black lh-1 text-truncate mb-1" :class="isLightMode ? 'text-grey-darken-4' : 'text-white'">
                                    {{ item.customer_name }}
                                </div>

                                <div class="d-flex align-center gap-3 mt-2 mb-2 pa-2 rounded" :class="isLightMode ? 'bg-grey-lighten-4' : 'bg-black-20'">
                                   <v-img
                                     :src="item.original.custom_stamp_url || item.original.stamp?.main_image_url || '/placeholder.png'"
                                     width="40" height="40" cover class="rounded shadow-sm border"
                                   ></v-img>
                                   <div class="d-flex flex-column overflow-hidden">
                                      <span class="text-[10px] font-weight-bold text-truncate">{{ item.original.custom_stamp_url ? 'Arte Exclusiva do Cliente' : (item.original.stamp?.title || 'Estampa') }}</span>
                                      <span class="text-[9px] opacity-70">{{ item.stamp_ref }}</span>
                                   </div>
                                </div>

                                <div v-if="item.original.notes" class="text-[10px] opacity-80 mt-2 mb-2 font-italic border-s-2 pl-2 border-indigo lh-1">
                                    "{{ item.original.notes }}"
                                </div>

                                <div class="d-flex align-center justify-space-between pt-2 border-t" :class="isLightMode ? 'border-indigo-lighten-4' : 'border-indigo-darken-4'">
                                    <div class="d-flex align-center gap-2">
                                        <v-avatar size="24" :color="item.designer_id ? 'indigo' : 'grey-lighten-1'" class="shadow-sm">
                                            <span class="text-[10px] font-weight-bold text-white">{{ getInitials(getDesignerName(item.designer_id)) }}</span>
                                        </v-avatar>
                                        <div class="d-flex flex-column lh-1">
                                            <span class="text-[9px] font-weight-black uppercase opacity-60">Designer</span>
                                            <span class="text-[10px] font-weight-bold text-truncate" style="max-width: 80px;" :class="item.designer_id ? '' : 'text-error'">
                                                {{ getDesignerName(item.designer_id) || 'Livre' }}
                                            </span>
                                        </div>
                                    </div>

                                    <v-btn v-if="!item.designer_id" size="x-small" variant="flat" color="indigo" class="font-weight-black px-2 text-[10px] btn-3d" @click.stop="assignCard(item, userStore.profile?.id)">
                                          <v-icon start size="12">mdi-hand-back-right</v-icon> Assumir
                                    </v-btn>
                                </div>
                            </v-card-text>
                        </v-card>

                        <v-card
                            v-else
                            class="production-card rounded-0 border-s-4 shadow-sm"
                            :class="[
                                themeStore.currentMode === 'light' ? 'bg-white border-thin' : 'bg-surface-card border-white-05',
                                isItemDelayed(item) ? 'border-error' : ''
                            ]"
                            :style="`border-left-color: ${isItemDelayed(item) ? '#FF5252' : column.accentColor} !important; border-left-width: 4px !important;`"
                            variant="flat"
                            @click="openModalForItem(item)"
                            v-ripple
                          >
                              <v-card-text class="pa-3">
                                <div class="d-flex align-center justify-space-between mb-1">
                                     <span class="pill-ref">#{{ String(item.original.order?.order_number || 'N/A').padStart(4, '0') }}</span>
                                     <v-icon v-if="item.status === 'customer_approval'" size="14" color="warning" class="animate-bounce">mdi-account-clock</v-icon>
                                </div>
                                <div class="text-body-2 font-weight-black lh-1 text-truncate mb-2" :title="item.customer_name">
                                  {{ item.customer_name }}
                                </div>
                                <div class="d-flex align-center gap-1 mb-2">
                                   <v-icon size="12" class="opacity-50">mdi-tag-outline</v-icon>
                                   <span class="text-[10px] font-weight-bold opacity-70 text-uppercase text-truncate">
                                     {{ item.stamp_ref }}
                                   </span>
                                </div>
                                <div class="d-flex align-center justify-space-between mt-2 pt-2 border-t" :class="themeStore.currentMode === 'light' ? 'border-grey-lighten-3' : 'border-white-05'">
                                   <div class="d-flex flex-column gap-0">
                                       <span class="text-[10px] font-weight-bold text-uppercase opacity-60">{{ item.fabric_type }}</span>
                                       <span class="text-[9px] font-weight-bold text-primary d-flex align-center mt-0.5" :title="formatDateFull(item.original.created_at)">
                                           <v-icon size="10" start class="mr-1">mdi-clock-time-four-outline</v-icon>
                                           {{ getRelativeTime(item.original.created_at) }}
                                       </span>
                                   </div>
                                   <div class="font-weight-black text-caption font-mono">{{ Number(item.quantity_meters).toLocaleString('pt-BR') }}m</div>
                                </div>

                                <div class="mt-2 pt-2 border-t d-flex align-center justify-space-between" :class="themeStore.currentMode === 'light' ? 'border-grey-lighten-3' : 'border-white-05'" v-if="column.id !== 'col-app'">
                                    <div class="d-flex align-center gap-2">
                                        <v-avatar size="24" :color="item.designer_id ? 'primary' : 'grey-lighten-1'" class="shadow-sm">
                                            <span class="text-[10px] text-white font-weight-bold">{{ getInitials(getDesignerName(item.designer_id)) }}</span>
                                        </v-avatar>
                                        <div class="d-flex flex-column lh-1">
                                            <span class="text-[9px] font-weight-black uppercase opacity-60">Responsável</span>
                                            <span class="text-[10px] font-weight-bold text-truncate" style="max-width: 90px;" :class="item.designer_id ? '' : 'text-error'">
                                                {{ getDesignerName(item.designer_id) || 'Sem Dono' }}
                                            </span>
                                        </div>
                                    </div>

                                    <v-menu v-if="isLeaderOrRightHand" location="bottom end">
                                        <template v-slot:activator="{ props }">
                                            <v-btn v-bind="props" size="x-small" variant="tonal" color="deep-purple-darken-1" class="font-weight-bold px-2 text-[10px] btn-3d" @click.stop>
                                                <v-icon start size="12">mdi-account-switch</v-icon> Atribuir
                                            </v-btn>
                                        </template>
                                        <v-list density="compact" nav>
                                            <v-list-item @click="assignCard(item, null)">
                                                <template v-slot:prepend><v-icon size="small" color="grey">mdi-account-off</v-icon></template>
                                                <v-list-item-title class="text-caption font-weight-bold">Nenhum (Livre)</v-list-item-title>
                                            </v-list-item>
                                            <v-divider class="my-1"></v-divider>
                                            <v-list-item v-for="member in designTeamMembers" :key="member.user_id" @click="assignCard(item, member.user_id)">
                                                <template v-slot:prepend>
                                                    <v-avatar size="20" color="primary" class="mr-2"><span class="text-[8px] text-white">{{ getInitials(member.profile?.full_name) }}</span></v-avatar>
                                                </template>
                                                <v-list-item-title class="text-caption font-weight-bold">{{ member.profile?.full_name }}</v-list-item-title>
                                            </v-list-item>
                                        </v-list>
                                    </v-menu>

                                    <v-btn v-else-if="!item.designer_id" size="x-small" variant="tonal" color="success" class="font-weight-bold px-2 text-[10px] btn-3d" @click.stop="assignCard(item, userStore.profile?.id)">
                                         <v-icon start size="12">mdi-hand-back-right</v-icon> Assumir
                                    </v-btn>
                                </div>

                                <div class="mt-3 d-flex flex-column gap-2" v-if="column.id !== 'col-app' && (isLeaderOrRightHand || item.designer_id === userStore.profile?.id)">

                                    <v-btn
                                        v-if="!isLeaderOrRightHand && requiresApproval && column.tag_name !== 'Aprovação Líder'"
                                        block
                                        variant="tonal"
                                        size="x-small"
                                        color="deep-purple-accent-4"
                                        class="font-weight-bold btn-3d"
                                        @click.stop="openUploadModal(item.original, 'leader', 'order')"
                                    >
                                        <v-icon start size="14">mdi-cloud-upload</v-icon>
                                        Upload / Enviar p/ Líder
                                    </v-btn>

                                    <v-btn
                                        v-if="(!requiresApproval || column.tag_name === 'Aprovado') && !isLeaderOrRightHand"
                                        block
                                        variant="flat"
                                        size="x-small"
                                        color="primary"
                                        class="font-weight-bold btn-3d"
                                        @click.stop="openUploadModal(item.original, 'customer', 'order')"
                                    >
                                        <v-icon start size="14">mdi-cloud-upload</v-icon>
                                        Upload / Enviar Vendedor
                                    </v-btn>

                                    <v-btn
                                        v-if="isLeaderOrRightHand && column.tag_name === 'Aprovação Líder'"
                                        block
                                        variant="flat"
                                        size="x-small"
                                        color="success"
                                        class="font-weight-bold btn-3d"
                                        @click.stop="openUploadModal(item.original, 'customer', 'order')"
                                    >
                                        <v-icon start size="14">mdi-check-decagram</v-icon>
                                        Aprovar Arte e Enviar Vendedor
                                    </v-btn>

                                    <v-btn
                                        v-if="isLeaderOrRightHand && column.tag_name === 'Aprovação Líder'"
                                        block
                                        variant="tonal"
                                        size="x-small"
                                        color="error"
                                        class="font-weight-bold btn-3d"
                                        @click.stop="openRejectModal(item)"
                                    >
                                        <v-icon start size="14">mdi-close-octagon</v-icon>
                                        Rejeitar / Solicitar Ajuste
                                    </v-btn>

                                    <v-btn
                                        v-if="itemRejectionCounts[item.id] > 0"
                                        block
                                        variant="outlined"
                                        size="x-small"
                                        color="warning"
                                        class="font-weight-bold border-dashed mt-1 btn-3d"
                                        @click.stop="openRejectionHistory(item)"
                                    >
                                        <v-icon start size="14">mdi-history</v-icon>
                                        Ver Rejeições ({{ itemRejectionCounts[item.id] }})
                                    </v-btn>

                                </div>

                                <div class="mt-3" v-if="column.id === 'col-app'">
                                    <v-btn
                                        v-if="item.original.is_op_generated"
                                        block
                                        variant="tonal"
                                        size="x-small"
                                        color="info"
                                        class="font-weight-bold btn-3d"
                                        @click.stop="generateOpPdf(item.original)"
                                    >
                                        <v-icon start size="14">mdi-printer-check</v-icon>
                                        OP #{{ item.original.op_number || 'Gerada' }}
                                    </v-btn>
                                    <v-btn
                                        v-else
                                        block
                                        variant="flat"
                                        size="x-small"
                                        color="warning"
                                        class="font-weight-bold btn-3d"
                                        @click.stop="generateOpPdf(item.original)"
                                    >
                                        <v-icon start size="14">mdi-printer-alert</v-icon>
                                        Gerar OP (Obrigatório)
                                    </v-btn>
                                </div>
                              </v-card-text>
                          </v-card>
                       </div>
                    </template>
                 </draggable>
            </div>
          </div>
        </v-card>
      </div>

      <v-dialog v-model="pilotDetailModal.show" max-width="500">
        <v-card class="rounded-xl border shadow-lg" :class="!isLightMode ? 'bg-grey-darken-4 border-white-10 text-white' : 'bg-white border-grey-lighten-2 text-grey-darken-4'">
          <div class="px-6 py-4 border-b d-flex align-center justify-space-between" :class="!isLightMode ? 'border-white-10' : 'border-grey-lighten-2'">
             <h3 class="text-h6 font-weight-black d-flex align-center">
               <v-icon color="indigo" class="mr-2">mdi-flask</v-icon>
               Detalhes do Piloto
             </h3>
             <v-btn icon="mdi-close" variant="text" size="small" @click="pilotDetailModal.show = false"></v-btn>
          </div>
          <div class="pa-6" v-if="pilotDetailModal.item">
             <div class="d-flex align-center justify-space-between mb-4">
                <v-chip v-if="pilotDetailModal.item.original.group_id" color="indigo" variant="flat" class="font-weight-black btn-3d" size="small">
                    GRP: {{ pilotDetailModal.item.original.group_id.substring(0,4).toUpperCase() }}
                </v-chip>
                <v-chip v-else color="grey" variant="flat" class="font-weight-black btn-3d" size="small">PILOTO AVULSO</v-chip>
                <span class="text-caption font-mono opacity-70 font-weight-bold">ID: {{ pilotDetailModal.item.id.substring(0,8).toUpperCase() }}</span>
             </div>

             <div class="d-flex gap-4 mb-4">
               <v-img
                  :src="pilotDetailModal.item.original.custom_stamp_url || pilotDetailModal.item.original.stamp?.main_image_url"
                  width="100" height="100" cover class="rounded-lg shadow-sm cursor-pointer border hover-elevate"
                  @click="openImageModal(pilotDetailModal.item.original.custom_stamp_url || pilotDetailModal.item.original.stamp?.main_image_url, 'Arte do Piloto')"
               ></v-img>
               <div class="d-flex flex-column">
                  <span class="font-weight-black text-body-1">{{ pilotDetailModal.item.customer_name }}</span>
                  <span class="text-caption opacity-80 mt-1">Estampa: <strong>{{ pilotDetailModal.item.original.custom_stamp_url ? 'Exclusiva' : pilotDetailModal.item.original.stamp?.title }}</strong></span>
                  <span class="text-caption opacity-80">Tecido: <strong>{{ pilotDetailModal.item.fabric_type }}</strong> ({{ pilotDetailModal.item.quantity_meters }}m)</span>
               </div>
             </div>

             <div class="pa-4 rounded-lg border-thin" :class="!isLightMode ? 'bg-black-20 border-white-10' : 'bg-grey-lighten-5 border-grey-lighten-2'">
               <div class="text-[10px] font-weight-black text-uppercase mb-2 opacity-60"><v-icon size="12" class="mr-1">mdi-message-text-outline</v-icon>Observações</div>
               <p class="text-body-2 font-italic" :class="!pilotDetailModal.item.original.notes ? 'opacity-50' : ''">{{ pilotDetailModal.item.original.notes || 'Nenhuma observação registrada.' }}</p>
             </div>

             <div class="mt-6" v-if="pilotDetailModal.item.designer_id === userStore.profile?.id || isLeaderOrRightHand">
               <v-btn block color="indigo" size="large" class="btn-3d font-weight-black" @click="concludePilot(pilotDetailModal.item)">
                 <v-icon start>mdi-check-decagram</v-icon> Concluir Piloto
               </v-btn>
             </div>
          </div>
        </v-card>
      </v-dialog>

      <v-dialog v-model="showAssignmentRequestsModal" max-width="600">
          <v-card class="rounded-xl overflow-hidden" :class="isLightMode ? 'bg-white' : 'glass-card border-white-05'">
              <div class="pa-4 border-b d-flex align-center justify-space-between" :class="isLightMode ? 'bg-orange-lighten-5 text-orange-darken-4' : 'bg-orange-darken-4 text-white'">
                  <div class="d-flex align-center gap-2 font-weight-bold">
                      <v-icon>mdi-hand-back-right</v-icon>
                      Solicitações de Atribuição
                  </div>
                  <v-btn icon="mdi-close" variant="text" size="small" @click="showAssignmentRequestsModal = false"></v-btn>
              </div>
              <v-card-text class="pa-0">
                  <div v-if="assignmentRequests.length === 0" class="text-center pa-6 opacity-60">
                      Nenhuma solicitação pendente.
                  </div>
                  <v-list v-else density="comfortable" class="bg-transparent">
                      <v-list-item v-for="req in assignmentRequests" :key="req.id" class="border-b py-3">
                          <template v-slot:prepend>
                              <v-avatar color="primary" class="mr-3 text-white text-caption font-weight-bold">
                                  {{ getInitials(req.profile?.full_name) }}
                              </v-avatar>
                          </template>
                          <v-list-item-title class="font-weight-bold">{{ req.item_name }}</v-list-item-title>
                          <v-list-item-subtitle class="text-caption mt-1">
                              Designer: <strong>{{ req.profile?.full_name }}</strong>
                              &bull; {{ getRelativeTime(req.created_at) }}
                          </v-list-item-subtitle>
                          <template v-slot:append>
                              <div class="d-flex gap-2 align-center">
                                  <v-btn icon="mdi-close" color="error" variant="tonal" size="small" class="btn-3d" @click="rejectAssignment(req)" title="Recusar"></v-btn>
                                  <v-btn icon="mdi-check" color="success" variant="flat" size="small" class="btn-3d" @click="approveAssignment(req)" title="Aprovar e Atribuir"></v-btn>
                              </div>
                          </template>
                      </v-list-item>
                  </v-list>
              </v-card-text>
          </v-card>
      </v-dialog>

      <div class="system-footer d-flex justify-space-between align-center px-4 py-1 mt-auto" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-4 text-grey-darken-1' : 'bg-transparent text-grey-darken-1'">
         <div class="text-caption">&copy; {{ new Date().getFullYear() }} MJ Process.</div>
         <div class="text-caption font-weight-medium">v2.8.9 - Pilot Integrator</div>
      </div>

      <div v-if="tutorialStep > 0" class="tutorial-click-overlay" @click="advanceTutorial"></div>
      <transition name="fade">
        <div v-if="tutorialStep > 0" class="tutorial-highlight" :style="highlightStyle"></div>
      </transition>
      <transition name="hint-bounce">
        <div v-if="tutorialStep > 0" ref="hintBubbleRef" class="hint-bubble" :style="hintPosition">
          <div class="hint-bubble-content">
            <v-icon start size="small" color="white">{{ hintContent.icon }}</v-icon>
            <span v-html="hintContent.text"></span>
          </div>
        </div>
      </transition>

      <LaunchDetailModal
        :show="showLaunchModal"
        :order-id="selectedOrderId"
        :item-id="selectedItemId"
        @close="closeLaunchModal"
        @sendToSeller="item => openUploadModal(item, 'customer', 'order')"
        @sendToLeader="item => openUploadModal(item, 'leader', 'order')"
        @releaseItem="handleReleaseItem"
        @itemUpdated="fetchAllData"
      />

      <FileUploadModal
        :show="showUploadModal"
        :order="selectedOrder"
        :title="uploadModalTitle"
        @close="showUploadModal = false"
        @uploaded="handleUploadSuccess"
      />

      <DevelopmentDetailModal
        :show="showDevDetailModal"
        :request="selectedDevRequest"
        @close="showDevDetailModal = false"
        @completed="fetchAllData"
      />

      <StorefrontVIPDetailModal
        :show="showVipDetailModal"
        :request="selectedDevRequest"
        @close="showVipDetailModal = false"
        @deliver="handleVipDelivery"
      />

      <v-dialog v-model="rejectModal.show" max-width="500" persistent>
          <v-card class="rounded-xl overflow-hidden" :class="isLightMode ? 'bg-white' : 'glass-card border-white-05'">
              <div class="pa-4 border-b d-flex align-center justify-space-between bg-error text-white">
                  <div class="d-flex align-center gap-2 font-weight-bold">
                      <v-icon>mdi-alert-octagon</v-icon>
                      Rejeitar Arte: {{ rejectModal.item?.stamp_ref || rejectModal.item?.original?.dev_code }}
                  </div>
                  <v-btn icon="mdi-close" variant="text" size="small" @click="rejectModal.show = false"></v-btn>
              </div>
              <v-card-text class="pa-6">
                  <p class="text-body-2 mb-4" :class="isLightMode ? 'text-grey-darken-3' : 'text-white-70'">Descreva o motivo da rejeição e os ajustes necessários. A arte será devolvida para a coluna de <strong>Alteração</strong> do designer responsável.</p>
                  <v-textarea
                      v-model="rejectModal.reason"
                      label="Motivo / Ajustes Necessários *"
                      variant="outlined"
                      rows="4"
                      auto-grow
                      hide-details
                      :bg-color="isLightMode ? 'white' : 'rgba(0,0,0,0.2)'"
                  ></v-textarea>
              </v-card-text>
              <v-card-actions class="pa-4 border-t d-flex justify-end gap-3" :class="isLightMode ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-surface border-white-05'">
                  <v-btn variant="outlined" class="btn-3d font-weight-bold" @click="rejectModal.show = false" :color="isLightMode ? 'grey-darken-2' : 'white'">Cancelar</v-btn>
                  <v-btn color="error" variant="flat" class="px-6 font-weight-bold btn-3d" :loading="rejectModal.loading" :disabled="!rejectModal.reason" @click="confirmRejection">Confirmar Rejeição</v-btn>
              </v-card-actions>
          </v-card>
      </v-dialog>

      <v-dialog v-model="rejectionHistoryModal.show" max-width="700">
          <v-card class="rounded-xl overflow-hidden" :class="isLightMode ? 'bg-white' : 'glass-card border-white-05'">
              <div class="pa-4 border-b d-flex align-center justify-space-between" :class="isLightMode ? 'bg-warning-lighten-5 border-warning-lighten-4 text-warning-darken-4' : 'bg-warning-darken-4 text-white border-warning-darken-3'">
                  <div class="d-flex align-center gap-2 font-weight-bold">
                      <v-icon :color="isLightMode ? 'warning-darken-4' : 'white'">mdi-history</v-icon>
                      Histórico de Rejeições: {{ rejectionHistoryModal.item?.stamp_ref || rejectionHistoryModal.item?.original?.dev_code }}
                  </div>
                  <v-btn icon="mdi-close" variant="text" size="small" @click="rejectionHistoryModal.show = false"></v-btn>
              </div>
              <v-card-text class="pa-0">
                  <div v-if="rejectionHistoryModal.loading" class="pa-10 d-flex justify-center">
                      <v-progress-circular indeterminate color="warning"></v-progress-circular>
                  </div>
                  <div v-else class="pa-4 d-flex flex-column gap-4" :class="isLightMode ? 'bg-grey-lighten-5' : 'bg-surface'" style="max-height: 60vh; overflow-y: auto;">
                      <v-card v-for="log in rejectionHistoryModal.logs" :key="log.id" class="border-thin elevation-1" :class="isLightMode ? 'bg-white border-grey-lighten-2' : 'bg-surface-card border-white-05'">
                          <div class="d-flex flex-column flex-sm-row">
                              <div v-if="log.rejected_image_url" class="pa-3 border-r d-flex flex-column align-center justify-center" :class="isLightMode ? 'bg-grey-lighten-4 border-grey-lighten-2' : 'bg-black-20 border-white-05'" style="width: 140px; flex-shrink: 0; cursor: pointer;" @click="openImageModal(log.rejected_image_url, 'Arte Rejeitada')">
                                  <v-img :src="log.rejected_image_url" aspect-ratio="1" cover class="rounded border w-100" :class="isLightMode ? 'border-grey-lighten-3' : 'border-white-10'"></v-img>
                                  <div class="text-[9px] text-center mt-2 font-weight-bold text-uppercase opacity-70"><v-icon size="12" class="mr-1">mdi-magnify</v-icon> Ampliar</div>
                              </div>
                              <div class="pa-4 flex-grow-1">
                                  <div class="d-flex justify-space-between align-center mb-3">
                                      <div class="d-flex align-center gap-2">
                                          <v-avatar size="24" color="error" class="text-white"><v-icon size="14">mdi-account-cancel</v-icon></v-avatar>
                                          <div class="d-flex flex-column lh-1">
                                              <span class="text-[9px] font-weight-black text-uppercase opacity-60">Rejeitado por</span>
                                              <span class="text-caption font-weight-bold">{{ log.leader?.full_name || 'Líder' }}</span>
                                          </div>
                                      </div>
                                      <span class="text-[10px] opacity-70 font-mono">{{ formatDateFull(log.created_at) }}</span>
                                  </div>
                                  <div class="text-body-2 pa-3 rounded border" :class="isLightMode ? 'bg-red-lighten-5 text-red-darken-4 border-red-lighten-4' : 'bg-red-darken-4-alpha text-red-lighten-1 border-red-darken-3'">
                                      {{ log.reason }}
                                  </div>
                              </div>
                          </div>
                      </v-card>
                      <div v-if="rejectionHistoryModal.logs.length === 0" class="text-center pa-6 opacity-60">
                          Nenhum registro encontrado.
                      </div>
                  </div>
              </v-card-text>
          </v-card>
      </v-dialog>

      <v-dialog v-model="showHistoryModal" max-width="1200" transition="dialog-bottom-transition" :scrim="true" persistent class="history-modal">
        <v-card class="d-flex flex-column overflow-hidden history-card rounded-0 fill-height" :class="isLightMode ? 'bg-grey-lighten-5' : 'bg-surface-modal'">
            <div class="header-bar px-6 py-4 d-flex align-center justify-space-between flex-shrink-0" :class="isLightMode ? 'bg-white border-b border-grey-lighten-2' : 'bg-glass-header border-bottom-white-05'">
                <div class="d-flex flex-column">
                  <div class="breadcrumb text-caption"><span class="opacity-70">Design</span><span class="mx-2 opacity-50">&gt;</span><span class="font-weight-bold">Liberações</span></div>
                  <div class="text-h6 font-weight-black tracking-tight leading-none mt-1" :class="textPrimaryClass">Histórico de Produção</div>
                </div>
                <v-btn icon="mdi-close" variant="text" size="large" @click="showHistoryModal = false" :color="textSecondaryColor"></v-btn>
            </div>

            <div class="px-6 pt-4 pb-2 flex-shrink-0">
               <div class="controls-bar d-flex align-center justify-space-between" :class="isLightMode ? 'controls-light' : 'controls-dark'">
                  <div class="d-flex align-center flex-wrap" style="gap: 10px;">
                      <div class="search-wrap d-flex align-center" :class="isLightMode ? 'search-light' : 'search-dark'">
                        <v-icon :color="isLightMode ? 'grey-darken-1' : 'white-70'">mdi-magnify</v-icon>
                        <input v-model="historySearch" type="text" placeholder="Buscar por cliente, estampa, ref..." class="clean-input flex-grow-1"/>
                      </div>
                  </div>
               </div>
            </div>

            <div class="px-6 py-3 flex-shrink-0">
                <v-row dense>
                    <v-col cols="12" md="6">
                        <v-card class="kpi-card kpi-rect bg-gradient-success py-3 px-4" elevation="2">
                            <div class="kpi-bg-icon"><v-icon>mdi-check-decagram</v-icon></div>
                            <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                                <div class="d-flex align-center gap-2"><v-icon size="18" class="opacity-80">mdi-check-all</v-icon><span class="kpi-label">Liberados</span></div>
                                <div class="kpi-number-group my-1"><span class="kpi-value">{{ paginatedHistoryItems.length }}</span><span class="text-caption ml-2 opacity-80">itens</span></div>
                                <div class="kpi-footer">Total Geral</div>
                            </div>
                        </v-card>
                    </v-col>
                    <v-col cols="12" md="6">
                        <v-card class="kpi-card kpi-rect bg-gradient-info py-3 px-4" elevation="2">
                            <div class="kpi-bg-icon"><v-icon>mdi-ruler</v-icon></div>
                            <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                                <div class="d-flex align-center gap-2"><v-icon size="18" class="opacity-80">mdi-ruler-square</v-icon><span class="kpi-label">Volume Processado</span></div>
                                <div class="kpi-number-group my-1"><span class="kpi-value">{{ historyTotalMeters }}</span><span class="text-caption ml-2 opacity-80">metros</span></div>
                                <div class="kpi-footer">Acumulado</div>
                            </div>
                        </v-card>
                    </v-col>
                </v-row>
            </div>

            <div class="flex-grow-1 px-6 pb-2 overflow-hidden d-flex flex-column">
                <v-card class="flex-grow-1 d-flex flex-column rounded-0 border-thin overflow-hidden" :class="isLightMode ? 'bg-white shadow-sm' : 'glass-card border-white-05'" :elevation="0">
                    <div class="grid-scroll flex-grow-1 overflow-y-auto custom-scroll">
                        <div class="grid-header sticky-head" :class="isLightMode ? 'grid-surface-light' : 'grid-surface-dark'">
                             <div class="cell center header-text" style="width: 80px;">Ref.</div>
                             <div class="cell header-text flex-grow-1">Cliente / Estampa</div>
                             <div class="cell center header-text" style="width: 140px;">Tecido</div>
                             <div class="cell center header-text" style="width: 120px;">Metragem</div>
                             <div class="cell center header-text" style="width: 140px;">Data Liberação</div>
                             <div class="cell center header-text" style="width: 120px;">Ações</div>
                        </div>

                        <div v-if="loadingHistory" class="d-flex flex-column justify-center align-center h-100 py-10">
                            <v-progress-circular indeterminate color="primary" size="32"></v-progress-circular>
                        </div>
                        <div v-else-if="filteredHistory.length === 0" class="d-flex flex-column justify-center align-center h-100 opacity-60 gap-2 py-10">
                            <v-icon size="48" color="grey-lighten-1">mdi-file-hidden</v-icon>
                            <span class="text-body-2 font-weight-medium text-grey">Nenhum registro encontrado</span>
                        </div>

                        <div v-else v-for="(item, index) in paginatedHistoryItems" :key="item.id" class="grid-row" :class="[isLightMode ? 'grid-row-light' : 'grid-row-dark', zebraClass(index)]">
                             <div class="cell center" style="width: 80px;">
                                 <span class="pill-ref">{{ String(item.order?.order_number || 'N/A').padStart(4,'0') }}</span>
                             </div>
                             <div class="cell flex-grow-1">
                                 <div class="d-flex flex-column">
                                     <span class="text-body-2 font-weight-bold text-truncate">{{ item.order?.customer_name || 'Desconhecido' }}</span>
                                     <span class="text-[10px] opacity-70">{{ item.stamp_ref || '-' }}</span>
                                 </div>
                             </div>
                             <div class="cell center" style="width: 140px;">
                                 <span class="text-[11px] font-weight-bold opacity-80">{{ item.fabric_type || '-' }}</span>
                             </div>
                             <div class="cell center" style="width: 120px;">
                                 <span class="font-mono font-weight-black text-[11px]">{{ Number(item.quantity_meters).toLocaleString('pt-BR') }}m</span>
                             </div>
                             <div class="cell center" style="width: 140px;">
                                <span class="solid-chip chip-success chip-3d font-mono">
                                    {{ item.scheduled_at ? formatDateSimple(item.scheduled_at) : 'Hoje' }}
                                </span>
                             </div>
                             <div class="cell center" style="width: 120px;">
                                 <div class="actions-inline">
                                     <v-btn icon size="small" class="action-btn action-edit btn-3d" @click.stop="generateOpPdf(item)" title="Baixar OP" variant="flat"><v-icon size="18">mdi-file-pdf-box</v-icon></v-btn>
                                 </div>
                             </div>
                        </div>
                    </div>

                    <div class="flex-shrink-0 border-t px-4 py-2 d-flex align-center justify-space-between" :class="isLightMode ? 'bg-grey-lighten-5' : 'bg-white-05'">
                        <div class="text-caption opacity-80">Total: <strong>{{ filteredHistory.length }}</strong> registros</div>
                        <v-pagination v-model="historyPage" :length="historyPageCount" :total-visible="5" density="compact" active-color="success" variant="tonal" size="small"></v-pagination>
                    </div>
                </v-card>
            </div>
        </v-card>
      </v-dialog>

      <v-dialog v-model="showColumnManagerModal" max-width="800" persistent>
        <v-card>
            <v-card-title class="d-flex align-center justify-space-between bg-primary text-white pa-4">
                <span>Gerenciar Fluxo de Colunas Dinâmicas</span>
                <v-btn icon="mdi-close" variant="text" @click="showColumnManagerModal = false"></v-btn>
            </v-card-title>
            <v-card-text class="pa-4">
                <div class="d-flex align-center gap-2 mb-4">
                    <v-text-field v-model="newColumn.title" label="Nome da Coluna (Ex: Vetorização)" density="compact" hide-details variant="outlined"></v-text-field>
                    <v-text-field v-model="newColumn.tag_name" label="Tag de Vínculo" density="compact" hide-details variant="outlined"></v-text-field>
                    <v-text-field v-model="newColumn.order_index" type="number" label="Ordem" style="max-width: 100px" density="compact" hide-details variant="outlined"></v-text-field>
                    <v-btn color="success" class="btn-3d font-weight-bold" prepend-icon="mdi-plus" @click="saveNewColumn">Adicionar</v-btn>
                </div>

                <v-table density="compact" class="border">
                    <thead>
                        <tr>
                            <th>Ordem</th>
                            <th>Título</th>
                            <th>Tag Oculta? (NewOrder)</th>
                            <th>Ações</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr v-for="col in dynamicColumnsConfig" :key="col.id">
                            <td>{{ col.order_index }}</td>
                            <td><strong>{{ col.title }}</strong><br><small class="text-grey">{{ col.tag_name }}</small></td>
                            <td>
                                <v-switch
                                    v-model="col.available_in_new_order"
                                    color="primary"
                                    hide-details
                                    density="compact"
                                    @change="updateColumnVisibility(col)"
                                ></v-switch>
                            </td>
                            <td>
                                <v-btn icon="mdi-delete" size="small" variant="text" color="error" @click="deleteColumn(col.id)"></v-btn>
                            </td>
                        </tr>
                    </tbody>
                </v-table>
                <p class="text-caption text-grey mt-2">* As colunas "Desenvolvimento" e "Aprovação Líder" são estruturais e a coluna "Aprovados" é fixada no fim.</p>
            </v-card-text>
        </v-card>
      </v-dialog>

      <v-dialog v-model="showTeamManagerModal" max-width="900" persistent>
        <v-card class="bg-grey-lighten-4">
            <v-card-title class="d-flex align-center justify-space-between bg-deep-purple-darken-1 text-white pa-4 shadow-sm">
                <div class="d-flex align-center gap-2">
                    <v-icon>mdi-account-group</v-icon>
                    <span>Equipe de Design & Permissões</span>
                </div>
                <v-btn icon="mdi-close" variant="text" @click="showTeamManagerModal = false"></v-btn>
            </v-card-title>

            <v-card-text class="pa-6">
                <v-card class="mb-6 pa-4 border-thin shadow-sm" elevation="0">
                    <h4 class="text-subtitle-2 font-weight-black uppercase text-grey-darken-3 mb-3">Adicionar Colaborador à Equipe</h4>
                    <div class="d-flex gap-3">
                        <v-autocomplete
                            v-model="newUserToTeam"
                            :items="availableProfilesToAdd"
                            item-title="full_name"
                            item-value="id"
                            label="Buscar colaborador no sistema..."
                            variant="outlined"
                            density="compact"
                            hide-details
                            prepend-inner-icon="mdi-account-search"
                            class="bg-white flex-grow-1"
                        ></v-autocomplete>
                        <v-btn color="deep-purple-darken-1" height="40" class="font-weight-bold btn-3d" prepend-icon="mdi-plus" @click="addMemberToTeam(newUserToTeam)">Adicionar</v-btn>
                    </div>
                </v-card>

                <v-card class="border-thin shadow-sm overflow-hidden" elevation="0">
                    <v-table density="comfortable" hover>
                        <thead class="bg-grey-lighten-3">
                            <tr>
                                <th class="font-weight-black text-uppercase text-[11px]">Designer</th>
                                <th class="font-weight-black text-uppercase text-[11px] text-center">Líder (Visão Total)</th>
                                <th class="font-weight-black text-uppercase text-[11px] text-center">Requer Avaliação (Iniciante)</th>
                                <th class="font-weight-black text-uppercase text-[11px] text-center">Braço Direito (Aprova)</th>
                                <th class="font-weight-black text-uppercase text-[11px] text-center">Ações</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr v-for="user in designTeamMembers" :key="user.user_id" class="bg-white">
                                <td>
                                    <div class="d-flex align-center gap-3 py-2">
                                        <v-avatar size="32" color="deep-purple-lighten-4" class="text-deep-purple-darken-4 font-weight-bold text-[12px]">
                                            {{ getInitials(user.profile?.full_name) }}
                                        </v-avatar>
                                        <div class="d-flex flex-column">
                                            <strong class="text-body-2">{{ user.profile?.full_name || 'Desconhecido' }}</strong>
                                            <span class="text-[10px] text-medium-emphasis">{{ user.profile?.email }}</span>
                                        </div>
                                    </div>
                                </td>
                                <td class="text-center">
                                    <v-switch v-model="user.is_leader" color="deep-purple" hide-details density="compact" class="d-inline-flex" @change="updateUserPermission(user)"></v-switch>
                                </td>
                                <td class="text-center">
                                    <v-switch v-model="user.requires_leader_approval" color="warning" hide-details density="compact" class="d-inline-flex" @change="updateUserPermission(user)"></v-switch>
                                </td>
                                <td class="text-center">
                                    <v-switch v-model="user.can_approve_for_leader" color="info" hide-details density="compact" class="d-inline-flex" @change="updateUserPermission(user)"></v-switch>
                                </td>
                                <td class="text-center">
                                    <v-btn icon="mdi-delete" color="error" variant="text" size="small" title="Remover da equipe" @click="removeMemberFromTeam(user.user_id)"></v-btn>
                                </td>
                            </tr>
                            <tr v-if="designTeamMembers.length === 0">
                                <td colspan="5" class="text-center py-6 text-medium-emphasis">Nenhum colaborador adicionado à equipe de design.</td>
                            </tr>
                        </tbody>
                    </v-table>
                </v-card>
            </v-card-text>
        </v-card>
      </v-dialog>

      <ImageModal
        :show="showImageModal"
        :image-url="selectedImageUrl"
        :file-name="selectedImageName"
        @close="showImageModal = false"
      />

    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, computed, onActivated, reactive, nextTick } from 'vue';
import { supabase } from '@/api/supabase';
import { useUserStore } from '@/stores/user';
import { useAppStore } from '@/stores/app';
import { useThemeStore } from '@/stores/theme';
import { useCompanyStore } from '@/stores/company';
import draggable from 'vuedraggable';
import LaunchDetailModal from '@/components/LaunchDetailModal.vue';
import FileUploadModal from '@/components/FileUploadModal.vue';
import DevelopmentRequestCard from '@/components/design/DevelopmentRequestCard.vue';
import DevelopmentDetailModal from '@/components/design/DevelopmentDetailModal.vue';
import StorefrontVIPDetailModal from '@/components/design/StorefrontVIPDetailModal.vue';
import ImageModal from '@/components/ImageModal.vue';
import { format, addDays, parseISO, formatDistanceToNow as fDistance } from 'date-fns';
import { ptBR } from 'date-fns/locale';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';

// --- TYPES ---
type KanbanCard = { id: string; type: 'order' | 'development' | 'pilot' | 'pilot_internal'; status: string; design_tag?: string; designer_id?: string | null; customer_name?: string; stamp_ref?: string; fabric_type?: string; quantity_meters?: number; original: any; };
type OrderItem = { id: string; status: string; design_tag: string; order_id: string; order: Order; unit_of_measure: string | null; quantity_unit: number | null; is_op_generated: boolean; stamp_image_url?: string; quantity_meters: number; stamp_ref?: string; fabric_type?: string; scheduled_at?: string; [key: string]: any };
type Order = { id: string; status: string; is_launch: boolean; order_items: OrderItem[]; created_at: string; order_number: number; customer_name: string; designer_id?: string | null; creator: { full_name: string }; [key: string]: any };
type DevRequest = { id: string; status: string; dev_code: string; designer_id?: string | null; design_items: any; profile: { full_name: string }; created_at: string; general_notes?: string; [key: string]: any };

type ColumnConfig = { id: string; title: string; tag_name: string; bg_class: string; dot_color: string; chip_color: string; accent_color: string; order_index: number; allowed_roles: string[]; available_in_new_order: boolean };
type UserPermission = { user_id: string; is_leader: boolean; requires_leader_approval: boolean; can_approve_for_leader: boolean; profile?: any };

// --- STATE ---
const themeStore = useThemeStore();
const userStore = useUserStore();
const appStore = useAppStore();
const companyStore = useCompanyStore();

const loading = ref(true);
const allOrders = ref<Order[]>([]);
const allDevRequests = ref<DevRequest[]>([]);
const allPilotRequests = ref<any[]>([]); // MALANDRAGEM: Adicionado lista de pilotos
const publicLeadsMap = ref<Map<string, string>>(new Map());

const dynamicColumnsConfig = ref<ColumnConfig[]>([]);
const teamPermissions = ref<UserPermission[]>([]);
const allProfiles = ref<any[]>([]);
const newUserToTeam = ref<string | null>(null);

const itemRejectionCounts = ref<Record<string, number>>({});
const rejectModal = reactive({ show: false, item: null as any, reason: '', loading: false });
const rejectionHistoryModal = reactive({ show: false, logs: [] as any[], loading: false, item: null as any });

const showImageModal = ref(false);
const selectedImageUrl = ref<string | undefined>('');
const selectedImageName = ref<string | undefined>('');

const showLaunchModal = ref(false);
const showUploadModal = ref(false);
const showHistoryModal = ref(false);
const showDevDetailModal = ref(false);
const showVipDetailModal = ref(false);
const showColumnManagerModal = ref(false);
const showTeamManagerModal = ref(false);
const showAssignmentRequestsModal = ref(false);
const pilotDetailModal = reactive({ show: false, item: null as any }); // NOVO MODAL PRA DETALHE DE PILOTO

const assignmentRequests = ref<any[]>([]);
const uploadDestination = ref<'customer' | 'leader'>('customer');
const newColumn = reactive({ title: '', tag_name: '', order_index: 10, bg_class: 'bg-grey-lighten-5', dot_color: 'bg-primary', chip_color: 'primary', accent_color: '#1976D2', available_in_new_order: true });

const selectedOrder = ref<Order | null>(null);
const selectedOrderId = ref<string | null>(null);
const selectedItemId = ref<string | null>(null);
const selectedItem = ref<any>(null);
const selectedDevRequest = ref<DevRequest | null>(null);
const uploadModalTitle = ref('');

const searchQuery = ref('');
const filterDelayed = ref(false);
const columnSorts = reactive<Record<string, string>>({});

const loadingHistory = ref(false);
const releasedItemsHistory = ref<OrderItem[]>([]);
const historySearch = ref('');
const historyPage = ref(1);
const historyItemsPerPage = 50;

const hintsEnabled = ref(JSON.parse(localStorage.getItem('DesignKanbanHints') ?? 'true'));
const tutorialStep = ref(0);
const hintPosition = ref({});
const highlightStyle = ref({});
const hintContent = reactive({ icon: '', text: '' });
const searchFieldRef = ref(null);
const hintBubbleRef = ref<HTMLElement | null>(null);
const isGeneratingPdf = ref(false);

const isLightMode = computed(() => themeStore.currentMode === 'light');
const textPrimaryClass = computed(() => isLightMode.value ? 'text-grey-darken-4' : 'text-white');
const textSecondaryColor = computed(() => isLightMode.value ? 'grey-darken-2' : 'white');

const selectedKpiIds = ref(['total', 'delayed', 'development', 'approved']);
const kpiOptions = [
  { value: 'total', title: 'Total Fluxo', icon: 'mdi-format-list-bulleted-type', iconColor: 'blue', gradient: 'bg-gradient-info' },
  { value: 'delayed', title: 'Atrasados', icon: 'mdi-clock-alert-outline', iconColor: 'orange', gradient: 'bg-gradient-warning' },
  { value: 'development', title: 'Em Desenv.', icon: 'mdi-lightbulb-on-outline', iconColor: 'cyan', gradient: 'bg-gradient-purple' },
  { value: 'approved', title: 'Aprovados', icon: 'mdi-check-decagram', iconColor: 'green', gradient: 'bg-gradient-success' },
];

const changeKpi = (index: number, value: string) => {
    selectedKpiIds.value[index] = value;
    localStorage.setItem('DesignKanbanKpis', JSON.stringify(selectedKpiIds.value));
};

// --- DATA FETCHING ---
const fetchSystemConfigs = async () => {
    const { data: cols } = await supabase.from('design_kanban_columns').select('*').order('order_index', { ascending: true });
    if (cols) dynamicColumnsConfig.value = cols as ColumnConfig[];

    const { data: profs } = await supabase.from('profiles').select('id, full_name, email, role, custom_role_id');
    if (profs) allProfiles.value = profs;

    const { data: perms } = await supabase.from('design_user_permissions').select('*');
    if (perms && profs) {
        teamPermissions.value = perms.map(p => ({
            ...p,
            profile: profs.find(pr => pr.id === p.user_id)
        }));
    }
};

const fetchRejectionCounts = async () => {
    const itemIds = baseKanbanCards.value.map(c => c.id);
    if (itemIds.length === 0) return;
    try {
        const { data } = await supabase.from('design_rejection_logs').select('item_id').in('item_id', itemIds);
        const counts: Record<string, number> = {};
        data?.forEach(log => { counts[log.item_id] = (counts[log.item_id] || 0) + 1; });
        itemRejectionCounts.value = counts;
    } catch(e) { console.warn("Tabela design_rejection_logs ausente ou vazia."); }
};

const fetchAssignmentRequests = async () => {
    if (!isLeaderOrRightHand.value) return;
    try {
        const { data, error } = await supabase
            .from('design_assignment_requests')
            .select('*, profile:profiles!designer_id(full_name)')
            .eq('status', 'pending')
            .order('created_at', { ascending: true });
        if (!error) assignmentRequests.value = data || [];
    } catch(e) {}
};

const fetchAllData = async () => {
  loading.value = true;

  if (companyStore.isDemoMode) {
      loading.value = false;
      return;
  }

  try {
    await fetchSystemConfigs();
    await fetchUserPerms();
    await fetchAssignmentRequests();

    // Map dos Leads para puxar o nome do ecommerce nos Pilotos
    const { data: leads } = await supabase.from('public_leads').select('id, name');
    if (leads) publicLeadsMap.value = new Map(leads.map(l => [l.id, l.name]));

    const designStatuses = ['design_pending', 'customer_approval', 'changes_requested', 'approved_by_designer', 'approved_by_seller'];
    const { data: orderData, error: orderError } = await supabase.from('orders')
      .select(`id, customer_name, status, is_launch, created_at, order_number, designer_id, creator:created_by(full_name), order_items!inner(*)`)
      .in('order_items.status', designStatuses);
    if (orderError) throw orderError;
    allOrders.value = (orderData as any[]) || [];

    const { data: devData, error: devError } = await supabase.from('design_requests')
      .select(`id, status, dev_code, designer_id, created_at, general_notes, design_items, design_tag, request_type, profile:created_by(id, full_name, avatar_url)`)
      .in('status', ['design_pending', 'in_design', 'finalizing', 'completed', 'approved_by_designer', 'pending_approval']);
    if (devError) throw devError;
    allDevRequests.value = (devData as any[]) || [];

    // MALANDRAGEM: Buscar Pilotos da Tabela Nova que estejam pagos
    const { data: pilotData, error: pilotError } = await supabase.from('pilot_requests')
        .select('*, stamp:catalog_stamps(title, ref_code, main_image_url), fabric:catalog_fabrics(name), customer_mj:customers_mj(nome, razao_social, cpf, cnpj)')
        .eq('status', 'paid'); // Se tá pago, cai pro designer na coluna "Novos Pilotos"
    if (!pilotError && pilotData) allPilotRequests.value = pilotData;

    await fetchRejectionCounts();

  } catch (error) { console.error("Erro fetch kanban:", error); } finally { loading.value = false; }
};

// --- PERMISSION CHECKS & TEAM HELPERS ---
const currentUserPerms = ref({ is_leader: false, requires_leader_approval: false, can_approve_for_leader: false });
const isLeaderOrRightHand = computed(() => currentUserPerms.value.is_leader || currentUserPerms.value.can_approve_for_leader);
const requiresApproval = computed(() => currentUserPerms.value.requires_leader_approval);

const fetchUserPerms = async () => {
    if (!userStore.profile?.id) return;
    const { data } = await supabase.from('design_user_permissions').select('*').eq('user_id', userStore.profile.id).maybeSingle();
    if (data) currentUserPerms.value = data;
};

const designTeamMembers = computed(() => teamPermissions.value.filter(p => p.profile));
const availableProfilesToAdd = computed(() => allProfiles.value.filter(p => !teamPermissions.value.some(tm => tm.user_id === p.id)));

const getInitials = (name: string) => {
    if (!name || name === 'Sem Dono' || name === 'Livre') return '--';
    const parts = name.trim().split(' ');
    if (parts.length > 1) return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
    return name.substring(0, 2).toUpperCase();
};

const getDesignerName = (id: string | null | undefined) => {
    if (!id) return '';
    const member = teamPermissions.value.find(p => p.user_id === id);
    return member?.profile?.full_name || 'Desconhecido';
};

const getRelativeTime = (dateStr: string) => { if (!dateStr) return ''; try { return fDistance(parseISO(dateStr), { addSuffix: true, locale: ptBR }); } catch { return ''; } };
const formatDateFull = (dateStr: string) => { if (!dateStr) return ''; return format(parseISO(dateStr), "dd/MM/yyyy HH:mm", { locale: ptBR }); };

// --- IMAGENS E MODAL ---
const openImageModal = (url: string | undefined, name: string = '') => {
    if (!url) return;
    selectedImageUrl.value = url;
    selectedImageName.value = name;
    showImageModal.value = true;
};

const openPilotModal = (item: any) => {
    pilotDetailModal.item = item;
    pilotDetailModal.show = true;
};

// --- COMPUTED DATA E VIP STOREFRONT ---
const isStorefrontItem = (item: KanbanCard) => {
    return item.type === 'development' && item.original?.general_notes?.includes('Marketplace');
};

const getStorefrontBriefing = (item: KanbanCard) => {
    try {
        if (item.original.design_items && item.original.design_items.length > 0) {
            return item.original.design_items[0].notes || 'Briefing anexado pelo cliente.';
        }
    } catch(e) {}
    return 'Briefing anexado pelo cliente.';
};

const baseKanbanCards = computed((): KanbanCard[] => {
  const orderCards: KanbanCard[] = allOrders.value.flatMap(order =>
    order.order_items.map(item => ({
      id: item.id, type: 'order', status: item.status, design_tag: item.design_tag || 'Desenvolvimento',
      designer_id: order.designer_id,
      customer_name: order.customer_name, stamp_ref: item.stamp_ref, fabric_type: item.fabric_type, quantity_meters: item.quantity_meters,
      original: { ...item, order: order, created_at: item.created_at || order.created_at }
    }))
  );

  const devCards: KanbanCard[] = allDevRequests.value.map(req => {
    let parsed = [];
    try { parsed = typeof req.design_items === 'string' ? JSON.parse(req.design_items) : (Array.isArray(req.design_items) ? req.design_items : []); } catch {}

    let currentTag = req.design_tag;
    if ((!currentTag || currentTag === 'Desenvolvimento') && req.request_type === 'alteration') currentTag = 'Alteração';
    else if ((!currentTag || currentTag === 'Desenvolvimento') && req.request_type === 'pilot') currentTag = 'Pilotos';
    else if (!currentTag) currentTag = 'Desenvolvimento';

    const typeStr = req.request_type === 'pilot' ? 'pilot_internal' : 'development';

    return {
      id: req.id, type: typeStr, status: req.status, design_tag: currentTag,
      designer_id: req.designer_id,
      customer_name: parsed.map((di: any) => di.customer_name).join(', '),
      quantity_meters: parsed.reduce((sum: number, di: any) => sum + (Number(di.quantity_meters) || 0), 0),
      original: { ...req, design_items: parsed }
    };
  });

  // MALANDRAGEM: Mapeando os pilotos vindos do SITE
  const pilotCards: KanbanCard[] = allPilotRequests.value.map(pilot => {
      const customerName = pilot.customer_mj?.nome || pilot.customer_mj?.razao_social || publicLeadsMap.value.get(pilot.user_id) || 'Cliente Piloto';

      // O LEÃO DE CHÁCARA: Intercepta a tag que vem do banco e amassa ela!
      let tagSegura = pilot.design_tag;
      if (!tagSegura || tagSegura === 'Desenvolvimento') {
          tagSegura = 'Pilotos';
      }

      return {
          id: pilot.id,
          type: 'pilot',
          status: pilot.status,
          design_tag: tagSegura,
          designer_id: pilot.designer_id,
          customer_name: customerName,
          stamp_ref: pilot.stamp?.ref_code || 'CUSTOM',
          fabric_type: pilot.fabric?.name || '-',
          quantity_meters: pilot.quantity_meters,
          original: pilot
      };
  });

  return [...orderCards, ...devCards, ...pilotCards];
});

const searchedItems = computed(() => {
    if (!searchQuery.value) return baseKanbanCards.value;
    const q = searchQuery.value.toLowerCase();
    return baseKanbanCards.value.filter(c =>
        c.customer_name?.toLowerCase().includes(q) ||
        (c.type === 'order' && (String(c.original.order.order_number).includes(q) || c.stamp_ref?.toLowerCase().includes(q))) ||
        (c.type === 'development' && c.original.dev_code?.toLowerCase().includes(q)) ||
        (c.type === 'pilot_internal' && c.original.dev_code?.toLowerCase().includes(q)) ||
        (c.type === 'pilot' && String(c.original.id).toLowerCase().includes(q))
    );
});

const oneDayAgo = addDays(new Date(), -1);
const isItemDelayed = (item: KanbanCard) => { if (item.status === 'customer_approval' || item.status === 'approved_by_seller' || item.status === 'completed' || item.status === 'approved_by_designer' || item.type === 'pilot' || item.type === 'pilot_internal') return false; return parseISO(item.original.created_at) < oneDayAgo; };
const setColumnSort = (colId: string, sortKey: string) => { columnSorts[colId] = sortKey; };

const sortItems = (items: KanbanCard[], colId: string) => {
    let res = items.filter(i => searchedItems.value.some(s => s.id === i.id));
    if (filterDelayed.value) res = res.filter(isItemDelayed);

    if (!isLeaderOrRightHand.value && colId !== 'col-app') {
        res = res.filter(i => !i.designer_id || i.designer_id === userStore.profile?.id);
    }

    const sortType = columnSorts[colId] || 'created_at_desc';
    res.sort((a, b) => {
        if (sortType === 'customer_name') return (a.customer_name || '').localeCompare(b.customer_name || '');
        if (sortType === 'quantity') return (b.quantity_meters || 0) - (a.quantity_meters || 0);
        if (sortType === 'created_at_asc') return new Date(a.original.created_at).getTime() - new Date(b.original.created_at).getTime();
        return new Date(b.original.created_at).getTime() - new Date(a.original.created_at).getTime();
    });
    return res;
};

const getDarkClass = (lightClass: string) => {
    if (!lightClass) return 'bg-surface-card';
    if (lightClass.includes('purple')) return 'bg-purple-darken-4-alpha';
    if (lightClass.includes('orange')) return 'bg-orange-darken-4-alpha';
    if (lightClass.includes('blue')) return 'bg-blue-darken-4-alpha';
    if (lightClass.includes('green')) return 'bg-green-darken-4-alpha';
    if (lightClass.includes('teal')) return 'bg-teal-darken-4-alpha';
    if (lightClass.includes('red')) return 'bg-red-darken-4-alpha';
    return 'bg-surface-card';
};

const columns = computed(() => {
    let cols: any[] = [];

    // 1. COLUNA AUTOMÁTICA DE PILOTOS (Fixa no começo)
    const pilotItems = sortItems(baseKanbanCards.value.filter(i =>
       (i.type === 'pilot' && i.status === 'paid' && (!i.design_tag || i.design_tag === 'Desenvolvimento' || i.design_tag === 'Pilotos')) ||
       (i.type === 'pilot_internal' && (i.status === 'design_pending' || i.status === 'in_design' || i.status === 'finalizing') && (!i.design_tag || i.design_tag === 'Pilotos'))
    ), 'col-pilots');

    cols.push({
        id: 'col-pilots',
        title: 'Novos Pilotos',
        tag_name: 'Pilotos',
        bgClass: isLightMode.value ? 'bg-indigo-lighten-5' : 'bg-indigo-darken-4-alpha',
        dotColor: 'bg-indigo',
        chipColor: 'indigo',
        accentColor: '#3F51B5',
        order_index: -1,
        items: pilotItems,
        meters: sumMeters(pilotItems)
    });

    // 2. FAZ O LOOP DAS COLUNAS DINÂMICAS
    dynamicColumnsConfig.value.forEach(config => {
        let canView = true;
        if (config.tag_name === 'Aprovação Líder') canView = isLeaderOrRightHand.value;

        if (canView) {
            // BLINDAGEM TOTAL NA HORA DE FILTRAR
            const items = sortItems(baseKanbanCards.value.filter(i =>
                (i.status === 'design_pending' || i.status === 'in_design' || i.status === 'finalizing' || (i.type === 'pilot' && i.status === 'paid'))
                && (i.design_tag || 'Desenvolvimento') === config.tag_name
                && !(i.type === 'pilot' && config.tag_name === 'Desenvolvimento') // <-- TRAVA DE SEGURANÇA PRO PILOTO EXTERNO NÃO INVADIR O DESENVOLVIMENTO
                && !(i.type === 'pilot_internal' && config.tag_name === 'Desenvolvimento') // <-- TRAVA DE SEGURANÇA PRO PILOTO INTERNO NÃO INVADIR O DESENVOLVIMENTO
            ), config.id);

            cols.push({
                id: config.id,
                title: config.title,
                tag_name: config.tag_name,
                bgClass: isLightMode.value ? config.bg_class : getDarkClass(config.bg_class),
                dotColor: config.dot_color,
                chipColor: config.chip_color,
                accentColor: config.accent_color,
                order_index: config.order_index,
                items: items,
                meters: sumMeters(items)
            });
        }
    });

    cols.sort((a, b) => a.order_index - b.order_index);

    // O filtro final de Aprovados só mostra Orders
    const app = sortItems(baseKanbanCards.value.filter(i =>
        i.type === 'order' &&
        ((i.status === 'design_pending' && i.design_tag === 'Aprovado') ||
          i.status === 'customer_approval' ||
          i.status === 'approved_by_seller')
    ), 'col-app');

    cols.push({
        id: 'col-app',
        title: 'Aprovados / Finalizados',
        tag_name: 'Aprovado',
        bgClass: isLightMode.value ? 'bg-green-lighten-5' : 'bg-green-darken-4-alpha',
        dotColor: 'bg-success',
        chipColor: 'success',
        accentColor: '#66BB6A',
        items: app,
        meters: sumMeters(app)
    });

    return cols;
});

const activeKpis = computed(() => selectedKpiIds.value.map(id => {
    const conf = kpiOptions.find(o => o.value === id) || kpiOptions[0];

    // O pulo do gato: extrair apenas os cards que realmente passaram pelos filtros
    // das colunas (permissão, status e tags)
    const allVisibleItems = columns.value.flatMap(c => c.items);

    let items: KanbanCard[] = [];

    if (id === 'total') {
        items = allVisibleItems;
    }
    else if (id === 'delayed') {
        items = allVisibleItems.filter(isItemDelayed);
    }
    else if (id === 'development') {
        items = allVisibleItems.filter(i => i.design_tag === 'Desenvolvimento');
    }
    else if (id === 'approved') {
        items = columns.value.find(c => c.id === 'col-app')?.items || [];
    }

    return { ...conf, id, count: items.length, meters: sumMeters(items) };
}));

const sumMeters = (items: KanbanCard[]) => items.reduce((acc, i) => acc + (i.quantity_meters || 0), 0);
const formatNumber = (n: number) => n.toLocaleString('pt-BR');

// --- AÇÕES DO FLUXO (DRAG E ATRIBUIÇÃO) ---
const onCardMoved = async (evt: any, targetColumn: any) => {
    if (companyStore.isDemoMode) return appStore.showSnackbar('Ação não permitida no Modo Demo.', 'warning');
    if (evt.added) {
        const itemMoved = evt.added.element;
        try {
            if (itemMoved.type === 'order') await supabase.from('order_items').update({ design_tag: targetColumn.tag_name }).eq('id', itemMoved.id);
            else if (itemMoved.type === 'pilot') await supabase.from('pilot_requests').update({ design_tag: targetColumn.tag_name }).eq('id', itemMoved.id);
            else await supabase.from('design_requests').update({ design_tag: targetColumn.tag_name }).eq('id', itemMoved.id);
        } catch (error) { console.error('Erro ao mover card', error); }
    }
};

const assignCard = async (item: KanbanCard, designerId: string | null) => {
    if (companyStore.isDemoMode) return appStore.showSnackbar('Ação não permitida no Modo Demo.', 'warning');

    if (designerId === userStore.profile?.id && !isLeaderOrRightHand.value) {
        try {
            const payload = {
                item_id: item.id,
                order_id: item.type === 'order' ? item.original.order_id : null,
                item_type: item.type,
                item_name: item.type === 'order' ? `OP #${item.original.order.order_number} - ${item.stamp_ref}` : (item.type === 'pilot' ? `Piloto #${item.original.id.substring(0,6)}` : item.original.dev_code),
                designer_id: designerId
            };
            await supabase.from('design_assignment_requests').insert(payload);
            appStore.showSnackbar('Solicitação enviada ao líder! Aguarde aprovação.', 'info');
        } catch (e) {
            console.error(e);
            appStore.showSnackbar('Erro ao enviar solicitação.', 'error');
        }
        return;
    }

    try {
        if (item.type === 'order') {
            await supabase.from('orders').update({ designer_id: designerId }).eq('id', item.original.order_id);
        } else if (item.type === 'pilot') {
            await supabase.from('pilot_requests').update({ designer_id: designerId }).eq('id', item.id);
        } else {
            await supabase.from('design_requests').update({ designer_id: designerId }).eq('id', item.id);
        }
        item.designer_id = designerId;
        appStore.showSnackbar('Responsável atualizado com sucesso.', 'success');
        setTimeout(fetchAllData, 500);
    } catch (e: any) {
        console.error(e);
        appStore.showSnackbar('Erro ao atribuir card.', 'error');
    }
};

const approveAssignment = async (req: any) => {
    if (companyStore.isDemoMode) return appStore.showSnackbar('Ação não permitida no Modo Demo.', 'warning');
    try {
        if (req.item_type === 'order') {
            await supabase.from('orders').update({ designer_id: req.designer_id }).eq('id', req.order_id);
        } else if (req.item_type === 'pilot') {
            await supabase.from('pilot_requests').update({ designer_id: req.designer_id }).eq('id', req.item_id);
        } else {
            await supabase.from('design_requests').update({ designer_id: req.designer_id }).eq('id', req.item_id);
        }
        await supabase.from('design_assignment_requests').update({ status: 'approved' }).eq('id', req.id);
        await supabase.from('design_assignment_requests').update({ status: 'rejected' }).eq('item_id', req.item_id).eq('status', 'pending');

        appStore.showSnackbar('Solicitação aprovada e card atribuído!', 'success');
        assignmentRequests.value = assignmentRequests.value.filter(r => r.id !== req.id);
        fetchAllData();
    } catch (e) {
        appStore.showSnackbar('Erro ao aprovar solicitação.', 'error');
    }
};

const rejectAssignment = async (req: any) => {
    if (companyStore.isDemoMode) return appStore.showSnackbar('Ação não permitida no Modo Demo.', 'warning');
    try {
        await supabase.from('design_assignment_requests').update({ status: 'rejected' }).eq('id', req.id);
        assignmentRequests.value = assignmentRequests.value.filter(r => r.id !== req.id);
        appStore.showSnackbar('Solicitação recusada.', 'success');
    } catch (e) {
        appStore.showSnackbar('Erro ao recusar solicitação.', 'error');
    }
};

const openRejectModal = (item: any) => {
    rejectModal.item = item;
    rejectModal.reason = '';
    rejectModal.show = true;
};

const confirmRejection = async () => {
    if (companyStore.isDemoMode) return appStore.showSnackbar('Ação não permitida no Modo Demo.', 'warning');
    if (!rejectModal.item || !rejectModal.reason.trim()) return;
    rejectModal.loading = true;
    try {
        const item = rejectModal.item;
        let imageUrl = '/placeholder.png';
        if (item.type === 'order') imageUrl = item.original.stamp_image_url;
        else if (item.type === 'pilot') imageUrl = item.original.custom_stamp_url || item.original.stamp?.main_image_url;
        else imageUrl = item.original.design_items?.[0]?.stamp_image_url;

        await supabase.from('design_rejection_logs').insert({
            item_id: item.id,
            item_type: item.type,
            leader_id: userStore.profile?.id,
            reason: rejectModal.reason,
            rejected_image_url: imageUrl
        });

        const tagAlteracao = 'Alteração';
        if (item.type === 'order') {
            await supabase.from('order_items').update({ design_tag: tagAlteracao }).eq('id', item.id);
        } else if (item.type === 'pilot') {
            await supabase.from('pilot_requests').update({ design_tag: tagAlteracao }).eq('id', item.id);
        } else {
            await supabase.from('design_requests').update({ design_tag: tagAlteracao }).eq('id', item.id);
        }

        appStore.showSnackbar('Arte rejeitada e devolvida para correção.', 'warning');
        rejectModal.show = false;
        fetchAllData();
    } catch (e: any) {
        console.error(e);
        appStore.showSnackbar('Erro ao rejeitar arte.', 'error');
    } finally {
        rejectModal.loading = false;
    }
};

const openRejectionHistory = async (item: any) => {
    rejectionHistoryModal.item = item;
    rejectionHistoryModal.show = true;

    if (companyStore.isDemoMode) {
        rejectionHistoryModal.logs = [
            { id: 'fake-log', leader: { full_name: 'Líder Demo' }, created_at: new Date().toISOString(), reason: 'As cores não estão de acordo com o manual da marca.' }
        ];
        return;
    }

    rejectionHistoryModal.loading = true;
    try {
        const { data, error } = await supabase
            .from('design_rejection_logs')
            .select('*, leader:profiles!leader_id(full_name)')
            .eq('item_id', item.id)
            .order('created_at', { ascending: false });
        if (error) throw error;
        rejectionHistoryModal.logs = data || [];
    } catch (e) {
        console.error(e);
        appStore.showSnackbar('Erro ao buscar histórico.', 'error');
    } finally {
        rejectionHistoryModal.loading = false;
    }
};


// --- UPLOAD EXCLUSIVO VIP E PILOTO SITE ---
const handleVipDelivery = async (fileUrl: string) => {
    if (companyStore.isDemoMode) return appStore.showSnackbar('Ação não permitida no Modo Demo.', 'warning');
    if (!selectedDevRequest.value) return;

    try {
        appStore.showSnackbar('Anexando e entregando ao cliente...', 'info');

        // Move o card para finalizado no Kanban
        await supabase.from('design_requests').update({
            status: 'approved_by_designer',
            final_art_url: fileUrl,
            designer_id: userStore.profile?.id,
            design_tag: 'Aprovado'
        }).eq('id', selectedDevRequest.value.id);

        // Insere a arte direto no cofre do cliente, calculando validade
        const customerId = selectedDevRequest.value.design_items?.[0]?.customer_id;
        let clientEmail = '';

        if (customerId) {
            const { data: lead } = await supabase.from('public_leads').select('email').eq('id', customerId).maybeSingle();
            if (lead) clientEmail = lead.email;
        }

        if (clientEmail) {
            const expiresDate = new Date();
            expiresDate.setHours(expiresDate.getHours() + 24);

            await supabase.from('client_design_deliveries').insert([{
                client_email: clientEmail,
                design_request_id: selectedDevRequest.value.dev_code,
                file_url: fileUrl,
                expires_at: expiresDate.toISOString()
            }]);
            appStore.showSnackbar('Arte entregue no Cofre VIP do cliente! Ela irá sumir em 24h.', 'success');
        } else {
            appStore.showSnackbar('Aviso: Arte aprovada, mas o e-mail do cliente não foi encontrado para envio ao Cofre.', 'warning');
        }

        showVipDetailModal.value = false;
        fetchAllData();
    } catch (e: any) {
        appStore.showSnackbar('Erro ao entregar arte VIP: ' + e.message, 'error');
    }
};

// MALANDRAGEM: Conclusão Direta do Piloto de Site
const concludePilot = async (item: KanbanCard) => {
    if (companyStore.isDemoMode) return appStore.showSnackbar('Ação não permitida no Modo Demo.', 'warning');

    try {
        await supabase.from('pilot_requests').update({
            design_tag: 'Aprovado',
            status: 'in_production', // Manda direto pra estamparia!
            designer_id: userStore.profile?.id
        }).eq('id', item.id);

        appStore.showSnackbar('Piloto concluído e enviado direto para Produção da Vendedora!', 'success');
        pilotDetailModal.show = false;
        fetchAllData();
    } catch (e: any) {
        appStore.showSnackbar('Erro ao aprovar piloto: ' + e.message, 'error');
    }
};


// --- FLUXO DE UPLOAD E APROVAÇÃO NORMAL (VENDEDOR/ERP) ---
const openModalForItem = (item: KanbanCard) => {
  if (item.type === 'order') {
    selectedOrderId.value = item.original.order_id;
    selectedItemId.value = item.id;
    showLaunchModal.value = true;
  } else if (item.type === 'pilot') {
    openPilotModal(item);
  } else if (isStorefrontItem(item)) {
    selectedDevRequest.value = item.original;
    showVipDetailModal.value = true;
  } else {
    // Both 'development' and 'pilot_internal' can reuse DevelopmentDetailModal
    selectedDevRequest.value = item.original;
    showDevDetailModal.value = true;
  }
};

const openUploadModal = (item: any, destination: 'customer' | 'leader' = 'customer', itemType: string = 'order') => {
    selectedItem.value = { ...item, _type: itemType };
    selectedOrder.value = allOrders.value.find(o => o.id === item.order_id) || null;
    uploadDestination.value = destination;

    if (destination === 'leader') {
        uploadModalTitle.value = `Enviar para Avaliação do Líder`;
    } else {
        uploadModalTitle.value = `Enviar Arte para "${item.stamp_ref || item.dev_code || item.id?.substring(0,8)}"`;
    }

    showUploadModal.value = true;
};

const handleUploadSuccess = async (fileUrl: string) => {
    if (companyStore.isDemoMode) return appStore.showSnackbar('Ação não permitida no Modo Demo.', 'warning');
    if (!selectedItem.value) return;

    try {
        if (uploadDestination.value === 'leader') {
            const tagLider = 'Aprovação Líder';
            if (selectedItem.value._type === 'order') {
                await supabase.from('order_items').update({ design_tag: tagLider, stamp_image_url: fileUrl }).eq('id', selectedItem.value.id);
            } else if (selectedItem.value._type === 'pilot') {
                await supabase.from('pilot_requests').update({ design_tag: tagLider, custom_stamp_url: fileUrl }).eq('id', selectedItem.value.id);
            } else {
                // Covers development and pilot_internal
                await supabase.from('design_requests').update({ design_tag: tagLider, final_art_url: fileUrl }).eq('id', selectedItem.value.id);
            }
            appStore.showSnackbar('Arte anexada e enviada para o líder!', 'success');

        } else {
            // FLUXO DE CONCLUSÃO DA ORDER OU DEV
            if (selectedItem.value._type === 'pilot') {
                await supabase.from('pilot_requests').update({
                    design_tag: 'Aprovado',
                    custom_stamp_url: fileUrl,
                    status: 'in_production', // O Piloto de Site vai reto pra estamparia!
                    designer_id: userStore.profile?.id
                }).eq('id', selectedItem.value.id);
                appStore.showSnackbar('Piloto aprovado e enviado direto para Produção!', 'success');

            } else if (selectedItem.value._type === 'order') {
                await supabase.from('orders').update({ designer_id: userStore.profile?.id }).eq('id', selectedItem.value.order_id);
                await supabase.rpc('update_order_item_status', {
                    p_item_id: selectedItem.value.id,
                    p_new_status: 'customer_approval',
                    p_final_art_url: fileUrl,
                    p_profile_id: userStore.profile?.id
                });
                await supabase.rpc('notify_seller_for_approval', {
                    p_item_id: selectedItem.value.id,
                    p_sender_id: userStore.profile?.id
                });
                appStore.showSnackbar('Arte enviada para aprovação do vendedor/cliente!', 'success');

            } else {
                // Covers development and pilot_internal
                await supabase.from('design_requests').update({
                    status: 'pending_approval', // Vai para approvals.vue
                    final_art_url: fileUrl,
                    designer_id: userStore.profile?.id,
                    design_tag: 'Aprovado'
                }).eq('id', selectedItem.value.id);
                appStore.showSnackbar('Arte enviada para aprovação do solicitante!', 'success');
            }
        }
    } catch (e: any) {
        appStore.showSnackbar('Erro ao processar envio: ' + e.message, 'error');
    }

    showUploadModal.value = false;
    fetchAllData();
};

const saveNewColumn = async () => {
    if (companyStore.isDemoMode) return appStore.showSnackbar('Ação não permitida no Modo Demo.', 'warning');
    if (!newColumn.title || !newColumn.tag_name) return alert("Preencha Título e Tag");
    const { error } = await supabase.from('design_kanban_columns').insert([newColumn]);
    if (!error) { fetchSystemConfigs(); newColumn.title = ''; newColumn.tag_name = ''; }
    else alert("Erro ao criar coluna: " + error.message);
};
const deleteColumn = async (id: string) => {
    if (companyStore.isDemoMode) return appStore.showSnackbar('Ação não permitida no Modo Demo.', 'warning');
    if(!confirm("Tem certeza que deseja deletar essa coluna? Os cards voltarão para o limbo (sem tag visível).")) return;
    await supabase.from('design_kanban_columns').delete().eq('id', id);
    fetchSystemConfigs();
};
const updateColumnVisibility = async (col: ColumnConfig) => {
    if (companyStore.isDemoMode) return appStore.showSnackbar('Ação não permitida no Modo Demo.', 'warning');
    await supabase.from('design_kanban_columns').update({ available_in_new_order: col.available_in_new_order }).eq('id', col.id);
};

const addMemberToTeam = async (userId: string | null) => {
    if (companyStore.isDemoMode) return appStore.showSnackbar('Ação não permitida no Modo Demo.', 'warning');
    if (!userId) return;
    try {
        await supabase.from('design_user_permissions').upsert({ user_id: userId, is_leader: false, requires_leader_approval: true, can_approve_for_leader: false }, { onConflict: 'user_id' });
        newUserToTeam.value = null;
        await fetchSystemConfigs();
        appStore.showSnackbar('Colaborador adicionado à equipe!', 'success');
    } catch(e: any) { appStore.showSnackbar(e.message, 'error'); }
};

const removeMemberFromTeam = async (userId: string) => {
    if (companyStore.isDemoMode) return appStore.showSnackbar('Ação não permitida no Modo Demo.', 'warning');
    if(!confirm('Deseja realmente remover este usuário da equipe de design?')) return;
    await supabase.from('design_user_permissions').delete().eq('user_id', userId);
    await fetchSystemConfigs();
};

const updateUserPermission = async (user: UserPermission) => {
    if (companyStore.isDemoMode) return appStore.showSnackbar('Ação não permitida no Modo Demo.', 'warning');
    await supabase.from('design_user_permissions').upsert({
        user_id: user.user_id,
        is_leader: user.is_leader,
        requires_leader_approval: user.requires_leader_approval,
        can_approve_for_leader: user.can_approve_for_leader
    }, { onConflict: 'user_id' });
};

// --- HISTORY ---
const fetchReleasedItemsHistory = async () => {
    loadingHistory.value = true;

    if (companyStore.isDemoMode) {
        releasedItemsHistory.value = [
            { id: 'hist-1', status: 'in_production', order_id: 'fake-order-1', stamp_ref: 'EST-ANTIGA-01', fabric_type: 'Dry Fit', quantity_meters: 1200, updated_at: new Date().toISOString(), order: { customer_name: 'Moda Praia Tropical', order_number: 15410, creator: { full_name: 'Carlos Vendas' } } }
        ] as any[];
        loadingHistory.value = false;
        return;
    }

    if (!userStore.profile?.id) return;
    try {
        const productionStatuses = ['design_released', 'waiting_separation', 'in_separation', 'waiting_print', 'printing', 'printed', 'waiting_calandra', 'in_calandra', 'in_production', 'billing_pending', 'waiting_release', 'ready_for_delivery', 'completed', 'delivered', 'production_queue', 'in_cutting'];
        const { data, error } = await supabase.from('order_items')
            .select(`id, status, design_tag, order_id, unit_of_measure, quantity_unit, is_op_generated, stamp_image_url, quantity_meters, stamp_ref, fabric_type, created_at, updated_at, order:orders!inner (id, customer_name, created_at, order_number, designer_id, creator:created_by(full_name))`)
            .eq('order.designer_id', userStore.profile.id).in('status', productionStatuses).order('updated_at', { ascending: false }).limit(3000);
        if (error) throw error;
        releasedItemsHistory.value = data?.map(d => ({ ...d, scheduled_at: d.updated_at || d.created_at })) as any[];
    } catch(err) { console.error("History error:", err); releasedItemsHistory.value = []; } finally { loadingHistory.value = false; }
}

const filteredHistory = computed(() => {
    if (!historySearch.value) return releasedItemsHistory.value;
    const q = historySearch.value.toLowerCase();
    return releasedItemsHistory.value.filter(i => i.order?.customer_name.toLowerCase().includes(q) || String(i.order?.order_number).includes(q) || i.stamp_ref?.toLowerCase().includes(q));
});
const historyPageCount = computed(() => Math.ceil(filteredHistory.value.length / historyItemsPerPage));
const paginatedHistoryItems = computed(() => { const start = (historyPage.value - 1) * historyItemsPerPage; return filteredHistory.value.slice(start, start + historyItemsPerPage); });
const historyTotalMeters = computed(() => filteredHistory.value.reduce((acc, i) => acc + (i.quantity_meters || 0), 0).toLocaleString('pt-BR'));

const openHistoryModal = () => { fetchReleasedItemsHistory(); showHistoryModal.value = true; };
const formatDateSimple = (d: string) => d ? format(parseISO(d), 'dd/MM/yyyy') : '-';

// --- ACTIONS & MODALS ---
const closeLaunchModal = () => { showLaunchModal.value = false; selectedOrderId.value = null; selectedItemId.value = null; };

const handleReleaseItem = async (item: OrderItem) => {
    if (companyStore.isDemoMode) return appStore.showSnackbar('Ação não permitida no Modo Demo.', 'warning');
    if (item.status !== 'approved_by_seller') { alert("O item precisa estar APROVADO PELO VENDEDOR (após cliente) para ser enviado ao PCP."); return; }
    if (!item.is_op_generated) { alert("É OBRIGATÓRIO gerar/imprimir a OP antes de enviar este item para o PCP."); return; }
    try {
        await supabase.from('orders').update({ designer_id: userStore.profile?.id }).eq('id', item.order_id);
        const { error } = await supabase.rpc('schedule_item_for_production', { p_item_id: item.id, p_profile_id: userStore.profile?.id });
        if (error) throw error;
        fetchAllData();
        if (selectedOrderId.value) closeLaunchModal();
        alert("Item enviado para a fila de produção com sucesso!");
    } catch(err: any) { console.error("Erro Release:", err); alert(`Erro ao liberar item: ${err.message}`); }
};

// --- PDF GEN ---
const addBusinessDays = (startDate: Date, days: number): Date => {
  const newDate = new Date(startDate); let addedDays = 0;
  while (addedDays < days) { newDate.setDate(newDate.getDate() + 1); if (newDate.getDay() !== 0) addedDays++; } return newDate;
};
const getNextDeliveryDay = (date: Date): Date => {
    const newDate = new Date(date); newDate.setDate(newDate.getDate() + 1);
    while (true) { const dayOfWeek = newDate.getDay(); if ([2, 4, 6].includes(dayOfWeek)) return newDate; newDate.setDate(newDate.getDate() + 1); }
};
const imageToBase64 = (url: string): Promise<string> => {
    return new Promise((resolve, reject) => {
        const img = new Image(); img.crossOrigin = 'Anonymous';
        img.onload = () => { const canvas = document.createElement('canvas'); canvas.width = img.width; canvas.height = img.height; const ctx = canvas.getContext('2d'); if(ctx){ ctx.drawImage(img, 0, 0); resolve(canvas.toDataURL('image/png')); } else reject(); };
        img.onerror = reject; img.src = url;
    });
};

const generateOpPdf = async (item: any) => {
  if (companyStore.isDemoMode) return appStore.showSnackbar('PDF gerado (Simulação Demo)', 'success');
  isGeneratingPdf.value = true;
  try {
    const { data: opNumber, error: rpcError } = await supabase.rpc('generate_op_number', { p_item_id: item.id });
    if(rpcError) throw rpcError;

    const { data: schedule } = await supabase.from('production_schedule').select('scheduled_date').eq('order_item_id', item.id).maybeSingle();
    const scheduleDate = (schedule && schedule.scheduled_date) ? parseISO(schedule.scheduled_date) : new Date();

    const parentOrder = item.order || item.original?.order;
    const hasStockIssues = (parentOrder?.order_items || []).some((i: any) => i.has_insufficient_stock || i.status === 'pending_stock');
    const completionDate = addBusinessDays(scheduleDate, 3 + (hasStockIssues ? 2 : 0));
    const forecastDate = getNextDeliveryDay(completionDate);

    const formattedOpNumber = String(opNumber).padStart(4, '0');
    const formattedOrderNumber = String(parentOrder?.order_number || '0000').padStart(4, '0');
    const formattedForecastDate = format(forecastDate, 'dd/MM/yyyy', { locale: ptBR });

    const doc = new jsPDF();
    const [logoBase64, artBase64] = await Promise.all([
        imageToBase64('https://cdn.shopify.com/s/files/1/0661/4574/6991/files/Sem_nome_1080_x_800_px_1080_x_500_px_1080_x_400_px_1000_x_380_px_da020cf2-2bb9-4dac-8dd3-4548cfd2e5ae.png?v=1756811713'),
        imageToBase64(item.stamp_image_url || '')
    ]);

    const pageWidth = doc.internal.pageSize.width; const pageHeight = doc.internal.pageSize.height;

    const drawCommonHeader = () => {
        const logoProps = doc.getImageProperties(logoBase64);
        const logoWidth = 50; const logoHeight = (logoProps.height * logoWidth) / logoProps.width;
        doc.addImage(logoBase64, "PNG", 15, 12, logoWidth, logoHeight);
        doc.setFontSize(9).setTextColor(100);
        doc.text([ "MR JACKY - 20.631.721/0001-07", "RUA LUIZ MONTANHAN, 1302 TIRO DE GUERRA - TIETE - SP CEP: 18.532-000", "Fone/Celular: (15) 99847-8789 | E-mail: mrjackyfinanceiro@gmail.com" ], pageWidth - 15, 15, { align: "right" });
    };

    drawCommonHeader();
    doc.setFontSize(10).setFont('helvetica', 'bold').setTextColor(0, 0, 0); doc.text("VIA DA PRODUÇÃO", pageWidth / 2, 40, { align: "center" });
    doc.setFontSize(18).setTextColor(0); doc.text(`OP #${formattedOpNumber}`, 15, 45);
    doc.setFontSize(12); doc.text(`Pedido #${formattedOrderNumber}`, pageWidth - 15, 45, { align: "right" });
    doc.setLineWidth(0.5).line(15, 50, pageWidth - 15, 50);

    autoTable(doc, {
        startY: 55, head: [["CLIENTE", "VENDEDOR", "EMISSÃO", "PREVISÃO DE ENTREGA"]],
        body: [[ parentOrder?.customer_name || 'N/A', parentOrder?.creator?.full_name || parentOrder?.creator_name || "N/A", format(new Date(parentOrder?.created_at || new Date()), "dd/MM/yyyy", { locale: ptBR }), formattedForecastDate ]],
        theme: "striped", headStyles: { fillColor: [41, 128, 185] },
    });

    autoTable(doc, {
        startY: (doc as any).lastAutoTable.finalY + 10, head: [["PRODUTO (BASE)", "SERVIÇO (ESTAMPA)", "QUANTIDADE"]],
        body: [[ item.fabric_type, item.stamp_ref, `${Number(item.quantity_meters).toLocaleString('pt-BR')}m` ]],
        theme: "grid", headStyles: { fillColor: [41, 128, 185] },
    });

    let currentY = (doc as any).lastAutoTable.finalY + 10;
    const notesContent = String(parentOrder?.notes || parentOrder?.details?.observation || "").trim();
    if (notesContent) {
        doc.setFillColor(255, 243, 224); doc.setDrawColor(255, 183, 77); doc.setLineWidth(0.3); doc.setFont("helvetica", "normal"); doc.setFontSize(8.5);
        const splitNotes = doc.splitTextToSize(notesContent, pageWidth - 34); const notesHeight = (splitNotes.length * 4) + 8;
        doc.rect(15, currentY, pageWidth - 30, notesHeight, "FD"); doc.setFont("helvetica", "bold"); doc.setTextColor(230, 81, 0); doc.text("OBSERVAÇÕES DO VENDEDOR / PEDIDO:", 17, currentY + 5);
        doc.setFont("helvetica", "normal"); doc.setTextColor(0); doc.text(splitNotes, 17, currentY + 10); currentY += notesHeight + 10;
    } else { currentY += 5; }

    const artStartY = currentY;
    doc.setFontSize(12).setFont("helvetica", "bold").setTextColor(0).text("ARTE APROVADA", 15, artStartY);
    doc.setFontSize(10).setFont('helvetica', 'normal').setTextColor(100).text(`Cliente: ${parentOrder?.customer_name || 'N/A'}`, 15, artStartY + 5);

    const artY = artStartY + 10; const maxImgWidth = pageWidth - 30; const maxImgHeight = pageHeight - artY - 25;
    const imgProps = doc.getImageProperties(artBase64);
    const ratio = Math.min( maxImgWidth / imgProps.width, maxImgHeight / imgProps.height );
    const imgWidth = imgProps.width * ratio; const imgHeight = imgProps.height * ratio; const imgXCentered = (pageWidth - imgWidth) / 2;

    doc.setDrawColor(180, 180, 180).setLineWidth(0.5).rect(imgXCentered - 1, artY - 1, imgWidth + 2, imgHeight + 2, "S");
    doc.addImage(artBase64, "PNG", imgXCentered, artY, imgWidth, imgHeight);
    doc.setFontSize(9).setTextColor(150).text("OP gerada com MJProcess", pageWidth / 2, pageHeight - 15, { align: "center" });

    // VIA 2: ARQUIVO
    doc.addPage(); drawCommonHeader();
    doc.setFontSize(18).setTextColor(0); doc.text(`OP #${formattedOpNumber}`, 15, 45);
    doc.setFontSize(10).setFont('helvetica', 'bold').setTextColor(150, 0, 0); doc.text("VIA PARA ARQUIVAMENTO", pageWidth / 2, 40, { align: "center" });
    doc.setTextColor(0); doc.setFontSize(12); doc.text(`Pedido #${formattedOrderNumber}`, pageWidth - 15, 45, { align: "right" });
    doc.setLineWidth(0.5).line(15, 50, pageWidth - 15, 50);

    autoTable(doc, { startY: 55, theme: "grid", headStyles: { fillColor: [41, 128, 185] }, head: [['CLIENTE', 'REFERÊNCIA (ESTAMPA)', 'PRODUTO (BASE)']], body: [[parentOrder?.customer_name || 'N/A', item.stamp_ref, item.fabric_type]], });
    let currentY2 = (doc as any).lastAutoTable.finalY + 10;

    if (notesContent) {
        doc.setFillColor(255, 243, 224); doc.setDrawColor(255, 183, 77); doc.setLineWidth(0.3); doc.setFont("helvetica", "normal"); doc.setFontSize(8.5);
        const splitNotes = doc.splitTextToSize(notesContent, pageWidth - 34); const notesHeight = (splitNotes.length * 4) + 8;
        doc.rect(15, currentY2, pageWidth - 30, notesHeight, "FD"); doc.setFont("helvetica", "bold"); doc.setTextColor(230, 81, 0); doc.text("OBSERVAÇÕES DO VENDEDOR / PEDIDO:", 17, currentY2 + 5);
        doc.setFont("helvetica", "normal"); doc.setTextColor(0); doc.text(splitNotes, 17, currentY2 + 10); currentY2 += notesHeight + 10;
    } else { currentY2 += 5; }

    const artStartY2 = currentY2;
    doc.setFontSize(12).setFont("helvetica", "bold").setTextColor(0).text("ARTE APROVADA", 15, artStartY2);
    doc.setDrawColor(180, 180, 180).setLineWidth(0.5).rect(imgXCentered - 1, artStartY2 + 5 - 1, imgWidth + 2, imgHeight + 2, "S");
    doc.addImage(artBase64, "PNG", imgXCentered, artStartY2 + 5, imgWidth, imgHeight);
    doc.setFontSize(9).setTextColor(150).text("OP gerada com MJProcess", pageWidth / 2, pageHeight - 15, { align: "center" });

    doc.save(`OP-${formattedOpNumber}.pdf`);

    if(item.original) item.original.is_op_generated = true; else item.is_op_generated = true;
    await supabase.from('order_items').update({ is_op_generated: true }).eq('id', item.id);
    fetchAllData();

  } catch (error: any) { console.error("Erro PDF:", error); alert("Erro ao gerar PDF: " + error.message); } finally { isGeneratingPdf.value = false; }
};

const onCardMouseMove = (e: MouseEvent) => {};

// --- TUTORIAL ---
const toggleHints = () => { hintsEnabled.value = !hintsEnabled.value; localStorage.setItem('DesignKanbanHints', String(hintsEnabled.value)); if(hintsEnabled.value) startTutorial(); else tutorialStep.value = 0; };
const startTutorial = async () => {
    if(!hintsEnabled.value) return;
    await nextTick();
    setTimeout(() => {
        if(searchFieldRef.value) {
            tutorialStep.value = 1; const rect = (searchFieldRef.value as any).getBoundingClientRect();
            highlightStyle.value = { top: `${rect.top}px`, left: `${rect.left}px`, width: `${rect.width}px`, height: `${rect.height}px` };
            hintPosition.value = { top: `${rect.bottom + 10}px`, left: `${rect.left}px` };
            hintContent.text = 'Use a busca para filtrar rapidamente.'; hintContent.icon = 'mdi-magnify';
        }
    }, 1000);
};
const advanceTutorial = () => { tutorialStep.value = 0; };

onActivated(() => { fetchAllData(); const savedKpis = localStorage.getItem('DesignKanbanKpis'); if (savedKpis) selectedKpiIds.value = JSON.parse(savedKpis); });
onMounted(() => { fetchAllData(); const savedKpis = localStorage.getItem('DesignKanbanKpis'); if (savedKpis) selectedKpiIds.value = JSON.parse(savedKpis); startTutorial(); });
</script>

<style scoped lang="scss">
.design-layout {
  position: relative;
  width: 100%;
  height: calc(100vh - 64px);
  display: flex;
  flex-direction: column;
  overflow: hidden;
}
.content-wrapper { flex: 1 1 0; min-height: 0; display: flex; flex-direction: column; overflow: hidden; }
.background-carousel-wrapper { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 0; opacity: 0.6; pointer-events: none; }
.background-overlay { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 1; background: radial-gradient(circle at center, rgba(15, 15, 19, 0.4), rgba(15, 15, 19, 0.98)); backdrop-filter: blur(8px); }
.z-10 { position: relative; z-index: 10; }
.bg-glass-dark { background: rgba(10,10,12,0.85); }
.bg-glass-header { background: rgba(20,20,24,0.55); backdrop-filter: blur(14px); }
.border-bottom-white-05 { border-bottom: 1px solid rgba(255,255,255,0.08); }
.border-thin { border: 1px solid rgba(0,0,0,0.08); }
.bg-white-05 { background: rgba(255,255,255,0.05); }

/* Buttons & Inputs (3D EFFECTS) */
.btn-rect { border-radius: 0 !important; text-transform: none !important; font-weight: 800; }
.btn-3d { border-radius: 6px !important; box-shadow: 0 3px 5px rgba(0,0,0,0.15), inset 0 2px 0 rgba(255,255,255,0.25) !important; transition: transform 0.1s ease, box-shadow 0.1s ease; text-transform: none !important; }
.btn-3d:active { transform: translateY(2px); box-shadow: 0 1px 2px rgba(0,0,0,0.15), inset 0 1px 0 rgba(255,255,255,0.2) !important; }
.chip-3d { border-radius: 6px !important; box-shadow: 0 3px 5px rgba(0,0,0,0.12), inset 0 1px 0 rgba(255,255,255,0.25) !important; text-shadow: 0 1px 2px rgba(0,0,0,0.25); }

.clean-input { border: none; outline: none; background: transparent; font-size: 12px; color: inherit; }
.search-wrap { height: 40px; border-radius: 0; padding: 0 12px; min-width: 300px; flex: 1; }
.search-light { background: #f4f6f8; border: 1px solid rgba(0,0,0,0.08); }
.search-dark { background: rgba(255,255,255,0.08); border: 1px solid rgba(255,255,255,0.10); }
.controls-bar { border: 1px solid rgba(0,0,0,0.08); border-radius: 0; padding: 10px; }
.controls-light { background: #ffffff; }
.controls-dark { background: rgba(30,30,35,0.55); backdrop-filter: blur(16px); border: 1px solid rgba(255,255,255,0.08); }

/* KPI Cards */
.kpi-card { border: 1px solid rgba(0,0,0,0.08); color: white; min-height: 110px; position: relative; overflow: hidden; }
.kpi-rect { border-radius: 0 !important; }
.bg-gradient-info { background: linear-gradient(135deg, #0288d1, #005b9f); }
.bg-gradient-success { background: linear-gradient(135deg, #2e7d32, #1b5e20); }
.bg-gradient-warning { background: linear-gradient(135deg, #FFB300, #F57F17); }
.bg-gradient-purple { background: linear-gradient(135deg, #7b1fa2, #4a148c); }
.kpi-bg-icon { position: absolute; right: -20px; bottom: -20px; opacity: 0.15; transform: rotate(-15deg); pointer-events: none; z-index: 0; }
.kpi-bg-icon .v-icon { font-size: 100px; color: white; }
.kpi-label { font-size: 12px; font-weight: 900; letter-spacing: .2px; text-transform: uppercase; }
.kpi-value { font-size: 22px; font-weight: 900; letter-spacing: .2px; }
.kpi-footer { font-size: 11px; opacity: .9; font-weight: 700; }

/* KANBAN STRICT CONTAINERS */
.kanban-master-container { flex: 1 1 0; min-height: 0; display: flex; flex-direction: column; overflow: hidden; }
.kanban-board-card { flex: 1 1 0; min-height: 0; display: flex; flex-direction: column; overflow: hidden; }
.kanban-container { flex: 1 1 0; min-height: 0; display: flex; align-items: stretch; gap: 0; overflow-x: auto; overflow-y: hidden; }
.kanban-column { min-width: 320px; width: 320px; flex-shrink: 0; transition: all 0.2s ease; height: 100%; max-height: 100%; display: flex; flex-direction: column; min-height: 0; }
.column-header { flex-shrink: 0; }
.kanban-content { flex: 1 1 0; min-height: 0; overflow-y: auto; overflow-x: hidden; padding-bottom: 30px !important; }

/* STOREFRONT E PILOT CARDS STYLES */
.storefront-card { transition: transform 0.2s, box-shadow 0.2s, border-color 0.2s; border-color: rgba(245, 158, 11, 0.4) !important; cursor: pointer; }
.storefront-card:hover { transform: translateY(-2px); border-color: rgba(245, 158, 11, 0.8) !important; box-shadow: 0 8px 25px rgba(245, 158, 11, 0.2) !important; z-index: 2; }
.pilot-internal-card { transition: transform 0.2s, box-shadow 0.2s, border-color 0.2s; border-color: rgba(156, 39, 176, 0.4) !important; cursor: pointer; }
.pilot-internal-card:hover { transform: translateY(-2px); border-color: rgba(156, 39, 176, 0.8) !important; box-shadow: 0 8px 25px rgba(156, 39, 176, 0.2) !important; z-index: 2; }

.vip-bg-glow { position: absolute; top: -50%; right: -50%; width: 200%; height: 200%; background: radial-gradient(circle at center, rgba(245, 158, 11, 0.08) 0%, transparent 60%); pointer-events: none; }
.shadow-gold { box-shadow: 0 4px 12px rgba(245, 158, 11, 0.3) !important; }
.bg-warning-darken-4-alpha { background-color: rgba(245, 158, 11, 0.15) !important; }
.bg-black-20 { background-color: rgba(0, 0, 0, 0.2); }
.border-white-10 { border-color: rgba(255, 255, 255, 0.1) !important; }

.bg-indigo-darken-4-alpha { background-color: rgba(63, 81, 181, 0.15) !important; }
.bg-blue-darken-4-alpha { background: rgba(13, 71, 161, 0.2) !important; }
.bg-orange-darken-4-alpha { background: rgba(230, 81, 0, 0.2) !important; }
.bg-teal-darken-4-alpha { background: rgba(0, 77, 64, 0.2) !important; }
.bg-green-darken-4-alpha { background: rgba(27, 94, 32, 0.25) !important; }
.bg-purple-darken-4-alpha { background: rgba(74, 20, 140, 0.2) !important; }
.bg-red-darken-4-alpha { background: rgba(183, 28, 28, 0.2) !important; }
.status-dot { width: 8px; height: 8px; border-radius: 50%; display: inline-block; }
.pulsing-dot { animation: pulse-opacity 2s infinite; }
@keyframes pulse-opacity { 0%, 100% { opacity: 1; } 50% { opacity: 0.5; } }

/* Production Card Style */
.production-card { transition: transform 0.2s, box-shadow 0.2s; position: relative; cursor: pointer; }
.production-card:hover { transform: translateY(-2px); box-shadow: 0 4px 12px rgba(0,0,0,0.15) !important; z-index: 2; }
.pill-ref { font-size: 9px; font-weight: 900; font-family: monospace; background: rgba(0,0,0,0.08); padding: 2px 6px; border-radius: 4px; }
.cursor-grab { cursor: grab; }
.lh-1 { line-height: 1 !important; }
.animate-bounce { animation: bounce 1s infinite; }
@keyframes bounce { 0%, 100% { transform: translateY(0); } 50% { transform: translateY(-3px); } }

/* Grid / Table Styles (Excel-like) */
.history-modal .history-card { border-radius: 0; box-shadow: 0 12px 30px rgba(0,0,0,0.12); overflow: hidden; }
.grid-scroll { scrollbar-gutter: stable both-edges; }
.grid-header, .grid-row { display: flex; width: 100%; }
.cell { padding: 8px 10px; display: flex; align-items: center; border-right: 1px solid rgba(0,0,0,0.08); border-bottom: 1px solid rgba(0,0,0,0.08); min-height: 48px; overflow: hidden; }
.center { justify-content: center; text-align: center; }
.grid-header .cell { min-height: 40px; font-size: 11px; font-weight: 900; text-transform: uppercase; letter-spacing: .6px; }
.header-text { font-size: 11px; }
.grid-surface-light .cell { background: #f5f7fa; color: rgba(0,0,0,0.7); border-color: rgba(0,0,0,0.10); }
.grid-surface-dark .cell { background: rgba(255,255,255,0.08); color: rgba(255,255,255,0.80); border-color: rgba(255,255,255,0.10); }
.grid-row-light .cell { background: #fff; border-color: rgba(0,0,0,0.08); }
.zebra-light-a .cell { background: #ffffff; }
.zebra-light-b .cell { background: #f0f4f8; }
.grid-row-light:hover .cell { background: #e3f2fd; }

.grid-row-dark .cell { background: rgba(255,255,255,0.04); border-color: rgba(255,255,255,0.08); }
.zebra-dark-a .cell { background: rgba(255,255,255,0.04) !important; }
.zebra-dark-b .cell { background: rgba(255,255,255,0.015) !important; }
.grid-row-dark:hover .cell { background: rgba(255,255,255,0.07); }

.sticky-head { position: sticky; top: 0; z-index: 10; box-shadow: 0 8px 16px -4px rgba(0, 0, 0, 0.12); }
.bg-glass-dark .sticky-head { box-shadow: 0 8px 20px -4px rgba(0, 0, 0, 0.4); }

.solid-chip { display: inline-flex; align-items: center; justify-content: center; height: 22px; padding: 0 10px; border-radius: 8px; font-size: 10px; font-weight: 900; color: #fff; white-space: nowrap; }
.chip-success { background: #2e7d32; }
.actions-inline { display: flex; align-items: center; gap: 8px; }
.action-btn { width: 28px !important; height: 28px !important; border-radius: 6px !important; color: #fff !important; }
.action-btn :deep(.v-icon) { color: #fff !important; }
.action-edit { background: #1976d2 !important; }

/* Scrollbars */
.custom-scroll::-webkit-scrollbar { width: 6px; height: 6px; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.35); border-radius: 6px; }
.custom-scroll::-webkit-scrollbar-track { background: transparent; }
.custom-scroll-x::-webkit-scrollbar { height: 8px; }
.custom-scroll-x::-webkit-scrollbar-track { background: transparent; }
.custom-scroll-x::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.35); border-radius: 6px; }

/* Z-Index */
.z-low { z-index: 1 !important; }
.z-high { z-index: 100 !important; }

/* Tutorial */
.tutorial-click-overlay { position: fixed; inset: 0; z-index: 1001; cursor: pointer; }
.tutorial-highlight { position: fixed; z-index: 1000; border-radius: 8px; box-shadow: 0 0 0 9999px rgba(12, 12, 12, 0.7); border: 2px solid #42a5f5; animation: pulse-opacity 2.5s infinite; transition: all 0.5s cubic-bezier(0.4, 0, 0.2, 1); pointer-events: none; }
.hint-bubble { position: fixed; z-index: 1002; pointer-events: none; width: max-content; max-width: 320px; transition: all 0.5s; .hint-bubble-content { display: flex; align-items: center; padding: 12px 18px; border-radius: 12px; font-size: 0.9rem; font-weight: 500; color: #e0e0e0; background-color: rgba(45, 45, 55, 0.9); backdrop-filter: blur(10px); border: 1px solid rgba(255, 255, 255, 0.15); box-shadow: 0 4px 20px rgba(0, 0, 0, 0.5); } }
</style>
